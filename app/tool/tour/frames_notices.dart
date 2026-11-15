// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Notice-*. Add `('fr-<Frame>', _Start.home, visit)` entries to the list and,
// when a frame needs its own data, a seed to `_noticesSeeds`. See tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

/// The arrival toast of Notice-2 and -3: two lines and a View button.
void _arrivalToast(_Tour t) {
  ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first)).read(noticeProvider.notifier).show(
    'On its way to you',
    title: '+12.5 EPIC from Bob',
    level: NoticeLevel.success,
    icon: KitIcons.receive,
    action: NoticeAction(t.l.homeNoticeView, () {}),
  );
}

final List<(String, _Start, _Visit)> _framesNotices = [
  (
    'fr-Notice-1-Announcement',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.shot('fr-Notice-1-Announcement');
    },
  ),
  (
    'fr-Notice-2-Toast-Home',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      _arrivalToast(t);
      await t.frames();
      await t.shot('fr-Notice-2-Toast-Home');
    },
  ),
  (
    'fr-Notice-3-Toast-Flow',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      // The frame's flow: Send-2's amount step (12.5 to Tom, the Tickets note) under the toast.
      await _sendToTom(t);
      _arrivalToast(t);
      await t.frames();
      await t.shot('fr-Notice-3-Toast-Flow');
    },
  ),
  (
    'fr-Notice-4-Slot',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.push(_noticeBoard(t, [
        KitNeedsYouCard(
          title: 'Invoice from Northwind',
          subtitle: '42.5 EPIC. Nothing is paid until you approve.',
          reviewLabel: 'Review',
          laterLabel: 'Later',
          onReview: () {},
          onLater: () {},
        ),
        KitSlotCard(
          title: 'Back up your recovery phrase',
          subtitle: 'Without it, a lost phone means a lost wallet.',
          icon: KitIcons.security,
          action: 'Back up now',
          onTap: () {},
        ),
      ]));
      await t.shot('fr-Notice-4-Slot');
    },
  ),
  (
    'fr-Notice-5-Toasts',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      Widget card(int id, String text, NoticeLevel level, {String? title, IconData? icon, String? action, bool persistent = false, double? progress}) =>
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: NoticeCard(
              key: ValueKey(id),
              notice: Notice(
                id,
                text,
                level: level,
                title: title,
                icon: icon,
                persistent: persistent,
                progress: progress,
                action: action == null ? null : NoticeAction(action, () {}),
              ),
            ),
          );
      await t.push(_noticeBoard(t, [
        card(1, 'On its way to you', NoticeLevel.success, title: '+12.5 EPIC from Bob', icon: KitIcons.receive, action: t.l.homeNoticeView),
        card(2, 'Address copied', NoticeLevel.success),
        card(3, 'Downloading version 26.11.4', NoticeLevel.info, icon: KitIcons.download, persistent: true, progress: 0.58),
        card(4, 'Version 26.11.4 is ready', NoticeLevel.info, icon: KitIcons.download, persistent: true, action: 'Install'),
        card(5, 'The coins are back in your balance', NoticeLevel.warning, title: 'Payment to Tom expired', icon: KitIcons.clock, action: t.l.homeNoticeView),
        card(6, 'Could not reach the node', NoticeLevel.error, action: 'Try again'),
      ]));
      await t.shot('fr-Notice-5-Toasts');
    },
  ),
];

/// The design boards of Notice-4 and -5 are 860 wide with captions; the pieces they show, stacked at phone width.
Widget _noticeBoard(_Tour t, List<Widget> children) => Scaffold(
  body: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [const SizedBox(height: 12), ...children])),
);

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _noticesSeeds = {
  'fr-Notice-1-Announcement': _noticeInvoice,
};

/// Home with the one thing waiting for the person: the invoice from Northwind.
void _noticeInvoice(FakeWalletSession s) {
  s.pairing.seedPaired(
    id: 'p-northwind',
    name: 'Northwind Exchange',
    contactId: 'f-nw',
    peerProfile: 2,
    allowInvoices: true,
    paymentsAddress: _fNorthwind,
  );
  s.pendingInvoicesValue['inv-1042'] = PendingInvoice(
    slateId: 'inv-1042',
    senderAddress: _fNorthwind,
    pairingId: 'p-northwind',
    amount: _epic(42.5),
    receivedAt: frameNow.subtract(const Duration(minutes: 20)),
    expiresAt: frameNow.add(const Duration(hours: 23)),
  );
}
