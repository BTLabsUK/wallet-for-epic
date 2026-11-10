// SPDX-License-Identifier: Apache-2.0
// Live: an install's wallet opened by this build, as the desktop app opens it, with nothing on
// the network (Kill switch on, Tor off), and everything it reads written to one JSON file. Run it
// on copies of a data folder with the library of each build to compare what an update keeps,
// and on a copy a newer build upgraded to see how this build refuses it. Skipped unless these
// are set:
//
//   WFE_LEPIC_LIB       the Linux library of the build under test
//   WFE_MIG_DESK        a copy of a .epic_cash_desktop folder (its wallets.json names dataDir)
//   WFE_MIG_STORE       the app's secure storage of that install as a JSON object (mode 600)
//   WFE_MIG_PASSWORD    a file holding the wallet password
//   WFE_MIG_OUT         where the JSON goes; an open that fails writes {"error": ...}
//
// Nothing prints a phrase, a password or an address.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _env = Platform.environment;

Object? _v(Object? x) => switch (x) {
  null || bool() || int() || String() => x,
  BigInt() => x.toString(),
  double() => x.toString(),
  Enum() => x.name,
  DateTime() => x.toUtc().toIso8601String(),
  Duration() => x.inMilliseconds,
  Iterable() => [for (final e in x) _v(e)],
  Map() => {for (final e in x.entries) '${e.key}': _v(e.value)},
  _ => x.toString(),
};

Map<String, Object?> _dTxEntry(TxEntry x) => {'key': _v(x.key), 'id': _v(x.id), 'slateId': _v(x.slateId), 'kind': _v(x.kind), 'status': _v(x.status), 'source': _v(x.source), 'createdAtUnix': _v(x.createdAtUnix), 'timeUnix': _v(x.timeUnix), 'confirmed': _v(x.confirmed), 'blockHeight': _v(x.blockHeight), 'blockTimeUnix': _v(x.blockTimeUnix), 'amountCredited': _v(x.amountCredited), 'amountDebited': _v(x.amountDebited), 'fee': _v(x.fee), 'numInputs': _v(x.numInputs), 'numOutputs': _v(x.numOutputs), 'kernelExcess': _v(x.kernelExcess), 'outputCommits': _v(x.outputCommits), 'counterparty': _v(x.counterparty), 'deviceName': _v(x.deviceName), 'rewardLockHeight': _v(x.rewardLockHeight), 'deviceEnding': _v(x.deviceEnding), 'deviceWhy': _v(x.deviceWhy), 'transport': _v(x.transport), 'note': _v(x.note), 'label': _v(x.label), 'manualFields': _v(x.manualFields), 'manualEditedAtUnix': _v(x.manualEditedAtUnix), 'messages': _v(x.messages), 'ttlCutoffHeight': _v(x.ttlCutoffHeight), 'cancellable': _v(x.cancellable), 'repostable': _v(x.repostable), 'posting': _v(x.posting), 'undelivered': _v(x.undelivered), 'statusDetail': _v(x.statusDetail), 'releasable': _v(x.releasable), 'finalizedAtUnix': _v(x.finalizedAtUnix), 'cancelReason': _v(x.cancelReason), 'flow': _v(x.flow), 'foundDuring': _v(x.foundDuring), 'datedByBlock': _v(x.datedByBlock), 'senderReportedPostedAtUnix': _v(x.senderReportedPostedAtUnix), 'senderReportedCancelledAtUnix': _v(x.senderReportedCancelledAtUnix), 'receiverDeclinedAtUnix': _v(x.receiverDeclinedAtUnix), 'pairingId': _v(x.pairingId), 'origin': _v(x.origin), 'spentCommits': _v(x.spentCommits), 'unverified': _v(x.unverified)};
Map<String, Object?> _dContact(Contact x) => {'id': _v(x.id), 'name': _v(x.name), 'note': _v(x.note), 'label': _v(x.label), 'epicbox': _v(x.epicbox), 'http': _v(x.http), 'tor': _v(x.tor)};
Map<String, Object?> _dWalletOutput(WalletOutput x) => {'commitment': _v(x.commitment), 'value': _v(x.value), 'status': _v(x.status), 'category': _v(x.category), 'isCoinbase': _v(x.isCoinbase), 'height': _v(x.height), 'lockHeight': _v(x.lockHeight), 'mmrIndex': _v(x.mmrIndex), 'confirmations': _v(x.confirmations), 'txId': _v(x.txId)};
Map<String, Object?> _dWalletSummary(WalletSummary x) => {'lastConfirmedHeight': _v(x.lastConfirmedHeight), 'minimumConfirmations': _v(x.minimumConfirmations), 'total': _v(x.total), 'spendable': _v(x.spendable), 'awaitingConfirmation': _v(x.awaitingConfirmation), 'awaitingFinalization': _v(x.awaitingFinalization), 'immature': _v(x.immature), 'locked': _v(x.locked), 'validatedWithNode': _v(x.validatedWithNode)};
Map<String, Object?> _dPendingInvoice(PendingInvoice x) => {'slateId': _v(x.slateId), 'senderAddress': _v(x.senderAddress), 'pairingId': _v(x.pairingId), 'reference': _v(x.reference), 'amount': _v(x.amount), 'message': _v(x.message), 'receivedAt': _v(x.receivedAt), 'expiresAt': _v(x.expiresAt)};
Map<String, Object?> _dIssuedInvoice(IssuedInvoice x) => {'slateId': _v(x.slateId), 'txId': _v(x.txId), 'payerAddress': _v(x.payerAddress), 'pairingId': _v(x.pairingId), 'amount': _v(x.amount), 'message': _v(x.message), 'issuedAt': _v(x.issuedAt), 'expiresAt': _v(x.expiresAt), 'state': _v(x.state)};
Map<String, Object?> _dPairingRecord(PairingRecord x) => {'id': _v(x.id), 'state': _v(x.state), 'way': _v(x.way), 'inviter': _v(x.inviter), 'createdAt': _v(x.createdAt), 'name': _v(x.name), 'label': _v(x.label), 'kind': _v(x.kind), 'caps': _v(x.caps), 'sas': _v(x.sas), 'verifiedAt': _v(x.verifiedAt), 'allowInvoices': _v(x.allowInvoices), 'seal': _v(x.seal), 'homeRelay': _v(x.homeRelay), 'contactId': _v(x.contactId), 'paymentsAddress': _v(x.paymentsAddress), 'lastSealedIn': _v(x.lastSealedIn), 'expiresAt': _v(x.expiresAt), 'inviteLink': _v(x.inviteLink), 'expectAddress': _v(x.expectAddress), 'peerHeardAt': _v(x.peerHeardAt), 'peerVerifiedAt': _v(x.peerVerifiedAt), 'peerFeatures': _v(x.peerFeatures), 'peerProfile': _v(x.peerProfile), 'endedReason': _v(x.endedReason), 'endedAt': _v(x.endedAt), 'relayDown': _v(x.relayDown), 'notAnswering': _v(x.notAnswering), 'otherDevice': _v(x.otherDevice), 'checksKeys': _v(x.checksKeys), 'requestedRelay': _v(x.requestedRelay), 'peerEncKey': _v(x.peerEncKey), 'peerDomain': _v(x.peerDomain), 'peerDomainAttestation': _v(x.peerDomainAttestation), 'domainStatus': _v(x.domainStatus), 'relayMove': _v(x.relayMove), 'movedAt': _v(x.movedAt)};

Future<Object?> _try(Future<Object?> Function() read) async {
  try {
    return await read();
  } on WalletError catch (e) {
    return {'error': e.kind.name};
  }
}

void main() {
  final lib = _env['WFE_LEPIC_LIB'];
  final desk = _env['WFE_MIG_DESK'];
  final storeFile = _env['WFE_MIG_STORE'];
  final passwordFile = _env['WFE_MIG_PASSWORD'];
  final out = _env['WFE_MIG_OUT'];
  final ready = lib != null && desk != null && storeFile != null && passwordFile != null && out != null;

  test('an existing wallet opens and reads the same', () async {
    await initLepic(libraryPath: lib);
    LepicWalletService.torWantedFor = (_) async => false;
    final secrets = MemorySecretStore(Map<String, String>.from(jsonDecode(File(storeFile!).readAsStringSync()) as Map));
    final registry = jsonDecode(File('$desk/wallets.json').readAsStringSync()) as Map<String, Object?>;
    final entry = (registry['wallets']! as List).cast<Map<String, Object?>>().first;
    final service = LepicWalletService(secrets: secrets, oneWalletPerChain: true, contactsDir: () async => desk!);
    final config = WalletConfig(
      dataDir: '$desk/wallets/mainnet',
      chain: Chain.mainnet,
      nodeUrl: 'https://node.invalid',
      epicboxDomain: 'epicbox.invalid',
      epicboxPort: 443,
      walletId: entry['id']! as String,
      offline: true,
    );
    final dump = <String, Object?>{'walletId': entry['id']};
    final WalletSession s;
    try {
      s = await service.open(config: config, password: File(passwordFile!).readAsStringSync().trim());
    } on WalletError catch (e) {
      dump['error'] = e.kind.name;
      dump['message'] = e.message;
      File(out!).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(dump));
      return;
    }
    try {
      dump['storeOpen'] = _v(s.storeOpen);
      dump['contactsAvailable'] = s.contactsAvailable;
      dump['restoreScanRequired'] = await _try(s.restoreScanRequired);
      dump['fingerprintLength'] = (await s.fingerprint()).length;
      dump['epicboxAddressLength'] = await _try(() async => (await s.epicboxAddress()).length);
      dump['minimumConfirmations'] = await _try(s.minimumConfirmations);
      final minConf = BigInt.from(await s.minimumConfirmations());
      dump['summary'] = await _try(() async => _dWalletSummary(await s.summary(refresh: false, minimumConfirmations: minConf)));
      dump['transactions'] = await _try(() async => [for (final t in await s.transactions(refresh: false)) _dTxEntry(t)]);
      dump['outputs'] = await _try(() async => [for (final o in await s.outputs()) _dWalletOutput(o)]);
      dump['contacts'] = await _try(() async => [for (final c in await s.contacts()) _dContact(c)]);
      dump['favourites'] = await _try(s.favouriteContacts);
      dump['pendingInvoices'] = await _try(() async => [for (final i in await s.pendingInvoices()) _dPendingInvoice(i)]);
      dump['issuedInvoices'] = await _try(() async => [for (final i in await s.issuedInvoices()) _dIssuedInvoice(i)]);
      dump['pairings'] = await _try(() async => [for (final p in await s.pairing.pairings()) _dPairingRecord(p)]);
      dump['privatePairings'] = await _try(() async => [for (final p in await s.pairing.privatePairings()) _dPairingRecord(p)]);
      dump['strays'] = await _try(() async => (await s.pairing.strays()).length);
      dump['requests'] = await _try(() async => (await s.pairing.requests()).length);
      dump['heldOutputs'] = s.heldOutputs.length;
    } finally {
      s.dispose();
    }
    File(out!).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(dump));
  }, skip: ready ? false : 'needs WFE_LEPIC_LIB, WFE_MIG_DESK, WFE_MIG_STORE, WFE_MIG_PASSWORD and WFE_MIG_OUT', timeout: const Timeout(Duration(minutes: 5)));
}
