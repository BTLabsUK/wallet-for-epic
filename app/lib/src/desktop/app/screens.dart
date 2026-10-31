// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';

import '../screens/invoices/issue_invoice_screen.dart';
import '../screens/invoices/invoices_screen.dart';
import '../screens/invoices/review_screen.dart';
import '../screens/onboarding/create_screen.dart';
import '../screens/pairing/pair_screens.dart';
import '../screens/onboarding/import_wallets_screen.dart';
import '../screens/onboarding/reset_password_screen.dart';
import '../screens/onboarding/restore_screen.dart';
import '../screens/onboarding/setup_screen.dart';
import '../screens/onboarding/unlock_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/settings/settings_about.dart';
import '../screens/settings/settings_account.dart';
import '../screens/settings/settings_advanced.dart';
import '../screens/settings/settings_appearance.dart';
import '../screens/settings/settings_devices.dart';
import '../screens/settings/settings_help.dart';
import '../screens/settings/settings_invoices.dart';
import '../screens/settings/settings_level.dart';
import '../screens/settings/settings_node.dart';
import '../screens/settings/settings_phrase.dart';
import '../screens/settings/settings_privacy.dart';
import '../screens/settings/settings_receiving.dart';
import '../screens/settings/settings_rescan.dart';
import '../screens/settings/settings_wallets.dart';
import '../screens/transfer/finalize_screen.dart';
import '../screens/transfer/import_tx_screen.dart';
import '../screens/transfer/receive_screen.dart';
import '../screens/transfer/send_screen.dart';
import '../screens/wallet/activity_screen.dart';
import '../screens/wallet/contacts_screen.dart';
import '../screens/wallet/outputs_screen.dart';
import '../screens/wallet/overview_screen.dart';
import 'routes.dart';

/// The widget of each place. [arg] is the location's argument (initial state, selection).
Widget deskScreen(DeskLocation at) {
  final a = at.arg;
  return switch (at.route) {
    DeskRoute.welcome => WelcomeScreen(arg: a),
    DeskRoute.create => CreateScreen(arg: a),
    DeskRoute.restore => RestoreScreen(arg: a),
    DeskRoute.setup => SetupScreen(arg: a),
    DeskRoute.unlock => UnlockScreen(arg: a),
    DeskRoute.importWallets => ImportWalletsScreen(arg: a),
    DeskRoute.resetPassword => ResetPasswordScreen(arg: a),
    DeskRoute.overview => OverviewScreen(arg: a),
    DeskRoute.activity => ActivityScreen(arg: a),
    DeskRoute.send => SendScreen(arg: a),
    DeskRoute.receive => ReceiveScreen(arg: a),
    DeskRoute.importTx => ImportTxScreen(arg: a),
    DeskRoute.finalize => FinalizeScreen(arg: a),
    DeskRoute.invoices => InvoicesScreen(arg: a),
    DeskRoute.invoiceIssue => IssueInvoiceScreen(arg: a),
    DeskRoute.invoiceReview => InvoiceReviewScreen(arg: a),
    DeskRoute.outputs => OutputsScreen(arg: a),
    DeskRoute.contacts => ContactsScreen(arg: a),
    DeskRoute.pair => DeskPairScreen(arg: a),
    DeskRoute.pairPending => DeskPendingScreen(arg: a),
    DeskRoute.settingsNode => SettingsNodeScreen(arg: a),
    DeskRoute.settingsReceiving => SettingsReceivingScreen(arg: a),
    DeskRoute.settingsPrivacy => SettingsPrivacyScreen(arg: a),
    DeskRoute.settingsInvoices => SettingsInvoicesScreen(arg: a),
    DeskRoute.settingsAppearance => SettingsAppearanceScreen(arg: a),
    DeskRoute.settingsAccount => SettingsAccountScreen(arg: a),
    DeskRoute.settingsDevices => SettingsDevicesScreen(arg: a),
    DeskRoute.settingsWallets => SettingsWalletsScreen(arg: a),
    DeskRoute.settingsPhrase => SettingsPhraseScreen(arg: a),
    DeskRoute.settingsRescan => SettingsRescanScreen(arg: a),
    DeskRoute.settingsAdvanced => SettingsAdvancedScreen(arg: a),
    DeskRoute.settingsLevel => SettingsLevelScreen(arg: a),
    DeskRoute.settingsAbout => SettingsAboutScreen(arg: a),
    DeskRoute.settingsHelp => SettingsHelpScreen(arg: a),
  };
}
