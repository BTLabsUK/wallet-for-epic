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
  String get txRestoredFunds => 'Found on the chain';

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
  String get txEditFromHelper => 'Not verified. For your records only.';

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
          'The file has different details for $n payments. Yours are kept unless you pick the file’s.',
      one: 'The file has different details for 1 payment. Yours are kept unless you pick the file’s.',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'Mine';

  @override
  String get histConflictBackup => 'File';

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
  String get txStatusFromBackup => 'Imported';

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
    return 'Found on the chain: $amount';
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
      'Not enough spendable EPIC for this amount plus the fee.';

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
      'This is not a wallet data file from this app.';

  @override
  String get errorHistoryNewer =>
      'This wallet data file was made by a newer version of the app.';

  @override
  String get errorHistoryDamaged => 'This wallet data file is damaged.';

  @override
  String get errorHistoryOtherWallet =>
      'This file belongs to a different wallet. Only the wallet restored from the same recovery phrase can open it.';

  @override
  String get errorHistoryOtherNetwork =>
      'This wallet data file is from another network.';

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
  String get scanResuming => 'Resuming the scan';

  @override
  String get scanResumedNotice =>
      'The scan paused while the app was in the background. It goes on from where it stopped.';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'System';

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
          'Waiting for $days days. The Epicbox server deletes payments after 7 days, so this one can no longer complete. Cancel it to free the coins, then send again.',
      one: 'Waiting for 1 day. The Epicbox server deletes payments after 7 days, so this one can no longer complete. Cancel it to free the coins, then send again.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Sent through Epicbox. Completes when their wallet comes online; the amount stays locked until then or until cancelled.';

  @override
  String get txDetailsWaitingRecipient =>
      'Waiting for the recipient’s response file. The amount stays locked until then or until cancelled.';

  @override
  String get txDetailsWaitingSender => 'Waiting for the sender to post it.';

  @override
  String get txDetailsSenderPosted =>
      'The sender reports it posted this payment. It completes when the network confirms it.';

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
      'Cancelled. Nothing was paid, and the coins are spendable again. If the recipient already got it, their wallet may still show it as waiting.';

  @override
  String get txDetailsCancelledReleased =>
      'The network never took it, so its coins were released. Check the recipient did not receive it before sending again.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'It did not reach the network in time and was cancelled. Check the recipient did not receive it before sending again.';

  @override
  String get txDetailsCancelledUnanswered =>
      'The recipient did not answer within 24 hours, so the wallet cancelled it. Nothing was paid, and the coins are spendable again.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'The recipient answered after the 24-hour limit, so the wallet cancelled it instead of finishing it. Nothing was paid, and the coins are spendable again.';

  @override
  String get txDetailsCancelledUndelivered =>
      'It could not be delivered to the recipient, so the wallet cancelled it at once. Nothing was sent, and the coins are spendable again.';

  @override
  String get txDetailsCancelledIncoming =>
      'Cancelled. If the sender posts it later, it still arrives.';

  @override
  String get txStatusSenderCancelled => 'Cancelled by the sender';

  @override
  String get txDetailsSenderCancelledWaiting =>
      'The sender cancelled this payment. The wallet clears it here after checking the network.';

  @override
  String get txDetailsSenderCancelled =>
      'The sender cancelled this payment. If it was posted before that, it still arrives.';

  @override
  String get txDetailsFromBackup =>
      'This payment was imported from a wallet data file and was not finished when that file was exported. This wallet has no record of its own for it, so it cannot tell whether it completed. Nothing is locked.';

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
  String get txWaitNoNewBlock => 'Waiting for the next block to be mined.';

  @override
  String get txWaitNotInBlock =>
      'Not in a block yet. It may still be on its way to the network.';

  @override
  String get txDetailsStuckBody =>
      'The network has not taken this payment. Post it again; it cannot go through twice.';

  @override
  String get txDetailsBroadcastAgain => 'Post again';

  @override
  String get txDetailsBroadcastAgainDone => 'Posted again.';

  @override
  String get txDetailsRefusedBody =>
      'This payment did not go through. The coins it holds can be released.';

  @override
  String get txDetailsReleaseFunds => 'Release coins';

  @override
  String get txDetailsReleaseTitle => 'Release coins?';

  @override
  String get txDetailsReleaseBody =>
      'This payment did not go through, but it still could later.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Keep waiting';

  @override
  String get txDetailsFundsReleased => 'Coins released';

  @override
  String get txDetailsCancelPayment => 'Cancel payment';

  @override
  String get txDetailsCancelTitle => 'Cancel this payment?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Nothing has arrived yet. If this payment still arrives later, it shows as received.';

  @override
  String get txDetailsCancelSendBody =>
      'Nothing has been paid yet: cancelling is free and certain.';

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
  String get txDetailsNoteLabel => 'Private note';

  @override
  String get txDetailsPrivateNoteLabel => 'Private note';

  @override
  String get txDetailsMessageFromSender => 'Message';

  @override
  String get txDetailsMessageFromRecipient => 'Message from the recipient';

  @override
  String get txDetailsYourMessage => 'Message';

  @override
  String get txDetailsMessageHintToRecipient => 'Sent to the recipient';

  @override
  String get txDetailsMessageHintFromSender => 'From the sender';

  @override
  String get txDetailsMessageHintFromRecipient => 'From the recipient';

  @override
  String get txDetailsMessageHintToSender => 'Sent to the sender';

  @override
  String get txDetailsNoNote => 'No note';

  @override
  String get txDetailsAddNote => 'Add note';

  @override
  String get txDetailsEditNote => 'Edit note';

  @override
  String get txDetailsNoteDialogTitle => 'Private note';

  @override
  String get txDetailsNoteHelper =>
      'Only in this app and in the exported wallet data.';

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
      'Found on the chain. Sender and fee are not on the chain; import wallet data to add them.';

  @override
  String get txDetailsSourceImported =>
      'Imported from a wallet data file. Status not checked on the chain.';

  @override
  String get historyTitle => 'Activity';

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
    return 'Nothing matches “$query”.';
  }

  @override
  String get historyBackupSaveDialogTitle => 'Save wallet data';

  @override
  String get importWarnTitle => 'Before you import';

  @override
  String get importWarnEarly => 'This is an early version of a new app.';

  @override
  String get importWarnReads =>
      'Import only reads your old wallets and files and never deletes or changes them.';

  @override
  String get importWarnBackup =>
      'Before you continue, make sure you have a backup of every wallet: its recovery phrase, and its wallet files if you keep them.';

  @override
  String get importWarnRisk =>
      'You import at your own risk, and we take no responsibility for any loss.';

  @override
  String get importWarnRiskPlain =>
      'Importing is at your own risk. No responsibility is taken for any loss.';

  @override
  String get importWarnAck => 'I have a backup of every wallet';

  @override
  String get historyBackupOpenDialogTitle => 'Open wallet data file';

  @override
  String get historyBackupFileTooLarge =>
      'That file is too large to be a wallet data file.';

  @override
  String get historyBackupShare => 'Share';

  @override
  String get historyBackupShareSubtitle =>
      'A copy off this phone, such as email or cloud storage.';

  @override
  String get historyBackupSaveToDevice => 'Save to device';

  @override
  String get historyBackupSaveToDeviceSubtitle => 'Copy it off this phone too.';

  @override
  String historyBackupSaved(String fileName) {
    return 'Saved $fileName';
  }

  @override
  String get historyBackupExportTitle => 'Export wallet data';

  @override
  String get historyBackupCsvTitle => 'Export CSV';

  @override
  String get historyBackupCsvWarning =>
      'Not encrypted: anyone with the file can read amounts, dates, addresses and notes. It cannot be imported; for a backup, use Export wallet data.';

  @override
  String get historyBackupCsvConfirm => 'Export CSV';

  @override
  String get historyBackupImportedTitle => 'Wallet data imported';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Could not import the wallet data. $reason';
  }

  @override
  String get historyBackupImportNothingNew => 'The file held nothing new.';

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
  String get homeBackedUpNotice => 'Recovery phrase backed up';

  @override
  String get homeNoticeView => 'View';

  @override
  String get homeNoticeReceived => 'A payment is on the way.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return 'A payment from $who is on the way.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount on the way.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$amount from $who on the way.';
  }

  @override
  String get homeNoticeSenderPosted => 'Sender reports a payment posted.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Sender reports $amount posted.';
  }

  @override
  String get homeNoticeFinished => 'Payment finished. Confirming.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Payment to $who finished. Confirming.';
  }

  @override
  String get homeNoticeRepeated => 'Already accepted. No second payment.';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return '$who’s payment was already accepted.';
  }

  @override
  String get homeNoticeDelayed => 'Cannot reach the node. The payment waits.';

  @override
  String get homeNoticeRelayProblem =>
      'The Epicbox server reported a problem. Retrying.';

  @override
  String get homeNoticePaymentFailed => 'A payment failed.';

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
      other: '$count payments are not in your exported wallet data.',
      one: '1 payment is not in your exported wallet data.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are new or changed since the last wallet data export.',
      one: '1 payment is new or changed since the last wallet data export.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Not now';

  @override
  String get homeHistoryExportButton => 'Export wallet data';

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
  String balanceExactTip(String amount) {
    return 'Exact amount: $amount';
  }

  @override
  String get homeShowBalances => 'Show balances';

  @override
  String get homeHideBalances => 'Hide amounts';

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
  String get homeBalanceImmature => 'Mining rewards';

  @override
  String get balanceImmatureHelp =>
      'Mining rewards wait a set number of blocks before they can be spent.';

  @override
  String get balanceLineAllConfirmed => 'All confirmed';

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
  String percentValue(String percent) {
    return '$percent%';
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
  String get statusEpicboxBlocked => 'Epicbox blocked';

  @override
  String epicboxBlockedBody(String host) {
    return 'This network blocks $host. A network filter may be the cause. Try another Epicbox server or a private DNS.';
  }

  @override
  String epicboxSwitchTo(String host) {
    return 'Switch to $host';
  }

  @override
  String get netStatusBlocked => 'Blocked';

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
  String get homeEpicboxConnecting => 'Connecting to Epicbox…';

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
  String get homeNoPayments => 'No payments yet';

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
      'No invoices are waiting. When a paired contact you allow asks you to pay, the invoice appears here and nothing is paid until you approve it.';

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
  String invoiceReviewAsks(String service) {
    return '$service asks you to pay';
  }

  @override
  String invoiceReviewMessageLabel(String name) {
    return 'Message from $name';
  }

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
    return 'If $service has not posted it, send the payment again: nothing is signed twice. If it is never posted, Cancel becomes available once the payment’s time runs out, about a day after you paid.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service reports it posted the payment. It completes once the network confirms it.';
  }

  @override
  String invoiceDetailsConfirmed(String service) {
    return 'Paid. The network confirmed the payment to $service.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service has not received your payment yet. Retry sends it again; you do not approve it again.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '$service withdrew this invoice after you paid it.';
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
  String get requestMessageLabel => 'Message to the payer (optional)';

  @override
  String get requestMessageHelper =>
      'The payer sees this message with your invoice.';

  @override
  String get invoicesToPaySection => 'To pay';

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
  String get issuedWithdrawTitle => 'Withdraw this invoice?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer can no longer pay it. Nothing has been paid, so no coins move. This cannot be undone.';
  }

  @override
  String get issuedWithdrawKeep => 'Keep it';

  @override
  String get issuedDetailsSection => 'Invoice';

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
      'The payer declined this invoice, so it was withdrawn. Nothing was paid.';

  @override
  String get issuedDetailsWithdrawn =>
      'You withdrew this invoice. Nothing was paid.';

  @override
  String get issuedDetailsExpired =>
      'This invoice expired before it was paid. Nothing was paid.';

  @override
  String get issuerNoticePaid => 'An invoice you sent was paid.';

  @override
  String get issuerNoticeDeclined => 'An invoice you sent was declined.';

  @override
  String get issuerNoticeWithdrawn =>
      'Invoice withdrawn. It can no longer be paid.';

  @override
  String get issuerNoticeExpired => 'An invoice you sent expired unpaid.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return '$payer’s wallet cannot pay invoices and sent yours back, so it was withdrawn. Ask them to send you the payment instead, to your address or as a transaction file.';
  }

  @override
  String get issuedBounced => 'Sent back';

  @override
  String get issuedDetailsBounced =>
      'The payer’s wallet cannot pay invoices, so nothing was paid. Ask them to send the payment to your address or as a transaction file.';

  @override
  String get txStatusWaitingPayer => 'Waiting for payer';

  @override
  String get txStepRequested => 'Requested';

  @override
  String get txStepPaid => 'Paid';

  @override
  String get txDetailsWaitingPayer =>
      'You asked for this payment. Nothing has arrived yet: it comes when the payer pays the invoice.';

  @override
  String get txDetailsRequestEnded =>
      'This invoice ended unpaid. Nothing arrived.';

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
  String receiveEpicboxConnected(String server) {
    return 'Connected · $server';
  }

  @override
  String get receiveQrLabel => 'QR code of your address';

  @override
  String get receiveAddressLabel => 'Epicbox address';

  @override
  String get receiveEpicboxOfflineBody =>
      'Payments wait on the Epicbox server and arrive when the wallet connects again.';

  @override
  String get receiveShareCardHeadline => 'Pay me in Epic Cash';

  @override
  String get receiveHelpButton => 'How receiving works';

  @override
  String get receiveAddressCopied => 'Address copied';

  @override
  String get receiveFileTitle => 'Receive by transaction file';

  @override
  String get receiveFileBody =>
      'Open the transaction file, or paste its text here.';

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
  String get updateManifestOtherApp =>
      'The update information is for another app.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'The download failed (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge => 'The download is larger than announced.';

  @override
  String get updateDownloadDamaged =>
      'The download is damaged (checksum mismatch).';

  @override
  String get updateDownloadInterrupted => 'The download was interrupted.';

  @override
  String get updateNoTorDownload =>
      'The update cannot be downloaded over Tor yet. Turn Tor off to download it, or get it from the download page.';

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
  String get setupWalletPerNetwork =>
      'Each network has its own wallet. A network without one gets a new wallet.';

  @override
  String get restoreTitle => 'Restore wallet';

  @override
  String get restorePhraseLabel => 'Recovery phrase';

  @override
  String get restorePhraseHelper =>
      'All the words (12, 15, 18, 21 or 24), separated by spaces.';

  @override
  String get restoreStartHeading => 'Where to start scanning';

  @override
  String get restoreStartByDate => 'Date';

  @override
  String get restoreStartByMonth => 'Month';

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
      'Optional. If unsure, pick an earlier date: a later one can miss coins.';

  @override
  String restoreDateStart(String height) {
    return 'Scanning starts two days before this date, from block $height.';
  }

  @override
  String get restoreWholeChain => 'Scan the whole chain instead';

  @override
  String get restorePickMonth => 'Pick the month you created the wallet';

  @override
  String get restorePickMonthShort => 'Pick a month';

  @override
  String get restorePickMonthFirst => 'Pick a month first.';

  @override
  String get restoreMonthHint =>
      'Optional. If unsure, pick an earlier month: a later one can miss coins.';

  @override
  String restoreMonthStart(String height) {
    return 'Scanning starts from block $height.';
  }

  @override
  String get restoreMonthRecent =>
      'A recent month: coins from before it may be missed.';

  @override
  String get restoreMonthEarlierYear => 'Earlier year';

  @override
  String get restoreMonthLaterYear => 'Later year';

  @override
  String get restoreScanIntro =>
      'Looking for this wallet’s coins on the chain. Keep the app open until this finishes.';

  @override
  String get restoreOpenWallet => 'Open wallet';

  @override
  String get restoreUnfinishedTitle => 'Restore not finished';

  @override
  String get restoreUnfinishedRunning =>
      'Looking for this wallet’s coins from block 0. Receiving and sending open when this ends.';

  @override
  String get restoreUnfinishedOffline =>
      'The scan goes on when Offline is off.';

  @override
  String get restoreUnfinishedFailed =>
      'The scan stopped and is retried by itself. Receiving and sending stay closed until it finishes.';

  @override
  String get errorRestoreScanRequired =>
      'Restore not finished. Receiving and sending open when the scan shown on Home ends.';

  @override
  String get restoreScanStop => 'Stop';

  @override
  String get restoreScanScreenOn => 'The screen stays on while this runs.';

  @override
  String get restoreScanStopped =>
      'Stopped. Receiving and sending open only when this scan finishes; it carries on from Home.';

  @override
  String get restoreScanUnfinished =>
      'The scan stopped before the end. Receiving and sending open only when it finishes: try again here, or open the wallet and it carries on from Home.';

  @override
  String get restoreFinishOnHome =>
      'Coins after the chosen start are found. A scan from block 0 now finishes the restore on Home; receiving and sending open when it ends.';

  @override
  String get unlockDatabaseRebuilt =>
      'The wallet database was damaged and has been rebuilt from the phrase. A scan brings the coins back; payment details, notes and labels come back only from a wallet data file.';

  @override
  String get restoreRebuiltImportText =>
      'A wallet data file brings back payment history, contacts, invoices and settings.';

  @override
  String get restoreReplaceLead =>
      'The phrase restores a wallet in place of the one on this phone. Nothing changes before the phrase checks out and the replacement is confirmed.';

  @override
  String get restoreReplacePinReason =>
      'Enter your PIN to replace this wallet. The restored wallet keeps this PIN.';

  @override
  String restorePhraseUnknownWord(int position, String word) {
    return 'Word $position, “$word”, is not in the word list.';
  }

  @override
  String restorePhraseUnknownWords(String words) {
    return 'Not in the word list: $words.';
  }

  @override
  String restorePhraseWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This phrase has $count words. A recovery phrase has 12, 15, 18, 21 or 24.',
      one:
          'This phrase has 1 word. A recovery phrase has 12, 15, 18, 21 or 24.',
    );
    return '$_temp0';
  }

  @override
  String get restorePhraseChecksum =>
      'Every word is in the word list, but the phrase does not check out. A word is wrong or out of order.';

  @override
  String deleteFailedNotice(String error) {
    return 'Wallet not deleted. $error Unlock and try again from Settings.';
  }

  @override
  String get restoreDoneIconLabel => 'Done';

  @override
  String get restoreDoneTitle => 'Your wallet is restored';

  @override
  String get restoreImportExplanation =>
      'The recovery phrase restored the balance. To bring back history, contacts, invoices and settings, import the wallet data file you exported.';

  @override
  String get restoreImportButton => 'Import wallet data';

  @override
  String get restoreImportNotNow => 'Not now';

  @override
  String get restoreImportLater => 'You can import one later from Settings.';

  @override
  String get restoreScanProgressLabel => 'Scan progress';

  @override
  String get firstRunTitle => 'Welcome';

  @override
  String get firstRunCreate => 'Create a new wallet';

  @override
  String get firstRunRestore => 'Restore from phrase';

  @override
  String get settingsRestoreReplaces =>
      'This wallet is removed and the wallet of the typed phrase takes its place, with the same PIN.';

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
      'Anyone who sees the words, or a photo of them, can take the coins.';

  @override
  String get backupConsentTitle => 'Before you see the phrase';

  @override
  String get backupConsentWhat =>
      'The next screen shows the words that restore this wallet.';

  @override
  String get backupConsentReady => 'Have paper and a pen ready.';

  @override
  String get backupCopyAgree => 'I will keep the phrase private';

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
          'Write these $count words on paper, in order. They are the only way to restore this wallet.',
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
      'Anyone with these words can take the coins. Store the copy somewhere safe.';

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
  String get pinBiometricsQuestion => 'Unlock with biometrics?';

  @override
  String get pinBiometricsPinStillWorks => 'The PIN still works.';

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
      'The PIN cannot be recovered. You can delete this wallet from the device and restore it from its recovery phrase. Without the phrase, its coins are lost for good.';

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
  String get scanQrTooltip => 'Scan QR code';

  @override
  String get sendScanButton => 'Scan';

  @override
  String get sendChooseContactTooltip => 'Choose a contact';

  @override
  String get sendContactsButton => 'Contacts';

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
  String get sendPasteResponseLabel => 'Paste the recipient’s response';

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
    return 'Payment of $amount posted to the network.';
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
    return '$amount arrives once the sender finishes the payment and it is on the chain.';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return 'Already accepted. Return $file to the sender again.';
  }

  @override
  String slateRepeatedBody(String amount) {
    return 'You accepted this payment before, so this is the same answer, not a second payment. $amount arrives once the sender finishes it and it is on the chain.';
  }

  @override
  String slateIncomingSend(String amount) {
    return 'Someone is sending you $amount.';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'The recipient’s answer to your send of $amount (fee $fee).';
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
      'The payment is finished but the network has not taken it yet. Post it again from the payment; do not send it again.';

  @override
  String get slateOpenPayment => 'Open the payment';

  @override
  String get scanQrTitle => 'Scan QR code';

  @override
  String get scanQrHint => 'Point the camera at the recipient’s QR code.';

  @override
  String get scanPhraseFoundQr =>
      'This QR code holds a recovery phrase. Keep it private.';

  @override
  String get scanPhraseFoundPasted =>
      'That is a recovery phrase, so it was not pasted. Keep it private.';

  @override
  String get scanQrPhraseHint =>
      'Point the camera at the recovery phrase QR code.';

  @override
  String get restoreScanNoPhrase => 'This QR code holds no recovery phrase.';

  @override
  String get scanQrCameraDenied =>
      'Camera access is off. Allow it in the phone’s settings, or paste the address instead.';

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
      'Show it to the sender’s phone. Only their wallet can use it.';

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
  String get qrHoldHint => 'Hold the other phone’s camera to this code.';

  @override
  String get qrSecureLine => 'Screenshots are off on this screen';

  @override
  String qrTimedOutTitle(int seconds) {
    return 'Hidden after $seconds s';
  }

  @override
  String get qrTimedOutBody => 'Show it again when the other phone is ready.';

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
  String get qrScanGot => 'Code read';

  @override
  String qrScanCount(int got, int count) {
    return '$got of $count';
  }

  @override
  String get qrScanCountLabel => 'Parts read';

  @override
  String get qrScanNotPayment =>
      'That is not a payment QR. Ask them to show the payment QR.';

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
      'Camera access is off. Allow it in the phone’s settings, or open a file instead.';

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
  String get methodArtCaptionQr => 'In person';

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
  String get receiveQrTitle => 'Next to the other phone?';

  @override
  String get receiveQrBody =>
      'Or ask for an amount: show a QR for them to scan.';

  @override
  String get txQrHint =>
      'QR Payment shows the payment as an animated code that the other phone scans with its camera, and takes their reply the same way. It works only between phones next to each other, needs no connection between the two wallets, and the code hides itself after 40 seconds. Adds QR Payment to Send and Receive.';

  @override
  String get advTransactionFiles => 'Direct · File Transfer';

  @override
  String get advTransactionFilesHint =>
      'Adds File Transfer under Settings › Transactions: pay or get paid with a file you pass on yourself.';

  @override
  String get sendMakeQr => 'Make payment QR';

  @override
  String sendQrPinReason(String amount) {
    return 'Enter the PIN to make a payment QR for $amount.';
  }

  @override
  String get sendQrHint =>
      'Show the code to the recipient’s phone, then scan their reply.';

  @override
  String get sendCancelRuleQr => 'Can be cancelled until you scan their reply.';

  @override
  String get qrStatusSendHidden => 'Show this to the recipient.';

  @override
  String get qrStatusSendShowing =>
      'Waiting for the recipient to scan. Then scan their reply.';

  @override
  String get qrStatusHiddenAgain => 'Hidden';

  @override
  String get qrStatusReplyHidden => 'Hidden';

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
  String get contactsAddressInvalidAny =>
      'Not a valid address. Use an Epicbox address (es5x…@server), a Link address (https://…) or an onion address (….onion).';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionDisplay => 'Appearance';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Show prices';

  @override
  String get settingsHideBalances => 'Hide amounts';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPricesOnNotice =>
      'Prices come from CoinGecko, which sees your IP address.';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsBiometrics => 'Unlock with biometrics';

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
  String get settingsSectionHistory => 'Wallet data';

  @override
  String get settingsExportHistory => 'Export wallet data';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsImportHistory => 'Import wallet data';

  @override
  String get settingsSectionWallet => 'This wallet';

  @override
  String get settingsContacts => 'Contacts';

  @override
  String get settingsInvoices => 'Invoices';

  @override
  String get settingsInvoicesSubtitle => 'Who may ask you to pay';

  @override
  String get settingsRescan => 'Recheck balance';

  @override
  String get settingsRescanFinished => 'Balance rechecked';

  @override
  String get settingsRescanTitle => 'Recheck balance';

  @override
  String get settingsRescanBody =>
      'Checks the chain again for this wallet’s coins. An earlier start finds more but takes longer.';

  @override
  String get settingsRescanFromDate => 'From a date';

  @override
  String get settingsRescanFromMonth => 'From a month';

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
  String get settingsRescanButton => 'Recheck';

  @override
  String get settingsDeleteWallet => 'Delete wallet';

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
      'This removes the wallet, its history and its PIN from this phone. Only the recovery phrase can bring the coins back. Without it, they are lost for good.';

  @override
  String get settingsDeleteHavePhrase =>
      'I have written down my recovery phrase';

  @override
  String get settingsDeleteConfirmWord => 'delete';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return 'Type “$word” to confirm';
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
  String settingsUpdatesFrom(String store) {
    return 'Updates come from $store.';
  }

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsSendFeedback => 'Report a problem';

  @override
  String get settingsSendFeedbackHint =>
      'Report a problem or suggest an idea to the developers. Logs go along only if you attach them, with the recovery phrase, PIN and other secrets removed first.';

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get contactLabel => 'Contact';

  @override
  String get settingsLicences => 'Licences';

  @override
  String get licencesLead =>
      'Open-source software in this wallet, each under its own licence.';

  @override
  String get licencesApp => 'Epic Cash Mobile by BT Labs: Apache-2.0.';

  @override
  String get licencesFlutter =>
      'Flutter and its Dart packages: BSD 3-Clause and similar permissive licences.';

  @override
  String get licencesLepic =>
      'LEPIC, the Epic Cash wallet library: Apache-2.0, with the Epic Cash secp256k1-zkp fork (CC0) and Rust crates under MIT or Apache-2.0, among them tokio, rustls, rusqlite and blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, version 3. Its source is named below.';

  @override
  String get licencesFonts =>
      'Fonts Montserrat, JetBrains Mono and Noto Sans Thai: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'All licence texts';

  @override
  String licencesPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licences',
      one: '$count licence',
    );
    return '$_temp0';
  }

  @override
  String get settingsCopyLink => 'Copy link';

  @override
  String get settingsLinkCopied => 'Link copied';

  @override
  String get settingsAddressCopied => 'Address copied';

  @override
  String get settingsCopyAddress => 'Copy address';

  @override
  String get settingsPinTitle => 'Change PIN';

  @override
  String get settingsPinEnterCurrent => 'Enter your current PIN';

  @override
  String get settingsPinCurrentLabel => 'Current PIN';

  @override
  String get settingsPinNewLabel => 'New PIN';

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
  String get helpDonateTitle => 'Support development';

  @override
  String get helpDonateText => 'Donations fund new features.';

  @override
  String get helpDonateCopy => 'Copy address';

  @override
  String get helpDonateCopied => 'Address copied';

  @override
  String get helpSendFeedback => 'Report a problem';

  @override
  String get feedbackTitle => 'Report a problem';

  @override
  String get feedbackIntro =>
      'Describe what went wrong or what could be better.';

  @override
  String get feedbackMessageLabel => 'What happened';

  @override
  String get feedbackMessageMissing => 'Write a few words about what happened.';

  @override
  String get feedbackEmailLabel => 'Contact (optional)';

  @override
  String get feedbackEmailInvalid =>
      'This does not look like an email address.';

  @override
  String get feedbackAttachLogs => 'Attach logs';

  @override
  String get feedbackAttachLogsHint =>
      'The newest part of the app log, without the recovery phrase, PIN and other secrets.';

  @override
  String get feedbackPreviewButton => 'What is sent';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackShareOrSaveInstead => 'Share or save';

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
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsSectionPrivacyNetwork => 'Privacy & network';

  @override
  String get settingsSectionNetworkPrivacy => 'Network & privacy';

  @override
  String get netSummaryTorOn => 'Tor on';

  @override
  String get netSummaryTorOff => 'Tor off';

  @override
  String get netPageServers => 'Servers';

  @override
  String get settingsSectionHelpFeedback => 'Help';

  @override
  String get settingsStateBackUp => 'Back up your recovery phrase';

  @override
  String get settingsStateNotBackedUp => 'Not backed up yet';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String settingsUseStatusSite(String site) {
    return 'Use $site';
  }

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Shows which nodes and Epicbox servers are online, from a public list on status.btlabs.uk.';

  @override
  String get txStepStarted => 'Payment started';

  @override
  String get txStepAccepted => 'Recipient signed';

  @override
  String get txStepPosted => 'Posted to the network';

  @override
  String get txStepConfirming => 'Confirming';

  @override
  String get txStepConfirmed => 'Confirmed';

  @override
  String get txStepArrived => 'Payment arrived';

  @override
  String get txStepSenderFinished => 'Signed and returned';

  @override
  String get fileHelpTitle => 'How a transaction file works';

  @override
  String get fileHelpYou => 'You';

  @override
  String get fileHelpFriend => 'Friend';

  @override
  String get fileHelpSendStep1 => 'You make a transaction file.';

  @override
  String get fileHelpSendStep2 =>
      'You send it to your friend any way you like, such as a chat or an email.';

  @override
  String get fileHelpSendStep3 =>
      'Your friend opens it in their wallet and sends you back the response file.';

  @override
  String get fileHelpSendStep4 =>
      'You open the response file, and the payment is on its way.';

  @override
  String get fileHelpReceiveStep1 =>
      'Your friend makes a transaction file for you.';

  @override
  String get fileHelpReceiveStep2 =>
      'They send it to you any way they like, such as a chat or an email.';

  @override
  String get fileHelpReceiveStep3 =>
      'You open it in your wallet and send back the response file.';

  @override
  String get fileHelpReceiveStep4 =>
      'Your friend opens the response file, and the payment is on its way to you.';

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
  String get sendAddressMissing => 'Enter their address.';

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
  String get sendAddNote => 'Add a message';

  @override
  String get sendNoteLabel => 'Message';

  @override
  String get sendNoteHelper => 'The recipient sees it.';

  @override
  String get sendReviewMessageKept =>
      'The recipient sees it. A copy is kept as your private note.';

  @override
  String get sendNetworkFee => 'Network fee';

  @override
  String get sendChecking => 'Checking…';

  @override
  String get sendReady => 'Ready to send';

  @override
  String get sendNodeDown => 'Cannot reach the network right now.';

  @override
  String sendRelayDown(String relay) {
    return 'Their Epicbox server ($relay) is not answering.';
  }

  @override
  String get sendListenerDown => 'Not connected yet. You can still send.';

  @override
  String get sendPayWithFile => 'Pay with a file instead';

  @override
  String get sendAnyway => 'Send anyway';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Waiting for $name’s wallet';
  }

  @override
  String get sendTrackWaiting => 'Waiting for their wallet';

  @override
  String sendTrackOffline(String amount) {
    return 'Their wallet signs it when it opens. $amount stays locked until then.';
  }

  @override
  String get sendTrackIfNot => 'What if it never finishes?';

  @override
  String get sendTrackCancelled => 'This payment was cancelled.';

  @override
  String get sendNoCoins => 'No coins to send yet.';

  @override
  String get sendFileTitle => 'Direct · File Transfer';

  @override
  String get sendMakeFile => 'Make transaction file';

  @override
  String sendFileOnHold(String amount) {
    return '$amount locked';
  }

  @override
  String get sendFileWaitingReply => 'Waiting for the response file';

  @override
  String get sendFileShareHint =>
      'Send them this file. Then open their response file.';

  @override
  String get sendOpenReply => 'Open response file';

  @override
  String get handshakeRequest => 'Invoice';

  @override
  String get handshakeYou => 'You';

  @override
  String get handshakeThem => 'Them';

  @override
  String get handshakeNetwork => 'Network';

  @override
  String get handshakePay1 =>
      'Your wallet sends the payment to the Epicbox server. The coins are locked.';

  @override
  String get handshakePay2 =>
      'The server passes it on. Their wallet adds its part and signs.';

  @override
  String get handshakeFinish =>
      'Your wallet finishes it and posts it to the network.';

  @override
  String get handshakeConfirm => 'The network confirms it.';

  @override
  String get handshakeReq1 =>
      'Your wallet sends the invoice to the Epicbox server.';

  @override
  String get handshakeReq2 =>
      'The server passes it on. They approve it, and their wallet adds the coins and signs.';

  @override
  String get handshakeRelay => 'Epicbox server';

  @override
  String get handshakeFile => 'File Transfer';

  @override
  String get handshakeBack =>
      'Their wallet sends it back to the Epicbox server.';

  @override
  String get handshakeRelayBack => 'The server passes it back to your wallet.';

  @override
  String get handshakeFile1 =>
      'Your wallet saves a transaction file. You send it to them yourself.';

  @override
  String get handshakeFile2 =>
      'They open it. Their wallet adds its part, signs and saves a response file.';

  @override
  String get handshakeFile3 => 'They send the response file back to you.';

  @override
  String get handshakeFile4 => 'You open their response file in your wallet.';

  @override
  String get handshakePrevious => 'Previous step';

  @override
  String get handshakeLink1 =>
      'Your wallet sends the payment straight to their wallet, over the internet or Tor. The coins are locked.';

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
  String get handshakeQr5 => 'Your wallet posts it to the network.';

  @override
  String get handshakeQrR1 => 'They show their code.';

  @override
  String get handshakeQrR2 => 'You scan it with your wallet.';

  @override
  String get handshakeQrR3 => 'Your wallet shows a reply code.';

  @override
  String get handshakeQrR4 => 'They scan it.';

  @override
  String get handshakeQrR5 => 'Their wallet posts it to the network.';

  @override
  String get handshakeNext => 'Next step';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their Epicbox server ($relay) refused it. The amount stays locked until you cancel it, or for up to $days days.',
      one:
          'Their Epicbox server ($relay) refused it. The amount stays locked until you cancel it, or for up to 1 day.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Their Epicbox server ($relay) refused it. Check Wallet before you send again.';
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
    return '$amount locked';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount coming in';
  }

  @override
  String get demoTestCoinsPill => 'Test coins';

  @override
  String get demoStripeLabel => 'Demo';

  @override
  String get demoTestCoinsPillTip =>
      'Epic’s test network. The coins have no value.';

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
      'Pay a friend’s demo, or open the demo in another browser or a private window.';

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
  String get receiveTorAddressLabel => 'Link · Tor address';

  @override
  String get receiveTorQrLabel => 'QR code of your Tor address';

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
      'Tor could not connect. Retry, or turn Tor off.';

  @override
  String get torFailureClock =>
      'The phone’s clock is wrong. Tor needs the right time.';

  @override
  String get torFailureListener => 'The wallet could not open its Tor address.';

  @override
  String get torFailureStopped => 'Tor stopped.';

  @override
  String get torFailurePublish => 'The Tor address could not be published.';

  @override
  String get torFailureKeys => 'Tor did not accept the wallet’s address key.';

  @override
  String get sendOnionIncomplete =>
      'This is not a complete Tor address. Copy it again from the recipient.';

  @override
  String get sendTorUnavailable =>
      'This app cannot send over Tor, so a Tor address cannot be paid here.';

  @override
  String get sendOverTor => 'Over Tor';

  @override
  String get sendTorReady => 'Ready to send over Tor';

  @override
  String get sendTorReaching =>
      'Reaching their wallet over Tor… Keep the app open.';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their wallet was not reached over Tor. The amount stays locked until you cancel it, or for up to $days days.',
      one: 'Their wallet was not reached over Tor. The amount stays locked until you cancel it, or for up to 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get sendTorTryEpicbox =>
      'Epicbox delivers a payment while their wallet is offline.';

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Nothing was sent.';
  }

  @override
  String get sendTryAgain => 'Try again';

  @override
  String get sendCancelPayment => 'Cancel payment';

  @override
  String get homeAvailableToSpend => 'Available to spend';

  @override
  String get homeTileWaitingSender => 'Waiting for sender';

  @override
  String get homeTileLocked => 'Locked in sends';

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
  String get tourPhoneSkip => 'Skip tour';

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
      'Paste or scan an address, or pick a contact. Epicbox pays an address; QR shows a code to a phone next to you. More ways: Settings › Transactions. A review comes first.';

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
  String get tourPhoneInvoicesTitle => 'Invoices';

  @override
  String get tourPhoneInvoicesText =>
      'Pay an invoice someone sent, or ask someone for a payment. The tabs switch between the two.';

  @override
  String get tourPhoneDevicesText =>
      'This wallet on a second device: each shows the other’s payments. An experiment.';

  @override
  String get tourPhonePrivacyTitle => 'Privacy & network';

  @override
  String get tourPhonePrivacyText =>
      'Which node and Epicbox server the wallet uses, and the Tor switch. Tap a server to change it.';

  @override
  String get tourPhoneNetworkText =>
      'The network mode, the Tor switch and the servers the wallet uses. Tap a server to change it.';

  @override
  String get tourPhoneNetworkTextNoTor =>
      'The network mode and the servers the wallet uses. Tap a server to change it.';

  @override
  String get tourPhoneAdvancedTitle => 'Advanced';

  @override
  String get tourPhoneAdvancedText =>
      'Tor-only mode, outputs and technical details live here. Switch on what you need.';

  @override
  String get tourAdvancedShowsText =>
      'Outputs and technical details live here. Switch on what you need.';

  @override
  String get tourPhoneHelpTitle => 'Help';

  @override
  String get tourPhoneHelpText =>
      'Help topics, Report a problem and Show the tour again.';

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
    return 'Enter the PIN to make a transaction file for $amount.';
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
  String outputsWaitLocked(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '$blocks confirmation',
    );
    return 'Wait until the payment in progress has $_temp0.';
  }

  @override
  String get outputsStrategy => 'Strategy for sends';

  @override
  String get outputsStrategyHint =>
      'Which outputs a send spends. Smallest spends the smallest outputs that cover the amount; All spends every output and returns one.';

  @override
  String get outputsSmallest => 'Smallest';

  @override
  String get outputsAll => 'All';

  @override
  String get outputsSmallestText =>
      'Spends the smallest outputs that cover the amount; the rest stays spendable.';

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
  String get outputsWordFinalizing => 'Waiting for the response';

  @override
  String get outputsWordImmature => 'Maturing';

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
  String get outputsEmptyHint => 'The first payment received makes one.';

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
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks blocks',
      one: '$blocks block',
    );
    return 'Spends $spent ($amount) and makes $made of about $each each. A normal network transaction to this wallet, confirmed after $_temp0 like any send; everything spendable is locked until then. More outputs let the next sends go out without waiting for each other’s change.';
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
  String outputsFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks blocks',
      one: '$blocks block',
    );
    return '$amount, about $_temp0';
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
  String outputsConsolidateText(
    String amount,
    String result,
    String spent,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '$blocks confirmation',
    );
    return 'Spends $spent ($amount) and makes one output of $result. Everything spendable is locked for $_temp0.';
  }

  @override
  String get outputsConsolidateAction => 'Consolidate';

  @override
  String get outputsSplitPin => 'Confirm with your PIN to split outputs';

  @override
  String get outputsConsolidatePin =>
      'Confirm with your PIN to consolidate outputs';

  @override
  String outputsSplitStarted(int count, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks blocks',
      one: '$blocks block',
    );
    return 'Split started: $count outputs, confirming in about $_temp0';
  }

  @override
  String outputsConsolidateStarted(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks blocks',
      one: '$blocks block',
    );
    return 'Consolidate started: one output, confirming in about $_temp0';
  }

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
    return '$amount stays locked until the recipient’s wallet answers.';
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
  String get contactsNoteHeading => 'Note';

  @override
  String get contactsShowCode => 'Show code';

  @override
  String contactsQrLabel(String name) {
    return 'QR code of $name’s address';
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
  String get invoicesNewRequest => 'New invoice';

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
  String get invoicesSentEmpty => 'No invoices sent';

  @override
  String get invoicesSentEmptyCaption =>
      'An invoice asks someone to pay you an amount.';

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
  String get invoicesNodeOk => 'Synced';

  @override
  String get invoicesNodeDown => 'Not responding';

  @override
  String get invoicesEpicboxOk => 'Connected';

  @override
  String get invoicesEpicboxDown => 'Not connected';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer is asked to pay $amount. The invoice expires in 24 h.';
  }

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
    return 'Syncing $percent%';
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
  String get netStatusOff => 'Off';

  @override
  String get netStatusConnected => 'Connected';

  @override
  String get netStatusNotConnected => 'Not connected';

  @override
  String get stateReceiving => 'Receiving';

  @override
  String get stateUnchecked => 'Not checked';

  @override
  String get serverUpNotConnected => 'Server up · not connected';

  @override
  String get netStatusOn => 'On';

  @override
  String get netStatusTitle => 'Network status';

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
  String serverTestFailed(String error) {
    return 'No answer. $error';
  }

  @override
  String serverHealthUnknown(String site) {
    return '$site not reachable; health unknown';
  }

  @override
  String get serverAtTip => 'synced';

  @override
  String serverBehindShort(String count) {
    return '$count behind';
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
  String get serverNotResponding => 'Not answering';

  @override
  String get serverLocalNotReachable => 'Not reachable from this computer';

  @override
  String get serverLocalNotReachablePhone => 'Not reachable from this phone';

  @override
  String get serverHealthy => 'Healthy';

  @override
  String get serverDegraded => 'Behind';

  @override
  String get serverHealthNone => 'Status unknown';

  @override
  String get serverCurrent => 'In use';

  @override
  String get serverDefault => 'Default';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return '$percent% up';
  }

  @override
  String get serverAdd => 'Add';

  @override
  String get serverAlreadyInUse => 'Already in use.';

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
    return '$height · synced';
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
  String serverCheckedAt(String time, String site) {
    return '$site, checked $time';
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
  String get methodArtCaptionFile => 'File out, response back';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: the payment goes to the Epicbox server, which holds it until the recipient’s wallet is back';

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
  String get methodSendFileTitle => 'No connection needed.';

  @override
  String get methodSendFileLine =>
      'Hand the file over, get their response file back, then open it here.';

  @override
  String get methodReceiveEpicboxTitle => 'Share it to get paid.';

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
  String get sendSwitchedEpicbox => 'Via Epicbox';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Epicbox address. Method set to Epicbox.';

  @override
  String get sendCancelRuleEpicbox =>
      'Can be cancelled while it waits for the recipient.';

  @override
  String get sendCancelRuleDirect =>
      'Cannot be cancelled once their wallet accepts it.';

  @override
  String get sendCancelRuleFile =>
      'Can be cancelled until you open the response file.';

  @override
  String get sendHttpReaching => 'Reaching their wallet… Keep the app open.';

  @override
  String get sendDeliveredWaitingBlock => 'Delivered · Waiting for a block';

  @override
  String get sendPlainHttpOffWithTor =>
      'Plain http:// does not work with Tor on.';

  @override
  String get sendPlainHttpOffWithTorWhy =>
      'Use an https:// or onion address, or Epicbox.';

  @override
  String get receiveTorCaption =>
      'Some wallets show the address without .onion; both are the same address.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Their wallet was not reached. The amount stays locked until you cancel it, or for up to $days days.',
      one: 'Their wallet was not reached. The amount stays locked until you cancel it, or for up to 1 day.',
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
      'The lists show what arrived before; the wallet retries.';

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
  String get deskInvPayNotDelivered => 'Not delivered';

  @override
  String get deskInvPayDelivered => 'Waiting to post';

  @override
  String deskInvPayPosted(String name) {
    return 'Posted by $name';
  }

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
  String get deskInvFailed => 'That did not work. Nothing changed; try again.';

  @override
  String get deskInvHowItWorks => 'How invoices work';

  @override
  String get deskInvIssuerSoon => 'Coming soon';

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
    return '$used / $max bytes';
  }

  @override
  String get deskInvIssuerMessageLong => 'The message is too long.';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'The payer has $hours hours to pay.';
  }

  @override
  String get deskInvIssuerRelayDown =>
      'The Epicbox server is not answering, so an invoice cannot go out now.';

  @override
  String get deskInvIssuerNotDelivered =>
      'The invoice did not reach the Epicbox server. Nothing was sent. Try again.';

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
    return '$payer can no longer pay it. Nothing has been paid, so no coins move.';
  }

  @override
  String get deskInvIssuerKeep => 'Keep it';

  @override
  String get deskInvIssuerWithdrawn => 'Invoice withdrawn.';

  @override
  String get deskInvIssuerRepost => 'Post again';

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
    return 'It will not arrive. $payer’s coins stay locked in their wallet until they cancel on their side.';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return '$payer’s wallet cannot pay invoices; ask $payer to send a payment instead.';
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
    return 'Delivered to $payer’s Epicbox server. Nothing is paid until they approve it.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Copy slate ID';

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
      'A payment for an invoice this device did not issue arrived. It stays on the server for a day for your other device with this wallet: open the wallet there to finish it.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'An answer to a payment this device did not send arrived. It stays on the server for a day for your other device with this wallet: open the wallet there to finish it.';

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
  String get deskInvPayerEmptyTitle => 'No invoices are waiting';

  @override
  String get deskInvPayerEmptyText =>
      'Invoices from allowed paired contacts appear here; nothing is paid without approval.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Your payment to $service was not delivered';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'It is signed and kept on this computer; the EPIC stays locked. Retry sends it again without a second approval.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service withdrew an invoice you paid';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'The payment may never reach the chain. Cancel it to free the coins.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Your payment to $service is not on chain';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Its time passed and the network has not seen it. Cancel it to free the coins.';

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
  String deskInvPayerMessageCaption(String name) {
    return 'Written by $name. Your wallet does not check it.';
  }

  @override
  String get deskInvPayerPaysTo => 'Pays to';

  @override
  String get deskInvPayerExpires => 'Expires';

  @override
  String get deskInvPayerLockHeight => 'Lock height';

  @override
  String get deskInvPayerLockNone => 'None';

  @override
  String get deskInvPayerReceived => 'Received';

  @override
  String get deskInvPayerShort => 'Not enough spendable EPIC';

  @override
  String deskInvPayerShortText(
    String total,
    String spendable,
    int confirmations,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'once they have $confirmations confirmations',
      one: 'once they have 1 confirmation',
    );
    return 'You need $total EPIC spendable; you have $spendable EPIC. Funds still confirming count $_temp0.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'The node is not answering';

  @override
  String get deskInvPayerNodeDownText =>
      'The wallet cannot check the balance, so it cannot pay. Approve works again once the node answers; you can pick another node in Settings › Node.';

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
      'The Epicbox server is not answering. Retry it under Invoices › Pay; no second approval.';

  @override
  String get deskInvPayerRetryFailed => 'Still not delivered';

  @override
  String get deskInvPayerRetryFailedText =>
      'The Epicbox server is not answering. The payment stays signed on this device.';

  @override
  String get deskInvPayerCancelTitle => 'Cancel this payment?';

  @override
  String get deskInvPayerCancelText =>
      'The other side can still finish this payment.';

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
  String get deskInvPayerCancelledText => 'The coins are unlocked.';

  @override
  String get deskInvPayerDeclined => 'Invoice declined. Nothing was paid.';

  @override
  String get deskInvPayerSpentText =>
      'The coins are on their way back to this wallet.';

  @override
  String get deskInvPayerSpendFailedText =>
      'The coins could not be moved back yet. The wallet tries again while it is open; until then the payment may still finish.';

  @override
  String get deskInvPayerLocked =>
      'This invoice cannot be paid: it is locked until a later block. Nothing was paid.';

  @override
  String get deskInvPayerRelayDownPay =>
      'The Epicbox server is not answering. Nothing was paid.';

  @override
  String get deskInvSetTitle => 'Invoices';

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
  String get deskInvSetReceiveHint =>
      'Ask a paired contact to pay you, or save the invoice as a file.';

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
  String get sendAvailableWhileConfirms => 'Available while this confirms';

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
  String methodDirectShape(String port) {
    return 'http://host:$port or xxxx….onion';
  }

  @override
  String get methodSendDirectLine =>
      'Their wallet must be open. An onion address goes over Tor.';

  @override
  String methodArtSpokenLink(String method) {
    return '$method: the payment goes straight to the recipient’s wallet, which must be open';
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
  String get methodReceiveEpicboxShort => 'Share the address to get paid.';

  @override
  String get methodReceiveEpicboxMore =>
      'The Epicbox server holds a payment until this wallet opens.';

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
  String get torNotOverTor => 'Without Tor';

  @override
  String get torNeeds => 'Link · Tor needs Tor.';

  @override
  String get torTurnOn => 'Turn on Tor';

  @override
  String get torTurnOff => 'Turn Tor off';

  @override
  String get torTurnOffCaption =>
      'Applies to every connection, not only this payment.';

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
  String get torNetworkLabel => 'Tor network';

  @override
  String get torNetworkHint =>
      'Network activity goes through the Tor network. Tor hides the wallet’s IP address: each connection passes through several volunteer-run relays, so no server learns where the wallet is. To get paid at a Tor address, turn on Link · Tor in Settings › Transactions.';

  @override
  String get receiveTabDirect => 'Link';

  @override
  String get receiveDirectNeedsTor => 'Link · Tor needs Tor.';

  @override
  String get receiveDirectMeanwhile => 'Meanwhile, share the Epicbox address.';

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
    return 'Port $port is in use by another program.';
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
  String get deskErrNotEnoughFunds => 'Not enough EPIC';

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
      'The recipient’s wallet is not reachable over Tor. Epicbox delivers a payment while it is offline';

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
  String get deskErrTorNetwork => 'Cannot reach the Tor network';

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
  String get deskErrTestNet => 'This is a test wallet and cannot be imported.';

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
  String get deskErrProofSeedRead => 'Recovery phrase read';

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
      'History in an older database format is not readable; the scan restores the balance';

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
      'File not saved. The payment waits in Activity; cancel it there to free the coins.';

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
      'The recipient’s wallet did not answer or refused. The payment waits in Activity; cancel it there to free the coins.';

  @override
  String get deskErrNotDelivered =>
      'Not delivered. The payment waits in Activity; cancel it there to free the coins.';

  @override
  String get deskErrInterruptedLock =>
      'Interrupted by the lock. It may have gone out: check Activity after unlocking.';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail. The payment waits in Activity; cancel it there to free the coins.';
  }

  @override
  String get deskErrNodeRefused =>
      'Signed by both wallets, but the node refused it. Cancel it in Activity to free the coins.';

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
    return 'Connecting to Tor… $percent%';
  }

  @override
  String get deskErrHistOtherWallet => 'Another wallet’s data';

  @override
  String get deskErrHistOtherChain => 'Wrong network';

  @override
  String get deskErrHistNotOurs => 'Not a wallet data file';

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
  String get deskErrHistChains => 'The file is from another network.';

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
    return 'Update server error ($status).';
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
  String get deskNodeAtTip => 'synced';

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
  String get deskNodeStartIt => 'Start it under Settings › Node.';

  @override
  String deskNodeFailPort(String port) {
    return 'port $port is in use by another program';
  }

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
  String get deskNodeStageKernels => 'checking the chain';

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
    return 'Checking the chain · $done of $total million';
  }

  @override
  String get deskNodeLineKernelsBare => 'Checking the chain';

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
  String deskNodeDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String deskNodeDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String get deskTorNetworkLabel => 'Tor network';

  @override
  String get deskTorNetworkHint =>
      'Network activity goes through the Tor network. Tor hides the wallet’s IP address: each connection passes through several volunteer-run relays, so no server learns where the wallet is.';

  @override
  String get deskTorOff => 'Off';

  @override
  String get deskTorStarting => 'Starting…';

  @override
  String get deskTorOn => 'On';

  @override
  String get deskTorNotConnected => 'Not connected';

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
  String get deskRecvTorDownText =>
      'Tor could not connect. Retry, or turn Tor off.';

  @override
  String get deskRecvTorStartingText =>
      'Addresses become reachable when Tor connects.';

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
  String get deskRecvEpicboxIntro => 'Share it to get paid.';

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
      'Programs on this computer can pay this address. For other devices, see Settings › Transactions.';

  @override
  String get deskRecvHttpIntro =>
      'For wallets on this computer, while this wallet is open.';

  @override
  String get deskRecvHttpTorHint =>
      'Turn on Tor in Settings › Privacy for a Tor address instead.';

  @override
  String get deskRecvDirectTor => 'Link · Tor address';

  @override
  String get deskRecvTorIntro =>
      'Straight from another wallet over Tor while this one is open. Tor is set in Settings › Privacy.';

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
      'Sign the sender’s transaction file and save the response file.';

  @override
  String get deskRecvOpen => 'Open';

  @override
  String get deskRecvFinalizeTitle => 'Finalize a response file';

  @override
  String get deskRecvFinalizeText =>
      'Finalize the recipient’s response file to post the payment.';

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
  String get deskSendSpendableWhile => 'Available while this confirms';

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
  String deskSendLockAll(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'about $blocks blocks',
      one: 'about 1 block',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'about $blocks blocks',
      one: 'about 1 block',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Everything is locked: $count outputs, $amount EPIC, $_temp0.',
      one: 'Everything is locked: 1 output, $amount EPIC, $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String deskSendLockSome(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'about $blocks blocks',
      one: 'about 1 block',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'about $blocks blocks',
      one: 'about 1 block',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs locked, $amount EPIC, $_temp0.',
      one: '1 output locked, $amount EPIC, $_temp1.',
    );
    return '$_temp2';
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
  String deskSendReviewSetAsideNone(String locked) {
    return '$locked EPIC goes out as it is; nothing is set aside.';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Everything: $locked EPIC in $count outputs until the change confirms $_temp0. Nothing stays spendable.',
      one:
          'Everything: $locked EPIC in 1 output until the change confirms $_temp1. Nothing stays spendable.',
    );
    return '$_temp2';
  }

  @override
  String deskSendReviewSetAsideAll(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    return 'Everything: $locked EPIC is set aside until this payment confirms $_temp0. Nothing stays spendable.';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count outputs until the change confirms $_temp0. Nothing else is spendable meanwhile.',
      one:
          '$locked EPIC in 1 output until the change confirms $_temp1. Nothing else is spendable meanwhile.',
    );
    return '$_temp2';
  }

  @override
  String deskSendReviewSetAsideEverything(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    return '$locked EPIC is set aside until this payment confirms $_temp0. Nothing else is spendable meanwhile.';
  }

  @override
  String deskSendReviewLocksSome(
    int count,
    String locked,
    String spendable,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count outputs until the change confirms $_temp0. $spendable EPIC stays spendable.',
      one:
          '$locked EPIC in 1 output until the change confirms $_temp1. $spendable EPIC stays spendable.',
    );
    return '$_temp2';
  }

  @override
  String deskSendReviewSetAsideSome(
    String locked,
    int blocks,
    String spendable,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks blocks)',
      one: '(1 block)',
    );
    return '$locked EPIC is set aside until this payment confirms $_temp0. $spendable EPIC stays spendable.';
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
      'Spends the smallest outputs that cover the amount; the rest stays spendable.';

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
  String get deskSendErrOwn => 'This is the wallet’s own address.';

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
      'Give this file to the recipient, then finalize with their response file.';

  @override
  String get deskSendFinalize => 'Finalize';

  @override
  String get deskSendNewSend => 'Send another';

  @override
  String get deskSendNodeNotSynced => 'Node not synced';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Sending resumes when the node is synced ($percent%).';
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
  String get deskSendTorStartingText => 'Sending waits for Tor.';

  @override
  String get deskSendEpicboxOff => 'Epicbox not connected';

  @override
  String get deskSendEpicboxOffText =>
      'Turn on Epicbox receiving to send by Epicbox, or use Direct · File Transfer.';

  @override
  String deskSendEpicboxOffTab(String method) {
    return 'Turn on Epicbox receiving to send by Epicbox, or use $method.';
  }

  @override
  String get deskSendEpicboxTurnOn => 'Turn on Epicbox receiving';

  @override
  String get deskSendDoneViaDirect => 'Finalized and posted to the network.';

  @override
  String get deskSendDoneViaEpicbox =>
      'Handed to Epicbox. Completes when the recipient answers.';

  @override
  String get deskSendViewTx => 'View in Activity';

  @override
  String get deskSendFailedTitle => 'Send failed';

  @override
  String get deskSendReviewAgain => 'Review again';

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
  String get deskSendNeedsTor => 'Link · Tor needs Tor';

  @override
  String get deskSendNeedsTorText =>
      'An onion address can only be reached over Tor.';

  @override
  String get deskSendNoTorBuild => 'Tor is not in this build.';

  @override
  String get deskSendTurnOnTor => 'Turn on Tor';

  @override
  String get deskSendHttpClearnet => 'Link · HTTP goes directly, without Tor.';

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
  String get deskSendAllButton => 'Max';

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
  String get deskSendMessageHelp => 'The recipient sees it.';

  @override
  String get deskSendPrivacyOn => 'Privacy · Dandelion++ on';

  @override
  String get deskSendPrivacyOff => 'Privacy · Dandelion++ off';

  @override
  String get deskSendDandelionText =>
      'Passes the transaction through a few random nodes before it spreads, so the network cannot tell where it came from.';

  @override
  String get deskSendHintSent => 'Sent.';

  @override
  String get deskSendHintQueued =>
      'Queued. Enter a new amount and recipient to send again.';

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
  String get deskSendHintFix => 'Fix the marked fields.';

  @override
  String get deskSendHintChecking => 'Checking the fee for this amount.';

  @override
  String get deskSendHintDefault => 'Nothing is sent before the review.';

  @override
  String get deskSendReviewWaitTor => 'Waiting for Tor';

  @override
  String get deskSendReviewTorOff => 'Tor not connected';

  @override
  String get deskSendReview => 'Review';

  @override
  String get deskSendSummary => 'Summary';

  @override
  String get deskSendNetworkFee => 'Network fee';

  @override
  String get deskSendTotal => 'Total';

  @override
  String get deskSendUpdating => 'Balance updating while the wallet scans.';

  @override
  String get deskSendEpicboxLine2 =>
      'The Epicbox server holds the payment until they open their wallet.';

  @override
  String get deskSendDirectLine1 => 'Straight to their wallet.';

  @override
  String get deskSendDirectLine2 =>
      'Their wallet must be open. An onion address goes over Tor.';

  @override
  String get deskSendFileLine1 => 'No connection needed.';

  @override
  String get deskSendFileLine2 =>
      'Hand the file over, get their response file back, then finalize it here.';

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
  String get deskFinPosted => 'Payment posted';

  @override
  String get deskFinTitle => 'Finalize a response file';

  @override
  String get deskFinNoticeTitle => 'For file payments';

  @override
  String get deskFinNoticeText =>
      'Use the response file the recipient sent back.';

  @override
  String get deskFinTryAgain => 'Try again';

  @override
  String get deskFinPostedText =>
      'The payment was finalized and posted to the network. Follow it in Activity.';

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
      'Not a transaction file. Choose the .tx file the sender gave.';

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
  String get deskActSearchHint => 'Search payments';

  @override
  String get deskActSearchLabel => 'Search payments';

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
  String get deskActDetailReceived => 'Incoming payment';

  @override
  String get deskActDetailSent => 'Outgoing payment';

  @override
  String get deskActLoading => 'Loading payments';

  @override
  String get deskActWaitingNode => 'Waiting for the node to sync.';

  @override
  String get deskActFilterAll => 'All';

  @override
  String get deskActFilterReceived => 'Received';

  @override
  String get deskActFilterSent => 'Sent';

  @override
  String deskActNoMatchTitle(String query) {
    return 'Nothing matches “$query”.';
  }

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
  String get deskActEmptyTitle => 'No payments yet';

  @override
  String get deskActEmptyText => 'Payments sent and received, newest first.';

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
  String get deskConNone => 'No contacts yet';

  @override
  String get deskConNoMatchList => 'No contacts match';

  @override
  String get deskConAdd => 'Add contact';

  @override
  String get deskConIdle => 'Choose a contact.';

  @override
  String get deskConEmptyTitle => 'No contacts yet';

  @override
  String get deskConEmptyText => 'A contact is a name for an address.';

  @override
  String get deskConSendToAddress => 'Send to address';

  @override
  String deskConLastTx(String when) {
    return 'Last payment: $when';
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
  String get deskConNote => 'Note';

  @override
  String deskConTxWith(String name) {
    return 'Payments with $name';
  }

  @override
  String get deskConAllTx => 'All payments';

  @override
  String get deskConTxNone =>
      'No payments with this contact yet. Payments sent to them from Send appear here.';

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
      'Not a valid address. Use an Epicbox address (es5x…@server), a Link address (https://…) or an onion address (….onion).';

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
      'Removes the contact; past payments stay in Activity. This cannot be undone.';

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
      'Outputs are the pieces the balance is made of. A send spends whole outputs and returns the change as a new one.';

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
  String deskOutCardWait(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'about $blocks blocks',
      one: 'about 1 block',
    );
    return 'Wait until the send confirms ($_temp0).';
  }

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
      other: 'Spends $count outputs. Fee at least $fee EPIC.',
      one: 'Spends $count output. Fee at least $fee EPIC.',
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
  String get deskOutNoneText => 'The first payment received makes one.';

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
  String get deskOutTileImmature => 'Mining rewards';

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
  String get deskOutStatusAwaiting => 'Waiting for the response';

  @override
  String get deskOutNoteWaitingSender => 'waiting for the sender';

  @override
  String get deskOutStatusUnpaid => 'Unpaid invoice';

  @override
  String get deskOutNoteNotInBalance => 'not in the balance';

  @override
  String get deskOutStatusImmature => 'Maturing';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number confirmations to go',
      one: '$number confirmation to go',
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
  String deskOutNoteByPendingSend(String date) {
    return 'by a pending send · $date';
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
  String deskOutSplitDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '1 confirmation',
    );
    return 'Spends $spent and makes $made each. Everything spendable is locked for $_temp0.';
  }

  @override
  String deskOutConsDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '1 confirmation',
    );
    return 'Spends $spent and makes $made. Everything spendable is locked for $_temp0.';
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
  String deskOutFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'about $blocks blocks',
      one: 'about 1 block',
    );
    return '$amount EPIC, $_temp0. Nothing stays spendable.';
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
  String get deskOutConsPosted => 'Consolidation posted';

  @override
  String deskOutSplitDoneText(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '1 confirmation',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '1 confirmation',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count outputs of about $amount EPIC, confirming. Locked for $_temp0.',
      one:
          '$count output of about $amount EPIC, confirming. Locked for $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String deskOutConsDoneText(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks confirmations',
      one: '1 confirmation',
    );
    return 'One output of $amount EPIC, confirming. Locked for $_temp0.';
  }

  @override
  String get deskOutNotPostedTitle => 'Not posted';

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
  String get deskOutPostingDesc => 'Posting';

  @override
  String get deskOutDoneDesc => 'Done';

  @override
  String get deskOutSplitDesc =>
      'More outputs, so several sends can follow each other.';

  @override
  String get deskOutConsDesc => 'One output instead of many.';

  @override
  String deskOutNothingText(String what) {
    return 'Nothing to consolidate: the wallet has $what.';
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
  String deskOvNodeAddrText(String node) {
    return 'Saved as $node.';
  }

  @override
  String get deskOvNodeIncompatTitle => 'Node version not compatible';

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
    return 'Cannot reach the node at $url';
  }

  @override
  String get deskOvCantReachNodeText =>
      'Balances may be out of date. Check the node, or choose another in Node settings.';

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
  String get deskOvSyncText => 'Downloading blocks.';

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
  String get deskOvSendWaits => 'Sending resumes when the node is synced.';

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
  String get deskOvFiatNote => '  whole balance';

  @override
  String get deskOvBreakTotal => 'Total';

  @override
  String get deskOvBreakConfirming => 'Confirming';

  @override
  String get deskOvBreakImmature => 'Mining rewards';

  @override
  String get deskOvBreakAwaiting => 'Waiting for sender';

  @override
  String get deskOvBreakLocked => 'Locked in sends';

  @override
  String get deskOvUpdating => 'Updating';

  @override
  String get deskOvHiddenAmount => 'Hidden amount';

  @override
  String get deskOvLoading => 'Loading payments';

  @override
  String get deskOvEmptyTitle => 'No payments yet';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Received EPIC shows as confirming, then spendable after $blocks confirmations.',
      one:
          'Received EPIC shows as confirming, then spendable after $blocks confirmation.',
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
      other: '$count file payments to finalize',
      one: '$count file payment to finalize',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText =>
      'Finalize with the response file from the recipient.';

  @override
  String get deskOvFinalize => 'Finalize';

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
  String get deskTxNoteBlock => 'Time of the block. The sender is unknown.';

  @override
  String get deskTxNoteScanTime =>
      'Time of the scan; the block’s time could not be read. The sender is not recorded.';

  @override
  String get deskTxNoteUnknown => 'The sender is not recorded.';

  @override
  String get deskTxFoundRestoredLabel => 'Restored';

  @override
  String get deskTxFoundRestoredLine => 'Found on the chain';

  @override
  String get deskTxFoundRestoredStep => 'Found on the chain';

  @override
  String get deskTxFoundRestoredTip =>
      'Found on the chain while restoring this wallet. The sender is not recorded.';

  @override
  String get deskTxFoundRescanLabel => 'Found by recheck';

  @override
  String get deskTxFoundRescanLine => 'Found by recheck';

  @override
  String get deskTxFoundRescanStep => 'Found by recheck';

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
  String get deskTxBackupTip => 'Imported from a wallet data file.';

  @override
  String get deskTxFromBackup => 'Imported';

  @override
  String get deskTxStatusImmature => 'Maturing';

  @override
  String get deskTxStatusWaitingSender => 'Waiting for sender';

  @override
  String get deskTxStatusWaitingResponseFile => 'Waiting for the response file';

  @override
  String get deskTxStatusWaitingRecipient => 'Waiting for recipient';

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
  String get deskTxNowBackup =>
      'Imported from a wallet data file. Status not checked on the chain.';

  @override
  String deskTxNowImmature(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Confirmed, but a mining reward is spendable only after $countString confirmations.',
      one:
          'Confirmed, but a mining reward is spendable only after $countString confirmation.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender => 'Waiting for the sender to post it.';

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
    final intl.NumberFormat confirmationsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String confirmationsString = confirmationsNumberFormat.format(
      confirmations,
    );

    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Confirmed, $confirmationsString confirmations.',
      one: 'Confirmed, $confirmationsString confirmation.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Cancelled';

  @override
  String get deskTxNotCancelled => 'Not cancelled';

  @override
  String get deskTxCancelled => 'Transaction cancelled';

  @override
  String get deskTxCancelling => 'Cancelling';

  @override
  String get deskTxHeadRestored => 'restored';

  @override
  String get deskTxHeadFoundOnChain => 'Found on the chain';

  @override
  String get deskTxHeadBackup => 'imported from a wallet data file';

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
  String get deskTxSignedByRecipient => 'Recipient signed';

  @override
  String get deskTxTechTitle => 'Technical details';

  @override
  String get deskTxStepMined => 'Mined in a block';

  @override
  String get deskTxStepSpendable => 'Completed';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmations to go',
      one: '$count confirmation to go',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Payment arrived';

  @override
  String get deskTxStepCreated => 'Payment started';

  @override
  String get deskTxStepSignedReturned => 'Signed and returned';

  @override
  String get deskTxStepWaitingFile => 'Waiting for the response file';

  @override
  String get deskTxStepWaitingRecipient => 'Waiting for recipient';

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
  String get deskTxCancelOutgoingTitle => 'Cancel this payment?';

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC to $who. Nothing has been paid yet: cancelling is free and certain.';
  }

  @override
  String get deskTxCancelKeep => 'Keep';

  @override
  String get deskTxCancelIncomingAction => 'Cancel payment';

  @override
  String get deskTxCancelOutgoingAction => 'Cancel payment';

  @override
  String get deskOnbWelcomeAdd => 'Add a wallet';

  @override
  String get deskOnbWelcomeTagline =>
      'Keys and coins stay on this computer, locked with a password.';

  @override
  String get deskOnbWelcomeCreate => 'Create a new wallet';

  @override
  String get deskOnbWelcomeImport => 'Import wallets';

  @override
  String get deskOnbWelcomeImportSub => 'From an older Epic Wallet or a folder';

  @override
  String get deskOnbWelcomeCreateSub => 'With a new recovery phrase';

  @override
  String get deskOnbWelcomeRestoreSub => 'Also from Stack Wallet or Epic Pay';

  @override
  String get deskOnbWelcomeRestore => 'Restore from phrase';

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
  String get deskOnbCreateStageCreate => 'Making the recovery phrase';

  @override
  String get deskOnbCreateStageSave => 'Saving the wallet';

  @override
  String get deskOnbCreateNotCreated => 'Wallet not created';

  @override
  String get deskOnbCreateCreating => 'Creating the wallet';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'A wallet on $network, a test network.';
  }

  @override
  String get deskOnbCreateDiskFull =>
      'Wallet not saved: the disk is full. Free some space, then try again.';

  @override
  String get deskOnbCreateWait => 'Keep the app open.';

  @override
  String get deskOnbCreateLocking => 'Locking the open wallet';

  @override
  String get deskOnbCreateSide => 'New wallet';

  @override
  String get deskOnbCreateTitle => 'Create wallet';

  @override
  String get deskOnbCreateLead =>
      'The password unlocks this wallet on this computer; only the recovery phrase restores the coins.';

  @override
  String get deskOnbCreateTestNote =>
      'A wallet on a test network, not for real EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'Write these words on paper, in order. They are the only way to restore this wallet.';

  @override
  String get deskOnbCreateRevealFirst => 'Reveal the phrase first';

  @override
  String get deskOnbCreateWarn => 'Anyone with these words can take the coins.';

  @override
  String get deskOnbCreateReveal => 'Reveal phrase';

  @override
  String get deskOnbCreateCheckScreen =>
      'Check that nobody can see the screen.';

  @override
  String get deskOnbCreateHide => 'Hide';

  @override
  String get deskOnbCreateShowQr => 'Show QR';

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
    return 'I have written down all $_temp0';
  }

  @override
  String get deskOnbRestoreDone => 'Wallet restored.';

  @override
  String get deskOnbRestoreNotRestored => 'Wallet not restored';

  @override
  String get deskOnbRestoreRestoring => 'Restoring the wallet';

  @override
  String deskOnbRestorePermission(String folder) {
    return 'Wallet files not written: no permission for $folder. Allow writing to that folder, then try again.';
  }

  @override
  String get deskOnbRestoreWait =>
      'Keep the app open. The balance appears after the first scan.';

  @override
  String get deskOnbRestoreSide => 'Restore wallet';

  @override
  String get deskOnbRestorePasswordLead =>
      'Set the password that unlocks this wallet on this computer.';

  @override
  String get deskOnbRestoreNothingToPaste =>
      'Nothing to paste: the clipboard holds no words.';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return 'Word $position, “$word”, is not in the word list.';
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
  String get deskOnbRestoreChecksumFirm =>
      'This phrase’s check number does not match. Compare every word with the paper.';

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
      'Type the words in order, or paste the whole phrase into any box.';

  @override
  String get deskOnbRestoreClear => 'Clear';

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
  String get deskOnbSameTitle => 'This wallet is already here';

  @override
  String get deskOnbSameBody =>
      'The phrase belongs to a wallet in the list. Nothing was added.';

  @override
  String get deskOnbSameWallet => 'Wallet';

  @override
  String get deskOnbSameNote =>
      'Open it with its password, or set a new password with this phrase.';

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
  String deskOnbUnlockPortInUse(String port) {
    return 'Port $port is in use by another program. Close it, then try again.';
  }

  @override
  String get deskOnbUnlockStageCheck => 'Checking wallet files';

  @override
  String get deskOnbUnlockStageWallet => 'Starting the wallet service';

  @override
  String get deskOnbUnlockStageUnlock => 'Unlocking the wallet';

  @override
  String get deskOnbUnlockEnter => 'Enter the password';

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
      'This computer’s key store is unavailable.';

  @override
  String get deskOnbUnlockThisWallet => 'this wallet';

  @override
  String get deskOnbUnlockFailed => 'Unlock failed';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'Unlocking $name';
  }

  @override
  String get deskOnbUnlockNote =>
      'Then the node, balances and receiving finish in the background.';

  @override
  String get deskOnbUnlockTitle => 'Unlock wallet';

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
    return 'It was at $folder. Remove it from the list, or restore it from the recovery phrase.';
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
    return '$size free';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'About $size now,';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return '$size now,';
  }

  @override
  String get deskOnbNodeFirewall => 'Windows asks once';

  @override
  String get deskOnbNodeFirewallText =>
      'to allow it through the firewall. Allow it on private networks.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'growing slowly · $free';
  }

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
      'Connects to the Epic GUI or CLI node already running here.';

  @override
  String get deskOnbNodeAddress => 'Address of the node on this computer';

  @override
  String get deskOnbNodeCheck => 'Check';

  @override
  String get deskOnbNodeBundled => 'Start the local node';

  @override
  String get deskOnbNodeBundledText =>
      'Downloads the chain into the wallet’s folder after Save.';

  @override
  String deskOnbNodeFallback(String host) {
    return 'Use $host until the local node is synced';
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
      other: '$count words pasted; a phrase has 12, 15, 18, 21 or 24.',
      one: '$count word pasted; a phrase has 12, 15, 18, 21 or 24.',
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
      'Searching the folders of older Epic Wallet versions and the epic program.';

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
  String get deskOnbImportCheckTitle => 'Checking wallets';

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
  String get deskOnbImportOlderSub => 'Wallets and folders';

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
    return '$name’s password in the older app';
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
  String get deskAppFirstScanTitle => 'First scan';

  @override
  String get deskAppFirstScanBody =>
      'The wallet scans the chain for its coins and stays usable meanwhile.';

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
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Open wallet settings: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Switch wallet';

  @override
  String get deskTourOverviewTitle => 'Overview';

  @override
  String get deskTourOverviewText =>
      'The balance and what is still confirming, then the latest payments. Everything else is in the sidebar.';

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
  String get deskTourNodeTitle => 'Settings › Node';

  @override
  String get deskTourNodeText =>
      'Which node the wallet reads the chain from. The other settings pages are listed on the left.';

  @override
  String get deskTourHelpTitle => 'Help';

  @override
  String get deskTourHelpText =>
      'Help topics, Report a problem and Show the tour again.';

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
      'Epicbox: the payment goes to the Epicbox server, which holds it until the recipient’s wallet is back';

  @override
  String get deskKitHeroLabelHttp =>
      'Link · HTTP: the payment goes straight to the recipient’s wallet, which must be open';

  @override
  String get deskKitHeroLabelTor =>
      'Link · Tor: the payment goes straight to the recipient’s wallet, routed through the Tor network';

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
  String deskKitLimitedNetwork(String site) {
    return '$site is not reachable; the facts come from the node only.';
  }

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
  String get deskKitAtTip => 'synced';

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
  String deskKitSourceChecked(String time, String site) {
    return '$site, checked $time';
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
  String get deskKitNodeDownHead => 'Node not answering';

  @override
  String deskKitNodeDownText(String host) {
    return 'Switch to $host, the healthiest other node?';
  }

  @override
  String get deskKitSwitch => 'Switch';

  @override
  String get deskKitLimitedInfo => 'Limited info';

  @override
  String deskKitFromStatusSite(String site) {
    return 'from $site';
  }

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
  String get deskKitMethodWaitingTor => 'Waiting for Tor';

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
    return 'Port $port is in use by another program. Close it, or change the port below.';
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
  String get deskKitChipNotOverTor => 'Without Tor';

  @override
  String get deskKitPasswordNote =>
      'Estimated on this device from the length and from common words, names and patterns, for an attacker with fast hardware trying 100,000 guesses a second against this wallet’s file. A guide, not a guarantee.';

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
  String get deskKitQrHideCode => 'Hide QR';

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
  String get deskSetAcctLabel => 'Name';

  @override
  String get deskSetAcctLabelHint => 'Only shown in this app.';

  @override
  String get deskSetAcctSaveLabel => 'Save label';

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
  String get deskSetBackupGroup => 'Wallet data';

  @override
  String get deskSetBackupExportTitle => 'Export wallet data';

  @override
  String get deskSetBackupExportHint =>
      'Payment history, contacts, invoices and settings, in a file only a wallet with this recovery phrase opens. The phrase alone brings back the balance, not these.';

  @override
  String get deskSetBackupExporting => 'Exporting…';

  @override
  String get deskSetBackupExportButton => 'Export…';

  @override
  String get deskSetBackupImportTitle => 'Import wallet data';

  @override
  String get deskSetBackupImportHint =>
      'Brings back this wallet’s payment history, contacts, invoices and settings from a wallet data file. Nothing is removed; the same file twice changes nothing.';

  @override
  String get deskSetBackupImportButton => 'Import…';

  @override
  String get deskSetBackupCsvHint =>
      'A plain table for spreadsheets. Not encrypted, not importable.';

  @override
  String get deskSetBackupSaveDialogTitle => 'Save wallet data';

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
  String get deskSetBackupInFileSub =>
      'Who paid what, fees, notes and labels; invoices; settings';

  @override
  String get deskSetBackupNotIn => 'Not in it';

  @override
  String get deskSetBackupNotInValue =>
      'The recovery phrase, keys, the password';

  @override
  String get deskSetBackupOpensWith => 'Opens with';

  @override
  String get deskSetBackupOpensWithValue =>
      'This wallet, or one restored from its recovery phrase';

  @override
  String get deskSetBackupFile => 'File';

  @override
  String get deskSetBackupFileNote => 'The file holds everything up to now.';

  @override
  String get deskSetBackupExportDesc =>
      'A file with this wallet’s payment history, contacts, invoices and settings.';

  @override
  String get deskSetBackupSaved => 'Saved';

  @override
  String get deskSetBackupKeepCopy =>
      'Keep a copy off this computer: a USB stick, another drive or cloud storage.';

  @override
  String get deskSetBackupOpenFolder => 'Open folder';

  @override
  String get deskSetBackupSaving => 'Saving…';

  @override
  String get deskSetBackupTryAgain => 'Try again';

  @override
  String get deskSetBackupSaveAs => 'Save as…';

  @override
  String get deskSetBackupOpenDialogTitle => 'Open wallet data file';

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
      'Payment details and notes, older payments the list lost, contacts, invoices and settings';

  @override
  String get deskSetBackupNeeds => 'Needs';

  @override
  String get deskSetBackupNeedsValue =>
      'A file from this wallet (same recovery phrase). Restore the wallet from its phrase first.';

  @override
  String get deskSetBackupChooseFile => 'Choose file…';

  @override
  String get deskSetBackupImportDesc =>
      'Brings back this wallet’s payment history, contacts, invoices and settings; existing records stay.';

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
  String get deskSetBackupRangeAll => 'All time';

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
    return '$_temp0 · $file';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '$file';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Not encrypted.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Anyone with the file can read amounts, dates, addresses and notes.';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments are not in your exported wallet data.',
      one: '1 payment is not in your exported wallet data.',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are new or changed since the last wallet data export.',
      one: '1 payment is new or changed since the last wallet data export.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'A restore from the recovery phrase brings back the balance, not who paid what.';

  @override
  String get deskSetBackupNotNow => 'Not now';

  @override
  String get deskSetDlgChainTitle => 'Chain data found';

  @override
  String get deskSetDlgChainDesc =>
      'The local node can use the Epic chain data already on this computer, instead of downloading it.';

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
      '1 other copy found; this one is the newest.';

  @override
  String get deskSetDlgChainInUse =>
      'Another Epic program is using this folder. Close it, then pick the local node again to use this data.';

  @override
  String get deskSetDlgChainUseIt => 'Use it?';

  @override
  String get deskSetDlgChainOlderWallet =>
      'An older Epic Wallet that uses this folder syncs again afterwards.';

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
      'The new password unlocks this wallet from now on; Remember on this computer is turned off.';

  @override
  String get deskSetDlgPwDescPlain =>
      'From now on the new password unlocks this wallet, and this computer no longer remembers it.';

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
  String get deskSetDlgRemoveWhat => 'What to remove';

  @override
  String get deskSetDlgRemoveFromList => 'Remove from list';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Files stay in $folder; Add a wallet brings it back.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Delete wallet';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Deletes its keys and database from $folder. Only the recovery phrase restores it; without it the coins are lost.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'To delete its files as well, unlock this wallet and use Delete wallet under Settings › This wallet.';

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
    return 'Use $host until the local node is synced';
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
      'Start the node again, or check the node log.';

  @override
  String deskSetLnodePortInUse(String port) {
    return 'Port $port is in use by another program.';
  }

  @override
  String get deskSetLnodePortInUseText =>
      'Close the other program, or choose that node under Node server.';

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
    return '$host, a public node, can stand in until the local node is synced.';
  }

  @override
  String get deskSetLndAskNote =>
      'Asked once. The node and the choice can be changed under Settings › Node › While syncing.';

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
    return 'Removes $size from $path; the chain downloads again on the next start. Keys and history stay.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Removes the chain data from $path. The node stops, and the whole chain downloads again on the next start (hours). Wallet keys and history are not touched.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Type “$word” to confirm';
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
  String get deskSetLndReuseTitle => 'Chain data found';

  @override
  String get deskSetLndReuseDesc =>
      'Another Epic node left chain data here. The local node can read that folder instead of downloading the chain.';

  @override
  String get deskSetLndLooking => 'Looking…';

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
  String deskSetPeersNotAddress(String port) {
    return 'Not an IP address and port, such as 203.0.113.5:$port.';
  }

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
  String deskSetPeersRefreshed(int seconds) {
    return 'Refreshed every $seconds s';
  }

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
    return 'Max incoming and outgoing: $min to $max (default $def).';
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
  String deskSetNodePortNote(String port) {
    return 'Check the address and the port (usually $port).';
  }

  @override
  String deskSetNodeListNote(String site) {
    return 'Status from $site; latency measured from this computer.';
  }

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
      'Write these words on paper, in order. They are the only way to restore this wallet.';

  @override
  String get deskSetPhrasePanel => 'Enter the password to show the words';

  @override
  String get deskSetPhraseShowWords => 'Show recovery phrase';

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
  String get deskSetPhraseHideQr => 'Hide QR';

  @override
  String get deskSetPhraseShowQr => 'Show QR';

  @override
  String get deskSetPhraseHideWords => 'Hide recovery phrase';

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
      'Anyone with these words can take the coins. Check that nobody can see the screen.';

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
  String deskSetPrivStartingDetail(int progress) {
    return '$progress%. Every connection waits for Tor.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Tor address not published yet. Sends work.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Sends work.';
  }

  @override
  String get deskSetPrivConnected => 'Connected';

  @override
  String get deskSetPrivNotConnected => 'Not connected';

  @override
  String get deskSetPrivStoppedDetail => 'Tor stopped. Retry, or turn Tor off.';

  @override
  String deskSetPrivProblemDetail(String problem) {
    return '$problem. Retry, or turn Tor off.';
  }

  @override
  String get deskSetPrivStatusSite => 'Status site';

  @override
  String deskSetPrivUseStatus(String site) {
    return 'Use $site';
  }

  @override
  String get deskSetPrivUseStatusHint =>
      'Shows which nodes and Epicbox servers are online, from a public list on status.btlabs.uk.';

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
  String get deskSetRecvEpicboxText =>
      'The Epicbox server holds payments until the wallet opens.';

  @override
  String get deskSetRecvEpicboxServer => 'Epicbox server';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Which server holds payments for this address. Both wallets can use different servers.';

  @override
  String get deskSetRecvSwitchingServer => 'Switching the Epicbox server…';

  @override
  String deskSetRecvListNote(String site) {
    return 'Status from $site.';
  }

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
    return 'Answers on all interfaces; the router must forward TCP $port to this computer.';
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
    return 'The wallet answers on 0.0.0.0, port $port, so other devices can send to it.';
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
      'Encrypted so only the developer can read it. Save to file keeps an unencrypted copy.';

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
  String get deskSetReportAttach => 'Attach logs';

  @override
  String get deskSetReportAttachHint =>
      'The newest part of the app log, without the recovery phrase, password and other secrets.';

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
  String get deskSetRescanLog => 'Recheck log';

  @override
  String get deskSetRescanText =>
      'Checks the chain again for this wallet’s coins. Use it when the balance looks wrong.';

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
    return 'Checking… $percent%';
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
  String get deskSetRescanFinished => 'Recheck finished';

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
  String get deskSetRescanRevived => 'Unlocked again';

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
  String get deskSetWalletsImport => 'Import wallets';

  @override
  String get deskSetWalletsImportText =>
      'From an older Epic Wallet or a folder';

  @override
  String get deskSetWalletsRestore => 'Restore from phrase';

  @override
  String get deskSetWalletsRestoreText => 'From the recovery phrase';

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
  String get deskSetupPrefsLead => 'App language';

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
  String get deskSetupEpicboxTitle => 'Epicbox';

  @override
  String get deskSetupReviewTitle => 'Review settings';

  @override
  String get deskSetupReviewLead =>
      'Change anything that is not right, then save.';

  @override
  String get deskSetupSideTitle => 'Set up';

  @override
  String get deskSetupBackToWallet => 'Back to wallet';

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
      'Runs on this computer: private, but needs disk space and a first sync.';

  @override
  String get deskSetupEpicboxText =>
      'The Epicbox server holds payments until the wallet opens.';

  @override
  String get deskSetupEpicboxPrivacy =>
      'The Epicbox server sees this computer’s IP address.';

  @override
  String get deskSetupEpicboxServer => 'Epicbox server';

  @override
  String get deskSetupChangePrefsSem => 'Change preferences';

  @override
  String get deskSetupChangeNodeSem => 'Change node';

  @override
  String get deskSetupChangeEpicboxSem => 'Change Epicbox';

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
  String get deskSetupBundledNode => 'Local node';

  @override
  String get deskSetupWhileSyncing => 'While syncing';

  @override
  String get deskSetupWait => 'wait';

  @override
  String get deskSetupDataFolder => 'Data folder';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Save starts the node; $node stands in until it is synced.';
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
      'Open-source software in this wallet, each under its own licence.';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop by BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Browser not opened';

  @override
  String get deskSetAboutOpen => 'Open';

  @override
  String deskSetAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Node $version';
  }

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
  String get deskSetAboutCheckNow => 'Check';

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
      other: '$count topics found',
      one: '$count topic found',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'No topic matches';

  @override
  String get deskSetHelpReportText =>
      'Describe what went wrong; the cleaned app log can go with it, encrypted to the developer.';

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
      'Epic Cash keeps its settings and your wallet’s sealed password in the system keyring, and none answered. Install or start a keyring (GNOME Keyring or KWallet), sign in to a desktop session that runs one, then choose Retry.';

  @override
  String get deskKeyringLockedTitle => 'The keyring is locked';

  @override
  String get deskKeyringLockedText =>
      'Epic Cash keeps its settings and your wallet’s sealed password in the system keyring, which is locked. Unlock it (it opens with your login password), then choose Retry, or choose Unlock now to have the system ask for it.';

  @override
  String get deskKeyringUnlockNow => 'Unlock now';

  @override
  String get txStatusNotDelivered => 'Not delivered';

  @override
  String get txDetailsNotDeliveredBody =>
      'This payment did not reach the Epicbox server yet, so the recipient has not received it. The coins stay locked until it is sent again or cancelled.';

  @override
  String get txDetailsSendAgainDone =>
      'Sent again. It completes when their wallet comes online.';

  @override
  String get deskTxThisWallet => 'This wallet';

  @override
  String get deskErrOldLinks =>
      'This wallet’s folder has links in it, so it is not imported. Restore it from the recovery phrase.';

  @override
  String get deskErrOldIncomplete =>
      'This wallet’s folder could not be read completely, so it is not imported. Restore it from the recovery phrase.';

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
      'Not delivered. The payment did not reach the Epicbox server, so the recipient has not received it. Send it again, or cancel it to free the coins.';

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
    return 'The wallet’s outputs changed since this review, so the send now pays $fee EPIC instead of $was EPIC. Check it and send again.';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max bytes';
  }

  @override
  String deskSendMessageCount(int used, int max) {
    return '$used / $max';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'The message is longer than $max bytes. Shorten it.';
  }

  @override
  String get deskSendMessageTooLongPlain =>
      'The message is too long. Shorten it.';

  @override
  String get deskSetPhraseCopyTitle => 'Copy the recovery phrase?';

  @override
  String get deskSetPhraseCopyText =>
      'Anyone with these words can take the coins. Store the copy somewhere safe.';

  @override
  String get deskOutAdvanced => 'Manage outputs';

  @override
  String get deskOutStrategyHint =>
      'Which outputs a send spends. Smallest spends the smallest outputs that cover the amount; All spends every output and returns one.';

  @override
  String get txStatusNotPosted => 'Not on the network';

  @override
  String get txStatusStalled => 'Stalled';

  @override
  String get txDetailsStalledBody =>
      'The other side has not posted this payment yet.';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      'This payment did not reach the recipient’s wallet, so they have not received it. The coins stay locked until it is sent again or cancelled.';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service has not posted your payment yet.';
  }

  @override
  String get deskTxStatusNotPosted => 'Not on the network';

  @override
  String get deskTxNowNotPosted =>
      'Not on the network. The node did not take this payment. Post it again; it cannot go through twice.';

  @override
  String get deskTxBroadcastAgain => 'Post again';

  @override
  String get deskTxBroadcastDone => 'Posted to the network';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return 'Not delivered. The recipient’s wallet did not take the payment ($method), so they have not received it. Send it again, or cancel it to free the coins.';
  }

  @override
  String get deskInvPayStalled => 'Stalled';

  @override
  String deskInvPayerStalledTitle(String service) {
    return 'Your payment to $service is stalled';
  }

  @override
  String get deskInvPayerStalledText =>
      'Not delivered: it has not reached the network yet, and the coins stay locked. Send again sends it once more without a second approval.';

  @override
  String get deskTxLabelAdd => 'Add label';

  @override
  String get deskTxLabelEdit => 'Edit label';

  @override
  String get deskTxLabelHint => 'Add label';

  @override
  String get deskTxLabelField => 'Label';

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
  String get deskTxDetailsTip => 'Only for payments found by a recheck.';

  @override
  String get deskTxDetailsFrom => 'From';

  @override
  String get deskTxDetailsFromTip =>
      'Who paid, for your records. Not verified.';

  @override
  String get deskTxDetailsFromHint => 'Address of the sender';

  @override
  String get deskTxDetailsFromBad =>
      'Use an Epicbox, http(s) or .onion address.';

  @override
  String get deskTxDetailsNote => 'Private note';

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
          'The file has different details for $n payments. Yours are kept unless you pick the file’s.',
      one: 'The file has different details for 1 payment. Yours are kept unless you pick the file’s.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'Mine';

  @override
  String get deskHistConflictBackup => 'File';

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
    return '$relay is not a server this app knows. Check the address before you send.';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay did not answer.';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay did not answer, so the recipient has not received this payment. The coins stay locked until it is sent again or cancelled.';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return 'Not delivered: $relay did not answer. The payment waits in Activity; cancel it there to free the coins.';
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
    return 'Not delivered. $relay did not answer, so the recipient has not received the payment. Send it again, or cancel it to free the coins.';
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
          'The old wallet’s history has different details for $n payments. Yours are kept unless you pick the old wallet’s.',
      one:
          'The old wallet’s history has different details for $n payment. Yours are kept unless you pick the old wallet’s.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Old wallet';

  @override
  String get deskHistConflictApply => 'Apply';

  @override
  String get deskUpdAvailable => 'Update available';

  @override
  String deskUpdDownload(String version) {
    return 'Download $version';
  }

  @override
  String get deskUpdOpensPage => 'Opens the download page';

  @override
  String deskUpdDownloading(String percent) {
    return 'Downloading $percent%';
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
  String get deskUpdFailed => 'Could not download the update';

  @override
  String get deskUpdTryAgain => 'Try again';

  @override
  String get deskUpdInstallFailed => 'Could not install the update';

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
  String get deskUpdUnfinished => 'Update did not finish. Try again.';

  @override
  String get advExperimental => 'Experimental';

  @override
  String get advTitle => 'Advanced';

  @override
  String get advIntro =>
      'Each switch shows one more part of the wallet, where it belongs.';

  @override
  String get advShowsHeader => 'Shows more';

  @override
  String get advNetworkHeader => 'Network';

  @override
  String get advOutputs => 'Outputs';

  @override
  String get advOutputsHint =>
      'Shows the Outputs page, under Wallet and on Home. It lists the coins the balance is made of, lets you split or consolidate them, and sets the defaults a send uses. A split or consolidation in progress keeps the page visible.';

  @override
  String get advTechnical => 'Technical details';

  @override
  String get advTechnicalHint =>
      'Shows the technical rows on a payment’s details: kernel, slate ID, commitments and block height. In Invoices settings, shows how long an invoice stays payable.';

  @override
  String get advSendOptions => 'Send options';

  @override
  String get advSendOptionsHint =>
      'Shows Strategy for sends and Split change in Settings › Transactions: which outputs a send spends, and whether its change is split. Stays visible while either is not at its default.';

  @override
  String get advServerDetails => 'Server details';

  @override
  String get advServerDetailsHint =>
      'Shows hosts, latency, version and block height in the server pickers and on the status card, and the Epicbox address under Receive.';

  @override
  String get advRecheckHeight => 'Recheck from a height';

  @override
  String get advRecheckHeightHint =>
      'Lets Recheck balance start from a block height or a date instead of the first block. Faster, and the only way to skip early history. Restore always offers the choice.';

  @override
  String get advModeStandard => 'Normal';

  @override
  String get advModeTorOnly => 'Tor only';

  @override
  String get advModeTorOnlyLine =>
      'Every connection goes through Tor. Until Tor is ready, nothing connects.';

  @override
  String get advReset => 'Hide everything again';

  @override
  String get advBuiltInNode => 'Local node';

  @override
  String get advLogs => 'Logs';

  @override
  String get deskSetFrameAdvanced => 'Advanced';

  @override
  String get deskSetAdvIntro =>
      'Each switch shows one more part of the wallet, where it belongs.';

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
      'Shows the Technical details fold on every transaction: kernel, slate ID, commitments and block height. Without it, a More link on a transaction shows them once. In Invoices, shows the Advanced folds.';

  @override
  String get deskSetAdvSendOptions => 'Send options';

  @override
  String get deskSetAdvSendOptionsHint =>
      'Adds a fold to Send where one send can choose which outputs it spends, Smallest or All, and whether to split the change. The defaults stay on Outputs.';

  @override
  String get deskSetAdvServerDetails => 'Server details';

  @override
  String get deskSetAdvServerDetailsHint =>
      'Shows hosts, latency, version and block height in the node and Epicbox lists, on the sidebar’s status rows and in the status card.';

  @override
  String get deskSetAdvRecheck => 'Recheck from a height';

  @override
  String get deskSetAdvRecheckHint =>
      'Lets Recheck balance also drop unconfirmed transactions. Restore offers a start block to everyone, whatever this says.';

  @override
  String get deskSetAdvBuiltInNode => 'Local node';

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
  String get deskSetAdvModeTorOnlyText =>
      'Every connection goes through Tor. Until Tor is ready, nothing connects.';

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
  String get deskSetAcctAutoLockHint =>
      'Locks the wallet after this long without a key press or mouse movement. With Never, only Lock wallet locks it.';

  @override
  String get torUndercoverKeepsOn => 'Undercover keeps Tor on.';

  @override
  String get torLockedTorOnly => 'On in Tor only.';

  @override
  String get torUndercoverChange => 'Change Undercover';

  @override
  String get torUndercoverChangeShort => 'Change';

  @override
  String get txDetailsMore => 'More';

  @override
  String get restoreStartFromLink => 'Start from a date or height';

  @override
  String get restoreStartFromMonthLink => 'Start from a month or height';

  @override
  String get settingsRescanBodyPlain =>
      'The wallet looks for its coins again, from the first block.';

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
  String get slSwitchBody => 'Switching gives you a new Epicbox address.';

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
  String get slRelayWarning => 'Switching gives you a new Epicbox address.';

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
  String get deskSlHealthUnknown => 'Status unknown';

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
  String get deskOnbRestoreFromHide => 'Check the whole chain';

  @override
  String get deskOnbRestoreFromLabel => 'Start from block';

  @override
  String get deskOnbRestoreFromHint => 'Block height';

  @override
  String get deskOnbRestoreFromHelp =>
      'Only if the wallet’s first payment came after this block. Leave it empty to check the whole chain.';

  @override
  String get deskOnbRestoreFromInvalid => 'Use digits only, or leave it empty.';

  @override
  String get deskNetWaitingTorReason =>
      'Waiting for Tor. Tor only is on in Advanced.';

  @override
  String get deskNetOpenAdvanced => 'Open Advanced';

  @override
  String get deskNetSendFileHint => 'File Transfer still works.';

  @override
  String get deskNetRecvWaitTorText =>
      'Receiving starts when Tor is connected. File Transfer still works.';

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
  String get txMethodsHeader => 'Payment methods';

  @override
  String txLinkHttpHint(String port) {
    return 'Link · HTTP pays straight to a wallet at a web address (http://host:$port) and gives this phone an address that wallets on the same Wi-Fi network can pay. Both wallets must be open. It is not encrypted on the way, cannot be reached from the internet or over mobile data, and is off while Tor is on. Adds Link · HTTP to Send and Receive.';
  }

  @override
  String get txLinkTorHint =>
      'Link · Tor pays straight to a wallet at an onion address and gives this phone a Tor address to be paid at. Both wallets must be open. Needs Tor: the Tor switch under Privacy & network routes the wallet’s connections through Tor; this switch only turns the address on. Adds Link · Tor to Send and Receive.';

  @override
  String get txLinkTorHintNet =>
      'Link · Tor pays straight to a wallet at an onion address and gives this phone a Tor address to be paid at. Both wallets must be open. Needs Tor: the Tor switch under Network & privacy routes the wallet’s connections through Tor; this switch only turns the address on. Adds Link · Tor to Send and Receive.';

  @override
  String get txLinkTorNeedsTor =>
      'Needs Tor. Turn it on under Privacy & network.';

  @override
  String get txLinkTorNeedsTorNet =>
      'Needs Tor. Turn it on under Network & privacy.';

  @override
  String get txLastMethodNotice => 'Keep at least one payment method on.';

  @override
  String get txEpicboxHint =>
      'Epicbox pays through a server, so the other wallet does not have to be open. Off, the wallet connects to no server: no Epicbox payments or invoices. The other methods still work.';

  @override
  String get txFileHint =>
      'File Transfer makes a transaction file that you pass to the other person any way you like (a message, a mail, a cable), and they pass one back. It needs no connection between the two wallets. Adds File Transfer to Send and Receive.';

  @override
  String get txStartHeader => 'Default method';

  @override
  String get txDefaultsHeader => 'Send defaults';

  @override
  String get outputsDefaultsMoved =>
      'Send defaults are in Settings › Transactions';

  @override
  String get advNodeFailover => 'Node failover';

  @override
  String get advNodeFailoverHint =>
      'When your node stops answering, the wallet uses the next working node in your list for this session.';

  @override
  String get advBalanceHeader => 'Balance';

  @override
  String get advConfirmations => 'Confirmations';

  @override
  String advConfirmationsHint(int byDefault, int min, int max) {
    return 'How many blocks a received payment waits before its outputs can be spent. $byDefault by default; any count from $min to $max.';
  }

  @override
  String get advConfirmationsDefault => 'Default';

  @override
  String advConfirmationsReset(int count) {
    return 'Reset to $count';
  }

  @override
  String get advConfirmationsFewer => 'Fewer confirmations';

  @override
  String get advConfirmationsMore => 'More confirmations';

  @override
  String advConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmations',
      one: '$count confirmation',
    );
    return '$_temp0';
  }

  @override
  String get advConfirmationsLowNote =>
      'Fewer confirmations are faster but less safe.';

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
  String get netOfflineNoPeers =>
      'Your node has no peers: the payment waits in its pool until it reconnects.';

  @override
  String get netOfflineNodeHint =>
      'Uses the node to read the chain and post. For the most privacy, use a local node.';

  @override
  String get netOfflineNodeLine => 'Uses the node';

  @override
  String get netBlockEpicboxOff => 'Epicbox is off in Settings › Transactions.';

  @override
  String netBlockMethodOff(String method) {
    return '$method is off in Settings › Transactions.';
  }

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
  String sendContactOnlyEpicbox(String name) {
    return '$name has only an Epicbox address.';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name has only a $method address.';
  }

  @override
  String get receiveEpicboxOffText =>
      'Payments wait on the Epicbox server until Epicbox is on again.';

  @override
  String get receiveNoMethods => 'No receiving method is on';

  @override
  String get receiveNoMethodsBody => 'Turn one on in Settings › Transactions.';

  @override
  String get receiveNoMethodsButton => 'Open Settings';

  @override
  String get deskNetOfflineNoPeers =>
      'Your node has no peers: the payment waits in its pool until it reconnects.';

  @override
  String get deskOutDefaultsMoved =>
      'The strategy and Split change for sends are set in Settings › Transactions.';

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
  String deskSetTxDirectHint(String port) {
    return 'Pay and get paid straight from wallet to wallet at a web address (http://host:$port), with no server between. Works only while both wallets are open; off while Tor is on. Adds Link · HTTP to Send and its address to Receive.';
  }

  @override
  String get deskSetTxFileHint =>
      'Pay and get paid by handing over a transaction file, with no network needed. Adds File Transfer to Send and the file steps to Receive.';

  @override
  String get deskSetTxSend => 'Send';

  @override
  String get deskSetTxStart => 'Default method';

  @override
  String get deskSetTxStartHint =>
      'The method the Send page opens with. You can still change it for one payment on Send.';

  @override
  String get deskSendMethodHeader => 'Payment method';

  @override
  String get sendRequestTitle => 'Invoice';

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
  String get payeeNameLabel => 'Name from the recipient (not verified)';

  @override
  String get payeeNoteLabel => 'Message from the recipient (not verified)';

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
  String get linkWaitingPairingNotice => 'Pairing link received';

  @override
  String get linkWaitingNotice => 'Payment link received';

  @override
  String get linkFinishCurrentFirst => 'Finish the current payment first.';

  @override
  String get deskSendToQrPayment =>
      'A QR Payment code. Scan it with Epic Cash Mobile.';

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
  String get deskRecvTorOffTitle => 'Link · Tor needs Tor.';

  @override
  String get deskRecvTorOffText =>
      'The Tor address works while Tor is on. Tor is Settings › Privacy’s switch; it routes the wallet’s connections through Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Settings not saved';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Save again, or skip to keep the settings saved so far.';
  }

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
      'The sender reports it posted this payment. It completes when the network confirms it.';

  @override
  String get deskImpWrongTypePasted =>
      'The pasted text is not a transaction. Paste the whole text the sender gave, or choose their file.';

  @override
  String get pairTitle => 'Pair';

  @override
  String pairWithName(String name) {
    return 'Pair with $name';
  }

  @override
  String get pairInPerson => 'In person';

  @override
  String get pairInPersonHint => 'Show your code and scan theirs';

  @override
  String get pairOfflineHint =>
      'Offline. The invite and the answer travel by hand.';

  @override
  String get pairEnterHint =>
      'Paste an invite link or type the words you were given';

  @override
  String get pairNotPaired => 'Not paired';

  @override
  String get pairNotPairedHint =>
      'Pair to seal transaction files and allow invoices.';

  @override
  String get pairInPersonTitle => 'Pair in person';

  @override
  String get pairShowMyCode => 'Show my invite';

  @override
  String get pairScanTheirs => 'Scan theirs';

  @override
  String get pairShowCodeCaption => 'Let them scan this, then scan theirs.';

  @override
  String get pairScanCaption =>
      'Both of you scan. The words check opens when both codes are in.';

  @override
  String get pairScanPrompt => 'Scan their QR';

  @override
  String get pairSeenAs => 'They will see you as';

  @override
  String get pairUseWords => 'Use words instead';

  @override
  String get pairCameraDeniedTitle => 'The camera is not allowed';

  @override
  String get pairCameraDeniedBody =>
      'Allow the camera to scan, or paste the invite.';

  @override
  String get pairOpenSettings => 'Open settings';

  @override
  String get pairWordsTitle => 'Pairing words';

  @override
  String get pairWordsLead =>
      'Read these to them, in this order. Their wallet finds the invite from the words.';

  @override
  String get pairWordsGoodFor => 'Good for 10 minutes';

  @override
  String get pairWordsLastMinute => 'Less than a minute left';

  @override
  String get pairWordsFooter =>
      'Whoever has these words can answer this invite until it expires. Check the words together afterwards.';

  @override
  String get pairWordsNew => 'New words';

  @override
  String get pairWordsCopy => 'Copy words';

  @override
  String get pairWordsExpiredTitle => 'These words have expired';

  @override
  String get pairWordsExpiredBody => 'Make new ones and read them out again.';

  @override
  String get pairWordsNeedEpicbox =>
      'Spoken invites need Epicbox, so they are not offered now.';

  @override
  String pairWordsDesktopChip(String time) {
    return 'Words: $time left';
  }

  @override
  String get pairEnterLead =>
      'Paste the invite link, or type the five words you were given.';

  @override
  String get pairEnterField => 'Invite link or words';

  @override
  String get pairEnterNotFound =>
      'No invite found for these words. Check them, or ask for new ones.';

  @override
  String get pairEnterTryAgain => 'Try again';

  @override
  String get pairCardCopy => 'Copy my pairing link';

  @override
  String get pairCardHint =>
      'Face to face without a camera: each wallet pastes the other’s pairing link above.';

  @override
  String pairCardBackTitle(String name) {
    return 'Now give $name your code';
  }

  @override
  String pairCardBackBody(String name) {
    return 'Paste this link under Enter link or words in $name’s wallet. Then verify together.';
  }

  @override
  String get pairEnterDesktopPlaceholder =>
      'Paste the invite link, or type the five words';

  @override
  String get pairExpiresIn => 'Invite expires in';

  @override
  String get pairExpiry1h => '1 hour';

  @override
  String get pairExpiry24h => '24 hours';

  @override
  String get pairExpiry7d => '7 days';

  @override
  String get pairWhatTheyReceive => 'What they receive';

  @override
  String get contactsPairHint =>
      'Pair with another wallet to seal transaction files and invoices between the two.';

  @override
  String get contactsPairLearn => 'How it works';

  @override
  String get contactsPairTooltip => 'Pair with another wallet';

  @override
  String get pairBadgePending => 'Pairing…';

  @override
  String get pairBadgePendingTip =>
      'Invite sent or answered, not finished yet.';

  @override
  String get pairWaysLead =>
      'Pair once. Transaction files and invoices between the two wallets are then sealed.';

  @override
  String get pairWayWords => 'Words';

  @override
  String get pairWayAutomatic => 'Spoken';

  @override
  String get pairWayWordsHint =>
      'Read the five pairing words to them. Both wallets must be online.';

  @override
  String get pairWayWordsInfo =>
      'Both wallets must be online. Your wallet leaves the invite on the connection servers; theirs finds it from the five words. Afterwards, verify together.';

  @override
  String get pairWayMessage => 'Invite by message';

  @override
  String get pairWayMessageHint => 'Send a link in any chat or email.';

  @override
  String get pairWayMessageInfo =>
      'Three messages: your invite, their reply, your finish link. Copy each one when it arrives; the wallet finds it on the clipboard when you come back. Works when a server is blocked or a wallet is offline.';

  @override
  String get pairWayInPersonDesk => 'Their phone scans your code';

  @override
  String get pairGotInvite => 'Got words or a link?';

  @override
  String get pairGotInviteHint =>
      'Type the words, or paste the message they sent.';

  @override
  String get pairHowItWorks => 'How pairing works';

  @override
  String get pairWordsBothOnline =>
      'Both wallets must be online. The rest happens by itself.';

  @override
  String get pairWordsWaiting => 'Waiting for their wallet…';

  @override
  String get pairUseMessageInstead => 'Invite by message instead';

  @override
  String get pairAskForMessage => 'Ask them to invite you by message instead.';

  @override
  String get pairStepInvite => 'Invite';

  @override
  String get pairStepReply => 'Reply';

  @override
  String get pairStepFinish => 'Finish link';

  @override
  String get pairStepWords => 'Words';

  @override
  String pairStepOf(int n, String step) {
    return 'Step $n of 4: $step';
  }

  @override
  String get pairMessageLead =>
      'Send the invite in any chat. Their reply comes back the same way.';

  @override
  String pairInviteMessage(String link) {
    return 'Pair with me in Epic Cash: $link';
  }

  @override
  String pairReplyMessage(String link) {
    return 'My reply to your Epic Cash pairing: $link';
  }

  @override
  String pairFinishMessage(String link) {
    return 'Finish our Epic Cash pairing: $link';
  }

  @override
  String pairFinishLinkMessage(String link) {
    return 'Finish the Epic Cash pairing: $link';
  }

  @override
  String get pairCopyMessage => 'Copy message';

  @override
  String get pairMessageCopied => 'Copied. Paste it in the chat.';

  @override
  String get pairAwaitReplyTitle => 'Waiting for the reply';

  @override
  String get pairAwaitReplyBody =>
      'When the reply arrives in the chat, copy it and come back. The wallet finds it.';

  @override
  String get pairByItself =>
      'When both wallets reach an Epicbox server, this step also happens by itself.';

  @override
  String get pairPasteReply => 'Paste reply';

  @override
  String get pairReplyTitle => 'Send your reply';

  @override
  String pairReplyLead(String name) {
    return 'Send this back to $name in the same chat.';
  }

  @override
  String get pairShareReply => 'Share reply';

  @override
  String get pairAwaitFinishTitle => 'Waiting for the finish link';

  @override
  String pairAwaitFinishBody(String name) {
    return '$name’s wallet makes it from your reply. Copy it when it arrives and come back.';
  }

  @override
  String get pairPasteFinish => 'Paste finish link';

  @override
  String get pairPasteLink => 'Paste link';

  @override
  String get pairFinishTitle => 'Send the finish link';

  @override
  String pairFinishLead(String name) {
    return 'One more message: $name’s wallet needs it to show the words.';
  }

  @override
  String get pairShareFinish => 'Share finish link';

  @override
  String get pairFinishThenCheck => 'Then check the words together.';

  @override
  String pairAlreadyPaired(String name) {
    return 'Already paired with $name.';
  }

  @override
  String get pairReplyNotHere =>
      'This reply answers an invite from another wallet.';

  @override
  String get helpPairWaysTitle => 'Three ways to pair';

  @override
  String get helpPairWaysShort =>
      'Spoken when both wallets are online, a message in any chat, or in person.';

  @override
  String get helpPairWaysP1 =>
      '**Spoken.** One wallet shows five words and leaves a sealed invite on the connection servers. The other wallet types the words and finds it. Both wallets must be online and reach one of these servers.';

  @override
  String get helpPairWaysP2 =>
      '**Invite by message.** Three messages in any chat: the invite, the reply, the finish link. No server is needed, so this works when a network blocks Epicbox. Copy each message when it arrives; the wallet offers it when you come back.';

  @override
  String get helpPairWaysP3 =>
      '**In person.** Each phone scans the other’s code. No network is used.';

  @override
  String get helpPairWaysP4 =>
      'Whichever way, verify together at the end: compare the four pictures and names. They show that nobody changed the messages on the way.';

  @override
  String get helpPairClipP =>
      'The wallet reads the clipboard only while Pairing is on, only when it comes to the front or the Pair screen opens, and offers each link once. It never stores or logs what it reads.';

  @override
  String get pairShareWarning =>
      'Anyone with this invite can pair as you until it expires. Send it only to the person you mean, then verify together.';

  @override
  String get pairShareInvite => 'Share invite';

  @override
  String get pairCopyInvite => 'Copy invite';

  @override
  String get pairCancelInvite => 'Cancel invite';

  @override
  String pairCancelInviteTitle(String name) {
    return 'Cancel the invite to $name?';
  }

  @override
  String pairCancelInviteBody(String name) {
    return 'Their wallet will see “$name cancelled this invite” if they open it later.';
  }

  @override
  String pairIncomingTitle(String name) {
    return 'Pair with $name?';
  }

  @override
  String get pairNameClaimed => 'Name chosen by them · not checked yet';

  @override
  String get pairNameClaimedShort => 'Name chosen by them';

  @override
  String pairCallsThemselves(String name) {
    return 'Calls themselves “$name”';
  }

  @override
  String pairIncomingBody(String name) {
    return 'Once paired, transaction files and invoices between you and $name are sealed. You verify together next.';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return 'Allow $name to request payments';
  }

  @override
  String get pairIncomingAllowHintDesktop =>
      'Turns on after you verify. Nothing is paid without the wallet password.';

  @override
  String get pairIncomingAllowHint =>
      'Turns on after you verify. Nothing is paid without your PIN.';

  @override
  String get pairNotNow => 'Not now';

  @override
  String get pairWaitingBody =>
      'Their wallet answers when it opens. You can close this screen; the verification appears when pairing is done.';

  @override
  String get pairSendByHand => 'Send by hand';

  @override
  String get pairReplyLateTitle => 'Not paired yet?';

  @override
  String pairReplyLateBody(String name) {
    return 'Your reply went to $name over the Epicbox server. If their wallet is closed or can\'t reach one, send the reply in the chat instead.';
  }

  @override
  String get pairRelayUnreachableTitle => 'Cannot reach the server';

  @override
  String get pairRelayUnreachableBody => 'Send your answer by hand?';

  @override
  String get pairRelayUnreachableTor =>
      'Cannot reach the server over Tor. Send your answer by hand?';

  @override
  String get pairNoRelay =>
      'Cannot reach any connection server. Pair with an invite link instead.';

  @override
  String get pairRelaysBlocked =>
      'This network blocks the connection servers. A network filter may be the cause. Pair with an invite link instead.';

  @override
  String get pairByHandTitle => 'Send by hand';

  @override
  String pairByHandLead(String name) {
    return 'Send this back to $name on any channel. Their wallet finishes the pairing when it opens it.';
  }

  @override
  String get pairByHandYourAnswer => 'Your answer';

  @override
  String pairByHandFooter(String name) {
    return 'The answer is sealed to $name’s invite. Nobody else can read it, and it works once.';
  }

  @override
  String pairConfirmByHandLead(String name) {
    return 'Send this back to $name. Their wallet shows the words check when it opens it.';
  }

  @override
  String get pairExpiredTitle => 'This invite has expired';

  @override
  String pairExpiredBody(String name) {
    return 'Ask for a new one.';
  }

  @override
  String get pairUsedTitle => 'This invite was already used';

  @override
  String get pairUsedBody => 'Ask for a new one.';

  @override
  String pairCancelledTitle(String name) {
    return '$name cancelled this pairing';
  }

  @override
  String get pairCancelledBody => 'Nothing was stored.';

  @override
  String pairNoAnswerTitle(String name) {
    return 'No answer from $name';
  }

  @override
  String get pairNoAnswerBody =>
      'The invite may have been cancelled. Ask for a new one, or pair in person.';

  @override
  String pairWaitingFinish(String name) {
    return 'Waiting for $name to finish…';
  }

  @override
  String get pairNotCompletedTitle => 'Not completed';

  @override
  String pairNotCompletedBody(String name) {
    return '$name’s wallet did not finish the pairing in time. Nothing was kept. Try again.';
  }

  @override
  String get pairLateCheck => 'Checking for a late answer…';

  @override
  String noticeUnpaired(String name) {
    return '$name removed the pairing.';
  }

  @override
  String trustRemovedBy(String name) {
    return 'Removed by $name';
  }

  @override
  String get trustRemovedShort => 'Removed';

  @override
  String get pairChangedTitle => 'This invite was changed on the way';

  @override
  String pairChangedBody(String name) {
    return 'Nothing was stored. Pair again, in person or with a fresh invite from $name.';
  }

  @override
  String get pairNewerTitle => 'Update Epic Cash to open this';

  @override
  String get pairNewerInviteBody => 'This invite was made by a newer wallet.';

  @override
  String get pairNewerFileBody => 'The file was sealed by a newer wallet.';

  @override
  String get pairCheckForUpdates => 'Check for updates';

  @override
  String pairSecondReplyTitle(String name) {
    return 'Someone else also answered your invite';
  }

  @override
  String get pairAnsweredSameInvite => 'Answered the same invite · not stored';

  @override
  String get sasTitle => 'Check the words';

  @override
  String sasLead(String name) {
    return '$name’s wallet shows the same four. Compare them.';
  }

  @override
  String sasLeadExchange(String name) {
    return 'The $name page shows the same four. Compare them, then confirm on both sides.';
  }

  @override
  String sasLeadRecheck(String name) {
    return '$name’s wallet shows these under $name › Check the words. Compare them on a call or in person.';
  }

  @override
  String get sasMatch => 'They match';

  @override
  String get sasNoMatch => 'They do not match';

  @override
  String get sasSkip => 'Skip for now';

  @override
  String get sasLater => 'Later';

  @override
  String sasMatchedTitle(String name) {
    return '$name is verified';
  }

  @override
  String sasMatchedBody(String name) {
    return 'Transaction files and invoices with $name are sealed from now on.';
  }

  @override
  String get sasNoMatchTitle => 'The words do not match';

  @override
  String get sasNoMatchBody =>
      'The pairing ends on both sides and nothing sent through it is finished. Pair again with a fresh invite.';

  @override
  String get sasStopPairing => 'Stop pairing';

  @override
  String sasSkippedTitle(String name) {
    return 'Paired with $name';
  }

  @override
  String sasSkippedBody(String name) {
    return 'Transaction files with $name are sealed. Check the words from $name’s contact page when you can; invoices wait until then.';
  }

  @override
  String get sasCheckNow => 'Check now';

  @override
  String get sasAllowAfterMatch => 'On once you confirm the words match.';

  @override
  String sasAllowInvoicesHint(String name) {
    return '$name’s wallet can ask you to pay. Nothing is paid without your PIN.';
  }

  @override
  String get trustVerified => 'Verified';

  @override
  String get trustPaired => 'Paired, not verified';

  @override
  String get trustPairedShort => 'Paired';

  @override
  String get trustKeysChanged => 'Keys changed';

  @override
  String get trustSealed => 'Sealed';

  @override
  String trustSealedFor(String name) {
    return 'Sealed for $name';
  }

  @override
  String get trustAllowsInvoices => 'Allows invoices';

  @override
  String get contactTitle => 'Contact';

  @override
  String get contactAddresses => 'Addresses';

  @override
  String get contactPairing => 'Pairing';

  @override
  String contactWordsChecked(String date) {
    return 'Verified $date';
  }

  @override
  String get contactCheckAgain => 'Check again';

  @override
  String get contactCheckWordsAgain => 'Verify again';

  @override
  String get contactSealPayments => 'Seal payments';

  @override
  String contactSealInfo(String name) {
    return 'Payments and invoices with $name are encrypted end to end. Only their wallet can read them.';
  }

  @override
  String contactSealInfoMore(String name) {
    return 'Off, a transaction file to $name is plain: anyone who gets the file can read it. Turn it off only if $name’s wallet cannot open sealed files.';
  }

  @override
  String get contactAllowInvoices => 'Allow invoices';

  @override
  String contactAllowInfoDesktop(String name) {
    return '$name’s wallet can send you invoices. Each one waits under Invoices for your approval and the wallet password. Nothing is paid on its own.';
  }

  @override
  String contactAllowInfo(String name) {
    return '$name’s wallet can send you invoices. Each one waits under Invoices for your approval and PIN. Nothing is paid on its own.';
  }

  @override
  String get contactAllowInfoMore =>
      'Only a Verified contact can be allowed: verifying rules out a swapped invite.';

  @override
  String get contactCheckWordsFirst => 'Verify first';

  @override
  String get contactPausedUntilChecked => 'Paused until verified';

  @override
  String contactDeliveredVia(String relay) {
    return 'Delivered via $relay';
  }

  @override
  String contactRelayDownTitle(String name) {
    return '$name’s Epicbox server is not answering';
  }

  @override
  String get contactRelayDownBody =>
      'Retrying. Invoices and payments wait until it answers.';

  @override
  String get contactPausedEpicboxOff => 'Paused while Epicbox is off';

  @override
  String get contactPausedEpicboxOffBody => 'Sealed files still work.';

  @override
  String get contactRemovePairing => 'Remove pairing';

  @override
  String contactRemovePairingTitle(String name) {
    return 'Remove the pairing with $name?';
  }

  @override
  String contactRemovePairingBody(String name) {
    return 'Sealed payments and invoices from $name will stop. Their addresses stay in your contacts.';
  }

  @override
  String get contactKeep => 'Keep';

  @override
  String get contactRemove => 'Remove';

  @override
  String contactKeysChangedTitle(String name) {
    return '$name’s keys changed';
  }

  @override
  String get contactKeysChangedBody =>
      'This can mean they use a different wallet now, or someone else is using their name. Verify the contact again.';

  @override
  String get contactKeysChangedStatus => 'Sealing and invoices paused';

  @override
  String get contactKeysChangedPaused => 'Sealing and invoices paused';

  @override
  String get contactKeepOldKeys => 'Keep the old keys';

  @override
  String get contactUseNewKeys => 'Use the new keys';

  @override
  String contactKeysBack(String name) {
    return '$name’s keys are back.';
  }

  @override
  String get contactKeysBackBody => 'Nothing changed for you.';

  @override
  String contactSealDegradedTitle(String name) {
    return 'The last payment to $name went plain';
  }

  @override
  String contactSealDegradedBody(String name) {
    return 'The next one asks Seal or plain. Sealing turns itself back on when $name’s wallet answers sealed.';
  }

  @override
  String get addrField => 'Address';

  @override
  String addrFieldTyped(String type) {
    return '$type address';
  }

  @override
  String get addrAddAnother => 'Add another address';

  @override
  String addrOneFree(String type) {
    return 'One more type is free: $type.';
  }

  @override
  String addrDuplicateType(String name, String type) {
    return '$name already has this kind of address ($type).';
  }

  @override
  String get addrKeepOld => 'Keep the old one';

  @override
  String get addrReplace => 'Replace it';

  @override
  String addrDesktopThird(String type) {
    return 'Paste a $type address, or leave empty';
  }

  @override
  String get pendingTitle => 'Pending invites';

  @override
  String pendingRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invites waiting for an answer',
      one: '1 invite waiting for an answer',
    );
    return '$_temp0';
  }

  @override
  String pendingLink(String time) {
    return 'Link · expires in $time';
  }

  @override
  String pendingWords(String time) {
    return 'Spoken invite · expires in $time';
  }

  @override
  String get pendingExpired => 'Expired';

  @override
  String get pendingInviteAgain => 'Invite again';

  @override
  String get pendingWaitingConfirm => 'Waiting for their confirmation';

  @override
  String get pendingPairedCheck => 'Paired · verify';

  @override
  String get pendingEmpty =>
      'No invites waiting. An invite shows here until the other wallet answers it.';

  @override
  String get pendingShareAgain => 'Share again';

  @override
  String get pendingShowWords => 'Show invite';

  @override
  String get invSetTitle => 'Invoices';

  @override
  String get invSetLead =>
      'A paired contact you allow can send you invoices. Each one waits under Invoices for your PIN.';

  @override
  String get invSetPaired => 'Paired contacts';

  @override
  String get invSetAllowed => 'Allowed';

  @override
  String get invSetOff => 'Off';

  @override
  String get invSetPairShop => 'Pair with a shop or exchange';

  @override
  String get invSetEmpty =>
      'No paired contacts yet. Pair with a shop, an exchange or a person, verify, then allow their invoices here.';

  @override
  String get invSetPausedBody =>
      'Invoices wait on the Epicbox server and arrive when it is back on.';

  @override
  String invSetSwitchedOff(String name) {
    return 'Invoices from $name are off.';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open invoices were declined.',
      one: '1 open invoice was declined.',
    );
    return '$_temp0';
  }

  @override
  String get invSetTimeToPay => 'Time to pay';

  @override
  String invSetTimeToPayHint(int hours) {
    return '$hours hours · how long an invoice stays payable';
  }

  @override
  String get invoicesEmptyAction => 'Paired contacts';

  @override
  String get reqTitle => 'Review invoice';

  @override
  String reqRequests(String name) {
    return '$name requests';
  }

  @override
  String reqSealedSigned(String name) {
    return 'Sealed to this wallet and signed by $name';
  }

  @override
  String get reqReference => 'Reference';

  @override
  String reqPaidWaiting(String name) {
    return 'Paid. Waiting for $name to post';
  }

  @override
  String get reqPaidWaitingBodyPerson =>
      'Your part is done. Their wallet finalizes and posts it; this closes on its own.';

  @override
  String get reqPaidWaitingBody =>
      'Your part is done. The exchange finalizes and posts; this closes on its own.';

  @override
  String get reqTlPaid => 'Paid';

  @override
  String reqTlDelivered(String name) {
    return 'Delivered to $name’s Epicbox server';
  }

  @override
  String reqTlAnswerDelivered(String name) {
    return 'Answer delivered to $name’s server';
  }

  @override
  String reqTlPosted(String name) {
    return 'Posted by $name';
  }

  @override
  String get reqTlPostedHint => 'Usually within minutes';

  @override
  String get reqTlConfirming => 'Confirming';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n of $total confirmations';
  }

  @override
  String get reqTlConfirmed => 'Confirmed';

  @override
  String reqNotPostedTitle(String name) {
    return '$name has not posted yet';
  }

  @override
  String get reqNotPostedBody =>
      'Send again delivers the same payment once more. It cannot be paid twice.';

  @override
  String get reqSendAgain => 'Send again';

  @override
  String reqUnreachableTitle(String name) {
    return 'Could not reach $name yet';
  }

  @override
  String get reqUnreachableBody =>
      'The coins unlock if it is not posted. Delivery keeps retrying.';

  @override
  String get reqRelayRetrying => 'Server not answering · retrying';

  @override
  String reqWithdrewTitle(String name) {
    return '$name withdrew the invoice';
  }

  @override
  String get reqWithdrewBody => 'The coins are unlocked. Nothing was paid.';

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name sent $count invoices for $amount EPIC within 10 minutes. Pay all of them?',
      one: '$name sent 1 invoice for $amount EPIC within 10 minutes. Pay it?',
    );
    return '$_temp0';
  }

  @override
  String reqWithdrawalFrom(String name) {
    return 'Withdrawal from $name';
  }

  @override
  String reqReceivedWaiting(String name) {
    return 'Received. Waiting for $name to post';
  }

  @override
  String get reqReceivedWaitingBody =>
      'Nothing to do. The exchange posts it; confirmations follow.';

  @override
  String get reqNewTitle => 'New invoice';

  @override
  String get reqNewLead =>
      'Ask a paired contact to pay you, or save the invoice as a file for anyone.';

  @override
  String get reqNewLeadContacts => 'Ask a paired contact to pay you.';

  @override
  String get reqNewTo => 'To';

  @override
  String get reqNewToHintContacts =>
      'Paired contacts whose wallet pays invoices.';

  @override
  String get reqNoPayersContacts =>
      'No paired contact pays invoices yet. Pair and verify with them.';

  @override
  String get reqNewToHint =>
      'Paired contacts whose wallet pays invoices. Anyone else: save the invoice as a file.';

  @override
  String get reqNewSend => 'Send invoice';

  @override
  String sendViaMailbox(String name) {
    return 'Send through $name’s Epicbox server';
  }

  @override
  String sendViaMailboxHint(String relay) {
    return 'Sealed. Delivered via $relay';
  }

  @override
  String sendSealedTitle(String name) {
    return 'Sealed for $name';
  }

  @override
  String sendSealedBody(String name) {
    return 'Only $name’s wallet can open this file. Send it any way you like, then open the file they send back.';
  }

  @override
  String get sendSealOrPlainTitle => 'Seal this file?';

  @override
  String sendSealOrPlainBody(String name) {
    return 'The last file to $name went plain. Sealed is the default again.';
  }

  @override
  String get sendSealedOption => 'Sealed';

  @override
  String sendSealedOptionHint(String name) {
    return 'Only $name’s wallet can read it';
  }

  @override
  String get sendPlainOption => 'Plain';

  @override
  String get sendPlainOptionHint => 'Anyone with the file can read it';

  @override
  String sendCantOpenTitle(String name) {
    return '$name cannot open sealed files?';
  }

  @override
  String get sendCantOpenBody =>
      'Send as plain instead resends the same payment unsealed. It is still one payment.';

  @override
  String get sendAsPlain => 'Send as plain instead';

  @override
  String get sendAsPlainTitle => 'Send as plain instead?';

  @override
  String get sendAsPlainBody =>
      'The file will not be sealed: anyone who gets it can read the amount and the addresses in it. It is the same payment, so it cannot be paid twice.';

  @override
  String get sendKeepSealed => 'Keep sealed';

  @override
  String get sendPlain => 'Send as plain';

  @override
  String sendNotHeardTitle(String name) {
    return 'Not heard from $name’s wallet in 90 days';
  }

  @override
  String sendNotHeardBody(String name) {
    return '$name will need Epic Cash to open this file.';
  }

  @override
  String get sendPlainShort => 'Send plain';

  @override
  String get openSealedOtherTitle =>
      'This was sealed for another wallet or install';

  @override
  String get openSealedOtherBody =>
      'It cannot be opened here. Ask the sender to send it again.';

  @override
  String get openArrivedUnsealed => 'This arrived unsealed.';

  @override
  String openArrivedUnsealedBody(String name) {
    return '$name chose plain for this file.';
  }

  @override
  String noticePairingReplied(String name) {
    return '$name answered. Verify together.';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'Paired with $name. Verify together.';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name requests $amount EPIC.';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return 'Received $amount EPIC from $name.';
  }

  @override
  String noticeKeysChanged(String name) {
    return '$name’s keys changed. Verify again.';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return '$name is paired with new keys. Their old keys could not be checked: there is one check a day, and it already ran.';
  }

  @override
  String noticeRelayDown(String name) {
    return 'Cannot reach $name’s Epicbox server.';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name withdrew the invoice. Coins unlocked.';
  }

  @override
  String get restoreUseContactsTitle => 'Use your contacts on this device?';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pairings in this file were used on another device. Your other device should stop using them.',
      one: '1 pairing in this file was used on another device. Your other device should stop using it.',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => 'Use them here';

  @override
  String get pairInvalidLink => 'Not a pairing invite.';

  @override
  String get pairInvalidBody =>
      'Check that the whole invite was copied, or ask for a new one.';

  @override
  String get pairWrongNetworkBody => 'This invite is for another network.';

  @override
  String get pairOwnCode => 'This is your own code';

  @override
  String get pairOwnCodeBody => 'Scan the code on the other phone.';

  @override
  String get pairUnnamedInvite => 'Open invite';

  @override
  String get pairSeenAsMissing => 'Enter the name they will see.';

  @override
  String get pairSeenAsTooLong => 'Use a shorter name.';

  @override
  String get pairSeenAsEdit => 'Change the name they will see';

  @override
  String get pairCodeLabel => 'Your pairing code';

  @override
  String get pairWordsLabel => 'Your pairing words';

  @override
  String get pairWordsEnteredLabel => 'Words entered';

  @override
  String pairWordSlot(int n) {
    return 'Word $n, not entered';
  }

  @override
  String get pairSuggestions => 'Suggestions';

  @override
  String get pairCopied => 'Copied';

  @override
  String get pairPaste => 'Paste';

  @override
  String get pairInPersonDone => 'Codes scanned';

  @override
  String get pairEpicboxOffNotice =>
      'Paused while Epicbox is off. The invite and the answer travel by hand.';

  @override
  String get pairWaitingTitleShort => 'Pairing';

  @override
  String get pairClosed => 'Close';

  @override
  String get sasWordsLabel => 'The four words';

  @override
  String sasDialogTitle(String name) {
    return 'Check the words with $name';
  }

  @override
  String get contactMore => 'More';

  @override
  String get contactEdit => 'Edit';

  @override
  String get contactDelete => 'Delete contact';

  @override
  String contactCopyAddress(String type) {
    return 'Copy $type address';
  }

  @override
  String contactDeletePaired(String name) {
    return 'Deleting $name also removes the pairing. Sealed payments and invoices from them stop.';
  }

  @override
  String get contactNoAddresses => 'No addresses saved.';

  @override
  String addrRemove(String type) {
    return 'Remove $type address';
  }

  @override
  String get sendVia => 'Send via';

  @override
  String get invSetLeadDesktop =>
      'A paired contact you allow can send this wallet invoices. Each one waits under Invoices for the wallet password.';

  @override
  String get invSetRowAllowed => 'Verified · allowed';

  @override
  String get invSetRowOff => 'Verified · off';

  @override
  String get invSetRowCheckFirst => 'Paired, not verified · verify first';

  @override
  String invSetAllowFor(String name) {
    return 'Allow invoices from $name';
  }

  @override
  String get reqNoPayers =>
      'No paired contact pays invoices yet. Pair and verify with them, or save the invoice as a file.';

  @override
  String get reqPickContact => 'Choose a contact';

  @override
  String get reqFileSaved => 'Invoice saved as a file';

  @override
  String reqSent(String name) {
    return 'Invoice sent to $name';
  }

  @override
  String get reqFileTitle => 'Invoice';

  @override
  String noticeOutboxStuck(String name) {
    return 'Cannot reach $name yet. Retrying.';
  }

  @override
  String noticeTooMany(String name) {
    return '$name sent too many invoices.';
  }

  @override
  String get noticeOpen => 'Open';

  @override
  String get noticeCheckWords => 'Verify';

  @override
  String get noticeView => 'View';

  @override
  String pairSaveContactTitle(String name) {
    return 'Save $name in your contacts?';
  }

  @override
  String get pairSaveNewContact => 'Save as a new contact';

  @override
  String pairOtherAddressTitle(String name) {
    return 'Not added to $name';
  }

  @override
  String pairOtherAddressBody(String name) {
    return '$name has an Epicbox address this pairing can’t confirm.';
  }

  @override
  String get pairOtherAddress =>
      'This contact has an Epicbox address this pairing can’t confirm.';

  @override
  String pairAddToNamed(String name) {
    return 'Add to $name';
  }

  @override
  String get pairAddToAContact => 'Add to a contact';

  @override
  String pairSavedAs(String name) {
    return 'Saved as $name.';
  }

  @override
  String pairDurDays(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String pairDurHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String pairDurMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get pairDurUnderMinute => 'under a minute';

  @override
  String get pairBack => 'Back';

  @override
  String get pairNotInContacts => 'Not in contacts';

  @override
  String get helpPairingSection => 'Pairing';

  @override
  String get helpPairingLede =>
      'Pair once; transaction files and invoices with that contact are sealed.';

  @override
  String get helpPairWhatTitle => 'What pairing is';

  @override
  String get helpPairWhatShort =>
      'Pair once with someone; after that, transaction files and invoices between the two wallets are sealed.';

  @override
  String get helpPairWhatP1 =>
      'Pairing links two wallets once: with a request to a contact you have paid over Epicbox, or with your invite, scanned as a QR or opened as a link. Each wallet keeps a key made for that one contact; nothing is shared with anyone else.';

  @override
  String get helpPairWhatP2 =>
      'After pairing, a transaction file to that contact is **sealed**: only their wallet can open it, and it cannot be changed or forged on the way. Payments over Epicbox between people keep working as before.';

  @override
  String get helpPairWhatStep1 => 'Open [[Contacts]] and choose **Pair**.';

  @override
  String get helpPairWhatStep2 =>
      'Pair with a contact, or show your invite and let them scan it.';

  @override
  String get helpPairWhatStep3 =>
      'Check the words together (not needed after a request), then **They match**.';

  @override
  String get helpPairWhatP3 =>
      'Pairing needs Epic Cash on both sides. A contact that is not paired still gets ordinary transaction files and Epicbox payments.';

  @override
  String get helpPairWhyTitle => 'Why verify';

  @override
  String get helpPairWhyShort =>
      'Verifying proves the pairing reached the right wallet and not someone in between.';

  @override
  String get helpPairWhyP1 =>
      'Both wallets show the same four pictures and names after pairing. They come from the two wallets’ keys, so a pairing that someone changed on the way shows different words on the two screens.';

  @override
  String get helpPairWhyP2 =>
      'Compare them on a call or in person, then tap **They match**. The contact becomes **Verified**. **Skip for now** leaves it **Paired, not verified**: transaction files are still sealed, but the contact cannot send invoices until the words are checked.';

  @override
  String get helpPairWhyP3 =>
      'If the words differ, tap **They do not match**. The pairing is dropped on this side. Pair again, in person or with a fresh invite.';

  @override
  String get helpPairWhyP4 =>
      'The word names stay in English in every language, so two people whose wallets use different languages can still compare them.';

  @override
  String get helpPairWordsTitle => 'Spoken invites';

  @override
  String get helpPairWordsShort =>
      'Five pictures with names stand in for a link when there is nothing to scan or paste.';

  @override
  String get helpPairWordsP1 =>
      'When one wallet has no camera, or the invite cannot be sent as a link, the inviting wallet shows five pairing words. The other person types their names under **Got words or a link?**; the field completes each name after a few letters. The words are good for 10 minutes.';

  @override
  String get helpPairWordsP2 =>
      'The words only find the invite. Whoever has them is in the same position as someone who received the link, so check the four words together afterwards as usual.';

  @override
  String get helpPairWordsP3 =>
      'Spoken invites need Epicbox. While Epicbox is off, send the invite link instead.';

  @override
  String get helpPairInvTitle => 'Invoices from paired contacts';

  @override
  String get helpPairInvShortDesktop =>
      'Only a Verified contact you allow can ask you to pay. Each invoice waits for the wallet password.';

  @override
  String get helpPairInvShort =>
      'Only a Verified contact you allow can ask you to pay. Each invoice waits for your PIN.';

  @override
  String get helpPairInvP1 =>
      'A shop, an exchange or a person you paired can send invoices, if you allow it: **Allow invoices** on the contact page, or under [[Settings › Invoices]]. The switch works only for a Verified contact.';

  @override
  String get helpPairInvP2Desktop =>
      'An invoice shows under [[Invoices › Pay]] with the contact’s name, the amount and a reference. Nothing is paid until you approve it with the wallet password. An invoice never adds money to your wallet.';

  @override
  String get helpPairInvP2 =>
      'An invoice shows under [[Invoices › Pay]] with the contact’s name, the amount and a reference. Nothing is paid until you approve it with your PIN. An invoice never adds money to your wallet.';

  @override
  String get helpPairInvP3 =>
      'Turning the switch off is immediate: new invoices from that contact are dropped and open ones are declined.';

  @override
  String get helpPairInvP4 =>
      'An exchange that pairs with you deposits and withdraws this way. Deposit: the exchange asks, you approve, the exchange posts. Withdrawal: the exchange sends the payment, your wallet answers on its own, the exchange posts.';

  @override
  String get helpPairRestoreTitle => 'What a restore does';

  @override
  String get helpPairRestoreShort =>
      'Restoring from the recovery phrase brings every pairing back with the wallet data file; without it, re-pairing finds the same keys.';

  @override
  String get helpPairRestoreP1 =>
      'With the wallet data file, a restore brings every pairing back unchanged: same keys, same Verified marks, same settings. Contacts notice nothing.';

  @override
  String get helpPairRestoreP2 =>
      'Without the file, the pairings are gone from this wallet, but the keys are not: they come from the recovery phrase. Pair again with a contact who kept the pairing, and their wallet finds the same keys. It tells them the keys are back, and the contact keeps its Verified mark. On this wallet, Seal payments and Allow invoices start at their defaults.';

  @override
  String get helpPairRestoreP3 =>
      'A contact sees **Keys changed** only when the phrase is a different one. That can mean a new wallet, or someone else using the name. Check the words again before trusting it.';

  @override
  String get helpPairRestoreP4 =>
      'Use a pairing on one device at a time. Wallet data imported on a second device asks before using the contacts there.';

  @override
  String get pairNameForCode =>
      'Enter the name they will see, and your code appears here.';

  @override
  String get deskConPickForPairing =>
      'The pairing is added to the contact you choose.';

  @override
  String txDetailsCancelHold(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Cancel becomes possible in $minutes minutes if the sender has not posted it.',
      one: 'Cancel becomes possible in 1 minute if the sender has not posted it.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsCancelWhileReported =>
      'Cancel is unavailable while the sender reports it posted.';

  @override
  String get txDetailsCancelRefusedOnNetwork =>
      'Not cancelled: the network already has this payment. It completes when the blockchain confirms it.';

  @override
  String get contactStar => 'Star';

  @override
  String get contactUnstar => 'Unstar';

  @override
  String get contactStarred => 'Starred';

  @override
  String get contactsImport => 'Import contacts';

  @override
  String get contactsExport => 'Export contacts';

  @override
  String contactsExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts exported',
      one: '1 contact exported',
    );
    return '$_temp0';
  }

  @override
  String get contactsExportHolds =>
      'The file holds names, notes and addresses. No keys or pairings.';

  @override
  String get contactsImportTitle => 'Import contacts?';

  @override
  String contactsImportNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new contacts',
      one: '1 new contact',
    );
    return '$_temp0';
  }

  @override
  String contactsImportMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts updated',
      one: '1 contact updated',
    );
    return '$_temp0';
  }

  @override
  String contactsImportSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already saved',
      one: '1 already saved',
    );
    return '$_temp0';
  }

  @override
  String contactsImportLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left out: no address this wallet can send to',
      one: '1 left out: no address this wallet can send to',
    );
    return '$_temp0';
  }

  @override
  String contactsImportOtherNet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left out: addresses for another network',
      one: '1 left out: address for another network',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportKeeps => 'Existing details are kept.';

  @override
  String get contactsImportDo => 'Import';

  @override
  String get contactsImportNothing => 'Nothing to import.';

  @override
  String contactsImported(int added, int same) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added contacts added',
      one: '1 contact added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      same,
      locale: localeName,
      other: '$same already saved',
      one: '1 already saved',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String contactsImportedAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added contacts added',
      one: '1 contact added',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportNotFile => 'That file is not a contacts file.';

  @override
  String get contactsImportDamaged =>
      'The file could not be read. It may be damaged.';

  @override
  String get contactsImportNewer =>
      'This file was made by a newer Epic Cash. Update to import it.';

  @override
  String get contactsImportEmpty => 'The file holds no contacts.';

  @override
  String get contactsImportAllOtherNet =>
      'These contacts are for another network. None can be used here.';

  @override
  String get expPairing => 'Pairing';

  @override
  String get expPairingHint =>
      'Pair once with someone you pay often: transaction files and invoices between the two wallets are then sealed, and the contact shows as paired. Experimental: it can still change.';

  @override
  String get expInvoices => 'Invoices';

  @override
  String get expInvoicesHint =>
      'Ask a paired contact for a payment, and approve the invoices paired contacts send. Needs Pairing. Experimental: it can still change.';

  @override
  String get expNeedsPairing => 'Invoices need Pairing.';

  @override
  String get expPairingOffTitle => 'Pairing is experimental';

  @override
  String get expPairingOffBody => 'Turn it on in Settings › Advanced.';

  @override
  String get expInvoicesOffTitle => 'Invoices are experimental';

  @override
  String get expInvoicesOffBody => 'Turn them on in Settings › Advanced.';

  @override
  String get expOpenAdvanced => 'Open Advanced';

  @override
  String get contactNoAddressPaired => 'Payments go through the pairing';

  @override
  String get contactSendKeysChanged => 'Verify the contact before sending.';

  @override
  String contactSendNoSealed(String name) {
    return '$name’s wallet does not take payments through the pairing. Ask for an address.';
  }

  @override
  String sendRecipientPairing(String name) {
    return 'Through $name’s pairing';
  }

  @override
  String get sendClearRecipient => 'Clear recipient';

  @override
  String get sendQueuedEpicboxOff =>
      'Epicbox is off. The payment waits here and goes out when Epicbox is back on.';

  @override
  String get sendQueue => 'Queue payment';

  @override
  String get sendQueuedHeadline => 'Payment queued';

  @override
  String sendQueuedBody(String name) {
    return 'It goes out when Epicbox is back on. $name’s answer comes back the same way.';
  }

  @override
  String txStatusWaitingFor(String name) {
    return 'Waiting for $name';
  }

  @override
  String txStepSentMailbox(String name) {
    return 'Sent through $name’s Epicbox server';
  }

  @override
  String txStepAnswerFrom(String name) {
    return 'Answer from $name';
  }

  @override
  String txStepCollecting(String name) {
    return 'Checking $name’s Epicbox server';
  }

  @override
  String deskTxStatusWaitingFor(String name) {
    return 'Waiting for $name to sign';
  }

  @override
  String deskSendContactNoLink(String name) {
    return '$name has no Link address.';
  }

  @override
  String get reqToFile => 'Save as a file for anyone';

  @override
  String reqFileSummary(String amount) {
    return 'Anyone who opens the file can pay $amount. The answer comes back as a file.';
  }

  @override
  String get reqSaveFile => 'Save as file';

  @override
  String get reqFileLead =>
      'Send this file to whoever should pay. Their wallet answers with a file; open that one here to finish.';

  @override
  String get reqByFile => 'By file';

  @override
  String get reqToAnyone => 'Anyone with the file';

  @override
  String get reqFileWaitingCard =>
      'Waiting for the answer file. Open it from Receive or by tapping it.';

  @override
  String get reqFromFileTitle => 'Invoice from a file';

  @override
  String get reqFromFileWarn =>
      'Nothing says who made this invoice. Pay it only if you expected it from someone you know.';

  @override
  String get reqFileMessageLabel => 'Message in the file';

  @override
  String get reqApproveSaveAnswer => 'Approve and save answer';

  @override
  String get reqNotNow => 'Not now';

  @override
  String get reqAnswerTitle => 'Answer saved';

  @override
  String get reqAnswerLead =>
      'Send this file back to whoever asked. They finish the payment and post it.';

  @override
  String get reqFileAlreadyPaid => 'This invoice is already paid.';

  @override
  String get reqFileEnded => 'This invoice has ended.';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return 'The answer to your invoice of $amount.';
  }

  @override
  String get reqAnswerUnknown =>
      'This answers an invoice this wallet no longer has.';

  @override
  String get deskInvIssuerAnother => 'Another invoice';

  @override
  String get deskImpOpenAnother => 'Open another file';

  @override
  String get deskInvIssuerToAnyone => 'Invoice for anyone with the file';

  @override
  String deskOnbImportRelayTitle(String name) {
    return 'Epicbox server for $name';
  }

  @override
  String deskOnbImportRelayLead(String old) {
    return 'The older app received through $old.';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return 'Keep $old';
  }

  @override
  String get deskOnbImportRelayKeepHint =>
      'Same address; the server joins the Epicbox list.';

  @override
  String deskOnbImportRelayApp(String current) {
    return 'Use $current';
  }

  @override
  String get deskOnbImportRelayAppHint =>
      'New address: payments to the old one do not arrive.';

  @override
  String get deskOnbImportUnlockOld => 'Unlock with the old password.';

  @override
  String get deskOnbImportUnlockNew =>
      'Unlock with the new password chosen here.';

  @override
  String get deskOnbWelcomeOtherApps =>
      'From Stack Wallet or Epic Pay: restore with the recovery phrase.';

  @override
  String get deskOnbImportCloseFirstWindows =>
      'Close the older Epic Wallet before importing. Whether it is still running cannot be checked on Windows.';

  @override
  String get deskSetRecvEpicboxOwnHint =>
      'This wallet has its own Epicbox server, kept from the older app. A change here applies to this wallet only.';

  @override
  String get deskErrRestoreScanRequired =>
      'Restore not finished. Receiving and sending open when the scan of the chain ends.';

  @override
  String get deskSetupSkip => 'Skip setup';

  @override
  String get deskOvRestoreTitle => 'Restore not finished';

  @override
  String get deskOvRestoreRunning =>
      'Looking for this wallet’s coins on the chain, from the first block. Received EPIC shows as it is found; receiving and sending open when the scan finishes.';

  @override
  String deskOvRestoreAfterHeight(String height) {
    return 'Funds after block $height are in. Earlier blocks are being checked; receiving and sending open when that finishes.';
  }

  @override
  String get deskOvRestoreWaiting => 'The scan waits for the network.';

  @override
  String get deskOvRestoreFailed =>
      'The scan stopped before the end. Receiving and sending stay closed until it finishes.';

  @override
  String get deskOvRestoreProgress => 'Restore scan progress';

  @override
  String get deskSetRescanRestoreRunning =>
      'The restore scan is running: the chain is read from the first block. Recheck balance is available when it finishes.';

  @override
  String get deskSetRescanStartHeading => 'Where to start';

  @override
  String get deskSetRescanFromHeight => 'From a block height';

  @override
  String get deskSetRescanHeightInvalid => 'Enter a block height of 1 or more.';

  @override
  String get deskSetRescanWholeChain => 'The whole chain';

  @override
  String get deskSetRescanWholeChainHint =>
      'From the first block. Finds everything and takes long. Also finishes an unfinished restore.';

  @override
  String get deskOnbForgotLink => 'Forgot password?';

  @override
  String get deskOnbForgotTitle => 'Set a new password';

  @override
  String deskOnbForgotLead(String name) {
    return 'The recovery phrase of $name replaces its password. History, notes and labels stay; no scan is needed.';
  }

  @override
  String get deskOnbForgotPasswordLead =>
      'The phrase checks out. Choose the new password that unlocks this wallet on this computer.';

  @override
  String get deskOnbForgotSet => 'Set password';

  @override
  String deskOnbForgotOtherWallet(String name) {
    return 'This phrase belongs to another wallet, not to $name. Nothing was changed.';
  }

  @override
  String get deskOnbSameNewPassword => 'Set a new password';

  @override
  String get deskSetupSkipKeeps =>
      'Skip keeps the current node and Epicbox settings.';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return 'Setup could not be marked as done: $reason. It may open again at the next start; Skip setup closes it.';
  }

  @override
  String get deskOvRestoredImportTitle => 'Your wallet is restored';

  @override
  String get deskOvRestoredImportBody =>
      'The balance is back. A wallet data file from this wallet brings back its history, contacts, invoices and settings.';

  @override
  String get deskOvRestoredImportButton => 'Import wallet data';

  @override
  String get deskOvRestoredImportLater =>
      'Later under Settings › This wallet › Wallet data.';

  @override
  String get deskOnbForgotNoCheck =>
      'Nothing in this wallet’s files can confirm the phrase, so the password stays.';

  @override
  String deskOnbForgotRestoreHint(String name) {
    return 'Restore it from the phrase instead: $name leaves the list and its files stay on this computer.';
  }

  @override
  String get deskOnbForgotRestoreInstead => 'Restore from the phrase';

  @override
  String get qrShowTitleRequest => 'Invoice';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount from a phone next to you';
  }

  @override
  String get qrHiddenBodyRequest =>
      'Whoever scans it can pay this invoice. Show it only to the person paying.';

  @override
  String get qrStatusRequestHidden => 'Show this to the person paying.';

  @override
  String get qrStatusRequestShowing =>
      'Waiting for them to scan and approve. Then scan their reply.';

  @override
  String qrSemanticsRequest(String state) {
    return 'Invoice QR code, $state';
  }

  @override
  String qrShowSubPaid(String amount) {
    return 'To whoever asked for $amount';
  }

  @override
  String get qrHiddenBodyPaid =>
      'Show it to the phone that asked for the payment. Only that wallet can use it.';

  @override
  String get qrStatusPaidHidden => 'Show this to whoever asked.';

  @override
  String get qrStatusPaidShowing => 'Waiting for them to scan and post it.';

  @override
  String get qrStatusPaid => 'Paid.';

  @override
  String get reqToQr => 'Show as QR to a phone nearby';

  @override
  String reqQrSummary(String amount) {
    return 'Whoever scans the code can pay $amount. Scan their reply here to finish. The invoice expires in 24 h.';
  }

  @override
  String get reqShowQr => 'Show as QR';

  @override
  String get receiveQrRequest => 'Request an amount';

  @override
  String get reqQrPaidTitle => 'Paid';

  @override
  String reqQrPaidHeadline(String amount) {
    return '$amount paid and posted to the network.';
  }

  @override
  String get reqQrNew => 'New invoice';

  @override
  String get reqQrAlreadyPaid =>
      'This invoice is already paid. Nothing was taken from this phone: its payment stays locked until they cancel it in Activity, or it runs out after a day.';

  @override
  String get reqFromQrTitle => 'Invoice from a QR code';

  @override
  String get reqFromQrWarn =>
      'Not from a paired contact. Nothing in the code says who made it: pay only the person or shop in front of you, and check the amount.';

  @override
  String get reqQrMessageLabel => 'Message in the code';

  @override
  String get reqApproveShowAnswer => 'Approve and show reply';

  @override
  String get reqQrAnswerTitle => 'Approved';

  @override
  String get reqQrAnswerLead =>
      'Whoever asked scans the reply and posts the payment. Until then it waits in Activity as \"Waiting for recipient\".';

  @override
  String get reqExpired =>
      'This invoice has expired. Ask for a new one. Nothing was paid.';

  @override
  String get reqOtherChain =>
      'This invoice is for another Epic network, or its time limit does not fit this one. Nothing was paid.';

  @override
  String get reqQrOpenNote =>
      'Open in Invoices › Sent for 24 h, then it expires.';

  @override
  String get reqQrWrongReply =>
      'This reply answers a different invoice. Scan the reply to this one.';

  @override
  String get backupFileHolds =>
      'Holds this wallet’s payment history, contacts, invoices and settings, up to now.';

  @override
  String get backupFileRestoreOrder =>
      'To restore: enter the recovery phrase first, then import this file.';

  @override
  String get backupImportLead =>
      'Brings back this wallet’s payment history, contacts, invoices and settings. Restore the wallet from its recovery phrase first.';

  @override
  String backupRestoredSummary(String items) {
    return 'Imported: $items.';
  }

  @override
  String get backupListSeparator => ', ';

  @override
  String get backupListLastSeparator => ' and ';

  @override
  String backupRestoredPayments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredNotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredLabels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n labels',
      one: '1 label',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredContacts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n contacts',
      one: '1 contact',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredStars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n starred contacts',
      one: '1 starred contact',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredPairings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pairings',
      one: '1 pairing',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredInvoices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n invoices',
      one: '1 invoice',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoredSettings => 'settings';

  @override
  String get backupRestoredWalletName => 'the wallet name';

  @override
  String backupRestoredAlreadyHere(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n records were already here.',
      one: '1 record was already here.',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsTitle => 'Use the settings from this file?';

  @override
  String backupSettingsBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n settings here differ from the file.',
      one: '1 setting here differs from the file.',
    );
    return '$_temp0 The rest of the file is already imported.';
  }

  @override
  String get backupSettingsUseBackup => 'Use the file’s';

  @override
  String get backupSettingsKeepMine => 'Keep mine';

  @override
  String get deskEpicboxBlockedWord => 'Blocked';

  @override
  String deskEpicboxBlockedText(String host) {
    return 'This network blocks $host. Choose another Epicbox server or use a private DNS.';
  }

  @override
  String deskEpicboxBlockedShort(String host) {
    return 'This network blocks $host. Try another server or a private DNS.';
  }

  @override
  String deskEpicboxBlockedSwitch(String host) {
    return 'Switch to $host';
  }

  @override
  String get deskSlotNow => 'Now';

  @override
  String get deskSlotHelp => 'Help';

  @override
  String get deskSlotScanning => 'Scanning the chain';

  @override
  String get deskSlotScanWaits => 'Scan waits for the network';

  @override
  String get deskSlotScanStopped => 'Scan stopped';

  @override
  String get deskSlotTryAgain => 'Try again';

  @override
  String get deskSlotSending => 'Sending payment';

  @override
  String get deskSlotPaymentOut => 'Payment on its way';

  @override
  String get deskSlotPaymentIn => 'Payment arriving';

  @override
  String get deskSlotPaymentsOut => 'Payments on their way';

  @override
  String get deskSlotPaymentsMoving => 'Payments confirming';

  @override
  String deskSlotOf(String done, String needed) {
    return '$done of $needed';
  }

  @override
  String get deskSlotWaitingBlock => 'waiting for a block';

  @override
  String get deskSlotRequests => 'New invoices';

  @override
  String get deskSlotNodeStarting => 'Local node starting';

  @override
  String get deskSlotNodeSyncing => 'Local node syncing';

  @override
  String get deskSlotOpenRecheck => 'Open Recheck balance';

  @override
  String get deskSlotOpenSend => 'Open Send';

  @override
  String get deskSlotOpenActivity => 'Open in Activity';

  @override
  String get deskSlotOpenInvoices => 'Open Invoices';

  @override
  String deskBarMenu(String app) {
    return '$app menu';
  }

  @override
  String get deskBarLock => 'Lock wallet';

  @override
  String get deskBarShortcuts => 'Keyboard shortcuts';

  @override
  String deskBarAbout(String app) {
    return 'About $app';
  }

  @override
  String get deskBarQuit => 'Quit';

  @override
  String get deskBarWalletsHere => 'Wallets on this computer';

  @override
  String get deskBarAddWallet => 'Add a wallet';

  @override
  String get deskBarWalletSettings => 'Wallet settings';

  @override
  String get deskBarStatus => 'Connection status';

  @override
  String get deskBarMinimise => 'Minimise';

  @override
  String get deskBarMaximise => 'Maximise';

  @override
  String get deskBarRestore => 'Restore';

  @override
  String get deskBarClose => 'Close';

  @override
  String get deskBarSendRunningTitle => 'A send is in progress';

  @override
  String get deskBarSendRunningBody =>
      'Closing now would leave the payment’s outcome unknown. The wallet can close by itself once the send has finished.';

  @override
  String get deskBarKeepOpen => 'Keep open';

  @override
  String get deskBarCloseAfterSend => 'Close when it finishes';

  @override
  String get deskBarClosesAfterSend => 'Closes when the send finishes';

  @override
  String get deskBarClosing => 'Closing';

  @override
  String get deskBarKeyBack => 'Back';

  @override
  String get deskBarKeyForward => 'Forward';

  @override
  String get deskBarKeyClose => 'Close a menu or dialog';

  @override
  String get deskBarKeySubmit => 'Run a form’s main action';

  @override
  String get deskBarKeyList => 'This list';

  @override
  String get deskBarCopyBuild => 'Copy build info';

  @override
  String get deskBarBuildCopied => 'Build info copied';

  @override
  String deskBarBuildTip(String version, String commit) {
    return 'Version $version, commit $commit. Click copies the build info.';
  }

  @override
  String deskBarBuildTipRebuild(String version, String rebuild, String commit) {
    return 'Version $version, rebuild $rebuild, commit $commit. Click copies the build info.';
  }

  @override
  String deskBarBuildTipDev(String version) {
    return 'Version $version. A development build. Click copies the build info.';
  }

  @override
  String get deskBarKeyMenu => 'Open the app menu';

  @override
  String get txDetailsCancelRequestBody =>
      'The other side can still finish this payment.';

  @override
  String get txDetailsCancelNotPostedBody =>
      'This payment could still go through later.';

  @override
  String get cancelMoreInHelp => 'How cancelling works';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '$amount EPIC to $who. This payment could still go through later.';
  }

  @override
  String get deskOnbWalletNameEdit => 'Edit wallet name';

  @override
  String get deskOnbWalletNameField => 'Wallet name';

  @override
  String deskOnbWalletNameIs(String name) {
    return 'Wallet name: $name';
  }

  @override
  String sendTurnOnMethod(String method) {
    return 'Turn on $method';
  }

  @override
  String get reqPickContactOrMethod => 'Choose a contact or method';

  @override
  String deskOnbUnlockOpened(String when) {
    return 'Opened $when';
  }

  @override
  String get deskOwnYourNode => 'Own node';

  @override
  String deskOwnLabel(String where) {
    return 'Own node · $where';
  }

  @override
  String get deskOwnClassThisComputer => 'this computer';

  @override
  String get deskOwnClassHome => 'home network';

  @override
  String get deskOwnClassVpn => 'VPN';

  @override
  String get deskOwnFactMempool => 'Mempool';

  @override
  String get deskOwnPoolEmpty => 'empty';

  @override
  String deskOwnPoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting',
      one: '1 waiting',
    );
    return '$_temp0';
  }

  @override
  String deskOwnSourceSite(String site) {
    return 'Asked directly every 15 s · tip from $site';
  }

  @override
  String deskOwnSourceNodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Asked directly every 15 s · tip from $count public nodes',
      one: 'Asked directly every 15 s · tip from 1 public node',
    );
    return '$_temp0';
  }

  @override
  String get deskOwnSourceNone =>
      'Asked directly every 15 s · no network tip to compare with';

  @override
  String get deskOwnSyncingLine =>
      'The wallet cannot send or receive through it until it is synced';

  @override
  String get deskOwnAccess => 'Owner access';

  @override
  String get deskOwnAccessHint =>
      'The node’s owner secret shows its sync stage and peers here and lets you ban a peer. It is kept in this computer’s keyring, never in the settings or the wallet data file.';

  @override
  String get deskOwnAccessNotSet => 'Not set up';

  @override
  String get deskOwnAccessOn => 'Added';

  @override
  String deskOwnAccessRefused(String time) {
    return 'Refused since $time';
  }

  @override
  String get deskOwnAccessRefusedBadge => 'Refused';

  @override
  String get deskOwnAccessTor => 'Not used while Tor is on';

  @override
  String get deskOwnAccessNote =>
      'Peers and sync details come from the node’s owner API.';

  @override
  String get deskOwnAdd => 'Add…';

  @override
  String get deskOwnUpdate => 'Update…';

  @override
  String get deskOwnRemove => 'Remove';

  @override
  String get deskOwnAdded => 'Owner access added';

  @override
  String get deskOwnRemoved => 'Owner access removed';

  @override
  String deskOwnDlgTitle(String host) {
    return 'Owner access to $host';
  }

  @override
  String get deskOwnDlgWhere =>
      'The secret is the first line of the file .api_secret in the node’s data folder (~/.epic/main on the node’s computer).';

  @override
  String get deskOwnDlgPaste => 'Paste the secret';

  @override
  String get deskOwnDlgPick => 'Pick the file…';

  @override
  String deskOwnDlgFileRead(String file) {
    return 'Read from $file';
  }

  @override
  String get deskOwnDlgFileEmpty => 'That file holds no secret';

  @override
  String get deskOwnDlgPlainTitle =>
      'The secret travels unencrypted on the home network';

  @override
  String get deskOwnDlgPlainText =>
      'On a shared network, reach the node over a VPN or https, or run the wallet on the node’s computer.';

  @override
  String get deskOwnDlgPlainAgain => 'Do not show again for this node';

  @override
  String get deskOwnDlgRefused => 'The node refused this secret';

  @override
  String get deskOwnDlgNoAnswer =>
      'The node did not answer; the secret was kept';

  @override
  String get deskOwnDlgAdd => 'Add';

  @override
  String get deskOwnDownTitle => 'Own node not answering';

  @override
  String deskOwnDownText(String host) {
    return 'The wallet uses $host meanwhile and moves back after this node answers twice in a row.';
  }

  @override
  String deskOwnUsingMeanwhile(String host) {
    return 'using $host meanwhile';
  }

  @override
  String deskOwnUsingUntilSynced(String host) {
    return 'using $host until it is synced';
  }

  @override
  String get deskOwnTryNow => 'Try now';

  @override
  String deskOwnUseForGood(String host) {
    return 'Keep $host';
  }

  @override
  String get deskOwnSyncTitle => 'Use a public node until this node is synced?';

  @override
  String deskOwnSyncText(String host) {
    return '$host can stand in until this node is synced.';
  }

  @override
  String get deskOwnWaitForMine => 'Wait for this node';

  @override
  String deskOwnSyncUsingTitle(String host) {
    return 'Using $host until this node is synced';
  }

  @override
  String get deskOwnSyncUsingText =>
      'The wallet moves back once this node accepts transactions.';

  @override
  String get deskOwnMine => 'This is my node';

  @override
  String deskOwnMineHint(String site) {
    return 'Asks the node itself instead of $site and offers owner access. For a node you run yourself.';
  }

  @override
  String get deskOwnSlotSyncing => 'Own node syncing';

  @override
  String ownNodeLabel(String where) {
    return 'Your node · $where';
  }

  @override
  String get ownNodeThisPhone => 'this phone';

  @override
  String get ownNodeHome => 'home network';

  @override
  String get ownNodeVpn => 'VPN';

  @override
  String get ownNodeSynced => 'Synced';

  @override
  String get ownNodeSyncing => 'Syncing';

  @override
  String get ownNodeBehind => 'Behind';

  @override
  String get ownNodeFactBehind => 'Behind';

  @override
  String get ownNodeFactLatency => 'Latency';

  @override
  String get ownNodeFactAccepts => 'Accepts transactions';

  @override
  String get ownNodeFactMempool => 'Mempool';

  @override
  String get ownNodeYes => 'Yes';

  @override
  String get ownNodeNotYet => 'Not yet';

  @override
  String get ownNodeUnknown => 'Unknown';

  @override
  String get ownNodePoolEmpty => 'empty';

  @override
  String ownNodePoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting',
      one: '1 waiting',
    );
    return '$_temp0';
  }

  @override
  String get ownNodeAskedDirectly =>
      'Asked directly from this phone every 15 s';

  @override
  String get deskConExportDo => 'Export';

  @override
  String get deskSetAboutDownloadPage => 'Download page';

  @override
  String get deskUpdManual => 'This copy cannot install updates itself.';

  @override
  String get deskUpdDownloadInstall => 'Download and install';

  @override
  String get deskUpdReadyTitle => 'Restart to update';

  @override
  String get deskUpdReadyBody => 'The wallet locks and the app opens again.';

  @override
  String get deskUpdRestartNow => 'Restart now';

  @override
  String get deskUpdLater => 'Later';

  @override
  String get sendTorNotInVersion =>
      'This version cannot send to Tor addresses.';

  @override
  String get methodSendDirectLineNoTor => 'Their wallet must be open.';

  @override
  String get sendDirectAddressShapeNoTor =>
      'A Link address starts with http:// or https://.';

  @override
  String get contactsAddressInvalidAnyNoTor =>
      'Not a valid address. Use an Epicbox address (es5x…@server) or a Link address (https://…).';

  @override
  String get handshakeLink1NoTor =>
      'Your wallet sends the payment straight to their wallet, over the internet. The coins are locked.';

  @override
  String txLinkHttpHintNoTor(String port) {
    return 'Link · HTTP pays straight to a wallet at a web address (http://host:$port) and gives this phone an address that wallets on the same Wi-Fi network can pay. Both wallets must be open. It is not encrypted on the way and cannot be reached from the internet or over mobile data. Adds Link · HTTP to Send and Receive.';
  }

  @override
  String get tourPhoneWalletTextNoTor =>
      'Your balance, and under it the icons for the node and Epicbox. What is still confirming is in the tiles below.';

  @override
  String get tourPhonePrivacyTextNoTor =>
      'Which node and Epicbox server the wallet uses. Tap a server to change it.';

  @override
  String get tourPhoneAdvancedTextNoTor =>
      'Offline, outputs and technical details live here. Switch on what you need.';

  @override
  String get deskNoTorSendDirectLine2 =>
      'An http(s) address. Their wallet must be open.';

  @override
  String deskNoTorSetTxDirectHint(String port) {
    return 'Pay and get paid straight from wallet to wallet at a web address (http://host:$port), with no server between. Works only while both wallets are open. Adds Link · HTTP to Send and its address to Receive.';
  }

  @override
  String get deskNoTorTxDetailsFromBad => 'Use an Epicbox or http(s) address.';

  @override
  String get deskNoTorTourAdvancedText =>
      'Outputs and technical details live here. Switch on what you need.';

  @override
  String get errorInputsSpentElsewhere =>
      'The node shows these coins already spent, and this wallet did not spend them. Most likely another wallet using your recovery phrase did.';

  @override
  String get deskErrInputsSpentElsewhere =>
      'The node shows these coins already spent, and this wallet did not spend them. Most likely another wallet using your recovery phrase did.';

  @override
  String get slAddedByYou => 'Added by you';

  @override
  String slCount(int n, int limit) {
    return '$n of $limit';
  }

  @override
  String slLimit(int limit) {
    return '$limit of $limit chosen. Untick one to choose another.';
  }

  @override
  String get slKeepOne => 'Keep at least one.';

  @override
  String get slChosenUntick => 'Chosen. Untick first.';

  @override
  String get slResetDefaults => 'Reset to defaults';

  @override
  String get slReset => 'Reset to defaults.';

  @override
  String slChosen(String host) {
    return 'Chosen $host.';
  }

  @override
  String slChosenNonDefault(String host) {
    return 'Chosen. Wallets that also use $host find you there.';
  }

  @override
  String slUnchosen(String host) {
    return 'Unticked $host.';
  }

  @override
  String slAddedNonDefault(String host) {
    return 'Added $host. Wallets that also use it find you there.';
  }

  @override
  String slAddedUntick(String host) {
    return 'Added $host. Untick one to choose it.';
  }

  @override
  String get txSentFromOtherWallet => 'Sent from another device';

  @override
  String txSpokenSentFromOtherWallet(String amount) {
    return 'Sent from another device, $amount';
  }

  @override
  String get txDetailsOtherWallet =>
      'Sent from another device with this wallet’s recovery phrase. Only the amount is known.';

  @override
  String get txSentFromOtherWalletUnverified =>
      'Sent from another device · unverified';

  @override
  String get txDetailsUnverified =>
      'Unverified: so far only the node reports this. Recheck balance to confirm it.';

  @override
  String get txDetailsNotKnown => 'Not known';

  @override
  String get txReceivedByOtherWallet => 'Received by another device';

  @override
  String txSpokenReceivedByOtherWallet(String amount) {
    return 'Received by another device, $amount';
  }

  @override
  String get txDetailsOtherWalletIn =>
      'Received by another device with this wallet’s recovery phrase. Only the amount is known.';

  @override
  String get expLinkedDevices => 'Linked devices';

  @override
  String get expLinkedDevicesHint =>
      'This wallet on two devices: each shows the other’s payments and holds the coins the other is spending. Experimental.';

  @override
  String get devicesThisPhone => 'Phone';

  @override
  String get devicesThisComputer => 'Desktop';

  @override
  String get devicesNone => 'None';

  @override
  String get devicesSeenNow => 'seen just now';

  @override
  String devicesSeenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seen $count min ago',
      one: 'seen $count min ago',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seen $count h ago',
      one: 'seen $count h ago',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seen $count d ago',
      one: 'seen $count d ago',
    );
    return '$_temp0';
  }

  @override
  String get devicesNotSeen => 'not seen yet';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '$count device',
    );
    return '$_temp0';
  }

  @override
  String get devicesThisDevice => 'This device';

  @override
  String get devicesOthers => 'Linked device';

  @override
  String get devicesEmpty =>
      'Restore this wallet on your other device, then link the two here.';

  @override
  String get devicesLink => 'Link a device';

  @override
  String get devicesServers => 'Servers';

  @override
  String get devicesPause => 'Pause sync';

  @override
  String get devicesPauseHint =>
      'While paused, notices wait on the servers for up to 7 days. Node only and Kill switch pause it too.';

  @override
  String get devicesHeld => 'Held coins';

  @override
  String devicesHeldBy(String name) {
    return 'Held by $name’s payment';
  }

  @override
  String get devicesRelease => 'Release';

  @override
  String get devicesReleaseTitle => 'Release these coins?';

  @override
  String devicesReleaseBody(String name) {
    return '$name may still be finishing this payment. If it does, a payment you make with these coins will fail. This affects only this device.';
  }

  @override
  String get devicesReleased => 'Released on this device.';

  @override
  String get devicesRename => 'Rename';

  @override
  String get devicesNameLabel => 'Name';

  @override
  String get devicesRemove => 'Remove';

  @override
  String devicesRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String devicesRemoveBody(String name) {
    return '$name stops getting this wallet’s notices; coins it holds here are released. It can still spend with the recovery phrase: if it may be in someone else’s hands, move the coins to a new wallet.';
  }

  @override
  String devicesRemoved(String name) {
    return '$name removed.';
  }

  @override
  String devicesRemovedBy(String name) {
    return '$name removed this device.';
  }

  @override
  String get devicesRemoving =>
      'Removing… The other device is told once this one is online.';

  @override
  String get devicesMoneyNote =>
      'Linking shares payments between the two devices. It does not protect the money: any device that holds the recovery phrase can spend it.';

  @override
  String get devicesUnsupported => 'This version cannot link devices yet.';

  @override
  String get linkLead =>
      'For this wallet on your other device. Restore it there from the recovery phrase first.';

  @override
  String get linkShow => 'Show QR';

  @override
  String get linkScan => 'Scan the QR';

  @override
  String get linkPaste => 'Paste invite';

  @override
  String get linkCopy => 'Copy invite';

  @override
  String get linkCopied => 'Invite copied.';

  @override
  String linkExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Invite works $count min more.',
      one: 'Invite works $count min more.',
    );
    return '$_temp0';
  }

  @override
  String get linkWaiting => 'Waiting for the other device…';

  @override
  String linkWaitingFor(String name) {
    return 'Waiting for $name…';
  }

  @override
  String get linkPasteLabel => 'Invite';

  @override
  String get linkGo => 'Link';

  @override
  String get linkPicturesLabel => 'The four pictures';

  @override
  String get linkDoneTitle => 'Linked';

  @override
  String linkDone(String name) {
    return 'Linked to $name.';
  }

  @override
  String get linkFailedTitle => 'Not linked';

  @override
  String get linkFailInvalid => 'Not a device invite.';

  @override
  String get linkFailExpired => 'The invite ran out of time. Make a new one.';

  @override
  String get linkFailNotFound => 'This invite was used already.';

  @override
  String get linkFailOwn =>
      'This invite is from this device. Scan it on the other one.';

  @override
  String get linkFailOtherWallet =>
      'This device holds another wallet. Linking needs the same recovery phrase.';

  @override
  String get linkFailOtherWalletCode =>
      'This invite is from a different wallet. Linking needs the same recovery phrase.';

  @override
  String get linkFailTooMany => 'A device is linked already.';

  @override
  String get linkFailUnreachable => 'The other device could not be reached.';

  @override
  String get linkTryAgain => 'Try again';

  @override
  String get linkOffTitle => 'Linked devices are experimental';

  @override
  String txSentFromDevice(String device) {
    return 'Sent from $device';
  }

  @override
  String txDeviceMadeOn(String device) {
    return 'Made on $device. Its details come from that device; the amount and confirmations come from the chain.';
  }

  @override
  String get txDeviceHeld =>
      'Its coins are held on this device until the chain shows the payment or the other device ends it.';

  @override
  String sendHeldByDevice(String amount, String name) {
    return '$amount EPIC is held by a payment ‘$name’ is making.';
  }

  @override
  String get offerLinkRestore =>
      'Using this wallet on another device too? Link them to see each other’s payments.';

  @override
  String get offerLinkOtherWallet =>
      'Is this your other device? Link it to see who was paid and to keep both in step.';

  @override
  String devicesReleasedRow(String name) {
    return 'Released here · $name may still send it';
  }

  @override
  String get deskDevPausedOffline => 'Paused while Offline is on.';

  @override
  String get deskDevPausedEpicboxOff => 'Paused while Epicbox is off.';

  @override
  String deskDevHeldAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskDevRenameThis => 'Rename this computer';

  @override
  String deskDevRenameDevice(String name) {
    return 'Rename $name';
  }

  @override
  String get deskDevPasteLead => 'Paste the code the other device shows.';

  @override
  String get deskDevMakingCode => 'Making the code…';

  @override
  String get deskDevConnecting => 'Connecting…';

  @override
  String get deskDevTheOther => 'The other device';

  @override
  String get deskDevOfferReceived =>
      'Is this your other device? Link it to see who sent it and to keep both in step.';

  @override
  String devicesEndCancelled(String name) {
    return 'Cancelled on $name';
  }

  @override
  String devicesEndFailed(String name) {
    return 'Failed on $name';
  }

  @override
  String devicesEndExpired(String name) {
    return 'Expired on $name';
  }

  @override
  String devicesEndLineCancelled(String name) {
    return '$name cancelled this payment. Its coins are free again.';
  }

  @override
  String devicesEndLineExpired(String name) {
    return '$name did not finish this payment in time. Its coins are free again.';
  }

  @override
  String devicesWhyNotDelivered(String name) {
    return '$name could not deliver it to the recipient. Its coins are free again.';
  }

  @override
  String get devicesWhyRefused =>
      'The recipient’s server refused it. Its coins are free again.';

  @override
  String get devicesWhyInputsSpent => 'Its coins had been spent already.';

  @override
  String devicesWhyOther(String name) {
    return '$name could not complete it. Its coins are free again.';
  }

  @override
  String devicesStatusInfo(String name) {
    return 'This status comes from $name. The blockchain decides the final state.';
  }

  @override
  String get syncHelpOtherDevice => 'Other device';

  @override
  String get syncHelpServer => 'Server';

  @override
  String get syncHelpChain => 'Blockchain';

  @override
  String get syncHelpStep1 => 'This device starts a payment.';

  @override
  String syncHelpStep2(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'An encrypted notice goes to both servers. Only the devices can read it.',
      one: 'An encrypted notice goes over the server. Only the devices can read it.',
    );
    return '$_temp0';
  }

  @override
  String get syncHelpStep3 =>
      'The other device holds those coins and lists the payment.';

  @override
  String get syncHelpStep4 =>
      'The chain confirms. The chain decides the final state.';

  @override
  String get syncHelpDiagram =>
      'How syncing works: this device starts a payment; an encrypted notice goes over the server to the other device, which holds those coins; the blockchain confirms.';

  @override
  String get syncHelpStatus => 'Live status';

  @override
  String get syncHelpPaused => 'Sync paused';

  @override
  String get syncHelpAnswering => 'Answering';

  @override
  String get syncHelpNotAnswering => 'Not answering';

  @override
  String get syncHelpNotChecked => 'Not checked';

  @override
  String get deskSetAdvBalance => 'Balance';

  @override
  String get deskSetAdvConfirmations => 'Confirmations';

  @override
  String deskSetAdvConfirmationsHint(int byDefault, int min, int max) {
    return 'How many blocks a received payment waits before its outputs can be spent. $byDefault by default; any count from $min to $max.';
  }

  @override
  String get deskSetAdvConfirmationsDefault => 'Default';

  @override
  String deskSetAdvConfirmationsReset(int count) {
    return 'Reset to $count';
  }

  @override
  String get deskSetAdvConfirmationsFewer => 'Fewer confirmations';

  @override
  String get deskSetAdvConfirmationsMore => 'More confirmations';

  @override
  String deskSetAdvConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmations',
      one: '$count confirmation',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAdvConfirmationsLowNote =>
      'Fewer confirmations are faster but less safe.';

  @override
  String get deskSetAdvConfirmationsNotSaved => 'Confirmations not changed';

  @override
  String get deskSetPeersFirstSeenHint =>
      'When this app first saw the peer connected, this session.';

  @override
  String deskAppFirstScanProgress(int percent) {
    return 'Scanning the chain · $percent%';
  }

  @override
  String deskAppFirstScanFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString outputs found',
      one: '$countString output found',
    );
    return '$_temp0';
  }

  @override
  String get deskAppFirstScanShowLog => 'Show log';

  @override
  String get deskAppFirstScanHideLog => 'Hide log';

  @override
  String deskNodeDurationDh(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String deskNodeDurationH(int hours) {
    return '$hours h';
  }

  @override
  String deskInvPayerAgoHoursOnly(int hours) {
    return '$hours h';
  }

  @override
  String get slPlainHttpTitle => 'Use this node without encryption?';

  @override
  String slPlainHttpBody(String host) {
    return '$host is in a shared address range: your own tailnet (Tailscale), or your internet provider’s network. The wallet talks to this node over plain http, so anyone on that network can read what the wallet asks it. Add it only if the address is your tailnet.';
  }

  @override
  String get slPlainHttpUse => 'Use this node';

  @override
  String get slRefusedLocal =>
      'Not chosen: other wallets cannot reach a server at a local or private address.';

  @override
  String get slRefusedOnion =>
      'Not chosen: an onion server works only with Tor on.';

  @override
  String get deskOwnAccessOnPlain =>
      'Added · goes to the node unencrypted (plain http), readable on that network';

  @override
  String get sasNotFromCamera =>
      'Their code came by message, not from your camera. Unless their wallet scanned your code from this screen, these words cannot prove who sent it, so They match is not offered: keep the pairing without checking, or pair with an invite.';

  @override
  String get slSwitchFirst => 'Switch first';

  @override
  String get contactPaymentsNone => 'No payments with this contact yet.';

  @override
  String contactPaymentsWith(String name) {
    return 'Payments with $name';
  }

  @override
  String get contactPaymentsAll => 'All payments';

  @override
  String receiveEpicboxNotConnected(String server) {
    return 'Not connected · $server';
  }

  @override
  String restoreWordsAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count words check out.',
      one: 'The word checks out.',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words are not in the list.',
      one: '1 word is not in the list.',
    );
    return '$_temp0';
  }

  @override
  String pairInvitedAt(String clock) {
    return 'Invited $clock';
  }

  @override
  String get pairInvitedYesterday => 'Invited yesterday';

  @override
  String pairInvitedOn(String day) {
    return 'Invited $day';
  }

  @override
  String get deskActNoneUnderFilter => 'Nothing under this filter';

  @override
  String get deskRecvHttpIntroInternet =>
      'For wallets on the internet, while this wallet is open.';

  @override
  String get deskKitMethodConnected => 'Connected';

  @override
  String get deskOvSendWaitsNode => 'Sending resumes when the node answers.';

  @override
  String get deskSetRescanRecheck => 'Recheck';

  @override
  String get deskSetRescanRecheckAgain => 'Recheck again';

  @override
  String get deskSetRescanFromDate => 'From a date';

  @override
  String get deskSetRescanPickDate => 'Pick a date';

  @override
  String get deskSetRescanPickDateFirst => 'Pick a date first.';

  @override
  String contactsImportAddsAddress(String name, String method, String address) {
    return '$name gets a $method address: $address';
  }

  @override
  String get netStatusTurnOnHint => 'Off. Turn on in Settings › Transactions.';

  @override
  String get netStatusTurnOnHintPrivacy =>
      'Off. Turn on in Settings › Privacy & network.';

  @override
  String get netStatusTurnOnHintNet =>
      'Off. Turn on in Settings › Network & privacy.';

  @override
  String get deskBarTurnOnHint => 'Off. Turn on in Settings › Transactions.';

  @override
  String get deskErrMacKeychain =>
      'macOS did not let the app read its saved data in the keychain. Quit Epic Cash Desktop and open it again; when macOS asks, enter your Mac login password and choose Always Allow.';

  @override
  String get deskUpdOpenDmg => 'Open the disk image';

  @override
  String get deskUpdDmgHint =>
      'The app closes and the disk image opens: drag Epic Cash Desktop into Applications, replace the old one, then open it.';

  @override
  String get balanceSheetTitle => 'Balances';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending',
      one: '1 pending',
    );
    return '$_temp0';
  }

  @override
  String get connectionsSheetTitle => 'Connections';

  @override
  String settingsFileSyntaxError(String file, int line) {
    return '$file, line $line: this line cannot be read. The last good settings are in use.';
  }

  @override
  String settingsFileNotText(String file, int line) {
    return '$file, line $line: not text in double quotes. The last good value is in use.';
  }

  @override
  String settingsFileNotNumber(String file, int line) {
    return '$file, line $line: not a whole number. The last good value is in use.';
  }

  @override
  String settingsFileNotSwitch(String file, int line) {
    return '$file, line $line: not true or false. The last good value is in use.';
  }

  @override
  String settingsFileNotList(String file, int line) {
    return '$file, line $line: not a list. The last good value is in use.';
  }

  @override
  String settingsFileNotNodeAddress(String file, int line) {
    return '$file, line $line: not a node address. The last good value is in use.';
  }

  @override
  String settingsFileNotEpicboxServer(String file, int line) {
    return '$file, line $line: not an Epicbox server. The last good value is in use.';
  }

  @override
  String settingsFileNotHostName(String file, int line) {
    return '$file, line $line: not a host name. The last good value is in use.';
  }

  @override
  String settingsFileNotWebAddress(String file, int line) {
    return '$file, line $line: not a web address. The last good value is in use.';
  }

  @override
  String settingsFileNotOnion(String file, int line) {
    return '$file, line $line: not an onion address. The last good value is in use.';
  }

  @override
  String settingsFileNotPort(String file, int line) {
    return '$file, line $line: not a port number. The last good value is in use.';
  }

  @override
  String settingsFileNotEmail(String file, int line) {
    return '$file, line $line: not an e-mail address. The last good value is in use.';
  }

  @override
  String settingsFileNotEpicboxAddress(String file, int line) {
    return '$file, line $line: not an Epicbox address. The last good value is in use.';
  }

  @override
  String settingsFileUnknownKey(String file, int line, String key) {
    return '$file, line $line: unknown key $key, ignored.';
  }

  @override
  String settingsFileConflict(String file, String key) {
    return '$file was edited at the same time; its value for $key is kept.';
  }

  @override
  String settingsFileBrokenSaved(String file, String backup) {
    return '$file had errors. It was saved as $backup and written again.';
  }

  @override
  String settingsFileRecreated(String file) {
    return '$file was missing and has been written again.';
  }

  @override
  String settingsFileWriteFailed(String file) {
    return '$file could not be written. The change applies until the app closes.';
  }

  @override
  String settingsFileReadFailed(String file) {
    return '$file could not be read. The built-in settings are in use.';
  }

  @override
  String get deskKitReachTorOff => 'The check needs Tor off.';

  @override
  String get deskSetBackupServersTitle => 'Use the servers from this file?';

  @override
  String get deskSetBackupServersBody =>
      'Its node and Epicbox server lists differ from this computer’s. Every wallet here uses the same lists.';

  @override
  String get deskSetBackupServersKeep => 'Keep this computer’s';

  @override
  String get deskSetBackupServersUse => 'Use the file’s';

  @override
  String get deskSlNoNodeTitle => 'No node set';

  @override
  String get deskSlNoNodeText =>
      'The node list is empty. Add a node to check balances and send.';

  @override
  String get deskSlNoEpicboxTitle => 'No Epicbox server set';

  @override
  String get deskSlNoEpicboxText =>
      'The Epicbox server list is empty. Add a server for an Epicbox address.';

  @override
  String get devicesOneOnly =>
      'One device can be linked. Remove it to link another.';

  @override
  String txReceivedOnDevice(String device) {
    return 'Received on $device';
  }

  @override
  String txSpokenReceivedOnDevice(String device, String amount) {
    return 'Received on $device, $amount';
  }

  @override
  String txDetailsDeviceIn(String device) {
    return '$device, linked to this wallet, received these coins.';
  }

  @override
  String get deskOnbNodeAdvanced => 'Advanced';

  @override
  String deskOnbNodePortsSub(String api, String p2p) {
    return 'API $api · P2P $p2p';
  }

  @override
  String get deskOnbNodeApiPort => 'API port';

  @override
  String get deskOnbNodeP2pPort => 'P2P port';

  @override
  String get deskOnbNodePortsWhy =>
      'Only needed if another node on this computer or network uses these ports.';

  @override
  String deskOnbNodePortRange(String min, String max) {
    return 'A number from $min to $max.';
  }

  @override
  String get deskOnbNodePortsSame => 'The two ports must differ.';

  @override
  String deskOnbNodePortTaken(String port, String next) {
    return 'Port $port is used by another program. $next is free.';
  }

  @override
  String deskOnbNodePortUse(String port) {
    return 'Use $port';
  }

  @override
  String get deskSetLnodePorts => 'Ports';

  @override
  String get deskSetLnodePortsTitle => 'Node ports';

  @override
  String get deskSetLnodePortsDesc => 'The ports the built-in node listens on.';

  @override
  String get deskSetLnodePortsRestart =>
      'The node restarts with the new ports.';

  @override
  String get deskSetLnodePortsSaved => 'Ports saved';

  @override
  String get deskSetLnodePortsRestarting => 'The node is restarting.';

  @override
  String get deskSetLnodePortsNotSaved => 'Ports not saved';

  @override
  String get deskKitInfoLabel => 'More information';

  @override
  String get advModeNodeOnly => 'Node only';

  @override
  String get advModeKillSwitch => 'Kill switch';

  @override
  String get advModeStandardHint =>
      'Connects directly. Turn on Tor in Privacy & network to hide the IP address.';

  @override
  String get advModeStandardHintHere =>
      'Connects directly. Turn on Tor below to hide the IP address.';

  @override
  String get advModeStandardHintNoTor =>
      'Connects directly to the node and the services you use.';

  @override
  String get advModeTorOnlyHint =>
      'Everything goes through Tor. Nothing connects until Tor is ready.';

  @override
  String get advModeNodeOnlyHint =>
      'Only the node in use connects. Direct · QR and Direct · File work.';

  @override
  String get advModeKillSwitchHint =>
      'Nothing connects. The wallet works offline with the last known balance, and payments go by file or QR code.';

  @override
  String advModeConfirmTitle(String mode) {
    return 'Switch to $mode?';
  }

  @override
  String advModeConfirmBody(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payments are waiting for the recipient over Epicbox or Link. They pause and continue when you leave $mode. Nothing is cancelled.',
      one:
          '1 payment is waiting for the recipient over Epicbox or Link. It pauses and continues when you leave $mode. Nothing is cancelled.',
    );
    return '$_temp0';
  }

  @override
  String get advModeConfirmSwitch => 'Switch';

  @override
  String netMarkSemantics(String mode) {
    return 'Network mode: $mode. Opens the Network section.';
  }

  @override
  String netMarkSemanticsDesk(String mode) {
    return 'Network mode: $mode. Shows what it does.';
  }

  @override
  String get netMarkLineTorOnly => 'Every connection goes through Tor.';

  @override
  String get netMarkLineTorWaiting =>
      'Waiting for Tor. Nothing connects until it is ready.';

  @override
  String get netMarkLineNodeOnly =>
      'Only the node in use. Epicbox, Link, updates and price are off.';

  @override
  String get netMarkLineKillSwitch =>
      'Nothing connects. Balance and history are as last known.';

  @override
  String get netMarkChange => 'Change';

  @override
  String statusOffByMode(String mode) {
    return 'Off ($mode)';
  }

  @override
  String get statusOffByModeDetail =>
      'Turned off by the network mode. Change it in Settings › Advanced › Network.';

  @override
  String get statusOffByModeDetailNet =>
      'Turned off by the network mode. Change it in Settings › Network & privacy.';

  @override
  String get netBlockEpicboxNodeOnly =>
      'Node only is on: Epicbox is off. Direct · QR Payment and Direct · File Transfer work.';

  @override
  String get netBlockLinkNodeOnly =>
      'Node only is on: Link is off. Direct · QR Payment and Direct · File Transfer work.';

  @override
  String get netBlockSendKillSwitch =>
      'Kill switch is on: nothing connects. Direct · QR Payment and Direct · File Transfer work.';

  @override
  String get netBlockNodeOnly => 'Off in Node only.';

  @override
  String get netBlockKillSwitch => 'Off in Kill switch: nothing connects.';

  @override
  String get netBlockWaitingForTorLong =>
      'Waiting for Tor. Nothing connects until it is ready.';

  @override
  String receiveEpicboxOffMode(String mode) {
    return 'Epicbox is off in $mode.';
  }

  @override
  String receiveEpicboxOffModeBody(String mode) {
    return 'Payments to this address wait on the Epicbox server and arrive when you leave $mode.';
  }

  @override
  String receiveLinkOffMode(String mode) {
    return 'Link receiving is off in $mode.';
  }

  @override
  String updatesOffMode(String mode) {
    return 'Update checks are off in $mode.';
  }

  @override
  String reportOffMode(String mode) {
    return 'Off in $mode. Save the report as a file instead.';
  }

  @override
  String get recheckOffKill =>
      'Recheck balance needs the node. Off in Kill switch.';

  @override
  String get postFinishedOffKill =>
      'Off in Kill switch: nothing connects here.';

  @override
  String get postFinishedOffTor => 'Waiting for Tor. Posting needs the node.';

  @override
  String get browserOffTorOnly => 'Opens outside Tor. Copy the link instead.';

  @override
  String browserOffMode(String mode) {
    return 'Off in $mode. Copy the link instead.';
  }

  @override
  String get netChangeLink => 'Change';

  @override
  String get lastKnownCaption => 'Last known';

  @override
  String get lastKnownList => 'Last known · Kill switch';

  @override
  String lastKnownConfirming(String text) {
    return '$text · last known';
  }

  @override
  String get coldNeedsOnlineCheck => 'Needs one balance check online first.';

  @override
  String get finalizeNotPostedTitle => 'Finished, not posted';

  @override
  String finalizeNotPostedBody(String amount) {
    return '$amount is finished. Kill switch is on, so this phone cannot post it: save it or show it as a QR code for a device that is online.';
  }

  @override
  String get finishedSaveFile => 'Save file';

  @override
  String get finishedShowQr => 'Show QR';

  @override
  String finishedSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get finishedQrTitle => 'Finished payment';

  @override
  String get finishedUnavailable =>
      'This version cannot save a finished payment yet.';

  @override
  String get finishedFailed => 'The finished payment could not be read.';

  @override
  String get txPostElsewhere => 'To be posted elsewhere';

  @override
  String get txPostElsewhereKill =>
      'Finished under Kill switch. Save it or show the QR, then post it on a device that is online.';

  @override
  String get txPostElsewhereAfter =>
      'Finished under Kill switch, not on the chain yet. Post it from here, or wait for the device that posted it.';

  @override
  String get txPostNow => 'Post now';

  @override
  String get txModeFinishedKill => 'Finished under Kill switch';

  @override
  String get txModeRow => 'Mode';

  @override
  String get postFinishedTitle => 'Post a finished payment';

  @override
  String get postFinishedIntro =>
      'Post a payment another device finished under Kill switch.';

  @override
  String get postFinishedIntroOffline =>
      'Post a payment another device finished with no connection.';

  @override
  String get postFinishedOpenFile => 'Open file';

  @override
  String get postFinishedScanQr => 'Scan QR';

  @override
  String get postFinishedPaste => 'Paste';

  @override
  String get postFinishedChooseFile => 'Choose file';

  @override
  String get postFinishedSummary => 'Finished payment';

  @override
  String get postFinishedAmount => 'Amount';

  @override
  String get postFinishedFee => 'Fee';

  @override
  String get postFinishedKernel => 'Kernel';

  @override
  String get postFinishedNote =>
      'Posting puts it on the network. The wallet that made it shows it confirming once it sees it on the chain.';

  @override
  String get postFinishedPost => 'Post';

  @override
  String get postFinishedPosting => 'Posting…';

  @override
  String get postFinishedDone => 'Posted';

  @override
  String get postFinishedDoneBody =>
      'The node has it. The wallet that made it shows it confirming once it sees it on the chain.';

  @override
  String get postFinishedNotFinished =>
      'Not a finished payment. Open the file saved under To be posted elsewhere, or scan its QR.';

  @override
  String get postFinishedFailed => 'The node did not take it. Try again.';

  @override
  String get postFinishedUnreachable => 'The node does not answer.';

  @override
  String get postFinishedDeskRow => 'Post a finished payment';

  @override
  String get postFinishedDeskRowText =>
      'Post a payment another device finished under Kill switch.';

  @override
  String get postFinishedOpen => 'Open';

  @override
  String get deskSetAdvModeStandardHint =>
      'Connects directly. Turn on Tor under Privacy to hide the IP address.';

  @override
  String deskFinNotPostedKillBody(String amount) {
    return '$amount is finished. Kill switch is on, so this computer cannot post it. Save it or copy it, then post it on a device that is online: Receive › Transaction files › Post a finished payment.';
  }

  @override
  String netMarkRowLabel(String mode) {
    return 'Network mode: $mode';
  }

  @override
  String get qrStatusFinishedHidden => 'Hidden';

  @override
  String get qrStatusFinishedShowing =>
      'Waiting for a device that is online to scan.';

  @override
  String qrShowSubFinished(String amount) {
    return '$amount, finished';
  }

  @override
  String qrSemanticsFinished(String state) {
    return 'Finished payment QR code, $state';
  }

  @override
  String get qrHiddenBodyFinished =>
      'Show it to a device that is online. It posts the payment; no key is needed.';

  @override
  String get qrScanFinished => 'Scan finished payment';

  @override
  String get qrScanNotFinished => 'That code is not a finished payment.';

  @override
  String get qrScanAimFinished => 'Aim at the code on the other device.';

  @override
  String get deskRailOpenNetwork => 'Open Network settings';

  @override
  String get cancelFeeLine => 'Costs the normal network fee.';

  @override
  String get cancelForSure => 'Cancel for sure';

  @override
  String get cancelStopWaiting => 'Stop waiting';

  @override
  String get cancelStopWaitingLine => 'Free. The payment may still finish.';

  @override
  String get cancelMoveBack => 'Move coins back';

  @override
  String cancelMoveBackFee(String fee) {
    return 'Move coins back · fee $fee';
  }

  @override
  String get cancelUnlockOpen => 'Unlock coins, leave payment open';

  @override
  String get cancelCompareMoveBack =>
      'Move coins back: certain, for the network fee.';

  @override
  String get cancelCompareUnlock =>
      'Unlock coins: free, the payment may still finish.';

  @override
  String get cancelChoicesTitle => 'Two ways to cancel';

  @override
  String get cancelChoicesWhy =>
      'Cancel for sure moves the coins back to this wallet first, for the normal network fee. After that the old payment can never go through, so it is the certain way.\n\nStop waiting is free and moves nothing. The coins are spendable again, and the payment is left as it is. If the other side still finishes it later, it goes through and shows as paid; if not, nothing happens.';

  @override
  String get cancelStoppedWaitingTitle => 'Stopped waiting';

  @override
  String get cancelStoppedWaitingText =>
      'The coins are spendable again. The payment may still finish; if it does, it shows as paid.';

  @override
  String get txDetailsStoppedWaiting =>
      'Stopped waiting. The coins are spendable again. The payment may still finish; if it does, it shows as paid.';

  @override
  String get errorPaymentCancelledCoinsMoved =>
      'This payment was cancelled, and its coins were already moved. It can no longer go through.';

  @override
  String get errorPaymentAlreadyWentThrough =>
      'The coins could not be moved back: the payment itself already went through. It shows as paid.';

  @override
  String get errorPinKeyLost =>
      'The PIN can no longer open this wallet. Your coins are safe: tap Forgot PIN and restore the wallet from its recovery phrase.';

  @override
  String get settingsUsePassphrase => 'Use a passphrase';

  @override
  String get settingsChangePassphrase => 'Change passphrase';

  @override
  String get passphraseLabel => 'Passphrase';

  @override
  String passphraseChoose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Choose a passphrase of at least $count characters, not only digits',
    );
    return '$_temp0';
  }

  @override
  String get passphraseRepeat => 'Repeat the passphrase';

  @override
  String get passphraseMismatch => 'The two passphrases differ';

  @override
  String get passphraseSet => 'Passphrase set';

  @override
  String get passphraseSetBiometricsOff =>
      'Passphrase set. Turn biometric unlock on again below.';

  @override
  String get passphraseForgot => 'Forgot passphrase?';

  @override
  String get passphrasePromptTitle => 'Enter your passphrase';

  @override
  String get passphraseEnterCurrent => 'Enter your current passphrase';

  @override
  String get passphraseCurrentLabel => 'Current passphrase';

  @override
  String get passphraseChooseTitle => 'Choose a passphrase';

  @override
  String passphraseRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count characters and not only digits.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseUsePinInstead => 'Use PIN instead';

  @override
  String get passphraseUsePassphraseInstead => 'Use passphrase instead';

  @override
  String get invoicePassphraseReason =>
      'Enter your passphrase to pay this invoice.';

  @override
  String get restoreReplacePassphraseReason =>
      'Enter your passphrase to replace this wallet. The restored wallet keeps this passphrase.';

  @override
  String get backupPassphraseReason =>
      'Enter your passphrase to show the recovery phrase.';

  @override
  String sendQrPassphraseReason(String amount) {
    return 'Enter your passphrase to make a payment QR for $amount.';
  }

  @override
  String get settingsBiometricsPassphraseReason =>
      'Enter your passphrase to turn on biometric unlock.';

  @override
  String get settingsDeletePassphraseReason =>
      'Enter your passphrase to delete this wallet.';

  @override
  String sendPassphraseReason(String amount) {
    return 'Enter your passphrase to send $amount.';
  }

  @override
  String sendFilePassphraseReason(String amount) {
    return 'Enter your passphrase to make a transaction file for $amount.';
  }

  @override
  String get passphraseSetTitle => 'Set a passphrase';

  @override
  String get receiveHttpNotTrustedTitle => 'Off on this network';

  @override
  String get receiveHttpNotTrusted =>
      'Link · HTTP listens only on networks you trust.';

  @override
  String get receiveHttpTrust => 'Trust this network';

  @override
  String get deskSetReportFullDetails => 'Include full details';

  @override
  String get deskSetReportPartFullDetails => 'Full details';

  @override
  String get txTrustedNetworks => 'Trusted networks';

  @override
  String txTrustedNetworksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trusted',
      one: '$count trusted',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String get txTrustedNetworksBody =>
      'Link · HTTP receives only on trusted networks. A forgotten network is asked about again the next time the phone joins it.';

  @override
  String get txTrustedNetworksNone => 'No trusted network yet.';

  @override
  String get txTrustedNetworkCurrent => 'This network';

  @override
  String get txTrustedNetworkForget => 'Forget';

  @override
  String txTrustedNetworkForgetLabel(String range) {
    return 'Forget $range';
  }

  @override
  String txTrustedNetworkRange(String range) {
    return '$range.x';
  }

  @override
  String get deskSetReportFullDetailsInfo =>
      'Sends addresses and amounts in full instead of shortened. Recovery phrases, keys and passwords are never sent.';

  @override
  String get deskOutNoteWaitingRecipient => 'waiting for the recipient';

  @override
  String get deskSlotNotPosted => 'Payment not posted';

  @override
  String get txOtherWalletMore => 'Payments by another wallet';

  @override
  String get finalizeNotPostedHelp => 'Paying from Kill switch';

  @override
  String get deskActSearchHintFull => 'Note, contact, address or amount';

  @override
  String get deskOutFilterWaiting => 'Waiting';

  @override
  String deskRecvHeaderTip(String methods) {
    return 'Receiving: $methods';
  }

  @override
  String deskSendHintNeedsMethod(String method) {
    return 'Review needs $method';
  }

  @override
  String get deskSetAboutVersionLabel => 'Version';

  @override
  String get deskSetAboutNodeLabel => 'Node';

  @override
  String deskTxNowConfirmedBlock(int confirmations, String block) {
    final intl.NumberFormat confirmationsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String confirmationsString = confirmationsNumberFormat.format(
      confirmations,
    );

    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Confirmed, $confirmationsString confirmations · block $block.',
      one: 'Confirmed, $confirmationsString confirmation · block $block.',
    );
    return '$_temp0';
  }

  @override
  String deskKitNoAnswerSince(String time) {
    return 'No answer since $time';
  }

  @override
  String get deskKitMoreInHelp => 'More in Help';

  @override
  String get homeReceiveEpicButton => 'Receive EPIC';

  @override
  String txDeviceStatusMadeOn(String device) {
    return 'Made on $device.';
  }

  @override
  String txDeviceStatusHeld(String device) {
    return 'Made on $device. Coins held here until the chain shows it.';
  }

  @override
  String get deskSendEpicboxNodeOnly =>
      'Node only is on: Epicbox is off. Direct · File Transfer works.';

  @override
  String deskSendEpicboxNodeOnlyTab(String method) {
    return 'Node only is on: Epicbox is off. $method works.';
  }

  @override
  String get deskSendLinkNodeOnly =>
      'Node only is on: Link is off. Direct · File Transfer works.';

  @override
  String deskSendLinkNodeOnlyTab(String method) {
    return 'Node only is on: Link is off. $method works.';
  }

  @override
  String get deskSendKillSwitch =>
      'Kill switch is on: nothing connects. Direct · File Transfer works.';

  @override
  String deskSendKillSwitchTab(String method) {
    return 'Kill switch is on: nothing connects. $method works.';
  }

  @override
  String get levelStepTitle => 'How much wallet do you want?';

  @override
  String get levelOneTitle => 'Just send and receive';

  @override
  String get levelOneLine => 'Money in, money out. Nothing to learn.';

  @override
  String get levelTwoTitle => 'Not too techy, but tell me what’s happening';

  @override
  String get levelTwoLine => 'Plain words about what the wallet is doing.';

  @override
  String get levelThreeTitle => 'Let me explore everything';

  @override
  String get levelThreeLine => 'Every switch, every number. Mind the knobs.';

  @override
  String get levelUndercoverTitle => 'Undercover from the start';

  @override
  String get levelUndercoverLine => 'Tor only, from the first connection.';

  @override
  String get levelFooter => 'Change it any time in Settings › Advanced.';

  @override
  String get levelRowTitle => 'Wallet view';

  @override
  String get levelChangeTitle => 'Change view';

  @override
  String get lvPickTitle => 'Pick your view';

  @override
  String get lvPickLead => 'How much of the wallet do you want to see?';

  @override
  String get lvPickStopOne => 'Shallow';

  @override
  String get lvPickStopTwo => 'Deeper';

  @override
  String get lvPickStopThree => 'Deep end';

  @override
  String get lvPickLineOne => 'Send, receive, done. The wallet minds the rest.';

  @override
  String get lvPickLineTwo => 'See what it’s doing, in plain words.';

  @override
  String get lvPickLineThree => 'Every switch, every number. All yours.';

  @override
  String get lvPickNone => 'Pick a stop';

  @override
  String get lvPickNoneLine => 'The preview follows the dial.';

  @override
  String get lvPickDepth => 'View';

  @override
  String get lvPickPreview =>
      'Preview of the home screen. It shows more as the dial goes deeper.';

  @override
  String get lvPickHelpTitle => 'What this decides';

  @override
  String get lvPickHelpText =>
      'Only how much the app shows. Every view sends and receives the same way, with the same keys and the same coins.';

  @override
  String get lvPickUndercoverHelp =>
      'Tor only, from the first connection. Every connection goes through Tor; starting takes longer.\n\nNothing has connected yet. Same as Network mode › Tor only; it can be turned off later in Settings › Advanced.';

  @override
  String get lvPickUndercoverHelpNet =>
      'Tor only, from the first connection. Every connection goes through Tor; starting takes longer.\n\nNothing has connected yet. Same as Network mode › Tor only; it can be turned off later in Settings › Network & privacy.';

  @override
  String get lvPickUndercover => 'Undercover';

  @override
  String get lvPickUndercoverLaterHelp =>
      'Tor only. Every connection goes through Tor; starting takes longer. Where Tor is blocked, the wallet cannot connect until this is off.';

  @override
  String get lvPickTakesEffect => 'Takes effect right away.';

  @override
  String get lvPickSaved => 'View saved';

  @override
  String get lvPickTorTitle => 'Connecting through Tor';

  @override
  String get lvPickTorLead =>
      'The first connection can take a minute. Nothing goes around Tor.';

  @override
  String get lvPickTorBusy => 'Building the circuit…';

  @override
  String get lvPickTorBlocked =>
      'If Tor is blocked where you are, the wallet cannot connect until Undercover is turned off.';

  @override
  String get lvPickTorOff => 'Turn Undercover off';

  @override
  String get lvPickTorOffDone => 'Undercover is off. Connecting directly.';

  @override
  String get lvPickNetworkOk => 'Network OK';

  @override
  String get lvPickEpicboxOk => 'Epicbox OK';

  @override
  String get lvPayArriving => 'Arriving';

  @override
  String lvPayConfirming(int count, int target) {
    return 'Confirming $count of $target';
  }

  @override
  String lvPayConfirmingOf(int count, int target) {
    return 'Confirming $count of $target';
  }

  @override
  String lvPaySigned(String name) {
    return '$name signed';
  }

  @override
  String get lvPaySendQrLink => 'Both phones here? QR Payment';

  @override
  String get lvPaySendAddressLink => 'Send to an address instead';

  @override
  String get lvPayOnItsWay => 'On its way';

  @override
  String get lvPayCloseNote =>
      'You can close this. It shows under Activity until it is done.';

  @override
  String lvPayArrivalFrom(String amount, String name) {
    return '$amount from $name';
  }

  @override
  String get lvPayOpen => 'Open';

  @override
  String get lvPayNewToday => 'New today';

  @override
  String get lvPayNewAddress => 'Your new address';

  @override
  String lvPayServerLine(String name) {
    return 'Epicbox server: $name.';
  }

  @override
  String get lvPayOldAddressLine =>
      'Anyone with the old address needs the new one.';

  @override
  String get lvPayReceiveBack => 'Back to my address';

  @override
  String lvPayDoneSent(String when) {
    return 'Sent. Done: $when.';
  }

  @override
  String lvPayDoneReceived(String when) {
    return 'Received. Done: $when.';
  }

  @override
  String get lvPayShowSteps => 'Show the steps';

  @override
  String get lvPayHideSteps => 'Hide the steps';

  @override
  String get lvPayDetails => 'Details';

  @override
  String get lvPayStarted => 'Started';

  @override
  String get lvPayPosted => 'Posted to the network';

  @override
  String get lvPayPaymentId => 'Payment ID';

  @override
  String get lvPayConfirmations => 'Confirmations';

  @override
  String lvPayOf(int count, int target) {
    return '$count of $target';
  }

  @override
  String get lvPayCopyDetails => 'Copy details';

  @override
  String get lvPayDetailsCopied => 'Details copied';

  @override
  String lvShellStatusTip(String name, String state) {
    return '$name · $state';
  }

  @override
  String get lvShellStateBehind => 'Behind';

  @override
  String get lvShellStateCatchingUp => 'Catching up';

  @override
  String get lvShellStateConnecting => 'Connecting';

  @override
  String get lvShellOpensDetails => 'Shows details';

  @override
  String get lvShellLatestBlock => 'Latest block';

  @override
  String get lvShellThisWallet => 'This wallet';

  @override
  String get lvShellUpToDate => 'Up to date';

  @override
  String get lvShellNotChecked => 'Not checked yet';

  @override
  String get lvShellLastChange => 'Last change';

  @override
  String get lvShellBoxListening => 'Connected · listening for payments';

  @override
  String get lvShellBoxNotReachable => 'Not reachable · keeps trying';

  @override
  String get lvShellBoxDownBody =>
      'Payments to you wait and arrive when the server is back. Nothing changes unless you switch.';

  @override
  String lvShellOfferReady(String name) {
    return '$name is ready';
  }

  @override
  String lvShellOfferBody(String name) {
    return 'Switching gives you a new address on $name. Anyone with your old address needs the new one.';
  }

  @override
  String lvShellSwitchTo(String name) {
    return 'Switch to $name';
  }

  @override
  String get lvShellKeepWaiting => 'Keep waiting';

  @override
  String lvShellRelayDownNotice(String name) {
    return 'Your Epicbox server is not reachable. Payments to you wait. $name is ready to take over; your address changes with it.';
  }

  @override
  String lvShellSwitchedNotice(String name) {
    return 'Now on $name. Your new address is ready.';
  }

  @override
  String lvShellNowOn(String name) {
    return 'Now on $name';
  }

  @override
  String get lvShellSwitchedBody =>
      'Your new address is ready. Anyone with your old address needs the new one.';

  @override
  String get lvShellShowNewAddress => 'Show new address';

  @override
  String get lvShellServer => 'Server';

  @override
  String get lvShellAddress => 'Address';

  @override
  String lvShellPairNotice(String name) {
    return '$name wants to pair with this wallet.';
  }

  @override
  String get lvShellSeeRequest => 'See request';

  @override
  String lvShellQuietArriving(String amount) {
    return '+$amount arriving';
  }

  @override
  String lvShellQuietOnHold(String amount) {
    return '$amount on hold';
  }

  @override
  String get lvShellLevelCaption =>
      'A deeper view shows more of the wallet. Nothing stored changes.';

  @override
  String get lvPolPosted => 'Posted';

  @override
  String get lvPolInvoiceWaiting => 'Invoice · waiting for your approval';

  @override
  String lvPolAbout(String name) {
    return 'About $name';
  }

  @override
  String get deskLvStartPreviewLabel =>
      'Preview of the Overview. It shows more as the dial goes deeper.';

  @override
  String get deskLvStartPreviewCaption =>
      'Your Overview in this view. Nothing stored changes between views.';

  @override
  String get deskLvStartPreviewCaptionShort => 'Your Overview in this view.';

  @override
  String get deskLvStartCover => 'Pick a stop to see the preview';

  @override
  String get deskLvStartUndercoverAbout => 'About Undercover';

  @override
  String get deskLvStartChangeLater =>
      'Change it any time in Settings › Advanced.';

  @override
  String get deskLvStartHelpShallow =>
      'Shallow · one address, no server names, no switches.';

  @override
  String get deskLvStartHelpDeeper =>
      'Deeper · the same wallet, plus what it is doing, in plain words.';

  @override
  String get deskLvStartHelpDeep =>
      'Deep end · every switch, every number: today’s app.';

  @override
  String get deskLvStartPickFirst =>
      'Pick a view first. Nothing connects until you do.';

  @override
  String get deskLvStartMiniWallet => 'Main wallet';

  @override
  String get deskLvStartMiniLine => '+12.5000 arriving · 25.0000 on hold';

  @override
  String get deskLvStartMiniFresh => 'Fresh from mining';

  @override
  String get deskLvStartMiniWaiting => 'Waiting for the other side';

  @override
  String get deskLvStartAdvNote =>
      'A deeper view shows more of the wallet. Nothing stored changes.';

  @override
  String deskLvStartAboutDepth(String name) {
    return 'View: $name';
  }

  @override
  String get deskLvSendHowTo => 'How to send it';

  @override
  String get deskLvSendButton => 'Send';

  @override
  String deskLvSendButtonAmount(String amount) {
    return 'Send $amount EPIC';
  }

  @override
  String deskLvSendButtonTo(String amount, String name) {
    return 'Send $amount EPIC to $name';
  }

  @override
  String get deskLvSendNothingLeaves =>
      'Nothing leaves until you press Send. After that it cannot be taken back.';

  @override
  String get deskLvSendPasswordTitle => 'Your password';

  @override
  String get deskLvSendConfirm => 'Send';

  @override
  String deskLvSendLiveTo(String name) {
    return 'On its way to $name';
  }

  @override
  String deskLvSendLiveAmountTo(String amount, String name) {
    return '$amount EPIC to $name';
  }

  @override
  String deskLvSendLiveAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskLvSendYourAddress => 'Your address';

  @override
  String get deskLvSendReady => 'Ready to receive';

  @override
  String get deskLvSendClosedInfo =>
      'Payments sent while the wallet is closed arrive when it opens.';

  @override
  String get deskLvSendPayFiles => 'Payment files';

  @override
  String get deskLvSendSignFile => 'Sign a payment file';

  @override
  String get deskLvSendSignFileText =>
      'Open the file the sender gave you and save your reply.';

  @override
  String get deskLvSendFinishFile => 'Finish a reply file';

  @override
  String get deskLvSendFinishFileText =>
      'Open the reply you got back to post the payment.';

  @override
  String get deskLvSendPrevAddress => 'Previous address';

  @override
  String deskLvSendPrevText(String server) {
    return 'The old address was on $server. Anyone who has it needs the new one.';
  }

  @override
  String get deskLvPayS1Sent => 'Slate S1 sent over Epicbox · waiting for S2';

  @override
  String deskLvPayS1On(String relay) {
    return 'S1 on $relay · awaiting S2';
  }

  @override
  String deskLvPayNotOpen(String name) {
    return '$name’s wallet is not open yet';
  }

  @override
  String deskLvPayWaitingOpen(String name) {
    return 'Waiting for $name’s wallet to open';
  }

  @override
  String get deskLvPaySenderFinished => 'Sender finished';

  @override
  String get deskLvPayPostedNode => 'Posted to node';

  @override
  String deskLvPayConfirmingComma(int count, int target) {
    return 'Confirming, $count of $target';
  }

  @override
  String deskLvPayConfirmationsOf(int count, int target) {
    return 'Confirmations $count / $target';
  }

  @override
  String get deskLvPayDone => 'Done';

  @override
  String deskLvPayOnItsWayTo(String name) {
    return 'On its way to $name';
  }

  @override
  String deskLvPaySendingTo(String name) {
    return 'Sending to $name';
  }

  @override
  String deskLvPayArrivingFrom(String name) {
    return 'Arriving from $name';
  }

  @override
  String deskLvPayStartedAt(String amount, String time) {
    return '$amount EPIC · started $time';
  }

  @override
  String deskLvPayHeroArriving(String amount, String name) {
    return '+$amount arriving from $name';
  }

  @override
  String deskLvPayHeroArrivingMany(String amount) {
    return '+$amount arriving';
  }

  @override
  String deskLvPayHeroHold(String amount, String name) {
    return '$amount on hold until $name signs';
  }

  @override
  String deskLvPayHeroHoldMany(String amount) {
    return '$amount on hold until signed';
  }

  @override
  String get deskLvPayHeroNothing => 'Nothing arriving yet.';

  @override
  String get deskLvPayReadyTitle => 'Your wallet is ready.';

  @override
  String get deskLvPayReadyHead => 'Wallet ready';

  @override
  String get deskLvPayReadyText => 'Share the address to get the first EPIC.';

  @override
  String get deskLvPayTileConfirming => 'Still confirming';

  @override
  String get deskLvPayTileMining => 'Fresh from mining';

  @override
  String get deskLvPayTileWaiting => 'Waiting for the other side';

  @override
  String get deskLvPayTileAwaiting => 'Awaiting reply';

  @override
  String get deskLvPayTileLocked => 'Set aside for sends';

  @override
  String get deskLvPayImmatureCasual => 'Fresh from mining, not spendable yet';

  @override
  String get deskLvPayKind => 'Payment';

  @override
  String get deskLvShellNewsTitle => 'New: wallet view';

  @override
  String get deskLvShellNewsText =>
      'This install shows everything, as before. Shallow and Deeper show less.';

  @override
  String get deskLvShellNewsLook => 'Have a look';

  @override
  String get deskLvShellFailover => 'Failover';

  @override
  String get deskLvShellOn => 'On';

  @override
  String get deskLvShellHeight => 'Height';

  @override
  String get deskLvShellVersion => 'Version';

  @override
  String get deskLvShellRecheckHint =>
      'If an amount looks wrong, the wallet reads the chain again.';

  @override
  String get lvShellSwitchServer => 'Switch server';

  @override
  String get lvShellNoOtherServer => 'No other server in the list.';

  @override
  String get deskLvShellSwitchServer => 'Switch server';

  @override
  String get deskLvShellNoOtherServer => 'No other server in the list.';

  @override
  String get deskLastSessionFroze =>
      'The app stopped responding last time. Send the log?';

  @override
  String get deskLastSessionClosed =>
      'The app closed unexpectedly last time. Send the log?';

  @override
  String get deskLastSessionSend => 'Send';

  @override
  String get deskLastSessionNotNow => 'Not now';

  @override
  String get deskLastSessionReportFroze => 'The app stopped responding.';

  @override
  String get deskLastSessionReportClosed => 'The app closed unexpectedly.';

  @override
  String get deskLastSessionAttached => 'With the log of the last session.';

  @override
  String get deskSetPrivUndercoverLine => 'Undercover keeps Tor on.';

  @override
  String get deskSetPrivUndercoverChange => 'Change Undercover';

  @override
  String get deskNodeEtaCalculating => 'Calculating time left…';

  @override
  String deskNodeEtaLeft(String time) {
    return 'about $time left';
  }

  @override
  String get deskNodeEtaMinute => 'a minute';

  @override
  String deskNodeEtaMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String deskNodeEtaHours(int hours) {
    return '$hours h';
  }

  @override
  String deskNodeEtaHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String deskNodeSwitchConnecting(String host) {
    return 'Connecting to $host…';
  }

  @override
  String get deskNodeSwitchStarting => 'Starting the local node…';

  @override
  String get deskNodeSwitchStopping => 'Stopping the local node…';

  @override
  String get deskNodeSwitchStoppingWord => 'Stopping';

  @override
  String get deskOnbFailedTitle => 'Not finished';

  @override
  String get deskDemoStripe => 'Demo · sample data';

  @override
  String deskOnbRestoreBadWords(String words) {
    return 'Not in the word list: $words.';
  }

  @override
  String get deskSetupExistingNodeType => 'Existing node';

  @override
  String get deskLvPayOnEpicbox => 'On Epicbox';

  @override
  String get deskRailReceivingInternet => 'Receiving · internet';

  @override
  String get deskRailReceivingLocal => 'Receiving · local';

  @override
  String get deskOnbImportFoundLead => 'Continue to choose the wallets to add.';

  @override
  String get deskOnbForgotFailedTitle => 'Password not changed';

  @override
  String get deskOnbForgotFailedLead =>
      'The current password still opens the wallet.';

  @override
  String get deskSetHelpSupportHead => 'Support';

  @override
  String get deskSetHelpTopicsHead => 'Topics';

  @override
  String deskKitPasswordRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters or more',
      one: '$count character or more',
    );
    return '$_temp0';
  }

  @override
  String trustLineOtherApp(Object name) {
    return '$name’s last payment was answered by another wallet app.';
  }

  @override
  String trustLineNotHeard(Object name, Object date) {
    return 'Not heard from $name’s wallet since $date.';
  }

  @override
  String get mailboxNotAnswered => 'Not answered yet';

  @override
  String get mailboxNotPickedUp => 'Not picked up';

  @override
  String mailboxNeverPickedUp(Object name) {
    return '$name’s wallet never picked this up.';
  }

  @override
  String get mailboxResendTitle => 'Cancel and send by Epicbox';

  @override
  String mailboxResendBody(Object name) {
    return 'The waiting send is cancelled and the same amount goes to $name’s Epicbox address as an ordinary payment. Two rows stay in the history.';
  }

  @override
  String get mailboxResendAction => 'Cancel and send';

  @override
  String get mailboxKeepWaiting => 'Keep waiting';

  @override
  String get mailboxResent => 'Cancelled and sent by Epicbox.';

  @override
  String get torRelayCaption =>
      'Over Tor the relay does not see this device’s address.';

  @override
  String get inviteLinkUnreadable => 'This link can\'t be opened.';

  @override
  String inviteLinkNoHandler(String feature) {
    return '$feature is off or not available in this wallet.';
  }

  @override
  String get linkShowMine => 'Show my QR';

  @override
  String get linkPasteAnother => 'Paste another invite';

  @override
  String linkLinkingWith(String name) {
    return 'Linking with $name…';
  }

  @override
  String linkLinkingSame(String name) {
    return '$name shows the same four.';
  }

  @override
  String linkFailFull(String name) {
    return '$name is linked to another device already. Remove that one on $name first.';
  }

  @override
  String get linkFailUpdate =>
      'The other device has a newer app. Update this one, then try again.';

  @override
  String linkFailUpdateOther(String name) {
    return '$name has an older app. Update it, then try again.';
  }

  @override
  String linkReplaceTitle(String name) {
    return 'Replace $name?';
  }

  @override
  String linkReplaceBody(String name) {
    return 'A new device asked to link. $name stops getting this wallet’s notices; coins it holds here are released.';
  }

  @override
  String get linkReplace => 'Replace';

  @override
  String linkKeep(String name) {
    return 'Keep $name';
  }

  @override
  String devicesEpicboxOff(String name) {
    return 'Epicbox is off: $name does not see this device’s payments.';
  }

  @override
  String get devicesEpicboxOffNone => 'Epicbox is off.';

  @override
  String devicesUpdateOther(String name) {
    return 'Update $name to keep this wallet in sync.';
  }

  @override
  String get devicesAbout => 'About the linked device';

  @override
  String get offerLinkThird =>
      'A third device has this wallet. Two can be linked.';

  @override
  String devicesForwardedInvoice(String name) {
    return '$name received a request to pay. Pay it there.';
  }

  @override
  String get linkConfirmInvite =>
      'Link this device with the one that sent the invite?';

  @override
  String get pairYourCode => 'Your invite';

  @override
  String get pairCodeCaption => 'Let them scan the QR, or send the invite.';

  @override
  String pairCodeCaptionFor(String name) {
    return 'Let $name scan the QR, or send the invite.';
  }

  @override
  String pairSeenAsLine(String name) {
    return 'They see you as $name';
  }

  @override
  String get pairChange => 'Change';

  @override
  String get pairSeenAsField => 'They see you as';

  @override
  String get pairCopyLink => 'Copy invite';

  @override
  String get pairHaveTheirCode => 'Have their invite?';

  @override
  String pairHaveNamesCode(String name) {
    return 'Have $name’s invite?';
  }

  @override
  String get pairScan => 'Scan QR';

  @override
  String get pairPasteField => 'Paste the invite';

  @override
  String get pairNotACode => 'Not a pairing invite.';

  @override
  String get pairEpicboxOffLine =>
      'Epicbox is off. Paste the answer below when it comes back.';

  @override
  String get pairWaitingAnswer => 'Waiting for the answer…';

  @override
  String pairAnsweredFinishing(String name) {
    return '$name answered your invite. Waiting for $name’s wallet to finish.';
  }

  @override
  String get pairFinishCodeTitle => 'Confirmation';

  @override
  String pairFinishCodeBody(String name) {
    return 'Send this to $name. The words check opens when that wallet reads it.';
  }

  @override
  String get pairYourAnswerBody =>
      'Send it back the way the invite came. Then paste what comes back.';

  @override
  String get pairPasteFinishField => 'Paste the confirmation';

  @override
  String pairPairingWith(String name) {
    return 'Pairing with $name…';
  }

  @override
  String get pairInContacts => 'In your contacts';

  @override
  String get pairRequestBody =>
      'A request goes to this contact’s Epicbox address. Their wallet shows it when it is open.';

  @override
  String get pairSendRequest => 'Send request';

  @override
  String get pairShowMyCodeInstead => 'Show my invite instead';

  @override
  String pairRequestSent(String date) {
    return 'Request sent · $date';
  }

  @override
  String pairWaitingFor(String name) {
    return 'Waiting for $name’s wallet';
  }

  @override
  String get pairAnsweredNotHeard => 'Answered your invite · not heard yet';

  @override
  String pairNotChecked(String name) {
    return '$name has not checked yet';
  }

  @override
  String pairConfirmedToo(String name) {
    return '$name confirmed too.';
  }

  @override
  String get pairEndedShort => 'Pairing ended';

  @override
  String get pairEndedMismatch => 'You reported the words do not match.';

  @override
  String pairEndedPeerMismatch(String name) {
    return '$name reported the words do not match.';
  }

  @override
  String pairEndedNeverFinished(String name) {
    return '$name’s wallet never finished.';
  }

  @override
  String pairNoAnswerFrom(String name) {
    return 'No answer from $name’s wallet';
  }

  @override
  String get pairAgain => 'Pair again';

  @override
  String get pairAddressNotConfirmed => 'Address not confirmed by pairing.';

  @override
  String get pairHeldSend => 'Waiting for recipient';

  @override
  String pairProvesOther(String name) {
    return '$name’s wallet proves another address';
  }

  @override
  String get pairUpdateAddress => 'Update the contact’s address';

  @override
  String get pairDetach => 'Detach';

  @override
  String get pairCheckWords => 'Check the words';

  @override
  String pairWantsToPair(String name) {
    return '$name wants to pair.';
  }

  @override
  String pairPairedWith(String name) {
    return 'Paired with $name.';
  }

  @override
  String pairPairedOn(String device) {
    return 'Paired on $device.';
  }

  @override
  String pairRequestsRow(int count) {
    return 'Pair requests · $count';
  }

  @override
  String get pairRequestsTitle => 'Pair requests';

  @override
  String get pairEndedNotice =>
      'The pairing ended. Pair again with a fresh invite.';

  @override
  String get pairOtherWalletTitle => 'This answer came from another wallet.';

  @override
  String get pairOtherWalletBody => 'Nothing was stored.';

  @override
  String pairNotProvenBody(String name) {
    return 'No Epic Cash payment with $name yet, so a request cannot be sent.';
  }

  @override
  String pairInProgressTitle(String name) {
    return 'A pairing with $name is under way.';
  }

  @override
  String pairCrossedTitle(String name) {
    return '$name’s wallet also started a pairing. Waiting for its answer.';
  }

  @override
  String pairDismissedTitle(String name) {
    return 'This request was dismissed. Ask $name to send a new one.';
  }

  @override
  String get pairEndedBody =>
      'Nothing new goes through it. Remove it, or pair again with a fresh invite.';

  @override
  String get pairWaitingSendBody => 'Send by Epicbox instead.';

  @override
  String get pairNotFoundTitle => 'No pairing matches this.';

  @override
  String get trustWaiting => 'Waiting';

  @override
  String get trustEnded => 'Ended';

  @override
  String get pairRequestPair => 'Pair';

  @override
  String get pairCancelPairingTitle => 'Cancel this pairing?';

  @override
  String pairCancelPairingBody(String name) {
    return '$name’s wallet is told if it answers late. Nothing is kept.';
  }

  @override
  String get pairCancelPairing => 'Cancel pairing';

  @override
  String get pairBackLater => 'Back';

  @override
  String get helpPairTwoWaysTitle => 'Two ways to pair';

  @override
  String get helpPairTwoWaysShort => 'A request to a contact, or your code.';

  @override
  String get helpPairTwoWaysP1 =>
      '**Pair with a contact.** On a contact you have paid or been paid by over Epicbox, Pair sends a request to that address. Their wallet shows it when it is open; one tap answers. Both wallets end Verified without a words check: the request and the answer each prove the address already in the other’s Contacts.';

  @override
  String get helpPairTwoWaysP2 =>
      '**Pair by code.** Contacts › Pair shows your code, good for 7 days. The other wallet scans it or opens the link; both finish over Epicbox and then compare the four words. With Epicbox off on either side, the same screen carries the answer and the finish code by hand: Share and Paste.';

  @override
  String get helpPairTwoWaysP3 =>
      'A request is sent only to a wallet that has shown it runs Epic Cash: a marked payment between the two addresses within the last 30 days. For anyone else, Pair shows your code.';

  @override
  String get helpPairWhyTitle2 => 'Why check the words';

  @override
  String get helpPairWhyShort2 => 'Compare them in person, by voice or video.';

  @override
  String get helpPairWhyP1b =>
      'After pairing by code both wallets show the same four pictures and names. Compare them with the other person in person, by voice or on a video call, never in the chat the code came through: whoever could change the code on the way could also change what that chat shows.';

  @override
  String get helpPairWhyP2b =>
      '**They match** marks the contact Verified; the other wallet learns of it and shows “confirmed too”. **They do not match** ends the pairing on both sides and nothing sent through it is finished. A mistaken No ends it too: pair again with a fresh code.';

  @override
  String get helpPairWhyP3b =>
      'Verified means the wallet behind the address in your Contacts. After a request between two contacts it is set without words, because the request and the answer each proved that address.';

  @override
  String get helpPairWhyP4b =>
      '“Proven” means a payment marked by both wallets has passed between the two Epicbox addresses within 30 days. A contact answered by another wallet app since then is not proven until the next marked payment.';

  @override
  String get pairStandingFootnote =>
      'Good for 7 days. A new invite appears when this one is used.';

  @override
  String get storeEncrypting => 'Encrypting wallet records…';

  @override
  String get storeRecordsPlain =>
      'Wallet records stay unencrypted for now. The app tries again next time.';

  @override
  String get errorStoreWrongKey =>
      'This wallet\'s records could not be opened with this phrase. Nothing was changed.';

  @override
  String get contactsClosedTitle => 'Address book closed';

  @override
  String get contactsClosedText =>
      'It opens once a wallet that uses it is unlocked.';

  @override
  String get pairSeenAsAskTitle => 'Name others see';

  @override
  String get pairSeenAsHint => 'Your name';

  @override
  String devicesNameWithCode(String name, String code) {
    return '$name $code';
  }

  @override
  String get deskSetDlgRemoveUnlockHintSecurity =>
      'To delete its files as well, unlock this wallet and use Delete wallet under Settings › Security.';

  @override
  String get deskRecvHttpTorHintNet =>
      'Turn on Tor in Settings › Network & privacy for a Tor address instead.';

  @override
  String get deskRecvTorIntroNet =>
      'Straight from another wallet over Tor while this one is open. Tor is set in Settings › Network & privacy.';

  @override
  String get deskRecvTorOffTextNet =>
      'The Tor address works while Tor is on. Tor is the switch in Settings › Network & privacy; it routes the wallet’s connections through Tor.';

  @override
  String get deskSetTxTorHintNet =>
      'Pay and get paid straight from wallet to wallet at an onion address, over Tor, with no server between. Works only while both wallets are open. Needs Tor: the Tor switch under Network & privacy routes the wallet’s connections through Tor; this switch only turns the address on. Adds Link · Tor to Send and its address to Receive.';

  @override
  String get deskSetTxTorNeedsTorNet =>
      'Tor is off. Turn it on under Network & privacy to be paid at the Tor address.';

  @override
  String get deskRailOpenNetworkPrivacy => 'Open Network & privacy';
}
