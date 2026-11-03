// SPDX-License-Identifier: Apache-2.0
import '../../../levels/first_start.dart' show firstStartProvider;
import '../../../network_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../data/mock_wallet.dart' show MockDeskWallet;
import '../../widgets/kit.dart';
import 'create_screen.dart';
import 'import_warning.dart';
import 'import_wallets_screen.dart';
import 'onboarding_parts.dart';
import 'restore_screen.dart';
import '../settings/shots.dart' show openInfoHint, tapShotKey;
import '../../../ui/scan_start.dart' show ScanStart;
import 'same_wallet_dialog.dart';
import 'local_node_step.dart' show LocalNodeShot;
import 'setup_screen.dart';
import 'unlock_screen.dart';

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> onboardingShots = [
  // The first start of a fresh install, as the user meets it: the doors and, in Tor builds,
  // the Tor only switch (no view picker). The tour harness releases the hold after the shot.
  DeskShot(id: '00a-first-start', title: 'First start', route: DeskRoute.welcome, before: _firstStart),
  DeskShot(id: '00b-first-start-tor-only', title: 'First start: Tor only on', route: DeskRoute.welcome, arg: 'tor-only', before: _firstStart),
  const DeskShot(id: '01-welcome', title: 'Welcome', route: DeskRoute.welcome),
  const DeskShot(id: '01b-welcome-advanced', title: 'Welcome: advanced', route: DeskRoute.welcome, arg: 'advanced'),
  const DeskShot(id: '01c-welcome-add', title: 'Add a wallet', route: DeskRoute.welcome, arg: 'add'),
  const DeskShot(id: '02a-create', title: 'Create: password', route: DeskRoute.create, arg: CreateStep.account),
  const DeskShot(id: '02b-create-phrase', title: 'Create: recovery phrase', route: DeskRoute.create, arg: CreateStep.phrase),
  const DeskShot(id: '02c-create-phrase-shown', title: 'Create: recovery phrase, shown', route: DeskRoute.create, arg: CreateShot.phraseShown),
  const DeskShot(id: '02d-create-creating', title: 'Create: creating', route: DeskRoute.create, arg: CreateStep.creating),
  const DeskShot(id: '02e-create-failed', title: 'Create: failed', route: DeskRoute.create, arg: CreateStep.failed),
  const DeskShot(id: '02f-create-locking', title: 'Create: locking the open wallet', route: DeskRoute.create, arg: CreateStep.locking),
  const DeskShot(id: '03-restore', title: 'Restore: phrase', route: DeskRoute.restore, arg: RestoreStep.words),
  const DeskShot(id: '03b-restore-words', title: 'Restore: a word off the list', route: DeskRoute.restore, arg: RestoreStep.wordsFilled),
  const DeskShot(
    id: '03b2-restore-typing',
    title: 'Restore: typing, the completion dim',
    route: DeskRoute.restore,
    arg: RestoreSample('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abo', typing: true),
  ),
  const DeskShot(
    id: '03b3-restore-pasted-24',
    title: 'Restore: 24 words pasted',
    route: DeskRoute.restore,
    arg: RestoreSample(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art',
    ),
  ),
  const DeskShot(
    id: '03b4-restore-pasted-12',
    title: 'Restore: 12 words pasted',
    route: DeskRoute.restore,
    arg: RestoreSample('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'),
  ),
  const DeskShot(
    id: '03b5-restore-bad-checksum',
    title: 'Restore: the check number does not match',
    route: DeskRoute.restore,
    arg: RestoreSample('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon'),
  ),
  const DeskShot(
    id: '03b6-restore-13-words',
    title: 'Restore: 13 words pasted',
    route: DeskRoute.restore,
    arg: RestoreSample('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon'),
  ),
  DeskShot(
    id: '03b7-dlg-restore-same-wallet',
    title: 'Restore: the phrase is already here',
    route: DeskRoute.restore,
    arg: const RestoreSample(MockDeskWallet.samePhrase),
    dialog: (c) => showSameWalletDialog(
      c,
      const WalletEntry(id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', name: 'Savings', folder: '~/.epic_cash_desktop/wallets/5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', network: 'mainnet'),
    ),
  ),
  const DeskShot(id: '03c-restore-password', title: 'Restore: password', route: DeskRoute.restore, arg: RestoreStep.account),
  DeskShot(
    id: '03c2-restore-start-open',
    title: 'Restore: the scan start open (month or height)',
    route: DeskRoute.restore,
    arg: RestoreStep.account,
    prepare: (_, ctx) async => tapShotKey(ctx, ScanStart.changeKey),
  ),
  DeskShot(
    id: '03c3-restore-month-open',
    title: 'Restore: the month picker open',
    route: DeskRoute.restore,
    arg: RestoreStep.account,
    prepare: (_, ctx) async => tapShotKey(ctx, ScanStart.changeKey),
    after: (_, ctx) async => tapShotKey(ctx, EStartMonthField.fieldKey),
  ),
  DeskShot(
    id: '03c4-restore-start-info',
    title: 'Restore: the scan start\u2019s info, with Scan from the start',
    route: DeskRoute.restore,
    arg: RestoreStep.account,
    dialog: (ctx) => openInfoHint(ctx, title: (l) => l.scanStartInfoTitle),
  ),
  const DeskShot(id: '03d-restore-restoring', title: 'Restore: restoring', route: DeskRoute.restore, arg: RestoreStep.restoring),
  const DeskShot(id: '03e-restore-failed', title: 'Restore: failed', route: DeskRoute.restore, arg: RestoreStep.failed),
  const DeskShot(id: '04-setup', title: 'Setup: preferences', route: DeskRoute.setup, arg: SetupStep.prefs),
  const DeskShot(id: '04b-setup-node', title: 'Setup: node', route: DeskRoute.setup, arg: SetupStep.node),
  const DeskShot(id: '03-setup-node', title: 'Setup: choose a node', route: DeskRoute.setup, arg: SetupStep.node),
  const DeskShot(id: '03b-setup-local', title: 'Setup: the local node step', route: DeskRoute.setup, arg: SetupShot(SetupStep.local)),
  const DeskShot(id: '03c-setup-existing', title: 'Setup: a node already running here', route: DeskRoute.setup, arg: SetupShot(SetupStep.local, local: LocalNodeShot.found)),
  const DeskShot(id: '03d-setup-notfound', title: 'Setup: no node answers', route: DeskRoute.setup, arg: SetupShot(SetupStep.local, local: LocalNodeShot.notFound)),
  const DeskShot(id: '03e-setup-review', title: 'Setup: review with the local node', route: DeskRoute.setup, arg: SetupShot(SetupStep.review, localChosen: true)),
  const DeskShot(id: '03f-setup-node-list', title: 'Setup: the node list open', route: DeskRoute.setup, arg: SetupShot(SetupStep.node, listOpen: true)),
  const DeskShot(id: '04c-setup-epicbox', title: 'Setup: Epicbox', route: DeskRoute.setup, arg: SetupStep.epicbox),
  const DeskShot(id: '04e-setup-epicbox-list', title: 'Setup: the Epicbox list open', route: DeskRoute.setup, arg: SetupShot(SetupStep.epicbox, listOpen: true)),
  const DeskShot(id: '04d-setup-review', title: 'Setup: review', route: DeskRoute.setup, arg: SetupStep.review),
  const DeskShot(id: '04f-setup-save-failed', title: 'Setup: Save failed on a first run', route: DeskRoute.setup, arg: SetupShot(SetupStep.review, first: SetupFirstRun(UnlockAdded('Wallet', id: 'shot')), saveFailed: true)),
  const DeskShot(id: '04g-setup-resumed', title: 'Setup: resumed after a restart', route: DeskRoute.setup, arg: SetupShot(SetupStep.node, first: SetupFirstRun(UnlockAdded('Wallet', id: 'shot'), resumed: true))),
  const DeskShot(id: '05-unlock', title: 'Unlock', route: DeskRoute.unlock),
  const DeskShot(id: '05b-unlock-error', title: 'Unlock: wrong password', route: DeskRoute.unlock, arg: UnlockShow.wrongPassword),
  const DeskShot(id: '05c-unlock-progress', title: 'Unlock: unlocking', route: DeskRoute.unlock, arg: UnlockShow.progress),
  const DeskShot(id: '05c2-unlock-encrypting', title: 'Unlock: encrypting records', route: DeskRoute.unlock, arg: UnlockShow.encrypting),
  const DeskShot(id: '05d-unlock-failed', title: 'Unlock: failed', route: DeskRoute.unlock, arg: UnlockShow.failed),
  const DeskShot(id: '05e-unlock-missing', title: 'Unlock: folder missing', route: DeskRoute.unlock, arg: UnlockShow.missing),
  const DeskShot(id: '05h-unlock-list', title: 'Unlock: the wallet list open', route: DeskRoute.unlock, arg: UnlockShow.listOpen),
  const DeskShot(id: '05f-unlock-added', title: 'Unlock: wallet added', route: DeskRoute.unlock, arg: UnlockAdded('Savings', id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f')),
  DeskShot(id: '09-dlg-import-warning', title: 'Before you import', route: DeskRoute.welcome, dialog: (context) => showImportWarningDialog(context)),
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

/// A fresh install still to answer the first-start step: the gate held, as at launch.
Future<void> _firstStart(ProviderContainer c) async {
  NetGate.holdFirstStart();
  c.invalidate(firstStartProvider);
}
