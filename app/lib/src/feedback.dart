// SPDX-License-Identifier: Apache-2.0
/// Feedback reports: what the user wrote, a few facts about the app, and optionally the
/// newest part of the log, cleaned of secrets and addresses (`support_clean.dart`). The preview
/// shows exactly what is shared, saved or sent.
///
/// "Send" seals the report to the developer and posts it to the support intake, the same format
/// as the Electron GUI's "Report a problem" (`support_report.dart`). Share or save hands over the
/// same text as a file.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'l10n.dart';
import 'slate_files.dart';
import 'support_clean.dart';
import 'support_report.dart';

/// [text] as a support URL: https, or http to this machine only, for a local intake. Null for
/// anything else.
Uri? parseFeedbackUrl(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme == 'https') return uri;
  const local = {'localhost', '127.0.0.1', '10.0.2.2', '::1'};
  if (uri.scheme == 'http' && local.contains(uri.host)) return uri;
  return null;
}

/// Where "Send" posts reports: the support intake. Null only in a build made with an empty or
/// bad `WFE_SUPPORT_URL`, which leaves share or save.
final feedbackUrlProvider = Provider<Uri?>(
  (ref) => switch (supportUrlSetting) {
    final url? => parseFeedbackUrl(url),
    // No `support.report` in app-config.toml: share or save only.
    null => null,
  },
);

/// How much of the log a report attaches: the newest 256 KB, days of normal use, and small
/// enough for any mail app to attach.
const int feedbackLogBytes = 256 * 1024;

/// Longest message the form takes.
const int maxFeedbackMessageChars = 5000;

/// The log a report attaches. Tests hand in a [MemoryLogSink].
final feedbackLogProvider = Provider<LogSink>((ref) => AppLog.sink);

/// Facts about the app a report states. Balances, transactions and addresses are never among
/// them.
class FeedbackDetails {
  const FeedbackDetails({
    required this.appVersion,
    required this.platform,
    required this.network,
    required this.node,
    required this.relay,
    required this.sync,
    this.logLevel,
  });

  final String appVersion;
  final String platform;
  final String network;

  /// Host names only, never full URLs.
  final String node;
  final String relay;
  final String sync;

  /// The log level while the log was written (`normal`, `detailed`); the desktop only.
  final String? logLevel;
}

/// A loose check that [email] can be replied to.
bool isValidFeedbackEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

/// The report. [log] is the attached log tail, or null when the user turned it off. The
/// message, the facts and the log are cleaned here, whatever the caller did; the email is the
/// user's own, for a reply, and stays as written.
SupportReport buildFeedbackReport({
  required String message,
  String? email,
  required FeedbackDetails details,
  String? log,
  required DateTime at,
  String ui = 'phone',
  CleanContext context = const CleanContext(),
}) {
  // One set of names for the facts and the log, so the node is the same <host-n> in both; the
  // message gets its own, as in the GUI.
  final ids = CleanIds();
  String clean(String text) => cleanForReport(text, context: context, ids: ids);
  return SupportReport(
    created: at,
    description: cleanForReport(message.trim(), context: context),
    contact: email?.trim() ?? '',
    app: {
      'version': details.appVersion,
      'ui': ui,
      'platform': clean(details.platform),
      // Mainnet, the only network a user sees, is never named.
      if (details.network.toLowerCase() != 'mainnet') 'network': details.network,
      'node': cleanHost(details.node, ids),
      'epicbox': cleanHost(details.relay, ids),
      'sync': clean(details.sync),
      'log level': ?details.logLevel,
    },
    files: [
      if (log != null)
        tailFile('app/wfe.log', clean(log), max: feedbackLogBytes),
    ],
  );
}

/// `epic-wallet-feedback-<yyyyMMdd-HHmm>.txt`, in local time.
String feedbackFileName(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'epic-wallet-feedback-${at.year}${two(at.month)}${two(at.day)}'
      '-${two(at.hour)}${two(at.minute)}.txt';
}

/// A report the server did not take. [text] words the reason for the screen; [message] is the
/// English, for logs.
class FeedbackSendError implements Exception {
  FeedbackSendError(this.text) : message = text(englishStrings);

  /// [error] in the screen's words.
  factory FeedbackSendError.from(SupportSendError error) => switch (error.reason) {
    SupportFailure.timeout => FeedbackSendError((l) => l.feedbackServerNoAnswer),
    SupportFailure.offline => FeedbackSendError((l) => l.feedbackServerUnreachable),
    _ => FeedbackSendError((l) => l.feedbackServerAnswered(error.status ?? 0)),
  };

  final String Function(AppLocalizations l) text;
  final String message;

  @override
  String toString() => message;
}

/// Ways a report leaves the app.
abstract interface class FeedbackOutlet {
  /// Whether [share] works here.
  bool get canShare;

  /// Saves the report where the user picks, in a dialog titled [dialogTitle] where the
  /// platform shows one. False if they cancelled.
  Future<bool> save({
    required String name,
    required String report,
    required String dialogTitle,
  });

  /// Hands the report to another app as a file. False if dismissed.
  Future<bool> share({required String name, required String report});

  /// Seals the report and posts it to the support intake at [url]; answers the report id.
  /// Throws [FeedbackSendError] if it was not taken.
  Future<String> post(Uri url, SupportReport report);
}

class PlatformFeedbackOutlet implements FeedbackOutlet {
  const PlatformFeedbackOutlet({this._timeout});

  final Duration? _timeout;

  /// `support.timeout_s` unless given.
  Duration get timeout => _timeout ?? supportTimeout;

  @override
  bool get canShare => canShareFiles;

  @override
  Future<bool> save({
    required String name,
    required String report,
    required String dialogTitle,
  }) => saveBytesToDevice(
    name: name,
    bytes: Uint8List.fromList(utf8.encode(report)),
    dialogTitle: dialogTitle,
  );

  @override
  Future<bool> share({required String name, required String report}) =>
      shareBytes(name: name, bytes: Uint8List.fromList(utf8.encode(report)));

  @override
  Future<String> post(Uri url, SupportReport report) async {
    try {
      return await HttpSupportSender(url, timeout: timeout).send(
        report,
        appVersion: supportAppTag(report.app['version'] ?? ''),
      );
    } on SupportSendError catch (error) {
      throw FeedbackSendError.from(error);
    }
  }
}

/// Records what left the app, for widget tests.
class FakeFeedbackOutlet implements FeedbackOutlet {
  final List<({String name, String report})> saved = [];
  final List<({String name, String report})> shared = [];
  final List<({Uri url, SupportReport report})> posted = [];

  /// When set, [post] throws it.
  FeedbackSendError? postError;

  @override
  bool canShare = true;

  @override
  Future<bool> save({
    required String name,
    required String report,
    required String dialogTitle,
  }) async {
    saved.add((name: name, report: report));
    return true;
  }

  @override
  Future<bool> share({required String name, required String report}) async {
    shared.add((name: name, report: report));
    return true;
  }

  @override
  Future<String> post(Uri url, SupportReport report) async {
    if (postError case final error?) throw error;
    posted.add((url: url, report: report));
    return 'ab12cd34';
  }
}

final feedbackOutletProvider = Provider<FeedbackOutlet>(
  (ref) => const PlatformFeedbackOutlet(),
);
