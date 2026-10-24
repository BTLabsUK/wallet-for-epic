import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';
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

  /// Payment details, why a send is cancelled: the user cancelled it before it was sent.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Nothing was sent, and the funds are spendable again.'**
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
  /// **'The recipient did not answer within 14 days, so the wallet cancelled it. Nothing was sent, and the funds are spendable again.'**
  String get txDetailsCancelledUnanswered;

  /// Payment details, why a send is cancelled: the answer came too late.
  ///
  /// In en, this message translates to:
  /// **'The recipient answered after the 14-day limit, so the wallet cancelled it instead of finishing it. Nothing was sent, and the funds are spendable again.'**
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

  /// Button: start a new payment to the same address.
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
  /// **'Epic Cash Mobile by BT Labs: Apache-2.0. The code is on GitHub.'**
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
  /// **'Fonts Montserrat and JetBrains Mono: SIL Open Font License 1.1.'**
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

  /// Send, review: the recipient's message relay does not answer, so the payment may not arrive; paying with a file is offered.
  ///
  /// In en, this message translates to:
  /// **'Their relay isn\'t answering.'**
  String get sendRelayDown;

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

  /// Send, review: the send failed at the recipient's relay; the wallet keeps the payment with its coins on hold until it is cancelled, and cancels it by itself after {days} days.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Their relay didn\'t take it. The amount is on hold until you cancel it, or for at most 1 day.} other{Their relay didn\'t take it. The amount is on hold until you cancel it, or for at most {days} days.}}'**
  String sendRelayRefused(int days);

  /// Send, review: the send failed at the recipient's relay and the app could not find the payment it may have left; the user should look in Wallet before trying again.
  ///
  /// In en, this message translates to:
  /// **'Their relay didn\'t take it. Check Wallet before you send again.'**
  String get sendRelayRefusedLost;

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

  /// Tooltip and screen reader name of the remove button on a My servers row of the Epicbox picker.
  ///
  /// In en, this message translates to:
  /// **'Remove from my servers'**
  String get serverRemoveRelay;

  /// Tooltip of the disabled remove button (Epicbox) or star (node) on the server the wallet uses now: why it cannot be removed.
  ///
  /// In en, this message translates to:
  /// **'In use. Switch to another server first.'**
  String get serverRemoveInUse;

  /// Title of the dialog that confirms removing an Epicbox relay from My servers.
  ///
  /// In en, this message translates to:
  /// **'Remove this server?'**
  String get serverRemoveRelayTitle;

  /// Title of the dialog that confirms removing a node from My nodes (the star of a My nodes row).
  ///
  /// In en, this message translates to:
  /// **'Remove this node?'**
  String get serverRemoveNodeTitle;

  /// Body of the dialogs that confirm removing a node or an Epicbox relay from the user's own list.
  ///
  /// In en, this message translates to:
  /// **'{host} leaves this list. Type it in again to use it later.'**
  String serverRemoveBody(String host);

  /// Confirm button of the remove dialogs.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get serverRemoveConfirm;

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

  /// Star button: add the node to My nodes.
  ///
  /// In en, this message translates to:
  /// **'Add to my nodes'**
  String get serverAddMine;

  /// Star button: remove the node from My nodes.
  ///
  /// In en, this message translates to:
  /// **'Remove from my nodes'**
  String get serverRemoveMine;

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

  /// Warning notice (desktop and phone): LEPIC refused the payment of an invoice it does not know; another install on the same recovery phrase may have issued it. Unverified: names no sender.
  ///
  /// In en, this message translates to:
  /// **'A payment for an invoice this device did not issue arrived and was refused. If another device with this wallet issued it, ask the payer to cancel and pay again.'**
  String get deskInvNoticeUnknownPayment;

  /// Warning notice (desktop and phone): LEPIC refused the answer to a send it does not know; another install on the same recovery phrase may have made it. Unverified: names no sender.
  ///
  /// In en, this message translates to:
  /// **'An answer to a payment this device did not send arrived and was refused. If another device with this wallet sent it, cancel it there and send again.'**
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
  /// **'The clipboard is cleared in 30 s.'**
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

  /// Delete chain data dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Delete chain data?'**
  String get deskSetLndDeleteQuestion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'pl', 'ru', 'zh'].contains(locale.languageCode);

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
