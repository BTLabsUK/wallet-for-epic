// SPDX-License-Identifier: Apache-2.0
/// The test drivers' stable names for the controls they press (`Semantics.identifier`, the
/// resource-id on Android). The same list is `tools/rellib/drivers/trust_ids.json`, which
/// `test/trust_ids_test.dart` keeps in step. An id never changes with the wording or the
/// language; a control without one is found by its label.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Whether the controls carry their ids. Off only in test/trust_ids_semantics_test.dart, which
/// builds each screen with and without ids and expects a screen reader to get the same tree.
@visibleForTesting
bool trustIdsOn = true;

/// Names a control for the drivers: [id] joins the semantics node that [child]'s own semantics
/// end in, and changes nothing else. `Semantics(identifier:)` is not used for this: an identifier
/// there starts a node of its own, which splits a control from the tooltip, label or button it
/// shares a node with (a password field read as its "Show" button). Around a widget that makes
/// its own node (a Material button or list tile), the mark goes inside it, on the label or the
/// icon: outside, the id lands on the node around the control, or on none.
class TrustId extends StatelessWidget {
  const TrustId(this.id, {super.key, required this.child});

  final String? id;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (trustIdsOn ? id : null) {
    final id? => _TrustIdMark(id, child: child),
    // No id: nothing in between, so the control's own render object is still the top one.
    null => child,
  };
}

class _TrustIdMark extends SingleChildRenderObjectWidget {
  const _TrustIdMark(this.id, {required Widget super.child});

  final String id;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTrustId(id);

  @override
  void updateRenderObject(BuildContext context, _RenderTrustId renderObject) => renderObject.id = id;
}

class _RenderTrustId extends RenderProxyBox {
  _RenderTrustId(this._id);

  String _id;
  set id(String value) {
    if (value == _id) return;
    _id = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.identifier = _id;
  }
}

/// [TrustId] around [child].
Widget trustId(String id, Widget child) => TrustId(id, child: child);

/// The ids of one server list (node or Epicbox).
class TrustServerIds {
  const TrustServerIds({required this.picker, required this.field, required this.row, required this.add});
  final String picker;
  final String field;
  final String row;
  final String add;
}

abstract final class TrustIds {
  static const welcomeCreate = 'g4.welcome.create';
  static const welcomeRestore = 'g4.welcome.restore';
  static const welcomeImport = 'g4.welcome.import';
  static const accountPassword = 'g4.account.password';
  static const accountConfirmPassword = 'g4.account.confirm';
  static const createSubmit = 'g4.create.submit';
  static const createReveal = 'g4.create.reveal';
  static const createWritten = 'g4.create.written';
  static const createContinue = 'g4.create.continue';
  static const setupSkip = 'g4.setup.skip';
  static const unlockPassword = 'g4.unlock.password';
  static const unlockSubmit = 'g4.unlock.submit';
  static const tourSkip = 'g4.tour.skip';
  static const navSettings = 'g4.nav.settings';
  static const appearanceThemeSystem = 'g4.appearance.theme.system';
  static const appearanceThemeDark = 'g4.appearance.theme.dark';
  static const appearanceThemeLight = 'g4.appearance.theme.light';
  static const walletLabel = 'g4.wallet.label';
  static const walletLabelSave = 'g4.wallet.label.save';
  static const confirmationsFewer = 'g4.confirmations.fewer';
  static const confirmationsMore = 'g4.confirmations.more';
  static const advancedTechnical = 'g4.advanced.technical';
  static const serverEpicboxSwitch = 'g4.server.epicbox.switch';
  static const receiveAddress = 'g4.receive.address';
  static const sendTo = 'g4.send.to';
  static const sendAmount = 'g4.send.amount';
  static const sendMax = 'g4.send.max';
  static const sendReview = 'g4.send.review';
  static const sendPassword = 'g4.send.password';
  static const sendConfirm = 'g4.send.confirm';
  static const sendAnother = 'g4.send.another';
  static const overviewRefresh = 'g4.overview.refresh';
  static const overviewAvailable = 'g4.overview.available';
  static const homeLock = 'g4.home.lock';
  static const homeSettings = 'g4.home.settings';
  static const backupAgree = 'g4.backup.agree';
  static const backupShow = 'g4.backup.show';
  static const backupDone = 'g4.backup.done';
  static const appearanceTheme = 'g4.appearance.theme';
  static const advancedLevel = 'g4.advanced.level';
  static const restorePhrase = 'g4.restore.phrase';
  static const restoreStart = 'g4.restore.start';
  static const restoreInfo = 'g4.restore.info';
  static const restoreByMonth = 'g4.restore.by.month';
  static const restoreByHeight = 'g4.restore.by.height';
  static const restoreMonth = 'g4.restore.month';
  static const restoreHeight = 'g4.restore.height';
  static const restoreFromStart = 'g4.restore.fromStart';
  static const restoreNext = 'g4.restore.next';
  static const restoreContinue = 'g4.restore.continue';
  static const restorePassword = 'g4.restore.password';
  static const restorePasswordConfirm = 'g4.restore.passwordConfirm';
  static const shellNavSettings = navSettings;
  static const epicboxSwitch = serverEpicboxSwitch;
  static const walletLabelField = walletLabel;
  static const walletSaveLabel = walletLabelSave;
  static const advancedTechnicalDetails = advancedTechnical;
  static const paymentsConfirmationsFewer = confirmationsFewer;
  static const paymentsConfirmationsMore = confirmationsMore;

  static const nodeList = TrustServerIds(picker: 'g4.server.node', field: serverSearch, row: 'g4.server.node.row', add: 'g4.server.node.add');
  static const epicboxList = TrustServerIds(picker: 'g4.server.epicbox', field: serverSearch, row: 'g4.server.epicbox.row', add: 'g4.server.epicbox.add');
  static const serverSearch = 'g4.server.search';

  /// A rail place: `g4.nav.<DeskSection.name>`.
  static String shellNav(String section) => 'g4.nav.$section';

  /// A Settings page of the desktop (`settingsNode` is `node`) or a group of the phone's hub
  /// (`SettingsSection.name`): `g4.settings.section.<name>`.
  static String settingsSection(String name) {
    final bare = name.startsWith('settings') && name.length > 8 ? name.substring(8) : name;
    return 'g4.settings.section.${bare[0].toLowerCase()}${bare.substring(1)}';
  }

  /// A level's stop on the dial: `g4.level.stop.<1-3>`.
  static String levelStop(int level) => 'g4.level.stop.$level';

  /// Every id above, spelled out.
  static const all = <String>[
    'g4.welcome.create',
    'g4.welcome.restore',
    'g4.welcome.import',
    'g4.account.password',
    'g4.account.confirm',
    'g4.create.submit',
    'g4.create.reveal',
    'g4.create.written',
    'g4.create.continue',
    'g4.setup.skip',
    'g4.unlock.password',
    'g4.unlock.submit',
    'g4.tour.skip',
    'g4.nav.overview',
    'g4.nav.activity',
    'g4.nav.send',
    'g4.nav.receive',
    'g4.nav.settings',
    'g4.settings.section.node',
    'g4.settings.section.receiving',
    'g4.settings.section.appearance',
    'g4.settings.section.account',
    'g4.settings.section.advanced',
    'g4.settings.section.about',
    'g4.level.stop.1',
    'g4.level.stop.2',
    'g4.level.stop.3',
    'g4.appearance.theme.system',
    'g4.appearance.theme.dark',
    'g4.appearance.theme.light',
    'g4.wallet.label',
    'g4.wallet.label.save',
    'g4.confirmations.fewer',
    'g4.confirmations.more',
    'g4.advanced.technical',
    'g4.server.node',
    'g4.server.epicbox',
    'g4.server.search',
    'g4.server.node.row',
    'g4.server.node.add',
    'g4.server.epicbox.row',
    'g4.server.epicbox.add',
    'g4.server.epicbox.switch',
    'g4.receive.address',
    'g4.send.to',
    'g4.send.amount',
    'g4.send.max',
    'g4.send.review',
    'g4.send.password',
    'g4.send.confirm',
    'g4.send.another',
    'g4.overview.refresh',
    'g4.overview.available',
    'g4.home.lock',
    'g4.home.settings',
    'g4.backup.agree',
    'g4.backup.show',
    'g4.backup.done',
    'g4.settings.section.security',
    'g4.settings.section.display',
    'g4.appearance.theme',
    'g4.advanced.level',
    'g4.restore.phrase',
    'g4.restore.start',
    'g4.restore.info',
    'g4.restore.by.month',
    'g4.restore.by.height',
    'g4.restore.month',
    'g4.restore.height',
    'g4.restore.fromStart',
    'g4.restore.next',
    'g4.restore.continue',
    'g4.restore.password',
    'g4.restore.passwordConfirm',
  ];
}
