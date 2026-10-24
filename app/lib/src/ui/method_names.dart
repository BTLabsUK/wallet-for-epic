import '../l10n.dart';
import '../recipient.dart';

/// The one place the phone names a payment method: Epicbox, Link Payment · HTTP, Link Payment · Tor or File.
/// Link is the method; HTTP and Tor are its transport, so neither stands alone as a method.

/// The name of a method as LEPIC names its transport (`epicbox`, `http`, `tor`, `file`), or
/// "Unknown".
String txMethodWord(AppLocalizations l, String? transport) =>
    switch (transport) {
      'epicbox' => l.methodEpicbox,
      'http' => l.methodDirectHttp,
      'tor' => l.methodDirectTor,
      'file' => l.methodFile,
      _ => l.txMethodUnknown,
    };

/// The name of the method an address is reached by.
String recipientMethodWord(AppLocalizations l, RecipientKind kind) =>
    switch (kind) {
      RecipientKind.epicbox => l.methodEpicbox,
      RecipientKind.http => l.methodDirectHttp,
      RecipientKind.tor => l.methodDirectTor,
    };
