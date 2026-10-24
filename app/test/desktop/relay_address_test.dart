// EPI-01: after the Epicbox server is switched, the address the desktop shows (Receive, QR,
// copy, the own-address checks) carries the relay now in use, not the one from before.
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the shown Epicbox address follows the relay right after the switch', () async {
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
    addTearDown(container.dispose);
    final desk = container.read(deskProvider.notifier);
    await desk.refresh();
    final key = container.read(deskProvider).epicboxAddress!.split('@').first;
    expect(container.read(deskProvider).epicboxAddress, '$key@epicbox.epiccash.com');

    await desk.useEpicbox('epicbox.stackwallet.com');
    expect(container.read(deskProvider).status?.epicbox.domain, 'epicbox.stackwallet.com');
    expect(container.read(deskProvider).epicboxAddress, '$key@epicbox.stackwallet.com');

    await desk.useEpicbox('epicbox.epiccash.com');
    expect(container.read(deskProvider).epicboxAddress, '$key@epicbox.epiccash.com');
  });

  test('the invoice address follows the relay right after the switch', () async {
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
    addTearDown(container.dispose);
    final desk = container.read(deskProvider.notifier);
    await desk.refresh();
    container.listen(deskInvoicesProvider, (_, _) {});
    final invoices = container.read(deskInvoicesProvider.notifier);
    await invoices.load();
    final key = container.read(deskInvoicesProvider)!.invoiceAddress.split('@').first;
    expect(container.read(deskInvoicesProvider)!.invoiceAddress, '$key@epicbox.epiccash.com');

    await desk.useEpicbox('epicbox.stackwallet.com');
    await pumpEventQueue();
    expect(container.read(deskInvoicesProvider)!.invoiceAddress, '$key@epicbox.stackwallet.com');

    await desk.useEpicbox('epicbox.epiccash.com');
    await pumpEventQueue();
    expect(container.read(deskInvoicesProvider)!.invoiceAddress, '$key@epicbox.epiccash.com');
  });
}
