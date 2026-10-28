// SPDX-License-Identifier: Apache-2.0
// Live: how soon each side of a payment sees it move (watch mode, watch_mode.dart), on the real
// LEPIC core through LepicDeskWallet against floonet. Run as two processes side by side, one
// per wallet, which meet through files in WFE_PACE_DIR:
//
//   WFE_DEMO_LEPIC_LIB=<liblepic_ffi.so> WFE_PACE_DIR=<dir> WFE_PACE_ROLE=receiver \
//     WFE_PACE_HOME=<home>/.epic_cash_desktop WFE_PACE_PASSWORD=<pw> WFE_PACE_NODE=<url> \
//     WFE_PACE_SECRETS=<the wallet's secrets as a JSON file> \
//     [WFE_PACE_WATCH=off] flutter test test/desktop/confirm_pace_live_test.dart
//   ... the same with WFE_PACE_ROLE=sender WFE_PACE_METHOD=epicbox|file in a second shell.
//
// Each side writes `<role>.log`: one line per change of the payment as the app shows it (ms,
// state, confirmations). WFE_PACE_WATCH=off asks the node at the normal pace only, as before
// watch mode. Without the library it is skipped.
import 'dart:io';

import 'package:epic_wallet/src/demo_server/file_secret_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:flutter_test/flutter_test.dart';

final _env = Platform.environment;
final String? _lib = _env['WFE_DEMO_LEPIC_LIB'];

void main() {
  setUpAll(() async {
    if (_lib != null) await initLepic(libraryPath: _lib);
  });

  test('a payment moves on both sides within moments of its block', () async {
    final dir = Directory(_env['WFE_PACE_DIR']!);
    final role = _env['WFE_PACE_ROLE']!;
    final home = _env['WFE_PACE_HOME']!;
    final method = _env['WFE_PACE_METHOD'] ?? 'epicbox';
    final watch = _env['WFE_PACE_WATCH'] != 'off';
    final log = File('${dir.path}/$role.log').openWrite(mode: FileMode.append);
    void note(String s) {
      final line = '${DateTime.now().millisecondsSinceEpoch} $s';
      log.writeln(line);
      // ignore: avoid_print
      print('$role $line');
    }

    // The wallet's secrets (its LEPIC vault), kept in a file between runs.
    final secrets = FileSecretStore(_env['WFE_PACE_SECRETS'] ?? '${dir.path}/$role-secrets.json');
    await secrets.write('app.node.floonet', _env['WFE_PACE_NODE']!);
    await secrets.delete('desk.serverList.node.floonet');
    final files = Directory('${dir.path}/$role-files')..createSync(recursive: true);
    final wallet = LepicDeskWallet(
      preset: floonetPreset,
      service: LepicWalletService(secrets: secrets, oneWalletPerChain: true),
      walletDir: (chain) async => '$home/wallets/${chain.name}',
      secrets: secrets,
      filesDir: () async => files,
      watchPoll: watch ? const Duration(seconds: 4) : const Duration(seconds: 30),
      rememberDir: () async => Directory('${dir.path}/$role-remember'),
      listProcesses: () async => const [],
      invoiceFocus: false,
    );
    // A receiver needs no funds: a fresh wallet when the home has none.
    if (!File('$home/wallets.json').existsSync()) {
      await wallet.createWallet(name: role, password: _env['WFE_PACE_PASSWORD']!);
    }
    expect(await wallet.unlock(_env['WFE_PACE_PASSWORD']!), isTrue);
    await wallet.syncNow();
    final b = await wallet.balance();
    note('balance spendable=${b.spendable} waiting=${b.awaitingConfirmation} locked=${b.locked}');
    note('open watch=${watch ? 'on' : 'off'} method=$method');
    if (method == 'epicbox') await wallet.setListening(true);

    Future<File> waitFor(String name) async {
      final f = File('${dir.path}/$name');
      while (!f.existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return f;
    }

    String? slate;
    if (role == 'receiver') {
      await File('${dir.path}/address').writeAsString(await wallet.epicboxAddress());
      if (method == 'file') {
        final s1 = await waitFor('s1');
        final got = await wallet.receiveFile(await s1.readAsString());
        slate = got.tx.slateId;
        await File('${dir.path}/s2').writeAsString(got.response);
        note('answered');
      } else {
        slate = (await (await waitFor('slate')).readAsString()).trim();
      }
    } else {
      final to = (await (await waitFor('address')).readAsString()).trim();
      final amount = int.parse(_env['WFE_PACE_AMOUNT'] ?? '1000000');
      final r = await wallet.send(
        SendRequest(method: method == 'file' ? TxMethod.file : TxMethod.epicbox, amount: amount, to: method == 'file' ? null : to),
      );
      switch (r) {
        case SendDone(:final tx):
          slate = tx.slateId;
          await File('${dir.path}/slate').writeAsString(slate);
        case SendFileReady(:final tx, :final fileName):
          slate = tx.slateId;
          await File('${dir.path}/s1').writeAsString(fileName);
          final s2 = await waitFor('s2');
          await wallet.finalizeFile(await s2.readAsString());
          note('finalized');
        default:
          fail('unexpected send result ${r is SendFailed ? r.message : r}');
      }
      note('sent $slate');
    }

    // Follow the payment as the app shows it until it is confirmed.
    String? last;
    final until = DateTime.now().add(Duration(minutes: int.parse(_env['WFE_PACE_MINUTES'] ?? '25')));
    while (DateTime.now().isBefore(until)) {
      final tx = (await wallet.transactions()).where((t) => t.slateId == slate).firstOrNull;
      final now = tx == null ? 'none' : '${tx.state.name} ${tx.confirmations}/${tx.confirmationsNeeded} wait=${tx.blockWait.name}${tx.notPosted ? ' notPosted' : ''}';
      if (now != last) note(now);
      last = now;
      if (tx?.state == TxState.confirmed && _env['WFE_PACE_STAY'] == null) break;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    note('end');
    await log.close();
    await wallet.dispose();
  }, skip: _lib == null ? 'needs WFE_DEMO_LEPIC_LIB' : false, timeout: const Timeout(Duration(minutes: 40)));
}
