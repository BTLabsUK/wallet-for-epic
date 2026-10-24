import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('pl'),
    Locale('ru'),
    Locale('th'),
    Locale('zh'),
  ];

  /// The phone app's product name, in the task switcher and window title. A brand name; do not translate.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash Mobile'**
  String get appTitle;

  /// The desktop app's product name (Windows, Linux). A brand name; do not translate.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash Desktop'**
  String get appTitleDesktop;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Said by a screen reader before the text of an info notice, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get noticeLevelInfo;

  /// Said by a screen reader before the text of a success notice, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get noticeLevelSuccess;

  /// Said by a screen reader before the text of a warning notice, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get noticeLevelWarning;

  /// Said by a screen reader before the text of an error notice, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get noticeLevelError;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Screen-reader label of the icon in front of an error message.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get commonPaste;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Shown where a value (network, relay, version) is not known.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// Tooltip on the copy button of a box holding a transaction's text (an Epic Cash slate, JSON) that the user passes to the other side.
  ///
  /// In en, this message translates to:
  /// **'Copy transaction text'**
  String get slateCopyTooltip;

  /// No description provided for @slateCopied.
  ///
  /// In en, this message translates to:
  /// **'Transaction text copied'**
  String get slateCopied;

  /// Heading of the payment file screen when the payment came as pasted text, where a file name would be.
  ///
  /// In en, this message translates to:
  /// **'Pasted payment'**
  String get slatePastedTitle;

  /// Button that copies the signed reply's text, after a pasted payment was accepted.
  ///
  /// In en, this message translates to:
  /// **'Copy reply'**
  String get slateCopyReply;

  /// Title of the system fingerprint/face prompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock wallet'**
  String get biometricPromptTitle;

  /// No description provided for @biometricPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your fingerprint or face'**
  String get biometricPromptSubtitle;

  /// Button in the system biometric prompt that falls back to the 6-digit PIN.
  ///
  /// In en, this message translates to:
  /// **'Use PIN'**
  String get biometricPromptUsePin;

  /// Amount field error. Write the example number with this language's decimal separator.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount such as 1.5'**
  String get amountEnterExample;

  /// Amount field error: EPIC has 8 decimal places.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{At most 1 decimal place} other{At most {count} decimal places}}'**
  String amountTooManyDecimals(int count);

  /// A date or day word followed by a clock time, e.g. '21 Sep 2026, 14:05' or 'Today, 14:05'.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dateWithTime(String date, String time);

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// A payment created by mining a block (coinbase).
  ///
  /// In en, this message translates to:
  /// **'Mining reward'**
  String get txMiningReward;

  /// Funds the wallet found by scanning the chain after a restore, with no record of who sent them.
  ///
  /// In en, this message translates to:
  /// **'Restored funds'**
  String get txRestoredFunds;

  /// Screen-reader sentence of a payment row the user labelled: the label first, then the whole row sentence (what happened, status, date).
  ///
  /// In en, this message translates to:
  /// **'{label}, {row}'**
  String txSpokenLabelled(String label, String row);

  /// Phone: title of the label tile on a payment with a label, and the field name in the history import dialog. A name the user gave the payment.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get txLabel;

  /// Phone: the tile and the pen button on a payment without a label (screen readers say it for the pen).
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get txLabelAdd;

  /// Phone: the pen button on a payment with a label (screen readers say it).
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get txLabelEdit;

  /// Phone: placeholder of the one-line label field that opens in place.
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get txLabelHint;

  /// Notice after a label was added to a payment.
  ///
  /// In en, this message translates to:
  /// **'Label added'**
  String get txLabelAddedNotice;

  /// Notice after a label was changed.
  ///
  /// In en, this message translates to:
  /// **'Label saved'**
  String get txLabelSavedNotice;

  /// Notice after a label was emptied and removed.
  ///
  /// In en, this message translates to:
  /// **'Label removed'**
  String get txLabelRemovedNotice;

  /// Phone: tile and sheet title on a payment found by a scan that has no details of the user yet (sender, method, note).
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get txEditAdd;

  /// Phone: tile and sheet title on a payment found by a scan whose details the user already entered.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get txEditEdit;

  /// Field of the details sheet and its tile: who paid, typed by the user. Also the field name in the history import dialog.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get txEditFrom;

  /// Placeholder of the From field: an address the user typed or picked from contacts.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get txEditFromHint;

  /// Helper under the From field. Short.
  ///
  /// In en, this message translates to:
  /// **'Not verified. Never used for payment proofs.'**
  String get txEditFromHelper;

  /// Method choice in the details sheet: how the payment came is not known.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get txMethodUnknown;

  /// Small tag after a value the user typed, not read from the chain or made by the wallet.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get txManualTag;

  /// Tooltip of the tag; date is the day and time the user entered it.
  ///
  /// In en, this message translates to:
  /// **'Added by you on {date}. Not from the chain.'**
  String txManualTip(String date);

  /// Tooltip of the tag when the time is not known.
  ///
  /// In en, this message translates to:
  /// **'Added by you. Not from the chain.'**
  String get txManualTipNoDate;

  /// Tooltip of the tag on the From value; the sender was typed by the user and is not checked.
  ///
  /// In en, this message translates to:
  /// **'Added by you on {date}. Not from the chain, not verified.'**
  String txManualTipFrom(String date);

  /// Tooltip of the tag on the From value when the time is not known.
  ///
  /// In en, this message translates to:
  /// **'Added by you. Not from the chain, not verified.'**
  String get txManualTipFromNoDate;

  /// Notice after details were added to a payment found by a scan.
  ///
  /// In en, this message translates to:
  /// **'Details added'**
  String get txEditAddedNotice;

  /// Notice after details were changed.
  ///
  /// In en, this message translates to:
  /// **'Details saved'**
  String get txEditSavedNotice;

  /// Notice after every detail was emptied.
  ///
  /// In en, this message translates to:
  /// **'Details removed'**
  String get txEditRemovedNotice;

  /// Title of the sheet shown when a history backup has other values than the ones the user entered.
  ///
  /// In en, this message translates to:
  /// **'Details differ'**
  String get histConflictTitle;

  /// Lead of the Details differ sheet; n is the number of payments. The user picks per value, Mine is chosen at first.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{The backup has other details for 1 payment you described. Yours are kept unless you choose otherwise.} other{The backup has other details for {n} payments you described. Yours are kept unless you choose otherwise.}}'**
  String histConflictLead(int n);

  /// Choice card: the value entered on this phone.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get histConflictMine;

  /// Choice card: the value in the backup file.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get histConflictBackup;

  /// Button: import without replacing anything the user entered.
  ///
  /// In en, this message translates to:
  /// **'Keep all mine'**
  String get histConflictKeepAll;

  /// Button: import with the choices made.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get histConflictImport;

  /// Shown in italics on a card whose value is empty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get histConflictEmpty;

  /// Line after an import in which the user chose the backup for some values; n is how many.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 detail replaced, the rest kept as yours.} other{{n} details replaced, the rest kept as yours.}}'**
  String histImportedReplaced(int n);

  /// No description provided for @txOutgoingPayment.
  ///
  /// In en, this message translates to:
  /// **'Outgoing payment'**
  String get txOutgoingPayment;

  /// No description provided for @txIncomingPayment.
  ///
  /// In en, this message translates to:
  /// **'Incoming payment'**
  String get txIncomingPayment;

  /// Status chip: the payment was sent, the recipient has not answered yet. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Waiting for recipient'**
  String get txStatusWaitingRecipient;

  /// Status chip: we answered a payment, the sender has not finished it yet. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender'**
  String get txStatusWaitingSender;

  /// Status chip: the payment is on the chain with count of target confirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirming {count}/{target}'**
  String txStatusConfirming(int count, int target);

  /// Status chip of a finished payment.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get txStatusCompleted;

  /// Status chip of a cancelled payment.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get txStatusCancelled;

  /// Status chip of a pending payment imported from a history backup, which this wallet cannot follow up.
  ///
  /// In en, this message translates to:
  /// **'From backup, status unknown'**
  String get txStatusFromBackup;

  /// Screen-reader label of a cancelled payment's icon.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get txIconCancelled;

  /// Screen-reader label of an incoming payment's icon.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get txIconIncoming;

  /// Screen-reader label of an outgoing payment's icon.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get txIconOutgoing;

  /// Read by the screen reader in place of the amount when balances are hidden; goes into the {amount} of the txSpoken messages.
  ///
  /// In en, this message translates to:
  /// **'a hidden amount'**
  String get txSpokenHiddenAmount;

  /// Screen-reader text of a payment row.
  ///
  /// In en, this message translates to:
  /// **'Mining reward of {amount}'**
  String txSpokenMiningReward(String amount);

  /// Screen-reader text of a payment row.
  ///
  /// In en, this message translates to:
  /// **'Restored funds of {amount}'**
  String txSpokenRestoredFunds(String amount);

  /// Screen-reader text of a payment row.
  ///
  /// In en, this message translates to:
  /// **'Cancelled send of {amount}'**
  String txSpokenCancelledSend(String amount);

  /// Screen-reader text of a payment row. who is a contact name or a short address.
  ///
  /// In en, this message translates to:
  /// **'Cancelled send of {amount} to {who}'**
  String txSpokenCancelledSendTo(String amount, String who);

  /// Screen-reader text of a payment row.
  ///
  /// In en, this message translates to:
  /// **'Cancelled receive of {amount}'**
  String txSpokenCancelledReceive(String amount);

  /// Screen-reader text of a payment row.
  ///
  /// In en, this message translates to:
  /// **'Cancelled receive of {amount} from {who}'**
  String txSpokenCancelledReceiveFrom(String amount, String who);

  /// Screen-reader text of a pending outgoing payment row.
  ///
  /// In en, this message translates to:
  /// **'Sending {amount}'**
  String txSpokenSending(String amount);

  /// Screen-reader text of a pending outgoing payment row.
  ///
  /// In en, this message translates to:
  /// **'Sending {amount} to {who}'**
  String txSpokenSendingTo(String amount, String who);

  /// Screen-reader text of a pending incoming payment row.
  ///
  /// In en, this message translates to:
  /// **'Receiving {amount}'**
  String txSpokenReceiving(String amount);

  /// Screen-reader text of a pending incoming payment row.
  ///
  /// In en, this message translates to:
  /// **'Receiving {amount} from {who}'**
  String txSpokenReceivingFrom(String amount, String who);

  /// Screen-reader text of a finished outgoing payment row.
  ///
  /// In en, this message translates to:
  /// **'Sent {amount}'**
  String txSpokenSent(String amount);

  /// Screen-reader text of a finished outgoing payment row.
  ///
  /// In en, this message translates to:
  /// **'Sent {amount} to {who}'**
  String txSpokenSentTo(String amount, String who);

  /// Screen-reader text of a finished incoming payment row.
  ///
  /// In en, this message translates to:
  /// **'Received {amount}'**
  String txSpokenReceived(String amount);

  /// Screen-reader text of a finished incoming payment row.
  ///
  /// In en, this message translates to:
  /// **'Received {amount} from {who}'**
  String txSpokenReceivedFrom(String amount, String who);

  /// Whole screen-reader sentence for a payment row: what happened, its status word, its date.
  ///
  /// In en, this message translates to:
  /// **'{what}, {status}, {date}'**
  String txSpokenRow(String what, String status, String date);

  /// No description provided for @errorInvalidMnemonic.
  ///
  /// In en, this message translates to:
  /// **'The recovery phrase is not valid. Check each word and the word order.'**
  String get errorInvalidMnemonic;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get errorWrongPassword;

  /// No description provided for @errorWalletAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A wallet already exists for this network.'**
  String get errorWalletAlreadyExists;

  /// No description provided for @errorWalletNotFound.
  ///
  /// In en, this message translates to:
  /// **'No wallet found for this network.'**
  String get errorWalletNotFound;

  /// The node is the Epic Cash server the wallet reads the chain from.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the node. Check the node URL and your connection.'**
  String get errorNodeUnreachable;

  /// No description provided for @errorNotEnoughFunds.
  ///
  /// In en, this message translates to:
  /// **'Not enough spendable funds for this amount plus the fee.'**
  String get errorNotEnoughFunds;

  /// No description provided for @errorInvalidSlate.
  ///
  /// In en, this message translates to:
  /// **'This transaction text is not valid for this step. Check that you pasted all of it.'**
  String get errorInvalidSlate;

  /// Summary in front of a technical detail the wallet core wrote in English.
  ///
  /// In en, this message translates to:
  /// **'Invalid input.'**
  String get errorInvalidInput;

  /// Summary in front of a technical detail in English.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the recipient.'**
  String get errorTransportFailed;

  /// A payment over Tor could not start because tor is not running or did not connect. Shown alone, without the core's detail.
  ///
  /// In en, this message translates to:
  /// **'Tor is not connected.'**
  String get errorTorNotRunning;

  /// A payment over Tor did not reach the recipient's wallet at its Tor address. Same words as the start of sendTorNotReached.
  ///
  /// In en, this message translates to:
  /// **'Their wallet was not reached over Tor.'**
  String get errorOnionUnreachable;

  /// No description provided for @errorChainBusy.
  ///
  /// In en, this message translates to:
  /// **'The wallet is still busy on the other network. Wait a moment and try again, or close and reopen the app.'**
  String get errorChainBusy;

  /// No description provided for @errorWalletBusy.
  ///
  /// In en, this message translates to:
  /// **'The wallet is still finishing a task. Try again in a moment.'**
  String get errorWalletBusy;

  /// No description provided for @errorPaymentExpired.
  ///
  /// In en, this message translates to:
  /// **'The answer to this payment came too late, so the payment was cancelled. Nothing was sent.'**
  String get errorPaymentExpired;

  /// Summary in front of a technical detail in English.
  ///
  /// In en, this message translates to:
  /// **'Could not read or write wallet files.'**
  String get errorIo;

  /// Summary in front of a technical detail in English.
  ///
  /// In en, this message translates to:
  /// **'Wallet error.'**
  String get errorOther;

  /// A scan of the blockchain for the wallet's funds failed. Summary in front of a technical detail in English.
  ///
  /// In en, this message translates to:
  /// **'The scan failed.'**
  String get errorScanFailed;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error. Please try again.'**
  String get errorUnexpected;

  /// Importing a payment-history backup file (.wfeh) failed.
  ///
  /// In en, this message translates to:
  /// **'This is not a history file exported by this app.'**
  String get errorHistoryNotOurs;

  /// No description provided for @errorHistoryNewer.
  ///
  /// In en, this message translates to:
  /// **'This history file was made by a newer version of the app.'**
  String get errorHistoryNewer;

  /// No description provided for @errorHistoryDamaged.
  ///
  /// In en, this message translates to:
  /// **'This history file is damaged.'**
  String get errorHistoryDamaged;

  /// No description provided for @errorHistoryOtherWallet.
  ///
  /// In en, this message translates to:
  /// **'This history file belongs to a different wallet.'**
  String get errorHistoryOtherWallet;

  /// Network names stay as given (Mainnet, Floonet, Usernet).
  ///
  /// In en, this message translates to:
  /// **'This history file is from {fileNetwork}, but this wallet is on {walletNetwork}.'**
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork);

  /// The real Epic Cash network, where coins have value. Short; used as a screen title.
  ///
  /// In en, this message translates to:
  /// **'Mainnet'**
  String get networkMainnet;

  /// Name of Epic Cash's public test network. A proper name: do not translate.
  ///
  /// In en, this message translates to:
  /// **'Floonet'**
  String get networkFloonet;

  /// Name of a local developer test network. A proper name: do not translate.
  ///
  /// In en, this message translates to:
  /// **'Usernet'**
  String get networkUsernet;

  /// No description provided for @networkMainnetDescription.
  ///
  /// In en, this message translates to:
  /// **'The real Epic Cash network.'**
  String get networkMainnetDescription;

  /// No description provided for @networkFloonetDescription.
  ///
  /// In en, this message translates to:
  /// **'A public test network for trying the app. Its coins have no value; get free ones from floo-explorer.btlabs.uk.'**
  String get networkFloonetDescription;

  /// No description provided for @networkUsernetDescription.
  ///
  /// In en, this message translates to:
  /// **'A test network running on this computer, for developers.'**
  String get networkUsernetDescription;

  /// Appended to a title on a test network, e.g. 'Unlock wallet (Floonet, test coins)'. Keep the leading space if this language puts one before parentheses.
  ///
  /// In en, this message translates to:
  /// **' ({network}, test coins)'**
  String networkTestSuffix(String network);

  /// Auto-lock choice: the wallet never locks by itself.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get autoLockNever;

  /// Auto-lock choice: lock as soon as the app goes to the background.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get autoLockImmediately;

  /// Auto-lock choice: lock this long after the app went to the background.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{After 1 minute} other{After {minutes} minutes}}'**
  String autoLockAfterMinutes(int minutes);

  /// Progress line when a scan of the blockchain for the wallet's funds begins.
  ///
  /// In en, this message translates to:
  /// **'Starting scan'**
  String get scanStarting;

  /// Progress line of a scan of the blockchain for the wallet's funds.
  ///
  /// In en, this message translates to:
  /// **'Scanning the chain ({percent}%)'**
  String scanProgress(int percent);

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get scanComplete;

  /// Settings row that picks the app's language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// Language choice that follows the phone's language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get currencyUsd;

  /// No description provided for @currencyEur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyEur;

  /// No description provided for @currencyGbp.
  ///
  /// In en, this message translates to:
  /// **'British pound'**
  String get currencyGbp;

  /// No description provided for @currencyBtc.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin'**
  String get currencyBtc;

  /// No description provided for @currencyJpy.
  ///
  /// In en, this message translates to:
  /// **'Japanese yen'**
  String get currencyJpy;

  /// No description provided for @currencyCny.
  ///
  /// In en, this message translates to:
  /// **'Chinese yuan'**
  String get currencyCny;

  /// No description provided for @currencyCad.
  ///
  /// In en, this message translates to:
  /// **'Canadian dollar'**
  String get currencyCad;

  /// No description provided for @currencyAud.
  ///
  /// In en, this message translates to:
  /// **'Australian dollar'**
  String get currencyAud;

  /// No description provided for @currencyChf.
  ///
  /// In en, this message translates to:
  /// **'Swiss franc'**
  String get currencyChf;

  /// No description provided for @currencyInr.
  ///
  /// In en, this message translates to:
  /// **'Indian rupee'**
  String get currencyInr;

  /// No description provided for @currencyBrl.
  ///
  /// In en, this message translates to:
  /// **'Brazilian real'**
  String get currencyBrl;

  /// No description provided for @currencyKrw.
  ///
  /// In en, this message translates to:
  /// **'South Korean won'**
  String get currencyKrw;

  /// No description provided for @currencyPln.
  ///
  /// In en, this message translates to:
  /// **'Polish złoty'**
  String get currencyPln;

  /// No description provided for @currencyTry.
  ///
  /// In en, this message translates to:
  /// **'Turkish lira'**
  String get currencyTry;

  /// Payment details, status explanation of a send that has waited days for an answer. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Waiting for 1 day. The epicbox deletes payments after 7 days, so this one can no longer complete. Cancel it to unlock your funds, then send again.} other{Waiting for {days} days. The epicbox deletes payments after 7 days, so this one can no longer complete. Cancel it to unlock your funds, then send again.}}'**
  String txDetailsWaitingTooLong(int days);

  /// Payment details, status explanation of a send waiting for its recipient. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Sent to the recipient\'s epicbox. It completes when their wallet comes online. Your funds stay locked until then, or until you cancel.'**
  String get txDetailsWaitingEpicbox;

  /// Payment details, status explanation of a send passed by file or copy and paste. The transaction file holds the slate, the JSON a payment passes between sender and recipient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the recipient to answer with their transaction file. Your funds stay locked until then, or until you cancel.'**
  String get txDetailsWaitingRecipient;

  /// Payment details, status explanation of a receive the sender has not finished yet.
  ///
  /// In en, this message translates to:
  /// **'You accepted this payment. It completes when the sender finishes it and publishes it to the network.'**
  String get txDetailsWaitingSender;

  /// Payment details, status explanation of a finished send that is not in a block yet.
  ///
  /// In en, this message translates to:
  /// **'Published to the network. Waiting for the first confirmation.'**
  String get txDetailsPublished;

  /// Payment details, status explanation of a receive that is not in a block yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the network to confirm it.'**
  String get txDetailsWaitingConfirmation;

  /// Payment details, status explanation of a payment on the chain that is still gaining confirmations (blocks on top of it). The wallet calls it final at target confirmations; minutes is a rough estimate of the time left.
  ///
  /// In en, this message translates to:
  /// **'In block {height}. {count} of {target, plural, =1{1 confirmation} other{{target} confirmations}}; final in about {minutes, plural, =1{1 minute} other{{minutes} minutes}}.'**
  String txDetailsConfirmingMinutes(
    String height,
    int count,
    int target,
    int minutes,
  );

  /// As txDetailsConfirmingMinutes, with the time left in hours.
  ///
  /// In en, this message translates to:
  /// **'In block {height}. {count} of {target, plural, =1{1 confirmation} other{{target} confirmations}}; final in about {hours, plural, =1{1 hour} other{{hours} hours}}.'**
  String txDetailsConfirmingHours(
    String height,
    int count,
    int target,
    int hours,
  );

  /// As txDetailsConfirmingMinutes, with the time left in days.
  ///
  /// In en, this message translates to:
  /// **'In block {height}. {count} of {target, plural, =1{1 confirmation} other{{target} confirmations}}; final in about {days, plural, =1{1 day} other{{days} days}}.'**
  String txDetailsConfirmingDays(
    String height,
    int count,
    int target,
    int days,
  );

  /// Payment details, status explanation of a finished payment whose block is not known.
  ///
  /// In en, this message translates to:
  /// **'Completed.'**
  String get txDetailsCompleted;

  /// Payment details, status explanation of a finished payment.
  ///
  /// In en, this message translates to:
  /// **'Completed in block {height}.'**
  String txDetailsCompletedInBlock(String height);

  /// Payment details, why a send is cancelled: the user cancelled it. The slate may have reached the recipient, so it never says nothing was sent.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Nothing was paid, and the funds are spendable again. If the recipient already got it, their wallet may still show it as waiting; it can no longer complete.'**
  String get txDetailsCancelledByUser;

  /// Payment details, why a send is cancelled: the user released the funds of a send the network refused.
  ///
  /// In en, this message translates to:
  /// **'The network never took it, so its funds were released. Check the recipient did not receive it before sending again.'**
  String get txDetailsCancelledReleased;

  /// Payment details, why a send is cancelled: it was finished but never confirmed within its 14-day limit.
  ///
  /// In en, this message translates to:
  /// **'It did not reach the network within 14 days, so the wallet cancelled it. Check the recipient did not receive it before sending again.'**
  String get txDetailsCancelledNotOnChain;

  /// Payment details, why a send is cancelled: the recipient never answered within its 14-day limit.
  ///
  /// In en, this message translates to:
  /// **'The recipient did not answer within 14 days, so the wallet cancelled it. Nothing was paid, and the funds are spendable again.'**
  String get txDetailsCancelledUnanswered;

  /// Payment details, why a send is cancelled: the answer came too late.
  ///
  /// In en, this message translates to:
  /// **'The recipient answered after the 14-day limit, so the wallet cancelled it instead of finishing it. Nothing was paid, and the funds are spendable again.'**
  String get txDetailsCancelledLateAnswer;

  /// Payment details, why a send is cancelled: it never reached the recipient.
  ///
  /// In en, this message translates to:
  /// **'It could not be delivered to the recipient, so the wallet cancelled it at once. Nothing was sent, and the funds are spendable again.'**
  String get txDetailsCancelledUndelivered;

  /// Payment details, status explanation of a cancelled receive.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. This payment will not arrive.'**
  String get txDetailsCancelledIncoming;

  /// Payment details, status explanation of an unfinished payment imported from a history backup file.
  ///
  /// In en, this message translates to:
  /// **'This payment comes from a history backup and was not finished when the backup was made. This wallet has no record of its own for it, so it cannot tell whether it completed. Nothing is locked.'**
  String get txDetailsFromBackup;

  /// Payment details, small line under the status of a pending payment, shown when the current block height is not known.
  ///
  /// In en, this message translates to:
  /// **'Cancels automatically if not completed by block {height}.'**
  String txDetailsCancelsAtBlock(String height);

  /// Payment details, small line under the status of a pending payment; minutes is a rough estimate of the time until that block.
  ///
  /// In en, this message translates to:
  /// **'Cancels automatically if not completed by block {height} (in about {minutes, plural, =1{1 minute} other{{minutes} minutes}}).'**
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes);

  /// As txDetailsCancelsAtBlockInMinutes, in hours.
  ///
  /// In en, this message translates to:
  /// **'Cancels automatically if not completed by block {height} (in about {hours, plural, =1{1 hour} other{{hours} hours}}).'**
  String txDetailsCancelsAtBlockInHours(String height, int hours);

  /// As txDetailsCancelsAtBlockInMinutes, in days.
  ///
  /// In en, this message translates to:
  /// **'Cancels automatically if not completed by block {height} (in about {days, plural, =1{1 day} other{{days} days}}).'**
  String txDetailsCancelsAtBlockInDays(String height, int days);

  /// Payment details, small line under the status of a pending payment whose limit has passed.
  ///
  /// In en, this message translates to:
  /// **'Expired at block {height}. The wallet cancels it on the next refresh.'**
  String txDetailsExpiredAtBlock(String height);

  /// Title of the payment details screen while the payment is loading or gone.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get txDetailsTitle;

  /// Screen-reader label of the progress bar while the payment details load.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get txDetailsLoading;

  /// No description provided for @txDetailsGone.
  ///
  /// In en, this message translates to:
  /// **'This payment is no longer in the wallet.'**
  String get txDetailsGone;

  /// Screen-reader label of the progress bar while an action on the payment runs.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get txDetailsWorking;

  /// Screen-reader label of the amount while balances are hidden.
  ///
  /// In en, this message translates to:
  /// **'Amount hidden'**
  String get txDetailsAmountHidden;

  /// Small heading above txDetailsStuckBody, for a send the network has not included for a while.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get txDetailsNotConfirmedYet;

  /// No description provided for @txDetailsStuckBody.
  ///
  /// In en, this message translates to:
  /// **'The network has not taken this payment yet. Broadcasting it again is safe. The same payment cannot go through twice.'**
  String get txDetailsStuckBody;

  /// Button: send the finished payment to the network again.
  ///
  /// In en, this message translates to:
  /// **'Broadcast again'**
  String get txDetailsBroadcastAgain;

  /// Notice after the payment was sent to the network again.
  ///
  /// In en, this message translates to:
  /// **'Broadcast again. It should confirm within a few minutes.'**
  String get txDetailsBroadcastAgainDone;

  /// No description provided for @txDetailsRefusedBody.
  ///
  /// In en, this message translates to:
  /// **'The network refused this payment and it never reached the chain. You can release the funds it locked.'**
  String get txDetailsRefusedBody;

  /// Button on the details card and in the confirmation dialog: unlock the funds of a send the network refused.
  ///
  /// In en, this message translates to:
  /// **'Release funds'**
  String get txDetailsReleaseFunds;

  /// Title of the dialog that confirms releasing the funds of a refused send.
  ///
  /// In en, this message translates to:
  /// **'Release funds?'**
  String get txDetailsReleaseTitle;

  /// Release dialog text. Rescan means scanning the blockchain for the wallet's funds again.
  ///
  /// In en, this message translates to:
  /// **'Use this only if the payment will never confirm. If it still does, you may see a wrong balance until you rescan.'**
  String get txDetailsReleaseBody;

  /// Release dialog button that closes it without releasing.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get txDetailsReleaseKeepWaiting;

  /// Notice after the funds of a refused send were unlocked.
  ///
  /// In en, this message translates to:
  /// **'Funds released'**
  String get txDetailsFundsReleased;

  /// Button on the details card and in the confirmation dialog that cancels a pending payment. Other screens tell the user to tap it by this name.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get txDetailsCancelPayment;

  /// Title of the dialog that confirms cancelling a pending payment.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment?'**
  String get txDetailsCancelTitle;

  /// Cancel dialog text for a pending receive. Rescan means scanning the blockchain for the wallet's funds again.
  ///
  /// In en, this message translates to:
  /// **'The sender may still finish this payment. If they do after you cancel, it will not show until you rescan.'**
  String get txDetailsCancelReceiveBody;

  /// Cancel dialog text for a pending send.
  ///
  /// In en, this message translates to:
  /// **'Cancel this payment and unlock its funds? Only do this if the recipient has not finished it.'**
  String get txDetailsCancelSendBody;

  /// Cancel dialog button that keeps the payment pending.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get txDetailsCancelKeep;

  /// Notice after a payment was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get txDetailsPaymentCancelled;

  /// Label of a details row: when the payment happened.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDetailsDate;

  /// Label of a details row: when the payment was started, shown when it differs from the date it reached the chain.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get txDetailsCreated;

  /// Label of the row with the recipient's address.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get txDetailsSentTo;

  /// Label of the row with the sender's address.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get txDetailsReceivedFrom;

  /// Tooltip of the copy button beside the other side's address.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get txDetailsCopyAddress;

  /// Notice after the other side's address was copied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get txDetailsAddressCopied;

  /// Button: save the other side's address in the address book.
  ///
  /// In en, this message translates to:
  /// **'Add to contacts'**
  String get txDetailsAddToContacts;

  /// Button: send the undelivered payment again.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get txDetailsSendAgain;

  /// Label of a details row: the network fee of a send.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get txDetailsFee;

  /// Label of the field that edits the payment's note. The note is the user's own text about the payment.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txDetailsNoteLabel;

  /// Label of the details row with the user's own note on the payment. It is never sent to the other party, unlike the message.
  ///
  /// In en, this message translates to:
  /// **'Private note, only on this device'**
  String get txDetailsPrivateNoteLabel;

  /// Label of the message the person who sent the money wrote into the payment. Shown in payment details and on a transaction file before accepting it.
  ///
  /// In en, this message translates to:
  /// **'Message from the sender'**
  String get txDetailsMessageFromSender;

  /// Label of the message the person who received the money wrote into their answer to the payment.
  ///
  /// In en, this message translates to:
  /// **'Message from the recipient'**
  String get txDetailsMessageFromRecipient;

  /// Label of the message this wallet's user wrote into the payment, which the other party sees.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get txDetailsYourMessage;

  /// No description provided for @txDetailsNoNote.
  ///
  /// In en, this message translates to:
  /// **'No note. Add one to remember what this was for.'**
  String get txDetailsNoNote;

  /// Tooltip of the button that adds a note to the payment.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get txDetailsAddNote;

  /// Tooltip of the button that changes the payment's note.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get txDetailsEditNote;

  /// Title of the dialog that edits the payment's note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txDetailsNoteDialogTitle;

  /// Helper text under the note field: where the note is stored.
  ///
  /// In en, this message translates to:
  /// **'Only on this device and in your history backups.'**
  String get txDetailsNoteHelper;

  /// Notice after the note was saved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get txDetailsNoteSaved;

  /// Notice after the note was cleared.
  ///
  /// In en, this message translates to:
  /// **'Note removed'**
  String get txDetailsNoteRemoved;

  /// Label of the row with the payment's link in a block explorer (a website that shows the blockchain); tapping the row copies it.
  ///
  /// In en, this message translates to:
  /// **'Copy explorer link'**
  String get txDetailsExplorerLink;

  /// Tooltip of the copy button on the block explorer link row.
  ///
  /// In en, this message translates to:
  /// **'Copy explorer link'**
  String get txDetailsExplorerLinkCopy;

  /// Notice after the block explorer link was copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get txDetailsLinkCopied;

  /// Heading of a collapsed section with the payment's block height, IDs and commitments.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get txDetailsTechnical;

  /// Label: number of the block that holds the payment.
  ///
  /// In en, this message translates to:
  /// **'Block height'**
  String get txDetailsBlockHeight;

  /// Label: the payment's ID. A slate is the JSON a payment passes between sender and recipient.
  ///
  /// In en, this message translates to:
  /// **'Slate ID'**
  String get txDetailsSlateId;

  /// Tooltip of the copy button on the Slate ID row.
  ///
  /// In en, this message translates to:
  /// **'Copy slate id'**
  String get txDetailsSlateIdCopy;

  /// No description provided for @txDetailsSlateIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Slate ID copied'**
  String get txDetailsSlateIdCopied;

  /// Label: the payment's kernel, the part of a transaction that stays on the blockchain and proves it.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get txDetailsKernel;

  /// Tooltip of the copy button on the Kernel row.
  ///
  /// In en, this message translates to:
  /// **'Copy kernel'**
  String get txDetailsKernelCopy;

  /// No description provided for @txDetailsKernelCopied.
  ///
  /// In en, this message translates to:
  /// **'Kernel copied'**
  String get txDetailsKernelCopied;

  /// Label: the on-chain commitment of the payment's only output (a coin the payment created).
  ///
  /// In en, this message translates to:
  /// **'Output commitment'**
  String get txDetailsOutputCommitment;

  /// Tooltip of the copy button on the Output commitment row.
  ///
  /// In en, this message translates to:
  /// **'Copy output commitment'**
  String get txDetailsOutputCommitmentCopy;

  /// No description provided for @txDetailsOutputCommitmentCopied.
  ///
  /// In en, this message translates to:
  /// **'Output commitment copied'**
  String get txDetailsOutputCommitmentCopied;

  /// Label: the on-chain commitment of one of the payment's outputs, numbered from 1.
  ///
  /// In en, this message translates to:
  /// **'Output commitment {number}'**
  String txDetailsOutputCommitmentNumbered(int number);

  /// Tooltip of the copy button on a numbered Output commitment row.
  ///
  /// In en, this message translates to:
  /// **'Copy output commitment {number}'**
  String txDetailsOutputCommitmentNumberedCopy(int number);

  /// No description provided for @txDetailsOutputCommitmentNumberedCopied.
  ///
  /// In en, this message translates to:
  /// **'Output commitment {number} copied'**
  String txDetailsOutputCommitmentNumberedCopied(int number);

  /// Label: the block number by which a pending payment cancels itself.
  ///
  /// In en, this message translates to:
  /// **'Expiry height'**
  String get txDetailsExpiryHeight;

  /// Label: the payment's number in this wallet's own records.
  ///
  /// In en, this message translates to:
  /// **'Local id'**
  String get txDetailsLocalId;

  /// Note on a payment the wallet found by scanning the blockchain after a restore.
  ///
  /// In en, this message translates to:
  /// **'Found by scanning the chain. Details such as the sender and fee are not stored on the chain; import a history backup to restore them.'**
  String get txDetailsSourceRestored;

  /// Note on a payment that came from a history backup file.
  ///
  /// In en, this message translates to:
  /// **'Imported from a history backup. This wallet has no record of its own for it, so its status may be out of date.'**
  String get txDetailsSourceImported;

  /// Title of the screen with every payment.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Screen-reader label of the progress bar while the payment list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading payments'**
  String get historyLoading;

  /// Screen-reader label of the progress bar while the payment list refreshes.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get historyRefreshing;

  /// Label of the search field on the history screen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get historySearchLabel;

  /// Hint in the history search field: what it searches.
  ///
  /// In en, this message translates to:
  /// **'Note, contact, address or amount'**
  String get historySearchHint;

  /// Tooltip of the button that empties the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get historyClearSearch;

  /// Filter chip: show every payment. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// Filter chip: show outgoing payments. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get historyFilterSent;

  /// Filter chip: show incoming payments. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get historyFilterReceived;

  /// Filter chip: show unfinished payments. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get historyFilterPending;

  /// Filter chip: show cancelled payments. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get historyFilterCancelled;

  /// Heading of the section with unfinished payments, above the sections by day.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get historySectionPending;

  /// History screen when the wallet has no payments.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Payments you send or receive show up here.'**
  String get historyEmpty;

  /// History screen when the Sent filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No sent payments.'**
  String get historyNoSent;

  /// History screen when the Received filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No received payments.'**
  String get historyNoReceived;

  /// History screen when the Pending filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No pending payments.'**
  String get historyNoPending;

  /// History screen when the Cancelled filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No cancelled payments.'**
  String get historyNoCancelled;

  /// History screen when the search finds nothing; query is what the user typed. Use this language's quotation marks.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\".'**
  String historyNoMatch(String query);

  /// Title of the system save dialog for a payment-history file (desktop only).
  ///
  /// In en, this message translates to:
  /// **'Save payment history'**
  String get historyBackupSaveDialogTitle;

  /// Title of the system file picker for a payment-history backup (desktop only).
  ///
  /// In en, this message translates to:
  /// **'Open history backup'**
  String get historyBackupOpenDialogTitle;

  /// Import error: the picked file is far larger than a history backup.
  ///
  /// In en, this message translates to:
  /// **'That file is too large to be a backup.'**
  String get historyBackupFileTooLarge;

  /// Choice in a sheet: hand the history file to another app through the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get historyBackupShare;

  /// Second line of the Share choice.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy off this phone, such as email or cloud storage'**
  String get historyBackupShareSubtitle;

  /// Choice in a sheet: save the history file in a folder on this device.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get historyBackupSaveToDevice;

  /// Second line of the Save to device choice.
  ///
  /// In en, this message translates to:
  /// **'Only useful if you also copy it off this phone.'**
  String get historyBackupSaveToDeviceSubtitle;

  /// Notice after a history file was saved on the device.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName}'**
  String historyBackupSaved(String fileName);

  /// Title of the sheet that hands over the encrypted payment-history backup file.
  ///
  /// In en, this message translates to:
  /// **'Export history backup'**
  String get historyBackupExportTitle;

  /// Text in the export sheet under its title.
  ///
  /// In en, this message translates to:
  /// **'History backups hold payments up to now. Export again after new payments.'**
  String get historyBackupExportNote;

  /// Title of the warning dialog and of the sheet that hands over the payment list as a CSV spreadsheet file.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get historyBackupCsvTitle;

  /// Warning before a CSV export. Export history backup is the name of the settings row that makes the encrypted backup: use the same words as there.
  ///
  /// In en, this message translates to:
  /// **'The CSV file is not encrypted. Anyone who gets it can read your amounts, dates, addresses and notes. It cannot be imported back; use Export history backup for that.'**
  String get historyBackupCsvWarning;

  /// Button in the CSV warning dialog that goes ahead with the export.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get historyBackupCsvConfirm;

  /// Title of the dialog with the result of a history backup import.
  ///
  /// In en, this message translates to:
  /// **'History imported'**
  String get historyBackupImportedTitle;

  /// Error notice when a history backup could not be imported; reason is the error, a whole sentence.
  ///
  /// In en, this message translates to:
  /// **'Could not import the history backup. {reason}'**
  String historyBackupImportFailed(String reason);

  /// Import result when the backup added nothing.
  ///
  /// In en, this message translates to:
  /// **'The backup held nothing new.'**
  String get historyBackupImportNothingNew;

  /// Import result. The historyBackupImport… messages are one sentence per combination of counts, each count shown only when above zero: merged payments already in the list got their note, address and fee back from the backup; added older payments were not in the list; skipped records were imported before; contacts went into the address book.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}.'**
  String historyBackupImportMerged(int merged);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =1{1 older payment added} other{{added} older payments added}}.'**
  String historyBackupImportAdded(int added);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {added, plural, =1{1 older payment added} other{{added} older payments added}}.'**
  String historyBackupImportMergedAdded(int merged, int added);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}.'**
  String historyBackupImportSkipped(int skipped);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}.'**
  String historyBackupImportMergedSkipped(int merged, int skipped);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =1{1 older payment added} other{{added} older payments added}}, {skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}.'**
  String historyBackupImportAddedSkipped(int added, int skipped);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {added, plural, =1{1 older payment added} other{{added} older payments added}}, {skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}.'**
  String historyBackupImportMergedAddedSkipped(
    int merged,
    int added,
    int skipped,
  );

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportContacts(int contacts);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportMergedContacts(int merged, int contacts);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =1{1 older payment added} other{{added} older payments added}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportAddedContacts(int added, int contacts);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {added, plural, =1{1 older payment added} other{{added} older payments added}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportMergedAddedContacts(
    int merged,
    int added,
    int contacts,
  );

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportSkippedContacts(int skipped, int contacts);

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportMergedSkippedContacts(
    int merged,
    int skipped,
    int contacts,
  );

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =1{1 older payment added} other{{added} older payments added}}, {skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportAddedSkippedContacts(
    int added,
    int skipped,
    int contacts,
  );

  /// Import result; see historyBackupImportMerged.
  ///
  /// In en, this message translates to:
  /// **'{merged, plural, =1{1 payment got their details back} other{{merged} payments got their details back}}, {added, plural, =1{1 older payment added} other{{added} older payments added}}, {skipped, plural, =1{1 record was already here} other{{skipped} records were already here}}, {contacts, plural, =1{1 contact added} other{{contacts} contacts added}}.'**
  String historyBackupImportMergedAddedSkippedContacts(
    int merged,
    int added,
    int skipped,
    int contacts,
  );

  /// Tooltip of the app-bar button that closes the wallet and returns to the PIN screen.
  ///
  /// In en, this message translates to:
  /// **'Lock wallet'**
  String get homeLockTooltip;

  /// App-bar title of the wallet's main page: the app's name. A product name; do not translate.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash Mobile'**
  String get shellTitle;

  /// Heading of the web demo's welcome screen, under the mark.
  ///
  /// In en, this message translates to:
  /// **'Try Epic Cash'**
  String get demoWelcomeTitle;

  /// The welcome screen's one line under its heading. 'Floonet' is a network's name; keep it.
  ///
  /// In en, this message translates to:
  /// **'A real wallet with free test coins, which have no value. It is deleted after 24 hours.'**
  String get demoWelcomeLine;

  /// Main button of the demo's welcome screen. It creates a demo wallet, then asks for a PIN.
  ///
  /// In en, this message translates to:
  /// **'Start the demo'**
  String get demoStart;

  /// Heading of the screen shown when the 24 hours of a web demo ran out.
  ///
  /// In en, this message translates to:
  /// **'Your demo ended'**
  String get demoEndedTitle;

  /// Body of the screen shown when a web demo ran out. 'Start again' is the button below (demoStartAgain); use the same words.
  ///
  /// In en, this message translates to:
  /// **'Its wallet and test coins were deleted.'**
  String get demoEndedBody;

  /// Button on the ended screen of the web demo: starts a new demo.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get demoStartAgain;

  /// Tooltip of the demo countdown. {time} is a date and time, such as '21 Sep 2026, 14:05'.
  ///
  /// In en, this message translates to:
  /// **'Your demo ends at {time}. Its wallet and test coins are deleted then.'**
  String demoEndsAt(String time);

  /// Warning notice shown once, 30 minutes before a web demo ends.
  ///
  /// In en, this message translates to:
  /// **'Your demo ends in 30 minutes. Its wallet and test coins are deleted then.'**
  String get demoEndingSoon;

  /// Button in the web demo that asks the Floonet faucet to send free test coins to this wallet.
  ///
  /// In en, this message translates to:
  /// **'Get test coins'**
  String get demoTestCoins;

  /// Notice after the faucet accepted a claim for test coins.
  ///
  /// In en, this message translates to:
  /// **'Test coins are on their way. They arrive in a minute or two.'**
  String get demoTestCoinsPaid;

  /// Notice when the faucet refused a claim because the last one was too recent. {seconds} is a number, with the seconds abbreviation.
  ///
  /// In en, this message translates to:
  /// **'The faucet needs a pause. Try again in {seconds} s.'**
  String demoTestCoinsCooldown(int seconds);

  /// Notice when the faucet failed or did not answer.
  ///
  /// In en, this message translates to:
  /// **'The faucet sent nothing this time. Try again in a minute.'**
  String get demoTestCoinsFailed;

  /// Settings row in the web demo, instead of Delete this wallet, and the confirm button of its dialog.
  ///
  /// In en, this message translates to:
  /// **'End demo'**
  String get demoEnd;

  /// Title of the dialog before a web demo is ended.
  ///
  /// In en, this message translates to:
  /// **'End the demo?'**
  String get demoEndTitle;

  /// Body of the dialog before a web demo is ended.
  ///
  /// In en, this message translates to:
  /// **'Your demo wallet and its test coins are deleted now. You can start a new demo afterwards.'**
  String get demoEndBody;

  /// Error on the web demo's welcome screen when the demo server did not answer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the demo server. Check your connection and try again.'**
  String get demoServerUnreachable;

  /// Error when the demo server already runs as many demos as it allows. {minutes} is a number, with the minute abbreviation.
  ///
  /// In en, this message translates to:
  /// **'The demo is full right now. Try again in {minutes} min.'**
  String demoStartFull(int minutes);

  /// Error when the visitor's network started too many demos in the last hour. {minutes} is a number, with the minute abbreviation.
  ///
  /// In en, this message translates to:
  /// **'Too many demos were started from your network. Try again in {minutes} min.'**
  String demoStartTooMany(int minutes);

  /// Warning notice in the web demo while the connection to its wallet server is down and the app retries.
  ///
  /// In en, this message translates to:
  /// **'Connection lost, reconnecting.'**
  String get demoConnectionLost;

  /// Success notice in the web demo once the connection to its wallet server is back.
  ///
  /// In en, this message translates to:
  /// **'Connected again.'**
  String get demoConnectionBack;

  /// Tooltip of the app-bar button that opens settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// Tooltip and screen-reader label of the app-bar Settings button while it carries a small dot because a newer app version is available.
  ///
  /// In en, this message translates to:
  /// **'Settings: an update is available'**
  String get homeSettingsUpdateTooltip;

  /// Label of the left tab of the bottom tab bar, where payments are sent. Short.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get homeSendButton;

  /// Label of the middle tab of the bottom tab bar: balance, reminders and recent payments. Short.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get shellWalletTab;

  /// Label of the right tab of the bottom tab bar, which shows the wallet's address. Short.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get homeReceiveButton;

  /// Tooltip of the app-bar button that scans a recipient's QR code and opens Send with it.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code to send'**
  String get homeScanTooltip;

  /// Heading above the latest payments on home.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get homeRecentActivity;

  /// Button beside the Recent activity heading that opens the full payment history.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// Short notice after the user wrote down the recovery phrase (the 12 or 24 words).
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase backed up'**
  String get homeBackedUpNotice;

  /// Button on a payment notice that opens the payment's details. Short.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get homeNoticeView;

  /// Notice when a push message says a payment is waiting. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'A payment is waiting in your epicbox. It arrives once the app is connected.'**
  String get homePushNotice;

  /// Notice: the wallet accepted an incoming payment; the sender still has to finish it.
  ///
  /// In en, this message translates to:
  /// **'A payment is on the way. It completes when the sender finishes.'**
  String get homeNoticeReceived;

  /// Notice: the wallet accepted an incoming payment from a saved contact; the sender still has to finish it.
  ///
  /// In en, this message translates to:
  /// **'A payment from {who} is on the way. It completes when the sender finishes.'**
  String homeNoticeReceivedFrom(String who);

  /// Notice: the wallet accepted an incoming payment of this amount; the sender still has to finish it.
  ///
  /// In en, this message translates to:
  /// **'{amount} on the way. It completes when the sender finishes.'**
  String homeNoticeReceivedAmount(String amount);

  /// Notice: the wallet accepted an incoming payment of this amount from a saved contact; the sender still has to finish it.
  ///
  /// In en, this message translates to:
  /// **'{amount} from {who} on the way. It completes when the sender finishes.'**
  String homeNoticeReceivedAmountFrom(String amount, String who);

  /// Notice: an outgoing payment was finished and posted to the chain, not yet confirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment finished. Waiting for confirmations.'**
  String get homeNoticeFinished;

  /// Notice: an outgoing payment was finished and posted to the chain, not yet confirmed. who is a contact name or a short address.
  ///
  /// In en, this message translates to:
  /// **'Payment to {who} finished. Waiting for confirmations.'**
  String homeNoticeFinishedTo(String who);

  /// Notice: an incoming payment the wallet accepted before arrived again and got the same answer; it is not a second payment.
  ///
  /// In en, this message translates to:
  /// **'This payment was already accepted. The sender got the same answer again; no second payment is on the way.'**
  String get homeNoticeRepeated;

  /// Notice: an incoming payment from a saved contact that the wallet accepted before arrived again and got the same answer; it is not a second payment.
  ///
  /// In en, this message translates to:
  /// **'The payment from {who} was already accepted. They got the same answer again; no second payment is on the way.'**
  String homeNoticeRepeatedFrom(String who);

  /// Notice: the answer to a payment arrived but the node (the Epic Cash server the wallet reads the chain from) could not be reached; the wallet retries.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the node. The payment will finish once it can.'**
  String get homeNoticeDelayed;

  /// Notice: the epicbox relay (a proper name; it carries payments) reported an error not tied to a payment.
  ///
  /// In en, this message translates to:
  /// **'The epicbox server reported a problem. Retrying.'**
  String get homeNoticeRelayProblem;

  /// Notice: something went wrong with one payment.
  ///
  /// In en, this message translates to:
  /// **'A payment could not be completed.'**
  String get homeNoticePaymentFailed;

  /// Card on home until the user writes down the recovery phrase (the 12 or 24 words).
  ///
  /// In en, this message translates to:
  /// **'Back up your recovery phrase.'**
  String get homeBackupCardText;

  /// Button on the recovery phrase card. Short: it shares a row with the card's text.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get homeBackupCardButton;

  /// Tooltip of the close button that hides the recovery phrase card for good.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get homeBackupCardDismiss;

  /// Card on home before the first history backup. A history backup is a file with the payment list, notes and contacts; a restore from the recovery phrase (the 12 or 24 words) finds the funds but not that list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment is not in a history backup. A restore from your recovery phrase brings back only your balance.} other{{count} payments are not in a history backup. A restore from your recovery phrase brings back only your balance.}}'**
  String homeHistoryNotBackedUp(int count);

  /// Card on home when payments changed after the last history backup (a file with the payment list, notes and contacts).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment is new or changed since your last history backup. A restore from your recovery phrase brings back only your balance.} other{{count} payments are new or changed since your last history backup. A restore from your recovery phrase brings back only your balance.}}'**
  String homeHistoryChangedSinceBackup(int count);

  /// Button that hides the history backup card for a week.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get homeHistoryReminderNotNow;

  /// Button on the history backup card that saves the backup file.
  ///
  /// In en, this message translates to:
  /// **'Export history backup'**
  String get homeHistoryExportButton;

  /// Label above the large balance on home: the funds that can be sent now.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get homeBalanceSpendable;

  /// Screen-reader label of the ? beside the balance; a tap shows every balance with a short explanation.
  ///
  /// In en, this message translates to:
  /// **'What these balances mean'**
  String get balanceHelpLabel;

  /// Label in the balance explanation: everything in the wallet. Followed by a colon and the amount.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get balanceTotal;

  /// One balance in the balance explanation: its name, then the amount.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}'**
  String balanceHelpRow(String label, String amount);

  /// Explanation under Total in the balance explanation.
  ///
  /// In en, this message translates to:
  /// **'Everything in this wallet, spendable or not.'**
  String get balanceTotalHelp;

  /// Screen-reader label of the balance while amounts are hidden.
  ///
  /// In en, this message translates to:
  /// **'Balance hidden'**
  String get homeBalanceHiddenLabel;

  /// Tooltip of the eye button while amounts are hidden.
  ///
  /// In en, this message translates to:
  /// **'Show balances'**
  String get homeShowBalances;

  /// Tooltip of the eye button that hides all amounts.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get homeHideBalances;

  /// Row of the balance breakdown: payments on the chain still collecting confirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get homeBalanceConfirming;

  /// Explanation under Confirming in the balance explanation.
  ///
  /// In en, this message translates to:
  /// **'On the chain, waiting for enough confirmations.'**
  String get balanceConfirmingHelp;

  /// Row of the balance breakdown: outputs not in a block yet (payments the sender has not finished, payments in the pool, change of a send). Never counted as money.
  ///
  /// In en, this message translates to:
  /// **'Not on chain yet'**
  String get homeBalanceNotOnChain;

  /// Explanation under Not on chain yet in the balance explanation.
  ///
  /// In en, this message translates to:
  /// **'Payments to you that the sender has not finished or that are not in a block yet, and change from your sends. Not counted until they are on chain: a payment someone only offered may never arrive.'**
  String get balanceNotOnChainHelp;

  /// Row of the balance breakdown: funds held by an outgoing payment until it finishes or is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Locked by a payment in progress'**
  String get homeBalanceLocked;

  /// Explanation under Locked in the balance explanation.
  ///
  /// In en, this message translates to:
  /// **'Held for a payment you started; the change comes back when it completes.'**
  String get balanceLockedHelp;

  /// Row of the balance breakdown: mined coins that need more blocks before they can be spent.
  ///
  /// In en, this message translates to:
  /// **'Mining rewards not spendable yet'**
  String get homeBalanceImmature;

  /// Explanation under the mining rewards line in the balance explanation.
  ///
  /// In en, this message translates to:
  /// **'Mining rewards wait a set number of blocks before they can be spent.'**
  String get balanceImmatureHelp;

  /// That line when nothing is pending: the whole balance is spendable. No full stop.
  ///
  /// In en, this message translates to:
  /// **'All confirmed'**
  String get balanceLineAllConfirmed;

  /// That line in a wallet that has had no payments yet. No full stop.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get balanceLineNothingYet;

  /// Status line under the balance while the wallet syncs with the node.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get homeSyncSyncing;

  /// Status line under the balance while the wallet syncs with the node.
  ///
  /// In en, this message translates to:
  /// **'Syncing… {percent}%'**
  String homeSyncSyncingPercent(int percent);

  /// Status line under the balance. The node is the Epic Cash server the wallet reads the chain from.
  ///
  /// In en, this message translates to:
  /// **'Node unreachable. Balances may be out of date.'**
  String get homeSyncNodeUnreachable;

  /// Status line under the balance: the node (the Epic Cash server the wallet reads the chain from) has not confirmed the figures.
  ///
  /// In en, this message translates to:
  /// **'Not validated with node. Balances may be out of date.'**
  String get homeSyncNotValidated;

  /// Status line under the balance when it matches the chain.
  ///
  /// In en, this message translates to:
  /// **'Up to date.'**
  String get homeSyncUpToDate;

  /// Status line under the balance before the node (the Epic Cash server the wallet reads the chain from) answered.
  ///
  /// In en, this message translates to:
  /// **'Contacting node…'**
  String get homeSyncContactingNode;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. The node works.
  ///
  /// In en, this message translates to:
  /// **'Node online'**
  String get statusNodeOnline;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. The wallet reads new blocks from the node.
  ///
  /// In en, this message translates to:
  /// **'Node syncing'**
  String get statusNodeSyncing;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. statusNodeSyncing with how far it got.
  ///
  /// In en, this message translates to:
  /// **'Node syncing {percent}%'**
  String statusNodeSyncingPercent(int percent);

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. No answer from the node yet.
  ///
  /// In en, this message translates to:
  /// **'Node connecting'**
  String get statusNodeConnecting;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. The node cannot be reached, or did not check the balances.
  ///
  /// In en, this message translates to:
  /// **'Node offline'**
  String get statusNodeOffline;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. Connected to the epicbox relay, so payments arrive.
  ///
  /// In en, this message translates to:
  /// **'Epicbox online'**
  String get statusEpicboxOnline;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. No connection to the epicbox relay yet.
  ///
  /// In en, this message translates to:
  /// **'Epicbox connecting'**
  String get statusEpicboxConnecting;

  /// Status in the balance header beside an icon, also what a screen reader says: the service (node: the Epic Cash server the wallet reads the chain from; epicbox: the relay payments arrive through) and its state, about two words. The connection to the epicbox relay was lost; it retries.
  ///
  /// In en, this message translates to:
  /// **'Epicbox offline'**
  String get statusEpicboxOffline;

  /// First line of the node status tooltip on a test network only, since the app bar names no network: the network's name (for example Floonet) and that its coins are test coins with no value.
  ///
  /// In en, this message translates to:
  /// **'{network}, test coins'**
  String statusNodeTestNetwork(String network);

  /// Line in the node status tooltip: the node's host name.
  ///
  /// In en, this message translates to:
  /// **'Node: {host}'**
  String statusNodeHost(Object host);

  /// Line in the node status tooltip.
  ///
  /// In en, this message translates to:
  /// **'Node version {version}'**
  String statusNodeVersion(Object version);

  /// Line in the epicbox status tooltip: the epicbox server as host:port.
  ///
  /// In en, this message translates to:
  /// **'Server: {relay}'**
  String statusRelay(Object relay);

  /// Second sentence of the status line: the connection to epicbox (the relay service that carries payments, a proper name) was lost.
  ///
  /// In en, this message translates to:
  /// **'Epicbox offline, reconnecting.'**
  String get homeEpicboxOffline;

  /// Second sentence of the status line while the app connects to epicbox (the relay service that carries payments, a proper name).
  ///
  /// In en, this message translates to:
  /// **'Connecting to epicbox…'**
  String get homeEpicboxConnecting;

  /// Tooltip of the status line: the chain height the balance was last checked at.
  ///
  /// In en, this message translates to:
  /// **'Synced at block {height}'**
  String homeSyncedAtBlock(String height);

  /// Title of the card on home about sent payments the recipient has not answered yet. No full stop.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A payment is waiting for the recipient} other{{count} payments are waiting for their recipients}}'**
  String homePendingTitle(int count);

  /// Text of the card about sent payments the recipient has not answered yet. amount is the total of those payments. 'Cancel payment' is the button on a payment's details screen: use the same words as that button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} is waiting for the recipient\'s wallet to answer. Until then the funds stay locked. If it never answers, open the payment and tap Cancel payment.} other{{amount} is waiting for the recipients\' wallets to answer. Until then the funds stay locked. If one never answers, open the payment and tap Cancel payment.}}'**
  String homePendingBody(int count, String amount);

  /// Button on the waiting-payments card that opens help. Short: it shares a row with the View button.
  ///
  /// In en, this message translates to:
  /// **'Why is it waiting?'**
  String get homePendingWhy;

  /// Button on the waiting-payments card that opens the payment, or the list of waiting payments. Short.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{View payment} other{View payments}}'**
  String homePendingView(int count);

  /// Shown on home in place of the payment list in a new wallet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get homeNoPayments;

  /// Title of the Invoices screen: invoices that services the user trusts sent, waiting for the user's answer. Also the word for an invoice elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoicesTitle;

  /// Tooltip and screen-reader label of the Invoices button in home's app bar. count is how many invoices wait for an answer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Invoices} =1{Invoices, 1 waiting} other{Invoices, {count} waiting}}'**
  String invoicesEntryTooltip(int count);

  /// Screen-reader label of the progress line while the Invoices screen fetches new invoices.
  ///
  /// In en, this message translates to:
  /// **'Checking for invoices'**
  String get invoicesChecking;

  /// Shown on the Invoices screen when no invoice waits.
  ///
  /// In en, this message translates to:
  /// **'No invoices are waiting. When a service you trust bills you, the invoice appears here, and nothing is paid until you approve it.'**
  String get invoicesEmpty;

  /// Name shown for a trusted service whose label was lost. Never the name the invoice gives itself.
  ///
  /// In en, this message translates to:
  /// **'Unnamed service'**
  String get invoicesUnnamedService;

  /// How long an invoice can still be paid, with an hour or more left. Short units, no plural forms needed.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min left'**
  String invoiceTimeLeftHours(int hours, int minutes);

  /// How long an invoice can still be paid, under an hour left. Short unit, no plural forms needed.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String invoiceTimeLeftMinutes(int minutes);

  /// How long an invoice can still be paid, under a minute left.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute left'**
  String get invoiceTimeLeftUnderMinute;

  /// On the invoice review screen once the invoice's time ran out.
  ///
  /// In en, this message translates to:
  /// **'This invoice has expired. Nothing was paid.'**
  String get invoiceExpired;

  /// On the invoice review screen when the service withdrew the invoice while the user looked at it.
  ///
  /// In en, this message translates to:
  /// **'This invoice is no longer open. Nothing was paid.'**
  String get invoiceGone;

  /// Title of the screen where the user approves or declines one invoice.
  ///
  /// In en, this message translates to:
  /// **'Review invoice'**
  String get invoiceReviewTitle;

  /// Heading above the invoiced amount. service is the name the user gave the service. No full stop.
  ///
  /// In en, this message translates to:
  /// **'{service} asks you to pay'**
  String invoiceReviewAsks(String service);

  /// Label above the one line of text the service put in its invoice.
  ///
  /// In en, this message translates to:
  /// **'Message from the service'**
  String get invoiceReviewMessageLabel;

  /// Under the invoice on the review screen.
  ///
  /// In en, this message translates to:
  /// **'Your wallet adds the network fee. Nothing is paid until you approve it.'**
  String get invoiceReviewNote;

  /// Main button of the invoice review screen; it asks for the PIN, then pays.
  ///
  /// In en, this message translates to:
  /// **'Approve and pay'**
  String get invoiceApprove;

  /// Button that declines an invoice and tells the service.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get invoiceDecline;

  /// In the PIN dialog after the user approves an invoice.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to pay this invoice.'**
  String get invoicePinReason;

  /// Title of the dialog that confirms declining an invoice.
  ///
  /// In en, this message translates to:
  /// **'Decline this invoice?'**
  String get invoiceDeclineTitle;

  /// Text of the dialog that confirms declining an invoice. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'{service} is told that you declined. Nothing is paid.'**
  String invoiceDeclineBody(String service);

  /// Button of the decline dialog that keeps the invoice open.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get invoiceDeclineKeep;

  /// Notice after the user declined an invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice declined.'**
  String get invoiceDeclinedNotice;

  /// Notice after an approved invoice's payment reached the service, which finalizes and posts it. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'Paid. {service} now finishes the payment.'**
  String invoicePaidNotice(String service);

  /// Heading on the review screen when the approved payment could not be delivered to the service. No full stop.
  ///
  /// In en, this message translates to:
  /// **'Your payment has not reached {service}'**
  String invoiceReplyFailedTitle(String service);

  /// Under invoiceReplyFailedTitle. 'Retry' is the button below: use the same word as invoiceRetry.
  ///
  /// In en, this message translates to:
  /// **'It is signed and kept on this device. Retry sends it again; you do not approve it again.'**
  String get invoiceReplyFailedBody;

  /// Error notice when an approved invoice's payment could not be delivered. 'Retry' is the button: use the same word as invoiceRetry.
  ///
  /// In en, this message translates to:
  /// **'Your payment could not reach the service. Tap Retry to send it again.'**
  String get invoiceReplyFailedNotice;

  /// Button that sends an approved invoice's payment to the service again, without approving again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get invoiceRetry;

  /// Section heading in a payment's details when the payment paid an invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceDetailsSection;

  /// Label of the service's name in a paid invoice's details.
  ///
  /// In en, this message translates to:
  /// **'Billed by'**
  String get invoiceDetailsService;

  /// Paid invoice's details: the service got the payment and has not reported posting it yet. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {service} to post the payment.'**
  String invoiceDetailsReplied(String service);

  /// Paid invoice's details while the service has not posted the payment: Send again delivers the stored reply again, and when Cancel becomes available. The payment's time to live is 1440 blocks, about a day. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'If {service} has not posted it, send the payment again: nothing is signed twice. If it is never posted, Cancel becomes available once the payment\'s time runs out, about a day after you paid.'**
  String invoiceDetailsRepliedHelp(String service);

  /// Paid invoice's details after the service's receipt arrived. The receipt only informs: the status above comes from the chain. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'{service} reports it posted the payment. It completes once the network confirms it.'**
  String invoiceDetailsPosted(String service);

  /// Paid invoice's details when the payment could not be delivered to the service. 'Retry' is the button below: use the same word as invoiceRetry. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'{service} has not received your payment yet. Retry sends it again; you do not approve it again.'**
  String invoiceDetailsReplyFailed(String service);

  /// Warning in a paid invoice's details when the service withdrew the invoice after payment. The Cancel payment button follows. service is the name the user gave the service.
  ///
  /// In en, this message translates to:
  /// **'{service} withdrew this invoice after you paid it. If the payment does not confirm, cancel it to unlock your funds.'**
  String invoiceDetailsWithdrawn(String service);

  /// Notice when a trusted service's invoice arrived.
  ///
  /// In en, this message translates to:
  /// **'An invoice is waiting for your approval.'**
  String get invoiceNoticeReceived;

  /// Notice when a service's receipt for a paid invoice arrived.
  ///
  /// In en, this message translates to:
  /// **'A service reports it posted your payment.'**
  String get invoiceNoticePosted;

  /// Warning notice when a service withdrew an invoice after the user paid it.
  ///
  /// In en, this message translates to:
  /// **'A service withdrew an invoice you already paid.'**
  String get invoiceNoticeWithdrawnPaid;

  /// Notice when a service withdrew an invoice the user had not answered.
  ///
  /// In en, this message translates to:
  /// **'A service withdrew an invoice before you answered it.'**
  String get invoiceNoticeWithdrawn;

  /// Notice when an invoice's time ran out before the user answered it.
  ///
  /// In en, this message translates to:
  /// **'An invoice expired before you answered it.'**
  String get invoiceNoticeExpired;

  /// Button on Receive's Epicbox address tab that opens the request form: the user asks someone to pay them over epicbox (an invoice they send). Shown beside Get test coins in the web demo, so keep it short.
  ///
  /// In en, this message translates to:
  /// **'Request a payment'**
  String get receiveRequestTitle;

  /// Title of the screen where the user asks someone to pay them.
  ///
  /// In en, this message translates to:
  /// **'Request a payment'**
  String get requestTitle;

  /// First line of the request screen, above the two numbered steps the payer must take first.
  ///
  /// In en, this message translates to:
  /// **'Their wallet must take invoices. Before you request:'**
  String get requestStepsIntro;

  /// First step on the request screen. 'Trusted services' is the list in the payer's invoice settings; the user's own address is shown in full right below.
  ///
  /// In en, this message translates to:
  /// **'1. They add your address below to their trusted services.'**
  String get requestStepTrust;

  /// Second step on the request screen: the payer's invoice address goes in the field below.
  ///
  /// In en, this message translates to:
  /// **'2. They give you their invoice address.'**
  String get requestStepAddress;

  /// Label above the user's own payments address on the request screen, which the payer must trust.
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get requestYourAddress;

  /// Label of the field for the payer's invoice address.
  ///
  /// In en, this message translates to:
  /// **'Their invoice address'**
  String get requestPayerLabel;

  /// Error under the payer field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Paste or scan their invoice address.'**
  String get requestPayerMissing;

  /// Error under the payer field when it holds the user's own payments or invoice address.
  ///
  /// In en, this message translates to:
  /// **'That is one of your own addresses. Enter the invoice address the payer gives you.'**
  String get requestPayerOwn;

  /// Label of the optional message field on the request screen.
  ///
  /// In en, this message translates to:
  /// **'Message to the payer (optional)'**
  String get requestMessageLabel;

  /// Helper text under the request's message field.
  ///
  /// In en, this message translates to:
  /// **'The payer sees this message with your request.'**
  String get requestMessageHelper;

  /// Main button of the request screen: sends the request to the payer.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestButton;

  /// Notice after a request reached the relay. payer is the contact's name or the start of their address.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {payer}.'**
  String requestSentNotice(String payer);

  /// Heading on the Invoices screen above invoices that services sent the user.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get invoicesToPaySection;

  /// Shown under invoicesToPaySection when no invoice waits but the user has sent requests.
  ///
  /// In en, this message translates to:
  /// **'Nothing to pay.'**
  String get invoicesNoneToPay;

  /// Heading on the Invoices screen above the payment requests the user sent to others.
  ///
  /// In en, this message translates to:
  /// **'Requests you sent'**
  String get invoicesSentSection;

  /// State of a request the user sent: the payer paid it.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get issuedPaid;

  /// State of a request the user sent: the payer declined it.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get issuedDeclined;

  /// State of a request the user sent: the user withdrew it.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get issuedWithdrawn;

  /// State of a request the user sent: its time ran out unpaid.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get issuedExpired;

  /// Button that withdraws a request the user sent, so it can no longer be paid. Asks first.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get issuedWithdraw;

  /// Title of the confirm before a request is withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this request?'**
  String get issuedWithdrawTitle;

  /// Body of the withdraw confirm. payer is the contact's name or the start of their address.
  ///
  /// In en, this message translates to:
  /// **'{payer} can no longer pay it. This cannot be undone.'**
  String issuedWithdrawBody(String payer);

  /// Button in the withdraw confirm that keeps the request open.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get issuedWithdrawKeep;

  /// Heading of the request block in a transaction's details, for a request the user sent.
  ///
  /// In en, this message translates to:
  /// **'Payment request'**
  String get issuedDetailsSection;

  /// Label above the payer in the request block of a transaction's details.
  ///
  /// In en, this message translates to:
  /// **'Requested from'**
  String get issuedDetailsPayer;

  /// Request block, while the request is unpaid.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the payer. Your wallet finishes the payment when it arrives.'**
  String get issuedDetailsWaiting;

  /// Request block, once the payer paid.
  ///
  /// In en, this message translates to:
  /// **'Paid. Your wallet finished the payment; it completes once the network confirms it.'**
  String get issuedDetailsPaid;

  /// Request block, after the payer declined.
  ///
  /// In en, this message translates to:
  /// **'The payer declined this request, so it was withdrawn. Nothing was paid.'**
  String get issuedDetailsDeclined;

  /// Request block, after the user withdrew it.
  ///
  /// In en, this message translates to:
  /// **'You withdrew this request. Nothing was paid.'**
  String get issuedDetailsWithdrawn;

  /// Request block, after its time ran out unpaid.
  ///
  /// In en, this message translates to:
  /// **'This request expired before it was paid. Nothing was paid.'**
  String get issuedDetailsExpired;

  /// Notice when a payer paid a request the user sent, and the wallet finished the payment.
  ///
  /// In en, this message translates to:
  /// **'A request you sent was paid.'**
  String get issuerNoticePaid;

  /// Notice when a payer declined a request the user sent.
  ///
  /// In en, this message translates to:
  /// **'A request you sent was declined.'**
  String get issuerNoticeDeclined;

  /// Notice after the user withdrew a request.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn. It can no longer be paid.'**
  String get issuerNoticeWithdrawn;

  /// Notice when a request the user sent ran out of time unpaid.
  ///
  /// In en, this message translates to:
  /// **'A request you sent expired unpaid.'**
  String get issuerNoticeExpired;

  /// Warning when a request the user sent came back from the payer's wallet, which cannot pay invoices (for example the standard epic-wallet). The app withdrew the request. payer is the contact name or the start of the address.
  ///
  /// In en, this message translates to:
  /// **'{payer}\'s wallet cannot pay requests and sent yours back, so it was withdrawn. Ask them to send you the payment instead, to your address or as a payment file.'**
  String issuerNoticeBouncedFrom(String payer);

  /// State of a request the user sent: the payer's wallet cannot pay invoices and sent it back.
  ///
  /// In en, this message translates to:
  /// **'Sent back'**
  String get issuedBounced;

  /// Request details: the payer's wallet cannot pay invoices and sent the request back, so the app withdrew it.
  ///
  /// In en, this message translates to:
  /// **'The payer\'s wallet cannot pay requests and sent this one back, so it was withdrawn. Nothing was paid. Ask them to send you the payment instead, to your address or as a payment file.'**
  String get issuedDetailsBounced;

  /// Warning on the request form, before Request: this payer's wallet sent a request back before, so it cannot pay requests. Shown with a button that explains payment files.
  ///
  /// In en, this message translates to:
  /// **'This wallet sent a request back before: it cannot pay requests. Ask them to send you the payment instead, to your address or as a payment file.'**
  String get requestPayerNoInvoices;

  /// Status of a payment request the user sent: the payer has not paid it yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payer'**
  String get txStatusWaitingPayer;

  /// Timeline step of a payment request: the user sent the request.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get txStepRequested;

  /// Timeline step of a payment request: the payer paid it and the wallet published the payment.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get txStepPaid;

  /// Details of a payment request the user sent that is not paid yet. Nothing has arrived.
  ///
  /// In en, this message translates to:
  /// **'You asked for this payment. Nothing has arrived yet: it comes when the payer pays the request.'**
  String get txDetailsWaitingPayer;

  /// Details of a payment request that ended unpaid: declined, withdrawn, sent back or expired.
  ///
  /// In en, this message translates to:
  /// **'This request ended unpaid. Nothing arrived.'**
  String get txDetailsRequestEnded;

  /// Details label above the address of the person a payment request went to.
  ///
  /// In en, this message translates to:
  /// **'Requested from'**
  String get txDetailsRequestedFrom;

  /// Title of a payment request the user sent, when no name or address is known.
  ///
  /// In en, this message translates to:
  /// **'Requested payment'**
  String get txPaymentRequest;

  /// Screen reader label of a payment request row that is not paid yet. amount is the formatted amount.
  ///
  /// In en, this message translates to:
  /// **'Requesting {amount}'**
  String txSpokenRequesting(String amount);

  /// Screen reader label of a payment request row that is not paid yet. amount is the formatted amount, who the contact name or short address.
  ///
  /// In en, this message translates to:
  /// **'Requesting {amount} from {who}'**
  String txSpokenRequestingFrom(String amount, String who);

  /// Tooltip and screen-reader label of the connection dot. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Epicbox connected'**
  String get receiveEpicboxConnected;

  /// Screen-reader label of the QR code image.
  ///
  /// In en, this message translates to:
  /// **'QR code of your address'**
  String get receiveQrLabel;

  /// Caption above the wallet's full epicbox address on the Receive tab; a tap on the card copies the address.
  ///
  /// In en, this message translates to:
  /// **'Epicbox address'**
  String get receiveAddressLabel;

  /// Shown under 'Epicbox offline' on the Receive tab, above a Retry button. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Payments sent to you now wait at epicbox and arrive once the wallet connects again.'**
  String get receiveEpicboxOfflineBody;

  /// One line at the top of the picture Share sends, above the QR code and the address. Epic Cash is the coin's name.
  ///
  /// In en, this message translates to:
  /// **'Pay me in Epic Cash'**
  String get receiveShareCardHeadline;

  /// Button on the Receive tab that opens help about receiving.
  ///
  /// In en, this message translates to:
  /// **'How receiving works'**
  String get receiveHelpButton;

  /// Notice after the wallet's address was copied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get receiveAddressCopied;

  /// Heading of the Receive tab's card for a payment that comes as a file (or its text) instead of over epicbox.
  ///
  /// In en, this message translates to:
  /// **'Receive by payment file'**
  String get receiveFileTitle;

  /// Line in the payment file card, above the Open file and Paste buttons.
  ///
  /// In en, this message translates to:
  /// **'Got a payment file from someone? Open it, or copy its text and paste it here.'**
  String get receiveFileBody;

  /// Button in the payment file card that picks the file.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get receiveFileOpen;

  /// Notice when Paste is tapped and the clipboard holds no text.
  ///
  /// In en, this message translates to:
  /// **'Copy the payment text first, then tap Paste.'**
  String get receivePasteEmpty;

  /// Notice at the top of the screen while the app checks for a new version.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// Notice at the top of the screen after a check found no new version.
  ///
  /// In en, this message translates to:
  /// **'This is the latest version.'**
  String get updateUpToDate;

  /// Notice at the top of the screen after a check: the update server has no information about releases for this app (none published there), so the app cannot say whether a newer version exists.
  ///
  /// In en, this message translates to:
  /// **'No update information available.'**
  String get updateNoInformation;

  /// Notice under the app bar; beside it is the Update button.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.'**
  String updateAvailable(String version);

  /// Notice at the top of the screen while the new version downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloading version {version}… {percent}%'**
  String updateDownloading(String version, int percent);

  /// Notice at the top of the screen while Android installs the new version.
  ///
  /// In en, this message translates to:
  /// **'Installing version {version}…'**
  String updateInstalling(String version);

  /// Notice at the top of the screen when an update failed for no known reason.
  ///
  /// In en, this message translates to:
  /// **'The update failed.'**
  String get updateFailed;

  /// Button that downloads and installs the new version. Short.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateInstallButton;

  /// Button after a failed update check or install. Short.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get updateTryAgain;

  /// Screen-reader label of the progress bar while the new version downloads.
  ///
  /// In en, this message translates to:
  /// **'Download progress'**
  String get updateDownloadProgressLabel;

  /// Settings' update row while Android's screen for allowing installs from this app is open or was just opened; the update carries on by itself once the user allows and comes back. 'Epic Cash Mobile' is the app's name, never translated.
  ///
  /// In en, this message translates to:
  /// **'Allow installs from Epic Cash Mobile, then return.'**
  String get updateAllowInstalls;

  /// Update banner and Settings row after Android's install dialog was closed without installing (Cancel or Back); the banner's and the row's buttons start it again.
  ///
  /// In en, this message translates to:
  /// **'The update was not installed. You can try again.'**
  String get updateInstallCancelled;

  /// Android's installer refused the update. detail is the installer's own message, in English.
  ///
  /// In en, this message translates to:
  /// **'The update was not installed: {detail}'**
  String updateNotInstalled(String detail);

  /// Handing the update to Android's installer failed. detail is the system's own message, in English.
  ///
  /// In en, this message translates to:
  /// **'Cannot install the update: {detail}.'**
  String updateCannotInstall(String detail);

  /// Handing the update to Android's installer failed and the system gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Cannot install the update: unknown error.'**
  String get updateCannotInstallUnknown;

  /// The update is signed with another key than the installed app, so Android cannot install it over it. The user must write down the recovery phrase, uninstall and install the new version; uninstalling deletes the wallet from the device.
  ///
  /// In en, this message translates to:
  /// **'This update is signed with a new key, so it cannot install over this version. A reinstall is needed, and uninstalling removes this wallet from the device: write down your recovery phrase first, then uninstall this app and install the new version.'**
  String get updateNeedsReinstall;

  /// The file that describes the new version could not be read.
  ///
  /// In en, this message translates to:
  /// **'The update information is not valid JSON.'**
  String get updateManifestNotJson;

  /// The file that describes the new version is not laid out as expected.
  ///
  /// In en, this message translates to:
  /// **'The update information has the wrong shape.'**
  String get updateManifestWrongShape;

  /// The file that describes the new version names a different app.
  ///
  /// In en, this message translates to:
  /// **'The update information is for another app.'**
  String get updateManifestOtherApp;

  /// The file that describes the new version lists no install files (APK is Android's app file format).
  ///
  /// In en, this message translates to:
  /// **'The update information lists no APKs.'**
  String get updateManifestNoApks;

  /// The server answered the download with an HTTP error code.
  ///
  /// In en, this message translates to:
  /// **'The download failed (HTTP {status}).'**
  String updateDownloadHttpFailed(int status);

  /// No description provided for @updateDownloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The download is larger than announced.'**
  String get updateDownloadTooLarge;

  /// No description provided for @updateDownloadIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The download is incomplete.'**
  String get updateDownloadIncomplete;

  /// The downloaded file's SHA-256 checksum does not match the one announced, so it is not installed.
  ///
  /// In en, this message translates to:
  /// **'The download is damaged (checksum mismatch).'**
  String get updateDownloadDamaged;

  /// No description provided for @updateDownloadInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The download was interrupted.'**
  String get updateDownloadInterrupted;

  /// The in-app update download failed because its server is not reachable over Tor.
  ///
  /// In en, this message translates to:
  /// **'The update can\'t be downloaded over Tor yet. Turn Tor off to download it, or get it from the download page.'**
  String get updateNoTorDownload;

  /// No description provided for @updateServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the update server.'**
  String get updateServerUnreachable;

  /// Checking for updates got an HTTP error code.
  ///
  /// In en, this message translates to:
  /// **'The update server answered HTTP {status}.'**
  String updateServerHttpStatus(int status);

  /// No description provided for @updateServerTimeout.
  ///
  /// In en, this message translates to:
  /// **'The update server did not answer in time.'**
  String get updateServerTimeout;

  /// No description provided for @updateConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'The connection to the update server failed.'**
  String get updateConnectionFailed;

  /// An update check or install failed for a reason the app does not know.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates failed.'**
  String get updateCheckFailed;

  /// Title of the node and Epicbox server screen. Never names a network: a release runs on one.
  ///
  /// In en, this message translates to:
  /// **'Node and Epicbox'**
  String get setupTitle;

  /// Tooltip of the app bar button on first run and unlock that opens the node and Epicbox screen.
  ///
  /// In en, this message translates to:
  /// **'Node and Epicbox'**
  String get setupNetworkSettingsTooltip;

  /// Heading above the choice of Mainnet, Floonet or Usernet.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get setupNetworkHeading;

  /// Field label: the web address of the node, the Epic Cash server the wallet reads the chain from.
  ///
  /// In en, this message translates to:
  /// **'Node URL'**
  String get setupNodeUrlLabel;

  /// Error under the node URL field. Keep the example URL as it is.
  ///
  /// In en, this message translates to:
  /// **'Enter a full URL such as https://node.example.com'**
  String get setupNodeUrlInvalid;

  /// Button that checks the node URL works.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get setupTestConnection;

  /// Result of a successful connection test. The node is the Epic Cash server the wallet reads the chain from.
  ///
  /// In en, this message translates to:
  /// **'Connected. The node is at block {height}, running version {version}.'**
  String setupTestConnected(String height, String version);

  /// Result of a failed connection test, followed by the reason as one or more sentences.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. {error}'**
  String setupTestFailed(String error);

  /// Screen-reader label of the check icon in front of a successful connection test.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get setupConnectedIconLabel;

  /// Heading above the list of epicbox servers. Epicbox is the relay service that carries payments, a proper name.
  ///
  /// In en, this message translates to:
  /// **'Epicbox server'**
  String get setupRelayHeading;

  /// Under the epicbox server heading: the wallet's address ends with the server's host.
  ///
  /// In en, this message translates to:
  /// **'Your address includes this server.'**
  String get setupRelayHint;

  /// Field label for typing an epicbox server that is not in the list. Keep host:port as it is.
  ///
  /// In en, this message translates to:
  /// **'Other epicbox server (host or host:port)'**
  String get setupCustomRelayLabel;

  /// Tooltip of the check button that selects the typed epicbox server.
  ///
  /// In en, this message translates to:
  /// **'Use this server'**
  String get setupCustomRelayUse;

  /// Error under the epicbox server field. Keep the example host as it is.
  ///
  /// In en, this message translates to:
  /// **'Enter a host such as epicbox.example.com'**
  String get setupCustomRelayInvalid;

  /// Warning shown once a different epicbox server is selected.
  ///
  /// In en, this message translates to:
  /// **'Changing the epicbox server changes your address. Give senders the new address. Payments sent to the old one wait on the old server until you switch back.'**
  String get setupRelayChangeWarning;

  /// No description provided for @setupWalletPerNetwork.
  ///
  /// In en, this message translates to:
  /// **'Each network has its own wallet. A network without one gets a new wallet.'**
  String get setupWalletPerNetwork;

  /// Screen-reader label of the icon of an epicbox server that is working.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get setupRelayHealthyIconLabel;

  /// Screen-reader label of the icon of an epicbox server that is not working.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get setupRelayDownIconLabel;

  /// Under the epicbox server list when the monitoring site could not be read. Keep status.btlabs.uk as it is.
  ///
  /// In en, this message translates to:
  /// **'Server health is unavailable from status.btlabs.uk.'**
  String get setupRelayHealthUnavailable;

  /// Under the epicbox server list: where the up/down information comes from. Keep status.btlabs.uk as it is.
  ///
  /// In en, this message translates to:
  /// **'Health from status.btlabs.uk, measured from its server.'**
  String get setupRelayHealthSource;

  /// Subtitle of an epicbox server the monitoring site does not list.
  ///
  /// In en, this message translates to:
  /// **'Not monitored'**
  String get setupRelayNotMonitored;

  /// First item of an epicbox server's subtitle, a list separated by ' · ' such as 'Up · epicnet.us · official · 99.5% up in the last day': the server is working.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get setupRelayUp;

  /// First item of an epicbox server's subtitle, a list separated by ' · ': the server is not working.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get setupRelayDown;

  /// Item in an epicbox server's subtitle, a list separated by ' · ' such as 'Up · epicnet.us · official': the server is run by a known operator. Lower case in English because it follows other items.
  ///
  /// In en, this message translates to:
  /// **'official'**
  String get setupRelayOfficial;

  /// Last item in an epicbox server's subtitle, a list separated by ' · ': how much of the last 24 hours the server was working.
  ///
  /// In en, this message translates to:
  /// **'{percent}% up in the last day'**
  String setupRelayUptime(String percent);

  /// Title of the screen that restores a wallet from its recovery phrase (the 12 or 24 words).
  ///
  /// In en, this message translates to:
  /// **'Restore wallet'**
  String get restoreTitle;

  /// Label of the field where the user types the 12 or 24 words.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get restorePhraseLabel;

  /// Help under the recovery phrase field. The words themselves are always English.
  ///
  /// In en, this message translates to:
  /// **'All the words (12 to 24), separated by spaces.'**
  String get restorePhraseHelper;

  /// Heading above the choice of a start date or a start block for the scan of the blockchain for the wallet's funds.
  ///
  /// In en, this message translates to:
  /// **'Where to start scanning'**
  String get restoreStartHeading;

  /// Segment button: give the scan's start as a date. Short.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get restoreStartByDate;

  /// Segment button: give the scan's start as a block number. Short.
  ///
  /// In en, this message translates to:
  /// **'Block height'**
  String get restoreStartByHeight;

  /// Field label: the block number the scan starts from.
  ///
  /// In en, this message translates to:
  /// **'Start height (optional)'**
  String get restoreStartHeightLabel;

  /// No description provided for @restoreStartHeightHelper.
  ///
  /// In en, this message translates to:
  /// **'Scan from this block. Leave empty to scan the whole chain.'**
  String get restoreStartHeightHelper;

  /// No description provided for @restoreStartHeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Start height must be a whole number.'**
  String get restoreStartHeightInvalid;

  /// Button after a failed restore that returns to the recovery phrase field.
  ///
  /// In en, this message translates to:
  /// **'Back to the phrase'**
  String get restoreBackToPhrase;

  /// Heading of the date picker for the scan's start.
  ///
  /// In en, this message translates to:
  /// **'When did you create the wallet?'**
  String get restoreDatePickerTitle;

  /// Button that opens the date picker.
  ///
  /// In en, this message translates to:
  /// **'Pick the date you created the wallet'**
  String get restorePickDate;

  /// Button showing the chosen start date of the scan.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String restoreFromDate(String date);

  /// No description provided for @restoreDateHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. If you are not sure, pick an earlier date. A date after your first payment misses funds. Without a date the whole chain is scanned, which takes longer.'**
  String get restoreDateHint;

  /// Under the chosen start date: the block number the scan starts from.
  ///
  /// In en, this message translates to:
  /// **'Scanning starts two days before this date, from block {height}.'**
  String restoreDateStart(String height);

  /// Button that clears the start date.
  ///
  /// In en, this message translates to:
  /// **'Scan the whole chain instead'**
  String get restoreWholeChain;

  /// No description provided for @restoreScanIntro.
  ///
  /// In en, this message translates to:
  /// **'Looking for your funds on the blockchain. Keep the app open until this finishes.'**
  String get restoreScanIntro;

  /// Button after the scan that goes to the wallet's home screen.
  ///
  /// In en, this message translates to:
  /// **'Open wallet'**
  String get restoreOpenWallet;

  /// No description provided for @restoreRescanLater.
  ///
  /// In en, this message translates to:
  /// **'You can run a full rescan later from Settings.'**
  String get restoreRescanLater;

  /// Screen-reader label of the check icon above 'Your wallet is restored'.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get restoreDoneIconLabel;

  /// No description provided for @restoreDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is restored'**
  String get restoreDoneTitle;

  /// Offer to import a payment-history backup after a restore. Keep .wfeh, the backup file's extension, as it is.
  ///
  /// In en, this message translates to:
  /// **'The chain holds your balance, but not who you paid, fees or notes. If you exported a history backup from this wallet, import it now to get them back. It is the .wfeh file you shared or saved outside your old phone.'**
  String get restoreImportExplanation;

  /// No description provided for @restoreImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import a history backup'**
  String get restoreImportButton;

  /// Button that skips the history import and opens the wallet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get restoreImportNotNow;

  /// No description provided for @restoreImportLater.
  ///
  /// In en, this message translates to:
  /// **'You can import one later from Settings.'**
  String get restoreImportLater;

  /// Screen-reader label of the progress bar of a scan of the blockchain for the wallet's funds.
  ///
  /// In en, this message translates to:
  /// **'Scan progress'**
  String get restoreScanProgressLabel;

  /// Title of the first screen after installing, where the user picks a PIN while the wallet is made.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get firstRunTitle;

  /// Button that opens the restore from a recovery phrase instead of making a new wallet.
  ///
  /// In en, this message translates to:
  /// **'I already have a wallet: restore it'**
  String get firstRunRestore;

  /// Shown after the PIN while the wallet is locked under it.
  ///
  /// In en, this message translates to:
  /// **'Securing your wallet…'**
  String get firstRunSecuring;

  /// Button after making the wallet failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get firstRunTryAgain;

  /// Notice after the first run when the fingerprint or face unlock the user asked for could not be enabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock was not set up. You can turn it on in Settings.'**
  String get firstRunBiometricsNotSetUp;

  /// Title of the screen that shows the 12 or 24 words that restore the wallet.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get backupTitle;

  /// Shown in the PIN prompt before the recovery phrase appears.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to show the recovery phrase.'**
  String get backupPinReason;

  /// Warning before the recovery phrase is shown: what a screenshot, photo or other copy of the phrase means.
  ///
  /// In en, this message translates to:
  /// **'A screenshot or photo of the phrase is a full copy of your wallet: anyone who sees it can take your funds, and photo apps may upload it to the cloud. Paper is safest.'**
  String get backupCopyWarning;

  /// Checkbox the user ticks before the recovery phrase can be shown.
  ///
  /// In en, this message translates to:
  /// **'I will keep any copy of the phrase private'**
  String get backupCopyAgree;

  /// Button that asks for the PIN and then shows the recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'Show recovery phrase'**
  String get backupShowPhrase;

  /// Screen-reader label of the warning icon above the recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get backupWarningIconLabel;

  /// Warning above the recovery phrase. count is 12 or 24.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Write these {count} words on paper, in order, and keep them private. They are the only way to restore this wallet.}}'**
  String backupWriteDown(int count);

  /// Screen-reader label of one word of the recovery phrase. The word is always English; number is its position.
  ///
  /// In en, this message translates to:
  /// **'Word {number}: {word}'**
  String backupWordSpoken(int number, String word);

  /// Title of the confirm dialog before the recovery phrase is copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy the recovery phrase?'**
  String get backupCopyTitle;

  /// Text of the confirm dialog before the recovery phrase is copied.
  ///
  /// In en, this message translates to:
  /// **'Anyone with these words can take your funds. Store the copy somewhere safe.'**
  String get backupCopyBody;

  /// Notice after the recovery phrase was copied: the clipboard is cleared after 60 seconds, and when the wallet locks.
  ///
  /// In en, this message translates to:
  /// **'Copied. The clipboard is cleared in 60 seconds.'**
  String get backupCopied;

  /// Notice when the clipboard refused the recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'Not copied. The clipboard refused the text.'**
  String get backupNotCopied;

  /// Title of the screen that opens the wallet with the PIN or biometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock wallet'**
  String get unlockTitle;

  /// Label of the 6-digit PIN field.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// Label of the field that confirms a new 6-digit PIN.
  ///
  /// In en, this message translates to:
  /// **'Repeat PIN'**
  String get pinRepeatLabel;

  /// Heading above the field for a new PIN. digits is 6.
  ///
  /// In en, this message translates to:
  /// **'{digits, plural, other{Choose a {digits}-digit PIN}}'**
  String pinChooseTitle(int digits);

  /// Heading above the field that confirms a new PIN.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get pinConfirmTitle;

  /// Button that goes back from confirming a new PIN to choosing one.
  ///
  /// In en, this message translates to:
  /// **'Choose a different PIN'**
  String get pinChooseDifferent;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match. Choose a PIN again.'**
  String get pinMismatch;

  /// Screen-reader label of the fingerprint icon above the question about fingerprint or face unlock.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get pinBiometricsIconLabel;

  /// Asked after a new PIN, on devices with fingerprint or face recognition.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint or face?'**
  String get pinBiometricsQuestion;

  /// No description provided for @pinBiometricsPinStillWorks.
  ///
  /// In en, this message translates to:
  /// **'You can still use your PIN at any time.'**
  String get pinBiometricsPinStillWorks;

  /// Button answering yes to 'Unlock with fingerprint or face?': turns fingerprint or face unlock on.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get pinBiometricsEnable;

  /// Button answering no to 'Unlock with fingerprint or face?'.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pinBiometricsNotNow;

  /// Error under the PIN field while tries are still checked at once. After the last one, each try waits before it is checked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. 1 try left before a pause.} other{Wrong PIN. {count} tries left before a pause.}}'**
  String pinWrong(int count);

  /// Error under the PIN field after the free tries are used up: each further try waits before the PIN is checked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. The next try is checked after 1 second.} other{Wrong PIN. The next try is checked after {count} seconds.}}'**
  String pinWrongWaitSeconds(int count);

  /// Error under the PIN field after the free tries are used up, for waits of two minutes or more.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. The next try is checked after 1 minute.} other{Wrong PIN. The next try is checked after {count} minutes.}}'**
  String pinWrongWaitMinutes(int count);

  /// Countdown under the PIN field while the wallet waits before it checks a PIN, after repeated wrong PINs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checking the PIN in 1 second…} other{Checking the PIN in {count} seconds…}}'**
  String pinCheckingSeconds(int count);

  /// Countdown under the PIN field, for waits of two minutes or more.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checking the PIN in 1 minute…} other{Checking the PIN in {count} minutes…}}'**
  String pinCheckingMinutes(int count);

  /// Shown under the PIN field when the wait before checking a PIN is over.
  ///
  /// In en, this message translates to:
  /// **'Checking the PIN…'**
  String get pinChecking;

  /// Title of the dialog that asks for the PIN before a protected action.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get pinPromptTitle;

  /// Button that unlocks now with fingerprint or face instead of the PIN.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get pinUseBiometrics;

  /// Button on the unlock screen that explains how to start over.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get pinForgot;

  /// Title of the dialog that deletes the wallet when the PIN is forgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get pinResetTitle;

  /// No description provided for @pinResetBody.
  ///
  /// In en, this message translates to:
  /// **'The PIN cannot be recovered. You can delete this wallet from the device and restore it from its recovery phrase. Without the phrase, its funds are lost for good.'**
  String get pinResetBody;

  /// Checkbox the user must tick before the wallet can be deleted.
  ///
  /// In en, this message translates to:
  /// **'I have my recovery phrase'**
  String get pinResetConfirm;

  /// Dialog button that closes without deleting.
  ///
  /// In en, this message translates to:
  /// **'Keep wallet'**
  String get pinResetKeep;

  /// Dialog button that deletes the wallet from this device.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet'**
  String get pinResetDelete;

  /// Button on the start screen after the wallet could not be found or opened.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get launchTryAgain;

  /// Unlock screen notice when the wallet or its sealed PIN text is missing from the store. Nothing is deleted automatically.
  ///
  /// In en, this message translates to:
  /// **'This wallet could not be read as it should be. Nothing was deleted. Try again after restarting the device. If this stays, you can remove the wallet with “Forgot PIN?” and restore it from its recovery phrase.'**
  String get unlockStranded;

  /// Amount field error.
  ///
  /// In en, this message translates to:
  /// **'The amount cannot be negative.'**
  String get sendAmountNegative;

  /// Amount field error when a typed amount such as '1,234' could be a whole number with a thousands separator or a decimal. asWhole is the whole-number reading, asDecimal the decimal reading in this language's decimal separator.
  ///
  /// In en, this message translates to:
  /// **'Write {asWhole} or {asDecimal}, so the amount is clear.'**
  String sendAmountAmbiguous(String asWhole, String asDecimal);

  /// Amount field error when the thousands separators in a typed amount are misplaced. Write the example number with this language's decimal separator and no thousands separator.
  ///
  /// In en, this message translates to:
  /// **'Write the amount without separators, such as 1234.5, so the amount is clear.'**
  String get sendAmountUnclear;

  /// Amount field error while entering the amount in a fiat currency and no exchange rate is known. EPIC is the coin's ticker.
  ///
  /// In en, this message translates to:
  /// **'No price right now. Enter EPIC instead.'**
  String get sendAmountNoPrice;

  /// Amount field error while entering the amount in a fiat currency. Write the example number with this language's decimal separator.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount such as 10.50'**
  String get sendAmountEnterFiatExample;

  /// Amount field error: more than the 21 million EPIC that will ever exist.
  ///
  /// In en, this message translates to:
  /// **'That is more EPIC than will ever exist. Check the amount.'**
  String get sendAmountTooLarge;

  /// Amount field error.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero.'**
  String get sendAmountZero;

  /// Error under the recipient field when the user entered a wallet URL (http:// or https://). The wallet sends over epicbox and by transaction file only. epicbox is a proper name.
  ///
  /// In en, this message translates to:
  /// **'Payments to a wallet URL are not supported. Ask the recipient for their epicbox address.'**
  String get sendUrlUnsupported;

  /// Tooltip of a button that opens the camera to read an address from a QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrTooltip;

  /// Short button label under the recipient field; opens the camera to read a QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get sendScanButton;

  /// Tooltip of the button that picks the recipient from the address book.
  ///
  /// In en, this message translates to:
  /// **'Choose a contact'**
  String get sendChooseContactTooltip;

  /// Short button label under the recipient field; opens the address book.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get sendContactsButton;

  /// Send form, first choice of how to send: to the recipient's epicbox address. Also Receive's first tab, which shows this wallet's epicbox address. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Epicbox address'**
  String get sendMethodEpicbox;

  /// Send form, second choice of how to send: a payment file the user passes on any way they like, and the recipient's signed reply. Also Receive's second tab, for accepting a payment file.
  ///
  /// In en, this message translates to:
  /// **'Payment file'**
  String get sendMethodFile;

  /// Tooltip and label of the ? button in payment file mode that opens an animated explanation.
  ///
  /// In en, this message translates to:
  /// **'How paying by file works'**
  String get sendFileHelpTooltip;

  /// Label of the amount field. unit is EPIC or a currency code.
  ///
  /// In en, this message translates to:
  /// **'Amount ({unit})'**
  String sendAmountLabel(String unit);

  /// Small button inside the amount field that switches the amount between EPIC and a fiat currency. Space is tight.
  ///
  /// In en, this message translates to:
  /// **'Use {unit}'**
  String sendUseUnit(String unit);

  /// Small button inside the amount field that fills in the most that can be sent. Space is tight.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get sendMax;

  /// Counter under the message field: how much of the message's size limit is used, in bytes. Most letters count 1, accented letters 2, Chinese characters 3.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit}'**
  String sendMessageCounter(int used, int limit);

  /// Heading of a section that expands to exchange the transaction as text instead of a file.
  ///
  /// In en, this message translates to:
  /// **'Copy and paste instead'**
  String get sendCopyPasteInstead;

  /// Title of a box with the payment's text (the slate, JSON) to copy to the recipient.
  ///
  /// In en, this message translates to:
  /// **'Transaction text'**
  String get sendSlateBoxTitle;

  /// Label of the field for the text the recipient sent back.
  ///
  /// In en, this message translates to:
  /// **'Paste the recipient\'s response'**
  String get sendPasteResponseLabel;

  /// Error when finishing a payment with the response field empty.
  ///
  /// In en, this message translates to:
  /// **'Paste the response text from the recipient.'**
  String get sendPasteResponseMissing;

  /// Button that completes a payment with the recipient's answer and sends it to the network.
  ///
  /// In en, this message translates to:
  /// **'Finish payment'**
  String get slateFinishPayment;

  /// After an epicbox send. 'Cancel payment' is the button on the payment's details screen; use the same words.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{If it is still not completed after 1 day, it cancels by itself and the amount unlocks. To stop it sooner, open the payment and tap Cancel payment.} other{If it is still not completed after {days} days, it cancels by itself and the amount unlocks. To stop it sooner, open the payment and tap Cancel payment.}}'**
  String sendResultAutoCancel(int days);

  /// After a send whose fee differs from the one shown in the review.
  ///
  /// In en, this message translates to:
  /// **'The fee charged was {charged}, not the {reviewed} shown before, because the wallet picked its coins again when sending.'**
  String sendResultFeeChanged(String charged, String reviewed);

  /// No description provided for @sendResultNoteNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The note could not be saved. You can add it by opening the payment.'**
  String get sendResultNoteNotSaved;

  /// Button after a send that opens the matching help answer.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get sendHelp;

  /// Row label in the payment review: amount plus fee. Space is tight (about 9 characters).
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get sendReviewTotal;

  /// The total in the payment review with its value in a fiat currency.
  ///
  /// In en, this message translates to:
  /// **'{amount} (≈ {fiat})'**
  String sendReviewTotalWithFiat(String amount, String fiat);

  /// Button in the payment review that sends the payment.
  ///
  /// In en, this message translates to:
  /// **'Send {amount}'**
  String sendReviewSendButton(String amount);

  /// Button in the payment review that goes back to change the payment.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sendReviewEdit;

  /// Title of the screen that opens a transaction file (a file holding a payment's slate, JSON) to accept or finish it.
  ///
  /// In en, this message translates to:
  /// **'Transaction file'**
  String get slateFileTitle;

  /// No description provided for @slateWrongPayment.
  ///
  /// In en, this message translates to:
  /// **'This response is for a different payment. Open the file the recipient returned for this send.'**
  String get slateWrongPayment;

  /// No description provided for @slateInvoiceUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Payment requests (invoices) are not supported yet.'**
  String get slateInvoiceUnsupported;

  /// No description provided for @slateNotTransactionFile.
  ///
  /// In en, this message translates to:
  /// **'That file is not a transaction file.'**
  String get slateNotTransactionFile;

  /// Screen reader label of the spinner while a transaction file is being read.
  ///
  /// In en, this message translates to:
  /// **'Reading the file'**
  String get slateReading;

  /// No description provided for @slateFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large to be a transaction file.'**
  String get slateFileTooLarge;

  /// No description provided for @slatePostedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} sent to the network.'**
  String slatePostedHeadline(String amount);

  /// 'Completed' is the payment's status chip (txStatusCompleted); use the same word.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{It shows as Completed after 1 confirmation.} other{It shows as Completed after {count} confirmations.}}'**
  String slatePostedBody(int count);

  /// After accepting a payment from a file: the answer file to give back.
  ///
  /// In en, this message translates to:
  /// **'Accepted. Return {file} to the sender.'**
  String slateAcceptedHeadline(String file);

  /// No description provided for @slateAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'The {amount} arrive once the sender finishes the payment and it is on the chain.'**
  String slateAcceptedBody(String amount);

  /// A transaction file this wallet accepted before was opened again: the same answer file can be given back; nothing new happened.
  ///
  /// In en, this message translates to:
  /// **'Already accepted. Return {file} to the sender again.'**
  String slateRepeatedHeadline(String file);

  /// Body under slateRepeatedHeadline: the payment was accepted before; this is the same answer, not a second payment.
  ///
  /// In en, this message translates to:
  /// **'You accepted this payment before, so this is the same answer, not a second payment. The {amount} arrive once the sender finishes it and it is on the chain.'**
  String slateRepeatedBody(String amount);

  /// A transaction file that pays this wallet.
  ///
  /// In en, this message translates to:
  /// **'Someone is sending you {amount}.'**
  String slateIncomingSend(String amount);

  /// A transaction file that answers a payment this wallet started.
  ///
  /// In en, this message translates to:
  /// **'The recipient\'s answer to your send of {amount} (fee {fee}).'**
  String slateIncomingResponse(String amount, String fee);

  /// No description provided for @slateIncomingSendHint.
  ///
  /// In en, this message translates to:
  /// **'Accept it, then return the response file to the sender.'**
  String get slateIncomingSendHint;

  /// No description provided for @slateIncomingResponseHint.
  ///
  /// In en, this message translates to:
  /// **'Finish it to send the payment to the network.'**
  String get slateIncomingResponseHint;

  /// Button that signs a payment received in a file.
  ///
  /// In en, this message translates to:
  /// **'Accept payment'**
  String get slateAcceptPayment;

  /// Notice when saving or sharing a transaction file failed.
  ///
  /// In en, this message translates to:
  /// **'Could not hand over {file}. Please try again.'**
  String slateHandOverFailed(String file);

  /// Button that saves a transaction file where the user picks (Downloads, Drive, a USB stick).
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get slateSaveToDevice;

  /// Notice after a transaction file was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {file}'**
  String slateSaved(String file);

  /// Title of the system dialog that saves a transaction file.
  ///
  /// In en, this message translates to:
  /// **'Save transaction file'**
  String get slateSaveDialogTitle;

  /// Title of the system dialog that picks a transaction file.
  ///
  /// In en, this message translates to:
  /// **'Open transaction file'**
  String get slateOpenDialogTitle;

  /// Headline when a finished payment was not accepted by the network yet.
  ///
  /// In en, this message translates to:
  /// **'Not on the network yet'**
  String get slateNotPostedTitle;

  /// No description provided for @slateNotPostedBody.
  ///
  /// In en, this message translates to:
  /// **'The payment is finished but the network has not taken it yet. It will be broadcast again from the payment. Do not send it again.'**
  String get slateNotPostedBody;

  /// Button that opens the payment's details screen.
  ///
  /// In en, this message translates to:
  /// **'Open the payment'**
  String get slateOpenPayment;

  /// Title of the camera screen that reads a QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrTitle;

  /// Shown over the camera picture.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the recipient\'s QR code.'**
  String get scanQrHint;

  /// No description provided for @scanQrCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The wallet may not use the camera. To scan, allow camera access for this app in your phone\'s settings. You can also paste the address instead.'**
  String get scanQrCameraDenied;

  /// No description provided for @scanQrCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start. Paste the address instead, or try again.'**
  String get scanQrCameraFailed;

  /// Button that starts the camera again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanQrTryAgain;

  /// Button that leaves the camera screen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get scanQrBack;

  /// Title of the address book screen.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// Title of the address book when it was opened to pick a recipient.
  ///
  /// In en, this message translates to:
  /// **'Choose a contact'**
  String get contactsPickTitle;

  /// Floating button on the address book.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get contactsAdd;

  /// No description provided for @contactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet. Add the people you pay often, so you do not have to paste their address each time.'**
  String get contactsEmpty;

  /// Label of the search field on the address book.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get contactsSearchLabel;

  /// The address book search found nothing.
  ///
  /// In en, this message translates to:
  /// **'No contact matches.'**
  String get contactsNoMatch;

  /// Error under the contact's name field.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get contactsNameMissing;

  /// Title of the dialog that confirms deleting a contact.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String contactsDeleteTitle(String name);

  /// No description provided for @contactsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The address is removed from your contacts. Past payments are not affected.'**
  String get contactsDeleteBody;

  /// Dialog button that does not delete the contact.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get contactsKeep;

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get contactsEditTitle;

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get contactsNewTitle;

  /// Tooltip of the delete icon on the contact screen.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get contactsDeleteTooltip;

  /// Label of the contact's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactsNameLabel;

  /// Label of the contact's address field, which holds an epicbox address. epicbox is a proper name.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get contactsAddressLabel;

  /// No description provided for @contactsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This address is already saved as {name}.'**
  String contactsDuplicate(String name);

  /// Label of the field for a note on the contact.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get contactsNoteLabel;

  /// Button that saves the contact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get contactsSave;

  /// Error under a recipient or contact address field left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter their address.'**
  String get contactsAddressMissing;

  /// Error under an address field holding an incomplete web address.
  ///
  /// In en, this message translates to:
  /// **'Enter the full wallet URL, such as {example}'**
  String contactsUrlIncomplete(String example);

  /// Error under an address field. example shows the shape of an epicbox address.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid address. It looks like {example}'**
  String contactsAddressInvalid(String example);

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section header above the Node and Epicbox row.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get settingsSectionNetwork;

  /// Settings row that opens the node and Epicbox screen; its subtitle is the node host.
  ///
  /// In en, this message translates to:
  /// **'Node and Epicbox'**
  String get settingsNetworkAndNode;

  /// Under the Network and node row: the network's name and the node's host name.
  ///
  /// In en, this message translates to:
  /// **'{network} · {node}'**
  String settingsNetworkSubtitle(String network, String node);

  /// Section heading in settings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsSectionDisplay;

  /// Settings row, and the title of its dialog, that picks the currency prices are shown in.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// A display currency: its name and its code.
  ///
  /// In en, this message translates to:
  /// **'{name} ({code})'**
  String settingsCurrencyWithCode(String name, String code);

  /// Settings switch that turns fiat prices of EPIC on and off.
  ///
  /// In en, this message translates to:
  /// **'Show prices'**
  String get settingsShowPrices;

  /// Settings switch that shows amounts as dots.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get settingsHideBalances;

  /// Settings row, and the title of its dialog, that picks light or dark colours.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme choice that follows the phone's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'Same as the device'**
  String get settingsThemeSystem;

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Short notice after prices are turned on. CoinGecko is a price service (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Prices come from CoinGecko, which sees your IP address.'**
  String get settingsPricesOnNotice;

  /// Section heading in settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// Under the payment notifications switch, in red, after the phone denied notification permission. No full stop, like the original.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked in system settings'**
  String get settingsPushBlocked;

  /// Under the payment notifications switch, in red, after the notification service failed to start. No full stop, like the original.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not available in this build'**
  String get settingsPushUnavailable;

  /// Section heading in settings.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// Settings row that opens the screen for a new 6-digit PIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsChangePin;

  /// Settings switch: unlock with fingerprint or face instead of the PIN.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get settingsBiometrics;

  /// Short notice.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock turned on'**
  String get settingsBiometricsOn;

  /// Short notice.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock turned off'**
  String get settingsBiometricsOff;

  /// Short notice after turning on biometric unlock failed or was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock was not set up'**
  String get settingsBiometricsFailed;

  /// In the PIN dialog shown before biometric unlock is turned on.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to turn on biometric unlock.'**
  String get settingsBiometricsPinReason;

  /// Settings row, and the title of its dialog, that picks when the wallet locks by itself after the app goes to the background.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get settingsAutoLock;

  /// Settings row that shows the 12 or 24 recovery words to write down.
  ///
  /// In en, this message translates to:
  /// **'Back up recovery phrase'**
  String get settingsBackupPhrase;

  /// Notice after the user proved they wrote down the recovery words.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase confirmed'**
  String get settingsPhraseConfirmed;

  /// Settings row that closes the wallet until the PIN is entered again.
  ///
  /// In en, this message translates to:
  /// **'Lock wallet'**
  String get settingsLockWallet;

  /// Section heading in settings. The help page refers to it by this name.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get settingsSectionHistory;

  /// Settings row: save an encrypted copy of payment notes, contacts and dates.
  ///
  /// In en, this message translates to:
  /// **'Export history backup'**
  String get settingsExportHistory;

  /// Settings row: save the payment history as a spreadsheet (CSV) file.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCsv;

  /// Settings row: open a history backup file. The help page refers to it by this name.
  ///
  /// In en, this message translates to:
  /// **'Import history backup'**
  String get settingsImportHistory;

  /// Section heading in settings.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get settingsSectionWallet;

  /// Settings row that opens the address book.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get settingsContacts;

  /// Settings section header for invoices from trusted services.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get settingsSectionInvoices;

  /// Settings row that opens the invoice settings.
  ///
  /// In en, this message translates to:
  /// **'Invoice address and trusted services'**
  String get settingsInvoices;

  /// Tooltip of the Invoice address and trusted services row (its info icon).
  ///
  /// In en, this message translates to:
  /// **'Let services you trust bill you. You approve every invoice.'**
  String get settingsInvoicesSubtitle;

  /// Title of the invoice settings screen.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoiceSettingsTitle;

  /// Heading above the invoice address and its QR code.
  ///
  /// In en, this message translates to:
  /// **'Your invoice address'**
  String get invoiceSettingsAddressTitle;

  /// Explains the invoice address, which is separate from the receive address.
  ///
  /// In en, this message translates to:
  /// **'Give this address to a service you trust, so it can send you invoices. Your address for payments stays the same.'**
  String get invoiceSettingsAddressBody;

  /// Screen reader label of the invoice address QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code of your invoice address'**
  String get invoiceSettingsQrLabel;

  /// Notice after copying the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Invoice address copied.'**
  String get invoiceSettingsAddressCopied;

  /// Heading above the list of services allowed to send invoices.
  ///
  /// In en, this message translates to:
  /// **'Trusted services'**
  String get invoiceSettingsServicesTitle;

  /// Shown when no service is allowed to send invoices.
  ///
  /// In en, this message translates to:
  /// **'No trusted services yet. Invoices from anyone else never reach you.'**
  String get invoiceSettingsNoServices;

  /// Button that opens the form to add a trusted service.
  ///
  /// In en, this message translates to:
  /// **'Add a service'**
  String get invoiceSettingsAddService;

  /// Tooltip of the button that removes a trusted service.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String invoiceSettingsRemoveTooltip(String name);

  /// Title of the dialog that confirms removing a trusted service.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String invoiceSettingsRemoveTitle(String name);

  /// Body of the dialog that confirms removing a trusted service.
  ///
  /// In en, this message translates to:
  /// **'This service can no longer send you invoices. Payments you already made are not affected.'**
  String get invoiceSettingsRemoveBody;

  /// Dialog button that leaves the invoice settings as they are.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get invoiceSettingsKeep;

  /// Dialog button that removes a trusted service.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get invoiceSettingsRemoveConfirm;

  /// Notice after removing a trusted service.
  ///
  /// In en, this message translates to:
  /// **'{name} can no longer send you invoices.'**
  String invoiceSettingsRemoved(String name);

  /// Advanced settings row that replaces the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Get a new invoice address'**
  String get invoiceSettingsRotate;

  /// Hint under the row that replaces the invoice address.
  ///
  /// In en, this message translates to:
  /// **'The current one stops working.'**
  String get invoiceSettingsRotateHint;

  /// Title of the dialog that confirms replacing the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Get a new invoice address?'**
  String get invoiceSettingsRotateTitle;

  /// Body of the dialog that confirms replacing the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Your current invoice address stops working for good. Every service that bills you needs the new one.'**
  String get invoiceSettingsRotateBody;

  /// Dialog button that replaces the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Get new address'**
  String get invoiceSettingsRotateConfirm;

  /// Notice after the invoice address was replaced.
  ///
  /// In en, this message translates to:
  /// **'New invoice address ready. Give it to your services.'**
  String get invoiceSettingsRotated;

  /// Advanced readout: messages to the invoice address from senders not on the list, dropped unread.
  ///
  /// In en, this message translates to:
  /// **'Dropped from unknown senders this session: {count}'**
  String invoiceSettingsDropped(int count);

  /// Title of the form that adds a trusted service.
  ///
  /// In en, this message translates to:
  /// **'Add a trusted service'**
  String get invoiceSettingsAddTitle;

  /// Explains, in two sentences, what adding a trusted service allows.
  ///
  /// In en, this message translates to:
  /// **'A trusted service can send invoices to your invoice address; messages from anyone else are dropped. Nothing is paid until you approve each invoice with your PIN or fingerprint.'**
  String get invoiceSettingsAddExplanation;

  /// Label of the field for the user's own name for a service.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get invoiceSettingsLabelLabel;

  /// Field error when the service name is empty.
  ///
  /// In en, this message translates to:
  /// **'Give the service a name.'**
  String get invoiceSettingsLabelMissing;

  /// Label of the field for the address a service shows.
  ///
  /// In en, this message translates to:
  /// **'The service\'s epicbox address'**
  String get invoiceSettingsServiceAddressLabel;

  /// Field error when the service address is empty.
  ///
  /// In en, this message translates to:
  /// **'Paste or scan the address the service shows.'**
  String get invoiceSettingsAddressMissing;

  /// Button that saves a trusted service.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get invoiceSettingsAddButton;

  /// Notice after adding a trusted service.
  ///
  /// In en, this message translates to:
  /// **'{name} can now send you invoices.'**
  String invoiceSettingsAdded(String name);

  /// Settings row: search the blockchain for the wallet's funds again.
  ///
  /// In en, this message translates to:
  /// **'Rescan the chain'**
  String get settingsRescan;

  /// Short notice.
  ///
  /// In en, this message translates to:
  /// **'Rescan finished'**
  String get settingsRescanFinished;

  /// Title of the dialog that starts a new search of the blockchain for the wallet's funds.
  ///
  /// In en, this message translates to:
  /// **'Rescan the chain'**
  String get settingsRescanTitle;

  /// No description provided for @settingsRescanBody.
  ///
  /// In en, this message translates to:
  /// **'The wallet looks for its funds again. An earlier start finds more but takes longer; the whole chain can take a long time.'**
  String get settingsRescanBody;

  /// Choice in the rescan dialog: start at the block of a picked day.
  ///
  /// In en, this message translates to:
  /// **'From a date'**
  String get settingsRescanFromDate;

  /// Choice in the rescan dialog: start at a block number.
  ///
  /// In en, this message translates to:
  /// **'From a block height'**
  String get settingsRescanFromHeight;

  /// Choice in the rescan dialog: start at the first block.
  ///
  /// In en, this message translates to:
  /// **'The whole chain'**
  String get settingsRescanWholeChain;

  /// Button in the rescan dialog that opens a calendar.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get settingsRescanPickDate;

  /// Error in the rescan dialog.
  ///
  /// In en, this message translates to:
  /// **'Pick a date first.'**
  String get settingsRescanPickDateFirst;

  /// Label of the block number field in the rescan dialog.
  ///
  /// In en, this message translates to:
  /// **'Start height'**
  String get settingsRescanStartHeight;

  /// Error in the rescan dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter a block height of 1 or more.'**
  String get settingsRescanHeightInvalid;

  /// Button that starts the rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get settingsRescanButton;

  /// Settings row, in red.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet'**
  String get settingsDeleteWallet;

  /// Notice when delete is tapped while a search of the blockchain runs.
  ///
  /// In en, this message translates to:
  /// **'Wait for the scan to finish before deleting the wallet.'**
  String get settingsDeleteDuringScan;

  /// In the PIN dialog shown before the wallet is deleted.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to delete this wallet.'**
  String get settingsDeletePinReason;

  /// Screen-reader label of the warning icon in the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get settingsDeleteWarningIcon;

  /// Title of the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet?'**
  String get settingsDeleteTitle;

  /// No description provided for @settingsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the wallet, its history and its PIN from this device. Only the recovery phrase can bring the funds back. Without it, they are lost for good.'**
  String get settingsDeleteBody;

  /// Checkbox in the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'I have written down my recovery phrase'**
  String get settingsDeleteHavePhrase;

  /// The word the user must type to confirm deleting the wallet. One word, easy to type on a phone keyboard; case does not matter.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get settingsDeleteConfirmWord;

  /// Label of the field in the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Type \"{word}\" to confirm'**
  String settingsDeleteTypeToConfirm(String word);

  /// Button that closes the delete dialog without deleting.
  ///
  /// In en, this message translates to:
  /// **'Keep wallet'**
  String get settingsDeleteKeep;

  /// Red button that deletes the wallet.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet'**
  String get settingsDeleteConfirm;

  /// Section heading in settings.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Settings row showing the app's version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Settings row in About showing which network the wallet is on (Mainnet, Floonet, Usernet).
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsAboutNetwork;

  /// Settings row showing the epicbox server's host. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Epicbox server'**
  String get settingsEpicboxServer;

  /// First row of Settings while a newer app version is available; Install is beside it.
  ///
  /// In en, this message translates to:
  /// **'Update to {version}'**
  String settingsUpdateTo(String version);

  /// Button on the Settings row that offers a newer app version; downloads and installs it.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get settingsUpdateInstall;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdates;

  /// Settings row that opens the help page.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// Settings row that opens the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsSendFeedback;

  /// Tooltip of the Send feedback row (its info icon).
  ///
  /// In en, this message translates to:
  /// **'Report a problem or suggest an idea'**
  String get settingsSendFeedbackHint;

  /// Settings row with the link to the app's source code.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSourceCode;

  /// Settings › About row that opens the short Licences screen: the app, Flutter, LEPIC, Tor and the fonts in one line each, with a link to every full text.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get settingsLicences;

  /// Licences screen: the first paragraph.
  ///
  /// In en, this message translates to:
  /// **'Open-source software in this wallet. Each component keeps its own licence; the full texts are one tap away.'**
  String get licencesLead;

  /// Licences screen: the wallet itself. Not "app" on its own: the web demo shows this screen too.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash Mobile by BT Labs: Apache-2.0.'**
  String get licencesApp;

  /// Licences screen: one line for Flutter and the Dart packages.
  ///
  /// In en, this message translates to:
  /// **'Flutter and its Dart packages: BSD 3-Clause and similar permissive licences.'**
  String get licencesFlutter;

  /// Licences screen: one line for LEPIC and its key Rust crates. Keep the crate names as they are.
  ///
  /// In en, this message translates to:
  /// **'LEPIC, the Epic Cash wallet library: Apache 2.0, with the Epic Cash secp256k1-zkp fork (CC0) and Rust crates under MIT or Apache 2.0, among them tokio, rustls, rusqlite and blake2.'**
  String get licencesLepic;

  /// Licences screen: one line for Tor; the English source note with the version and URLs follows it.
  ///
  /// In en, this message translates to:
  /// **'Tor: GNU General Public License, version 3. Its source is named below.'**
  String get licencesTor;

  /// Licences screen: one line for the bundled fonts. Keep the font names as they are.
  ///
  /// In en, this message translates to:
  /// **'Fonts Montserrat, JetBrains Mono and Noto Sans Thai: SIL Open Font License 1.1.'**
  String get licencesFonts;

  /// Licences screen button that opens the full texts of every licence (Flutter’s licence page).
  ///
  /// In en, this message translates to:
  /// **'All licence texts'**
  String get licencesFull;

  /// Screen-reader label of the copy icon on a link row.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get settingsCopyLink;

  /// Notice after a web link was copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get settingsLinkCopied;

  /// Title of the screen that sets a new 6-digit PIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsPinTitle;

  /// Heading above the PIN field.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get settingsPinEnterCurrent;

  /// Label of the PIN field.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get settingsPinCurrentLabel;

  /// Heading above the field for the new PIN.
  ///
  /// In en, this message translates to:
  /// **'{digits, plural, other{Choose a new {digits}-digit PIN}}'**
  String settingsPinChooseNew(int digits);

  /// Short notice.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get settingsPinChanged;

  /// Notice after a PIN change when the fingerprint or face prompt that updates biometric unlock was dismissed.
  ///
  /// In en, this message translates to:
  /// **'PIN changed. Biometric unlock is off; turn it on again below.'**
  String get settingsPinChangedBiometricsOff;

  /// Title of the help page.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// Heading at the end of the help page.
  ///
  /// In en, this message translates to:
  /// **'Still stuck?'**
  String get helpStillStuck;

  /// Under the Still stuck? heading.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened or what is unclear.'**
  String get helpTellUs;

  /// Button at the end of the help page that opens the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get helpSendFeedback;

  /// Title of the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackTitle;

  /// First line of the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Describe what went wrong or what could be better.'**
  String get feedbackIntro;

  /// Label of the message field.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get feedbackMessageLabel;

  /// Error under an empty message field.
  ///
  /// In en, this message translates to:
  /// **'Write a few words about what happened.'**
  String get feedbackMessageMissing;

  /// Label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Email for a reply (optional)'**
  String get feedbackEmailLabel;

  /// Error under the email field.
  ///
  /// In en, this message translates to:
  /// **'This does not look like an email address.'**
  String get feedbackEmailInvalid;

  /// Switch: add the app's log to the report.
  ///
  /// In en, this message translates to:
  /// **'Attach diagnostic logs'**
  String get feedbackAttachLogs;

  /// Under the Attach diagnostic logs switch.
  ///
  /// In en, this message translates to:
  /// **'Logs help find the problem. The recovery phrase, PIN and other secrets are removed first.'**
  String get feedbackAttachLogsHint;

  /// Button that shows the report's full text. The report itself stays in English.
  ///
  /// In en, this message translates to:
  /// **'Preview what is sent'**
  String get feedbackPreviewButton;

  /// Button that sends the report to the feedback server.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// Button under Send: hand the report over as a file instead.
  ///
  /// In en, this message translates to:
  /// **'Share or save instead'**
  String get feedbackShareOrSaveInstead;

  /// Shown above the Share or save button in builds without a feedback server.
  ///
  /// In en, this message translates to:
  /// **'Your feedback becomes a text file you can send by email or chat, or save.'**
  String get feedbackFileExplanation;

  /// Button that hands the report over as a text file.
  ///
  /// In en, this message translates to:
  /// **'Share or save'**
  String get feedbackShareOrSave;

  /// Under Share in the sheet that picks where the report file goes.
  ///
  /// In en, this message translates to:
  /// **'Send it by email or a chat app'**
  String get feedbackShareHint;

  /// Choice in the sheet that picks where the report file goes.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get feedbackSaveToDevice;

  /// Title of the system dialog that picks where to save the report file (desktop).
  ///
  /// In en, this message translates to:
  /// **'Save feedback'**
  String get feedbackSaveDialogTitle;

  /// Notice after the report file was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String feedbackSavedFile(String name);

  /// Notice after the report reached the feedback server.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your feedback was sent.'**
  String get feedbackSent;

  /// Notice after the report file was handed to another app.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback.'**
  String get feedbackThanks;

  /// Error: the feedback server refused the report. status is an HTTP status code such as 503.
  ///
  /// In en, this message translates to:
  /// **'The feedback server answered {status}.'**
  String feedbackServerAnswered(int status);

  /// Error: the feedback server timed out.
  ///
  /// In en, this message translates to:
  /// **'The feedback server did not answer.'**
  String get feedbackServerNoAnswer;

  /// Error: no connection to the feedback server.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the feedback server.'**
  String get feedbackServerUnreachable;

  /// Title of the screen that shows the report's full text, which stays in English.
  ///
  /// In en, this message translates to:
  /// **'What is sent'**
  String get feedbackPreviewTitle;

  /// Settings switch that shows the technical controls (network, node, epicbox server, transaction files, logs) across the app. Off by default.
  ///
  /// In en, this message translates to:
  /// **'Advanced options'**
  String get settingsAdvancedOptions;

  /// Tooltip of the Advanced options switch (its info icon).
  ///
  /// In en, this message translates to:
  /// **'Technical details, files and logs'**
  String get settingsAdvancedOptionsSubtitle;

  /// Settings section header above the status.btlabs.uk switch.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// Settings group on the phone's Settings hub: the Tor switch, the status site and the node and Epicbox servers.
  ///
  /// In en, this message translates to:
  /// **'Privacy & network'**
  String get settingsSectionPrivacyNetwork;

  /// Settings group on the phone's Settings hub: opens Help, which starts with Send feedback.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get settingsSectionHelpFeedback;

  /// State line under the Security group while the recovery phrase has not been backed up.
  ///
  /// In en, this message translates to:
  /// **'Back up your recovery phrase'**
  String get settingsStateBackUp;

  /// State line under the Back up recovery phrase row on the Security page while the phrase has not been backed up.
  ///
  /// In en, this message translates to:
  /// **'Not backed up yet'**
  String get settingsStateNotBackedUp;

  /// State line under the Security group: the wallet unlocks with the PIN only.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get settingsStatePin;

  /// State line under the Security group: the wallet unlocks with the PIN or biometrics.
  ///
  /// In en, this message translates to:
  /// **'PIN and biometrics'**
  String get settingsStatePinBiometrics;

  /// Two state words on one line under a Settings group, with a middle dot between them.
  ///
  /// In en, this message translates to:
  /// **'{a} · {b}'**
  String settingsStateJoin(String a, String b);

  /// Settings switch: read server health and node lists from the status.btlabs.uk monitor. Keep status.btlabs.uk as it is.
  ///
  /// In en, this message translates to:
  /// **'Use status.btlabs.uk'**
  String get settingsUseStatusSite;

  /// Tooltip of the Use status.btlabs.uk switch (its info icon). Keep status.btlabs.uk as it is.
  ///
  /// In en, this message translates to:
  /// **'Network status and information provided by status.btlabs.uk'**
  String get settingsUseStatusSiteSubtitle;

  /// Payment details timeline, first step of a send: we created it and set the funds aside.
  ///
  /// In en, this message translates to:
  /// **'Payment started'**
  String get txStepStarted;

  /// Payment details timeline, a send: the recipient's wallet signed it. Shown once it happened.
  ///
  /// In en, this message translates to:
  /// **'Recipient accepted'**
  String get txStepAccepted;

  /// Payment details timeline, a send: the finished payment was posted to the chain.
  ///
  /// In en, this message translates to:
  /// **'Sent to the network'**
  String get txStepPosted;

  /// Payment details timeline: the confirmation step, before it has started. Short.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get txStepConfirming;

  /// Payment details timeline: the confirmation step, once enough blocks confirmed the payment.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get txStepConfirmed;

  /// Payment details timeline, first step of an incoming payment: our wallet signed it and sent it back.
  ///
  /// In en, this message translates to:
  /// **'Payment arrived'**
  String get txStepArrived;

  /// Payment details timeline, an incoming payment: the sender finished it and posted it to the chain.
  ///
  /// In en, this message translates to:
  /// **'Sender finished it'**
  String get txStepSenderFinished;

  /// Title of the sheet that explains, with an animation, how paying by file works: one wallet makes a file, the other signs it and sends it back.
  ///
  /// In en, this message translates to:
  /// **'How a payment file works'**
  String get fileHelpTitle;

  /// Label under the figure that stands for the user in the payment file animation.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get fileHelpYou;

  /// Label under the figure that stands for the other person in the payment file animation.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get fileHelpFriend;

  /// Payment file animation, told by the person who pays, step 1 of 4.
  ///
  /// In en, this message translates to:
  /// **'You make a payment file.'**
  String get fileHelpSendStep1;

  /// Payment file animation, sender's side, step 2 of 4.
  ///
  /// In en, this message translates to:
  /// **'You send it to your friend any way you like, such as a chat or an email.'**
  String get fileHelpSendStep2;

  /// Payment file animation, sender's side, step 3 of 4. The reply is a second file.
  ///
  /// In en, this message translates to:
  /// **'Your friend opens it in their wallet and sends you back the signed reply.'**
  String get fileHelpSendStep3;

  /// Payment file animation, sender's side, step 4 of 4.
  ///
  /// In en, this message translates to:
  /// **'You open the reply, and the payment is on its way.'**
  String get fileHelpSendStep4;

  /// Payment file animation, told by the person who gets paid, step 1 of 4.
  ///
  /// In en, this message translates to:
  /// **'Your friend makes a payment file for you.'**
  String get fileHelpReceiveStep1;

  /// Payment file animation, receiver's side, step 2 of 4.
  ///
  /// In en, this message translates to:
  /// **'They send it to you any way they like, such as a chat or an email.'**
  String get fileHelpReceiveStep2;

  /// Payment file animation, receiver's side, step 3 of 4. The reply is a second file.
  ///
  /// In en, this message translates to:
  /// **'You open it in your wallet and send back the signed reply.'**
  String get fileHelpReceiveStep3;

  /// Payment file animation, receiver's side, step 4 of 4.
  ///
  /// In en, this message translates to:
  /// **'Your friend opens the reply, and the payment is on its way to you.'**
  String get fileHelpReceiveStep4;

  /// Screen-reader label of the dots under the payment file animation.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {count}'**
  String fileHelpStepOf(int step, int count);

  /// Screen-reader label of the payment file animation while it plays; a tap pauses it.
  ///
  /// In en, this message translates to:
  /// **'Pause the animation'**
  String get fileHelpPause;

  /// Screen-reader label of the payment file animation while it is paused; a tap plays it.
  ///
  /// In en, this message translates to:
  /// **'Play the animation'**
  String get fileHelpPlay;

  /// Web demo: under the six dots that fill in the demo wallet's fixed PIN on first run, unlock and PIN prompts. Also the screen-reader announcement.
  ///
  /// In en, this message translates to:
  /// **'Demo PIN, filled in for you'**
  String get demoPinFilled;

  /// Web demo: button that stops the PIN fill animation and goes on at once.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get demoPinSkip;

  /// Web demo: heading of the first run while the demo PIN fills in and the wallet is created. Replaces the usual title with its network name.
  ///
  /// In en, this message translates to:
  /// **'Setting up your demo wallet'**
  String get demoPinSetUpTitle;

  /// Web demo: heading of the unlock screen while the demo PIN fills in. The usual title returns with the PIN field.
  ///
  /// In en, this message translates to:
  /// **'Opening your demo wallet'**
  String get demoPinUnlockTitle;

  /// Send, step 1: heading of the step where the user enters who to pay.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get sendStepRecipient;

  /// Send, step 2: heading of the step where the user enters how much.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sendStepAmount;

  /// Send, step 3: heading of the step that shows the payment before it is sent.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get sendStepReview;

  /// Send: which step of the three the user is on, beside the step heading.
  ///
  /// In en, this message translates to:
  /// **'{step} of {total}'**
  String sendStepOf(int step, int total);

  /// Send: tooltip and label of the info button that opens the animated explanation of how an Epic payment works; also the heading of that sheet.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get sendHowItWorks;

  /// Send, step 1: label of the field for the recipient's address.
  ///
  /// In en, this message translates to:
  /// **'Epic address'**
  String get sendAddressLabel;

  /// Send, step 1: shown when Continue is tapped with an empty address field.
  ///
  /// In en, this message translates to:
  /// **'Enter their address.'**
  String get sendAddressMissing;

  /// Send, step 1: the pasted text is a web URL; the wallet only pays Epic addresses or by file.
  ///
  /// In en, this message translates to:
  /// **'This is a web link, not an Epic address.'**
  String get sendAddressWebLink;

  /// Send, step 1: the text looks like the start of an Epic address but is too short or lacks its server part.
  ///
  /// In en, this message translates to:
  /// **'This address looks incomplete.'**
  String get sendAddressIncomplete;

  /// Send, step 1: the text is not a valid Epic address for this network.
  ///
  /// In en, this message translates to:
  /// **'This is not an Epicbox address.'**
  String get sendAddressNotEpic;

  /// Send: shown on the recipient card instead of a name when the address is not in the user's contacts.
  ///
  /// In en, this message translates to:
  /// **'New recipient'**
  String get sendNewRecipient;

  /// Send: quiet button that saves the recipient's address as a contact.
  ///
  /// In en, this message translates to:
  /// **'Save as contact'**
  String get sendSaveContact;

  /// Send, step 1: heading of the short list of people the user paid recently.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sendRecent;

  /// Send, step 1: quiet row that opens paying with a payment file instead of an address.
  ///
  /// In en, this message translates to:
  /// **'No address? Use a payment file'**
  String get sendUseFile;

  /// Send: who the payment goes to, a contact name or a shortened address, above the amount and under it on the tracker.
  ///
  /// In en, this message translates to:
  /// **'To {who}'**
  String sendTo(String who);

  /// Send, step 2: the amount the wallet can spend now, under the amount field. {amount} is like '7.49 EPIC'.
  ///
  /// In en, this message translates to:
  /// **'Available {amount}'**
  String sendAvailable(String amount);

  /// Send, step 2: the estimated network fee as a quiet figure under the amount.
  ///
  /// In en, this message translates to:
  /// **'Network fee {fee}'**
  String sendFeeQuiet(String fee);

  /// Send, step 2: folded row that opens the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get sendAddNote;

  /// Send, step 2: label of the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get sendNoteLabel;

  /// Send, step 2: under the note field; the recipient sees the note as well.
  ///
  /// In en, this message translates to:
  /// **'They see it too.'**
  String get sendNoteHelper;

  /// Send, review: label of the row with the network fee.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get sendNetworkFee;

  /// Send, review: the checks of the network and the recipient's relay are running.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get sendChecking;

  /// Send, review: every check passed.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get sendReady;

  /// Send, review: the node does not answer, so the payment cannot be sent; a Retry button follows.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the network right now.'**
  String get sendNodeDown;

  /// Send, review: the recipient's message relay does not answer, so the payment may not arrive; paying with a file is offered. {relay} is its host name, as in the address (epicbox.example.org).
  ///
  /// In en, this message translates to:
  /// **'Their relay ({relay}) isn\'t answering.'**
  String sendRelayDown(String relay);

  /// Send, review: this wallet is not connected to its message relay yet; sending is still allowed.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet. You can still send.'**
  String get sendListenerDown;

  /// Send, review: button that switches to paying with a payment file, keeping the amount and note.
  ///
  /// In en, this message translates to:
  /// **'Pay with a file instead'**
  String get sendPayWithFile;

  /// Send, review: sends although the recipient's relay did not answer.
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get sendAnyway;

  /// Send tracker, step 1 done: the payment went to the contact {name}.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}'**
  String sendTrackSentTo(String name);

  /// Send tracker, step 1 done, for a recipient without a contact name.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sendTrackSent;

  /// Send tracker, step 2 current: the contact's wallet has not signed yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}\'s wallet'**
  String sendTrackWaitingFor(String name);

  /// Send tracker, step 2 current, for a recipient without a contact name.
  ///
  /// In en, this message translates to:
  /// **'Waiting for their wallet'**
  String get sendTrackWaiting;

  /// Send tracker, step 2 done: the contact's wallet signed the payment.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s wallet signed'**
  String sendTrackSignedBy(String name);

  /// Send tracker, step 2 done, for a recipient without a contact name; also the file route's reply step once done.
  ///
  /// In en, this message translates to:
  /// **'Their wallet signed'**
  String get sendTrackSigned;

  /// Send tracker: the finished payment was handed to the network.
  ///
  /// In en, this message translates to:
  /// **'Sent to the network'**
  String get sendTrackOnNetwork;

  /// Send tracker, last step: the network confirmed the payment.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get sendTrackConfirmed;

  /// Send tracker, while waiting for the recipient's wallet. {amount} is the amount plus fee, like '2.508 EPIC'.
  ///
  /// In en, this message translates to:
  /// **'Their wallet finishes it when it opens. {amount} stays on hold until then.'**
  String sendTrackOffline(String amount);

  /// Send tracker: small expandable row with the automatic cancel rule.
  ///
  /// In en, this message translates to:
  /// **'What if it never finishes?'**
  String get sendTrackIfNot;

  /// Send tracker: the payment was cancelled or expired.
  ///
  /// In en, this message translates to:
  /// **'This payment was cancelled.'**
  String get sendTrackCancelled;

  /// Send: empty state when the wallet has no coins at all, spendable or on the way.
  ///
  /// In en, this message translates to:
  /// **'No coins to send yet.'**
  String get sendNoCoins;

  /// Send, file route: heading of the steps that pay with a payment file.
  ///
  /// In en, this message translates to:
  /// **'Pay with a file'**
  String get sendFileTitle;

  /// Send, file route: button that makes the payment file for the amount.
  ///
  /// In en, this message translates to:
  /// **'Make payment file'**
  String get sendMakeFile;

  /// Send, file route tracker: the payment file exists.
  ///
  /// In en, this message translates to:
  /// **'File made'**
  String get sendFileMade;

  /// Send, file route tracker: detail under 'File made'; the amount is held until the payment finishes.
  ///
  /// In en, this message translates to:
  /// **'{amount} on hold'**
  String sendFileOnHold(String amount);

  /// Send, file route tracker, current step: waiting for the file the other person sends back.
  ///
  /// In en, this message translates to:
  /// **'Waiting for their reply'**
  String get sendFileWaitingReply;

  /// Send, file route: one line above the save and share buttons.
  ///
  /// In en, this message translates to:
  /// **'Send them this file. Then open their reply.'**
  String get sendFileShareHint;

  /// Send, file route: button that opens the file the other person sent back.
  ///
  /// In en, this message translates to:
  /// **'Open their reply'**
  String get sendOpenReply;

  /// How it works sheet: toggle segment for the flow where you pay someone.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get handshakePayment;

  /// How it works sheet: toggle segment for the flow where you ask someone for coins (an invoice).
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get handshakeRequest;

  /// How it works sheet: label of the user's wallet in the diagram.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get handshakeYou;

  /// How it works sheet: label of the other person's wallet in the diagram.
  ///
  /// In en, this message translates to:
  /// **'Them'**
  String get handshakeThem;

  /// How it works sheet: label of the Epic network in the diagram.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get handshakeNetwork;

  /// How it works, payment, step 1: your wallet sends the payment to the epicbox relay.
  ///
  /// In en, this message translates to:
  /// **'Your wallet sends the payment to the relay. Your coins go on hold.'**
  String get handshakePay1;

  /// How it works, payment, step 2: the relay hands it to their wallet, which signs.
  ///
  /// In en, this message translates to:
  /// **'The relay passes it on. Their wallet adds its part and signs.'**
  String get handshakePay2;

  /// How it works, step 3 of both flows: the wallet that started finishes and broadcasts it.
  ///
  /// In en, this message translates to:
  /// **'Your wallet finishes it and sends it to the network.'**
  String get handshakeFinish;

  /// How it works, step 4 of both flows.
  ///
  /// In en, this message translates to:
  /// **'The network confirms it.'**
  String get handshakeConfirm;

  /// How it works, request, step 1: you ask them for coins through the relay.
  ///
  /// In en, this message translates to:
  /// **'Your wallet sends the request to the relay.'**
  String get handshakeReq1;

  /// How it works, request, step 2: the relay hands the request to the payer, who approves; their wallet pays and signs.
  ///
  /// In en, this message translates to:
  /// **'The relay passes it on. They approve it, and their wallet adds the coins and signs.'**
  String get handshakeReq2;

  /// How it works sheet: label of the epicbox relay in the diagram, which carries the payment between the two wallets.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get handshakeRelay;

  /// How it works sheet: toggle segment for paying with a payment file, and the label of the file in the diagram. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get handshakeFile;

  /// How it works, step 3 of the payment and the request: the other wallet sends it back to the relay.
  ///
  /// In en, this message translates to:
  /// **'Their wallet sends it back to the relay.'**
  String get handshakeBack;

  /// How it works, step 4 of the payment and the request: the relay hands it back to your wallet.
  ///
  /// In en, this message translates to:
  /// **'The relay passes it back to your wallet.'**
  String get handshakeRelayBack;

  /// How it works, payment file, step 1: your wallet makes a payment file and you pass it on by hand (message, email…).
  ///
  /// In en, this message translates to:
  /// **'Your wallet saves a payment file. You send it to them yourself.'**
  String get handshakeFile1;

  /// How it works, payment file, step 2.
  ///
  /// In en, this message translates to:
  /// **'They open it. Their wallet adds its part, signs and saves a reply.'**
  String get handshakeFile2;

  /// How it works, payment file, step 3.
  ///
  /// In en, this message translates to:
  /// **'They send the reply file back to you.'**
  String get handshakeFile3;

  /// How it works, payment file, step 4: you open the reply file.
  ///
  /// In en, this message translates to:
  /// **'You open their reply in your wallet.'**
  String get handshakeFile4;

  /// How it works sheet: tooltip of the button that shows the step before.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get handshakePrevious;

  /// How it works sheet: tooltip of the button that shows the next step.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get handshakeNext;

  /// Send, review: the send failed at the recipient's relay; the wallet keeps the payment with its coins on hold until it is cancelled, and cancels it by itself after {days} days. {relay} is the relay's host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Their relay ({relay}) didn\'t take it. The amount is on hold until you cancel it, or for at most 1 day.} other{Their relay ({relay}) didn\'t take it. The amount is on hold until you cancel it, or for at most {days} days.}}'**
  String sendRelayRefused(int days, String relay);

  /// Send, review: the send failed at the recipient's relay and the app could not find the payment it may have left; the user should look in Wallet before trying again. {relay} is the relay's host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'Their relay ({relay}) didn\'t take it. Check Wallet before you send again.'**
  String sendRelayRefusedLost(String relay);

  /// Send, review after a failed send: cancels the payment the wallet kept, then pays the same amount with a payment file.
  ///
  /// In en, this message translates to:
  /// **'Cancel and pay with a file'**
  String get sendCancelAndFile;

  /// Send, review after a failed send: leaves the payment on hold (it can be cancelled later from Wallet) and goes back to Wallet.
  ///
  /// In en, this message translates to:
  /// **'Leave it for now'**
  String get sendLeaveIt;

  /// Send, review: the payment is being sent; it can take a while when a relay is slow.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendSending;

  /// Screen readers, a step of a payment's progress that is done. {step} is the step's label.
  ///
  /// In en, this message translates to:
  /// **'{step}, done'**
  String trackStepDone(String step);

  /// Screen readers, the step of a payment's progress that is happening now.
  ///
  /// In en, this message translates to:
  /// **'{step}, now'**
  String trackStepNow(String step);

  /// Screen readers, a step of a payment's progress still to come.
  ///
  /// In en, this message translates to:
  /// **'{step}, later'**
  String trackStepLater(String step);

  /// Under the balance: coins a send holds until it completes (locked outputs), with the amount. Keep it short; it shares one line with balanceLineComingIn.
  ///
  /// In en, this message translates to:
  /// **'{amount} on hold'**
  String balanceLineOnHold(String amount);

  /// Under the balance: coins on their way in (in a block and confirming, mining rewards maturing), with the amount. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'+{amount} coming in'**
  String balanceLineComingIn(String amount);

  /// Web demo: a small pill in the app bar saying the wallet holds test coins. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'Test coins'**
  String get demoTestCoinsPill;

  /// Web demo: tooltip and screen-reader text of the Test coins pill. Floonet is a proper name.
  ///
  /// In en, this message translates to:
  /// **'Floonet, Epic\'s test network. The coins have no value.'**
  String get demoTestCoinsPillTip;

  /// Web demo: in the Test coins pill, hours until the demo wallet is deleted, with the hour abbreviation.
  ///
  /// In en, this message translates to:
  /// **'{hours} h left'**
  String demoLeftHours(int hours);

  /// Web demo: in the Test coins pill, minutes until the demo wallet is deleted, with the minute abbreviation.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String demoLeftMinutes(int minutes);

  /// Web demo, Receive: under the address. Payments arrive only while the browser tab with the demo is open.
  ///
  /// In en, this message translates to:
  /// **'Keep this tab open to receive.'**
  String get demoReceiveKeepOpen;

  /// Web demo, Wallet tab: heading of the short checklist that guides a visitor through a first payment.
  ///
  /// In en, this message translates to:
  /// **'Try a payment'**
  String get demoGuideTitle;

  /// Web demo checklist, step 2: send some test coins to someone.
  ///
  /// In en, this message translates to:
  /// **'Send some to someone'**
  String get demoGuideSend;

  /// Web demo checklist, under step 2. A demo is tied to the browser's cookies: another browser, or a private window opened from a normal one, starts a second, separate demo; a second tab or a second private window opens the same one, so do not say 'new tab'.
  ///
  /// In en, this message translates to:
  /// **'Pay a friend\'s demo, or open this page in a different browser or a private window.'**
  String get demoGuideSendHint;

  /// Web demo checklist, step 2's button: switches to the Send tab.
  ///
  /// In en, this message translates to:
  /// **'Go to Send'**
  String get demoGuideOpenSend;

  /// Web demo checklist: while the faucet claim runs, which takes up to about a minute.
  ///
  /// In en, this message translates to:
  /// **'Asking the test faucet. This can take a minute.'**
  String get demoGuideAsking;

  /// Web demo checklist: the one line left once both steps are done.
  ///
  /// In en, this message translates to:
  /// **'Both done. Look around as long as the demo lasts.'**
  String get demoGuideDone;

  /// Web demo checklist: small button that hides the checklist.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get demoGuideHide;

  /// Web demo checklist: screen-reader label of the Hide button.
  ///
  /// In en, this message translates to:
  /// **'Hide the demo steps'**
  String get demoGuideHideLabel;

  /// Web demo checklist: what a screen reader says for a finished step; step is the step's text.
  ///
  /// In en, this message translates to:
  /// **'{step}, done'**
  String demoGuideStepDone(String step);

  /// Web demo checklist: what a screen reader says for a step not done yet; step is the step's text.
  ///
  /// In en, this message translates to:
  /// **'{step}, not done yet'**
  String demoGuideStepToDo(String step);

  /// Receive, first tab: this wallet's epicbox address. epicbox is a proper name. Short: three tabs share one row on a phone.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get receiveTabEpicbox;

  /// Receive, second tab (only when the app has Tor): this wallet's Tor address, an onion address. Tor is a proper name.
  ///
  /// In en, this message translates to:
  /// **'Tor'**
  String get receiveTabTor;

  /// Receive, last tab: accepting a payment file. Short: three tabs share one row on a phone.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get receiveTabFile;

  /// Caption above the wallet's full Tor address (the onion address) on the Receive tab; a tap on the card copies it.
  ///
  /// In en, this message translates to:
  /// **'Tor address'**
  String get receiveTorAddressLabel;

  /// Screen reader label of the QR code of the wallet's Tor address.
  ///
  /// In en, this message translates to:
  /// **'QR code of your Tor address'**
  String get receiveTorQrLabel;

  /// Title of the on/off switch for receiving payments over Tor, on the Receive tab and in Settings. Same words in both places.
  ///
  /// In en, this message translates to:
  /// **'Tor receiving'**
  String get torReceivingTitle;

  /// The lines that describe Tor receiving, under the switch: only what is true. No time promises. The last sentence: the phone cuts the app's network when it leaves the screen, so a payment over Tor reaches the wallet only while the app is open; nothing waits for it elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Tor receiving works while the app is open or briefly in the background.'**
  String get torHonestLine;

  /// Tor status line on Receive: the switch is off, so other wallets cannot reach this one over Tor.
  ///
  /// In en, this message translates to:
  /// **'Tor receiving is off'**
  String get torStateOff;

  /// Tor status line while tor connects, with the percentage done. Also Send's status while it connects for a payment.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Tor… {percent}%'**
  String torStateStarting(int percent);

  /// Tor status line: connected, the wallet's onion address is being made reachable.
  ///
  /// In en, this message translates to:
  /// **'Publishing your Tor address…'**
  String get torStatePublishing;

  /// Tor status line: other wallets can reach this one at its Tor address.
  ///
  /// In en, this message translates to:
  /// **'Tor receiving is on'**
  String get torStateReady;

  /// Tor status line: tor is connected but the wallet's own address cannot be reached; {reason} is one of the torFailure sentences.
  ///
  /// In en, this message translates to:
  /// **'Your Tor address is not reachable yet. {reason}'**
  String torStateNotReachable(String reason);

  /// Why Tor is not working: this build has no tor binary.
  ///
  /// In en, this message translates to:
  /// **'Tor is not included in this app.'**
  String get torFailureMissing;

  /// Why Tor is not working: the tor program did not start.
  ///
  /// In en, this message translates to:
  /// **'Tor did not start.'**
  String get torFailureStart;

  /// Why Tor is not working: no progress connecting (offline, or Tor blocked). The line under the switch already says Tor is blocked in some countries, so this does not repeat it.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Tor network. Check the connection.'**
  String get torFailureNetwork;

  /// Why Tor is not working: the device's clock is off, which Tor refuses.
  ///
  /// In en, this message translates to:
  /// **'The phone\'s clock is wrong. Tor needs the right time.'**
  String get torFailureClock;

  /// Why Tor is not working for receiving: the wallet's own Tor service did not start.
  ///
  /// In en, this message translates to:
  /// **'The wallet could not open its Tor address.'**
  String get torFailureListener;

  /// Why Tor is not working: the tor program exited.
  ///
  /// In en, this message translates to:
  /// **'Tor stopped.'**
  String get torFailureStopped;

  /// Why Tor is not working for receiving: the onion address was not published in time.
  ///
  /// In en, this message translates to:
  /// **'The Tor address could not be published.'**
  String get torFailurePublish;

  /// Why Tor is not working for receiving: tor refused the wallet's onion key.
  ///
  /// In en, this message translates to:
  /// **'Tor did not accept the wallet\'s address key.'**
  String get torFailureKeys;

  /// Send, step 1, and a contact's address: the text looks like a Tor (onion) address but its checksum fails: a typo or a cut.
  ///
  /// In en, this message translates to:
  /// **'This is not a complete Tor address. Copy it again from the recipient.'**
  String get sendOnionIncomplete;

  /// Send, step 1: the recipient is a Tor address but this build or platform has no Tor.
  ///
  /// In en, this message translates to:
  /// **'This app cannot send over Tor, so a Tor address cannot be paid here.'**
  String get sendTorUnavailable;

  /// Small label on the recipient card and the review when the payment goes over Tor (the address is an onion address).
  ///
  /// In en, this message translates to:
  /// **'Over Tor'**
  String get sendOverTor;

  /// Send, review: the recipient is a Tor address and tor is not running yet; it starts when Send is tapped.
  ///
  /// In en, this message translates to:
  /// **'Tor connects when you send.'**
  String get sendTorConnectsOnSend;

  /// Send, review: tor is connected; the payment can go.
  ///
  /// In en, this message translates to:
  /// **'Ready to send over Tor'**
  String get sendTorReady;

  /// Send, review, while sending over Tor: the recipient's wallet is being contacted. No time promise.
  ///
  /// In en, this message translates to:
  /// **'Reaching their wallet over Tor… This can take a while. Keep the app open.'**
  String get sendTorReaching;

  /// Send, review: the recipient's wallet was not reached over Tor; the wallet keeps the payment with its coins on hold until it is cancelled, and cancels it by itself after {days} days. Try again and Cancel payment follow.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Their wallet was not reached over Tor. The amount is on hold until you cancel it, or for at most 1 day.} other{Their wallet was not reached over Tor. The amount is on hold until you cancel it, or for at most {days} days.}}'**
  String sendTorNotReached(int days);

  /// Send, review: tor did not connect before anything was sent; {reason} is one of the torFailure sentences.
  ///
  /// In en, this message translates to:
  /// **'{reason} Nothing was sent.'**
  String sendTorNothingSent(String reason);

  /// Button: deliver the waiting payment again over Tor.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sendTryAgain;

  /// Button: cancel the waiting payment, freeing its coins.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get sendCancelPayment;

  /// Settings section header: how payments reach this wallet (Tor receiving).
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get settingsSectionReceiving;

  /// Caption above Wallet's big figure: the spendable balance.
  ///
  /// In en, this message translates to:
  /// **'Available to spend'**
  String get homeAvailableToSpend;

  /// Balance tile label: payments offered to this wallet that are not in a block yet (awaiting finalization). 1 to 3 words.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender'**
  String get homeTileWaitingSender;

  /// Balance tile label: coins a send in progress holds until it confirms. 1 to 3 words.
  ///
  /// In en, this message translates to:
  /// **'Locked in sends'**
  String get homeTileLocked;

  /// Balance tile label: mining rewards not spendable yet. 1 to 3 words.
  ///
  /// In en, this message translates to:
  /// **'Rewards maturing'**
  String get homeTileMaturing;

  /// Balance tile label: the whole balance, spendable and pending together.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get homeTileTotal;

  /// Button beside Recent activity: opens History. {count} is the number of payments.
  ///
  /// In en, this message translates to:
  /// **'View all {count}'**
  String homeViewAll(int count);

  /// Home destination tile: the payment history.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get homeDestActivity;

  /// Home destination tile: the Outputs screen (the pieces the balance is made of).
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get homeDestOutputs;

  /// Status word of a completed incoming payment or mining reward in lists.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get txStatusReceived;

  /// Status word of a completed outgoing payment in lists.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get txStatusSent;

  /// The PIN prompt's reason right before a send is posted. {amount} is the exact amount.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN to send {amount}.'**
  String sendPinReason(String amount);

  /// The PIN prompt's reason right before a payment file is made, which locks the coins. {amount} is the exact amount.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN to make a payment file for {amount}.'**
  String sendFilePinReason(String amount);

  /// Outputs screen title and Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get outputsTitle;

  /// Outputs tile and filter: outputs that can be spent now.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get outputsSpendable;

  /// Outputs tile and filter: outputs waiting for confirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get outputsConfirming;

  /// Outputs tile: outputs a send in progress spends.
  ///
  /// In en, this message translates to:
  /// **'Locked in sends'**
  String get outputsLockedTile;

  /// Outputs tile: mining rewards not yet spendable.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get outputsImmature;

  /// Under a tile value: how many outputs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 output} other{{count} outputs}}'**
  String outputsCount(int count);

  /// Button: open the Split sheet.
  ///
  /// In en, this message translates to:
  /// **'Split…'**
  String get outputsSplitButton;

  /// Button: open the Consolidate sheet.
  ///
  /// In en, this message translates to:
  /// **'Consolidate…'**
  String get outputsConsolidateButton;

  /// Caption under the buttons: why Split is disabled.
  ///
  /// In en, this message translates to:
  /// **'Split needs at least 1 EPIC spendable.'**
  String get outputsSplitNeeds;

  /// Caption under the buttons: why Consolidate is disabled.
  ///
  /// In en, this message translates to:
  /// **'Consolidate needs at least 2 spendable outputs.'**
  String get outputsConsolidateNeeds;

  /// Caption under the buttons: a send is in progress.
  ///
  /// In en, this message translates to:
  /// **'Wait until the send in progress confirms (about 3 blocks).'**
  String get outputsWaitLocked;

  /// Row: which outputs a send spends.
  ///
  /// In en, this message translates to:
  /// **'Strategy for sends'**
  String get outputsStrategy;

  /// Strategy name.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get outputsSmallest;

  /// Strategy name and filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get outputsAll;

  /// Strategy explanation, one line.
  ///
  /// In en, this message translates to:
  /// **'Spends the fewest small outputs; the rest of the balance stays spendable while the change confirms.'**
  String get outputsSmallestText;

  /// Strategy explanation, one line.
  ///
  /// In en, this message translates to:
  /// **'Spends every spendable output and returns one change output. Everything is locked until it confirms; fewer, larger outputs afterwards.'**
  String get outputsAllText;

  /// Row with a switch: split the change of a send.
  ///
  /// In en, this message translates to:
  /// **'Split change'**
  String get outputsSplitChange;

  /// Caption under the Split change switch.
  ///
  /// In en, this message translates to:
  /// **'When few outputs would be left'**
  String get outputsSplitChangeText;

  /// Filter segment with a count.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String outputsFilterAll(int count);

  /// Filter segment with a count.
  ///
  /// In en, this message translates to:
  /// **'Spendable {count}'**
  String outputsFilterSpendable(int count);

  /// Filter segment with a count.
  ///
  /// In en, this message translates to:
  /// **'Confirming {count}'**
  String outputsFilterConfirming(int count);

  /// Filter segment with a count, shown only when any output is locked.
  ///
  /// In en, this message translates to:
  /// **'Locked {count}'**
  String outputsFilterLocked(int count);

  /// Toggle: list outputs already spent.
  ///
  /// In en, this message translates to:
  /// **'Show spent'**
  String get outputsShowSpent;

  /// Toggle: hide outputs already spent.
  ///
  /// In en, this message translates to:
  /// **'Hide spent'**
  String get outputsHideSpent;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get outputsWordSpendable;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get outputsWordConfirming;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Awaiting finalization'**
  String get outputsWordFinalizing;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get outputsWordImmature;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Mining'**
  String get outputsWordMining;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get outputsWordLocked;

  /// Status word of an output.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get outputsWordSpent;

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'Can be spent now.'**
  String get outputsMeanSpendable;

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'Needs {need} confirmations before it can be spent.'**
  String outputsMeanConfirming(int need);

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the sender to finish the payment.'**
  String get outputsMeanFinalizing;

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'A mining reward. It can be spent after a delay.'**
  String get outputsMeanImmature;

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'A mining reward not confirmed yet.'**
  String get outputsMeanMining;

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'Being spent by a send in progress.'**
  String get outputsMeanLocked;

  /// One line in the output sheet.
  ///
  /// In en, this message translates to:
  /// **'Already spent.'**
  String get outputsMeanSpent;

  /// Row note: when the output was received.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String outputsNoteReceived(String date);

  /// Row note on a locked output: the send that holds it.
  ///
  /// In en, this message translates to:
  /// **'Send to {who}'**
  String outputsNoteSend(String who);

  /// Row note on a locked output when the send is not known.
  ///
  /// In en, this message translates to:
  /// **'Send in progress'**
  String get outputsNoteSendPlain;

  /// Output sheet fact.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get outputsFactHeight;

  /// Output sheet fact.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get outputsFactConfirmations;

  /// Output sheet fact.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get outputsFactTransaction;

  /// Output sheet label above the full commitment.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get outputsFactCommitment;

  /// Button: copy the commitment.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get outputsCopy;

  /// Notice: the commitment was copied.
  ///
  /// In en, this message translates to:
  /// **'Commitment copied'**
  String get outputsCopied;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'No outputs yet'**
  String get outputsEmpty;

  /// Empty state hint.
  ///
  /// In en, this message translates to:
  /// **'The first payment received makes one. Receive shows the address.'**
  String get outputsEmptyHint;

  /// Empty list under a filter.
  ///
  /// In en, this message translates to:
  /// **'No outputs in this view'**
  String get outputsNoMatch;

  /// Button: load the outputs again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get outputsRetry;

  /// Settings row subtitle: output count and strategy name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 output · {strategy}} other{{count} outputs · {strategy}}}'**
  String outputsSettingsSubtitle(int count, String strategy);

  /// Button: close a sheet.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get outputsCancel;

  /// Sheet title.
  ///
  /// In en, this message translates to:
  /// **'Split outputs'**
  String get outputsSplitTitle;

  /// Split sheet paragraph. {spent} and {made} are counts such as "3 outputs".
  ///
  /// In en, this message translates to:
  /// **'Spends {spent} ({amount}) and makes {made} of about {each} each. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then.'**
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  );

  /// Stepper label in the Split sheet.
  ///
  /// In en, this message translates to:
  /// **'Outputs to make'**
  String get outputsToMake;

  /// Stepper range hint.
  ///
  /// In en, this message translates to:
  /// **'2 to 10'**
  String get outputsStepperHint;

  /// Sheet fact.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get outputsFactFee;

  /// Sheet fact: value of each new output.
  ///
  /// In en, this message translates to:
  /// **'Each output'**
  String get outputsFactEach;

  /// A value with "about" in front.
  ///
  /// In en, this message translates to:
  /// **'about {amount}'**
  String outputsFactAbout(String amount);

  /// Sheet fact: what gets locked and for how long.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get outputsFactLocked;

  /// Sheet fact value.
  ///
  /// In en, this message translates to:
  /// **'{amount}, about 3 blocks'**
  String outputsFactLockedValue(String amount);

  /// Warning line in the sheets.
  ///
  /// In en, this message translates to:
  /// **'Nothing stays spendable meanwhile.'**
  String get outputsNothingSpendable;

  /// Warning line: Split needs bigger outputs.
  ///
  /// In en, this message translates to:
  /// **'Each output must be at least 0.5 EPIC.'**
  String get outputsMinEach;

  /// Button in the Split sheet.
  ///
  /// In en, this message translates to:
  /// **'Split into {count}'**
  String outputsSplitInto(int count);

  /// Sheet title.
  ///
  /// In en, this message translates to:
  /// **'Consolidate outputs'**
  String get outputsConsolidateTitle;

  /// Consolidate sheet paragraph. {spent} is a count such as "3 outputs".
  ///
  /// In en, this message translates to:
  /// **'Spends {spent} ({amount}) and makes one output of {result}. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then. The next send spends one output, so its fee is the smallest.'**
  String outputsConsolidateText(String amount, String result, String spent);

  /// Button in the Consolidate sheet.
  ///
  /// In en, this message translates to:
  /// **'Consolidate'**
  String get outputsConsolidateAction;

  /// Reason shown in the PIN prompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your PIN to split outputs'**
  String get outputsSplitPin;

  /// Reason shown in the PIN prompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your PIN to consolidate outputs'**
  String get outputsConsolidatePin;

  /// Notice after a split was posted.
  ///
  /// In en, this message translates to:
  /// **'Split started: {count} outputs, confirming in about 3 blocks'**
  String outputsSplitStarted(int count);

  /// Notice after a consolidation was posted.
  ///
  /// In en, this message translates to:
  /// **'Consolidate started: one output, confirming in about 3 blocks'**
  String get outputsConsolidateStarted;

  /// Outputs screen: head of the section under the table that holds Split, Consolidate, the strategy and Split change.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get outputsAdvanced;

  /// Output table header: the column with each output's state mark, word and note. One word.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get outputsColState;

  /// Output table header: the column with each output's amount.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get outputsColValue;

  /// Output table header: the column with an output's confirmations out of the needed, e.g. 1 / 3. The column is narrow: keep it to one short word.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get outputsColConfirmations;

  /// One line under the pending-sends card's title: the locked amount and what it waits for. {amount} is the total of the waiting sends.
  ///
  /// In en, this message translates to:
  /// **'{amount} stays locked until the recipient\'s wallet answers.'**
  String homePendingShort(String amount);

  /// Contacts: the search field's hint.
  ///
  /// In en, this message translates to:
  /// **'Name or address'**
  String get contactsSearchHint;

  /// Contacts: the empty list's heading.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsEmptyTitle;

  /// Contacts: one line under the empty list's heading.
  ///
  /// In en, this message translates to:
  /// **'A contact is a name for an address.'**
  String get contactsEmptyCaption;

  /// Contacts: no contact matches the search text.
  ///
  /// In en, this message translates to:
  /// **'No contact matches \"{query}\"'**
  String contactsNoMatchQuery(String query);

  /// Contact sheet: opens Send with this contact as the recipient.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactsSendAction;

  /// Contact sheet: opens the contact's edit screen.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get contactsEditAction;

  /// Contact sheet: label over the full address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get contactsAddressHeading;

  /// Contact sheet: label over the contact's note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get contactsNoteHeading;

  /// Contact sheet: shows the address as a QR code.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get contactsShowCode;

  /// Contact sheet: hides the QR code again.
  ///
  /// In en, this message translates to:
  /// **'Hide code'**
  String get contactsHideCode;

  /// Contact sheet: screen reader label of the QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code of {name}\'s address'**
  String contactsQrLabel(String name);

  /// Contact delete confirm: what changes after deleting.
  ///
  /// In en, this message translates to:
  /// **'Payments to this address show the address instead of the name after this.'**
  String get contactsDeleteConfirmBody;

  /// Notice after a contact was deleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted.'**
  String contactsDeleted(String name);

  /// Notice after the contact's address was copied.
  ///
  /// In en, this message translates to:
  /// **'Address copied.'**
  String get contactsCopied;

  /// Invoices: app bar action that opens the request form.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get invoicesNewRequest;

  /// Invoices: segment with the requests this wallet sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get invoicesSegmentSent;

  /// Invoices: screen reader text of a segment with its count.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count, plural, =0{none} =1{1 item} other{{count} items}}'**
  String invoicesSegmentCount(String label, int count);

  /// Invoices: empty To pay segment, heading.
  ///
  /// In en, this message translates to:
  /// **'No invoices to pay'**
  String get invoicesToPayEmpty;

  /// Invoices: empty To pay segment, caption.
  ///
  /// In en, this message translates to:
  /// **'Services on your trusted list can bill this wallet. Each invoice waits here for your approval.'**
  String get invoicesToPayEmptyCaption;

  /// Invoices: empty Sent segment, heading.
  ///
  /// In en, this message translates to:
  /// **'No requests sent'**
  String get invoicesSentEmpty;

  /// Invoices: empty Sent segment, caption.
  ///
  /// In en, this message translates to:
  /// **'A request asks someone to pay you an amount.'**
  String get invoicesSentEmptyCaption;

  /// Invoices, Sent row: a request still waiting, before its time left.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get invoicesWaitingPayment;

  /// Invoice review: label of the expiry row.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get invoicesExpires;

  /// Invoice review: the clock time an invoice expires.
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String invoicesUntil(String time);

  /// Invoice review: label of the service's message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get invoicesMessage;

  /// Invoice review: label of the service's full address.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get invoicesFrom;

  /// Invoice review: label of the balance the payment comes from.
  ///
  /// In en, this message translates to:
  /// **'Pays from'**
  String get invoicesPaysFrom;

  /// Invoice review: the spendable balance.
  ///
  /// In en, this message translates to:
  /// **'Available to spend {amount}'**
  String invoicesAvailable(String amount);

  /// Invoice review: the invoice is more than the spendable balance.
  ///
  /// In en, this message translates to:
  /// **'Not enough to pay. {amount} short.'**
  String invoicesShort(String amount);

  /// Invoice review: the node check's label.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get invoicesCheckNode;

  /// Invoice review: the epicbox check's label.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get invoicesCheckEpicbox;

  /// Invoice review: the node answered.
  ///
  /// In en, this message translates to:
  /// **'Responding'**
  String get invoicesNodeOk;

  /// Invoice review: the node did not answer.
  ///
  /// In en, this message translates to:
  /// **'Not responding'**
  String get invoicesNodeDown;

  /// Invoice review: the epicbox listener is connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get invoicesEpicboxOk;

  /// Invoice review: the epicbox listener is not connected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get invoicesEpicboxDown;

  /// Request form: the button that sends the request.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get invoicesSendRequest;

  /// Request form: summary above Send request.
  ///
  /// In en, this message translates to:
  /// **'{payer} is asked to pay {amount}. The request expires in 24 h.'**
  String invoicesRequestSummary(String payer, String amount);

  /// Request form: heading of what the payer must do first.
  ///
  /// In en, this message translates to:
  /// **'Before you request'**
  String get invoicesRequestHowTitle;

  /// Status card row title: the node the wallet uses.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get netStatusNode;

  /// Status card row title: the Epicbox relay.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get netStatusEpicbox;

  /// Status card row title: Tor on the phone.
  ///
  /// In en, this message translates to:
  /// **'Tor'**
  String get netStatusTor;

  /// Status card: the node is at the chain tip.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get netStatusSynced;

  /// Status card: the wallet is syncing with the node, no percent known.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get netStatusSyncing;

  /// Status card: syncing with a percent.
  ///
  /// In en, this message translates to:
  /// **'Syncing {percent} %'**
  String netStatusSyncingPercent(int percent);

  /// Status card: no answer yet.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get netStatusConnecting;

  /// Status card: the node is {count} blocks behind the network.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Behind {count}} other{Behind {count}}}'**
  String netStatusBehind(int count);

  /// Status card: the service does not answer.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get netStatusOffline;

  /// Status card: the Epicbox relay is connected.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get netStatusOnline;

  /// Status card: the service is turned off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get netStatusOff;

  /// Status card: Tor is connected.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get netStatusOn;

  /// Status card: Tor stopped with an error.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get netStatusFailed;

  /// Status card: Tor is starting, percent done.
  ///
  /// In en, this message translates to:
  /// **'Starting {percent} %'**
  String netStatusStarting(int percent);

  /// Status card host line on a test network: the network name, then the host.
  ///
  /// In en, this message translates to:
  /// **'{network} · {host}'**
  String netStatusTestHost(String network, String host);

  /// Screen reader name of the status card.
  ///
  /// In en, this message translates to:
  /// **'Network status'**
  String get netStatusTitle;

  /// Epicbox picker section head: relays the wallet has connected to that the public list does not have, each with a remove button. Beside the 'Public servers' head.
  ///
  /// In en, this message translates to:
  /// **'My servers'**
  String get serverMyRelays;

  /// Tooltip of the down arrow on a public server in the My nodes or My servers list, and the one item of the popup it opens: the server goes back to the public list.
  ///
  /// In en, this message translates to:
  /// **'Remove from my list'**
  String get serverMenuRemove;

  /// Tooltip of the bin on a typed-in server in the My nodes or My servers list, and the one item of the popup it opens: the server is deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get serverMenuDelete;

  /// Tor's part of the state line under Privacy & network on the Settings hub, after the node and Epicbox hosts: the word is lower case.
  ///
  /// In en, this message translates to:
  /// **'Tor {state}'**
  String settingsStateTor(String state);

  /// Tooltip of the disabled arrow or bin on the My list row of the server the wallet uses now: why it cannot be removed or deleted.
  ///
  /// In en, this message translates to:
  /// **'In use. Pick another server first.'**
  String get serverRemoveInUse;

  /// Screen reader words for the bell icon on the Epicbox relay that can send push notifications.
  ///
  /// In en, this message translates to:
  /// **'Supports notifications'**
  String get serverSupportsNotifications;

  /// Direct receive status icon state word: the wallet's Tor address is published and reachable.
  ///
  /// In en, this message translates to:
  /// **'Reachable'**
  String get netStatusReachable;

  /// Direct receive status icon state word: Tor is connected and the address is being published.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get netStatusPublishing;

  /// Direct receive status icon state word: the Tor address could not be published.
  ///
  /// In en, this message translates to:
  /// **'Not reachable'**
  String get netStatusNotReachable;

  /// Screen reader hint on the Tor status icon: a tap opens Settings › Privacy.
  ///
  /// In en, this message translates to:
  /// **'Opens the privacy settings'**
  String get netStatusTorOpenHint;

  /// Screen reader hint on the Direct receive status icon: a tap opens the Receive tab's Direct address.
  ///
  /// In en, this message translates to:
  /// **'Opens the Direct receive address'**
  String get netStatusDirectOpenHint;

  /// Screen reader hint on a status card row.
  ///
  /// In en, this message translates to:
  /// **'Shows the servers'**
  String get netStatusOpenHint;

  /// Node picker sheet title.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get serverNodeTitle;

  /// Epicbox picker sheet title.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get serverEpicboxTitle;

  /// Node picker search field.
  ///
  /// In en, this message translates to:
  /// **'Find or type a node address'**
  String get serverSearchHint;

  /// Row offering a typed node address that matches no list row.
  ///
  /// In en, this message translates to:
  /// **'Use {address}'**
  String serverUseAddress(String address);

  /// While a typed node address is being tested.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get serverTesting;

  /// The typed node answered: its block and version.
  ///
  /// In en, this message translates to:
  /// **'Block {height} · v{version}'**
  String serverTestAnswer(String height, String version);

  /// The typed node did not answer; {error} says why.
  ///
  /// In en, this message translates to:
  /// **'No answer. {error}'**
  String serverTestFailed(String error);

  /// Node picker section head: starred and typed nodes.
  ///
  /// In en, this message translates to:
  /// **'My nodes'**
  String get serverMyNodes;

  /// Node picker section head: public nodes.
  ///
  /// In en, this message translates to:
  /// **'Public nodes'**
  String get serverPublicNodes;

  /// Epicbox picker section head: public relays.
  ///
  /// In en, this message translates to:
  /// **'Public servers'**
  String get serverPublicRelays;

  /// Caption under the lists when the monitor did not answer.
  ///
  /// In en, this message translates to:
  /// **'status.btlabs.uk not reachable; health unknown'**
  String get serverHealthUnknown;

  /// Node row: the node is at the network tip.
  ///
  /// In en, this message translates to:
  /// **'at tip'**
  String get serverAtTip;

  /// Node row: blocks behind the tip, as a short number with a minus sign.
  ///
  /// In en, this message translates to:
  /// **'−{count}'**
  String serverBehindShort(String count);

  /// Screen reader: the node is behind the tip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} block behind} other{{count} blocks behind}}'**
  String serverBehindLabel(int count);

  /// Row: the server does not answer the monitor.
  ///
  /// In en, this message translates to:
  /// **'Not responding'**
  String get serverNotResponding;

  /// Screen reader: the monitor saw the server healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get serverHealthy;

  /// Screen reader: the monitor saw the server answer but lag or misbehave.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get serverDegraded;

  /// Screen reader: no health known for the server.
  ///
  /// In en, this message translates to:
  /// **'Health unknown'**
  String get serverHealthNone;

  /// Row trailing word: the server in use.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get serverCurrent;

  /// Tag on the default Epicbox relay.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get serverDefault;

  /// Latency in milliseconds, measured by the monitor.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String serverLatency(String ms);

  /// Relay uptime over the last day.
  ///
  /// In en, this message translates to:
  /// **'{percent} % up'**
  String serverUptime(String percent);

  /// Confirm strip button: switch to the chosen server.
  ///
  /// In en, this message translates to:
  /// **'Switch to {host}'**
  String serverSwitchTo(String host);

  /// Confirm strip caption: what switching the node does.
  ///
  /// In en, this message translates to:
  /// **'The wallet reconnects. Balances are checked again against the new node.'**
  String get serverNodeSwitchNote;

  /// Epicbox picker warning above the list.
  ///
  /// In en, this message translates to:
  /// **'Your address includes this server. Switching changes your address; senders need the new one.'**
  String get serverRelayWarning;

  /// Epicbox confirm strip caption.
  ///
  /// In en, this message translates to:
  /// **'Your address changes; senders need the new one.'**
  String get serverRelaySwitchNote;

  /// Epicbox picker field for a relay not in the list.
  ///
  /// In en, this message translates to:
  /// **'Other server, host or host:port'**
  String get serverOtherRelay;

  /// Current node card label: the node's block height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get serverFactHeight;

  /// Current node card label: the node's version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get serverFactVersion;

  /// Current node card label: peers the node is connected to.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get serverFactPeers;

  /// Current node card label: uptime over the last 24 hours.
  ///
  /// In en, this message translates to:
  /// **'Uptime 24 h'**
  String get serverFactUptime;

  /// Current node card: height and at tip.
  ///
  /// In en, this message translates to:
  /// **'{height} · at tip'**
  String serverHeightAtTip(String height);

  /// Directory line: the height the nodes agree on.
  ///
  /// In en, this message translates to:
  /// **'Nodes agree on {height}'**
  String serverNodesAgree(String height);

  /// Directory line: healthy nodes of all nodes.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, one{{up} of {total} node up} other{{up} of {total} nodes up}}'**
  String serverNodesUp(int up, int total);

  /// Directory line: age of the last block in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, one{last block {seconds} s ago} other{last block {seconds} s ago}}'**
  String serverLastBlockSeconds(int seconds);

  /// Directory line: age of the last block in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{last block {minutes} min ago} other{last block {minutes} min ago}}'**
  String serverLastBlockMinutes(int minutes);

  /// Directory source line with the time of the monitor's last check.
  ///
  /// In en, this message translates to:
  /// **'status.btlabs.uk, checked {time}'**
  String serverCheckedAt(String time);

  /// Screen reader label of a server row: host, then its facts.
  ///
  /// In en, this message translates to:
  /// **'{host}, {facts}'**
  String serverRowLabel(String host, String facts);

  /// Method name on Send and Receive segments.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get methodEpicbox;

  /// Method name: straight to the other wallet over HTTP.
  ///
  /// In en, this message translates to:
  /// **'HTTP'**
  String get methodHttp;

  /// Method name: straight to the other wallet over Tor.
  ///
  /// In en, this message translates to:
  /// **'Tor'**
  String get methodTor;

  /// Method name: a transaction file handed over by hand.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get methodFile;

  /// Caption under the Epicbox picture, a few words, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Epicbox server holds it'**
  String get methodArtCaptionEpicbox;

  /// Caption under the HTTP picture, a few words, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Straight to their wallet'**
  String get methodArtCaptionHttp;

  /// Caption under the Tor picture, a few words, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Straight, through Tor'**
  String get methodArtCaptionTor;

  /// Caption under the File picture, a few words, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'File out, response back'**
  String get methodArtCaptionFile;

  /// Screen reader label of the Epicbox picture.
  ///
  /// In en, this message translates to:
  /// **'Epicbox: the payment goes to the Epicbox server, which holds it until the recipient\'s wallet is back'**
  String get methodArtLabelEpicbox;

  /// Screen reader label of the HTTP picture.
  ///
  /// In en, this message translates to:
  /// **'HTTP: the payment goes straight to the recipient\'s wallet, which must be open'**
  String get methodArtLabelHttp;

  /// Screen reader label of the Tor picture.
  ///
  /// In en, this message translates to:
  /// **'Tor: the payment goes straight to the recipient\'s wallet, routed through the Tor network'**
  String get methodArtLabelTor;

  /// Screen reader label of the File picture.
  ///
  /// In en, this message translates to:
  /// **'File: a transaction file is handed over, a response file comes back, then the sender finalizes'**
  String get methodArtLabelFile;

  /// Send strip title for Epicbox.
  ///
  /// In en, this message translates to:
  /// **'The recipient can be offline.'**
  String get methodSendEpicboxTitle;

  /// Settings row that brings back every guide box the user closed with its X (the method explanations on Send and Receive).
  ///
  /// In en, this message translates to:
  /// **'Show tips again'**
  String get settingsShowTipsAgain;

  /// Notice after Show tips again: the closed guide boxes are back.
  ///
  /// In en, this message translates to:
  /// **'Tips will show again'**
  String get settingsShowTipsAgainDone;

  /// Screen reader label of the small X that closes a guide box (for example the method explanation on Send) for good.
  ///
  /// In en, this message translates to:
  /// **'Hide tip'**
  String get tipHide;

  /// Send strip line for Epicbox.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server holds the payment until they open their wallet.'**
  String get methodSendEpicboxLine;

  /// Send strip title for HTTP.
  ///
  /// In en, this message translates to:
  /// **'Straight to their wallet.'**
  String get methodSendHttpTitle;

  /// Send strip line for HTTP.
  ///
  /// In en, this message translates to:
  /// **'It must be open and reachable at its HTTP address.'**
  String get methodSendHttpLine;

  /// Send strip title for Tor.
  ///
  /// In en, this message translates to:
  /// **'Straight to their wallet, over Tor.'**
  String get methodSendTorTitle;

  /// Send strip line for Tor.
  ///
  /// In en, this message translates to:
  /// **'Slower and more private. Their wallet must be open.'**
  String get methodSendTorLine;

  /// Send strip title for File.
  ///
  /// In en, this message translates to:
  /// **'No connection needed.'**
  String get methodSendFileTitle;

  /// Send strip line for File.
  ///
  /// In en, this message translates to:
  /// **'Hand the file over, get their response file back, then finalize it here.'**
  String get methodSendFileLine;

  /// Receive strip title for Epicbox.
  ///
  /// In en, this message translates to:
  /// **'Share it to get paid.'**
  String get methodReceiveEpicboxTitle;

  /// Receive strip line for Epicbox.
  ///
  /// In en, this message translates to:
  /// **'Works while the wallet is closed: the Epicbox server holds payments until it is back.'**
  String get methodReceiveEpicboxLine;

  /// Receive strip title for Tor.
  ///
  /// In en, this message translates to:
  /// **'Slower and more private.'**
  String get methodReceiveTorTitle;

  /// Receive strip line for Tor.
  ///
  /// In en, this message translates to:
  /// **'Works only while the app is open or briefly in the background.'**
  String get methodReceiveTorLine;

  /// Receive strip title for File.
  ///
  /// In en, this message translates to:
  /// **'Hand a file back and forth.'**
  String get methodReceiveFileTitle;

  /// Receive strip line for File.
  ///
  /// In en, this message translates to:
  /// **'Works with no connection between the wallets.'**
  String get methodReceiveFileLine;

  /// Tooltip of the ? beside the address shape under Send's To field; opens help on address kinds.
  ///
  /// In en, this message translates to:
  /// **'Address kinds'**
  String get methodAddressKindsTooltip;

  /// Screen reader name of Send's method selector, and the review row naming the method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get sendMethodLabel;

  /// Label of Send's recipient field.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get sendToLabel;

  /// Placeholder of Send's recipient field.
  ///
  /// In en, this message translates to:
  /// **'Address or contact'**
  String get sendToHint;

  /// Tag beside the To label for 3 s after the method moved to HTTP because of the address.
  ///
  /// In en, this message translates to:
  /// **'Over HTTP'**
  String get sendSwitchedHttp;

  /// Tag beside the To label for 3 s after the method moved to Epicbox because of the address.
  ///
  /// In en, this message translates to:
  /// **'Via Epicbox'**
  String get sendSwitchedEpicbox;

  /// Read out when a Tor address moved the method to Tor.
  ///
  /// In en, this message translates to:
  /// **'Tor address. Method set to Tor.'**
  String get sendSwitchedTorAnnounce;

  /// Read out when an HTTP address moved the method to HTTP.
  ///
  /// In en, this message translates to:
  /// **'HTTP address. Method set to HTTP.'**
  String get sendSwitchedHttpAnnounce;

  /// Read out when an Epicbox address moved the method to Epicbox.
  ///
  /// In en, this message translates to:
  /// **'Epicbox address. Method set to Epicbox.'**
  String get sendSwitchedEpicboxAnnounce;

  /// Review, Method row for an HTTP send.
  ///
  /// In en, this message translates to:
  /// **'HTTP, straight to their wallet'**
  String get sendReviewMethodHttp;

  /// Review caption: when an Epicbox send can be cancelled.
  ///
  /// In en, this message translates to:
  /// **'Can be cancelled while it waits for the recipient.'**
  String get sendCancelRuleEpicbox;

  /// Review caption: an HTTP or Tor send cannot be cancelled once the other wallet accepted it.
  ///
  /// In en, this message translates to:
  /// **'Cannot be cancelled once their wallet accepts it.'**
  String get sendCancelRuleDirect;

  /// Caption on the payment file step: when a file payment can be cancelled.
  ///
  /// In en, this message translates to:
  /// **'Can be cancelled until the response file is finalized.'**
  String get sendCancelRuleFile;

  /// Send, review: an HTTP send is under way.
  ///
  /// In en, this message translates to:
  /// **'Reaching their wallet… Keep the app open.'**
  String get sendHttpReaching;

  /// Send tracker and payment details: an HTTP or Tor send the other wallet accepted, not in a block yet.
  ///
  /// In en, this message translates to:
  /// **'Delivered · Waiting for a block'**
  String get sendDeliveredWaitingBlock;

  /// Send: the text under the HTTP method is not a web address.
  ///
  /// In en, this message translates to:
  /// **'An HTTP address starts with http:// or https://.'**
  String get sendHttpAddressShape;

  /// Dialog title before a send over plain http to another device.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted. Send anyway?'**
  String get sendPlainHttpTitle;

  /// Dialog text before a send over plain http to another device.
  ///
  /// In en, this message translates to:
  /// **'Plain HTTP to another device. Anyone on the way can read the transaction. An https:// address is encrypted.'**
  String get sendPlainHttpBody;

  /// Payment details: caption under Cancel payment.
  ///
  /// In en, this message translates to:
  /// **'Possible while the payment waits for the recipient.'**
  String get sendCancelPossibleWhileWaiting;

  /// Receive, Epicbox tab: caption under the address.
  ///
  /// In en, this message translates to:
  /// **'When reading it out, check the first six and last six characters.'**
  String get receiveEpicboxCaption;

  /// Receive, Tor tab: caption under the address.
  ///
  /// In en, this message translates to:
  /// **'Some wallets show the address without .onion; both are the same address.'**
  String get receiveTorCaption;

  /// Send, review: the recipient's wallet was not reached over HTTP; the payment is kept with its coins on hold until it is cancelled, and cancels itself after {days} days. Try again and Cancel payment follow.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Their wallet was not reached. The amount is on hold until you cancel it, or for at most 1 day.} other{Their wallet was not reached. The amount is on hold until you cancel it, or for at most {days} days.}}'**
  String sendHttpNotReached(int days);

  /// Activity row title of an invoice you paid; label is your name for the service.
  ///
  /// In en, this message translates to:
  /// **'Invoice from {label}'**
  String deskInvActFrom(String label);

  /// Activity filter: requests you sent and invoices you paid.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvActFilter;

  /// Section title in a transaction's details: the request or invoice behind it.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get deskInvActBlock;

  /// Link from a transaction to its invoice on the Invoices page.
  ///
  /// In en, this message translates to:
  /// **'Open in Invoices'**
  String get deskInvActOpen;

  /// Detail label: the service that sent the invoice.
  ///
  /// In en, this message translates to:
  /// **'Billed by'**
  String get deskInvActBilledBy;

  /// Overview card title: invoices to pay and requests waiting.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvActOverviewTitle;

  /// Overview card line: invoices waiting for your answer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to pay} =1{1 invoice to pay} other{{count} invoices to pay}}'**
  String deskInvActOverviewToPay(int count);

  /// Overview card line: requests you sent, not answered yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No issued invoices waiting} =1{1 issued invoice waiting for its payer} other{{count} issued invoices waiting for their payers}}'**
  String deskInvActOverviewWaiting(int count);

  /// Overview card warning: paid invoices whose payment needs Retry or Cancel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment needs you: retry or cancel it} other{{count} payments need you: retry or cancel them}}'**
  String deskInvActOverviewAttention(int count);

  /// Overview card button: open the invoices to pay.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get deskInvActReview;

  /// Overview card button: open the Invoices page.
  ///
  /// In en, this message translates to:
  /// **'Open Invoices'**
  String get deskInvActOpenInvoices;

  /// Sidebar entry for invoices: to pay and issued. One word.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvNav;

  /// Title of the Invoices page: invoices to pay (tab Pay) and invoices this wallet issued (tab Issue).
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvTitle;

  /// Tab on the Invoices page: invoices sent to this wallet, waiting for an answer. A short verb.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get deskInvTabPay;

  /// Tab on the Invoices page: invoices this wallet issued to others. A short verb.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get deskInvTabIssue;

  /// A tab label with how many items in it need you, e.g. 'To pay (2)'.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String deskInvTabCount(String label, int count);

  /// Button: start a new invoice to someone who should pay this wallet.
  ///
  /// In en, this message translates to:
  /// **'Issue an invoice'**
  String get deskInvIssueAction;

  /// Status while the wallet asks the relay for invoices and payments.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get deskInvChecking;

  /// When the wallet last asked the relay for invoices, e.g. 'Checked at 14:32'.
  ///
  /// In en, this message translates to:
  /// **'Checked at {time}'**
  String deskInvCheckedAt(String time);

  /// Notice title when checking for invoices failed.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server is not answering'**
  String get deskInvCheckFailedTitle;

  /// Notice text when checking for invoices failed.
  ///
  /// In en, this message translates to:
  /// **'The lists show what arrived before. Nothing was lost; the wallet tries again every 2 minutes.'**
  String get deskInvCheckFailedBody;

  /// State of a request you sent: delivered, no answer yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payer'**
  String get deskInvReqWaiting;

  /// State of a request you sent: the payer paid, your wallet finishes and posts the payment.
  ///
  /// In en, this message translates to:
  /// **'Paid, finalizing'**
  String get deskInvReqPaid;

  /// State of a request you sent: the payment is posted to the network, not yet in a block.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get deskInvReqPosted;

  /// State: the payment is in blocks, e.g. 'Confirming 2 of 3'.
  ///
  /// In en, this message translates to:
  /// **'Confirming {count} of {total}'**
  String deskInvConfirming(int count, int total);

  /// State: the payment has enough confirmations.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get deskInvCompleted;

  /// State of a request you sent: paid and finished, but the node refused it or could not be reached.
  ///
  /// In en, this message translates to:
  /// **'Not posted'**
  String get deskInvReqNotPosted;

  /// State: the invoice or request was declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get deskInvDeclined;

  /// State: time ran out before an answer.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get deskInvExpired;

  /// State: the request was withdrawn by the one who sent it.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get deskInvWithdrawn;

  /// State of a request you sent: the payer's wallet cannot pay requests and returned it.
  ///
  /// In en, this message translates to:
  /// **'Sent back'**
  String get deskInvReqBounced;

  /// State of an invoice you received: waiting for your answer.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get deskInvPayWaiting;

  /// State of an invoice you approved: signing and sending the payment.
  ///
  /// In en, this message translates to:
  /// **'Paying'**
  String get deskInvPayPaying;

  /// State of an invoice you paid: the signed payment did not reach the relay; funds stay locked until Retry or Cancel.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get deskInvPayNotDelivered;

  /// State of an invoice you paid: the service has your payment and must post it.
  ///
  /// In en, this message translates to:
  /// **'Waiting to post'**
  String get deskInvPayDelivered;

  /// State of an invoice you paid: the service reports it posted the payment.
  ///
  /// In en, this message translates to:
  /// **'Posted by service'**
  String get deskInvPayPosted;

  /// State of an invoice you paid: the service withdrew it afterwards; you may cancel the payment.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn after paying'**
  String get deskInvPayWithdrawnAfterPay;

  /// State of an invoice you paid: its time passed and the payment is not in the pool or on the chain; you may cancel it.
  ///
  /// In en, this message translates to:
  /// **'Not on chain'**
  String get deskInvPayPastTtl;

  /// State of an invoice you paid: you cancelled the payment; the funds are back.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get deskInvPayCancelled;

  /// Word beside the amount of an invoice this wallet issued that is not paid: it is not money received.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get deskInvUnpaid;

  /// Word beside the amount of an invoice you received: money that would leave your wallet.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get deskInvYouPay;

  /// Absolute expiry time, e.g. 'Expires 22 Oct, 14:30'. Shown on hover of a countdown.
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String deskInvExpiresAt(String time);

  /// Label: the transaction's technical identifier (Advanced).
  ///
  /// In en, this message translates to:
  /// **'Slate ID'**
  String get deskInvSlateId;

  /// Title of a fold that holds technical controls (slate ID, rotation, expiry). Desktop has no Advanced switch.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get deskInvAdvanced;

  /// Standing warning on the request form, Review and Settings › Invoices: the same wallet on two devices can intercept invoice payments.
  ///
  /// In en, this message translates to:
  /// **'Use invoices on one device only. Another device with this wallet can take a payment meant for this one.'**
  String get deskInvOneDevice;

  /// Error notice when an invoice action failed for a reason without its own words.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Nothing changed; try again.'**
  String get deskInvFailed;

  /// Link on the Invoices page to Help › Invoices.
  ///
  /// In en, this message translates to:
  /// **'How invoices work'**
  String get deskInvHowItWorks;

  /// Hint in an Epicbox address field: the shape of an address. Keep as is.
  ///
  /// In en, this message translates to:
  /// **'es…@epicbox.epiccash.com'**
  String get deskInvAddressHint;

  /// Title of the QR of this wallet's Epicbox address (its payments address).
  ///
  /// In en, this message translates to:
  /// **'Epicbox address'**
  String get deskInvEpicboxAddress;

  /// Help section title: invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvHelpTitle;

  /// Help section lede under 'Invoices'.
  ///
  /// In en, this message translates to:
  /// **'Bills from trusted senders, paid only after approval.'**
  String get deskInvHelpLede;

  /// Help topic title.
  ///
  /// In en, this message translates to:
  /// **'How an invoice works'**
  String get deskInvHelpFlowTitle;

  /// One-line answer of the topic.
  ///
  /// In en, this message translates to:
  /// **'The issuer sends an invoice to the payer\'s invoice address. Nothing is paid until the payer approves it.'**
  String get deskInvHelpFlowShort;

  /// Paragraph. **x** marks a term.
  ///
  /// In en, this message translates to:
  /// **'An invoice asks for a payment. The **issuer** is paid; the **payer** decides.'**
  String get deskInvHelpFlowIntro;

  /// Step 1 of the invoice flow.
  ///
  /// In en, this message translates to:
  /// **'The issuer\'s wallet sends the invoice to the payer\'s **invoice address** over the Epicbox server.'**
  String get deskInvHelpFlowStep1;

  /// Step 2. [[x]] marks a place in the app; keep the place name as the UI shows it.
  ///
  /// In en, this message translates to:
  /// **'The payer opens it under [[Invoices › Pay]], checks the sender, the amount and the message, and chooses **Approve and pay** with the wallet password.'**
  String get deskInvHelpFlowStep2;

  /// Step 3.
  ///
  /// In en, this message translates to:
  /// **'The payer\'s wallet sends the payment to the issuer\'s **payments address**.'**
  String get deskInvHelpFlowStep3;

  /// Step 4.
  ///
  /// In en, this message translates to:
  /// **'The issuer\'s wallet finalizes the payment and posts it to the network. After {confirmations} confirmations it is final.'**
  String deskInvHelpFlowStep4(int confirmations);

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'Nothing is paid without approval, and an invoice never adds money to the payer\'s wallet. Each invoice has a time to pay, at most 48 hours; after it, the invoice can no longer be paid.'**
  String get deskInvHelpFlowNever;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'Invoices this wallet issued are under [[Invoices › Issue]].'**
  String get deskInvHelpFlowIssued;

  /// Help topic title.
  ///
  /// In en, this message translates to:
  /// **'Why only trusted senders'**
  String get deskInvHelpTrustTitle;

  /// One-line answer.
  ///
  /// In en, this message translates to:
  /// **'Only senders on the trusted list can put an invoice in the inbox. That keeps out spam and fake bills.'**
  String get deskInvHelpTrustShort;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'The wallet accepts an invoice only at its invoice address and only from a sender on the trusted list, matched on the sender\'s address. Anything else is dropped unread, before it is opened, and never shows under [[Invoices › Pay]].'**
  String get deskInvHelpTrustP1;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'Without the list, anyone who learned the invoice address could fill the inbox with spam or with bills that look real.'**
  String get deskInvHelpTrustP2;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'Trust only lets a sender ask. A trusted sender cannot take anything: each invoice still waits for **Approve and pay**.'**
  String get deskInvHelpTrustP3;

  /// List item.
  ///
  /// In en, this message translates to:
  /// **'Trust a sender under [[Settings › Invoices]].'**
  String get deskInvHelpTrustWhere1;

  /// List item.
  ///
  /// In en, this message translates to:
  /// **'Or switch on **Trusted for invoices** on a contact under [[Contacts]].'**
  String get deskInvHelpTrustWhere2;

  /// List item.
  ///
  /// In en, this message translates to:
  /// **'A sender can be removed from the list at any time. Its new invoices are then dropped.'**
  String get deskInvHelpTrustWhere3;

  /// Help topic title.
  ///
  /// In en, this message translates to:
  /// **'Why a separate invoice address'**
  String get deskInvHelpAddrTitle;

  /// One-line answer.
  ///
  /// In en, this message translates to:
  /// **'Invoices arrive at their own address, apart from the payments address that people pay to.'**
  String get deskInvHelpAddrShort;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'The wallet has two Epicbox addresses. The **payments address**, under [[Receive]], receives payments. The **invoice address** receives only invoices.'**
  String get deskInvHelpAddrP1;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'Keeping them apart means the invoice address can be given to services, or replaced, without exposing or changing the address people pay to.'**
  String get deskInvHelpAddrP2;

  /// Paragraph.
  ///
  /// In en, this message translates to:
  /// **'The invoice address does not receive payments: a payment sent to it is dropped. To be paid, give the payments address.'**
  String get deskInvHelpAddrP3;

  /// List item.
  ///
  /// In en, this message translates to:
  /// **'Find, copy or show the invoice address as a QR code under [[Settings › Invoices]].'**
  String get deskInvHelpAddrWhere1;

  /// List item; 'New address' is the button's label.
  ///
  /// In en, this message translates to:
  /// **'**New invoice address** replaces it. Services with the old one can no longer send invoices until they get the new one.'**
  String get deskInvHelpAddrWhere2;

  /// Caption over the invoice flow diagram.
  ///
  /// In en, this message translates to:
  /// **'How an invoice travels'**
  String get deskInvHelpDiagramTitle;

  /// Diagram lane: the side that issues the invoice and is paid.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get deskInvHelpDiagramIssuer;

  /// Diagram lane: the side that pays.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get deskInvHelpDiagramPayer;

  /// Diagram box, issuer side. Short.
  ///
  /// In en, this message translates to:
  /// **'Issues the invoice'**
  String get deskInvHelpDiagramIssues;

  /// Diagram arrow label. Short.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get deskInvHelpDiagramInvoice;

  /// Diagram box: the payer's invoice address, a gate.
  ///
  /// In en, this message translates to:
  /// **'Invoice address'**
  String get deskInvHelpDiagramGate;

  /// Under the gate. Short.
  ///
  /// In en, this message translates to:
  /// **'Trusted senders only'**
  String get deskInvHelpDiagramGateSub;

  /// Diagram: a sender not on the trusted list.
  ///
  /// In en, this message translates to:
  /// **'Other senders'**
  String get deskInvHelpDiagramDropped;

  /// Under 'Other senders'. Short.
  ///
  /// In en, this message translates to:
  /// **'Dropped unread'**
  String get deskInvHelpDiagramDroppedSub;

  /// Diagram box, payer side. Short.
  ///
  /// In en, this message translates to:
  /// **'Reviews and approves'**
  String get deskInvHelpDiagramReview;

  /// Under it: the button's label.
  ///
  /// In en, this message translates to:
  /// **'Approve and pay'**
  String get deskInvHelpDiagramReviewSub;

  /// Diagram arrow label. Short.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get deskInvHelpDiagramPayment;

  /// Diagram box, issuer side: the normal receive address.
  ///
  /// In en, this message translates to:
  /// **'Payments address'**
  String get deskInvHelpDiagramPayAddr;

  /// Under 'Payments address'. Short.
  ///
  /// In en, this message translates to:
  /// **'Not the invoice address'**
  String get deskInvHelpDiagramPayAddrSub;

  /// Diagram box, issuer side: finalizes the payment and posts it to the network.
  ///
  /// In en, this message translates to:
  /// **'Finalizes and posts'**
  String get deskInvHelpDiagramFinal;

  /// Under it. Short.
  ///
  /// In en, this message translates to:
  /// **'Final after {confirmations} confirmations'**
  String deskInvHelpDiagramFinalSub(int confirmations);

  /// Screen reader text for the whole diagram.
  ///
  /// In en, this message translates to:
  /// **'The issuer sends an invoice to the payer\'s invoice address, which accepts trusted senders only and drops the rest; the payer reviews and approves it; the payment goes to the issuer\'s payments address; the issuer\'s wallet finalizes it and posts it to the network.'**
  String get deskInvHelpDiagramSemantics;

  /// Title of the form that asks someone to pay you.
  ///
  /// In en, this message translates to:
  /// **'Issue an invoice'**
  String get deskInvIssuerFormTitle;

  /// Panel title: the one-off steps the payer takes before they can be billed.
  ///
  /// In en, this message translates to:
  /// **'Before the first invoice'**
  String get deskInvIssuerFirstTitle;

  /// Label: this wallet's normal Epicbox address, which the payer must trust.
  ///
  /// In en, this message translates to:
  /// **'Your payments address'**
  String get deskInvIssuerYourAddress;

  /// Label of the choice how the request travels: Epicbox, File, Direct.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get deskInvIssuerMethod;

  /// Method: the request goes over the Epicbox relay. Product name, usually not translated.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get deskInvIssuerEpicbox;

  /// Method: the request is saved as a file to hand over.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskInvIssuerFile;

  /// Method: the payment comes straight to this wallet over HTTP or Tor.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get deskInvIssuerDirect;

  /// Why a method or button is disabled: not built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get deskInvIssuerSoon;

  /// Field label: the payer's invoice address, where the request goes.
  ///
  /// In en, this message translates to:
  /// **'Their invoice address'**
  String get deskInvIssuerPayer;

  /// Help under the payer field: where the payer finds their invoice address.
  ///
  /// In en, this message translates to:
  /// **'Their wallet shows it under Settings › Invoices.'**
  String get deskInvIssuerPayerHelp;

  /// Error: the payer field is empty.
  ///
  /// In en, this message translates to:
  /// **'Paste their invoice address.'**
  String get deskInvIssuerPayerMissing;

  /// Error: the payer field holds something that is not an Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid Epicbox address.'**
  String get deskInvIssuerPayerInvalid;

  /// Error: the payer field holds this wallet's payments or invoice address.
  ///
  /// In en, this message translates to:
  /// **'This is one of your own addresses. Use the invoice address the payer gives you.'**
  String get deskInvIssuerPayerOwn;

  /// Error: an http(s) or onion address was given while the method is Epicbox.
  ///
  /// In en, this message translates to:
  /// **'Invoices over Epicbox need an Epicbox address, not an HTTP or Tor one.'**
  String get deskInvIssuerPayerHttp;

  /// Button: pick the payer from contacts that have an invoice address.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get deskInvIssuerContacts;

  /// Shown in the contact picker when no contact has an invoice address.
  ///
  /// In en, this message translates to:
  /// **'No contact has an invoice address yet. Add it under Contacts.'**
  String get deskInvIssuerNoContacts;

  /// Warning on the request form: the payer's wallet is known not to pay requests.
  ///
  /// In en, this message translates to:
  /// **'This wallet sent an invoice back before: it cannot pay invoices over Epicbox. Send them an invoice file instead, or ask them to send you the payment.'**
  String get deskInvIssuerNoInvoices;

  /// Button: switch the request to the File method.
  ///
  /// In en, this message translates to:
  /// **'Use a file'**
  String get deskInvIssuerUseFile;

  /// Quiet line on the request form when nothing is known about the payer's wallet. Product names stay as they are.
  ///
  /// In en, this message translates to:
  /// **'Only wallet-for-epic and other LEPIC wallets can pay an invoice over Epicbox. The Epic GUI wallet and Stack Wallet cannot pay invoices at all; the epic-wallet command line can pay an invoice file.'**
  String get deskInvIssuerUnknown;

  /// Field label: how much the payer is asked to pay, in EPIC.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get deskInvIssuerAmount;

  /// Error: the amount field is empty or not a number.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get deskInvIssuerAmountMissing;

  /// Error: the amount is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'The amount must be more than 0.'**
  String get deskInvIssuerAmountZero;

  /// Error: the amount has more than 8 decimal places.
  ///
  /// In en, this message translates to:
  /// **'EPIC has at most 8 decimals.'**
  String get deskInvIssuerAmountDecimals;

  /// Error: the amount is above the coin's supply cap.
  ///
  /// In en, this message translates to:
  /// **'More than all the EPIC there will ever be.'**
  String get deskInvIssuerAmountCap;

  /// Help under the amount: a request spends nothing from this wallet.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your wallet: the payer pays this amount plus their own fee.'**
  String get deskInvIssuerAmountHelp;

  /// Field label: optional text the payer sees with the request.
  ///
  /// In en, this message translates to:
  /// **'Message to the payer'**
  String get deskInvIssuerMessage;

  /// Counter under the message field.
  ///
  /// In en, this message translates to:
  /// **'{used} of {max} bytes'**
  String deskInvIssuerMessageCount(int used, int max);

  /// Error: the message is over 256 bytes.
  ///
  /// In en, this message translates to:
  /// **'The message is too long.'**
  String get deskInvIssuerMessageLong;

  /// Line on the request form: how long the request stays payable (from Settings).
  ///
  /// In en, this message translates to:
  /// **'The payer has {hours} hours to pay.'**
  String deskInvIssuerExpiry(int hours);

  /// Main button: send the payment request. No password is needed.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get deskInvIssuerIssue;

  /// Why Request is disabled: the relay is down.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server is not answering, so an invoice cannot go out now.'**
  String get deskInvIssuerRelayDown;

  /// Why Request did nothing: some fields have errors.
  ///
  /// In en, this message translates to:
  /// **'Fix the fields marked in red.'**
  String get deskInvIssuerFixFields;

  /// Error after Request: the relay did not take it; it was cancelled at once.
  ///
  /// In en, this message translates to:
  /// **'The invoice did not reach the Epicbox server. Nothing was sent. Try again.'**
  String get deskInvIssuerNotDelivered;

  /// Notice after Request: delivered to the payer's invoice address.
  ///
  /// In en, this message translates to:
  /// **'Invoice sent to {payer}.'**
  String deskInvIssuerSent(String payer);

  /// Empty Sent tab.
  ///
  /// In en, this message translates to:
  /// **'No invoices issued yet. An invoice asks a contact or a service to pay you; it spends nothing.'**
  String get deskInvIssuerEmpty;

  /// Row title of a request you sent.
  ///
  /// In en, this message translates to:
  /// **'Invoice to {payer}'**
  String deskInvIssuerTo(String payer);

  /// When the request was sent, e.g. 'Sent 21 Oct, 12:40'.
  ///
  /// In en, this message translates to:
  /// **'Issued {time}'**
  String deskInvIssuerIssued(String time);

  /// Detail label: who was asked to pay.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get deskInvIssuerPayerFact;

  /// Detail label: the amount asked for.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get deskInvIssuerAmountFact;

  /// Detail label: the message sent with the request.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get deskInvIssuerMessageFact;

  /// Detail label: when the request was sent.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get deskInvIssuerSentFact;

  /// Detail label: when the request stops being payable.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get deskInvIssuerExpiresFact;

  /// Detail label: when the request left waiting (paid, declined, expired, withdrawn).
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get deskInvIssuerAnsweredFact;

  /// Progress step: the payer paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get deskInvIssuerStepPaid;

  /// Progress step: the payment is in blocks.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskInvIssuerStepConfirming;

  /// Detail text of a request that was declined, expired, withdrawn or sent back.
  ///
  /// In en, this message translates to:
  /// **'This invoice ended unpaid. Nothing arrived.'**
  String get deskInvIssuerEnded;

  /// Button: take back a waiting request.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get deskInvIssuerWithdraw;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this invoice?'**
  String get deskInvIssuerWithdrawTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'{payer} can no longer pay it.'**
  String deskInvIssuerWithdrawBody(String payer);

  /// Dialog button: do not withdraw or cancel.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get deskInvIssuerKeep;

  /// Notice after Withdraw.
  ///
  /// In en, this message translates to:
  /// **'Invoice withdrawn.'**
  String get deskInvIssuerWithdrawn;

  /// Button: send the finished payment to the node again.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get deskInvIssuerRepost;

  /// Notice after Repost worked.
  ///
  /// In en, this message translates to:
  /// **'Payment posted again.'**
  String get deskInvIssuerReposted;

  /// Error: Repost or Cancel needs the node.
  ///
  /// In en, this message translates to:
  /// **'The node is not answering. Try again when it is reachable.'**
  String get deskInvIssuerNodeDown;

  /// Detail text of a request in Not posted.
  ///
  /// In en, this message translates to:
  /// **'The payment is finished but not on the network: the node refused it or could not be reached.'**
  String get deskInvIssuerNotPostedText;

  /// Button (Advanced): cancel a paid request that was never posted.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get deskInvIssuerCancel;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Cancel this payment?'**
  String get deskInvIssuerCancelTitle;

  /// Confirm dialog text for cancelling a paid request on the receiving side.
  ///
  /// In en, this message translates to:
  /// **'It will not arrive. {payer}\'s funds stay locked in their wallet until they cancel on their side.'**
  String deskInvIssuerCancelBody(String payer);

  /// Detail text and warning notice of a request the payer's wallet returned.
  ///
  /// In en, this message translates to:
  /// **'{payer}\'s wallet sent the invoice back: it cannot pay invoices. Ask them to send you a payment instead.'**
  String deskInvIssuerBounced(String payer);

  /// Button: make a request file for a payer whose wallet cannot pay over Epicbox.
  ///
  /// In en, this message translates to:
  /// **'Use a file'**
  String get deskInvIssuerSendFile;

  /// Quiet note on an ended request that got a late payment.
  ///
  /// In en, this message translates to:
  /// **'A payment arrived after this invoice ended. It was refused; nothing changed.'**
  String get deskInvIssuerLate;

  /// Detail text of a paid request.
  ///
  /// In en, this message translates to:
  /// **'{payer} paid. Your wallet finished the payment and posted it.'**
  String deskInvIssuerPaidText(String payer);

  /// Detail text of a waiting request.
  ///
  /// In en, this message translates to:
  /// **'Delivered to {payer}\'s invoice address. Nothing is paid until they approve it.'**
  String deskInvIssuerWaitingText(String payer);

  /// Button tooltip: copy the request's technical identifier.
  ///
  /// In en, this message translates to:
  /// **'Copy slate ID'**
  String get deskInvIssuerCopySlate;

  /// Before the steps on the issue form: the payer must have done these once.
  ///
  /// In en, this message translates to:
  /// **'Their wallet must take invoices. Before the first invoice:'**
  String get deskInvIssuerStepsIntro;

  /// Step 1 on the issue form.
  ///
  /// In en, this message translates to:
  /// **'1. They add your payments address below to their trusted senders.'**
  String get deskInvIssuerStepTrust;

  /// Step 2 on the issue form.
  ///
  /// In en, this message translates to:
  /// **'2. They give you their invoice address.'**
  String get deskInvIssuerStepAddress;

  /// Progress step: the invoice was issued and delivered.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get deskInvIssuerStepIssued;

  /// Notice: a payer paid an invoice this wallet issued; the wallet finalized it. payer is the contact name or a short address; amount is the number only; EPIC follows it.
  ///
  /// In en, this message translates to:
  /// **'{payer} paid {amount} EPIC.'**
  String deskInvNoticePaid(String payer, String amount);

  /// Warning notice: the payer declined an invoice this wallet issued; the wallet withdrew it.
  ///
  /// In en, this message translates to:
  /// **'{payer} declined your invoice.'**
  String deskInvNoticeDeclined(String payer);

  /// Notice: an invoice this wallet issued ran out of time unpaid.
  ///
  /// In en, this message translates to:
  /// **'An invoice you issued expired unpaid.'**
  String get deskInvNoticeIssuedExpired;

  /// Notice: a service withdrew an invoice that was waiting for the user. service is the user's label for it.
  ///
  /// In en, this message translates to:
  /// **'{service} withdrew an invoice before you answered it.'**
  String deskInvNoticeWithdrawn(String service);

  /// Notice: an invoice waiting for the user ran out of time.
  ///
  /// In en, this message translates to:
  /// **'An invoice expired before you answered it.'**
  String get deskInvNoticeExpired;

  /// Warning notice (desktop and phone): the payment of an invoice this install does not know arrived; LEPIC leaves it on the relay for a day for another install on the same recovery phrase, which may have issued it. Unverified: names no sender.
  ///
  /// In en, this message translates to:
  /// **'A payment for an invoice this device did not issue arrived. It stays on the relay for a day for your other device with this wallet: open the wallet there to finish it.'**
  String get deskInvNoticeUnknownPayment;

  /// Warning notice (desktop and phone): the answer to a send this install does not know arrived; LEPIC leaves it on the relay for a day for another install on the same recovery phrase, which may have made the send. Unverified: names no sender.
  ///
  /// In en, this message translates to:
  /// **'An answer to a payment this device did not send arrived. It stays on the relay for a day for your other device with this wallet: open the wallet there to finish it.'**
  String get deskInvNoticeUnknownAnswer;

  /// Section heading on the Invoices page › To pay: invoices from trusted services that wait for the user's answer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get deskInvPayerWaitingHead;

  /// Section heading on the Invoices page › To pay: invoice payments that need the user (Retry or Cancel payment).
  ///
  /// In en, this message translates to:
  /// **'Payments to settle'**
  String get deskInvPayerNeedsHead;

  /// Button on an invoice row: open the invoice to pay or decline it.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get deskInvPayerReview;

  /// Section head on Invoices › To pay: a paid invoice opened from Activity, which To pay no longer lists.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get deskInvPayerPaidHead;

  /// Link on an answered invoice: open its payment in Activity.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get deskInvPayerView;

  /// Shown in place of the service's message when the invoice has none.
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get deskInvPayerNoMessage;

  /// Quiet line on the Invoices page › To pay: invoices from senders not on the trusted list were dropped unread. Never more detail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message from a sender you do not trust was ignored.} other{{count} messages from senders you do not trust were ignored.}}'**
  String deskInvPayerDropped(int count);

  /// Link: open Settings › Receiving to add a service allowed to send invoices.
  ///
  /// In en, this message translates to:
  /// **'Trust a service…'**
  String get deskInvPayerTrustService;

  /// Link: open Settings › Receiving where the invoice address is shown.
  ///
  /// In en, this message translates to:
  /// **'Your invoice address'**
  String get deskInvPayerYourInvoiceAddress;

  /// Empty state title of Requests › To pay.
  ///
  /// In en, this message translates to:
  /// **'No invoices are waiting'**
  String get deskInvPayerEmptyTitle;

  /// Empty state text of Requests › To pay.
  ///
  /// In en, this message translates to:
  /// **'When a service you trust bills you, the invoice appears here. Nothing is paid until you approve it.'**
  String get deskInvPayerEmptyText;

  /// Notice on To pay: an approved invoice payment did not reach the relay. service is the user's label for the service.
  ///
  /// In en, this message translates to:
  /// **'Your payment to {service} was not delivered'**
  String deskInvPayerNotDeliveredTitle(String service);

  /// Notice text for a payment that was not delivered.
  ///
  /// In en, this message translates to:
  /// **'It is signed and kept on this device; the funds stay locked. Retry sends it again without a second approval.'**
  String get deskInvPayerNotDeliveredText;

  /// Notice on To pay: the service withdrew the invoice after the user paid. service is the user's label.
  ///
  /// In en, this message translates to:
  /// **'{service} withdrew an invoice you paid'**
  String deskInvPayerWithdrawnTitle(String service);

  /// Notice text: a paid invoice was withdrawn; the user may cancel the payment.
  ///
  /// In en, this message translates to:
  /// **'The payment may never reach the chain. Cancel it to unlock your funds.'**
  String get deskInvPayerWithdrawnText;

  /// Notice on To pay: the invoice's time passed and the payment is neither in the pool nor on the chain. service is the user's label.
  ///
  /// In en, this message translates to:
  /// **'Your payment to {service} is not on chain'**
  String deskInvPayerPastTtlTitle(String service);

  /// Notice text for a paid invoice past its time and not on chain.
  ///
  /// In en, this message translates to:
  /// **'Its time passed and the network has not seen it. Cancel it to unlock your funds.'**
  String get deskInvPayerPastTtlText;

  /// Button: cancel an invoice payment that did not complete, unlocking the funds.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get deskInvPayerCancelPayment;

  /// Warning panel title on Review invoice: a fake invoice must not be paid.
  ///
  /// In en, this message translates to:
  /// **'Pay only bills you expect'**
  String get deskInvPayerSafetyTitle;

  /// Warning panel text on Review invoice.
  ///
  /// In en, this message translates to:
  /// **'An invoice never adds money to your wallet. Approving it sends money out.'**
  String get deskInvPayerSafetyText;

  /// Warning on Review invoice: a paid invoice from the same service for the same amount is recent. ago is a duration like '3 h 10 min' or '25 min'.
  ///
  /// In en, this message translates to:
  /// **'You paid {service} the same amount {ago} ago'**
  String deskInvPayerSameBillTitle(String service, String ago);

  /// Text under the same-bill warning.
  ///
  /// In en, this message translates to:
  /// **'Check that this is a new bill before you pay it.'**
  String get deskInvPayerSameBillText;

  /// A past duration in hours and minutes, used inside another sentence, e.g. '3 h 10 min'.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String deskInvPayerAgoHours(int hours, int minutes);

  /// A past duration in minutes, used inside another sentence, e.g. '25 min'.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String deskInvPayerAgoMinutes(int minutes);

  /// Label: the network fee the user pays on top of the invoice.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get deskInvPayerFee;

  /// Label: invoice amount plus fee.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deskInvPayerTotal;

  /// Label: spendable balance left after paying.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get deskInvPayerBalanceAfter;

  /// Caption under the service's message on Review invoice: the text is untrusted.
  ///
  /// In en, this message translates to:
  /// **'Written by the service. Your wallet does not check it.'**
  String get deskInvPayerMessageCaption;

  /// Label: the address the payment goes to (stored in the trusted list).
  ///
  /// In en, this message translates to:
  /// **'Pays to'**
  String get deskInvPayerPaysTo;

  /// The service's label and when the user added it to trusted services, e.g. 'Coffee Roasters, trusted since 2 Sep 2026'.
  ///
  /// In en, this message translates to:
  /// **'{service}, trusted since {date}'**
  String deskInvPayerTrustedSince(String service, String date);

  /// Label: time left before the invoice expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get deskInvPayerExpires;

  /// Label: the block before which the payment cannot be included. Always None for a valid invoice.
  ///
  /// In en, this message translates to:
  /// **'Lock height'**
  String get deskInvPayerLockHeight;

  /// Value of Lock height: the payment is not locked to a later block.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get deskInvPayerLockNone;

  /// Label (Advanced): when the invoice arrived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get deskInvPayerReceived;

  /// Reason Approve is disabled: the spendable balance is below amount plus fee.
  ///
  /// In en, this message translates to:
  /// **'Not enough spendable funds'**
  String get deskInvPayerShort;

  /// Text under the not-enough-funds reason. total and spendable are formatted amounts.
  ///
  /// In en, this message translates to:
  /// **'You need {total} EPIC spendable; you have {spendable} EPIC. Funds still confirming count once they have 3 confirmations.'**
  String deskInvPayerShortText(String total, String spendable);

  /// Reason Approve is disabled: the wallet's node cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'The node is not answering'**
  String get deskInvPayerNodeDownTitle;

  /// Text under the node-down reason. The wallet never switches node by itself.
  ///
  /// In en, this message translates to:
  /// **'The wallet cannot check your funds, so it cannot pay. Approve works again once the node answers; you can pick another node in Settings › Node.'**
  String get deskInvPayerNodeDownText;

  /// Read-only Review invoice: the invoice was already approved and paid.
  ///
  /// In en, this message translates to:
  /// **'This invoice is paid. Nothing more can be paid on it.'**
  String get deskInvPayerPaid;

  /// Read-only Review invoice: the user declined it.
  ///
  /// In en, this message translates to:
  /// **'You declined this invoice. Nothing was paid.'**
  String get deskInvPayerDeclinedText;

  /// Button on a read-only Review invoice page: go back to Requests › To pay.
  ///
  /// In en, this message translates to:
  /// **'Back to Invoices'**
  String get deskInvPayerBack;

  /// Title of the approve dialog. amount and fee are formatted numbers; service is the user's label.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} EPIC + {fee} fee to {service}?'**
  String deskInvPayerApproveTitle(String amount, String fee, String service);

  /// Text of the approve dialog. total is the formatted amount plus fee.
  ///
  /// In en, this message translates to:
  /// **'{total} EPIC leaves your wallet. Enter the wallet password to approve.'**
  String deskInvPayerApproveText(String total);

  /// Label of the password field in the approve dialog.
  ///
  /// In en, this message translates to:
  /// **'Wallet password'**
  String get deskInvPayerPassword;

  /// Field error in the approve dialog.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Nothing was paid.'**
  String get deskInvPayerWrongPassword;

  /// Field error in the approve dialog when the password is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the wallet password.'**
  String get deskInvPayerEnterPassword;

  /// Main button of the approve dialog.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get deskInvPayerPay;

  /// Button: close a dialog without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deskInvPayerCancel;

  /// Button: close a dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get deskInvPayerClose;

  /// Error in the approve dialog: the pay call failed because the node is down.
  ///
  /// In en, this message translates to:
  /// **'The node is not answering. Nothing was paid.'**
  String get deskInvPayerNodeDownPay;

  /// Error in the approve dialog: the invoice was paid or declined elsewhere (double pay prevented).
  ///
  /// In en, this message translates to:
  /// **'This invoice was already answered. Nothing more was paid.'**
  String get deskInvPayerAlreadyAnswered;

  /// Error in the approve dialog for any other refusal (amount mismatch, invalid).
  ///
  /// In en, this message translates to:
  /// **'This invoice cannot be paid. Nothing was paid.'**
  String get deskInvPayerCannotPay;

  /// Toast after Approve when the relay did not take the payment.
  ///
  /// In en, this message translates to:
  /// **'Signed, not delivered'**
  String get deskInvPayerNotDeliveredToast;

  /// Toast text after Approve when the relay did not take the payment.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server is not answering. Retry it under Invoices › Pay; no second approval.'**
  String get deskInvPayerNotDeliveredToastText;

  /// Toast when Retry failed.
  ///
  /// In en, this message translates to:
  /// **'Still not delivered'**
  String get deskInvPayerRetryFailed;

  /// Toast text when Retry failed.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server is not answering. The payment stays signed on this device.'**
  String get deskInvPayerRetryFailedText;

  /// Title of the cancel payment dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel this payment?'**
  String get deskInvPayerCancelTitle;

  /// Cancel payment dialog text (decision D-2): cancelling is local; the signed payment can still complete.
  ///
  /// In en, this message translates to:
  /// **'Cancelling unlocks your funds here. The service still holds your signed payment, so it could still complete until these funds are spent again.'**
  String get deskInvPayerCancelText;

  /// Which payment the cancel dialog is about. amount is formatted.
  ///
  /// In en, this message translates to:
  /// **'{amount} EPIC to {service}'**
  String deskInvPayerCancelWho(String amount, String service);

  /// Button: close the cancel dialog and keep the payment.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get deskInvPayerKeepPayment;

  /// Error: the payment is in the pool or on chain.
  ///
  /// In en, this message translates to:
  /// **'Already on its way: it cannot be cancelled.'**
  String get deskInvPayerOnItsWay;

  /// Error: cancelling needs the node, which is not answering.
  ///
  /// In en, this message translates to:
  /// **'Cannot check the network now; try again when the node is reachable.'**
  String get deskInvPayerCannotCheck;

  /// Toast after a payment was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get deskInvPayerCancelled;

  /// Toast text after a payment was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Your funds are unlocked.'**
  String get deskInvPayerCancelledText;

  /// Toast after the user declined an invoice; it leaves To pay at once.
  ///
  /// In en, this message translates to:
  /// **'Invoice declined. Nothing was paid.'**
  String get deskInvPayerDeclined;

  /// Checkbox on the Cancel payment confirm (decision D-2): after the cancel, move the unlocked coins to this wallet itself.
  ///
  /// In en, this message translates to:
  /// **'Spend them to myself now'**
  String get deskInvPayerSpendToSelf;

  /// Help under the Spend them to myself now checkbox.
  ///
  /// In en, this message translates to:
  /// **'Makes the cancel final: the service\'s signed copy can no longer complete. Costs a network fee.'**
  String get deskInvPayerSpendToSelfHelp;

  /// Toast text after a cancel whose coins were spent to the wallet itself.
  ///
  /// In en, this message translates to:
  /// **'Your funds are unlocked and moved within this wallet. The cancel is final.'**
  String get deskInvPayerSpentText;

  /// Toast text after a cancel whose spend to the wallet itself failed.
  ///
  /// In en, this message translates to:
  /// **'Your funds are unlocked, but moving them did not work. The cancel is not final yet.'**
  String get deskInvPayerSpendFailedText;

  /// Review: the invoice's kernel is locked above the chain's tip (LEPIC refuses it and stores nothing).
  ///
  /// In en, this message translates to:
  /// **'This invoice cannot be paid: it is locked until a later block. Nothing was paid.'**
  String get deskInvPayerLocked;

  /// Approve dialog: the Epicbox server could not be reached before anything was signed or stored.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server is not answering. Nothing was paid.'**
  String get deskInvPayerRelayDownPay;

  /// Settings › Receiving section title: the invoice address and who may bill you.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvSetTitle;

  /// Intro of the Invoices settings section.
  ///
  /// In en, this message translates to:
  /// **'Services you trust bill this wallet at its invoice address. Nothing is paid until you approve each invoice.'**
  String get deskInvSetIntro;

  /// Label of this wallet's separate address for receiving invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoice address'**
  String get deskInvSetAddressLabel;

  /// Warning beside the invoice address and its QR code: never use it to receive money.
  ///
  /// In en, this message translates to:
  /// **'Give it only to services you trust. It does not receive payments.'**
  String get deskInvSetAddressWarning;

  /// Button: copy the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get deskInvSetCopy;

  /// Notice after copying the invoice address, repeating the warning.
  ///
  /// In en, this message translates to:
  /// **'Invoice address copied. Give it only to services you trust; it does not receive payments.'**
  String get deskInvSetCopied;

  /// Button: show the invoice address as a QR code.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get deskInvSetQrShow;

  /// Button: hide the QR code.
  ///
  /// In en, this message translates to:
  /// **'Hide QR'**
  String get deskInvSetQrHide;

  /// Screen-reader label of the invoice address QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code of your invoice address'**
  String get deskInvSetQrLabel;

  /// Which invoice address this is (it changes when rotated), e.g. 'Invoice address 2'.
  ///
  /// In en, this message translates to:
  /// **'Invoice address {index}'**
  String deskInvSetIndex(int index);

  /// List title: services and contacts allowed to send you invoices.
  ///
  /// In en, this message translates to:
  /// **'Trusted senders'**
  String get deskInvSetTrusted;

  /// Empty trusted list.
  ///
  /// In en, this message translates to:
  /// **'No trusted senders. Invoices from anyone else are ignored unread.'**
  String get deskInvSetTrustedNone;

  /// When a sender was trusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted since {date}'**
  String deskInvSetSince(String date);

  /// Tag on a trusted sender that is one of your contacts.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get deskInvSetContactTag;

  /// Button: stop trusting a sender.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deskInvSetRemove;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Stop trusting {name}?'**
  String deskInvSetRemoveTitle(String name);

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'{name} can no longer send you invoices. Invoices already waiting stay until you answer them or they expire.'**
  String deskInvSetRemoveBody(String name);

  /// Notice after removing a trusted sender.
  ///
  /// In en, this message translates to:
  /// **'{name} can no longer send you invoices.'**
  String deskInvSetRemoved(String name);

  /// Dialog button: keep as it is.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get deskInvSetKeep;

  /// Button: add a service allowed to send you invoices.
  ///
  /// In en, this message translates to:
  /// **'Trust a sender'**
  String get deskInvSetAdd;

  /// Text of the Trust a sender dialog.
  ///
  /// In en, this message translates to:
  /// **'A trusted sender can bill this wallet at its invoice address. Nothing is paid until you approve each invoice with your wallet password.'**
  String get deskInvSetAddBody;

  /// Field label: your name for the sender, shown on its invoices.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deskInvSetName;

  /// Error: name is empty.
  ///
  /// In en, this message translates to:
  /// **'Give the sender a name.'**
  String get deskInvSetNameMissing;

  /// Field label: the Epicbox address the service shows on its site.
  ///
  /// In en, this message translates to:
  /// **'Their payments address'**
  String get deskInvSetSenderAddress;

  /// Error: address is empty.
  ///
  /// In en, this message translates to:
  /// **'Paste the address the service shows.'**
  String get deskInvSetSenderMissing;

  /// Error: not an Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid Epicbox address.'**
  String get deskInvSetSenderInvalid;

  /// Dialog button: add the sender to the trusted list.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get deskInvSetTrust;

  /// Notice after trusting a sender.
  ///
  /// In en, this message translates to:
  /// **'{name} can now send you invoices.'**
  String deskInvSetAdded(String name);

  /// Quiet line: messages to the invoice address from untrusted senders, dropped without opening.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message from a sender you do not trust was ignored unread.} other{{count} messages from senders you do not trust were ignored unread.}}'**
  String deskInvSetDropped(int count);

  /// Button (Advanced): move to a fresh invoice address.
  ///
  /// In en, this message translates to:
  /// **'New invoice address'**
  String get deskInvSetRotate;

  /// Text beside the rotate button.
  ///
  /// In en, this message translates to:
  /// **'Services that have the old one can no longer send you invoices.'**
  String get deskInvSetRotateHint;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Make a new invoice address?'**
  String get deskInvSetRotateTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Services that have the old one can no longer send you invoices. Give the new one to every service that bills you.'**
  String get deskInvSetRotateBody;

  /// Dialog button: rotate the invoice address.
  ///
  /// In en, this message translates to:
  /// **'Make new address'**
  String get deskInvSetRotateConfirm;

  /// Notice after rotating.
  ///
  /// In en, this message translates to:
  /// **'New invoice address ready. Give it to your services.'**
  String get deskInvSetRotated;

  /// Setting (Advanced): how long requests and invoices stay payable.
  ///
  /// In en, this message translates to:
  /// **'Time to pay'**
  String get deskInvSetExpiry;

  /// Text of the Time to pay setting.
  ///
  /// In en, this message translates to:
  /// **'How long an invoice you issue stays payable, and how long one you receive waits for you. At most 48 hours.'**
  String get deskInvSetExpiryHint;

  /// A duration in hours, e.g. '24 hours'.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String deskInvSetHours(int hours);

  /// Dialog button: close without changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deskInvSetCancel;

  /// Section title in a contact's detail: their invoice address and trust.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskInvSetContactSection;

  /// Contact field: where requests to this contact go.
  ///
  /// In en, this message translates to:
  /// **'Their invoice address'**
  String get deskInvSetTheirInvoice;

  /// Contact detail when no invoice address is saved.
  ///
  /// In en, this message translates to:
  /// **'No invoice address saved. Ask them for it to issue invoices to them.'**
  String get deskInvSetTheirInvoiceNone;

  /// Contact switch: this contact may send you invoices.
  ///
  /// In en, this message translates to:
  /// **'Trusted for invoices'**
  String get deskInvSetTrustedSwitch;

  /// Text of the trusted switch.
  ///
  /// In en, this message translates to:
  /// **'Lets this contact bill you. Nothing is paid until you approve an invoice.'**
  String get deskInvSetTrustedSwitchHelp;

  /// Why Request payment is disabled for a contact.
  ///
  /// In en, this message translates to:
  /// **'Needs their invoice address.'**
  String get deskInvSetIssueNeeds;

  /// Contact action: copy your invoice address to give to this contact.
  ///
  /// In en, this message translates to:
  /// **'Share invoice address'**
  String get deskInvSetShare;

  /// Text beside Request a payment on Receive.
  ///
  /// In en, this message translates to:
  /// **'Ask a contact or a service to pay you. Their wallet must take invoices.'**
  String get deskInvSetReceiveHint;

  /// Line under the invoice address while its index is 1: a wallet restored without its history file starts again at the first invoice address, so services hold an old one (flow.md §2, P-16).
  ///
  /// In en, this message translates to:
  /// **'Restored this wallet from its recovery phrase? Give services this invoice address again.'**
  String get deskInvSetRestoredHint;

  /// Title of the confirm before the epicbox server of the open wallet changes.
  ///
  /// In en, this message translates to:
  /// **'Switch epicbox server?'**
  String get serverSwitchRelayTitle;

  /// Body of that confirm: the address keeps its key and takes the new server.
  ///
  /// In en, this message translates to:
  /// **'The epicbox address changes to …@{relay}. Senders need the new address. Payments sent to the old address stay on the old server.'**
  String serverSwitchRelayBody(String relay);

  /// Button of that confirm that switches the server.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get serverSwitchRelayConfirm;

  /// Tooltip of the small ? button that opens one help topic.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpButton;

  /// Hint of the search field at the top of Help.
  ///
  /// In en, this message translates to:
  /// **'Search help'**
  String get helpSearchHint;

  /// Caption at the top of Help in every language but English: the topics are not translated yet.
  ///
  /// In en, this message translates to:
  /// **'Help is in English for now.'**
  String get helpEnglishOnly;

  /// Label and tooltip of the switch at the top of Help that picks the language of the help topics only, not the app's (e.g. 'Help language: Deutsch'). Short.
  ///
  /// In en, this message translates to:
  /// **'Help language'**
  String get helpLanguageLabel;

  /// Help search with no result. {query} is what was typed.
  ///
  /// In en, this message translates to:
  /// **'No help matches \"{query}\"'**
  String helpNoMatch(String query);

  /// Help search result count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 topic} other{{count} topics}}'**
  String helpMatchCount(int count);

  /// Button under the handshake help topic: opens the animated handshake sheet.
  ///
  /// In en, this message translates to:
  /// **'Show how it works'**
  String get helpShowHandshake;

  /// Heading over the other topics of the same section at the end of a help topic.
  ///
  /// In en, this message translates to:
  /// **'More in this section'**
  String get helpMoreInSection;

  /// Send review row: the spendable balance once this send and its fee are out.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get sendBalanceAfter;

  /// Send review row: what stays spendable while the send's change confirms (spendable minus the outputs the send locks).
  ///
  /// In en, this message translates to:
  /// **'Spendable until change confirms'**
  String get sendSpendableUntilChange;

  /// Caption under the Spendable until change confirms row.
  ///
  /// In en, this message translates to:
  /// **'The change comes back once the send confirms.'**
  String get sendSpendableUntilChangeHint;

  /// Notice after the node or Epicbox server changed live, without locking the wallet. {host} is the new host.
  ///
  /// In en, this message translates to:
  /// **'Switched to {host}'**
  String serverSwitched(String host);

  /// Send and Receive method: straight to the other wallet, at an http(s) or onion address.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get methodDirect;

  /// Under Send's empty To field on Direct: the two shapes a Direct address takes. Keep the addresses as they are.
  ///
  /// In en, this message translates to:
  /// **'http://host:3415 or xxxx….onion'**
  String get methodDirectShape;

  /// Send's strip line for Direct.
  ///
  /// In en, this message translates to:
  /// **'Their wallet must be open. An onion address goes over Tor.'**
  String get methodSendDirectLine;

  /// Screen reader label of the Direct picture.
  ///
  /// In en, this message translates to:
  /// **'Direct: the payment goes straight to the recipient\'s wallet, which must be open'**
  String get methodArtLabelDirect;

  /// Receive's Epicbox strip line: payments arrive even while the wallet is closed (the Epicbox server holds them). No "app": the web demo shows it too.
  ///
  /// In en, this message translates to:
  /// **'Works with the wallet closed.'**
  String get methodReceiveEpicboxShort;

  /// Receive's Direct strip title.
  ///
  /// In en, this message translates to:
  /// **'Straight to this wallet.'**
  String get methodReceiveDirectTitle;

  /// Receive's Direct strip line: the onion address answers only while the app runs.
  ///
  /// In en, this message translates to:
  /// **'Works while the app is open.'**
  String get methodReceiveDirectLine;

  /// A strip line followed by 'Over Tor.' when its connection goes through Tor.
  ///
  /// In en, this message translates to:
  /// **'{line} Over Tor.'**
  String methodLineOverTor(String line);

  /// Tag beside Send's To label for 3 s after the address moved the method to Direct.
  ///
  /// In en, this message translates to:
  /// **'Direct address'**
  String get sendSwitchedDirect;

  /// Read out once when the address moved Send's method to Direct.
  ///
  /// In en, this message translates to:
  /// **'Direct address. Method set to Direct.'**
  String get sendSwitchedDirectAnnounce;

  /// Error under To when Direct is chosen and the text is not an http(s) or onion address.
  ///
  /// In en, this message translates to:
  /// **'A Direct address starts with http:// or https://, or ends in .onion.'**
  String get sendDirectAddressShape;

  /// Tag on Send and Review: this connection stays on the clearnet although Tor is on.
  ///
  /// In en, this message translates to:
  /// **'Not over Tor'**
  String get torNotOverTor;

  /// Notice under Send's To: an onion address needs Tor, which is off.
  ///
  /// In en, this message translates to:
  /// **'Needs Tor.'**
  String get torNeeds;

  /// Button that turns the Tor switch on.
  ///
  /// In en, this message translates to:
  /// **'Turn on Tor'**
  String get torTurnOn;

  /// Button that turns the Tor switch off.
  ///
  /// In en, this message translates to:
  /// **'Turn Tor off'**
  String get torTurnOff;

  /// Notice on Send while Tor is on but not connected: nothing that needs it goes.
  ///
  /// In en, this message translates to:
  /// **'Tor is not connected.'**
  String get torNotConnectedNotice;

  /// Send's Review button while Tor starts.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Tor'**
  String get torWaiting;

  /// Tor state word: the switch is on and Tor is connecting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get torWordStarting;

  /// Tor state word: Tor is on but could not connect.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get torWordNotConnected;

  /// Text link on Receive's Direct tab to Settings › Privacy.
  ///
  /// In en, this message translates to:
  /// **'Tor settings'**
  String get torSettingsLink;

  /// The one Tor switch (Settings › Privacy) and the status card’s Tor row: the label, with no description in the row.
  ///
  /// In en, this message translates to:
  /// **'Tor Network'**
  String get torNetworkLabel;

  /// Tooltip of the Tor Network switch and status row (its info icon): what the switch does and what Tor is, in plain words. Never list what does not go over Tor.
  ///
  /// In en, this message translates to:
  /// **'Network activity goes through the Tor network. Tor hides the wallet’s internet address: each connection passes through several volunteer-run relays, so no server learns where the wallet is. Notifications are off while Tor is on.'**
  String get torNetworkHint;

  /// Receive tab: receiving straight to this wallet at its onion address.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get receiveTabDirect;

  /// Receive's Direct tab while Tor is off.
  ///
  /// In en, this message translates to:
  /// **'Direct receiving needs Tor.'**
  String get receiveDirectNeedsTor;

  /// Caption under 'Direct receiving needs Tor.'
  ///
  /// In en, this message translates to:
  /// **'Senders use the Epicbox address meanwhile.'**
  String get receiveDirectMeanwhile;

  /// Status card: read out after a service whose connection goes through Tor.
  ///
  /// In en, this message translates to:
  /// **'over Tor'**
  String get netStatusOverTor;

  /// The Notifications switch in Settings: the label only, its explanation is the info tooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Tooltip (info icon) of the Notifications switch.
  ///
  /// In en, this message translates to:
  /// **'Uses Google’s notification service. No sensitive data is shared.'**
  String get settingsNotificationsHint;

  /// State line under the Notifications switch while it is on and Tor is on.
  ///
  /// In en, this message translates to:
  /// **'Paused while Tor is on'**
  String get settingsPushPaused;

  /// Confirm when notifications are turned on while the wallet is on another Epicbox relay: only the BT Labs relay can push, and Google carries the notification.
  ///
  /// In en, this message translates to:
  /// **'Notifications use the BT Labs Epicbox and Google’s notification service. No sensitive data is shared.'**
  String get pushConfirmRelayBody;

  /// Second line of that confirm: the wallet is moved to the BT Labs relay, so its Epicbox address ends in @flooepicbox.btlabs.uk from now on.
  ///
  /// In en, this message translates to:
  /// **'Your Epicbox address will change. Share the new one.'**
  String get pushConfirmRelayAddress;

  /// Notice when moving to the BT Labs relay for notifications was refused.
  ///
  /// In en, this message translates to:
  /// **'The relay could not be switched. Notifications stay off.'**
  String get pushRelaySwitchFailed;

  /// Title of the confirmation before notifications are turned on.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications?'**
  String get pushConfirmTitle;

  /// Body of the confirmation before notifications are turned on.
  ///
  /// In en, this message translates to:
  /// **'Notifications use Google’s notification service. No sensitive data is shared.'**
  String get pushConfirmBody;

  /// The confirm button of the notifications dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get pushConfirmAction;

  /// Quiet notice once notifications work again after Tor was turned off.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get pushNoticeOn;

  /// Notice after the user turned notifications off.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get pushNoticeOff;

  /// One-time reminder, about a minute after the first unlock, that notifications exist.
  ///
  /// In en, this message translates to:
  /// **'Notifications are available in Settings.'**
  String get pushNoticeAvailable;

  /// Status card, Settings › Servers and the server lists: this connection (node or Epicbox) goes through Tor now. Same words as desktop's 'Over Tor'.
  ///
  /// In en, this message translates to:
  /// **'Over Tor'**
  String get torWayOver;

  /// Status card, Settings › Servers and the server lists: Tor is on but not connected yet (or not connected at all), so this connection waits for it and never goes on the clearnet meanwhile.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Tor'**
  String get torWayWaiting;

  /// Detail after 'Waiting for Tor' when Tor failed: read out and shown as the row's hint.
  ///
  /// In en, this message translates to:
  /// **'Tor is not connected.'**
  String get torWayNotConnected;

  /// Line in the payment review when the send spends every spendable output (strategy All) and change comes back: it is always one change output, whatever Split change says.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Uses its 1 output · change 1 output} other{Uses all {count} outputs · change 1 output}}'**
  String sendUsesAllOutputs(int count);

  /// An error message the user reads when nothing more is known (toast, inline error).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get deskErrSomethingWrong;

  /// An error message the user reads when a password is wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get deskErrWrongPassword;

  /// An error message the user reads when the recovery phrase is not a valid phrase.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase not valid'**
  String get deskErrPhraseInvalid;

  /// An error message the user reads when creating a wallet that already exists.
  ///
  /// In en, this message translates to:
  /// **'A wallet exists already'**
  String get deskErrWalletExists;

  /// An error message the user reads when no wallet is found.
  ///
  /// In en, this message translates to:
  /// **'No wallet found'**
  String get deskErrWalletNotFound;

  /// An error message the user reads when the node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Node not answering'**
  String get deskErrNodeNotAnswering;

  /// An error message the user reads when the spendable balance is too small.
  ///
  /// In en, this message translates to:
  /// **'Not enough funds'**
  String get deskErrNotEnoughFunds;

  /// An error message the user reads when a transaction file does not belong to this wallet.
  ///
  /// In en, this message translates to:
  /// **'Not a transaction file for this wallet'**
  String get deskErrNotTxFile;

  /// An error message the user reads when the Epicbox server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Epicbox server not reachable'**
  String get deskErrEpicboxUnreachable;

  /// An error message the user reads when an address is not an http or https address.
  ///
  /// In en, this message translates to:
  /// **'Not an http(s) address'**
  String get deskErrNotHttpAddress;

  /// An error message the user reads when a send to a plain http address was not confirmed by the user.
  ///
  /// In en, this message translates to:
  /// **'Plain HTTP not confirmed'**
  String get deskErrPlainHttp;

  /// An error message the user reads when an address is not a Tor onion address.
  ///
  /// In en, this message translates to:
  /// **'Not an onion address'**
  String get deskErrNotOnion;

  /// An error message the user reads when a Tor send is asked while Tor is not connected.
  ///
  /// In en, this message translates to:
  /// **'Tor is not connected'**
  String get deskErrTorNotConnected;

  /// An error message the user reads when a Tor send finds no wallet at the onion address.
  ///
  /// In en, this message translates to:
  /// **'The recipient’s wallet is not reachable over Tor'**
  String get deskErrOnionUnreachable;

  /// An error message the user reads when the wallet is busy with another operation.
  ///
  /// In en, this message translates to:
  /// **'Wallet busy. Try again in a moment.'**
  String get deskErrWalletBusy;

  /// An error message the user reads (also a notice on Overview) when the wallet database is damaged and is being rebuilt.
  ///
  /// In en, this message translates to:
  /// **'Wallet database damaged, rebuilding'**
  String get deskErrDbDamaged;

  /// An error message the user reads when a payment has expired.
  ///
  /// In en, this message translates to:
  /// **'Payment expired'**
  String get deskErrPaymentExpired;

  /// An error message the user reads when an invoice cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found'**
  String get deskErrInvoiceNotFound;

  /// An error message the user reads when the amount does not match the invoice.
  ///
  /// In en, this message translates to:
  /// **'Amount differs from the invoice'**
  String get deskErrAmountMismatch;

  /// An error message the user reads when an invoice is already paid.
  ///
  /// In en, this message translates to:
  /// **'Invoice already paid'**
  String get deskErrInvoicePaid;

  /// An error message the user reads when an invoice is locked until a later block.
  ///
  /// In en, this message translates to:
  /// **'Invoice locked until a later block'**
  String get deskErrInvoiceLocked;

  /// An error message the user reads when an invoice changed since it was read.
  ///
  /// In en, this message translates to:
  /// **'Invoice changed'**
  String get deskErrInvoiceChanged;

  /// An error message the user reads when the wallet core did not accept an input and gave no detail.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get deskErrNotAccepted;

  /// An error message the user reads when the wallet core did not accept an input. {detail} is the core's own English sentence.
  ///
  /// In en, this message translates to:
  /// **'Not accepted: {detail}'**
  String deskErrNotAcceptedDetail(String detail);

  /// An error message the user reads when the disk failed, no detail.
  ///
  /// In en, this message translates to:
  /// **'Disk error'**
  String get deskErrDisk;

  /// An error message the user reads when the disk failed. {detail} is the system's English text.
  ///
  /// In en, this message translates to:
  /// **'Disk error: {detail}'**
  String deskErrDiskDetail(String detail);

  /// Why Tor is down: this build has no Tor program. Shown on the Tor status line.
  ///
  /// In en, this message translates to:
  /// **'Tor not included in this build'**
  String get deskErrTorMissing;

  /// Why Tor is down: the Tor network cannot be reached. Shown on the Tor status line.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the Tor network'**
  String get deskErrTorNetwork;

  /// Why Tor is down: the computer's clock is wrong. Shown on the Tor status line.
  ///
  /// In en, this message translates to:
  /// **'The computer’s clock is wrong'**
  String get deskErrTorClock;

  /// Why Tor receiving does not work: the onion address is not published. Shown on the Tor status line.
  ///
  /// In en, this message translates to:
  /// **'Onion address not published'**
  String get deskErrOnionNotPublished;

  /// Why Tor is down: the Tor program did not start. Shown on the Tor status line.
  ///
  /// In en, this message translates to:
  /// **'Tor did not start'**
  String get deskErrTorStart;

  /// Why Tor is down: Tor stopped. Shown on the Tor status line.
  ///
  /// In en, this message translates to:
  /// **'Tor stopped'**
  String get deskErrTorStopped;

  /// An error message the user reads when a second balance recheck is asked while one runs.
  ///
  /// In en, this message translates to:
  /// **'A scan is already running.'**
  String get deskErrScanRunning;

  /// An error message the user reads when a cancel was refused because the node already has the payment.
  ///
  /// In en, this message translates to:
  /// **'Not cancelled: the node already has this payment.'**
  String get deskErrCancelRefused;

  /// An error message the user reads when an action needs the wallet to be unlocked.
  ///
  /// In en, this message translates to:
  /// **'The wallet is locked'**
  String get deskErrWalletLocked;

  /// An error message the user reads when an action is asked while the wallet is locking.
  ///
  /// In en, this message translates to:
  /// **'The wallet is locking'**
  String get deskErrWalletLocking;

  /// An error message the user reads when the damaged wallet database could not be reopened. {detail} is the second error.
  ///
  /// In en, this message translates to:
  /// **'Wallet database damaged. {detail}'**
  String deskErrDbDamagedDetail(String detail);

  /// An error message the user reads when a change failed and the wallet had to be closed. {detail} is the reason.
  ///
  /// In en, this message translates to:
  /// **'Wallet closed: {detail}. Unlock again.'**
  String deskErrWalletClosed(String detail);

  /// An error message the user reads when a settings change failed. {detail} is the reason.
  ///
  /// In en, this message translates to:
  /// **'Not changed: {detail}'**
  String deskErrNotChanged(String detail);

  /// An error message the user reads when a new password is too short. {count} is the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use at least {count} character} other{Use at least {count} characters}}'**
  String deskErrPasswordShort(int count);

  /// An error message the user reads when the wallet is not in the wallet list.
  ///
  /// In en, this message translates to:
  /// **'Wallet not in the list'**
  String get deskErrWalletNotListed;

  /// An error message the user reads when the wallet list was written by a newer app version.
  ///
  /// In en, this message translates to:
  /// **'Update the app to change the list'**
  String get deskErrUpdateApp;

  /// An error message the user reads when the wallet list could not be changed, no detail.
  ///
  /// In en, this message translates to:
  /// **'Wallet list not changed'**
  String get deskErrListNotChanged;

  /// An error message the user reads when a wallet is deleted without being open.
  ///
  /// In en, this message translates to:
  /// **'Open the wallet to delete it'**
  String get deskErrOpenToDelete;

  /// An error message the user reads when a password is needed and empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the password'**
  String get deskErrEnterPassword;

  /// An error message the user reads when a wallet's folder is gone.
  ///
  /// In en, this message translates to:
  /// **'Wallet folder not found'**
  String get deskErrFolderNotFound;

  /// An error message the user reads when a recovery phrase belongs to a wallet that is already listed. {name} is the listed wallet's name.
  ///
  /// In en, this message translates to:
  /// **'This wallet is already here: {name}'**
  String deskErrAlreadyHere(String name);

  /// Shown in the import wizard for an older wallet on the test network.
  ///
  /// In en, this message translates to:
  /// **'Test network wallet. Only mainnet wallets can be imported.'**
  String get deskErrTestNet;

  /// Shown in the import wizard when every wallet found is already in the app.
  ///
  /// In en, this message translates to:
  /// **'This wallet is in the app already.'**
  String get deskErrWalletInApp;

  /// An error message the user reads in the import wizard when the chosen old wallet is gone.
  ///
  /// In en, this message translates to:
  /// **'Wallet not found. Search again.'**
  String get deskErrWalletNotFoundSearch;

  /// An error message the user reads in the import wizard when the old password is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the old password'**
  String get deskErrEnterOldPassword;

  /// An error message the user reads in the import wizard when the old password is shorter than the app's minimum. {count} is the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{The old password is short. Choose a new one of at least {count} character.} other{The old password is short. Choose a new one of at least {count} characters.}}'**
  String deskErrOldPasswordShort(int count);

  /// An error message the user reads in the import wizard when wallet.seed cannot be read from disk.
  ///
  /// In en, this message translates to:
  /// **'The wallet.seed file could not be read'**
  String get deskErrSeedUnreadable;

  /// An error message the user reads in the import wizard when the chosen file is not a wallet.seed file.
  ///
  /// In en, this message translates to:
  /// **'Not a wallet.seed file'**
  String get deskErrNotSeedFile;

  /// An error message the user reads in the import wizard when the wallet is already in the app. {name} is its name.
  ///
  /// In en, this message translates to:
  /// **'Already in the app as {name}'**
  String deskErrAlreadyInApp(String name);

  /// An error message the user reads in the import wizard when the old wallet's password is wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong old password'**
  String get deskErrWrongOldPassword;

  /// An error message the user reads in the import wizard when the new wallet could not be listed.
  ///
  /// In en, this message translates to:
  /// **'Wallet list not saved'**
  String get deskErrListNotSaved;

  /// A line of the import wizard's result: the old wallet's seed was read.
  ///
  /// In en, this message translates to:
  /// **'Seed read'**
  String get deskErrProofSeedRead;

  /// A line of the import wizard's result: the new wallet was created.
  ///
  /// In en, this message translates to:
  /// **'Wallet created'**
  String get deskErrProofWalletCreated;

  /// A line of the import wizard's result: contacts taken over from the old app.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 contact added} other{{count} contacts added}}'**
  String deskErrProofContacts(int count);

  /// A line of the import wizard's result: the old app's node was added to the node list. {name} is the node's label.
  ///
  /// In en, this message translates to:
  /// **'Node {name} added to the node list'**
  String deskErrProofNode(String name);

  /// A line of the import wizard's result: the old app used another Epicbox server than this app. Both are host names.
  ///
  /// In en, this message translates to:
  /// **'The older app used the Epicbox server {old}; this app uses {current}'**
  String deskErrProofEpicbox(String old, String current);

  /// A line of the import wizard's result: the old wallet's folder was only read.
  ///
  /// In en, this message translates to:
  /// **'Old folder unchanged'**
  String get deskErrProofFolderUnchanged;

  /// A line of the import wizard's result: another program changed the old folder meanwhile.
  ///
  /// In en, this message translates to:
  /// **'Old folder changed by another program'**
  String get deskErrProofFolderChanged;

  /// A line of the import wizard's result: the old payment history was imported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{History: 1 transaction} other{History: {count} transactions}}'**
  String deskErrProofHistory(int count);

  /// A line of the import wizard's result.
  ///
  /// In en, this message translates to:
  /// **'History already imported'**
  String get deskErrProofHistoryAlready;

  /// A line of the import wizard's result.
  ///
  /// In en, this message translates to:
  /// **'No history in the old folder; the scan restores the balance'**
  String get deskErrProofHistoryNone;

  /// A line of the import wizard's result.
  ///
  /// In en, this message translates to:
  /// **'History of Epic Wallet 5.3 or older is not readable; the scan restores the balance'**
  String get deskErrProofHistoryOld;

  /// A line of the import wizard's result.
  ///
  /// In en, this message translates to:
  /// **'History not imported: the older wallet is running. It is imported at the next unlock'**
  String get deskErrProofHistoryBusy;

  /// A line of the import wizard's result.
  ///
  /// In en, this message translates to:
  /// **'History not imported: it belongs to another wallet'**
  String get deskErrProofHistoryOther;

  /// A line of the import wizard's result.
  ///
  /// In en, this message translates to:
  /// **'History not imported: the old database could not be read; the scan restores the balance'**
  String get deskErrProofHistoryUnreadable;

  /// An error message the user reads when a sync could not reach the node.
  ///
  /// In en, this message translates to:
  /// **'The node did not answer'**
  String get deskErrNodeNoAnswer;

  /// An error message the user reads when a split or consolidation was stored but the node did not take it.
  ///
  /// In en, this message translates to:
  /// **'Not posted'**
  String get deskErrNotPosted;

  /// Why a send failed: the address is not an Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'Not an Epicbox address'**
  String get deskErrNotEpicboxAddress;

  /// Why a file send failed: the transaction file could not be saved.
  ///
  /// In en, this message translates to:
  /// **'File not saved. The payment waits in Activity; cancel it there to unlock the funds.'**
  String get deskErrFileNotSaved;

  /// Why a send to an onion address failed: Tor is off.
  ///
  /// In en, this message translates to:
  /// **'Tor is off. Turn on Tor to send to an onion address.'**
  String get deskErrTorOffSend;

  /// Why a send to an onion address failed: Tor is still starting.
  ///
  /// In en, this message translates to:
  /// **'Tor is still connecting. Try again in a moment.'**
  String get deskErrTorConnecting;

  /// Why a direct send failed: nothing was sent.
  ///
  /// In en, this message translates to:
  /// **'The recipient’s wallet did not answer or refused.'**
  String get deskErrRecipientNoAnswer;

  /// Why a direct send failed: the payment may exist and waits in Activity.
  ///
  /// In en, this message translates to:
  /// **'The recipient’s wallet did not answer or refused. The payment waits in Activity; cancel it there to unlock the funds.'**
  String get deskErrRecipientNoAnswerWaits;

  /// Why an Epicbox send failed: the payment waits in Activity.
  ///
  /// In en, this message translates to:
  /// **'Not delivered. The payment waits in Activity; cancel it there to unlock the funds.'**
  String get deskErrNotDelivered;

  /// Why a send ended: the wallet was locked during it.
  ///
  /// In en, this message translates to:
  /// **'Interrupted by the lock. It may have gone out: check Activity after unlocking.'**
  String get deskErrInterruptedLock;

  /// Why a send failed with a reason, when the payment may exist. {detail} is the reason without its final full stop.
  ///
  /// In en, this message translates to:
  /// **'{detail}. The payment waits in Activity; cancel it there to unlock the funds.'**
  String deskErrStoredWaits(String detail);

  /// Why a direct send failed: both wallets signed but the node refused the transaction.
  ///
  /// In en, this message translates to:
  /// **'Signed by both wallets, but the node refused it. Cancel it in Activity to unlock the funds.'**
  String get deskErrNodeRefused;

  /// An error message the user reads when a transaction file cannot be read from disk.
  ///
  /// In en, this message translates to:
  /// **'File not readable'**
  String get deskErrFileNotReadable;

  /// An error message the user reads when a chosen file is not a transaction file.
  ///
  /// In en, this message translates to:
  /// **'Not a transaction file'**
  String get deskErrNotTxFile2;

  /// An error message the user reads when the response file could not be written.
  ///
  /// In en, this message translates to:
  /// **'Response file not saved'**
  String get deskErrResponseNotSaved;

  /// An error message the user reads when a payment cannot be cancelled.
  ///
  /// In en, this message translates to:
  /// **'This payment cannot be cancelled'**
  String get deskErrCannotCancel;

  /// An error message the user reads when the local node is asked but this build has none.
  ///
  /// In en, this message translates to:
  /// **'No local node in this build'**
  String get deskErrNoLocalNode;

  /// An error message the user reads when the local node was stopped while starting.
  ///
  /// In en, this message translates to:
  /// **'Local node stopped'**
  String get deskErrLocalNodeStopped;

  /// An error message the user reads when the wallet was locked during a change.
  ///
  /// In en, this message translates to:
  /// **'Not changed: the wallet was locked'**
  String get deskErrNotChangedLocked;

  /// Notice on Overview when the local node did not start. {detail} is the reason.
  ///
  /// In en, this message translates to:
  /// **'Local node not started: {detail}'**
  String deskErrLocalNodeNotStarted(String detail);

  /// Reason after "Local node not started:" when nothing more is known. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get deskErrUnknown;

  /// An error message the user reads when the Epicbox server name is not valid.
  ///
  /// In en, this message translates to:
  /// **'Not a server name'**
  String get deskErrNotServerName;

  /// Why receiving over HTTP did not start: the port is used by another program.
  ///
  /// In en, this message translates to:
  /// **'Port {port} in use'**
  String deskErrPortInUse(int port);

  /// Why receiving over HTTP did not start: the port cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Port {port} not available'**
  String deskErrPortUnavailable(int port);

  /// Why receiving over HTTP stopped, no detail.
  ///
  /// In en, this message translates to:
  /// **'Stopped with an error'**
  String get deskErrStoppedWithError;

  /// An error message the user reads when changing the password failed.
  ///
  /// In en, this message translates to:
  /// **'Password not changed. The current password still opens the wallet.'**
  String get deskErrPasswordNotChanged;

  /// An error message the user reads when there are no coins to spend.
  ///
  /// In en, this message translates to:
  /// **'Nothing to spend'**
  String get deskErrNothingToSpend;

  /// Tor line of the status card and Settings › Receiving when Tor is off. Short.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskTorLineOff;

  /// Tor line of the status card and Settings › Receiving when Tor is ready. Short.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get deskTorLineReady;

  /// Tor line when the onion address is not published but sending works. {problem} is a short reason such as "Onion address not published".
  ///
  /// In en, this message translates to:
  /// **'{problem}. Sends work.'**
  String deskTorLineSendsWork(String problem);

  /// Tor line while the onion address is being published.
  ///
  /// In en, this message translates to:
  /// **'Publishing the onion address…'**
  String get deskTorLinePublishing;

  /// Tor line while Tor connects. {percent} is a number from 0 to 100.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Tor… {percent} %'**
  String deskTorLineConnecting(int percent);

  /// Title of the notice when a history backup file was exported from a different wallet.
  ///
  /// In en, this message translates to:
  /// **'Another wallet\'s backup'**
  String get deskErrHistOtherWallet;

  /// Title of the notice when a history backup file is from another network (mainnet or the test network).
  ///
  /// In en, this message translates to:
  /// **'Wrong network'**
  String get deskErrHistOtherChain;

  /// Title of the notice when a chosen file is not a history backup.
  ///
  /// In en, this message translates to:
  /// **'Not a history backup'**
  String get deskErrHistNotOurs;

  /// Title of the notice when a history backup file was made by a newer app version.
  ///
  /// In en, this message translates to:
  /// **'Newer file'**
  String get deskErrHistNewer;

  /// Title of the notice when a history backup file is incomplete or changed.
  ///
  /// In en, this message translates to:
  /// **'File damaged'**
  String get deskErrHistDamaged;

  /// Group heading in the import wizard's Find step: wallets made by the older Epic Wallet app.
  ///
  /// In en, this message translates to:
  /// **'Older Epic Wallet'**
  String get deskErrOldGui;

  /// Group heading in the import wizard's Find step: wallets made by the epic command-line program.
  ///
  /// In en, this message translates to:
  /// **'The epic program'**
  String get deskErrOldCli;

  /// Group heading in the import wizard's Find step: folders the user picked by hand.
  ///
  /// In en, this message translates to:
  /// **'Chosen folders'**
  String get deskErrOldPicked;

  /// Why a history backup was refused: the file is far larger than any backup.
  ///
  /// In en, this message translates to:
  /// **'The file is too large to be one.'**
  String get deskErrHistTooLarge;

  /// Why a history backup was refused: it is from another network. {from} and {to} are network names such as Mainnet.
  ///
  /// In en, this message translates to:
  /// **'The file is from {from}; this wallet is on {to}.'**
  String deskErrHistChains(String from, String to);

  /// Why a history backup was refused: it belongs to another wallet.
  ///
  /// In en, this message translates to:
  /// **'The file was exported from a wallet with a different recovery phrase.'**
  String get deskErrHistOtherWalletText;

  /// Why a history backup was refused: it was made by a newer app version.
  ///
  /// In en, this message translates to:
  /// **'A newer version of the app made this file. Update the app, then import it.'**
  String get deskErrHistNewerText;

  /// Why a history backup was refused: the file is damaged.
  ///
  /// In en, this message translates to:
  /// **'The file is incomplete or was changed.'**
  String get deskErrHistDamagedText;

  /// Why a history backup was refused: it is not a backup file of this app.
  ///
  /// In en, this message translates to:
  /// **'The file was not made by Epic Cash Desktop or Epic Cash Mobile.'**
  String get deskErrHistNotOursText;

  /// Hint under the Send address field when it is empty and the Direct method is chosen.
  ///
  /// In en, this message translates to:
  /// **'Enter the recipient’s address'**
  String get deskDataHttpEnter;

  /// Hint under the Send address field: an http address needs its scheme.
  ///
  /// In en, this message translates to:
  /// **'Start with https:// or http://'**
  String get deskDataHttpScheme;

  /// Hint under the Send address field: an .onion address was typed where an http(s) address is expected.
  ///
  /// In en, this message translates to:
  /// **'Onion addresses need Tor'**
  String get deskDataHttpOnion;

  /// Hint under the Send address field: the text is not an http or https address.
  ///
  /// In en, this message translates to:
  /// **'Not an http(s) address'**
  String get deskDataHttpNot;

  /// Hint under the Send address field: the port number is out of range.
  ///
  /// In en, this message translates to:
  /// **'Port must be 1 to 65535'**
  String get deskDataHttpPort;

  /// Update check failed: the server did not answer in time.
  ///
  /// In en, this message translates to:
  /// **'The update server did not answer.'**
  String get deskDataUpdTimeout;

  /// Update check failed: the server could not be reached.
  ///
  /// In en, this message translates to:
  /// **'The update server could not be reached.'**
  String get deskDataUpdUnreachable;

  /// Update check failed: the server answered with an HTTP error code.
  ///
  /// In en, this message translates to:
  /// **'The update server answered {status}.'**
  String deskDataUpdStatus(int status);

  /// Update check: the update list has no entry for the desktop app yet.
  ///
  /// In en, this message translates to:
  /// **'No desktop update information is published yet.'**
  String get deskDataUpdNone;

  /// Node status word: the node is at the chain tip. Short, in the status rail and node panels.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get deskNodeSynced;

  /// Node status word: the node is behind the network. Short.
  ///
  /// In en, this message translates to:
  /// **'Behind'**
  String get deskNodeBehind;

  /// Node status word: the node does not answer. Short.
  ///
  /// In en, this message translates to:
  /// **'Not answering'**
  String get deskNodeNotAnswering;

  /// Node status word while the first check is running. Short.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get deskNodeChecking;

  /// Local node status word: the node program is starting. Short.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get deskNodeStarting;

  /// Local node status word: the node is downloading the chain. Short.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get deskNodeSyncing;

  /// Local node status word: the sync made no progress. Short.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get deskNodeStalled;

  /// Local node status word: the node program failed. Short.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get deskNodeFailed;

  /// Local node status word: the node program is stopped. Short.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deskNodeStopped;

  /// Marker after the node host in the rail's second line when the node does not answer. Very short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'no answer'**
  String get deskNodeMarkerNoAnswer;

  /// Marker after the node host in the rail when the node is that many blocks behind. Very short. {count} is a number with thousands separators.
  ///
  /// In en, this message translates to:
  /// **'{count} behind'**
  String deskNodeMarkerBehind(String count);

  /// Marker after the host in the rail while the local node starts. Very short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'starting'**
  String get deskNodeMarkerStarting;

  /// Marker after the host in the rail when the local node's sync stalled. Very short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'stalled'**
  String get deskNodeMarkerStalled;

  /// Marker after the host in the rail when the local node failed. Very short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get deskNodeMarkerFailed;

  /// Marker after the host in the rail when the local node is stopped. Very short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get deskNodeMarkerStopped;

  /// Tooltip line for a node that stopped answering: the node's host and the time it went down.
  ///
  /// In en, this message translates to:
  /// **'{host} · since {time}'**
  String deskNodeHostSince(String host, String time);

  /// Tooltip line when the node does not answer.
  ///
  /// In en, this message translates to:
  /// **'The node is not answering.'**
  String get deskNodeNotAnsweringLine;

  /// Tooltip line part: the node's answer time in milliseconds.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String deskNodeLatency(String ms);

  /// Tooltip line part: the node's answer time in milliseconds, measured over Tor.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms over Tor'**
  String deskNodeLatencyOverTor(String ms);

  /// Tooltip line part: a newer node version is released.
  ///
  /// In en, this message translates to:
  /// **'{version} is out'**
  String deskNodeNewerOut(String version);

  /// Tooltip line when the node is behind the network.
  ///
  /// In en, this message translates to:
  /// **'Behind the network; catching up.'**
  String get deskNodeBehindLine;

  /// Tooltip line part: the node's block height of the network's height.
  ///
  /// In en, this message translates to:
  /// **'{height} of {total}'**
  String deskNodeHeightOf(String height, String total);

  /// Tooltip line part: the node is at the chain tip. Short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'at tip'**
  String get deskNodeAtTip;

  /// Name of the node program that runs on this computer, in the rail and node panels.
  ///
  /// In en, this message translates to:
  /// **'Local node'**
  String get deskNodeLocal;

  /// Local node line while it looks for peers.
  ///
  /// In en, this message translates to:
  /// **'Connecting to peers'**
  String get deskNodeConnectingPeers;

  /// Local node tooltip line: the wallet reads through this public node until the local node has synced.
  ///
  /// In en, this message translates to:
  /// **'Using {host} until it is synced.'**
  String deskNodeUsingUntilSynced(String host);

  /// Local node tooltip line while it syncs and no other node is used.
  ///
  /// In en, this message translates to:
  /// **'Nothing can be sent until it is synced.'**
  String get deskNodeNothingUntilSynced;

  /// Local node tooltip line part: how many peers the node is connected to.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} peer} other{{count} peers}}'**
  String deskNodePeers(int count);

  /// Local node tooltip line part: how long the node program has been running. {duration} is like "9 h 40 min".
  ///
  /// In en, this message translates to:
  /// **'running {duration}'**
  String deskNodeRunning(String duration);

  /// Local node tooltip line once synced while the wallet still reads through a public node.
  ///
  /// In en, this message translates to:
  /// **'Still using {host}; the local node takes over shortly.'**
  String deskNodeStillUsing(String host);

  /// Local node tooltip line when the sync stalled.
  ///
  /// In en, this message translates to:
  /// **'No progress for 5 min. Restarted once already.'**
  String get deskNodeNoProgress;

  /// Local node tooltip line: the wallet reads through this public node while the local node is not working.
  ///
  /// In en, this message translates to:
  /// **'Using {host} meanwhile.'**
  String deskNodeUsingMeanwhile(String host);

  /// Local node tooltip line when the node is stopped.
  ///
  /// In en, this message translates to:
  /// **'Start it under Settings › Node.'**
  String get deskNodeStartIt;

  /// Why the local node failed, as a detail after the word "Failed". Lowercase fragment.
  ///
  /// In en, this message translates to:
  /// **'port 3413 is used by another program'**
  String get deskNodeFailPort;

  /// Why the local node failed. Lowercase fragment.
  ///
  /// In en, this message translates to:
  /// **'not enough disk space'**
  String get deskNodeFailDisk;

  /// Why the local node failed. Lowercase fragment.
  ///
  /// In en, this message translates to:
  /// **'the node program is missing'**
  String get deskNodeFailMissing;

  /// Why the local node failed. Lowercase fragment.
  ///
  /// In en, this message translates to:
  /// **'the node program stopped'**
  String get deskNodeFailExited;

  /// Why the local node failed, with the program's exit code. Lowercase fragment.
  ///
  /// In en, this message translates to:
  /// **'the node program stopped (exit code {code})'**
  String deskNodeFailExitedCode(String code);

  /// Why the local node failed when nothing more is known. Lowercase fragment.
  ///
  /// In en, this message translates to:
  /// **'the node did not start'**
  String get deskNodeFailDefault;

  /// Name of the local node's sync stage, lowercase, used inside a sentence.
  ///
  /// In en, this message translates to:
  /// **'connecting to peers'**
  String get deskNodeStageWaiting;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'headers'**
  String get deskNodeStageHeaders;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'chain state download'**
  String get deskNodeStageChainDownload;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'checking kernels'**
  String get deskNodeStageKernels;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'checking range proofs'**
  String get deskNodeStageRangeProofs;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'processing the chain state'**
  String get deskNodeStageProcessing;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'blocks'**
  String get deskNodeStageBlocks;

  /// Name of the local node's sync stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'compacting'**
  String get deskNodeStageCompacting;

  /// Name of the local node's stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'stopping'**
  String get deskNodeStageStopping;

  /// Name of the local node's stage, lowercase.
  ///
  /// In en, this message translates to:
  /// **'syncing'**
  String get deskNodeStageSyncing;

  /// Local node stage line while it waits for peers.
  ///
  /// In en, this message translates to:
  /// **'Connecting to peers'**
  String get deskNodeLineWaiting;

  /// Local node stage line: block headers downloaded of the total.
  ///
  /// In en, this message translates to:
  /// **'Headers · {done} of {total}'**
  String deskNodeLineHeaders(String done, String total);

  /// Local node stage line: block headers, count unknown.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get deskNodeLineHeadersBare;

  /// Local node stage line: chain state downloaded of the total, in gigabytes.
  ///
  /// In en, this message translates to:
  /// **'Chain state · {done} of {total} GB'**
  String deskNodeLineChain(String done, String total);

  /// Local node stage line: chain state, size unknown.
  ///
  /// In en, this message translates to:
  /// **'Chain state'**
  String get deskNodeLineChainBare;

  /// Local node stage line: kernels checked of the total, in millions.
  ///
  /// In en, this message translates to:
  /// **'Checking kernels · {done} of {total} million'**
  String deskNodeLineKernels(String done, String total);

  /// Local node stage line: checking kernels.
  ///
  /// In en, this message translates to:
  /// **'Checking kernels'**
  String get deskNodeLineKernelsBare;

  /// Local node stage line: range proofs checked of the total, in millions.
  ///
  /// In en, this message translates to:
  /// **'Checking range proofs · {done} of {total} million'**
  String deskNodeLineRangeProofs(String done, String total);

  /// Local node stage line: checking range proofs.
  ///
  /// In en, this message translates to:
  /// **'Checking range proofs'**
  String get deskNodeLineRangeProofsBare;

  /// Local node stage line.
  ///
  /// In en, this message translates to:
  /// **'Processing the chain state'**
  String get deskNodeLineProcessing;

  /// Local node stage line: blocks downloaded of the total.
  ///
  /// In en, this message translates to:
  /// **'Blocks · {done} of {total}'**
  String deskNodeLineBlocks(String done, String total);

  /// Local node stage line: blocks, count unknown.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get deskNodeLineBlocksBare;

  /// Local node stage line.
  ///
  /// In en, this message translates to:
  /// **'Compacting the chain data'**
  String get deskNodeLineCompacting;

  /// Local node stage line while the node program shuts down.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get deskNodeLineStopping;

  /// Local node stage line when the stage is unknown.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get deskNodeLineSyncing;

  /// Time left for the local node's checks, which cannot be estimated. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'no estimate; up to an hour'**
  String get deskNodeNoEstimate;

  /// Time left for the local node's sync while the estimate is not ready yet. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'estimating…'**
  String get deskNodeEstimating;

  /// Time left for the local node's sync, in hours. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'about {hours} h left'**
  String deskNodeAboutHours(int hours);

  /// Time left for the local node's sync, in minutes. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min left'**
  String deskNodeAboutMinutes(int minutes);

  /// A length of time in hours and minutes, e.g. how long the node has been running.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String deskNodeDurationHm(int hours, int minutes);

  /// A length of time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String deskNodeDurationM(int minutes);

  /// Label of the Tor switch in Settings › Privacy and the status rail's Tor row.
  ///
  /// In en, this message translates to:
  /// **'Tor Network'**
  String get deskTorNetworkLabel;

  /// Explains what the Tor switch does, in the info hover card behind the Tor switch.
  ///
  /// In en, this message translates to:
  /// **'Network activity goes through the Tor network. Tor hides the wallet’s internet address: each connection passes through several volunteer-run relays, so no server learns where the wallet is.'**
  String get deskTorNetworkHint;

  /// Tor state word: the switch is off. Short.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskTorOff;

  /// Tor state word: Tor is connecting. Short.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get deskTorStarting;

  /// Tor state word: Tor is connected. Short.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get deskTorOn;

  /// Tor state word: Tor stopped or could not connect. Short.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get deskTorNotConnected;

  /// The connections that wait for Tor, as a phrase that starts a sentence: Epicbox, the node, the app's status/price/update/support requests and Tor addresses. It is followed by a verb in the sentences that use it ("… wait until Tor is up.").
  ///
  /// In en, this message translates to:
  /// **'Epicbox, the node, status, price, updates, support and Tor addresses'**
  String get deskTorRoutes;

  /// One sentence listing what goes over Tor while the switch is on.
  ///
  /// In en, this message translates to:
  /// **'Over Tor: Epicbox, the node, status, price, updates, support and Tor addresses.'**
  String get deskTorCoverage;

  /// Node tooltip line: the node is reached over Tor.
  ///
  /// In en, this message translates to:
  /// **'Over Tor'**
  String get deskTorNodeOver;

  /// Node tooltip line: a plain http node is not encrypted after the Tor exit.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted past Tor'**
  String get deskTorNodeNotEncrypted;

  /// Node tooltip line: the node connection waits for Tor.
  ///
  /// In en, this message translates to:
  /// **'Waits until Tor is connected.'**
  String get deskTorNodeWaits;

  /// Page title of Receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get deskRecvTitle;

  /// Label before the method icons in the Receive page header, and before the on/off switch of each receiving method.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get deskRecvReceiving;

  /// Name of the file method (transaction files) when read out in a screen reader line such as "File off".
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskRecvNameFile;

  /// Toast title when turning a receiving method on failed; the reason follows as text. {method} is Epicbox, HTTP, Tor or File.
  ///
  /// In en, this message translates to:
  /// **'{method} not turned on'**
  String deskRecvTurnOnFailed(String method);

  /// Toast title when turning a receiving method off failed; the reason follows as text. {method} is Epicbox, HTTP, Tor or File.
  ///
  /// In en, this message translates to:
  /// **'{method} not turned off'**
  String deskRecvTurnOffFailed(String method);

  /// Heading above the HTTP or Tor panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Other ways to receive'**
  String get deskRecvOtherWays;

  /// Small button next to the Other ways to receive heading: opens Settings › Receiving.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get deskRecvSettings;

  /// Title of the notice on Receive when Tor failed.
  ///
  /// In en, this message translates to:
  /// **'Tor is not connected.'**
  String get deskRecvTorNotConnected;

  /// Title of the notice on Receive while Tor connects.
  ///
  /// In en, this message translates to:
  /// **'Tor is starting.'**
  String get deskRecvTorStarting;

  /// Text of the notice on Receive when Tor failed. {routes} is a list of the connections that wait for Tor, such as "Epicbox, the node, status, price, updates, support and Tor addresses". "it" is Tor.
  ///
  /// In en, this message translates to:
  /// **'Nothing arrives over {routes} until it is, or until Tor is turned off.'**
  String deskRecvTorDownText(String routes);

  /// Text of the notice on Receive while Tor connects. "it" is Tor.
  ///
  /// In en, this message translates to:
  /// **'Addresses become reachable once it is connected. Nothing goes over the clearnet meanwhile.'**
  String get deskRecvTorStartingText;

  /// Button in the Tor failed notice on Receive: switches Tor off.
  ///
  /// In en, this message translates to:
  /// **'Turn Tor off'**
  String get deskRecvTurnTorOff;

  /// Retry button on the HTTP panel on Receive when the HTTP listener failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deskRecvTryAgain;

  /// Spoken state of a receiving method for screen readers, lowercase: the method is on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get deskRecvStateOn;

  /// Spoken state of a receiving method for screen readers, lowercase: the method is off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get deskRecvStateOff;

  /// Spoken state of a receiving method for screen readers, lowercase: still being checked.
  ///
  /// In en, this message translates to:
  /// **'checking'**
  String get deskRecvStateChecking;

  /// Screen reader text for one receiving method in the page header summary, e.g. "Epicbox on". The summary joins these with commas.
  ///
  /// In en, this message translates to:
  /// **'{method} {state}'**
  String deskRecvSemList(String method, String state);

  /// Screen reader label of a receiving method's icon button in the page header, e.g. "Epicbox: on".
  ///
  /// In en, this message translates to:
  /// **'{method}: {state}'**
  String deskRecvSemMethod(String method, String state);

  /// Tooltip of a receiving method's icon in the page header while it is being checked.
  ///
  /// In en, this message translates to:
  /// **'{method} · Checking'**
  String deskRecvTipChecking(String method);

  /// Tooltip of a receiving method's icon in the page header. {state} is the state word such as On or Off.
  ///
  /// In en, this message translates to:
  /// **'{method} · {state}'**
  String deskRecvTip(String method, String state);

  /// Tooltip of a receiving method's icon in the page header with a second line of detail.
  ///
  /// In en, this message translates to:
  /// **'{method} · {state}\n{detail}'**
  String deskRecvTipDetail(String method, String state, String detail);

  /// Small tag on the covered Epicbox QR code while Epicbox receiving is off.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get deskRecvTagPaused;

  /// Small tag on a QR code while its receiving method starts.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get deskRecvTagStarting;

  /// Small tag on a QR code when its receiving method does not work.
  ///
  /// In en, this message translates to:
  /// **'Not reachable'**
  String get deskRecvTagNotReachable;

  /// Shown instead of an address when the wallet could not read it.
  ///
  /// In en, this message translates to:
  /// **'The address could not be read. Open Receive again in a moment.'**
  String get deskRecvAddressUnreadable;

  /// Title of the Epicbox panel and of its QR code on Receive.
  ///
  /// In en, this message translates to:
  /// **'Epicbox address'**
  String get deskRecvEpicboxAddress;

  /// Screen reader and tooltip label of the copy button next to the Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'Copy Epicbox address'**
  String get deskRecvCopyEpicbox;

  /// Intro text of the Epicbox panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Share it to get paid. Works while the wallet is closed: the Epicbox server holds payments until the wallet is back.'**
  String get deskRecvEpicboxIntro;

  /// Caption under the Epicbox address on Receive.
  ///
  /// In en, this message translates to:
  /// **'When reading it out, check the first six and last six characters.'**
  String get deskRecvCheckSix;

  /// Title of the HTTP panel on Receive and of its QR code.
  ///
  /// In en, this message translates to:
  /// **'HTTP address'**
  String get deskRecvHttpAddress;

  /// Label of the copy button next to the HTTP address.
  ///
  /// In en, this message translates to:
  /// **'Copy HTTP address'**
  String get deskRecvCopyHttp;

  /// Caption under the HTTP address when receiving from the internet is on. {port} is the port number.
  ///
  /// In en, this message translates to:
  /// **'Your router’s public address. Senders on the internet use it once the router forwards port {port}.'**
  String deskRecvHttpPublic(int port);

  /// Caption under the HTTP address when receiving is only for this computer.
  ///
  /// In en, this message translates to:
  /// **'Programs on this computer can pay this address. For other devices, see Settings › Receiving.'**
  String get deskRecvHttpLocal;

  /// Intro text of the HTTP panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Straight from another wallet while this one is open. On this computer only unless Settings says otherwise.'**
  String get deskRecvHttpIntro;

  /// Caption at the bottom of the HTTP panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Turn on Tor in Settings › Privacy for a Tor address instead.'**
  String get deskRecvHttpTorHint;

  /// Title of the Tor panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Direct, Tor address'**
  String get deskRecvDirectTor;

  /// Intro text of the Tor panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Straight from another wallet over Tor while this one is open. Tor is set in Settings › Privacy.'**
  String get deskRecvTorIntro;

  /// Title of the QR code of the Tor address on Receive.
  ///
  /// In en, this message translates to:
  /// **'Tor address'**
  String get deskRecvTorAddress;

  /// Label of the copy button next to the Tor address.
  ///
  /// In en, this message translates to:
  /// **'Copy Tor address'**
  String get deskRecvCopyTor;

  /// Caption under the Tor address on Receive.
  ///
  /// In en, this message translates to:
  /// **'Some wallets show the address without .onion; both are the same address.'**
  String get deskRecvTorOnion;

  /// Heading of the transaction files panel on Receive.
  ///
  /// In en, this message translates to:
  /// **'Transaction files'**
  String get deskRecvFiles;

  /// Row title in the transaction files panel: opens the page that signs a file the sender gave.
  ///
  /// In en, this message translates to:
  /// **'Sign a transaction file'**
  String get deskRecvSignTitle;

  /// Row text under Sign a transaction file.
  ///
  /// In en, this message translates to:
  /// **'A sender gave a transaction file. The wallet signs it and saves a response for them.'**
  String get deskRecvSignText;

  /// Button on the rows of the transaction files panel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get deskRecvOpen;

  /// Row title in the transaction files panel: opens the page that finalizes a response file.
  ///
  /// In en, this message translates to:
  /// **'Finalize a response file'**
  String get deskRecvFinalizeTitle;

  /// Row text under Finalize a response file.
  ///
  /// In en, this message translates to:
  /// **'A file send got a response back. Finalizing posts the payment.'**
  String get deskRecvFinalizeText;

  /// Screen reader label of a receiving method's on/off switch. {title} is the panel's title, e.g. Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'{title}, receiving'**
  String deskRecvSwitchLabel(String title);

  /// Name of the output-selection strategy that spends the fewest small outputs. Used as a radio title and inside sentences. Short.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get deskSendStrategySmallest;

  /// Name of the output-selection strategy that spends every output. Used as a radio title and inside sentences. Short.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deskSendStrategyAll;

  /// Summary line on Send: the balance left after this payment.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get deskSendBalanceAfter;

  /// Summary line on Send: the amount still spendable while the change confirms.
  ///
  /// In en, this message translates to:
  /// **'Spendable until change confirms'**
  String get deskSendSpendableUntil;

  /// Summary line on Send when the change comes back as several outputs. {outputs} is the number of change outputs; {fee} the extra network fee, in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{outputs, plural, one{Change split into {outputs} output (+{fee} EPIC fee)} other{Change split into {outputs} outputs (+{fee} EPIC fee)}}'**
  String deskSendSplitLine(int outputs, String fee);

  /// Help text behind the info icon of the split-change line. {outputs} is the number of change outputs; {each} the size of each, in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{outputs, plural, one{So the next send does not wait for this one to confirm. Change comes back as {outputs} output of about {each} EPIC instead of one.} other{So the next send does not wait for this one to confirm. Change comes back as {outputs} outputs of about {each} EPIC instead of one.}}'**
  String deskSendSplitWhy(int outputs, String each);

  /// Screen reader label of the info icon next to the split-change line.
  ///
  /// In en, this message translates to:
  /// **'Why the change is split'**
  String get deskSendSplitWhyLabel;

  /// Caption under "Spendable until change confirms" on Send when the payment spends its outputs exactly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{No change: 1 output spent exactly, nothing waits.} other{No change: {count} outputs spent exactly, nothing waits.}}'**
  String deskSendLockNoChange(int count);

  /// Caption under "Spendable until change confirms" on Send when every output is locked until the change confirms. {amount} is in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Everything is locked: 1 output, {amount} EPIC, about 3 blocks.} other{Everything is locked: {count} outputs, {amount} EPIC, about 3 blocks.}}'**
  String deskSendLockAll(int count, String amount);

  /// Caption under "Spendable until change confirms" on Send: how much is locked until the change confirms. {amount} is in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 output locked, {amount} EPIC, about 3 blocks.} other{{count} outputs locked, {amount} EPIC, about 3 blocks.}}'**
  String deskSendLockSome(int count, String amount);

  /// Caption on Send when this send uses another output strategy than the default. {strategy} is the strategy's name (Smallest or All).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Strategy for this send: {strategy} · 1 output.} other{Strategy for this send: {strategy} · {count} outputs.}}'**
  String deskSendStrategyLine(int count, String strategy);

  /// Second line of the Network fee in the review dialog when the change is split. {fee} is the extra fee in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{outputs, plural, one{Change split into {outputs} output (+{fee} EPIC).} other{Change split into {outputs} outputs (+{fee} EPIC).}}'**
  String deskSendReviewSplit(int outputs, String fee);

  /// Review dialog, fact "Locks": the outputs are spent exactly. {locked} is in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{locked} EPIC in 1 output; no change comes back.} other{{locked} EPIC in {count} outputs; no change comes back.}}'**
  String deskSendReviewLocksNone(int count, String locked);

  /// Review dialog, fact "Locks": strategy All locks everything. {locked} is in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Everything: {locked} EPIC in 1 output until the change confirms (3 blocks). Nothing stays spendable.} other{Everything: {locked} EPIC in {count} outputs until the change confirms (3 blocks). Nothing stays spendable.}}'**
  String deskSendReviewLocksAll(int count, String locked);

  /// Review dialog, fact "Locks": all outputs are needed. {locked} is in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{locked} EPIC in 1 output until the change confirms (3 blocks). Nothing else is spendable meanwhile.} other{{locked} EPIC in {count} outputs until the change confirms (3 blocks). Nothing else is spendable meanwhile.}}'**
  String deskSendReviewLocksEverything(int count, String locked);

  /// Review dialog, fact "Locks": some outputs are locked, the rest stays spendable. Amounts are in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{locked} EPIC in 1 output until the change confirms (3 blocks). {spendable} EPIC stays spendable.} other{{locked} EPIC in {count} outputs until the change confirms (3 blocks). {spendable} EPIC stays spendable.}}'**
  String deskSendReviewLocksSome(int count, String locked, String spendable);

  /// Label of a fact in the review dialog: the outputs the payment locks until the change confirms. Short.
  ///
  /// In en, this message translates to:
  /// **'Locks'**
  String get deskSendFactLocks;

  /// Label of a fact in the review dialog: the output strategy of this send. Short.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get deskSendFactStrategy;

  /// Value of the Strategy fact in the review dialog. {strategy} is the strategy's name (Smallest or All).
  ///
  /// In en, this message translates to:
  /// **'{strategy} outputs, for this send'**
  String deskSendFactStrategyValue(String strategy);

  /// Subtitle of the Advanced disclosure on Send: strategy Smallest, change split. Starts with a middle dot.
  ///
  /// In en, this message translates to:
  /// **'· Smallest outputs'**
  String get deskSendAdvSmallest;

  /// Subtitle of the Advanced disclosure on Send: strategy Smallest, change not split. Starts with a middle dot.
  ///
  /// In en, this message translates to:
  /// **'· Smallest outputs, change not split'**
  String get deskSendAdvSmallestNoSplit;

  /// Subtitle of the Advanced disclosure on Send: strategy All, change split. Starts with a middle dot.
  ///
  /// In en, this message translates to:
  /// **'· All outputs'**
  String get deskSendAdvAll;

  /// Subtitle of the Advanced disclosure on Send: strategy All, change not split. Starts with a middle dot.
  ///
  /// In en, this message translates to:
  /// **'· All outputs, change not split'**
  String get deskSendAdvAllNoSplit;

  /// Title of the collapsed Advanced disclosure on Send.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get deskSendAdvanced;

  /// Screen reader label of the group of strategy radio rows on Send.
  ///
  /// In en, this message translates to:
  /// **'Strategy for this send'**
  String get deskSendAdvStrategy;

  /// Description of the Smallest strategy radio row on Send.
  ///
  /// In en, this message translates to:
  /// **'Spends the fewest small outputs; the rest of the balance stays spendable while the change confirms.'**
  String get deskSendAdvSmallestText;

  /// Description of the All strategy radio row on Send.
  ///
  /// In en, this message translates to:
  /// **'Spends every spendable output and returns one change output. Everything is locked until it confirms; fewer, larger outputs afterwards.'**
  String get deskSendAdvAllText;

  /// Small tag on the radio row of the strategy that is the default. Lowercase, very short.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get deskSendDefaultTag;

  /// Note under the strategy rows when the whole balance is sent.
  ///
  /// In en, this message translates to:
  /// **'Sending everything spends every output.'**
  String get deskSendAdvAllNote;

  /// Title of the switch (and its screen reader label) that splits the change into several outputs, on Send › Advanced.
  ///
  /// In en, this message translates to:
  /// **'Split change'**
  String get deskSendAdvSplit;

  /// Description of the Split change switch on Send › Advanced.
  ///
  /// In en, this message translates to:
  /// **'Returns the change as several outputs when few would be left, so the next send does not wait.'**
  String get deskSendAdvSplitText;

  /// Caption under Send › Advanced, followed by a link named "Outputs". Ends with a space.
  ///
  /// In en, this message translates to:
  /// **'For this send only. Defaults: '**
  String get deskSendAdvDefaults;

  /// Link at the end of the Advanced caption: opens the Outputs page, where the defaults are set.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get deskSendAdvOutputsLink;

  /// Empty state title of the Choose contact dialog on Send.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get deskSendPickNone;

  /// Empty state text of the Choose contact dialog on Send.
  ///
  /// In en, this message translates to:
  /// **'Save the people you pay in Contacts, then choose them here.'**
  String get deskSendPickNoneText;

  /// Button (empty state and dialog footer) that opens the Contacts page.
  ///
  /// In en, this message translates to:
  /// **'Open contacts'**
  String get deskSendPickOpen;

  /// Shown in the Choose contact dialog when the search finds nothing. {query} is what the user typed.
  ///
  /// In en, this message translates to:
  /// **'No contact matches \"{query}\".'**
  String deskSendPickNoMatch(String query);

  /// Title of the dialog that picks a contact as the recipient on Send.
  ///
  /// In en, this message translates to:
  /// **'Choose contact'**
  String get deskSendPickTitle;

  /// Subtitle of the Choose contact dialog.
  ///
  /// In en, this message translates to:
  /// **'The address fills the recipient field.'**
  String get deskSendPickDesc;

  /// Placeholder and screen reader label of the search field in the Choose contact dialog.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get deskSendPickSearch;

  /// Page title of Send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deskSendTitle;

  /// Error under the To field on Send when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Add an address to send to.'**
  String get deskSendErrNoAddress;

  /// Error under the To field on Send when the Epicbox method is chosen and the address is not an Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid Epicbox address.'**
  String get deskSendErrEpicbox;

  /// Error under the To field on Send when the Direct method is chosen and the address is an Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'This is not a Direct address.'**
  String get deskSendErrNotDirect;

  /// Error under the To field on Send when the address looks like a Tor address but is not complete or valid.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid onion address.'**
  String get deskSendErrOnion;

  /// Error under the To field on Send when the recipient is this wallet.
  ///
  /// In en, this message translates to:
  /// **'This is the wallet\'s own address.'**
  String get deskSendErrOwn;

  /// Demo failure text on Send (used by the guided tour).
  ///
  /// In en, this message translates to:
  /// **'The recipient did not answer. Nothing was sent.'**
  String get deskSendNoAnswer;

  /// Toast title on Send when switching Tor on failed; the reason follows as text.
  ///
  /// In en, this message translates to:
  /// **'Tor not turned on'**
  String get deskSendTorOnFailed;

  /// Toast title on Send when switching Tor off failed; the reason follows as text.
  ///
  /// In en, this message translates to:
  /// **'Tor not turned off'**
  String get deskSendTorOffFailed;

  /// Toast title on Send when switching Epicbox receiving on failed; the reason follows as text.
  ///
  /// In en, this message translates to:
  /// **'Epicbox not turned on'**
  String get deskSendEpicboxOnFailed;

  /// Error under the Amount field on Send when the All button finds nothing to send.
  ///
  /// In en, this message translates to:
  /// **'Nothing spendable to send.'**
  String get deskSendNothingSpendable;

  /// Error under the Amount field on Send when the All button could not get the maximum.
  ///
  /// In en, this message translates to:
  /// **'Could not work out how much can be sent. Try again in a moment.'**
  String get deskSendAllFailed;

  /// Error under the Amount field on Send when it is empty or not a number.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get deskSendErrAmountEnter;

  /// Error under the Amount field on Send when the amount has more than eight decimals.
  ///
  /// In en, this message translates to:
  /// **'EPIC has at most 8 decimals.'**
  String get deskSendErrAmountDecimals;

  /// Error under the Amount field on Send when the amount is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'The amount must be more than 0.'**
  String get deskSendErrAmountZero;

  /// Error under the Amount field on Send when the amount plus the fee is more than the spendable balance.
  ///
  /// In en, this message translates to:
  /// **'More than the available balance.'**
  String get deskSendErrAmountMore;

  /// Toast title and notice title after a send went out.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get deskSendSent;

  /// Result card title on Send after a file send created the transaction file.
  ///
  /// In en, this message translates to:
  /// **'Transaction file ready'**
  String get deskSendFileReadyTitle;

  /// Result card text on Send after a file send created the transaction file.
  ///
  /// In en, this message translates to:
  /// **'Give this file to the recipient. The wallet is waiting for the response file; finalize it when it comes back.'**
  String get deskSendFileReadyText;

  /// Button on the file-ready card on Send: opens the Finalize page.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get deskSendFinalize;

  /// Button on the file-ready card on Send: starts over.
  ///
  /// In en, this message translates to:
  /// **'New send'**
  String get deskSendNewSend;

  /// Title of the warning notice on Send while the node has not synced.
  ///
  /// In en, this message translates to:
  /// **'Node not synced'**
  String get deskSendNodeNotSynced;

  /// Text of that notice with the sync progress. {percent} is a whole number from 0 to 100.
  ///
  /// In en, this message translates to:
  /// **'Sending is possible once the node has synced. {percent}% done; the form can be filled in meanwhile.'**
  String deskSendNodeSyncingPct(int percent);

  /// Text of that notice when the progress is unknown.
  ///
  /// In en, this message translates to:
  /// **'Sending is possible once the node has synced.'**
  String get deskSendNodeSyncing;

  /// Title of the notice on Send when Tor failed and a send needs it.
  ///
  /// In en, this message translates to:
  /// **'Tor is not connected'**
  String get deskSendTorBlocked;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent until it is, or until Tor is turned off.'**
  String get deskSendTorBlockedText;

  /// Button in the Tor failed notice on Send: switches Tor off.
  ///
  /// In en, this message translates to:
  /// **'Turn Tor off'**
  String get deskSendTurnTorOff;

  /// Title of the notice on Send while Tor connects.
  ///
  /// In en, this message translates to:
  /// **'Tor is starting'**
  String get deskSendTorStarting;

  /// Text of the notice on Send while Tor connects.
  ///
  /// In en, this message translates to:
  /// **'Sending waits until it is connected. Nothing goes over the clearnet meanwhile.'**
  String get deskSendTorStartingText;

  /// Title of the warning notice on Send when Epicbox receiving is off.
  ///
  /// In en, this message translates to:
  /// **'Epicbox not connected'**
  String get deskSendEpicboxOff;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'Epicbox sends work once Epicbox receiving is on. Send by file meanwhile.'**
  String get deskSendEpicboxOffText;

  /// Button in that notice.
  ///
  /// In en, this message translates to:
  /// **'Turn on Epicbox receiving'**
  String get deskSendEpicboxTurnOn;

  /// Text of the Sent notice after a Direct send.
  ///
  /// In en, this message translates to:
  /// **'Finalized and posted to the network.'**
  String get deskSendDoneViaDirect;

  /// Text of the Sent notice after an Epicbox send.
  ///
  /// In en, this message translates to:
  /// **'Handed to Epicbox. Completes when the recipient answers.'**
  String get deskSendDoneViaEpicbox;

  /// Button in the Sent notice: opens the payment in Activity.
  ///
  /// In en, this message translates to:
  /// **'View transaction'**
  String get deskSendViewTx;

  /// Title of the error notice on Send after a send failed; the reason is the text.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get deskSendFailedTitle;

  /// Button in the Send failed notice: opens the review again.
  ///
  /// In en, this message translates to:
  /// **'Review again'**
  String get deskSendReviewAgain;

  /// Name of the Direct send method (an http(s) or onion address), in the method selector and in tags. Short.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get deskSendMethodDirect;

  /// Name of the File send method (a transaction file), in the method selector. Short.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskSendMethodFile;

  /// Label of the recipient field on Send.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get deskSendTo;

  /// Help text under the recipient field on Send.
  ///
  /// In en, this message translates to:
  /// **'Paste an address, or type a contact’s name.'**
  String get deskSendToHelp;

  /// Placeholder of the recipient field on Send.
  ///
  /// In en, this message translates to:
  /// **'Address or contact'**
  String get deskSendToHint;

  /// Screen reader label of the recipient field on Send.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get deskSendToSem;

  /// Screen reader label of the clear button in the recipient field.
  ///
  /// In en, this message translates to:
  /// **'Clear recipient'**
  String get deskSendClearTo;

  /// Small button in the recipient field on Send: opens the contact picker.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get deskSendContacts;

  /// Title of the warning under the recipient field when an onion address is entered and Tor is off.
  ///
  /// In en, this message translates to:
  /// **'Needs Tor'**
  String get deskSendNeedsTor;

  /// Text of that warning.
  ///
  /// In en, this message translates to:
  /// **'An onion address can only be reached over Tor.'**
  String get deskSendNeedsTorText;

  /// Text of that warning when this app build has no Tor.
  ///
  /// In en, this message translates to:
  /// **'Tor is not in this build.'**
  String get deskSendNoTorBuild;

  /// Button in that warning: switches Tor on.
  ///
  /// In en, this message translates to:
  /// **'Turn on Tor'**
  String get deskSendTurnOnTor;

  /// Note under the recipient field when Tor is on and the address is http(s).
  ///
  /// In en, this message translates to:
  /// **'Direct to http(s) addresses goes over the clearnet, not Tor.'**
  String get deskSendHttpClearnet;

  /// Button on the card of the contact picked as recipient: clears the recipient.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get deskSendClear;

  /// Label of the amount field on Send and of the summary line.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get deskSendAmount;

  /// Label next to the amount field while the balance is unknown.
  ///
  /// In en, this message translates to:
  /// **'Available —'**
  String get deskSendAvailableNone;

  /// Link next to the amount field: the spendable balance; clicking it sends everything. {amount} is a number or hidden dots.
  ///
  /// In en, this message translates to:
  /// **'Available {amount} EPIC'**
  String deskSendAvailable(String amount);

  /// Screen reader label of the amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount in EPIC'**
  String get deskSendAmountSem;

  /// Small button in the amount field: send the whole spendable balance. Very short.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deskSendAllButton;

  /// Note under the amount field when amounts are hidden and some balance is still confirming.
  ///
  /// In en, this message translates to:
  /// **'Part of the balance is still confirming and cannot be sent yet.'**
  String get deskSendConfirmingHidden;

  /// Note under the amount field when some balance is still confirming. {amount} is in EPIC.
  ///
  /// In en, this message translates to:
  /// **'{amount} EPIC is still confirming and cannot be sent yet.'**
  String deskSendConfirming(String amount);

  /// Label and screen reader label of the message field on Send.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get deskSendMessage;

  /// Help text under the message field.
  ///
  /// In en, this message translates to:
  /// **'The recipient sees this message.'**
  String get deskSendMessageHelp;

  /// Title of the collapsed privacy disclosure on Send when Dandelion++ is on. Dandelion++ is a protocol name.
  ///
  /// In en, this message translates to:
  /// **'Privacy · Dandelion++ on'**
  String get deskSendPrivacyOn;

  /// Title of the collapsed privacy disclosure on Send when Dandelion++ is off.
  ///
  /// In en, this message translates to:
  /// **'Privacy · Dandelion++ off'**
  String get deskSendPrivacyOff;

  /// Description of the Dandelion++ switch on Send.
  ///
  /// In en, this message translates to:
  /// **'Passes the transaction through a few random nodes before it spreads, so the network cannot tell where it came from.'**
  String get deskSendDandelionText;

  /// Line under the Review send button after a send went out.
  ///
  /// In en, this message translates to:
  /// **'Sent. Enter a new amount and recipient to send again.'**
  String get deskSendHintSent;

  /// Line under the Review send button while the node syncs.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the node to sync.'**
  String get deskSendHintNode;

  /// Line under the Review send button while Epicbox connects.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Epicbox to connect.'**
  String get deskSendHintEpicbox;

  /// Line under the Review send button while Tor connects.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Tor to connect.'**
  String get deskSendHintTorWait;

  /// Line under the Review send button when Tor failed.
  ///
  /// In en, this message translates to:
  /// **'Retry Tor, or turn it off.'**
  String get deskSendHintTorBlocked;

  /// Line under the Review send button when an onion address needs Tor.
  ///
  /// In en, this message translates to:
  /// **'Turn on Tor to send to an onion address.'**
  String get deskSendHintNeedsTor;

  /// Line under the Review send button when the form has errors.
  ///
  /// In en, this message translates to:
  /// **'Fix the fields marked in red.'**
  String get deskSendHintFix;

  /// Line under the Review send button while the fee is estimated.
  ///
  /// In en, this message translates to:
  /// **'Checking the fee for this amount.'**
  String get deskSendHintChecking;

  /// Line under the Review send button when the form is ready.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent until confirmed.'**
  String get deskSendHintDefault;

  /// Label of the disabled primary button on Send while Tor connects.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Tor'**
  String get deskSendReviewWaitTor;

  /// Label of the disabled primary button on Send when Tor failed.
  ///
  /// In en, this message translates to:
  /// **'Tor not connected'**
  String get deskSendReviewTorOff;

  /// Label of the primary button on Send: opens the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Review send'**
  String get deskSendReview;

  /// Title of the summary panel on Send.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get deskSendSummary;

  /// Label of the fee line in the Send summary and in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get deskSendNetworkFee;

  /// Label of the total line in the Send summary and in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deskSendTotal;

  /// Caption in the Send summary while the wallet rechecks the balance.
  ///
  /// In en, this message translates to:
  /// **'Balance updating while the wallet scans.'**
  String get deskSendUpdating;

  /// Bold first line under the method selector on Send for the Epicbox method.
  ///
  /// In en, this message translates to:
  /// **'The recipient can be offline.'**
  String get deskSendEpicboxLine1;

  /// Second line under the method selector for the Epicbox method.
  ///
  /// In en, this message translates to:
  /// **'The Epicbox server holds the payment until they open their wallet.'**
  String get deskSendEpicboxLine2;

  /// Bold first line under the method selector for the Direct method.
  ///
  /// In en, this message translates to:
  /// **'Straight to their wallet.'**
  String get deskSendDirectLine1;

  /// Second line under the method selector for the Direct method.
  ///
  /// In en, this message translates to:
  /// **'An http(s) or .onion address; an onion goes over Tor. Their wallet must be open.'**
  String get deskSendDirectLine2;

  /// Bold first line under the method selector for the File method.
  ///
  /// In en, this message translates to:
  /// **'No connection needed.'**
  String get deskSendFileLine1;

  /// Second line under the method selector for the File method.
  ///
  /// In en, this message translates to:
  /// **'Hand the file over, get their response file back, then finalize it here.'**
  String get deskSendFileLine2;

  /// Small tag next to the To label after the method switched to Direct by itself. Short.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get deskSendTagDirect;

  /// Small tag next to the To label after the method switched to File. Short.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskSendTagFile;

  /// Small tag next to the To label after the method switched to Epicbox. Short.
  ///
  /// In en, this message translates to:
  /// **'Via Epicbox'**
  String get deskSendTagEpicbox;

  /// Screen reader announcement when the method switched to Direct by itself.
  ///
  /// In en, this message translates to:
  /// **'Direct address. Method set to Direct.'**
  String get deskSendSwitchedDirect;

  /// Screen reader announcement when the method switched to File.
  ///
  /// In en, this message translates to:
  /// **'File address. Method set to File.'**
  String get deskSendSwitchedFile;

  /// Screen reader announcement when the method switched to Epicbox by itself.
  ///
  /// In en, this message translates to:
  /// **'Epicbox address. Method set to Epicbox.'**
  String get deskSendSwitchedEpicbox;

  /// Screen reader label of the list of contacts that match the recipient text.
  ///
  /// In en, this message translates to:
  /// **'Matching contacts'**
  String get deskSendMatching;

  /// Caption under the list of contacts that match the recipient text.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 contact matches} other{{count} contacts match}}'**
  String deskSendMatchCount(int count);

  /// Error under the password field in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get deskSendWrongPassword;

  /// Failure text when a send ended with an unknown error; the payment may exist.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed. Check Activity before sending again.'**
  String get deskSendNotConfirmed;

  /// Value of the Via fact in the review dialog for an Epicbox send.
  ///
  /// In en, this message translates to:
  /// **'Epicbox (the recipient can be offline)'**
  String get deskSendViaEpicbox;

  /// Value of the Via fact in the review dialog for a Direct send over http(s).
  ///
  /// In en, this message translates to:
  /// **'Direct (their wallet must be open)'**
  String get deskSendViaDirect;

  /// Value of the Via fact in the review dialog for a Direct send to an onion address.
  ///
  /// In en, this message translates to:
  /// **'Direct, over Tor (their wallet must be open)'**
  String get deskSendViaTor;

  /// Value of the Via fact in the review dialog for a file send.
  ///
  /// In en, this message translates to:
  /// **'Transaction file'**
  String get deskSendViaFile;

  /// Second line of the Network fee in the review dialog when strategy All spends every output and one change output comes back.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Uses its 1 output · change 1 output} other{Uses all {count} outputs · change 1 output}}'**
  String deskSendUsesAll(int count);

  /// Title of the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Check and send'**
  String get deskSendReviewTitle;

  /// Subtitle of the review dialog.
  ///
  /// In en, this message translates to:
  /// **'A send cannot be undone once it is posted.'**
  String get deskSendReviewDesc;

  /// Label of the recipient fact in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get deskSendFactTo;

  /// Caption under the recipient address in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted characters against what the recipient gave.'**
  String get deskSendCheckChars;

  /// Label of the fact that says how the payment goes (Epicbox, Direct, file) in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Via'**
  String get deskSendFactVia;

  /// Label of the privacy fact in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get deskSendFactPrivacy;

  /// Value of the Privacy fact in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Dandelion++ on'**
  String get deskSendDandelionOn;

  /// Value of the Privacy fact in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Dandelion++ off'**
  String get deskSendDandelionOff;

  /// Label of the message fact in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get deskSendFactMessage;

  /// Label of the password field in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deskSendPassword;

  /// Help text under the password field in the review dialog.
  ///
  /// In en, this message translates to:
  /// **'Every send asks the wallet’s password.'**
  String get deskSendPasswordHelp;

  /// Status in the review dialog while a file send creates the transaction file.
  ///
  /// In en, this message translates to:
  /// **'Creating the file.'**
  String get deskSendBusyFile;

  /// Status in the review dialog while a send to an onion address runs.
  ///
  /// In en, this message translates to:
  /// **'Reaching their wallet over Tor… This can take a while. Keep the app open.'**
  String get deskSendBusyTor;

  /// Status in the review dialog while a send runs.
  ///
  /// In en, this message translates to:
  /// **'Sending. This can take a few seconds; keep this window open.'**
  String get deskSendBusy;

  /// Button in the review dialog: close it and edit the form.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deskSendBack;

  /// Label of the primary button in the review dialog while the send runs.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get deskSendSending;

  /// Label of the primary button in the review dialog. {amount} is the amount.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} EPIC'**
  String deskSendConfirm(String amount);

  /// Title of the dialog shown before a send to a plain http address.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted. Send anyway?'**
  String get deskSendPlainTitle;

  /// Text of that dialog.
  ///
  /// In en, this message translates to:
  /// **'Plain HTTP to another computer. Anyone on the way can read the transaction. https:// is encrypted.'**
  String get deskSendPlainDesc;

  /// Button in that dialog: send over plain http.
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get deskSendPlainConfirm;

  /// Toast after the user switched the Epicbox server from the "server not answering" notice. {domain} is the new server's host name.
  ///
  /// In en, this message translates to:
  /// **'Switched to {domain}'**
  String deskSendEpicboxSwitched(String domain);

  /// Toast title when switching the Epicbox server failed; the reason follows as the toast text.
  ///
  /// In en, this message translates to:
  /// **'Not switched'**
  String get deskSendEpicboxNotSwitched;

  /// Title of the warning notice on Send and Receive when the Epicbox server does not answer.
  ///
  /// In en, this message translates to:
  /// **'Epicbox server not answering'**
  String get deskSendEpicboxDownTitle;

  /// Text of that notice when no other server is available.
  ///
  /// In en, this message translates to:
  /// **'Payments wait until it is back.'**
  String get deskSendEpicboxDownWait;

  /// Text of that notice when another server is healthy. {domain} is its host name.
  ///
  /// In en, this message translates to:
  /// **'Switch to {domain}?'**
  String deskSendEpicboxSwitchTo(String domain);

  /// Button in that notice: switch to the other server. Short.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get deskSendEpicboxSwitch;

  /// Button next to a file name: open the folder that holds the file in the system's file manager.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get deskFinOpenFolder;

  /// Toast title when the file manager could not be opened; the folder path follows as text.
  ///
  /// In en, this message translates to:
  /// **'Folder not opened'**
  String get deskFinFolderNotOpened;

  /// Title of the error notice on the Finalize page: the chosen file is not a response file.
  ///
  /// In en, this message translates to:
  /// **'Not a response file'**
  String get deskFinWrongType;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The file is not a response file. Choose the file the recipient sent back.'**
  String get deskFinWrongTypeText;

  /// Title of the error notice on the Finalize page: the chosen file could not be read.
  ///
  /// In en, this message translates to:
  /// **'File not readable'**
  String get deskFinUnreadable;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read. It may be damaged or still being copied.'**
  String get deskFinUnreadableText;

  /// Title of the error notice on the Finalize page: the wallet could not finalize the file.
  ///
  /// In en, this message translates to:
  /// **'Finalizing failed'**
  String get deskFinFailed;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The wallet could not finalize this file. It may belong to another transaction or be finalized already.'**
  String get deskFinFailedText;

  /// Title of the error notice on the Finalize page: the node did not accept the finalized transaction.
  ///
  /// In en, this message translates to:
  /// **'Not posted'**
  String get deskFinNotPosted;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The transaction was finalized but the node did not accept it. Check the node, then try again.'**
  String get deskFinNotPostedText;

  /// Title of the system file dialog that picks the recipient's response file.
  ///
  /// In en, this message translates to:
  /// **'Response file'**
  String get deskFinPickTitle;

  /// Toast and result title after the response file was finalized and posted.
  ///
  /// In en, this message translates to:
  /// **'Transaction posted'**
  String get deskFinPosted;

  /// Page title of Finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize a response file'**
  String get deskFinTitle;

  /// Title of the info notice at the top of the Finalize page.
  ///
  /// In en, this message translates to:
  /// **'For a transaction created as a file'**
  String get deskFinNoticeTitle;

  /// Text of the info notice at the top of the Finalize page.
  ///
  /// In en, this message translates to:
  /// **'Use the response file the recipient sent back.'**
  String get deskFinNoticeText;

  /// Button in the "Not posted" notice on Finalize: choose the file again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deskFinTryAgain;

  /// Text of the result card after finalizing.
  ///
  /// In en, this message translates to:
  /// **'The payment was finalized and sent to the network. Follow it in Activity.'**
  String get deskFinPostedText;

  /// Button on the result card after finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalize another file'**
  String get deskFinAnother;

  /// Button on the result cards of Finalize and Sign a transaction file: opens the payment in Activity.
  ///
  /// In en, this message translates to:
  /// **'View in Activity'**
  String get deskFinViewActivity;

  /// Shown next to a spinner while the wallet finalizes and posts the transaction.
  ///
  /// In en, this message translates to:
  /// **'Finalizing and posting'**
  String get deskFinBusy;

  /// Title of the drop zone on Finalize.
  ///
  /// In en, this message translates to:
  /// **'Choose a response file'**
  String get deskFinChoose;

  /// Text of the drop zone on Finalize.
  ///
  /// In en, this message translates to:
  /// **'The wallet completes the transaction and posts it to the network.'**
  String get deskFinChooseText;

  /// Button in the drop zones of Finalize and Sign a transaction file: opens the system file dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get deskFinChooseFile;

  /// Title of the error notice on the Sign a transaction file page: the chosen file is not a transaction file.
  ///
  /// In en, this message translates to:
  /// **'Not a transaction file'**
  String get deskImpWrongType;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The file is not a transaction file. Choose the .slate or .tx file the sender gave.'**
  String get deskImpWrongTypeText;

  /// Title of the error notice on the Sign a transaction file page: the file could not be read.
  ///
  /// In en, this message translates to:
  /// **'File not readable'**
  String get deskImpUnreadable;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read. It may be damaged or still being copied.'**
  String get deskImpUnreadableText;

  /// Title of the error notice: no place was chosen to save the response file.
  ///
  /// In en, this message translates to:
  /// **'Nothing signed'**
  String get deskImpNoPlace;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'No place was chosen for the response file, so nothing was signed.'**
  String get deskImpNoPlaceText;

  /// Title of the error notice: the wallet could not sign the file.
  ///
  /// In en, this message translates to:
  /// **'Signing failed'**
  String get deskImpFailed;

  /// Text of that notice.
  ///
  /// In en, this message translates to:
  /// **'The wallet could not sign this file. It may be for another wallet or already used.'**
  String get deskImpFailedText;

  /// Text of that notice when the wallet gave its own reason. {detail} is that reason, a short sentence without its final full stop.
  ///
  /// In en, this message translates to:
  /// **'The wallet could not sign this file. It may be for another wallet or already used. {detail}.'**
  String deskImpFailedDetail(String detail);

  /// Title of the system file dialog that picks the sender's transaction file.
  ///
  /// In en, this message translates to:
  /// **'Transaction file'**
  String get deskImpPickTitle;

  /// Page title of Sign a transaction file.
  ///
  /// In en, this message translates to:
  /// **'Sign a transaction file'**
  String get deskImpTitle;

  /// Title of the info notice at the top of the Sign a transaction file page.
  ///
  /// In en, this message translates to:
  /// **'Signing does not spend anything'**
  String get deskImpNoticeTitle;

  /// Text of the info notice at the top of the page.
  ///
  /// In en, this message translates to:
  /// **'Send the response file back to the sender over the same channel they used.'**
  String get deskImpNoticeText;

  /// Title of the result card after the response file was saved.
  ///
  /// In en, this message translates to:
  /// **'Response saved'**
  String get deskImpSaved;

  /// Text of the result card after signing.
  ///
  /// In en, this message translates to:
  /// **'Send the response file back to the sender. The EPIC arrives once the sender finalizes it.'**
  String get deskImpSavedText;

  /// Label before the amount on the result card. Ends with a space.
  ///
  /// In en, this message translates to:
  /// **'Amount '**
  String get deskImpAmount;

  /// Button on the result card after signing.
  ///
  /// In en, this message translates to:
  /// **'Sign another file'**
  String get deskImpAnother;

  /// Shown next to a spinner while the wallet signs the file.
  ///
  /// In en, this message translates to:
  /// **'Signing the file'**
  String get deskImpBusy;

  /// Title of the drop zone on Sign a transaction file.
  ///
  /// In en, this message translates to:
  /// **'Choose a transaction file'**
  String get deskImpChoose;

  /// Text of the drop zone.
  ///
  /// In en, this message translates to:
  /// **'The wallet signs it and saves a response for the sender.'**
  String get deskImpChooseText;

  /// Title of the toast on Activity when the refresh could not ask the node; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get deskActNotUpdated;

  /// Placeholder of the search field on Activity. Narrow field.
  ///
  /// In en, this message translates to:
  /// **'Address or slate id'**
  String get deskActSearchHint;

  /// Placeholder of the search field on Activity when there are no transactions yet. Narrow field.
  ///
  /// In en, this message translates to:
  /// **'Nothing to search yet'**
  String get deskActSearchHintEmpty;

  /// Screen reader label of the search field on Activity.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get deskActSearchLabel;

  /// Tooltip of the button that empties the search field; also the button of the 'no match' state.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get deskActClearSearch;

  /// Tooltip of the icon button on Activity that shows the hidden amounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get deskActShowAmounts;

  /// Tooltip of the icon button on Activity that hides amounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get deskActHideAmounts;

  /// Tooltip of the icon button on Activity that asks the node for new transactions.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get deskActRefresh;

  /// Title of the Activity page: the list of all transactions.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get deskActTitle;

  /// Title of the transaction detail for an incoming payment, in the pane beside the list or on its own page.
  ///
  /// In en, this message translates to:
  /// **'Received transaction'**
  String get deskActDetailReceived;

  /// Title of the transaction detail for an outgoing payment, in the pane beside the list or on its own page.
  ///
  /// In en, this message translates to:
  /// **'Sent transaction'**
  String get deskActDetailSent;

  /// Line with a spinner on Activity while the transactions are being read.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions'**
  String get deskActLoading;

  /// Line with a spinner on Activity while the node has not finished syncing, so there is no list yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the node to be synced.'**
  String get deskActWaitingNode;

  /// Filter tab on Activity: every transaction. Narrow tab; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deskActFilterAll;

  /// Filter tab on Activity: incoming payments. Narrow tab; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get deskActFilterReceived;

  /// Filter tab on Activity: outgoing payments. Narrow tab; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get deskActFilterSent;

  /// Title of the empty state on Activity when the search and filter show nothing.
  ///
  /// In en, this message translates to:
  /// **'No transactions match'**
  String get deskActNoMatchTitle;

  /// Text of the empty state on Activity when the search and filter show nothing.
  ///
  /// In en, this message translates to:
  /// **'Try another address or slate id, or clear the filter.'**
  String get deskActNoMatchText;

  /// Pager caption under the Activity list: the current page of all pages.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String deskActPageOf(int page, int pages);

  /// Tooltip of the pager's previous button.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get deskActPrevPage;

  /// Tooltip of the pager's next button.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get deskActNextPage;

  /// Screen reader label of the pager group.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get deskActPages;

  /// Column header of the Activity table: who the other side is. Narrow header.
  ///
  /// In en, this message translates to:
  /// **'From / to'**
  String get deskActColFromTo;

  /// Column header of the Activity table. Narrow header.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deskActColStatus;

  /// Column header of the Activity table: the clock time. Narrow header, right aligned.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get deskActColTime;

  /// Column header of the Activity table. Narrow header, right aligned.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get deskActColAmount;

  /// Title of the empty state on Activity when the wallet has no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get deskActEmptyTitle;

  /// Text of the empty state on Activity when the wallet has no transactions.
  ///
  /// In en, this message translates to:
  /// **'Every payment sent or received is listed here, newest first, with who it was with and how far along it is.'**
  String get deskActEmptyText;

  /// Title of the first of three stages a payment goes through, in the empty state of Activity.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get deskActStageWaiting;

  /// Text of the first stage in the empty state of Activity.
  ///
  /// In en, this message translates to:
  /// **'Both wallets sign it. Over Epicbox this is automatic.'**
  String get deskActStageWaitingText;

  /// Title of the second stage in the empty state of Activity.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskActStageConfirming;

  /// Text of the second stage in the empty state of Activity.
  ///
  /// In en, this message translates to:
  /// **'On the chain. About one block a minute.'**
  String get deskActStageConfirmingText;

  /// Title of the third stage in the empty state of Activity.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get deskActStageSpendable;

  /// Text of the third stage in the empty state of Activity: the number of confirmations before the money can be spent; the minutes equal the confirmations (one block a minute).
  ///
  /// In en, this message translates to:
  /// **'{needed, plural, one{After {needed} confirmation, about {needed} minute.} other{After {needed} confirmations, about {needed} minutes.}}'**
  String deskActStageSpendableText(int needed);

  /// Primary button in the empty state of Activity: opens the Receive page.
  ///
  /// In en, this message translates to:
  /// **'Show address'**
  String get deskActShowAddress;

  /// Ghost button in the empty state of Activity: opens the page to import a payment file.
  ///
  /// In en, this message translates to:
  /// **'Receive a file'**
  String get deskActReceiveFile;

  /// Title of the Contacts page: saved people and shops with their addresses.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get deskConTitle;

  /// Line with a spinner on Contacts while the list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading contacts'**
  String get deskConLoading;

  /// Title of the form for a new contact (page title on a narrow window, panel title and form heading).
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get deskConNewTitle;

  /// Title of the form for editing a contact (page title on a narrow window, panel title and form heading).
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get deskConEditTitle;

  /// Title of the panel beside the contact list when a contact is shown.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get deskConDetailsTitle;

  /// Placeholder of the search field above the contact list.
  ///
  /// In en, this message translates to:
  /// **'Name or address'**
  String get deskConSearchHint;

  /// Screen reader label of the search field above the contact list.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get deskConSearchLabel;

  /// Tooltip of the button that empties the contact search; also the button of the 'no contacts match' state.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get deskConClearSearch;

  /// Number of saved contacts, above a long contact list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} contact} other{{count} contacts}}'**
  String deskConCount(int count);

  /// Count line above the contact list when the search finds nobody.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get deskConNoMatches;

  /// Count line above the contact list while searching.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} match} other{{count} matches}}'**
  String deskConMatches(int count);

  /// Option of the sort switch above the contact list: sort by name. Narrow segment.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deskConSortName;

  /// Option of the sort switch above the contact list: most recently used first. Narrow segment.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get deskConSortRecent;

  /// Line in the contact list when there are no contacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet.'**
  String get deskConNone;

  /// Line in the contact list when the search finds nobody.
  ///
  /// In en, this message translates to:
  /// **'No contacts match'**
  String get deskConNoMatchList;

  /// Button on Contacts that opens the form for a new contact. Short.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get deskConAdd;

  /// Text in the empty detail panel beside the contact list.
  ///
  /// In en, this message translates to:
  /// **'Choose a contact to see their details, send to them, edit or delete them.'**
  String get deskConIdle;

  /// Title of the empty state of Contacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get deskConEmptyTitle;

  /// Text of the empty state of Contacts.
  ///
  /// In en, this message translates to:
  /// **'Save the people and shops paid often. On Send, pick a name instead of pasting an address.'**
  String get deskConEmptyText;

  /// Small text of the empty state of Contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts stay on this computer. They are not part of the recovery phrase.'**
  String get deskConEmptyLocal;

  /// Ghost button in the empty state of Contacts: opens Send without a contact.
  ///
  /// In en, this message translates to:
  /// **'Send to address'**
  String get deskConSendToAddress;

  /// Small line under a contact's name. The placeholder is a time such as 'today', '3 days ago' or '12 Oct'.
  ///
  /// In en, this message translates to:
  /// **'Last transaction: {when}'**
  String deskConLastTx(String when);

  /// Primary button in a contact's detail: send to this contact. Short.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deskConSend;

  /// Button in a contact's detail: edit it. Short.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deskConEdit;

  /// Button in a contact's detail: mark as favourite. Short.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get deskConStar;

  /// Button in a contact's detail: remove the favourite mark. Short.
  ///
  /// In en, this message translates to:
  /// **'Unstar'**
  String get deskConUnstar;

  /// Danger button in a contact's detail: delete it. Short.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deskConDelete;

  /// Title of the toast when a contact could not be deleted; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not deleted'**
  String get deskConNotDeleted;

  /// Toast after a contact was deleted.
  ///
  /// In en, this message translates to:
  /// **'{name} was deleted'**
  String deskConDeleted(String name);

  /// Label above the address in a contact's detail, for an Epicbox address.
  ///
  /// In en, this message translates to:
  /// **'Epicbox address'**
  String get deskConAddrEpicbox;

  /// Label above the address in a contact's detail, for a Tor address.
  ///
  /// In en, this message translates to:
  /// **'Tor address'**
  String get deskConAddrTor;

  /// Label above the address in a contact's detail, for an HTTP address.
  ///
  /// In en, this message translates to:
  /// **'HTTP address'**
  String get deskConAddrHttp;

  /// Label above the note in a contact's detail; also the label of the note field in the form.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get deskConNote;

  /// Heading above the list of payments with this contact.
  ///
  /// In en, this message translates to:
  /// **'Transactions with {name}'**
  String deskConTxWith(String name);

  /// Link next to the heading: opens Activity.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get deskConAllTx;

  /// Text under the heading when there are no payments with this contact.
  ///
  /// In en, this message translates to:
  /// **'No transactions with this contact yet. Payments sent to them from Send appear here.'**
  String get deskConTxNone;

  /// Title of a compact row in a contact's payments: an incoming payment. One word.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get deskConTxReceived;

  /// Title of a compact row in a contact's payments: an outgoing payment. One word.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get deskConTxSent;

  /// Error under the Name field of the contact form when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Give the contact a name.'**
  String get deskConErrName;

  /// Error under the Address field of the contact form when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Add an address.'**
  String get deskConErrAddressEmpty;

  /// Error under the Address field of the contact form when the text is not an address.
  ///
  /// In en, this message translates to:
  /// **'Not a recognised address'**
  String get deskConErrAddressInvalid;

  /// Small button in the contact form: add a picture. Only shown when contact pictures exist.
  ///
  /// In en, this message translates to:
  /// **'Add picture'**
  String get deskConAddPicture;

  /// Small button in the contact form: change the picture.
  ///
  /// In en, this message translates to:
  /// **'Change picture'**
  String get deskConChangePicture;

  /// Small button in the contact form: remove the picture.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deskConRemovePicture;

  /// Small text under the picture buttons in the contact form.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPEG, WebP or GIF, up to 10 MB. A small copy is kept in this app.'**
  String get deskConPictureHelp;

  /// Label of the Name field in the contact form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deskConFieldName;

  /// Label of the Address field in the contact form.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get deskConFieldAddress;

  /// Title of the red notice in the contact form when saving failed; the reason follows.
  ///
  /// In en, this message translates to:
  /// **'Contact not saved'**
  String get deskConSaveFailed;

  /// Primary button of the contact form. Short.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get deskConSave;

  /// Title of the dialog that asks before deleting a contact.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deskConDeleteTitle(String name);

  /// Body of the dialog that asks before deleting a contact.
  ///
  /// In en, this message translates to:
  /// **'The contact’s address and note are removed from this wallet. Past transactions stay in Activity. This cannot be undone.'**
  String get deskConDeleteBody;

  /// Button in the delete dialog: do not delete. Short.
  ///
  /// In en, this message translates to:
  /// **'Keep contact'**
  String get deskConKeep;

  /// Danger button in the delete dialog. Short.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deskConDeleteAction;

  /// Title of the toast on Outputs when the refresh could not ask the node; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get deskOutNotUpdated;

  /// Title of the Outputs page; also the screen reader label of the outputs table. Outputs are the coins the balance is made of.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get deskOutTitle;

  /// Tooltip of the icon button on Outputs that shows the hidden amounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get deskOutShowAmounts;

  /// Tooltip of the icon button on Outputs that hides amounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get deskOutHideAmounts;

  /// Tooltip of the icon button on Outputs that asks the node for new data; also the button when the list could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get deskOutRefresh;

  /// Small note under the balance tiles on Outputs, shown while some outputs are locked.
  ///
  /// In en, this message translates to:
  /// **'Locked outputs are being spent by a transaction in progress. Their change shows as awaiting finalization and is not in Total until the send is finalized, so Total counts the coins once.'**
  String get deskOutLockedNote;

  /// Intro paragraph on the Outputs page.
  ///
  /// In en, this message translates to:
  /// **'Outputs are the pieces the balance is made of. A send spends whole outputs, pays the recipient and returns the rest as a new output; the spent ones are locked until the send confirms.'**
  String get deskOutIntro;

  /// Number of outputs, small caption next to an amount in the balance tiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} output} other{{count} outputs}}'**
  String deskOutCount(int count);

  /// Note on the Split and Consolidate cards while a send is still locking outputs.
  ///
  /// In en, this message translates to:
  /// **'Wait until the send confirms (about 3 blocks).'**
  String get deskOutCardWait;

  /// Note on the Split card when there are no spendable outputs.
  ///
  /// In en, this message translates to:
  /// **'Nothing to split yet.'**
  String get deskOutSplitNothing;

  /// Note on the Split card: how many outputs a split would spend.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Spends {count} output.} other{Spends {count} outputs.}}'**
  String deskOutSplitSpends(int count);

  /// Note on the Split card: how many outputs a split would spend and the lowest fee.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Spends {count} output. Fee from {fee} EPIC.} other{Spends {count} outputs. Fee from {fee} EPIC.}}'**
  String deskOutSplitSpendsFee(int count, String fee);

  /// Note on the Consolidate card when there are no spendable outputs.
  ///
  /// In en, this message translates to:
  /// **'Nothing to consolidate yet.'**
  String get deskOutConsNothing;

  /// Note on the Consolidate card when there is only one spendable output.
  ///
  /// In en, this message translates to:
  /// **'Nothing to consolidate: one spendable output.'**
  String get deskOutConsOne;

  /// Note on the Consolidate card: how many outputs a consolidation merges into one.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} output into 1.} other{{count} outputs into 1.}}'**
  String deskOutConsInto(int count);

  /// Note on the Consolidate card: how many outputs a consolidation merges into one, and its fee.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} output into 1. Fee {fee} EPIC.} other{{count} outputs into 1. Fee {fee} EPIC.}}'**
  String deskOutConsIntoFee(int count, String fee);

  /// Title of the Split card on Outputs.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get deskOutSplitCardTitle;

  /// Text of the Split card on Outputs.
  ///
  /// In en, this message translates to:
  /// **'Makes more outputs from the spendable balance, so several sends can follow each other without waiting.'**
  String get deskOutSplitCardText;

  /// Button of the Split card; opens a dialog. Keep the ellipsis. Short.
  ///
  /// In en, this message translates to:
  /// **'Split…'**
  String get deskOutSplitCardButton;

  /// Title of the Consolidate card on Outputs.
  ///
  /// In en, this message translates to:
  /// **'Consolidate'**
  String get deskOutConsCardTitle;

  /// Text of the Consolidate card on Outputs.
  ///
  /// In en, this message translates to:
  /// **'Merges every spendable output into one. Smaller fees on the next send; everything is locked until it confirms.'**
  String get deskOutConsCardText;

  /// Button of the Consolidate card; opens a dialog. Keep the ellipsis. Short.
  ///
  /// In en, this message translates to:
  /// **'Consolidate…'**
  String get deskOutConsCardButton;

  /// Title of the empty state on Outputs when the list could not be read.
  ///
  /// In en, this message translates to:
  /// **'Outputs not loaded'**
  String get deskOutNotLoadedTitle;

  /// Text of the empty state on Outputs when the list could not be read.
  ///
  /// In en, this message translates to:
  /// **'Refresh to try again.'**
  String get deskOutNotLoadedText;

  /// Line with a spinner on Outputs while the list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading wallet data'**
  String get deskOutLoading;

  /// Title of the empty state on Outputs when the wallet has no outputs.
  ///
  /// In en, this message translates to:
  /// **'No outputs yet'**
  String get deskOutNoneTitle;

  /// Text of the empty state on Outputs when the wallet has no outputs.
  ///
  /// In en, this message translates to:
  /// **'The first payment received makes one. Split and Consolidate need something to work with.'**
  String get deskOutNoneText;

  /// Filter chip on Outputs: every output. Narrow chip; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deskOutFilterAll;

  /// Filter chip on Outputs: outputs that can be spent now. Narrow chip; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get deskOutFilterSpendable;

  /// Filter chip on Outputs: outputs waiting for confirmations. Narrow chip; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskOutFilterConfirming;

  /// Filter chip on Outputs: outputs locked by a send. Narrow chip; a count follows it.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get deskOutFilterLocked;

  /// Placeholder of the search field on Outputs. A commitment is the output's technical identifier.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get deskOutSearchHint;

  /// Screen reader label of the search field on Outputs.
  ///
  /// In en, this message translates to:
  /// **'Search outputs'**
  String get deskOutSearchLabel;

  /// Tooltip of the button that empties the search field on Outputs.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get deskOutClearSearch;

  /// Checkbox on Outputs: also list outputs that were already spent.
  ///
  /// In en, this message translates to:
  /// **'Show spent'**
  String get deskOutShowSpent;

  /// Title of the empty state on Outputs when the search and filter show nothing.
  ///
  /// In en, this message translates to:
  /// **'No outputs match'**
  String get deskOutNoMatchTitle;

  /// Text of the empty state on Outputs when the search and filter show nothing.
  ///
  /// In en, this message translates to:
  /// **'Try another commitment, or clear the filter.'**
  String get deskOutNoMatchText;

  /// Button of the 'no match' state on Outputs: empties the search and resets the filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get deskOutClearFilter;

  /// Label of a balance tile on Outputs: money that can be spent now. Narrow tile.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get deskOutTileSpendable;

  /// Label of a balance tile on Outputs: money waiting for confirmations. Narrow tile.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskOutTileConfirming;

  /// Label of a balance tile on Outputs: mining rewards not yet spendable. Narrow tile.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get deskOutTileImmature;

  /// Label of a balance tile on Outputs: money locked in unfinished sends. Narrow tile.
  ///
  /// In en, this message translates to:
  /// **'Locked in sends'**
  String get deskOutTileLocked;

  /// Label of a balance tile on Outputs: the whole balance. Narrow tile.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deskOutTileTotal;

  /// Title of the panel on Outputs with the settings Send uses.
  ///
  /// In en, this message translates to:
  /// **'Defaults for sends'**
  String get deskOutDefaultsTitle;

  /// Setting title in the Defaults panel: which outputs a send spends.
  ///
  /// In en, this message translates to:
  /// **'Strategy for sends'**
  String get deskOutStrategyTitle;

  /// Option of the strategy switch: spend the smallest outputs. Narrow segment.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get deskOutStrategySmallest;

  /// Option of the strategy switch: spend all outputs. Narrow segment.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deskOutStrategyAll;

  /// Title of the toast that shows the strategy help.
  ///
  /// In en, this message translates to:
  /// **'Smallest or All'**
  String get deskOutStrategyHelpTitle;

  /// Setting title in the Defaults panel (a switch); also its screen reader label.
  ///
  /// In en, this message translates to:
  /// **'Split change'**
  String get deskOutSplitChangeTitle;

  /// Setting description under 'Split change'.
  ///
  /// In en, this message translates to:
  /// **'When a send would leave fewer than 3 spendable outputs and its change is at least 1 EPIC, the change comes back as up to 4 outputs of at least 0.5 EPIC each. Costs 0.004 EPIC per extra output.'**
  String get deskOutSplitChangeText;

  /// Column header of the outputs table: the amount. Narrow header, right aligned.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get deskOutColValue;

  /// Column header of the outputs table. Narrow header.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deskOutColStatus;

  /// Column header of the outputs table: number of confirmations. Narrow header, right aligned.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get deskOutColConfirmations;

  /// Column header of the outputs table: block height. Narrow header.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get deskOutColHeight;

  /// Column header of the outputs table: the transaction the output belongs to. Narrow header.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get deskOutColTransaction;

  /// Column header of the outputs table: the output's technical identifier.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get deskOutColCommitment;

  /// Status of an output that can be spent. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get deskOutStatusSpendable;

  /// Status of an output waiting for confirmations. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskOutStatusConfirming;

  /// Small grey note after an output's status: how many confirmations it has. number is the count with thousands separators.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{number} confirmation} other{{number} confirmations}}'**
  String deskOutConfirmations(int count, String number);

  /// Status of an output of a payment still waiting to be finalized. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Awaiting finalization'**
  String get deskOutStatusAwaiting;

  /// Small grey note after the status 'Awaiting finalization'. Lower case.
  ///
  /// In en, this message translates to:
  /// **'waiting for the sender'**
  String get deskOutNoteWaitingSender;

  /// Status of an output made for an invoice that is not paid yet. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Unpaid invoice'**
  String get deskOutStatusUnpaid;

  /// Small grey note after the status 'Unpaid invoice'. Lower case.
  ///
  /// In en, this message translates to:
  /// **'not in the balance'**
  String get deskOutNoteNotInBalance;

  /// Status of a mining reward output that cannot be spent yet. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get deskOutStatusImmature;

  /// Small grey note after the status 'Immature': blocks until it can be spent. number is the count with thousands separators.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{number} block to go} other{{number} blocks to go}}'**
  String deskOutNoteBlocksToGo(int count, String number);

  /// Status of an output that is a mining reward. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Mining'**
  String get deskOutStatusMining;

  /// Status of an output locked by a send. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get deskOutStatusLocked;

  /// Small grey note after the status 'Locked': which send locked it.
  ///
  /// In en, this message translates to:
  /// **'by send #{id}'**
  String deskOutNoteBySend(int id);

  /// Status of an output that was spent. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get deskOutStatusSpent;

  /// Link in the outputs table to the transaction an output came from: incoming, with a short date.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String deskOutTxReceived(String date);

  /// Link in the outputs table to the transaction an output belongs to: outgoing, with a short date.
  ///
  /// In en, this message translates to:
  /// **'Sent {date}'**
  String deskOutTxSent(String date);

  /// Tooltip of the copy button next to a commitment; short is its shortened form.
  ///
  /// In en, this message translates to:
  /// **'Copy commitment {short}'**
  String deskOutCopyCommitment(String short);

  /// Bold part of the Split and Consolidate dialog text: how many outputs are spent and what they hold.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} output ({amount} EPIC)} other{{count} outputs ({amount} EPIC)}}'**
  String deskOutSplitSpentPart(int count, String amount);

  /// Bold part of the Split dialog text: how many outputs are made and the size of each.
  ///
  /// In en, this message translates to:
  /// **'{count} outputs of about {amount} EPIC'**
  String deskOutSplitMadePart(int count, String amount);

  /// Bold part of the Consolidate dialog text: the single output that is made.
  ///
  /// In en, this message translates to:
  /// **'one output of {amount} EPIC'**
  String deskOutConsMadePart(String amount);

  /// Paragraph in the Split dialog. The two placeholders are shown in bold; keep them as whole pieces.
  ///
  /// In en, this message translates to:
  /// **'Spends {spent} and makes {made} each. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then.'**
  String deskOutSplitDialogText(String spent, String made);

  /// Paragraph in the Consolidate dialog. The two placeholders are shown in bold; keep them as whole pieces.
  ///
  /// In en, this message translates to:
  /// **'Spends {spent} and makes {made}. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then. The next send spends one output, so its fee is the smallest.'**
  String deskOutConsDialogText(String spent, String made);

  /// Label in the dialog's facts list: the fee of the transaction.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get deskOutFactFee;

  /// Label in the Split dialog's facts list: the size of every new output.
  ///
  /// In en, this message translates to:
  /// **'Each output'**
  String get deskOutFactEach;

  /// Value in the Split dialog's facts list.
  ///
  /// In en, this message translates to:
  /// **'about {amount} EPIC'**
  String deskOutFactAbout(String amount);

  /// Label in the dialog's facts list: the amount locked while the transaction confirms.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get deskOutFactLocked;

  /// Value in the dialog's facts list: how much is locked and for how long.
  ///
  /// In en, this message translates to:
  /// **'{amount} EPIC, about 3 blocks. Nothing stays spendable.'**
  String deskOutFactLockedValue(String amount);

  /// Label of the number stepper in the Split dialog; also its screen reader label.
  ///
  /// In en, this message translates to:
  /// **'Outputs to make'**
  String get deskOutMakeLabel;

  /// Small text under 'Outputs to make': the allowed range.
  ///
  /// In en, this message translates to:
  /// **'2 to 10.'**
  String get deskOutMakeRange;

  /// Tooltip of the minus button of the number stepper.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get deskOutStepperFewer;

  /// Tooltip of the plus button of the number stepper.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get deskOutStepperMore;

  /// Line with a spinner in the dialog while the fee is estimated.
  ///
  /// In en, this message translates to:
  /// **'Working out the fee'**
  String get deskOutFeeWorking;

  /// Title of the red notice in the dialog when the fee could not be estimated; the reason follows.
  ///
  /// In en, this message translates to:
  /// **'No estimate'**
  String get deskOutNoEstimate;

  /// Warning in the Split dialog when the outputs would be too small.
  ///
  /// In en, this message translates to:
  /// **'Each output must be at least 0.5 EPIC.'**
  String get deskOutEachMin;

  /// Warning in the Consolidate dialog when the outputs do not cover the fee.
  ///
  /// In en, this message translates to:
  /// **'Not enough to pay the fee.'**
  String get deskOutNotEnoughFee;

  /// Primary button of the Split dialog: split into this many outputs.
  ///
  /// In en, this message translates to:
  /// **'Split into {count}'**
  String deskOutSplitInto(int count);

  /// Primary button of the Consolidate dialog.
  ///
  /// In en, this message translates to:
  /// **'Consolidate'**
  String get deskOutConsolidateButton;

  /// Line with a spinner in the Split dialog while the transaction is built and sent.
  ///
  /// In en, this message translates to:
  /// **'Building and posting the split. Keep the app open.'**
  String get deskOutPostingSplit;

  /// Line with a spinner in the Consolidate dialog while the transaction is built and sent.
  ///
  /// In en, this message translates to:
  /// **'Building and posting the consolidate. Keep the app open.'**
  String get deskOutPostingCons;

  /// Title of the green notice in the Split dialog when it worked.
  ///
  /// In en, this message translates to:
  /// **'Split posted'**
  String get deskOutSplitPosted;

  /// Title of the green notice in the Consolidate dialog when it worked.
  ///
  /// In en, this message translates to:
  /// **'Consolidate posted'**
  String get deskOutConsPosted;

  /// Text of the green notice in the Split dialog when it worked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{The wallet now has {count} output of about {amount} EPIC, confirming. Everything is locked until they confirm (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.} other{The wallet now has {count} outputs of about {amount} EPIC, confirming. Everything is locked until they confirm (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.}}'**
  String deskOutSplitDoneText(int count, String amount);

  /// Text of the green notice in the Consolidate dialog when it worked.
  ///
  /// In en, this message translates to:
  /// **'One output of {amount} EPIC, confirming. Everything is locked until it confirms (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.'**
  String deskOutConsDoneText(String amount);

  /// Title of the red notice when the node did not take the transaction.
  ///
  /// In en, this message translates to:
  /// **'Not posted.'**
  String get deskOutNotPostedTitle;

  /// Text of the red notice in the Split dialog when the node did not take the transaction.
  ///
  /// In en, this message translates to:
  /// **'The split was built and stored, but the node did not take it. Post it again, or cancel it to unlock the outputs.'**
  String get deskOutNotPostedSplit;

  /// Text of the red notice in the Consolidate dialog when the node did not take the transaction.
  ///
  /// In en, this message translates to:
  /// **'The consolidate was built and stored, but the node did not take it. Post it again, or cancel it to unlock the outputs.'**
  String get deskOutNotPostedCons;

  /// Button in the Split dialog: cancel the stored transaction. Short.
  ///
  /// In en, this message translates to:
  /// **'Cancel the split'**
  String get deskOutCancelSplit;

  /// Button in the Consolidate dialog: cancel the stored transaction. Short.
  ///
  /// In en, this message translates to:
  /// **'Cancel the consolidate'**
  String get deskOutCancelCons;

  /// Primary button: send the stored transaction to the node again. Short.
  ///
  /// In en, this message translates to:
  /// **'Post again'**
  String get deskOutPostAgain;

  /// Title of the red notice in the dialog when it failed.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get deskOutNotDoneTitle;

  /// Text of the red notice in the dialog when it failed; error is the reason (a sentence without final full stop).
  ///
  /// In en, this message translates to:
  /// **'{error}. The outputs are unchanged.'**
  String deskOutNotDoneText(String error);

  /// Reason shown when nothing more is known about why the split or consolidate failed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get deskOutSomethingWrong;

  /// Primary button of the failure state in the dialog. Short.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deskOutTryAgain;

  /// Title of the toast when posting again failed; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not posted'**
  String get deskOutToastNotPosted;

  /// Title of the toast when cancelling the stored transaction failed; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not cancelled'**
  String get deskOutToastNotCancelled;

  /// Title of the Split dialog.
  ///
  /// In en, this message translates to:
  /// **'Split outputs'**
  String get deskOutSplitDialogTitle;

  /// Title of the Consolidate dialog.
  ///
  /// In en, this message translates to:
  /// **'Consolidate outputs'**
  String get deskOutConsDialogTitle;

  /// Description in the dialog header while posting.
  ///
  /// In en, this message translates to:
  /// **'Posting.'**
  String get deskOutPostingDesc;

  /// Description in the dialog header when it worked.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get deskOutDoneDesc;

  /// Description in the Split dialog header.
  ///
  /// In en, this message translates to:
  /// **'More outputs, so several sends can follow each other.'**
  String get deskOutSplitDesc;

  /// Description in the Consolidate dialog header.
  ///
  /// In en, this message translates to:
  /// **'One output instead of many.'**
  String get deskOutConsDesc;

  /// Text of the dialog shown when there is nothing to consolidate (the wallet has one spendable output, or the core says fewer than two); the placeholder is shown in bold.
  ///
  /// In en, this message translates to:
  /// **'Nothing to consolidate: the wallet has {what}. Consolidate merges several outputs into one.'**
  String deskOutNothingText(String what);

  /// Bold part of the 'nothing to consolidate' text.
  ///
  /// In en, this message translates to:
  /// **'fewer than two spendable outputs'**
  String get deskOutWhatFewer;

  /// Bold part of the 'nothing to consolidate' text.
  ///
  /// In en, this message translates to:
  /// **'one spendable output'**
  String get deskOutWhatOne;

  /// Title of the toast on Overview when the refresh could not ask the node; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get deskOvNotUpdated;

  /// Title of the toast on Overview when the built-in node could not be started; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Node not started'**
  String get deskOvNodeNotStarted;

  /// Title of a notice on Overview: the saved node address was corrected.
  ///
  /// In en, this message translates to:
  /// **'Node address updated'**
  String get deskOvNodeAddrTitle;

  /// Text of the notice about the corrected node address. The addresses stay as written.
  ///
  /// In en, this message translates to:
  /// **'Now using node.epiccash.com instead of node.epiccash.com:3413.'**
  String get deskOvNodeAddrText;

  /// Title of a red notice on Overview: the node runs a version the wallet cannot use.
  ///
  /// In en, this message translates to:
  /// **'This node’s version is not compatible with this wallet'**
  String get deskOvNodeIncompatTitle;

  /// Text of the incompatible-node notice: the node's address.
  ///
  /// In en, this message translates to:
  /// **'Node: {url}'**
  String deskOvNodeUrl(String url);

  /// Button in the incompatible-node notice: switch to the public node. Short.
  ///
  /// In en, this message translates to:
  /// **'Use public node'**
  String get deskOvUsePublicNode;

  /// Button in the incompatible-node notice: switch to the node built into the app. Short.
  ///
  /// In en, this message translates to:
  /// **'Use local node'**
  String get deskOvUseLocalNode;

  /// Ghost button in the incompatible-node notice: dismiss it. Short.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get deskOvHide;

  /// Title of a red notice on Overview: the node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the node at {url}'**
  String deskOvCantReachNode(String url);

  /// Text of the notice that the node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Check that it is running and reachable. Balances may be out of date and sending is paused.'**
  String get deskOvCantReachNodeText;

  /// Label of the Start node button while the node is starting. One word.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get deskOvStarting;

  /// Button in the node-down notice: start the built-in node. Short.
  ///
  /// In en, this message translates to:
  /// **'Start node'**
  String get deskOvStartNode;

  /// Ghost button in the node-down notice: opens Settings for the node. Short.
  ///
  /// In en, this message translates to:
  /// **'Node settings'**
  String get deskOvNodeSettings;

  /// Title of the Overview page: balance and recent activity.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get deskOvTitle;

  /// Tooltip of the icon button on Overview that shows the hidden amounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get deskOvShowAmounts;

  /// Tooltip of the icon button on Overview that hides amounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get deskOvHideAmounts;

  /// Tooltip of the icon button on Overview that asks the node for new data.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get deskOvRefresh;

  /// Screen reader state of a start-up step that is finished. Lower case, follows the step's text.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get deskOvStepDone;

  /// Screen reader state of a start-up step that is running. Lower case, follows the step's text.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get deskOvStepNow;

  /// Screen reader state of a start-up step that has not started. Lower case, follows the step's text.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get deskOvStepWait;

  /// Screen reader label of a start-up step: its text and its state.
  ///
  /// In en, this message translates to:
  /// **'{text}, {state}'**
  String deskOvStepSemantics(String text, String state);

  /// Screen reader label of the group of start-up steps shown after unlocking.
  ///
  /// In en, this message translates to:
  /// **'Starting up'**
  String get deskOvStartingUp;

  /// Start-up step shown on Overview after unlocking.
  ///
  /// In en, this message translates to:
  /// **'Wallet unlocked'**
  String get deskOvStepUnlocked;

  /// Start-up step shown on Overview after unlocking.
  ///
  /// In en, this message translates to:
  /// **'Connected to node'**
  String get deskOvStepConnected;

  /// Start-up step shown on Overview after unlocking.
  ///
  /// In en, this message translates to:
  /// **'Updating balances'**
  String get deskOvStepUpdating;

  /// Start-up step shown on Overview after unlocking.
  ///
  /// In en, this message translates to:
  /// **'Starting Epicbox receiving'**
  String get deskOvStepEpicbox;

  /// Title of a notice on Overview while the node catches up with the network.
  ///
  /// In en, this message translates to:
  /// **'Node syncing: {percent}%'**
  String deskOvSyncTitle(int percent);

  /// Text of the node-syncing notice.
  ///
  /// In en, this message translates to:
  /// **'Downloading blocks. Balances are what the wallet knew at block {block}. Sending opens when the node has caught up.'**
  String deskOvSyncText(String block);

  /// Screen reader label of the sync progress bar.
  ///
  /// In en, this message translates to:
  /// **'Node sync progress'**
  String get deskOvSyncProgress;

  /// Caption under the sync progress bar.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the chain'**
  String deskOvSyncOfChain(int percent);

  /// Primary button on Overview of an empty wallet: opens Receive. Short.
  ///
  /// In en, this message translates to:
  /// **'Receive EPIC'**
  String get deskOvReceiveEpic;

  /// Primary button on Overview: opens Send. Short.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deskOvSend;

  /// Button on Overview: opens Receive. Short.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get deskOvReceive;

  /// Small text under the buttons on Overview while Send is disabled until the node is synced.
  ///
  /// In en, this message translates to:
  /// **'Sending opens when the node is synced.'**
  String get deskOvSendWaits;

  /// Label above the big balance amount on Overview.
  ///
  /// In en, this message translates to:
  /// **'Available to spend'**
  String get deskOvAvailable;

  /// Small tag next to the balance: the balance is as of this block height.
  ///
  /// In en, this message translates to:
  /// **'As of block {block}'**
  String deskOvAsOfBlock(String block);

  /// Text under the balance of an empty wallet.
  ///
  /// In en, this message translates to:
  /// **'Share the Epicbox address to receive the first EPIC.'**
  String get deskOvEmptyHint;

  /// Small grey text after the dollar value of the whole balance on Overview. Starts with two spaces.
  ///
  /// In en, this message translates to:
  /// **'  whole balance, CoinGecko'**
  String get deskOvFiatNote;

  /// Label of a balance cell under the big amount on Overview: the whole balance. Narrow cell, may wrap to two lines.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deskOvBreakTotal;

  /// Label of a balance cell on Overview: money still waiting for confirmations. Narrow cell.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskOvBreakConfirming;

  /// Label of a balance cell on Overview: mining rewards not yet spendable. Narrow cell.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get deskOvBreakImmature;

  /// Label of a balance cell on Overview: money of payments that wait to be finalized. Narrow cell, may wrap to two lines.
  ///
  /// In en, this message translates to:
  /// **'Awaiting finalization'**
  String get deskOvBreakAwaiting;

  /// Label of a balance cell on Overview: money locked in unfinished sends. Narrow cell, may wrap to two lines.
  ///
  /// In en, this message translates to:
  /// **'Locked in sends'**
  String get deskOvBreakLocked;

  /// Tag next to the balance label while the balance is being updated; also its screen reader label. One word.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get deskOvUpdating;

  /// Screen reader label of the balance when amounts are hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden amount'**
  String get deskOvHiddenAmount;

  /// Line with a spinner in the Recent activity panel while the transactions load.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions'**
  String get deskOvLoading;

  /// Title of the empty state of Recent activity.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get deskOvEmptyTitle;

  /// Text of the empty state of Recent activity; blocks is the number of confirmations needed.
  ///
  /// In en, this message translates to:
  /// **'{blocks, plural, one{Received EPIC shows here first as confirming, then as spendable after {blocks} block.} other{Received EPIC shows here first as confirming, then as spendable after {blocks} blocks.}}'**
  String deskOvEmptyText(int blocks);

  /// Primary button in the empty state of Recent activity: opens Receive.
  ///
  /// In en, this message translates to:
  /// **'Show address'**
  String get deskOvShowAddress;

  /// Ghost button in the empty state of Recent activity: opens the page to import a payment file.
  ///
  /// In en, this message translates to:
  /// **'Receive a file'**
  String get deskOvReceiveFile;

  /// Heading above the last transactions on Overview.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get deskOvRecent;

  /// Link next to the Recent activity heading: opens Activity; count is the number of transactions.
  ///
  /// In en, this message translates to:
  /// **'View all {count}'**
  String deskOvViewAll(int count);

  /// Title of a notice on Overview: file payments waiting for the recipient's response file.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} file send open} other{{count} file sends open}}'**
  String deskOvPendingFiles(int count);

  /// Text of the notice about open file sends.
  ///
  /// In en, this message translates to:
  /// **'Finalize with the response file from the recipient.'**
  String get deskOvPendingText;

  /// Ghost button in the open-file-sends notice: opens the Finalize page. Short.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get deskOvFinalize;

  /// Transaction method name for a payment made with a file (not Epicbox, HTTP or Tor). Table cell and detail value; one short word.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskTxMethodFile;

  /// Who the other side of a transaction is when it is a mining reward. Activity table name column; short.
  ///
  /// In en, this message translates to:
  /// **'Mining reward'**
  String get deskTxMiningReward;

  /// Name column of an Activity row for a payment restored from a history backup with no sender known (incoming); also the status word of a confirmed incoming payment and the semantics label. One word.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get deskTxReceived;

  /// Name column of an Activity row for a payment restored from a history backup with no recipient known (outgoing); also the status word of a confirmed outgoing payment. One word.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get deskTxSent;

  /// Name column of an Activity row for an incoming payment whose sender is not recorded.
  ///
  /// In en, this message translates to:
  /// **'Unknown sender'**
  String get deskTxUnknownSender;

  /// Name column of an Activity row for an outgoing payment whose recipient is not recorded.
  ///
  /// In en, this message translates to:
  /// **'Unknown recipient'**
  String get deskTxUnknownRecipient;

  /// Small note under the Date step of a payment found by a scan, when the date comes from the block.
  ///
  /// In en, this message translates to:
  /// **'Block time. The sender is not recorded.'**
  String get deskTxNoteBlock;

  /// Small note under the Date step of a payment found by a scan, when the block's time could not be read so the time of the scan is shown.
  ///
  /// In en, this message translates to:
  /// **'Time of the scan; the block\'s time could not be read. The sender is not recorded.'**
  String get deskTxNoteScanTime;

  /// Small note under the first step of a payment found by a scan when the scan type is not known.
  ///
  /// In en, this message translates to:
  /// **'The sender is not recorded.'**
  String get deskTxNoteUnknown;

  /// Name of a payment found while restoring the wallet. Activity table, narrow; one word.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get deskTxFoundRestoredLabel;

  /// Small line under the name of a payment found while restoring the wallet. Activity table, narrow.
  ///
  /// In en, this message translates to:
  /// **'Found while restoring'**
  String get deskTxFoundRestoredLine;

  /// First step on the transaction detail timeline for a payment found while restoring the wallet.
  ///
  /// In en, this message translates to:
  /// **'Found while restoring this wallet'**
  String get deskTxFoundRestoredStep;

  /// Tooltip on a payment found while restoring the wallet.
  ///
  /// In en, this message translates to:
  /// **'Found on the chain while restoring this wallet. The sender is not recorded.'**
  String get deskTxFoundRestoredTip;

  /// Name of a payment found by a scan (balance recheck or any scan). Activity table, narrow.
  ///
  /// In en, this message translates to:
  /// **'Found by scan'**
  String get deskTxFoundRescanLabel;

  /// Small line under the name of a payment found by a balance recheck. Activity table, narrow.
  ///
  /// In en, this message translates to:
  /// **'Found by a balance recheck'**
  String get deskTxFoundRescanLine;

  /// First step on the transaction detail timeline for a payment found by a balance recheck.
  ///
  /// In en, this message translates to:
  /// **'Found by a balance recheck'**
  String get deskTxFoundRescanStep;

  /// Tooltip on a payment found by a balance recheck.
  ///
  /// In en, this message translates to:
  /// **'Found on the chain by a balance recheck. The sender is not recorded.'**
  String get deskTxFoundRescanTip;

  /// Small line under the name of a payment found by a scan of unknown kind. Activity table, narrow.
  ///
  /// In en, this message translates to:
  /// **'Found by a scan'**
  String get deskTxFoundScanLine;

  /// First step on the transaction detail timeline for a payment found by a scan of unknown kind.
  ///
  /// In en, this message translates to:
  /// **'Found by a scan'**
  String get deskTxFoundScanStep;

  /// Tooltip on a payment found by a scan of unknown kind.
  ///
  /// In en, this message translates to:
  /// **'Found on the chain by a scan. The sender is not recorded.'**
  String get deskTxFoundScanTip;

  /// Tooltip on a payment that was added from a history backup file.
  ///
  /// In en, this message translates to:
  /// **'Added from a history backup.'**
  String get deskTxBackupTip;

  /// Status and small line of a payment that came from a history backup. Activity table, narrow.
  ///
  /// In en, this message translates to:
  /// **'From backup'**
  String get deskTxFromBackup;

  /// Status of a mining reward not yet spendable. Activity table status column, narrow; one word.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get deskTxStatusImmature;

  /// Status of an incoming payment that waits for the sender to finalize it. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender to finalize'**
  String get deskTxStatusWaitingSender;

  /// Status of an outgoing file payment that waits for the response file from the recipient. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the response file'**
  String get deskTxStatusWaitingResponseFile;

  /// Status of an outgoing payment that waits for the recipient to sign. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Waiting for recipient to sign'**
  String get deskTxStatusWaitingRecipient;

  /// Status of a payment that was sent to the network and waits to be put in a block. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a block'**
  String get deskTxStatusWaitingBlock;

  /// Status of a payment on the chain: how many confirmations it has of how many are needed. Narrow status column.
  ///
  /// In en, this message translates to:
  /// **'Confirming {confirmations}/{needed}'**
  String deskTxStatusConfirming(int confirmations, int needed);

  /// Status of a cancelled payment. Narrow status column; one word.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get deskTxStatusCancelled;

  /// Lower case, inside a sentence such as 'Last transaction: today'.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get deskTxToday;

  /// Lower case, inside a sentence such as 'Last transaction: yesterday'.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get deskTxYesterday;

  /// How long ago a payment was, from 2 to 6 days. Inside a sentence such as 'Last transaction: 3 days ago'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day ago} other{{count} days ago}}'**
  String deskTxDaysAgo(int count);

  /// Compact row time: today with the clock time.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String deskTxTodayAt(String time);

  /// Day separator above the Activity list for today. The date is a full weekday and date.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String deskTxDayToday(String date);

  /// Day separator above the Activity list for yesterday. The date is a full weekday and date.
  ///
  /// In en, this message translates to:
  /// **'Yesterday · {date}'**
  String deskTxDayYesterday(String date);

  /// Small line under the amount of an outgoing payment: the network fee. The amount is a number without the unit.
  ///
  /// In en, this message translates to:
  /// **'Fee {amount}'**
  String deskTxFee(String amount);

  /// Small line under a payment that has a payment proof.
  ///
  /// In en, this message translates to:
  /// **'Payment proof'**
  String get deskTxPaymentProof;

  /// Button in an Activity row of an outgoing file payment: finalize it with the response file. Short.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get deskTxFinalize;

  /// Screen reader label of an Activity row for a payment received.
  ///
  /// In en, this message translates to:
  /// **'Received {amount}, {who}, {status}'**
  String deskTxSemReceived(String amount, String who, String status);

  /// Screen reader label of an Activity row for a payment sent.
  ///
  /// In en, this message translates to:
  /// **'Sent {amount}, {who}, {status}'**
  String deskTxSemSent(String amount, String who, String status);

  /// Screen reader label of an Activity row for an invoice or request; kind is a word such as Unpaid.
  ///
  /// In en, this message translates to:
  /// **'{kind} {amount}, {who}, {status}'**
  String deskTxSemKind(String kind, String amount, String who, String status);

  /// Screen reader words for an amount hidden by the 'hide amounts' setting.
  ///
  /// In en, this message translates to:
  /// **'hidden amount'**
  String get deskTxHiddenAmount;

  /// Status line at the top of the transaction detail for a payment that came from a history backup.
  ///
  /// In en, this message translates to:
  /// **'From backup; the chain was not asked.'**
  String get deskTxNowBackup;

  /// Status line at the top of the transaction detail for a mining reward that is not yet spendable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Confirmed, but a mining reward is spendable only after {count} confirmation.} other{Confirmed, but a mining reward is spendable only after {count} confirmations.}}'**
  String deskTxNowImmature(int count);

  /// Status line on the transaction detail: an incoming payment this wallet signed and sent back.
  ///
  /// In en, this message translates to:
  /// **'Signed and returned. Waiting for the sender to finalize.'**
  String get deskTxNowWaitingSender;

  /// Status line on the transaction detail: an outgoing file payment waiting for the recipient's response file.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the response file. Finalize when it arrives.'**
  String get deskTxNowWaitingResponseFile;

  /// Status line on the transaction detail: an outgoing payment waiting for the recipient to sign.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the recipient to sign. Nothing leaves the wallet until it is finalized.'**
  String get deskTxNowWaitingRecipient;

  /// Status line on the transaction detail: a payment was sent to the network and is not in a block yet.
  ///
  /// In en, this message translates to:
  /// **'Posted to the network, waiting for a block.'**
  String get deskTxNowPosted;

  /// Status line on the transaction detail: how many confirmations a payment has of how many it needs.
  ///
  /// In en, this message translates to:
  /// **'{needed, plural, one{In a block, {confirmations} of {needed} confirmation.} other{In a block, {confirmations} of {needed} confirmations.}}'**
  String deskTxNowConfirming(int confirmations, int needed);

  /// Status line on the transaction detail for a confirmed payment.
  ///
  /// In en, this message translates to:
  /// **'{confirmations, plural, one{Confirmed, {confirmations} confirmation.} other{Confirmed, {confirmations} confirmations.}}'**
  String deskTxNowConfirmed(int confirmations);

  /// Status line on the transaction detail for a cancelled payment.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get deskTxNowCancelled;

  /// Title of the toast when cancelling a payment failed; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Not cancelled'**
  String get deskTxNotCancelled;

  /// Toast after a payment was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Transaction cancelled'**
  String get deskTxCancelled;

  /// Label of the Cancel button on the transaction detail while the cancel is running. One word.
  ///
  /// In en, this message translates to:
  /// **'Cancelling'**
  String get deskTxCancelling;

  /// Small line under the big amount on the transaction detail: the payment was found while restoring the wallet. Lower case.
  ///
  /// In en, this message translates to:
  /// **'restored'**
  String get deskTxHeadRestored;

  /// Small line under the big amount on the transaction detail: the payment was found by a scan. Lower case.
  ///
  /// In en, this message translates to:
  /// **'found on the chain'**
  String get deskTxHeadFoundOnChain;

  /// Small line under the big amount on the transaction detail: the payment came from a history backup. Lower case.
  ///
  /// In en, this message translates to:
  /// **'added from a history backup'**
  String get deskTxHeadBackup;

  /// Small line under the big amount on the transaction detail for an incoming payment. The name is shown in a different style; keep the placeholder as one piece. Lower case.
  ///
  /// In en, this message translates to:
  /// **'from {who}'**
  String deskTxHeadFrom(String who);

  /// Small line under the big amount on the transaction detail for an outgoing payment. The name is shown in a different style; keep the placeholder as one piece. Lower case.
  ///
  /// In en, this message translates to:
  /// **'to {who}'**
  String deskTxHeadTo(String who);

  /// Section heading on the transaction detail: the timeline of steps.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get deskTxSubProgress;

  /// Section heading on the transaction detail: the facts list.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get deskTxSubDetails;

  /// Label in the facts list on the transaction detail. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get deskTxFactDate;

  /// Label in the facts list on the transaction detail for an incoming payment's sender address. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get deskTxFactFrom;

  /// Label in the facts list on the transaction detail for an outgoing payment's recipient address. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get deskTxFactTo;

  /// Tooltip of the copy button next to the address on the transaction detail.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get deskTxCopyAddress;

  /// Label in the facts list on the transaction detail: how the payment travelled (Epicbox, HTTP, Tor, file). Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get deskTxFactMethod;

  /// Label in the facts list on the transaction detail. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get deskTxFactAmount;

  /// Label in the facts list on the transaction detail: the network fee. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get deskTxFactFee;

  /// Label in the facts list on the transaction detail: amount plus fee. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deskTxFactTotal;

  /// Label in the facts list on the transaction detail: the note attached to the payment. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get deskTxFactMessage;

  /// Payment proof line on the transaction detail, and a step of the timeline.
  ///
  /// In en, this message translates to:
  /// **'Signed by the recipient'**
  String get deskTxSignedByRecipient;

  /// Button on the transaction detail that opens the payment proof. Short.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get deskTxProofView;

  /// Collapsible section on the transaction detail with technical identifiers.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get deskTxTechTitle;

  /// Technical details label: the wallet's internal number of the transaction. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Id'**
  String get deskTxTechId;

  /// Technical details label: the slate id, a unique id of the payment. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Slate id'**
  String get deskTxTechSlate;

  /// Tooltip of the copy button next to the slate id.
  ///
  /// In en, this message translates to:
  /// **'Copy slate id'**
  String get deskTxCopySlate;

  /// Technical details label: the block height. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get deskTxTechHeight;

  /// Technical details label: the transaction kernel. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get deskTxTechKernel;

  /// Technical details label: when the payment was confirmed. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get deskTxTechConfirmed;

  /// Technical details label: the amount added to the balance. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Credited'**
  String get deskTxTechCredited;

  /// Technical details label: the amount taken from the balance. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Debited'**
  String get deskTxTechDebited;

  /// Technical details label: the internal state name. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deskTxTechStatus;

  /// Technical details label: the core's transaction type name. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get deskTxTechType;

  /// Timeline step of a mining reward.
  ///
  /// In en, this message translates to:
  /// **'Mined in a block'**
  String get deskTxStepMined;

  /// Timeline step: the payment can be spent. Also the status of a payment that has enough confirmations.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get deskTxStepSpendable;

  /// Small line under the Spendable step of a mining reward.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} block to go} other{{count} blocks to go}}'**
  String deskTxStepBlocksToGo(int count);

  /// Timeline step of an incoming payment: the sender's first message arrived.
  ///
  /// In en, this message translates to:
  /// **'Received slate'**
  String get deskTxStepReceivedSlate;

  /// Timeline step of an outgoing payment.
  ///
  /// In en, this message translates to:
  /// **'Created and signed'**
  String get deskTxStepCreated;

  /// Timeline step of an incoming payment: this wallet signed and sent it back.
  ///
  /// In en, this message translates to:
  /// **'Signed and returned'**
  String get deskTxStepSignedReturned;

  /// Small line under a timeline step of an outgoing file payment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the response file'**
  String get deskTxStepWaitingFile;

  /// Small line under a timeline step of an outgoing payment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the recipient'**
  String get deskTxStepWaitingRecipient;

  /// Timeline step: the payment was sent to the network.
  ///
  /// In en, this message translates to:
  /// **'Posted to the network'**
  String get deskTxStepPosted;

  /// Timeline step: the payment is in a block and collecting confirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get deskTxStepConfirming;

  /// Small line under the Confirming step: confirmations so far of how many are needed.
  ///
  /// In en, this message translates to:
  /// **'{confirmations} of {needed}'**
  String deskTxStepProgress(int confirmations, int needed);

  /// Title of the dialog that asks before cancelling an incoming payment.
  ///
  /// In en, this message translates to:
  /// **'Cancel this payment?'**
  String get deskTxCancelIncomingTitle;

  /// Title of the dialog that asks before cancelling an outgoing payment.
  ///
  /// In en, this message translates to:
  /// **'Cancel this send?'**
  String get deskTxCancelOutgoingTitle;

  /// Body of the dialog that asks before cancelling an incoming payment.
  ///
  /// In en, this message translates to:
  /// **'{amount} EPIC from {who} leaves your balance. The wallet asks the node first and refuses if the payment is already in the node’s pool or a block. If the sender posts it later, it may still arrive.'**
  String deskTxCancelIncomingBody(String amount, String who);

  /// Body of the dialog that asks before cancelling an outgoing payment.
  ///
  /// In en, this message translates to:
  /// **'{amount} EPIC to {who}. The locked amount returns to the balance. If the recipient already finalized it, it may still confirm.'**
  String deskTxCancelOutgoingBody(String amount, String who);

  /// Button in the cancel dialog that leaves the payment as it is. Short.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get deskTxCancelKeep;

  /// Danger button in the cancel dialog for an incoming payment. Short.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get deskTxCancelIncomingAction;

  /// Danger button in the cancel dialog for an outgoing payment. Short.
  ///
  /// In en, this message translates to:
  /// **'Cancel send'**
  String get deskTxCancelOutgoingAction;

  /// Description in the payment proof dialog for an incoming payment.
  ///
  /// In en, this message translates to:
  /// **'Proves that this wallet received {amount} EPIC in this kernel.'**
  String deskTxProofIncoming(String amount);

  /// Description in the payment proof dialog for an outgoing payment.
  ///
  /// In en, this message translates to:
  /// **'Proves that the recipient received {amount} EPIC in this kernel.'**
  String deskTxProofOutgoing(String amount);

  /// Field label in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Sender address'**
  String get deskTxProofSenderAddress;

  /// Field label in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get deskTxProofRecipientAddress;

  /// Field label in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Recipient signature'**
  String get deskTxProofRecipientSignature;

  /// Tooltip of the copy button next to the kernel in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy kernel'**
  String get deskTxProofCopyKernel;

  /// Tooltip of the copy button next to the sender address in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy sender address'**
  String get deskTxProofCopySender;

  /// Tooltip of the copy button next to the recipient address in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy recipient address'**
  String get deskTxProofCopyRecipient;

  /// Tooltip of the copy button next to the recipient signature in the payment proof dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy recipient signature'**
  String get deskTxProofCopySignature;

  /// Primary button in the payment proof dialog: save the proof as a file. Short.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get deskTxProofExport;

  /// Toast title after the payment proof was saved to a file; the path follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Proof saved'**
  String get deskTxProofSaved;

  /// Title of the Welcome page when the app already has wallets and the user adds another.
  ///
  /// In en, this message translates to:
  /// **'Add a wallet'**
  String get deskOnbWelcomeAdd;

  /// Line under the app name on the first-run Welcome page.
  ///
  /// In en, this message translates to:
  /// **'Keys and coins stay on this computer, locked with a password.'**
  String get deskOnbWelcomeTagline;

  /// Title of a choice card on the Welcome page: make a brand new wallet.
  ///
  /// In en, this message translates to:
  /// **'Create a new wallet'**
  String get deskOnbWelcomeCreate;

  /// One-line description under 'Create a new wallet': a new wallet gets new recovery words.
  ///
  /// In en, this message translates to:
  /// **'New recovery phrase'**
  String get deskOnbWelcomeCreateSub;

  /// Title of a choice card on the Welcome page: bring in wallets from an older Epic Wallet or from a folder.
  ///
  /// In en, this message translates to:
  /// **'Import wallets'**
  String get deskOnbWelcomeImport;

  /// One-line description under 'Import wallets'.
  ///
  /// In en, this message translates to:
  /// **'From an older Epic Wallet or a folder'**
  String get deskOnbWelcomeImportSub;

  /// Title of a choice card on the Welcome page: restore a wallet from its recovery words.
  ///
  /// In en, this message translates to:
  /// **'Restore from a phrase'**
  String get deskOnbWelcomeRestore;

  /// One-line description under 'Restore from a phrase'.
  ///
  /// In en, this message translates to:
  /// **'From the recovery words'**
  String get deskOnbWelcomeRestoreSub;

  /// Note on the Welcome page when a test network is selected; the network's name is shown beside it.
  ///
  /// In en, this message translates to:
  /// **'New wallets are made on this test network.'**
  String get deskOnbWelcomeTestNote;

  /// Link on the Welcome page (when wallets exist) that returns to the unlock screen.
  ///
  /// In en, this message translates to:
  /// **'Back to unlock'**
  String get deskOnbWelcomeBack;

  /// Title of the collapsible 'Advanced' section of the Welcome page (network and data folder).
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get deskOnbWelcomeAdvanced;

  /// Label of the network selector in the Advanced section of the Welcome page, and its screen-reader name.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get deskOnbWelcomeNetwork;

  /// Help text under the network selector. Mainnet, Floonet and Usernet are network names and stay as they are.
  ///
  /// In en, this message translates to:
  /// **'Mainnet holds real EPIC. Floonet and Usernet are test networks.'**
  String get deskOnbWelcomeNetworkHelp;

  /// Label of the data-folder setting in the Advanced section of the Welcome page.
  ///
  /// In en, this message translates to:
  /// **'App data folder'**
  String get deskOnbWelcomeFolder;

  /// Tooltip of the info button beside 'App data folder' when the details are shown.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get deskOnbWelcomeHideDetails;

  /// Tooltip of the info button beside 'App data folder' when the details are hidden.
  ///
  /// In en, this message translates to:
  /// **'More about this'**
  String get deskOnbWelcomeMoreAbout;

  /// Short explanation under 'App data folder'.
  ///
  /// In en, this message translates to:
  /// **'Where the app keeps wallets and settings.'**
  String get deskOnbWelcomeFolderWhere;

  /// Longer explanation shown when the info button is pressed.
  ///
  /// In en, this message translates to:
  /// **'With the local node, the blockchain is kept here too. A new folder must be empty: the app makes its folders there and keeps using it.'**
  String get deskOnbWelcomeFolderDetail;

  /// Confirmation after the user picked a data folder. {folder} is a path.
  ///
  /// In en, this message translates to:
  /// **'Using {folder}. The app restarts to use it.'**
  String deskOnbWelcomeUsing(String folder);

  /// Note instead of the folder button once a wallet exists.
  ///
  /// In en, this message translates to:
  /// **'It can be changed only before the first wallet is added.'**
  String get deskOnbWelcomeLocked;

  /// Button and dialog title: pick the app data folder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get deskOnbWelcomeChooseFolder;

  /// Link that goes back to the default data folder.
  ///
  /// In en, this message translates to:
  /// **'Default folder'**
  String get deskOnbWelcomeDefaultFolder;

  /// Error under the data-folder setting: the chosen folder has files in it.
  ///
  /// In en, this message translates to:
  /// **'That folder is not empty. Choose a new, empty folder.'**
  String get deskOnbWelcomeFolderNotEmpty;

  /// Error under the data-folder setting: the chosen folder already holds a wallet.
  ///
  /// In en, this message translates to:
  /// **'That is a wallet folder. Choose a new, empty folder.'**
  String get deskOnbWelcomeFolderIsWallet;

  /// Button of the folder dialog: confirm the selected folder. One word.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get deskOnbWelcomeChoose;

  /// Name of the first step in the left rail of the new-wallet and restore pages. One short word.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deskOnbStepPassword;

  /// Name of a step in the left rail of the new-wallet and restore pages, and the title of the page that shows the recovery words. Short.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get deskOnbStepPhrase;

  /// Progress step while the new wallet is made.
  ///
  /// In en, this message translates to:
  /// **'Creating the wallet and its recovery phrase'**
  String get deskOnbCreateStageCreate;

  /// Progress step after the wallet is made: its account is saved.
  ///
  /// In en, this message translates to:
  /// **'Saving the account'**
  String get deskOnbCreateStageSave;

  /// Title of the new-wallet progress page after a failure.
  ///
  /// In en, this message translates to:
  /// **'Wallet not created'**
  String get deskOnbCreateNotCreated;

  /// Title of the new-wallet progress page while it works.
  ///
  /// In en, this message translates to:
  /// **'Creating the wallet'**
  String get deskOnbCreateCreating;

  /// Line under the progress title when a test network is selected. {network} is the network's name, e.g. Floonet.
  ///
  /// In en, this message translates to:
  /// **'A wallet on {network}, a test network.'**
  String deskOnbCreateTestLead(String network);

  /// Heading of the failure box on the new-wallet progress page.
  ///
  /// In en, this message translates to:
  /// **'The wallet could not be created'**
  String get deskOnbCreateFailedTitle;

  /// Failure text on the new-wallet progress page when the disk is full.
  ///
  /// In en, this message translates to:
  /// **'The account could not be saved: the disk is full.'**
  String get deskOnbCreateDiskFull;

  /// Hint on the new-wallet progress page.
  ///
  /// In en, this message translates to:
  /// **'This can take up to a minute. Keep the app open.'**
  String get deskOnbCreateWait;

  /// Title and progress step while a wallet that is open gets locked before the new one is used.
  ///
  /// In en, this message translates to:
  /// **'Locking the open wallet'**
  String get deskOnbCreateLocking;

  /// Title above the step rail on the left of the new-wallet pages.
  ///
  /// In en, this message translates to:
  /// **'New wallet'**
  String get deskOnbCreateSide;

  /// Title of the password page of the new-wallet flow and label of its primary button.
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get deskOnbCreateTitle;

  /// Text under the title of the password page of the new-wallet flow.
  ///
  /// In en, this message translates to:
  /// **'The password unlocks this wallet on this computer. It cannot recover coins; the phrase on the next step does.'**
  String get deskOnbCreateLead;

  /// Note on the password page when a test network is selected; the network's name is shown beside it.
  ///
  /// In en, this message translates to:
  /// **'A wallet on a test network, not for real EPIC'**
  String get deskOnbCreateTestNote;

  /// Text under the title of the recovery phrase page.
  ///
  /// In en, this message translates to:
  /// **'These words are the only way to get the coins back if this computer breaks. Write them on paper, in order.'**
  String get deskOnbCreatePhraseLead;

  /// Small hint beside the disabled Continue button until the phrase is revealed.
  ///
  /// In en, this message translates to:
  /// **'Reveal the phrase first'**
  String get deskOnbCreateRevealFirst;

  /// Warning box above the recovery words.
  ///
  /// In en, this message translates to:
  /// **'Anyone with these words can take the coins'**
  String get deskOnbCreateWarn;

  /// Button over the hidden recovery words.
  ///
  /// In en, this message translates to:
  /// **'Reveal phrase'**
  String get deskOnbCreateReveal;

  /// Hint under the Reveal phrase button.
  ///
  /// In en, this message translates to:
  /// **'Check that nobody can see the screen.'**
  String get deskOnbCreateCheckScreen;

  /// Button that hides the revealed recovery words again. One short word.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get deskOnbCreateHide;

  /// Button that shows the recovery phrase as a QR code.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get deskOnbCreateShowQr;

  /// Button that hides the recovery phrase QR code.
  ///
  /// In en, this message translates to:
  /// **'Hide QR code'**
  String get deskOnbCreateHideQr;

  /// Warning title above the recovery phrase QR code.
  ///
  /// In en, this message translates to:
  /// **'Anyone who scans this code can take the coins'**
  String get deskOnbCreateQrWarn;

  /// Warning text above the recovery phrase QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan it only into another wallet you trust.'**
  String get deskOnbCreateQrWarnText;

  /// Screen-reader label of the recovery phrase QR code image.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase as a QR code'**
  String get deskOnbCreateQrLabel;

  /// Checkbox label the user ticks after writing the recovery phrase down. {count} is the number of words (12 or 24).
  ///
  /// In en, this message translates to:
  /// **'Written down: all {count, plural, one{{count} word} other{{count} words}} on paper'**
  String deskOnbCreateWritten(int count);

  /// Toast shown after a wallet was restored from its recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'Wallet restored.'**
  String get deskOnbRestoreDone;

  /// Title of the restore progress page after a failure.
  ///
  /// In en, this message translates to:
  /// **'Wallet not restored'**
  String get deskOnbRestoreNotRestored;

  /// Title of the restore progress page and its progress step.
  ///
  /// In en, this message translates to:
  /// **'Restoring the wallet'**
  String get deskOnbRestoreRestoring;

  /// Heading of the failure box on the restore progress page.
  ///
  /// In en, this message translates to:
  /// **'The wallet could not be restored'**
  String get deskOnbRestoreFailedTitle;

  /// Sample failure text on the restore progress page (permission denied). The folder path stays as written.
  ///
  /// In en, this message translates to:
  /// **'The wallet files could not be written: permission denied in ~/.config/Epic Cash Desktop.'**
  String get deskOnbRestorePermission;

  /// Hint on the restore progress page.
  ///
  /// In en, this message translates to:
  /// **'This can take up to a minute. The balance appears after the first scan of the chain.'**
  String get deskOnbRestoreWait;

  /// Title above the step rail on the left of the restore pages and label of the primary button of the password step.
  ///
  /// In en, this message translates to:
  /// **'Restore wallet'**
  String get deskOnbRestoreSide;

  /// Title of the password step of the restore flow.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get deskOnbRestoreChoosePassword;

  /// Text under the title of the password step of the restore flow. {count} is the number of words (12 or 24).
  ///
  /// In en, this message translates to:
  /// **'The {count}-word phrase checks out. Set the password that unlocks this wallet on this computer. The wallet opens when it is restored.'**
  String deskOnbRestorePasswordLead(int count);

  /// Status line under the phrase grid when Paste found no words on the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste: the clipboard holds no words.'**
  String get deskOnbRestoreNothingToPaste;

  /// Status line under the phrase grid: a typed word is not a valid recovery word. {position} is its number in the phrase.
  ///
  /// In en, this message translates to:
  /// **'Word {position}, \"{word}\", is not in the word list.'**
  String deskOnbRestoreBadWord(int position, String word);

  /// Status line under the phrase grid when the whole phrase is valid. {count} is 12 or 24.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{All {count} word checks out.} other{All {count} words check out.}}'**
  String deskOnbRestoreAllOk(int count);

  /// Default status line under the phrase grid.
  ///
  /// In en, this message translates to:
  /// **'The phrase never leaves this computer.'**
  String get deskOnbRestoreStaysHere;

  /// Status line under the phrase grid: all words are valid but the checksum is wrong.
  ///
  /// In en, this message translates to:
  /// **'This phrase\'s check number does not match. Compare every word with the paper.'**
  String get deskOnbRestoreChecksumFirm;

  /// Status line under the phrase grid while typing: the words so far do not give a valid check number. {count} is how many words are filled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} word so far; the check number does not match. Keep typing, or compare every word with the paper.} other{{count} words so far; the check number does not match. Keep typing, or compare every word with the paper.}}'**
  String deskOnbRestoreChecksumSoFar(int count);

  /// Text under the title of the recovery phrase step of the restore flow.
  ///
  /// In en, this message translates to:
  /// **'Type the words in order, or paste the whole phrase into any box. Line breaks, commas and numbering are ignored.'**
  String get deskOnbRestoreWordsLead;

  /// Button on the restore phrase step: empty the phrase grid. One word.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get deskOnbRestoreClear;

  /// Primary button of the restore phrase step once the phrase is complete. Narrow: short. {count} is 12 or 24.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use {count} word} other{Use {count} words}}'**
  String deskOnbRestoreUseWords(int count);

  /// Label above the phrase grid.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get deskOnbRestoreWords;

  /// Counter above the phrase grid, e.g. '12 of 24 words'.
  ///
  /// In en, this message translates to:
  /// **'{filled} of {total, plural, one{{total} word} other{{total} words}}'**
  String deskOnbRestoreFilledOf(int filled, int total);

  /// Title of the dialog shown on unlock when an older wallet or node process is still running.
  ///
  /// In en, this message translates to:
  /// **'Epic is already running'**
  String get deskOnbKillTitle;

  /// Body of the 'Epic is already running' dialog.
  ///
  /// In en, this message translates to:
  /// **'Another wallet or node process is using the wallet files and ports. Close it to unlock here, or cancel and close it yourself.'**
  String get deskOnbKillBody;

  /// Screen-reader name of the list of running processes in that dialog.
  ///
  /// In en, this message translates to:
  /// **'Running processes'**
  String get deskOnbKillProcesses;

  /// Small grey note beside a process in the list: it is the wallet service. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'wallet service'**
  String get deskOnbKillRoleWallet;

  /// Small grey note beside a process in the list: it is a node. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'node'**
  String get deskOnbKillRoleNode;

  /// Note under the process list.
  ///
  /// In en, this message translates to:
  /// **'Closing them stops what they were doing, such as a node sync or receiving payments. They start again from this app after unlock.'**
  String get deskOnbKillNote;

  /// Danger button of the 'Epic is already running' dialog while the processes are being closed.
  ///
  /// In en, this message translates to:
  /// **'Closing…'**
  String get deskOnbKillClosing;

  /// Danger button of the 'Epic is already running' dialog: close the processes and unlock the wallet.
  ///
  /// In en, this message translates to:
  /// **'Close and unlock'**
  String get deskOnbKillClose;

  /// Title of the dialog shown when the typed recovery phrase belongs to a wallet that is already in the list.
  ///
  /// In en, this message translates to:
  /// **'This wallet is already here'**
  String get deskOnbSameTitle;

  /// Body of that dialog.
  ///
  /// In en, this message translates to:
  /// **'The phrase belongs to a wallet in the list. Nothing was added.'**
  String get deskOnbSameBody;

  /// Screen-reader name of the box that shows the existing wallet's name and folder.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get deskOnbSameWallet;

  /// Note in that dialog. 'Open it' and 'Cancel' are the two buttons below.
  ///
  /// In en, this message translates to:
  /// **'Open it asks for that wallet\'s password. Cancel keeps the phrase on the grid.'**
  String get deskOnbSameNote;

  /// Primary button of that dialog: go to the existing wallet's unlock. Short.
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get deskOnbSameOpen;

  /// Tooltip of the 'Remember on this computer' checkbox on Windows, and part of the Remembered row in Settings: who can open a remembered wallet.
  ///
  /// In en, this message translates to:
  /// **'Anyone using this Windows account can open this wallet.'**
  String get deskOnbUnlockWhoWindows;

  /// Same as the previous message on macOS and Linux (the computer account).
  ///
  /// In en, this message translates to:
  /// **'Anyone using this account can open this wallet.'**
  String get deskOnbUnlockWho;

  /// Error under the password field after a wrong password.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Check Caps Lock and the keyboard layout.'**
  String get deskOnbUnlockWrong;

  /// Failure text when the wallet service cannot start because its port is taken. Keep the number 3415.
  ///
  /// In en, this message translates to:
  /// **'The wallet service did not start: port 3415 is in use by another program.'**
  String get deskOnbUnlockPortInUse;

  /// Progress step while unlocking.
  ///
  /// In en, this message translates to:
  /// **'Checking wallet files'**
  String get deskOnbUnlockStageCheck;

  /// Progress step while unlocking: looking for older wallet processes.
  ///
  /// In en, this message translates to:
  /// **'Looking for wallet processes still running'**
  String get deskOnbUnlockStageProcesses;

  /// Progress step while unlocking: closing older wallet processes.
  ///
  /// In en, this message translates to:
  /// **'Closing the old wallet processes'**
  String get deskOnbUnlockStageClosing;

  /// Progress step while unlocking.
  ///
  /// In en, this message translates to:
  /// **'Starting the wallet service'**
  String get deskOnbUnlockStageWallet;

  /// Progress step while unlocking.
  ///
  /// In en, this message translates to:
  /// **'Unlocking the wallet'**
  String get deskOnbUnlockStageUnlock;

  /// Error under the password field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the password'**
  String get deskOnbUnlockEnter;

  /// Error under the password field when the user cancelled the 'Epic is already running' dialog.
  ///
  /// In en, this message translates to:
  /// **'Close the other Epic processes, then unlock.'**
  String get deskOnbUnlockCloseOthers;

  /// Error under the password field when the remembered password could not be read.
  ///
  /// In en, this message translates to:
  /// **'Remembered password unavailable. Enter the password.'**
  String get deskOnbUnlockRememberedUnavailable;

  /// Error under the password field when the remembered password no longer works.
  ///
  /// In en, this message translates to:
  /// **'The remembered password was forgotten. Enter the password.'**
  String get deskOnbUnlockRememberedForgotten;

  /// Toast title after unlocking with 'Remember on this computer' ticked when the password could not be stored.
  ///
  /// In en, this message translates to:
  /// **'Not remembered'**
  String get deskOnbUnlockNotRemembered;

  /// Toast text for the previous message.
  ///
  /// In en, this message translates to:
  /// **'This computer\'s key store is unavailable.'**
  String get deskOnbUnlockKeyStore;

  /// Fallback name in 'Unlocking {name}' when the wallet's name is not known. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'this wallet'**
  String get deskOnbUnlockThisWallet;

  /// Title of the unlock progress page after a failure.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed'**
  String get deskOnbUnlockFailed;

  /// Line under the title of a failed unlock.
  ///
  /// In en, this message translates to:
  /// **'The wallet did not open. The reason is below.'**
  String get deskOnbUnlockFailedLead;

  /// Heading of the failure box of a failed unlock.
  ///
  /// In en, this message translates to:
  /// **'The wallet did not open'**
  String get deskOnbUnlockFailedBox;

  /// Title of the unlock progress page. {name} is the wallet's name.
  ///
  /// In en, this message translates to:
  /// **'Unlocking {name}'**
  String deskOnbUnlockUnlocking(String name);

  /// Line under the title of the unlock progress page.
  ///
  /// In en, this message translates to:
  /// **'Each step shows as it finishes.'**
  String get deskOnbUnlockStepsLead;

  /// Note under the unlock progress list.
  ///
  /// In en, this message translates to:
  /// **'Then the overview opens and finishes in the background: connecting to the node, updating balances, turning on receiving.'**
  String get deskOnbUnlockNote;

  /// Title of the unlock page.
  ///
  /// In en, this message translates to:
  /// **'Unlock wallet'**
  String get deskOnbUnlockTitle;

  /// Line under the title of the unlock page.
  ///
  /// In en, this message translates to:
  /// **'Keys stay on this computer.'**
  String get deskOnbUnlockLead;

  /// Checkbox on the unlock page: store the password in this computer's key store.
  ///
  /// In en, this message translates to:
  /// **'Remember on this computer'**
  String get deskOnbUnlockRemember;

  /// Note under the 'Remember on this computer' checkbox. {who} is the sentence about who can open the wallet.
  ///
  /// In en, this message translates to:
  /// **'For 30 days. {who}'**
  String deskOnbUnlockRememberFor(String who);

  /// Warning title on the unlock page when the wallet's folder no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This wallet’s folder is missing'**
  String get deskOnbUnlockMissingTitle;

  /// Warning text under the previous title. {folder} is a path.
  ///
  /// In en, this message translates to:
  /// **'It was at {folder}'**
  String deskOnbUnlockMissingText(String folder);

  /// Button of the missing-folder warning: remove the wallet from the list. One word.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deskOnbUnlockRemove;

  /// Button of the missing-folder warning: look for the folder again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deskOnbUnlockTryAgain;

  /// Primary button of the unlock page. One word.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get deskOnbUnlockButton;

  /// End of the 'growing slowly' line on the local node step when the free disk space is not known. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'free space unknown'**
  String get deskOnbNodeFreeUnknown;

  /// End of the 'growing slowly' line on the local node step. {size} is e.g. '120 GB'.
  ///
  /// In en, this message translates to:
  /// **'{size} free here'**
  String deskOnbNodeFreeHere(String size);

  /// Bold start of a line on the local node step: the chain takes about this much disk space now. {size} is e.g. '5 GB'.
  ///
  /// In en, this message translates to:
  /// **'About {size} of disk now'**
  String deskOnbNodeDiskAbout(String size);

  /// Bold start of a line on the local node step: the chain takes this much disk space now (measured).
  ///
  /// In en, this message translates to:
  /// **'{size} of disk now'**
  String deskOnbNodeDisk(String size);

  /// Bold start of the first fact of the local node step, read together with the next message.
  ///
  /// In en, this message translates to:
  /// **'A separate program.'**
  String get deskOnbNodeSeparate;

  /// Rest of the first fact of the local node step.
  ///
  /// In en, this message translates to:
  /// **'The wallet starts the Epic node and stops it with the app.'**
  String get deskOnbNodeSeparateText;

  /// Bold start of a fact shown on Windows only, read together with the next message.
  ///
  /// In en, this message translates to:
  /// **'Windows asks once'**
  String get deskOnbNodeFirewall;

  /// Rest of the Windows firewall fact. Continues the previous sentence start, in lowercase.
  ///
  /// In en, this message translates to:
  /// **'to allow it through the firewall. Allow it on private networks.'**
  String get deskOnbNodeFirewallText;

  /// Rest of the disk-space fact, continues 'About 5 GB of disk now'. {free} is the free-space phrase, e.g. '120 GB free here'.
  ///
  /// In en, this message translates to:
  /// **'growing slowly. {free}.'**
  String deskOnbNodeGrowing(String free);

  /// Bold start of a fact on the local node step, read together with the next message.
  ///
  /// In en, this message translates to:
  /// **'Hours to sync'**
  String get deskOnbNodeHours;

  /// Rest of the 'Hours to sync' fact. Continues the bold start in lowercase.
  ///
  /// In en, this message translates to:
  /// **'the first time, 2 to 6 on a typical connection. The wallet shows the progress and can use a public node meanwhile.'**
  String get deskOnbNodeHoursText;

  /// Bold start of a fact on the local node step, read together with the next message.
  ///
  /// In en, this message translates to:
  /// **'About 4 GB downloaded'**
  String get deskOnbNodeDownload;

  /// Rest of the download fact. Continues the bold start in lowercase.
  ///
  /// In en, this message translates to:
  /// **'the first time, then a little every day.'**
  String get deskOnbNodeDownloadText;

  /// Bold green word on the local node step: a node is running on this computer.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get deskOnbNodeFound;

  /// Part of the 'Found' line: the node's version and address, e.g. 'Epic 4.1.1 at 127.0.0.1:3413'.
  ///
  /// In en, this message translates to:
  /// **'Epic {version} at {address}'**
  String deskOnbNodeFoundAt(String version, String address);

  /// Part of the 'Found' line: the node's block height.
  ///
  /// In en, this message translates to:
  /// **'height {height}'**
  String deskOnbNodeHeight(String height);

  /// Part of the 'Found' line: the node is fully synced.
  ///
  /// In en, this message translates to:
  /// **'synced'**
  String get deskOnbNodeSynced;

  /// Bold red words on the local node step: nothing answers at the address.
  ///
  /// In en, this message translates to:
  /// **'No node answers'**
  String get deskOnbNodeNoAnswer;

  /// Rest of the 'No node answers' line. {address} is host:port.
  ///
  /// In en, this message translates to:
  /// **'at {address}. Start it, or check the address and port.'**
  String deskOnbNodeNoAnswerAt(String address);

  /// Title of a choice card on the local node step.
  ///
  /// In en, this message translates to:
  /// **'Use a node already running on this computer'**
  String get deskOnbNodeExisting;

  /// Description of that choice card.
  ///
  /// In en, this message translates to:
  /// **'The Epic GUI or CLI node. The wallet connects to it and starts nothing.'**
  String get deskOnbNodeExistingText;

  /// Screen-reader name of the node address field.
  ///
  /// In en, this message translates to:
  /// **'Address of the node on this computer'**
  String get deskOnbNodeAddress;

  /// Button next to the node address field: test the address. One word.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get deskOnbNodeCheck;

  /// Title of a choice card on the local node step.
  ///
  /// In en, this message translates to:
  /// **'Start the bundled node'**
  String get deskOnbNodeBundled;

  /// Description of that choice card. 'Save' is the button of the last setup step.
  ///
  /// In en, this message translates to:
  /// **'Downloads and syncs the chain into the wallet’s own folder. Nothing is downloaded before Save on the last step.'**
  String get deskOnbNodeBundledText;

  /// Checkbox label under the bundled node choice. {host} is a public node's host name.
  ///
  /// In en, this message translates to:
  /// **'Use {host} until the local node is synced. The local node takes over by itself.'**
  String deskOnbNodeFallback(String host);

  /// Title of the local node setup dialog opened from Settings › Node.
  ///
  /// In en, this message translates to:
  /// **'Local node'**
  String get deskOnbNodeDialogTitle;

  /// Description in that dialog.
  ///
  /// In en, this message translates to:
  /// **'What running the node here means, and which node to use.'**
  String get deskOnbNodeDialogBody;

  /// Primary button of that dialog when 'already running' is chosen.
  ///
  /// In en, this message translates to:
  /// **'Use this node'**
  String get deskOnbNodeUseThis;

  /// Primary button of that dialog when the bundled node is chosen.
  ///
  /// In en, this message translates to:
  /// **'Start local node'**
  String get deskOnbNodeStart;

  /// Status line under the phrase grid after pasting text whose number of words is not a valid phrase length. {count} is the number of pasted words.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} word pasted; a phrase has 12, 15, 18, 21 or 24} other{{count} words pasted; a phrase has 12, 15, 18, 21 or 24}}'**
  String deskOnbRestorePasteCount(int count);

  /// Screen-reader name of one box of the recovery phrase grid. {number} is its position, from 1.
  ///
  /// In en, this message translates to:
  /// **'Word {number}'**
  String deskOnbWordN(int number);

  /// Error under the old-password field of the import wizard when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the old password'**
  String get deskOnbImportEnterOld;

  /// Error when the new password the import wizard asks for is too short.
  ///
  /// In en, this message translates to:
  /// **'New password: at least {count, plural, one{{count} character} other{{count} characters}}'**
  String deskOnbImportNewShort(int count);

  /// Error when the two new passwords typed in the import wizard are not the same.
  ///
  /// In en, this message translates to:
  /// **'The new passwords differ'**
  String get deskOnbImportNewDiffer;

  /// Name shown for the wallets just imported when more than one, e.g. '3 wallets'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} wallet} other{{count} wallets}}'**
  String deskOnbImportWalletsN(int count);

  /// Notice on the unlock page after the import wizard finished.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Wallet imported.} other{{count} wallets imported.}}'**
  String deskOnbImportDone(int count);

  /// Title of the first step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Finding wallets'**
  String get deskOnbImportFindingTitle;

  /// Line under the title of the first step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Searching the folders of older Epic Wallet versions and the epic program. Nothing is changed.'**
  String get deskOnbImportFindingLead;

  /// Title of the import wizard once wallets were found.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} wallet found} other{{count} wallets found}}'**
  String deskOnbImportFoundTitle(int count);

  /// Line under the 'wallets found' title.
  ///
  /// In en, this message translates to:
  /// **'Old folders are only read.'**
  String get deskOnbImportFoundLead;

  /// Title of the import wizard when nothing was found.
  ///
  /// In en, this message translates to:
  /// **'No wallets found'**
  String get deskOnbImportNoneTitle;

  /// Line under the 'No wallets found' title.
  ///
  /// In en, this message translates to:
  /// **'Choose the wallet folder, or restore from the recovery phrase.'**
  String get deskOnbImportNoneLead;

  /// Title of the choose step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Choose wallets'**
  String get deskOnbImportChooseTitle;

  /// Line under the 'Choose wallets' title.
  ///
  /// In en, this message translates to:
  /// **'Ticked wallets are added to the app. History is rebuilt by a scan.'**
  String get deskOnbImportChooseLead;

  /// Title of the check step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Checking for use'**
  String get deskOnbImportCheckTitle;

  /// Line under the 'Checking for use' title.
  ///
  /// In en, this message translates to:
  /// **'A wallet in use by another program is not imported.'**
  String get deskOnbImportCheckLead;

  /// Title of the import step of the import wizard, its primary button and a step name in the left rail. One word.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get deskOnbImportTitle;

  /// Line under the 'Import' title.
  ///
  /// In en, this message translates to:
  /// **'Each wallet asks for its old password once.'**
  String get deskOnbImportLead;

  /// Title of the last step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Wallets imported'**
  String get deskOnbImportDoneTitle;

  /// Line under the 'Wallets imported' title.
  ///
  /// In en, this message translates to:
  /// **'The first unlock of each wallet scans the chain for its history.'**
  String get deskOnbImportDoneLead;

  /// Counter at the bottom of the choose step. Both are numbers.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String deskOnbImportSelected(int selected, int total);

  /// Status word while a wallet folder is checked, and counter text at the bottom of the check step.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get deskOnbImportChecking;

  /// Hint at the bottom of the check step when a wallet is in use by another program.
  ///
  /// In en, this message translates to:
  /// **'Close the other program or skip the wallet'**
  String get deskOnbImportCloseOther;

  /// Counter at the bottom of the import step. Both are numbers.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} imported'**
  String deskOnbImportImportedOf(int done, int total);

  /// Primary button of the last step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Open wallet'**
  String get deskOnbImportOpen;

  /// Step name in the left rail of the import wizard. One word.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get deskOnbImportStepFind;

  /// Step name in the left rail of the import wizard. One word.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get deskOnbImportStepChoose;

  /// Step name in the left rail of the import wizard. One word.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get deskOnbImportStepCheck;

  /// Back button of the import wizard. One word.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deskOnbImportBack;

  /// Button in the import wizard: leave this wallet out. One word.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get deskOnbImportSkip;

  /// Name of a place being searched on the first step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Older Epic Wallet'**
  String get deskOnbImportOlder;

  /// Small text under 'Older Epic Wallet' on the first step.
  ///
  /// In en, this message translates to:
  /// **'Accounts and folders'**
  String get deskOnbImportOlderSub;

  /// Name of a place being searched on the first step of the import wizard (the command-line program called epic).
  ///
  /// In en, this message translates to:
  /// **'The epic program'**
  String get deskOnbImportEpicProgram;

  /// Status word beside a place being searched.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get deskOnbImportSearching;

  /// Link in the import wizard when nothing was found: restore from the recovery words instead.
  ///
  /// In en, this message translates to:
  /// **'Restore from phrase'**
  String get deskOnbImportRestore;

  /// Small line under a found wallet. {date} is a date.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String deskOnbImportLastUsed(String date);

  /// Small note under a found wallet that is already in the app. {reason} is a sentence from the app about why.
  ///
  /// In en, this message translates to:
  /// **'{reason}. Tick for a second copy.'**
  String deskOnbImportSecondCopy(String reason);

  /// Screen-reader label of the cross shown for a wallet that cannot be imported. {name} is the wallet's name.
  ///
  /// In en, this message translates to:
  /// **'{name}: cannot be imported'**
  String deskOnbImportCannot(String name);

  /// Small tag on a found wallet that is already in the app.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get deskOnbImportInApp;

  /// Small tag on a found wallet that is the same as another found one.
  ///
  /// In en, this message translates to:
  /// **'Same wallet'**
  String get deskOnbImportSameWallet;

  /// Status word of the check step: the wallet can be imported.
  ///
  /// In en, this message translates to:
  /// **'Not in use'**
  String get deskOnbImportNotInUse;

  /// Status word of the check step: it could not be checked.
  ///
  /// In en, this message translates to:
  /// **'Not checked'**
  String get deskOnbImportNotChecked;

  /// Status word of a wallet that was left out.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get deskOnbImportSkipped;

  /// Status word of the check step: another program uses this wallet.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get deskOnbImportInUse;

  /// Text under a wallet that is in use by another program.
  ///
  /// In en, this message translates to:
  /// **'In use by another program. Close the older Epic Wallet or the epic program, then check again.'**
  String get deskOnbImportInUseText;

  /// Button under a wallet that is in use: check once more.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get deskOnbImportCheckAgain;

  /// Status word of a wallet that was imported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get deskOnbImportImported;

  /// Status word of the wallet being imported now.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get deskOnbImportImporting;

  /// Status word of a wallet that waits for its turn.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get deskOnbImportWaiting;

  /// Label of the old-password field of the import step.
  ///
  /// In en, this message translates to:
  /// **'Old password'**
  String get deskOnbImportOldPassword;

  /// Help text under the old-password field. {name} is the wallet's name.
  ///
  /// In en, this message translates to:
  /// **'The password of {name} in the older app.'**
  String deskOnbImportOldHelp(String name);

  /// Screen-reader name of the old-password field. {name} is the wallet's name.
  ///
  /// In en, this message translates to:
  /// **'Old password of {name}'**
  String deskOnbImportOldOf(String name);

  /// Text shown when the old password is shorter than the app requires. {count} is the minimum length.
  ///
  /// In en, this message translates to:
  /// **'The old password is short. Choose a new one, {count, plural, one{{count} or more characters.} other{{count} or more characters.}}'**
  String deskOnbImportOldShort(int count);

  /// Label and screen-reader name of the new-password field of the import step.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get deskOnbImportNewPassword;

  /// Label of the repeat-password field of the import step. One word.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get deskOnbImportRepeat;

  /// Screen-reader name of the repeat-password field of the import step.
  ///
  /// In en, this message translates to:
  /// **'Repeat the new password'**
  String get deskOnbImportRepeatNew;

  /// Note under the list on the last step of the import wizard.
  ///
  /// In en, this message translates to:
  /// **'Old folders are unchanged. The older app can still open them.'**
  String get deskOnbImportUnchanged;

  /// Title of the dialog asking whether to stop the import half-way.
  ///
  /// In en, this message translates to:
  /// **'Stop the import?'**
  String get deskOnbImportStopTitle;

  /// Body of that dialog.
  ///
  /// In en, this message translates to:
  /// **'Wallets imported so far are removed. Old folders are unchanged.'**
  String get deskOnbImportStopBody;

  /// Button of that dialog: carry on with the import.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get deskOnbImportGoBack;

  /// Danger button of that dialog.
  ///
  /// In en, this message translates to:
  /// **'Stop import'**
  String get deskOnbImportStop;

  /// Status word on the sidebar's Epicbox row while the app waits for Tor to connect first. Narrow: one short phrase.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Tor'**
  String get deskRailWaitingTor;

  /// Status word on a sidebar service row (Epicbox, HTTP): the service is running. One short word.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get deskRailOn;

  /// Status word on the sidebar's Epicbox row: connecting to the Epicbox server. One short word.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get deskRailConnecting;

  /// Status word on the sidebar's Epicbox row: the server answers slowly. One short word.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get deskRailSlow;

  /// Status word on the sidebar's Epicbox row: the server does not answer. Short phrase.
  ///
  /// In en, this message translates to:
  /// **'Not answering'**
  String get deskRailNotAnswering;

  /// Status word on a sidebar service row (Epicbox, HTTP): the service is turned off. One short word.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskRailOff;

  /// Status word on a sidebar row (Node, Epicbox) while its state is not known yet. One short word.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get deskRailChecking;

  /// Line in the sidebar Epicbox hover card: the connection goes through Tor.
  ///
  /// In en, this message translates to:
  /// **'Over Tor'**
  String get deskRailOverTor;

  /// Line in the sidebar Epicbox hover card: Epicbox will connect once Tor is up.
  ///
  /// In en, this message translates to:
  /// **'Waits until Tor is connected.'**
  String get deskRailWaitsForTor;

  /// Line in the sidebar Epicbox hover card when the Epicbox server does not answer: incoming payments are held until it is back.
  ///
  /// In en, this message translates to:
  /// **'Payments wait on the Epicbox server.'**
  String get deskRailPaymentsWait;

  /// Last line of the sidebar Epicbox hover card: a click opens the Epicbox receiving settings.
  ///
  /// In en, this message translates to:
  /// **'Open Epicbox receiving'**
  String get deskRailOpenEpicbox;

  /// Status word on a sidebar row (HTTP): the service is starting. One short word.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get deskRailStarting;

  /// Status word on the sidebar's HTTP row: the HTTP listener failed and nothing can be received that way. Short phrase.
  ///
  /// In en, this message translates to:
  /// **'Not receiving'**
  String get deskRailNotReceiving;

  /// Second line of the sidebar's HTTP row: running and reachable from the internet. Narrow: keep the · separator.
  ///
  /// In en, this message translates to:
  /// **'On · internet'**
  String get deskRailOnInternet;

  /// Second line of the sidebar's HTTP row: running and reachable on this computer's network only. Narrow: keep the · separator.
  ///
  /// In en, this message translates to:
  /// **'On · local'**
  String get deskRailOnLocal;

  /// Second line of the sidebar's HTTP row: the chosen port is taken by another program. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Port in use'**
  String get deskRailPortInUse;

  /// Second line of the sidebar's HTTP row: the HTTP listener stopped. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deskRailStopped;

  /// Line in the sidebar HTTP hover card: the listening port, reachable from the internet.
  ///
  /// In en, this message translates to:
  /// **'Port {port} · from the internet'**
  String deskRailPortInternet(String port);

  /// Line in the sidebar HTTP hover card: the listening port, reachable from this computer only.
  ///
  /// In en, this message translates to:
  /// **'Port {port} · this computer only'**
  String deskRailPortLocal(String port);

  /// Last line of the sidebar HTTP hover card: a click opens the HTTP receiving settings.
  ///
  /// In en, this message translates to:
  /// **'Open HTTP receiving'**
  String get deskRailOpenHttp;

  /// Status word on the sidebar's Tor row when this build of the app does not include Tor.
  ///
  /// In en, this message translates to:
  /// **'Not in this build'**
  String get deskRailTorNotInBuild;

  /// Second line of the sidebar's Tor row while Tor starts. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get deskRailStartingDots;

  /// Line in the sidebar Tor hover card when Tor runs but the app's own Tor address is not published; sending still works. {problem} is a short reason, e.g. 'Tor address not published'.
  ///
  /// In en, this message translates to:
  /// **'{problem}. Sends work.'**
  String deskRailTorSlow(String problem);

  /// Short reason shown in the sidebar Tor hover card when Tor runs but the receiving address is not published yet.
  ///
  /// In en, this message translates to:
  /// **'Tor address not published'**
  String get deskRailTorNoAddress;

  /// Last line of the sidebar Tor hover card: a click opens the Privacy settings.
  ///
  /// In en, this message translates to:
  /// **'Open Privacy settings'**
  String get deskRailOpenPrivacy;

  /// Name of the sidebar's first row: the node the wallet reads the chain from. Very short.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get deskRailNode;

  /// Last line of the sidebar Node hover card: a click opens the node settings.
  ///
  /// In en, this message translates to:
  /// **'Open node settings'**
  String get deskRailOpenNode;

  /// Title of the dialog shown when the built-in node has finished syncing.
  ///
  /// In en, this message translates to:
  /// **'Local node synced'**
  String get deskAppNodeSyncedTitle;

  /// Body of the dialog shown when the built-in node has finished syncing.
  ///
  /// In en, this message translates to:
  /// **'The local node has the whole chain and can be used now. The app restarts to switch to it.'**
  String get deskAppNodeSyncedBody;

  /// Button of the local-node-synced dialog: postpone the restart. Short.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get deskAppNotNow;

  /// Button of the local-node-synced dialog: restart the app and switch to the local node. Short.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get deskAppRestartNow;

  /// Title of the dialog that shows the first scan of a new wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet first scan'**
  String get deskAppFirstScanTitle;

  /// Body of the first-scan dialog.
  ///
  /// In en, this message translates to:
  /// **'The wallet looks through the chain for its outputs. It stays usable; the balance updates when the scan is done.'**
  String get deskAppFirstScanBody;

  /// Screen-reader label of the box listing the scan's progress lines.
  ///
  /// In en, this message translates to:
  /// **'Scan output'**
  String get deskAppScanOutput;

  /// Placeholder in the first-scan dialog before the scan has printed anything.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first output…'**
  String get deskAppWaitingOutput;

  /// Sidebar entry and window title: the Overview page (balance and latest transactions). One word where possible.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get deskShellNavOverview;

  /// Sidebar entry and window title: the list of all transactions. One word where possible.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get deskShellNavActivity;

  /// Sidebar entry and window title: the Send page. One word.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deskShellNavSend;

  /// Sidebar entry and window title: the Receive page. One word.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get deskShellNavReceive;

  /// Sidebar entry and window title: the page listing the wallet's outputs (coins). One word where possible.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get deskShellNavOutputs;

  /// Sidebar entry and window title: the address book. One word where possible.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get deskShellNavContacts;

  /// Sidebar entry, phone top-bar button label and window title: the Settings pages. One word where possible.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get deskShellNavSettings;

  /// Window title of the page where a transaction file is imported.
  ///
  /// In en, this message translates to:
  /// **'Import transaction'**
  String get deskShellTitleImportTx;

  /// Window title of the page where a received transaction file is finalized.
  ///
  /// In en, this message translates to:
  /// **'Finalize transaction'**
  String get deskShellTitleFinalizeTx;

  /// Toast when the user locks the wallet while a payment is still being sent: the lock happens afterwards.
  ///
  /// In en, this message translates to:
  /// **'Locks when the payment is sent'**
  String get deskShellLocksAfterSend;

  /// Toast title when Quit is pressed while a send is in progress.
  ///
  /// In en, this message translates to:
  /// **'Not quit'**
  String get deskShellNotQuitTitle;

  /// Toast body when Quit is pressed while a send is in progress.
  ///
  /// In en, this message translates to:
  /// **'A send is in progress. Quit again once it finishes.'**
  String get deskShellNotQuitBody;

  /// Toast title after Quit in a build that cannot close the app (demo): the wallet was only locked.
  ///
  /// In en, this message translates to:
  /// **'Wallet locked'**
  String get deskShellLockedTitle;

  /// Toast body after Quit in a build that cannot close the app (demo).
  ///
  /// In en, this message translates to:
  /// **'Quit closes the app once the wallet core is connected.'**
  String get deskShellLockedBody;

  /// Tooltip and screen-reader label of the lock button in the sidebar. {keys} is the shortcut, e.g. Ctrl+L or ⌘L.
  ///
  /// In en, this message translates to:
  /// **'Lock wallet ({keys})'**
  String deskShellLockWallet(String keys);

  /// Screen-reader label of the sidebar that holds the main places.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get deskShellMainNav;

  /// Tooltip of the logo and screen-reader label of the version under the compact sidebar. {version} is the app version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String deskShellVersion(String version);

  /// Tooltip of the account row at the bottom of the sidebar: a click opens the wallet's settings.
  ///
  /// In en, this message translates to:
  /// **'Open wallet settings'**
  String get deskShellOpenWalletSettings;

  /// Screen-reader label of the account row at the bottom of the sidebar. {name} is the wallet's name.
  ///
  /// In en, this message translates to:
  /// **'Open wallet settings: {name}'**
  String deskShellOpenWalletSettingsNamed(String name);

  /// Tooltip of the button next to the account row that locks the wallet so another wallet can be picked.
  ///
  /// In en, this message translates to:
  /// **'Switch wallet'**
  String get deskShellSwitchWallet;

  /// Small credit line at the bottom of the sidebar. {maker} is the company's name (BT Labs); the app draws it dimmer.
  ///
  /// In en, this message translates to:
  /// **'Wallet by {maker}'**
  String deskShellWalletBy(String maker);

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get deskTourOverviewTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'The balance and what is still confirming, then the latest transactions. Everything else is in the sidebar.'**
  String get deskTourOverviewText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deskTourSendTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Three ways to pay: an Epicbox address, a Direct address (http(s) or Tor), or a transaction file. A review comes before anything leaves.'**
  String get deskTourSendText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get deskTourReceiveTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'This wallet’s Epicbox address, with HTTP and Tor beside it. Transaction files to sign or finalize are at the bottom.'**
  String get deskTourReceiveText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get deskTourInvoicesTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Pay an invoice someone sent, or issue one to someone who owes you. The tabs switch between the two.'**
  String get deskTourInvoicesText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get deskTourActivityTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Every transaction with its progress and details. A number on this sidebar entry means something waits for an action.'**
  String get deskTourActivityText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get deskTourContactsTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses by name: Epicbox, HTTP or Tor. Send picks from here.'**
  String get deskTourContactsText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Settings › Node'**
  String get deskTourNodeTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Which node the wallet reads the chain from: a public one or the local node. The other settings pages are listed on the left.'**
  String get deskTourNodeText;

  /// Title of the tour card for this page (first-unlock tour). Short.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get deskTourHelpTitle;

  /// Text of the tour card for this page (first-unlock tour); one or two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Topics by section, Report a problem and the app log. More on every page is here, and this tour can be shown again.'**
  String get deskTourHelpText;

  /// Step counter on the tour card, e.g. '2 of 7'. Narrow: keep it short.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String deskTourCounter(int current, int total);

  /// Screen-reader name of the tour card dialog.
  ///
  /// In en, this message translates to:
  /// **'Tour of the wallet'**
  String get deskTourSemantics;

  /// Button on the tour card: close the tour. Short.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get deskTourSkip;

  /// Button on the tour card: previous step. One word.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deskTourBack;

  /// Button on the tour card: next step. One word.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get deskTourNext;

  /// Tag on an address row when the address type is not recognised. One short word.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get deskKitUnknown;

  /// Screen-reader label of the progress ring on a cancelled transaction.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get deskKitRingCancelled;

  /// Screen-reader label of the progress ring on a fully confirmed transaction.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get deskKitRingConfirmed;

  /// Screen-reader label of the progress ring on a transaction still confirming, e.g. '2 of 3 confirmations'. {needed} is the number of confirmations the wallet waits for.
  ///
  /// In en, this message translates to:
  /// **'{confirmations, plural, one{{confirmations} of {needed} confirmation} other{{confirmations} of {needed} confirmations}}'**
  String deskKitRingProgress(int confirmations, int needed);

  /// Screen-reader label of an amount that is hidden behind dots (privacy mode).
  ///
  /// In en, this message translates to:
  /// **'Hidden amount'**
  String get deskKitHiddenAmount;

  /// Button of a file drop zone: opens a file picker. Short.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get deskKitChooseFile;

  /// Screen-reader label of a sidebar entry with a badge, e.g. 'Activity, 2 need action'. {label} is the entry's name.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count, plural, one{{count} needs action} other{{count} need action}}'**
  String deskKitNeedAction(String label, int count);

  /// Status word of a service row (On / Slow / Offline / Off / Checking). One short word.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get deskKitHealthOn;

  /// Status word of a service that answers slowly. One short word.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get deskKitHealthSlow;

  /// Status word of a service that does not answer. One short word.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get deskKitHealthOffline;

  /// Status word of a service that is turned off. One short word.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskKitHealthOff;

  /// Status word of a service whose state is being checked. One short word.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get deskKitHealthChecking;

  /// Tooltip and screen-reader label of the close (X) button of a dialog or drawer; Esc is the keyboard key that does the same.
  ///
  /// In en, this message translates to:
  /// **'Close (Esc)'**
  String get deskKitCloseEsc;

  /// Small grey note beside a form field's label: the field may stay empty. One short word.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get deskKitOptional;

  /// Tooltip of the back arrow at the top of a page; Alt+Left is the keyboard shortcut.
  ///
  /// In en, this message translates to:
  /// **'Back (Alt+Left)'**
  String get deskKitBackAlt;

  /// Small step counter above the title of an onboarding page on a narrow window, e.g. 'Step 2 of 4'.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String deskKitStepOf(int current, int total);

  /// Caption under the Epicbox picture on the Send page. Written in capitals; at most about 24 characters, it sits in a 160 px wide picture.
  ///
  /// In en, this message translates to:
  /// **'EPICBOX SERVER HOLDS IT'**
  String get deskKitHeroCaptionEpicbox;

  /// Caption under the HTTP picture on the Send page. Capitals; at most about 24 characters.
  ///
  /// In en, this message translates to:
  /// **'STRAIGHT TO THEIR WALLET'**
  String get deskKitHeroCaptionHttp;

  /// Caption under the Tor picture on the Send page. Capitals; at most about 24 characters.
  ///
  /// In en, this message translates to:
  /// **'STRAIGHT, THROUGH TOR'**
  String get deskKitHeroCaptionTor;

  /// Caption under the transaction-file picture on the Send page. Capitals; at most about 24 characters.
  ///
  /// In en, this message translates to:
  /// **'FILE OUT, RESPONSE BACK'**
  String get deskKitHeroCaptionFile;

  /// Screen-reader description of the Epicbox picture on the Send page.
  ///
  /// In en, this message translates to:
  /// **'Epicbox: the payment goes to the Epicbox server, which holds it until the recipient\'s wallet is back'**
  String get deskKitHeroLabelEpicbox;

  /// Screen-reader description of the HTTP picture on the Send page.
  ///
  /// In en, this message translates to:
  /// **'HTTP: the payment goes straight to the recipient\'s wallet, which must be open'**
  String get deskKitHeroLabelHttp;

  /// Screen-reader description of the Tor picture on the Send page.
  ///
  /// In en, this message translates to:
  /// **'Tor: the payment goes straight to the recipient\'s wallet, routed through the Tor network'**
  String get deskKitHeroLabelTor;

  /// Screen-reader description of the transaction-file picture on the Send page.
  ///
  /// In en, this message translates to:
  /// **'File: a transaction file is handed over, a response file comes back, then the sender finalizes'**
  String get deskKitHeroLabelFile;

  /// Small button of the internet-reachability notice in the HTTP receiving settings: check again. One word.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get deskKitReachCheck;

  /// Notice title while the app asks an outside service whether the HTTP port is reachable.
  ///
  /// In en, this message translates to:
  /// **'Checking from the internet…'**
  String get deskKitReachChecking;

  /// Notice title when the app could not learn the computer's public IP address.
  ///
  /// In en, this message translates to:
  /// **'Public IP not found'**
  String get deskKitReachNoIpTitle;

  /// Notice text under 'Public IP not found'.
  ///
  /// In en, this message translates to:
  /// **'The internet could not be asked for it. Try again later.'**
  String get deskKitReachNoIpText;

  /// Same as the previous message, plus the computer's address on the local network.
  ///
  /// In en, this message translates to:
  /// **'The internet could not be asked for it. Try again later. On your network: {address}.'**
  String deskKitReachNoIpTextLan(String address);

  /// Notice title when the HTTP port is not reachable from outside.
  ///
  /// In en, this message translates to:
  /// **'Not reachable from the internet'**
  String get deskKitReachClosedTitle;

  /// Notice text: the user must forward the port on their router.
  ///
  /// In en, this message translates to:
  /// **'Forward TCP port {port} on your router to this computer, then check again.'**
  String deskKitReachClosedText(String port);

  /// Same, with the computer's address on the local network in brackets.
  ///
  /// In en, this message translates to:
  /// **'Forward TCP port {port} on your router to this computer ({address}), then check again.'**
  String deskKitReachClosedTextLan(String port, String address);

  /// Notice title when the port check service did not answer.
  ///
  /// In en, this message translates to:
  /// **'Reachability unknown'**
  String get deskKitReachUnknownTitle;

  /// Notice text under 'Reachability unknown'.
  ///
  /// In en, this message translates to:
  /// **'The port check did not answer. Try again later.'**
  String get deskKitReachUnknownText;

  /// Same, plus the computer's address on the local network.
  ///
  /// In en, this message translates to:
  /// **'The port check did not answer. Try again later. On your network: {address}.'**
  String deskKitReachUnknownTextLan(String address);

  /// Notice title when the HTTP port is reachable from outside.
  ///
  /// In en, this message translates to:
  /// **'Reachable from the internet'**
  String get deskKitReachOpenTitle;

  /// Notice text under 'Reachable from the internet'.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is forwarded.'**
  String deskKitReachOpenText(String port);

  /// Same, plus the computer's address on the local network.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is forwarded. On your network: {address}.'**
  String deskKitReachOpenTextLan(String port, String address);

  /// How long ago something happened, in seconds, e.g. '40 s ago'. Abbreviate the unit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} s ago} other{{count} s ago}}'**
  String deskKitAgeSeconds(int count);

  /// How long ago something happened, in minutes, e.g. '2 min ago'. Abbreviate the unit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min ago} other{{count} min ago}}'**
  String deskKitAgeMinutes(int count);

  /// How long ago something happened, in hours, e.g. '3 h ago'. Abbreviate the unit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} h ago} other{{count} h ago}}'**
  String deskKitAgeHours(int count);

  /// How long ago something happened, in days, e.g. '2 d ago'. Abbreviate the unit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} d ago} other{{count} d ago}}'**
  String deskKitAgeDays(int count);

  /// Small note under 'Accepts transactions' when the node runs a version older than 4.1.0 that cannot tell. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'node before 4.1.0'**
  String get deskKitNodeBefore410;

  /// Small note under a node fact when the node did not answer. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'no answer'**
  String get deskKitNodeNoAnswer;

  /// Part of the network line of the node card: the public nodes report different latest blocks.
  ///
  /// In en, this message translates to:
  /// **'Nodes disagree on the tip'**
  String get deskKitNodesDisagree;

  /// Part of the network line of the node card: all nodes agree on this block height. {height} is a number with thousands separators.
  ///
  /// In en, this message translates to:
  /// **'Nodes agree on {height}'**
  String deskKitNodesAgree(String height);

  /// Part of the network line of the node card, e.g. '5 of 6 nodes up'.
  ///
  /// In en, this message translates to:
  /// **'{up, plural, one{{up} of {total} node up} other{{up} of {total} nodes up}}'**
  String deskKitNodesUp(int up, int total);

  /// Part of the network line of the node card, e.g. '3 of 4 Epicbox servers up'.
  ///
  /// In en, this message translates to:
  /// **'{up, plural, one{{up} of {total} Epicbox server up} other{{up} of {total} Epicbox servers up}}'**
  String deskKitEpicboxUp(int up, int total);

  /// Part of the network line of the node card and a note under Height: how long ago the last block was found. {age} is e.g. '2 min ago'.
  ///
  /// In en, this message translates to:
  /// **'last block {age}'**
  String deskKitLastBlock(String age);

  /// Line on the node card when the status website cannot be reached and only the node itself answered.
  ///
  /// In en, this message translates to:
  /// **'status.btlabs.uk is not reachable. These facts come from the node itself: no tip to compare with, no uptime, no peer count.'**
  String get deskKitLimitedNetwork;

  /// Label of a fact on the node card: the node's block height. One short word.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get deskKitFactHeight;

  /// Label of a fact on the node card: the node's software version. One short word.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get deskKitFactVersion;

  /// Label of a fact on the node card: whether the node is ready to take new transactions. Narrow: at most about 22 characters.
  ///
  /// In en, this message translates to:
  /// **'Accepts transactions'**
  String get deskKitFactAccepts;

  /// Value of the 'Accepts transactions' fact. One short word.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get deskKitFactYes;

  /// Value of the 'Accepts transactions' fact: the node is not ready yet. Short.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get deskKitFactNotYet;

  /// Value of the 'Accepts transactions' fact when it could not be learned. One short word.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get deskKitFactUnknown;

  /// Label of a fact on the node card: the time the node takes to answer. One short word.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get deskKitFactLatency;

  /// Label of a fact on the node card: how much of the time the node was up. One short word.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get deskKitFactUptime;

  /// Label of a fact on the node card: the number of other nodes it is connected to. One short word.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get deskKitFactPeers;

  /// Label of a fact on the node card: who runs the node. One short word.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get deskKitFactOperator;

  /// Small note under Height: the node is on the latest block. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'at tip'**
  String get deskKitAtTip;

  /// Small note under Height: the node is this many blocks behind. {blocks} is the number with thousands separators; {count} is the same number for grammar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{blocks} behind} other{{blocks} behind}}'**
  String deskKitBehind(int count, String blocks);

  /// Small note under Version: a newer version is released. {version} is the version number.
  ///
  /// In en, this message translates to:
  /// **'{version} is out'**
  String deskKitVersionOut(String version);

  /// Small note under Version: the node runs the newest version. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'latest'**
  String get deskKitVersionLatest;

  /// Small note under Uptime: the figure covers the last 24 hours. Short.
  ///
  /// In en, this message translates to:
  /// **'last 24 h'**
  String get deskKitUptimeWindow;

  /// Small note under Peers on a down node: the time it was last seen, e.g. 'at 14:05'.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String deskKitAtTime(String time);

  /// Small note under Operator: the node is on the official list. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'listed as official'**
  String get deskKitListedOfficial;

  /// Source line of the node card: the status site and when it was last asked. {time} is e.g. 14:05.
  ///
  /// In en, this message translates to:
  /// **'status.btlabs.uk, checked {time}'**
  String deskKitSourceChecked(String time);

  /// Source line of the node card. {where} is 'from this computer', 'over Tor' or 'from status.btlabs.uk'.
  ///
  /// In en, this message translates to:
  /// **'latency measured {where}'**
  String deskKitLatencyMeasured(String where);

  /// Source line of the node card when the status site is not reachable now. {time} is e.g. 14:05.
  ///
  /// In en, this message translates to:
  /// **'Status site last reached {time}'**
  String deskKitSiteLastReached(String time);

  /// Part of the node card's header when the node is down: since when, e.g. 'since 14:05'.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String deskKitSince(String time);

  /// Screen-reader label of the node card. {status} is a status word such as Synced.
  ///
  /// In en, this message translates to:
  /// **'Node {status}: {host}'**
  String deskKitNodeSemantics(String status, String host);

  /// Title of the notice on the node card when the node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Node not answering.'**
  String get deskKitNodeDownTitle;

  /// Text of the notice on the node card offering to use another node. {host} is a host name.
  ///
  /// In en, this message translates to:
  /// **'Switch to {host}, the healthiest other node?'**
  String deskKitNodeDownText(String host);

  /// Button of the node-down notice: switch to the suggested node. One word.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get deskKitSwitch;

  /// Small warning tag on the node card: only some facts are known.
  ///
  /// In en, this message translates to:
  /// **'Limited info'**
  String get deskKitLimitedInfo;

  /// Small note under Latency: measured by the status website.
  ///
  /// In en, this message translates to:
  /// **'from status.btlabs.uk'**
  String get deskKitFromStatusSite;

  /// Small note under Latency: measured through Tor.
  ///
  /// In en, this message translates to:
  /// **'over Tor'**
  String get deskKitOverTor;

  /// Small note under Latency: measured from this computer.
  ///
  /// In en, this message translates to:
  /// **'from this computer'**
  String get deskKitFromThisComputer;

  /// Tooltip and screen-reader label of the filled star on a node row: remove the node from the user's own list. {host} is a host name.
  ///
  /// In en, this message translates to:
  /// **'Remove {host} from my nodes'**
  String deskKitNodeRemove(String host);

  /// Tooltip and screen-reader label of the empty star on a node row: add the node to the user's own list. {host} is a host name.
  ///
  /// In en, this message translates to:
  /// **'Add {host} to my nodes'**
  String deskKitNodeAdd(String host);

  /// Screen-reader label of a node row in the node list: pick this node.
  ///
  /// In en, this message translates to:
  /// **'Use {host}'**
  String deskKitNodeUse(String host);

  /// Screen-reader label of a node row: pick this node; {operator} is who runs it.
  ///
  /// In en, this message translates to:
  /// **'Use {host}, {operator}'**
  String deskKitNodeUseOperator(String host, String operator);

  /// Screen-reader label of a node row whose node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Use {host}, not answering'**
  String deskKitNodeUseDown(String host);

  /// Screen-reader label of a node row whose node does not answer; {operator} is who runs it.
  ///
  /// In en, this message translates to:
  /// **'Use {host}, {operator}, not answering'**
  String deskKitNodeUseOperatorDown(String host, String operator);

  /// Screen-reader label of the 'Local node' row of the node list. {state} is its state, e.g. Synced.
  ///
  /// In en, this message translates to:
  /// **'Use the local node, {state}'**
  String deskKitLocalNodeUse(String state);

  /// Name of the row in the node list that stands for the node running on this computer.
  ///
  /// In en, this message translates to:
  /// **'Local node'**
  String get deskKitLocalNode;

  /// Bold status word of the Epicbox line (Receive, Settings › Receiving): waits until Tor is connected.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Tor'**
  String get deskKitMethodWaitingTor;

  /// Detail of the Epicbox status line when Epicbox must go through Tor but Tor is not connected. {host} is the Epicbox server.
  ///
  /// In en, this message translates to:
  /// **'{host}. Tor is not connected.'**
  String deskKitMethodTorNotConnected(String host);

  /// Bold status word of a receiving method line: working. One short word.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get deskKitMethodOn;

  /// Detail of the Epicbox status line: the connection goes through Tor. {host} is the Epicbox server.
  ///
  /// In en, this message translates to:
  /// **'{host}, over Tor'**
  String deskKitMethodOverTor(String host);

  /// Bold status word of a receiving method line: turned off. One short word.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskKitMethodOff;

  /// Detail of the Epicbox status line when Epicbox is off.
  ///
  /// In en, this message translates to:
  /// **'Payments to this address wait on the Epicbox server.'**
  String get deskKitMethodEpicboxOffDetail;

  /// Bold status word of the Epicbox status line: connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get deskKitMethodConnecting;

  /// Bold status word of the Epicbox status line: the server answers slowly.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get deskKitMethodSlow;

  /// Bold status word of the Epicbox status line: the server does not answer.
  ///
  /// In en, this message translates to:
  /// **'Not answering'**
  String get deskKitMethodNotAnswering;

  /// Detail of the Epicbox status line when the server does not answer. {host} is the Epicbox server.
  ///
  /// In en, this message translates to:
  /// **'{host}. Payments wait on the Epicbox server.'**
  String deskKitMethodEpicboxDown(String host);

  /// Detail of the HTTP status line when HTTP is off: how HTTP payments work.
  ///
  /// In en, this message translates to:
  /// **'Straight from another wallet while this one is open.'**
  String get deskKitMethodHttpOffDetail;

  /// Bold status word of the HTTP status line: the listener is starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get deskKitMethodStarting;

  /// Detail of the HTTP status line: reachable from the internet on this port.
  ///
  /// In en, this message translates to:
  /// **'from the internet, port {port}'**
  String deskKitMethodHttpInternet(String port);

  /// Detail of the HTTP status line: reachable from this computer only. Keep the address 127.0.0.1.
  ///
  /// In en, this message translates to:
  /// **'this computer only (127.0.0.1)'**
  String get deskKitMethodHttpLocal;

  /// Bold status word of the HTTP status line: the listener failed.
  ///
  /// In en, this message translates to:
  /// **'Not receiving'**
  String get deskKitMethodNotReceiving;

  /// Detail of the HTTP status line when the port is taken.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is used by another program. Close it or pick another port in Settings.'**
  String deskKitMethodPortInUse(String port);

  /// Bold status word of the Tor status line when this build has no Tor.
  ///
  /// In en, this message translates to:
  /// **'Not in this build'**
  String get deskKitMethodNotInBuild;

  /// Detail of the Tor status line when Tor is off: what Tor means for the user.
  ///
  /// In en, this message translates to:
  /// **'Slower and more private. Blocked or not allowed in some countries.'**
  String get deskKitMethodTorOffDetail;

  /// Bold status word of the Tor status line: Tor is up and the address is being published.
  ///
  /// In en, this message translates to:
  /// **'Publishing the Tor address…'**
  String get deskKitMethodTorPublishing;

  /// Bold status word of the Tor status line while Tor connects; the detail is a percentage.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Tor…'**
  String get deskKitMethodTorConnecting;

  /// Detail of the Tor status line when Tor works.
  ///
  /// In en, this message translates to:
  /// **'reachable at the Tor address'**
  String get deskKitMethodTorOnDetail;

  /// Bold status word of the Tor status line: Tor runs but the receiving address is not published yet.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get deskKitMethodTorNotPublished;

  /// Detail of the Tor status line: {reason} is a short reason; sending still works.
  ///
  /// In en, this message translates to:
  /// **'{reason}. Sends work.'**
  String deskKitMethodTorSendsWork(String reason);

  /// Default reason inside the Tor status line when the core gave none.
  ///
  /// In en, this message translates to:
  /// **'The Tor address is not reachable yet'**
  String get deskKitMethodTorNotReachableYet;

  /// Bold status word of the Tor status line: Tor stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deskKitMethodTorStopped;

  /// Detail of the Tor status line when Tor stopped and the core gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Tor stopped.'**
  String get deskKitMethodTorStoppedDetail;

  /// Bold status word of the transaction-file method line (no state).
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get deskKitMethodFiles;

  /// Small chip on the Send and Receive pages: this method goes through Tor. Narrow chip: 2 short words.
  ///
  /// In en, this message translates to:
  /// **'Over Tor'**
  String get deskKitChipOverTor;

  /// Small chip: Tor is still starting. Narrow chip.
  ///
  /// In en, this message translates to:
  /// **'Tor starting'**
  String get deskKitChipStarting;

  /// Small chip: Tor should be used but is not connected. Narrow chip.
  ///
  /// In en, this message translates to:
  /// **'Tor not connected'**
  String get deskKitChipNotConnected;

  /// Small chip: this method does not go through Tor. Narrow chip.
  ///
  /// In en, this message translates to:
  /// **'Not over Tor'**
  String get deskKitChipNotOverTor;

  /// Tooltip behind the info icon under a new-password field: how the 'time to crack' is estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated on this device from the length and from common words, names and patterns, for an attacker with fast hardware trying 100,000 guesses a second against this wallet\'s file. A guide, not a guarantee.'**
  String get deskKitPasswordNote;

  /// Screen-reader name of the info icon under a new-password field.
  ///
  /// In en, this message translates to:
  /// **'How the time is estimated'**
  String get deskKitPasswordNoteLabel;

  /// Brief label of a copy button when the clipboard refused the text. Short.
  ///
  /// In en, this message translates to:
  /// **'Not copied'**
  String get deskKitNotCopied;

  /// Brief label of a copy button for 1.5 seconds after a successful copy. Short.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get deskKitCopied;

  /// Caption and screen-reader label of a QR code. {title} is the name of what it holds, e.g. 'Epicbox address' (lowercase in the sentence).
  ///
  /// In en, this message translates to:
  /// **'QR code of the {title}'**
  String deskKitQrOf(String title);

  /// Screen-reader label of a QR code with a note. {title} is the name of what it holds; {tag} a short lowercase note.
  ///
  /// In en, this message translates to:
  /// **'QR code of the {title}, {tag}'**
  String deskKitQrOfTag(String title, String tag);

  /// Screen-reader label of the button that reveals a QR code. {title} is what it holds.
  ///
  /// In en, this message translates to:
  /// **'Show QR code of the {title}'**
  String deskKitQrShowOf(String title);

  /// Button and tooltip: reveal the hidden QR code. Short.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get deskKitQrShow;

  /// Button and tooltip: hide the QR code again. Short.
  ///
  /// In en, this message translates to:
  /// **'Hide QR'**
  String get deskKitQrHide;

  /// Screen-reader label of the button that hides the QR code.
  ///
  /// In en, this message translates to:
  /// **'Hide QR code'**
  String get deskKitQrHideCode;

  /// Toast title when forgetting the remembered password failed.
  ///
  /// In en, this message translates to:
  /// **'Not forgotten'**
  String get deskSetAcctNotForgotten;

  /// Toast title after the remembered password was forgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgotten on this computer'**
  String get deskSetAcctForgotten;

  /// Toast text after the remembered password was forgotten.
  ///
  /// In en, this message translates to:
  /// **'The next start asks the password.'**
  String get deskSetAcctForgottenText;

  /// Toast title when the wallet label could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Label not saved'**
  String get deskSetAcctLabelNotSaved;

  /// Toast text when the wallet label is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a label'**
  String get deskSetAcctEnterLabel;

  /// Toast title after the wallet label was saved. The label follows as text.
  ///
  /// In en, this message translates to:
  /// **'Label saved'**
  String get deskSetAcctLabelSaved;

  /// Settings > This wallet: row title and screen reader name of the wallet label field.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get deskSetAcctLabel;

  /// Settings > This wallet: hint under the Label row.
  ///
  /// In en, this message translates to:
  /// **'Only shown in this app.'**
  String get deskSetAcctLabelHint;

  /// Tooltip and screen reader label of the check button in the label field.
  ///
  /// In en, this message translates to:
  /// **'Save label'**
  String get deskSetAcctSaveLabel;

  /// Settings > This wallet: hint under the Recovery phrase row.
  ///
  /// In en, this message translates to:
  /// **'The words that restore this wallet. Keep them private.'**
  String get deskSetAcctPhraseHint;

  /// Settings > This wallet: button that opens the recovery phrase page.
  ///
  /// In en, this message translates to:
  /// **'Show phrase…'**
  String get deskSetAcctShowPhrase;

  /// Settings > This wallet: hint under the Recheck balance row.
  ///
  /// In en, this message translates to:
  /// **'Reads the chain again when the balance looks wrong.'**
  String get deskSetAcctRescanHint;

  /// Settings > This wallet: button that opens the Recheck balance page.
  ///
  /// In en, this message translates to:
  /// **'Recheck…'**
  String get deskSetAcctRecheck;

  /// Settings > This wallet: title of the group of folder rows.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get deskSetAcctFiles;

  /// Settings > This wallet: row title for the folder holding this wallet’s files.
  ///
  /// In en, this message translates to:
  /// **'Wallet folder'**
  String get deskSetAcctWalletFolder;

  /// Settings > This wallet: row title for the folder holding the app’s files.
  ///
  /// In en, this message translates to:
  /// **'App files'**
  String get deskSetAcctAppFiles;

  /// Settings > This wallet: hint under the App files row.
  ///
  /// In en, this message translates to:
  /// **'Settings and the log.'**
  String get deskSetAcctAppFilesHint;

  /// Settings > This wallet: row title showing which network (e.g. Floonet) the wallet belongs to. Shown only when it is not Mainnet.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get deskSetAcctNetwork;

  /// Settings > This wallet: hint under the Network row.
  ///
  /// In en, this message translates to:
  /// **'Set when the wallet was created.'**
  String get deskSetAcctNetworkHint;

  /// Settings > This wallet: row title for the first-run setup assistant.
  ///
  /// In en, this message translates to:
  /// **'Setup assistant'**
  String get deskSetAcctSetup;

  /// Settings > This wallet: hint under the Setup assistant row.
  ///
  /// In en, this message translates to:
  /// **'Walk through node and receiving again. Nothing is lost.'**
  String get deskSetAcctSetupHint;

  /// Settings > This wallet: button that opens the setup assistant.
  ///
  /// In en, this message translates to:
  /// **'Run setup…'**
  String get deskSetAcctRunSetup;

  /// Settings > This wallet: title of the group with password and delete rows.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get deskSetAcctSecurity;

  /// Settings > This wallet: row title shown when the wallet opens without a password.
  ///
  /// In en, this message translates to:
  /// **'Remembered on this computer'**
  String get deskSetAcctRemembered;

  /// Settings > This wallet: hint under the Remembered row. {who} is another sentence about who can open the wallet, supplied by the app in English.
  ///
  /// In en, this message translates to:
  /// **'Opens at start without the password, for 30 days from when it was set. Sends still ask the password. {who}'**
  String deskSetAcctRememberedHint(String who);

  /// Settings > This wallet: button that forgets the remembered password.
  ///
  /// In en, this message translates to:
  /// **'Forget this computer'**
  String get deskSetAcctForget;

  /// Settings > This wallet: hint under the Password row.
  ///
  /// In en, this message translates to:
  /// **'Unlocks this wallet.'**
  String get deskSetAcctPasswordHint;

  /// Settings > This wallet: button that opens the change password dialog.
  ///
  /// In en, this message translates to:
  /// **'Change password…'**
  String get deskSetAcctChangePassword;

  /// Settings > This wallet: hint under the Delete wallet row.
  ///
  /// In en, this message translates to:
  /// **'Deletes its keys and database.'**
  String get deskSetAcctDeleteHint;

  /// Toast title when a folder does not exist on disk. The path follows as text.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get deskSetAcctFolderNotFound;

  /// Tooltip and screen reader label of the copy button of a folder row. {title} is the row title, e.g. "Wallet folder".
  ///
  /// In en, this message translates to:
  /// **'Copy path: {title}'**
  String deskSetAcctCopyPath(String title);

  /// Settings > Backup: when the last export was, when it was today. {time} is a clock time like 14:02. Part of a longer line; keep lowercase.
  ///
  /// In en, this message translates to:
  /// **'today, {time}'**
  String deskSetBackupWhenToday(String time);

  /// Settings > Backup: when the last export was, when it was yesterday. {time} is a clock time like 09:10. Part of a longer line; keep lowercase.
  ///
  /// In en, this message translates to:
  /// **'yesterday, {time}'**
  String deskSetBackupWhenYesterday(String time);

  /// Settings > Backup: date and time of the last export, e.g. "3 Oct 2026, 14:02".
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String deskSetBackupWhenDate(String day, String time);

  /// Settings > Backup: line under Export history backup when nothing was ever exported.
  ///
  /// In en, this message translates to:
  /// **'Never exported.'**
  String get deskSetBackupNeverExported;

  /// Settings > Backup: line under Export history backup. {when} is a date such as "today, 14:02".
  ///
  /// In en, this message translates to:
  /// **'Last export {when} · nothing new since.'**
  String deskSetBackupLastExportNothingNew(String when);

  /// Settings > Backup: line under Export history backup. {when} is a date such as "today, 14:02"; count is how many payments are not in that backup.
  ///
  /// In en, this message translates to:
  /// **'Last export {when} · {count, plural, one{1 payment since} other{{count} payments since}}.'**
  String deskSetBackupLastExportSince(String when, int count);

  /// Error in the Export dialogs when the file could not be saved and the system did not say where. {reason} is the system message.
  ///
  /// In en, this message translates to:
  /// **'Could not write to the folder: {reason}. Choose another folder.'**
  String deskSetBackupWriteFailedHere(String reason);

  /// Error in the Export dialogs when the file could not be saved. {folder} is a path; {reason} is the system message.
  ///
  /// In en, this message translates to:
  /// **'Could not write to {folder}: {reason}. Choose another folder.'**
  String deskSetBackupWriteFailedIn(String folder, String reason);

  /// Error in the Export dialogs when the file could not be saved, reason unknown.
  ///
  /// In en, this message translates to:
  /// **'The file could not be written. Choose another folder.'**
  String get deskSetBackupWriteFailed;

  /// Settings > This wallet: title of the Backup group of rows.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get deskSetBackupGroup;

  /// Settings > Backup: row title, dialog title and the reminder button for exporting the history backup file.
  ///
  /// In en, this message translates to:
  /// **'Export history backup'**
  String get deskSetBackupExportTitle;

  /// Settings > Backup: hint under the Export history backup row.
  ///
  /// In en, this message translates to:
  /// **'Payments with their details and contacts, in a file only a wallet with this recovery phrase opens. The phrase alone brings back the balance, not the records.'**
  String get deskSetBackupExportHint;

  /// Settings > Backup: button label while the export dialog is open. Short.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get deskSetBackupExporting;

  /// Settings > Backup: button that opens the export dialog. Short; the dots mean a dialog follows.
  ///
  /// In en, this message translates to:
  /// **'Export…'**
  String get deskSetBackupExportButton;

  /// Settings > Backup: row title and dialog title for importing a history backup file.
  ///
  /// In en, this message translates to:
  /// **'Import history backup'**
  String get deskSetBackupImportTitle;

  /// Settings > Backup: hint under the Import history backup row.
  ///
  /// In en, this message translates to:
  /// **'Merges a backup of this wallet into Activity. Nothing is removed; the same file twice changes nothing.'**
  String get deskSetBackupImportHint;

  /// Settings > Backup: button that opens the import dialog. Short.
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get deskSetBackupImportButton;

  /// Settings > Backup: row title for exporting payments as a spreadsheet file.
  ///
  /// In en, this message translates to:
  /// **'Payments as CSV'**
  String get deskSetBackupCsvTitle;

  /// Settings > Backup: hint under the Payments as CSV row.
  ///
  /// In en, this message translates to:
  /// **'A plain table for spreadsheets. Not encrypted, not importable.'**
  String get deskSetBackupCsvHint;

  /// Settings > Backup: button that opens the CSV export dialog. Short.
  ///
  /// In en, this message translates to:
  /// **'Export CSV…'**
  String get deskSetBackupCsvButton;

  /// Title of the system Save dialog when exporting the history backup.
  ///
  /// In en, this message translates to:
  /// **'Save payment history'**
  String get deskSetBackupSaveDialogTitle;

  /// Export dialogs: title of the error notice when the file could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get deskSetBackupNotSaved;

  /// Export history dialog: label of the row listing what the file holds. Narrow label column (about 100 px).
  ///
  /// In en, this message translates to:
  /// **'In the file'**
  String get deskSetBackupInFile;

  /// Export history dialog: what the file holds, e.g. "12 payments, 3 contacts".
  ///
  /// In en, this message translates to:
  /// **'{payments, plural, one{1 payment} other{{payments} payments}}, {contacts, plural, one{1 contact} other{{contacts} contacts}}'**
  String deskSetBackupInFileCounts(int payments, int contacts);

  /// Export history dialog: small text under the counts of what the file holds.
  ///
  /// In en, this message translates to:
  /// **'Who paid what, fees, notes, slate ids'**
  String get deskSetBackupInFileSub;

  /// Export history dialog: label of the row listing what the file does not hold. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Not in it'**
  String get deskSetBackupNotIn;

  /// Export history dialog: what the file does not contain.
  ///
  /// In en, this message translates to:
  /// **'Keys, the recovery phrase, the password'**
  String get deskSetBackupNotInValue;

  /// Export history dialog: label of the row saying which wallet can open the file. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Opens with'**
  String get deskSetBackupOpensWith;

  /// Export history dialog: which wallets can open the file.
  ///
  /// In en, this message translates to:
  /// **'This wallet, or one restored from its phrase'**
  String get deskSetBackupOpensWithValue;

  /// Export dialog: label of the row with the file name. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskSetBackupFile;

  /// Export history dialog: note under the list.
  ///
  /// In en, this message translates to:
  /// **'The file holds payments up to now. Export again after new payments.'**
  String get deskSetBackupFileNote;

  /// Export history dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'A file with this wallet’s payments, their details and contacts. Only a wallet with the same recovery phrase opens it.'**
  String get deskSetBackupExportDesc;

  /// Export dialogs: title of the success block once the file is saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get deskSetBackupSaved;

  /// Export history dialog: advice shown after saving.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy off this computer too: a USB stick, another drive, or cloud storage. Export again after new payments.'**
  String get deskSetBackupKeepCopy;

  /// Export dialogs: button that opens the folder of the saved file.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get deskSetBackupOpenFolder;

  /// Export dialogs: save button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get deskSetBackupSaving;

  /// Export dialogs: save button label after a failed save.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deskSetBackupTryAgain;

  /// Export dialogs: button that opens the system Save dialog.
  ///
  /// In en, this message translates to:
  /// **'Save as…'**
  String get deskSetBackupSaveAs;

  /// Title of the system Open dialog when importing a history backup.
  ///
  /// In en, this message translates to:
  /// **'Open history backup'**
  String get deskSetBackupOpenDialogTitle;

  /// Import result tile title: count of payments that got details back.
  ///
  /// In en, this message translates to:
  /// **'Details restored'**
  String get deskSetBackupDetailsRestored;

  /// Import result tile text under "Details restored".
  ///
  /// In en, this message translates to:
  /// **'Payments already here got their counterparty, fee or note back'**
  String get deskSetBackupDetailsRestoredSub;

  /// Import result tile title: count of payments added from the backup.
  ///
  /// In en, this message translates to:
  /// **'Older payments added'**
  String get deskSetBackupOlderAdded;

  /// Import result tile text under "Older payments added". "From backup" is a label shown in Activity.
  ///
  /// In en, this message translates to:
  /// **'Not in the list any more; shown as From backup'**
  String get deskSetBackupOlderAddedSub;

  /// Import result tile title: count of contacts added.
  ///
  /// In en, this message translates to:
  /// **'Contacts added'**
  String get deskSetBackupContactsAdded;

  /// Import result tile title: count of records that were already in the wallet.
  ///
  /// In en, this message translates to:
  /// **'Already here'**
  String get deskSetBackupAlreadyHere;

  /// Import result tile text under "Already here".
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get deskSetBackupUnchanged;

  /// Import dialog: title of the success block when the file brought nothing new.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get deskSetBackupNothingNew;

  /// Import dialog: text of the "Nothing new" block. {file} is the file name, shown in monospace.
  ///
  /// In en, this message translates to:
  /// **'Every record in {file} was already here.'**
  String deskSetBackupNothingNewBody(String file);

  /// Import dialog: title of the success block.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get deskSetBackupImported;

  /// Import dialog: shown while the chosen file is read. {file} is the file name, shown in monospace.
  ///
  /// In en, this message translates to:
  /// **'Reading {file}…'**
  String deskSetBackupReading(String file);

  /// Import dialog: title of the error notice when the import failed.
  ///
  /// In en, this message translates to:
  /// **'Not imported'**
  String get deskSetBackupNotImported;

  /// Import dialog: label of the row saying what the import restores. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Brings back'**
  String get deskSetBackupBringsBack;

  /// Import dialog: what the import restores.
  ///
  /// In en, this message translates to:
  /// **'Who paid what, fees and notes of payments already here; older payments the list lost; contacts'**
  String get deskSetBackupBringsBackValue;

  /// Import dialog: label of the row saying what file is needed. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get deskSetBackupNeeds;

  /// Import dialog: what file the import needs. {network} is the network name, e.g. "Mainnet".
  ///
  /// In en, this message translates to:
  /// **'A file from this wallet (the same recovery phrase), on {network}'**
  String deskSetBackupNeedsValue(String network);

  /// Import dialog: label of the row saying what the import never does. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get deskSetBackupNever;

  /// Import dialog: what the import never does (continues the label "Never").
  ///
  /// In en, this message translates to:
  /// **'Removes or changes a payment that is here'**
  String get deskSetBackupNeverValue;

  /// Import dialog: button that opens the system Open dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose file…'**
  String get deskSetBackupChooseFile;

  /// Import history dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'Merges a history backup of this wallet into Activity. Nothing is removed, and the same file twice changes nothing.'**
  String get deskSetBackupImportDesc;

  /// Title of the system Save dialog when exporting the CSV.
  ///
  /// In en, this message translates to:
  /// **'Save payments as CSV'**
  String get deskSetBackupSaveCsvDialogTitle;

  /// Export CSV dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get deskSetBackupCsvDialogTitle;

  /// Export CSV dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'A plain table of this wallet’s payments, for spreadsheets.'**
  String get deskSetBackupCsvDialogDesc;

  /// Export CSV dialog: note after saving.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 payment} other{{count} payments}}, newest first. Amounts in EPIC with 8 decimals; dates in UTC.'**
  String deskSetBackupCsvSavedNote(int count);

  /// Export CSV dialog: error under a custom date field that is not a valid date. Keep the year-month-day format shown.
  ///
  /// In en, this message translates to:
  /// **'Enter a date as 2026-01-31'**
  String get deskSetBackupDateError;

  /// Export CSV dialog: placeholder of the custom date fields.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get deskSetBackupDateHint;

  /// Export CSV dialog: label of the segmented control choosing which payments to export.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get deskSetBackupRange;

  /// Export CSV dialog: segment, all payments. Four segments share a narrow row; keep short.
  ///
  /// In en, this message translates to:
  /// **'All payments'**
  String get deskSetBackupRangeAll;

  /// Export CSV dialog: segment, payments of this calendar year. Keep short.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get deskSetBackupRangeThisYear;

  /// Export CSV dialog: segment, payments of last calendar year. Keep short.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get deskSetBackupRangeLastYear;

  /// Export CSV dialog: segment, choose own dates. Keep short.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get deskSetBackupRangeCustom;

  /// Export CSV dialog: label of the first custom date field.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get deskSetBackupFrom;

  /// Export CSV dialog: label of the last custom date field.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get deskSetBackupTo;

  /// Export CSV dialog: summary line. {file} is the file name, shown in monospace. The columns named are in the file, whose headers stay English.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 payment} other{{count} payments}} · columns: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. File {file}.'**
  String deskSetBackupCsvInfo(int count, String file);

  /// Export CSV dialog: summary line while the date range is not valid, so there is no count. {file} is the file name.
  ///
  /// In en, this message translates to:
  /// **'– · columns: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. File {file}.'**
  String deskSetBackupCsvInfoNoCount(String file);

  /// Export CSV dialog: title of the warning notice.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted.'**
  String get deskSetBackupNotEncrypted;

  /// Export CSV dialog: text of the warning notice.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the file reads amounts, dates, addresses and notes. It cannot be imported; the history backup is for that.'**
  String get deskSetBackupNotEncryptedBody;

  /// Reminder on Overview when the history was never backed up. Count is the number of payments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 payment is not in a history backup.} other{{count} payments are not in a history backup.}}'**
  String deskSetBackupReminderNever(int count);

  /// Reminder on Overview when payments changed since the last history backup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 payment is new or changed since the last history backup.} other{{count} payments are new or changed since the last history backup.}}'**
  String deskSetBackupReminderChanged(int count);

  /// Reminder on Overview: text under the title.
  ///
  /// In en, this message translates to:
  /// **'A restore from the recovery phrase brings back the balance, not who paid what.'**
  String get deskSetBackupReminderBody;

  /// Reminder on Overview: button that dismisses the reminder. Small inline button.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get deskSetBackupNotNow;

  /// Add or edit node dialog: error under the address field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the node’s address.'**
  String get deskSetDlgNodeAddressEmpty;

  /// Add or edit node dialog: error under the address field when the text is not a node address.
  ///
  /// In en, this message translates to:
  /// **'Not a node address. Check the address and the port (usually 3413).'**
  String get deskSetDlgNodeAddressBad;

  /// Add or edit node dialog: error when the address is already saved. "My nodes" is the list of own nodes in Settings > Node.
  ///
  /// In en, this message translates to:
  /// **'This address is already in My nodes.'**
  String get deskSetDlgNodeAddressDuplicate;

  /// Toast title when saving a node failed; the reason follows as the toast text.
  ///
  /// In en, this message translates to:
  /// **'Node not added'**
  String get deskSetDlgNodeNotAdded;

  /// Toast title after an edited node was saved.
  ///
  /// In en, this message translates to:
  /// **'Node saved'**
  String get deskSetDlgNodeSaved;

  /// Toast title after a node was added to the own-nodes list.
  ///
  /// In en, this message translates to:
  /// **'Added to my nodes'**
  String get deskSetDlgNodeAdded;

  /// Add node dialog: shown next to the check result when the node does not respond.
  ///
  /// In en, this message translates to:
  /// **'It can be saved anyway.'**
  String get deskSetDlgNodeSaveAnyway;

  /// Title of the dialog for editing a saved node.
  ///
  /// In en, this message translates to:
  /// **'Edit node'**
  String get deskSetDlgNodeEditTitle;

  /// Title of the dialog for adding a node to the own-nodes list; also the matching button.
  ///
  /// In en, this message translates to:
  /// **'Add to my nodes'**
  String get deskSetDlgNodeAddTitle;

  /// Add or edit node dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'Save a node address to find it again later. It can be saved while it is offline.'**
  String get deskSetDlgNodeDesc;

  /// Add or edit node dialog: label and screen reader name of the address field.
  ///
  /// In en, this message translates to:
  /// **'Node address'**
  String get deskSetDlgNodeAddress;

  /// Add or edit node dialog: label and screen reader name of the optional name field.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get deskSetDlgNodeLabel;

  /// Add or edit node dialog: placeholder of the label field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home node'**
  String get deskSetDlgNodeLabelHint;

  /// Title of the dialog listing public nodes.
  ///
  /// In en, this message translates to:
  /// **'Node directory'**
  String get deskSetDlgDirTitle;

  /// Node directory dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'Public nodes, their operators and their state at the last check.'**
  String get deskSetDlgDirDesc;

  /// Node directory dialog: empty state.
  ///
  /// In en, this message translates to:
  /// **'No nodes to show'**
  String get deskSetDlgDirEmpty;

  /// Node directory: a node’s software version in a small detail line, e.g. "version 4.1.0". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'version {version}'**
  String deskSetDlgDirVersion(String version);

  /// Node directory: a node’s block height in a small detail line, e.g. "height 2,914,414". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'height {height}'**
  String deskSetDlgDirHeight(String height);

  /// Node directory: tag on the node the wallet uses now. Short.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get deskSetDlgDirInUse;

  /// Node directory: button that switches to that node. Short.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get deskSetDlgDirUse;

  /// Node directory dialog: note under the list.
  ///
  /// In en, this message translates to:
  /// **'Response times are measured from the status site, not from this computer.'**
  String get deskSetDlgDirNote;

  /// Title of the dialog offering to reuse blockchain data already on this computer.
  ///
  /// In en, this message translates to:
  /// **'Existing blockchain data found'**
  String get deskSetDlgChainTitle;

  /// Existing blockchain data dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'This computer already has Epic blockchain data that the local node can use.'**
  String get deskSetDlgChainDesc;

  /// Existing blockchain data dialog: fact label for the folder. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get deskSetDlgChainFolder;

  /// Existing blockchain data dialog: fact label for the data size. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get deskSetDlgChainSize;

  /// Existing blockchain data dialog: fact label for when the data was last changed. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get deskSetDlgChainUpdated;

  /// Existing blockchain data dialog: sample value of Last updated.
  ///
  /// In en, this message translates to:
  /// **'3 days ago'**
  String get deskSetDlgChainUpdatedValue;

  /// Existing blockchain data dialog: note that another copy exists.
  ///
  /// In en, this message translates to:
  /// **'Other copies were found too (1). This one was updated most recently.'**
  String get deskSetDlgChainOthers;

  /// Existing blockchain data dialog: question line when the folder is locked by another program.
  ///
  /// In en, this message translates to:
  /// **'Another Epic program is using this folder. Close it, then pick the local node again to use this data.'**
  String get deskSetDlgChainInUse;

  /// Existing blockchain data dialog: question line.
  ///
  /// In en, this message translates to:
  /// **'Use it? That saves downloading and syncing the whole blockchain.'**
  String get deskSetDlgChainUseIt;

  /// Existing blockchain data dialog: small note under the question.
  ///
  /// In en, this message translates to:
  /// **'An older Epic Wallet that uses this folder may need to sync again after this. Coins are not affected.'**
  String get deskSetDlgChainOlderWallet;

  /// Existing blockchain data dialog: button to ignore the old data and download anew.
  ///
  /// In en, this message translates to:
  /// **'Download fresh'**
  String get deskSetDlgChainFresh;

  /// Existing blockchain data dialog: primary button to reuse the data.
  ///
  /// In en, this message translates to:
  /// **'Use this data'**
  String get deskSetDlgChainUse;

  /// Toast after the wallet password was changed.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get deskSetDlgPwChanged;

  /// Change password dialog: title and primary button.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get deskSetDlgPwTitle;

  /// Change password dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'The new password unlocks this wallet from now on. A remembered password is forgotten.'**
  String get deskSetDlgPwDesc;

  /// Change password dialog: label and screen reader name of the field.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get deskSetDlgPwCurrent;

  /// Change password dialog: error under the current password field.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get deskSetDlgPwWrong;

  /// Change password dialog: label and screen reader name of the field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get deskSetDlgPwNew;

  /// Change password dialog: label and screen reader name of the field.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get deskSetDlgPwRepeat;

  /// Toast title after a wallet was removed from the list. {name} is the wallet name.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from the list'**
  String deskSetDlgRemoveToastList(String name);

  /// Toast title after a wallet was deleted. {name} is the wallet name.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String deskSetDlgRemoveToastDeleted(String name);

  /// Toast text after a wallet was removed from the list only.
  ///
  /// In en, this message translates to:
  /// **'Files kept.'**
  String get deskSetDlgRemoveFilesKept;

  /// Remove wallet dialog: title. {name} is the wallet name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String deskSetDlgRemoveTitle(String name);

  /// Remove wallet dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'Nothing changes until confirmed.'**
  String get deskSetDlgRemoveDesc;

  /// Remove wallet dialog: screen reader label of the two choices.
  ///
  /// In en, this message translates to:
  /// **'What to remove'**
  String get deskSetDlgRemoveWhat;

  /// Remove wallet dialog: choice title and button label; the wallet’s files stay on the computer.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get deskSetDlgRemoveFromList;

  /// Remove wallet dialog: explanation of Remove from list. {folder} is a folder path. "All wallets" is the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Files stay in {folder}. All wallets can add it back.'**
  String deskSetDlgRemoveFromListHint(String folder);

  /// Remove wallet and Delete wallet dialogs: choice title and danger button label.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet'**
  String get deskSetDlgDeleteWallet;

  /// Remove wallet dialog: explanation of Delete wallet. {folder} is a folder path.
  ///
  /// In en, this message translates to:
  /// **'Deletes its keys and database from {folder}. Only the recovery phrase restores it; without it the coins are lost.'**
  String deskSetDlgRemoveDeleteHint(String folder);

  /// Remove wallet dialog: shown for a locked wallet. "Settings › This wallet" is a menu path.
  ///
  /// In en, this message translates to:
  /// **'To delete its files as well, unlock this wallet and use Delete wallet under Settings › This wallet.'**
  String get deskSetDlgRemoveUnlockHint;

  /// Remove wallet dialog: link that locks the open wallet and opens Unlock with this wallet selected.
  ///
  /// In en, this message translates to:
  /// **'Unlock this wallet'**
  String get deskSetDlgRemoveUnlock;

  /// Remove wallet dialog: title of the warning shown for Delete wallet.
  ///
  /// In en, this message translates to:
  /// **'Cannot be undone'**
  String get deskSetDlgRemoveIrreversible;

  /// Remove wallet dialog: text of the warning.
  ///
  /// In en, this message translates to:
  /// **'Only the recovery phrase restores the wallet; without it the coins are lost for good.'**
  String get deskSetDlgRemoveIrreversibleBody;

  /// Remove wallet dialog: label and screen reader name of the confirmation field.
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get deskSetDlgRemoveName;

  /// Remove wallet dialog: help under the confirmation field. {name} is the wallet name to type.
  ///
  /// In en, this message translates to:
  /// **'Type {name} to confirm.'**
  String deskSetDlgRemoveTypeName(String name);

  /// Remove wallet dialog: error under the confirmation field.
  ///
  /// In en, this message translates to:
  /// **'Name does not match'**
  String get deskSetDlgRemoveNameMismatch;

  /// Remove and Delete wallet dialogs: label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deskSetDlgPassword;

  /// Remove and Delete wallet dialogs: checkbox label confirming the recovery phrase is saved.
  ///
  /// In en, this message translates to:
  /// **'The recovery phrase is written down'**
  String get deskSetDlgPhraseWritten;

  /// Remove wallet dialog: shown while the wallet is removed.
  ///
  /// In en, this message translates to:
  /// **'Removing…'**
  String get deskSetDlgRemoving;

  /// Error when an action needs the open wallet but it is locked.
  ///
  /// In en, this message translates to:
  /// **'The wallet is locked'**
  String get deskSetDlgWalletLocked;

  /// Delete wallet dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet?'**
  String get deskSetDlgDeleteTitle;

  /// Delete wallet dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'Deletes the wallet and its seed from this computer. Only the recovery phrase restores it; without it the coins are lost.'**
  String get deskSetDlgDeleteDesc;

  /// Title of the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get deskSetFrameTitle;

  /// Accessibility label of the Settings sidebar list.
  ///
  /// In en, this message translates to:
  /// **'Settings sections'**
  String get deskSetFrameSections;

  /// Settings sidebar entry and page name for the node section. Narrow (about 200 px).
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get deskSetFrameNode;

  /// Settings sidebar entry and page name for how this wallet receives payments. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get deskSetFrameReceiving;

  /// Settings sidebar entry and page name for privacy and network routing. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get deskSetFramePrivacy;

  /// Settings sidebar entry and page name for theme, language and display. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get deskSetFrameAppearance;

  /// Settings sidebar entry and page name for the open wallet (name, password, backup, delete). Narrow.
  ///
  /// In en, this message translates to:
  /// **'This wallet'**
  String get deskSetFrameThisWallet;

  /// Settings sidebar entry and page name for the list of wallets on this computer. Narrow.
  ///
  /// In en, this message translates to:
  /// **'All wallets'**
  String get deskSetFrameAllWallets;

  /// Settings sidebar entry and page name for showing the recovery phrase. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get deskSetFramePhrase;

  /// Settings sidebar entry and page name for rescanning the chain to recheck the balance. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Recheck balance'**
  String get deskSetFrameRescan;

  /// Settings sidebar entry and page name for the About page. Narrow.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get deskSetFrameAbout;

  /// Settings sidebar entry and page name for the Help page. Narrow.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get deskSetFrameHelp;

  /// Status word of a service that works normally.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get deskSetFrameHealthOn;

  /// Status word of a service that answers slowly.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get deskSetFrameHealthSlow;

  /// Status word of a service or node that does not answer.
  ///
  /// In en, this message translates to:
  /// **'Not responding'**
  String get deskSetFrameNotResponding;

  /// Status word of a service that is switched off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskSetFrameOff;

  /// Status word while a service is being checked.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get deskSetFrameChecking;

  /// Status word of a node that has the whole blockchain.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get deskSetFrameNodeSynced;

  /// Status word of a node that is still downloading the blockchain.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get deskSetFrameNodeSyncing;

  /// Status word while connecting to a node or to Epicbox.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get deskSetFrameConnecting;

  /// Status word of the Epicbox listener that waits for incoming payments.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get deskSetFrameListening;

  /// Status word with its response time, e.g. "On · 84 ms". {word} is a status word, {ms} milliseconds.
  ///
  /// In en, this message translates to:
  /// **'{word} · {ms} ms'**
  String deskSetFrameHealthLatency(String word, int ms);

  /// Time since an event that never happened. Lowercase, part of a line.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get deskSetFrameNever;

  /// Time since an event that happened less than a minute ago. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get deskSetFrameJustNow;

  /// Minutes since an event, abbreviated, e.g. "5 min ago".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min ago} other{{count} min ago}}'**
  String deskSetFrameMinAgo(int count);

  /// Hours since an event, abbreviated, e.g. "3 h ago".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} h ago} other{{count} h ago}}'**
  String deskSetFrameHoursAgo(int count);

  /// Days since an event, abbreviated, e.g. "2 d ago".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} d ago} other{{count} d ago}}'**
  String deskSetFrameDaysAgo(int count);

  /// Screen reader hint of the node and relay picker field.
  ///
  /// In en, this message translates to:
  /// **'Opens the list'**
  String get deskSetComboOpens;

  /// Picker field: shown when a check takes long. Narrow.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get deskSetComboNoAnswer;

  /// Picker list: empty note.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show.'**
  String get deskSetComboNothing;

  /// Screen reader label of a picker row; the node’s details follow after a comma. {host} is a server address.
  ///
  /// In en, this message translates to:
  /// **'Use {host}'**
  String deskSetComboUse(String host);

  /// Toast title when starting the local node failed; the error follows as text.
  ///
  /// In en, this message translates to:
  /// **'The node did not start'**
  String get deskSetLnodeDidNotStart;

  /// Toast title when stopping the local node failed; the error follows as text.
  ///
  /// In en, this message translates to:
  /// **'The node did not stop'**
  String get deskSetLnodeDidNotStop;

  /// Toast title when restarting the local node failed; the error follows as text.
  ///
  /// In en, this message translates to:
  /// **'The node did not restart'**
  String get deskSetLnodeDidNotRestart;

  /// Toast title after the blockchain data folder was moved. The new path follows as text.
  ///
  /// In en, this message translates to:
  /// **'Chain data moved'**
  String get deskSetLnodeMoved;

  /// Toast title after the node data folder was changed without moving data. The new path follows as text.
  ///
  /// In en, this message translates to:
  /// **'Data folder changed'**
  String get deskSetLnodeFolderChanged;

  /// Toast title when changing the node data folder failed.
  ///
  /// In en, this message translates to:
  /// **'The folder did not change'**
  String get deskSetLnodeFolderFailed;

  /// Local node panel: button that starts the node. Short.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get deskSetLnodeStart;

  /// Local node panel: button that stops the node. Short.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get deskSetLnodeStop;

  /// Local node panel: button that restarts the node; also the label of a notice button. Short.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get deskSetLnodeRestart;

  /// Local node panel: tab showing the node state. Short.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deskSetLnodeTabStatus;

  /// Local node panel: tab showing connected peers. Short.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get deskSetLnodeTabPeers;

  /// Local node panel: row title for using another node while the local node syncs.
  ///
  /// In en, this message translates to:
  /// **'While syncing'**
  String get deskSetLnodeWhileSyncing;

  /// Local node panel: text of the While syncing row. {host} is a node address.
  ///
  /// In en, this message translates to:
  /// **'Use {host} until the local node is synced. The local node takes over by itself.'**
  String deskSetLnodeWhileSyncingText(String host);

  /// Local node panel: button that opens a dialog to change a setting. Short; the dots mean a dialog follows.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get deskSetLnodeChange;

  /// Screen reader label of the switch that makes the wallet use another node while the local node syncs. {host} is a node address.
  ///
  /// In en, this message translates to:
  /// **'Use {host} while syncing'**
  String deskSetLnodeUseWhileSyncing(String host);

  /// Local node panel: row title for the folder where the node keeps its data.
  ///
  /// In en, this message translates to:
  /// **'Data folder'**
  String get deskSetLnodeDataFolder;

  /// Local node panel: disk space the chain data uses, e.g. "4.2 GB used".
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String deskSetLnodeUsed(String size);

  /// Local node panel: shown when the free disk space cannot be read. Lowercase, part of a line.
  ///
  /// In en, this message translates to:
  /// **'free space unknown'**
  String get deskSetLnodeFreeUnknown;

  /// Local node panel: free disk space, e.g. "120 GB free".
  ///
  /// In en, this message translates to:
  /// **'{size} free'**
  String deskSetLnodeFree(String size);

  /// Local node panel: button that opens the data folder in the file manager. Short.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get deskSetLnodeOpen;

  /// Toast title when the data folder could not be opened. The path follows as text.
  ///
  /// In en, this message translates to:
  /// **'Folder not opened'**
  String get deskSetLnodeFolderNotOpened;

  /// Local node panel: row title for the downloaded blockchain.
  ///
  /// In en, this message translates to:
  /// **'Chain data'**
  String get deskSetLnodeChainData;

  /// Local node panel: text of the Chain data row when the node uses another program’s folder.
  ///
  /// In en, this message translates to:
  /// **'This node reads another program’s folder; delete it there.'**
  String get deskSetLnodeChainPointed;

  /// Local node panel: text of the Chain data row.
  ///
  /// In en, this message translates to:
  /// **'Use chain data another Epic node left on this computer, or delete this node’s data and download the chain again.'**
  String get deskSetLnodeChainText;

  /// Local node panel: button that offers chain data found on this computer. The dots mean a dialog follows.
  ///
  /// In en, this message translates to:
  /// **'Reuse existing…'**
  String get deskSetLnodeReuse;

  /// Local node panel: button that deletes the chain data. The dots mean a dialog follows.
  ///
  /// In en, this message translates to:
  /// **'Delete…'**
  String get deskSetLnodeDelete;

  /// Local node panel: switch title and screen reader name for starting the node when the app starts.
  ///
  /// In en, this message translates to:
  /// **'Start with the app'**
  String get deskSetLnodeAutostart;

  /// Local node panel: hint under Start with the app.
  ///
  /// In en, this message translates to:
  /// **'Starts the node at launch and keeps it syncing while the app is open.'**
  String get deskSetLnodeAutostartHint;

  /// Local node panel: button and notice button that open the node log.
  ///
  /// In en, this message translates to:
  /// **'View node log'**
  String get deskSetLnodeViewLog;

  /// Local node panel: notice button that opens the change data folder dialog.
  ///
  /// In en, this message translates to:
  /// **'Change folder…'**
  String get deskSetLnodeChangeFolder;

  /// Local node panel: notice button that makes the wallet use another node while the local node syncs. {host} is a node address.
  ///
  /// In en, this message translates to:
  /// **'Use {host} meanwhile'**
  String deskSetLnodeUseMeanwhile(String host);

  /// Local node panel: detail after the status word while the node starts. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'waiting for peers'**
  String get deskSetLnodeWaitingPeers;

  /// Local node panel: detail after the status word while syncing, when no stage is known. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'syncing'**
  String get deskSetLnodeSyncingLower;

  /// Local node panel: detail after the status word. {stage} is a sync stage word; {host} a node address.
  ///
  /// In en, this message translates to:
  /// **'{stage} · using {host} meanwhile'**
  String deskSetLnodeStageUsing(String stage, String host);

  /// Local node panel: notice title while the node is syncing.
  ///
  /// In en, this message translates to:
  /// **'Nothing can be sent or received until the local node is synced.'**
  String get deskSetLnodeNothingUntilSynced;

  /// Local node panel: detail after the block height when the node has the newest block. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'at tip'**
  String get deskSetLnodeAtTip;

  /// Local node panel: detail after the status word when the sync stalled. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'no progress for 5 min; restarted once already'**
  String get deskSetLnodeStalledDetail;

  /// Local node panel: notice title when the sync stalled.
  ///
  /// In en, this message translates to:
  /// **'The node makes no progress.'**
  String get deskSetLnodeNoProgress;

  /// Local node panel: notice text when the sync stalled.
  ///
  /// In en, this message translates to:
  /// **'Restarting usually helps; if not, the log says why.'**
  String get deskSetLnodeNoProgressText;

  /// Local node panel: notice title when the node cannot open its port.
  ///
  /// In en, this message translates to:
  /// **'Port 3413 is used by another program.'**
  String get deskSetLnodePortInUse;

  /// Local node panel: notice text when the port is in use. "Node server" is a row title in Settings > Node.
  ///
  /// In en, this message translates to:
  /// **'Close it (another Epic node?) or pick the node already running there under Node server.'**
  String get deskSetLnodePortInUseText;

  /// Local node panel: notice title when the disk is nearly full.
  ///
  /// In en, this message translates to:
  /// **'Less than 2 GB free on this volume.'**
  String get deskSetLnodeDiskLow;

  /// Local node panel: notice text when the disk is nearly full.
  ///
  /// In en, this message translates to:
  /// **'Free space or change the data folder.'**
  String get deskSetLnodeDiskLowText;

  /// Local node panel: notice title when the node program file is gone.
  ///
  /// In en, this message translates to:
  /// **'The node program is missing from this installation.'**
  String get deskSetLnodeMissing;

  /// Local node panel: notice text when the node program file is gone.
  ///
  /// In en, this message translates to:
  /// **'Reinstall the wallet.'**
  String get deskSetLnodeMissingText;

  /// Local node panel: notice title when the node ended unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'The node stopped by itself.'**
  String get deskSetLnodeStopped;

  /// Local node panel: notice text when the node ended unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'The last log lines may say why.'**
  String get deskSetLnodeStoppedText;

  /// Local node panel: detail after the status word when the node is stopped and another node is used. Lowercase. {host} is a node address.
  ///
  /// In en, this message translates to:
  /// **'the wallet uses {host} meanwhile'**
  String deskSetLnodeUsesMeanwhile(String host);

  /// Local node panel: detail after the status word when the node is stopped. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'nothing can be sent until it runs'**
  String get deskSetLnodeNothingUntilRuns;

  /// Local node panel: label of the tile showing the number of connected peers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get deskSetLnodeTilePeers;

  /// Local node panel: label of the tile showing sync progress.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get deskSetLnodeTileSync;

  /// Local node panel: label of the tile showing the download speed.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get deskSetLnodeTileDownload;

  /// Local node panel: download tile suffix, e.g. "1.2 GB so far".
  ///
  /// In en, this message translates to:
  /// **'{size} so far'**
  String deskSetLnodeSoFar(String size);

  /// Local node panel: label of the tile showing the disk space used by the chain.
  ///
  /// In en, this message translates to:
  /// **'Chain data on disk'**
  String get deskSetLnodeTileDisk;

  /// Local node panel: disk tile suffix, e.g. "+300 MB this session".
  ///
  /// In en, this message translates to:
  /// **'+{size} this session'**
  String deskSetLnodeThisSession(String size);

  /// Local node panel: node version in the line under the tiles.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String deskSetLnodeVersion(String version);

  /// Local node panel: how long the node has run, e.g. "running 2 h 5 min". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'running {duration}'**
  String deskSetLnodeRunning(String duration);

  /// Local node panel: when the node stopped, e.g. "stopped 14:02". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'stopped {time}'**
  String deskSetLnodeStoppedAt(String time);

  /// Local node panel: number of connected peers in the line under the tiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} peer} other{{count} peers}}'**
  String deskSetLnodePeersCount(int count);

  /// Local node panel: progress text while the data folder moves, e.g. "Moving the chain data · 1 GB of 4 GB".
  ///
  /// In en, this message translates to:
  /// **'Moving the chain data · {done} of {total}'**
  String deskSetLnodeMoving(String done, String total);

  /// Local node panel: line under the progress bar while the node looks for peers.
  ///
  /// In en, this message translates to:
  /// **'Connecting to peers'**
  String get deskSetLnodeConnectingPeers;

  /// Local node panel: how long ago the node started, in seconds. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'started {seconds} s ago'**
  String deskSetLnodeStartedSecAgo(int seconds);

  /// Local node panel: how long ago the node started. {duration} is like "3 min". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'started {duration} ago'**
  String deskSetLnodeStartedAgo(String duration);

  /// Local node panel: notice title when node settings changed while it runs.
  ///
  /// In en, this message translates to:
  /// **'Settings changed.'**
  String get deskSetLnodeSettingsChanged;

  /// Local node panel: notice text when node settings changed.
  ///
  /// In en, this message translates to:
  /// **'They apply at the next restart.'**
  String get deskSetLnodeSettingsChangedText;

  /// Local node panel: notice button that restarts the node.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get deskSetLnodeRestartNow;

  /// Local node panel: note under the tiles.
  ///
  /// In en, this message translates to:
  /// **'Sampled every 30 s while this page is open.'**
  String get deskSetLnodeSampled;

  /// Local node panel: warning when the node config file was edited by hand. epic-server.toml is a file name and stays.
  ///
  /// In en, this message translates to:
  /// **'epic-server.toml was edited by hand; peer and folder settings here do not apply.'**
  String get deskSetLnodeTomlEdited;

  /// Screen reader label of the sync progress bar.
  ///
  /// In en, this message translates to:
  /// **'Sync progress'**
  String get deskSetLnodeSyncProgress;

  /// Local node panel: first sync step name. Short; shown in a row of four.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get deskSetLnodeStepHeaders;

  /// Local node panel: second sync step name. Short; shown in a row of four.
  ///
  /// In en, this message translates to:
  /// **'Chain state'**
  String get deskSetLnodeStepChainState;

  /// Local node panel: third sync step name. Short; shown in a row of four.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get deskSetLnodeStepBlocks;

  /// Screen reader label of the sync step strip before the first step.
  ///
  /// In en, this message translates to:
  /// **'Sync steps: none started'**
  String get deskSetLnodeStepsNone;

  /// Screen reader label of the sync step strip. {n} is the step number, {name} its name.
  ///
  /// In en, this message translates to:
  /// **'Sync step {n} of 4: {name}'**
  String deskSetLnodeStepOf(int n, String name);

  /// Dialog title asked once when the local node first syncs. {host} is a public node address.
  ///
  /// In en, this message translates to:
  /// **'Use {host} until the local node is synced?'**
  String deskSetLndAskTitle(String host);

  /// Fallback question dialog: description. {host} is a public node address.
  ///
  /// In en, this message translates to:
  /// **'Syncing takes hours. Meanwhile the wallet can read the chain and send through {host}, a public node. The local node takes over by itself once it is synced.'**
  String deskSetLndAskDesc(String host);

  /// Fallback question dialog: small note. "Settings › Node › While syncing" is a menu path.
  ///
  /// In en, this message translates to:
  /// **'Asked once. The node and the choice can be changed under Settings › Node › While syncing.'**
  String get deskSetLndAskNote;

  /// Fallback question dialog: button to wait instead of using a public node.
  ///
  /// In en, this message translates to:
  /// **'Wait for the local node'**
  String get deskSetLndAskWait;

  /// Fallback question dialog: primary button. {host} is a public node address.
  ///
  /// In en, this message translates to:
  /// **'Use {host}'**
  String deskSetLndAskUse(String host);

  /// Dialog title for choosing the public node used while the local node syncs.
  ///
  /// In en, this message translates to:
  /// **'Node while syncing'**
  String get deskSetLndPickTitle;

  /// Node while syncing dialog: description.
  ///
  /// In en, this message translates to:
  /// **'The public node the wallet uses until the local node is synced.'**
  String get deskSetLndPickDesc;

  /// Toast title after the chain data was deleted.
  ///
  /// In en, this message translates to:
  /// **'Chain data deleted'**
  String get deskSetLndDeleted;

  /// Toast text after the chain data was deleted, e.g. "4.2 GB freed".
  ///
  /// In en, this message translates to:
  /// **'{size} freed'**
  String deskSetLndFreed(String size);

  /// Toast title when deleting the chain data failed.
  ///
  /// In en, this message translates to:
  /// **'Chain data not deleted'**
  String get deskSetLndNotDeleted;

  /// Delete chain data dialog: danger button label.
  ///
  /// In en, this message translates to:
  /// **'Delete chain data'**
  String get deskSetLndDeleteTitle;

  /// Delete chain data dialog: description. {size} is a size like "4.2 GB"; {path} a folder path.
  ///
  /// In en, this message translates to:
  /// **'Removes {size} from {path}. The node stops, and the whole chain downloads again on the next start (hours). Wallet keys and history are not touched.'**
  String deskSetLndDeleteDesc(String size, String path);

  /// Delete chain data dialog: description when the size is not known. {path} is a folder path.
  ///
  /// In en, this message translates to:
  /// **'Removes the chain data from {path}. The node stops, and the whole chain downloads again on the next start (hours). Wallet keys and history are not touched.'**
  String deskSetLndDeleteDescNoSize(String path);

  /// Delete chain data dialog: asks to type a word, which is shown in monospace in place of {word}. The word itself is always the English "delete" and is not translated.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm.'**
  String deskSetLndTypeToConfirm(String word);

  /// Screen reader label of the confirmation field in the Delete chain data dialog. {word} is the English word "delete".
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String deskSetLndTypeToConfirmLabel(String word);

  /// Reuse chain data dialog: where a chain data folder came from. "epic" is the program name.
  ///
  /// In en, this message translates to:
  /// **'epic (the command-line node)'**
  String get deskSetLndSourceCli;

  /// Reuse chain data dialog: where a chain data folder came from.
  ///
  /// In en, this message translates to:
  /// **'Epic GUI'**
  String get deskSetLndSourceGui;

  /// Reuse chain data dialog: where a chain data folder came from.
  ///
  /// In en, this message translates to:
  /// **'an earlier Epic Wallet'**
  String get deskSetLndSourceBundled;

  /// Reuse chain data dialog: where a chain data folder came from.
  ///
  /// In en, this message translates to:
  /// **'another folder'**
  String get deskSetLndSourceCustom;

  /// Toast title after the node was pointed at existing chain data. The folder follows as text.
  ///
  /// In en, this message translates to:
  /// **'Chain data in use'**
  String get deskSetLndInUse;

  /// Toast title when pointing the node at a chain data folder failed.
  ///
  /// In en, this message translates to:
  /// **'The folder is not in use'**
  String get deskSetLndNotInUse;

  /// Reuse chain data dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Chain data found on this computer'**
  String get deskSetLndReuseTitle;

  /// Reuse chain data dialog: description.
  ///
  /// In en, this message translates to:
  /// **'Another Epic node left chain data here. The local node can read that folder instead of downloading the chain.'**
  String get deskSetLndReuseDesc;

  /// Reuse chain data dialog: shown while folders are searched.
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get deskSetLndLooking;

  /// Reuse chain data dialog: choice title for using a found folder.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get deskSetLndUseIt;

  /// Reuse chain data dialog: when the folder last changed, e.g. "last written 2026-10-03". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'last written {date}'**
  String deskSetLndLastWritten(String date);

  /// Reuse chain data dialog: shown on a folder that another program holds.
  ///
  /// In en, this message translates to:
  /// **'In use by another program'**
  String get deskSetLndLocked;

  /// Reuse chain data dialog: explains what Use it does. "Delete chain data" is a button name.
  ///
  /// In en, this message translates to:
  /// **'Nothing is copied: the node reads that folder, and Delete chain data is off for it.'**
  String get deskSetLndNothingCopied;

  /// Reuse chain data dialog: choice title for not reusing any folder.
  ///
  /// In en, this message translates to:
  /// **'Download fresh'**
  String get deskSetLndFresh;

  /// Reuse chain data dialog: Download fresh details. {size} is like "5 GB".
  ///
  /// In en, this message translates to:
  /// **'Into the wallet’s own folder. About {size}.'**
  String deskSetLndFreshLine(String size);

  /// Node log dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Node log'**
  String get deskSetLndLogTitle;

  /// Node log dialog: shown while the log is read.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get deskSetLndReading;

  /// Node log dialog: note under the log. epic-server.log is a file name and stays.
  ///
  /// In en, this message translates to:
  /// **'Last 200 lines of epic-server.log in the data folder. Newest at the bottom.'**
  String get deskSetLndLogNote;

  /// Toast title after the node log was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get deskSetLndCopied;

  /// Toast text after the node log was copied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} line} other{{count} lines}}'**
  String deskSetLndLines(int count);

  /// Change folder dialog: title when the chosen folder is unusable. The reasons follow.
  ///
  /// In en, this message translates to:
  /// **'That folder does not work'**
  String get deskSetLndBadFolder;

  /// Change folder dialog: button to pick another folder.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get deskSetLndChooseAnother;

  /// Change folder dialog: title. {size} is like "4.2 GB"; {folder} a path.
  ///
  /// In en, this message translates to:
  /// **'Move {size} to {folder}?'**
  String deskSetLndMoveTitle(String size, String folder);

  /// Change folder dialog: description. "Start fresh there" is a button name.
  ///
  /// In en, this message translates to:
  /// **'The node stops while the data moves, then starts again from the new folder. Start fresh there downloads the chain again into it instead.'**
  String get deskSetLndMoveDesc;

  /// Change folder dialog: button that uses the new folder and downloads the chain again.
  ///
  /// In en, this message translates to:
  /// **'Start fresh there'**
  String get deskSetLndStartFresh;

  /// Change folder dialog: primary button that moves the data.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get deskSetLndMove;

  /// Change folder dialog: reason the chosen folder does not work.
  ///
  /// In en, this message translates to:
  /// **'The folder is not empty.'**
  String get deskSetLndProbNotEmpty;

  /// Change folder dialog: reason; "It" is the chosen folder.
  ///
  /// In en, this message translates to:
  /// **'It is inside the current folder.'**
  String get deskSetLndProbInsideSource;

  /// Change folder dialog: reason; "it" is the chosen folder.
  ///
  /// In en, this message translates to:
  /// **'The current folder is inside it.'**
  String get deskSetLndProbSourceInside;

  /// Change folder dialog: reason. Sizes like "4.2 GB".
  ///
  /// In en, this message translates to:
  /// **'Not enough space: {needed} needed, {free} free.'**
  String deskSetLndProbSpace(String needed, String free);

  /// Change folder dialog: reason when the free space cannot be read. {needed} is a size.
  ///
  /// In en, this message translates to:
  /// **'Not enough space: {needed} needed, unknown free.'**
  String deskSetLndProbSpaceUnknown(String needed);

  /// Change folder dialog: reason; "it" is the current folder.
  ///
  /// In en, this message translates to:
  /// **'Another program holds it.'**
  String get deskSetLndProbLocked;

  /// Change folder dialog: reason.
  ///
  /// In en, this message translates to:
  /// **'The current chain data is missing.'**
  String get deskSetLndProbMissing;

  /// Change folder dialog: reason; "It" is the chosen folder.
  ///
  /// In en, this message translates to:
  /// **'It cannot be written to.'**
  String get deskSetLndProbNotWritable;

  /// Change folder dialog: reason.
  ///
  /// In en, this message translates to:
  /// **'The current chain data is incomplete.'**
  String get deskSetLndProbIncomplete;

  /// Change folder dialog: reason.
  ///
  /// In en, this message translates to:
  /// **'Another program’s chain data is there.'**
  String get deskSetLndProbForeign;

  /// Toast title after a peer was banned. The peer address follows as text.
  ///
  /// In en, this message translates to:
  /// **'Peer banned'**
  String get deskSetPeersBannedToast;

  /// Toast title after a peer was unbanned. The peer address follows as text.
  ///
  /// In en, this message translates to:
  /// **'Peer unbanned'**
  String get deskSetPeersUnbannedToast;

  /// Peers tab: error under the preferred peer field.
  ///
  /// In en, this message translates to:
  /// **'Not an IP address and port, such as 203.0.113.5:3414.'**
  String get deskSetPeersNotAddress;

  /// Peers tab: error under the preferred peer field when the address is already in the list.
  ///
  /// In en, this message translates to:
  /// **'Already preferred.'**
  String get deskSetPeersAlreadyPreferred;

  /// Peers tab: error under the maximum peers fields, e.g. "8 to 500."
  ///
  /// In en, this message translates to:
  /// **'{min} to {max}.'**
  String deskSetPeersMaxRange(int min, int max);

  /// Peers tab: summary line while the peers are read.
  ///
  /// In en, this message translates to:
  /// **'Reading the peers…'**
  String get deskSetPeersReading;

  /// Peers tab: summary line. Counts of connected peers, incoming and outgoing connections.
  ///
  /// In en, this message translates to:
  /// **'{connected} connected · {inbound} in · {outbound} out'**
  String deskSetPeersSummary(int connected, int inbound, int outbound);

  /// Peers tab: summary line when some peers are banned.
  ///
  /// In en, this message translates to:
  /// **'{connected} connected · {inbound} in · {outbound} out · {banned} banned'**
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  );

  /// Peers tab: direction of a connection that the peer opened. Lowercase, narrow column.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get deskSetPeersIn;

  /// Peers tab: direction of a connection that this node opened. Lowercase, narrow column.
  ///
  /// In en, this message translates to:
  /// **'out'**
  String get deskSetPeersOut;

  /// Peers tab: small button on a peer row that bans the peer.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get deskSetPeersBan;

  /// Peers tab: table header of the peer address column.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get deskSetPeersColAddress;

  /// Peers tab: table header of the connection direction column. Narrow (70 px).
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get deskSetPeersColDirection;

  /// Peers tab: table header of the peer software version column. Narrow (70 px).
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get deskSetPeersColVersion;

  /// Peers tab: table header of the peer block height column. Narrow (90 px).
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get deskSetPeersColHeight;

  /// Peers tab: table header of the column with the time the peer was first seen. Narrow (80 px).
  ///
  /// In en, this message translates to:
  /// **'First seen'**
  String get deskSetPeersColFirstSeen;

  /// Peers tab: empty state of the table.
  ///
  /// In en, this message translates to:
  /// **'No peers connected.'**
  String get deskSetPeersNone;

  /// Peers tab: link that shows the remaining peers of the table, e.g. "12 more".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} more} other{{count} more}}'**
  String deskSetPeersMore(int count);

  /// Peers tab: note beside the summary.
  ///
  /// In en, this message translates to:
  /// **'Refreshed every 10 s'**
  String get deskSetPeersRefreshed;

  /// Peers tab: small heading of the list of banned peers. Shown in capital letters by the app.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get deskSetPeersBanned;

  /// Peers tab: when a peer was banned, e.g. "banned 14:02". Lowercase.
  ///
  /// In en, this message translates to:
  /// **'banned {time}'**
  String deskSetPeersBannedAt(String time);

  /// Peers tab: small button that lifts a ban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get deskSetPeersUnban;

  /// Peers tab: label of the field for adding a preferred peer.
  ///
  /// In en, this message translates to:
  /// **'Preferred peers'**
  String get deskSetPeersPreferred;

  /// Screen reader label of the preferred peer field.
  ///
  /// In en, this message translates to:
  /// **'Preferred peer, IP address and port'**
  String get deskSetPeersPreferredLabel;

  /// Peers tab: small button that adds the preferred peer.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get deskSetPeersAdd;

  /// Peers tab: label of the field for the maximum number of incoming connections.
  ///
  /// In en, this message translates to:
  /// **'Max incoming'**
  String get deskSetPeersMaxIn;

  /// Screen reader label of the maximum incoming connections field.
  ///
  /// In en, this message translates to:
  /// **'Max incoming peers'**
  String get deskSetPeersMaxInLabel;

  /// Peers tab: label of the field for the maximum number of outgoing connections.
  ///
  /// In en, this message translates to:
  /// **'Max outgoing'**
  String get deskSetPeersMaxOut;

  /// Screen reader label of the maximum outgoing connections field.
  ///
  /// In en, this message translates to:
  /// **'Max outgoing peers'**
  String get deskSetPeersMaxOutLabel;

  /// Peers tab: label before the list of preferred peers, e.g. "2 preferred:".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} preferred:} other{{count} preferred:}}'**
  String deskSetPeersPreferredCount(int count);

  /// Tooltip and screen reader label of the small button that removes a preferred peer. {peer} is its address.
  ///
  /// In en, this message translates to:
  /// **'Forget {peer}'**
  String deskSetPeersForget(String peer);

  /// Peers tab: explanatory note at the bottom. "Enter" is the keyboard key. {min}, {max} and {def} are numbers.
  ///
  /// In en, this message translates to:
  /// **'First seen is when this app first saw the peer connected, this session; the node does not report when a connection began. Ban and unban use the node’s owner API. Enter saves a maximum ({min} to {max}, {def} by default).'**
  String deskSetPeersNote(int min, int max, int def);

  /// Delete chain data dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Delete chain data?'**
  String get deskSetLndDeleteQuestion;

  /// Toast text when the log folder cannot be opened because the log is not written to disk.
  ///
  /// In en, this message translates to:
  /// **'The log is kept in memory only.'**
  String get deskSetLogsMemoryOnly;

  /// Clear logs dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Clear logs?'**
  String get deskSetLogsClearTitle;

  /// Clear logs dialog: description.
  ///
  /// In en, this message translates to:
  /// **'Deletes the log files. A report sent later has only what is logged from now on.'**
  String get deskSetLogsClearDesc;

  /// Clear logs dialog: button that cancels.
  ///
  /// In en, this message translates to:
  /// **'Keep logs'**
  String get deskSetLogsKeep;

  /// Clear logs dialog danger button and the Settings > Help > Logs button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get deskSetLogsClear;

  /// Toast title after the logs were cleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get deskSetLogsCleared;

  /// Settings > Help > Logs: when detailed logging ends, today. {time} is a clock time like 14:02. Lowercase, part of a line.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String deskSetLogsToday(String time);

  /// Settings > Help > Logs: when detailed logging ends, tomorrow. {time} is a clock time like 14:02. Lowercase, part of a line.
  ///
  /// In en, this message translates to:
  /// **'tomorrow {time}'**
  String deskSetLogsTomorrow(String time);

  /// Settings > Help: title of the Logs group.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get deskSetLogsTitle;

  /// Settings > Help > Logs: row title.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get deskSetLogsLevel;

  /// Settings > Help > Logs: text of the Log level row when the level is Normal.
  ///
  /// In en, this message translates to:
  /// **'Normal. Detailed keeps more lines on disk for 24 hours; addresses may appear in the file, reports leave them out.'**
  String get deskSetLogsLevelNormal;

  /// Settings > Help > Logs: text of the Log level row when Detailed. {until} is like "today 14:02" or "tomorrow 14:02".
  ///
  /// In en, this message translates to:
  /// **'Detailed until {until}, then Normal. Addresses may appear in the file; reports leave them out.'**
  String deskSetLogsLevelDetailed(String until);

  /// Settings > Help > Logs: text of the Log level row when Detailed and the wallet core needs an app restart. {until} is like "today 14:02".
  ///
  /// In en, this message translates to:
  /// **'Detailed until {until}, then Normal. Addresses may appear in the file; reports leave them out. Wallet core lines get detailed from the next app start.'**
  String deskSetLogsLevelDetailedCore(String until);

  /// Settings > Help > Logs: segment for the normal log level. Short.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get deskSetLogsNormal;

  /// Settings > Help > Logs: segment for the detailed log level. Short.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get deskSetLogsDetailed;

  /// Settings > Help > Logs: row title.
  ///
  /// In en, this message translates to:
  /// **'Log files'**
  String get deskSetLogsFiles;

  /// Settings > Help > Logs: text of the Log files row. Sizes like "1.2 MB".
  ///
  /// In en, this message translates to:
  /// **'Current size {size} of {max}. Keeps one older file.'**
  String deskSetLogsSize(String size, String max);

  /// Settings > Help > Logs: button that opens the log folder.
  ///
  /// In en, this message translates to:
  /// **'Open log folder'**
  String get deskSetLogsOpenFolder;

  /// Settings > Node: tag or sub-line on a node whose software is older than the minimum version the wallet works well with. {version} is a version number like 3.6.0.
  ///
  /// In en, this message translates to:
  /// **'Version older than {version}'**
  String deskSetNodeVersionOld(String version);

  /// Settings > Node: error under the node picker when the typed node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Check the address and the port (usually 3413).'**
  String get deskSetNodePortNote;

  /// Settings > Node: footer under the node list. status.btlabs.uk is a web address and stays as is.
  ///
  /// In en, this message translates to:
  /// **'State from status.btlabs.uk, checked every few minutes. Latency as measured from this computer.'**
  String get deskSetNodeListNote;

  /// Dialog title before the local node program starts.
  ///
  /// In en, this message translates to:
  /// **'Start the local node?'**
  String get deskSetNodeStartTitle;

  /// Start the local node dialog: description under the title.
  ///
  /// In en, this message translates to:
  /// **'A separate program syncs the Epic chain on this computer.'**
  String get deskSetNodeStartDesc;

  /// Start the local node dialog: first bullet.
  ///
  /// In en, this message translates to:
  /// **'Downloads the whole chain: several GB of disk space and bandwidth.'**
  String get deskSetNodeStartLine1;

  /// Start the local node dialog: second bullet. "Syncing" is the node status word.
  ///
  /// In en, this message translates to:
  /// **'The first sync takes hours. Until it is done the node shows Syncing.'**
  String get deskSetNodeStartLine2;

  /// Start the local node dialog: third bullet.
  ///
  /// In en, this message translates to:
  /// **'The firewall may ask to allow the node program.'**
  String get deskSetNodeStartLine3;

  /// Start the local node dialog: primary button.
  ///
  /// In en, this message translates to:
  /// **'Start local node'**
  String get deskSetNodeStartButton;

  /// Status of the local node in the node picker: not installed or never started.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get deskSetNodeRowNotSetUp;

  /// Status of the local node in the node picker: switched off.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deskSetNodeRowStopped;

  /// Status of the local node in the node picker: starting up.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get deskSetNodeRowStarting;

  /// Status of the local node in the node picker while syncing. {percent} is a number with a percent sign, e.g. "42%".
  ///
  /// In en, this message translates to:
  /// **'Syncing {percent}'**
  String deskSetNodeRowSyncingPct(String percent);

  /// Status of the local node in the node picker: sync stopped making progress.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get deskSetNodeRowStalled;

  /// Status of the local node in the node picker: could not run.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get deskSetNodeRowFailed;

  /// Toast title after switching to the local node.
  ///
  /// In en, this message translates to:
  /// **'Local node in use'**
  String get deskSetNodeLocalInUse;

  /// Toast text after switching to the local node.
  ///
  /// In en, this message translates to:
  /// **'It downloads the whole chain. Needs 5 GB free.'**
  String get deskSetNodeLocalInUseText;

  /// Name of the node program on this computer, in the node picker and its field.
  ///
  /// In en, this message translates to:
  /// **'Local node'**
  String get deskSetNodeLocalNode;

  /// Heading of the node picker group holding the local node.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get deskSetNodeGroupComputer;

  /// Heading of the node picker group of nodes the user saved; also a name used in other texts.
  ///
  /// In en, this message translates to:
  /// **'My nodes'**
  String get deskSetNodeGroupMine;

  /// Heading of the node picker group of public nodes.
  ///
  /// In en, this message translates to:
  /// **'Public nodes'**
  String get deskSetNodeGroupPublic;

  /// Toast title after a node was removed from the saved nodes. The node address follows as text.
  ///
  /// In en, this message translates to:
  /// **'Removed from my nodes'**
  String get deskSetNodeRemovedFromMine;

  /// Node picker: word on a typed address whose node does not answer.
  ///
  /// In en, this message translates to:
  /// **'Not answering'**
  String get deskSetNodeNotAnswering;

  /// Node picker: tooltip and screen reader label of the star button on a typed address.
  ///
  /// In en, this message translates to:
  /// **'Add to my nodes'**
  String get deskSetNodeAddToMine;

  /// Settings > Node: row title, picker label and screen reader name.
  ///
  /// In en, this message translates to:
  /// **'Node server'**
  String get deskSetNodeServer;

  /// Settings > Node: hint under the Node server row.
  ///
  /// In en, this message translates to:
  /// **'The node the wallet reads the chain through and sends with.'**
  String get deskSetNodeServerHint;

  /// Settings > Node: placeholder of the node picker search field.
  ///
  /// In en, this message translates to:
  /// **'Find or type a node address'**
  String get deskSetNodeFindHint;

  /// Settings > Node: shown while a chosen node is checked.
  ///
  /// In en, this message translates to:
  /// **'Checking the node…'**
  String get deskSetNodeChecking;

  /// Settings > Node: note under a typed address in the picker. "Enter" is the keyboard key.
  ///
  /// In en, this message translates to:
  /// **'Enter uses it. The star keeps it in My nodes.'**
  String get deskSetNodeTypedNote;

  /// Settings > Node: empty note of the node picker.
  ///
  /// In en, this message translates to:
  /// **'No nodes to show.'**
  String get deskSetNodeNoNodes;

  /// Node picker footer action that opens the add node dialog.
  ///
  /// In en, this message translates to:
  /// **'Add to my nodes…'**
  String get deskSetNodeFooterAdd;

  /// Node picker footer action that opens the node directory dialog.
  ///
  /// In en, this message translates to:
  /// **'Node directory…'**
  String get deskSetNodeFooterDirectory;

  /// Settings > Node: switch title and screen reader name.
  ///
  /// In en, this message translates to:
  /// **'Sync in background'**
  String get deskSetNodeBackground;

  /// Settings > Node: hint under Sync in background.
  ///
  /// In en, this message translates to:
  /// **'Keeps syncing while the app is closed.'**
  String get deskSetNodeBackgroundHint;

  /// Toast title when the recovery phrase could not be copied.
  ///
  /// In en, this message translates to:
  /// **'Not copied'**
  String get deskSetPhraseNotCopied;

  /// Toast text when the clipboard refused the recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'The clipboard refused the text.'**
  String get deskSetPhraseClipboardRefused;

  /// Toast title after the recovery phrase was copied.
  ///
  /// In en, this message translates to:
  /// **'Phrase copied'**
  String get deskSetPhraseCopied;

  /// Toast text after the recovery phrase was copied.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is cleared in 60 s.'**
  String get deskSetPhraseCleared;

  /// Settings > Recovery phrase: error under the password field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the password.'**
  String get deskSetPhraseEnterPassword;

  /// Settings > Recovery phrase: error under the password field.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get deskSetPhraseWrongPassword;

  /// Settings > Recovery phrase: text under the page heading.
  ///
  /// In en, this message translates to:
  /// **'Write the words on paper, in this order. Never type them into a website or a chat.'**
  String get deskSetPhraseIntro;

  /// Settings > Recovery phrase: title of the panel with the hidden words and the password field.
  ///
  /// In en, this message translates to:
  /// **'Enter the password to show the words'**
  String get deskSetPhrasePanel;

  /// Settings > Recovery phrase: button that reveals the words.
  ///
  /// In en, this message translates to:
  /// **'Show words'**
  String get deskSetPhraseShowWords;

  /// Screen reader label of the revealed recovery phrase grid.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Recovery phrase, {count} word} other{Recovery phrase, {count} words}}'**
  String deskSetPhraseWordsLabel(int count);

  /// Settings > Recovery phrase: button that hides the QR code.
  ///
  /// In en, this message translates to:
  /// **'Hide QR code'**
  String get deskSetPhraseHideQr;

  /// Settings > Recovery phrase: button that shows the phrase as a QR code.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get deskSetPhraseShowQr;

  /// Settings > Recovery phrase: button that hides the words.
  ///
  /// In en, this message translates to:
  /// **'Hide words'**
  String get deskSetPhraseHideWords;

  /// Settings > Recovery phrase: countdown until the words hide themselves. {seconds} is a number of seconds.
  ///
  /// In en, this message translates to:
  /// **'Hides in {seconds} s'**
  String deskSetPhraseHidesIn(int seconds);

  /// Screen reader label of the recovery phrase QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code of the recovery phrase'**
  String get deskSetPhraseQrLabel;

  /// Settings > Recovery phrase: title of the warning under the words.
  ///
  /// In en, this message translates to:
  /// **'Back up the phrase'**
  String get deskSetPhraseBackUp;

  /// Settings > Recovery phrase: text of the warning under the words.
  ///
  /// In en, this message translates to:
  /// **'Anyone with these words can take the EPIC. Check that nobody can see the screen.'**
  String get deskSetPhraseBackUpText;

  /// Toast title when turning Tor on failed. The error follows as text.
  ///
  /// In en, this message translates to:
  /// **'Tor not turned on'**
  String get deskSetPrivTorOnFailed;

  /// Toast title when turning Tor off failed. The error follows as text.
  ///
  /// In en, this message translates to:
  /// **'Tor not turned off'**
  String get deskSetPrivTorOffFailed;

  /// Settings > Privacy: title of the Tor group. Tor is a product name.
  ///
  /// In en, this message translates to:
  /// **'Tor'**
  String get deskSetPrivTor;

  /// Screen reader label of the spinner while Tor is switched.
  ///
  /// In en, this message translates to:
  /// **'Switching Tor'**
  String get deskSetPrivSwitching;

  /// Settings > Privacy: small button shown when Tor is not connected.
  ///
  /// In en, this message translates to:
  /// **'Turn Tor off'**
  String get deskSetPrivTurnOff;

  /// Settings > Privacy: Tor state word when this app build has no Tor.
  ///
  /// In en, this message translates to:
  /// **'Not in this build'**
  String get deskSetPrivNotInBuild;

  /// Settings > Privacy: Tor state word while it starts.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get deskSetPrivStarting;

  /// Settings > Privacy: detail of the Tor state while it starts. {progress} is a number 0–100. {waiting} is a list of what waits, e.g. "Sending, Epicbox and HTTP", supplied by the app.
  ///
  /// In en, this message translates to:
  /// **'{progress} %. {waiting} wait until Tor is up.'**
  String deskSetPrivStartingDetail(int progress, String waiting);

  /// Settings > Privacy: detail of the Tor state when Tor runs but its receiving address is not published yet.
  ///
  /// In en, this message translates to:
  /// **'Tor address not published yet. Sends work.'**
  String get deskSetPrivNotPublished;

  /// Settings > Privacy: detail of the Tor state when Tor runs but receiving has a problem. {problem} is a short sentence from the app without final full stop.
  ///
  /// In en, this message translates to:
  /// **'{problem}. Sends work.'**
  String deskSetPrivProblemSendsWork(String problem);

  /// Settings > Privacy: detail of the Tor state when everything works.
  ///
  /// In en, this message translates to:
  /// **'Connected.'**
  String get deskSetPrivConnected;

  /// Settings > Privacy: Tor state word when Tor could not connect.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get deskSetPrivNotConnected;

  /// Settings > Privacy: detail of the Tor state when Tor stopped. {waiting} is a list of what waits, supplied by the app.
  ///
  /// In en, this message translates to:
  /// **'Tor stopped. {waiting} wait for Retry or Tor off.'**
  String deskSetPrivStoppedDetail(String waiting);

  /// Settings > Privacy: detail of the Tor state when Tor failed. {problem} is a short sentence from the app without final full stop; {waiting} is a list of what waits.
  ///
  /// In en, this message translates to:
  /// **'{problem}. {waiting} wait for Retry or Tor off.'**
  String deskSetPrivProblemDetail(String problem, String waiting);

  /// Settings > Privacy: title of the group with the status site switch.
  ///
  /// In en, this message translates to:
  /// **'Status site'**
  String get deskSetPrivStatusSite;

  /// Settings > Privacy: switch title and screen reader name. status.btlabs.uk is a web address and stays.
  ///
  /// In en, this message translates to:
  /// **'Use status.btlabs.uk'**
  String get deskSetPrivUseStatus;

  /// Settings > Privacy: hint under the status site switch. status.btlabs.uk is a web address and stays.
  ///
  /// In en, this message translates to:
  /// **'Network status and information provided by status.btlabs.uk'**
  String get deskSetPrivUseStatusHint;

  /// Toast title when turning a receiving method on failed. {method} is a method name such as Epicbox, HTTP or Tor.
  ///
  /// In en, this message translates to:
  /// **'{method} not turned on'**
  String deskSetRecvMethodOnFailed(String method);

  /// Toast title when turning a receiving method off failed. {method} is a method name such as Epicbox, HTTP or Tor.
  ///
  /// In en, this message translates to:
  /// **'{method} not turned off'**
  String deskSetRecvMethodOffFailed(String method);

  /// Toast title when switching the Epicbox server failed.
  ///
  /// In en, this message translates to:
  /// **'Server not changed'**
  String get deskSetRecvServerNotChanged;

  /// Settings > Receiving: title of the first row of each method group (the on/off switch).
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get deskSetRecvReceiving;

  /// Screen reader label of the spinner while a receiving method is switched. {method} is Epicbox, HTTP or Tor.
  ///
  /// In en, this message translates to:
  /// **'Switching {method} receiving'**
  String deskSetRecvSwitching(String method);

  /// Screen reader label of the switch for a receiving method. {method} is Epicbox, HTTP or Tor.
  ///
  /// In en, this message translates to:
  /// **'{method} receiving'**
  String deskSetRecvMethodReceiving(String method);

  /// Toast title when saving a receiving setting failed.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get deskSetRecvNotSaved;

  /// Settings > Receiving: row title of the switch that turns the method on at unlock.
  ///
  /// In en, this message translates to:
  /// **'Start with the wallet'**
  String get deskSetRecvAutostart;

  /// Settings > Receiving: hint under Start with the wallet.
  ///
  /// In en, this message translates to:
  /// **'Turns on at unlock.'**
  String get deskSetRecvAutostartHint;

  /// Screen reader label of the Start with the wallet switch. {method} is Epicbox, HTTP or Tor.
  ///
  /// In en, this message translates to:
  /// **'{method}: start with the wallet'**
  String deskSetRecvMethodAutostart(String method);

  /// Settings > Receiving: state word at the right of a method group head when the method has stopped. Short.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deskSetRecvHeadStopped;

  /// Settings > Receiving: state word at the right of a method group head while the method starts. Short.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get deskSetRecvHeadStarting;

  /// Tooltip on an Epicbox server in the picker. {ms} is milliseconds.
  ///
  /// In en, this message translates to:
  /// **'Response time {ms} ms. Measured from the status site.'**
  String deskSetRecvResponseTime(int ms);

  /// Settings > Receiving: heading of the Epicbox group.
  ///
  /// In en, this message translates to:
  /// **'Epicbox receiving'**
  String get deskSetRecvEpicboxTitle;

  /// Settings > Receiving: text of the Epicbox receiving row.
  ///
  /// In en, this message translates to:
  /// **'Payments arrive via the Epicbox server, also while the wallet is closed.'**
  String get deskSetRecvEpicboxText;

  /// Settings > Receiving: row title, picker label and screen reader name for the Epicbox server.
  ///
  /// In en, this message translates to:
  /// **'Epicbox server'**
  String get deskSetRecvEpicboxServer;

  /// Settings > Receiving: hint under the Epicbox server row.
  ///
  /// In en, this message translates to:
  /// **'Which server holds payments for this address. Both wallets can use different servers.'**
  String get deskSetRecvEpicboxServerHint;

  /// Settings > Receiving: placeholder of the Epicbox server picker search field.
  ///
  /// In en, this message translates to:
  /// **'Find or type an Epicbox server'**
  String get deskSetRecvFindHint;

  /// Settings > Receiving: shown while the Epicbox server is switched.
  ///
  /// In en, this message translates to:
  /// **'Switching the Epicbox server…'**
  String get deskSetRecvSwitchingServer;

  /// Epicbox server picker: note on a typed server that is not in the public list. Lowercase.
  ///
  /// In en, this message translates to:
  /// **'not in the public list'**
  String get deskSetRecvNotInList;

  /// Epicbox server picker: note under a typed server. "Enter" is the keyboard key.
  ///
  /// In en, this message translates to:
  /// **'Enter uses it. Its status shows once the wallet connects.'**
  String get deskSetRecvTypedNote;

  /// Epicbox server picker: footer under the list. status.btlabs.uk is a web address and stays.
  ///
  /// In en, this message translates to:
  /// **'State from status.btlabs.uk, checked every few minutes.'**
  String get deskSetRecvListNote;

  /// Settings > Receiving: heading of the HTTP group.
  ///
  /// In en, this message translates to:
  /// **'HTTP receiving'**
  String get deskSetRecvHttpTitle;

  /// Settings > Receiving: text of the HTTP receiving row.
  ///
  /// In en, this message translates to:
  /// **'Straight from another wallet while this one is open.'**
  String get deskSetRecvHttpText;

  /// Settings > Receiving: notice title in the HTTP group when Tor is on.
  ///
  /// In en, this message translates to:
  /// **'Off while Tor is on'**
  String get deskSetRecvHttpOffTitle;

  /// Settings > Receiving: notice text in the HTTP group when Tor is on.
  ///
  /// In en, this message translates to:
  /// **'Direct payments arrive at this wallet’s Tor address instead.'**
  String get deskSetRecvHttpOffText;

  /// Settings > Receiving: notice button that jumps to the Tor switch in Settings > Privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get deskSetRecvPrivacySettings;

  /// Toast title when changing an HTTP receiving option failed. The error follows as text.
  ///
  /// In en, this message translates to:
  /// **'Not changed'**
  String get deskSetHttpNotChanged;

  /// Settings > Receiving > HTTP: error under the port field.
  ///
  /// In en, this message translates to:
  /// **'Port must be 1 to 65535'**
  String get deskSetHttpPortError;

  /// Settings > Receiving > HTTP: row title for who can send payments to the HTTP address.
  ///
  /// In en, this message translates to:
  /// **'Reachable'**
  String get deskSetHttpReachable;

  /// Settings > Receiving > HTTP: hint under the Reachable row.
  ///
  /// In en, this message translates to:
  /// **'Who can pay the HTTP address.'**
  String get deskSetHttpReachableHint;

  /// Settings > Receiving > HTTP: segment, only programs on this computer reach the address. Short.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get deskSetHttpLocalOnly;

  /// Settings > Receiving > HTTP: segment, the address answers on the internet. Short.
  ///
  /// In en, this message translates to:
  /// **'From the internet'**
  String get deskSetHttpFromInternet;

  /// Tooltip and screen reader label of the help button that opens the internet guide.
  ///
  /// In en, this message translates to:
  /// **'Receive from the internet: how it works'**
  String get deskSetHttpGuideHelp;

  /// Settings > Receiving > HTTP: note under the Reachable row when From the internet is chosen. {port} is a port number; http://<public IP>:{port} is an address template and stays in this form.
  ///
  /// In en, this message translates to:
  /// **'Answers on all interfaces. The router must forward TCP {port} to this computer. Senders on the internet use http://<public IP>:{port}.'**
  String deskSetHttpPublicNote(String port);

  /// Settings > Receiving > HTTP: row title for the port number.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get deskSetHttpPort;

  /// Settings > Receiving > HTTP: hint under the Port row.
  ///
  /// In en, this message translates to:
  /// **'1 to 65535. Used by the HTTP address.'**
  String get deskSetHttpPortHint;

  /// Screen reader label of the port field.
  ///
  /// In en, this message translates to:
  /// **'HTTP port'**
  String get deskSetHttpPortLabel;

  /// Internet guide dialog: title; also the primary button that turns it on.
  ///
  /// In en, this message translates to:
  /// **'Receive from the internet'**
  String get deskSetHttpGuideTitle;

  /// Internet guide dialog: description when the address is public.
  ///
  /// In en, this message translates to:
  /// **'Now: from the internet.'**
  String get deskSetHttpGuideNowPublic;

  /// Internet guide dialog: description when the address is local only.
  ///
  /// In en, this message translates to:
  /// **'Now: local only. Only programs on this computer reach the HTTP address.'**
  String get deskSetHttpGuideNowLocal;

  /// Internet guide dialog: step 1 title.
  ///
  /// In en, this message translates to:
  /// **'Listen on all interfaces'**
  String get deskSetHttpStep1;

  /// Internet guide dialog: step 1 text. 0.0.0.0 is an address and stays.
  ///
  /// In en, this message translates to:
  /// **'The wallet answers on 0.0.0.0, port {port}. Other devices and the internet can then send payments to this wallet. The firewall may ask to allow it.'**
  String deskSetHttpStep1Text(String port);

  /// Internet guide dialog: step 2 title.
  ///
  /// In en, this message translates to:
  /// **'Forward the port'**
  String get deskSetHttpStep2;

  /// Internet guide dialog: step 2 text.
  ///
  /// In en, this message translates to:
  /// **'On the router’s page (often 10.0.1.1), find Port forwarding and forward TCP {port} to this computer.'**
  String deskSetHttpStep2Text(String port);

  /// Internet guide dialog: step 3 title.
  ///
  /// In en, this message translates to:
  /// **'Share the public address'**
  String get deskSetHttpStep3;

  /// Internet guide dialog: step 3 text. http://<public IP>:{port} is an address template and stays in this form.
  ///
  /// In en, this message translates to:
  /// **'Senders use http://<public IP>:{port}. The public IP can change.'**
  String deskSetHttpStep3Text(String port);

  /// Internet guide dialog: title of the Tor suggestion.
  ///
  /// In en, this message translates to:
  /// **'No router setup?'**
  String get deskSetHttpNoRouter;

  /// Internet guide dialog: text of the Tor suggestion.
  ///
  /// In en, this message translates to:
  /// **'Tor works from anywhere with nothing to forward.'**
  String get deskSetHttpNoRouterText;

  /// Internet guide dialog: small button that turns Tor receiving on.
  ///
  /// In en, this message translates to:
  /// **'Turn on Tor'**
  String get deskSetHttpTurnOnTor;

  /// Internet guide dialog: small note at the bottom.
  ///
  /// In en, this message translates to:
  /// **'Only the receiving API is exposed. Plain HTTP is not encrypted.'**
  String get deskSetHttpExposed;

  /// Internet guide dialog: button that goes back to local only.
  ///
  /// In en, this message translates to:
  /// **'Back to local only'**
  String get deskSetHttpBackLocal;

  /// Report a problem dialog: error when sending failed.
  ///
  /// In en, this message translates to:
  /// **'The report was not sent. Try again.'**
  String get deskSetReportNotSent;

  /// Title of the system Save dialog when saving the report to a file.
  ///
  /// In en, this message translates to:
  /// **'Save the report'**
  String get deskSetReportSaveDialog;

  /// Report a problem dialog: notice after the report was saved to a file.
  ///
  /// In en, this message translates to:
  /// **'Saved. Cleaned of secrets, not encrypted.'**
  String get deskSetReportSaved;

  /// Report a problem dialog: error when saving to a file failed.
  ///
  /// In en, this message translates to:
  /// **'The file was not saved. Try again.'**
  String get deskSetReportNotSaved;

  /// Report a problem dialog: item in the "What is sent" list.
  ///
  /// In en, this message translates to:
  /// **'Report text'**
  String get deskSetReportText;

  /// Report a problem dialog: item in the "What is sent" list. {size} is like "256 KB".
  ///
  /// In en, this message translates to:
  /// **'App log (last {size})'**
  String deskSetReportAppLog(String size);

  /// Report a problem dialog: title after the report was sent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get deskSetReportSent;

  /// Report a problem dialog: description after the report was sent, when there is no reference.
  ///
  /// In en, this message translates to:
  /// **'The report arrived.'**
  String get deskSetReportArrived;

  /// Report a problem dialog: description after the report was sent. {id} is a reference code.
  ///
  /// In en, this message translates to:
  /// **'The report arrived. Its reference is {id}.'**
  String deskSetReportArrivedRef(String id);

  /// Report a problem dialog: error under the description field when empty.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened.'**
  String get deskSetReportDescribe;

  /// Report a problem dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get deskSetReportTitle;

  /// Report a problem dialog: description under the title. "Send" and "Save to file" are button names.
  ///
  /// In en, this message translates to:
  /// **'The report is encrypted so only the developer can read it. Nothing is sent before Send. Save to file keeps the same cleaned report, not encrypted.'**
  String get deskSetReportDesc;

  /// Report a problem dialog: label and screen reader name of the description field.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get deskSetReportWhat;

  /// Report a problem dialog: placeholder of the description field.
  ///
  /// In en, this message translates to:
  /// **'What you did, what you expected, what happened instead'**
  String get deskSetReportWhatHint;

  /// Report a problem dialog: label and screen reader name of the optional contact field.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get deskSetReportContact;

  /// Report a problem dialog: placeholder of the contact field.
  ///
  /// In en, this message translates to:
  /// **'An email address or other handle, for a reply'**
  String get deskSetReportContactHint;

  /// Report a problem dialog: checkbox label.
  ///
  /// In en, this message translates to:
  /// **'Attach logs (recommended)'**
  String get deskSetReportAttach;

  /// Report a problem dialog: small text under the Attach logs checkbox.
  ///
  /// In en, this message translates to:
  /// **'The newest part of the app log, cleaned of phrases, passwords, addresses, IPs and home folders.'**
  String get deskSetReportAttachHint;

  /// Report a problem dialog: title of the collapsible list of what the report holds.
  ///
  /// In en, this message translates to:
  /// **'What is sent'**
  String get deskSetReportSentWhat;

  /// Report a problem dialog: title of the error notice when sending failed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get deskSetReportNotSentTitle;

  /// Report a problem dialog: notice shown when this app build cannot send reports.
  ///
  /// In en, this message translates to:
  /// **'Sending is off in this build'**
  String get deskSetReportOff;

  /// Report a problem dialog: button that saves the report to a file.
  ///
  /// In en, this message translates to:
  /// **'Save to file'**
  String get deskSetReportSaveToFile;

  /// Report a problem dialog: primary button that sends the report.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deskSetReportSend;

  /// Settings > Recheck balance: line added to the scan log when the scan ended normally.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get deskSetRescanComplete;

  /// Settings > Recheck balance: line added to the scan log when the scan was stopped; also the title of the result card.
  ///
  /// In en, this message translates to:
  /// **'Scan stopped'**
  String get deskSetRescanStoppedLine;

  /// Settings > Recheck balance: title of the collapsible scan log and its screen reader label.
  ///
  /// In en, this message translates to:
  /// **'Scan log'**
  String get deskSetRescanLog;

  /// Settings > Recheck balance: text of the first row.
  ///
  /// In en, this message translates to:
  /// **'Reads the chain again and rebuilds the balance from the outputs found. Use it when the balance looks wrong, after a restore, or when outputs stay locked after a failed send. The wallet stays usable meanwhile.'**
  String get deskSetRescanText;

  /// Settings > Recheck balance: button after a scan ended or failed.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get deskSetRescanStartAgain;

  /// Settings > Recheck balance: checkbox label.
  ///
  /// In en, this message translates to:
  /// **'Delete unconfirmed'**
  String get deskSetRescanDeleteUnconfirmed;

  /// Settings > Recheck balance: small text under the Delete unconfirmed checkbox.
  ///
  /// In en, this message translates to:
  /// **'Also cancels unconfirmed transactions and unlocks their outputs. A payment already on its way may then fail.'**
  String get deskSetRescanDeleteHint;

  /// Settings > Recheck balance: text while a scan runs.
  ///
  /// In en, this message translates to:
  /// **'Scanning the chain. The wallet stays usable; the balance updates when the scan ends.'**
  String get deskSetRescanScanning;

  /// Settings > Recheck balance: progress line after Stop was pressed.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get deskSetRescanStopping;

  /// Settings > Recheck balance: progress line with the percentage done.
  ///
  /// In en, this message translates to:
  /// **'Checking… {percent} %'**
  String deskSetRescanChecking(int percent);

  /// Settings > Recheck balance: title of the error notice when the scan failed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get deskSetRescanFailed;

  /// Settings > Recheck balance: result sentence after Delete unconfirmed found nothing.
  ///
  /// In en, this message translates to:
  /// **'No unconfirmed transaction was found.'**
  String get deskSetRescanNoneFound;

  /// Settings > Recheck balance: result sentence after Delete unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed transactions were cancelled and their outputs unlocked.'**
  String get deskSetRescanCancelled;

  /// Settings > Recheck balance: shown instead of a balance that could not be read.
  ///
  /// In en, this message translates to:
  /// **'Not read'**
  String get deskSetRescanNotRead;

  /// Settings > Recheck balance: title of the result card after a complete scan.
  ///
  /// In en, this message translates to:
  /// **'Scan finished'**
  String get deskSetRescanFinished;

  /// Settings > Recheck balance: first sentence of the result after a complete scan. Further sentences follow after a space.
  ///
  /// In en, this message translates to:
  /// **'The balance is up to date.'**
  String get deskSetRescanUpToDate;

  /// Settings > Recheck balance: result sentence after a resumed scan; follows another sentence after a space.
  ///
  /// In en, this message translates to:
  /// **'The scan carried on from where it stopped; the counts cover that part.'**
  String get deskSetRescanResumed;

  /// Settings > Recheck balance: first sentence of the result after a stopped scan. A further sentence may follow after a space.
  ///
  /// In en, this message translates to:
  /// **'Stopped before the end. The balance was read again; start again to carry on.'**
  String get deskSetRescanStoppedEarly;

  /// Settings > Recheck balance: result sentence after a stopped scan with Delete unconfirmed; follows another sentence after a space.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed transactions were not deleted: that runs only when a scan completes.'**
  String get deskSetRescanNotDeleted;

  /// Settings > Recheck balance: label of a fact in the result card.
  ///
  /// In en, this message translates to:
  /// **'Balance before'**
  String get deskSetRescanBefore;

  /// Settings > Recheck balance: label of a fact in the result card.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get deskSetRescanAfter;

  /// Settings > Recheck balance: label of a count in the result card. An output is a coin unit in the wallet.
  ///
  /// In en, this message translates to:
  /// **'Outputs found'**
  String get deskSetRescanFound;

  /// Settings > Recheck balance: label of a count of restored outputs in the result card.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get deskSetRescanRestored;

  /// Settings > Recheck balance: label of a count of outputs that became spendable again in the result card.
  ///
  /// In en, this message translates to:
  /// **'Back to unspent'**
  String get deskSetRescanRevived;

  /// Settings > Recheck balance: label of a count of unlocked outputs in the result card.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get deskSetRescanUnlocked;

  /// Settings > Recheck balance: label of a count of deleted outputs in the result card.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deskSetRescanDeleted;

  /// Toast title after a wallet that was removed from the list was added back. {name} is the wallet name.
  ///
  /// In en, this message translates to:
  /// **'{name} added back'**
  String deskSetWalletsAddedBack(String name);

  /// Toast title when adding a wallet back failed.
  ///
  /// In en, this message translates to:
  /// **'Not added back'**
  String get deskSetWalletsNotAddedBack;

  /// Settings > All wallets: tag on the wallet that is open. Short.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get deskSetWalletsOpenNow;

  /// Settings > All wallets: tag on a wallet whose folder is gone. Short.
  ///
  /// In en, this message translates to:
  /// **'Folder missing'**
  String get deskSetWalletsFolderMissing;

  /// Tooltip and screen reader label of the button that opens a wallet’s folder. {name} is the wallet name.
  ///
  /// In en, this message translates to:
  /// **'Show {name} in its folder'**
  String deskSetWalletsShowFolder(String name);

  /// Tooltip and screen reader label of the button that opens the remove dialog. {name} is the wallet name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}…'**
  String deskSetWalletsRemove(String name);

  /// Settings > All wallets: title of the group of wallets removed from the list but whose files still exist.
  ///
  /// In en, this message translates to:
  /// **'Removed from list'**
  String get deskSetWalletsRemovedGroup;

  /// Settings > All wallets: button that puts a removed wallet back into the list.
  ///
  /// In en, this message translates to:
  /// **'Add back'**
  String get deskSetWalletsAddBack;

  /// Settings > All wallets: heading above the cards for creating, importing or restoring a wallet.
  ///
  /// In en, this message translates to:
  /// **'Add a wallet'**
  String get deskSetWalletsAdd;

  /// Settings > All wallets: card title.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet'**
  String get deskSetWalletsCreate;

  /// Settings > All wallets: text of the Create a wallet card.
  ///
  /// In en, this message translates to:
  /// **'A new wallet with a new recovery phrase.'**
  String get deskSetWalletsCreateText;

  /// Settings > All wallets: card title for importing wallets from an older app or a folder.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get deskSetWalletsImport;

  /// Settings > All wallets: text of the Import card.
  ///
  /// In en, this message translates to:
  /// **'From an older Epic Wallet or a folder.'**
  String get deskSetWalletsImportText;

  /// Settings > All wallets: card title for restoring a wallet from its recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get deskSetWalletsRestore;

  /// Settings > All wallets: text of the Restore card.
  ///
  /// In en, this message translates to:
  /// **'From a recovery phrase.'**
  String get deskSetWalletsRestoreText;

  /// Field label and screen reader label on the password step of creating or restoring a wallet: type the password again.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get deskSetupConfirmPassword;

  /// Error under the password field when the new password is shorter than 8 characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get deskSetupPasswordShort;

  /// Error under the confirm field when the two passwords are not the same.
  ///
  /// In en, this message translates to:
  /// **'Passwords differ'**
  String get deskSetupPasswordsDiffer;

  /// Button in the foot of the first-run and setup screens: one step back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deskSetupBack;

  /// Notice on the Unlock screen after a new wallet was created; the wallet is selected below it.
  ///
  /// In en, this message translates to:
  /// **'New wallet added.'**
  String get deskSetupNewWalletAdded;

  /// Warning under a password field while Caps Lock is on. Caps Lock is the key's name as printed on keyboards.
  ///
  /// In en, this message translates to:
  /// **'Caps Lock is on'**
  String get deskSetupCapsLock;

  /// Screen reader announcement of the step a progress list is on, e.g. 'Step 2 of 4: Scanning the chain'.
  ///
  /// In en, this message translates to:
  /// **'Step {number} of {total}: {label}'**
  String deskSetupStepSem(int number, int total, String label);

  /// Button after a step of creating or restoring a wallet failed: run it again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deskSetupTryAgain;

  /// Toast title when the setup's settings could not be saved; the reason follows.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get deskSetupNotSaved;

  /// Setup step and its title: app preferences (the language). Also a section head on the setup's last step. Short: it is in the step list of a narrow side panel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get deskSetupStepPrefs;

  /// Setup step in the side panel's step list (choose the Epic node), and a section head on the last step. One word.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get deskSetupStepNode;

  /// Setup step in the side panel's step list (the Epicbox server for receiving), and a section head on the last step. Epicbox is a product name: keep it.
  ///
  /// In en, this message translates to:
  /// **'Epicbox'**
  String get deskSetupStepEpicbox;

  /// Setup's last step in the side panel's step list: check everything, then save. One word.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get deskSetupStepReview;

  /// Lead under each step's title when setup is opened again from Settings. 'Save' is the button on the last step (deskSetupSave).
  ///
  /// In en, this message translates to:
  /// **'Running setup again. Nothing changes until Save on the last step.'**
  String get deskSetupAgain;

  /// Lead under the title of the setup's Preferences step, which has the language picker.
  ///
  /// In en, this message translates to:
  /// **'App language. It can be changed later.'**
  String get deskSetupPrefsLead;

  /// Title of the setup step where the user picks the Epic node the wallet uses.
  ///
  /// In en, this message translates to:
  /// **'Choose a node'**
  String get deskSetupNodeTitle;

  /// Lead under the title of the setup's node step.
  ///
  /// In en, this message translates to:
  /// **'The wallet reads the chain and sends through an Epic node.'**
  String get deskSetupNodeLead;

  /// Title of the setup step about running the Epic node on this computer.
  ///
  /// In en, this message translates to:
  /// **'Local node'**
  String get deskSetupLocalTitle;

  /// Lead under the title of the setup's local node step.
  ///
  /// In en, this message translates to:
  /// **'What running the node here means, and which node to use.'**
  String get deskSetupLocalLead;

  /// Title of the setup step about the Epicbox server, which holds payments while this wallet is closed.
  ///
  /// In en, this message translates to:
  /// **'Receive when offline'**
  String get deskSetupEpicboxTitle;

  /// Title of the setup's last step: a summary of the choices.
  ///
  /// In en, this message translates to:
  /// **'Check settings'**
  String get deskSetupReviewTitle;

  /// Lead under the title of the setup's last step.
  ///
  /// In en, this message translates to:
  /// **'Change anything that is not right, then save.'**
  String get deskSetupReviewLead;

  /// Title of the setup's side panel, above its step list. Short.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get deskSetupSideTitle;

  /// Button in the setup's side panel when setup was opened again from Settings: leave it without changes.
  ///
  /// In en, this message translates to:
  /// **'Back to wallet'**
  String get deskSetupBackToWallet;

  /// Small note at the foot of the setup's side panel on the first run.
  ///
  /// In en, this message translates to:
  /// **'Everything here can be changed later in Settings.'**
  String get deskSetupLaterNote;

  /// Main button on the setup's last step: save every choice.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get deskSetupSave;

  /// Label of the language picker on the setup's Preferences step, and the row in its summary. The language names in the list stay in their own language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get deskSetupLanguage;

  /// Label of the field where the user picks or types a public Epic node.
  ///
  /// In en, this message translates to:
  /// **'Node server'**
  String get deskSetupNodeServer;

  /// Placeholder in the node picker's search field.
  ///
  /// In en, this message translates to:
  /// **'Find or type a node address'**
  String get deskSetupNodeHint;

  /// Shown in the node picker while the public node list is being checked.
  ///
  /// In en, this message translates to:
  /// **'Checking nodes…'**
  String get deskSetupCheckingNodes;

  /// Shown in the node picker's field before a node is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick a node'**
  String get deskSetupPickNode;

  /// Group head in the node picker's list: public Epic nodes run by others.
  ///
  /// In en, this message translates to:
  /// **'Public nodes'**
  String get deskSetupPublicNodes;

  /// Small line under a node address the user typed that is not one of the public nodes. Lower case: it follows the address.
  ///
  /// In en, this message translates to:
  /// **'not in the public list'**
  String get deskSetupNotInList;

  /// Note under a typed node address in the picker: pressing the Enter key picks it.
  ///
  /// In en, this message translates to:
  /// **'Enter uses it.'**
  String get deskSetupEnterUses;

  /// The node picker's list is empty.
  ///
  /// In en, this message translates to:
  /// **'No nodes to show.'**
  String get deskSetupNoNodes;

  /// Choice card on the setup's node step: use a public node on the internet. Also the node type on the summary step.
  ///
  /// In en, this message translates to:
  /// **'Remote node'**
  String get deskSetupRemoteNode;

  /// Text on the Remote node choice card.
  ///
  /// In en, this message translates to:
  /// **'Any public node. Ready at once.'**
  String get deskSetupRemoteNodeText;

  /// Text on the Local node choice card of the setup's node step.
  ///
  /// In en, this message translates to:
  /// **'Runs the Epic node on this computer. Nothing is shared with an operator. Needs disk space and hours to sync.'**
  String get deskSetupLocalNodeText;

  /// First paragraph of the setup's Epicbox step.
  ///
  /// In en, this message translates to:
  /// **'Epicbox delivers payments to the Epicbox address and holds them until the wallet is online.'**
  String get deskSetupEpicboxText;

  /// Second paragraph of the setup's Epicbox step: a privacy note.
  ///
  /// In en, this message translates to:
  /// **'It does not hide the IP address from the Epicbox server. Use a VPN if that matters.'**
  String get deskSetupEpicboxPrivacy;

  /// Label of the Epicbox server field on the setup's Epicbox step.
  ///
  /// In en, this message translates to:
  /// **'Epicbox server'**
  String get deskSetupEpicboxServer;

  /// Help under the Epicbox server field.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to turn receiving through Epicbox off.'**
  String get deskSetupEpicboxHelp;

  /// Screen reader label of the Change link next to the Preferences section on the setup's summary.
  ///
  /// In en, this message translates to:
  /// **'Change preferences'**
  String get deskSetupChangePrefsSem;

  /// Screen reader label of the Change link next to the Node section on the setup's summary.
  ///
  /// In en, this message translates to:
  /// **'Change node'**
  String get deskSetupChangeNodeSem;

  /// Screen reader label of the Change link next to the Epicbox section on the setup's summary.
  ///
  /// In en, this message translates to:
  /// **'Change epicbox'**
  String get deskSetupChangeEpicboxSem;

  /// Link next to a section on the setup's summary: go back to that step.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get deskSetupChange;

  /// Row label on the setup's summary: what kind of node. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get deskSetupType;

  /// Row label on the setup's summary: the node's address. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get deskSetupAddress;

  /// Node type on the setup's summary: an Epic node already running on this computer.
  ///
  /// In en, this message translates to:
  /// **'Existing node at {host}'**
  String deskSetupExistingNode(String host);

  /// Node type on the setup's summary: the Epic node that comes with the app, run on this computer.
  ///
  /// In en, this message translates to:
  /// **'Local node, bundled'**
  String get deskSetupBundledNode;

  /// Row label on the setup's summary: which node the wallet uses while the local node syncs. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'While syncing'**
  String get deskSetupWhileSyncing;

  /// Value of the While syncing row when the wallet waits for the local node instead of using a public one. Lower case, one word.
  ///
  /// In en, this message translates to:
  /// **'wait'**
  String get deskSetupWait;

  /// Row label on the setup's summary: where the local node keeps the chain. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Data folder'**
  String get deskSetupDataFolder;

  /// Note under the Node section of the setup's summary when the local node is chosen and a public node is used while it syncs.
  ///
  /// In en, this message translates to:
  /// **'Save starts the node. The first sync takes hours; the wallet opens meanwhile and uses {node} until then.'**
  String deskSetupSaveStartsFallback(String node);

  /// Note under the Node section of the setup's summary when the local node is chosen and the wallet waits for it.
  ///
  /// In en, this message translates to:
  /// **'Save starts the node. The first sync takes hours; the wallet opens meanwhile.'**
  String get deskSetupSaveStarts;

  /// Row label on the setup's summary: the Epicbox server. Narrow label column.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get deskSetupServer;

  /// Value of the Epicbox server row when no server is set: receiving through Epicbox is off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deskSetupOff;

  /// Settings › About › Licences: the paragraph before the list of components. The phone's version says 'tap' (licencesLead).
  ///
  /// In en, this message translates to:
  /// **'Open-source software in this wallet. Each component keeps its own licence; the full texts are one click away.'**
  String get deskSetAboutLicencesLead;

  /// Settings › About › Licences: the app's own licence. Epic Cash Desktop, BT Labs, Apache-2.0 and GitHub are names: keep them.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash Desktop by BT Labs: Apache-2.0.'**
  String get deskSetAboutLicenceApp;

  /// Toast title when a link could not be opened in the web browser; the link follows.
  ///
  /// In en, this message translates to:
  /// **'Browser not opened'**
  String get deskSetAboutBrowserNotOpened;

  /// Small button on a link row of Settings › About: open the link in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get deskSetAboutOpen;

  /// Settings › About: the app's version, e.g. 'Version  26.10.2 · core 0.1.0'. Two spaces before the value, as in the English.
  ///
  /// In en, this message translates to:
  /// **'Version  {version}'**
  String deskSetAboutVersion(String version);

  /// Settings › About: the version of the Epic node the wallet uses, or '-'. Two spaces before the value, as in the English.
  ///
  /// In en, this message translates to:
  /// **'Node  {version}'**
  String deskSetAboutNode(String version);

  /// Settings › About: group head of the Epic Cash community links (Telegram, epiccash.com).
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get deskSetAboutCommunity;

  /// Settings › About: group head of the open-source licences.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get deskSetAboutLicences;

  /// Settings › About › Licences: row with the link to the app's source code.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get deskSetAboutSource;

  /// Small button on the All licence texts row: open the page with every licence text.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get deskSetAboutView;

  /// Settings › About › Updates: when the app last asked for updates, e.g. 'Checked 5 min ago.' or 'Checked just now.' The {ago} part comes from deskSetAboutAgo*.
  ///
  /// In en, this message translates to:
  /// **'Checked {ago}.'**
  String deskSetAboutChecked(String ago);

  /// Settings › About › Updates: this version is the newest.
  ///
  /// In en, this message translates to:
  /// **'{version} is the latest'**
  String deskSetAboutLatest(String version);

  /// Settings › About › Updates: a newer version exists.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version}'**
  String deskSetAboutAvailable(String version);

  /// Settings › About › Updates: the update check failed; the reason follows.
  ///
  /// In en, this message translates to:
  /// **'Could not check'**
  String get deskSetAboutCouldNotCheck;

  /// Settings › About: group head of the update check.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get deskSetAboutUpdates;

  /// Button: open the download page of the newer version.
  ///
  /// In en, this message translates to:
  /// **'Get {version}'**
  String deskSetAboutGet(String version);

  /// Button: check for updates now.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get deskSetAboutCheckNow;

  /// Fills {ago} in deskSetAboutChecked: less than a minute ago. Lower case.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get deskSetAboutAgoNow;

  /// Fills {ago} in deskSetAboutChecked: minutes ago (1 to 59). Lower case; 'min' is the short unit.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String deskSetAboutAgoMin(int count);

  /// Fills {ago} in deskSetAboutChecked: hours ago (1 to 23). Lower case; 'h' is the short unit.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String deskSetAboutAgoHours(int count);

  /// Fills {ago} in deskSetAboutChecked: days ago. Lower case; 'd' is the short unit.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String deskSetAboutAgoDays(int count);

  /// Tooltip and screen reader label of the small copy icon beside a link.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get deskSetAboutCopyLink;

  /// Shown in place of Copy link for a moment after the link was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get deskSetAboutCopied;

  /// Shown in place of Copy link for a moment when copying failed.
  ///
  /// In en, this message translates to:
  /// **'Not copied'**
  String get deskSetAboutNotCopied;

  /// Settings › Appearance row: light or dark colours.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get deskSetAppearTheme;

  /// Hint under the Theme row. 'System' is the first choice (deskSetAppearSystem).
  ///
  /// In en, this message translates to:
  /// **'System follows the computer’s setting.'**
  String get deskSetAppearThemeHint;

  /// Theme choice: follow the computer's light or dark setting. One short word: a segment of a three-part switch.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get deskSetAppearSystem;

  /// Theme choice: dark colours. One short word: a segment of a three-part switch.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get deskSetAppearDark;

  /// Theme choice: light colours. One short word: a segment of a three-part switch.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get deskSetAppearLight;

  /// Settings › Appearance row: make text and controls larger or smaller (90 % to 150 %).
  ///
  /// In en, this message translates to:
  /// **'Interface scale'**
  String get deskSetAppearScale;

  /// Hint under the Interface scale row.
  ///
  /// In en, this message translates to:
  /// **'Text and controls, larger or smaller. Applies at once.'**
  String get deskSetAppearScaleHint;

  /// Settings › Appearance row: the language of the app. The language names in its list stay in their own language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get deskSetAppearLanguage;

  /// Hint under the Language row: no restart needed.
  ///
  /// In en, this message translates to:
  /// **'Applies at once.'**
  String get deskSetAppearLanguageHint;

  /// Hint under the Hide amounts row (the row's title is deskOvHideAmounts).
  ///
  /// In en, this message translates to:
  /// **'Shows dots in place of balances and amounts.'**
  String get deskSetAppearHideHint;

  /// Help search: nothing matches what the user typed. Use the language's own quotation marks around {query}.
  ///
  /// In en, this message translates to:
  /// **'No topic matches “{query}”. Try another word.'**
  String deskSetHelpNoMatchText(String query);

  /// Help search: how many topics match, read out by screen readers too, e.g. 'Topics found: 3'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Topics found: {count}} other{Topics found: {count}}}'**
  String deskSetHelpFound(int count);

  /// Title of the empty state of the Help search.
  ///
  /// In en, this message translates to:
  /// **'No topic matches'**
  String get deskSetHelpNoMatch;

  /// Help page, the Report a problem card: what the report does. 'Save to file' is a button in the report dialog.
  ///
  /// In en, this message translates to:
  /// **'Describe what went wrong. The app log can go with it, cleaned of secrets and encrypted to the developer. Save to file keeps a copy to send by hand.'**
  String get deskSetHelpReportText;

  /// Link under an opened Help topic: fold it again.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get deskSetHelpShowLess;

  /// Link under a Help topic's first lines: open the rest.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get deskSetHelpReadMore;

  /// Help, 'How a transaction travels' over Epicbox, step 1 of 6.
  ///
  /// In en, this message translates to:
  /// **'The sending wallet passes the payment to Epicbox and locks the outputs.'**
  String get deskSetHelpEb1;

  /// Help, 'How a transaction travels' over Epicbox, step 2 of 6.
  ///
  /// In en, this message translates to:
  /// **'Epicbox delivers it when the receiving wallet is online. That wallet adds its part and signs.'**
  String get deskSetHelpEb2;

  /// Help, 'How a transaction travels' over Epicbox, step 3 of 6.
  ///
  /// In en, this message translates to:
  /// **'The receiving wallet sends it back to Epicbox.'**
  String get deskSetHelpEb3;

  /// Help, 'How a transaction travels' over Epicbox, step 4 of 6.
  ///
  /// In en, this message translates to:
  /// **'Epicbox passes it back to the sending wallet.'**
  String get deskSetHelpEb4;

  /// Help, 'How a transaction travels', step 5 of 6 (over Epicbox and with a file).
  ///
  /// In en, this message translates to:
  /// **'The sending wallet signs too, finishes the transaction and posts it to the network.'**
  String get deskSetHelpSigns;

  /// Help, 'How a transaction travels', the last step: how many confirmations the wallet waits for.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{The network puts it in a block. After {count} confirmation it is final.} other{The network puts it in a block. After {count} confirmations it is final.}}'**
  String deskSetHelpFinal(int count);

  /// Help, 'How a transaction travels' with a file, step 1 of 6.
  ///
  /// In en, this message translates to:
  /// **'The sending wallet saves a transaction file and locks the outputs. The file goes to the recipient by any means.'**
  String get deskSetHelpFile1;

  /// Help, 'How a transaction travels' with a file, step 2 of 6.
  ///
  /// In en, this message translates to:
  /// **'The recipient opens it. Their wallet adds its part, signs and saves a response file.'**
  String get deskSetHelpFile2;

  /// Help, 'How a transaction travels' with a file, step 3 of 6.
  ///
  /// In en, this message translates to:
  /// **'The response file comes back to the sender.'**
  String get deskSetHelpFile3;

  /// Help, 'How a transaction travels' with a file, step 4 of 6. 'Finalize' is the name of the page in the sidebar: use its translation.
  ///
  /// In en, this message translates to:
  /// **'The sender opens the response file under Finalize.'**
  String get deskSetHelpFile4;

  /// Tag in the 'How a transaction travels' diagram: the sending wallet. One short word.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get deskSetHelpSender;

  /// Tag in the 'How a transaction travels' diagram: the transaction file in between. One short word.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskSetHelpFile;

  /// Tag in the 'How a transaction travels' diagram: the receiving wallet. One short word.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get deskSetHelpRecipient;

  /// Tag in the 'How a transaction travels' diagram: the Epic Cash network. One short word.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get deskSetHelpNetwork;

  /// Title of the step-by-step diagram on the Help page.
  ///
  /// In en, this message translates to:
  /// **'How a transaction travels'**
  String get deskSetHelpTravels;

  /// Switch segment of the diagram: the way through the Epicbox server. Short.
  ///
  /// In en, this message translates to:
  /// **'Over Epicbox'**
  String get deskSetHelpOverEpicbox;

  /// Switch segment of the diagram: the way with a transaction file. Short.
  ///
  /// In en, this message translates to:
  /// **'With a file'**
  String get deskSetHelpWithFile;

  /// Under the diagram: which step is shown, e.g. 'Step 2 of 6'.
  ///
  /// In en, this message translates to:
  /// **'Step {number} of {total}'**
  String deskSetHelpStep(int number, int total);

  /// Label and screen reader label of the search field on the Help page.
  ///
  /// In en, this message translates to:
  /// **'Search help'**
  String get deskSetHelpSearch;

  /// Help under the Help page's search field: the / key moves to the search, the Esc key clears it. Keep / and Esc as keys.
  ///
  /// In en, this message translates to:
  /// **'Press / to search. Esc clears the search.'**
  String get deskSetHelpSearchKeys;

  /// Placeholder in the Help search field: three example words a user might search for (the transaction file, confirmations, the recovery phrase). Use the words the app uses.
  ///
  /// In en, this message translates to:
  /// **'For example: file, confirmations, phrase'**
  String get deskSetHelpSearchHint;

  /// Tooltip and screen reader label of the x button in the Help search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get deskSetHelpClear;

  /// Button on the Help page: start the first-run guided tour of the app again.
  ///
  /// In en, this message translates to:
  /// **'Show the tour again'**
  String get deskSetHelpTourAgain;

  /// Small count at the right of a Help section's head, e.g. '4 topics'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} topic} other{{count} topics}}'**
  String deskSetHelpTopics(int count);

  /// Error when Windows (DPAPI) refused to protect the wallet's secrets, e.g. in a remote or service session. DPAPI and Windows are names.
  ///
  /// In en, this message translates to:
  /// **'Windows could not protect the wallet’s secrets (DPAPI refused), so nothing was saved. Sign in to Windows with your own account and its password, not through a remote or service session, then try again.'**
  String get deskErrSecretProtect;

  /// Desktop, Linux, first screen: the system has no usable keyring (Secret Service) to keep the wallet's secrets.
  ///
  /// In en, this message translates to:
  /// **'No keyring found'**
  String get deskKeyringMissingTitle;

  /// Desktop, Linux: what is missing and what to do. Names the keyring programs; Retry is the commonRetry button.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash keeps its settings and your wallet\'s sealed password in the system keyring, and none answered. Install or start a keyring (GNOME Keyring or KWallet), sign in to a desktop session that runs one, then choose Retry.'**
  String get deskKeyringMissingText;

  /// Desktop, Linux, first screen: the system keyring exists but is locked.
  ///
  /// In en, this message translates to:
  /// **'The keyring is locked'**
  String get deskKeyringLockedTitle;

  /// Desktop, Linux: the keyring is locked. Retry is commonRetry; 'Unlock now' is deskKeyringUnlockNow.
  ///
  /// In en, this message translates to:
  /// **'Epic Cash keeps its settings and your wallet\'s sealed password in the system keyring, which is locked. Unlock it (it opens with your login password), then choose Retry, or choose Unlock now to have the system ask for it.'**
  String get deskKeyringLockedText;

  /// Desktop, Linux, locked keyring: go on, and the system asks for the keyring's password.
  ///
  /// In en, this message translates to:
  /// **'Unlock now'**
  String get deskKeyringUnlockNow;

  /// Status chip of an Epicbox payment no attempt has delivered to the relay.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get txStatusNotDelivered;

  /// Explanation under the status of a payment that was not delivered.
  ///
  /// In en, this message translates to:
  /// **'This payment did not reach the epicbox yet, so the recipient has not received it. Your funds stay locked until it is sent again or cancelled.'**
  String get txDetailsNotDeliveredBody;

  /// Notice after the payment was sent again.
  ///
  /// In en, this message translates to:
  /// **'Sent again. It completes when their wallet comes online.'**
  String get txDetailsSendAgainDone;

  /// Activity and payment detail: who the other side is for a split or consolidation, where both sides are this wallet. Short, it sits in the name column.
  ///
  /// In en, this message translates to:
  /// **'This wallet'**
  String get deskTxThisWallet;

  /// Import of an old wallet: why it cannot be imported. Its folder contains links (symlinks, junctions); the user can copy the folder by hand or restore from the recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'This wallet\'s folder has links in it; copy it by hand or restore from the phrase.'**
  String get deskErrOldLinks;

  /// Import of an old wallet: why it cannot be imported. Its folder is too big to check or a part could not be read; the user can copy it by hand or restore from the recovery phrase.
  ///
  /// In en, this message translates to:
  /// **'This wallet\'s folder could not be read completely; copy it by hand or restore from the phrase.'**
  String get deskErrOldIncomplete;

  /// Import of an old wallet: why it cannot be imported. wallet.seed is a file name and stays as written.
  ///
  /// In en, this message translates to:
  /// **'The wallet.seed file is too large to be a wallet seed.'**
  String get deskErrOldSeedTooLarge;

  /// Error when a send or split cannot be made from the wallet's spendable outputs (the core refused it). Nothing was sent.
  ///
  /// In en, this message translates to:
  /// **'This send cannot be built from the coins available.'**
  String get deskErrSendUnbuildable;

  /// Error when Consolidate is asked with fewer than two spendable outputs. Nothing was changed.
  ///
  /// In en, this message translates to:
  /// **'Nothing to consolidate: fewer than two spendable outputs.'**
  String get deskErrNothingToConsolidate;

  /// Report a problem › What is sent: a log file that does not go with the report. {name} is the file name.
  ///
  /// In en, this message translates to:
  /// **'{name} (not included)'**
  String deskSetReportFileNone(String name);

  /// Report a problem › What is sent: a log file that goes with the report whole. {size} is its size.
  ///
  /// In en, this message translates to:
  /// **'{name} (all, {size})'**
  String deskSetReportFileAll(String name, String size);

  /// Report a problem › What is sent: only the end of a log file goes with the report. {part} is how much, {size} the whole file.
  ///
  /// In en, this message translates to:
  /// **'{name} (last {part} of {size})'**
  String deskSetReportFilePart(String name, String part, String size);

  /// Error when the wallet cannot find the transaction it was asked to send again.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get deskErrTxNotFound;

  /// Payment detail, the line under the status of a send that never reached the Epicbox server ("epicbox" here means that server). Send again and Cancel are buttons below it.
  ///
  /// In en, this message translates to:
  /// **'Not delivered. The payment did not reach the epicbox, so the recipient has not received it. Send it again, or cancel it to free the funds.'**
  String get deskTxNowUndelivered;

  /// Status of a send that never reached the Epicbox server, in the Activity list and payment detail. Short: a table cell.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get deskTxStatusUndelivered;

  /// Button in the payment detail of an undelivered send: send it to the Epicbox server again.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get deskTxSendAgain;

  /// Toast title when Send again failed; the reason follows.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get deskTxNotSent;

  /// Toast title after Send again worked.
  ///
  /// In en, this message translates to:
  /// **'Sent again'**
  String get deskTxSentAgain;

  /// Toast text after Send again worked.
  ///
  /// In en, this message translates to:
  /// **'It completes when the recipient’s wallet comes online.'**
  String get deskTxSentAgainText;

  /// Title of the notice in the Check and send dialog when the fee moved after the review was opened (an output finished confirming or was locked).
  ///
  /// In en, this message translates to:
  /// **'The fee changed'**
  String get deskSendFeeChangedTitle;

  /// Text of that notice. {fee} is the new network fee, {was} the fee the dialog showed before, both in EPIC.
  ///
  /// In en, this message translates to:
  /// **'The wallet\'s outputs changed since this review, so the send now pays {fee} EPIC instead of {was} EPIC. Check it and send again.'**
  String deskSendFeeChangedText(String fee, String was);

  /// Counter next to the Message label on Send: the message length in UTF-8 bytes (an emoji takes 4) and the limit.
  ///
  /// In en, this message translates to:
  /// **'{used} / {max} bytes'**
  String deskSendMessageBytes(int used, int max);

  /// Error under the Message field on Send when the message is over the limit, in UTF-8 bytes.
  ///
  /// In en, this message translates to:
  /// **'The message is longer than {max} bytes. Shorten it.'**
  String deskSendMessageTooLong(int max);

  /// Confirm dialog title before the recovery phrase is copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy the recovery phrase?'**
  String get deskSetPhraseCopyTitle;

  /// Confirm dialog text before the recovery phrase is copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Anyone with these words can take your funds. Store the copy somewhere safe.'**
  String get deskSetPhraseCopyText;

  /// Head of the management section under the outputs table: the intro paragraph, Split and Consolidate, the defaults for sends.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get deskOutAdvanced;

  /// Hover card behind the info icon of the Strategy for sends row (its title is deskOutStrategyHelpTitle).
  ///
  /// In en, this message translates to:
  /// **'Which outputs a send spends. Smallest spends the fewest small outputs and leaves the rest spendable; All spends everything and returns one output. Send can change it for one send under Advanced.'**
  String get deskOutStrategyHint;

  /// Status of a finished payment the node refused: it is not on the network until it is broadcast again.
  ///
  /// In en, this message translates to:
  /// **'Not on the network'**
  String get txStatusNotPosted;

  /// Status of a paid invoice whose payment has not reached the network a while after paying, though the wallet sent it again by itself.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get txStatusStalled;

  /// Explanation under the status of a stalled invoice payment; Send again is a button below.
  ///
  /// In en, this message translates to:
  /// **'Stalled, not delivered. Your payment has not reached the network yet. Send it again.'**
  String get txDetailsStalledBody;

  /// Explanation under the status of an HTTP or Tor payment that was not delivered (the recipient's wallet did not answer).
  ///
  /// In en, this message translates to:
  /// **'This payment did not reach the recipient\'s wallet, so they have not received it. Your funds stay locked until it is sent again or cancelled.'**
  String get txDetailsNotDeliveredDirectBody;

  /// Paid invoice in the payment's details: the service still has not posted the payment a while after paying. service is the user's label for the service.
  ///
  /// In en, this message translates to:
  /// **'{service} has not posted your payment yet.'**
  String invoiceDetailsStalled(String service);

  /// Activity row status: a finished send the node refused; it is not on the network until it is broadcast again.
  ///
  /// In en, this message translates to:
  /// **'Not on the network'**
  String get deskTxStatusNotPosted;

  /// Payment detail, the line under the status of a finished send the node refused. Broadcast again is a button below; the wallet also retries by itself.
  ///
  /// In en, this message translates to:
  /// **'Not on the network. The node did not take this payment. Broadcast it again; it cannot go through twice.'**
  String get deskTxNowNotPosted;

  /// Button on the payment detail of a send the node refused: posts it to the node again.
  ///
  /// In en, this message translates to:
  /// **'Broadcast again'**
  String get deskTxBroadcastAgain;

  /// Toast after Broadcast again worked.
  ///
  /// In en, this message translates to:
  /// **'Sent to the network'**
  String get deskTxBroadcastDone;

  /// Payment detail, the line under the status of a Direct send that never reached the other wallet. method is HTTP or Tor. Send again and Cancel are buttons below it.
  ///
  /// In en, this message translates to:
  /// **'Not delivered. The recipient\'s wallet did not take the payment over {method}, so they have not received it. Send it again, or cancel it to free the funds.'**
  String deskTxNowUndeliveredDirect(String method);

  /// State of an invoice you paid: the payment has not reached the network a while after paying, though the wallet sent it again by itself.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get deskInvPayStalled;

  /// Notice on To pay: a paid invoice whose payment has not reached the network a while after paying. service is the user's label for the service.
  ///
  /// In en, this message translates to:
  /// **'Your payment to {service} is stalled'**
  String deskInvPayerStalledTitle(String service);

  /// Notice text and Invoice block text for a stalled invoice payment. Send again is a button.
  ///
  /// In en, this message translates to:
  /// **'Not delivered: it has not reached the network yet, and the funds stay locked. Send again sends it once more without a second approval.'**
  String get deskInvPayerStalledText;

  /// Tooltip and screen-reader name of the pen on an Activity row or details title that has no label yet; also the ghost button in the details sub-header.
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get deskTxLabelAdd;

  /// Tooltip and screen-reader name of the pen when the payment has a label; also the ghost button in the details sub-header.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get deskTxLabelEdit;

  /// Placeholder of the inline label field while it is empty.
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get deskTxLabelHint;

  /// Screen-reader name of the inline label field, and the name of the field in the Details differ dialog.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get deskTxLabelField;

  /// Tooltip on the label pen: what a label is.
  ///
  /// In en, this message translates to:
  /// **'A name for this payment, for you. Shown in Activity and exports.'**
  String get deskTxLabelTip;

  /// Toast title after a label was added.
  ///
  /// In en, this message translates to:
  /// **'Label added'**
  String get deskTxLabelAdded;

  /// Toast title after a label was changed.
  ///
  /// In en, this message translates to:
  /// **'Label saved'**
  String get deskTxLabelSaved;

  /// Toast title after a label was emptied and removed.
  ///
  /// In en, this message translates to:
  /// **'Label removed'**
  String get deskTxLabelRemoved;

  /// Toast title when saving a label failed; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Label not saved'**
  String get deskTxLabelNotSaved;

  /// Ghost button in the details sub-header of a payment a scan found: opens the dialog to add what the user knows.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get deskTxDetailsAdd;

  /// Short ghost button in the details sub-header when details were added already.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deskTxDetailsEdit;

  /// Title of the dialog where the user adds details to a payment a scan found.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get deskTxDetailsTitleAdd;

  /// Title of the dialog when details exist already.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get deskTxDetailsTitleEdit;

  /// Description under the details dialog title, and tooltip on the details button: what it is for.
  ///
  /// In en, this message translates to:
  /// **'Only for payments found by a scan. Shown as added by you in Activity, details and exports. Amounts, dates and confirmations do not change.'**
  String get deskTxDetailsTip;

  /// Field name in the details dialog: who paid.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get deskTxDetailsFrom;

  /// Tooltip on the From field of the details dialog.
  ///
  /// In en, this message translates to:
  /// **'Who paid, for your records. Not verified and never used for payment proofs.'**
  String get deskTxDetailsFromTip;

  /// Placeholder of the From field in the details dialog.
  ///
  /// In en, this message translates to:
  /// **'Address of the sender'**
  String get deskTxDetailsFromHint;

  /// Shown under the From field when the text is not an address the wallet knows.
  ///
  /// In en, this message translates to:
  /// **'Use an Epicbox, http(s) or .onion address.'**
  String get deskTxDetailsFromBad;

  /// Field name in the details dialog and the details list: the private note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get deskTxDetailsNote;

  /// Toast title after details were added to a payment.
  ///
  /// In en, this message translates to:
  /// **'Details added'**
  String get deskTxDetailsAdded;

  /// Toast title after details were changed.
  ///
  /// In en, this message translates to:
  /// **'Details saved'**
  String get deskTxDetailsSaved;

  /// Toast title after every detail was cleared.
  ///
  /// In en, this message translates to:
  /// **'Details removed'**
  String get deskTxDetailsRemoved;

  /// Toast title when saving details failed; the reason follows as its text.
  ///
  /// In en, this message translates to:
  /// **'Details not saved'**
  String get deskTxDetailsNotSaved;

  /// Tag next to a value the user typed (label, sender, method, note).
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get deskTxManualTag;

  /// Tooltip on the Added by you tag when the time of the change is known.
  ///
  /// In en, this message translates to:
  /// **'Added by you on {date}. Not from the chain.'**
  String deskTxManualTip(String date);

  /// Tooltip on the Added by you tag when the time of the change is not known.
  ///
  /// In en, this message translates to:
  /// **'Added by you. Not from the chain.'**
  String get deskTxManualTipNoDate;

  /// Tooltip on the Added by you tag of the From value when the time of the change is known.
  ///
  /// In en, this message translates to:
  /// **'Added by you on {date}. Not from the chain, not verified.'**
  String deskTxManualTipFrom(String date);

  /// Tooltip on the Added by you tag of the From value when the time of the change is not known.
  ///
  /// In en, this message translates to:
  /// **'Added by you. Not from the chain, not verified.'**
  String get deskTxManualTipFromNoDate;

  /// Title of the dialog shown when a history backup disagrees with what the user typed.
  ///
  /// In en, this message translates to:
  /// **'Details differ'**
  String get deskHistConflictTitle;

  /// Description of the Details differ dialog; n payments.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{The backup has other details for {n} payment you described. Yours are kept unless you choose otherwise.} other{The backup has other details for {n} payments you described. Yours are kept unless you choose otherwise.}}'**
  String deskHistConflictLead(int n);

  /// Choice card in the Details differ dialog: the value typed here.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get deskHistConflictMine;

  /// Choice card in the Details differ dialog: the value in the backup file.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get deskHistConflictBackup;

  /// Button in the Details differ dialog: import and keep every value the user typed.
  ///
  /// In en, this message translates to:
  /// **'Keep all mine'**
  String get deskHistConflictKeepAll;

  /// Primary button in the Details differ dialog: import with the choices made.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get deskHistConflictImport;

  /// Placeholder, in italics, where a value in the Details differ dialog is empty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get deskHistConflictEmpty;

  /// Line on the import result: how many typed details the user replaced with the backup's.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} detail replaced, the rest kept as yours.} other{{n} details replaced, the rest kept as yours.}}'**
  String deskHistImportedReplaced(int n);

  /// Send, review: the recipient's relay (the part of the address after @) is not one the app knows from its public list or the user's servers, so the address may be mistyped. A warning; sending is still allowed. {relay} is its host name.
  ///
  /// In en, this message translates to:
  /// **'{relay} isn\'t a server this app knows. Check the address before you send.'**
  String sendRelayUnknown(String relay);

  /// A payment could not be handed to the recipient's relay: it did not answer (a failed Send again). {relay} is the relay's host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'{relay} did not answer.'**
  String relayNoAnswer(String relay);

  /// Explanation under the status of a payment that was not delivered, naming the relay that did not answer. {relay} is its host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'{relay} did not answer, so the recipient has not received this payment. Your funds stay locked until it is sent again or cancelled.'**
  String txDetailsNotDeliveredRelayBody(String relay);

  /// Why an Epicbox send failed: the recipient's relay did not answer; the payment waits in Activity. {relay} is its host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'Not delivered: {relay} did not answer. The payment waits in Activity; cancel it there to unlock the funds.'**
  String deskErrNotDeliveredRelay(String relay);

  /// An error message the user reads when Send again to an Epicbox address fails because the recipient's relay did not answer. {relay} is its host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'{relay} did not answer.'**
  String deskErrRelayNoAnswer(String relay);

  /// Send review: title of the warning that the recipient's Epicbox server is not one the app knows.
  ///
  /// In en, this message translates to:
  /// **'Unknown Epicbox server'**
  String get deskSendRelayUnknownTitle;

  /// Send review: the recipient's Epicbox server (the part of the address after @) is not in the app's public list or among the user's servers, so the address may be mistyped. A warning; sending is still allowed. {relay} is its host name.
  ///
  /// In en, this message translates to:
  /// **'{relay} is not a server this app knows. Check the address before you send. You can still send.'**
  String deskSendRelayUnknownText(String relay);

  /// Transaction detail, 'what is happening now' for a payment that was not delivered, naming the relay that did not answer. {relay} is its host name, as in the address.
  ///
  /// In en, this message translates to:
  /// **'Not delivered. {relay} did not answer, so the recipient has not received the payment. Send it again, or cancel it to free the funds.'**
  String deskTxNowUndeliveredRelay(String relay);

  /// Notice (desktop and phone): another install on the same recovery phrase answered the same incoming payment and the sender completed that one, so this install's copy of the receive ended. 'Recheck balance' is the name of the rescan action in Settings.
  ///
  /// In en, this message translates to:
  /// **'Your other device with this wallet took a payment this device was also receiving. Recheck balance to see it here.'**
  String get deskInvNoticeReceiveSuperseded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'pl',
    'ru',
    'th',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
