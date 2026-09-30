/// Feedback reports: what the user wrote, a few facts about the app, and optionally the
/// newest part of the log. The report is plain text, and the preview shows exactly the text that
/// is shared, saved or posted.
///
/// No feedback server exists. Share or save always works. "Send" appears only in builds made
/// with `--dart-define=WFE_FEEDBACK_URL=https://...`, and posts the same text there.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'redact.dart';
import 'slate_files.dart';

/// Where "Send" posts reports. Empty in normal builds.
const String feedbackUrlSetting = String.fromEnvironment('WFE_FEEDBACK_URL');

/// How much of the log a report attaches: the newest 256 KB, days of normal use, and small
/// enough for any mail app to attach.
const int feedbackLogBytes = 256 * 1024;

/// Longest message the form takes.
const int maxFeedbackMessageChars = 5000;

/// [text] as a feedback URL: https, or http to this machine only, for the dev receiver in
/// `tool/feedback_receiver.py`. Null for anything else.
Uri? parseFeedbackUrl(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme == 'https') return uri;
  const local = {'localhost', '127.0.0.1', '10.0.2.2', '::1'};
  if (uri.scheme == 'http' && local.contains(uri.host)) return uri;
  return null;
}

final feedbackUrlProvider = Provider<Uri?>(
  (ref) => parseFeedbackUrl(feedbackUrlSetting),
);

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
  });

  final String appVersion;
  final String platform;
  final String network;

  /// Host names only, never full URLs.
  final String node;
  final String relay;
  final String sync;
}

/// A loose check that [email] can be replied to.
bool isValidFeedbackEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

/// [text] cut to at most [maxBytes] of UTF-8, keeping the end and starting on a whole line.
String keepLastBytes(String text, int maxBytes) {
  final bytes = utf8.encode(text);
  if (bytes.length <= maxBytes) return text;
  var cut = utf8.decode(
    bytes.sublist(bytes.length - maxBytes),
    allowMalformed: true,
  );
  final line = cut.indexOf('\n');
  if (line >= 0) cut = cut.substring(line + 1);
  return cut;
}

/// The report text. [log] is the attached log tail, or null when the user turned it off.
/// The message and the log are redacted here, whatever the caller did.
String buildFeedbackReport({
  required String message,
  String? email,
  required FeedbackDetails details,
  String? log,
  required DateTime at,
}) {
  final reply = email?.trim() ?? '';
  final out = StringBuffer()
    ..writeln('Epic Cash Wallet feedback')
    ..writeln('Written: ${at.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln('Message')
    ..writeln('-------')
    ..writeln(redact(message.trim()))
    ..writeln()
    ..writeln('Reply to: ${reply.isEmpty ? 'not given' : reply}')
    ..writeln()
    ..writeln('About the app')
    ..writeln('-------------')
    ..writeln('Version: ${details.appVersion}')
    ..writeln('Platform: ${redact(details.platform)}')
    ..writeln('Network: ${details.network}')
    ..writeln('Node: ${details.node}')
    ..writeln('Epicbox server: ${details.relay}')
    ..writeln('Sync: ${redact(details.sync)}')
    ..writeln();
  if (log == null) {
    out.writeln('Diagnostic log: not attached');
  } else {
    final tail = keepLastBytes(redact(log), feedbackLogBytes);
    out
      ..writeln('Diagnostic log (newest part, secrets removed)')
      ..writeln('---------------------------------------------')
      ..write(tail);
    if (!tail.endsWith('\n')) out.writeln();
  }
  return out.toString();
}

/// `epic-wallet-feedback-<yyyyMMdd-HHmm>.txt`, in local time.
String feedbackFileName(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'epic-wallet-feedback-${at.year}${two(at.month)}${two(at.day)}'
      '-${two(at.hour)}${two(at.minute)}.txt';
}

/// A report the server did not take.
class FeedbackSendError implements Exception {
  const FeedbackSendError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Ways a report leaves the app.
abstract interface class FeedbackOutlet {
  /// Whether [share] works here.
  bool get canShare;

  /// Saves the report where the user picks. False if they cancelled.
  Future<bool> save({required String name, required String report});

  /// Hands the report to another app as a file. False if dismissed.
  Future<bool> share({required String name, required String report});

  /// Posts the report to [url] as `text/plain`. Throws [FeedbackSendError] if it was not taken.
  Future<void> post(Uri url, String report);
}

class PlatformFeedbackOutlet implements FeedbackOutlet {
  const PlatformFeedbackOutlet({this.timeout = const Duration(seconds: 30)});

  final Duration timeout;

  @override
  bool get canShare => canShareFiles;

  @override
  Future<bool> save({required String name, required String report}) =>
      saveBytesToDevice(
        name: name,
        bytes: Uint8List.fromList(utf8.encode(report)),
        dialogTitle: 'Save feedback',
      );

  @override
  Future<bool> share({required String name, required String report}) =>
      shareBytes(name: name, bytes: Uint8List.fromList(utf8.encode(report)));

  @override
  Future<void> post(Uri url, String report) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(url).timeout(timeout);
      request.headers.contentType = ContentType(
        'text',
        'plain',
        charset: 'utf-8',
      );
      request.add(utf8.encode(report));
      final response = await request.close().timeout(timeout);
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FeedbackSendError(
          'The feedback server answered ${response.statusCode}.',
        );
      }
    } on FeedbackSendError {
      rethrow;
    } on TimeoutException {
      throw const FeedbackSendError('The feedback server did not answer.');
    } on IOException {
      throw const FeedbackSendError('Could not reach the feedback server.');
    } finally {
      client.close(force: true);
    }
  }
}

/// Records what left the app, for widget tests.
class FakeFeedbackOutlet implements FeedbackOutlet {
  final List<({String name, String report})> saved = [];
  final List<({String name, String report})> shared = [];
  final List<({Uri url, String report})> posted = [];

  /// When set, [post] throws it.
  FeedbackSendError? postError;

  @override
  bool canShare = true;

  @override
  Future<bool> save({required String name, required String report}) async {
    saved.add((name: name, report: report));
    return true;
  }

  @override
  Future<bool> share({required String name, required String report}) async {
    shared.add((name: name, report: report));
    return true;
  }

  @override
  Future<void> post(Uri url, String report) async {
    if (postError case final error?) throw error;
    posted.add((url: url, report: report));
  }
}

final feedbackOutletProvider = Provider<FeedbackOutlet>(
  (ref) => const PlatformFeedbackOutlet(),
);
