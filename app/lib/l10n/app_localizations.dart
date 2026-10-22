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

  /// The app's name in the task switcher and window title. A product name; do not translate.
  ///
  /// In en, this message translates to:
  /// **'Epic Wallet'**
  String get appTitle;

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
  /// **'Epic Wallet'**
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
  /// **'Your address'**
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

  /// Android opened its settings screen for installing apps from this source. 'Update' is the updateInstallButton label: use the same word.
  ///
  /// In en, this message translates to:
  /// **'Allow this app to install updates in the screen that opened, then tap Update again.'**
  String get updateNeedsPermission;

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

  /// Title of the screen that picks the network, the node and the epicbox server.
  ///
  /// In en, this message translates to:
  /// **'Network settings'**
  String get setupTitle;

  /// Tooltip of the icon button on the welcome and unlock screens that opens the network settings.
  ///
  /// In en, this message translates to:
  /// **'Network settings'**
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
  /// **'Epicbox address'**
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
  /// **'Enter their epicbox address.'**
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

  /// Section heading in settings.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsSectionNetwork;

  /// Settings row that opens the network setup. The node is the Epic Cash server the wallet reads the chain from.
  ///
  /// In en, this message translates to:
  /// **'Network and node'**
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

  /// Settings switch for push notifications about incoming payments.
  ///
  /// In en, this message translates to:
  /// **'Payment notifications'**
  String get settingsPaymentNotifications;

  /// Under the payment notifications switch. Google Firebase is a proper name.
  ///
  /// In en, this message translates to:
  /// **'Delivered by Google Firebase.'**
  String get settingsPushHint;

  /// Notice after payment notifications are turned on. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'No epicbox server sends them yet. Open the app to receive a payment.'**
  String get settingsPushOnNotice;

  /// Notice after payment notifications are turned off.
  ///
  /// In en, this message translates to:
  /// **'Notifications stop the next time the app starts.'**
  String get settingsPushOffNotice;

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

  /// Hint under the invoice settings row.
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

  /// Under the Send feedback row.
  ///
  /// In en, this message translates to:
  /// **'Report a problem or suggest an idea'**
  String get settingsSendFeedbackHint;

  /// Settings row with the link to the app's source code.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSourceCode;

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

  /// A question on the help page. Quote the status chip's text exactly as txStatusWaitingRecipient translates it.
  ///
  /// In en, this message translates to:
  /// **'Why does my payment say \"Waiting for recipient\"?'**
  String get helpWaitingQuestion;

  /// Answer on the help page. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'An Epic Cash payment is built by both wallets together: yours starts it, the recipient\'s wallet accepts it, then yours finishes it. Epic\'s epicbox service holds your payment for about a week, until the recipient\'s wallet comes online and answers. Until then the amount stays locked in your wallet, so you cannot spend it twice. If the payment is not completed, your wallet cancels it by itself after {days, plural, =1{1 day} other{{days} days}} and unlocks the amount.'**
  String helpWaitingAnswer(int days);

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'Should I cancel a payment?'**
  String get helpCancellingQuestion;

  /// Answer on the help page. "Waiting for recipient" is the status chip (txStatusWaitingRecipient) and Cancel payment the button on the payment's details screen: use the same words as those.
  ///
  /// In en, this message translates to:
  /// **'Usually you do not need to: a payment that is not completed cancels itself after {days, plural, =1{1 day} other{{days} days}} and unlocks the amount. To stop one sooner, for example when the recipient says they will never answer, open it while it still says \"Waiting for recipient\" and tap Cancel payment; you would then have to send it again. A payment that is already confirming cannot be cancelled. Payments made with older versions of this app do not cancel themselves: if one has waited more than two weeks, cancel it and send again.'**
  String helpCancellingAnswer(int days);

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'Why must I keep the app open to receive?'**
  String get helpReceivingQuestion;

  /// Answer on the help page. epicbox is the relay service that carries payments (a proper name). Waiting for sender is the status chip (txStatusWaitingSender): use the same words.
  ///
  /// In en, this message translates to:
  /// **'Your wallet has to accept every incoming payment, and it can only do that while the app is open and connected to epicbox. A payment sent while the app is closed waits in epicbox for about a week and arrives the next time you unlock. After that epicbox deletes it; if the sender uses this app, their wallet cancels it by itself after {days, plural, =1{1 day} other{{days} days}}, and they can send it again. Once your wallet accepts a payment, the sender\'s wallet must finish it; until then it shows as Waiting for sender.'**
  String helpReceivingAnswer(int days);

  /// A question on the help page: why the wallet waits for this many blocks.
  ///
  /// In en, this message translates to:
  /// **'What are confirmations and why {count}?'**
  String helpConfirmationsQuestion(int count);

  /// Answer on the help page. Completed is the status chip (txStatusCompleted): use the same word.
  ///
  /// In en, this message translates to:
  /// **'A confirmation is a new block added to the Epic Cash blockchain after the one that holds your payment; a block arrives about once a minute. Each block makes it harder to undo the payment. After {count, plural, =1{1 confirmation, about 1 minute} other{{count} confirmations, about {count} minutes}}, a payment shows as Completed and received coins can be spent; that is the Epic wallet\'s standard.'**
  String helpConfirmationsAnswer(int count);

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'Why is my history missing after a restore?'**
  String get helpHistoryQuestion;

  /// Answer on the help page. Settings, Payment history and Import history backup are the names on the settings screen (settingsTitle, settingsSectionHistory, settingsImportHistory): use the same words.
  ///
  /// In en, this message translates to:
  /// **'The recovery phrase brings back your balance: the wallet scans the blockchain for coins that belong to it. Who you paid, your notes and most dates are never stored on the blockchain, so a restore cannot find them. If you saved a history backup, import it in Settings, under Payment history, Import history backup, to get them back. The backup must be a copy you kept outside the lost phone, for example in email or cloud storage.'**
  String get helpHistoryAnswer;

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'Does my address ever change?'**
  String get helpAddressQuestion;

  /// Answer on the help page. epicbox is the relay service that carries payments (a proper name).
  ///
  /// In en, this message translates to:
  /// **'Your address is made from your recovery phrase and the epicbox server you use, and it ends in @ and that server\'s name. It stays the same as long as you keep the same epicbox server. If you pick another one in network settings, your address changes, so give the new one to people who pay you.'**
  String get helpAddressAnswer;

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'What is the recovery phrase and who can see it?'**
  String get helpPhraseQuestion;

  /// Answer on the help page.
  ///
  /// In en, this message translates to:
  /// **'The recovery phrase is a list of words that is the key to your money: anyone who has it can take your coins, and with it you can restore your wallet on a new phone. The app shows it only after you enter your PIN, and it never sends it anywhere. Write it on paper, keep it somewhere safe, and never share it or type it into a website.'**
  String get helpPhraseAnswer;

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'What does the fee pay for?'**
  String get helpFeesQuestion;

  /// Answer on the help page. EPIC is the coin's ticker: keep it.
  ///
  /// In en, this message translates to:
  /// **'The fee goes to the miners who add your payment to the blockchain. It is usually a small fraction of an EPIC and depends on how many coins your wallet combines to make the payment. You see the exact fee before you send.'**
  String get helpFeesAnswer;

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'What is a node?'**
  String get helpNodeQuestion;

  /// Answer on the help page.
  ///
  /// In en, this message translates to:
  /// **'A node is a computer that keeps a copy of the Epic Cash blockchain. The wallet asks a node for your balance and sends your payments to the network through it. The node sees your IP address and which coins the wallet asks about, so pick one you trust in network settings. Network settings are in Settings once Advanced options is on, and on the unlock screen.'**
  String get helpNodeAnswer;

  /// A question on the help page.
  ///
  /// In en, this message translates to:
  /// **'Are there other ways to send?'**
  String get helpOtherWaysQuestion;

  /// Answer on the help page. "Send by transaction file" and "Other ways to send" are names on the send screen: use the same words. Keep .response as it is.
  ///
  /// In en, this message translates to:
  /// **'For advanced users. Without epicbox, use \"Send by transaction file\" under \"Other ways to send\": you share a file, the recipient accepts it and returns a .response file, and you open that file to finish. \"Other ways to send\" appears once Advanced options is on in Settings.'**
  String get helpOtherWaysAnswer;

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

  /// Under the Advanced options switch: what it shows. epicbox is a proper name.
  ///
  /// In en, this message translates to:
  /// **'Network, node, epicbox server, files and logs'**
  String get settingsAdvancedOptionsSubtitle;

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
  /// **'This is not an Epic address.'**
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
