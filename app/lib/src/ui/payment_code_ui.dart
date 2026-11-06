// SPDX-License-Identifier: Apache-2.0
/// What Send shows for a payment code (an `epic:` QR, link or paste): the request banner, the
/// payee's unverified name and note, and the origin pill on the review. The name and note are
/// the payee's claims: plain text in a quoted block, never a contact's or a title's style.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../scan/scan_checks.dart' show CodeOrigin;
import '../scan/scan_router.dart' show RequestProblem;
import '../scan/scan_text.dart';
import 'badge.dart';
import 'notices.dart';

const Key sendRequestBannerKey = Key('send-request-banner');
const Key sendRequestDismissKey = Key('send-request-dismiss');
const Key payeeClaimsKey = Key('payee-claims');
const Key sendOriginPillKey = Key('send-origin-pill');

/// How long the banner takes to fold away, and to open again for a new code.
const Duration requestBannerMotion = Duration(milliseconds: 240);

/// The icon of where a code came from.
IconData originIcon(CodeOrigin origin) => switch (origin) {
  CodeOrigin.qr => Icons.qr_code_2,
  CodeOrigin.link => Icons.link,
  CodeOrigin.paste => Icons.content_paste,
};

/// "Payment request" over the amount step: check the amount, or what was dropped from the
/// code. × folds it away; a new code opens it again.
class RequestBanner extends StatelessWidget {
  const RequestBanner({
    super.key,
    required this.open,
    required this.origin,
    required this.problems,
    required this.onDismiss,
  });

  final bool open;
  final CodeOrigin origin;
  final Set<RequestProblem> problems;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final child = open
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _card(context),
          )
        : const SizedBox(width: double.infinity);
    // Reduced motion: no AnimatedSize at all. One of zero duration ends its animation inside
    // its own layout, which Flutter refuses (it asserts when × closes the banner).
    if (MediaQuery.of(context).disableAnimations) return child;
    return AnimatedSize(
      duration: requestBannerMotion,
      reverseDuration: requestBannerMotion,
      curve: open ? Curves.easeOutCubic : Curves.easeInCubic,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedOpacity(
        duration: requestBannerMotion,
        curve: open ? Curves.easeOutCubic : Curves.easeInCubic,
        opacity: open ? 1 : 0,
        child: child,
      ),
    );
  }

  Widget _card(BuildContext context) {
    final l = context.l10n;
    final lines = requestProblemLines(l, problems);
    // Only the parts the app dropped from the code; a plain send has no banner of its own.
    return InlineNotice(
      key: sendRequestBannerKey,
      level: NoticeLevel.warning,
      icon: originIcon(origin),
      title: lines.join('\n'),
      liveRegion: true,
      onClose: onDismiss,
      closeKey: sendRequestDismissKey,
      closeLabel: l.sendRequestDismiss,
    );
  }
}

/// Where the payment details came from, as a neutral badge under the review's header.
class OriginPill extends StatelessWidget {
  const OriginPill({super.key, required this.origin});

  final CodeOrigin origin;

  @override
  Widget build(BuildContext context) => EBadge(
    originText(context.l10n, origin),
    key: sendOriginPillKey,
    icon: originIcon(origin),
  );
}
