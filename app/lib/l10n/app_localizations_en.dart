// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Mobile';

  @override
  String get appTitleDesktop => 'Epic Cash Desktop';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get noticeLevelInfo => 'Information';

  @override
  String get noticeLevelSuccess => 'Done';

  @override
  String get noticeLevelWarning => 'Warning';

  @override
  String get noticeLevelError => 'Error';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonError => 'Error';

  @override
  String get commonOk => 'OK';

  @override
  String get commonPaste => 'Paste';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonShare => 'Share';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get slateCopyTooltip => 'Copy transaction text';

  @override
  String get slateCopied => 'Transaction text copied';

  @override
  String get slatePastedTitle => 'Pasted payment';

  @override
  String get slateCopyReply => 'Copy reply';

  @override
  String get biometricPromptTitle => 'Unlock wallet';

  @override
  String get biometricPromptSubtitle => 'Confirm with your fingerprint or face';

  @override
  String get biometricPromptUsePin => 'Use PIN';

  @override
  String get amountEnterExample => 'Enter an amount such as 1.5';

  @override
  String amountTooManyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At most $count decimal places',
      one: 'At most 1 decimal place',
    );
    return '$_temp0';
  }

  @override
  String dateWithTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get txMiningReward => 'Mining reward';

  @override
  String get txRestoredFunds => 'Restored funds';

  @override
  String get txOutgoingPayment => 'Outgoing payment';

  @override
  String get txIncomingPayment => 'Incoming payment';

  @override
  String get txStatusWaitingRecipient => 'Waiting for recipient';

  @override
  String get txStatusWaitingSender => 'Waiting for sender';

  @override
  String txStatusConfirming(int count, int target) {
    return 'Confirming $count/$target';
  }

  @override
  String get txStatusCompleted => 'Completed';

  @override
  String get txStatusCancelled => 'Cancelled';

  @override
  String get txStatusFromBackup => 'From backup, status unknown';

  @override
  String get txIconCancelled => 'Cancelled';

  @override
  String get txIconIncoming => 'Incoming';

  @override
  String get txIconOutgoing => 'Outgoing';

  @override
  String get txSpokenHiddenAmount => 'a hidden amount';

  @override
  String txSpokenMiningReward(String amount) {
    return 'Mining reward of $amount';
  }

  @override
  String txSpokenRestoredFunds(String amount) {
    return 'Restored funds of $amount';
  }

  @override
  String txSpokenCancelledSend(String amount) {
    return 'Cancelled send of $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return 'Cancelled send of $amount to $who';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return 'Cancelled receive of $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return 'Cancelled receive of $amount from $who';
  }

  @override
  String txSpokenSending(String amount) {
    return 'Sending $amount';
  }

  @override
  String txSpokenSendingTo(String amount, String who) {
    return 'Sending $amount to $who';
  }

  @override
  String txSpokenReceiving(String amount) {
    return 'Receiving $amount';
  }

  @override
  String txSpokenReceivingFrom(String amount, String who) {
    return 'Receiving $amount from $who';
  }

  @override
  String txSpokenSent(String amount) {
    return 'Sent $amount';
  }

  @override
  String txSpokenSentTo(String amount, String who) {
    return 'Sent $amount to $who';
  }

  @override
  String txSpokenReceived(String amount) {
    return 'Received $amount';
  }

  @override
  String txSpokenReceivedFrom(String amount, String who) {
    return 'Received $amount from $who';
  }

  @override
  String txSpokenRow(String what, String status, String date) {
    return '$what, $status, $date';
  }

  @override
  String get errorInvalidMnemonic =>
      'The recovery phrase is not valid. Check each word and the word order.';

  @override
  String get errorWrongPassword => 'Wrong password.';

  @override
  String get errorWalletAlreadyExists =>
      'A wallet already exists for this network.';

  @override
  String get errorWalletNotFound => 'No wallet found for this network.';

  @override
  String get errorNodeUnreachable =>
      'Cannot reach the node. Check the node URL and your connection.';

  @override
  String get errorNotEnoughFunds =>
      'Not enough spendable funds for this amount plus the fee.';

  @override
  String get errorInvalidSlate =>
      'This transaction text is not valid for this step. Check that you pasted all of it.';

  @override
  String get errorInvalidInput => 'Invalid input.';

  @override
  String get errorTransportFailed => 'Could not reach the recipient.';

  @override
  String get errorTorNotRunning => 'Tor is not connected.';

  @override
  String get errorOnionUnreachable => 'Their wallet was not reached over Tor.';

  @override
  String get errorChainBusy =>
      'The wallet is still busy on the other network. Wait a moment and try again, or close and reopen the app.';

  @override
  String get errorWalletBusy =>
      'The wallet is still finishing a task. Try again in a moment.';

  @override
  String get errorPaymentExpired =>
      'The answer to this payment came too late, so the payment was cancelled. Nothing was sent.';

  @override
  String get errorIo => 'Could not read or write wallet files.';

  @override
  String get errorOther => 'Wallet error.';

  @override
  String get errorScanFailed => 'The scan failed.';

  @override
  String get errorUnexpected => 'Unexpected error. Please try again.';

  @override
  String get errorHistoryNotOurs =>
      'This is not a history file exported by this app.';

  @override
  String get errorHistoryNewer =>
      'This history file was made by a newer version of the app.';

  @override
  String get errorHistoryDamaged => 'This history file is damaged.';

  @override
  String get errorHistoryOtherWallet =>
      'This history file belongs to a different wallet.';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return 'This history file is from $fileNetwork, but this wallet is on $walletNetwork.';
  }

  @override
  String get networkMainnet => 'Mainnet';

  @override
  String get networkFloonet => 'Floonet';

  @override
  String get networkUsernet => 'Usernet';

  @override
  String get networkMainnetDescription => 'The real Epic Cash network.';

  @override
  String get networkFloonetDescription =>
      'A public test network for trying the app. Its coins have no value; get free ones from floo-explorer.btlabs.uk.';

  @override
  String get networkUsernetDescription =>
      'A test network running on this computer, for developers.';

  @override
  String networkTestSuffix(String network) {
    return ' ($network, test coins)';
  }

  @override
  String get autoLockNever => 'Never';

  @override
  String get autoLockImmediately => 'Immediately';

  @override
  String autoLockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'After $minutes minutes',
      one: 'After 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get scanStarting => 'Starting scan';

  @override
  String scanProgress(int percent) {
    return 'Scanning the chain ($percent%)';
  }

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get currencyUsd => 'US dollar';

  @override
  String get currencyEur => 'Euro';

  @override
  String get currencyGbp => 'British pound';

  @override
  String get currencyBtc => 'Bitcoin';

  @override
  String get currencyJpy => 'Japanese yen';

  @override
  String get currencyCny => 'Chinese yuan';

  @override
  String get currencyCad => 'Canadian dollar';

  @override
  String get currencyAud => 'Australian dollar';

  @override
  String get currencyChf => 'Swiss franc';

  @override
  String get currencyInr => 'Indian rupee';

  @override
  String get currencyBrl => 'Brazilian real';

  @override
  String get currencyKrw => 'South Korean won';

  @override
  String get currencyPln => 'Polish złoty';

  @override
  String get currencyTry => 'Turkish lira';

  @override
  String txDetailsWaitingTooLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Waiting for $days days. The epicbox deletes payments after 7 days, so this one can no longer complete. Cancel it to unlock your funds, then send again.',
      one: 'Waiting for 1 day. The epicbox deletes payments after 7 days, so this one can no longer complete. Cancel it to unlock your funds, then send again.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Sent to the recipient\'s epicbox. It completes when their wallet comes online. Your funds stay locked until then, or until you cancel.';

  @override
  String get txDetailsWaitingRecipient =>
      'Waiting for the recipient to answer with their transaction file. Your funds stay locked until then, or until you cancel.';

  @override
  String get txDetailsWaitingSender =>
      'You accepted this payment. It completes when the sender finishes it and publishes it to the network.';

  @override
  String get txDetailsPublished =>
      'Published to the network. Waiting for the first confirmation.';

  @override
  String get txDetailsWaitingConfirmation =>
      'Waiting for the network to confirm it.';

  @override
  String txDetailsConfirmingMinutes(
    String height,
    int count,
    int target,
    int minutes,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$target confirmations',
      one: '1 confirmation',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'In block $height. $count of $_temp0; final in about $_temp1.';
  }

  @override
  String txDetailsConfirmingHours(
    String height,
    int count,
    int target,
    int hours,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$target confirmations',
      one: '1 confirmation',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'In block $height. $count of $_temp0; final in about $_temp1.';
  }

  @override
  String txDetailsConfirmingDays(
    String height,
    int count,
    int target,
    int days,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$target confirmations',
      one: '1 confirmation',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'In block $height. $count of $_temp0; final in about $_temp1.';
  }

  @override
  String get txDetailsCompleted => 'Completed.';

  @override
  String txDetailsCompletedInBlock(String height) {
    return 'Completed in block $height.';
  }

  @override
  String get txDetailsCancelledByUser =>
      'Cancelled. Nothing was sent, and the funds are spendable again.';

  @override
  String get txDetailsCancelledReleased =>
      'The network never took it, so its funds were released. Check the recipient did not receive it before sending again.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'It did not reach the network within 14 days, so the wallet cancelled it. Check the recipient did not receive it before sending again.';

  @override
  String get txDetailsCancelledUnanswered =>
      'The recipient did not answer within 14 days, so the wallet cancelled it. Nothing was sent, and the funds are spendable again.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'The recipient answered after the 14-day limit, so the wallet cancelled it instead of finishing it. Nothing was sent, and the funds are spendable again.';

  @override
  String get txDetailsCancelledUndelivered =>
      'It could not be delivered to the recipient, so the wallet cancelled it at once. Nothing was sent, and the funds are spendable again.';

  @override
  String get txDetailsCancelledIncoming =>
      'Cancelled. This payment will not arrive.';

  @override
  String get txDetailsFromBackup =>
      'This payment comes from a history backup and was not finished when the backup was made. This wallet has no record of its own for it, so it cannot tell whether it completed. Nothing is locked.';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return 'Cancels automatically if not completed by block $height.';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Cancels automatically if not completed by block $height (in about $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'Cancels automatically if not completed by block $height (in about $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Cancels automatically if not completed by block $height (in about $_temp0).';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return 'Expired at block $height. The wallet cancels it on the next refresh.';
  }

  @override
  String get txDetailsTitle => 'Payment';

  @override
  String get txDetailsLoading => 'Loading';

  @override
  String get txDetailsGone => 'This payment is no longer in the wallet.';

  @override
  String get txDetailsWorking => 'Working';

  @override
  String get txDetailsAmountHidden => 'Amount hidden';

  @override
  String get txDetailsNotConfirmedYet => 'Not confirmed yet';

  @override
  String get txDetailsStuckBody =>
      'The network has not taken this payment yet. Broadcasting it again is safe. The same payment cannot go through twice.';

  @override
  String get txDetailsBroadcastAgain => 'Broadcast again';

  @override
  String get txDetailsBroadcastAgainDone =>
      'Broadcast again. It should confirm within a few minutes.';

  @override
  String get txDetailsRefusedBody =>
      'The network refused this payment and it never reached the chain. You can release the funds it locked.';

  @override
  String get txDetailsReleaseFunds => 'Release funds';

  @override
  String get txDetailsReleaseTitle => 'Release funds?';

  @override
  String get txDetailsReleaseBody =>
      'Use this only if the payment will never confirm. If it still does, you may see a wrong balance until you rescan.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Keep waiting';

  @override
  String get txDetailsFundsReleased => 'Funds released';

  @override
  String get txDetailsCancelPayment => 'Cancel payment';

  @override
  String get txDetailsCancelTitle => 'Cancel payment?';

  @override
  String get txDetailsCancelReceiveBody =>
      'The sender may still finish this payment. If they do after you cancel, it will not show until you rescan.';

  @override
  String get txDetailsCancelSendBody =>
      'Cancel this payment and unlock its funds? Only do this if the recipient has not finished it.';

  @override
  String get txDetailsCancelKeep => 'Keep';

  @override
  String get txDetailsPaymentCancelled => 'Payment cancelled';

  @override
  String get txDetailsDate => 'Date';

  @override
  String get txDetailsCreated => 'Created';

  @override
  String get txDetailsSentTo => 'Sent to';

  @override
  String get txDetailsReceivedFrom => 'Received from';

  @override
  String get txDetailsCopyAddress => 'Copy address';

  @override
  String get txDetailsAddressCopied => 'Address copied';

  @override
  String get txDetailsAddToContacts => 'Add to contacts';

  @override
  String get txDetailsSendAgain => 'Send again';

  @override
  String get txDetailsFee => 'Fee';

  @override
  String get txDetailsNoteLabel => 'Note';

  @override
  String get txDetailsPrivateNoteLabel => 'Private note, only on this device';

  @override
  String get txDetailsMessageFromSender => 'Message from the sender';

  @override
  String get txDetailsMessageFromRecipient => 'Message from the recipient';

  @override
  String get txDetailsYourMessage => 'Your message';

  @override
  String get txDetailsNoNote =>
      'No note. Add one to remember what this was for.';

  @override
  String get txDetailsAddNote => 'Add note';

  @override
  String get txDetailsEditNote => 'Edit note';

  @override
  String get txDetailsNoteDialogTitle => 'Note';

  @override
  String get txDetailsNoteHelper =>
      'Only on this device and in your history backups.';

  @override
  String get txDetailsNoteSaved => 'Note saved';

  @override
  String get txDetailsNoteRemoved => 'Note removed';

  @override
  String get txDetailsExplorerLink => 'Copy explorer link';

  @override
  String get txDetailsExplorerLinkCopy => 'Copy explorer link';

  @override
  String get txDetailsLinkCopied => 'Link copied';

  @override
  String get txDetailsTechnical => 'Technical details';

  @override
  String get txDetailsBlockHeight => 'Block height';

  @override
  String get txDetailsSlateId => 'Slate ID';

  @override
  String get txDetailsSlateIdCopy => 'Copy slate id';

  @override
  String get txDetailsSlateIdCopied => 'Slate ID copied';

  @override
  String get txDetailsKernel => 'Kernel';

  @override
  String get txDetailsKernelCopy => 'Copy kernel';

  @override
  String get txDetailsKernelCopied => 'Kernel copied';

  @override
  String get txDetailsOutputCommitment => 'Output commitment';

  @override
  String get txDetailsOutputCommitmentCopy => 'Copy output commitment';

  @override
  String get txDetailsOutputCommitmentCopied => 'Output commitment copied';

  @override
  String txDetailsOutputCommitmentNumbered(int number) {
    return 'Output commitment $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopy(int number) {
    return 'Copy output commitment $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopied(int number) {
    return 'Output commitment $number copied';
  }

  @override
  String get txDetailsExpiryHeight => 'Expiry height';

  @override
  String get txDetailsLocalId => 'Local id';

  @override
  String get txDetailsSourceRestored =>
      'Found by scanning the chain. Details such as the sender and fee are not stored on the chain; import a history backup to restore them.';

  @override
  String get txDetailsSourceImported =>
      'Imported from a history backup. This wallet has no record of its own for it, so its status may be out of date.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyLoading => 'Loading payments';

  @override
  String get historyRefreshing => 'Refreshing';

  @override
  String get historySearchLabel => 'Search';

  @override
  String get historySearchHint => 'Note, contact, address or amount';

  @override
  String get historyClearSearch => 'Clear search';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterSent => 'Sent';

  @override
  String get historyFilterReceived => 'Received';

  @override
  String get historyFilterPending => 'Pending';

  @override
  String get historyFilterCancelled => 'Cancelled';

  @override
  String get historySectionPending => 'Pending';

  @override
  String get historyEmpty =>
      'Nothing yet. Payments you send or receive show up here.';

  @override
  String get historyNoSent => 'No sent payments.';

  @override
  String get historyNoReceived => 'No received payments.';

  @override
  String get historyNoPending => 'No pending payments.';

  @override
  String get historyNoCancelled => 'No cancelled payments.';

  @override
  String historyNoMatch(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String get historyBackupSaveDialogTitle => 'Save payment history';

  @override
  String get historyBackupOpenDialogTitle => 'Open history backup';

  @override
  String get historyBackupFileTooLarge =>
      'That file is too large to be a backup.';

  @override
  String get historyBackupShare => 'Share';

  @override
  String get historyBackupShareSubtitle =>
      'Keep a copy off this phone, such as email or cloud storage';

  @override
  String get historyBackupSaveToDevice => 'Save to device';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Only useful if you also copy it off this phone.';

  @override
  String historyBackupSaved(String fileName) {
    return 'Saved $fileName';
  }

  @override
  String get historyBackupExportTitle => 'Export history backup';

  @override
  String get historyBackupExportNote =>
      'History backups hold payments up to now. Export again after new payments.';

  @override
  String get historyBackupCsvTitle => 'Export CSV';

  @override
  String get historyBackupCsvWarning =>
      'The CSV file is not encrypted. Anyone who gets it can read your amounts, dates, addresses and notes. It cannot be imported back; use Export history backup for that.';

  @override
  String get historyBackupCsvConfirm => 'Export CSV';

  @override
  String get historyBackupImportedTitle => 'History imported';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Could not import the history backup. $reason';
  }

  @override
  String get historyBackupImportNothingNew => 'The backup held nothing new.';

  @override
  String historyBackupImportMerged(int merged) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedAdded(int merged, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportSkipped(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedSkipped(int merged, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportMergedAddedSkipped(
    int merged,
    int added,
    int skipped,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportContacts(int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedContacts(int merged, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedContacts(int added, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportMergedAddedContacts(
    int merged,
    int added,
    int contacts,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportSkippedContacts(int skipped, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportMergedSkippedContacts(
    int merged,
    int skipped,
    int contacts,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportAddedSkippedContacts(
    int added,
    int skipped,
    int contacts,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportMergedAddedSkippedContacts(
    int merged,
    int added,
    int skipped,
    int contacts,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged payments got their details back',
      one: '1 payment got their details back',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added older payments added',
      one: '1 older payment added',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped records were already here',
      one: '1 record was already here',
    );
    String _temp3 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts added',
      one: '1 contact added',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3.';
  }

  @override
  String get homeLockTooltip => 'Lock wallet';

  @override
  String get shellTitle => 'Epic Cash Mobile';

  @override
  String get demoWelcomeTitle => 'Try Epic Cash';

  @override
  String get demoWelcomeLine =>
      'A real wallet with free test coins, which have no value. It is deleted after 24 hours.';

  @override
  String get demoStart => 'Start the demo';

  @override
  String get demoEndedTitle => 'Your demo ended';

  @override
  String get demoEndedBody => 'Its wallet and test coins were deleted.';

  @override
  String get demoStartAgain => 'Start again';

  @override
  String demoEndsAt(String time) {
    return 'Your demo ends at $time. Its wallet and test coins are deleted then.';
  }

  @override
  String get demoEndingSoon =>
      'Your demo ends in 30 minutes. Its wallet and test coins are deleted then.';

  @override
  String get demoTestCoins => 'Get test coins';

  @override
  String get demoTestCoinsPaid =>
      'Test coins are on their way. They arrive in a minute or two.';

  @override
  String demoTestCoinsCooldown(int seconds) {
    return 'The faucet needs a pause. Try again in $seconds s.';
  }

  @override
  String get demoTestCoinsFailed =>
      'The faucet sent nothing this time. Try again in a minute.';

  @override
  String get demoEnd => 'End demo';

  @override
  String get demoEndTitle => 'End the demo?';

  @override
  String get demoEndBody =>
      'Your demo wallet and its test coins are deleted now. You can start a new demo afterwards.';

  @override
  String get demoServerUnreachable =>
      'Cannot reach the demo server. Check your connection and try again.';

  @override
  String demoStartFull(int minutes) {
    return 'The demo is full right now. Try again in $minutes min.';
  }

  @override
  String demoStartTooMany(int minutes) {
    return 'Too many demos were started from your network. Try again in $minutes min.';
  }

  @override
  String get demoConnectionLost => 'Connection lost, reconnecting.';

  @override
  String get demoConnectionBack => 'Connected again.';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeSettingsUpdateTooltip => 'Settings: an update is available';

  @override
  String get homeSendButton => 'Send';

  @override
  String get shellWalletTab => 'Wallet';

  @override
  String get homeReceiveButton => 'Receive';

  @override
  String get homeScanTooltip => 'Scan a QR code to send';

  @override
  String get homeRecentActivity => 'Recent activity';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeBackedUpNotice => 'Recovery phrase backed up';

  @override
  String get homeNoticeView => 'View';

  @override
  String get homePushNotice =>
      'A payment is waiting in your epicbox. It arrives once the app is connected.';

  @override
  String get homeNoticeReceived =>
      'A payment is on the way. It completes when the sender finishes.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return 'A payment from $who is on the way. It completes when the sender finishes.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount on the way. It completes when the sender finishes.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$amount from $who on the way. It completes when the sender finishes.';
  }

  @override
  String get homeNoticeFinished =>
      'Payment finished. Waiting for confirmations.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Payment to $who finished. Waiting for confirmations.';
  }

  @override
  String get homeNoticeRepeated =>
      'This payment was already accepted. The sender got the same answer again; no second payment is on the way.';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return 'The payment from $who was already accepted. They got the same answer again; no second payment is on the way.';
  }

  @override
  String get homeNoticeDelayed =>
      'Could not reach the node. The payment will finish once it can.';

  @override
  String get homeNoticeRelayProblem =>
      'The epicbox server reported a problem. Retrying.';

  @override
  String get homeNoticePaymentFailed => 'A payment could not be completed.';

  @override
  String get homeBackupCardText => 'Back up your recovery phrase.';

  @override
  String get homeBackupCardButton => 'Back up';

  @override
  String get homeBackupCardDismiss => 'Dismiss';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are not in a history backup. A restore from your recovery phrase brings back only your balance.',
      one: '1 payment is not in a history backup. A restore from your recovery phrase brings back only your balance.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are new or changed since your last history backup. A restore from your recovery phrase brings back only your balance.',
      one: '1 payment is new or changed since your last history backup. A restore from your recovery phrase brings back only your balance.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Not now';

  @override
  String get homeHistoryExportButton => 'Export history backup';

  @override
  String get homeBalanceSpendable => 'Spendable';

  @override
  String get balanceHelpLabel => 'What these balances mean';

  @override
  String get balanceTotal => 'Total';

  @override
  String balanceHelpRow(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get balanceTotalHelp => 'Everything in this wallet, spendable or not.';

  @override
  String get homeBalanceHiddenLabel => 'Balance hidden';

  @override
  String get homeShowBalances => 'Show balances';

  @override
  String get homeHideBalances => 'Hide balances';

  @override
  String get homeBalanceConfirming => 'Confirming';

  @override
  String get balanceConfirmingHelp =>
      'On the chain, waiting for enough confirmations.';

  @override
  String get homeBalanceNotOnChain => 'Not on chain yet';

  @override
  String get balanceNotOnChainHelp =>
      'Payments to you that the sender has not finished or that are not in a block yet, and change from your sends. Not counted until they are on chain: a payment someone only offered may never arrive.';

  @override
  String get homeBalanceLocked => 'Locked by a payment in progress';

  @override
  String get balanceLockedHelp =>
      'Held for a payment you started; the change comes back when it completes.';

  @override
  String get homeBalanceImmature => 'Mining rewards not spendable yet';

  @override
  String get balanceImmatureHelp =>
      'Mining rewards wait a set number of blocks before they can be spent.';

  @override
  String get balanceLineAllConfirmed => 'All confirmed';

  @override
  String get balanceLineNothingYet => 'Nothing here yet';

  @override
  String get homeSyncSyncing => 'Syncing…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'Syncing… $percent%';
  }

  @override
  String get homeSyncNodeUnreachable =>
      'Node unreachable. Balances may be out of date.';

  @override
  String get homeSyncNotValidated =>
      'Not validated with node. Balances may be out of date.';

  @override
  String get homeSyncUpToDate => 'Up to date.';

  @override
  String get homeSyncContactingNode => 'Contacting node…';

  @override
  String get statusNodeOnline => 'Node online';

  @override
  String get statusNodeSyncing => 'Node syncing';

  @override
  String statusNodeSyncingPercent(int percent) {
    return 'Node syncing $percent%';
  }

  @override
  String get statusNodeConnecting => 'Node connecting';

  @override
  String get statusNodeOffline => 'Node offline';

  @override
  String get statusEpicboxOnline => 'Epicbox online';

  @override
  String get statusEpicboxConnecting => 'Epicbox connecting';

  @override
  String get statusEpicboxOffline => 'Epicbox offline';

  @override
  String statusNodeTestNetwork(String network) {
    return '$network, test coins';
  }

  @override
  String statusNodeHost(Object host) {
    return 'Node: $host';
  }

  @override
  String statusNodeVersion(Object version) {
    return 'Node version $version';
  }

  @override
  String statusRelay(Object relay) {
    return 'Server: $relay';
  }

  @override
  String get homeEpicboxOffline => 'Epicbox offline, reconnecting.';

  @override
  String get homeEpicboxConnecting => 'Connecting to epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Synced at block $height';
  }

  @override
  String homePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments are waiting for their recipients',
      one: 'A payment is waiting for the recipient',
    );
    return '$_temp0';
  }

  @override
  String homePendingBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$amount is waiting for the recipients\' wallets to answer. Until then the funds stay locked. If one never answers, open the payment and tap Cancel payment.',
      one:
          '$amount is waiting for the recipient\'s wallet to answer. Until then the funds stay locked. If it never answers, open the payment and tap Cancel payment.',
    );
    return '$_temp0';
  }

  @override
  String get homePendingWhy => 'Why is it waiting?';

  @override
  String homePendingView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View payments',
      one: 'View payment',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPayments => 'No payments yet.';

  @override
  String get invoicesTitle => 'Invoices';

  @override
  String invoicesEntryTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Invoices, $count waiting',
      one: 'Invoices, 1 waiting',
      zero: 'Invoices',
    );
    return '$_temp0';
  }

  @override
  String get invoicesChecking => 'Checking for invoices';

  @override
  String get invoicesEmpty =>
      'No invoices are waiting. When a service you trust bills you, the invoice appears here, and nothing is paid until you approve it.';

  @override
  String get invoicesUnnamedService => 'Unnamed service';

  @override
  String invoiceTimeLeftHours(int hours, int minutes) {
    return '$hours h $minutes min left';
  }

  @override
  String invoiceTimeLeftMinutes(int minutes) {
    return '$minutes min left';
  }

  @override
  String get invoiceTimeLeftUnderMinute => 'Less than a minute left';

  @override
  String get invoiceExpired => 'This invoice has expired. Nothing was paid.';

  @override
  String get invoiceGone => 'This invoice is no longer open. Nothing was paid.';

  @override
  String get invoiceReviewTitle => 'Review invoice';

  @override
  String invoiceReviewAsks(String service) {
    return '$service asks you to pay';
  }

  @override
  String get invoiceReviewMessageLabel => 'Message from the service';

  @override
  String get invoiceReviewNote =>
      'Your wallet adds the network fee. Nothing is paid until you approve it.';

  @override
  String get invoiceApprove => 'Approve and pay';

  @override
  String get invoiceDecline => 'Decline';

  @override
  String get invoicePinReason => 'Enter your PIN to pay this invoice.';

  @override
  String get invoiceDeclineTitle => 'Decline this invoice?';

  @override
  String invoiceDeclineBody(String service) {
    return '$service is told that you declined. Nothing is paid.';
  }

  @override
  String get invoiceDeclineKeep => 'Keep it';

  @override
  String get invoiceDeclinedNotice => 'Invoice declined.';

  @override
  String invoicePaidNotice(String service) {
    return 'Paid. $service now finishes the payment.';
  }

  @override
  String invoiceReplyFailedTitle(String service) {
    return 'Your payment has not reached $service';
  }

  @override
  String get invoiceReplyFailedBody =>
      'It is signed and kept on this device. Retry sends it again; you do not approve it again.';

  @override
  String get invoiceReplyFailedNotice =>
      'Your payment could not reach the service. Tap Retry to send it again.';

  @override
  String get invoiceRetry => 'Retry';

  @override
  String get invoiceDetailsSection => 'Invoice';

  @override
  String get invoiceDetailsService => 'Billed by';

  @override
  String invoiceDetailsReplied(String service) {
    return 'Waiting for $service to post the payment.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service reports it posted the payment. It completes once the network confirms it.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service has not received your payment yet. Retry sends it again; you do not approve it again.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '$service withdrew this invoice after you paid it. If the payment does not confirm, cancel it to unlock your funds.';
  }

  @override
  String get invoiceNoticeReceived =>
      'An invoice is waiting for your approval.';

  @override
  String get invoiceNoticePosted => 'A service reports it posted your payment.';

  @override
  String get invoiceNoticeWithdrawnPaid =>
      'A service withdrew an invoice you already paid.';

  @override
  String get invoiceNoticeWithdrawn =>
      'A service withdrew an invoice before you answered it.';

  @override
  String get invoiceNoticeExpired =>
      'An invoice expired before you answered it.';

  @override
  String get receiveRequestTitle => 'Request a payment';

  @override
  String get requestTitle => 'Request a payment';

  @override
  String get requestStepsIntro =>
      'Their wallet must take invoices. Before you request:';

  @override
  String get requestStepTrust =>
      '1. They add your address below to their trusted services.';

  @override
  String get requestStepAddress => '2. They give you their invoice address.';

  @override
  String get requestYourAddress => 'Your address';

  @override
  String get requestPayerLabel => 'Their invoice address';

  @override
  String get requestPayerMissing => 'Paste or scan their invoice address.';

  @override
  String get requestPayerOwn =>
      'That is one of your own addresses. Enter the invoice address the payer gives you.';

  @override
  String get requestMessageLabel => 'Message to the payer (optional)';

  @override
  String get requestMessageHelper =>
      'The payer sees this message with your request.';

  @override
  String get requestButton => 'Request';

  @override
  String requestSentNotice(String payer) {
    return 'Request sent to $payer.';
  }

  @override
  String get invoicesToPaySection => 'To pay';

  @override
  String get invoicesNoneToPay => 'Nothing to pay.';

  @override
  String get invoicesSentSection => 'Requests you sent';

  @override
  String get issuedPaid => 'Paid';

  @override
  String get issuedDeclined => 'Declined';

  @override
  String get issuedWithdrawn => 'Withdrawn';

  @override
  String get issuedExpired => 'Expired';

  @override
  String get issuedWithdraw => 'Withdraw';

  @override
  String get issuedWithdrawTitle => 'Withdraw this request?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer can no longer pay it. This cannot be undone.';
  }

  @override
  String get issuedWithdrawKeep => 'Keep it';

  @override
  String get issuedDetailsSection => 'Payment request';

  @override
  String get issuedDetailsPayer => 'Requested from';

  @override
  String get issuedDetailsWaiting =>
      'Waiting for the payer. Your wallet finishes the payment when it arrives.';

  @override
  String get issuedDetailsPaid =>
      'Paid. Your wallet finished the payment; it completes once the network confirms it.';

  @override
  String get issuedDetailsDeclined =>
      'The payer declined this request, so it was withdrawn. Nothing was paid.';

  @override
  String get issuedDetailsWithdrawn =>
      'You withdrew this request. Nothing was paid.';

  @override
  String get issuedDetailsExpired =>
      'This request expired before it was paid. Nothing was paid.';

  @override
  String get issuerNoticePaid => 'A request you sent was paid.';

  @override
  String get issuerNoticeDeclined => 'A request you sent was declined.';

  @override
  String get issuerNoticeWithdrawn =>
      'Request withdrawn. It can no longer be paid.';

  @override
  String get issuerNoticeExpired => 'A request you sent expired unpaid.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return '$payer\'s wallet cannot pay requests and sent yours back, so it was withdrawn. Ask them to send you the payment instead, to your address or as a payment file.';
  }

  @override
  String get issuedBounced => 'Sent back';

  @override
  String get issuedDetailsBounced =>
      'The payer\'s wallet cannot pay requests and sent this one back, so it was withdrawn. Nothing was paid. Ask them to send you the payment instead, to your address or as a payment file.';

  @override
  String get requestPayerNoInvoices =>
      'This wallet sent a request back before: it cannot pay requests. Ask them to send you the payment instead, to your address or as a payment file.';

  @override
  String get txStatusWaitingPayer => 'Waiting for payer';

  @override
  String get txStepRequested => 'Requested';

  @override
  String get txStepPaid => 'Paid';

  @override
  String get txDetailsWaitingPayer =>
      'You asked for this payment. Nothing has arrived yet: it comes when the payer pays the request.';

  @override
  String get txDetailsRequestEnded =>
      'This request ended unpaid. Nothing arrived.';

  @override
  String get txDetailsRequestedFrom => 'Requested from';

  @override
  String get txPaymentRequest => 'Requested payment';

  @override
  String txSpokenRequesting(String amount) {
    return 'Requesting $amount';
  }

  @override
  String txSpokenRequestingFrom(String amount, String who) {
    return 'Requesting $amount from $who';
  }

  @override
  String get receiveEpicboxConnected => 'Epicbox connected';

  @override
  String get receiveQrLabel => 'QR code of your address';

  @override
  String get receiveAddressLabel => 'Epicbox address';

  @override
  String get receiveEpicboxOfflineBody =>
      'Payments sent to you now wait at epicbox and arrive once the wallet connects again.';

  @override
  String get receiveShareCardHeadline => 'Pay me in Epic Cash';

  @override
  String get receiveHelpButton => 'How receiving works';

  @override
  String get receiveAddressCopied => 'Address copied';

  @override
  String get receiveFileTitle => 'Receive by payment file';

  @override
  String get receiveFileBody =>
      'Got a payment file from someone? Open it, or copy its text and paste it here.';

  @override
  String get receiveFileOpen => 'Open file';

  @override
  String get receivePasteEmpty =>
      'Copy the payment text first, then tap Paste.';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'This is the latest version.';

  @override
  String get updateNoInformation => 'No update information available.';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available.';
  }

  @override
  String updateDownloading(String version, int percent) {
    return 'Downloading version $version… $percent%';
  }

  @override
  String updateInstalling(String version) {
    return 'Installing version $version…';
  }

  @override
  String get updateFailed => 'The update failed.';

  @override
  String get updateInstallButton => 'Update';

  @override
  String get updateTryAgain => 'Try again';

  @override
  String get updateDownloadProgressLabel => 'Download progress';

  @override
  String get updateAllowInstalls =>
      'Allow installs from Epic Cash Mobile, then return.';

  @override
  String updateNotInstalled(String detail) {
    return 'The update was not installed: $detail';
  }

  @override
  String updateCannotInstall(String detail) {
    return 'Cannot install the update: $detail.';
  }

  @override
  String get updateCannotInstallUnknown =>
      'Cannot install the update: unknown error.';

  @override
  String get updateNeedsReinstall =>
      'This update is signed with a new key, so it cannot install over this version. A reinstall is needed, and uninstalling removes this wallet from the device: write down your recovery phrase first, then uninstall this app and install the new version.';

  @override
  String get updateManifestNotJson =>
      'The update information is not valid JSON.';

  @override
  String get updateManifestWrongShape =>
      'The update information has the wrong shape.';

  @override
  String get updateManifestOtherApp =>
      'The update information is for another app.';

  @override
  String get updateManifestNoApks => 'The update information lists no APKs.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'The download failed (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge => 'The download is larger than announced.';

  @override
  String get updateDownloadIncomplete => 'The download is incomplete.';

  @override
  String get updateDownloadDamaged =>
      'The download is damaged (checksum mismatch).';

  @override
  String get updateDownloadInterrupted => 'The download was interrupted.';

  @override
  String get updateServerUnreachable => 'Cannot reach the update server.';

  @override
  String updateServerHttpStatus(int status) {
    return 'The update server answered HTTP $status.';
  }

  @override
  String get updateServerTimeout => 'The update server did not answer in time.';

  @override
  String get updateConnectionFailed =>
      'The connection to the update server failed.';

  @override
  String get updateCheckFailed => 'Checking for updates failed.';

  @override
  String get setupTitle => 'Node and Epicbox';

  @override
  String get setupNetworkSettingsTooltip => 'Node and Epicbox';

  @override
  String get setupNetworkHeading => 'Network';

  @override
  String get setupNodeUrlLabel => 'Node URL';

  @override
  String get setupNodeUrlInvalid =>
      'Enter a full URL such as https://node.example.com';

  @override
  String get setupTestConnection => 'Test connection';

  @override
  String setupTestConnected(String height, String version) {
    return 'Connected. The node is at block $height, running version $version.';
  }

  @override
  String setupTestFailed(String error) {
    return 'Could not connect. $error';
  }

  @override
  String get setupConnectedIconLabel => 'Connected';

  @override
  String get setupRelayHeading => 'Epicbox server';

  @override
  String get setupRelayHint => 'Your address includes this server.';

  @override
  String get setupCustomRelayLabel =>
      'Other epicbox server (host or host:port)';

  @override
  String get setupCustomRelayUse => 'Use this server';

  @override
  String get setupCustomRelayInvalid =>
      'Enter a host such as epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      'Changing the epicbox server changes your address. Give senders the new address. Payments sent to the old one wait on the old server until you switch back.';

  @override
  String get setupWalletPerNetwork =>
      'Each network has its own wallet. A network without one gets a new wallet.';

  @override
  String get setupRelayHealthyIconLabel => 'Healthy';

  @override
  String get setupRelayDownIconLabel => 'Down';

  @override
  String get setupRelayHealthUnavailable =>
      'Server health is unavailable from status.btlabs.uk.';

  @override
  String get setupRelayHealthSource =>
      'Health from status.btlabs.uk, measured from its server.';

  @override
  String get setupRelayNotMonitored => 'Not monitored';

  @override
  String get setupRelayUp => 'Up';

  @override
  String get setupRelayDown => 'Down';

  @override
  String get setupRelayOfficial => 'official';

  @override
  String setupRelayUptime(String percent) {
    return '$percent% up in the last day';
  }

  @override
  String get restoreTitle => 'Restore wallet';

  @override
  String get restorePhraseLabel => 'Recovery phrase';

  @override
  String get restorePhraseHelper =>
      'All the words (12 to 24), separated by spaces.';

  @override
  String get restoreStartHeading => 'Where to start scanning';

  @override
  String get restoreStartByDate => 'Date';

  @override
  String get restoreStartByHeight => 'Block height';

  @override
  String get restoreStartHeightLabel => 'Start height (optional)';

  @override
  String get restoreStartHeightHelper =>
      'Scan from this block. Leave empty to scan the whole chain.';

  @override
  String get restoreStartHeightInvalid =>
      'Start height must be a whole number.';

  @override
  String get restoreBackToPhrase => 'Back to the phrase';

  @override
  String get restoreDatePickerTitle => 'When did you create the wallet?';

  @override
  String get restorePickDate => 'Pick the date you created the wallet';

  @override
  String restoreFromDate(String date) {
    return 'From $date';
  }

  @override
  String get restoreDateHint =>
      'Optional. If you are not sure, pick an earlier date. A date after your first payment misses funds. Without a date the whole chain is scanned, which takes longer.';

  @override
  String restoreDateStart(String height) {
    return 'Scanning starts two days before this date, from block $height.';
  }

  @override
  String get restoreWholeChain => 'Scan the whole chain instead';

  @override
  String get restoreScanIntro =>
      'Looking for your funds on the blockchain. Keep the app open until this finishes.';

  @override
  String get restoreOpenWallet => 'Open wallet';

  @override
  String get restoreRescanLater =>
      'You can run a full rescan later from Settings.';

  @override
  String get restoreDoneIconLabel => 'Done';

  @override
  String get restoreDoneTitle => 'Your wallet is restored';

  @override
  String get restoreImportExplanation =>
      'The chain holds your balance, but not who you paid, fees or notes. If you exported a history backup from this wallet, import it now to get them back. It is the .wfeh file you shared or saved outside your old phone.';

  @override
  String get restoreImportButton => 'Import a history backup';

  @override
  String get restoreImportNotNow => 'Not now';

  @override
  String get restoreImportLater => 'You can import one later from Settings.';

  @override
  String get restoreScanProgressLabel => 'Scan progress';

  @override
  String get firstRunTitle => 'Welcome';

  @override
  String get firstRunRestore => 'I already have a wallet: restore it';

  @override
  String get firstRunSecuring => 'Securing your wallet…';

  @override
  String get firstRunTryAgain => 'Try again';

  @override
  String get firstRunBiometricsNotSetUp =>
      'Biometric unlock was not set up. You can turn it on in Settings.';

  @override
  String get backupTitle => 'Recovery phrase';

  @override
  String get backupPinReason => 'Enter your PIN to show the recovery phrase.';

  @override
  String get backupCopyWarning =>
      'A screenshot or photo of the phrase is a full copy of your wallet: anyone who sees it can take your funds, and photo apps may upload it to the cloud. Paper is safest.';

  @override
  String get backupCopyAgree => 'I will keep any copy of the phrase private';

  @override
  String get backupShowPhrase => 'Show recovery phrase';

  @override
  String get backupWarningIconLabel => 'Warning';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Write these $count words on paper, in order, and keep them private. They are the only way to restore this wallet.',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return 'Word $number: $word';
  }

  @override
  String get unlockTitle => 'Unlock wallet';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinRepeatLabel => 'Repeat PIN';

  @override
  String pinChooseTitle(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Choose a $digits-digit PIN',
    );
    return '$_temp0';
  }

  @override
  String get pinConfirmTitle => 'Enter the PIN again';

  @override
  String get pinChooseDifferent => 'Choose a different PIN';

  @override
  String get pinMismatch => 'The PINs do not match. Choose a PIN again.';

  @override
  String get pinBiometricsIconLabel => 'Biometrics';

  @override
  String get pinBiometricsQuestion => 'Unlock with fingerprint or face?';

  @override
  String get pinBiometricsPinStillWorks =>
      'You can still use your PIN at any time.';

  @override
  String get pinBiometricsEnable => 'Use biometrics';

  @override
  String get pinBiometricsNotNow => 'Not now';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count tries left before a pause.',
      one: 'Wrong PIN. 1 try left before a pause.',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. The next try is checked after $count seconds.',
      one: 'Wrong PIN. The next try is checked after 1 second.',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. The next try is checked after $count minutes.',
      one: 'Wrong PIN. The next try is checked after 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Checking the PIN in $count seconds…',
      one: 'Checking the PIN in 1 second…',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Checking the PIN in $count minutes…',
      one: 'Checking the PIN in 1 minute…',
    );
    return '$_temp0';
  }

  @override
  String get pinChecking => 'Checking the PIN…';

  @override
  String get pinPromptTitle => 'Enter your PIN';

  @override
  String get pinUseBiometrics => 'Use biometrics';

  @override
  String get pinForgot => 'Forgot PIN?';

  @override
  String get pinResetTitle => 'Forgot PIN';

  @override
  String get pinResetBody =>
      'The PIN cannot be recovered. You can delete this wallet from the device and restore it from its recovery phrase. Without the phrase, its funds are lost for good.';

  @override
  String get pinResetConfirm => 'I have my recovery phrase';

  @override
  String get pinResetKeep => 'Keep wallet';

  @override
  String get pinResetDelete => 'Delete wallet';

  @override
  String get launchTryAgain => 'Try again';

  @override
  String get unlockStranded =>
      'This wallet could not be read as it should be. Nothing was deleted. Try again after restarting the device. If this stays, you can remove the wallet with “Forgot PIN?” and restore it from its recovery phrase.';

  @override
  String get sendAmountNegative => 'The amount cannot be negative.';

  @override
  String sendAmountAmbiguous(String asWhole, String asDecimal) {
    return 'Write $asWhole or $asDecimal, so the amount is clear.';
  }

  @override
  String get sendAmountUnclear =>
      'Write the amount without separators, such as 1234.5, so the amount is clear.';

  @override
  String get sendAmountNoPrice => 'No price right now. Enter EPIC instead.';

  @override
  String get sendAmountEnterFiatExample => 'Enter an amount such as 10.50';

  @override
  String get sendAmountTooLarge =>
      'That is more EPIC than will ever exist. Check the amount.';

  @override
  String get sendAmountZero => 'Enter an amount above zero.';

  @override
  String get sendUrlUnsupported =>
      'Payments to a wallet URL are not supported. Ask the recipient for their epicbox address.';

  @override
  String get scanQrTooltip => 'Scan QR code';

  @override
  String get sendScanButton => 'Scan';

  @override
  String get sendChooseContactTooltip => 'Choose a contact';

  @override
  String get sendContactsButton => 'Contacts';

  @override
  String get sendMethodEpicbox => 'Epicbox address';

  @override
  String get sendMethodFile => 'Payment file';

  @override
  String get sendFileHelpTooltip => 'How paying by file works';

  @override
  String sendAmountLabel(String unit) {
    return 'Amount ($unit)';
  }

  @override
  String sendUseUnit(String unit) {
    return 'Use $unit';
  }

  @override
  String get sendMax => 'Max';

  @override
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String get sendCopyPasteInstead => 'Copy and paste instead';

  @override
  String get sendSlateBoxTitle => 'Transaction text';

  @override
  String get sendPasteResponseLabel => 'Paste the recipient\'s response';

  @override
  String get sendPasteResponseMissing =>
      'Paste the response text from the recipient.';

  @override
  String get slateFinishPayment => 'Finish payment';

  @override
  String sendResultAutoCancel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'If it is still not completed after $days days, it cancels by itself and the amount unlocks. To stop it sooner, open the payment and tap Cancel payment.',
      one: 'If it is still not completed after 1 day, it cancels by itself and the amount unlocks. To stop it sooner, open the payment and tap Cancel payment.',
    );
    return '$_temp0';
  }

  @override
  String sendResultFeeChanged(String charged, String reviewed) {
    return 'The fee charged was $charged, not the $reviewed shown before, because the wallet picked its coins again when sending.';
  }

  @override
  String get sendResultNoteNotSaved =>
      'The note could not be saved. You can add it by opening the payment.';

  @override
  String get sendHelp => 'Help';

  @override
  String get sendReviewTotal => 'Total';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
  }

  @override
  String sendReviewSendButton(String amount) {
    return 'Send $amount';
  }

  @override
  String get sendReviewEdit => 'Edit';

  @override
  String get slateFileTitle => 'Transaction file';

  @override
  String get slateWrongPayment =>
      'This response is for a different payment. Open the file the recipient returned for this send.';

  @override
  String get slateInvoiceUnsupported =>
      'Payment requests (invoices) are not supported yet.';

  @override
  String get slateNotTransactionFile => 'That file is not a transaction file.';

  @override
  String get slateReading => 'Reading the file';

  @override
  String get slateFileTooLarge =>
      'That file is too large to be a transaction file.';

  @override
  String slatePostedHeadline(String amount) {
    return 'Payment of $amount sent to the network.';
  }

  @override
  String slatePostedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It shows as Completed after $count confirmations.',
      one: 'It shows as Completed after 1 confirmation.',
    );
    return '$_temp0';
  }

  @override
  String slateAcceptedHeadline(String file) {
    return 'Accepted. Return $file to the sender.';
  }

  @override
  String slateAcceptedBody(String amount) {
    return 'The $amount arrive once the sender finishes the payment and it is on the chain.';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return 'Already accepted. Return $file to the sender again.';
  }

  @override
  String slateRepeatedBody(String amount) {
    return 'You accepted this payment before, so this is the same answer, not a second payment. The $amount arrive once the sender finishes it and it is on the chain.';
  }

  @override
  String slateIncomingSend(String amount) {
    return 'Someone is sending you $amount.';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'The recipient\'s answer to your send of $amount (fee $fee).';
  }

  @override
  String get slateIncomingSendHint =>
      'Accept it, then return the response file to the sender.';

  @override
  String get slateIncomingResponseHint =>
      'Finish it to send the payment to the network.';

  @override
  String get slateAcceptPayment => 'Accept payment';

  @override
  String slateHandOverFailed(String file) {
    return 'Could not hand over $file. Please try again.';
  }

  @override
  String get slateSaveToDevice => 'Save to device';

  @override
  String slateSaved(String file) {
    return 'Saved $file';
  }

  @override
  String get slateSaveDialogTitle => 'Save transaction file';

  @override
  String get slateOpenDialogTitle => 'Open transaction file';

  @override
  String get slateNotPostedTitle => 'Not on the network yet';

  @override
  String get slateNotPostedBody =>
      'The payment is finished but the network has not taken it yet. It will be broadcast again from the payment. Do not send it again.';

  @override
  String get slateOpenPayment => 'Open the payment';

  @override
  String get scanQrTitle => 'Scan QR code';

  @override
  String get scanQrHint => 'Point the camera at the recipient\'s QR code.';

  @override
  String get scanQrCameraDenied =>
      'The wallet may not use the camera. To scan, allow camera access for this app in your phone\'s settings. You can also paste the address instead.';

  @override
  String get scanQrCameraFailed =>
      'The camera could not start. Paste the address instead, or try again.';

  @override
  String get scanQrTryAgain => 'Try again';

  @override
  String get scanQrBack => 'Back';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsPickTitle => 'Choose a contact';

  @override
  String get contactsAdd => 'Add contact';

  @override
  String get contactsEmpty =>
      'No contacts yet. Add the people you pay often, so you do not have to paste their address each time.';

  @override
  String get contactsSearchLabel => 'Search contacts';

  @override
  String get contactsNoMatch => 'No contact matches.';

  @override
  String get contactsNameMissing => 'Enter a name.';

  @override
  String contactsDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get contactsDeleteBody =>
      'The address is removed from your contacts. Past payments are not affected.';

  @override
  String get contactsKeep => 'Keep';

  @override
  String get contactsEditTitle => 'Edit contact';

  @override
  String get contactsNewTitle => 'New contact';

  @override
  String get contactsDeleteTooltip => 'Delete contact';

  @override
  String get contactsNameLabel => 'Name';

  @override
  String get contactsAddressLabel => 'Address';

  @override
  String contactsDuplicate(String name) {
    return 'This address is already saved as $name.';
  }

  @override
  String get contactsNoteLabel => 'Note (optional)';

  @override
  String get contactsSave => 'Save contact';

  @override
  String get contactsAddressMissing => 'Enter their address.';

  @override
  String contactsUrlIncomplete(String example) {
    return 'Enter the full wallet URL, such as $example';
  }

  @override
  String contactsAddressInvalid(String example) {
    return 'This is not a valid address. It looks like $example';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNetwork => 'Servers';

  @override
  String get settingsNetworkAndNode => 'Node and Epicbox';

  @override
  String settingsNetworkSubtitle(String network, String node) {
    return '$network · $node';
  }

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Show prices';

  @override
  String get settingsHideBalances => 'Hide balances';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'Same as the device';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPricesOnNotice =>
      'Prices come from CoinGecko, which sees your IP address.';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsPushBlocked =>
      'Notifications are blocked in system settings';

  @override
  String get settingsPushUnavailable =>
      'Notifications are not available in this build';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsBiometrics => 'Unlock with biometrics';

  @override
  String get settingsBiometricsOn => 'Biometric unlock turned on';

  @override
  String get settingsBiometricsOff => 'Biometric unlock turned off';

  @override
  String get settingsBiometricsFailed => 'Biometric unlock was not set up';

  @override
  String get settingsBiometricsPinReason =>
      'Enter your PIN to turn on biometric unlock.';

  @override
  String get settingsAutoLock => 'Auto-lock';

  @override
  String get settingsBackupPhrase => 'Back up recovery phrase';

  @override
  String get settingsPhraseConfirmed => 'Recovery phrase confirmed';

  @override
  String get settingsLockWallet => 'Lock wallet';

  @override
  String get settingsSectionHistory => 'Payment history';

  @override
  String get settingsExportHistory => 'Export history backup';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsImportHistory => 'Import history backup';

  @override
  String get settingsSectionWallet => 'Wallet';

  @override
  String get settingsContacts => 'Contacts';

  @override
  String get settingsSectionInvoices => 'Invoices';

  @override
  String get settingsInvoices => 'Invoice address and trusted services';

  @override
  String get settingsInvoicesSubtitle =>
      'Let services you trust bill you. You approve every invoice.';

  @override
  String get invoiceSettingsTitle => 'Invoices';

  @override
  String get invoiceSettingsAddressTitle => 'Your invoice address';

  @override
  String get invoiceSettingsAddressBody =>
      'Give this address to a service you trust, so it can send you invoices. Your address for payments stays the same.';

  @override
  String get invoiceSettingsQrLabel => 'QR code of your invoice address';

  @override
  String get invoiceSettingsAddressCopied => 'Invoice address copied.';

  @override
  String get invoiceSettingsServicesTitle => 'Trusted services';

  @override
  String get invoiceSettingsNoServices =>
      'No trusted services yet. Invoices from anyone else never reach you.';

  @override
  String get invoiceSettingsAddService => 'Add a service';

  @override
  String invoiceSettingsRemoveTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String invoiceSettingsRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get invoiceSettingsRemoveBody =>
      'This service can no longer send you invoices. Payments you already made are not affected.';

  @override
  String get invoiceSettingsKeep => 'Keep';

  @override
  String get invoiceSettingsRemoveConfirm => 'Remove';

  @override
  String invoiceSettingsRemoved(String name) {
    return '$name can no longer send you invoices.';
  }

  @override
  String get invoiceSettingsRotate => 'Get a new invoice address';

  @override
  String get invoiceSettingsRotateHint => 'The current one stops working.';

  @override
  String get invoiceSettingsRotateTitle => 'Get a new invoice address?';

  @override
  String get invoiceSettingsRotateBody =>
      'Your current invoice address stops working for good. Every service that bills you needs the new one.';

  @override
  String get invoiceSettingsRotateConfirm => 'Get new address';

  @override
  String get invoiceSettingsRotated =>
      'New invoice address ready. Give it to your services.';

  @override
  String invoiceSettingsDropped(int count) {
    return 'Dropped from unknown senders this session: $count';
  }

  @override
  String get invoiceSettingsAddTitle => 'Add a trusted service';

  @override
  String get invoiceSettingsAddExplanation =>
      'A trusted service can send invoices to your invoice address; messages from anyone else are dropped. Nothing is paid until you approve each invoice with your PIN or fingerprint.';

  @override
  String get invoiceSettingsLabelLabel => 'Name';

  @override
  String get invoiceSettingsLabelMissing => 'Give the service a name.';

  @override
  String get invoiceSettingsServiceAddressLabel =>
      'The service\'s epicbox address';

  @override
  String get invoiceSettingsAddressMissing =>
      'Paste or scan the address the service shows.';

  @override
  String get invoiceSettingsAddButton => 'Add service';

  @override
  String invoiceSettingsAdded(String name) {
    return '$name can now send you invoices.';
  }

  @override
  String get settingsRescan => 'Rescan the chain';

  @override
  String get settingsRescanFinished => 'Rescan finished';

  @override
  String get settingsRescanTitle => 'Rescan the chain';

  @override
  String get settingsRescanBody =>
      'The wallet looks for its funds again. An earlier start finds more but takes longer; the whole chain can take a long time.';

  @override
  String get settingsRescanFromDate => 'From a date';

  @override
  String get settingsRescanFromHeight => 'From a block height';

  @override
  String get settingsRescanWholeChain => 'The whole chain';

  @override
  String get settingsRescanPickDate => 'Pick a date';

  @override
  String get settingsRescanPickDateFirst => 'Pick a date first.';

  @override
  String get settingsRescanStartHeight => 'Start height';

  @override
  String get settingsRescanHeightInvalid =>
      'Enter a block height of 1 or more.';

  @override
  String get settingsRescanButton => 'Rescan';

  @override
  String get settingsDeleteWallet => 'Delete this wallet';

  @override
  String get settingsDeleteDuringScan =>
      'Wait for the scan to finish before deleting the wallet.';

  @override
  String get settingsDeletePinReason => 'Enter your PIN to delete this wallet.';

  @override
  String get settingsDeleteWarningIcon => 'Warning';

  @override
  String get settingsDeleteTitle => 'Delete this wallet?';

  @override
  String get settingsDeleteBody =>
      'This removes the wallet, its history and its PIN from this device. Only the recovery phrase can bring the funds back. Without it, they are lost for good.';

  @override
  String get settingsDeleteHavePhrase =>
      'I have written down my recovery phrase';

  @override
  String get settingsDeleteConfirmWord => 'delete';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return 'Type \"$word\" to confirm';
  }

  @override
  String get settingsDeleteKeep => 'Keep wallet';

  @override
  String get settingsDeleteConfirm => 'Delete wallet';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAboutNetwork => 'Network';

  @override
  String get settingsEpicboxServer => 'Epicbox server';

  @override
  String settingsUpdateTo(String version) {
    return 'Update to $version';
  }

  @override
  String get settingsUpdateInstall => 'Install';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsSendFeedback => 'Send feedback';

  @override
  String get settingsSendFeedbackHint => 'Report a problem or suggest an idea';

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get settingsLicences => 'Licences';

  @override
  String get licencesLead =>
      'Open-source software in this wallet. Each component keeps its own licence; the full texts are one tap away.';

  @override
  String get licencesApp =>
      'Epic Cash Mobile by BT Labs: Apache-2.0. The code is on GitHub.';

  @override
  String get licencesFlutter =>
      'Flutter and its Dart packages: BSD 3-Clause and similar permissive licences.';

  @override
  String get licencesLepic =>
      'LEPIC, the Epic Cash wallet library: Apache 2.0, with the Epic Cash secp256k1-zkp fork (CC0) and Rust crates under MIT or Apache 2.0, among them tokio, rustls, rusqlite and blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, version 3. Its source is named below.';

  @override
  String get licencesFonts =>
      'Fonts Montserrat and JetBrains Mono: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'All licence texts';

  @override
  String get settingsCopyLink => 'Copy link';

  @override
  String get settingsLinkCopied => 'Link copied';

  @override
  String get settingsPinTitle => 'Change PIN';

  @override
  String get settingsPinEnterCurrent => 'Enter your current PIN';

  @override
  String get settingsPinCurrentLabel => 'Current PIN';

  @override
  String settingsPinChooseNew(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Choose a new $digits-digit PIN',
    );
    return '$_temp0';
  }

  @override
  String get settingsPinChanged => 'PIN changed';

  @override
  String get settingsPinChangedBiometricsOff =>
      'PIN changed. Biometric unlock is off; turn it on again below.';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpStillStuck => 'Still stuck?';

  @override
  String get helpTellUs => 'Describe what happened or what is unclear.';

  @override
  String get helpSendFeedback => 'Send feedback';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackIntro =>
      'Describe what went wrong or what could be better.';

  @override
  String get feedbackMessageLabel => 'Your message';

  @override
  String get feedbackMessageMissing => 'Write a few words about what happened.';

  @override
  String get feedbackEmailLabel => 'Email for a reply (optional)';

  @override
  String get feedbackEmailInvalid =>
      'This does not look like an email address.';

  @override
  String get feedbackAttachLogs => 'Attach diagnostic logs';

  @override
  String get feedbackAttachLogsHint =>
      'Logs help find the problem. The recovery phrase, PIN and other secrets are removed first.';

  @override
  String get feedbackPreviewButton => 'Preview what is sent';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackShareOrSaveInstead => 'Share or save instead';

  @override
  String get feedbackFileExplanation =>
      'Your feedback becomes a text file you can send by email or chat, or save.';

  @override
  String get feedbackShareOrSave => 'Share or save';

  @override
  String get feedbackShareHint => 'Send it by email or a chat app';

  @override
  String get feedbackSaveToDevice => 'Save to device';

  @override
  String get feedbackSaveDialogTitle => 'Save feedback';

  @override
  String feedbackSavedFile(String name) {
    return 'Saved $name';
  }

  @override
  String get feedbackSent => 'Thank you. Your feedback was sent.';

  @override
  String get feedbackThanks => 'Thank you for your feedback.';

  @override
  String feedbackServerAnswered(int status) {
    return 'The feedback server answered $status.';
  }

  @override
  String get feedbackServerNoAnswer => 'The feedback server did not answer.';

  @override
  String get feedbackServerUnreachable =>
      'Could not reach the feedback server.';

  @override
  String get feedbackPreviewTitle => 'What is sent';

  @override
  String get settingsAdvancedOptions => 'Advanced options';

  @override
  String get settingsAdvancedOptionsSubtitle =>
      'Technical details, files and logs';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsSectionPrivacyNetwork => 'Privacy & network';

  @override
  String get settingsSectionHelpFeedback => 'Help & feedback';

  @override
  String get settingsStateBackUp => 'Back up your recovery phrase';

  @override
  String get settingsStateNotBackedUp => 'Not backed up yet';

  @override
  String get settingsStatePin => 'PIN';

  @override
  String get settingsStatePinBiometrics => 'PIN and biometrics';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'Use status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Network status and information provided by status.btlabs.uk';

  @override
  String get txStepStarted => 'Payment started';

  @override
  String get txStepAccepted => 'Recipient accepted';

  @override
  String get txStepPosted => 'Sent to the network';

  @override
  String get txStepConfirming => 'Confirming';

  @override
  String get txStepConfirmed => 'Confirmed';

  @override
  String get txStepArrived => 'Payment arrived';

  @override
  String get txStepSenderFinished => 'Sender finished it';

  @override
  String get fileHelpTitle => 'How a payment file works';

  @override
  String get fileHelpYou => 'You';

  @override
  String get fileHelpFriend => 'Friend';

  @override
  String get fileHelpSendStep1 => 'You make a payment file.';

  @override
  String get fileHelpSendStep2 =>
      'You send it to your friend any way you like, such as a chat or an email.';

  @override
  String get fileHelpSendStep3 =>
      'Your friend opens it in their wallet and sends you back the signed reply.';

  @override
  String get fileHelpSendStep4 =>
      'You open the reply, and the payment is on its way.';

  @override
  String get fileHelpReceiveStep1 =>
      'Your friend makes a payment file for you.';

  @override
  String get fileHelpReceiveStep2 =>
      'They send it to you any way they like, such as a chat or an email.';

  @override
  String get fileHelpReceiveStep3 =>
      'You open it in your wallet and send back the signed reply.';

  @override
  String get fileHelpReceiveStep4 =>
      'Your friend opens the reply, and the payment is on its way to you.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get fileHelpPause => 'Pause the animation';

  @override
  String get fileHelpPlay => 'Play the animation';

  @override
  String get demoPinFilled => 'Demo PIN, filled in for you';

  @override
  String get demoPinSkip => 'Skip';

  @override
  String get demoPinSetUpTitle => 'Setting up your demo wallet';

  @override
  String get demoPinUnlockTitle => 'Opening your demo wallet';

  @override
  String get sendStepRecipient => 'Recipient';

  @override
  String get sendStepAmount => 'Amount';

  @override
  String get sendStepReview => 'Review';

  @override
  String sendStepOf(int step, int total) {
    return '$step of $total';
  }

  @override
  String get sendHowItWorks => 'How it works';

  @override
  String get sendAddressLabel => 'Epic address';

  @override
  String get sendAddressMissing => 'Enter their address.';

  @override
  String get sendAddressWebLink => 'This is a web link, not an Epic address.';

  @override
  String get sendAddressIncomplete => 'This address looks incomplete.';

  @override
  String get sendAddressNotEpic => 'This is not an Epicbox address.';

  @override
  String get sendNewRecipient => 'New recipient';

  @override
  String get sendSaveContact => 'Save as contact';

  @override
  String get sendRecent => 'Recent';

  @override
  String get sendUseFile => 'No address? Use a payment file';

  @override
  String sendTo(String who) {
    return 'To $who';
  }

  @override
  String sendAvailable(String amount) {
    return 'Available $amount';
  }

  @override
  String sendFeeQuiet(String fee) {
    return 'Network fee $fee';
  }

  @override
  String get sendAddNote => 'Add a note';

  @override
  String get sendNoteLabel => 'Note';

  @override
  String get sendNoteHelper => 'They see it too.';

  @override
  String get sendNetworkFee => 'Network fee';

  @override
  String get sendChecking => 'Checking…';

  @override
  String get sendReady => 'Ready to send';

  @override
  String get sendNodeDown => 'Can\'t reach the network right now.';

  @override
  String get sendRelayDown => 'Their relay isn\'t answering.';

  @override
  String get sendListenerDown => 'Not connected yet. You can still send.';

  @override
  String get sendPayWithFile => 'Pay with a file instead';

  @override
  String get sendAnyway => 'Send anyway';

  @override
  String sendTrackSentTo(String name) {
    return 'Sent to $name';
  }

  @override
  String get sendTrackSent => 'Sent';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Waiting for $name\'s wallet';
  }

  @override
  String get sendTrackWaiting => 'Waiting for their wallet';

  @override
  String sendTrackSignedBy(String name) {
    return '$name\'s wallet signed';
  }

  @override
  String get sendTrackSigned => 'Their wallet signed';

  @override
  String get sendTrackOnNetwork => 'Sent to the network';

  @override
  String get sendTrackConfirmed => 'Confirmed';

  @override
  String sendTrackOffline(String amount) {
    return 'Their wallet finishes it when it opens. $amount stays on hold until then.';
  }

  @override
  String get sendTrackIfNot => 'What if it never finishes?';

  @override
  String get sendTrackCancelled => 'This payment was cancelled.';

  @override
  String get sendNoCoins => 'No coins to send yet.';

  @override
  String get sendFileTitle => 'Pay with a file';

  @override
  String get sendMakeFile => 'Make payment file';

  @override
  String get sendFileMade => 'File made';

  @override
  String sendFileOnHold(String amount) {
    return '$amount on hold';
  }

  @override
  String get sendFileWaitingReply => 'Waiting for their reply';

  @override
  String get sendFileShareHint => 'Send them this file. Then open their reply.';

  @override
  String get sendOpenReply => 'Open their reply';

  @override
  String get handshakePayment => 'Payment';

  @override
  String get handshakeRequest => 'Request';

  @override
  String get handshakeYou => 'You';

  @override
  String get handshakeThem => 'Them';

  @override
  String get handshakeNetwork => 'Network';

  @override
  String get handshakePay1 =>
      'Your wallet sends the payment to the relay. Your coins go on hold.';

  @override
  String get handshakePay2 =>
      'The relay passes it on. Their wallet adds its part and signs.';

  @override
  String get handshakeFinish =>
      'Your wallet finishes it and sends it to the network.';

  @override
  String get handshakeConfirm => 'The network confirms it.';

  @override
  String get handshakeReq1 => 'Your wallet sends the request to the relay.';

  @override
  String get handshakeReq2 =>
      'The relay passes it on. They approve it, and their wallet adds the coins and signs.';

  @override
  String get handshakeRelay => 'Relay';

  @override
  String get handshakeFile => 'File';

  @override
  String get handshakeBack => 'Their wallet sends it back to the relay.';

  @override
  String get handshakeRelayBack => 'The relay passes it back to your wallet.';

  @override
  String get handshakeFile1 =>
      'Your wallet saves a payment file. You send it to them yourself.';

  @override
  String get handshakeFile2 =>
      'They open it. Their wallet adds its part, signs and saves a reply.';

  @override
  String get handshakeFile3 => 'They send the reply file back to you.';

  @override
  String get handshakeFile4 => 'You open their reply in your wallet.';

  @override
  String get handshakePrevious => 'Previous step';

  @override
  String get handshakeNext => 'Next step';

  @override
  String sendRelayRefused(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their relay didn\'t take it. The amount is on hold until you cancel it, or for at most $days days.',
      one: 'Their relay didn\'t take it. The amount is on hold until you cancel it, or for at most 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost =>
      'Their relay didn\'t take it. Check Wallet before you send again.';

  @override
  String get sendCancelAndFile => 'Cancel and pay with a file';

  @override
  String get sendLeaveIt => 'Leave it for now';

  @override
  String get sendSending => 'Sending…';

  @override
  String trackStepDone(String step) {
    return '$step, done';
  }

  @override
  String trackStepNow(String step) {
    return '$step, now';
  }

  @override
  String trackStepLater(String step) {
    return '$step, later';
  }

  @override
  String balanceLineOnHold(String amount) {
    return '$amount on hold';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount coming in';
  }

  @override
  String get demoTestCoinsPill => 'Test coins';

  @override
  String get demoTestCoinsPillTip =>
      'Floonet, Epic\'s test network. The coins have no value.';

  @override
  String demoLeftHours(int hours) {
    return '$hours h left';
  }

  @override
  String demoLeftMinutes(int minutes) {
    return '$minutes min left';
  }

  @override
  String get demoReceiveKeepOpen => 'Keep this tab open to receive.';

  @override
  String get demoGuideTitle => 'Try a payment';

  @override
  String get demoGuideSend => 'Send some to someone';

  @override
  String get demoGuideSendHint =>
      'Pay a friend\'s demo, or open this page in a different browser or a private window.';

  @override
  String get demoGuideOpenSend => 'Go to Send';

  @override
  String get demoGuideAsking =>
      'Asking the test faucet. This can take a minute.';

  @override
  String get demoGuideDone =>
      'Both done. Look around as long as the demo lasts.';

  @override
  String get demoGuideHide => 'Hide';

  @override
  String get demoGuideHideLabel => 'Hide the demo steps';

  @override
  String demoGuideStepDone(String step) {
    return '$step, done';
  }

  @override
  String demoGuideStepToDo(String step) {
    return '$step, not done yet';
  }

  @override
  String get receiveTabEpicbox => 'Epicbox';

  @override
  String get receiveTabTor => 'Tor';

  @override
  String get receiveTabFile => 'File';

  @override
  String get receiveTorAddressLabel => 'Tor address';

  @override
  String get receiveTorQrLabel => 'QR code of your Tor address';

  @override
  String get torReceivingTitle => 'Tor receiving';

  @override
  String get torHonestLine =>
      'Tor receiving works while the app is open or briefly in the background.';

  @override
  String get torStateOff => 'Tor receiving is off';

  @override
  String torStateStarting(int percent) {
    return 'Connecting to Tor… $percent%';
  }

  @override
  String get torStatePublishing => 'Publishing your Tor address…';

  @override
  String get torStateReady => 'Tor receiving is on';

  @override
  String torStateNotReachable(String reason) {
    return 'Your Tor address is not reachable yet. $reason';
  }

  @override
  String get torFailureMissing => 'Tor is not included in this app.';

  @override
  String get torFailureStart => 'Tor did not start.';

  @override
  String get torFailureNetwork =>
      'Could not reach the Tor network. Check the connection.';

  @override
  String get torFailureClock =>
      'The phone\'s clock is wrong. Tor needs the right time.';

  @override
  String get torFailureListener => 'The wallet could not open its Tor address.';

  @override
  String get torFailureStopped => 'Tor stopped.';

  @override
  String get torFailurePublish => 'The Tor address could not be published.';

  @override
  String get torFailureKeys => 'Tor did not accept the wallet\'s address key.';

  @override
  String get sendOnionIncomplete =>
      'This is not a complete Tor address. Copy it again from the recipient.';

  @override
  String get sendTorUnavailable =>
      'This app cannot send over Tor, so a Tor address cannot be paid here.';

  @override
  String get sendOverTor => 'Over Tor';

  @override
  String get sendTorConnectsOnSend => 'Tor connects when you send.';

  @override
  String get sendTorReady => 'Ready to send over Tor';

  @override
  String get sendTorReaching =>
      'Reaching their wallet over Tor… This can take a while. Keep the app open.';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their wallet was not reached over Tor. The amount is on hold until you cancel it, or for at most $days days.',
      one: 'Their wallet was not reached over Tor. The amount is on hold until you cancel it, or for at most 1 day.',
    );
    return '$_temp0';
  }

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Nothing was sent.';
  }

  @override
  String get sendTryAgain => 'Try again';

  @override
  String get sendCancelPayment => 'Cancel payment';

  @override
  String get settingsSectionReceiving => 'Receiving';

  @override
  String get homeAvailableToSpend => 'Available to spend';

  @override
  String get homeTileWaitingSender => 'Waiting for sender';

  @override
  String get homeTileLocked => 'Locked in sends';

  @override
  String get homeTileMaturing => 'Rewards maturing';

  @override
  String get homeTileTotal => 'Total';

  @override
  String homeViewAll(int count) {
    return 'View all $count';
  }

  @override
  String get homeDestActivity => 'Activity';

  @override
  String get homeDestOutputs => 'Outputs';

  @override
  String get txStatusReceived => 'Received';

  @override
  String get txStatusSent => 'Sent';

  @override
  String sendPinReason(String amount) {
    return 'Enter the PIN to send $amount.';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'Enter the PIN to make a payment file for $amount.';
  }

  @override
  String get outputsTitle => 'Outputs';

  @override
  String get outputsSpendable => 'Spendable';

  @override
  String get outputsConfirming => 'Confirming';

  @override
  String get outputsLockedTile => 'Locked in sends';

  @override
  String get outputsImmature => 'Immature';

  @override
  String outputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs',
      one: '1 output',
    );
    return '$_temp0';
  }

  @override
  String get outputsSplitButton => 'Split…';

  @override
  String get outputsConsolidateButton => 'Consolidate…';

  @override
  String get outputsSplitNeeds => 'Split needs at least 1 EPIC spendable.';

  @override
  String get outputsConsolidateNeeds =>
      'Consolidate needs at least 2 spendable outputs.';

  @override
  String get outputsWaitLocked =>
      'Wait until the send in progress confirms (about 3 blocks).';

  @override
  String get outputsStrategy => 'Strategy for sends';

  @override
  String get outputsSmallest => 'Smallest';

  @override
  String get outputsAll => 'All';

  @override
  String get outputsSmallestText =>
      'Spends the fewest small outputs; the rest of the balance stays spendable while the change confirms.';

  @override
  String get outputsAllText =>
      'Spends every spendable output and returns one change output. Everything is locked until it confirms; fewer, larger outputs afterwards.';

  @override
  String get outputsSplitChange => 'Split change';

  @override
  String get outputsSplitChangeText => 'When few outputs would be left';

  @override
  String outputsFilterAll(int count) {
    return 'All $count';
  }

  @override
  String outputsFilterSpendable(int count) {
    return 'Spendable $count';
  }

  @override
  String outputsFilterConfirming(int count) {
    return 'Confirming $count';
  }

  @override
  String outputsFilterLocked(int count) {
    return 'Locked $count';
  }

  @override
  String get outputsShowSpent => 'Show spent';

  @override
  String get outputsHideSpent => 'Hide spent';

  @override
  String get outputsWordSpendable => 'Spendable';

  @override
  String get outputsWordConfirming => 'Confirming';

  @override
  String get outputsWordFinalizing => 'Awaiting finalization';

  @override
  String get outputsWordImmature => 'Immature';

  @override
  String get outputsWordMining => 'Mining';

  @override
  String get outputsWordLocked => 'Locked';

  @override
  String get outputsWordSpent => 'Spent';

  @override
  String get outputsMeanSpendable => 'Can be spent now.';

  @override
  String outputsMeanConfirming(int need) {
    return 'Needs $need confirmations before it can be spent.';
  }

  @override
  String get outputsMeanFinalizing =>
      'Waiting for the sender to finish the payment.';

  @override
  String get outputsMeanImmature =>
      'A mining reward. It can be spent after a delay.';

  @override
  String get outputsMeanMining => 'A mining reward not confirmed yet.';

  @override
  String get outputsMeanLocked => 'Being spent by a send in progress.';

  @override
  String get outputsMeanSpent => 'Already spent.';

  @override
  String outputsNoteReceived(String date) {
    return 'Received $date';
  }

  @override
  String outputsNoteSend(String who) {
    return 'Send to $who';
  }

  @override
  String get outputsNoteSendPlain => 'Send in progress';

  @override
  String get outputsFactHeight => 'Height';

  @override
  String get outputsFactConfirmations => 'Confirmations';

  @override
  String get outputsFactTransaction => 'Transaction';

  @override
  String get outputsFactCommitment => 'Commitment';

  @override
  String get outputsCopy => 'Copy';

  @override
  String get outputsCopied => 'Commitment copied';

  @override
  String get outputsEmpty => 'No outputs yet';

  @override
  String get outputsEmptyHint =>
      'The first payment received makes one. Receive shows the address.';

  @override
  String get outputsNoMatch => 'No outputs in this view';

  @override
  String get outputsRetry => 'Retry';

  @override
  String outputsSettingsSubtitle(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs · $strategy',
      one: '1 output · $strategy',
    );
    return '$_temp0';
  }

  @override
  String get outputsCancel => 'Cancel';

  @override
  String get outputsSplitTitle => 'Split outputs';

  @override
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  ) {
    return 'Spends $spent ($amount) and makes $made of about $each each. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then.';
  }

  @override
  String get outputsToMake => 'Outputs to make';

  @override
  String get outputsStepperHint => '2 to 10';

  @override
  String get outputsFactFee => 'Network fee';

  @override
  String get outputsFactEach => 'Each output';

  @override
  String outputsFactAbout(String amount) {
    return 'about $amount';
  }

  @override
  String get outputsFactLocked => 'Locked';

  @override
  String outputsFactLockedValue(String amount) {
    return '$amount, about 3 blocks';
  }

  @override
  String get outputsNothingSpendable => 'Nothing stays spendable meanwhile.';

  @override
  String get outputsMinEach => 'Each output must be at least 0.5 EPIC.';

  @override
  String outputsSplitInto(int count) {
    return 'Split into $count';
  }

  @override
  String get outputsConsolidateTitle => 'Consolidate outputs';

  @override
  String outputsConsolidateText(String amount, String result, String spent) {
    return 'Spends $spent ($amount) and makes one output of $result. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then. The next send spends one output, so its fee is the smallest.';
  }

  @override
  String get outputsConsolidateAction => 'Consolidate';

  @override
  String get outputsSplitPin => 'Confirm with your PIN to split outputs';

  @override
  String get outputsConsolidatePin =>
      'Confirm with your PIN to consolidate outputs';

  @override
  String outputsSplitStarted(int count) {
    return 'Split started: $count outputs, confirming in about 3 blocks';
  }

  @override
  String get outputsConsolidateStarted =>
      'Consolidate started: one output, confirming in about 3 blocks';

  @override
  String get outputsAdvanced => 'Advanced';

  @override
  String get outputsColState => 'State';

  @override
  String get outputsColValue => 'Value';

  @override
  String get outputsColConfirmations => 'Confirmations';

  @override
  String homePendingShort(String amount) {
    return '$amount stays locked until the recipient\'s wallet answers.';
  }

  @override
  String get contactsSearchHint => 'Name or address';

  @override
  String get contactsEmptyTitle => 'No contacts yet';

  @override
  String get contactsEmptyCaption => 'A contact is a name for an address.';

  @override
  String contactsNoMatchQuery(String query) {
    return 'No contact matches \"$query\"';
  }

  @override
  String get contactsSendAction => 'Send';

  @override
  String get contactsEditAction => 'Edit';

  @override
  String get contactsAddressHeading => 'Address';

  @override
  String get contactsNoteHeading => 'Note';

  @override
  String get contactsShowCode => 'Show code';

  @override
  String get contactsHideCode => 'Hide code';

  @override
  String contactsQrLabel(String name) {
    return 'QR code of $name\'s address';
  }

  @override
  String get contactsDeleteConfirmBody =>
      'Payments to this address show the address instead of the name after this.';

  @override
  String contactsDeleted(String name) {
    return '$name deleted.';
  }

  @override
  String get contactsCopied => 'Address copied.';

  @override
  String get invoicesNewRequest => 'New request';

  @override
  String get invoicesSegmentSent => 'Sent';

  @override
  String invoicesSegmentCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'none',
    );
    return '$label, $_temp0';
  }

  @override
  String get invoicesToPayEmpty => 'No invoices to pay';

  @override
  String get invoicesToPayEmptyCaption =>
      'Services on your trusted list can bill this wallet. Each invoice waits here for your approval.';

  @override
  String get invoicesSentEmpty => 'No requests sent';

  @override
  String get invoicesSentEmptyCaption =>
      'A request asks someone to pay you an amount.';

  @override
  String get invoicesWaitingPayment => 'Waiting for payment';

  @override
  String get invoicesExpires => 'Expires';

  @override
  String invoicesUntil(String time) {
    return 'until $time';
  }

  @override
  String get invoicesMessage => 'Message';

  @override
  String get invoicesFrom => 'From';

  @override
  String get invoicesPaysFrom => 'Pays from';

  @override
  String invoicesAvailable(String amount) {
    return 'Available to spend $amount';
  }

  @override
  String invoicesShort(String amount) {
    return 'Not enough to pay. $amount short.';
  }

  @override
  String get invoicesCheckNode => 'Node';

  @override
  String get invoicesCheckEpicbox => 'Epicbox';

  @override
  String get invoicesNodeOk => 'Responding';

  @override
  String get invoicesNodeDown => 'Not responding';

  @override
  String get invoicesEpicboxOk => 'Connected';

  @override
  String get invoicesEpicboxDown => 'Not connected';

  @override
  String get invoicesSendRequest => 'Send request';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer is asked to pay $amount. The request expires in 24 h.';
  }

  @override
  String get invoicesRequestHowTitle => 'Before you request';

  @override
  String get netStatusNode => 'Node';

  @override
  String get netStatusEpicbox => 'Epicbox';

  @override
  String get netStatusTor => 'Tor';

  @override
  String get netStatusSynced => 'Synced';

  @override
  String get netStatusSyncing => 'Syncing';

  @override
  String netStatusSyncingPercent(int percent) {
    return 'Syncing $percent %';
  }

  @override
  String get netStatusConnecting => 'Connecting';

  @override
  String netStatusBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Behind $countString',
      one: 'Behind $countString',
    );
    return '$_temp0';
  }

  @override
  String get netStatusOffline => 'Offline';

  @override
  String get netStatusOnline => 'Online';

  @override
  String get netStatusOff => 'Off';

  @override
  String get netStatusOn => 'On';

  @override
  String get netStatusFailed => 'Failed';

  @override
  String netStatusStarting(int percent) {
    return 'Starting $percent %';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => 'Network status';

  @override
  String get serverMyRelays => 'My servers';

  @override
  String get serverRemoveRelay => 'Remove from my servers';

  @override
  String get serverRemoveInUse => 'In use. Switch to another server first.';

  @override
  String get serverRemoveRelayTitle => 'Remove this server?';

  @override
  String get serverRemoveNodeTitle => 'Remove this node?';

  @override
  String serverRemoveBody(String host) {
    return '$host leaves this list. Type it in again to use it later.';
  }

  @override
  String get serverRemoveConfirm => 'Remove';

  @override
  String get serverSupportsNotifications => 'Supports notifications';

  @override
  String get netStatusReachable => 'Reachable';

  @override
  String get netStatusPublishing => 'Publishing…';

  @override
  String get netStatusNotReachable => 'Not reachable';

  @override
  String get netStatusTorOpenHint => 'Opens the privacy settings';

  @override
  String get netStatusDirectOpenHint => 'Opens the Direct receive address';

  @override
  String get netStatusOpenHint => 'Shows the servers';

  @override
  String get serverNodeTitle => 'Node';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'Find or type a node address';

  @override
  String serverUseAddress(String address) {
    return 'Use $address';
  }

  @override
  String get serverTesting => 'Testing…';

  @override
  String serverTestAnswer(String height, String version) {
    return 'Block $height · v$version';
  }

  @override
  String serverTestFailed(String error) {
    return 'No answer. $error';
  }

  @override
  String get serverMyNodes => 'My nodes';

  @override
  String get serverPublicNodes => 'Public nodes';

  @override
  String get serverPublicRelays => 'Public servers';

  @override
  String get serverHealthUnknown =>
      'status.btlabs.uk not reachable; health unknown';

  @override
  String get serverAtTip => 'at tip';

  @override
  String serverBehindShort(String count) {
    return '−$count';
  }

  @override
  String serverBehindLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks behind',
      one: '$count block behind',
    );
    return '$_temp0';
  }

  @override
  String get serverAddMine => 'Add to my nodes';

  @override
  String get serverRemoveMine => 'Remove from my nodes';

  @override
  String get serverNotResponding => 'Not responding';

  @override
  String get serverHealthy => 'Healthy';

  @override
  String get serverDegraded => 'Degraded';

  @override
  String get serverHealthNone => 'Health unknown';

  @override
  String get serverCurrent => 'Current';

  @override
  String get serverDefault => 'Default';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % up';
  }

  @override
  String serverSwitchTo(String host) {
    return 'Switch to $host';
  }

  @override
  String get serverNodeSwitchNote =>
      'The wallet reconnects. Balances are checked again against the new node.';

  @override
  String get serverRelayWarning =>
      'Your address includes this server. Switching changes your address; senders need the new one.';

  @override
  String get serverRelaySwitchNote =>
      'Your address changes; senders need the new one.';

  @override
  String get serverOtherRelay => 'Other server, host or host:port';

  @override
  String get serverFactHeight => 'Height';

  @override
  String get serverFactVersion => 'Version';

  @override
  String get serverFactPeers => 'Peers';

  @override
  String get serverFactUptime => 'Uptime 24 h';

  @override
  String serverHeightAtTip(String height) {
    return '$height · at tip';
  }

  @override
  String serverNodesAgree(String height) {
    return 'Nodes agree on $height';
  }

  @override
  String serverNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$up of $total nodes up',
      one: '$up of $total node up',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'last block $seconds s ago',
      one: 'last block $seconds s ago',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'last block $minutes min ago',
      one: 'last block $minutes min ago',
    );
    return '$_temp0';
  }

  @override
  String serverCheckedAt(String time) {
    return 'status.btlabs.uk, checked $time';
  }

  @override
  String serverRowLabel(String host, String facts) {
    return '$host, $facts';
  }

  @override
  String get methodEpicbox => 'Epicbox';

  @override
  String get methodHttp => 'HTTP';

  @override
  String get methodTor => 'Tor';

  @override
  String get methodFile => 'File';

  @override
  String get methodArtCaptionEpicbox => 'Epicbox server holds it';

  @override
  String get methodArtCaptionHttp => 'Straight to their wallet';

  @override
  String get methodArtCaptionTor => 'Straight, through Tor';

  @override
  String get methodArtCaptionFile => 'File out, response back';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: the payment goes to the Epicbox server, which holds it until the recipient\'s wallet is back';

  @override
  String get methodArtLabelHttp =>
      'HTTP: the payment goes straight to the recipient\'s wallet, which must be open';

  @override
  String get methodArtLabelTor =>
      'Tor: the payment goes straight to the recipient\'s wallet, routed through the Tor network';

  @override
  String get methodArtLabelFile =>
      'File: a transaction file is handed over, a response file comes back, then the sender finalizes';

  @override
  String get methodSendEpicboxTitle => 'The recipient can be offline.';

  @override
  String get settingsShowTipsAgain => 'Show tips again';

  @override
  String get settingsShowTipsAgainDone => 'Tips will show again';

  @override
  String get tipHide => 'Hide tip';

  @override
  String get methodSendEpicboxLine =>
      'The Epicbox server holds the payment until they open their wallet.';

  @override
  String get methodSendHttpTitle => 'Straight to their wallet.';

  @override
  String get methodSendHttpLine =>
      'It must be open and reachable at its HTTP address.';

  @override
  String get methodSendTorTitle => 'Straight to their wallet, over Tor.';

  @override
  String get methodSendTorLine =>
      'Slower and more private. Their wallet must be open.';

  @override
  String get methodSendFileTitle => 'No connection needed.';

  @override
  String get methodSendFileLine =>
      'Hand the file over, get their response file back, then finalize it here.';

  @override
  String get methodReceiveEpicboxTitle => 'Share it to get paid.';

  @override
  String get methodReceiveEpicboxLine =>
      'Works while the wallet is closed: the Epicbox server holds payments until it is back.';

  @override
  String get methodReceiveTorTitle => 'Slower and more private.';

  @override
  String get methodReceiveTorLine =>
      'Works only while the app is open or briefly in the background.';

  @override
  String get methodReceiveFileTitle => 'Hand a file back and forth.';

  @override
  String get methodReceiveFileLine =>
      'Works with no connection between the wallets.';

  @override
  String get methodAddressKindsTooltip => 'Address kinds';

  @override
  String get sendMethodLabel => 'Method';

  @override
  String get sendToLabel => 'To';

  @override
  String get sendToHint => 'Address or contact';

  @override
  String get sendSwitchedHttp => 'Over HTTP';

  @override
  String get sendSwitchedEpicbox => 'Via Epicbox';

  @override
  String get sendSwitchedTorAnnounce => 'Tor address. Method set to Tor.';

  @override
  String get sendSwitchedHttpAnnounce => 'HTTP address. Method set to HTTP.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Epicbox address. Method set to Epicbox.';

  @override
  String get sendReviewMethodHttp => 'HTTP, straight to their wallet';

  @override
  String get sendCancelRuleEpicbox =>
      'Can be cancelled while it waits for the recipient.';

  @override
  String get sendCancelRuleDirect =>
      'Cannot be cancelled once their wallet accepts it.';

  @override
  String get sendCancelRuleFile =>
      'Can be cancelled until the response file is finalized.';

  @override
  String get sendHttpReaching => 'Reaching their wallet… Keep the app open.';

  @override
  String get sendDeliveredWaitingBlock => 'Delivered · Waiting for a block';

  @override
  String get sendHttpAddressShape =>
      'An HTTP address starts with http:// or https://.';

  @override
  String get sendPlainHttpTitle => 'Not encrypted. Send anyway?';

  @override
  String get sendPlainHttpBody =>
      'Plain HTTP to another device. Anyone on the way can read the transaction. An https:// address is encrypted.';

  @override
  String get sendCancelPossibleWhileWaiting =>
      'Possible while the payment waits for the recipient.';

  @override
  String get receiveEpicboxCaption =>
      'When reading it out, check the first six and last six characters.';

  @override
  String get receiveTorCaption =>
      'Some wallets show the address without .onion; both are the same address.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their wallet was not reached. The amount is on hold until you cancel it, or for at most $days days.',
      one: 'Their wallet was not reached. The amount is on hold until you cancel it, or for at most 1 day.',
    );
    return '$_temp0';
  }

  @override
  String deskInvActFrom(String label) {
    return 'Invoice from $label';
  }

  @override
  String get deskInvActFilter => 'Invoices';

  @override
  String get deskInvActBlock => 'Invoice';

  @override
  String get deskInvActOpen => 'Open in Invoices';

  @override
  String get deskInvActBilledBy => 'Billed by';

  @override
  String get deskInvActOverviewTitle => 'Invoices';

  @override
  String deskInvActOverviewToPay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices to pay',
      one: '1 invoice to pay',
      zero: 'Nothing to pay',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count issued invoices waiting for their payers',
      one: '1 issued invoice waiting for its payer',
      zero: 'No issued invoices waiting',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments need you: retry or cancel them',
      one: '1 payment needs you: retry or cancel it',
    );
    return '$_temp0';
  }

  @override
  String get deskInvActReview => 'Review';

  @override
  String get deskInvActOpenInvoices => 'Open Invoices';

  @override
  String get deskInvNav => 'Invoices';

  @override
  String get deskInvTitle => 'Invoices';

  @override
  String get deskInvTabPay => 'Pay';

  @override
  String get deskInvTabIssue => 'Issue';

  @override
  String deskInvTabCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get deskInvIssueAction => 'Issue an invoice';

  @override
  String get deskInvChecking => 'Checking';

  @override
  String deskInvCheckedAt(String time) {
    return 'Checked at $time';
  }

  @override
  String get deskInvCheckFailedTitle => 'The Epicbox server is not answering';

  @override
  String get deskInvCheckFailedBody =>
      'The lists show what arrived before. Nothing was lost; the wallet tries again every 2 minutes.';

  @override
  String get deskInvReqWaiting => 'Waiting for payer';

  @override
  String get deskInvReqPaid => 'Paid, finalizing';

  @override
  String get deskInvReqPosted => 'Posted';

  @override
  String deskInvConfirming(int count, int total) {
    return 'Confirming $count of $total';
  }

  @override
  String get deskInvCompleted => 'Completed';

  @override
  String get deskInvReqNotPosted => 'Not posted';

  @override
  String get deskInvDeclined => 'Declined';

  @override
  String get deskInvExpired => 'Expired';

  @override
  String get deskInvWithdrawn => 'Withdrawn';

  @override
  String get deskInvReqBounced => 'Sent back';

  @override
  String get deskInvPayWaiting => 'To pay';

  @override
  String get deskInvPayPaying => 'Paying';

  @override
  String get deskInvPayNotDelivered => 'Not delivered';

  @override
  String get deskInvPayDelivered => 'Waiting to post';

  @override
  String get deskInvPayPosted => 'Posted by service';

  @override
  String get deskInvPayWithdrawnAfterPay => 'Withdrawn after paying';

  @override
  String get deskInvPayPastTtl => 'Not on chain';

  @override
  String get deskInvPayCancelled => 'Cancelled';

  @override
  String get deskInvUnpaid => 'Unpaid';

  @override
  String get deskInvYouPay => 'You pay';

  @override
  String deskInvExpiresAt(String time) {
    return 'Expires $time';
  }

  @override
  String get deskInvSlateId => 'Slate ID';

  @override
  String get deskInvAdvanced => 'Advanced';

  @override
  String get deskInvOneDevice =>
      'Use invoices on one device only. Another device with this wallet can take a payment meant for this one.';

  @override
  String get deskInvFailed => 'That did not work. Nothing changed; try again.';

  @override
  String get deskInvHowItWorks => 'How invoices work';

  @override
  String get deskInvAddressHint => 'es…@epicbox.epiccash.com';

  @override
  String get deskInvEpicboxAddress => 'Epicbox address';

  @override
  String get deskInvHelpTitle => 'Invoices';

  @override
  String get deskInvHelpLede =>
      'Bills from trusted senders, paid only after approval.';

  @override
  String get deskInvHelpFlowTitle => 'How an invoice works';

  @override
  String get deskInvHelpFlowShort =>
      'The issuer sends an invoice to the payer\'s invoice address. Nothing is paid until the payer approves it.';

  @override
  String get deskInvHelpFlowIntro =>
      'An invoice asks for a payment. The **issuer** is paid; the **payer** decides.';

  @override
  String get deskInvHelpFlowStep1 =>
      'The issuer\'s wallet sends the invoice to the payer\'s **invoice address** over the Epicbox server.';

  @override
  String get deskInvHelpFlowStep2 =>
      'The payer opens it under [[Invoices › Pay]], checks the sender, the amount and the message, and chooses **Approve and pay** with the wallet password.';

  @override
  String get deskInvHelpFlowStep3 =>
      'The payer\'s wallet sends the payment to the issuer\'s **payments address**.';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return 'The issuer\'s wallet finalizes the payment and posts it to the network. After $confirmations confirmations it is final.';
  }

  @override
  String get deskInvHelpFlowNever =>
      'Nothing is paid without approval, and an invoice never adds money to the payer\'s wallet. Each invoice has a time to pay, at most 48 hours; after it, the invoice can no longer be paid.';

  @override
  String get deskInvHelpFlowIssued =>
      'Invoices this wallet issued are under [[Invoices › Issue]].';

  @override
  String get deskInvHelpTrustTitle => 'Why only trusted senders';

  @override
  String get deskInvHelpTrustShort =>
      'Only senders on the trusted list can put an invoice in the inbox. That keeps out spam and fake bills.';

  @override
  String get deskInvHelpTrustP1 =>
      'The wallet accepts an invoice only at its invoice address and only from a sender on the trusted list, matched on the sender\'s address. Anything else is dropped unread, before it is opened, and never shows under [[Invoices › Pay]].';

  @override
  String get deskInvHelpTrustP2 =>
      'Without the list, anyone who learned the invoice address could fill the inbox with spam or with bills that look real.';

  @override
  String get deskInvHelpTrustP3 =>
      'Trust only lets a sender ask. A trusted sender cannot take anything: each invoice still waits for **Approve and pay**.';

  @override
  String get deskInvHelpTrustWhere1 =>
      'Trust a sender under [[Settings › Invoices]].';

  @override
  String get deskInvHelpTrustWhere2 =>
      'Or switch on **Trusted for invoices** on a contact under [[Contacts]].';

  @override
  String get deskInvHelpTrustWhere3 =>
      'A sender can be removed from the list at any time. Its new invoices are then dropped.';

  @override
  String get deskInvHelpAddrTitle => 'Why a separate invoice address';

  @override
  String get deskInvHelpAddrShort =>
      'Invoices arrive at their own address, apart from the payments address that people pay to.';

  @override
  String get deskInvHelpAddrP1 =>
      'The wallet has two Epicbox addresses. The **payments address**, under [[Receive]], receives payments. The **invoice address** receives only invoices.';

  @override
  String get deskInvHelpAddrP2 =>
      'Keeping them apart means the invoice address can be given to services, or replaced, without exposing or changing the address people pay to.';

  @override
  String get deskInvHelpAddrP3 =>
      'The invoice address does not receive payments: a payment sent to it is dropped. To be paid, give the payments address.';

  @override
  String get deskInvHelpAddrWhere1 =>
      'Find, copy or show the invoice address as a QR code under [[Settings › Invoices]].';

  @override
  String get deskInvHelpAddrWhere2 =>
      '**New invoice address** replaces it. Services with the old one can no longer send invoices until they get the new one.';

  @override
  String get deskInvHelpDiagramTitle => 'How an invoice travels';

  @override
  String get deskInvHelpDiagramIssuer => 'Issuer';

  @override
  String get deskInvHelpDiagramPayer => 'Payer';

  @override
  String get deskInvHelpDiagramIssues => 'Issues the invoice';

  @override
  String get deskInvHelpDiagramInvoice => 'Invoice';

  @override
  String get deskInvHelpDiagramGate => 'Invoice address';

  @override
  String get deskInvHelpDiagramGateSub => 'Trusted senders only';

  @override
  String get deskInvHelpDiagramDropped => 'Other senders';

  @override
  String get deskInvHelpDiagramDroppedSub => 'Dropped unread';

  @override
  String get deskInvHelpDiagramReview => 'Reviews and approves';

  @override
  String get deskInvHelpDiagramReviewSub => 'Approve and pay';

  @override
  String get deskInvHelpDiagramPayment => 'Payment';

  @override
  String get deskInvHelpDiagramPayAddr => 'Payments address';

  @override
  String get deskInvHelpDiagramPayAddrSub => 'Not the invoice address';

  @override
  String get deskInvHelpDiagramFinal => 'Finalizes and posts';

  @override
  String deskInvHelpDiagramFinalSub(int confirmations) {
    return 'Final after $confirmations confirmations';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      'The issuer sends an invoice to the payer\'s invoice address, which accepts trusted senders only and drops the rest; the payer reviews and approves it; the payment goes to the issuer\'s payments address; the issuer\'s wallet finalizes it and posts it to the network.';

  @override
  String get deskInvIssuerFormTitle => 'Issue an invoice';

  @override
  String get deskInvIssuerFirstTitle => 'Before the first invoice';

  @override
  String get deskInvIssuerYourAddress => 'Your payments address';

  @override
  String get deskInvIssuerMethod => 'Method';

  @override
  String get deskInvIssuerEpicbox => 'Epicbox';

  @override
  String get deskInvIssuerFile => 'File';

  @override
  String get deskInvIssuerDirect => 'Direct';

  @override
  String get deskInvIssuerSoon => 'Coming soon';

  @override
  String get deskInvIssuerPayer => 'Their invoice address';

  @override
  String get deskInvIssuerPayerHelp =>
      'Their wallet shows it under Settings › Invoices.';

  @override
  String get deskInvIssuerPayerMissing => 'Paste their invoice address.';

  @override
  String get deskInvIssuerPayerInvalid =>
      'This is not a valid Epicbox address.';

  @override
  String get deskInvIssuerPayerOwn =>
      'This is one of your own addresses. Use the invoice address the payer gives you.';

  @override
  String get deskInvIssuerPayerHttp =>
      'Invoices over Epicbox need an Epicbox address, not an HTTP or Tor one.';

  @override
  String get deskInvIssuerContacts => 'Contacts';

  @override
  String get deskInvIssuerNoContacts =>
      'No contact has an invoice address yet. Add it under Contacts.';

  @override
  String get deskInvIssuerNoInvoices =>
      'This wallet sent an invoice back before: it cannot pay invoices over Epicbox. Send them an invoice file instead, or ask them to send you the payment.';

  @override
  String get deskInvIssuerUseFile => 'Use a file';

  @override
  String get deskInvIssuerUnknown =>
      'Only wallet-for-epic and other LEPIC wallets can pay an invoice over Epicbox. The Epic GUI wallet and Stack Wallet cannot pay invoices at all; the epic-wallet command line can pay an invoice file.';

  @override
  String get deskInvIssuerAmount => 'Amount';

  @override
  String get deskInvIssuerAmountMissing => 'Enter an amount.';

  @override
  String get deskInvIssuerAmountZero => 'The amount must be more than 0.';

  @override
  String get deskInvIssuerAmountDecimals => 'EPIC has at most 8 decimals.';

  @override
  String get deskInvIssuerAmountCap =>
      'More than all the EPIC there will ever be.';

  @override
  String get deskInvIssuerAmountHelp =>
      'Nothing leaves your wallet: the payer pays this amount plus their own fee.';

  @override
  String get deskInvIssuerMessage => 'Message to the payer';

  @override
  String deskInvIssuerMessageCount(int used, int max) {
    return '$used of $max bytes';
  }

  @override
  String get deskInvIssuerMessageLong => 'The message is too long.';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'The payer has $hours hours to pay.';
  }

  @override
  String get deskInvIssuerIssue => 'Issue';

  @override
  String get deskInvIssuerRelayDown =>
      'The Epicbox server is not answering, so an invoice cannot go out now.';

  @override
  String get deskInvIssuerFixFields => 'Fix the fields marked in red.';

  @override
  String get deskInvIssuerNotDelivered =>
      'The invoice did not reach the Epicbox server. Nothing was sent. Try again.';

  @override
  String deskInvIssuerSent(String payer) {
    return 'Invoice sent to $payer.';
  }

  @override
  String get deskInvIssuerEmpty =>
      'No invoices issued yet. An invoice asks a contact or a service to pay you; it spends nothing.';

  @override
  String deskInvIssuerTo(String payer) {
    return 'Invoice to $payer';
  }

  @override
  String deskInvIssuerIssued(String time) {
    return 'Issued $time';
  }

  @override
  String get deskInvIssuerPayerFact => 'Payer';

  @override
  String get deskInvIssuerAmountFact => 'Amount';

  @override
  String get deskInvIssuerMessageFact => 'Message';

  @override
  String get deskInvIssuerSentFact => 'Issued';

  @override
  String get deskInvIssuerExpiresFact => 'Expires';

  @override
  String get deskInvIssuerAnsweredFact => 'Ended';

  @override
  String get deskInvIssuerStepPaid => 'Paid';

  @override
  String get deskInvIssuerStepConfirming => 'Confirming';

  @override
  String get deskInvIssuerEnded =>
      'This invoice ended unpaid. Nothing arrived.';

  @override
  String get deskInvIssuerWithdraw => 'Withdraw';

  @override
  String get deskInvIssuerWithdrawTitle => 'Withdraw this invoice?';

  @override
  String deskInvIssuerWithdrawBody(String payer) {
    return '$payer can no longer pay it.';
  }

  @override
  String get deskInvIssuerKeep => 'Keep it';

  @override
  String get deskInvIssuerWithdrawn => 'Invoice withdrawn.';

  @override
  String get deskInvIssuerRepost => 'Repost';

  @override
  String get deskInvIssuerReposted => 'Payment posted again.';

  @override
  String get deskInvIssuerNodeDown =>
      'The node is not answering. Try again when it is reachable.';

  @override
  String get deskInvIssuerNotPostedText =>
      'The payment is finished but not on the network: the node refused it or could not be reached.';

  @override
  String get deskInvIssuerCancel => 'Cancel payment';

  @override
  String get deskInvIssuerCancelTitle => 'Cancel this payment?';

  @override
  String deskInvIssuerCancelBody(String payer) {
    return 'It will not arrive. $payer\'s funds stay locked in their wallet until they cancel on their side.';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return '$payer\'s wallet sent the invoice back: it cannot pay invoices. Ask them to send you a payment instead.';
  }

  @override
  String get deskInvIssuerSendFile => 'Use a file';

  @override
  String get deskInvIssuerLate =>
      'A payment arrived after this invoice ended. It was refused; nothing changed.';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer paid. Your wallet finished the payment and posted it.';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return 'Delivered to $payer\'s invoice address. Nothing is paid until they approve it.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Copy slate ID';

  @override
  String get deskInvIssuerStepsIntro =>
      'Their wallet must take invoices. Before the first invoice:';

  @override
  String get deskInvIssuerStepTrust =>
      '1. They add your payments address below to their trusted senders.';

  @override
  String get deskInvIssuerStepAddress =>
      '2. They give you their invoice address.';

  @override
  String get deskInvIssuerStepIssued => 'Issued';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return '$payer paid $amount EPIC.';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return '$payer declined your invoice.';
  }

  @override
  String get deskInvNoticeIssuedExpired =>
      'An invoice you issued expired unpaid.';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return '$service withdrew an invoice before you answered it.';
  }

  @override
  String get deskInvNoticeExpired =>
      'An invoice expired before you answered it.';

  @override
  String get deskInvNoticeUnknownPayment =>
      'A payment for an invoice this device did not issue arrived and was refused. If another device with this wallet issued it, ask the payer to cancel and pay again.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'An answer to a payment this device did not send arrived and was refused. If another device with this wallet sent it, cancel it there and send again.';

  @override
  String get deskInvPayerWaitingHead => 'Waiting for you';

  @override
  String get deskInvPayerNeedsHead => 'Payments to settle';

  @override
  String get deskInvPayerReview => 'Review';

  @override
  String get deskInvPayerPaidHead => 'Paid';

  @override
  String get deskInvPayerView => 'View';

  @override
  String get deskInvPayerNoMessage => 'No message';

  @override
  String deskInvPayerDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages from senders you do not trust were ignored.',
      one: '1 message from a sender you do not trust was ignored.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvPayerTrustService => 'Trust a service…';

  @override
  String get deskInvPayerYourInvoiceAddress => 'Your invoice address';

  @override
  String get deskInvPayerEmptyTitle => 'No invoices are waiting';

  @override
  String get deskInvPayerEmptyText =>
      'When a service you trust bills you, the invoice appears here. Nothing is paid until you approve it.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Your payment to $service was not delivered';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'It is signed and kept on this device; the funds stay locked. Retry sends it again without a second approval.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service withdrew an invoice you paid';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'The payment may never reach the chain. Cancel it to unlock your funds.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Your payment to $service is not on chain';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Its time passed and the network has not seen it. Cancel it to unlock your funds.';

  @override
  String get deskInvPayerCancelPayment => 'Cancel payment';

  @override
  String get deskInvPayerSafetyTitle => 'Pay only bills you expect';

  @override
  String get deskInvPayerSafetyText =>
      'An invoice never adds money to your wallet. Approving it sends money out.';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return 'You paid $service the same amount $ago ago';
  }

  @override
  String get deskInvPayerSameBillText =>
      'Check that this is a new bill before you pay it.';

  @override
  String deskInvPayerAgoHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String deskInvPayerAgoMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get deskInvPayerFee => 'Fee';

  @override
  String get deskInvPayerTotal => 'Total';

  @override
  String get deskInvPayerBalanceAfter => 'Balance after';

  @override
  String get deskInvPayerMessageCaption =>
      'Written by the service. Your wallet does not check it.';

  @override
  String get deskInvPayerPaysTo => 'Pays to';

  @override
  String deskInvPayerTrustedSince(String service, String date) {
    return '$service, trusted since $date';
  }

  @override
  String get deskInvPayerExpires => 'Expires';

  @override
  String get deskInvPayerLockHeight => 'Lock height';

  @override
  String get deskInvPayerLockNone => 'None';

  @override
  String get deskInvPayerReceived => 'Received';

  @override
  String get deskInvPayerShort => 'Not enough spendable funds';

  @override
  String deskInvPayerShortText(String total, String spendable) {
    return 'You need $total EPIC spendable; you have $spendable EPIC. Funds still confirming count once they have 3 confirmations.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'The node is not answering';

  @override
  String get deskInvPayerNodeDownText =>
      'The wallet cannot check your funds, so it cannot pay. Approve works again once the node answers; you can pick another node in Settings › Node.';

  @override
  String get deskInvPayerPaid =>
      'This invoice is paid. Nothing more can be paid on it.';

  @override
  String get deskInvPayerDeclinedText =>
      'You declined this invoice. Nothing was paid.';

  @override
  String get deskInvPayerBack => 'Back to Invoices';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return 'Pay $amount EPIC + $fee fee to $service?';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC leaves your wallet. Enter the wallet password to approve.';
  }

  @override
  String get deskInvPayerPassword => 'Wallet password';

  @override
  String get deskInvPayerWrongPassword => 'Wrong password. Nothing was paid.';

  @override
  String get deskInvPayerEnterPassword => 'Enter the wallet password.';

  @override
  String get deskInvPayerPay => 'Pay';

  @override
  String get deskInvPayerCancel => 'Cancel';

  @override
  String get deskInvPayerClose => 'Close';

  @override
  String get deskInvPayerNodeDownPay =>
      'The node is not answering. Nothing was paid.';

  @override
  String get deskInvPayerAlreadyAnswered =>
      'This invoice was already answered. Nothing more was paid.';

  @override
  String get deskInvPayerCannotPay =>
      'This invoice cannot be paid. Nothing was paid.';

  @override
  String get deskInvPayerNotDeliveredToast => 'Signed, not delivered';

  @override
  String get deskInvPayerNotDeliveredToastText =>
      'The Epicbox server is not answering. Retry it under Invoices › Pay; no second approval.';

  @override
  String get deskInvPayerRetryFailed => 'Still not delivered';

  @override
  String get deskInvPayerRetryFailedText =>
      'The Epicbox server is not answering. The payment stays signed on this device.';

  @override
  String get deskInvPayerCancelTitle => 'Cancel this payment?';

  @override
  String get deskInvPayerCancelText =>
      'Cancelling unlocks your funds here. The service still holds your signed payment, so it could still complete until these funds are spent again.';

  @override
  String deskInvPayerCancelWho(String amount, String service) {
    return '$amount EPIC to $service';
  }

  @override
  String get deskInvPayerKeepPayment => 'Keep it';

  @override
  String get deskInvPayerOnItsWay =>
      'Already on its way: it cannot be cancelled.';

  @override
  String get deskInvPayerCannotCheck =>
      'Cannot check the network now; try again when the node is reachable.';

  @override
  String get deskInvPayerCancelled => 'Payment cancelled';

  @override
  String get deskInvPayerCancelledText => 'Your funds are unlocked.';

  @override
  String get deskInvPayerDeclined => 'Invoice declined. Nothing was paid.';

  @override
  String get deskInvPayerSpendToSelf => 'Spend them to myself now';

  @override
  String get deskInvPayerSpendToSelfHelp =>
      'Makes the cancel final: the service\'s signed copy can no longer complete. Costs a network fee.';

  @override
  String get deskInvPayerSpentText =>
      'Your funds are unlocked and moved within this wallet. The cancel is final.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Your funds are unlocked, but moving them did not work. The cancel is not final yet.';

  @override
  String get deskInvPayerLocked =>
      'This invoice cannot be paid: it is locked until a later block. Nothing was paid.';

  @override
  String get deskInvPayerRelayDownPay =>
      'The Epicbox server is not answering. Nothing was paid.';

  @override
  String get deskInvSetTitle => 'Invoices';

  @override
  String get deskInvSetIntro =>
      'Services you trust bill this wallet at its invoice address. Nothing is paid until you approve each invoice.';

  @override
  String get deskInvSetAddressLabel => 'Invoice address';

  @override
  String get deskInvSetAddressWarning =>
      'Give it only to services you trust. It does not receive payments.';

  @override
  String get deskInvSetCopy => 'Copy';

  @override
  String get deskInvSetCopied =>
      'Invoice address copied. Give it only to services you trust; it does not receive payments.';

  @override
  String get deskInvSetQrShow => 'Show QR';

  @override
  String get deskInvSetQrHide => 'Hide QR';

  @override
  String get deskInvSetQrLabel => 'QR code of your invoice address';

  @override
  String deskInvSetIndex(int index) {
    return 'Invoice address $index';
  }

  @override
  String get deskInvSetTrusted => 'Trusted senders';

  @override
  String get deskInvSetTrustedNone =>
      'No trusted senders. Invoices from anyone else are ignored unread.';

  @override
  String deskInvSetSince(String date) {
    return 'Trusted since $date';
  }

  @override
  String get deskInvSetContactTag => 'Contact';

  @override
  String get deskInvSetRemove => 'Remove';

  @override
  String deskInvSetRemoveTitle(String name) {
    return 'Stop trusting $name?';
  }

  @override
  String deskInvSetRemoveBody(String name) {
    return '$name can no longer send you invoices. Invoices already waiting stay until you answer them or they expire.';
  }

  @override
  String deskInvSetRemoved(String name) {
    return '$name can no longer send you invoices.';
  }

  @override
  String get deskInvSetKeep => 'Keep';

  @override
  String get deskInvSetAdd => 'Trust a sender';

  @override
  String get deskInvSetAddBody =>
      'A trusted sender can bill this wallet at its invoice address. Nothing is paid until you approve each invoice with your wallet password.';

  @override
  String get deskInvSetName => 'Name';

  @override
  String get deskInvSetNameMissing => 'Give the sender a name.';

  @override
  String get deskInvSetSenderAddress => 'Their payments address';

  @override
  String get deskInvSetSenderMissing => 'Paste the address the service shows.';

  @override
  String get deskInvSetSenderInvalid => 'This is not a valid Epicbox address.';

  @override
  String get deskInvSetTrust => 'Trust';

  @override
  String deskInvSetAdded(String name) {
    return '$name can now send you invoices.';
  }

  @override
  String deskInvSetDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count messages from senders you do not trust were ignored unread.',
      one: '1 message from a sender you do not trust was ignored unread.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvSetRotate => 'New invoice address';

  @override
  String get deskInvSetRotateHint =>
      'Services that have the old one can no longer send you invoices.';

  @override
  String get deskInvSetRotateTitle => 'Make a new invoice address?';

  @override
  String get deskInvSetRotateBody =>
      'Services that have the old one can no longer send you invoices. Give the new one to every service that bills you.';

  @override
  String get deskInvSetRotateConfirm => 'Make new address';

  @override
  String get deskInvSetRotated =>
      'New invoice address ready. Give it to your services.';

  @override
  String get deskInvSetExpiry => 'Time to pay';

  @override
  String get deskInvSetExpiryHint =>
      'How long an invoice you issue stays payable, and how long one you receive waits for you. At most 48 hours.';

  @override
  String deskInvSetHours(int hours) {
    return '$hours hours';
  }

  @override
  String get deskInvSetCancel => 'Cancel';

  @override
  String get deskInvSetContactSection => 'Invoices';

  @override
  String get deskInvSetTheirInvoice => 'Their invoice address';

  @override
  String get deskInvSetTheirInvoiceNone =>
      'No invoice address saved. Ask them for it to issue invoices to them.';

  @override
  String get deskInvSetTrustedSwitch => 'Trusted for invoices';

  @override
  String get deskInvSetTrustedSwitchHelp =>
      'Lets this contact bill you. Nothing is paid until you approve an invoice.';

  @override
  String get deskInvSetIssueNeeds => 'Needs their invoice address.';

  @override
  String get deskInvSetShare => 'Share invoice address';

  @override
  String get deskInvSetReceiveHint =>
      'Ask a contact or a service to pay you. Their wallet must take invoices.';

  @override
  String get deskInvSetRestoredHint =>
      'Restored this wallet from its recovery phrase? Give services this invoice address again.';

  @override
  String get serverSwitchRelayTitle => 'Switch epicbox server?';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'The epicbox address changes to …@$relay. Senders need the new address. Payments sent to the old address stay on the old server.';
  }

  @override
  String get serverSwitchRelayConfirm => 'Switch';

  @override
  String get helpButton => 'Help';

  @override
  String get helpSearchHint => 'Search help';

  @override
  String get helpEnglishOnly => 'Help is in English for now.';

  @override
  String helpNoMatch(String query) {
    return 'No help matches \"$query\"';
  }

  @override
  String helpMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '1 topic',
    );
    return '$_temp0';
  }

  @override
  String get helpShowHandshake => 'Show how it works';

  @override
  String get helpMoreInSection => 'More in this section';

  @override
  String get sendBalanceAfter => 'Balance after';

  @override
  String get sendSpendableUntilChange => 'Spendable until change confirms';

  @override
  String get sendSpendableUntilChangeHint =>
      'The change comes back once the send confirms.';

  @override
  String serverSwitched(String host) {
    return 'Switched to $host';
  }

  @override
  String get methodDirect => 'Direct';

  @override
  String get methodDirectShape => 'http://host:3415 or xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Their wallet must be open. An onion address goes over Tor.';

  @override
  String get methodArtLabelDirect =>
      'Direct: the payment goes straight to the recipient\'s wallet, which must be open';

  @override
  String get methodReceiveEpicboxShort => 'Works with the wallet closed.';

  @override
  String get methodReceiveDirectTitle => 'Straight to this wallet.';

  @override
  String get methodReceiveDirectLine => 'Works while the app is open.';

  @override
  String methodLineOverTor(String line) {
    return '$line Over Tor.';
  }

  @override
  String get sendSwitchedDirect => 'Direct address';

  @override
  String get sendSwitchedDirectAnnounce =>
      'Direct address. Method set to Direct.';

  @override
  String get sendDirectAddressShape =>
      'A Direct address starts with http:// or https://, or ends in .onion.';

  @override
  String get torNotOverTor => 'Not over Tor';

  @override
  String get torNeeds => 'Needs Tor.';

  @override
  String get torTurnOn => 'Turn on Tor';

  @override
  String get torTurnOff => 'Turn Tor off';

  @override
  String get torNotConnectedNotice => 'Tor is not connected.';

  @override
  String get torWaiting => 'Waiting for Tor';

  @override
  String get torWordStarting => 'Starting…';

  @override
  String get torWordNotConnected => 'Not connected';

  @override
  String get torSettingsLink => 'Tor settings';

  @override
  String get torNetworkLabel => 'Tor Network';

  @override
  String get torNetworkHint =>
      'Network activity goes through the Tor network. Tor hides the wallet’s internet address: each connection passes through several volunteer-run relays, so no server learns where the wallet is. Notifications are off while Tor is on.';

  @override
  String get receiveTabDirect => 'Direct';

  @override
  String get receiveDirectNeedsTor => 'Direct receiving needs Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Senders use the Epicbox address meanwhile.';

  @override
  String get netStatusOverTor => 'over Tor';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsHint =>
      'Uses Google’s notification service. No sensitive data is shared.';

  @override
  String get settingsPushPaused => 'Paused while Tor is on';

  @override
  String get pushConfirmRelayBody =>
      'Notifications use the BT Labs Epicbox and Google’s notification service. No sensitive data is shared.';

  @override
  String get pushConfirmRelayAddress =>
      'Your Epicbox address will change. Share the new one.';

  @override
  String get pushRelaySwitchFailed =>
      'The relay could not be switched. Notifications stay off.';

  @override
  String get pushConfirmTitle => 'Turn on notifications?';

  @override
  String get pushConfirmBody =>
      'Notifications use Google’s notification service. No sensitive data is shared.';

  @override
  String get pushConfirmAction => 'Turn on';

  @override
  String get pushNoticeOn => 'Notifications on';

  @override
  String get pushNoticeOff => 'Notifications off';

  @override
  String get pushNoticeAvailable => 'Notifications are available in Settings.';

  @override
  String get torWayOver => 'Over Tor';

  @override
  String get torWayWaiting => 'Waiting for Tor';

  @override
  String get torWayNotConnected => 'Tor is not connected.';
}
