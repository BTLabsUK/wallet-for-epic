/// What the desktop UI shows that the wallet core (LEPIC) or the app cannot do yet. Every spot
/// of a false flag is hidden, not faked: a screen, row, segment, menu item, status line or
/// onboarding path. The adapter (`lepic_desk_wallet.dart`) throws [UnsupportedError] for the
/// methods behind a false flag. Flip a flag once its adapter method is real.
///
/// The hidden spots, by flag (gap ids from LEPIC's `docs/reviews/feature-gap-2026-10/gui-parity.md`):
///
/// multiWallet (A06–A13, D9, on): several wallets of one network, one open at a time, desktop
///   only (phones keep one). The adapter lists them in `WalletRegistry`.
///   - Unlock: the Wallet select, "Add a wallet", the missing-folder notice and its Remove.
///   - Welcome: "Add a wallet" heading and "Back to unlock" for a later visit.
///   - Settings: the "All wallets" section (settingsWallets route), with Add back.
///   - Sidebar: "Switch wallet".
///   - Remove wallet dialog: "Remove from list" and "Delete wallet".
/// importWizard (B01–B25 as LEPIC takes them, A01's third door, on): wallets of older Epic
///   Wallets and the epic program, found or from a chosen folder. Old folders are only read:
///   each wallet.seed opens once with its old password (B18) and becomes a new wallet whose
///   history a scan rebuilds (B14, B09). Mainnet only; no settings carried over, no old-folder
///   delete (B26–B29) and no blockchain data copy (B21).
///   - Welcome: "Import wallets". Route importWallets.
///   - All wallets: the "Import" card.
/// dataFolder (A15): Welcome › Advanced › App data folder.
/// testNetworks (A06 "any network each"): Welcome › Advanced › Network. Mainnet only.
/// httpDirect (G01–G06, F07, J04, on): Send › Direct (HTTP), with a question before plain HTTP
///   to another computer; Receive's HTTP address; Settings › Receiving › HTTP listener (off by
///   default), Reachable (Local only / From the internet, through its guide), Port and Start with
///   the wallet; the status card's HTTP line; HTTP addresses in contacts. No resend over HTTP
///   yet: a send nobody answered waits in Activity to be cancelled.
/// tor (G07–G12): Send › Direct › Tor (an onion pasted anywhere goes there; Turn on Tor while
///   off; a send can take about two minutes), Receive's onion address with Copy and QR,
///   Settings › Receiving › Advanced › Tor (per wallet, off by default, its state and Retry),
///   the status card's and Overview's Tor line, .onion addresses in contacts, the Help topic.
///   Needs the bundled tor (bin/tor-bundle beside the app, tools/fetch-tor.sh); without it
///   the row says "Tor not included in this build" and its switch is disabled.
/// builtInNode (D09–D14, on): Setup › Node's "Built-in node" card (off by default, D10),
///   Settings › Node's "This computer" option, Overview's "Start node". Needs the bundled `epic`
///   (bin/epic beside the app); without it turning the node on says so. The blockchain data
///   offer (D12) and the head start (D14) are not built.
/// nodeBackground (D09): Settings › Node's "Sync in background" for the built-in node.
/// coins (I05, F13, on): the Outputs page (sidebar), Split and Consolidate.
/// dandelion (F05, H04): Send's Dandelion++ switch and the review's Privacy line.
/// rescanRepair (A16, on): Rescan's "Delete unconfirmed" (LEPIC's scan delete_unconfirmed)
///   and the result's counts.
/// stopScan (on): Rescan's Stop, which ends the LEPIC scan at its next page (cancel_scan).
/// nodeBlockTime (C04): "last block … ago" on the node status line.
/// paymentProofs (I08, D6): Transaction details › Export proof.
/// changePassword (F32, on): Settings › This wallet › Change password (LEPIC's change_password);
///   forgets the wallet's remembered password.
/// walletProcesses (A20, dropped): Unlock's "Looking for wallet processes" stage and the
///   kill-process dialog (LEPIC runs in-process).
///
/// App-side, not in 0.1.0 (no core change needed):
/// languages (K04): Setup › Preferences › Language, Settings › Appearance › Language.
/// fiatPrice (C12): the fiat line under the balance.
/// contactPictures: the contact form's picture and the list's photos (initials stay).
library;

abstract final class DeskFeatures {
  static const bool multiWallet = true;
  static const bool importWizard = true;
  static const bool dataFolder = false;
  static const bool testNetworks = false;
  static const bool httpDirect = true;
  static const bool tor = true;
  static const bool builtInNode = true;
  static const bool nodeBackground = false;
  static const bool coins = true;
  static const bool dandelion = false;
  static const bool rescanRepair = true;
  static const bool stopScan = true;
  static const bool nodeBlockTime = false;
  static const bool paymentProofs = false;
  static const bool changePassword = true;
  static const bool walletProcesses = false;
  static const bool languages = false;
  static const bool fiatPrice = false;
  static const bool contactPictures = false;
}
