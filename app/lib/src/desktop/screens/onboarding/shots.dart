import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'create_screen.dart';
import 'found_screen.dart';
import 'import_wallets_screen.dart';
import 'restore_screen.dart';
import 'setup_screen.dart';

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> onboardingShots = [
  const DeskShot(id: '01-welcome', title: 'Welcome', route: DeskRoute.welcome),
  const DeskShot(id: '02a-create', title: 'Create: password', route: DeskRoute.create, arg: CreateStep.account),
  const DeskShot(id: '02b-create-phrase', title: 'Create: recovery phrase', route: DeskRoute.create, arg: CreateStep.phrase),
  const DeskShot(id: '02c-create-confirm', title: 'Create: check phrase', route: DeskRoute.create, arg: CreateStep.confirm),
  const DeskShot(id: '03-restore', title: 'Restore: password', route: DeskRoute.restore, arg: RestoreStep.account),
  const DeskShot(id: '03b-restore-words', title: 'Restore: words', route: DeskRoute.restore, arg: RestoreStep.wordsFilled),
  const DeskShot(id: '04-setup', title: 'Setup: preferences', route: DeskRoute.setup, arg: SetupStep.prefs),
  const DeskShot(id: '04b-setup-node', title: 'Setup: node', route: DeskRoute.setup, arg: SetupStep.node),
  const DeskShot(id: '04c-setup-epicbox', title: 'Setup: Epicbox', route: DeskRoute.setup, arg: SetupStep.epicbox),
  const DeskShot(id: '04d-setup-review', title: 'Setup: review', route: DeskRoute.setup, arg: SetupStep.review),
  const DeskShot(id: '05-unlock', title: 'Unlock', route: DeskRoute.unlock),
  const DeskShot(id: '05b-unlock-error', title: 'Unlock: wrong password', route: DeskRoute.unlock, arg: 'error'),
  const DeskShot(id: '06-found', title: 'Wallets found', route: DeskRoute.found, arg: FoundVariant.found),
  const DeskShot(id: '07-add-existing', title: 'Add existing wallet', route: DeskRoute.found, arg: FoundVariant.addExisting),
  const DeskShot(id: '08-settings-error', title: 'Settings file error', route: DeskRoute.found, arg: FoundVariant.settingsError),
  const DeskShot(id: '09a-import-finding', title: 'Import: finding', route: DeskRoute.importWallets, arg: ImportStep.find),
  const DeskShot(id: '09b-import-found', title: 'Import: found', route: DeskRoute.importWallets, arg: ImportStep.found),
  const DeskShot(id: '09c-import-choose', title: 'Import: choose', route: DeskRoute.importWallets, arg: ImportStep.choose),
  const DeskShot(id: '09d-import-check', title: 'Import: check for use', route: DeskRoute.importWallets, arg: ImportStep.check),
  const DeskShot(id: '09e-import-copying', title: 'Import: copying', route: DeskRoute.importWallets, arg: ImportStep.copy),
  const DeskShot(id: '09f-import-settings', title: 'Import: settings', route: DeskRoute.importWallets, arg: ImportStep.settings),
  const DeskShot(id: '09g-import-done', title: 'Import: done', route: DeskRoute.importWallets, arg: ImportStep.done),
  DeskShot(
    id: '09h-dlg-import-stop',
    title: 'Stop the import?',
    route: DeskRoute.importWallets,
    arg: ImportStep.copy,
    dialog: (context) => showImportStopDialog(context),
  ),
  DeskShot(
    id: '09i-dlg-import-same-wallet',
    title: 'Same wallet as …',
    route: DeskRoute.importWallets,
    arg: ImportStep.choose,
    dialog: (context) => showImportSameWalletDialog(context, 'Wallet (epic program)', 'Everyday'),
  ),
  const DeskShot(id: '09j-import-none', title: 'Import: none found', route: DeskRoute.importWallets, arg: ImportStep.none),
  DeskShot(
    id: '09k-dlg-import-delete',
    title: 'Delete the old folder?',
    route: DeskRoute.importWallets,
    arg: ImportStep.done,
    dialog: (context) => showImportDeleteDialog(context, 'Savings', '~/EpicWallet-old/Savings'),
  ),
  DeskShot(
    id: '09l-dlg-import-picker',
    title: 'Choose a folder',
    route: DeskRoute.importWallets,
    arg: ImportStep.found,
    dialog: (context) => showImportPickerDialog(context),
  ),
];
