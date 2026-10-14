// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Epic Cash 钱包';

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
  String get shellTitle => 'Epic Cash';

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
  String get homeBalanceWaitingToFinish => '等待完成';

  @override
  String get balanceWaitingHelp => '你已接受，发送方还需完成。';

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
  String get receiveAddressLabel => '你的地址';

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
  String get setupTitle => '网络设置';

  @override
  String get setupNetworkSettingsTooltip => '网络设置';

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
  String get restorePhraseHelper => '12 或 24 个单词，以空格分隔。';

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
      '下一个页面允许截图。助记词的截图或照片就是你钱包的完整副本：任何看到它的人都能转走你的资金，相册应用还可能把它上传到云端。抄在纸上最安全。';

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
  String get contactsAddressLabel => 'epicbox 地址';

  @override
  String contactsDuplicate(String name) {
    return '此地址已保存为 $name。';
  }

  @override
  String get contactsNoteLabel => '备注（可选）';

  @override
  String get contactsSave => '保存联系人';

  @override
  String get contactsAddressMissing => '请输入对方的 epicbox 地址。';

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
  String get settingsSectionNetwork => '网络';

  @override
  String get settingsNetworkAndNode => '网络和节点';

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
  String get settingsPaymentNotifications => '付款通知';

  @override
  String get settingsPushHint => '由 Google Firebase 推送。';

  @override
  String get settingsPushOnNotice => '目前还没有 epicbox 服务器发送这类通知。请打开应用以接收付款。';

  @override
  String get settingsPushOffNotice => '通知将在应用下次启动时停止。';

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
  String get helpWaitingQuestion => '为什么我的付款显示“等待接收方”？';

  @override
  String helpWaitingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天',
    );
    return 'Epic Cash 付款由双方的钱包共同完成：你的钱包发起付款，接收方的钱包接受付款，最后由你的钱包完成付款。Epic 的 epicbox 服务会将你的付款保存约一周，直到接收方的钱包上线并回复。在此之前，这笔金额会在你的钱包中保持锁定，因此不会被重复花费。如果付款未完成，你的钱包会在 $_temp0后自动取消付款并解锁金额。';
  }

  @override
  String get helpCancellingQuestion => '我应该取消付款吗？';

  @override
  String helpCancellingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天',
    );
    return '通常不需要：未完成的付款会在 $_temp0后自动取消并解锁金额。如需提前终止，例如接收方表示永远不会回复，请在付款仍显示“等待接收方”时打开它，然后点击“取消付款”；之后你需要重新发送。已在确认中的付款无法取消。使用本应用旧版本发起的付款不会自动取消：如果某笔付款已等待超过两周，请将其取消并重新发送。';
  }

  @override
  String get helpReceivingQuestion => '为什么接收付款时必须保持应用打开？';

  @override
  String helpReceivingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天',
    );
    return '你的钱包必须接受每一笔转入的付款，而只有在应用打开并连接到 epicbox 时才能做到。应用关闭时发来的付款会在 epicbox 中等待约一周，并在你下次解锁时到达。超过这个时间，epicbox 会将其删除；如果发送方使用的是本应用，其钱包会在 $_temp0后自动取消该付款，对方可以重新发送。你的钱包接受付款后，还需要发送方的钱包完成付款；在此之前，它会显示为“等待发送方”。';
  }

  @override
  String helpConfirmationsQuestion(int count) {
    return '什么是确认？为什么需要 $count 个？';
  }

  @override
  String helpConfirmationsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个确认（约 $count 分钟）',
    );
    return '确认是指在包含你这笔付款的区块之后，Epic Cash 区块链上新增的区块；大约每分钟产生一个区块。每增加一个区块，付款就更难被撤销。经过 $_temp0后，付款会显示为“已完成”，收到的币即可使用；这是 Epic 钱包的标准。';
  }

  @override
  String get helpHistoryQuestion => '为什么恢复钱包后交易记录不见了？';

  @override
  String get helpHistoryAnswer =>
      '助记词能找回你的余额：钱包会扫描区块链，找出属于它的币。付款对象、你的备注和大多数日期从不保存在区块链上，因此恢复时无法找回。如果你保存过历史备份，请在“设置”的“交易记录”下点击“导入历史备份”，即可找回这些信息。该备份必须是你保存在丢失的手机以外的副本，例如在电子邮件或云存储中。';

  @override
  String get helpAddressQuestion => '我的地址会改变吗？';

  @override
  String get helpAddressAnswer =>
      '你的地址由助记词和你使用的 epicbox 服务器生成，以 @ 加该服务器的名称结尾。只要你继续使用同一个 epicbox 服务器，地址就保持不变。如果你在网络设置中选择了其他服务器，地址就会改变，请把新地址告诉向你付款的人。';

  @override
  String get helpPhraseQuestion => '什么是助记词？谁能看到它？';

  @override
  String get helpPhraseAnswer =>
      '助记词是一组单词，是你资金的钥匙：任何拥有它的人都能拿走你的币，而你也可以用它在新手机上恢复钱包。本应用只在你输入 PIN 码后才会显示它，并且从不将它发送到任何地方。请把它抄写在纸上，存放在安全的地方，切勿分享给他人或输入到任何网站。';

  @override
  String get helpFeesQuestion => '手续费用来支付什么？';

  @override
  String get helpFeesAnswer =>
      '手续费归将你的付款打包进区块链的矿工所有。它通常只是 1 EPIC 的很小一部分，具体取决于你的钱包为完成这笔付款合并了多少个币。发送前你会看到确切的手续费。';

  @override
  String get helpNodeQuestion => '什么是节点？';

  @override
  String get helpNodeAnswer =>
      '节点是保存一份 Epic Cash 区块链副本的计算机。钱包向节点查询你的余额，并通过它将你的付款发送到网络。节点能看到你的 IP 地址以及钱包查询了哪些币，因此请在网络设置中选择你信任的节点。打开“高级选项”后，可在设置中找到网络设置；解锁界面上也有。';

  @override
  String get helpOtherWaysQuestion => '还有其他发送方式吗？';

  @override
  String get helpOtherWaysAnswer =>
      '供高级用户使用。如果不使用 epicbox，请在“其他发送方式”中选择“通过交易文件发送”：你分享一个文件，接收方接受后返回一个 .response 文件，你再打开该文件完成付款。在设置中打开“高级选项”后，才会显示“其他发送方式”。';

  @override
  String get helpStillStuck => '仍未解决？';

  @override
  String get helpTellUs => '告诉我们发生了什么，或哪里不清楚。';

  @override
  String get helpSendFeedback => '发送反馈';

  @override
  String get feedbackTitle => '发送反馈';

  @override
  String get feedbackIntro => '告诉我们哪里出了问题，或哪些地方可以改进。';

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
  String get feedbackAttachLogsHint => '有助于我们找到问题。你的助记词、PIN 码和其他机密信息会先被移除。';

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
  String get settingsAdvancedOptionsSubtitle => '网络、节点、epicbox 服务器、文件和日志';

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
  String get sendAddressNotEpic => '这不是 Epic 地址。';

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
}
