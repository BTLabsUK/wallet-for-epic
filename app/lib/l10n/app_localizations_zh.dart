// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Mobile';

  @override
  String get appTitleDesktop => 'Epic Cash Desktop';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get noticeLevelInfo => '提示';

  @override
  String get noticeLevelSuccess => '完成';

  @override
  String get noticeLevelWarning => '警告';

  @override
  String get noticeLevelError => '错误';

  @override
  String get commonContinue => '继续';

  @override
  String get commonCopy => '复制';

  @override
  String get commonDelete => '删除';

  @override
  String get commonDone => '完成';

  @override
  String get commonError => '错误';

  @override
  String get commonOk => '确定';

  @override
  String get commonPaste => '粘贴';

  @override
  String get commonRetry => '重试';

  @override
  String get commonSave => '保存';

  @override
  String get commonShare => '分享';

  @override
  String get commonUnknown => '未知';

  @override
  String get passwordShow => '显示密码';

  @override
  String get passwordHide => '隐藏密码';

  @override
  String get slateCopyTooltip => '复制交易文本';

  @override
  String get slateCopied => '交易文本已复制';

  @override
  String get slatePastedTitle => '粘贴的付款';

  @override
  String get slateCopyReply => '复制回复';

  @override
  String get biometricPromptTitle => '解锁钱包';

  @override
  String get biometricPromptSubtitle => '使用指纹或面容验证';

  @override
  String get biometricPromptUsePin => '使用 PIN 码';

  @override
  String get amountEnterExample => '请输入金额，例如 1.5';

  @override
  String amountTooManyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最多 $count 位小数',
    );
    return '$_temp0';
  }

  @override
  String dateWithTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String get txMiningReward => '挖矿奖励';

  @override
  String get txRestoredFunds => '恢复的资金';

  @override
  String get txOutgoingPayment => '发出的付款';

  @override
  String get txIncomingPayment => '收到的付款';

  @override
  String get txStatusWaitingRecipient => '等待接收方';

  @override
  String get txStatusWaitingSender => '等待发送方';

  @override
  String txStatusConfirming(int count, int target) {
    return '确认中 $count/$target';
  }

  @override
  String get txStatusCompleted => '已完成';

  @override
  String get txStatusCancelled => '已取消';

  @override
  String get txStatusFromBackup => '来自备份，状态未知';

  @override
  String get txIconCancelled => '已取消';

  @override
  String get txIconIncoming => '转入';

  @override
  String get txIconOutgoing => '转出';

  @override
  String get txSpokenHiddenAmount => '隐藏的金额';

  @override
  String txSpokenMiningReward(String amount) {
    return '挖矿奖励 $amount';
  }

  @override
  String txSpokenRestoredFunds(String amount) {
    return '恢复的资金 $amount';
  }

  @override
  String txSpokenCancelledSend(String amount) {
    return '已取消发送 $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return '已取消向 $who 发送 $amount';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return '已取消接收 $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return '已取消接收来自 $who 的 $amount';
  }

  @override
  String txSpokenSending(String amount) {
    return '正在发送 $amount';
  }

  @override
  String txSpokenSendingTo(String amount, String who) {
    return '正在向 $who 发送 $amount';
  }

  @override
  String txSpokenReceiving(String amount) {
    return '正在接收 $amount';
  }

  @override
  String txSpokenReceivingFrom(String amount, String who) {
    return '正在接收来自 $who 的 $amount';
  }

  @override
  String txSpokenSent(String amount) {
    return '已发送 $amount';
  }

  @override
  String txSpokenSentTo(String amount, String who) {
    return '已向 $who 发送 $amount';
  }

  @override
  String txSpokenReceived(String amount) {
    return '已收到 $amount';
  }

  @override
  String txSpokenReceivedFrom(String amount, String who) {
    return '已收到来自 $who 的 $amount';
  }

  @override
  String txSpokenRow(String what, String status, String date) {
    return '$what，$status，$date';
  }

  @override
  String get errorInvalidMnemonic => '助记词无效。请检查每个单词及其顺序。';

  @override
  String get errorWrongPassword => '密码错误。';

  @override
  String get errorWalletAlreadyExists => '此网络已有钱包。';

  @override
  String get errorWalletNotFound => '未找到此网络的钱包。';

  @override
  String get errorNodeUnreachable => '无法连接节点。请检查节点地址和网络连接。';

  @override
  String get errorNotEnoughFunds => '可用余额不足以支付该金额及手续费。';

  @override
  String get errorInvalidSlate => '此交易文本不适用于当前步骤。请检查是否已完整粘贴。';

  @override
  String get errorInvalidInput => '输入无效。';

  @override
  String get errorTransportFailed => '无法连接到接收方。';

  @override
  String get errorTorNotRunning => 'Tor 未连接。';

  @override
  String get errorOnionUnreachable => '未能通过 Tor 联系到对方钱包。';

  @override
  String get errorChainBusy => '钱包仍在另一个网络上处理任务。请稍后再试，或关闭并重新打开应用。';

  @override
  String get errorWalletBusy => '钱包仍在完成一项任务。请稍后再试。';

  @override
  String get errorPaymentExpired => '这笔付款的回复来得太晚，付款已取消。没有发送任何资金。';

  @override
  String get errorIo => '无法读取或写入钱包文件。';

  @override
  String get errorOther => '钱包错误。';

  @override
  String get errorScanFailed => '扫描失败。';

  @override
  String get errorUnexpected => '发生意外错误，请重试。';

  @override
  String get errorHistoryNotOurs => '此文件不是本应用导出的历史备份。';

  @override
  String get errorHistoryNewer => '此历史备份由更新版本的应用创建。';

  @override
  String get errorHistoryDamaged => '此历史备份已损坏。';

  @override
  String get errorHistoryOtherWallet => '此历史备份属于另一个钱包。';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return '此历史备份来自 $fileNetwork，但当前钱包位于 $walletNetwork。';
  }

  @override
  String get networkMainnet => '主网';

  @override
  String get networkFloonet => 'Floonet';

  @override
  String get networkUsernet => 'Usernet';

  @override
  String get networkMainnetDescription => '真实的 Epic Cash 网络。';

  @override
  String get networkFloonetDescription =>
      '用于试用本应用的公共测试网络。测试币没有价值，可在 floo-explorer.btlabs.uk 免费领取。';

  @override
  String get networkUsernetDescription => '在这台电脑上运行的测试网络，供开发者使用。';

  @override
  String networkTestSuffix(String network) {
    return '（$network，测试币）';
  }

  @override
  String get autoLockNever => '从不';

  @override
  String get autoLockImmediately => '立即';

  @override
  String autoLockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟后',
    );
    return '$_temp0';
  }

  @override
  String get scanStarting => '正在开始扫描';

  @override
  String scanProgress(int percent) {
    return '正在扫描区块链（$percent%）';
  }

  @override
  String get scanComplete => '扫描完成';

  @override
  String get languageSetting => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get currencyUsd => '美元';

  @override
  String get currencyEur => '欧元';

  @override
  String get currencyGbp => '英镑';

  @override
  String get currencyBtc => '比特币';

  @override
  String get currencyJpy => '日元';

  @override
  String get currencyCny => '人民币';

  @override
  String get currencyCad => '加元';

  @override
  String get currencyAud => '澳元';

  @override
  String get currencyChf => '瑞士法郎';

  @override
  String get currencyInr => '印度卢比';

  @override
  String get currencyBrl => '巴西雷亚尔';

  @override
  String get currencyKrw => '韩元';

  @override
  String get currencyPln => '波兰兹罗提';

  @override
  String get currencyTry => '土耳其里拉';

  @override
  String txDetailsWaitingTooLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '已等待 $days 天。epicbox 会在 7 天后删除付款，因此这笔付款已无法完成。请取消它以解锁资金，然后重新发送。',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      '已发送到接收方的 epicbox。对方钱包上线后即可完成。在此之前，或在你取消之前，你的资金将保持锁定。';

  @override
  String get txDetailsWaitingRecipient =>
      '正在等待接收方回复其交易文件。在此之前，或在你取消之前，你的资金将保持锁定。';

  @override
  String get txDetailsWaitingSender => '你已接受这笔付款。发送方完成并将其发布到网络后，付款即完成。';

  @override
  String get txDetailsPublished => '已发布到网络。正在等待第一个确认。';

  @override
  String get txDetailsWaitingConfirmation => '正在等待网络确认。';

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
      other: '$target 个',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '位于区块 $height。已有 $count 个确认，共需 $_temp0；约 $_temp1后完成最终确认。';
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
      other: '$target 个',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 小时',
    );
    return '位于区块 $height。已有 $count 个确认，共需 $_temp0；约 $_temp1后完成最终确认。';
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
      other: '$target 个',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天',
    );
    return '位于区块 $height。已有 $count 个确认，共需 $_temp0；约 $_temp1后完成最终确认。';
  }

  @override
  String get txDetailsCompleted => '已完成。';

  @override
  String txDetailsCompletedInBlock(String height) {
    return '已在区块 $height 中完成。';
  }

  @override
  String get txDetailsCancelledByUser => '已取消。没有发送任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledReleased =>
      '网络始终未接受这笔付款，因此其资金已释放。再次发送前，请确认接收方没有收到。';

  @override
  String get txDetailsCancelledNotOnChain =>
      '这笔付款未能在 14 天内进入网络，因此钱包已将其取消。再次发送前，请确认接收方没有收到。';

  @override
  String get txDetailsCancelledUnanswered =>
      '接收方未在 14 天内回复，因此钱包已将其取消。没有发送任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledLateAnswer =>
      '接收方在 14 天期限过后才回复，因此钱包取消了这笔付款，而没有完成它。没有发送任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledUndelivered =>
      '这笔付款无法送达接收方，因此钱包已立即将其取消。没有发送任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledIncoming => '已取消。这笔付款不会到账。';

  @override
  String get txDetailsFromBackup =>
      '这笔付款来自历史备份，备份时尚未完成。此钱包自身没有它的记录，因此无法判断它是否已完成。没有锁定任何资金。';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return '如果在区块 $height 前未完成，将自动取消。';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '如果在区块 $height 前未完成，将自动取消（约 $_temp0后）。';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 小时',
    );
    return '如果在区块 $height 前未完成，将自动取消（约 $_temp0后）。';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天',
    );
    return '如果在区块 $height 前未完成，将自动取消（约 $_temp0后）。';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return '已在区块 $height 过期。钱包将在下次刷新时取消它。';
  }

  @override
  String get txDetailsTitle => '付款';

  @override
  String get txDetailsLoading => '正在加载';

  @override
  String get txDetailsGone => '这笔付款已不在钱包中。';

  @override
  String get txDetailsWorking => '正在处理';

  @override
  String get txDetailsAmountHidden => '金额已隐藏';

  @override
  String get txDetailsNotConfirmedYet => '尚未确认';

  @override
  String get txDetailsStuckBody => '网络尚未接受这笔付款。重新广播是安全的，同一笔付款不会被执行两次。';

  @override
  String get txDetailsBroadcastAgain => '重新广播';

  @override
  String get txDetailsBroadcastAgainDone => '已重新广播。应会在几分钟内确认。';

  @override
  String get txDetailsRefusedBody => '网络拒绝了这笔付款，它从未上链。你可以释放它锁定的资金。';

  @override
  String get txDetailsReleaseFunds => '释放资金';

  @override
  String get txDetailsReleaseTitle => '释放资金？';

  @override
  String get txDetailsReleaseBody =>
      '仅在这笔付款永远不会确认时使用。如果它之后仍然确认，在你重新扫描之前，余额可能显示错误。';

  @override
  String get txDetailsReleaseKeepWaiting => '继续等待';

  @override
  String get txDetailsFundsReleased => '资金已释放';

  @override
  String get txDetailsCancelPayment => '取消付款';

  @override
  String get txDetailsCancelTitle => '取消付款？';

  @override
  String get txDetailsCancelReceiveBody =>
      '发送方仍可能完成这笔付款。如果对方在你取消后完成，在你重新扫描之前它不会显示。';

  @override
  String get txDetailsCancelSendBody => '取消这笔付款并解锁其资金？仅在接收方尚未完成时这样做。';

  @override
  String get txDetailsCancelKeep => '保留';

  @override
  String get txDetailsPaymentCancelled => '付款已取消';

  @override
  String get txDetailsDate => '日期';

  @override
  String get txDetailsCreated => '创建时间';

  @override
  String get txDetailsSentTo => '发送至';

  @override
  String get txDetailsReceivedFrom => '来自';

  @override
  String get txDetailsCopyAddress => '复制地址';

  @override
  String get txDetailsAddressCopied => '地址已复制';

  @override
  String get txDetailsAddToContacts => '添加到联系人';

  @override
  String get txDetailsSendAgain => '再次发送';

  @override
  String get txDetailsFee => '手续费';

  @override
  String get txDetailsNoteLabel => '备注';

  @override
  String get txDetailsPrivateNoteLabel => '私人备注，仅保存在本设备';

  @override
  String get txDetailsMessageFromSender => '发送方的留言';

  @override
  String get txDetailsMessageFromRecipient => '接收方的留言';

  @override
  String get txDetailsYourMessage => '你的留言';

  @override
  String get txDetailsNoNote => '暂无备注。添加备注，记下这笔付款的用途。';

  @override
  String get txDetailsAddNote => '添加备注';

  @override
  String get txDetailsEditNote => '编辑备注';

  @override
  String get txDetailsNoteDialogTitle => '备注';

  @override
  String get txDetailsNoteHelper => '仅保存在此设备和你的历史备份中。';

  @override
  String get txDetailsNoteSaved => '备注已保存';

  @override
  String get txDetailsNoteRemoved => '备注已删除';

  @override
  String get txDetailsExplorerLink => '复制区块浏览器链接';

  @override
  String get txDetailsExplorerLinkCopy => '复制区块浏览器链接';

  @override
  String get txDetailsLinkCopied => '链接已复制';

  @override
  String get txDetailsTechnical => '技术详情';

  @override
  String get txDetailsBlockHeight => '区块高度';

  @override
  String get txDetailsSlateId => 'Slate ID';

  @override
  String get txDetailsSlateIdCopy => '复制 Slate ID';

  @override
  String get txDetailsSlateIdCopied => 'Slate ID 已复制';

  @override
  String get txDetailsKernel => '内核';

  @override
  String get txDetailsKernelCopy => '复制内核';

  @override
  String get txDetailsKernelCopied => '内核已复制';

  @override
  String get txDetailsOutputCommitment => '输出承诺';

  @override
  String get txDetailsOutputCommitmentCopy => '复制输出承诺';

  @override
  String get txDetailsOutputCommitmentCopied => '输出承诺已复制';

  @override
  String txDetailsOutputCommitmentNumbered(int number) {
    return '输出承诺 $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopy(int number) {
    return '复制输出承诺 $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopied(int number) {
    return '输出承诺 $number 已复制';
  }

  @override
  String get txDetailsExpiryHeight => '过期高度';

  @override
  String get txDetailsLocalId => '本地 ID';

  @override
  String get txDetailsSourceRestored =>
      '通过扫描区块链找到。发送方和手续费等详情不会保存在链上；导入历史备份即可恢复。';

  @override
  String get txDetailsSourceImported => '从历史备份导入。此钱包自身没有它的记录，因此其状态可能已过时。';

  @override
  String get historyTitle => '交易记录';

  @override
  String get historyLoading => '正在加载付款';

  @override
  String get historyRefreshing => '正在刷新';

  @override
  String get historySearchLabel => '搜索';

  @override
  String get historySearchHint => '备注、联系人、地址或金额';

  @override
  String get historyClearSearch => '清除搜索';

  @override
  String get historyFilterAll => '全部';

  @override
  String get historyFilterSent => '已发送';

  @override
  String get historyFilterReceived => '已接收';

  @override
  String get historyFilterPending => '进行中';

  @override
  String get historyFilterCancelled => '已取消';

  @override
  String get historySectionPending => '进行中';

  @override
  String get historyEmpty => '暂无记录。你发送或接收的付款会显示在这里。';

  @override
  String get historyNoSent => '没有已发送的付款。';

  @override
  String get historyNoReceived => '没有已接收的付款。';

  @override
  String get historyNoPending => '没有进行中的付款。';

  @override
  String get historyNoCancelled => '没有已取消的付款。';

  @override
  String historyNoMatch(String query) {
    return '没有与“$query”匹配的结果。';
  }

  @override
  String get historyBackupSaveDialogTitle => '保存交易记录';

  @override
  String get historyBackupOpenDialogTitle => '打开历史备份';

  @override
  String get historyBackupFileTooLarge => '该文件过大，不可能是备份文件。';

  @override
  String get historyBackupShare => '分享';

  @override
  String get historyBackupShareSubtitle => '将副本保存到手机以外，例如电子邮件或云存储';

  @override
  String get historyBackupSaveToDevice => '保存到设备';

  @override
  String get historyBackupSaveToDeviceSubtitle => '仅在你同时将它复制到手机以外时才有用。';

  @override
  String historyBackupSaved(String fileName) {
    return '已保存 $fileName';
  }

  @override
  String get historyBackupExportTitle => '导出历史备份';

  @override
  String get historyBackupExportNote => '历史备份包含截至目前的付款。有新付款后请重新导出。';

  @override
  String get historyBackupCsvTitle => '导出 CSV';

  @override
  String get historyBackupCsvWarning =>
      'CSV 文件未加密。任何拿到它的人都能看到你的金额、日期、地址和备注。它无法再导入；如需可导入的备份，请使用“导出历史备份”。';

  @override
  String get historyBackupCsvConfirm => '导出 CSV';

  @override
  String get historyBackupImportedTitle => '已导入历史备份';

  @override
  String historyBackupImportFailed(String reason) {
    return '未能导入历史备份。$reason';
  }

  @override
  String get historyBackupImportNothingNew => '备份中没有新内容。';

  @override
  String historyBackupImportMerged(int merged) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged 笔付款已恢复详情',
    );
    return '$_temp0。';
  }

  @override
  String historyBackupImportAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    return '$_temp0。';
  }

  @override
  String historyBackupImportMergedAdded(int merged, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    return '$_temp0，$_temp1。';
  }

  @override
  String historyBackupImportSkipped(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    return '$_temp0。';
  }

  @override
  String historyBackupImportMergedSkipped(int merged, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    return '$_temp0，$_temp1。';
  }

  @override
  String historyBackupImportAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    return '$_temp0，$_temp1。';
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
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    return '$_temp0，$_temp1，$_temp2。';
  }

  @override
  String historyBackupImportContacts(int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0。';
  }

  @override
  String historyBackupImportMergedContacts(int merged, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1。';
  }

  @override
  String historyBackupImportAddedContacts(int added, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1。';
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
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1，$_temp2。';
  }

  @override
  String historyBackupImportSkippedContacts(int skipped, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1。';
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
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1，$_temp2。';
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
      other: '已添加 $added 笔较早的付款',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1，$_temp2。';
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
      other: '$merged 笔付款已恢复详情',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 笔较早的付款',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped 条记录已存在',
    );
    String _temp3 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '已添加 $contacts 个联系人',
    );
    return '$_temp0，$_temp1，$_temp2，$_temp3。';
  }

  @override
  String get homeLockTooltip => '锁定钱包';

  @override
  String get shellTitle => 'Epic Cash Mobile';

  @override
  String get demoWelcomeTitle => '试用 Epic Cash';

  @override
  String get demoWelcomeLine => '一个真正的钱包，附带免费的测试币，测试币没有价值。24 小时后删除。';

  @override
  String get demoStart => '开始演示';

  @override
  String get demoEndedTitle => '你的演示已结束';

  @override
  String get demoEndedBody => '它的钱包和测试币已删除。';

  @override
  String get demoStartAgain => '重新开始';

  @override
  String demoEndsAt(String time) {
    return '你的演示将于 $time 结束，届时它的钱包和测试币会被删除。';
  }

  @override
  String get demoEndingSoon => '你的演示将在 30 分钟后结束，届时它的钱包和测试币会被删除。';

  @override
  String get demoTestCoins => '获取测试币';

  @override
  String get demoTestCoinsPaid => '测试币已在路上，一两分钟内到账。';

  @override
  String demoTestCoinsCooldown(int seconds) {
    return '水龙头需要休息一下。请在 $seconds 秒后重试。';
  }

  @override
  String get demoTestCoinsFailed => '水龙头这次没有发送。请一分钟后重试。';

  @override
  String get demoEnd => '结束演示';

  @override
  String get demoEndTitle => '结束演示？';

  @override
  String get demoEndBody => '你的演示钱包及其测试币现在会被删除。之后可以开始新的演示。';

  @override
  String get demoServerUnreachable => '无法连接演示服务器。请检查网络连接后重试。';

  @override
  String demoStartFull(int minutes) {
    return '演示名额已满。请在 $minutes 分钟后重试。';
  }

  @override
  String demoStartTooMany(int minutes) {
    return '从你的网络启动的演示过多。请在 $minutes 分钟后重试。';
  }

  @override
  String get demoConnectionLost => '连接已断开，正在重新连接。';

  @override
  String get demoConnectionBack => '已重新连接。';

  @override
  String get homeSettingsTooltip => '设置';

  @override
  String get homeSettingsUpdateTooltip => '设置：有可用更新';

  @override
  String get homeSendButton => '发送';

  @override
  String get shellWalletTab => '钱包';

  @override
  String get homeReceiveButton => '接收';

  @override
  String get homeScanTooltip => '扫描二维码发送';

  @override
  String get homeRecentActivity => '最近交易';

  @override
  String get homeSeeAll => '查看全部';

  @override
  String get homeBackedUpNotice => '助记词已备份';

  @override
  String get homeNoticeView => '查看';

  @override
  String get homePushNotice => '你的 epicbox 中有一笔待接收的付款。应用连接后即可到账。';

  @override
  String get homeNoticeReceived => '有一笔付款正在途中。待发送方完成操作后即可到账。';

  @override
  String homeNoticeReceivedFrom(String who) {
    return '来自 $who 的付款正在途中。待发送方完成操作后即可到账。';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount 正在途中。待发送方完成操作后即可到账。';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '来自 $who 的 $amount 正在途中。待发送方完成操作后即可到账。';
  }

  @override
  String get homeNoticeFinished => '付款已完成，正在等待确认。';

  @override
  String homeNoticeFinishedTo(String who) {
    return '发给 $who 的付款已完成，正在等待确认。';
  }

  @override
  String get homeNoticeRepeated => '这笔付款已被接受。发送方再次收到了相同的回复；不会有第二笔付款。';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return '来自 $who 的付款已被接受。对方再次收到了相同的回复；不会有第二笔付款。';
  }

  @override
  String get homeNoticeDelayed => '无法连接节点。连接恢复后，付款将自动完成。';

  @override
  String get homeNoticeRelayProblem => 'epicbox 服务器报告了问题，正在重试。';

  @override
  String get homeNoticePaymentFailed => '有一笔付款未能完成。';

  @override
  String get homeBackupCardText => '请备份你的助记词。';

  @override
  String get homeBackupCardButton => '备份';

  @override
  String get homeBackupCardDismiss => '不再显示';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 笔付款不在历史备份中。用助记词恢复钱包只能找回余额。',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '自上次历史备份以来，有 $count 笔付款为新增或有变动。用助记词恢复钱包只能找回余额。',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => '以后再说';

  @override
  String get homeHistoryExportButton => '导出历史备份';

  @override
  String get homeBalanceSpendable => '可用余额';

  @override
  String get balanceHelpLabel => '这些余额的含义';

  @override
  String get balanceTotal => '总额';

  @override
  String balanceHelpRow(String label, String amount) {
    return '$label：$amount';
  }

  @override
  String get balanceTotalHelp => '此钱包中的全部金额，无论能否使用。';

  @override
  String get homeBalanceHiddenLabel => '余额已隐藏';

  @override
  String get homeShowBalances => '显示余额';

  @override
  String get homeHideBalances => '隐藏余额';

  @override
  String get homeBalanceConfirming => '确认中';

  @override
  String get balanceConfirmingHelp => '已上链，等待足够的确认。';

  @override
  String get homeBalanceNotOnChain => '尚未上链';

  @override
  String get balanceNotOnChainHelp =>
      '发给你但发送方尚未完成、或尚未进入区块的付款，以及你发送时的找零。进入区块后才计入：仅被提出的付款可能永远不会到账。';

  @override
  String get homeBalanceLocked => '被进行中的付款锁定';

  @override
  String get balanceLockedHelp => '为你发起的付款保留；完成后找零会返回。';

  @override
  String get homeBalanceImmature => '暂不可用的挖矿奖励';

  @override
  String get balanceImmatureHelp => '挖矿奖励需等待一定数量的区块后才能使用。';

  @override
  String get balanceLineAllConfirmed => '全部已确认';

  @override
  String get balanceLineNothingYet => '暂无内容';

  @override
  String get homeSyncSyncing => '正在同步…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return '正在同步 $percent%…';
  }

  @override
  String get homeSyncNodeUnreachable => '无法连接节点，余额可能不是最新的。';

  @override
  String get homeSyncNotValidated => '尚未经节点验证，余额可能不是最新的。';

  @override
  String get homeSyncUpToDate => '已是最新。';

  @override
  String get homeSyncContactingNode => '正在连接节点…';

  @override
  String get statusNodeOnline => '节点在线';

  @override
  String get statusNodeSyncing => '节点同步中';

  @override
  String statusNodeSyncingPercent(int percent) {
    return '节点同步中 $percent%';
  }

  @override
  String get statusNodeConnecting => '正在连接节点';

  @override
  String get statusNodeOffline => '节点离线';

  @override
  String get statusEpicboxOnline => 'epicbox 在线';

  @override
  String get statusEpicboxConnecting => '正在连接 epicbox';

  @override
  String get statusEpicboxOffline => 'epicbox 离线';

  @override
  String statusNodeTestNetwork(String network) {
    return '$network，测试币';
  }

  @override
  String statusNodeHost(Object host) {
    return '节点：$host';
  }

  @override
  String statusNodeVersion(Object version) {
    return '节点版本 $version';
  }

  @override
  String statusRelay(Object relay) {
    return '服务器：$relay';
  }

  @override
  String get homeEpicboxOffline => 'epicbox 已离线，正在重新连接。';

  @override
  String get homeEpicboxConnecting => '正在连接 epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return '已同步至区块 $height';
  }

  @override
  String homePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款正在等待接收方',
    );
    return '$_temp0';
  }

  @override
  String homePendingBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount 正在等待接收方钱包回复。在此之前，这些资金将保持锁定。如果一直没有回复，请打开相应的付款并点击“取消付款”。',
    );
    return '$_temp0';
  }

  @override
  String get homePendingWhy => '为什么要等待？';

  @override
  String homePendingView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '查看付款',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPayments => '暂无付款。';

  @override
  String get invoicesTitle => '账单';

  @override
  String invoicesEntryTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '账单，$count 张待处理',
      zero: '账单',
    );
    return '$_temp0';
  }

  @override
  String get invoicesChecking => '正在检查账单';

  @override
  String get invoicesEmpty => '没有待处理的账单。您信任的服务向您发送账单后，账单会显示在这里。未经您批准，不会支付任何款项。';

  @override
  String get invoicesUnnamedService => '未命名的服务';

  @override
  String invoiceTimeLeftHours(int hours, int minutes) {
    return '剩余 $hours 小时 $minutes 分钟';
  }

  @override
  String invoiceTimeLeftMinutes(int minutes) {
    return '剩余 $minutes 分钟';
  }

  @override
  String get invoiceTimeLeftUnderMinute => '剩余不到一分钟';

  @override
  String get invoiceExpired => '此账单已过期，未支付任何款项。';

  @override
  String get invoiceGone => '此账单已不再有效，未支付任何款项。';

  @override
  String get invoiceReviewTitle => '查看账单';

  @override
  String invoiceReviewAsks(String service) {
    return '$service 请您付款';
  }

  @override
  String get invoiceReviewMessageLabel => '服务的留言';

  @override
  String get invoiceReviewNote => '钱包会加上网络手续费。在您批准之前不会支付任何款项。';

  @override
  String get invoiceApprove => '批准并付款';

  @override
  String get invoiceDecline => '拒绝';

  @override
  String get invoicePinReason => '输入 PIN 码以支付此账单。';

  @override
  String get invoiceDeclineTitle => '拒绝此账单？';

  @override
  String invoiceDeclineBody(String service) {
    return '$service 会收到您拒绝的通知。不会支付任何款项。';
  }

  @override
  String get invoiceDeclineKeep => '保留';

  @override
  String get invoiceDeclinedNotice => '已拒绝账单。';

  @override
  String invoicePaidNotice(String service) {
    return '已付款。$service 正在完成这笔付款。';
  }

  @override
  String invoiceReplyFailedTitle(String service) {
    return '您的付款尚未送达 $service';
  }

  @override
  String get invoiceReplyFailedBody => '付款已签名并保存在此设备上。点“重试”会再次发送，无需再次批准。';

  @override
  String get invoiceReplyFailedNotice => '付款未能送达服务。请点“重试”再次发送。';

  @override
  String get invoiceRetry => '重试';

  @override
  String get invoiceDetailsSection => '账单';

  @override
  String get invoiceDetailsService => '开单方';

  @override
  String invoiceDetailsReplied(String service) {
    return '正在等待 $service 发布这笔付款。';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service 报告已发布这笔付款。网络确认后即完成。';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service 尚未收到您的付款。点“重试”会再次发送，无需再次批准。';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '您付款后，$service 撤回了此账单。如果这笔付款未能确认，请取消它以解锁资金。';
  }

  @override
  String get invoiceNoticeReceived => '有一张账单等待您批准。';

  @override
  String get invoiceNoticePosted => '某个服务报告已发布您的付款。';

  @override
  String get invoiceNoticeWithdrawnPaid => '某个服务撤回了一张您已支付的账单。';

  @override
  String get invoiceNoticeWithdrawn => '某个服务在您答复前撤回了一张账单。';

  @override
  String get invoiceNoticeExpired => '一张账单在您答复前已过期。';

  @override
  String get receiveRequestTitle => '请求付款';

  @override
  String get requestTitle => '请求付款';

  @override
  String get requestStepsIntro => '对方的钱包必须能接收账单。请求之前：';

  @override
  String get requestStepTrust => '1. 对方把下面你的地址添加到其信任的服务中。';

  @override
  String get requestStepAddress => '2. 对方把其账单地址给你。';

  @override
  String get requestYourAddress => '你的地址';

  @override
  String get requestPayerLabel => '对方的账单地址';

  @override
  String get requestPayerMissing => '粘贴或扫描对方的账单地址。';

  @override
  String get requestPayerOwn => '这是你自己的地址之一。请输入付款人给你的账单地址。';

  @override
  String get requestMessageLabel => '给付款人的留言（可选）';

  @override
  String get requestMessageHelper => '付款人会随请求看到这条留言。';

  @override
  String get requestButton => '请求';

  @override
  String requestSentNotice(String payer) {
    return '已向 $payer 发送请求。';
  }

  @override
  String get invoicesToPaySection => '待支付';

  @override
  String get invoicesNoneToPay => '没有待支付的账单。';

  @override
  String get invoicesSentSection => '你发出的请求';

  @override
  String get issuedPaid => '已支付';

  @override
  String get issuedDeclined => '已拒绝';

  @override
  String get issuedWithdrawn => '已撤回';

  @override
  String get issuedExpired => '已过期';

  @override
  String get issuedWithdraw => '撤回';

  @override
  String get issuedWithdrawTitle => '撤回这个请求？';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer 将无法再支付它。此操作无法撤销。';
  }

  @override
  String get issuedWithdrawKeep => '保留';

  @override
  String get issuedDetailsSection => '付款请求';

  @override
  String get issuedDetailsPayer => '请求对象';

  @override
  String get issuedDetailsWaiting => '正在等待付款人。付款到达后，你的钱包会完成它。';

  @override
  String get issuedDetailsPaid => '已支付。你的钱包已完成这笔付款；网络确认后即完成。';

  @override
  String get issuedDetailsDeclined => '付款人拒绝了这个请求，因此已撤回。没有支付任何款项。';

  @override
  String get issuedDetailsWithdrawn => '你撤回了这个请求。没有支付任何款项。';

  @override
  String get issuedDetailsExpired => '这个请求在支付前已过期。没有支付任何款项。';

  @override
  String get issuerNoticePaid => '你发出的一个请求已支付。';

  @override
  String get issuerNoticeDeclined => '你发出的一个请求被拒绝了。';

  @override
  String get issuerNoticeWithdrawn => '请求已撤回，无法再支付。';

  @override
  String get issuerNoticeExpired => '你发出的一个请求未支付就过期了。';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return '$payer 的钱包无法支付请求，已将你的请求退回，因此已撤回。请让对方改为直接向你的地址付款，或使用付款文件。';
  }

  @override
  String get issuedBounced => '已退回';

  @override
  String get issuedDetailsBounced =>
      '付款人的钱包无法支付请求，已将这个请求退回，因此已撤回。没有支付任何款项。请让对方改为直接向你的地址付款，或使用付款文件。';

  @override
  String get requestPayerNoInvoices =>
      '这个钱包之前退回过请求：它无法支付请求。请让对方改为直接向你的地址付款，或使用付款文件。';

  @override
  String get txStatusWaitingPayer => '等待付款人';

  @override
  String get txStepRequested => '已请求';

  @override
  String get txStepPaid => '已支付';

  @override
  String get txDetailsWaitingPayer => '你请求了这笔付款。目前还没有到账：付款人支付请求后款项才会到达。';

  @override
  String get txDetailsRequestEnded => '这个请求未付款即已结束。没有任何款项到账。';

  @override
  String get txDetailsRequestedFrom => '请求对象';

  @override
  String get txPaymentRequest => '已请求的付款';

  @override
  String txSpokenRequesting(String amount) {
    return '正在请求 $amount';
  }

  @override
  String txSpokenRequestingFrom(String amount, String who) {
    return '正在向 $who 请求 $amount';
  }

  @override
  String get receiveEpicboxConnected => 'epicbox 已连接';

  @override
  String get receiveQrLabel => '你的地址二维码';

  @override
  String get receiveAddressLabel => 'Epicbox 地址';

  @override
  String get receiveEpicboxOfflineBody => '发给你的付款现在会在 epicbox 等待，钱包重新连接后到账。';

  @override
  String get receiveShareCardHeadline => '用 Epic Cash 付款给我';

  @override
  String get receiveHelpButton => '收款说明';

  @override
  String get receiveAddressCopied => '地址已复制';

  @override
  String get receiveFileTitle => '通过付款文件收款';

  @override
  String get receiveFileBody => '收到了付款文件？打开它，或复制其中的文本粘贴到这里。';

  @override
  String get receiveFileOpen => '打开文件';

  @override
  String get receivePasteEmpty => '请先复制付款文本，再点按粘贴。';

  @override
  String get updateChecking => '正在检查更新…';

  @override
  String get updateUpToDate => '已是最新版本。';

  @override
  String get updateNoInformation => '没有可用的更新信息。';

  @override
  String updateAvailable(String version) {
    return '版本 $version 已可用。';
  }

  @override
  String updateDownloading(String version, int percent) {
    return '正在下载版本 $version… $percent%';
  }

  @override
  String updateInstalling(String version) {
    return '正在安装版本 $version…';
  }

  @override
  String get updateFailed => '更新失败。';

  @override
  String get updateInstallButton => '更新';

  @override
  String get updateTryAgain => '重试';

  @override
  String get updateDownloadProgressLabel => '下载进度';

  @override
  String get updateNeedsPermission => '请在打开的页面中允许此应用安装更新，然后再次点击“更新”。';

  @override
  String updateNotInstalled(String detail) {
    return '更新未安装：$detail';
  }

  @override
  String updateCannotInstall(String detail) {
    return '无法安装更新：$detail。';
  }

  @override
  String get updateCannotInstallUnknown => '无法安装更新：未知错误。';

  @override
  String get updateNeedsReinstall =>
      '此更新使用新的密钥签名，无法覆盖安装当前版本。需要重新安装，而卸载会从设备上删除此钱包：请先抄下你的助记词，然后卸载此应用并安装新版本。';

  @override
  String get updateManifestNotJson => '更新信息不是有效的 JSON。';

  @override
  String get updateManifestWrongShape => '更新信息格式不正确。';

  @override
  String get updateManifestOtherApp => '更新信息属于其他应用。';

  @override
  String get updateManifestNoApks => '更新信息中没有列出 APK。';

  @override
  String updateDownloadHttpFailed(int status) {
    return '下载失败（HTTP $status）。';
  }

  @override
  String get updateDownloadTooLarge => '下载内容超过了声明的大小。';

  @override
  String get updateDownloadIncomplete => '下载不完整。';

  @override
  String get updateDownloadDamaged => '下载的文件已损坏（校验和不匹配）。';

  @override
  String get updateDownloadInterrupted => '下载已中断。';

  @override
  String get updateServerUnreachable => '无法连接更新服务器。';

  @override
  String updateServerHttpStatus(int status) {
    return '更新服务器返回 HTTP $status。';
  }

  @override
  String get updateServerTimeout => '更新服务器响应超时。';

  @override
  String get updateConnectionFailed => '连接更新服务器失败。';

  @override
  String get updateCheckFailed => '检查更新失败。';

  @override
  String get setupTitle => '节点与 Epicbox';

  @override
  String get setupNetworkSettingsTooltip => '节点与 Epicbox';

  @override
  String get setupNetworkHeading => '网络';

  @override
  String get setupNodeUrlLabel => '节点地址';

  @override
  String get setupNodeUrlInvalid => '请输入完整的地址，例如 https://node.example.com';

  @override
  String get setupTestConnection => '测试连接';

  @override
  String setupTestConnected(String height, String version) {
    return '已连接。节点当前区块高度为 $height，运行版本 $version。';
  }

  @override
  String setupTestFailed(String error) {
    return '无法连接。$error';
  }

  @override
  String get setupConnectedIconLabel => '已连接';

  @override
  String get setupRelayHeading => 'epicbox 服务器';

  @override
  String get setupRelayHint => '你的地址包含此服务器。';

  @override
  String get setupCustomRelayLabel => '其他 epicbox 服务器（主机名或 host:port）';

  @override
  String get setupCustomRelayUse => '使用此服务器';

  @override
  String get setupCustomRelayInvalid => '请输入主机名，例如 epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      '更换 epicbox 服务器会改变你的地址。请把新地址告诉发送方。发送到旧地址的付款会留在旧服务器上，直到你切换回去。';

  @override
  String get setupWalletPerNetwork => '每个网络都有各自的钱包。尚无钱包的网络会创建一个新钱包。';

  @override
  String get setupRelayHealthyIconLabel => '正常';

  @override
  String get setupRelayDownIconLabel => '不可用';

  @override
  String get setupRelayHealthUnavailable => '无法从 status.btlabs.uk 获取服务器状态。';

  @override
  String get setupRelayHealthSource => '状态来自 status.btlabs.uk，由其服务器测得。';

  @override
  String get setupRelayNotMonitored => '未监控';

  @override
  String get setupRelayUp => '正常';

  @override
  String get setupRelayDown => '不可用';

  @override
  String get setupRelayOfficial => '官方';

  @override
  String setupRelayUptime(String percent) {
    return '近一天在线率 $percent%';
  }

  @override
  String get restoreTitle => '恢复钱包';

  @override
  String get restorePhraseLabel => '助记词';

  @override
  String get restorePhraseHelper => '全部单词（12 至 24 个），以空格分隔。';

  @override
  String get restoreStartHeading => '从何处开始扫描';

  @override
  String get restoreStartByDate => '日期';

  @override
  String get restoreStartByHeight => '区块高度';

  @override
  String get restoreStartHeightLabel => '起始高度（可选）';

  @override
  String get restoreStartHeightHelper => '从此区块开始扫描。留空则扫描整条链。';

  @override
  String get restoreStartHeightInvalid => '起始高度必须是整数。';

  @override
  String get restoreBackToPhrase => '返回助记词';

  @override
  String get restoreDatePickerTitle => '你是什么时候创建这个钱包的？';

  @override
  String get restorePickDate => '选择你创建钱包的日期';

  @override
  String restoreFromDate(String date) {
    return '自 $date 起';
  }

  @override
  String get restoreDateHint =>
      '可选。如果不确定，请选择更早的日期。所选日期若晚于你的第一笔付款，就会漏掉资金。不选日期则扫描整条链，耗时更长。';

  @override
  String restoreDateStart(String height) {
    return '扫描将从此日期前两天开始，起始区块为 $height。';
  }

  @override
  String get restoreWholeChain => '改为扫描整条链';

  @override
  String get restoreScanIntro => '正在区块链上查找你的资金。完成前请保持应用打开。';

  @override
  String get restoreOpenWallet => '打开钱包';

  @override
  String get restoreRescanLater => '你之后可以在“设置”中进行完整的重新扫描。';

  @override
  String get restoreDoneIconLabel => '完成';

  @override
  String get restoreDoneTitle => '钱包已恢复';

  @override
  String get restoreImportExplanation =>
      '区块链上保存着你的余额，但不包含付款对象、手续费和备注。如果你曾从这个钱包导出历史备份，现在导入即可找回这些信息。它就是你分享或保存到旧手机以外的 .wfeh 文件。';

  @override
  String get restoreImportButton => '导入历史备份';

  @override
  String get restoreImportNotNow => '以后再说';

  @override
  String get restoreImportLater => '你之后可以在“设置”中导入。';

  @override
  String get restoreScanProgressLabel => '扫描进度';

  @override
  String get firstRunTitle => '欢迎';

  @override
  String get firstRunRestore => '我已有钱包：恢复钱包';

  @override
  String get firstRunSecuring => '正在保护你的钱包…';

  @override
  String get firstRunTryAgain => '重试';

  @override
  String get firstRunBiometricsNotSetUp => '未能设置生物识别解锁。你可以在“设置”中开启。';

  @override
  String get backupTitle => '助记词';

  @override
  String get backupPinReason => '请输入 PIN 码以显示助记词。';

  @override
  String get backupCopyWarning =>
      '助记词的截图或照片就是你钱包的完整副本：任何看到它的人都能转走你的资金，相册应用还可能把它上传到云端。抄在纸上最安全。';

  @override
  String get backupCopyAgree => '我会妥善保管助记词的任何副本，不泄露给他人';

  @override
  String get backupShowPhrase => '显示助记词';

  @override
  String get backupWarningIconLabel => '警告';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请将这 $count 个单词按顺序抄写在纸上，并妥善保管，切勿泄露。它们是恢复此钱包的唯一方式。',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return '第 $number 个单词：$word';
  }

  @override
  String get unlockTitle => '解锁钱包';

  @override
  String get pinLabel => 'PIN 码';

  @override
  String get pinRepeatLabel => '确认 PIN 码';

  @override
  String pinChooseTitle(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: '设置 $digits 位 PIN 码',
    );
    return '$_temp0';
  }

  @override
  String get pinConfirmTitle => '请再次输入 PIN 码';

  @override
  String get pinChooseDifferent => '重新设置 PIN 码';

  @override
  String get pinMismatch => '两次输入的 PIN 码不一致，请重新设置。';

  @override
  String get pinBiometricsIconLabel => '生物识别';

  @override
  String get pinBiometricsQuestion => '使用指纹或面容解锁？';

  @override
  String get pinBiometricsPinStillWorks => '你仍可随时使用 PIN 码。';

  @override
  String get pinBiometricsEnable => '使用生物识别';

  @override
  String get pinBiometricsNotNow => '以后再说';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN 码错误。还可尝试 $count 次，之后将暂停输入。',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN 码错误。下一次尝试将在 $count 秒后验证。',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN 码错误。下一次尝试将在 $count 分钟后验证。',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将在 $count 秒后验证 PIN 码…',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将在 $count 分钟后验证 PIN 码…',
    );
    return '$_temp0';
  }

  @override
  String get pinChecking => '正在验证 PIN 码…';

  @override
  String get pinPromptTitle => '请输入 PIN 码';

  @override
  String get pinUseBiometrics => '使用生物识别';

  @override
  String get pinForgot => '忘记 PIN 码？';

  @override
  String get pinResetTitle => '忘记 PIN 码';

  @override
  String get pinResetBody =>
      'PIN 码无法找回。你可以从设备中删除此钱包，再用助记词恢复。如果没有助记词，其中的资金将永久丢失。';

  @override
  String get pinResetConfirm => '我已备好助记词';

  @override
  String get pinResetKeep => '保留钱包';

  @override
  String get pinResetDelete => '删除钱包';

  @override
  String get launchTryAgain => '重试';

  @override
  String get unlockStranded =>
      '无法正常读取此钱包。没有删除任何内容。请重启设备后重试。如果问题仍然存在，可以通过“忘记 PIN 码？”移除钱包，再用恢复短语恢复。';

  @override
  String get sendAmountNegative => '金额不能为负数。';

  @override
  String sendAmountAmbiguous(String asWhole, String asDecimal) {
    return '请写成 $asWhole 或 $asDecimal，以免金额产生歧义。';
  }

  @override
  String get sendAmountUnclear => '请输入不带分隔符的金额，例如 1234.5，以免金额产生歧义。';

  @override
  String get sendAmountNoPrice => '暂无价格，请改用 EPIC 输入。';

  @override
  String get sendAmountEnterFiatExample => '请输入金额，例如 10.50';

  @override
  String get sendAmountTooLarge => '这超过了 EPIC 的总供应量。请检查金额。';

  @override
  String get sendAmountZero => '请输入大于零的金额。';

  @override
  String get sendUrlUnsupported => '不支持向钱包 URL 付款。请向接收方索取其 epicbox 地址。';

  @override
  String get scanQrTooltip => '扫描二维码';

  @override
  String get sendScanButton => '扫码';

  @override
  String get sendChooseContactTooltip => '选择联系人';

  @override
  String get sendContactsButton => '联系人';

  @override
  String get sendMethodEpicbox => 'Epicbox 地址';

  @override
  String get sendMethodFile => '付款文件';

  @override
  String get sendFileHelpTooltip => '文件付款如何使用';

  @override
  String sendAmountLabel(String unit) {
    return '金额（$unit）';
  }

  @override
  String sendUseUnit(String unit) {
    return '改用 $unit';
  }

  @override
  String get sendMax => '最大';

  @override
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String get sendCopyPasteInstead => '改为复制粘贴';

  @override
  String get sendSlateBoxTitle => '交易文本';

  @override
  String get sendPasteResponseLabel => '粘贴接收方的回复';

  @override
  String get sendPasteResponseMissing => '请粘贴接收方发回的回复文本。';

  @override
  String get slateFinishPayment => '完成付款';

  @override
  String sendResultAutoCancel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '如果 $days 天后仍未完成，付款将自动取消，金额随之解锁。如需提前终止，请打开该付款并点击“取消付款”。',
    );
    return '$_temp0';
  }

  @override
  String sendResultFeeChanged(String charged, String reviewed) {
    return '实际收取的手续费为 $charged，而不是之前显示的 $reviewed，因为钱包在发送时重新选择了要使用的币。';
  }

  @override
  String get sendResultNoteNotSaved => '备注未能保存。你可以打开该付款重新添加。';

  @override
  String get sendHelp => '帮助';

  @override
  String get sendReviewTotal => '总计';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount（≈ $fiat）';
  }

  @override
  String sendReviewSendButton(String amount) {
    return '发送 $amount';
  }

  @override
  String get sendReviewEdit => '修改';

  @override
  String get slateFileTitle => '交易文件';

  @override
  String get slateWrongPayment => '此回复属于另一笔付款。请打开接收方针对这笔付款返回的文件。';

  @override
  String get slateInvoiceUnsupported => '暂不支持收款请求（发票）。';

  @override
  String get slateNotTransactionFile => '该文件不是交易文件。';

  @override
  String get slateReading => '正在读取文件';

  @override
  String get slateFileTooLarge => '该文件过大，不可能是交易文件。';

  @override
  String slatePostedHeadline(String amount) {
    return '$amount 的付款已发送到网络。';
  }

  @override
  String slatePostedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '获得 $count 个确认后将显示为“已完成”。',
    );
    return '$_temp0';
  }

  @override
  String slateAcceptedHeadline(String file) {
    return '已接受。请将 $file 发回给发送方。';
  }

  @override
  String slateAcceptedBody(String amount) {
    return '发送方完成付款并上链后，这笔 $amount 即会到账。';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return '已接受过。请再次将 $file 发回给发送方。';
  }

  @override
  String slateRepeatedBody(String amount) {
    return '您之前已接受这笔付款，因此这是相同的回复，而不是第二笔付款。发送方完成付款并上链后，这笔 $amount 即会到账。';
  }

  @override
  String slateIncomingSend(String amount) {
    return '有人正在向你发送 $amount。';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return '接收方对你发送的 $amount（手续费 $fee）的回复。';
  }

  @override
  String get slateIncomingSendHint => '请接受付款，然后将回复文件发回给发送方。';

  @override
  String get slateIncomingResponseHint => '完成此步骤即可将付款发送到网络。';

  @override
  String get slateAcceptPayment => '接受付款';

  @override
  String slateHandOverFailed(String file) {
    return '未能保存或分享 $file，请重试。';
  }

  @override
  String get slateSaveToDevice => '保存到设备';

  @override
  String slateSaved(String file) {
    return '已保存 $file';
  }

  @override
  String get slateSaveDialogTitle => '保存交易文件';

  @override
  String get slateOpenDialogTitle => '打开交易文件';

  @override
  String get slateNotPostedTitle => '尚未进入网络';

  @override
  String get slateNotPostedBody => '付款已完成，但网络尚未接受。钱包会从这笔付款重新广播。请勿再次发送。';

  @override
  String get slateOpenPayment => '查看付款';

  @override
  String get scanQrTitle => '扫描二维码';

  @override
  String get scanQrHint => '将摄像头对准接收方的二维码。';

  @override
  String get scanQrCameraDenied =>
      '钱包无权使用摄像头。如需扫码，请在手机设置中允许此应用访问摄像头。你也可以直接粘贴地址。';

  @override
  String get scanQrCameraFailed => '无法启动摄像头。请改为粘贴地址，或重试。';

  @override
  String get scanQrTryAgain => '重试';

  @override
  String get scanQrBack => '返回';

  @override
  String get contactsTitle => '联系人';

  @override
  String get contactsPickTitle => '选择联系人';

  @override
  String get contactsAdd => '添加联系人';

  @override
  String get contactsEmpty => '暂无联系人。添加你经常付款的对象，就不必每次都粘贴地址了。';

  @override
  String get contactsSearchLabel => '搜索联系人';

  @override
  String get contactsNoMatch => '没有匹配的联系人。';

  @override
  String get contactsNameMissing => '请输入名称。';

  @override
  String contactsDeleteTitle(String name) {
    return '删除 $name？';
  }

  @override
  String get contactsDeleteBody => '该地址将从联系人中移除。过去的付款不受影响。';

  @override
  String get contactsKeep => '保留';

  @override
  String get contactsEditTitle => '编辑联系人';

  @override
  String get contactsNewTitle => '新建联系人';

  @override
  String get contactsDeleteTooltip => '删除联系人';

  @override
  String get contactsNameLabel => '名称';

  @override
  String get contactsAddressLabel => '地址';

  @override
  String contactsDuplicate(String name) {
    return '此地址已保存为 $name。';
  }

  @override
  String get contactsNoteLabel => '备注（可选）';

  @override
  String get contactsSave => '保存联系人';

  @override
  String get contactsAddressMissing => '请输入地址。';

  @override
  String contactsUrlIncomplete(String example) {
    return '请输入完整的钱包 URL，例如 $example';
  }

  @override
  String contactsAddressInvalid(String example) {
    return '这不是有效的地址。地址格式类似 $example';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionNetwork => '服务器';

  @override
  String get settingsNetworkAndNode => '节点与 Epicbox';

  @override
  String settingsNetworkSubtitle(String network, String node) {
    return '$network · $node';
  }

  @override
  String get settingsSectionDisplay => '显示';

  @override
  String get settingsCurrency => '计价货币';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name（$code）';
  }

  @override
  String get settingsShowPrices => '显示价格';

  @override
  String get settingsHideBalances => '隐藏余额';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPricesOnNotice => '价格来自 CoinGecko，它能看到你的 IP 地址。';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsPushBlocked => '通知已在系统设置中被屏蔽';

  @override
  String get settingsPushUnavailable => '此版本不支持通知';

  @override
  String get settingsSectionSecurity => '安全';

  @override
  String get settingsChangePin => '修改 PIN 码';

  @override
  String get settingsBiometrics => '生物识别解锁';

  @override
  String get settingsBiometricsOn => '已开启生物识别解锁';

  @override
  String get settingsBiometricsOff => '已关闭生物识别解锁';

  @override
  String get settingsBiometricsFailed => '未能设置生物识别解锁';

  @override
  String get settingsBiometricsPinReason => '请输入 PIN 码以开启生物识别解锁。';

  @override
  String get settingsAutoLock => '自动锁定';

  @override
  String get settingsBackupPhrase => '备份助记词';

  @override
  String get settingsPhraseConfirmed => '助记词已确认';

  @override
  String get settingsLockWallet => '锁定钱包';

  @override
  String get settingsSectionHistory => '交易记录';

  @override
  String get settingsExportHistory => '导出历史备份';

  @override
  String get settingsExportCsv => '导出 CSV';

  @override
  String get settingsImportHistory => '导入历史备份';

  @override
  String get settingsSectionWallet => '钱包';

  @override
  String get settingsContacts => '联系人';

  @override
  String get settingsSectionInvoices => '账单';

  @override
  String get settingsInvoices => '账单地址和受信任的服务';

  @override
  String get settingsInvoicesSubtitle => '允许您信任的服务向您发送账单。每张账单都需要您批准。';

  @override
  String get invoiceSettingsTitle => '账单';

  @override
  String get invoiceSettingsAddressTitle => '您的账单地址';

  @override
  String get invoiceSettingsAddressBody =>
      '将此地址提供给您信任的服务，以便它向您发送账单。您的收款地址保持不变。';

  @override
  String get invoiceSettingsQrLabel => '您的账单地址二维码';

  @override
  String get invoiceSettingsAddressCopied => '已复制账单地址。';

  @override
  String get invoiceSettingsServicesTitle => '受信任的服务';

  @override
  String get invoiceSettingsNoServices => '还没有受信任的服务。其他人的账单永远不会到达您这里。';

  @override
  String get invoiceSettingsAddService => '添加服务';

  @override
  String invoiceSettingsRemoveTooltip(String name) {
    return '移除 $name';
  }

  @override
  String invoiceSettingsRemoveTitle(String name) {
    return '移除 $name？';
  }

  @override
  String get invoiceSettingsRemoveBody => '此服务将无法再向您发送账单。已完成的付款不受影响。';

  @override
  String get invoiceSettingsKeep => '保留';

  @override
  String get invoiceSettingsRemoveConfirm => '移除';

  @override
  String invoiceSettingsRemoved(String name) {
    return '$name 无法再向您发送账单。';
  }

  @override
  String get invoiceSettingsRotate => '获取新的账单地址';

  @override
  String get invoiceSettingsRotateHint => '当前地址将停止使用。';

  @override
  String get invoiceSettingsRotateTitle => '获取新的账单地址？';

  @override
  String get invoiceSettingsRotateBody => '您当前的账单地址将永久停止使用。每个向您发送账单的服务都需要新地址。';

  @override
  String get invoiceSettingsRotateConfirm => '获取新地址';

  @override
  String get invoiceSettingsRotated => '新的账单地址已就绪。请把它提供给您的服务。';

  @override
  String invoiceSettingsDropped(int count) {
    return '本次会话丢弃（未知发件人）：$count';
  }

  @override
  String get invoiceSettingsAddTitle => '添加受信任的服务';

  @override
  String get invoiceSettingsAddExplanation =>
      '受信任的服务可以向您的账单地址发送账单；其他人的消息会被丢弃。在您用 PIN 或指纹批准每张账单之前，不会支付任何款项。';

  @override
  String get invoiceSettingsLabelLabel => '名称';

  @override
  String get invoiceSettingsLabelMissing => '请为服务命名。';

  @override
  String get invoiceSettingsServiceAddressLabel => '服务的 epicbox 地址';

  @override
  String get invoiceSettingsAddressMissing => '粘贴或扫描服务显示的地址。';

  @override
  String get invoiceSettingsAddButton => '添加服务';

  @override
  String invoiceSettingsAdded(String name) {
    return '$name 现在可以向您发送账单了。';
  }

  @override
  String get settingsRescan => '重新扫描区块链';

  @override
  String get settingsRescanFinished => '重新扫描已完成';

  @override
  String get settingsRescanTitle => '重新扫描区块链';

  @override
  String get settingsRescanBody =>
      '钱包将重新查找它的资金。起点越早，找到的越全，但耗时越长；扫描整条链可能需要很长时间。';

  @override
  String get settingsRescanFromDate => '从某个日期开始';

  @override
  String get settingsRescanFromHeight => '从某个区块高度开始';

  @override
  String get settingsRescanWholeChain => '整条链';

  @override
  String get settingsRescanPickDate => '选择日期';

  @override
  String get settingsRescanPickDateFirst => '请先选择日期。';

  @override
  String get settingsRescanStartHeight => '起始高度';

  @override
  String get settingsRescanHeightInvalid => '请输入不小于 1 的区块高度。';

  @override
  String get settingsRescanButton => '重新扫描';

  @override
  String get settingsDeleteWallet => '删除此钱包';

  @override
  String get settingsDeleteDuringScan => '请等待扫描完成后再删除钱包。';

  @override
  String get settingsDeletePinReason => '请输入 PIN 码以删除此钱包。';

  @override
  String get settingsDeleteWarningIcon => '警告';

  @override
  String get settingsDeleteTitle => '删除此钱包？';

  @override
  String get settingsDeleteBody =>
      '这将从此设备中删除钱包、交易记录和 PIN 码。只有助记词能找回资金。没有助记词，资金将永久丢失。';

  @override
  String get settingsDeleteHavePhrase => '我已抄写好助记词';

  @override
  String get settingsDeleteConfirmWord => '删除';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return '输入“$word”以确认';
  }

  @override
  String get settingsDeleteKeep => '保留钱包';

  @override
  String get settingsDeleteConfirm => '删除钱包';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsAboutNetwork => '网络';

  @override
  String get settingsEpicboxServer => 'epicbox 服务器';

  @override
  String settingsUpdateTo(String version) {
    return '更新到 $version';
  }

  @override
  String get settingsUpdateInstall => '安装';

  @override
  String get settingsCheckUpdates => '检查更新';

  @override
  String get settingsHelp => '帮助';

  @override
  String get settingsSendFeedback => '发送反馈';

  @override
  String get settingsSendFeedbackHint => '报告问题或提出建议';

  @override
  String get settingsSourceCode => '源代码';

  @override
  String get settingsLicences => '许可证';

  @override
  String get licencesLead => '本钱包包含的开源软件。每个组件保留各自的许可证；完整文本一键可达。';

  @override
  String get licencesApp =>
      'Epic Cash Mobile，由 BT Labs 开发：Apache-2.0。代码在 GitHub 上。';

  @override
  String get licencesFlutter => 'Flutter 及其 Dart 软件包：BSD 3-Clause 及类似的宽松许可证。';

  @override
  String get licencesLepic =>
      'LEPIC，Epic Cash 钱包库：Apache 2.0，包含 Epic Cash 的 secp256k1-zkp 分支（CC0）以及 MIT 或 Apache 2.0 许可的 Rust crate，其中有 tokio、rustls、rusqlite 和 blake2。';

  @override
  String get licencesTor => 'Tor：GNU 通用公共许可证第 3 版。其源代码见下文。';

  @override
  String get licencesFonts => '字体 Montserrat 和 JetBrains Mono：SIL 开放字体许可证 1.1。';

  @override
  String get licencesFull => '全部许可证文本';

  @override
  String get settingsCopyLink => '复制链接';

  @override
  String get settingsLinkCopied => '链接已复制';

  @override
  String get settingsPinTitle => '修改 PIN 码';

  @override
  String get settingsPinEnterCurrent => '请输入当前 PIN 码';

  @override
  String get settingsPinCurrentLabel => '当前 PIN 码';

  @override
  String settingsPinChooseNew(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: '设置新的 $digits 位 PIN 码',
    );
    return '$_temp0';
  }

  @override
  String get settingsPinChanged => 'PIN 码已修改';

  @override
  String get settingsPinChangedBiometricsOff => 'PIN 码已修改。生物识别解锁已关闭，请在下方重新开启。';

  @override
  String get helpTitle => '帮助';

  @override
  String get helpStillStuck => '仍未解决？';

  @override
  String get helpTellUs => '描述发生了什么，或哪里不清楚。';

  @override
  String get helpSendFeedback => '发送反馈';

  @override
  String get feedbackTitle => '发送反馈';

  @override
  String get feedbackIntro => '描述哪里出了问题，或哪些地方可以改进。';

  @override
  String get feedbackMessageLabel => '反馈内容';

  @override
  String get feedbackMessageMissing => '请简单描述发生了什么。';

  @override
  String get feedbackEmailLabel => '用于回复的电子邮箱（可选）';

  @override
  String get feedbackEmailInvalid => '这看起来不是有效的电子邮箱地址。';

  @override
  String get feedbackAttachLogs => '附加诊断日志';

  @override
  String get feedbackAttachLogsHint => '日志有助于找到问题。助记词、PIN 码和其他机密信息会先被移除。';

  @override
  String get feedbackPreviewButton => '预览发送内容';

  @override
  String get feedbackSend => '发送';

  @override
  String get feedbackShareOrSaveInstead => '改为分享或保存';

  @override
  String get feedbackFileExplanation => '你的反馈将生成一个文本文件，你可以通过电子邮件或聊天应用发送，也可以保存。';

  @override
  String get feedbackShareOrSave => '分享或保存';

  @override
  String get feedbackShareHint => '通过电子邮件或聊天应用发送';

  @override
  String get feedbackSaveToDevice => '保存到设备';

  @override
  String get feedbackSaveDialogTitle => '保存反馈';

  @override
  String feedbackSavedFile(String name) {
    return '已保存 $name';
  }

  @override
  String get feedbackSent => '谢谢，你的反馈已发送。';

  @override
  String get feedbackThanks => '感谢你的反馈。';

  @override
  String feedbackServerAnswered(int status) {
    return '反馈服务器返回了 $status。';
  }

  @override
  String get feedbackServerNoAnswer => '反馈服务器没有响应。';

  @override
  String get feedbackServerUnreachable => '无法连接反馈服务器。';

  @override
  String get feedbackPreviewTitle => '发送内容';

  @override
  String get settingsAdvancedOptions => '高级选项';

  @override
  String get settingsAdvancedOptionsSubtitle => '技术细节、文件和日志';

  @override
  String get settingsSectionPrivacy => '隐私';

  @override
  String get settingsUseStatusSite => '使用 status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle => '网络状态和信息由 status.btlabs.uk 提供';

  @override
  String get txStepStarted => '付款已发起';

  @override
  String get txStepAccepted => '接收方已接受';

  @override
  String get txStepPosted => '已发送到网络';

  @override
  String get txStepConfirming => '确认中';

  @override
  String get txStepConfirmed => '已确认';

  @override
  String get txStepArrived => '付款已到达';

  @override
  String get txStepSenderFinished => '发送方已完成';

  @override
  String get fileHelpTitle => '付款文件如何使用';

  @override
  String get fileHelpYou => '你';

  @override
  String get fileHelpFriend => '朋友';

  @override
  String get fileHelpSendStep1 => '你创建一个付款文件。';

  @override
  String get fileHelpSendStep2 => '你用任何方式把它发给朋友，比如聊天或电子邮件。';

  @override
  String get fileHelpSendStep3 => '朋友在自己的钱包中打开它，并把签名后的回复发还给你。';

  @override
  String get fileHelpSendStep4 => '你打开回复，付款就在路上了。';

  @override
  String get fileHelpReceiveStep1 => '朋友为你创建一个付款文件。';

  @override
  String get fileHelpReceiveStep2 => '对方用任何方式把它发给你，比如聊天或电子邮件。';

  @override
  String get fileHelpReceiveStep3 => '你在钱包中打开它，并发回签名后的回复。';

  @override
  String get fileHelpReceiveStep4 => '朋友打开回复，付款就在发给你的路上了。';

  @override
  String fileHelpStepOf(int step, int count) {
    return '第 $step 步，共 $count 步';
  }

  @override
  String get fileHelpPause => '暂停动画';

  @override
  String get fileHelpPlay => '播放动画';

  @override
  String get demoPinFilled => '演示 PIN 已为你填好';

  @override
  String get demoPinSkip => '跳过';

  @override
  String get demoPinSetUpTitle => '正在设置你的演示钱包';

  @override
  String get demoPinUnlockTitle => '正在打开你的演示钱包';

  @override
  String get sendStepRecipient => '收款人';

  @override
  String get sendStepAmount => '金额';

  @override
  String get sendStepReview => '确认';

  @override
  String sendStepOf(int step, int total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get sendHowItWorks => '运作方式';

  @override
  String get sendAddressLabel => 'Epic 地址';

  @override
  String get sendAddressMissing => '请输入对方的地址。';

  @override
  String get sendAddressWebLink => '这是网页链接，不是 Epic 地址。';

  @override
  String get sendAddressIncomplete => '这个地址似乎不完整。';

  @override
  String get sendAddressNotEpic => '这不是 Epicbox 地址。';

  @override
  String get sendNewRecipient => '新收款人';

  @override
  String get sendSaveContact => '保存为联系人';

  @override
  String get sendRecent => '最近';

  @override
  String get sendUseFile => '没有地址？使用付款文件';

  @override
  String sendTo(String who) {
    return '付给 $who';
  }

  @override
  String sendAvailable(String amount) {
    return '可用 $amount';
  }

  @override
  String sendFeeQuiet(String fee) {
    return '网络手续费 $fee';
  }

  @override
  String get sendAddNote => '添加备注';

  @override
  String get sendNoteLabel => '备注';

  @override
  String get sendNoteHelper => '对方也能看到。';

  @override
  String get sendNetworkFee => '网络手续费';

  @override
  String get sendChecking => '正在检查…';

  @override
  String get sendReady => '可以发送';

  @override
  String get sendNodeDown => '目前无法连接网络。';

  @override
  String get sendRelayDown => '对方的中继没有响应。';

  @override
  String get sendListenerDown => '尚未连接。仍可发送。';

  @override
  String get sendPayWithFile => '改用文件付款';

  @override
  String get sendAnyway => '仍然发送';

  @override
  String sendTrackSentTo(String name) {
    return '已发送给 $name';
  }

  @override
  String get sendTrackSent => '已发送';

  @override
  String sendTrackWaitingFor(String name) {
    return '等待 $name 的钱包';
  }

  @override
  String get sendTrackWaiting => '等待对方的钱包';

  @override
  String sendTrackSignedBy(String name) {
    return '$name 的钱包已签名';
  }

  @override
  String get sendTrackSigned => '对方钱包已签名';

  @override
  String get sendTrackOnNetwork => '已发送到网络';

  @override
  String get sendTrackConfirmed => '已确认';

  @override
  String sendTrackOffline(String amount) {
    return '对方钱包打开后会完成付款。在此之前 $amount 处于冻结状态。';
  }

  @override
  String get sendTrackIfNot => '如果一直没有完成怎么办？';

  @override
  String get sendTrackCancelled => '这笔付款已取消。';

  @override
  String get sendNoCoins => '还没有可发送的币。';

  @override
  String get sendFileTitle => '用文件付款';

  @override
  String get sendMakeFile => '生成付款文件';

  @override
  String get sendFileMade => '文件已生成';

  @override
  String sendFileOnHold(String amount) {
    return '$amount 已冻结';
  }

  @override
  String get sendFileWaitingReply => '等待对方回复';

  @override
  String get sendFileShareHint => '把这个文件发给对方，然后打开对方的回复。';

  @override
  String get sendOpenReply => '打开回复';

  @override
  String get handshakePayment => '付款';

  @override
  String get handshakeRequest => '收款请求';

  @override
  String get handshakeYou => '你';

  @override
  String get handshakeThem => '对方';

  @override
  String get handshakeNetwork => '网络';

  @override
  String get handshakePay1 => '你的钱包把付款发到中继。你的币被冻结。';

  @override
  String get handshakePay2 => '中继把它转给对方。对方钱包加入自己的部分并签名。';

  @override
  String get handshakeFinish => '你的钱包完成它并发送到网络。';

  @override
  String get handshakeConfirm => '网络确认它。';

  @override
  String get handshakeReq1 => '你的钱包把收款请求发到中继。';

  @override
  String get handshakeReq2 => '中继把它转给对方。对方批准后，其钱包加入币并签名。';

  @override
  String get handshakeRelay => '中继';

  @override
  String get handshakeFile => '文件';

  @override
  String get handshakeBack => '对方钱包把它发回中继。';

  @override
  String get handshakeRelayBack => '中继把它转回你的钱包。';

  @override
  String get handshakeFile1 => '你的钱包保存一个付款文件。你自己把它发给对方。';

  @override
  String get handshakeFile2 => '对方打开它。对方钱包加入自己的部分、签名并保存回复。';

  @override
  String get handshakeFile3 => '对方把回复文件发回给你。';

  @override
  String get handshakeFile4 => '你在钱包中打开对方的回复。';

  @override
  String get handshakePrevious => '上一步';

  @override
  String get handshakeNext => '下一步';

  @override
  String sendRelayRefused(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '对方的中继没有接收。在你取消之前，这笔金额处于冻结状态，最长 $days 天。',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost => '对方的中继没有接收。再次发送前请先查看钱包。';

  @override
  String get sendCancelAndFile => '取消并改用文件付款';

  @override
  String get sendLeaveIt => '暂时保留';

  @override
  String get sendSending => '正在发送…';

  @override
  String trackStepDone(String step) {
    return '$step，已完成';
  }

  @override
  String trackStepNow(String step) {
    return '$step，进行中';
  }

  @override
  String trackStepLater(String step) {
    return '$step，稍后';
  }

  @override
  String balanceLineOnHold(String amount) {
    return '$amount 冻结中';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount 即将到账';
  }

  @override
  String get demoTestCoinsPill => '测试币';

  @override
  String get demoTestCoinsPillTip => 'Floonet，Epic 的测试网络。这些币没有价值。';

  @override
  String demoLeftHours(int hours) {
    return '剩 $hours 小时';
  }

  @override
  String demoLeftMinutes(int minutes) {
    return '剩 $minutes 分钟';
  }

  @override
  String get demoReceiveKeepOpen => '保持此标签页打开才能收款。';

  @override
  String get demoGuideTitle => '试一次付款';

  @override
  String get demoGuideSend => '发一些给别人';

  @override
  String get demoGuideSendHint => '付款给朋友的演示，或在另一个浏览器或无痕窗口中打开本页面。';

  @override
  String get demoGuideOpenSend => '前往发送';

  @override
  String get demoGuideAsking => '正在向测试水龙头申请，可能需要一分钟。';

  @override
  String get demoGuideDone => '都完成了。演示结束前可以随意看看。';

  @override
  String get demoGuideHide => '隐藏';

  @override
  String get demoGuideHideLabel => '隐藏演示步骤';

  @override
  String demoGuideStepDone(String step) {
    return '$step，已完成';
  }

  @override
  String demoGuideStepToDo(String step) {
    return '$step，尚未完成';
  }

  @override
  String get receiveTabEpicbox => 'Epicbox';

  @override
  String get receiveTabTor => 'Tor';

  @override
  String get receiveTabFile => '文件';

  @override
  String get receiveTorAddressLabel => 'Tor 地址';

  @override
  String get receiveTorQrLabel => '你的 Tor 地址二维码';

  @override
  String get torReceivingTitle => 'Tor 接收';

  @override
  String get torHonestLine => 'Tor 收款仅在应用打开或短暂处于后台时有效。';

  @override
  String get torStateOff => 'Tor 接收已关闭';

  @override
  String torStateStarting(int percent) {
    return '正在连接 Tor… $percent%';
  }

  @override
  String get torStatePublishing => '正在发布你的 Tor 地址…';

  @override
  String get torStateReady => 'Tor 接收已开启';

  @override
  String torStateNotReachable(String reason) {
    return '你的 Tor 地址暂时无法访问。$reason';
  }

  @override
  String get torFailureMissing => '此应用不包含 Tor。';

  @override
  String get torFailureStart => 'Tor 未能启动。';

  @override
  String get torFailureNetwork => '无法连接 Tor 网络。请检查网络。';

  @override
  String get torFailureClock => '手机时钟不准。Tor 需要正确的时间。';

  @override
  String get torFailureListener => '钱包无法打开自己的 Tor 地址。';

  @override
  String get torFailureStopped => 'Tor 已停止。';

  @override
  String get torFailurePublish => '无法发布 Tor 地址。';

  @override
  String get torFailureKeys => 'Tor 不接受钱包的地址密钥。';

  @override
  String get sendOnionIncomplete => '这不是完整的 Tor 地址。请从收款人处重新复制。';

  @override
  String get sendTorUnavailable => '此应用无法通过 Tor 发送，因此无法在这里向 Tor 地址付款。';

  @override
  String get sendOverTor => '通过 Tor';

  @override
  String get sendTorConnectsOnSend => '发送时会连接 Tor。';

  @override
  String get sendTorReady => '可以通过 Tor 发送';

  @override
  String get sendTorReaching => '正在通过 Tor 联系对方钱包… 可能需要一些时间，请保持应用打开。';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '未能通过 Tor 联系到对方钱包。在你取消之前，这笔金额处于冻结状态，最长 $days 天。',
    );
    return '$_temp0';
  }

  @override
  String sendTorNothingSent(String reason) {
    return '$reason未发送任何内容。';
  }

  @override
  String get sendTryAgain => '重试';

  @override
  String get sendCancelPayment => '取消付款';

  @override
  String get settingsSectionReceiving => '接收';

  @override
  String get homeAvailableToSpend => '可用余额';

  @override
  String get homeTileWaitingSender => '等待付款方';

  @override
  String get homeTileLocked => '发送中锁定';

  @override
  String get homeTileMaturing => '奖励成熟中';

  @override
  String get homeTileTotal => '总计';

  @override
  String homeViewAll(int count) {
    return '查看全部 $count';
  }

  @override
  String get homeDestActivity => '活动';

  @override
  String get homeDestOutputs => '输出';

  @override
  String get txStatusReceived => '已收到';

  @override
  String get txStatusSent => '已发送';

  @override
  String sendPinReason(String amount) {
    return '输入 PIN 以发送 $amount。';
  }

  @override
  String sendFilePinReason(String amount) {
    return '输入 PIN 以生成 $amount 的付款文件。';
  }

  @override
  String get outputsTitle => '输出';

  @override
  String get outputsSpendable => '可用';

  @override
  String get outputsConfirming => '确认中';

  @override
  String get outputsLockedTile => '发送中锁定';

  @override
  String get outputsImmature => '未成熟';

  @override
  String outputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出',
    );
    return '$_temp0';
  }

  @override
  String get outputsSplitButton => '拆分…';

  @override
  String get outputsConsolidateButton => '合并…';

  @override
  String get outputsSplitNeeds => '拆分需要至少 1 EPIC 可用。';

  @override
  String get outputsConsolidateNeeds => '合并需要至少 2 个可用输出。';

  @override
  String get outputsWaitLocked => '请等待进行中的发送确认（约 3 个区块）。';

  @override
  String get outputsStrategy => '发送策略';

  @override
  String get outputsSmallest => '最小';

  @override
  String get outputsAll => '全部';

  @override
  String get outputsSmallestText => '只花最少的小额输出；找零确认期间，其余余额仍可使用。';

  @override
  String get outputsAllText => '花掉所有可用输出并返回一个找零输出。确认前全部锁定；之后输出更少、更大。';

  @override
  String get outputsSplitChange => '拆分找零';

  @override
  String get outputsSplitChangeText => '当剩余输出很少时';

  @override
  String outputsFilterAll(int count) {
    return '全部 $count';
  }

  @override
  String outputsFilterSpendable(int count) {
    return '可用 $count';
  }

  @override
  String outputsFilterConfirming(int count) {
    return '确认中 $count';
  }

  @override
  String outputsFilterLocked(int count) {
    return '锁定 $count';
  }

  @override
  String get outputsShowSpent => '显示已花费';

  @override
  String get outputsHideSpent => '隐藏已花费';

  @override
  String get outputsWordSpendable => '可用';

  @override
  String get outputsWordConfirming => '确认中';

  @override
  String get outputsWordFinalizing => '等待完成';

  @override
  String get outputsWordImmature => '未成熟';

  @override
  String get outputsWordMining => '挖矿中';

  @override
  String get outputsWordLocked => '已锁定';

  @override
  String get outputsWordSpent => '已花费';

  @override
  String get outputsMeanSpendable => '现在可以花费。';

  @override
  String outputsMeanConfirming(int need) {
    return '需要 $need 次确认后才能花费。';
  }

  @override
  String get outputsMeanFinalizing => '等待发送方完成付款。';

  @override
  String get outputsMeanImmature => '挖矿奖励，延迟一段时间后才能花费。';

  @override
  String get outputsMeanMining => '尚未确认的挖矿奖励。';

  @override
  String get outputsMeanLocked => '正被进行中的发送花费。';

  @override
  String get outputsMeanSpent => '已花费。';

  @override
  String outputsNoteReceived(String date) {
    return '收到于 $date';
  }

  @override
  String outputsNoteSend(String who) {
    return '发送至 $who';
  }

  @override
  String get outputsNoteSendPlain => '发送进行中';

  @override
  String get outputsFactHeight => '高度';

  @override
  String get outputsFactConfirmations => '确认数';

  @override
  String get outputsFactTransaction => '交易';

  @override
  String get outputsFactCommitment => '承诺值';

  @override
  String get outputsCopy => '复制';

  @override
  String get outputsCopied => '已复制承诺值';

  @override
  String get outputsEmpty => '暂无输出';

  @override
  String get outputsEmptyHint => '收到第一笔付款后会产生一个。地址在“接收”中。';

  @override
  String get outputsNoMatch => '此视图没有输出';

  @override
  String get outputsRetry => '重试';

  @override
  String outputsSettingsSubtitle(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出 · $strategy',
    );
    return '$_temp0';
  }

  @override
  String get outputsCancel => '取消';

  @override
  String get outputsSplitTitle => '拆分输出';

  @override
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  ) {
    return '花掉 $spent（$amount），生成 $made，每个约 $each。这是发往本钱包的普通网络交易，与任何发送一样在 3 个区块后确认；在此之前所有可用余额都被锁定。';
  }

  @override
  String get outputsToMake => '生成数量';

  @override
  String get outputsStepperHint => '2 到 10';

  @override
  String get outputsFactFee => '网络费用';

  @override
  String get outputsFactEach => '每个输出';

  @override
  String outputsFactAbout(String amount) {
    return '约 $amount';
  }

  @override
  String get outputsFactLocked => '锁定';

  @override
  String outputsFactLockedValue(String amount) {
    return '$amount，约 3 个区块';
  }

  @override
  String get outputsNothingSpendable => '期间没有可用余额。';

  @override
  String get outputsMinEach => '每个输出至少需要 0.5 EPIC。';

  @override
  String outputsSplitInto(int count) {
    return '拆分为 $count 个';
  }

  @override
  String get outputsConsolidateTitle => '合并输出';

  @override
  String outputsConsolidateText(String amount, String result, String spent) {
    return '花掉 $spent（$amount），生成一个 $result 的输出。这是发往本钱包的普通网络交易，与任何发送一样在 3 个区块后确认；在此之前所有可用余额都被锁定。下一次发送只花一个输出，因此费用最低。';
  }

  @override
  String get outputsConsolidateAction => '合并';

  @override
  String get outputsSplitPin => '输入 PIN 以确认拆分输出';

  @override
  String get outputsConsolidatePin => '输入 PIN 以确认合并输出';

  @override
  String outputsSplitStarted(int count) {
    return '拆分已开始：$count 个输出，约 3 个区块后确认';
  }

  @override
  String get outputsConsolidateStarted => '合并已开始：一个输出，约 3 个区块后确认';

  @override
  String get outputsAdvanced => '高级';

  @override
  String get outputsColState => '状态';

  @override
  String get outputsColValue => '数值';

  @override
  String get outputsColConfirmations => '确认数';

  @override
  String homePendingShort(String amount) {
    return '$amount 将保持锁定，直到收款方钱包响应。';
  }

  @override
  String get contactsSearchHint => '名称或地址';

  @override
  String get contactsEmptyTitle => '还没有联系人';

  @override
  String get contactsEmptyCaption => '联系人就是一个地址的名称。';

  @override
  String contactsNoMatchQuery(String query) {
    return '没有与“$query”匹配的联系人';
  }

  @override
  String get contactsSendAction => '发送';

  @override
  String get contactsEditAction => '编辑';

  @override
  String get contactsAddressHeading => '地址';

  @override
  String get contactsNoteHeading => '备注';

  @override
  String get contactsShowCode => '显示二维码';

  @override
  String get contactsHideCode => '隐藏二维码';

  @override
  String contactsQrLabel(String name) {
    return '$name 的地址二维码';
  }

  @override
  String get contactsDeleteConfirmBody => '此后，发往该地址的付款将显示地址而不是名称。';

  @override
  String contactsDeleted(String name) {
    return '已删除 $name。';
  }

  @override
  String get contactsCopied => '地址已复制。';

  @override
  String get invoicesNewRequest => '新建请求';

  @override
  String get invoicesSegmentSent => '已发送';

  @override
  String invoicesSegmentCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项',
      zero: '无',
    );
    return '$label，$_temp0';
  }

  @override
  String get invoicesToPayEmpty => '没有待付发票';

  @override
  String get invoicesToPayEmptyCaption => '你信任列表中的服务可以向此钱包开具发票。每张发票都在这里等待你批准。';

  @override
  String get invoicesSentEmpty => '没有已发送的请求';

  @override
  String get invoicesSentEmptyCaption => '请求是请某人向你支付一笔金额。';

  @override
  String get invoicesWaitingPayment => '等待付款';

  @override
  String get invoicesExpires => '到期';

  @override
  String invoicesUntil(String time) {
    return '截至 $time';
  }

  @override
  String get invoicesMessage => '消息';

  @override
  String get invoicesFrom => '来自';

  @override
  String get invoicesPaysFrom => '付款来源';

  @override
  String invoicesAvailable(String amount) {
    return '可用 $amount';
  }

  @override
  String invoicesShort(String amount) {
    return '余额不足，差 $amount。';
  }

  @override
  String get invoicesCheckNode => '节点';

  @override
  String get invoicesCheckEpicbox => 'Epicbox';

  @override
  String get invoicesNodeOk => '正常响应';

  @override
  String get invoicesNodeDown => '无响应';

  @override
  String get invoicesEpicboxOk => '已连接';

  @override
  String get invoicesEpicboxDown => '未连接';

  @override
  String get invoicesSendRequest => '发送请求';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '将请求 $payer 支付 $amount。请求在 24 小时后到期。';
  }

  @override
  String get invoicesRequestHowTitle => '请求之前';

  @override
  String get netStatusNode => '节点';

  @override
  String get netStatusEpicbox => 'Epicbox';

  @override
  String get netStatusTor => 'Tor';

  @override
  String get netStatusSynced => '已同步';

  @override
  String get netStatusSyncing => '同步中';

  @override
  String netStatusSyncingPercent(int percent) {
    return '同步中 $percent %';
  }

  @override
  String get netStatusConnecting => '连接中';

  @override
  String netStatusBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '落后 $countString',
    );
    return '$_temp0';
  }

  @override
  String get netStatusOffline => '离线';

  @override
  String get netStatusOnline => '在线';

  @override
  String get netStatusOff => '关闭';

  @override
  String get netStatusOn => '开启';

  @override
  String get netStatusFailed => '失败';

  @override
  String netStatusStarting(int percent) {
    return '启动中 $percent %';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => '网络状态';

  @override
  String get netStatusOpenHint => '显示服务器';

  @override
  String get serverNodeTitle => '节点';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => '查找或输入节点地址';

  @override
  String serverUseAddress(String address) {
    return '使用 $address';
  }

  @override
  String get serverTesting => '正在测试…';

  @override
  String serverTestAnswer(String height, String version) {
    return '区块 $height · v$version';
  }

  @override
  String serverTestFailed(String error) {
    return '无应答。$error';
  }

  @override
  String get serverMyNodes => '我的节点';

  @override
  String get serverPublicNodes => '公共节点';

  @override
  String get serverPublicRelays => '公共服务器';

  @override
  String get serverHealthUnknown => '无法访问 status.btlabs.uk；状态未知';

  @override
  String get serverAtTip => '已最新';

  @override
  String serverBehindShort(String count) {
    return '−$count';
  }

  @override
  String serverBehindLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '落后 $count 个区块',
    );
    return '$_temp0';
  }

  @override
  String get serverAddMine => '添加到我的节点';

  @override
  String get serverRemoveMine => '从我的节点移除';

  @override
  String get serverNotResponding => '无响应';

  @override
  String get serverHealthy => '正常';

  @override
  String get serverDegraded => '性能下降';

  @override
  String get serverHealthNone => '状态未知';

  @override
  String get serverCurrent => '当前';

  @override
  String get serverDefault => '默认';

  @override
  String serverLatency(String ms) {
    return '$ms 毫秒';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % 在线';
  }

  @override
  String serverSwitchTo(String host) {
    return '切换到 $host';
  }

  @override
  String get serverNodeSwitchNote => '钱包将重新连接，并根据新节点重新核对余额。';

  @override
  String get serverRelayWarning => '你的地址包含此服务器。切换会更改你的地址；付款方需要新地址。';

  @override
  String get serverRelaySwitchNote => '你的地址将改变；付款方需要新地址。';

  @override
  String get serverOtherRelay => '其他服务器，host 或 host:port';

  @override
  String get serverFactHeight => '高度';

  @override
  String get serverFactVersion => '版本';

  @override
  String get serverFactPeers => '对等节点';

  @override
  String get serverFactUptime => '24 小时在线率';

  @override
  String serverHeightAtTip(String height) {
    return '$height · 已最新';
  }

  @override
  String serverNodesAgree(String height) {
    return '节点一致于 $height';
  }

  @override
  String serverNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 个节点中 $up 个在线',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '最新区块 $seconds 秒前',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '最新区块 $minutes 分钟前',
    );
    return '$_temp0';
  }

  @override
  String serverCheckedAt(String time) {
    return 'status.btlabs.uk，检查于 $time';
  }

  @override
  String serverRowLabel(String host, String facts) {
    return '$host，$facts';
  }

  @override
  String get methodEpicbox => 'Epicbox';

  @override
  String get methodHttp => 'HTTP';

  @override
  String get methodTor => 'Tor';

  @override
  String get methodFile => '文件';

  @override
  String get methodArtCaptionEpicbox => 'Epicbox 服务器暂存';

  @override
  String get methodArtCaptionHttp => '直达对方钱包';

  @override
  String get methodArtCaptionTor => '直达，经由 Tor';

  @override
  String get methodArtCaptionFile => '发出文件，收回回复';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox：付款发送到 Epicbox 服务器，服务器暂存它，直到对方钱包上线';

  @override
  String get methodArtLabelHttp => 'HTTP：付款直接发送到对方钱包，对方钱包必须处于打开状态';

  @override
  String get methodArtLabelTor => 'Tor：付款经由 Tor 网络直接发送到对方钱包';

  @override
  String get methodArtLabelFile => '文件：交出交易文件，收回回复文件，然后由发送方完成';

  @override
  String get methodSendEpicboxTitle => '对方可以不在线。';

  @override
  String get settingsShowTipsAgain => '再次显示提示';

  @override
  String get settingsShowTipsAgainDone => '提示将再次显示';

  @override
  String get tipHide => '隐藏提示';

  @override
  String get methodSendEpicboxLine => 'Epicbox 服务器会暂存付款，直到对方打开钱包。';

  @override
  String get methodSendHttpTitle => '直达对方钱包。';

  @override
  String get methodSendHttpLine => '对方钱包必须处于打开状态，并且可以通过其 HTTP 地址访问。';

  @override
  String get methodSendTorTitle => '经由 Tor 直达对方钱包。';

  @override
  String get methodSendTorLine => '更慢，也更私密。对方钱包必须处于打开状态。';

  @override
  String get methodSendFileTitle => '无需连接。';

  @override
  String get methodSendFileLine => '交出文件，收回对方的回复文件，然后在这里完成。';

  @override
  String get methodReceiveEpicboxTitle => '分享它即可收款。';

  @override
  String get methodReceiveEpicboxLine => '钱包关闭时也有效：Epicbox 服务器会保存付款，直到钱包重新上线。';

  @override
  String get methodReceiveTorTitle => '更慢，也更私密。';

  @override
  String get methodReceiveTorLine => '仅在应用打开或短暂处于后台时可用。';

  @override
  String get methodReceiveFileTitle => '来回传递一个文件。';

  @override
  String get methodReceiveFileLine => '两个钱包之间无需连接。';

  @override
  String get methodAddressKindsTooltip => '地址类型';

  @override
  String get sendMethodLabel => '方式';

  @override
  String get sendToLabel => '收款方';

  @override
  String get sendToHint => '地址或联系人';

  @override
  String get sendSwitchedHttp => '经由 HTTP';

  @override
  String get sendSwitchedEpicbox => '经由 Epicbox';

  @override
  String get sendSwitchedTorAnnounce => 'Tor 地址。方式已设为 Tor。';

  @override
  String get sendSwitchedHttpAnnounce => 'HTTP 地址。方式已设为 HTTP。';

  @override
  String get sendSwitchedEpicboxAnnounce => 'Epicbox 地址。方式已设为 Epicbox。';

  @override
  String get sendReviewMethodHttp => 'HTTP，直达对方钱包';

  @override
  String get sendCancelRuleEpicbox => '在等待对方期间可以取消。';

  @override
  String get sendCancelRuleDirect => '对方钱包接受后无法取消。';

  @override
  String get sendCancelRuleFile => '在回复文件完成之前可以取消。';

  @override
  String get sendHttpReaching => '正在联系对方钱包… 请保持应用打开。';

  @override
  String get sendDeliveredWaitingBlock => '已送达 · 等待区块';

  @override
  String get sendHttpAddressShape => 'HTTP 地址以 http:// 或 https:// 开头。';

  @override
  String get sendPlainHttpTitle => '未加密。仍要发送吗？';

  @override
  String get sendPlainHttpBody =>
      '以明文 HTTP 发送到另一台设备。途中任何人都能读取这笔交易。https:// 地址是加密的。';

  @override
  String get sendCancelPossibleWhileWaiting => '在付款等待对方期间可以操作。';

  @override
  String get receiveEpicboxCaption => '念出地址时，核对前六位和后六位字符。';

  @override
  String get receiveTorCaption => '有些钱包显示的地址不带 .onion；两者是同一个地址。';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '未能联系到对方钱包。在你取消之前，这笔金额处于冻结状态，最长 $days 天。',
    );
    return '$_temp0';
  }

  @override
  String deskInvActFrom(String label) {
    return '来自 $label 的账单';
  }

  @override
  String get deskInvActFilter => '账单';

  @override
  String get deskInvActBlock => '账单';

  @override
  String get deskInvActOpen => '在账单中打开';

  @override
  String get deskInvActBilledBy => '开单方';

  @override
  String get deskInvActOverviewTitle => '账单';

  @override
  String deskInvActOverviewToPay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张账单待支付',
      zero: '没有待支付的账单',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张已开具账单等待付款方',
      zero: '没有等待中的已开具账单',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款需要处理：重试或取消',
    );
    return '$_temp0';
  }

  @override
  String get deskInvActReview => '查看';

  @override
  String get deskInvActOpenInvoices => '打开账单';

  @override
  String get deskInvNav => '账单';

  @override
  String get deskInvTitle => '账单';

  @override
  String get deskInvTabPay => '支付';

  @override
  String get deskInvTabIssue => '开具';

  @override
  String deskInvTabCount(String label, int count) {
    return '$label（$count）';
  }

  @override
  String get deskInvIssueAction => '开具账单';

  @override
  String get deskInvChecking => '正在检查';

  @override
  String deskInvCheckedAt(String time) {
    return '$time 已检查';
  }

  @override
  String get deskInvCheckFailedTitle => 'Epicbox 服务器无响应';

  @override
  String get deskInvCheckFailedBody => '列表显示之前收到的内容。没有丢失任何内容；钱包每 2 分钟重试一次。';

  @override
  String get deskInvReqWaiting => '等待付款方';

  @override
  String get deskInvReqPaid => '已付款，正在完成';

  @override
  String get deskInvReqPosted => '已发布';

  @override
  String deskInvConfirming(int count, int total) {
    return '确认中 $count/$total';
  }

  @override
  String get deskInvCompleted => '已完成';

  @override
  String get deskInvReqNotPosted => '未发布';

  @override
  String get deskInvDeclined => '已拒绝';

  @override
  String get deskInvExpired => '已过期';

  @override
  String get deskInvWithdrawn => '已撤回';

  @override
  String get deskInvReqBounced => '已退回';

  @override
  String get deskInvPayWaiting => '待支付';

  @override
  String get deskInvPayPaying => '正在付款';

  @override
  String get deskInvPayNotDelivered => '未送达';

  @override
  String get deskInvPayDelivered => '等待发布';

  @override
  String get deskInvPayPosted => '服务已发布';

  @override
  String get deskInvPayWithdrawnAfterPay => '付款后已撤回';

  @override
  String get deskInvPayPastTtl => '不在链上';

  @override
  String get deskInvPayCancelled => '已取消';

  @override
  String get deskInvUnpaid => '未支付';

  @override
  String get deskInvYouPay => '您支付';

  @override
  String deskInvExpiresAt(String time) {
    return '$time 过期';
  }

  @override
  String get deskInvSlateId => 'Slate ID';

  @override
  String get deskInvAdvanced => '高级';

  @override
  String get deskInvOneDevice => '请只在一台设备上使用账单。装有此钱包的另一台设备可能会收走本应给这台设备的付款。';

  @override
  String get deskInvFailed => '操作未成功。没有任何更改；请重试。';

  @override
  String get deskInvHowItWorks => '账单如何运作';

  @override
  String get deskInvAddressHint => 'es…@epicbox.epiccash.com';

  @override
  String get deskInvEpicboxAddress => 'Epicbox 地址';

  @override
  String get deskInvHelpTitle => '账单';

  @override
  String get deskInvHelpLede => '来自受信任发送方的账单，批准后才付款。';

  @override
  String get deskInvHelpFlowTitle => '账单如何运作';

  @override
  String get deskInvHelpFlowShort => '开单方把账单发到付款方的账单地址。付款方批准之前不会付款。';

  @override
  String get deskInvHelpFlowIntro => '账单是一项付款请求。**开单方**收款；**付款方**做决定。';

  @override
  String get deskInvHelpFlowStep1 => '开单方的钱包通过 Epicbox 服务器把账单发到付款方的**账单地址**。';

  @override
  String get deskInvHelpFlowStep2 =>
      '付款方在 [[账单 › 支付]] 中打开它，核对发送方、金额和留言，然后输入钱包密码，选择**批准并付款**。';

  @override
  String get deskInvHelpFlowStep3 => '付款方的钱包把付款发到开单方的**收款地址**。';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return '开单方的钱包完成这笔付款并发布到网络。经过 $confirmations 个确认后即为最终。';
  }

  @override
  String get deskInvHelpFlowNever =>
      '未经批准不会付款，账单也绝不会给付款方的钱包增加资金。每张账单都有付款期限，最长 48 小时；过期后无法再付款。';

  @override
  String get deskInvHelpFlowIssued => '本钱包开具的账单在 [[账单 › 开具]] 中。';

  @override
  String get deskInvHelpTrustTitle => '为什么只接受受信任的发送方';

  @override
  String get deskInvHelpTrustShort => '只有受信任列表中的发送方才能把账单放进收件箱。这可以挡住垃圾信息和假账单。';

  @override
  String get deskInvHelpTrustP1 =>
      '钱包只在自己的账单地址接收账单，并且只接收受信任列表中的发送方（按发送方地址匹配）。其他一切在打开之前就被直接丢弃，不会出现在 [[账单 › 支付]] 中。';

  @override
  String get deskInvHelpTrustP2 => '没有这个列表，任何知道账单地址的人都可以用垃圾信息或看似真实的账单塞满收件箱。';

  @override
  String get deskInvHelpTrustP3 =>
      '信任只是允许发送方提出请求。受信任的发送方无法拿走任何东西：每张账单仍需**批准并付款**。';

  @override
  String get deskInvHelpTrustWhere1 => '在 [[设置 › 账单]] 中信任发送方。';

  @override
  String get deskInvHelpTrustWhere2 => '或在 [[联系人]] 中为联系人打开**信任其账单**。';

  @override
  String get deskInvHelpTrustWhere3 => '发送方可随时从列表中移除。之后它的新账单会被丢弃。';

  @override
  String get deskInvHelpAddrTitle => '为什么要单独的账单地址';

  @override
  String get deskInvHelpAddrShort => '账单到达自己的地址，与别人付款用的收款地址分开。';

  @override
  String get deskInvHelpAddrP1 =>
      '钱包有两个 Epicbox 地址。[[接收]] 中的**收款地址**接收付款。**账单地址**只接收账单。';

  @override
  String get deskInvHelpAddrP2 => '分开之后，账单地址可以提供给服务或更换，而不会暴露或改变别人付款用的地址。';

  @override
  String get deskInvHelpAddrP3 => '账单地址不接收付款：发到它的付款会被丢弃。收款应使用收款地址。';

  @override
  String get deskInvHelpAddrWhere1 => '在 [[设置 › 账单]] 中查找、复制账单地址或显示其二维码。';

  @override
  String get deskInvHelpAddrWhere2 => '**新的账单地址**会替换它。持有旧地址的服务在拿到新地址之前无法再发送账单。';

  @override
  String get deskInvHelpDiagramTitle => '账单的流转';

  @override
  String get deskInvHelpDiagramIssuer => '开单方';

  @override
  String get deskInvHelpDiagramPayer => '付款方';

  @override
  String get deskInvHelpDiagramIssues => '开具账单';

  @override
  String get deskInvHelpDiagramInvoice => '账单';

  @override
  String get deskInvHelpDiagramGate => '账单地址';

  @override
  String get deskInvHelpDiagramGateSub => '仅限受信任的发送方';

  @override
  String get deskInvHelpDiagramDropped => '其他发送方';

  @override
  String get deskInvHelpDiagramDroppedSub => '直接丢弃';

  @override
  String get deskInvHelpDiagramReview => '核对并批准';

  @override
  String get deskInvHelpDiagramReviewSub => '批准并付款';

  @override
  String get deskInvHelpDiagramPayment => '付款';

  @override
  String get deskInvHelpDiagramPayAddr => '收款地址';

  @override
  String get deskInvHelpDiagramPayAddrSub => '不是账单地址';

  @override
  String get deskInvHelpDiagramFinal => '完成并发布';

  @override
  String deskInvHelpDiagramFinalSub(int confirmations) {
    return '确认数达到 $confirmations 后为最终';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      '开单方把账单发到付款方的账单地址，该地址只接受受信任的发送方并丢弃其他；付款方核对并批准；付款发到开单方的收款地址；开单方的钱包完成付款并发布到网络。';

  @override
  String get deskInvIssuerFormTitle => '开具账单';

  @override
  String get deskInvIssuerFirstTitle => '首次开具账单之前';

  @override
  String get deskInvIssuerYourAddress => '您的收款地址';

  @override
  String get deskInvIssuerMethod => '方式';

  @override
  String get deskInvIssuerEpicbox => 'Epicbox';

  @override
  String get deskInvIssuerFile => '文件';

  @override
  String get deskInvIssuerDirect => '直连';

  @override
  String get deskInvIssuerSoon => '即将推出';

  @override
  String get deskInvIssuerPayer => '对方的账单地址';

  @override
  String get deskInvIssuerPayerHelp => '对方钱包在 设置 › 账单 中显示。';

  @override
  String get deskInvIssuerPayerMissing => '粘贴对方的账单地址。';

  @override
  String get deskInvIssuerPayerInvalid => '这不是有效的 Epicbox 地址。';

  @override
  String get deskInvIssuerPayerOwn => '这是您自己的地址之一。请使用付款方提供的账单地址。';

  @override
  String get deskInvIssuerPayerHttp =>
      '通过 Epicbox 的账单需要 Epicbox 地址，而不是 HTTP 或 Tor 地址。';

  @override
  String get deskInvIssuerContacts => '联系人';

  @override
  String get deskInvIssuerNoContacts => '还没有联系人有账单地址。请在联系人中添加。';

  @override
  String get deskInvIssuerNoInvoices =>
      '该钱包曾退回过账单：它无法通过 Epicbox 支付账单。请改为发送账单文件，或请对方直接付款给您。';

  @override
  String get deskInvIssuerUseFile => '使用文件';

  @override
  String get deskInvIssuerUnknown =>
      '只有 wallet-for-epic 和其他 LEPIC 钱包可以通过 Epicbox 支付账单。Epic GUI wallet 和 Stack Wallet 完全无法支付账单；epic-wallet 命令行可以支付账单文件。';

  @override
  String get deskInvIssuerAmount => '金额';

  @override
  String get deskInvIssuerAmountMissing => '请输入金额。';

  @override
  String get deskInvIssuerAmountZero => '金额必须大于 0。';

  @override
  String get deskInvIssuerAmountDecimals => 'EPIC 最多 8 位小数。';

  @override
  String get deskInvIssuerAmountCap => '超过 EPIC 的总供应量。';

  @override
  String get deskInvIssuerAmountHelp => '您的钱包不会支出任何资金：付款方支付此金额外加其自己的手续费。';

  @override
  String get deskInvIssuerMessage => '给付款方的留言';

  @override
  String deskInvIssuerMessageCount(int used, int max) {
    return '$used/$max 字节';
  }

  @override
  String get deskInvIssuerMessageLong => '留言过长。';

  @override
  String deskInvIssuerExpiry(int hours) {
    return '付款方有 $hours 小时付款。';
  }

  @override
  String get deskInvIssuerIssue => '开具';

  @override
  String get deskInvIssuerRelayDown => 'Epicbox 服务器无响应，暂时无法发出账单。';

  @override
  String get deskInvIssuerFixFields => '请修正标红的字段。';

  @override
  String get deskInvIssuerNotDelivered => '账单未到达 Epicbox 服务器。未发送任何内容。请重试。';

  @override
  String deskInvIssuerSent(String payer) {
    return '已向 $payer 发送账单。';
  }

  @override
  String get deskInvIssuerEmpty => '还没有开具账单。账单会让联系人或服务向您付款；它不花费任何资金。';

  @override
  String deskInvIssuerTo(String payer) {
    return '开给 $payer 的账单';
  }

  @override
  String deskInvIssuerIssued(String time) {
    return '$time 开具';
  }

  @override
  String get deskInvIssuerPayerFact => '付款方';

  @override
  String get deskInvIssuerAmountFact => '金额';

  @override
  String get deskInvIssuerMessageFact => '留言';

  @override
  String get deskInvIssuerSentFact => '开具时间';

  @override
  String get deskInvIssuerExpiresFact => '过期时间';

  @override
  String get deskInvIssuerAnsweredFact => '结束时间';

  @override
  String get deskInvIssuerStepPaid => '已付款';

  @override
  String get deskInvIssuerStepConfirming => '确认中';

  @override
  String get deskInvIssuerEnded => '此账单未付款即结束。未收到任何款项。';

  @override
  String get deskInvIssuerWithdraw => '撤回';

  @override
  String get deskInvIssuerWithdrawTitle => '撤回此账单？';

  @override
  String deskInvIssuerWithdrawBody(String payer) {
    return '$payer 将无法再支付它。';
  }

  @override
  String get deskInvIssuerKeep => '保留';

  @override
  String get deskInvIssuerWithdrawn => '账单已撤回。';

  @override
  String get deskInvIssuerRepost => '重新发布';

  @override
  String get deskInvIssuerReposted => '付款已重新发布。';

  @override
  String get deskInvIssuerNodeDown => '节点无响应。请在节点可用时重试。';

  @override
  String get deskInvIssuerNotPostedText => '付款已完成但未进入网络：节点拒绝了它或无法连接。';

  @override
  String get deskInvIssuerCancel => '取消付款';

  @override
  String get deskInvIssuerCancelTitle => '取消此付款？';

  @override
  String deskInvIssuerCancelBody(String payer) {
    return '这笔款项将不会到账。$payer 的资金会在其钱包中保持锁定，直到对方在自己那边取消。';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return '$payer 的钱包退回了账单：它无法支付账单。请改为让对方直接付款给您。';
  }

  @override
  String get deskInvIssuerSendFile => '改用文件';

  @override
  String get deskInvIssuerLate => '此账单结束后收到一笔付款。已被拒绝；没有任何变化。';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer 已付款。您的钱包已完成并发布该付款。';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return '已送达 $payer 的账单地址。在对方批准之前不会付款。';
  }

  @override
  String get deskInvIssuerCopySlate => '复制 Slate ID';

  @override
  String get deskInvIssuerStepsIntro => '对方的钱包必须支持账单。首次开具账单之前：';

  @override
  String get deskInvIssuerStepTrust => '1. 对方把您下面的收款地址加入受信任的发送方。';

  @override
  String get deskInvIssuerStepAddress => '2. 对方把其账单地址提供给您。';

  @override
  String get deskInvIssuerStepIssued => '已开具';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return '$payer 已支付 $amount EPIC。';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return '$payer 拒绝了你的发票。';
  }

  @override
  String get deskInvNoticeIssuedExpired => '你开具的一张发票已过期未付。';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return '$service 在你回复前撤回了一张发票。';
  }

  @override
  String get deskInvNoticeExpired => '一张发票在你回复前已过期。';

  @override
  String get deskInvNoticeUnknownPayment =>
      '收到一笔针对本设备未开具发票的付款，已被拒绝。如果是使用此钱包的另一台设备开具的，请让付款方取消后重新付款。';

  @override
  String get deskInvNoticeUnknownAnswer =>
      '收到一条针对本设备未发送付款的回复，已被拒绝。如果是使用此钱包的另一台设备发送的，请在那里取消后重新发送。';

  @override
  String get deskInvPayerWaitingHead => '等待您处理';

  @override
  String get deskInvPayerNeedsHead => '待处理的付款';

  @override
  String get deskInvPayerReview => '查看';

  @override
  String get deskInvPayerPaidHead => '已支付';

  @override
  String get deskInvPayerView => '查看';

  @override
  String get deskInvPayerNoMessage => '无留言';

  @override
  String deskInvPayerDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已忽略 $count 条来自不受信任发送方的消息。',
    );
    return '$_temp0';
  }

  @override
  String get deskInvPayerTrustService => '信任服务…';

  @override
  String get deskInvPayerYourInvoiceAddress => '您的账单地址';

  @override
  String get deskInvPayerEmptyTitle => '没有等待中的账单';

  @override
  String get deskInvPayerEmptyText => '当您信任的服务向您开账单时，账单会显示在这里。在您批准之前不会付款。';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return '您给 $service 的付款未送达';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      '付款已签名并保存在此设备上；资金保持锁定。重试会再次发送，无需再次批准。';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service 撤回了一张您已支付的账单';
  }

  @override
  String get deskInvPayerWithdrawnText => '这笔付款可能永远不会上链。取消它以解锁您的资金。';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return '您给 $service 的付款不在链上';
  }

  @override
  String get deskInvPayerPastTtlText => '其期限已过，网络未见到它。取消它以解锁您的资金。';

  @override
  String get deskInvPayerCancelPayment => '取消付款';

  @override
  String get deskInvPayerSafetyTitle => '只支付您预期的账单';

  @override
  String get deskInvPayerSafetyText => '账单永远不会给您的钱包增加资金。批准它就是向外付款。';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return '您在 $ago 前已向 $service 支付过相同金额';
  }

  @override
  String get deskInvPayerSameBillText => '付款前请确认这是一张新账单。';

  @override
  String deskInvPayerAgoHours(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String deskInvPayerAgoMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get deskInvPayerFee => '手续费';

  @override
  String get deskInvPayerTotal => '合计';

  @override
  String get deskInvPayerBalanceAfter => '付款后余额';

  @override
  String get deskInvPayerMessageCaption => '由服务填写。您的钱包不会核实。';

  @override
  String get deskInvPayerPaysTo => '付款给';

  @override
  String deskInvPayerTrustedSince(String service, String date) {
    return '$service，自 $date 起受信任';
  }

  @override
  String get deskInvPayerExpires => '过期时间';

  @override
  String get deskInvPayerLockHeight => '锁定高度';

  @override
  String get deskInvPayerLockNone => '无';

  @override
  String get deskInvPayerReceived => '收到时间';

  @override
  String get deskInvPayerShort => '可用资金不足';

  @override
  String deskInvPayerShortText(String total, String spendable) {
    return '您需要 $total EPIC 可用资金；您有 $spendable EPIC。确认中的资金在 3 次确认后计入。';
  }

  @override
  String get deskInvPayerNodeDownTitle => '节点无响应';

  @override
  String get deskInvPayerNodeDownText =>
      '钱包无法检查您的资金，因此无法付款。节点恢复响应后即可再次批准；您可以在 设置 › 节点 中选择其他节点。';

  @override
  String get deskInvPayerPaid => '此账单已支付。不能再为其付款。';

  @override
  String get deskInvPayerDeclinedText => '您已拒绝此账单。未支付任何款项。';

  @override
  String get deskInvPayerBack => '返回账单';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return '向 $service 支付 $amount EPIC + $fee 手续费？';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC 将离开您的钱包。输入钱包密码以批准。';
  }

  @override
  String get deskInvPayerPassword => '钱包密码';

  @override
  String get deskInvPayerWrongPassword => '密码错误。未支付任何款项。';

  @override
  String get deskInvPayerEnterPassword => '请输入钱包密码。';

  @override
  String get deskInvPayerPay => '付款';

  @override
  String get deskInvPayerCancel => '取消';

  @override
  String get deskInvPayerClose => '关闭';

  @override
  String get deskInvPayerNodeDownPay => '节点无响应。未支付任何款项。';

  @override
  String get deskInvPayerAlreadyAnswered => '此账单已处理。未额外支付任何款项。';

  @override
  String get deskInvPayerCannotPay => '此账单无法支付。未支付任何款项。';

  @override
  String get deskInvPayerNotDeliveredToast => '已签名，未送达';

  @override
  String get deskInvPayerNotDeliveredToastText =>
      'Epicbox 服务器无响应。请在 账单 › 支付 中重试；无需再次批准。';

  @override
  String get deskInvPayerRetryFailed => '仍未送达';

  @override
  String get deskInvPayerRetryFailedText => 'Epicbox 服务器无响应。付款仍以签名状态保存在此设备上。';

  @override
  String get deskInvPayerCancelTitle => '取消此付款？';

  @override
  String get deskInvPayerCancelText =>
      '取消会在此处解锁您的资金。服务仍持有您签名的付款，因此在这些资金再次花出之前，它仍可能完成。';

  @override
  String deskInvPayerCancelWho(String amount, String service) {
    return '$amount EPIC 给 $service';
  }

  @override
  String get deskInvPayerKeepPayment => '保留';

  @override
  String get deskInvPayerOnItsWay => '已在途中：无法取消。';

  @override
  String get deskInvPayerCannotCheck => '暂时无法检查网络；请在节点可用时重试。';

  @override
  String get deskInvPayerCancelled => '付款已取消';

  @override
  String get deskInvPayerCancelledText => '您的资金已解锁。';

  @override
  String get deskInvPayerDeclined => '账单已拒绝。未支付任何款项。';

  @override
  String get deskInvPayerSpendToSelf => '立即转给自己';

  @override
  String get deskInvPayerSpendToSelfHelp =>
      '使取消成为最终结果：服务方持有的已签名副本将无法完成。需支付网络手续费。';

  @override
  String get deskInvPayerSpentText => '你的资金已解锁并在此钱包内转移。取消已为最终结果。';

  @override
  String get deskInvPayerSpendFailedText => '你的资金已解锁，但转移未成功。取消尚未成为最终结果。';

  @override
  String get deskInvPayerLocked => '此发票无法支付：它被锁定到较晚的区块。未支付任何款项。';

  @override
  String get deskInvPayerRelayDownPay => 'Epicbox 服务器没有响应。未支付任何款项。';

  @override
  String get deskInvSetTitle => '账单';

  @override
  String get deskInvSetIntro => '您信任的服务会向此钱包的账单地址发送账单。在您批准每张账单之前不会付款。';

  @override
  String get deskInvSetAddressLabel => '账单地址';

  @override
  String get deskInvSetAddressWarning => '只提供给您信任的服务。此地址不接收付款。';

  @override
  String get deskInvSetCopy => '复制';

  @override
  String get deskInvSetCopied => '已复制账单地址。只提供给您信任的服务；此地址不接收付款。';

  @override
  String get deskInvSetQrShow => '显示二维码';

  @override
  String get deskInvSetQrHide => '隐藏二维码';

  @override
  String get deskInvSetQrLabel => '您的账单地址二维码';

  @override
  String deskInvSetIndex(int index) {
    return '账单地址 $index';
  }

  @override
  String get deskInvSetTrusted => '受信任的发送方';

  @override
  String get deskInvSetTrustedNone => '没有受信任的发送方。其他人的账单会被直接忽略，不会打开。';

  @override
  String deskInvSetSince(String date) {
    return '自 $date 起受信任';
  }

  @override
  String get deskInvSetContactTag => '联系人';

  @override
  String get deskInvSetRemove => '移除';

  @override
  String deskInvSetRemoveTitle(String name) {
    return '不再信任 $name？';
  }

  @override
  String deskInvSetRemoveBody(String name) {
    return '$name 将无法再向您发送账单。已在等待的账单会保留，直到您处理或它们过期。';
  }

  @override
  String deskInvSetRemoved(String name) {
    return '$name 已无法再向您发送账单。';
  }

  @override
  String get deskInvSetKeep => '保留';

  @override
  String get deskInvSetAdd => '信任发送方';

  @override
  String get deskInvSetAddBody => '受信任的发送方可以向此钱包的账单地址发送账单。在您用钱包密码批准每张账单之前不会付款。';

  @override
  String get deskInvSetName => '名称';

  @override
  String get deskInvSetNameMissing => '请为发送方命名。';

  @override
  String get deskInvSetSenderAddress => '对方的收款地址';

  @override
  String get deskInvSetSenderMissing => '粘贴服务显示的地址。';

  @override
  String get deskInvSetSenderInvalid => '这不是有效的 Epicbox 地址。';

  @override
  String get deskInvSetTrust => '信任';

  @override
  String deskInvSetAdded(String name) {
    return '$name 现在可以向您发送账单。';
  }

  @override
  String deskInvSetDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已忽略 $count 条来自不受信任发送方的消息，未打开。',
    );
    return '$_temp0';
  }

  @override
  String get deskInvSetRotate => '新的账单地址';

  @override
  String get deskInvSetRotateHint => '持有旧地址的服务将无法再向您发送账单。';

  @override
  String get deskInvSetRotateTitle => '生成新的账单地址？';

  @override
  String get deskInvSetRotateBody => '持有旧地址的服务将无法再向您发送账单。请把新地址提供给每个向您开账单的服务。';

  @override
  String get deskInvSetRotateConfirm => '生成新地址';

  @override
  String get deskInvSetRotated => '新的账单地址已就绪。请提供给您的服务。';

  @override
  String get deskInvSetExpiry => '付款期限';

  @override
  String get deskInvSetExpiryHint => '您开具的账单可支付多久，以及收到的账单等待您多久。最长 48 小时。';

  @override
  String deskInvSetHours(int hours) {
    return '$hours 小时';
  }

  @override
  String get deskInvSetCancel => '取消';

  @override
  String get deskInvSetContactSection => '账单';

  @override
  String get deskInvSetTheirInvoice => '对方的账单地址';

  @override
  String get deskInvSetTheirInvoiceNone => '未保存账单地址。请向对方索取，以便开具账单。';

  @override
  String get deskInvSetTrustedSwitch => '信任其账单';

  @override
  String get deskInvSetTrustedSwitchHelp => '允许此联系人向您开账单。在您批准账单之前不会付款。';

  @override
  String get deskInvSetIssueNeeds => '需要对方的账单地址。';

  @override
  String get deskInvSetShare => '分享账单地址';

  @override
  String get deskInvSetReceiveHint => '请联系人或服务向您付款。对方的钱包必须支持账单。';

  @override
  String get deskInvSetRestoredHint => '此钱包是用助记词恢复的？请重新把这个发票地址提供给服务方。';

  @override
  String get serverSwitchRelayTitle => '更换 epicbox 服务器？';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'epicbox 地址将变为 …@$relay。发送方需要新地址。发送到旧地址的付款会留在旧服务器上。';
  }

  @override
  String get serverSwitchRelayConfirm => '更换';

  @override
  String get helpButton => '帮助';

  @override
  String get helpSearchHint => '搜索帮助';

  @override
  String get helpEnglishOnly => '帮助目前仅提供英文。';

  @override
  String helpNoMatch(String query) {
    return '没有与“$query”匹配的帮助';
  }

  @override
  String helpMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个主题',
      one: '1 个主题',
    );
    return '$_temp0';
  }

  @override
  String get helpShowHandshake => '查看运作方式';

  @override
  String get helpMoreInSection => '本节更多内容';

  @override
  String get sendBalanceAfter => '发送后余额';

  @override
  String get sendSpendableUntilChange => '找零确认前可用';

  @override
  String get sendSpendableUntilChangeHint => '找零在发送确认后返回。';

  @override
  String serverSwitched(String host) {
    return '已切换到 $host';
  }

  @override
  String get methodDirect => '直连';

  @override
  String get methodDirectShape => 'http://host:3415 或 xxxx….onion';

  @override
  String get methodSendDirectLine => '对方钱包必须处于打开状态。onion 地址经由 Tor。';

  @override
  String get methodArtLabelDirect => '直连：付款直接发送到收款人的钱包，该钱包必须处于打开状态';

  @override
  String get methodReceiveEpicboxShort => '钱包关闭时也可收款。';

  @override
  String get methodReceiveDirectTitle => '直接发送到此钱包。';

  @override
  String get methodReceiveDirectLine => '仅在应用打开时可用。';

  @override
  String methodLineOverTor(String line) {
    return '$line 经由 Tor。';
  }

  @override
  String get sendSwitchedDirect => '直连地址';

  @override
  String get sendSwitchedDirectAnnounce => '直连地址。方式已设为直连。';

  @override
  String get sendDirectAddressShape =>
      '直连地址以 http:// 或 https:// 开头，或以 .onion 结尾。';

  @override
  String get torNotOverTor => '不经由 Tor';

  @override
  String get torNeeds => '需要 Tor。';

  @override
  String get torTurnOn => '开启 Tor';

  @override
  String get torTurnOff => '关闭 Tor';

  @override
  String get torNotConnectedNotice => 'Tor 未连接。';

  @override
  String get torWaiting => '正在等待 Tor';

  @override
  String get torWordStarting => '正在启动…';

  @override
  String get torWordNotConnected => '未连接';

  @override
  String get torSettingsLink => 'Tor 设置';

  @override
  String get torNetworkLabel => 'Tor 网络';

  @override
  String get torNetworkHint =>
      '网络活动经由 Tor 网络。Tor 隐藏钱包的互联网地址：每个连接都经过多个志愿者运营的中继，因此没有服务器能得知钱包所在。通知在 Tor 开启时关闭。';

  @override
  String get receiveTabDirect => '直连';

  @override
  String get receiveDirectNeedsTor => '直连收款需要 Tor。';

  @override
  String get receiveDirectMeanwhile => '在此期间，付款方使用 Epicbox 地址。';

  @override
  String get netStatusOverTor => '经由 Tor';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsNotificationsHint => '使用 Google 的通知服务。不会共享任何敏感数据。';

  @override
  String get settingsPushPaused => 'Tor 开启时已暂停';

  @override
  String get pushConfirmRelayBody =>
      '通知使用 BT Labs 的 Epicbox 和 Google 的通知服务。不会共享任何敏感数据。';

  @override
  String get pushConfirmRelayAddress => '你的 Epicbox 地址将会更改。请分享新地址。';

  @override
  String get pushRelaySwitchFailed => '无法切换服务器。通知保持关闭。';

  @override
  String get pushConfirmTitle => '开启通知？';

  @override
  String get pushConfirmBody => '通知使用 Google 的通知服务。不会共享任何敏感数据。';

  @override
  String get pushConfirmAction => '开启';

  @override
  String get pushNoticeOn => '通知已开启';

  @override
  String get pushNoticeOff => '通知已关闭';

  @override
  String get pushNoticeAvailable => '通知可在设置中开启。';

  @override
  String get torWayOver => '经由 Tor';

  @override
  String get torWayWaiting => '正在等待 Tor';

  @override
  String get torWayNotConnected => 'Tor 未连接。';
}
