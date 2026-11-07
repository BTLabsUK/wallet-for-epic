// SPDX-License-Identifier: Apache-2.0
/// What the status places say about the wallet's message checks, on phone and desktop: one
/// headline ("Checking messages", "Checked 2 min ago", why the last one failed), a folded
/// summary of what the last check found ("3 read · 2 waiting · 1 to look at") and, unfolded,
/// one line per finding in three groups, each only when it is not zero. The widgets differ
/// per platform; the words and the grouping are here.
library;

import '../../l10n/app_localizations.dart';
import '../message_checks.dart';
import '../text_join.dart';

/// A finding of the last check, in the order the groups show.
enum CheckItemKind {
  read(CheckGroup.read),
  held(CheckGroup.waiting),
  more(CheckGroup.waiting),
  refused(CheckGroup.problems),
  pairingFailed(CheckGroup.problems),
  unreadable(CheckGroup.problems);

  const CheckItemKind(this.group);

  final CheckGroup group;
}

/// The three groups of findings: what came in, what waits on the relay, what needs a look.
enum CheckGroup { read, waiting, problems }

/// One finding: its kind, how many (1 for [CheckItemKind.more], which has no count), the line
/// and, for a problem, the quiet line under it that says why.
typedef CheckItem = ({CheckItemKind kind, int count, String text, String? why});

/// How the headline reads: a check running, the last one failed, done at [MessageCheckView.checkedAt],
/// or none yet.
enum CheckHead { checking, failed, checked, never }

/// The last check as the status places show it.
class MessageCheckView {
  const MessageCheckView({required this.head, required this.checkedAt, required this.items});

  final CheckHead head;

  /// When the last check ended well; null before the first.
  final DateTime? checkedAt;

  /// The findings, grouped in [CheckGroup] order, zero counts left out.
  final List<CheckItem> items;

  /// The findings of [group], in order.
  List<CheckItem> of(CheckGroup group) => [for (final i in items) if (i.kind.group == group) i];

  /// Whether there is anything to unfold.
  bool get hasItems => items.isNotEmpty;

  /// Messages turned away or not readable and pairings that did not complete, added.
  int get problems => of(CheckGroup.problems).fold(0, (a, i) => a + i.count);
}

/// The view of [check] in [l]'s words.
MessageCheckView messageCheckView(AppLocalizations l, MessageCheck check) {
  final o = check.outcome;
  final head = check.checking
      ? CheckHead.checking
      : check.failed
      ? CheckHead.failed
      : check.checkedAt != null
      ? CheckHead.checked
      : CheckHead.never;
  return MessageCheckView(
    head: head,
    checkedAt: check.checkedAt,
    items: [
      if (o.messages > 0) (kind: CheckItemKind.read, count: o.messages, text: l.msgCheckItemRead(o.messages), why: null),
      if (o.held > 0) (kind: CheckItemKind.held, count: o.held, text: l.msgCheckItemHeld(o.held), why: null),
      if (o.capped > 0) (kind: CheckItemKind.more, count: 1, text: l.msgCheckItemMore, why: null),
      if (o.refused > 0) (kind: CheckItemKind.refused, count: o.refused, text: l.msgCheckItemRefused(o.refused), why: l.msgCheckWhyRefused),
      if (o.failed > 0) (kind: CheckItemKind.pairingFailed, count: o.failed, text: l.msgCheckItemPairingFailed(o.failed), why: null),
      if (o.unreadable > 0) (kind: CheckItemKind.unreadable, count: o.unreadable, text: l.msgCheckItemUnreadable(o.unreadable), why: l.msgCheckWhyUnreadable),
    ],
  );
}

/// The headline for [view] at [now]: "Checking messages", "The last message check failed",
/// "Checked 2 min ago" (the age in minutes, hours or days) or "Not checked yet".
String messageCheckHeadline(AppLocalizations l, MessageCheckView view, DateTime now) => switch (view.head) {
  CheckHead.checking => l.msgChecking,
  CheckHead.failed => l.msgCheckFailed,
  CheckHead.checked => messageCheckedAgo(l, now.difference(view.checkedAt!)),
  CheckHead.never => l.lvShellNotChecked,
};

/// "Checked just now" under a minute, then minutes to 89, hours under two days, else days.
String messageCheckedAgo(AppLocalizations l, Duration since) {
  final d = since.isNegative ? Duration.zero : since;
  if (d.inSeconds < 60) return l.msgCheckedJustNow;
  if (d.inMinutes < 90) return l.msgCheckedMinutesAgo(d.inMinutes);
  if (d.inHours < 48) return l.msgCheckedHoursAgo(d.inHours);
  return l.msgCheckedDaysAgo(d.inDays);
}

/// The folded summary of [view]'s findings: "3 read · 2 waiting · 1 to look at", each part
/// only when it is not zero; empty when nothing was found.
String messageCheckSummary(AppLocalizations l, MessageCheckView view) {
  final read = view.of(CheckGroup.read).fold(0, (a, i) => a + i.count);
  final held = view.items.where((i) => i.kind == CheckItemKind.held).fold(0, (a, i) => a + i.count);
  final more = view.items.any((i) => i.kind == CheckItemKind.more);
  final problems = view.problems;
  return metaLine([
    if (read > 0) l.msgCheckSumRead(read),
    if (held > 0) l.msgCheckSumWaiting(held) else if (more) l.msgCheckSumMore,
    if (problems > 0) l.msgCheckSumProblems(problems),
  ], whole: true);
}

/// The group's small heading.
String checkGroupLabel(AppLocalizations l, CheckGroup group) => switch (group) {
  CheckGroup.read => l.msgCheckGroupRead,
  CheckGroup.waiting => l.msgCheckGroupWaiting,
  CheckGroup.problems => l.msgCheckGroupProblems,
};

/// Every line of [check] as plain text at [now], the headline first: what a screen reader
/// hears, and what a test checks.
List<String> messageCheckLines(AppLocalizations l, MessageCheck check, {DateTime? now}) {
  final view = messageCheckView(l, check);
  return [
    messageCheckHeadline(l, view, now ?? DateTime.now()),
    for (final i in view.items) ...[i.text, ?i.why],
  ];
}
