// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'BT Wallet';

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
  String get txRestoredFunds => '在链上找到';

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
  String get txEditFromHelper => '未验证。仅供你记录。';

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
      other: '文件中有 $n 笔付款带有不同的详情。除非你选择文件中的，否则保留你的。',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => '我的';

  @override
  String get histConflictBackup => '文件';

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
  String get txStatusFromBackup => '已导入';

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
    return '在链上找到 $amount';
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
  String get errorHistoryNotOurs => '此文件不是本应用的钱包数据文件。';

  @override
  String get errorHistoryNewer => '此钱包数据文件由更新版本的应用创建。';

  @override
  String get errorHistoryDamaged => '此钱包数据文件已损坏。';

  @override
  String get errorHistoryOtherWallet => '此文件属于另一个钱包。只有用同一助记词恢复的钱包才能打开它。';

  @override
  String get errorHistoryOtherNetwork => '此钱包数据文件来自另一个网络。';

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
  String get scanResuming => '正在继续扫描';

  @override
  String get scanResumedNotice => '应用在后台时扫描已暂停，现在从停下的位置继续。';

  @override
  String get languageSetting => '语言';

  @override
  String get languageSystem => '系统';

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
      other:
          '已等待 $days 天。Epicbox 服务器会在 7 天后删除付款，因此这笔付款已无法完成。请取消它以解锁这些币，然后重新发送。',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      '已通过 Epicbox 发送。对方钱包上线后完成；在此之前或取消之前，金额保持锁定。';

  @override
  String get txDetailsWaitingRecipient => '正在等待接收方的回复文件。在此之前或取消之前，该金额保持锁定。';

  @override
  String get txDetailsWaitingSender => '等待发送方将其广播到网络。';

  @override
  String get txDetailsSenderPosted => '发送方称已广播这笔付款。网络确认后，付款即完成。';

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
      '已取消。没有支付任何资金，这些资金已恢复可用。如果接收方已经收到，其钱包可能仍显示为等待中。';

  @override
  String get txDetailsCancelledReleased =>
      '网络始终未接受这笔付款，因此其资金已释放。再次发送前，请确认接收方没有收到。';

  @override
  String get txDetailsCancelledNotOnChain =>
      '这笔付款未能及时进入网络，已被取消。再次发送前，请确认接收方没有收到。';

  @override
  String get txDetailsCancelledUnanswered =>
      '接收方未在 24 小时内回复，因此钱包已将其取消。没有支付任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledLateAnswer =>
      '接收方在 24 小时期限过后才回复，因此钱包取消了这笔付款，而没有完成它。没有支付任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledUndelivered =>
      '这笔付款无法送达接收方，因此钱包已立即将其取消。没有发送任何资金，这些资金已恢复可用。';

  @override
  String get txDetailsCancelledIncoming => '已取消。如果发送方之后广播这笔付款，它仍会到账。';

  @override
  String get txStatusSenderCancelled => '已被发送方取消';

  @override
  String get txDetailsSenderCancelledWaiting => '发送方已取消这笔付款。钱包检查网络后会在此清除它。';

  @override
  String get txDetailsSenderCancelled => '发送方已取消这笔付款。如果此前已广播，它仍会到账。';

  @override
  String get txDetailsFromBackup =>
      '这笔付款从钱包数据文件导入，导出该文件时尚未完成。此钱包自身没有它的记录，因此无法判断它是否已完成。没有锁定任何资金。';

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
  String get txWaitNoNewBlock => '正在等待下一个区块被挖出。';

  @override
  String get txWaitNotInBlock => '尚未进入区块，可能仍在发往网络的途中。';

  @override
  String get txDetailsStuckBody => '网络未接受这笔付款。请重新广播；同一笔付款不会被执行两次。';

  @override
  String get txDetailsBroadcastAgain => '重新广播';

  @override
  String get txDetailsBroadcastAgainDone => '已重新广播。';

  @override
  String get txDetailsRefusedBody => '这笔付款没有完成。它占用的币可以释放。';

  @override
  String get txDetailsReleaseFunds => '释放资金';

  @override
  String get txDetailsReleaseTitle => '释放资金？';

  @override
  String get txDetailsReleaseBody => '这笔付款没有完成，但之后仍有可能完成。';

  @override
  String get txDetailsReleaseKeepWaiting => '继续等待';

  @override
  String get txDetailsFundsReleased => '资金已释放';

  @override
  String get txDetailsCancelPayment => '取消付款';

  @override
  String get txDetailsCancelTitle => '取消这笔付款？';

  @override
  String get txDetailsCancelReceiveBody => '尚未收到任何款项。如果这笔付款之后到达，会显示为已收到。';

  @override
  String get txDetailsCancelSendBody => '尚未支付任何款项：取消免费且一定成功。';

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
  String get txDetailsNoteLabel => '私人备注';

  @override
  String get txDetailsPrivateNoteLabel => '私人备注';

  @override
  String get txDetailsMessageFromSender => '留言';

  @override
  String get txDetailsMessageFromRecipient => '接收方的留言';

  @override
  String get txDetailsYourMessage => '留言';

  @override
  String get txDetailsMessageHintToRecipient => '已发送给收款人';

  @override
  String get txDetailsMessageHintFromSender => '来自付款人';

  @override
  String get txDetailsMessageHintFromRecipient => '来自收款人';

  @override
  String get txDetailsMessageHintToSender => '已发送给付款人';

  @override
  String get txDetailsNoNote => '暂无备注';

  @override
  String get txDetailsAddNote => '添加备注';

  @override
  String get txDetailsEditNote => '编辑备注';

  @override
  String get txDetailsNoteDialogTitle => '私人备注';

  @override
  String get txDetailsNoteHelper => '仅保存在此应用和导出的钱包数据中。';

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
  String get txDetailsExplorerBehind => '区块浏览器尚未同步到这个区块。';

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
  String get txDetailsSourceRestored => '在链上找到。链上没有发送方和手续费；导入钱包数据即可补上。';

  @override
  String get txDetailsSourceImported => '从钱包数据文件导入。未在链上核对状态。';

  @override
  String get historyTitle => '活动';

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
  String get historyBackupSaveDialogTitle => '保存钱包数据';

  @override
  String get importWarnTitle => '导入之前';

  @override
  String get importWarnEarly => '这是一个新应用的早期版本。';

  @override
  String get importWarnReads => '导入只会读取你的旧钱包和文件，绝不会删除或更改它们。';

  @override
  String get importWarnBackup => '继续之前，请确认每个钱包都有备份：它的助记词，以及你保留的钱包文件。';

  @override
  String get importWarnRisk => '导入的风险由你自行承担，我们对任何损失不负责任。';

  @override
  String get importWarnRiskPlain => '导入风险自负，任何损失概不负责。';

  @override
  String get importWarnAck => '每个钱包我都有备份';

  @override
  String get historyBackupOpenDialogTitle => '打开钱包数据文件';

  @override
  String get historyBackupFileTooLarge => '该文件过大，不可能是钱包数据文件。';

  @override
  String get historyBackupShare => '分享';

  @override
  String get historyBackupShareSubtitle => '手机以外的副本，例如云存储或其他设备。';

  @override
  String get historyBackupSaveToDevice => '保存到设备';

  @override
  String get historyBackupSaveToDeviceSubtitle => '同时把它复制到手机以外。';

  @override
  String historyBackupSaved(String fileName) {
    return '已保存 $fileName';
  }

  @override
  String get historyBackupExportTitle => '导出钱包数据';

  @override
  String get historyBackupCsvTitle => '导出 CSV';

  @override
  String get historyBackupCsvWarning =>
      '未加密：任何拿到文件的人都能看到金额、日期、地址和备注。它无法导入；如需备份，请使用“导出钱包数据”。';

  @override
  String get historyBackupCsvConfirm => '导出 CSV';

  @override
  String get historyBackupImportedTitle => '已导入钱包数据';

  @override
  String historyBackupImportFailed(String reason) {
    return '未能导入钱包数据。$reason';
  }

  @override
  String get historyBackupImportNothingNew => '文件中没有新内容。';

  @override
  String get homeLockTooltip => '锁定钱包';

  @override
  String get shellTitle => 'BT Wallet';

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
  String get homeBackedUpNotice => '助记词已备份';

  @override
  String get homeNoticeView => '查看';

  @override
  String get homeNoticeReceived => '有一笔付款正在途中。';

  @override
  String homeNoticeReceivedFrom(String who) {
    return '来自 $who 的付款正在途中。';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount 正在途中。';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '来自 $who 的 $amount 正在途中。';
  }

  @override
  String get homeNoticeSenderPosted => '发送方称付款已广播。';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return '发送方称 $amount 已广播。';
  }

  @override
  String get homeNoticeFinished => '付款已完成，正在确认。';

  @override
  String homeNoticeFinishedTo(String who) {
    return '发给 $who 的付款已完成，正在确认。';
  }

  @override
  String get homeNoticeDelayed => '无法连接节点。付款等待中。';

  @override
  String get homeNoticeRelayProblem => 'Epicbox 服务器报告了问题，正在重试。';

  @override
  String get homeNoticePaymentFailed => '有一笔付款失败。';

  @override
  String get homeBackupCardText => '助记词未备份';

  @override
  String get homeBackupCardButton => '备份';

  @override
  String get homeBackupCardDismiss => '不再显示';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款不在你导出的钱包数据中。',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '自上次导出钱包数据以来，有 $count 笔付款是新的或有改动。',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => '以后再说';

  @override
  String get homeHistoryExportButton => '导出钱包数据';

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
  String balanceExactTip(String amount) {
    return '精确金额：$amount';
  }

  @override
  String get homeShowBalances => '显示余额';

  @override
  String get homeHideBalances => '隐藏金额';

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
  String get homeBalanceImmature => '挖矿奖励';

  @override
  String get balanceImmatureHelp => '挖矿奖励需等待一定数量的区块后才能使用。';

  @override
  String get balanceLineAllConfirmed => '全部已确认';

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
  String percentValue(String percent) {
    return '$percent%';
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
  String get statusEpicboxBlocked => 'Epicbox 被拦截';

  @override
  String epicboxBlockedBody(String host) {
    return '此网络拦截了 $host。可能是网络过滤所致。请尝试其他 Epicbox 服务器或专用 DNS。';
  }

  @override
  String epicboxSwitchTo(String host) {
    return '切换到 $host';
  }

  @override
  String get netStatusBlocked => '被拦截';

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
  String contactsStaleOpened(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '上次打开是 $days 天前。正在检查已配对的联系人。',
    );
    return '$_temp0';
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
  String get homeNoPayments => '还没有付款';

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
  String get invoicesEmpty => '没有等待中的账单。你允许的已配对联系人请求付款时，账单会显示在这里，在你批准之前不会付款。';

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
  String get invoiceApprove => '批准并付款';

  @override
  String get invoiceDecline => '拒绝';

  @override
  String get invoicePinReason => '输入 PIN 码以支付此账单。';

  @override
  String get invoiceDeclineTitle => '拒绝此账单？';

  @override
  String invoiceDeclineBody(String service) {
    return '$service 会得知你已拒绝。不会支付任何款项。';
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
  String invoiceDetailsConfirmed(String service) {
    return '已付款。网络已确认这笔付给 $service 的付款。';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service 尚未收到你的付款。点“重试”会再次发送，无需再次批准。';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '你付款后，$service 撤回了此账单。';
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
  String get requestMessageHelper => '付款方会随账单看到这条留言。';

  @override
  String get invoicesToPaySection => '待支付';

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
  String get issuedWithdrawTitle => '撤回这个账单？';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer 将无法再支付它。尚未支付任何款项，因此没有币被移动。此操作无法撤销。';
  }

  @override
  String get issuedWithdrawKeep => '保留';

  @override
  String get issuedDetailsSection => '账单';

  @override
  String get issuedDetailsPayer => '请求对象';

  @override
  String get issuedDetailsWaiting => '正在等待付款方。付款到达后，你的钱包会完成它。';

  @override
  String get issuedDetailsPaid => '已支付。你的钱包已完成这笔付款；网络确认后即完成。';

  @override
  String get issuedDetailsDeclined => '付款方拒绝了这个账单，因此已撤回。没有支付任何款项。';

  @override
  String get issuedDetailsWithdrawn => '你撤回了这个账单。没有支付任何款项。';

  @override
  String get issuedDetailsExpired => '这个账单在支付前已过期。没有支付任何款项。';

  @override
  String get issuerNoticePaid => '你发出的一个账单已支付。';

  @override
  String get issuerNoticeDeclined => '你发出的一个账单被拒绝了。';

  @override
  String get issuerNoticeWithdrawn => '账单已撤回，无法再支付。';

  @override
  String get issuerNoticeExpired => '你发出的一个账单未支付就过期了。';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return '$payer 的钱包无法账单，已将你的账单退回，因此已撤回。请让对方改为直接向你的地址付款，或使用交易文件。';
  }

  @override
  String get issuedBounced => '已退回';

  @override
  String get issuedDetailsBounced =>
      '付款方的钱包无法账单，因此没有付款。请让对方把款项付到你的地址，或以交易文件发送。';

  @override
  String get txStatusWaitingPayer => '等待付款方';

  @override
  String get txStepRequested => '已请求';

  @override
  String get txStepPaid => '已支付';

  @override
  String get txDetailsWaitingPayer => '你账单了这笔付款。目前还没有到账：付款方账单后款项才会到达。';

  @override
  String get txDetailsRequestEnded => '这个账单未付款即已结束。没有任何款项到账。';

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
  String receiveEpicboxConnected(String server) {
    return '已连接 · $server';
  }

  @override
  String get receiveQrLabel => '你的地址二维码';

  @override
  String get receiveAddressLabel => 'Epicbox 地址';

  @override
  String get receiveEpicboxOfflineBody => '付款暂存在 Epicbox 服务器上，钱包重新连接后到达。';

  @override
  String get receiveShareCardHeadline => '用 Epic Cash 付款给我';

  @override
  String get receiveHelpButton => '收款说明';

  @override
  String get receiveAddressCopied => '地址已复制';

  @override
  String get receiveFileTitle => '通过交易文件收款';

  @override
  String get receiveFileBody => '打开交易文件，或把其中的文本粘贴到这里。';

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
  String get updateAllowInstalls => '允许来自 BT Wallet 的安装，然后返回。';

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
  String get updateManifestOtherApp => '更新信息属于其他应用。';

  @override
  String updateDownloadHttpFailed(int status) {
    return '下载失败（HTTP $status）。';
  }

  @override
  String get updateDownloadTooLarge => '下载内容超过了声明的大小。';

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
  String get setupWalletPerNetwork => '每个网络都有各自的钱包。尚无钱包的网络会创建一个新钱包。';

  @override
  String get restoreTitle => '恢复钱包';

  @override
  String get restorePhraseLabel => '助记词';

  @override
  String get restorePhraseHelper => '全部单词（12、15、18、21 或 24 个），以空格分隔。';

  @override
  String get restoreStartByMonth => '月份';

  @override
  String get restoreStartByHeight => '区块高度';

  @override
  String get restoreStartHeightLabel => '起始高度（可选）';

  @override
  String get restoreStartHeightHelper => '从此区块开始扫描。留空则扫描整条链。';

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
  String get restoreDateHint => '可选。不确定时请选更早的日期：更晚的日期可能漏掉资金。';

  @override
  String restoreDateStart(String height) {
    return '扫描将从此日期前两天开始，起始区块为 $height。';
  }

  @override
  String get restorePickMonth => '选择你创建钱包的月份';

  @override
  String get restorePickMonthShort => '选择月份';

  @override
  String restoreMonthStart(String height) {
    return '扫描将从区块 $height 开始。';
  }

  @override
  String get restoreMonthRecent => '月份很近：此前收到的资金可能被漏掉。';

  @override
  String get restoreMonthEarlierYear => '上一年';

  @override
  String get restoreMonthLaterYear => '下一年';

  @override
  String get restoreScanIntro => '正在区块链上查找你的资金。完成前请保持应用打开。';

  @override
  String get restoreOpenWallet => '打开钱包';

  @override
  String get restoreUnfinishedTitle => '恢复尚未完成';

  @override
  String get restoreUnfinishedRunning => '正在查找此钱包的资金。完成后即可接收和发送。';

  @override
  String get restoreUnfinishedOffline => '关闭离线后扫描会继续。';

  @override
  String get restoreUnfinishedFailed => '扫描已中断，将自动重试。扫描完成前无法接收和发送。';

  @override
  String get errorRestoreScanRequired => '恢复尚未完成。主页上显示的扫描结束后即可接收和发送。';

  @override
  String get restoreScanStop => '停止';

  @override
  String get restoreScanScreenOn => '扫描期间屏幕保持常亮。';

  @override
  String get restoreScanStopped => '已停止。要等此扫描完成后才能接收和发送；扫描会在主页继续。';

  @override
  String get restoreScanUnfinished =>
      '扫描在结束前中断。要等它完成后才能接收和发送：可在此重试，或打开钱包，扫描会在主页继续。';

  @override
  String get restoreFinishOnHome =>
      '已找到所选起点之后的币。现在从区块 0 开始的扫描会在主页完成恢复，结束后即可接收和发送。';

  @override
  String get unlockDatabaseRebuilt =>
      '钱包数据库已损坏，并已根据助记词重建。扫描会找回资金；付款详情、备注和标签只能从钱包数据文件中找回。';

  @override
  String get restoreRebuiltImportText => '钱包数据文件可找回交易记录、联系人、账单和设置。';

  @override
  String get restoreReplaceLead =>
      '此助记词恢复的钱包将取代这部手机上的钱包。在助记词核对无误并确认替换之前，不会有任何更改。';

  @override
  String get restoreReplacePinReason => '输入 PIN 码以替换此钱包。恢复后的钱包沿用此 PIN 码。';

  @override
  String restorePhraseUnknownWord(int position, String word) {
    return '第 $position 个单词“$word”不在词表中。';
  }

  @override
  String restorePhraseUnknownWords(String words) {
    return '不在词表中：$words。';
  }

  @override
  String restorePhraseWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此助记词有 $count 个单词。助记词应为 12、15、18、21 或 24 个单词。',
    );
    return '$_temp0';
  }

  @override
  String get restorePhraseChecksum => '每个单词都在词表中，但助记词校验不通过。有单词错误或顺序不对。';

  @override
  String deleteFailedNotice(String error) {
    return '钱包未删除。$error请解锁后在“设置”中重试。';
  }

  @override
  String get restoreDoneIconLabel => '完成';

  @override
  String get restoreDoneTitle => '钱包已恢复';

  @override
  String get restoreImportExplanation =>
      '助记词已找回余额。要找回记录、联系人、账单和设置，请导入你导出的钱包数据文件。';

  @override
  String get restoreImportButton => '导入钱包数据';

  @override
  String get restoreImportNotNow => '以后再说';

  @override
  String get restoreImportLater => '你之后可以在“设置”中导入。';

  @override
  String get restoreScanProgressLabel => '扫描进度';

  @override
  String get firstRunTitle => '欢迎';

  @override
  String get firstRunCreate => '创建新钱包';

  @override
  String get firstRunRestore => '用助记词恢复';

  @override
  String get settingsRestoreReplaces => '此钱包将被删除，由所输入助记词对应的钱包取代，PIN 码保持不变。';

  @override
  String get firstRunSecuring => '正在保护你的钱包…';

  @override
  String get workStoppingRecheck => '正在停止核对…';

  @override
  String get workTellingDevices => '正在通知关联设备…';

  @override
  String get workRemovingFiles => '正在删除钱包文件…';

  @override
  String get workClearingKeys => '正在清除密钥…';

  @override
  String get workChecking => '正在检查…';

  @override
  String get workOpening => '正在打开钱包…';

  @override
  String get workCreating => '正在创建钱包…';

  @override
  String get workRestoring => '正在恢复钱包…';

  @override
  String get workStarting => '正在启动…';

  @override
  String get firstRunTryAgain => '重试';

  @override
  String get firstRunBiometricsNotSetUp => '未能设置生物识别解锁。你可以在“设置”中开启。';

  @override
  String get backupTitle => '助记词';

  @override
  String get backupPinReason => '请输入 PIN 码以显示助记词。';

  @override
  String get backupCopyWarning => '任何看到这些词或其照片的人都能转走资金。';

  @override
  String get backupConsentTitle => '查看助记词之前';

  @override
  String get backupConsentWhat => '下一屏会显示用于恢复此钱包的词语。';

  @override
  String get backupConsentReady => '请准备好纸和笔。';

  @override
  String get backupCopyAgree => '我会妥善保管助记词，不泄露给他人';

  @override
  String get backupShowPhrase => '显示助记词';

  @override
  String get backupWarningIconLabel => '警告';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请将这 $count 个单词按顺序抄写在纸上。它们是恢复此钱包的唯一方式。',
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
  String get pinBiometricsQuestion => '使用生物识别解锁？';

  @override
  String get pinBiometricsPinStillWorks => 'PIN 码仍然可用。';

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
  String get scanQrTooltip => '扫描二维码';

  @override
  String get sendScanButton => '扫码';

  @override
  String get sendChooseContactTooltip => '选择联系人';

  @override
  String get sendContactsButton => '联系人';

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
  String get slateNotTransactionFile => '该文件不是交易文件。';

  @override
  String get slateReading => '正在读取文件';

  @override
  String get slateReadingQr => '正在读取付款';

  @override
  String get slateFileTooLarge => '该文件过大，不可能是交易文件。';

  @override
  String slatePostedHeadline(String amount) {
    return '$amount 的付款已广播到网络。';
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
  String get scanPhraseFoundQr => '此二维码包含助记词。请妥善保密。';

  @override
  String get scanPhraseFoundPasted => '这是助记词，因此未粘贴。请妥善保密。';

  @override
  String get scanQrPhraseHint => '将摄像头对准助记词二维码。';

  @override
  String get restoreScanNoPhrase => '此二维码不含助记词。';

  @override
  String get scanQrCameraDenied => '摄像头权限已关闭。请在手机设置中允许，或直接粘贴地址。';

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
  String get qrScanGot => '已读取二维码';

  @override
  String qrScanCount(int got, int count) {
    return '$got / $count';
  }

  @override
  String get qrScanCountLabel => '已读取的段数';

  @override
  String get qrScanNotPayment => '这不是付款二维码。请让对方显示付款二维码。';

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
  String get qrScanCameraDenied => '摄像头权限已关闭。请在手机设置中允许，或改为打开文件。';

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
  String get methodArtCaptionQr => '当面';

  @override
  String get methodSendQrTitle => '给你身边的手机。';

  @override
  String get methodSendQrLine => '在这块屏幕上显示二维码，再用摄像头扫描对方的回复。';

  @override
  String get methodReceiveQrTitle => '扫描对方的屏幕。';

  @override
  String get methodReceiveQrLine => '接受付款，再用同样的方式显示你的回复。';

  @override
  String get receiveQrTitle => '就在对方手机旁边？';

  @override
  String get receiveQrBody => '或者请求一个金额：显示二维码让对方扫描。';

  @override
  String get txQrHint =>
      '二维码付款会把付款显示成动态码，由另一部手机用摄像头扫描，回复也用同样方式接收。它只适用于并排的两部手机，两个钱包之间无需连接，二维码会在 40 秒后自动隐藏。会在发送和接收中加入二维码付款。';

  @override
  String get advTransactionFiles => '直接 · 文件传输';

  @override
  String get advTransactionFilesHint => '在设置 › 交易中加入“文件传输”：用你自己传递的文件付款或收款。';

  @override
  String get sendMakeQr => '生成付款二维码';

  @override
  String sendQrPinReason(String amount) {
    return '输入 PIN，以生成 $amount 的付款二维码。';
  }

  @override
  String get sendQrHint => '把二维码给接收方的手机看，然后扫描对方的回复。';

  @override
  String get sendCancelRuleQr => '在你扫描对方回复之前都可以取消。';

  @override
  String get qrStatusSendHidden => '把它给接收方看。';

  @override
  String get qrStatusSendShowing => '等待接收方扫描。然后扫描对方的回复。';

  @override
  String get qrStatusHiddenAgain => '已隐藏';

  @override
  String get qrStatusReplyHidden => '已隐藏';

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
      '地址无效。请使用 Epicbox 地址（es5x…@服务器）、链接地址（https://…）或 onion 地址（….onion）。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionDisplay => '外观';

  @override
  String get settingsCurrency => '计价货币';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name（$code）';
  }

  @override
  String get settingsShowPrices => '显示价格';

  @override
  String get settingsHideBalances => '隐藏金额';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPricesOnNotice =>
      '价格来自 BT Labs 在 status.btlabs.uk 上保存的 CoinGecko 价格副本，该站点能看到你的 IP 地址。Tor 关闭时，若该副本没有价格，则会询问 CoinGecko，此时 CoinGecko 能看到你的 IP 地址。';

  @override
  String get settingsSectionSecurity => '安全';

  @override
  String get settingsChangePin => '修改 PIN 码';

  @override
  String get settingsBiometrics => '生物识别解锁';

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
  String get settingsSectionHistory => '钱包数据';

  @override
  String get settingsExportHistory => '导出钱包数据';

  @override
  String get settingsExportCsv => '导出 CSV';

  @override
  String get settingsImportHistory => '导入钱包数据';

  @override
  String get settingsSectionWallet => '此钱包';

  @override
  String get settingsContacts => '联系人';

  @override
  String get settingsInvoices => '账单';

  @override
  String get settingsInvoicesSubtitle => '谁可以请求你付款';

  @override
  String get settingsRescan => '重新核对余额';

  @override
  String get settingsRescanFinished => '余额已重新核对';

  @override
  String get settingsRescanTitle => '重新核对余额';

  @override
  String get settingsRescanBody => '重新核对链上属于此钱包的资金。';

  @override
  String get settingsRescanButton => '重新核对';

  @override
  String get settingsDeleteWallet => '删除钱包';

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
      '这将从此手机中删除钱包、交易记录和 PIN 码。只有助记词能找回资金。没有助记词，资金将永久丢失。';

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
  String settingsUpdatesFrom(String store) {
    return '更新由 $store 提供。';
  }

  @override
  String get settingsHelp => '帮助';

  @override
  String get settingsSendFeedback => '报告问题';

  @override
  String get settingsSendFeedbackHint =>
      '向开发者报告问题或提出建议。只有你选择附上时才会发送日志，且会先移除助记词、PIN 码和其他机密信息。';

  @override
  String get settingsSourceCode => '源代码';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsLicences => '许可证';

  @override
  String get licencesLead => '本钱包包含的开源软件，各自适用其许可证。';

  @override
  String get licencesApp => 'BT Wallet，BT Labs 出品：Apache-2.0。';

  @override
  String get licencesFlutter => 'Flutter 及其 Dart 软件包：BSD 3-Clause 及类似的宽松许可证。';

  @override
  String get licencesLepic =>
      'LEPIC，Epic Cash 钱包库：Apache-2.0，包含 Epic Cash 的 secp256k1-zkp 分支（CC0）以及 MIT 或 Apache-2.0 许可的 Rust crate，其中有 tokio、rustls、rusqlite 和 blake2。';

  @override
  String get licencesTor => 'Tor：GNU 通用公共许可证第 3 版。其源代码见下文。';

  @override
  String get licencesFonts =>
      '字体 Montserrat、JetBrains Mono、Geist、Geist Mono 和 Noto Sans Thai：SIL 开放字体许可证 1.1。';

  @override
  String get licencesFull => '全部许可证文本';

  @override
  String licencesPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个许可证',
    );
    return '$_temp0';
  }

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
  String get settingsPinNewLabel => '新 PIN 码';

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
  String get helpSendFeedback => '报告问题';

  @override
  String get feedbackTitle => '报告问题';

  @override
  String get feedbackIntro => '描述哪里出了问题，或哪些地方可以改进。';

  @override
  String get feedbackMessageLabel => '发生了什么';

  @override
  String get feedbackMessageMissing => '请简单描述发生了什么。';

  @override
  String get feedbackAttachLogs => '附加日志';

  @override
  String get feedbackAttachLogsHint => '应用日志的最新部分，不含助记词、PIN 码和其他机密信息。';

  @override
  String get feedbackPreviewButton => '发送的内容';

  @override
  String get feedbackSend => '发送';

  @override
  String get feedbackShareOrSaveInstead => '分享或保存';

  @override
  String get feedbackFileExplanation => '你的反馈将生成一个文本文件，你可以分享或保存。';

  @override
  String get feedbackShareOrSave => '分享或保存';

  @override
  String get feedbackShareHint => '把文件交给其他应用';

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
  String get settingsSectionPrivacy => '隐私';

  @override
  String get settingsSectionPrivacyNetwork => '隐私与网络';

  @override
  String get settingsSectionNetworkPrivacy => '网络与隐私';

  @override
  String get netSummaryTorOn => 'Tor 已开启';

  @override
  String get netSummaryTorOff => 'Tor 已关闭';

  @override
  String get netPageServers => '服务器';

  @override
  String get settingsSectionHelpFeedback => '帮助';

  @override
  String get settingsExperimentTag => '实验';

  @override
  String get settingsStateBackUp => '备份助记词';

  @override
  String get settingsStateNotBackedUp => '尚未备份';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String settingsUseStatusSite(String site) {
    return '使用 $site';
  }

  @override
  String get settingsUseStatusSiteSubtitle =>
      '显示哪些节点和 Epicbox 服务器在线，数据来自 status.btlabs.uk 上的公开列表。';

  @override
  String get txStepStarted => '付款已发起';

  @override
  String get txStepAccepted => '接收方已签名';

  @override
  String get txStepPosted => '已广播到网络';

  @override
  String get txStepConfirming => '确认中';

  @override
  String get txStepConfirmed => '已确认';

  @override
  String get txStepArrived => '付款已到达';

  @override
  String get txStepSenderFinished => '已签名并发回';

  @override
  String get fileHelpTitle => '交易文件如何使用';

  @override
  String get fileHelpYou => '你';

  @override
  String get fileHelpFriend => '朋友';

  @override
  String get fileHelpSendStep1 => '你创建一个交易文件。';

  @override
  String get fileHelpSendStep2 => '你用任何方式把它交给朋友，比如聊天应用或 U 盘。';

  @override
  String get fileHelpSendStep3 => '朋友在自己的钱包中打开它，并把回复文件发还给你。';

  @override
  String get fileHelpSendStep4 => '你打开回复文件，付款就在路上了。';

  @override
  String get fileHelpReceiveStep1 => '朋友为你创建一个交易文件。';

  @override
  String get fileHelpReceiveStep2 => '对方用任何方式把它交给你，比如聊天应用或 U 盘。';

  @override
  String get fileHelpReceiveStep3 => '你在钱包中打开它，并发回回复文件。';

  @override
  String get fileHelpReceiveStep4 => '朋友打开回复文件，付款就在发给你的路上了。';

  @override
  String fileHelpStepOf(int step, int count) {
    return '第 $step 步，共 $count 步';
  }

  @override
  String get fileHelpPause => '暂停动画';

  @override
  String get fileHelpPlay => '播放动画';

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
  String get sendAddressMissing => '请输入对方的地址。';

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
  String get sendAddNote => '添加留言';

  @override
  String get sendNoteLabel => '留言';

  @override
  String get sendNoteHelper => '收款人能看到。';

  @override
  String get sendReviewMessageKept => '收款人能看到。副本会作为你的私人备注保存。';

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
    return '对方的 Epicbox 服务器（$relay）没有响应。';
  }

  @override
  String get sendListenerDown => '尚未连接。仍可发送。';

  @override
  String get sendPayWithFile => '改用文件付款';

  @override
  String get sendAnyway => '仍然发送';

  @override
  String sendTrackWaitingFor(String name) {
    return '等待 $name 的钱包';
  }

  @override
  String get sendTrackWaiting => '等待对方的钱包';

  @override
  String sendTrackOffline(String amount) {
    return '对方钱包打开后会签名。在此之前 $amount 保持锁定。';
  }

  @override
  String get sendTrackIfNot => '如果一直没有完成怎么办？';

  @override
  String get sendTrackCancelled => '这笔付款已取消。';

  @override
  String get sendNoCoins => '还没有可发送的币。';

  @override
  String get sendFileTitle => '直接 · 文件传输';

  @override
  String get sendMakeFile => '生成交易文件';

  @override
  String sendFileOnHold(String amount) {
    return '$amount 已锁定';
  }

  @override
  String get sendFileWaitingReply => '等待回复文件';

  @override
  String get sendFileShareHint => '把这个文件发给对方，然后打开对方的回复文件。';

  @override
  String get sendOpenReply => '打开回复文件';

  @override
  String get handshakeRequest => '账单';

  @override
  String get handshakeYou => '你';

  @override
  String get handshakeThem => '对方';

  @override
  String get handshakeNetwork => '网络';

  @override
  String get handshakePay1 => '你的钱包把付款发到 Epicbox 服务器。这些币被锁定。';

  @override
  String get handshakePay2 => '服务器把它转给对方。对方钱包加入自己的部分并签名。';

  @override
  String get handshakeFinish => '你的钱包完成它并发送到网络。';

  @override
  String get handshakeConfirm => '网络确认它。';

  @override
  String get handshakeReq1 => '你的钱包把账单发到 Epicbox 服务器。';

  @override
  String get handshakeReq2 => '服务器把它转给对方。对方批准后，其钱包加入币并签名。';

  @override
  String get handshakeRelay => 'Epicbox 服务器';

  @override
  String get handshakeFile => '文件传输';

  @override
  String get handshakeBack => '对方钱包把它发回 Epicbox 服务器。';

  @override
  String get handshakeRelayBack => '服务器把它转回你的钱包。';

  @override
  String get handshakeFile1 => '你的钱包保存一个交易文件。你自己把它发给对方。';

  @override
  String get handshakeFile2 => '对方打开它。对方钱包加入自己的部分、签名并保存回复文件。';

  @override
  String get handshakeFile3 => '对方把回复文件发回给你。';

  @override
  String get handshakeFile4 => '你在钱包中打开对方的回复文件。';

  @override
  String get handshakePrevious => '上一步';

  @override
  String get handshakeLink1 => '你的钱包通过互联网或 Tor 把付款直接发到对方的钱包。这些币被锁定。';

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
      other: '对方的 Epicbox 服务器（$relay）拒绝了这笔付款。在你取消之前，这笔金额保持锁定，最长 $days 天。',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return '对方的 Epicbox 服务器（$relay）拒绝了这笔付款。再次发送前请先查看钱包。';
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
    return '$amount 已锁定';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount 即将到账';
  }

  @override
  String get receiveTorAddressLabel => '链接 · Tor 地址';

  @override
  String get receiveTorQrLabel => '你的 Tor 地址二维码';

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
  String get torFailureNetwork => 'Tor 无法连接。请重试，或关闭 Tor。';

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
  String get sendTorReady => '可以通过 Tor 发送';

  @override
  String get sendTorReaching => '正在通过 Tor 联系对方钱包… 请保持应用打开。';

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
  String get sendTorTryEpicbox => '即使对方钱包离线，Epicbox 也能送达付款。';

  @override
  String sendTorNothingSent(String reason) {
    return '$reason未发送任何内容。';
  }

  @override
  String get sendTryAgain => '重试';

  @override
  String get sendCancelPayment => '取消付款';

  @override
  String get homeAvailableToSpend => '可用余额';

  @override
  String get homeTileWaitingSender => '等待付款方';

  @override
  String get homeTileLocked => '发送中锁定';

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
  String get tourPhoneSkip => '跳过导览';

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
      '粘贴或扫描地址，或选择联系人。Epicbox 向地址付款；二维码把码显示给身边的手机。更多方式：设置 › 交易。发出前会先确认。';

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
  String get tourPhoneInvoicesTitle => '账单';

  @override
  String get tourPhoneInvoicesText => '支付别人发来的账单，或向别人请求付款。用标签页在两者之间切换。';

  @override
  String get tourPhoneDevicesText => '在第二台设备上使用此钱包：每台设备显示另一台的付款。实验功能。';

  @override
  String get tourPhonePrivacyTitle => '隐私与网络';

  @override
  String get tourPhonePrivacyText =>
      '钱包使用哪个节点和 Epicbox 服务器，以及 Tor 开关。点一个服务器即可更改。';

  @override
  String get tourPhoneNetworkText => '网络模式、Tor 开关，以及钱包使用的服务器。点一个服务器即可更改。';

  @override
  String get tourPhoneNetworkTextNoTor => '网络模式，以及钱包使用的服务器。点一个服务器即可更改。';

  @override
  String get tourPhoneAdvancedTitle => '高级';

  @override
  String get tourPhoneAdvancedText => '仅 Tor 模式、输出和技术详情都在这里。需要什么就开启什么。';

  @override
  String get tourAdvancedShowsText => '输出和技术详情都在这里。需要什么就开启什么。';

  @override
  String get tourPhoneHelpTitle => '帮助';

  @override
  String get tourPhoneHelpText => '帮助主题、“报告问题”和“再次查看导览”。';

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
    return '输入 PIN 码以生成 $amount 的交易文件。';
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
  String outputsWaitLocked(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks 次确认',
    );
    return '请等待进行中的付款获得 $_temp0。';
  }

  @override
  String get outputsStrategy => '发送策略';

  @override
  String get outputsStrategyHint =>
      '一笔发送花掉哪些输出。“最小”花掉能覆盖该金额的最小输出；“全部”花掉每个输出并返回一个。';

  @override
  String get outputsSmallest => '最小';

  @override
  String get outputsAll => '全部';

  @override
  String get outputsSmallestText => '花掉能覆盖该金额的最小输出；其余仍可使用。';

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
  String get outputsWordFinalizing => '等待回应';

  @override
  String get outputsWordImmature => '成熟中';

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
  String get outputsEmptyHint => '收到第一笔付款后会产生一个。';

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
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks 个区块',
    );
    return '花掉 $spent（$amount），生成 $made，每个约 $each。这是发往本钱包的普通网络交易，与任何发送一样在 $_temp0后确认；在此之前所有可用余额都被锁定。输出多了，接下来的几笔发送就不必互相等待找零。';
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
  String outputsFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks 个区块',
    );
    return '$amount，约 $_temp0';
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
  String outputsConsolidateText(
    String amount,
    String result,
    String spent,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks 个确认',
    );
    return '花掉 $spent（$amount），生成一个 $result 的输出。所有可用余额会锁定 $_temp0。';
  }

  @override
  String get outputsConsolidateAction => '合并';

  @override
  String get outputsSplitPin => '输入 PIN 码以确认拆分输出';

  @override
  String get outputsConsolidatePin => '输入 PIN 码以确认合并输出';

  @override
  String outputsSplitStarted(int count, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks 个区块',
    );
    return '拆分已开始：$count 个输出，约 $_temp0后确认';
  }

  @override
  String outputsConsolidateStarted(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks 个区块',
    );
    return '合并已开始：一个输出，约 $_temp0后确认';
  }

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
  String get contactTakesNoPayments => '不接受付款';

  @override
  String get contactNoPayments => '不收款';

  @override
  String contactNoPaymentsNamed(String name) {
    return '$name 不接受付款。';
  }

  @override
  String get linkNoPaymentsTitle => '不接受付款';

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
  String get invoicesNewRequest => '新建账单';

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
  String get invoicesSentEmpty => '没有已发送的账单';

  @override
  String get invoicesSentEmptyCaption => '账单是请某人向你支付一笔金额。';

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
  String get invoicesNodeOk => '已同步';

  @override
  String get invoicesNodeDown => '无响应';

  @override
  String get invoicesEpicboxOk => '已连接';

  @override
  String get invoicesEpicboxDown => '未连接';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '将账单 $payer 支付 $amount。账单在 24 小时后到期。';
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
  String get netStatusOff => '关闭';

  @override
  String get netStatusConnected => '已连接';

  @override
  String get netStatusNotConnected => '未连接';

  @override
  String get stateReceiving => '接收中';

  @override
  String get stateUnchecked => '未检查';

  @override
  String get serverUpNotConnected => '服务器正常 · 未连接';

  @override
  String get netStatusOn => '开启';

  @override
  String get netStatusTitle => '网络状态';

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
  String serverTestFailed(String error) {
    return '无应答。$error';
  }

  @override
  String serverHealthUnknown(String site) {
    return '无法访问 $site；状态未知';
  }

  @override
  String get serverAtTip => '已同步';

  @override
  String serverBehindShort(String count) {
    return '落后 $count';
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
  String get serverLocalNotReachable => '无法从这台电脑访问';

  @override
  String get serverLocalNotReachablePhone => '无法从这部手机访问';

  @override
  String get serverHealthy => '正常';

  @override
  String get serverDegraded => '落后';

  @override
  String get serverHealthNone => '状态未知';

  @override
  String get serverCurrent => '使用中';

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
  String get serverAdd => '添加';

  @override
  String get serverAlreadyInUse => '已在使用。';

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
    return '$height · 已同步';
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
  String serverCheckedAt(String time, String site) {
    return '$site，检查于 $time';
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
  String get methodArtCaptionFile => '发出文件，收回回复';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox：付款发送到 Epicbox 服务器，服务器暂存它，直到对方钱包上线';

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
  String get methodSendFileTitle => '无需连接。';

  @override
  String get methodSendFileLine => '交出文件，收回对方的回复文件，然后在这里打开。';

  @override
  String get methodReceiveEpicboxTitle => '分享它即可收款。';

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
  String get sendSwitchedEpicbox => '经由 Epicbox';

  @override
  String get sendSwitchedEpicboxAnnounce => 'Epicbox 地址。方式已设为 Epicbox。';

  @override
  String get sendCancelRuleEpicbox => '在等待对方期间可以取消。';

  @override
  String get sendCancelRuleDirect => '对方钱包接受后无法取消。';

  @override
  String get sendCancelRuleFile => '在你打开回复文件之前可以取消。';

  @override
  String get sendHttpReaching => '正在联系对方钱包… 请保持应用打开。';

  @override
  String get sendDeliveredWaitingBlock => '已送达 · 等待区块';

  @override
  String get sendPlainHttpOffWithTor => '开启 Tor 时，明文 http:// 无法使用。';

  @override
  String get sendPlainHttpOffWithTorWhy => '请使用 https:// 或 onion 地址，或 Epicbox。';

  @override
  String get receiveTorCaption => '有些钱包显示的地址不带 .onion；两者是同一个地址。';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '未能联系到对方钱包。在你取消之前，这笔金额保持锁定，最长 $days 天。',
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
  String get deskInvCheckFailedBody => '列表显示之前收到的内容；钱包会自动重试。';

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
  String get deskInvPayNotDelivered => '未送达';

  @override
  String get deskInvPayDelivered => '等待广播';

  @override
  String deskInvPayPosted(String name) {
    return '已由 $name 发布';
  }

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
    return '$used / $max 字节';
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
    return '$payer 将无法再支付它。尚未支付任何款项，因此没有币被移动。';
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
    return '$payer 的钱包无法支付账单；请让 $payer 直接付款。';
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
    return '已通过 Epicbox 送达。在 $payer 批准之前不会付款。';
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
      '收到了一笔本设备未开具的账单的付款。它会在服务器上为您使用此钱包的另一台设备保留一天：请在那台设备上打开钱包完成它。';

  @override
  String get deskInvNoticeUnknownAnswer =>
      '收到了对一笔本设备未发送的付款的回复。它会在服务器上为您使用此钱包的另一台设备保留一天：请在那台设备上打开钱包完成它。';

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
  String get deskInvPayerEmptyText => '已允许的配对联系人发来的账单会显示在这里；未经批准不会付款。';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return '你给 $service 的付款未送达';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      '付款已签名并保存在这台电脑上；EPIC 保持锁定。重试会再次发送，无需再次批准。';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service 撤回了一张你已支付的账单';
  }

  @override
  String get deskInvPayerWithdrawnText => '这笔付款可能永远不会上链。取消它以释放这些币。';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return '你给 $service 的付款不在链上';
  }

  @override
  String get deskInvPayerPastTtlText => '其期限已过，网络未见到它。取消它以释放这些币。';

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
  String deskInvPayerShortText(
    String total,
    String spendable,
    int confirmations,
  ) {
    return '你需要 $total EPIC 可用资金；你有 $spendable EPIC。确认中的资金在 $confirmations 个确认后计入。';
  }

  @override
  String get deskInvPayerNodeDownTitle => '节点无响应';

  @override
  String get deskInvPayerNodeDownText =>
      '钱包无法检查你的资金，因此无法付款。节点恢复响应后即可再次批准；你可以在“设置 › 节点”中选择其他节点。';

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
      'Epicbox 服务器无响应。请在“账单 › 支付”中重试；无需再次批准。';

  @override
  String get deskInvPayerRetryFailed => '仍未送达';

  @override
  String get deskInvPayerRetryFailedText => 'Epicbox 服务器无响应。付款仍以签名状态保存在此设备上。';

  @override
  String get deskInvPayerCancelTitle => '取消此付款？';

  @override
  String get deskInvPayerCancelText => '对方仍可以完成这笔付款。';

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
  String get deskInvPayerSpentText => '币正在移回这个钱包。';

  @override
  String get deskInvPayerSpendFailedText => '币暂时无法移回。钱包会在打开期间重试；在此之前这笔付款仍可能完成。';

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
  String get deskInvSetReceiveHint => '请已配对的联系人付款，或将账单保存为文件。';

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
  String get sendAvailableWhileConfirms => '确认期间可用';

  @override
  String get sendSpendableUntilChangeHint => '找零在发送确认后返回。';

  @override
  String serverSwitched(String host) {
    return '已切换到 $host';
  }

  @override
  String get methodDirect => '链接';

  @override
  String methodDirectShape(String port) {
    return 'http://host:$port 或 xxxx….onion';
  }

  @override
  String get methodSendDirectLine => '对方钱包必须处于打开状态。onion 地址经由 Tor。';

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
  String get methodReceiveEpicboxShort => '分享地址即可收款。';

  @override
  String get methodReceiveEpicboxMore => 'Epicbox 服务器会保留付款，直到此钱包打开。';

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
  String get torNotOverTor => '不使用 Tor';

  @override
  String get torNeeds => 'Link · Tor 需要 Tor。';

  @override
  String get torTurnOn => '开启 Tor';

  @override
  String get torTurnOff => '关闭 Tor';

  @override
  String get torTurnOffCaption => '适用于所有连接，不只是这笔付款。';

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
      '网络活动经由 Tor 网络。要通过 Tor 地址收款，请在“设置 › 交易”中开启 链接 · Tor。';

  @override
  String get receiveTabDirect => '链接';

  @override
  String get receiveDirectNeedsTor => '链接 · Tor 需要 Tor。';

  @override
  String get receiveDirectMeanwhile => '在此期间，请分享 Epicbox 地址。';

  @override
  String get receiveHttpShowQr => '显示二维码';

  @override
  String get receiveHttpHideQr => '隐藏二维码';

  @override
  String get netStatusOverTor => '经由 Tor';

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
  String get deskErrOnionUnreachable =>
      '无法经由 Tor 连接接收方的钱包。即使钱包离线，Epicbox 也能送达付款';

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
  String get deskErrTestNet => '这是测试钱包，无法导入。';

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
  String get deskErrProofSeedRead => '已读取助记词';

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
  String get deskErrProofHistoryOld => '交易记录为旧版数据库格式，无法读取；扫描会恢复余额';

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
  String get deskErrHistOtherWallet => '其他钱包的数据';

  @override
  String get deskErrHistOtherChain => '网络不符';

  @override
  String get deskErrHistNotOurs => '不是钱包数据文件';

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
  String get deskErrHistChains => '该文件来自另一个网络。';

  @override
  String get deskErrHistOtherWalletText => '该文件是从一个助记词不同的钱包导出的。';

  @override
  String get deskErrHistNewerText => '该文件由更新版本的应用生成。请先更新应用，然后再导入。';

  @override
  String get deskErrHistDamagedText => '该文件不完整或已被改动。';

  @override
  String get deskErrHistNotOursText => '该文件不是由 BT Wallet 生成的。';

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
    return '更新服务器错误（$status）。';
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
  String get deskNodeAtTip => '已同步';

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
  String get deskNodeStartIt => '可在“设置 › 节点”中启动。';

  @override
  String deskNodeFailPort(String port) {
    return '端口 $port 被其他程序占用';
  }

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
  String get deskNodeStageKernels => '检查区块链';

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
    return '检查区块链 · $done/$total 百万';
  }

  @override
  String get deskNodeLineKernelsBare => '检查区块链';

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
  String get deskTorNetworkHint => '网络活动经由 Tor 网络。';

  @override
  String get deskTorOff => '关闭';

  @override
  String get deskTorStarting => '正在启动…';

  @override
  String get deskTorOn => '开启';

  @override
  String get deskTorNotConnected => '未连接';

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
  String get deskRecvTorDownText => 'Tor 无法连接。请重试，或关闭 Tor。';

  @override
  String get deskRecvTorStartingText => 'Tor 连接后地址即可访问。';

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
  String get deskRecvEpicboxIntro => '分享它即可收款。';

  @override
  String get deskRecvCheckSix => '念给别人核对时，请检查前六位和后六位字符。';

  @override
  String get deskRecvHttpAddress => '链接 · HTTP 地址';

  @override
  String get deskRecvCopyHttp => '复制 链接 · HTTP 地址';

  @override
  String get deskRecvHttpIntro => '供此电脑上的钱包使用，仅在此钱包打开时。';

  @override
  String get deskRecvHttpTorHint => '如需 Tor 地址，请在“设置 › 隐私”中开启 Tor。';

  @override
  String get deskRecvDirectTor => '链接 · Tor 地址';

  @override
  String get deskRecvTorIntro => '本钱包打开时，经由 Tor 直接从另一个钱包接收。Tor 在“设置 › 隐私”中设置。';

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
  String get deskRecvSignText => '签署发送方的交易文件并保存回复文件。';

  @override
  String get deskRecvOpen => '打开';

  @override
  String get deskRecvFinalizeTitle => '完成回复文件';

  @override
  String get deskRecvFinalizeText => '用接收方的回复文件完成交易并广播付款。';

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
  String get deskSendSpendableWhile => '确认期间可用';

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
  String deskSendLockAll(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部锁定：$count 个输出，$amount EPIC，约 $blocks 个区块。',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出被锁定，$amount EPIC，约 $blocks 个区块。',
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
  String deskSendReviewSetAsideNone(String locked) {
    return '$locked EPIC 原样发出，不预留任何金额。';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部：$count 个输出中的 $locked EPIC 将锁定到找零确认（$blocks 个区块）。期间没有可用余额。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSetAsideAll(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '（$blocks 个区块）',
    );
    return '全部：$locked EPIC 预留至此付款确认$_temp0。没有可用余额。';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输出中的 $locked EPIC 将锁定到找零确认（$blocks 个区块）。期间没有其他可用余额。',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSetAsideEverything(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '（$blocks 个区块）',
    );
    return '$locked EPIC 预留至此付款确认$_temp0。在此期间没有其他可用余额。';
  }

  @override
  String deskSendReviewLocksSome(
    int count,
    String locked,
    String spendable,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count 个输出中的 $locked EPIC 将锁定到找零确认（$blocks 个区块）。$spendable EPIC 仍可使用。',
    );
    return '$_temp0';
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
      other: '（$blocks 个区块）',
    );
    return '$locked EPIC 预留至此付款确认$_temp0。$spendable EPIC 仍可用。';
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
  String get deskSendAdvSmallestText => '花掉能覆盖该金额的最小输出；其余仍可使用。';

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
  String get deskSendFileReadyText => '把这个文件交给接收方，然后用对方的回复文件完成交易。';

  @override
  String get deskSendFinalize => '完成交易';

  @override
  String get deskSendNewSend => '再发送一笔';

  @override
  String get deskSendNodeNotSynced => '节点未同步';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return '节点同步完成后即可恢复发送（$percent%）。';
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
  String get deskSendTorStartingText => '发送会等待 Tor。';

  @override
  String get deskSendEpicboxOff => 'Epicbox 未连接';

  @override
  String get deskSendEpicboxOffText =>
      '开启 Epicbox 接收即可通过 Epicbox 发送，或使用 直接 · 文件传输。';

  @override
  String deskSendEpicboxOffTab(String method) {
    return '开启 Epicbox 接收即可通过 Epicbox 发送，或使用 $method。';
  }

  @override
  String get deskSendEpicboxTurnOn => '开启 Epicbox 接收';

  @override
  String get deskSendDoneViaDirect => '已完成并广播到网络。';

  @override
  String get deskSendDoneViaEpicbox => '已交给 Epicbox。接收方响应后即完成。';

  @override
  String get deskSendViewTx => '在“活动”中查看';

  @override
  String get deskSendFailedTitle => '发送失败';

  @override
  String get deskSendReviewAgain => '重新确认';

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
  String get deskSendNeedsTor => 'Link · Tor 需要 Tor';

  @override
  String get deskSendNeedsTorText => 'onion 地址只能经由 Tor 访问。';

  @override
  String get deskSendNoTorBuild => '此版本不含 Tor。';

  @override
  String get deskSendTurnOnTor => '开启 Tor';

  @override
  String get deskSendHttpClearnet => '链接 · HTTP 直接连接，不经过 Tor。';

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
  String get deskSendAllButton => '最大';

  @override
  String get deskSendConfirmingHidden => '部分余额仍在确认中，暂时无法发送。';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC 仍在确认中，暂时无法发送。';
  }

  @override
  String get deskSendMessage => '留言';

  @override
  String get deskSendMessageHelp => '收款人能看到。';

  @override
  String get deskSendPrivacyOn => '隐私 · Dandelion++ 已开启';

  @override
  String get deskSendPrivacyOff => '隐私 · Dandelion++ 已关闭';

  @override
  String get deskSendDandelionText =>
      '交易在扩散前会先经过几个随机节点，这让它的来源更难追踪。钱包所用的节点仍会收到它。';

  @override
  String get deskSendHintSent => '已发送。';

  @override
  String get deskSendHintQueued => '已排队。如需再次发送，请输入新的金额和接收方。';

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
  String get deskSendHintFix => '请修正标记的字段。';

  @override
  String get deskSendHintChecking => '正在计算此金额的手续费。';

  @override
  String get deskSendHintDefault => '检查之前不会发送任何内容。';

  @override
  String get deskSendReviewWaitTor => '等待 Tor';

  @override
  String get deskSendReviewTorOff => 'Tor 未连接';

  @override
  String get deskSendReview => '确认';

  @override
  String get deskSendSummary => '摘要';

  @override
  String get deskSendNetworkFee => '网络手续费';

  @override
  String get deskSendTotal => '总计';

  @override
  String get deskSendUpdating => '钱包扫描期间余额正在更新。';

  @override
  String get deskSendEpicboxLine2 => 'Epicbox 服务器会暂存付款，直到对方打开钱包。';

  @override
  String get deskSendDirectLine1 => '直达对方钱包。';

  @override
  String get deskSendDirectLine2 => '对方钱包必须处于打开状态。onion 地址经由 Tor。';

  @override
  String get deskSendFileLine1 => '无需联网。';

  @override
  String get deskSendFileLine2 => '把文件交给对方，收回对方的回复文件，然后在这里完成交易。';

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
  String get deskFinPosted => '付款已广播';

  @override
  String get deskFinTitle => '完成回复文件';

  @override
  String get deskFinNoticeTitle => '用于文件付款';

  @override
  String get deskFinNoticeText => '使用接收方发回的回复文件。';

  @override
  String get deskFinTryAgain => '重试';

  @override
  String get deskFinPostedText => '付款已完成并广播到网络。可在“活动”中查看进度。';

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
  String get deskImpWrongTypeText => '不是交易文件。请选择发送方提供的 .tx 文件。';

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
  String get deskActSearchHint => '搜索付款';

  @override
  String get deskActSearchLabel => '搜索付款';

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
  String get deskActDetailReceived => '收到的付款';

  @override
  String get deskActDetailSent => '发出的付款';

  @override
  String get deskActLoading => '正在加载付款';

  @override
  String get deskActWaitingNode => '等待节点同步。';

  @override
  String get deskActFilterAll => '全部';

  @override
  String get deskActFilterReceived => '已接收';

  @override
  String get deskActFilterSent => '已发送';

  @override
  String deskActNoMatchTitle(String query) {
    return '没有与“$query”匹配的结果。';
  }

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
  String get deskActEmptyTitle => '还没有付款';

  @override
  String get deskActEmptyText => '发送和接收的付款，最新的在前。';

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
  String get deskConNone => '暂无联系人';

  @override
  String get deskConNoMatchList => '没有匹配的联系人';

  @override
  String get deskConAdd => '添加联系人';

  @override
  String get deskConIdle => '选择一个联系人。';

  @override
  String get deskConEmptyTitle => '暂无联系人';

  @override
  String get deskConEmptyText => '联系人就是一个地址的名称。';

  @override
  String get deskConSendToAddress => '发送到地址';

  @override
  String deskConLastTx(String when) {
    return '最近付款：$when';
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
    return '与 $name 的付款';
  }

  @override
  String get deskConAllTx => '全部付款';

  @override
  String get deskConTxNone => '还没有与此联系人的付款。从“发送”付给对方的付款会显示在这里。';

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
      '地址无效。请使用 Epicbox 地址（es5x…@服务器）、链接地址（https://…）或 onion 地址（….onion）。';

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
  String get deskConDeleteBody => '删除此联系人；过去的付款仍保留在“活动”中。此操作无法撤销。';

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
  String get deskOutIntro => '输出是构成余额的一个个部分。一笔发送会花掉整个输出，并把找零作为新的输出返回。';

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
  String deskOutCardWait(int blocks) {
    return '请等待发送确认（约 $blocks 个区块）。';
  }

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
      other: '花费 $count 个输出。手续费至少 $fee EPIC。',
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
  String get deskOutNoneText => '收到第一笔付款时会生成一个输出。';

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
  String get deskOutTileImmature => '挖矿奖励';

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
  String get deskOutStatusAwaiting => '等待回应';

  @override
  String get deskOutNoteWaitingSender => '等待发送方';

  @override
  String get deskOutStatusUnpaid => '未支付的账单';

  @override
  String get deskOutNoteNotInBalance => '不计入余额';

  @override
  String get deskOutStatusImmature => '成熟中';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还需 $number 次确认',
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
  String deskOutNoteByPendingSend(String date) {
    return '被进行中的付款占用 · $date';
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
  String deskOutSplitDialogText(String spent, String made, int blocks) {
    return '花费 $spent，生成 $made。所有可用余额会锁定 $blocks 个确认。';
  }

  @override
  String deskOutConsDialogText(String spent, String made, int blocks) {
    return '花费 $spent，生成 $made。所有可用余额会锁定 $blocks 个确认。';
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
  String deskOutFactLockedValue(String amount, int blocks) {
    return '$amount EPIC，约 $blocks 个区块。期间没有可用余额。';
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
  String deskOutSplitDoneText(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个约 $amount EPIC 的输出，正在确认。锁定 $blocks 个确认。',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount, int blocks) {
    return '一个 $amount EPIC 的输出，正在确认。锁定 $blocks 个确认。';
  }

  @override
  String get deskOutNotPostedTitle => '未广播';

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
  String get deskOutPostingDesc => '正在广播';

  @override
  String get deskOutDoneDesc => '已完成';

  @override
  String get deskOutSplitDesc => '更多输出，这样多笔发送可以接连进行。';

  @override
  String get deskOutConsDesc => '用一个输出代替多个。';

  @override
  String deskOutNothingText(String what) {
    return '无需合并：钱包只有$what。';
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
  String deskOvNodeAddrText(String node) {
    return '已保存为 $node。';
  }

  @override
  String get deskOvNodeIncompatTitle => '节点版本不兼容';

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
  String get deskOvCantReachNodeText => '余额可能不是最新的。请检查节点，或在节点设置中选择其他节点。';

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
  String get deskOvSyncText => '正在下载区块。';

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
  String get deskOvSendWaits => '节点同步完成后即可恢复发送。';

  @override
  String get deskOvAvailable => '可用余额';

  @override
  String deskOvAsOfBlock(String block) {
    return '截至区块 $block';
  }

  @override
  String get deskOvEmptyHint => '分享 Epicbox 地址，接收你的第一笔 EPIC。';

  @override
  String get deskOvFiatNote => '  全部余额';

  @override
  String get deskOvBreakTotal => '总额';

  @override
  String get deskOvBreakConfirming => '确认中';

  @override
  String get deskOvBreakImmature => '挖矿奖励';

  @override
  String get deskOvBreakAwaiting => '等待发送方';

  @override
  String get deskOvBreakLocked => '发送中锁定';

  @override
  String get deskOvUpdating => '正在更新';

  @override
  String get deskOvHiddenAmount => '金额已隐藏';

  @override
  String get deskOvLoading => '正在加载付款';

  @override
  String get deskOvEmptyTitle => '还没有付款';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '收到的 EPIC 先显示为确认中，$blocks 个确认后变为可用。',
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
      other: '$count 笔文件付款待完成',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => '使用接收方发回的回复文件完成交易。';

  @override
  String get deskOvFinalize => '完成交易';

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
  String get deskTxNoteBlock => '区块时间。发送方未知。';

  @override
  String get deskTxNoteScanTime => '扫描时间；无法读取区块时间。未记录发送方。';

  @override
  String get deskTxNoteUnknown => '未记录发送方。';

  @override
  String get deskTxFoundRestoredLabel => '已恢复';

  @override
  String get deskTxFoundRestoredLine => '在区块链上找到';

  @override
  String get deskTxFoundRestoredStep => '在区块链上找到';

  @override
  String get deskTxFoundRestoredTip => '恢复此钱包时在区块链上找到。未记录发送方。';

  @override
  String get deskTxFoundRescanLabel => '核对余额时找到';

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
  String get deskTxBackupTip => '从钱包数据文件导入。';

  @override
  String get deskTxFromBackup => '已导入';

  @override
  String get deskTxStatusImmature => '成熟中';

  @override
  String get deskTxStatusWaitingSender => '等待发送方';

  @override
  String get deskTxStatusWaitingResponseFile => '等待回复文件';

  @override
  String get deskTxStatusWaitingRecipient => '等待接收方';

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
  String get deskTxNowBackup => '从钱包数据文件导入。未在链上核对状态。';

  @override
  String deskTxNowImmature(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已确认，但挖矿奖励需要 $countString 个确认后才能使用。',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender => '等待发送方将其广播到网络。';

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
    final intl.NumberFormat confirmationsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String confirmationsString = confirmationsNumberFormat.format(
      confirmations,
    );

    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '已确认，$confirmationsString 个确认。',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => '已取消';

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
  String get deskTxHeadBackup => '从钱包数据文件导入';

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
  String get deskTxTechTitle => '技术详情';

  @override
  String get deskTxStepMined => '已挖出区块';

  @override
  String get deskTxStepSpendable => '已完成';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还需 $count 次确认',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => '付款已到达';

  @override
  String get deskTxStepCreated => '付款已发起';

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
  String get deskTxCancelOutgoingTitle => '取消这笔付款？';

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '发往 $who 的 $amount EPIC。尚未支付任何款项：取消免费且一定成功。';
  }

  @override
  String get deskTxCancelKeep => '保留';

  @override
  String get deskTxCancelIncomingAction => '取消付款';

  @override
  String get deskTxCancelOutgoingAction => '取消付款';

  @override
  String get deskOnbWelcomeAdd => '添加钱包';

  @override
  String get deskOnbWelcomeTagline => '密钥和币都保存在这台电脑上，由密码锁定。';

  @override
  String get deskOnbWelcomeCreate => '创建新钱包';

  @override
  String get deskOnbWelcomeImport => '导入钱包';

  @override
  String get deskOnbWelcomeImportSub => '从旧版 Epic Wallet 或文件夹导入';

  @override
  String get deskOnbWelcomeCreateSub => '生成新的助记词';

  @override
  String get deskOnbWelcomeRestoreSub => '也适用于 Stack Wallet 或 Epic Pay';

  @override
  String get deskOnbWelcomeRestore => '用助记词恢复';

  @override
  String get deskOnbWelcomeTestNote => '新钱包将创建在此测试网络上。';

  @override
  String get deskOnbWelcomeBack => '返回解锁';

  @override
  String get deskOnbWelcomeAdvanced => '高级';

  @override
  String get deskOnbWelcomeNetwork => '网络';

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
  String get deskOnbCreateStageCreate => '正在生成助记词';

  @override
  String get deskOnbCreateStageSave => '正在保存钱包';

  @override
  String get deskOnbCreateNotCreated => '钱包未创建';

  @override
  String get deskOnbCreateCreating => '正在创建钱包';

  @override
  String deskOnbCreateTestLead(String network) {
    return '$network 上的钱包，这是一个测试网络。';
  }

  @override
  String get deskOnbCreateDiskFull => '未保存钱包：磁盘已满。请释放一些空间后重试。';

  @override
  String get deskOnbCreateWait => '请保持应用打开。';

  @override
  String get deskOnbCreateLocking => '正在锁定已打开的钱包';

  @override
  String get deskOnbCreateSide => '新钱包';

  @override
  String get deskOnbCreateTitle => '创建钱包';

  @override
  String get deskOnbCreateLead => '密码用于在这台电脑上解锁此钱包；只有助记词才能恢复币。';

  @override
  String get deskOnbCreateTestNote => '测试网络上的钱包，不用于真实的 EPIC';

  @override
  String get deskOnbCreatePhraseLead => '请将这些单词按顺序抄写在纸上。它们是恢复此钱包的唯一方式。';

  @override
  String get deskOnbCreateRevealFirst => '请先显示助记词';

  @override
  String get deskOnbCreateWarn => '任何拿到这些单词的人都能拿走你的币。';

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
    return '我已抄下全部 $_temp0';
  }

  @override
  String get deskOnbRestoreDone => '钱包已恢复。';

  @override
  String get deskOnbRestoreNotRestored => '钱包未恢复';

  @override
  String get deskOnbRestoreRestoring => '正在恢复钱包';

  @override
  String deskOnbRestorePermission(String folder) {
    return '钱包文件未写入：没有 $folder 的权限。请允许写入该文件夹，然后重试。';
  }

  @override
  String get deskOnbRestoreWait => '请保持应用打开。首次扫描后会显示余额。';

  @override
  String get deskOnbRestoreSide => '恢复钱包';

  @override
  String get deskOnbRestorePasswordLead => '请设置在这台电脑上解锁此钱包的密码。';

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
  String get deskOnbRestoreWordsLead => '按顺序输入这些单词，或把整段助记词粘贴到任意一个框中。';

  @override
  String get deskOnbRestoreClear => '清空';

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
  String get deskOnbSameTitle => '此钱包已在这里';

  @override
  String get deskOnbSameBody => '此助记词属于列表中的一个钱包。没有添加任何内容。';

  @override
  String get deskOnbSameWallet => '钱包';

  @override
  String get deskOnbSameNote => '用该钱包的密码打开它，或用此助记词设置新密码。';

  @override
  String get deskOnbSameOpen => '打开';

  @override
  String get deskOnbUnlockWhoWindows => '任何以你的身份使用这台电脑的人都能打开此钱包。';

  @override
  String get deskOnbUnlockWho => '任何以你的身份使用这台电脑的人都能打开此钱包。';

  @override
  String get deskOnbUnlockWrong => '密码错误。请检查大写锁定键和键盘布局。';

  @override
  String deskOnbUnlockPortInUse(String port) {
    return '端口 $port 被其他程序占用。请关闭该程序，然后重试。';
  }

  @override
  String get deskOnbUnlockStageCheck => '正在检查钱包文件';

  @override
  String get deskOnbUnlockStageWallet => '正在启动钱包服务';

  @override
  String get deskOnbUnlockStageUnlock => '正在解锁钱包';

  @override
  String get deskOnbUnlockEnter => '请输入密码';

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
  String deskOnbUnlockUnlocking(String name) {
    return '正在解锁 $name';
  }

  @override
  String get deskOnbUnlockNote => '随后节点、余额和接收会在后台完成。';

  @override
  String get deskOnbUnlockTitle => '解锁钱包';

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
    return '原位置：$folder。请从列表中移除该钱包，或用助记词恢复。';
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
    return '可用 $size';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return '目前约占用 $size，';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return '目前占用 $size，';
  }

  @override
  String get deskOnbNodeFirewall => 'Windows 会询问一次';

  @override
  String get deskOnbNodeFirewallText => '是否允许它通过防火墙。请在专用网络上允许。';

  @override
  String deskOnbNodeGrowing(String free) {
    return '并缓慢增长 · $free';
  }

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
  String get deskOnbNodeExistingText => '连接到这里已在运行的 Epic GUI 或 CLI 节点。';

  @override
  String get deskOnbNodeAddress => '本机节点的地址';

  @override
  String get deskOnbNodeCheck => '检查';

  @override
  String get deskOnbNodeBundled => '启动本地节点';

  @override
  String get deskOnbNodeBundledText => '点击“保存”后把区块链下载到钱包的文件夹。';

  @override
  String deskOnbNodeFallback(String host) {
    return '本地节点同步完成前使用 $host';
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
      other: '已粘贴 $count 个单词；助记词应为 12、15、18、21 或 24 个单词。',
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
  String get deskOnbImportFindingLead => '正在搜索旧版 Epic Wallet 和 epic 程序的文件夹。';

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
  String get deskOnbImportNoneTitle => '未找到钱包';

  @override
  String get deskOnbImportNoneLead => '请选择钱包文件夹，或用助记词恢复。';

  @override
  String get deskOnbImportChooseTitle => '选择钱包';

  @override
  String get deskOnbImportChooseLead => '勾选的钱包会添加到应用中。交易记录会通过扫描重建。';

  @override
  String get deskOnbImportCheckTitle => '正在检查钱包';

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
  String get deskOnbImportOlderSub => '钱包和文件夹';

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
    return '$name 在旧应用中的密码';
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
  String get deskAppFirstScanTitle => '首次扫描';

  @override
  String get deskAppFirstScanBody => '钱包正在扫描区块链查找属于它的币，期间仍可使用。';

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
  String deskShellOpenWalletSettingsNamed(String name) {
    return '打开钱包设置：$name';
  }

  @override
  String get deskShellSwitchWallet => '切换钱包';

  @override
  String get deskTourOverviewTitle => '概览';

  @override
  String get deskTourOverviewText => '余额和仍在确认中的金额，下面是最近的付款。其他功能都在侧边栏中。';

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
  String get deskTourNodeTitle => '设置 › 节点';

  @override
  String get deskTourNodeText => '钱包从哪个节点读取区块链。其余设置页面列在左侧。';

  @override
  String get deskTourHelpTitle => '帮助';

  @override
  String get deskTourHelpText => '帮助主题、“报告问题”和“再次查看导览”。';

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
  String deskKitLimitedNetwork(String site) {
    return '无法访问 $site；信息仅来自节点本身。';
  }

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
  String get deskKitAtTip => '已同步';

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
  String deskKitSourceChecked(String time, String site) {
    return '$site，检查于 $time';
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
  String get deskKitNodeDownHead => '节点无响应';

  @override
  String deskKitNodeDownText(String host) {
    return '切换到 $host？这是状态最好的其他节点。';
  }

  @override
  String get deskKitSwitch => '切换';

  @override
  String get deskKitLimitedInfo => '信息有限';

  @override
  String deskKitFromStatusSite(String site) {
    return '来自 $site';
  }

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
  String get deskKitMethodWaitingTor => '等待 Tor';

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
    return '端口 $port 被其他程序占用。请关闭该程序，或在下方更改端口。';
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
  String get deskKitChipNotOverTor => '不使用 Tor';

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
  String get deskSetBackupExportTitle => '导出钱包数据';

  @override
  String get deskSetBackupExportHint =>
      '交易记录、联系人、账单和设置，存在只有持这个助记词的钱包才能打开的文件里。助记词本身只找回余额，找不回这些。';

  @override
  String get deskSetBackupExporting => '正在导出…';

  @override
  String get deskSetBackupExportButton => '导出…';

  @override
  String get deskSetBackupImportTitle => '导入钱包数据';

  @override
  String get deskSetBackupImportHint =>
      '从钱包数据文件找回这个钱包的交易记录、联系人、账单和设置。不会删除任何内容；同一文件导入两次不会有变化。';

  @override
  String get deskSetBackupImportButton => '导入…';

  @override
  String get deskSetBackupCsvHint => '用于电子表格的普通表格。不加密，不能导入。';

  @override
  String get deskSetBackupSaveDialogTitle => '保存钱包数据';

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
  String get deskSetBackupInFileSub => '谁付了什么、手续费、备注和标签；账单；设置';

  @override
  String get deskSetBackupNotIn => '不包含';

  @override
  String get deskSetBackupNotInValue => '助记词、密钥、密码';

  @override
  String get deskSetBackupOpensWith => '可打开的钱包';

  @override
  String get deskSetBackupOpensWithValue => '这个钱包，或用它的助记词恢复的钱包';

  @override
  String get deskSetBackupFile => '文件';

  @override
  String get deskSetBackupFileNote => '文件包含截至目前的全部内容。';

  @override
  String get deskSetBackupExportDesc => '包含这个钱包的交易记录、联系人、账单和设置的文件。';

  @override
  String get deskSetBackupSaved => '已保存';

  @override
  String get deskSetBackupKeepCopy => '在这台电脑之外也保存一份：U 盘、另一块硬盘或云存储。';

  @override
  String get deskSetBackupOpenFolder => '打开文件夹';

  @override
  String get deskSetBackupSaving => '正在保存…';

  @override
  String get deskSetBackupTryAgain => '重试';

  @override
  String get deskSetBackupSaveAs => '另存为…';

  @override
  String get deskSetBackupOpenDialogTitle => '打开钱包数据文件';

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
  String get deskSetBackupBringsBackValue => '付款详情和备注、列表中丢失的较早付款、联系人、账单和设置';

  @override
  String get deskSetBackupNeeds => '需要';

  @override
  String get deskSetBackupNeedsValue => '这个钱包（同一助记词）导出的文件。请先用助记词恢复钱包。';

  @override
  String get deskSetBackupChooseFile => '选择文件…';

  @override
  String get deskSetBackupImportDesc => '找回这个钱包的交易记录、联系人、账单和设置；已有记录保留。';

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
  String get deskSetBackupRangeAll => '全部时间';

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
    return '$_temp0 · $file';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '$file';
  }

  @override
  String get deskSetBackupNotEncrypted => '未加密。';

  @override
  String get deskSetBackupNotEncryptedBody => '任何拿到文件的人都能看到金额、日期、地址和备注。';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款不在你导出的钱包数据中。',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '自上次导出钱包数据以来，有 $count 笔付款是新的或有改动。',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody => '用助记词恢复只能找回余额，无法找回谁付了什么。';

  @override
  String get deskSetBackupNotNow => '以后再说';

  @override
  String get deskSetDlgChainTitle => '找到链数据';

  @override
  String get deskSetDlgChainDesc => '本地节点可以使用这台电脑上已有的 Epic 链数据，无需重新下载。';

  @override
  String get deskSetDlgChainFolder => '文件夹';

  @override
  String get deskSetDlgChainSize => '大小';

  @override
  String get deskSetDlgChainUpdated => '上次更新';

  @override
  String get deskSetDlgChainUpdatedValue => '3 天前';

  @override
  String get deskSetDlgChainOthers => '另找到 1 份副本；这一份是最新的。';

  @override
  String get deskSetDlgChainInUse =>
      '另一个 Epic 程序正在使用此文件夹。请关闭它，然后重新选择本地节点以使用这些数据。';

  @override
  String get deskSetDlgChainUseIt => '要使用吗？';

  @override
  String get deskSetDlgChainOlderWallet => '使用此文件夹的旧版 Epic Wallet 之后会重新同步。';

  @override
  String get deskSetDlgChainFresh => '重新下载';

  @override
  String get deskSetDlgChainUse => '使用这些数据';

  @override
  String get deskSetDlgPwChanged => '密码已更改。';

  @override
  String get deskSetDlgPwTitle => '更改密码';

  @override
  String get deskSetDlgPwDesc => '从现在起用新密码解锁此钱包；“在这台电脑上记住”会关闭。';

  @override
  String get deskSetDlgPwDescPlain => '从现在起用新密码解锁此钱包，这台电脑也不再记住它。';

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
  String get deskSetDlgRemoveWhat => '要移除什么';

  @override
  String get deskSetDlgRemoveFromList => '从列表中移除';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return '文件保留在 $folder 中；“添加钱包”可将其加回。';
  }

  @override
  String get deskSetDlgDeleteWallet => '删除钱包';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return '从 $folder 删除它的密钥和数据库。只有助记词能恢复它；没有助记词，币就会丢失。';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      '如果还要删除它的文件，请解锁此钱包，然后使用“设置 › 此钱包”中的“删除钱包”。';

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
    return '本地节点同步完成前使用 $host';
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
  String get deskSetLnodeNoProgressText => '请重新启动节点，或查看节点日志。';

  @override
  String deskSetLnodePortInUse(String port) {
    return '端口 $port 被其他程序占用。';
  }

  @override
  String get deskSetLnodePortInUseText => '关闭另一个程序，或在“节点服务器”中选择那个节点。';

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
    return '本地节点同步完成前，可由公共节点 $host 代替。';
  }

  @override
  String get deskSetLndAskNote => '只询问一次。可以在“设置 › 节点 › 同步期间”中更改节点和这个选择。';

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
    return '从 $path 删除 $size；下次启动时会重新下载区块链。密钥和交易记录保留。';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return '从 $path 删除链数据。节点会停止，下次启动时会重新下载整个区块链（需要数小时）。钱包密钥和交易记录不受影响。';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return '输入“$word”以确认';
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
  String get deskSetLndReuseTitle => '找到链数据';

  @override
  String get deskSetLndReuseDesc =>
      '另一个 Epic 节点在这里留下了链数据。本地节点可以读取那个文件夹，而不用下载区块链。';

  @override
  String get deskSetLndLooking => '正在查找…';

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
  String deskSetPeersNotAddress(String port) {
    return '不是 IP 地址加端口，例如 203.0.113.5:$port。';
  }

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
  String deskSetPeersRefreshed(int seconds) {
    return '每 $seconds 秒刷新';
  }

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
    return '最大传入和传出：$min 到 $max（默认 $def）。';
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
  String deskSetNodePortNote(String port) {
    return '请检查地址和端口（通常是 $port）。';
  }

  @override
  String deskSetNodeListNote(String site) {
    return '状态来自 $site；延迟从这台电脑测得。';
  }

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
  String get deskSetPhraseIntro => '请将这些单词按顺序抄写在纸上。它们是恢复此钱包的唯一方式。';

  @override
  String get deskSetPhrasePanel => '输入密码以显示这些单词';

  @override
  String get deskSetPhraseShowWords => '显示助记词';

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
  String get deskSetPhraseHideWords => '隐藏助记词';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return '$seconds 秒后隐藏';
  }

  @override
  String get deskSetPhraseQrLabel => '助记词二维码';

  @override
  String get deskSetPhraseBackUp => '备份助记词';

  @override
  String get deskSetPhraseBackUpText => '任何拿到这些单词的人都能拿走你的币。请确认没有人能看到屏幕。';

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
  String deskSetPrivStartingDetail(int progress) {
    return '$progress%。所有连接都在等待 Tor。';
  }

  @override
  String get deskSetPrivNotPublished => 'Tor 地址尚未发布。发送不受影响。';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem。发送不受影响。';
  }

  @override
  String get deskSetPrivConnected => '已连接';

  @override
  String get deskSetPrivNotConnected => '未连接';

  @override
  String get deskSetPrivStoppedDetail => 'Tor 已停止。请重试，或关闭 Tor。';

  @override
  String deskSetPrivProblemDetail(String problem) {
    return '$problem。请重试，或关闭 Tor。';
  }

  @override
  String get deskSetPrivStatusSite => '状态网站';

  @override
  String deskSetPrivUseStatus(String site) {
    return '使用 $site';
  }

  @override
  String get deskSetPrivUseStatusHint =>
      '显示哪些节点和 Epicbox 服务器在线，数据来自 status.btlabs.uk 上的公开列表。';

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
  String get deskSetRecvEpicboxText => 'Epicbox 服务器会暂存付款，直到钱包打开。';

  @override
  String get deskSetRecvEpicboxServer => 'Epicbox 服务器';

  @override
  String get deskSetRecvEpicboxServerHint => '由哪个服务器为此地址暂存付款。双方钱包可以使用不同的服务器。';

  @override
  String get deskSetRecvSwitchingServer => '正在切换 Epicbox 服务器…';

  @override
  String deskSetRecvListNote(String site) {
    return '状态来自 $site。';
  }

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
  String get deskSetHttpPortError => '端口必须在 1024 到 65535 之间';

  @override
  String get deskSetHttpGuideHelp => '从互联网接收：如何操作';

  @override
  String get deskSetHttpPort => '端口';

  @override
  String deskSetHttpPortHint(String port) {
    return '1024 到 65535。默认 $port。';
  }

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
    return '钱包在 0.0.0.0 的端口 $port 上响应，其他设备即可向它付款。';
  }

  @override
  String get deskSetHttpStep2 => '转发端口';

  @override
  String deskSetHttpStep2Text(String port) {
    return '在路由器的管理页面（通常是 192.168.1.1）找到“端口转发”，把 TCP $port 转发到这台电脑。';
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
  String get deskSetReportDesc => '已加密，只有开发者能读取。“保存到文件”会保留一份未加密的副本。';

  @override
  String get deskSetReportWhat => '发生了什么';

  @override
  String get deskSetReportWhatHint => '你做了什么，期望发生什么，实际发生了什么';

  @override
  String get deskSetReportAttach => '附上日志';

  @override
  String get deskSetReportAttachHint => '应用日志的最新部分，不含助记词、密码和其他机密信息。';

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
  String get deskSetRescanLog => '核对日志';

  @override
  String get deskSetRescanText => '重新核对链上属于此钱包的资金。在余额看起来不对时使用。';

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
  String get deskSetRescanFinished => '核对已完成';

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
  String get deskSetRescanRevived => '已重新解锁';

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
  String get deskSetWalletsImport => '导入钱包';

  @override
  String get deskSetWalletsImportText => '从旧版 Epic Wallet 或文件夹导入';

  @override
  String get deskSetWalletsRestore => '用助记词恢复';

  @override
  String get deskSetWalletsRestoreText => '使用助记词';

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
  String get deskSetupAgain => '正在重新运行设置向导。在最后一步点击“保存设置”之前不会有任何更改。';

  @override
  String get deskSetupPrefsLead => '应用语言';

  @override
  String get deskSetupNodeTitle => '选择节点';

  @override
  String get deskSetupNodeLead => '钱包通过 Epic 节点读取区块链并发送交易。';

  @override
  String get deskSetupLocalTitle => '本地节点';

  @override
  String get deskSetupLocalLead => '在这里运行节点意味着什么，以及使用哪个节点。';

  @override
  String get deskSetupEpicboxTitle => 'Epicbox';

  @override
  String get deskSetupSideTitle => '设置向导';

  @override
  String get deskSetupBackToWallet => '返回钱包';

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
  String get deskSetupLocalNodeText => '在这台电脑上运行：私密，但需要磁盘空间和首次同步。';

  @override
  String get deskSetupEpicboxText => 'Epicbox 服务器会暂存付款，直到钱包打开。';

  @override
  String get deskSetupEpicboxServer => 'Epicbox 服务器';

  @override
  String deskSetupExistingNode(String host) {
    return '$host 上的现有节点';
  }

  @override
  String deskSetupSaveStartsFallback(String node) {
    return '保存后会启动节点；同步完成前由 $node 代替。';
  }

  @override
  String get deskSetupSaveStarts => '保存后会启动节点。首次同步需要数小时；期间钱包会打开。';

  @override
  String get deskSetAboutLicencesLead => '此钱包中的开源软件，各自遵循其许可证。';

  @override
  String get deskSetAboutLicenceApp => 'BT Wallet，BT Labs 出品：Apache-2.0。';

  @override
  String get deskSetAboutBrowserNotOpened => '未能打开浏览器';

  @override
  String get deskSetAboutOpen => '打开';

  @override
  String deskSetAboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return '节点 $version';
  }

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
  String get deskSetAboutCheckNow => '检查';

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
      other: '找到 $count 个主题',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => '没有匹配的主题';

  @override
  String get deskSetHelpReportText => '描述出了什么问题；可附上已清理的应用日志，加密后发送给开发者。';

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
      'Windows 无法保护钱包的机密（DPAPI 拒绝），因此未保存任何内容。请直接以你自己的身份使用 Windows，用你自己的密码，不要通过远程或服务会话，然后重试。';

  @override
  String get deskKeyringMissingTitle => '未找到密钥环';

  @override
  String get deskKeyringMissingText =>
      'BT Wallet 将其设置和钱包的密封密码保存在系统密钥环中，但没有密钥环响应。请安装或启动密钥环（GNOME Keyring 或 KWallet），或使用运行密钥环的桌面会话，然后选择重试。';

  @override
  String get deskKeyringLockedTitle => '密钥环已锁定';

  @override
  String get deskKeyringLockedText =>
      'BT Wallet 将其设置和钱包的密封密码保存在系统密钥环中，而它已锁定。请解锁它（通常使用你解锁这台电脑的密码），然后选择重试，或选择立即解锁让系统询问密码。';

  @override
  String get deskKeyringUnlockNow => '立即解锁';

  @override
  String get txStatusNotDelivered => '未送达';

  @override
  String get txDetailsNotDeliveredBody =>
      '此付款尚未到达 Epicbox 服务器，收款人还没有收到。在重新发送或取消之前，这些币保持锁定。';

  @override
  String get txDetailsSendAgainDone => '已重新发送。收款人的钱包上线后即可完成。';

  @override
  String get deskTxThisWallet => '此钱包';

  @override
  String get deskErrOldLinks => '此钱包的文件夹中含有链接，因此不会导入。请用助记词恢复。';

  @override
  String get deskErrOldIncomplete => '无法完整读取此钱包的文件夹，因此不会导入。请用助记词恢复。';

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
      '未送达。这笔付款没有到达 Epicbox 服务器，收款人没有收到。请重新发送，或取消以释放这些币。';

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
  String deskSendMessageCount(int used, int max) {
    return '$used / $max';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return '消息超过 $max 字节，请缩短。';
  }

  @override
  String get deskSendMessageTooLongPlain => '消息太长，请缩短。';

  @override
  String get deskSetPhraseCopyTitle => '复制助记词？';

  @override
  String get deskSetPhraseCopyText => '任何拿到这些单词的人都能转走你的资金。请把复制的内容保存在安全的地方。';

  @override
  String get deskOutAdvanced => '管理输出';

  @override
  String get deskOutStrategyHint =>
      '一笔发送花掉哪些输出。“最小”花掉能覆盖该金额的最小输出；“全部”花掉每个输出并返回一个。';

  @override
  String get txStatusNotPosted => '不在网络上';

  @override
  String get txStatusStalled => '已停滞';

  @override
  String get txDetailsStalledBody => '对方尚未广播这笔付款。';

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
  String get deskTxBroadcastDone => '已广播到网络';

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
  String get deskTxDetailsTip => '仅适用于核对余额时找到的付款。';

  @override
  String get deskTxDetailsFrom => '来自';

  @override
  String get deskTxDetailsFromTip => '付款人，仅供你记录。未验证。';

  @override
  String get deskTxDetailsFromHint => '发送方地址';

  @override
  String get deskTxDetailsFromBad => '请使用 Epicbox、http(s) 或 .onion 地址。';

  @override
  String get deskTxDetailsNote => '私人备注';

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
      other: '文件中有 $n 笔付款带有不同的详情。除非你选择文件中的，否则保留你的。',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => '我的';

  @override
  String get deskHistConflictBackup => '文件';

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
      other: '旧钱包的历史中有 $n 笔付款带有不同的详情。除非你选择旧钱包中的，否则保留你的。',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => '旧钱包';

  @override
  String get deskHistConflictApply => '应用';

  @override
  String get deskUpdAvailable => '有可用更新';

  @override
  String deskUpdDownload(String version) {
    return '下载 $version';
  }

  @override
  String get deskUpdOpensPage => '打开下载页面';

  @override
  String deskUpdDownloading(String percent) {
    return '正在下载 $percent%';
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
  String get advIntro => '每个开关会在相应位置显示钱包的另一部分。';

  @override
  String get advShowsHeader => '显示更多';

  @override
  String get advNetworkHeader => '网络';

  @override
  String get advOutputs => '输出';

  @override
  String get advOutputsHint =>
      '在“钱包”下和主页上显示“输出”页面。它列出组成余额的币，可以拆分或合并，并设置发送使用的默认值。正在进行的拆分或合并会让该页面保持可见。';

  @override
  String get advTechnical => '技术详情';

  @override
  String get advTechnicalHint =>
      '在付款详情中显示技术信息行：内核、slate ID、承诺和区块高度。在“账单”设置中显示账单可付款的时长。';

  @override
  String get advSendOptions => '发送选项';

  @override
  String get advSendOptionsHint =>
      '在“设置 › 交易”中显示发送的“策略”和“拆分找零”：一笔发送花掉哪些输出，以及找零是否拆分。只要其中一项不是默认值，就保持可见。';

  @override
  String get advServerDetails => '服务器详情';

  @override
  String get advServerDetailsHint =>
      '在服务器列表和状态卡片中显示主机、延迟、版本和区块高度，并在“接收”中显示 Epicbox 地址。';

  @override
  String get advRecheckHeight => '从某个高度重新核对';

  @override
  String get advRecheckHeightHint =>
      '让“重新核对余额”可以从某个区块高度或日期开始，而不是从第一个区块开始。更快，也是跳过早期记录的唯一办法。恢复钱包时始终可以选择。';

  @override
  String get advModeStandard => '常规';

  @override
  String get advModeTorOnly => '仅 Tor';

  @override
  String get advModeTorOnlyLine => '所有连接都经过 Tor。Tor 就绪之前，什么都不会连接。';

  @override
  String get advReset => '再次全部隐藏';

  @override
  String get advBuiltInNode => '本地节点';

  @override
  String get advLogs => '日志';

  @override
  String get deskSetFrameAdvanced => '高级';

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
      '在每笔交易上显示“技术详情”折叠区：内核、slate ID、承诺和区块高度。不开启时，交易上的“更多”链接可以一次性显示它们。在“账单”中显示高级折叠区。';

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
  String get deskSetAdvBuiltInNode => '本地节点';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      '让这台电脑运行自己的节点：“节点”下的“这台电脑”选项、它的同步面板，以及概览中的“启动节点”。同步整条链需要数小时和数 GB 磁盘空间。已在运行的节点会保留它的各行。';

  @override
  String get deskSetAdvLogs => '日志';

  @override
  String get deskSetAdvLogsHint =>
      '在“文件与日志”下显示“日志”分组：打开日志文件夹、清除日志。无论是否开启，“报告问题”都会附上日志。';

  @override
  String get deskSetAdvNetwork => '网络';

  @override
  String get deskSetAdvModeTorOnlyText => '所有连接都经过 Tor。Tor 就绪之前，什么都不会连接。';

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
  String get deskSetAcctAutoLockHint =>
      '在这段时间内没有按键或移动鼠标时锁定钱包。选“从不”时，只能用“锁定钱包”锁定。所有钱包。';

  @override
  String get torUndercoverKeepsOn => '隐身模式让 Tor 保持开启。';

  @override
  String get torLockedTorOnly => '在“仅 Tor”下保持开启。';

  @override
  String get torUndercoverChange => '更改隐身设置';

  @override
  String get torUndercoverChangeShort => '更改';

  @override
  String get txDetailsMore => '更多';

  @override
  String get restoreStartFromLink => '从某个日期或高度开始';

  @override
  String restoreScanningFrom(String month) {
    return '从 $month 开始扫描';
  }

  @override
  String get restoreScanningFromStart => '从头开始扫描';

  @override
  String get restoreScanFromStart => '从头扫描';

  @override
  String restoreScanningFromBlock(String height) {
    return '从区块 $height 开始扫描';
  }

  @override
  String get scanStartChange => '更改起点';

  @override
  String get scanStartInfoTitle => '扫描起点';

  @override
  String get scanStartInfo => '只会找到从此点开始的币。更早的起点能找到更早的币，但耗时更长。';

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
  String get slSwitchBody => '切换后你会得到新的 Epicbox 地址。';

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
  String get slRelayWarning => '切换后你会得到新的 Epicbox 地址。';

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
  String get deskNetWaitingTorReason => '等待 Tor。“高级”中已开启“仅 Tor”。';

  @override
  String get deskNetOpenAdvanced => '打开“高级”';

  @override
  String get deskNetSendFileHint => '文件传输仍然可用。';

  @override
  String get deskNetRecvWaitTorText => 'Tor 连接后才开始接收。文件传输仍然可用。';

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
  String get txMethodsHeader => '付款方式';

  @override
  String txLinkHttpHint(String port) {
    return '链接 · HTTP 通过网址（http://host:$port）直接向对方钱包付款，并为这部手机提供一个同一 Wi-Fi 网络中的钱包可以付款的地址。双方钱包都必须打开。它在传输途中不加密，无法从互联网或移动数据访问，Tor 开启时也会关闭。会在“发送”和“接收”中加入 链接 · HTTP。';
  }

  @override
  String get txLinkTorHint =>
      '链接 · Tor 通过 onion 地址直接向对方钱包付款，并为这部手机提供一个可收款的 Tor 地址。双方钱包都必须打开。需要 Tor：“隐私与网络”中的 Tor 开关让钱包的连接走 Tor；这个开关只负责开启地址。会在“发送”和“接收”中加入 链接 · Tor。';

  @override
  String get txLinkTorHintNet =>
      '链接 · Tor 通过 onion 地址直接向对方钱包付款，并为这部手机提供一个可收款的 Tor 地址。双方钱包都必须打开。需要 Tor：“网络与隐私”中的 Tor 开关让钱包的连接走 Tor；这个开关只负责开启地址。会在“发送”和“接收”中加入 链接 · Tor。';

  @override
  String get txLinkTorNeedsTor => '需要 Tor。请在“隐私与网络”中开启。';

  @override
  String get txLinkTorNeedsTorNet => '需要 Tor。请在“网络与隐私”中开启。';

  @override
  String get txLastMethodNotice => '至少保留一种付款方式开启。';

  @override
  String get txEpicboxHint =>
      'Epicbox 通过服务器付款，所以对方的钱包不必打开。关闭后，钱包不连接任何服务器：没有 Epicbox 付款或账单。其他方式仍可使用。';

  @override
  String get txFileHint =>
      '“文件传输”生成一个交易文件，你用任何方式（聊天消息、U 盘、数据线）交给对方，对方再回传一个。两个钱包之间不需要连接。会在“发送”和“接收”中加入“文件传输”。';

  @override
  String get txStartHeader => '默认方式';

  @override
  String get txDefaultsHeader => '发送默认设置';

  @override
  String get outputsDefaultsMoved => '发送默认设置已移到“设置 › 交易”';

  @override
  String get advNodeFailover => '节点故障切换';

  @override
  String get advNodeFailoverHint => '当你的节点不再响应时，钱包在本次会话中改用列表里下一个可用的节点。';

  @override
  String get advBalanceHeader => '余额';

  @override
  String get advConfirmations => '确认数';

  @override
  String advConfirmationsHint(int byDefault, int min, int max) {
    return '收到的付款要等待多少个区块，其输出才能花费。默认 $byDefault，可设为 $min 到 $max。';
  }

  @override
  String get advConfirmationsDefault => '默认';

  @override
  String advConfirmationsReset(int count) {
    return '恢复为 $count';
  }

  @override
  String get advConfirmationsFewer => '减少确认数';

  @override
  String get advConfirmationsMore => '增加确认数';

  @override
  String advConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个确认',
    );
    return '$_temp0';
  }

  @override
  String get advConfirmationsLowNote => '确认数越少越快，但越不安全。';

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
  String get netOfflineNoPeers => '你的节点没有对等节点：付款会留在它的交易池里，直到它重新连接。';

  @override
  String get netOfflineNodeHint => '使用节点读取链并广播。为了最大限度的隐私，请使用本地节点。';

  @override
  String get netOfflineNodeLine => '使用节点';

  @override
  String get netBlockEpicboxOff => 'Epicbox 已在 设置 › 交易 中关闭。';

  @override
  String netBlockMethodOff(String method) {
    return '$method 已在设置 › 交易中关闭。';
  }

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
  String sendContactOnlyEpicbox(String name) {
    return '$name 只有 Epicbox 地址。';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name 只有 $method 的地址。';
  }

  @override
  String get receiveEpicboxOffText => '付款会在 Epicbox 服务器上等待，直到 Epicbox 再次开启。';

  @override
  String get receiveNoMethods => '没有开启任何收款方式';

  @override
  String get receiveNoMethodsBody => '请在 设置 › 交易 中开启一种。';

  @override
  String get receiveNoMethodsButton => '打开设置';

  @override
  String get deskNetOfflineNoPeers => '你的节点没有对等节点：付款会留在它的交易池里，直到它重新连接。';

  @override
  String get deskOutDefaultsMoved => '发送的“策略”和“拆分找零”在“设置 › 支付”中设置。';

  @override
  String get deskOutDefaultsOpen => '打开“支付”';

  @override
  String get deskSetFrameTransactions => '交易';

  @override
  String get deskSetTxMethods => '方式';

  @override
  String get deskSetTxEpicboxHint =>
      '通过 Epicbox 服务器付款和收款。大多数付款都走这条路。关闭后，钱包不连接任何 Epicbox 服务器：没有 Epicbox 付款或账单。其他方式仍可使用。所有钱包。';

  @override
  String deskSetTxDirectHint(String port) {
    return '通过网址（http://host:$port）在钱包之间直接付款和收款，中间没有服务器。仅在双方钱包都打开时有效；Tor 开启时关闭。会在“发送”中加入 链接 · HTTP，并在“接收”中加入它的地址。所有钱包。';
  }

  @override
  String get deskSetTxFileHint =>
      '通过传递交易文件付款和收款，无需网络。会在“发送”中加入“文件传输”，并在“接收”中加入文件步骤。所有钱包。';

  @override
  String get deskSetTxStart => '默认方式';

  @override
  String get deskSetTxStartHint => '“发送”页面打开时使用的方式。单笔付款时，仍可在“发送”页面更改。所有钱包。';

  @override
  String get deskSendMethodHeader => '付款方式';

  @override
  String get sendRequestTitle => '账单';

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
  String get payeeNameLabel => '收款方提供的名称';

  @override
  String get payeeNoteLabel => '收款方的留言';

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
  String get linkWaitingPairingNotice => '收到配对链接';

  @override
  String get linkWaitingNotice => '收到付款链接';

  @override
  String get linkFinishCurrentFirst => '请先完成当前付款。';

  @override
  String get deskSendToQrPayment => '这是二维码付款码，请用手机上的 BT Wallet 扫描。';

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
  String get deskRecvTorOffTitle => 'Link · Tor 需要 Tor。';

  @override
  String get deskRecvTorOffText =>
      'Tor 开启时，Tor 地址才可用。Tor 是设置 › 隐私中的开关，它让钱包的连接走 Tor。';

  @override
  String get deskSetupSaveFailedTitle => '设置未保存';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason。请再次保存，或跳过以保留目前已保存的设置。';
  }

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
  String get deskTxNowSenderPosted => '发送方称已广播这笔付款。网络确认后，付款即完成。';

  @override
  String get deskImpWrongTypePasted => '粘贴的文本不是交易。请粘贴发送方提供的完整文本，或选择其文件。';

  @override
  String get pairTitle => '配对';

  @override
  String pairWithName(String name) {
    return '与 $name 配对';
  }

  @override
  String get pairInPerson => '当面';

  @override
  String get pairInPersonHint => '出示你的码并扫描对方的码';

  @override
  String get pairOfflineHint => '你已离线。邀请和回复需手动传递。';

  @override
  String get pairEnterHint => '粘贴邀请链接，或输入收到的词';

  @override
  String get pairNotPaired => '未配对';

  @override
  String get pairNotPairedHint => '配对后可密封交易文件并允许账单。';

  @override
  String get pairInPersonTitle => '当面配对';

  @override
  String get pairShowMyCode => '显示我的邀请';

  @override
  String get pairScanTheirs => '扫描对方的码';

  @override
  String get pairShowCodeCaption => '让对方扫描此码，然后扫描对方的码。';

  @override
  String get pairScanCaption => '双方都要扫描。两个码都读取后会打开词语核对。';

  @override
  String get pairScanPrompt => '扫描对方的二维码';

  @override
  String get pairSeenAs => '对方看到你的名字';

  @override
  String get pairUseWords => '改用配对词';

  @override
  String get pairCameraDeniedTitle => '未允许使用相机';

  @override
  String get pairCameraDeniedBody => '允许使用相机扫描，或粘贴邀请。';

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
  String get pairWordsNeedEpicbox => '口头邀请需要 Epicbox，因此现在不可用。';

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
  String get pairCardCopy => '复制我的配对链接';

  @override
  String get pairCardHint => '当面配对且没有摄像头：双方钱包各自在上方粘贴对方的配对链接。';

  @override
  String pairCardBackTitle(String name) {
    return '现在把你的码交给 $name';
  }

  @override
  String pairCardBackBody(String name) {
    return '在 $name 的钱包中“输入链接或词”处粘贴此链接。然后一起验证。';
  }

  @override
  String get pairEnterDesktopPlaceholder => '粘贴邀请链接，或输入五个词';

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
  String get contactsPairHint => '与另一个钱包配对，即可密封两者之间的交易文件和账单。';

  @override
  String get contactsPairLearn => '如何运作';

  @override
  String get contactsPairTooltip => '与另一个钱包配对';

  @override
  String get pairBadgePending => '配对中…';

  @override
  String get pairBadgePendingTip => '邀请已发送或已回复，尚未完成。';

  @override
  String get pairWaysLead => '只需配对一次。之后两个钱包之间的交易文件和账单都会被密封。';

  @override
  String get pairWayWords => '配对词';

  @override
  String get pairWayAutomatic => '口头';

  @override
  String get pairWayWordsHint => '把五个配对词念给对方。两个钱包都需在线。';

  @override
  String get pairWayWordsInfo =>
      '两个钱包都需在线。你的钱包把邀请留在连接服务器上；对方的钱包通过五个词找到它。之后一起验证。';

  @override
  String get pairWayMessage => '通过消息邀请';

  @override
  String get pairWayMessageHint => '在任意聊天中发送链接。';

  @override
  String get pairWayMessageInfo =>
      '三条消息：你的邀请、对方的回复、你的完成链接。每条到达后复制它；你回来时钱包会在剪贴板中找到。服务器被屏蔽或钱包离线时也可用。';

  @override
  String get pairWayInPersonDesk => '对方的手机扫描你的码';

  @override
  String get pairGotInvite => '收到了配对词或链接？';

  @override
  String get pairGotInviteHint => '输入配对词，或粘贴对方发来的消息。';

  @override
  String get pairHowItWorks => '配对如何运作';

  @override
  String get pairWordsBothOnline => '两个钱包都需在线，其余会自动完成。';

  @override
  String get pairWordsWaiting => '正在等待对方的钱包…';

  @override
  String get pairUseMessageInstead => '改为通过消息邀请';

  @override
  String get pairAskForMessage => '请对方改为通过消息邀请你。';

  @override
  String get pairStepInvite => '邀请';

  @override
  String get pairStepReply => '回复';

  @override
  String get pairStepFinish => '完成链接';

  @override
  String get pairStepWords => '核对词语';

  @override
  String pairStepOf(int n, String step) {
    return '第 $n 步，共 4 步：$step';
  }

  @override
  String get pairMessageLead => '在任意聊天中发送邀请。回复会以同样方式回来。';

  @override
  String pairInviteMessage(String link) {
    return '在 BT Wallet 中与我配对：$link';
  }

  @override
  String pairReplyMessage(String link) {
    return '我对 BT Wallet 配对的回复：$link';
  }

  @override
  String pairFinishMessage(String link) {
    return '完成我们的 BT Wallet 配对：$link';
  }

  @override
  String pairFinishLinkMessage(String link) {
    return '完成 BT Wallet 配对：$link';
  }

  @override
  String get pairCopyMessage => '复制消息';

  @override
  String get pairMessageCopied => '已复制。粘贴到聊天中即可。';

  @override
  String get pairAwaitReplyTitle => '正在等待回复';

  @override
  String get pairAwaitReplyBody => '回复到达聊天后，复制它再回来，钱包会自动找到。';

  @override
  String get pairByItself => '若双方都能连上 Epicbox 服务器，此步骤也会自动完成。';

  @override
  String get pairPasteReply => '粘贴回复';

  @override
  String get pairReplyTitle => '发送你的回复';

  @override
  String pairReplyLead(String name) {
    return '在同一聊天中把它发回给 $name。';
  }

  @override
  String get pairShareReply => '分享回复';

  @override
  String get pairAwaitFinishTitle => '正在等待完成链接';

  @override
  String pairAwaitFinishBody(String name) {
    return '$name 的钱包会根据你的回复生成它。收到后复制并回来。';
  }

  @override
  String get pairPasteFinish => '粘贴完成链接';

  @override
  String get pairPasteLink => '粘贴链接';

  @override
  String get pairFinishTitle => '发送完成链接';

  @override
  String pairFinishLead(String name) {
    return '还差一条消息：$name 的钱包需要它来显示词语。';
  }

  @override
  String get pairShareFinish => '分享完成链接';

  @override
  String get pairFinishThenCheck => '然后一起核对词语。';

  @override
  String pairAlreadyPaired(String name) {
    return '已与 $name 配对。';
  }

  @override
  String get pairReplyNotHere => '此回复对应的是另一个钱包的邀请。';

  @override
  String get helpPairWaysTitle => '三种配对方式';

  @override
  String get helpPairWaysShort => '两个钱包都在线时用口头方式，或在任意聊天中发消息，或当面配对。';

  @override
  String get helpPairWaysP1 =>
      '**口头。**一个钱包显示五个词，并把密封的邀请留在连接服务器上。另一个钱包输入这些词即可找到它。两个钱包都需在线，并能连上其中一个服务器。';

  @override
  String get helpPairWaysP2 =>
      '**通过消息邀请。**在任意聊天中发三条消息：邀请、回复、完成链接。无需服务器，因此网络屏蔽 Epicbox 时也可用。每条消息到达后复制它；你回来时钱包会提示使用。';

  @override
  String get helpPairWaysP3 => '**当面。**两部手机互相扫描对方的码。不使用网络。';

  @override
  String get helpPairWaysP4 => '无论哪种方式，最后都要一起验证：比较四张图片和名称。它们表明消息在途中没有被人改动。';

  @override
  String get helpPairClipP =>
      '钱包仅在配对开启时、仅在回到前台或打开配对界面时读取剪贴板，每个链接只提示一次。它从不保存或记录读取的内容。';

  @override
  String get pairShareWarning => '在邀请过期前，任何拥有此邀请的人都能以你的身份配对。只发送给你要配对的人，然后一起验证。';

  @override
  String get pairShareInvite => '分享邀请';

  @override
  String get pairCopyInvite => '复制邀请';

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
    return '来自 $name 的配对请求';
  }

  @override
  String get pairVerifiedService => '已验证的 BT Labs 服务';

  @override
  String pairCallsThemselves(String name) {
    return '自称“$name”';
  }

  @override
  String pairIncomingBody(String name) {
    return '配对后，你与 $name 之间的交易文件和账单都会被密封。接下来你们一起验证。';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return '允许 $name 请求付款';
  }

  @override
  String get pairIncomingAllowHintDesktop => '验证后开启。没有钱包密码不会付款。';

  @override
  String get pairIncomingAllowHint => '验证后开启。没有你的 PIN 不会付款。';

  @override
  String get pairNotNow => '暂不';

  @override
  String get pairWaitingBody => '对方的钱包打开时会回复。你可以关闭此页面；配对完成后会出现验证。';

  @override
  String get pairSendByHand => '手动发送';

  @override
  String get pairReplyLateTitle => '还没配对？';

  @override
  String pairReplyLateBody(String name) {
    return '你的回复已通过 Epicbox 服务器发给 $name。若对方的钱包已关闭或连不上服务器，请改在聊天中发送回复。';
  }

  @override
  String get pairRelayUnreachableTitle => '无法连接服务器';

  @override
  String get pairRelayUnreachableBody => '手动发送你的回复？';

  @override
  String get pairRelayUnreachableTor => '无法通过 Tor 连接服务器。手动发送你的回复？';

  @override
  String get pairNoRelay => '无法连接任何连接服务器。请改用邀请链接配对。';

  @override
  String get pairRelaysBlocked => '此网络拦截了连接服务器。可能是网络过滤所致。请改用邀请链接配对。';

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
    return '请索取新的邀请。';
  }

  @override
  String get pairUsedTitle => '此邀请已被使用';

  @override
  String get pairUsedBody => '请索取新的邀请。';

  @override
  String pairCancelledTitle(String name) {
    return '$name 取消了这次配对';
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
  String pairWaitingFinish(String name) {
    return '正在等待 $name 完成配对…';
  }

  @override
  String get pairNotCompletedTitle => '未完成';

  @override
  String pairNotCompletedBody(String name) {
    return '$name 的钱包未能及时完成配对。未保存任何内容。请重试。';
  }

  @override
  String get pairLateCheck => '正在检查迟到的回复…';

  @override
  String noticeUnpaired(String name) {
    return '$name 已移除配对。';
  }

  @override
  String trustRemovedBy(String name) {
    return '已被 $name 移除';
  }

  @override
  String get trustRemovedShort => '已移除';

  @override
  String get pairChangedTitle => '此邀请在途中被更改';

  @override
  String pairChangedBody(String name) {
    return '未保存任何内容。请重新配对，当面或使用 $name 的新邀请。';
  }

  @override
  String get pairNewerTitle => '更新 BT Wallet 以打开此内容';

  @override
  String get pairNewerInviteBody => '此邀请由更新版本的钱包生成。';

  @override
  String get pairNewerFileBody => '此文件由更新版本的钱包密封。';

  @override
  String get pairCheckForUpdates => '检查更新';

  @override
  String pairSecondReplyTitle(String name) {
    return '还有其他人回复了你的邀请';
  }

  @override
  String get pairAnsweredSameInvite => '回复了同一邀请 · 未保存';

  @override
  String get sasTitle => '核对词语';

  @override
  String sasLead(String name) {
    return '$name 的钱包显示同样的四个词语。请核对。';
  }

  @override
  String sasLeadExchange(String name) {
    return '$name 页面显示相同的四个词。比较后在双方确认。';
  }

  @override
  String sasLeadRecheck(String name) {
    return '$name 的钱包在“$name › 核对词语”中显示这些词。请通过电话或当面比较。';
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
    return '从现在起，与 $name 的交易文件和账单都会被密封。';
  }

  @override
  String get sasNoMatchTitle => '词语不一致';

  @override
  String get sasNoMatchBody => '配对将在双方结束，通过它发送的内容都不会完成。请用新的邀请重新配对。';

  @override
  String get sasStopPairing => '停止配对';

  @override
  String sasSkippedTitle(String name) {
    return '已与 $name 配对';
  }

  @override
  String sasSkippedBody(String name) {
    return '与 $name 的交易文件已密封。方便时请在 $name 的联系人页面核对词语；在此之前账单会等待。';
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
    return '验证于 $date';
  }

  @override
  String get contactCheckAgain => '再次核对';

  @override
  String get contactCheckWordsAgain => '再次验证';

  @override
  String get contactSealPayments => '密封付款';

  @override
  String contactSealInfo(String name) {
    return '交易文件已加密（封存），只有 $name 能读取。';
  }

  @override
  String contactSealInfoMore(String name) {
    return '关闭后，发给 $name 的交易文件为明文：拿到文件的任何人都能读取。仅当 $name 的钱包无法打开密封文件时才关闭。';
  }

  @override
  String get contactAllowInvoices => '允许账单';

  @override
  String contactAllowInfoDesktop(String name) {
    return '$name 的钱包可以向你发送账单。每个账单都在“账单”中等待你的批准和钱包密码。不会自动付款。';
  }

  @override
  String contactAllowInfo(String name) {
    return '$name 的钱包可以向你发送账单。每个账单都在“账单”中等待你的批准和 PIN。不会自动付款。';
  }

  @override
  String get contactAllowInfoMore => '只能允许已验证的联系人：验证可排除被调换的邀请。';

  @override
  String get contactCheckWordsFirst => '请先验证';

  @override
  String get contactPausedUntilChecked => '验证前已暂停';

  @override
  String contactDeliveredVia(String relay) {
    return '经 $relay 投递';
  }

  @override
  String get contactDomain => '域名';

  @override
  String get contactDomainVerified => '已验证';

  @override
  String get contactDomainNotVerified => '尚未验证';

  @override
  String get contactDomainRefused => '已拒绝';

  @override
  String relayMoveTitle(String name) {
    return '$name 已切换到新的中继';
  }

  @override
  String relayMoveBody(String name, String relay) {
    return '$name 请你今后经 $relay 发送。如果拒绝，一切不变，$name 也不会收到通知。';
  }

  @override
  String relayMoveAddsServer(String relay) {
    return '接受后，$relay 也会加入你的 Epicbox 服务器列表。';
  }

  @override
  String get relayMoveAccept => '接受';

  @override
  String get relayMoveRefuse => '拒绝';

  @override
  String contactMoveAsked(String relay) {
    return '请求切换到 $relay';
  }

  @override
  String contactMoveRefused(String relay) {
    return '你拒绝了切换到 $relay。';
  }

  @override
  String contactMoveNotPublic(String relay) {
    return '请求切换到 $relay。未切换：不是公共中继。';
  }

  @override
  String contactMovedOn(String date) {
    return '$date 切换到此处';
  }

  @override
  String sendViaMailboxMovedHint(String relay, String date) {
    return '已密封。经 $relay 投递，$date 切换到此处';
  }

  @override
  String contactRelayDownTitle(String name) {
    return '$name 的服务器没有响应';
  }

  @override
  String get contactRelayDownBody => '正在重试。账单和付款会等待其响应。';

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
      '这可能表示对方现在使用了另一个钱包，或有其他人在使用这个名字。请再次验证该联系人。';

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
    return '口头邀请 · $time 后过期';
  }

  @override
  String get pendingExpired => '已过期';

  @override
  String get pendingInviteAgain => '再次邀请';

  @override
  String get pendingWaitingConfirm => '等待对方确认';

  @override
  String get pendingPairedCheck => '已配对 · 请验证';

  @override
  String get pendingEmpty => '没有等待中的邀请。邀请会显示在这里，直到对方的钱包回复。';

  @override
  String get pendingShareAgain => '再次分享';

  @override
  String get pendingShowWords => '显示邀请';

  @override
  String get invSetTitle => '账单';

  @override
  String get invSetLead => '你允许的已配对联系人可以向你发送账单。每个账单都在“账单”中等待你的 PIN。';

  @override
  String get invSetPaired => '已配对联系人';

  @override
  String get invSetAllowed => '已允许';

  @override
  String get invSetOff => '关闭';

  @override
  String get invSetPairShop => '与商店或交易所配对';

  @override
  String get invSetEmpty => '还没有已配对的联系人。与商店、交易所或个人配对，验证，然后在这里允许其账单。';

  @override
  String get invSetPausedBody => '账单在服务器上等待，Epicbox 重新开启后送达。';

  @override
  String invSetSwitchedOff(String name) {
    return '来自 $name 的账单已关闭。';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已拒绝 $count 个未处理的账单。',
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
  String get reqTitle => '查看账单';

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
  String get reqPaidWaitingBodyPerson => '你的部分已完成。对方的钱包会完成并发布；此项会自动关闭。';

  @override
  String get reqPaidWaitingBody => '你的部分已完成。对方会完成并发布；此项会自动关闭。';

  @override
  String get reqTlPaid => '已付款';

  @override
  String get reqTlDelivered => '已通过 Epicbox 送达';

  @override
  String get reqTlAnswerDelivered => '回复已通过 Epicbox 送达';

  @override
  String reqTlPosted(String name) {
    return '已由 $name 发布';
  }

  @override
  String get reqTlConfirming => '确认中';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n / $total 次确认';
  }

  @override
  String get reqTlConfirmed => '已确认';

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
  String get reqUnreachableBody => '如果未发布，这些币会解锁。投递会持续重试。';

  @override
  String get reqRelayRetrying => '服务器无响应 · 重试中';

  @override
  String reqWithdrewTitle(String name) {
    return '$name 撤回了账单';
  }

  @override
  String get reqWithdrewBody => '你的资金已解锁。未付款。';

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name 在 10 分钟内发送了 $count 个 $amount EPIC 的账单。全部付款？',
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
  String get reqReceivedWaitingBody => '无需操作。发送方会发布；之后会有确认。';

  @override
  String get reqNewTitle => '新建账单';

  @override
  String get reqNewLead => '请已配对的联系人付款，或将账单保存为文件发给任何人。';

  @override
  String get reqNewLeadContacts => '请已配对的联系人付款。';

  @override
  String get reqNewTo => '收款对象';

  @override
  String get reqNewToHintContacts => '钱包可账单的已配对联系人。';

  @override
  String get reqNoPayersContacts => '还没有可账单的已配对联系人。请配对并验证。';

  @override
  String get reqNewToHint => '钱包可账单的已配对联系人。其他人：将账单保存为文件。';

  @override
  String get reqNewSend => '发送账单';

  @override
  String sendViaMailbox(String name) {
    return '通过 $name 的 Epicbox 服务器发送';
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
    return '$name 已回复。请一起验证。';
  }

  @override
  String noticePairingConfirmed(String name) {
    return '已与 $name 配对。请一起验证。';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name 请求 $amount EPIC。';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return '已收到来自 $name 的 $amount EPIC。';
  }

  @override
  String noticeKeysChanged(String name) {
    return '$name 的密钥已更改。请再次验证。';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return '$name 已用新密钥配对。无法核对旧密钥：每天只能核对一次，今天已核对过。';
  }

  @override
  String noticeRelayDown(String name) {
    return '$name 的 Epicbox 服务器没有响应。';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name 撤回了账单。资金已解锁。';
  }

  @override
  String get restoreUseContactsTitle => '在此设备上使用你的联系人？';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此文件中有 $count 个配对曾在另一台设备上使用。另一台设备应停止使用它们。',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => '在此使用';

  @override
  String get pairInvalidLink => '这不是配对邀请。';

  @override
  String get pairInvalidBody => '请检查是否完整复制了邀请，或索取新的邀请。';

  @override
  String get pairWrongNetworkBody => '此邀请属于另一个网络。';

  @override
  String get pairOwnCode => '这是你自己的码';

  @override
  String get pairOwnCodeBody => '请扫描另一部手机上的码。';

  @override
  String get pairUnnamedInvite => '公开邀请';

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
  String get invSetLeadDesktop => '你允许的已配对联系人可以向此钱包发送账单。每个账单都在“账单”中等待钱包密码。';

  @override
  String get invSetRowAllowed => '已验证 · 已允许';

  @override
  String get invSetRowOff => '已验证 · 已关闭';

  @override
  String get invSetRowCheckFirst => '已配对，未验证 · 请先验证';

  @override
  String invSetAllowFor(String name) {
    return '允许来自 $name 的账单';
  }

  @override
  String get reqNoPayers => '还没有可账单的已配对联系人。请配对并验证，或将账单保存为文件。';

  @override
  String get reqPickContact => '选择联系人';

  @override
  String get reqFileSaved => '账单已保存为文件';

  @override
  String reqSent(String name) {
    return '账单已发送给 $name';
  }

  @override
  String get reqFileTitle => '账单';

  @override
  String noticeOutboxStuck(String name) {
    return '暂时无法联系 $name。正在重试。';
  }

  @override
  String noticeTooMany(String name) {
    return '$name 发送的账单过多。';
  }

  @override
  String get noticeOpen => '打开';

  @override
  String get noticeCheckWords => '验证';

  @override
  String get noticeView => '查看';

  @override
  String pairSaveContactTitle(String name) {
    return '将 $name 保存到联系人？';
  }

  @override
  String get pairSaveNewContact => '保存为新联系人';

  @override
  String pairOtherAddressTitle(String name) {
    return '未添加到联系人 $name';
  }

  @override
  String pairOtherAddressBody(String name) {
    return '$name 已有一个此配对无法确认的 Epicbox 地址。';
  }

  @override
  String get pairOtherAddress => '此联系人已有一个此配对无法确认的 Epicbox 地址。';

  @override
  String pairAddToNamed(String name) {
    return '添加到联系人 $name';
  }

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
  String get helpPairingSection => '配对';

  @override
  String get helpPairingLede => '配对一次；与该联系人的交易文件和账单都会被密封。';

  @override
  String get helpPairWhatTitle => '什么是配对';

  @override
  String get helpPairWhatShort => '与对方配对一次；之后两个钱包之间的交易文件和账单都会被密封。';

  @override
  String get helpPairWhatP1 =>
      '配对将两个钱包连接一次：向你曾通过 Epicbox 付款的联系人发送请求，或使用你的邀请（扫描二维码或打开链接）。每个钱包为这一个联系人保留一把专用密钥；不与任何其他人共享。';

  @override
  String get helpPairWhatP2 =>
      '配对后，发给该联系人的交易文件是**密封**的：只有对方的钱包能打开，途中也无法被更改或伪造。人与人之间通过 Epicbox 的付款照常进行。';

  @override
  String get helpPairWhatStep1 => '打开[[联系人|Contacts]]，选择**配对**。';

  @override
  String get helpPairWhatStep2 => '与联系人配对，或显示你的邀请让对方扫描。';

  @override
  String get helpPairWhatStep3 => '一起核对词语（请求之后无需核对），然后点 **一致**。';

  @override
  String get helpPairWhatP3 =>
      '配对需要双方都使用 BT Wallet。未配对的联系人仍会收到普通交易文件和 Epicbox 付款。';

  @override
  String get helpPairWhyTitle => '为什么要验证';

  @override
  String get helpPairWhyShort => '验证证明配对到达了正确的钱包，而不是中间的某个人。';

  @override
  String get helpPairWhyP1 =>
      '配对后，两个钱包都会显示相同的四个图片和名称。它们来自两个钱包的密钥，因此在途中被更改的配对会在两个屏幕上显示不同的词。';

  @override
  String get helpPairWhyP2 =>
      '通过电话或当面比较，然后点按**一致**。联系人变为**已验证**。**暂时跳过**会保留为**已配对，未验证**：交易文件仍会密封，但在核对词语之前，该联系人不能发送账单。';

  @override
  String get helpPairWhyP3 => '如果词语不同，点按**不一致**。此端会丢弃该配对。请重新配对，当面或使用新的邀请。';

  @override
  String get helpPairWhyP4 => '这些词语的名称在所有语言中都保持英文，因此使用不同语言钱包的两个人也能核对。';

  @override
  String get helpPairWordsTitle => '口头邀请';

  @override
  String get helpPairWordsShort => '在无法扫描或粘贴时，五个带名称的图片可代替链接。';

  @override
  String get helpPairWordsP1 =>
      '当一个钱包没有相机，或邀请无法以链接发送时，发出邀请的钱包会显示五个配对词。对方在**收到了配对词或链接？**中输入它们的名称；输入几个字母后，输入框会补全名称。这些词 10 分钟内有效。';

  @override
  String get helpPairWordsP2 =>
      '这些词只用于找到邀请。拥有它们的人与收到链接的人处境相同，因此之后仍要像平常一样一起核对四个词。';

  @override
  String get helpPairWordsP3 => '口头邀请需要 Epicbox。Epicbox 关闭期间，请改为发送邀请链接。';

  @override
  String get helpPairInvTitle => '来自已配对联系人的账单';

  @override
  String get helpPairInvShortDesktop => '只有你允许的已验证联系人才能账单你付款。每个账单都会等待钱包密码。';

  @override
  String get helpPairInvShort => '只有你允许的已验证联系人才能账单你付款。每个账单都会等待你的 PIN。';

  @override
  String get helpPairInvP1 =>
      '与你配对的商店、交易所或个人在你允许后可以发送账单：在联系人页面或[[设置 › 账单|Settings › Invoices]]中打开**允许账单**。此开关仅对已验证的联系人有效。';

  @override
  String get helpPairInvP2Desktop =>
      '账单会显示在[[账单 › 支付|Invoices › Pay]]中，附有联系人的名字、金额和参考号。在你用钱包密码批准之前不会付款。账单绝不会向你的钱包加钱。';

  @override
  String get helpPairInvP2 =>
      '账单会显示在[[账单 › 支付|Invoices › Pay]]中，附有联系人的名字、金额和参考号。在你用 PIN 批准之前不会付款。账单绝不会向你的钱包加钱。';

  @override
  String get helpPairInvP3 => '关闭开关立即生效：该联系人的新账单会被丢弃，未处理的账单会被拒绝。';

  @override
  String get helpPairInvP4 =>
      '与你配对的交易所通过这种方式处理充值和提现。充值：交易所请求，你批准，交易所发布。提现：交易所发送付款，你的钱包自动回复，交易所发布。';

  @override
  String get helpPairRestoreTitle => '恢复会带来什么';

  @override
  String get helpPairRestoreShort =>
      '有钱包数据文件时，用助记词恢复会带回所有配对；没有它时，重新配对会找到相同的密钥。';

  @override
  String get helpPairRestoreP1 =>
      '有钱包数据文件时，恢复会原样带回所有配对：相同的密钥、相同的“已验证”标记、相同的设置。联系人不会察觉任何变化。';

  @override
  String get helpPairRestoreP2 =>
      '没有该文件时，配对会从此钱包中消失，但密钥不会：它们来自助记词。与保留了配对的联系人重新配对，对方的钱包会找到相同的密钥。它会告诉对方密钥已恢复，联系人也会保留“已验证”标记。在此钱包上，“密封付款”和“允许账单”恢复为默认设置。';

  @override
  String get helpPairRestoreP3 =>
      '只有当恢复短语不同时，联系人才会看到**密钥已更改**。这可能表示一个新钱包，或有其他人在使用这个名字。信任之前请再次核对词语。';

  @override
  String get helpPairRestoreP4 => '一次只在一台设备上使用配对。在第二台设备上导入的钱包数据会先询问，再在那里使用联系人。';

  @override
  String get pairNameForCode => '输入对方会看到的名字，你的码就会显示在这里。';

  @override
  String get deskConPickForPairing => '配对将添加到你选择的联系人。';

  @override
  String txDetailsCancelHold(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '如果发送方到时仍未广播，$minutes 分钟后可以取消。',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsCancelWhileReported => '发送方报告已广播期间，无法取消。';

  @override
  String get txDetailsCancelRefusedOnNetwork => '未取消：网络中已有这笔付款。区块链确认后即完成。';

  @override
  String get contactStar => '加星标';

  @override
  String get contactUnstar => '取消星标';

  @override
  String get contactStarred => '已加星标';

  @override
  String get contactsImport => '导入联系人';

  @override
  String get contactsExport => '导出联系人';

  @override
  String contactsExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已导出 $count 个联系人',
    );
    return '$_temp0';
  }

  @override
  String get contactsExportHolds => '文件包含名称、备注和地址。不含密钥或配对。';

  @override
  String get contactsImportTitle => '导入联系人？';

  @override
  String contactsImportNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个新联系人',
    );
    return '$_temp0';
  }

  @override
  String contactsImportMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '更新 $count 个联系人',
    );
    return '$_temp0';
  }

  @override
  String contactsImportSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已存在',
    );
    return '$_temp0';
  }

  @override
  String contactsImportLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跳过 $count 个：没有本钱包可发送的地址',
    );
    return '$_temp0';
  }

  @override
  String contactsImportOtherNet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跳过 $count 个：其他网络的地址',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportKeeps => '已有信息会保留。';

  @override
  String get contactsImportDo => '导入';

  @override
  String get contactsImportNothing => '没有可导入的内容。';

  @override
  String contactsImported(int added, int same) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 个联系人',
    );
    String _temp1 = intl.Intl.pluralLogic(
      same,
      locale: localeName,
      other: '$same 个已存在',
    );
    return '$_temp0，$_temp1';
  }

  @override
  String contactsImportedAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '已添加 $added 个联系人',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportNotFile => '该文件不是联系人文件。';

  @override
  String get contactsImportDamaged => '无法读取该文件，文件可能已损坏。';

  @override
  String get contactsImportNewer => '该文件由更新版本的 BT Wallet 创建。请更新后再导入。';

  @override
  String get contactsImportEmpty => '该文件中没有联系人。';

  @override
  String get contactsImportAllOtherNet => '这些联系人属于其他网络，此处均无法使用。';

  @override
  String get expPairing => '配对';

  @override
  String get expPairingHint =>
      '与常付款的人配对一次：之后两个钱包之间的交易文件和账单都会被密封，联系人显示为已配对。实验性：仍可能变化。';

  @override
  String get expInvoices => '账单';

  @override
  String get expInvoicesHint => '向已配对的联系人请求付款，并批准已配对联系人发来的账单。需要配对。实验性：仍可能变化。';

  @override
  String get expNeedsPairing => '账单需要配对。';

  @override
  String get expPairingOffTitle => '配对是实验性功能';

  @override
  String get expPairingOffBody => '可在 设置 › 高级 中开启。';

  @override
  String get expInvoicesOffTitle => '账单是实验性功能';

  @override
  String get expInvoicesOffBody => '可在 设置 › 高级 中开启。';

  @override
  String get expOpenAdvanced => '打开高级';

  @override
  String get contactNoAddressPaired => '付款通过配对进行';

  @override
  String get contactSendKeysChanged => '发送前请先验证该联系人。';

  @override
  String contactSendNoSealed(String name) {
    return '$name 的钱包不接受通过配对的付款。请索要地址。';
  }

  @override
  String sendRecipientPairing(String name) {
    return '通过与 $name 的配对';
  }

  @override
  String get sendClearRecipient => '清除收款方';

  @override
  String get sendQueuedEpicboxOff => 'Epicbox 已关闭。付款在此等待，Epicbox 重新开启后发出。';

  @override
  String get sendQueue => '排队付款';

  @override
  String get sendQueuedHeadline => '付款已排队';

  @override
  String sendQueuedBody(String name) {
    return 'Epicbox 重新开启后发出。$name 的回复也经同一途径返回。';
  }

  @override
  String txStatusWaitingFor(String name) {
    return '等待 $name';
  }

  @override
  String txStepSentMailbox(String name) {
    return '已通过 $name 的 Epicbox 服务器发送';
  }

  @override
  String txStepAnswerFrom(String name) {
    return '$name 的回复';
  }

  @override
  String txStepCollecting(String name) {
    return '正在查看 $name 的 Epicbox 服务器';
  }

  @override
  String deskTxStatusWaitingFor(String name) {
    return '等待 $name 签名';
  }

  @override
  String deskSendContactNoLink(String name) {
    return '$name 没有 Link 地址。';
  }

  @override
  String get reqToFile => '保存为文件发给任何人';

  @override
  String reqFileSummary(String amount) {
    return '任何打开此文件的人都可以支付 $amount。回复会以文件形式返回。';
  }

  @override
  String get reqSaveFile => '保存为文件';

  @override
  String get reqFileLead => '把此文件发给应付款的人。对方钱包会回复一个文件；在这里打开它即可完成。';

  @override
  String get reqByFile => '通过文件';

  @override
  String get reqToAnyone => '持有此文件的任何人';

  @override
  String get reqFileWaitingCard => '正在等待回复文件。可从“收款”打开，或直接点按该文件。';

  @override
  String get reqFromFileTitle => '来自文件的账单';

  @override
  String get reqFromFileWarn => '无法得知此账单是谁发出的。只有在你预期收到来自熟人的账单时才付款。';

  @override
  String get reqFileMessageLabel => '文件中的留言';

  @override
  String get reqApproveSaveAnswer => '批准并保存回复';

  @override
  String get reqNotNow => '暂不';

  @override
  String get reqAnswerTitle => '回复已保存';

  @override
  String get reqAnswerLead => '把此文件发回给请求方。对方会完成付款并广播。';

  @override
  String get reqFileAlreadyPaid => '此账单已付款。';

  @override
  String get reqFileEnded => '此账单已结束。';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return '对你 $amount 账单的回复。';
  }

  @override
  String get reqAnswerUnknown => '这是对本钱包已不存在的账单的回复。';

  @override
  String get deskInvIssuerAnother => '再发一个账单';

  @override
  String get deskImpOpenAnother => '打开另一个文件';

  @override
  String get deskInvIssuerToAnyone => '开给持有此文件的任何人的账单';

  @override
  String deskOnbImportRelayTitle(String name) {
    return '$name 的 Epicbox 服务器';
  }

  @override
  String deskOnbImportRelayLead(String old) {
    return '旧应用通过 $old 接收。';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return '保留 $old';
  }

  @override
  String get deskOnbImportRelayKeepHint => '地址不变；该服务器加入 Epicbox 列表。';

  @override
  String deskOnbImportRelayApp(String current) {
    return '使用 $current';
  }

  @override
  String get deskOnbImportRelayAppHint => '新地址：发往旧地址的付款不会到达。';

  @override
  String get deskOnbImportUnlockOld => '用旧密码解锁。';

  @override
  String get deskOnbImportUnlockNew => '用在此设置的新密码解锁。';

  @override
  String get deskOnbWelcomeOtherApps => '来自 Stack Wallet 或 Epic Pay：请用助记词恢复。';

  @override
  String get deskOnbImportCloseFirstWindows =>
      '导入前请先关闭旧版 Epic Wallet。在 Windows 上无法检查它是否仍在运行。';

  @override
  String get deskSetRecvEpicboxOwnHint =>
      '此钱包有自己的 Epicbox 服务器，保留自旧应用。此处的更改只适用于此钱包。';

  @override
  String get deskErrRestoreScanRequired => '恢复尚未完成。区块链扫描结束后即可接收和发送。';

  @override
  String get deskSetupSkip => '跳过设置';

  @override
  String get deskOvRestoreTitle => '恢复尚未完成';

  @override
  String get deskOvRestoreRunning =>
      '正在链上查找此钱包的资金。已收到的 EPIC 会随查找逐步显示；扫描完成后即可接收和发送。';

  @override
  String deskOvRestoreAfterHeight(String height) {
    return '区块 $height 之后的资金已找到。更早的区块仍在检查中，完成后即可接收和发送。';
  }

  @override
  String get deskOvRestoreWaiting => '扫描正在等待网络。';

  @override
  String get deskOvRestoreFailed => '扫描在结束前中断。扫描完成前无法接收和发送。';

  @override
  String get deskOvRestoreProgress => '恢复扫描进度';

  @override
  String get deskSetRescanRestoreRunning => '恢复扫描正在进行。扫描完成后才能重新核对余额。';

  @override
  String get deskSetRescanStartHeading => '从哪里开始';

  @override
  String get deskOnbForgotLink => '忘记密码？';

  @override
  String get deskOnbForgotTitle => '设置新密码';

  @override
  String deskOnbForgotLead(String name) {
    return '用 $name 的助记词替换其密码。交易记录、备注和标签保留，无需扫描。';
  }

  @override
  String get deskOnbForgotPasswordLead => '助记词核对无误。请设置在这台电脑上解锁此钱包的新密码。';

  @override
  String get deskOnbForgotSet => '设置密码';

  @override
  String deskOnbForgotOtherWallet(String name) {
    return '此助记词属于另一个钱包，不属于 $name。没有做任何更改。';
  }

  @override
  String get deskOnbSameNewPassword => '设置新密码';

  @override
  String get deskSetupSkipKeeps => '跳过将保留当前的节点和 Epicbox 设置。';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return '无法将设置标记为已完成：$reason。下次启动时可能会再次显示；“跳过设置”可直接离开。';
  }

  @override
  String get deskOvRestoredImportTitle => '钱包已恢复';

  @override
  String get deskOvRestoredImportBody => '余额已找回。此钱包的钱包数据文件可找回记录、联系人、账单和设置。';

  @override
  String get deskOvRestoredImportButton => '导入钱包数据';

  @override
  String get deskOvRestoredImportLater => '以后可在“设置 › 钱包 › 备份”中导入。';

  @override
  String get deskOnbForgotNoCheck => '此钱包的文件无法确认该助记词，因此密码保持不变。';

  @override
  String deskOnbForgotRestoreHint(String name) {
    return '请改为用助记词恢复：$name 会从列表中移除，其文件仍保留在这台电脑上。';
  }

  @override
  String get deskOnbForgotRestoreInstead => '用助记词恢复';

  @override
  String get qrShowTitleRequest => '账单';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount，来自你身边的手机';
  }

  @override
  String get qrHiddenBodyRequest => '谁扫到，谁就能支付这个账单。只给付款的人看。';

  @override
  String get qrStatusRequestHidden => '把它给付款的人看。';

  @override
  String get qrStatusRequestShowing => '等待对方扫描并批准。然后扫描对方的回复。';

  @override
  String qrSemanticsRequest(String state) {
    return '账单二维码，$state';
  }

  @override
  String qrShowSubPaid(String amount) {
    return '发给请求 $amount 的一方';
  }

  @override
  String get qrHiddenBodyPaid => '只给发出付款请求的手机看。只有那个钱包能使用它。';

  @override
  String get qrStatusPaidHidden => '把它给请求方看。';

  @override
  String get qrStatusPaidShowing => '等待对方扫描并广播。';

  @override
  String get qrStatusPaid => '已付款。';

  @override
  String get reqToQr => '显示为二维码给身边的手机';

  @override
  String reqQrSummary(String amount) {
    return '谁扫到二维码，谁就能支付 $amount。在这里扫描对方的回复即可完成。账单在 24 小时后过期。';
  }

  @override
  String get reqShowQr => '显示为二维码';

  @override
  String get receiveQrRequest => '请求金额';

  @override
  String get reqQrPaidTitle => '已付款';

  @override
  String reqQrPaidHeadline(String amount) {
    return '$amount 已付款并广播到网络。';
  }

  @override
  String get reqQrNew => '新建账单';

  @override
  String get reqQrAlreadyPaid =>
      '此账单已付款。这部手机没有被扣款：它的付款会保持锁定，直到对方在“活动”中取消，或一天后过期。';

  @override
  String get reqFromQrTitle => '来自二维码的账单';

  @override
  String get reqFromQrWarn =>
      '不是来自已配对的联系人。二维码中没有任何信息说明是谁发出的：只向你面前的人或店铺付款，并核对金额。';

  @override
  String get reqQrMessageLabel => '二维码中的留言';

  @override
  String get reqApproveShowAnswer => '批准并显示回复';

  @override
  String get reqQrAnswerTitle => '已批准';

  @override
  String get reqQrAnswerLead => '请求方扫描回复后广播付款。在此之前，它会在交易记录中显示为“等待接收方”。';

  @override
  String get reqExpired => '此账单已过期。请对方重新发起。未付款。';

  @override
  String get reqOtherChain => '此账单属于另一个 Epic 网络，或者它的时限与本网络不符。未付款。';

  @override
  String get reqQrOpenNote => '在 账单 › 已发送 中保留 24 小时，之后过期。';

  @override
  String get reqQrWrongReply => '此回复属于另一个账单。请扫描针对这个账单的回复。';

  @override
  String get backupFileHolds => '包含此钱包截至目前的交易记录、联系人、账单和设置。';

  @override
  String get backupFileRestoreOrder => '恢复时：先输入助记词，再导入此文件。';

  @override
  String get backupImportLead => '找回这个钱包的交易记录、联系人、账单和设置。请先用助记词恢复钱包。';

  @override
  String backupRestoredSummary(String items) {
    return '已导入：$items。';
  }

  @override
  String get backupListSeparator => '、';

  @override
  String get backupListLastSeparator => '和';

  @override
  String backupRestoredPayments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 笔付款',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredNotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 条备注',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredLabels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个标签',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredContacts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个联系人',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredStars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个星标联系人',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredPairings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个配对',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredInvoices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张账单',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoredSettings => '设置';

  @override
  String get backupRestoredWalletName => '钱包名称';

  @override
  String backupRestoredAlreadyHere(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 条记录已存在。',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsTitle => '使用此文件中的设置？';

  @override
  String backupSettingsBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '这里有 $n 项设置与文件不同。',
    );
    return '$_temp0文件的其余内容已导入。';
  }

  @override
  String get backupSettingsUseBackup => '使用文件的';

  @override
  String get backupSettingsKeepMine => '保留我的';

  @override
  String get deskEpicboxBlockedWord => '被拦截';

  @override
  String deskEpicboxBlockedText(String host) {
    return '此网络拦截了 $host。请选择其他 Epicbox 服务器或使用专用 DNS。';
  }

  @override
  String deskEpicboxBlockedShort(String host) {
    return '此网络拦截了 $host。请换个服务器或使用专用 DNS。';
  }

  @override
  String deskEpicboxBlockedSwitch(String host) {
    return '切换到 $host';
  }

  @override
  String get deskSlotNow => '当前';

  @override
  String get deskSlotHelp => '帮助';

  @override
  String get deskSlotScanning => '正在扫描区块链';

  @override
  String get deskSlotScanWaits => '扫描正在等待网络';

  @override
  String get deskSlotScanStopped => '扫描已停止';

  @override
  String get deskSlotTryAgain => '重试';

  @override
  String get deskSlotSending => '正在发送付款';

  @override
  String get deskSlotPaymentOut => '付款途中';

  @override
  String get deskSlotPaymentIn => '付款到账中';

  @override
  String get deskSlotPaymentsOut => '付款途中';

  @override
  String get deskSlotPaymentsMoving => '付款确认中';

  @override
  String deskSlotOf(String done, String needed) {
    return '$done/$needed';
  }

  @override
  String get deskSlotWaitingBlock => '等待区块';

  @override
  String get deskSlotRequests => '新账单';

  @override
  String get deskSlotNodeStarting => '本地节点正在启动';

  @override
  String get deskSlotNodeSyncing => '本地节点正在同步';

  @override
  String get deskSlotOpenRecheck => '打开重新核对余额';

  @override
  String get deskSlotOpenSend => '打开发送';

  @override
  String get deskSlotOpenActivity => '在活动中打开';

  @override
  String get deskSlotOpenInvoices => '打开账单';

  @override
  String deskBarMenu(String app) {
    return '$app 菜单';
  }

  @override
  String get deskBarLock => '锁定钱包';

  @override
  String get deskBarShortcuts => '键盘快捷键';

  @override
  String deskBarAbout(String app) {
    return '关于 $app';
  }

  @override
  String get deskBarQuit => '退出';

  @override
  String get deskBarWalletsHere => '此电脑上的钱包';

  @override
  String get deskBarAddWallet => '添加钱包';

  @override
  String get deskBarWalletSettings => '钱包设置';

  @override
  String get deskBarStatus => '连接状态';

  @override
  String get deskBarMinimise => '最小化';

  @override
  String get deskBarMaximise => '最大化';

  @override
  String get deskBarRestore => '还原';

  @override
  String get deskBarClose => '关闭';

  @override
  String get deskBarSendRunningTitle => '正在发送一笔付款';

  @override
  String get deskBarSendRunningBody => '现在关闭会使这笔付款的结果无法确定。发送完成后，钱包可以自动关闭。';

  @override
  String get deskBarKeepOpen => '保持打开';

  @override
  String get deskBarCloseAfterSend => '完成后关闭';

  @override
  String get deskBarClosesAfterSend => '发送完成后关闭';

  @override
  String get deskBarClosing => '正在关闭';

  @override
  String get deskBarKeyBack => '后退';

  @override
  String get deskBarKeyForward => '前进';

  @override
  String get deskBarKeyClose => '关闭菜单或对话框';

  @override
  String get deskBarKeySubmit => '执行表单的主要操作';

  @override
  String get deskBarKeyList => '此列表';

  @override
  String get deskBarCopyBuild => '复制构建信息';

  @override
  String get deskBarBuildCopied => '已复制构建信息';

  @override
  String get deskBarKeyMenu => '打开应用菜单';

  @override
  String get txDetailsCancelRequestBody => '对方仍可以完成这笔付款。';

  @override
  String get txDetailsCancelNotPostedBody => '这笔付款之后仍可能完成。';

  @override
  String get cancelMoreInHelp => '取消是如何进行的';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '发往 $who 的 $amount EPIC。这笔付款之后仍可能完成。';
  }

  @override
  String get deskOnbWalletNameEdit => '编辑钱包名称';

  @override
  String get deskOnbWalletNameField => '钱包名称';

  @override
  String deskOnbWalletNameIs(String name) {
    return '钱包名称：$name';
  }

  @override
  String sendTurnOnMethod(String method) {
    return '开启 $method';
  }

  @override
  String get reqPickContactOrMethod => '选择联系人或方式';

  @override
  String deskOnbUnlockOpened(String when) {
    return '上次打开：$when';
  }

  @override
  String get deskOwnYourNode => '自有节点';

  @override
  String deskOwnLabel(String where) {
    return '自有节点 · $where';
  }

  @override
  String get deskOwnClassThisComputer => '这台电脑';

  @override
  String get deskOwnClassHome => '家庭网络';

  @override
  String get deskOwnClassVpn => 'VPN';

  @override
  String get deskOwnFactMempool => '内存池';

  @override
  String get deskOwnPoolEmpty => '空';

  @override
  String deskOwnPoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔等待中',
    );
    return '$_temp0';
  }

  @override
  String deskOwnSourceSite(String site) {
    return '每 15 秒直接询问 · 最新高度来自 $site';
  }

  @override
  String deskOwnSourceNodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每 15 秒直接询问 · 最新高度来自 $count 个公共节点',
    );
    return '$_temp0';
  }

  @override
  String get deskOwnSourceNone => '每 15 秒直接询问 · 没有可比较的网络高度';

  @override
  String get deskOwnSyncingLine => '同步完成前，钱包无法通过它发送或接收';

  @override
  String get deskOwnAccess => '所有者访问';

  @override
  String get deskOwnAccessHint =>
      '节点的所有者密钥会在这里显示同步阶段和对等节点，并可封禁对等节点。它保存在这台电脑的密钥环中，不在设置或钱包数据文件里。';

  @override
  String get deskOwnAccessNotSet => '未设置';

  @override
  String get deskOwnAccessOn => '已添加';

  @override
  String deskOwnAccessRefused(String time) {
    return '自 $time 起被拒绝';
  }

  @override
  String get deskOwnAccessRefusedBadge => '被拒绝';

  @override
  String get deskOwnAccessTor => 'Tor 开启时不使用';

  @override
  String get deskOwnAccessNote => '对等节点和同步详情来自节点的所有者 API。';

  @override
  String get deskOwnAdd => '添加…';

  @override
  String get deskOwnUpdate => '更新…';

  @override
  String get deskOwnRemove => '移除';

  @override
  String get deskOwnAdded => '已添加所有者访问';

  @override
  String get deskOwnRemoved => '已移除所有者访问';

  @override
  String deskOwnDlgTitle(String host) {
    return '$host 的所有者访问';
  }

  @override
  String get deskOwnDlgWhere =>
      '密钥是节点数据文件夹中 .api_secret 文件的第一行（节点电脑上的 ~/.epic/main）。';

  @override
  String get deskOwnDlgPaste => '粘贴密钥';

  @override
  String get deskOwnDlgPick => '选择文件…';

  @override
  String deskOwnDlgFileRead(String file) {
    return '已从 $file 读取';
  }

  @override
  String get deskOwnDlgFileEmpty => '该文件中没有密钥';

  @override
  String get deskOwnDlgPlainTitle => '密钥会在家庭网络中未加密传输';

  @override
  String get deskOwnDlgPlainText => '在共享网络上，请通过 VPN 或 https 连接节点，或在节点的电脑上运行钱包。';

  @override
  String get deskOwnDlgPlainAgain => '此节点不再提示';

  @override
  String get deskOwnDlgRefused => '节点拒绝了此密钥';

  @override
  String get deskOwnDlgNoAnswer => '节点没有响应；密钥已保留';

  @override
  String get deskOwnDlgAdd => '添加';

  @override
  String get deskOwnDownTitle => '自有节点没有响应';

  @override
  String deskOwnDownText(String host) {
    return '期间钱包使用 $host，此节点连续响应两次后会切换回来。';
  }

  @override
  String deskOwnUsingMeanwhile(String host) {
    return '期间使用 $host';
  }

  @override
  String deskOwnUsingUntilSynced(String host) {
    return '同步完成前使用 $host';
  }

  @override
  String get deskOwnTryNow => '立即重试';

  @override
  String deskOwnUseForGood(String host) {
    return '保留 $host';
  }

  @override
  String get deskOwnSyncTitle => '在此节点同步完成前使用公共节点？';

  @override
  String deskOwnSyncText(String host) {
    return '此节点同步完成前，可由 $host 代替。';
  }

  @override
  String get deskOwnWaitForMine => '等待此节点';

  @override
  String deskOwnSyncUsingTitle(String host) {
    return '同步完成前使用 $host';
  }

  @override
  String get deskOwnSyncUsingText => '此节点开始接受交易后，钱包会切换回来。';

  @override
  String get deskOwnMine => '这是我的节点';

  @override
  String deskOwnMineHint(String site) {
    return '直接询问节点本身而不是 $site，并提供所有者访问。适用于你自己运行的节点。';
  }

  @override
  String get deskOwnSlotSyncing => '自有节点正在同步';

  @override
  String ownNodeLabel(String where) {
    return '你的节点 · $where';
  }

  @override
  String get ownNodeThisPhone => '这部手机';

  @override
  String get ownNodeHome => '家庭网络';

  @override
  String get ownNodeVpn => 'VPN';

  @override
  String get ownNodeSynced => '已同步';

  @override
  String get ownNodeSyncing => '正在同步';

  @override
  String get ownNodeBehind => '落后';

  @override
  String get ownNodeFactBehind => '落后';

  @override
  String get ownNodeFactLatency => '延迟';

  @override
  String get ownNodeFactAccepts => '接受交易';

  @override
  String get ownNodeFactMempool => '内存池';

  @override
  String get ownNodeYes => '是';

  @override
  String get ownNodeNotYet => '尚未';

  @override
  String get ownNodeUnknown => '未知';

  @override
  String get ownNodePoolEmpty => '空';

  @override
  String ownNodePoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔等待中',
    );
    return '$_temp0';
  }

  @override
  String get ownNodeAskedDirectly => '每 15 秒从这部手机直接询问';

  @override
  String get deskConExportDo => '导出';

  @override
  String get deskSetAboutDownloadPage => '下载页面';

  @override
  String get deskUpdManual => '此副本无法自行安装更新。';

  @override
  String get deskUpdDownloadInstall => '下载并安装';

  @override
  String get deskUpdReadyTitle => '重启以更新';

  @override
  String get deskUpdReadyBody => '钱包会锁定，应用会重新打开。';

  @override
  String get deskUpdRestartNow => '立即重启';

  @override
  String get deskUpdLater => '稍后';

  @override
  String get sendTorNotInVersion => '此版本无法向 Tor 地址发送。';

  @override
  String get methodSendDirectLineNoTor => '对方钱包必须处于打开状态。';

  @override
  String get sendDirectAddressShapeNoTor => '链接地址以 http:// 或 https:// 开头。';

  @override
  String get contactsAddressInvalidAnyNoTor =>
      '地址无效。请使用 Epicbox 地址（es5x…@服务器）或链接地址（https://…）。';

  @override
  String get handshakeLink1NoTor => '你的钱包通过互联网把付款直接发到对方的钱包。这些币被锁定。';

  @override
  String txLinkHttpHintNoTor(String port) {
    return '链接 · HTTP 通过网址（http://host:$port）直接向对方钱包付款，并为这部手机提供一个同一 Wi-Fi 网络中的钱包可以付款的地址。双方钱包都必须打开。它在传输途中不加密，也无法从互联网或移动数据访问。会在“发送”和“接收”中加入 链接 · HTTP。';
  }

  @override
  String get tourPhoneWalletTextNoTor =>
      '你的余额，下面是节点和 Epicbox 的图标。仍在确认中的金额在下方的卡片里。';

  @override
  String get tourPhonePrivacyTextNoTor => '钱包使用哪个节点和 Epicbox 服务器。点一个服务器即可更改。';

  @override
  String get tourPhoneAdvancedTextNoTor => '离线、输出和技术详情都在这里。需要什么就开启什么。';

  @override
  String get deskNoTorSendDirectLine2 => 'http(s) 地址。对方钱包必须处于打开状态。';

  @override
  String deskNoTorSetTxDirectHint(String port) {
    return '通过网址（http://host:$port）在钱包之间直接付款和收款，中间没有服务器。仅在双方钱包都打开时有效。会在“发送”中加入 链接 · HTTP，并在“接收”中加入它的地址。所有钱包。';
  }

  @override
  String get deskNoTorTxDetailsFromBad => '请使用 Epicbox 或 http(s) 地址。';

  @override
  String get deskNoTorTourAdvancedText => '输出和技术详情都在这里。需要什么就开启什么。';

  @override
  String get errorInputsSpentElsewhere =>
      '节点显示这些币已被花掉，而本钱包没有花它们。很可能是另一个使用你助记词的钱包花掉的。';

  @override
  String get deskErrInputsSpentElsewhere =>
      '节点显示这些币已被花掉，而本钱包没有花它们。很可能是另一个使用你助记词的钱包花掉的。';

  @override
  String get slAddedByYou => '由你添加';

  @override
  String slCount(int n, int limit) {
    return '$n/$limit';
  }

  @override
  String slLimit(int limit) {
    return '已选 $limit/$limit。取消一个后才能选其他。';
  }

  @override
  String get slKeepOne => '至少保留一个。';

  @override
  String get slChosenUntick => '已选中。请先取消勾选。';

  @override
  String get slResetDefaults => '恢复默认';

  @override
  String get slReset => '已恢复默认。';

  @override
  String slChosen(String host) {
    return '已选择 $host。';
  }

  @override
  String slChosenNonDefault(String host) {
    return '已选择。同样使用 $host 的钱包会在那里找到你。';
  }

  @override
  String slUnchosen(String host) {
    return '已取消勾选 $host。';
  }

  @override
  String slAddedNonDefault(String host) {
    return '已添加 $host。同样使用它的钱包会在那里找到你。';
  }

  @override
  String slAddedUntick(String host) {
    return '已添加 $host。取消其他勾选后即可选择。';
  }

  @override
  String get txSentFromOtherWallet => '从另一台设备发送';

  @override
  String txSpokenSentFromOtherWallet(String amount) {
    return '从另一台设备发送，$amount';
  }

  @override
  String get txDetailsOtherWallet => '由持有此钱包助记词的另一台设备发送。只知道金额。';

  @override
  String get txSentFromOtherWalletUnverified => '从另一台设备发送 · 未验证';

  @override
  String get txDetailsUnverified => '未核实：目前只有节点报告了这笔付款。用“重新核对余额”来确认。';

  @override
  String get txDetailsNotKnown => '未知';

  @override
  String get txReceivedByOtherWallet => '由另一台设备收到';

  @override
  String txSpokenReceivedByOtherWallet(String amount) {
    return '由另一台设备收到，$amount';
  }

  @override
  String get txDetailsOtherWalletIn => '由持有此钱包助记词的另一台设备收到。只知道金额。';

  @override
  String get expLinkedDevices => '关联设备';

  @override
  String get expLinkedDevicesHint =>
      '此钱包在两台设备上使用：每台显示另一台的付款，并保留另一台正在花费的币。实验性功能。';

  @override
  String get devicesThisPhone => '手机';

  @override
  String get devicesThisComputer => '电脑';

  @override
  String get devicesNone => '无';

  @override
  String get devicesSeenNow => '刚刚在线';

  @override
  String devicesSeenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前在线',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前在线',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前在线',
    );
    return '$_temp0';
  }

  @override
  String get devicesNotSeen => '尚未在线';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备',
    );
    return '$_temp0';
  }

  @override
  String get devicesThisDevice => '本设备';

  @override
  String get devicesOthers => '关联设备';

  @override
  String get devicesEmpty => '先在另一台设备上恢复此钱包，然后在这里关联两台设备。';

  @override
  String get devicesLink => '关联设备';

  @override
  String get devicesServers => '服务器';

  @override
  String get devicesPause => '暂停同步';

  @override
  String get devicesPauseHint => '暂停期间，消息会在服务器上保留最多 7 天。“仅节点”和“紧急断网”也会暂停同步。';

  @override
  String get devicesHeld => '保留的币';

  @override
  String devicesHeldBy(String name) {
    return '被 $name 的付款保留';
  }

  @override
  String get devicesRelease => '释放';

  @override
  String get devicesReleaseTitle => '释放这些币？';

  @override
  String devicesReleaseBody(String name) {
    return '$name 可能仍在完成这笔付款。如果是这样，你用这些币进行的付款会失败。这只影响本设备。';
  }

  @override
  String get devicesReleased => '已在本设备上释放。';

  @override
  String get devicesRename => '重命名';

  @override
  String get devicesNameLabel => '名称';

  @override
  String get devicesRemove => '移除';

  @override
  String devicesRemoveTitle(String name) {
    return '移除 $name？';
  }

  @override
  String devicesRemoveBody(String name) {
    return '$name 将不再收到此钱包的消息；它在这里保留的币会被释放。它仍可用助记词花费：如果它可能落入他人之手，请把资金转到新钱包。';
  }

  @override
  String devicesRemoved(String name) {
    return '已移除 $name。';
  }

  @override
  String devicesRemovedBy(String name) {
    return '$name 移除了此设备。';
  }

  @override
  String get devicesRemoving => '正在移除… 本设备联网后会通知另一台设备。';

  @override
  String get devicesMoneyNote => '关联会在两台设备之间共享付款信息。它不能保护资金：任何持有助记词的设备都能花费它。';

  @override
  String get devicesUnsupported => '此版本暂不能关联设备。';

  @override
  String get linkLead => '用于另一台设备上的此钱包。请先在那里用助记词恢复它。';

  @override
  String get linkShow => '显示二维码';

  @override
  String get linkScan => '扫描二维码';

  @override
  String get linkPaste => '粘贴邀请';

  @override
  String get linkCopy => '复制邀请';

  @override
  String get linkCopied => '邀请已复制。';

  @override
  String linkExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '邀请还可用 $count 分钟。',
    );
    return '$_temp0';
  }

  @override
  String get linkWaiting => '正在等待另一台设备…';

  @override
  String linkWaitingFor(String name) {
    return '正在等待 $name…';
  }

  @override
  String get linkPasteLabel => '邀请';

  @override
  String get linkGo => '关联';

  @override
  String get linkPicturesLabel => '四张图片';

  @override
  String get linkDoneTitle => '已关联';

  @override
  String linkDone(String name) {
    return '已关联 $name。';
  }

  @override
  String get linkFailedTitle => '未关联';

  @override
  String get linkFailInvalid => '这不是设备邀请。';

  @override
  String get linkFailExpired => '邀请已过期。请重新生成。';

  @override
  String get linkFailNotFound => '此邀请已被使用。';

  @override
  String get linkFailOwn => '此邀请来自本设备。请在另一台设备上扫描。';

  @override
  String get linkFailOtherWallet => '该设备持有另一个钱包。关联需要同一个助记词。';

  @override
  String get linkFailOtherWalletCode => '此邀请来自另一个钱包。关联需要相同的助记词。';

  @override
  String get linkFailTooMany => '已关联了一台设备。';

  @override
  String get linkFailUnreachable => '无法联系另一台设备。';

  @override
  String get linkTryAgain => '重试';

  @override
  String get linkOffTitle => '关联设备是实验性功能';

  @override
  String txSentFromDevice(String device) {
    return '从 $device 发送';
  }

  @override
  String txDeviceMadeOn(String device) {
    return '在 $device 上发起。详情来自该设备；金额和确认数来自区块链。';
  }

  @override
  String get txDeviceHeld => '在区块链显示这笔付款或另一台设备结束它之前，其币会在本设备上被保留。';

  @override
  String sendHeldByDevice(String amount, String name) {
    return '$amount EPIC 被“$name”正在进行的一笔付款保留。';
  }

  @override
  String get offerLinkRestore => '也在另一台设备上使用这个钱包？关联它们即可看到彼此的付款。';

  @override
  String get offerLinkOtherWallet => '这是你的另一台设备吗？关联它即可看到付给了谁，并让两台设备保持同步。';

  @override
  String devicesReleasedRow(String name) {
    return '已在此释放 · $name 仍可能发送';
  }

  @override
  String get deskDevPausedOffline => '离线开启时已暂停。';

  @override
  String get deskDevPausedEpicboxOff => 'Epicbox 关闭时已暂停。';

  @override
  String deskDevHeldAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskDevRenameThis => '重命名这台电脑';

  @override
  String deskDevRenameDevice(String name) {
    return '重命名 $name';
  }

  @override
  String get deskDevPasteLead => '粘贴另一台设备显示的代码。';

  @override
  String get deskDevMakingCode => '正在生成代码…';

  @override
  String get deskDevConnecting => '正在连接…';

  @override
  String get deskDevTheOther => '另一台设备';

  @override
  String get deskDevOfferReceived => '这是你的另一台设备吗？关联它即可看到是谁发来的，并让两台设备保持同步。';

  @override
  String devicesEndCancelled(String name) {
    return '在 $name 上已取消';
  }

  @override
  String devicesEndFailed(String name) {
    return '在 $name 上失败';
  }

  @override
  String devicesEndExpired(String name) {
    return '在 $name 上已过期';
  }

  @override
  String devicesEndLineCancelled(String name) {
    return '$name 取消了这笔付款。其币已重新可用。';
  }

  @override
  String devicesEndLineExpired(String name) {
    return '$name 未能及时完成这笔付款。其币已重新可用。';
  }

  @override
  String devicesWhyNotDelivered(String name) {
    return '$name 无法将其送达收款方。其币已重新可用。';
  }

  @override
  String get devicesWhyRefused => '收款方的服务器拒绝了它。其币已重新可用。';

  @override
  String get devicesWhyInputsSpent => '其币此前已被花费。';

  @override
  String devicesWhyOther(String name) {
    return '$name 无法完成这笔付款。其币已重新可用。';
  }

  @override
  String devicesStatusInfo(String name) {
    return '此状态来自 $name。最终状态以区块链为准。';
  }

  @override
  String get syncHelpOtherDevice => '另一台设备';

  @override
  String get syncHelpServer => '服务器';

  @override
  String get syncHelpChain => '区块链';

  @override
  String get syncHelpStep1 => '本设备开始一笔付款。';

  @override
  String syncHelpStep2(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '加密消息送到两个服务器。只有设备能读取。',
      one: '加密消息经服务器送出。只有设备能读取。',
    );
    return '$_temp0';
  }

  @override
  String get syncHelpStep3 => '另一台设备保留这些币，并列出这笔付款。';

  @override
  String get syncHelpStep4 => '区块链确认。最终状态由区块链决定。';

  @override
  String get syncHelpDiagram =>
      '同步的工作方式：本设备开始一笔付款；加密消息经服务器送到另一台设备，它保留这些币；区块链确认。';

  @override
  String get syncHelpStatus => '实时状态';

  @override
  String get syncHelpPaused => '同步已暂停';

  @override
  String get syncHelpAnswering => '正常响应';

  @override
  String get syncHelpNotAnswering => '无响应';

  @override
  String get syncHelpNotChecked => '未检查';

  @override
  String get deskSetAdvConfirmations => '确认数';

  @override
  String deskSetAdvConfirmationsHint(int byDefault, int min, int max) {
    return '收到的付款要等待多少个区块，其输出才能花费。默认 $byDefault，可设为 $min 到 $max。';
  }

  @override
  String get deskSetAdvConfirmationsDefault => '默认';

  @override
  String deskSetAdvConfirmationsReset(int count) {
    return '恢复为 $count';
  }

  @override
  String get deskSetAdvConfirmationsFewer => '减少确认数';

  @override
  String get deskSetAdvConfirmationsMore => '增加确认数';

  @override
  String deskSetAdvConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个确认',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAdvConfirmationsLowNote => '确认数越少越快，但越不安全。';

  @override
  String get deskSetAdvConfirmationsNotSaved => '确认数未更改';

  @override
  String get deskSetPeersFirstSeenHint => '本应用在本次运行中首次看到该对等节点连接的时间。';

  @override
  String deskAppFirstScanProgress(int percent) {
    return '正在扫描区块链 · $percent%';
  }

  @override
  String deskAppFirstScanFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已找到 $countString 个输出',
    );
    return '$_temp0';
  }

  @override
  String get deskAppFirstScanShowLog => '显示日志';

  @override
  String get deskAppFirstScanHideLog => '隐藏日志';

  @override
  String deskNodeDurationDh(int days, int hours) {
    return '$days 天 $hours 小时';
  }

  @override
  String deskNodeDurationH(int hours) {
    return '$hours 小时';
  }

  @override
  String deskInvPayerAgoHoursOnly(int hours) {
    return '$hours 小时';
  }

  @override
  String get slPlainHttpTitle => '要在不加密的情况下使用此节点吗？';

  @override
  String slPlainHttpBody(String host) {
    return '$host 属于共享地址段：可能是你自己的 tailnet（Tailscale），也可能是你的网络服务商的网络。钱包通过未加密的 http 与此节点通信，因此该网络上的任何人都能看到钱包向它查询的内容。只有当此地址是你的 tailnet 时才添加。';
  }

  @override
  String get slPlainHttpUse => '使用此节点';

  @override
  String get slRefusedLocal => '未选择：其他钱包无法连接本地或私有地址上的服务器。';

  @override
  String get slRefusedOnion => '未选择：onion 服务器只有在开启 Tor 时才能使用。';

  @override
  String get slRefusedOnionNoTor => '未选择：此版本无法连接这台服务器。';

  @override
  String get deskOwnAccessOnPlain => '已添加 · 以未加密方式（http）发送到节点，该网络上可被读取';

  @override
  String get sasNotFromCamera =>
      '对方的代码是通过消息收到的，而不是用你的相机扫描的。除非对方钱包从这个屏幕扫描过你的代码，否则这些词无法证明是谁发送的，因此这里不提供确认：可以先不核对保留配对，或用邀请配对。';

  @override
  String get slSwitchFirst => '请先切换';

  @override
  String get contactPaymentsNone => '还没有与此联系人的付款。';

  @override
  String contactPaymentsWith(String name) {
    return '与 $name 的付款';
  }

  @override
  String get contactPaymentsAll => '全部付款';

  @override
  String receiveEpicboxNotConnected(String server) {
    return '未连接 · $server';
  }

  @override
  String restoreWordsAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部 $count 个单词都正确。',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个单词',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个单词不在词表中。',
    );
    return '$_temp0';
  }

  @override
  String pairInvitedAt(String clock) {
    return '已邀请 $clock';
  }

  @override
  String get pairInvitedYesterday => '昨天已邀请';

  @override
  String pairInvitedOn(String day) {
    return '已邀请 $day';
  }

  @override
  String get deskActNoneUnderFilter => '此筛选下没有内容';

  @override
  String get deskKitMethodConnected => '已连接';

  @override
  String get deskOvSendWaitsNode => '节点响应后即可继续发送。';

  @override
  String get deskSetRescanRecheck => '重新核对';

  @override
  String get deskSetRescanRecheckAgain => '再次核对';

  @override
  String get deskSetRescanFromDate => '从某个日期';

  @override
  String get deskSetRescanPickDate => '选择日期';

  @override
  String get deskSetRescanPickDateFirst => '请先选择日期。';

  @override
  String contactsImportAddsAddress(String name, String method, String address) {
    return '$name 新增 $method 地址：$address';
  }

  @override
  String get netStatusTurnOnHint => '已关闭。在“设置 › 交易”中开启。';

  @override
  String get netStatusTurnOnHintPrivacy => '已关闭。在“设置 › 隐私与网络”中开启。';

  @override
  String get netStatusTurnOnHintNet => '已关闭。在“设置 › 网络与隐私”中开启。';

  @override
  String get deskBarTurnOnHint => '已关闭。在“设置 › 交易”中开启。';

  @override
  String get deskErrMacKeychain =>
      'macOS 不允许应用读取其保存在钥匙串中的数据。请退出 BT Wallet 并重新打开；当 macOS 询问时，输入你解锁 Mac 的密码并选择“始终允许”。';

  @override
  String get deskUpdOpenDmg => '打开磁盘映像';

  @override
  String get deskUpdDmgHint =>
      '应用会关闭并打开磁盘映像：将 BT Wallet 拖到“应用程序”中替换旧版本。如果那里有 Epic Cash Desktop，请将其移到废纸篓。';

  @override
  String get balanceSheetTitle => '余额';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项待处理',
    );
    return '$_temp0';
  }

  @override
  String get connectionsSheetTitle => '连接';

  @override
  String settingsFileSyntaxError(String file, int line) {
    return '$file，第 $line 行：无法读取此行。仍使用上次有效的设置。';
  }

  @override
  String settingsFileNotText(String file, int line) {
    return '$file，第 $line 行：不是带双引号的文本。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotNumber(String file, int line) {
    return '$file，第 $line 行：不是整数。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotSwitch(String file, int line) {
    return '$file，第 $line 行：不是 true 或 false。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotList(String file, int line) {
    return '$file，第 $line 行：不是列表。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotNodeAddress(String file, int line) {
    return '$file，第 $line 行：不是节点地址。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotEpicboxServer(String file, int line) {
    return '$file，第 $line 行：不是 Epicbox 服务器。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotHostName(String file, int line) {
    return '$file，第 $line 行：不是主机名。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotWebAddress(String file, int line) {
    return '$file，第 $line 行：不是网址。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotOnion(String file, int line) {
    return '$file，第 $line 行：不是洋葱地址。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotPort(String file, int line) {
    return '$file，第 $line 行：不是端口号。仍使用上次有效的值。';
  }

  @override
  String settingsFileNotEpicboxAddress(String file, int line) {
    return '$file，第 $line 行：不是 Epicbox 地址。仍使用上次有效的值。';
  }

  @override
  String settingsFileUnknownKey(String file, int line, String key) {
    return '$file，第 $line 行：未知的键 $key，已忽略。';
  }

  @override
  String settingsFileConflict(String file, String key) {
    return '$file 同时被编辑过；保留其中 $key 的值。';
  }

  @override
  String settingsFileBrokenSaved(String file, String backup) {
    return '$file 有错误。已另存为 $backup 并重新写入。';
  }

  @override
  String settingsFileRecreated(String file) {
    return '$file 不见了，已重新写入。';
  }

  @override
  String settingsFileWriteFailed(String file) {
    return '无法写入 $file。此更改在关闭应用前有效。';
  }

  @override
  String settingsFileReadFailed(String file) {
    return '无法读取 $file。正在使用内置设置。';
  }

  @override
  String get deskKitReachTorOff => '此检查需要关闭 Tor。';

  @override
  String get deskSetBackupServersTitle => '使用此文件中的服务器？';

  @override
  String get deskSetBackupServersBody =>
      '文件中的节点和 Epicbox 服务器列表与这台电脑的不同。这里的所有钱包都使用同一份列表。';

  @override
  String get deskSetBackupServersKeep => '保留这台电脑的';

  @override
  String get deskSetBackupServersUse => '使用文件的';

  @override
  String get deskSlNoNodeTitle => '未设置节点';

  @override
  String get deskSlNoNodeText => '节点列表为空。添加节点后才能核对余额和发送。';

  @override
  String get deskSlNoEpicboxTitle => '未设置 Epicbox 服务器';

  @override
  String get deskSlNoEpicboxText => 'Epicbox 服务器列表为空。添加服务器后才有 Epicbox 地址。';

  @override
  String get devicesOneOnly => '只能关联一台设备。请先移除它，再关联另一台。';

  @override
  String txReceivedOnDevice(String device) {
    return '在 $device 上收到';
  }

  @override
  String txSpokenReceivedOnDevice(String device, String amount) {
    return '在 $device 上收到，$amount';
  }

  @override
  String txDetailsDeviceIn(String device) {
    return '与本钱包关联的 $device 收到了这些币。';
  }

  @override
  String get deskOnbNodeAdvanced => '高级';

  @override
  String deskOnbNodePortsSub(String api, String p2p) {
    return 'API $api · P2P $p2p';
  }

  @override
  String get deskOnbNodeApiPort => 'API 端口';

  @override
  String get deskOnbNodeP2pPort => 'P2P 端口';

  @override
  String get deskOnbNodePortsWhy => '仅当这台电脑或网络中的另一个节点使用这些端口时才需要更改。';

  @override
  String deskOnbNodePortRange(String min, String max) {
    return '$min 到 $max 之间的数字。';
  }

  @override
  String get deskOnbNodePortsSame => '两个端口必须不同。';

  @override
  String deskOnbNodePortTaken(String port, String next) {
    return '端口 $port 被其他程序占用。$next 可用。';
  }

  @override
  String deskOnbNodePortUse(String port) {
    return '使用 $port';
  }

  @override
  String get deskSetLnodePorts => '端口';

  @override
  String get deskSetLnodePortsTitle => '节点端口';

  @override
  String get deskSetLnodePortsDesc => '内置节点监听的端口。';

  @override
  String get deskSetLnodePortsRestart => '节点将使用新端口重新启动。';

  @override
  String get deskSetLnodePortsSaved => '端口已保存';

  @override
  String get deskSetLnodePortsRestarting => '节点正在重新启动。';

  @override
  String get deskSetLnodePortsNotSaved => '端口未保存';

  @override
  String get deskKitInfoLabel => '更多信息';

  @override
  String get advModeNodeOnly => '仅节点';

  @override
  String get advModeKillSwitch => '紧急断网';

  @override
  String get advModeStandardHintHere => '直接连接。在下方开启 Tor 可经由 Tor 连接。';

  @override
  String get advModeStandardHintNoTor => '直接连接到节点和你使用的服务。';

  @override
  String get advModeTorOnlyHint => '一切都经过 Tor。Tor 就绪前不会建立任何连接。';

  @override
  String get advModeNodeOnlyHint => '只连接当前使用的节点。直接 · QR 和 直接 · 文件可用。';

  @override
  String get advModeKillSwitchHint => '不建立任何连接。钱包以最后已知的余额离线工作，付款通过文件或二维码进行。';

  @override
  String advModeConfirmTitle(String mode) {
    return '切换到“$mode”？';
  }

  @override
  String advModeConfirmBody(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 笔付款正通过 Epicbox 或链接等待接收方。离开“$mode”后它们会暂停并继续。不会取消任何内容。',
    );
    return '$_temp0';
  }

  @override
  String get advModeConfirmSwitch => '切换';

  @override
  String netMarkSemantics(String mode) {
    return '网络模式：$mode。打开“网络”部分。';
  }

  @override
  String netMarkSemanticsDesk(String mode) {
    return '网络模式：$mode。显示它的作用。';
  }

  @override
  String get netMarkLineTorOnly => '所有连接都经过 Tor。';

  @override
  String get netMarkLineTorWaiting => '正在等待 Tor。就绪之前什么都不会连接。';

  @override
  String get netMarkLineNodeOnly => '只连接正在使用的节点。Epicbox、链接、更新和价格已关闭。';

  @override
  String get netMarkLineKillSwitch => '什么都不连接。余额和历史记录是上次已知的。';

  @override
  String get netMarkChange => '更改';

  @override
  String statusOffByMode(String mode) {
    return '关闭（$mode）';
  }

  @override
  String get statusOffByModeDetail => '已被网络模式关闭。可在“设置”›“高级”›“网络”中更改。';

  @override
  String get statusOffByModeDetailNet => '已被网络模式关闭。可在“设置”›“网络与隐私”中更改。';

  @override
  String get netBlockEpicboxNodeOnly =>
      '“仅节点”已开启：Epicbox 已关闭。直接 · 二维码付款 和 直接 · 文件传输可用。';

  @override
  String get netBlockLinkNodeOnly => '“仅节点”已开启：链接已关闭。直接 · 二维码付款 和 直接 · 文件传输可用。';

  @override
  String get netBlockSendKillSwitch =>
      '“紧急断网”已开启：什么都不连接。直接 · 二维码付款 和 直接 · 文件传输可用。';

  @override
  String get netBlockNodeOnly => '在“仅节点”下已关闭。';

  @override
  String get netBlockKillSwitch => '在“紧急断网”下已关闭：什么都不连接。';

  @override
  String get netBlockWaitingForTorLong => '正在等待 Tor。就绪之前什么都不会连接。';

  @override
  String receiveEpicboxOffMode(String mode) {
    return 'Epicbox 在“$mode”下已关闭。';
  }

  @override
  String receiveEpicboxOffModeBody(String mode) {
    return '发往此地址的付款会暂存在 Epicbox 服务器上，离开“$mode”后到达。';
  }

  @override
  String receiveLinkOffMode(String mode) {
    return '链接收款在“$mode”下已关闭。';
  }

  @override
  String updatesOffMode(String mode) {
    return '更新检查在“$mode”下已关闭。';
  }

  @override
  String reportOffMode(String mode) {
    return '在“$mode”下已关闭。请改为将报告保存为文件。';
  }

  @override
  String get recheckOffKill => '重新核对余额需要节点。在“紧急断网”下已关闭。';

  @override
  String get postFinishedOffKill => '在“紧急断网”下已关闭：这里什么都不连接。';

  @override
  String get postFinishedOffTor => '正在等待 Tor。广播需要节点。';

  @override
  String get browserOffTorOnly => '会在 Tor 之外打开。请改为复制链接。';

  @override
  String browserOffMode(String mode) {
    return '在“$mode”下已关闭。请改为复制链接。';
  }

  @override
  String get netChangeLink => '更改';

  @override
  String get lastKnownCaption => '上次已知';

  @override
  String get lastKnownList => '上次已知 · 紧急断网';

  @override
  String lastKnownConfirming(String text) {
    return '$text · 上次已知';
  }

  @override
  String get coldNeedsOnlineCheck => '需要先联网核对一次余额。';

  @override
  String get finalizeNotPostedTitle => '已完成，未广播';

  @override
  String finalizeNotPostedBody(String amount) {
    return '$amount 已完成。“紧急断网”已开启，所以这部手机无法广播它：请保存它，或显示为二维码，供联网的设备使用。';
  }

  @override
  String get finishedSaveFile => '保存文件';

  @override
  String get finishedShowQr => '显示二维码';

  @override
  String finishedSaved(String name) {
    return '已保存 $name';
  }

  @override
  String get finishedQrTitle => '已完成的付款';

  @override
  String get finishedUnavailable => '此版本还不能保存已完成的付款。';

  @override
  String get finishedFailed => '无法读取已完成的付款。';

  @override
  String get txPostElsewhere => '待在其他设备广播';

  @override
  String get txPostElsewhereKill => '在“紧急断网”下完成。请保存它或显示二维码，然后在联网的设备上广播。';

  @override
  String get txPostElsewhereAfter => '在“紧急断网”下完成，尚未上链。可从这里广播，或等待已广播它的设备。';

  @override
  String get txPostNow => '立即广播';

  @override
  String get txModeFinishedKill => '在“紧急断网”下完成';

  @override
  String get txModeRow => '模式';

  @override
  String get postFinishedTitle => '广播已完成的付款';

  @override
  String get postFinishedIntro => '广播另一台设备在“紧急断网”下完成的付款。';

  @override
  String get postFinishedIntroOffline => '发布另一台设备在无网络时完成的付款。';

  @override
  String get postFinishedOpenFile => '打开文件';

  @override
  String get postFinishedScanQr => '扫描二维码';

  @override
  String get postFinishedPaste => '粘贴';

  @override
  String get postFinishedChooseFile => '选择文件';

  @override
  String get postFinishedSummary => '已完成的付款';

  @override
  String get postFinishedAmount => '金额';

  @override
  String get postFinishedFee => '手续费';

  @override
  String get postFinishedKernel => '内核';

  @override
  String get postFinishedNote => '广播会把它送入网络。创建它的钱包在链上看到后，会显示为确认中。';

  @override
  String get postFinishedPost => '广播';

  @override
  String get postFinishedPosting => '正在广播…';

  @override
  String get postFinishedDone => '已广播到网络';

  @override
  String get postFinishedDoneBody => '节点已收到。创建它的钱包在链上看到后，会显示为确认中。';

  @override
  String get postFinishedNotFinished =>
      '这不是已完成的付款。请打开保存在“待在其他设备广播”下的文件，或扫描它的二维码。';

  @override
  String get postFinishedFailed => '节点没有接受。请重试。';

  @override
  String get postFinishedUnreachable => '节点没有响应。';

  @override
  String get postFinishedDeskRow => '广播已完成的付款';

  @override
  String get postFinishedDeskRowText => '广播另一台设备在“紧急断网”下完成的付款。';

  @override
  String get postFinishedOpen => '打开';

  @override
  String deskFinNotPostedKillBody(String amount) {
    return '$amount 已完成。“紧急断网”已开启，所以这台电脑无法广播它。请保存或复制它，然后在联网的设备上广播：接收 › 交易文件 › 广播已完成的付款。';
  }

  @override
  String netMarkRowLabel(String mode) {
    return '网络模式：$mode';
  }

  @override
  String get qrStatusFinishedHidden => '已隐藏';

  @override
  String get qrStatusFinishedShowing => '正在等待联网设备扫描。';

  @override
  String qrShowSubFinished(String amount) {
    return '$amount，已完成';
  }

  @override
  String qrSemanticsFinished(String state) {
    return '已完成付款的二维码，$state';
  }

  @override
  String get qrHiddenBodyFinished => '把它给联网的设备看。它会广播这笔付款，不需要密钥。';

  @override
  String get qrScanFinished => '扫描已完成的付款';

  @override
  String get qrScanNotFinished => '该二维码不是已完成的付款。';

  @override
  String get qrScanAimFinished => '请将相机对准另一台设备上的二维码。';

  @override
  String get deskRailOpenNetwork => '打开网络设置';

  @override
  String get cancelFeeLine => '需支付正常的网络手续费。';

  @override
  String get cancelForSure => '彻底取消';

  @override
  String get cancelStopWaiting => '不再等待';

  @override
  String get cancelStopWaitingLine => '免费。这笔付款仍可能完成。';

  @override
  String get cancelMoveBack => '把币转回';

  @override
  String cancelMoveBackFee(String fee) {
    return '把币转回 · 手续费 $fee';
  }

  @override
  String get cancelUnlockOpen => '解锁币，付款保持未结';

  @override
  String get cancelCompareMoveBack => '把币转回：确定，需支付网络手续费。';

  @override
  String get cancelCompareUnlock => '解锁币：免费，这笔付款仍可能完成。';

  @override
  String get cancelChoicesTitle => '两种取消方式';

  @override
  String get cancelChoicesWhy =>
      '彻底取消会先把币移回这个钱包，需支付正常的网络手续费。之后旧的付款再也无法完成，所以这是稳妥的方式。\n\n不再等待免费，也不移动任何币。这些币可以再次使用，付款则保持原样。如果对方之后仍完成了它，付款会完成并显示为已付；如果没有，就什么也不会发生。';

  @override
  String get cancelStoppedWaitingTitle => '已不再等待';

  @override
  String get cancelStoppedWaitingText => '这些币可以再次使用。这笔付款仍可能完成；如果完成，会显示为已付。';

  @override
  String get txDetailsStoppedWaiting =>
      '已不再等待。这些币可以再次使用。这笔付款仍可能完成；如果完成，会显示为已付。';

  @override
  String get errorPaymentCancelledCoinsMoved => '这笔付款已取消，它的币已被移走。它无法再完成。';

  @override
  String get errorPaymentAlreadyWentThrough => '无法把币移回：这笔付款本身已经完成。它显示为已付款。';

  @override
  String get errorPinKeyLost =>
      'PIN 码已无法打开此钱包。点按“忘记 PIN 码？”，用恢复短语恢复钱包。币仍留在区块链上，只能用该恢复短语恢复；如果设置过密码短语，还需要密码短语。';

  @override
  String get errorKeystoreRefused => '手机未提供钱包密钥。请先用手机自身的 PIN 码或指纹解锁手机，然后重试。';

  @override
  String get unlockTryAgain => '重试';

  @override
  String get settingsUsePassphrase => '使用密码短语';

  @override
  String get settingsChangePassphrase => '更改密码短语';

  @override
  String get passphraseLabel => '密码短语';

  @override
  String passphraseChoose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请设置至少 $count 个字符且不全是数字的密码短语',
    );
    return '$_temp0';
  }

  @override
  String get passphraseRepeat => '再次输入密码短语';

  @override
  String get passphraseMismatch => '两次输入的密码短语不同';

  @override
  String get passphraseSet => '密码短语已设置';

  @override
  String get passphraseSetBiometricsOff => '密码短语已设置。可在下方重新开启生物识别解锁。';

  @override
  String get passphraseForgot => '忘记密码短语？';

  @override
  String get passphrasePromptTitle => '输入密码短语';

  @override
  String get passphraseEnterCurrent => '输入当前的密码短语';

  @override
  String get passphraseCurrentLabel => '当前密码短语';

  @override
  String get passphraseChooseTitle => '设置密码短语';

  @override
  String passphraseRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '至少 $count 个字符，且不能全是数字。',
    );
    return '$_temp0';
  }

  @override
  String get passphraseUsePinInstead => '改用 PIN';

  @override
  String get passphraseUsePassphraseInstead => '改用密码短语';

  @override
  String get invoicePassphraseReason => '输入密码短语以支付此账单。';

  @override
  String get restoreReplacePassphraseReason => '输入密码短语以替换此钱包。恢复后的钱包沿用此密码短语。';

  @override
  String get backupPassphraseReason => '请输入密码短语以显示助记词。';

  @override
  String sendQrPassphraseReason(String amount) {
    return '输入密码短语，以生成 $amount 的付款二维码。';
  }

  @override
  String get settingsBiometricsPassphraseReason => '请输入密码短语以开启生物识别解锁。';

  @override
  String get settingsDeletePassphraseReason => '请输入密码短语以删除此钱包。';

  @override
  String sendPassphraseReason(String amount) {
    return '输入密码短语以发送 $amount。';
  }

  @override
  String sendFilePassphraseReason(String amount) {
    return '输入密码短语以生成 $amount 的交易文件。';
  }

  @override
  String get passphraseSetTitle => '设置密码短语';

  @override
  String get deskSetReportFullDetails => '包含完整详情';

  @override
  String get deskSetReportPartFullDetails => '完整详情';

  @override
  String get deskSetReportFullDetailsInfo =>
      '地址和金额将完整发送而不是缩短。助记词、密钥和密码会先被移除；发送前请检查预览。';

  @override
  String get deskOutNoteWaitingRecipient => '等待接收方';

  @override
  String get deskSlotNotPosted => '付款不在网络上';

  @override
  String get txOtherWalletMore => '另一个钱包的付款';

  @override
  String get finalizeNotPostedHelp => '在“紧急断网”下付款';

  @override
  String get deskActSearchHintFull => '备注、联系人、地址或金额';

  @override
  String get deskOutFilterWaiting => '等待中';

  @override
  String deskRecvHeaderTip(String methods) {
    return '接收：$methods';
  }

  @override
  String deskSendHintNeedsMethod(String method) {
    return '确认需要 $method';
  }

  @override
  String get deskSetAboutVersionLabel => '版本';

  @override
  String get deskSetAboutNodeLabel => '节点';

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
      other: '已确认，$confirmationsString 个确认 · 区块 $block。',
    );
    return '$_temp0';
  }

  @override
  String deskKitNoAnswerSince(String time) {
    return '自 $time 起无响应';
  }

  @override
  String get deskKitMoreInHelp => '更多见帮助';

  @override
  String get homeReceiveEpicButton => '接收 EPIC';

  @override
  String txDeviceStatusMadeOn(String device) {
    return '在 $device 上发起。';
  }

  @override
  String txDeviceStatusHeld(String device) {
    return '在 $device 上发起。资金在此保留，直到链上出现该付款。';
  }

  @override
  String get deskSendEpicboxNodeOnly => '“仅节点”已开启：Epicbox 已关闭。直接 · 文件传输可用。';

  @override
  String deskSendEpicboxNodeOnlyTab(String method) {
    return '“仅节点”已开启：Epicbox 已关闭。$method 可用。';
  }

  @override
  String get deskSendLinkNodeOnly => '“仅节点”已开启：链接已关闭。直接 · 文件传输可用。';

  @override
  String deskSendLinkNodeOnlyTab(String method) {
    return '“仅节点”已开启：链接已关闭。$method 可用。';
  }

  @override
  String get deskSendKillSwitch => '“紧急断网”已开启：什么都不连接。直接 · 文件传输可用。';

  @override
  String deskSendKillSwitchTab(String method) {
    return '“紧急断网”已开启：什么都不连接。$method 可用。';
  }

  @override
  String get levelOneTitle => '只管收付款';

  @override
  String get levelOneLine => '钱进钱出，无需学习。';

  @override
  String get levelTwoTitle => '别太技术化，但告诉我发生了什么';

  @override
  String get levelTwoLine => '用平实的话说明钱包在做什么。';

  @override
  String get levelThreeTitle => '让我探索全部';

  @override
  String get levelThreeLine => '每个开关，每个数字。小心调节。';

  @override
  String get levelUndercoverTitle => '仅 Tor';

  @override
  String get levelFooter => '随时可在 设置 › 高级 中更改。';

  @override
  String get levelRowTitle => '钱包视图';

  @override
  String get levelChangeTitle => '更改视图';

  @override
  String get lvPickStopOne => '浅水';

  @override
  String get lvPickStopTwo => '再深些';

  @override
  String get lvPickStopThree => '深水区';

  @override
  String get lvPickLineOne => '收款、付款，就这样。其余交给钱包。';

  @override
  String get lvPickLineTwo => '用简单的话看到它在做什么。';

  @override
  String get lvPickLineThree => '每个开关、每个数字，全归你。';

  @override
  String get lvPickNone => '选一个档位';

  @override
  String get lvPickNoneLine => '预览随档位变化。';

  @override
  String get lvPickDepth => '视图';

  @override
  String get lvPickPreview => '主屏幕预览。档位越深，显示越多。';

  @override
  String get lvPickHelpTitle => '这决定什么';

  @override
  String get lvPickHelpText => '只决定应用显示多少。每个视图收付款的方式都一样，密钥和币也一样。';

  @override
  String get lvPickUndercoverHelp =>
      '仅 Tor，从第一次连接开始。所有连接都经过 Tor；启动会慢一些。\n\n目前还没有任何连接。与 网络模式 › 仅 Tor 相同；之后可在 设置 › 高级 中关闭。';

  @override
  String get lvPickUndercoverHelpNet =>
      '仅 Tor，从第一次连接开始。所有连接都经过 Tor；启动会慢一些。\n\n目前还没有任何连接。与 连接模式 › 仅 Tor 相同；之后可在 设置 › 网络与隐私 中关闭。';

  @override
  String get lvPickUndercover => '隐身';

  @override
  String get lvPickUndercoverLaterHelp =>
      '仅 Tor。所有连接都经过 Tor；启动会慢一些。在 Tor 被封锁的地方，关闭此项之前钱包无法连接。';

  @override
  String get lvPickTakesEffect => '立即生效。';

  @override
  String get lvPickSaved => '视图已保存';

  @override
  String get lvPickTorTitle => '正在通过 Tor 连接';

  @override
  String get lvPickTorLead => '第一次通过 Tor 连接可能需要一分钟。';

  @override
  String get lvPickTorBusy => '正在建立线路…';

  @override
  String get lvPickTorBlocked => '如果你所在的地方封锁了 Tor，关闭隐身之前钱包无法连接。';

  @override
  String get lvPickTorOff => '关闭隐身';

  @override
  String get lvPickTorOffDone => '隐身已关闭。正在直接连接。';

  @override
  String get lvPickNetworkOk => '网络 正常';

  @override
  String get lvPickEpicboxOk => 'Epicbox 正常';

  @override
  String get lvPayArriving => '即将到账';

  @override
  String lvPayConfirming(int count, int target) {
    return '确认中 $count/$target';
  }

  @override
  String lvPayConfirmingOf(int count, int target) {
    return '确认中 $count/$target';
  }

  @override
  String lvPaySigned(String name) {
    return '$name 已签名';
  }

  @override
  String get lvPaySendQrLink => '两部手机在一起？二维码付款';

  @override
  String get lvPaySendAddressLink => '改为发送到地址';

  @override
  String get lvPayOnItsWay => '已发出';

  @override
  String get lvPayCloseNote => '可以关闭此页。完成前会显示在“活动”中。';

  @override
  String lvPayArrivalFrom(String amount, String name) {
    return '$amount 来自 $name';
  }

  @override
  String get lvPayOpen => '打开';

  @override
  String get lvPayNewToday => '今日新增';

  @override
  String get lvPayNewAddress => '您的新地址';

  @override
  String lvPayServerLine(String name) {
    return 'Epicbox 服务器：$name。';
  }

  @override
  String get lvPayOldAddressLine => '持有旧地址的人需要使用新地址。';

  @override
  String get lvPayReceiveBack => '返回我的地址';

  @override
  String lvPayDoneSent(String when) {
    return '已发送。完成于 $when。';
  }

  @override
  String lvPayDoneReceived(String when) {
    return '已收到。完成于 $when。';
  }

  @override
  String get lvPayShowSteps => '显示步骤';

  @override
  String get lvPayHideSteps => '隐藏步骤';

  @override
  String get lvPayDetails => '详情';

  @override
  String get lvPayStarted => '开始于';

  @override
  String get lvPayPosted => '已发布到网络';

  @override
  String get lvPayPaymentId => '付款编号';

  @override
  String get lvPayConfirmations => '确认数';

  @override
  String lvPayOf(int count, int target) {
    return '$count/$target';
  }

  @override
  String get lvPayCopyDetails => '复制详情';

  @override
  String get lvPayDetailsCopied => '详情已复制';

  @override
  String lvShellStatusTip(String name, String state) {
    return '$name · $state';
  }

  @override
  String get lvShellStateBehind => '落后';

  @override
  String get lvShellStateCatchingUp => '正在同步';

  @override
  String get lvShellStateConnecting => '正在连接';

  @override
  String get lvShellOpensDetails => '显示详情';

  @override
  String get lvShellLatestBlock => '最新区块';

  @override
  String get lvShellThisWallet => '本钱包';

  @override
  String get lvShellUpToDate => '已是最新';

  @override
  String get lvShellNotChecked => '尚未检查';

  @override
  String get lvShellLastChange => '最近变更';

  @override
  String get lvShellBoxListening => '已连接 · 正在等待付款';

  @override
  String get lvShellBoxNotReachable => '无法连接 · 正在继续尝试';

  @override
  String get lvShellBoxDownBody => '发给你的付款会等待，服务器恢复后到账。除非你切换，否则什么都不会改变。';

  @override
  String lvShellOfferReady(String name) {
    return '$name 已就绪';
  }

  @override
  String lvShellOfferBody(String name) {
    return '切换后你会在 $name 上获得新地址。持有你旧地址的人需要新地址。';
  }

  @override
  String lvShellSwitchTo(String name) {
    return '切换到 $name';
  }

  @override
  String get lvShellKeepWaiting => '继续等待';

  @override
  String get lvShellRelayDownTitle => '你的 Epicbox 服务器无法连接。';

  @override
  String lvShellRelayDownShort(String name) {
    return '$name 可以接替；你的地址会随之改变。';
  }

  @override
  String get lvShellSwitch => '切换';

  @override
  String lvShellSwitchedNotice(String name) {
    return '已切换到 $name。你的新地址已就绪。';
  }

  @override
  String lvShellNowOn(String name) {
    return '已切换到 $name';
  }

  @override
  String get lvShellSwitchedBody => '你的新地址已就绪。持有你旧地址的人需要新地址。';

  @override
  String get lvShellShowNewAddress => '显示新地址';

  @override
  String get lvShellServer => '服务器';

  @override
  String get lvShellAddress => '地址';

  @override
  String lvShellPairNotice(String name) {
    return '$name 想与此钱包配对。';
  }

  @override
  String get lvShellSeeRequest => '查看请求';

  @override
  String lvShellQuietArriving(String amount) {
    return '+$amount 即将到账';
  }

  @override
  String lvShellQuietOnHold(String amount) {
    return '$amount 暂扣中';
  }

  @override
  String get lvShellLevelCaption => '更深的视图显示钱包的更多内容。已保存的内容不会改变。';

  @override
  String get lvPolPosted => '已广播';

  @override
  String get lvPolInvoiceWaiting => '账单 · 等待你批准';

  @override
  String lvPolAbout(String name) {
    return '关于$name';
  }

  @override
  String get deskLvStartPreviewLabel => '概览预览。档位越深，显示越多。';

  @override
  String get deskLvStartPreviewCaption => '此视图下的概览。已保存的内容不会改变。';

  @override
  String get deskLvStartCover => '选择一个档位以查看预览';

  @override
  String get deskLvStartUndercoverAbout => '关于仅 Tor';

  @override
  String get deskLvStartHelpShallow => '浅水 · 一个地址，不显示服务器名称，没有开关。';

  @override
  String get deskLvStartHelpDeeper => '再深些 · 同一个钱包，并用简单的话显示它在做什么。';

  @override
  String get deskLvStartHelpDeep => '深水区 · 每个开关、每个数字：现在的应用。';

  @override
  String get deskLvStartMiniWallet => '主钱包';

  @override
  String get deskLvStartMiniLine => '+12.5 即将到账 · 25.0 已冻结';

  @override
  String get deskLvStartMiniFresh => '刚挖出的币';

  @override
  String get deskLvStartMiniWaiting => '等待对方';

  @override
  String get deskLvSendHowTo => '发送方式';

  @override
  String get deskLvSendButton => '发送';

  @override
  String deskLvSendButtonAmount(String amount) {
    return '发送 $amount EPIC';
  }

  @override
  String deskLvSendButtonTo(String amount, String name) {
    return '向 $name 发送 $amount EPIC';
  }

  @override
  String get deskLvSendNothingLeaves => '按下“发送”之前不会发出任何内容。发出后无法撤回。';

  @override
  String get deskLvSendPasswordTitle => '你的密码';

  @override
  String get deskLvSendConfirm => '发送';

  @override
  String deskLvSendLiveTo(String name) {
    return '正在发往 $name';
  }

  @override
  String deskLvSendLiveAmountTo(String amount, String name) {
    return '$amount EPIC 给 $name';
  }

  @override
  String deskLvSendLiveAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskLvSendYourAddress => '你的地址';

  @override
  String get deskLvSendReady => '可以接收';

  @override
  String get deskLvSendClosedInfo => '钱包关闭期间发出的付款，会在钱包打开后到账。';

  @override
  String get deskLvSendPayFiles => '付款文件';

  @override
  String get deskLvSendSignFile => '签署付款文件';

  @override
  String get deskLvSendSignFileText => '打开发送方给你的文件，并保存你的回复。';

  @override
  String get deskLvSendFinishFile => '完成回复文件';

  @override
  String get deskLvSendFinishFileText => '打开收到的回复，以发布这笔付款。';

  @override
  String get deskLvSendPrevAddress => '旧地址';

  @override
  String deskLvSendPrevText(String server) {
    return '旧地址在 $server 上。拥有旧地址的人需要新地址。';
  }

  @override
  String get deskLvPayS1Sent => 'Slate S1 已通过 Epicbox 发出 · 等待 S2';

  @override
  String deskLvPayS1On(String relay) {
    return 'S1 已发到 $relay · 等待 S2';
  }

  @override
  String deskLvPayNotOpen(String name) {
    return '$name 的钱包尚未打开';
  }

  @override
  String deskLvPayWaitingOpen(String name) {
    return '等待 $name 的钱包打开';
  }

  @override
  String get deskLvPaySenderFinished => '发送方已完成';

  @override
  String get deskLvPayPostedNode => '已发布到节点';

  @override
  String deskLvPayConfirmingComma(int count, int target) {
    return '确认中，$count/$target';
  }

  @override
  String deskLvPayConfirmationsOf(int count, int target) {
    return '确认 $count / $target';
  }

  @override
  String get deskLvPayDone => '完成';

  @override
  String deskLvPayOnItsWayTo(String name) {
    return '正在发往 $name';
  }

  @override
  String deskLvPaySendingTo(String name) {
    return '正在发送给 $name';
  }

  @override
  String deskLvPayArrivingFrom(String name) {
    return '正在收取来自 $name 的付款';
  }

  @override
  String deskLvPayStartedAt(String amount, String time) {
    return '$amount EPIC · 开始于 $time';
  }

  @override
  String deskLvPayHeroArriving(String amount, String name) {
    return '+$amount 来自 $name，即将到账';
  }

  @override
  String deskLvPayHeroArrivingMany(String amount) {
    return '+$amount 即将到账';
  }

  @override
  String deskLvPayHeroHold(String amount, String name) {
    return '$amount 已冻结，等待 $name 签署';
  }

  @override
  String deskLvPayHeroHoldMany(String amount) {
    return '$amount 已冻结，等待签署';
  }

  @override
  String get deskLvPayHeroNothing => '暂时没有即将到账的付款。';

  @override
  String get deskLvPayReadyTitle => '你的钱包已就绪。';

  @override
  String get deskLvPayReadyHead => '钱包已就绪';

  @override
  String get deskLvPayReadyText => '分享地址即可收到第一笔 EPIC。';

  @override
  String get deskLvPayTileConfirming => '仍在确认';

  @override
  String get deskLvPayTileMining => '刚挖出的币';

  @override
  String get deskLvPayTileWaiting => '等待对方';

  @override
  String get deskLvPayTileAwaiting => '等待回复';

  @override
  String get deskLvPayTileLocked => '为付款预留';

  @override
  String get deskLvPayImmatureCasual => '刚挖出的币，暂不可用';

  @override
  String get deskLvPayKind => '付款';

  @override
  String get deskLvShellNewsTitle => '新功能：钱包视图';

  @override
  String get deskLvShellNewsText => '此安装显示全部内容，与以往相同。浅水和再深些显示得更少。';

  @override
  String get deskLvShellNewsLook => '去看看';

  @override
  String get deskLvShellFailover => '故障切换';

  @override
  String get deskLvShellOn => '开';

  @override
  String get deskLvShellHeight => '高度';

  @override
  String get deskLvShellVersion => '版本';

  @override
  String get deskLvShellRecheckHint => '如果金额看起来不对，钱包会重新读取区块链。';

  @override
  String get lvShellSwitchServer => '切换服务器';

  @override
  String get lvShellNoOtherServer => '列表中没有其他服务器。';

  @override
  String get deskLvShellSwitchServer => '切换服务器';

  @override
  String get deskLvShellNoOtherServer => '列表里没有其他服务器。';

  @override
  String get deskLastSessionFroze => '上次应用停止了响应。要发送日志吗？';

  @override
  String get deskLastSessionClosed => '上次应用意外关闭。要发送日志吗？';

  @override
  String get deskLastSessionSend => '发送';

  @override
  String get deskLastSessionNotNow => '以后再说';

  @override
  String get deskLastSessionReportFroze => '应用停止了响应。';

  @override
  String get deskLastSessionReportClosed => '应用意外关闭。';

  @override
  String get deskLastSessionAttached => '附带上次运行的日志。';

  @override
  String get deskSetPrivUndercoverLine => '隐身模式让 Tor 保持开启。';

  @override
  String get deskSetPrivUndercoverChange => '更改隐身设置';

  @override
  String get deskNodeEtaCalculating => '正在计算剩余时间…';

  @override
  String deskNodeEtaLeft(String time) {
    return '还需约 $time';
  }

  @override
  String get deskNodeEtaMinute => '一分钟';

  @override
  String deskNodeEtaMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String deskNodeEtaHours(int hours) {
    return '$hours 小时';
  }

  @override
  String deskNodeEtaHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String deskNodeSwitchConnecting(String host) {
    return '正在连接 $host…';
  }

  @override
  String get deskNodeSwitchStarting => '正在启动本地节点…';

  @override
  String get deskNodeSwitchStopping => '正在停止本地节点…';

  @override
  String get deskNodeSwitchStoppingWord => '正在停止';

  @override
  String get deskOnbFailedTitle => '未完成';

  @override
  String deskOnbRestoreBadWords(String words) {
    return '不在词表中：$words。';
  }

  @override
  String get deskLvPayOnEpicbox => '在 Epicbox 上';

  @override
  String get deskRailReceivingInternet => '接收中 · 互联网';

  @override
  String get deskRailReceivingLocal => '接收中 · 本地';

  @override
  String get deskOnbImportFoundLead => '继续以选择要添加的钱包。';

  @override
  String get deskOnbForgotFailedTitle => '密码未更改';

  @override
  String get deskOnbForgotFailedLead => '当前密码仍可打开钱包。';

  @override
  String get deskSetHelpSupportHead => '支持';

  @override
  String deskKitPasswordRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '至少 $count 个字符',
    );
    return '$_temp0';
  }

  @override
  String trustLineOtherApp(Object name) {
    return '$name 的上一笔付款由另一款钱包应用应答。';
  }

  @override
  String trustLineNotHeard(Object name, Object date) {
    return '自 $date 起未收到 $name 的钱包的任何消息。';
  }

  @override
  String get mailboxNotAnswered => '尚未应答';

  @override
  String get mailboxNotPickedUp => '未取件';

  @override
  String mailboxNeverPickedUp(Object name) {
    return '$name 的钱包从未收取这笔付款。';
  }

  @override
  String get mailboxResendTitle => '取消并经 Epicbox 发送';

  @override
  String mailboxResendBody(Object name) {
    return '等待中的付款将被取消，相同金额将作为普通付款发送到 $name 的 Epicbox 地址。历史记录中保留两行。';
  }

  @override
  String get mailboxResendAction => '取消并发送';

  @override
  String get mailboxKeepWaiting => '继续等待';

  @override
  String get linkPayeeLead => '收款方';

  @override
  String get linkPayeeMid => '收款方';

  @override
  String get linkResendBody => '等待中的付款将被取消，“发送”会以相同金额打开。请核对地址，然后重新发送。';

  @override
  String receiptTellSent(Object name) {
    return '告知 $name 已发送';
  }

  @override
  String receiptTellPosted(Object name) {
    return '告知 $name 已发往网络';
  }

  @override
  String receiptTold(Object name) {
    return '已告知 $name';
  }

  @override
  String receiptSeesSent(Object name, Object id, Object amount, Object time) {
    return '$name 将看到：请求 $id、$amount、发送于 $time。不会附带其他内容：没有地址，也没有交易 ID。';
  }

  @override
  String receiptSeesPosted(Object name, Object id, Object amount, Object time) {
    return '$name 将看到：请求 $id、$amount、$time 已发往网络。不会附带其他内容：没有地址，也没有交易 ID。';
  }

  @override
  String receiptNotSent(Object name) {
    return '暂时无法告知 $name，请重试。';
  }

  @override
  String get receiptHintTitle => '回执';

  @override
  String get mailboxResent => '已取消并经 Epicbox 发送。';

  @override
  String get torRelayCaption => '开启 Tor 后，与 Epicbox 服务器的连接经由 Tor。';

  @override
  String get inviteLinkUnreadable => '无法打开此链接。';

  @override
  String inviteLinkNoHandler(String feature) {
    return '“$feature”已关闭或在此钱包中不可用。';
  }

  @override
  String get linkShowMine => '显示我的二维码';

  @override
  String get linkPasteAnother => '粘贴另一个邀请';

  @override
  String linkLinkingWith(String name) {
    return '正在与 $name 关联…';
  }

  @override
  String linkLinkingSame(String name) {
    return '$name 显示相同的四张图片。';
  }

  @override
  String linkFailFull(String name) {
    return '$name 已关联了另一台设备。请先在 $name 上移除那台设备。';
  }

  @override
  String get linkFailUpdate => '另一台设备的应用版本更新。请更新此设备后重试。';

  @override
  String linkFailUpdateOther(String name) {
    return '$name 的应用版本较旧。请在那里更新后重试。';
  }

  @override
  String linkReplaceTitle(String name) {
    return '替换 $name？';
  }

  @override
  String linkReplaceBody(String name) {
    return '一台新设备请求关联。$name 将不再收到此钱包的消息；它在这里保留的币会被释放。';
  }

  @override
  String get linkReplace => '替换';

  @override
  String linkKeep(String name) {
    return '保留 $name';
  }

  @override
  String devicesEpicboxOff(String name) {
    return 'Epicbox 已关闭：$name 看不到此设备的付款。';
  }

  @override
  String get devicesEpicboxOffNone => 'Epicbox 已关闭。';

  @override
  String devicesUpdateOther(String name) {
    return '请更新 $name，以保持此钱包同步。';
  }

  @override
  String get devicesAbout => '关于关联设备';

  @override
  String get offerLinkThird => '第三台设备持有此钱包。只能关联两台。';

  @override
  String devicesForwardedInvoice(String name) {
    return '$name 收到了一个付款请求。请在那里支付。';
  }

  @override
  String get linkConfirmInvite => '将此设备与发送邀请的设备关联？';

  @override
  String get pairYourCode => '你的邀请';

  @override
  String get pairCodeCaption => '让对方扫描二维码，或发送邀请。';

  @override
  String pairCodeCaptionFor(String name) {
    return '让 $name 扫描二维码，或发送邀请。';
  }

  @override
  String pairSeenAsLine(String name) {
    return '对方看到你的名字是 $name';
  }

  @override
  String get pairChange => '更改';

  @override
  String get pairSeenAsField => '对方看到你的名字';

  @override
  String get pairCopyLink => '复制邀请';

  @override
  String get pairHaveTheirCode => '有对方的邀请？';

  @override
  String pairHaveNamesCode(String name) {
    return '有 $name 的邀请？';
  }

  @override
  String get pairScan => '扫描二维码';

  @override
  String get pairPasteField => '粘贴邀请';

  @override
  String get pairNotACode => '这不是配对邀请。';

  @override
  String get pairEpicboxOffLine => 'Epicbox 已关闭。收到回复后请在下方粘贴。';

  @override
  String get pairWaitingAnswer => '等待回复…';

  @override
  String pairAnsweredFinishing(String name) {
    return '$name 已回复你的邀请。等待 $name 的钱包完成。';
  }

  @override
  String get pairFinishCodeTitle => '确认';

  @override
  String pairFinishCodeBody(String name) {
    return '把它发给 $name。对方钱包读取后，会打开词语核对。';
  }

  @override
  String get pairYourAnswerBody => '按邀请来的方式发回去。然后粘贴收到的内容。';

  @override
  String get pairPasteFinishField => '粘贴确认';

  @override
  String pairPairingWith(String name) {
    return '正在与 $name 配对…';
  }

  @override
  String get pairInContacts => '在你的联系人中';

  @override
  String get pairRequestBody => '请求会发送到该联系人的 Epicbox 地址。对方钱包打开时会显示。';

  @override
  String get pairSendRequest => '发送请求';

  @override
  String get pairShowMyCodeInstead => '改为显示我的邀请';

  @override
  String pairRequestSent(String date) {
    return '请求已发送 · $date';
  }

  @override
  String pairWaitingFor(String name) {
    return '等待 $name 的钱包';
  }

  @override
  String get pairAnsweredNotHeard => '已回复你的邀请 · 尚无消息';

  @override
  String pairNotChecked(String name) {
    return '$name 尚未核对';
  }

  @override
  String contactTakesPaymentsAgain(String name) {
    return '$name 现在接受付款。';
  }

  @override
  String get pairIsService => '自动化服务。';

  @override
  String pairConfirmedToo(String name) {
    return '$name 也已确认。';
  }

  @override
  String get pairEndedShort => '配对已结束';

  @override
  String get pairEndedMismatch => '你报告了词语不一致。';

  @override
  String pairEndedPeerMismatch(String name) {
    return '$name 报告了词语不一致。';
  }

  @override
  String pairEndedNeverFinished(String name) {
    return '$name 的钱包始终未完成。';
  }

  @override
  String get pairEndedRowPeerMismatch => '报告了词语不一致。';

  @override
  String get pairEndedRowNeverFinished => '其钱包始终未完成。';

  @override
  String get pairEndedRowUnpaired => '已移除配对。';

  @override
  String pairNoAnswerFrom(String name) {
    return '$name 的钱包没有回复';
  }

  @override
  String get pairAgain => '重新配对';

  @override
  String get pairAddressNotConfirmed => '地址未经配对确认。';

  @override
  String get pairHeldSend => '等待收款方';

  @override
  String pairProvesOther(String name) {
    return '$name 的钱包证明了另一个地址';
  }

  @override
  String get pairUpdateAddress => '更新联系人的地址';

  @override
  String get pairDetach => '解除关联';

  @override
  String get pairCheckWords => '核对词语';

  @override
  String pairWantsToPair(String name) {
    return '$name 想要配对。';
  }

  @override
  String pairPairedWith(String name) {
    return '已与 $name 配对。';
  }

  @override
  String pairPairedOn(String device) {
    return '已在 $device 上配对。';
  }

  @override
  String pairRequestsRow(int count) {
    return '配对请求 · $count';
  }

  @override
  String get pairRequestsTitle => '配对请求';

  @override
  String get pairEndedNotice => '配对已结束。请用新的邀请重新配对。';

  @override
  String get pairOtherWalletTitle => '这个回复来自另一个钱包。';

  @override
  String get pairOtherWalletBody => '没有保存任何内容。';

  @override
  String get pairKindDiffersTitle => '此回复与邀请不匹配。';

  @override
  String get pairKindDiffersBody => '其中的联系人类型与邀请不同。未保存任何内容。请重新配对。';

  @override
  String pairNotProvenBody(String name) {
    return '尚未与 $name 有过 Epic Cash 付款，无法发送请求。';
  }

  @override
  String pairInProgressTitle(String name) {
    return '与 $name 的配对正在进行。';
  }

  @override
  String pairCrossedTitle(String name) {
    return '$name 的钱包也发起了配对。正在等待其回复。';
  }

  @override
  String pairDismissedTitle(String name) {
    return '该请求已被忽略。请让 $name 重新发送。';
  }

  @override
  String get pairEndedBody => '不会再有新内容通过它。移除它，或用新的邀请重新配对。';

  @override
  String get pairWaitingSendBody => '请改用 Epicbox 发送。';

  @override
  String get pairNotFoundTitle => '没有与此匹配的配对。';

  @override
  String get trustWaiting => '等待中';

  @override
  String get trustEnded => '已结束';

  @override
  String get trustNotAnswering => '没有响应';

  @override
  String get contactNotAnsweringBody => '账单和付款可能无法送达对方。';

  @override
  String get pairRequestPair => '配对';

  @override
  String get pairCancelPairingTitle => '取消这次配对？';

  @override
  String pairCancelPairingBody(String name) {
    return '如果 $name 的钱包迟来回复，会被告知。不会保留任何内容。';
  }

  @override
  String get pairCancelPairing => '取消配对';

  @override
  String get pairBackLater => '返回';

  @override
  String get helpPairTwoWaysTitle => '两种配对方式';

  @override
  String get helpPairTwoWaysShort => '向联系人发送请求，或使用你的邀请。';

  @override
  String get helpPairTwoWaysP1 =>
      '**与联系人配对。** 对于你曾通过 Epicbox 付款或收款的联系人，“配对”会向该地址发送请求。对方钱包打开时会显示，点一下即可回复。双方都直接成为“已验证”，无需核对词语：请求和回复各自证明了对方联系人中已有的地址。';

  @override
  String get helpPairTwoWaysP2 =>
      '**通过邀请配对。** 联系人 › 配对 显示你的邀请，有效期 7 天。对方钱包扫描它或打开链接；双方通过 Epicbox 完成，然后核对四个词语。若任一方关闭了 Epicbox，同一屏幕会以手动方式传递回复和确认：分享与粘贴。';

  @override
  String get helpPairTwoWaysP3 =>
      '请求只会发给已证明运行 BT Wallet 的钱包：最近 30 天内两个地址之间有一笔带标记的付款。对其他人，“配对”会显示你的邀请。';

  @override
  String get helpPairWhyTitle2 => '为什么要核对词语';

  @override
  String get helpPairWhyShort2 => '当面、通话或视频核对。';

  @override
  String get helpPairWhyP1b =>
      '通过邀请配对后，两个钱包显示相同的四个图片和名称。请与对方当面、通话或视频核对，绝不要在传来邀请的聊天里核对：能在途中篡改邀请的人，也能篡改那个聊天显示的内容。';

  @override
  String get helpPairWhyP2b =>
      '**一致** 将联系人标为已验证；对方钱包会得知并显示“也已确认”。**不一致** 会在双方结束配对，通过它发送的内容都不会完成。误点“否”同样会结束：请用新的邀请重新配对。';

  @override
  String get helpPairWhyP3b =>
      '已验证表示你的联系人中该地址背后的钱包。两个联系人之间的请求完成后无需词语即可设为已验证，因为请求和回复都证明了该地址。';

  @override
  String get helpPairWhyP4b =>
      '“已证明”指最近 30 天内两个 Epicbox 地址之间有一笔双方钱包都标记的付款。此后由另一款钱包应用回复过的联系人，在下一笔带标记的付款之前不算已证明。';

  @override
  String get pairStandingFootnote => '有效期 7 天。此邀请被使用后会出现新的邀请。';

  @override
  String get storeEncrypting => '正在加密钱包记录…';

  @override
  String get storeRecordsPlain => '钱包记录暂时保持未加密。下次启动时会再次尝试。';

  @override
  String get errorStoreWrongKey => '无法用此助记词打开该钱包的记录。未做任何更改。';

  @override
  String get contactsClosedTitle => '通讯录已关闭';

  @override
  String get contactsClosedText => '解锁使用该通讯录的钱包后即可打开。';

  @override
  String get pairSeenAsHint => '可选';

  @override
  String devicesNameWithCode(String name, String code) {
    return '$name $code';
  }

  @override
  String get deskSetDlgRemoveUnlockHintSecurity =>
      '如果还要删除它的文件，请解锁此钱包，然后使用“设置 › 钱包”中的“删除钱包”。';

  @override
  String get deskRecvHttpTorHintNet => '如需 Tor 地址，请在“设置 › 网络与隐私”中开启 Tor。';

  @override
  String get deskRecvTorIntroNet =>
      '本钱包打开时，经由 Tor 直接从另一个钱包接收。Tor 在“设置 › 网络与隐私”中设置。';

  @override
  String get deskRecvTorOffTextNet =>
      'Tor 开启时，Tor 地址才可用。Tor 是设置 › 网络与隐私中的开关，它让钱包的连接走 Tor。';

  @override
  String get deskRailOpenNetworkPrivacy => '打开网络与隐私';

  @override
  String get deskSetSearchHint => '搜索设置';

  @override
  String get deskSetSearchKeyHint => 'Ctrl K';

  @override
  String get deskSetSearchClear => '清除搜索';

  @override
  String deskSetSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个结果',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchFor(String query) {
    return '搜索“$query”';
  }

  @override
  String get deskSetSearchKeysMove => '移动';

  @override
  String get deskSetSearchKeysGo => '前往设置';

  @override
  String get deskSetSearchKeysClear => '清除';

  @override
  String deskSetSearchMatches(String word) {
    return '匹配“$word”';
  }

  @override
  String get deskSetSearchHelpTopics => '帮助主题';

  @override
  String get deskSetSearchHidden => '此处隐藏';

  @override
  String get deskSetSearchHiddenLine => '其他视图或“高级”中的开关会显示它们';

  @override
  String deskSetSearchShowIn(String view) {
    return '在$view中显示';
  }

  @override
  String get deskSetSearchTurnOn => '开启';

  @override
  String get deskSetSearchOpen => '打开';

  @override
  String get deskSetSearchRead => '阅读';

  @override
  String deskSetSearchNone(String query) {
    return '没有与“$query”匹配的设置。';
  }

  @override
  String get deskSetSearchTry => '试试';

  @override
  String get deskSetSearchTryWords => '密码,tor,助记词,备份,手续费,节点,锁定';

  @override
  String get deskSetSearchNoResults => '无结果';

  @override
  String get deskSetSearchResults => '搜索结果';

  @override
  String deskSetSearchViewGate(String view) {
    return '$view视图';
  }

  @override
  String deskSetSearchFeatGate(String feature) {
    return '高级 › $feature';
  }

  @override
  String deskSetSearchGateJoin(String first, String last) {
    return '$first和$last';
  }

  @override
  String deskSetSearchMore(int count, String gates) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 个选项 · 由$gates显示',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchLess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '隐藏 $count 个额外选项',
      one: '隐藏额外选项',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchViewApplied(String view) {
    return '视图：$view';
  }

  @override
  String deskSetSearchFeatApplied(String feature) {
    return '高级 › $feature：已开启';
  }

  @override
  String deskSetSearchFallbackView(String page, String view) {
    return '$page在$view视图中显示。';
  }

  @override
  String deskSetSearchFallbackFeat(String page, String feature) {
    return '开启高级 › $feature 后显示$page。';
  }

  @override
  String get deskSetSecWallet => '钱包';

  @override
  String get deskSetSecPayments => '支付';

  @override
  String get deskSetSecDevices => '关联设备';

  @override
  String get deskSetSecWallets => '钱包列表';

  @override
  String get deskSetSecFiles => '文件与日志';

  @override
  String get deskSetNavApp => '应用';

  @override
  String get deskSetNavComputer => '这台电脑';

  @override
  String get deskSetGrpBackup => '备份';

  @override
  String get deskSetGrpBalance => '余额';

  @override
  String get deskSetGrpRemove => '移除';

  @override
  String get deskSetGrpMethods => '方式';

  @override
  String get deskSetGrpSending => '发送';

  @override
  String get deskSetGrpReceiving => '接收';

  @override
  String get deskSetGrpThisDevice => '此设备';

  @override
  String get deskSetGrpLinkedDevice => '关联设备';

  @override
  String get deskSetGrpSync => '同步';

  @override
  String get deskSetGrpConnection => '连接';

  @override
  String get deskSetGrpLocalNode => '这台电脑上的节点';

  @override
  String get deskSetGrpConnections => '连接方式';

  @override
  String get deskSetGrpTor => 'Tor';

  @override
  String get deskSetGrpServerStatus => '服务器状态';

  @override
  String get deskSetGrpView => '视图';

  @override
  String get deskSetGrpShowsMore => '显示更多';

  @override
  String get deskSetGrpExperiments => '实验功能';

  @override
  String get deskSetGrpOnComputer => '这台电脑上';

  @override
  String get deskSetGrpAddWallet => '添加钱包';

  @override
  String get deskSetGrpFolders => '文件夹';

  @override
  String get deskSetGrpLogs => '日志';

  @override
  String get deskSetGrpSupport => '支持';

  @override
  String get deskSetGrpStartAgain => '重新开始';

  @override
  String get deskSetGrpLinks => '链接';

  @override
  String get deskSetRowNameHint => '只在此应用中显示。';

  @override
  String get deskSetSynName => '重命名, 钱包名称, 标签, 名称';

  @override
  String get deskSetRowExportDataHint => '历史、联系人、发票和设置，存于一个加密文件。';

  @override
  String get deskSetRowExportDataInfo => '只有使用此助记词的钱包能打开该文件。币本身由助记词恢复。';

  @override
  String get deskSetSynExportData => '备份, 保存, 历史, 联系人, 文件';

  @override
  String get deskSetRowImportDataHint => '从导出文件恢复历史、联系人、发票和设置。';

  @override
  String get deskSetSynImportData => '恢复, 备份, 历史, 载入';

  @override
  String get deskSetRowExportCsvHint => '用于电子表格的普通表格。未加密。';

  @override
  String get deskSetSynExportCsv => 'csv, excel, 表格, 税, 历史, 报表';

  @override
  String get deskSetRowRecheckGoHint => '重新读取区块链，查找此钱包的币。';

  @override
  String get deskSetSynRecheckGo => '重新扫描, 扫描, 余额不对, 丢失, 重新同步, 刷新, 修复';

  @override
  String get deskSetRowDeleteWalletHint => '从这台电脑删除它的密钥和数据库。';

  @override
  String get deskSetSynDeleteWallet => '移除, 删除, 清除';

  @override
  String get deskSetSynRecheckFrom => '开始, 日期, 高度, 区块';

  @override
  String get deskSetRowRecheckDropHint => '同时取消未确认的交易。正在途中的付款可能因此失败。';

  @override
  String get deskSetSynRecheckDrop => '未确认, 卡住, 取消, 解锁';

  @override
  String get deskSetRowPhraseGoHint => '恢复此钱包的 24 个单词。';

  @override
  String get deskSetSynPhraseGo => '种子, seed, 助记词, 单词, 备份, 秘密, 恢复, 24 个单词, 私钥';

  @override
  String get deskSetRowPasswordHint => '解锁此钱包。';

  @override
  String get deskSetSynPassword => '密码, 口令, 修改密码, 解锁, pin';

  @override
  String get deskSetRowRememberedHint => '启动时无需密码即可打开。发送时仍需输入。';

  @override
  String get deskSetSynRemembered => '记住我, 密码, 解锁, 自动解锁, 忘记';

  @override
  String get deskSetRowAutolockHint => '无按键或鼠标移动时锁定。所有钱包。';

  @override
  String get deskSetSynAutolock => '锁定, 超时, 空闲, 无操作, 锁屏';

  @override
  String get deskSetRowEpicboxHint => '通过 Epicbox 服务器付款和收款。大多数付款走这里。所有钱包。';

  @override
  String get deskSetSynEpicbox => '中继, 服务器, 地址, 接收, 发送, 方式';

  @override
  String get deskSetSynEpicboxRecv => '监听, 传入, 接收';

  @override
  String get deskSetRowEpicboxServerHint => '此钱包地址的一部分。';

  @override
  String get deskSetSynEpicboxServer => '中继, 服务器, 主机, 地址';

  @override
  String get deskSetSynEpicboxStart => '启动, 自动启动';

  @override
  String get deskSetRowHttpHint => '在网址上钱包对钱包，双方都需打开。所有钱包。';

  @override
  String get deskSetSynHttp => 'http, ip, 端口, 直连, 监听, 方式';

  @override
  String get deskSetSynHttpReach => '互联网, 路由器, 端口转发, 公网';

  @override
  String get deskSetSynHttpPort => '端口, tcp';

  @override
  String get deskSetRowTorPayHint => '在此钱包的 Tor 地址上钱包对钱包，双方都需打开。所有钱包。';

  @override
  String get deskSetRowTorPayInfo =>
      'Tor 只用于在 Tor 地址上收发付款。节点、价格和更新沿用“网络与隐私”中的设置。';

  @override
  String get deskSetSynTorPay => 'tor, 洋葱, 隐藏服务, 隐私, 方式';

  @override
  String get deskSetRowFileHint => '通过交换交易文件。无需网络。所有钱包。';

  @override
  String get deskSetSynFile => '文件, 离线, slate, 交易文件, usb, 方式, 手动';

  @override
  String get deskSetRowDefaultMethodHint => '“发送”打开时使用的方式。所有钱包。';

  @override
  String get deskSetSynDefaultMethod => '发送, 方式, 默认';

  @override
  String get deskSetRowStrategy => '发送使用的输出';

  @override
  String get deskSetRowStrategyHint => '最小：刚好够金额；全部：花掉每个输出。';

  @override
  String get deskSetRowStrategyInfo => '花掉的输出越多，手续费越高。';

  @override
  String get deskSetSynStrategy => '手续费, 费用, 策略, 选币, 输入, utxo, 输出';

  @override
  String get deskSetRowSplitChangeHint => '剩余不多时，找零最多分成 4 个输出返回。';

  @override
  String get deskSetRowSplitChangeInfo =>
      '仅当发送后可花费的输出少于 3 个且找零至少 1 EPIC 时。每多一个输出花费 0.004 EPIC。';

  @override
  String get deskSetSynSplitChange => '手续费, 找零, 输出, utxo, 拆分';

  @override
  String get deskSetRowConfirmationsHint => '收到的付款可花费前需等待的区块数。';

  @override
  String get deskSetSynConfirmations => '确认, 区块, 可花费, 锁定, 待处理, 等待';

  @override
  String get deskSetRowPairShopHint => '你允许的已配对联系人可以向此钱包发送发票。';

  @override
  String get deskSetSynPairShop => '配对, 发票, 商店, 交易所, 商家';

  @override
  String get deskSetRowTimeToPayHint => '发票可支付的时长。';

  @override
  String get deskSetSynTimeToPay => '发票, 过期, 到期, 期限';

  @override
  String get deskSetSynDeviceName => '设备名称, 重命名';

  @override
  String get deskSetRowLinkDeviceHint => '此钱包在两台设备上：每台显示另一台的付款。';

  @override
  String get deskSetRowLinkDeviceInfo =>
      '可以关联一台设备。已关联的设备会互相告知正在花费哪些币，所以通常会选不同的币。如果两台花了同一个币，区块链只接受一笔付款，另一笔会失败。';

  @override
  String get deskSetSynLinkDevice => '关联设备, 配对手机, 第二台设备, 手机, 同步, 移动端, 多设备';

  @override
  String get deskSetRowPauseSyncHint => '暂停期间，通知在服务器上等待。';

  @override
  String get deskSetSynPauseSync => '同步, 暂停, 关联';

  @override
  String get deskSetSynTheme => '深色模式, 浅色模式, 颜色, 夜间, dark mode';

  @override
  String get deskSetSynLanguage => '语言, 翻译, 中文, english, polski';

  @override
  String get deskSetRowScaleHint => '文字和控件，放大或缩小。';

  @override
  String get deskSetSynScale => '缩放, 大小, 字号, 放大, 缩小, 文字大小, dpi';

  @override
  String get deskSetRowHideAmountsHint => '用圆点代替余额和金额。';

  @override
  String get deskSetSynHideAmounts => '隐私, 隐藏余额, 遮盖, 屏幕共享, 直播';

  @override
  String get deskSetRowNodeServerHint => '读取区块链并发送此钱包的交易。';

  @override
  String get deskSetSynNodeServer => '节点, 服务器, 主机, rpc, api, url';

  @override
  String get deskSetRowFailover => '自动切换节点';

  @override
  String get deskSetRowFailoverHint => '节点不再响应时，改用下一个可用的。';

  @override
  String get deskSetSynFailover => '故障转移, 备用, 自动';

  @override
  String get deskSetRowMyNodeHint => '直接向节点询问其状态，并提供所有者访问。';

  @override
  String get deskSetSynMyNode => '自己的节点, 我的节点, 自建, 所有者, api secret';

  @override
  String get deskSetRowLocalNode => '这台电脑上的节点';

  @override
  String get deskSetRowLocalNodeHint => '在这里运行自己的节点。需要几 GB 磁盘空间。';

  @override
  String get deskSetSynLocalNode => '本地节点, 内置节点, 全节点, 运行节点, 同步区块链';

  @override
  String get deskSetRowLocalStartHint => '应用打开时保持节点同步。';

  @override
  String get deskSetSynLocalStart => '启动, 本地节点';

  @override
  String get deskSetRowNetMode => '连接模式';

  @override
  String get deskSetSynNetMode =>
      '仅 tor, undercover, 离线, 断网开关, 仅节点, vpn, ip, 隐私, 飞行模式';

  @override
  String get deskSetRowStatusSiteHint => '显示哪些节点和 Epicbox 服务器在线。';

  @override
  String get deskSetSynStatusSite => '状态, 健康, 在线时间, 监控';

  @override
  String get deskSetRowView => '视图';

  @override
  String get deskSetRowViewHint => '浅水、再深些或深水区：钱包显示多少内容。';

  @override
  String get deskSetSynView => '级别, 深度, 浅水, 再深些, 深水区, 简单, 专家, 新手, 高级模式';

  @override
  String get deskSetRowAdvOutputsHint => '“输出”页：组成余额的币。';

  @override
  String get deskSetSynAdvOutputs => 'utxo, 币, 输出, 拆分, 合并';

  @override
  String get deskSetRowAdvTechHint => '每笔交易的 kernel、slate ID 和承诺。';

  @override
  String get deskSetSynAdvTech => 'kernel, slate, 承诺, 交易 id, 详情';

  @override
  String get deskSetRowAdvSendoptsHint => '发送时和“支付”下的输出与找零选项。';

  @override
  String get deskSetSynAdvSendopts => '手续费, 选币, 输出, 找零';

  @override
  String get deskSetRowAdvServersHint => '服务器列表中的主机、延迟、版本和高度。';

  @override
  String get deskSetSynAdvServers => '延迟, ping, 高度, 版本, 主机';

  @override
  String get deskSetRowAdvHeightHint => '“重新核对余额”中的起点和删除未确认。';

  @override
  String get deskSetSynAdvHeight => '重新扫描, 高度, 区块';

  @override
  String get deskSetRowAdvLocalHint => '在这台电脑上运行节点，位于“节点”下。';

  @override
  String get deskSetSynAdvLocal => '全节点, 本地节点';

  @override
  String get deskSetRowAdvLogsHint => '“文件与日志”中的日志级别和日志文件。';

  @override
  String get deskSetSynAdvLogs => '日志, 调试, 诊断';

  @override
  String get deskSetRowXInvoicesHint => '向已配对联系人请求付款；批准他们的请求。';

  @override
  String get deskSetSynXInvoices => '发票, 请求付款, 配对, 账单';

  @override
  String get deskSetRowWalletRows => '钱包列表';

  @override
  String get deskSetRowWalletRowsHint => '这台电脑上的钱包；打开或移除一个。';

  @override
  String get deskSetSynWalletRows => '钱包, 切换钱包, 其他钱包, 列表';

  @override
  String get deskSetRowCreateWalletHint => '新钱包，配新的助记词。';

  @override
  String get deskSetSynCreateWallet => '新钱包, 添加钱包';

  @override
  String get deskSetRowImportWalletsHint => '从旧版 Epic Wallet 或文件夹导入。';

  @override
  String get deskSetSynImportWallets => '迁移, 旧钱包, electron, gui 钱包, 文件夹';

  @override
  String get deskSetRowRestoreWalletHint => '用 24 个单词的助记词恢复。';

  @override
  String get deskSetSynRestoreWallet => '种子, seed, 恢复, 助记词';

  @override
  String get deskSetRowWalletFolderHint => '此钱包的密钥和数据库。';

  @override
  String get deskSetSynWalletFolder => '数据文件夹, 目录, 路径, 文件, 位置';

  @override
  String get deskSetRowAppFilesHint => 'settings.toml 和日志。';

  @override
  String get deskSetSynAppFiles => '设置文件, settings.toml, 配置, toml, 目录';

  @override
  String get deskSetRowLogLevelHint => '详细会保留更多行；报告不含地址。';

  @override
  String get deskSetSynLogLevel => '日志, 调试, 详细';

  @override
  String get deskSetRowLogFilesHint => '清除日志文件或打开其文件夹。';

  @override
  String get deskSetSynLogFiles => '日志, 清除日志, 删除日志';

  @override
  String get deskSetRowReportHint => '描述出了什么问题；可附上清理后的应用日志。';

  @override
  String get deskSetSynReport => '错误, bug, 问题, 支持, 崩溃, 错误报告';

  @override
  String get deskSetSynTour => '导览, 教程, 介绍, 引导';

  @override
  String get deskSetRowSetup => '重新运行设置';

  @override
  String get deskSetRowSetupHint => '节点和接收，逐步设置。';

  @override
  String get deskSetSynSetup => '设置, 向导, 助手, 重新配置';

  @override
  String get deskSetRowUpdatesHint => '检查新版本。';

  @override
  String get deskSetSynUpdates => '更新, 升级, 新版本, 下载, 发布';

  @override
  String get deskSetRowWebsite => '网站';

  @override
  String get deskSetSynWebsite => '网站, 网页, 官网, epic cash';

  @override
  String get deskSetSynSource => 'github, 代码, 源代码, 开源, 仓库';

  @override
  String get deskSetSynPrivacyPolicy => '隐私, 政策, gdpr, 数据';

  @override
  String get deskSetAcctBackup => '备份';

  @override
  String get deskSetAcctBalance => '余额';

  @override
  String get deskSetAcctRemove => '删除';

  @override
  String get deskSetAdvViewLineOne => '发送、收款和备份。节点和 Epicbox 服务器自动选择。';

  @override
  String get deskSetAdvViewLineTwo => '增加付款方式、节点、网络模式和更多钱包。';

  @override
  String get deskSetAdvViewLineThree => '增加输出、发票、本地节点和所有高级开关。';

  @override
  String get deskSetAdvExperiments => '实验功能';

  @override
  String get deskSetFrameBack => '钱包';

  @override
  String get deskSetFrameBackTip => '返回钱包（Esc）';

  @override
  String deskSetFrameBackTo(String page) {
    return '返回$page';
  }

  @override
  String get deskSetFrameEscKey => 'Esc';

  @override
  String get deskSetFrameEscHint => '返回钱包';

  @override
  String get deskSetFrameExperiment => '实验';

  @override
  String get deskSetHelpReportButton => '报告…';

  @override
  String get deskSetHelpSetupAgain => '重新运行设置';

  @override
  String get deskSetHelpSetupHint => '节点和收款，逐步设置。';

  @override
  String get deskSetHelpStartAgain => '重新开始';

  @override
  String get deskSetHelpTourStart => '开始导览';

  @override
  String get deskSetFilesFolders => '文件夹';

  @override
  String get deskSetNodeConnection => '连接';

  @override
  String get deskSetNodeFailover => '自动切换节点';

  @override
  String get deskSetNodeStatus => '状态';

  @override
  String get deskSetPrivTorAll => '所有连接都走 Tor';

  @override
  String get deskSetPrivServerStatus => '服务器状态';

  @override
  String get deskSetPrivMode => '连接模式';

  @override
  String get deskSetTxSending => '发送';

  @override
  String get deskSetTxTorPayHint =>
      'Tor 只用于在 Tor 地址收发付款。节点、价格和更新沿用“网络与隐私”中的设置。所有钱包。';

  @override
  String get deskSetWalletsOnComputer => '此电脑上';

  @override
  String get deskSetSearchKeyEnter => 'Enter';

  @override
  String get deskSetSearchKeyEsc => 'Esc';

  @override
  String get deskTorPayOff => '关闭';

  @override
  String get deskTorPayStarting => '正在启动 Tor · 仅用于付款';

  @override
  String get deskTorPayReady => '正在接收';

  @override
  String deskTorPayBlockedNodeOnly(String mode) {
    return '在$mode下关闭：只有节点会连接。';
  }

  @override
  String deskTorPayBlockedKill(String mode) {
    return '在$mode下关闭：不会有任何连接。';
  }

  @override
  String get deskTorPayFailed => 'Tor 未能连接。';

  @override
  String deskTorPayFailedWhy(String problem) {
    return 'Tor 未能连接：$problem。';
  }

  @override
  String get deskTorPayRestOn => '所有连接都走 Tor：开启（网络与隐私）。';

  @override
  String get deskTorPayRestOff => '所有连接都走 Tor：关闭（网络与隐私）。';

  @override
  String get deskRailTorForPayments => '用于付款';

  @override
  String get deskBarKeySearch => '搜索设置';

  @override
  String get deskBarKeySearchHere => '在设置中搜索';

  @override
  String get deskHttpLocalTitle => '本地网络';

  @override
  String get deskHttpLocalSwitch => '在本机接收';

  @override
  String get deskHttpPublicTitle => '互联网';

  @override
  String deskHttpPublicNote(String port) {
    return '供互联网上的钱包使用。路由器需将端口 $port 转发到这台电脑。';
  }

  @override
  String deskKitMethodHttpNotReachable(String port) {
    return '仅限本地网络。要从互联网收款，路由器需要把端口 $port 转到这台电脑。';
  }

  @override
  String get sendRouteLinkHttps => '链接 · HTTPS';

  @override
  String get sendRouteThisPhone => '这部手机';

  @override
  String get sendRouteThisComputer => '这台电脑';

  @override
  String get sendRouteYourNetwork => '你的网络';

  @override
  String get sendRouteOverTor => '经由 Tor';

  @override
  String get sendRouteTorStarts => '发送时会启动 Tor。';

  @override
  String get sendRouteChange => '更改';

  @override
  String sendRouteChangeSem(int count) {
    return '更改地址，另有 $count 个';
  }

  @override
  String sendRouteAddressesOf(String name) {
    return '$name 的地址';
  }

  @override
  String sendRouteMore(int count) {
    return '另有 $count 个';
  }

  @override
  String sendRouteSemantics(String method, String host) {
    return '通过 $method 发送到 $host';
  }

  @override
  String get sendHeldKillSwitch => '“紧急断网”已开启。什么都不连接。';

  @override
  String get sendHeldNodeOnly => '“仅节点”已开启。只有节点会连接。';

  @override
  String get sendHeldTorOnly => '“仅 Tor”已开启。普通 http:// 无法经由 Tor。';

  @override
  String get sendHeldTorOn => 'Tor 已开启。普通 http:// 无法经由 Tor。';

  @override
  String get sendHeldFixKillSwitch => '关闭“紧急断网”';

  @override
  String get sendHeldFixNodeOnly => '关闭“仅节点”';

  @override
  String get sendHeldFixTorOnly => '关闭“仅 Tor”';

  @override
  String get sendHeldByKillSwitch => '因“紧急断网”暂不可用';

  @override
  String get sendHeldByNodeOnly => '因“仅节点”暂不可用';

  @override
  String get sendHeldByTorOnly => '因“仅 Tor”暂不可用';

  @override
  String get sendHeldWhileTorOn => 'Tor 开启时不可用';

  @override
  String get sendHeldModeNormal => '网络模式：常规。';

  @override
  String get sendHeldTorIsOff => 'Tor 已关闭。';

  @override
  String get sendNoAddress => '没有地址？';

  @override
  String get sendWithoutConnection => '无需网络连接：';

  @override
  String get sendPayInPerson => '当面付款';

  @override
  String get sendPayByFile => '用文件付款';

  @override
  String get sendIsSlateText => '这是交易文本，不是地址。';

  @override
  String get sendOpenSlateText => '打开';

  @override
  String get sendSendsTo => '发送到';

  @override
  String get sendProblemNotAddress => '这不是地址，也没有叫这个名字的联系人。';

  @override
  String get sendProblemOtherScheme => '此钱包无法向这种地址付款。';

  @override
  String get sendProblemIncomplete => '此地址似乎不完整。';

  @override
  String get sendProblemOnion => '这不是完整的 Tor 地址。请从接收方处重新复制。';

  @override
  String get sendProblemPort => '端口必须在 1 到 65535 之间。';

  @override
  String get sendProblemCredentials => '无法向包含用户名的地址付款。';

  @override
  String get sendProblemCharacters => '此地址包含地址中不能有的字符。';

  @override
  String get sendProblemTooLong => '此地址太长。';

  @override
  String get sendProblemOwn => '这是此钱包自己的地址。';

  @override
  String get sendReachChecking => '正在检查…';

  @override
  String sendReachNone(String host) {
    return '$host 没有钱包应答。';
  }

  @override
  String sendReachNotWallet(String host) {
    return '$host 有应答，但不是 Epic 钱包。';
  }

  @override
  String get sendReachTheirOnion => '对方的 Tor 地址';

  @override
  String get sendReachOpenFirst => '对方钱包必须处于打开状态才能收款。';

  @override
  String get sendReachCheckAddress => '请与接收方核对地址。';

  @override
  String get sendReachTryAgain => '重试';

  @override
  String get sendFactVia => '通过';

  @override
  String get sendFactHost => '主机';

  @override
  String get sendFactConnection => '连接';

  @override
  String get sendFactNotEncrypted => '未加密 · http://';

  @override
  String get sendFactTor => 'Tor';

  @override
  String get sendFactTorStarts => '发送时启动';

  @override
  String get sendFactOffline => '对方钱包可以离线。';

  @override
  String get sendFactOnline => '对方钱包必须处于打开状态。';

  @override
  String get deskTfOpenTitle => '打开交易文件';

  @override
  String get deskTfOpenText => '选择一个或多个文件。钱包会逐个读取，并对其签名、完成或广播。';

  @override
  String get deskTfPickTitle => '交易文件';

  @override
  String get deskTfResults => '已打开的文件';

  @override
  String get deskTfWorking => '正在处理…';

  @override
  String deskTfSigned(String path) {
    return '已签名。回复已保存到 $path';
  }

  @override
  String get deskTfAlreadyPosted => '已广播';

  @override
  String deskTfInvoice(String amount) {
    return '一张 $amount 的账单。确认后即可付款。';
  }

  @override
  String get deskTfReview => '确认';

  @override
  String get deskTfCreate => '创建付款文件';

  @override
  String get deskTfDropHint => '也可以把文件拖到这里。';

  @override
  String get deskSaToAddress => '发送到地址';

  @override
  String deskSaToContactSem(String name) {
    return '发给 $name';
  }

  @override
  String get netModesTitle => '连接模式';

  @override
  String get netModesAbout => '关于连接模式';

  @override
  String get netModesGroup => '连接模式';

  @override
  String get netModesTag => '[NET]';

  @override
  String get netModesTopology => '拓扑';

  @override
  String get netModesDevice => '设备';

  @override
  String get netModesDeviceSub => '本钱包';

  @override
  String get netModesTorSub => '内置';

  @override
  String get netModesEpicboxSub => '中继';

  @override
  String get netModesNode => '节点';

  @override
  String get netModesNodeSub => '当前节点';

  @override
  String get netModesNetwork => '网络';

  @override
  String get netModesNetworkSub => '对等节点';

  @override
  String get netModesPostElsewhere => '在别处广播';

  @override
  String get netModesLeaves => '离开设备';

  @override
  String get netModesDirect => '直连';

  @override
  String get netModesViaTor => '经由 Tor';

  @override
  String get netModesOptional => '可选';

  @override
  String get netModesAllTraffic => '全部流量';

  @override
  String get netModesOff => '关';

  @override
  String get netModesYes => '是';

  @override
  String get netModesNo => '否';

  @override
  String get netModesDescStandard =>
      '直接连接节点、Epicbox 和你使用的服务。开启 Tor 时，付款经过 Tor。';

  @override
  String get netModesDescNodeOnly =>
      '只有当前使用的节点会连接，Tor 开启时经由 Tor。Epicbox、链接、已链接设备、价格和更新检查均已关闭。';

  @override
  String get netModesDescNodeOnlyNoTor =>
      '只有当前使用的节点会连接。Epicbox、链接、已链接设备、价格和更新检查均已关闭。';

  @override
  String get netModesDescKillSwitch =>
      '不建立任何连接，节点也不例外。付款在离线状态下创建并完成，然后由联网的设备广播。';

  @override
  String netModesLiveLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动连接',
    );
    return '$_temp0';
  }

  @override
  String netModesDiagramLabel(String mode, String description) {
    return '网络拓扑，$mode模式：$description';
  }

  @override
  String get netModesModeTag => '[模式]';

  @override
  String get deskOldAppTitle => '发现旧应用';

  @override
  String deskOldAppBody(String app, String folder) {
    return '$app 仍在 $folder 中。';
  }

  @override
  String get deskOldAppTrash => '移到废纸篓';

  @override
  String get deskOldAppKeep => '保留';

  @override
  String deskOldAppTrashed(String app) {
    return '已将 $app 移到废纸篓';
  }

  @override
  String deskOldAppNotTrashed(String app) {
    return '无法将 $app 移到废纸篓';
  }

  @override
  String deskOvInflightMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 笔付款进行中',
    );
    return '$_temp0';
  }

  @override
  String get deskOvInflightView => '查看';

  @override
  String get deskNoTorSetSynNetMode => '离线, 断网开关, 仅节点, vpn, ip, 隐私, 飞行模式';

  @override
  String get deskNoTorSetSearchTryWords => '密码,隐私,助记词,备份,手续费,节点,锁定';

  @override
  String get deskKitReachDismiss => '不再提示';

  @override
  String deskErrKeyMissing(String name) {
    return '$name 的文件在这台电脑上，但打开它们的密钥已不在安全存储中（Mac 上为钥匙串）。输入该钱包的助记词即可重新打开；交易记录保留。';
  }

  @override
  String get deskOnbUnlockUsePhrase => '输入助记词';

  @override
  String get pairSeenAsNone => '对方看不到名字';

  @override
  String get pairSeenAsAdd => '添加名字';

  @override
  String get pairSeenAsOptional => '留空则不带名字配对。';

  @override
  String get pairUnnamed => '未命名钱包';

  @override
  String pairDefaultLabel(int n) {
    return '联系人 $n';
  }

  @override
  String get linkNotALink => '不是付款链接';

  @override
  String get linkMadeForMainnet => '为 mainnet 创建';

  @override
  String get linkMadeForFloonet => '为 floonet 创建';

  @override
  String get linkChanged => '此链接在创建后被更改过。';

  @override
  String linkExpired(String date) {
    return '此链接已于 $date 过期';
  }

  @override
  String get linkForOther => '为其他人创建';

  @override
  String get linkPaidTitle => '已付款';

  @override
  String linkPaidBefore(String date) {
    return '你已在 $date 支付此请求';
  }

  @override
  String get linkPayAgain => '再次付款';

  @override
  String linkTrustListed(String name, String service) {
    return '$name · 经由 $service';
  }

  @override
  String linkTrustListedBy(String service) {
    return '经由 $service';
  }

  @override
  String get linkTrustNameService => '来自你已配对的服务';

  @override
  String get linkTrustOther => '请确认与付款消息中的一致';

  @override
  String linkTrustChanged(String name, String date) {
    return '$name 现在收款到另一个钱包，与你在 $date 付款时不同。仅在对方告知过你时再付款。';
  }

  @override
  String linkTrustChangedNoName(String date) {
    return '收款方现在收款到另一个钱包，与你在 $date 付款时不同。仅在对方告知过你时再付款。';
  }

  @override
  String linkCodeLabel(String name) {
    return '$name 的图案';
  }

  @override
  String get linkCodeLabelPlain => '图案';

  @override
  String get linkAmountEdited => '不是请求的金额';

  @override
  String get linkChangedConfirmTitle => '付款前请核对';

  @override
  String nsWaitingFor(String label) {
    return '正在等待 $label…';
  }

  @override
  String get nsCodeTitle => '核对代码';

  @override
  String nsCodeLead(String label) {
    return '$label 显示四个图案。请与这里的对比。';
  }

  @override
  String get nsCodeLabel => '四个图案';

  @override
  String nsJoin(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': '通过 $label 收款',
      'other': '以 $name 收款',
    });
    return '$_temp0';
  }

  @override
  String get nsNotNow => '暂不';

  @override
  String nsJoinTitle(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': '通过 $label 收款？',
      'other': '以 $name 收款？',
    });
    return '$_temp0';
  }

  @override
  String nsJoinBody(String name, String label, String host) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': '使用 $label 的人可以在那里向你付款。款项通过 $host 到达',
      'other': '使用 $label 的人可以用 $name 向你付款。款项通过 $host 到达',
    });
    return '$_temp0';
  }

  @override
  String nsJoinInfo(String label) {
    return '$label 会得到一个收款地址和一个代码，都仅为它创建。它看不到你的余额，也不能动用币。它会把为你或由你创建的付款链接连同金额保存 30 天。Epic Cash 打开时款项才会到达。可随时在 联系人 › $label 中退出。';
  }

  @override
  String nsJoinedNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': '通过 $label 收款：已开启',
      'other': '以 $name 收款：已开启',
    });
    return '$_temp0';
  }

  @override
  String nsLeftNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': '通过 $label 收款：已关闭',
      'other': '以 $name 收款：已关闭',
    });
    return '$_temp0';
  }

  @override
  String nsJoined(String name, String label, String date) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': '通过 $label 收款 · 自 $date 起',
      'other': '以 $name 收款 · 自 $date 起',
    });
    return '$_temp0';
  }

  @override
  String get nsNotListed => '关闭';

  @override
  String nsNotListedBody(String label) {
    return '$label 已移除你的名称。';
  }

  @override
  String get nsNotJoined => '关闭';

  @override
  String get nsJoinAgain => '重新开启';

  @override
  String get nsListingCode => '你的名称的图案';

  @override
  String nsListingCodeInfo(String label) {
    return '由你的名称所收款的钱包生成的四个图案。$label 可显示同样的四个供对比。';
  }

  @override
  String get nsLeave => '退出';

  @override
  String nsRemoveTooTitle(String label) {
    return '也移除 $label？';
  }

  @override
  String deskSendErrOwnNamed(String wallet) {
    return '这是当前打开的钱包“$wallet”。要向它付款，请先打开另一个钱包。';
  }

  @override
  String get deskConLabelTitle => '标签';

  @override
  String get deskConLabelWallet => '普通钱包';

  @override
  String get deskConLabelExchange => '交易所';

  @override
  String get deskConLabelVendor => '商家';

  @override
  String get deskConLabelService => '服务';

  @override
  String get deskConLabelDefault => '默认';

  @override
  String deskConLabelCurrent(String name) {
    return '标签：$name';
  }

  @override
  String get deskUpdStripAct => '更新';

  @override
  String get deskUpdStripHide => '隐藏至下一版本';
}
