// SPDX-License-Identifier: Apache-2.0
/// Send's side of the scan router a pasted
/// or linked `epic:` code, the payee's claims it carries, and the dialogs a link gets for codes
/// Send does not take. A code only fills the form; the review and the password stay the only
/// way to send.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scan/scan_checks.dart' show CodeOrigin;
import '../../../scan/scan_router.dart';
import '../../../scan/scan_text.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show SettingsJump, settingsPrefsProvider;

export '../../../scan/scan_checks.dart' show CodeOrigin;

/// What a code put into Send. It holds while To keeps [address].
class SendCode {
  const SendCode({
    required this.origin,
    required this.address,
    this.amount,
    this.note,
    this.label,
    this.problems = const {},
    this.noteFilled = false,
  });

  /// A payment request; [address] is the one To got (the code's own or its Direct one).
  factory SendCode.request(PaymentRequest r, CodeOrigin origin, {required String address, required bool noteFilled}) => SendCode(
    origin: origin,
    address: address,
    amount: r.amount?.toInt(),
    note: r.note,
    label: r.label,
    problems: r.problems,
    noteFilled: noteFilled,
  );

  final CodeOrigin origin;
  final String address;

  /// The amount the code asked for, in nanoepic; null when it had none or it was dropped.
  final int? amount;

  /// The payee's note and name, cleaned by the router; not verified.
  final String? note;
  final String? label;
  final Set<RequestProblem> problems;

  /// Message got [note] (it fits a slate's message).
  final bool noteFilled;

  /// A plain `epic:<address>` (or an address from a link) is an address for the UI: no banner.
  bool get banner => amount != null || note != null || label != null || problems.isNotEmpty;
}

/// The review's origin tag.
IconData codeOriginIcon(CodeOrigin o) => switch (o) {
  CodeOrigin.qr => EIcons.qr,
  CodeOrigin.link => EIcons.link,
  CodeOrigin.paste => EIcons.paste,
};

/// The parts of a code that were dropped, one line each, the amount first.
/// The banner under To while a payment request fills the form: "check the amount", or what was
/// dropped from the code, in the warning colour.
class CodeBanner extends StatelessWidget {
  const CodeBanner({super.key, required this.code, required this.onDismiss});

  final SendCode code;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final problems = requestProblemLines(l, code.problems);
    return Semantics(
      container: true,
      liveRegion: true,
      child: ENotice(
        key: const ValueKey('send-code-banner'),
        title: l.sendRequestTitle,
        text: problems.isEmpty ? l.sendRequestCheck : problems.join('\n'),
        textColor: problems.isEmpty ? null : context.dc.warn,
        tone: ETone.info,
        icon: codeOriginIcon(code.origin),
        actions: [EIconButton(key: const ValueKey('send-code-dismiss'), icon: EIcons.close, label: l.sendRequestDismiss, size: EBtnSize.inline, onPressed: onDismiss)],
      ),
    );
  }
}

/// The payee's own words from a code: a quoted block with a start rule, labelled "not verified",
/// plain text, never a contact's name style. Nothing when both are absent.
class EPayeeClaims extends StatelessWidget {
  const EPayeeClaims({super.key, this.label, this.note});

  /// The payee's name from the code; null when absent or a saved contact has the same name.
  final String? label;
  final String? note;

  bool get isEmpty => label == null && note == null;

  /// [label] unless the contact paid has the same name (trimmed, any case).
  static String? labelBeside(String? label, String? contactName) =>
      label != null && contactName != null && label.trim().toLowerCase() == contactName.trim().toLowerCase() ? null : label;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final lines = [
      if (label case final name?) (const ValueKey('send-code-label'), l.payeeNameLabel, name),
      if (note case final text?) (const ValueKey('send-code-note'), l.payeeNoteLabel, text),
    ];
    return Container(
      key: const ValueKey('send-code-claims'),
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(Sp.x4, Sp.x3, Sp.x3, Sp.x3),
      decoration: BoxDecoration(
        color: c.s1,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: BorderDirectional(start: BorderSide(color: c.lineStrong, width: 2)),
      ),
      child: Semantics(
        container: true,
        label: lines.map((x) => '${x.$2}: ${x.$3}').join('. '),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, (key, caption, value)) in lines.indexed) ...[
              if (i > 0) SizedBox(height: Sp.x2),
              Row(
                children: [
                  Flexible(child: ExcludeSemantics(child: Text(caption, style: ts.caption.copyWith(color: c.dim)))),
                  if (i == 0) ...[SizedBox(width: Sp.x1), EInfoHint(l.payeeUnverifiedHint, title: l.payeeUnverifiedTitle)],
                ],
              ),
              SizedBox(height: 4.u),
              ExcludeSemantics(child: Text(value, key: key, style: ts.body.copyWith(color: c.text))),
            ],
          ],
        ),
      ),
    );
  }
}

/// A transaction file's text: it is opened in Import transaction.
void showSlateTextDialog(BuildContext context, {required VoidCallback onOpen}) => unawaited(
  showEDialog<void>(
    context,
    builder: (ctx) => EDialog(
      key: const ValueKey('send-code-slate'),
      title: ctx.l10n.slateFileTitle,
      description: ctx.l10n.scanSlateTextBody,
      icon: EIcons.file,
      actions: [
        EButton(label: ctx.l10n.commonCancel, onPressed: () => Navigator.of(ctx).pop()),
        EButton.primary(
          label: ctx.l10n.commonOpen,
          onPressed: () {
            Navigator.of(ctx).pop();
            onOpen();
          },
        ),
      ],
    ),
  ),
);

/// A link Send cannot take: what it is, the start of the text, Copy (the whole text)
/// and OK. Pairing comes here too until the desktop pairs: the one place to swap for that flow.
void showCodeDialog(BuildContext context, {required IconData icon, required String title, required String text, required String code}) {
  final shown = scanPreview(code);
  unawaited(
    showEDialog<void>(
      context,
      builder: (ctx) => EDialog(
        key: const ValueKey('send-code-dialog'),
        title: title,
        description: text,
        icon: icon,
        body: Semantics(
          label: ctx.l10n.scanCodeTextLabel,
          value: shown,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(Sp.x3),
            decoration: BoxDecoration(color: ctx.dc.s1, borderRadius: BorderRadius.circular(Rad.sm)),
            child: ExcludeSemantics(child: EMonoText(shown)),
          ),
        ),
        actions: [
          EButton(
            label: ctx.l10n.commonCopy,
            kind: EBtnKind.ghost,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (ctx.mounted) showEToast(ctx, ctx.l10n.scanCopied, tone: ETone.ok);
            },
          ),
          EButton.primary(label: ctx.l10n.commonOk, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    ),
  );
}

/// An invoice while Invoices in Settings › Advanced › Experimental is off: says so, Open
/// Advanced goes there.
void showExperimentalOffDialog(BuildContext context, {bool invoices = true}) => unawaited(
  showEDialog<void>(
    context,
    builder: (ctx) => EDialog(
      key: const ValueKey('experimental-off'),
      title: ctx.l10n.expInvoicesOffTitle,
      description: ctx.l10n.expInvoicesOffBody,
      icon: EIcons.invoice,
      actions: [
        EButton(label: ctx.l10n.commonClose, onPressed: () => Navigator.of(ctx).pop()),
        EButton.primary(
          key: const ValueKey('experimental-off-open'),
          label: ctx.l10n.expOpenAdvanced,
          onPressed: () {
            Navigator.of(ctx).pop();
            // Scrolled to the switches, not the top of Advanced (LNX3-1).
            ProviderScope.containerOf(context, listen: false).read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.experimental);
          },
        ),
      ],
    ),
  ),
);
