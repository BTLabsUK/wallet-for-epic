// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_places.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/help/help_i18n.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every `[[place]]` in Help goes to a screen that exists, on the phone and on the desktop, in all
/// six languages; a translated place says what that language's UI says and goes to the English
/// place; and the English text writes no place in plain words that a link could name.
void main() {
  final languages = [for (final a in appLanguages) a.code];

  /// Every place of [topics] as (topic id, label, target).
  List<({String id, String label, String target})> placesOf(List<HelpTopic> topics) => [
    for (final t in topics)
      for (final b in t.body)
        for (final line in b.kind == HelpBlockKind.p ? [b.text] : b.items)
          for (final p in helpInline(line))
            if (p.place) (id: t.id, label: p.text, target: p.target),
  ];

  /// All of Help for [lang]: the topics (with and without Tor) and the pairing topics.
  List<HelpTopic> topicsOf(String lang, HelpPlatform platform, {bool tor = true}) => [
    ...localizedHelpTopics(lang, 3, platform: platform, tor: tor),
    ...pairingHelpTopics(helpStrings(lang), platform: platform),
  ];

  /// What each part of an English place is called in the UI, in the language of [l]. A part may be
  /// called differently on the phone and the desktop; the label must be one of them.
  Map<String, Set<String>> uiNames(AppLocalizations l) => {
    'Settings': {l.settingsTitle, l.deskShellNavSettings},
    'Security': {l.settingsSectionSecurity},
    'Back up recovery phrase': {l.settingsBackupPhrase},
    'Network & privacy': {l.settingsSectionNetworkPrivacy},
    'Tor network': {l.torNetworkLabel},
    'Wallet': {l.settingsSectionWallet, l.deskSetSecWallet},
    'Wallets': {l.deskSetSecWallets},
    'Payments': {l.deskSetSecPayments},
    'Files & logs': {l.deskSetSecFiles},
    'Confirmations': {l.deskSetAdvConfirmations},
    'Transactions': {l.settingsSectionTransactions, l.deskSetFrameTransactions},
    'Export wallet data': {l.settingsExportHistory, l.deskSetBackupExportTitle},
    'Recheck balance': {l.settingsRescan, l.deskSetFrameRescan},
    'Node': {l.deskSetFrameNode, l.serverNodeTitle},
    'Epicbox': {l.serverEpicboxTitle},
    'Privacy': {l.deskSetFramePrivacy},
    'Tor': {l.deskSetPrivTor},
    'This wallet': {l.deskSetFrameThisWallet},
    'Wallet folder': {l.deskSetAcctWalletFolder},
    'App files': {l.deskSetAcctAppFiles},
    'All wallets': {l.deskSetFrameAllWallets},
    'Recovery phrase': {l.deskSetFramePhrase},
    'Receive': {l.homeReceiveButton, l.deskShellNavReceive},
    'Send': {l.homeSendButton, l.deskShellNavSend},
    'Activity': {l.homeDestActivity, l.deskShellNavActivity},
    'Outputs': {l.outputsTitle, l.deskShellNavOutputs},
    'Manage outputs': {l.outputsAdvanced, l.deskOutAdvanced},
    'Direct · File': {l.methodShortFile},
    'Direct · QR': {l.methodShortQr},
    'Transaction files': {l.deskRecvFiles},
    'Sign a transaction file': {l.deskRecvSignTitle},
    'Finalize a response file': {l.deskRecvFinalizeTitle},
    'Contacts': {l.settingsContacts, l.deskShellNavContacts},
    'Invoices': {l.invoicesTitle, l.deskInvNav, l.deskInvSetTitle},
    'Linked devices': {l.expLinkedDevices, l.deskSetSecDevices},
    'To pay': {l.invoicesToPaySection},
    'Pay': {l.deskInvTabPay},
    'Issue': {l.deskInvTabIssue},
    // The transaction's own words in Activity: not a screen's name.
    'the transaction': {},
    'Cancel': {},
  };

  group('the pure resolvers', () {
    test('phone: Settings places open the page that holds them', () {
      expect(helpPlaceDestination('Settings › Security'), HelpPhonePlace.security);
      expect(helpPlaceDestination('Settings › Security › Back up recovery phrase'), HelpPhonePlace.security);
      expect(helpPlaceDestination('Settings › Network & privacy › Tor network'), HelpPhonePlace.privacyNetwork);
      expect(helpPlaceDestination('Settings › This wallet › Recheck balance'), HelpPhonePlace.wallet);
      expect(helpPlaceDestination('Settings › This wallet › Linked devices'), HelpPhonePlace.linkedDevices);
      expect(helpPlaceDestination('Settings › Appearance'), HelpPhonePlace.display);
      expect(helpPlaceDestination('Settings › About'), HelpPhonePlace.about);
      expect(helpPlaceDestination('Settings'), HelpPhonePlace.settings);
      expect(helpPlaceDestination('Outputs › Manage outputs'), HelpPhonePlace.outputs);
      expect(helpPlaceDestination('Invoices › To pay'), HelpPhonePlace.invoices);
    });

    test('phone: a place the phone does not have is no link', () {
      for (final place in [
        'Settings › Recovery phrase',
        'Settings › Node',
        'Settings › Security › Nothing',
        'Settings › Network & privacy › Tor › More',
        'Settings › Privacy & network',
        'Receive › Transaction files › Sign a transaction file',
        'Restore from a recovery phrase',
        'Empfangen',
        '',
      ]) {
        expect(helpPlaceDestination(place), isNull, reason: place);
      }
    });

    test('desktop: each place has its page, and a jump where it names a section', () {
      expect(deskHelpPlace('Settings › Security › Recovery phrase')!.route, DeskRoute.settingsPhrase);
      expect(deskHelpPlace('Settings › Security')!.route, DeskRoute.settingsSecurity);
      expect(deskHelpPlace('Settings › Wallet › Recheck balance')!.route, DeskRoute.settingsRescan);
      expect(deskHelpPlace('Settings › Wallets')!.route, DeskRoute.settingsWallets);
      expect(deskHelpPlace('Settings › Payments')!.route, DeskRoute.settingsReceiving);
      expect(deskHelpPlace('Settings › Files & logs › App files')!.route, DeskRoute.settingsFiles);
      expect(deskHelpPlace('Settings › Linked devices')!.route, DeskRoute.settingsDevices);
      expect(deskHelpPlace('Settings › Network & privacy › Tor')!.route, DeskRoute.settingsPrivacy);
      expect(deskHelpPlace('Settings › Network & privacy › Tor')!.jump, SettingsJump.tor);
      expect(deskHelpPlace('Settings › Network & privacy')!.jump, SettingsJump.network);
      expect(deskHelpPlace('Settings › Privacy › Tor'), isNull, reason: 'one page now (B-03)');
      expect(deskHelpPlace('Settings › Payments › Epicbox')!.jump, SettingsJump.epicbox);
      // The places of the Settings before 26.10.25 are gone: Help names the new ones.
      for (final old in ['Settings › Transactions', 'Settings › This wallet', 'Settings › All wallets', 'Settings › Recheck balance', 'Settings › This wallet › App files', 'Settings › Advanced › Confirmations']) {
        expect(deskHelpPlace(old), isNull, reason: old);
      }
      expect(deskHelpPlace('Receive › Transaction files › Finalize a response file')!.route, DeskRoute.finalize);
      expect(deskHelpPlace('Invoices › Issue')!.arg, InvoicesTab.issue);
      expect(deskHelpPlace('Settings › Security › Back up recovery phrase'), isNull);
    });

    testWidgets('phone: a Settings place opens its page, not the hub', (tester) async {
      late BuildContext context;
      // The pages read providers; the route only has to be pushed, so look at what was pushed.
      final pushed = <Route<dynamic>>[];
      final observer = _Observer(pushed);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      pushed.clear();
      openHelpPlace(context, 'Settings › Security › Back up recovery phrase');
      expect(pushed, hasLength(1));
      final page = (pushed.single as MaterialPageRoute<dynamic>).builder(context);
      expect(page, isA<SettingsSectionScreen>());
      expect((page as SettingsSectionScreen).section, SettingsSection.security);
    });
  });

  for (final platform in HelpPlatform.values) {
    final phone = platform == HelpPlatform.phone;
    final english = {for (final tor in [true, false]) tor: topicsOf('en', platform, tor: tor)};

    test('${platform.name}: English writes no place in plain words', () {
      for (final tor in [true, false]) {
        for (final t in english[tor]!) {
          for (final b in t.body) {
            for (final line in b.kind == HelpBlockKind.p ? [b.text] : b.items) {
              final plain = helpInline(line).where((p) => !p.place).map((p) => p.text).join();
              expect(plain, isNot(contains('Settings ›')), reason: '${t.id}: $line');
              expect(plain, isNot(contains('Outputs ›')), reason: '${t.id}: $line');
              expect(plain, isNot(contains('Activity ›')), reason: '${t.id}: $line');
            }
          }
        }
      }
    });

    for (final lang in languages) {
      for (final tor in [true, false]) {
        test('$lang ${platform.name} tor:$tor: every place goes to a screen', () {
          final l = helpStrings(lang);
          final names = uiNames(l);
          final topics = topicsOf(lang, platform, tor: tor);
          final places = placesOf(topics);
          expect(places, isNotEmpty);
          for (final p in places) {
            final where = '${p.id}: ${p.label} → ${p.target}';
            // 1. The place exists.
            if (phone) {
              expect(helpPlaceDestination(p.target), isNotNull, reason: where);
            } else {
              expect(deskHelpPlace(p.target), isNotNull, reason: where);
            }
            // 2. The label has the target's parts, each as that language's UI calls it.
            final targetParts = p.target.split(' › ');
            final labelParts = p.label.split(' › ');
            expect(labelParts, hasLength(targetParts.length), reason: where);
            for (final (i, part) in targetParts.indexed) {
              final known = names[part];
              expect(known, isNotNull, reason: '$where: no UI name known for "$part"');
              if (known!.isEmpty) continue;
              expect(known, contains(labelParts[i]), reason: '$where: "${labelParts[i]}" is not the UI name of "$part"');
            }
            if (lang == 'en') expect(p.label, p.target, reason: where);
          }
        });
      }

      if (lang != 'en') {
        test('$lang ${platform.name}: the same places as English, topic by topic', () {
          for (final tor in [true, false]) {
            final topics = topicsOf(lang, platform, tor: tor);
            final en = english[tor]!;
            expect([for (final t in topics) t.id], [for (final t in en) t.id]);
            for (final (i, t) in topics.indexed) {
              expect(
                [for (final p in placesOf([t])) p.target],
                [for (final p in placesOf([en[i]])) p.target],
                reason: '$lang ${t.id}',
              );
            }
          }
        });
      }
    }
  }

  test('the restore line names the first screen as the UI does', () {
    for (final lang in languages) {
      final l = helpStrings(lang);
      final phone = localizedHelpTopics(lang, 3, platform: HelpPlatform.phone).firstWhere((t) => t.id == HelpId.backup);
      final desktop = localizedHelpTopics(lang, 3, platform: HelpPlatform.desktop).firstWhere((t) => t.id == HelpId.backup);
      expect(phone.bodyText, contains(l.firstRunRestore), reason: lang);
      expect(desktop.bodyText, contains(l.deskOnbWelcomeRestore), reason: lang);
    }
  });
}

class _Observer extends NavigatorObserver {
  _Observer(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushed.add(route);
}
