// SPDX-License-Identifier: Apache-2.0
/// The page after "Ask for an amount" (Gap-1): the request as a code or a file, with what it asks
/// for, Copy and Share, and where the payment stands. The request QR and the request file both
/// use it; each brings its own card and its own steps after the payment.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart' show epicUnit;
import '../app_log.dart';
import '../l10n.dart';
import '../price.dart';
import '../providers.dart';
import '../qr_slate.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../trust_ids.dart';
import 'common.dart';
import 'help_screen.dart';
import 'kit/kit_button.dart';
import 'kit/kit_corner_marks.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_hero_amount.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_tokens.dart';
import 'theme/logo_qr.dart';
import 'theme/tokens.dart';

/// Opens the short help of the Ask pages.
void showAskHelp(BuildContext context) {
  final l = context.l10n;
  showKitHelp(
    context,
    title: l.phoneRecvAsk,
    lines: [l.phoneRecvHelp2],
    onMore: () => openHelp(context, HelpId.receive),
    sheetId: TrustIds.receiveHelpSheet,
    moreId: TrustIds.receiveHelpMore,
  );
}

/// The card of a request page: [child] inside gold corner marks, like the address QR on Receive.
class RequestCodeCard extends StatelessWidget {
  const RequestCodeCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: KitCornerMarks(
      inset: 14,
      arm: 22,
      child: SizedBox(width: Kit.qr, height: Kit.qr, child: child),
    ),
  );
}

/// A request page: back header, the card, the amount and what it is for, the lead, Copy and
/// Share, [status] and Done. [json] is the request's text; [fileName] names it when it is shared
/// or saved.
class RequestCodePage extends ConsumerWidget {
  const RequestCodePage({
    super.key,
    required this.amount,
    required this.json,
    required this.fileName,
    required this.card,
    required this.status,
    required this.onDone,
    this.message,
    this.lead,
    this.actions = const [],
    this.busy = false,
  });

  final BigInt amount;
  final String? message;
  final String json;
  final String fileName;
  final Widget card;
  final Widget status;
  final VoidCallback onDone;

  /// Replaces the lead line.
  final String? lead;

  /// More buttons under Copy and Share (Scan reply).
  final List<Widget> actions;
  final bool busy;

  Future<void> _hand(BuildContext context, WidgetRef ref, Future<bool> Function(SlateFiles files) action) async {
    final files = ref.read(slateFilesProvider);
    final notice = ref.read(noticeProvider.notifier);
    final failed = context.l10n.slateHandOverFailed(fileName);
    try {
      await ref.read(autoLockHoldProvider.notifier).during(() => action(files));
    } catch (error) {
      logWarn('files', 'handing over a request failed: $error');
      notice.show(failed, level: NoticeLevel.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final files = ref.watch(slateFilesProvider);
    final price = ref.watch(priceProvider).value;
    final currency = ref.watch(appSettingsProvider.select((s) => s.value?.fiatCurrency)) ?? 'usd';
    final figure = epicExact(l, amount);
    final number = figure.endsWith(epicUnit) ? figure.substring(0, figure.length - epicUnit.length).trimRight() : figure;
    final fiat = price == null ? null : phoneFiat(l, amount, (hidden: false, price: price, currency: currency), approx: true);
    final note = message == null || message!.isEmpty ? null : message;
    final detail = [?note, ?fiat].join(' · ');
    return SlotScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                KitFlowHeader(
                  title: l.phoneRecvAsk,
                  back: true,
                  onLeading: () => Navigator.of(context).maybePop(),
                  onHelp: () => showAskHelp(context),
                  leadingId: TrustIds.receiveAskBack,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(Kit.gutter, 14, Kit.gutter, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KitHeroAmount(amount: number, unit: epicUnit, incoming: true),
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(detail, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: KitType.body.copyWith(color: t.dim)),
                        ],
                        const SizedBox(height: 34),
                        card,
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            lead ?? l.phoneRecvCodeLead(figure),
                            textAlign: TextAlign.center,
                            style: KitType.body.copyWith(color: t.dim, height: 1.45),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: KitButton(
                                label: l.commonCopy,
                                kind: KitButtonKind.quiet,
                                icon: KitIcons.copy,
                                semanticsId: TrustIds.receiveCodeCopy,
                                onPressed: () => copySecretText(context, json, l.slateCopied),
                              ),
                            ),
                            if (files.canShare) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: KitButton(
                                  label: l.commonShare,
                                  icon: KitIcons.share,
                                  semanticsId: TrustIds.receiveCodeShare,
                                  onPressed: () => _hand(context, ref, (f) => f.share(name: fileName, json: json)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        for (final a in actions) ...[const SizedBox(height: 10), a],
                        const SizedBox(height: 16),
                        Center(child: status),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 0),
                  child: KitButton(label: l.commonDone, kind: KitButtonKind.quiet, semanticsId: TrustIds.receiveCodeDone, onPressed: busy ? null : onDone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Waiting to be paid" with an info-blue dot, or [text] where the request stands otherwise.
class RequestStatusLine extends StatelessWidget {
  const RequestStatusLine({super.key, this.text, this.ok = false});

  final String? text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = ok ? t.ok : t.info;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(text ?? context.l10n.phoneRecvWaitingPaid, style: KitType.rowSub.copyWith(color: color))),
        ],
      ),
    );
  }
}

/// A plain request page (a receipt, a notice): back header, [children] scrolling, [bottom] buttons.
class RequestPlainPage extends StatelessWidget {
  const RequestPlainPage({super.key, required this.title, required this.children, this.bottom = const []});

  final String title;
  final List<Widget> children;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) => SlotScaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              KitFlowHeader(title: title, back: true, onLeading: () => Navigator.of(context).maybePop(), onHelp: () => showAskHelp(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter, 20, Kit.gutter, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
              if (bottom.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < bottom.length; i++) ...[if (i > 0) const SizedBox(height: 10), bottom[i]],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}


/// The request as its animated QR (the payment code the in-person and QR screens draw): the
/// request text cut into [qrFragmentLen]-byte parts, drawn in one version and mask, dark modules
/// on white with the epic1 mark, in the gold corner marks. A request that fits one part stands
/// still. While the parts are made the card shows a quiet spinner; a request too large for a
/// code shows [failed].
class RequestQrCard extends ConsumerStatefulWidget {
  const RequestQrCard({super.key, required this.json, required this.label});

  /// The request's text (an I1 slate).
  final String json;

  /// What a screen reader says for the code.
  final String label;

  @override
  ConsumerState<RequestQrCard> createState() => _RequestQrCardState();
}

class _RequestQrCardState extends ConsumerState<RequestQrCard> {
  QrFrames? _frames;
  Object? _error;
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_encode());
  }

  Future<void> _encode() async {
    try {
      final texts = await ref
          .read(walletServiceProvider)
          .encodeQrSlate(json: widget.json, maxFragmentLen: qrFragmentLen, singleCodeMaxLen: qrSingleCodeMaxLen);
      final frames = QrFrames.of(texts);
      if (!mounted) return;
      setState(() => _frames = frames);
      if (frames.length > 1) {
        _timer = Timer.periodic(const Duration(milliseconds: qrFrameMs), (_) {
          if (mounted) setState(() => _frame = (_frame + 1) % frames.length);
        });
      }
    } catch (error) {
      logWarn('invoices', 'request code not drawn: $error');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final frames = _frames;
    final Widget inner;
    if (frames != null) {
      inner = TrustId(
        TrustIds.receiveCodeQr,
        child: Semantics(
          label: widget.label,
          image: true,
          child: Container(
            key: requestQrCardKey,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Dark modules on white scan reliably in either theme.
              color: protocolLight.surface,
              borderRadius: BorderRadius.circular(Kit.rQr),
              boxShadow: [BoxShadow(color: t.accent.withValues(alpha: dark ? 0.22 : 0.12), blurRadius: 40)],
            ),
            child: LayoutBuilder(
              builder: (context, box) =>
                  LogoQrImage(image: frames.images[_frame % frames.length], size: box.biggest.shortestSide, logo: QrLogo.epic1),
            ),
          ),
        ),
      );
    } else if (_error != null) {
      inner = Center(child: Icon(KitIcons.qr, size: 48, color: t.dim));
    } else {
      inner = const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return RequestCodeCard(child: inner);
  }
}

/// The drawn request code, for tests and the tour.
const Key requestQrCardKey = ValueKey('request-code-qr');
