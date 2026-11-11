// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/announcements/announcement_card.dart';
import 'package:epic_wallet/src/btlabs_public.dart' show Announcement, AnnouncementLink;
import 'package:epic_wallet/src/scan/incoming_link.dart' show incomingLinkProvider;

/// A 1×1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final Uint8List _broken = Uint8List.fromList(List<int>.generate(64, (i) => i));

const _faucet = AnnouncementLink(label: 'Open faucet', url: 'https://t.me/BTLABS_BOT?start=faucet');

Announcement _msg({
  String text = 'Faucet open for beta testers: a small amount of EPIC to try payments.',
  AnnouncementLink? link = _faucet,
  Uint8List? png,
}) => Announcement(id: 'faucet-open-2611', text: text, link: link, imagePng: png);

Future<void> _pump(
  WidgetTester tester,
  Widget card, {
  List<String>? opened,
  double width = 360,
  double textScale = 1,
  ProviderContainer? container,
}) async {
  final overrides = [
    announcementOpenUrlProvider.overrideWithValue((url) async {
      opened?.add(url);
      return true;
    }),
  ];
  final scope = container == null
      ? ProviderScope(overrides: overrides, child: _app(card, width, textScale))
      : UncontrolledProviderScope(container: container, child: _app(card, width, textScale));
  await tester.pumpWidget(scope);
}

Widget _app(Widget card, double width, double textScale) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: card),
    ),
  ),
);

Finder get _cardFinder => find.byType(AnnouncementCard);
Finder get _text => find.byKey(const ValueKey('announcement-text'));
Finder get _link => find.byKey(const ValueKey('announcement-link'));
Finder get _x => find.byKey(const ValueKey('announcement-dismiss'));
Finder get _image => find.byKey(const ValueKey('announcement-image'));

String _linkText(WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: _link, matching: find.byType(Text))).textSpan!.toPlainText();

void main() {
  group('height', () {
    testWidgets('is the 64 px image box plus padding, with or without an image', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}));
      final none = tester.getSize(_cardFinder);
      expect(none.height, 12 + announcementImageSize + 12);
      expect(_image, findsNothing);

      await _pump(tester, AnnouncementCard(_msg(png: _png), onDismiss: () {}));
      await tester.pump();
      expect(tester.getSize(_cardFinder), none);
      expect(tester.getSize(_image), const Size(64, 64));
    });

    testWidgets('does not change when the PNG cannot be decoded', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(png: _png), onDismiss: () {}));
      final good = tester.getSize(_cardFinder);

      await _pump(tester, AnnouncementCard(_msg(png: _broken), onDismiss: () {}));
      // The decode runs outside fake time.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump();
      expect(tester.getSize(_cardFinder), good);
      expect(tester.getSize(_image), const Size(64, 64));
      expect(find.descendant(of: _image, matching: find.byType(Image)), findsOneWidget);
      // Nothing was drawn into the box but the surface colour.
      expect(find.descendant(of: _image, matching: find.byType(ColoredBox)), findsOneWidget);
    });

    testWidgets('is the same without a link, and for a short text', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}));
      final full = tester.getSize(_cardFinder);
      await _pump(tester, AnnouncementCard(_msg(link: null, text: 'Hi'), onDismiss: () {}));
      expect(tester.getSize(_cardFinder), full);
      expect(_link, findsNothing);
    });

    testWidgets('grows together with a larger system text size, image or not', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}), textScale: 1.6);
      final plain = tester.getSize(_cardFinder);
      await _pump(tester, AnnouncementCard(_msg(png: _png), onDismiss: () {}), textScale: 1.6);
      await tester.pump();
      expect(tester.getSize(_cardFinder), plain);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the dense card keeps the image box', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(png: _png), dense: true, onDismiss: () {}));
      await tester.pump();
      expect(tester.getSize(_image), const Size(64, 64));
      expect(tester.getSize(_cardFinder).height, 12 + 64 + 12);
    });
  });

  group('text', () {
    testWidgets('starts at the left edge without an image and after the box with one', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}));
      final left = tester.getTopLeft(_text).dx;
      expect(left, 12);

      await _pump(tester, AnnouncementCard(_msg(png: _png), onDismiss: () {}));
      await tester.pump();
      expect(tester.getTopLeft(_text).dx, 12 + 64 + 12);
    });

    testWidgets('is cut at two lines with an ellipsis', (tester) async {
      final long = List.filled(14, 'a long announcement word').join(' ');
      await _pump(tester, AnnouncementCard(_msg(text: long.substring(0, 140)), onDismiss: () {}));
      final widget = tester.widget<Text>(_text);
      expect(widget.maxLines, 2);
      expect(widget.overflow, TextOverflow.ellipsis);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: _text, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.getSize(_text).height, lessThanOrEqualTo(2 * 20.0));
      expect(tester.getSize(_cardFinder).height, 12 + 64 + 12);
    });

    testWidgets('is plain: markup and markdown characters are shown as typed', (tester) async {
      const raw = '**bold** <b>x</b> [a](https://x.y)';
      await _pump(tester, AnnouncementCard(_msg(text: raw, link: null), onDismiss: () {}));
      expect(find.text(raw), findsOneWidget);
    });
  });

  group('link', () {
    testWidgets('shows the label, the host of an https address and the external glyph', (tester) async {
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}));
      expect(_linkText(tester), 'Open faucet · t.me');
      expect(find.descendant(of: _link, matching: find.byIcon(Icons.open_in_new)), findsOneWidget);
    });

    testWidgets('shows "Epic Cash" for an epic: link, without the glyph', (tester) async {
      await _pump(
        tester,
        AnnouncementCard(
          _msg(link: const AnnouncementLink(label: 'Pay now', url: 'epic:pay?to=abc')),
          onDismiss: () {},
        ),
      );
      expect(_linkText(tester), 'Pay now · Epic Cash');
      expect(find.descendant(of: _link, matching: find.byIcon(Icons.open_in_new)), findsNothing);
    });

    testWidgets('is a link to the screen reader, not a button', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}));
      final node = tester.getSemantics(find.descendant(of: _link, matching: find.byType(Semantics)).first);
      expect(node.label, 'Open faucet, t.me, opens in the browser');
      expect(node.flagsCollection.isLink, isTrue);
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('an https tap hands the address to the launcher, and nothing opens before it', (tester) async {
      final opened = <String>[];
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () {}), opened: opened);
      await tester.pump();
      expect(opened, isEmpty);
      await tester.tap(_link);
      await tester.pump();
      expect(opened, ['https://t.me/BTLABS_BOT?start=faucet']);
    });

    testWidgets('an epic: tap goes to the incoming-link router and not to the launcher', (tester) async {
      final opened = <String>[];
      final container = ProviderContainer(
        overrides: [
          announcementOpenUrlProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(incomingLinkProvider, (_, _) {});
      await _pump(
        tester,
        AnnouncementCard(
          _msg(link: const AnnouncementLink(label: 'Pay now', url: 'epic:pay?to=abc')),
          onDismiss: () {},
        ),
        container: container,
      );
      expect(container.read(incomingLinkProvider), isNull);
      await tester.tap(_link);
      await tester.pump();
      expect(container.read(incomingLinkProvider)?.text, 'epic:pay?to=abc');
      expect(opened, isEmpty);
    });

    test('the default launcher refuses what is not https', () async {
      expect(await openAnnouncementUrl('http://t.me/x'), isFalse);
      expect(await openAnnouncementUrl('epic:pay'), isFalse);
      expect(await openAnnouncementUrl('https:///nohost'), isFalse);
    });
  });

  group('dismiss', () {
    testWidgets('the × calls onDismiss and carries the name Dismiss', (tester) async {
      var dismissed = 0;
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () => dismissed++));
      expect(tester.widget<IconButton>(_x).tooltip, 'Dismiss');
      await tester.tap(_x);
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('no onDismiss, no ×', (tester) async {
      await _pump(tester, AnnouncementCard(_msg()));
      expect(_x, findsNothing);
    });

    testWidgets('a swipe dismisses only when asked for', (tester) async {
      var dismissed = 0;
      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () => dismissed++));
      await tester.drag(_cardFinder, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(dismissed, 0);

      await _pump(tester, AnnouncementCard(_msg(), onDismiss: () => dismissed++, swipeToDismiss: true));
      await tester.drag(_cardFinder, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });

  group('shown', () {
    testWidgets('onShown runs once, after the first frame, and not on a rebuild', (tester) async {
      var shown = 0;
      final card = AnnouncementCard(_msg(), onShown: () => shown++);
      await _pump(tester, card);
      expect(shown, 1);
      await tester.pump();
      await _pump(tester, AnnouncementCard(_msg(), onShown: () => shown++));
      await tester.pump();
      expect(shown, 1);
    });

    testWidgets('a card given another message reports it again', (tester) async {
      final ids = <String>[];
      Widget card(String id) => AnnouncementCard(
        Announcement(id: id, text: 'x'),
        onShown: () => ids.add(id),
      );
      await _pump(tester, card('one'));
      await _pump(tester, card('two'));
      await tester.pump();
      expect(ids, ['one', 'two']);
    });
  });
}
