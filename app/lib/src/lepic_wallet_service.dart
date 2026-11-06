// SPDX-License-Identifier: Apache-2.0
/// [WalletService] over the LEPIC library (`package:lepic`, pinned by `tools/lepic.rev`).
///
/// The app's only core. It implements [WalletService], so the UI and its fakes never see
/// LEPIC's own types. Notes, contacts, imported records and history files are the app's own, in
/// `history/` (H-01).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary, Uint64List;
import 'package:lepic/lepic.dart' as lepic;
import 'package:meta/meta.dart' show visibleForTesting;

import 'name_service/pins.dart' show LinkMemory;
import 'name_service/link_payments.dart' show LinkPaymentRecords;
import 'name_service/wire.dart' show Payreq, fromHex, toHex;
import 'history/export.dart';
import 'history/meta_store.dart';
import 'history/wallet_history.dart';
import 'seed_contacts.dart';
import 'advanced.dart' show NetworkMode;
import 'contact_store.dart';
import 'finished_payment.dart';
import 'key_picture.dart' show inviteKeyOf;
import 'legacy/gui_contacts.dart' show AddressChecks;
import 'listener_receives.dart';
import 'log.dart';
import 'net/lan_node_relay.dart';
import 'net/tor_net.dart' show TorNet;
import 'net/tor_switch.dart';
import 'network.dart' show EpicboxRelay;
import 'network_gate.dart';
import 'pin_wrap.dart';
import 'tor_build.dart';
import 'trust/policy.dart' show PeerCompat, appHostFeatures;
import 'send_route.dart' show HostScope, plainHttpGoesDirect, plainHttpHeldNow, urlHostScope;
import 'redact.dart';
import 'sealed_file.dart';
import 'secret_store_api.dart';
import 'settings_file/host_settings.dart';
import 'wallet_service.dart';
import 'watch_mode.dart' show postingFor;

/// Loads the LEPIC library, which the package's build hook bundles on Android, iOS, Linux and
/// Windows (`tools/lepic.sh build`); macOS gets it from the app's own hook (`hook/build.dart`,
/// libraries from `tools/build-apple.sh lepic`).
///
/// A release build opens the bundled file by its place in the bundle ([bundledLepicLibrary]),
/// never through flutter_rust_bridge's search, which tries the directory in
/// `FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR` and a path under the working directory
/// first, so another file there would be loaded in place of the checked one. Debug and test
/// runs keep that search, except on iOS and macOS, whose loader finds the framework only by its
/// full path in the bundle.
///
/// Outside a Flutter bundle (a plain `dart run`, live tests) the load by name fails, so
/// those pass [libraryPath], the library file itself, for example
/// `third_party/lepic-flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so`.
Future<void> initLepic({String? libraryPath}) async {
  await lepic.RustLib.init(
    externalLibrary: libraryPath != null
        ? ExternalLibrary.open(libraryPath)
        : _releaseBuild || Platform.isIOS || Platform.isMacOS
        ? ExternalLibrary.open(bundledLepicLibrary())
        : null,
  );
}


const bool _releaseBuild = bool.fromEnvironment('dart.vm.product');

/// Where a Flutter bundle keeps the LEPIC library: by name on Android, which looks only in the
/// app's own native library folder; `lib/` beside the executable on Linux; beside the
/// executable on Windows; the `lepic_ffi.framework` the build embeds on iOS and macOS, by its
/// full path in the bundle.
@visibleForTesting
String bundledLepicLibrary({String? os, String? executable}) {
  final system = os ?? Platform.operatingSystem;
  final exe = executable ?? Platform.resolvedExecutable;
  final dir = exe.substring(0, max(exe.lastIndexOf('/'), exe.lastIndexOf(r'\')));
  return switch (system) {
    'android' => 'liblepic_ffi.so',
    'linux' => '$dir/lib/liblepic_ffi.so',
    'windows' => '$dir\\lepic_ffi.dll',
    // The framework the build embeds: Frameworks/ at the bundle's top on iOS, beside MacOS/
    // in Contents on macOS.
    'ios' => '$dir/Frameworks/lepic_ffi.framework/lepic_ffi',
    'macos' => '${dir.substring(0, dir.lastIndexOf('/'))}/Frameworks/lepic_ffi.framework/lepic_ffi',
    _ => 'lepic_ffi.framework/lepic_ffi',
  };
}

/// LEPIC info lines that come on a timer and say nothing new (the refresh every minute was
/// a third of a support log): logged as debug, so only Detailed logging keeps them.
const Set<(String, String)> lepicRoutineLines = {
  ('lepic_wallet::refresh', 'refresh completed'),
};

/// Logs one entry of `LepicRuntime.logs()` under its own target:
/// `lepic_wallet::send: slate received in send slate_id=… height=…`. Trace entries are
/// dropped; debug ones, and [lepicRoutineLines], reach the log only while [AppLog.detailed]
/// is on. The app's own lines, which also go to LEPIC's log ring ([AppLog.ring]) and come back
/// on this stream under `dart`, are in the log already and are dropped.
void logLepicEntry(lepic.LogEntry entry) {
  if (entry.target == dartTarget || entry.target.startsWith('$dartTarget.')) return;
  final level = switch (entry.level) {
    lepic.LogLevel.error => LogLevel.error,
    lepic.LogLevel.warn => LogLevel.warn,
    lepic.LogLevel.info
        when lepicRoutineLines.contains((entry.target, entry.message)) =>
      LogLevel.debug,
    lepic.LogLevel.info => LogLevel.info,
    lepic.LogLevel.debug => LogLevel.debug,
    lepic.LogLevel.trace => null,
  };
  if (level == null) return;
  final line = StringBuffer(entry.message);
  // Nested spans of the same name, and the fields each span and the event repeat, are
  // written once (windows-08).
  final spans = [
    for (final (i, span) in entry.spans.indexed)
      if (i == 0 || entry.spans[i - 1] != span) span,
  ];
  if (spans.isNotEmpty) line.write(' in ${spans.join('>')}');
  final written = <(String, String)>{};
  for (final field in entry.fields) {
    if (!written.add((field.name, field.value))) continue;
    final value = field.name == 'error'
        ? redactQuoted(field.value)
        : lepicKeptFields.contains(field.name)
        ? field.value
        : redacted;
    line.write(' ${field.name}=$value');
  }
  AppLog.record(level, entry.target, line.toString());
}

/// How a node check with no wallet open reaches [nodeUrl]: directly for a node on this computer
/// or network; through the app's tor while that carries the app's requests; directly where the
/// Tor switch is off. Throws [NetBlocked] when the switch is on (or Tor only) and tor does not
/// carry yet: nothing leaves the device directly.
@visibleForTesting
lepic.NodeRoute nodeRouteFor(String nodeUrl) {
  if (isLocalAddressUrl(nodeUrl)) return const lepic.NodeRoute();
  final proxy = TorNet.proxy;
  if (TorSwitch.carried && proxy != null) {
    return lepic.NodeRoute(socks: '${proxy.host}:${proxy.port}');
  }
  if (TorSwitch.on || NetGate.torOnly) {
    throw NetBlocked(NetGate.mode, 'direct http ${Uri.tryParse(nodeUrl.trim())?.host ?? ''}');
  }
  return const lepic.NodeRoute();
}

/// LEPIC's error as the app's. The switch is exhaustive, so a kind LEPIC adds breaks the build
/// here instead of reaching the UI unmapped.
WalletError mapLepicError(lepic.WalletError error) {
  // A pairing call's own failure says which, for the pairing screens' words.
  if (lepicPairingFailure(error.kind, error.message) case final failure?) return pairingError(failure);
  final kind = switch (error.kind) {
    lepic.WalletErrorKind.contactsOffline ||
    lepic.WalletErrorKind.epicboxOff ||
    lepic.WalletErrorKind.invalidPairingText ||
    lepic.WalletErrorKind.inviteExpired ||
    lepic.WalletErrorKind.alreadyPaired ||
    lepic.WalletErrorKind.pairingNotFound ||
    lepic.WalletErrorKind.pairingWordsUnavailable ||
    lepic.WalletErrorKind.sealedForAnotherWallet ||
    lepic.WalletErrorKind.sealedUnopenable ||
    lepic.WalletErrorKind.pairingWordsNotFound ||
    lepic.WalletErrorKind.invalidPairingWords ||
    // A device link scanned in the contact pairing flow, or a contact invite in Link a device.
    lepic.WalletErrorKind.wrongPairingClass ||
    // Pairing v3: [lepicPairingFailure] words each one above; listed so the switch stays whole.
    lepic.WalletErrorKind.otherAddress ||
    lepic.WalletErrorKind.addressProofMissing ||
    lepic.WalletErrorKind.peerNotProven ||
    lepic.WalletErrorKind.pairingInProgress ||
    lepic.WalletErrorKind.pairingCrossed ||
    lepic.WalletErrorKind.pairingKindDiffers ||
    lepic.WalletErrorKind.inviteDismissed ||
    lepic.WalletErrorKind.pairingEnded ||
    lepic.WalletErrorKind.pairingWaiting => WalletErrorKind.pairingFailed,
    // A payment that asked for a proof this wallet does not sign (another key's, or any for a
    // listing address): refused, nothing signed or stored.
    lepic.WalletErrorKind.foreignProofAddress => WalletErrorKind.invalidArgument,
    // A contact that is not in the state the call needs; the screens check it first.
    lepic.WalletErrorKind.invalidContactName ||
    lepic.WalletErrorKind.contactNotFound ||
    // A relay move the contact did not ask for (or no longer asks for): nothing moved.
    lepic.WalletErrorKind.relayMoveNotRequested ||
    lepic.WalletErrorKind.contactNotVerified ||
    lepic.WalletErrorKind.sealingOff ||
    lepic.WalletErrorKind.noSlateToSend ||
    lepic.WalletErrorKind.keyCheckRefused ||
    lepic.WalletErrorKind.contactRefusesInvoices => WalletErrorKind.invalidArgument,
    lepic.WalletErrorKind.invalidMnemonic => WalletErrorKind.invalidMnemonic,
    lepic.WalletErrorKind.wrongPassword => WalletErrorKind.wrongPassword,
    lepic.WalletErrorKind.walletAlreadyExists =>
      WalletErrorKind.walletAlreadyExists,
    lepic.WalletErrorKind.walletNotFound => WalletErrorKind.walletNotFound,
    lepic.WalletErrorKind.nodeUnreachable => WalletErrorKind.nodeUnreachable,
    lepic.WalletErrorKind.notEnoughFunds => WalletErrorKind.notEnoughFunds,
    lepic.WalletErrorKind.invalidSlate => WalletErrorKind.invalidSlate,
    lepic.WalletErrorKind.invalidArgument => WalletErrorKind.invalidArgument,
    // A split that cannot be built from the coins at hand; one short error for both.
    lepic.WalletErrorKind.changeTooSmall ||
    lepic.WalletErrorKind.tooHeavy ||
    lepic.WalletErrorKind.nothingToConsolidate =>
      WalletErrorKind.invalidArgument,
    lepic.WalletErrorKind.transportFailed => WalletErrorKind.transportFailed,
    lepic.WalletErrorKind.chainBusy => WalletErrorKind.chainBusy,
    lepic.WalletErrorKind.walletBusy => WalletErrorKind.walletBusy,
    lepic.WalletErrorKind.paymentExpired => WalletErrorKind.paymentExpired,
    lepic.WalletErrorKind.inputsSpentElsewhere => WalletErrorKind.inputsSpentElsewhere,
    lepic.WalletErrorKind.inputsSpentByOwnTransaction => WalletErrorKind.inputsSpentByOwnPayment,
    lepic.WalletErrorKind.peerInputsSpent => WalletErrorKind.peerInputsSpent,
    // A Kill switch session (WalletConfig.offline) refused its node or relay.
    lepic.WalletErrorKind.offline => WalletErrorKind.networkOff,
    lepic.WalletErrorKind.notUrCode => WalletErrorKind.notQrSlate,
    lepic.WalletErrorKind.foreignUrCode => WalletErrorKind.foreignQrCode,
    lepic.WalletErrorKind.mixedUrCodes => WalletErrorKind.mixedQrCodes,
    lepic.WalletErrorKind.invalidUrCode => WalletErrorKind.invalidQrCode,
    lepic.WalletErrorKind.urCodeTooLarge => WalletErrorKind.qrCodeTooLarge,
    lepic.WalletErrorKind.io => WalletErrorKind.io,
    lepic.WalletErrorKind.damagedDatabase => WalletErrorKind.damagedDatabase,
    lepic.WalletErrorKind.httpUrlInvalid => WalletErrorKind.httpUrlInvalid,
    lepic.WalletErrorKind.plainHttpNotAllowed =>
      WalletErrorKind.plainHttpNotAllowed,
    lepic.WalletErrorKind.onionAddressInvalid =>
      WalletErrorKind.onionAddressInvalid,
    lepic.WalletErrorKind.torNotRunning => WalletErrorKind.torNotRunning,
    lepic.WalletErrorKind.onionUnreachable => WalletErrorKind.onionUnreachable,
    lepic.WalletErrorKind.secretStore => WalletErrorKind.io,
    lepic.WalletErrorKind.foreignWallet => WalletErrorKind.invalidArgument,
    lepic.WalletErrorKind.phraseMismatch => WalletErrorKind.phraseMismatch,
    // The old core refused a cancel of a payment on chain, and a history file of another
    // wallet or a damaged one, as invalidArgument; the UI words them from that.
    lepic.WalletErrorKind.onChain ||
    lepic.WalletErrorKind.inPool ||
    lepic.WalletErrorKind.notReleasable ||
    lepic.WalletErrorKind.foreignAppData ||
    lepic.WalletErrorKind.damagedAppData => WalletErrorKind.invalidArgument,
    lepic.WalletErrorKind.invoiceNotFound => WalletErrorKind.invoiceNotFound,
    lepic.WalletErrorKind.amountMismatch => WalletErrorKind.amountMismatch,
    lepic.WalletErrorKind.invoiceAlreadyPaid =>
      WalletErrorKind.invoiceAlreadyPaid,
    lepic.WalletErrorKind.invoiceLockedAboveTip =>
      WalletErrorKind.invoiceLockedAboveTip,
    lepic.WalletErrorKind.invoiceChanged => WalletErrorKind.invoiceChanged,
    lepic.WalletErrorKind.invoiceNotForThisChain =>
      WalletErrorKind.invoiceNotForThisChain,
    // An undelivered issue or resend is a transport failure; `payInvoice` catches the kind
    // before it gets here and answers `InvoiceStatus.replyFailed`.
    lepic.WalletErrorKind.notDelivered => WalletErrorKind.transportFailed,
    lepic.WalletErrorKind.restoreScanRequired =>
      WalletErrorKind.restoreScanRequired,
    // Decided on by kind, never by the core's English message.
    lepic.WalletErrorKind.unsupported => WalletErrorKind.unsupported,
    lepic.WalletErrorKind.cancelled => WalletErrorKind.cancelled,
    // The encrypted records refuse the key this phrase gives: nothing changed or moved.
    lepic.WalletErrorKind.wrongKey => WalletErrorKind.wrongKey,
    lepic.WalletErrorKind.changedDuringCancel ||
    lepic.WalletErrorKind.other ||
    lepic.WalletErrorKind.locked ||
    lepic.WalletErrorKind.notPosted ||
    lepic.WalletErrorKind.panic => WalletErrorKind.other,
  };
  final split =
      error.kind == lepic.WalletErrorKind.changeTooSmall ||
      error.kind == lepic.WalletErrorKind.tooHeavy;
  return WalletError(
    kind: kind,
    txId: error.txId,
    message: split
        ? sendUnbuildable
        : error.kind == lepic.WalletErrorKind.nothingToConsolidate
        ? nothingToConsolidate
        : error.message,
  );
}

/// The core no longer holds a minimum password length: a new password (create, restore, import,
/// reset, change) of under 8 characters is refused here, before any call to it. Opening takes
/// whatever the wallet was made with.
void _requireNewPassword(String password) {
  if (password.runes.length < 8) {
    throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'password has fewer than 8 characters');
  }
}

Future<T> _guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on lepic.WalletError catch (error) {
    throw mapLepicError(error);
  }
}

/// LEPIC's copy-step event as the app's: copying counts pages; checking holds the bar full
/// while the copy is compared; finished ends it.
StoreMigrationProgress lepicStoreMigrationProgress(lepic.StoreMigrationProgress p) => switch (p.stage) {
  lepic.StoreMigrationStage.copying => StoreMigrationProgress(done: p.done, total: p.total),
  lepic.StoreMigrationStage.checking => StoreMigrationProgress(done: p.total, total: p.total),
  lepic.StoreMigrationStage.finished => StoreMigrationProgress(done: p.total, total: p.total, finished: true),
};

/// How LEPIC found the records at the unlock, as the app's. A fallback's reason (English, for
/// the log only) and a rollback set aside (LEPIC requires the restore scan itself) are logged.
StoreOpenOutcome lepicStoreOpen(lepic.StoreAtRest s) {
  if (s.rollbackSetAside) logWarn('store', 'a plain database made after a downgrade was set aside; a scan from genesis follows');
  if (s.state == lepic.StoreAtRestState.fellBackToPlain) {
    logWarn('store', 'records not encrypted this session: ${redact(s.reason)}');
  }
  return switch (s.state) {
    lepic.StoreAtRestState.encrypted => StoreOpenOutcome.encrypted,
    lepic.StoreAtRestState.migratedNow => StoreOpenOutcome.migratedNow,
    lepic.StoreAtRestState.fellBackToPlain => StoreOpenOutcome.plainFallback,
  };
}

/// LEPIC's `PeerCompat` as the app's: the stored facts only; what follows from them (LEPIC's
/// `lepic`, `notices`, `fresh`) the trust policy derives itself from the same dates. Null for a
/// key nothing is known about (everything unset), so the policy sees no row at all.
PeerCompat? lepicPeerCompat(lepic.PeerCompat c) {
  if (c.lastMarkedAtMs == null && c.lastUnmarkedAtMs == null && c.featuresAtMs == null && c.claimed == 0 && c.works == 0) {
    return null;
  }
  DateTime? at(int? ms) => ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  return PeerCompat(
    lastMarkedAt: at(c.lastMarkedAtMs),
    lastUnmarkedAt: at(c.lastUnmarkedAtMs),
    claimed: c.claimed,
    works: c.works,
    featuresAt: at(c.featuresAtMs),
  );
}

T _guardSync<T>(T Function() call) {
  try {
    return call();
  } on lepic.WalletError catch (error) {
    throw mapLepicError(error);
  }
}

/// [_guard] for a call that reaches the network beyond the node: refused in Node only and Kill
/// switch ([NetGate]) before LEPIC is asked, whatever the caller checked.
Future<T> _netGuard<T>(String what, Future<T> Function() call) async {
  NetGate.check(what);
  return _guard(call);
}

/// [_guard] for a call that reaches only the node in use (no payment): Node only lets it run,
/// Kill switch refuses it.
Future<T> _nodeNetGuard<T>(String what, Future<T> Function() call) async {
  NetGate.checkNode(what);
  return _guard(call);
}

/// [_guardStream] for a stream that reaches the network beyond the node: in Node only and Kill
/// switch only a [NetBlocked] error.
Stream<T> _netStream<T>(String what, Stream<T> Function() make) => NetGate.restricted
    ? Stream.error(NetBlocked(NetGate.mode, what))
    : _guardStream(make());

/// [_netGuard] for a call over Epicbox (a send, a resend, an invoice): refused by the mode and
/// with the Epicbox switch off ([NetGate.checkEpicbox]).
Future<T> _epicboxGuard<T>(String what, Future<T> Function() call) async {
  NetGate.checkEpicbox(what);
  return _guard(call);
}

/// [_netStream] for the Epicbox listener.
Stream<T> _epicboxStream<T>(String what, Stream<T> Function() make) {
  try {
    NetGate.checkEpicbox(what);
  } on NetBlocked catch (e) {
    return Stream.error(e);
  }
  return _guardStream(make());
}

/// A Direct send over plain `http` to an internet address is refused while the Tor switch is
/// on ([plainHttpOffNow]): it would go through a Tor exit, which could take the payment
/// (tor_routes.dart, [torStops]). To this device or the local network it goes direct in Normal
/// ([plainHttpGoesDirect]: Tor cannot reach it); Tor only refuses it to anything but this
/// device. `https` and onions go through the wallet's Tor, which LEPIC waits for.
void _torRefusesPlainHttp(String url, String what) {
  if (plainHttpHeldNow(url)) throw PlainHttpOffWithTor(what);
}

Stream<T> _guardStream<T>(Stream<T> stream) => stream.transform(
  StreamTransformer.fromHandlers(
    handleError: (error, stack, sink) => sink.addError(
      error is lepic.WalletError ? mapLepicError(error) : error,
      stack,
    ),
  ),
);

/// Usernet is `Chain.mainnet` to LEPIC: epic-wallet derives mainnet Epicbox addresses there
/// too, and LEPIC's interop chain runs that way (LEPIC V-09).
lepic.Chain _lepicChain(Chain chain) => switch (chain) {
  Chain.mainnet || Chain.usernet => lepic.Chain.mainnet,
  Chain.floonet => lepic.Chain.floonet,
};

WalletSummary _summary(lepic.WalletSummary s) => WalletSummary(
  lastConfirmedHeight: s.lastConfirmedHeight,
  minimumConfirmations: s.minimumConfirmations,
  total: s.total,
  spendable: s.spendable,
  awaitingConfirmation: s.awaitingConfirmation,
  awaitingFinalization: s.awaitingFinalization,
  immature: s.immature,
  locked: s.locked,
  validatedWithNode: s.validatedWithNode,
);

lepic.HttpExposure _lepicExposure(HttpExposure e) => switch (e) {
  HttpExposure.localOnly => lepic.HttpExposure.localOnly,
  HttpExposure.internet => lepic.HttpExposure.internet,
};

/// LEPIC's HTTP listener event as the app's.
HttpListenerEvent lepicHttpEvent(
  lepic.HttpListenerEvent e,
) => HttpListenerEvent(
  kind: switch (e.kind) {
    lepic.HttpListenerEventKind.started => HttpListenerEventKind.started,
    lepic.HttpListenerEventKind.portInUse => HttpListenerEventKind.portInUse,
    lepic.HttpListenerEventKind.bindFailed => HttpListenerEventKind.bindFailed,
    lepic.HttpListenerEventKind.received => HttpListenerEventKind.received,
    lepic.HttpListenerEventKind.refused => HttpListenerEventKind.refused,
    lepic.HttpListenerEventKind.stopped => HttpListenerEventKind.stopped,
  },
  port: e.port,
  txId: e.txId,
  amount: e.amount,
  repeated: e.repeated,
  refusal: switch (e.refusal) {
    lepic.HttpRefusal.rejected => HttpRefusal.rejected,
    lepic.HttpRefusal.unavailable => HttpRefusal.unavailable,
    null => null,
  },
);

HttpRefusal? _refusal(lepic.HttpRefusal? r) => switch (r) {
  lepic.HttpRefusal.rejected => HttpRefusal.rejected,
  lepic.HttpRefusal.unavailable => HttpRefusal.unavailable,
  null => null,
};

TorFailure? _torFailure(lepic.TorFailureKind? f) => switch (f) {
  lepic.TorFailureKind.missing => TorFailure.missing,
  lepic.TorFailureKind.start => TorFailure.start,
  lepic.TorFailureKind.network => TorFailure.network,
  lepic.TorFailureKind.clock => TorFailure.clock,
  lepic.TorFailureKind.listener => TorFailure.listener,
  lepic.TorFailureKind.stopped => TorFailure.stopped,
  lepic.TorFailureKind.publish => TorFailure.publish,
  lepic.TorFailureKind.keys => TorFailure.keys,
  null => null,
};

/// LEPIC's tor event as the app's.
TorEvent lepicTorEvent(lepic.TorEvent e) => TorEvent(
  kind: switch (e.kind) {
    lepic.TorEventKind.starting => TorEventKind.starting,
    lepic.TorEventKind.bootstrapped => TorEventKind.bootstrapped,
    lepic.TorEventKind.publishing => TorEventKind.publishing,
    lepic.TorEventKind.ready => TorEventKind.ready,
    lepic.TorEventKind.failed => TorEventKind.failed,
    lepic.TorEventKind.sending => TorEventKind.sending,
    lepic.TorEventKind.received => TorEventKind.received,
    lepic.TorEventKind.refused => TorEventKind.refused,
    lepic.TorEventKind.stopped => TorEventKind.stopped,
  },
  progress: e.progress,
  onion: e.onion,
  failure: _torFailure(e.failure),
  txId: e.txId,
  amount: e.amount,
  repeated: e.repeated,
  refusal: _refusal(e.refusal),
  socksPort: e.socksPort,
);

/// LEPIC's listener event as the app's, or null for `invoiceBounced`, which is an issuer
/// event: the session handles it ([lepicListenerBounce]) and the listener's own stream does
/// not show it. `repeated` stays apart from `received`: it is a slate answered before, not a
/// new payment.
ListenerEvent? lepicListenerEvent(lepic.ListenerEvent e) {
  final kind = switch (e.kind) {
    lepic.ListenerEventKind.connected => ListenerEventKind.connected,
    lepic.ListenerEventKind.disconnected => ListenerEventKind.disconnected,
    lepic.ListenerEventKind.received => ListenerEventKind.received,
    lepic.ListenerEventKind.repeated => ListenerEventKind.repeated,
    lepic.ListenerEventKind.finalized => ListenerEventKind.finalized,
    lepic.ListenerEventKind.error => ListenerEventKind.error,
    lepic.ListenerEventKind.stopped => ListenerEventKind.stopped,
    lepic.ListenerEventKind.invoiceBounced => null,
  };
  return kind == null
      ? null
      : ListenerEvent(
          kind: kind,
          txId: e.txId,
          message: e.message,
          reason: e.reason,
          retryInMs: e.retryInMs?.toInt(),
        );
}

/// The slate id of the issued invoice a listener event says came back unpaid, or null for
/// any other event.
String? lepicListenerBounce(lepic.ListenerEvent e) =>
    e.kind == lepic.ListenerEventKind.invoiceBounced ? e.slateId : null;

/// LEPIC's view of a peer as the app's.
/// The app's send options as LEPIC's. Strategy All spends every output, a consolidating
/// send, so its change is always one output, whatever count it was given.
/// [exclude]: commitments no coin selection may take (coins another linked device holds).
lepic.SendOptions lepicSendOptions(SendOptions o, {Set<String> exclude = const {}}) => switch (o.strategy) {
  SelectionStrategy.smallest => lepic.SendOptions(
    strategy: lepic.SelectionStrategy.smallest,
    changeOutputs: o.changeOutputs,
    excludeOutputs: exclude.isEmpty ? const [] : [...exclude],
  ),
  SelectionStrategy.all => lepic.SendOptions(
    strategy: lepic.SelectionStrategy.all,
    changeOutputs: 1,
    excludeOutputs: exclude.isEmpty ? const [] : [...exclude],
  ),
};

FeeEstimate lepicFeeEstimate(lepic.FeeEstimate e) => FeeEstimate(
  amount: e.amount,
  fee: e.fee,
  inputCount: e.inputCount,
  change: e.change,
  locked: e.locked,
  changeOutputs: e.changeOutputs,
);

WalletOutput lepicWalletOutput(lepic.WalletOutput o) => WalletOutput(
  commitment: o.commitment,
  value: o.value,
  status: switch (o.status) {
    lepic.OutputStatus.unconfirmed => WalletOutputStatus.unconfirmed,
    lepic.OutputStatus.unspent => WalletOutputStatus.unspent,
    lepic.OutputStatus.locked => WalletOutputStatus.locked,
    lepic.OutputStatus.spent => WalletOutputStatus.spent,
  },
  category: switch (o.category) {
    null => null,
    lepic.OutputCategory.spendable => OutputCategory.spendable,
    lepic.OutputCategory.awaitingConfirmation =>
      OutputCategory.awaitingConfirmation,
    lepic.OutputCategory.awaitingFinalization =>
      OutputCategory.awaitingFinalization,
    lepic.OutputCategory.immature => OutputCategory.immature,
    lepic.OutputCategory.locked => OutputCategory.locked,
    lepic.OutputCategory.unpaidInvoice => OutputCategory.unpaidInvoice,
  },
  isCoinbase: o.isCoinbase,
  height: o.height,
  lockHeight: o.lockHeight,
  mmrIndex: o.mmrIndex,
  confirmations: o.confirmations,
  txId: o.txId,
);

SelfSentTx lepicSelfSentTx(lepic.SelfSentTx t) => SelfSentTx(
  txId: t.txId,
  receivedTxId: t.receivedTxId,
  amount: t.amount,
  fee: t.fee,
  inputCount: t.inputCount,
  outputCount: t.outputCount,
);

/// LEPIC's answer to a received slate as the app's, keeping whether it was a repeat.
ReceivedSlate lepicReceivedSlate(lepic.ReceivedSlate s) =>
    ReceivedSlate(slateId: s.slateId, json: s.json, repeated: s.repeated);

/// LEPIC's slate messages as the app's.
List<SlateMessage> lepicMessages(List<lepic.SlateMessage> messages) => [
  for (final m in messages)
    SlateMessage(
      role: switch (m.role) {
        lepic.SlateRole.sender => SlateRole.sender,
        lepic.SlateRole.receiver => SlateRole.receiver,
      },
      text: m.text,
    ),
];

/// A message as LEPIC takes it: trimmed, and none when blank.
String? _message(String? text) {
  final t = text?.trim() ?? '';
  return t.isEmpty ? null : t;
}

/// LEPIC's reading of a slate. A finalized S3 reads as an answer and a finalized I3 as a
/// request's answer, which finalizing refuses with LEPIC's own error.
SlateInfo lepicSlateInfo(lepic.SlateInfo info) => SlateInfo(
  slateId: info.slateId,
  amount: info.amount,
  fee: info.fee,
  stage: lepicSlateStage(info.stage),
  messages: lepicMessages(info.messages),
);

/// A contact's waiting invoice as the app's (RFC 11): no address, the contact's pairing, its
/// reference and the issuer's message, which LEPIC passes only when its signature verifies.
PendingInvoice lepicContactInvoice(lepic.ContactInvoiceView i) {
  final received = DateTime.fromMillisecondsSinceEpoch(i.receivedAtMs.toInt());
  final expires = i.expires;
  return PendingInvoice(
    slateId: i.slateId,
    senderAddress: '',
    amount: i.amount,
    receivedAt: received,
    expiresAt: expires == null ? received.add(invoiceExpiry) : DateTime.fromMillisecondsSinceEpoch(expires.toInt() * 1000),
    pairingId: i.contactId,
    reference: i.reference,
    message: i.message,
  );
}

/// The invoice event in a LEPIC wallet event, or null for any other event and for the
/// issuer's side (`invoiceFinalized`, `invoiceDeclined`, an expired invoice this wallet
/// issued), which the app, a payer only, does not show. The app's own `declined` comes from
/// [LepicWalletSession.declineInvoice].
InvoiceEvent? lepicInvoiceEvent(lepic.WalletEvent e) {
  final slateId = e.slateId;
  if (slateId == null) return null;
  final kind = switch (e.kind) {
    lepic.WalletEventKind.invoiceReceived => InvoiceEventKind.received,
    lepic.WalletEventKind.invoicePosted => InvoiceEventKind.posted,
    lepic.WalletEventKind.invoiceWithdrawn => InvoiceEventKind.withdrawn,
    lepic.WalletEventKind.invoiceExpired when e.txId == null =>
      InvoiceEventKind.expired,
    // Unverified: only ever a notice (another install on this phrase may own the slate).
    lepic.WalletEventKind.unknownSlate when e.slateStage == 'I2' =>
      InvoiceEventKind.unknownInvoicePayment,
    lepic.WalletEventKind.unknownSlate => InvoiceEventKind.unknownSendAnswer,
    lepic.WalletEventKind.receiveSuperseded => InvoiceEventKind.receiveSuperseded,
    // An ordinary Epicbox payment's sender reports it posted: advisory, LEPIC checked who.
    lepic.WalletEventKind.paymentPosted => InvoiceEventKind.paymentPosted,
    // The sender of a payment this wallet answered reports it cancelled: LEPIC checked who and
    // cancelled nothing; the app releases it (sender_cancel.dart).
    lepic.WalletEventKind.paymentCancelled => InvoiceEventKind.paymentCancelled,
    _ => null,
  };
  if (kind == null) return null;
  return InvoiceEvent(
    kind: kind,
    slateId: slateId,
    kernelExcess:
        kind == InvoiceEventKind.posted || kind == InvoiceEventKind.paymentPosted
        ? e.kernelExcess
        : null,
  );
}

/// The issuer's side of a LEPIC wallet event: the state an invoice this wallet issued moved
/// to, or null for any other event. `invoiceExpired` is the issuer's only with a `txId`
/// (LEPIC cancelled it); without one it was a waiting invoice to pay.
({String slateId, IssuedInvoiceState state})? lepicIssuerEvent(
  lepic.WalletEvent e,
) {
  final slateId = e.slateId;
  if (slateId == null) return null;
  final state = switch (e.kind) {
    lepic.WalletEventKind.invoiceFinalized => IssuedInvoiceState.paid,
    lepic.WalletEventKind.invoiceDeclined => IssuedInvoiceState.declined,
    lepic.WalletEventKind.invoiceExpired when e.txId != null =>
      IssuedInvoiceState.expired,
    lepic.WalletEventKind.invoiceBounced => IssuedInvoiceState.bounced,
    _ => null,
  };
  return state == null ? null : (slateId: slateId, state: state);
}

/// The local transaction id in a history key this service made (`l:<id>`).
int lepicTxId(String key) {
  final id = key.startsWith('l:') ? int.tryParse(key.substring(2)) : null;
  if (id == null) {
    throw WalletError(
      kind: WalletErrorKind.invalidArgument,
      message: 'not a LEPIC transaction key: $key',
    );
  }
  return id;
}

/// The transports whose undelivered sends are sent again: Epicbox, HTTP and Tor.
const resendTransports = {'epicbox', 'http', 'tor'};

/// What LEPIC is given when the Node list is empty (`[node] servers = []`): it opens a wallet
/// only with a node address, so it gets one that never answers (an RFC 2606 `.invalid` name
/// never resolves). The app keeps the empty address, so its screens say no node is set, and
/// nothing connects until a node is added.
const noNodeUrl = 'https://no-node.invalid';

/// The same for an empty Epicbox list (`[epicbox] servers = []`): LEPIC gets a server that never
/// answers rather than none, so the wallet still has its address key (the `.wfeh` files are
/// matched by it) and a server added later moves the open wallet onto it like any other
/// change. The app keeps the empty name and shows no address.
const noEpicboxDomain = 'epicbox.invalid';

/// The wait before the one more try of a Tor send whose onion was not reached: a published
/// onion is often reached at the second try, once its circuits are built.
Duration get onionRetryWait => appConfig.onionRetry;

/// Sends over Tor with [send]. When the onion was not reached and the send stayed stored (the
/// one waiting sent payment not in the list before), waits [wait] and delivers it again once
/// with [resend]; its failure is the answer. Never another method.
@visibleForTesting
Future<HttpSent> sendTorRetryingOnce({
  required Future<HttpSent> Function() send,
  required Future<HttpSent> Function(int txId) resend,
  required Future<List<TxEntry>> Function() transactions,
  Duration? wait,
}) async {
  wait ??= onionRetryWait;
  final before = {for (final t in await transactions()) t.key};
  try {
    return await send();
  } on WalletError catch (e) {
    if (e.kind != WalletErrorKind.onionUnreachable) rethrow;
    final left = [
      for (final t in await transactions())
        if (!before.contains(t.key) && t.kind == TxKind.sent && t.status == TxStatus.awaitingRecipient && t.id != null) t,
    ];
    if (left.length != 1) rethrow;
    logInfo('tor', 'onion not reached; one more try in ${wait.inSeconds} s');
    await Future<void>.delayed(wait);
    return resend(left.single.id!);
  }
}

/// A LEPIC transaction as a history row. Keys are `l:<tx id>` ([lepicTxId]) until the merge
/// gives the stable one: a row a scan restored is then known by its output's commitment, which
/// a restore finds again while the id changes. Notes, labels, contacts and imported rows are
/// the app's (H-01), so `note` and `label` stay empty here; `messages` are the slate's, which
/// LEPIC verified.
///
/// [posting]: [d] is finalized and its post may still be under way ([TxEntry.posting]).
TxEntry lepicTxEntry(lepic.TransactionDetails d, {bool sending = false, bool posting = false, String? pairingId}) {
  final outgoing = d.direction == lepic.TxDirection.outgoing;
  final ended =
      d.status == lepic.TxStatus.cancelled ||
      d.status == lepic.TxStatus.expired;
  final status = switch (d.status) {
    lepic.TxStatus.sent => TxStatus.awaitingRecipient,
    lepic.TxStatus.received ||
    lepic.TxStatus.finalized ||
    lepic.TxStatus.posted => TxStatus.awaitingConfirmation,
    lepic.TxStatus.confirmed => TxStatus.confirmed,
    lepic.TxStatus.cancelled || lepic.TxStatus.expired => TxStatus.cancelled,
  };
  final createdAt = d.createdAtMs ~/ 1000;
  final confirmedAt = d.confirmedAtMs == null ? null : d.confirmedAtMs! ~/ 1000;
  final imported = d.imported;
  // An output a scan found with no record; also one the old wallet's own scan found, which it
  // knew no more about.
  final foundByScan =
      d.origin == lepic.TxOrigin.foundByScan ||
      (imported != null &&
          imported.kind == lepic.ImportedTxKind.received &&
          d.slateId == null);
  return TxEntry(
    key: 'l:${d.txId}',
    id: d.txId,
    slateId: d.slateId,
    kind: imported?.kind == lepic.ImportedTxKind.coinbase
        ? TxKind.coinbase
        : switch ((outgoing, ended)) {
            (true, false) => TxKind.sent,
            (true, true) => TxKind.sentCancelled,
            (false, false) => TxKind.received,
            (false, true) => TxKind.receivedCancelled,
          },
    status: status,
    source: foundByScan ? TxSource.restored : TxSource.wallet,
    createdAtUnix: createdAt,
    timeUnix: confirmedAt ?? createdAt,
    confirmed: status == TxStatus.confirmed,
    blockHeight: d.confirmedHeight,
    blockTimeUnix: confirmedAt,
    amountCredited: d.amountCredited,
    amountDebited: d.amountDebited,
    fee: d.fee,
    numInputs: imported?.inputCount ?? 0,
    numOutputs: imported?.outputCount ?? 0,
    kernelExcess: d.kernelExcess,
    outputCommits: d.outputCommits,
    // A row for coins another wallet on this phrase spent or received: confirmed, no fee, no
    // counterparty; the direction picks sent or received.
    origin: d.origin == lepic.TxOrigin.otherWallet ? TxOrigin.otherWallet : TxOrigin.thisWallet,
    spentCommits: d.spentCommits,
    unverified: d.unverified,
    counterparty: d.counterparty,
    transport: d.transport,
    messages: lepicMessages(d.messages),
    ttlCutoffHeight: d.ttlCutoffHeight,
    cancellable:
        d.status == lepic.TxStatus.sent || d.status == lepic.TxStatus.received,
    // Finalized but refused by the node: LEPIC stores it for a repost. While its post may still
    // be under way it is posting instead, never "Not on the network".
    repostable: d.status == lepic.TxStatus.finalized && !posting,
    posting: d.status == lepic.TxStatus.finalized && posting,
    // LEPIC also says undelivered during the first attempt of a send still running: not then.
    // A file send has no delivery to redo.
    undelivered:
        d.undelivered &&
        !sending &&
        outgoing &&
        d.status == lepic.TxStatus.sent &&
        resendTransports.contains(d.transport),
    releasable: d.releasable,
    cancelReason: d.status == lepic.TxStatus.expired
        ? CancelReason.expiry
        : null,
    statusDetail: imported == null ? null : importedDetail(d, imported),
    flow: switch (d.flow) {
      lepic.TxFlow.payment => TxFlow.payment,
      lepic.TxFlow.invoice => TxFlow.invoice,
    },
    foundDuring: switch (d.found?.during) {
      lepic.FoundDuring.restore => TxFoundDuring.restore,
      lepic.FoundDuring.rescan => TxFoundDuring.rescan,
      null => null,
    },
    datedByBlock: d.found?.datedByBlock ?? true,
    senderReportedPostedAtUnix: d.senderReportedPostedAtMs == null
        ? null
        : d.senderReportedPostedAtMs! ~/ 1000,
    senderReportedCancelledAtUnix: d.senderReportedCancelledAtMs == null
        ? null
        : d.senderReportedCancelledAtMs! ~/ 1000,
    pairingId: pairingId,
  );
}

/// Where an imported transaction came from and how the blockchain judged it, in words.
String importedDetail(lepic.TransactionDetails d, lepic.ImportedTx imported) {
  final open =
      d.status == lepic.TxStatus.sent ||
      d.status == lepic.TxStatus.received ||
      d.status == lepic.TxStatus.finalized ||
      d.status == lepic.TxStatus.posted;
  return switch (imported.check) {
    lepic.ChainCheck.cancelledButOnChain => 'The older wallet had cancelled this, but the blockchain has it, so the funds count.',
    lepic.ChainCheck.unspentNotOnChain =>
      'The older wallet showed these funds as unspent, but the blockchain does not have them, '
          'so they are not in the balance.',
    _ when open =>
      'Started in the older wallet and not finished there. Finish or cancel it in the older '
          'wallet; cancelling it here only hides it.',
    _ =>
      'Imported from the older wallet, where it was transaction ${imported.sourceId}.',
  };
}

/// Prefixes every key, so each wallet's LEPIC vault stays apart from the app's other secrets.
class _PrefixedStore implements lepic.SecretStore {
  _PrefixedStore(this._inner, this._prefix);

  final SecretStore _inner;
  final String _prefix;

  @override
  Future<String?> read(String key) => _inner.read('$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _inner.write('$_prefix$key', value);

  @override
  Future<void> delete(String key) => _inner.delete('$_prefix$key');
}

/// [_inner], noting the last [KeyWrapUnavailable] one of its calls threw: LEPIC turns any store
/// failure into its own error, which no longer says that the Keystore refused.
class _RefusalWatch implements lepic.SecretStore {
  _RefusalWatch(this._inner);

  final lepic.SecretStore _inner;
  KeyWrapUnavailable? refused;

  Future<T> _watch<T>(Future<T> call) async {
    try {
      return await call;
    } on KeyWrapUnavailable catch (error) {
      refused = error;
      rethrow;
    }
  }

  @override
  Future<String?> read(String key) => _watch(_inner.read(key));

  @override
  Future<void> write(String key, String value) => _watch(_inner.write(key, value));

  @override
  Future<void> delete(String key) => _watch(_inner.delete(key));
}

class LepicWalletService implements WalletService {
  /// [runtime] is called once, on first use; tests pass a `MockChain` runtime.
  ///
  /// With [oneWalletPerChain] (the app on a device), a chain's store keys stay the same when
  /// its data directory moves ([_storePrefix]). Tests keep several wallets of one chain in one
  /// store, so theirs follow the directory.
  LepicWalletService({
    required this._secrets,
    lepic.LepicRuntime Function()? runtime,
    this.oneWalletPerChain = false,
    this.contactsDir,
    this.keyWrap,
  }) : _makeRuntime = runtime ?? _defaultRuntime;

  final SecretStore _secrets;
  final bool oneWalletPerChain;

  /// Seals each wallet's PIN key and failure count with the phone's secure hardware
  /// ([HardwarePinStore]); null keeps them plain in [_secrets] (desktop, tests).
  final KeyWrap? keyWrap;

  /// The folder of the address book every wallet shares (`contact_store.dart`); null keeps
  /// each wallet's contacts in its own archive (tests).
  final Future<String> Function()? contactsDir;

  /// The prefix pinned for each chain, once read.
  final Map<Chain, String> _pinnedPrefixes = {};
  final lepic.LepicRuntime Function() _makeRuntime;
  lepic.LepicRuntime? _runtimeValue;

  /// Chain of the last wallet config seen, for [validateEpicboxAddress] and [inspectSlate],
  /// which the interface asks without one.
  Chain _chain = Chain.mainnet;

  /// One runtime for every service built without `runtime:`: tests that make several services
  /// share LEPIC's pool and log stream. The phone builds one service.
  static lepic.LepicRuntime? _shared;

  static lepic.LepicRuntime _defaultRuntime() => _shared ??= _newRuntime();

  static lepic.LepicRuntime _newRuntime() {
    // LEPIC has no level setter: Detailed logging reaches it when the runtime starts.
    final runtime = lepic.LepicRuntime(
      logLevel: AppLog.detailed ? lepic.LogLevel.debug : lepic.LogLevel.info,
    );
    // The stream's error reaches the zone instead (UP-11); onError covers a future pin.
    runtime.logs().listen(
      logLepicEntry,
      onError: (Object error) => logWarn('lepic', 'log stream ended: $error'),
    );
    if (AppLog.ringDir case final dir?) unawaited(_openLogRing(runtime, dir));
    return runtime;
  }

  /// Opens LEPIC's log ring in [dir], the folder `startLogging` named, and from then on sends
  /// the app's own lines there too ([AppLog.ring]), so the ring a report attaches holds both,
  /// redacted at the source. Tests name none.
  static Future<void> _openLogRing(lepic.LepicRuntime runtime, String dir) async {
    try {
      await runtime.openLogRing(dir: dir, maxBytes: BigInt.from(logRingBytes));
      AppLog.ring = (level, tag, message) => runtime.logMessage(
        level: switch (level) {
          LogLevel.error => lepic.LogLevel.error,
          LogLevel.warn => lepic.LogLevel.warn,
          LogLevel.info => lepic.LogLevel.info,
          LogLevel.debug => lepic.LogLevel.debug,
        },
        tag: tag,
        message: message,
      );
    } on Object catch (error) {
      logWarn('log', 'no log ring: ${error is lepic.WalletError ? error.kind.name : error.runtimeType}');
    }
  }

  lepic.LepicRuntime get _runtime => _runtimeValue ??= _withMigration(_makeRuntime());

  /// The copy step of the first open after the update that encrypts the records, from LEPIC's
  /// `storeMigrationProgress` ([_withMigration]). Most opens copy nothing and send nothing.
  final StreamController<StoreMigrationProgress> _storeMigration = StreamController<StoreMigrationProgress>.broadcast();

  @override
  Stream<StoreMigrationProgress> get storeMigrationProgress {
    // Subscribed before the open that copies: the screens listen, then open.
    _runtime;
    return _storeMigration.stream;
  }

  /// The copy-step events of every runtime, by runtime: LEPIC keeps one subscriber per runtime
  /// (a new one replaces the old), and services built without `runtime:` share one.
  static final Expando<Stream<StoreMigrationProgress>> _migrationOf = Expando('store migration');

  /// [runtime], with its copy-step events subscribed once, before any open, and passed on to
  /// [storeMigrationProgress].
  lepic.LepicRuntime _withMigration(lepic.LepicRuntime runtime) {
    try {
      final events = _migrationOf[runtime] ??= runtime.storeMigrationProgress().map(lepicStoreMigrationProgress).asBroadcastStream();
      events.listen(
        _storeMigration.add,
        onError: (Object error) => logWarn('store', 'copy progress ended: ${error is lepic.WalletError ? error.kind.name : error.runtimeType}'),
      );
    } on Object catch (error) {
      // A runtime with no copy events (a test double): the opens report none.
      logWarn('store', 'no copy progress: ${error.runtimeType}');
    }
    return runtime;
  }

  /// LEPIC keeps its database in a subdirectory, so it never meets epic-wallet's `wallet_data/`
  /// or the app's `wfe_meta.json` beside it.
  Future<lepic.WalletConfig> _config(WalletConfig config) {
    _chain = config.chain;
    final dir = Directory('${config.dataDir}${Platform.pathSeparator}lepic')
      ..createSync(recursive: true);
    return _lepicConfig(config, dir.path);
  }

  /// Whether the Tor switch is on for [config]'s wallet, asked before its session opens. LEPIC
  /// then waits for tor from the first connection (`WalletConfig.torWanted`), so a tor that
  /// never starts (no tor bundle) blocks the node, Epicbox and Direct sends instead of letting
  /// them go directly. Each app's main sets it; without it (tests, the web) no tor is wanted.
  static Future<bool> Function(WalletConfig config)? torWantedFor;

  /// What LEPIC is given for [config] (tests).
  @visibleForTesting
  static Future<lepic.WalletConfig> lepicConfigOf(WalletConfig config) => _lepicConfig(config, config.dataDir);

  /// A plain-http node on the local network goes to LEPIC through a loopback relay
  /// ([lanNodeUrl]): LEPIC refuses plain http to anything but loopback. The onion routes are
  /// the settings file's TLS ones ([settingsOnionRoutes]) from the first connection; the app
  /// replaces them later with [WalletSession.setOnionRoutes] (the signed list).
  static Future<lepic.WalletConfig> _lepicConfig(WalletConfig config, String dataDir) async =>
      lepic.WalletConfig(
        policy: const lepic.HostPolicy(),
        dataDir: dataDir,
        chain: _lepicChain(config.chain),
        nodeUrl: config.nodeUrl.trim().isEmpty ? noNodeUrl : await lanNodeUrl(config.nodeUrl),
        nodeApiSecret: config.nodeApiSecret,
        epicboxDomain: config.epicboxDomain.trim().isEmpty ? noEpicboxDomain : config.epicboxDomain,
        epicboxPort: config.epicboxPort,
        onionRoutes: [
          for (final r in settingsOnionRoutes())
            lepic.OnionRoute(host: r.host, port: r.port, onion: r.onion, onionPort: r.onionPort),
        ],
        tuning: netTuningOf(appConfig),
        offline: config.offline,
        // Kill switch runs no tor, and the build without Tor has none.
        torWanted: torBuilt && !config.offline && await (torWantedFor?.call(config) ?? Future.value(false)),
        hostFeatures: appHostFeatures,
        profile: 0,
      );

  /// The wallet core's timeouts, retries and limits: `[node]`, `[epicbox]`, `[http]` and `[tor]`
  /// of `app-config.toml`, under the same names (LEPIC's ADR 0030).
  static lepic.NetTuning netTuningOf(AppConfig c) => lepic.NetTuning(
    node: lepic.NodeTuning(
      connectTimeoutS: c.number('node.connect_timeout_s'),
      requestTimeoutS: c.number('node.request_timeout_s'),
      idleTimeoutS: c.number('node.idle_timeout_s'),
      retryAttempts: c.number('node.retry_attempts'),
      retryBackoffMinMs: c.number('node.retry_backoff_min_ms'),
      retryBackoffMaxMs: c.number('node.retry_backoff_max_ms'),
      outputsPerRequest: c.number('node.outputs_per_request'),
      concurrentRequests: c.number('node.concurrent_requests'),
    ),
    epicbox: lepic.EpicboxTuning(
      connectTimeoutS: c.number('epicbox.connect_timeout_s'),
      responseTimeoutS: c.number('epicbox.response_timeout_s'),
      pingIntervalS: c.number('epicbox.ping_interval_s'),
      reconnectMinS: c.number('epicbox.reconnect_min_s'),
      reconnectMaxS: c.number('epicbox.reconnect_max_s'),
      drainTimeoutS: c.number('epicbox.drain_timeout_s'),
      torConnectTimeoutS: c.number('epicbox.tor_connect_timeout_s'),
      onionDiscoveryTimeoutS: c.number('epicbox.onion_discovery_timeout_s'),
      onionDiscoveryRetryS: c.number('epicbox.onion_discovery_retry_s'),
    ),
    http: lepic.HttpTuning(
      headerTimeoutS: c.number('http.header_timeout_s'),
      bodyTimeoutS: c.number('http.body_timeout_s'),
      requestTimeoutS: c.number('http.request_timeout_s'),
      answerTimeoutS: c.number('http.answer_timeout_s'),
      maxConnections: c.number('http.max_connections'),
      maxConnectionsPerAddress: c.number('http.max_connections_per_address'),
      requestsPerMinute: c.number('http.requests_per_minute'),
      receivesPerMinute: c.number('http.receives_per_minute'),
      sendConnectTimeoutS: c.number('http.send_connect_timeout_s'),
      sendRequestTimeoutS: c.number('http.send_request_timeout_s'),
    ),
    tor: lepic.TorTuning(
      bootstrapTimeoutS: c.number('tor.bootstrap_timeout_s'),
      coldBootstrapTimeoutS: c.number('tor.cold_bootstrap_timeout_s'),
      stallTimeoutS: c.number('tor.stall_timeout_s'),
      coldStallTimeoutS: c.number('tor.cold_stall_timeout_s'),
      publishTimeoutS: c.number('tor.publish_timeout_s'),
      connectTimeoutS: c.number('tor.connect_timeout_s'),
      requestTimeoutS: c.number('tor.request_timeout_s'),
    ),
  );

  /// The settings file's onion routes LEPIC takes: TLS ones only (the connection still checks
  /// the host's certificate). None before the settings are open (a bare core check).
  static List<OnionRoute> settingsOnionRoutes() => [
    if (hostSettingsLoaded)
      for (final r in hostSettings.torOnions)
        if (r.tls) r,
  ];

  /// `<anything>/wallets/<32 hex>/<chain>`, the folder of a registry wallet.
  static final RegExp _registryFolder = RegExp(
    r'[\\/]wallets[\\/][0-9a-f]{32}[\\/](mainnet|floonet|usernet)[\\/]?$',
  );

  /// The prefix of the wallet's LEPIC entries in the app's store.
  ///
  /// It used to name the absolute data directory, which moves with an app container or a
  /// profile. With [oneWalletPerChain] the prefix is pinned once per chain under
  /// [storePrefixKey]: a wallet created before pinning keeps the path prefix its entries
  /// already have, and a new wallet gets a random id. Nothing is copied or deleted. Until a
  /// prefix is pinned, everything but [creating] uses the path prefix. A registry wallet
  /// ([WalletConfig.walletId], other than `legacy-…`) skips all that: its prefix is
  /// `lepic:<chain>:id-<walletId>:`.
  Future<String> _storePrefix(
    WalletConfig config, {
    bool creating = false,
  }) async {
    final chain = config.chain;
    final id = config.walletId;
    if (id != null && !id.startsWith('legacy-')) {
      return 'lepic:${chain.name}:id-$id:';
    }
    final pathPrefix = 'lepic:${chain.name}:${config.dataDir}:';
    if (!oneWalletPerChain) return pathPrefix;
    if (id == null && _registryFolder.hasMatch(config.dataDir)) {
      // A registry wallet's config lost its id: wallet 1's pinned prefix would be wrong.
      throw StateError('a registry wallet config needs its walletId');
    }
    final cached = _pinnedPrefixes[chain];
    if (cached != null) return cached;
    final pinKey = storePrefixKey(chain);
    final pinned = await _secrets.read(pinKey);
    if (pinned != null) return _pinnedPrefixes[chain] = pinned;
    final String prefix;
    if (await lepic.walletExists(
      runtime: _runtime,
      store: lepic.lepicSecretStore(_PrefixedStore(_secrets, pathPrefix)),
    )) {
      prefix = pathPrefix;
    } else if (creating) {
      final random = Random.secure();
      final id = [
        for (var i = 0; i < 16; i++)
          random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();
      prefix = 'lepic:${chain.name}:id-$id:';
    } else {
      return pathPrefix;
    }
    await _secrets.write(pinKey, prefix);
    if (await _secrets.read(pinKey) != prefix) {
      throw StateError('the store did not keep the wallet key prefix');
    }
    logInfo('lepic', 'pinned the ${chain == Chain.mainnet ? '' : '${chain.name} '}wallet store keys');
    return _pinnedPrefixes[chain] = prefix;
  }

  /// [_storePrefix] for tests. A registry wallet's prefix needs no runtime or pin.
  @visibleForTesting
  Future<String> storePrefixFor(WalletConfig config) => _storePrefix(config);

  /// Where the store keeps the pinned prefix of [chain]'s wallet entries.
  static String storePrefixKey(Chain chain) =>
      'lepic:${chain.name}:storePrefix';

  Future<_PrefixedStore> _storeKeys(
    WalletConfig config, {
    bool creating = false,
  }) async {
    final prefix = await _storePrefix(config, creating: creating);
    final wrap = keyWrap;
    return _PrefixedStore(
      wrap == null ? _secrets : HardwarePinStore(_secrets, wrap, prefix),
      prefix,
    );
  }

  Future<lepic.AppSecretStore> _store(
    WalletConfig config, {
    bool creating = false,
  }) async =>
      lepic.lepicSecretStore(await _storeKeys(config, creating: creating));

  @override
  bool validateMnemonic({required String phrase}) =>
      lepic.validateMnemonic(phrase: phrase);

  @override
  String walletFingerprint({required String mnemonic, required Chain chain}) =>
      _guardSync(
        () => lepic.walletFingerprint(
          mnemonic: mnemonic,
          chain: _lepicChain(chain),
        ),
      );

  /// The open wallet's rows: null while no wallet is open, for an address LEPIC refuses (it
  /// does not parse, or is on the other network) and for a key nothing is known about. The
  /// trust policy treats null as the safe default.
  @override
  Future<PeerCompat?> peerCompat(String address) async {
    final session = _open;
    if (session == null) return null;
    try {
      return await session.peerCompat(address);
    } on WalletError catch (e) {
      if (e.kind == WalletErrorKind.invalidArgument) return null;
      rethrow;
    }
  }

  @override
  Future<SlateInfo> inspectSlate({required String json}) => _guard(
    () async => lepicSlateInfo(
      await lepic.inspectSlate(json: json, chain: _lepicChain(_chain)),
    ),
  );

  @override
  Future<List<String>> encodeQrSlate({
    required String json,
    required int maxFragmentLen,
  }) => _guard(
    () => lepic.encodeUrSlate(json: json, maxFragmentLen: maxFragmentLen),
  );

  @override
  Future<QrSlateProgress> decodeQrSlate({required List<String> parts}) => _guard(
    () async {
      final p = await lepic.decodeUrSlate(parts: parts);
      return QrSlateProgress(
        complete: p.complete,
        received: p.receivedFragments,
        count: p.fragmentCount,
        json: p.json,
      );
    },
  );

  @override
  bool validateEpicboxAddress({required String address}) => lepic
      .validateEpicboxAddress(address: lepicEpicboxAddress(address), chain: _lepicChain(_chain));

  @override
  Future<bool> verifyListingSignature(
    String publicKeyText,
    String domain,
    Uint8List message,
    Uint8List der,
  ) async {
    try {
      return lepic.verifyAddressSignatureAt(
        publicKey: publicKeyText,
        domain: domain,
        message: message,
        signature: toHex(der),
      );
    } on Object {
      return false;
    }
  }

  @override
  bool epicboxAddressOtherChain({required String address}) =>
      lepic.validateEpicboxAddress(
        address: lepicEpicboxAddress(address),
        chain: _lepicChain(_chain) == lepic.Chain.mainnet
            ? lepic.Chain.floonet
            : lepic.Chain.mainnet,
      );

  @override
  bool validateOnionAddress({required String address}) =>
      lepic.validateOnionAddress(address: address);

  @override
  Future<bool> walletExists({required WalletConfig config}) => _guard(
    () async =>
        lepic.walletExists(runtime: _runtime, store: await _store(config)),
  );

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) => _guard(() async {
    // Node only: the node in use alone, not the others of the list (their checks). Kill
    // switch asks nothing. No wallet is open, so LEPIC has no tor: the request goes through
    // the app's tor while that carries the app's requests, directly only where the Tor
    // switch is off, and never directly to a node off this network while it is on.
    NetGate.dial(NetDial.http, config.nodeUrl);
    final route = nodeRouteFor(config.nodeUrl);
    // LEPIC asks the node only: no wallet folder is made (the setup screen's test passes an
    // empty one, which made `/lepic` and failed) and the open wallet's chain stays.
    final tip = await lepic.nodeTip(
      runtime: _runtime,
      config: await _lepicConfig(config, config.dataDir),
      route: route,
    );
    return NodeTip(
      height: tip.height,
      nodeVersion: tip.nodeVersion,
      readyForTxs: tip.readyForTxs,
    );
  });

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
    BigInt? restoreFromHeight,
  }) => _guard(
    () async {
      _requireNewPassword(password);
      return _session(
        config,
        await lepic.EpicWallet.create(
          runtime: _runtime,
          config: await _config(config),
          store: await _store(config, creating: true),
          mnemonic: mnemonic,
          password: password,
          restoreFromHeight: restoreFromHeight,
        ),
      );
    },
  );

  @override
  Future<WalletSession> importWalletSeed({
    required WalletConfig config,
    required String seedFile,
    required String seedPassword,
    required String password,
  }) => _guard(
    () async {
      _requireNewPassword(password);
      return _session(
        config,
        await lepic.EpicWallet.importWalletSeed(
          runtime: _runtime,
          config: await _config(config),
          store: await _store(config, creating: true),
          seedFile: seedFile,
          seedPassword: seedPassword,
          password: password,
        ),
      );
    },
  );

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) => _guard(
    () async => _session(
      config,
      await lepic.EpicWallet.open(
        runtime: _runtime,
        config: await _config(config),
        store: await _store(config),
        password: password,
      ),
    ),
  );

  /// [wallet] with its history archive, `<dataDir>/wfe_meta.json`. A wallet whose archive
  /// cannot be read is closed again.
  Future<LepicWalletSession> _session(
    WalletConfig config,
    lepic.EpicWallet wallet,
  ) async {
    final sealer = LepicAppDataSealer(wallet);
    final walletId = sealedWalletId(config.walletId, config.chain.name);
    ContactStore? contacts;
    try {
      contacts = await _sharedContacts(walletId, sealer);
      final session = (await LepicWalletSession.openOn(
        wallet,
        config.dataDir,
        config.chain,
        contacts: contacts,
        sealer: sealer,
        walletId: walletId,
      ))
        ..nodeUrl = config.nodeUrl
        ..nodeApiSecret = config.nodeApiSecret;
      await session.readStoreOpen();
      // The open wallet, for [peerCompat]; forgotten when the session goes.
      _open = session;
      session.onDispose = () {
        if (identical(_open, session)) _open = null;
      };
      return session;
    } catch (_) {
      await contacts?.detach(walletId, sealer);
      wallet.lock();
      wallet.dispose();
      rethrow;
    }
  }

  /// The session opened last and not disposed yet, whose store [peerCompat] reads.
  LepicWalletSession? _open;

  /// The shared address book, sealed, with this wallet attached; null without [contactsDir]. A
  /// book that cannot be read (its folder unreadable) never keeps a wallet from opening: the
  /// wallet then keeps its own list.
  Future<ContactStore?> _sharedContacts(String walletId, AppDataSealer sealer) async {
    final dir = contactsDir;
    if (dir == null) return null;
    try {
      return await ContactStore.openSealed(await dir(), walletId, sealer);
    } on Object catch (e) {
      logWarn('contacts', 'the shared address book could not be opened (${e.runtimeType})');
      return null;
    }
  }

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
    BigInt? restoreFromHeight,
  }) => _guard(() async {
    final created = await lepic.EpicWallet.createWithPin(
      runtime: _runtime,
      config: await _config(config),
      store: await _store(config, creating: true),
      mnemonic: mnemonic,
      pin: pin,
      restoreFromHeight: restoreFromHeight,
    );
    return (
      session: await _session(config, created.wallet) as WalletSession,
      sealedPassword: created.sealedPassword,
    );
  });

  /// A store failure while the Keystore refused one of the calls throws that refusal
  /// ([KeyWrapUnavailable]): the wallet is intact, and the unlock screen says so.
  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) async {
    _RefusalWatch? store;
    try {
      return await _guard(() async {
        final walletConfig = await _config(config);
        final watched = store = _RefusalWatch(await _storeKeys(config));
        return _session(
          config,
          await lepic.EpicWallet.openWithPin(
            runtime: _runtime,
            config: walletConfig,
            store: lepic.lepicSecretStore(watched),
            pin: pin,
            sealedPassword: sealedPassword,
          ),
        );
      });
    } on WalletError catch (error) {
      final refused = store?.refused;
      if (error.kind != WalletErrorKind.io || refused == null) rethrow;
      logWarn('unlock', 'the Keystore refused the PIN key (${refused.code})');
      throw refused;
    }
  }

  /// LEPIC keeps the count in the wallet's store as `lepic.pin-failures` (documented on
  /// `EpicWallet.openWithPin`). A count that does not parse costs LEPIC the longest wait, so it
  /// reads as a large one here too.
  ///
  /// The count is read before a PIN is tried (the unlock screen, the PIN prompt): with
  /// [keyWrap], the Keystore key that attempt rotates to is made meanwhile, while the user
  /// types ([HardwarePinStore.prepareNextKey]).
  @override
  Future<int> pinFailures({required WalletConfig config}) async {
    final text = await (await _storeKeys(config)).read('lepic.pin-failures');
    final wrap = keyWrap;
    if (wrap != null) {
      unawaited(HardwarePinStore(_secrets, wrap, await _storePrefix(config)).prepareNextKey());
    }
    if (text == null) return 0;
    return int.tryParse(text.trim()) ?? 0x7fffffff;
  }

  @override
  Future<void> deleteWallet({required WalletConfig config}) => _guard(() async {
    await lepic.deleteWallet(
      runtime: _runtime,
      config: await _config(config),
      store: await _store(config),
    );
    // After LEPIC, which refuses while a wallet on the directory is open.
    await MetaStore.deleteFiles(config.dataDir);
    // Only this wallet's key to the shared book; the book goes with the last one.
    final dir = contactsDir;
    if (dir != null) {
      await ContactStore.removeWalletKey(await dir(), sealedWalletId(config.walletId, config.chain.name));
    }
  });

  @override
  Future<void> resetPassword({
    required WalletConfig config,
    required String mnemonic,
    required String newPassword,
  }) => _guard(() async {
    _requireNewPassword(newPassword);
    return lepic.resetPassword(
      runtime: _runtime,
      config: await _config(config),
      store: await _store(config),
      mnemonic: mnemonic,
      newPassword: newPassword,
    );
  });
}

/// What a history file names as the program that wrote it. Informational only.
const String historyAppVersion = 'wfe-lepic';

/// The files LEPIC keeps in a wallet's `lepic` folder once it encrypts
/// the records. The first open copies the plain database into the encrypted one, checks it and
/// switches, then renames the plain one aside; a plain database an older build made after a
/// rollback is set aside by its time. Never renamed: they are on disk (install contract).
const String lepicPlainStoreFile = 'wallet.sqlite3';
const String lepicEncryptedStoreFile = 'wallet.enc.sqlite3';
const String lepicStoreCheckFile = 'wallet.enc.sqlite3.check';
const String lepicPreEncryptionFile = 'wallet.sqlite3.pre-encryption';
const String lepicAfterRollbackPrefix = 'wallet.sqlite3.after-rollback-';

/// The app's files sealed by an open LEPIC wallet (`sealed_file.dart`): LEPIC's `sealAppData`
/// and `openAppData`, with LEPIC's refusals as [SealedOpenError].
class LepicAppDataSealer implements AppDataSealer {
  LepicAppDataSealer(this._wallet);

  final lepic.EpicWallet _wallet;

  @override
  Future<Uint8List> seal(Uint8List payload) async {
    try {
      return await _wallet.sealAppData(payload: payload);
    } on lepic.WalletError catch (e) {
      throw mapLepicError(e);
    }
  }

  @override
  Future<Uint8List> open(Uint8List file) async {
    try {
      return await _wallet.openAppData(file: file);
    } on lepic.WalletError catch (e) {
      throw switch (e.kind) {
        lepic.WalletErrorKind.foreignAppData => const SealedOpenError(SealedOpenProblem.foreign),
        lepic.WalletErrorKind.damagedAppData => const SealedOpenError(SealedOpenProblem.damaged),
        lepic.WalletErrorKind.unsupported => const SealedOpenError(SealedOpenProblem.newer),
        lepic.WalletErrorKind.invalidArgument => const SealedOpenError(SealedOpenProblem.notOurs),
        _ => mapLepicError(e),
      };
    }
  }
}

/// An open LEPIC wallet. Public so tests can wrap a stand-in `EpicWallet`; without [history]
/// it keeps notes and contacts in memory only.
class LepicWalletSession implements WalletSession, EpicboxDrainAt, ListingKeys {
  LepicWalletSession(
    this._wallet, {
    WalletHistory? history,
  }) : _history = history ?? WalletHistory.memory() {
    // The record as it was before this session's first refresh replaces it.
    final at = _history.lastActivity?.atUnix;
    _lastActivityAtOpen = at == null ? null : DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true);
  }

  /// The node the wallet uses (open, then [setServers]). Offline still lets a refresh, a scan
  /// or the HTTP listener run when it is local ([isLocalAddressUrl]); null counts as not local.
  String? nodeUrl;

  /// The node in use's API secret, for the app's own post of a finished payment.
  String? nodeApiSecret;


  /// [_guard] for a payment call that reaches only the node (a transaction file or QR Payment
  /// made, signed, finalized or posted, an estimate): Node only lets it use the node in use;
  /// in Kill switch LEPIC makes, signs and finalizes without a node and refuses the posting
  /// itself (its own gate), so nothing is checked here. A refusal is logged under [what].
  Future<T> _nodeGuard<T>(String what, Future<T> Function() call) async {
    try {
      return await _guard(call);
    } on WalletError catch (e) {
      logInfo('wallet', '$what refused: ${e.kind.name}');
      rethrow;
    }
  }

  /// [_netStream] for a stream that reaches only the node and is not a payment (a scan):
  /// Node only lets it run, Kill switch refuses it.
  Stream<T> _nodeStream<T>(String what, Stream<T> Function() make) => NetGate.killSwitch
      ? Stream.error(NetBlocked(NetGate.mode, what))
      : _guardStream(make());

  /// The address a Direct send goes to, as given; refused in Node only and Kill switch (no Link
  /// at all). With the Tor switch on, plain `http` off this computer is refused.
  Future<String> _directUrl(String url, String what) async {
    NetGate.check(what);
    _torRefusesPlainHttp(url, what);
    return url;
  }

  /// [wallet] with the archive in [dataDir], as every open does. Public so tests can drive it with a stand-in wallet.
  @visibleForTesting
  /// With [sealer] and [walletId] the archive is sealed (`wfe_meta.sealed`) and [contacts] is
  /// the sealed book this wallet is attached to, detached again on [dispose].
  static Future<LepicWalletSession> openOn(
    lepic.EpicWallet wallet,
    String dataDir,
    Chain chain, {
    ContactStore? contacts,
    AppDataSealer? sealer,
    String? walletId,
  }) async {
    final history = await WalletHistory.open(dataDir, chain, contacts: contacts, sealer: sealer, walletId: walletId);
    try {
      await history.seedContacts(bundledSeedContacts);
    } on Object catch (e) {
      logWarn('contacts', 'seed contacts not added (${e.runtimeType})');
    }
    final session = LepicWalletSession(wallet, history: history);
    if (contacts != null && contacts.sealed && sealer != null && walletId != null) {
      session._detachBook = () => contacts.detach(walletId, sealer);
    }
    return session;
  }

  /// Ends this wallet's use of the sealed address book.
  Future<void> Function()? _detachBook;

  /// How LEPIC found the records at this unlock (`storeAtRest`), read once by
  /// `LepicWalletService._session` right after the open.
  @override
  StoreOpenOutcome get storeOpen => _storeOpen;
  StoreOpenOutcome _storeOpen = StoreOpenOutcome.encrypted;

  /// Reads [storeOpen] from LEPIC, then retires the plain copies (see [_retirePlainCopies]). A
  /// wallet that cannot say (a test double) counts as encrypted, which shows no fallback notice,
  /// and retires nothing.
  @visibleForTesting
  Future<void> readStoreOpen() async {
    try {
      _storeOpen = lepicStoreOpen(await _wallet.storeAtRest());
    } on Object catch (error) {
      logWarn('store', 'open state not read: ${error is lepic.WalletError ? error.kind.name : error.runtimeType}');
      return;
    }
    if (_storeOpen != StoreOpenOutcome.plainFallback) await _retirePlainCopies();
  }

  /// Days an `after-rollback` plain database is kept before [_retirePlainCopies] deletes it, so
  /// a downgrade made a few weeks ago can still be looked at. The `pre-encryption` copy goes at
  /// once: encryption shipped in 26.10.25 and LEPIC ADR 0032 has the app retire it one release on.
  static const _afterRollbackKeepDays = 30;

  /// Deletes the plaintext database copies left by the move to encryption, once per unlock and
  /// never on a plain fallback. Never fails or delays the unlock: an error is logged by kind only
  /// (a message could carry a path).
  Future<void> _retirePlainCopies() async {
    try {
      final r = await _wallet.retirePlainStore(olderThanDays: _afterRollbackKeepDays);
      if (r.deleted.isNotEmpty || r.kept.isNotEmpty) {
        logInfo('store', 'plain copies retired: ${r.deleted.length} deleted, ${r.kept.length} kept');
      }
    } on Object catch (error) {
      logWarn('store', 'plain copies not retired: ${error is lepic.WalletError ? error.kind.name : error.runtimeType}');
    }
  }

  @override
  bool get contactsAvailable => _history.contactsAvailable;

  @override
  DateTime? get lastActivityAtOpen => _lastActivityAtOpen;
  DateTime? _lastActivityAtOpen;

  /// The least time between two saves of the activity record: refresh runs often.
  static const _activityEvery = Duration(minutes: 1);
  DateTime? _activitySavedAt;

  /// Saves that the wallet just synced to [height]: the time (UTC) and the height, in the
  /// history archive. At most once a [_activityEvery]; a failed write is logged and tried again
  /// on the next sync. Never delays or fails the sync.
  void _recordActivity(BigInt height) {
    final now = DateTime.now().toUtc();
    final saved = _activitySavedAt;
    if (saved != null && now.difference(saved) < _activityEvery) return;
    _activitySavedAt = now;
    unawaited(
      _history.recordActivity(now, height).catchError((Object error) {
        _activitySavedAt = null;
        logWarn('history', 'last activity not saved (${error.runtimeType})');
      }),
    );
  }

  final lepic.EpicWallet _wallet;
  final WalletHistory _history;

  /// Told once, first thing in [dispose]: the service drops its handle on this session.
  void Function()? onDispose;

  @override
  void dispose() {
    onDispose?.call();
    onDispose = null;
    _walletEvents?.cancel();
    _walletEvents = null;
    _pairing.close();
    _invoiceEvents.close();
    _issuerEvents.close();
    _unmatched.close();
    _history.close();
    final detach = _detachBook;
    _detachBook = null;
    if (detach != null) unawaited(detach());
    if (_wallet.isDisposed) return;
    _wallet.lock();
    _wallet.dispose();
  }

  /// LEPIC's rows, before the archive is merged in, each with the pairing it was exchanged
  /// with.
  Future<List<TxEntry>> _live() async {
    final rows = [
      for (final d in await _wallet.transactions())
        lepicTxEntry(d, sending: _sending > 0, posting: _posting(d), pairingId: await _pairingOfTx(d)),
    ];
    _listed = true;
    return rows;
  }

  /// When each finalized row was first read finalized; [_settled] for one whose post is known
  /// to have ended (it was already finalized at the first list read, or the app's own post of
  /// it ended). LEPIC stores a finalize, and tells the app, before it posts, so a row read
  /// meanwhile is finalized for as long as the node takes to answer (the listener's finalize
  /// of an Epicbox reply, whose post the app never sees end).
  final Map<int, DateTime> _finalizedSeen = {};
  static final DateTime _settled = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether the first full list read is done ([_finalizedSeen]).
  bool _listed = false;

  /// The clock [_posting] reads; tests move it.
  @visibleForTesting
  static DateTime Function() postingClock = DateTime.now;

  /// Whether [d] is finalized and its post may still be under way: first read finalized under
  /// [postingFor] ago, and no post of it known to have ended. After that a row still finalized
  /// was refused or not reached, and reads "Not on the network".
  bool _posting(lepic.TransactionDetails d) {
    if (d.status != lepic.TxStatus.finalized) {
      _finalizedSeen.remove(d.txId);
      return false;
    }
    final now = postingClock();
    final seen = _finalizedSeen.putIfAbsent(d.txId, () => _listed ? now : _settled);
    return now.difference(seen) < postingFor;
  }

  /// Runs [post], one of the app's own posts, and then counts the rows it may have posted
  /// ([txId], or every row being posted when unknown) as settled: a refusal it met shows at once.
  Future<T> _posted<T>(Future<T> Function() post, {int? txId}) async {
    try {
      return await post();
    } finally {
      if (txId != null) {
        _finalizedSeen[txId] = _settled;
      } else {
        _finalizedSeen.updateAll((_, _) => _settled);
      }
    }
  }

  /// The pairing [d] was sealed to or from ([_contactOfTx]), asked only of the rows a pairing
  /// can make: a mailbox payment or a sealed file either way, which have no counterparty
  /// (LEPIC keeps them as file exchanges, and a mailbox send as `epicbox` once its answer is
  /// in), and a request. A row with none is asked again while it is open, as LEPIC links a
  /// receive to its pairing just after storing it: at every read in its first [_noContactFor],
  /// then after [_noContactFor] or at LEPIC's next event.
  Future<String?> _pairingOfTx(lepic.TransactionDetails d) async {
    if (d.origin != lepic.TxOrigin.wallet) return null;
    if (d.counterparty != null && d.flow != lepic.TxFlow.invoice) return null;
    final asked = _noContactAt[d.txId];
    if (asked != null && DateTime.now().difference(asked) >= _noContactFor) {
      _txContacts.remove(d.txId);
      _noContactAt.remove(d.txId);
    }
    final fresh = !_txContacts.containsKey(d.txId);
    final contact = await _contactOfTx(d.txId);
    final ended = d.status == lepic.TxStatus.confirmed ||
        d.status == lepic.TxStatus.cancelled ||
        d.status == lepic.TxStatus.expired;
    if (contact != null || ended) {
      _noContactAt.remove(d.txId);
    } else if (DateTime.now().millisecondsSinceEpoch - d.createdAtMs.toInt() < _noContactFor.inMilliseconds) {
      // Stored under a minute ago: LEPIC may link it any moment, so every read asks, as before.
      _txContacts.remove(d.txId);
      _noContactAt.remove(d.txId);
    } else if (fresh) {
      _noContactAt[d.txId] = DateTime.now();
    }
    return contact;
  }

  /// When an open row was last found with no pairing ([_pairingOfTx]).
  final Map<int, DateTime> _noContactAt = {};

  /// How long an open row's "no pairing" answer is kept.
  static const Duration _noContactFor = Duration(seconds: 60);

  /// Asks the open rows with no pairing again at the next list read.
  void _askNoContactAgain() {
    for (final id in _noContactAt.keys) {
      _txContacts.remove(id);
    }
    _noContactAt.clear();
  }

  /// The stored row of [txId], as the history shows it. Only its own pairing is asked: the
  /// history takes a row's pairing from that row alone.
  Future<TxEntry> _entry(int txId) async {
    final live = [
      for (final d in await _wallet.transactions())
        lepicTxEntry(d, sending: _sending > 0, posting: _posting(d), pairingId: d.txId == txId ? await _pairingOfTx(d) : null),
    ];
    final shown = _history
        .transactions(live)
        .where((t) => t.id == txId)
        .firstOrNull;
    if (shown != null) return shown;
    final d = await _wallet.transaction(txId: txId);
    return lepicTxEntry(d, sending: _sending > 0, posting: _posting(d));
  }

  /// The LEPIC id behind a history key: `l:<id>`, a key ending `#l<id>` (one side of a
  /// self-send), or the row shown under [key]. The keys do not depend on the pairings, so none
  /// is asked.
  Future<int> _txIdOf(String key) async {
    if (key.startsWith('l:')) return lepicTxId(key);
    final own = RegExp(r'#l(\d+)$').firstMatch(key);
    if (own != null) return int.parse(own.group(1)!);
    final id = _history
        .transactions([
          for (final d in await _wallet.transactions()) lepicTxEntry(d, sending: _sending > 0, posting: _posting(d)),
        ])
        .where((t) => t.key == key)
        .firstOrNull
        ?.id;
    return id ?? lepicTxId(key);
  }

  @override
  Future<String> mnemonic({required String password}) =>
      _guard(() => _wallet.mnemonic(password: password));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() {
    _requireNewPassword(newPassword);
    return _wallet.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  });

  @override
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  }) => _guard(
    () => _wallet.mnemonicWithPin(pin: pin, sealedPassword: sealedPassword),
  );

  @override
  Future<void> checkPin({
    required String pin,
    required String sealedPassword,
  }) => _guard(() => _wallet.checkPin(pin: pin, sealedPassword: sealedPassword));

  @override
  Future<bool> checkPassword({required String password}) =>
      _guard(() => _wallet.checkPassword(password: password));

  @override
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  }) => _guard(
    () => _wallet.changePin(
      sealedPassword: sealedPassword,
      oldPin: oldPin,
      newPin: newPin,
    ),
  );

  @override
  Future<void> confirmPinChange({required String sealedPassword}) =>
      _guard(() => _wallet.confirmPinChange(sealedPassword: sealedPassword));

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _guard(() => _wallet.cancelTransaction(txId: txId));

  /// What LEPIC learned about the key at [address] ([lepicPeerCompat]); null for a key nothing
  /// is known about. Throws [WalletErrorKind.invalidArgument] for an address LEPIC refuses.
  Future<PeerCompat?> peerCompat(String address) =>
      _guard(() async => lepicPeerCompat(await _wallet.peerCompat(address: address)));

  @override
  Future<void> forgetPeers({required Duration olderThan}) => _guard(() async {
    final forgotten = await _wallet.forgetPeers(olderThanDays: olderThan.inDays);
    // A count only: the keys themselves never reach the log.
    if (forgotten > 0) logDebug('trust', 'forgot $forgotten silent peers');
  });

  @override
  Future<void> repostTransaction({required String key}) =>
      _nodeGuard('repost', () async {
        final txId = await _txIdOf(key);
        return _posted(() => _wallet.repostTransaction(txId: txId), txId: txId);
      });

  // The cold flow (Kill switch). The finished payment's text is LEPIC's (its finishedPayment
  // getter: the stored S3, or an issued invoice's I3); reading and posting one is
  // the app's own (finished_payment.dart), through the node in use and the network mode's gate.

  @override
  Future<String> finishedPaymentText({required int txId}) => _guard(() => _wallet.finishedPayment(txId: txId));

  @override
  Future<FinishedPayment> inspectFinished(String text) async => readFinishedPayment(text).payment;

  @override
  Future<void> postFinished(String text) async {
    final node = nodeUrl;
    if (node == null || node.trim().isEmpty) {
      NetGate.checkNode('post finished');
      throw const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'post finished: no node');
    }
    await pushFinishedPayment(text, nodeUrl: node, nodeApiSecret: nodeApiSecret);
  }

  @override
  Future<void> releaseStuckSend({required String key}) =>
      _nodeNetGuard('release', () async => _wallet.releaseTransaction(txId: await _txIdOf(key)));

  /// The amount [estimateMax] last returned. A send of exactly the wallet's current maximum is
  /// a send-all and takes every coin into one change output, as the max estimate did, so fee
  /// and amount match.
  BigInt? _maxAmount;

  /// Send-all: every coin but the [heldOutputs] into one change output.
  lepic.SendOptions get _sendAll => lepic.SendOptions(
    strategy: lepic.SelectionStrategy.all,
    changeOutputs: 1,
    excludeOutputs: heldOutputs.isEmpty ? const [] : [...heldOutputs],
  );

  // Every call that chooses coins passes [heldOutputs] to LEPIC: sends through [_optionsFor] or
  // [estimateMax], invoice payments and request files through [_heldOnly]; a non-empty set turns
  // LEPIC's default, null, into the standard options with the exclusion. Split and Consolidate
  // take no exclusion in LEPIC, so they wait while any coin is held ([_noneHeld]).
  @override
  Set<String> heldOutputs = const {};

  // LEPIC's kernel lookup. A failure stays a failure: the linked devices read it as "unknown",
  // never as "absent" (null), which would end payments that are still on their way.
  @override
  Future<KernelLocation?> kernelOnChain(String excessHex, {int? minHeight}) => _guard(() async {
    final found = await _wallet.kernelOnChain(
      excess: excessHex,
      minHeight: minHeight == null ? null : BigInt.from(minHeight),
    );
    return found == null ? null : KernelLocation(height: found.height.toInt(), mmrIndex: found.mmrIndex.toInt());
  });

  /// LEPIC's default options, or the standard ones without the [heldOutputs].
  lepic.SendOptions? get _heldOnly =>
      heldOutputs.isEmpty ? null : lepicSendOptions(const SendOptions(), exclude: heldOutputs);

  /// Split and Consolidate spend every spendable coin: refused while another device holds some.
  void _noneHeld(String what) {
    if (heldOutputs.isEmpty) return;
    throw WalletError(kind: WalletErrorKind.walletBusy, message: '$what waits: coins are held by a linked device');
  }

  /// The caller's [options] when given. Else send-all when [amount] is still the wallet's
  /// maximum, checked again now: a max remembered from before the balance changed must not
  /// turn a typed amount into a send-all. Null (LEPIC's default) otherwise.
  Future<lepic.SendOptions?> _optionsFor(
    BigInt amount,
    BigInt minimumConfirmations, [
    SendOptions? options,
  ]) async {
    if (options != null) return lepicSendOptions(options, exclude: heldOutputs);
    final standard = heldOutputs.isEmpty ? null : lepicSendOptions(const SendOptions(), exclude: heldOutputs);
    if (_maxAmount == null || amount != _maxAmount) return standard;
    final now = await _wallet.estimateMax(
      minimumConfirmations: minimumConfirmations,
      options: _sendAll,
    );
    _maxAmount = now.amount;
    return now.amount == amount ? _sendAll : standard;
  }

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) => _nodeGuard('send file', () async {
    final slate = await _wallet.createSendSlate(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      message: _message(message),
      options: await _optionsFor(amount, minimumConfirmations, options),
    );
    return Slate(slateId: slate.slateId, json: slate.json);
  });

  @override
  Future<String> epicboxAddress() => _guard(_wallet.epicboxAddress);

  @override
  Future<String> fingerprint() => _guard(_wallet.fingerprint);

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  }) => _nodeGuard('fee estimate', () async {
    final e = await _wallet.estimateFee(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      options: await _optionsFor(amount, minimumConfirmations, options),
    );
    return lepicFeeEstimate(e);
  });

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _nodeGuard('max estimate', () async {
        final e = await _wallet.estimateMax(
          minimumConfirmations: minimumConfirmations,
          options: _sendAll,
        );
        _maxAmount = e.amount;
        return lepicFeeEstimate(e);
      });

  @override
  Future<List<WalletOutput>> outputs() => _guard(() async {
    final list = await _wallet.outputs();
    return [for (final o in list) lepicWalletOutput(o)];
  });

  /// Split into [outputs] outputs: all spendable outputs into that many.
  static lepic.SelfSendRequest _splitRequest(int outputs) => lepic.SelfSendRequest(
    inputs: lepic.SelfInputs.all,
    named: const [],
    outputs: lepic.SelfOutputs.count,
    count: outputs,
    amounts: Uint64List(0),
  );

  @override
  Future<FeeEstimate> estimateSplit({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _nodeGuard('split estimate', () async {
    _noneHeld('split');
    return lepicFeeEstimate(
      await _wallet.estimateSendToSelf(
        request: _splitRequest(outputs),
        minimumConfirmations: minimumConfirmations,
      ),
    );
  });

  @override
  Future<SelfSentTx> splitOutputs({
    required int outputs,
    required BigInt minimumConfirmations,
  }) => _nodeGuard('split', () async {
    _noneHeld('split');
    return lepicSelfSentTx(
      await _wallet.sendToSelf(
        request: _splitRequest(outputs),
        minimumConfirmations: minimumConfirmations,
      ),
    );
  });

  @override
  Future<FeeEstimate> estimateConsolidate({
    required BigInt minimumConfirmations,
  }) => _nodeGuard('consolidate estimate', () async {
    _noneHeld('consolidate');
    return lepicFeeEstimate(
      await _wallet.estimateSendToSelf(
        request: _splitRequest(1),
        minimumConfirmations: minimumConfirmations,
      ),
    );
  });

  @override
  Future<SelfSentTx> consolidateOutputs({
    required BigInt minimumConfirmations,
  }) => _nodeGuard('consolidate', () async {
    _noneHeld('consolidate');
    return lepicSelfSentTx(
      await _wallet.sendToSelf(
        request: _splitRequest(1),
        minimumConfirmations: minimumConfirmations,
      ),
    );
  });

  @override
  Future<void> setServers({required WalletConfig config}) => _guard(() async {
    await _wallet.setServers(
      config: await LepicWalletService._lepicConfig(
        config,
        '${config.dataDir}${Platform.pathSeparator}lepic',
      ),
    );
    nodeUrl = config.nodeUrl;
    nodeApiSecret = config.nodeApiSecret;
  });

  @override
  Future<NodeTip> nodeTipFor({required WalletConfig config}) =>
      _guard(() async {
        // Node only: the node in use alone, not the others of the list (their checks).
        NetGate.dial(NetDial.http, config.nodeUrl);
        final tip = await _wallet.nodeTipFor(
          config: await LepicWalletService._lepicConfig(config, config.dataDir),
        );
        return NodeTip(
          height: tip.height,
          nodeVersion: tip.nodeVersion,
          readyForTxs: tip.readyForTxs,
        );
      });

  @override
  Future<SelfSentTx> spendOutputsToSelf({
    required List<String> commitments,
    required BigInt minimumConfirmations,
    int outputs = 1,
  }) => _nodeGuard('spend to self', () async {
    if (commitments.any(heldOutputs.contains)) _noneHeld('spend to self');
    return lepicSelfSentTx(
      await _wallet.sendToSelf(
        request: lepic.SelfSendRequest(
          inputs: lepic.SelfInputs.named,
          named: commitments,
          outputs: lepic.SelfOutputs.count,
          count: outputs,
          amounts: Uint64List(0),
        ),
        minimumConfirmations: minimumConfirmations,
      ),
    );
  });

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) =>
      _nodeGuard('finalize', () async {
        final tx = await _posted(() => _wallet.finalizeAndPost(slateJson: slateJson));
        return _entry(tx.txId);
      });

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) => _epicboxGuard('send over Epicbox', () async {
    _sending++;
    final lepic.SentTx tx;
    try {
      tx = await _wallet.sendEpicbox(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
        address: lepicEpicboxAddress(address),
        message: _message(message),
        options: await _optionsFor(amount, minimumConfirmations, options),
      );
    } finally {
      _sending--;
    }
    return _entry(tx.txId);
  });

  /// Epicbox, HTTP and Tor sends and resends under way: LEPIC calls a send undelivered until
  /// its first attempt ends, so none of the rows shows "Not delivered" meanwhile.
  int _sending = 0;

  /// Runs [send] counted in [_sending].
  Future<T> _counted<T>(Future<T> Function() send) async {
    _sending++;
    try {
      return await send();
    } finally {
      _sending--;
    }
  }

  @override
  Future<void> resendEpicbox({required String key}) => _epicboxGuard('resend over Epicbox', () async {
    final txId = await _txIdOf(key);
    _sending++;
    try {
      await _wallet.resendEpicbox(txId: txId);
    } finally {
      _sending--;
    }
  });

  @override
  Stream<ListenerEvent> startListener() => _epicboxStream('listener', () =>
    _wallet.startListener().expand((e) {
      final bounced = lepicListenerBounce(e);
      if (bounced != null) _onBounce(bounced);
      final event = lepicListenerEvent(e);
      return event == null ? const <ListenerEvent>[] : [event];
    }),
  );

  @override
  Future<void> stopListener() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopListener);
  }

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
  }) => _nodeGuard('send over HTTP', () async {
    final to = await _directUrl(url, 'send over HTTP');
    final sendOptions = await _optionsFor(amount, minimumConfirmations, options);
    final tx = await _counted(
      () => _directWhenLocal(to, () => _wallet.sendHttp(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
        url: to,
        allowPlainHttp: allowPlainHttp,
        message: _message(message),
        options: sendOptions,
      )),
    );
    return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
  });

  @override
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  }) => _nodeGuard('resend over HTTP', () async {
    final to = await _directUrl(url, 'resend over HTTP');
    final tx = await _counted(
      () => _directWhenLocal(to, () => _wallet.resendHttp(
        txId: txId,
        url: to,
        allowPlainHttp: allowPlainHttp,
      )),
    );
    return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
  });

  @override
  Stream<HttpListenerEvent> startHttpListener({
    required HttpExposure exposure,
    required int port,
  }) => NetGate.torOnly && exposure == HttpExposure.internet
      // Tor only: no clearnet listener; one on 127.0.0.1 behind the onion stays.
      ? Stream.error(const NetBlocked(NetworkMode.torOnly, 'HTTP listener'))
      // Node only and Kill switch: no Link listener at all.
      : _netStream(
          'HTTP listener',
          () => _wallet
              .startHttpListener(exposure: _lepicExposure(exposure), port: port)
              .map(lepicHttpEvent),
        );

  @override
  Future<void> stopHttpListener() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopHttpListener);
  }

  @override
  Future<String> signDeviceLink(List<int> transcript) =>
      _guard(() async => _hexOf(await _wallet.deviceLinkSign(transcript: transcript)));

  @override
  Future<bool> verifyDeviceLink({required List<int> transcript, required String signature}) async {
    final bytes = _bytesOfHex(signature);
    if (bytes == null) return false;
    return _guard(() => _wallet.deviceLinkVerify(transcript: transcript, signature: bytes));
  }

  final StreamController<UnmatchedNotice> _unmatched = StreamController<UnmatchedNotice>.broadcast();

  @override
  Stream<UnmatchedNotice> unmatchedNotices() {
    _watchEvents();
    return _unmatched.stream;
  }

  @override
  Future<bool> applyForwardedNotice({required String sender, required String notice}) =>
      _guard(() => _wallet.noticeApplyForwarded(sender: sender, notice: notice));

  static String _hexOf(List<int> bytes) => [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

  /// [hex] as bytes, or null for anything but an even run of hex digits.
  static Uint8List? _bytesOfHex(String hex) {
    if (hex.isEmpty || hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;
    return Uint8List.fromList([for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)]);
  }

  @override
  Future<String> onionAddress() => _guard(_wallet.onionAddress);

  @override
  Stream<TorEvent> startTor({required String torBinary, String? libDir}) =>
      // Tor carries the node in Node only (the user's switch) and publishes no onion there, so
      // no Link listener runs behind it; Kill switch starts none.
      _nodeStream('tor', () =>
        _wallet
            .startTor(torBinary: torBinary, libDir: libDir, publishOnion: torPublishesOnion)
            .map(lepicTorEvent),
      );

  @override
  Future<void> stopTor() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.stopTor);
  }

  @override
  Future<void> setEpicboxOverTor(bool on) async {
    if (!_wallet.isDisposed) {
      _guardSync(() => _wallet.setEpicboxOverTor(enabled: on));
    }
  }

  @override
  Future<void> setNodeAndHttpOverTor(bool on) async {
    if (_wallet.isDisposed) return;
    _httpOverTor = on;
    _guardSync(() {
      _wallet.setNodeOverTor(enabled: on);
      if (_directSends == 0) _wallet.setHttpOverTor(enabled: on);
    });
  }

  /// HTTP sends over Tor as [setNodeAndHttpOverTor] last set it (on when the wallet opens).
  bool _httpOverTor = true;

  /// Plain http sends to the local network running now with HTTP over Tor turned off for them.
  int _directSends = 0;

  /// [call] for a send to [url]: plain http to this device or the local network goes direct
  /// while HTTP sends go over Tor (tor cannot reach the local network), then they go over Tor
  /// again. One send runs at a time from Send; another http send meanwhile would go direct too.
  Future<T> _directWhenLocal<T>(String url, Future<T> Function() call) async {
    // This device stays direct in LEPIC itself; only the local network needs HTTP over Tor off.
    if (!_httpOverTor || !plainHttpOffNow || NetGate.torOnly || urlHostScope(url) != HostScope.network || !plainHttpGoesDirect(url)) return call();
    _directSends++;
    _guardSync(() => _wallet.setHttpOverTor(enabled: false));
    try {
      return await call();
    } finally {
      _directSends--;
      if (_directSends == 0 && !_wallet.isDisposed) _guardSync(() => _wallet.setHttpOverTor(enabled: _httpOverTor));
    }
  }

  @override
  Future<void> expectTor() async {
    if (!_wallet.isDisposed) _guardSync(_wallet.expectTor);
  }

  @override
  Future<bool> epicboxOverTor() async =>
      !_wallet.isDisposed && _guardSync(_wallet.epicboxOverTor);

  @override
  Future<void> setOnionRoutes(List<TorOnionRoute> routes) async {
    if (_wallet.isDisposed) return;
    _guardSync(
      () => _wallet.setOnionRoutes(
        routes: [
          for (final r in routes)
            lepic.OnionRoute(
              host: r.host,
              port: r.port,
              onion: r.onion,
              onionPort: r.onionPort,
            ),
        ],
      ),
    );
  }

  @override
  Future<void> refreshTor({required bool networkChanged}) =>
      _nodeNetGuard('tor refresh', () => _wallet.refreshTor(networkChanged: networkChanged));

  @override
  Future<void> torNetworkLost() => _guard(() => _wallet.torNetworkLost());

  @override
  Future<TorStatus> torStatus() async {
    if (_wallet.isDisposed) return TorStatus.off;
    final s = _guardSync(_wallet.torStatus);
    return TorStatus(
      kind: switch (s.kind) {
        lepic.TorStatusKind.off => TorStatusKind.off,
        lepic.TorStatusKind.starting => TorStatusKind.starting,
        lepic.TorStatusKind.bootstrapped => TorStatusKind.bootstrapped,
        lepic.TorStatusKind.publishing => TorStatusKind.publishing,
        lepic.TorStatusKind.ready => TorStatusKind.ready,
      },
      progress: s.progress,
      onion: s.onion,
      failure: _torFailure(s.failure),
      socksPort: s.socksPort,
    );
  }

  @override
  Future<HttpSent> sendTor({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String onion,
    String? message,
    SendOptions? options,
  }) => sendTorRetryingOnce(
    transactions: () => transactions(refresh: false),
    resend: (txId) => resendTor(txId: txId, onion: onion),
    send: () => _netGuard('send over Tor', () async {
      final sendOptions = await _optionsFor(amount, minimumConfirmations, options);
      final tx = await _counted(
        () => _wallet.sendTor(
          amount: amount,
          minimumConfirmations: minimumConfirmations,
          onion: onion,
          message: _message(message),
          options: sendOptions,
        ),
      );
      return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
    }),
  );

  @override
  Future<HttpSent> resendTor({required int txId, required String onion}) =>
      _netGuard('resend over Tor', () async {
        final tx = await _counted(
          () => _wallet.resendTor(txId: txId, onion: onion),
        );
        return HttpSent(txId: tx.txId, slateId: tx.slateId, posted: tx.posted);
      });

  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) => _nodeGuard('receive file', 
    () async =>
        lepicReceivedSlate(await _wallet.receiveSlate(slateJson: slateJson)),
  );

  @override
  Stream<ScanProgress> scan({
    BigInt? startHeight,
    bool deleteUnconfirmed = false,
  }) => _nodeStream('scan', () =>
    _wallet
        .scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed)
        // cancelScan ends the stream with `cancelled`: a stop, not a failure.
        .handleError(
          (Object _) {},
          test: (e) =>
              e is lepic.WalletError &&
              e.kind == lepic.WalletErrorKind.cancelled,
        )
        .map(
          (p) => ScanProgress(
            percent: p.percent,
            message: p.message,
            finished: p.finished,
            result: switch (p.result) {
              final r? => ScanResult(
                resumed: r.resumed,
                found: r.found.toInt(),
                restored: r.restored.toInt(),
                revived: r.revived.toInt(),
                unlocked: r.unlocked.toInt(),
                deleted: r.deleted.toInt(),
              ),
              null => null,
            },
          ),
        ),
  );

  @override
  void cancelScan() {
    if (!_wallet.isDisposed) _guardSync(_wallet.cancelScan);
  }

  @override
  Future<bool> restoreScanRequired() => _guard(_wallet.restoreScanRequired);

  /// LEPIC counts balances with its own confirmations and reports them in the summary
  /// (`countedConfirmationsProvider`), so [minimumConfirmations] changes nothing.
  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _guard(() async {
    if (refresh) NetGate.checkNode('refresh');
    final s = _summary(await _wallet.summary(refresh: refresh));
    if (refresh && s.validatedWithNode) _recordActivity(s.lastConfirmedHeight);
    return s;
  });

  @override
  Future<int> minimumConfirmations() =>
      _guard(() async => (await _wallet.minimumConfirmations()).toInt());

  /// LEPIC stores the count per wallet, re-splits every balance and emits balance events. The
  /// core refuses only 0; the app keeps 1–30 ([minMinimumConfirmations]) and refuses the rest
  /// as [WalletErrorKind.invalidArgument] before the call.
  @override
  Future<void> setMinimumConfirmations(int count) => _guard(() {
    if (count < minMinimumConfirmations || count > maxMinimumConfirmations) {
      throw WalletError(kind: WalletErrorKind.invalidArgument, message: 'minimum confirmations $count is not 1 to 30');
    }
    return _wallet.setMinimumConfirmations(count: BigInt.from(count));
  });

  /// As the old core: with the node out of reach the refresh still ends with the local balances,
  /// marked as not checked with the node, so Home shows them instead of an error.
  @override
  Stream<RefreshProgress> refresh({
    required BigInt minimumConfirmations,
  }) async* {
    NetGate.checkNode('refresh');
    try {
      // `await for`, not `yield*`: only it raises the stream's error here.
      await for (final p in _guardStream(_wallet.refresh())) {
        final summary = p.summary == null ? null : _summary(p.summary!);
        if (summary != null && summary.validatedWithNode) _recordActivity(summary.lastConfirmedHeight);
        yield RefreshProgress(percent: p.percent, message: p.message, summary: summary);
      }
    } on WalletError catch (error) {
      if (error.kind != WalletErrorKind.nodeUnreachable) rethrow;
      // Locked while the node did not answer: the handle is gone and has nothing left to read.
      if (_wallet.isDisposed) return;
      final local = _summary(
        await _guard(() => _wallet.summary(refresh: false)),
      );
      yield RefreshProgress(
        percent: 100,
        message: 'Could not reach the node',
        summary: WalletSummary(
          lastConfirmedHeight: local.lastConfirmedHeight,
          minimumConfirmations: local.minimumConfirmations,
          total: local.total,
          spendable: local.spendable,
          awaitingConfirmation: local.awaitingConfirmation,
          awaitingFinalization: local.awaitingFinalization,
          immature: local.immature,
          locked: local.locked,
          validatedWithNode: false,
        ),
      );
    }
  }

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) =>
      _guard(() async {
        if (refresh) {
          NetGate.checkNode('refresh');
          await _wallet.summary(refresh: true);
        }
        final txs = _history.transactions(await _live());
        if (!refresh) return txs;
        // Listener payments waiting too long, or too many (listener_receives.dart).
        final expired = listenerReceivesToCancel(txs, DateTime.now());
        if (expired.isEmpty) return txs;
        var cancelled = 0;
        for (final id in expired) {
          try {
            await _wallet.cancelTransaction(txId: id);
            cancelled++;
          } on Object catch (e) {
            logWarn('history', 'listener payment not cancelled: ${e.runtimeType}');
          }
        }
        logInfo('history', 'listener payments cancelled: $cancelled');
        return cancelled == 0 ? txs : _history.transactions(await _live());
      });

  /// LEPIC stores heights and times as it confirms, so nothing is left to fill in.
  @override
  Future<int> enrichHistory() async => 0;

  @override
  Future<void> setTxNote({required String key, String? note}) =>
      _guard(() async => _history.setNote(await _live(), key, note));

  @override
  Future<void> setTxLabel({required String key, String? label}) =>
      _guard(() async => _history.setLabel(await _live(), key, label));

  @override
  Future<void> setTxDetails({
    required String key,
    String? counterparty,
    String? transport,
    String? note,
  }) => _guard(
    () async => _history.setDetails(
      await _live(),
      key,
      counterparty: counterparty,
      transport: transport,
      note: note,
    ),
  );

  @override
  Future<List<Contact>> contacts() async => _history.contacts();

  @override
  Future<Contact> saveContact({required Contact contact}) =>
      _history.saveContact(contact);

  @override
  Future<void> deleteContact({required String id}) =>
      _history.deleteContact(id);

  @override
  Future<List<String>> favouriteContacts() async => [..._history.favourites()];

  @override
  Future<void> setFavouriteContact({required String id, required bool favourite}) =>
      _history.setFavourite(id, favourite);

  @override
  Chain get chain => _history.chain;

  @override
  LinkMemory linkMemory() => _history.linkMemory();

  @override
  Future<void> recordLinkPayment(Payreq request, int paidAt, {String? txId}) =>
      _history.recordLinkPayment(request, paidAt, txId: txId);

  @override
  LinkPaymentRecords linkPaymentRecords({void Function()? onChange}) => _history.linkPaymentRecords(onChange: onChange);

  /// The history as a `.wfeh` file LEPIC seals under a key from the seed, so only a wallet
  /// with the same recovery phrase opens it.
  @override
  Future<Uint8List> exportHistory({String? walletName, Map<String, Object?>? settings}) => _guard(() async {
    final payload = _history.exportPayload(
      await _live(),
      walletFp: walletFingerprint(await _wallet.epicboxAddress()),
      appVersion: historyAppVersion,
      lastConfirmedHeight: (await _wallet.summary(refresh: false))
          .lastConfirmedHeight,
    );
    final pairings = await _pairing.exportBackup();
    final full = (pairings == null ? payload : payload.withPairings(pairings))
        .withExtras(walletName: walletName, settings: settings);
    return _wallet.sealAppData(payload: full.encode());
  });

  @override
  Future<String> exportHistoryCsv() => _guard(() async {
    final summary = await _wallet.summary(refresh: false);
    return _history.csv(
      await _live(),
      summary.lastConfirmedHeight,
      target: summary.minimumConfirmations.toInt(),
    );
  });

  @override
  Future<ImportReport> importHistory({
    required Uint8List data,
    Map<String, bool>? useBackup,
  }) => _guard(() async {
        final payload = HistoryPayload.decode(await _openHistoryFile(data));
        final report = await _history.importPayload(
          payload,
          await _live(),
          walletFp: walletFingerprint(await _wallet.epicboxAddress()),
          useBackup: useBackup,
          // The contact form's checks, as the contacts file import uses.
          checks: AddressChecks(
            epicbox: (a) => lepic.validateEpicboxAddress(
              address: lepicEpicboxAddress(a),
              chain: _lepicChain(_history.chain),
            ),
            onion: (a) => lepic.validateOnionAddress(address: a),
          ),
        );
        if (!report.applied) return report;
        // Restored pairings may still be in use on the device the backup came from.
        final pairings = await _pairing.importBackup(payload.pairings);
        return report.withPairings(pairings, otherDevice: pairings);
      });

  @override
  Future<LegacyHistoryImport> importLegacyHistory({
    required String sourceDir,
    Map<String, bool>? useOldWallet,
  }) => _guard(() async {
    final r = await _wallet.importLegacyHistory(sourceDir: sourceDir);
    final status = switch (r.status) {
        lepic.LegacyImportStatus.imported => LegacyHistoryStatus.imported,
        lepic.LegacyImportStatus.alreadyImported =>
          LegacyHistoryStatus.alreadyImported,
        lepic.LegacyImportStatus.noHistory => LegacyHistoryStatus.noHistory,
        lepic.LegacyImportStatus.oldFormat => LegacyHistoryStatus.oldFormat,
        lepic.LegacyImportStatus.unreadable => LegacyHistoryStatus.unreadable,
        lepic.LegacyImportStatus.sourceBusy => LegacyHistoryStatus.sourceBusy,
        lepic.LegacyImportStatus.tooLarge => LegacyHistoryStatus.tooLarge,
        lepic.LegacyImportStatus.otherWallet => LegacyHistoryStatus.otherWallet,
        lepic.LegacyImportStatus.otherHistory =>
          LegacyHistoryStatus.otherHistory,
    };
    // What the user typed for a payment a scan found, against what the old wallet recorded
    // for it: the same per-field choice as a history backup, Mine unless they say otherwise.
    final read =
        status == LegacyHistoryStatus.imported ||
        status == LegacyHistoryStatus.alreadyImported;
    final live = read ? await _live() : const <TxEntry>[];
    final List<ImportConflict> conflicts =
        read ? _history.legacyConflicts(live) : const [];
    var replaced = 0;
    if (conflicts.isNotEmpty) {
      if (useOldWallet == null) {
        return LegacyHistoryImport(
          status: status,
          transactions: r.transactions,
          conflicts: conflicts,
          applied: false,
        );
      }
      replaced = await _history.resolveLegacyConflicts(live, useOldWallet);
    }
    return LegacyHistoryImport(
      status: status,
      transactions: r.transactions,
      linked: r.linked,
      skipped: r.skipped,
      replaced: replaced,
    );
  });

  /// LEPIC's answer for a history file, in the old core's sentences the UI translates.
  Future<Uint8List> _openHistoryFile(Uint8List data) async {
    try {
      final payload = await _wallet.openAppData(file: data);
      // A wallet's own sealed archive or key opens with the same key, but is no history file.
      if (isSealedAppPayload(payload)) throw historyError(historyNotOurs);
      return payload;
    } on lepic.WalletError catch (e) {
      throw switch (e.kind) {
        lepic.WalletErrorKind.foreignAppData => historyError(
          historyOtherWallet,
        ),
        lepic.WalletErrorKind.damagedAppData => historyError(historyDamaged),
        lepic.WalletErrorKind.unsupported => historyError(historyNewer),
        lepic.WalletErrorKind.invalidArgument => historyError(historyNotOurs),
        _ => mapLepicError(e),
      };
    }
  }

  // Invoices from paired contacts (RFC 0002 11). LEPIC keeps the pairings, their mailboxes
  // and the waiting invoices; the app keeps what became of each invoice it paid or issued,
  // in `wfe_meta.json`. Nothing here pays but [payInvoice], which only the
  // review screen calls after the PIN or biometric gate; no event leads to it.

  /// The confirmations LEPIC's balance counts a coin spendable with, so an invoice is paid
  /// from what the balance shows as spendable.
  Future<BigInt> _balanceConfirmations() async =>
      (await _wallet.summary(refresh: false)).minimumConfirmations;

  BigInt get _expirySecs => BigInt.from(invoiceExpiry.inSeconds);

  StreamSubscription<lepic.WalletEvent>? _walletEvents;
  final StreamController<InvoiceEvent> _invoiceEvents =
      StreamController<InvoiceEvent>.broadcast();
  final StreamController<IssuerEvent> _issuerEvents =
      StreamController<IssuerEvent>.broadcast();

  /// Slates LEPIC reported as unknown in this session, so a redelivered one is told once.
  final Set<String> _unknownSlates = {};

  /// Invoices this wallet was asked to pay and has not answered: LEPIC deletes a waiting one
  /// it withdraws, so only this tells a real withdraw from an event about something else.
  final Set<String> _waitingSlates = {};

  /// Events are handled one at a time, so the archive changes in the order LEPIC reported.
  /// A withdrawal and a reconcile of issued invoices take their turn here too.
  Future<void> _eventTail = Future.value();

  /// Runs [step] after every event and step before it.
  Future<T> _inTurn<T>(Future<T> Function() step) {
    final result = _eventTail.then((_) => step());
    _eventTail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Subscribes to LEPIC's events on the first invoice call, so a notice found by a collect
  /// updates the archive before the app's event goes out.
  void _watchEvents() {
    if (_walletEvents != null || _wallet.isDisposed) return;
    _walletEvents = _wallet.events().listen(
      (e) => unawaited(
        _inTurn(() => _onWalletEvent(e))
        // One failed event must not stop the ones after it.
        .catchError(
          (Object error) =>
              logWarn('invoices', 'invoice event failed: ${error.runtimeType}'),
        ),
      ),
      onError: (Object error) =>
          logWarn('invoices', 'wallet events ended: $error'),
    );
  }

  Future<void> _onWalletEvent(lepic.WalletEvent e) async {
    // The node did not take a finalized send: its row reads "Not on the network" at once, with
    // the repost and cancel the screens already offer, instead of "Posting…" until [postingFor].
    if (e.kind == lepic.WalletEventKind.notPosted) {
      final tx = e.txId;
      if (tx != null) _finalizedSeen[tx] = _settled;
      logWarn('wallet', 'send not posted: ${e.message ?? ''}');
      return;
    }
    // For the linked device only: nothing here holds its slate, and nothing verified it.
    if (e.kind == lepic.WalletEventKind.noticeUnmatched) {
      final (slate, kind, sender, notice) = (e.slateId, e.noticeKind, e.sender, e.notice);
      if (slate != null && kind != null && sender != null && notice != null && !_unmatched.isClosed) {
        _unmatched.add(UnmatchedNotice(slateId: slate, kind: kind, sender: sender, notice: notice));
      }
      return;
    }
    // LEPIC may have linked a row to its pairing meanwhile.
    _askNoContactAgain();
    try {
      await _pairing.onWalletEvent(e);
    } on Object catch (error) {
      // Only the pairing's notice is lost; an invoice in the same event still counts.
      logWarn('pairing', 'pairing event failed: ${error.runtimeType}');
    }
    final slate = e.slateId;
    // A contact's invoice waits to be paid; its answer's delivery moves the paid invoice.
    if (slate != null) {
      switch (e.kind) {
        case lepic.WalletEventKind.invoiceFromContact:
          _waitingSlates.add(slate);
          if (!_invoiceEvents.isClosed) _invoiceEvents.add(InvoiceEvent(kind: InvoiceEventKind.received, slateId: slate));
          return;
        case lepic.WalletEventKind.outboxDelivered || lepic.WalletEventKind.outboxStuck:
          if (_history.paidInvoiceRecord(slate) != null) {
            await _history.setPaidInvoiceStatus(
              slate,
              e.kind == lepic.WalletEventKind.outboxDelivered ? InvoiceStatus.replied : InvoiceStatus.replyFailed,
            );
          }
          return;
        default:
      }
    }
    final issued = lepicIssuerEvent(e);
    if (issued != null) return _onIssuerEvent(issued.slateId, issued.state);
    final event = lepicInvoiceEvent(e);
    if (event == null) return;
    try {
      switch (event.kind) {
        case InvoiceEventKind.posted:
          await _history.setPaidInvoiceStatus(
            event.slateId,
            InvoiceStatus.posted,
            kernelExcess: event.kernelExcess,
          );
        case InvoiceEventKind.withdrawn:
          // Only an invoice this wallet was asked to pay counts: a waiting one, or one it paid.
          final waiting = _waitingSlates.remove(event.slateId);
          if (await _paidInvoice(event.slateId) == null) {
            if (!waiting) return;
          } else {
            // Only a paid one has a record; a waiting one LEPIC deleted itself.
            await _history.setPaidInvoiceStatus(
              event.slateId,
              InvoiceStatus.withdrawn,
            );
          }
        case InvoiceEventKind.received:
          _waitingSlates.add(event.slateId);
        case InvoiceEventKind.declined || InvoiceEventKind.expired:
          _waitingSlates.remove(event.slateId);
        case InvoiceEventKind.unknownInvoicePayment ||
            InvoiceEventKind.unknownSendAnswer ||
            InvoiceEventKind.receiveSuperseded:
          // A relay that did not settle the message delivers it again: one notice per slate.
          if (!_unknownSlates.add(event.slateId)) return;
        case InvoiceEventKind.paymentPosted || InvoiceEventKind.paymentCancelled:
          // LEPIC raises it once per payment and records the report itself.
          break;
      }
    } on WalletError catch (error) {
      logWarn(
        'invoices',
        'could not record an invoice notice: ${error.kind.name}',
      );
    }
    if (!_invoiceEvents.isClosed) _invoiceEvents.add(event);
  }

  @override
  bool get supportsInvoices => true;

  /// LEPIC issues, pays and finishes requests as files for anyone (`issue_invoice_slate`,
  /// `pay_invoice_slate`; `finalize_and_post` takes the answer).
  @override
  bool get supportsRequestFiles => true;

  /// Pays the request (I1) in [slateJson] with LEPIC's `pay_invoice_slate`, which checks the
  /// amount against the one signed into it, and returns the answer (I2).
  @override
  Future<PaidRequestFile> payRequestFile({required String slateJson, required BigInt amount}) =>
      _nodeGuard('pay request file', () async {
        final paid = await _wallet.payInvoiceSlate(
          slateJson: slateJson,
          amount: amount,
          minimumConfirmations: await _balanceConfirmations(),
          options: _heldOnly,
        );
        logInfo('invoices', 'request file paid');
        return PaidRequestFile(txId: paid.txId, slateId: paid.slateId, amount: paid.amount, fee: paid.fee, json: paid.json);
      });

  /// A request as a file for anyone (I1), kept as an issued invoice waiting for its payer.
  Future<Slate> _issueFile({required BigInt amount, String? message}) => _nodeGuard('request file', () async {
    _watchEvents();
    if (amount <= BigInt.zero) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'the amount must be above zero');
    }
    final slate = await _wallet.issueInvoiceSlate(amount: amount, message: cutMessage(message));
    try {
      await _history.putIssuedInvoice(slate.slateId);
    } on WalletError catch (error) {
      // The file is made; only the app's view of it is lost. The sweep ends it.
      logWarn('invoices', 'could not record an issued invoice: ${error.kind.name}');
    }
    logInfo('invoices', 'request saved as a file');
    return Slate(slateId: slate.slateId, json: slate.json);
  });

  late final _LepicPairing _pairing = _LepicPairing(this);

  @override
  PairingApi get pairing => _pairing;

  /// Invoices come only from paired contacts (RFC 0002 11): an open collect of their
  /// mailboxes, then the sweep.
  @override
  Future<InvoiceCollectReport> collectInvoices() => _epicboxGuard('invoice collect', () async {
    // Invoices off (Settings › Advanced › Experimental): no mailbox is opened, nothing expires.
    if (!NetGate.invoices) return const InvoiceCollectReport();
    _watchEvents();
    final before = (await _wallet.contactInvoices()).length;
    await _pairing.collectOrFail(PairingCollectTrigger.open);
    await _sweep();
    final after = (await _wallet.contactInvoices()).length;
    return InvoiceCollectReport(parked: after > before ? after - before : 0);
  });

  /// Expires invoices on both sides: waiting ones to pay are deleted, issued ones cancelled,
  /// each with its event. A failure is logged only; the next collect sweeps again.
  Future<void> _sweep() async {
    try {
      final sweep = await _wallet.sweepInvoices(expirySecs: _expirySecs);
      if (sweep.cancellable.isNotEmpty) {
        logInfo(
          'invoices',
          '${sweep.cancellable.length} invoice payments past their time to live',
        );
      }
    } on lepic.WalletError catch (error) {
      logWarn('invoices', 'invoice sweep failed: ${error.kind.name}');
    }
  }

  @override
  Future<List<PendingInvoice>> pendingInvoices() => _guard(() async {
    _watchEvents();
    final pending = [
      for (final i in await _wallet.contactInvoices()) lepicContactInvoice(i),
    ];
    _waitingSlates.addAll(pending.map((i) => i.slateId));
    return pending;
  });

  @override
  Future<PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
  }) => _epicboxGuard('pay invoice', () async {
    _watchEvents();
    final pending = (await _wallet.contactInvoices()).where((i) => i.slateId == slateId).firstOrNull;
    if (pending == null) {
      throw const WalletError(
        kind: WalletErrorKind.invoiceNotFound,
        message: 'no pending invoice with that id',
      );
    }
    // Sealed to the contact and queued for its mailbox; its delivery moves the status.
    final paid = await _wallet.contactPayInvoice(
      slateId: slateId,
      amount: amount,
      minimumConfirmations: await _balanceConfirmations(),
      options: _heldOnly,
      relayMode: lepicRelayMode(),
    );
    _deliverOutbox();
    final result = PaidInvoice(
      slateId: slateId,
      senderAddress: '',
      amount: pending.amount,
      status: InvoiceStatus.replied,
      txId: paid.txId,
      pairingId: pending.contactId,
    );
    _waitingSlates.remove(slateId);
    try {
      await _history.putPaidInvoice(slateId, result.status);
    } on WalletError catch (error) {
      // The payment stands either way; only its details screen loses the invoice.
      logWarn('invoices', 'could not record a paid invoice: ${error.kind.name}');
    }
    return result;
  });

  /// Posts what waits in the contacts' outbox now, not on the next collect: a request, a
  /// payment or a decline reaches the contact at once. A failure is logged only; the next
  /// collect posts it again.
  void _deliverOutbox() {
    if (NetGate.epicboxOff) return;
    unawaited(
      Future.sync(() => _wallet.contactsOutboxDeliver(relayMode: lepicRelayMode())).then<void>(
        (_) {},
        onError: (Object error) => logWarn(
          'pairing',
          'outbox not delivered: ${error is lepic.WalletError ? error.kind.name : error.runtimeType}',
        ),
      ),
    );
  }

  @override
  Future<PaidInvoice> resendInvoiceReply({required String slateId}) =>
      _epicboxGuard('invoice reply', () async {
        final paid = await _paidInvoice(slateId);
        if (paid == null) {
          throw const WalletError(
            kind: WalletErrorKind.invalidArgument,
            message: 'no paid invoice with that id',
          );
        }
        // "Send again": the outbox posts the same answer once more (RFC 8.6).
        for (final c in await _wallet.contacts()) {
          final entry = (await _wallet.contactOutbox(contactId: c.contactId)).where((o) => o.slateId == slateId).firstOrNull;
          if (entry == null) continue;
          await _wallet.contactOutboxResend(id: entry.id, relayMode: lepicRelayMode());
          await _history.setPaidInvoiceStatus(slateId, InvoiceStatus.replied);
          return paid.withStatus(InvoiceStatus.replied);
        }
        throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'nothing to send again for this invoice');
      });

  @override
  Future<void> declineInvoice({required String slateId}) => _guard(() async {
    _watchEvents();
    await _wallet.contactDeclineInvoice(slateId: slateId);
    _deliverOutbox();
    _waitingSlates.remove(slateId);
    if (!_invoiceEvents.isClosed) {
      _invoiceEvents.add(
        InvoiceEvent(kind: InvoiceEventKind.declined, slateId: slateId),
      );
    }
  });

  @override
  Future<PaidInvoice?> paidInvoice({required String slateId}) =>
      _guard(() => _paidInvoice(slateId));

  /// The invoice paid under [slateId], from LEPIC's payment (`flow` invoice, outgoing) and
  /// what the archive recorded of its reply and receipt; null when LEPIC has no such payment.
  Future<PaidInvoice?> _paidInvoice(String slateId) async {
    final record = _history.paidInvoiceRecord(slateId);
    final rows = await _wallet.transactions();
    for (final d in rows) {
      if (d.slateId != slateId) continue;
      final paid = paidInvoiceOf(
        lepicTxEntry(d, sending: _sending > 0, posting: _posting(d)),
        status: record?.status,
        kernelExcess: record?.kernelExcess,
      );
      if (paid == null) continue;
      // Contact invoices only (RFC 11): the contact it was sealed to names it.
      final contact = await _contactOfTx(d.txId);
      return PaidInvoice(
        slateId: paid.slateId,
        senderAddress: paid.senderAddress,
        pairingId: contact,
        amount: paid.amount,
        message: paid.message,
        status: paid.status,
        txId: paid.txId,
        kernelExcess: paid.kernelExcess,
      );
    }
    // One a history backup brought back: shown as recorded, never resent.
    final live = [for (final d in rows) lepicTxEntry(d, sending: _sending > 0, posting: _posting(d))];
    for (final t in _history.transactions(live)) {
      if (t.source == TxSource.wallet || t.slateId != slateId) continue;
      final paid = paidInvoiceOf(t, status: record?.status, kernelExcess: record?.kernelExcess);
      if (paid == null) continue;
      return PaidInvoice(
        slateId: paid.slateId,
        senderAddress: paid.senderAddress,
        pairingId: t.pairingId,
        amount: paid.amount,
        message: paid.message,
        status: paid.status,
        kernelExcess: paid.kernelExcess,
      );
    }
    return null;
  }

  @override
  Stream<InvoiceEvent> invoiceEvents() {
    _watchEvents();
    return _invoiceEvents.stream;
  }

  // Issuing invoices (I-05, I-07). LEPIC keeps an issued invoice as an incoming transaction
  // with `flow` invoice, so the requests come from its store; `wfe_meta.json`
  // (`issued_invoices`) keeps only the state the app learned, which LEPIC reports as
  // cancelled, and moves it once, from waiting, on LEPIC's events. Nothing here pays.

  /// The requests in LEPIC's store, newest first, with the states the archive recorded.
  Future<List<IssuedInvoice>> _requests() async {
    final live = [
      for (final d in await _wallet.transactions())
        lepicTxEntry(d, sending: _sending > 0, posting: _posting(d)),
    ];
    // With the ended requests a history backup brought back, which LEPIC no longer holds as
    // requests (a paid one's output may be a row a scan found).
    final requests = requestsOf([
      ...live,
      for (final t in _history.transactions(live))
        if (t.source != TxSource.wallet && t.isRequest) t,
    ], _history.issuedInvoiceState);
    return [
      for (final r in requests)
        if (r.txId case final id?) r.withPairing(await _contactOfTx(id)) else r,
    ];
  }

  /// The paired contact a transaction was sealed to or from; once known it never changes, so
  /// it is asked once.
  final Map<int, String?> _txContacts = {};

  Future<String?> _contactOfTx(int txId) async {
    if (_txContacts.containsKey(txId)) return _txContacts[txId];
    try {
      return _txContacts[txId] = await _wallet.contactOfTransaction(txId: txId);
    } on lepic.WalletError catch (_) {
      // Shown without its contact; asked again next time.
      return null;
    }
  }

  Future<IssuedInvoice?> _request(String slateId) async =>
      (await _requests()).where((i) => i.slateId == slateId).firstOrNull;

  /// Moves [slateId] to [state] and tells the app, once.
  Future<void> _settleIssued(
    String slateId,
    IssuedInvoiceState state, {
    String? payerAddress,
    String? pairingId,
  }) async {
    final kind = issuerEventFor(state);
    if (kind == null) return;
    bool moved;
    try {
      moved = await _history.settleIssuedInvoice(slateId, state);
    } on WalletError catch (error) {
      logWarn(
        'invoices',
        'could not record an issued invoice: ${error.kind.name}',
      );
      return;
    }
    if (moved && !_issuerEvents.isClosed) {
      _issuerEvents.add(
        IssuerEvent(kind: kind, slateId: slateId, payerAddress: payerAddress, pairingId: pairingId),
      );
    }
  }

  /// An issuer event from LEPIC, for a request still waiting. A decline is final and a
  /// bounce means the payer cannot pay it, so the app withdraws the request itself, which
  /// frees the output LEPIC set aside for it. A repeated event finds it no longer waiting and
  /// changes nothing, so a bounce LEPIC delivers twice withdraws and tells once. A request
  /// without a record (its write failed) is moved and told too: a live event is news, unlike
  /// the catch-up in [_reconcileIssued], which stays silent for such a request.
  Future<void> _onIssuerEvent(String slateId, IssuedInvoiceState state) async {
    final recorded = _history.issuedInvoiceState(slateId);
    if (recorded != null && recorded != IssuedInvoiceState.waiting) return;
    final issued = await _request(slateId);
    if (issued == null) return;
    // LEPIC moved its transaction already for a payment or an expiry. A decline or a bounce
    // counts only for a request it still holds; anything else is settled by what LEPIC says.
    if (state == IssuedInvoiceState.declined ||
        state == IssuedInvoiceState.bounced) {
      if (!issued.withdrawable) return;
      try {
        await _wallet.cancelTransaction(txId: issued.txId!);
      } on lepic.WalletError catch (error) {
        // The sweep cancels it when its time runs out.
        logWarn(
          'invoices',
          '${state.name} invoice not withdrawn: ${error.kind.name}',
        );
      }
    }
    await _settleIssued(slateId, state, payerAddress: issued.payerAddress, pairingId: issued.pairingId);
  }

  /// A bounce the listener reported. LEPIC raises it on [lepic.EpicWallet.events] too; the
  /// second one changes nothing.
  void _onBounce(String slateId) {
    _watchEvents();
    unawaited(
      _inTurn(() => _onIssuerEvent(slateId, IssuedInvoiceState.bounced))
          .catchError(
            (Object error) =>
                logWarn('invoices', 'bounce not handled: ${error.runtimeType}'),
          ),
    );
  }

  /// Asks the paired contact [contactId] for [amount] (RFC 11.2): sealed, queued for its
  /// mailbox, posted once now when the mode allows. The payment comes back by collecting.
  Future<IssuedInvoice> _issueToContact({
    required String contactId,
    required BigInt amount,
    String? message,
  }) => _guard(() async {
    _watchEvents();
    if (amount <= BigInt.zero) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the amount must be above zero',
      );
    }
    final text = cutMessage(message);
    final now = DateTime.now();
    final expires = now.add(invoiceExpiry);
    final lepic.IssuedInvoice sent;
    try {
      sent = await _wallet.contactIssueInvoice(
        contactId: contactId,
        amount: amount,
        message: text,
        purpose: lepic.SlatePurpose.request,
        expires: BigInt.from(expires.millisecondsSinceEpoch ~/ 1000),
        relayMode: lepicRelayMode(),
      );
    } on lepic.WalletError catch (error) {
      final failure = lepicPairingFailure(error.kind, error.message);
      if (failure != null) throw pairingError(failure);
      rethrow;
    }
    _txContacts[sent.txId] = contactId;
    _deliverOutbox();
    final issued = IssuedInvoice(
      slateId: sent.slateId,
      txId: sent.txId,
      payerAddress: '',
      pairingId: contactId,
      amount: sent.amount,
      message: text,
      issuedAt: now,
      expiresAt: expires,
      state: IssuedInvoiceState.waiting,
    );
    try {
      await _history.putIssuedInvoice(issued.slateId);
    } on WalletError catch (error) {
      // The request went out; only the app's view of it is lost. The sweep ends it.
      logWarn(
        'invoices',
        'could not record an issued invoice: ${error.kind.name}',
      );
    }
    logInfo('invoices', 'request sent to a paired contact');
    return issued;
  });

  @override
  Future<List<IssuedInvoice>> issuedInvoices() => _guard(() async {
    _watchEvents();
    return _inTurn(_reconcileIssued);
  });

  /// Settles waiting records from LEPIC's transactions, for events the app missed: the
  /// listener or a drain finalized one while nothing listened, or a sweep cancelled one.
  /// A request without a record (its write failed, or `wfe_meta.json` was lost) shows what
  /// LEPIC says and raises no notice. Returns the requests as settled.
  Future<List<IssuedInvoice>> _reconcileIssued() async {
    final requests = await _requests();
    return [
      for (final i in requests)
        // Only a request LEPIC holds settles here: one a history backup brought back is not
        // news, so it raises no notice.
        if (i.txId != null &&
            i.state != IssuedInvoiceState.waiting &&
            _history.issuedInvoiceState(i.slateId) ==
                IssuedInvoiceState.waiting)
          await _settledAs(i)
        else
          i,
    ];
  }

  Future<IssuedInvoice> _settledAs(IssuedInvoice i) async {
    await _settleIssued(i.slateId, i.state, payerAddress: i.payerAddress, pairingId: i.pairingId);
    return i;
  }

  /// Reconciled as [issuedInvoices] is, so a details screen does not show a request as
  /// waiting after an event the app missed.
  @override
  Future<IssuedInvoice?> issuedInvoice({required String slateId}) =>
      _guard(() async {
        _watchEvents();
        final requests = await _inTurn(_reconcileIssued);
        return requests.where((i) => i.slateId == slateId).firstOrNull;
      });

  @override
  Future<IssuedInvoice> withdrawInvoice({required String slateId}) =>
      _epicboxGuard('withdraw invoice', () async {
        _watchEvents();
        return _inTurn(() async {
          final issued = await _request(slateId);
          if (issued == null || !issued.withdrawable) {
            throw const WalletError(
              kind: WalletErrorKind.invalidArgument,
              message: 'only a waiting invoice can be withdrawn',
            );
          }
          // LEPIC sends a LEPIC payer the `withdrawn` notice.
          await _wallet.cancelTransaction(txId: issued.txId!);
          await _settleIssued(
            slateId,
            IssuedInvoiceState.withdrawn,
            payerAddress: issued.payerAddress,
            pairingId: issued.pairingId,
          );
          return issued.withState(IssuedInvoiceState.withdrawn);
        });
      });

  @override
  Future<PaymentsDrainReport> drainPayments() => _epicboxGuard('payments drain', () async {
    _watchEvents();
    // Each bounce raises `invoiceBounced` on the events, which withdraws that request.
    final report = await _wallet.drainEpicbox();
    await _sweep();
    return PaymentsDrainReport(
      received: report.received,
      finalized: report.finalized,
      bounced: report.bounced,
    );
  });

  @override
  Stream<IssuerEvent> issuerEvents() {
    _watchEvents();
    return _issuerEvents.stream;
  }

  /// Not yet: the pinned LEPIC drains only the configured relay ([lepic.EpicWallet.drainEpicbox]).
  /// LEPIC E-15 (`drain_epicbox_at(domain, port)`) adds it; until then the old relay is not
  /// read and the drainer skips quietly.
  @override
  Future<PaymentsDrainReport?> drainEpicboxAt({required String domain, required int port}) async => null;

  @override
  Future<String> listingAddress(String serviceKeyHex, int generation) =>
      _guard(() => _wallet.epicboxAddressAt(serviceKey: serviceKeyHex, generation: generation));

  @override
  Future<Uint8List> signWithListing(String serviceKeyHex, int generation, String domain, Uint8List message) =>
      _guard(() async => fromHex(await _wallet.signWithAddressKeyAt(serviceKey: serviceKeyHex, generation: generation, domain: domain, message: message)));

  @override
  Future<PaymentsDrainReport> drainListing(String serviceKeyHex, int generation) => _epicboxGuard('listing drain', () async {
    _watchEvents();
    final report = await _wallet.drainEpicboxAt(serviceKey: serviceKeyHex, generation: generation);
    await _sweep();
    return PaymentsDrainReport(received: report.received, finalized: report.finalized, bounced: report.bounced);
  });
}

// ---------------------------------------------------------------------------------------
// Pairing (RFC 0002, U-24) over LEPIC's contact calls. The engine keeps the pairings, their
// keys, mailboxes, outbox and contact invoices; this adapter maps them to the app's
// [PairingApi] and carries what the app needs between calls (an invite's link and words for
// Pending invites, the answer to send by hand, what the user chose before the words check).
// Relay calls take the mode from the network mode and the Epicbox switch ([NetGate]).

/// The relay mode of a contact call: off by the mode (Node only, Kill switch), Epicbox off, or
/// online.
lepic.ContactRelayMode lepicRelayMode() => NetGate.restricted
    ? lepic.ContactRelayMode.offline
    : !NetGate.epicbox
    ? lepic.ContactRelayMode.epicboxOff
    : lepic.ContactRelayMode.online;

PairingState lepicPairingState(lepic.PairingState s) => switch (s) {
  lepic.PairingState.pendingInvite => PairingState.pendingInvite,
  lepic.PairingState.pendingReply => PairingState.pendingReply,
  lepic.PairingState.paired => PairingState.paired,
  lepic.PairingState.verified => PairingState.verified,
  lepic.PairingState.keysChanged => PairingState.keysChanged,
};

/// The app's state of a stored pairing, from LEPIC's derived status (ended, then keys changed,
/// then waiting until the other wallet was heard, then paired or verified).
PairingState lepicPairingStatus(lepic.PairingStatus s) => switch (s) {
  lepic.PairingStatus.waiting => PairingState.waiting,
  lepic.PairingStatus.paired => PairingState.paired,
  lepic.PairingStatus.verified => PairingState.verified,
  lepic.PairingStatus.keysChanged => PairingState.keysChanged,
  lepic.PairingStatus.ended => PairingState.ended,
};

PairingEndReason lepicPairingEndReason(lepic.PairingEndReason r) => switch (r) {
  lepic.PairingEndReason.mismatch => PairingEndReason.mismatch,
  lepic.PairingEndReason.peerMismatch => PairingEndReason.peerMismatch,
  lepic.PairingEndReason.unpaired => PairingEndReason.unpaired,
  lepic.PairingEndReason.neverFinished => PairingEndReason.neverFinished,
};

PairingParty lepicPairingParty(lepic.ContactKind? k) => switch (k) {
  lepic.ContactKind.shop => PairingParty.shop,
  lepic.ContactKind.exchange => PairingParty.exchange,
  lepic.ContactKind.person || null => PairingParty.person,
};

SlatePurpose lepicSlatePurpose(lepic.SlatePurpose p) => switch (p) {
  lepic.SlatePurpose.payment => SlatePurpose.payment,
  lepic.SlatePurpose.depositRequest => SlatePurpose.deposit,
  lepic.SlatePurpose.withdrawal => SlatePurpose.withdrawal,
  lepic.SlatePurpose.refund => SlatePurpose.refund,
  lepic.SlatePurpose.request => SlatePurpose.request,
};

SlateStage lepicSlateStage(lepic.SlateStage s) => switch (s) {
  lepic.SlateStage.s1 => SlateStage.send,
  lepic.SlateStage.s2 || lepic.SlateStage.s3 => SlateStage.response,
  lepic.SlateStage.i1 => SlateStage.request,
  lepic.SlateStage.i2 || lepic.SlateStage.i3 => SlateStage.requestAnswer,
};

/// The app's pairing failure for LEPIC's contact errors, or null for any other kind. [attach]:
/// the call was `contact_attach`, whose `OtherAddress` means the contact's address is not the
/// pairing's, not that an answer came from another wallet.
PairingFailure? lepicPairingFailure(lepic.WalletErrorKind k, [String message = '', bool attach = false]) => switch (k) {
  // LEPIC words why a text was refused; the kind alone says only "not readable".
  lepic.WalletErrorKind.invalidPairingText when message.contains('other network') => PairingFailure.wrongNetwork,
  lepic.WalletErrorKind.invalidPairingText when message.contains('newer wallet') => PairingFailure.newerVersion,
  lepic.WalletErrorKind.invalidPairingText || lepic.WalletErrorKind.invalidPairingWords => PairingFailure.invalid,
  lepic.WalletErrorKind.inviteExpired => PairingFailure.expired,
  lepic.WalletErrorKind.alreadyPaired => PairingFailure.alreadyUsed,
  lepic.WalletErrorKind.pairingWordsNotFound || lepic.WalletErrorKind.pairingNotFound => PairingFailure.notFound,
  // No built-in relay for the network: words have nowhere to go.
  lepic.WalletErrorKind.pairingWordsUnavailable => PairingFailure.noRelay,
  lepic.WalletErrorKind.contactsOffline ||
  lepic.WalletErrorKind.epicboxOff => PairingFailure.relayUnreachable,
  lepic.WalletErrorKind.sealedForAnotherWallet => PairingFailure.sealedForOther,
  lepic.WalletErrorKind.sealedUnopenable => PairingFailure.changedOnTheWay,
  // Pairing v3 (LEPIC schema v13).
  lepic.WalletErrorKind.otherAddress => attach ? PairingFailure.otherAddress : PairingFailure.otherWallet,
  lepic.WalletErrorKind.addressProofMissing => PairingFailure.addressProofMissing,
  lepic.WalletErrorKind.peerNotProven => PairingFailure.peerNotProven,
  lepic.WalletErrorKind.pairingInProgress => PairingFailure.inProgress,
  lepic.WalletErrorKind.pairingCrossed => PairingFailure.crossed,
  lepic.WalletErrorKind.pairingKindDiffers => PairingFailure.kindDiffers,
  lepic.WalletErrorKind.inviteDismissed => PairingFailure.inviteDismissed,
  lepic.WalletErrorKind.pairingEnded => PairingFailure.ended,
  lepic.WalletErrorKind.pairingWaiting => PairingFailure.waiting,
  _ => null,
};

class _LepicPairing implements PairingApi {
  _LepicPairing(this._s);

  final LepicWalletSession _s;

  lepic.EpicWallet get _w => _s._wallet;

  final StreamController<PairingEvent> _events = StreamController<PairingEvent>.broadcast();

  // No meeting relays any more: the standing code and requests use the wallet's own relay
  // (pairing words are gone), so the Connection servers are not passed to LEPIC.
  @override
  void setConnectionServers(List<String>? hosts) {}

  /// Whether [relay] (`host[:port]`) is in the Epicbox server list, compared by host and port.
  bool _inServerList(String relay) {
    final r = EpicboxRelay.parse(relay);
    return r != null && hostSettings.epicboxServers.any((s) => s.host.toLowerCase() == r.host && s.port == r.port);
  }

  /// Applies the move [relay] that contact [id] asked for. False when the core would not (none
  /// is pending any more, the pairing ended): nothing moved.
  Future<bool> _applyMove(String id, String relay) async {
    try {
      await _w.contactApplyRelayMove(contactId: id, relay: relay);
      return true;
    } on lepic.WalletError {
      return false;
    }
  }

  /// Applies each pending move to a relay in the server list; true when one was made.
  Future<bool> _followMoves(List<lepic.ContactView> contacts) async {
    var moved = false;
    for (final c in contacts) {
      final relay = c.requestedRelay;
      if (relay != null && _inServerList(relay) && await _applyMove(c.contactId, relay)) moved = true;
    }
    return moved;
  }

  @override
  Future<void> followRelayMoves() => _call(() async {
    if (await _followMoves(await _w.contacts()) && !_events.isClosed) _events.add(const PairingEvent(PairingEventKind.contactUpdated));
  });

  /// Contacts a check got no answer from, with when it was sent (Unix ms): "Not answering" until
  /// the contact is heard after that, or checked again. Not kept across a restart.
  final Map<String, int> _notAnswering = {};

  /// The moves already told as refused (`id relay`), so a check and the event say it once.
  final Set<String> _refusedMoves = {};

  bool _isNotAnswering(lepic.ContactView c) {
    final sent = _notAnswering[c.contactId];
    return sent != null && c.endedReason == null && (c.lastSealedInMs ?? c.createdAtMs).toInt() <= sent;
  }

  /// A paired shop or exchange whose pairing has not ended: the contacts a check asks. People are
  /// offline often and are not checked.
  bool _checkable(lepic.ContactView c, {bool anyKind = false}) =>
      (anyKind || c.kind == lepic.ContactKind.shop || c.kind == lepic.ContactKind.exchange) &&
      (c.state == lepic.PairingState.paired || c.state == lepic.PairingState.verified) &&
      c.endedReason == null &&
      !c.removedByPeer;

  void _contactsChanged() {
    if (!_events.isClosed) _events.add(const PairingEvent(PairingEventKind.contactUpdated));
  }

  @override
  Future<Map<String, ContactCheckOutcome>> checkContacts({Duration? wait, Duration every = contactCheckEvery, Set<String>? only}) async {
    final outcomes = <String, ContactCheckOutcome>{};
    if (!supported || !NetGate.pairing || NetGate.epicboxOff) return outcomes;
    if (_checkRunning) return outcomes;
    _checkRunning = true;
    final window = wait ?? appConfig.contactsCheckWait;
    // Who was asked, and when (Unix ms, read before the call so an answer is always later).
    final asked = <String, int>{};
    final sentAt = <String, int>{};
    try {
      for (final c in await _w.contacts()) {
        if (only != null ? !only.contains(c.contactId) || !_checkable(c, anyKind: true) : !_checkable(c)) continue;
        final at = DateTime.now().millisecondsSinceEpoch;
        try {
          await _w.contactCheck(contactId: c.contactId);
          asked[c.contactId] = at;
        } on lepic.WalletError catch (error) {
          logWarn('pairing', 'contact check not sent: ${error.kind.name}');
          outcomes[c.contactId] = ContactCheckOutcome.failed;
        }
      }
      sentAt.addAll(asked);
      var waited = Duration.zero;
      var changed = false;
      void settle(String id, ContactCheckOutcome outcome) {
        outcomes[id] = outcome;
        asked.remove(id);
        if (outcome == ContactCheckOutcome.notAnswering) {
          _notAnswering[id] = sentAt[id]!;
          changed = true;
        } else if (_notAnswering.remove(id) != null) {
          changed = true;
        }
      }
      while (asked.isNotEmpty && waited < window && supported) {
        final step = window - waited < every ? window - waited : every;
        await Future<void>.delayed(step);
        waited += step;
        try {
          await collectOrFail(PairingCollectTrigger.foreground, only: asked.keys.toList());
        } on lepic.WalletError catch (error) {
          logWarn('pairing', 'contact check collect failed: ${error.kind.name}');
        }
        final now = {for (final c in await _w.contacts()) c.contactId: c};
        for (final id in asked.keys.toList()) {
          final c = now[id];
          final sent = asked[id]!;
          final relay = c?.requestedRelay;
          if (c == null || c.endedReason != null) {
            // Removed or ended meanwhile: not ours to judge.
            asked.remove(id);
            outcomes.remove(id);
          } else if (relay != null) {
            await _followCheckedMove(id, relay);
            settle(id, ContactCheckOutcome.moved);
          } else if ((c.lastSealedInMs ?? 0).toInt() > sent) {
            settle(id, ContactCheckOutcome.reachable);
          } else if (c.homeRelay != null && _relaysDown.contains(c.homeRelay)) {
            settle(id, ContactCheckOutcome.notAnswering);
          }
        }
      }
      // No word in the whole wait.
      for (final id in asked.keys.toList()) {
        settle(id, ContactCheckOutcome.notAnswering);
      }
      if (changed) _contactsChanged();
    } on lepic.WalletError catch (error) {
      logWarn('pairing', 'contact check failed: ${error.kind.name}');
    } finally {
      _checkRunning = false;
    }
    return outcomes;
  }

  bool _checkRunning = false;

  /// A checked contact's answer named another relay: follow it when the user lists that relay,
  /// else say so once, as the event path does.
  Future<void> _followCheckedMove(String id, String relay) async {
    if (_inServerList(relay)) {
      if (await _applyMove(id, relay)) _contactsChanged();
    } else if (_refusedMoves.add('$id $relay') && !_events.isClosed) {
      _events.add(PairingEvent(PairingEventKind.relayMoveRefused, pairingId: id, name: await _nameOf(id), relay: relay));
    }
  }

  /// What the engine does not list again: an invite's link and words, the answer to send by
  /// hand, the confirmation of a reply pasted by hand, how a pairing was made.
  final Map<String, String> _inviteLinks = {};
  final Map<String, String> _replyLinks = {};
  final Map<String, String> _confirmLinks = {};
  final Map<String, PairingWay> _ways = {};

  /// The address-book contact a pending pairing attaches to once it completes.
  final Map<String, String> _attachLater = {};

  /// Requests a linked device passed on, by id: answered here as LEPIC's own are, never stored
  /// by LEPIC. They go when answered, dismissed, handled on the other device or expired.
  final Map<String, PairRequest> _forwardedRequests = {};

  /// The sender of each request opened here, by its invite link: accepting it expects the
  /// confirm to prove that address.
  final Map<String, ({String requestId, String fromAddress})> _requestLinks = {};

  /// Allow invoices the user turned on before the words check; set on a match.
  final Set<String> _wantsInvoices = {};

  /// Answers that did not reach the relay: they go by hand.
  final Set<String> _unposted = {};

  /// Relays that did not answer (`domain:port`), until a collect finds them again.
  final Set<String> _relaysDown = {};

  /// What a slate a contact took part in was for, from the events.
  final Map<String, PairingSlate> _slates = {};

  /// Key checks this wallet started (RFC 7.8): the new pairing and the old one it checks.
  final Map<String, String> _checking = {};

  /// New pairings the engine folded into the old one when the key check found the old keys.
  /// It deletes them once their last message is out, a collect later and with no event, so
  /// they are never listed meanwhile: a contact has one pairing, the old one.
  final Set<String> _folded = {};

  /// A call to LEPIC: its pairing errors as the app's [PairingFailure], the rest mapped.
  /// [attach]: the call attaches a pairing ([lepicPairingFailure]).
  Future<T> _call<T>(Future<T> Function() call, {bool attach = false}) async {
    try {
      return await call();
    } on lepic.WalletError catch (error) {
      final failure = lepicPairingFailure(error.kind, error.message, attach);
      if (failure != null) throw pairingError(failure);
      throw mapLepicError(error);
    }
  }

  DateTime _ms(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  List<SasWord> _sas(List<lepic.SasEntry> e) => [for (final w in e) SasWord(w.emoji, w.name)];

  /// [inviter], [inviteLink] and [way] are given for a private pairing (a device link).
  PairingRecord _record(lepic.ContactView c, {bool? inviter, String? inviteLink, PairingWay? way}) => PairingRecord(
    id: c.contactId,
    // A private pairing in progress is listed with its pending state; a stored one by LEPIC's
    // derived status.
    state: c.state == lepic.PairingState.pendingInvite || c.state == lepic.PairingState.pendingReply
        ? lepicPairingState(c.state)
        : lepicPairingStatus(c.status),
    way: way ?? _ways[c.contactId] ?? PairingWay.link,
    // The inviter of a pairing whose answer came by hand: its confirm can be sent again.
    inviter: inviter ?? _confirmLinks.containsKey(c.contactId),
    inviteLink: inviteLink,
    createdAt: _ms(c.createdAtMs.toInt()),
    name: c.claimedName,
    label: c.label.isEmpty ? null : c.label,
    kind: lepicPairingParty(c.kind),
    sas: _sas(c.sas),
    verifiedAt: c.verifiedAtMs == null ? null : _ms(c.verifiedAtMs!.toInt()),
    allowInvoices: c.allowInvoices,
    asksInvoices: _wantsInvoices.contains(c.contactId),
    seal: switch (c.seal) {
      lepic.SealState.on_ => SealMode.on,
      lepic.SealState.off => SealMode.off,
      lepic.SealState.degraded => SealMode.degraded,
    },
    homeRelay: c.homeRelay ?? '',
    contactId: c.appContact,
    // Since pairing until a sealed message opens, as LEPIC counts it for "lapsed".
    lastSealedIn: _ms((c.lastSealedInMs ?? c.createdAtMs).toInt()),
    relayDown: c.homeRelay != null && _relaysDown.contains(c.homeRelay),
    notAnswering: _isNotAnswering(c),
    otherDevice: c.importedFromBackup,
    checksKeys: _checking.containsKey(c.contactId),
    // Only from a verified address proof of this pairing; a pairing made before 26.10.25 has
    // none, and nothing here stands in for it.
    paymentsAddress: c.paymentsAddress,
    peerHeardAt: c.peerHeardAtMs == null ? null : _ms(c.peerHeardAtMs!.toInt()),
    peerVerifiedAt: c.peerVerifiedAtMs == null ? null : _ms(c.peerVerifiedAtMs!.toInt()),
    peerFeatures: c.peerFeatures,
    peerProfile: c.peerProfile,
    endedReason: c.endedReason == null ? null : lepicPairingEndReason(c.endedReason!),
    endedAt: c.endedAtMs == null ? null : _ms(c.endedAtMs!.toInt()),
  );

  PairingRecord _pending(lepic.PendingPairingView p) => PairingRecord(
    id: p.contactId,
    state: p.inviter ? PairingState.pendingInvite : PairingState.pendingReply,
    way: _ways[p.contactId] ?? PairingWay.link,
    inviter: p.inviter,
    createdAt: _ms(p.createdAtMs.toInt()),
    name: p.inviter ? null : p.inviteName,
    label: p.label.isEmpty ? null : p.label,
    expiresAt: _ms(p.expiresAtMs.toInt()),
    inviteLink: _inviteLinks[p.contactId],
    expectAddress: p.expectAddress,
    homeRelay: p.homeRelay,
    // An answer the relay did not take, or a home relay that did not answer the last collect:
    // past its time such a pairing still waits for one drain (LEPIC LATE_DRAIN_WAIT).
    relayDown: _unposted.contains(p.contactId) || _relaysDown.contains(p.homeRelay),
    contactId: _attachLater[p.contactId],
  );

  /// The name the app shows for [contactId]: the user's label, else the name it chose.
  Future<String> _nameOf(String? contactId) async {
    if (contactId == null) return '';
    try {
      final c = await _w.contact(contactId: contactId);
      if (c.label.isNotEmpty) return c.label;
      final app = c.appContact;
      if (app != null) {
        final saved = (await _s.contacts()).where((x) => x.id == app).firstOrNull;
        if (saved != null) return saved.name;
      }
      return c.claimedName ?? '';
    } on lepic.WalletError {
      return '';
    }
  }

  /// LEPIC's transaction id of the slate [slateId] (the newest when there are two).
  Future<int?> _txOfSlate(String slateId) async {
    int? id;
    for (final t in await _w.transactions()) {
      if (t.slateId == slateId && (id == null || t.txId > id)) id = t.txId;
    }
    return id;
  }

  @override
  bool get supported => !_w.isDisposed;

  @override
  Future<List<PairingRecord>> pairings() => _call(() async {
    final pending = [for (final p in await _w.pairingsPending()) _pending(p)];
    var contacts = await _w.contacts();
    if (await _followMoves(contacts)) contacts = await _w.contacts();
    final paired = [
      for (final c in contacts)
        if (!_folded.contains(c.contactId)) _record(c),
    ];
    // Newest first, as the app lists them; a new pairing still checking the keys of its
    // contact's old one last, so the contact's pairing stays the old one, which stays whatever
    // the check finds.
    final checking = [for (final r in paired.reversed) if (_checking.containsKey(r.id)) r];
    return [...pending.reversed, for (final r in paired.reversed) if (!_checking.containsKey(r.id)) r, ...checking];
  });

  @override
  Future<PairingRecord?> pairing(String id) async {
    for (final r in await pairings()) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<PairingRecord?> pairingForContact(String contactId) => _call(() async {
    final found = [
      for (final c in (await _w.pairingsForAppContact(appContact: contactId)).reversed)
        if (!_folded.contains(c.contactId)) _record(c),
    ];
    return contactPairingOf(found, contactId);
  });

  // No second answers are kept: the engine refuses a used invite.
  @override
  Future<List<PairingStray>> strays() async => const [];

  @override
  Future<void> removeStray(String id) async {}


  @override
  Future<PairingRecord> standingCode({required String name}) => _call(() async {
    // LEPIC keeps the standing code and makes it anew when it was answered, has under a day
    // left, names another relay than the wallet's now or another name (withdrawing the old
    // one then). Online on the wallet's own relay; it sends nothing.
    final invite = await _w.pairingStandingInvite(name: name.trim());
    final id = invite.contactId;
    _inviteLinks[id] = invite.link;
    _ways[id] = PairingWay.link;
    return PairingRecord(
      id: id,
      state: PairingState.pendingInvite,
      way: PairingWay.link,
      inviter: true,
      createdAt: DateTime.now(),
      name: name.trim(),
      expiresAt: _ms(invite.expiresAtMs.toInt()),
      inviteLink: invite.link,
    );
  });

  @override
  Future<int> setOwnName(String name) => _call(() => _w.contactsSetOwnName(name: name.trim()));

  @override
  Future<PairingRecord> requestPairing({required String toAddress, required String name, String? contactId}) => _call(() async {
    final view = await _w.pairingRequestSend(
      toAddress: lepicEpicboxAddress(toAddress),
      name: name.trim(),
      relayMode: lepicRelayMode(),
    );
    final id = view.contactId;
    _ways[id] = PairingWay.request;
    if (contactId != null) _attachLater[id] = contactId;
    return _pending(view);
  });

  PairRequest _request(lepic.PairRequestView r) => PairRequest(
    id: r.requestId,
    fromAddress: r.fromAddress,
    claimedName: r.claimedName,
    kind: lepicPairingParty(r.kind),
    receivedAt: _ms(r.receivedAtMs.toInt()),
    expiresAt: _ms(r.expiresAtMs.toInt()),
    inviteLink: r.inviteLink,
  );

  @override
  Future<List<PairRequest>> requests() => _call(() async {
    final now = DateTime.now();
    _forwardedRequests.removeWhere((_, r) => r.expiredAt(now));
    final own = [for (final r in await _w.pairingRequests()) _request(r)];
    final ids = {for (final r in own) r.id};
    // Oldest first, LEPIC's and the linked device's alike.
    return [...own, for (final r in _forwardedRequests.values) if (!ids.contains(r.id)) r]
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
  });

  @override
  Future<void> takeForwardedRequest(PairRequest request) async {
    if (request.expiredAt(DateTime.now())) return;
    _forwardedRequests[request.id] = request;
    if (!_events.isClosed) {
      _events.add(PairingEvent(PairingEventKind.requested, requestId: request.id, sender: request.fromAddress, name: request.claimedName));
    }
  }

  @override
  Future<PairingInvitePreview> openRequest(String requestId) => _call(() async {
    final request = (await requests()).where((r) => r.id == requestId).firstOrNull ?? (throw pairingError(PairingFailure.notFound));
    final link = request.inviteLink.trim();
    final preview = await _w.pairingPreview(link: link);
    _requestLinks[link] = (requestId: request.id, fromAddress: request.fromAddress);
    return _preview(link, preview, fromAddress: request.fromAddress, requestId: request.id);
  });

  @override
  Future<void> dismissRequest(String requestId) => _call(() async {
    final forwarded = _forwardedRequests.remove(requestId) != null;
    try {
      await _w.pairingRequestDismiss(requestId: requestId);
    } on lepic.WalletError catch (error) {
      // One the linked device passed on is not LEPIC's here.
      if (!(forwarded && error.kind == lepic.WalletErrorKind.pairingNotFound)) rethrow;
    }
  });

  @override
  Future<void> requestHandledOn(String requestId, String device) => _call(() async {
    final known = _forwardedRequests.remove(requestId) != null;
    var stored = false;
    try {
      await _w.pairingRequestDismiss(requestId: requestId);
      stored = true;
    } on lepic.WalletError catch (error) {
      // Not stored here (it reached the other device only), or answered or gone already.
      if (error.kind != lepic.WalletErrorKind.pairingNotFound) rethrow;
    }
    if ((known || stored) && !_events.isClosed) {
      _events.add(PairingEvent(PairingEventKind.pairedElsewhere, requestId: requestId, name: device));
    }
  });

  @override
  Future<void> cancelInvite(String id) => _call(() => _w.pairingCancel(contactId: id));

  /// A reply or confirmation pasted by hand.
  Future<PairingRecord> _enterLink(String link) => _call(() async {
    final r = await _w.pairingEnterLink(text: link, relayMode: lepicRelayMode());
    final id = r.contactId;
    if (r.outcome == lepic.PairingLinkOutcome.ignored || id == null) throw pairingError(PairingFailure.notFound);
    if (r.link case final confirm?) _confirmLinks[id] = confirm;
    await _attachPending(id);
    return (await pairing(id)) ?? (throw pairingError(PairingFailure.notFound));
  });

  @override
  Future<PairingRecord> openReply(String link) => _enterLink(link);

  @override
  Future<PairingRecord> openConfirm(String link) => _enterLink(link);

  @override
  Future<String> confirmLink(String id) async => _confirmLinks[id] ?? (throw pairingError(PairingFailure.notFound));

  PairingInvitePreview _preview(String link, lepic.InvitePreview p, {String? fromAddress, String? requestId}) => PairingInvitePreview(
    token: link,
    name: p.claimedName,
    expiresAt: _ms(p.expiresAtMs.toInt()),
    kind: lepicPairingParty(p.kind),
    asksInvoices: p.service,
    homeRelay: p.homeRelay,
    wordsAvailable: lepicRelayMode() == lepic.ContactRelayMode.online,
    fromAddress: fromAddress,
    requestId: requestId,
    inviteKey: inviteKeyOf(link),
  );

  @override
  Future<PairingInvitePreview> openInvite(String link) => _call(() async {
    final preview = await _w.pairingPreview(link: link.trim());
    _refuseOwn(preview);
    return _preview(link.trim(), preview);
  });

  /// This wallet's own invite, opened here: refused before "Pair with …?", which
  /// LEPIC would only refuse on the answer. LEPIC's preview knows every invite this wallet
  /// made, standing, waiting or cancelled, also after a restart.
  void _refuseOwn(lepic.InvitePreview p) {
    if (p.own) throw pairingError(PairingFailure.ownCard);
  }

  @override
  Future<PairingRecord> acceptInvite({
    required String token,
    required String name,
    bool allowInvoices = false,
    String? contactId,
    bool byHand = false,
  }) => _call(() async {
    // A request's code: the confirm must prove the sender's address, and LEPIC marks the
    // request answered.
    final request = _requestLinks[token.trim()];
    final answer = await _w.pairingAccept(
      link: token,
      name: name.trim(),
      byHand: byHand,
      relayMode: lepicRelayMode(),
      pairingClass: lepic.PairingClass.contact,
      expectAddress: request?.fromAddress,
    );
    final id = answer.contactId;
    _replyLinks[id] = answer.replyLink;
    _ways[id] = request == null ? PairingWay.link : PairingWay.request;
    if (request != null) {
      _requestLinks.remove(token.trim());
      _forwardedRequests.remove(request.requestId);
      // The first Pair wins: a linked device hides its copy ([requestHandledOn]).
      if (!_events.isClosed) _events.add(PairingEvent(PairingEventKind.requestAnswered, requestId: request.requestId, pairingId: id));
    }
    if (allowInvoices) _wantsInvoices.add(id);
    if (contactId != null) _attachLater[id] = contactId;
    if (!answer.posted && !byHand) _unposted.add(id);
    return (await pairing(id)) ??
        PairingRecord(
          id: id,
          state: PairingState.pendingReply,
          way: PairingWay.link,
          inviter: false,
          createdAt: DateTime.now(),
          relayDown: _unposted.contains(id),
          contactId: contactId,
        );
  });

  @override
  Future<String> replyLink(String id) async => _replyLinks[id] ?? (throw pairingError(PairingFailure.notFound));

  @override
  Future<PairingRecord?> checkWords(String id, PairingCheck check) => _call(() async {
    await _w.pairingSas(
      contactId: id,
      decision: switch (check) {
        PairingCheck.match => lepic.SasDecision.match,
        PairingCheck.mismatch => lepic.SasDecision.mismatch,
        PairingCheck.skip => lepic.SasDecision.skip,
      },
      relayMode: lepicRelayMode(),
    );
    // A mismatch ends the record and keeps it: the ended record comes back.
    if (check == PairingCheck.mismatch) {
      if (_privateLinks.containsKey(id) || (await _w.privatePairings()).any((c) => c.contactId == id)) return _privateOf(id);
      try {
        return _record(await _w.contact(contactId: id));
      } on lepic.WalletError catch (error) {
        if (error.kind == lepic.WalletErrorKind.contactNotFound) return null;
        rethrow;
      }
    }
    // Allow invoices the user turned on while answering applies once the words match.
    if (check == PairingCheck.match && _wantsInvoices.remove(id)) {
      await _w.contactSetAllowInvoices(contactId: id, allow: true);
    }
    if (_privateLinks.containsKey(id) || (await _w.privatePairings()).any((c) => c.contactId == id)) return _privateOf(id);
    return _record(await _w.contact(contactId: id));
  });

  @override
  Future<int> collect({PairingCollectTrigger trigger = PairingCollectTrigger.foreground}) async {
    if (!supported || NetGate.epicboxOff) return 0;
    try {
      return await collectOrFail(trigger);
    } on lepic.WalletError catch (error) {
      logWarn('pairing', 'collect failed: ${error.kind.name}');
      return 0;
    } finally {
      // Contact invoices arrive with this collect: what ran out expires on the same beat.
      if (NetGate.invoices && !_s._wallet.isDisposed) await _s._sweep();
    }
  }

  /// [collect], failing as LEPIC does: a check the user asked for says when the relay is
  /// down.
  Future<int> collectOrFail(PairingCollectTrigger trigger, {List<String>? only}) async {
    // Pairing off (Settings › Advanced › Experimental): no pairing or contact mailbox is opened.
    if (!NetGate.pairing) return 0;
    _s._watchEvents();
    final before = {for (final c in await _w.contacts()) c.contactId};
    final report = await _w.contactsCollect(
      trigger: switch (trigger) {
        PairingCollectTrigger.open => lepic.CollectTrigger.open,
        PairingCollectTrigger.foreground => lepic.CollectTrigger.foreground,
        PairingCollectTrigger.pull => lepic.CollectTrigger.pull,
        PairingCollectTrigger.push => lepic.CollectTrigger.push,
      },
      relayMode: lepicRelayMode(),
      only: only,
    );
    // A relay that answers again is no longer down; a look at a few contacts says nothing of
    // the others' relays.
    if (only == null) {
      _relaysDown.retainAll(report.unreachable);
    } else {
      final looked = {
        for (final c in await _w.contacts())
          if (only.contains(c.contactId) && c.homeRelay != null) c.homeRelay!,
      };
      _relaysDown.removeAll(looked.difference(report.unreachable.toSet()));
    }
    try {
      await _w.contactsOutboxDeliver(relayMode: lepicRelayMode());
    } on lepic.WalletError catch (error) {
      // The outbox retries on the next collect.
      logWarn('pairing', 'outbox not delivered: ${error.kind.name}');
    }
    // The engine drops a folded pairing without an event: the lists read again.
    final now = {for (final c in await _w.contacts()) c.contactId};
    _folded.retainAll(now);
    // Pairings that ended this cycle are kept, ended: their own events name them; the lists
    // read again.
    if ((before.difference(now).isNotEmpty || report.ended.isNotEmpty) && !_events.isClosed) {
      _events.add(const PairingEvent(PairingEventKind.contactUpdated));
    }
    return report.paired + report.ended.length;
  }

  @override
  Future<void> removePairing(String id) => _call(() async {
    // The other side is told, best effort, so it stops sending through it (RFC 7.6).
    await _w.contactUnpair(contactId: id, relayMode: lepicRelayMode());
  });

  @override
  Future<PairingRecord> setSeal(String id, bool on) => _call(() async {
    await _w.contactSetSeal(contactId: id, seal: on);
    return _record(await _w.contact(contactId: id));
  });

  @override
  Future<int> setAllowInvoices(String id, bool on) => _call(() async {
    final before = on ? 0 : (await _w.contactInvoices()).where((i) => i.contactId == id).length;
    await _w.contactSetAllowInvoices(contactId: id, allow: on);
    if (on) return 0;
    final after = (await _w.contactInvoices()).where((i) => i.contactId == id).length;
    return before - after;
  });

  /// Attaches a pending pairing that completed to the contact it was made for.
  Future<void> _attachPending(String id) async {
    final app = _attachLater.remove(id);
    if (app == null) return;
    try {
      await attach(id, app);
    } on WalletError catch (error) {
      logWarn('pairing', 'could not attach a pairing: ${error.kind.name}');
    }
  }

  @override
  Future<PairingRecord> attach(String id, String? contactId, {String? contactAddress}) => _call(attach: true, () async {
    // The one check of every way in (pickers, the same-name offer, an invite made from a
    // contact) is LEPIC's: refused, nothing changed, when the contact's Epicbox address is not
    // the one the pairing proves (`OtherAddress`) or the pairing proves none, as one made
    // before 26.10.25 (`AddressProofMissing`). The proven address is written into the book by
    // the app at Verified only ([writeProvenAddress]), never here.
    // The contact's own address when the caller gave none (a pairing attached as it completes).
    final given = contactAddress ?? (contactId == null ? null : (await _s.contacts()).where((c) => c.id == contactId).firstOrNull?.epicbox);
    final address = given == null || given.trim().isEmpty ? null : lepicEpicboxAddress(given);
    // A contact that has a pairing already: the new one checks whether its keys are back.
    final before = contactId == null ? const <lepic.ContactView>[] : await _w.pairingsForAppContact(appContact: contactId);
    await _w.contactAttach(contactId: id, appContact: contactId, appAddress: contactId == null ? null : address);
    final old = before
        .where((c) => c.contactId != id && c.state != lepic.PairingState.keysChanged && c.status != lepic.PairingStatus.ended)
        .firstOrNull;
    if (old != null) {
      try {
        // No check allowed now (one a day per slot): LEPIC puts the new pairing in keys
        // changed at once and says so (contactKeysChanged), so the dead old one is not used.
        final started = await _w.contactKeyCheck(new_: id, old: old.contactId, relayMode: lepicRelayMode());
        if (started == lepic.KeyCheckStart.sent) _checking[id] = old.contactId;
      } on lepic.WalletError catch (error) {
        logWarn('pairing', 'key check not started: ${error.kind.name}');
        // Said, not silent: the contact now uses the new pairing.
        if (error.kind == lepic.WalletErrorKind.keyCheckRefused && !_events.isClosed) {
          _events.add(PairingEvent(PairingEventKind.keyCheckRefused, pairingId: id, name: await _nameOf(id)));
        }
      }
    }
    return _record(await _w.contact(contactId: id));
  });

  @override
  Future<PairingRecord> resolveKeysChanged(String id, KeysChoice choice) => _call(() async {
    final app = (await _w.contact(contactId: id)).appContact;
    await _w.contactKeysResolve(
      new_: id,
      decision: choice == KeysChoice.keepOld ? lepic.KeysDecision.keepOld : lepic.KeysDecision.useNew,
    );
    if (choice == KeysChoice.useNew) {
      // The new keys are the contact's: its older pairings are the ones the other side lost
      // (a restore), dead, so they do not stay on the contact as if they worked.
      final kept = await _w.contact(contactId: id);
      if (app != null) {
        for (final c in await _w.pairingsForAppContact(appContact: app)) {
          if (c.contactId != id && c.createdAtMs < kept.createdAtMs) await _w.contactRemove(contactId: c.contactId);
        }
      }
      return _record(kept);
    }
    final kept = app == null ? null : (await _w.pairingsForAppContact(appContact: app)).lastOrNull;
    if (kept == null) throw pairingError(PairingFailure.notFound);
    return _record(kept);
  });

  @override
  Future<IssuedInvoice> requestPayment({required String id, required BigInt amount, String? message}) =>
      _s._issueToContact(contactId: id, amount: amount, message: message);

  @override
  Future<Slate> requestFile({required BigInt amount, String? message}) => _s._issueFile(amount: amount, message: message);

  @override
  Future<String> sealSlate({required String id, required String slateJson}) => _call(() async {
    final slateId = (jsonDecode(slateJson) as Map<String, Object?>)['id'];
    final txId = slateId is String ? await _txOfSlate(slateId) : null;
    if (txId == null) throw const WalletError(kind: WalletErrorKind.invalidSlate, message: 'no transaction for this slate');
    return _w.contactSealSlate(contactId: id, txId: txId);
  });

  @override
  Future<OpenedSlate> openSlate(String text) => _call(() async {
    if (!isSealedLepicText(text)) return OpenedSlate(slateJson: text);
    final v = await _w.sealedOpen(text: text.trim());
    return OpenedSlate(
      pairingId: v.contactId,
      sealed: true,
      stage: lepicSlateStage(v.stage),
      slateId: v.slateId,
      amount: v.amount,
      fee: v.fee,
      purpose: v.purpose == null ? null : lepicSlatePurpose(v.purpose!),
      reference: v.reference,
      messages: lepicMessages(v.messages),
    );
  });

  @override
  Future<PaidSealedRequest> paySealedRequest(String text, {required BigInt amount}) => _s._nodeGuard('pay sealed request', () async {
    final a = await _call(
      () async => _w.sealedPay(
        text: text.trim(),
        amount: amount,
        minimumConfirmations: await _s._balanceConfirmations(),
        options: _s._heldOnly,
      ),
    );
    logInfo('invoices', 'sealed request paid');
    return PaidSealedRequest(
      paid: PaidRequestFile(txId: a.txId, slateId: a.slateId, amount: a.amount, fee: a.fee, json: a.answer),
      sealed: a.sealed,
    );
  });

  @override
  Future<SealedReply> receiveSealed(String text, {String? message}) => _call(() async {
    final a = await _w.sealedReceive(text: text.trim(), message: _message(message));
    return SealedReply(slateId: a.slateId, answer: a.answer, sealed: a.sealed);
  });

  @override
  Future<TxEntry> finalizeSealed(String text) => _call(() async {
    final tx = await _w.sealedFinalize(text: text.trim());
    return _s._entry(tx.txId);
  });

  @override
  Future<TxEntry> sendViaMailbox({
    required String id,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  }) => _call(() async {
    // LEPIC checks the pairing before it locks anything, makes the payment and queues it
    // sealed for the contact's mailbox (RFC 9.1), posted when relays may be reached; one it
    // could not queue it cancels. The answer comes back by collecting.
    final sent = await _w.contactSend(
      contactId: id,
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      message: _message(message),
      options: await _s._optionsFor(amount, minimumConfirmations, options),
      purpose: lepic.SlatePurpose.payment,
      relayMode: lepicRelayMode(),
    );
    _slates[sent.slateId] = PairingSlate(pairingId: id, purpose: SlatePurpose.payment);
    return _s._entry(sent.txId);
  });

  @override
  Future<String> plainSlate(String txKey) => _call(() async {
    final int? txId = txKey.startsWith('s:') ? await _txOfSlate(txKey.substring(2)) : await _s._txIdOf(txKey);
    if (txId == null) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'not a sealed send');
    return _w.contactPlainFallback(txId: txId);
  });

  // The engine marks pairings restored from a backup; they work here as they are.
  @override
  Future<int> useImportedPairings() => _call(() async => (await _w.contacts()).where((c) => c.importedFromBackup).length);

  @override
  Future<PairingSlate?> slateOf(String slateId) => _call(() async {
    final known = _slates[slateId];
    if (known != null) return known;
    final txId = await _txOfSlate(slateId);
    final contact = txId == null ? null : await _w.contactOfTransaction(txId: txId);
    return contact == null ? null : PairingSlate(pairingId: contact, purpose: SlatePurpose.payment);
  });

  @override
  Stream<PairingEvent> events() {
    _s._watchEvents();
    return _events.stream;
  }

  // Private pairings (linked devices): LEPIC's private class, never listed with the contacts.

  /// Private invites this run made, by id: their link for the QR, and that this side invited.
  final Map<String, String> _privateLinks = {};

  @override
  bool get privateSupported => true;

  PairingRecord _privateRecord(lepic.ContactView c) =>
      _record(c, inviter: _privateLinks.containsKey(c.contactId), inviteLink: _privateLinks[c.contactId], way: PairingWay.link);

  @override
  Future<List<PairingRecord>> privatePairings() => _call(() async {
    final all = [for (final c in await _w.privatePairings()) _privateRecord(c)];
    return all.reversed.toList();
  });

  Future<PairingRecord> _privateOf(String id) async {
    for (final c in await _w.privatePairings()) {
      if (c.contactId == id) return _privateRecord(c);
    }
    throw pairingError(PairingFailure.notFound);
  }

  @override
  Future<PairingRecord> makePrivateInvite({required String name, required String homeRelay, Duration expiry = privateInviteExpiry}) =>
      _call(() async {
        // The shortest expiry LEPIC offers; the link flow itself gives up after [expiry].
        final invite = await _w.pairingInvite(
          name: name.trim(),
          kind: lepic.ContactKind.person,
          expiry: lepic.InviteExpiry.oneHour,
          offerWords: false,
          relayMode: lepicRelayMode(),
          // No words: no meeting relay is asked.
          meetingRelays: const [],
          homeRelay: homeRelay,
          pairingClass: lepic.PairingClass.private,
        );
        _privateLinks[invite.contactId] = invite.link;
        return _privateOf(invite.contactId);
      });

  @override
  Future<PairingRecord> acceptPrivateInvite({required String link, required String name}) => _call(() async {
    final answer = await _w.pairingAccept(
      link: link.trim(),
      name: name.trim(),
      byHand: false,
      relayMode: lepicRelayMode(),
      pairingClass: lepic.PairingClass.private,
    );
    return _privateOf(answer.contactId);
  });

  @override
  Future<int> collectPrivate({List<String>? only}) async {
    if (NetGate.restricted || !NetGate.linkedDevices) return 0;
    _s._watchEvents();
    try {
      final ids = only ?? [for (final c in await _w.privatePairings()) c.contactId];
      if (ids.isEmpty) return 0;
      final report = await _w.contactsCollect(trigger: lepic.CollectTrigger.foreground, relayMode: lepicRelayMode(), only: ids);
      try {
        await _w.contactsOutboxDeliver(relayMode: lepicRelayMode());
      } on lepic.WalletError catch (error) {
        logWarn('devices', 'outbox not delivered: ${error.kind.name}');
      }
      return report.paired;
    } on lepic.WalletError catch (error) {
      logWarn('devices', 'collect failed: ${error.kind.name}');
      return 0;
    }
  }

  @override
  Future<void> postPayload({required String id, required List<int> bytes}) => _call(() async {
    await _w.contactPostPayload(contactId: id, payload: Uint8List.fromList(bytes), relayMode: lepicRelayMode());
  });

  @override
  Future<List<PairingPayload>> payloads() => _call(() async => [
    for (final p in await _w.contactPayloads())
      PairingPayload(id: p.id, pairingId: p.contactId, bytes: p.payload, receivedAt: _ms(p.receivedAtMs.toInt())),
  ]);

  @override
  Future<void> ackPayloads(List<String> ids) => _call(() async {
    if (ids.isNotEmpty) await _w.contactPayloadsAck(ids: ids);
  });

  /// A LEPIC wallet event about a contact, as the app's, or nothing for any other.
  Future<void> onWalletEvent(lepic.WalletEvent e) async {
    final id = e.contactId;
    final slateId = e.slateId;
    if (e.kind == lepic.WalletEventKind.contactRelayMoveRequested) {
      final relay = e.relay;
      if (id == null || relay == null || _events.isClosed) return;
      // Only to a relay the user lists; otherwise the contact keeps its mailbox and the user is told.
      if (_inServerList(relay)) {
        if (await _applyMove(id, relay) && !_events.isClosed) _events.add(PairingEvent(PairingEventKind.contactUpdated, pairingId: id));
      } else {
        _refusedMoves.add('$id $relay');
        _events.add(PairingEvent(PairingEventKind.relayMoveRefused, pairingId: id, name: await _nameOf(id), relay: relay));
      }
      return;
    }
    if (e.kind == lepic.WalletEventKind.homeRelayUnreachable && e.relay != null) _relaysDown.add(e.relay!);
    if (e.kind == lepic.WalletEventKind.contactKeysRestored && id != null) {
      // The old pairing [id] has its keys back: the new one checking it was folded into it.
      for (final fresh in [for (final c in _checking.entries) if (c.value == id) c.key]) {
        _checking.remove(fresh);
        _folded.add(fresh);
      }
    }
    if (e.kind == lepic.WalletEventKind.contactKeysChanged && id != null) _checking.remove(id);
    if (e.kind == lepic.WalletEventKind.contactPaymentFinalized && id != null && slateId != null) {
      _slates[slateId] = PairingSlate(pairingId: id, purpose: SlatePurpose.payment);
    }
    if (e.kind == lepic.WalletEventKind.withdrawalFromContact && id != null && slateId != null) {
      _slates[slateId] = PairingSlate(pairingId: id, purpose: SlatePurpose.withdrawal, reference: e.reference);
    }
    if (e.kind == lepic.WalletEventKind.pairingReplied || e.kind == lepic.WalletEventKind.pairingConfirmed) {
      if (id != null) {
        _unposted.remove(id);
        await _attachPending(id);
      }
    }
    final kind = switch (e.kind) {
      lepic.WalletEventKind.pairingReplied => PairingEventKind.replied,
      lepic.WalletEventKind.pairingConfirmed => PairingEventKind.confirmed,
      lepic.WalletEventKind.pairingFailed => PairingEventKind.failed,
      lepic.WalletEventKind.contactUpdated => switch (e.contactChange) {
        lepic.ContactChange.heard => PairingEventKind.heard,
        lepic.ContactChange.peerVerified => PairingEventKind.peerVerified,
        lepic.ContactChange.address => PairingEventKind.addressUpdated,
        lepic.ContactChange.ended => PairingEventKind.ended,
        lepic.ContactChange.card || null => PairingEventKind.contactUpdated,
      },
      lepic.WalletEventKind.pairingRequested => PairingEventKind.requested,
      lepic.WalletEventKind.homeRelayUnreachable => PairingEventKind.homeRelayUnreachable,
      lepic.WalletEventKind.contactKeysRestored => PairingEventKind.keysRestored,
      lepic.WalletEventKind.contactKeysChanged => PairingEventKind.keysChanged,
      lepic.WalletEventKind.invoiceFromContact => PairingEventKind.invoiceFromContact,
      lepic.WalletEventKind.withdrawalFromContact => PairingEventKind.withdrawalFromContact,
      lepic.WalletEventKind.sealedReceived => PairingEventKind.sealedReceived,
      lepic.WalletEventKind.sealedUnopenable => PairingEventKind.sealedUnopenable,
      lepic.WalletEventKind.outboxDelivered => PairingEventKind.outboxDelivered,
      lepic.WalletEventKind.outboxStuck => PairingEventKind.outboxStuck,
      lepic.WalletEventKind.contactPaymentFinalized => PairingEventKind.paymentFinalized,
      lepic.WalletEventKind.contactUnpaired => PairingEventKind.unpaired,
      _ => null,
    };
    if (kind == null || _events.isClosed) return;
    // The relay's contact: the event names the relay, the app the contact whose it is.
    var contact = id;
    if (contact == null && e.relay != null) {
      contact = (await _w.contacts()).where((c) => c.homeRelay == e.relay).firstOrNull?.contactId;
    }
    _events.add(
      PairingEvent(
        kind,
        pairingId: contact,
        name: await _nameOf(contact),
        failure: switch (e.pairingFailure) {
          lepic.PairingFailureReason.changedOnTheWay => PairingFailure.changedOnTheWay,
          lepic.PairingFailureReason.expired => PairingFailure.noAnswer,
          lepic.PairingFailureReason.notConfirmed => PairingFailure.notCompleted,
          lepic.PairingFailureReason.refused => PairingFailure.alreadyUsed,
          lepic.PairingFailureReason.otherAddress => PairingFailure.otherWallet,
          lepic.PairingFailureReason.addressProofMissing => PairingFailure.addressProofMissing,
          lepic.PairingFailureReason.crossed => PairingFailure.crossed,
          lepic.PairingFailureReason.kindDiffers => PairingFailure.kindDiffers,
          null => null,
        },
        slateId: slateId,
        amount: e.amount,
        requestId: e.requestId,
        sender: kind == PairingEventKind.requested ? e.sender : null,
        endedReason: e.endedReason == null ? null : lepicPairingEndReason(e.endedReason!),
      ),
    );
  }

  void close() => _events.close();

  /// The pairings for the `.wfeh` backup (RFC 9.5): LEPIC's own document, which holds no
  /// secret.
  Future<Map<String, Object?>?> exportBackup() async {
    if ((await _w.contacts()).isEmpty) return null;
    return {'lepic': await _w.contactsExport()};
  }

  /// Takes the pairings of a backup in; they are marked as possibly in use elsewhere too.
  Future<int> importBackup(Map<String, Object?>? backup) async {
    final document = backup?['lepic'];
    if (document is! String) return 0;
    final before = {for (final c in await _w.contacts()) c.contactId};
    final summary = await _w.contactsImport(document: document);
    if (summary.imported > 0) {
      // A restored pairing may be stale or gone: ask each one once, whatever its kind.
      final restored = {for (final c in await _w.contacts()) c.contactId}.difference(before);
      if (restored.isNotEmpty) unawaited(checkContacts(only: restored).then<void>((_) {}, onError: (Object _) {}));
    }
    return summary.imported;
  }
}

/// LEPIC's armored sealed text (RFC 3.5): `BEGINEPICSEALED` after optional whitespace.
bool isSealedLepicText(String text) => text.trimLeft().startsWith('BEGINEPICSEALED');

/// [address] with its Epicbox server: a bare key names the settings' `epicbox.default`. LEPIC
/// refuses an address without one and has no default of its own.
String lepicEpicboxAddress(String address) {
  final a = address.trim();
  if (a.isEmpty || a.contains('@') || a.contains('://') || !hostSettingsLoaded) return address;
  return '$a@${hostSettings.epicboxDefault}';
}
