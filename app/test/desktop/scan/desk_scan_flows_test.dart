// SPDX-License-Identifier: Apache-2.0
// Scan on the rest of the desktop's code entries: pairing (invite and answer), Link a device,
// in person (answer scan, animated parts, a part without or with a camera), the contacts address
// field, epic1 link send, reset password, and the smart scan (Home). The paste-instead path
// (DeskPasted) is covered once, in the smart scan. The origin (qr or paste) is read from the
// route argument the smart scan hands to Send; the screens' own scans do not show it before the
// review, so it is not covered there.
import 'dart:async';
import 'dart:convert';

import 'package:epic_wallet/src/camera/camera_presence.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/devices/link_flow.dart';
import 'package:epic_wallet/src/desktop/screens/epic1/send_link.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_entry.dart';
import 'package:epic_wallet/src/desktop/screens/in_person/in_person_reader.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/reset_password_screen.dart';
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/screens/scan/desk_scan.dart';
import 'package:epic_wallet/src/desktop/screens/scan/desk_scan_route.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_devices.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/devices/device_link_code.dart' show deviceLinkText;
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_text.dart' show pairReplyFallbackAfter;
import 'package:epic_wallet/src/scan/scan_checks.dart' show CodeOrigin;
import 'package:epic_wallet/src/ui/in_person/in_person_scan.dart' show InPersonScanned;
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;

const _e = 'esTk4wRm8Nq2Vx7Lc5Bh9Jd3Fg6Hs1Ka8Pz4Yu2Wn7Ec5Rt9Q@box.epic.invalid';

/// A send code's bytes, as the in-person tests make one.
final _codeBytes = [InPersonStage.send.index, ...List.filled(32, 7)];
final _codePart = 'ur:epic1/${base64Url.encode(_codeBytes)}';

/// A fake whose animated code needs two parts.
class _TwoParts extends FakeEpic1 {
  _TwoParts({super.on});

  @override
  InPersonQrProgress qrRead(List<String> parts) {
    if (parts.length < 2) return InPersonQrProgress(complete: false, received: parts.length, total: 2);
    final b = base64Url.decode(parts.first.replaceFirst('ur:epic1/', ''));
    return InPersonQrProgress(complete: true, received: 2, total: 2, bytes: Uint8List.fromList(b));
  }
}

class _Mock extends MockDeskWallet {
  _Mock(this.fake) : super(delay: Duration.zero);
  final FakeEpic1 fake;

  @override
  Epic1Wallet? get epic1 => fake;
}

late ProviderContainer _c;
final List<FakeQrCamera> _cams = [];
String? _clip;

FakeQrCamera get _cam => _cams.last;

Future<void> _settle(WidgetTester tester, {int n = 8}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _show(WidgetTester tester, Widget screen, {MockDeskWallet? api, CameraPresence presence = CameraPresence.present}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _cams.clear();
  _clip = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') return <String, Object?>{'text': _clip};
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  _c = ProviderContainer(overrides: [
    deskApiProvider.overrideWithValue(api ?? MockDeskWallet(delay: Duration.zero)),
    qrCameraFactoryProvider.overrideWithValue(() {
      final c = FakeQrCamera();
      _cams.add(c);
      return c;
    }),
    cameraProbeProvider.overrideWithValue(FakeCameraProbe(presence)),
  ]);
  addTearDown(_c.dispose);
  await tester.runAsync(() => _c.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await _settle(tester);
}

/// Taps [button], lets the dialog open, and has the camera read [text].
Future<void> _scanWith(WidgetTester tester, Finder button, String text) async {
  await tester.tap(button);
  await _settle(tester, n: 3);
  _cam.emit(text);
  await _settle(tester);
}

String _fieldText(WidgetTester tester, Finder within) => tester.widget<EditableText>(find.descendant(of: within, matching: find.byType(EditableText)).first).controller.text;

/// A page with one button that runs the smart scan.
Widget _home() => Consumer(
  builder: (context, ref, _) => TextButton(onPressed: () => unawaited(openDeskScan(context, ref)), child: const Text('scan')),
);

void main() {
  setUpAll(initializeDateFormatting);
  setUp(deskForgetOpenChecks);

  group('pairing', () {
    testWidgets('the invite field takes a scanned invite', (tester) async {
      final api = MockDeskWallet(delay: Duration.zero);
      await _show(tester, const DeskPairScreen(), api: api);
      final invite = api.pairing.inviteLinkFrom(name: 'Anna');
      await _scanWith(tester, find.byKey(deskPairScanKey), invite);
      expect(_fieldText(tester, find.byKey(deskPairEnterKey)), invite);
    });

    testWidgets('the answer field of the wait takes a scanned confirmation and opens the words', (tester) async {
      final api = MockDeskWallet(delay: Duration.zero);
      await _show(tester, const DeskPairScreen(), api: api);
      await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), api.pairing.inviteLinkFrom(name: 'Anna'));
      await tester.pump();
      await tester.tap(find.byKey(deskPairGoKey));
      await _settle(tester);
      await tester.tap(find.byKey(deskIncomingPairKey));
      await _settle(tester);
      await tester.pump(pairReplyFallbackAfter + const Duration(seconds: 1));
      await _settle(tester);
      final answered = (await tester.runAsync(api.pairing.pairings))!.firstWhere((r) => r.id.isNotEmpty);
      await _scanWith(tester, find.byKey(deskWaitingScanKey), fakePairingLink('pair-confirm', {'t': answered.id}));
      expect(find.text(_l.sasDialogTitle('Anna')), findsOneWidget);
    });
  });

  testWidgets('Link a device: the paste field takes a scanned code', (tester) async {
    await _show(tester, const DevicesSettingsBlock());
    await tester.tap(find.byKey(devicesLinkKey));
    await _settle(tester);
    await tester.tap(find.text(_l.linkPaste));
    await _settle(tester);
    final code = deviceLinkText('epiccash://invite/x', fingerprint: '0123456789abcdef');
    await _scanWith(tester, find.byKey(deskLinkScanKey), code);
    expect(_fieldText(tester, find.byKey(deskLinkPasteFieldKey)), code);
  });

  group('in person', () {
    Future<_TwoParts> waiting(WidgetTester tester) async {
      final fake = _TwoParts(on: true);
      await _show(tester, Builder(builder: (c) => TextButton(onPressed: () => openDeskPayInPerson(c), child: const Text('pay'))), api: _Mock(fake));
      await tester.tap(find.text('pay'));
      await _settle(tester);
      await tester.enterText(find.byKey(deskInPersonAmountKey), '1.5');
      await tester.enterText(find.byKey(deskInPersonPasswordKey), 'secret');
      await tester.pump();
      await tester.tap(find.text(_l.deskIpMakeCode));
      await _settle(tester);
      return fake;
    }

    testWidgets('the answer scan: an animated code over qrRead, two parts', (tester) async {
      final fake = await waiting(tester);
      await tester.tap(find.byKey(deskIpScanKey));
      await _settle(tester, n: 3);
      _cam.emit(_codePart);
      await _settle(tester, n: 3);
      expect(fake.calls, isNot(contains('inPersonTake')), reason: 'one part is not a code');
      _cam.emit('ur:epic1/second');
      await _settle(tester);
      expect(fake.calls, contains('inPersonTake'));
      expect(find.text(_l.deskIpCheckOther('4821')), findsOneWidget);
    });

    testWidgets('the answer scan: a plain-text answer is taken as pasted', (tester) async {
      final fake = await waiting(tester);
      await _scanWith(tester, find.byKey(deskIpScanKey), 'BEGINEPICTX. answer. ENDEPICTX.');
      expect(fake.calls, contains('inPersonTake'));
      expect(find.text(_l.deskIpCheckOther('4821')), findsOneWidget);
    });

    test('the reader keeps parts, ignores a repeat and finishes on the last', () {
      final r = DeskInPersonReader(_TwoParts(on: true));
      expect(r.read(_codePart), isA<DeskPartWaiting<InPersonScanned>>());
      expect(r.read(_codePart), isA<DeskPartWaiting<InPersonScanned>>());
      final done = r.read('ur:epic1/second');
      expect(done, isA<DeskPartDone<InPersonScanned>>());
      expect((done as DeskPartDone<InPersonScanned>).value.bytes, _codeBytes);
      expect((DeskInPersonReader(_TwoParts(on: true)).read('BEGINEPICTX. a. ENDEPICTX.') as DeskPartDone<InPersonScanned>).value.text, 'BEGINEPICTX. a. ENDEPICTX.');
    });

    Future<Future<bool>> partOpened(WidgetTester tester, CameraPresence presence) async {
      await _show(tester, Builder(builder: (c) => TextButton(onPressed: () {}, child: const Text('page'))), api: _Mock(_TwoParts(on: true)), presence: presence);
      final ctx = tester.element(find.text('page'));
      return openDeskInPersonText(ctx, _codePart);
    }

    testWidgets('a first part of an animated code with a camera: the scan reads the rest and opens the review', (tester) async {
      final opened = await partOpened(tester, CameraPresence.present);
      unawaited(opened);
      await _settle(tester, n: 6);
      expect(_cams, isNotEmpty, reason: 'the scan dialog is open');
      _cam.emit('ur:epic1/second');
      await _settle(tester);
      expect(find.text(_l.deskIpReceiveTitle), findsOneWidget);
    });

    testWidgets('a first part of an animated code with no camera: not handled', (tester) async {
      final opened = await partOpened(tester, CameraPresence.none);
      bool? handled;
      unawaited(opened.then((v) => handled = v));
      await _settle(tester);
      expect(handled, isFalse);
      expect(_cams, isEmpty);
    });
  });

  testWidgets('Contacts: the address field takes a scanned address', (tester) async {
    await _show(tester, const ContactsScreen(arg: ContactsArgs(adding: true)));
    await _scanWith(tester, find.widgetWithIcon(EIconButton, EIcons.camera), _e);
    expect(find.text(_e), findsOneWidget);
  });

  testWidgets('epic1 link send: the To field takes a scanned text and reads it', (tester) async {
    final fake = FakeEpic1(on: true);
    await _show(tester, const Epic1SendPage(), api: _Mock(fake));
    await _scanWith(tester, find.byKey(const ValueKey('e1-scan')), _e);
    expect(find.byKey(const ValueKey('e1-clear')), findsOneWidget, reason: 'To is filled, so Scan gives way to Clear');
  });

  testWidgets('Reset password: a scanned phrase fills the words', (tester) async {
    final api = MockDeskWallet(delay: Duration.zero);
    final id = (await tester.runAsync(api.wallets))!.first.id;
    await _show(tester, ResetPasswordScreen(arg: ResetPasswordArg(id)), api: api);
    await _scanWith(tester, find.byKey(const ValueKey('reset-scan')), List.filled(11, 'abandon').followedBy(['about']).join(' '));
    expect(find.text(_l.deskOnbRestoreAllOk(12)), findsOneWidget);
  });

  group('the smart scan', () {
    DeskLocation nav() => _c.read(deskNavProvider);

    testWidgets('a payment code reaches Send with origin qr', (tester) async {
      await _show(tester, _home());
      await _scanWith(tester, find.text('scan'), 'epic:$_e?amount=1.5');
      expect(nav().route, DeskRoute.send);
      final arg = nav().arg as SendArgs;
      expect(arg.code, 'epic:$_e?amount=1.5');
      expect(arg.codeOrigin, CodeOrigin.qr);
    });

    testWidgets('paste instead of the camera takes the same way with origin paste', (tester) async {
      await _show(tester, _home());
      _clip = 'epic:$_e?amount=2';
      await tester.tap(find.text('scan'));
      await _settle(tester, n: 3);
      await tester.tap(find.text(_l.commonPaste));
      await _settle(tester);
      final arg = nav().arg as SendArgs;
      expect(nav().route, DeskRoute.send);
      expect(arg.code, 'epic:$_e?amount=2');
      expect(arg.codeOrigin, CodeOrigin.paste);
    });

    testWidgets('a device-link code opens Link a device', (tester) async {
      await _show(tester, _home());
      await _scanWith(tester, find.text('scan'), deviceLinkText('epiccash://invite/x', fingerprint: '0123456789abcdef'));
      expect(find.text(_l.devicesLink), findsWidgets);
      expect(nav().route, isNot(DeskRoute.send));
    });

    testWidgets('an in-person code in epic1 mode opens its dialog', (tester) async {
      await _show(tester, _home(), api: _Mock(FakeEpic1(on: true)));
      await _scanWith(tester, find.text('scan'), _codePart);
      expect(find.text(_l.deskIpReceiveTitle), findsOneWidget);
    });

    testWidgets('an in-person code in classic mode gets the mode refusal, not "not an Epic code"', (tester) async {
      await _show(tester, _home(), api: _Mock(FakeEpic1()));
      await _scanWith(tester, find.text('scan'), _codePart);
      await _settle(tester);
      expect(find.byKey(const ValueKey('e1-mode-dialog')), findsOneWidget);
      expect(nav().route, isNot(DeskRoute.send));
    });
  });
}
