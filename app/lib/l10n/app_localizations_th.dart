// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Mobile';

  @override
  String get appTitleDesktop => 'Epic Cash Desktop';

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get commonClose => 'ปิด';

  @override
  String get noticeLevelInfo => 'ข้อมูล';

  @override
  String get noticeLevelSuccess => 'เสร็จแล้ว';

  @override
  String get noticeLevelWarning => 'คำเตือน';

  @override
  String get noticeLevelError => 'ข้อผิดพลาด';

  @override
  String get commonContinue => 'ดำเนินการต่อ';

  @override
  String get commonCopy => 'คัดลอก';

  @override
  String get commonDelete => 'ลบ';

  @override
  String get commonDone => 'เสร็จสิ้น';

  @override
  String get commonError => 'ข้อผิดพลาด';

  @override
  String get commonOk => 'ตกลง';

  @override
  String get commonPaste => 'วาง';

  @override
  String get commonRetry => 'ลองอีกครั้ง';

  @override
  String get commonSave => 'บันทึก';

  @override
  String get commonShare => 'แชร์';

  @override
  String get commonUnknown => 'ไม่ทราบ';

  @override
  String get passwordShow => 'แสดงรหัสผ่าน';

  @override
  String get passwordHide => 'ซ่อนรหัสผ่าน';

  @override
  String get slateCopyTooltip => 'คัดลอกข้อความธุรกรรม';

  @override
  String get slateCopied => 'คัดลอกข้อความธุรกรรมแล้ว';

  @override
  String get slatePastedTitle => 'รายการที่วาง';

  @override
  String get slateCopyReply => 'คัดลอกคำตอบ';

  @override
  String get biometricPromptTitle => 'ปลดล็อกกระเป๋าเงิน';

  @override
  String get biometricPromptSubtitle => 'ยืนยันด้วยลายนิ้วมือหรือใบหน้า';

  @override
  String get biometricPromptUsePin => 'ใช้ PIN';

  @override
  String get amountEnterExample => 'ใส่จำนวน เช่น 1.5';

  @override
  String amountTooManyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทศนิยมได้ไม่เกิน $count ตำแหน่ง',
    );
    return '$_temp0';
  }

  @override
  String dateWithTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get dateToday => 'วันนี้';

  @override
  String get dateYesterday => 'เมื่อวาน';

  @override
  String get txMiningReward => 'รางวัลการขุด';

  @override
  String get txRestoredFunds => 'ยอดที่กู้คืน';

  @override
  String get txOutgoingPayment => 'รายการส่งออก';

  @override
  String get txIncomingPayment => 'รายการรับเข้า';

  @override
  String get txStatusWaitingRecipient => 'รอผู้รับ';

  @override
  String get txStatusWaitingSender => 'รอผู้ส่ง';

  @override
  String txStatusConfirming(int count, int target) {
    return 'กำลังยืนยัน $count/$target';
  }

  @override
  String get txStatusCompleted => 'สำเร็จ';

  @override
  String get txStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get txStatusFromBackup => 'จากข้อมูลสำรอง ไม่ทราบสถานะ';

  @override
  String get txIconCancelled => 'ยกเลิกแล้ว';

  @override
  String get txIconIncoming => 'รับเข้า';

  @override
  String get txIconOutgoing => 'ส่งออก';

  @override
  String get txSpokenHiddenAmount => 'จำนวนที่ซ่อนไว้';

  @override
  String txSpokenMiningReward(String amount) {
    return 'รางวัลการขุด $amount';
  }

  @override
  String txSpokenRestoredFunds(String amount) {
    return 'ยอดที่กู้คืน $amount';
  }

  @override
  String txSpokenCancelledSend(String amount) {
    return 'ยกเลิกการส่ง $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return 'ยกเลิกการส่ง $amount ถึง $who';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return 'ยกเลิกการรับ $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return 'ยกเลิกการรับ $amount จาก $who';
  }

  @override
  String txSpokenSending(String amount) {
    return 'กำลังส่ง $amount';
  }

  @override
  String txSpokenSendingTo(String amount, String who) {
    return 'กำลังส่ง $amount ถึง $who';
  }

  @override
  String txSpokenReceiving(String amount) {
    return 'กำลังรับ $amount';
  }

  @override
  String txSpokenReceivingFrom(String amount, String who) {
    return 'กำลังรับ $amount จาก $who';
  }

  @override
  String txSpokenSent(String amount) {
    return 'ส่งแล้ว $amount';
  }

  @override
  String txSpokenSentTo(String amount, String who) {
    return 'ส่ง $amount ถึง $who แล้ว';
  }

  @override
  String txSpokenReceived(String amount) {
    return 'ได้รับ $amount';
  }

  @override
  String txSpokenReceivedFrom(String amount, String who) {
    return 'ได้รับ $amount จาก $who';
  }

  @override
  String txSpokenRow(String what, String status, String date) {
    return '$what, $status, $date';
  }

  @override
  String get errorInvalidMnemonic =>
      'วลีกู้คืนไม่ถูกต้อง ตรวจสอบแต่ละคำและลำดับคำ';

  @override
  String get errorWrongPassword => 'รหัสผ่านไม่ถูกต้อง';

  @override
  String get errorWalletAlreadyExists =>
      'มีกระเป๋าเงินสำหรับเครือข่ายนี้อยู่แล้ว';

  @override
  String get errorWalletNotFound => 'ไม่พบกระเป๋าเงินสำหรับเครือข่ายนี้';

  @override
  String get errorNodeUnreachable =>
      'เชื่อมต่อโหนดไม่ได้ ตรวจสอบ URL ของโหนดและการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get errorNotEnoughFunds =>
      'ยอดที่ใช้ได้ไม่พอสำหรับจำนวนนี้รวมค่าธรรมเนียม';

  @override
  String get errorInvalidSlate =>
      'ข้อความธุรกรรมนี้ใช้กับขั้นตอนนี้ไม่ได้ ตรวจสอบว่าวางครบทั้งหมด';

  @override
  String get errorInvalidInput => 'ข้อมูลไม่ถูกต้อง';

  @override
  String get errorTransportFailed => 'ติดต่อผู้รับไม่ได้';

  @override
  String get errorTorNotRunning => 'Tor ไม่ได้เชื่อมต่อ';

  @override
  String get errorOnionUnreachable =>
      'ติดต่อกระเป๋าเงินของผู้รับผ่าน Tor ไม่ได้';

  @override
  String get errorChainBusy =>
      'กระเป๋าเงินยังทำงานอยู่บนอีกเครือข่าย รอสักครู่แล้วลองอีกครั้ง หรือปิดแล้วเปิดแอปใหม่';

  @override
  String get errorWalletBusy =>
      'กระเป๋าเงินยังทำงานค้างอยู่ ลองอีกครั้งในอีกสักครู่';

  @override
  String get errorPaymentExpired =>
      'คำตอบของรายการนี้มาช้าเกินไป รายการจึงถูกยกเลิก ไม่มีการส่งเงินออก';

  @override
  String get errorIo => 'อ่านหรือเขียนไฟล์กระเป๋าเงินไม่ได้';

  @override
  String get errorOther => 'ข้อผิดพลาดของกระเป๋าเงิน';

  @override
  String get errorScanFailed => 'การสแกนล้มเหลว';

  @override
  String get errorUnexpected => 'เกิดข้อผิดพลาดที่ไม่คาดคิด ลองอีกครั้ง';

  @override
  String get errorHistoryNotOurs =>
      'ไฟล์นี้ไม่ใช่ไฟล์ประวัติที่ส่งออกจากแอปนี้';

  @override
  String get errorHistoryNewer =>
      'ไฟล์ประวัตินี้สร้างจากแอปเวอร์ชันที่ใหม่กว่า';

  @override
  String get errorHistoryDamaged => 'ไฟล์ประวัตินี้เสียหาย';

  @override
  String get errorHistoryOtherWallet => 'ไฟล์ประวัตินี้เป็นของกระเป๋าเงินอื่น';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return 'ไฟล์ประวัตินี้มาจาก $fileNetwork แต่กระเป๋าเงินนี้อยู่บน $walletNetwork';
  }

  @override
  String get networkMainnet => 'Mainnet';

  @override
  String get networkFloonet => 'Floonet';

  @override
  String get networkUsernet => 'Usernet';

  @override
  String get networkMainnetDescription => 'เครือข่าย Epic Cash จริง';

  @override
  String get networkFloonetDescription =>
      'เครือข่ายทดสอบสาธารณะสำหรับลองใช้แอป เหรียญไม่มีมูลค่า รับฟรีได้ที่ floo-explorer.btlabs.uk';

  @override
  String get networkUsernetDescription =>
      'เครือข่ายทดสอบบนคอมพิวเตอร์เครื่องนี้ สำหรับนักพัฒนา';

  @override
  String networkTestSuffix(String network) {
    return ' ($network, เหรียญทดสอบ)';
  }

  @override
  String get autoLockNever => 'ไม่ล็อก';

  @override
  String get autoLockImmediately => 'ทันที';

  @override
  String autoLockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'หลัง $minutes นาที',
    );
    return '$_temp0';
  }

  @override
  String get scanStarting => 'กำลังเริ่มสแกน';

  @override
  String scanProgress(int percent) {
    return 'กำลังสแกนบล็อกเชน ($percent%)';
  }

  @override
  String get scanComplete => 'สแกนเสร็จแล้ว';

  @override
  String get languageSetting => 'ภาษา';

  @override
  String get languageSystem => 'ตามระบบ';

  @override
  String get currencyUsd => 'ดอลลาร์สหรัฐ';

  @override
  String get currencyEur => 'ยูโร';

  @override
  String get currencyGbp => 'ปอนด์สเตอร์ลิง';

  @override
  String get currencyBtc => 'Bitcoin';

  @override
  String get currencyJpy => 'เยนญี่ปุ่น';

  @override
  String get currencyCny => 'หยวนจีน';

  @override
  String get currencyCad => 'ดอลลาร์แคนาดา';

  @override
  String get currencyAud => 'ดอลลาร์ออสเตรเลีย';

  @override
  String get currencyChf => 'ฟรังก์สวิส';

  @override
  String get currencyInr => 'รูปีอินเดีย';

  @override
  String get currencyBrl => 'เรอัลบราซิล';

  @override
  String get currencyKrw => 'วอนเกาหลีใต้';

  @override
  String get currencyPln => 'ซลอตีโปแลนด์';

  @override
  String get currencyTry => 'ลีราตุรกี';

  @override
  String txDetailsWaitingTooLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'รอมา $days วันแล้ว Epicbox ลบรายการหลัง 7 วัน รายการนี้จึงทำต่อไม่ได้แล้ว ยกเลิกเพื่อปลดล็อกยอดเงิน แล้วส่งใหม่',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'ส่งไปยัง Epicbox ของผู้รับแล้ว รายการจะสำเร็จเมื่อกระเป๋าเงินของผู้รับออนไลน์ ยอดเงินจะถูกล็อกจนถึงตอนนั้น หรือจนกว่าจะยกเลิก';

  @override
  String get txDetailsWaitingRecipient =>
      'รอผู้รับตอบกลับด้วยไฟล์ธุรกรรม ยอดเงินจะถูกล็อกจนถึงตอนนั้น หรือจนกว่าจะยกเลิก';

  @override
  String get txDetailsWaitingSender =>
      'รับรายการนี้แล้ว รายการจะสำเร็จเมื่อผู้ส่งทำรายการให้เสร็จและเผยแพร่ไปยังเครือข่าย';

  @override
  String get txDetailsPublished =>
      'เผยแพร่ไปยังเครือข่ายแล้ว รอการยืนยันครั้งแรก';

  @override
  String get txDetailsWaitingConfirmation => 'รอเครือข่ายยืนยัน';

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
      other: '$target ครั้ง',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes นาที',
    );
    return 'อยู่ในบล็อก $height ยืนยันแล้ว $count จาก $_temp0 เสร็จสมบูรณ์ในอีกประมาณ $_temp1';
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
      other: '$target ครั้ง',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ชั่วโมง',
    );
    return 'อยู่ในบล็อก $height ยืนยันแล้ว $count จาก $_temp0 เสร็จสมบูรณ์ในอีกประมาณ $_temp1';
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
      other: '$target ครั้ง',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days วัน',
    );
    return 'อยู่ในบล็อก $height ยืนยันแล้ว $count จาก $_temp0 เสร็จสมบูรณ์ในอีกประมาณ $_temp1';
  }

  @override
  String get txDetailsCompleted => 'สำเร็จ';

  @override
  String txDetailsCompletedInBlock(String height) {
    return 'สำเร็จในบล็อก $height';
  }

  @override
  String get txDetailsCancelledByUser =>
      'ยกเลิกแล้ว ไม่มีการส่งเงินออก และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledReleased =>
      'เครือข่ายไม่รับรายการนี้ จึงปลดยอดเงินแล้ว ตรวจสอบว่าผู้รับไม่ได้รับเงินก่อนส่งใหม่';

  @override
  String get txDetailsCancelledNotOnChain =>
      'รายการไม่เข้าสู่เครือข่ายภายใน 14 วัน กระเป๋าเงินจึงยกเลิก ตรวจสอบว่าผู้รับไม่ได้รับเงินก่อนส่งใหม่';

  @override
  String get txDetailsCancelledUnanswered =>
      'ผู้รับไม่ตอบภายใน 14 วัน กระเป๋าเงินจึงยกเลิก ไม่มีการส่งเงินออก และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledLateAnswer =>
      'ผู้รับตอบหลังครบกำหนด 14 วัน กระเป๋าเงินจึงยกเลิกแทนการทำรายการให้เสร็จ ไม่มีการส่งเงินออก และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledUndelivered =>
      'ส่งถึงผู้รับไม่ได้ กระเป๋าเงินจึงยกเลิกทันที ไม่มีการส่งเงินออก และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledIncoming => 'ยกเลิกแล้ว รายการนี้จะไม่เข้า';

  @override
  String get txDetailsFromBackup =>
      'รายการนี้มาจากข้อมูลสำรองประวัติ และยังไม่เสร็จตอนสำรองข้อมูล กระเป๋าเงินนี้ไม่มีบันทึกของตัวเอง จึงไม่ทราบว่าสำเร็จหรือไม่ ไม่มียอดเงินถูกล็อก';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return 'ยกเลิกอัตโนมัติถ้าไม่สำเร็จภายในบล็อก $height';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes นาที',
    );
    return 'ยกเลิกอัตโนมัติถ้าไม่สำเร็จภายในบล็อก $height (อีกประมาณ $_temp0)';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ชั่วโมง',
    );
    return 'ยกเลิกอัตโนมัติถ้าไม่สำเร็จภายในบล็อก $height (อีกประมาณ $_temp0)';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days วัน',
    );
    return 'ยกเลิกอัตโนมัติถ้าไม่สำเร็จภายในบล็อก $height (อีกประมาณ $_temp0)';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return 'หมดอายุที่บล็อก $height กระเป๋าเงินจะยกเลิกในการรีเฟรชครั้งถัดไป';
  }

  @override
  String get txDetailsTitle => 'รายการ';

  @override
  String get txDetailsLoading => 'กำลังโหลด';

  @override
  String get txDetailsGone => 'รายการนี้ไม่อยู่ในกระเป๋าเงินแล้ว';

  @override
  String get txDetailsWorking => 'กำลังดำเนินการ';

  @override
  String get txDetailsAmountHidden => 'ซ่อนจำนวนอยู่';

  @override
  String get txDetailsNotConfirmedYet => 'ยังไม่ได้รับการยืนยัน';

  @override
  String get txDetailsStuckBody =>
      'เครือข่ายยังไม่รับรายการนี้ ส่งซ้ำได้อย่างปลอดภัย รายการเดียวกันผ่านสองครั้งไม่ได้';

  @override
  String get txDetailsBroadcastAgain => 'ส่งเข้าเครือข่ายอีกครั้ง';

  @override
  String get txDetailsBroadcastAgainDone =>
      'ส่งเข้าเครือข่ายอีกครั้งแล้ว น่าจะได้รับการยืนยันในไม่กี่นาที';

  @override
  String get txDetailsRefusedBody =>
      'เครือข่ายปฏิเสธรายการนี้ และรายการไม่เคยเข้าบล็อกเชน ปลดยอดเงินที่ถูกล็อกได้';

  @override
  String get txDetailsReleaseFunds => 'ปลดยอดเงิน';

  @override
  String get txDetailsReleaseTitle => 'ปลดยอดเงินไหม?';

  @override
  String get txDetailsReleaseBody =>
      'ใช้เฉพาะเมื่อรายการจะไม่ได้รับการยืนยันแน่นอน ถ้ายังได้รับการยืนยันภายหลัง ยอดคงเหลืออาจแสดงผิดจนกว่าจะตรวจยอดใหม่';

  @override
  String get txDetailsReleaseKeepWaiting => 'รอต่อ';

  @override
  String get txDetailsFundsReleased => 'ปลดยอดเงินแล้ว';

  @override
  String get txDetailsCancelPayment => 'ยกเลิกรายการ';

  @override
  String get txDetailsCancelTitle => 'ยกเลิกรายการไหม?';

  @override
  String get txDetailsCancelReceiveBody =>
      'ผู้ส่งอาจยังทำรายการนี้ให้เสร็จได้ ถ้าทำหลังจากยกเลิกแล้ว รายการจะไม่แสดงจนกว่าจะตรวจยอดใหม่';

  @override
  String get txDetailsCancelSendBody =>
      'ยกเลิกรายการนี้และปลดล็อกยอดเงินไหม? ทำเฉพาะเมื่อผู้รับยังไม่ได้ทำรายการให้เสร็จ';

  @override
  String get txDetailsCancelKeep => 'เก็บไว้';

  @override
  String get txDetailsPaymentCancelled => 'ยกเลิกรายการแล้ว';

  @override
  String get txDetailsDate => 'วันที่';

  @override
  String get txDetailsCreated => 'สร้างเมื่อ';

  @override
  String get txDetailsSentTo => 'ส่งถึง';

  @override
  String get txDetailsReceivedFrom => 'ได้รับจาก';

  @override
  String get txDetailsCopyAddress => 'คัดลอกที่อยู่';

  @override
  String get txDetailsAddressCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get txDetailsAddToContacts => 'เพิ่มในผู้ติดต่อ';

  @override
  String get txDetailsSendAgain => 'ส่งอีกครั้ง';

  @override
  String get txDetailsFee => 'ค่าธรรมเนียม';

  @override
  String get txDetailsNoteLabel => 'บันทึก';

  @override
  String get txDetailsPrivateNoteLabel =>
      'บันทึกส่วนตัว อยู่บนอุปกรณ์นี้เท่านั้น';

  @override
  String get txDetailsMessageFromSender => 'ข้อความจากผู้ส่ง';

  @override
  String get txDetailsMessageFromRecipient => 'ข้อความจากผู้รับ';

  @override
  String get txDetailsYourMessage => 'ข้อความของคุณ';

  @override
  String get txDetailsNoNote =>
      'ไม่มีบันทึก เพิ่มไว้เพื่อจำว่ารายการนี้เป็นค่าอะไร';

  @override
  String get txDetailsAddNote => 'เพิ่มบันทึก';

  @override
  String get txDetailsEditNote => 'แก้ไขบันทึก';

  @override
  String get txDetailsNoteDialogTitle => 'บันทึก';

  @override
  String get txDetailsNoteHelper =>
      'อยู่บนอุปกรณ์นี้และในข้อมูลสำรองประวัติเท่านั้น';

  @override
  String get txDetailsNoteSaved => 'บันทึกแล้ว';

  @override
  String get txDetailsNoteRemoved => 'ลบบันทึกแล้ว';

  @override
  String get txDetailsExplorerLink => 'คัดลอกลิงก์ Explorer';

  @override
  String get txDetailsExplorerLinkCopy => 'คัดลอกลิงก์ Explorer';

  @override
  String get txDetailsLinkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get txDetailsTechnical => 'รายละเอียดทางเทคนิค';

  @override
  String get txDetailsBlockHeight => 'ความสูงบล็อก';

  @override
  String get txDetailsSlateId => 'Slate ID';

  @override
  String get txDetailsSlateIdCopy => 'คัดลอก Slate ID';

  @override
  String get txDetailsSlateIdCopied => 'คัดลอก Slate ID แล้ว';

  @override
  String get txDetailsKernel => 'Kernel';

  @override
  String get txDetailsKernelCopy => 'คัดลอก Kernel';

  @override
  String get txDetailsKernelCopied => 'คัดลอก Kernel แล้ว';

  @override
  String get txDetailsOutputCommitment => 'Commitment ของเอาต์พุต';

  @override
  String get txDetailsOutputCommitmentCopy => 'คัดลอก Commitment ของเอาต์พุต';

  @override
  String get txDetailsOutputCommitmentCopied =>
      'คัดลอก Commitment ของเอาต์พุตแล้ว';

  @override
  String txDetailsOutputCommitmentNumbered(int number) {
    return 'Commitment ของเอาต์พุต $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopy(int number) {
    return 'คัดลอก Commitment ของเอาต์พุต $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopied(int number) {
    return 'คัดลอก Commitment ของเอาต์พุต $number แล้ว';
  }

  @override
  String get txDetailsExpiryHeight => 'บล็อกหมดอายุ';

  @override
  String get txDetailsLocalId => 'ID ในเครื่อง';

  @override
  String get txDetailsSourceRestored =>
      'พบจากการสแกนบล็อกเชน รายละเอียดอย่างผู้ส่งและค่าธรรมเนียมไม่ได้เก็บบนบล็อกเชน นำเข้าข้อมูลสำรองประวัติเพื่อกู้คืนรายละเอียด';

  @override
  String get txDetailsSourceImported =>
      'นำเข้าจากข้อมูลสำรองประวัติ กระเป๋าเงินนี้ไม่มีบันทึกของตัวเอง สถานะจึงอาจไม่เป็นปัจจุบัน';

  @override
  String get historyTitle => 'ประวัติ';

  @override
  String get historyLoading => 'กำลังโหลดรายการ';

  @override
  String get historyRefreshing => 'กำลังรีเฟรช';

  @override
  String get historySearchLabel => 'ค้นหา';

  @override
  String get historySearchHint => 'บันทึก ผู้ติดต่อ ที่อยู่ หรือจำนวน';

  @override
  String get historyClearSearch => 'ล้างการค้นหา';

  @override
  String get historyFilterAll => 'ทั้งหมด';

  @override
  String get historyFilterSent => 'ส่ง';

  @override
  String get historyFilterReceived => 'รับ';

  @override
  String get historyFilterPending => 'รอดำเนินการ';

  @override
  String get historyFilterCancelled => 'ยกเลิก';

  @override
  String get historySectionPending => 'รอดำเนินการ';

  @override
  String get historyEmpty => 'ยังไม่มีรายการ รายการที่ส่งหรือรับจะแสดงที่นี่';

  @override
  String get historyNoSent => 'ไม่มีรายการส่ง';

  @override
  String get historyNoReceived => 'ไม่มีรายการรับ';

  @override
  String get historyNoPending => 'ไม่มีรายการรอดำเนินการ';

  @override
  String get historyNoCancelled => 'ไม่มีรายการที่ยกเลิก';

  @override
  String historyNoMatch(String query) {
    return 'ไม่พบรายการที่ตรงกับ “$query”';
  }

  @override
  String get historyBackupSaveDialogTitle => 'บันทึกประวัติรายการ';

  @override
  String get historyBackupOpenDialogTitle => 'เปิดข้อมูลสำรองประวัติ';

  @override
  String get historyBackupFileTooLarge =>
      'ไฟล์นี้ใหญ่เกินกว่าจะเป็นข้อมูลสำรอง';

  @override
  String get historyBackupShare => 'แชร์';

  @override
  String get historyBackupShareSubtitle =>
      'เก็บสำเนาไว้นอกโทรศัพท์นี้ เช่น อีเมลหรือคลาวด์';

  @override
  String get historyBackupSaveToDevice => 'บันทึกลงอุปกรณ์';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'มีประโยชน์เมื่อคัดลอกไปเก็บนอกโทรศัพท์นี้ด้วยเท่านั้น';

  @override
  String historyBackupSaved(String fileName) {
    return 'บันทึก $fileName แล้ว';
  }

  @override
  String get historyBackupExportTitle => 'ส่งออกข้อมูลสำรองประวัติ';

  @override
  String get historyBackupExportNote =>
      'ข้อมูลสำรองประวัติเก็บรายการถึงปัจจุบันเท่านั้น ส่งออกใหม่หลังมีรายการใหม่';

  @override
  String get historyBackupCsvTitle => 'ส่งออก CSV';

  @override
  String get historyBackupCsvWarning =>
      'ไฟล์ CSV ไม่ได้เข้ารหัส ใครได้ไฟล์ไปก็อ่านจำนวน วันที่ ที่อยู่ และบันทึกได้ และนำเข้ากลับไม่ได้ ถ้าต้องการนำเข้าให้ใช้ ส่งออกข้อมูลสำรองประวัติ';

  @override
  String get historyBackupCsvConfirm => 'ส่งออก CSV';

  @override
  String get historyBackupImportedTitle => 'นำเข้าประวัติแล้ว';

  @override
  String historyBackupImportFailed(String reason) {
    return 'นำเข้าข้อมูลสำรองประวัติไม่ได้ $reason';
  }

  @override
  String get historyBackupImportNothingNew => 'ข้อมูลสำรองไม่มีอะไรใหม่';

  @override
  String historyBackupImportMerged(int merged) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    return '$_temp0';
  }

  @override
  String historyBackupImportAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    return '$_temp0';
  }

  @override
  String historyBackupImportMergedAdded(int merged, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String historyBackupImportSkipped(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    return '$_temp0';
  }

  @override
  String historyBackupImportMergedSkipped(int merged, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String historyBackupImportAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    return '$_temp0, $_temp1';
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
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    return '$_temp0, $_temp1, $_temp2';
  }

  @override
  String historyBackupImportContacts(int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0';
  }

  @override
  String historyBackupImportMergedContacts(int merged, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String historyBackupImportAddedContacts(int added, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1';
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
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1, $_temp2';
  }

  @override
  String historyBackupImportSkippedContacts(int skipped, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1';
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
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1, $_temp2';
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
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1, $_temp2';
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
      other: 'กู้รายละเอียดคืน $merged รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มรายการเก่า $added รายการ',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'มีอยู่แล้ว $skipped รายการ',
    );
    String _temp3 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3';
  }

  @override
  String get homeLockTooltip => 'ล็อกกระเป๋าเงิน';

  @override
  String get shellTitle => 'Epic Cash Mobile';

  @override
  String get demoWelcomeTitle => 'ลองใช้ Epic Cash';

  @override
  String get demoWelcomeLine =>
      'กระเป๋าเงินจริงพร้อมเหรียญทดสอบฟรีที่ไม่มีมูลค่า จะถูกลบหลัง 24 ชั่วโมง';

  @override
  String get demoStart => 'เริ่มเดโม';

  @override
  String get demoEndedTitle => 'เดโมสิ้นสุดแล้ว';

  @override
  String get demoEndedBody => 'กระเป๋าเงินและเหรียญทดสอบของเดโมถูกลบแล้ว';

  @override
  String get demoStartAgain => 'เริ่มใหม่';

  @override
  String demoEndsAt(String time) {
    return 'เดโมสิ้นสุดเวลา $time กระเป๋าเงินและเหรียญทดสอบจะถูกลบตอนนั้น';
  }

  @override
  String get demoEndingSoon =>
      'เดโมจะสิ้นสุดในอีก 30 นาที กระเป๋าเงินและเหรียญทดสอบจะถูกลบตอนนั้น';

  @override
  String get demoTestCoins => 'รับเหรียญทดสอบ';

  @override
  String get demoTestCoinsPaid => 'เหรียญทดสอบกำลังมา จะเข้าในอีก 1–2 นาที';

  @override
  String demoTestCoinsCooldown(int seconds) {
    return 'Faucet ต้องพักก่อน ลองอีกครั้งใน $seconds วินาที';
  }

  @override
  String get demoTestCoinsFailed =>
      'Faucet ไม่ได้ส่งอะไรมาในครั้งนี้ ลองอีกครั้งในอีก 1 นาที';

  @override
  String get demoEnd => 'จบเดโม';

  @override
  String get demoEndTitle => 'จบเดโมไหม?';

  @override
  String get demoEndBody =>
      'กระเป๋าเงินเดโมและเหรียญทดสอบจะถูกลบตอนนี้ เริ่มเดโมใหม่ได้ภายหลัง';

  @override
  String get demoServerUnreachable =>
      'เชื่อมต่อเซิร์ฟเวอร์เดโมไม่ได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String demoStartFull(int minutes) {
    return 'เดโมเต็มอยู่ตอนนี้ ลองอีกครั้งใน $minutes นาที';
  }

  @override
  String demoStartTooMany(int minutes) {
    return 'มีการเริ่มเดโมจากเครือข่ายของคุณมากเกินไป ลองอีกครั้งใน $minutes นาที';
  }

  @override
  String get demoConnectionLost => 'การเชื่อมต่อขาดหาย กำลังเชื่อมต่อใหม่';

  @override
  String get demoConnectionBack => 'เชื่อมต่อแล้ว';

  @override
  String get homeSettingsTooltip => 'การตั้งค่า';

  @override
  String get homeSettingsUpdateTooltip => 'การตั้งค่า: มีอัปเดตใหม่';

  @override
  String get homeSendButton => 'ส่ง';

  @override
  String get shellWalletTab => 'กระเป๋า';

  @override
  String get homeReceiveButton => 'รับ';

  @override
  String get homeScanTooltip => 'สแกน QR Code เพื่อส่ง';

  @override
  String get homeRecentActivity => 'รายการล่าสุด';

  @override
  String get homeSeeAll => 'ดูทั้งหมด';

  @override
  String get homeBackedUpNotice => 'สำรองวลีกู้คืนแล้ว';

  @override
  String get homeNoticeView => 'ดู';

  @override
  String get homePushNotice =>
      'มีรายการรออยู่ใน Epicbox จะเข้าเมื่อแอปเชื่อมต่อแล้ว';

  @override
  String get homeNoticeReceived =>
      'มีรายการกำลังเข้า จะสำเร็จเมื่อผู้ส่งทำรายการเสร็จ';

  @override
  String homeNoticeReceivedFrom(String who) {
    return 'รายการจาก $who กำลังเข้า จะสำเร็จเมื่อผู้ส่งทำรายการเสร็จ';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount กำลังเข้า จะสำเร็จเมื่อผู้ส่งทำรายการเสร็จ';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$amount จาก $who กำลังเข้า จะสำเร็จเมื่อผู้ส่งทำรายการเสร็จ';
  }

  @override
  String get homeNoticeFinished => 'ทำรายการเสร็จแล้ว รอการยืนยัน';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'รายการถึง $who เสร็จแล้ว รอการยืนยัน';
  }

  @override
  String get homeNoticeRepeated =>
      'รับรายการนี้ไปแล้ว ผู้ส่งได้รับคำตอบเดิมอีกครั้ง ไม่มีรายการที่สองกำลังเข้า';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return 'รับรายการจาก $who ไปแล้ว ผู้ส่งได้รับคำตอบเดิมอีกครั้ง ไม่มีรายการที่สองกำลังเข้า';
  }

  @override
  String get homeNoticeDelayed =>
      'เชื่อมต่อโหนดไม่ได้ รายการจะเสร็จเมื่อเชื่อมต่อได้';

  @override
  String get homeNoticeRelayProblem =>
      'เซิร์ฟเวอร์ Epicbox แจ้งว่ามีปัญหา กำลังลองใหม่';

  @override
  String get homeNoticePaymentFailed => 'ทำรายการหนึ่งให้เสร็จไม่ได้';

  @override
  String get homeBackupCardText => 'สำรองวลีกู้คืน';

  @override
  String get homeBackupCardButton => 'สำรอง';

  @override
  String get homeBackupCardDismiss => 'ปิด';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count รายการยังไม่อยู่ในข้อมูลสำรองประวัติ การกู้คืนด้วยวลีกู้คืนได้คืนมาเฉพาะยอดคงเหลือ',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count รายการเป็นรายการใหม่หรือเปลี่ยนไปหลังสำรองประวัติครั้งล่าสุด การกู้คืนด้วยวลีกู้คืนได้คืนมาเฉพาะยอดคงเหลือ',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'ไว้ทีหลัง';

  @override
  String get homeHistoryExportButton => 'ส่งออกข้อมูลสำรองประวัติ';

  @override
  String get homeBalanceSpendable => 'ใช้ได้';

  @override
  String get balanceHelpLabel => 'ความหมายของยอดแต่ละแบบ';

  @override
  String get balanceTotal => 'ทั้งหมด';

  @override
  String balanceHelpRow(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get balanceTotalHelp =>
      'ทุกอย่างในกระเป๋าเงินนี้ ทั้งที่ใช้ได้และยังใช้ไม่ได้';

  @override
  String get homeBalanceHiddenLabel => 'ซ่อนยอดคงเหลืออยู่';

  @override
  String get homeShowBalances => 'แสดงยอดเงิน';

  @override
  String get homeHideBalances => 'ซ่อนยอดเงิน';

  @override
  String get homeBalanceConfirming => 'กำลังยืนยัน';

  @override
  String get balanceConfirmingHelp => 'อยู่บนบล็อกเชนแล้ว รอการยืนยันให้ครบ';

  @override
  String get homeBalanceNotOnChain => 'ยังไม่อยู่บนบล็อกเชน';

  @override
  String get balanceNotOnChainHelp =>
      'รายการถึงคุณที่ผู้ส่งยังทำไม่เสร็จหรือยังไม่เข้าบล็อก และเงินทอนจากการส่งของคุณ ยังไม่นับจนกว่าจะอยู่บนบล็อกเชน: รายการที่เพิ่งเสนอมาอาจไม่เข้าเลยก็ได้';

  @override
  String get homeBalanceLocked => 'ล็อกไว้สำหรับรายการที่กำลังทำ';

  @override
  String get balanceLockedHelp =>
      'กันไว้สำหรับรายการที่คุณเริ่มส่ง เงินทอนจะกลับมาเมื่อรายการสำเร็จ';

  @override
  String get homeBalanceImmature => 'รางวัลการขุดที่ยังใช้ไม่ได้';

  @override
  String get balanceImmatureHelp =>
      'รางวัลการขุดต้องรอครบจำนวนบล็อกที่กำหนดก่อนจึงใช้ได้';

  @override
  String get balanceLineAllConfirmed => 'ยืนยันครบแล้ว';

  @override
  String get balanceLineNothingYet => 'ยังไม่มีอะไร';

  @override
  String get homeSyncSyncing => 'กำลังซิงก์…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'กำลังซิงก์… $percent%';
  }

  @override
  String get homeSyncNodeUnreachable =>
      'เชื่อมต่อโหนดไม่ได้ ยอดเงินอาจไม่เป็นปัจจุบัน';

  @override
  String get homeSyncNotValidated =>
      'ยังไม่ได้ตรวจกับโหนด ยอดเงินอาจไม่เป็นปัจจุบัน';

  @override
  String get homeSyncUpToDate => 'เป็นปัจจุบันแล้ว';

  @override
  String get homeSyncContactingNode => 'กำลังติดต่อโหนด…';

  @override
  String get statusNodeOnline => 'โหนดออนไลน์';

  @override
  String get statusNodeSyncing => 'โหนดกำลังซิงก์';

  @override
  String statusNodeSyncingPercent(int percent) {
    return 'โหนดกำลังซิงก์ $percent%';
  }

  @override
  String get statusNodeConnecting => 'กำลังเชื่อมต่อโหนด';

  @override
  String get statusNodeOffline => 'โหนดออฟไลน์';

  @override
  String get statusEpicboxOnline => 'Epicbox ออนไลน์';

  @override
  String get statusEpicboxConnecting => 'กำลังเชื่อมต่อ Epicbox';

  @override
  String get statusEpicboxOffline => 'Epicbox ออฟไลน์';

  @override
  String statusNodeTestNetwork(String network) {
    return '$network, เหรียญทดสอบ';
  }

  @override
  String statusNodeHost(Object host) {
    return 'โหนด: $host';
  }

  @override
  String statusNodeVersion(Object version) {
    return 'โหนดเวอร์ชัน $version';
  }

  @override
  String statusRelay(Object relay) {
    return 'เซิร์ฟเวอร์: $relay';
  }

  @override
  String get homeEpicboxOffline => 'Epicbox ออฟไลน์ กำลังเชื่อมต่อใหม่';

  @override
  String get homeEpicboxConnecting => 'กำลังเชื่อมต่อ Epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'ซิงก์ที่บล็อก $height';
  }

  @override
  String homePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการกำลังรอผู้รับ',
    );
    return '$_temp0';
  }

  @override
  String homePendingBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$amount กำลังรอกระเป๋าเงินของผู้รับตอบกลับ ระหว่างนี้ยอดเงินจะถูกล็อก ถ้าไม่มีคำตอบ ให้เปิดรายการแล้วแตะ ยกเลิกรายการ',
    );
    return '$_temp0';
  }

  @override
  String get homePendingWhy => 'ทำไมต้องรอ?';

  @override
  String homePendingView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ดูรายการ',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPayments => 'ยังไม่มีรายการ';

  @override
  String get invoicesTitle => 'ใบแจ้งหนี้';

  @override
  String invoicesEntryTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใบแจ้งหนี้ รออยู่ $count ใบ',
      zero: 'ใบแจ้งหนี้',
    );
    return '$_temp0';
  }

  @override
  String get invoicesChecking => 'กำลังตรวจหาใบแจ้งหนี้';

  @override
  String get invoicesEmpty =>
      'ไม่มีใบแจ้งหนี้รออยู่ เมื่อบริการที่คุณเชื่อถือเรียกเก็บเงิน ใบแจ้งหนี้จะแสดงที่นี่ และจะไม่มีการจ่ายจนกว่าคุณจะอนุมัติ';

  @override
  String get invoicesUnnamedService => 'บริการไม่มีชื่อ';

  @override
  String invoiceTimeLeftHours(int hours, int minutes) {
    return 'เหลือ $hours ชั่วโมง $minutes นาที';
  }

  @override
  String invoiceTimeLeftMinutes(int minutes) {
    return 'เหลือ $minutes นาที';
  }

  @override
  String get invoiceTimeLeftUnderMinute => 'เหลือไม่ถึง 1 นาที';

  @override
  String get invoiceExpired => 'ใบแจ้งหนี้นี้หมดอายุแล้ว ไม่มีการจ่ายเงิน';

  @override
  String get invoiceGone => 'ใบแจ้งหนี้นี้ไม่เปิดอยู่แล้ว ไม่มีการจ่ายเงิน';

  @override
  String get invoiceReviewTitle => 'ตรวจสอบใบแจ้งหนี้';

  @override
  String invoiceReviewAsks(String service) {
    return '$service ขอให้คุณชำระ';
  }

  @override
  String get invoiceReviewMessageLabel => 'ข้อความจากบริการ';

  @override
  String get invoiceReviewNote =>
      'กระเป๋าเงินจะบวกค่าธรรมเนียมเครือข่ายให้ ไม่มีการจ่ายจนกว่าคุณจะอนุมัติ';

  @override
  String get invoiceApprove => 'อนุมัติและชำระ';

  @override
  String get invoiceDecline => 'ปฏิเสธ';

  @override
  String get invoicePinReason => 'ใส่ PIN เพื่อชำระใบแจ้งหนี้นี้';

  @override
  String get invoiceDeclineTitle => 'ปฏิเสธใบแจ้งหนี้นี้ไหม?';

  @override
  String invoiceDeclineBody(String service) {
    return '$service จะได้รับแจ้งว่าคุณปฏิเสธ ไม่มีการจ่ายเงิน';
  }

  @override
  String get invoiceDeclineKeep => 'เก็บไว้';

  @override
  String get invoiceDeclinedNotice => 'ปฏิเสธใบแจ้งหนี้แล้ว';

  @override
  String invoicePaidNotice(String service) {
    return 'ชำระแล้ว $service จะทำรายการให้เสร็จต่อ';
  }

  @override
  String invoiceReplyFailedTitle(String service) {
    return 'การชำระเงินยังไม่ถึง $service';
  }

  @override
  String get invoiceReplyFailedBody =>
      'รายการลงนามแล้วและเก็บไว้บนอุปกรณ์นี้ ลองอีกครั้ง จะส่งซ้ำโดยไม่ต้องอนุมัติใหม่';

  @override
  String get invoiceReplyFailedNotice =>
      'การชำระเงินไปไม่ถึงบริการ แตะ ลองอีกครั้ง เพื่อส่งซ้ำ';

  @override
  String get invoiceRetry => 'ลองอีกครั้ง';

  @override
  String get invoiceDetailsSection => 'ใบแจ้งหนี้';

  @override
  String get invoiceDetailsService => 'เรียกเก็บโดย';

  @override
  String invoiceDetailsReplied(String service) {
    return 'รอ $service ส่งรายการเข้าเครือข่าย';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service แจ้งว่าส่งรายการเข้าเครือข่ายแล้ว จะสำเร็จเมื่อเครือข่ายยืนยัน';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service ยังไม่ได้รับการชำระเงิน ลองอีกครั้ง จะส่งซ้ำโดยไม่ต้องอนุมัติใหม่';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '$service เรียกคืนใบแจ้งหนี้นี้หลังคุณชำระแล้ว ถ้ารายการไม่ได้รับการยืนยัน ให้ยกเลิกเพื่อปลดล็อกยอดเงิน';
  }

  @override
  String get invoiceNoticeReceived => 'มีใบแจ้งหนี้รอการอนุมัติ';

  @override
  String get invoiceNoticePosted =>
      'บริการแจ้งว่าส่งรายการของคุณเข้าเครือข่ายแล้ว';

  @override
  String get invoiceNoticeWithdrawnPaid =>
      'บริการเรียกคืนใบแจ้งหนี้ที่คุณชำระไปแล้ว';

  @override
  String get invoiceNoticeWithdrawn => 'บริการเรียกคืนใบแจ้งหนี้ก่อนคุณตอบ';

  @override
  String get invoiceNoticeExpired => 'ใบแจ้งหนี้หมดอายุก่อนคุณตอบ';

  @override
  String get receiveRequestTitle => 'ขอรับเงิน';

  @override
  String get requestTitle => 'ขอรับเงิน';

  @override
  String get requestStepsIntro =>
      'กระเป๋าเงินของผู้จ่ายต้องรับใบแจ้งหนี้ได้ ก่อนขอรับเงิน:';

  @override
  String get requestStepTrust =>
      '1. ผู้จ่ายเพิ่มที่อยู่ของคุณด้านล่างในบริการที่เชื่อถือ';

  @override
  String get requestStepAddress =>
      '2. ผู้จ่ายให้ที่อยู่สำหรับใบแจ้งหนี้ของเขามา';

  @override
  String get requestYourAddress => 'ที่อยู่ของคุณ';

  @override
  String get requestPayerLabel => 'ที่อยู่สำหรับใบแจ้งหนี้ของผู้จ่าย';

  @override
  String get requestPayerMissing =>
      'วางหรือสแกนที่อยู่สำหรับใบแจ้งหนี้ของผู้จ่าย';

  @override
  String get requestPayerOwn =>
      'นี่คือที่อยู่ของคุณเอง ใส่ที่อยู่สำหรับใบแจ้งหนี้ที่ผู้จ่ายให้มา';

  @override
  String get requestMessageLabel => 'ข้อความถึงผู้จ่าย (ไม่บังคับ)';

  @override
  String get requestMessageHelper => 'ผู้จ่ายจะเห็นข้อความนี้พร้อมคำขอ';

  @override
  String get requestButton => 'ขอรับเงิน';

  @override
  String requestSentNotice(String payer) {
    return 'ส่งคำขอถึง $payer แล้ว';
  }

  @override
  String get invoicesToPaySection => 'ต้องชำระ';

  @override
  String get invoicesNoneToPay => 'ไม่มีรายการต้องชำระ';

  @override
  String get invoicesSentSection => 'คำขอที่ส่งไป';

  @override
  String get issuedPaid => 'ชำระแล้ว';

  @override
  String get issuedDeclined => 'ถูกปฏิเสธ';

  @override
  String get issuedWithdrawn => 'เรียกคืนแล้ว';

  @override
  String get issuedExpired => 'หมดอายุ';

  @override
  String get issuedWithdraw => 'เรียกคืน';

  @override
  String get issuedWithdrawTitle => 'เรียกคืนคำขอนี้ไหม?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer จะชำระคำขอนี้ไม่ได้อีก ย้อนกลับไม่ได้';
  }

  @override
  String get issuedWithdrawKeep => 'เก็บไว้';

  @override
  String get issuedDetailsSection => 'คำขอรับเงิน';

  @override
  String get issuedDetailsPayer => 'ขอจาก';

  @override
  String get issuedDetailsWaiting =>
      'รอผู้จ่าย กระเป๋าเงินจะทำรายการให้เสร็จเมื่อได้รับ';

  @override
  String get issuedDetailsPaid =>
      'ชำระแล้ว กระเป๋าเงินทำรายการเสร็จแล้ว จะสำเร็จเมื่อเครือข่ายยืนยัน';

  @override
  String get issuedDetailsDeclined =>
      'ผู้จ่ายปฏิเสธคำขอนี้ จึงถูกเรียกคืน ไม่มีการจ่ายเงิน';

  @override
  String get issuedDetailsWithdrawn =>
      'คุณเรียกคืนคำขอนี้แล้ว ไม่มีการจ่ายเงิน';

  @override
  String get issuedDetailsExpired =>
      'คำขอนี้หมดอายุก่อนมีการชำระ ไม่มีการจ่ายเงิน';

  @override
  String get issuerNoticePaid => 'คำขอที่คุณส่งได้รับการชำระแล้ว';

  @override
  String get issuerNoticeDeclined => 'คำขอที่คุณส่งถูกปฏิเสธ';

  @override
  String get issuerNoticeWithdrawn => 'เรียกคืนคำขอแล้ว ชำระไม่ได้อีก';

  @override
  String get issuerNoticeExpired => 'คำขอที่คุณส่งหมดอายุโดยไม่มีการชำระ';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'กระเป๋าเงินของ $payer ชำระคำขอไม่ได้และส่งคืนมา คำขอจึงถูกเรียกคืน ขอให้เขาส่งเงินมาแทน ไปยังที่อยู่ของคุณหรือเป็นไฟล์รายการ';
  }

  @override
  String get issuedBounced => 'ถูกส่งคืน';

  @override
  String get issuedDetailsBounced =>
      'กระเป๋าเงินของผู้จ่ายชำระคำขอไม่ได้และส่งคำขอนี้คืนมา จึงถูกเรียกคืน ไม่มีการจ่ายเงิน ขอให้เขาส่งเงินมาแทน ไปยังที่อยู่ของคุณหรือเป็นไฟล์รายการ';

  @override
  String get requestPayerNoInvoices =>
      'กระเป๋าเงินนี้เคยส่งคำขอคืนมาแล้ว: ชำระคำขอไม่ได้ ขอให้เขาส่งเงินมาแทน ไปยังที่อยู่ของคุณหรือเป็นไฟล์รายการ';

  @override
  String get txStatusWaitingPayer => 'รอผู้จ่าย';

  @override
  String get txStepRequested => 'ขอแล้ว';

  @override
  String get txStepPaid => 'ชำระแล้ว';

  @override
  String get txDetailsWaitingPayer =>
      'คุณขอรับเงินรายการนี้ ยังไม่มีเงินเข้า จะเข้าเมื่อผู้จ่ายชำระคำขอ';

  @override
  String get txDetailsRequestEnded =>
      'คำขอนี้สิ้นสุดโดยไม่มีการชำระ ไม่มีเงินเข้า';

  @override
  String get txDetailsRequestedFrom => 'ขอจาก';

  @override
  String get txPaymentRequest => 'คำขอรับเงิน';

  @override
  String txSpokenRequesting(String amount) {
    return 'ขอรับ $amount';
  }

  @override
  String txSpokenRequestingFrom(String amount, String who) {
    return 'ขอรับ $amount จาก $who';
  }

  @override
  String get receiveEpicboxConnected => 'เชื่อมต่อ Epicbox แล้ว';

  @override
  String get receiveQrLabel => 'QR Code ของที่อยู่คุณ';

  @override
  String get receiveAddressLabel => 'ที่อยู่ Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'รายการที่ส่งถึงคุณตอนนี้จะรออยู่ที่ Epicbox และเข้าเมื่อกระเป๋าเงินเชื่อมต่อได้อีกครั้ง';

  @override
  String get receiveShareCardHeadline => 'จ่ายให้ฉันด้วย Epic Cash';

  @override
  String get receiveHelpButton => 'การรับเงินทำงานอย่างไร';

  @override
  String get receiveAddressCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get receiveFileTitle => 'รับด้วยไฟล์รายการ';

  @override
  String get receiveFileBody =>
      'ได้ไฟล์รายการจากใครมาไหม? เปิดไฟล์ หรือคัดลอกข้อความแล้ววางที่นี่';

  @override
  String get receiveFileOpen => 'เปิดไฟล์';

  @override
  String get receivePasteEmpty => 'คัดลอกข้อความรายการก่อน แล้วแตะ วาง';

  @override
  String get updateChecking => 'กำลังตรวจหาอัปเดต…';

  @override
  String get updateUpToDate => 'นี่คือเวอร์ชันล่าสุด';

  @override
  String get updateNoInformation => 'ไม่มีข้อมูลอัปเดต';

  @override
  String updateAvailable(String version) {
    return 'มีเวอร์ชัน $version แล้ว';
  }

  @override
  String updateDownloading(String version, int percent) {
    return 'กำลังดาวน์โหลดเวอร์ชัน $version… $percent%';
  }

  @override
  String updateInstalling(String version) {
    return 'กำลังติดตั้งเวอร์ชัน $version…';
  }

  @override
  String get updateFailed => 'อัปเดตไม่สำเร็จ';

  @override
  String get updateInstallButton => 'อัปเดต';

  @override
  String get updateTryAgain => 'ลองอีกครั้ง';

  @override
  String get updateDownloadProgressLabel => 'ความคืบหน้าการดาวน์โหลด';

  @override
  String get updateAllowInstalls =>
      'อนุญาตการติดตั้งจาก Epic Cash Mobile แล้วกลับมาที่นี่';

  @override
  String updateNotInstalled(String detail) {
    return 'ไม่ได้ติดตั้งอัปเดต: $detail';
  }

  @override
  String updateCannotInstall(String detail) {
    return 'ติดตั้งอัปเดตไม่ได้: $detail';
  }

  @override
  String get updateCannotInstallUnknown =>
      'ติดตั้งอัปเดตไม่ได้: ข้อผิดพลาดที่ไม่ทราบสาเหตุ';

  @override
  String get updateNeedsReinstall =>
      'อัปเดตนี้ลงนามด้วยคีย์ใหม่ จึงติดตั้งทับเวอร์ชันนี้ไม่ได้ ต้องติดตั้งใหม่ และการถอนการติดตั้งจะลบกระเป๋าเงินนี้ออกจากอุปกรณ์: จดวลีกู้คืนก่อน แล้วถอนการติดตั้งแอปนี้และติดตั้งเวอร์ชันใหม่';

  @override
  String get updateManifestNotJson => 'ข้อมูลอัปเดตไม่ใช่ JSON ที่ถูกต้อง';

  @override
  String get updateManifestWrongShape => 'ข้อมูลอัปเดตมีรูปแบบไม่ถูกต้อง';

  @override
  String get updateManifestOtherApp => 'ข้อมูลอัปเดตเป็นของแอปอื่น';

  @override
  String get updateManifestNoApks => 'ข้อมูลอัปเดตไม่มีไฟล์ APK';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'ดาวน์โหลดไม่สำเร็จ (HTTP $status)';
  }

  @override
  String get updateDownloadTooLarge => 'ไฟล์ที่ดาวน์โหลดใหญ่กว่าที่แจ้งไว้';

  @override
  String get updateDownloadIncomplete => 'ดาวน์โหลดไม่ครบ';

  @override
  String get updateDownloadDamaged =>
      'ไฟล์ที่ดาวน์โหลดเสียหาย (checksum ไม่ตรง)';

  @override
  String get updateDownloadInterrupted => 'การดาวน์โหลดถูกขัดจังหวะ';

  @override
  String get updateServerUnreachable => 'เชื่อมต่อเซิร์ฟเวอร์อัปเดตไม่ได้';

  @override
  String updateServerHttpStatus(int status) {
    return 'เซิร์ฟเวอร์อัปเดตตอบกลับ HTTP $status';
  }

  @override
  String get updateServerTimeout => 'เซิร์ฟเวอร์อัปเดตไม่ตอบกลับในเวลาที่กำหนด';

  @override
  String get updateConnectionFailed =>
      'การเชื่อมต่อกับเซิร์ฟเวอร์อัปเดตล้มเหลว';

  @override
  String get updateCheckFailed => 'ตรวจหาอัปเดตไม่สำเร็จ';

  @override
  String get setupTitle => 'โหนดและ Epicbox';

  @override
  String get setupNetworkSettingsTooltip => 'โหนดและ Epicbox';

  @override
  String get setupNetworkHeading => 'เครือข่าย';

  @override
  String get setupNodeUrlLabel => 'URL ของโหนด';

  @override
  String get setupNodeUrlInvalid =>
      'ใส่ URL เต็ม เช่น https://node.example.com';

  @override
  String get setupTestConnection => 'ทดสอบการเชื่อมต่อ';

  @override
  String setupTestConnected(String height, String version) {
    return 'เชื่อมต่อแล้ว โหนดอยู่ที่บล็อก $height เวอร์ชัน $version';
  }

  @override
  String setupTestFailed(String error) {
    return 'เชื่อมต่อไม่ได้ $error';
  }

  @override
  String get setupConnectedIconLabel => 'เชื่อมต่อแล้ว';

  @override
  String get setupRelayHeading => 'เซิร์ฟเวอร์ Epicbox';

  @override
  String get setupRelayHint => 'ที่อยู่ของคุณรวมเซิร์ฟเวอร์นี้ไว้ด้วย';

  @override
  String get setupCustomRelayLabel =>
      'เซิร์ฟเวอร์ Epicbox อื่น (host หรือ host:port)';

  @override
  String get setupCustomRelayUse => 'ใช้เซิร์ฟเวอร์นี้';

  @override
  String get setupCustomRelayInvalid => 'ใส่ host เช่น epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      'การเปลี่ยนเซิร์ฟเวอร์ Epicbox จะเปลี่ยนที่อยู่ของคุณ ให้ที่อยู่ใหม่กับผู้ส่ง รายการที่ส่งไปที่อยู่เดิมจะรออยู่บนเซิร์ฟเวอร์เดิมจนกว่าจะเปลี่ยนกลับ';

  @override
  String get setupWalletPerNetwork =>
      'แต่ละเครือข่ายมีกระเป๋าเงินของตัวเอง เครือข่ายที่ยังไม่มีจะได้กระเป๋าเงินใหม่';

  @override
  String get setupRelayHealthyIconLabel => 'ทำงานปกติ';

  @override
  String get setupRelayDownIconLabel => 'ล่ม';

  @override
  String get setupRelayHealthUnavailable =>
      'ไม่มีข้อมูลสถานะเซิร์ฟเวอร์จาก status.btlabs.uk';

  @override
  String get setupRelayHealthSource =>
      'สถานะจาก status.btlabs.uk วัดจากเซิร์ฟเวอร์ของเว็บนั้น';

  @override
  String get setupRelayNotMonitored => 'ไม่ได้ตรวจสอบ';

  @override
  String get setupRelayUp => 'ทำงาน';

  @override
  String get setupRelayDown => 'ล่ม';

  @override
  String get setupRelayOfficial => 'ทางการ';

  @override
  String setupRelayUptime(String percent) {
    return 'ทำงาน $percent% ในวันที่ผ่านมา';
  }

  @override
  String get restoreTitle => 'กู้คืนกระเป๋าเงิน';

  @override
  String get restorePhraseLabel => 'วลีกู้คืน';

  @override
  String get restorePhraseHelper => 'ทุกคำ (12 ถึง 24 คำ) คั่นด้วยช่องว่าง';

  @override
  String get restoreStartHeading => 'เริ่มสแกนจากไหน';

  @override
  String get restoreStartByDate => 'วันที่';

  @override
  String get restoreStartByHeight => 'ความสูงบล็อก';

  @override
  String get restoreStartHeightLabel => 'บล็อกเริ่มต้น (ไม่บังคับ)';

  @override
  String get restoreStartHeightHelper =>
      'สแกนตั้งแต่บล็อกนี้ เว้นว่างไว้เพื่อสแกนทั้งบล็อกเชน';

  @override
  String get restoreStartHeightInvalid => 'บล็อกเริ่มต้นต้องเป็นจำนวนเต็ม';

  @override
  String get restoreBackToPhrase => 'กลับไปที่วลี';

  @override
  String get restoreDatePickerTitle => 'สร้างกระเป๋าเงินเมื่อไร?';

  @override
  String get restorePickDate => 'เลือกวันที่สร้างกระเป๋าเงิน';

  @override
  String restoreFromDate(String date) {
    return 'ตั้งแต่ $date';
  }

  @override
  String get restoreDateHint =>
      'ไม่บังคับ ถ้าไม่แน่ใจ ให้เลือกวันที่ก่อนหน้านั้น วันที่หลังรายการแรกจะทำให้ยอดเงินบางส่วนหายไป ถ้าไม่ใส่วันที่จะสแกนทั้งบล็อกเชน ซึ่งใช้เวลานานกว่า';

  @override
  String restoreDateStart(String height) {
    return 'เริ่มสแกนสองวันก่อนวันที่นี้ ตั้งแต่บล็อก $height';
  }

  @override
  String get restoreWholeChain => 'สแกนทั้งบล็อกเชนแทน';

  @override
  String get restoreScanIntro =>
      'กำลังค้นหายอดเงินของคุณบนบล็อกเชน เปิดแอปไว้จนกว่าจะเสร็จ';

  @override
  String get restoreOpenWallet => 'เปิดกระเป๋าเงิน';

  @override
  String get restoreRescanLater => 'สแกนใหม่ทั้งหมดได้ภายหลังจากการตั้งค่า';

  @override
  String get restoreDoneIconLabel => 'เสร็จสิ้น';

  @override
  String get restoreDoneTitle => 'กู้คืนกระเป๋าเงินแล้ว';

  @override
  String get restoreImportExplanation =>
      'บล็อกเชนเก็บยอดคงเหลือ แต่ไม่ได้เก็บว่าคุณจ่ายให้ใคร ค่าธรรมเนียม หรือบันทึก ถ้าเคยส่งออกข้อมูลสำรองประวัติจากกระเป๋าเงินนี้ ให้นำเข้าตอนนี้เพื่อได้ข้อมูลคืน คือไฟล์ .wfeh ที่คุณแชร์หรือบันทึกไว้นอกโทรศัพท์เครื่องเก่า';

  @override
  String get restoreImportButton => 'นำเข้าข้อมูลสำรองประวัติ';

  @override
  String get restoreImportNotNow => 'ไว้ทีหลัง';

  @override
  String get restoreImportLater => 'นำเข้าได้ภายหลังจากการตั้งค่า';

  @override
  String get restoreScanProgressLabel => 'ความคืบหน้าการสแกน';

  @override
  String get firstRunTitle => 'ยินดีต้อนรับ';

  @override
  String get firstRunRestore => 'มีกระเป๋าเงินอยู่แล้ว: กู้คืน';

  @override
  String get firstRunSecuring => 'กำลังรักษาความปลอดภัยกระเป๋าเงิน…';

  @override
  String get firstRunTryAgain => 'ลองอีกครั้ง';

  @override
  String get firstRunBiometricsNotSetUp =>
      'ยังไม่ได้ตั้งค่าการปลดล็อกด้วยไบโอเมตริก เปิดได้ในการตั้งค่า';

  @override
  String get backupTitle => 'วลีกู้คืน';

  @override
  String get backupPinReason => 'ใส่ PIN เพื่อแสดงวลีกู้คืน';

  @override
  String get backupCopyWarning =>
      'ภาพหน้าจอหรือรูปถ่ายของวลีคือสำเนาเต็มของกระเป๋าเงิน: ใครเห็นก็นำเงินไปได้ และแอปรูปภาพอาจอัปโหลดขึ้นคลาวด์ จดบนกระดาษปลอดภัยที่สุด';

  @override
  String get backupCopyAgree => 'จะเก็บสำเนาของวลีไว้เป็นความลับ';

  @override
  String get backupShowPhrase => 'แสดงวลีกู้คืน';

  @override
  String get backupWarningIconLabel => 'คำเตือน';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'จด $count คำนี้ลงกระดาษตามลำดับ และเก็บเป็นความลับ เป็นทางเดียวที่จะกู้คืนกระเป๋าเงินนี้',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return 'คำที่ $number: $word';
  }

  @override
  String get unlockTitle => 'ปลดล็อกกระเป๋า';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinRepeatLabel => 'ป้อน PIN อีกครั้ง';

  @override
  String pinChooseTitle(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'ตั้ง PIN $digits หลัก',
    );
    return '$_temp0';
  }

  @override
  String get pinConfirmTitle => 'ป้อน PIN อีกครั้ง';

  @override
  String get pinChooseDifferent => 'ตั้ง PIN ใหม่';

  @override
  String get pinMismatch => 'PIN ไม่ตรงกัน ตั้ง PIN ใหม่อีกครั้ง';

  @override
  String get pinBiometricsIconLabel => 'ไบโอเมตริก';

  @override
  String get pinBiometricsQuestion => 'ปลดล็อกด้วยลายนิ้วมือหรือใบหน้าไหม?';

  @override
  String get pinBiometricsPinStillWorks => 'ยังใช้ PIN ได้ทุกเมื่อ';

  @override
  String get pinBiometricsEnable => 'ใช้ไบโอเมตริก';

  @override
  String get pinBiometricsNotNow => 'ไว้ทีหลัง';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN ไม่ถูกต้อง ลองได้อีก $count ครั้งก่อนต้องรอ',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN ไม่ถูกต้อง ครั้งถัดไปจะตรวจหลังจาก $count วินาที',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN ไม่ถูกต้อง ครั้งถัดไปจะตรวจหลังจาก $count นาที',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จะตรวจ PIN ใน $count วินาที…',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จะตรวจ PIN ใน $count นาที…',
    );
    return '$_temp0';
  }

  @override
  String get pinChecking => 'กำลังตรวจ PIN…';

  @override
  String get pinPromptTitle => 'ป้อน PIN';

  @override
  String get pinUseBiometrics => 'ใช้ไบโอเมตริก';

  @override
  String get pinForgot => 'ลืม PIN?';

  @override
  String get pinResetTitle => 'ลืม PIN';

  @override
  String get pinResetBody =>
      'ไม่สามารถกู้คืน PIN ได้ ลบกระเป๋านี้ออกจากอุปกรณ์แล้วกู้คืนจากวลีกู้คืนได้ หากไม่มีวลีกู้คืน เงินในกระเป๋าจะสูญหายถาวร';

  @override
  String get pinResetConfirm => 'มีวลีกู้คืนอยู่แล้ว';

  @override
  String get pinResetKeep => 'เก็บกระเป๋าไว้';

  @override
  String get pinResetDelete => 'ลบกระเป๋า';

  @override
  String get launchTryAgain => 'ลองอีกครั้ง';

  @override
  String get unlockStranded =>
      'อ่านข้อมูลกระเป๋านี้ไม่ได้ตามปกติ ไม่มีข้อมูลใดถูกลบ รีสตาร์ทอุปกรณ์แล้วลองอีกครั้ง หากยังเป็นอยู่ ลบกระเป๋าได้ด้วย “ลืม PIN?” แล้วกู้คืนจากวลีกู้คืน';

  @override
  String get sendAmountNegative => 'จำนวนต้องไม่ติดลบ';

  @override
  String sendAmountAmbiguous(String asWhole, String asDecimal) {
    return 'เขียนเป็น $asWhole หรือ $asDecimal เพื่อให้จำนวนชัดเจน';
  }

  @override
  String get sendAmountUnclear =>
      'เขียนจำนวนโดยไม่มีตัวคั่น เช่น 1234.5 เพื่อให้จำนวนชัดเจน';

  @override
  String get sendAmountNoPrice => 'ไม่มีราคาในขณะนี้ ป้อนเป็น EPIC แทน';

  @override
  String get sendAmountEnterFiatExample => 'ป้อนจำนวน เช่น 10.50';

  @override
  String get sendAmountTooLarge =>
      'จำนวน EPIC มากกว่าที่จะมีอยู่จริง ตรวจสอบจำนวนอีกครั้ง';

  @override
  String get sendAmountZero => 'ป้อนจำนวนที่มากกว่าศูนย์';

  @override
  String get sendUrlUnsupported =>
      'ไม่รองรับการส่งไปยัง URL ของกระเป๋า ขอที่อยู่ Epicbox จากผู้รับ';

  @override
  String get scanQrTooltip => 'สแกน QR Code';

  @override
  String get sendScanButton => 'สแกน';

  @override
  String get sendChooseContactTooltip => 'เลือกผู้ติดต่อ';

  @override
  String get sendContactsButton => 'ผู้ติดต่อ';

  @override
  String get sendMethodEpicbox => 'ที่อยู่ Epicbox';

  @override
  String get sendMethodFile => 'ไฟล์ชำระเงิน';

  @override
  String get sendFileHelpTooltip => 'การชำระด้วยไฟล์ทำงานอย่างไร';

  @override
  String sendAmountLabel(String unit) {
    return 'จำนวน ($unit)';
  }

  @override
  String sendUseUnit(String unit) {
    return 'ใช้ $unit';
  }

  @override
  String get sendMax => 'สูงสุด';

  @override
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String get sendCopyPasteInstead => 'คัดลอกและวางแทน';

  @override
  String get sendSlateBoxTitle => 'ข้อความธุรกรรม';

  @override
  String get sendPasteResponseLabel => 'วางคำตอบจากผู้รับ';

  @override
  String get sendPasteResponseMissing => 'วางข้อความตอบกลับจากผู้รับ';

  @override
  String get slateFinishPayment => 'ทำรายการให้เสร็จ';

  @override
  String sendResultAutoCancel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'หากยังไม่เสร็จภายใน $days วัน รายการจะยกเลิกเองและปลดล็อกจำนวนเงิน หากต้องการยกเลิกก่อน ให้เปิดรายการแล้วแตะ ยกเลิกรายการ',
    );
    return '$_temp0';
  }

  @override
  String sendResultFeeChanged(String charged, String reviewed) {
    return 'ค่าธรรมเนียมที่เรียกเก็บคือ $charged ไม่ใช่ $reviewed ที่แสดงก่อนหน้า เพราะกระเป๋าเลือกเหรียญใหม่ตอนส่ง';
  }

  @override
  String get sendResultNoteNotSaved =>
      'บันทึกโน้ตไม่สำเร็จ เพิ่มได้โดยเปิดรายการ';

  @override
  String get sendHelp => 'ช่วยเหลือ';

  @override
  String get sendReviewTotal => 'รวม';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
  }

  @override
  String sendReviewSendButton(String amount) {
    return 'ส่ง $amount';
  }

  @override
  String get sendReviewEdit => 'แก้ไข';

  @override
  String get slateFileTitle => 'ไฟล์ธุรกรรม';

  @override
  String get slateWrongPayment =>
      'คำตอบนี้เป็นของรายการอื่น เปิดไฟล์ที่ผู้รับส่งกลับมาสำหรับการส่งครั้งนี้';

  @override
  String get slateInvoiceUnsupported => 'ยังไม่รองรับคำขอรับเงิน (ใบแจ้งหนี้)';

  @override
  String get slateNotTransactionFile => 'ไฟล์นี้ไม่ใช่ไฟล์ธุรกรรม';

  @override
  String get slateReading => 'กำลังอ่านไฟล์';

  @override
  String get slateFileTooLarge => 'ไฟล์นี้ใหญ่เกินกว่าจะเป็นไฟล์ธุรกรรม';

  @override
  String slatePostedHeadline(String amount) {
    return 'ส่งรายการ $amount ไปยังเครือข่ายแล้ว';
  }

  @override
  String slatePostedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จะแสดงเป็น เสร็จสมบูรณ์ หลังยืนยัน $count ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String slateAcceptedHeadline(String file) {
    return 'รับแล้ว ส่ง $file กลับให้ผู้ส่ง';
  }

  @override
  String slateAcceptedBody(String amount) {
    return 'จะได้รับ $amount เมื่อผู้ส่งทำรายการเสร็จและบันทึกลงบล็อกเชนแล้ว';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return 'รับไปแล้ว ส่ง $file กลับให้ผู้ส่งอีกครั้ง';
  }

  @override
  String slateRepeatedBody(String amount) {
    return 'รายการนี้รับไปแล้ว นี่คือคำตอบเดิม ไม่ใช่รายการที่สอง จะได้รับ $amount เมื่อผู้ส่งทำรายการเสร็จและบันทึกลงบล็อกเชนแล้ว';
  }

  @override
  String slateIncomingSend(String amount) {
    return 'มีผู้ส่ง $amount ให้คุณ';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'คำตอบของผู้รับสำหรับการส่ง $amount (ค่าธรรมเนียม $fee)';
  }

  @override
  String get slateIncomingSendHint => 'รับรายการ แล้วส่งไฟล์ตอบกลับให้ผู้ส่ง';

  @override
  String get slateIncomingResponseHint =>
      'ทำรายการให้เสร็จเพื่อส่งไปยังเครือข่าย';

  @override
  String get slateAcceptPayment => 'รับรายการ';

  @override
  String slateHandOverFailed(String file) {
    return 'ส่งต่อ $file ไม่สำเร็จ ลองอีกครั้ง';
  }

  @override
  String get slateSaveToDevice => 'บันทึกลงอุปกรณ์';

  @override
  String slateSaved(String file) {
    return 'บันทึก $file แล้ว';
  }

  @override
  String get slateSaveDialogTitle => 'บันทึกไฟล์ธุรกรรม';

  @override
  String get slateOpenDialogTitle => 'เปิดไฟล์ธุรกรรม';

  @override
  String get slateNotPostedTitle => 'ยังไม่อยู่บนเครือข่าย';

  @override
  String get slateNotPostedBody =>
      'รายการเสร็จแล้ว แต่เครือข่ายยังไม่รับ ระบบจะเผยแพร่อีกครั้งจากหน้ารายการ อย่าส่งซ้ำ';

  @override
  String get slateOpenPayment => 'เปิดรายการ';

  @override
  String get scanQrTitle => 'สแกน QR Code';

  @override
  String get scanQrHint => 'หันกล้องไปที่ QR Code ของผู้รับ';

  @override
  String get scanQrCameraDenied =>
      'กระเป๋าไม่ได้รับอนุญาตให้ใช้กล้อง หากต้องการสแกน ให้อนุญาตการเข้าถึงกล้องสำหรับแอปนี้ในการตั้งค่าโทรศัพท์ หรือวางที่อยู่แทน';

  @override
  String get scanQrCameraFailed =>
      'เปิดกล้องไม่ได้ วางที่อยู่แทน หรือลองอีกครั้ง';

  @override
  String get scanQrTryAgain => 'ลองอีกครั้ง';

  @override
  String get scanQrBack => 'กลับ';

  @override
  String get contactsTitle => 'ผู้ติดต่อ';

  @override
  String get contactsPickTitle => 'เลือกผู้ติดต่อ';

  @override
  String get contactsAdd => 'เพิ่มผู้ติดต่อ';

  @override
  String get contactsEmpty =>
      'ยังไม่มีผู้ติดต่อ เพิ่มคนที่ชำระเงินให้บ่อย จะได้ไม่ต้องวางที่อยู่ทุกครั้ง';

  @override
  String get contactsSearchLabel => 'ค้นหาผู้ติดต่อ';

  @override
  String get contactsNoMatch => 'ไม่พบผู้ติดต่อที่ตรงกัน';

  @override
  String get contactsNameMissing => 'ป้อนชื่อ';

  @override
  String contactsDeleteTitle(String name) {
    return 'ลบ $name ไหม?';
  }

  @override
  String get contactsDeleteBody =>
      'ที่อยู่นี้จะถูกลบออกจากผู้ติดต่อ รายการที่ผ่านมาไม่ได้รับผลกระทบ';

  @override
  String get contactsKeep => 'เก็บไว้';

  @override
  String get contactsEditTitle => 'แก้ไขผู้ติดต่อ';

  @override
  String get contactsNewTitle => 'ผู้ติดต่อใหม่';

  @override
  String get contactsDeleteTooltip => 'ลบผู้ติดต่อ';

  @override
  String get contactsNameLabel => 'ชื่อ';

  @override
  String get contactsAddressLabel => 'ที่อยู่';

  @override
  String contactsDuplicate(String name) {
    return 'ที่อยู่นี้บันทึกไว้แล้วในชื่อ $name';
  }

  @override
  String get contactsNoteLabel => 'บันทึก (ไม่บังคับ)';

  @override
  String get contactsSave => 'บันทึกผู้ติดต่อ';

  @override
  String get contactsAddressMissing => 'ป้อนที่อยู่ของผู้รับ';

  @override
  String contactsUrlIncomplete(String example) {
    return 'ป้อน URL ของกระเป๋าแบบเต็ม เช่น $example';
  }

  @override
  String contactsAddressInvalid(String example) {
    return 'ที่อยู่ไม่ถูกต้อง ที่อยู่ควรมีลักษณะเช่น $example';
  }

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsSectionNetwork => 'เซิร์ฟเวอร์';

  @override
  String get settingsNetworkAndNode => 'โหนดและ Epicbox';

  @override
  String settingsNetworkSubtitle(String network, String node) {
    return '$network · $node';
  }

  @override
  String get settingsSectionDisplay => 'การแสดงผล';

  @override
  String get settingsCurrency => 'สกุลเงิน';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'แสดงราคา';

  @override
  String get settingsHideBalances => 'ซ่อนยอดคงเหลือ';

  @override
  String get settingsTheme => 'ธีม';

  @override
  String get settingsThemeSystem => 'ตามอุปกรณ์';

  @override
  String get settingsThemeLight => 'สว่าง';

  @override
  String get settingsThemeDark => 'มืด';

  @override
  String get settingsPricesOnNotice =>
      'ราคามาจาก CoinGecko ซึ่งจะเห็นที่อยู่ IP ของคุณ';

  @override
  String get settingsSectionNotifications => 'การแจ้งเตือน';

  @override
  String get settingsPushBlocked => 'การแจ้งเตือนถูกบล็อกในการตั้งค่าระบบ';

  @override
  String get settingsPushUnavailable => 'เวอร์ชันนี้ไม่รองรับการแจ้งเตือน';

  @override
  String get settingsSectionSecurity => 'ความปลอดภัย';

  @override
  String get settingsChangePin => 'เปลี่ยน PIN';

  @override
  String get settingsBiometrics => 'ปลดล็อกด้วยไบโอเมตริก';

  @override
  String get settingsBiometricsOn => 'เปิดการปลดล็อกด้วยไบโอเมตริกแล้ว';

  @override
  String get settingsBiometricsOff => 'ปิดการปลดล็อกด้วยไบโอเมตริกแล้ว';

  @override
  String get settingsBiometricsFailed =>
      'ตั้งค่าการปลดล็อกด้วยไบโอเมตริกไม่สำเร็จ';

  @override
  String get settingsBiometricsPinReason =>
      'ป้อน PIN เพื่อเปิดการปลดล็อกด้วยไบโอเมตริก';

  @override
  String get settingsAutoLock => 'ล็อกอัตโนมัติ';

  @override
  String get settingsBackupPhrase => 'สำรองวลีกู้คืน';

  @override
  String get settingsPhraseConfirmed => 'ยืนยันวลีกู้คืนแล้ว';

  @override
  String get settingsLockWallet => 'ล็อกกระเป๋า';

  @override
  String get settingsSectionHistory => 'ประวัติรายการ';

  @override
  String get settingsExportHistory => 'ส่งออกข้อมูลสำรองประวัติ';

  @override
  String get settingsExportCsv => 'ส่งออก CSV';

  @override
  String get settingsImportHistory => 'นำเข้าข้อมูลสำรองประวัติ';

  @override
  String get settingsSectionWallet => 'กระเป๋าเงิน';

  @override
  String get settingsContacts => 'ผู้ติดต่อ';

  @override
  String get settingsSectionInvoices => 'ใบแจ้งหนี้';

  @override
  String get settingsInvoices => 'ที่อยู่ใบแจ้งหนี้และบริการที่เชื่อถือ';

  @override
  String get settingsInvoicesSubtitle =>
      'ให้บริการที่เชื่อถือส่งใบแจ้งหนี้ได้ ทุกใบต้องได้รับการอนุมัติก่อน';

  @override
  String get invoiceSettingsTitle => 'ใบแจ้งหนี้';

  @override
  String get invoiceSettingsAddressTitle => 'ที่อยู่สำหรับใบแจ้งหนี้';

  @override
  String get invoiceSettingsAddressBody =>
      'ให้ที่อยู่นี้กับบริการที่เชื่อถือ เพื่อให้ส่งใบแจ้งหนี้ได้ ที่อยู่สำหรับรับเงินยังคงเดิม';

  @override
  String get invoiceSettingsQrLabel => 'QR Code ของที่อยู่สำหรับใบแจ้งหนี้';

  @override
  String get invoiceSettingsAddressCopied =>
      'คัดลอกที่อยู่สำหรับใบแจ้งหนี้แล้ว';

  @override
  String get invoiceSettingsServicesTitle => 'บริการที่เชื่อถือ';

  @override
  String get invoiceSettingsNoServices =>
      'ยังไม่มีบริการที่เชื่อถือ ใบแจ้งหนี้จากผู้อื่นจะไม่ถึงคุณ';

  @override
  String get invoiceSettingsAddService => 'เพิ่มบริการ';

  @override
  String invoiceSettingsRemoveTooltip(String name) {
    return 'ลบ $name';
  }

  @override
  String invoiceSettingsRemoveTitle(String name) {
    return 'ลบ $name ไหม?';
  }

  @override
  String get invoiceSettingsRemoveBody =>
      'บริการนี้จะส่งใบแจ้งหนี้ไม่ได้อีก การชำระที่ทำไปแล้วไม่ได้รับผลกระทบ';

  @override
  String get invoiceSettingsKeep => 'เก็บไว้';

  @override
  String get invoiceSettingsRemoveConfirm => 'ลบ';

  @override
  String invoiceSettingsRemoved(String name) {
    return '$name ส่งใบแจ้งหนี้ไม่ได้อีกแล้ว';
  }

  @override
  String get invoiceSettingsRotate => 'ขอที่อยู่ใบแจ้งหนี้ใหม่';

  @override
  String get invoiceSettingsRotateHint => 'ที่อยู่ปัจจุบันจะใช้ไม่ได้';

  @override
  String get invoiceSettingsRotateTitle => 'ขอที่อยู่ใบแจ้งหนี้ใหม่ไหม?';

  @override
  String get invoiceSettingsRotateBody =>
      'ที่อยู่ใบแจ้งหนี้ปัจจุบันจะใช้ไม่ได้อีกถาวร ทุกบริการที่ส่งใบแจ้งหนี้ต้องใช้ที่อยู่ใหม่';

  @override
  String get invoiceSettingsRotateConfirm => 'ขอที่อยู่ใหม่';

  @override
  String get invoiceSettingsRotated =>
      'ที่อยู่ใบแจ้งหนี้ใหม่พร้อมแล้ว ส่งให้บริการต่างๆ';

  @override
  String invoiceSettingsDropped(int count) {
    return 'ข้อความจากผู้ส่งที่ไม่รู้จักที่ถูกทิ้งในรอบนี้: $count';
  }

  @override
  String get invoiceSettingsAddTitle => 'เพิ่มบริการที่เชื่อถือ';

  @override
  String get invoiceSettingsAddExplanation =>
      'บริการที่เชื่อถือส่งใบแจ้งหนี้มายังที่อยู่ใบแจ้งหนี้ได้ ข้อความจากผู้อื่นจะถูกทิ้ง ไม่มีการชำระใดๆ จนกว่าจะอนุมัติใบแจ้งหนี้แต่ละใบด้วย PIN หรือลายนิ้วมือ';

  @override
  String get invoiceSettingsLabelLabel => 'ชื่อ';

  @override
  String get invoiceSettingsLabelMissing => 'ตั้งชื่อบริการ';

  @override
  String get invoiceSettingsServiceAddressLabel => 'ที่อยู่ Epicbox ของบริการ';

  @override
  String get invoiceSettingsAddressMissing => 'วางหรือสแกนที่อยู่ที่บริการแสดง';

  @override
  String get invoiceSettingsAddButton => 'เพิ่มบริการ';

  @override
  String invoiceSettingsAdded(String name) {
    return '$name ส่งใบแจ้งหนี้ได้แล้ว';
  }

  @override
  String get settingsRescan => 'ตรวจยอดใหม่';

  @override
  String get settingsRescanFinished => 'สแกนใหม่เสร็จแล้ว';

  @override
  String get settingsRescanTitle => 'ตรวจยอดใหม่';

  @override
  String get settingsRescanBody =>
      'กระเป๋าจะค้นหาเงินอีกครั้ง เริ่มจากจุดที่เก่ากว่าจะพบมากกว่าแต่ใช้เวลานานกว่า การสแกนทั้งบล็อกเชนอาจใช้เวลานาน';

  @override
  String get settingsRescanFromDate => 'จากวันที่';

  @override
  String get settingsRescanFromHeight => 'จากความสูงบล็อก';

  @override
  String get settingsRescanWholeChain => 'ทั้งบล็อกเชน';

  @override
  String get settingsRescanPickDate => 'เลือกวันที่';

  @override
  String get settingsRescanPickDateFirst => 'เลือกวันที่ก่อน';

  @override
  String get settingsRescanStartHeight => 'ความสูงเริ่มต้น';

  @override
  String get settingsRescanHeightInvalid => 'ป้อนความสูงบล็อกตั้งแต่ 1 ขึ้นไป';

  @override
  String get settingsRescanButton => 'สแกนใหม่';

  @override
  String get settingsDeleteWallet => 'ลบกระเป๋านี้';

  @override
  String get settingsDeleteDuringScan => 'รอให้การสแกนเสร็จก่อนลบกระเป๋า';

  @override
  String get settingsDeletePinReason => 'ป้อน PIN เพื่อลบกระเป๋านี้';

  @override
  String get settingsDeleteWarningIcon => 'คำเตือน';

  @override
  String get settingsDeleteTitle => 'ลบกระเป๋านี้ไหม?';

  @override
  String get settingsDeleteBody =>
      'กระเป๋า ประวัติ และ PIN จะถูกลบออกจากอุปกรณ์นี้ มีเพียงวลีกู้คืนที่นำเงินกลับมาได้ หากไม่มีวลีกู้คืน เงินจะสูญหายถาวร';

  @override
  String get settingsDeleteHavePhrase => 'จดวลีกู้คืนไว้แล้ว';

  @override
  String get settingsDeleteConfirmWord => 'ลบ';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return 'พิมพ์ \"$word\" เพื่อยืนยัน';
  }

  @override
  String get settingsDeleteKeep => 'เก็บกระเป๋าไว้';

  @override
  String get settingsDeleteConfirm => 'ลบกระเป๋า';

  @override
  String get settingsSectionAbout => 'เกี่ยวกับ';

  @override
  String get settingsVersion => 'เวอร์ชัน';

  @override
  String get settingsAboutNetwork => 'เครือข่าย';

  @override
  String get settingsEpicboxServer => 'เซิร์ฟเวอร์ Epicbox';

  @override
  String settingsUpdateTo(String version) {
    return 'อัปเดตเป็น $version';
  }

  @override
  String get settingsUpdateInstall => 'ติดตั้ง';

  @override
  String get settingsCheckUpdates => 'ตรวจหาอัปเดต';

  @override
  String get settingsHelp => 'ช่วยเหลือ';

  @override
  String get settingsSendFeedback => 'ส่งความคิดเห็น';

  @override
  String get settingsSendFeedbackHint => 'แจ้งปัญหาหรือเสนอไอเดีย';

  @override
  String get settingsSourceCode => 'ซอร์สโค้ด';

  @override
  String get settingsLicences => 'สัญญาอนุญาต';

  @override
  String get licencesLead =>
      'ซอฟต์แวร์โอเพนซอร์สในกระเป๋านี้ แต่ละส่วนใช้สัญญาอนุญาตของตนเอง ดูข้อความเต็มได้ในแตะเดียว';

  @override
  String get licencesApp =>
      'Epic Cash Mobile โดย BT Labs: Apache-2.0 โค้ดอยู่บน GitHub';

  @override
  String get licencesFlutter =>
      'Flutter และแพ็กเกจ Dart: BSD 3-Clause และสัญญาอนุญาตแบบเปิดที่คล้ายกัน';

  @override
  String get licencesLepic =>
      'LEPIC ไลบรารีกระเป๋า Epic Cash: Apache 2.0 พร้อม Epic Cash secp256k1-zkp fork (CC0) และ Rust crate ภายใต้ MIT หรือ Apache 2.0 เช่น tokio, rustls, rusqlite และ blake2';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License เวอร์ชัน 3 แหล่งซอร์สโค้ดระบุไว้ด้านล่าง';

  @override
  String get licencesFonts =>
      'ฟอนต์ Montserrat และ JetBrains Mono: SIL Open Font License 1.1';

  @override
  String get licencesFull => 'ข้อความสัญญาอนุญาตทั้งหมด';

  @override
  String get settingsCopyLink => 'คัดลอกลิงก์';

  @override
  String get settingsLinkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get settingsPinTitle => 'เปลี่ยน PIN';

  @override
  String get settingsPinEnterCurrent => 'ป้อน PIN ปัจจุบัน';

  @override
  String get settingsPinCurrentLabel => 'PIN ปัจจุบัน';

  @override
  String settingsPinChooseNew(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'ตั้ง PIN ใหม่ $digits หลัก',
    );
    return '$_temp0';
  }

  @override
  String get settingsPinChanged => 'เปลี่ยน PIN แล้ว';

  @override
  String get settingsPinChangedBiometricsOff =>
      'เปลี่ยน PIN แล้ว การปลดล็อกด้วยไบโอเมตริกปิดอยู่ เปิดอีกครั้งได้ด้านล่าง';

  @override
  String get helpTitle => 'ช่วยเหลือ';

  @override
  String get helpStillStuck => 'ยังติดปัญหา?';

  @override
  String get helpTellUs => 'อธิบายสิ่งที่เกิดขึ้นหรือสิ่งที่ไม่ชัดเจน';

  @override
  String get helpSendFeedback => 'ส่งความคิดเห็น';

  @override
  String get feedbackTitle => 'ส่งความคิดเห็น';

  @override
  String get feedbackIntro => 'อธิบายสิ่งที่ผิดพลาดหรือสิ่งที่ควรปรับปรุง';

  @override
  String get feedbackMessageLabel => 'ข้อความ';

  @override
  String get feedbackMessageMissing => 'เขียนสั้นๆ ว่าเกิดอะไรขึ้น';

  @override
  String get feedbackEmailLabel => 'อีเมลสำหรับตอบกลับ (ไม่บังคับ)';

  @override
  String get feedbackEmailInvalid => 'ดูไม่เหมือนที่อยู่อีเมล';

  @override
  String get feedbackAttachLogs => 'แนบล็อกการวินิจฉัย';

  @override
  String get feedbackAttachLogsHint =>
      'ล็อกช่วยหาสาเหตุของปัญหา วลีกู้คืน PIN และข้อมูลลับอื่นๆ จะถูกลบออกก่อน';

  @override
  String get feedbackPreviewButton => 'ดูตัวอย่างสิ่งที่จะส่ง';

  @override
  String get feedbackSend => 'ส่ง';

  @override
  String get feedbackShareOrSaveInstead => 'แชร์หรือบันทึกแทน';

  @override
  String get feedbackFileExplanation =>
      'ความคิดเห็นจะถูกสร้างเป็นไฟล์ข้อความ ส่งทางอีเมลหรือแชต หรือบันทึกไว้ได้';

  @override
  String get feedbackShareOrSave => 'แชร์หรือบันทึก';

  @override
  String get feedbackShareHint => 'ส่งทางอีเมลหรือแอปแชต';

  @override
  String get feedbackSaveToDevice => 'บันทึกลงอุปกรณ์';

  @override
  String get feedbackSaveDialogTitle => 'บันทึกความคิดเห็น';

  @override
  String feedbackSavedFile(String name) {
    return 'บันทึก $name แล้ว';
  }

  @override
  String get feedbackSent => 'ขอบคุณ ส่งความคิดเห็นแล้ว';

  @override
  String get feedbackThanks => 'ขอบคุณสำหรับความคิดเห็น';

  @override
  String feedbackServerAnswered(int status) {
    return 'เซิร์ฟเวอร์รับความคิดเห็นตอบกลับ $status';
  }

  @override
  String get feedbackServerNoAnswer => 'เซิร์ฟเวอร์รับความคิดเห็นไม่ตอบสนอง';

  @override
  String get feedbackServerUnreachable =>
      'เชื่อมต่อเซิร์ฟเวอร์รับความคิดเห็นไม่ได้';

  @override
  String get feedbackPreviewTitle => 'สิ่งที่จะส่ง';

  @override
  String get settingsAdvancedOptions => 'ตัวเลือกขั้นสูง';

  @override
  String get settingsAdvancedOptionsSubtitle =>
      'รายละเอียดทางเทคนิค ไฟล์ และล็อก';

  @override
  String get settingsSectionPrivacy => 'ความเป็นส่วนตัว';

  @override
  String get settingsSectionPrivacyNetwork => 'ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get settingsSectionHelpFeedback => 'ช่วยเหลือและความคิดเห็น';

  @override
  String get settingsStateBackUp => 'สำรองวลีกู้คืน';

  @override
  String get settingsStateNotBackedUp => 'ยังไม่ได้สำรอง';

  @override
  String get settingsStatePin => 'PIN';

  @override
  String get settingsStatePinBiometrics => 'PIN และไบโอเมตริก';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'ใช้ status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'สถานะและข้อมูลเครือข่ายจาก status.btlabs.uk';

  @override
  String get txStepStarted => 'เริ่มรายการแล้ว';

  @override
  String get txStepAccepted => 'ผู้รับยอมรับแล้ว';

  @override
  String get txStepPosted => 'ส่งไปยังเครือข่ายแล้ว';

  @override
  String get txStepConfirming => 'กำลังยืนยัน';

  @override
  String get txStepConfirmed => 'ยืนยันแล้ว';

  @override
  String get txStepArrived => 'ได้รับเงินแล้ว';

  @override
  String get txStepSenderFinished => 'ผู้ส่งทำรายการเสร็จแล้ว';

  @override
  String get fileHelpTitle => 'ไฟล์ชำระเงินทำงานอย่างไร';

  @override
  String get fileHelpYou => 'คุณ';

  @override
  String get fileHelpFriend => 'เพื่อน';

  @override
  String get fileHelpSendStep1 => 'คุณสร้างไฟล์ชำระเงิน';

  @override
  String get fileHelpSendStep2 =>
      'ส่งไฟล์ให้เพื่อนด้วยวิธีใดก็ได้ เช่น แชตหรืออีเมล';

  @override
  String get fileHelpSendStep3 =>
      'เพื่อนเปิดไฟล์ในกระเป๋าของตนแล้วส่งคำตอบที่ลงนามแล้วกลับมา';

  @override
  String get fileHelpSendStep4 => 'คุณเปิดคำตอบ แล้วรายการก็ถูกส่งออกไป';

  @override
  String get fileHelpReceiveStep1 => 'เพื่อนสร้างไฟล์ชำระเงินให้คุณ';

  @override
  String get fileHelpReceiveStep2 =>
      'เพื่อนส่งไฟล์ให้คุณด้วยวิธีใดก็ได้ เช่น แชตหรืออีเมล';

  @override
  String get fileHelpReceiveStep3 =>
      'คุณเปิดไฟล์ในกระเป๋าแล้วส่งคำตอบที่ลงนามแล้วกลับไป';

  @override
  String get fileHelpReceiveStep4 => 'เพื่อนเปิดคำตอบ แล้วเงินก็กำลังมาถึงคุณ';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'ขั้นตอน $step จาก $count';
  }

  @override
  String get fileHelpPause => 'หยุดภาพเคลื่อนไหวชั่วคราว';

  @override
  String get fileHelpPlay => 'เล่นภาพเคลื่อนไหว';

  @override
  String get demoPinFilled => 'PIN ทดลอง กรอกให้แล้ว';

  @override
  String get demoPinSkip => 'ข้าม';

  @override
  String get demoPinSetUpTitle => 'กำลังตั้งค่ากระเป๋าทดลอง';

  @override
  String get demoPinUnlockTitle => 'กำลังเปิดกระเป๋าทดลอง';

  @override
  String get sendStepRecipient => 'ผู้รับ';

  @override
  String get sendStepAmount => 'จำนวน';

  @override
  String get sendStepReview => 'ตรวจสอบ';

  @override
  String sendStepOf(int step, int total) {
    return '$step จาก $total';
  }

  @override
  String get sendHowItWorks => 'ทำงานอย่างไร';

  @override
  String get sendAddressLabel => 'ที่อยู่ Epic';

  @override
  String get sendAddressMissing => 'ป้อนที่อยู่ของผู้รับ';

  @override
  String get sendAddressWebLink => 'นี่คือลิงก์เว็บ ไม่ใช่ที่อยู่ Epic';

  @override
  String get sendAddressIncomplete => 'ที่อยู่นี้ดูเหมือนไม่ครบ';

  @override
  String get sendAddressNotEpic => 'นี่ไม่ใช่ที่อยู่ Epicbox';

  @override
  String get sendNewRecipient => 'ผู้รับใหม่';

  @override
  String get sendSaveContact => 'บันทึกเป็นผู้ติดต่อ';

  @override
  String get sendRecent => 'ล่าสุด';

  @override
  String get sendUseFile => 'ไม่มีที่อยู่? ใช้ไฟล์ชำระเงิน';

  @override
  String sendTo(String who) {
    return 'ถึง $who';
  }

  @override
  String sendAvailable(String amount) {
    return 'ใช้ได้ $amount';
  }

  @override
  String sendFeeQuiet(String fee) {
    return 'ค่าธรรมเนียมเครือข่าย $fee';
  }

  @override
  String get sendAddNote => 'เพิ่มบันทึก';

  @override
  String get sendNoteLabel => 'บันทึก';

  @override
  String get sendNoteHelper => 'ผู้รับเห็นบันทึกนี้ด้วย';

  @override
  String get sendNetworkFee => 'ค่าธรรมเนียม';

  @override
  String get sendChecking => 'กำลังตรวจสอบ…';

  @override
  String get sendReady => 'พร้อมส่ง';

  @override
  String get sendNodeDown => 'เชื่อมต่อเครือข่ายไม่ได้ในขณะนี้';

  @override
  String get sendRelayDown => 'เซิร์ฟเวอร์ของผู้รับไม่ตอบสนอง';

  @override
  String get sendListenerDown => 'ยังไม่ได้เชื่อมต่อ แต่ยังส่งได้';

  @override
  String get sendPayWithFile => 'ชำระด้วยไฟล์แทน';

  @override
  String get sendAnyway => 'ส่งเลย';

  @override
  String sendTrackSentTo(String name) {
    return 'ส่งถึง $name แล้ว';
  }

  @override
  String get sendTrackSent => 'ส่งแล้ว';

  @override
  String sendTrackWaitingFor(String name) {
    return 'รอกระเป๋าของ $name';
  }

  @override
  String get sendTrackWaiting => 'รอกระเป๋าของผู้รับ';

  @override
  String sendTrackSignedBy(String name) {
    return 'กระเป๋าของ $name ลงนามแล้ว';
  }

  @override
  String get sendTrackSigned => 'กระเป๋าของผู้รับลงนามแล้ว';

  @override
  String get sendTrackOnNetwork => 'ส่งไปยังเครือข่ายแล้ว';

  @override
  String get sendTrackConfirmed => 'ยืนยันแล้ว';

  @override
  String sendTrackOffline(String amount) {
    return 'กระเป๋าของผู้รับจะทำรายการให้เสร็จเมื่อเปิดขึ้นมา ระหว่างนี้ $amount จะถูกพักไว้';
  }

  @override
  String get sendTrackIfNot => 'หากรายการไม่เสร็จ?';

  @override
  String get sendTrackCancelled => 'รายการนี้ถูกยกเลิกแล้ว';

  @override
  String get sendNoCoins => 'ยังไม่มีเหรียญให้ส่ง';

  @override
  String get sendFileTitle => 'ชำระด้วยไฟล์';

  @override
  String get sendMakeFile => 'สร้างไฟล์ชำระเงิน';

  @override
  String get sendFileMade => 'สร้างไฟล์แล้ว';

  @override
  String sendFileOnHold(String amount) {
    return 'พัก $amount ไว้';
  }

  @override
  String get sendFileWaitingReply => 'รอคำตอบจากผู้รับ';

  @override
  String get sendFileShareHint =>
      'ส่งไฟล์นี้ให้ผู้รับ แล้วเปิดคำตอบที่ส่งกลับมา';

  @override
  String get sendOpenReply => 'เปิดคำตอบ';

  @override
  String get handshakePayment => 'ชำระเงิน';

  @override
  String get handshakeRequest => 'ขอรับเงิน';

  @override
  String get handshakeYou => 'คุณ';

  @override
  String get handshakeThem => 'อีกฝ่าย';

  @override
  String get handshakeNetwork => 'เครือข่าย';

  @override
  String get handshakePay1 =>
      'กระเป๋าของคุณส่งรายการไปยังเซิร์ฟเวอร์ เหรียญของคุณถูกพักไว้';

  @override
  String get handshakePay2 =>
      'เซิร์ฟเวอร์ส่งต่อไป กระเป๋าของอีกฝ่ายเพิ่มส่วนของตนและลงนาม';

  @override
  String get handshakeFinish =>
      'กระเป๋าของคุณทำรายการให้เสร็จและส่งไปยังเครือข่าย';

  @override
  String get handshakeConfirm => 'เครือข่ายยืนยันรายการ';

  @override
  String get handshakeReq1 => 'กระเป๋าของคุณส่งคำขอไปยังเซิร์ฟเวอร์';

  @override
  String get handshakeReq2 =>
      'เซิร์ฟเวอร์ส่งต่อไป อีกฝ่ายอนุมัติ แล้วกระเป๋าของอีกฝ่ายเพิ่มเหรียญและลงนาม';

  @override
  String get handshakeRelay => 'เซิร์ฟเวอร์';

  @override
  String get handshakeFile => 'ไฟล์';

  @override
  String get handshakeBack => 'กระเป๋าของอีกฝ่ายส่งกลับไปยังเซิร์ฟเวอร์';

  @override
  String get handshakeRelayBack => 'เซิร์ฟเวอร์ส่งกลับมายังกระเป๋าของคุณ';

  @override
  String get handshakeFile1 =>
      'กระเป๋าของคุณบันทึกไฟล์ชำระเงิน คุณส่งไฟล์ให้อีกฝ่ายเอง';

  @override
  String get handshakeFile2 =>
      'อีกฝ่ายเปิดไฟล์ กระเป๋าของอีกฝ่ายเพิ่มส่วนของตน ลงนาม และบันทึกไฟล์ตอบกลับ';

  @override
  String get handshakeFile3 => 'อีกฝ่ายส่งไฟล์ตอบกลับมาให้คุณ';

  @override
  String get handshakeFile4 => 'คุณเปิดไฟล์ตอบกลับในกระเป๋า';

  @override
  String get handshakePrevious => 'ขั้นตอนก่อนหน้า';

  @override
  String get handshakeNext => 'ขั้นตอนถัดไป';

  @override
  String sendRelayRefused(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'เซิร์ฟเวอร์ของผู้รับไม่รับรายการ จำนวนเงินจะถูกพักไว้จนกว่าจะยกเลิก หรือไม่เกิน $days วัน',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost =>
      'เซิร์ฟเวอร์ของผู้รับไม่รับรายการ ตรวจสอบหน้ากระเป๋าก่อนส่งอีกครั้ง';

  @override
  String get sendCancelAndFile => 'ยกเลิกแล้วชำระด้วยไฟล์';

  @override
  String get sendLeaveIt => 'ปล่อยไว้ก่อน';

  @override
  String get sendSending => 'กำลังส่ง…';

  @override
  String trackStepDone(String step) {
    return '$step เสร็จแล้ว';
  }

  @override
  String trackStepNow(String step) {
    return '$step กำลังดำเนินการ';
  }

  @override
  String trackStepLater(String step) {
    return '$step ภายหลัง';
  }

  @override
  String balanceLineOnHold(String amount) {
    return 'พักไว้ $amount';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount กำลังเข้า';
  }

  @override
  String get demoTestCoinsPill => 'เหรียญทดสอบ';

  @override
  String get demoTestCoinsPillTip =>
      'Floonet เครือข่ายทดสอบของ Epic เหรียญไม่มีมูลค่า';

  @override
  String demoLeftHours(int hours) {
    return 'เหลือ $hours ชั่วโมง';
  }

  @override
  String demoLeftMinutes(int minutes) {
    return 'เหลือ $minutes นาที';
  }

  @override
  String get demoReceiveKeepOpen => 'เปิดแท็บนี้ไว้เพื่อรับเงิน';

  @override
  String get demoGuideTitle => 'ลองทำรายการ';

  @override
  String get demoGuideSend => 'ส่งให้ใครสักคน';

  @override
  String get demoGuideSendHint =>
      'ส่งให้เดโมของเพื่อน หรือเปิดหน้านี้ในเบราว์เซอร์อื่นหรือหน้าต่างส่วนตัว';

  @override
  String get demoGuideOpenSend => 'ไปที่ ส่ง';

  @override
  String get demoGuideAsking => 'กำลังขอจาก faucet ทดสอบ อาจใช้เวลาสักครู่';

  @override
  String get demoGuideDone =>
      'เสร็จทั้งสองขั้นตอนแล้ว สำรวจต่อได้ตลอดอายุของเดโม';

  @override
  String get demoGuideHide => 'ซ่อน';

  @override
  String get demoGuideHideLabel => 'ซ่อนขั้นตอนเดโม';

  @override
  String demoGuideStepDone(String step) {
    return '$step เสร็จแล้ว';
  }

  @override
  String demoGuideStepToDo(String step) {
    return '$step ยังไม่เสร็จ';
  }

  @override
  String get receiveTabEpicbox => 'Epicbox';

  @override
  String get receiveTabTor => 'Tor';

  @override
  String get receiveTabFile => 'ไฟล์';

  @override
  String get receiveTorAddressLabel => 'ที่อยู่ Tor';

  @override
  String get receiveTorQrLabel => 'QR Code ของที่อยู่ Tor';

  @override
  String get torReceivingTitle => 'รับผ่าน Tor';

  @override
  String get torHonestLine =>
      'การรับผ่าน Tor ทำงานขณะเปิดแอปอยู่หรืออยู่เบื้องหลังช่วงสั้นๆ';

  @override
  String get torStateOff => 'ปิดการรับผ่าน Tor อยู่';

  @override
  String torStateStarting(int percent) {
    return 'กำลังเชื่อมต่อ Tor… $percent%';
  }

  @override
  String get torStatePublishing => 'กำลังเผยแพร่ที่อยู่ Tor…';

  @override
  String get torStateReady => 'เปิดการรับผ่าน Tor อยู่';

  @override
  String torStateNotReachable(String reason) {
    return 'ยังเข้าถึงที่อยู่ Tor ไม่ได้ $reason';
  }

  @override
  String get torFailureMissing => 'แอปนี้ไม่มี Tor';

  @override
  String get torFailureStart => 'Tor ไม่เริ่มทำงาน';

  @override
  String get torFailureNetwork =>
      'เชื่อมต่อเครือข่าย Tor ไม่ได้ ตรวจสอบการเชื่อมต่อ';

  @override
  String get torFailureClock =>
      'นาฬิกาของโทรศัพท์ไม่ถูกต้อง Tor ต้องใช้เวลาที่ถูกต้อง';

  @override
  String get torFailureListener => 'กระเป๋าเปิดที่อยู่ Tor ไม่ได้';

  @override
  String get torFailureStopped => 'Tor หยุดทำงาน';

  @override
  String get torFailurePublish => 'เผยแพร่ที่อยู่ Tor ไม่ได้';

  @override
  String get torFailureKeys => 'Tor ไม่ยอมรับคีย์ที่อยู่ของกระเป๋า';

  @override
  String get sendOnionIncomplete =>
      'ที่อยู่ Tor ไม่ครบ คัดลอกจากผู้รับอีกครั้ง';

  @override
  String get sendTorUnavailable =>
      'แอปนี้ส่งผ่าน Tor ไม่ได้ จึงชำระไปยังที่อยู่ Tor ที่นี่ไม่ได้';

  @override
  String get sendOverTor => 'ผ่าน Tor';

  @override
  String get sendTorConnectsOnSend => 'Tor จะเชื่อมต่อเมื่อกดส่ง';

  @override
  String get sendTorReady => 'พร้อมส่งผ่าน Tor';

  @override
  String get sendTorReaching =>
      'กำลังติดต่อกระเป๋าของผู้รับผ่าน Tor… อาจใช้เวลาสักพัก เปิดแอปไว้';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'ติดต่อกระเป๋าของผู้รับผ่าน Tor ไม่ได้ จำนวนเงินจะถูกพักไว้จนกว่าจะยกเลิก หรือไม่เกิน $days วัน',
    );
    return '$_temp0';
  }

  @override
  String sendTorNothingSent(String reason) {
    return '$reason ไม่มีสิ่งใดถูกส่งออกไป';
  }

  @override
  String get sendTryAgain => 'ลองอีกครั้ง';

  @override
  String get sendCancelPayment => 'ยกเลิกรายการ';

  @override
  String get settingsSectionReceiving => 'การรับเงิน';

  @override
  String get homeAvailableToSpend => 'ยอดที่ใช้ได้';

  @override
  String get homeTileWaitingSender => 'รอผู้ส่ง';

  @override
  String get homeTileLocked => 'ล็อกในการส่ง';

  @override
  String get homeTileMaturing => 'รางวัลรอครบกำหนด';

  @override
  String get homeTileTotal => 'รวม';

  @override
  String homeViewAll(int count) {
    return 'ดูทั้งหมด $count';
  }

  @override
  String get homeDestActivity => 'ประวัติ';

  @override
  String get homeDestOutputs => 'เอาต์พุต';

  @override
  String get txStatusReceived => 'ได้รับแล้ว';

  @override
  String get txStatusSent => 'ส่งแล้ว';

  @override
  String sendPinReason(String amount) {
    return 'ป้อน PIN เพื่อส่ง $amount';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'ป้อน PIN เพื่อสร้างไฟล์ชำระเงิน $amount';
  }

  @override
  String get outputsTitle => 'เอาต์พุต';

  @override
  String get outputsSpendable => 'ใช้ได้';

  @override
  String get outputsConfirming => 'กำลังยืนยัน';

  @override
  String get outputsLockedTile => 'ล็อกในการส่ง';

  @override
  String get outputsImmature => 'รอครบกำหนด';

  @override
  String outputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอาต์พุต',
    );
    return '$_temp0';
  }

  @override
  String get outputsSplitButton => 'แยก…';

  @override
  String get outputsConsolidateButton => 'รวม…';

  @override
  String get outputsSplitNeeds => 'การแยกต้องมียอดที่ใช้ได้อย่างน้อย 1 EPIC';

  @override
  String get outputsConsolidateNeeds =>
      'การรวมต้องมีเอาต์พุตที่ใช้ได้อย่างน้อย 2 รายการ';

  @override
  String get outputsWaitLocked =>
      'รอให้การส่งที่กำลังดำเนินการได้รับการยืนยัน (ประมาณ 3 บล็อก)';

  @override
  String get outputsStrategy => 'วิธีเลือกเอาต์พุตตอนส่ง';

  @override
  String get outputsSmallest => 'เล็กที่สุด';

  @override
  String get outputsAll => 'ทั้งหมด';

  @override
  String get outputsSmallestText =>
      'ใช้เอาต์พุตเล็กให้น้อยที่สุด ยอดที่เหลือยังใช้ได้ระหว่างที่เงินทอนรอการยืนยัน';

  @override
  String get outputsAllText =>
      'ใช้ทุกเอาต์พุตที่ใช้ได้และคืนเงินทอนเป็นเอาต์พุตเดียว ทุกอย่างถูกล็อกจนกว่าจะยืนยัน หลังจากนั้นจะมีเอาต์พุตน้อยลงแต่ใหญ่ขึ้น';

  @override
  String get outputsSplitChange => 'แยกเงินทอน';

  @override
  String get outputsSplitChangeText => 'เมื่อจะเหลือเอาต์พุตน้อย';

  @override
  String outputsFilterAll(int count) {
    return 'ทั้งหมด $count';
  }

  @override
  String outputsFilterSpendable(int count) {
    return 'ใช้ได้ $count';
  }

  @override
  String outputsFilterConfirming(int count) {
    return 'กำลังยืนยัน $count';
  }

  @override
  String outputsFilterLocked(int count) {
    return 'ล็อก $count';
  }

  @override
  String get outputsShowSpent => 'แสดงที่ใช้แล้ว';

  @override
  String get outputsHideSpent => 'ซ่อนที่ใช้แล้ว';

  @override
  String get outputsWordSpendable => 'ใช้ได้';

  @override
  String get outputsWordConfirming => 'กำลังยืนยัน';

  @override
  String get outputsWordFinalizing => 'รอผู้ส่งทำรายการให้เสร็จ';

  @override
  String get outputsWordImmature => 'รอครบกำหนด';

  @override
  String get outputsWordMining => 'กำลังขุด';

  @override
  String get outputsWordLocked => 'ล็อกอยู่';

  @override
  String get outputsWordSpent => 'ใช้แล้ว';

  @override
  String get outputsMeanSpendable => 'ใช้ได้ทันที';

  @override
  String outputsMeanConfirming(int need) {
    return 'ต้องได้รับการยืนยัน $need ครั้งก่อนจึงจะใช้ได้';
  }

  @override
  String get outputsMeanFinalizing => 'รอผู้ส่งทำรายการให้เสร็จ';

  @override
  String get outputsMeanImmature => 'รางวัลการขุด ใช้ได้หลังจากช่วงเวลาหนึ่ง';

  @override
  String get outputsMeanMining => 'รางวัลการขุดที่ยังไม่ได้รับการยืนยัน';

  @override
  String get outputsMeanLocked => 'กำลังถูกใช้โดยการส่งที่ดำเนินอยู่';

  @override
  String get outputsMeanSpent => 'ใช้ไปแล้ว';

  @override
  String outputsNoteReceived(String date) {
    return 'ได้รับเมื่อ $date';
  }

  @override
  String outputsNoteSend(String who) {
    return 'ส่งถึง $who';
  }

  @override
  String get outputsNoteSendPlain => 'กำลังส่ง';

  @override
  String get outputsFactHeight => 'ความสูงบล็อก';

  @override
  String get outputsFactConfirmations => 'การยืนยัน';

  @override
  String get outputsFactTransaction => 'ธุรกรรม';

  @override
  String get outputsFactCommitment => 'Commitment';

  @override
  String get outputsCopy => 'คัดลอก';

  @override
  String get outputsCopied => 'คัดลอก Commitment แล้ว';

  @override
  String get outputsEmpty => 'ยังไม่มีเอาต์พุต';

  @override
  String get outputsEmptyHint =>
      'การรับเงินครั้งแรกจะสร้างเอาต์พุต ดูที่อยู่ได้ที่หน้า รับ';

  @override
  String get outputsNoMatch => 'ไม่มีเอาต์พุตในมุมมองนี้';

  @override
  String get outputsRetry => 'ลองใหม่';

  @override
  String outputsSettingsSubtitle(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอาต์พุต · $strategy',
    );
    return '$_temp0';
  }

  @override
  String get outputsCancel => 'ยกเลิก';

  @override
  String get outputsSplitTitle => 'แยกเอาต์พุต';

  @override
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  ) {
    return 'ใช้ $spent ($amount) และสร้าง $made ประมาณ $each ต่อเอาต์พุต เป็นธุรกรรมปกติบนเครือข่ายที่ส่งเข้ากระเป๋านี้ ยืนยันหลัง 3 บล็อกเหมือนการส่งทั่วไป ยอดที่ใช้ได้ทั้งหมดจะถูกล็อกจนกว่าจะยืนยัน';
  }

  @override
  String get outputsToMake => 'จำนวนเอาต์พุตที่จะสร้าง';

  @override
  String get outputsStepperHint => '2 ถึง 10';

  @override
  String get outputsFactFee => 'ค่าธรรมเนียม';

  @override
  String get outputsFactEach => 'ต่อเอาต์พุต';

  @override
  String outputsFactAbout(String amount) {
    return 'ประมาณ $amount';
  }

  @override
  String get outputsFactLocked => 'ล็อก';

  @override
  String outputsFactLockedValue(String amount) {
    return '$amount ประมาณ 3 บล็อก';
  }

  @override
  String get outputsNothingSpendable => 'ระหว่างนี้จะไม่มียอดที่ใช้ได้';

  @override
  String get outputsMinEach => 'แต่ละเอาต์พุตต้องมีอย่างน้อย 0.5 EPIC';

  @override
  String outputsSplitInto(int count) {
    return 'แยกเป็น $count';
  }

  @override
  String get outputsConsolidateTitle => 'รวมเอาต์พุต';

  @override
  String outputsConsolidateText(String amount, String result, String spent) {
    return 'ใช้ $spent ($amount) และสร้างเอาต์พุตเดียวมูลค่า $result เป็นธุรกรรมปกติบนเครือข่ายที่ส่งเข้ากระเป๋านี้ ยืนยันหลัง 3 บล็อกเหมือนการส่งทั่วไป ยอดที่ใช้ได้ทั้งหมดจะถูกล็อกจนกว่าจะยืนยัน การส่งครั้งถัดไปจะใช้เอาต์พุตเดียว ค่าธรรมเนียมจึงต่ำที่สุด';
  }

  @override
  String get outputsConsolidateAction => 'รวม';

  @override
  String get outputsSplitPin => 'ยืนยันด้วย PIN เพื่อแยกเอาต์พุต';

  @override
  String get outputsConsolidatePin => 'ยืนยันด้วย PIN เพื่อรวมเอาต์พุต';

  @override
  String outputsSplitStarted(int count) {
    return 'เริ่มแยกแล้ว: $count เอาต์พุต ยืนยันในประมาณ 3 บล็อก';
  }

  @override
  String get outputsConsolidateStarted =>
      'เริ่มรวมแล้ว: 1 เอาต์พุต ยืนยันในประมาณ 3 บล็อก';

  @override
  String get outputsAdvanced => 'ขั้นสูง';

  @override
  String get outputsColState => 'สถานะ';

  @override
  String get outputsColValue => 'มูลค่า';

  @override
  String get outputsColConfirmations => 'ยืนยัน';

  @override
  String homePendingShort(String amount) {
    return '$amount จะถูกล็อกไว้จนกว่ากระเป๋าของผู้รับจะตอบกลับ';
  }

  @override
  String get contactsSearchHint => 'ชื่อหรือที่อยู่';

  @override
  String get contactsEmptyTitle => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get contactsEmptyCaption => 'ผู้ติดต่อคือชื่อที่ตั้งให้ที่อยู่';

  @override
  String contactsNoMatchQuery(String query) {
    return 'ไม่พบผู้ติดต่อที่ตรงกับ \"$query\"';
  }

  @override
  String get contactsSendAction => 'ส่ง';

  @override
  String get contactsEditAction => 'แก้ไข';

  @override
  String get contactsAddressHeading => 'ที่อยู่';

  @override
  String get contactsNoteHeading => 'บันทึก';

  @override
  String get contactsShowCode => 'แสดง QR Code';

  @override
  String get contactsHideCode => 'ซ่อน QR Code';

  @override
  String contactsQrLabel(String name) {
    return 'QR Code ของที่อยู่ $name';
  }

  @override
  String get contactsDeleteConfirmBody =>
      'หลังจากนี้ รายการที่ส่งไปยังที่อยู่นี้จะแสดงที่อยู่แทนชื่อ';

  @override
  String contactsDeleted(String name) {
    return 'ลบ $name แล้ว';
  }

  @override
  String get contactsCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get invoicesNewRequest => 'คำขอใหม่';

  @override
  String get invoicesSegmentSent => 'ส่งแล้ว';

  @override
  String invoicesSegmentCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
      zero: 'ไม่มี',
    );
    return '$label, $_temp0';
  }

  @override
  String get invoicesToPayEmpty => 'ไม่มีใบแจ้งหนี้ที่ต้องชำระ';

  @override
  String get invoicesToPayEmptyCaption =>
      'บริการในรายการที่เชื่อถือส่งใบแจ้งหนี้มายังกระเป๋านี้ได้ ใบแจ้งหนี้แต่ละใบจะรอการอนุมัติที่นี่';

  @override
  String get invoicesSentEmpty => 'ยังไม่ได้ส่งคำขอ';

  @override
  String get invoicesSentEmptyCaption =>
      'คำขอรับเงินคือการขอให้ผู้อื่นชำระเงินตามจำนวนที่กำหนด';

  @override
  String get invoicesWaitingPayment => 'รอการชำระ';

  @override
  String get invoicesExpires => 'หมดอายุ';

  @override
  String invoicesUntil(String time) {
    return 'จนถึง $time';
  }

  @override
  String get invoicesMessage => 'ข้อความ';

  @override
  String get invoicesFrom => 'จาก';

  @override
  String get invoicesPaysFrom => 'ชำระจาก';

  @override
  String invoicesAvailable(String amount) {
    return 'ยอดที่ใช้ได้ $amount';
  }

  @override
  String invoicesShort(String amount) {
    return 'ยอดไม่พอชำระ ขาดอีก $amount';
  }

  @override
  String get invoicesCheckNode => 'โหนด';

  @override
  String get invoicesCheckEpicbox => 'Epicbox';

  @override
  String get invoicesNodeOk => 'ตอบสนอง';

  @override
  String get invoicesNodeDown => 'ไม่ตอบสนอง';

  @override
  String get invoicesEpicboxOk => 'เชื่อมต่อแล้ว';

  @override
  String get invoicesEpicboxDown => 'ไม่ได้เชื่อมต่อ';

  @override
  String get invoicesSendRequest => 'ส่งคำขอ';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return 'ขอให้ $payer ชำระ $amount คำขอจะหมดอายุใน 24 ชั่วโมง';
  }

  @override
  String get invoicesRequestHowTitle => 'ก่อนส่งคำขอ';

  @override
  String get netStatusNode => 'โหนด';

  @override
  String get netStatusEpicbox => 'Epicbox';

  @override
  String get netStatusTor => 'Tor';

  @override
  String get netStatusSynced => 'ซิงก์แล้ว';

  @override
  String get netStatusSyncing => 'กำลังซิงก์';

  @override
  String netStatusSyncingPercent(int percent) {
    return 'กำลังซิงก์ $percent %';
  }

  @override
  String get netStatusConnecting => 'กำลังเชื่อมต่อ';

  @override
  String netStatusBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ตามหลัง $countString',
    );
    return '$_temp0';
  }

  @override
  String get netStatusOffline => 'ออฟไลน์';

  @override
  String get netStatusOnline => 'ออนไลน์';

  @override
  String get netStatusOff => 'ปิด';

  @override
  String get netStatusOn => 'เปิด';

  @override
  String get netStatusFailed => 'ล้มเหลว';

  @override
  String netStatusStarting(int percent) {
    return 'กำลังเริ่ม $percent %';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => 'สถานะเครือข่าย';

  @override
  String get serverMyRelays => 'เซิร์ฟเวอร์ของฉัน';

  @override
  String get serverRemoveRelay => 'ลบออกจากเซิร์ฟเวอร์ของฉัน';

  @override
  String get serverRemoveInUse =>
      'กำลังใช้งานอยู่ เปลี่ยนไปใช้เซิร์ฟเวอร์อื่นก่อน';

  @override
  String get serverRemoveRelayTitle => 'ลบเซิร์ฟเวอร์นี้ไหม?';

  @override
  String get serverRemoveNodeTitle => 'ลบโหนดนี้ไหม?';

  @override
  String serverRemoveBody(String host) {
    return '$host จะถูกลบออกจากรายการ หากต้องการใช้ภายหลังให้พิมพ์ใหม่';
  }

  @override
  String get serverRemoveConfirm => 'ลบ';

  @override
  String get serverSupportsNotifications => 'รองรับการแจ้งเตือน';

  @override
  String get netStatusReachable => 'เข้าถึงได้';

  @override
  String get netStatusPublishing => 'กำลังเผยแพร่…';

  @override
  String get netStatusNotReachable => 'เข้าถึงไม่ได้';

  @override
  String get netStatusTorOpenHint => 'เปิดการตั้งค่าความเป็นส่วนตัว';

  @override
  String get netStatusDirectOpenHint => 'เปิดที่อยู่สำหรับรับแบบส่งตรง';

  @override
  String get netStatusOpenHint => 'แสดงเซิร์ฟเวอร์';

  @override
  String get serverNodeTitle => 'โหนด';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'ค้นหาหรือพิมพ์ที่อยู่โหนด';

  @override
  String serverUseAddress(String address) {
    return 'ใช้ $address';
  }

  @override
  String get serverTesting => 'กำลังทดสอบ…';

  @override
  String serverTestAnswer(String height, String version) {
    return 'บล็อก $height · v$version';
  }

  @override
  String serverTestFailed(String error) {
    return 'ไม่ตอบสนอง $error';
  }

  @override
  String get serverMyNodes => 'โหนดของฉัน';

  @override
  String get serverPublicNodes => 'โหนดสาธารณะ';

  @override
  String get serverPublicRelays => 'เซิร์ฟเวอร์สาธารณะ';

  @override
  String get serverHealthUnknown =>
      'เข้าถึง status.btlabs.uk ไม่ได้ ไม่ทราบสถานะ';

  @override
  String get serverAtTip => 'ล่าสุด';

  @override
  String serverBehindShort(String count) {
    return '−$count';
  }

  @override
  String serverBehindLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ตามหลัง $count บล็อก',
    );
    return '$_temp0';
  }

  @override
  String get serverAddMine => 'เพิ่มในโหนดของฉัน';

  @override
  String get serverRemoveMine => 'ลบออกจากโหนดของฉัน';

  @override
  String get serverNotResponding => 'ไม่ตอบสนอง';

  @override
  String get serverHealthy => 'ปกติ';

  @override
  String get serverDegraded => 'ไม่เสถียร';

  @override
  String get serverHealthNone => 'ไม่ทราบสถานะ';

  @override
  String get serverCurrent => 'ใช้อยู่';

  @override
  String get serverDefault => 'ค่าเริ่มต้น';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return 'ออนไลน์ $percent %';
  }

  @override
  String serverSwitchTo(String host) {
    return 'เปลี่ยนเป็น $host';
  }

  @override
  String get serverNodeSwitchNote =>
      'กระเป๋าจะเชื่อมต่อใหม่ และตรวจยอดคงเหลืออีกครั้งกับโหนดใหม่';

  @override
  String get serverRelayWarning =>
      'ที่อยู่ของคุณมีเซิร์ฟเวอร์นี้อยู่ด้วย การเปลี่ยนจะทำให้ที่อยู่เปลี่ยน ผู้ส่งต้องใช้ที่อยู่ใหม่';

  @override
  String get serverRelaySwitchNote =>
      'ที่อยู่ของคุณจะเปลี่ยน ผู้ส่งต้องใช้ที่อยู่ใหม่';

  @override
  String get serverOtherRelay => 'เซิร์ฟเวอร์อื่น host หรือ host:port';

  @override
  String get serverFactHeight => 'ความสูงบล็อก';

  @override
  String get serverFactVersion => 'เวอร์ชัน';

  @override
  String get serverFactPeers => 'Peer';

  @override
  String get serverFactUptime => 'ออนไลน์ 24 ชั่วโมง';

  @override
  String serverHeightAtTip(String height) {
    return '$height · ล่าสุด';
  }

  @override
  String serverNodesAgree(String height) {
    return 'โหนดตรงกันที่ $height';
  }

  @override
  String serverNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'โหนดออนไลน์ $up จาก $total',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'บล็อกล่าสุด $seconds วินาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'บล็อกล่าสุด $minutes นาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String serverCheckedAt(String time) {
    return 'status.btlabs.uk ตรวจเมื่อ $time';
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
  String get methodFile => 'ไฟล์';

  @override
  String get methodArtCaptionEpicbox => 'เซิร์ฟเวอร์ Epicbox เก็บไว้ให้';

  @override
  String get methodArtCaptionHttp => 'ส่งตรงถึงกระเป๋าผู้รับ';

  @override
  String get methodArtCaptionTor => 'ส่งตรงผ่าน Tor';

  @override
  String get methodArtCaptionFile => 'ส่งไฟล์ไป รับไฟล์ตอบกลับ';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: รายการจะไปที่เซิร์ฟเวอร์ Epicbox ซึ่งเก็บไว้จนกว่ากระเป๋าของผู้รับจะกลับมาออนไลน์';

  @override
  String get methodArtLabelHttp =>
      'HTTP: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';

  @override
  String get methodArtLabelTor =>
      'Tor: รายการจะไปถึงกระเป๋าของผู้รับโดยตรงผ่านเครือข่าย Tor';

  @override
  String get methodArtLabelFile =>
      'ไฟล์: ส่งไฟล์ธุรกรรมไป รับไฟล์ตอบกลับมา แล้วผู้ส่งทำรายการให้เสร็จ';

  @override
  String get methodSendEpicboxTitle => 'ผู้รับออฟไลน์อยู่ก็ได้';

  @override
  String get settingsShowTipsAgain => 'แสดงคำแนะนำอีกครั้ง';

  @override
  String get settingsShowTipsAgainDone => 'คำแนะนำจะแสดงอีกครั้ง';

  @override
  String get tipHide => 'ซ่อนคำแนะนำ';

  @override
  String get methodSendEpicboxLine =>
      'เซิร์ฟเวอร์ Epicbox จะเก็บรายการไว้จนกว่าผู้รับจะเปิดกระเป๋า';

  @override
  String get methodSendHttpTitle => 'ส่งตรงถึงกระเป๋าผู้รับ';

  @override
  String get methodSendHttpLine =>
      'กระเป๋าต้องเปิดอยู่และเข้าถึงได้ที่ที่อยู่ HTTP';

  @override
  String get methodSendTorTitle => 'ส่งตรงถึงกระเป๋าผู้รับผ่าน Tor';

  @override
  String get methodSendTorLine =>
      'ช้ากว่าแต่เป็นส่วนตัวกว่า กระเป๋าของผู้รับต้องเปิดอยู่';

  @override
  String get methodSendFileTitle => 'ไม่ต้องเชื่อมต่อ';

  @override
  String get methodSendFileLine =>
      'ส่งไฟล์ให้ผู้รับ รับไฟล์ตอบกลับ แล้วทำรายการให้เสร็จที่นี่';

  @override
  String get methodReceiveEpicboxTitle => 'แชร์ที่อยู่เพื่อรับเงิน';

  @override
  String get methodReceiveEpicboxLine =>
      'ใช้ได้แม้กระเป๋าปิดอยู่ เซิร์ฟเวอร์ Epicbox จะเก็บรายการไว้จนกว่าจะเปิดกระเป๋า';

  @override
  String get methodReceiveTorTitle => 'ช้ากว่าแต่เป็นส่วนตัวกว่า';

  @override
  String get methodReceiveTorLine =>
      'ใช้ได้เฉพาะขณะเปิดแอปหรืออยู่เบื้องหลังช่วงสั้นๆ';

  @override
  String get methodReceiveFileTitle => 'ส่งไฟล์ไปมา';

  @override
  String get methodReceiveFileLine => 'ใช้ได้โดยไม่ต้องเชื่อมต่อระหว่างกระเป๋า';

  @override
  String get methodAddressKindsTooltip => 'ประเภทที่อยู่';

  @override
  String get sendMethodLabel => 'วิธีส่ง';

  @override
  String get sendToLabel => 'ถึง';

  @override
  String get sendToHint => 'ที่อยู่หรือผู้ติดต่อ';

  @override
  String get sendSwitchedHttp => 'ผ่าน HTTP';

  @override
  String get sendSwitchedEpicbox => 'ผ่าน Epicbox';

  @override
  String get sendSwitchedTorAnnounce => 'ที่อยู่ Tor ตั้งวิธีส่งเป็น Tor แล้ว';

  @override
  String get sendSwitchedHttpAnnounce =>
      'ที่อยู่ HTTP ตั้งวิธีส่งเป็น HTTP แล้ว';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'ที่อยู่ Epicbox ตั้งวิธีส่งเป็น Epicbox แล้ว';

  @override
  String get sendReviewMethodHttp => 'HTTP ส่งตรงถึงกระเป๋าผู้รับ';

  @override
  String get sendCancelRuleEpicbox => 'ยกเลิกได้ระหว่างรอผู้รับ';

  @override
  String get sendCancelRuleDirect => 'ยกเลิกไม่ได้เมื่อกระเป๋าผู้รับยอมรับแล้ว';

  @override
  String get sendCancelRuleFile =>
      'ยกเลิกได้จนกว่าจะทำรายการจากไฟล์ตอบกลับให้เสร็จ';

  @override
  String get sendHttpReaching => 'กำลังติดต่อกระเป๋าของผู้รับ… เปิดแอปไว้';

  @override
  String get sendDeliveredWaitingBlock => 'ส่งถึงแล้ว · รอบล็อก';

  @override
  String get sendHttpAddressShape =>
      'ที่อยู่ HTTP ขึ้นต้นด้วย http:// หรือ https://';

  @override
  String get sendPlainHttpTitle => 'ไม่ได้เข้ารหัส ส่งเลยไหม?';

  @override
  String get sendPlainHttpBody =>
      'HTTP แบบไม่เข้ารหัสไปยังอุปกรณ์อื่น ใครก็ตามระหว่างทางอ่านธุรกรรมได้ ที่อยู่ https:// จะเข้ารหัส';

  @override
  String get sendCancelPossibleWhileWaiting => 'ทำได้ระหว่างที่รายการรอผู้รับ';

  @override
  String get receiveEpicboxCaption =>
      'เมื่ออ่านที่อยู่ให้ผู้อื่นฟัง ให้ตรวจ 6 ตัวแรกและ 6 ตัวท้าย';

  @override
  String get receiveTorCaption =>
      'บางกระเป๋าแสดงที่อยู่โดยไม่มี .onion ทั้งสองแบบคือที่อยู่เดียวกัน';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'ติดต่อกระเป๋าของผู้รับไม่ได้ จำนวนเงินจะถูกพักไว้จนกว่าจะยกเลิก หรือไม่เกิน $days วัน',
    );
    return '$_temp0';
  }

  @override
  String deskInvActFrom(String label) {
    return 'ใบแจ้งหนี้จาก $label';
  }

  @override
  String get deskInvActFilter => 'ใบแจ้งหนี้';

  @override
  String get deskInvActBlock => 'ใบแจ้งหนี้';

  @override
  String get deskInvActOpen => 'เปิดในใบแจ้งหนี้';

  @override
  String get deskInvActBilledBy => 'เรียกเก็บโดย';

  @override
  String get deskInvActOverviewTitle => 'ใบแจ้งหนี้';

  @override
  String deskInvActOverviewToPay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'มีใบแจ้งหนี้ที่ต้องชำระ $count ใบ',
      zero: 'ไม่มีรายการที่ต้องชำระ',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใบแจ้งหนี้ที่ออกแล้ว $count ใบรอผู้ชำระ',
      zero: 'ไม่มีใบแจ้งหนี้ที่ออกแล้วรออยู่',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'มี $count รายการที่ต้องจัดการ: ลองใหม่หรือยกเลิก',
    );
    return '$_temp0';
  }

  @override
  String get deskInvActReview => 'ตรวจสอบ';

  @override
  String get deskInvActOpenInvoices => 'เปิดใบแจ้งหนี้';

  @override
  String get deskInvNav => 'ใบแจ้งหนี้';

  @override
  String get deskInvTitle => 'ใบแจ้งหนี้';

  @override
  String get deskInvTabPay => 'ชำระ';

  @override
  String get deskInvTabIssue => 'ออก';

  @override
  String deskInvTabCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get deskInvIssueAction => 'ออกใบแจ้งหนี้';

  @override
  String get deskInvChecking => 'กำลังตรวจสอบ';

  @override
  String deskInvCheckedAt(String time) {
    return 'ตรวจเมื่อ $time';
  }

  @override
  String get deskInvCheckFailedTitle => 'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง';

  @override
  String get deskInvCheckFailedBody =>
      'รายการแสดงสิ่งที่ได้รับก่อนหน้านี้ ไม่มีข้อมูลสูญหาย กระเป๋าจะลองใหม่ทุก 2 นาที';

  @override
  String get deskInvReqWaiting => 'รอผู้ชำระ';

  @override
  String get deskInvReqPaid => 'ชำระแล้ว กำลังทำรายการให้เสร็จ';

  @override
  String get deskInvReqPosted => 'ส่งเข้าเครือข่ายแล้ว';

  @override
  String deskInvConfirming(int count, int total) {
    return 'กำลังยืนยัน $count จาก $total';
  }

  @override
  String get deskInvCompleted => 'เสร็จสมบูรณ์';

  @override
  String get deskInvReqNotPosted => 'ส่งเข้าเครือข่ายไม่สำเร็จ';

  @override
  String get deskInvDeclined => 'ถูกปฏิเสธ';

  @override
  String get deskInvExpired => 'หมดอายุ';

  @override
  String get deskInvWithdrawn => 'ถูกเรียกคืน';

  @override
  String get deskInvReqBounced => 'ถูกส่งกลับ';

  @override
  String get deskInvPayWaiting => 'รอชำระ';

  @override
  String get deskInvPayPaying => 'กำลังชำระ';

  @override
  String get deskInvPayNotDelivered => 'ส่งไม่ถึง';

  @override
  String get deskInvPayDelivered => 'รอส่งเข้าเครือข่าย';

  @override
  String get deskInvPayPosted => 'บริการส่งเข้าเครือข่ายแล้ว';

  @override
  String get deskInvPayWithdrawnAfterPay => 'ถูกเรียกคืนหลังชำระ';

  @override
  String get deskInvPayPastTtl => 'ไม่อยู่บนบล็อกเชน';

  @override
  String get deskInvPayCancelled => 'ยกเลิกแล้ว';

  @override
  String get deskInvUnpaid => 'ยังไม่ชำระ';

  @override
  String get deskInvYouPay => 'คุณจ่าย';

  @override
  String deskInvExpiresAt(String time) {
    return 'หมดอายุ $time';
  }

  @override
  String get deskInvSlateId => 'Slate ID';

  @override
  String get deskInvAdvanced => 'ขั้นสูง';

  @override
  String get deskInvOneDevice =>
      'ใช้ใบแจ้งหนี้บนอุปกรณ์เดียวเท่านั้น อุปกรณ์อื่นที่มีกระเป๋าเดียวกันอาจรับการชำระที่ตั้งใจส่งมายังอุปกรณ์นี้';

  @override
  String get deskInvFailed => 'ไม่สำเร็จ ไม่มีสิ่งใดเปลี่ยนแปลง ลองอีกครั้ง';

  @override
  String get deskInvHowItWorks => 'ใบแจ้งหนี้ทำงานอย่างไร';

  @override
  String get deskInvAddressHint => 'es…@epicbox.epiccash.com';

  @override
  String get deskInvEpicboxAddress => 'ที่อยู่ Epicbox';

  @override
  String get deskInvHelpTitle => 'ใบแจ้งหนี้';

  @override
  String get deskInvHelpLede =>
      'บิลจากผู้ส่งที่เชื่อถือ ชำระหลังอนุมัติเท่านั้น';

  @override
  String get deskInvHelpFlowTitle => 'ใบแจ้งหนี้ทำงานอย่างไร';

  @override
  String get deskInvHelpFlowShort =>
      'ผู้ออกส่งใบแจ้งหนี้ไปยังที่อยู่สำหรับใบแจ้งหนี้ของผู้ชำระ ไม่มีการชำระใดๆ จนกว่าผู้ชำระจะอนุมัติ';

  @override
  String get deskInvHelpFlowIntro =>
      'ใบแจ้งหนี้คือการขอให้ชำระเงิน **ผู้ออก** เป็นผู้รับเงิน **ผู้ชำระ** เป็นผู้ตัดสินใจ';

  @override
  String get deskInvHelpFlowStep1 =>
      'กระเป๋าของผู้ออกส่งใบแจ้งหนี้ไปยัง **ที่อยู่สำหรับใบแจ้งหนี้** ของผู้ชำระผ่านเซิร์ฟเวอร์ Epicbox';

  @override
  String get deskInvHelpFlowStep2 =>
      'ผู้ชำระเปิดใบแจ้งหนี้ใน [[ใบแจ้งหนี้ › ชำระ]] ตรวจผู้ส่ง จำนวน และข้อความ แล้วเลือก **อนุมัติและชำระ** ด้วยรหัสผ่านกระเป๋า';

  @override
  String get deskInvHelpFlowStep3 =>
      'กระเป๋าของผู้ชำระส่งเงินไปยัง **ที่อยู่รับเงิน** ของผู้ออก';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return 'กระเป๋าของผู้ออกทำรายการให้เสร็จและส่งเข้าเครือข่าย หลังยืนยัน $confirmations ครั้ง รายการจะถือเป็นที่สุด';
  }

  @override
  String get deskInvHelpFlowNever =>
      'ไม่มีการชำระใดๆ หากไม่ได้อนุมัติ และใบแจ้งหนี้ไม่เคยเพิ่มเงินเข้ากระเป๋าของผู้ชำระ ใบแจ้งหนี้แต่ละใบมีเวลาชำระไม่เกิน 48 ชั่วโมง หลังจากนั้นจะชำระไม่ได้อีก';

  @override
  String get deskInvHelpFlowIssued =>
      'ใบแจ้งหนี้ที่กระเป๋านี้ออกอยู่ใน [[ใบแจ้งหนี้ › ออก]]';

  @override
  String get deskInvHelpTrustTitle => 'ทำไมรับเฉพาะผู้ส่งที่เชื่อถือ';

  @override
  String get deskInvHelpTrustShort =>
      'เฉพาะผู้ส่งในรายการที่เชื่อถือเท่านั้นที่ส่งใบแจ้งหนี้เข้ามาได้ ช่วยกันสแปมและบิลปลอม';

  @override
  String get deskInvHelpTrustP1 =>
      'กระเป๋ารับใบแจ้งหนี้เฉพาะที่ที่อยู่สำหรับใบแจ้งหนี้ และเฉพาะจากผู้ส่งในรายการที่เชื่อถือ โดยจับคู่จากที่อยู่ของผู้ส่ง สิ่งอื่นจะถูกทิ้งโดยไม่เปิดอ่าน และไม่แสดงใน [[ใบแจ้งหนี้ › ชำระ]]';

  @override
  String get deskInvHelpTrustP2 =>
      'หากไม่มีรายการนี้ ใครก็ตามที่รู้ที่อยู่สำหรับใบแจ้งหนี้อาจส่งสแปมหรือบิลที่ดูเหมือนจริงเข้ามาได้';

  @override
  String get deskInvHelpTrustP3 =>
      'การเชื่อถือเพียงอนุญาตให้ผู้ส่งขอเงินได้ ผู้ส่งที่เชื่อถือไม่สามารถเอาเงินไปได้ ใบแจ้งหนี้ทุกใบยังต้องรอ **อนุมัติและชำระ**';

  @override
  String get deskInvHelpTrustWhere1 =>
      'เพิ่มผู้ส่งที่เชื่อถือได้ใน [[การตั้งค่า › ใบแจ้งหนี้]]';

  @override
  String get deskInvHelpTrustWhere2 =>
      'หรือเปิด **เชื่อถือสำหรับใบแจ้งหนี้** ที่ผู้ติดต่อใน [[ผู้ติดต่อ]]';

  @override
  String get deskInvHelpTrustWhere3 =>
      'ลบผู้ส่งออกจากรายการได้ทุกเมื่อ ใบแจ้งหนี้ใหม่จากผู้ส่งนั้นจะถูกทิ้ง';

  @override
  String get deskInvHelpAddrTitle => 'ทำไมต้องมีที่อยู่สำหรับใบแจ้งหนี้แยก';

  @override
  String get deskInvHelpAddrShort =>
      'ใบแจ้งหนี้เข้ามาที่ที่อยู่ของตัวเอง แยกจากที่อยู่รับเงินที่ผู้อื่นใช้ชำระ';

  @override
  String get deskInvHelpAddrP1 =>
      'กระเป๋ามีที่อยู่ Epicbox สองที่อยู่ **ที่อยู่รับเงิน** ใน [[รับ]] ใช้รับเงิน **ที่อยู่สำหรับใบแจ้งหนี้** รับเฉพาะใบแจ้งหนี้';

  @override
  String get deskInvHelpAddrP2 =>
      'การแยกกันทำให้ให้ที่อยู่สำหรับใบแจ้งหนี้กับบริการต่างๆ หรือเปลี่ยนใหม่ได้ โดยไม่เปิดเผยหรือเปลี่ยนที่อยู่ที่ผู้อื่นใช้ชำระ';

  @override
  String get deskInvHelpAddrP3 =>
      'ที่อยู่สำหรับใบแจ้งหนี้ไม่รับเงิน เงินที่ส่งมาที่อยู่นี้จะถูกทิ้ง หากต้องการรับเงิน ให้ใช้ที่อยู่รับเงิน';

  @override
  String get deskInvHelpAddrWhere1 =>
      'ดู คัดลอก หรือแสดงที่อยู่สำหรับใบแจ้งหนี้เป็น QR Code ได้ใน [[การตั้งค่า › ใบแจ้งหนี้]]';

  @override
  String get deskInvHelpAddrWhere2 =>
      '**ที่อยู่ใบแจ้งหนี้ใหม่** จะแทนที่อยู่เดิม บริการที่มีที่อยู่เดิมจะส่งใบแจ้งหนี้ไม่ได้จนกว่าจะได้ที่อยู่ใหม่';

  @override
  String get deskInvHelpDiagramTitle => 'เส้นทางของใบแจ้งหนี้';

  @override
  String get deskInvHelpDiagramIssuer => 'ผู้ออก';

  @override
  String get deskInvHelpDiagramPayer => 'ผู้ชำระ';

  @override
  String get deskInvHelpDiagramIssues => 'ออกใบแจ้งหนี้';

  @override
  String get deskInvHelpDiagramInvoice => 'ใบแจ้งหนี้';

  @override
  String get deskInvHelpDiagramGate => 'ที่อยู่ใบแจ้งหนี้';

  @override
  String get deskInvHelpDiagramGateSub => 'เฉพาะผู้ส่งที่เชื่อถือ';

  @override
  String get deskInvHelpDiagramDropped => 'ผู้ส่งอื่น';

  @override
  String get deskInvHelpDiagramDroppedSub => 'ทิ้งโดยไม่อ่าน';

  @override
  String get deskInvHelpDiagramReview => 'ตรวจสอบและอนุมัติ';

  @override
  String get deskInvHelpDiagramReviewSub => 'อนุมัติและชำระ';

  @override
  String get deskInvHelpDiagramPayment => 'การชำระ';

  @override
  String get deskInvHelpDiagramPayAddr => 'ที่อยู่รับเงิน';

  @override
  String get deskInvHelpDiagramPayAddrSub => 'ไม่ใช่ที่อยู่ใบแจ้งหนี้';

  @override
  String get deskInvHelpDiagramFinal => 'ทำรายการให้เสร็จและส่ง';

  @override
  String deskInvHelpDiagramFinalSub(int confirmations) {
    return 'เป็นที่สุดหลังยืนยัน $confirmations ครั้ง';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      'ผู้ออกส่งใบแจ้งหนี้ไปยังที่อยู่สำหรับใบแจ้งหนี้ของผู้ชำระ ซึ่งรับเฉพาะผู้ส่งที่เชื่อถือและทิ้งที่เหลือ ผู้ชำระตรวจสอบและอนุมัติ เงินส่งไปยังที่อยู่รับเงินของผู้ออก กระเป๋าของผู้ออกทำรายการให้เสร็จและส่งเข้าเครือข่าย';

  @override
  String get deskInvIssuerFormTitle => 'ออกใบแจ้งหนี้';

  @override
  String get deskInvIssuerFirstTitle => 'ก่อนออกใบแจ้งหนี้ใบแรก';

  @override
  String get deskInvIssuerYourAddress => 'ที่อยู่รับเงินของคุณ';

  @override
  String get deskInvIssuerMethod => 'วิธีส่ง';

  @override
  String get deskInvIssuerEpicbox => 'Epicbox';

  @override
  String get deskInvIssuerFile => 'ไฟล์';

  @override
  String get deskInvIssuerDirect => 'ส่งตรง';

  @override
  String get deskInvIssuerSoon => 'เร็วๆ นี้';

  @override
  String get deskInvIssuerPayer => 'ที่อยู่ใบแจ้งหนี้ของผู้ชำระ';

  @override
  String get deskInvIssuerPayerHelp =>
      'กระเป๋าของผู้ชำระแสดงที่อยู่นี้ใน การตั้งค่า › ใบแจ้งหนี้';

  @override
  String get deskInvIssuerPayerMissing => 'วางที่อยู่ใบแจ้งหนี้ของผู้ชำระ';

  @override
  String get deskInvIssuerPayerInvalid => 'ที่อยู่ Epicbox ไม่ถูกต้อง';

  @override
  String get deskInvIssuerPayerOwn =>
      'นี่คือที่อยู่ของคุณเอง ใช้ที่อยู่ใบแจ้งหนี้ที่ผู้ชำระให้มา';

  @override
  String get deskInvIssuerPayerHttp =>
      'ใบแจ้งหนี้ผ่าน Epicbox ต้องใช้ที่อยู่ Epicbox ไม่ใช่ที่อยู่ HTTP หรือ Tor';

  @override
  String get deskInvIssuerContacts => 'ผู้ติดต่อ';

  @override
  String get deskInvIssuerNoContacts =>
      'ยังไม่มีผู้ติดต่อที่มีที่อยู่ใบแจ้งหนี้ เพิ่มได้ในผู้ติดต่อ';

  @override
  String get deskInvIssuerNoInvoices =>
      'กระเป๋านี้เคยส่งใบแจ้งหนี้กลับมาแล้ว จึงชำระใบแจ้งหนี้ผ่าน Epicbox ไม่ได้ ส่งไฟล์ใบแจ้งหนี้แทน หรือขอให้ส่งเงินมาให้คุณ';

  @override
  String get deskInvIssuerUseFile => 'ใช้ไฟล์';

  @override
  String get deskInvIssuerUnknown =>
      'เฉพาะ wallet-for-epic และกระเป๋า LEPIC อื่นๆ ที่ชำระใบแจ้งหนี้ผ่าน Epicbox ได้ Epic GUI wallet และ Stack Wallet ชำระใบแจ้งหนี้ไม่ได้เลย ส่วน epic-wallet แบบ command line ชำระไฟล์ใบแจ้งหนี้ได้';

  @override
  String get deskInvIssuerAmount => 'จำนวน';

  @override
  String get deskInvIssuerAmountMissing => 'ป้อนจำนวน';

  @override
  String get deskInvIssuerAmountZero => 'จำนวนต้องมากกว่า 0';

  @override
  String get deskInvIssuerAmountDecimals => 'EPIC มีทศนิยมได้ไม่เกิน 8 ตำแหน่ง';

  @override
  String get deskInvIssuerAmountCap => 'มากกว่า EPIC ทั้งหมดที่จะมีอยู่';

  @override
  String get deskInvIssuerAmountHelp =>
      'ไม่มีเงินออกจากกระเป๋าของคุณ ผู้ชำระจ่ายจำนวนนี้บวกค่าธรรมเนียมของตนเอง';

  @override
  String get deskInvIssuerMessage => 'ข้อความถึงผู้ชำระ';

  @override
  String deskInvIssuerMessageCount(int used, int max) {
    return '$used จาก $max ไบต์';
  }

  @override
  String get deskInvIssuerMessageLong => 'ข้อความยาวเกินไป';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'ผู้ชำระมีเวลาชำระ $hours ชั่วโมง';
  }

  @override
  String get deskInvIssuerIssue => 'ออกใบแจ้งหนี้';

  @override
  String get deskInvIssuerRelayDown =>
      'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง จึงส่งใบแจ้งหนี้ไม่ได้ในขณะนี้';

  @override
  String get deskInvIssuerFixFields => 'แก้ไขช่องที่มีเครื่องหมายสีแดง';

  @override
  String get deskInvIssuerNotDelivered =>
      'ใบแจ้งหนี้ไปไม่ถึงเซิร์ฟเวอร์ Epicbox ไม่มีสิ่งใดถูกส่ง ลองอีกครั้ง';

  @override
  String deskInvIssuerSent(String payer) {
    return 'ส่งใบแจ้งหนี้ถึง $payer แล้ว';
  }

  @override
  String get deskInvIssuerEmpty =>
      'ยังไม่ได้ออกใบแจ้งหนี้ ใบแจ้งหนี้คือการขอให้ผู้ติดต่อหรือบริการชำระเงินให้คุณ โดยไม่ใช้เงินของคุณ';

  @override
  String deskInvIssuerTo(String payer) {
    return 'ใบแจ้งหนี้ถึง $payer';
  }

  @override
  String deskInvIssuerIssued(String time) {
    return 'ออกเมื่อ $time';
  }

  @override
  String get deskInvIssuerPayerFact => 'ผู้ชำระ';

  @override
  String get deskInvIssuerAmountFact => 'จำนวน';

  @override
  String get deskInvIssuerMessageFact => 'ข้อความ';

  @override
  String get deskInvIssuerSentFact => 'ออกเมื่อ';

  @override
  String get deskInvIssuerExpiresFact => 'หมดอายุ';

  @override
  String get deskInvIssuerAnsweredFact => 'สิ้นสุด';

  @override
  String get deskInvIssuerStepPaid => 'ชำระแล้ว';

  @override
  String get deskInvIssuerStepConfirming => 'กำลังยืนยัน';

  @override
  String get deskInvIssuerEnded =>
      'ใบแจ้งหนี้นี้สิ้นสุดโดยไม่ได้รับชำระ ไม่มีเงินเข้า';

  @override
  String get deskInvIssuerWithdraw => 'เรียกคืน';

  @override
  String get deskInvIssuerWithdrawTitle => 'เรียกคืนใบแจ้งหนี้นี้ไหม?';

  @override
  String deskInvIssuerWithdrawBody(String payer) {
    return '$payer จะชำระใบแจ้งหนี้นี้ไม่ได้อีก';
  }

  @override
  String get deskInvIssuerKeep => 'เก็บไว้';

  @override
  String get deskInvIssuerWithdrawn => 'เรียกคืนใบแจ้งหนี้แล้ว';

  @override
  String get deskInvIssuerRepost => 'ส่งอีกครั้ง';

  @override
  String get deskInvIssuerReposted => 'ส่งรายการเข้าเครือข่ายอีกครั้งแล้ว';

  @override
  String get deskInvIssuerNodeDown =>
      'โหนดไม่ตอบสนอง ลองอีกครั้งเมื่อเชื่อมต่อได้';

  @override
  String get deskInvIssuerNotPostedText =>
      'รายการเสร็จแล้วแต่ไม่อยู่บนเครือข่าย โหนดปฏิเสธหรือเชื่อมต่อโหนดไม่ได้';

  @override
  String get deskInvIssuerCancel => 'ยกเลิกรายการ';

  @override
  String get deskInvIssuerCancelTitle => 'ยกเลิกรายการนี้ไหม?';

  @override
  String deskInvIssuerCancelBody(String payer) {
    return 'เงินจะไม่เข้ามา เงินของ $payer จะถูกล็อกในกระเป๋าของผู้ชำระจนกว่าจะยกเลิกทางฝั่งนั้น';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return 'กระเป๋าของ $payer ส่งใบแจ้งหนี้กลับมา เพราะชำระใบแจ้งหนี้ไม่ได้ ขอให้ส่งเงินมาให้คุณแทน';
  }

  @override
  String get deskInvIssuerSendFile => 'ใช้ไฟล์';

  @override
  String get deskInvIssuerLate =>
      'มีเงินเข้ามาหลังใบแจ้งหนี้นี้สิ้นสุด ถูกปฏิเสธแล้ว ไม่มีสิ่งใดเปลี่ยนแปลง';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer ชำระแล้ว กระเป๋าของคุณทำรายการให้เสร็จและส่งเข้าเครือข่ายแล้ว';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return 'ส่งถึงที่อยู่ใบแจ้งหนี้ของ $payer แล้ว ไม่มีการชำระใดๆ จนกว่าผู้ชำระจะอนุมัติ';
  }

  @override
  String get deskInvIssuerCopySlate => 'คัดลอก Slate ID';

  @override
  String get deskInvIssuerStepsIntro =>
      'กระเป๋าของผู้ชำระต้องรับใบแจ้งหนี้ได้ ก่อนใบแจ้งหนี้ใบแรก:';

  @override
  String get deskInvIssuerStepTrust =>
      '1. ผู้ชำระเพิ่มที่อยู่รับเงินของคุณด้านล่างในรายการผู้ส่งที่เชื่อถือ';

  @override
  String get deskInvIssuerStepAddress =>
      '2. ผู้ชำระให้ที่อยู่ใบแจ้งหนี้ของตนกับคุณ';

  @override
  String get deskInvIssuerStepIssued => 'ออกแล้ว';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return '$payer ชำระ $amount EPIC แล้ว';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return '$payer ปฏิเสธใบแจ้งหนี้ของคุณ';
  }

  @override
  String get deskInvNoticeIssuedExpired =>
      'ใบแจ้งหนี้ที่คุณออกหมดอายุโดยไม่ได้รับชำระ';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return '$service เรียกคืนใบแจ้งหนี้ก่อนที่คุณจะตอบ';
  }

  @override
  String get deskInvNoticeExpired => 'ใบแจ้งหนี้หมดอายุก่อนที่คุณจะตอบ';

  @override
  String get deskInvNoticeUnknownPayment =>
      'มีการชำระสำหรับใบแจ้งหนี้ที่อุปกรณ์นี้ไม่ได้ออก และถูกปฏิเสธ หากอุปกรณ์อื่นที่มีกระเป๋านี้เป็นผู้ออก ให้ขอผู้ชำระยกเลิกแล้วชำระใหม่';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'มีคำตอบสำหรับรายการที่อุปกรณ์นี้ไม่ได้ส่ง และถูกปฏิเสธ หากอุปกรณ์อื่นที่มีกระเป๋านี้เป็นผู้ส่ง ให้ยกเลิกที่อุปกรณ์นั้นแล้วส่งใหม่';

  @override
  String get deskInvPayerWaitingHead => 'รอคุณตอบ';

  @override
  String get deskInvPayerNeedsHead => 'รายการที่ต้องจัดการ';

  @override
  String get deskInvPayerReview => 'ตรวจสอบ';

  @override
  String get deskInvPayerPaidHead => 'Paid';

  @override
  String get deskInvPayerView => 'ดู';

  @override
  String get deskInvPayerNoMessage => 'ไม่มีข้อความ';

  @override
  String deskInvPayerDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้อความ $count รายการจากผู้ส่งที่ไม่ได้เชื่อถือถูกละเว้น',
    );
    return '$_temp0';
  }

  @override
  String get deskInvPayerTrustService => 'เชื่อถือบริการ…';

  @override
  String get deskInvPayerYourInvoiceAddress => 'ที่อยู่ใบแจ้งหนี้ของคุณ';

  @override
  String get deskInvPayerEmptyTitle => 'ไม่มีใบแจ้งหนี้รออยู่';

  @override
  String get deskInvPayerEmptyText =>
      'เมื่อบริการที่เชื่อถือเรียกเก็บเงิน ใบแจ้งหนี้จะแสดงที่นี่ ไม่มีการชำระใดๆ จนกว่าคุณจะอนุมัติ';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'การชำระถึง $service ส่งไม่ถึง';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'รายการลงนามแล้วและเก็บไว้ในอุปกรณ์นี้ เงินยังถูกล็อกอยู่ ลองใหม่จะส่งอีกครั้งโดยไม่ต้องอนุมัติซ้ำ';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service เรียกคืนใบแจ้งหนี้ที่คุณชำระแล้ว';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'รายการอาจไม่ถึงบล็อกเชน ยกเลิกเพื่อปลดล็อกเงิน';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'การชำระถึง $service ไม่อยู่บนบล็อกเชน';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'เลยเวลาแล้วและเครือข่ายไม่พบรายการนี้ ยกเลิกเพื่อปลดล็อกเงิน';

  @override
  String get deskInvPayerCancelPayment => 'ยกเลิกรายการ';

  @override
  String get deskInvPayerSafetyTitle => 'ชำระเฉพาะบิลที่คาดว่าจะได้รับ';

  @override
  String get deskInvPayerSafetyText =>
      'ใบแจ้งหนี้ไม่เคยเพิ่มเงินเข้ากระเป๋า การอนุมัติคือการส่งเงินออก';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return 'คุณชำระ $service ด้วยจำนวนเดียวกันเมื่อ $ago ที่แล้ว';
  }

  @override
  String get deskInvPayerSameBillText => 'ตรวจว่านี่เป็นบิลใหม่ก่อนชำระ';

  @override
  String deskInvPayerAgoHours(int hours, int minutes) {
    return '$hours ชั่วโมง $minutes นาที';
  }

  @override
  String deskInvPayerAgoMinutes(int minutes) {
    return '$minutes นาที';
  }

  @override
  String get deskInvPayerFee => 'ค่าธรรมเนียม';

  @override
  String get deskInvPayerTotal => 'รวม';

  @override
  String get deskInvPayerBalanceAfter => 'ยอดคงเหลือหลังชำระ';

  @override
  String get deskInvPayerMessageCaption =>
      'เขียนโดยบริการ กระเป๋าไม่ได้ตรวจสอบข้อความนี้';

  @override
  String get deskInvPayerPaysTo => 'ชำระไปที่';

  @override
  String deskInvPayerTrustedSince(String service, String date) {
    return '$service เชื่อถือตั้งแต่ $date';
  }

  @override
  String get deskInvPayerExpires => 'หมดอายุ';

  @override
  String get deskInvPayerLockHeight => 'ความสูงล็อก';

  @override
  String get deskInvPayerLockNone => 'ไม่มี';

  @override
  String get deskInvPayerReceived => 'ได้รับเมื่อ';

  @override
  String get deskInvPayerShort => 'ยอดที่ใช้ได้ไม่พอ';

  @override
  String deskInvPayerShortText(String total, String spendable) {
    return 'ต้องมียอดที่ใช้ได้ $total EPIC มีอยู่ $spendable EPIC เงินที่กำลังยืนยันจะนับรวมเมื่อได้รับการยืนยัน 3 ครั้ง';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'โหนดไม่ตอบสนอง';

  @override
  String get deskInvPayerNodeDownText =>
      'กระเป๋าตรวจยอดเงินไม่ได้ จึงชำระไม่ได้ การอนุมัติจะใช้ได้อีกครั้งเมื่อโหนดตอบสนอง เลือกโหนดอื่นได้ใน การตั้งค่า › โหนด';

  @override
  String get deskInvPayerPaid => 'ใบแจ้งหนี้นี้ชำระแล้ว ชำระเพิ่มไม่ได้';

  @override
  String get deskInvPayerDeclinedText =>
      'คุณปฏิเสธใบแจ้งหนี้นี้แล้ว ไม่มีการชำระ';

  @override
  String get deskInvPayerBack => 'กลับไปที่ใบแจ้งหนี้';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return 'ชำระ $amount EPIC + ค่าธรรมเนียม $fee ให้ $service ไหม?';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC จะออกจากกระเป๋าของคุณ ป้อนรหัสผ่านกระเป๋าเพื่ออนุมัติ';
  }

  @override
  String get deskInvPayerPassword => 'รหัสผ่านกระเป๋า';

  @override
  String get deskInvPayerWrongPassword => 'รหัสผ่านไม่ถูกต้อง ไม่มีการชำระ';

  @override
  String get deskInvPayerEnterPassword => 'ป้อนรหัสผ่านกระเป๋า';

  @override
  String get deskInvPayerPay => 'ชำระ';

  @override
  String get deskInvPayerCancel => 'ยกเลิก';

  @override
  String get deskInvPayerClose => 'ปิด';

  @override
  String get deskInvPayerNodeDownPay => 'โหนดไม่ตอบสนอง ไม่มีการชำระ';

  @override
  String get deskInvPayerAlreadyAnswered =>
      'ใบแจ้งหนี้นี้ได้รับการตอบแล้ว ไม่มีการชำระเพิ่ม';

  @override
  String get deskInvPayerCannotPay => 'ชำระใบแจ้งหนี้นี้ไม่ได้ ไม่มีการชำระ';

  @override
  String get deskInvPayerNotDeliveredToast => 'ลงนามแล้ว แต่ส่งไม่ถึง';

  @override
  String get deskInvPayerNotDeliveredToastText =>
      'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง ลองใหม่ได้ใน ใบแจ้งหนี้ › ชำระ โดยไม่ต้องอนุมัติซ้ำ';

  @override
  String get deskInvPayerRetryFailed => 'ยังส่งไม่ถึง';

  @override
  String get deskInvPayerRetryFailedText =>
      'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง รายการที่ลงนามแล้วยังเก็บอยู่ในอุปกรณ์นี้';

  @override
  String get deskInvPayerCancelTitle => 'ยกเลิกรายการนี้ไหม?';

  @override
  String get deskInvPayerCancelText =>
      'การยกเลิกจะปลดล็อกเงินในกระเป๋านี้ แต่บริการยังมีรายการที่ลงนามแล้ว จึงอาจยังทำรายการสำเร็จได้จนกว่าเงินนี้จะถูกใช้ไปอีกครั้ง';

  @override
  String deskInvPayerCancelWho(String amount, String service) {
    return '$amount EPIC ให้ $service';
  }

  @override
  String get deskInvPayerKeepPayment => 'เก็บไว้';

  @override
  String get deskInvPayerOnItsWay => 'รายการกำลังดำเนินการอยู่ ยกเลิกไม่ได้';

  @override
  String get deskInvPayerCannotCheck =>
      'ตรวจสอบเครือข่ายไม่ได้ในขณะนี้ ลองอีกครั้งเมื่อเชื่อมต่อโหนดได้';

  @override
  String get deskInvPayerCancelled => 'ยกเลิกรายการแล้ว';

  @override
  String get deskInvPayerCancelledText => 'ปลดล็อกเงินแล้ว';

  @override
  String get deskInvPayerDeclined => 'ปฏิเสธใบแจ้งหนี้แล้ว ไม่มีการชำระ';

  @override
  String get deskInvPayerSpendToSelf => 'โอนเข้ากระเป๋าตัวเองทันที';

  @override
  String get deskInvPayerSpendToSelfHelp =>
      'ทำให้การยกเลิกเป็นที่สุด สำเนาที่ลงนามของบริการจะทำรายการสำเร็จไม่ได้อีก มีค่าธรรมเนียมเครือข่าย';

  @override
  String get deskInvPayerSpentText =>
      'ปลดล็อกเงินและย้ายภายในกระเป๋านี้แล้ว การยกเลิกเป็นที่สุด';

  @override
  String get deskInvPayerSpendFailedText =>
      'ปลดล็อกเงินแล้ว แต่ย้ายเงินไม่สำเร็จ การยกเลิกยังไม่เป็นที่สุด';

  @override
  String get deskInvPayerLocked =>
      'ชำระใบแจ้งหนี้นี้ไม่ได้ เพราะถูกล็อกไว้จนถึงบล็อกถัดไป ไม่มีการชำระ';

  @override
  String get deskInvPayerRelayDownPay =>
      'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง ไม่มีการชำระ';

  @override
  String get deskInvSetTitle => 'ใบแจ้งหนี้';

  @override
  String get deskInvSetIntro =>
      'บริการที่เชื่อถือเรียกเก็บเงินจากกระเป๋านี้ผ่านที่อยู่ใบแจ้งหนี้ ไม่มีการชำระใดๆ จนกว่าคุณจะอนุมัติแต่ละใบ';

  @override
  String get deskInvSetAddressLabel => 'ที่อยู่ใบแจ้งหนี้';

  @override
  String get deskInvSetAddressWarning =>
      'ให้เฉพาะบริการที่เชื่อถือเท่านั้น ที่อยู่นี้ไม่รับเงิน';

  @override
  String get deskInvSetCopy => 'คัดลอก';

  @override
  String get deskInvSetCopied =>
      'คัดลอกที่อยู่ใบแจ้งหนี้แล้ว ให้เฉพาะบริการที่เชื่อถือเท่านั้น ที่อยู่นี้ไม่รับเงิน';

  @override
  String get deskInvSetQrShow => 'แสดง QR';

  @override
  String get deskInvSetQrHide => 'ซ่อน QR';

  @override
  String get deskInvSetQrLabel => 'QR Code ของที่อยู่ใบแจ้งหนี้';

  @override
  String deskInvSetIndex(int index) {
    return 'ที่อยู่ใบแจ้งหนี้ $index';
  }

  @override
  String get deskInvSetTrusted => 'ผู้ส่งที่เชื่อถือ';

  @override
  String get deskInvSetTrustedNone =>
      'ไม่มีผู้ส่งที่เชื่อถือ ใบแจ้งหนี้จากผู้อื่นจะถูกละเว้นโดยไม่อ่าน';

  @override
  String deskInvSetSince(String date) {
    return 'เชื่อถือตั้งแต่ $date';
  }

  @override
  String get deskInvSetContactTag => 'ผู้ติดต่อ';

  @override
  String get deskInvSetRemove => 'ลบ';

  @override
  String deskInvSetRemoveTitle(String name) {
    return 'เลิกเชื่อถือ $name ไหม?';
  }

  @override
  String deskInvSetRemoveBody(String name) {
    return '$name จะส่งใบแจ้งหนี้ไม่ได้อีก ใบแจ้งหนี้ที่รออยู่จะยังอยู่จนกว่าคุณจะตอบหรือหมดอายุ';
  }

  @override
  String deskInvSetRemoved(String name) {
    return '$name ส่งใบแจ้งหนี้ไม่ได้อีกแล้ว';
  }

  @override
  String get deskInvSetKeep => 'เก็บไว้';

  @override
  String get deskInvSetAdd => 'เพิ่มผู้ส่งที่เชื่อถือ';

  @override
  String get deskInvSetAddBody =>
      'ผู้ส่งที่เชื่อถือเรียกเก็บเงินจากกระเป๋านี้ผ่านที่อยู่ใบแจ้งหนี้ได้ ไม่มีการชำระใดๆ จนกว่าคุณจะอนุมัติแต่ละใบด้วยรหัสผ่านกระเป๋า';

  @override
  String get deskInvSetName => 'ชื่อ';

  @override
  String get deskInvSetNameMissing => 'ตั้งชื่อผู้ส่ง';

  @override
  String get deskInvSetSenderAddress => 'ที่อยู่รับเงินของผู้ส่ง';

  @override
  String get deskInvSetSenderMissing => 'วางที่อยู่ที่บริการแสดง';

  @override
  String get deskInvSetSenderInvalid => 'ที่อยู่ Epicbox ไม่ถูกต้อง';

  @override
  String get deskInvSetTrust => 'เชื่อถือ';

  @override
  String deskInvSetAdded(String name) {
    return '$name ส่งใบแจ้งหนี้ได้แล้ว';
  }

  @override
  String deskInvSetDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ข้อความ $count รายการจากผู้ส่งที่ไม่ได้เชื่อถือถูกละเว้นโดยไม่อ่าน',
    );
    return '$_temp0';
  }

  @override
  String get deskInvSetRotate => 'ที่อยู่ใบแจ้งหนี้ใหม่';

  @override
  String get deskInvSetRotateHint =>
      'บริการที่มีที่อยู่เดิมจะส่งใบแจ้งหนี้ไม่ได้อีก';

  @override
  String get deskInvSetRotateTitle => 'สร้างที่อยู่ใบแจ้งหนี้ใหม่ไหม?';

  @override
  String get deskInvSetRotateBody =>
      'บริการที่มีที่อยู่เดิมจะส่งใบแจ้งหนี้ไม่ได้อีก ให้ที่อยู่ใหม่กับทุกบริการที่เรียกเก็บเงินจากคุณ';

  @override
  String get deskInvSetRotateConfirm => 'สร้างที่อยู่ใหม่';

  @override
  String get deskInvSetRotated =>
      'ที่อยู่ใบแจ้งหนี้ใหม่พร้อมแล้ว ส่งให้บริการต่างๆ';

  @override
  String get deskInvSetExpiry => 'เวลาชำระ';

  @override
  String get deskInvSetExpiryHint =>
      'ระยะเวลาที่ใบแจ้งหนี้ที่คุณออกยังชำระได้ และระยะเวลาที่ใบแจ้งหนี้ที่ได้รับจะรอคุณ ไม่เกิน 48 ชั่วโมง';

  @override
  String deskInvSetHours(int hours) {
    return '$hours ชั่วโมง';
  }

  @override
  String get deskInvSetCancel => 'ยกเลิก';

  @override
  String get deskInvSetContactSection => 'ใบแจ้งหนี้';

  @override
  String get deskInvSetTheirInvoice => 'ที่อยู่ใบแจ้งหนี้ของผู้ติดต่อ';

  @override
  String get deskInvSetTheirInvoiceNone =>
      'ยังไม่ได้บันทึกที่อยู่ใบแจ้งหนี้ ขอที่อยู่จากผู้ติดต่อเพื่อออกใบแจ้งหนี้ให้';

  @override
  String get deskInvSetTrustedSwitch => 'เชื่อถือสำหรับใบแจ้งหนี้';

  @override
  String get deskInvSetTrustedSwitchHelp =>
      'ให้ผู้ติดต่อนี้เรียกเก็บเงินได้ ไม่มีการชำระใดๆ จนกว่าคุณจะอนุมัติใบแจ้งหนี้';

  @override
  String get deskInvSetIssueNeeds => 'ต้องมีที่อยู่ใบแจ้งหนี้ของผู้ติดต่อ';

  @override
  String get deskInvSetShare => 'แชร์ที่อยู่ใบแจ้งหนี้';

  @override
  String get deskInvSetReceiveHint =>
      'ขอให้ผู้ติดต่อหรือบริการชำระเงินให้คุณ กระเป๋าของอีกฝ่ายต้องรับใบแจ้งหนี้ได้';

  @override
  String get deskInvSetRestoredHint =>
      'กู้คืนกระเป๋านี้จากวลีกู้คืน? ให้ที่อยู่ใบแจ้งหนี้นี้กับบริการต่างๆ อีกครั้ง';

  @override
  String get serverSwitchRelayTitle => 'เปลี่ยนเซิร์ฟเวอร์ Epicbox ไหม?';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'ที่อยู่ Epicbox จะเปลี่ยนเป็น …@$relay ผู้ส่งต้องใช้ที่อยู่ใหม่ รายการที่ส่งไปยังที่อยู่เดิมจะยังอยู่บนเซิร์ฟเวอร์เดิม';
  }

  @override
  String get serverSwitchRelayConfirm => 'เปลี่ยน';

  @override
  String get helpButton => 'ช่วยเหลือ';

  @override
  String get helpSearchHint => 'ค้นหาความช่วยเหลือ';

  @override
  String get helpEnglishOnly => 'ขณะนี้ความช่วยเหลือมีเฉพาะภาษาอังกฤษ';

  @override
  String get helpLanguageLabel => 'ภาษาของคู่มือ';

  @override
  String helpNoMatch(String query) {
    return 'ไม่พบความช่วยเหลือที่ตรงกับ \"$query\"';
  }

  @override
  String helpMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count หัวข้อ',
    );
    return '$_temp0';
  }

  @override
  String get helpShowHandshake => 'ดูวิธีการทำงาน';

  @override
  String get helpMoreInSection => 'เพิ่มเติมในหมวดนี้';

  @override
  String get sendBalanceAfter => 'ยอดคงเหลือหลังส่ง';

  @override
  String get sendSpendableUntilChange => 'ใช้ได้ระหว่างรอเงินทอน';

  @override
  String get sendSpendableUntilChangeHint =>
      'เงินทอนจะกลับมาเมื่อการส่งได้รับการยืนยัน';

  @override
  String serverSwitched(String host) {
    return 'เปลี่ยนเป็น $host แล้ว';
  }

  @override
  String get methodDirect => 'ส่งตรง';

  @override
  String get methodDirectShape => 'http://host:3415 หรือ xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'กระเป๋าของผู้รับต้องเปิดอยู่ ที่อยู่ onion จะส่งผ่าน Tor';

  @override
  String get methodArtLabelDirect =>
      'ส่งตรง: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';

  @override
  String get methodReceiveEpicboxShort => 'ใช้ได้แม้กระเป๋าปิดอยู่';

  @override
  String get methodReceiveDirectTitle => 'ส่งตรงถึงกระเป๋านี้';

  @override
  String get methodReceiveDirectLine => 'ใช้ได้ขณะเปิดแอปอยู่';

  @override
  String methodLineOverTor(String line) {
    return '$line ผ่าน Tor';
  }

  @override
  String get sendSwitchedDirect => 'ที่อยู่ส่งตรง';

  @override
  String get sendSwitchedDirectAnnounce =>
      'ที่อยู่ส่งตรง ตั้งวิธีส่งเป็น ส่งตรง แล้ว';

  @override
  String get sendDirectAddressShape =>
      'ที่อยู่ส่งตรงขึ้นต้นด้วย http:// หรือ https:// หรือลงท้ายด้วย .onion';

  @override
  String get torNotOverTor => 'ไม่ผ่าน Tor';

  @override
  String get torNeeds => 'ต้องใช้ Tor';

  @override
  String get torTurnOn => 'เปิด Tor';

  @override
  String get torTurnOff => 'ปิด Tor';

  @override
  String get torNotConnectedNotice => 'Tor ยังไม่ได้เชื่อมต่อ';

  @override
  String get torWaiting => 'รอ Tor';

  @override
  String get torWordStarting => 'กำลังเริ่ม…';

  @override
  String get torWordNotConnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get torSettingsLink => 'การตั้งค่า Tor';

  @override
  String get torNetworkLabel => 'เครือข่าย Tor';

  @override
  String get torNetworkHint =>
      'การเชื่อมต่อเครือข่ายจะผ่านเครือข่าย Tor ซึ่งซ่อนที่อยู่อินเทอร์เน็ตของกระเป๋า แต่ละการเชื่อมต่อผ่านเซิร์ฟเวอร์หลายจุดที่อาสาสมัครดูแล จึงไม่มีเซิร์ฟเวอร์ใดรู้ว่ากระเป๋าอยู่ที่ไหน การแจ้งเตือนจะปิดขณะเปิด Tor';

  @override
  String get receiveTabDirect => 'ส่งตรง';

  @override
  String get receiveDirectNeedsTor => 'การรับแบบส่งตรงต้องใช้ Tor';

  @override
  String get receiveDirectMeanwhile => 'ระหว่างนี้ผู้ส่งใช้ที่อยู่ Epicbox';

  @override
  String get netStatusOverTor => 'ผ่าน Tor';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsNotificationsHint =>
      'ใช้บริการแจ้งเตือนของ Google ไม่มีการแชร์ข้อมูลที่ละเอียดอ่อน';

  @override
  String get settingsPushPaused => 'หยุดชั่วคราวขณะเปิด Tor';

  @override
  String get pushConfirmRelayBody =>
      'การแจ้งเตือนใช้ Epicbox ของ BT Labs และบริการแจ้งเตือนของ Google ไม่มีการแชร์ข้อมูลที่ละเอียดอ่อน';

  @override
  String get pushConfirmRelayAddress =>
      'ที่อยู่ Epicbox ของคุณจะเปลี่ยน แชร์ที่อยู่ใหม่';

  @override
  String get pushRelaySwitchFailed =>
      'เปลี่ยนเซิร์ฟเวอร์ไม่ได้ การแจ้งเตือนยังปิดอยู่';

  @override
  String get pushConfirmTitle => 'เปิดการแจ้งเตือนไหม?';

  @override
  String get pushConfirmBody =>
      'การแจ้งเตือนใช้บริการแจ้งเตือนของ Google ไม่มีการแชร์ข้อมูลที่ละเอียดอ่อน';

  @override
  String get pushConfirmAction => 'เปิด';

  @override
  String get pushNoticeOn => 'เปิดการแจ้งเตือนแล้ว';

  @override
  String get pushNoticeOff => 'ปิดการแจ้งเตือนแล้ว';

  @override
  String get pushNoticeAvailable => 'เปิดการแจ้งเตือนได้ในการตั้งค่า';

  @override
  String get torWayOver => 'ผ่าน Tor';

  @override
  String get torWayWaiting => 'รอ Tor';

  @override
  String get torWayNotConnected => 'Tor ยังไม่ได้เชื่อมต่อ';

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใช้เอาต์พุตทั้งหมด $count · เงินทอน 1 เอาต์พุต',
    );
    return '$_temp0';
  }
}
