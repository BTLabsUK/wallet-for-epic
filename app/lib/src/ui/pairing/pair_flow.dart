// SPDX-License-Identifier: Apache-2.0
/// The frame the phone's pairing and device-link flows share, on the kit: a flow header (a close
/// mark on the first step, a back arrow on a later one), the steps' content on the gutter, an
/// optional pinned bottom of buttons, and the QR inside its corner marks.
library;

import 'package:flutter/material.dart';

import '../common.dart';
import '../kit/kit_corner_marks.dart';
import '../kit/kit_button.dart';
import '../kit/kit_headers.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_support.dart';
import '../kit/kit_tokens.dart';
import '../phone_frame.dart' show phoneFrameBreakpoint;
import '../theme/logo_qr.dart';
import '../theme/tokens.dart';

/// One step of a pairing flow: [title] in the flow header, [children] scrolling under it, and
/// [bottom] (the step's buttons) pinned under them. [back] makes the leading mark a back arrow;
/// [onLeading] defaults to leaving the screen. [idle] is the slot line (a wait in progress).
class PairFlowPage extends StatelessWidget {
  const PairFlowPage({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.back = false,
    this.onLeading,
    this.onHelp,
    this.leadingId,
    this.helpId,
    this.idle,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottom;
  final bool back;
  final VoidCallback? onLeading;
  final VoidCallback? onHelp;
  final String? leadingId;
  final String? helpId;
  final Widget? idle;

  @override
  Widget build(BuildContext context) {
    final padding = DockSlack.pad(context, const EdgeInsets.fromLTRB(Kit.gutter, 8, Kit.gutter, Kit.gutter));
    return SlotScaffold(
      idle: idle,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: phoneFrameBreakpoint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitFlowHeader(
                  title: title,
                  back: back,
                  onLeading: onLeading ?? () => Navigator.of(context).maybePop(),
                  onHelp: onHelp,
                  leadingId: leadingId,
                  helpId: helpId,
                ),
                Expanded(
                  child: ListView(
                    padding: bottom == null ? padding : padding.copyWith(bottom: Kit.gutter),
                    children: children,
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, padding.bottom),
                    child: bottom,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A QR code on white (dark modules on white scan reliably in either theme) inside the brand's
/// corner marks, as Receive shows its code. [placeholder] stands in until there is [data].
class PairQr extends StatelessWidget {
  const PairQr({super.key, required this.data, this.size = Kit.qr, this.label, this.placeholder});

  final String? data;
  final double size;

  /// What a screen reader calls the code.
  final String? label;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final data = this.data;
    return Center(
      child: KitCornerMarks(
        inset: 14,
        child: Container(
          padding: const EdgeInsets.all(Kit.gutter),
          decoration: BoxDecoration(color: protocolLight.surface, borderRadius: BorderRadius.circular(Kit.rQr)),
          child: data == null
              ? SizedBox.square(dimension: size, child: Center(child: placeholder ?? const CircularProgressIndicator()))
              : Semantics(label: label, image: label != null, child: LogoQr(data: data, size: size, logo: QrLogo.epic1)),
        ),
      ),
    );
  }
}

/// A line of body text on a flow step: 15, dim, centred when [center].
class PairNote extends StatelessWidget {
  const PairNote(this.text, {super.key, this.center = false, this.strong = false});

  final String text;
  final bool center;

  /// The text colour instead of the dim one.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, textAlign: center ? TextAlign.center : null, style: KitType.body.copyWith(color: strong ? t.text : t.dim)),
    );
  }
}

/// A text field on the kit's quiet ground (radius [Kit.rField]) for a pasted code or a name.
class PairField extends StatelessWidget {
  const PairField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
    this.semanticsId,
    this.textInputAction,
    this.maxLength,
    this.error,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? semanticsId;
  final TextInputAction? textInputAction;
  final int? maxLength;

  /// A refusal shown under the field.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    OutlineInputBorder border(Color color) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(Kit.rField), borderSide: BorderSide(color: color));
    return kitId(
      semanticsId,
      TextField(
        controller: controller,
        autofocus: autofocus,
        minLines: 1,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: KitType.body.copyWith(color: t.text),
        cursorColor: t.accent,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          errorText: error,
          errorStyle: KitType.rowSub.copyWith(color: t.risk),
          filled: true,
          fillColor: t.fill,
          labelStyle: KitType.body.copyWith(color: t.dim),
          hintStyle: KitType.body.copyWith(color: t.faint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: border(Colors.transparent),
          enabledBorder: border(Colors.transparent),
          focusedBorder: border(t.accent),
          errorBorder: border(t.risk),
          focusedErrorBorder: border(t.risk),
        ),
      ),
    );
  }
}

/// The centred block of an end state: a mark in a well, a sheet-size [title] and a dim [body].
class PairOutcome extends StatelessWidget {
  const PairOutcome({super.key, required this.icon, required this.title, this.body, this.good = true});

  final IconData icon;
  final String title;
  final String? body;

  /// Green mark for a good end, amber for one that needs a look.
  final bool good;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = good ? t.ok : t.warn;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Column(
        children: [
          Container(
            width: Kit.emptyWell,
            height: Kit.emptyWell,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.fill, shape: BoxShape.circle),
            child: ExcludeSemantics(child: Icon(icon, size: 34, color: color)),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(title, textAlign: TextAlign.center, style: KitType.sheetTitle.copyWith(color: t.text)),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.dim)),
          ],
        ],
      ),
    );
  }
}

/// Space between the content of a step and the next block.
class PairGap extends StatelessWidget {
  const PairGap([this.height = Kit.groupGap, Key? key]) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

/// A yes/no sheet over a flow: [body] under the [title], a primary [action] and a quiet
/// [cancel] below it. True when the primary one was pressed; a dismissed sheet is a no.
Future<bool> confirmPairSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  required String cancel,
  bool risky = false,
  String? sheetId,
  String? actionId,
  String? cancelId,
  Key? actionKey,
  Key? cancelKey,
}) async {
  final yes = await showKitSheet<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      return KitSheet(
        title: title,
        primary: KitButton(
          key: actionKey,
          label: action,
          kind: risky ? KitButtonKind.danger : KitButtonKind.gold,
          semanticsId: actionId,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
        secondary: KitButton(
          key: cancelKey,
          label: cancel,
          kind: KitButtonKind.quiet,
          semanticsId: cancelId,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        // Text sits at the title's 20; a group would take the gutter.
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child: kitId(sheetId, Text(body, style: KitType.body.copyWith(color: t.dim))),
        ),
      );
    },
  );
  return yes ?? false;
}
