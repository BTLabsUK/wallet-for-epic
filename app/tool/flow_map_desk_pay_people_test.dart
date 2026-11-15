// SPDX-License-Identifier: Apache-2.0
// Desktop flow map, part `pay-people`: the Send, Receive, Invoices, Contacts and Pairing states the
// desktop tour lacks (dialogs without a shot), rendered on the mock wallet exactly as
// tool/desktop_tour_test.dart does. Ids `fm-pay-people-...`. DESK_SHOTS_OUT, DESK_SHOTS_SIZE,
// DESK_SHOTS_LANG, SHOTS_META and LAYOUT_AUDIT work as in the tour.
//
//   flutter test tool/flow_map_desk_pay_people_test.dart
import 'package:epic_wallet/src/desktop/app/desk_window.dart' show PictureDeskWindow, deskWindowProvider;
import 'package:epic_wallet/src/desktop/app/shots.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/desktop/data/mock_hosts.dart';
import 'package:epic_wallet/src/desktop/desk_l10n.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_entry.dart' show openDeskPayInPerson;
import 'package:epic_wallet/src/desktop/screens/invoices/pay_dialogs.dart' show showApproveRequestFile;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart' show tapShotKey;
import 'package:epic_wallet/src/desktop/screens/transfer/import_tx_screen.dart' show ImportArgs;
import 'package:epic_wallet/src/desktop/screens/transfer/link_trust.dart' show showLinkNoPayments, showLinkRefusal;
import 'package:epic_wallet/src/desktop/screens/transfer/qr_payment.dart' show DeskQrKind, showDeskSlateQr;
import 'package:epic_wallet/src/desktop/screens/transfer/send_code.dart' show showCodeDialog, showSlateTextDialog;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/models.dart' show PairingState, PairingFailure;
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingsProvider;
import 'package:epic_wallet/src/pairing_fake.dart' show FakePairing;
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/camera/camera_presence.dart' show FakeCameraProbe, cameraProbeProvider;
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/devices_state.dart' show deskDeviceClockProvider;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingRefusalsProvider;
import 'package:epic_wallet/src/name_service/payment_refusals.dart' show paymentRefusalsProvider;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:epic_wallet/src/server_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show GestureBinding, PointerDownEvent, PointerUpEvent;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_audit.dart';
import 'shot_meta.dart';

final String _out = Platform.environment['DESK_SHOTS_OUT'] ?? 'build/desk_shots';
final bool _light = Platform.environment['DESK_SHOTS_LIGHT'] == '1';
final String? _helpLanguage = Platform.environment['DESK_SHOTS_HELP'];
final int _scale = int.tryParse(Platform.environment['DESK_SHOTS_SCALE'] ?? '') ?? 100;
final String _lang = Platform.environment['DESK_SHOTS_LANG'] ?? 'en';

final Size? _size = () {
  final m = RegExp(r'^(\d+)x(\d+)$').firstMatch(Platform.environment['DESK_SHOTS_SIZE'] ?? '');
  return m == null ? null : Size(double.parse(m[1]!), double.parse(m[2]!));
}();

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  final cjk = _lang == 'zh';
  if (cjk) {
    // The first face of each collection; it has Latin, Cyrillic and Han glyphs.
    for (final weight in ['Regular', 'Bold']) {
      roboto.addFont(read('/usr/share/fonts/opentype/noto/NotoSansCJK-$weight.ttc'));
    }
  } else {
    for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
      roboto.addFont(read('$dir/$face'));
    }
  }
  await roboto.load();
  for (final (family, file) in [
    if (cjk) ('Montserrat', '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc') else ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    if (cjk) ('JetBrainsMonoNL', '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc') else ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'), // the icon font is not loaded by the test binding
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  // The Thai font of the fallback (bundledFallback), for Help in Thai.
  final thai = FontLoader('NotoSansThai');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    thai.addFont(read('assets/fonts/NotoSansThai-$weight.ttf'));
  }
  await thai.load();
  // The bundled Chinese fallback (cjkFamily).
  await (FontLoader('NotoSansSCSubset')..addFont(read('assets/fonts/NotoSansSCSubset.otf'))).load();
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

/// The fixture PNG for an icon URL, by its hash.
Future<Uint8List?> _fixtureIcon(Uri url) async {
  final hash = RegExp(r'([0-9a-f]{20})-[0-9]+[.]png$').firstMatch(url.path)?.group(1);
  final f = File('test/fixtures/icons/$hash-128.png');
  return f.existsSync() ? f.readAsBytesSync() : null;
}


// ---- helpers ----

typedef _Step = Future<void> Function(ProviderContainer c, BuildContext ctx);

MockDeskWallet _w(ProviderContainer c) => c.read(deskApiProvider) as MockDeskWallet;
FakePairing _pair(ProviderContainer c) => _w(c).pairing;

/// A tap at the middle of the first widget under [ctx] that [match] accepts.
void _tapWhere(BuildContext ctx, bool Function(Widget) match, {bool last = false}) {
  Element? found;
  void visit(Element e) {
    if (found != null && !last) return;
    if (match(e.widget)) {
      found = e;
      if (!last) return;
    }
    e.visitChildren(visit);
  }

  ctx.visitChildElements(visit);
  final box = found?.renderObject as RenderBox?;
  if (box == null || !box.hasSize) throw StateError('nothing to tap');
  final at = box.localToGlobal(box.size.center(Offset.zero));
  GestureBinding.instance
    ..handlePointerEvent(PointerDownEvent(position: at))
    ..handlePointerEvent(PointerUpEvent(position: at));
}

/// Taps the first text on stage that reads [text].
void _tapText(BuildContext ctx, String text, {bool last = false}) =>
    _tapWhere(ctx, (w) => w is Text && (w.data == text || w.textSpan?.toPlainText() == text), last: last);

/// The root context's strings.
AppLocalizations _l(BuildContext ctx) => ctx.l10n;

Future<void> _openCoffeeReview(ProviderContainer c, BuildContext _) async {
  final waiting = (await _w(c).invoices()).waiting;
  await c.read(deskInvoicesProvider.notifier).load();
  c.read(deskNavProvider.notifier).go(DeskRoute.invoiceReview, waiting.firstWhere((i) => i.label == 'Merchant: Coffee').slateId);
}

const _payeeAddr = 'esTk7uLfB3hJd9gA4sXeR6pTnC1vK8xHwP2bZr8mQ2pVtW5kNcY';
const _slateJson = '{"id":"0436430c-2b02-624c-2032-570501212b00","amt":"12500000000","sta":"S1"}';

final Map<String, List<_Step>> _more = {};

DeskShot _shot(String name, String title, DeskRoute route, {Object? arg, Future<void> Function(ProviderContainer)? before, _Step? prepare, Future<void> Function(BuildContext)? dialog, List<_Step> then = const [], double w = 1280, double h = 800}) {
  final id = 'fm-pay-people-$name';
  if (then.isNotEmpty) _more[id] = then;
  return DeskShot(id: id, title: title, route: route, arg: arg, before: before, prepare: prepare, dialog: dialog, width: w, height: h);
}

final List<DeskShot> _shots = [
  // ---- Send: dialogs over the form ----
  _shot('send-slate-text', 'Send: a pasted transaction file', DeskRoute.send, dialog: (ctx) async => showSlateTextDialog(ctx, onOpen: () {})),
  _shot('send-code-not-epic', 'Send: pasted text that is no payment code', DeskRoute.send,
      dialog: (ctx) async => showCodeDialog(ctx, icon: EIcons.qr, title: _l(ctx).scanNotEpicTitle, text: _l(ctx).scanNotEpicBody, code: 'https://example.org/pay/42')),
  _shot('send-code-wrong-network', 'Send: pasted address of another network', DeskRoute.send,
      dialog: (ctx) async => showCodeDialog(ctx, icon: Icons.public_off, title: _l(ctx).scanWrongNetworkTitle, text: _l(ctx).scanWrongNetworkBody, code: '$_payeeAddr@$mockBox')),
  _shot('send-link-refused', 'Send: a link that is refused', DeskRoute.send, dialog: (ctx) async => showLinkRefusal(ctx, _l(ctx).linkChanged)),
  _shot('send-link-no-payments', 'Send: a link to a contact that takes no payments', DeskRoute.send, dialog: (ctx) async => showLinkNoPayments(ctx, 'Northwind')),
  _shot('qr-slate-payment', 'Show QR: a payment file', DeskRoute.send, dialog: (ctx) => showDeskSlateQr(ctx, kind: DeskQrKind.payment, json: _slateJson, onScanReply: () {})),
  _shot('qr-slate-request', 'Show QR: an invoice request', DeskRoute.invoiceIssue, dialog: (ctx) => showDeskSlateQr(ctx, kind: DeskQrKind.request, json: _slateJson)),
  _shot('in-person-send', 'Send: Pay in person', DeskRoute.send, dialog: openDeskPayInPerson),

  // ---- Invoices ----
  _shot('invoices-decline', 'Review invoice: Decline asks to confirm', DeskRoute.invoices, prepare: _openCoffeeReview,
      then: [(c, ctx) async => _tapText(ctx, _l(ctx).invoiceDecline)]),
  _shot('invoices-approve-file', 'Approve a request file: password', DeskRoute.invoices, arg: InvoicesTab.pay,
      dialog: (ctx) async {
        final f = await ProviderScope.containerOf(ctx, listen: false).read(deskApiProvider).readRequestText('{"sta":"I1"}');
        if (f != null && ctx.mounted) unawaited(showApproveRequestFile(ctx, f));
      }),
  _shot('invoices-withdraw', 'Invoices › Issue: Withdraw asks to confirm', DeskRoute.invoices, arg: InvoicesTab.issue,
      then: [(c, ctx) async => _tapText(ctx, _l(ctx).deskInvIssuerWithdraw)]),
  _shot('invoices-cancel-request', 'Invoices › Issue: Cancel payment of a paid, unposted request', DeskRoute.invoices, arg: InvoicesTab.issue,
      prepare: (c, _) async {
        _w(c).proto.setNet(ProtoNet.nodeDown);
        _w(c).proto.payerPays();
        await c.read(deskInvoicesProvider.notifier).load();
      },
      h: 1000,
      then: [(c, ctx) async => _tapText(ctx, _l(ctx).deskInvAdvanced), (c, ctx) async => _tapText(ctx, _l(ctx).deskInvIssuerCancel)]),
  _shot('invoices-request-file', 'Open a request file: Approve and pay', DeskRoute.importTx, arg: const ImportArgs(text: '{"id":"0436430c-2b02-624c-2032-570501212b00","sta":"I1"}')),

  // ---- Pairing ----
  _shot('pair-name', 'Pair: They see you as, change', DeskRoute.pair, then: [(c, ctx) async => tapShotKey(ctx, deskPairChangeNameKey)]),
  for (final f in [PairingFailure.expired, PairingFailure.changedOnTheWay, PairingFailure.cancelled])
    _shot('pair-outcome-${f.name}', 'Pair: outcome ${f.name}', DeskRoute.pair, dialog: (ctx) => showDeskOutcome(ctx, f, name: 'Anna')),
  _shot('pair-matched', 'Pair: words match, pairing already in a contact', DeskRoute.pair,
      prepare: (c, _) async {
        _pair(c).seedPaired(id: 'p-anna-2', name: 'Anna Kowalska', state: PairingState.verified, contactId: 'c1');
        c.invalidate(deskPairingsProvider);
      },
      dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => const DeskMatchedResult(pairingId: 'p-anna-2'))),
];

void main() {
  setUpAll(_loadFonts);
  // The screens show the shipped servers (the tour is not under test/, so no test settings are loaded).
  hostSettings = HostSettings.fromText(
    File('assets/config/settings.default.toml').readAsStringSync(),
    config: AppConfig.fromText(File('assets/config/app-config.toml').readAsStringSync()),
  );
  shippedHostSettings = hostSettings;
  // BADGE_LOOK=bare|outline|ghost renders another badge direction (badge.dart).
  final look = Platform.environment['BADGE_LOOK'];
  if (look != null) badgeLook = BadgeLook.values.byName(look);
  final all = _shots;
  // The invoice shots start from a seeded book.
  final experimental = {...all.map((s) => s.id)};

  for (final shot in all) {
    testWidgets(shot.id, (tester) async {
      tester.view.physicalSize = _size ?? Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final wallet = MockDeskWallet(delay: Duration.zero, seedInvoices: experimental.contains(shot.id), otherWalletRows: shot.id.contains('other-wallet'));
      final container = ProviderContainer(
        overrides: [
          deskApiProvider.overrideWithValue(wallet),
          // The app's own refusals, as main_desktop.dart sets them: a card that takes no payments.
          paymentRefusalsProvider.overrideWith((ref) => ref.watch(deskPairingRefusalsProvider)),
          // The devices' book is kept in memory, and their times follow the mock's pairing clock.
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          deskDeviceClockProvider.overrideWithValue(() => wallet.pairing.clock()),
          // The operators' icons status.btlabs.uk serves, from the test fixtures.
          serverIconFetchProvider.overrideWithValue(_fixtureIcon),
          // The title bar with its window controls, as the app draws them on Linux.
          deskWindowProvider.overrideWithValue(const PictureDeskWindow()),
          // A laptop with its camera: Scan is offered (the scan shots set their own answer).
          cameraProbeProvider.overrideWithValue(FakeCameraProbe()),
        ],
        retry: (_, _) => null,
      );
      var closed = false;
      addTearDown(() => closed ? null : container.dispose());
      // A first-start shot holds the gate (onboarding/shots.dart); the next shot starts open.
      addTearDown(NetGate.releaseFirstStart);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      final s = container.read(deskProvider).settings;
      await tester.runAsync(
        () => container.read(deskProvider.notifier).saveSettings(s.copyWith(
          theme: _light ? ThemeChoice.light : null,
          scale: _scale,
          language: () => _lang,
          helpLanguage: _helpLanguage == null ? null : () => _helpLanguage,
        )),
      );
      if (shot.before != null) await tester.runAsync(() => shot.before!(container));
      container.read(deskNavProvider.notifier).reset(shot.route, shot.arg);

      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: boundary, child: const DeskApp()),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        }
      }

      await settle();
      final ctx = tester.element(find.byType(DeskRoot));
      if (shot.prepare != null) {
        await tester.runAsync(() => shot.prepare!(container, ctx));
        await settle();
      }
      if (shot.after != null) {
        await tester.runAsync(() => shot.after!(container, ctx));
        await settle();
      }
      for (final step in _more[shot.id] ?? const <_Step>[]) {
        await tester.runAsync(() => step(container, ctx));
        await settle();
      }
      if (shot.opensDialog) {
        // The dialog opens once an estimate came back (real time and frames): wait for it.
        for (var i = 0; i < 60 && find.byType(Dialog).evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        }
        expect(find.byType(Dialog), findsOneWidget, reason: '${shot.id} opens a dialog');
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }
      if (shot.dialog != null) {
        // Not awaited: it completes when the dialog closes.
        shot.dialog!(ctx);
        await settle();
        await tester.pump(const Duration(milliseconds: 400));
      }

      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File('$_out/${_lang == 'en' ? '' : '$_lang/'}${shot.id}${_light ? '-light' : ''}${_scale == 100 ? '' : '-s$_scale'}${_helpLanguage == null ? '' : '-help-$_helpLanguage'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        if (layoutAudit) writeLayoutAudit(file.path, boundary.currentContext! as Element, deskScale);
        if (shotMeta) {
          writeShotMeta(file.path, boundary.currentContext! as Element, {
            'id': shot.id,
            'title': shot.title,
            'route': shot.route.name,
            if (shot.arg != null) 'arg': '${shot.arg}',
            'dialog': shot.dialog != null || shot.opensDialog,
            'width': (_size?.width ?? shot.width).round(),
            'height': (_size?.height ?? shot.height).round(),
            'theme': _light ? 'light' : 'dark',
            'lang': _lang,
            'scale': _scale,
            'experimental': experimental.contains(shot.id),
          });
        }
      });
      // Anything drawn with an overflow or thrown while building fails the shot.
      expect(tester.takeException(), isNull);
      // The app goes first, then its services: a dialog closing with the tree may start a timer.
      await tester.pumpWidget(const SizedBox());
      closed = true;
      container.dispose();
    });
  }
}
