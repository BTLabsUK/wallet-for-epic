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
///   - All wallets: "Import" and "Import wallets…".
/// dataFolder (A15): Welcome › Advanced › App data folder.
/// testNetworks (A06 "any network each"): Welcome › Advanced › Network. Mainnet only.
/// httpDirect (G01–G06, F07, J04): Send › Direct (HTTP), Receive's HTTP address, Settings ›
///   Receiving › HTTP listener and Start with the wallet, the status card's HTTP line.
/// tor (G07–G12): Send › Direct › Tor, Receive's onion address, Settings › Receiving ›
///   Advanced › Tor, the status card's Tor line.
/// builtInNode (D09–D14, on): Setup › Node's "Built-in node" card (off by default, D10),
///   Settings › Node's "This computer" option, Overview's "Start node". Needs the bundled `epic`
///   (bin/epic beside the app); without it turning the node on says so. The blockchain data
///   offer (D12) and the head start (D14) are not built.
/// nodeBackground (D09): Settings › Node's "Sync in background" for the built-in node.
/// coins (I05): Activity › Outputs tab.
/// dandelion (F05, H04): Send's Dandelion++ switch and the review's Privacy line.
/// rescanRepair (A16): Rescan's "Delete unconfirmed transactions".
/// stopScan: Rescan's Stop (a LEPIC scan runs to its end).
/// nodeBlockTime (C04): "last block … ago" on the node status line.
/// paymentProofs (I08, D6): Transaction details › Export proof.
/// changePassword: Settings › This wallet › Change password (LEPIC has no password change).
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
  static const bool httpDirect = false;
  static const bool tor = false;
  static const bool builtInNode = true;
  static const bool nodeBackground = false;
  static const bool coins = false;
  static const bool dandelion = false;
  static const bool rescanRepair = false;
  static const bool stopScan = false;
  static const bool nodeBlockTime = false;
  static const bool paymentProofs = false;
  static const bool changePassword = false;
  static const bool walletProcesses = false;
  static const bool languages = false;
  static const bool fiatPrice = false;
  static const bool contactPictures = false;
}
