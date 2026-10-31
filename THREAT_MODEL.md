# Threat model

What Epic Cash Desktop and Epic Cash Mobile protect, against whom, and where the limits are. The wallet
engine is [LEPIC](https://gitlab.com/epic-cash-bt/lepic). Statements about it refer to the version this app
pins (`tools/lepic.rev`). Report anything that breaks a promise below as SECURITY.md describes.

**There has been no external security audit of the app or of LEPIC yet, and there is no bug bounty.**

## What we protect

1. **Funds.** Nobody but the wallet's owner can spend them, and a payment goes to the party the user meant.
2. **The recovery phrase and keys.** They never leave the device unencrypted, except when the user shows or
   copies the phrase.
3. **The payment the user approves is the payment that is made**: amount, fee and recipient.
4. **Updates.** An installed app only installs builds that BT Labs signed.
5. **Privacy**, as far as the Epic Cash protocol allows it: amounts and history stay on the device, and with
   Tor on, network traffic does not reveal the user's IP address.

## Who can do what

### The Epicbox relay

The relay passes slates between wallets. Its protocol is inherited from the reference Epic Cash wallet and
kept unchanged for compatibility:

- Messages are encrypted end to end: static-static ECDH between the two wallet addresses, then
  PBKDF2-SHA512, then ChaCha20-Poly1305. The PBKDF2 step uses 100 iterations. That is not a weakness here:
  its input is an ECDH shared secret, not a password, so there is nothing to brute-force.
- There is no forward secrecy. Whoever later learns a wallet's address key can read its past messages.
- The relay cannot read or change a slate. It **can** drop, delay, reorder or redeliver messages: the
  protocol has no sequence numbers. The wallet ignores repeats of the same slate and stage.
- Subscription signatures are not bound to the relay's name or to a time.
- The relay sees which addresses talk to each other, when, and how much data they send. Without Tor it also
  sees the user's IP address.

### The node

The wallet asks a node (BT Labs' public node by default, or one the user sets) about the chain.

- A lying node **cannot steal funds**: every transaction is built and signed on the device.
- It **can** hide or fake confirmations, hide incoming payments, refuse to post a transaction, and see the
  user's IP address without Tor.
- The wallet checks node answers for plausibility, but does not cross-check a second node or verify headers
  and proof of work. A user who needs that should run their own node.

### The network: Wi-Fi, a router, the ISP

- Epicbox, the node, updates and https sends use TLS (rustls with the web PKI, no exceptions) or Tor.
- **Plain `http://` sends.** The app can send to a plain `http://` wallet address, which the reference
  Epic Cash wallet needs. In Mimblewimble the sender's first slate goes to whoever answers, so **anyone on
  the network path can receive that payment instead of the recipient**. The app asks before such a send.
  While Tor is on, plain `http://` sends to another device are off.
- **Tor.** With Tor on, the wallet's traffic goes through Tor, and names are resolved inside Tor. If Tor is
  wanted but cannot run, the wallet stops, not falls back to the open internet.

### Another app on the same phone

- Android keeps the app's files private. Backups are off (`allowBackup=false`, every domain excluded). No
  services, receivers or providers are exported.
- The onion service's local listener and the optional "Link · HTTP" listener accept slates from anyone who
  can reach them. They cannot take funds: a received slate can only pay *to* the wallet. They can add pending
  "received" entries, which are capped, expire, and are shown apart from receives the user started.
- A copied recovery phrase is marked sensitive (Android 13+) and cleared from the clipboard after a short
  time.

### A thief with the phone

- The wallet is locked by a 6-digit PIN, with waits after wrong PINs. The failure is counted before each try,
  so killing the app does not reset the count.
- The wallet's own password is random (256 bits) and is sealed under the PIN with Argon2id
  (64 MiB, t=3).
- **Limit.** Someone who can copy the app's protected storage off the device (a rooted or forensically imaged
  phone) can try all 10^6 PINs offline at the cost of Argon2id each. Wrapping the PIN key in the phone's
  hardware Keystore (StrongBox where available), with the attempt counter enforced there, closes this; until
  a release says it has shipped, assume the limit applies. A longer PIN or passphrase is an option in
  Settings.
- **Screenshots of the recovery phrase are allowed, on purpose**: many people keep their phrase that way.
  Screenshots may sync to cloud photo libraries. Keep the phrase offline if that matters to you. The app hides
  its content in the app switcher (Recents).

### Malware on the computer

- Desktop wallets are protected by a password (at least 8 characters), which seals the seed with Argon2id
  and XChaCha20-Poly1305.
- Malware that runs as the user can capture that password as it is typed, or read the wallet while it is open.
  No software wallet defends against that.
- The wallet database (amounts, outputs, history and counterparty addresses) is **not encrypted**, the same
  as in the reference wallet. On Linux and macOS it is readable only by its owner. On Windows the data folder
  is restricted to its owner. A copied profile still shows the history without the password.

### Contacts and pairing

- Slates to a paired contact sent by file or paste travel sealed to that contact's key (HPKE, RFC 9180) and
  signed by the sender (Ed25519, bound to the recipient key). Only that contact can open them, and a party
  that is not the contact is refused (LEPIC RFC 0002).
- **Pairing** compares a short code (SAS with a commitment from the inviter). Skipping the comparison ("Skip") leaves the contact trusted on
  first use. Pairing over relayed screenshots needs only about 2^16 work per side for a man in the middle
  (LEPIC RFC 0002, §7.4–7.5). Compare the code over a channel you trust.

### The update channel and BT Labs itself

- Installed apps accept an update only from a manifest signed with Ed25519 (DSSE). The keys are compiled into
  the app in two ranks, and a higher rank can revoke a lower one. Manifests expire, and a persisted serial
  refuses rollbacks.
- The app checks the file's size and SHA-256 again right before installing, and Android also requires the
  same signing certificate as the installed app.
- What this does not cover:
  - Whoever holds the signing keys can ship an update. The rank-2 key is not kept on the build machine. Each
    release signature needs a maintainer's explicit approval.
  - First-time downloads are not protected by the manifest. Check `SHA256SUMS` with its minisign signature and
    the public key published in the README (never one served next to the file).
  - The Windows installer is not yet Authenticode-signed, so Windows SmartScreen warns about it.
  - The builds are not yet reproducible by third parties. See `https://docs.btlabs.uk/developers/build/variants/` for the F-Droid route.

## What we do not try to protect against

- A device whose operating system is compromised while the wallet is unlocked.
- Coercion of the owner.
- Chain-level privacy limits of Mimblewimble and Epic Cash: transaction graph analysis by observers of the
  network that relays transactions.
- Attacks on the Epic Cash node software, the consensus rules or the reference wallet. Report those to those
  projects.
