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
  String txSpokenLabelled(String label, String row) {
    return '$label，$row';
  }

  @override
  String get txLabel => '标签';

  @override
  String get txLabelAdd => '添加标签';

  @override
  String get txLabelEdit => '编辑标签';

  @override
  String get txLabelHint => '添加标签';

  @override
  String get txLabelAddedNotice => '标签已添加';

  @override
  String get txLabelSavedNotice => '标签已保存';

  @override
  String get txLabelRemovedNotice => '标签已移除';

  @override
  String get txEditAdd => '添加详情';

  @override
  String get txEditEdit => '编辑详情';

  @override
  String get txEditFrom => '来自';

  @override
  String get txEditFromHint => '地址';

  @override
  String get txEditFromHelper => '未验证。绝不用于付款证明。';

  @override
  String get txMethodUnknown => '未知';

  @override
  String get txManualTag => '由你添加';

  @override
  String txManualTip(String date) {
    return '你于 $date 添加。并非来自区块链。';
  }

  @override
  String get txManualTipNoDate => '由你添加。并非来自区块链。';

  @override
  String txManualTipFrom(String date) {
    return '你于 $date 添加。并非来自区块链，未验证。';
  }

  @override
  String get txManualTipFromNoDate => '由你添加。并非来自区块链，未验证。';

  @override
  String get txEditAddedNotice => '详情已添加';

  @override
  String get txEditSavedNotice => '详情已保存';

  @override
  String get txEditRemovedNotice => '详情已移除';

  @override
  String get histConflictTitle => '详情不一致';

  @override
  String histConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '备份中有 $n 笔你已描述的付款带有不同的详情。除非你另行选择，否则保留你的。',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => '我的';

  @override
  String get histConflictBackup => '备份';

  @override
  String get histConflictKeepAll => '全部保留我的';

  @override
  String get histConflictImport => '导入';

  @override
  String get histConflictEmpty => '空';

  @override
  String histImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已替换 $n 项详情，其余保留为你的内容。',
    );
    return '$_temp0';
  }

  @override
  String get txOutgoingPayment => '发出的付款';

  @override
  String get txIncomingPayment => '收到的付款';

  @override
  String get txStatusWaitingRecipient => '等待接收方';

  @override
  String get txStatusWaitingSender => '等待发送方';

  @override
  String get txStatusSenderPosted => '发送方称已广播';

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
  String get errorHistoryNotOurs => '此文件不是本应用导出的交易记录备份。';

  @override
  String get errorHistoryNewer => '此交易记录备份由更新版本的应用创建。';

  @override
  String get errorHistoryDamaged => '此交易记录备份已损坏。';

  @override
  String get errorHistoryOtherWallet => '此交易记录备份属于另一个钱包。';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return '此交易记录备份来自 $fileNetwork，但当前钱包位于 $walletNetwork。';
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
      other: '已等待 $days 天。Epicbox 会在 7 天后删除付款，因此这笔付款已无法完成。请取消它以解锁资金，然后重新发送。',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      '已发送到接收方的 Epicbox。对方钱包上线后即可完成。在此之前，或在你取消之前，你的资金将保持锁定。';

  @override
  String get txDetailsWaitingRecipient =>
      '正在等待接收方回复其交易文件。在此之前，或在你取消之前，你的资金将保持锁定。';

  @override
  String get txDetailsWaitingSender => '你已接受这笔付款。发送方完成并将其广播到网络后，付款即完成。';

  @override
  String get txDetailsSenderPosted => '发送方称已广播这笔付款。区块链确认后，付款即完成。';

  @override
  String get txDetailsPublished => '已广播到网络。正在等待第一个确认。';

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
  String get txDetailsCancelledByUser =>
      '已取消。没有支付任何资金，这些资金已恢复可用。如果接收方已经收到，其钱包可能仍显示为等待中；这笔付款已无法完成。';

  @override
  String get txDetailsCancelledReleased =>
      '网络始终未接受这笔付款，因此其资金已释放。再次发送前，请确认接收方没有收到。';

  @override
  String get txDetailsCancelledNotOnChain =>
      '这笔付款未能在 14 天内进入网络，因此钱包已将其取消。再次发送前，请确认接收方没有收到。';

  @override
  String get txDetailsCancelledUnanswered =>
      '接收方未在 14 天内回复，因此钱包已将其取消。没有支付任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledLateAnswer =>
      '接收方在 14 天期限过后才回复，因此钱包取消了这笔付款，而没有完成它。没有支付任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledUndelivered =>
      '这笔付款无法送达接收方，因此钱包已立即将其取消。没有发送任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledIncoming => '已取消。这笔付款不会到账。';

  @override
  String get txDetailsFromBackup =>
      '这笔付款来自交易记录备份，备份时尚未完成。此钱包自身没有它的记录，因此无法判断它是否已完成。没有锁定任何资金。';

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
  String get txDetailsSendAgain => '重新发送';

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
  String get txDetailsNoteHelper => '仅保存在此设备和你的交易记录备份中。';

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
      '通过扫描区块链找到。发送方和手续费等详情不会保存在链上；导入交易记录备份即可恢复。';

  @override
  String get txDetailsSourceImported => '从交易记录备份导入。此钱包自身没有它的记录，因此其状态可能已过时。';

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
  String get historyBackupOpenDialogTitle => '打开交易记录备份';

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
  String get historyBackupExportTitle => '导出交易记录备份';

  @override
  String get historyBackupExportNote => '交易记录备份包含截至目前的付款。有新付款后请重新导出。';

  @override
  String get historyBackupCsvTitle => '导出 CSV';

  @override
  String get historyBackupCsvWarning =>
      'CSV 文件未加密。任何拿到它的人都能看到你的金额、日期、地址和备注。它无法再导入；如需可导入的备份，请使用“导出交易记录备份”。';

  @override
  String get historyBackupCsvConfirm => '导出 CSV';

  @override
  String get historyBackupImportedTitle => '已导入交易记录备份';

  @override
  String historyBackupImportFailed(String reason) {
    return '未能导入交易记录备份。$reason';
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
  String get homeSendButton => '发送';

  @override
  String get shellWalletTab => '钱包';

  @override
  String get homeReceiveButton => '接收';

  @override
  String get homeScanTooltip => '扫描二维码发送';

  @override
  String get homeRecentActivity => '最近活动';

  @override
  String get homeSeeAll => '查看全部';

  @override
  String get homeBackedUpNotice => '助记词已备份';

  @override
  String get homeNoticeView => '查看';

  @override
  String get homePushNotice => '你的 Epicbox 中有一笔待接收的付款。应用连接后即可到账。';

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
  String get homeNoticeSenderPosted => '发送方称付款已广播。';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return '发送方称 $amount 已广播。';
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
  String get homeNoticeRelayProblem => 'Epicbox 服务器报告了问题，正在重试。';

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
      other: '有 $count 笔付款不在交易记录备份中。用助记词恢复钱包只能找回余额。',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '自上次交易记录备份以来，有 $count 笔付款为新增或有变动。用助记词恢复钱包只能找回余额。',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => '以后再说';

  @override
  String get homeHistoryExportButton => '导出交易记录备份';

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
  String get statusEpicboxOnline => 'Epicbox 已连接';

  @override
  String get statusEpicboxConnecting => '正在连接 Epicbox';

  @override
  String get statusEpicboxOffline => 'Epicbox 未连接';

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
  String get homeEpicboxOffline => '钱包未连接到其 Epicbox 服务器，正在继续尝试。';

  @override
  String get homeEpicboxConnecting => '正在连接 Epicbox…';

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
  String get invoicesEmpty => '没有等待中的请求。你允许的已配对联系人请求付款时，请求会显示在这里，在你批准之前不会付款。';

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
  String invoiceReviewAsks(String service) {
    return '$service 请你付款';
  }

  @override
  String invoiceReviewMessageLabel(String name) {
    return '$name 的留言';
  }

  @override
  String get invoiceReviewNote => '钱包会加上网络手续费。在你批准之前不会支付任何款项。';

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
    return '$service 会收到你拒绝的通知。不会支付任何款项。';
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
    return '你的付款尚未送达 $service';
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
    return '正在等待 $service 广播这笔付款。';
  }

  @override
  String invoiceDetailsRepliedHelp(String service) {
    return '如果 $service 尚未发布这笔付款，请再次发送：不会重复签名。如果一直没有发布，付款时限到期后（付款后约一天）即可取消。';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service 报告已广播这笔付款。网络确认后即完成。';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service 尚未收到你的付款。点“重试”会再次发送，无需再次批准。';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '你付款后，$service 撤回了此账单。如果这笔付款未能确认，请取消它以解锁资金。';
  }

  @override
  String get invoiceNoticeReceived => '有一张账单等待你批准。';

  @override
  String get invoiceNoticePosted => '某个服务报告已广播你的付款。';

  @override
  String get invoiceNoticeWithdrawnPaid => '某个服务撤回了一张你已支付的账单。';

  @override
  String get invoiceNoticeWithdrawn => '某个服务在你答复前撤回了一张账单。';

  @override
  String get invoiceNoticeExpired => '一张账单在你答复前已过期。';

  @override
  String get receiveRequestTitle => '请求付款';

  @override
  String get requestMessageLabel => '给付款方的留言（可选）';

  @override
  String get requestMessageHelper => '付款方会随请求看到这条留言。';

  @override
  String get requestButton => '请求';

  @override
  String get invoicesToPaySection => '待支付';

  @override
  String get invoicesNoneToPay => '没有待支付的账单。';

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
  String get issuedDetailsSection => '收款请求';

  @override
  String get issuedDetailsPayer => '请求对象';

  @override
  String get issuedDetailsWaiting => '正在等待付款方。付款到达后，你的钱包会完成它。';

  @override
  String get issuedDetailsPaid => '已支付。你的钱包已完成这笔付款；网络确认后即完成。';

  @override
  String get issuedDetailsDeclined => '付款方拒绝了这个请求，因此已撤回。没有支付任何款项。';

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
      '付款方的钱包无法支付请求，已将这个请求退回，因此已撤回。没有支付任何款项。请让对方改为直接向你的地址付款，或使用付款文件。';

  @override
  String get txStatusWaitingPayer => '等待付款方';

  @override
  String get txStepRequested => '已请求';

  @override
  String get txStepPaid => '已支付';

  @override
  String get txDetailsWaitingPayer => '你请求了这笔付款。目前还没有到账：付款方支付请求后款项才会到达。';

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
  String get receiveEpicboxConnected => 'Epicbox 已连接';

  @override
  String get receiveQrLabel => '你的地址二维码';

  @override
  String get receiveAddressLabel => 'Epicbox 地址';

  @override
  String get receiveEpicboxOfflineBody => '发给你的付款现在会在 Epicbox 等待，钱包重新连接后到账。';

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
  String get updateAllowInstalls => '允许来自 Epic Cash Mobile 的安装，然后返回。';

  @override
  String get updateInstallCancelled => '更新未安装。可以再试一次。';

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
  String get updateNoTorDownload => '暂时无法通过 Tor 下载此更新。请关闭 Tor 后下载，或从下载页面获取。';

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
  String get setupNetworkSettingsTooltip => '节点与 Epicbox';

  @override
  String get setupNetworkHeading => '网络';

  @override
  String get setupNodeUrlLabel => '节点地址';

  @override
  String get setupCustomRelayLabel => '其他 Epicbox 服务器（主机名或 host:port）';

  @override
  String get setupCustomRelayInvalid => '请输入主机名，例如 epicbox.example.com';

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
      '区块链上保存着你的余额，但不包含付款对象、手续费和备注。如果你曾从这个钱包导出交易记录备份，现在导入即可找回这些信息。它就是你分享或保存到旧手机以外的 .wfeh 文件。';

  @override
  String get restoreImportButton => '导入交易记录备份';

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
  String get backupCopyTitle => '复制助记词？';

  @override
  String get backupCopyBody => '任何拿到这些单词的人都能转走你的资金。请把复制的内容保存在安全的地方。';

  @override
  String get backupCopied => '已复制。剪贴板将在 60 秒后清空。';

  @override
  String get backupNotCopied => '未复制。剪贴板拒绝了该文本。';

  @override
  String get unlockTitle => '解锁钱包';

  @override
  String get pinlessUnlock => '解锁';

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
      '无法正常读取此钱包。没有删除任何内容。请重启设备后重试。如果问题仍然存在，可以通过“忘记 PIN 码？”移除钱包，再用助记词恢复。';

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
  String get sendUrlUnsupported => '不支持向钱包 URL 付款。请向接收方索取其 Epicbox 地址。';

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
  String get slateInvoiceUnsupported => '暂不支持账单。';

  @override
  String get slateNotTransactionFile => '该文件不是交易文件。';

  @override
  String get slateReading => '正在读取文件';

  @override
  String get slateReadingQr => '正在读取付款';

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
    return '你之前已接受这笔付款，因此这是相同的回复，而不是第二笔付款。发送方完成付款并上链后，这笔 $amount 即会到账。';
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
  String get qrShowReplyAsQr => '将回复显示为二维码';

  @override
  String get qrShowTitlePayment => '付款二维码';

  @override
  String get qrShowTitleReply => '回复二维码';

  @override
  String qrShowSubPayment(String amount) {
    return '$amount，给你身边的手机';
  }

  @override
  String qrShowSubReply(String amount) {
    return '发给 $amount 的发送方';
  }

  @override
  String get qrHiddenTitle => '点击后才会显示';

  @override
  String get qrHiddenBodyPayment => '谁先扫到，谁就能接受这笔付款。只给你要付款的那个人看。';

  @override
  String get qrHiddenBodyReply => '只给发送方的手机看。只有对方的钱包能使用它。';

  @override
  String get qrShow => '显示二维码';

  @override
  String get qrShowAgain => '再次显示';

  @override
  String get qrHide => '隐藏';

  @override
  String qrCountdownLabel(int seconds) {
    return '$seconds 秒后显示';
  }

  @override
  String qrPartOf(int part, int count) {
    return '第 $part 段，共 $count 段';
  }

  @override
  String qrSecondsShort(int seconds) {
    return '$seconds 秒';
  }

  @override
  String qrSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '还剩 $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String get qrHoldHint => '请把另一部手机的摄像头对准这个码。';

  @override
  String get qrSecureLine => '此屏幕已禁止截屏';

  @override
  String qrTimedOutTitle(int seconds) {
    return '$seconds 秒后已隐藏';
  }

  @override
  String get qrTimedOutBody => '另一部手机准备好后再显示。';

  @override
  String qrTimedOutAnnounce(int seconds) {
    return '$seconds 秒后已隐藏';
  }

  @override
  String get qrAwayTitle => '应用离开期间已隐藏';

  @override
  String get qrAwayBody => '应用离开屏幕时，二维码会自动隐藏。';

  @override
  String qrSemanticsPayment(String state) {
    return '付款二维码，$state';
  }

  @override
  String qrSemanticsReply(String state) {
    return '回复二维码，$state';
  }

  @override
  String get qrStateHidden => '已隐藏';

  @override
  String get qrStateShowing => '显示中';

  @override
  String get qrScanPayment => '扫描付款二维码';

  @override
  String get qrScanReply => '扫描对方的回复';

  @override
  String get qrScanAimPayment => '请把摄像头对准对方手机上的二维码。';

  @override
  String get qrScanAimReply => '请把摄像头对准对方手机上的回复。';

  @override
  String get qrScanSteady => '请拿稳，或靠近一点。';

  @override
  String get qrScanGot => '已读取';

  @override
  String qrScanCount(int got, int count) {
    return '$got / $count';
  }

  @override
  String get qrScanCountLabel => '已读取的段数';

  @override
  String get qrScanNotPayment => '这不是付款二维码。请让对方在手机上显示付款二维码。';

  @override
  String get qrScanNotReply => '这不是回复二维码。请让对方在手机上显示回复。';

  @override
  String get qrScanOtherPayment => '这个码属于另一笔付款。正在重新开始。';

  @override
  String get qrScanTorch => '手电筒';

  @override
  String qrScanZoom(String factor) {
    return '缩放 $factor×';
  }

  @override
  String get qrScanCameraDenied =>
      '钱包无权使用摄像头。如需扫码，请在手机设置中允许此应用访问摄像头。你也可以改为打开文件。';

  @override
  String get qrScanCameraFailed => '摄像头无法启动。请重试，或改为打开文件。';

  @override
  String get qrScanOpenSettings => '打开设置';

  @override
  String get qrScanOpenFileInstead => '改为打开文件';

  @override
  String get qrScanAgain => '再次扫描';

  @override
  String get slateWrongPaymentQr => '此回复属于另一笔付款。请扫描这笔付款的回复。';

  @override
  String get slateScannedPaymentTitle => '已扫描的付款';

  @override
  String get slateScannedReplyTitle => '已扫描的回复';

  @override
  String get slateIncomingSendHintQr => '接受付款，然后把回复展示给发送方。';

  @override
  String get slateAcceptedHeadlineQr => '已接受。请把回复展示给发送方。';

  @override
  String get methodQr => '二维码付款';

  @override
  String get methodQrChip => '二维码';

  @override
  String get receiveTabQr => '二维码';

  @override
  String get methodArtCaptionQr => '当面';

  @override
  String get methodArtLabelQr => '直接 · 二维码付款：一部手机上的码被身边的另一部手机扫描';

  @override
  String get methodSendQrTitle => '给你身边的手机。';

  @override
  String get methodSendQrLine => '在这块屏幕上显示二维码，再用摄像头扫描对方的回复。';

  @override
  String get methodReceiveQrTitle => '扫描对方的屏幕。';

  @override
  String get methodReceiveQrLine => '接受付款，再用同样的方式显示你的回复。';

  @override
  String get receiveQrTitle => '就在发送方身边？';

  @override
  String get receiveQrBody => '扫描发送方手机上的二维码，接受付款，再显示你的回复。';

  @override
  String get txQrLine => '面对面付款或收款，用屏幕上的二维码。';

  @override
  String get txQrHint =>
      '二维码付款会把付款显示成动态码，由另一部手机用摄像头扫描，回复也用同样方式接收。它只适用于并排的两部手机，两个钱包之间无需连接，二维码会在 40 秒后自动隐藏。会在发送和接收中加入二维码付款。';

  @override
  String get advTransactionFiles => '文件传输';

  @override
  String get advTransactionFilesHint => '在设置 › 交易中加入“文件传输”：用你自己传递的文件付款或收款。';

  @override
  String get sendQrTitle => '二维码付款';

  @override
  String get sendMakeQr => '生成付款二维码';

  @override
  String sendQrPinReason(String amount) {
    return '输入 PIN，以生成 $amount 的付款二维码。';
  }

  @override
  String get sendQrMade => '付款已生成';

  @override
  String get sendQrHint => '把二维码给接收方的手机看，然后扫描对方的回复。';

  @override
  String get sendCancelRuleQr => '在你扫描对方回复之前都可以取消。';

  @override
  String get qrStatusSendHidden => '把它给接收方看。';

  @override
  String get qrStatusSendShowing => '等待接收方扫描。然后扫描对方的回复。';

  @override
  String get qrStatusHiddenAgain => '已隐藏。如果对方没扫完，请再次显示。';

  @override
  String get qrStatusReplyHidden => '把它给发送方看。';

  @override
  String get qrStatusReplyShowing => '等待发送方扫描。';

  @override
  String get qrStatusReceivedWaiting => '已收到付款。等待发送方扫描并发布。';

  @override
  String qrStatusPosted(int got, int target) {
    return '已发布。确认中 $got/$target';
  }

  @override
  String get qrStatusReceived => '已收到。';

  @override
  String qrScanProgress(int got, int count) {
    return '已扫描 $got / $count。请让二维码保持在取景框内。';
  }

  @override
  String get qrScanReplyScanned => '已扫描回复。';

  @override
  String get qrScanPosting => '已扫描回复。正在发布…';

  @override
  String get qrScanPosted => '已发布。';

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
  String get contactsAddressInvalidAny =>
      '地址无效。请使用 Epicbox 地址（es5x…@epicbox.epiccash.com）、链接地址（https://…）或 onion 地址（….onion）。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionNetwork => '服务器';

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
  String get settingsExportHistory => '导出交易记录备份';

  @override
  String get settingsExportCsv => '导出 CSV';

  @override
  String get settingsImportHistory => '导入交易记录备份';

  @override
  String get settingsSectionWallet => '钱包';

  @override
  String get settingsContacts => '联系人';

  @override
  String get settingsSectionInvoices => '账单';

  @override
  String get settingsInvoices => '账单';

  @override
  String get settingsInvoicesSubtitle => '谁可以请求你付款';

  @override
  String get settingsRescan => '重新核对余额';

  @override
  String get settingsRescanFinished => '重新扫描已完成';

  @override
  String get settingsRescanTitle => '重新核对余额';

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
  String get settingsCheckUpdates => '检查更新';

  @override
  String get settingsHelp => '帮助';

  @override
  String get settingsSendFeedback => '发送反馈';

  @override
  String get settingsSendFeedbackHint =>
      '向开发者报告问题或提出建议。只有你选择附上时才会发送日志，且会先移除助记词、PIN 码和其他机密信息。';

  @override
  String get settingsSourceCode => '源代码';

  @override
  String get settingsLicences => '许可证';

  @override
  String get licencesLead => '本钱包包含的开源软件。每个组件保留各自的许可证；点按即可查看完整文本。';

  @override
  String get licencesApp => 'Epic Cash Mobile，BT Labs 出品：Apache-2.0。';

  @override
  String get licencesFlutter => 'Flutter 及其 Dart 软件包：BSD 3-Clause 及类似的宽松许可证。';

  @override
  String get licencesLepic =>
      'LEPIC，Epic Cash 钱包库：Apache 2.0，包含 Epic Cash 的 secp256k1-zkp 分支（CC0）以及 MIT 或 Apache 2.0 许可的 Rust crate，其中有 tokio、rustls、rusqlite 和 blake2。';

  @override
  String get licencesTor => 'Tor：GNU 通用公共许可证第 3 版。其源代码见下文。';

  @override
  String get licencesFonts =>
      '字体 Montserrat、JetBrains Mono 和 Noto Sans Thai：SIL 开放字体许可证 1.1。';

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
  String get settingsAdvancedOptionsSubtitle =>
      '显示技术细节：节点和 Epicbox 服务器的详情、区块高度、交易文件和日志。关闭后，应用只保留日常使用所需。';

  @override
  String get settingsSectionPrivacy => '隐私';

  @override
  String get settingsSectionPrivacyNetwork => '隐私与网络';

  @override
  String get settingsSectionHelpFeedback => '帮助与反馈';

  @override
  String get settingsStateBackUp => '备份助记词';

  @override
  String get settingsStateNotBackedUp => '尚未备份';

  @override
  String get settingsHubBackup => '备份';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => '使用 status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      '从 BT Labs 的监测站 status.btlabs.uk 读取哪些节点和 Epicbox 服务器在线、它们的区块高度和响应时间，并显示在服务器列表和状态卡上。关闭后不再询问 status.btlabs.uk，服务器列表也不显示状态。';

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
  String get demoPinFilled => '演示 PIN 码已为你填好';

  @override
  String get demoPinSkip => '跳过';

  @override
  String get demoPinSetUpTitle => '正在设置你的演示钱包';

  @override
  String get demoPinUnlockTitle => '正在打开你的演示钱包';

  @override
  String get sendStepMethod => '付款方式';

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
  String sendRelayDown(String relay) {
    return '对方的中继（$relay）没有响应。';
  }

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
    return '对方钱包打开后会完成付款。在此之前 $amount 处于锁定状态。';
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
    return '$amount 已锁定';
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
  String get handshakePay1 => '你的钱包把付款发到中继。你的币被锁定。';

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
  String get handshakeFile => '文件传输';

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
  String get handshakeLink1 => '你的钱包通过互联网或 Tor 把付款直接发到对方的钱包。你的币被锁定。';

  @override
  String get handshakeLink2 => '对方钱包加入自己的部分、签名，并在同一连接上回复。';

  @override
  String get handshakeQr1 => '你显示你的二维码。';

  @override
  String get handshakeQr2 => '对方用钱包扫描它。';

  @override
  String get handshakeQr3 => '对方的钱包显示回复二维码。';

  @override
  String get handshakeQr4 => '你扫描它。';

  @override
  String get handshakeQr5 => '你的钱包把付款发送到网络。';

  @override
  String get handshakeQrR1 => '对方显示他们的二维码。';

  @override
  String get handshakeQrR2 => '你用钱包扫描它。';

  @override
  String get handshakeQrR3 => '你的钱包显示回复二维码。';

  @override
  String get handshakeQrR4 => '对方扫描它。';

  @override
  String get handshakeQrR5 => '对方的钱包把付款发送到网络。';

  @override
  String get handshakeNext => '下一步';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '对方的中继（$relay）没有接收。在你取消之前，这笔金额处于锁定状态，最长 $days 天。',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return '对方的中继（$relay）没有接收。再次发送前请先查看钱包。';
  }

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
    return '$amount 锁定中';
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
  String get receiveTorAddressLabel => '链接 · Tor 地址';

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
      other: '未能通过 Tor 联系到对方钱包。在你取消之前，这笔金额处于锁定状态，最长 $days 天。',
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
  String get tourPhoneSemantics => '钱包导览';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get tourPhoneSkip => '跳过';

  @override
  String get tourPhoneBack => '上一步';

  @override
  String get tourPhoneNext => '下一步';

  @override
  String get tourPhoneWalletTitle => '钱包';

  @override
  String get tourPhoneWalletText =>
      '你的余额，下面是节点、Epicbox 和 Tor 的图标。仍在确认中的金额在下方的卡片里。';

  @override
  String get tourPhoneSendTitle => '发送';

  @override
  String get tourPhoneSendText =>
      '粘贴或扫描地址，或选择联系人。Epicbox 向地址付款；二维码把码显示给身边的手机。更多方式：设置 › 交易。发出前会先确认。';

  @override
  String get tourPhoneReceiveTitle => '接收';

  @override
  String get tourPhoneReceiveText =>
      '你的 Epicbox 地址。分享它即可收款。“文件”标签页用于需要签名或完成的交易文件。';

  @override
  String get tourPhoneActivityTitle => '活动';

  @override
  String get tourPhoneActivityText => '每笔付款的进度和详情。点一笔即可打开。';

  @override
  String get tourPhoneContactsTitle => '联系人';

  @override
  String get tourPhoneContactsText => '按名称保存的地址。“发送”从这里选择。';

  @override
  String get tourPhoneInvoicesTitle => '账单';

  @override
  String get tourPhoneInvoicesText => '支付别人发来的账单，或向别人请求付款。用标签页在两者之间切换。';

  @override
  String get tourPhonePrivacyTitle => '隐私与网络';

  @override
  String get tourPhonePrivacyText =>
      '钱包使用哪个节点和 Epicbox 服务器，以及 Tor 开关。点一个服务器即可更改。';

  @override
  String get tourPhoneAdvancedTitle => '高级';

  @override
  String get tourPhoneAdvancedText => '仅 Tor 模式、输出和技术详情都在这里。需要什么就开启什么。';

  @override
  String get tourPhoneHelpTitle => '帮助';

  @override
  String get tourPhoneHelpText => '搜索主题或发送反馈。“再次查看导览”在列表底部。';

  @override
  String get tourPhoneShowAgain => '再次查看导览';

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
    return '输入 PIN 码以发送 $amount。';
  }

  @override
  String sendFilePinReason(String amount) {
    return '输入 PIN 码以生成 $amount 的付款文件。';
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
  String get outputsStrategyHint =>
      '一笔发送花掉哪些输出。“最小”只花最少的小额输出，找零确认期间其余余额仍可使用。“全部”花掉所有可用输出并返回一个找零输出：确认前全部锁定，之后输出更少、更大。';

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
  String get outputsSplitChangeText =>
      '当一笔发送会使可用输出少于 3 个且找零至少为 1 EPIC 时，找零会以最多 4 个输出返回，这样接下来的发送不必等待确认。每多一个输出花费 0.004 EPIC。';

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
    return '需要 $need 个确认后才能花费。';
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
  String get outputsFactCommitment => '承诺';

  @override
  String get outputsCopy => '复制';

  @override
  String get outputsCopied => '承诺已复制';

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
    return '花掉 $spent（$amount），生成 $made，每个约 $each。这是发往本钱包的普通网络交易，与任何发送一样在 3 个区块后确认；在此之前所有可用余额都被锁定。输出多了，接下来的几笔发送就不必互相等待找零。';
  }

  @override
  String get outputsToMake => '生成数量';

  @override
  String get outputsStepperHint => '2 到 10';

  @override
  String get outputsFactFee => '网络手续费';

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
  String get outputsSplitPin => '输入 PIN 码以确认拆分输出';

  @override
  String get outputsConsolidatePin => '输入 PIN 码以确认合并输出';

  @override
  String outputsSplitStarted(int count) {
    return '拆分已开始：$count 个输出，约 3 个区块后确认';
  }

  @override
  String get outputsConsolidateStarted => '合并已开始：一个输出，约 3 个区块后确认';

  @override
  String get outputsAdvanced => '管理输出';

  @override
  String get outputsColState => '状态';

  @override
  String get outputsColValue => '金额';

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
  String get contactsNoteHeading => '备注';

  @override
  String get contactsShowCode => '显示二维码';

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
  String invoicesRequestSummary(String payer, String amount) {
    return '将请求 $payer 支付 $amount。请求在 24 小时后到期。';
  }

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
    return '同步中 $percent%';
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
  String get netStatusConnected => '已连接';

  @override
  String get netStatusNotConnected => '未连接';

  @override
  String get serverUpNotConnected => '服务器正常 · 未连接';

  @override
  String get netStatusOn => '开启';

  @override
  String get netStatusFailed => '失败';

  @override
  String netStatusStarting(int percent) {
    return '启动中 $percent%';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => '网络状态';

  @override
  String get serverMyRelays => '我的服务器';

  @override
  String get serverMenuDelete => '删除';

  @override
  String get serverSupportsNotifications => '支持通知';

  @override
  String get netStatusReachable => '可访问';

  @override
  String get netStatusPublishing => '正在发布…';

  @override
  String get netStatusNotReachable => '不可访问';

  @override
  String get netStatusTorOpenHint => '打开隐私设置';

  @override
  String get netStatusDirectOpenHint => '打开链接接收地址';

  @override
  String get netStatusOpenHint => '显示服务器';

  @override
  String get serverNodeTitle => '节点';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => '查找节点';

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
  String get serverAtTip => '已是最新';

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
    return '$percent% 在线';
  }

  @override
  String get serverRelayWarning => '你的地址包含此服务器。切换会更改你的地址；发送方需要新地址。';

  @override
  String get serverOtherRelay => '其他服务器，host 或 host:port';

  @override
  String get serverMyListNote => '正在使用的和你添加的。';

  @override
  String get serverPublicNote => '点按即可切换。';

  @override
  String get serverOtherNode => '其他节点，host 或 host:port';

  @override
  String get serverOtherNodeInvalid => '请输入节点地址，例如 node.example.com:3413';

  @override
  String get serverAdd => '添加';

  @override
  String get serverAddedNode => '已添加到“我的节点”。';

  @override
  String get serverAddedRelay => '已添加到“我的服务器”。';

  @override
  String serverDeleted(String host) {
    return '已删除 $host。';
  }

  @override
  String get serverAlreadyInUse => '已在使用。';

  @override
  String get serverNoMatch => '无匹配结果。';

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
    return '$height · 已是最新';
  }

  @override
  String serverNodesAgree(String height) {
    return '各节点一致：$height';
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
  String get methodDirectHttp => '链接 · HTTP';

  @override
  String get methodDirectTor => '链接 · Tor';

  @override
  String get methodFile => '文件传输';

  @override
  String get methodShortHttp => '链接 · HTTP';

  @override
  String get methodShortTor => '链接 · Tor';

  @override
  String get methodShortQr => '直接 · QR';

  @override
  String get methodShortFile => '直接 · 文件';

  @override
  String get methodGroupHttp => 'HTTP';

  @override
  String get methodGroupTor => 'Tor';

  @override
  String get methodDirectQr => '直接 · 二维码付款';

  @override
  String get methodDirectFile => '直接 · 文件传输';

  @override
  String get methodDirectFamily => '直接';

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
  String get methodArtLabelHttp => '链接 · HTTP：付款直接发送到对方钱包，对方钱包必须处于打开状态';

  @override
  String get methodArtLabelTor => '链接 · Tor：付款经由 Tor 网络直接发送到对方钱包';

  @override
  String get methodArtLabelFile => '直接 · 文件传输：交出交易文件，收回回复文件，然后由发送方完成';

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
  String get sendSwitchedHttp => '链接 · HTTP';

  @override
  String get sendSwitchedEpicbox => '经由 Epicbox';

  @override
  String get sendSwitchedTorAnnounce => 'Tor 地址。方式已设为 链接 · Tor。';

  @override
  String get sendSwitchedHttpAnnounce => 'HTTP 地址。方式已设为 链接 · HTTP。';

  @override
  String get sendSwitchedEpicboxAnnounce => 'Epicbox 地址。方式已设为 Epicbox。';

  @override
  String get sendReviewMethodHttp => '链接 · HTTP，直达对方钱包';

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
      other: '未能联系到对方钱包。在你取消之前，这笔金额处于锁定状态，最长 $days 天。',
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
  String get deskInvReqPosted => '已广播';

  @override
  String deskInvConfirming(int count, int total) {
    return '确认中 $count/$total';
  }

  @override
  String get deskInvCompleted => '已完成';

  @override
  String get deskInvReqNotPosted => '未广播';

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
  String get deskInvPayDelivered => '等待广播';

  @override
  String get deskInvPayPosted => '已由服务广播';

  @override
  String get deskInvPayWithdrawnAfterPay => '付款后已撤回';

  @override
  String get deskInvPayPastTtl => '不在链上';

  @override
  String get deskInvPayCancelled => '已取消';

  @override
  String get deskInvUnpaid => '未支付';

  @override
  String get deskInvYouPay => '你支付';

  @override
  String deskInvExpiresAt(String time) {
    return '$time 过期';
  }

  @override
  String get deskInvSlateId => 'Slate ID';

  @override
  String get deskInvAdvanced => '高级';

  @override
  String get deskInvFailed => '操作未成功。没有任何更改；请重试。';

  @override
  String get deskInvHowItWorks => '账单如何运作';

  @override
  String get deskInvIssuerSoon => '即将推出';

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
  String get deskInvIssuerAmountHelp => '你的钱包不会支出任何资金：付款方支付此金额外加其自己的手续费。';

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
  String get deskInvIssuerRelayDown => 'Epicbox 服务器无响应，暂时无法发出账单。';

  @override
  String get deskInvIssuerNotDelivered => '账单未到达 Epicbox 服务器。未发送任何内容。请重试。';

  @override
  String get deskInvIssuerEmpty => '还没有开具账单。账单会让联系人或服务向你付款；它不花费任何资金。';

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
  String get deskInvIssuerRepost => '重新广播';

  @override
  String get deskInvIssuerReposted => '付款已重新广播。';

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
    return '$payer 的钱包退回了账单：它无法支付账单。请改为让对方直接付款给你。';
  }

  @override
  String get deskInvIssuerSendFile => '改用文件';

  @override
  String get deskInvIssuerLate => '此账单结束后收到一笔付款。已被拒绝；没有任何变化。';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer 已付款。你的钱包已完成并广播该付款。';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return '已送达 $payer 的信箱。在对方批准之前不会付款。';
  }

  @override
  String get deskInvIssuerCopySlate => '复制 Slate ID';

  @override
  String get deskInvIssuerStepIssued => '已开具';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return '$payer 已支付 $amount EPIC。';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return '$payer 拒绝了你的账单。';
  }

  @override
  String get deskInvNoticeIssuedExpired => '你开具的一张账单已过期未付。';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return '$service 在你回复前撤回了一张账单。';
  }

  @override
  String get deskInvNoticeExpired => '一张账单在你回复前已过期。';

  @override
  String get deskInvNoticeUnknownPayment =>
      '收到了一笔本设备未开具的账单的付款。它会在中继上为您使用此钱包的另一台设备保留一天：请在那台设备上打开钱包完成它。';

  @override
  String get deskInvNoticeUnknownAnswer =>
      '收到了对一笔本设备未发送的付款的回复。它会在中继上为您使用此钱包的另一台设备保留一天：请在那台设备上打开钱包完成它。';

  @override
  String get deskInvPayerWaitingHead => '等待你处理';

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
  String get deskInvPayerEmptyTitle => '没有等待中的账单';

  @override
  String get deskInvPayerEmptyText => '你允许的已配对联系人请求付款时，请求会显示在这里，在你批准之前不会付款。';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return '你给 $service 的付款未送达';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      '付款已签名并保存在此设备上；资金保持锁定。重试会再次发送，无需再次批准。';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service 撤回了一张你已支付的账单';
  }

  @override
  String get deskInvPayerWithdrawnText => '这笔付款可能永远不会上链。取消它以解锁你的资金。';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return '你给 $service 的付款不在链上';
  }

  @override
  String get deskInvPayerPastTtlText => '其期限已过，网络未见到它。取消它以解锁你的资金。';

  @override
  String get deskInvPayerCancelPayment => '取消付款';

  @override
  String get deskInvPayerSafetyTitle => '只支付你预期的账单';

  @override
  String get deskInvPayerSafetyText => '账单永远不会给你的钱包增加资金。批准它就是向外付款。';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return '你在 $ago 前已向 $service 支付过相同金额';
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
  String deskInvPayerMessageCaption(String name) {
    return '由 $name 填写。你的钱包不会核实。';
  }

  @override
  String get deskInvPayerPaysTo => '付款给';

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
    return '你需要 $total EPIC 可用资金；你有 $spendable EPIC。确认中的资金在 3 个确认后计入。';
  }

  @override
  String get deskInvPayerNodeDownTitle => '节点无响应';

  @override
  String get deskInvPayerNodeDownText =>
      '钱包无法检查你的资金，因此无法付款。节点恢复响应后即可再次批准；你可以在“设置 › 节点”中选择其他节点。';

  @override
  String get deskInvPayerPaid => '此账单已支付。不能再为其付款。';

  @override
  String get deskInvPayerDeclinedText => '你已拒绝此账单。未支付任何款项。';

  @override
  String get deskInvPayerBack => '返回账单';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return '向 $service 支付 $amount EPIC + $fee 手续费？';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC 将离开你的钱包。输入钱包密码以批准。';
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
      'Epicbox 服务器无响应。请在“账单 › 支付”中重试；无需再次批准。';

  @override
  String get deskInvPayerRetryFailed => '仍未送达';

  @override
  String get deskInvPayerRetryFailedText => 'Epicbox 服务器无响应。付款仍以签名状态保存在此设备上。';

  @override
  String get deskInvPayerCancelTitle => '取消此付款？';

  @override
  String get deskInvPayerCancelText =>
      '取消会在此处解锁你的资金。服务仍持有你签名的付款，因此在这些资金再次花出之前，它仍可能完成。';

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
  String get deskInvPayerCancelledText => '你的资金已解锁。';

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
  String get deskInvPayerLocked => '此账单无法支付：它被锁定到较晚的区块。未支付任何款项。';

  @override
  String get deskInvPayerRelayDownPay => 'Epicbox 服务器没有响应。未支付任何款项。';

  @override
  String get deskInvSetTitle => '账单';

  @override
  String get deskInvSetExpiry => '付款期限';

  @override
  String get deskInvSetExpiryHint => '你开具的账单可支付多久，以及收到的账单等待你多久。最长 48 小时。';

  @override
  String deskInvSetHours(int hours) {
    return '$hours 小时';
  }

  @override
  String get deskInvSetReceiveHint => '请已配对的联系人付款，或将请求保存为文件。';

  @override
  String get serverSwitchRelayTitle => '更换 Epicbox 服务器？';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'Epicbox 地址将变为 …@$relay。发送方需要新地址。发送到旧地址的付款会留在旧服务器上。';
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
  String get helpLanguageLabel => '帮助语言';

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
  String get methodDirect => '链接';

  @override
  String get methodLinkPayment => '链接付款';

  @override
  String get methodDirectShape => 'http://host:3415 或 xxxx….onion';

  @override
  String get methodSendDirectLine => '对方钱包必须处于打开状态。onion 地址经由 Tor。';

  @override
  String get methodArtLabelDirect => '链接：付款直接发送到收款人的钱包，该钱包必须处于打开状态';

  @override
  String methodArtSpokenLink(String method) {
    return '$method：付款直接发送到收款人的钱包，该钱包必须处于打开状态';
  }

  @override
  String methodArtSpokenQr(String method) {
    return '$method：一部手机上的码被身边的另一部手机扫描';
  }

  @override
  String methodArtSpokenFile(String method) {
    return '$method：交出交易文件，收回回复文件，然后由发送方完成';
  }

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
  String get sendSwitchedDirect => '链接地址';

  @override
  String get sendSwitchedDirectAnnounce => '链接地址。方式已设为链接。';

  @override
  String get sendDirectAddressShape =>
      '链接地址以 http:// 或 https:// 开头，或以 .onion 结尾。';

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
      '网络活动经由 Tor 网络。Tor 隐藏钱包的互联网地址：每个连接都经过多个志愿者运营的中继，因此没有服务器能得知钱包所在。通知在 Tor 开启时关闭。通过 Tor 地址收款由“交易”中的 链接 · Tor 开关控制。';

  @override
  String get receiveTabDirect => '链接';

  @override
  String get receiveDirectNeedsTor => '链接 · Tor 收款需要 Tor。';

  @override
  String get receiveDirectMeanwhile => '在此期间，发送方使用 Epicbox 地址。';

  @override
  String get receiveHttpTitle => '链接 · HTTP 地址';

  @override
  String get receiveHttpLanLine => '供此 Wi-Fi 网络中的钱包使用，本钱包保持打开时有效。';

  @override
  String get receiveHttpNoNetwork => '未连接 Wi-Fi 网络，没有可提供的地址。';

  @override
  String get receiveHttpOffWhileTor => 'Tor 开启时关闭。';

  @override
  String receiveHttpPortInUse(String port) {
    return '端口 $port 已被其他程序占用。';
  }

  @override
  String get receiveHttpFailed => '无法启动。';

  @override
  String get receiveHttpShowQr => '显示二维码';

  @override
  String get receiveHttpHideQr => '隐藏二维码';

  @override
  String get receiveHttpQrLabel => '链接 · HTTP 地址二维码';

  @override
  String get netStatusOverTor => '经由 Tor';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsNotificationsHint =>
      '在应用关闭时，有付款或账单到达会通知你。使用 BT Labs 的 Epicbox 和 Google 的通知服务；消息只用来唤醒应用，不含金额、发送方或地址。Tor 开启时关闭，因为注册会暴露手机的地址。';

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
  String get pushNoticeAvailable => '通知可在设置 › 高级中开启。';

  @override
  String get torWayOver => '经由 Tor';

  @override
  String get torWayWaiting => '正在等待 Tor';

  @override
  String get torWayNotConnected => 'Tor 未连接。';

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '使用全部 $count 个输出 · 找零 1 个输出',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSomethingWrong => '出了点问题';

  @override
  String get deskErrWrongPassword => '密码错误';

  @override
  String get deskErrPhraseInvalid => '助记词无效';

  @override
  String get deskErrWalletExists => '钱包已存在';

  @override
  String get deskErrWalletNotFound => '未找到钱包';

  @override
  String get deskErrNodeNotAnswering => '节点无响应';

  @override
  String get deskErrNotEnoughFunds => '余额不足';

  @override
  String get deskErrNotTxFile => '不是本钱包的交易文件';

  @override
  String get deskErrEpicboxUnreachable => '无法连接 Epicbox 服务器';

  @override
  String get deskErrNotHttpAddress => '不是 http(s) 地址';

  @override
  String get deskErrPlainHttp => '未确认使用明文 HTTP';

  @override
  String get deskErrNotOnion => '不是 onion 地址';

  @override
  String get deskErrTorNotConnected => 'Tor 未连接';

  @override
  String get deskErrOnionUnreachable => '无法经由 Tor 连接接收方的钱包';

  @override
  String get deskErrWalletBusy => '钱包正忙。请稍后重试。';

  @override
  String get deskErrDbDamaged => '钱包数据库已损坏，正在重建';

  @override
  String get deskErrPaymentExpired => '付款已过期';

  @override
  String get deskErrInvoiceNotFound => '未找到账单';

  @override
  String get deskErrAmountMismatch => '金额与账单不符';

  @override
  String get deskErrInvoicePaid => '账单已支付';

  @override
  String get deskErrInvoiceLocked => '账单锁定到之后的某个区块';

  @override
  String get deskErrInvoiceChanged => '账单已变更';

  @override
  String get deskErrNotAccepted => '未被接受';

  @override
  String deskErrNotAcceptedDetail(String detail) {
    return '未被接受：$detail';
  }

  @override
  String get deskErrDisk => '磁盘错误';

  @override
  String deskErrDiskDetail(String detail) {
    return '磁盘错误：$detail';
  }

  @override
  String get deskErrTorMissing => '此版本不含 Tor';

  @override
  String get deskErrTorNetwork => '无法连接 Tor 网络';

  @override
  String get deskErrTorClock => '电脑的时钟不正确';

  @override
  String get deskErrOnionNotPublished => 'onion 地址尚未发布';

  @override
  String get deskErrTorStart => 'Tor 未能启动';

  @override
  String get deskErrTorStopped => 'Tor 已停止';

  @override
  String get deskErrScanRunning => '已有一个扫描正在运行。';

  @override
  String get deskErrCancelRefused => '未取消：节点已收到这笔付款。';

  @override
  String get deskErrWalletLocked => '钱包已锁定';

  @override
  String get deskErrWalletLocking => '钱包正在锁定';

  @override
  String deskErrDbDamagedDetail(String detail) {
    return '钱包数据库已损坏。$detail';
  }

  @override
  String deskErrWalletClosed(String detail) {
    return '钱包已关闭：$detail。请重新解锁。';
  }

  @override
  String deskErrNotChanged(String detail) {
    return '未更改：$detail';
  }

  @override
  String deskErrPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请至少使用 $count 个字符',
    );
    return '$_temp0';
  }

  @override
  String get deskErrWalletNotListed => '钱包不在列表中';

  @override
  String get deskErrUpdateApp => '请更新应用后再更改列表';

  @override
  String get deskErrListNotChanged => '钱包列表未更改';

  @override
  String get deskErrOpenToDelete => '请先打开钱包再删除';

  @override
  String get deskErrEnterPassword => '请输入密码';

  @override
  String get deskErrFolderNotFound => '未找到钱包文件夹';

  @override
  String deskErrAlreadyHere(String name) {
    return '此钱包已在列表中：$name';
  }

  @override
  String get deskErrTestNet => '测试网络钱包。只能导入主网钱包。';

  @override
  String get deskErrWalletInApp => '此钱包已在应用中。';

  @override
  String get deskErrWalletNotFoundSearch => '未找到钱包。请重新搜索。';

  @override
  String get deskErrEnterOldPassword => '请输入旧密码';

  @override
  String deskErrOldPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '旧密码太短。请设置一个至少 $count 个字符的新密码。',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSeedUnreadable => '无法读取 wallet.seed 文件';

  @override
  String get deskErrNotSeedFile => '不是 wallet.seed 文件';

  @override
  String deskErrAlreadyInApp(String name) {
    return '已在应用中，名称为 $name';
  }

  @override
  String get deskErrWrongOldPassword => '旧密码错误';

  @override
  String get deskErrListNotSaved => '钱包列表未保存';

  @override
  String get deskErrProofSeedRead => '已读取种子';

  @override
  String get deskErrProofWalletCreated => '已创建钱包';

  @override
  String deskErrProofContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $count 个联系人',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofNode(String name) {
    return '已将节点 $name 添加到节点列表';
  }

  @override
  String deskErrProofEpicbox(String old, String current) {
    return '旧应用使用的 Epicbox 服务器是 $old；本应用使用 $current';
  }

  @override
  String get deskErrProofFolderUnchanged => '旧文件夹未改动';

  @override
  String get deskErrProofFolderChanged => '旧文件夹已被其他程序改动';

  @override
  String deskErrProofHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '交易记录：$count 笔交易',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofHistoryAlready => '交易记录已导入';

  @override
  String get deskErrProofHistoryNone => '旧文件夹中没有交易记录；扫描会恢复余额';

  @override
  String get deskErrProofHistoryOld =>
      '无法读取 Epic Wallet 5.3 及更早版本的交易记录；扫描会恢复余额';

  @override
  String get deskErrProofHistoryBusy => '交易记录未导入：旧钱包正在运行。下次解锁时会导入';

  @override
  String get deskErrProofHistoryOther => '交易记录未导入：它属于另一个钱包';

  @override
  String get deskErrProofHistoryUnreadable => '交易记录未导入：无法读取旧数据库；扫描会恢复余额';

  @override
  String get deskErrNodeNoAnswer => '节点没有响应';

  @override
  String get deskErrNotPosted => '未广播';

  @override
  String get deskErrNotEpicboxAddress => '不是 Epicbox 地址';

  @override
  String get deskErrFileNotSaved => '文件未保存。这笔付款保留在“活动”中；在那里取消即可解锁资金。';

  @override
  String get deskErrTorOffSend => 'Tor 已关闭。开启 Tor 才能发送到 onion 地址。';

  @override
  String get deskErrTorConnecting => 'Tor 仍在连接。请稍后重试。';

  @override
  String get deskErrRecipientNoAnswer => '接收方的钱包没有响应或拒绝了。';

  @override
  String get deskErrRecipientNoAnswerWaits =>
      '接收方的钱包没有响应或拒绝了。这笔付款保留在“活动”中；在那里取消即可解锁资金。';

  @override
  String get deskErrNotDelivered => '未送达。这笔付款保留在“活动”中；在那里取消即可解锁资金。';

  @override
  String get deskErrInterruptedLock => '被锁定中断。它可能已经发出：解锁后请查看“活动”。';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail。这笔付款保留在“活动”中；在那里取消即可解锁资金。';
  }

  @override
  String get deskErrNodeRefused => '双方钱包都已签名，但节点拒绝了这笔交易。在“活动”中取消它即可解锁资金。';

  @override
  String get deskErrFileNotReadable => '无法读取文件';

  @override
  String get deskErrNotTxFile2 => '不是交易文件';

  @override
  String get deskErrResponseNotSaved => '回复文件未保存';

  @override
  String get deskErrCannotCancel => '这笔付款无法取消';

  @override
  String get deskErrNoLocalNode => '此版本不含本地节点';

  @override
  String get deskErrLocalNodeStopped => '本地节点已停止';

  @override
  String get deskErrNotChangedLocked => '未更改：钱包已被锁定';

  @override
  String deskErrLocalNodeNotStarted(String detail) {
    return '本地节点未启动：$detail';
  }

  @override
  String get deskErrUnknown => '未知错误';

  @override
  String get deskErrNotServerName => '不是有效的服务器名称';

  @override
  String deskErrPortInUse(int port) {
    return '端口 $port 被占用';
  }

  @override
  String deskErrPortUnavailable(int port) {
    return '端口 $port 不可用';
  }

  @override
  String get deskErrStoppedWithError => '因错误而停止';

  @override
  String get deskErrPasswordNotChanged => '密码未更改。当前密码仍可打开钱包。';

  @override
  String get deskErrNothingToSpend => '没有可花费的资金';

  @override
  String get deskTorLineOff => '关闭';

  @override
  String get deskTorLineReady => '就绪';

  @override
  String deskTorLineSendsWork(String problem) {
    return '$problem。发送不受影响。';
  }

  @override
  String get deskTorLinePublishing => '正在发布 onion 地址…';

  @override
  String deskTorLineConnecting(int percent) {
    return '正在连接 Tor… $percent%';
  }

  @override
  String get deskErrHistOtherWallet => '其他钱包的备份';

  @override
  String get deskErrHistOtherChain => '网络不符';

  @override
  String get deskErrHistNotOurs => '不是交易记录备份';

  @override
  String get deskErrHistNewer => '文件版本较新';

  @override
  String get deskErrHistDamaged => '文件已损坏';

  @override
  String get deskErrOldGui => '旧版 Epic Wallet';

  @override
  String get deskErrOldCli => 'epic 命令行程序';

  @override
  String get deskErrOldPicked => '手动选择的文件夹';

  @override
  String get deskErrHistTooLarge => '文件太大，不可能是交易记录备份。';

  @override
  String deskErrHistChains(String from, String to) {
    return '该文件来自 $from；本钱包在 $to 上。';
  }

  @override
  String get deskErrHistOtherWalletText => '该文件是从一个助记词不同的钱包导出的。';

  @override
  String get deskErrHistNewerText => '该文件由更新版本的应用生成。请先更新应用，然后再导入。';

  @override
  String get deskErrHistDamagedText => '该文件不完整或已被改动。';

  @override
  String get deskErrHistNotOursText =>
      '该文件不是由 Epic Cash Desktop 或 Epic Cash Mobile 生成的。';

  @override
  String get deskDataHttpEnter => '请输入接收方的地址';

  @override
  String get deskDataHttpScheme => '以 https:// 或 http:// 开头';

  @override
  String get deskDataHttpOnion => 'onion 地址需要 Tor';

  @override
  String get deskDataHttpNot => '不是 http(s) 地址';

  @override
  String get deskDataHttpPort => '端口必须在 1 到 65535 之间';

  @override
  String get deskDataUpdTimeout => '更新服务器没有响应。';

  @override
  String get deskDataUpdUnreachable => '无法连接更新服务器。';

  @override
  String deskDataUpdStatus(int status) {
    return '更新服务器返回了 $status。';
  }

  @override
  String get deskDataUpdNone => '尚未发布桌面版的更新信息。';

  @override
  String get deskNodeSynced => '已同步';

  @override
  String get deskNodeBehind => '落后';

  @override
  String get deskNodeNotAnswering => '无响应';

  @override
  String get deskNodeChecking => '正在检查';

  @override
  String get deskNodeStarting => '正在启动';

  @override
  String get deskNodeSyncing => '正在同步';

  @override
  String get deskNodeStalled => '停滞';

  @override
  String get deskNodeFailed => '失败';

  @override
  String get deskNodeStopped => '已停止';

  @override
  String get deskNodeMarkerNoAnswer => '无响应';

  @override
  String deskNodeMarkerBehind(String count) {
    return '落后 $count';
  }

  @override
  String get deskNodeMarkerStarting => '启动中';

  @override
  String get deskNodeMarkerStalled => '停滞';

  @override
  String get deskNodeMarkerFailed => '失败';

  @override
  String get deskNodeMarkerStopped => '已停止';

  @override
  String deskNodeHostSince(String host, String time) {
    return '$host · 自 $time 起';
  }

  @override
  String get deskNodeNotAnsweringLine => '节点无响应。';

  @override
  String deskNodeLatency(String ms) {
    return '$ms 毫秒';
  }

  @override
  String deskNodeLatencyOverTor(String ms) {
    return '经由 Tor $ms 毫秒';
  }

  @override
  String deskNodeNewerOut(String version) {
    return '$version 已发布';
  }

  @override
  String get deskNodeBehindLine => '落后于网络，正在追赶。';

  @override
  String deskNodeHeightOf(String height, String total) {
    return '$height/$total';
  }

  @override
  String get deskNodeAtTip => '已是最新';

  @override
  String get deskNodeLocal => '本地节点';

  @override
  String get deskNodeConnectingPeers => '正在连接对等节点';

  @override
  String deskNodeUsingUntilSynced(String host) {
    return '同步完成前使用 $host。';
  }

  @override
  String get deskNodeNothingUntilSynced => '同步完成前无法发送。';

  @override
  String deskNodePeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个对等节点',
    );
    return '$_temp0';
  }

  @override
  String deskNodeRunning(String duration) {
    return '已运行 $duration';
  }

  @override
  String deskNodeStillUsing(String host) {
    return '仍在使用 $host；本地节点很快会接替。';
  }

  @override
  String get deskNodeNoProgress => '5 分钟没有进展，已自动重启过一次。';

  @override
  String deskNodeUsingMeanwhile(String host) {
    return '期间使用 $host。';
  }

  @override
  String get deskNodeStartIt => '可在“设置 › 节点”中启动。';

  @override
  String get deskNodeFailPort => '端口 3413 被其他程序占用';

  @override
  String get deskNodeFailDisk => '磁盘空间不足';

  @override
  String get deskNodeFailMissing => '缺少节点程序';

  @override
  String get deskNodeFailExited => '节点程序已停止';

  @override
  String deskNodeFailExitedCode(String code) {
    return '节点程序已停止（退出代码 $code）';
  }

  @override
  String get deskNodeFailDefault => '节点未能启动';

  @override
  String get deskNodeStageWaiting => '连接对等节点';

  @override
  String get deskNodeStageHeaders => '区块头';

  @override
  String get deskNodeStageChainDownload => '下载链状态';

  @override
  String get deskNodeStageKernels => '检查内核';

  @override
  String get deskNodeStageRangeProofs => '检查范围证明';

  @override
  String get deskNodeStageProcessing => '处理链状态';

  @override
  String get deskNodeStageBlocks => '区块';

  @override
  String get deskNodeStageCompacting => '压缩';

  @override
  String get deskNodeStageStopping => '正在停止';

  @override
  String get deskNodeStageSyncing => '同步';

  @override
  String get deskNodeLineWaiting => '正在连接对等节点';

  @override
  String deskNodeLineHeaders(String done, String total) {
    return '区块头 · $done/$total';
  }

  @override
  String get deskNodeLineHeadersBare => '区块头';

  @override
  String deskNodeLineChain(String done, String total) {
    return '链状态 · $done/$total GB';
  }

  @override
  String get deskNodeLineChainBare => '链状态';

  @override
  String deskNodeLineKernels(String done, String total) {
    return '检查内核 · $done/$total 百万';
  }

  @override
  String get deskNodeLineKernelsBare => '检查内核';

  @override
  String deskNodeLineRangeProofs(String done, String total) {
    return '检查范围证明 · $done/$total 百万';
  }

  @override
  String get deskNodeLineRangeProofsBare => '检查范围证明';

  @override
  String get deskNodeLineProcessing => '正在处理链状态';

  @override
  String deskNodeLineBlocks(String done, String total) {
    return '区块 · $done/$total';
  }

  @override
  String get deskNodeLineBlocksBare => '区块';

  @override
  String get deskNodeLineCompacting => '正在压缩链数据';

  @override
  String get deskNodeLineStopping => '正在停止…';

  @override
  String get deskNodeLineSyncing => '正在同步';

  @override
  String get deskNodeNoEstimate => '无法估算；最多一小时';

  @override
  String get deskNodeEstimating => '正在估算…';

  @override
  String deskNodeAboutHours(int hours) {
    return '约剩 $hours 小时';
  }

  @override
  String deskNodeAboutMinutes(int minutes) {
    return '约剩 $minutes 分钟';
  }

  @override
  String deskNodeDurationHm(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String deskNodeDurationM(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get deskTorNetworkLabel => 'Tor 网络';

  @override
  String get deskTorNetworkHint =>
      '网络活动经由 Tor 网络。Tor 会隐藏钱包的互联网地址：每个连接都经过多个由志愿者运行的中继，因此没有任何服务器知道钱包在哪里。';

  @override
  String get deskTorOff => '关闭';

  @override
  String get deskTorStarting => '正在启动…';

  @override
  String get deskTorOn => '开启';

  @override
  String get deskTorNotConnected => '未连接';

  @override
  String get deskTorRoutes => 'Epicbox、节点、状态、价格、更新、支持和 Tor 地址';

  @override
  String get deskTorCoverage => '经由 Tor：Epicbox、节点、状态、价格、更新、支持和 Tor 地址。';

  @override
  String get deskTorNodeOver => '经由 Tor';

  @override
  String get deskTorNodeNotEncrypted => 'Tor 出口之后未加密';

  @override
  String get deskTorNodeWaits => '等 Tor 连接后再连接。';

  @override
  String get deskRecvTitle => '接收';

  @override
  String get deskRecvReceiving => '接收';

  @override
  String get deskRecvNameFile => '直接 · 文件传输';

  @override
  String deskRecvTurnOnFailed(String method) {
    return '$method 未开启';
  }

  @override
  String deskRecvTurnOffFailed(String method) {
    return '$method 未关闭';
  }

  @override
  String get deskRecvOtherWays => '其他接收方式';

  @override
  String get deskRecvSettings => '设置';

  @override
  String get deskRecvTorNotConnected => 'Tor 未连接。';

  @override
  String get deskRecvTorStarting => 'Tor 正在启动。';

  @override
  String deskRecvTorDownText(String routes) {
    return '在 Tor 连接成功或被关闭之前，$routes都无法使用。';
  }

  @override
  String get deskRecvTorStartingText => 'Tor 连接后地址即可访问。在此期间不会经由明网传输任何内容。';

  @override
  String get deskRecvTurnTorOff => '关闭 Tor';

  @override
  String get deskRecvTryAgain => '重试';

  @override
  String get deskRecvStateOn => '开启';

  @override
  String get deskRecvStateOff => '关闭';

  @override
  String get deskRecvStateChecking => '正在检查';

  @override
  String deskRecvSemList(String method, String state) {
    return '$method $state';
  }

  @override
  String deskRecvSemMethod(String method, String state) {
    return '$method：$state';
  }

  @override
  String deskRecvTipChecking(String method) {
    return '$method · 正在检查';
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
  String get deskRecvTagPaused => '已暂停';

  @override
  String get deskRecvTagStarting => '正在启动';

  @override
  String get deskRecvTagNotReachable => '无法访问';

  @override
  String get deskRecvAddressUnreadable => '无法读取地址。请稍后重新打开“接收”。';

  @override
  String get deskRecvEpicboxAddress => 'Epicbox 地址';

  @override
  String get deskRecvCopyEpicbox => '复制 Epicbox 地址';

  @override
  String get deskRecvEpicboxIntro =>
      '分享此地址即可收款。钱包关闭时也能用：Epicbox 服务器会暂存付款，直到钱包重新打开。';

  @override
  String get deskRecvCheckSix => '念给别人核对时，请检查前六位和后六位字符。';

  @override
  String get deskRecvHttpAddress => '链接 · HTTP 地址';

  @override
  String get deskRecvCopyHttp => '复制 链接 · HTTP 地址';

  @override
  String deskRecvHttpPublic(int port) {
    return '你的路由器的公网地址。路由器转发端口 $port 后，互联网上的发送方即可使用。';
  }

  @override
  String get deskRecvHttpLocal => '本机上的程序可以向此地址付款。其他设备请见“设置 › 交易”。';

  @override
  String get deskRecvHttpIntro => '本钱包打开时，直接从另一个钱包接收。除非设置中另有选择，否则仅限本机。';

  @override
  String get deskRecvHttpTorHint => '如需 Tor 地址，请在“设置 › 隐私”中开启 Tor。';

  @override
  String get deskRecvDirectTor => '链接 · Tor 地址';

  @override
  String get deskRecvTorIntro => '本钱包打开时，经由 Tor 直接从另一个钱包接收。Tor 在“设置 › 隐私”中设置。';

  @override
  String get deskRecvTorAddress => '链接 · Tor 地址';

  @override
  String get deskRecvCopyTor => '复制 Tor 地址';

  @override
  String get deskRecvTorOnion => '有些钱包显示的地址不带 .onion；两者是同一个地址。';

  @override
  String get deskRecvFiles => '交易文件';

  @override
  String get deskRecvSignTitle => '签署交易文件';

  @override
  String get deskRecvSignText => '发送方提供了一个交易文件。钱包会签署它，并为对方保存一份回复。';

  @override
  String get deskRecvOpen => '打开';

  @override
  String get deskRecvFinalizeTitle => '完成回复文件';

  @override
  String get deskRecvFinalizeText => '以文件方式发送的付款收到了回复。完成后即会广播这笔付款。';

  @override
  String deskRecvSwitchLabel(String title) {
    return '$title，接收';
  }

  @override
  String get deskSendStrategySmallest => '最小';

  @override
  String get deskSendStrategyAll => '全部';

  @override
  String get deskSendBalanceAfter => '发送后余额';

  @override
  String get deskSendSpendableUntil => '找零确认前可用';

  @override
  String deskSendSplitLine(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: '找零拆分为 $outputs 个输出（+$fee EPIC 手续费）',
    );
    return '$_temp0';
  }

  @override
  String deskSendSplitWhy(int outputs, String each) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: '这样下一笔发送不必等这一笔确认。找零会以 $outputs 个约 $each EPIC 的输出返回，而不是一个。',
    );
    return '$_temp0';
  }

  @override
  String get deskSendSplitWhyLabel => '为什么拆分找零';

  @override
  String deskSendLockNoChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '没有找零：正好花掉 $count 个输出，无需等待。',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockAll(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部锁定：$count 个输出，$amount EPIC，约 3 个区块。',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出被锁定，$amount EPIC，约 3 个区块。',
    );
    return '$_temp0';
  }

  @override
  String deskSendStrategyLine(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '本次发送的策略：$strategy · $count 个输出。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSplit(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: '找零拆分为 $outputs 个输出（+$fee EPIC）。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksNone(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出中的 $locked EPIC；没有找零返回。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部：$count 个输出中的 $locked EPIC 将锁定到找零确认（3 个区块）。期间没有可用余额。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出中的 $locked EPIC 将锁定到找零确认（3 个区块）。期间没有其他可用余额。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksSome(int count, String locked, String spendable) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出中的 $locked EPIC 将锁定到找零确认（3 个区块）。$spendable EPIC 仍可使用。',
    );
    return '$_temp0';
  }

  @override
  String get deskSendFactLocks => '锁定';

  @override
  String get deskSendFactStrategy => '策略';

  @override
  String deskSendFactStrategyValue(String strategy) {
    return '$strategy输出，仅限本次发送';
  }

  @override
  String get deskSendAdvSmallest => '· 最小输出';

  @override
  String get deskSendAdvSmallestNoSplit => '· 最小输出，不拆分找零';

  @override
  String get deskSendAdvAll => '· 全部输出';

  @override
  String get deskSendAdvAllNoSplit => '· 全部输出，不拆分找零';

  @override
  String get deskSendAdvanced => '发送选项';

  @override
  String get deskSendAdvStrategy => '本次发送的策略';

  @override
  String get deskSendAdvSmallestText => '花掉最少的小额输出；找零确认期间，其余余额仍可使用。';

  @override
  String get deskSendAdvAllText => '花掉所有可用输出，并返回一个找零输出。确认前全部锁定；之后输出更少、更大。';

  @override
  String get deskSendDefaultTag => '默认';

  @override
  String get deskSendAdvAllNote => '发送全部余额会花掉所有输出。';

  @override
  String get deskSendAdvSplit => '拆分找零';

  @override
  String get deskSendAdvSplitText => '剩余输出很少时，把找零拆成多个输出返回，这样下一笔发送不必等待。';

  @override
  String get deskSendAdvDefaults => '仅限本次发送。默认设置：';

  @override
  String get deskSendAdvOutputsLink => '输出';

  @override
  String get deskSendPickNone => '暂无联系人';

  @override
  String get deskSendPickNoneText => '先在“联系人”中保存你要付款的人，然后在这里选择。';

  @override
  String get deskSendPickOpen => '打开联系人';

  @override
  String deskSendPickNoMatch(String query) {
    return '没有与“$query”匹配的联系人。';
  }

  @override
  String get deskSendPickTitle => '选择联系人';

  @override
  String get deskSendPickDesc => '地址会填入接收方字段。';

  @override
  String get deskSendPickSearch => '搜索联系人';

  @override
  String get deskSendTitle => '发送';

  @override
  String get deskSendErrNoAddress => '请填写接收地址。';

  @override
  String get deskSendErrEpicbox => '这不是有效的 Epicbox 地址。';

  @override
  String get deskSendErrNotDirect => '这不是链接地址。';

  @override
  String get deskSendErrOnion => '这不是有效的 onion 地址。';

  @override
  String get deskSendErrOwn => '这是本钱包自己的地址。';

  @override
  String get deskSendNoAnswer => '接收方没有响应。没有发送任何资金。';

  @override
  String get deskSendTorOnFailed => 'Tor 未开启';

  @override
  String get deskSendTorOffFailed => 'Tor 未关闭';

  @override
  String get deskSendEpicboxOnFailed => 'Epicbox 未开启';

  @override
  String get deskSendNothingSpendable => '没有可发送的可用余额。';

  @override
  String get deskSendAllFailed => '无法计算可发送的金额。请稍后重试。';

  @override
  String get deskSendErrAmountEnter => '请输入金额。';

  @override
  String get deskSendErrAmountDecimals => 'EPIC 最多有 8 位小数。';

  @override
  String get deskSendErrAmountZero => '金额必须大于 0。';

  @override
  String get deskSendErrAmountMore => '超过可用余额。';

  @override
  String get deskSendSent => '已发送';

  @override
  String get deskSendFileReadyTitle => '交易文件已就绪';

  @override
  String get deskSendFileReadyText => '把这个文件交给接收方。钱包正在等待回复文件；收到后请完成交易。';

  @override
  String get deskSendFinalize => '完成交易';

  @override
  String get deskSendNewSend => '新的发送';

  @override
  String get deskSendNodeNotSynced => '节点未同步';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return '节点同步完成后才能发送。已完成 $percent%；期间可以先填写表单。';
  }

  @override
  String get deskSendNodeSyncing => '节点同步完成后才能发送。';

  @override
  String get deskSendTorBlocked => 'Tor 未连接';

  @override
  String get deskSendTorBlockedText => '在 Tor 连接成功或被关闭之前，不会发送任何内容。';

  @override
  String get deskSendTurnTorOff => '关闭 Tor';

  @override
  String get deskSendTorStarting => 'Tor 正在启动';

  @override
  String get deskSendTorStartingText => '发送会等到 Tor 连接成功。在此期间不会经由明网传输任何内容。';

  @override
  String get deskSendEpicboxOff => 'Epicbox 未连接';

  @override
  String get deskSendEpicboxOffText =>
      '开启 Epicbox 接收后才能通过 Epicbox 发送。在此期间可以使用 直接 · 文件传输。';

  @override
  String get deskSendEpicboxTurnOn => '开启 Epicbox 接收';

  @override
  String get deskSendDoneViaDirect => '已完成并广播到网络。';

  @override
  String get deskSendDoneViaEpicbox => '已交给 Epicbox。接收方响应后即完成。';

  @override
  String get deskSendViewTx => '查看交易';

  @override
  String get deskSendFailedTitle => '发送失败';

  @override
  String get deskSendReviewAgain => '重新确认';

  @override
  String get deskSendMethodDirect => '链接';

  @override
  String get deskSendMethodFile => '直接 · 文件';

  @override
  String get deskSendTo => '接收方';

  @override
  String get deskSendToHelp => '粘贴地址，或输入联系人的名称。';

  @override
  String get deskSendToHint => '地址或联系人';

  @override
  String get deskSendToSem => '接收方';

  @override
  String get deskSendClearTo => '清除接收方';

  @override
  String get deskSendContacts => '联系人';

  @override
  String get deskSendNeedsTor => '需要 Tor';

  @override
  String get deskSendNeedsTorText => 'onion 地址只能经由 Tor 访问。';

  @override
  String get deskSendNoTorBuild => '此版本不含 Tor。';

  @override
  String get deskSendTurnOnTor => '开启 Tor';

  @override
  String get deskSendHttpClearnet => '链接 · HTTP 经由明网，而不是 Tor。';

  @override
  String get deskSendClear => '清除';

  @override
  String get deskSendAmount => '金额';

  @override
  String get deskSendAvailableNone => '可用 —';

  @override
  String deskSendAvailable(String amount) {
    return '可用 $amount EPIC';
  }

  @override
  String get deskSendAmountSem => '金额（EPIC）';

  @override
  String get deskSendAllButton => '全部';

  @override
  String get deskSendConfirmingHidden => '部分余额仍在确认中，暂时无法发送。';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC 仍在确认中，暂时无法发送。';
  }

  @override
  String get deskSendMessage => '留言';

  @override
  String get deskSendMessageHelp => '接收方会看到这条留言。';

  @override
  String get deskSendPrivacyOn => '隐私 · Dandelion++ 已开启';

  @override
  String get deskSendPrivacyOff => '隐私 · Dandelion++ 已关闭';

  @override
  String get deskSendDandelionText => '交易在扩散前会先经过几个随机节点，因此网络无法判断它来自哪里。';

  @override
  String get deskSendHintSent => '已发送。如需再次发送，请输入新的金额和接收方。';

  @override
  String get deskSendHintNode => '等待节点同步。';

  @override
  String get deskSendHintEpicbox => '等待 Epicbox 连接。';

  @override
  String get deskSendHintTorWait => '等待 Tor 连接。';

  @override
  String get deskSendHintTorBlocked => '重试 Tor，或将其关闭。';

  @override
  String get deskSendHintNeedsTor => '开启 Tor 才能发送到 onion 地址。';

  @override
  String get deskSendHintFix => '请修正标红的字段。';

  @override
  String get deskSendHintChecking => '正在计算此金额的手续费。';

  @override
  String get deskSendHintDefault => '确认之前不会发送任何资金。';

  @override
  String get deskSendReviewWaitTor => '等待 Tor';

  @override
  String get deskSendReviewTorOff => 'Tor 未连接';

  @override
  String get deskSendReview => '确认发送';

  @override
  String get deskSendSummary => '摘要';

  @override
  String get deskSendNetworkFee => '网络手续费';

  @override
  String get deskSendTotal => '总计';

  @override
  String get deskSendUpdating => '钱包扫描期间余额正在更新。';

  @override
  String get deskSendEpicboxLine1 => '接收方可以不在线。';

  @override
  String get deskSendEpicboxLine2 => 'Epicbox 服务器会暂存付款，直到对方打开钱包。';

  @override
  String get deskSendDirectLine1 => '直达对方钱包。';

  @override
  String get deskSendDirectLine2 =>
      'http(s) 或 .onion 地址；onion 地址经由 Tor。对方钱包必须处于打开状态。';

  @override
  String get deskSendFileLine1 => '无需联网。';

  @override
  String get deskSendFileLine2 => '把文件交给对方，收回对方的回复文件，然后在这里完成交易。';

  @override
  String get deskSendTagDirect => '链接';

  @override
  String get deskSendTagFile => '直接 · 文件';

  @override
  String get deskSendTagEpicbox => '经由 Epicbox';

  @override
  String get deskSendSwitchedDirect => '链接地址。方式已设为链接。';

  @override
  String get deskSendSwitchedFile => '文件地址。方式已设为 直接 · 文件。';

  @override
  String get deskSendSwitchedEpicbox => 'Epicbox 地址。方式已设为 Epicbox。';

  @override
  String get deskSendMatching => '匹配的联系人';

  @override
  String deskSendMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个联系人匹配',
    );
    return '$_temp0';
  }

  @override
  String get deskSendWrongPassword => '密码错误。';

  @override
  String get deskSendNotConfirmed => '未确认。再次发送前，请先查看“活动”。';

  @override
  String get deskSendViaEpicbox => 'Epicbox（接收方可以不在线）';

  @override
  String get deskSendViaDirect => '链接 · HTTP（对方钱包必须处于打开状态）';

  @override
  String get deskSendViaTor => '链接 · Tor（对方钱包必须处于打开状态）';

  @override
  String get deskSendViaFile => '交易文件';

  @override
  String deskSendUsesAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '使用全部 $count 个输出 · 找零 1 个输出',
    );
    return '$_temp0';
  }

  @override
  String get deskSendReviewTitle => '确认并发送';

  @override
  String get deskSendReviewDesc => '发送一经广播就无法撤销。';

  @override
  String get deskSendFactTo => '接收方';

  @override
  String get deskSendCheckChars => '请将高亮的字符与接收方提供的地址核对。';

  @override
  String get deskSendFactVia => '方式';

  @override
  String get deskSendFactPrivacy => '隐私';

  @override
  String get deskSendDandelionOn => 'Dandelion++ 已开启';

  @override
  String get deskSendDandelionOff => 'Dandelion++ 已关闭';

  @override
  String get deskSendFactMessage => '留言';

  @override
  String get deskSendPassword => '密码';

  @override
  String get deskSendPasswordHelp => '每次发送都需要输入钱包密码。';

  @override
  String get deskSendBusyFile => '正在创建文件。';

  @override
  String get deskSendBusyTor => '正在经由 Tor 连接对方钱包…这可能需要一些时间。请保持应用打开。';

  @override
  String get deskSendBusy => '正在发送。这可能需要几秒钟；请保持此窗口打开。';

  @override
  String get deskSendBack => '返回';

  @override
  String get deskSendSending => '正在发送';

  @override
  String deskSendConfirm(String amount) {
    return '发送 $amount EPIC';
  }

  @override
  String get deskSendPlainTitle => '未加密。仍要发送？';

  @override
  String get deskSendPlainDesc =>
      '以明文 HTTP 发送到另一台电脑。途经的任何人都能读取这笔交易。https:// 是加密的。';

  @override
  String get deskSendPlainConfirm => '仍要发送';

  @override
  String deskSendEpicboxSwitched(String domain) {
    return '已切换到 $domain';
  }

  @override
  String get deskSendEpicboxNotSwitched => '未切换';

  @override
  String get deskSendEpicboxDownTitle => 'Epicbox 服务器无响应';

  @override
  String get deskSendEpicboxDownWait => '付款会等到服务器恢复。';

  @override
  String deskSendEpicboxSwitchTo(String domain) {
    return '切换到 $domain？';
  }

  @override
  String get deskSendEpicboxSwitch => '切换';

  @override
  String get deskFinOpenFolder => '打开文件夹';

  @override
  String get deskFinFolderNotOpened => '未能打开文件夹';

  @override
  String get deskFinWrongType => '不是回复文件';

  @override
  String get deskFinWrongTypeText => '该文件不是回复文件。请选择接收方发回的文件。';

  @override
  String get deskFinUnreadable => '无法读取文件';

  @override
  String get deskFinUnreadableText => '无法读取该文件。文件可能已损坏，或仍在复制中。';

  @override
  String get deskFinFailed => '完成交易失败';

  @override
  String get deskFinFailedText => '钱包无法完成此文件。它可能属于另一笔交易，或已经完成过。';

  @override
  String get deskFinNotPosted => '未广播';

  @override
  String get deskFinNotPostedText => '交易已完成，但节点没有接受。请检查节点，然后重试。';

  @override
  String get deskFinPickTitle => '回复文件';

  @override
  String get deskFinPosted => '交易已广播';

  @override
  String get deskFinTitle => '完成回复文件';

  @override
  String get deskFinNoticeTitle => '用于以文件方式创建的交易';

  @override
  String get deskFinNoticeText => '使用接收方发回的回复文件。';

  @override
  String get deskFinTryAgain => '重试';

  @override
  String get deskFinPostedText => '付款已完成并发送到网络。可在“活动”中查看进度。';

  @override
  String get deskFinAnother => '完成另一个文件';

  @override
  String get deskFinViewActivity => '在“活动”中查看';

  @override
  String get deskFinBusy => '正在完成并广播';

  @override
  String get deskFinChoose => '选择回复文件';

  @override
  String get deskFinChooseText => '钱包会完成这笔交易并广播到网络。';

  @override
  String get deskFinChooseFile => '选择文件';

  @override
  String get deskImpWrongType => '不是交易文件';

  @override
  String get deskImpWrongTypeText => '该文件不是交易文件。请选择发送方提供的 .slate 或 .tx 文件。';

  @override
  String get deskImpUnreadable => '无法读取文件';

  @override
  String get deskImpUnreadableText => '无法读取该文件。文件可能已损坏，或仍在复制中。';

  @override
  String get deskImpNoPlace => '未签名';

  @override
  String get deskImpNoPlaceText => '没有选择回复文件的保存位置，因此未签名。';

  @override
  String get deskImpFailed => '签名失败';

  @override
  String get deskImpFailedText => '钱包无法签署此文件。它可能属于另一个钱包，或已被使用。';

  @override
  String deskImpFailedDetail(String detail) {
    return '钱包无法签署此文件。它可能属于另一个钱包，或已被使用。$detail。';
  }

  @override
  String get deskImpPickTitle => '交易文件';

  @override
  String get deskImpTitle => '签署交易文件';

  @override
  String get deskImpNoticeTitle => '签名不会花费任何资金';

  @override
  String get deskImpNoticeText => '通过发送方使用的同一渠道，把回复文件发回给对方。';

  @override
  String get deskImpSaved => '回复已保存';

  @override
  String get deskImpSavedText => '把回复文件发回给发送方。发送方完成交易后，EPIC 即会到账。';

  @override
  String get deskImpAmount => '金额 ';

  @override
  String get deskImpAnother => '签署另一个文件';

  @override
  String get deskImpBusy => '正在签署文件';

  @override
  String get deskImpChoose => '选择交易文件';

  @override
  String get deskImpChooseText => '钱包会签署它，并为发送方保存一份回复。';

  @override
  String get deskActNotUpdated => '未更新';

  @override
  String get deskActSearchHint => '地址或 Slate ID';

  @override
  String get deskActSearchHintEmpty => '暂无可搜索的内容';

  @override
  String get deskActSearchLabel => '搜索交易';

  @override
  String get deskActClearSearch => '清除搜索';

  @override
  String get deskActShowAmounts => '显示金额';

  @override
  String get deskActHideAmounts => '隐藏金额';

  @override
  String get deskActRefresh => '刷新';

  @override
  String get deskActTitle => '活动';

  @override
  String get deskActDetailReceived => '收到的交易';

  @override
  String get deskActDetailSent => '发出的交易';

  @override
  String get deskActLoading => '正在加载交易';

  @override
  String get deskActWaitingNode => '等待节点完成同步。';

  @override
  String get deskActFilterAll => '全部';

  @override
  String get deskActFilterReceived => '已接收';

  @override
  String get deskActFilterSent => '已发送';

  @override
  String get deskActNoMatchTitle => '没有匹配的交易';

  @override
  String get deskActNoMatchText => '换一个地址或 Slate ID，或清除筛选条件。';

  @override
  String deskActPageOf(int page, int pages) {
    return '第 $page 页，共 $pages 页';
  }

  @override
  String get deskActPrevPage => '上一页';

  @override
  String get deskActNextPage => '下一页';

  @override
  String get deskActPages => '分页';

  @override
  String get deskActColFromTo => '来自 / 发往';

  @override
  String get deskActColStatus => '状态';

  @override
  String get deskActColTime => '时间';

  @override
  String get deskActColAmount => '金额';

  @override
  String get deskActEmptyTitle => '暂无交易';

  @override
  String get deskActEmptyText => '每笔发送或接收的付款都会列在这里，最新的在前，并显示对方是谁以及进行到哪一步。';

  @override
  String get deskActStageWaiting => '等待中';

  @override
  String get deskActStageWaitingText => '双方钱包都要签名。使用 Epicbox 时会自动完成。';

  @override
  String get deskActStageConfirming => '确认中';

  @override
  String get deskActStageConfirmingText => '已上链。大约每分钟一个区块。';

  @override
  String get deskActStageSpendable => '可用';

  @override
  String deskActStageSpendableText(int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: '$needed 个确认之后，约 $needed 分钟。',
    );
    return '$_temp0';
  }

  @override
  String get deskActShowAddress => '显示地址';

  @override
  String get deskActReceiveFile => '接收文件';

  @override
  String get deskConTitle => '联系人';

  @override
  String get deskConLoading => '正在加载联系人';

  @override
  String get deskConNewTitle => '新建联系人';

  @override
  String get deskConEditTitle => '编辑联系人';

  @override
  String get deskConDetailsTitle => '详情';

  @override
  String get deskConSearchHint => '名称或地址';

  @override
  String get deskConSearchLabel => '搜索联系人';

  @override
  String get deskConClearSearch => '清除搜索';

  @override
  String deskConCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个联系人',
    );
    return '$_temp0';
  }

  @override
  String get deskConNoMatches => '无匹配';

  @override
  String deskConMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个匹配',
    );
    return '$_temp0';
  }

  @override
  String get deskConSortName => '名称';

  @override
  String get deskConSortRecent => '最近';

  @override
  String get deskConNone => '暂无联系人。';

  @override
  String get deskConNoMatchList => '没有匹配的联系人';

  @override
  String get deskConAdd => '添加联系人';

  @override
  String get deskConIdle => '选择一个联系人，即可查看详情、向其发送、编辑或删除。';

  @override
  String get deskConEmptyTitle => '暂无联系人';

  @override
  String get deskConEmptyText => '保存经常付款的人和商家。在“发送”页可以直接选择名称，而不用粘贴地址。';

  @override
  String get deskConEmptyLocal => '联系人只保存在这台电脑上，不包含在助记词中。';

  @override
  String get deskConSendToAddress => '发送到地址';

  @override
  String deskConLastTx(String when) {
    return '上一笔交易：$when';
  }

  @override
  String get deskConSend => '发送';

  @override
  String get deskConEdit => '编辑';

  @override
  String get deskConStar => '加星标';

  @override
  String get deskConUnstar => '取消星标';

  @override
  String get deskConDelete => '删除';

  @override
  String get deskConNotDeleted => '未删除';

  @override
  String deskConDeleted(String name) {
    return '已删除 $name';
  }

  @override
  String get deskConNote => '备注';

  @override
  String deskConTxWith(String name) {
    return '与 $name 的交易';
  }

  @override
  String get deskConAllTx => '全部交易';

  @override
  String get deskConTxNone => '与此联系人还没有交易。从“发送”页发给对方的付款会显示在这里。';

  @override
  String get deskConTxReceived => '已收到';

  @override
  String get deskConTxSent => '已发送';

  @override
  String get deskConErrName => '请为联系人填写名称。';

  @override
  String get deskConErrAddressEmpty => '请填写地址。';

  @override
  String get deskConErrAddressInvalid =>
      '地址无效。请使用 Epicbox 地址（es5x…@epicbox.epiccash.com）、链接地址（https://…）或 onion 地址（….onion）。';

  @override
  String get deskConAddPicture => '添加图片';

  @override
  String get deskConChangePicture => '更换图片';

  @override
  String get deskConRemovePicture => '移除';

  @override
  String get deskConPictureHelp =>
      'PNG、JPEG、WebP 或 GIF，最大 10 MB。应用内会保留一份小尺寸副本。';

  @override
  String get deskConFieldName => '名称';

  @override
  String get deskConFieldAddress => '地址';

  @override
  String get deskConSaveFailed => '联系人未保存';

  @override
  String get deskConSave => '保存联系人';

  @override
  String deskConDeleteTitle(String name) {
    return '删除 $name？';
  }

  @override
  String get deskConDeleteBody => '此联系人的地址和备注将从本钱包中移除。过去的交易仍保留在“活动”中。此操作无法撤销。';

  @override
  String get deskConKeep => '保留联系人';

  @override
  String get deskConDeleteAction => '删除联系人';

  @override
  String get deskOutNotUpdated => '未更新';

  @override
  String get deskOutTitle => '输出';

  @override
  String get deskOutShowAmounts => '显示金额';

  @override
  String get deskOutHideAmounts => '隐藏金额';

  @override
  String get deskOutRefresh => '刷新';

  @override
  String get deskOutLockedNote =>
      '已锁定的输出正被一笔进行中的交易花费。它们的找零显示为“等待完成”，在发送完成前不计入总额，因此总额中每个币只计算一次。';

  @override
  String get deskOutIntro =>
      '输出是构成余额的一个个部分。一笔发送会花掉整个输出，付给接收方，并把剩余部分作为新的输出返回；被花掉的输出在发送确认前保持锁定。';

  @override
  String deskOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出',
    );
    return '$_temp0';
  }

  @override
  String get deskOutCardWait => '请等待发送确认（约 3 个区块）。';

  @override
  String get deskOutSplitNothing => '暂无可拆分的输出。';

  @override
  String deskOutSplitSpends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '花费 $count 个输出。',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitSpendsFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '花费 $count 个输出。手续费 $fee EPIC 起。',
    );
    return '$_temp0';
  }

  @override
  String get deskOutConsNothing => '暂无可合并的输出。';

  @override
  String get deskOutConsOne => '无需合并：只有一个可用输出。';

  @override
  String deskOutConsInto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出合并为 1 个。',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsIntoFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出合并为 1 个。手续费 $fee EPIC。',
    );
    return '$_temp0';
  }

  @override
  String get deskOutSplitCardTitle => '拆分';

  @override
  String get deskOutSplitCardText => '用可用余额生成更多输出，这样多笔发送可以接连进行，无需等待。';

  @override
  String get deskOutSplitCardButton => '拆分…';

  @override
  String get deskOutConsCardTitle => '合并';

  @override
  String get deskOutConsCardText => '把所有可用输出合并为一个。下一笔发送的手续费更低；确认前全部锁定。';

  @override
  String get deskOutConsCardButton => '合并…';

  @override
  String get deskOutNotLoadedTitle => '未能加载输出';

  @override
  String get deskOutNotLoadedText => '刷新以重试。';

  @override
  String get deskOutLoading => '正在加载钱包数据';

  @override
  String get deskOutNoneTitle => '暂无输出';

  @override
  String get deskOutNoneText => '收到第一笔付款时会生成一个输出。拆分和合并需要有输出才能使用。';

  @override
  String get deskOutFilterAll => '全部';

  @override
  String get deskOutFilterSpendable => '可用';

  @override
  String get deskOutFilterConfirming => '确认中';

  @override
  String get deskOutFilterLocked => '已锁定';

  @override
  String get deskOutSearchHint => '承诺';

  @override
  String get deskOutSearchLabel => '搜索输出';

  @override
  String get deskOutClearSearch => '清除搜索';

  @override
  String get deskOutShowSpent => '显示已花费';

  @override
  String get deskOutNoMatchTitle => '没有匹配的输出';

  @override
  String get deskOutNoMatchText => '换一个承诺，或清除筛选条件。';

  @override
  String get deskOutClearFilter => '清除筛选';

  @override
  String get deskOutTileSpendable => '可用';

  @override
  String get deskOutTileConfirming => '确认中';

  @override
  String get deskOutTileImmature => '未成熟';

  @override
  String get deskOutTileLocked => '发送中锁定';

  @override
  String get deskOutTileTotal => '总额';

  @override
  String get deskOutStrategyTitle => '发送策略';

  @override
  String get deskOutStrategySmallest => '最小';

  @override
  String get deskOutStrategyAll => '全部';

  @override
  String get deskOutStrategyHelpTitle => '最小还是全部';

  @override
  String get deskOutSplitChangeTitle => '拆分找零';

  @override
  String get deskOutSplitChangeText =>
      '当一笔发送会使可用输出少于 3 个且找零至少为 1 EPIC 时，找零会以最多 4 个输出返回，每个至少 0.5 EPIC。每多一个输出花费 0.004 EPIC。';

  @override
  String get deskOutColValue => '金额';

  @override
  String get deskOutColStatus => '状态';

  @override
  String get deskOutColConfirmations => '确认数';

  @override
  String get deskOutColHeight => '高度';

  @override
  String get deskOutColTransaction => '交易';

  @override
  String get deskOutColCommitment => '承诺';

  @override
  String get deskOutStatusSpendable => '可用';

  @override
  String get deskOutStatusConfirming => '确认中';

  @override
  String deskOutConfirmations(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number 个确认',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusAwaiting => '等待完成';

  @override
  String get deskOutNoteWaitingSender => '等待发送方';

  @override
  String get deskOutStatusUnpaid => '未支付的账单';

  @override
  String get deskOutNoteNotInBalance => '不计入余额';

  @override
  String get deskOutStatusImmature => '未成熟';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还需 $number 个区块',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusMining => '挖矿';

  @override
  String get deskOutStatusLocked => '已锁定';

  @override
  String deskOutNoteBySend(int id) {
    return '被发送 #$id 锁定';
  }

  @override
  String get deskOutStatusSpent => '已花费';

  @override
  String deskOutTxReceived(String date) {
    return '收到 $date';
  }

  @override
  String deskOutTxSent(String date) {
    return '发出 $date';
  }

  @override
  String deskOutCopyCommitment(String short) {
    return '复制承诺 $short';
  }

  @override
  String deskOutSplitSpentPart(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出（$amount EPIC）',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitMadePart(int count, String amount) {
    return '$count 个约 $amount EPIC 的输出';
  }

  @override
  String deskOutConsMadePart(String amount) {
    return '一个 $amount EPIC 的输出';
  }

  @override
  String deskOutSplitDialogText(String spent, String made) {
    return '花费 $spent，生成 $made。这是一笔发给本钱包的普通网络交易，和任何发送一样在 3 个区块后确认；在此之前，所有可用余额都会锁定。';
  }

  @override
  String deskOutConsDialogText(String spent, String made) {
    return '花费 $spent，生成 $made。这是一笔发给本钱包的普通网络交易，和任何发送一样在 3 个区块后确认；在此之前，所有可用余额都会锁定。下一笔发送只花一个输出，因此手续费最低。';
  }

  @override
  String get deskOutFactFee => '网络手续费';

  @override
  String get deskOutFactEach => '每个输出';

  @override
  String deskOutFactAbout(String amount) {
    return '约 $amount EPIC';
  }

  @override
  String get deskOutFactLocked => '锁定';

  @override
  String deskOutFactLockedValue(String amount) {
    return '$amount EPIC，约 3 个区块。期间没有可用余额。';
  }

  @override
  String get deskOutMakeLabel => '生成的输出数';

  @override
  String get deskOutMakeRange => '2 到 10 个。';

  @override
  String get deskOutStepperFewer => '减少';

  @override
  String get deskOutStepperMore => '增加';

  @override
  String get deskOutFeeWorking => '正在计算手续费';

  @override
  String get deskOutNoEstimate => '无法估算';

  @override
  String get deskOutEachMin => '每个输出至少为 0.5 EPIC。';

  @override
  String get deskOutNotEnoughFee => '不足以支付手续费。';

  @override
  String deskOutSplitInto(int count) {
    return '拆分为 $count 个';
  }

  @override
  String get deskOutConsolidateButton => '合并';

  @override
  String get deskOutPostingSplit => '正在构建并广播拆分交易。请保持应用打开。';

  @override
  String get deskOutPostingCons => '正在构建并广播合并交易。请保持应用打开。';

  @override
  String get deskOutSplitPosted => '拆分已广播';

  @override
  String get deskOutConsPosted => '合并已广播';

  @override
  String deskOutSplitDoneText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '钱包现在有 $count 个约 $amount EPIC 的输出，正在确认。确认前（3 个区块）全部锁定。“活动”中会显示两条记录：一笔发送和一笔接收，都是发给本钱包的。',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount) {
    return '一个 $amount EPIC 的输出，正在确认。确认前（3 个区块）全部锁定。“活动”中会显示两条记录：一笔发送和一笔接收，都是发给本钱包的。';
  }

  @override
  String get deskOutNotPostedTitle => '未广播。';

  @override
  String get deskOutNotPostedSplit => '拆分交易已构建并保存，但节点没有接受。请重新广播，或取消它以解锁输出。';

  @override
  String get deskOutNotPostedCons => '合并交易已构建并保存，但节点没有接受。请重新广播，或取消它以解锁输出。';

  @override
  String get deskOutCancelSplit => '取消拆分';

  @override
  String get deskOutCancelCons => '取消合并';

  @override
  String get deskOutPostAgain => '重新广播';

  @override
  String get deskOutNotDoneTitle => '未完成';

  @override
  String deskOutNotDoneText(String error) {
    return '$error。输出没有变化。';
  }

  @override
  String get deskOutSomethingWrong => '出了点问题';

  @override
  String get deskOutTryAgain => '重试';

  @override
  String get deskOutToastNotPosted => '未广播';

  @override
  String get deskOutToastNotCancelled => '未取消';

  @override
  String get deskOutSplitDialogTitle => '拆分输出';

  @override
  String get deskOutConsDialogTitle => '合并输出';

  @override
  String get deskOutPostingDesc => '正在广播。';

  @override
  String get deskOutDoneDesc => '已完成。';

  @override
  String get deskOutSplitDesc => '更多输出，这样多笔发送可以接连进行。';

  @override
  String get deskOutConsDesc => '用一个输出代替多个。';

  @override
  String deskOutNothingText(String what) {
    return '无需合并：钱包只有$what。合并会把多个输出合为一个。';
  }

  @override
  String get deskOutWhatFewer => '不到两个可用输出';

  @override
  String get deskOutWhatOne => '一个可用输出';

  @override
  String get deskOvNotUpdated => '未更新';

  @override
  String get deskOvNodeNotStarted => '节点未启动';

  @override
  String get deskOvNodeAddrTitle => '节点地址已更新';

  @override
  String get deskOvNodeAddrText =>
      '现在使用 node.epiccash.com，而不是 node.epiccash.com:3413。';

  @override
  String get deskOvNodeIncompatTitle => '此节点的版本与本钱包不兼容';

  @override
  String deskOvNodeUrl(String url) {
    return '节点：$url';
  }

  @override
  String get deskOvUsePublicNode => '使用公共节点';

  @override
  String get deskOvUseLocalNode => '使用本地节点';

  @override
  String get deskOvHide => '隐藏';

  @override
  String deskOvCantReachNode(String url) {
    return '无法连接节点 $url';
  }

  @override
  String get deskOvCantReachNodeText => '请检查它是否正在运行且可以访问。余额可能不是最新的，发送已暂停。';

  @override
  String get deskOvStarting => '正在启动';

  @override
  String get deskOvStartNode => '启动节点';

  @override
  String get deskOvNodeSettings => '节点设置';

  @override
  String get deskOvTitle => '概览';

  @override
  String get deskOvShowAmounts => '显示金额';

  @override
  String get deskOvHideAmounts => '隐藏金额';

  @override
  String get deskOvRefresh => '刷新';

  @override
  String get deskOvStepDone => '已完成';

  @override
  String get deskOvStepNow => '进行中';

  @override
  String get deskOvStepWait => '等待中';

  @override
  String deskOvStepSemantics(String text, String state) {
    return '$text，$state';
  }

  @override
  String get deskOvStartingUp => '正在启动';

  @override
  String get deskOvStepUnlocked => '钱包已解锁';

  @override
  String get deskOvStepConnected => '已连接节点';

  @override
  String get deskOvStepUpdating => '正在更新余额';

  @override
  String get deskOvStepEpicbox => '正在启动 Epicbox 接收';

  @override
  String deskOvSyncTitle(int percent) {
    return '节点同步中：$percent%';
  }

  @override
  String deskOvSyncText(String block) {
    return '正在下载区块。余额是钱包在区块 $block 时所知的数额。节点追上网络后即可发送。';
  }

  @override
  String get deskOvSyncProgress => '节点同步进度';

  @override
  String deskOvSyncOfChain(int percent) {
    return '已完成区块链的 $percent%';
  }

  @override
  String get deskOvReceiveEpic => '接收 EPIC';

  @override
  String get deskOvSend => '发送';

  @override
  String get deskOvReceive => '接收';

  @override
  String get deskOvSendWaits => '节点同步完成后即可发送。';

  @override
  String get deskOvAvailable => '可用余额';

  @override
  String deskOvAsOfBlock(String block) {
    return '截至区块 $block';
  }

  @override
  String get deskOvEmptyHint => '分享 Epicbox 地址，接收你的第一笔 EPIC。';

  @override
  String get deskOvFiatNote => '  全部余额，CoinGecko';

  @override
  String get deskOvBreakTotal => '总额';

  @override
  String get deskOvBreakConfirming => '确认中';

  @override
  String get deskOvBreakImmature => '未成熟';

  @override
  String get deskOvBreakAwaiting => '等待完成';

  @override
  String get deskOvBreakLocked => '发送中锁定';

  @override
  String get deskOvUpdating => '正在更新';

  @override
  String get deskOvHiddenAmount => '金额已隐藏';

  @override
  String get deskOvLoading => '正在加载交易';

  @override
  String get deskOvEmptyTitle => '暂无交易';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '收到的 EPIC 会先在这里显示为确认中，$blocks 个区块后变为可用。',
    );
    return '$_temp0';
  }

  @override
  String get deskOvShowAddress => '显示地址';

  @override
  String get deskOvReceiveFile => '接收文件';

  @override
  String get deskOvRecent => '最近活动';

  @override
  String deskOvViewAll(int count) {
    return '查看全部 $count 笔';
  }

  @override
  String deskOvPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔文件发送未完成',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => '使用接收方发回的回复文件完成交易。';

  @override
  String get deskOvFinalize => '完成交易';

  @override
  String get deskTxMethodFile => '直接 · 文件';

  @override
  String get deskTxMiningReward => '挖矿奖励';

  @override
  String get deskTxReceived => '已收到';

  @override
  String get deskTxSent => '已发送';

  @override
  String get deskTxUnknownSender => '未知发送方';

  @override
  String get deskTxUnknownRecipient => '未知接收方';

  @override
  String get deskTxNoteBlock => '区块时间。未记录发送方。';

  @override
  String get deskTxNoteScanTime => '扫描时间；无法读取区块时间。未记录发送方。';

  @override
  String get deskTxNoteUnknown => '未记录发送方。';

  @override
  String get deskTxFoundRestoredLabel => '已恢复';

  @override
  String get deskTxFoundRestoredLine => '恢复时找到';

  @override
  String get deskTxFoundRestoredStep => '恢复此钱包时找到';

  @override
  String get deskTxFoundRestoredTip => '恢复此钱包时在区块链上找到。未记录发送方。';

  @override
  String get deskTxFoundRescanLabel => '扫描找到';

  @override
  String get deskTxFoundRescanLine => '核对余额时找到';

  @override
  String get deskTxFoundRescanStep => '核对余额时找到';

  @override
  String get deskTxFoundRescanTip => '核对余额时在区块链上找到。未记录发送方。';

  @override
  String get deskTxFoundScanLine => '扫描时找到';

  @override
  String get deskTxFoundScanStep => '扫描时找到';

  @override
  String get deskTxFoundScanTip => '扫描时在区块链上找到。未记录发送方。';

  @override
  String get deskTxBackupTip => '从交易记录备份中添加。';

  @override
  String get deskTxFromBackup => '来自备份';

  @override
  String get deskTxStatusImmature => '未成熟';

  @override
  String get deskTxStatusWaitingSender => '等待发送方完成';

  @override
  String get deskTxStatusWaitingResponseFile => '等待回复文件';

  @override
  String get deskTxStatusWaitingRecipient => '等待接收方签名';

  @override
  String get deskTxStatusWaitingBlock => '等待打包进区块';

  @override
  String deskTxStatusConfirming(int confirmations, int needed) {
    return '确认中 $confirmations/$needed';
  }

  @override
  String get deskTxStatusCancelled => '已取消';

  @override
  String get deskTxToday => '今天';

  @override
  String get deskTxYesterday => '昨天';

  @override
  String deskTxDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String deskTxTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String deskTxDayToday(String date) {
    return '今天 · $date';
  }

  @override
  String deskTxDayYesterday(String date) {
    return '昨天 · $date';
  }

  @override
  String deskTxFee(String amount) {
    return '手续费 $amount';
  }

  @override
  String get deskTxPaymentProof => '付款证明';

  @override
  String get deskTxFinalize => '完成交易';

  @override
  String deskTxSemReceived(String amount, String who, String status) {
    return '已收到 $amount，$who，$status';
  }

  @override
  String deskTxSemSent(String amount, String who, String status) {
    return '已发送 $amount，$who，$status';
  }

  @override
  String deskTxSemKind(String kind, String amount, String who, String status) {
    return '$kind $amount，$who，$status';
  }

  @override
  String get deskTxHiddenAmount => '金额已隐藏';

  @override
  String get deskTxNowBackup => '来自备份；未向区块链查询。';

  @override
  String deskTxNowImmature(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已确认，但挖矿奖励需要 $count 个确认后才能使用。',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender => '已签名并发回。等待发送方完成。';

  @override
  String get deskTxNowWaitingResponseFile => '等待回复文件。文件到达后完成交易。';

  @override
  String get deskTxNowWaitingRecipient => '等待接收方签名。交易完成前，资金不会离开钱包。';

  @override
  String get deskTxNowPosted => '已广播到网络，等待打包进区块。';

  @override
  String deskTxNowConfirming(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: '已进入区块，$confirmations/$needed 个确认。',
    );
    return '$_temp0';
  }

  @override
  String deskTxNowConfirmed(int confirmations) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '已确认，$confirmations 个确认。',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => '已取消。';

  @override
  String get deskTxNotCancelled => '未取消';

  @override
  String get deskTxCancelled => '交易已取消';

  @override
  String get deskTxCancelling => '正在取消';

  @override
  String get deskTxHeadRestored => '恢复时找到';

  @override
  String get deskTxHeadFoundOnChain => '在区块链上找到';

  @override
  String get deskTxHeadBackup => '从交易记录备份中添加';

  @override
  String deskTxHeadFrom(String who) {
    return '来自 $who';
  }

  @override
  String deskTxHeadTo(String who) {
    return '发往 $who';
  }

  @override
  String get deskTxSubProgress => '进度';

  @override
  String get deskTxSubDetails => '详情';

  @override
  String get deskTxFactDate => '日期';

  @override
  String get deskTxFactFrom => '来自';

  @override
  String get deskTxFactTo => '发往';

  @override
  String get deskTxCopyAddress => '复制地址';

  @override
  String get deskTxFactMethod => '方式';

  @override
  String get deskTxFactAmount => '金额';

  @override
  String get deskTxFactFee => '手续费';

  @override
  String get deskTxFactTotal => '总计';

  @override
  String get deskTxFactMessage => '留言';

  @override
  String get deskTxSignedByRecipient => '接收方已签名';

  @override
  String get deskTxProofView => '查看';

  @override
  String get deskTxTechTitle => '技术详情';

  @override
  String get deskTxTechId => 'ID';

  @override
  String get deskTxTechSlate => 'Slate ID';

  @override
  String get deskTxCopySlate => '复制 Slate ID';

  @override
  String get deskTxTechHeight => '高度';

  @override
  String get deskTxTechKernel => '内核';

  @override
  String get deskTxTechConfirmed => '已确认';

  @override
  String get deskTxTechCredited => '转入';

  @override
  String get deskTxTechDebited => '转出';

  @override
  String get deskTxTechStatus => '状态';

  @override
  String get deskTxTechType => '类型';

  @override
  String get deskTxStepMined => '已挖出区块';

  @override
  String get deskTxStepSpendable => '可用';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还需 $count 个区块',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => '已收到 Slate';

  @override
  String get deskTxStepCreated => '已创建并签名';

  @override
  String get deskTxStepSignedReturned => '已签名并发回';

  @override
  String get deskTxStepWaitingFile => '等待回复文件';

  @override
  String get deskTxStepWaitingRecipient => '等待接收方';

  @override
  String get deskTxStepPosted => '已广播到网络';

  @override
  String get deskTxStepConfirming => '确认中';

  @override
  String deskTxStepProgress(int confirmations, int needed) {
    return '$confirmations/$needed';
  }

  @override
  String get deskTxCancelIncomingTitle => '取消这笔付款？';

  @override
  String get deskTxCancelOutgoingTitle => '取消这笔发送？';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '来自 $who 的 $amount EPIC 将从你的余额中移除。钱包会先询问节点；如果这笔付款已在节点的交易池或区块中，则拒绝取消。如果发送方之后广播了它，款项仍可能到账。';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '发往 $who 的 $amount EPIC。锁定的金额会退回余额。如果接收方已经完成了这笔交易，它仍可能被确认。';
  }

  @override
  String get deskTxCancelKeep => '保留';

  @override
  String get deskTxCancelIncomingAction => '取消付款';

  @override
  String get deskTxCancelOutgoingAction => '取消发送';

  @override
  String deskTxProofIncoming(String amount) {
    return '证明本钱包在此内核中收到了 $amount EPIC。';
  }

  @override
  String deskTxProofOutgoing(String amount) {
    return '证明接收方在此内核中收到了 $amount EPIC。';
  }

  @override
  String get deskTxProofSenderAddress => '发送方地址';

  @override
  String get deskTxProofRecipientAddress => '接收方地址';

  @override
  String get deskTxProofRecipientSignature => '接收方签名';

  @override
  String get deskTxProofCopyKernel => '复制内核';

  @override
  String get deskTxProofCopySender => '复制发送方地址';

  @override
  String get deskTxProofCopyRecipient => '复制接收方地址';

  @override
  String get deskTxProofCopySignature => '复制接收方签名';

  @override
  String get deskTxProofExport => '导出';

  @override
  String get deskTxProofSaved => '证明已保存';

  @override
  String get deskOnbWelcomeAdd => '添加钱包';

  @override
  String get deskOnbWelcomeTagline => '密钥和币都保存在这台电脑上，由密码锁定。';

  @override
  String get deskOnbWelcomeCreate => '创建新钱包';

  @override
  String get deskOnbWelcomeCreateSub => '新的助记词';

  @override
  String get deskOnbWelcomeImport => '导入钱包';

  @override
  String get deskOnbWelcomeImportSub => '从旧版 Epic Wallet 或文件夹导入';

  @override
  String get deskOnbWelcomeRestore => '用助记词恢复';

  @override
  String get deskOnbWelcomeRestoreSub => '使用助记词';

  @override
  String get deskOnbWelcomeTestNote => '新钱包将创建在此测试网络上。';

  @override
  String get deskOnbWelcomeBack => '返回解锁';

  @override
  String get deskOnbWelcomeAdvanced => '高级';

  @override
  String get deskOnbWelcomeNetwork => '网络';

  @override
  String get deskOnbWelcomeNetworkHelp =>
      'Mainnet 上是真实的 EPIC。Floonet 和 Usernet 是测试网络。';

  @override
  String get deskOnbWelcomeFolder => '应用数据文件夹';

  @override
  String get deskOnbWelcomeHideDetails => '隐藏详情';

  @override
  String get deskOnbWelcomeMoreAbout => '了解更多';

  @override
  String get deskOnbWelcomeFolderWhere => '应用保存钱包和设置的位置。';

  @override
  String get deskOnbWelcomeFolderDetail =>
      '使用本地节点时，区块链也保存在这里。新文件夹必须是空的：应用会在其中创建自己的文件夹，并一直使用它。';

  @override
  String deskOnbWelcomeUsing(String folder) {
    return '正在使用 $folder。应用将重启以使用它。';
  }

  @override
  String get deskOnbWelcomeLocked => '只能在添加第一个钱包之前更改。';

  @override
  String get deskOnbWelcomeChooseFolder => '选择文件夹';

  @override
  String get deskOnbWelcomeDefaultFolder => '默认文件夹';

  @override
  String get deskOnbWelcomeFolderNotEmpty => '该文件夹不是空的。请选择一个新的空文件夹。';

  @override
  String get deskOnbWelcomeFolderIsWallet => '这是一个钱包文件夹。请选择一个新的空文件夹。';

  @override
  String get deskOnbWelcomeChoose => '选择';

  @override
  String get deskOnbStepPassword => '密码';

  @override
  String get deskOnbStepPhrase => '助记词';

  @override
  String get deskOnbCreateStageCreate => '正在创建钱包及其助记词';

  @override
  String get deskOnbCreateStageSave => '正在保存账户';

  @override
  String get deskOnbCreateNotCreated => '钱包未创建';

  @override
  String get deskOnbCreateCreating => '正在创建钱包';

  @override
  String deskOnbCreateTestLead(String network) {
    return '$network 上的钱包，这是一个测试网络。';
  }

  @override
  String get deskOnbCreateFailedTitle => '无法创建钱包';

  @override
  String get deskOnbCreateDiskFull => '无法保存账户：磁盘已满。';

  @override
  String get deskOnbCreateWait => '这最多需要一分钟。请保持应用打开。';

  @override
  String get deskOnbCreateLocking => '正在锁定已打开的钱包';

  @override
  String get deskOnbCreateSide => '新钱包';

  @override
  String get deskOnbCreateTitle => '创建钱包';

  @override
  String get deskOnbCreateLead => '密码用于在这台电脑上解锁此钱包。它不能找回币；下一步的助记词才能。';

  @override
  String get deskOnbCreateTestNote => '测试网络上的钱包，不用于真实的 EPIC';

  @override
  String get deskOnbCreatePhraseLead => '如果这台电脑坏了，这些单词是找回币的唯一方法。请按顺序抄写在纸上。';

  @override
  String get deskOnbCreateRevealFirst => '请先显示助记词';

  @override
  String get deskOnbCreateWarn => '任何拿到这些单词的人都能拿走你的币';

  @override
  String get deskOnbCreateReveal => '显示助记词';

  @override
  String get deskOnbCreateCheckScreen => '请确认没有人能看到屏幕。';

  @override
  String get deskOnbCreateHide => '隐藏';

  @override
  String get deskOnbCreateShowQr => '显示二维码';

  @override
  String get deskOnbCreateHideQr => '隐藏二维码';

  @override
  String get deskOnbCreateQrWarn => '任何扫描此二维码的人都能拿走你的币';

  @override
  String get deskOnbCreateQrWarnText => '只扫描到你信任的另一个钱包中。';

  @override
  String get deskOnbCreateQrLabel => '助记词二维码';

  @override
  String deskOnbCreateWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个单词',
    );
    return '已抄写：全部 $_temp0都写在纸上';
  }

  @override
  String get deskOnbRestoreDone => '钱包已恢复。';

  @override
  String get deskOnbRestoreNotRestored => '钱包未恢复';

  @override
  String get deskOnbRestoreRestoring => '正在恢复钱包';

  @override
  String get deskOnbRestoreFailedTitle => '无法恢复钱包';

  @override
  String get deskOnbRestorePermission =>
      '无法写入钱包文件：~/.config/Epic Cash Desktop 权限被拒绝。';

  @override
  String get deskOnbRestoreWait => '这最多需要一分钟。首次扫描区块链后会显示余额。';

  @override
  String get deskOnbRestoreSide => '恢复钱包';

  @override
  String get deskOnbRestoreChoosePassword => '设置密码';

  @override
  String deskOnbRestorePasswordLead(int count) {
    return '这 $count 个单词的助记词有效。请设置在这台电脑上解锁此钱包的密码。';
  }

  @override
  String get deskOnbRestoreNothingToPaste => '没有可粘贴的内容：剪贴板中没有单词。';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return '第 $position 个单词“$word”不在词表中。';
  }

  @override
  String deskOnbRestoreAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部 $count 个单词均有效。',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreStaysHere => '助记词不会离开这台电脑。';

  @override
  String get deskOnbRestoreChecksumFirm => '此助记词的校验位不匹配。请把每个单词与纸上的逐一核对。';

  @override
  String deskOnbRestoreChecksumSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已输入 $count 个单词；校验位不匹配。请继续输入，或把每个单词与纸上的逐一核对。',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWordsLead =>
      '按顺序输入这些单词，或把整段助记词粘贴到任意一个框中。换行、逗号和编号会被忽略。';

  @override
  String get deskOnbRestoreClear => '清空';

  @override
  String deskOnbRestoreUseWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '使用这 $count 个单词',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWords => '单词';

  @override
  String deskOnbRestoreFilledOf(int filled, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 个单词',
    );
    return '$filled/$_temp0';
  }

  @override
  String get deskOnbKillTitle => 'Epic 已在运行';

  @override
  String get deskOnbKillBody => '另一个钱包或节点进程正在使用钱包文件和端口。关闭它即可在这里解锁，或取消后自己关闭它。';

  @override
  String get deskOnbKillProcesses => '正在运行的进程';

  @override
  String get deskOnbKillRoleWallet => '钱包服务';

  @override
  String get deskOnbKillRoleNode => '节点';

  @override
  String get deskOnbKillNote => '关闭它们会中止它们正在做的事，例如节点同步或接收付款。解锁后它们会由本应用重新启动。';

  @override
  String get deskOnbKillClosing => '正在关闭…';

  @override
  String get deskOnbKillClose => '关闭并解锁';

  @override
  String get deskOnbSameTitle => '此钱包已在这里';

  @override
  String get deskOnbSameBody => '此助记词属于列表中的一个钱包。没有添加任何内容。';

  @override
  String get deskOnbSameWallet => '钱包';

  @override
  String get deskOnbSameNote => '“打开”会要求输入该钱包的密码。“取消”会把助记词保留在输入框中。';

  @override
  String get deskOnbSameOpen => '打开';

  @override
  String get deskOnbUnlockWhoWindows => '使用此 Windows 账户的任何人都能打开此钱包。';

  @override
  String get deskOnbUnlockWho => '使用此账户的任何人都能打开此钱包。';

  @override
  String get deskOnbUnlockWrong => '密码错误。请检查大写锁定键和键盘布局。';

  @override
  String get deskOnbUnlockPortInUse => '钱包服务未能启动：端口 3415 被其他程序占用。';

  @override
  String get deskOnbUnlockStageCheck => '正在检查钱包文件';

  @override
  String get deskOnbUnlockStageProcesses => '正在查找仍在运行的钱包进程';

  @override
  String get deskOnbUnlockStageClosing => '正在关闭旧的钱包进程';

  @override
  String get deskOnbUnlockStageWallet => '正在启动钱包服务';

  @override
  String get deskOnbUnlockStageUnlock => '正在解锁钱包';

  @override
  String get deskOnbUnlockEnter => '请输入密码';

  @override
  String get deskOnbUnlockCloseOthers => '请关闭其他 Epic 进程，然后解锁。';

  @override
  String get deskOnbUnlockRememberedUnavailable => '无法使用记住的密码。请输入密码。';

  @override
  String get deskOnbUnlockRememberedForgotten => '记住的密码已失效。请输入密码。';

  @override
  String get deskOnbUnlockNotRemembered => '未记住';

  @override
  String get deskOnbUnlockKeyStore => '这台电脑的密钥库不可用。';

  @override
  String get deskOnbUnlockThisWallet => '此钱包';

  @override
  String get deskOnbUnlockFailed => '解锁失败';

  @override
  String get deskOnbUnlockFailedLead => '钱包没有打开。原因见下方。';

  @override
  String get deskOnbUnlockFailedBox => '钱包没有打开';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return '正在解锁 $name';
  }

  @override
  String get deskOnbUnlockStepsLead => '每一步完成后都会显示。';

  @override
  String get deskOnbUnlockNote => '随后会打开概览，并在后台完成其余工作：连接节点、更新余额、开启接收。';

  @override
  String get deskOnbUnlockTitle => '解锁钱包';

  @override
  String get deskOnbUnlockLead => '密钥只保存在这台电脑上。';

  @override
  String get deskOnbUnlockRemember => '在这台电脑上记住';

  @override
  String deskOnbUnlockRememberFor(String who) {
    return '保留 30 天。$who';
  }

  @override
  String get deskOnbUnlockMissingTitle => '此钱包的文件夹不见了';

  @override
  String deskOnbUnlockMissingText(String folder) {
    return '原位置：$folder';
  }

  @override
  String get deskOnbUnlockRemove => '移除';

  @override
  String get deskOnbUnlockTryAgain => '重试';

  @override
  String get deskOnbUnlockButton => '解锁';

  @override
  String get deskOnbNodeFreeUnknown => '可用空间未知';

  @override
  String deskOnbNodeFreeHere(String size) {
    return '此处可用 $size';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return '目前约占用 $size 磁盘空间';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return '目前占用 $size 磁盘空间';
  }

  @override
  String get deskOnbNodeSeparate => '独立程序';

  @override
  String get deskOnbNodeSeparateText => '钱包会启动 Epic 节点，并在应用关闭时停止它。';

  @override
  String get deskOnbNodeFirewall => 'Windows 会询问一次';

  @override
  String get deskOnbNodeFirewallText => '是否允许它通过防火墙。请在专用网络上允许。';

  @override
  String deskOnbNodeGrowing(String free) {
    return '并缓慢增长。$free。';
  }

  @override
  String get deskOnbNodeHours => '同步需要数小时';

  @override
  String get deskOnbNodeHoursText =>
      '首次同步在一般网络下需要 2 到 6 小时。钱包会显示进度，期间可以使用公共节点。';

  @override
  String get deskOnbNodeDownload => '下载约 4 GB';

  @override
  String get deskOnbNodeDownloadText => '首次下载这么多，之后每天下载少量数据。';

  @override
  String get deskOnbNodeFound => '已找到';

  @override
  String deskOnbNodeFoundAt(String version, String address) {
    return 'Epic $version，位于 $address';
  }

  @override
  String deskOnbNodeHeight(String height) {
    return '高度 $height';
  }

  @override
  String get deskOnbNodeSynced => '已同步';

  @override
  String get deskOnbNodeNoAnswer => '没有节点响应';

  @override
  String deskOnbNodeNoAnswerAt(String address) {
    return '地址 $address。请启动节点，或检查地址和端口。';
  }

  @override
  String get deskOnbNodeExisting => '使用这台电脑上已在运行的节点';

  @override
  String get deskOnbNodeExistingText => 'Epic GUI 或 CLI 节点。钱包会连接到它，不会启动任何程序。';

  @override
  String get deskOnbNodeAddress => '本机节点的地址';

  @override
  String get deskOnbNodeCheck => '检查';

  @override
  String get deskOnbNodeBundled => '启动内置节点';

  @override
  String get deskOnbNodeBundledText =>
      '把区块链下载并同步到钱包自己的文件夹中。在最后一步点击“保存”之前不会下载任何内容。';

  @override
  String deskOnbNodeFallback(String host) {
    return '本地节点同步完成前使用 $host。之后本地节点会自动接替。';
  }

  @override
  String get deskOnbNodeDialogTitle => '本地节点';

  @override
  String get deskOnbNodeDialogBody => '在这里运行节点意味着什么，以及使用哪个节点。';

  @override
  String get deskOnbNodeUseThis => '使用此节点';

  @override
  String get deskOnbNodeStart => '启动本地节点';

  @override
  String deskOnbRestorePasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已粘贴 $count 个单词；助记词应为 12、15、18、21 或 24 个单词',
    );
    return '$_temp0';
  }

  @override
  String deskOnbWordN(int number) {
    return '第 $number 个单词';
  }

  @override
  String get deskOnbImportEnterOld => '请输入旧密码';

  @override
  String deskOnbImportNewShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个字符',
    );
    return '新密码：至少 $_temp0';
  }

  @override
  String get deskOnbImportNewDiffer => '两次输入的新密码不一致';

  @override
  String deskOnbImportWalletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个钱包',
    );
    return '$_temp0';
  }

  @override
  String deskOnbImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已导入 $count 个钱包。',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFindingTitle => '正在查找钱包';

  @override
  String get deskOnbImportFindingLead =>
      '正在搜索旧版 Epic Wallet 和 epic 程序的文件夹。不会改动任何内容。';

  @override
  String deskOnbImportFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '找到 $count 个钱包',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFoundLead => '旧文件夹只会被读取。';

  @override
  String get deskOnbImportNoneTitle => '未找到钱包';

  @override
  String get deskOnbImportNoneLead => '请选择钱包文件夹，或用助记词恢复。';

  @override
  String get deskOnbImportChooseTitle => '选择钱包';

  @override
  String get deskOnbImportChooseLead => '勾选的钱包会添加到应用中。交易记录会通过扫描重建。';

  @override
  String get deskOnbImportCheckTitle => '检查是否被占用';

  @override
  String get deskOnbImportCheckLead => '被其他程序占用的钱包不会导入。';

  @override
  String get deskOnbImportTitle => '导入';

  @override
  String get deskOnbImportLead => '每个钱包会要求输入一次它的旧密码。';

  @override
  String get deskOnbImportDoneTitle => '钱包已导入';

  @override
  String get deskOnbImportDoneLead => '每个钱包首次解锁时会扫描区块链以获取交易记录。';

  @override
  String deskOnbImportSelected(int selected, int total) {
    return '已选择 $selected/$total';
  }

  @override
  String get deskOnbImportChecking => '正在检查…';

  @override
  String get deskOnbImportCloseOther => '请关闭另一个程序，或跳过此钱包';

  @override
  String deskOnbImportImportedOf(int done, int total) {
    return '已导入 $done/$total';
  }

  @override
  String get deskOnbImportOpen => '打开钱包';

  @override
  String get deskOnbImportStepFind => '查找';

  @override
  String get deskOnbImportStepChoose => '选择';

  @override
  String get deskOnbImportStepCheck => '检查';

  @override
  String get deskOnbImportBack => '返回';

  @override
  String get deskOnbImportSkip => '跳过';

  @override
  String get deskOnbImportOlder => '旧版 Epic Wallet';

  @override
  String get deskOnbImportOlderSub => '账户和文件夹';

  @override
  String get deskOnbImportEpicProgram => 'epic 程序';

  @override
  String get deskOnbImportSearching => '正在搜索…';

  @override
  String get deskOnbImportRestore => '用助记词恢复';

  @override
  String deskOnbImportLastUsed(String date) {
    return '上次使用：$date';
  }

  @override
  String deskOnbImportSecondCopy(String reason) {
    return '$reason。勾选即可再添加一份副本。';
  }

  @override
  String deskOnbImportCannot(String name) {
    return '$name：无法导入';
  }

  @override
  String get deskOnbImportInApp => '已在应用中';

  @override
  String get deskOnbImportSameWallet => '同一个钱包';

  @override
  String get deskOnbImportNotInUse => '未被占用';

  @override
  String get deskOnbImportNotChecked => '未检查';

  @override
  String get deskOnbImportSkipped => '已跳过';

  @override
  String get deskOnbImportInUse => '被占用';

  @override
  String get deskOnbImportInUseText =>
      '正被其他程序使用。请关闭旧版 Epic Wallet 或 epic 程序，然后重新检查。';

  @override
  String get deskOnbImportCheckAgain => '重新检查';

  @override
  String get deskOnbImportImported => '已导入';

  @override
  String get deskOnbImportImporting => '正在导入…';

  @override
  String get deskOnbImportWaiting => '等待中';

  @override
  String get deskOnbImportOldPassword => '旧密码';

  @override
  String deskOnbImportOldHelp(String name) {
    return '$name 在旧应用中的密码。';
  }

  @override
  String deskOnbImportOldOf(String name) {
    return '$name 的旧密码';
  }

  @override
  String deskOnbImportOldShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '至少 $count 个字符。',
    );
    return '旧密码太短。请设置一个新密码，$_temp0';
  }

  @override
  String get deskOnbImportNewPassword => '新密码';

  @override
  String get deskOnbImportRepeat => '重复';

  @override
  String get deskOnbImportRepeatNew => '再次输入新密码';

  @override
  String get deskOnbImportUnchanged => '旧文件夹未改动。旧应用仍可打开它们。';

  @override
  String get deskOnbImportStopTitle => '停止导入？';

  @override
  String get deskOnbImportStopBody => '已导入的钱包会被移除。旧文件夹不会改动。';

  @override
  String get deskOnbImportGoBack => '返回';

  @override
  String get deskOnbImportStop => '停止导入';

  @override
  String get deskRailWaitingTor => '等待 Tor';

  @override
  String get deskRailOn => '开启';

  @override
  String get deskRailConnecting => '正在连接';

  @override
  String get deskRailSlow => '较慢';

  @override
  String get deskRailNotAnswering => '无响应';

  @override
  String get deskRailOff => '关闭';

  @override
  String get deskRailChecking => '正在检查';

  @override
  String get deskRailOverTor => '经由 Tor';

  @override
  String get deskRailWaitsForTor => '等 Tor 连接后再连接。';

  @override
  String get deskRailPaymentsWait => '付款暂存在 Epicbox 服务器上。';

  @override
  String get deskRailOpenEpicbox => '打开 Epicbox 接收设置';

  @override
  String get deskRailStarting => '正在启动';

  @override
  String get deskRailNotReceiving => '无法接收';

  @override
  String get deskRailOnInternet => '开启 · 互联网';

  @override
  String get deskRailOnLocal => '开启 · 本地';

  @override
  String get deskRailPortInUse => '端口被占用';

  @override
  String get deskRailStopped => '已停止';

  @override
  String deskRailPortInternet(String port) {
    return '端口 $port · 可从互联网访问';
  }

  @override
  String deskRailPortLocal(String port) {
    return '端口 $port · 仅限本机';
  }

  @override
  String get deskRailOpenHttp => '打开 链接 · HTTP 接收设置';

  @override
  String get deskRailTorNotInBuild => '此版本不含 Tor';

  @override
  String get deskRailStartingDots => '正在启动…';

  @override
  String deskRailTorSlow(String problem) {
    return '$problem。发送不受影响。';
  }

  @override
  String get deskRailTorNoAddress => 'Tor 地址尚未发布';

  @override
  String get deskRailOpenPrivacy => '打开隐私设置';

  @override
  String get deskRailNode => '节点';

  @override
  String get deskRailOpenNode => '打开节点设置';

  @override
  String get deskAppNodeSyncedTitle => '本地节点已同步';

  @override
  String get deskAppNodeSyncedBody => '本地节点已拥有完整的区块链，现在可以使用。应用将重启以切换到本地节点。';

  @override
  String get deskAppNotNow => '以后再说';

  @override
  String get deskAppRestartNow => '立即重启';

  @override
  String get deskAppFirstScanTitle => '钱包首次扫描';

  @override
  String get deskAppFirstScanBody => '钱包正在区块链中查找属于它的输出。期间钱包仍可使用；扫描完成后余额会更新。';

  @override
  String get deskAppScanOutput => '扫描进度';

  @override
  String get deskAppWaitingOutput => '等待第一条输出…';

  @override
  String get deskShellNavOverview => '概览';

  @override
  String get deskShellNavActivity => '活动';

  @override
  String get deskShellNavSend => '发送';

  @override
  String get deskShellNavReceive => '接收';

  @override
  String get deskShellNavOutputs => '输出';

  @override
  String get deskShellNavContacts => '联系人';

  @override
  String get deskShellNavSettings => '设置';

  @override
  String get deskShellTitleImportTx => '导入交易';

  @override
  String get deskShellTitleFinalizeTx => '完成交易';

  @override
  String get deskShellLocksAfterSend => '付款发出后锁定';

  @override
  String get deskShellNotQuitTitle => '未退出';

  @override
  String get deskShellNotQuitBody => '正在发送一笔付款。发送完成后再退出。';

  @override
  String get deskShellLockedTitle => '钱包已锁定';

  @override
  String get deskShellLockedBody => '连接钱包核心后，“退出”才会关闭应用。';

  @override
  String deskShellLockWallet(String keys) {
    return '锁定钱包（$keys）';
  }

  @override
  String get deskShellMainNav => '主导航';

  @override
  String deskShellVersion(String version) {
    return '版本 $version';
  }

  @override
  String get deskShellOpenWalletSettings => '打开钱包设置';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return '打开钱包设置：$name';
  }

  @override
  String get deskShellSwitchWallet => '切换钱包';

  @override
  String deskShellWalletBy(String maker) {
    return '钱包出品：$maker';
  }

  @override
  String get deskTourOverviewTitle => '概览';

  @override
  String get deskTourOverviewText => '余额和仍在确认中的金额，下面是最近的交易。其他功能都在侧边栏中。';

  @override
  String get deskTourSendTitle => '发送';

  @override
  String get deskTourSendText => '向 Epicbox 地址付款，或生成交易文件让对方签名。发出前会先确认。';

  @override
  String get deskTourReceiveTitle => '接收';

  @override
  String get deskTourReceiveText =>
      '这个钱包的 Epicbox 地址：分享它即可收款。需要签名或完成的交易文件在它下方。';

  @override
  String get deskTourInvoicesTitle => '账单';

  @override
  String get deskTourInvoicesText => '支付别人发来的账单，或向欠你钱的人开具账单。用标签页在两者之间切换。';

  @override
  String get deskTourActivityTitle => '活动';

  @override
  String get deskTourActivityText => '每笔交易的进度和详情。侧边栏此项上的数字表示有事项等待你处理。';

  @override
  String get deskTourContactsTitle => '联系人';

  @override
  String get deskTourContactsText => '按名称保存的地址。“发送”从这里选择。';

  @override
  String get deskTourNodeTitle => '设置 › 节点';

  @override
  String get deskTourNodeText => '钱包从哪个节点读取区块链。其余设置页面列在左侧。';

  @override
  String get deskTourHelpTitle => '帮助';

  @override
  String get deskTourHelpText => '按分区查看主题，还有“报告问题”。每个页面的更多说明都在这里，导览也可以再次查看。';

  @override
  String deskTourCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get deskTourSemantics => '钱包导览';

  @override
  String get deskTourSkip => '跳过导览';

  @override
  String get deskTourBack => '上一步';

  @override
  String get deskTourNext => '下一步';

  @override
  String get deskKitUnknown => '未知';

  @override
  String get deskKitRingCancelled => '已取消';

  @override
  String get deskKitRingConfirmed => '已确认';

  @override
  String deskKitRingProgress(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '$confirmations/$needed 个确认',
    );
    return '$_temp0';
  }

  @override
  String get deskKitHiddenAmount => '金额已隐藏';

  @override
  String get deskKitChooseFile => '选择文件';

  @override
  String deskKitNeedAction(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项待处理',
    );
    return '$label，$_temp0';
  }

  @override
  String get deskKitHealthOn => '开启';

  @override
  String get deskKitHealthSlow => '较慢';

  @override
  String get deskKitHealthOffline => '离线';

  @override
  String get deskKitHealthOff => '关闭';

  @override
  String get deskKitHealthChecking => '正在检查';

  @override
  String get deskKitCloseEsc => '关闭（Esc）';

  @override
  String get deskKitOptional => '可选';

  @override
  String get deskKitBackAlt => '返回（Alt+左方向键）';

  @override
  String deskKitStepOf(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get deskKitHeroCaptionEpicbox => '由 EPICBOX 服务器暂存';

  @override
  String get deskKitHeroCaptionHttp => '直达对方钱包';

  @override
  String get deskKitHeroCaptionTor => '经由 TOR 直达';

  @override
  String get deskKitHeroCaptionFile => '发出文件，收回回复';

  @override
  String get deskKitHeroLabelEpicbox =>
      'Epicbox：付款发送到 Epicbox 服务器，由服务器暂存，直到接收方的钱包重新上线';

  @override
  String get deskKitHeroLabelHttp => '链接 · HTTP：付款直接发送到对方钱包，对方钱包必须处于打开状态';

  @override
  String get deskKitHeroLabelTor => '链接 · Tor：付款经由 Tor 网络直接发送到对方钱包';

  @override
  String get deskKitHeroLabelFile => '直接 · 文件传输：交出交易文件，收回回复文件，然后由发送方完成';

  @override
  String get deskKitReachCheck => '检查';

  @override
  String get deskKitReachChecking => '正在从互联网检查…';

  @override
  String get deskKitReachNoIpTitle => '未找到公网 IP';

  @override
  String get deskKitReachNoIpText => '无法从互联网获取。请稍后重试。';

  @override
  String deskKitReachNoIpTextLan(String address) {
    return '无法从互联网获取。请稍后重试。在你的局域网中：$address。';
  }

  @override
  String get deskKitReachClosedTitle => '无法从互联网访问';

  @override
  String deskKitReachClosedText(String port) {
    return '在路由器上把 TCP 端口 $port 转发到这台电脑，然后再检查一次。';
  }

  @override
  String deskKitReachClosedTextLan(String port, String address) {
    return '在路由器上把 TCP 端口 $port 转发到这台电脑（$address），然后再检查一次。';
  }

  @override
  String get deskKitReachUnknownTitle => '无法确定是否可访问';

  @override
  String get deskKitReachUnknownText => '端口检查服务没有响应。请稍后重试。';

  @override
  String deskKitReachUnknownTextLan(String address) {
    return '端口检查服务没有响应。请稍后重试。在你的局域网中：$address。';
  }

  @override
  String get deskKitReachOpenTitle => '可从互联网访问';

  @override
  String deskKitReachOpenText(String port) {
    return '端口 $port 已转发。';
  }

  @override
  String deskKitReachOpenTextLan(String port, String address) {
    return '端口 $port 已转发。在你的局域网中：$address。';
  }

  @override
  String deskKitAgeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒前',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String get deskKitNodeBefore410 => '节点版本低于 4.1.0';

  @override
  String get deskKitNodeNoAnswer => '无响应';

  @override
  String get deskKitNodesDisagree => '各节点的最新区块不一致';

  @override
  String deskKitNodesAgree(String height) {
    return '各节点一致：$height';
  }

  @override
  String deskKitNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up/$total 个节点在线',
    );
    return '$_temp0';
  }

  @override
  String deskKitEpicboxUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up/$total 个 Epicbox 服务器在线',
    );
    return '$_temp0';
  }

  @override
  String deskKitLastBlock(String age) {
    return '上一个区块 $age';
  }

  @override
  String get deskKitLimitedNetwork =>
      '无法访问 status.btlabs.uk。以下信息来自节点本身：没有可对比的最新区块，没有在线率，也没有对等节点数。';

  @override
  String get deskKitFactHeight => '高度';

  @override
  String get deskKitFactVersion => '版本';

  @override
  String get deskKitFactAccepts => '接受交易';

  @override
  String get deskKitFactYes => '是';

  @override
  String get deskKitFactNotYet => '尚未';

  @override
  String get deskKitFactUnknown => '未知';

  @override
  String get deskKitFactLatency => '延迟';

  @override
  String get deskKitFactUptime => '在线率';

  @override
  String get deskKitFactPeers => '对等节点';

  @override
  String get deskKitFactOperator => '运营方';

  @override
  String get deskKitAtTip => '已是最新';

  @override
  String deskKitBehind(int count, String blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '落后 $blocks 个区块',
    );
    return '$_temp0';
  }

  @override
  String deskKitVersionOut(String version) {
    return '$version 已发布';
  }

  @override
  String get deskKitVersionLatest => '最新版';

  @override
  String get deskKitUptimeWindow => '过去 24 小时';

  @override
  String deskKitAtTime(String time) {
    return '于 $time';
  }

  @override
  String get deskKitListedOfficial => '官方列表';

  @override
  String deskKitSourceChecked(String time) {
    return 'status.btlabs.uk，检查于 $time';
  }

  @override
  String deskKitLatencyMeasured(String where) {
    return '延迟测量：$where';
  }

  @override
  String deskKitSiteLastReached(String time) {
    return '上次访问状态网站：$time';
  }

  @override
  String deskKitSince(String time) {
    return '自 $time 起';
  }

  @override
  String deskKitNodeSemantics(String status, String host) {
    return '节点$status：$host';
  }

  @override
  String get deskKitNodeDownTitle => '节点无响应。';

  @override
  String deskKitNodeDownText(String host) {
    return '切换到 $host？这是状态最好的其他节点。';
  }

  @override
  String get deskKitSwitch => '切换';

  @override
  String get deskKitLimitedInfo => '信息有限';

  @override
  String get deskKitFromStatusSite => '来自 status.btlabs.uk';

  @override
  String get deskKitOverTor => '经由 Tor';

  @override
  String get deskKitFromThisComputer => '来自这台电脑';

  @override
  String deskKitNodeUse(String host) {
    return '使用 $host';
  }

  @override
  String deskKitNodeUseOperator(String host, String operator) {
    return '使用 $host，$operator';
  }

  @override
  String deskKitNodeUseDown(String host) {
    return '使用 $host，无响应';
  }

  @override
  String deskKitNodeUseOperatorDown(String host, String operator) {
    return '使用 $host，$operator，无响应';
  }

  @override
  String deskKitLocalNodeUse(String state) {
    return '使用本地节点，$state';
  }

  @override
  String get deskKitLocalNode => '本地节点';

  @override
  String get deskKitMethodWaitingTor => '等待 Tor';

  @override
  String deskKitMethodTorNotConnected(String host) {
    return '$host。Tor 未连接。';
  }

  @override
  String get deskKitMethodOn => '开启';

  @override
  String deskKitMethodOverTor(String host) {
    return '$host，经由 Tor';
  }

  @override
  String get deskKitMethodOff => '关闭';

  @override
  String get deskKitMethodEpicboxOffDetail => '发往此地址的付款暂存在 Epicbox 服务器上。';

  @override
  String get deskKitMethodConnecting => '正在连接';

  @override
  String get deskKitMethodSlow => '较慢';

  @override
  String get deskKitMethodNotAnswering => '无响应';

  @override
  String deskKitMethodEpicboxDown(String host) {
    return '$host。付款暂存在 Epicbox 服务器上。';
  }

  @override
  String get deskKitMethodHttpOffDetail => '本钱包打开时，直接从另一个钱包接收。';

  @override
  String get deskKitMethodStarting => '正在启动…';

  @override
  String deskKitMethodHttpInternet(String port) {
    return '可从互联网访问，端口 $port';
  }

  @override
  String get deskKitMethodHttpLocal => '仅限本机（127.0.0.1）';

  @override
  String get deskKitMethodNotReceiving => '无法接收';

  @override
  String deskKitMethodPortInUse(String port) {
    return '端口 $port 被其他程序占用。请关闭该程序，或在设置中选择其他端口。';
  }

  @override
  String get deskKitMethodNotInBuild => '此版本不含 Tor';

  @override
  String get deskKitMethodTorOffDetail => '更慢，但更私密。在部分国家被封锁或不被允许。';

  @override
  String get deskKitMethodTorPublishing => '正在发布 Tor 地址…';

  @override
  String get deskKitMethodTorConnecting => '正在连接 Tor…';

  @override
  String get deskKitMethodTorOnDetail => '可通过 Tor 地址访问';

  @override
  String get deskKitMethodTorNotPublished => '未发布';

  @override
  String deskKitMethodTorSendsWork(String reason) {
    return '$reason。发送不受影响。';
  }

  @override
  String get deskKitMethodTorNotReachableYet => 'Tor 地址暂时无法访问';

  @override
  String get deskKitMethodTorStopped => '已停止';

  @override
  String get deskKitMethodTorStoppedDetail => 'Tor 已停止。';

  @override
  String get deskKitMethodFiles => '直接 · 文件传输';

  @override
  String get deskKitChipOverTor => '经由 Tor';

  @override
  String get deskKitChipStarting => 'Tor 启动中';

  @override
  String get deskKitChipNotConnected => 'Tor 未连接';

  @override
  String get deskKitChipNotOverTor => '不经由 Tor';

  @override
  String get deskKitPasswordNote =>
      '在本设备上根据长度以及常见词语、姓名和模式估算；假设攻击者使用高速硬件，每秒对此钱包文件尝试 100,000 次猜测。仅供参考，不作保证。';

  @override
  String get deskKitPasswordNoteLabel => '时间如何估算';

  @override
  String get deskKitNotCopied => '未复制';

  @override
  String get deskKitCopied => '已复制';

  @override
  String deskKitQrOf(String title) {
    return '$title的二维码';
  }

  @override
  String deskKitQrOfTag(String title, String tag) {
    return '$title的二维码，$tag';
  }

  @override
  String deskKitQrShowOf(String title) {
    return '显示$title的二维码';
  }

  @override
  String get deskKitQrShow => '显示二维码';

  @override
  String get deskKitQrHide => '隐藏二维码';

  @override
  String get deskKitQrHideCode => '隐藏二维码';

  @override
  String get deskSetAcctNotForgotten => '未忘记';

  @override
  String get deskSetAcctForgotten => '已在这台电脑上忘记';

  @override
  String get deskSetAcctForgottenText => '下次启动时会要求输入密码。';

  @override
  String get deskSetAcctLabelNotSaved => '名称未保存';

  @override
  String get deskSetAcctEnterLabel => '请输入名称';

  @override
  String get deskSetAcctLabelSaved => '名称已保存';

  @override
  String get deskSetAcctLabel => '名称';

  @override
  String get deskSetAcctLabelHint => '只在本应用中显示。';

  @override
  String get deskSetAcctSaveLabel => '保存名称';

  @override
  String get deskSetAcctPhraseHint => '用于恢复此钱包的单词。请妥善保密。';

  @override
  String get deskSetAcctShowPhrase => '显示助记词…';

  @override
  String get deskSetAcctRescanHint => '余额看起来不对时，重新读取区块链。';

  @override
  String get deskSetAcctRecheck => '重新核对…';

  @override
  String get deskSetAcctFiles => '文件';

  @override
  String get deskSetAcctWalletFolder => '钱包文件夹';

  @override
  String get deskSetAcctAppFiles => '应用文件';

  @override
  String get deskSetAcctAppFilesHint => '设置和日志。';

  @override
  String get deskSetAcctNetwork => '网络';

  @override
  String get deskSetAcctNetworkHint => '在创建钱包时设定。';

  @override
  String get deskSetAcctSetup => '设置向导';

  @override
  String get deskSetAcctSetupHint => '重新设置节点和接收方式。不会丢失任何内容。';

  @override
  String get deskSetAcctRunSetup => '运行设置向导…';

  @override
  String get deskSetAcctSecurity => '安全';

  @override
  String get deskSetAcctRemembered => '已在这台电脑上记住';

  @override
  String deskSetAcctRememberedHint(String who) {
    return '启动时无需密码即可打开，从设定起保留 30 天。发送时仍会要求输入密码。$who';
  }

  @override
  String get deskSetAcctForget => '忘记这台电脑';

  @override
  String get deskSetAcctPasswordHint => '用于解锁此钱包。';

  @override
  String get deskSetAcctChangePassword => '更改密码…';

  @override
  String get deskSetAcctDeleteHint => '删除它的密钥和数据库。';

  @override
  String get deskSetAcctFolderNotFound => '未找到文件夹';

  @override
  String deskSetAcctCopyPath(String title) {
    return '复制路径：$title';
  }

  @override
  String deskSetBackupWhenToday(String time) {
    return '今天 $time';
  }

  @override
  String deskSetBackupWhenYesterday(String time) {
    return '昨天 $time';
  }

  @override
  String deskSetBackupWhenDate(String day, String time) {
    return '$day $time';
  }

  @override
  String get deskSetBackupNeverExported => '从未导出。';

  @override
  String deskSetBackupLastExportNothingNew(String when) {
    return '上次导出：$when · 此后没有新内容。';
  }

  @override
  String deskSetBackupLastExportSince(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新增 $count 笔付款',
    );
    return '上次导出：$when · 此后$_temp0。';
  }

  @override
  String deskSetBackupWriteFailedHere(String reason) {
    return '无法写入该文件夹：$reason。请选择其他文件夹。';
  }

  @override
  String deskSetBackupWriteFailedIn(String folder, String reason) {
    return '无法写入 $folder：$reason。请选择其他文件夹。';
  }

  @override
  String get deskSetBackupWriteFailed => '无法写入文件。请选择其他文件夹。';

  @override
  String get deskSetBackupGroup => '备份';

  @override
  String get deskSetBackupExportTitle => '导出交易记录备份';

  @override
  String get deskSetBackupExportHint =>
      '包含付款及其详情和联系人，只有使用同一助记词的钱包才能打开此文件。仅凭助记词只能恢复余额，无法恢复这些记录。';

  @override
  String get deskSetBackupExporting => '正在导出…';

  @override
  String get deskSetBackupExportButton => '导出…';

  @override
  String get deskSetBackupImportTitle => '导入交易记录备份';

  @override
  String get deskSetBackupImportHint =>
      '把本钱包的备份合并到“活动”中。不会删除任何内容；同一文件导入两次不会有变化。';

  @override
  String get deskSetBackupImportButton => '导入…';

  @override
  String get deskSetBackupCsvTitle => '付款导出为 CSV';

  @override
  String get deskSetBackupCsvHint => '用于电子表格的普通表格。不加密，不能导入。';

  @override
  String get deskSetBackupCsvButton => '导出 CSV…';

  @override
  String get deskSetBackupSaveDialogTitle => '保存付款记录';

  @override
  String get deskSetBackupNotSaved => '未保存';

  @override
  String get deskSetBackupInFile => '文件内容';

  @override
  String deskSetBackupInFileCounts(int payments, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments 笔付款',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts 个联系人',
    );
    return '$_temp0，$_temp1';
  }

  @override
  String get deskSetBackupInFileSub => '谁付了什么、手续费、备注、Slate ID';

  @override
  String get deskSetBackupNotIn => '不包含';

  @override
  String get deskSetBackupNotInValue => '密钥、助记词、密码';

  @override
  String get deskSetBackupOpensWith => '可打开的钱包';

  @override
  String get deskSetBackupOpensWithValue => '本钱包，或用其助记词恢复的钱包';

  @override
  String get deskSetBackupFile => '文件';

  @override
  String get deskSetBackupFileNote => '文件包含截至目前的付款。有新付款后请再次导出。';

  @override
  String get deskSetBackupExportDesc => '包含本钱包的付款、详情和联系人的文件。只有使用同一助记词的钱包才能打开它。';

  @override
  String get deskSetBackupSaved => '已保存';

  @override
  String get deskSetBackupKeepCopy =>
      '另外在这台电脑之外也保存一份：U 盘、另一块硬盘或云存储。有新付款后请再次导出。';

  @override
  String get deskSetBackupOpenFolder => '打开文件夹';

  @override
  String get deskSetBackupSaving => '正在保存…';

  @override
  String get deskSetBackupTryAgain => '重试';

  @override
  String get deskSetBackupSaveAs => '另存为…';

  @override
  String get deskSetBackupOpenDialogTitle => '打开交易记录备份';

  @override
  String get deskSetBackupDetailsRestored => '已恢复详情';

  @override
  String get deskSetBackupDetailsRestoredSub => '已有的付款找回了对方、手续费或备注';

  @override
  String get deskSetBackupOlderAdded => '已添加较早的付款';

  @override
  String get deskSetBackupOlderAddedSub => '已不在列表中；显示为“来自备份”';

  @override
  String get deskSetBackupContactsAdded => '已添加联系人';

  @override
  String get deskSetBackupAlreadyHere => '已存在';

  @override
  String get deskSetBackupUnchanged => '未改动';

  @override
  String get deskSetBackupNothingNew => '没有新内容';

  @override
  String deskSetBackupNothingNewBody(String file) {
    return '$file 中的每条记录都已存在。';
  }

  @override
  String get deskSetBackupImported => '已导入';

  @override
  String deskSetBackupReading(String file) {
    return '正在读取 $file…';
  }

  @override
  String get deskSetBackupNotImported => '未导入';

  @override
  String get deskSetBackupBringsBack => '可找回';

  @override
  String get deskSetBackupBringsBackValue => '已有付款的付款人、手续费和备注；列表中丢失的较早付款；联系人';

  @override
  String get deskSetBackupNeeds => '需要';

  @override
  String deskSetBackupNeedsValue(String network) {
    return '来自本钱包（同一助记词）的文件，网络为 $network';
  }

  @override
  String get deskSetBackupNever => '绝不会';

  @override
  String get deskSetBackupNeverValue => '删除或改动已有的付款';

  @override
  String get deskSetBackupChooseFile => '选择文件…';

  @override
  String get deskSetBackupImportDesc =>
      '把本钱包的交易记录备份合并到“活动”中。不会删除任何内容，同一文件导入两次也不会有变化。';

  @override
  String get deskSetBackupSaveCsvDialogTitle => '将付款保存为 CSV';

  @override
  String get deskSetBackupCsvDialogTitle => '导出 CSV';

  @override
  String get deskSetBackupCsvDialogDesc => '本钱包付款的普通表格，用于电子表格。';

  @override
  String deskSetBackupCsvSavedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款',
    );
    return '$_temp0，最新的在前。金额以 EPIC 计，保留 8 位小数；日期为 UTC。';
  }

  @override
  String get deskSetBackupDateError => '请按 2026-01-31 的格式输入日期';

  @override
  String get deskSetBackupDateHint => 'YYYY-MM-DD';

  @override
  String get deskSetBackupRange => '范围';

  @override
  String get deskSetBackupRangeAll => '全部付款';

  @override
  String get deskSetBackupRangeThisYear => '今年';

  @override
  String get deskSetBackupRangeLastYear => '去年';

  @override
  String get deskSetBackupRangeCustom => '自定义';

  @override
  String get deskSetBackupFrom => '从';

  @override
  String get deskSetBackupTo => '到';

  @override
  String deskSetBackupCsvInfo(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款',
    );
    return '$_temp0 · 列：日期、类型、状态、金额、手续费、对方、备注、Slate ID、内核、区块高度。文件 $file。';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '– · 列：日期、类型、状态、金额、手续费、对方、备注、Slate ID、内核、区块高度。文件 $file。';
  }

  @override
  String get deskSetBackupNotEncrypted => '未加密。';

  @override
  String get deskSetBackupNotEncryptedBody =>
      '任何拿到此文件的人都能看到金额、日期、地址和备注。它不能导入；导入请使用交易记录备份。';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款不在交易记录备份中。',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '自上次交易记录备份以来，有 $count 笔付款是新的或有改动。',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody => '用助记词恢复只能找回余额，无法找回谁付了什么。';

  @override
  String get deskSetBackupNotNow => '以后再说';

  @override
  String get deskSetDlgChainTitle => '找到已有的区块链数据';

  @override
  String get deskSetDlgChainDesc => '这台电脑上已有本地节点可以使用的 Epic 区块链数据。';

  @override
  String get deskSetDlgChainFolder => '文件夹';

  @override
  String get deskSetDlgChainSize => '大小';

  @override
  String get deskSetDlgChainUpdated => '上次更新';

  @override
  String get deskSetDlgChainUpdatedValue => '3 天前';

  @override
  String get deskSetDlgChainOthers => '还找到了其他副本（1 个）。这一份是最近更新的。';

  @override
  String get deskSetDlgChainInUse =>
      '另一个 Epic 程序正在使用此文件夹。请关闭它，然后重新选择本地节点以使用这些数据。';

  @override
  String get deskSetDlgChainUseIt => '要使用它吗？这样可以省去下载和同步整个区块链。';

  @override
  String get deskSetDlgChainOlderWallet =>
      '之后，使用此文件夹的旧版 Epic Wallet 可能需要重新同步。币不受影响。';

  @override
  String get deskSetDlgChainFresh => '重新下载';

  @override
  String get deskSetDlgChainUse => '使用这些数据';

  @override
  String get deskSetDlgPwChanged => '密码已更改。';

  @override
  String get deskSetDlgPwTitle => '更改密码';

  @override
  String get deskSetDlgPwDesc => '从现在起用新密码解锁此钱包。记住的密码会被忘记。';

  @override
  String get deskSetDlgPwCurrent => '当前密码';

  @override
  String get deskSetDlgPwWrong => '密码错误';

  @override
  String get deskSetDlgPwNew => '新密码';

  @override
  String get deskSetDlgPwRepeat => '再次输入新密码';

  @override
  String deskSetDlgRemoveToastList(String name) {
    return '已从列表中移除 $name';
  }

  @override
  String deskSetDlgRemoveToastDeleted(String name) {
    return '已删除 $name';
  }

  @override
  String get deskSetDlgRemoveFilesKept => '文件已保留。';

  @override
  String deskSetDlgRemoveTitle(String name) {
    return '移除 $name？';
  }

  @override
  String get deskSetDlgRemoveDesc => '确认之前不会有任何变化。';

  @override
  String get deskSetDlgRemoveWhat => '要移除什么';

  @override
  String get deskSetDlgRemoveFromList => '从列表中移除';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return '文件保留在 $folder 中。可在“所有钱包”中重新添加。';
  }

  @override
  String get deskSetDlgDeleteWallet => '删除钱包';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return '从 $folder 删除它的密钥和数据库。只有助记词能恢复它；没有助记词，币就会丢失。';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      '如果还要删除它的文件，请解锁此钱包，然后使用“设置 › 此钱包”中的“删除钱包”。';

  @override
  String get deskSetDlgRemoveUnlock => '解锁此钱包';

  @override
  String get deskSetDlgRemoveIrreversible => '无法撤销';

  @override
  String get deskSetDlgRemoveIrreversibleBody => '只有助记词能恢复这个钱包；没有助记词，币就会永久丢失。';

  @override
  String get deskSetDlgRemoveName => '钱包名称';

  @override
  String deskSetDlgRemoveTypeName(String name) {
    return '输入 $name 以确认。';
  }

  @override
  String get deskSetDlgRemoveNameMismatch => '名称不匹配';

  @override
  String get deskSetDlgPassword => '密码';

  @override
  String get deskSetDlgPhraseWritten => '助记词已抄写下来';

  @override
  String get deskSetDlgRemoving => '正在移除…';

  @override
  String get deskSetDlgWalletLocked => '钱包已锁定';

  @override
  String get deskSetDlgDeleteTitle => '删除此钱包？';

  @override
  String get deskSetDlgDeleteDesc => '从这台电脑上删除此钱包及其种子。只有助记词能恢复它；没有助记词，币就会丢失。';

  @override
  String get deskSetFrameTitle => '设置';

  @override
  String get deskSetFrameSections => '设置分区';

  @override
  String get deskSetFrameNode => '节点';

  @override
  String get deskSetFramePrivacy => '隐私';

  @override
  String get deskSetFrameAppearance => '外观';

  @override
  String get deskSetFrameThisWallet => '此钱包';

  @override
  String get deskSetFrameAllWallets => '所有钱包';

  @override
  String get deskSetFramePhrase => '助记词';

  @override
  String get deskSetFrameRescan => '重新核对余额';

  @override
  String get deskSetFrameAbout => '关于';

  @override
  String get deskSetFrameHelp => '帮助';

  @override
  String get deskSetFrameHealthOn => '开启';

  @override
  String get deskSetFrameHealthSlow => '较慢';

  @override
  String get deskSetFrameNotResponding => '无响应';

  @override
  String get deskSetFrameOff => '关闭';

  @override
  String get deskSetFrameChecking => '正在检查…';

  @override
  String get deskSetFrameNodeSynced => '已同步';

  @override
  String get deskSetFrameNodeSyncing => '正在同步';

  @override
  String get deskSetFrameConnecting => '正在连接…';

  @override
  String get deskSetFrameListening => '正在监听';

  @override
  String deskSetFrameHealthLatency(String word, int ms) {
    return '$word · $ms 毫秒';
  }

  @override
  String get deskSetFrameNever => '从未';

  @override
  String get deskSetFrameJustNow => '刚刚';

  @override
  String deskSetFrameMinAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String get deskSetComboOpens => '打开列表';

  @override
  String get deskSetComboNoAnswer => '暂无响应';

  @override
  String deskSetComboUse(String host) {
    return '使用 $host';
  }

  @override
  String get deskSetLnodeDidNotStart => '节点未能启动';

  @override
  String get deskSetLnodeDidNotStop => '节点未能停止';

  @override
  String get deskSetLnodeDidNotRestart => '节点未能重启';

  @override
  String get deskSetLnodeMoved => '链数据已移动';

  @override
  String get deskSetLnodeFolderChanged => '数据文件夹已更改';

  @override
  String get deskSetLnodeFolderFailed => '文件夹未更改';

  @override
  String get deskSetLnodeStart => '启动';

  @override
  String get deskSetLnodeStop => '停止';

  @override
  String get deskSetLnodeRestart => '重启';

  @override
  String get deskSetLnodeTabStatus => '状态';

  @override
  String get deskSetLnodeTabPeers => '对等节点';

  @override
  String get deskSetLnodeWhileSyncing => '同步期间';

  @override
  String deskSetLnodeWhileSyncingText(String host) {
    return '本地节点同步完成前使用 $host。之后本地节点会自动接替。';
  }

  @override
  String get deskSetLnodeChange => '更改…';

  @override
  String deskSetLnodeUseWhileSyncing(String host) {
    return '同步期间使用 $host';
  }

  @override
  String get deskSetLnodeDataFolder => '数据文件夹';

  @override
  String deskSetLnodeUsed(String size) {
    return '已用 $size';
  }

  @override
  String get deskSetLnodeFreeUnknown => '可用空间未知';

  @override
  String deskSetLnodeFree(String size) {
    return '可用 $size';
  }

  @override
  String get deskSetLnodeOpen => '打开';

  @override
  String get deskSetLnodeFolderNotOpened => '未能打开文件夹';

  @override
  String get deskSetLnodeChainData => '链数据';

  @override
  String get deskSetLnodeChainPointed => '此节点读取的是另一个程序的文件夹；请在那里删除。';

  @override
  String get deskSetLnodeChainText =>
      '使用另一个 Epic 节点留在这台电脑上的链数据，或删除此节点的数据并重新下载区块链。';

  @override
  String get deskSetLnodeReuse => '使用已有数据…';

  @override
  String get deskSetLnodeDelete => '删除…';

  @override
  String get deskSetLnodeAutostart => '随应用启动';

  @override
  String get deskSetLnodeAutostartHint => '启动应用时启动节点，并在应用打开期间持续同步。';

  @override
  String get deskSetLnodeViewLog => '查看节点日志';

  @override
  String get deskSetLnodeChangeFolder => '更改文件夹…';

  @override
  String deskSetLnodeUseMeanwhile(String host) {
    return '期间使用 $host';
  }

  @override
  String get deskSetLnodeWaitingPeers => '等待对等节点';

  @override
  String get deskSetLnodeSyncingLower => '正在同步';

  @override
  String deskSetLnodeStageUsing(String stage, String host) {
    return '$stage · 期间使用 $host';
  }

  @override
  String get deskSetLnodeNothingUntilSynced => '本地节点同步完成前，无法发送或接收。';

  @override
  String get deskSetLnodeAtTip => '已是最新';

  @override
  String get deskSetLnodeStalledDetail => '5 分钟没有进展；已自动重启过一次';

  @override
  String get deskSetLnodeNoProgress => '节点没有进展。';

  @override
  String get deskSetLnodeNoProgressText => '重启通常能解决；如果不行，日志会说明原因。';

  @override
  String get deskSetLnodePortInUse => '端口 3413 被其他程序占用。';

  @override
  String get deskSetLnodePortInUseText =>
      '关闭那个程序（另一个 Epic 节点？），或在“节点服务器”中选择已在该端口运行的节点。';

  @override
  String get deskSetLnodeDiskLow => '此磁盘的可用空间不足 2 GB。';

  @override
  String get deskSetLnodeDiskLowText => '请释放空间，或更改数据文件夹。';

  @override
  String get deskSetLnodeMissing => '此安装中缺少节点程序。';

  @override
  String get deskSetLnodeMissingText => '请重新安装钱包。';

  @override
  String get deskSetLnodeStopped => '节点自行停止了。';

  @override
  String get deskSetLnodeStoppedText => '最后几行日志可能说明了原因。';

  @override
  String deskSetLnodeUsesMeanwhile(String host) {
    return '期间钱包使用 $host';
  }

  @override
  String get deskSetLnodeNothingUntilRuns => '节点运行前无法发送';

  @override
  String get deskSetLnodeTilePeers => '对等节点';

  @override
  String get deskSetLnodeTileSync => '同步';

  @override
  String get deskSetLnodeTileDownload => '下载';

  @override
  String deskSetLnodeSoFar(String size) {
    return '目前共 $size';
  }

  @override
  String get deskSetLnodeTileDisk => '磁盘上的链数据';

  @override
  String deskSetLnodeThisSession(String size) {
    return '本次运行 +$size';
  }

  @override
  String deskSetLnodeVersion(String version) {
    return '版本 $version';
  }

  @override
  String deskSetLnodeRunning(String duration) {
    return '已运行 $duration';
  }

  @override
  String deskSetLnodeStoppedAt(String time) {
    return '停止于 $time';
  }

  @override
  String deskSetLnodePeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个对等节点',
    );
    return '$_temp0';
  }

  @override
  String deskSetLnodeMoving(String done, String total) {
    return '正在移动链数据 · $done/$total';
  }

  @override
  String get deskSetLnodeConnectingPeers => '正在连接对等节点';

  @override
  String deskSetLnodeStartedSecAgo(int seconds) {
    return '$seconds 秒前启动';
  }

  @override
  String deskSetLnodeStartedAgo(String duration) {
    return '$duration前启动';
  }

  @override
  String get deskSetLnodeSettingsChanged => '设置已更改。';

  @override
  String get deskSetLnodeSettingsChangedText => '下次重启时生效。';

  @override
  String get deskSetLnodeRestartNow => '立即重启';

  @override
  String get deskSetLnodeSampled => '此页面打开期间每 30 秒采样一次。';

  @override
  String get deskSetLnodeTomlEdited =>
      'epic-server.toml 被手动编辑过；这里的对等节点和文件夹设置不会生效。';

  @override
  String get deskSetLnodeSyncProgress => '同步进度';

  @override
  String get deskSetLnodeStepHeaders => '区块头';

  @override
  String get deskSetLnodeStepChainState => '链状态';

  @override
  String get deskSetLnodeStepBlocks => '区块';

  @override
  String get deskSetLnodeStepsNone => '同步步骤：尚未开始';

  @override
  String deskSetLnodeStepOf(int n, String name) {
    return '同步第 $n 步，共 4 步：$name';
  }

  @override
  String deskSetLndAskTitle(String host) {
    return '本地节点同步完成前使用 $host？';
  }

  @override
  String deskSetLndAskDesc(String host) {
    return '同步需要数小时。在此期间，钱包可以通过公共节点 $host 读取区块链和发送交易。本地节点同步完成后会自动接替。';
  }

  @override
  String get deskSetLndAskNote => '只询问一次。可以在“设置 › 节点 › 同步期间”中更改节点和这个选择。';

  @override
  String get deskSetLndAskWait => '等待本地节点';

  @override
  String deskSetLndAskUse(String host) {
    return '使用 $host';
  }

  @override
  String get deskSetLndPickTitle => '同步期间使用的节点';

  @override
  String get deskSetLndPickDesc => '本地节点同步完成前钱包使用的公共节点。';

  @override
  String get deskSetLndDeleted => '链数据已删除';

  @override
  String deskSetLndFreed(String size) {
    return '已释放 $size';
  }

  @override
  String get deskSetLndNotDeleted => '链数据未删除';

  @override
  String get deskSetLndDeleteTitle => '删除链数据';

  @override
  String deskSetLndDeleteDesc(String size, String path) {
    return '从 $path 删除 $size。节点会停止，下次启动时会重新下载整个区块链（需要数小时）。钱包密钥和交易记录不受影响。';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return '从 $path 删除链数据。节点会停止，下次启动时会重新下载整个区块链（需要数小时）。钱包密钥和交易记录不受影响。';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return '输入 $word 以确认。';
  }

  @override
  String deskSetLndTypeToConfirmLabel(String word) {
    return '输入 $word 以确认';
  }

  @override
  String get deskSetLndSourceCli => 'epic（命令行节点）';

  @override
  String get deskSetLndSourceGui => 'Epic GUI';

  @override
  String get deskSetLndSourceBundled => '旧版 Epic Wallet';

  @override
  String get deskSetLndSourceCustom => '其他文件夹';

  @override
  String get deskSetLndInUse => '正在使用链数据';

  @override
  String get deskSetLndNotInUse => '该文件夹未被使用';

  @override
  String get deskSetLndReuseTitle => '在这台电脑上找到链数据';

  @override
  String get deskSetLndReuseDesc =>
      '另一个 Epic 节点在这里留下了链数据。本地节点可以读取那个文件夹，而不用下载区块链。';

  @override
  String get deskSetLndLooking => '正在查找…';

  @override
  String get deskSetLndUseIt => '使用它';

  @override
  String deskSetLndLastWritten(String date) {
    return '最后写入于 $date';
  }

  @override
  String get deskSetLndLocked => '正被其他程序使用';

  @override
  String get deskSetLndNothingCopied => '不会复制任何内容：节点直接读取那个文件夹，并且对它禁用“删除链数据”。';

  @override
  String get deskSetLndFresh => '重新下载';

  @override
  String deskSetLndFreshLine(String size) {
    return '下载到钱包自己的文件夹中。约 $size。';
  }

  @override
  String get deskSetLndLogTitle => '节点日志';

  @override
  String get deskSetLndReading => '正在读取…';

  @override
  String get deskSetLndLogNote => '数据文件夹中 epic-server.log 的最后 200 行。最新的在底部。';

  @override
  String get deskSetLndCopied => '已复制';

  @override
  String deskSetLndLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行',
    );
    return '$_temp0';
  }

  @override
  String get deskSetLndBadFolder => '该文件夹不可用';

  @override
  String get deskSetLndChooseAnother => '选择其他文件夹';

  @override
  String deskSetLndMoveTitle(String size, String folder) {
    return '把 $size 移动到 $folder？';
  }

  @override
  String get deskSetLndMoveDesc =>
      '移动数据期间节点会停止，之后从新文件夹重新启动。“在那里重新开始”则会改为把区块链重新下载到新文件夹中。';

  @override
  String get deskSetLndStartFresh => '在那里重新开始';

  @override
  String get deskSetLndMove => '移动';

  @override
  String get deskSetLndProbNotEmpty => '该文件夹不是空的。';

  @override
  String get deskSetLndProbInsideSource => '它位于当前文件夹之内。';

  @override
  String get deskSetLndProbSourceInside => '当前文件夹位于它之内。';

  @override
  String deskSetLndProbSpace(String needed, String free) {
    return '空间不足：需要 $needed，可用 $free。';
  }

  @override
  String deskSetLndProbSpaceUnknown(String needed) {
    return '空间不足：需要 $needed，可用空间未知。';
  }

  @override
  String get deskSetLndProbLocked => '它正被另一个程序占用。';

  @override
  String get deskSetLndProbMissing => '当前的链数据不见了。';

  @override
  String get deskSetLndProbNotWritable => '无法写入该文件夹。';

  @override
  String get deskSetLndProbIncomplete => '当前的链数据不完整。';

  @override
  String get deskSetLndProbForeign => '那里有另一个程序的链数据。';

  @override
  String get deskSetPeersBannedToast => '已封禁对等节点';

  @override
  String get deskSetPeersUnbannedToast => '已解封对等节点';

  @override
  String get deskSetPeersNotAddress => '不是 IP 地址加端口，例如 203.0.113.5:3414。';

  @override
  String get deskSetPeersAlreadyPreferred => '已在首选列表中。';

  @override
  String deskSetPeersMaxRange(int min, int max) {
    return '$min 到 $max。';
  }

  @override
  String get deskSetPeersReading => '正在读取对等节点…';

  @override
  String deskSetPeersSummary(int connected, int inbound, int outbound) {
    return '已连接 $connected · 入站 $inbound · 出站 $outbound';
  }

  @override
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  ) {
    return '已连接 $connected · 入站 $inbound · 出站 $outbound · 已封禁 $banned';
  }

  @override
  String get deskSetPeersIn => '入站';

  @override
  String get deskSetPeersOut => '出站';

  @override
  String get deskSetPeersBan => '封禁';

  @override
  String get deskSetPeersColAddress => '地址';

  @override
  String get deskSetPeersColDirection => '方向';

  @override
  String get deskSetPeersColVersion => '版本';

  @override
  String get deskSetPeersColHeight => '高度';

  @override
  String get deskSetPeersColFirstSeen => '首次出现';

  @override
  String get deskSetPeersNone => '没有已连接的对等节点。';

  @override
  String deskSetPeersMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另外 $count 个',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPeersRefreshed => '每 10 秒刷新';

  @override
  String get deskSetPeersBanned => '已封禁';

  @override
  String deskSetPeersBannedAt(String time) {
    return '封禁于 $time';
  }

  @override
  String get deskSetPeersUnban => '解封';

  @override
  String get deskSetPeersPreferred => '首选对等节点';

  @override
  String get deskSetPeersPreferredLabel => '首选对等节点，IP 地址和端口';

  @override
  String get deskSetPeersAdd => '添加';

  @override
  String get deskSetPeersMaxIn => '最大入站数';

  @override
  String get deskSetPeersMaxInLabel => '最大入站对等节点数';

  @override
  String get deskSetPeersMaxOut => '最大出站数';

  @override
  String get deskSetPeersMaxOutLabel => '最大出站对等节点数';

  @override
  String deskSetPeersPreferredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个首选：',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersForget(String peer) {
    return '移除 $peer';
  }

  @override
  String deskSetPeersNote(int min, int max, int def) {
    return '“首次出现”是本应用在本次运行中首次看到该对等节点连接的时间；节点不会报告连接何时开始。封禁和解封使用节点的 owner API。按 Enter 保存最大值（$min 到 $max，默认 $def）。';
  }

  @override
  String get deskSetLndDeleteQuestion => '删除链数据？';

  @override
  String get deskSetLogsMemoryOnly => '日志只保存在内存中。';

  @override
  String get deskSetLogsClearTitle => '清除日志？';

  @override
  String get deskSetLogsClearDesc => '删除日志文件。之后发送的报告只包含从现在开始记录的内容。';

  @override
  String get deskSetLogsKeep => '保留日志';

  @override
  String get deskSetLogsClear => '清除日志';

  @override
  String get deskSetLogsCleared => '日志已清除';

  @override
  String deskSetLogsToday(String time) {
    return '今天 $time';
  }

  @override
  String deskSetLogsTomorrow(String time) {
    return '明天 $time';
  }

  @override
  String get deskSetLogsTitle => '日志';

  @override
  String get deskSetLogsLevel => '日志级别';

  @override
  String get deskSetLogsLevelNormal =>
      '普通。“详细”会在磁盘上保留更多行，持续 24 小时；文件中可能出现地址，报告会去掉它们。';

  @override
  String deskSetLogsLevelDetailed(String until) {
    return '详细，直到 $until，之后恢复普通。文件中可能出现地址；报告会去掉它们。';
  }

  @override
  String deskSetLogsLevelDetailedCore(String until) {
    return '详细，直到 $until，之后恢复普通。文件中可能出现地址；报告会去掉它们。钱包核心的日志从下次启动应用起变为详细。';
  }

  @override
  String get deskSetLogsNormal => '普通';

  @override
  String get deskSetLogsDetailed => '详细';

  @override
  String get deskSetLogsFiles => '日志文件';

  @override
  String deskSetLogsSize(String size, String max) {
    return '当前大小 $size，上限 $max。保留一个较旧的文件。';
  }

  @override
  String get deskSetLogsOpenFolder => '打开日志文件夹';

  @override
  String get deskSetNodePortNote => '请检查地址和端口（通常是 3413）。';

  @override
  String get deskSetNodeListNote =>
      '状态来自 status.btlabs.uk，每隔几分钟检查一次。延迟是从这台电脑测得的。';

  @override
  String get deskSetNodeStartTitle => '启动本地节点？';

  @override
  String get deskSetNodeStartDesc => '一个独立的程序会在这台电脑上同步 Epic 区块链。';

  @override
  String get deskSetNodeStartLine1 => '下载完整的区块链：需要数 GB 的磁盘空间和流量。';

  @override
  String get deskSetNodeStartLine2 => '首次同步需要数小时。完成之前，节点显示为“正在同步”。';

  @override
  String get deskSetNodeStartLine3 => '防火墙可能会询问是否允许节点程序。';

  @override
  String get deskSetNodeStartButton => '启动本地节点';

  @override
  String get deskSetNodeRowNotSetUp => '未设置';

  @override
  String get deskSetNodeRowStopped => '已停止';

  @override
  String get deskSetNodeRowStarting => '正在启动';

  @override
  String deskSetNodeRowSyncingPct(String percent) {
    return '正在同步 $percent';
  }

  @override
  String get deskSetNodeRowStalled => '停滞';

  @override
  String get deskSetNodeRowFailed => '失败';

  @override
  String get deskSetNodeLocalInUse => '正在使用本地节点';

  @override
  String get deskSetNodeLocalInUseText => '它会下载完整的区块链。需要 5 GB 可用空间。';

  @override
  String get deskSetNodeLocalNode => '本地节点';

  @override
  String get deskSetNodeGroupComputer => '这台电脑';

  @override
  String get deskSetNodeServer => '节点服务器';

  @override
  String get deskSetNodeServerHint => '钱包通过这个节点读取区块链并发送交易。';

  @override
  String get deskSetNodeChecking => '正在检查节点…';

  @override
  String get deskSetNodeBackground => '后台同步';

  @override
  String get deskSetNodeBackgroundHint => '应用关闭时继续同步。';

  @override
  String get deskSetPhraseNotCopied => '未复制';

  @override
  String get deskSetPhraseClipboardRefused => '剪贴板拒绝了这段文本。';

  @override
  String get deskSetPhraseCopied => '助记词已复制';

  @override
  String get deskSetPhraseCleared => '剪贴板将在 60 秒后清空。';

  @override
  String get deskSetPhraseEnterPassword => '请输入密码。';

  @override
  String get deskSetPhraseWrongPassword => '密码错误。';

  @override
  String get deskSetPhraseIntro => '请按此顺序把这些单词抄写在纸上。切勿把它们输入任何网站或聊天中。';

  @override
  String get deskSetPhrasePanel => '输入密码以显示这些单词';

  @override
  String get deskSetPhraseShowWords => '显示单词';

  @override
  String deskSetPhraseWordsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '助记词，$count 个单词',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPhraseHideQr => '隐藏二维码';

  @override
  String get deskSetPhraseShowQr => '显示二维码';

  @override
  String get deskSetPhraseHideWords => '隐藏单词';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return '$seconds 秒后隐藏';
  }

  @override
  String get deskSetPhraseQrLabel => '助记词二维码';

  @override
  String get deskSetPhraseBackUp => '备份助记词';

  @override
  String get deskSetPhraseBackUpText => '任何拿到这些单词的人都能拿走你的 EPIC。请确认没有人能看到屏幕。';

  @override
  String get deskSetPrivTorOnFailed => 'Tor 未开启';

  @override
  String get deskSetPrivTorOffFailed => 'Tor 未关闭';

  @override
  String get deskSetPrivTor => 'Tor';

  @override
  String get deskSetPrivSwitching => '正在切换 Tor';

  @override
  String get deskSetPrivTurnOff => '关闭 Tor';

  @override
  String get deskSetPrivNotInBuild => '此版本不含 Tor';

  @override
  String get deskSetPrivStarting => '正在启动…';

  @override
  String deskSetPrivStartingDetail(int progress, String waiting) {
    return '$progress%。$waiting会等到 Tor 连接成功。';
  }

  @override
  String get deskSetPrivNotPublished => 'Tor 地址尚未发布。发送不受影响。';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem。发送不受影响。';
  }

  @override
  String get deskSetPrivConnected => '已连接。';

  @override
  String get deskSetPrivNotConnected => '未连接';

  @override
  String deskSetPrivStoppedDetail(String waiting) {
    return 'Tor 已停止。$waiting会等待你点击“重试”或关闭 Tor。';
  }

  @override
  String deskSetPrivProblemDetail(String problem, String waiting) {
    return '$problem。$waiting会等待你点击“重试”或关闭 Tor。';
  }

  @override
  String get deskSetPrivStatusSite => '状态网站';

  @override
  String get deskSetPrivUseStatus => '使用 status.btlabs.uk';

  @override
  String get deskSetPrivUseStatusHint => '网络状态和信息由 status.btlabs.uk 提供';

  @override
  String deskSetRecvMethodOnFailed(String method) {
    return '$method 未开启';
  }

  @override
  String deskSetRecvMethodOffFailed(String method) {
    return '$method 未关闭';
  }

  @override
  String get deskSetRecvServerNotChanged => '服务器未更改';

  @override
  String get deskSetRecvReceiving => '接收';

  @override
  String deskSetRecvSwitching(String method) {
    return '正在切换 $method 接收';
  }

  @override
  String deskSetRecvMethodReceiving(String method) {
    return '$method 接收';
  }

  @override
  String get deskSetRecvNotSaved => '未保存';

  @override
  String get deskSetRecvAutostart => '随钱包启动';

  @override
  String get deskSetRecvAutostartHint => '解锁时开启。';

  @override
  String deskSetRecvMethodAutostart(String method) {
    return '$method：随钱包启动';
  }

  @override
  String get deskSetRecvHeadStopped => '已停止';

  @override
  String get deskSetRecvHeadStarting => '正在启动';

  @override
  String get deskSetRecvEpicboxTitle => 'Epicbox 接收';

  @override
  String get deskSetRecvEpicboxText => '付款经由 Epicbox 服务器到达，钱包关闭时也可以。';

  @override
  String get deskSetRecvEpicboxServer => 'Epicbox 服务器';

  @override
  String get deskSetRecvEpicboxServerHint => '由哪个服务器为此地址暂存付款。双方钱包可以使用不同的服务器。';

  @override
  String get deskSetRecvSwitchingServer => '正在切换 Epicbox 服务器…';

  @override
  String get deskSetRecvListNote => '状态来自 status.btlabs.uk，每隔几分钟检查一次。';

  @override
  String get deskSetRecvHttpTitle => '链接 · HTTP 接收';

  @override
  String get deskSetRecvHttpText => '本钱包打开时，直接从另一个钱包经此电脑的网址接收。';

  @override
  String get deskSetRecvHttpOffTitle => 'Tor 开启时关闭';

  @override
  String get deskSetRecvHttpOffText => '直接来自另一个钱包的付款会改为发送到 链接 · Tor 地址。';

  @override
  String get deskSetRecvPrivacySettings => '隐私设置';

  @override
  String get deskSetHttpNotChanged => '未更改';

  @override
  String get deskSetHttpPortError => '端口必须在 1 到 65535 之间';

  @override
  String get deskSetHttpReachable => '访问范围';

  @override
  String get deskSetHttpReachableHint => '谁可以向 HTTP 地址付款。';

  @override
  String get deskSetHttpLocalOnly => '仅限本机';

  @override
  String get deskSetHttpFromInternet => '来自互联网';

  @override
  String get deskSetHttpGuideHelp => '从互联网接收：如何操作';

  @override
  String deskSetHttpPublicNote(String port) {
    return '在所有网络接口上响应。路由器必须把 TCP $port 转发到这台电脑。互联网上的发送方使用 http://<public IP>:$port。';
  }

  @override
  String get deskSetHttpPort => '端口';

  @override
  String get deskSetHttpPortHint => '1 到 65535。供 HTTP 地址使用。';

  @override
  String get deskSetHttpPortLabel => 'HTTP 端口';

  @override
  String get deskSetHttpGuideTitle => '从互联网接收';

  @override
  String get deskSetHttpGuideNowPublic => '当前：来自互联网。';

  @override
  String get deskSetHttpGuideNowLocal => '当前：仅限本机。只有这台电脑上的程序能访问 HTTP 地址。';

  @override
  String get deskSetHttpStep1 => '在所有网络接口上监听';

  @override
  String deskSetHttpStep1Text(String port) {
    return '钱包在 0.0.0.0 的端口 $port 上响应。这样其他设备和互联网就能向本钱包付款。防火墙可能会询问是否允许。';
  }

  @override
  String get deskSetHttpStep2 => '转发端口';

  @override
  String deskSetHttpStep2Text(String port) {
    return '在路由器的管理页面（通常是 10.0.1.1）找到“端口转发”，把 TCP $port 转发到这台电脑。';
  }

  @override
  String get deskSetHttpStep3 => '分享公网地址';

  @override
  String deskSetHttpStep3Text(String port) {
    return '发送方使用 http://<public IP>:$port。公网 IP 可能会变化。';
  }

  @override
  String get deskSetHttpNoRouter => '不想设置路由器？';

  @override
  String get deskSetHttpNoRouterText => 'Tor 在任何地方都能用，无需转发任何端口。';

  @override
  String get deskSetHttpTurnOnTor => '开启 Tor';

  @override
  String get deskSetHttpExposed => '只开放接收 API。明文 HTTP 不加密。';

  @override
  String get deskSetHttpBackLocal => '改回仅限本机';

  @override
  String get deskSetReportNotSent => '报告未发送。请重试。';

  @override
  String get deskSetReportSaveDialog => '保存报告';

  @override
  String get deskSetReportSaved => '已保存。已清除机密信息，但未加密。';

  @override
  String get deskSetReportNotSaved => '文件未保存。请重试。';

  @override
  String get deskSetReportText => '报告内容';

  @override
  String deskSetReportAppLog(String size) {
    return '应用日志（最近 $size）';
  }

  @override
  String get deskSetReportSent => '报告已发送';

  @override
  String get deskSetReportArrived => '报告已送达。';

  @override
  String deskSetReportArrivedRef(String id) {
    return '报告已送达。编号为 $id。';
  }

  @override
  String get deskSetReportDescribe => '请描述发生了什么。';

  @override
  String get deskSetReportTitle => '报告问题';

  @override
  String get deskSetReportDesc =>
      '报告经过加密，只有开发者能读取。点击“发送”之前不会发送任何内容。“保存到文件”会保存同一份已清理的报告，但不加密。';

  @override
  String get deskSetReportWhat => '发生了什么';

  @override
  String get deskSetReportWhatHint => '你做了什么，期望发生什么，实际发生了什么';

  @override
  String get deskSetReportContact => '联系方式';

  @override
  String get deskSetReportContactHint => '电子邮件地址或其他账号，用于回复';

  @override
  String get deskSetReportAttach => '附上日志（建议）';

  @override
  String get deskSetReportAttachHint => '应用日志的最新部分，已清除助记词、密码、地址、IP 和用户主文件夹。';

  @override
  String get deskSetReportSentWhat => '发送的内容';

  @override
  String get deskSetReportNotSentTitle => '未发送';

  @override
  String get deskSetReportOff => '此版本已关闭发送功能';

  @override
  String get deskSetReportSaveToFile => '保存到文件';

  @override
  String get deskSetReportSend => '发送';

  @override
  String get deskSetRescanComplete => '扫描完成';

  @override
  String get deskSetRescanStoppedLine => '扫描已停止';

  @override
  String get deskSetRescanLog => '扫描日志';

  @override
  String get deskSetRescanText =>
      '重新读取区块链，并根据找到的输出重建余额。在余额看起来不对、恢复钱包之后，或发送失败后输出一直锁定时使用。期间钱包仍可使用。';

  @override
  String get deskSetRescanStartAgain => '重新开始';

  @override
  String get deskSetRescanDeleteUnconfirmed => '删除未确认的交易';

  @override
  String get deskSetRescanDeleteHint => '同时取消未确认的交易并解锁它们的输出。已在途中的付款可能因此失败。';

  @override
  String get deskSetRescanScanning => '正在扫描区块链。钱包仍可使用；扫描结束后余额会更新。';

  @override
  String get deskSetRescanStopping => '正在停止…';

  @override
  String deskSetRescanChecking(int percent) {
    return '正在检查… $percent%';
  }

  @override
  String get deskSetRescanFailed => '扫描失败';

  @override
  String get deskSetRescanNoneFound => '没有找到未确认的交易。';

  @override
  String get deskSetRescanCancelled => '未确认的交易已取消，它们的输出已解锁。';

  @override
  String get deskSetRescanNotRead => '未读取';

  @override
  String get deskSetRescanFinished => '扫描已完成';

  @override
  String get deskSetRescanUpToDate => '余额已是最新。';

  @override
  String get deskSetRescanResumed => '扫描从上次停止的地方继续；计数只包括这一部分。';

  @override
  String get deskSetRescanStoppedEarly => '在结束前停止了。余额已重新读取；重新开始即可继续。';

  @override
  String get deskSetRescanNotDeleted => '未确认的交易没有删除：只有扫描完整结束时才会执行。';

  @override
  String get deskSetRescanBefore => '之前的余额';

  @override
  String get deskSetRescanAfter => '之后的余额';

  @override
  String get deskSetRescanFound => '找到的输出';

  @override
  String get deskSetRescanRestored => '已恢复';

  @override
  String get deskSetRescanRevived => '恢复为未花费';

  @override
  String get deskSetRescanUnlocked => '已解锁';

  @override
  String get deskSetRescanDeleted => '已删除';

  @override
  String deskSetWalletsAddedBack(String name) {
    return '已重新添加 $name';
  }

  @override
  String get deskSetWalletsNotAddedBack => '未重新添加';

  @override
  String get deskSetWalletsOpenNow => '已打开';

  @override
  String get deskSetWalletsFolderMissing => '文件夹丢失';

  @override
  String deskSetWalletsShowFolder(String name) {
    return '在文件夹中显示 $name';
  }

  @override
  String deskSetWalletsRemove(String name) {
    return '移除 $name…';
  }

  @override
  String get deskSetWalletsRemovedGroup => '已从列表中移除';

  @override
  String get deskSetWalletsAddBack => '重新添加';

  @override
  String get deskSetWalletsAdd => '添加钱包';

  @override
  String get deskSetWalletsCreate => '创建钱包';

  @override
  String get deskSetWalletsCreateText => '带有新助记词的新钱包。';

  @override
  String get deskSetWalletsImport => '导入';

  @override
  String get deskSetWalletsImportText => '从旧版 Epic Wallet 或文件夹导入。';

  @override
  String get deskSetWalletsRestore => '恢复';

  @override
  String get deskSetWalletsRestoreText => '用助记词恢复。';

  @override
  String get deskSetupConfirmPassword => '确认密码';

  @override
  String get deskSetupPasswordShort => '至少 8 个字符';

  @override
  String get deskSetupPasswordsDiffer => '两次输入的密码不一致';

  @override
  String get deskSetupBack => '返回';

  @override
  String get deskSetupNewWalletAdded => '已添加新钱包。';

  @override
  String get deskSetupCapsLock => '大写锁定已开启';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return '第 $number 步，共 $total 步：$label';
  }

  @override
  String get deskSetupTryAgain => '重试';

  @override
  String get deskSetupNotSaved => '未保存';

  @override
  String get deskSetupStepPrefs => '偏好设置';

  @override
  String get deskSetupStepNode => '节点';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupStepReview => '检查';

  @override
  String get deskSetupAgain => '正在重新运行设置向导。在最后一步点击“保存设置”之前不会有任何更改。';

  @override
  String get deskSetupPrefsLead => '应用语言。之后可以更改。';

  @override
  String get deskSetupNodeTitle => '选择节点';

  @override
  String get deskSetupNodeLead => '钱包通过 Epic 节点读取区块链并发送交易。';

  @override
  String get deskSetupLocalTitle => '本地节点';

  @override
  String get deskSetupLocalLead => '在这里运行节点意味着什么，以及使用哪个节点。';

  @override
  String get deskSetupEpicboxTitle => '离线时也能接收';

  @override
  String get deskSetupReviewTitle => '检查设置';

  @override
  String get deskSetupReviewLead => '修改不正确的地方，然后保存。';

  @override
  String get deskSetupSideTitle => '设置向导';

  @override
  String get deskSetupBackToWallet => '返回钱包';

  @override
  String get deskSetupLaterNote => '这里的所有选项之后都可以在“设置”中更改。';

  @override
  String get deskSetupSave => '保存设置';

  @override
  String get deskSetupLanguage => '语言';

  @override
  String get deskSetupNodeServer => '节点服务器';

  @override
  String get deskSetupCheckingNodes => '正在检查节点…';

  @override
  String get deskSetupPickNode => '选择一个节点';

  @override
  String get deskSetupRemoteNode => '远程节点';

  @override
  String get deskSetupRemoteNodeText => '任意公共节点。立即可用。';

  @override
  String get deskSetupLocalNodeText =>
      '在这台电脑上运行 Epic 节点。不与任何运营方共享信息。需要磁盘空间和数小时同步。';

  @override
  String get deskSetupEpicboxText => 'Epicbox 会把付款送到 Epicbox 地址，并暂存到钱包上线为止。';

  @override
  String get deskSetupEpicboxPrivacy =>
      '它不会对 Epicbox 服务器隐藏你的 IP 地址。如果你在意这一点，请使用 VPN。';

  @override
  String get deskSetupEpicboxServer => 'Epicbox 服务器';

  @override
  String get deskSetupChangePrefsSem => '更改偏好设置';

  @override
  String get deskSetupChangeNodeSem => '更改节点';

  @override
  String get deskSetupChangeEpicboxSem => '更改 Epicbox';

  @override
  String get deskSetupChange => '更改';

  @override
  String get deskSetupType => '类型';

  @override
  String get deskSetupAddress => '地址';

  @override
  String deskSetupExistingNode(String host) {
    return '$host 上的现有节点';
  }

  @override
  String get deskSetupBundledNode => '本地节点（内置）';

  @override
  String get deskSetupWhileSyncing => '同步期间';

  @override
  String get deskSetupWait => '等待';

  @override
  String get deskSetupDataFolder => '数据文件夹';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return '保存后会启动节点。首次同步需要数小时；期间钱包会打开，并使用 $node。';
  }

  @override
  String get deskSetupSaveStarts => '保存后会启动节点。首次同步需要数小时；期间钱包会打开。';

  @override
  String get deskSetupServer => '服务器';

  @override
  String get deskSetupOff => '关闭';

  @override
  String get deskSetAboutLicencesLead => '本钱包使用的开源软件。每个组件都保留各自的许可证；点击即可查看全文。';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop，BT Labs 出品：Apache-2.0。';

  @override
  String get deskSetAboutBrowserNotOpened => '未能打开浏览器';

  @override
  String get deskSetAboutOpen => '打开';

  @override
  String deskSetAboutVersion(String version) {
    return '版本  $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return '节点  $version';
  }

  @override
  String get deskSetAboutCommunity => '社区';

  @override
  String get deskSetAboutLicences => '许可证';

  @override
  String get deskSetAboutSource => '源代码';

  @override
  String get deskSetAboutView => '查看';

  @override
  String deskSetAboutChecked(String ago) {
    return '$ago检查过。';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version 已是最新版本';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return '有可用更新：$version';
  }

  @override
  String get deskSetAboutCouldNotCheck => '无法检查';

  @override
  String get deskSetAboutUpdates => '更新';

  @override
  String get deskSetAboutCheckNow => '立即检查';

  @override
  String get deskSetAboutAgoNow => '刚刚';

  @override
  String deskSetAboutAgoMin(int count) {
    return '$count 分钟前';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return '$count 小时前';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return '$count 天前';
  }

  @override
  String get deskSetAboutCopyLink => '复制链接';

  @override
  String get deskSetAboutCopied => '已复制';

  @override
  String get deskSetAboutNotCopied => '未复制';

  @override
  String get deskSetAppearTheme => '主题';

  @override
  String get deskSetAppearThemeHint => '“系统”会跟随电脑的设置。';

  @override
  String get deskSetAppearSystem => '系统';

  @override
  String get deskSetAppearDark => '深色';

  @override
  String get deskSetAppearLight => '浅色';

  @override
  String get deskSetAppearScale => '界面缩放';

  @override
  String get deskSetAppearScaleHint => '放大或缩小文字和控件。立即生效。';

  @override
  String get deskSetAppearLanguage => '语言';

  @override
  String get deskSetAppearLanguageHint => '立即生效。';

  @override
  String get deskSetAppearHideHint => '用圆点代替余额和金额。';

  @override
  String deskSetHelpNoMatchText(String query) {
    return '没有与“$query”匹配的主题。换个词试试。';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '找到的主题：$count',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => '没有匹配的主题';

  @override
  String get deskSetHelpReportText =>
      '描述出了什么问题。可以附上应用日志，日志会清除机密信息并加密发送给开发者。“保存到文件”会保留一份副本，供你手动发送。';

  @override
  String get deskSetHelpShowLess => '收起';

  @override
  String get deskSetHelpReadMore => '展开阅读';

  @override
  String get deskSetHelpEb1 => '发送方钱包把付款交给 Epicbox，并锁定相应的输出。';

  @override
  String get deskSetHelpEb2 => '接收方钱包上线时，Epicbox 把付款送达。该钱包加入自己的部分并签名。';

  @override
  String get deskSetHelpEb3 => '接收方钱包把它发回 Epicbox。';

  @override
  String get deskSetHelpEb4 => 'Epicbox 把它转回发送方钱包。';

  @override
  String get deskSetHelpSigns => '发送方钱包也签名，完成交易并广播到网络。';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '网络把它打包进区块。$count 个确认之后即为最终状态。',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 => '发送方钱包保存一个交易文件并锁定相应的输出。文件可以通过任何方式交给接收方。';

  @override
  String get deskSetHelpFile2 => '接收方打开文件。对方钱包加入自己的部分、签名，并保存一个回复文件。';

  @override
  String get deskSetHelpFile3 => '回复文件回到发送方手中。';

  @override
  String get deskSetHelpFile4 => '发送方在“完成交易”中打开回复文件。';

  @override
  String get deskSetHelpSender => '发送方';

  @override
  String get deskSetHelpFile => '文件传输';

  @override
  String get deskSetHelpRecipient => '接收方';

  @override
  String get deskSetHelpNetwork => '网络';

  @override
  String get deskSetHelpTravels => '一笔交易如何传递';

  @override
  String get deskSetHelpOverEpicbox => '经由 Epicbox';

  @override
  String get deskSetHelpWithFile => '使用文件';

  @override
  String deskSetHelpStep(int number, int total) {
    return '第 $number 步，共 $total 步';
  }

  @override
  String get deskSetHelpSearch => '搜索帮助';

  @override
  String get deskSetHelpSearchKeys => '按 / 搜索。按 Esc 清除搜索。';

  @override
  String get deskSetHelpSearchHint => '例如：文件、确认、助记词';

  @override
  String get deskSetHelpClear => '清除搜索';

  @override
  String get deskSetHelpTourAgain => '重新查看导览';

  @override
  String deskSetHelpTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个主题',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSecretProtect =>
      'Windows 无法保护钱包的机密（DPAPI 拒绝），因此未保存任何内容。请用你自己的账户和密码登录 Windows，不要通过远程或服务会话，然后重试。';

  @override
  String get deskKeyringMissingTitle => '未找到密钥环';

  @override
  String get deskKeyringMissingText =>
      'Epic Cash 将其设置和钱包的密封密码保存在系统密钥环中，但没有密钥环响应。请安装或启动密钥环（GNOME Keyring 或 KWallet），登录运行密钥环的桌面会话，然后选择重试。';

  @override
  String get deskKeyringLockedTitle => '密钥环已锁定';

  @override
  String get deskKeyringLockedText =>
      'Epic Cash 将其设置和钱包的密封密码保存在系统密钥环中，而它已锁定。请解锁它（使用您的登录密码），然后选择重试，或选择立即解锁让系统询问密码。';

  @override
  String get deskKeyringUnlockNow => '立即解锁';

  @override
  String get txStatusNotDelivered => '未送达';

  @override
  String get txDetailsNotDeliveredBody =>
      '此付款尚未到达 epicbox，收款人还没有收到。在重新发送或取消之前，你的资金保持锁定。';

  @override
  String get txDetailsSendAgainDone => '已重新发送。收款人的钱包上线后即可完成。';

  @override
  String get deskTxThisWallet => '此钱包';

  @override
  String get deskErrOldLinks => '此钱包的文件夹中含有链接；请手动复制它，或用助记词恢复。';

  @override
  String get deskErrOldIncomplete => '无法完整读取此钱包的文件夹；请手动复制它，或用助记词恢复。';

  @override
  String get deskErrOldSeedTooLarge => 'wallet.seed 文件太大，不可能是钱包种子文件。';

  @override
  String get deskErrSendUnbuildable => '无法用现有的币构建这笔发送。';

  @override
  String get deskErrNothingToConsolidate => '无需合并：可用输出少于两个。';

  @override
  String deskSetReportFileNone(String name) {
    return '$name（不包含）';
  }

  @override
  String deskSetReportFileAll(String name, String size) {
    return '$name（全部，$size）';
  }

  @override
  String deskSetReportFilePart(String name, String part, String size) {
    return '$name（$size 中的最后 $part）';
  }

  @override
  String get deskErrTxNotFound => '找不到该交易';

  @override
  String get deskTxNowUndelivered =>
      '未送达。这笔付款没有到达 Epicbox 服务器，收款人没有收到。请重新发送，或取消以释放资金。';

  @override
  String get deskTxStatusUndelivered => '未送达';

  @override
  String get deskTxSendAgain => '重新发送';

  @override
  String get deskTxNotSent => '未发送';

  @override
  String get deskTxSentAgain => '已重新发送';

  @override
  String get deskTxSentAgainText => '收款人的钱包上线后即可完成。';

  @override
  String get deskSendFeeChangedTitle => '手续费已变化';

  @override
  String deskSendFeeChangedText(String fee, String was) {
    return '自本次核对以来钱包的输出已变化，此次发送的手续费现在是 $fee EPIC，而不是 $was EPIC。请核对后再次发送。';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max 字节';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return '消息超过 $max 字节，请缩短。';
  }

  @override
  String get deskSetPhraseCopyTitle => '复制助记词？';

  @override
  String get deskSetPhraseCopyText => '任何拿到这些单词的人都能转走你的资金。请把复制的内容保存在安全的地方。';

  @override
  String get deskOutAdvanced => '管理输出';

  @override
  String get deskOutStrategyHint =>
      '一笔发送花掉哪些输出。“最小”花掉最少的小额输出，其余仍可使用；“全部”花掉所有输出，并返回一个输出。可在“发送”页的“高级”中为单次发送更改。';

  @override
  String get txStatusNotPosted => '不在网络上';

  @override
  String get txStatusStalled => '已停滞';

  @override
  String get txDetailsStalledBody => '已停滞，未送达。你的付款还没有进入网络。请重新发送。';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      '这笔付款没有到达收款人的钱包，对方没有收到。在重新发送或取消之前，你的资金会一直锁定。';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service 还没有发布你的付款。';
  }

  @override
  String get deskTxStatusNotPosted => '不在网络上';

  @override
  String get deskTxNowNotPosted => '不在网络上。节点没有接受这笔付款。请重新广播；同一笔付款不会成交两次。';

  @override
  String get deskTxBroadcastAgain => '重新广播';

  @override
  String get deskTxBroadcastDone => '已发送到网络';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return '未送达。收款人的钱包没有接收这笔付款（$method），对方没有收到。请重新发送，或取消以释放资金。';
  }

  @override
  String get deskInvPayStalled => '已停滞';

  @override
  String deskInvPayerStalledTitle(String service) {
    return '你给 $service 的付款已停滞';
  }

  @override
  String get deskInvPayerStalledText =>
      '未送达：付款还没有进入网络，资金仍被锁定。“重新发送”会再发送一次，无需再次批准。';

  @override
  String get deskTxLabelAdd => '添加标签';

  @override
  String get deskTxLabelEdit => '编辑标签';

  @override
  String get deskTxLabelHint => '添加标签';

  @override
  String get deskTxLabelField => '标签';

  @override
  String get deskTxLabelTip => '这笔付款的名称，只给你自己看。显示在“活动”和导出文件中。';

  @override
  String get deskTxLabelAdded => '已添加标签';

  @override
  String get deskTxLabelSaved => '已保存标签';

  @override
  String get deskTxLabelRemoved => '已删除标签';

  @override
  String get deskTxLabelNotSaved => '标签未保存';

  @override
  String get deskTxDetailsAdd => '添加详情';

  @override
  String get deskTxDetailsEdit => '编辑';

  @override
  String get deskTxDetailsTitleAdd => '添加详情';

  @override
  String get deskTxDetailsTitleEdit => '编辑详情';

  @override
  String get deskTxDetailsTip =>
      '仅适用于扫描找到的付款。在“活动”、详情和导出文件中会标为由你添加。金额、日期和确认数不会改变。';

  @override
  String get deskTxDetailsFrom => '来自';

  @override
  String get deskTxDetailsFromTip => '付款人，仅供你记录。未验证，也不会用于付款证明。';

  @override
  String get deskTxDetailsFromHint => '发送方地址';

  @override
  String get deskTxDetailsFromBad => '请使用 Epicbox、http(s) 或 .onion 地址。';

  @override
  String get deskTxDetailsNote => '备注';

  @override
  String get deskTxDetailsAdded => '已添加详情';

  @override
  String get deskTxDetailsSaved => '已保存详情';

  @override
  String get deskTxDetailsRemoved => '已删除详情';

  @override
  String get deskTxDetailsNotSaved => '详情未保存';

  @override
  String get deskTxManualTag => '由你添加';

  @override
  String deskTxManualTip(String date) {
    return '你于 $date 添加。并非来自区块链。';
  }

  @override
  String get deskTxManualTipNoDate => '由你添加。并非来自区块链。';

  @override
  String deskTxManualTipFrom(String date) {
    return '你于 $date 添加。并非来自区块链，未验证。';
  }

  @override
  String get deskTxManualTipFromNoDate => '由你添加。并非来自区块链，未验证。';

  @override
  String get deskHistConflictTitle => '详情不一致';

  @override
  String deskHistConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '备份中有 $n 笔你描述过的付款带有不同的详情。除非你另行选择，否则保留你的内容。',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => '我的';

  @override
  String get deskHistConflictBackup => '备份';

  @override
  String get deskHistConflictKeepAll => '全部保留我的';

  @override
  String get deskHistConflictImport => '导入';

  @override
  String get deskHistConflictEmpty => '空';

  @override
  String deskHistImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已替换 $n 项详情，其余保留你的内容。',
    );
    return '$_temp0';
  }

  @override
  String sendRelayUnknown(String relay) {
    return '此应用不认识服务器 $relay。发送前请检查地址。';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay 没有响应。';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay 没有响应，收款人还没有收到此付款。在重新发送或取消之前，你的资金保持锁定。';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return '未送达：$relay 没有响应。这笔付款保留在“活动”中；在那里取消即可解锁资金。';
  }

  @override
  String deskErrRelayNoAnswer(String relay) {
    return '$relay 没有响应。';
  }

  @override
  String get deskSendRelayUnknownTitle => '未知的 Epicbox 服务器';

  @override
  String deskSendRelayUnknownText(String relay) {
    return '此应用不认识服务器 $relay。发送前请检查地址。你仍然可以发送。';
  }

  @override
  String deskTxNowUndeliveredRelay(String relay) {
    return '未送达。$relay 没有响应，收款人没有收到这笔付款。请重新发送，或取消以释放资金。';
  }

  @override
  String get deskInvNoticeReceiveSuperseded =>
      '您使用此钱包的另一台设备接收了一笔本设备也在接收的付款。请重新核对余额，在这里查看它。';

  @override
  String deskHistConflictLeadOldWallet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '旧钱包的历史中有 $n 笔你描述过的付款带有不同的详情。除非你另行选择，否则保留你的内容。',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => '旧钱包';

  @override
  String get deskHistConflictApply => '应用';

  @override
  String get deskTxProofNone => '这笔付款没有付款证明。';

  @override
  String get deskUpdAvailable => '有可用更新';

  @override
  String deskUpdNotice(String version) {
    return '有可用更新 · $version';
  }

  @override
  String deskUpdDownload(String version) {
    return '下载 $version';
  }

  @override
  String get deskUpdOpensPage => '打开下载页面';

  @override
  String deskUpdDownloading(String percent) {
    return '正在下载 $percent %';
  }

  @override
  String get deskUpdRestart => '重启以更新';

  @override
  String deskUpdReady(String version) {
    return '$version 已就绪';
  }

  @override
  String get deskUpdRestartHint => '应用会关闭、安装更新，然后重新打开。';

  @override
  String get deskUpdFailed => '无法下载更新';

  @override
  String get deskUpdTryAgain => '重试';

  @override
  String get deskUpdInstallFailed => '无法安装更新';

  @override
  String get deskUpdOpenPage => '打开下载页面';

  @override
  String get deskUpdErrDamaged => '文件与已签名的更新信息不符。';

  @override
  String get deskUpdErrStopped => '下载已中断。';

  @override
  String get deskUpdErrInstall => '无法替换为新版本。';

  @override
  String get deskUpdUnfinished => '更新未完成。请重试。';

  @override
  String get advExperimental => '实验性';

  @override
  String get advTitle => '高级';

  @override
  String get advStateOff => '关闭';

  @override
  String get advIntro => '一开始全部关闭。每个开关会把钱包的一个部分加到它所属的位置。';

  @override
  String get advShowsHeader => '显示更多';

  @override
  String get advNetworkHeader => '网络';

  @override
  String get advNetworkHint =>
      '钱包如何连接网络。“标准”直接连接；Tor 可在“隐私与网络”中开启。“仅 Tor”从不直接连接：没有 Tor 时，钱包保持离线，并在主页上提示。“离线”只限这部手机和你的本地网络：二维码付款和文件传输仍可通过正在使用的节点进行；如果你的网络中有节点，还可以向本地地址发送，余额也会刷新。';

  @override
  String get advOutputs => '输出';

  @override
  String get advOutputsHint =>
      '在“钱包”下和主页上显示“输出”页面。它列出组成余额的币，可以拆分或合并，并设置发送使用的默认值。正在进行的拆分或合并会让该页面保持可见。';

  @override
  String get advTechnical => '技术详情';

  @override
  String get advTechnicalHint =>
      '在付款详情中显示技术信息行：内核、slate ID、承诺和区块高度。在“账单”中显示地址轮换和被丢弃消息的数量。';

  @override
  String get advSendOptions => '发送选项';

  @override
  String get advSendOptionsHint =>
      '在“设置 › 交易”中显示发送的“策略”和“拆分找零”：一笔发送花掉哪些输出，以及找零是否拆分。只要其中一项不是默认值，就保持可见。';

  @override
  String get advServerDetails => '服务器详情';

  @override
  String get advServerDetailsHint =>
      '在服务器列表和状态卡片中显示主机、延迟、版本和区块高度，并在“接收”中显示中继地址。';

  @override
  String get advRecheckHeight => '从某个高度重新核对';

  @override
  String get advRecheckHeightHint =>
      '让“重新核对余额”可以从某个区块高度或日期开始，而不是从第一个区块开始。更快，也是跳过早期记录的唯一办法。恢复钱包时始终可以选择。';

  @override
  String get advModeStandard => '标准';

  @override
  String get advModeStandardLine => '直接连接。可在“隐私与网络”中开启 Tor。';

  @override
  String get advModeTorOnly => '仅 Tor';

  @override
  String get advModeTorOnlyLine => '所有连接都经过 Tor。没有 Tor 时，钱包保持离线并会提示。';

  @override
  String get advModeOffline => '离线';

  @override
  String get advModeOfflineLine =>
      '只限这部手机和你的本地网络。二维码付款和文件传输仍可通过正在使用的节点进行；其余一切会等到你切换回来。';

  @override
  String get advTorOnlyNote => '“仅 Tor”会暂停通知：注册通知会暴露这部手机的地址。';

  @override
  String get advOfflineNote =>
      '离线会暂停 Epicbox、Tor、状态检查和通知。二维码付款和文件传输仍可使用：它们通过正在使用的节点读取链并广播，公共节点也可以。如果你的本地网络中有节点，“重新核对余额”以及向本地地址的链接发送也可使用。节点自己的对等节点是节点本身的设置。';

  @override
  String get advReset => '再次全部隐藏';

  @override
  String get advHomeOffline => '离线模式';

  @override
  String get advHomeTorOnlyWaiting => '仅 Tor · 等待 Tor';

  @override
  String get advBuiltInNode => '内置节点';

  @override
  String get advLogs => '日志';

  @override
  String get deskSetFrameAdvanced => '高级';

  @override
  String get deskSetAdvIntro => '一开始全部关闭。每个开关会把钱包的一个部分加到它所属的位置。';

  @override
  String get deskSetAdvShows => '显示更多';

  @override
  String get deskSetAdvOutputs => '输出';

  @override
  String get deskSetAdvOutputsHint =>
      '在侧边栏显示“输出”页面。它列出组成余额的币，可以拆分或合并，并设置发送使用的默认值。正在进行的拆分或合并会让该页面保持可见。';

  @override
  String get deskSetAdvTechnical => '技术详情';

  @override
  String get deskSetAdvTechnicalHint =>
      '在每笔交易上显示“技术详情”折叠区：slate ID、内核、区块高度、核心的状态和类型，以及付款证明。不开启时，交易上的“更多”链接可以一次性显示它们。在“账单”中显示高级折叠区。';

  @override
  String get deskSetAdvSendOptions => '发送选项';

  @override
  String get deskSetAdvSendOptionsHint =>
      '在“发送”中加入一个折叠区，单笔发送可以在其中选择花掉哪些输出（“最小”或“全部”），以及是否拆分找零。默认值仍在“输出”中。';

  @override
  String get deskSetAdvServerDetails => '服务器详情';

  @override
  String get deskSetAdvServerDetailsHint =>
      '在节点和 Epicbox 列表、侧边栏的状态行以及状态卡片中显示主机、延迟、版本和区块高度。';

  @override
  String get deskSetAdvRecheck => '从某个高度重新核对';

  @override
  String get deskSetAdvRecheckHint =>
      '让“重新核对余额”同时丢弃未确认的交易。无论此项如何设置，恢复钱包时都会向所有人提供起始区块。';

  @override
  String get deskSetAdvBuiltInNode => '内置节点';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      '让这台电脑运行自己的节点：“节点”下的“这台电脑”选项、它的同步面板，以及概览中的“启动节点”。同步整条链需要数小时和数 GB 磁盘空间。已在运行的节点会保留它的各行。';

  @override
  String get deskSetAdvLogs => '日志';

  @override
  String get deskSetAdvLogsHint =>
      '在“帮助”下显示“日志”分组：打开日志文件夹、清除日志。无论是否开启，“报告问题”都会附上日志。';

  @override
  String get deskSetAdvNetwork => '网络';

  @override
  String get deskSetAdvNetworkHint =>
      '钱包如何连接网络。“标准”直接连接；Tor 可在“隐私”中开启。“仅 Tor”从不直接连接：没有 Tor 时，钱包保持离线，并在侧边栏中提示。“离线”只限这台电脑和你的本地网络：文件传输仍可通过正在使用的节点进行；如果这里或你的网络中有节点，还可以向本地地址发送并通过“链接”接收，余额也会刷新。内置节点会继续运行，它的对等节点是节点本身的设置。';

  @override
  String get deskSetAdvModeStandard => '标准';

  @override
  String get deskSetAdvModeStandardText => '直接连接。可在“隐私”中开启 Tor。';

  @override
  String get deskSetAdvModeTorOnly => '仅 Tor';

  @override
  String get deskSetAdvModeTorOnlyText => '所有连接都经过 Tor。没有 Tor 时，钱包保持离线并会提示。';

  @override
  String get deskSetAdvModeOffline => '离线';

  @override
  String get deskSetAdvModeOfflineText =>
      '只限这台电脑和你的本地网络。你的节点继续运行；它的对等节点是节点本身的设置。';

  @override
  String get deskSetAdvTorOnlyNote => '“仅 Tor”会关闭 链接 · HTTP 接收：普通地址会暴露这台电脑。';

  @override
  String get deskSetAdvOfflineNote =>
      'Epicbox、Tor 和状态检查会暂停。文件传输仍可通过正在使用的节点进行，公共节点也可以。如果这台电脑上或你的网络中有节点，“重新核对余额”以及向本地地址的“链接”发送也可使用。';

  @override
  String get deskSetAdvNotInBuild => '此版本不含';

  @override
  String get deskSetAdvReset => '再次全部隐藏';

  @override
  String deskSetAdvOn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已开启 $n 个开关',
    );
    return '$_temp0';
  }

  @override
  String get deskShellOffline => '离线模式';

  @override
  String get deskShellTorOnlyWaiting => '仅 Tor · 等待 Tor';

  @override
  String get deskSetAcctAutoLockHint => '在这段时间内没有按键或移动鼠标时锁定钱包。关闭后，只能用“锁定钱包”锁定。';

  @override
  String get netBlockOffline => '“高级”中已开启离线模式。';

  @override
  String get netBlockTorOnly => '“高级”中已开启“仅 Tor”。';

  @override
  String get netBlockWaitingForTor => '等待 Tor。';

  @override
  String get receiveOfflineLine => '离线模式开启时，无法用这种方式接收。';

  @override
  String get txDetailsMore => '更多';

  @override
  String get restoreStartFromLink => '从某个日期或高度开始';

  @override
  String get homeOfflineDetail => '“高级”中已开启离线模式。余额是上次看到的。';

  @override
  String get homeWaitingTorDetail => '“高级”中已开启“仅 Tor”。正在等待 Tor 连接。';

  @override
  String get settingsRescanBodyPlain => '钱包从第一个区块开始，重新查找它的资金。这可能需要很长时间。';

  @override
  String get slNodeField => '节点地址';

  @override
  String get slRelayField => 'Epicbox 服务器';

  @override
  String get slFieldHint => '粘贴或输入，用于筛选或添加';

  @override
  String slSwitchTitle(String host) {
    return '切换到 $host？';
  }

  @override
  String get slSwitchBody => '你的 Epicbox 地址会改变。请分享新的地址。';

  @override
  String get slSwitch => '切换';

  @override
  String get slHelpAddable => '不在列表中。';

  @override
  String slHelpMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个匹配项。',
      zero: '无匹配项。',
    );
    return '$_temp0';
  }

  @override
  String get slClear => '清除';

  @override
  String slAddRow(String host) {
    return '添加 $host';
  }

  @override
  String get slAddTestsNode => '先测试节点，再提供切换。';

  @override
  String get slAddTestsRelay => '先测试服务器，再提供切换。';

  @override
  String slAdded(String host) {
    return '已添加 $host。';
  }

  @override
  String get slRemove => '移除';

  @override
  String slRemoved(String host) {
    return '已移除 $host。';
  }

  @override
  String get slUndo => '撤销';

  @override
  String get slInUseSwitchFirst => '使用中。请先切换。';

  @override
  String get slRestore => '恢复已移除的服务器';

  @override
  String slRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已移除 $count 个',
    );
    return '$_temp0';
  }

  @override
  String get slRestored => '已恢复已移除的服务器。';

  @override
  String get slRelayWarning => '切换会改变你的地址；发送方需要新地址。';

  @override
  String get slNotAnAddress => '不是服务器地址。请使用 host 或 host:port。';

  @override
  String get slRelayNoAnswer => '此服务器无应答。未添加任何内容。';

  @override
  String deskSlRemoveHost(String host) {
    return '移除 $host';
  }

  @override
  String get deskSlInUse => '使用中';

  @override
  String get deskSlHealthUnknown => '状态未知';

  @override
  String get deskSlNodeNoAnswer => '此节点无应答。未添加任何内容。';

  @override
  String get deskSlTorWait => 'Tor 尚未连接。未添加任何内容。';

  @override
  String deskSlLatency(String ms) {
    return '$ms 毫秒';
  }

  @override
  String get deskSlDefault => '默认';

  @override
  String deskSlTesting(String host) {
    return '正在测试 $host…';
  }

  @override
  String get deskSlSetupEpicboxOn => '通过 Epicbox 接收';

  @override
  String get deskSlHelpChoose => '选择一个，或输入以筛选列表或添加服务器。';

  @override
  String get deskOnbRestoreFromLink => '从某个区块高度开始';

  @override
  String get deskOnbRestoreFromHide => '检查整条链';

  @override
  String get deskOnbRestoreFromLabel => '从区块开始';

  @override
  String get deskOnbRestoreFromHint => '区块高度';

  @override
  String get deskOnbRestoreFromHelp => '仅当钱包的第一笔付款发生在此区块之后才使用。留空则检查整条链。';

  @override
  String get deskOnbRestoreFromInvalid => '只能输入数字，或留空。';

  @override
  String get deskNetOfflineReason => '“高级”中已开启离线模式。';

  @override
  String get deskNetWaitingTorReason => '等待 Tor。“高级”中已开启“仅 Tor”。';

  @override
  String get deskNetTorOnlyLine => '“高级”中已开启“仅 Tor”。';

  @override
  String get deskNetOpenAdvanced => '打开“高级”';

  @override
  String get deskNetSendFileHint => '文件传输仍然可用。';

  @override
  String get deskNetRecvOfflineText => '你的地址保持不变。离线模式关闭之前，什么都收不到。';

  @override
  String get deskNetRecvWaitTorText => 'Tor 连接后才开始接收。文件传输仍然可用。';

  @override
  String get deskNetCantReceive => '离线时无法接收。';

  @override
  String get deskRailOffline => '离线';

  @override
  String get deskTourAdvancedTitle => '高级';

  @override
  String get deskTourAdvancedText => '仅 Tor 模式、输出和技术详情都在这里。需要什么就开启什么。';

  @override
  String get deskTxMore => '更多';

  @override
  String get deskTxLess => '收起';

  @override
  String get settingsSectionTransactions => '交易';

  @override
  String get settingsHubMethods => '方式';

  @override
  String get settingsHubDefault => '默认';

  @override
  String get settingsHubSendDefaults => '发送默认设置';

  @override
  String get txMethodsHeader => '付款方式';

  @override
  String get txFamilyLinkLine => '直接发送到对方钱包，前提是双方都已打开。';

  @override
  String get txFamilyDirectLine => '当面传递，两个钱包之间无需连接。';

  @override
  String get txLinkHttpLine => '向网址付款；从这个 Wi-Fi 网络收款。';

  @override
  String get txLinkHttpHint =>
      '链接 · HTTP 通过网址直接向对方钱包付款，并为这部手机提供一个同一 Wi-Fi 网络中的钱包可以付款的地址。双方钱包都必须打开。它在传输途中不加密，无法从互联网或移动数据访问，Tor 开启时也会关闭。会在“发送”和“接收”中加入 链接 · HTTP。';

  @override
  String get txLinkTorLine => '向 onion 地址付款；通过这部手机的 Tor 地址收款。';

  @override
  String get txLinkTorHint =>
      '链接 · Tor 通过 onion 地址直接向对方钱包付款，并为这部手机提供一个可收款的 Tor 地址。双方钱包都必须打开。需要 Tor：“隐私与网络”中的 Tor 开关让钱包的连接走 Tor；这个开关只负责开启地址。会在“发送”和“接收”中加入 链接 · Tor。';

  @override
  String get txLinkTorNeedsTor => '需要 Tor。请在“隐私与网络”中开启。';

  @override
  String get txLastMethodNotice => '至少保留一种付款方式开启。';

  @override
  String get txEpicboxHint =>
      'Epicbox 通过中继付款，所以对方的钱包不必打开。关闭后，钱包不连接任何中继：没有 Epicbox 付款、账单或通知。其他方式仍可使用。';

  @override
  String get txDirectLine => '向网址和 onion 地址付款；直接从其他钱包收款。';

  @override
  String get txDirectHint =>
      '“链接”通过网址或 onion 地址直接向对方钱包付款，这部手机也能以同样方式收款。双方钱包都必须打开。HTTP 在这个 Wi-Fi 网络中可用；Tor 需要 Tor。会在“发送”和“接收”中加入“链接”。';

  @override
  String get txFileLine => '用你自己传递的文件付款或收款。';

  @override
  String get txFileHint =>
      '“文件传输”生成一个交易文件，你用任何方式（消息、邮件、数据线）交给对方，对方再回传一个。两个钱包之间不需要连接。会在“发送”和“接收”中加入“文件传输”。';

  @override
  String get txStartHeader => '发送默认方式';

  @override
  String get txStartNote => '在“发送”中仍可选择其他方式。';

  @override
  String get txDefaultsHeader => '发送默认设置';

  @override
  String get outputsDefaultsMoved => '发送默认设置已移到“设置 › 交易”';

  @override
  String get advNodeFailover => '节点故障切换';

  @override
  String get advNodeFailoverHint => '当你的节点不再响应时，钱包在本次会话中改用列表里下一个可用的节点。';

  @override
  String nodeFailoverSwitched(String host) {
    return '节点无响应。已切换到 $host。';
  }

  @override
  String nodeFailoverInsteadOf(String host) {
    return '代替 $host';
  }

  @override
  String get deskSetAdvNodeFailover => '节点故障切换';

  @override
  String get deskSetAdvNodeFailoverHint => '当你的节点不再响应时，钱包在本次会话中改用列表里下一个可用的节点。';

  @override
  String deskNodeFailoverSwitched(String host) {
    return '节点无响应。已切换到 $host。';
  }

  @override
  String deskNodeFailoverInsteadOf(String host) {
    return '代替 $host';
  }

  @override
  String get netOfflineOnlyLocal => '离线：只能用本地地址。';

  @override
  String get netOfflineNoPeers => '你的节点没有对等节点：付款会留在它的交易池里，直到它重新连接。';

  @override
  String get netOfflineNodeHint => '使用节点读取链并广播。为了最大限度的隐私，请使用本地节点。';

  @override
  String get netOfflineNodeLine => '使用节点';

  @override
  String get netBlockEpicboxOff => 'Epicbox 已在 设置 › 交易 中关闭。';

  @override
  String netBlockMethodOff(String method) {
    return '$method 已在设置 › 交易中关闭。';
  }

  @override
  String get txEpicboxLine => '通过中继付款或收款。对方的钱包可以处于关闭状态。';

  @override
  String get txEpicboxOffTitle => '关闭 Epicbox？';

  @override
  String txEpicboxOffPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款正在等待通过 Epicbox 的回复。Epicbox 再次开启后它们才会到达。',
    );
    return '$_temp0';
  }

  @override
  String get txEpicboxOffAction => '关闭';

  @override
  String get pushNoticeOffEpicbox => '通知已关闭：通知需要 Epicbox。';

  @override
  String get settingsPushNeedsEpicbox => '需要 Epicbox';

  @override
  String sendContactOnlyEpicbox(String name) {
    return '$name 只有 Epicbox 地址。';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name 只有 $method 的地址。';
  }

  @override
  String get receiveEpicboxOffText => '发送方的付款会在中继等待，直到 Epicbox 再次开启。';

  @override
  String get receiveNoMethods => '没有开启任何收款方式';

  @override
  String get receiveNoMethodsBody => '请在 设置 › 交易 中开启一种。';

  @override
  String get receiveNoMethodsButton => '打开设置';

  @override
  String get deskErrOfflineOnlyLocal => '离线：只能用本地地址。';

  @override
  String get deskNetOfflineNoPeers => '你的节点没有对等节点：付款会留在它的交易池里，直到它重新连接。';

  @override
  String get deskOutDefaultsMoved => '发送的“策略”和“拆分找零”在“设置 › 交易”中设置。';

  @override
  String get deskOutDefaultsOpen => '打开“交易”';

  @override
  String get deskSetFrameTransactions => '交易';

  @override
  String get deskSetTxMethods => '付款方式';

  @override
  String get deskSetTxEpicboxHint =>
      '通过 Epicbox 服务器付款和收款。大多数付款都走这条路。关闭后，钱包不连接任何 Epicbox 服务器：没有 Epicbox 付款或账单。其他方式仍可使用。';

  @override
  String get deskSetTxDirectHint =>
      '通过网址（http://host:3415）在钱包之间直接付款和收款，中间没有服务器。仅在双方钱包都打开时有效；Tor 开启时关闭。会在“发送”中加入 链接 · HTTP，并在“接收”中加入它的地址。';

  @override
  String get deskSetTxFileHint =>
      '通过传递交易文件付款和收款，无需网络。会在“发送”中加入“文件传输”，并在“接收”中加入文件步骤。';

  @override
  String get deskSetTxSend => '发送';

  @override
  String get deskSetTxStart => '发送默认方式';

  @override
  String get deskSetTxStartHint => '“发送”页面打开时使用的方式。单笔付款时，仍可在“发送”页面更改。';

  @override
  String get deskSendMethodHeader => '付款方式';

  @override
  String get sendRequestTitle => '付款请求';

  @override
  String get sendRequestCheck => '请检查金额，然后继续。';

  @override
  String get sendRequestDismiss => '关闭';

  @override
  String get sendAmountFromCode => '来自付款码';

  @override
  String sendAmountCodeAsked(String amount) {
    return '付款码要求的金额为 $amount。';
  }

  @override
  String get sendCodeAmountInvalid => '此码中的金额无效，已忽略。';

  @override
  String get sendCodeAmountTooLarge => '此码中的金额过大，已忽略。';

  @override
  String get sendCodeTooLong => '此码的一部分过长，已忽略。';

  @override
  String get payeeNameLabel => '收款方自称的名称（未验证）';

  @override
  String get payeeNoteLabel => '收款方的备注（未验证）';

  @override
  String get payeeUnverifiedTitle => '未验证';

  @override
  String get payeeUnverifiedHint => '名称和备注由制作此码的人写入，没有人核实。请核对地址和金额，而不是名称。';

  @override
  String get sendNoteFromCodeHelper => '来自付款码。对方也能看到。';

  @override
  String get sendOriginQr => '来自二维码';

  @override
  String get sendOriginLink => '来自链接';

  @override
  String get sendOriginPasted => '已粘贴';

  @override
  String get sendDirectHost => '主机';

  @override
  String get sendPlainHttpRow => '未加密（纯 HTTP）';

  @override
  String get scanNotEpicTitle => '不是 Epic 码';

  @override
  String get scanNotEpicBody => '这不是 Epic 地址，也不是付款码。';

  @override
  String get scanBadAddress => '此码中的地址无效。';

  @override
  String get scanWrongNetworkTitle => '其他网络';

  @override
  String get scanWrongNetworkBody => '此地址属于另一个 Epic 网络，此钱包无法向它付款。';

  @override
  String get scanSlateTextBody => '这是交易文件的文本，不是地址。';

  @override
  String get commonOpen => '打开';

  @override
  String get scanPairingTitle => '配对链接';

  @override
  String get scanPairingUnavailable => '此版本不支持配对。';

  @override
  String get scanCodeTextLabel => '扫描到的文本';

  @override
  String get scanCopied => '已复制';

  @override
  String get linkWaitingNotice => '收到付款链接';

  @override
  String get linkFinishCurrentFirst => '请先完成当前付款。';

  @override
  String get deskSendToQrPayment => '这是二维码付款码，请用 Epic Cash Mobile 扫描。';

  @override
  String get deskSetRecvTorTitle => '链接 · Tor 接收';

  @override
  String get deskSetRecvTorText => '钱包打开时，直接从另一个钱包经本钱包的 Tor 地址接收。';

  @override
  String get deskSetTxTorHint =>
      '通过 onion 地址、经由 Tor 在钱包之间直接付款和收款，中间没有服务器。仅在双方钱包都打开时有效。需要 Tor：“隐私”中的 Tor 开关让钱包的连接走 Tor；这个开关只负责开启地址。会在“发送”中加入 链接 · Tor，并在“接收”中加入它的地址。';

  @override
  String get deskSetTxTorNeedsTor => 'Tor 已关闭。请在“隐私”中开启，才能通过 Tor 地址收款。';

  @override
  String get deskSetTxLastMethod => '至少保留一种付款方式开启。';

  @override
  String get deskRecvTorOffTitle => '链接 · Tor 收款需要 Tor。';

  @override
  String get deskRecvTorOffText =>
      'Tor 开启时，Tor 地址才可用。Tor 是设置 › 隐私中的开关，它让钱包的连接走 Tor。';

  @override
  String get deskSetupSaveFailedTitle => '设置未保存';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason。不保存时，钱包使用目前已存储的设置，之后可在“设置”中更改。';
  }

  @override
  String get deskSetupSkipSave => '不保存并继续';

  @override
  String get deskSetupResumeLead => '上次设置未完成。钱包通过 Epic 节点读取区块链并发送交易。';

  @override
  String deskErrProofContactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已将 $count 个联系人与现有联系人合并',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsKnown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个联系人此前已保存',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已跳过 $count 个联系人：没有有效地址',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactAddressesLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个地址未添加：与已保存的联系人冲突',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofContactsUnreadable => '部分旧联系人无法读取：旧通讯录已损坏';

  @override
  String get deskErrProofContactsFailed => '联系人未全部保存：无法写入通讯录';

  @override
  String get deskTxStatusSenderPosted => '发送方称已广播';

  @override
  String get deskTxNowSenderPosted => '已签名并发回。发送方称已广播到网络；区块链确认后即完成。';

  @override
  String get deskImpWrongTypePasted => '粘贴的文本不是交易。请粘贴发送方提供的完整文本，或选择其文件。';

  @override
  String get pairTitle => '配对';

  @override
  String pairWithName(String name) {
    return '与 $name 配对';
  }

  @override
  String get pairLead => '与对方配对一次。之后两个钱包之间的付款文件和账单都会被密封：只有这两个钱包能读取。';

  @override
  String get pairInPerson => '当面';

  @override
  String get pairInPersonHint => '出示你的码并扫描对方的码';

  @override
  String get pairOnline => '在线';

  @override
  String get pairOnlineHint => '发送邀请链接，或念出配对词';

  @override
  String get pairOfflineHint => '你已离线。请改为当面配对。';

  @override
  String get pairEnter => '输入链接或词';

  @override
  String get pairEnterHint => '粘贴邀请链接，或输入收到的词';

  @override
  String get pairNotPaired => '未配对';

  @override
  String get pairNotPairedHint => '配对后可密封付款文件并允许账单。';

  @override
  String get pairInPersonTitle => '当面配对';

  @override
  String get pairShowMyCode => '出示我的码';

  @override
  String get pairScanTheirs => '扫描对方的码';

  @override
  String get pairShowCodeCaption => '让对方扫描此码，然后扫描对方的码。';

  @override
  String get pairScanCaption => '双方都要扫描。两个码都读取后会打开词语核对。';

  @override
  String get pairScanPrompt => '将相机对准对方的码';

  @override
  String get pairSeenAs => '对方看到你的名字';

  @override
  String get pairUseWords => '改用配对词';

  @override
  String get pairCameraDeniedTitle => '未允许使用相机';

  @override
  String get pairCameraDeniedBody => '允许相机以进行扫描，或改用配对词。';

  @override
  String get pairOpenSettings => '打开设置';

  @override
  String get pairWordsTitle => '配对词';

  @override
  String get pairWordsLead => '按此顺序念给对方。对方的钱包会根据这些词找到邀请。';

  @override
  String get pairWordsGoodFor => '10 分钟内有效';

  @override
  String get pairWordsLastMinute => '剩余不到一分钟';

  @override
  String get pairWordsFooter => '在邀请过期前，任何拥有这些词的人都能回应此邀请。之后请一起核对词语。';

  @override
  String get pairWordsNew => '新词';

  @override
  String get pairWordsCopy => '复制词';

  @override
  String get pairWordsExpiredTitle => '这些词已过期';

  @override
  String get pairWordsExpiredBody => '生成新的词并重新念出。';

  @override
  String get pairWordsNeedEpicbox => '配对词需要 Epicbox，因此现在不可用。';

  @override
  String pairWordsDesktopChip(String time) {
    return '配对词：剩余 $time';
  }

  @override
  String get pairEnterLead => '粘贴邀请链接，或输入收到的五个词。';

  @override
  String get pairEnterField => '邀请链接或词';

  @override
  String get pairEnterNotFound => '找不到与这些词对应的邀请。请检查，或索取新的词。';

  @override
  String get pairEnterTryAgain => '重试';

  @override
  String get pairEnterDesktopHint => '粘贴的链接或输入的词相当于在手机上扫描。';

  @override
  String get pairCardCopy => '复制我的配对链接';

  @override
  String get pairCardHint => '当面配对且没有摄像头：双方钱包各自在上方粘贴对方的配对链接。';

  @override
  String pairCardBackTitle(String name) {
    return '现在把你的码交给 $name';
  }

  @override
  String pairCardBackBody(String name) {
    return '在 $name 的钱包中“输入链接或词”处粘贴此链接。然后一起核对词语。';
  }

  @override
  String get pairEnterDesktopPlaceholder => '粘贴邀请链接，或输入五个词';

  @override
  String get pairOnlineTitle => '在线配对';

  @override
  String get pairOnlineLead => '通过你们已在使用的任何渠道发送邀请。对方的钱包打开邀请后即完成配对。';

  @override
  String get pairOnlineLeadByHand =>
      '通过你们已在使用的任何渠道发送邀请。对方的回复会经同样的方式返回：将其粘贴到“输入链接或词”。';

  @override
  String get pairExpiresIn => '邀请过期时间';

  @override
  String get pairExpiry1h => '1 小时';

  @override
  String get pairExpiry24h => '24 小时';

  @override
  String get pairExpiry7d => '7 天';

  @override
  String get pairWhatTheyReceive => '对方收到的内容';

  @override
  String pairShareText(String name, String link, String date) {
    return '$name 想与你配对 Epic Cash 钱包。\n\n在 Epic Cash 中打开：\n$link\n\n过期时间：$date。';
  }

  @override
  String get pairShareWarning =>
      '在邀请过期前，任何拥有此邀请的人都能以你的身份配对。只发送给你要配对的人，然后一起核对词语。';

  @override
  String get pairShareInvite => '分享邀请';

  @override
  String get pairCopyInvite => '复制邀请';

  @override
  String get pairUseWordsShort => '用配对词';

  @override
  String get pairInviteSentTitle => '邀请已发送';

  @override
  String pairInviteSentBody(String name) {
    return '$name 的钱包打开邀请后即完成配对。你可以离开此页面；邀请会保留在“联系人 › 待处理邀请”中。';
  }

  @override
  String get pairCancelInvite => '取消邀请';

  @override
  String pairCancelInviteTitle(String name) {
    return '取消给 $name 的邀请？';
  }

  @override
  String pairCancelInviteBody(String name) {
    return '如果对方的钱包之后打开它，会看到“$name 已取消此邀请”。';
  }

  @override
  String pairIncomingTitle(String name) {
    return '与 $name 配对？';
  }

  @override
  String get pairNameClaimed => '名字由对方选择 · 尚未核对';

  @override
  String get pairNameClaimedShort => '名字由对方选择';

  @override
  String pairCallsThemselves(String name) {
    return '自称“$name”';
  }

  @override
  String pairIncomingBody(String name) {
    return '配对后，你与 $name 之间的付款文件和账单都会被密封。接下来你们一起核对词语。';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return '允许 $name 请求付款';
  }

  @override
  String get pairIncomingAllowHint => '核对词语后开启。没有你的 PIN 不会付款。';

  @override
  String get pairNotNow => '暂不';

  @override
  String pairWaitingTitle(String name) {
    return '正在等待 $name 的钱包…';
  }

  @override
  String get pairWaitingBody => '对方的钱包下次打开时会回复。你可以关闭此页面；配对会在后台继续，完成后会出现词语核对。';

  @override
  String get pairSendByHand => '手动发送';

  @override
  String get pairRelayUnreachableTitle => '无法连接中继';

  @override
  String get pairRelayUnreachableBody => '手动发送你的回复？';

  @override
  String get pairRelayUnreachableTor => '无法通过 Tor 连接中继。手动发送你的回复？';

  @override
  String get pairByHandTitle => '手动发送';

  @override
  String pairByHandLead(String name) {
    return '通过任何渠道将此发回给 $name。对方的钱包打开后会完成配对。';
  }

  @override
  String get pairByHandYourAnswer => '你的回复';

  @override
  String pairByHandFooter(String name) {
    return '回复已针对 $name 的邀请密封。其他人无法读取，且只能使用一次。';
  }

  @override
  String pairConfirmByHandLead(String name) {
    return '将此发回给 $name。对方的钱包打开后会显示词语核对。';
  }

  @override
  String get pairExpiredTitle => '此邀请已过期';

  @override
  String pairExpiredBody(String name) {
    return '请向 $name 索取新的邀请。';
  }

  @override
  String get pairUsedTitle => '此邀请已被使用';

  @override
  String get pairUsedBody => '请索取新的邀请。';

  @override
  String pairCancelledTitle(String name) {
    return '$name 已取消此邀请';
  }

  @override
  String get pairCancelledBody => '未保存任何内容。';

  @override
  String pairNoAnswerTitle(String name) {
    return '$name 没有回复';
  }

  @override
  String get pairNoAnswerBody => '邀请可能已被取消。请索取新的邀请，或当面配对。';

  @override
  String get pairChangedTitle => '此邀请在途中被更改';

  @override
  String pairChangedBody(String name) {
    return '未保存任何内容。请重新配对，当面或使用 $name 的新邀请。';
  }

  @override
  String get pairNewerTitle => '更新 Epic Cash 以打开此内容';

  @override
  String get pairNewerInviteBody => '此邀请由更新版本的钱包生成。';

  @override
  String get pairNewerFileBody => '此文件由更新版本的钱包密封。';

  @override
  String get pairCheckForUpdates => '检查更新';

  @override
  String pairSecondReplyTitle(String name) {
    return '还有其他人回应了 $name 的邀请。请查看待处理邀请。';
  }

  @override
  String get pairAnsweredSameInvite => '回应了同一邀请 · 未保存';

  @override
  String get sasTitle => '核对词语';

  @override
  String sasLead(String name) {
    return '$name 的钱包显示相同的四个词。请通过电话或当面比较。';
  }

  @override
  String sasLeadExchange(String name) {
    return '$name 页面显示相同的四个词。比较后在双方确认。';
  }

  @override
  String sasLeadRecheck(String name) {
    return '$name 的钱包在“$name › 核对词语”中显示这些词。请通过电话或当面比较。';
  }

  @override
  String get sasMatch => '一致';

  @override
  String get sasNoMatch => '不一致';

  @override
  String get sasSkip => '暂时跳过';

  @override
  String get sasLater => '稍后';

  @override
  String sasMatchedTitle(String name) {
    return '$name 已验证';
  }

  @override
  String sasMatchedBody(String name) {
    return '从现在起，与 $name 的付款文件和账单都会被密封。';
  }

  @override
  String get sasNoMatchTitle => '词语不一致';

  @override
  String get sasNoMatchBody => '可能有人在途中更改了邀请。不会保留任何内容。请重新配对，当面或使用新的邀请。';

  @override
  String get sasStopPairing => '停止配对';

  @override
  String sasSkippedTitle(String name) {
    return '已与 $name 配对';
  }

  @override
  String sasSkippedBody(String name) {
    return '与 $name 的付款文件已密封。方便时请在 $name 的联系人页面核对词语；在此之前账单会等待。';
  }

  @override
  String get sasCheckNow => '立即核对';

  @override
  String get sasAllowAfterMatch => '确认词语一致后开启。';

  @override
  String sasAllowInvoicesHint(String name) {
    return '$name 的钱包可以请求你付款。没有你的 PIN 不会付款。';
  }

  @override
  String get trustVerified => '已验证';

  @override
  String get trustPaired => '已配对，未验证';

  @override
  String get trustPairedShort => '已配对';

  @override
  String get trustKeysChanged => '密钥已更改';

  @override
  String get trustSealed => '已密封';

  @override
  String trustSealedFor(String name) {
    return '为 $name 密封';
  }

  @override
  String get trustAllowsInvoices => '允许账单';

  @override
  String get contactTitle => '联系人';

  @override
  String get contactAddresses => '地址';

  @override
  String get contactPairing => '配对';

  @override
  String contactWordsChecked(String date) {
    return '词语核对于 $date';
  }

  @override
  String get contactCheckAgain => '再次核对';

  @override
  String get contactCheckWordsAgain => '再次核对词语';

  @override
  String get contactSealPayments => '密封付款';

  @override
  String contactSealInfo(String name) {
    return '与 $name 的付款和账单采用端到端加密。只有对方的钱包能读取。';
  }

  @override
  String contactSealInfoMore(String name) {
    return '关闭后，发给 $name 的付款文件为明文：拿到文件的任何人都能读取。仅当 $name 的钱包无法打开密封文件时才关闭。';
  }

  @override
  String get contactAllowInvoices => '允许账单';

  @override
  String contactAllowInfo(String name) {
    return '$name 的钱包可以向你发送付款请求。每个请求都在“账单”中等待你的批准和 PIN。不会自动付款。';
  }

  @override
  String get contactAllowInfoMore => '只能允许已验证的联系人：核对词语可排除被调换的邀请。';

  @override
  String get contactCheckWordsFirst => '请先核对词语';

  @override
  String get contactPausedUntilChecked => '核对词语前已暂停';

  @override
  String contactDeliveredVia(String relay) {
    return '经 $relay 投递';
  }

  @override
  String contactRelayDownTitle(String name) {
    return '$name 的中继没有响应';
  }

  @override
  String get contactRelayDownBody => '正在重试。请求和付款会等待其响应；不会丢失任何内容。';

  @override
  String get contactPausedEpicboxOff => 'Epicbox 关闭期间已暂停';

  @override
  String get contactPausedEpicboxOffBody => '密封文件仍可使用。';

  @override
  String get contactRemovePairing => '移除配对';

  @override
  String contactRemovePairingTitle(String name) {
    return '移除与 $name 的配对？';
  }

  @override
  String contactRemovePairingBody(String name) {
    return '来自 $name 的密封付款和账单将停止。地址仍保留在你的联系人中。';
  }

  @override
  String get contactKeep => '保留';

  @override
  String get contactRemove => '移除';

  @override
  String contactKeysChangedTitle(String name) {
    return '$name 的密钥已更改';
  }

  @override
  String get contactKeysChangedBody =>
      '这可能表示对方现在使用了另一个钱包，或有其他人在使用这个名字。请再次核对词语。';

  @override
  String get contactKeysChangedStatus => '密封和账单已暂停';

  @override
  String get contactKeysChangedPaused => '密封和账单已暂停';

  @override
  String get contactKeepOldKeys => '保留旧密钥';

  @override
  String get contactUseNewKeys => '使用新密钥';

  @override
  String contactKeysBack(String name) {
    return '$name 的密钥已恢复。';
  }

  @override
  String get contactKeysBackBody => '对你来说没有任何变化。';

  @override
  String contactSealDegradedTitle(String name) {
    return '上一笔给 $name 的付款为明文';
  }

  @override
  String contactSealDegradedBody(String name) {
    return '下一笔会询问密封还是明文。$name 的钱包以密封方式回复后，密封会自动重新开启。';
  }

  @override
  String get addrField => '地址';

  @override
  String addrFieldTyped(String type) {
    return '$type 地址';
  }

  @override
  String get addrAddAnother => '添加另一个地址';

  @override
  String addrOneFree(String type) {
    return '还有一种类型可用：$type。';
  }

  @override
  String addrDuplicateType(String name, String type) {
    return '$name 已有此类地址（$type）。';
  }

  @override
  String get addrKeepOld => '保留旧的';

  @override
  String get addrReplace => '替换';

  @override
  String addrDesktopThird(String type) {
    return '粘贴 $type 地址，或留空';
  }

  @override
  String get addrDesktopRule => '每种类型一个地址。只有某种类型空缺时才显示第三个字段。';

  @override
  String get pendingTitle => '待处理邀请';

  @override
  String pendingRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个邀请等待回复',
    );
    return '$_temp0';
  }

  @override
  String pendingLink(String time) {
    return '链接 · $time 后过期';
  }

  @override
  String pendingWords(String time) {
    return '配对词 · $time 后过期';
  }

  @override
  String get pendingExpired => '已过期';

  @override
  String get pendingInviteAgain => '再次邀请';

  @override
  String pendingWaitingConfirm(String time) {
    return '等待对方确认 · $time';
  }

  @override
  String get pendingPairedCheck => '已配对 · 请核对词语';

  @override
  String get pendingEmpty => '没有等待中的邀请。邀请会显示在这里，直到对方的钱包回复。';

  @override
  String get pendingShareAgain => '再次分享';

  @override
  String get pendingShowWords => '显示配对词';

  @override
  String get pendingCopyLink => '复制链接';

  @override
  String get invSetTitle => '账单';

  @override
  String get invSetLead => '你允许的已配对联系人可以向你发送付款请求。每个请求都在“账单”中等待你的 PIN。';

  @override
  String get invSetPaired => '已配对联系人';

  @override
  String get invSetAllowed => '已允许';

  @override
  String get invSetOff => '关闭';

  @override
  String get invSetPairShop => '与商店或交易所配对';

  @override
  String get invSetEmpty => '还没有已配对的联系人。与商店、交易所或个人配对，核对词语，然后在这里允许其账单。';

  @override
  String get invSetPausedBody => '请求在中继上等待，Epicbox 重新开启后送达。';

  @override
  String invSetSwitchedOff(String name) {
    return '来自 $name 的账单已关闭。';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已拒绝 $count 个未处理的请求。',
    );
    return '$_temp0';
  }

  @override
  String get invSetTimeToPay => '付款期限';

  @override
  String invSetTimeToPayHint(int hours) {
    return '$hours 小时 · 账单可付款的时长';
  }

  @override
  String get invoicesEmptyAction => '已配对联系人';

  @override
  String get reqTitle => '查看请求';

  @override
  String reqRequests(String name) {
    return '$name 请求';
  }

  @override
  String reqSealedSigned(String name) {
    return '为此钱包密封并由 $name 签名';
  }

  @override
  String get reqReference => '参考号';

  @override
  String reqPaidWaiting(String name) {
    return '已付款。等待 $name 发布';
  }

  @override
  String get reqPaidWaitingBody => '你的部分已完成。交易所会完成并发布；此项会自动关闭。';

  @override
  String get reqTlPaid => '已付款';

  @override
  String reqTlDelivered(String name) {
    return '已送达 $name 的中继';
  }

  @override
  String reqTlAnswerDelivered(String name) {
    return '回复已送达 $name 的中继';
  }

  @override
  String reqTlPosted(String name) {
    return '已由 $name 发布';
  }

  @override
  String get reqTlPostedHint => '通常在几分钟内';

  @override
  String get reqTlConfirming => '确认中';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n / $total 次确认';
  }

  @override
  String get reqTlConfirmed => '已确认';

  @override
  String reqTlWaiting(String time) {
    return '已等待 $time';
  }

  @override
  String reqNotPostedTitle(String name) {
    return '$name 尚未发布';
  }

  @override
  String get reqNotPostedBody => '“再次发送”会再次投递同一笔付款。它不会被支付两次。';

  @override
  String get reqSendAgain => '再次发送';

  @override
  String reqUnreachableTitle(String name) {
    return '暂时无法联系 $name';
  }

  @override
  String get reqUnreachableBody => '你的资金是安全的；如果未发布，资金会解锁。投递会持续重试。';

  @override
  String get reqRelayRetrying => '中继无响应 · 重试中';

  @override
  String reqWithdrewTitle(String name) {
    return '$name 撤回了请求';
  }

  @override
  String get reqWithdrewBody => '你的资金已解锁。未付款。';

  @override
  String reqWithdrewUnpaid(String name) {
    return '$name 撤回了此请求';
  }

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name 在 10 分钟内发送了 $count 个 $amount EPIC 的请求。全部付款？',
    );
    return '$_temp0';
  }

  @override
  String reqWithdrawalFrom(String name) {
    return '来自 $name 的提现';
  }

  @override
  String reqReceivedWaiting(String name) {
    return '已收到。等待 $name 发布';
  }

  @override
  String get reqReceivedWaitingBody => '无需操作。交易所会发布；之后会有确认。';

  @override
  String get reqNewTitle => '新请求';

  @override
  String get reqNewLead => '请已配对的联系人付款，或将请求保存为文件发给任何人。';

  @override
  String get reqNewLeadContacts => '请已配对的联系人付款。';

  @override
  String get reqNewTo => '收款对象';

  @override
  String get reqNewToHint => '钱包可支付请求的已配对联系人。其他人：将请求保存为文件。';

  @override
  String get reqNewSaveFile => '保存为文件';

  @override
  String get reqNewSend => '发送请求';

  @override
  String sendViaMailbox(String name) {
    return '通过 $name 的信箱发送';
  }

  @override
  String sendViaMailboxHint(String relay) {
    return '已密封。经 $relay 投递';
  }

  @override
  String sendSealedTitle(String name) {
    return '为 $name 密封';
  }

  @override
  String sendSealedBody(String name) {
    return '只有 $name 的钱包能打开此文件。可用任何方式发送，然后打开对方发回的文件。';
  }

  @override
  String get sendSealOrPlainTitle => '密封此文件？';

  @override
  String sendSealOrPlainBody(String name) {
    return '上一个发给 $name 的文件为明文。现在默认重新为密封。';
  }

  @override
  String get sendSealedOption => '密封';

  @override
  String sendSealedOptionHint(String name) {
    return '只有 $name 的钱包能读取';
  }

  @override
  String get sendPlainOption => '明文';

  @override
  String get sendPlainOptionHint => '拿到文件的任何人都能读取';

  @override
  String sendCantOpenTitle(String name) {
    return '$name 无法打开密封文件？';
  }

  @override
  String get sendCantOpenBody => '“改为明文发送”会以不密封的方式重新发送同一笔付款。仍然只是一笔付款。';

  @override
  String get sendAsPlain => '改为明文发送';

  @override
  String get sendAsPlainTitle => '改为明文发送？';

  @override
  String get sendAsPlainBody =>
      '文件不会被密封：拿到文件的任何人都能看到其中的金额和地址。这是同一笔付款，因此不会被支付两次。';

  @override
  String get sendKeepSealed => '保持密封';

  @override
  String get sendPlain => '明文发送';

  @override
  String sendNotHeardTitle(String name) {
    return '$name 的钱包已 90 天没有消息';
  }

  @override
  String sendNotHeardBody(String name) {
    return '$name 需要 Epic Cash 才能打开此文件。';
  }

  @override
  String get sendPlainShort => '明文发送';

  @override
  String get openSealedOtherTitle => '此内容是为另一个钱包或安装密封的';

  @override
  String get openSealedOtherBody => '无法在此打开。请让发送方重新发送。';

  @override
  String get openArrivedUnsealed => '此内容未密封送达。';

  @override
  String openArrivedUnsealedBody(String name) {
    return '$name 以明文发送了此文件。';
  }

  @override
  String noticePairingReplied(String name) {
    return '$name 回复了你的邀请。请一起核对词语。';
  }

  @override
  String noticePairingConfirmed(String name) {
    return '已与 $name 配对。请一起核对词语。';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name 请求 $amount EPIC。请在“账单”中查看。';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return '已收到来自 $name 的 $amount EPIC。等待发布。';
  }

  @override
  String noticeKeysChanged(String name) {
    return '$name 的密钥已更改。付款前请再次核对词语。';
  }

  @override
  String noticeRelayDown(String name) {
    return '$name 的中继没有响应。正在重试。';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name 撤回了请求。你的资金已解锁。';
  }

  @override
  String get restoreUseContactsTitle => '在此设备上使用你的联系人？';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此备份中有 $count 个配对曾在另一台设备上使用。另一台设备应停止使用它们。',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => '在此使用';

  @override
  String restorePairingsOnOtherDevice(int count) {
    return '$count · 在另一台设备上';
  }

  @override
  String get pairInviteSentBodyAnyone =>
      '对方的钱包打开邀请后即完成配对。你可以离开此页面；邀请会保留在“联系人 › 待处理邀请”中。';

  @override
  String get pairInvalidLink => '这不是配对链接';

  @override
  String get pairInvalidBody => '请检查是否复制了完整链接，或索取新的链接。';

  @override
  String get pairOwnCode => '这是你自己的码';

  @override
  String get pairOwnCodeBody => '请扫描另一部手机上的码。';

  @override
  String get pairUnnamedInvite => '公开邀请';

  @override
  String get pairSeenAsMissing => '请输入对方会看到的名字。';

  @override
  String get pairSeenAsTooLong => '请使用更短的名字。';

  @override
  String get pairSeenAsEdit => '更改对方看到的名字';

  @override
  String get pairCodeLabel => '你的配对码';

  @override
  String get pairWordsLabel => '你的配对词';

  @override
  String get pairWordsEnteredLabel => '已输入的词';

  @override
  String pairWordSlot(int n) {
    return '第 $n 个词，未输入';
  }

  @override
  String get pairSuggestions => '建议';

  @override
  String get pairCopied => '已复制';

  @override
  String get pairPaste => '粘贴';

  @override
  String get pairInPersonDone => '码已扫描';

  @override
  String get pairEpicboxOffNotice => 'Epicbox 关闭期间已暂停。邀请和回复需手动传递。';

  @override
  String get pairWaitingTitleShort => '配对';

  @override
  String get pairClosed => '关闭';

  @override
  String get sasWordsLabel => '四个词';

  @override
  String sasDialogTitle(String name) {
    return '与 $name 核对词语';
  }

  @override
  String get contactMore => '更多';

  @override
  String get contactEdit => '编辑';

  @override
  String get contactDelete => '删除联系人';

  @override
  String contactCopyAddress(String type) {
    return '复制 $type 地址';
  }

  @override
  String contactDeletePaired(String name) {
    return '删除 $name 也会移除配对。来自该联系人的密封付款和账单将停止。';
  }

  @override
  String get contactNoAddresses => '未保存地址。';

  @override
  String addrRemove(String type) {
    return '移除 $type 地址';
  }

  @override
  String get sendVia => '发送方式';

  @override
  String get invSetLeadDesktop => '你允许的已配对联系人可以向此钱包发送付款请求。每个请求都在“账单”中等待钱包密码。';

  @override
  String get invSetRowAllowed => '已验证 · 已允许';

  @override
  String get invSetRowOff => '已验证 · 已关闭';

  @override
  String get invSetRowCheckFirst => '已配对，未验证 · 请先核对词语';

  @override
  String invSetAllowFor(String name) {
    return '允许来自 $name 的账单';
  }

  @override
  String get reqNoPayers => '还没有可支付请求的已配对联系人。请配对并核对词语，或将请求保存为文件。';

  @override
  String get reqPickContact => '选择联系人';

  @override
  String get reqFileSaved => '请求已保存为文件';

  @override
  String reqSent(String name) {
    return '请求已发送给 $name';
  }

  @override
  String get reqFileTitle => '付款请求';

  @override
  String noticeOutboxStuck(String name) {
    return '暂时无法联系 $name。你的资金是安全的。';
  }

  @override
  String noticeTooMany(String name) {
    return '$name 发送的请求过多。多余的已被丢弃。如果持续发生，请关闭其账单。';
  }

  @override
  String get noticeOpen => '打开';

  @override
  String get noticeCheckWords => '核对词语';

  @override
  String get noticeView => '查看';

  @override
  String get restorePairings => '配对';

  @override
  String get pairingDesktopShowCodeLead => '让对方用手机扫描此码，或念出配对词。';

  @override
  String get pairingDesktopInviteLead => '通过你们已在使用的任何渠道发送邀请。对方的钱包打开邀请后即完成配对。';

  @override
  String get pairingInviteOnline => '在线邀请';

  @override
  String pairSaveContactTitle(String name) {
    return '将 $name 保存到联系人？';
  }

  @override
  String get pairSaveNewContact => '保存为新联系人';

  @override
  String get pairAddToAContact => '添加到联系人';

  @override
  String pairSavedAs(String name) {
    return '已保存为 $name。';
  }

  @override
  String pairDurDays(int days, int hours) {
    return '$days 天 $hours 小时';
  }

  @override
  String pairDurHours(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String pairDurMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get pairDurUnderMinute => '不到一分钟';

  @override
  String get pairBack => '返回';

  @override
  String get pairNotInContacts => '不在联系人中';

  @override
  String get pairAddToContacts => '添加到联系人';

  @override
  String get helpPairingSection => '配对';

  @override
  String get helpPairingLede => '配对一次；与该联系人的付款文件和账单都会被密封。';

  @override
  String get helpPairWhatTitle => '什么是配对';

  @override
  String get helpPairWhatShort => '与对方配对一次；之后两个钱包之间的付款文件和账单都会被密封。';

  @override
  String get helpPairWhatP1 =>
      '配对一次性地连接两个钱包：当面互相扫描对方的码，或在线使用邀请链接或五个配对词。每个钱包保存一把只为该联系人生成的密钥；这些都不会与 Epicbox 服务器共享。';

  @override
  String get helpPairWhatP2 =>
      '配对后，发给该联系人的付款文件是**密封**的：只有对方的钱包能打开，途中也无法被更改或伪造。人与人之间通过 Epicbox 的付款照常进行。';

  @override
  String get helpPairWhatStep1 => '打开[[联系人|Contacts]]，选择**配对**。';

  @override
  String get helpPairWhatStep2 => '当面：出示你的码，扫描对方的码。在线：发送邀请，或念出配对词。';

  @override
  String get helpPairWhatStep3 => '一起核对词语，然后选择**一致**。';

  @override
  String get helpPairWhatP3 =>
      '配对需要双方都使用 Epic Cash。未配对的联系人仍会收到普通付款文件和 Epicbox 付款。';

  @override
  String get helpPairWhyTitle => '为什么要核对词语';

  @override
  String get helpPairWhyShort => '这四个词证明配对到达了正确的钱包，而不是中间的某个人。';

  @override
  String get helpPairWhyP1 =>
      '配对后，两个钱包都会显示相同的四个图片和名称。它们来自两个钱包的密钥，因此在途中被更改的配对会在两个屏幕上显示不同的词。';

  @override
  String get helpPairWhyP2 =>
      '通过电话或当面比较，然后点按**一致**。联系人变为**已验证**。**暂时跳过**会保留为**已配对，未验证**：付款文件仍会密封，但在核对词语之前，该联系人不能发送账单。';

  @override
  String get helpPairWhyP3 => '如果词语不同，点按**不一致**。此端会丢弃该配对。请重新配对，当面或使用新的邀请。';

  @override
  String get helpPairWordsTitle => '配对词';

  @override
  String get helpPairWordsShort => '在无法扫描或粘贴时，五个带名称的图片可代替链接。';

  @override
  String get helpPairWordsP1 =>
      '当一个钱包没有相机，或邀请无法以链接发送时，发出邀请的钱包会显示五个配对词。对方在**输入链接或词**中输入它们的名称；输入几个字母后，输入框会补全名称。这些词 10 分钟内有效。';

  @override
  String get helpPairWordsP2 =>
      '这些词只用于找到邀请。拥有它们的人与收到链接的人处境相同，因此之后仍要像平常一样一起核对四个词。';

  @override
  String get helpPairWordsP3 => '配对词需要 Epicbox 服务器。Epicbox 关闭期间，请改为发送邀请链接。';

  @override
  String get helpPairInvTitle => '来自已配对联系人的账单';

  @override
  String get helpPairInvShort => '只有你允许的已验证联系人才能请求你付款。每个请求都会等待你的 PIN。';

  @override
  String get helpPairInvP1 =>
      '与你配对的商店、交易所或个人在你允许后可以发送付款请求：在联系人页面或[[设置 › 账单|Settings › Invoices]]中打开**允许账单**。此开关仅对已验证的联系人有效。';

  @override
  String get helpPairInvP2 =>
      '请求会显示在[[账单 › 支付|Invoices › Pay]]中，附有联系人的名字、金额和参考号。在你用 PIN 批准之前不会付款。请求绝不会向你的钱包加钱。';

  @override
  String get helpPairInvP3 => '关闭开关立即生效：该联系人的新请求会被丢弃，未处理的请求会被拒绝。';

  @override
  String get helpPairInvP4 =>
      '与你配对的交易所通过这种方式处理充值和提现。充值：交易所请求，你批准，交易所发布。提现：交易所发送付款，你的钱包自动回复，交易所发布。';

  @override
  String get helpPairRestoreTitle => '恢复会带来什么';

  @override
  String get helpPairRestoreShort =>
      '有历史备份时，用恢复短语恢复会带回所有配对；没有备份时，重新配对会找到相同的密钥。';

  @override
  String get helpPairRestoreP1 =>
      '有历史备份时，恢复会原样带回所有配对：相同的密钥、相同的“已验证”标记、相同的设置。联系人不会察觉任何变化。';

  @override
  String get helpPairRestoreP2 =>
      '没有备份时，配对会从此钱包中消失，但密钥不会：它们来自恢复短语。与保留了配对的联系人重新配对，对方的钱包会找到相同的密钥。它会告诉对方密钥已恢复，联系人也会保留“已验证”标记。在此钱包上，“密封付款”和“允许账单”恢复为默认设置。';

  @override
  String get helpPairRestoreP3 =>
      '只有当恢复短语不同时，联系人才会看到**密钥已更改**。这可能表示一个新钱包，或有其他人在使用这个名字。信任之前请再次核对词语。';

  @override
  String get helpPairRestoreP4 => '一次只在一台设备上使用配对。在第二台设备上恢复的备份会先询问，再在那里使用联系人。';

  @override
  String get pairNameForCode => '输入对方会看到的名字，你的码就会显示在这里。';

  @override
  String get pairYourNamePlaceholder => '你的名字';

  @override
  String get restoreDone => '历史已恢复。';

  @override
  String restoreDoneBody(int payments, int contacts, int pairings) {
    return '已恢复 $payments 笔付款、$contacts 个联系人和 $pairings 个配对。';
  }
}
