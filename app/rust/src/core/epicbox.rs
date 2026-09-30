//! Epicbox: slates exchanged through a store-and-forward relay, protocol 3.0.0.
//!
//! Built on epic-wallet's own pieces (`EpicboxAddress`, `EncryptedMessage`, `TxProof`,
//! `sign_challenge`, the protocol message types) with our own connection loop. Upstream's
//! `EpicboxListenChannel` panics on a failed connect or post, has no way to stop, and cannot
//! report what it did, none of which a phone app can live with.
//!
//! One [`Listener`] per open wallet. It keeps a websocket to the relay, subscribes with the
//! wallet's address key, and handles every slate the relay delivers:
//!
//! - a new send to us: `Foreign::receive_tx`, then the signed response goes back to the sender;
//! - the response to one of our sends: `finalize_tx` and `post_tx`.
//!
//! A send over epicbox therefore only completes while the listener runs, because the response
//! arrives through it. It reconnects with backoff until stopped.

use std::net::{TcpStream, ToSocketAddrs};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread::JoinHandle;
use std::time::{Duration, Instant};

use epic_wallet_api::Foreign;
use epic_wallet_impls::epicbox::protocol::{ProtocolRequestV2, ProtocolResponseV2};
use epic_wallet_libwallet::address::address_from_derivation_path;
use epic_wallet_libwallet::crypto::{sign_challenge, Hex};
use epic_wallet_libwallet::message::EncryptedMessage;
use epic_wallet_libwallet::{
    Address, EpicboxAddress, Error as LibWalletError, Slate as LibSlate, SlateVersion, TxProof,
    VersionedSlate,
};
use epic_wallet_util::epic_core::core::amount_to_hr_string;
use epic_wallet_util::epic_keychain::Keychain;
use epic_wallet_util::epic_util::secp::key::{PublicKey, SecretKey};
use tungstenite::stream::MaybeTlsStream;
use tungstenite::{Message, WebSocket};

use super::error::{CoreError, CoreResult};
use super::meta::MetaStore;
use super::session::{OwnerApi, WalletHandle};
use crate::api::types::{ListenerEvent, ListenerEventKind, WalletConfig};

const PROTOCOL_VERSION: &str = "3.0.0";
/// Index of the key the address is derived from; epic-wallet's CLI uses 0.
pub(crate) const ADDRESS_INDEX: u32 = 0;
/// How long a read blocks before the loop checks whether it should stop.
const READ_TICK: Duration = Duration::from_millis(500);
const CONNECT_TIMEOUT: Duration = Duration::from_secs(15);
const MAX_BACKOFF: Duration = Duration::from_secs(60);
/// Waits between tip reads before an answer is left for a later delivery: about 30 s in all.
const TIP_RETRY_DELAYS: [Duration; 3] = [
    Duration::from_secs(5),
    Duration::from_secs(10),
    Duration::from_secs(15),
];

type Socket = WebSocket<MaybeTlsStream<TcpStream>>;

/// The wallet's epicbox identity: address and the key that signs for it.
#[derive(Clone)]
pub(crate) struct Identity {
    pub(crate) address: EpicboxAddress,
    secret_key: SecretKey,
}

impl Identity {
    pub(crate) fn derive(
        wallet: &WalletHandle,
        mask: Option<&SecretKey>,
        config: &WalletConfig,
    ) -> CoreResult<Identity> {
        let mut guard = wallet.lock();
        let w = guard.lc_provider()?.wallet_inst()?;
        let keychain = w.keychain(mask)?;
        let parent = w.parent_key_id();
        let secret_key = address_from_derivation_path(&keychain, &parent, ADDRESS_INDEX)?;
        let public_key = PublicKey::from_secret_key(keychain.secp(), &secret_key)
            .map_err(|e| CoreError::InvalidArgument(format!("address key: {e}")))?;
        let address = EpicboxAddress::new(
            public_key,
            Some(config.epicbox_domain.clone()),
            Some(config.epicbox_port),
        );
        Ok(Identity {
            address,
            secret_key,
        })
    }

    fn sign(&self, text: &str) -> CoreResult<String> {
        Ok(sign_challenge(text, &self.secret_key)?.to_hex())
    }
}

/// Parses `<52-char key>@<domain>[:port]`. A bare key is refused: epicbox would route it to the
/// default public relay, which is almost never what the user meant.
pub(crate) fn parse_address(text: &str) -> CoreResult<EpicboxAddress> {
    let text = text.trim();
    if !text.contains('@') {
        return Err(CoreError::InvalidArgument(
            "an address needs its epicbox server: <address>@<server>".into(),
        ));
    }
    let address = EpicboxAddress::from_str(text)
        .map_err(|_| CoreError::InvalidArgument("not a valid address".into()))?;
    // from_str checks the base58 checksum; the version bytes tie the key to the chain.
    address
        .public_key()
        .map_err(|_| CoreError::InvalidArgument("this address is for another network".into()))?;
    Ok(address)
}

fn relay_url(config: &WalletConfig) -> String {
    // Plain ws only for a relay on this machine, as epic-wallet's `epicbox_protocol_unsecure`.
    let local = matches!(config.epicbox_domain.as_str(), "127.0.0.1" | "localhost");
    let scheme = if local { "ws" } else { "wss" };
    format!(
        "{scheme}://{}:{}",
        config.epicbox_domain, config.epicbox_port
    )
}

fn connect(config: &WalletConfig) -> CoreResult<Socket> {
    let url = relay_url(config);
    let addr = (config.epicbox_domain.as_str(), config.epicbox_port)
        .to_socket_addrs()
        .map_err(|e| CoreError::Relay(format!("cannot resolve {}: {e}", config.epicbox_domain)))?
        .next()
        .ok_or_else(|| CoreError::Relay(format!("no address for {}", config.epicbox_domain)))?;
    let tcp = TcpStream::connect_timeout(&addr, CONNECT_TIMEOUT)
        .map_err(|e| CoreError::Relay(format!("cannot connect to {url}: {e}")))?;
    tcp.set_read_timeout(Some(CONNECT_TIMEOUT))
        .and_then(|_| tcp.set_write_timeout(Some(CONNECT_TIMEOUT)))
        .map_err(|e| CoreError::Relay(e.to_string()))?;
    let (socket, _) = tungstenite::client_tls(url.as_str(), tcp)
        .map_err(|e| CoreError::Relay(format!("websocket handshake with {url}: {e}")))?;
    // From here reads time out quickly, so the loop can notice a stop request.
    set_read_timeout(&socket, READ_TICK)?;
    Ok(socket)
}

fn set_read_timeout(socket: &Socket, timeout: Duration) -> CoreResult<()> {
    let tcp = match socket.get_ref() {
        MaybeTlsStream::Plain(s) => s,
        MaybeTlsStream::NativeTls(s) => s.get_ref(),
        _ => return Ok(()),
    };
    tcp.set_read_timeout(Some(timeout))
        .map_err(|e| CoreError::Relay(e.to_string()))
}

fn send_request(socket: &mut Socket, request: &ProtocolRequestV2) -> CoreResult<()> {
    let text = serde_json::to_string(request).map_err(|e| CoreError::Relay(e.to_string()))?;
    socket
        .send(Message::Text(text.into()))
        .map_err(|e| CoreError::Relay(format!("sending to the epicbox server: {e}")))
}

/// The encrypted, signed `PostSlate` for `slate` from `from` to `to`.
fn post_request(
    identity: &Identity,
    to: &EpicboxAddress,
    slate: &VersionedSlate,
) -> CoreResult<ProtocolRequestV2> {
    let body = serde_json::to_string(slate).map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
    let receiver_key = to
        .public_key()
        .map_err(|_| CoreError::InvalidArgument("not a valid address".into()))?;
    let message = EncryptedMessage::new(body, to, &receiver_key, &identity.secret_key)?;
    let message =
        serde_json::to_string(&message).map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
    Ok(ProtocolRequestV2::PostSlate {
        from: identity.address.stripped(),
        to: to.stripped(),
        signature: identity.sign(&message)?,
        str: message,
    })
}

/// Posts one slate over a short-lived connection. Used for sends: the response comes back to
/// the listener, not to this connection.
pub(crate) fn post_once(
    config: &WalletConfig,
    identity: &Identity,
    to: &EpicboxAddress,
    slate: &LibSlate,
) -> CoreResult<()> {
    // Protocol 3.0.0 relays and the CLI send V2; V3-only fields (payment proof, TTL) are unset
    // for our sends.
    let versioned = VersionedSlate::into_version(slate.clone(), SlateVersion::V2);
    let request = post_request(identity, to, &versioned)?;
    let mut socket = connect(config)?;
    // The relay opens with a challenge; answering it is not needed to post, but reading it
    // confirms the relay speaks epicbox before we hand it a slate.
    let deadline = Instant::now() + CONNECT_TIMEOUT;
    loop {
        match socket.read() {
            Ok(Message::Text(text)) => {
                if serde_json::from_str::<ProtocolResponseV2>(&text).is_ok() {
                    break;
                }
            }
            Ok(_) => {}
            Err(e) if is_timeout(&e) => {}
            Err(e) => {
                return Err(CoreError::Relay(format!(
                    "reading from the epicbox server: {e}"
                )))
            }
        }
        if Instant::now() > deadline {
            return Err(CoreError::Relay("the epicbox server did not answer".into()));
        }
    }
    send_request(&mut socket, &request)?;
    // Wait briefly for the relay's verdict on the post; an Error means it was refused.
    let deadline = Instant::now() + Duration::from_secs(5);
    while Instant::now() < deadline {
        match socket.read() {
            Ok(Message::Text(text)) => match serde_json::from_str::<ProtocolResponseV2>(&text) {
                Ok(ProtocolResponseV2::Ok) => break,
                Ok(ProtocolResponseV2::Error { kind, description }) => {
                    return Err(CoreError::Relay(format!(
                        "the epicbox server refused the payment: {kind} {description}"
                    )))
                }
                _ => {}
            },
            Ok(_) => {}
            Err(e) if is_timeout(&e) => {}
            Err(e) => {
                log::info!("epicbox post: no verdict from the relay: {e}");
                break;
            }
        }
    }
    let _ = socket.close(None);
    Ok(())
}

fn is_timeout(e: &tungstenite::Error) -> bool {
    matches!(e, tungstenite::Error::Io(io)
        if matches!(io.kind(), std::io::ErrorKind::WouldBlock | std::io::ErrorKind::TimedOut))
}

/// A running listener. Dropping it stops the thread and waits for it.
pub(crate) struct Listener {
    stop: Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl Listener {
    pub(crate) fn start<F>(
        config: WalletConfig,
        identity: Identity,
        wallet: WalletHandle,
        mask: Option<SecretKey>,
        owner: Arc<OwnerApi>,
        meta: Arc<MetaStore>,
        on_event: F,
    ) -> Listener
    where
        F: FnMut(ListenerEvent) + Send + 'static,
    {
        let stop = Arc::new(AtomicBool::new(false));
        let worker = Worker {
            config,
            identity,
            wallet,
            mask,
            owner,
            meta,
            stop: stop.clone(),
            on_event: Box::new(on_event),
            delayed: std::collections::HashSet::new(),
        };
        let thread = std::thread::Builder::new()
            .name("epicbox-listener".into())
            .spawn(move || worker.run())
            .map_err(|e| log::warn!("listener: no thread: {e}"))
            .ok();
        Listener { stop, thread }
    }

    pub(crate) fn is_running(&self) -> bool {
        self.thread.as_ref().is_some_and(|t| !t.is_finished())
    }
}

impl Drop for Listener {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::SeqCst);
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}

struct Worker {
    config: WalletConfig,
    identity: Identity,
    wallet: WalletHandle,
    mask: Option<SecretKey>,
    owner: Arc<OwnerApi>,
    meta: Arc<MetaStore>,
    stop: Arc<AtomicBool>,
    on_event: Box<dyn FnMut(ListenerEvent) + Send>,
    /// Slates already reported as `Delayed` in this run, so the UI hears about each once.
    delayed: std::collections::HashSet<String>,
}

impl Worker {
    fn emit(&mut self, kind: ListenerEventKind, slate_id: Option<String>, message: String) {
        self.emit_with(kind, slate_id, message, None);
    }

    fn emit_with(
        &mut self,
        kind: ListenerEventKind,
        slate_id: Option<String>,
        message: String,
        amount: Option<u64>,
    ) {
        let slate = slate_id
            .as_deref()
            .map(|s| format!(" {s}"))
            .unwrap_or_default();
        match kind {
            // The message is our own address; the relay is enough.
            ListenerEventKind::Connected => {
                log::info!("listener: connected to {}", self.config.epicbox_domain)
            }
            ListenerEventKind::Error => log::warn!("listener: error{slate}: {message}"),
            _ => log::info!("listener: {kind:?}{slate}: {message}"),
        }
        (self.on_event)(ListenerEvent {
            amount,
            kind,
            slate_id,
            message,
        });
    }

    fn stopped(&self) -> bool {
        self.stop.load(Ordering::SeqCst)
    }

    /// Sleeps for `d` in ticks. Returns false if a stop was asked for meanwhile.
    fn pause(&self, d: Duration) -> bool {
        let until = Instant::now() + d;
        while Instant::now() < until {
            if self.stopped() {
                return false;
            }
            std::thread::sleep(READ_TICK);
        }
        !self.stopped()
    }

    fn run(mut self) {
        let mut backoff = Duration::from_secs(1);
        while !self.stopped() {
            match connect(&self.config) {
                Ok(socket) => {
                    backoff = Duration::from_secs(1);
                    let reason = self.session(socket);
                    if self.stopped() {
                        break;
                    }
                    self.emit(ListenerEventKind::Disconnected, None, reason);
                }
                Err(e) => self.emit(ListenerEventKind::Disconnected, None, e.to_string()),
            }
            // Sleep in ticks so a stop request is honoured quickly.
            let until = Instant::now() + backoff;
            while Instant::now() < until && !self.stopped() {
                std::thread::sleep(READ_TICK);
            }
            backoff = (backoff * 2).min(MAX_BACKOFF);
        }
        self.emit(ListenerEventKind::Stopped, None, "Offline".into());
    }

    /// Serves one connection until it drops or a stop is requested. Returns why it ended.
    fn session(&mut self, mut socket: Socket) -> String {
        let mut subscribed = false;
        loop {
            if self.stopped() {
                let _ = socket.close(None);
                return "stopped".into();
            }
            let message = match socket.read() {
                Ok(m) => m,
                Err(e) if is_timeout(&e) => continue,
                Err(e) => return format!("connection lost: {e}"),
            };
            let text = match message {
                Message::Text(t) => t.to_string(),
                Message::Close(_) => return "the epicbox server closed the connection".into(),
                _ => continue,
            };
            let Ok(response) = serde_json::from_str::<ProtocolResponseV2>(&text) else {
                // Some relays answer pings with bare text; nothing to do with it.
                continue;
            };
            match response {
                ProtocolResponseV2::Challenge { str } => {
                    if !subscribed {
                        let details = ProtocolRequestV2::ClientDetails {
                            wallet_version: env!("CARGO_PKG_VERSION").into(),
                            wallet_mode: "listener".into(),
                            protocol_version: PROTOCOL_VERSION.into(),
                        };
                        if let Err(e) = send_request(&mut socket, &details) {
                            return e.to_string();
                        }
                    }
                    if let Err(e) = self.subscribe(&mut socket, &str) {
                        return e.to_string();
                    }
                    if !subscribed {
                        subscribed = true;
                        let address = self.identity.address.to_string();
                        self.emit(ListenerEventKind::Connected, None, address);
                    }
                }
                ProtocolResponseV2::Slate {
                    from,
                    str,
                    signature,
                    epicboxmsgid,
                    ..
                } => {
                    // Acknowledge whether or not handling succeeded: a slate that failed once
                    // fails again, and redelivery would only repeat the error. The exception is
                    // an answer that could not be checked against the chain height: left
                    // unacknowledged, the relay delivers it again on a later subscribe. The relay
                    // answers a Made with a fresh challenge, which re-subscribes us above.
                    // Upstream re-subscribes with the old challenge first, which the relay
                    // rejects once it has rotated the challenge.
                    if self.on_slate(&mut socket, from, str, signature) {
                        if let Err(e) = self.made(&mut socket, epicboxmsgid) {
                            return e.to_string();
                        }
                    }
                }
                ProtocolResponseV2::Error { kind, description } => {
                    self.emit(
                        ListenerEventKind::Error,
                        None,
                        format!("epicbox server error: {kind} {description}"),
                    );
                }
                ProtocolResponseV2::Ok | ProtocolResponseV2::GetVersion { .. } => {}
            }
        }
    }

    fn subscribe(&self, socket: &mut Socket, challenge: &str) -> CoreResult<()> {
        let request = ProtocolRequestV2::Subscribe {
            address: self.identity.address.public_key.clone(),
            ver: PROTOCOL_VERSION.into(),
            signature: self.identity.sign(challenge)?,
        };
        send_request(socket, &request)
    }

    fn made(&self, socket: &mut Socket, message_id: String) -> CoreResult<()> {
        let request = ProtocolRequestV2::Made {
            address: self.identity.address.public_key.clone(),
            signature: self.identity.sign(&message_id)?,
            epicboxmsgid: message_id,
            ver: PROTOCOL_VERSION.into(),
        };
        send_request(socket, &request)
    }

    /// Handles one delivered slate. Returns false when it must not be acknowledged, so the
    /// relay delivers it again later (the chain height could not be read).
    fn on_slate(
        &mut self,
        socket: &mut Socket,
        from: String,
        message: String,
        signature: String,
    ) -> bool {
        let parsed = TxProof::from_response(
            from,
            message,
            signature,
            &self.identity.secret_key,
            Some(&self.identity.address),
        );
        let (versioned, proof) = match parsed {
            Ok(x) => x,
            Err(e) => {
                let text = format!("an unreadable payment arrived from the epicbox server: {e}");
                self.emit(ListenerEventKind::Error, None, text);
                return true;
            }
        };
        let version = versioned.version();
        let slate: LibSlate = versioned.into();
        let slate_id = slate.id.to_string();
        let sender = proof.address;
        let result = if slate.num_participants > slate.participant_data.len() {
            self.receive(socket, &slate, version, &sender)
        } else {
            self.finalize(&slate)
        };
        match result {
            // The slate carries the amount both ways: what we receive, or what we sent.
            Ok((kind, text)) => self.emit_with(kind, Some(slate_id), text, Some(slate.amount)),
            // The relay redelivers a slate whose acknowledgement it missed. Handling it again is
            // refused by the wallet, and that refusal means it was already done.
            Err(CoreError::Wallet(LibWalletError::TransactionAlreadyReceived(_))) => {
                log::info!("slate {slate_id} was already received");
            }
            Err(CoreError::Expired(text)) => self.emit_with(
                ListenerEventKind::Expired,
                Some(slate_id),
                text,
                Some(slate.amount),
            ),
            Err(CoreError::RetryLater(text)) => {
                log::info!("payment {slate_id} left for a later delivery: {text}");
                if self.delayed.insert(slate_id.clone()) {
                    self.emit_with(
                        ListenerEventKind::Delayed,
                        Some(slate_id),
                        "Could not reach the node. The payment will finish once it can.".into(),
                        Some(slate.amount),
                    );
                }
                return false;
            }
            Err(e) => self.emit(ListenerEventKind::Error, Some(slate_id), e.to_string()),
        }
        true
    }

    /// A new send to us: sign it and post the response back to the sender.
    fn receive(
        &self,
        socket: &mut Socket,
        slate: &LibSlate,
        version: SlateVersion,
        sender: &EpicboxAddress,
    ) -> CoreResult<(ListenerEventKind, String)> {
        if slate.tx.inputs().is_empty() {
            return Err(CoreError::InvalidSlate(
                "payment requests (invoices) are not supported".into(),
            ));
        }
        let foreign = Foreign::new(self.wallet.clone(), self.mask.clone(), None);
        foreign
            .verify_slate_messages(slate)
            .map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
        let response = foreign.receive_tx(slate, None, None, Some(sender.to_string()))?;
        self.meta.annotate(&slate.id.to_string(), |a| {
            a.counterparty = Some(sender.to_string())
        });
        let versioned = VersionedSlate::into_version(response, version);
        let request = post_request(&self.identity, sender, &versioned)?;
        send_request(socket, &request)?;
        Ok((
            ListenerEventKind::Received,
            format!(
                "Received {} from {}",
                format!("{} EPIC", amount_to_hr_string(slate.amount, false)),
                sender.stripped()
            ),
        ))
    }

    /// The response to one of our sends: finalize and broadcast.
    fn finalize(&self, slate: &LibSlate) -> CoreResult<(ListenerEventKind, String)> {
        let mask = self.mask.as_ref();
        self.owner
            .verify_slate_messages(mask, slate)
            .map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
        // The node may be busy (429) or briefly down: try the height a few more times, about
        // 30 s in all, before leaving the answer for a later delivery.
        let mut attempt = 0;
        loop {
            match super::session::answer_in_time(&self.owner, mask, &self.wallet, &self.meta, slate)
            {
                Err(CoreError::RetryLater(text)) if attempt < TIP_RETRY_DELAYS.len() => {
                    if !self.pause(TIP_RETRY_DELAYS[attempt]) {
                        return Err(CoreError::RetryLater(text));
                    }
                    attempt += 1;
                }
                other => {
                    other?;
                    break;
                }
            }
        }
        let finalized = self.owner.finalize_tx(mask, slate)?;
        let height = super::session::wallet_height(&self.wallet);
        super::session::record_finalized(&self.meta, &finalized, height);
        // A failed post is recorded: the payment shows as not taken yet, and repostable.
        super::session::post_recorded(&self.owner, mask, &self.meta, &finalized)?;
        Ok((
            ListenerEventKind::Finalized,
            format!(
                "Sent {}, posted to the node",
                format!("{} EPIC", amount_to_hr_string(finalized.amount, false))
            ),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY: &str = "esY8LvovTpEGYnGH1UGyWzktBv2sHaPgNE2senHw8KN4fvFFU2PV";

    #[test]
    fn parses_full_addresses_and_refuses_bare_keys() {
        epic_wallet_util::epic_core::global::set_mining_mode(
            epic_wallet_util::epic_core::global::ChainTypes::Mainnet,
        );
        let a = parse_address(&format!("{KEY}@epicbox.epiccash.com")).unwrap();
        assert_eq!(a.domain, "epicbox.epiccash.com");
        assert_eq!(a.port, None);
        let b = parse_address(&format!(" {KEY}@127.0.0.1:3423 ")).unwrap();
        assert_eq!(b.port, Some(3423));
        assert!(parse_address(KEY).is_err(), "a bare key must be refused");
        assert!(parse_address("nonsense@epicbox.epiccash.com").is_err());
        let mut broken = KEY.to_string();
        broken.replace_range(10..11, "1");
        assert!(parse_address(&format!("{broken}@epicbox.epiccash.com")).is_err());
    }

    #[test]
    fn relay_url_uses_tls_except_on_loopback() {
        let mut c = WalletConfig {
            data_dir: String::new(),
            chain: crate::api::types::Chain::Mainnet,
            node_url: String::new(),
            node_api_secret: None,
            epicbox_domain: "flooepicbox.btlabs.uk".into(),
            epicbox_port: 443,
        };
        assert_eq!(relay_url(&c), "wss://flooepicbox.btlabs.uk:443");
        c.epicbox_domain = "127.0.0.1".into();
        c.epicbox_port = 3423;
        assert_eq!(relay_url(&c), "ws://127.0.0.1:3423");
    }
}
