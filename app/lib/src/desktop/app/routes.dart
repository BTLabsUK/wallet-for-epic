/// Where the desktop UI is. One flat list of places; [DeskRoute.bare] places fill the window
/// (first run, unlock), the rest sit in the app shell with the sidebar.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../theme/icons.dart';
import 'package:flutter/widgets.dart' show IconData;

enum DeskSection { overview, activity, send, receive, invoices, outputs, contacts, settings }

enum DeskRoute {
  // Bare: the screens that open the app.
  welcome(bare: true),
  create(bare: true),
  restore(bare: true),
  setup(bare: true),
  unlock(bare: true),
  importWallets(bare: true),

  /// Forgot password: the wallet's phrase sets a new one ([ResetPasswordArg]).
  resetPassword(bare: true),

  // In the shell.
  overview(section: DeskSection.overview),
  activity(section: DeskSection.activity),
  send(section: DeskSection.send),
  receive(section: DeskSection.receive),
  importTx(section: DeskSection.receive),
  finalize(section: DeskSection.receive),

  /// Invoices: the To pay and Sent tabs ([InvoicesTab] or a slate id
  /// to select), the request form (a [Contact] or an invoice address to start from) and the
  /// review of one invoice (its slate id).
  invoices(section: DeskSection.invoices),
  invoiceIssue(section: DeskSection.invoices),
  invoiceReview(section: DeskSection.invoices),
  outputs(section: DeskSection.outputs),
  contacts(section: DeskSection.contacts),

  /// Pairing (RFC 0002): the Pair page (a [Contact] to attach to) and Pending invites.
  pair(section: DeskSection.contacts),
  pairPending(section: DeskSection.contacts),
  settingsNode(section: DeskSection.settings),
  settingsReceiving(section: DeskSection.settings),

  /// The one Tor switch and the status site (`settings_privacy.dart`).
  settingsPrivacy(section: DeskSection.settings),

  /// Invoices: the paired contacts allowed to bill this wallet, Pair with a shop or exchange,
  /// time to pay.
  settingsInvoices(section: DeskSection.settings),
  settingsAppearance(section: DeskSection.settings),
  settingsAccount(section: DeskSection.settings),

  /// This wallet on other devices (`devices/`): the devices, their servers, the coins they
  /// hold. Hidden while Linked devices is off.
  settingsDevices(section: DeskSection.settings),
  settingsWallets(section: DeskSection.settings),
  settingsPhrase(section: DeskSection.settings),
  settingsRescan(section: DeskSection.settings),

  /// The expert features' switches and the network mode (`settings_advanced.dart`).
  settingsAdvanced(section: DeskSection.settings),
  settingsAbout(section: DeskSection.settings),
  settingsHelp(section: DeskSection.settings);

  const DeskRoute({this.bare = false, this.section});

  final bool bare;
  final DeskSection? section;
}

/// A place plus what it needs: a transaction id on Activity, a contact on Send, a step.
class DeskLocation {
  const DeskLocation(this.route, [this.arg]);

  final DeskRoute route;
  final Object? arg;
}

/// The sidebar's entries, in order: the phone's (Activity, Outputs, Contacts, Invoices), then Send
/// and Receive.
const List<(DeskSection, DeskRoute, IconData)> deskNav = [
  (DeskSection.overview, DeskRoute.overview, EIcons.home),
  (DeskSection.activity, DeskRoute.activity, EIcons.activity),
  (DeskSection.outputs, DeskRoute.outputs, EIcons.coins),
  (DeskSection.contacts, DeskRoute.contacts, EIcons.contacts),
  // Shown only when the wallet supports invoices.
  (DeskSection.invoices, DeskRoute.invoices, EIcons.invoice),
  (DeskSection.send, DeskRoute.send, EIcons.send),
  (DeskSection.receive, DeskRoute.receive, EIcons.receive),
];

/// The sidebar's label of a place (the window title uses it too).
String deskNavLabel(AppLocalizations l, DeskSection s) => switch (s) {
  DeskSection.overview => l.deskShellNavOverview,
  DeskSection.activity => l.deskShellNavActivity,
  DeskSection.send => l.deskShellNavSend,
  DeskSection.receive => l.deskShellNavReceive,
  DeskSection.invoices => l.deskInvNav,
  DeskSection.outputs => l.deskShellNavOutputs,
  DeskSection.contacts => l.deskShellNavContacts,
  DeskSection.settings => l.deskShellNavSettings,
};

/// The tabs of Invoices: Pay (invoices to pay) and Issue (invoices this wallet issued).
enum InvoicesTab { pay, issue }

/// Start place: `--dart-define=WFE_DESK_START=<route name>`, unlock by default.
const String _start = String.fromEnvironment('WFE_DESK_START', defaultValue: 'unlock');

/// True when WFE_DESK_START names the start place; otherwise the app picks it (Welcome without
/// a wallet, Unlock with one) by overriding [deskStartProvider].
const bool deskStartGiven = bool.hasEnvironment('WFE_DESK_START');

/// Where the app opens.
final deskStartProvider = Provider<DeskRoute>((ref) => deskRouteNamed(_start));

DeskRoute deskRouteNamed(String name) =>
    DeskRoute.values.firstWhere((r) => r.name == name, orElse: () => DeskRoute.unlock);

/// The place and its history: Back and Forward like a browser. Going to the place already
/// shown adds nothing; going somewhere new drops the forward places.
class DeskNav extends Notifier<DeskLocation> {
  final List<DeskLocation> _history = [];
  final List<DeskLocation> _forward = [];

  /// Older places beyond this are forgotten.
  static const _keep = 50;

  @override
  DeskLocation build() => DeskLocation(ref.read(deskStartProvider));

  void go(DeskRoute route, [Object? arg]) {
    if (route == state.route && arg == state.arg) return;
    _history.add(state);
    if (_history.length > _keep) _history.removeAt(0);
    _forward.clear();
    state = DeskLocation(route, arg);
  }

  /// Replaces the place without history (after unlock, lock, finishing a flow).
  void reset(DeskRoute route, [Object? arg]) {
    _history.clear();
    _forward.clear();
    state = DeskLocation(route, arg);
  }

  bool get canBack => _history.isNotEmpty;

  bool get canForward => _forward.isNotEmpty;

  /// The previous place; an in-app page with no history goes to Overview.
  void back() {
    if (_history.isEmpty) {
      if (!state.route.bare && state.route != DeskRoute.overview) {
        _forward.add(state);
        state = const DeskLocation(DeskRoute.overview);
      }
      return;
    }
    _forward.add(state);
    state = _history.removeLast();
  }

  void forward() {
    if (_forward.isEmpty) return;
    _history.add(state);
    state = _forward.removeLast();
  }
}

final deskNavProvider = NotifierProvider<DeskNav, DeskLocation>(DeskNav.new);
