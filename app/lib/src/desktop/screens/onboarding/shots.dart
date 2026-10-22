import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'create_screen.dart';
import 'import_wallets_screen.dart';
import 'kill_process_dialog.dart';
import 'onboarding_parts.dart';
import 'restore_screen.dart';
import 'setup_screen.dart';
import 'unlock_screen.dart';

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> onboardingShots = [
  const DeskShot(id: '01-welcome', title: 'Welcome', route: DeskRoute.welcome),
  const DeskShot(id: '01b-welcome-advanced', title: 'Welcome: advanced', route: DeskRoute.welcome, arg: 'advanced'),
  const DeskShot(id: '01c-welcome-add', title: 'Add a wallet', route: DeskRoute.welcome, arg: 'add'),
  const DeskShot(id: '02a-create', title: 'Create: password', route: DeskRoute.create, arg: CreateStep.account),
  const DeskShot(id: '02b-create-phrase', title: 'Create: recovery phrase', route: DeskRoute.create, arg: CreateStep.phrase),
  const DeskShot(id: '02c-create-confirm', title: 'Create: check phrase', route: DeskRoute.create, arg: CreateStep.confirm),
  const DeskShot(id: '02d-create-creating', title: 'Create: creating', route: DeskRoute.create, arg: CreateStep.creating),
  const DeskShot(id: '02e-create-failed', title: 'Create: failed', route: DeskRoute.create, arg: CreateStep.failed),
  const DeskShot(id: '02f-create-locking', title: 'Create: locking the open wallet', route: DeskRoute.create, arg: CreateStep.locking),
  const DeskShot(id: '03-restore', title: 'Restore: phrase', route: DeskRoute.restore, arg: RestoreStep.words),
  const DeskShot(id: '03b-restore-words', title: 'Restore: words', route: DeskRoute.restore, arg: RestoreStep.wordsFilled),
  const DeskShot(id: '03c-restore-password', title: 'Restore: password', route: DeskRoute.restore, arg: RestoreStep.account),
  const DeskShot(id: '03d-restore-restoring', title: 'Restore: restoring', route: DeskRoute.restore, arg: RestoreStep.restoring),
  const DeskShot(id: '03e-restore-failed', title: 'Restore: failed', route: DeskRoute.restore, arg: RestoreStep.failed),
  const DeskShot(id: '04-setup', title: 'Setup: preferences', route: DeskRoute.setup, arg: SetupStep.prefs),
  const DeskShot(id: '04b-setup-node', title: 'Setup: node', route: DeskRoute.setup, arg: SetupStep.node),
  const DeskShot(id: '04c-setup-epicbox', title: 'Setup: Epicbox', route: DeskRoute.setup, arg: SetupStep.epicbox),
  const DeskShot(id: '04d-setup-review', title: 'Setup: review', route: DeskRoute.setup, arg: SetupStep.review),
  const DeskShot(id: '05-unlock', title: 'Unlock', route: DeskRoute.unlock),
  const DeskShot(id: '05b-unlock-error', title: 'Unlock: wrong password', route: DeskRoute.unlock, arg: UnlockShow.wrongPassword),
  const DeskShot(id: '05c-unlock-progress', title: 'Unlock: unlocking', route: DeskRoute.unlock, arg: UnlockShow.progress),
  const DeskShot(id: '05d-unlock-failed', title: 'Unlock: failed', route: DeskRoute.unlock, arg: UnlockShow.failed),
  const DeskShot(id: '05e-unlock-missing', title: 'Unlock: folder missing', route: DeskRoute.unlock, arg: UnlockShow.missing),
  const DeskShot(id: '05f-unlock-added', title: 'Unlock: wallet added', route: DeskRoute.unlock, arg: UnlockAdded('Savings')),
  DeskShot(
    id: '05g-dlg-kill-process',
    title: 'Epic is already running',
    route: DeskRoute.unlock,
    dialog: (context) => showKillProcessDialog(context),
  ),
  const DeskShot(id: '09a-import-finding', title: 'Import: finding', route: DeskRoute.importWallets, arg: ImportStep.find),
  const DeskShot(id: '09b-import-found', title: 'Import: found', route: DeskRoute.importWallets, arg: ImportStep.found),
  const DeskShot(id: '09c-import-choose', title: 'Import: choose', route: DeskRoute.importWallets, arg: ImportStep.choose),
  const DeskShot(id: '09d-import-check', title: 'Import: check for use', route: DeskRoute.importWallets, arg: ImportStep.check),
  const DeskShot(id: '09e-import-passwords', title: 'Import: old passwords', route: DeskRoute.importWallets, arg: ImportStep.import),
  const DeskShot(id: '09g-import-done', title: 'Import: done', route: DeskRoute.importWallets, arg: ImportStep.done),
  DeskShot(
    id: '09h-dlg-import-stop',
    title: 'Stop the import?',
    route: DeskRoute.importWallets,
    arg: ImportStep.import,
    dialog: (context) => showImportStopDialog(context),
  ),
  const DeskShot(id: '09j-import-none', title: 'Import: none found', route: DeskRoute.importWallets, arg: ImportStep.none),
];
