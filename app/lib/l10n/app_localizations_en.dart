// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Epic Wallet';

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
  String get shellTitle => 'Epic Wallet';

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
  String get updateNeedsPermission =>
      'Allow this app to install updates in the screen that opened, then tap Update again.';

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
  String get setupTitle => 'Network settings';

  @override
  String get setupNetworkSettingsTooltip => 'Network settings';

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
  String get contactsAddressLabel => 'Epicbox address';

  @override
  String contactsDuplicate(String name) {
    return 'This address is already saved as $name.';
  }

  @override
  String get contactsNoteLabel => 'Note (optional)';

  @override
  String get contactsSave => 'Save contact';

  @override
  String get contactsAddressMissing => 'Enter their epicbox address.';

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
  String get settingsSectionNetwork => 'Network';

  @override
  String get settingsNetworkAndNode => 'Network and node';

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
  String get settingsPaymentNotifications => 'Payment notifications';

  @override
  String get settingsPushHint => 'Delivered by Google Firebase.';

  @override
  String get settingsPushOnNotice =>
      'No epicbox server sends them yet. Open the app to receive a payment.';

  @override
  String get settingsPushOffNotice =>
      'Notifications stop the next time the app starts.';

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
  String get settingsLicencesHint => 'Open-source software in this wallet';

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
  String get helpWaitingQuestion =>
      'Why does my payment say \"Waiting for recipient\"?';

  @override
  String helpWaitingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'An Epic Cash payment is built by both wallets together: yours starts it, the recipient\'s wallet accepts it, then yours finishes it. Epic\'s epicbox service holds your payment for about a week, until the recipient\'s wallet comes online and answers. Until then the amount stays locked in your wallet, so you cannot spend it twice. If the payment is not completed, your wallet cancels it by itself after $_temp0 and unlocks the amount.';
  }

  @override
  String get helpCancellingQuestion => 'Should I cancel a payment?';

  @override
  String helpCancellingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Usually you do not need to: a payment that is not completed cancels itself after $_temp0 and unlocks the amount. To stop one sooner, for example when the recipient says they will never answer, open it while it still says \"Waiting for recipient\" and tap Cancel payment; you would then have to send it again. A payment that is already confirming cannot be cancelled. Payments made with older versions of this app do not cancel themselves: if one has waited more than two weeks, cancel it and send again.';
  }

  @override
  String get helpReceivingQuestion =>
      'Why must I keep the app open to receive?';

  @override
  String helpReceivingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Your wallet has to accept every incoming payment, and it can only do that while the app is open and connected to epicbox. A payment sent while the app is closed waits in epicbox for about a week and arrives the next time you unlock. After that epicbox deletes it; if the sender uses this app, their wallet cancels it by itself after $_temp0, and they can send it again. Once your wallet accepts a payment, the sender\'s wallet must finish it; until then it shows as Waiting for sender.';
  }

  @override
  String helpConfirmationsQuestion(int count) {
    return 'What are confirmations and why $count?';
  }

  @override
  String helpConfirmationsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmations, about $count minutes',
      one: '1 confirmation, about 1 minute',
    );
    return 'A confirmation is a new block added to the Epic Cash blockchain after the one that holds your payment; a block arrives about once a minute. Each block makes it harder to undo the payment. After $_temp0, a payment shows as Completed and received coins can be spent; that is the Epic wallet\'s standard.';
  }

  @override
  String get helpHistoryQuestion =>
      'Why is my history missing after a restore?';

  @override
  String get helpHistoryAnswer =>
      'The recovery phrase brings back your balance: the wallet scans the blockchain for coins that belong to it. Who you paid, your notes and most dates are never stored on the blockchain, so a restore cannot find them. If you saved a history backup, import it in Settings, under Payment history, Import history backup, to get them back. The backup must be a copy you kept outside the lost phone, for example in email or cloud storage.';

  @override
  String get helpAddressQuestion => 'Does my address ever change?';

  @override
  String get helpAddressAnswer =>
      'Your address is made from your recovery phrase and the epicbox server you use, and it ends in @ and that server\'s name. It stays the same as long as you keep the same epicbox server. If you pick another one in network settings, your address changes, so give the new one to people who pay you.';

  @override
  String get helpPhraseQuestion =>
      'What is the recovery phrase and who can see it?';

  @override
  String get helpPhraseAnswer =>
      'The recovery phrase is a list of words that is the key to your money: anyone who has it can take your coins, and with it you can restore your wallet on a new phone. The app shows it only after you enter your PIN, and it never sends it anywhere. Write it on paper, keep it somewhere safe, and never share it or type it into a website.';

  @override
  String get helpFeesQuestion => 'What does the fee pay for?';

  @override
  String get helpFeesAnswer =>
      'The fee goes to the miners who add your payment to the blockchain. It is usually a small fraction of an EPIC and depends on how many coins your wallet combines to make the payment. You see the exact fee before you send.';

  @override
  String get helpNodeQuestion => 'What is a node?';

  @override
  String get helpNodeAnswer =>
      'A node is a computer that keeps a copy of the Epic Cash blockchain. The wallet asks a node for your balance and sends your payments to the network through it. The node sees your IP address and which coins the wallet asks about, so pick one you trust in network settings. Network settings are in Settings once Advanced options is on, and on the unlock screen.';

  @override
  String get helpOtherWaysQuestion => 'Are there other ways to send?';

  @override
  String get helpOtherWaysAnswer =>
      'For advanced users. Without epicbox, use \"Send by transaction file\" under \"Other ways to send\": you share a file, the recipient accepts it and returns a .response file, and you open that file to finish. \"Other ways to send\" appears once Advanced options is on in Settings.';

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
      'Network, node, epicbox server, files and logs';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsUseStatusSite => 'Use status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Server health and node lists. Off: only the servers themselves are asked.';

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
  String get sendAddressNotEpic => 'This is not an Epic address.';

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
      'Slower and more private. Blocked or not allowed in some countries. Receives only while the app is open.';

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
    return 'Enter the PIN to send $amount EPIC.';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'Enter the PIN to make a payment file for $amount EPIC.';
  }
}
