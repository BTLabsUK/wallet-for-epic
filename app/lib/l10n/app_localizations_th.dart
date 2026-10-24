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
  String get deskRecvNameFile => 'File';

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
  String get deskRecvHttpAddress => 'HTTP address';

  @override
  String get deskRecvCopyHttp => 'Copy HTTP address';

  @override
  String deskRecvHttpPublic(int port) {
    return 'Your router’s public address. Senders on the internet use it once the router forwards port $port.';
  }

  @override
  String get deskRecvHttpLocal =>
      'Programs on this computer can pay this address. For other devices, see Settings › Receiving.';

  @override
  String get deskRecvHttpIntro =>
      'Straight from another wallet while this one is open. On this computer only unless Settings says otherwise.';

  @override
  String get deskRecvHttpTorHint =>
      'Turn on Tor in Settings › Privacy for a Tor address instead.';

  @override
  String get deskRecvDirectTor => 'Direct, Tor address';

  @override
  String get deskRecvTorIntro =>
      'Straight from another wallet over Tor while this one is open. Tor is set in Settings › Privacy.';

  @override
  String get deskRecvTorAddress => 'Tor address';

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
  String get deskSendAdvanced => 'Advanced';

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
  String get deskSendErrNotDirect => 'This is not a Direct address.';

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
      'Epicbox sends work once Epicbox receiving is on. Send by file meanwhile.';

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
  String get deskSendMethodDirect => 'Direct';

  @override
  String get deskSendMethodFile => 'File';

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
      'Direct to http(s) addresses goes over the clearnet, not Tor.';

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
  String get deskSendTagDirect => 'Direct';

  @override
  String get deskSendTagFile => 'File';

  @override
  String get deskSendTagEpicbox => 'Via Epicbox';

  @override
  String get deskSendSwitchedDirect => 'Direct address. Method set to Direct.';

  @override
  String get deskSendSwitchedFile => 'File address. Method set to File.';

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
  String get deskSendViaDirect => 'Direct (their wallet must be open)';

  @override
  String get deskSendViaTor => 'Direct, over Tor (their wallet must be open)';

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
  String get deskSendPasswordHelp =>
      'Opened with the remembered password: this send asks it.';

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
  String get deskConAddrTor => 'Tor address';

  @override
  String get deskConAddrHttp => 'HTTP address';

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
  String get deskConErrAddressInvalid => 'Not a recognised address';

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
  String get deskOutDefaultsTitle => 'Defaults for sends';

  @override
  String get deskOutStrategyTitle => 'Strategy for sends';

  @override
  String get deskOutStrategyText =>
      'Which outputs a send spends. Send can change it for one send under Advanced.';

  @override
  String get deskOutStrategySmallest => 'Smallest';

  @override
  String get deskOutStrategyAll => 'All';

  @override
  String get deskOutStrategyHelp =>
      'Smallest spends the fewest small outputs and leaves the rest spendable. All spends everything and returns one output.';

  @override
  String get deskOutStrategyHelpTitle => 'Smallest or All';

  @override
  String get deskOutSplitChangeTitle => 'Split change';

  @override
  String get deskOutSplitChangeText =>
      'When a send would leave fewer than 3 spendable outputs, its change comes back as up to 4 outputs. Costs 0.004 EPIC per extra output.';

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
  String get deskTxMethodFile => 'File';

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
  String get deskOnbWelcomeAdvanced => 'Advanced';

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
  String get deskRailOpenHttp => 'Open HTTP receiving';

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
      'Three ways to pay: an Epicbox address, a Direct address (http(s) or Tor), or a transaction file. A review comes before anything leaves.';

  @override
  String get deskTourReceiveTitle => 'Receive';

  @override
  String get deskTourReceiveText =>
      'This wallet’s Epicbox address, with HTTP and Tor beside it. Transaction files to sign or finalize are at the bottom.';

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
      'Saved addresses by name: Epicbox, HTTP or Tor. Send picks from here.';

  @override
  String get deskTourNodeTitle => 'Settings › Node';

  @override
  String get deskTourNodeText =>
      'Which node the wallet reads the chain from: a public one or the local node. The other settings pages are listed on the left.';

  @override
  String get deskTourHelpTitle => 'Help';

  @override
  String get deskTourHelpText =>
      'Topics by section, Report a problem and the app log. More on every page is here, and this tour can be shown again.';

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
      'HTTP: the payment goes straight to the recipient\'s wallet, which must be open';

  @override
  String get deskKitHeroLabelTor =>
      'Tor: the payment goes straight to the recipient\'s wallet, routed through the Tor network';

  @override
  String get deskKitHeroLabelFile =>
      'File: a transaction file is handed over, a response file comes back, then the sender finalizes';

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
  String deskKitNodeRemove(String host) {
    return 'Remove $host from my nodes';
  }

  @override
  String deskKitNodeAdd(String host) {
    return 'Add $host to my nodes';
  }

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
  String get deskKitMethodFiles => 'Files';

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
  String get deskSetDlgNodeAddressEmpty => 'Enter the node’s address.';

  @override
  String get deskSetDlgNodeAddressBad =>
      'Not a node address. Check the address and the port (usually 3413).';

  @override
  String get deskSetDlgNodeAddressDuplicate =>
      'This address is already in My nodes.';

  @override
  String get deskSetDlgNodeNotAdded => 'Node not added';

  @override
  String get deskSetDlgNodeSaved => 'Node saved';

  @override
  String get deskSetDlgNodeAdded => 'Added to my nodes';

  @override
  String get deskSetDlgNodeSaveAnyway => 'It can be saved anyway.';

  @override
  String get deskSetDlgNodeEditTitle => 'Edit node';

  @override
  String get deskSetDlgNodeAddTitle => 'Add to my nodes';

  @override
  String get deskSetDlgNodeDesc =>
      'Save a node address to find it again later. It can be saved while it is offline.';

  @override
  String get deskSetDlgNodeAddress => 'Node address';

  @override
  String get deskSetDlgNodeLabel => 'Label';

  @override
  String get deskSetDlgNodeLabelHint => 'e.g. Home node';

  @override
  String get deskSetDlgDirTitle => 'Node directory';

  @override
  String get deskSetDlgDirDesc =>
      'Public nodes, their operators and their state at the last check.';

  @override
  String get deskSetDlgDirEmpty => 'No nodes to show';

  @override
  String deskSetDlgDirVersion(String version) {
    return 'version $version';
  }

  @override
  String deskSetDlgDirHeight(String height) {
    return 'height $height';
  }

  @override
  String get deskSetDlgDirInUse => 'In use';

  @override
  String get deskSetDlgDirUse => 'Use';

  @override
  String get deskSetDlgDirNote =>
      'Response times are measured from the status site, not from this computer.';

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
  String get deskSetFrameReceiving => 'Receiving';

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
  String get deskSetComboNothing => 'Nothing to show.';

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
  String deskSetNodeVersionOld(String version) {
    return 'Version older than $version';
  }

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
  String get deskSetNodeGroupMine => 'My nodes';

  @override
  String get deskSetNodeGroupPublic => 'Public nodes';

  @override
  String get deskSetNodeRemovedFromMine => 'Removed from my nodes';

  @override
  String get deskSetNodeNotAnswering => 'Not answering';

  @override
  String get deskSetNodeAddToMine => 'Add to my nodes';

  @override
  String get deskSetNodeServer => 'Node server';

  @override
  String get deskSetNodeServerHint =>
      'The node the wallet reads the chain through and sends with.';

  @override
  String get deskSetNodeFindHint => 'Find or type a node address';

  @override
  String get deskSetNodeChecking => 'Checking the node…';

  @override
  String get deskSetNodeTypedNote =>
      'Enter uses it. The star keeps it in My nodes.';

  @override
  String get deskSetNodeNoNodes => 'No nodes to show.';

  @override
  String get deskSetNodeFooterAdd => 'Add to my nodes…';

  @override
  String get deskSetNodeFooterDirectory => 'Node directory…';

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
  String get deskSetPhraseCleared => 'The clipboard is cleared in 30 s.';

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
  String deskSetRecvResponseTime(int ms) {
    return 'Response time $ms ms. Measured from the status site.';
  }

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
  String get deskSetRecvFindHint => 'Find or type an Epicbox server';

  @override
  String get deskSetRecvSwitchingServer => 'Switching the Epicbox server…';

  @override
  String get deskSetRecvNotInList => 'not in the public list';

  @override
  String get deskSetRecvTypedNote =>
      'Enter uses it. Its status shows once the wallet connects.';

  @override
  String get deskSetRecvListNote =>
      'State from status.btlabs.uk, checked every few minutes.';

  @override
  String get deskSetRecvHttpTitle => 'HTTP receiving';

  @override
  String get deskSetRecvHttpText =>
      'Straight from another wallet while this one is open.';

  @override
  String get deskSetRecvHttpOffTitle => 'Off while Tor is on';

  @override
  String get deskSetRecvHttpOffText =>
      'Direct payments arrive at this wallet’s Tor address instead.';

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
}
