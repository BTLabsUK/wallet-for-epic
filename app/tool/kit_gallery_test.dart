// SPDX-License-Identifier: Apache-2.0
// The phone kit gallery: every part of `ui/kit/` and the toast, dark and light, 390 dp wide with
// the real fonts, to compare with the design frame Std-2-Parts.
//
//   . tools/env.sh && cd app && flutter test tool/kit_gallery_test.dart
//
// Writes `<KIT_GALLERY_DIR>/<page>-<theme>.png` (default `build/kit-gallery/` at the repo root):
// page 1 buttons, rows, chips, avatars, headers and fields; page 2 steps, the home slot, the
// amount screen, the keypad and the corner marks; page 3 sheets, the empty state and toasts.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/kit/kit_amount.dart';
import 'package:epic_wallet/src/ui/kit/kit_avatar.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:epic_wallet/src/ui/kit/kit_chip.dart';
import 'package:epic_wallet/src/ui/kit/kit_corner_marks.dart';
import 'package:epic_wallet/src/ui/kit/kit_empty_state.dart';
import 'package:epic_wallet/src/ui/kit/kit_group.dart';
import 'package:epic_wallet/src/ui/kit/kit_connection_dot.dart';
import 'package:epic_wallet/src/ui/kit/kit_headers.dart';
import 'package:epic_wallet/src/ui/kit/kit_help_sheet.dart';
import 'package:epic_wallet/src/ui/kit/kit_icons.dart';
import 'package:epic_wallet/src/ui/kit/kit_keypad.dart';
import 'package:epic_wallet/src/ui/kit/kit_row.dart';
import 'package:epic_wallet/src/ui/kit/kit_search_field.dart';
import 'package:epic_wallet/src/ui/kit/kit_sheet.dart';
import 'package:epic_wallet/src/ui/kit/kit_slot_card.dart';
import 'package:epic_wallet/src/ui/kit/kit_status_pill.dart';
import 'package:epic_wallet/src/ui/kit/kit_steps.dart';
import 'package:epic_wallet/src/ui/kit/kit_tokens.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const double _width = 390;
const double _ratio = 2;

final String _outDir = Platform.environment['KIT_GALLERY_DIR'] ?? '${Directory.current.parent.path}/build/kit-gallery';

void _noop() {}

/// A titled block, as in the parts frame: the gold-ticked head, then the parts.
class _Block extends StatelessWidget {
  const _Block(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHead(title),
        const SizedBox(height: 4),
        ...children,
      ],
    ),
  );
}

Widget _padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: Kit.gutter), child: child);

Widget _wrap(List<Widget> children) => _padded(Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: children));

Widget _page1(AppLocalizations l) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _Block('Buttons', [
      _padded(KitButton(label: 'Review', onPressed: _noop)),
      const SizedBox(height: 10),
      _padded(KitButton(label: 'Copy', kind: KitButtonKind.quiet, onPressed: _noop)),
      const SizedBox(height: 10),
      _padded(KitButton(label: 'Edit', kind: KitButtonKind.ghost, onPressed: _noop)),
      const SizedBox(height: 10),
      _padded(KitButton(label: 'Cancel payment', kind: KitButtonKind.danger, onPressed: _noop)),
      const SizedBox(height: 10),
      _padded(const KitButton(label: 'Review', onPressed: null)),
      const SizedBox(height: 14),
      _wrap([
        KitButton(label: 'Copy', small: true, expand: false, kind: KitButtonKind.quiet, onPressed: _noop),
        KitButton(label: 'Review', small: true, expand: false, onPressed: _noop),
        KitButton(label: 'Share', small: true, expand: false, icon: KitIcons.share, kind: KitButtonKind.quiet, onPressed: _noop),
        KitButton(label: 'Delete', small: true, expand: false, kind: KitButtonKind.danger, onPressed: _noop),
      ]),
    ]),
    _Block('Rows', [
      KitGroup(
        children: [
          KitRow(
            title: 'Anna Kowalska',
            subtitle: 'Today 14:48 · Received',
            leading: const KitAvatar(initials: 'AK', direction: KitDirection.incoming),
            trailing: const Text('+25.0', style: TextStyle(fontFamily: jetBrainsMono, color: Color(0xFF8DDC8D), fontSize: 15)),
            onTap: _noop,
          ),
          KitRow(
            title: 'Security',
            subtitle: 'Locks after 15 minutes',
            leading: const KitIconWell(KitIcons.security),
            chevron: true,
            onTap: _noop,
          ),
          KitRow.toggle(title: 'Outputs', subtitle: 'The coins your balance is made of', value: true, onChanged: (_) {}),
        ],
      ),
      const SizedBox(height: 12),
      const KitGroupLabel('Wallet'),
      KitGroup(
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitRow(title: 'Language', value: 'English', chevron: true, onTap: _noop),
          KitRow(title: 'Currency', value: 'USD', chevron: true, onTap: _noop),
          KitRow(title: 'Network', selected: true, onTap: _noop),
        ],
      ),
    ]),
    _Block('Status and chips', [
      _wrap([
        KitStatusPill(ready: true, onTap: _noop),
        KitStatusPill(ready: false, onTap: _noop),
        KitStatusPill(ready: true, tor: true, onTap: _noop),
        KitStatusPill(ready: false, tor: true, onTap: _noop),
        const KitConnectionDot(ready: true),
        const KitConnectionDot(ready: false),
      ]),
      const SizedBox(height: 10),
      _wrap([
        KitChip('+37.0 arriving', info: true, onTap: _noop),
        KitChip('15.713 in sends', onTap: _noop),
        KitChip('Epicbox', onTap: _noop),
      ]),
    ]),
    _Block('Avatars', [
      _wrap([
        const KitAvatar(initials: 'AK'),
        const KitAvatar(initials: 'TM', direction: KitDirection.out),
        const KitAvatar(initials: 'BO', direction: KitDirection.incoming),
        const KitAvatar(initials: 'NW', direction: KitDirection.pending),
        const KitAvatar(icon: KitIcons.contact, neutral: true),
        const KitAvatar(initials: 'AK', large: true),
      ]),
    ]),
    _Block('Headers and fields', [
      KitFlowHeader(title: 'Send', onLeading: _noop, onHelp: _noop),
      KitFlowHeader(title: 'Anna', onLeading: _noop, back: true, avatar: const KitAvatar(initials: 'AK')),
      KitPageHeader(backLabel: 'Settings', onBack: _noop, title: 'Security', onHelp: _noop),
      const KitTabTitle('Contacts', trailing: Icon(KitIcons.add)),
      const SizedBox(height: 8),
      KitSearchField(hint: 'Search or paste an address', onPaste: _noop, onScan: _noop),
      const SizedBox(height: 8),
      KitSearchField(hint: 'Search', controller: TextEditingController(text: 'Northwind')),
      const SizedBox(height: 8),
      KitAddressField(hint: 'Search, or paste an address', onPaste: _noop, onScan: _noop),
      const SizedBox(height: 8),
      KitAddressField(hint: 'Search', controller: TextEditingController(text: 'Anna Kowalska')),
    ]),
  ],
);

Widget _page2(AppLocalizations l) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _Block('Steps', [
      _padded(
        const KitSteps(
          steps: [
            KitStep(title: 'Sent', state: KitStepState.done, detail: 'Today 18:12'),
            KitStep(title: "Waiting for Tom's wallet to answer", state: KitStepState.now),
            KitStep(title: 'Confirmed', state: KitStepState.later),
          ],
        ),
      ),
    ]),
    _Block('Needs you', [
      KitNeedsYouCard(
        title: 'Invoice from Northwind',
        subtitle: '42.5 EPIC. Nothing is paid until you approve.',
        reviewLabel: 'Review',
        laterLabel: 'Later',
        onReview: _noop,
        onLater: _noop,
        pages: 2,
      ),
      const SizedBox(height: 14),
      KitSlotCard(title: 'Back up your phrase', subtitle: 'Do it once, keep it safe', icon: KitIcons.backup, onTap: _noop, pages: 2, page: 1),
    ]),
    _Block('Amount, keypad and PIN', [
      KitAmountDisplay(amount: '12.5', unit: 'EPIC', fiat: '≈ \$25.82', onSwap: _noop),
      const SizedBox(height: 8),
      KitAvailableBar(available: '1,284.7321', onMax: _noop),
      const SizedBox(height: 8),
      const Center(child: KitLeavesLine(amount: '1,272.2241 EPIC', fee: '0.008 EPIC')),
      const SizedBox(height: 12),
      const Center(child: KitPinDots(filled: 3)),
      const SizedBox(height: 12),
      KitKeypad(onDigit: (_) {}, onDelete: _noop, onPoint: _noop),
      const SizedBox(height: 16),
      const Center(child: KitPinDots(filled: 6, error: true)),
      const SizedBox(height: 8),
      KitAvailableBar(available: '12.0000', onMax: _noop, over: true),
      const SizedBox(height: 6),
      const Center(child: KitLeavesLine(amount: '', fee: '0.008 EPIC', bad: true)),
    ]),
    _Block('Corner marks', [
      Center(
        child: KitCornerMarks(
          inset: 8,
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Kit.rGroup)),
            child: const Icon(KitIcons.qr, size: 72, color: Colors.black87),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ]),
  ],
);

Widget _page3(AppLocalizations l) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _Block('Sheet', [
      Builder(
        builder: (context) => Material(
          color: context.tokens.sheet,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Kit.rSheetTop)),
            side: BorderSide(color: context.tokens.hair2),
          ),
          child: KitSheet(
            title: 'Send 12.5 EPIC',
            primaryLabel: 'Send',
            secondaryLabel: 'Edit',
            onPrimary: _noop,
            onSecondary: _noop,
            child: KitGroup(
              onSheet: true,
              children: [
                KitRow(title: 'To', value: 'epic1q…x7k2', size: KitRowSize.sheet),
                KitRow(title: 'Network fee', value: '0.008 EPIC', size: KitRowSize.sheet),
                KitRow(title: 'Total', value: '12.508 EPIC', size: KitRowSize.sheet),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Builder(
        builder: (context) => Material(
          color: context.tokens.sheet,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Kit.rSheetTop)),
            side: BorderSide(color: context.tokens.hair2),
          ),
          child: KitPickerSheet<String>(
            title: 'Currency',
            selected: 'usd',
            onSelected: (_) {},
            choices: const [
              KitChoice(value: 'usd', title: 'US dollar', subtitle: 'USD'),
              KitChoice(value: 'eur', title: 'Euro', subtitle: 'EUR'),
              KitChoice(value: 'pln', title: 'Złoty', subtitle: 'PLN'),
            ],
          ),
        ),
      ),
    ]),
    _Block('Help sheet', [
      Builder(
        builder: (context) => Material(
          color: context.tokens.sheet,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Kit.rSheetTop)),
            side: BorderSide(color: context.tokens.hair2),
          ),
          child: KitHelpSheet(
            title: 'How sending works',
            lines: const [
              'Your wallet and the other wallet take turns. You send first, then they answer.',
              'Nothing leaves your balance for good until the payment is confirmed.',
            ],
            onMore: _noop,
          ),
        ),
      ),
    ]),
    _Block('Empty state', [
      KitEmptyState(icon: KitIcons.activity, title: 'No payments yet', message: 'Money you send or receive shows up here.', actionLabel: 'Receive', onAction: _noop),
    ]),
    _Block('Toasts', [
      for (final n in [
        Notice(1, 'On its way to you', level: NoticeLevel.success, title: '+12.5 EPIC from Bob', action: NoticeAction('View', _noop)),
        Notice(2, 'Address copied', level: NoticeLevel.success),
        Notice(3, 'Downloading version 26.11.4', level: NoticeLevel.info, persistent: true, progress: 0.4, progressLabel: 'Downloading'),
        Notice(4, 'Version 26.11.4 is ready', level: NoticeLevel.info, persistent: true, action: NoticeAction('Install', _noop)),
        Notice(5, 'The coins are back in your balance', level: NoticeLevel.warning, title: 'Payment to Tom expired', action: NoticeAction('View', _noop)),
        Notice(6, 'Could not reach the node', level: NoticeLevel.error, action: NoticeAction('Try again', _noop)),
        Notice(7, 'An invoice is waiting for your approval.', level: NoticeLevel.info, action: NoticeAction('View', _noop)),
        Notice(8, 'Your Epicbox server is not reachable.', level: NoticeLevel.warning, action: NoticeAction('Switch', _noop)),
        Notice(9, 'Your Epicbox server is not reachable. Your payments wait until it is back or you switch.', level: NoticeLevel.warning, action: NoticeAction('Switch', _noop)),
        Notice(10, 'Could not reach the node, so nothing was sent.', level: NoticeLevel.error, action: NoticeAction('Try again', _noop), secondary: NoticeAction('Later', _noop)),
        Notice(11, 'A long note without any action that runs over two lines of the toast to see the wrap', level: NoticeLevel.info),
      ])
        Padding(
          padding: const EdgeInsets.fromLTRB(Kit.toastSide, 0, Kit.toastSide, 10),
          child: Material(type: MaterialType.transparency, child: NoticeCard(notice: n)),
        ),
    ]),
  ],
);

Future<void> _loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Light.ttf', 'Roboto-Italic.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  for (final (family, file) in [
    ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'),
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  final thai = FontLoader('NotoSansThai');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    thai.addFont(read('assets/fonts/NotoSansThai-$weight.ttf'));
  }
  await thai.load();
  final inter = FontLoader('Inter');
  for (final face in ['Regular', 'Medium', 'SemiBold']) {
    inter.addFont(read('assets/fonts/Inter-$face.ttf'));
  }
  await inter.load();
  await (FontLoader('Lucide')..addFont(read('assets/fonts/Lucide.ttf'))).load();
  await (FontLoader('NotoSansSCSubset')..addFont(read('assets/fonts/NotoSansSCSubset.otf'))).load();
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

void main() {
  setUpAll(_loadFonts);

  final pages = <(String, Widget Function(AppLocalizations))>[
    ('1-buttons-rows-chips', _page1),
    ('2-steps-slot-amount', _page2),
    ('3-sheets-empty-toasts', _page3),
  ];
  for (final dark in [true, false]) {
    final name = dark ? 'dark' : 'light';
    for (final (page, build) in pages) {
      testWidgets('kit gallery $page ($name)', (tester) async {
        tester.view.physicalSize = const Size(_width, 3600) * _ratio;
        tester.view.devicePixelRatio = _ratio;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              theme: buildWalletTheme(protocolLight, Brightness.light),
              darkTheme: buildWalletTheme(protocolDark, Brightness.dark),
              home: Builder(
                builder: (context) => Scaffold(
                  backgroundColor: context.tokens.bg,
                  body: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: RepaintBoundary(
                      key: key,
                      child: ColoredBox(
                        color: context.tokens.bg,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: build(context.l10n),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: _ratio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$_outDir/$page-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        });
        expect(tester.takeException(), isNull);
      });
    }
  }
}
