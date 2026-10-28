// SPDX-License-Identifier: Apache-2.0
// The outputs list follows the open wallet: another wallet or a moved balance reads it again,
// so SmartOutputs on Send never counts a list from before (review of fb/w5, item 3).
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  String id = 'a';
  int reads = 0;

  @override
  Future<WalletAccount> account() async =>
      WalletAccount(id: id, name: id, network: 'mainnet', folder: '/w/$id', created: DateTime(2024));

  @override
  Future<List<Output>> outputs() async {
    reads++;
    final all = await super.outputs();
    // Wallet b holds one output fewer, so the two lists differ.
    return id == 'a' ? all : all.skip(1).toList();
  }
}

void main() {
  test('another wallet and a new balance read the outputs again', () async {
    final wallet = _Wallet();
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
    addTearDown(container.dispose);
    // Keep the provider alive as Send and the Outputs page do.
    final sub = container.listen(deskOutputsProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(deskProvider.notifier).refresh();
    final first = await container.read(deskOutputsProvider.future);
    final reads = wallet.reads;

    wallet.id = 'b';
    await container.read(deskProvider.notifier).refresh();
    final second = await container.read(deskOutputsProvider.future);
    expect(wallet.reads, greaterThan(reads), reason: 'another wallet opened');
    expect(second.length, first.length - 1);

    final before = wallet.reads;
    await container.read(deskProvider.notifier).refresh(); // a new balance, same wallet
    await container.read(deskOutputsProvider.future);
    expect(wallet.reads, greaterThan(before), reason: 'the balance moved');
  });
}
