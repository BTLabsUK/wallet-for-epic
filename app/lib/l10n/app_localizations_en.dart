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
  String txSpokenLabelled(String label, String row) {
    return '$label, $row';
  }

  @override
  String get txLabel => 'Label';

  @override
  String get txLabelAdd => 'Add label';

  @override
  String get txLabelEdit => 'Edit label';

  @override
  String get txLabelHint => 'Add label';

  @override
  String get txLabelAddedNotice => 'Label added';

  @override
  String get txLabelSavedNotice => 'Label saved';

  @override
  String get txLabelRemovedNotice => 'Label removed';

  @override
  String get txEditAdd => 'Add details';

  @override
  String get txEditEdit => 'Edit details';

  @override
  String get txEditFrom => 'From';

  @override
  String get txEditFromHint => 'Address';

  @override
  String get txEditFromHelper => 'Not verified. Never used for payment proofs.';

  @override
  String get txMethodUnknown => 'Unknown';

  @override
  String get txManualTag => 'Added by you';

  @override
  String txManualTip(String date) {
    return 'Added by you on $date. Not from the chain.';
  }

  @override
  String get txManualTipNoDate => 'Added by you. Not from the chain.';

  @override
  String txManualTipFrom(String date) {
    return 'Added by you on $date. Not from the chain, not verified.';
  }

  @override
  String get txManualTipFromNoDate =>
      'Added by you. Not from the chain, not verified.';

  @override
  String get txEditAddedNotice => 'Details added';

  @override
  String get txEditSavedNotice => 'Details saved';

  @override
  String get txEditRemovedNotice => 'Details removed';

  @override
  String get histConflictTitle => 'Details differ';

  @override
  String histConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'The backup has other details for $n payments you described. Yours are kept unless you choose otherwise.',
      one: 'The backup has other details for 1 payment you described. Yours are kept unless you choose otherwise.',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'Mine';

  @override
  String get histConflictBackup => 'Backup';

  @override
  String get histConflictKeepAll => 'Keep all mine';

  @override
  String get histConflictImport => 'Import';

  @override
  String get histConflictEmpty => 'empty';

  @override
  String histImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n details replaced, the rest kept as yours.',
      one: '1 detail replaced, the rest kept as yours.',
    );
    return '$_temp0';
  }

  @override
  String get txOutgoingPayment => 'Outgoing payment';

  @override
  String get txIncomingPayment => 'Incoming payment';

  @override
  String get txStatusWaitingRecipient => 'Waiting for recipient';

  @override
  String get txStatusWaitingSender => 'Waiting for sender';

  @override
  String get txStatusSenderPosted => 'Sender reports posted';

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
  String get txDetailsSenderPosted =>
      'The sender reports it posted this payment. It completes when the blockchain confirms it.';

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
      'Cancelled. Nothing was paid, and the funds are spendable again. If the recipient already got it, their wallet may still show it as waiting; it can no longer complete.';

  @override
  String get txDetailsCancelledReleased =>
      'The network never took it, so its funds were released. Check the recipient did not receive it before sending again.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'It did not reach the network within 14 days, so the wallet cancelled it. Check the recipient did not receive it before sending again.';

  @override
  String get txDetailsCancelledUnanswered =>
      'The recipient did not answer within 14 days, so the wallet cancelled it. Nothing was paid, and the funds are spendable again.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'The recipient answered after the 14-day limit, so the wallet cancelled it instead of finishing it. Nothing was paid, and the funds are spendable again.';

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
  String get homeNoticeSenderPosted => 'Sender reports a payment posted.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Sender reports $amount posted.';
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
  String get statusEpicboxOnline => 'Epicbox connected';

  @override
  String get statusEpicboxConnecting => 'Epicbox connecting';

  @override
  String get statusEpicboxOffline => 'Epicbox not connected';

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
  String get homeEpicboxOffline =>
      'Your wallet is not connected to its Epicbox server and keeps trying.';

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
  String invoiceDetailsRepliedHelp(String service) {
    return 'If $service has not posted it, send the payment again: nothing is signed twice. If it is never posted, Cancel becomes available once the payment\'s time runs out, about a day after you paid.';
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
  String get updateInstallCancelled =>
      'The update was not installed. You can try again.';

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
  String get updateNoTorDownload =>
      'The update can\'t be downloaded over Tor yet. Turn Tor off to download it, or get it from the download page.';

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
  String get setupNetworkSettingsTooltip => 'Node and Epicbox';

  @override
  String get setupNetworkHeading => 'Network';

  @override
  String get setupNodeUrlLabel => 'Node URL';

  @override
  String get setupCustomRelayLabel =>
      'Other epicbox server (host or host:port)';

  @override
  String get setupCustomRelayInvalid =>
      'Enter a host such as epicbox.example.com';

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
  String get backupCopyTitle => 'Copy the recovery phrase?';

  @override
  String get backupCopyBody =>
      'Anyone with these words can take your funds. Store the copy somewhere safe.';

  @override
  String get backupCopied => 'Copied. The clipboard is cleared in 60 seconds.';

  @override
  String get backupNotCopied => 'Not copied. The clipboard refused the text.';

  @override
  String get unlockTitle => 'Unlock wallet';

  @override
  String get pinlessUnlock => 'Unlock';

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
  String get slateReadingQr => 'Reading the payment';

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
  String get qrShowReplyAsQr => 'Show reply as QR';

  @override
  String get qrShowTitlePayment => 'Payment QR';

  @override
  String get qrShowTitleReply => 'Reply QR';

  @override
  String qrShowSubPayment(String amount) {
    return '$amount to a phone next to you';
  }

  @override
  String qrShowSubReply(String amount) {
    return 'To the sender of $amount';
  }

  @override
  String get qrHiddenTitle => 'Hidden until you show it';

  @override
  String get qrHiddenBodyPayment =>
      'Whoever scans it first can accept this payment. Show it only to the person you are paying.';

  @override
  String get qrHiddenBodyReply =>
      'Show it to the sender\'s phone. Only their wallet can use it.';

  @override
  String get qrShow => 'Show QR';

  @override
  String get qrShowAgain => 'Show again';

  @override
  String get qrHide => 'Hide';

  @override
  String qrCountdownLabel(int seconds) {
    return 'Showing in $seconds';
  }

  @override
  String qrPartOf(int part, int count) {
    return 'Part $part of $count';
  }

  @override
  String qrSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String qrSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds left',
      one: '1 second left',
    );
    return '$_temp0';
  }

  @override
  String get qrHoldHint => 'Hold the other phone\'s camera to this code.';

  @override
  String get qrSecureLine => 'Screenshots are off on this screen';

  @override
  String qrTimedOutTitle(int seconds) {
    return 'Hidden after $seconds s';
  }

  @override
  String get qrTimedOutBody => 'Show it again when the other phone is ready.';

  @override
  String qrTimedOutAnnounce(int seconds) {
    return 'Hidden after $seconds seconds';
  }

  @override
  String get qrAwayTitle => 'Hidden while the app was away';

  @override
  String get qrAwayBody => 'The code hides whenever the app leaves the screen.';

  @override
  String qrSemanticsPayment(String state) {
    return 'Payment QR code, $state';
  }

  @override
  String qrSemanticsReply(String state) {
    return 'Reply QR code, $state';
  }

  @override
  String get qrStateHidden => 'hidden';

  @override
  String get qrStateShowing => 'showing';

  @override
  String get qrScanPayment => 'Scan payment QR';

  @override
  String get qrScanReply => 'Scan their reply';

  @override
  String get qrScanAimPayment =>
      'Point the camera at the QR code on their phone.';

  @override
  String get qrScanAimReply => 'Point the camera at the reply on their phone.';

  @override
  String get qrScanSteady => 'Hold steady, or move a little closer.';

  @override
  String get qrScanGot => 'Got it';

  @override
  String qrScanCount(int got, int count) {
    return '$got of $count';
  }

  @override
  String get qrScanCountLabel => 'Parts read';

  @override
  String get qrScanNotPayment =>
      'That is not a payment QR. Ask them to show the payment code on their phone.';

  @override
  String get qrScanNotReply =>
      'That is not a reply QR. Ask them to show the reply on their phone.';

  @override
  String get qrScanOtherPayment =>
      'This code belongs to a different payment. Starting over.';

  @override
  String get qrScanTorch => 'Torch';

  @override
  String qrScanZoom(String factor) {
    return 'Zoom $factor×';
  }

  @override
  String get qrScanCameraDenied =>
      'The wallet may not use the camera. To scan, allow camera access for this app in your phone\'s settings. You can also open the file instead.';

  @override
  String get qrScanCameraFailed =>
      'The camera could not start. Try again, or open the file instead.';

  @override
  String get qrScanOpenSettings => 'Open settings';

  @override
  String get qrScanOpenFileInstead => 'Open a file instead';

  @override
  String get qrScanAgain => 'Scan again';

  @override
  String get slateWrongPaymentQr =>
      'This reply is for a different payment. Scan the reply for this send.';

  @override
  String get slateScannedPaymentTitle => 'Scanned payment';

  @override
  String get slateScannedReplyTitle => 'Scanned reply';

  @override
  String get slateIncomingSendHintQr =>
      'Accept it, then show the reply to the sender.';

  @override
  String get slateAcceptedHeadlineQr =>
      'Accepted. Show the reply to the sender.';

  @override
  String get methodQr => 'QR Payment';

  @override
  String get methodQrChip => 'QR Code';

  @override
  String get receiveTabQr => 'QR Code';

  @override
  String get methodArtCaptionQr => 'In person';

  @override
  String get methodArtLabelQr =>
      'Direct · QR Payment: a code passes from one phone to the phone next to it';

  @override
  String get methodSendQrTitle => 'For a phone next to you.';

  @override
  String get methodSendQrLine =>
      'Show a code on this screen, then scan their reply with the camera.';

  @override
  String get methodReceiveQrTitle => 'Scan their screen.';

  @override
  String get methodReceiveQrLine =>
      'Accept the payment, then show your reply the same way.';

  @override
  String get receiveQrTitle => 'Standing next to the sender?';

  @override
  String get receiveQrBody =>
      'Scan the code on their phone, accept the payment, then show your reply.';

  @override
  String get txQrLine =>
      'Pay or get paid next to each other, with a code on the screen.';

  @override
  String get txQrHint =>
      'QR Payment shows the payment as an animated code that the other phone scans with its camera, and takes their reply the same way. It works only between phones next to each other, needs no connection between the two wallets, and the code hides itself after 40 seconds. Adds QR Payment to Send and Receive.';

  @override
  String get advTransactionFiles => 'File Transfer';

  @override
  String get advTransactionFilesHint =>
      'Adds File Transfer under Settings › Transactions: pay or get paid with a file you pass on yourself.';

  @override
  String get sendQrTitle => 'QR Payment';

  @override
  String get sendMakeQr => 'Make payment QR';

  @override
  String sendQrPinReason(String amount) {
    return 'Enter the PIN to make a payment QR for $amount.';
  }

  @override
  String get sendQrMade => 'Payment made';

  @override
  String get sendQrHint =>
      'Show the code to the recipient\'s phone, then scan their reply.';

  @override
  String get sendCancelRuleQr => 'Can be cancelled until you scan their reply.';

  @override
  String get qrStatusSendHidden => 'Show this to the recipient.';

  @override
  String get qrStatusSendShowing =>
      'Waiting for the recipient to scan. Then scan their reply.';

  @override
  String get qrStatusHiddenAgain =>
      'Hidden. Show again if they did not finish scanning.';

  @override
  String get qrStatusReplyHidden => 'Show this to the sender.';

  @override
  String get qrStatusReplyShowing => 'Waiting for the sender to scan.';

  @override
  String get qrStatusReceivedWaiting =>
      'Payment received. Waiting for the sender to scan and post it.';

  @override
  String qrStatusPosted(int got, int target) {
    return 'Posted. Confirming $got/$target';
  }

  @override
  String get qrStatusReceived => 'Received.';

  @override
  String qrScanProgress(int got, int count) {
    return 'Scanned $got of $count. Keep the code in the frame.';
  }

  @override
  String get qrScanReplyScanned => 'Reply scanned.';

  @override
  String get qrScanPosting => 'Reply scanned. Posting…';

  @override
  String get qrScanPosted => 'Posted.';

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
  String get contactsAddressInvalidAny =>
      'Not a valid address. Use an Epicbox address (es5x…@epicbox.epiccash.com), a Link address (https://…) or an onion address (….onion).';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNetwork => 'Servers';

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
      'A second address, only for invoices, that services you trust can bill. Messages from anyone else are dropped, and nothing is paid until you approve each invoice with your PIN. It is separate from your payment address.';

  @override
  String get invoiceSettingsTitle => 'Invoices';

  @override
  String get invoiceSettingsAddressTitle => 'Your invoice address';

  @override
  String get invoiceSettingsAddressBody =>
      'Give this address to a service you trust, so it can send you invoices. It is separate from your payment address.';

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
  String get settingsRescan => 'Recheck balance';

  @override
  String get settingsRescanFinished => 'Rescan finished';

  @override
  String get settingsRescanTitle => 'Recheck balance';

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
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsSendFeedback => 'Send feedback';

  @override
  String get settingsSendFeedbackHint =>
      'Report a problem or suggest an idea to the developers. Logs go along only if you attach them, with the recovery phrase, PIN and other secrets removed first.';

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get settingsLicences => 'Licences';

  @override
  String get licencesLead =>
      'Open-source software in this wallet. Each component keeps its own licence; the full texts are one tap away.';

  @override
  String get licencesApp => 'Epic Cash Mobile by BT Labs: Apache-2.0.';

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
      'Fonts Montserrat, JetBrains Mono and Noto Sans Thai: SIL Open Font License 1.1.';

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
      'Shows the technical side: node and Epicbox server details, block heights, transaction files and logs. Off, the app keeps to what everyday use needs.';

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
  String get settingsHubBackup => 'Backup';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'Use status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Reads which nodes and Epicbox servers are online, their block height and their response time from status.btlabs.uk, the BT Labs monitor, and shows them in the server lists and the status card. Off, status.btlabs.uk is never asked and the server lists show no state.';

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
  String get sendStepMethod => 'Payment method';

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
  String sendRelayDown(String relay) {
    return 'Their relay ($relay) isn\'t answering.';
  }

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
  String get handshakeFile => 'File Transfer';

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
  String get handshakeLink1 =>
      'Your wallet sends the payment straight to their wallet, over the internet or Tor. Your coins go on hold.';

  @override
  String get handshakeLink2 =>
      'Their wallet adds its part, signs and answers on the same connection.';

  @override
  String get handshakeQr1 => 'You show your code.';

  @override
  String get handshakeQr2 => 'They scan it with their wallet.';

  @override
  String get handshakeQr3 => 'Their wallet shows a reply code.';

  @override
  String get handshakeQr4 => 'You scan it.';

  @override
  String get handshakeQr5 => 'Your wallet sends it to the network.';

  @override
  String get handshakeQrR1 => 'They show their code.';

  @override
  String get handshakeQrR2 => 'You scan it with your wallet.';

  @override
  String get handshakeQrR3 => 'Your wallet shows a reply code.';

  @override
  String get handshakeQrR4 => 'They scan it.';

  @override
  String get handshakeQrR5 => 'Their wallet sends it to the network.';

  @override
  String get handshakeNext => 'Next step';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their relay ($relay) didn\'t take it. The amount is on hold until you cancel it, or for at most $days days.',
      one:
          'Their relay ($relay) didn\'t take it. The amount is on hold until you cancel it, or for at most 1 day.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Their relay ($relay) didn\'t take it. Check Wallet before you send again.';
  }

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
  String get receiveTorAddressLabel => 'Your link';

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
  String get tourPhoneSemantics => 'Wallet tour';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get tourPhoneSkip => 'Skip';

  @override
  String get tourPhoneBack => 'Back';

  @override
  String get tourPhoneNext => 'Next';

  @override
  String get tourPhoneWalletTitle => 'Wallet';

  @override
  String get tourPhoneWalletText =>
      'Your balance, and under it the icons for the node, Epicbox and Tor. What is still confirming is in the tiles below.';

  @override
  String get tourPhoneSendTitle => 'Send';

  @override
  String get tourPhoneSendText =>
      'Paste or scan an address, or pick a contact. Epicbox pays an address; QR shows a code to a phone next to you. More ways: Settings › Transactions. A review comes first.';

  @override
  String get tourPhoneReceiveTitle => 'Receive';

  @override
  String get tourPhoneReceiveText =>
      'Your Epicbox address. Share it to get paid. The File tab is for transaction files to sign or finish.';

  @override
  String get tourPhoneActivityTitle => 'Activity';

  @override
  String get tourPhoneActivityText =>
      'Every payment with its progress and details. Tap one to open it.';

  @override
  String get tourPhoneContactsTitle => 'Contacts';

  @override
  String get tourPhoneContactsText =>
      'Saved addresses by name. Send picks from here.';

  @override
  String get tourPhoneInvoicesTitle => 'Invoices';

  @override
  String get tourPhoneInvoicesText =>
      'Pay an invoice someone sent, or ask someone for a payment. The tabs switch between the two.';

  @override
  String get tourPhonePrivacyTitle => 'Privacy & network';

  @override
  String get tourPhonePrivacyText =>
      'Which node and Epicbox server the wallet uses, and the Tor switch. Tap a server to change it.';

  @override
  String get tourPhoneAdvancedTitle => 'Advanced';

  @override
  String get tourPhoneAdvancedText =>
      'Tor-only mode, outputs and technical details live here. Switch on what you need.';

  @override
  String get tourPhoneHelpTitle => 'Help';

  @override
  String get tourPhoneHelpText =>
      'Search the topics or send feedback. “Show the tour again” is at the bottom of the list.';

  @override
  String get tourPhoneShowAgain => 'Show the tour again';

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
  String get outputsStrategyHint =>
      'Which outputs a send spends. Smallest spends the fewest small outputs, so the rest stays spendable while the change confirms. All spends every spendable output and returns one change output: everything is locked until it confirms, and fewer, larger outputs remain.';

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
  String get outputsSplitChangeText =>
      'When a send would leave fewer than 3 spendable outputs and its change is at least 1 EPIC, the change comes back as up to 4 outputs, so the next sends do not wait for confirmations. Each extra output costs 0.004 EPIC.';

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
    return 'Spends $spent ($amount) and makes $made of about $each each. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then. More outputs let the next sends go out without waiting for each other’s change.';
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
  String get outputsAdvanced => 'Manage outputs';

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
  String get netStatusConnected => 'Connected';

  @override
  String get netStatusNotConnected => 'Not connected';

  @override
  String get serverUpNotConnected => 'Server up · not connected';

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
  String get serverMenuDelete => 'Delete';

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
  String get netStatusDirectOpenHint => 'Opens the Link receive address';

  @override
  String get netStatusOpenHint => 'Shows the servers';

  @override
  String get serverNodeTitle => 'Node';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'Find a node';

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
  String get serverRelayWarning =>
      'Your address includes this server. Switching changes your address; senders need the new one.';

  @override
  String get serverOtherRelay => 'Other server, host or host:port';

  @override
  String get serverMyListNote => 'The one in use and the ones you added.';

  @override
  String get serverPublicNote => 'Tap one to switch to it.';

  @override
  String get serverOtherNode => 'Other node, host or host:port';

  @override
  String get serverOtherNodeInvalid =>
      'Enter a node address such as node.example.com:3413';

  @override
  String get serverAdd => 'Add';

  @override
  String get serverAddedNode => 'Added to My nodes.';

  @override
  String get serverAddedRelay => 'Added to My servers.';

  @override
  String serverDeleted(String host) {
    return 'Deleted $host.';
  }

  @override
  String get serverAlreadyInUse => 'Already in use.';

  @override
  String get serverNoMatch => 'No match.';

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
  String get methodDirectHttp => 'Link · HTTP';

  @override
  String get methodDirectTor => 'Link · Tor';

  @override
  String get methodFile => 'File Transfer';

  @override
  String get methodShortHttp => 'Link · HTTP';

  @override
  String get methodShortTor => 'Link · Tor';

  @override
  String get methodShortQr => 'Direct · QR';

  @override
  String get methodShortFile => 'Direct · File';

  @override
  String get methodGroupHttp => 'HTTP';

  @override
  String get methodGroupTor => 'Tor';

  @override
  String get methodDirectQr => 'Direct · QR Payment';

  @override
  String get methodDirectFile => 'Direct · File Transfer';

  @override
  String get methodDirectFamily => 'Direct';

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
      'Link · HTTP: the payment goes straight to the recipient\'s wallet, which must be open';

  @override
  String get methodArtLabelTor =>
      'Link · Tor: the payment goes straight to the recipient\'s wallet, routed through the Tor network';

  @override
  String get methodArtLabelFile =>
      'Direct · File Transfer: a transaction file is handed over, a response file comes back, then the sender finalizes';

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
  String get sendSwitchedHttp => 'Link · HTTP';

  @override
  String get sendSwitchedEpicbox => 'Via Epicbox';

  @override
  String get sendSwitchedTorAnnounce =>
      'Tor address. Method set to Link · Tor.';

  @override
  String get sendSwitchedHttpAnnounce =>
      'HTTP address. Method set to Link · HTTP.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Epicbox address. Method set to Epicbox.';

  @override
  String get sendReviewMethodHttp => 'Link · HTTP, straight to their wallet';

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
  String get deskInvAdvanced => 'Address and expiry';

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
  String get deskInvIssuerFile => 'Direct · File';

  @override
  String get deskInvIssuerDirect => 'Link';

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
      'A payment for an invoice this device did not issue arrived. It stays on the relay for a day for your other device with this wallet: open the wallet there to finish it.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'An answer to a payment this device did not send arrived. It stays on the relay for a day for your other device with this wallet: open the wallet there to finish it.';

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
  String get helpLanguageLabel => 'Help language';

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
  String get methodDirect => 'Link';

  @override
  String get methodLinkPayment => 'Link Payment';

  @override
  String get methodDirectShape => 'http://host:3415 or xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Their wallet must be open. An onion address goes over Tor.';

  @override
  String get methodArtLabelDirect =>
      'Link: the payment goes straight to the recipient\'s wallet, which must be open';

  @override
  String methodArtSpokenLink(String method) {
    return '$method: the payment goes straight to the recipient\'s wallet, which must be open';
  }

  @override
  String methodArtSpokenQr(String method) {
    return '$method: a code passes from one phone to the phone next to it';
  }

  @override
  String methodArtSpokenFile(String method) {
    return '$method: a transaction file is handed over, a response file comes back, then the sender finalizes';
  }

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
  String get sendSwitchedDirect => 'Link address';

  @override
  String get sendSwitchedDirectAnnounce => 'Link address. Method set to Link.';

  @override
  String get sendDirectAddressShape =>
      'A Link address starts with http:// or https://, or ends in .onion.';

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
      'Network activity goes through the Tor network. Tor hides the wallet’s internet address: each connection passes through several volunteer-run relays, so no server learns where the wallet is. Notifications are off while Tor is on. Being paid at a Tor address is the Link · Tor switch under Transactions.';

  @override
  String get receiveTabDirect => 'Link';

  @override
  String get receiveDirectNeedsTor => 'Link · Tor receiving needs Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Senders use the Epicbox address meanwhile.';

  @override
  String get receiveHttpTitle => 'Link · HTTP address';

  @override
  String get receiveHttpLanLine =>
      'For wallets on this Wi-Fi network, while this wallet is open.';

  @override
  String get receiveHttpNoNetwork =>
      'Not on a Wi-Fi network. No address to hand out.';

  @override
  String get receiveHttpOffWhileTor => 'Off while Tor is on.';

  @override
  String receiveHttpPortInUse(String port) {
    return 'Port $port is used by another program.';
  }

  @override
  String get receiveHttpFailed => 'Could not start.';

  @override
  String get receiveHttpShowQr => 'Show QR';

  @override
  String get receiveHttpHideQr => 'Hide QR';

  @override
  String get receiveHttpQrLabel => 'QR code of the Link · HTTP address';

  @override
  String get netStatusOverTor => 'over Tor';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsHint =>
      'Tells you when a payment or an invoice arrives while the app is closed. Uses the BT Labs Epicbox and Google’s notification service; the message only wakes the app and carries no amount, sender or address. Off while Tor is on, because registering would reveal the phone’s address.';

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
  String get pushNoticeAvailable =>
      'Notifications are available in Settings › Advanced.';

  @override
  String get torWayOver => 'Over Tor';

  @override
  String get torWayWaiting => 'Waiting for Tor';

  @override
  String get torWayNotConnected => 'Tor is not connected.';

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uses all $count outputs · change 1 output',
      one: 'Uses its 1 output · change 1 output',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSomethingWrong => 'Something went wrong';

  @override
  String get deskErrWrongPassword => 'Wrong password';

  @override
  String get deskErrPhraseInvalid => 'Recovery phrase not valid';

  @override
  String get deskErrWalletExists => 'A wallet exists already';

  @override
  String get deskErrWalletNotFound => 'No wallet found';

  @override
  String get deskErrNodeNotAnswering => 'Node not answering';

  @override
  String get deskErrNotEnoughFunds => 'Not enough funds';

  @override
  String get deskErrNotTxFile => 'Not a transaction file for this wallet';

  @override
  String get deskErrEpicboxUnreachable => 'Epicbox server not reachable';

  @override
  String get deskErrNotHttpAddress => 'Not an http(s) address';

  @override
  String get deskErrPlainHttp => 'Plain HTTP not confirmed';

  @override
  String get deskErrNotOnion => 'Not an onion address';

  @override
  String get deskErrTorNotConnected => 'Tor is not connected';

  @override
  String get deskErrOnionUnreachable =>
      'The recipient’s wallet is not reachable over Tor';

  @override
  String get deskErrWalletBusy => 'Wallet busy. Try again in a moment.';

  @override
  String get deskErrDbDamaged => 'Wallet database damaged, rebuilding';

  @override
  String get deskErrPaymentExpired => 'Payment expired';

  @override
  String get deskErrInvoiceNotFound => 'Invoice not found';

  @override
  String get deskErrAmountMismatch => 'Amount differs from the invoice';

  @override
  String get deskErrInvoicePaid => 'Invoice already paid';

  @override
  String get deskErrInvoiceLocked => 'Invoice locked until a later block';

  @override
  String get deskErrInvoiceChanged => 'Invoice changed';

  @override
  String get deskErrNotAccepted => 'Not accepted';

  @override
  String deskErrNotAcceptedDetail(String detail) {
    return 'Not accepted: $detail';
  }

  @override
  String get deskErrDisk => 'Disk error';

  @override
  String deskErrDiskDetail(String detail) {
    return 'Disk error: $detail';
  }

  @override
  String get deskErrTorMissing => 'Tor not included in this build';

  @override
  String get deskErrTorNetwork => 'Can’t reach the Tor network';

  @override
  String get deskErrTorClock => 'The computer’s clock is wrong';

  @override
  String get deskErrOnionNotPublished => 'Onion address not published';

  @override
  String get deskErrTorStart => 'Tor did not start';

  @override
  String get deskErrTorStopped => 'Tor stopped';

  @override
  String get deskErrScanRunning => 'A scan is already running.';

  @override
  String get deskErrCancelRefused =>
      'Not cancelled: the node already has this payment.';

  @override
  String get deskErrWalletLocked => 'The wallet is locked';

  @override
  String get deskErrWalletLocking => 'The wallet is locking';

  @override
  String deskErrDbDamagedDetail(String detail) {
    return 'Wallet database damaged. $detail';
  }

  @override
  String deskErrWalletClosed(String detail) {
    return 'Wallet closed: $detail. Unlock again.';
  }

  @override
  String deskErrNotChanged(String detail) {
    return 'Not changed: $detail';
  }

  @override
  String deskErrPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use at least $count characters',
      one: 'Use at least $count character',
    );
    return '$_temp0';
  }

  @override
  String get deskErrWalletNotListed => 'Wallet not in the list';

  @override
  String get deskErrUpdateApp => 'Update the app to change the list';

  @override
  String get deskErrListNotChanged => 'Wallet list not changed';

  @override
  String get deskErrOpenToDelete => 'Open the wallet to delete it';

  @override
  String get deskErrEnterPassword => 'Enter the password';

  @override
  String get deskErrFolderNotFound => 'Wallet folder not found';

  @override
  String deskErrAlreadyHere(String name) {
    return 'This wallet is already here: $name';
  }

  @override
  String get deskErrTestNet =>
      'Test network wallet. Only mainnet wallets can be imported.';

  @override
  String get deskErrWalletInApp => 'This wallet is in the app already.';

  @override
  String get deskErrWalletNotFoundSearch => 'Wallet not found. Search again.';

  @override
  String get deskErrEnterOldPassword => 'Enter the old password';

  @override
  String deskErrOldPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The old password is short. Choose a new one of at least $count characters.',
      one:
          'The old password is short. Choose a new one of at least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSeedUnreadable => 'The wallet.seed file could not be read';

  @override
  String get deskErrNotSeedFile => 'Not a wallet.seed file';

  @override
  String deskErrAlreadyInApp(String name) {
    return 'Already in the app as $name';
  }

  @override
  String get deskErrWrongOldPassword => 'Wrong old password';

  @override
  String get deskErrListNotSaved => 'Wallet list not saved';

  @override
  String get deskErrProofSeedRead => 'Seed read';

  @override
  String get deskErrProofWalletCreated => 'Wallet created';

  @override
  String deskErrProofContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts added',
      one: '1 contact added',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofNode(String name) {
    return 'Node $name added to the node list';
  }

  @override
  String deskErrProofEpicbox(String old, String current) {
    return 'The older app used the Epicbox server $old; this app uses $current';
  }

  @override
  String get deskErrProofFolderUnchanged => 'Old folder unchanged';

  @override
  String get deskErrProofFolderChanged =>
      'Old folder changed by another program';

  @override
  String deskErrProofHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'History: $count transactions',
      one: 'History: 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofHistoryAlready => 'History already imported';

  @override
  String get deskErrProofHistoryNone =>
      'No history in the old folder; the scan restores the balance';

  @override
  String get deskErrProofHistoryOld =>
      'History of Epic Wallet 5.3 or older is not readable; the scan restores the balance';

  @override
  String get deskErrProofHistoryBusy =>
      'History not imported: the older wallet is running. It is imported at the next unlock';

  @override
  String get deskErrProofHistoryOther =>
      'History not imported: it belongs to another wallet';

  @override
  String get deskErrProofHistoryUnreadable =>
      'History not imported: the old database could not be read; the scan restores the balance';

  @override
  String get deskErrNodeNoAnswer => 'The node did not answer';

  @override
  String get deskErrNotPosted => 'Not posted';

  @override
  String get deskErrNotEpicboxAddress => 'Not an Epicbox address';

  @override
  String get deskErrFileNotSaved =>
      'File not saved. The payment waits in Activity; cancel it there to unlock the funds.';

  @override
  String get deskErrTorOffSend =>
      'Tor is off. Turn on Tor to send to an onion address.';

  @override
  String get deskErrTorConnecting =>
      'Tor is still connecting. Try again in a moment.';

  @override
  String get deskErrRecipientNoAnswer =>
      'The recipient’s wallet did not answer or refused.';

  @override
  String get deskErrRecipientNoAnswerWaits =>
      'The recipient’s wallet did not answer or refused. The payment waits in Activity; cancel it there to unlock the funds.';

  @override
  String get deskErrNotDelivered =>
      'Not delivered. The payment waits in Activity; cancel it there to unlock the funds.';

  @override
  String get deskErrInterruptedLock =>
      'Interrupted by the lock. It may have gone out: check Activity after unlocking.';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail. The payment waits in Activity; cancel it there to unlock the funds.';
  }

  @override
  String get deskErrNodeRefused =>
      'Signed by both wallets, but the node refused it. Cancel it in Activity to unlock the funds.';

  @override
  String get deskErrFileNotReadable => 'File not readable';

  @override
  String get deskErrNotTxFile2 => 'Not a transaction file';

  @override
  String get deskErrResponseNotSaved => 'Response file not saved';

  @override
  String get deskErrCannotCancel => 'This payment cannot be cancelled';

  @override
  String get deskErrNoLocalNode => 'No local node in this build';

  @override
  String get deskErrLocalNodeStopped => 'Local node stopped';

  @override
  String get deskErrNotChangedLocked => 'Not changed: the wallet was locked';

  @override
  String deskErrLocalNodeNotStarted(String detail) {
    return 'Local node not started: $detail';
  }

  @override
  String get deskErrUnknown => 'unknown error';

  @override
  String get deskErrNotServerName => 'Not a server name';

  @override
  String deskErrPortInUse(int port) {
    return 'Port $port in use';
  }

  @override
  String deskErrPortUnavailable(int port) {
    return 'Port $port not available';
  }

  @override
  String get deskErrStoppedWithError => 'Stopped with an error';

  @override
  String get deskErrPasswordNotChanged =>
      'Password not changed. The current password still opens the wallet.';

  @override
  String get deskErrNothingToSpend => 'Nothing to spend';

  @override
  String get deskTorLineOff => 'Off';

  @override
  String get deskTorLineReady => 'Ready';

  @override
  String deskTorLineSendsWork(String problem) {
    return '$problem. Sends work.';
  }

  @override
  String get deskTorLinePublishing => 'Publishing the onion address…';

  @override
  String deskTorLineConnecting(int percent) {
    return 'Connecting to Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'Another wallet\'s backup';

  @override
  String get deskErrHistOtherChain => 'Wrong network';

  @override
  String get deskErrHistNotOurs => 'Not a history backup';

  @override
  String get deskErrHistNewer => 'Newer file';

  @override
  String get deskErrHistDamaged => 'File damaged';

  @override
  String get deskErrOldGui => 'Older Epic Wallet';

  @override
  String get deskErrOldCli => 'The epic program';

  @override
  String get deskErrOldPicked => 'Chosen folders';

  @override
  String get deskErrHistTooLarge => 'The file is too large to be one.';

  @override
  String deskErrHistChains(String from, String to) {
    return 'The file is from $from; this wallet is on $to.';
  }

  @override
  String get deskErrHistOtherWalletText =>
      'The file was exported from a wallet with a different recovery phrase.';

  @override
  String get deskErrHistNewerText =>
      'A newer version of the app made this file. Update the app, then import it.';

  @override
  String get deskErrHistDamagedText => 'The file is incomplete or was changed.';

  @override
  String get deskErrHistNotOursText =>
      'The file was not made by Epic Cash Desktop or Epic Cash Mobile.';

  @override
  String get deskDataHttpEnter => 'Enter the recipient’s address';

  @override
  String get deskDataHttpScheme => 'Start with https:// or http://';

  @override
  String get deskDataHttpOnion => 'Onion addresses need Tor';

  @override
  String get deskDataHttpNot => 'Not an http(s) address';

  @override
  String get deskDataHttpPort => 'Port must be 1 to 65535';

  @override
  String get deskDataUpdTimeout => 'The update server did not answer.';

  @override
  String get deskDataUpdUnreachable =>
      'The update server could not be reached.';

  @override
  String deskDataUpdStatus(int status) {
    return 'The update server answered $status.';
  }

  @override
  String get deskDataUpdNone =>
      'No desktop update information is published yet.';

  @override
  String get deskNodeSynced => 'Synced';

  @override
  String get deskNodeBehind => 'Behind';

  @override
  String get deskNodeNotAnswering => 'Not answering';

  @override
  String get deskNodeChecking => 'Checking';

  @override
  String get deskNodeStarting => 'Starting';

  @override
  String get deskNodeSyncing => 'Syncing';

  @override
  String get deskNodeStalled => 'Stalled';

  @override
  String get deskNodeFailed => 'Failed';

  @override
  String get deskNodeStopped => 'Stopped';

  @override
  String get deskNodeMarkerNoAnswer => 'no answer';

  @override
  String deskNodeMarkerBehind(String count) {
    return '$count behind';
  }

  @override
  String get deskNodeMarkerStarting => 'starting';

  @override
  String get deskNodeMarkerStalled => 'stalled';

  @override
  String get deskNodeMarkerFailed => 'failed';

  @override
  String get deskNodeMarkerStopped => 'stopped';

  @override
  String deskNodeHostSince(String host, String time) {
    return '$host · since $time';
  }

  @override
  String get deskNodeNotAnsweringLine => 'The node is not answering.';

  @override
  String deskNodeLatency(String ms) {
    return '$ms ms';
  }

  @override
  String deskNodeLatencyOverTor(String ms) {
    return '$ms ms over Tor';
  }

  @override
  String deskNodeNewerOut(String version) {
    return '$version is out';
  }

  @override
  String get deskNodeBehindLine => 'Behind the network; catching up.';

  @override
  String deskNodeHeightOf(String height, String total) {
    return '$height of $total';
  }

  @override
  String get deskNodeAtTip => 'at tip';

  @override
  String get deskNodeLocal => 'Local node';

  @override
  String get deskNodeConnectingPeers => 'Connecting to peers';

  @override
  String deskNodeUsingUntilSynced(String host) {
    return 'Using $host until it is synced.';
  }

  @override
  String get deskNodeNothingUntilSynced =>
      'Nothing can be sent until it is synced.';

  @override
  String deskNodePeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '$count peer',
    );
    return '$_temp0';
  }

  @override
  String deskNodeRunning(String duration) {
    return 'running $duration';
  }

  @override
  String deskNodeStillUsing(String host) {
    return 'Still using $host; the local node takes over shortly.';
  }

  @override
  String get deskNodeNoProgress =>
      'No progress for 5 min. Restarted once already.';

  @override
  String deskNodeUsingMeanwhile(String host) {
    return 'Using $host meanwhile.';
  }

  @override
  String get deskNodeStartIt => 'Start it under Settings › Node.';

  @override
  String get deskNodeFailPort => 'port 3413 is used by another program';

  @override
  String get deskNodeFailDisk => 'not enough disk space';

  @override
  String get deskNodeFailMissing => 'the node program is missing';

  @override
  String get deskNodeFailExited => 'the node program stopped';

  @override
  String deskNodeFailExitedCode(String code) {
    return 'the node program stopped (exit code $code)';
  }

  @override
  String get deskNodeFailDefault => 'the node did not start';

  @override
  String get deskNodeStageWaiting => 'connecting to peers';

  @override
  String get deskNodeStageHeaders => 'headers';

  @override
  String get deskNodeStageChainDownload => 'chain state download';

  @override
  String get deskNodeStageKernels => 'checking kernels';

  @override
  String get deskNodeStageRangeProofs => 'checking range proofs';

  @override
  String get deskNodeStageProcessing => 'processing the chain state';

  @override
  String get deskNodeStageBlocks => 'blocks';

  @override
  String get deskNodeStageCompacting => 'compacting';

  @override
  String get deskNodeStageStopping => 'stopping';

  @override
  String get deskNodeStageSyncing => 'syncing';

  @override
  String get deskNodeLineWaiting => 'Connecting to peers';

  @override
  String deskNodeLineHeaders(String done, String total) {
    return 'Headers · $done of $total';
  }

  @override
  String get deskNodeLineHeadersBare => 'Headers';

  @override
  String deskNodeLineChain(String done, String total) {
    return 'Chain state · $done of $total GB';
  }

  @override
  String get deskNodeLineChainBare => 'Chain state';

  @override
  String deskNodeLineKernels(String done, String total) {
    return 'Checking kernels · $done of $total million';
  }

  @override
  String get deskNodeLineKernelsBare => 'Checking kernels';

  @override
  String deskNodeLineRangeProofs(String done, String total) {
    return 'Checking range proofs · $done of $total million';
  }

  @override
  String get deskNodeLineRangeProofsBare => 'Checking range proofs';

  @override
  String get deskNodeLineProcessing => 'Processing the chain state';

  @override
  String deskNodeLineBlocks(String done, String total) {
    return 'Blocks · $done of $total';
  }

  @override
  String get deskNodeLineBlocksBare => 'Blocks';

  @override
  String get deskNodeLineCompacting => 'Compacting the chain data';

  @override
  String get deskNodeLineStopping => 'Stopping…';

  @override
  String get deskNodeLineSyncing => 'Syncing';

  @override
  String get deskNodeNoEstimate => 'no estimate; up to an hour';

  @override
  String get deskNodeEstimating => 'estimating…';

  @override
  String deskNodeAboutHours(int hours) {
    return 'about $hours h left';
  }

  @override
  String deskNodeAboutMinutes(int minutes) {
    return 'about $minutes min left';
  }

  @override
  String deskNodeDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String deskNodeDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String get deskTorNetworkLabel => 'Tor Network';

  @override
  String get deskTorNetworkHint =>
      'Network activity goes through the Tor network. Tor hides the wallet’s internet address: each connection passes through several volunteer-run relays, so no server learns where the wallet is.';

  @override
  String get deskTorOff => 'Off';

  @override
  String get deskTorStarting => 'Starting…';

  @override
  String get deskTorOn => 'On';

  @override
  String get deskTorNotConnected => 'Not connected';

  @override
  String get deskTorRoutes =>
      'Epicbox, the node, status, price, updates, support and Tor addresses';

  @override
  String get deskTorCoverage =>
      'Over Tor: Epicbox, the node, status, price, updates, support and Tor addresses.';

  @override
  String get deskTorNodeOver => 'Over Tor';

  @override
  String get deskTorNodeNotEncrypted => 'Not encrypted past Tor';

  @override
  String get deskTorNodeWaits => 'Waits until Tor is connected.';

  @override
  String get deskRecvTitle => 'Receive';

  @override
  String get deskRecvReceiving => 'Receiving';

  @override
  String get deskRecvNameFile => 'Direct · File Transfer';

  @override
  String deskRecvTurnOnFailed(String method) {
    return '$method not turned on';
  }

  @override
  String deskRecvTurnOffFailed(String method) {
    return '$method not turned off';
  }

  @override
  String get deskRecvOtherWays => 'Other ways to receive';

  @override
  String get deskRecvSettings => 'Settings';

  @override
  String get deskRecvTorNotConnected => 'Tor is not connected.';

  @override
  String get deskRecvTorStarting => 'Tor is starting.';

  @override
  String deskRecvTorDownText(String routes) {
    return 'Nothing arrives over $routes until it is, or until Tor is turned off.';
  }

  @override
  String get deskRecvTorStartingText =>
      'Addresses become reachable once it is connected. Nothing goes over the clearnet meanwhile.';

  @override
  String get deskRecvTurnTorOff => 'Turn Tor off';

  @override
  String get deskRecvTryAgain => 'Try again';

  @override
  String get deskRecvStateOn => 'on';

  @override
  String get deskRecvStateOff => 'off';

  @override
  String get deskRecvStateChecking => 'checking';

  @override
  String deskRecvSemList(String method, String state) {
    return '$method $state';
  }

  @override
  String deskRecvSemMethod(String method, String state) {
    return '$method: $state';
  }

  @override
  String deskRecvTipChecking(String method) {
    return '$method · Checking';
  }

  @override
  String deskRecvTip(String method, String state) {
    return '$method · $state';
  }

  @override
  String deskRecvTipDetail(String method, String state, String detail) {
    return '$method · $state\n$detail';
  }

  @override
  String get deskRecvTagPaused => 'Paused';

  @override
  String get deskRecvTagStarting => 'Starting';

  @override
  String get deskRecvTagNotReachable => 'Not reachable';

  @override
  String get deskRecvAddressUnreadable =>
      'The address could not be read. Open Receive again in a moment.';

  @override
  String get deskRecvEpicboxAddress => 'Epicbox address';

  @override
  String get deskRecvCopyEpicbox => 'Copy Epicbox address';

  @override
  String get deskRecvEpicboxIntro =>
      'Share it to get paid. Works while the wallet is closed: the Epicbox server holds payments until the wallet is back.';

  @override
  String get deskRecvCheckSix =>
      'When reading it out, check the first six and last six characters.';

  @override
  String get deskRecvHttpAddress => 'Link · HTTP address';

  @override
  String get deskRecvCopyHttp => 'Copy Link · HTTP address';

  @override
  String deskRecvHttpPublic(int port) {
    return 'Your router’s public address. Senders on the internet use it once the router forwards port $port.';
  }

  @override
  String get deskRecvHttpLocal =>
      'Programs on this computer can pay this address. For other devices, see Settings › Transactions.';

  @override
  String get deskRecvHttpIntro =>
      'Straight from another wallet while this one is open. On this computer only unless Settings says otherwise.';

  @override
  String get deskRecvHttpTorHint =>
      'Turn on Tor in Settings › Privacy for a Tor address instead.';

  @override
  String get deskRecvDirectTor => 'Link · Tor address';

  @override
  String get deskRecvTorIntro =>
      'Straight from another wallet over Tor while this one is open. Tor is set in Settings › Privacy.';

  @override
  String get deskRecvTorAddress => 'Link · Tor address';

  @override
  String get deskRecvCopyTor => 'Copy Tor address';

  @override
  String get deskRecvTorOnion =>
      'Some wallets show the address without .onion; both are the same address.';

  @override
  String get deskRecvFiles => 'Transaction files';

  @override
  String get deskRecvSignTitle => 'Sign a transaction file';

  @override
  String get deskRecvSignText =>
      'A sender gave a transaction file. The wallet signs it and saves a response for them.';

  @override
  String get deskRecvOpen => 'Open';

  @override
  String get deskRecvFinalizeTitle => 'Finalize a response file';

  @override
  String get deskRecvFinalizeText =>
      'A file send got a response back. Finalizing posts the payment.';

  @override
  String deskRecvSwitchLabel(String title) {
    return '$title, receiving';
  }

  @override
  String get deskSendStrategySmallest => 'Smallest';

  @override
  String get deskSendStrategyAll => 'All';

  @override
  String get deskSendBalanceAfter => 'Balance after';

  @override
  String get deskSendSpendableUntil => 'Spendable until change confirms';

  @override
  String deskSendSplitLine(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Change split into $outputs outputs (+$fee EPIC fee)',
      one: 'Change split into $outputs output (+$fee EPIC fee)',
    );
    return '$_temp0';
  }

  @override
  String deskSendSplitWhy(int outputs, String each) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other:
          'So the next send does not wait for this one to confirm. Change comes back as $outputs outputs of about $each EPIC instead of one.',
      one:
          'So the next send does not wait for this one to confirm. Change comes back as $outputs output of about $each EPIC instead of one.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendSplitWhyLabel => 'Why the change is split';

  @override
  String deskSendLockNoChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No change: $count outputs spent exactly, nothing waits.',
      one: 'No change: 1 output spent exactly, nothing waits.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockAll(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Everything is locked: $count outputs, $amount EPIC, about 3 blocks.',
      one: 'Everything is locked: 1 output, $amount EPIC, about 3 blocks.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs locked, $amount EPIC, about 3 blocks.',
      one: '1 output locked, $amount EPIC, about 3 blocks.',
    );
    return '$_temp0';
  }

  @override
  String deskSendStrategyLine(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Strategy for this send: $strategy · $count outputs.',
      one: 'Strategy for this send: $strategy · 1 output.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSplit(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Change split into $outputs outputs (+$fee EPIC).',
      one: 'Change split into $outputs output (+$fee EPIC).',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksNone(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$locked EPIC in $count outputs; no change comes back.',
      one: '$locked EPIC in 1 output; no change comes back.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Everything: $locked EPIC in $count outputs until the change confirms (3 blocks). Nothing stays spendable.',
      one:
          'Everything: $locked EPIC in 1 output until the change confirms (3 blocks). Nothing stays spendable.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count outputs until the change confirms (3 blocks). Nothing else is spendable meanwhile.',
      one:
          '$locked EPIC in 1 output until the change confirms (3 blocks). Nothing else is spendable meanwhile.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksSome(int count, String locked, String spendable) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count outputs until the change confirms (3 blocks). $spendable EPIC stays spendable.',
      one:
          '$locked EPIC in 1 output until the change confirms (3 blocks). $spendable EPIC stays spendable.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendFactLocks => 'Locks';

  @override
  String get deskSendFactStrategy => 'Strategy';

  @override
  String deskSendFactStrategyValue(String strategy) {
    return '$strategy outputs, for this send';
  }

  @override
  String get deskSendAdvSmallest => '· Smallest outputs';

  @override
  String get deskSendAdvSmallestNoSplit =>
      '· Smallest outputs, change not split';

  @override
  String get deskSendAdvAll => '· All outputs';

  @override
  String get deskSendAdvAllNoSplit => '· All outputs, change not split';

  @override
  String get deskSendAdvanced => 'Send options';

  @override
  String get deskSendAdvStrategy => 'Strategy for this send';

  @override
  String get deskSendAdvSmallestText =>
      'Spends the fewest small outputs; the rest of the balance stays spendable while the change confirms.';

  @override
  String get deskSendAdvAllText =>
      'Spends every spendable output and returns one change output. Everything is locked until it confirms; fewer, larger outputs afterwards.';

  @override
  String get deskSendDefaultTag => 'default';

  @override
  String get deskSendAdvAllNote => 'Sending everything spends every output.';

  @override
  String get deskSendAdvSplit => 'Split change';

  @override
  String get deskSendAdvSplitText =>
      'Returns the change as several outputs when few would be left, so the next send does not wait.';

  @override
  String get deskSendAdvDefaults => 'For this send only. Defaults: ';

  @override
  String get deskSendAdvOutputsLink => 'Outputs';

  @override
  String get deskSendPickNone => 'No contacts yet';

  @override
  String get deskSendPickNoneText =>
      'Save the people you pay in Contacts, then choose them here.';

  @override
  String get deskSendPickOpen => 'Open contacts';

  @override
  String deskSendPickNoMatch(String query) {
    return 'No contact matches \"$query\".';
  }

  @override
  String get deskSendPickTitle => 'Choose contact';

  @override
  String get deskSendPickDesc => 'The address fills the recipient field.';

  @override
  String get deskSendPickSearch => 'Search contacts';

  @override
  String get deskSendTitle => 'Send';

  @override
  String get deskSendErrNoAddress => 'Add an address to send to.';

  @override
  String get deskSendErrEpicbox => 'This is not a valid Epicbox address.';

  @override
  String get deskSendErrNotDirect => 'This is not a Link address.';

  @override
  String get deskSendErrOnion => 'This is not a valid onion address.';

  @override
  String get deskSendErrOwn => 'This is the wallet\'s own address.';

  @override
  String get deskSendNoAnswer =>
      'The recipient did not answer. Nothing was sent.';

  @override
  String get deskSendTorOnFailed => 'Tor not turned on';

  @override
  String get deskSendTorOffFailed => 'Tor not turned off';

  @override
  String get deskSendEpicboxOnFailed => 'Epicbox not turned on';

  @override
  String get deskSendNothingSpendable => 'Nothing spendable to send.';

  @override
  String get deskSendAllFailed =>
      'Could not work out how much can be sent. Try again in a moment.';

  @override
  String get deskSendErrAmountEnter => 'Enter an amount.';

  @override
  String get deskSendErrAmountDecimals => 'EPIC has at most 8 decimals.';

  @override
  String get deskSendErrAmountZero => 'The amount must be more than 0.';

  @override
  String get deskSendErrAmountMore => 'More than the available balance.';

  @override
  String get deskSendSent => 'Sent';

  @override
  String get deskSendFileReadyTitle => 'Transaction file ready';

  @override
  String get deskSendFileReadyText =>
      'Give this file to the recipient. The wallet is waiting for the response file; finalize it when it comes back.';

  @override
  String get deskSendFinalize => 'Finalize';

  @override
  String get deskSendNewSend => 'New send';

  @override
  String get deskSendNodeNotSynced => 'Node not synced';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Sending is possible once the node has synced. $percent% done; the form can be filled in meanwhile.';
  }

  @override
  String get deskSendNodeSyncing =>
      'Sending is possible once the node has synced.';

  @override
  String get deskSendTorBlocked => 'Tor is not connected';

  @override
  String get deskSendTorBlockedText =>
      'Nothing is sent until it is, or until Tor is turned off.';

  @override
  String get deskSendTurnTorOff => 'Turn Tor off';

  @override
  String get deskSendTorStarting => 'Tor is starting';

  @override
  String get deskSendTorStartingText =>
      'Sending waits until it is connected. Nothing goes over the clearnet meanwhile.';

  @override
  String get deskSendEpicboxOff => 'Epicbox not connected';

  @override
  String get deskSendEpicboxOffText =>
      'Epicbox sends work once Epicbox receiving is on. Use Direct · File Transfer meanwhile.';

  @override
  String get deskSendEpicboxTurnOn => 'Turn on Epicbox receiving';

  @override
  String get deskSendDoneViaDirect => 'Finalized and posted to the network.';

  @override
  String get deskSendDoneViaEpicbox =>
      'Handed to Epicbox. Completes when the recipient answers.';

  @override
  String get deskSendViewTx => 'View transaction';

  @override
  String get deskSendFailedTitle => 'Send failed';

  @override
  String get deskSendReviewAgain => 'Review again';

  @override
  String get deskSendMethodDirect => 'Link';

  @override
  String get deskSendMethodFile => 'Direct · File';

  @override
  String get deskSendTo => 'To';

  @override
  String get deskSendToHelp => 'Paste an address, or type a contact’s name.';

  @override
  String get deskSendToHint => 'Address or contact';

  @override
  String get deskSendToSem => 'Recipient';

  @override
  String get deskSendClearTo => 'Clear recipient';

  @override
  String get deskSendContacts => 'Contacts';

  @override
  String get deskSendNeedsTor => 'Needs Tor';

  @override
  String get deskSendNeedsTorText =>
      'An onion address can only be reached over Tor.';

  @override
  String get deskSendNoTorBuild => 'Tor is not in this build.';

  @override
  String get deskSendTurnOnTor => 'Turn on Tor';

  @override
  String get deskSendHttpClearnet =>
      'Link · HTTP goes over the clearnet, not Tor.';

  @override
  String get deskSendClear => 'Clear';

  @override
  String get deskSendAmount => 'Amount';

  @override
  String get deskSendAvailableNone => 'Available —';

  @override
  String deskSendAvailable(String amount) {
    return 'Available $amount EPIC';
  }

  @override
  String get deskSendAmountSem => 'Amount in EPIC';

  @override
  String get deskSendAllButton => 'All';

  @override
  String get deskSendConfirmingHidden =>
      'Part of the balance is still confirming and cannot be sent yet.';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC is still confirming and cannot be sent yet.';
  }

  @override
  String get deskSendMessage => 'Message';

  @override
  String get deskSendMessageHelp => 'The recipient sees this message.';

  @override
  String get deskSendPrivacyOn => 'Privacy · Dandelion++ on';

  @override
  String get deskSendPrivacyOff => 'Privacy · Dandelion++ off';

  @override
  String get deskSendDandelionText =>
      'Passes the transaction through a few random nodes before it spreads, so the network cannot tell where it came from.';

  @override
  String get deskSendHintSent =>
      'Sent. Enter a new amount and recipient to send again.';

  @override
  String get deskSendHintNode => 'Waiting for the node to sync.';

  @override
  String get deskSendHintEpicbox => 'Waiting for Epicbox to connect.';

  @override
  String get deskSendHintTorWait => 'Waiting for Tor to connect.';

  @override
  String get deskSendHintTorBlocked => 'Retry Tor, or turn it off.';

  @override
  String get deskSendHintNeedsTor => 'Turn on Tor to send to an onion address.';

  @override
  String get deskSendHintFix => 'Fix the fields marked in red.';

  @override
  String get deskSendHintChecking => 'Checking the fee for this amount.';

  @override
  String get deskSendHintDefault => 'Nothing is sent until confirmed.';

  @override
  String get deskSendReviewWaitTor => 'Waiting for Tor';

  @override
  String get deskSendReviewTorOff => 'Tor not connected';

  @override
  String get deskSendReview => 'Review send';

  @override
  String get deskSendSummary => 'Summary';

  @override
  String get deskSendNetworkFee => 'Network fee';

  @override
  String get deskSendTotal => 'Total';

  @override
  String get deskSendUpdating => 'Balance updating while the wallet scans.';

  @override
  String get deskSendEpicboxLine1 => 'The recipient can be offline.';

  @override
  String get deskSendEpicboxLine2 =>
      'The Epicbox server holds the payment until they open their wallet.';

  @override
  String get deskSendDirectLine1 => 'Straight to their wallet.';

  @override
  String get deskSendDirectLine2 =>
      'An http(s) or .onion address; an onion goes over Tor. Their wallet must be open.';

  @override
  String get deskSendFileLine1 => 'No connection needed.';

  @override
  String get deskSendFileLine2 =>
      'Hand the file over, get their response file back, then finalize it here.';

  @override
  String get deskSendTagDirect => 'Link';

  @override
  String get deskSendTagFile => 'Direct · File';

  @override
  String get deskSendTagEpicbox => 'Via Epicbox';

  @override
  String get deskSendSwitchedDirect => 'Link address. Method set to Link.';

  @override
  String get deskSendSwitchedFile =>
      'File address. Method set to Direct · File.';

  @override
  String get deskSendSwitchedEpicbox =>
      'Epicbox address. Method set to Epicbox.';

  @override
  String get deskSendMatching => 'Matching contacts';

  @override
  String deskSendMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts match',
      one: '1 contact matches',
    );
    return '$_temp0';
  }

  @override
  String get deskSendWrongPassword => 'Wrong password.';

  @override
  String get deskSendNotConfirmed =>
      'Not confirmed. Check Activity before sending again.';

  @override
  String get deskSendViaEpicbox => 'Epicbox (the recipient can be offline)';

  @override
  String get deskSendViaDirect => 'Link · HTTP (their wallet must be open)';

  @override
  String get deskSendViaTor => 'Link · Tor (their wallet must be open)';

  @override
  String get deskSendViaFile => 'Transaction file';

  @override
  String deskSendUsesAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uses all $count outputs · change 1 output',
      one: 'Uses its 1 output · change 1 output',
    );
    return '$_temp0';
  }

  @override
  String get deskSendReviewTitle => 'Check and send';

  @override
  String get deskSendReviewDesc => 'A send cannot be undone once it is posted.';

  @override
  String get deskSendFactTo => 'To';

  @override
  String get deskSendCheckChars =>
      'Check the highlighted characters against what the recipient gave.';

  @override
  String get deskSendFactVia => 'Via';

  @override
  String get deskSendFactPrivacy => 'Privacy';

  @override
  String get deskSendDandelionOn => 'Dandelion++ on';

  @override
  String get deskSendDandelionOff => 'Dandelion++ off';

  @override
  String get deskSendFactMessage => 'Message';

  @override
  String get deskSendPassword => 'Password';

  @override
  String get deskSendPasswordHelp => 'Every send asks the wallet’s password.';

  @override
  String get deskSendBusyFile => 'Creating the file.';

  @override
  String get deskSendBusyTor =>
      'Reaching their wallet over Tor… This can take a while. Keep the app open.';

  @override
  String get deskSendBusy =>
      'Sending. This can take a few seconds; keep this window open.';

  @override
  String get deskSendBack => 'Back';

  @override
  String get deskSendSending => 'Sending';

  @override
  String deskSendConfirm(String amount) {
    return 'Send $amount EPIC';
  }

  @override
  String get deskSendPlainTitle => 'Not encrypted. Send anyway?';

  @override
  String get deskSendPlainDesc =>
      'Plain HTTP to another computer. Anyone on the way can read the transaction. https:// is encrypted.';

  @override
  String get deskSendPlainConfirm => 'Send anyway';

  @override
  String deskSendEpicboxSwitched(String domain) {
    return 'Switched to $domain';
  }

  @override
  String get deskSendEpicboxNotSwitched => 'Not switched';

  @override
  String get deskSendEpicboxDownTitle => 'Epicbox server not answering';

  @override
  String get deskSendEpicboxDownWait => 'Payments wait until it is back.';

  @override
  String deskSendEpicboxSwitchTo(String domain) {
    return 'Switch to $domain?';
  }

  @override
  String get deskSendEpicboxSwitch => 'Switch';

  @override
  String get deskFinOpenFolder => 'Open folder';

  @override
  String get deskFinFolderNotOpened => 'Folder not opened';

  @override
  String get deskFinWrongType => 'Not a response file';

  @override
  String get deskFinWrongTypeText =>
      'The file is not a response file. Choose the file the recipient sent back.';

  @override
  String get deskFinUnreadable => 'File not readable';

  @override
  String get deskFinUnreadableText =>
      'The file could not be read. It may be damaged or still being copied.';

  @override
  String get deskFinFailed => 'Finalizing failed';

  @override
  String get deskFinFailedText =>
      'The wallet could not finalize this file. It may belong to another transaction or be finalized already.';

  @override
  String get deskFinNotPosted => 'Not posted';

  @override
  String get deskFinNotPostedText =>
      'The transaction was finalized but the node did not accept it. Check the node, then try again.';

  @override
  String get deskFinPickTitle => 'Response file';

  @override
  String get deskFinPosted => 'Transaction posted';

  @override
  String get deskFinTitle => 'Finalize a response file';

  @override
  String get deskFinNoticeTitle => 'For a transaction created as a file';

  @override
  String get deskFinNoticeText =>
      'Use the response file the recipient sent back.';

  @override
  String get deskFinTryAgain => 'Try again';

  @override
  String get deskFinPostedText =>
      'The payment was finalized and sent to the network. Follow it in Activity.';

  @override
  String get deskFinAnother => 'Finalize another file';

  @override
  String get deskFinViewActivity => 'View in Activity';

  @override
  String get deskFinBusy => 'Finalizing and posting';

  @override
  String get deskFinChoose => 'Choose a response file';

  @override
  String get deskFinChooseText =>
      'The wallet completes the transaction and posts it to the network.';

  @override
  String get deskFinChooseFile => 'Choose file';

  @override
  String get deskImpWrongType => 'Not a transaction file';

  @override
  String get deskImpWrongTypeText =>
      'The file is not a transaction file. Choose the .slate or .tx file the sender gave.';

  @override
  String get deskImpUnreadable => 'File not readable';

  @override
  String get deskImpUnreadableText =>
      'The file could not be read. It may be damaged or still being copied.';

  @override
  String get deskImpNoPlace => 'Nothing signed';

  @override
  String get deskImpNoPlaceText =>
      'No place was chosen for the response file, so nothing was signed.';

  @override
  String get deskImpFailed => 'Signing failed';

  @override
  String get deskImpFailedText =>
      'The wallet could not sign this file. It may be for another wallet or already used.';

  @override
  String deskImpFailedDetail(String detail) {
    return 'The wallet could not sign this file. It may be for another wallet or already used. $detail.';
  }

  @override
  String get deskImpPickTitle => 'Transaction file';

  @override
  String get deskImpTitle => 'Sign a transaction file';

  @override
  String get deskImpNoticeTitle => 'Signing does not spend anything';

  @override
  String get deskImpNoticeText =>
      'Send the response file back to the sender over the same channel they used.';

  @override
  String get deskImpSaved => 'Response saved';

  @override
  String get deskImpSavedText =>
      'Send the response file back to the sender. The EPIC arrives once the sender finalizes it.';

  @override
  String get deskImpAmount => 'Amount ';

  @override
  String get deskImpAnother => 'Sign another file';

  @override
  String get deskImpBusy => 'Signing the file';

  @override
  String get deskImpChoose => 'Choose a transaction file';

  @override
  String get deskImpChooseText =>
      'The wallet signs it and saves a response for the sender.';

  @override
  String get deskActNotUpdated => 'Not updated';

  @override
  String get deskActSearchHint => 'Address or slate id';

  @override
  String get deskActSearchHintEmpty => 'Nothing to search yet';

  @override
  String get deskActSearchLabel => 'Search transactions';

  @override
  String get deskActClearSearch => 'Clear search';

  @override
  String get deskActShowAmounts => 'Show amounts';

  @override
  String get deskActHideAmounts => 'Hide amounts';

  @override
  String get deskActRefresh => 'Refresh';

  @override
  String get deskActTitle => 'Activity';

  @override
  String get deskActDetailReceived => 'Received transaction';

  @override
  String get deskActDetailSent => 'Sent transaction';

  @override
  String get deskActLoading => 'Loading transactions';

  @override
  String get deskActWaitingNode => 'Waiting for the node to be synced.';

  @override
  String get deskActFilterAll => 'All';

  @override
  String get deskActFilterReceived => 'Received';

  @override
  String get deskActFilterSent => 'Sent';

  @override
  String get deskActNoMatchTitle => 'No transactions match';

  @override
  String get deskActNoMatchText =>
      'Try another address or slate id, or clear the filter.';

  @override
  String deskActPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get deskActPrevPage => 'Previous page';

  @override
  String get deskActNextPage => 'Next page';

  @override
  String get deskActPages => 'Pages';

  @override
  String get deskActColFromTo => 'From / to';

  @override
  String get deskActColStatus => 'Status';

  @override
  String get deskActColTime => 'Time';

  @override
  String get deskActColAmount => 'Amount';

  @override
  String get deskActEmptyTitle => 'No transactions yet';

  @override
  String get deskActEmptyText =>
      'Every payment sent or received is listed here, newest first, with who it was with and how far along it is.';

  @override
  String get deskActStageWaiting => 'Waiting';

  @override
  String get deskActStageWaitingText =>
      'Both wallets sign it. Over Epicbox this is automatic.';

  @override
  String get deskActStageConfirming => 'Confirming';

  @override
  String get deskActStageConfirmingText =>
      'On the chain. About one block a minute.';

  @override
  String get deskActStageSpendable => 'Spendable';

  @override
  String deskActStageSpendableText(int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'After $needed confirmations, about $needed minutes.',
      one: 'After $needed confirmation, about $needed minute.',
    );
    return '$_temp0';
  }

  @override
  String get deskActShowAddress => 'Show address';

  @override
  String get deskActReceiveFile => 'Receive a file';

  @override
  String get deskConTitle => 'Contacts';

  @override
  String get deskConLoading => 'Loading contacts';

  @override
  String get deskConNewTitle => 'New contact';

  @override
  String get deskConEditTitle => 'Edit contact';

  @override
  String get deskConDetailsTitle => 'Details';

  @override
  String get deskConSearchHint => 'Name or address';

  @override
  String get deskConSearchLabel => 'Search contacts';

  @override
  String get deskConClearSearch => 'Clear search';

  @override
  String deskConCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '$count contact',
    );
    return '$_temp0';
  }

  @override
  String get deskConNoMatches => 'No matches';

  @override
  String deskConMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '$count match',
    );
    return '$_temp0';
  }

  @override
  String get deskConSortName => 'Name';

  @override
  String get deskConSortRecent => 'Recent';

  @override
  String get deskConNone => 'No contacts yet.';

  @override
  String get deskConNoMatchList => 'No contacts match';

  @override
  String get deskConAdd => 'Add contact';

  @override
  String get deskConIdle =>
      'Choose a contact to see their details, send to them, edit or delete them.';

  @override
  String get deskConEmptyTitle => 'No contacts yet';

  @override
  String get deskConEmptyText =>
      'Save the people and shops paid often. On Send, pick a name instead of pasting an address.';

  @override
  String get deskConEmptyLocal =>
      'Contacts stay on this computer. They are not part of the recovery phrase.';

  @override
  String get deskConSendToAddress => 'Send to address';

  @override
  String deskConLastTx(String when) {
    return 'Last transaction: $when';
  }

  @override
  String get deskConSend => 'Send';

  @override
  String get deskConEdit => 'Edit';

  @override
  String get deskConStar => 'Star';

  @override
  String get deskConUnstar => 'Unstar';

  @override
  String get deskConDelete => 'Delete';

  @override
  String get deskConNotDeleted => 'Not deleted';

  @override
  String deskConDeleted(String name) {
    return '$name was deleted';
  }

  @override
  String get deskConAddrEpicbox => 'Epicbox address';

  @override
  String get deskConAddrTor => 'Link · Tor address';

  @override
  String get deskConAddrHttp => 'Link · HTTP address';

  @override
  String get deskConNote => 'Note';

  @override
  String deskConTxWith(String name) {
    return 'Transactions with $name';
  }

  @override
  String get deskConAllTx => 'All transactions';

  @override
  String get deskConTxNone =>
      'No transactions with this contact yet. Payments sent to them from Send appear here.';

  @override
  String get deskConTxReceived => 'Received';

  @override
  String get deskConTxSent => 'Sent';

  @override
  String get deskConErrName => 'Give the contact a name.';

  @override
  String get deskConErrAddressEmpty => 'Add an address.';

  @override
  String get deskConErrAddressInvalid =>
      'Not a valid address. Use an Epicbox address (es5x…@epicbox.epiccash.com), a Link address (https://…) or an onion address (….onion).';

  @override
  String get deskConAddPicture => 'Add picture';

  @override
  String get deskConChangePicture => 'Change picture';

  @override
  String get deskConRemovePicture => 'Remove';

  @override
  String get deskConPictureHelp =>
      'PNG, JPEG, WebP or GIF, up to 10 MB. A small copy is kept in this app.';

  @override
  String get deskConFieldName => 'Name';

  @override
  String get deskConFieldAddress => 'Address';

  @override
  String get deskConSaveFailed => 'Contact not saved';

  @override
  String get deskConSave => 'Save contact';

  @override
  String deskConDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deskConDeleteBody =>
      'The contact’s address and note are removed from this wallet. Past transactions stay in Activity. This cannot be undone.';

  @override
  String get deskConKeep => 'Keep contact';

  @override
  String get deskConDeleteAction => 'Delete contact';

  @override
  String get deskOutNotUpdated => 'Not updated';

  @override
  String get deskOutTitle => 'Outputs';

  @override
  String get deskOutShowAmounts => 'Show amounts';

  @override
  String get deskOutHideAmounts => 'Hide amounts';

  @override
  String get deskOutRefresh => 'Refresh';

  @override
  String get deskOutLockedNote =>
      'Locked outputs are being spent by a transaction in progress. Their change shows as awaiting finalization and is not in Total until the send is finalized, so Total counts the coins once.';

  @override
  String get deskOutIntro =>
      'Outputs are the pieces the balance is made of. A send spends whole outputs, pays the recipient and returns the rest as a new output; the spent ones are locked until the send confirms.';

  @override
  String deskOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs',
      one: '$count output',
    );
    return '$_temp0';
  }

  @override
  String get deskOutCardWait =>
      'Wait until the send confirms (about 3 blocks).';

  @override
  String get deskOutSplitNothing => 'Nothing to split yet.';

  @override
  String deskOutSplitSpends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Spends $count outputs.',
      one: 'Spends $count output.',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitSpendsFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Spends $count outputs. Fee from $fee EPIC.',
      one: 'Spends $count output. Fee from $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutConsNothing => 'Nothing to consolidate yet.';

  @override
  String get deskOutConsOne => 'Nothing to consolidate: one spendable output.';

  @override
  String deskOutConsInto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs into 1.',
      one: '$count output into 1.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsIntoFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs into 1. Fee $fee EPIC.',
      one: '$count output into 1. Fee $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutSplitCardTitle => 'Split';

  @override
  String get deskOutSplitCardText =>
      'Makes more outputs from the spendable balance, so several sends can follow each other without waiting.';

  @override
  String get deskOutSplitCardButton => 'Split…';

  @override
  String get deskOutConsCardTitle => 'Consolidate';

  @override
  String get deskOutConsCardText =>
      'Merges every spendable output into one. Smaller fees on the next send; everything is locked until it confirms.';

  @override
  String get deskOutConsCardButton => 'Consolidate…';

  @override
  String get deskOutNotLoadedTitle => 'Outputs not loaded';

  @override
  String get deskOutNotLoadedText => 'Refresh to try again.';

  @override
  String get deskOutLoading => 'Loading wallet data';

  @override
  String get deskOutNoneTitle => 'No outputs yet';

  @override
  String get deskOutNoneText =>
      'The first payment received makes one. Split and Consolidate need something to work with.';

  @override
  String get deskOutFilterAll => 'All';

  @override
  String get deskOutFilterSpendable => 'Spendable';

  @override
  String get deskOutFilterConfirming => 'Confirming';

  @override
  String get deskOutFilterLocked => 'Locked';

  @override
  String get deskOutSearchHint => 'Commitment';

  @override
  String get deskOutSearchLabel => 'Search outputs';

  @override
  String get deskOutClearSearch => 'Clear search';

  @override
  String get deskOutShowSpent => 'Show spent';

  @override
  String get deskOutNoMatchTitle => 'No outputs match';

  @override
  String get deskOutNoMatchText =>
      'Try another commitment, or clear the filter.';

  @override
  String get deskOutClearFilter => 'Clear filter';

  @override
  String get deskOutTileSpendable => 'Spendable';

  @override
  String get deskOutTileConfirming => 'Confirming';

  @override
  String get deskOutTileImmature => 'Immature';

  @override
  String get deskOutTileLocked => 'Locked in sends';

  @override
  String get deskOutTileTotal => 'Total';

  @override
  String get deskOutStrategyTitle => 'Strategy for sends';

  @override
  String get deskOutStrategySmallest => 'Smallest';

  @override
  String get deskOutStrategyAll => 'All';

  @override
  String get deskOutStrategyHelpTitle => 'Smallest or All';

  @override
  String get deskOutSplitChangeTitle => 'Split change';

  @override
  String get deskOutSplitChangeText =>
      'When a send would leave fewer than 3 spendable outputs and its change is at least 1 EPIC, the change comes back as up to 4 outputs of at least 0.5 EPIC each. Costs 0.004 EPIC per extra output.';

  @override
  String get deskOutColValue => 'Value';

  @override
  String get deskOutColStatus => 'Status';

  @override
  String get deskOutColConfirmations => 'Confirmations';

  @override
  String get deskOutColHeight => 'Height';

  @override
  String get deskOutColTransaction => 'Transaction';

  @override
  String get deskOutColCommitment => 'Commitment';

  @override
  String get deskOutStatusSpendable => 'Spendable';

  @override
  String get deskOutStatusConfirming => 'Confirming';

  @override
  String deskOutConfirmations(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number confirmations',
      one: '$number confirmation',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusAwaiting => 'Awaiting finalization';

  @override
  String get deskOutNoteWaitingSender => 'waiting for the sender';

  @override
  String get deskOutStatusUnpaid => 'Unpaid invoice';

  @override
  String get deskOutNoteNotInBalance => 'not in the balance';

  @override
  String get deskOutStatusImmature => 'Immature';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number blocks to go',
      one: '$number block to go',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusMining => 'Mining';

  @override
  String get deskOutStatusLocked => 'Locked';

  @override
  String deskOutNoteBySend(int id) {
    return 'by send #$id';
  }

  @override
  String get deskOutStatusSpent => 'Spent';

  @override
  String deskOutTxReceived(String date) {
    return 'Received $date';
  }

  @override
  String deskOutTxSent(String date) {
    return 'Sent $date';
  }

  @override
  String deskOutCopyCommitment(String short) {
    return 'Copy commitment $short';
  }

  @override
  String deskOutSplitSpentPart(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs ($amount EPIC)',
      one: '$count output ($amount EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitMadePart(int count, String amount) {
    return '$count outputs of about $amount EPIC';
  }

  @override
  String deskOutConsMadePart(String amount) {
    return 'one output of $amount EPIC';
  }

  @override
  String deskOutSplitDialogText(String spent, String made) {
    return 'Spends $spent and makes $made each. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then.';
  }

  @override
  String deskOutConsDialogText(String spent, String made) {
    return 'Spends $spent and makes $made. A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then. The next send spends one output, so its fee is the smallest.';
  }

  @override
  String get deskOutFactFee => 'Network fee';

  @override
  String get deskOutFactEach => 'Each output';

  @override
  String deskOutFactAbout(String amount) {
    return 'about $amount EPIC';
  }

  @override
  String get deskOutFactLocked => 'Locked';

  @override
  String deskOutFactLockedValue(String amount) {
    return '$amount EPIC, about 3 blocks. Nothing stays spendable.';
  }

  @override
  String get deskOutMakeLabel => 'Outputs to make';

  @override
  String get deskOutMakeRange => '2 to 10.';

  @override
  String get deskOutStepperFewer => 'Fewer';

  @override
  String get deskOutStepperMore => 'More';

  @override
  String get deskOutFeeWorking => 'Working out the fee';

  @override
  String get deskOutNoEstimate => 'No estimate';

  @override
  String get deskOutEachMin => 'Each output must be at least 0.5 EPIC.';

  @override
  String get deskOutNotEnoughFee => 'Not enough to pay the fee.';

  @override
  String deskOutSplitInto(int count) {
    return 'Split into $count';
  }

  @override
  String get deskOutConsolidateButton => 'Consolidate';

  @override
  String get deskOutPostingSplit =>
      'Building and posting the split. Keep the app open.';

  @override
  String get deskOutPostingCons =>
      'Building and posting the consolidate. Keep the app open.';

  @override
  String get deskOutSplitPosted => 'Split posted';

  @override
  String get deskOutConsPosted => 'Consolidate posted';

  @override
  String deskOutSplitDoneText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The wallet now has $count outputs of about $amount EPIC, confirming. Everything is locked until they confirm (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.',
      one:
          'The wallet now has $count output of about $amount EPIC, confirming. Everything is locked until they confirm (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount) {
    return 'One output of $amount EPIC, confirming. Everything is locked until it confirms (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.';
  }

  @override
  String get deskOutNotPostedTitle => 'Not posted.';

  @override
  String get deskOutNotPostedSplit =>
      'The split was built and stored, but the node did not take it. Post it again, or cancel it to unlock the outputs.';

  @override
  String get deskOutNotPostedCons =>
      'The consolidate was built and stored, but the node did not take it. Post it again, or cancel it to unlock the outputs.';

  @override
  String get deskOutCancelSplit => 'Cancel the split';

  @override
  String get deskOutCancelCons => 'Cancel the consolidate';

  @override
  String get deskOutPostAgain => 'Post again';

  @override
  String get deskOutNotDoneTitle => 'Not done';

  @override
  String deskOutNotDoneText(String error) {
    return '$error. The outputs are unchanged.';
  }

  @override
  String get deskOutSomethingWrong => 'Something went wrong';

  @override
  String get deskOutTryAgain => 'Try again';

  @override
  String get deskOutToastNotPosted => 'Not posted';

  @override
  String get deskOutToastNotCancelled => 'Not cancelled';

  @override
  String get deskOutSplitDialogTitle => 'Split outputs';

  @override
  String get deskOutConsDialogTitle => 'Consolidate outputs';

  @override
  String get deskOutPostingDesc => 'Posting.';

  @override
  String get deskOutDoneDesc => 'Done.';

  @override
  String get deskOutSplitDesc =>
      'More outputs, so several sends can follow each other.';

  @override
  String get deskOutConsDesc => 'One output instead of many.';

  @override
  String deskOutNothingText(String what) {
    return 'Nothing to consolidate: the wallet has $what. Consolidate merges several outputs into one.';
  }

  @override
  String get deskOutWhatFewer => 'fewer than two spendable outputs';

  @override
  String get deskOutWhatOne => 'one spendable output';

  @override
  String get deskOvNotUpdated => 'Not updated';

  @override
  String get deskOvNodeNotStarted => 'Node not started';

  @override
  String get deskOvNodeAddrTitle => 'Node address updated';

  @override
  String get deskOvNodeAddrText =>
      'Now using node.epiccash.com instead of node.epiccash.com:3413.';

  @override
  String get deskOvNodeIncompatTitle =>
      'This node’s version is not compatible with this wallet';

  @override
  String deskOvNodeUrl(String url) {
    return 'Node: $url';
  }

  @override
  String get deskOvUsePublicNode => 'Use public node';

  @override
  String get deskOvUseLocalNode => 'Use local node';

  @override
  String get deskOvHide => 'Hide';

  @override
  String deskOvCantReachNode(String url) {
    return 'Can’t reach the node at $url';
  }

  @override
  String get deskOvCantReachNodeText =>
      'Check that it is running and reachable. Balances may be out of date and sending is paused.';

  @override
  String get deskOvStarting => 'Starting';

  @override
  String get deskOvStartNode => 'Start node';

  @override
  String get deskOvNodeSettings => 'Node settings';

  @override
  String get deskOvTitle => 'Overview';

  @override
  String get deskOvShowAmounts => 'Show amounts';

  @override
  String get deskOvHideAmounts => 'Hide amounts';

  @override
  String get deskOvRefresh => 'Refresh';

  @override
  String get deskOvStepDone => 'done';

  @override
  String get deskOvStepNow => 'in progress';

  @override
  String get deskOvStepWait => 'pending';

  @override
  String deskOvStepSemantics(String text, String state) {
    return '$text, $state';
  }

  @override
  String get deskOvStartingUp => 'Starting up';

  @override
  String get deskOvStepUnlocked => 'Wallet unlocked';

  @override
  String get deskOvStepConnected => 'Connected to node';

  @override
  String get deskOvStepUpdating => 'Updating balances';

  @override
  String get deskOvStepEpicbox => 'Starting Epicbox receiving';

  @override
  String deskOvSyncTitle(int percent) {
    return 'Node syncing: $percent%';
  }

  @override
  String deskOvSyncText(String block) {
    return 'Downloading blocks. Balances are what the wallet knew at block $block. Sending opens when the node has caught up.';
  }

  @override
  String get deskOvSyncProgress => 'Node sync progress';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent% of the chain';
  }

  @override
  String get deskOvReceiveEpic => 'Receive EPIC';

  @override
  String get deskOvSend => 'Send';

  @override
  String get deskOvReceive => 'Receive';

  @override
  String get deskOvSendWaits => 'Sending opens when the node is synced.';

  @override
  String get deskOvAvailable => 'Available to spend';

  @override
  String deskOvAsOfBlock(String block) {
    return 'As of block $block';
  }

  @override
  String get deskOvEmptyHint =>
      'Share the Epicbox address to receive the first EPIC.';

  @override
  String get deskOvFiatNote => '  whole balance, CoinGecko';

  @override
  String get deskOvBreakTotal => 'Total';

  @override
  String get deskOvBreakConfirming => 'Confirming';

  @override
  String get deskOvBreakImmature => 'Immature';

  @override
  String get deskOvBreakAwaiting => 'Awaiting finalization';

  @override
  String get deskOvBreakLocked => 'Locked in sends';

  @override
  String get deskOvUpdating => 'Updating';

  @override
  String get deskOvHiddenAmount => 'Hidden amount';

  @override
  String get deskOvLoading => 'Loading transactions';

  @override
  String get deskOvEmptyTitle => 'No transactions yet';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Received EPIC shows here first as confirming, then as spendable after $blocks blocks.',
      one:
          'Received EPIC shows here first as confirming, then as spendable after $blocks block.',
    );
    return '$_temp0';
  }

  @override
  String get deskOvShowAddress => 'Show address';

  @override
  String get deskOvReceiveFile => 'Receive a file';

  @override
  String get deskOvRecent => 'Recent activity';

  @override
  String deskOvViewAll(int count) {
    return 'View all $count';
  }

  @override
  String deskOvPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file sends open',
      one: '$count file send open',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText =>
      'Finalize with the response file from the recipient.';

  @override
  String get deskOvFinalize => 'Finalize';

  @override
  String get deskTxMethodFile => 'Direct · File';

  @override
  String get deskTxMiningReward => 'Mining reward';

  @override
  String get deskTxReceived => 'Received';

  @override
  String get deskTxSent => 'Sent';

  @override
  String get deskTxUnknownSender => 'Unknown sender';

  @override
  String get deskTxUnknownRecipient => 'Unknown recipient';

  @override
  String get deskTxNoteBlock => 'Block time. The sender is not recorded.';

  @override
  String get deskTxNoteScanTime =>
      'Time of the scan; the block\'s time could not be read. The sender is not recorded.';

  @override
  String get deskTxNoteUnknown => 'The sender is not recorded.';

  @override
  String get deskTxFoundRestoredLabel => 'Restored';

  @override
  String get deskTxFoundRestoredLine => 'Found while restoring';

  @override
  String get deskTxFoundRestoredStep => 'Found while restoring this wallet';

  @override
  String get deskTxFoundRestoredTip =>
      'Found on the chain while restoring this wallet. The sender is not recorded.';

  @override
  String get deskTxFoundRescanLabel => 'Found by scan';

  @override
  String get deskTxFoundRescanLine => 'Found by a balance recheck';

  @override
  String get deskTxFoundRescanStep => 'Found by a balance recheck';

  @override
  String get deskTxFoundRescanTip =>
      'Found on the chain by a balance recheck. The sender is not recorded.';

  @override
  String get deskTxFoundScanLine => 'Found by a scan';

  @override
  String get deskTxFoundScanStep => 'Found by a scan';

  @override
  String get deskTxFoundScanTip =>
      'Found on the chain by a scan. The sender is not recorded.';

  @override
  String get deskTxBackupTip => 'Added from a history backup.';

  @override
  String get deskTxFromBackup => 'From backup';

  @override
  String get deskTxStatusImmature => 'Immature';

  @override
  String get deskTxStatusWaitingSender => 'Waiting for sender to finalize';

  @override
  String get deskTxStatusWaitingResponseFile => 'Waiting for the response file';

  @override
  String get deskTxStatusWaitingRecipient => 'Waiting for recipient to sign';

  @override
  String get deskTxStatusWaitingBlock => 'Waiting for a block';

  @override
  String deskTxStatusConfirming(int confirmations, int needed) {
    return 'Confirming $confirmations/$needed';
  }

  @override
  String get deskTxStatusCancelled => 'Cancelled';

  @override
  String get deskTxToday => 'today';

  @override
  String get deskTxYesterday => 'yesterday';

  @override
  String deskTxDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String deskTxTodayAt(String time) {
    return 'Today $time';
  }

  @override
  String deskTxDayToday(String date) {
    return 'Today · $date';
  }

  @override
  String deskTxDayYesterday(String date) {
    return 'Yesterday · $date';
  }

  @override
  String deskTxFee(String amount) {
    return 'Fee $amount';
  }

  @override
  String get deskTxPaymentProof => 'Payment proof';

  @override
  String get deskTxFinalize => 'Finalize';

  @override
  String deskTxSemReceived(String amount, String who, String status) {
    return 'Received $amount, $who, $status';
  }

  @override
  String deskTxSemSent(String amount, String who, String status) {
    return 'Sent $amount, $who, $status';
  }

  @override
  String deskTxSemKind(String kind, String amount, String who, String status) {
    return '$kind $amount, $who, $status';
  }

  @override
  String get deskTxHiddenAmount => 'hidden amount';

  @override
  String get deskTxNowBackup => 'From backup; the chain was not asked.';

  @override
  String deskTxNowImmature(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Confirmed, but a mining reward is spendable only after $count confirmations.',
      one:
          'Confirmed, but a mining reward is spendable only after $count confirmation.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Signed and returned. Waiting for the sender to finalize.';

  @override
  String get deskTxNowWaitingResponseFile =>
      'Waiting for the response file. Finalize when it arrives.';

  @override
  String get deskTxNowWaitingRecipient =>
      'Waiting for the recipient to sign. Nothing leaves the wallet until it is finalized.';

  @override
  String get deskTxNowPosted => 'Posted to the network, waiting for a block.';

  @override
  String deskTxNowConfirming(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'In a block, $confirmations of $needed confirmations.',
      one: 'In a block, $confirmations of $needed confirmation.',
    );
    return '$_temp0';
  }

  @override
  String deskTxNowConfirmed(int confirmations) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Confirmed, $confirmations confirmations.',
      one: 'Confirmed, $confirmations confirmation.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Cancelled.';

  @override
  String get deskTxNotCancelled => 'Not cancelled';

  @override
  String get deskTxCancelled => 'Transaction cancelled';

  @override
  String get deskTxCancelling => 'Cancelling';

  @override
  String get deskTxHeadRestored => 'restored';

  @override
  String get deskTxHeadFoundOnChain => 'found on the chain';

  @override
  String get deskTxHeadBackup => 'added from a history backup';

  @override
  String deskTxHeadFrom(String who) {
    return 'from $who';
  }

  @override
  String deskTxHeadTo(String who) {
    return 'to $who';
  }

  @override
  String get deskTxSubProgress => 'Progress';

  @override
  String get deskTxSubDetails => 'Details';

  @override
  String get deskTxFactDate => 'Date';

  @override
  String get deskTxFactFrom => 'From';

  @override
  String get deskTxFactTo => 'To';

  @override
  String get deskTxCopyAddress => 'Copy address';

  @override
  String get deskTxFactMethod => 'Method';

  @override
  String get deskTxFactAmount => 'Amount';

  @override
  String get deskTxFactFee => 'Fee';

  @override
  String get deskTxFactTotal => 'Total';

  @override
  String get deskTxFactMessage => 'Message';

  @override
  String get deskTxSignedByRecipient => 'Signed by the recipient';

  @override
  String get deskTxProofView => 'View';

  @override
  String get deskTxTechTitle => 'Technical details';

  @override
  String get deskTxTechId => 'Id';

  @override
  String get deskTxTechSlate => 'Slate id';

  @override
  String get deskTxCopySlate => 'Copy slate id';

  @override
  String get deskTxTechHeight => 'Height';

  @override
  String get deskTxTechKernel => 'Kernel';

  @override
  String get deskTxTechConfirmed => 'Confirmed';

  @override
  String get deskTxTechCredited => 'Credited';

  @override
  String get deskTxTechDebited => 'Debited';

  @override
  String get deskTxTechStatus => 'Status';

  @override
  String get deskTxTechType => 'Type';

  @override
  String get deskTxStepMined => 'Mined in a block';

  @override
  String get deskTxStepSpendable => 'Spendable';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks to go',
      one: '$count block to go',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Received slate';

  @override
  String get deskTxStepCreated => 'Created and signed';

  @override
  String get deskTxStepSignedReturned => 'Signed and returned';

  @override
  String get deskTxStepWaitingFile => 'Waiting for the response file';

  @override
  String get deskTxStepWaitingRecipient => 'Waiting for the recipient';

  @override
  String get deskTxStepPosted => 'Posted to the network';

  @override
  String get deskTxStepConfirming => 'Confirming';

  @override
  String deskTxStepProgress(int confirmations, int needed) {
    return '$confirmations of $needed';
  }

  @override
  String get deskTxCancelIncomingTitle => 'Cancel this payment?';

  @override
  String get deskTxCancelOutgoingTitle => 'Cancel this send?';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '$amount EPIC from $who leaves your balance. The wallet asks the node first and refuses if the payment is already in the node’s pool or a block. If the sender posts it later, it may still arrive.';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC to $who. The locked amount returns to the balance. If the recipient already finalized it, it may still confirm.';
  }

  @override
  String get deskTxCancelKeep => 'Keep';

  @override
  String get deskTxCancelIncomingAction => 'Cancel payment';

  @override
  String get deskTxCancelOutgoingAction => 'Cancel send';

  @override
  String deskTxProofIncoming(String amount) {
    return 'Proves that this wallet received $amount EPIC in this kernel.';
  }

  @override
  String deskTxProofOutgoing(String amount) {
    return 'Proves that the recipient received $amount EPIC in this kernel.';
  }

  @override
  String get deskTxProofSenderAddress => 'Sender address';

  @override
  String get deskTxProofRecipientAddress => 'Recipient address';

  @override
  String get deskTxProofRecipientSignature => 'Recipient signature';

  @override
  String get deskTxProofCopyKernel => 'Copy kernel';

  @override
  String get deskTxProofCopySender => 'Copy sender address';

  @override
  String get deskTxProofCopyRecipient => 'Copy recipient address';

  @override
  String get deskTxProofCopySignature => 'Copy recipient signature';

  @override
  String get deskTxProofExport => 'Export';

  @override
  String get deskTxProofSaved => 'Proof saved';

  @override
  String get deskOnbWelcomeAdd => 'Add a wallet';

  @override
  String get deskOnbWelcomeTagline =>
      'Keys and coins stay on this computer, locked with a password.';

  @override
  String get deskOnbWelcomeCreate => 'Create a new wallet';

  @override
  String get deskOnbWelcomeCreateSub => 'New recovery phrase';

  @override
  String get deskOnbWelcomeImport => 'Import wallets';

  @override
  String get deskOnbWelcomeImportSub => 'From an older Epic Wallet or a folder';

  @override
  String get deskOnbWelcomeRestore => 'Restore from a phrase';

  @override
  String get deskOnbWelcomeRestoreSub => 'From the recovery words';

  @override
  String get deskOnbWelcomeTestNote =>
      'New wallets are made on this test network.';

  @override
  String get deskOnbWelcomeBack => 'Back to unlock';

  @override
  String get deskOnbWelcomeAdvanced => 'Network and folder';

  @override
  String get deskOnbWelcomeNetwork => 'Network';

  @override
  String get deskOnbWelcomeNetworkHelp =>
      'Mainnet holds real EPIC. Floonet and Usernet are test networks.';

  @override
  String get deskOnbWelcomeFolder => 'App data folder';

  @override
  String get deskOnbWelcomeHideDetails => 'Hide details';

  @override
  String get deskOnbWelcomeMoreAbout => 'More about this';

  @override
  String get deskOnbWelcomeFolderWhere =>
      'Where the app keeps wallets and settings.';

  @override
  String get deskOnbWelcomeFolderDetail =>
      'With the local node, the blockchain is kept here too. A new folder must be empty: the app makes its folders there and keeps using it.';

  @override
  String deskOnbWelcomeUsing(String folder) {
    return 'Using $folder. The app restarts to use it.';
  }

  @override
  String get deskOnbWelcomeLocked =>
      'It can be changed only before the first wallet is added.';

  @override
  String get deskOnbWelcomeChooseFolder => 'Choose a folder';

  @override
  String get deskOnbWelcomeDefaultFolder => 'Default folder';

  @override
  String get deskOnbWelcomeFolderNotEmpty =>
      'That folder is not empty. Choose a new, empty folder.';

  @override
  String get deskOnbWelcomeFolderIsWallet =>
      'That is a wallet folder. Choose a new, empty folder.';

  @override
  String get deskOnbWelcomeChoose => 'Choose';

  @override
  String get deskOnbStepPassword => 'Password';

  @override
  String get deskOnbStepPhrase => 'Recovery phrase';

  @override
  String get deskOnbCreateStageCreate =>
      'Creating the wallet and its recovery phrase';

  @override
  String get deskOnbCreateStageSave => 'Saving the account';

  @override
  String get deskOnbCreateNotCreated => 'Wallet not created';

  @override
  String get deskOnbCreateCreating => 'Creating the wallet';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'A wallet on $network, a test network.';
  }

  @override
  String get deskOnbCreateFailedTitle => 'The wallet could not be created';

  @override
  String get deskOnbCreateDiskFull =>
      'The account could not be saved: the disk is full.';

  @override
  String get deskOnbCreateWait =>
      'This can take up to a minute. Keep the app open.';

  @override
  String get deskOnbCreateLocking => 'Locking the open wallet';

  @override
  String get deskOnbCreateSide => 'New wallet';

  @override
  String get deskOnbCreateTitle => 'Create wallet';

  @override
  String get deskOnbCreateLead =>
      'The password unlocks this wallet on this computer. It cannot recover coins; the phrase on the next step does.';

  @override
  String get deskOnbCreateTestNote =>
      'A wallet on a test network, not for real EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'These words are the only way to get the coins back if this computer breaks. Write them on paper, in order.';

  @override
  String get deskOnbCreateRevealFirst => 'Reveal the phrase first';

  @override
  String get deskOnbCreateWarn => 'Anyone with these words can take the coins';

  @override
  String get deskOnbCreateReveal => 'Reveal phrase';

  @override
  String get deskOnbCreateCheckScreen =>
      'Check that nobody can see the screen.';

  @override
  String get deskOnbCreateHide => 'Hide';

  @override
  String get deskOnbCreateShowQr => 'Show QR code';

  @override
  String get deskOnbCreateHideQr => 'Hide QR code';

  @override
  String get deskOnbCreateQrWarn =>
      'Anyone who scans this code can take the coins';

  @override
  String get deskOnbCreateQrWarnText =>
      'Scan it only into another wallet you trust.';

  @override
  String get deskOnbCreateQrLabel => 'Recovery phrase as a QR code';

  @override
  String deskOnbCreateWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '$count word',
    );
    return 'Written down: all $_temp0 on paper';
  }

  @override
  String get deskOnbRestoreDone => 'Wallet restored.';

  @override
  String get deskOnbRestoreNotRestored => 'Wallet not restored';

  @override
  String get deskOnbRestoreRestoring => 'Restoring the wallet';

  @override
  String get deskOnbRestoreFailedTitle => 'The wallet could not be restored';

  @override
  String get deskOnbRestorePermission =>
      'The wallet files could not be written: permission denied in ~/.config/Epic Cash Desktop.';

  @override
  String get deskOnbRestoreWait =>
      'This can take up to a minute. The balance appears after the first scan of the chain.';

  @override
  String get deskOnbRestoreSide => 'Restore wallet';

  @override
  String get deskOnbRestoreChoosePassword => 'Choose a password';

  @override
  String deskOnbRestorePasswordLead(int count) {
    return 'The $count-word phrase checks out. Set the password that unlocks this wallet on this computer. The wallet opens when it is restored.';
  }

  @override
  String get deskOnbRestoreNothingToPaste =>
      'Nothing to paste: the clipboard holds no words.';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return 'Word $position, \"$word\", is not in the word list.';
  }

  @override
  String deskOnbRestoreAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count words check out.',
      one: 'All $count word checks out.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreStaysHere =>
      'The phrase never leaves this computer.';

  @override
  String get deskOnbRestoreChecksumFirm =>
      'This phrase\'s check number does not match. Compare every word with the paper.';

  @override
  String deskOnbRestoreChecksumSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count words so far; the check number does not match. Keep typing, or compare every word with the paper.',
      one:
          '$count word so far; the check number does not match. Keep typing, or compare every word with the paper.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWordsLead =>
      'Type the words in order, or paste the whole phrase into any box. Line breaks, commas and numbering are ignored.';

  @override
  String get deskOnbRestoreClear => 'Clear';

  @override
  String deskOnbRestoreUseWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use $count words',
      one: 'Use $count word',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWords => 'Words';

  @override
  String deskOnbRestoreFilledOf(int filled, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total words',
      one: '$total word',
    );
    return '$filled of $_temp0';
  }

  @override
  String get deskOnbKillTitle => 'Epic is already running';

  @override
  String get deskOnbKillBody =>
      'Another wallet or node process is using the wallet files and ports. Close it to unlock here, or cancel and close it yourself.';

  @override
  String get deskOnbKillProcesses => 'Running processes';

  @override
  String get deskOnbKillRoleWallet => 'wallet service';

  @override
  String get deskOnbKillRoleNode => 'node';

  @override
  String get deskOnbKillNote =>
      'Closing them stops what they were doing, such as a node sync or receiving payments. They start again from this app after unlock.';

  @override
  String get deskOnbKillClosing => 'Closing…';

  @override
  String get deskOnbKillClose => 'Close and unlock';

  @override
  String get deskOnbSameTitle => 'This wallet is already here';

  @override
  String get deskOnbSameBody =>
      'The phrase belongs to a wallet in the list. Nothing was added.';

  @override
  String get deskOnbSameWallet => 'Wallet';

  @override
  String get deskOnbSameNote =>
      'Open it asks for that wallet\'s password. Cancel keeps the phrase on the grid.';

  @override
  String get deskOnbSameOpen => 'Open it';

  @override
  String get deskOnbUnlockWhoWindows =>
      'Anyone using this Windows account can open this wallet.';

  @override
  String get deskOnbUnlockWho =>
      'Anyone using this account can open this wallet.';

  @override
  String get deskOnbUnlockWrong =>
      'Wrong password. Check Caps Lock and the keyboard layout.';

  @override
  String get deskOnbUnlockPortInUse =>
      'The wallet service did not start: port 3415 is in use by another program.';

  @override
  String get deskOnbUnlockStageCheck => 'Checking wallet files';

  @override
  String get deskOnbUnlockStageProcesses =>
      'Looking for wallet processes still running';

  @override
  String get deskOnbUnlockStageClosing => 'Closing the old wallet processes';

  @override
  String get deskOnbUnlockStageWallet => 'Starting the wallet service';

  @override
  String get deskOnbUnlockStageUnlock => 'Unlocking the wallet';

  @override
  String get deskOnbUnlockEnter => 'Enter the password';

  @override
  String get deskOnbUnlockCloseOthers =>
      'Close the other Epic processes, then unlock.';

  @override
  String get deskOnbUnlockRememberedUnavailable =>
      'Remembered password unavailable. Enter the password.';

  @override
  String get deskOnbUnlockRememberedForgotten =>
      'The remembered password was forgotten. Enter the password.';

  @override
  String get deskOnbUnlockNotRemembered => 'Not remembered';

  @override
  String get deskOnbUnlockKeyStore =>
      'This computer\'s key store is unavailable.';

  @override
  String get deskOnbUnlockThisWallet => 'this wallet';

  @override
  String get deskOnbUnlockFailed => 'Unlock failed';

  @override
  String get deskOnbUnlockFailedLead =>
      'The wallet did not open. The reason is below.';

  @override
  String get deskOnbUnlockFailedBox => 'The wallet did not open';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'Unlocking $name';
  }

  @override
  String get deskOnbUnlockStepsLead => 'Each step shows as it finishes.';

  @override
  String get deskOnbUnlockNote =>
      'Then the overview opens and finishes in the background: connecting to the node, updating balances, turning on receiving.';

  @override
  String get deskOnbUnlockTitle => 'Unlock wallet';

  @override
  String get deskOnbUnlockLead => 'Keys stay on this computer.';

  @override
  String get deskOnbUnlockRemember => 'Remember on this computer';

  @override
  String deskOnbUnlockRememberFor(String who) {
    return 'For 30 days. $who';
  }

  @override
  String get deskOnbUnlockMissingTitle => 'This wallet’s folder is missing';

  @override
  String deskOnbUnlockMissingText(String folder) {
    return 'It was at $folder';
  }

  @override
  String get deskOnbUnlockRemove => 'Remove';

  @override
  String get deskOnbUnlockTryAgain => 'Try again';

  @override
  String get deskOnbUnlockButton => 'Unlock';

  @override
  String get deskOnbNodeFreeUnknown => 'free space unknown';

  @override
  String deskOnbNodeFreeHere(String size) {
    return '$size free here';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'About $size of disk now';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return '$size of disk now';
  }

  @override
  String get deskOnbNodeSeparate => 'A separate program.';

  @override
  String get deskOnbNodeSeparateText =>
      'The wallet starts the Epic node and stops it with the app.';

  @override
  String get deskOnbNodeFirewall => 'Windows asks once';

  @override
  String get deskOnbNodeFirewallText =>
      'to allow it through the firewall. Allow it on private networks.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'growing slowly. $free.';
  }

  @override
  String get deskOnbNodeHours => 'Hours to sync';

  @override
  String get deskOnbNodeHoursText =>
      'the first time, 2 to 6 on a typical connection. The wallet shows the progress and can use a public node meanwhile.';

  @override
  String get deskOnbNodeDownload => 'About 4 GB downloaded';

  @override
  String get deskOnbNodeDownloadText =>
      'the first time, then a little every day.';

  @override
  String get deskOnbNodeFound => 'Found';

  @override
  String deskOnbNodeFoundAt(String version, String address) {
    return 'Epic $version at $address';
  }

  @override
  String deskOnbNodeHeight(String height) {
    return 'height $height';
  }

  @override
  String get deskOnbNodeSynced => 'synced';

  @override
  String get deskOnbNodeNoAnswer => 'No node answers';

  @override
  String deskOnbNodeNoAnswerAt(String address) {
    return 'at $address. Start it, or check the address and port.';
  }

  @override
  String get deskOnbNodeExisting =>
      'Use a node already running on this computer';

  @override
  String get deskOnbNodeExistingText =>
      'The Epic GUI or CLI node. The wallet connects to it and starts nothing.';

  @override
  String get deskOnbNodeAddress => 'Address of the node on this computer';

  @override
  String get deskOnbNodeCheck => 'Check';

  @override
  String get deskOnbNodeBundled => 'Start the bundled node';

  @override
  String get deskOnbNodeBundledText =>
      'Downloads and syncs the chain into the wallet’s own folder. Nothing is downloaded before Save on the last step.';

  @override
  String deskOnbNodeFallback(String host) {
    return 'Use $host until the local node is synced. The local node takes over by itself.';
  }

  @override
  String get deskOnbNodeDialogTitle => 'Local node';

  @override
  String get deskOnbNodeDialogBody =>
      'What running the node here means, and which node to use.';

  @override
  String get deskOnbNodeUseThis => 'Use this node';

  @override
  String get deskOnbNodeStart => 'Start local node';

  @override
  String deskOnbRestorePasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words pasted; a phrase has 12, 15, 18, 21 or 24',
      one: '$count word pasted; a phrase has 12, 15, 18, 21 or 24',
    );
    return '$_temp0';
  }

  @override
  String deskOnbWordN(int number) {
    return 'Word $number';
  }

  @override
  String get deskOnbImportEnterOld => 'Enter the old password';

  @override
  String deskOnbImportNewShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '$count character',
    );
    return 'New password: at least $_temp0';
  }

  @override
  String get deskOnbImportNewDiffer => 'The new passwords differ';

  @override
  String deskOnbImportWalletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '$count wallet',
    );
    return '$_temp0';
  }

  @override
  String deskOnbImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets imported.',
      one: 'Wallet imported.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFindingTitle => 'Finding wallets';

  @override
  String get deskOnbImportFindingLead =>
      'Searching the folders of older Epic Wallet versions and the epic program. Nothing is changed.';

  @override
  String deskOnbImportFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets found',
      one: '$count wallet found',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFoundLead => 'Old folders are only read.';

  @override
  String get deskOnbImportNoneTitle => 'No wallets found';

  @override
  String get deskOnbImportNoneLead =>
      'Choose the wallet folder, or restore from the recovery phrase.';

  @override
  String get deskOnbImportChooseTitle => 'Choose wallets';

  @override
  String get deskOnbImportChooseLead =>
      'Ticked wallets are added to the app. History is rebuilt by a scan.';

  @override
  String get deskOnbImportCheckTitle => 'Checking for use';

  @override
  String get deskOnbImportCheckLead =>
      'A wallet in use by another program is not imported.';

  @override
  String get deskOnbImportTitle => 'Import';

  @override
  String get deskOnbImportLead => 'Each wallet asks for its old password once.';

  @override
  String get deskOnbImportDoneTitle => 'Wallets imported';

  @override
  String get deskOnbImportDoneLead =>
      'The first unlock of each wallet scans the chain for its history.';

  @override
  String deskOnbImportSelected(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get deskOnbImportChecking => 'Checking…';

  @override
  String get deskOnbImportCloseOther =>
      'Close the other program or skip the wallet';

  @override
  String deskOnbImportImportedOf(int done, int total) {
    return '$done of $total imported';
  }

  @override
  String get deskOnbImportOpen => 'Open wallet';

  @override
  String get deskOnbImportStepFind => 'Find';

  @override
  String get deskOnbImportStepChoose => 'Choose';

  @override
  String get deskOnbImportStepCheck => 'Check';

  @override
  String get deskOnbImportBack => 'Back';

  @override
  String get deskOnbImportSkip => 'Skip';

  @override
  String get deskOnbImportOlder => 'Older Epic Wallet';

  @override
  String get deskOnbImportOlderSub => 'Accounts and folders';

  @override
  String get deskOnbImportEpicProgram => 'The epic program';

  @override
  String get deskOnbImportSearching => 'Searching…';

  @override
  String get deskOnbImportRestore => 'Restore from phrase';

  @override
  String deskOnbImportLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String deskOnbImportSecondCopy(String reason) {
    return '$reason. Tick for a second copy.';
  }

  @override
  String deskOnbImportCannot(String name) {
    return '$name: cannot be imported';
  }

  @override
  String get deskOnbImportInApp => 'In the app';

  @override
  String get deskOnbImportSameWallet => 'Same wallet';

  @override
  String get deskOnbImportNotInUse => 'Not in use';

  @override
  String get deskOnbImportNotChecked => 'Not checked';

  @override
  String get deskOnbImportSkipped => 'Skipped';

  @override
  String get deskOnbImportInUse => 'In use';

  @override
  String get deskOnbImportInUseText =>
      'In use by another program. Close the older Epic Wallet or the epic program, then check again.';

  @override
  String get deskOnbImportCheckAgain => 'Check again';

  @override
  String get deskOnbImportImported => 'Imported';

  @override
  String get deskOnbImportImporting => 'Importing…';

  @override
  String get deskOnbImportWaiting => 'Waiting';

  @override
  String get deskOnbImportOldPassword => 'Old password';

  @override
  String deskOnbImportOldHelp(String name) {
    return 'The password of $name in the older app.';
  }

  @override
  String deskOnbImportOldOf(String name) {
    return 'Old password of $name';
  }

  @override
  String deskOnbImportOldShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count or more characters.',
      one: '$count or more characters.',
    );
    return 'The old password is short. Choose a new one, $_temp0';
  }

  @override
  String get deskOnbImportNewPassword => 'New password';

  @override
  String get deskOnbImportRepeat => 'Repeat';

  @override
  String get deskOnbImportRepeatNew => 'Repeat the new password';

  @override
  String get deskOnbImportUnchanged =>
      'Old folders are unchanged. The older app can still open them.';

  @override
  String get deskOnbImportStopTitle => 'Stop the import?';

  @override
  String get deskOnbImportStopBody =>
      'Wallets imported so far are removed. Old folders are unchanged.';

  @override
  String get deskOnbImportGoBack => 'Go back';

  @override
  String get deskOnbImportStop => 'Stop import';

  @override
  String get deskRailWaitingTor => 'Waiting for Tor';

  @override
  String get deskRailOn => 'On';

  @override
  String get deskRailConnecting => 'Connecting';

  @override
  String get deskRailSlow => 'Slow';

  @override
  String get deskRailNotAnswering => 'Not answering';

  @override
  String get deskRailOff => 'Off';

  @override
  String get deskRailChecking => 'Checking';

  @override
  String get deskRailOverTor => 'Over Tor';

  @override
  String get deskRailWaitsForTor => 'Waits until Tor is connected.';

  @override
  String get deskRailPaymentsWait => 'Payments wait on the Epicbox server.';

  @override
  String get deskRailOpenEpicbox => 'Open Epicbox receiving';

  @override
  String get deskRailStarting => 'Starting';

  @override
  String get deskRailNotReceiving => 'Not receiving';

  @override
  String get deskRailOnInternet => 'On · internet';

  @override
  String get deskRailOnLocal => 'On · local';

  @override
  String get deskRailPortInUse => 'Port in use';

  @override
  String get deskRailStopped => 'Stopped';

  @override
  String deskRailPortInternet(String port) {
    return 'Port $port · from the internet';
  }

  @override
  String deskRailPortLocal(String port) {
    return 'Port $port · this computer only';
  }

  @override
  String get deskRailOpenHttp => 'Open Link · HTTP receiving';

  @override
  String get deskRailTorNotInBuild => 'Not in this build';

  @override
  String get deskRailStartingDots => 'Starting…';

  @override
  String deskRailTorSlow(String problem) {
    return '$problem. Sends work.';
  }

  @override
  String get deskRailTorNoAddress => 'Tor address not published';

  @override
  String get deskRailOpenPrivacy => 'Open Privacy settings';

  @override
  String get deskRailNode => 'Node';

  @override
  String get deskRailOpenNode => 'Open node settings';

  @override
  String get deskAppNodeSyncedTitle => 'Local node synced';

  @override
  String get deskAppNodeSyncedBody =>
      'The local node has the whole chain and can be used now. The app restarts to switch to it.';

  @override
  String get deskAppNotNow => 'Not now';

  @override
  String get deskAppRestartNow => 'Restart now';

  @override
  String get deskAppFirstScanTitle => 'Wallet first scan';

  @override
  String get deskAppFirstScanBody =>
      'The wallet looks through the chain for its outputs. It stays usable; the balance updates when the scan is done.';

  @override
  String get deskAppScanOutput => 'Scan output';

  @override
  String get deskAppWaitingOutput => 'Waiting for the first output…';

  @override
  String get deskShellNavOverview => 'Overview';

  @override
  String get deskShellNavActivity => 'Activity';

  @override
  String get deskShellNavSend => 'Send';

  @override
  String get deskShellNavReceive => 'Receive';

  @override
  String get deskShellNavOutputs => 'Outputs';

  @override
  String get deskShellNavContacts => 'Contacts';

  @override
  String get deskShellNavSettings => 'Settings';

  @override
  String get deskShellTitleImportTx => 'Import transaction';

  @override
  String get deskShellTitleFinalizeTx => 'Finalize transaction';

  @override
  String get deskShellLocksAfterSend => 'Locks when the payment is sent';

  @override
  String get deskShellNotQuitTitle => 'Not quit';

  @override
  String get deskShellNotQuitBody =>
      'A send is in progress. Quit again once it finishes.';

  @override
  String get deskShellLockedTitle => 'Wallet locked';

  @override
  String get deskShellLockedBody =>
      'Quit closes the app once the wallet core is connected.';

  @override
  String deskShellLockWallet(String keys) {
    return 'Lock wallet ($keys)';
  }

  @override
  String get deskShellMainNav => 'Main navigation';

  @override
  String deskShellVersion(String version) {
    return 'Version $version';
  }

  @override
  String get deskShellOpenWalletSettings => 'Open wallet settings';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Open wallet settings: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Switch wallet';

  @override
  String deskShellWalletBy(String maker) {
    return 'Wallet by $maker';
  }

  @override
  String get deskTourOverviewTitle => 'Overview';

  @override
  String get deskTourOverviewText =>
      'The balance and what is still confirming, then the latest transactions. Everything else is in the sidebar.';

  @override
  String get deskTourSendTitle => 'Send';

  @override
  String get deskTourSendText =>
      'Pay an Epicbox address, or make a transaction file for someone to sign. A review comes before anything leaves.';

  @override
  String get deskTourReceiveTitle => 'Receive';

  @override
  String get deskTourReceiveText =>
      'This wallet’s Epicbox address: share it to be paid. Transaction files to sign or finalize are below it.';

  @override
  String get deskTourInvoicesTitle => 'Invoices';

  @override
  String get deskTourInvoicesText =>
      'Pay an invoice someone sent, or issue one to someone who owes you. The tabs switch between the two.';

  @override
  String get deskTourActivityTitle => 'Activity';

  @override
  String get deskTourActivityText =>
      'Every transaction with its progress and details. A number on this sidebar entry means something waits for an action.';

  @override
  String get deskTourContactsTitle => 'Contacts';

  @override
  String get deskTourContactsText =>
      'Saved addresses by name. Send picks from here.';

  @override
  String get deskTourNodeTitle => 'Settings › Node';

  @override
  String get deskTourNodeText =>
      'Which node the wallet reads the chain from. The other settings pages are listed on the left.';

  @override
  String get deskTourHelpTitle => 'Help';

  @override
  String get deskTourHelpText =>
      'Topics by section and Report a problem. More on every page is here, and this tour can be shown again.';

  @override
  String deskTourCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get deskTourSemantics => 'Tour of the wallet';

  @override
  String get deskTourSkip => 'Skip tour';

  @override
  String get deskTourBack => 'Back';

  @override
  String get deskTourNext => 'Next';

  @override
  String get deskKitUnknown => 'Unknown';

  @override
  String get deskKitRingCancelled => 'Cancelled';

  @override
  String get deskKitRingConfirmed => 'Confirmed';

  @override
  String deskKitRingProgress(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '$confirmations of $needed confirmations',
      one: '$confirmations of $needed confirmation',
    );
    return '$_temp0';
  }

  @override
  String get deskKitHiddenAmount => 'Hidden amount';

  @override
  String get deskKitChooseFile => 'Choose file';

  @override
  String deskKitNeedAction(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need action',
      one: '$count needs action',
    );
    return '$label, $_temp0';
  }

  @override
  String get deskKitHealthOn => 'On';

  @override
  String get deskKitHealthSlow => 'Slow';

  @override
  String get deskKitHealthOffline => 'Offline';

  @override
  String get deskKitHealthOff => 'Off';

  @override
  String get deskKitHealthChecking => 'Checking';

  @override
  String get deskKitCloseEsc => 'Close (Esc)';

  @override
  String get deskKitOptional => 'Optional';

  @override
  String get deskKitBackAlt => 'Back (Alt+Left)';

  @override
  String deskKitStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get deskKitHeroCaptionEpicbox => 'EPICBOX SERVER HOLDS IT';

  @override
  String get deskKitHeroCaptionHttp => 'STRAIGHT TO THEIR WALLET';

  @override
  String get deskKitHeroCaptionTor => 'STRAIGHT, THROUGH TOR';

  @override
  String get deskKitHeroCaptionFile => 'FILE OUT, RESPONSE BACK';

  @override
  String get deskKitHeroLabelEpicbox =>
      'Epicbox: the payment goes to the Epicbox server, which holds it until the recipient\'s wallet is back';

  @override
  String get deskKitHeroLabelHttp =>
      'Link · HTTP: the payment goes straight to the recipient\'s wallet, which must be open';

  @override
  String get deskKitHeroLabelTor =>
      'Link · Tor: the payment goes straight to the recipient\'s wallet, routed through the Tor network';

  @override
  String get deskKitHeroLabelFile =>
      'Direct · File Transfer: a transaction file is handed over, a response file comes back, then the sender finalizes';

  @override
  String get deskKitReachCheck => 'Check';

  @override
  String get deskKitReachChecking => 'Checking from the internet…';

  @override
  String get deskKitReachNoIpTitle => 'Public IP not found';

  @override
  String get deskKitReachNoIpText =>
      'The internet could not be asked for it. Try again later.';

  @override
  String deskKitReachNoIpTextLan(String address) {
    return 'The internet could not be asked for it. Try again later. On your network: $address.';
  }

  @override
  String get deskKitReachClosedTitle => 'Not reachable from the internet';

  @override
  String deskKitReachClosedText(String port) {
    return 'Forward TCP port $port on your router to this computer, then check again.';
  }

  @override
  String deskKitReachClosedTextLan(String port, String address) {
    return 'Forward TCP port $port on your router to this computer ($address), then check again.';
  }

  @override
  String get deskKitReachUnknownTitle => 'Reachability unknown';

  @override
  String get deskKitReachUnknownText =>
      'The port check did not answer. Try again later.';

  @override
  String deskKitReachUnknownTextLan(String address) {
    return 'The port check did not answer. Try again later. On your network: $address.';
  }

  @override
  String get deskKitReachOpenTitle => 'Reachable from the internet';

  @override
  String deskKitReachOpenText(String port) {
    return 'Port $port is forwarded.';
  }

  @override
  String deskKitReachOpenTextLan(String port, String address) {
    return 'Port $port is forwarded. On your network: $address.';
  }

  @override
  String deskKitAgeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count s ago',
      one: '$count s ago',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '$count h ago',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d ago',
      one: '$count d ago',
    );
    return '$_temp0';
  }

  @override
  String get deskKitNodeBefore410 => 'node before 4.1.0';

  @override
  String get deskKitNodeNoAnswer => 'no answer';

  @override
  String get deskKitNodesDisagree => 'Nodes disagree on the tip';

  @override
  String deskKitNodesAgree(String height) {
    return 'Nodes agree on $height';
  }

  @override
  String deskKitNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up of $total nodes up',
      one: '$up of $total node up',
    );
    return '$_temp0';
  }

  @override
  String deskKitEpicboxUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up of $total Epicbox servers up',
      one: '$up of $total Epicbox server up',
    );
    return '$_temp0';
  }

  @override
  String deskKitLastBlock(String age) {
    return 'last block $age';
  }

  @override
  String get deskKitLimitedNetwork =>
      'status.btlabs.uk is not reachable. These facts come from the node itself: no tip to compare with, no uptime, no peer count.';

  @override
  String get deskKitFactHeight => 'Height';

  @override
  String get deskKitFactVersion => 'Version';

  @override
  String get deskKitFactAccepts => 'Accepts transactions';

  @override
  String get deskKitFactYes => 'Yes';

  @override
  String get deskKitFactNotYet => 'Not yet';

  @override
  String get deskKitFactUnknown => 'Unknown';

  @override
  String get deskKitFactLatency => 'Latency';

  @override
  String get deskKitFactUptime => 'Uptime';

  @override
  String get deskKitFactPeers => 'Peers';

  @override
  String get deskKitFactOperator => 'Operator';

  @override
  String get deskKitAtTip => 'at tip';

  @override
  String deskKitBehind(int count, String blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$blocks behind',
      one: '$blocks behind',
    );
    return '$_temp0';
  }

  @override
  String deskKitVersionOut(String version) {
    return '$version is out';
  }

  @override
  String get deskKitVersionLatest => 'latest';

  @override
  String get deskKitUptimeWindow => 'last 24 h';

  @override
  String deskKitAtTime(String time) {
    return 'at $time';
  }

  @override
  String get deskKitListedOfficial => 'listed as official';

  @override
  String deskKitSourceChecked(String time) {
    return 'status.btlabs.uk, checked $time';
  }

  @override
  String deskKitLatencyMeasured(String where) {
    return 'latency measured $where';
  }

  @override
  String deskKitSiteLastReached(String time) {
    return 'Status site last reached $time';
  }

  @override
  String deskKitSince(String time) {
    return 'since $time';
  }

  @override
  String deskKitNodeSemantics(String status, String host) {
    return 'Node $status: $host';
  }

  @override
  String get deskKitNodeDownTitle => 'Node not answering.';

  @override
  String deskKitNodeDownText(String host) {
    return 'Switch to $host, the healthiest other node?';
  }

  @override
  String get deskKitSwitch => 'Switch';

  @override
  String get deskKitLimitedInfo => 'Limited info';

  @override
  String get deskKitFromStatusSite => 'from status.btlabs.uk';

  @override
  String get deskKitOverTor => 'over Tor';

  @override
  String get deskKitFromThisComputer => 'from this computer';

  @override
  String deskKitNodeUse(String host) {
    return 'Use $host';
  }

  @override
  String deskKitNodeUseOperator(String host, String operator) {
    return 'Use $host, $operator';
  }

  @override
  String deskKitNodeUseDown(String host) {
    return 'Use $host, not answering';
  }

  @override
  String deskKitNodeUseOperatorDown(String host, String operator) {
    return 'Use $host, $operator, not answering';
  }

  @override
  String deskKitLocalNodeUse(String state) {
    return 'Use the local node, $state';
  }

  @override
  String get deskKitLocalNode => 'Local node';

  @override
  String get deskKitMethodWaitingTor => 'Waiting for Tor';

  @override
  String deskKitMethodTorNotConnected(String host) {
    return '$host. Tor is not connected.';
  }

  @override
  String get deskKitMethodOn => 'On';

  @override
  String deskKitMethodOverTor(String host) {
    return '$host, over Tor';
  }

  @override
  String get deskKitMethodOff => 'Off';

  @override
  String get deskKitMethodEpicboxOffDetail =>
      'Payments to this address wait on the Epicbox server.';

  @override
  String get deskKitMethodConnecting => 'Connecting';

  @override
  String get deskKitMethodSlow => 'Slow';

  @override
  String get deskKitMethodNotAnswering => 'Not answering';

  @override
  String deskKitMethodEpicboxDown(String host) {
    return '$host. Payments wait on the Epicbox server.';
  }

  @override
  String get deskKitMethodHttpOffDetail =>
      'Straight from another wallet while this one is open.';

  @override
  String get deskKitMethodStarting => 'Starting…';

  @override
  String deskKitMethodHttpInternet(String port) {
    return 'from the internet, port $port';
  }

  @override
  String get deskKitMethodHttpLocal => 'this computer only (127.0.0.1)';

  @override
  String get deskKitMethodNotReceiving => 'Not receiving';

  @override
  String deskKitMethodPortInUse(String port) {
    return 'Port $port is used by another program. Close it or pick another port in Settings.';
  }

  @override
  String get deskKitMethodNotInBuild => 'Not in this build';

  @override
  String get deskKitMethodTorOffDetail =>
      'Slower and more private. Blocked or not allowed in some countries.';

  @override
  String get deskKitMethodTorPublishing => 'Publishing the Tor address…';

  @override
  String get deskKitMethodTorConnecting => 'Connecting to Tor…';

  @override
  String get deskKitMethodTorOnDetail => 'reachable at the Tor address';

  @override
  String get deskKitMethodTorNotPublished => 'Not published';

  @override
  String deskKitMethodTorSendsWork(String reason) {
    return '$reason. Sends work.';
  }

  @override
  String get deskKitMethodTorNotReachableYet =>
      'The Tor address is not reachable yet';

  @override
  String get deskKitMethodTorStopped => 'Stopped';

  @override
  String get deskKitMethodTorStoppedDetail => 'Tor stopped.';

  @override
  String get deskKitMethodFiles => 'Direct · File Transfer';

  @override
  String get deskKitChipOverTor => 'Over Tor';

  @override
  String get deskKitChipStarting => 'Tor starting';

  @override
  String get deskKitChipNotConnected => 'Tor not connected';

  @override
  String get deskKitChipNotOverTor => 'Not over Tor';

  @override
  String get deskKitPasswordNote =>
      'Estimated on this device from the length and from common words, names and patterns, for an attacker with fast hardware trying 100,000 guesses a second against this wallet\'s file. A guide, not a guarantee.';

  @override
  String get deskKitPasswordNoteLabel => 'How the time is estimated';

  @override
  String get deskKitNotCopied => 'Not copied';

  @override
  String get deskKitCopied => 'Copied';

  @override
  String deskKitQrOf(String title) {
    return 'QR code of the $title';
  }

  @override
  String deskKitQrOfTag(String title, String tag) {
    return 'QR code of the $title, $tag';
  }

  @override
  String deskKitQrShowOf(String title) {
    return 'Show QR code of the $title';
  }

  @override
  String get deskKitQrShow => 'Show QR';

  @override
  String get deskKitQrHide => 'Hide QR';

  @override
  String get deskKitQrHideCode => 'Hide QR code';

  @override
  String get deskSetAcctNotForgotten => 'Not forgotten';

  @override
  String get deskSetAcctForgotten => 'Forgotten on this computer';

  @override
  String get deskSetAcctForgottenText => 'The next start asks the password.';

  @override
  String get deskSetAcctLabelNotSaved => 'Label not saved';

  @override
  String get deskSetAcctEnterLabel => 'Enter a label';

  @override
  String get deskSetAcctLabelSaved => 'Label saved';

  @override
  String get deskSetAcctLabel => 'Label';

  @override
  String get deskSetAcctLabelHint => 'Only shown in this app.';

  @override
  String get deskSetAcctSaveLabel => 'Save label';

  @override
  String get deskSetAcctPhraseHint =>
      'The words that restore this wallet. Keep them private.';

  @override
  String get deskSetAcctShowPhrase => 'Show phrase…';

  @override
  String get deskSetAcctRescanHint =>
      'Reads the chain again when the balance looks wrong.';

  @override
  String get deskSetAcctRecheck => 'Recheck…';

  @override
  String get deskSetAcctFiles => 'Files';

  @override
  String get deskSetAcctWalletFolder => 'Wallet folder';

  @override
  String get deskSetAcctAppFiles => 'App files';

  @override
  String get deskSetAcctAppFilesHint => 'Settings and the log.';

  @override
  String get deskSetAcctNetwork => 'Network';

  @override
  String get deskSetAcctNetworkHint => 'Set when the wallet was created.';

  @override
  String get deskSetAcctSetup => 'Setup assistant';

  @override
  String get deskSetAcctSetupHint =>
      'Walk through node and receiving again. Nothing is lost.';

  @override
  String get deskSetAcctRunSetup => 'Run setup…';

  @override
  String get deskSetAcctSecurity => 'Security';

  @override
  String get deskSetAcctRemembered => 'Remembered on this computer';

  @override
  String deskSetAcctRememberedHint(String who) {
    return 'Opens at start without the password, for 30 days from when it was set. Sends still ask the password. $who';
  }

  @override
  String get deskSetAcctForget => 'Forget this computer';

  @override
  String get deskSetAcctPasswordHint => 'Unlocks this wallet.';

  @override
  String get deskSetAcctChangePassword => 'Change password…';

  @override
  String get deskSetAcctDeleteHint => 'Deletes its keys and database.';

  @override
  String get deskSetAcctFolderNotFound => 'Folder not found';

  @override
  String deskSetAcctCopyPath(String title) {
    return 'Copy path: $title';
  }

  @override
  String deskSetBackupWhenToday(String time) {
    return 'today, $time';
  }

  @override
  String deskSetBackupWhenYesterday(String time) {
    return 'yesterday, $time';
  }

  @override
  String deskSetBackupWhenDate(String day, String time) {
    return '$day, $time';
  }

  @override
  String get deskSetBackupNeverExported => 'Never exported.';

  @override
  String deskSetBackupLastExportNothingNew(String when) {
    return 'Last export $when · nothing new since.';
  }

  @override
  String deskSetBackupLastExportSince(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments since',
      one: '1 payment since',
    );
    return 'Last export $when · $_temp0.';
  }

  @override
  String deskSetBackupWriteFailedHere(String reason) {
    return 'Could not write to the folder: $reason. Choose another folder.';
  }

  @override
  String deskSetBackupWriteFailedIn(String folder, String reason) {
    return 'Could not write to $folder: $reason. Choose another folder.';
  }

  @override
  String get deskSetBackupWriteFailed =>
      'The file could not be written. Choose another folder.';

  @override
  String get deskSetBackupGroup => 'Backup';

  @override
  String get deskSetBackupExportTitle => 'Export history backup';

  @override
  String get deskSetBackupExportHint =>
      'Payments with their details and contacts, in a file only a wallet with this recovery phrase opens. The phrase alone brings back the balance, not the records.';

  @override
  String get deskSetBackupExporting => 'Exporting…';

  @override
  String get deskSetBackupExportButton => 'Export…';

  @override
  String get deskSetBackupImportTitle => 'Import history backup';

  @override
  String get deskSetBackupImportHint =>
      'Merges a backup of this wallet into Activity. Nothing is removed; the same file twice changes nothing.';

  @override
  String get deskSetBackupImportButton => 'Import…';

  @override
  String get deskSetBackupCsvTitle => 'Payments as CSV';

  @override
  String get deskSetBackupCsvHint =>
      'A plain table for spreadsheets. Not encrypted, not importable.';

  @override
  String get deskSetBackupCsvButton => 'Export CSV…';

  @override
  String get deskSetBackupSaveDialogTitle => 'Save payment history';

  @override
  String get deskSetBackupNotSaved => 'Not saved';

  @override
  String get deskSetBackupInFile => 'In the file';

  @override
  String deskSetBackupInFileCounts(int payments, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments payments',
      one: '1 payment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts',
      one: '1 contact',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get deskSetBackupInFileSub => 'Who paid what, fees, notes, slate ids';

  @override
  String get deskSetBackupNotIn => 'Not in it';

  @override
  String get deskSetBackupNotInValue =>
      'Keys, the recovery phrase, the password';

  @override
  String get deskSetBackupOpensWith => 'Opens with';

  @override
  String get deskSetBackupOpensWithValue =>
      'This wallet, or one restored from its phrase';

  @override
  String get deskSetBackupFile => 'File';

  @override
  String get deskSetBackupFileNote =>
      'The file holds payments up to now. Export again after new payments.';

  @override
  String get deskSetBackupExportDesc =>
      'A file with this wallet’s payments, their details and contacts. Only a wallet with the same recovery phrase opens it.';

  @override
  String get deskSetBackupSaved => 'Saved';

  @override
  String get deskSetBackupKeepCopy =>
      'Keep a copy off this computer too: a USB stick, another drive, or cloud storage. Export again after new payments.';

  @override
  String get deskSetBackupOpenFolder => 'Open folder';

  @override
  String get deskSetBackupSaving => 'Saving…';

  @override
  String get deskSetBackupTryAgain => 'Try again';

  @override
  String get deskSetBackupSaveAs => 'Save as…';

  @override
  String get deskSetBackupOpenDialogTitle => 'Open history backup';

  @override
  String get deskSetBackupDetailsRestored => 'Details restored';

  @override
  String get deskSetBackupDetailsRestoredSub =>
      'Payments already here got their counterparty, fee or note back';

  @override
  String get deskSetBackupOlderAdded => 'Older payments added';

  @override
  String get deskSetBackupOlderAddedSub =>
      'Not in the list any more; shown as From backup';

  @override
  String get deskSetBackupContactsAdded => 'Contacts added';

  @override
  String get deskSetBackupAlreadyHere => 'Already here';

  @override
  String get deskSetBackupUnchanged => 'Unchanged';

  @override
  String get deskSetBackupNothingNew => 'Nothing new';

  @override
  String deskSetBackupNothingNewBody(String file) {
    return 'Every record in $file was already here.';
  }

  @override
  String get deskSetBackupImported => 'Imported';

  @override
  String deskSetBackupReading(String file) {
    return 'Reading $file…';
  }

  @override
  String get deskSetBackupNotImported => 'Not imported';

  @override
  String get deskSetBackupBringsBack => 'Brings back';

  @override
  String get deskSetBackupBringsBackValue =>
      'Who paid what, fees and notes of payments already here; older payments the list lost; contacts';

  @override
  String get deskSetBackupNeeds => 'Needs';

  @override
  String deskSetBackupNeedsValue(String network) {
    return 'A file from this wallet (the same recovery phrase), on $network';
  }

  @override
  String get deskSetBackupNever => 'Never';

  @override
  String get deskSetBackupNeverValue =>
      'Removes or changes a payment that is here';

  @override
  String get deskSetBackupChooseFile => 'Choose file…';

  @override
  String get deskSetBackupImportDesc =>
      'Merges a history backup of this wallet into Activity. Nothing is removed, and the same file twice changes nothing.';

  @override
  String get deskSetBackupSaveCsvDialogTitle => 'Save payments as CSV';

  @override
  String get deskSetBackupCsvDialogTitle => 'Export CSV';

  @override
  String get deskSetBackupCsvDialogDesc =>
      'A plain table of this wallet’s payments, for spreadsheets.';

  @override
  String deskSetBackupCsvSavedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0, newest first. Amounts in EPIC with 8 decimals; dates in UTC.';
  }

  @override
  String get deskSetBackupDateError => 'Enter a date as 2026-01-31';

  @override
  String get deskSetBackupDateHint => 'YYYY-MM-DD';

  @override
  String get deskSetBackupRange => 'Range';

  @override
  String get deskSetBackupRangeAll => 'All payments';

  @override
  String get deskSetBackupRangeThisYear => 'This year';

  @override
  String get deskSetBackupRangeLastYear => 'Last year';

  @override
  String get deskSetBackupRangeCustom => 'Custom';

  @override
  String get deskSetBackupFrom => 'From';

  @override
  String get deskSetBackupTo => 'To';

  @override
  String deskSetBackupCsvInfo(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0 · columns: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. File $file.';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '– · columns: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. File $file.';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Not encrypted.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Anyone with the file reads amounts, dates, addresses and notes. It cannot be imported; the history backup is for that.';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments are not in a history backup.',
      one: '1 payment is not in a history backup.',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are new or changed since the last history backup.',
      one: '1 payment is new or changed since the last history backup.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'A restore from the recovery phrase brings back the balance, not who paid what.';

  @override
  String get deskSetBackupNotNow => 'Not now';

  @override
  String get deskSetDlgChainTitle => 'Existing blockchain data found';

  @override
  String get deskSetDlgChainDesc =>
      'This computer already has Epic blockchain data that the local node can use.';

  @override
  String get deskSetDlgChainFolder => 'Folder';

  @override
  String get deskSetDlgChainSize => 'Size';

  @override
  String get deskSetDlgChainUpdated => 'Last updated';

  @override
  String get deskSetDlgChainUpdatedValue => '3 days ago';

  @override
  String get deskSetDlgChainOthers =>
      'Other copies were found too (1). This one was updated most recently.';

  @override
  String get deskSetDlgChainInUse =>
      'Another Epic program is using this folder. Close it, then pick the local node again to use this data.';

  @override
  String get deskSetDlgChainUseIt =>
      'Use it? That saves downloading and syncing the whole blockchain.';

  @override
  String get deskSetDlgChainOlderWallet =>
      'An older Epic Wallet that uses this folder may need to sync again after this. Coins are not affected.';

  @override
  String get deskSetDlgChainFresh => 'Download fresh';

  @override
  String get deskSetDlgChainUse => 'Use this data';

  @override
  String get deskSetDlgPwChanged => 'Password changed.';

  @override
  String get deskSetDlgPwTitle => 'Change password';

  @override
  String get deskSetDlgPwDesc =>
      'The new password unlocks this wallet from now on. A remembered password is forgotten.';

  @override
  String get deskSetDlgPwCurrent => 'Current password';

  @override
  String get deskSetDlgPwWrong => 'Wrong password';

  @override
  String get deskSetDlgPwNew => 'New password';

  @override
  String get deskSetDlgPwRepeat => 'Repeat new password';

  @override
  String deskSetDlgRemoveToastList(String name) {
    return '$name removed from the list';
  }

  @override
  String deskSetDlgRemoveToastDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get deskSetDlgRemoveFilesKept => 'Files kept.';

  @override
  String deskSetDlgRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get deskSetDlgRemoveDesc => 'Nothing changes until confirmed.';

  @override
  String get deskSetDlgRemoveWhat => 'What to remove';

  @override
  String get deskSetDlgRemoveFromList => 'Remove from list';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Files stay in $folder. All wallets can add it back.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Delete wallet';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Deletes its keys and database from $folder. Only the recovery phrase restores it; without it the coins are lost.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'To delete its files as well, unlock this wallet and use Delete wallet under Settings › This wallet.';

  @override
  String get deskSetDlgRemoveUnlock => 'Unlock this wallet';

  @override
  String get deskSetDlgRemoveIrreversible => 'Cannot be undone';

  @override
  String get deskSetDlgRemoveIrreversibleBody =>
      'Only the recovery phrase restores the wallet; without it the coins are lost for good.';

  @override
  String get deskSetDlgRemoveName => 'Wallet name';

  @override
  String deskSetDlgRemoveTypeName(String name) {
    return 'Type $name to confirm.';
  }

  @override
  String get deskSetDlgRemoveNameMismatch => 'Name does not match';

  @override
  String get deskSetDlgPassword => 'Password';

  @override
  String get deskSetDlgPhraseWritten => 'The recovery phrase is written down';

  @override
  String get deskSetDlgRemoving => 'Removing…';

  @override
  String get deskSetDlgWalletLocked => 'The wallet is locked';

  @override
  String get deskSetDlgDeleteTitle => 'Delete this wallet?';

  @override
  String get deskSetDlgDeleteDesc =>
      'Deletes the wallet and its seed from this computer. Only the recovery phrase restores it; without it the coins are lost.';

  @override
  String get deskSetFrameTitle => 'Settings';

  @override
  String get deskSetFrameSections => 'Settings sections';

  @override
  String get deskSetFrameNode => 'Node';

  @override
  String get deskSetFramePrivacy => 'Privacy';

  @override
  String get deskSetFrameAppearance => 'Appearance';

  @override
  String get deskSetFrameThisWallet => 'This wallet';

  @override
  String get deskSetFrameAllWallets => 'All wallets';

  @override
  String get deskSetFramePhrase => 'Recovery phrase';

  @override
  String get deskSetFrameRescan => 'Recheck balance';

  @override
  String get deskSetFrameAbout => 'About';

  @override
  String get deskSetFrameHelp => 'Help';

  @override
  String get deskSetFrameHealthOn => 'On';

  @override
  String get deskSetFrameHealthSlow => 'Slow';

  @override
  String get deskSetFrameNotResponding => 'Not responding';

  @override
  String get deskSetFrameOff => 'Off';

  @override
  String get deskSetFrameChecking => 'Checking…';

  @override
  String get deskSetFrameNodeSynced => 'Synced';

  @override
  String get deskSetFrameNodeSyncing => 'Syncing';

  @override
  String get deskSetFrameConnecting => 'Connecting…';

  @override
  String get deskSetFrameListening => 'Listening';

  @override
  String deskSetFrameHealthLatency(String word, int ms) {
    return '$word · $ms ms';
  }

  @override
  String get deskSetFrameNever => 'never';

  @override
  String get deskSetFrameJustNow => 'just now';

  @override
  String deskSetFrameMinAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '$count h ago',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d ago',
      one: '$count d ago',
    );
    return '$_temp0';
  }

  @override
  String get deskSetComboOpens => 'Opens the list';

  @override
  String get deskSetComboNoAnswer => 'No answer yet';

  @override
  String deskSetComboUse(String host) {
    return 'Use $host';
  }

  @override
  String get deskSetLnodeDidNotStart => 'The node did not start';

  @override
  String get deskSetLnodeDidNotStop => 'The node did not stop';

  @override
  String get deskSetLnodeDidNotRestart => 'The node did not restart';

  @override
  String get deskSetLnodeMoved => 'Chain data moved';

  @override
  String get deskSetLnodeFolderChanged => 'Data folder changed';

  @override
  String get deskSetLnodeFolderFailed => 'The folder did not change';

  @override
  String get deskSetLnodeStart => 'Start';

  @override
  String get deskSetLnodeStop => 'Stop';

  @override
  String get deskSetLnodeRestart => 'Restart';

  @override
  String get deskSetLnodeTabStatus => 'Status';

  @override
  String get deskSetLnodeTabPeers => 'Peers';

  @override
  String get deskSetLnodeWhileSyncing => 'While syncing';

  @override
  String deskSetLnodeWhileSyncingText(String host) {
    return 'Use $host until the local node is synced. The local node takes over by itself.';
  }

  @override
  String get deskSetLnodeChange => 'Change…';

  @override
  String deskSetLnodeUseWhileSyncing(String host) {
    return 'Use $host while syncing';
  }

  @override
  String get deskSetLnodeDataFolder => 'Data folder';

  @override
  String deskSetLnodeUsed(String size) {
    return '$size used';
  }

  @override
  String get deskSetLnodeFreeUnknown => 'free space unknown';

  @override
  String deskSetLnodeFree(String size) {
    return '$size free';
  }

  @override
  String get deskSetLnodeOpen => 'Open';

  @override
  String get deskSetLnodeFolderNotOpened => 'Folder not opened';

  @override
  String get deskSetLnodeChainData => 'Chain data';

  @override
  String get deskSetLnodeChainPointed =>
      'This node reads another program’s folder; delete it there.';

  @override
  String get deskSetLnodeChainText =>
      'Use chain data another Epic node left on this computer, or delete this node’s data and download the chain again.';

  @override
  String get deskSetLnodeReuse => 'Reuse existing…';

  @override
  String get deskSetLnodeDelete => 'Delete…';

  @override
  String get deskSetLnodeAutostart => 'Start with the app';

  @override
  String get deskSetLnodeAutostartHint =>
      'Starts the node at launch and keeps it syncing while the app is open.';

  @override
  String get deskSetLnodeViewLog => 'View node log';

  @override
  String get deskSetLnodeChangeFolder => 'Change folder…';

  @override
  String deskSetLnodeUseMeanwhile(String host) {
    return 'Use $host meanwhile';
  }

  @override
  String get deskSetLnodeWaitingPeers => 'waiting for peers';

  @override
  String get deskSetLnodeSyncingLower => 'syncing';

  @override
  String deskSetLnodeStageUsing(String stage, String host) {
    return '$stage · using $host meanwhile';
  }

  @override
  String get deskSetLnodeNothingUntilSynced =>
      'Nothing can be sent or received until the local node is synced.';

  @override
  String get deskSetLnodeAtTip => 'at tip';

  @override
  String get deskSetLnodeStalledDetail =>
      'no progress for 5 min; restarted once already';

  @override
  String get deskSetLnodeNoProgress => 'The node makes no progress.';

  @override
  String get deskSetLnodeNoProgressText =>
      'Restarting usually helps; if not, the log says why.';

  @override
  String get deskSetLnodePortInUse => 'Port 3413 is used by another program.';

  @override
  String get deskSetLnodePortInUseText =>
      'Close it (another Epic node?) or pick the node already running there under Node server.';

  @override
  String get deskSetLnodeDiskLow => 'Less than 2 GB free on this volume.';

  @override
  String get deskSetLnodeDiskLowText => 'Free space or change the data folder.';

  @override
  String get deskSetLnodeMissing =>
      'The node program is missing from this installation.';

  @override
  String get deskSetLnodeMissingText => 'Reinstall the wallet.';

  @override
  String get deskSetLnodeStopped => 'The node stopped by itself.';

  @override
  String get deskSetLnodeStoppedText => 'The last log lines may say why.';

  @override
  String deskSetLnodeUsesMeanwhile(String host) {
    return 'the wallet uses $host meanwhile';
  }

  @override
  String get deskSetLnodeNothingUntilRuns =>
      'nothing can be sent until it runs';

  @override
  String get deskSetLnodeTilePeers => 'Peers';

  @override
  String get deskSetLnodeTileSync => 'Sync';

  @override
  String get deskSetLnodeTileDownload => 'Download';

  @override
  String deskSetLnodeSoFar(String size) {
    return '$size so far';
  }

  @override
  String get deskSetLnodeTileDisk => 'Chain data on disk';

  @override
  String deskSetLnodeThisSession(String size) {
    return '+$size this session';
  }

  @override
  String deskSetLnodeVersion(String version) {
    return 'Version $version';
  }

  @override
  String deskSetLnodeRunning(String duration) {
    return 'running $duration';
  }

  @override
  String deskSetLnodeStoppedAt(String time) {
    return 'stopped $time';
  }

  @override
  String deskSetLnodePeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '$count peer',
    );
    return '$_temp0';
  }

  @override
  String deskSetLnodeMoving(String done, String total) {
    return 'Moving the chain data · $done of $total';
  }

  @override
  String get deskSetLnodeConnectingPeers => 'Connecting to peers';

  @override
  String deskSetLnodeStartedSecAgo(int seconds) {
    return 'started $seconds s ago';
  }

  @override
  String deskSetLnodeStartedAgo(String duration) {
    return 'started $duration ago';
  }

  @override
  String get deskSetLnodeSettingsChanged => 'Settings changed.';

  @override
  String get deskSetLnodeSettingsChangedText =>
      'They apply at the next restart.';

  @override
  String get deskSetLnodeRestartNow => 'Restart now';

  @override
  String get deskSetLnodeSampled =>
      'Sampled every 30 s while this page is open.';

  @override
  String get deskSetLnodeTomlEdited =>
      'epic-server.toml was edited by hand; peer and folder settings here do not apply.';

  @override
  String get deskSetLnodeSyncProgress => 'Sync progress';

  @override
  String get deskSetLnodeStepHeaders => 'Headers';

  @override
  String get deskSetLnodeStepChainState => 'Chain state';

  @override
  String get deskSetLnodeStepBlocks => 'Blocks';

  @override
  String get deskSetLnodeStepsNone => 'Sync steps: none started';

  @override
  String deskSetLnodeStepOf(int n, String name) {
    return 'Sync step $n of 4: $name';
  }

  @override
  String deskSetLndAskTitle(String host) {
    return 'Use $host until the local node is synced?';
  }

  @override
  String deskSetLndAskDesc(String host) {
    return 'Syncing takes hours. Meanwhile the wallet can read the chain and send through $host, a public node. The local node takes over by itself once it is synced.';
  }

  @override
  String get deskSetLndAskNote =>
      'Asked once. The node and the choice can be changed under Settings › Node › While syncing.';

  @override
  String get deskSetLndAskWait => 'Wait for the local node';

  @override
  String deskSetLndAskUse(String host) {
    return 'Use $host';
  }

  @override
  String get deskSetLndPickTitle => 'Node while syncing';

  @override
  String get deskSetLndPickDesc =>
      'The public node the wallet uses until the local node is synced.';

  @override
  String get deskSetLndDeleted => 'Chain data deleted';

  @override
  String deskSetLndFreed(String size) {
    return '$size freed';
  }

  @override
  String get deskSetLndNotDeleted => 'Chain data not deleted';

  @override
  String get deskSetLndDeleteTitle => 'Delete chain data';

  @override
  String deskSetLndDeleteDesc(String size, String path) {
    return 'Removes $size from $path. The node stops, and the whole chain downloads again on the next start (hours). Wallet keys and history are not touched.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Removes the chain data from $path. The node stops, and the whole chain downloads again on the next start (hours). Wallet keys and history are not touched.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Type $word to confirm.';
  }

  @override
  String deskSetLndTypeToConfirmLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get deskSetLndSourceCli => 'epic (the command-line node)';

  @override
  String get deskSetLndSourceGui => 'Epic GUI';

  @override
  String get deskSetLndSourceBundled => 'an earlier Epic Wallet';

  @override
  String get deskSetLndSourceCustom => 'another folder';

  @override
  String get deskSetLndInUse => 'Chain data in use';

  @override
  String get deskSetLndNotInUse => 'The folder is not in use';

  @override
  String get deskSetLndReuseTitle => 'Chain data found on this computer';

  @override
  String get deskSetLndReuseDesc =>
      'Another Epic node left chain data here. The local node can read that folder instead of downloading the chain.';

  @override
  String get deskSetLndLooking => 'Looking…';

  @override
  String get deskSetLndUseIt => 'Use it';

  @override
  String deskSetLndLastWritten(String date) {
    return 'last written $date';
  }

  @override
  String get deskSetLndLocked => 'In use by another program';

  @override
  String get deskSetLndNothingCopied =>
      'Nothing is copied: the node reads that folder, and Delete chain data is off for it.';

  @override
  String get deskSetLndFresh => 'Download fresh';

  @override
  String deskSetLndFreshLine(String size) {
    return 'Into the wallet’s own folder. About $size.';
  }

  @override
  String get deskSetLndLogTitle => 'Node log';

  @override
  String get deskSetLndReading => 'Reading…';

  @override
  String get deskSetLndLogNote =>
      'Last 200 lines of epic-server.log in the data folder. Newest at the bottom.';

  @override
  String get deskSetLndCopied => 'Copied';

  @override
  String deskSetLndLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '$count line',
    );
    return '$_temp0';
  }

  @override
  String get deskSetLndBadFolder => 'That folder does not work';

  @override
  String get deskSetLndChooseAnother => 'Choose another';

  @override
  String deskSetLndMoveTitle(String size, String folder) {
    return 'Move $size to $folder?';
  }

  @override
  String get deskSetLndMoveDesc =>
      'The node stops while the data moves, then starts again from the new folder. Start fresh there downloads the chain again into it instead.';

  @override
  String get deskSetLndStartFresh => 'Start fresh there';

  @override
  String get deskSetLndMove => 'Move';

  @override
  String get deskSetLndProbNotEmpty => 'The folder is not empty.';

  @override
  String get deskSetLndProbInsideSource => 'It is inside the current folder.';

  @override
  String get deskSetLndProbSourceInside => 'The current folder is inside it.';

  @override
  String deskSetLndProbSpace(String needed, String free) {
    return 'Not enough space: $needed needed, $free free.';
  }

  @override
  String deskSetLndProbSpaceUnknown(String needed) {
    return 'Not enough space: $needed needed, unknown free.';
  }

  @override
  String get deskSetLndProbLocked => 'Another program holds it.';

  @override
  String get deskSetLndProbMissing => 'The current chain data is missing.';

  @override
  String get deskSetLndProbNotWritable => 'It cannot be written to.';

  @override
  String get deskSetLndProbIncomplete =>
      'The current chain data is incomplete.';

  @override
  String get deskSetLndProbForeign => 'Another program’s chain data is there.';

  @override
  String get deskSetPeersBannedToast => 'Peer banned';

  @override
  String get deskSetPeersUnbannedToast => 'Peer unbanned';

  @override
  String get deskSetPeersNotAddress =>
      'Not an IP address and port, such as 203.0.113.5:3414.';

  @override
  String get deskSetPeersAlreadyPreferred => 'Already preferred.';

  @override
  String deskSetPeersMaxRange(int min, int max) {
    return '$min to $max.';
  }

  @override
  String get deskSetPeersReading => 'Reading the peers…';

  @override
  String deskSetPeersSummary(int connected, int inbound, int outbound) {
    return '$connected connected · $inbound in · $outbound out';
  }

  @override
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  ) {
    return '$connected connected · $inbound in · $outbound out · $banned banned';
  }

  @override
  String get deskSetPeersIn => 'in';

  @override
  String get deskSetPeersOut => 'out';

  @override
  String get deskSetPeersBan => 'Ban';

  @override
  String get deskSetPeersColAddress => 'Address';

  @override
  String get deskSetPeersColDirection => 'Direction';

  @override
  String get deskSetPeersColVersion => 'Version';

  @override
  String get deskSetPeersColHeight => 'Height';

  @override
  String get deskSetPeersColFirstSeen => 'First seen';

  @override
  String get deskSetPeersNone => 'No peers connected.';

  @override
  String deskSetPeersMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '$count more',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPeersRefreshed => 'Refreshed every 10 s';

  @override
  String get deskSetPeersBanned => 'Banned';

  @override
  String deskSetPeersBannedAt(String time) {
    return 'banned $time';
  }

  @override
  String get deskSetPeersUnban => 'Unban';

  @override
  String get deskSetPeersPreferred => 'Preferred peers';

  @override
  String get deskSetPeersPreferredLabel =>
      'Preferred peer, IP address and port';

  @override
  String get deskSetPeersAdd => 'Add';

  @override
  String get deskSetPeersMaxIn => 'Max incoming';

  @override
  String get deskSetPeersMaxInLabel => 'Max incoming peers';

  @override
  String get deskSetPeersMaxOut => 'Max outgoing';

  @override
  String get deskSetPeersMaxOutLabel => 'Max outgoing peers';

  @override
  String deskSetPeersPreferredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preferred:',
      one: '$count preferred:',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersForget(String peer) {
    return 'Forget $peer';
  }

  @override
  String deskSetPeersNote(int min, int max, int def) {
    return 'First seen is when this app first saw the peer connected, this session; the node does not report when a connection began. Ban and unban use the node’s owner API. Enter saves a maximum ($min to $max, $def by default).';
  }

  @override
  String get deskSetLndDeleteQuestion => 'Delete chain data?';

  @override
  String get deskSetLogsMemoryOnly => 'The log is kept in memory only.';

  @override
  String get deskSetLogsClearTitle => 'Clear logs?';

  @override
  String get deskSetLogsClearDesc =>
      'Deletes the log files. A report sent later has only what is logged from now on.';

  @override
  String get deskSetLogsKeep => 'Keep logs';

  @override
  String get deskSetLogsClear => 'Clear logs';

  @override
  String get deskSetLogsCleared => 'Logs cleared';

  @override
  String deskSetLogsToday(String time) {
    return 'today $time';
  }

  @override
  String deskSetLogsTomorrow(String time) {
    return 'tomorrow $time';
  }

  @override
  String get deskSetLogsTitle => 'Logs';

  @override
  String get deskSetLogsLevel => 'Log level';

  @override
  String get deskSetLogsLevelNormal =>
      'Normal. Detailed keeps more lines on disk for 24 hours; addresses may appear in the file, reports leave them out.';

  @override
  String deskSetLogsLevelDetailed(String until) {
    return 'Detailed until $until, then Normal. Addresses may appear in the file; reports leave them out.';
  }

  @override
  String deskSetLogsLevelDetailedCore(String until) {
    return 'Detailed until $until, then Normal. Addresses may appear in the file; reports leave them out. Wallet core lines get detailed from the next app start.';
  }

  @override
  String get deskSetLogsNormal => 'Normal';

  @override
  String get deskSetLogsDetailed => 'Detailed';

  @override
  String get deskSetLogsFiles => 'Log files';

  @override
  String deskSetLogsSize(String size, String max) {
    return 'Current size $size of $max. Keeps one older file.';
  }

  @override
  String get deskSetLogsOpenFolder => 'Open log folder';

  @override
  String get deskSetNodePortNote =>
      'Check the address and the port (usually 3413).';

  @override
  String get deskSetNodeListNote =>
      'State from status.btlabs.uk, checked every few minutes. Latency as measured from this computer.';

  @override
  String get deskSetNodeStartTitle => 'Start the local node?';

  @override
  String get deskSetNodeStartDesc =>
      'A separate program syncs the Epic chain on this computer.';

  @override
  String get deskSetNodeStartLine1 =>
      'Downloads the whole chain: several GB of disk space and bandwidth.';

  @override
  String get deskSetNodeStartLine2 =>
      'The first sync takes hours. Until it is done the node shows Syncing.';

  @override
  String get deskSetNodeStartLine3 =>
      'The firewall may ask to allow the node program.';

  @override
  String get deskSetNodeStartButton => 'Start local node';

  @override
  String get deskSetNodeRowNotSetUp => 'Not set up';

  @override
  String get deskSetNodeRowStopped => 'Stopped';

  @override
  String get deskSetNodeRowStarting => 'Starting';

  @override
  String deskSetNodeRowSyncingPct(String percent) {
    return 'Syncing $percent';
  }

  @override
  String get deskSetNodeRowStalled => 'Stalled';

  @override
  String get deskSetNodeRowFailed => 'Failed';

  @override
  String get deskSetNodeLocalInUse => 'Local node in use';

  @override
  String get deskSetNodeLocalInUseText =>
      'It downloads the whole chain. Needs 5 GB free.';

  @override
  String get deskSetNodeLocalNode => 'Local node';

  @override
  String get deskSetNodeGroupComputer => 'This computer';

  @override
  String get deskSetNodeServer => 'Node server';

  @override
  String get deskSetNodeServerHint =>
      'The node the wallet reads the chain through and sends with.';

  @override
  String get deskSetNodeChecking => 'Checking the node…';

  @override
  String get deskSetNodeBackground => 'Sync in background';

  @override
  String get deskSetNodeBackgroundHint =>
      'Keeps syncing while the app is closed.';

  @override
  String get deskSetPhraseNotCopied => 'Not copied';

  @override
  String get deskSetPhraseClipboardRefused => 'The clipboard refused the text.';

  @override
  String get deskSetPhraseCopied => 'Phrase copied';

  @override
  String get deskSetPhraseCleared => 'The clipboard is cleared in 60 s.';

  @override
  String get deskSetPhraseEnterPassword => 'Enter the password.';

  @override
  String get deskSetPhraseWrongPassword => 'Wrong password.';

  @override
  String get deskSetPhraseIntro =>
      'Write the words on paper, in this order. Never type them into a website or a chat.';

  @override
  String get deskSetPhrasePanel => 'Enter the password to show the words';

  @override
  String get deskSetPhraseShowWords => 'Show words';

  @override
  String deskSetPhraseWordsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recovery phrase, $count words',
      one: 'Recovery phrase, $count word',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPhraseHideQr => 'Hide QR code';

  @override
  String get deskSetPhraseShowQr => 'Show QR code';

  @override
  String get deskSetPhraseHideWords => 'Hide words';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return 'Hides in $seconds s';
  }

  @override
  String get deskSetPhraseQrLabel => 'QR code of the recovery phrase';

  @override
  String get deskSetPhraseBackUp => 'Back up the phrase';

  @override
  String get deskSetPhraseBackUpText =>
      'Anyone with these words can take the EPIC. Check that nobody can see the screen.';

  @override
  String get deskSetPrivTorOnFailed => 'Tor not turned on';

  @override
  String get deskSetPrivTorOffFailed => 'Tor not turned off';

  @override
  String get deskSetPrivTor => 'Tor';

  @override
  String get deskSetPrivSwitching => 'Switching Tor';

  @override
  String get deskSetPrivTurnOff => 'Turn Tor off';

  @override
  String get deskSetPrivNotInBuild => 'Not in this build';

  @override
  String get deskSetPrivStarting => 'Starting…';

  @override
  String deskSetPrivStartingDetail(int progress, String waiting) {
    return '$progress %. $waiting wait until Tor is up.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Tor address not published yet. Sends work.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Sends work.';
  }

  @override
  String get deskSetPrivConnected => 'Connected.';

  @override
  String get deskSetPrivNotConnected => 'Not connected';

  @override
  String deskSetPrivStoppedDetail(String waiting) {
    return 'Tor stopped. $waiting wait for Retry or Tor off.';
  }

  @override
  String deskSetPrivProblemDetail(String problem, String waiting) {
    return '$problem. $waiting wait for Retry or Tor off.';
  }

  @override
  String get deskSetPrivStatusSite => 'Status site';

  @override
  String get deskSetPrivUseStatus => 'Use status.btlabs.uk';

  @override
  String get deskSetPrivUseStatusHint =>
      'Network status and information provided by status.btlabs.uk';

  @override
  String deskSetRecvMethodOnFailed(String method) {
    return '$method not turned on';
  }

  @override
  String deskSetRecvMethodOffFailed(String method) {
    return '$method not turned off';
  }

  @override
  String get deskSetRecvServerNotChanged => 'Server not changed';

  @override
  String get deskSetRecvReceiving => 'Receiving';

  @override
  String deskSetRecvSwitching(String method) {
    return 'Switching $method receiving';
  }

  @override
  String deskSetRecvMethodReceiving(String method) {
    return '$method receiving';
  }

  @override
  String get deskSetRecvNotSaved => 'Not saved';

  @override
  String get deskSetRecvAutostart => 'Start with the wallet';

  @override
  String get deskSetRecvAutostartHint => 'Turns on at unlock.';

  @override
  String deskSetRecvMethodAutostart(String method) {
    return '$method: start with the wallet';
  }

  @override
  String get deskSetRecvHeadStopped => 'Stopped';

  @override
  String get deskSetRecvHeadStarting => 'Starting';

  @override
  String get deskSetRecvEpicboxTitle => 'Epicbox receiving';

  @override
  String get deskSetRecvEpicboxText =>
      'Payments arrive via the Epicbox server, also while the wallet is closed.';

  @override
  String get deskSetRecvEpicboxServer => 'Epicbox server';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Which server holds payments for this address. Both wallets can use different servers.';

  @override
  String get deskSetRecvSwitchingServer => 'Switching the Epicbox server…';

  @override
  String get deskSetRecvListNote =>
      'State from status.btlabs.uk, checked every few minutes.';

  @override
  String get deskSetRecvHttpTitle => 'Link · HTTP receiving';

  @override
  String get deskSetRecvHttpText =>
      'Straight from another wallet at this computer’s web address, while this wallet is open.';

  @override
  String get deskSetRecvHttpOffTitle => 'Off while Tor is on';

  @override
  String get deskSetRecvHttpOffText =>
      'Payments straight from another wallet arrive at the Link · Tor address instead.';

  @override
  String get deskSetRecvPrivacySettings => 'Privacy settings';

  @override
  String get deskSetHttpNotChanged => 'Not changed';

  @override
  String get deskSetHttpPortError => 'Port must be 1 to 65535';

  @override
  String get deskSetHttpReachable => 'Reachable';

  @override
  String get deskSetHttpReachableHint => 'Who can pay the HTTP address.';

  @override
  String get deskSetHttpLocalOnly => 'Local only';

  @override
  String get deskSetHttpFromInternet => 'From the internet';

  @override
  String get deskSetHttpGuideHelp => 'Receive from the internet: how it works';

  @override
  String deskSetHttpPublicNote(String port) {
    return 'Answers on all interfaces. The router must forward TCP $port to this computer. Senders on the internet use http://<public IP>:$port.';
  }

  @override
  String get deskSetHttpPort => 'Port';

  @override
  String get deskSetHttpPortHint => '1 to 65535. Used by the HTTP address.';

  @override
  String get deskSetHttpPortLabel => 'HTTP port';

  @override
  String get deskSetHttpGuideTitle => 'Receive from the internet';

  @override
  String get deskSetHttpGuideNowPublic => 'Now: from the internet.';

  @override
  String get deskSetHttpGuideNowLocal =>
      'Now: local only. Only programs on this computer reach the HTTP address.';

  @override
  String get deskSetHttpStep1 => 'Listen on all interfaces';

  @override
  String deskSetHttpStep1Text(String port) {
    return 'The wallet answers on 0.0.0.0, port $port. Other devices and the internet can then send payments to this wallet. The firewall may ask to allow it.';
  }

  @override
  String get deskSetHttpStep2 => 'Forward the port';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'On the router’s page (often 10.0.1.1), find Port forwarding and forward TCP $port to this computer.';
  }

  @override
  String get deskSetHttpStep3 => 'Share the public address';

  @override
  String deskSetHttpStep3Text(String port) {
    return 'Senders use http://<public IP>:$port. The public IP can change.';
  }

  @override
  String get deskSetHttpNoRouter => 'No router setup?';

  @override
  String get deskSetHttpNoRouterText =>
      'Tor works from anywhere with nothing to forward.';

  @override
  String get deskSetHttpTurnOnTor => 'Turn on Tor';

  @override
  String get deskSetHttpExposed =>
      'Only the receiving API is exposed. Plain HTTP is not encrypted.';

  @override
  String get deskSetHttpBackLocal => 'Back to local only';

  @override
  String get deskSetReportNotSent => 'The report was not sent. Try again.';

  @override
  String get deskSetReportSaveDialog => 'Save the report';

  @override
  String get deskSetReportSaved => 'Saved. Cleaned of secrets, not encrypted.';

  @override
  String get deskSetReportNotSaved => 'The file was not saved. Try again.';

  @override
  String get deskSetReportText => 'Report text';

  @override
  String deskSetReportAppLog(String size) {
    return 'App log (last $size)';
  }

  @override
  String get deskSetReportSent => 'Report sent';

  @override
  String get deskSetReportArrived => 'The report arrived.';

  @override
  String deskSetReportArrivedRef(String id) {
    return 'The report arrived. Its reference is $id.';
  }

  @override
  String get deskSetReportDescribe => 'Describe what happened.';

  @override
  String get deskSetReportTitle => 'Report a problem';

  @override
  String get deskSetReportDesc =>
      'The report is encrypted so only the developer can read it. Nothing is sent before Send. Save to file keeps the same cleaned report, not encrypted.';

  @override
  String get deskSetReportWhat => 'What happened';

  @override
  String get deskSetReportWhatHint =>
      'What you did, what you expected, what happened instead';

  @override
  String get deskSetReportContact => 'Contact';

  @override
  String get deskSetReportContactHint =>
      'An email address or other handle, for a reply';

  @override
  String get deskSetReportAttach => 'Attach logs (recommended)';

  @override
  String get deskSetReportAttachHint =>
      'The newest part of the app log, cleaned of phrases, passwords, addresses, IPs and home folders.';

  @override
  String get deskSetReportSentWhat => 'What is sent';

  @override
  String get deskSetReportNotSentTitle => 'Not sent';

  @override
  String get deskSetReportOff => 'Sending is off in this build';

  @override
  String get deskSetReportSaveToFile => 'Save to file';

  @override
  String get deskSetReportSend => 'Send';

  @override
  String get deskSetRescanComplete => 'Scan complete';

  @override
  String get deskSetRescanStoppedLine => 'Scan stopped';

  @override
  String get deskSetRescanLog => 'Scan log';

  @override
  String get deskSetRescanText =>
      'Reads the chain again and rebuilds the balance from the outputs found. Use it when the balance looks wrong, after a restore, or when outputs stay locked after a failed send. The wallet stays usable meanwhile.';

  @override
  String get deskSetRescanStartAgain => 'Start again';

  @override
  String get deskSetRescanDeleteUnconfirmed => 'Delete unconfirmed';

  @override
  String get deskSetRescanDeleteHint =>
      'Also cancels unconfirmed transactions and unlocks their outputs. A payment already on its way may then fail.';

  @override
  String get deskSetRescanScanning =>
      'Scanning the chain. The wallet stays usable; the balance updates when the scan ends.';

  @override
  String get deskSetRescanStopping => 'Stopping…';

  @override
  String deskSetRescanChecking(int percent) {
    return 'Checking… $percent %';
  }

  @override
  String get deskSetRescanFailed => 'Scan failed';

  @override
  String get deskSetRescanNoneFound => 'No unconfirmed transaction was found.';

  @override
  String get deskSetRescanCancelled =>
      'Unconfirmed transactions were cancelled and their outputs unlocked.';

  @override
  String get deskSetRescanNotRead => 'Not read';

  @override
  String get deskSetRescanFinished => 'Scan finished';

  @override
  String get deskSetRescanUpToDate => 'The balance is up to date.';

  @override
  String get deskSetRescanResumed =>
      'The scan carried on from where it stopped; the counts cover that part.';

  @override
  String get deskSetRescanStoppedEarly =>
      'Stopped before the end. The balance was read again; start again to carry on.';

  @override
  String get deskSetRescanNotDeleted =>
      'Unconfirmed transactions were not deleted: that runs only when a scan completes.';

  @override
  String get deskSetRescanBefore => 'Balance before';

  @override
  String get deskSetRescanAfter => 'Balance after';

  @override
  String get deskSetRescanFound => 'Outputs found';

  @override
  String get deskSetRescanRestored => 'Restored';

  @override
  String get deskSetRescanRevived => 'Back to unspent';

  @override
  String get deskSetRescanUnlocked => 'Unlocked';

  @override
  String get deskSetRescanDeleted => 'Deleted';

  @override
  String deskSetWalletsAddedBack(String name) {
    return '$name added back';
  }

  @override
  String get deskSetWalletsNotAddedBack => 'Not added back';

  @override
  String get deskSetWalletsOpenNow => 'Open now';

  @override
  String get deskSetWalletsFolderMissing => 'Folder missing';

  @override
  String deskSetWalletsShowFolder(String name) {
    return 'Show $name in its folder';
  }

  @override
  String deskSetWalletsRemove(String name) {
    return 'Remove $name…';
  }

  @override
  String get deskSetWalletsRemovedGroup => 'Removed from list';

  @override
  String get deskSetWalletsAddBack => 'Add back';

  @override
  String get deskSetWalletsAdd => 'Add a wallet';

  @override
  String get deskSetWalletsCreate => 'Create a wallet';

  @override
  String get deskSetWalletsCreateText =>
      'A new wallet with a new recovery phrase.';

  @override
  String get deskSetWalletsImport => 'Import';

  @override
  String get deskSetWalletsImportText =>
      'From an older Epic Wallet or a folder.';

  @override
  String get deskSetWalletsRestore => 'Restore';

  @override
  String get deskSetWalletsRestoreText => 'From a recovery phrase.';

  @override
  String get deskSetupConfirmPassword => 'Confirm password';

  @override
  String get deskSetupPasswordShort => 'At least 8 characters';

  @override
  String get deskSetupPasswordsDiffer => 'Passwords differ';

  @override
  String get deskSetupBack => 'Back';

  @override
  String get deskSetupNewWalletAdded => 'New wallet added.';

  @override
  String get deskSetupCapsLock => 'Caps Lock is on';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return 'Step $number of $total: $label';
  }

  @override
  String get deskSetupTryAgain => 'Try again';

  @override
  String get deskSetupNotSaved => 'Not saved';

  @override
  String get deskSetupStepPrefs => 'Preferences';

  @override
  String get deskSetupStepNode => 'Node';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupStepReview => 'Review';

  @override
  String get deskSetupAgain =>
      'Running setup again. Nothing changes until Save on the last step.';

  @override
  String get deskSetupPrefsLead => 'App language. It can be changed later.';

  @override
  String get deskSetupNodeTitle => 'Choose a node';

  @override
  String get deskSetupNodeLead =>
      'The wallet reads the chain and sends through an Epic node.';

  @override
  String get deskSetupLocalTitle => 'Local node';

  @override
  String get deskSetupLocalLead =>
      'What running the node here means, and which node to use.';

  @override
  String get deskSetupEpicboxTitle => 'Receive when offline';

  @override
  String get deskSetupReviewTitle => 'Check settings';

  @override
  String get deskSetupReviewLead =>
      'Change anything that is not right, then save.';

  @override
  String get deskSetupSideTitle => 'Set up';

  @override
  String get deskSetupBackToWallet => 'Back to wallet';

  @override
  String get deskSetupLaterNote =>
      'Everything here can be changed later in Settings.';

  @override
  String get deskSetupSave => 'Save settings';

  @override
  String get deskSetupLanguage => 'Language';

  @override
  String get deskSetupNodeServer => 'Node server';

  @override
  String get deskSetupCheckingNodes => 'Checking nodes…';

  @override
  String get deskSetupPickNode => 'Pick a node';

  @override
  String get deskSetupRemoteNode => 'Remote node';

  @override
  String get deskSetupRemoteNodeText => 'Any public node. Ready at once.';

  @override
  String get deskSetupLocalNodeText =>
      'Runs the Epic node on this computer. Nothing is shared with an operator. Needs disk space and hours to sync.';

  @override
  String get deskSetupEpicboxText =>
      'Epicbox delivers payments to the Epicbox address and holds them until the wallet is online.';

  @override
  String get deskSetupEpicboxPrivacy =>
      'It does not hide the IP address from the Epicbox server. Use a VPN if that matters.';

  @override
  String get deskSetupEpicboxServer => 'Epicbox server';

  @override
  String get deskSetupChangePrefsSem => 'Change preferences';

  @override
  String get deskSetupChangeNodeSem => 'Change node';

  @override
  String get deskSetupChangeEpicboxSem => 'Change epicbox';

  @override
  String get deskSetupChange => 'Change';

  @override
  String get deskSetupType => 'Type';

  @override
  String get deskSetupAddress => 'Address';

  @override
  String deskSetupExistingNode(String host) {
    return 'Existing node at $host';
  }

  @override
  String get deskSetupBundledNode => 'Local node, bundled';

  @override
  String get deskSetupWhileSyncing => 'While syncing';

  @override
  String get deskSetupWait => 'wait';

  @override
  String get deskSetupDataFolder => 'Data folder';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Save starts the node. The first sync takes hours; the wallet opens meanwhile and uses $node until then.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Save starts the node. The first sync takes hours; the wallet opens meanwhile.';

  @override
  String get deskSetupServer => 'Server';

  @override
  String get deskSetupOff => 'Off';

  @override
  String get deskSetAboutLicencesLead =>
      'Open-source software in this wallet. Each component keeps its own licence; the full texts are one click away.';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop by BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Browser not opened';

  @override
  String get deskSetAboutOpen => 'Open';

  @override
  String deskSetAboutVersion(String version) {
    return 'Version  $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Node  $version';
  }

  @override
  String get deskSetAboutCommunity => 'Community';

  @override
  String get deskSetAboutLicences => 'Licences';

  @override
  String get deskSetAboutSource => 'Source code';

  @override
  String get deskSetAboutView => 'View';

  @override
  String deskSetAboutChecked(String ago) {
    return 'Checked $ago.';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version is the latest';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return 'Update available: $version';
  }

  @override
  String get deskSetAboutCouldNotCheck => 'Could not check';

  @override
  String get deskSetAboutUpdates => 'Updates';

  @override
  String get deskSetAboutCheckNow => 'Check now';

  @override
  String get deskSetAboutAgoNow => 'just now';

  @override
  String deskSetAboutAgoMin(int count) {
    return '$count min ago';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return '$count h ago';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return '$count d ago';
  }

  @override
  String get deskSetAboutCopyLink => 'Copy link';

  @override
  String get deskSetAboutCopied => 'Copied';

  @override
  String get deskSetAboutNotCopied => 'Not copied';

  @override
  String get deskSetAppearTheme => 'Theme';

  @override
  String get deskSetAppearThemeHint => 'System follows the computer’s setting.';

  @override
  String get deskSetAppearSystem => 'System';

  @override
  String get deskSetAppearDark => 'Dark';

  @override
  String get deskSetAppearLight => 'Light';

  @override
  String get deskSetAppearScale => 'Interface scale';

  @override
  String get deskSetAppearScaleHint =>
      'Text and controls, larger or smaller. Applies at once.';

  @override
  String get deskSetAppearLanguage => 'Language';

  @override
  String get deskSetAppearLanguageHint => 'Applies at once.';

  @override
  String get deskSetAppearHideHint =>
      'Shows dots in place of balances and amounts.';

  @override
  String deskSetHelpNoMatchText(String query) {
    return 'No topic matches “$query”. Try another word.';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Topics found: $count',
      one: 'Topics found: $count',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'No topic matches';

  @override
  String get deskSetHelpReportText =>
      'Describe what went wrong. The app log can go with it, cleaned of secrets and encrypted to the developer. Save to file keeps a copy to send by hand.';

  @override
  String get deskSetHelpShowLess => 'Show less';

  @override
  String get deskSetHelpReadMore => 'Read more';

  @override
  String get deskSetHelpEb1 =>
      'The sending wallet passes the payment to Epicbox and locks the outputs.';

  @override
  String get deskSetHelpEb2 =>
      'Epicbox delivers it when the receiving wallet is online. That wallet adds its part and signs.';

  @override
  String get deskSetHelpEb3 => 'The receiving wallet sends it back to Epicbox.';

  @override
  String get deskSetHelpEb4 => 'Epicbox passes it back to the sending wallet.';

  @override
  String get deskSetHelpSigns =>
      'The sending wallet signs too, finishes the transaction and posts it to the network.';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The network puts it in a block. After $count confirmations it is final.',
      one:
          'The network puts it in a block. After $count confirmation it is final.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 =>
      'The sending wallet saves a transaction file and locks the outputs. The file goes to the recipient by any means.';

  @override
  String get deskSetHelpFile2 =>
      'The recipient opens it. Their wallet adds its part, signs and saves a response file.';

  @override
  String get deskSetHelpFile3 => 'The response file comes back to the sender.';

  @override
  String get deskSetHelpFile4 =>
      'The sender opens the response file under Finalize.';

  @override
  String get deskSetHelpSender => 'Sender';

  @override
  String get deskSetHelpFile => 'File Transfer';

  @override
  String get deskSetHelpRecipient => 'Recipient';

  @override
  String get deskSetHelpNetwork => 'Network';

  @override
  String get deskSetHelpTravels => 'How a transaction travels';

  @override
  String get deskSetHelpOverEpicbox => 'Over Epicbox';

  @override
  String get deskSetHelpWithFile => 'With a file';

  @override
  String deskSetHelpStep(int number, int total) {
    return 'Step $number of $total';
  }

  @override
  String get deskSetHelpSearch => 'Search help';

  @override
  String get deskSetHelpSearchKeys =>
      'Press / to search. Esc clears the search.';

  @override
  String get deskSetHelpSearchHint =>
      'For example: file, confirmations, phrase';

  @override
  String get deskSetHelpClear => 'Clear search';

  @override
  String get deskSetHelpTourAgain => 'Show the tour again';

  @override
  String deskSetHelpTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '$count topic',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSecretProtect =>
      'Windows could not protect the wallet’s secrets (DPAPI refused), so nothing was saved. Sign in to Windows with your own account and its password, not through a remote or service session, then try again.';

  @override
  String get deskKeyringMissingTitle => 'No keyring found';

  @override
  String get deskKeyringMissingText =>
      'Epic Cash keeps its settings and your wallet\'s sealed password in the system keyring, and none answered. Install or start a keyring (GNOME Keyring or KWallet), sign in to a desktop session that runs one, then choose Retry.';

  @override
  String get deskKeyringLockedTitle => 'The keyring is locked';

  @override
  String get deskKeyringLockedText =>
      'Epic Cash keeps its settings and your wallet\'s sealed password in the system keyring, which is locked. Unlock it (it opens with your login password), then choose Retry, or choose Unlock now to have the system ask for it.';

  @override
  String get deskKeyringUnlockNow => 'Unlock now';

  @override
  String get txStatusNotDelivered => 'Not delivered';

  @override
  String get txDetailsNotDeliveredBody =>
      'This payment did not reach the epicbox yet, so the recipient has not received it. Your funds stay locked until it is sent again or cancelled.';

  @override
  String get txDetailsSendAgainDone =>
      'Sent again. It completes when their wallet comes online.';

  @override
  String get deskTxThisWallet => 'This wallet';

  @override
  String get deskErrOldLinks =>
      'This wallet\'s folder has links in it; copy it by hand or restore from the phrase.';

  @override
  String get deskErrOldIncomplete =>
      'This wallet\'s folder could not be read completely; copy it by hand or restore from the phrase.';

  @override
  String get deskErrOldSeedTooLarge =>
      'The wallet.seed file is too large to be a wallet seed.';

  @override
  String get deskErrSendUnbuildable =>
      'This send cannot be built from the coins available.';

  @override
  String get deskErrNothingToConsolidate =>
      'Nothing to consolidate: fewer than two spendable outputs.';

  @override
  String deskSetReportFileNone(String name) {
    return '$name (not included)';
  }

  @override
  String deskSetReportFileAll(String name, String size) {
    return '$name (all, $size)';
  }

  @override
  String deskSetReportFilePart(String name, String part, String size) {
    return '$name (last $part of $size)';
  }

  @override
  String get deskErrTxNotFound => 'Transaction not found';

  @override
  String get deskTxNowUndelivered =>
      'Not delivered. The payment did not reach the epicbox, so the recipient has not received it. Send it again, or cancel it to free the funds.';

  @override
  String get deskTxStatusUndelivered => 'Not delivered';

  @override
  String get deskTxSendAgain => 'Send again';

  @override
  String get deskTxNotSent => 'Not sent';

  @override
  String get deskTxSentAgain => 'Sent again';

  @override
  String get deskTxSentAgainText =>
      'It completes when the recipient’s wallet comes online.';

  @override
  String get deskSendFeeChangedTitle => 'The fee changed';

  @override
  String deskSendFeeChangedText(String fee, String was) {
    return 'The wallet\'s outputs changed since this review, so the send now pays $fee EPIC instead of $was EPIC. Check it and send again.';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max bytes';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'The message is longer than $max bytes. Shorten it.';
  }

  @override
  String get deskSetPhraseCopyTitle => 'Copy the recovery phrase?';

  @override
  String get deskSetPhraseCopyText =>
      'Anyone with these words can take your funds. Store the copy somewhere safe.';

  @override
  String get deskOutAdvanced => 'Manage outputs';

  @override
  String get deskOutStrategyHint =>
      'Which outputs a send spends. Smallest spends the fewest small outputs and leaves the rest spendable; All spends everything and returns one output. Send can change it for one send under Advanced.';

  @override
  String get txStatusNotPosted => 'Not on the network';

  @override
  String get txStatusStalled => 'Stalled';

  @override
  String get txDetailsStalledBody =>
      'Stalled, not delivered. Your payment has not reached the network yet. Send it again.';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      'This payment did not reach the recipient\'s wallet, so they have not received it. Your funds stay locked until it is sent again or cancelled.';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service has not posted your payment yet.';
  }

  @override
  String get deskTxStatusNotPosted => 'Not on the network';

  @override
  String get deskTxNowNotPosted =>
      'Not on the network. The node did not take this payment. Broadcast it again; it cannot go through twice.';

  @override
  String get deskTxBroadcastAgain => 'Broadcast again';

  @override
  String get deskTxBroadcastDone => 'Sent to the network';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return 'Not delivered. The recipient\'s wallet did not take the payment ($method), so they have not received it. Send it again, or cancel it to free the funds.';
  }

  @override
  String get deskInvPayStalled => 'Stalled';

  @override
  String deskInvPayerStalledTitle(String service) {
    return 'Your payment to $service is stalled';
  }

  @override
  String get deskInvPayerStalledText =>
      'Not delivered: it has not reached the network yet, and the funds stay locked. Send again sends it once more without a second approval.';

  @override
  String get deskTxLabelAdd => 'Add label';

  @override
  String get deskTxLabelEdit => 'Edit label';

  @override
  String get deskTxLabelHint => 'Add label';

  @override
  String get deskTxLabelField => 'Label';

  @override
  String get deskTxLabelTip =>
      'A name for this payment, for you. Shown in Activity and exports.';

  @override
  String get deskTxLabelAdded => 'Label added';

  @override
  String get deskTxLabelSaved => 'Label saved';

  @override
  String get deskTxLabelRemoved => 'Label removed';

  @override
  String get deskTxLabelNotSaved => 'Label not saved';

  @override
  String get deskTxDetailsAdd => 'Add details';

  @override
  String get deskTxDetailsEdit => 'Edit';

  @override
  String get deskTxDetailsTitleAdd => 'Add details';

  @override
  String get deskTxDetailsTitleEdit => 'Edit details';

  @override
  String get deskTxDetailsTip =>
      'Only for payments found by a scan. Shown as added by you in Activity, details and exports. Amounts, dates and confirmations do not change.';

  @override
  String get deskTxDetailsFrom => 'From';

  @override
  String get deskTxDetailsFromTip =>
      'Who paid, for your records. Not verified and never used for payment proofs.';

  @override
  String get deskTxDetailsFromHint => 'Address of the sender';

  @override
  String get deskTxDetailsFromBad =>
      'Use an Epicbox, http(s) or .onion address.';

  @override
  String get deskTxDetailsNote => 'Note';

  @override
  String get deskTxDetailsAdded => 'Details added';

  @override
  String get deskTxDetailsSaved => 'Details saved';

  @override
  String get deskTxDetailsRemoved => 'Details removed';

  @override
  String get deskTxDetailsNotSaved => 'Details not saved';

  @override
  String get deskTxManualTag => 'Added by you';

  @override
  String deskTxManualTip(String date) {
    return 'Added by you on $date. Not from the chain.';
  }

  @override
  String get deskTxManualTipNoDate => 'Added by you. Not from the chain.';

  @override
  String deskTxManualTipFrom(String date) {
    return 'Added by you on $date. Not from the chain, not verified.';
  }

  @override
  String get deskTxManualTipFromNoDate =>
      'Added by you. Not from the chain, not verified.';

  @override
  String get deskHistConflictTitle => 'Details differ';

  @override
  String deskHistConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'The backup has other details for $n payments you described. Yours are kept unless you choose otherwise.',
      one:
          'The backup has other details for $n payment you described. Yours are kept unless you choose otherwise.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'Mine';

  @override
  String get deskHistConflictBackup => 'Backup';

  @override
  String get deskHistConflictKeepAll => 'Keep all mine';

  @override
  String get deskHistConflictImport => 'Import';

  @override
  String get deskHistConflictEmpty => 'empty';

  @override
  String deskHistImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n details replaced, the rest kept as yours.',
      one: '$n detail replaced, the rest kept as yours.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayUnknown(String relay) {
    return '$relay isn\'t a server this app knows. Check the address before you send.';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay did not answer.';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay did not answer, so the recipient has not received this payment. Your funds stay locked until it is sent again or cancelled.';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return 'Not delivered: $relay did not answer. The payment waits in Activity; cancel it there to unlock the funds.';
  }

  @override
  String deskErrRelayNoAnswer(String relay) {
    return '$relay did not answer.';
  }

  @override
  String get deskSendRelayUnknownTitle => 'Unknown Epicbox server';

  @override
  String deskSendRelayUnknownText(String relay) {
    return '$relay is not a server this app knows. Check the address before you send. You can still send.';
  }

  @override
  String deskTxNowUndeliveredRelay(String relay) {
    return 'Not delivered. $relay did not answer, so the recipient has not received the payment. Send it again, or cancel it to free the funds.';
  }

  @override
  String get deskInvNoticeReceiveSuperseded =>
      'Your other device with this wallet took a payment this device was also receiving. Recheck balance to see it here.';

  @override
  String deskHistConflictLeadOldWallet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'The old wallet\'s history has other details for $n payments you described. Yours are kept unless you choose otherwise.',
      one:
          'The old wallet\'s history has other details for $n payment you described. Yours are kept unless you choose otherwise.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Old wallet';

  @override
  String get deskHistConflictApply => 'Apply';

  @override
  String get deskTxProofNone => 'No payment proof for this payment.';

  @override
  String get deskUpdAvailable => 'Update available';

  @override
  String deskUpdNotice(String version) {
    return 'Update available · $version';
  }

  @override
  String deskUpdDownload(String version) {
    return 'Download $version';
  }

  @override
  String get deskUpdOpensPage => 'Opens the download page';

  @override
  String deskUpdDownloading(String percent) {
    return 'Downloading $percent %';
  }

  @override
  String get deskUpdRestart => 'Restart to update';

  @override
  String deskUpdReady(String version) {
    return '$version is ready';
  }

  @override
  String get deskUpdRestartHint =>
      'The app closes, installs it and opens again.';

  @override
  String get deskUpdFailed => 'Couldn\'t download the update';

  @override
  String get deskUpdTryAgain => 'Try again';

  @override
  String get deskUpdInstallFailed => 'Couldn\'t install the update';

  @override
  String get deskUpdOpenPage => 'Open the download page';

  @override
  String get deskUpdErrDamaged =>
      'The file did not match the signed update information.';

  @override
  String get deskUpdErrStopped => 'The download stopped.';

  @override
  String get deskUpdErrInstall => 'The new version could not be put in place.';

  @override
  String get deskUpdUnfinished => 'Update didn\'t finish. Try again.';

  @override
  String get advExperimental => 'Experimental';

  @override
  String get advTitle => 'Advanced';

  @override
  String get advStateOff => 'Off';

  @override
  String get advIntro =>
      'Everything here is off to begin with. Each switch adds one more part of the wallet, in the place it belongs.';

  @override
  String get advShowsHeader => 'Shows more';

  @override
  String get advNetworkHeader => 'Network';

  @override
  String get advNetworkHint =>
      'How the wallet reaches the network. Standard connects directly; Tor can be turned on in Privacy & network. Tor only never connects directly: without Tor the wallet stays offline and says so on Home. Offline stays on this phone and your local network: with a node on your network you can still send to local addresses and use File Transfer; otherwise you see your balance and history as last seen.';

  @override
  String get advOutputs => 'Outputs';

  @override
  String get advOutputsHint =>
      'Shows the Outputs page, under Wallet and on Home. It lists the coins the balance is made of, lets you split or consolidate them, and sets the defaults a send uses. A split or consolidation in progress keeps the page visible.';

  @override
  String get advTechnical => 'Technical details';

  @override
  String get advTechnicalHint =>
      'Shows the technical rows on a payment\'s details: kernel, slate ID, commitments and block height. In Invoices, shows the address rotation and the count of dropped messages.';

  @override
  String get advSendOptions => 'Send options';

  @override
  String get advSendOptionsHint =>
      'Shows Strategy for sends and Split change in Settings › Transactions: which outputs a send spends, and whether its change is split. Stays visible while either is not at its default.';

  @override
  String get advServerDetails => 'Server details';

  @override
  String get advServerDetailsHint =>
      'Shows hosts, latency, version and block height in the server pickers and on the status card, the relay address under Receive, and the invoice address in full.';

  @override
  String get advRecheckHeight => 'Recheck from a height';

  @override
  String get advRecheckHeightHint =>
      'Lets Recheck balance start from a block height or a date instead of the first block. Faster, and the only way to skip early history. Restore always offers the choice.';

  @override
  String get advModeStandard => 'Standard';

  @override
  String get advModeStandardLine =>
      'Connects directly. Tor can be turned on in Privacy & network.';

  @override
  String get advModeTorOnly => 'Tor only';

  @override
  String get advModeTorOnlyLine =>
      'Every connection goes through Tor. Without Tor the wallet stays offline and says so.';

  @override
  String get advModeOffline => 'Offline';

  @override
  String get advModeOfflineLine =>
      'Only this phone and your local network. A node on your network still works; everything else waits until you switch back.';

  @override
  String get advTorOnlyNote =>
      'Tor only pauses notifications: registering for them would reveal this phone\'s address.';

  @override
  String get advOfflineNote =>
      'Offline pauses Epicbox, Tor, status checks and notifications. With a node on your local network, Recheck balance, File Transfer and Link sends to local addresses still work. The node\'s own peers are the node\'s setting.';

  @override
  String get advReset => 'Hide everything again';

  @override
  String get advHomeOffline => 'Offline mode';

  @override
  String get advHomeTorOnlyWaiting => 'Tor only · waiting for Tor';

  @override
  String get advBuiltInNode => 'Built-in node';

  @override
  String get advLogs => 'Logs';

  @override
  String get deskSetFrameAdvanced => 'Advanced';

  @override
  String get deskSetAdvIntro =>
      'Everything here is off to begin with. Each switch adds one more part of the wallet, in the place it belongs.';

  @override
  String get deskSetAdvShows => 'Shows more';

  @override
  String get deskSetAdvOutputs => 'Outputs';

  @override
  String get deskSetAdvOutputsHint =>
      'Shows the Outputs page in the sidebar. It lists the coins the balance is made of, lets you split or consolidate them, and sets the defaults a send uses. A split or consolidation in progress keeps the page visible.';

  @override
  String get deskSetAdvTechnical => 'Technical details';

  @override
  String get deskSetAdvTechnicalHint =>
      'Shows the Technical details fold on every transaction: slate ID, kernel, block height, the core\'s status and type, and the payment proof. Without it, a More link on a transaction shows them once. In Invoices, shows the Advanced folds.';

  @override
  String get deskSetAdvSendOptions => 'Send options';

  @override
  String get deskSetAdvSendOptionsHint =>
      'Adds a fold to Send where one send can choose which outputs it spends, Smallest or All, and whether to split the change. The defaults stay on Outputs.';

  @override
  String get deskSetAdvServerDetails => 'Server details';

  @override
  String get deskSetAdvServerDetailsHint =>
      'Shows hosts, latency, version and block height in the node and Epicbox lists, on the sidebar\'s status rows and in the status card.';

  @override
  String get deskSetAdvRecheck => 'Recheck from a height';

  @override
  String get deskSetAdvRecheckHint =>
      'Lets Recheck balance also drop unconfirmed transactions. Restore offers a start block to everyone, whatever this says.';

  @override
  String get deskSetAdvBuiltInNode => 'Built-in node';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'Lets this computer run its own node: the This computer option under Node, its sync panel, and Start node on Overview. The chain takes hours to sync and several gigabytes of disk. A node that is running keeps its rows.';

  @override
  String get deskSetAdvLogs => 'Logs';

  @override
  String get deskSetAdvLogsHint =>
      'Shows the Logs group under Help: open the log folder, clear the logs. Report a problem attaches the log either way.';

  @override
  String get deskSetAdvNetwork => 'Network';

  @override
  String get deskSetAdvNetworkHint =>
      'How the wallet reaches the network. Standard connects directly; Tor can be turned on under Privacy. Tor only never connects directly: without Tor the wallet stays offline and says so in the sidebar. Offline stays on this computer and your local network: with a node here or on your network you can still send to local addresses, receive over Link and use File Transfer; the built-in node keeps running, as its own peers are the node\'s setting.';

  @override
  String get deskSetAdvModeStandard => 'Standard';

  @override
  String get deskSetAdvModeStandardText =>
      'Connects directly. Tor can be turned on under Privacy.';

  @override
  String get deskSetAdvModeTorOnly => 'Tor only';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'Every connection goes through Tor. Without Tor the wallet stays offline and says so.';

  @override
  String get deskSetAdvModeOffline => 'Offline';

  @override
  String get deskSetAdvModeOfflineText =>
      'Only this computer and your local network. Your node keeps running; its own peers are the node\'s setting.';

  @override
  String get deskSetAdvTorOnlyNote =>
      'Tor only turns Link · HTTP receiving off: a plain address would reveal this computer.';

  @override
  String get deskSetAdvOfflineNote =>
      'Epicbox, Tor and status checks pause. With a node on this computer or your network, Recheck balance, File Transfer and Link sends to local addresses still work.';

  @override
  String get deskSetAdvNotInBuild => 'Not in this build';

  @override
  String get deskSetAdvReset => 'Hide everything again';

  @override
  String deskSetAdvOn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n switches on',
      one: '1 switch on',
    );
    return '$_temp0';
  }

  @override
  String get deskShellOffline => 'Offline mode';

  @override
  String get deskShellTorOnlyWaiting => 'Tor only · waiting for Tor';

  @override
  String get deskSetAcctAutoLockHint =>
      'Locks the wallet after this long without a key press or mouse movement. Turn it off to lock only with Lock wallet.';

  @override
  String get netBlockOffline => 'Offline mode is on in Advanced.';

  @override
  String get netBlockTorOnly => 'Tor only is on in Advanced.';

  @override
  String get netBlockWaitingForTor => 'Waiting for Tor.';

  @override
  String get receiveOfflineLine =>
      'Can\'t receive this way while Offline mode is on.';

  @override
  String get txDetailsMore => 'More';

  @override
  String get restoreStartFromLink => 'Start from a date or height';

  @override
  String get homeOfflineDetail =>
      'Offline mode is on in Advanced. The balance is the last one seen.';

  @override
  String get homeWaitingTorDetail =>
      'Tor only is on in Advanced. Waiting for Tor to connect.';

  @override
  String get settingsRescanBodyPlain =>
      'The wallet looks for its funds again, from the first block. This can take a long time.';

  @override
  String get slNodeField => 'Node address';

  @override
  String get slRelayField => 'Epicbox server';

  @override
  String get slFieldHint => 'Paste or type to filter or add';

  @override
  String slSwitchTitle(String host) {
    return 'Switch to $host?';
  }

  @override
  String get slSwitchBody => 'Your Epicbox address changes. Share the new one.';

  @override
  String get slSwitch => 'Switch';

  @override
  String get slHelpAddable => 'Not in the list.';

  @override
  String slHelpMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches.',
      one: '$count match.',
      zero: 'No match.',
    );
    return '$_temp0';
  }

  @override
  String get slClear => 'Clear';

  @override
  String slAddRow(String host) {
    return 'Add $host';
  }

  @override
  String get slAddTestsNode => 'Tests the node first, then offers the switch.';

  @override
  String get slAddTestsRelay =>
      'Tests the server first, then offers the switch.';

  @override
  String slAdded(String host) {
    return 'Added $host.';
  }

  @override
  String get slRemove => 'Remove';

  @override
  String slRemoved(String host) {
    return 'Removed $host.';
  }

  @override
  String get slUndo => 'Undo';

  @override
  String get slInUseSwitchFirst => 'In use. Switch first.';

  @override
  String get slRestore => 'Restore removed servers';

  @override
  String slRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count removed',
      one: '$count removed',
    );
    return '$_temp0';
  }

  @override
  String get slRestored => 'Removed servers restored.';

  @override
  String get slRelayWarning =>
      'Switching changes your address. Senders need the new one.';

  @override
  String get slNotAnAddress => 'Not a server address. Use host or host:port.';

  @override
  String get slRelayNoAnswer => 'No answer from this server. Nothing added.';

  @override
  String deskSlRemoveHost(String host) {
    return 'Remove $host';
  }

  @override
  String get deskSlInUse => 'In use';

  @override
  String get deskSlHealthUnknown => 'Health unknown';

  @override
  String get deskSlNodeNoAnswer => 'No answer from this node. Nothing added.';

  @override
  String get deskSlTorWait => 'Tor is not connected yet. Nothing added.';

  @override
  String deskSlLatency(String ms) {
    return '$ms ms';
  }

  @override
  String get deskSlDefault => 'Default';

  @override
  String deskSlTesting(String host) {
    return 'Testing $host…';
  }

  @override
  String get deskSlSetupEpicboxOn => 'Receive through Epicbox';

  @override
  String get deskSlHelpChoose =>
      'Pick one, or type to filter the list or add a server.';

  @override
  String get deskOnbRestoreFromLink => 'Start from a block height';

  @override
  String get deskOnbRestoreFromHide => 'Check the whole chain';

  @override
  String get deskOnbRestoreFromLabel => 'Start from block';

  @override
  String get deskOnbRestoreFromHint => 'Block height';

  @override
  String get deskOnbRestoreFromHelp =>
      'Only if the wallet\'s first payment came after this block. Leave it empty to check the whole chain.';

  @override
  String get deskOnbRestoreFromInvalid => 'Use digits only, or leave it empty.';

  @override
  String get deskNetOfflineReason => 'Offline mode is on in Advanced.';

  @override
  String get deskNetWaitingTorReason =>
      'Waiting for Tor. Tor only is on in Advanced.';

  @override
  String get deskNetTorOnlyLine => 'Tor only is on in Advanced.';

  @override
  String get deskNetOpenAdvanced => 'Open Advanced';

  @override
  String get deskNetSendFileHint => 'File Transfer still works.';

  @override
  String get deskNetRecvOfflineText =>
      'Your address stays the same. Nothing can arrive until Offline mode is off.';

  @override
  String get deskNetRecvWaitTorText =>
      'Receiving starts when Tor is connected. File Transfer still works.';

  @override
  String get deskNetCantReceive => 'Can\'t receive offline.';

  @override
  String get deskRailOffline => 'Offline';

  @override
  String get deskTourAdvancedTitle => 'Advanced';

  @override
  String get deskTourAdvancedText =>
      'Tor-only mode, outputs and technical details live here. Switch on what you need.';

  @override
  String get deskTxMore => 'More';

  @override
  String get deskTxLess => 'Less';

  @override
  String get settingsSectionTransactions => 'Transactions';

  @override
  String get settingsHubMethods => 'Methods';

  @override
  String get settingsHubDefault => 'Default';

  @override
  String get settingsHubSendDefaults => 'Send defaults';

  @override
  String get txMethodsHeader => 'Payment methods';

  @override
  String get txFamilyLinkLine =>
      'Straight to the other wallet while both are open.';

  @override
  String get txFamilyDirectLine =>
      'Hand to hand, with no connection between the wallets.';

  @override
  String get txLinkHttpLine =>
      'Pay web addresses; get paid from this Wi-Fi network.';

  @override
  String get txLinkHttpHint =>
      'Link · HTTP pays straight to a wallet at a web address (http://host:3415) and gives this phone an address that wallets on the same Wi-Fi network can pay. Both wallets must be open. It is not encrypted on the way, cannot be reached from the internet or over mobile data, and is off while Tor is on. Adds Link · HTTP to Send and Receive.';

  @override
  String get txLinkTorLine =>
      'Pay onion addresses; get paid at this phone’s Tor address.';

  @override
  String get txLinkTorHint =>
      'Link · Tor pays straight to a wallet at an onion address and gives this phone a Tor address to be paid at. Both wallets must be open. Needs Tor: the Tor switch under Privacy & network routes the wallet’s connections through Tor; this switch only turns the address on. Adds Link · Tor to Send and Receive.';

  @override
  String get txLinkTorNeedsTor =>
      'Needs Tor. Turn it on under Privacy & network.';

  @override
  String get txLastMethodNotice => 'Keep at least one payment method on.';

  @override
  String get txEpicboxHint =>
      'Epicbox pays through a relay, so the other wallet does not have to be open. Off, the wallet connects to no relay: no Epicbox payments, invoices or notifications. The other methods still work.';

  @override
  String get txDirectLine =>
      'Pay web and onion addresses; get paid straight from other wallets.';

  @override
  String get txDirectHint =>
      'Link pays straight to the other wallet at a web or onion address, and lets this phone be paid the same way. Both wallets must be open. HTTP works on this Wi-Fi network; Tor needs Tor. Adds Link to Send and Receive.';

  @override
  String get txFileLine => 'Pay or get paid with a file you pass on yourself.';

  @override
  String get txFileHint =>
      'File Transfer makes a transaction file that you pass to the other person any way you like (a message, a mail, a cable), and they pass one back. It needs no connection between the two wallets. Adds File Transfer to Send and Receive.';

  @override
  String get txStartHeader => 'Send starts on';

  @override
  String get txStartNote => 'You can still pick another method on Send.';

  @override
  String get txDefaultsHeader => 'Send defaults';

  @override
  String get outputsDefaultsMoved =>
      'Send defaults are in Settings › Transactions';

  @override
  String get advNodeFailover => 'Node failover';

  @override
  String get advNodeFailoverHint =>
      'When your node stops answering, the wallet uses the next working node in your list for this session.';

  @override
  String nodeFailoverSwitched(String host) {
    return 'Node not answering. Switched to $host.';
  }

  @override
  String nodeFailoverInsteadOf(String host) {
    return 'Instead of $host';
  }

  @override
  String get deskSetAdvNodeFailover => 'Node failover';

  @override
  String get deskSetAdvNodeFailoverHint =>
      'When your node stops answering, the wallet uses the next working node in your list for this session.';

  @override
  String deskNodeFailoverSwitched(String host) {
    return 'Node not answering. Switched to $host.';
  }

  @override
  String deskNodeFailoverInsteadOf(String host) {
    return 'Instead of $host';
  }

  @override
  String get netOfflineOnlyLocal => 'Offline: only local addresses.';

  @override
  String get netOfflineNoPeers =>
      'Your node has no peers: the payment waits in its pool until it reconnects.';

  @override
  String get netOfflineNodeHint =>
      'Uses the node to read the chain and post. For the most privacy, use a local node.';

  @override
  String get netOfflineNodeLine => 'Uses the node';

  @override
  String get netBlockEpicboxOff => 'Epicbox is off in Settings › Transactions.';

  @override
  String netBlockMethodOff(String method) {
    return '$method is off in Settings › Transactions.';
  }

  @override
  String get txEpicboxLine =>
      'Pay or get paid through a relay. The other wallet can be closed.';

  @override
  String get txEpicboxOffTitle => 'Turn Epicbox off?';

  @override
  String txEpicboxOffPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are waiting for their replies over Epicbox. They arrive when Epicbox is on again.',
      one: 'A payment is waiting for its reply over Epicbox. It arrives when Epicbox is on again.',
    );
    return '$_temp0';
  }

  @override
  String get txEpicboxOffAction => 'Turn off';

  @override
  String get pushNoticeOffEpicbox => 'Notifications off: they need Epicbox.';

  @override
  String get settingsPushNeedsEpicbox => 'Needs Epicbox';

  @override
  String sendContactOnlyEpicbox(String name) {
    return '$name has only an Epicbox address.';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name has only a $method address.';
  }

  @override
  String get receiveEpicboxOffText =>
      'Senders\' payments wait at the relay until Epicbox is on again.';

  @override
  String get receiveNoMethods => 'No receiving method is on';

  @override
  String get receiveNoMethodsBody => 'Turn one on in Settings › Transactions.';

  @override
  String get receiveNoMethodsButton => 'Open Settings';

  @override
  String get deskErrOfflineOnlyLocal => 'Offline: only local addresses.';

  @override
  String get deskNetOfflineNoPeers =>
      'Your node has no peers: the payment waits in its pool until it reconnects.';

  @override
  String get deskOutDefaultsMoved =>
      'The strategy and Split change for sends are set in Settings › Transactions.';

  @override
  String get deskOutDefaultsOpen => 'Open Transactions';

  @override
  String get deskSetFrameTransactions => 'Transactions';

  @override
  String get deskSetTxMethods => 'Payment methods';

  @override
  String get deskSetTxEpicboxHint =>
      'Pay and get paid through an Epicbox server. Most payments go this way. Off, the wallet connects to no Epicbox server: no Epicbox payments or invoices. The other methods still work.';

  @override
  String get deskSetTxDirectHint =>
      'Pay and get paid straight from wallet to wallet at a web address (http://host:3415), with no server between. Works only while both wallets are open; off while Tor is on. Adds Link · HTTP to Send and its address to Receive.';

  @override
  String get deskSetTxFileHint =>
      'Pay and get paid by handing over a transaction file, with no network needed. Adds File Transfer to Send and the file steps to Receive.';

  @override
  String get deskSetTxSend => 'Send';

  @override
  String get deskSetTxStart => 'Send starts on';

  @override
  String get deskSetTxStartHint =>
      'The method the Send page opens with. You can still change it for one payment on Send.';

  @override
  String get deskSendMethodHeader => 'Payment method';

  @override
  String get sendRequestTitle => 'Payment request';

  @override
  String get sendRequestCheck => 'Check the amount, then continue.';

  @override
  String get sendRequestDismiss => 'Dismiss';

  @override
  String get sendAmountFromCode => 'Requested by the code';

  @override
  String sendAmountCodeAsked(String amount) {
    return 'The code asked for $amount.';
  }

  @override
  String get sendCodeAmountInvalid =>
      'The amount in this code is not valid and was ignored.';

  @override
  String get sendCodeAmountTooLarge =>
      'The amount in this code is too large and was ignored.';

  @override
  String get sendCodeTooLong =>
      'Part of this code was too long and was ignored.';

  @override
  String get payeeNameLabel => 'Name given by the payee (not verified)';

  @override
  String get payeeNoteLabel => 'Note from the payee (not verified)';

  @override
  String get payeeUnverifiedTitle => 'Not verified';

  @override
  String get payeeUnverifiedHint =>
      'The name and the note are written into the code by whoever made it. Nobody checks them. Check the address and the amount, not the name.';

  @override
  String get sendNoteFromCodeHelper => 'From the code. They see it too.';

  @override
  String get sendOriginQr => 'From a QR code';

  @override
  String get sendOriginLink => 'From a link';

  @override
  String get sendOriginPasted => 'Pasted';

  @override
  String get sendDirectHost => 'Host';

  @override
  String get sendPlainHttpRow => 'Not encrypted (plain HTTP)';

  @override
  String get scanNotEpicTitle => 'Not an Epic code';

  @override
  String get scanNotEpicBody => 'This is not an Epic address or payment code.';

  @override
  String get scanBadAddress => 'The address in this code is not valid.';

  @override
  String get scanWrongNetworkTitle => 'Other network';

  @override
  String get scanWrongNetworkBody =>
      'This address is for a different Epic network. This wallet cannot pay it.';

  @override
  String get scanSlateTextBody =>
      'This is the text of a transaction file, not an address.';

  @override
  String get commonOpen => 'Open';

  @override
  String get scanPairingTitle => 'Pairing link';

  @override
  String get scanPairingUnavailable =>
      'Pairing is not available in this version.';

  @override
  String get scanCodeTextLabel => 'Scanned text';

  @override
  String get scanCopied => 'Copied';

  @override
  String get linkWaitingNotice => 'Payment link received';

  @override
  String get linkFinishCurrentFirst => 'Finish the current payment first.';

  @override
  String get deskSendToQrPayment =>
      'A QR Payment code. Scan it with Epic Cash Mobile.';

  @override
  String get deskSetRecvTorTitle => 'Link · Tor receiving';

  @override
  String get deskSetRecvTorText =>
      'Straight from another wallet at this wallet’s Tor address, while it is open.';

  @override
  String get deskSetTxTorHint =>
      'Pay and get paid straight from wallet to wallet at an onion address, over Tor, with no server between. Works only while both wallets are open. Needs Tor: the Tor switch under Privacy routes the wallet’s connections through Tor; this switch only turns the address on. Adds Link · Tor to Send and its address to Receive.';

  @override
  String get deskSetTxTorNeedsTor =>
      'Tor is off. Turn it on under Privacy to be paid at the Tor address.';

  @override
  String get deskSetTxLastMethod => 'Keep at least one payment method on.';

  @override
  String get deskRecvTorOffTitle => 'Link · Tor receiving needs Tor.';

  @override
  String get deskRecvTorOffText =>
      'The Tor address works while Tor is on. Tor is Settings › Privacy’s switch; it routes the wallet’s connections through Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Settings not saved';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Without saving, the wallet uses the settings stored so far. They can be changed later in Settings.';
  }

  @override
  String get deskSetupSkipSave => 'Continue without saving';

  @override
  String get deskSetupResumeLead =>
      'Setup was not finished last time. The wallet reads the chain and sends through an Epic node.';

  @override
  String deskErrProofContactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts merged with existing ones',
      one: '1 contact merged with an existing one',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsKnown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts already saved',
      one: '1 contact already saved',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts skipped: no valid address',
      one: '1 contact skipped: no valid address',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactAddressesLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count addresses not added: they conflict with saved contacts',
      one: '1 address not added: it conflicts with a saved contact',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofContactsUnreadable =>
      'Some old contacts could not be read: the old address book is damaged';

  @override
  String get deskErrProofContactsFailed =>
      'Not all contacts were saved: the address book could not be written';

  @override
  String get deskTxStatusSenderPosted => 'Sender reports posted';

  @override
  String get deskTxNowSenderPosted =>
      'Signed and returned. The sender reports it posted this payment; it completes when the blockchain confirms it.';
}
