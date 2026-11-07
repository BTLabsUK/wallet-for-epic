// SPDX-License-Identifier: Apache-2.0
/// A design-review page for the notice surfaces of 26.11.4: the message-check panel of the
/// Epicbox sheet and the desktop status popover in every state, and the digest notice that
/// unfolds into its items, all running on the real widgets with made-up checks.
///
///   `flutter build web --release -t tool/notices_gallery.dart --base-href / -o OUT`
///
/// Nothing in a release builds it.
library;

import 'package:epic_wallet/src/desktop/app/message_check_panel.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/notice_digest.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/notice_digest_text.dart';
import 'package:epic_wallet/src/ui/levels/status_parts.dart';
import 'package:epic_wallet/src/ui/message_check_panel.dart';
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/web/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // `?slow=4` runs every animation at a quarter speed, for recording a clip of it.
  final slow = double.tryParse(Uri.base.queryParameters['slow'] ?? '');
  if (slow != null && slow >= 1) timeDilation = slow;
  runApp(const ProviderScope(child: _Gallery()));
  // The web page's splash (web/index.html) stays until Flutter has drawn over it.
  WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
}

/// The states a check can be in, each with a made-up outcome.
enum _State {
  checking('Checking'),
  never('Not checked yet'),
  failed('Failed'),
  clean('Connected, nothing new'),
  read('Connected, 3 read'),
  behind('Behind'),
  held('Held and problems');

  const _State(this.label);
  final String label;

  MessageCheck check() {
    final now = DateTime.now();
    return switch (this) {
      checking => const MessageCheck(checking: true),
      never => const MessageCheck(),
      failed => MessageCheck(failed: true, checkedAt: now.subtract(const Duration(minutes: 12))),
      clean => MessageCheck(checkedAt: now.subtract(const Duration(minutes: 2))),
      read => MessageCheck(checkedAt: now.subtract(const Duration(seconds: 20)), outcome: const CheckOutcome(messages: 3)),
      behind => MessageCheck(checkedAt: now.subtract(const Duration(minutes: 1)), outcome: const CheckOutcome(messages: 3, capped: 1)),
      held => MessageCheck(
          checkedAt: now.subtract(const Duration(hours: 3)),
          outcome: const CheckOutcome(messages: 3, held: 2, rejected: 1, failed: 1, unreadable: 1, capped: 1),
        ),
    };
  }
}

final _digest = NoticeDigest({HeldKind.invoice: 2, HeldKind.withdrawal: 1});

class _Gallery extends StatefulWidget {
  const _Gallery();

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  Brightness _brightness = Brightness.dark;
  _State _state = _State.held;

  @override
  Widget build(BuildContext context) {
    final dark = _brightness == Brightness.dark;
    return MaterialApp(
      title: 'Notices',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: buildWalletTheme(protocolLight, Brightness.light),
      darkTheme: buildWalletTheme(protocolDark, Brightness.dark),
      home: _Page(
        state: _state,
        dark: dark,
        onState: (s) => setState(() => _state = s),
        onTheme: () => setState(() => _brightness = dark ? Brightness.light : Brightness.dark),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.state, required this.dark, required this.onState, required this.onTheme});

  final _State state;
  final bool dark;
  final ValueChanged<_State> onState;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final phone = _PhoneColumn(state: state);
    final desk = Theme(
      data: buildDeskTheme(dark ? Brightness.dark : Brightness.light),
      child: _DeskColumn(state: state),
    );
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ListView(
          // At phone width the sheet runs edge to edge, as in the app; the words keep their margin.
          padding: EdgeInsets.fromLTRB(wide ? 16 : 0, 12, wide ? 16 : 0, 32),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              children: [
                Expanded(child: Text('Notices in 26.11.4', style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  tooltip: dark ? 'Light theme' : 'Dark theme',
                  onPressed: onTheme,
                  icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.dim),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Real widgets with made-up checks. Pick a state, then tap a row to unfold it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _State.values)
                  ChoiceChip(label: Text(s.label), selected: s == state, onSelected: (_) => onState(s)),
              ],
            ),
              ]),
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 390, child: phone),
                  const SizedBox(width: 32),
                  Expanded(child: desk),
                ],
              )
            else ...[
              phone,
              const SizedBox(height: 32),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: desk),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _heading(BuildContext context, String text) {
  final t = context.tokens;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.dim, letterSpacing: 0.8)),
  );
}

/// The phone: the Epicbox sheet's lower half with the panel, then the digest notice.
class _PhoneColumn extends ConsumerWidget {
  const _PhoneColumn({required this.state});

  final _State state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final check = state.check();
    final sheet = Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusSheetHeader(
            tile: StatusServiceTile(icon: EpicGlyphs.epicbox, enabled: !check.failed),
            name: l.netStatusEpicbox,
            word: check.failed ? l.lvShellBoxNotReachable : l.lvShellBoxListening,
            dot: check.failed ? StatusDot.bad : StatusDot.ok,
            second: 'epicbox.epiccash.com',
            secondMono: true,
          ),
          const SizedBox(height: 8),
          MessageCheckPanel(key: ValueKey(state), check),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: t.line),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () {},
            child: Text(l.lvShellSwitchServer),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: t.dim),
            onPressed: () {},
            child: Text(l.commonClose),
          ),
        ],
      ),
    );
    // At phone width the frames run edge to edge, as the app does; the headings keep a margin.
    final edge = MediaQuery.sizeOf(context).width < 1000 ? 16.0 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: EdgeInsets.only(left: edge), child: _heading(context, 'Phone · Epicbox sheet')),
        ClipRRect(
          borderRadius: BorderRadius.circular(t.radius),
          child: Container(
            color: t.bg,
            padding: const EdgeInsets.only(top: 24),
            child: sheet,
          ),
        ),
        const SizedBox(height: 28),
        Padding(padding: EdgeInsets.only(left: edge), child: _heading(context, 'Phone · digest notice')),
        _PhoneDigest(),
      ],
    );
  }
}

class _PhoneDigest extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PhoneDigest> createState() => _PhoneDigestState();
}

class _PhoneDigestState extends ConsumerState<_PhoneDigest> {
  String? _went;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    final l = context.l10n;
    setState(() => _went = null);
    ref.read(noticeProvider.notifier).show(
          noticeDigestText(l, _digest),
          level: NoticeLevel.info,
          persistent: true,
          items: [
            for (final item in noticeDigestItems(l, _digest))
              NoticeAction(item.text, () => setState(() => _went = 'Opens ${item.place.name}')),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shown = ref.watch(noticeProvider) != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radius),
      child: Container(
        color: t.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text('Home', style: Theme.of(context).textTheme.titleMedium),
            ),
            const NoticeDock(),
            SizedBox(
              height: 120,
              child: Center(
                child: shown
                    ? Text(_went ?? ' ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.dim))
                    : TextButton(onPressed: _show, child: const Text('Show the digest again')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The desktop: the status popover's check panel, then the digest toast.
class _DeskColumn extends StatelessWidget {
  const _DeskColumn({required this.state});

  final _State state;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final check = state.check();
    final popover = Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: c.s2,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.lineStrong),
      ),
      padding: EdgeInsets.all(Sp.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x1, Sp.x1, Sp.x1, 0),
            child: Row(
              children: [
                Icon(EIcons.epicbox, size: Ctl.icon, color: c.dim),
                SizedBox(width: Sp.x2),
                Text(l.netStatusEpicbox, style: ts.body),
                SizedBox(width: Sp.x2),
                Expanded(
                  child: Text(check.failed ? l.lvShellBoxNotReachable : l.lvShellBoxListening,
                      textAlign: TextAlign.end, maxLines: 2, style: ts.small.copyWith(color: check.failed ? c.risk : c.dim)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x1, Sp.x1, Sp.x1, Sp.x2),
            child: Text('epicbox.epiccash.com', style: ts.mono(color: c.dim)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x1, 0, Sp.x1, 0),
            child: Container(
              padding: EdgeInsets.only(top: Sp.x1),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: DeskMessageCheckPanel(key: ValueKey(state), check),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, 'Desktop · status popover'),
        Container(
          decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(Rad.sm)),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.topLeft,
          child: popover,
        ),
        const SizedBox(height: 28),
        _heading(context, 'Desktop · digest toast'),
        const _DeskDigest(),
      ],
    );
  }
}

class _DeskDigest extends StatelessWidget {
  const _DeskDigest();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      height: 260,
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(Rad.sm)),
      clipBehavior: Clip.antiAlias,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: c.bg,
          body: const _DeskDigestBody(),
        ),
      ),
    );
  }
}

class _DeskDigestBody extends StatefulWidget {
  const _DeskDigestBody();

  @override
  State<_DeskDigestBody> createState() => _DeskDigestBodyState();
}

class _DeskDigestBodyState extends State<_DeskDigestBody> {
  String? _went;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    final l = context.l10n;
    setState(() => _went = null);
    showEToast(
      context,
      noticeDigestText(l, _digest),
      tone: ETone.info,
      stay: true,
      items: [
        for (final item in noticeDigestItems(l, _digest))
          (label: item.text, run: () => setState(() => _went = 'Opens ${item.place.name}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_went ?? ' ', style: context.ts.small.copyWith(color: c.dim)),
          SizedBox(height: Sp.x2),
          EButton(label: 'Show the toast again', onPressed: _show),
        ],
      ),
    );
  }
}
