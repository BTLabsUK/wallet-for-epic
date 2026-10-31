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
  String get txRestoredFunds => 'พบบนบล็อกเชน';

  @override
  String txSpokenLabelled(String label, String row) {
    return '$label, $row';
  }

  @override
  String get txLabel => 'ป้ายกำกับ';

  @override
  String get txLabelAdd => 'เพิ่มป้ายกำกับ';

  @override
  String get txLabelEdit => 'แก้ไขป้ายกำกับ';

  @override
  String get txLabelHint => 'เพิ่มป้ายกำกับ';

  @override
  String get txLabelAddedNotice => 'เพิ่มป้ายกำกับแล้ว';

  @override
  String get txLabelSavedNotice => 'บันทึกป้ายกำกับแล้ว';

  @override
  String get txLabelRemovedNotice => 'ลบป้ายกำกับแล้ว';

  @override
  String get txEditAdd => 'เพิ่มรายละเอียด';

  @override
  String get txEditEdit => 'แก้ไขรายละเอียด';

  @override
  String get txEditFrom => 'จาก';

  @override
  String get txEditFromHint => 'ที่อยู่';

  @override
  String get txEditFromHelper =>
      'ยังไม่ได้ตรวจสอบ ไม่ใช้เป็นหลักฐานการชำระเงิน';

  @override
  String get txMethodUnknown => 'ไม่ทราบ';

  @override
  String get txManualTag => 'คุณเพิ่มเอง';

  @override
  String txManualTip(String date) {
    return 'คุณเพิ่มเมื่อ $date ไม่ได้มาจากบล็อกเชน';
  }

  @override
  String get txManualTipNoDate => 'คุณเพิ่มเอง ไม่ได้มาจากบล็อกเชน';

  @override
  String txManualTipFrom(String date) {
    return 'คุณเพิ่มเมื่อ $date ไม่ได้มาจากบล็อกเชน ยังไม่ได้ตรวจสอบ';
  }

  @override
  String get txManualTipFromNoDate =>
      'คุณเพิ่มเอง ไม่ได้มาจากบล็อกเชน ยังไม่ได้ตรวจสอบ';

  @override
  String get txEditAddedNotice => 'เพิ่มรายละเอียดแล้ว';

  @override
  String get txEditSavedNotice => 'บันทึกรายละเอียดแล้ว';

  @override
  String get txEditRemovedNotice => 'ลบรายละเอียดแล้ว';

  @override
  String get histConflictTitle => 'รายละเอียดไม่ตรงกัน';

  @override
  String histConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'ไฟล์มีรายละเอียดต่างออกไปใน $n รายการ ระบบจะใช้ของคุณ เว้นแต่คุณเลือกของไฟล์',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'ของฉัน';

  @override
  String get histConflictBackup => 'ไฟล์';

  @override
  String get histConflictKeepAll => 'เก็บของฉันทั้งหมด';

  @override
  String get histConflictImport => 'นำเข้า';

  @override
  String get histConflictEmpty => 'ว่าง';

  @override
  String histImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'แทนที่ $n รายละเอียด ส่วนที่เหลือยังเป็นของคุณ',
    );
    return '$_temp0';
  }

  @override
  String get txOutgoingPayment => 'รายการส่งออก';

  @override
  String get txIncomingPayment => 'รายการรับเข้า';

  @override
  String get txStatusWaitingRecipient => 'รอผู้รับ';

  @override
  String get txStatusWaitingSender => 'รอผู้ส่ง';

  @override
  String get txStatusSenderPosted => 'ผู้ส่งแจ้งว่าส่งแล้ว';

  @override
  String txStatusConfirming(int count, int target) {
    return 'กำลังยืนยัน $count/$target';
  }

  @override
  String get txStatusCompleted => 'สำเร็จ';

  @override
  String get txStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get txStatusFromBackup => 'นำเข้าแล้ว';

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
    return 'พบบนบล็อกเชน $amount';
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
      'ไฟล์นี้ไม่ใช่ไฟล์ข้อมูลกระเป๋าเงินจากแอปนี้';

  @override
  String get errorHistoryNewer =>
      'ไฟล์ข้อมูลกระเป๋าเงินนี้สร้างจากแอปเวอร์ชันที่ใหม่กว่า';

  @override
  String get errorHistoryDamaged => 'ไฟล์ข้อมูลกระเป๋าเงินนี้เสียหาย';

  @override
  String get errorHistoryOtherWallet =>
      'ไฟล์นี้เป็นของกระเป๋าเงินอื่น เปิดได้เฉพาะกระเป๋าเงินที่กู้คืนจากวลีกู้คืนเดียวกัน';

  @override
  String get errorHistoryOtherNetwork =>
      'ไฟล์ข้อมูลกระเป๋าเงินนี้มาจากเครือข่ายอื่น';

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
  String get scanResuming => 'กำลังสแกนต่อ';

  @override
  String get scanResumedNotice =>
      'การสแกนหยุดชั่วคราวขณะที่แอปอยู่เบื้องหลัง และจะสแกนต่อจากจุดที่หยุดไว้';

  @override
  String get languageSetting => 'ภาษา';

  @override
  String get languageSystem => 'ระบบ';

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
          'รอมา $days วันแล้ว เซิร์ฟเวอร์ Epicbox ลบรายการหลัง 7 วัน รายการนี้จึงทำต่อไม่ได้แล้ว ยกเลิกเพื่อปลดล็อกเหรียญ แล้วส่งใหม่',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'ส่งผ่าน Epicbox แล้ว จะสำเร็จเมื่อกระเป๋าเงินของผู้รับออนไลน์ ยอดเงินจะถูกล็อกจนถึงตอนนั้นหรือจนกว่าจะยกเลิก';

  @override
  String get txDetailsWaitingRecipient =>
      'รอผู้รับตอบกลับด้วยไฟล์ธุรกรรม ยอดเงินจะถูกล็อกจนถึงตอนนั้น หรือจนกว่าจะยกเลิก';

  @override
  String get txDetailsWaitingSender =>
      'รับรายการนี้แล้ว รายการจะสำเร็จเมื่อผู้ส่งทำรายการให้เสร็จและเผยแพร่ไปยังเครือข่าย';

  @override
  String get txDetailsSenderPosted =>
      'ผู้ส่งแจ้งว่าส่งรายการนี้แล้ว รายการจะสำเร็จเมื่อเครือข่ายยืนยัน';

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
      'ยกเลิกแล้ว ไม่มีการชำระเงิน และยอดเงินกลับมาใช้ได้แล้ว หากผู้รับได้รับรายการนี้ไปแล้ว กระเป๋าเงินของผู้รับอาจยังแสดงว่ากำลังรอ แต่รายการนี้ทำให้เสร็จไม่ได้อีกแล้ว';

  @override
  String get txDetailsCancelledReleased =>
      'เครือข่ายไม่รับรายการนี้ จึงปลดยอดเงินแล้ว ตรวจสอบว่าผู้รับไม่ได้รับเงินก่อนส่งใหม่';

  @override
  String get txDetailsCancelledNotOnChain =>
      'รายการไม่เข้าสู่เครือข่ายทันเวลาและถูกยกเลิกแล้ว ตรวจสอบว่าผู้รับไม่ได้รับเงินก่อนส่งใหม่';

  @override
  String get txDetailsCancelledUnanswered =>
      'ผู้รับไม่ตอบภายใน 24 ชั่วโมง กระเป๋าเงินจึงยกเลิก ไม่มีการชำระเงิน และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledLateAnswer =>
      'ผู้รับตอบหลังครบกำหนด 24 ชั่วโมง กระเป๋าเงินจึงยกเลิกแทนการทำรายการให้เสร็จ ไม่มีการชำระเงิน และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledUndelivered =>
      'ส่งถึงผู้รับไม่ได้ กระเป๋าเงินจึงยกเลิกทันที ไม่มีการส่งเงินออก และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledIncoming =>
      'ยกเลิกแล้ว ถ้าผู้ส่งเผยแพร่ภายหลัง รายการจะยังเข้า';

  @override
  String get txStatusSenderCancelled => 'ผู้ส่งยกเลิกแล้ว';

  @override
  String get txDetailsSenderCancelledWaiting =>
      'ผู้ส่งยกเลิกรายการนี้แล้ว กระเป๋าเงินจะล้างรายการนี้หลังตรวจสอบเครือข่าย';

  @override
  String get txDetailsSenderCancelled =>
      'ผู้ส่งยกเลิกรายการนี้แล้ว ถ้าเผยแพร่ไปก่อนหน้านั้น รายการจะยังเข้า';

  @override
  String get txDetailsFromBackup =>
      'รายการนี้นำเข้าจากไฟล์ข้อมูลกระเป๋าเงิน และยังไม่เสร็จตอนส่งออกไฟล์นั้น กระเป๋าเงินนี้ไม่มีบันทึกของตัวเอง จึงไม่ทราบว่าสำเร็จหรือไม่ ไม่มียอดเงินถูกล็อก';

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
  String get txWaitNoNewBlock => 'กำลังรอบล็อกถัดไป';

  @override
  String get txWaitNotInBlock =>
      'ยังไม่อยู่ในบล็อก อาจยังอยู่ระหว่างทางไปยังเครือข่าย';

  @override
  String get txDetailsStuckBody =>
      'เครือข่ายยังไม่รับรายการนี้ ส่งซ้ำได้อย่างปลอดภัย รายการเดียวกันผ่านสองครั้งไม่ได้';

  @override
  String get txDetailsBroadcastAgain => 'ส่งเข้าเครือข่ายอีกครั้ง';

  @override
  String get txDetailsBroadcastAgainDone => 'ส่งเข้าเครือข่ายอีกครั้งแล้ว';

  @override
  String get txDetailsRefusedBody =>
      'รายการนี้ยังไม่สำเร็จ ปลดเหรียญที่รายการนี้ถือไว้ได้';

  @override
  String get txDetailsReleaseFunds => 'ปลดยอดเงิน';

  @override
  String get txDetailsReleaseTitle => 'ปลดยอดเงินไหม?';

  @override
  String get txDetailsReleaseBody =>
      'รายการนี้ยังไม่สำเร็จ แต่อาจสำเร็จได้ในภายหลัง';

  @override
  String get txDetailsReleaseKeepWaiting => 'รอต่อ';

  @override
  String get txDetailsFundsReleased => 'ปลดยอดเงินแล้ว';

  @override
  String get txDetailsCancelPayment => 'ยกเลิกรายการ';

  @override
  String get txDetailsCancelTitle => 'ยกเลิกรายการนี้ไหม?';

  @override
  String get txDetailsCancelReceiveBody =>
      'ยังไม่มีอะไรมาถึง หากรายการนี้มาถึงในภายหลัง จะแสดงว่าได้รับแล้ว';

  @override
  String get txDetailsCancelSendBody =>
      'ยังไม่มีการจ่ายใด ๆ การยกเลิกไม่มีค่าธรรมเนียมและแน่นอน';

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
  String get txDetailsNoteLabel => 'บันทึกส่วนตัว';

  @override
  String get txDetailsPrivateNoteLabel => 'บันทึกส่วนตัว';

  @override
  String get txDetailsMessageFromSender => 'ข้อความ';

  @override
  String get txDetailsMessageFromRecipient => 'ข้อความจากผู้รับ';

  @override
  String get txDetailsYourMessage => 'ข้อความ';

  @override
  String get txDetailsMessageHintToRecipient => 'ส่งถึงผู้รับแล้ว';

  @override
  String get txDetailsMessageHintFromSender => 'จากผู้ส่ง';

  @override
  String get txDetailsMessageHintFromRecipient => 'จากผู้รับ';

  @override
  String get txDetailsMessageHintToSender => 'ส่งถึงผู้ส่งแล้ว';

  @override
  String get txDetailsNoNote =>
      'ไม่มีบันทึก เพิ่มไว้เพื่อจำว่ารายการนี้เป็นค่าอะไร';

  @override
  String get txDetailsAddNote => 'เพิ่มบันทึก';

  @override
  String get txDetailsEditNote => 'แก้ไขบันทึก';

  @override
  String get txDetailsNoteDialogTitle => 'บันทึกส่วนตัว';

  @override
  String get txDetailsNoteHelper =>
      'อยู่บนอุปกรณ์นี้และในข้อมูลกระเป๋าเงินที่ส่งออกเท่านั้น';

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
      'พบบนบล็อกเชน ผู้ส่งและค่าธรรมเนียมไม่ได้อยู่บนบล็อกเชน นำเข้าข้อมูลกระเป๋าเงินเพื่อเพิ่มรายละเอียด';

  @override
  String get txDetailsSourceImported =>
      'นำเข้าจากไฟล์ข้อมูลกระเป๋าเงิน ยังไม่ได้ตรวจสถานะบนเชน';

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
  String get historyBackupSaveDialogTitle => 'บันทึกข้อมูลกระเป๋าเงิน';

  @override
  String get importWarnTitle => 'ก่อนนำเข้า';

  @override
  String get importWarnEarly => 'นี่คือเวอร์ชันแรกเริ่มของแอปใหม่';

  @override
  String get importWarnReads =>
      'การนำเข้าจะอ่านกระเป๋าเงินและไฟล์เก่าของคุณเท่านั้น ไม่มีวันลบหรือแก้ไข';

  @override
  String get importWarnBackup =>
      'ก่อนดำเนินการต่อ โปรดแน่ใจว่าคุณมีข้อมูลสำรองของกระเป๋าเงินทุกใบ ได้แก่ วลีกู้คืน และไฟล์กระเป๋าเงินหากคุณเก็บไว้';

  @override
  String get importWarnRisk =>
      'คุณนำเข้าด้วยความเสี่ยงของคุณเอง และเราไม่รับผิดชอบต่อความสูญเสียใด ๆ';

  @override
  String get importWarnAck => 'ฉันมีข้อมูลสำรองของกระเป๋าเงินทุกใบแล้ว';

  @override
  String get historyBackupOpenDialogTitle => 'เปิดไฟล์ข้อมูลกระเป๋าเงิน';

  @override
  String get historyBackupFileTooLarge =>
      'ไฟล์นี้ใหญ่เกินกว่าจะเป็นไฟล์ข้อมูลกระเป๋าเงิน';

  @override
  String get historyBackupShare => 'แชร์';

  @override
  String get historyBackupShareSubtitle =>
      'สำเนานอกโทรศัพท์นี้ เช่น อีเมลหรือคลาวด์';

  @override
  String get historyBackupSaveToDevice => 'บันทึกลงอุปกรณ์';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'คัดลอกไปเก็บนอกโทรศัพท์นี้ด้วย';

  @override
  String historyBackupSaved(String fileName) {
    return 'บันทึก $fileName แล้ว';
  }

  @override
  String get historyBackupExportTitle => 'ส่งออกข้อมูลกระเป๋าเงิน';

  @override
  String get historyBackupCsvTitle => 'ส่งออก CSV';

  @override
  String get historyBackupCsvWarning =>
      'ไม่ได้เข้ารหัส: ใครมีไฟล์ก็อ่านจำนวน วันที่ ที่อยู่ และบันทึกได้ นำเข้าไม่ได้ หากต้องการสำรองข้อมูลให้ใช้ ส่งออกข้อมูลกระเป๋าเงิน';

  @override
  String get historyBackupCsvConfirm => 'ส่งออก CSV';

  @override
  String get historyBackupImportedTitle => 'นำเข้าข้อมูลกระเป๋าเงินแล้ว';

  @override
  String historyBackupImportFailed(String reason) {
    return 'นำเข้าข้อมูลกระเป๋าเงินไม่ได้ $reason';
  }

  @override
  String get historyBackupImportNothingNew => 'ไฟล์ไม่มีอะไรใหม่';

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
  String get homeNoticeSenderPosted =>
      'ผู้ส่งแจ้งว่าส่งรายการเข้าเครือข่ายแล้ว';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'ผู้ส่งแจ้งว่าส่ง $amount เข้าเครือข่ายแล้ว';
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
  String get homeNoticePaymentFailed => 'รายการหนึ่งไม่สำเร็จ ดูได้ในประวัติ';

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
      other: '$count รายการยังไม่อยู่ในข้อมูลกระเป๋าเงินที่ส่งออก',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count รายการเป็นรายการใหม่หรือเปลี่ยนไปหลังส่งออกข้อมูลกระเป๋าเงินครั้งล่าสุด',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'ไว้ทีหลัง';

  @override
  String get homeHistoryExportButton => 'ส่งออกข้อมูลกระเป๋าเงิน';

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
  String balanceExactTip(String amount) {
    return 'จำนวนที่แน่นอน: $amount';
  }

  @override
  String get homeShowBalances => 'แสดงยอดเงิน';

  @override
  String get homeHideBalances => 'ซ่อนจำนวน';

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
  String get statusEpicboxOnline => 'เชื่อมต่อ Epicbox แล้ว';

  @override
  String get statusEpicboxConnecting => 'กำลังเชื่อมต่อ Epicbox';

  @override
  String get statusEpicboxOffline => 'ไม่ได้เชื่อมต่อ Epicbox';

  @override
  String get statusEpicboxBlocked => 'Epicbox ถูกบล็อก';

  @override
  String epicboxBlockedBody(String host) {
    return 'เครือข่ายนี้บล็อก $host อาจเกิดจากตัวกรองของเครือข่าย ลองใช้เซิร์ฟเวอร์ Epicbox อื่นหรือ DNS ส่วนตัว';
  }

  @override
  String epicboxSwitchTo(String host) {
    return 'สลับไปที่ $host';
  }

  @override
  String get netStatusBlocked => 'ถูกบล็อก';

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
  String get homeEpicboxOffline =>
      'กระเป๋าเงินยังไม่ได้เชื่อมต่อกับเซิร์ฟเวอร์ Epicbox และกำลังลองต่อไป';

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
          '$amount กำลังรอกระเป๋าเงินของผู้รับตอบกลับ ระหว่างนี้เหรียญจะถูกล็อก ถ้าไม่มีคำตอบ ให้เปิดรายการแล้วแตะ ยกเลิกรายการ',
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
  String get homeNoPayments => 'ยังไม่มีการชำระเงิน';

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
      'ไม่มีใบแจ้งหนี้ที่รออยู่ เมื่อผู้ติดต่อที่จับคู่และคุณอนุญาตขอให้ชำระเงิน ใบแจ้งหนี้จะแสดงที่นี่ และจะไม่มีการชำระจนกว่าคุณจะอนุมัติ';

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
  String invoiceReviewAsks(String service) {
    return '$service ขอให้คุณชำระ';
  }

  @override
  String invoiceReviewMessageLabel(String name) {
    return 'ข้อความจาก $name';
  }

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
  String invoiceDetailsRepliedHelp(String service) {
    return 'หาก $service ยังไม่ได้โพสต์การชำระเงิน ให้ส่งอีกครั้ง โดยไม่มีการลงนามซ้ำ หากไม่ได้โพสต์เลย ปุ่มยกเลิกจะใช้ได้เมื่อหมดเวลาของการชำระเงิน ประมาณหนึ่งวันหลังจากชำระ';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service แจ้งว่าส่งรายการเข้าเครือข่ายแล้ว จะสำเร็จเมื่อเครือข่ายยืนยัน';
  }

  @override
  String invoiceDetailsConfirmed(String service) {
    return 'ชำระแล้ว เครือข่ายยืนยันการชำระให้ $service แล้ว';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service ยังไม่ได้รับการชำระเงิน ลองอีกครั้ง จะส่งซ้ำโดยไม่ต้องอนุมัติใหม่';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '$service เรียกคืนใบแจ้งหนี้นี้หลังคุณชำระแล้ว';
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
  String get requestMessageLabel => 'ข้อความถึงผู้จ่าย (ไม่บังคับ)';

  @override
  String get requestMessageHelper => 'ผู้จ่ายจะเห็นข้อความนี้พร้อมใบแจ้งหนี้';

  @override
  String get requestButton => 'ขอรับเงิน';

  @override
  String get invoicesToPaySection => 'ต้องชำระ';

  @override
  String get invoicesNoneToPay => 'ไม่มีรายการต้องชำระ';

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
  String get issuedWithdrawTitle => 'เรียกคืนใบแจ้งหนี้นี้ไหม?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer จะชำระคำขอนี้ไม่ได้อีก ยังไม่มีการชำระ จึงไม่มีเหรียญย้ายไปไหน ย้อนกลับไม่ได้';
  }

  @override
  String get issuedWithdrawKeep => 'เก็บไว้';

  @override
  String get issuedDetailsSection => 'ใบแจ้งหนี้';

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
      'ผู้จ่ายปฏิเสธใบแจ้งหนี้นี้ จึงถูกเรียกคืน ไม่มีการจ่ายเงิน';

  @override
  String get issuedDetailsWithdrawn =>
      'คุณเรียกคืนใบแจ้งหนี้นี้แล้ว ไม่มีการจ่ายเงิน';

  @override
  String get issuedDetailsExpired =>
      'ใบแจ้งหนี้นี้หมดอายุก่อนมีการชำระ ไม่มีการจ่ายเงิน';

  @override
  String get issuerNoticePaid => 'ใบแจ้งหนี้ที่คุณส่งได้รับการชำระแล้ว';

  @override
  String get issuerNoticeDeclined => 'ใบแจ้งหนี้ที่คุณส่งถูกปฏิเสธ';

  @override
  String get issuerNoticeWithdrawn => 'เรียกคืนใบแจ้งหนี้แล้ว ชำระไม่ได้อีก';

  @override
  String get issuerNoticeExpired => 'ใบแจ้งหนี้ที่คุณส่งหมดอายุโดยไม่มีการชำระ';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'กระเป๋าเงินของ $payer ชำระใบแจ้งหนี้ไม่ได้และส่งคืนมา ใบแจ้งหนี้จึงถูกเรียกคืน ขอให้เขาส่งเงินมาแทน ไปยังที่อยู่ของคุณหรือเป็นไฟล์รายการ';
  }

  @override
  String get issuedBounced => 'ถูกส่งคืน';

  @override
  String get issuedDetailsBounced =>
      'กระเป๋าเงินของผู้จ่ายชำระใบแจ้งหนี้ไม่ได้ จึงไม่มีการจ่ายเงิน ขอให้เขาส่งเงินไปยังที่อยู่ของคุณหรือเป็นไฟล์ธุรกรรม';

  @override
  String get txStatusWaitingPayer => 'รอผู้จ่าย';

  @override
  String get txStepRequested => 'ขอแล้ว';

  @override
  String get txStepPaid => 'ชำระแล้ว';

  @override
  String get txDetailsWaitingPayer =>
      'คุณขอรับเงินรายการนี้ ยังไม่มีเงินเข้า จะเข้าเมื่อผู้จ่ายชำระใบแจ้งหนี้';

  @override
  String get txDetailsRequestEnded =>
      'ใบแจ้งหนี้นี้สิ้นสุดโดยไม่มีการชำระ ไม่มีเงินเข้า';

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
  String receiveEpicboxConnected(String server) {
    return 'เชื่อมต่อแล้ว · $server';
  }

  @override
  String get receiveQrLabel => 'QR Code ของที่อยู่คุณ';

  @override
  String get receiveAddressLabel => 'ที่อยู่ Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'รายการรออยู่บนเซิร์ฟเวอร์ Epicbox และจะมาถึงเมื่อกระเป๋าเงินเชื่อมต่ออีกครั้ง';

  @override
  String get receiveShareCardHeadline => 'จ่ายให้ฉันด้วย Epic Cash';

  @override
  String get receiveHelpButton => 'การรับเงินทำงานอย่างไร';

  @override
  String get receiveAddressCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get receiveFileTitle => 'รับด้วยไฟล์ธุรกรรม';

  @override
  String get receiveFileBody => 'เปิดไฟล์ธุรกรรม หรือวางข้อความของไฟล์ที่นี่';

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
  String get updateInstallCancelled => 'ไม่ได้ติดตั้งอัปเดต ลองอีกครั้งได้';

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
  String get updateNoTorDownload =>
      'ยังดาวน์โหลดอัปเดตผ่าน Tor ไม่ได้ ปิด Tor เพื่อดาวน์โหลด หรือรับจากหน้าดาวน์โหลด';

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
  String get setupNetworkSettingsTooltip => 'โหนดและ Epicbox';

  @override
  String get setupNetworkHeading => 'เครือข่าย';

  @override
  String get setupNodeUrlLabel => 'URL ของโหนด';

  @override
  String get setupCustomRelayLabel =>
      'เซิร์ฟเวอร์ Epicbox อื่น (host หรือ host:port)';

  @override
  String get setupCustomRelayInvalid => 'ใส่ host เช่น epicbox.example.com';

  @override
  String get setupWalletPerNetwork =>
      'แต่ละเครือข่ายมีกระเป๋าเงินของตัวเอง เครือข่ายที่ยังไม่มีจะได้กระเป๋าเงินใหม่';

  @override
  String get setupRelayHealthyIconLabel => 'ทำงานปกติ';

  @override
  String get setupRelayDownIconLabel => 'ล่ม';

  @override
  String setupRelayHealthUnavailable(String site) {
    return 'ไม่มีข้อมูลสถานะเซิร์ฟเวอร์จาก $site';
  }

  @override
  String setupRelayHealthSource(String site) {
    return 'สถานะจาก $site วัดจากเซิร์ฟเวอร์ของเว็บนั้น';
  }

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
  String get restorePhraseHelper =>
      'ทุกคำ (12, 15, 18, 21 หรือ 24 คำ) คั่นด้วยช่องว่าง';

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
      'ไม่บังคับ ถ้าไม่แน่ใจ ให้เลือกวันที่ก่อนหน้า: วันที่หลังกว่าอาจทำให้เงินบางส่วนหายไป';

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
  String get restoreUnfinishedTitle => 'การกู้คืนยังไม่เสร็จ';

  @override
  String get restoreUnfinishedRunning =>
      'กำลังค้นหายอดเงินของกระเป๋าเงินนี้ตั้งแต่บล็อก 0 เมื่อเสร็จจึงรับและส่งได้';

  @override
  String get restoreUnfinishedOffline => 'การสแกนจะดำเนินต่อเมื่อปิดออฟไลน์';

  @override
  String get restoreUnfinishedFailed =>
      'การสแกนหยุดและจะลองใหม่เอง รับและส่งไม่ได้จนกว่าจะสแกนเสร็จ';

  @override
  String get errorRestoreScanRequired =>
      'การกู้คืนยังไม่เสร็จ เมื่อการสแกนที่แสดงบนหน้าหลักเสร็จจึงรับและส่งได้';

  @override
  String get restoreScanStop => 'หยุด';

  @override
  String get restoreScanScreenOn => 'หน้าจอจะเปิดค้างไว้ระหว่างสแกน';

  @override
  String get restoreScanStopped =>
      'หยุดแล้ว จะรับและส่งได้เมื่อสแกนนี้เสร็จเท่านั้น และจะดำเนินต่อจากหน้าหลัก';

  @override
  String get restoreScanUnfinished =>
      'การสแกนหยุดก่อนจบ จะรับและส่งได้เมื่อสแกนเสร็จเท่านั้น ลองอีกครั้งที่นี่ หรือเปิดกระเป๋าเงินแล้วสแกนจะดำเนินต่อจากหน้าหลัก';

  @override
  String get restoreFinishOnHome =>
      'พบยอดเงินหลังจุดเริ่มที่เลือกแล้ว ตอนนี้การสแกนตั้งแต่บล็อก 0 จะกู้คืนให้เสร็จบนหน้าหลัก เมื่อเสร็จจึงรับและส่งได้';

  @override
  String get unlockDatabaseRebuilt =>
      'ฐานข้อมูลกระเป๋าเงินเสียหายและถูกสร้างใหม่จากวลีแล้ว การสแกนจะนำยอดเงินกลับมา ส่วนรายละเอียดรายการ บันทึก และป้ายกำกับจะกลับมาได้จากไฟล์ข้อมูลกระเป๋าเงินเท่านั้น';

  @override
  String get restoreRebuiltImportText =>
      'ไฟล์ข้อมูลกระเป๋าเงินจะนำประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่ากลับมา';

  @override
  String get restoreReplaceLead =>
      'วลีนี้จะกู้คืนกระเป๋าเงินมาแทนกระเป๋าเงินบนโทรศัพท์นี้ จะไม่มีอะไรเปลี่ยนจนกว่าวลีจะผ่านการตรวจและยืนยันการแทนที่';

  @override
  String get restoreReplacePinReason =>
      'ใส่ PIN เพื่อแทนที่กระเป๋าเงินนี้ กระเป๋าเงินที่กู้คืนจะใช้ PIN นี้ต่อ';

  @override
  String restorePhraseUnknownWord(int position, String word) {
    return 'คำที่ $position “$word” ไม่อยู่ในรายการคำ';
  }

  @override
  String restorePhraseWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วลีนี้มี $count คำ วลีกู้คืนมี 12, 15, 18, 21 หรือ 24 คำ',
    );
    return '$_temp0';
  }

  @override
  String get restorePhraseChecksum =>
      'ทุกคำอยู่ในรายการคำ แต่วลีไม่ผ่านการตรวจ มีคำผิดหรือลำดับไม่ถูก';

  @override
  String deleteFailedNotice(String error) {
    return 'ยังไม่ได้ลบกระเป๋าเงิน $error ปลดล็อกแล้วลองอีกครั้งใน การตั้งค่า';
  }

  @override
  String get restoreDoneIconLabel => 'เสร็จสิ้น';

  @override
  String get restoreDoneTitle => 'กู้คืนกระเป๋าเงินแล้ว';

  @override
  String get restoreImportExplanation =>
      'วลีกู้คืนนำยอดคงเหลือกลับมาแล้ว หากต้องการนำประวัติ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่ากลับมา ให้นำเข้าไฟล์ข้อมูลกระเป๋าเงินที่ส่งออกไว้';

  @override
  String get restoreImportButton => 'นำเข้าข้อมูลกระเป๋าเงิน';

  @override
  String get restoreImportNotNow => 'ไว้ทีหลัง';

  @override
  String get restoreImportLater => 'นำเข้าได้ภายหลังจากการตั้งค่า';

  @override
  String get restoreScanProgressLabel => 'ความคืบหน้าการสแกน';

  @override
  String get firstRunTitle => 'ยินดีต้อนรับ';

  @override
  String get firstRunCreate => 'สร้างกระเป๋าเงินใหม่';

  @override
  String get firstRunRestore => 'กู้คืนจากวลีกู้คืน';

  @override
  String get settingsRestoreReplaces =>
      'กระเป๋าเงินนี้จะถูกลบ และกระเป๋าเงินของวลีที่ใส่จะมาแทน โดยใช้ PIN เดิม';

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
      'ใครเห็นคำเหล่านี้หรือรูปถ่ายของคำ ก็นำเงินไปได้';

  @override
  String get backupConsentTitle => 'ก่อนดูวลี';

  @override
  String get backupConsentWhat => 'หน้าถัดไปจะแสดงคำที่ใช้กู้คืนกระเป๋าเงินนี้';

  @override
  String get backupConsentReady => 'เตรียมกระดาษและปากกาไว้';

  @override
  String get backupCopyAgree => 'จะเก็บวลีไว้เป็นความลับ';

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
  String get backupCopyTitle => 'คัดลอกวลีกู้คืน?';

  @override
  String get backupCopyBody =>
      'ใครมีคำเหล่านี้ก็นำเงินของคุณไปได้ เก็บสำเนาไว้ในที่ปลอดภัย';

  @override
  String get backupCopied => 'คัดลอกแล้ว คลิปบอร์ดจะถูกล้างใน 60 วินาที';

  @override
  String get backupNotCopied => 'ไม่ได้คัดลอก คลิปบอร์ดปฏิเสธข้อความ';

  @override
  String get unlockTitle => 'ปลดล็อกกระเป๋า';

  @override
  String get pinlessUnlock => 'ปลดล็อก';

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
  String get pinBiometricsPinStillWorks => 'ยังใช้ PIN ได้';

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
  String get pinResetTitle => 'ลืม PIN?';

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
  String get sendMethodFile => 'ไฟล์ธุรกรรม';

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
  String get slateNotTransactionFile => 'ไฟล์นี้ไม่ใช่ไฟล์ธุรกรรม';

  @override
  String get slateReading => 'กำลังอ่านไฟล์';

  @override
  String get slateReadingQr => 'กำลังอ่านรายการ';

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
      'ปิดการเข้าถึงกล้องอยู่ อนุญาตในการตั้งค่าโทรศัพท์ หรือวางที่อยู่แทน';

  @override
  String get scanQrCameraFailed =>
      'เปิดกล้องไม่ได้ วางที่อยู่แทน หรือลองอีกครั้ง';

  @override
  String get scanQrTryAgain => 'ลองอีกครั้ง';

  @override
  String get scanQrBack => 'กลับ';

  @override
  String get qrShowReplyAsQr => 'แสดงคำตอบเป็น QR';

  @override
  String get qrShowTitlePayment => 'QR ของรายการ';

  @override
  String get qrShowTitleReply => 'QR ของคำตอบ';

  @override
  String qrShowSubPayment(String amount) {
    return '$amount ถึงโทรศัพท์ที่อยู่ข้างคุณ';
  }

  @override
  String qrShowSubReply(String amount) {
    return 'ถึงผู้ส่ง $amount';
  }

  @override
  String get qrHiddenTitle => 'ซ่อนไว้จนกว่าคุณจะแสดง';

  @override
  String get qrHiddenBodyPayment =>
      'ใครสแกนก่อนจะรับรายการนี้ได้ แสดงให้เฉพาะคนที่คุณจ่ายให้เท่านั้น';

  @override
  String get qrHiddenBodyReply =>
      'แสดงให้โทรศัพท์ของผู้ส่ง เฉพาะกระเป๋าของเขาเท่านั้นที่ใช้ได้';

  @override
  String get qrShow => 'แสดง QR';

  @override
  String get qrShowAgain => 'แสดงอีกครั้ง';

  @override
  String get qrHide => 'ซ่อน';

  @override
  String qrCountdownLabel(int seconds) {
    return 'แสดงใน $seconds';
  }

  @override
  String qrPartOf(int part, int count) {
    return 'ส่วนที่ $part จาก $count';
  }

  @override
  String qrSecondsShort(int seconds) {
    return '$seconds วิ';
  }

  @override
  String qrSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'เหลืออีก $seconds วินาที',
    );
    return '$_temp0';
  }

  @override
  String get qrHoldHint => 'ถือกล้องของโทรศัพท์อีกเครื่องให้ตรงกับโค้ดนี้';

  @override
  String get qrSecureLine => 'หน้าจอนี้ปิดการจับภาพหน้าจอ';

  @override
  String qrTimedOutTitle(int seconds) {
    return 'ซ่อนหลัง $seconds วิ';
  }

  @override
  String get qrTimedOutBody => 'แสดงอีกครั้งเมื่อโทรศัพท์อีกเครื่องพร้อม';

  @override
  String qrTimedOutAnnounce(int seconds) {
    return 'ซ่อนหลัง $seconds วินาที';
  }

  @override
  String get qrAwayTitle => 'ซ่อนไว้ขณะที่แอปไม่ได้อยู่หน้าจอ';

  @override
  String get qrAwayBody => 'โค้ดจะซ่อนทุกครั้งที่แอปออกจากหน้าจอ';

  @override
  String qrSemanticsPayment(String state) {
    return 'QR ของรายการ, $state';
  }

  @override
  String qrSemanticsReply(String state) {
    return 'QR ของคำตอบ, $state';
  }

  @override
  String get qrStateHidden => 'ซ่อนอยู่';

  @override
  String get qrStateShowing => 'แสดงอยู่';

  @override
  String get qrScanPayment => 'สแกน QR ของรายการ';

  @override
  String get qrScanReply => 'สแกนคำตอบ';

  @override
  String get qrScanAimPayment => 'หันกล้องไปที่ QR Code บนโทรศัพท์ของเขา';

  @override
  String get qrScanAimReply => 'หันกล้องไปที่คำตอบบนโทรศัพท์ของเขา';

  @override
  String get qrScanSteady => 'ถือให้นิ่ง หรือขยับเข้าไปใกล้อีกนิด';

  @override
  String get qrScanGot => 'อ่านครบแล้ว';

  @override
  String qrScanCount(int got, int count) {
    return '$got จาก $count';
  }

  @override
  String get qrScanCountLabel => 'ส่วนที่อ่านแล้ว';

  @override
  String get qrScanNotPayment =>
      'นี่ไม่ใช่ QR ของรายการ ให้เขาแสดงโค้ดรายการบนโทรศัพท์ของเขา';

  @override
  String get qrScanNotReply =>
      'นี่ไม่ใช่ QR ของคำตอบ ให้เขาแสดงคำตอบบนโทรศัพท์ของเขา';

  @override
  String get qrScanOtherPayment =>
      'โค้ดนี้เป็นของอีกรายการหนึ่ง กำลังเริ่มใหม่';

  @override
  String get qrScanTorch => 'ไฟฉาย';

  @override
  String qrScanZoom(String factor) {
    return 'ซูม $factor×';
  }

  @override
  String get qrScanCameraDenied =>
      'ปิดการเข้าถึงกล้องอยู่ อนุญาตในการตั้งค่าโทรศัพท์ หรือเปิดไฟล์แทน';

  @override
  String get qrScanCameraFailed =>
      'เปิดกล้องไม่ได้ ลองอีกครั้ง หรือเปิดไฟล์แทน';

  @override
  String get qrScanOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get qrScanOpenFileInstead => 'เปิดไฟล์แทน';

  @override
  String get qrScanAgain => 'สแกนอีกครั้ง';

  @override
  String get slateWrongPaymentQr =>
      'คำตอบนี้เป็นของอีกรายการหนึ่ง สแกนคำตอบของการส่งครั้งนี้';

  @override
  String get slateScannedPaymentTitle => 'รายการที่สแกน';

  @override
  String get slateScannedReplyTitle => 'คำตอบที่สแกน';

  @override
  String get slateIncomingSendHintQr => 'รับรายการ แล้วแสดงคำตอบให้ผู้ส่ง';

  @override
  String get slateAcceptedHeadlineQr => 'รับแล้ว แสดงคำตอบให้ผู้ส่ง';

  @override
  String get methodQr => 'ชำระด้วย QR';

  @override
  String get methodQrChip => 'QR Code';

  @override
  String get receiveTabQr => 'QR Code';

  @override
  String get methodArtCaptionQr => 'ต่อหน้า';

  @override
  String get methodArtLabelQr =>
      'โดยตรง · ชำระด้วย QR: โค้ดส่งจากโทรศัพท์เครื่องหนึ่งไปยังอีกเครื่องที่อยู่ข้างกัน';

  @override
  String get methodSendQrTitle => 'สำหรับโทรศัพท์ที่อยู่ข้างคุณ';

  @override
  String get methodSendQrLine =>
      'แสดงโค้ดบนหน้าจอนี้ แล้วใช้กล้องสแกนคำตอบของเขา';

  @override
  String get methodReceiveQrTitle => 'สแกนหน้าจอของเขา';

  @override
  String get methodReceiveQrLine =>
      'รับรายการ แล้วแสดงคำตอบของคุณด้วยวิธีเดียวกัน';

  @override
  String get receiveQrTitle => 'อยู่ข้างโทรศัพท์อีกเครื่องไหม?';

  @override
  String get receiveQrBody =>
      'สแกนรายการจากหน้าจอของเขาแล้วแสดงคำตอบของคุณ หรือขอจำนวนเงินแล้วแสดงเป็นโค้ดให้เขาสแกน';

  @override
  String get txQrHint =>
      'ชำระด้วย QR แสดงรายการเป็นโค้ดเคลื่อนไหวที่โทรศัพท์อีกเครื่องสแกนด้วยกล้อง และรับคำตอบด้วยวิธีเดียวกัน ใช้ได้เฉพาะโทรศัพท์ที่อยู่ข้างกัน ไม่ต้องมีการเชื่อมต่อระหว่างกระเป๋าทั้งสอง และโค้ดจะซ่อนเองหลัง 40 วินาที เพิ่ม ชำระด้วย QR ในส่งและรับ';

  @override
  String get advTransactionFiles => 'โอนไฟล์';

  @override
  String get advTransactionFilesHint =>
      'เพิ่มโอนไฟล์ใน ตั้งค่า › ธุรกรรม: จ่ายหรือรับเงินด้วยไฟล์ที่คุณส่งต่อเอง';

  @override
  String get sendQrTitle => 'ชำระด้วย QR';

  @override
  String get sendMakeQr => 'สร้าง QR ของรายการ';

  @override
  String sendQrPinReason(String amount) {
    return 'ใส่ PIN เพื่อสร้าง QR ของรายการ $amount';
  }

  @override
  String get sendQrMade => 'QR ของรายการพร้อมแล้ว';

  @override
  String get sendQrHint => 'แสดงโค้ดให้โทรศัพท์ของผู้รับ แล้วสแกนคำตอบของเขา';

  @override
  String get sendCancelRuleQr => 'ยกเลิกได้จนกว่าคุณจะสแกนคำตอบของเขา';

  @override
  String get qrStatusSendHidden => 'แสดงสิ่งนี้ให้ผู้รับ';

  @override
  String get qrStatusSendShowing => 'รอผู้รับสแกน แล้วสแกนคำตอบของเขา';

  @override
  String get qrStatusHiddenAgain => 'ซ่อนอยู่';

  @override
  String get qrStatusReplyHidden => 'ซ่อนอยู่';

  @override
  String get qrStatusReplyShowing => 'รอผู้ส่งสแกน';

  @override
  String get qrStatusReceivedWaiting =>
      'ได้รับรายการแล้ว รอผู้ส่งสแกนและส่งเข้าเครือข่าย';

  @override
  String qrStatusPosted(int got, int target) {
    return 'ส่งแล้ว กำลังยืนยัน $got/$target';
  }

  @override
  String get qrStatusReceived => 'ได้รับแล้ว';

  @override
  String qrScanProgress(int got, int count) {
    return 'สแกนแล้ว $got จาก $count ให้โค้ดอยู่ในกรอบ';
  }

  @override
  String get qrScanReplyScanned => 'สแกนคำตอบแล้ว';

  @override
  String get qrScanPosting => 'สแกนคำตอบแล้ว กำลังส่ง…';

  @override
  String get qrScanPosted => 'ส่งแล้ว';

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
  String get contactsAddressInvalidAny =>
      'ที่อยู่ไม่ถูกต้อง ใช้ที่อยู่ Epicbox (es5x…@เซิร์ฟเวอร์) ที่อยู่ลิงก์ (https://…) หรือที่อยู่ onion (….onion)';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsSectionNetwork => 'เซิร์ฟเวอร์';

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
  String get settingsHideBalances => 'ซ่อนจำนวน';

  @override
  String get settingsTheme => 'ธีม';

  @override
  String get settingsThemeSystem => 'ระบบ';

  @override
  String get settingsThemeLight => 'สว่าง';

  @override
  String get settingsThemeDark => 'มืด';

  @override
  String get settingsPricesOnNotice =>
      'ราคามาจาก CoinGecko ซึ่งจะเห็นที่อยู่ IP ของคุณ';

  @override
  String get settingsSectionSecurity => 'ความปลอดภัย';

  @override
  String get settingsChangePin => 'เปลี่ยน PIN';

  @override
  String get settingsBiometrics => 'ปลดล็อกด้วยไบโอเมตริก';

  @override
  String get settingsBiometricsOn =>
      'การปลดล็อกด้วยไบโอเมตริกจะใช้ได้ตั้งแต่เปิดแอปครั้งถัดไป';

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
  String get settingsSectionHistory => 'ข้อมูลกระเป๋าเงิน';

  @override
  String get settingsExportHistory => 'ส่งออกข้อมูลกระเป๋าเงิน';

  @override
  String get settingsExportCsv => 'ส่งออก CSV';

  @override
  String get settingsImportHistory => 'นำเข้าข้อมูลกระเป๋าเงิน';

  @override
  String get settingsSectionWallet => 'กระเป๋าเงินนี้';

  @override
  String get settingsContacts => 'ผู้ติดต่อ';

  @override
  String get settingsSectionInvoices => 'ใบแจ้งหนี้';

  @override
  String get settingsInvoices => 'ใบแจ้งหนี้';

  @override
  String get settingsInvoicesSubtitle => 'ใครขอให้คุณชำระเงินได้';

  @override
  String get settingsRescan => 'ตรวจยอดใหม่';

  @override
  String get settingsRescanFinished => 'ตรวจยอดใหม่แล้ว';

  @override
  String get settingsRescanTitle => 'ตรวจยอดใหม่';

  @override
  String get settingsRescanBody =>
      'ตรวจสอบบล็อกเชนอีกครั้งเพื่อหาเงินของกระเป๋านี้ เริ่มจากจุดที่เก่ากว่าจะพบมากกว่าแต่ใช้เวลานานกว่า';

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
  String get settingsRescanButton => 'ตรวจใหม่';

  @override
  String get settingsDeleteWallet => 'ลบกระเป๋าเงิน';

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
  String get settingsCheckUpdates => 'ตรวจหาอัปเดต';

  @override
  String settingsUpdatesFrom(String store) {
    return 'การอัปเดตมาจาก $store';
  }

  @override
  String get settingsHelp => 'ช่วยเหลือ';

  @override
  String get settingsSendFeedback => 'รายงานปัญหา';

  @override
  String get settingsSendFeedbackHint =>
      'แจ้งปัญหาหรือเสนอไอเดียให้ผู้พัฒนา ล็อกจะส่งไปเฉพาะเมื่อคุณแนบ โดยลบวลีกู้คืน PIN และข้อมูลลับอื่นๆ ออกก่อน';

  @override
  String get settingsSourceCode => 'ซอร์สโค้ด';

  @override
  String get settingsPrivacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get contactLabel => 'ติดต่อ';

  @override
  String get settingsLicences => 'สัญญาอนุญาต';

  @override
  String get licencesLead =>
      'ซอฟต์แวร์โอเพนซอร์สในกระเป๋านี้ แต่ละส่วนมีสัญญาอนุญาตของตนเอง';

  @override
  String get licencesApp => 'Epic Cash Mobile โดย BT Labs: Apache 2.0';

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
  String get settingsAddressCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get settingsCopyAddress => 'คัดลอกที่อยู่';

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
  String get helpDonateTitle => 'สนับสนุนการพัฒนา';

  @override
  String get helpDonateText => 'เงินบริจาคใช้พัฒนาฟีเจอร์ใหม่';

  @override
  String get helpDonateCopy => 'คัดลอกที่อยู่';

  @override
  String get helpDonateCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String get helpSendFeedback => 'รายงานปัญหา';

  @override
  String get feedbackTitle => 'รายงานปัญหา';

  @override
  String get feedbackIntro => 'อธิบายสิ่งที่ผิดพลาดหรือสิ่งที่ควรปรับปรุง';

  @override
  String get feedbackMessageLabel => 'เกิดอะไรขึ้น';

  @override
  String get feedbackMessageMissing => 'เขียนสั้นๆ ว่าเกิดอะไรขึ้น';

  @override
  String get feedbackEmailLabel => 'ช่องทางติดต่อ (ไม่บังคับ)';

  @override
  String get feedbackEmailInvalid => 'ดูไม่เหมือนที่อยู่อีเมล';

  @override
  String get feedbackAttachLogs => 'แนบบันทึก';

  @override
  String get feedbackAttachLogsHint =>
      'ล็อกช่วยหาสาเหตุของปัญหา วลีกู้คืน PIN และข้อมูลลับอื่นๆ จะถูกลบออกก่อน';

  @override
  String get feedbackPreviewButton => 'สิ่งที่ส่ง';

  @override
  String get feedbackSend => 'ส่ง';

  @override
  String get feedbackShareOrSaveInstead => 'แชร์หรือบันทึก';

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
      'แสดงด้านเทคนิค รายละเอียดโหนดและเซิร์ฟเวอร์ Epicbox ความสูงบล็อก ไฟล์ธุรกรรม และล็อก เมื่อปิด แอปจะแสดงเฉพาะสิ่งที่ใช้ในชีวิตประจำวัน';

  @override
  String get settingsSectionPrivacy => 'ความเป็นส่วนตัว';

  @override
  String get settingsSectionPrivacyNetwork => 'ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get settingsSectionHelpFeedback => 'ช่วยเหลือ';

  @override
  String get settingsStateBackUp => 'สำรองวลีกู้คืน';

  @override
  String get settingsStateNotBackedUp => 'ยังไม่ได้สำรอง';

  @override
  String get settingsHubBackup => 'สำรองข้อมูล';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String settingsUseStatusSite(String site) {
    return 'ใช้ $site';
  }

  @override
  String get settingsUseStatusSiteSubtitle =>
      'แสดงว่าโหนดและเซิร์ฟเวอร์ Epicbox ใดออนไลน์อยู่ ดาวน์โหลดเพียงรายการสาธารณะ ไม่มีการส่งข้อมูลใดจากกระเป๋าเงิน';

  @override
  String get txStepStarted => 'เริ่มรายการแล้ว';

  @override
  String get txStepAccepted => 'ผู้รับลงนามแล้ว';

  @override
  String get txStepPosted => 'ส่งไปยังเครือข่ายแล้ว';

  @override
  String get txStepConfirming => 'กำลังยืนยัน';

  @override
  String get txStepConfirmed => 'ยืนยันแล้ว';

  @override
  String get txStepArrived => 'ได้รับเงินแล้ว';

  @override
  String get txStepSenderFinished => 'ลงนามและส่งคืนแล้ว';

  @override
  String get fileHelpTitle => 'ไฟล์ธุรกรรมทำงานอย่างไร';

  @override
  String get fileHelpYou => 'คุณ';

  @override
  String get fileHelpFriend => 'เพื่อน';

  @override
  String get fileHelpSendStep1 => 'คุณสร้างไฟล์ธุรกรรม';

  @override
  String get fileHelpSendStep2 =>
      'ส่งไฟล์ให้เพื่อนด้วยวิธีใดก็ได้ เช่น แชตหรืออีเมล';

  @override
  String get fileHelpSendStep3 =>
      'เพื่อนเปิดไฟล์ในกระเป๋าของตนแล้วส่งไฟล์ตอบกลับมา';

  @override
  String get fileHelpSendStep4 => 'คุณเปิดไฟล์ตอบกลับ แล้วรายการก็ถูกส่งออกไป';

  @override
  String get fileHelpReceiveStep1 => 'เพื่อนสร้างไฟล์ธุรกรรมให้คุณ';

  @override
  String get fileHelpReceiveStep2 =>
      'เพื่อนส่งไฟล์ให้คุณด้วยวิธีใดก็ได้ เช่น แชตหรืออีเมล';

  @override
  String get fileHelpReceiveStep3 => 'คุณเปิดไฟล์ในกระเป๋าแล้วส่งไฟล์ตอบกลับไป';

  @override
  String get fileHelpReceiveStep4 =>
      'เพื่อนเปิดไฟล์ตอบกลับ แล้วเงินก็กำลังมาถึงคุณ';

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
  String get sendStepMethod => 'วิธีชำระเงิน';

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
  String get sendUseFile => 'ไม่มีที่อยู่? ใช้ไฟล์ธุรกรรม';

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
  String get sendAddNote => 'เพิ่มข้อความ';

  @override
  String get sendNoteLabel => 'ข้อความ';

  @override
  String get sendNoteHelper => 'ผู้รับเห็นข้อความนี้';

  @override
  String get sendReviewMessageKept =>
      'ผู้รับเห็นข้อความนี้ และจะเก็บสำเนาไว้เป็นบันทึกส่วนตัวของคุณซึ่งแก้ไขได้';

  @override
  String get sendNetworkFee => 'ค่าธรรมเนียม';

  @override
  String get sendChecking => 'กำลังตรวจสอบ…';

  @override
  String get sendReady => 'พร้อมส่ง';

  @override
  String get sendNodeDown => 'เชื่อมต่อเครือข่ายไม่ได้ในขณะนี้';

  @override
  String sendRelayDown(String relay) {
    return 'เซิร์ฟเวอร์ Epicbox ของผู้รับ ($relay) ไม่ตอบสนอง';
  }

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
    return 'กระเป๋าของผู้รับจะลงนามเมื่อเปิดขึ้นมา ระหว่างนี้ $amount จะถูกล็อก';
  }

  @override
  String get sendTrackIfNot => 'หากรายการไม่เสร็จ?';

  @override
  String get sendTrackCancelled => 'รายการนี้ถูกยกเลิกแล้ว';

  @override
  String get sendNoCoins => 'ยังไม่มีเหรียญให้ส่ง';

  @override
  String get sendFileTitle => 'โดยตรง · โอนไฟล์';

  @override
  String get sendMakeFile => 'สร้างไฟล์ธุรกรรม';

  @override
  String get sendFileMade => 'สร้างไฟล์แล้ว';

  @override
  String sendFileOnHold(String amount) {
    return 'ล็อก $amount';
  }

  @override
  String get sendFileWaitingReply => 'รอไฟล์ตอบกลับ';

  @override
  String get sendFileShareHint =>
      'ส่งไฟล์นี้ให้ผู้รับ แล้วเปิดไฟล์ตอบกลับที่ส่งกลับมา';

  @override
  String get sendOpenReply => 'เปิดไฟล์ตอบกลับ';

  @override
  String get handshakePayment => 'ชำระเงิน';

  @override
  String get handshakeRequest => 'ใบแจ้งหนี้';

  @override
  String get handshakeYou => 'คุณ';

  @override
  String get handshakeThem => 'อีกฝ่าย';

  @override
  String get handshakeNetwork => 'เครือข่าย';

  @override
  String get handshakePay1 =>
      'กระเป๋าของคุณส่งรายการไปยังเซิร์ฟเวอร์ Epicbox เหรียญถูกล็อก';

  @override
  String get handshakePay2 =>
      'เซิร์ฟเวอร์ส่งต่อไป กระเป๋าของอีกฝ่ายเพิ่มส่วนของตนและลงนาม';

  @override
  String get handshakeFinish =>
      'กระเป๋าของคุณทำรายการให้เสร็จและส่งไปยังเครือข่าย';

  @override
  String get handshakeConfirm => 'เครือข่ายยืนยันรายการ';

  @override
  String get handshakeReq1 =>
      'กระเป๋าของคุณส่งใบแจ้งหนี้ไปยังเซิร์ฟเวอร์ Epicbox';

  @override
  String get handshakeReq2 =>
      'เซิร์ฟเวอร์ส่งต่อไป อีกฝ่ายอนุมัติ แล้วกระเป๋าของอีกฝ่ายเพิ่มเหรียญและลงนาม';

  @override
  String get handshakeRelay => 'เซิร์ฟเวอร์ Epicbox';

  @override
  String get handshakeFile => 'โอนไฟล์';

  @override
  String get handshakeBack =>
      'กระเป๋าของอีกฝ่ายส่งกลับไปยังเซิร์ฟเวอร์ Epicbox';

  @override
  String get handshakeRelayBack => 'เซิร์ฟเวอร์ส่งกลับมายังกระเป๋าของคุณ';

  @override
  String get handshakeFile1 =>
      'กระเป๋าของคุณบันทึกไฟล์ธุรกรรม คุณส่งไฟล์ให้อีกฝ่ายเอง';

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
  String get handshakeLink1 =>
      'กระเป๋าของคุณส่งรายการตรงไปยังกระเป๋าของอีกฝ่ายผ่านอินเทอร์เน็ตหรือ Tor เหรียญถูกล็อก';

  @override
  String get handshakeLink2 =>
      'กระเป๋าของอีกฝ่ายเพิ่มส่วนของตน ลงนาม และตอบกลับในการเชื่อมต่อเดียวกัน';

  @override
  String get handshakeQr1 => 'คุณแสดงโค้ดของคุณ';

  @override
  String get handshakeQr2 => 'อีกฝ่ายสแกนด้วยกระเป๋าของตน';

  @override
  String get handshakeQr3 => 'กระเป๋าของอีกฝ่ายแสดงโค้ดตอบกลับ';

  @override
  String get handshakeQr4 => 'คุณสแกนโค้ดนั้น';

  @override
  String get handshakeQr5 => 'กระเป๋าของคุณส่งรายการไปยังเครือข่าย';

  @override
  String get handshakeQrR1 => 'อีกฝ่ายแสดงโค้ดของตน';

  @override
  String get handshakeQrR2 => 'คุณสแกนด้วยกระเป๋าของคุณ';

  @override
  String get handshakeQrR3 => 'กระเป๋าของคุณแสดงโค้ดตอบกลับ';

  @override
  String get handshakeQrR4 => 'อีกฝ่ายสแกนโค้ดนั้น';

  @override
  String get handshakeQrR5 => 'กระเป๋าของอีกฝ่ายส่งรายการไปยังเครือข่าย';

  @override
  String get handshakeNext => 'ขั้นตอนถัดไป';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'เซิร์ฟเวอร์ Epicbox ของผู้รับ ($relay) ปฏิเสธรายการ จำนวนเงินจะถูกล็อกจนกว่าจะยกเลิก หรือไม่เกิน $days วัน',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'เซิร์ฟเวอร์ Epicbox ของผู้รับ ($relay) ปฏิเสธรายการ ตรวจสอบหน้ากระเป๋าก่อนส่งอีกครั้ง';
  }

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
    return 'ล็อก $amount';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount กำลังเข้า';
  }

  @override
  String get demoTestCoinsPill => 'เหรียญทดสอบ';

  @override
  String get demoTestCoinsPillTip => 'เครือข่ายทดสอบของ Epic เหรียญไม่มีมูลค่า';

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
      'ส่งให้เดโมของเพื่อน หรือเปิดเดโมในเบราว์เซอร์อื่นหรือหน้าต่างส่วนตัว';

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
  String get receiveTorAddressLabel => 'ที่อยู่ ลิงก์ · Tor';

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
      'กำลังติดต่อกระเป๋าของผู้รับผ่าน Tor… เปิดแอปไว้';

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
  String get sendTorTryEpicbox =>
      'Epicbox ส่งการชำระเงินได้แม้กระเป๋าเงินของผู้รับออฟไลน์อยู่';

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
  String get homeTileMaturing => 'รอครบกำหนด';

  @override
  String get homeTileTotal => 'รวม';

  @override
  String homeViewAll(int count) {
    return 'ดูทั้งหมด $count';
  }

  @override
  String get tourPhoneSemantics => 'ทัวร์กระเป๋าเงิน';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current จาก $total';
  }

  @override
  String get tourPhoneSkip => 'ข้ามทัวร์';

  @override
  String get tourPhoneBack => 'ย้อนกลับ';

  @override
  String get tourPhoneNext => 'ถัดไป';

  @override
  String get tourPhoneWalletTitle => 'กระเป๋าเงิน';

  @override
  String get tourPhoneWalletText =>
      'ยอดคงเหลือของคุณ และใต้ลงไปคือไอคอนโหนด Epicbox และ Tor สิ่งที่ยังอยู่ระหว่างยืนยันอยู่ในช่องด้านล่าง';

  @override
  String get tourPhoneSendTitle => 'ส่ง';

  @override
  String get tourPhoneSendText =>
      'วางหรือสแกนที่อยู่ หรือเลือกผู้ติดต่อ Epicbox จ่ายไปที่อยู่ QR แสดงโค้ดให้โทรศัพท์ที่อยู่ข้างคุณ วิธีอื่น: การตั้งค่า › ธุรกรรม จะมีการตรวจสอบก่อนเสมอ';

  @override
  String get tourPhoneReceiveTitle => 'รับ';

  @override
  String get tourPhoneReceiveText =>
      'ที่อยู่ Epicbox ของคุณ แชร์เพื่อรับเงิน แท็บไฟล์ใช้กับไฟล์ธุรกรรมที่ต้องเซ็นหรือทำให้เสร็จ';

  @override
  String get tourPhoneActivityTitle => 'ประวัติ';

  @override
  String get tourPhoneActivityText =>
      'ทุกรายการพร้อมความคืบหน้าและรายละเอียด แตะรายการเพื่อเปิด';

  @override
  String get tourPhoneContactsTitle => 'ผู้ติดต่อ';

  @override
  String get tourPhoneContactsText =>
      'ที่อยู่ที่บันทึกไว้ตามชื่อ หน้าส่งเลือกจากที่นี่';

  @override
  String get tourPhoneInvoicesTitle => 'ใบแจ้งหนี้';

  @override
  String get tourPhoneInvoicesText =>
      'ชำระใบแจ้งหนี้ที่มีคนส่งมา หรือขอให้ใครจ่ายเงิน แท็บใช้สลับระหว่างสองอย่างนี้';

  @override
  String get tourPhonePrivacyTitle => 'ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get tourPhonePrivacyText =>
      'โหนดและเซิร์ฟเวอร์ Epicbox ที่กระเป๋าเงินใช้ และสวิตช์ Tor แตะเซิร์ฟเวอร์เพื่อเปลี่ยน';

  @override
  String get tourPhoneAdvancedTitle => 'ขั้นสูง';

  @override
  String get tourPhoneAdvancedText =>
      'โหมด Tor เท่านั้น เอาต์พุต และรายละเอียดทางเทคนิคอยู่ที่นี่ เปิดเฉพาะที่ต้องการ';

  @override
  String get tourPhoneHelpTitle => 'ช่วยเหลือ';

  @override
  String get tourPhoneHelpText =>
      'ค้นหาหัวข้อหรือส่งความคิดเห็น “แสดงทัวร์แนะนำอีกครั้ง” อยู่ท้ายรายการ';

  @override
  String get tourPhoneShowAgain => 'แสดงทัวร์แนะนำอีกครั้ง';

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
    return 'ป้อน PIN เพื่อสร้างไฟล์ธุรกรรม $amount';
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
  String outputsWaitLocked(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks การยืนยัน',
    );
    return 'รอให้การส่งที่กำลังดำเนินการได้รับการยืนยัน ($_temp0)';
  }

  @override
  String get outputsStrategy => 'วิธีเลือกเอาต์พุตตอนส่ง';

  @override
  String get outputsStrategyHint =>
      'การส่งจะใช้เอาต์พุตใด เล็กสุด ใช้เอาต์พุตเล็กให้น้อยที่สุด ยอดที่เหลือจึงยังใช้ได้ระหว่างที่เงินทอนรอการยืนยัน ทั้งหมด ใช้ทุกเอาต์พุตที่ใช้ได้และคืนเงินทอนเป็นเอาต์พุตเดียว ทุกอย่างถูกล็อกจนกว่าจะยืนยัน หลังจากนั้นจะมีเอาต์พุตน้อยลงแต่ใหญ่ขึ้น';

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
  String get outputsSplitChangeText =>
      'เมื่อการส่งจะเหลือเอาต์พุตที่ใช้ได้น้อยกว่า 3 และเงินทอนมีอย่างน้อย 1 EPIC เงินทอนจะกลับมาเป็นเอาต์พุตได้ถึง 4 ก้อน การส่งครั้งถัดไปจึงไม่ต้องรอการยืนยัน คิด 0.004 EPIC ต่อเอาต์พุตที่เพิ่ม';

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
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks บล็อก',
    );
    return 'ใช้ $spent ($amount) และสร้าง $made ประมาณ $each ต่อเอาต์พุต เป็นธุรกรรมปกติบนเครือข่ายที่ส่งเข้ากระเป๋านี้ ยืนยันหลัง $_temp0เหมือนการส่งทั่วไป ยอดที่ใช้ได้ทั้งหมดจะถูกล็อกจนกว่าจะยืนยัน เอาต์พุตที่มากขึ้นช่วยให้การส่งครั้งถัดไปหลายรายการออกไปได้โดยไม่ต้องรอเงินทอนของกันและกัน';
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
  String outputsFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks บล็อก',
    );
    return '$amount ประมาณ $_temp0';
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
  String outputsConsolidateText(
    String amount,
    String result,
    String spent,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks การยืนยัน',
    );
    return 'ใช้ $spent ($amount) และสร้างเอาต์พุตเดียวมูลค่า $result ยอดที่ใช้ได้ทั้งหมดจะถูกล็อกจนครบ $_temp0';
  }

  @override
  String get outputsConsolidateAction => 'รวม';

  @override
  String get outputsSplitPin => 'ยืนยันด้วย PIN เพื่อแยกเอาต์พุต';

  @override
  String get outputsConsolidatePin => 'ยืนยันด้วย PIN เพื่อรวมเอาต์พุต';

  @override
  String outputsSplitStarted(int count, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks บล็อก',
    );
    return 'เริ่มแยกแล้ว: $count เอาต์พุต ยืนยันในประมาณ $_temp0';
  }

  @override
  String outputsConsolidateStarted(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks บล็อก',
    );
    return 'เริ่มรวมแล้ว: 1 เอาต์พุต ยืนยันในประมาณ $_temp0';
  }

  @override
  String get outputsAdvanced => 'จัดการเอาต์พุต';

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
  String get contactsNoteHeading => 'บันทึก';

  @override
  String get contactsShowCode => 'แสดง QR Code';

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
  String get invoicesNewRequest => 'ใบแจ้งหนี้ใหม่';

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
  String get invoicesSentEmpty => 'ยังไม่ได้ส่งใบแจ้งหนี้';

  @override
  String get invoicesSentEmptyCaption =>
      'ใบแจ้งหนี้คือการขอให้ผู้อื่นชำระเงินตามจำนวนที่กำหนด';

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
  String get invoicesNodeOk => 'ซิงก์แล้ว';

  @override
  String get invoicesNodeDown => 'ไม่ตอบสนอง';

  @override
  String get invoicesEpicboxOk => 'เชื่อมต่อแล้ว';

  @override
  String get invoicesEpicboxDown => 'ไม่ได้เชื่อมต่อ';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return 'ขอให้ $payer ชำระ $amount ใบแจ้งหนี้จะหมดอายุใน 24 ชั่วโมง';
  }

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
  String get netStatusConnected => 'เชื่อมต่อแล้ว';

  @override
  String get netStatusNotConnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get serverUpNotConnected => 'เซิร์ฟเวอร์ทำงาน · ไม่ได้เชื่อมต่อ';

  @override
  String get netStatusOn => 'เปิด';

  @override
  String get netStatusFailed => 'ล้มเหลว';

  @override
  String netStatusStarting(int percent) {
    return 'กำลังเริ่ม $percent %';
  }

  @override
  String get netStatusTitle => 'สถานะเครือข่าย';

  @override
  String get serverMyRelays => 'เซิร์ฟเวอร์ของฉัน';

  @override
  String get serverMenuDelete => 'ลบ';

  @override
  String get netStatusReachable => 'เข้าถึงได้';

  @override
  String get netStatusPublishing => 'กำลังเผยแพร่…';

  @override
  String get netStatusNotReachable => 'เข้าถึงไม่ได้';

  @override
  String get netStatusTorOpenHint => 'เปิดการตั้งค่าความเป็นส่วนตัว';

  @override
  String get netStatusDirectOpenHint => 'เปิดที่อยู่สำหรับการรับผ่านลิงก์';

  @override
  String get netStatusOpenHint => 'แสดงเซิร์ฟเวอร์';

  @override
  String get serverNodeTitle => 'โหนด';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'ค้นหาโหนด';

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
  String serverHealthUnknown(String site) {
    return 'เข้าถึง $site ไม่ได้ ไม่ทราบสถานะ';
  }

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
  String get serverNotResponding => 'ไม่ตอบสนอง';

  @override
  String get serverLocalNotReachable => 'เข้าถึงจากคอมพิวเตอร์เครื่องนี้ไม่ได้';

  @override
  String get serverLocalNotReachablePhone =>
      'เข้าถึงจากโทรศัพท์เครื่องนี้ไม่ได้';

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
  String get serverRelayWarning =>
      'ที่อยู่ของคุณมีเซิร์ฟเวอร์นี้อยู่ด้วย การเปลี่ยนจะทำให้ที่อยู่เปลี่ยน ผู้ส่งต้องใช้ที่อยู่ใหม่';

  @override
  String get serverOtherRelay => 'เซิร์ฟเวอร์อื่น host หรือ host:port';

  @override
  String get serverMyListNote => 'ตัวที่ใช้อยู่และที่เพิ่มเอง';

  @override
  String get serverPublicNote => 'แตะเพื่อเปลี่ยนไปใช้ตัวนั้น';

  @override
  String get serverOtherNode => 'โหนดอื่น host หรือ host:port';

  @override
  String serverOtherNodeInvalid(String port) {
    return 'ใส่ที่อยู่โหนด เช่น node.example.com:$port';
  }

  @override
  String get serverAdd => 'เพิ่ม';

  @override
  String get serverAddedNode => 'เพิ่มในโหนดของฉันแล้ว';

  @override
  String get serverAddedRelay => 'เพิ่มในเซิร์ฟเวอร์ของฉันแล้ว';

  @override
  String serverDeleted(String host) {
    return 'ลบ $host แล้ว';
  }

  @override
  String get serverAlreadyInUse => 'ใช้อยู่แล้ว';

  @override
  String get serverNoMatch => 'ไม่พบรายการที่ตรงกัน';

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
  String serverCheckedAt(String time, String site) {
    return '$site ตรวจเมื่อ $time';
  }

  @override
  String serverRowLabel(String host, String facts) {
    return '$host, $facts';
  }

  @override
  String get methodEpicbox => 'Epicbox';

  @override
  String get methodDirectHttp => 'ลิงก์ · HTTP';

  @override
  String get methodDirectTor => 'ลิงก์ · Tor';

  @override
  String get methodFile => 'โอนไฟล์';

  @override
  String get methodShortHttp => 'ลิงก์ · HTTP';

  @override
  String get methodShortTor => 'ลิงก์ · Tor';

  @override
  String get methodShortQr => 'โดยตรง · QR';

  @override
  String get methodShortFile => 'โดยตรง · ไฟล์';

  @override
  String get methodGroupHttp => 'HTTP';

  @override
  String get methodGroupTor => 'Tor';

  @override
  String get methodDirectQr => 'โดยตรง · ชำระด้วย QR';

  @override
  String get methodDirectFile => 'โดยตรง · โอนไฟล์';

  @override
  String get methodDirectFamily => 'โดยตรง';

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
      'ลิงก์ · HTTP: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';

  @override
  String get methodArtLabelTor =>
      'ลิงก์ · Tor: รายการจะไปถึงกระเป๋าของผู้รับโดยตรงผ่านเครือข่าย Tor';

  @override
  String get methodArtLabelFile =>
      'โดยตรง · โอนไฟล์: ส่งไฟล์ธุรกรรมไป รับไฟล์ตอบกลับมา แล้วผู้ส่งทำรายการให้เสร็จ';

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
  String get sendSwitchedHttp => 'ลิงก์ · HTTP';

  @override
  String get sendSwitchedEpicbox => 'ผ่าน Epicbox';

  @override
  String get sendSwitchedTorAnnounce =>
      'ที่อยู่ Tor ตั้งวิธีส่งเป็น ลิงก์ · Tor แล้ว';

  @override
  String get sendSwitchedHttpAnnounce =>
      'ที่อยู่ HTTP ตั้งวิธีส่งเป็น ลิงก์ · HTTP แล้ว';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'ที่อยู่ Epicbox ตั้งวิธีส่งเป็น Epicbox แล้ว';

  @override
  String get sendReviewMethodHttp => 'ลิงก์ · HTTP ส่งตรงถึงกระเป๋าผู้รับ';

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
          'ติดต่อกระเป๋าของผู้รับไม่ได้ จำนวนเงินจะถูกล็อกจนกว่าจะยกเลิก หรือไม่เกิน $days วัน',
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
      'รายการแสดงสิ่งที่ได้รับก่อนหน้านี้ กระเป๋าจะลองใหม่เอง';

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
  String get deskInvFailed => 'ไม่สำเร็จ ไม่มีสิ่งใดเปลี่ยนแปลง ลองอีกครั้ง';

  @override
  String get deskInvHowItWorks => 'ใบแจ้งหนี้ทำงานอย่างไร';

  @override
  String get deskInvIssuerSoon => 'เร็วๆ นี้';

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
  String get deskInvIssuerRelayDown =>
      'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง จึงส่งใบแจ้งหนี้ไม่ได้ในขณะนี้';

  @override
  String get deskInvIssuerNotDelivered =>
      'ใบแจ้งหนี้ไปไม่ถึงเซิร์ฟเวอร์ Epicbox ไม่มีสิ่งใดถูกส่ง ลองอีกครั้ง';

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
    return '$payer จะชำระใบแจ้งหนี้นี้ไม่ได้อีก ยังไม่มีการชำระ จึงไม่มีเหรียญย้ายไปไหน';
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
    return 'กระเป๋าของ $payer ชำระใบแจ้งหนี้ไม่ได้ ขอให้ $payer ส่งเงินมาแทน';
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
    return 'ส่งถึงเซิร์ฟเวอร์ Epicbox ของ $payer แล้ว ไม่มีการชำระใดๆ จนกว่าผู้ชำระจะอนุมัติ';
  }

  @override
  String get deskInvIssuerCopySlate => 'คัดลอก Slate ID';

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
      'มีการชำระเงินสำหรับใบแจ้งหนี้ที่อุปกรณ์นี้ไม่ได้ออกเข้ามา ระบบจะเก็บไว้บนเซิร์ฟเวอร์หนึ่งวันสำหรับอุปกรณ์อีกเครื่องของคุณที่ใช้กระเป๋านี้ เปิดกระเป๋าที่เครื่องนั้นเพื่อทำให้เสร็จ';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'มีคำตอบของการชำระเงินที่อุปกรณ์นี้ไม่ได้ส่งเข้ามา ระบบจะเก็บไว้บนเซิร์ฟเวอร์หนึ่งวันสำหรับอุปกรณ์อีกเครื่องของคุณที่ใช้กระเป๋านี้ เปิดกระเป๋าที่เครื่องนั้นเพื่อทำให้เสร็จ';

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
  String get deskInvPayerEmptyTitle => 'ไม่มีใบแจ้งหนี้รออยู่';

  @override
  String get deskInvPayerEmptyText =>
      'ใบแจ้งหนี้จากผู้ติดต่อที่จับคู่และได้รับอนุญาตจะแสดงที่นี่ จะไม่มีการชำระจนกว่าจะอนุมัติ';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'การชำระถึง $service ส่งไม่ถึง';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'รายการลงนามแล้วและเก็บไว้ในคอมพิวเตอร์นี้ EPIC ยังถูกล็อกอยู่ ลองใหม่จะส่งอีกครั้งโดยไม่ต้องอนุมัติซ้ำ';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service เรียกคืนใบแจ้งหนี้ที่คุณชำระแล้ว';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'รายการอาจไม่ถึงบล็อกเชน ยกเลิกเพื่อคืนเหรียญ';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'การชำระถึง $service ไม่อยู่บนบล็อกเชน';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'เลยเวลาแล้วและเครือข่ายไม่พบรายการนี้ ยกเลิกเพื่อคืนเหรียญ';

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
  String deskInvPayerMessageCaption(String name) {
    return 'เขียนโดย $name กระเป๋าไม่ได้ตรวจสอบข้อความนี้';
  }

  @override
  String get deskInvPayerPaysTo => 'ชำระไปที่';

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
  String deskInvPayerShortText(
    String total,
    String spendable,
    int confirmations,
  ) {
    return 'ต้องมียอดที่ใช้ได้ $total EPIC มีอยู่ $spendable EPIC เงินที่กำลังยืนยันจะนับรวมเมื่อได้รับการยืนยัน $confirmations ครั้ง';
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
  String get deskInvPayerCancelText => 'อีกฝ่ายยังทำรายการนี้ให้เสร็จได้';

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
  String get deskInvPayerSpentText => 'เหรียญกำลังกลับมายังกระเป๋าเงินนี้';

  @override
  String get deskInvPayerSpendFailedText =>
      'ยังย้ายเหรียญกลับมาไม่ได้ กระเป๋าเงินจะลองใหม่ขณะที่เปิดอยู่ ระหว่างนั้นรายการยังอาจสำเร็จได้';

  @override
  String get deskInvPayerLocked =>
      'ชำระใบแจ้งหนี้นี้ไม่ได้ เพราะถูกล็อกไว้จนถึงบล็อกถัดไป ไม่มีการชำระ';

  @override
  String get deskInvPayerRelayDownPay =>
      'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง ไม่มีการชำระ';

  @override
  String get deskInvSetTitle => 'ใบแจ้งหนี้';

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
  String get deskInvSetReceiveHint =>
      'ขอให้ผู้ติดต่อที่จับคู่แล้วชำระเงินให้คุณ หรือบันทึกใบแจ้งหนี้เป็นไฟล์';

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
  String get methodDirect => 'ลิงก์';

  @override
  String get methodLinkPayment => 'จ่ายผ่านลิงก์';

  @override
  String methodDirectShape(String port) {
    return 'http://host:$port หรือ xxxx….onion';
  }

  @override
  String get methodSendDirectLine =>
      'กระเป๋าของผู้รับต้องเปิดอยู่ ที่อยู่ onion จะส่งผ่าน Tor';

  @override
  String get methodArtLabelDirect =>
      'ลิงก์: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';

  @override
  String methodArtSpokenLink(String method) {
    return '$method: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';
  }

  @override
  String methodArtSpokenQr(String method) {
    return '$method: โค้ดส่งจากโทรศัพท์เครื่องหนึ่งไปยังอีกเครื่องที่อยู่ข้างกัน';
  }

  @override
  String methodArtSpokenFile(String method) {
    return '$method: ส่งไฟล์ธุรกรรมไป รับไฟล์ตอบกลับมา แล้วผู้ส่งทำรายการให้เสร็จ';
  }

  @override
  String get methodReceiveEpicboxShort => 'ผู้ส่งจ่ายได้แม้กระเป๋านี้ปิดอยู่';

  @override
  String get methodReceiveDirectTitle => 'ส่งตรงถึงกระเป๋านี้';

  @override
  String get methodReceiveDirectLine => 'ใช้ได้ขณะเปิดแอปอยู่';

  @override
  String methodLineOverTor(String line) {
    return '$line ผ่าน Tor';
  }

  @override
  String get sendSwitchedDirect => 'ที่อยู่ลิงก์';

  @override
  String get sendSwitchedDirectAnnounce =>
      'ที่อยู่ลิงก์ ตั้งวิธีส่งเป็น ลิงก์ แล้ว';

  @override
  String get sendDirectAddressShape =>
      'ที่อยู่ลิงก์ขึ้นต้นด้วย http:// หรือ https:// หรือลงท้ายด้วย .onion';

  @override
  String get torNotOverTor => 'ไม่ผ่าน Tor';

  @override
  String get torNeeds => 'Link · Tor ต้องใช้ Tor';

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
      'การเชื่อมต่อเครือข่ายจะผ่านเครือข่าย Tor ซึ่งซ่อนที่อยู่อินเทอร์เน็ตของกระเป๋า แต่ละการเชื่อมต่อผ่านเซิร์ฟเวอร์หลายจุดที่อาสาสมัครดูแล จึงไม่มีเซิร์ฟเวอร์ใดรู้ว่ากระเป๋าอยู่ที่ไหน หากต้องการรับเงินที่ที่อยู่ Tor ให้เปิด ลิงก์ · Tor ใน การตั้งค่า › ธุรกรรม';

  @override
  String get receiveTabDirect => 'ลิงก์';

  @override
  String get receiveDirectNeedsTor => 'ลิงก์ · Tor ต้องใช้ Tor';

  @override
  String get receiveDirectMeanwhile => 'ระหว่างนี้ให้แชร์ที่อยู่ Epicbox';

  @override
  String get receiveHttpTitle => 'ที่อยู่ ลิงก์ · HTTP';

  @override
  String get receiveHttpLanLine =>
      'สำหรับกระเป๋าเงินในเครือข่าย Wi-Fi นี้ ขณะที่กระเป๋าเงินนี้เปิดอยู่';

  @override
  String get receiveHttpNoNetwork =>
      'ไม่ได้เชื่อมต่อ Wi-Fi ไม่มีที่อยู่ให้ส่งต่อ';

  @override
  String get receiveHttpOffWhileTor => 'ปิดอยู่ขณะเปิด Tor';

  @override
  String receiveHttpPortInUse(String port) {
    return 'พอร์ต $port ถูกใช้โดยโปรแกรมอื่น';
  }

  @override
  String get receiveHttpFailed => 'เริ่มไม่ได้';

  @override
  String get receiveHttpShowQr => 'แสดง QR';

  @override
  String get receiveHttpHideQr => 'ซ่อน QR';

  @override
  String get receiveHttpQrLabel => 'QR Code ของที่อยู่ ลิงก์ · HTTP';

  @override
  String get netStatusOverTor => 'ผ่าน Tor';

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
  String get deskErrSomethingWrong => 'เกิดข้อผิดพลาด';

  @override
  String get deskErrWrongPassword => 'รหัสผ่านไม่ถูกต้อง';

  @override
  String get deskErrPhraseInvalid => 'วลีกู้คืนไม่ถูกต้อง';

  @override
  String get deskErrWalletExists => 'มีกระเป๋าเงินอยู่แล้ว';

  @override
  String get deskErrWalletNotFound => 'ไม่พบกระเป๋าเงิน';

  @override
  String get deskErrNodeNotAnswering => 'โหนดไม่ตอบสนอง';

  @override
  String get deskErrNotEnoughFunds => 'ยอดไม่พอ';

  @override
  String get deskErrNotTxFile => 'ไม่ใช่ไฟล์ธุรกรรมของกระเป๋าเงินนี้';

  @override
  String get deskErrEpicboxUnreachable => 'เชื่อมต่อเซิร์ฟเวอร์ Epicbox ไม่ได้';

  @override
  String get deskErrNotHttpAddress => 'ไม่ใช่ที่อยู่ http(s)';

  @override
  String get deskErrPlainHttp => 'ยังไม่ได้ยืนยันการใช้ HTTP ธรรมดา';

  @override
  String get deskErrNotOnion => 'ไม่ใช่ที่อยู่ onion';

  @override
  String get deskErrTorNotConnected => 'Tor ไม่ได้เชื่อมต่อ';

  @override
  String get deskErrOnionUnreachable =>
      'ติดต่อกระเป๋าเงินของผู้รับผ่าน Tor ไม่ได้ Epicbox ส่งการชำระเงินได้แม้กระเป๋าเงินออฟไลน์อยู่';

  @override
  String get deskErrWalletBusy => 'กระเป๋าเงินไม่ว่าง ลองอีกครั้งในอีกสักครู่';

  @override
  String get deskErrDbDamaged => 'ฐานข้อมูลกระเป๋าเงินเสียหาย กำลังสร้างใหม่';

  @override
  String get deskErrPaymentExpired => 'รายการหมดอายุ';

  @override
  String get deskErrInvoiceNotFound => 'ไม่พบใบแจ้งหนี้';

  @override
  String get deskErrAmountMismatch => 'จำนวนไม่ตรงกับใบแจ้งหนี้';

  @override
  String get deskErrInvoicePaid => 'ใบแจ้งหนี้ชำระแล้ว';

  @override
  String get deskErrInvoiceLocked => 'ใบแจ้งหนี้ถูกล็อกจนถึงบล็อกถัดไป';

  @override
  String get deskErrInvoiceChanged => 'ใบแจ้งหนี้เปลี่ยนไป';

  @override
  String get deskErrNotAccepted => 'ไม่ได้รับ';

  @override
  String deskErrNotAcceptedDetail(String detail) {
    return 'ไม่ได้รับ: $detail';
  }

  @override
  String get deskErrDisk => 'ข้อผิดพลาดของดิสก์';

  @override
  String deskErrDiskDetail(String detail) {
    return 'ข้อผิดพลาดของดิสก์: $detail';
  }

  @override
  String get deskErrTorMissing => 'รุ่นนี้ไม่มี Tor';

  @override
  String get deskErrTorNetwork => 'เชื่อมต่อเครือข่าย Tor ไม่ได้';

  @override
  String get deskErrTorClock => 'นาฬิกาของคอมพิวเตอร์ไม่ตรง';

  @override
  String get deskErrOnionNotPublished => 'ยังไม่ได้เผยแพร่ที่อยู่ onion';

  @override
  String get deskErrTorStart => 'Tor ไม่เริ่มทำงาน';

  @override
  String get deskErrTorStopped => 'Tor หยุดแล้ว';

  @override
  String get deskErrScanRunning => 'มีการสแกนอยู่แล้ว';

  @override
  String get deskErrCancelRefused => 'ไม่ได้ยกเลิก: โหนดได้รับรายการนี้แล้ว';

  @override
  String get deskErrWalletLocked => 'กระเป๋าเงินล็อกอยู่';

  @override
  String get deskErrWalletLocking => 'กระเป๋าเงินกำลังล็อก';

  @override
  String deskErrDbDamagedDetail(String detail) {
    return 'ฐานข้อมูลกระเป๋าเงินเสียหาย $detail';
  }

  @override
  String deskErrWalletClosed(String detail) {
    return 'ปิดกระเป๋าเงินแล้ว: $detail ปลดล็อกอีกครั้ง';
  }

  @override
  String deskErrNotChanged(String detail) {
    return 'ไม่ได้เปลี่ยน: $detail';
  }

  @override
  String deskErrPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใช้อย่างน้อย $count ตัวอักษร',
    );
    return '$_temp0';
  }

  @override
  String get deskErrWalletNotListed => 'กระเป๋าเงินไม่อยู่ในรายการ';

  @override
  String get deskErrUpdateApp => 'อัปเดตแอปเพื่อเปลี่ยนรายการ';

  @override
  String get deskErrListNotChanged => 'ไม่ได้เปลี่ยนรายการกระเป๋าเงิน';

  @override
  String get deskErrOpenToDelete => 'เปิดกระเป๋าเงินก่อนลบ';

  @override
  String get deskErrEnterPassword => 'ใส่รหัสผ่าน';

  @override
  String get deskErrFolderNotFound => 'ไม่พบโฟลเดอร์กระเป๋าเงิน';

  @override
  String deskErrAlreadyHere(String name) {
    return 'มีกระเป๋าเงินนี้อยู่แล้ว: $name';
  }

  @override
  String get deskErrTestNet => 'นี่คือกระเป๋าเงินทดสอบ นำเข้าไม่ได้';

  @override
  String get deskErrWalletInApp => 'กระเป๋าเงินนี้อยู่ในแอปแล้ว';

  @override
  String get deskErrWalletNotFoundSearch => 'ไม่พบกระเป๋าเงิน ค้นหาอีกครั้ง';

  @override
  String get deskErrEnterOldPassword => 'ใส่รหัสผ่านเดิม';

  @override
  String deskErrOldPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รหัสผ่านเดิมสั้นไป ตั้งรหัสผ่านใหม่อย่างน้อย $count ตัวอักษร',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSeedUnreadable => 'อ่านไฟล์ wallet.seed ไม่ได้';

  @override
  String get deskErrNotSeedFile => 'ไม่ใช่ไฟล์ wallet.seed';

  @override
  String deskErrAlreadyInApp(String name) {
    return 'อยู่ในแอปแล้วในชื่อ $name';
  }

  @override
  String get deskErrWrongOldPassword => 'รหัสผ่านเดิมไม่ถูกต้อง';

  @override
  String get deskErrListNotSaved => 'ไม่ได้บันทึกรายการกระเป๋าเงิน';

  @override
  String get deskErrProofSeedRead => 'อ่าน seed แล้ว';

  @override
  String get deskErrProofWalletCreated => 'สร้างกระเป๋าเงินแล้ว';

  @override
  String deskErrProofContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $count ราย',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofNode(String name) {
    return 'เพิ่มโหนด $name ในรายการโหนดแล้ว';
  }

  @override
  String deskErrProofEpicbox(String old, String current) {
    return 'แอปเดิมใช้เซิร์ฟเวอร์ Epicbox $old แอปนี้ใช้ $current';
  }

  @override
  String get deskErrProofFolderUnchanged => 'โฟลเดอร์เดิมไม่เปลี่ยนแปลง';

  @override
  String get deskErrProofFolderChanged => 'โปรแกรมอื่นเปลี่ยนโฟลเดอร์เดิม';

  @override
  String deskErrProofHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ประวัติ: $count ธุรกรรม',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofHistoryAlready => 'นำเข้าประวัติไปแล้ว';

  @override
  String get deskErrProofHistoryNone =>
      'โฟลเดอร์เดิมไม่มีประวัติ การสแกนจะกู้ยอดคงเหลือคืน';

  @override
  String get deskErrProofHistoryOld =>
      'ประวัติอยู่ในรูปแบบฐานข้อมูลรุ่นเก่า อ่านไม่ได้ การสแกนจะกู้ยอดคืน';

  @override
  String get deskErrProofHistoryBusy =>
      'ไม่ได้นำเข้าประวัติ: กระเป๋าเงินเดิมกำลังทำงาน จะนำเข้าเมื่อปลดล็อกครั้งถัดไป';

  @override
  String get deskErrProofHistoryOther =>
      'ไม่ได้นำเข้าประวัติ: เป็นของกระเป๋าเงินอื่น';

  @override
  String get deskErrProofHistoryUnreadable =>
      'ไม่ได้นำเข้าประวัติ: อ่านฐานข้อมูลเดิมไม่ได้ การสแกนจะกู้ยอดคงเหลือคืน';

  @override
  String get deskErrNodeNoAnswer => 'โหนดไม่ตอบ';

  @override
  String get deskErrNotPosted => 'ไม่ได้ส่งเข้าเครือข่าย';

  @override
  String get deskErrNotEpicboxAddress => 'ไม่ใช่ที่อยู่ Epicbox';

  @override
  String get deskErrFileNotSaved =>
      'ไม่ได้บันทึกไฟล์ รายการรออยู่ในประวัติ ยกเลิกที่นั่นเพื่อปลดล็อกยอดเงิน';

  @override
  String get deskErrTorOffSend =>
      'Tor ปิดอยู่ เปิด Tor เพื่อส่งไปที่อยู่ onion';

  @override
  String get deskErrTorConnecting =>
      'Tor ยังเชื่อมต่ออยู่ ลองอีกครั้งในอีกสักครู่';

  @override
  String get deskErrRecipientNoAnswer => 'กระเป๋าเงินของผู้รับไม่ตอบหรือปฏิเสธ';

  @override
  String get deskErrRecipientNoAnswerWaits =>
      'กระเป๋าเงินของผู้รับไม่ตอบหรือปฏิเสธ รายการรออยู่ในประวัติ ยกเลิกที่นั่นเพื่อปลดล็อกยอดเงิน';

  @override
  String get deskErrNotDelivered =>
      'ส่งไม่ถึง รายการรออยู่ในประวัติ ยกเลิกที่นั่นเพื่อปลดล็อกยอดเงิน';

  @override
  String get deskErrInterruptedLock =>
      'ถูกขัดจังหวะเพราะล็อก รายการอาจส่งออกไปแล้ว: ตรวจประวัติหลังปลดล็อก';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail รายการรออยู่ในประวัติ ยกเลิกที่นั่นเพื่อปลดล็อกยอดเงิน';
  }

  @override
  String get deskErrNodeRefused =>
      'ทั้งสองกระเป๋าเงินลงนามแล้ว แต่โหนดปฏิเสธ ยกเลิกในประวัติเพื่อปลดล็อกยอดเงิน';

  @override
  String get deskErrFileNotReadable => 'อ่านไฟล์ไม่ได้';

  @override
  String get deskErrNotTxFile2 => 'ไม่ใช่ไฟล์ธุรกรรม';

  @override
  String get deskErrResponseNotSaved => 'ไม่ได้บันทึกไฟล์ตอบกลับ';

  @override
  String get deskErrCannotCancel => 'ยกเลิกรายการนี้ไม่ได้';

  @override
  String get deskErrNoLocalNode => 'รุ่นนี้ไม่มีโหนดในเครื่อง';

  @override
  String get deskErrLocalNodeStopped => 'โหนดในเครื่องหยุดแล้ว';

  @override
  String get deskErrNotChangedLocked => 'ไม่ได้เปลี่ยน: กระเป๋าเงินถูกล็อก';

  @override
  String deskErrLocalNodeNotStarted(String detail) {
    return 'โหนดในเครื่องไม่เริ่มทำงาน: $detail';
  }

  @override
  String get deskErrUnknown => 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ';

  @override
  String get deskErrNotServerName => 'ไม่ใช่ชื่อเซิร์ฟเวอร์';

  @override
  String deskErrPortInUse(int port) {
    return 'พอร์ต $port ถูกใช้อยู่';
  }

  @override
  String deskErrPortUnavailable(int port) {
    return 'ใช้พอร์ต $port ไม่ได้';
  }

  @override
  String get deskErrStoppedWithError => 'หยุดเพราะข้อผิดพลาด';

  @override
  String get deskErrPasswordNotChanged =>
      'ไม่ได้เปลี่ยนรหัสผ่าน รหัสผ่านปัจจุบันยังใช้เปิดกระเป๋าเงินได้';

  @override
  String get deskErrNothingToSpend => 'ไม่มียอดให้ใช้';

  @override
  String get deskTorLineOff => 'ปิด';

  @override
  String get deskTorLineReady => 'พร้อม';

  @override
  String deskTorLineSendsWork(String problem) {
    return '$problem การส่งใช้ได้';
  }

  @override
  String get deskTorLinePublishing => 'กำลังเผยแพร่ที่อยู่ onion…';

  @override
  String deskTorLineConnecting(int percent) {
    return 'กำลังเชื่อมต่อ Tor… $percent%';
  }

  @override
  String get deskErrHistOtherWallet => 'ข้อมูลของกระเป๋าเงินอื่น';

  @override
  String get deskErrHistOtherChain => 'เครือข่ายไม่ตรง';

  @override
  String get deskErrHistNotOurs => 'ไม่ใช่ไฟล์ข้อมูลกระเป๋าเงิน';

  @override
  String get deskErrHistNewer => 'ไฟล์จากรุ่นใหม่กว่า';

  @override
  String get deskErrHistDamaged => 'ไฟล์เสียหาย';

  @override
  String get deskErrOldGui => 'Epic Wallet รุ่นเก่า';

  @override
  String get deskErrOldCli => 'โปรแกรม epic';

  @override
  String get deskErrOldPicked => 'โฟลเดอร์ที่เลือก';

  @override
  String get deskErrHistTooLarge => 'ไฟล์ใหญ่เกินกว่าจะเป็นข้อมูลสำรอง';

  @override
  String get deskErrHistChains => 'ไฟล์มาจากเครือข่ายอื่น';

  @override
  String get deskErrHistOtherWalletText =>
      'ไฟล์ส่งออกจากกระเป๋าเงินที่มีวลีกู้คืนต่างกัน';

  @override
  String get deskErrHistNewerText =>
      'แอปเวอร์ชันใหม่กว่าเป็นผู้สร้างไฟล์นี้ อัปเดตแอปแล้วนำเข้า';

  @override
  String get deskErrHistDamagedText => 'ไฟล์ไม่ครบหรือถูกแก้ไข';

  @override
  String get deskErrHistNotOursText =>
      'ไฟล์นี้ไม่ได้สร้างจาก Epic Cash Desktop หรือ Epic Cash Mobile';

  @override
  String get deskDataHttpEnter => 'ใส่ที่อยู่ของผู้รับ';

  @override
  String get deskDataHttpScheme => 'ขึ้นต้นด้วย https:// หรือ http://';

  @override
  String get deskDataHttpOnion => 'ที่อยู่ onion ต้องใช้ Tor';

  @override
  String get deskDataHttpNot => 'ไม่ใช่ที่อยู่ http(s)';

  @override
  String get deskDataHttpPort => 'พอร์ตต้องอยู่ระหว่าง 1 ถึง 65535';

  @override
  String get deskDataUpdTimeout => 'เซิร์ฟเวอร์อัปเดตไม่ตอบ';

  @override
  String get deskDataUpdUnreachable => 'เชื่อมต่อเซิร์ฟเวอร์อัปเดตไม่ได้';

  @override
  String deskDataUpdStatus(int status) {
    return 'เซิร์ฟเวอร์อัปเดตผิดพลาด ($status)';
  }

  @override
  String get deskDataUpdNone => 'ยังไม่มีข้อมูลอัปเดตสำหรับเดสก์ท็อป';

  @override
  String get deskNodeSynced => 'ซิงก์แล้ว';

  @override
  String get deskNodeBehind => 'ตามหลัง';

  @override
  String get deskNodeNotAnswering => 'ไม่ตอบสนอง';

  @override
  String get deskNodeChecking => 'กำลังตรวจ';

  @override
  String get deskNodeStarting => 'กำลังเริ่ม';

  @override
  String get deskNodeSyncing => 'กำลังซิงก์';

  @override
  String get deskNodeStalled => 'ค้าง';

  @override
  String get deskNodeFailed => 'ล้มเหลว';

  @override
  String get deskNodeStopped => 'หยุดอยู่';

  @override
  String get deskNodeMarkerNoAnswer => 'ไม่ตอบ';

  @override
  String deskNodeMarkerBehind(String count) {
    return 'ตามหลัง $count';
  }

  @override
  String get deskNodeMarkerStarting => 'กำลังเริ่ม';

  @override
  String get deskNodeMarkerStalled => 'ค้าง';

  @override
  String get deskNodeMarkerFailed => 'ล้มเหลว';

  @override
  String get deskNodeMarkerStopped => 'หยุดอยู่';

  @override
  String deskNodeHostSince(String host, String time) {
    return '$host · ตั้งแต่ $time';
  }

  @override
  String get deskNodeNotAnsweringLine => 'โหนดไม่ตอบสนอง';

  @override
  String deskNodeLatency(String ms) {
    return '$ms ms';
  }

  @override
  String deskNodeLatencyOverTor(String ms) {
    return '$ms ms ผ่าน Tor';
  }

  @override
  String deskNodeNewerOut(String version) {
    return 'มี $version แล้ว';
  }

  @override
  String get deskNodeBehindLine => 'ตามหลังเครือข่าย กำลังตามให้ทัน';

  @override
  String deskNodeHeightOf(String height, String total) {
    return '$height จาก $total';
  }

  @override
  String get deskNodeAtTip => 'ล่าสุด';

  @override
  String get deskNodeLocal => 'โหนดในเครื่อง';

  @override
  String get deskNodeConnectingPeers => 'กำลังเชื่อมต่อ peer';

  @override
  String deskNodeUsingUntilSynced(String host) {
    return 'ใช้ $host จนกว่าจะซิงก์เสร็จ';
  }

  @override
  String get deskNodeNothingUntilSynced => 'ส่งไม่ได้จนกว่าจะซิงก์เสร็จ';

  @override
  String deskNodePeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เชื่อมต่อ $count peer',
    );
    return '$_temp0';
  }

  @override
  String deskNodeRunning(String duration) {
    return 'ทำงานมา $duration';
  }

  @override
  String deskNodeStillUsing(String host) {
    return 'ยังใช้ $host อยู่ อีกไม่นานโหนดในเครื่องจะทำงานแทน';
  }

  @override
  String get deskNodeNoProgress =>
      'ไม่คืบหน้า 5 นาที เริ่มใหม่ไปแล้วหนึ่งครั้ง';

  @override
  String deskNodeUsingMeanwhile(String host) {
    return 'ใช้ $host ระหว่างนี้';
  }

  @override
  String get deskNodeStartIt => 'เริ่มได้ที่ การตั้งค่า › โหนด';

  @override
  String deskNodeFailPort(String port) {
    return 'พอร์ต $port ถูกโปรแกรมอื่นใช้อยู่';
  }

  @override
  String get deskNodeFailDisk => 'พื้นที่ดิสก์ไม่พอ';

  @override
  String get deskNodeFailMissing => 'ไม่พบโปรแกรมโหนด';

  @override
  String get deskNodeFailExited => 'โปรแกรมโหนดหยุดทำงาน';

  @override
  String deskNodeFailExitedCode(String code) {
    return 'โปรแกรมโหนดหยุดทำงาน (exit code $code)';
  }

  @override
  String get deskNodeFailDefault => 'โหนดไม่เริ่มทำงาน';

  @override
  String get deskNodeStageWaiting => 'กำลังเชื่อมต่อ peer';

  @override
  String get deskNodeStageHeaders => 'header';

  @override
  String get deskNodeStageChainDownload => 'ดาวน์โหลดสถานะเชน';

  @override
  String get deskNodeStageKernels => 'ตรวจ kernel';

  @override
  String get deskNodeStageRangeProofs => 'ตรวจ range proof';

  @override
  String get deskNodeStageProcessing => 'ประมวลผลสถานะเชน';

  @override
  String get deskNodeStageBlocks => 'บล็อก';

  @override
  String get deskNodeStageCompacting => 'บีบอัดข้อมูล';

  @override
  String get deskNodeStageStopping => 'กำลังหยุด';

  @override
  String get deskNodeStageSyncing => 'กำลังซิงก์';

  @override
  String get deskNodeLineWaiting => 'กำลังเชื่อมต่อ peer';

  @override
  String deskNodeLineHeaders(String done, String total) {
    return 'Header · $done จาก $total';
  }

  @override
  String get deskNodeLineHeadersBare => 'Header';

  @override
  String deskNodeLineChain(String done, String total) {
    return 'สถานะเชน · $done จาก $total GB';
  }

  @override
  String get deskNodeLineChainBare => 'สถานะเชน';

  @override
  String deskNodeLineKernels(String done, String total) {
    return 'ตรวจ kernel · $done จาก $total ล้าน';
  }

  @override
  String get deskNodeLineKernelsBare => 'ตรวจ kernel';

  @override
  String deskNodeLineRangeProofs(String done, String total) {
    return 'ตรวจ range proof · $done จาก $total ล้าน';
  }

  @override
  String get deskNodeLineRangeProofsBare => 'ตรวจ range proof';

  @override
  String get deskNodeLineProcessing => 'กำลังประมวลผลสถานะเชน';

  @override
  String deskNodeLineBlocks(String done, String total) {
    return 'บล็อก · $done จาก $total';
  }

  @override
  String get deskNodeLineBlocksBare => 'บล็อก';

  @override
  String get deskNodeLineCompacting => 'กำลังบีบอัดข้อมูลบล็อกเชน';

  @override
  String get deskNodeLineStopping => 'กำลังหยุด…';

  @override
  String get deskNodeLineSyncing => 'กำลังซิงก์';

  @override
  String deskNodeDurationHm(int hours, int minutes) {
    return '$hours ชั่วโมง $minutes นาที';
  }

  @override
  String deskNodeDurationM(int minutes) {
    return '$minutes นาที';
  }

  @override
  String get deskTorNetworkLabel => 'เครือข่าย Tor';

  @override
  String get deskTorNetworkHint =>
      'การเชื่อมต่อเครือข่ายจะผ่านเครือข่าย Tor ซึ่งซ่อนที่อยู่อินเทอร์เน็ตของกระเป๋าเงิน: แต่ละการเชื่อมต่อผ่านรีเลย์หลายตัวที่อาสาสมัครดูแล จึงไม่มีเซิร์ฟเวอร์ไหนรู้ว่ากระเป๋าเงินอยู่ที่ไหน';

  @override
  String get deskTorOff => 'ปิด';

  @override
  String get deskTorStarting => 'กำลังเริ่ม…';

  @override
  String get deskTorOn => 'เปิด';

  @override
  String get deskTorNotConnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get deskTorCoverage =>
      'ผ่าน Tor: Epicbox, โหนด, สถานะ, ราคา, อัปเดต, ฝ่ายช่วยเหลือ และที่อยู่ Tor';

  @override
  String get deskTorNodeOver => 'ผ่าน Tor';

  @override
  String get deskTorNodeNotEncrypted => 'ไม่เข้ารหัสหลังออกจาก Tor';

  @override
  String get deskTorNodeWaits => 'รอจนกว่า Tor จะเชื่อมต่อ';

  @override
  String get deskRecvTitle => 'รับ';

  @override
  String get deskRecvReceiving => 'การรับเงิน';

  @override
  String get deskRecvNameFile => 'โดยตรง · โอนไฟล์';

  @override
  String deskRecvTurnOnFailed(String method) {
    return 'ไม่ได้เปิด $method';
  }

  @override
  String deskRecvTurnOffFailed(String method) {
    return 'ไม่ได้ปิด $method';
  }

  @override
  String get deskRecvOtherWays => 'วิธีรับเงินอื่น';

  @override
  String get deskRecvSettings => 'การตั้งค่า';

  @override
  String get deskRecvTorNotConnected => 'Tor ไม่ได้เชื่อมต่อ';

  @override
  String get deskRecvTorStarting => 'Tor กำลังเริ่ม';

  @override
  String get deskRecvTorDownText =>
      'ทุกการเชื่อมต่อรอ Tor ลองอีกครั้ง หรือปิด Tor';

  @override
  String get deskRecvTorStartingText =>
      'ที่อยู่จะเข้าถึงได้เมื่อ Tor เชื่อมต่อ';

  @override
  String get deskRecvTurnTorOff => 'ปิด Tor';

  @override
  String get deskRecvTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskRecvStateOn => 'เปิด';

  @override
  String get deskRecvStateOff => 'ปิด';

  @override
  String get deskRecvStateChecking => 'กำลังตรวจ';

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
    return '$method · กำลังตรวจ';
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
  String get deskRecvTagPaused => 'หยุดชั่วคราว';

  @override
  String get deskRecvTagStarting => 'กำลังเริ่ม';

  @override
  String get deskRecvTagNotReachable => 'เข้าถึงไม่ได้';

  @override
  String get deskRecvAddressUnreadable =>
      'อ่านที่อยู่ไม่ได้ เปิดหน้า รับ อีกครั้งในอีกสักครู่';

  @override
  String get deskRecvEpicboxAddress => 'ที่อยู่ Epicbox';

  @override
  String get deskRecvCopyEpicbox => 'คัดลอกที่อยู่ Epicbox';

  @override
  String get deskRecvEpicboxIntro =>
      'แชร์ที่อยู่เพื่อรับเงิน ผู้ส่งจ่ายได้แม้กระเป๋านี้ปิดอยู่';

  @override
  String get deskRecvCheckSix =>
      'เวลาอ่านให้กัน ให้เทียบ 6 ตัวแรกและ 6 ตัวสุดท้าย';

  @override
  String get deskRecvHttpAddress => 'ที่อยู่ ลิงก์ · HTTP';

  @override
  String get deskRecvCopyHttp => 'คัดลอกที่อยู่ ลิงก์ · HTTP';

  @override
  String deskRecvHttpPublic(int port) {
    return 'ที่อยู่สาธารณะของเราเตอร์ ผู้ส่งบนอินเทอร์เน็ตใช้ได้เมื่อเราเตอร์ forward พอร์ต $port แล้ว';
  }

  @override
  String get deskRecvHttpLocal =>
      'โปรแกรมบนคอมพิวเตอร์นี้จ่ายมาที่ที่อยู่นี้ได้ สำหรับอุปกรณ์อื่น ดูที่ การตั้งค่า › ธุรกรรม';

  @override
  String get deskRecvHttpIntro =>
      'สำหรับกระเป๋าเงินบนคอมพิวเตอร์เครื่องนี้ ขณะที่กระเป๋าเงินนี้เปิดอยู่';

  @override
  String get deskRecvHttpTorHint =>
      'เปิด Tor ที่ การตั้งค่า › ความเป็นส่วนตัว เพื่อใช้ที่อยู่ Tor แทน';

  @override
  String get deskRecvDirectTor => 'ที่อยู่ ลิงก์ · Tor';

  @override
  String get deskRecvTorIntro =>
      'ตรงจากกระเป๋าเงินอื่นผ่าน Tor ขณะที่กระเป๋าเงินนี้เปิดอยู่ ตั้งค่า Tor ได้ที่ การตั้งค่า › ความเป็นส่วนตัว';

  @override
  String get deskRecvTorAddress => 'ที่อยู่ ลิงก์ · Tor';

  @override
  String get deskRecvCopyTor => 'คัดลอกที่อยู่ Tor';

  @override
  String get deskRecvTorOnion =>
      'บางกระเป๋าเงินแสดงที่อยู่โดยไม่มี .onion ซึ่งเป็นที่อยู่เดียวกัน';

  @override
  String get deskRecvFiles => 'ไฟล์ธุรกรรม';

  @override
  String get deskRecvSignTitle => 'ลงนามไฟล์ธุรกรรม';

  @override
  String get deskRecvSignText =>
      'ลงนามไฟล์ธุรกรรมของผู้ส่งและบันทึกไฟล์ตอบกลับ';

  @override
  String get deskRecvOpen => 'เปิด';

  @override
  String get deskRecvFinalizeTitle => 'ทำรายการให้เสร็จด้วยไฟล์ตอบกลับ';

  @override
  String get deskRecvFinalizeText =>
      'ใช้ไฟล์ตอบกลับของผู้รับทำรายการให้เสร็จเพื่อส่งเข้าเครือข่าย';

  @override
  String deskRecvSwitchLabel(String title) {
    return '$title, การรับเงิน';
  }

  @override
  String get deskSendStrategySmallest => 'เล็กสุด';

  @override
  String get deskSendStrategyAll => 'ทั้งหมด';

  @override
  String get deskSendBalanceAfter => 'ยอดหลังส่ง';

  @override
  String get deskSendSpendableUntil => 'ใช้ได้ระหว่างรอเงินทอนยืนยัน';

  @override
  String deskSendSplitLine(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'แยกเงินทอนเป็น $outputs เอาต์พุต (+ค่าธรรมเนียม $fee EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskSendSplitWhy(int outputs, String each) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other:
          'เพื่อให้การส่งครั้งถัดไปไม่ต้องรอครั้งนี้ยืนยัน เงินทอนจะกลับมาเป็น $outputs เอาต์พุต ก้อนละประมาณ $each EPIC แทนก้อนเดียว',
    );
    return '$_temp0';
  }

  @override
  String get deskSendSplitWhyLabel => 'ทำไมจึงแยกเงินทอน';

  @override
  String deskSendLockNoChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ไม่มีเงินทอน: ใช้ $count เอาต์พุตพอดี ไม่มีอะไรต้องรอ',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockAll(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ทุกอย่างถูกล็อก: $count เอาต์พุต $amount EPIC ประมาณ $blocks บล็อก',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ล็อก $count เอาต์พุต $amount EPIC ประมาณ $blocks บล็อก',
    );
    return '$_temp0';
  }

  @override
  String deskSendStrategyLine(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วิธีเลือกเอาต์พุตของการส่งนี้: $strategy · $count เอาต์พุต',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSplit(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'แยกเงินทอนเป็น $outputs เอาต์พุต (+$fee EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksNone(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$locked EPIC ใน $count เอาต์พุต ไม่มีเงินทอนกลับมา',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ทั้งหมด: $locked EPIC ใน $count เอาต์พุต จนกว่าเงินทอนจะยืนยัน ($blocks บล็อก) ไม่มีส่วนไหนใช้ได้ระหว่างนั้น',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC ใน $count เอาต์พุต จนกว่าเงินทอนจะยืนยัน ($blocks บล็อก) ไม่มีส่วนอื่นใช้ได้ระหว่างนั้น',
    );
    return '$_temp0';
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
          '$locked EPIC ใน $count เอาต์พุต จนกว่าเงินทอนจะยืนยัน ($blocks บล็อก) ยังใช้ได้ $spendable EPIC',
    );
    return '$_temp0';
  }

  @override
  String get deskSendFactLocks => 'ล็อก';

  @override
  String get deskSendFactStrategy => 'วิธีเลือก';

  @override
  String deskSendFactStrategyValue(String strategy) {
    return 'เอาต์พุตแบบ$strategy สำหรับการส่งนี้';
  }

  @override
  String get deskSendAdvSmallest => '· เอาต์พุตเล็กสุด';

  @override
  String get deskSendAdvSmallestNoSplit => '· เอาต์พุตเล็กสุด ไม่แยกเงินทอน';

  @override
  String get deskSendAdvAll => '· เอาต์พุตทั้งหมด';

  @override
  String get deskSendAdvAllNoSplit => '· เอาต์พุตทั้งหมด ไม่แยกเงินทอน';

  @override
  String get deskSendAdvanced => 'ตัวเลือกการส่ง';

  @override
  String get deskSendAdvStrategy => 'วิธีเลือกเอาต์พุตของการส่งนี้';

  @override
  String get deskSendAdvSmallestText =>
      'ใช้เอาต์พุตเล็กให้น้อยที่สุด ยอดที่เหลือยังใช้ได้ระหว่างรอเงินทอนยืนยัน';

  @override
  String get deskSendAdvAllText =>
      'ใช้ทุกเอาต์พุตที่ใช้ได้และคืนเงินทอนเป็นเอาต์พุตเดียว ทุกอย่างถูกล็อกจนกว่าจะยืนยัน หลังจากนั้นจะมีเอาต์พุตน้อยลงแต่ใหญ่ขึ้น';

  @override
  String get deskSendDefaultTag => 'ค่าเริ่มต้น';

  @override
  String get deskSendAdvAllNote => 'การส่งยอดทั้งหมดจะใช้ทุกเอาต์พุต';

  @override
  String get deskSendAdvSplit => 'แยกเงินทอน';

  @override
  String get deskSendAdvSplitText =>
      'คืนเงินทอนเป็นหลายเอาต์พุตเมื่อจะเหลือน้อย เพื่อให้การส่งครั้งถัดไปไม่ต้องรอ';

  @override
  String get deskSendAdvDefaults => 'เฉพาะการส่งนี้ ค่าเริ่มต้น: ';

  @override
  String get deskSendAdvOutputsLink => 'เอาต์พุต';

  @override
  String get deskSendPickNone => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get deskSendPickNoneText =>
      'บันทึกคนที่จ่ายบ่อยไว้ในผู้ติดต่อ แล้วเลือกจากที่นี่';

  @override
  String get deskSendPickOpen => 'เปิดผู้ติดต่อ';

  @override
  String deskSendPickNoMatch(String query) {
    return 'ไม่มีผู้ติดต่อที่ตรงกับ “$query”';
  }

  @override
  String get deskSendPickTitle => 'เลือกผู้ติดต่อ';

  @override
  String get deskSendPickDesc => 'ที่อยู่จะถูกใส่ในช่องผู้รับ';

  @override
  String get deskSendPickSearch => 'ค้นหาผู้ติดต่อ';

  @override
  String get deskSendTitle => 'ส่ง';

  @override
  String get deskSendErrNoAddress => 'ใส่ที่อยู่ที่จะส่งไป';

  @override
  String get deskSendErrEpicbox => 'ไม่ใช่ที่อยู่ Epicbox ที่ถูกต้อง';

  @override
  String get deskSendErrNotDirect => 'ไม่ใช่ที่อยู่ลิงก์';

  @override
  String get deskSendErrOnion => 'ไม่ใช่ที่อยู่ onion ที่ถูกต้อง';

  @override
  String get deskSendErrOwn => 'นี่คือที่อยู่ของกระเป๋าเงินนี้เอง';

  @override
  String get deskSendNoAnswer => 'ผู้รับไม่ตอบ ไม่มีการส่งเงินออก';

  @override
  String get deskSendTorOnFailed => 'ไม่ได้เปิด Tor';

  @override
  String get deskSendTorOffFailed => 'ไม่ได้ปิด Tor';

  @override
  String get deskSendEpicboxOnFailed => 'ไม่ได้เปิด Epicbox';

  @override
  String get deskSendNothingSpendable => 'ไม่มียอดที่ใช้ได้ให้ส่ง';

  @override
  String get deskSendAllFailed =>
      'คำนวณยอดที่ส่งได้ไม่ได้ ลองอีกครั้งในอีกสักครู่';

  @override
  String get deskSendErrAmountEnter => 'ใส่จำนวน';

  @override
  String get deskSendErrAmountDecimals => 'EPIC มีทศนิยมได้ไม่เกิน 8 ตำแหน่ง';

  @override
  String get deskSendErrAmountZero => 'จำนวนต้องมากกว่า 0';

  @override
  String get deskSendErrAmountMore => 'มากกว่ายอดที่ใช้ได้';

  @override
  String get deskSendSent => 'ส่งแล้ว';

  @override
  String get deskSendFileReadyTitle => 'ไฟล์ธุรกรรมพร้อมแล้ว';

  @override
  String get deskSendFileReadyText =>
      'ให้ไฟล์นี้กับผู้รับ แล้วทำรายการให้เสร็จด้วยไฟล์ตอบกลับของผู้รับ';

  @override
  String get deskSendFinalize => 'ทำให้เสร็จ';

  @override
  String get deskSendNewSend => 'ส่งอีกรายการ';

  @override
  String get deskSendNodeNotSynced => 'โหนดยังไม่ซิงก์';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'การส่งจะกลับมาเมื่อโหนดซิงก์เสร็จ ($percent%)';
  }

  @override
  String get deskSendNodeSyncing => 'ส่งได้เมื่อโหนดซิงก์เสร็จ';

  @override
  String get deskSendTorBlocked => 'Tor ไม่ได้เชื่อมต่อ';

  @override
  String get deskSendTorBlockedText =>
      'จะไม่มีอะไรถูกส่งจนกว่า Tor จะเชื่อมต่อ หรือจนกว่าจะปิด Tor';

  @override
  String get deskSendTurnTorOff => 'ปิด Tor';

  @override
  String get deskSendTorStarting => 'Tor กำลังเริ่ม';

  @override
  String get deskSendTorStartingText => 'การส่งจะรอ Tor';

  @override
  String get deskSendEpicboxOff => 'Epicbox ไม่ได้เชื่อมต่อ';

  @override
  String get deskSendEpicboxOffText =>
      'เปิดการรับผ่าน Epicbox เพื่อส่งผ่าน Epicbox หรือใช้ โดยตรง · โอนไฟล์';

  @override
  String get deskSendEpicboxTurnOn => 'เปิดการรับผ่าน Epicbox';

  @override
  String get deskSendDoneViaDirect => 'ทำรายการเสร็จและส่งเข้าเครือข่ายแล้ว';

  @override
  String get deskSendDoneViaEpicbox =>
      'ส่งให้ Epicbox แล้ว จะสำเร็จเมื่อผู้รับตอบกลับ';

  @override
  String get deskSendViewTx => 'ดูรายการ';

  @override
  String get deskSendFailedTitle => 'ส่งไม่สำเร็จ';

  @override
  String get deskSendReviewAgain => 'ตรวจสอบอีกครั้ง';

  @override
  String get deskSendMethodDirect => 'ลิงก์';

  @override
  String get deskSendMethodFile => 'โดยตรง · ไฟล์';

  @override
  String get deskSendTo => 'ถึง';

  @override
  String get deskSendToHelp => 'วางที่อยู่ หรือพิมพ์ชื่อผู้ติดต่อ';

  @override
  String get deskSendToHint => 'ที่อยู่หรือผู้ติดต่อ';

  @override
  String get deskSendToSem => 'ผู้รับ';

  @override
  String get deskSendClearTo => 'ล้างผู้รับ';

  @override
  String get deskSendContacts => 'ผู้ติดต่อ';

  @override
  String get deskSendNeedsTor => 'Link · Tor ต้องใช้ Tor';

  @override
  String get deskSendNeedsTorText =>
      'ที่อยู่ onion เข้าถึงได้ผ่าน Tor เท่านั้น';

  @override
  String get deskSendNoTorBuild => 'รุ่นนี้ไม่มี Tor';

  @override
  String get deskSendTurnOnTor => 'เปิด Tor';

  @override
  String get deskSendHttpClearnet => 'ลิงก์ · HTTP ส่งตรง ไม่ผ่าน Tor';

  @override
  String get deskSendClear => 'ล้าง';

  @override
  String get deskSendAmount => 'จำนวน';

  @override
  String get deskSendAvailableNone => 'ใช้ได้ —';

  @override
  String deskSendAvailable(String amount) {
    return 'ใช้ได้ $amount EPIC';
  }

  @override
  String get deskSendAmountSem => 'จำนวนเป็น EPIC';

  @override
  String get deskSendAllButton => 'สูงสุด';

  @override
  String get deskSendConfirmingHidden =>
      'ยอดบางส่วนยังกำลังยืนยันและยังส่งไม่ได้';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC ยังกำลังยืนยันและยังส่งไม่ได้';
  }

  @override
  String get deskSendMessage => 'ข้อความ';

  @override
  String get deskSendMessageHelp => 'ผู้รับจะเห็นข้อความนี้';

  @override
  String get deskSendPrivacyOn => 'ความเป็นส่วนตัว · เปิด Dandelion++';

  @override
  String get deskSendPrivacyOff => 'ความเป็นส่วนตัว · ปิด Dandelion++';

  @override
  String get deskSendDandelionText =>
      'ส่งธุรกรรมผ่านโหนดสุ่มไม่กี่โหนดก่อนกระจายออกไป เครือข่ายจึงบอกไม่ได้ว่ามาจากไหน';

  @override
  String get deskSendHintSent => 'ส่งแล้ว';

  @override
  String get deskSendHintQueued =>
      'เข้าคิวแล้ว ใส่จำนวนและผู้รับใหม่เพื่อส่งอีกครั้ง';

  @override
  String get deskSendHintNode => 'รอโหนดซิงก์';

  @override
  String get deskSendHintEpicbox => 'รอ Epicbox เชื่อมต่อ';

  @override
  String get deskSendHintTorWait => 'รอ Tor เชื่อมต่อ';

  @override
  String get deskSendHintTorBlocked => 'ลอง Tor อีกครั้ง หรือปิด Tor';

  @override
  String get deskSendHintNeedsTor => 'เปิด Tor เพื่อส่งไปที่อยู่ onion';

  @override
  String get deskSendHintFix => 'แก้ช่องที่มีสีแดง';

  @override
  String get deskSendHintChecking => 'กำลังตรวจค่าธรรมเนียมของจำนวนนี้';

  @override
  String get deskSendHintDefault => 'ไม่มีการส่งจนกว่าจะยืนยัน';

  @override
  String get deskSendReviewWaitTor => 'รอ Tor';

  @override
  String get deskSendReviewTorOff => 'Tor ไม่ได้เชื่อมต่อ';

  @override
  String get deskSendReview => 'ตรวจสอบ';

  @override
  String get deskSendSummary => 'สรุป';

  @override
  String get deskSendNetworkFee => 'ค่าธรรมเนียม';

  @override
  String get deskSendTotal => 'รวม';

  @override
  String get deskSendUpdating => 'ยอดกำลังอัปเดตระหว่างกระเป๋าเงินสแกน';

  @override
  String get deskSendEpicboxLine1 => 'ผู้รับออฟไลน์อยู่ก็ได้';

  @override
  String get deskSendEpicboxLine2 =>
      'เซิร์ฟเวอร์ Epicbox จะเก็บรายการไว้จนกว่าผู้รับจะเปิดกระเป๋าเงิน';

  @override
  String get deskSendDirectLine1 => 'ตรงถึงกระเป๋าเงินผู้รับ';

  @override
  String get deskSendDirectLine2 =>
      'ที่อยู่ http(s) หรือ .onion กระเป๋าเงินของผู้รับต้องเปิดอยู่';

  @override
  String get deskSendFileLine1 => 'ไม่ต้องเชื่อมต่อ';

  @override
  String get deskSendFileLine2 =>
      'ส่งไฟล์ให้ผู้รับ รับไฟล์ตอบกลับคืนมา แล้วทำรายการให้เสร็จที่นี่';

  @override
  String get deskSendTagDirect => 'ลิงก์';

  @override
  String get deskSendTagFile => 'โดยตรง · ไฟล์';

  @override
  String get deskSendTagEpicbox => 'ผ่าน Epicbox';

  @override
  String get deskSendSwitchedDirect =>
      'ที่อยู่ลิงก์ ตั้งวิธีส่งเป็น ลิงก์ แล้ว';

  @override
  String get deskSendSwitchedFile =>
      'ที่อยู่แบบไฟล์ ตั้งวิธีส่งเป็น โดยตรง · ไฟล์ แล้ว';

  @override
  String get deskSendSwitchedEpicbox =>
      'ที่อยู่ Epicbox ตั้งวิธีส่งเป็น Epicbox แล้ว';

  @override
  String get deskSendMatching => 'ผู้ติดต่อที่ตรงกัน';

  @override
  String deskSendMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ผู้ติดต่อตรงกัน $count ราย',
    );
    return '$_temp0';
  }

  @override
  String get deskSendWrongPassword => 'รหัสผ่านไม่ถูกต้อง';

  @override
  String get deskSendNotConfirmed => 'ยังไม่ยืนยัน ตรวจประวัติก่อนส่งอีกครั้ง';

  @override
  String get deskSendViaEpicbox => 'Epicbox (ผู้รับออฟไลน์อยู่ก็ได้)';

  @override
  String get deskSendViaDirect =>
      'ลิงก์ · HTTP (กระเป๋าเงินของผู้รับต้องเปิดอยู่)';

  @override
  String get deskSendViaTor => 'ลิงก์ · Tor (กระเป๋าเงินของผู้รับต้องเปิดอยู่)';

  @override
  String get deskSendViaFile => 'ไฟล์ธุรกรรม';

  @override
  String deskSendUsesAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใช้ทั้ง $count เอาต์พุต · เงินทอน 1 เอาต์พุต',
    );
    return '$_temp0';
  }

  @override
  String get deskSendReviewTitle => 'ตรวจสอบและส่ง';

  @override
  String get deskSendReviewDesc => 'เมื่อส่งเข้าเครือข่ายแล้วจะย้อนกลับไม่ได้';

  @override
  String get deskSendFactTo => 'ถึง';

  @override
  String get deskSendCheckChars => 'เทียบตัวอักษรที่ไฮไลต์กับที่ผู้รับให้มา';

  @override
  String get deskSendFactVia => 'ผ่าน';

  @override
  String get deskSendFactPrivacy => 'ความเป็นส่วนตัว';

  @override
  String get deskSendDandelionOn => 'เปิด Dandelion++';

  @override
  String get deskSendDandelionOff => 'ปิด Dandelion++';

  @override
  String get deskSendFactMessage => 'ข้อความ';

  @override
  String get deskSendPassword => 'รหัสผ่าน';

  @override
  String get deskSendPasswordHelp => 'ทุกการส่งต้องใส่รหัสผ่านกระเป๋าเงิน';

  @override
  String get deskSendBusyFile => 'กำลังสร้างไฟล์';

  @override
  String get deskSendBusyTor =>
      'กำลังติดต่อกระเป๋าเงินของผู้รับผ่าน Tor… อาจใช้เวลาสักพัก เปิดแอปไว้';

  @override
  String get deskSendBusy =>
      'กำลังส่ง อาจใช้เวลาไม่กี่วินาที เปิดหน้าต่างนี้ไว้';

  @override
  String get deskSendBack => 'ย้อนกลับ';

  @override
  String get deskSendSending => 'กำลังส่ง';

  @override
  String deskSendConfirm(String amount) {
    return 'ส่ง $amount EPIC';
  }

  @override
  String get deskSendPlainTitle => 'ไม่ได้เข้ารหัส ส่งเลยไหม?';

  @override
  String get deskSendPlainDesc =>
      'HTTP ธรรมดาไปยังคอมพิวเตอร์อื่น ใครที่อยู่ระหว่างทางก็อ่านธุรกรรมได้ https:// เข้ารหัส';

  @override
  String get deskSendPlainConfirm => 'ส่งเลย';

  @override
  String deskSendEpicboxSwitched(String domain) {
    return 'เปลี่ยนเป็น $domain แล้ว';
  }

  @override
  String get deskSendEpicboxNotSwitched => 'ไม่ได้เปลี่ยน';

  @override
  String get deskSendEpicboxDownTitle => 'เซิร์ฟเวอร์ Epicbox ไม่ตอบสนอง';

  @override
  String get deskSendEpicboxDownWait => 'รายการจะรอจนกว่าเซิร์ฟเวอร์จะกลับมา';

  @override
  String deskSendEpicboxSwitchTo(String domain) {
    return 'เปลี่ยนเป็น $domain ไหม?';
  }

  @override
  String get deskSendEpicboxSwitch => 'เปลี่ยน';

  @override
  String get deskFinOpenFolder => 'เปิดโฟลเดอร์';

  @override
  String get deskFinFolderNotOpened => 'เปิดโฟลเดอร์ไม่ได้';

  @override
  String get deskFinWrongType => 'ไม่ใช่ไฟล์ตอบกลับ';

  @override
  String get deskFinWrongTypeText =>
      'ไฟล์นี้ไม่ใช่ไฟล์ตอบกลับ เลือกไฟล์ที่ผู้รับส่งคืนมา';

  @override
  String get deskFinUnreadable => 'อ่านไฟล์ไม่ได้';

  @override
  String get deskFinUnreadableText =>
      'อ่านไฟล์ไม่ได้ ไฟล์อาจเสียหายหรือยังคัดลอกไม่เสร็จ';

  @override
  String get deskFinFailed => 'ทำรายการให้เสร็จไม่สำเร็จ';

  @override
  String get deskFinFailedText =>
      'กระเป๋าเงินทำไฟล์นี้ให้เสร็จไม่ได้ ไฟล์อาจเป็นของธุรกรรมอื่น หรือทำเสร็จไปแล้ว';

  @override
  String get deskFinNotPosted => 'ไม่ได้ส่งเข้าเครือข่าย';

  @override
  String get deskFinNotPostedText =>
      'ทำธุรกรรมเสร็จแล้วแต่โหนดไม่รับ ตรวจโหนดแล้วลองอีกครั้ง';

  @override
  String get deskFinPickTitle => 'ไฟล์ตอบกลับ';

  @override
  String get deskFinPosted => 'ส่งรายการเข้าเครือข่ายแล้ว';

  @override
  String get deskFinTitle => 'ทำรายการให้เสร็จด้วยไฟล์ตอบกลับ';

  @override
  String get deskFinNoticeTitle => 'สำหรับการชำระด้วยไฟล์';

  @override
  String get deskFinNoticeText => 'ใช้ไฟล์ตอบกลับที่ผู้รับส่งคืนมา';

  @override
  String get deskFinTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskFinPostedText =>
      'ทำรายการเสร็จและส่งเข้าเครือข่ายแล้ว ติดตามได้ในประวัติ';

  @override
  String get deskFinAnother => 'ทำไฟล์อื่นให้เสร็จ';

  @override
  String get deskFinViewActivity => 'ดูในประวัติ';

  @override
  String get deskFinBusy => 'กำลังทำให้เสร็จและส่งเข้าเครือข่าย';

  @override
  String get deskFinChoose => 'เลือกไฟล์ตอบกลับ';

  @override
  String get deskFinChooseText =>
      'กระเป๋าเงินจะทำธุรกรรมให้เสร็จและส่งเข้าเครือข่าย';

  @override
  String get deskFinChooseFile => 'เลือกไฟล์';

  @override
  String get deskImpWrongType => 'ไม่ใช่ไฟล์ธุรกรรม';

  @override
  String get deskImpWrongTypeText =>
      'ไม่ใช่ไฟล์ธุรกรรม เลือกไฟล์ .tx ที่ผู้ส่งให้มา';

  @override
  String get deskImpUnreadable => 'อ่านไฟล์ไม่ได้';

  @override
  String get deskImpUnreadableText =>
      'อ่านไฟล์ไม่ได้ ไฟล์อาจเสียหายหรือยังคัดลอกไม่เสร็จ';

  @override
  String get deskImpNoPlace => 'ไม่ได้ลงนาม';

  @override
  String get deskImpNoPlaceText =>
      'ไม่ได้เลือกที่เก็บไฟล์ตอบกลับ จึงไม่ได้ลงนาม';

  @override
  String get deskImpFailed => 'ลงนามไม่สำเร็จ';

  @override
  String get deskImpFailedText =>
      'กระเป๋าเงินลงนามไฟล์นี้ไม่ได้ ไฟล์อาจเป็นของกระเป๋าเงินอื่น หรือใช้ไปแล้ว';

  @override
  String deskImpFailedDetail(String detail) {
    return 'กระเป๋าเงินลงนามไฟล์นี้ไม่ได้ ไฟล์อาจเป็นของกระเป๋าเงินอื่น หรือใช้ไปแล้ว $detail';
  }

  @override
  String get deskImpPickTitle => 'ไฟล์ธุรกรรม';

  @override
  String get deskImpTitle => 'ลงนามไฟล์ธุรกรรม';

  @override
  String get deskImpNoticeTitle => 'การลงนามไม่ได้ใช้เงิน';

  @override
  String get deskImpNoticeText =>
      'ส่งไฟล์ตอบกลับคืนให้ผู้ส่งผ่านช่องทางเดียวกับที่เขาใช้';

  @override
  String get deskImpSaved => 'บันทึกไฟล์ตอบกลับแล้ว';

  @override
  String get deskImpSavedText =>
      'ส่งไฟล์ตอบกลับคืนให้ผู้ส่ง EPIC จะเข้าเมื่อผู้ส่งทำรายการให้เสร็จ';

  @override
  String get deskImpAmount => 'จำนวน ';

  @override
  String get deskImpAnother => 'ลงนามไฟล์อื่น';

  @override
  String get deskImpBusy => 'กำลังลงนามไฟล์';

  @override
  String get deskImpChoose => 'เลือกไฟล์ธุรกรรม';

  @override
  String get deskImpChooseText =>
      'กระเป๋าเงินจะลงนามและบันทึกไฟล์ตอบกลับให้ผู้ส่ง';

  @override
  String get deskActNotUpdated => 'ไม่ได้อัปเดต';

  @override
  String get deskActSearchHint => 'บันทึก ผู้ติดต่อ ที่อยู่ หรือจำนวน';

  @override
  String get deskActSearchHintEmpty => 'ยังไม่มีอะไรให้ค้นหา';

  @override
  String get deskActSearchLabel => 'ค้นหารายการ';

  @override
  String get deskActClearSearch => 'ล้างการค้นหา';

  @override
  String get deskActShowAmounts => 'แสดงจำนวน';

  @override
  String get deskActHideAmounts => 'ซ่อนจำนวน';

  @override
  String get deskActRefresh => 'รีเฟรช';

  @override
  String get deskActTitle => 'ประวัติ';

  @override
  String get deskActDetailReceived => 'การชำระเงินที่ได้รับ';

  @override
  String get deskActDetailSent => 'การชำระเงินที่ส่ง';

  @override
  String get deskActLoading => 'กำลังโหลดรายการ';

  @override
  String get deskActWaitingNode => 'รอโหนดซิงก์';

  @override
  String get deskActFilterAll => 'ทั้งหมด';

  @override
  String get deskActFilterReceived => 'รับ';

  @override
  String get deskActFilterSent => 'ส่ง';

  @override
  String deskActNoMatchTitle(String query) {
    return 'ไม่พบรายการที่ตรงกับ “$query”';
  }

  @override
  String deskActPageOf(int page, int pages) {
    return 'หน้า $page จาก $pages';
  }

  @override
  String get deskActPrevPage => 'หน้าก่อน';

  @override
  String get deskActNextPage => 'หน้าถัดไป';

  @override
  String get deskActPages => 'หน้า';

  @override
  String get deskActColFromTo => 'จาก / ถึง';

  @override
  String get deskActColStatus => 'สถานะ';

  @override
  String get deskActColTime => 'เวลา';

  @override
  String get deskActColAmount => 'จำนวน';

  @override
  String get deskActEmptyTitle => 'ยังไม่มีการชำระเงิน';

  @override
  String get deskActEmptyText => 'รายการที่ส่งและรับ ใหม่สุดก่อน';

  @override
  String get deskActStageWaiting => 'รอ';

  @override
  String get deskActStageWaitingText =>
      'กระเป๋าเงินทั้งสองฝั่งลงนาม ผ่าน Epicbox จะทำให้เอง';

  @override
  String get deskActStageConfirming => 'กำลังยืนยัน';

  @override
  String get deskActStageConfirmingText =>
      'อยู่บนบล็อกเชน ประมาณหนึ่งบล็อกต่อนาที';

  @override
  String get deskActStageSpendable => 'ใช้ได้';

  @override
  String deskActStageSpendableText(int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'หลังยืนยันครบ $needed ครั้ง ประมาณ $needed นาที',
    );
    return '$_temp0';
  }

  @override
  String get deskActShowAddress => 'แสดงที่อยู่';

  @override
  String get deskActReceiveFile => 'รับไฟล์';

  @override
  String get deskConTitle => 'ผู้ติดต่อ';

  @override
  String get deskConLoading => 'กำลังโหลดผู้ติดต่อ';

  @override
  String get deskConNewTitle => 'ผู้ติดต่อใหม่';

  @override
  String get deskConEditTitle => 'แก้ไขผู้ติดต่อ';

  @override
  String get deskConDetailsTitle => 'รายละเอียด';

  @override
  String get deskConSearchHint => 'ชื่อหรือที่อยู่';

  @override
  String get deskConSearchLabel => 'ค้นหาผู้ติดต่อ';

  @override
  String get deskConClearSearch => 'ล้างการค้นหา';

  @override
  String deskConCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ผู้ติดต่อ $count ราย',
    );
    return '$_temp0';
  }

  @override
  String get deskConNoMatches => 'ไม่พบ';

  @override
  String deskConMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'พบ $count ราย',
    );
    return '$_temp0';
  }

  @override
  String get deskConSortName => 'ชื่อ';

  @override
  String get deskConSortRecent => 'ล่าสุด';

  @override
  String get deskConNone => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get deskConNoMatchList => 'ไม่มีผู้ติดต่อที่ตรงกัน';

  @override
  String get deskConAdd => 'เพิ่มผู้ติดต่อ';

  @override
  String get deskConIdle => 'เลือกผู้ติดต่อ';

  @override
  String get deskConEmptyTitle => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get deskConEmptyText =>
      'บันทึกคนและร้านค้าที่จ่ายบ่อย แล้วเลือกตามชื่อที่หน้า ส่ง';

  @override
  String get deskConEmptyLocal =>
      'ผู้ติดต่ออยู่บนคอมพิวเตอร์นี้ ส่งออกเพื่อเก็บสำเนา';

  @override
  String get deskConSendToAddress => 'ส่งไปยังที่อยู่';

  @override
  String deskConLastTx(String when) {
    return 'รายการล่าสุด: $when';
  }

  @override
  String get deskConSend => 'ส่ง';

  @override
  String get deskConEdit => 'แก้ไข';

  @override
  String get deskConStar => 'ติดดาว';

  @override
  String get deskConUnstar => 'เลิกติดดาว';

  @override
  String get deskConDelete => 'ลบ';

  @override
  String get deskConNotDeleted => 'ไม่ได้ลบ';

  @override
  String deskConDeleted(String name) {
    return 'ลบ $name แล้ว';
  }

  @override
  String get deskConNote => 'บันทึก';

  @override
  String deskConTxWith(String name) {
    return 'รายการกับ $name';
  }

  @override
  String get deskConAllTx => 'รายการทั้งหมด';

  @override
  String get deskConTxNone =>
      'ยังไม่มีรายการกับผู้ติดต่อนี้ รายการที่ส่งให้จากหน้า ส่ง จะแสดงที่นี่';

  @override
  String get deskConTxReceived => 'รับ';

  @override
  String get deskConTxSent => 'ส่ง';

  @override
  String get deskConErrName => 'ตั้งชื่อผู้ติดต่อ';

  @override
  String get deskConErrAddressEmpty => 'ใส่ที่อยู่';

  @override
  String get deskConErrAddressInvalid =>
      'ที่อยู่ไม่ถูกต้อง ใช้ที่อยู่ Epicbox (es5x…@เซิร์ฟเวอร์) ที่อยู่ลิงก์ (https://…) หรือที่อยู่ onion (….onion)';

  @override
  String get deskConAddPicture => 'เพิ่มรูป';

  @override
  String get deskConChangePicture => 'เปลี่ยนรูป';

  @override
  String get deskConRemovePicture => 'ลบ';

  @override
  String get deskConPictureHelp =>
      'PNG, JPEG, WebP หรือ GIF ไม่เกิน 10 MB แอปเก็บสำเนาขนาดเล็กไว้';

  @override
  String get deskConFieldName => 'ชื่อ';

  @override
  String get deskConFieldAddress => 'ที่อยู่';

  @override
  String get deskConSaveFailed => 'ไม่ได้บันทึกผู้ติดต่อ';

  @override
  String get deskConSave => 'บันทึกผู้ติดต่อ';

  @override
  String deskConDeleteTitle(String name) {
    return 'ลบ $name ไหม?';
  }

  @override
  String get deskConDeleteBody =>
      'ลบผู้ติดต่อ รายการที่ผ่านมายังอยู่ในประวัติ ย้อนกลับไม่ได้';

  @override
  String get deskConKeep => 'เก็บไว้';

  @override
  String get deskConDeleteAction => 'ลบผู้ติดต่อ';

  @override
  String get deskOutNotUpdated => 'ไม่ได้อัปเดต';

  @override
  String get deskOutTitle => 'เอาต์พุต';

  @override
  String get deskOutShowAmounts => 'แสดงจำนวน';

  @override
  String get deskOutHideAmounts => 'ซ่อนจำนวน';

  @override
  String get deskOutRefresh => 'รีเฟรช';

  @override
  String get deskOutLockedNote =>
      'เอาต์พุตที่ถูกล็อกกำลังถูกใช้โดยธุรกรรมที่ยังไม่เสร็จ เงินทอนของธุรกรรมนั้นแสดงเป็นรอทำรายการให้เสร็จ และยังไม่นับในยอดรวมจนกว่าการส่งจะเสร็จ ยอดรวมจึงนับเหรียญแค่ครั้งเดียว';

  @override
  String get deskOutIntro =>
      'เอาต์พุตคือชิ้นส่วนที่ประกอบเป็นยอดคงเหลือ การส่งจะใช้เอาต์พุตทั้งก้อนและคืนเงินทอนเป็นเอาต์พุตใหม่';

  @override
  String deskOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอาต์พุต',
    );
    return '$_temp0';
  }

  @override
  String deskOutCardWait(int blocks) {
    return 'รอจนกว่าการส่งจะได้รับการยืนยัน (ประมาณ $blocks บล็อก)';
  }

  @override
  String get deskOutSplitNothing => 'ยังไม่มีอะไรให้แยก';

  @override
  String deskOutSplitSpends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใช้ $count เอาต์พุต',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitSpendsFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใช้ $count เอาต์พุต ค่าธรรมเนียมเริ่มต้น $fee EPIC',
    );
    return '$_temp0';
  }

  @override
  String get deskOutConsNothing => 'ยังไม่มีอะไรให้รวม';

  @override
  String get deskOutConsOne => 'ไม่มีอะไรให้รวม: มีเอาต์พุตที่ใช้ได้เพียงหนึ่ง';

  @override
  String deskOutConsInto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอาต์พุต รวมเป็น 1',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsIntoFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอาต์พุต รวมเป็น 1 ค่าธรรมเนียม $fee EPIC',
    );
    return '$_temp0';
  }

  @override
  String get deskOutSplitCardTitle => 'แยก';

  @override
  String get deskOutSplitCardText =>
      'สร้างเอาต์พุตเพิ่มจากยอดที่ใช้ได้ เพื่อให้ส่งต่อกันหลายครั้งได้โดยไม่ต้องรอ';

  @override
  String get deskOutSplitCardButton => 'แยก…';

  @override
  String get deskOutConsCardTitle => 'รวม';

  @override
  String get deskOutConsCardText =>
      'รวมทุกเอาต์พุตที่ใช้ได้เป็นก้อนเดียว ค่าธรรมเนียมการส่งครั้งถัดไปจะถูกลง ทุกอย่างจะถูกล็อกจนกว่าจะได้รับการยืนยัน';

  @override
  String get deskOutConsCardButton => 'รวม…';

  @override
  String get deskOutNotLoadedTitle => 'โหลดเอาต์พุตไม่ได้';

  @override
  String get deskOutNotLoadedText => 'รีเฟรชเพื่อลองอีกครั้ง';

  @override
  String get deskOutLoading => 'กำลังโหลดข้อมูลกระเป๋าเงิน';

  @override
  String get deskOutNoneTitle => 'ยังไม่มีเอาต์พุต';

  @override
  String get deskOutNoneText => 'รายการแรกที่ได้รับจะสร้างเอาต์พุตขึ้น';

  @override
  String get deskOutFilterAll => 'ทั้งหมด';

  @override
  String get deskOutFilterSpendable => 'ใช้ได้';

  @override
  String get deskOutFilterConfirming => 'กำลังยืนยัน';

  @override
  String get deskOutFilterLocked => 'ถูกล็อก';

  @override
  String get deskOutSearchHint => 'Commitment';

  @override
  String get deskOutSearchLabel => 'ค้นหาเอาต์พุต';

  @override
  String get deskOutClearSearch => 'ล้างการค้นหา';

  @override
  String get deskOutShowSpent => 'แสดงที่ใช้ไปแล้ว';

  @override
  String get deskOutNoMatchTitle => 'ไม่มีเอาต์พุตที่ตรงกัน';

  @override
  String get deskOutNoMatchText => 'ลอง commitment อื่น หรือล้างตัวกรอง';

  @override
  String get deskOutClearFilter => 'ล้างตัวกรอง';

  @override
  String get deskOutTileSpendable => 'ใช้ได้';

  @override
  String get deskOutTileConfirming => 'กำลังยืนยัน';

  @override
  String get deskOutTileImmature => 'รอครบกำหนด';

  @override
  String get deskOutTileLocked => 'ล็อกในการส่ง';

  @override
  String get deskOutTileTotal => 'รวม';

  @override
  String get deskOutStrategyTitle => 'วิธีเลือกเอาต์พุตตอนส่ง';

  @override
  String get deskOutStrategySmallest => 'เล็กสุด';

  @override
  String get deskOutStrategyAll => 'ทั้งหมด';

  @override
  String get deskOutStrategyHelpTitle => 'เล็กสุด หรือ ทั้งหมด';

  @override
  String get deskOutSplitChangeTitle => 'แยกเงินทอน';

  @override
  String get deskOutSplitChangeText =>
      'เมื่อการส่งจะเหลือเอาต์พุตที่ใช้ได้น้อยกว่า 3 และเงินทอนมีอย่างน้อย 1 EPIC เงินทอนจะกลับมาเป็นเอาต์พุตได้ถึง 4 ก้อน ก้อนละอย่างน้อย 0.5 EPIC คิด 0.004 EPIC ต่อเอาต์พุตที่เพิ่ม';

  @override
  String get deskOutColValue => 'มูลค่า';

  @override
  String get deskOutColStatus => 'สถานะ';

  @override
  String get deskOutColConfirmations => 'การยืนยัน';

  @override
  String get deskOutColHeight => 'บล็อก';

  @override
  String get deskOutColTransaction => 'ธุรกรรม';

  @override
  String get deskOutColCommitment => 'Commitment';

  @override
  String get deskOutStatusSpendable => 'ใช้ได้';

  @override
  String get deskOutStatusConfirming => 'กำลังยืนยัน';

  @override
  String deskOutConfirmations(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ยืนยัน $number ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusAwaiting => 'รอทำรายการให้เสร็จ';

  @override
  String get deskOutNoteWaitingSender => 'รอผู้ส่ง';

  @override
  String get deskOutStatusUnpaid => 'ใบแจ้งหนี้ยังไม่ชำระ';

  @override
  String get deskOutNoteNotInBalance => 'ไม่นับในยอดคงเหลือ';

  @override
  String get deskOutStatusImmature => 'รอครบกำหนด';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อีก $number บล็อก',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusMining => 'การขุด';

  @override
  String get deskOutStatusLocked => 'ถูกล็อก';

  @override
  String deskOutNoteBySend(int id) {
    return 'โดยการส่ง #$id';
  }

  @override
  String get deskOutStatusSpent => 'ใช้ไปแล้ว';

  @override
  String deskOutTxReceived(String date) {
    return 'รับ $date';
  }

  @override
  String deskOutTxSent(String date) {
    return 'ส่ง $date';
  }

  @override
  String deskOutCopyCommitment(String short) {
    return 'คัดลอก commitment $short';
  }

  @override
  String deskOutSplitSpentPart(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เอาต์พุต ($amount EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitMadePart(int count, String amount) {
    return '$count เอาต์พุต ก้อนละประมาณ $amount EPIC';
  }

  @override
  String deskOutConsMadePart(String amount) {
    return 'เอาต์พุตเดียว $amount EPIC';
  }

  @override
  String deskOutSplitDialogText(String spent, String made, int blocks) {
    return 'ใช้ $spent และสร้าง $made ทุกอย่างที่ใช้ได้จะถูกล็อกจนครบ $blocks การยืนยัน';
  }

  @override
  String deskOutConsDialogText(String spent, String made, int blocks) {
    return 'ใช้ $spent และสร้าง $made ทุกอย่างที่ใช้ได้จะถูกล็อกจนครบ $blocks การยืนยัน';
  }

  @override
  String get deskOutFactFee => 'ค่าธรรมเนียม';

  @override
  String get deskOutFactEach => 'แต่ละเอาต์พุต';

  @override
  String deskOutFactAbout(String amount) {
    return 'ประมาณ $amount EPIC';
  }

  @override
  String get deskOutFactLocked => 'ถูกล็อก';

  @override
  String deskOutFactLockedValue(String amount, int blocks) {
    return '$amount EPIC ประมาณ $blocks บล็อก ไม่มีส่วนไหนใช้ได้ระหว่างนั้น';
  }

  @override
  String get deskOutMakeLabel => 'จำนวนเอาต์พุตที่จะสร้าง';

  @override
  String get deskOutMakeRange => '2 ถึง 10';

  @override
  String get deskOutStepperFewer => 'น้อยลง';

  @override
  String get deskOutStepperMore => 'มากขึ้น';

  @override
  String get deskOutFeeWorking => 'กำลังคำนวณค่าธรรมเนียม';

  @override
  String get deskOutNoEstimate => 'ประเมินไม่ได้';

  @override
  String get deskOutEachMin => 'แต่ละเอาต์พุตต้องมีอย่างน้อย 0.5 EPIC';

  @override
  String get deskOutNotEnoughFee => 'ไม่พอจ่ายค่าธรรมเนียม';

  @override
  String deskOutSplitInto(int count) {
    return 'แยกเป็น $count';
  }

  @override
  String get deskOutConsolidateButton => 'รวม';

  @override
  String get deskOutPostingSplit =>
      'กำลังสร้างและส่งการแยกเข้าเครือข่าย เปิดแอปไว้';

  @override
  String get deskOutPostingCons =>
      'กำลังสร้างและส่งการรวมเข้าเครือข่าย เปิดแอปไว้';

  @override
  String get deskOutSplitPosted => 'ส่งการแยกเข้าเครือข่ายแล้ว';

  @override
  String get deskOutConsPosted => 'ส่งการรวมเข้าเครือข่ายแล้ว';

  @override
  String deskOutSplitDoneText(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count เอาต์พุต ก้อนละประมาณ $amount EPIC กำลังยืนยัน ล็อกจนครบ $blocks การยืนยัน',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount, int blocks) {
    return 'เอาต์พุตเดียว $amount EPIC กำลังยืนยัน ล็อกจนครบ $blocks การยืนยัน';
  }

  @override
  String get deskOutNotPostedTitle => 'ไม่ได้ส่งเข้าเครือข่าย';

  @override
  String get deskOutNotPostedSplit =>
      'สร้างและเก็บการแยกไว้แล้ว แต่โหนดไม่รับ ส่งอีกครั้ง หรือยกเลิกเพื่อปลดล็อกเอาต์พุต';

  @override
  String get deskOutNotPostedCons =>
      'สร้างและเก็บการรวมไว้แล้ว แต่โหนดไม่รับ ส่งอีกครั้ง หรือยกเลิกเพื่อปลดล็อกเอาต์พุต';

  @override
  String get deskOutCancelSplit => 'ยกเลิกการแยก';

  @override
  String get deskOutCancelCons => 'ยกเลิกการรวม';

  @override
  String get deskOutPostAgain => 'ส่งอีกครั้ง';

  @override
  String get deskOutNotDoneTitle => 'ไม่สำเร็จ';

  @override
  String deskOutNotDoneText(String error) {
    return '$error เอาต์พุตไม่เปลี่ยนแปลง';
  }

  @override
  String get deskOutSomethingWrong => 'เกิดข้อผิดพลาด';

  @override
  String get deskOutTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskOutToastNotPosted => 'ไม่ได้ส่งเข้าเครือข่าย';

  @override
  String get deskOutToastNotCancelled => 'ไม่ได้ยกเลิก';

  @override
  String get deskOutSplitDialogTitle => 'แยกเอาต์พุต';

  @override
  String get deskOutConsDialogTitle => 'รวมเอาต์พุต';

  @override
  String get deskOutPostingDesc => 'กำลังส่ง';

  @override
  String get deskOutDoneDesc => 'เสร็จแล้ว';

  @override
  String get deskOutSplitDesc =>
      'เอาต์พุตมากขึ้น เพื่อให้ส่งต่อกันได้หลายครั้ง';

  @override
  String get deskOutConsDesc => 'เอาต์พุตเดียวแทนหลายก้อน';

  @override
  String deskOutNothingText(String what) {
    return 'ไม่มีอะไรให้รวม: กระเป๋าเงินมี$what';
  }

  @override
  String get deskOutWhatFewer => 'เอาต์พุตที่ใช้ได้น้อยกว่าสองก้อน';

  @override
  String get deskOutWhatOne => 'เอาต์พุตที่ใช้ได้เพียงก้อนเดียว';

  @override
  String get deskOvNotUpdated => 'ไม่ได้อัปเดต';

  @override
  String get deskOvNodeNotStarted => 'โหนดไม่เริ่มทำงาน';

  @override
  String get deskOvNodeAddrTitle => 'อัปเดตที่อยู่โหนดแล้ว';

  @override
  String deskOvNodeAddrText(String node, String old) {
    return 'ตอนนี้ใช้ $node แทน $old';
  }

  @override
  String get deskOvNodeIncompatTitle => 'เวอร์ชันโหนดใช้ไม่ได้';

  @override
  String deskOvNodeUrl(String url) {
    return 'โหนด: $url';
  }

  @override
  String get deskOvUsePublicNode => 'ใช้โหนดสาธารณะ';

  @override
  String get deskOvUseLocalNode => 'ใช้โหนดในเครื่อง';

  @override
  String get deskOvHide => 'ซ่อน';

  @override
  String deskOvCantReachNode(String url) {
    return 'เชื่อมต่อโหนดที่ $url ไม่ได้';
  }

  @override
  String get deskOvCantReachNodeText =>
      'ตรวจว่าโหนดทำงานและเข้าถึงได้ ยอดเงินอาจไม่เป็นปัจจุบันและการส่งหยุดไว้ก่อน';

  @override
  String get deskOvStarting => 'กำลังเริ่ม';

  @override
  String get deskOvStartNode => 'เริ่มโหนด';

  @override
  String get deskOvNodeSettings => 'การตั้งค่าโหนด';

  @override
  String get deskOvTitle => 'ภาพรวม';

  @override
  String get deskOvShowAmounts => 'แสดงจำนวน';

  @override
  String get deskOvHideAmounts => 'ซ่อนจำนวน';

  @override
  String get deskOvRefresh => 'รีเฟรช';

  @override
  String get deskOvStepDone => 'เสร็จแล้ว';

  @override
  String get deskOvStepNow => 'กำลังดำเนินการ';

  @override
  String get deskOvStepWait => 'รอ';

  @override
  String deskOvStepSemantics(String text, String state) {
    return '$text, $state';
  }

  @override
  String get deskOvStartingUp => 'กำลังเริ่มต้น';

  @override
  String get deskOvStepUnlocked => 'ปลดล็อกกระเป๋าเงินแล้ว';

  @override
  String get deskOvStepConnected => 'เชื่อมต่อโหนดแล้ว';

  @override
  String get deskOvStepUpdating => 'กำลังอัปเดตยอดเงิน';

  @override
  String get deskOvStepEpicbox => 'กำลังเริ่มรับผ่าน Epicbox';

  @override
  String deskOvSyncTitle(int percent) {
    return 'โหนดกำลังซิงก์: $percent%';
  }

  @override
  String get deskOvSyncText =>
      'กำลังดาวน์โหลดบล็อก การส่งจะกลับมาเมื่อโหนดซิงก์เสร็จ';

  @override
  String get deskOvSyncProgress => 'ความคืบหน้าการซิงก์โหนด';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent% ของบล็อกเชน';
  }

  @override
  String get deskOvReceiveEpic => 'รับ EPIC';

  @override
  String get deskOvSend => 'ส่ง';

  @override
  String get deskOvReceive => 'รับ';

  @override
  String get deskOvSendWaits => 'การส่งจะกลับมาเมื่อโหนดซิงก์เสร็จ';

  @override
  String get deskOvAvailable => 'ยอดที่ใช้ได้';

  @override
  String deskOvAsOfBlock(String block) {
    return 'ณ บล็อก $block';
  }

  @override
  String get deskOvEmptyHint => 'แชร์ที่อยู่ Epicbox เพื่อรับ EPIC ครั้งแรก';

  @override
  String get deskOvFiatNote => '  ยอดทั้งหมด, CoinGecko';

  @override
  String get deskOvBreakTotal => 'รวม';

  @override
  String get deskOvBreakConfirming => 'กำลังยืนยัน';

  @override
  String get deskOvBreakImmature => 'รอครบกำหนด';

  @override
  String get deskOvBreakAwaiting => 'รอผู้ส่ง';

  @override
  String get deskOvBreakLocked => 'ล็อกในการส่ง';

  @override
  String get deskOvUpdating => 'กำลังอัปเดต';

  @override
  String get deskOvHiddenAmount => 'จำนวนที่ซ่อนไว้';

  @override
  String get deskOvLoading => 'กำลังโหลดรายการ';

  @override
  String get deskOvEmptyTitle => 'ยังไม่มีการชำระเงิน';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'EPIC ที่ได้รับจะแสดงเป็นกำลังยืนยันก่อน แล้วจึงใช้ได้หลัง $blocks การยืนยัน',
    );
    return '$_temp0';
  }

  @override
  String get deskOvShowAddress => 'แสดงที่อยู่';

  @override
  String get deskOvReceiveFile => 'รับไฟล์';

  @override
  String get deskOvRecent => 'รายการล่าสุด';

  @override
  String deskOvViewAll(int count) {
    return 'ดูทั้งหมด $count';
  }

  @override
  String deskOvPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'การชำระด้วยไฟล์รอทำให้เสร็จ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => 'ทำรายการให้เสร็จด้วยไฟล์ตอบกลับจากผู้รับ';

  @override
  String get deskOvFinalize => 'ทำให้เสร็จ';

  @override
  String get deskTxMethodFile => 'โดยตรง · ไฟล์';

  @override
  String get deskTxMiningReward => 'รางวัลการขุด';

  @override
  String get deskTxReceived => 'รับ';

  @override
  String get deskTxSent => 'ส่ง';

  @override
  String get deskTxUnknownSender => 'ไม่ทราบผู้ส่ง';

  @override
  String get deskTxUnknownRecipient => 'ไม่ทราบผู้รับ';

  @override
  String get deskTxNoteBlock => 'เวลาของบล็อก ไม่มีบันทึกผู้ส่ง';

  @override
  String get deskTxNoteScanTime =>
      'เวลาที่สแกน อ่านเวลาของบล็อกไม่ได้ ไม่มีบันทึกผู้ส่ง';

  @override
  String get deskTxNoteUnknown => 'ไม่มีบันทึกผู้ส่ง';

  @override
  String get deskTxFoundRestoredLabel => 'กู้คืน';

  @override
  String get deskTxFoundRestoredLine => 'พบระหว่างกู้คืน';

  @override
  String get deskTxFoundRestoredStep => 'พบระหว่างกู้คืนกระเป๋าเงินนี้';

  @override
  String get deskTxFoundRestoredTip =>
      'พบบนบล็อกเชนระหว่างกู้คืนกระเป๋าเงินนี้ ไม่มีบันทึกผู้ส่ง';

  @override
  String get deskTxFoundRescanLabel => 'พบจากการตรวจยอดใหม่';

  @override
  String get deskTxFoundRescanLine => 'พบจากการตรวจยอดใหม่';

  @override
  String get deskTxFoundRescanStep => 'พบจากการตรวจยอดใหม่';

  @override
  String get deskTxFoundRescanTip =>
      'พบบนบล็อกเชนจากการตรวจยอดใหม่ ไม่มีบันทึกผู้ส่ง';

  @override
  String get deskTxFoundScanLine => 'พบจากการสแกน';

  @override
  String get deskTxFoundScanStep => 'พบจากการสแกน';

  @override
  String get deskTxFoundScanTip => 'พบบนบล็อกเชนจากการสแกน ไม่มีบันทึกผู้ส่ง';

  @override
  String get deskTxBackupTip => 'นำเข้าจากไฟล์ข้อมูลกระเป๋าเงิน';

  @override
  String get deskTxFromBackup => 'นำเข้าแล้ว';

  @override
  String get deskTxStatusImmature => 'รอครบกำหนด';

  @override
  String get deskTxStatusWaitingSender => 'รอผู้ส่ง';

  @override
  String get deskTxStatusWaitingResponseFile => 'รอไฟล์ตอบกลับ';

  @override
  String get deskTxStatusWaitingRecipient => 'รอผู้รับ';

  @override
  String get deskTxStatusWaitingBlock => 'รอเข้าบล็อก';

  @override
  String deskTxStatusConfirming(int confirmations, int needed) {
    return 'กำลังยืนยัน $confirmations/$needed';
  }

  @override
  String get deskTxStatusCancelled => 'ยกเลิกแล้ว';

  @override
  String get deskTxToday => 'วันนี้';

  @override
  String get deskTxYesterday => 'เมื่อวาน';

  @override
  String deskTxDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วันที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskTxTodayAt(String time) {
    return 'วันนี้ $time';
  }

  @override
  String deskTxDayToday(String date) {
    return 'วันนี้ · $date';
  }

  @override
  String deskTxDayYesterday(String date) {
    return 'เมื่อวาน · $date';
  }

  @override
  String deskTxFee(String amount) {
    return 'ค่าธรรมเนียม $amount';
  }

  @override
  String get deskTxPaymentProof => 'หลักฐานการชำระเงิน';

  @override
  String get deskTxFinalize => 'ทำให้เสร็จ';

  @override
  String deskTxSemReceived(String amount, String who, String status) {
    return 'รับ $amount, $who, $status';
  }

  @override
  String deskTxSemSent(String amount, String who, String status) {
    return 'ส่ง $amount, $who, $status';
  }

  @override
  String deskTxSemKind(String kind, String amount, String who, String status) {
    return '$kind $amount, $who, $status';
  }

  @override
  String get deskTxHiddenAmount => 'จำนวนที่ซ่อนไว้';

  @override
  String get deskTxNowBackup =>
      'นำเข้าจากไฟล์ข้อมูลกระเป๋าเงิน ยังไม่ได้ตรวจสถานะบนเชน';

  @override
  String deskTxNowImmature(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ยืนยันแล้ว แต่รางวัลการขุดใช้ได้หลังยืนยันครบ $countString ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender => 'รอให้ผู้ส่งส่งรายการเข้าเครือข่าย';

  @override
  String get deskTxNowWaitingResponseFile =>
      'รอไฟล์ตอบกลับ ทำรายการให้เสร็จเมื่อได้รับ';

  @override
  String get deskTxNowWaitingRecipient =>
      'รอผู้รับลงนาม ไม่มีเงินออกจากกระเป๋าเงินจนกว่าจะทำรายการเสร็จ';

  @override
  String get deskTxNowPosted => 'ส่งเข้าเครือข่ายแล้ว รอเข้าบล็อก';

  @override
  String deskTxNowConfirming(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'อยู่ในบล็อก ยืนยันแล้ว $confirmations จาก $needed ครั้ง',
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
      other: 'ยืนยันแล้ว $confirmationsString ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'ยกเลิกแล้ว';

  @override
  String get deskTxNotCancelled => 'ไม่ได้ยกเลิก';

  @override
  String get deskTxCancelled => 'ยกเลิกธุรกรรมแล้ว';

  @override
  String get deskTxCancelling => 'กำลังยกเลิก';

  @override
  String get deskTxHeadRestored => 'กู้คืน';

  @override
  String get deskTxHeadFoundOnChain => 'พบบนบล็อกเชน';

  @override
  String get deskTxHeadBackup => 'นำเข้าจากไฟล์ข้อมูลกระเป๋าเงิน';

  @override
  String deskTxHeadFrom(String who) {
    return 'จาก $who';
  }

  @override
  String deskTxHeadTo(String who) {
    return 'ถึง $who';
  }

  @override
  String get deskTxSubProgress => 'ความคืบหน้า';

  @override
  String get deskTxSubDetails => 'รายละเอียด';

  @override
  String get deskTxFactDate => 'วันที่';

  @override
  String get deskTxFactFrom => 'จาก';

  @override
  String get deskTxFactTo => 'ถึง';

  @override
  String get deskTxCopyAddress => 'คัดลอกที่อยู่';

  @override
  String get deskTxFactMethod => 'วิธีส่ง';

  @override
  String get deskTxFactAmount => 'จำนวน';

  @override
  String get deskTxFactFee => 'ค่าธรรมเนียม';

  @override
  String get deskTxFactTotal => 'รวม';

  @override
  String get deskTxFactMessage => 'ข้อความ';

  @override
  String get deskTxSignedByRecipient => 'ผู้รับลงนามแล้ว';

  @override
  String get deskTxProofView => 'ดู';

  @override
  String get deskTxTechTitle => 'รายละเอียดทางเทคนิค';

  @override
  String get deskTxTechId => 'ID';

  @override
  String get deskTxTechSlate => 'Slate ID';

  @override
  String get deskTxCopySlate => 'คัดลอก Slate ID';

  @override
  String get deskTxTechHeight => 'บล็อก';

  @override
  String get deskTxTechKernel => 'Kernel';

  @override
  String get deskTxTechConfirmed => 'ยืนยันเมื่อ';

  @override
  String get deskTxTechCredited => 'เข้า';

  @override
  String get deskTxTechDebited => 'ออก';

  @override
  String get deskTxTechStatus => 'สถานะ';

  @override
  String get deskTxTechType => 'ประเภท';

  @override
  String get deskTxStepMined => 'ขุดได้ในบล็อก';

  @override
  String get deskTxStepSpendable => 'สำเร็จ';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อีก $count บล็อก',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'ได้รับเงินแล้ว';

  @override
  String get deskTxStepCreated => 'เริ่มรายการแล้ว';

  @override
  String get deskTxStepSignedReturned => 'ลงนามและส่งคืนแล้ว';

  @override
  String get deskTxStepWaitingFile => 'รอไฟล์ตอบกลับ';

  @override
  String get deskTxStepWaitingRecipient => 'รอผู้รับ';

  @override
  String get deskTxStepPosted => 'ส่งเข้าเครือข่ายแล้ว';

  @override
  String get deskTxStepConfirming => 'กำลังยืนยัน';

  @override
  String deskTxStepProgress(int confirmations, int needed) {
    return '$confirmations จาก $needed';
  }

  @override
  String get deskTxCancelIncomingTitle => 'ยกเลิกรายการนี้ไหม?';

  @override
  String get deskTxCancelOutgoingTitle => 'ยกเลิกรายการนี้ไหม?';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '$amount EPIC จาก $who จะออกจากยอดคงเหลือ กระเป๋าเงินจะถามโหนดก่อน และไม่ยกเลิกถ้ารายการอยู่ใน pool ของโหนดหรืออยู่ในบล็อกแล้ว ถ้าผู้ส่งเผยแพร่ภายหลัง รายการจะยังเข้า';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC ถึง $who ยังไม่มีการจ่ายใด ๆ การยกเลิกไม่มีค่าธรรมเนียมและแน่นอน';
  }

  @override
  String get deskTxCancelKeep => 'เก็บไว้';

  @override
  String get deskTxCancelIncomingAction => 'ยกเลิกรายการ';

  @override
  String get deskTxCancelOutgoingAction => 'ยกเลิกรายการ';

  @override
  String deskTxProofIncoming(String amount) {
    return 'พิสูจน์ว่ากระเป๋าเงินนี้ได้รับ $amount EPIC ใน kernel นี้';
  }

  @override
  String deskTxProofOutgoing(String amount) {
    return 'พิสูจน์ว่าผู้รับได้รับ $amount EPIC ใน kernel นี้';
  }

  @override
  String get deskTxProofSenderAddress => 'ที่อยู่ผู้ส่ง';

  @override
  String get deskTxProofRecipientAddress => 'ที่อยู่ผู้รับ';

  @override
  String get deskTxProofRecipientSignature => 'ลายเซ็นผู้รับ';

  @override
  String get deskTxProofCopyKernel => 'คัดลอก kernel';

  @override
  String get deskTxProofCopySender => 'คัดลอกที่อยู่ผู้ส่ง';

  @override
  String get deskTxProofCopyRecipient => 'คัดลอกที่อยู่ผู้รับ';

  @override
  String get deskTxProofCopySignature => 'คัดลอกลายเซ็นผู้รับ';

  @override
  String get deskTxProofExport => 'ส่งออก';

  @override
  String get deskTxProofSaved => 'บันทึกหลักฐานแล้ว';

  @override
  String get deskOnbWelcomeAdd => 'เพิ่มกระเป๋าเงิน';

  @override
  String get deskOnbWelcomeTagline =>
      'คีย์และเหรียญอยู่บนคอมพิวเตอร์นี้ ล็อกด้วยรหัสผ่าน';

  @override
  String get deskOnbWelcomeCreate => 'สร้างกระเป๋าเงินใหม่';

  @override
  String get deskOnbWelcomeCreateSub => 'วลีกู้คืนใหม่';

  @override
  String get deskOnbWelcomeImport => 'นำเข้ากระเป๋าเงิน';

  @override
  String get deskOnbWelcomeImportSub => 'จาก Epic Wallet รุ่นเก่าหรือโฟลเดอร์';

  @override
  String get deskOnbWelcomeRestore => 'กู้คืนจากวลีกู้คืน';

  @override
  String get deskOnbWelcomeRestoreSub => 'จากวลีกู้คืน';

  @override
  String get deskOnbWelcomeTestNote =>
      'กระเป๋าเงินใหม่จะสร้างบนเครือข่ายทดสอบนี้';

  @override
  String get deskOnbWelcomeBack => 'กลับไปปลดล็อก';

  @override
  String get deskOnbWelcomeAdvanced => 'ขั้นสูง';

  @override
  String get deskOnbWelcomeNetwork => 'เครือข่าย';

  @override
  String get deskOnbWelcomeFolder => 'โฟลเดอร์ข้อมูลแอป';

  @override
  String get deskOnbWelcomeHideDetails => 'ซ่อนรายละเอียด';

  @override
  String get deskOnbWelcomeMoreAbout => 'ข้อมูลเพิ่มเติม';

  @override
  String get deskOnbWelcomeFolderWhere => 'ที่แอปเก็บกระเป๋าเงินและการตั้งค่า';

  @override
  String get deskOnbWelcomeFolderDetail =>
      'ถ้าใช้โหนดในเครื่อง บล็อกเชนจะเก็บที่นี่ด้วย โฟลเดอร์ใหม่ต้องว่าง: แอปจะสร้างโฟลเดอร์ของตัวเองที่นั่นและใช้ต่อไป';

  @override
  String deskOnbWelcomeUsing(String folder) {
    return 'ใช้ $folder แอปจะเริ่มใหม่เพื่อใช้โฟลเดอร์นี้';
  }

  @override
  String get deskOnbWelcomeLocked => 'เปลี่ยนได้เฉพาะก่อนเพิ่มกระเป๋าเงินแรก';

  @override
  String get deskOnbWelcomeChooseFolder => 'เลือกโฟลเดอร์';

  @override
  String get deskOnbWelcomeDefaultFolder => 'โฟลเดอร์ค่าเริ่มต้น';

  @override
  String get deskOnbWelcomeFolderNotEmpty =>
      'โฟลเดอร์นั้นไม่ว่าง เลือกโฟลเดอร์ใหม่ที่ว่าง';

  @override
  String get deskOnbWelcomeFolderIsWallet =>
      'นั่นคือโฟลเดอร์กระเป๋าเงิน เลือกโฟลเดอร์ใหม่ที่ว่าง';

  @override
  String get deskOnbWelcomeChoose => 'เลือก';

  @override
  String get deskOnbStepPassword => 'รหัสผ่าน';

  @override
  String get deskOnbStepPhrase => 'วลีกู้คืน';

  @override
  String get deskOnbCreateStageCreate => 'กำลังสร้างวลีกู้คืน';

  @override
  String get deskOnbCreateStageSave => 'กำลังบันทึกกระเป๋าเงิน';

  @override
  String get deskOnbCreateNotCreated => 'ไม่ได้สร้างกระเป๋าเงิน';

  @override
  String get deskOnbCreateCreating => 'กำลังสร้างกระเป๋าเงิน';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'กระเป๋าเงินบน $network ซึ่งเป็นเครือข่ายทดสอบ';
  }

  @override
  String get deskOnbCreateDiskFull =>
      'บันทึกกระเป๋าเงินไม่ได้: ดิสก์เต็ม เพิ่มพื้นที่ว่างแล้วลองอีกครั้ง';

  @override
  String get deskOnbCreateWait => 'อาจใช้เวลาถึงหนึ่งนาที เปิดแอปไว้';

  @override
  String get deskOnbCreateLocking => 'กำลังล็อกกระเป๋าเงินที่เปิดอยู่';

  @override
  String get deskOnbCreateSide => 'กระเป๋าเงินใหม่';

  @override
  String get deskOnbCreateTitle => 'สร้างกระเป๋าเงิน';

  @override
  String get deskOnbCreateLead =>
      'รหัสผ่านใช้ปลดล็อกกระเป๋าเงินนี้บนคอมพิวเตอร์นี้ มีเพียงวลีกู้คืนที่กู้เหรียญคืนได้';

  @override
  String get deskOnbCreateTestNote =>
      'กระเป๋าเงินบนเครือข่ายทดสอบ ไม่ใช่สำหรับ EPIC จริง';

  @override
  String get deskOnbCreatePhraseLead =>
      'จดคำเหล่านี้ลงกระดาษตามลำดับ: เป็นทางเดียวที่จะกู้เหรียญคืน';

  @override
  String get deskOnbCreateRevealFirst => 'แสดงวลีก่อน';

  @override
  String get deskOnbCreateWarn => 'ใครมีคำเหล่านี้ก็เอาเหรียญไปได้';

  @override
  String get deskOnbCreateReveal => 'แสดงวลี';

  @override
  String get deskOnbCreateCheckScreen => 'ตรวจดูว่าไม่มีใครเห็นหน้าจอ';

  @override
  String get deskOnbCreateHide => 'ซ่อน';

  @override
  String get deskOnbCreateShowQr => 'แสดง QR';

  @override
  String get deskOnbCreateHideQr => 'ซ่อน QR Code';

  @override
  String get deskOnbCreateQrWarn => 'ใครสแกนโค้ดนี้ก็เอาเหรียญไปได้';

  @override
  String get deskOnbCreateQrWarnText =>
      'สแกนเข้ากระเป๋าเงินอื่นที่ไว้ใจเท่านั้น';

  @override
  String get deskOnbCreateQrLabel => 'วลีกู้คืนเป็น QR Code';

  @override
  String deskOnbCreateWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คำ',
    );
    return 'ฉันจดครบทั้ง $_temp0 แล้ว';
  }

  @override
  String get deskOnbRestoreDone => 'กู้คืนกระเป๋าเงินแล้ว';

  @override
  String get deskOnbRestoreNotRestored => 'ไม่ได้กู้คืนกระเป๋าเงิน';

  @override
  String get deskOnbRestoreRestoring => 'กำลังกู้คืนกระเป๋าเงิน';

  @override
  String get deskOnbRestorePermission =>
      'เขียนไฟล์กระเป๋าเงินไม่ได้: ไม่มีสิทธิ์ใน ~/.config/Epic Cash Desktop อนุญาตให้เขียนลงโฟลเดอร์นั้น แล้วลองอีกครั้ง';

  @override
  String get deskOnbRestoreWait =>
      'อาจใช้เวลาถึงหนึ่งนาที ยอดคงเหลือจะแสดงหลังสแกนบล็อกเชนครั้งแรก';

  @override
  String get deskOnbRestoreSide => 'กู้คืนกระเป๋าเงิน';

  @override
  String get deskOnbRestorePasswordLead =>
      'ตั้งรหัสผ่านที่ใช้ปลดล็อกกระเป๋าเงินนี้บนคอมพิวเตอร์นี้';

  @override
  String get deskOnbRestoreNothingToPaste =>
      'ไม่มีอะไรให้วาง: คลิปบอร์ดไม่มีคำ';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return 'คำที่ $position “$word” ไม่อยู่ในรายการคำ';
  }

  @override
  String deskOnbRestoreAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทั้ง $count คำถูกต้อง',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreStaysHere => 'วลีไม่เคยออกจากคอมพิวเตอร์นี้';

  @override
  String get deskOnbRestoreChecksumFirm =>
      'เลขตรวจสอบของวลีนี้ไม่ตรง เทียบทุกคำกับกระดาษ';

  @override
  String deskOnbRestoreChecksumSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ใส่แล้ว $count คำ เลขตรวจสอบไม่ตรง พิมพ์ต่อ หรือเทียบทุกคำกับกระดาษ',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWordsLead =>
      'พิมพ์คำตามลำดับ หรือวางทั้งวลีลงช่องไหนก็ได้';

  @override
  String get deskOnbRestoreClear => 'ล้าง';

  @override
  String deskOnbRestoreUseWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใช้ $count คำ',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWords => 'คำ';

  @override
  String deskOnbRestoreFilledOf(int filled, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total คำ',
    );
    return '$filled จาก $_temp0';
  }

  @override
  String get deskOnbKillTitle => 'Epic ทำงานอยู่แล้ว';

  @override
  String get deskOnbKillBody =>
      'มีกระเป๋าเงินหรือโหนดอื่นใช้ไฟล์และพอร์ตของกระเป๋าเงินอยู่ ปิดโปรแกรมนั้นเพื่อปลดล็อกที่นี่ หรือยกเลิกแล้วปิดเอง';

  @override
  String get deskOnbKillProcesses => 'โปรเซสที่ทำงานอยู่';

  @override
  String get deskOnbKillRoleWallet => 'บริการกระเป๋าเงิน';

  @override
  String get deskOnbKillRoleNode => 'โหนด';

  @override
  String get deskOnbKillNote =>
      'การปิดจะหยุดการซิงก์โหนดหรือการรับเงิน แอปนี้จะเริ่มใหม่หลังปลดล็อก';

  @override
  String get deskOnbKillClosing => 'กำลังปิด…';

  @override
  String get deskOnbKillClose => 'ปิดและปลดล็อก';

  @override
  String get deskOnbSameTitle => 'มีกระเป๋าเงินนี้อยู่แล้ว';

  @override
  String get deskOnbSameBody =>
      'วลีนี้เป็นของกระเป๋าเงินในรายการ ไม่ได้เพิ่มอะไร';

  @override
  String get deskOnbSameWallet => 'กระเป๋าเงิน';

  @override
  String get deskOnbSameNote =>
      'เปิดด้วยรหัสผ่านของกระเป๋าเงินนั้น หรือใช้วลีนี้ตั้งรหัสผ่านใหม่';

  @override
  String get deskOnbSameOpen => 'เปิดกระเป๋าเงิน';

  @override
  String get deskOnbUnlockWhoWindows =>
      'ใครที่ใช้บัญชี Windows นี้ก็เปิดกระเป๋าเงินนี้ได้';

  @override
  String get deskOnbUnlockWho => 'ใครที่ใช้บัญชีนี้ก็เปิดกระเป๋าเงินนี้ได้';

  @override
  String get deskOnbUnlockWrong =>
      'รหัสผ่านไม่ถูกต้อง ตรวจ Caps Lock และภาษาของแป้นพิมพ์';

  @override
  String deskOnbUnlockPortInUse(String port) {
    return 'พอร์ต $port ถูกโปรแกรมอื่นใช้อยู่ ปิดโปรแกรมนั้นแล้วลองอีกครั้ง';
  }

  @override
  String get deskOnbUnlockStageCheck => 'กำลังตรวจไฟล์กระเป๋าเงิน';

  @override
  String get deskOnbUnlockStageProcesses =>
      'กำลังหาโปรเซสกระเป๋าเงินที่ยังทำงานอยู่';

  @override
  String get deskOnbUnlockStageClosing => 'กำลังปิดโปรเซสกระเป๋าเงินเดิม';

  @override
  String get deskOnbUnlockStageWallet => 'กำลังเริ่มบริการกระเป๋าเงิน';

  @override
  String get deskOnbUnlockStageUnlock => 'กำลังปลดล็อกกระเป๋าเงิน';

  @override
  String get deskOnbUnlockEnter => 'ใส่รหัสผ่าน';

  @override
  String get deskOnbUnlockCloseOthers => 'ปิดโปรเซส Epic อื่น แล้วปลดล็อก';

  @override
  String get deskOnbUnlockRememberedUnavailable =>
      'ใช้รหัสผ่านที่จำไว้ไม่ได้ ใส่รหัสผ่าน';

  @override
  String get deskOnbUnlockRememberedForgotten =>
      'รหัสผ่านที่จำไว้ถูกลืมแล้ว ใส่รหัสผ่าน';

  @override
  String get deskOnbUnlockNotRemembered => 'ไม่ได้จำ';

  @override
  String get deskOnbUnlockKeyStore => 'ที่เก็บคีย์ของคอมพิวเตอร์นี้ใช้ไม่ได้';

  @override
  String get deskOnbUnlockThisWallet => 'กระเป๋าเงินนี้';

  @override
  String get deskOnbUnlockFailed => 'ปลดล็อกไม่สำเร็จ';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'กำลังปลดล็อก $name';
  }

  @override
  String get deskOnbUnlockNote =>
      'จากนั้นโหนด ยอดเงิน และการรับเงินจะทำงานต่อเบื้องหลังจนเสร็จ';

  @override
  String get deskOnbUnlockTitle => 'ปลดล็อกกระเป๋าเงิน';

  @override
  String get deskOnbUnlockLead => 'คีย์อยู่บนคอมพิวเตอร์นี้';

  @override
  String get deskOnbUnlockRemember => 'จำไว้บนคอมพิวเตอร์นี้';

  @override
  String deskOnbUnlockRememberFor(String who) {
    return '30 วัน $who';
  }

  @override
  String get deskOnbUnlockMissingTitle => 'ไม่พบโฟลเดอร์ของกระเป๋าเงินนี้';

  @override
  String deskOnbUnlockMissingText(String folder) {
    return 'เคยอยู่ที่ $folder';
  }

  @override
  String get deskOnbUnlockRemove => 'นำออก';

  @override
  String get deskOnbUnlockTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskOnbUnlockButton => 'ปลดล็อก';

  @override
  String get deskOnbNodeFreeUnknown => 'ไม่ทราบพื้นที่ว่าง';

  @override
  String deskOnbNodeFreeHere(String size) {
    return 'ว่าง $size';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'ตอนนี้ใช้ดิสก์ประมาณ $size';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return 'ตอนนี้ใช้ดิสก์ $size';
  }

  @override
  String get deskOnbNodeSeparate => 'เป็นโปรแกรมแยก';

  @override
  String get deskOnbNodeSeparateText => 'เริ่มและหยุดพร้อมกับแอป';

  @override
  String get deskOnbNodeFirewall => 'Windows จะถามครั้งเดียว';

  @override
  String get deskOnbNodeFirewallText =>
      'ว่าจะอนุญาตผ่านไฟร์วอลล์ไหม อนุญาตสำหรับเครือข่ายส่วนตัว';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'และเพิ่มขึ้นช้า ๆ · $free';
  }

  @override
  String get deskOnbNodeHours => 'การซิงก์ครั้งแรก';

  @override
  String get deskOnbNodeHoursText =>
      'แสดงความคืบหน้า ระหว่างนั้นใช้โหนดสาธารณะแทน';

  @override
  String get deskOnbNodeDownload => 'ดาวน์โหลดประมาณ 4 GB';

  @override
  String get deskOnbNodeDownloadText => 'ในครั้งแรก จากนั้นเพิ่มเล็กน้อยทุกวัน';

  @override
  String get deskOnbNodeFound => 'พบ';

  @override
  String deskOnbNodeFoundAt(String version, String address) {
    return 'Epic $version ที่ $address';
  }

  @override
  String deskOnbNodeHeight(String height) {
    return 'บล็อก $height';
  }

  @override
  String get deskOnbNodeSynced => 'ซิงก์แล้ว';

  @override
  String get deskOnbNodeNoAnswer => 'ไม่มีโหนดตอบ';

  @override
  String deskOnbNodeNoAnswerAt(String address) {
    return 'ที่ $address เริ่มโหนด หรือตรวจที่อยู่และพอร์ต';
  }

  @override
  String get deskOnbNodeExisting => 'ใช้โหนดที่ทำงานอยู่บนคอมพิวเตอร์นี้';

  @override
  String get deskOnbNodeExistingText =>
      'เชื่อมต่อกับโหนดของ Epic GUI หรือ CLI ที่ทำงานอยู่ในเครื่องนี้แล้ว';

  @override
  String get deskOnbNodeAddress => 'ที่อยู่ของโหนดบนคอมพิวเตอร์นี้';

  @override
  String get deskOnbNodeCheck => 'ตรวจ';

  @override
  String get deskOnbNodeBundled => 'เริ่มโหนดที่มากับแอป';

  @override
  String get deskOnbNodeBundledText =>
      'ดาวน์โหลดบล็อกเชนลงในโฟลเดอร์ของกระเป๋าเงินหลังกด บันทึก';

  @override
  String deskOnbNodeFallback(String host) {
    return 'ใช้ $host จนกว่าโหนดในเครื่องจะซิงก์เสร็จ';
  }

  @override
  String get deskOnbNodeDialogTitle => 'โหนดในเครื่อง';

  @override
  String get deskOnbNodeDialogBody =>
      'การรันโหนดที่นี่หมายถึงอะไร และจะใช้โหนดไหน';

  @override
  String get deskOnbNodeUseThis => 'ใช้โหนดนี้';

  @override
  String get deskOnbNodeStart => 'เริ่มโหนดในเครื่อง';

  @override
  String deskOnbRestorePasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วางแล้ว $count คำ วลีมี 12, 15, 18, 21 หรือ 24 คำ',
    );
    return '$_temp0';
  }

  @override
  String deskOnbWordN(int number) {
    return 'คำที่ $number';
  }

  @override
  String get deskOnbImportEnterOld => 'ใส่รหัสผ่านเดิม';

  @override
  String deskOnbImportNewShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ตัวอักษร',
    );
    return 'รหัสผ่านใหม่: อย่างน้อย $_temp0';
  }

  @override
  String get deskOnbImportNewDiffer => 'รหัสผ่านใหม่ไม่ตรงกัน';

  @override
  String deskOnbImportWalletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'กระเป๋าเงิน $count ใบ',
    );
    return '$_temp0';
  }

  @override
  String deskOnbImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'นำเข้ากระเป๋าเงิน $count ใบแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFindingTitle => 'กำลังหากระเป๋าเงิน';

  @override
  String get deskOnbImportFindingLead =>
      'กำลังค้นหาโฟลเดอร์ของ Epic Wallet รุ่นเก่าและโปรแกรม epic โดยอ่านโฟลเดอร์เดิมเท่านั้น';

  @override
  String deskOnbImportFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'พบกระเป๋าเงิน $count ใบ',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFoundLead => 'โฟลเดอร์เดิมถูกอ่านอย่างเดียว';

  @override
  String get deskOnbImportNoneTitle => 'ไม่พบกระเป๋าเงิน';

  @override
  String get deskOnbImportNoneLead =>
      'เลือกโฟลเดอร์กระเป๋าเงิน หรือกู้คืนจากวลีกู้คืน';

  @override
  String get deskOnbImportChooseTitle => 'เลือกกระเป๋าเงิน';

  @override
  String get deskOnbImportChooseLead =>
      'กระเป๋าเงินที่เลือกจะถูกเพิ่มในแอป ประวัติจะสร้างใหม่จากการสแกน';

  @override
  String get deskOnbImportCheckTitle => 'กำลังตรวจกระเป๋าเงิน';

  @override
  String get deskOnbImportCheckLead =>
      'กระเป๋าเงินที่โปรแกรมอื่นใช้อยู่จะไม่ถูกนำเข้า';

  @override
  String get deskOnbImportTitle => 'นำเข้า';

  @override
  String get deskOnbImportLead => 'แต่ละกระเป๋าเงินจะถามรหัสผ่านเดิมครั้งเดียว';

  @override
  String get deskOnbImportDoneTitle => 'นำเข้ากระเป๋าเงินแล้ว';

  @override
  String get deskOnbImportDoneLead =>
      'การปลดล็อกครั้งแรกของแต่ละกระเป๋าเงินจะสแกนบล็อกเชนหาประวัติ';

  @override
  String deskOnbImportSelected(int selected, int total) {
    return 'เลือก $selected จาก $total';
  }

  @override
  String get deskOnbImportChecking => 'กำลังตรวจ…';

  @override
  String get deskOnbImportCloseOther => 'ปิดโปรแกรมอื่น หรือข้ามกระเป๋าเงินนี้';

  @override
  String deskOnbImportImportedOf(int done, int total) {
    return 'นำเข้าแล้ว $done จาก $total';
  }

  @override
  String get deskOnbImportOpen => 'เปิดกระเป๋าเงิน';

  @override
  String get deskOnbImportStepFind => 'ค้นหา';

  @override
  String get deskOnbImportStepChoose => 'เลือก';

  @override
  String get deskOnbImportStepCheck => 'ตรวจ';

  @override
  String get deskOnbImportBack => 'ย้อนกลับ';

  @override
  String get deskOnbImportSkip => 'ข้าม';

  @override
  String get deskOnbImportOlder => 'Epic Wallet รุ่นเก่า';

  @override
  String get deskOnbImportOlderSub => 'กระเป๋าเงินและโฟลเดอร์';

  @override
  String get deskOnbImportEpicProgram => 'โปรแกรม epic';

  @override
  String get deskOnbImportSearching => 'กำลังค้นหา…';

  @override
  String get deskOnbImportRestore => 'กู้คืนจากวลีกู้คืน';

  @override
  String deskOnbImportLastUsed(String date) {
    return 'ใช้ล่าสุด $date';
  }

  @override
  String deskOnbImportSecondCopy(String reason) {
    return '$reason เลือกเพื่อเพิ่มสำเนาที่สอง';
  }

  @override
  String deskOnbImportCannot(String name) {
    return '$name: นำเข้าไม่ได้';
  }

  @override
  String get deskOnbImportInApp => 'อยู่ในแอปแล้ว';

  @override
  String get deskOnbImportSameWallet => 'กระเป๋าเงินเดียวกัน';

  @override
  String get deskOnbImportNotInUse => 'ไม่ได้ใช้อยู่';

  @override
  String get deskOnbImportNotChecked => 'ไม่ได้ตรวจ';

  @override
  String get deskOnbImportSkipped => 'ข้ามแล้ว';

  @override
  String get deskOnbImportInUse => 'ใช้อยู่';

  @override
  String get deskOnbImportInUseText =>
      'โปรแกรมอื่นใช้อยู่ ปิด Epic Wallet รุ่นเก่าหรือโปรแกรม epic แล้วตรวจอีกครั้ง';

  @override
  String get deskOnbImportCheckAgain => 'ตรวจอีกครั้ง';

  @override
  String get deskOnbImportImported => 'นำเข้าแล้ว';

  @override
  String get deskOnbImportImporting => 'กำลังนำเข้า…';

  @override
  String get deskOnbImportWaiting => 'รอ';

  @override
  String get deskOnbImportOldPassword => 'รหัสผ่านเดิม';

  @override
  String deskOnbImportOldHelp(String name) {
    return 'รหัสผ่านของ $name ในแอปเดิม';
  }

  @override
  String deskOnbImportOldOf(String name) {
    return 'รหัสผ่านเดิมของ $name';
  }

  @override
  String deskOnbImportOldShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อย่างน้อย $count ตัวอักษร',
    );
    return 'รหัสผ่านเดิมสั้นไป ตั้งรหัสผ่านใหม่ $_temp0';
  }

  @override
  String get deskOnbImportNewPassword => 'รหัสผ่านใหม่';

  @override
  String get deskOnbImportRepeat => 'ใส่อีกครั้ง';

  @override
  String get deskOnbImportRepeatNew => 'ใส่รหัสผ่านใหม่อีกครั้ง';

  @override
  String get deskOnbImportUnchanged =>
      'โฟลเดอร์เดิมไม่เปลี่ยน แอปเดิมยังเปิดได้';

  @override
  String get deskOnbImportStopTitle => 'หยุดการนำเข้าไหม?';

  @override
  String get deskOnbImportStopBody =>
      'กระเป๋าเงินที่นำเข้าไปแล้วจะถูกนำออก โฟลเดอร์เดิมไม่เปลี่ยน';

  @override
  String get deskOnbImportGoBack => 'กลับไป';

  @override
  String get deskOnbImportStop => 'หยุดการนำเข้า';

  @override
  String get deskRailWaitingTor => 'รอ Tor';

  @override
  String get deskRailOn => 'เปิด';

  @override
  String get deskRailConnecting => 'กำลังเชื่อมต่อ';

  @override
  String get deskRailSlow => 'ช้า';

  @override
  String get deskRailNotAnswering => 'ไม่ตอบสนอง';

  @override
  String get deskRailOff => 'ปิด';

  @override
  String get deskRailChecking => 'กำลังตรวจ';

  @override
  String get deskRailOverTor => 'ผ่าน Tor';

  @override
  String get deskRailWaitsForTor => 'รอจนกว่า Tor จะเชื่อมต่อ';

  @override
  String get deskRailPaymentsWait => 'รายการรออยู่บนเซิร์ฟเวอร์ Epicbox';

  @override
  String get deskRailOpenEpicbox => 'เปิดการรับผ่าน Epicbox';

  @override
  String get deskRailStarting => 'กำลังเริ่ม';

  @override
  String get deskRailNotReceiving => 'ไม่ได้รับเงิน';

  @override
  String get deskRailOnInternet => 'เปิด · อินเทอร์เน็ต';

  @override
  String get deskRailOnLocal => 'เปิด · ในเครื่อง';

  @override
  String get deskRailPortInUse => 'พอร์ตถูกใช้อยู่';

  @override
  String get deskRailStopped => 'หยุดอยู่';

  @override
  String deskRailPortInternet(String port) {
    return 'พอร์ต $port · จากอินเทอร์เน็ต';
  }

  @override
  String deskRailPortLocal(String port) {
    return 'พอร์ต $port · คอมพิวเตอร์นี้เท่านั้น';
  }

  @override
  String get deskRailOpenHttp => 'เปิดการรับ: ลิงก์ · HTTP';

  @override
  String get deskRailTorNotInBuild => 'ไม่มีในรุ่นนี้';

  @override
  String get deskRailStartingDots => 'กำลังเริ่ม…';

  @override
  String deskRailTorSlow(String problem) {
    return '$problem การส่งใช้ได้';
  }

  @override
  String get deskRailTorNoAddress => 'ยังไม่ได้เผยแพร่ที่อยู่ Tor';

  @override
  String get deskRailOpenPrivacy => 'เปิดการตั้งค่าความเป็นส่วนตัว';

  @override
  String get deskRailNode => 'โหนด';

  @override
  String get deskRailOpenNode => 'เปิดการตั้งค่าโหนด';

  @override
  String get deskAppNodeSyncedTitle => 'โหนดในเครื่องซิงก์เสร็จแล้ว';

  @override
  String get deskAppNodeSyncedBody =>
      'โหนดในเครื่องมีบล็อกเชนครบแล้วและใช้ได้ทันที แอปจะเริ่มใหม่เพื่อสลับไปใช้';

  @override
  String get deskAppNotNow => 'ไว้ทีหลัง';

  @override
  String get deskAppRestartNow => 'เริ่มใหม่ตอนนี้';

  @override
  String get deskAppFirstScanTitle => 'การสแกนครั้งแรก';

  @override
  String get deskAppFirstScanBody =>
      'กระเป๋าเงินกำลังค้นหาเอาต์พุตของตัวเองบนบล็อกเชน ระหว่างนี้ยังใช้ได้ ยอดคงเหลือจะอัปเดตเมื่อสแกนเสร็จ';

  @override
  String get deskAppScanOutput => 'ผลการสแกน';

  @override
  String get deskAppWaitingOutput => 'รอผลแรก…';

  @override
  String get deskShellNavOverview => 'ภาพรวม';

  @override
  String get deskShellNavActivity => 'ประวัติ';

  @override
  String get deskShellNavSend => 'ส่ง';

  @override
  String get deskShellNavReceive => 'รับ';

  @override
  String get deskShellNavOutputs => 'เอาต์พุต';

  @override
  String get deskShellNavContacts => 'ผู้ติดต่อ';

  @override
  String get deskShellNavSettings => 'การตั้งค่า';

  @override
  String get deskShellTitleImportTx => 'นำเข้าธุรกรรม';

  @override
  String get deskShellTitleFinalizeTx => 'ทำธุรกรรมให้เสร็จ';

  @override
  String get deskShellLocksAfterSend => 'จะล็อกเมื่อส่งรายการเสร็จ';

  @override
  String get deskShellNotQuitTitle => 'ไม่ได้ปิดแอป';

  @override
  String get deskShellNotQuitBody =>
      'มีการส่งที่กำลังดำเนินอยู่ ปิดอีกครั้งเมื่อเสร็จแล้ว';

  @override
  String get deskShellLockedTitle => 'ล็อกกระเป๋าเงินแล้ว';

  @override
  String get deskShellLockedBody => 'ปิดแอปได้เมื่อเชื่อมต่อแกนกระเป๋าเงินแล้ว';

  @override
  String deskShellLockWallet(String keys) {
    return 'ล็อกกระเป๋าเงิน ($keys)';
  }

  @override
  String get deskShellMainNav => 'เมนูหลัก';

  @override
  String deskShellVersion(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get deskShellOpenWalletSettings => 'เปิดการตั้งค่ากระเป๋าเงิน';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'เปิดการตั้งค่ากระเป๋าเงิน: $name';
  }

  @override
  String get deskShellSwitchWallet => 'สลับกระเป๋าเงิน';

  @override
  String deskShellWalletBy(String maker) {
    return 'กระเป๋าเงินโดย $maker';
  }

  @override
  String get deskTourOverviewTitle => 'ภาพรวม';

  @override
  String get deskTourOverviewText =>
      'ยอดคงเหลือและยอดที่กำลังยืนยัน ตามด้วยธุรกรรมล่าสุด อย่างอื่นอยู่ในแถบด้านข้าง';

  @override
  String get deskTourSendTitle => 'ส่ง';

  @override
  String get deskTourSendText =>
      'จ่ายไปที่อยู่ Epicbox หรือสร้างไฟล์ธุรกรรมให้อีกฝ่ายเซ็น จะมีการตรวจสอบก่อนส่งทุกครั้ง';

  @override
  String get deskTourReceiveTitle => 'รับ';

  @override
  String get deskTourReceiveText =>
      'ที่อยู่ Epicbox ของกระเป๋าเงินนี้ แชร์เพื่อรับเงิน ไฟล์ธุรกรรมที่ต้องเซ็นหรือทำให้เสร็จอยู่ใต้ลงไป';

  @override
  String get deskTourInvoicesTitle => 'ใบแจ้งหนี้';

  @override
  String get deskTourInvoicesText =>
      'ชำระใบแจ้งหนี้ที่มีคนส่งมา หรือออกใบแจ้งหนี้ให้คนที่ค้างจ่าย แท็บใช้สลับระหว่างสองอย่างนี้';

  @override
  String get deskTourActivityTitle => 'ประวัติ';

  @override
  String get deskTourActivityText =>
      'ทุกธุรกรรมพร้อมความคืบหน้าและรายละเอียด ตัวเลขบนเมนูนี้หมายความว่ามีบางอย่างรอการดำเนินการ';

  @override
  String get deskTourContactsTitle => 'ผู้ติดต่อ';

  @override
  String get deskTourContactsText =>
      'ที่อยู่ที่บันทึกไว้ตามชื่อ หน้าส่งเลือกจากที่นี่';

  @override
  String get deskTourNodeTitle => 'การตั้งค่า › โหนด';

  @override
  String get deskTourNodeText =>
      'โหนดที่กระเป๋าเงินใช้อ่านเชน หน้าการตั้งค่าอื่นๆ อยู่ทางซ้าย';

  @override
  String get deskTourHelpTitle => 'ช่วยเหลือ';

  @override
  String get deskTourHelpText =>
      'หัวข้อช่วยเหลือ รายงานปัญหา และแสดงทัวร์อีกครั้ง';

  @override
  String deskTourCounter(int current, int total) {
    return '$current จาก $total';
  }

  @override
  String get deskTourSemantics => 'ทัวร์กระเป๋าเงิน';

  @override
  String get deskTourSkip => 'ข้ามทัวร์';

  @override
  String get deskTourBack => 'ย้อนกลับ';

  @override
  String get deskTourNext => 'ถัดไป';

  @override
  String get deskKitUnknown => 'ไม่ทราบ';

  @override
  String get deskKitRingCancelled => 'ยกเลิกแล้ว';

  @override
  String get deskKitRingConfirmed => 'ยืนยันแล้ว';

  @override
  String deskKitRingProgress(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'ยืนยันแล้ว $confirmations จาก $needed ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get deskKitHiddenAmount => 'จำนวนที่ซ่อนไว้';

  @override
  String get deskKitChooseFile => 'เลือกไฟล์';

  @override
  String deskKitNeedAction(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการรอดำเนินการ',
    );
    return '$label, $_temp0';
  }

  @override
  String get deskKitHealthOn => 'ทำงาน';

  @override
  String get deskKitHealthSlow => 'ช้า';

  @override
  String get deskKitHealthOffline => 'ออฟไลน์';

  @override
  String get deskKitHealthOff => 'ปิด';

  @override
  String get deskKitHealthChecking => 'กำลังตรวจ';

  @override
  String get deskKitCloseEsc => 'ปิด (Esc)';

  @override
  String get deskKitOptional => 'ไม่บังคับ';

  @override
  String get deskKitBackAlt => 'ย้อนกลับ (Alt+Left)';

  @override
  String deskKitStepOf(int current, int total) {
    return 'ขั้นตอน $current จาก $total';
  }

  @override
  String get deskKitHeroCaptionEpicbox => 'เซิร์ฟเวอร์ EPICBOX เก็บไว้ให้';

  @override
  String get deskKitHeroCaptionHttp => 'ตรงถึงกระเป๋าผู้รับ';

  @override
  String get deskKitHeroCaptionTor => 'ส่งตรง ผ่าน TOR';

  @override
  String get deskKitHeroCaptionFile => 'ส่งไฟล์ไป ได้ไฟล์ตอบกลับ';

  @override
  String get deskKitHeroLabelEpicbox =>
      'Epicbox: รายการไปที่เซิร์ฟเวอร์ Epicbox ซึ่งเก็บไว้จนกว่ากระเป๋าเงินของผู้รับจะกลับมาออนไลน์';

  @override
  String get deskKitHeroLabelHttp =>
      'ลิงก์ · HTTP: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';

  @override
  String get deskKitHeroLabelTor =>
      'ลิงก์ · Tor: รายการจะไปถึงกระเป๋าของผู้รับโดยตรงผ่านเครือข่าย Tor';

  @override
  String get deskKitHeroLabelFile =>
      'โดยตรง · โอนไฟล์: ส่งไฟล์ธุรกรรมไป รับไฟล์ตอบกลับมา แล้วผู้ส่งทำรายการให้เสร็จ';

  @override
  String get deskKitReachCheck => 'ตรวจ';

  @override
  String get deskKitReachChecking => 'กำลังตรวจจากอินเทอร์เน็ต…';

  @override
  String get deskKitReachNoIpTitle => 'ไม่พบ public IP';

  @override
  String get deskKitReachNoIpText =>
      'ถามจากอินเทอร์เน็ตไม่ได้ ลองอีกครั้งภายหลัง';

  @override
  String deskKitReachNoIpTextLan(String address) {
    return 'ถามจากอินเทอร์เน็ตไม่ได้ ลองอีกครั้งภายหลัง ในเครือข่ายของคุณ: $address';
  }

  @override
  String get deskKitReachClosedTitle => 'เข้าถึงจากอินเทอร์เน็ตไม่ได้';

  @override
  String deskKitReachClosedText(String port) {
    return 'Forward พอร์ต TCP $port บนเราเตอร์มายังคอมพิวเตอร์นี้ แล้วตรวจอีกครั้ง';
  }

  @override
  String deskKitReachClosedTextLan(String port, String address) {
    return 'Forward พอร์ต TCP $port บนเราเตอร์มายังคอมพิวเตอร์นี้ ($address) แล้วตรวจอีกครั้ง';
  }

  @override
  String get deskKitReachUnknownTitle => 'ไม่ทราบว่าเข้าถึงได้ไหม';

  @override
  String get deskKitReachUnknownText =>
      'บริการตรวจพอร์ตไม่ตอบ ลองอีกครั้งภายหลัง';

  @override
  String deskKitReachUnknownTextLan(String address) {
    return 'บริการตรวจพอร์ตไม่ตอบ ลองอีกครั้งภายหลัง ในเครือข่ายของคุณ: $address';
  }

  @override
  String get deskKitReachOpenTitle => 'เข้าถึงได้จากอินเทอร์เน็ต';

  @override
  String deskKitReachOpenText(String port) {
    return 'Forward พอร์ต $port แล้ว';
  }

  @override
  String deskKitReachOpenTextLan(String port, String address) {
    return 'Forward พอร์ต $port แล้ว ในเครือข่ายของคุณ: $address';
  }

  @override
  String deskKitAgeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วินาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count นาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ชั่วโมงที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วันที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get deskKitNodeBefore410 => 'โหนดก่อน 4.1.0';

  @override
  String get deskKitNodeNoAnswer => 'ไม่ตอบ';

  @override
  String get deskKitNodesDisagree => 'โหนดเห็นบล็อกล่าสุดไม่ตรงกัน';

  @override
  String deskKitNodesAgree(String height) {
    return 'โหนดเห็นตรงกันที่ $height';
  }

  @override
  String deskKitNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: 'โหนดทำงาน $up จาก $total',
    );
    return '$_temp0';
  }

  @override
  String deskKitEpicboxUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: 'เซิร์ฟเวอร์ Epicbox ทำงาน $up จาก $total',
    );
    return '$_temp0';
  }

  @override
  String deskKitLastBlock(String age) {
    return 'บล็อกล่าสุด $age';
  }

  @override
  String deskKitLimitedNetwork(String site) {
    return 'เข้าถึง $site ไม่ได้ ข้อมูลมาจากโหนดเท่านั้น';
  }

  @override
  String get deskKitFactHeight => 'บล็อก';

  @override
  String get deskKitFactVersion => 'เวอร์ชัน';

  @override
  String get deskKitFactAccepts => 'รับธุรกรรม';

  @override
  String get deskKitFactYes => 'ใช่';

  @override
  String get deskKitFactNotYet => 'ยังไม่';

  @override
  String get deskKitFactUnknown => 'ไม่ทราบ';

  @override
  String get deskKitFactLatency => 'เวลาตอบสนอง';

  @override
  String get deskKitFactUptime => 'Uptime';

  @override
  String get deskKitFactPeers => 'Peer';

  @override
  String get deskKitFactOperator => 'ผู้ดูแล';

  @override
  String get deskKitAtTip => 'ล่าสุด';

  @override
  String deskKitBehind(int count, String blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ตามหลัง $blocks',
    );
    return '$_temp0';
  }

  @override
  String deskKitVersionOut(String version) {
    return 'มี $version แล้ว';
  }

  @override
  String get deskKitVersionLatest => 'ล่าสุด';

  @override
  String get deskKitUptimeWindow => '24 ชั่วโมงล่าสุด';

  @override
  String deskKitAtTime(String time) {
    return 'เมื่อ $time';
  }

  @override
  String get deskKitListedOfficial => 'อยู่ในรายการทางการ';

  @override
  String deskKitSourceChecked(String time, String site) {
    return '$site ตรวจเมื่อ $time';
  }

  @override
  String deskKitLatencyMeasured(String where) {
    return 'วัดเวลาตอบสนอง$where';
  }

  @override
  String deskKitSiteLastReached(String time) {
    return 'เข้าถึงเว็บสถานะครั้งล่าสุดเมื่อ $time';
  }

  @override
  String deskKitSince(String time) {
    return 'ตั้งแต่ $time';
  }

  @override
  String deskKitNodeSemantics(String status, String host) {
    return 'โหนด $status: $host';
  }

  @override
  String get deskKitNodeDownTitle => 'โหนดไม่ตอบสนอง';

  @override
  String deskKitNodeDownText(String host) {
    return 'เปลี่ยนไปใช้ $host ซึ่งเป็นโหนดอื่นที่ทำงานดีที่สุดไหม?';
  }

  @override
  String get deskKitSwitch => 'เปลี่ยน';

  @override
  String get deskKitLimitedInfo => 'ข้อมูลจำกัด';

  @override
  String deskKitFromStatusSite(String site) {
    return 'จาก $site';
  }

  @override
  String get deskKitOverTor => 'ผ่าน Tor';

  @override
  String get deskKitFromThisComputer => 'จากคอมพิวเตอร์นี้';

  @override
  String deskKitNodeUse(String host) {
    return 'ใช้ $host';
  }

  @override
  String deskKitNodeUseOperator(String host, String operator) {
    return 'ใช้ $host, $operator';
  }

  @override
  String deskKitNodeUseDown(String host) {
    return 'ใช้ $host, ไม่ตอบสนอง';
  }

  @override
  String deskKitNodeUseOperatorDown(String host, String operator) {
    return 'ใช้ $host, $operator, ไม่ตอบสนอง';
  }

  @override
  String deskKitLocalNodeUse(String state) {
    return 'ใช้โหนดในเครื่อง, $state';
  }

  @override
  String get deskKitLocalNode => 'โหนดในเครื่อง';

  @override
  String get deskKitMethodWaitingTor => 'รอ Tor';

  @override
  String get deskKitMethodOn => 'เปิด';

  @override
  String deskKitMethodOverTor(String host) {
    return '$host ผ่าน Tor';
  }

  @override
  String get deskKitMethodOff => 'ปิด';

  @override
  String get deskKitMethodEpicboxOffDetail =>
      'รายการที่ส่งถึงที่อยู่นี้รออยู่บนเซิร์ฟเวอร์ Epicbox';

  @override
  String get deskKitMethodConnecting => 'กำลังเชื่อมต่อ';

  @override
  String get deskKitMethodSlow => 'ช้า';

  @override
  String get deskKitMethodNotAnswering => 'ไม่ตอบสนอง';

  @override
  String deskKitMethodEpicboxDown(String host) {
    return '$host รายการรออยู่บนเซิร์ฟเวอร์ Epicbox';
  }

  @override
  String get deskKitMethodHttpOffDetail =>
      'ตรงจากกระเป๋าเงินอื่นขณะที่กระเป๋าเงินนี้เปิดอยู่';

  @override
  String get deskKitMethodStarting => 'กำลังเริ่ม…';

  @override
  String deskKitMethodHttpInternet(String port) {
    return 'จากอินเทอร์เน็ต พอร์ต $port';
  }

  @override
  String get deskKitMethodHttpLocal => 'คอมพิวเตอร์นี้เท่านั้น (127.0.0.1)';

  @override
  String get deskKitMethodNotReceiving => 'ไม่ได้รับเงิน';

  @override
  String deskKitMethodPortInUse(String port) {
    return 'พอร์ต $port ถูกโปรแกรมอื่นใช้อยู่ ปิดโปรแกรมนั้น หรือเลือกพอร์ตอื่นในการตั้งค่า';
  }

  @override
  String get deskKitMethodNotInBuild => 'ไม่มีในรุ่นนี้';

  @override
  String get deskKitMethodTorOffDetail =>
      'ช้ากว่าแต่เป็นส่วนตัวกว่า บางประเทศบล็อกหรือไม่อนุญาต';

  @override
  String get deskKitMethodTorPublishing => 'กำลังเผยแพร่ที่อยู่ Tor…';

  @override
  String get deskKitMethodTorConnecting => 'กำลังเชื่อมต่อ Tor…';

  @override
  String get deskKitMethodTorOnDetail => 'รับได้ที่ที่อยู่ Tor';

  @override
  String get deskKitMethodTorNotPublished => 'ยังไม่ได้เผยแพร่';

  @override
  String deskKitMethodTorSendsWork(String reason) {
    return '$reason การส่งใช้ได้';
  }

  @override
  String get deskKitMethodTorNotReachableYet => 'ยังเข้าถึงที่อยู่ Tor ไม่ได้';

  @override
  String get deskKitMethodTorStopped => 'หยุดอยู่';

  @override
  String get deskKitMethodTorStoppedDetail => 'Tor หยุดแล้ว';

  @override
  String get deskKitMethodFiles => 'โดยตรง · โอนไฟล์';

  @override
  String get deskKitChipOverTor => 'ผ่าน Tor';

  @override
  String get deskKitChipStarting => 'Tor กำลังเริ่ม';

  @override
  String get deskKitChipNotConnected => 'Tor ไม่ได้เชื่อมต่อ';

  @override
  String get deskKitChipNotOverTor => 'ไม่ผ่าน Tor';

  @override
  String get deskKitPasswordNote =>
      'ประเมินบนอุปกรณ์นี้จากความยาวและคำ ชื่อ และรูปแบบที่พบบ่อย สำหรับผู้โจมตีที่ใช้ฮาร์ดแวร์เร็วเดา 100,000 ครั้งต่อวินาทีกับไฟล์ของกระเป๋าเงินนี้ เป็นแนวทาง ไม่ใช่การรับประกัน';

  @override
  String get deskKitPasswordNoteLabel => 'วิธีประเมินเวลา';

  @override
  String get deskKitNotCopied => 'ไม่ได้คัดลอก';

  @override
  String get deskKitCopied => 'คัดลอกแล้ว';

  @override
  String deskKitQrOf(String title) {
    return 'QR Code ของ$title';
  }

  @override
  String deskKitQrOfTag(String title, String tag) {
    return 'QR Code ของ$title, $tag';
  }

  @override
  String deskKitQrShowOf(String title) {
    return 'แสดง QR Code ของ$title';
  }

  @override
  String get deskKitQrShow => 'แสดง QR';

  @override
  String get deskKitQrHide => 'ซ่อน QR';

  @override
  String get deskKitQrHideCode => 'ซ่อน QR';

  @override
  String get deskSetAcctNotForgotten => 'ไม่ได้ลืม';

  @override
  String get deskSetAcctForgotten => 'ลืมบนคอมพิวเตอร์นี้แล้ว';

  @override
  String get deskSetAcctForgottenText => 'ครั้งหน้าที่เปิดจะถามรหัสผ่าน';

  @override
  String get deskSetAcctLabelNotSaved => 'ไม่ได้บันทึกชื่อ';

  @override
  String get deskSetAcctEnterLabel => 'ใส่ชื่อ';

  @override
  String get deskSetAcctLabelSaved => 'บันทึกชื่อแล้ว';

  @override
  String get deskSetAcctLabel => 'ชื่อ';

  @override
  String get deskSetAcctLabelHint => 'แสดงในแอปนี้เท่านั้น';

  @override
  String get deskSetAcctSaveLabel => 'บันทึกชื่อ';

  @override
  String get deskSetAcctPhraseHint =>
      'คำที่ใช้กู้คืนกระเป๋าเงินนี้ เก็บเป็นความลับ';

  @override
  String get deskSetAcctShowPhrase => 'แสดงวลีกู้คืน…';

  @override
  String get deskSetAcctRescanHint =>
      'อ่านบล็อกเชนอีกครั้งเมื่อยอดดูไม่ถูกต้อง';

  @override
  String get deskSetAcctRecheck => 'ตรวจใหม่…';

  @override
  String get deskSetAcctFiles => 'ไฟล์';

  @override
  String get deskSetAcctWalletFolder => 'โฟลเดอร์กระเป๋าเงิน';

  @override
  String get deskSetAcctAppFiles => 'ไฟล์ของแอป';

  @override
  String get deskSetAcctAppFilesHint => 'การตั้งค่าและบันทึก';

  @override
  String get deskSetAcctNetwork => 'เครือข่าย';

  @override
  String get deskSetAcctNetworkHint => 'กำหนดตอนสร้างกระเป๋าเงิน';

  @override
  String get deskSetAcctSetup => 'ผู้ช่วยตั้งค่า';

  @override
  String get deskSetAcctSetupHint =>
      'ตั้งค่าโหนดและการรับเงินอีกครั้ง ไม่มีอะไรหาย';

  @override
  String get deskSetAcctRunSetup => 'เริ่มตั้งค่า…';

  @override
  String get deskSetAcctSecurity => 'ความปลอดภัย';

  @override
  String get deskSetAcctRemembered => 'จำไว้บนคอมพิวเตอร์นี้';

  @override
  String deskSetAcctRememberedHint(String who) {
    return 'เปิดได้โดยไม่ต้องใส่รหัสผ่าน 30 วันนับจากวันที่ตั้ง การส่งยังถามรหัสผ่าน $who';
  }

  @override
  String get deskSetAcctForget => 'ลืมคอมพิวเตอร์นี้';

  @override
  String get deskSetAcctPasswordHint => 'ใช้ปลดล็อกกระเป๋าเงินนี้';

  @override
  String get deskSetAcctChangePassword => 'เปลี่ยนรหัสผ่าน…';

  @override
  String get deskSetAcctDeleteHint => 'ลบคีย์และฐานข้อมูล';

  @override
  String get deskSetAcctFolderNotFound => 'ไม่พบโฟลเดอร์';

  @override
  String deskSetAcctCopyPath(String title) {
    return 'คัดลอกพาธ: $title';
  }

  @override
  String deskSetBackupWhenToday(String time) {
    return 'วันนี้ $time';
  }

  @override
  String deskSetBackupWhenYesterday(String time) {
    return 'เมื่อวาน $time';
  }

  @override
  String deskSetBackupWhenDate(String day, String time) {
    return '$day, $time';
  }

  @override
  String get deskSetBackupNeverExported => 'ยังไม่เคยส่งออก';

  @override
  String deskSetBackupLastExportNothingNew(String when) {
    return 'ส่งออกล่าสุด $when · ไม่มีอะไรใหม่ตั้งแต่นั้น';
  }

  @override
  String deskSetBackupLastExportSince(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'มีรายการใหม่ $count รายการ',
    );
    return 'ส่งออกล่าสุด $when · $_temp0';
  }

  @override
  String deskSetBackupWriteFailedHere(String reason) {
    return 'เขียนลงโฟลเดอร์ไม่ได้: $reason เลือกโฟลเดอร์อื่น';
  }

  @override
  String deskSetBackupWriteFailedIn(String folder, String reason) {
    return 'เขียนลง $folder ไม่ได้: $reason เลือกโฟลเดอร์อื่น';
  }

  @override
  String get deskSetBackupWriteFailed => 'เขียนไฟล์ไม่ได้ เลือกโฟลเดอร์อื่น';

  @override
  String get deskSetBackupGroup => 'ข้อมูลกระเป๋าเงิน';

  @override
  String get deskSetBackupExportTitle => 'ส่งออกข้อมูลกระเป๋าเงิน';

  @override
  String get deskSetBackupExportHint =>
      'ประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่า ในไฟล์ที่เปิดได้เฉพาะกระเป๋าเงินที่มีวลีกู้คืนนี้ วลีอย่างเดียวนำยอดคงเหลือกลับมา แต่ไม่รวมสิ่งเหล่านี้';

  @override
  String get deskSetBackupExporting => 'กำลังส่งออก…';

  @override
  String get deskSetBackupExportButton => 'ส่งออก…';

  @override
  String get deskSetBackupImportTitle => 'นำเข้าข้อมูลกระเป๋าเงิน';

  @override
  String get deskSetBackupImportHint =>
      'นำประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่าของกระเป๋าเงินนี้กลับมาจากไฟล์ข้อมูลกระเป๋าเงิน ไม่มีอะไรถูกลบ นำเข้าไฟล์เดิมซ้ำก็ไม่เปลี่ยนอะไร';

  @override
  String get deskSetBackupImportButton => 'นำเข้า…';

  @override
  String get deskSetBackupCsvTitle => 'รายการเป็น CSV';

  @override
  String get deskSetBackupCsvHint =>
      'ตารางธรรมดาสำหรับสเปรดชีต ไม่ได้เข้ารหัส และนำเข้ากลับไม่ได้';

  @override
  String get deskSetBackupCsvButton => 'ส่งออก CSV…';

  @override
  String get deskSetBackupSaveDialogTitle => 'บันทึกข้อมูลกระเป๋าเงิน';

  @override
  String get deskSetBackupNotSaved => 'ไม่ได้บันทึก';

  @override
  String get deskSetBackupInFile => 'ในไฟล์';

  @override
  String deskSetBackupInFileCounts(int payments, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments รายการ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'ผู้ติดต่อ $contacts ราย',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get deskSetBackupInFileSub =>
      'ใครจ่ายอะไร ค่าธรรมเนียม บันทึก และป้ายกำกับ; ใบแจ้งหนี้; การตั้งค่า';

  @override
  String get deskSetBackupNotIn => 'ไม่มีในไฟล์';

  @override
  String get deskSetBackupNotInValue => 'วลีกู้คืน กุญแจ รหัสผ่าน';

  @override
  String get deskSetBackupOpensWith => 'เปิดได้ด้วย';

  @override
  String get deskSetBackupOpensWithValue =>
      'กระเป๋าเงินนี้ หรือกระเป๋าเงินที่กู้คืนจากวลีกู้คืนของมัน';

  @override
  String get deskSetBackupFile => 'ไฟล์';

  @override
  String get deskSetBackupFileNote => 'ไฟล์เก็บทุกอย่างถึงปัจจุบัน';

  @override
  String get deskSetBackupExportDesc =>
      'ไฟล์ที่มีประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่าของกระเป๋าเงินนี้ ไฟล์กู้คืนกระเป๋าเงินด้วยตัวเองไม่ได้: กู้คืนจากวลีกู้คืนก่อน แล้วจึงนำเข้าไฟล์นี้';

  @override
  String get deskSetBackupSaved => 'บันทึกแล้ว';

  @override
  String get deskSetBackupKeepCopy =>
      'เก็บสำเนาไว้นอกคอมพิวเตอร์นี้ เช่น USB ไดรฟ์อื่น หรือคลาวด์';

  @override
  String get deskSetBackupOpenFolder => 'เปิดโฟลเดอร์';

  @override
  String get deskSetBackupSaving => 'กำลังบันทึก…';

  @override
  String get deskSetBackupTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskSetBackupSaveAs => 'บันทึกเป็น…';

  @override
  String get deskSetBackupOpenDialogTitle => 'เปิดไฟล์ข้อมูลกระเป๋าเงิน';

  @override
  String get deskSetBackupNothingNew => 'ไม่มีอะไรใหม่';

  @override
  String deskSetBackupNothingNewBody(String file) {
    return 'ทุกรายการใน $file มีอยู่แล้ว';
  }

  @override
  String get deskSetBackupImported => 'นำเข้าแล้ว';

  @override
  String deskSetBackupReading(String file) {
    return 'กำลังอ่าน $file…';
  }

  @override
  String get deskSetBackupNotImported => 'ไม่ได้นำเข้า';

  @override
  String get deskSetBackupBringsBack => 'ได้คืน';

  @override
  String get deskSetBackupBringsBackValue =>
      'รายละเอียดและบันทึกของรายการ รายการเก่าที่หายจากรายชื่อ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่า';

  @override
  String get deskSetBackupNeeds => 'ต้องใช้';

  @override
  String get deskSetBackupNeedsValue =>
      'ไฟล์จากกระเป๋าเงินนี้ (วลีกู้คืนเดียวกัน) กู้คืนกระเป๋าเงินจากวลีของมันก่อน';

  @override
  String get deskSetBackupChooseFile => 'เลือกไฟล์…';

  @override
  String get deskSetBackupImportDesc =>
      'นำประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่าของกระเป๋าเงินนี้กลับมา รายการที่มีอยู่ยังคงอยู่';

  @override
  String get deskSetBackupSaveCsvDialogTitle => 'บันทึกรายการเป็น CSV';

  @override
  String get deskSetBackupCsvDialogTitle => 'ส่งออก CSV';

  @override
  String get deskSetBackupCsvDialogDesc =>
      'ตารางธรรมดาของรายการในกระเป๋าเงินนี้ สำหรับสเปรดชีต';

  @override
  String deskSetBackupCsvSavedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0 ใหม่สุดก่อน จำนวนเป็น EPIC ทศนิยม 8 ตำแหน่ง วันที่เป็น UTC';
  }

  @override
  String get deskSetBackupDateError => 'ใส่วันที่แบบ 2026-01-31';

  @override
  String get deskSetBackupDateHint => 'YYYY-MM-DD';

  @override
  String get deskSetBackupRange => 'ช่วง';

  @override
  String get deskSetBackupRangeAll => 'ตลอดเวลา';

  @override
  String get deskSetBackupRangeThisYear => 'ปีนี้';

  @override
  String get deskSetBackupRangeLastYear => 'ปีที่แล้ว';

  @override
  String get deskSetBackupRangeCustom => 'กำหนดเอง';

  @override
  String get deskSetBackupFrom => 'จาก';

  @override
  String get deskSetBackupTo => 'ถึง';

  @override
  String deskSetBackupCsvInfo(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0 · คอลัมน์: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height ไฟล์ $file';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '– · คอลัมน์: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height ไฟล์ $file';
  }

  @override
  String get deskSetBackupNotEncrypted => 'ไม่ได้เข้ารหัส';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'ใครมีไฟล์ก็อ่านจำนวน วันที่ ที่อยู่ และบันทึกได้ และนำเข้ากลับไม่ได้ ถ้าจะนำเข้าให้ใช้ ส่งออกข้อมูลกระเป๋าเงิน';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการยังไม่อยู่ในข้อมูลกระเป๋าเงินที่ส่งออก',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count รายการเป็นรายการใหม่หรือเปลี่ยนไปหลังส่งออกข้อมูลกระเป๋าเงินครั้งล่าสุด',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'การกู้คืนจากวลีกู้คืนได้คืนยอดคงเหลือ แต่ไม่ได้คืนว่าใครจ่ายอะไร';

  @override
  String get deskSetBackupNotNow => 'ไว้ทีหลัง';

  @override
  String get deskSetDlgChainTitle => 'พบข้อมูลบล็อกเชน';

  @override
  String get deskSetDlgChainDesc =>
      'โหนดในเครื่องใช้ข้อมูลบล็อกเชน Epic ที่มีอยู่แล้วบนคอมพิวเตอร์นี้ได้ ไม่ต้องดาวน์โหลดใหม่';

  @override
  String get deskSetDlgChainFolder => 'โฟลเดอร์';

  @override
  String get deskSetDlgChainSize => 'ขนาด';

  @override
  String get deskSetDlgChainUpdated => 'อัปเดตล่าสุด';

  @override
  String get deskSetDlgChainUpdatedValue => '3 วันที่แล้ว';

  @override
  String get deskSetDlgChainOthers => 'พบสำเนาอื่นอีก 1 ชุด ชุดนี้ใหม่ที่สุด';

  @override
  String get deskSetDlgChainInUse =>
      'โปรแกรม Epic อื่นกำลังใช้โฟลเดอร์นี้ ปิดโปรแกรมนั้น แล้วเลือกโหนดในเครื่องอีกครั้งเพื่อใช้ข้อมูลนี้';

  @override
  String get deskSetDlgChainUseIt => 'ใช้ข้อมูลนี้ไหม?';

  @override
  String get deskSetDlgChainOlderWallet =>
      'Epic Wallet รุ่นเก่าที่ใช้โฟลเดอร์นี้อาจต้องซิงก์ใหม่หลังจากนี้ เหรียญไม่ได้รับผลกระทบ';

  @override
  String get deskSetDlgChainFresh => 'ดาวน์โหลดใหม่';

  @override
  String get deskSetDlgChainUse => 'ใช้ข้อมูลนี้';

  @override
  String get deskSetDlgPwChanged => 'เปลี่ยนรหัสผ่านแล้ว';

  @override
  String get deskSetDlgPwTitle => 'เปลี่ยนรหัสผ่าน';

  @override
  String get deskSetDlgPwDesc =>
      'ตั้งแต่นี้รหัสผ่านใหม่จะใช้ปลดล็อกกระเป๋าเงินนี้ และ จำไว้บนคอมพิวเตอร์นี้ จะถูกปิด';

  @override
  String get deskSetDlgPwCurrent => 'รหัสผ่านปัจจุบัน';

  @override
  String get deskSetDlgPwWrong => 'รหัสผ่านไม่ถูกต้อง';

  @override
  String get deskSetDlgPwNew => 'รหัสผ่านใหม่';

  @override
  String get deskSetDlgPwRepeat => 'ใส่รหัสผ่านใหม่อีกครั้ง';

  @override
  String deskSetDlgRemoveToastList(String name) {
    return 'นำ $name ออกจากรายการแล้ว';
  }

  @override
  String deskSetDlgRemoveToastDeleted(String name) {
    return 'ลบ $name แล้ว';
  }

  @override
  String get deskSetDlgRemoveFilesKept => 'เก็บไฟล์ไว้';

  @override
  String deskSetDlgRemoveTitle(String name) {
    return 'นำ $name ออกไหม?';
  }

  @override
  String get deskSetDlgRemoveWhat => 'สิ่งที่จะนำออก';

  @override
  String get deskSetDlgRemoveFromList => 'นำออกจากรายการ';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'ไฟล์ยังอยู่ใน $folder เพิ่มกระเป๋าเงิน จะนำกลับมา';
  }

  @override
  String get deskSetDlgDeleteWallet => 'ลบกระเป๋าเงิน';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'ลบคีย์และฐานข้อมูลออกจาก $folder มีเพียงวลีกู้คืนที่กู้คืนได้ หากไม่มีวลี เหรียญจะหายไป';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'ถ้าจะลบไฟล์ด้วย ให้ปลดล็อกกระเป๋าเงินนี้ แล้วใช้ ลบกระเป๋าเงิน ที่ การตั้งค่า › กระเป๋าเงินนี้';

  @override
  String get deskSetDlgRemoveUnlock => 'ปลดล็อกกระเป๋าเงินนี้';

  @override
  String get deskSetDlgRemoveIrreversible => 'ย้อนกลับไม่ได้';

  @override
  String get deskSetDlgRemoveIrreversibleBody =>
      'มีเพียงวลีกู้คืนที่กู้กระเป๋าเงินคืนได้ หากไม่มีวลี เหรียญจะหายไปถาวร';

  @override
  String get deskSetDlgRemoveName => 'ชื่อกระเป๋าเงิน';

  @override
  String deskSetDlgRemoveTypeName(String name) {
    return 'พิมพ์ $name เพื่อยืนยัน';
  }

  @override
  String get deskSetDlgRemoveNameMismatch => 'ชื่อไม่ตรงกัน';

  @override
  String get deskSetDlgPassword => 'รหัสผ่าน';

  @override
  String get deskSetDlgPhraseWritten => 'จดวลีกู้คืนไว้แล้ว';

  @override
  String get deskSetDlgRemoving => 'กำลังนำออก…';

  @override
  String get deskSetDlgWalletLocked => 'กระเป๋าเงินล็อกอยู่';

  @override
  String get deskSetDlgDeleteTitle => 'ลบกระเป๋าเงินนี้ไหม?';

  @override
  String get deskSetDlgDeleteDesc =>
      'ลบกระเป๋าเงินและ seed ออกจากคอมพิวเตอร์นี้ มีเพียงวลีกู้คืนที่กู้คืนได้ หากไม่มีวลี เหรียญจะหายไป';

  @override
  String get deskSetFrameTitle => 'การตั้งค่า';

  @override
  String get deskSetFrameSections => 'หมวดการตั้งค่า';

  @override
  String get deskSetFrameNode => 'โหนด';

  @override
  String get deskSetFramePrivacy => 'ความเป็นส่วนตัว';

  @override
  String get deskSetFrameAppearance => 'การแสดงผล';

  @override
  String get deskSetFrameThisWallet => 'กระเป๋าเงินนี้';

  @override
  String get deskSetFrameAllWallets => 'กระเป๋าเงินทั้งหมด';

  @override
  String get deskSetFramePhrase => 'วลีกู้คืน';

  @override
  String get deskSetFrameRescan => 'ตรวจยอดใหม่';

  @override
  String get deskSetFrameAbout => 'เกี่ยวกับ';

  @override
  String get deskSetFrameHelp => 'ช่วยเหลือ';

  @override
  String get deskSetFrameHealthOn => 'ทำงาน';

  @override
  String get deskSetFrameHealthSlow => 'ช้า';

  @override
  String get deskSetFrameNotResponding => 'ไม่ตอบสนอง';

  @override
  String get deskSetFrameOff => 'ปิด';

  @override
  String get deskSetFrameChecking => 'กำลังตรวจ…';

  @override
  String get deskSetFrameNodeSynced => 'ซิงก์แล้ว';

  @override
  String get deskSetFrameNodeSyncing => 'กำลังซิงก์';

  @override
  String get deskSetFrameConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get deskSetFrameListening => 'รอรับอยู่';

  @override
  String deskSetFrameHealthLatency(String word, int ms) {
    return '$word · $ms ms';
  }

  @override
  String get deskSetFrameNever => 'ไม่เคย';

  @override
  String get deskSetFrameJustNow => 'เมื่อสักครู่';

  @override
  String deskSetFrameMinAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count นาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ชั่วโมงที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วันที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get deskSetComboOpens => 'เปิดรายการ';

  @override
  String get deskSetComboNoAnswer => 'ยังไม่ตอบ';

  @override
  String deskSetComboUse(String host) {
    return 'ใช้ $host';
  }

  @override
  String get deskSetLnodeDidNotStart => 'โหนดไม่เริ่มทำงาน';

  @override
  String get deskSetLnodeDidNotStop => 'โหนดไม่หยุด';

  @override
  String get deskSetLnodeDidNotRestart => 'โหนดไม่เริ่มใหม่';

  @override
  String get deskSetLnodeMoved => 'ย้ายข้อมูลบล็อกเชนแล้ว';

  @override
  String get deskSetLnodeFolderChanged => 'เปลี่ยนโฟลเดอร์ข้อมูลแล้ว';

  @override
  String get deskSetLnodeFolderFailed => 'โฟลเดอร์ไม่เปลี่ยน';

  @override
  String get deskSetLnodeStart => 'เริ่ม';

  @override
  String get deskSetLnodeStop => 'หยุด';

  @override
  String get deskSetLnodeRestart => 'เริ่มใหม่';

  @override
  String get deskSetLnodeTabStatus => 'สถานะ';

  @override
  String get deskSetLnodeTabPeers => 'Peer';

  @override
  String get deskSetLnodeWhileSyncing => 'ระหว่างซิงก์';

  @override
  String deskSetLnodeWhileSyncingText(String host) {
    return 'ใช้ $host จนกว่าโหนดในเครื่องจะซิงก์เสร็จ';
  }

  @override
  String get deskSetLnodeChange => 'เปลี่ยน…';

  @override
  String deskSetLnodeUseWhileSyncing(String host) {
    return 'ใช้ $host ระหว่างซิงก์';
  }

  @override
  String get deskSetLnodeDataFolder => 'โฟลเดอร์ข้อมูล';

  @override
  String deskSetLnodeUsed(String size) {
    return 'ใช้ไป $size';
  }

  @override
  String get deskSetLnodeFreeUnknown => 'ไม่ทราบพื้นที่ว่าง';

  @override
  String deskSetLnodeFree(String size) {
    return 'ว่าง $size';
  }

  @override
  String get deskSetLnodeOpen => 'เปิด';

  @override
  String get deskSetLnodeFolderNotOpened => 'เปิดโฟลเดอร์ไม่ได้';

  @override
  String get deskSetLnodeChainData => 'ข้อมูลบล็อกเชน';

  @override
  String get deskSetLnodeChainPointed =>
      'โหนดนี้อ่านโฟลเดอร์ของโปรแกรมอื่น ให้ลบที่โปรแกรมนั้น';

  @override
  String get deskSetLnodeChainText =>
      'ใช้ข้อมูลบล็อกเชนที่โหนด Epic อื่นทิ้งไว้บนคอมพิวเตอร์นี้ หรือลบข้อมูลของโหนดนี้แล้วดาวน์โหลดบล็อกเชนใหม่';

  @override
  String get deskSetLnodeReuse => 'ใช้ข้อมูลที่มีอยู่…';

  @override
  String get deskSetLnodeDelete => 'ลบ…';

  @override
  String get deskSetLnodeAutostart => 'เริ่มพร้อมแอป';

  @override
  String get deskSetLnodeAutostartHint =>
      'เริ่มโหนดเมื่อเปิดแอป และซิงก์ต่อเนื่องขณะแอปเปิดอยู่';

  @override
  String get deskSetLnodeViewLog => 'ดูบันทึกโหนด';

  @override
  String get deskSetLnodeChangeFolder => 'เปลี่ยนโฟลเดอร์…';

  @override
  String deskSetLnodeUseMeanwhile(String host) {
    return 'ใช้ $host ระหว่างนี้';
  }

  @override
  String get deskSetLnodeWaitingPeers => 'รอ peer';

  @override
  String get deskSetLnodeSyncingLower => 'กำลังซิงก์';

  @override
  String deskSetLnodeStageUsing(String stage, String host) {
    return '$stage · ใช้ $host ระหว่างนี้';
  }

  @override
  String get deskSetLnodeNothingUntilSynced =>
      'ส่งหรือรับไม่ได้จนกว่าโหนดในเครื่องจะซิงก์เสร็จ';

  @override
  String get deskSetLnodeAtTip => 'ล่าสุด';

  @override
  String get deskSetLnodeStalledDetail =>
      'ไม่คืบหน้า 5 นาที เริ่มใหม่ไปแล้วหนึ่งครั้ง';

  @override
  String get deskSetLnodeNoProgress => 'โหนดไม่คืบหน้า';

  @override
  String get deskSetLnodeNoProgressText => 'เริ่มใหม่ หรือดูบันทึกของโหนด';

  @override
  String deskSetLnodePortInUse(String port) {
    return 'พอร์ต $port ถูกโปรแกรมอื่นใช้อยู่';
  }

  @override
  String get deskSetLnodePortInUseText =>
      'ปิดโปรแกรมอื่นนั้น หรือเลือกโหนดนั้นใน เซิร์ฟเวอร์โหนด';

  @override
  String get deskSetLnodeDiskLow => 'ไดรฟ์นี้มีพื้นที่ว่างไม่ถึง 2 GB';

  @override
  String get deskSetLnodeDiskLowText =>
      'เพิ่มพื้นที่ว่าง หรือเปลี่ยนโฟลเดอร์ข้อมูล';

  @override
  String get deskSetLnodeMissing => 'การติดตั้งนี้ไม่มีโปรแกรมโหนด';

  @override
  String get deskSetLnodeMissingText => 'ติดตั้งกระเป๋าเงินใหม่';

  @override
  String get deskSetLnodeStopped => 'โหนดหยุดทำงานเอง';

  @override
  String get deskSetLnodeStoppedText => 'บันทึกบรรทัดท้าย ๆ อาจบอกสาเหตุ';

  @override
  String deskSetLnodeUsesMeanwhile(String host) {
    return 'กระเป๋าเงินใช้ $host ระหว่างนี้';
  }

  @override
  String get deskSetLnodeNothingUntilRuns => 'ส่งไม่ได้จนกว่าโหนดจะทำงาน';

  @override
  String get deskSetLnodeTilePeers => 'Peer';

  @override
  String get deskSetLnodeTileSync => 'ซิงก์';

  @override
  String get deskSetLnodeTileDownload => 'ดาวน์โหลด';

  @override
  String deskSetLnodeSoFar(String size) {
    return 'ได้ $size แล้ว';
  }

  @override
  String get deskSetLnodeTileDisk => 'ข้อมูลบล็อกเชนบนดิสก์';

  @override
  String deskSetLnodeThisSession(String size) {
    return '+$size ในรอบนี้';
  }

  @override
  String deskSetLnodeVersion(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String deskSetLnodeRunning(String duration) {
    return 'ทำงานมา $duration';
  }

  @override
  String deskSetLnodeStoppedAt(String time) {
    return 'หยุดเมื่อ $time';
  }

  @override
  String deskSetLnodePeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เชื่อมต่อ $count peer',
    );
    return '$_temp0';
  }

  @override
  String deskSetLnodeMoving(String done, String total) {
    return 'กำลังย้ายข้อมูลบล็อกเชน · $done จาก $total';
  }

  @override
  String get deskSetLnodeConnectingPeers => 'กำลังเชื่อมต่อ peer';

  @override
  String deskSetLnodeStartedSecAgo(int seconds) {
    return 'เริ่มเมื่อ $seconds วินาทีที่แล้ว';
  }

  @override
  String deskSetLnodeStartedAgo(String duration) {
    return 'เริ่มเมื่อ $duration ที่แล้ว';
  }

  @override
  String get deskSetLnodeSettingsChanged => 'การตั้งค่าเปลี่ยนแล้ว';

  @override
  String get deskSetLnodeSettingsChangedText =>
      'จะมีผลเมื่อเริ่มใหม่ครั้งถัดไป';

  @override
  String get deskSetLnodeRestartNow => 'เริ่มใหม่ตอนนี้';

  @override
  String get deskSetLnodeSampled => 'อัปเดตทุก 30 วินาทีขณะเปิดหน้านี้';

  @override
  String get deskSetLnodeTomlEdited =>
      'epic-server.toml ถูกแก้ด้วยมือ การตั้งค่า peer และโฟลเดอร์ที่นี่จึงไม่มีผล';

  @override
  String get deskSetLnodeSyncProgress => 'ความคืบหน้าการซิงก์';

  @override
  String get deskSetLnodeStepHeaders => 'Header';

  @override
  String get deskSetLnodeStepChainState => 'สถานะเชน';

  @override
  String get deskSetLnodeStepBlocks => 'บล็อก';

  @override
  String get deskSetLnodeStepsNone => 'ขั้นตอนการซิงก์: ยังไม่เริ่ม';

  @override
  String deskSetLnodeStepOf(int n, String name) {
    return 'ขั้นตอนการซิงก์ $n จาก 4: $name';
  }

  @override
  String deskSetLndAskTitle(String host) {
    return 'ใช้ $host จนกว่าโหนดในเครื่องจะซิงก์เสร็จไหม?';
  }

  @override
  String deskSetLndAskDesc(String host) {
    return '$host ซึ่งเป็นโหนดสาธารณะ ใช้แทนได้จนกว่าโหนดในเครื่องจะซิงก์เสร็จ';
  }

  @override
  String get deskSetLndAskNote =>
      'ถามครั้งเดียว เปลี่ยนโหนดและตัวเลือกนี้ได้ที่ การตั้งค่า › โหนด › ระหว่างซิงก์';

  @override
  String get deskSetLndAskWait => 'รอโหนดในเครื่อง';

  @override
  String deskSetLndAskUse(String host) {
    return 'ใช้ $host';
  }

  @override
  String get deskSetLndPickTitle => 'โหนดระหว่างซิงก์';

  @override
  String get deskSetLndPickDesc =>
      'โหนดสาธารณะที่กระเป๋าเงินใช้จนกว่าโหนดในเครื่องจะซิงก์เสร็จ';

  @override
  String get deskSetLndDeleted => 'ลบข้อมูลบล็อกเชนแล้ว';

  @override
  String deskSetLndFreed(String size) {
    return 'ได้พื้นที่คืน $size';
  }

  @override
  String get deskSetLndNotDeleted => 'ไม่ได้ลบข้อมูลบล็อกเชน';

  @override
  String get deskSetLndDeleteTitle => 'ลบข้อมูลบล็อกเชน';

  @override
  String deskSetLndDeleteDesc(String size, String path) {
    return 'ลบ $size ออกจาก $path บล็อกเชนจะดาวน์โหลดใหม่เมื่อเริ่มครั้งถัดไป คีย์และประวัติยังอยู่';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'ลบข้อมูลบล็อกเชนออกจาก $path โหนดจะหยุด และบล็อกเชนทั้งหมดจะดาวน์โหลดใหม่เมื่อเริ่มครั้งถัดไป (หลายชั่วโมง) คีย์และประวัติของกระเป๋าเงินไม่ได้รับผลกระทบ';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'พิมพ์ $word เพื่อยืนยัน';
  }

  @override
  String deskSetLndTypeToConfirmLabel(String word) {
    return 'พิมพ์ $word เพื่อยืนยัน';
  }

  @override
  String get deskSetLndSourceCli => 'epic (โหนดแบบ command line)';

  @override
  String get deskSetLndSourceGui => 'Epic GUI';

  @override
  String get deskSetLndSourceBundled => 'Epic Wallet รุ่นก่อน';

  @override
  String get deskSetLndSourceCustom => 'โฟลเดอร์อื่น';

  @override
  String get deskSetLndInUse => 'ใช้ข้อมูลบล็อกเชนนี้แล้ว';

  @override
  String get deskSetLndNotInUse => 'ไม่ได้ใช้โฟลเดอร์นี้';

  @override
  String get deskSetLndReuseTitle => 'พบข้อมูลบล็อกเชน';

  @override
  String get deskSetLndReuseDesc =>
      'โหนด Epic อื่นทิ้งข้อมูลบล็อกเชนไว้ที่นี่ โหนดในเครื่องอ่านโฟลเดอร์นั้นแทนการดาวน์โหลดบล็อกเชนได้';

  @override
  String get deskSetLndLooking => 'กำลังค้นหา…';

  @override
  String get deskSetLndUseIt => 'ใช้ข้อมูลนี้';

  @override
  String deskSetLndLastWritten(String date) {
    return 'เขียนล่าสุด $date';
  }

  @override
  String get deskSetLndLocked => 'โปรแกรมอื่นใช้อยู่';

  @override
  String get deskSetLndNothingCopied =>
      'ไม่มีการคัดลอก: โหนดอ่านโฟลเดอร์นั้น และ ลบข้อมูลบล็อกเชน จะปิดไว้สำหรับโฟลเดอร์นั้น';

  @override
  String get deskSetLndFresh => 'ดาวน์โหลดใหม่';

  @override
  String deskSetLndFreshLine(String size) {
    return 'ลงในโฟลเดอร์ของกระเป๋าเงินเอง ประมาณ $size';
  }

  @override
  String get deskSetLndLogTitle => 'บันทึกโหนด';

  @override
  String get deskSetLndReading => 'กำลังอ่าน…';

  @override
  String get deskSetLndLogNote =>
      '200 บรรทัดสุดท้ายของ epic-server.log ในโฟลเดอร์ข้อมูล ใหม่สุดอยู่ด้านล่าง';

  @override
  String get deskSetLndCopied => 'คัดลอกแล้ว';

  @override
  String deskSetLndLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count บรรทัด',
    );
    return '$_temp0';
  }

  @override
  String get deskSetLndBadFolder => 'โฟลเดอร์นั้นใช้ไม่ได้';

  @override
  String get deskSetLndChooseAnother => 'เลือกโฟลเดอร์อื่น';

  @override
  String deskSetLndMoveTitle(String size, String folder) {
    return 'ย้าย $size ไปที่ $folder ไหม?';
  }

  @override
  String get deskSetLndMoveDesc =>
      'โหนดจะหยุดระหว่างย้ายข้อมูล แล้วเริ่มใหม่จากโฟลเดอร์ใหม่ ส่วน เริ่มใหม่ที่นั่น จะดาวน์โหลดบล็อกเชนลงในโฟลเดอร์นั้นแทน';

  @override
  String get deskSetLndStartFresh => 'เริ่มใหม่ที่นั่น';

  @override
  String get deskSetLndMove => 'ย้าย';

  @override
  String get deskSetLndProbNotEmpty => 'โฟลเดอร์ไม่ว่าง';

  @override
  String get deskSetLndProbInsideSource => 'โฟลเดอร์นี้อยู่ในโฟลเดอร์ปัจจุบัน';

  @override
  String get deskSetLndProbSourceInside => 'โฟลเดอร์ปัจจุบันอยู่ในโฟลเดอร์นี้';

  @override
  String deskSetLndProbSpace(String needed, String free) {
    return 'พื้นที่ไม่พอ: ต้องใช้ $needed ว่าง $free';
  }

  @override
  String deskSetLndProbSpaceUnknown(String needed) {
    return 'พื้นที่ไม่พอ: ต้องใช้ $needed ไม่ทราบพื้นที่ว่าง';
  }

  @override
  String get deskSetLndProbLocked => 'โปรแกรมอื่นใช้โฟลเดอร์ปัจจุบันอยู่';

  @override
  String get deskSetLndProbMissing => 'ไม่พบข้อมูลบล็อกเชนปัจจุบัน';

  @override
  String get deskSetLndProbNotWritable => 'เขียนลงโฟลเดอร์นี้ไม่ได้';

  @override
  String get deskSetLndProbIncomplete => 'ข้อมูลบล็อกเชนปัจจุบันไม่ครบ';

  @override
  String get deskSetLndProbForeign =>
      'มีข้อมูลบล็อกเชนของโปรแกรมอื่นอยู่ที่นั่น';

  @override
  String get deskSetPeersBannedToast => 'แบน peer แล้ว';

  @override
  String get deskSetPeersUnbannedToast => 'ยกเลิกการแบน peer แล้ว';

  @override
  String deskSetPeersNotAddress(String port) {
    return 'ไม่ใช่ IP address และพอร์ต เช่น 203.0.113.5:$port';
  }

  @override
  String get deskSetPeersAlreadyPreferred => 'อยู่ในรายการแล้ว';

  @override
  String deskSetPeersMaxRange(int min, int max) {
    return '$min ถึง $max';
  }

  @override
  String get deskSetPeersReading => 'กำลังอ่าน peer…';

  @override
  String deskSetPeersSummary(int connected, int inbound, int outbound) {
    return 'เชื่อมต่อ $connected · เข้า $inbound · ออก $outbound';
  }

  @override
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  ) {
    return 'เชื่อมต่อ $connected · เข้า $inbound · ออก $outbound · แบน $banned';
  }

  @override
  String get deskSetPeersIn => 'เข้า';

  @override
  String get deskSetPeersOut => 'ออก';

  @override
  String get deskSetPeersBan => 'แบน';

  @override
  String get deskSetPeersColAddress => 'ที่อยู่';

  @override
  String get deskSetPeersColDirection => 'ทิศทาง';

  @override
  String get deskSetPeersColVersion => 'เวอร์ชัน';

  @override
  String get deskSetPeersColHeight => 'บล็อก';

  @override
  String get deskSetPeersColFirstSeen => 'พบครั้งแรก';

  @override
  String get deskSetPeersNone => 'ไม่มี peer เชื่อมต่อ';

  @override
  String deskSetPeersMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อีก $count',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersRefreshed(int seconds) {
    return 'รีเฟรชทุก $seconds วินาที';
  }

  @override
  String get deskSetPeersBanned => 'แบนแล้ว';

  @override
  String deskSetPeersBannedAt(String time) {
    return 'แบนเมื่อ $time';
  }

  @override
  String get deskSetPeersUnban => 'ยกเลิกแบน';

  @override
  String get deskSetPeersPreferred => 'Peer ที่ต้องการ';

  @override
  String get deskSetPeersPreferredLabel =>
      'Peer ที่ต้องการ, IP address และพอร์ต';

  @override
  String get deskSetPeersAdd => 'เพิ่ม';

  @override
  String get deskSetPeersMaxIn => 'ขาเข้าสูงสุด';

  @override
  String get deskSetPeersMaxInLabel => 'Peer ขาเข้าสูงสุด';

  @override
  String get deskSetPeersMaxOut => 'ขาออกสูงสุด';

  @override
  String get deskSetPeersMaxOutLabel => 'Peer ขาออกสูงสุด';

  @override
  String deskSetPeersPreferredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ที่ต้องการ $count:',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersForget(String peer) {
    return 'ลบ $peer';
  }

  @override
  String deskSetPeersNote(int min, int max, int def) {
    return 'สูงสุดขาเข้าและขาออก: $min ถึง $max (ค่าเริ่มต้น $def)';
  }

  @override
  String get deskSetLndDeleteQuestion => 'ลบข้อมูลบล็อกเชนไหม?';

  @override
  String get deskSetLogsMemoryOnly => 'บันทึกเก็บไว้ในหน่วยความจำเท่านั้น';

  @override
  String get deskSetLogsClearTitle => 'ล้างบันทึกไหม?';

  @override
  String get deskSetLogsClearDesc =>
      'ลบไฟล์บันทึก รายงานที่ส่งภายหลังจะมีเฉพาะสิ่งที่บันทึกตั้งแต่นี้';

  @override
  String get deskSetLogsKeep => 'เก็บบันทึกไว้';

  @override
  String get deskSetLogsClear => 'ล้างบันทึก';

  @override
  String get deskSetLogsCleared => 'ล้างบันทึกแล้ว';

  @override
  String deskSetLogsToday(String time) {
    return 'วันนี้ $time';
  }

  @override
  String deskSetLogsTomorrow(String time) {
    return 'พรุ่งนี้ $time';
  }

  @override
  String get deskSetLogsTitle => 'บันทึก';

  @override
  String get deskSetLogsLevel => 'ระดับบันทึก';

  @override
  String get deskSetLogsLevelNormal =>
      'ปกติ แบบละเอียดจะเก็บบรรทัดมากขึ้นบนดิสก์ 24 ชั่วโมง ที่อยู่อาจปรากฏในไฟล์ แต่รายงานจะตัดออก';

  @override
  String deskSetLogsLevelDetailed(String until) {
    return 'ละเอียดถึง $until แล้วกลับเป็นปกติ ที่อยู่อาจปรากฏในไฟล์ แต่รายงานจะตัดออก';
  }

  @override
  String deskSetLogsLevelDetailedCore(String until) {
    return 'ละเอียดถึง $until แล้วกลับเป็นปกติ ที่อยู่อาจปรากฏในไฟล์ แต่รายงานจะตัดออก บรรทัดของแกนกระเป๋าเงินจะละเอียดตั้งแต่เปิดแอปครั้งถัดไป';
  }

  @override
  String get deskSetLogsNormal => 'ปกติ';

  @override
  String get deskSetLogsDetailed => 'ละเอียด';

  @override
  String get deskSetLogsFiles => 'ไฟล์บันทึก';

  @override
  String deskSetLogsSize(String size, String max) {
    return 'ขนาดปัจจุบัน $size จาก $max เก็บไฟล์เก่าไว้หนึ่งไฟล์';
  }

  @override
  String get deskSetLogsOpenFolder => 'เปิดโฟลเดอร์บันทึก';

  @override
  String deskSetNodePortNote(String port) {
    return 'ตรวจที่อยู่และพอร์ต (ปกติคือ $port)';
  }

  @override
  String deskSetNodeListNote(String site) {
    return 'สถานะจาก $site เวลาตอบสนองวัดจากคอมพิวเตอร์นี้';
  }

  @override
  String get deskSetNodeStartTitle => 'เริ่มโหนดในเครื่องไหม?';

  @override
  String get deskSetNodeStartDesc =>
      'โปรแกรมแยกต่างหากจะซิงก์บล็อกเชน Epic บนคอมพิวเตอร์นี้';

  @override
  String get deskSetNodeStartLine1 =>
      'ดาวน์โหลดบล็อกเชนทั้งหมด: ใช้พื้นที่ดิสก์และแบนด์วิดท์หลาย GB';

  @override
  String get deskSetNodeStartLine2 =>
      'การซิงก์ครั้งแรกใช้เวลาหลายชั่วโมง ระหว่างนั้นโหนดจะแสดง กำลังซิงก์';

  @override
  String get deskSetNodeStartLine3 =>
      'ไฟร์วอลล์อาจถามว่าจะอนุญาตโปรแกรมโหนดไหม';

  @override
  String get deskSetNodeStartButton => 'เริ่มโหนดในเครื่อง';

  @override
  String get deskSetNodeRowNotSetUp => 'ยังไม่ได้ตั้งค่า';

  @override
  String get deskSetNodeRowStopped => 'หยุดอยู่';

  @override
  String get deskSetNodeRowStarting => 'กำลังเริ่ม';

  @override
  String deskSetNodeRowSyncingPct(String percent) {
    return 'กำลังซิงก์ $percent';
  }

  @override
  String get deskSetNodeRowStalled => 'ค้าง';

  @override
  String get deskSetNodeRowFailed => 'ล้มเหลว';

  @override
  String get deskSetNodeLocalInUse => 'ใช้โหนดในเครื่องแล้ว';

  @override
  String get deskSetNodeLocalInUseText =>
      'จะดาวน์โหลดบล็อกเชนทั้งหมด ต้องมีพื้นที่ว่าง 5 GB';

  @override
  String get deskSetNodeLocalNode => 'โหนดในเครื่อง';

  @override
  String get deskSetNodeGroupComputer => 'คอมพิวเตอร์นี้';

  @override
  String get deskSetNodeServer => 'เซิร์ฟเวอร์โหนด';

  @override
  String get deskSetNodeServerHint =>
      'โหนดที่กระเป๋าเงินใช้อ่านบล็อกเชนและส่งธุรกรรม';

  @override
  String get deskSetNodeChecking => 'กำลังตรวจโหนด…';

  @override
  String get deskSetNodeBackground => 'ซิงก์เบื้องหลัง';

  @override
  String get deskSetNodeBackgroundHint => 'ซิงก์ต่อขณะแอปปิดอยู่';

  @override
  String get deskSetPhraseNotCopied => 'ไม่ได้คัดลอก';

  @override
  String get deskSetPhraseClipboardRefused => 'คลิปบอร์ดไม่รับข้อความ';

  @override
  String get deskSetPhraseCopied => 'คัดลอกวลีแล้ว';

  @override
  String get deskSetPhraseCleared => 'คลิปบอร์ดจะถูกล้างใน 60 วินาที';

  @override
  String get deskSetPhraseEnterPassword => 'ใส่รหัสผ่าน';

  @override
  String get deskSetPhraseWrongPassword => 'รหัสผ่านไม่ถูกต้อง';

  @override
  String get deskSetPhraseIntro =>
      'จดคำลงกระดาษตามลำดับนี้ ห้ามพิมพ์ลงในเว็บไซต์หรือแชต';

  @override
  String get deskSetPhrasePanel => 'ใส่รหัสผ่านเพื่อแสดงคำ';

  @override
  String get deskSetPhraseShowWords => 'แสดงวลีกู้คืน';

  @override
  String deskSetPhraseWordsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วลีกู้คืน $count คำ',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPhraseHideQr => 'ซ่อน QR';

  @override
  String get deskSetPhraseShowQr => 'แสดง QR';

  @override
  String get deskSetPhraseHideWords => 'ซ่อนวลีกู้คืน';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return 'ซ่อนใน $seconds วินาที';
  }

  @override
  String get deskSetPhraseQrLabel => 'QR Code ของวลีกู้คืน';

  @override
  String get deskSetPhraseBackUp => 'สำรองวลี';

  @override
  String get deskSetPhraseBackUpText =>
      'ใครมีคำเหล่านี้ก็เอา EPIC ไปได้ ตรวจดูว่าไม่มีใครเห็นหน้าจอ';

  @override
  String get deskSetPrivTorOnFailed => 'ไม่ได้เปิด Tor';

  @override
  String get deskSetPrivTorOffFailed => 'ไม่ได้ปิด Tor';

  @override
  String get deskSetPrivTor => 'Tor';

  @override
  String get deskSetPrivSwitching => 'กำลังสลับ Tor';

  @override
  String get deskSetPrivTurnOff => 'ปิด Tor';

  @override
  String get deskSetPrivNotInBuild => 'ไม่มีในรุ่นนี้';

  @override
  String get deskSetPrivStarting => 'กำลังเริ่ม…';

  @override
  String deskSetPrivStartingDetail(int progress) {
    return '$progress% ทุกการเชื่อมต่อรอ Tor';
  }

  @override
  String get deskSetPrivNotPublished =>
      'ยังไม่ได้เผยแพร่ที่อยู่ Tor การส่งใช้ได้';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem การส่งใช้ได้';
  }

  @override
  String get deskSetPrivConnected => 'เชื่อมต่อแล้ว';

  @override
  String get deskSetPrivNotConnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get deskSetPrivStoppedDetail => 'Tor หยุดแล้ว ลองอีกครั้ง หรือปิด Tor';

  @override
  String deskSetPrivProblemDetail(String problem) {
    return '$problem ลองอีกครั้ง หรือปิด Tor';
  }

  @override
  String get deskSetPrivStatusSite => 'เว็บสถานะ';

  @override
  String deskSetPrivUseStatus(String site) {
    return 'ใช้ $site';
  }

  @override
  String get deskSetPrivUseStatusHint =>
      'แสดงว่าโหนดและเซิร์ฟเวอร์ Epicbox ใดออนไลน์อยู่ ดาวน์โหลดเพียงรายการสาธารณะ ไม่มีการส่งข้อมูลใดจากกระเป๋าเงิน';

  @override
  String deskSetRecvMethodOnFailed(String method) {
    return 'ไม่ได้เปิด $method';
  }

  @override
  String deskSetRecvMethodOffFailed(String method) {
    return 'ไม่ได้ปิด $method';
  }

  @override
  String get deskSetRecvServerNotChanged => 'ไม่ได้เปลี่ยนเซิร์ฟเวอร์';

  @override
  String get deskSetRecvReceiving => 'การรับเงิน';

  @override
  String deskSetRecvSwitching(String method) {
    return 'กำลังสลับการรับผ่าน $method';
  }

  @override
  String deskSetRecvMethodReceiving(String method) {
    return 'รับผ่าน $method';
  }

  @override
  String get deskSetRecvNotSaved => 'ไม่ได้บันทึก';

  @override
  String get deskSetRecvAutostart => 'เริ่มพร้อมกระเป๋าเงิน';

  @override
  String get deskSetRecvAutostartHint => 'เปิดเมื่อปลดล็อก';

  @override
  String deskSetRecvMethodAutostart(String method) {
    return '$method: เริ่มพร้อมกระเป๋าเงิน';
  }

  @override
  String get deskSetRecvEpicboxText =>
      'รายการเข้าผ่านเซิร์ฟเวอร์ Epicbox แม้ตอนกระเป๋าเงินปิดอยู่';

  @override
  String get deskSetRecvEpicboxServer => 'เซิร์ฟเวอร์ Epicbox';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'เซิร์ฟเวอร์ที่เก็บรายการของที่อยู่นี้ สองกระเป๋าเงินใช้เซิร์ฟเวอร์ต่างกันได้';

  @override
  String get deskSetRecvSwitchingServer => 'กำลังเปลี่ยนเซิร์ฟเวอร์ Epicbox…';

  @override
  String deskSetRecvListNote(String site) {
    return 'สถานะจาก $site';
  }

  @override
  String get deskSetRecvHttpText =>
      'ตรงจากกระเป๋าเงินอื่นที่ที่อยู่เว็บของคอมพิวเตอร์เครื่องนี้ ขณะที่กระเป๋าเงินนี้เปิดอยู่';

  @override
  String get deskSetRecvHttpOffTitle => 'ปิดอยู่ขณะเปิด Tor';

  @override
  String get deskSetRecvHttpOffText =>
      'รายการตรงจากกระเป๋าเงินอื่นจะเข้าที่ที่อยู่ ลิงก์ · Tor แทน';

  @override
  String get deskSetRecvPrivacySettings => 'การตั้งค่าความเป็นส่วนตัว';

  @override
  String get deskSetHttpNotChanged => 'ไม่ได้เปลี่ยน';

  @override
  String get deskSetHttpPortError => 'พอร์ตต้องอยู่ระหว่าง 1 ถึง 65535';

  @override
  String get deskSetHttpReachable => 'ใครเข้าถึงได้';

  @override
  String get deskSetHttpReachableHint => 'ใครจ่ายมาที่ที่อยู่ HTTP ได้';

  @override
  String get deskSetHttpLocalOnly => 'ในเครื่องเท่านั้น';

  @override
  String get deskSetHttpFromInternet => 'จากอินเทอร์เน็ต';

  @override
  String get deskSetHttpGuideHelp => 'รับจากอินเทอร์เน็ต: ทำงานอย่างไร';

  @override
  String deskSetHttpPublicNote(String port) {
    return 'ตอบทุก interface เราเตอร์ต้อง forward TCP $port มายังคอมพิวเตอร์นี้';
  }

  @override
  String get deskSetHttpPort => 'พอร์ต';

  @override
  String get deskSetHttpPortHint => '1 ถึง 65535 ใช้กับที่อยู่ HTTP';

  @override
  String get deskSetHttpPortLabel => 'พอร์ต HTTP';

  @override
  String get deskSetHttpGuideTitle => 'รับจากอินเทอร์เน็ต';

  @override
  String get deskSetHttpGuideNowPublic => 'ตอนนี้: จากอินเทอร์เน็ต';

  @override
  String get deskSetHttpGuideNowLocal =>
      'ตอนนี้: ในเครื่องเท่านั้น มีเพียงโปรแกรมบนคอมพิวเตอร์นี้ที่เข้าถึงที่อยู่ HTTP ได้';

  @override
  String get deskSetHttpStep1 => 'รอรับทุก interface';

  @override
  String deskSetHttpStep1Text(String port) {
    return 'กระเป๋าเงินจะตอบที่ 0.0.0.0 พอร์ต $port อุปกรณ์อื่นจึงส่งเงินมาได้';
  }

  @override
  String get deskSetHttpStep2 => 'Forward พอร์ต';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'ในหน้าตั้งค่าเราเตอร์ (มักเป็น 10.0.1.1) หา Port forwarding แล้ว forward TCP $port มายังคอมพิวเตอร์นี้';
  }

  @override
  String get deskSetHttpStep3 => 'แชร์ที่อยู่สาธารณะ';

  @override
  String deskSetHttpStep3Text(String port) {
    return 'ผู้ส่งใช้ http://<public IP>:$port โดย public IP อาจเปลี่ยนได้';
  }

  @override
  String get deskSetHttpNoRouter => 'ไม่ได้ตั้งค่าเราเตอร์?';

  @override
  String get deskSetHttpNoRouterText =>
      'Tor ใช้ได้จากทุกที่โดยไม่ต้อง forward อะไร';

  @override
  String get deskSetHttpTurnOnTor => 'เปิด Tor';

  @override
  String get deskSetHttpExposed =>
      'เปิดเฉพาะ API สำหรับรับเงิน HTTP ธรรมดาไม่ได้เข้ารหัส';

  @override
  String get deskSetHttpBackLocal => 'กลับเป็นในเครื่องเท่านั้น';

  @override
  String get deskSetReportNotSent => 'ส่งรายงานไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get deskSetReportSaveDialog => 'บันทึกรายงาน';

  @override
  String get deskSetReportSaved =>
      'บันทึกแล้ว ลบข้อมูลลับออกแล้ว แต่ไม่ได้เข้ารหัส';

  @override
  String get deskSetReportNotSaved => 'บันทึกไฟล์ไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get deskSetReportText => 'ข้อความรายงาน';

  @override
  String deskSetReportAppLog(String size) {
    return 'บันทึกของแอป ($size ล่าสุด)';
  }

  @override
  String get deskSetReportSent => 'ส่งรายงานแล้ว';

  @override
  String get deskSetReportArrived => 'รายงานถึงแล้ว';

  @override
  String deskSetReportArrivedRef(String id) {
    return 'รายงานถึงแล้ว เลขอ้างอิงคือ $id';
  }

  @override
  String get deskSetReportDescribe => 'อธิบายสิ่งที่เกิดขึ้น';

  @override
  String get deskSetReportTitle => 'รายงานปัญหา';

  @override
  String get deskSetReportDesc =>
      'เข้ารหัสให้นักพัฒนาอ่านได้เท่านั้น บันทึกเป็นไฟล์ จะเก็บสำเนาที่ไม่เข้ารหัส';

  @override
  String get deskSetReportWhat => 'เกิดอะไรขึ้น';

  @override
  String get deskSetReportWhatHint =>
      'ทำอะไร คาดว่าจะเกิดอะไร และเกิดอะไรขึ้นแทน';

  @override
  String get deskSetReportContact => 'ช่องทางติดต่อ';

  @override
  String get deskSetReportContactHint => 'อีเมลหรือชื่อบัญชีอื่น สำหรับตอบกลับ';

  @override
  String get deskSetReportAttach => 'แนบบันทึก (แนะนำ)';

  @override
  String get deskSetReportAttachHint =>
      'ส่วนล่าสุดของบันทึกแอป ลบวลี รหัสผ่าน ที่อยู่ IP และโฟลเดอร์ส่วนตัวออกแล้ว';

  @override
  String get deskSetReportSentWhat => 'สิ่งที่ส่ง';

  @override
  String get deskSetReportNotSentTitle => 'ไม่ได้ส่ง';

  @override
  String get deskSetReportOff => 'รุ่นนี้ปิดการส่งรายงาน';

  @override
  String get deskSetReportSaveToFile => 'บันทึกเป็นไฟล์';

  @override
  String get deskSetReportSend => 'ส่ง';

  @override
  String get deskSetRescanComplete => 'สแกนเสร็จแล้ว';

  @override
  String get deskSetRescanStoppedLine => 'หยุดสแกนแล้ว';

  @override
  String get deskSetRescanLog => 'บันทึกการตรวจยอดใหม่';

  @override
  String get deskSetRescanText =>
      'อ่านบล็อกเชนอีกครั้งและคำนวณยอดคงเหลือใหม่ ใช้เมื่อยอดดูไม่ถูกต้องหรือเอาต์พุตยังถูกล็อก';

  @override
  String get deskSetRescanStartAgain => 'เริ่มใหม่';

  @override
  String get deskSetRescanDeleteUnconfirmed => 'ลบรายการที่ยังไม่ยืนยัน';

  @override
  String get deskSetRescanDeleteHint =>
      'ยกเลิกธุรกรรมที่ยังไม่ยืนยันและปลดล็อกเอาต์พุตด้วย รายการที่กำลังส่งอยู่อาจล้มเหลว';

  @override
  String get deskSetRescanScanning =>
      'กำลังสแกนบล็อกเชน ระหว่างนี้ยังใช้กระเป๋าเงินได้ ยอดคงเหลือจะอัปเดตเมื่อสแกนเสร็จ';

  @override
  String get deskSetRescanStopping => 'กำลังหยุด…';

  @override
  String deskSetRescanChecking(int percent) {
    return 'กำลังตรวจ… $percent %';
  }

  @override
  String get deskSetRescanFailed => 'สแกนไม่สำเร็จ';

  @override
  String get deskSetRescanNoneFound => 'ไม่พบธุรกรรมที่ยังไม่ยืนยัน';

  @override
  String get deskSetRescanCancelled =>
      'ยกเลิกธุรกรรมที่ยังไม่ยืนยันและปลดล็อกเอาต์พุตแล้ว';

  @override
  String get deskSetRescanNotRead => 'อ่านไม่ได้';

  @override
  String get deskSetRescanFinished => 'ตรวจยอดใหม่เสร็จแล้ว';

  @override
  String get deskSetRescanUpToDate => 'ยอดคงเหลือเป็นปัจจุบันแล้ว';

  @override
  String get deskSetRescanResumed =>
      'การสแกนทำต่อจากจุดที่หยุด ตัวเลขนับเฉพาะส่วนนั้น';

  @override
  String get deskSetRescanStoppedEarly =>
      'หยุดก่อนจบ อ่านยอดคงเหลือใหม่แล้ว เริ่มใหม่เพื่อทำต่อ';

  @override
  String get deskSetRescanNotDeleted =>
      'ไม่ได้ลบธุรกรรมที่ยังไม่ยืนยัน: จะลบเฉพาะเมื่อสแกนจนจบ';

  @override
  String get deskSetRescanBefore => 'ยอดก่อน';

  @override
  String get deskSetRescanAfter => 'ยอดหลัง';

  @override
  String get deskSetRescanFound => 'เอาต์พุตที่พบ';

  @override
  String get deskSetRescanRestored => 'กู้คืน';

  @override
  String get deskSetRescanRevived => 'กลับมาใช้ได้';

  @override
  String get deskSetRescanUnlocked => 'ปลดล็อก';

  @override
  String get deskSetRescanDeleted => 'ลบ';

  @override
  String deskSetWalletsAddedBack(String name) {
    return 'เพิ่ม $name กลับแล้ว';
  }

  @override
  String get deskSetWalletsNotAddedBack => 'ไม่ได้เพิ่มกลับ';

  @override
  String get deskSetWalletsOpenNow => 'เปิดอยู่';

  @override
  String get deskSetWalletsFolderMissing => 'ไม่พบโฟลเดอร์';

  @override
  String deskSetWalletsShowFolder(String name) {
    return 'แสดง $name ในโฟลเดอร์';
  }

  @override
  String deskSetWalletsRemove(String name) {
    return 'นำ $name ออก…';
  }

  @override
  String get deskSetWalletsRemovedGroup => 'นำออกจากรายการแล้ว';

  @override
  String get deskSetWalletsAddBack => 'เพิ่มกลับ';

  @override
  String get deskSetWalletsAdd => 'เพิ่มกระเป๋าเงิน';

  @override
  String get deskSetWalletsCreate => 'สร้างกระเป๋าเงิน';

  @override
  String get deskSetWalletsCreateText => 'กระเป๋าเงินใหม่พร้อมวลีกู้คืนใหม่';

  @override
  String get deskSetWalletsImport => 'นำเข้ากระเป๋าเงิน';

  @override
  String get deskSetWalletsImportText => 'จาก Epic Wallet รุ่นเก่าหรือโฟลเดอร์';

  @override
  String get deskSetWalletsRestore => 'กู้คืนจากวลีกู้คืน';

  @override
  String get deskSetWalletsRestoreText => 'จากวลีกู้คืน';

  @override
  String get deskSetupConfirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get deskSetupPasswordShort => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get deskSetupPasswordsDiffer => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get deskSetupBack => 'ย้อนกลับ';

  @override
  String get deskSetupNewWalletAdded => 'เพิ่มกระเป๋าเงินใหม่แล้ว';

  @override
  String get deskSetupCapsLock => 'Caps Lock เปิดอยู่';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return 'ขั้นตอน $number จาก $total: $label';
  }

  @override
  String get deskSetupTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskSetupNotSaved => 'ไม่ได้บันทึก';

  @override
  String get deskSetupStepPrefs => 'การตั้งค่าแอป';

  @override
  String get deskSetupStepNode => 'โหนด';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupStepReview => 'ตรวจสอบ';

  @override
  String get deskSetupAgain =>
      'กำลังตั้งค่าใหม่ ไม่มีอะไรเปลี่ยนจนกว่าจะกด บันทึก ในขั้นตอนสุดท้าย';

  @override
  String get deskSetupPrefsLead => 'ภาษาของแอป';

  @override
  String get deskSetupNodeTitle => 'เลือกโหนด';

  @override
  String get deskSetupNodeLead =>
      'กระเป๋าเงินอ่านบล็อกเชนและส่งธุรกรรมผ่านโหนด Epic';

  @override
  String get deskSetupLocalTitle => 'โหนดในเครื่อง';

  @override
  String get deskSetupLocalLead =>
      'การรันโหนดที่นี่หมายถึงอะไร และจะใช้โหนดไหน';

  @override
  String get deskSetupEpicboxTitle => 'รับเงินแม้ออฟไลน์';

  @override
  String get deskSetupReviewTitle => 'ตรวจการตั้งค่า';

  @override
  String get deskSetupReviewLead => 'แก้สิ่งที่ไม่ถูกต้อง แล้วบันทึก';

  @override
  String get deskSetupSideTitle => 'ตั้งค่า';

  @override
  String get deskSetupBackToWallet => 'กลับไปที่กระเป๋าเงิน';

  @override
  String get deskSetupSave => 'บันทึกการตั้งค่า';

  @override
  String get deskSetupLanguage => 'ภาษา';

  @override
  String get deskSetupNodeServer => 'เซิร์ฟเวอร์โหนด';

  @override
  String get deskSetupCheckingNodes => 'กำลังตรวจโหนด…';

  @override
  String get deskSetupPickNode => 'เลือกโหนด';

  @override
  String get deskSetupRemoteNode => 'โหนดระยะไกล';

  @override
  String get deskSetupRemoteNodeText => 'โหนดสาธารณะใดก็ได้ ใช้ได้ทันที';

  @override
  String get deskSetupLocalNodeText =>
      'รันบนคอมพิวเตอร์นี้: เป็นส่วนตัว แต่ต้องใช้พื้นที่ดิสก์และการซิงก์ครั้งแรก';

  @override
  String get deskSetupEpicboxText =>
      'Epicbox ส่งรายการไปยังที่อยู่ Epicbox และเก็บไว้จนกว่ากระเป๋าเงินจะออนไลน์';

  @override
  String get deskSetupEpicboxPrivacy =>
      'เซิร์ฟเวอร์ Epicbox เห็นที่อยู่ IP ของคอมพิวเตอร์นี้';

  @override
  String get deskSetupEpicboxServer => 'เซิร์ฟเวอร์ Epicbox';

  @override
  String get deskSetupChangePrefsSem => 'เปลี่ยนการตั้งค่าแอป';

  @override
  String get deskSetupChangeNodeSem => 'เปลี่ยนโหนด';

  @override
  String get deskSetupChangeEpicboxSem => 'เปลี่ยน Epicbox';

  @override
  String get deskSetupChange => 'เปลี่ยน';

  @override
  String get deskSetupType => 'ประเภท';

  @override
  String get deskSetupAddress => 'ที่อยู่';

  @override
  String deskSetupExistingNode(String host) {
    return 'โหนดที่มีอยู่ที่ $host';
  }

  @override
  String get deskSetupBundledNode => 'โหนดในเครื่อง ที่มากับแอป';

  @override
  String get deskSetupWhileSyncing => 'ระหว่างซิงก์';

  @override
  String get deskSetupWait => 'รอ';

  @override
  String get deskSetupDataFolder => 'โฟลเดอร์ข้อมูล';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'บันทึก จะเริ่มโหนด และใช้ $node แทนจนกว่าจะซิงก์เสร็จ';
  }

  @override
  String get deskSetupSaveStarts =>
      'บันทึก จะเริ่มโหนด การซิงก์ครั้งแรกใช้เวลาหลายชั่วโมง ระหว่างนั้นกระเป๋าเงินจะเปิดใช้ได้';

  @override
  String get deskSetupServer => 'เซิร์ฟเวอร์';

  @override
  String get deskSetupOff => 'ปิด';

  @override
  String get deskSetAboutLicencesLead =>
      'ซอฟต์แวร์โอเพนซอร์สในกระเป๋าเงินนี้ แต่ละรายการมีสัญญาอนุญาตของตัวเอง';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop โดย BT Labs: Apache-2.0';

  @override
  String get deskSetAboutBrowserNotOpened => 'เปิดเบราว์เซอร์ไม่ได้';

  @override
  String get deskSetAboutOpen => 'เปิด';

  @override
  String deskSetAboutVersion(String version) {
    return 'เวอร์ชัน  $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'โหนด  $version';
  }

  @override
  String get deskSetAboutCommunity => 'ชุมชน';

  @override
  String get deskSetAboutLicences => 'สัญญาอนุญาต';

  @override
  String get deskSetAboutSource => 'ซอร์สโค้ด';

  @override
  String get deskSetAboutView => 'ดู';

  @override
  String deskSetAboutChecked(String ago) {
    return 'ตรวจเมื่อ $ago';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version เป็นเวอร์ชันล่าสุด';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return 'มีอัปเดต: $version';
  }

  @override
  String get deskSetAboutCouldNotCheck => 'ตรวจไม่ได้';

  @override
  String get deskSetAboutUpdates => 'อัปเดต';

  @override
  String get deskSetAboutCheckNow => 'ตรวจสอบ';

  @override
  String get deskSetAboutAgoNow => 'เมื่อสักครู่';

  @override
  String deskSetAboutAgoMin(int count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return '$count ชั่วโมงที่แล้ว';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return '$count วันที่แล้ว';
  }

  @override
  String get deskSetAboutCopyLink => 'คัดลอกลิงก์';

  @override
  String get deskSetAboutCopied => 'คัดลอกแล้ว';

  @override
  String get deskSetAboutNotCopied => 'ไม่ได้คัดลอก';

  @override
  String get deskSetAppearTheme => 'ธีม';

  @override
  String get deskSetAppearThemeHint => 'ระบบ ใช้ค่าของคอมพิวเตอร์';

  @override
  String get deskSetAppearSystem => 'ระบบ';

  @override
  String get deskSetAppearDark => 'มืด';

  @override
  String get deskSetAppearLight => 'สว่าง';

  @override
  String get deskSetAppearScale => 'ขนาดอินเทอร์เฟซ';

  @override
  String get deskSetAppearScaleHint =>
      'ปรับขนาดข้อความและปุ่มให้ใหญ่หรือเล็กลง มีผลทันที';

  @override
  String get deskSetAppearLanguage => 'ภาษา';

  @override
  String get deskSetAppearLanguageHint => 'มีผลทันที';

  @override
  String get deskSetAppearHideHint => 'แสดงจุดแทนยอดคงเหลือและจำนวน';

  @override
  String deskSetHelpNoMatchText(String query) {
    return 'ไม่มีหัวข้อที่ตรงกับ “$query” ลองคำอื่น';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'พบ $count หัวข้อ',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'ไม่มีหัวข้อที่ตรงกัน';

  @override
  String get deskSetHelpReportText =>
      'อธิบายสิ่งที่ผิดพลาด แนบบันทึกของแอปที่ลบข้อมูลลับแล้วไปด้วยได้ โดยเข้ารหัสให้นักพัฒนา';

  @override
  String get deskSetHelpShowLess => 'ย่อ';

  @override
  String get deskSetHelpReadMore => 'อ่านต่อ';

  @override
  String get deskSetHelpEb1 =>
      'กระเป๋าเงินผู้ส่งส่งรายการให้ Epicbox และล็อกเอาต์พุต';

  @override
  String get deskSetHelpEb2 =>
      'Epicbox ส่งต่อเมื่อกระเป๋าเงินผู้รับออนไลน์ กระเป๋าเงินนั้นเพิ่มส่วนของตัวเองและลงนาม';

  @override
  String get deskSetHelpEb3 => 'กระเป๋าเงินผู้รับส่งกลับไปที่ Epicbox';

  @override
  String get deskSetHelpEb4 => 'Epicbox ส่งกลับไปยังกระเป๋าเงินผู้ส่ง';

  @override
  String get deskSetHelpSigns =>
      'กระเป๋าเงินผู้ส่งลงนามด้วย ทำธุรกรรมให้เสร็จ และส่งเข้าเครือข่าย';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'เครือข่ายใส่ธุรกรรมลงในบล็อก หลังยืนยันครบ $count ครั้งถือว่าสมบูรณ์',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 =>
      'กระเป๋าเงินผู้ส่งบันทึกไฟล์ธุรกรรมและล็อกเอาต์พุต ไฟล์ไปถึงผู้รับด้วยวิธีใดก็ได้';

  @override
  String get deskSetHelpFile2 =>
      'ผู้รับเปิดไฟล์ กระเป๋าเงินของผู้รับเพิ่มส่วนของตัวเอง ลงนาม และบันทึกไฟล์ตอบกลับ';

  @override
  String get deskSetHelpFile3 => 'ไฟล์ตอบกลับกลับมาถึงผู้ส่ง';

  @override
  String get deskSetHelpFile4 => 'ผู้ส่งเปิดไฟล์ตอบกลับที่ ทำให้เสร็จ';

  @override
  String get deskSetHelpSender => 'ผู้ส่ง';

  @override
  String get deskSetHelpFile => 'โอนไฟล์';

  @override
  String get deskSetHelpRecipient => 'ผู้รับ';

  @override
  String get deskSetHelpNetwork => 'เครือข่าย';

  @override
  String get deskSetHelpTravels => 'ธุรกรรมเดินทางอย่างไร';

  @override
  String get deskSetHelpOverEpicbox => 'ผ่าน Epicbox';

  @override
  String get deskSetHelpWithFile => 'ด้วยไฟล์';

  @override
  String deskSetHelpStep(int number, int total) {
    return 'ขั้นตอน $number จาก $total';
  }

  @override
  String get deskSetHelpSearch => 'ค้นหาความช่วยเหลือ';

  @override
  String get deskSetHelpSearchKeys =>
      'กด / เพื่อค้นหา กด Esc เพื่อล้างการค้นหา';

  @override
  String get deskSetHelpSearchHint => 'เช่น ไฟล์ การยืนยัน วลีกู้คืน';

  @override
  String get deskSetHelpClear => 'ล้างการค้นหา';

  @override
  String get deskSetHelpTourAgain => 'แสดงทัวร์แนะนำอีกครั้ง';

  @override
  String deskSetHelpTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count หัวข้อ',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSecretProtect =>
      'Windows ป้องกันข้อมูลลับของกระเป๋าเงินไม่ได้ (DPAPI ปฏิเสธ) จึงไม่ได้บันทึกอะไร ลงชื่อเข้าใช้ Windows ด้วยบัญชีของคุณเองและรหัสผ่านของบัญชีนั้น ไม่ใช่ผ่านเซสชันระยะไกลหรือเซสชันบริการ แล้วลองอีกครั้ง';

  @override
  String get deskKeyringMissingTitle => 'ไม่พบพวงกุญแจ';

  @override
  String get deskKeyringMissingText =>
      'Epic Cash เก็บการตั้งค่าและรหัสผ่านที่ปิดผนึกของกระเป๋าเงินไว้ในพวงกุญแจของระบบ แต่ไม่มีพวงกุญแจใดตอบกลับ ติดตั้งหรือเริ่มพวงกุญแจ (GNOME Keyring หรือ KWallet) เข้าสู่ระบบเดสก์ท็อปที่ใช้งานพวงกุญแจ แล้วเลือกลองอีกครั้ง';

  @override
  String get deskKeyringLockedTitle => 'พวงกุญแจถูกล็อก';

  @override
  String get deskKeyringLockedText =>
      'Epic Cash เก็บการตั้งค่าและรหัสผ่านที่ปิดผนึกของกระเป๋าเงินไว้ในพวงกุญแจของระบบ ซึ่งถูกล็อกอยู่ ปลดล็อกพวงกุญแจ (ใช้รหัสผ่านเข้าสู่ระบบ) แล้วเลือกลองอีกครั้ง หรือเลือกปลดล็อกตอนนี้เพื่อให้ระบบถามรหัสผ่าน';

  @override
  String get deskKeyringUnlockNow => 'ปลดล็อกตอนนี้';

  @override
  String get txStatusNotDelivered => 'ยังไม่ได้ส่งถึง';

  @override
  String get txDetailsNotDeliveredBody =>
      'รายการนี้ยังไปไม่ถึงเซิร์ฟเวอร์ Epicbox ผู้รับจึงยังไม่ได้รับ เหรียญจะถูกล็อกไว้จนกว่าจะส่งอีกครั้งหรือยกเลิก';

  @override
  String get txDetailsSendAgainDone =>
      'ส่งอีกครั้งแล้ว การชำระเงินจะเสร็จสมบูรณ์เมื่อกระเป๋าของผู้รับออนไลน์';

  @override
  String get deskTxThisWallet => 'กระเป๋าเงินนี้';

  @override
  String get deskErrOldLinks =>
      'โฟลเดอร์ของกระเป๋าเงินนี้มีลิงก์อยู่ จึงไม่นำเข้า กู้คืนจากวลีกู้คืนแทน';

  @override
  String get deskErrOldIncomplete =>
      'อ่านโฟลเดอร์ของกระเป๋าเงินนี้ได้ไม่ครบ จึงไม่นำเข้า กู้คืนจากวลีกู้คืนแทน';

  @override
  String get deskErrOldSeedTooLarge =>
      'ไฟล์ wallet.seed ใหญ่เกินกว่าจะเป็น seed ของกระเป๋าเงิน';

  @override
  String get deskErrSendUnbuildable => 'สร้างการส่งนี้จากเหรียญที่มีอยู่ไม่ได้';

  @override
  String get deskErrNothingToConsolidate =>
      'ไม่มีอะไรให้รวม: มีเอาต์พุตที่ใช้ได้น้อยกว่าสองรายการ';

  @override
  String deskSetReportFileNone(String name) {
    return '$name (ไม่ได้แนบ)';
  }

  @override
  String deskSetReportFileAll(String name, String size) {
    return '$name (ทั้งไฟล์ $size)';
  }

  @override
  String deskSetReportFilePart(String name, String part, String size) {
    return '$name ($part สุดท้ายจาก $size)';
  }

  @override
  String get deskErrTxNotFound => 'ไม่พบธุรกรรม';

  @override
  String get deskTxNowUndelivered =>
      'ส่งไม่ถึง รายการนี้ไปไม่ถึงเซิร์ฟเวอร์ Epicbox ผู้รับจึงยังไม่ได้รับ ส่งอีกครั้ง หรือยกเลิกเพื่อปลดเหรียญคืน';

  @override
  String get deskTxStatusUndelivered => 'ส่งไม่ถึง';

  @override
  String get deskTxSendAgain => 'ส่งอีกครั้ง';

  @override
  String get deskTxNotSent => 'ส่งไม่สำเร็จ';

  @override
  String get deskTxSentAgain => 'ส่งอีกครั้งแล้ว';

  @override
  String get deskTxSentAgainText => 'จะเสร็จเมื่อกระเป๋าเงินของผู้รับออนไลน์';

  @override
  String get deskSendFeeChangedTitle => 'ค่าธรรมเนียมเปลี่ยนไป';

  @override
  String deskSendFeeChangedText(String fee, String was) {
    return 'เอาต์พุตของกระเป๋าเงินเปลี่ยนไปหลังการตรวจสอบนี้ การส่งครั้งนี้จึงเสียค่าธรรมเนียม $fee EPIC แทน $was EPIC โปรดตรวจสอบแล้วส่งอีกครั้ง';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max ไบต์';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'ข้อความยาวเกิน $max ไบต์ โปรดทำให้สั้นลง';
  }

  @override
  String get deskSetPhraseCopyTitle => 'คัดลอกวลีกู้คืน?';

  @override
  String get deskSetPhraseCopyText =>
      'ใครมีคำเหล่านี้ก็นำเงินของคุณไปได้ เก็บสำเนาไว้ในที่ปลอดภัย';

  @override
  String get deskOutAdvanced => 'จัดการเอาต์พุต';

  @override
  String get deskOutStrategyHint =>
      'การส่งจะใช้เอาต์พุตใด เล็กสุด ใช้เอาต์พุตเล็กให้น้อยที่สุดและเหลือส่วนอื่นไว้ใช้ได้ ทั้งหมด ใช้ทุกเอาต์พุตและคืนเป็นเอาต์พุตเดียว หน้า ส่ง เปลี่ยนได้เฉพาะครั้งนั้นใต้ ขั้นสูง';

  @override
  String get txStatusNotPosted => 'ไม่อยู่ในเครือข่าย';

  @override
  String get txStatusStalled => 'ค้างอยู่';

  @override
  String get txDetailsStalledBody =>
      'ค้างอยู่ ส่งไม่ถึง รายการชำระของคุณยังไม่เข้าสู่เครือข่าย ส่งอีกครั้ง';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      'รายการนี้ไปไม่ถึงกระเป๋าเงินของผู้รับ ผู้รับจึงยังไม่ได้รับ เงินของคุณจะถูกล็อกไว้จนกว่าจะส่งอีกครั้งหรือยกเลิก';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service ยังไม่ได้เผยแพร่รายการชำระของคุณ';
  }

  @override
  String get deskTxStatusNotPosted => 'ไม่อยู่ในเครือข่าย';

  @override
  String get deskTxNowNotPosted =>
      'ไม่อยู่ในเครือข่าย โหนดไม่รับรายการนี้ กระจายอีกครั้งได้ รายการเดียวกันจะไม่ผ่านซ้ำสองครั้ง';

  @override
  String get deskTxBroadcastAgain => 'กระจายอีกครั้ง';

  @override
  String get deskTxBroadcastDone => 'ส่งเข้าเครือข่ายแล้ว';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return 'ส่งไม่ถึง กระเป๋าเงินของผู้รับไม่รับรายการนี้ ($method) ผู้รับจึงยังไม่ได้รับ ส่งอีกครั้ง หรือยกเลิกเพื่อปลดเงินคืน';
  }

  @override
  String get deskInvPayStalled => 'ค้างอยู่';

  @override
  String deskInvPayerStalledTitle(String service) {
    return 'รายการชำระให้ $service ค้างอยู่';
  }

  @override
  String get deskInvPayerStalledText =>
      'ส่งไม่ถึง รายการยังไม่เข้าสู่เครือข่าย และเงินยังถูกล็อกอยู่ ส่งอีกครั้งจะส่งซ้ำโดยไม่ต้องอนุมัติอีก';

  @override
  String get deskTxLabelAdd => 'เพิ่มป้ายกำกับ';

  @override
  String get deskTxLabelEdit => 'แก้ไขป้ายกำกับ';

  @override
  String get deskTxLabelHint => 'เพิ่มป้ายกำกับ';

  @override
  String get deskTxLabelField => 'ป้ายกำกับ';

  @override
  String get deskTxLabelTip =>
      'ชื่อของรายการนี้ไว้ให้คุณเอง แสดงในกิจกรรมและในไฟล์ที่ส่งออก';

  @override
  String get deskTxLabelAdded => 'เพิ่มป้ายกำกับแล้ว';

  @override
  String get deskTxLabelSaved => 'บันทึกป้ายกำกับแล้ว';

  @override
  String get deskTxLabelRemoved => 'ลบป้ายกำกับแล้ว';

  @override
  String get deskTxLabelNotSaved => 'ไม่ได้บันทึกป้ายกำกับ';

  @override
  String get deskTxDetailsAdd => 'เพิ่มรายละเอียด';

  @override
  String get deskTxDetailsEdit => 'แก้ไข';

  @override
  String get deskTxDetailsTitleAdd => 'เพิ่มรายละเอียด';

  @override
  String get deskTxDetailsTitleEdit => 'แก้ไขรายละเอียด';

  @override
  String get deskTxDetailsTip => 'ใช้ได้เฉพาะรายการที่พบจากการตรวจยอดใหม่';

  @override
  String get deskTxDetailsFrom => 'จาก';

  @override
  String get deskTxDetailsFromTip =>
      'ผู้จ่ายเงิน ไว้เป็นบันทึกของคุณ ไม่ได้ตรวจสอบ และไม่ใช้ในหลักฐานการชำระเงิน';

  @override
  String get deskTxDetailsFromHint => 'ที่อยู่ของผู้ส่ง';

  @override
  String get deskTxDetailsFromBad => 'ใช้ที่อยู่ Epicbox, http(s) หรือ .onion';

  @override
  String get deskTxDetailsNote => 'บันทึกส่วนตัว';

  @override
  String get deskTxDetailsAdded => 'เพิ่มรายละเอียดแล้ว';

  @override
  String get deskTxDetailsSaved => 'บันทึกรายละเอียดแล้ว';

  @override
  String get deskTxDetailsRemoved => 'ลบรายละเอียดแล้ว';

  @override
  String get deskTxDetailsNotSaved => 'ไม่ได้บันทึกรายละเอียด';

  @override
  String get deskTxManualTag => 'คุณเพิ่มเอง';

  @override
  String deskTxManualTip(String date) {
    return 'คุณเพิ่มเมื่อ $date ไม่ได้มาจากบล็อกเชน';
  }

  @override
  String get deskTxManualTipNoDate => 'คุณเพิ่มเอง ไม่ได้มาจากบล็อกเชน';

  @override
  String deskTxManualTipFrom(String date) {
    return 'คุณเพิ่มเมื่อ $date ไม่ได้มาจากบล็อกเชน และไม่ได้ตรวจสอบ';
  }

  @override
  String get deskTxManualTipFromNoDate =>
      'คุณเพิ่มเอง ไม่ได้มาจากบล็อกเชน และไม่ได้ตรวจสอบ';

  @override
  String get deskHistConflictTitle => 'รายละเอียดไม่ตรงกัน';

  @override
  String deskHistConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'ไฟล์มีรายละเอียดต่างจากที่คุณใส่ไว้ใน $n รายการ จะใช้ของคุณต่อไป เว้นแต่คุณเลือกอย่างอื่น',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'ของฉัน';

  @override
  String get deskHistConflictBackup => 'ไฟล์';

  @override
  String get deskHistConflictKeepAll => 'เก็บของฉันทั้งหมด';

  @override
  String get deskHistConflictImport => 'นำเข้า';

  @override
  String get deskHistConflictEmpty => 'ว่าง';

  @override
  String deskHistImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'แทนที่รายละเอียด $n รายการ ที่เหลือใช้ของคุณเหมือนเดิม',
    );
    return '$_temp0';
  }

  @override
  String sendRelayUnknown(String relay) {
    return 'แอปไม่รู้จักเซิร์ฟเวอร์ $relay ตรวจสอบที่อยู่ก่อนส่ง';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay ไม่ตอบสนอง';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay ไม่ตอบสนอง ผู้รับจึงยังไม่ได้รับการชำระเงินนี้ เงินของคุณจะถูกล็อกไว้จนกว่าจะส่งอีกครั้งหรือยกเลิก';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return 'ส่งไม่ถึง: $relay ไม่ตอบสนอง รายการรออยู่ในประวัติ ยกเลิกที่นั่นเพื่อปลดล็อกยอดเงิน';
  }

  @override
  String deskErrRelayNoAnswer(String relay) {
    return '$relay ไม่ตอบสนอง';
  }

  @override
  String get deskSendRelayUnknownTitle => 'ไม่รู้จักเซิร์ฟเวอร์ Epicbox';

  @override
  String deskSendRelayUnknownText(String relay) {
    return 'แอปไม่รู้จักเซิร์ฟเวอร์ $relay ตรวจสอบที่อยู่ก่อนส่ง แต่ยังส่งได้';
  }

  @override
  String deskTxNowUndeliveredRelay(String relay) {
    return 'ส่งไม่ถึง $relay ไม่ตอบสนอง ผู้รับจึงยังไม่ได้รับรายการนี้ ส่งอีกครั้ง หรือยกเลิกเพื่อปลดเงินคืน';
  }

  @override
  String get deskInvNoticeReceiveSuperseded =>
      'อุปกรณ์อีกเครื่องของคุณที่ใช้กระเป๋านี้รับการชำระเงินที่อุปกรณ์นี้กำลังรับอยู่ด้วยไปแล้ว ใช้ “ตรวจยอดใหม่” เพื่อดูที่นี่';

  @override
  String deskHistConflictLeadOldWallet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'ประวัติของกระเป๋าเงินเก่ามีรายละเอียดต่างจากที่คุณใส่ไว้ใน $n รายการ ระบบจะเก็บของคุณไว้ เว้นแต่คุณเลือกอย่างอื่น',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'กระเป๋าเงินเก่า';

  @override
  String get deskHistConflictApply => 'ใช้';

  @override
  String get deskTxProofNone => 'การชำระเงินนี้ไม่มีหลักฐานการชำระเงิน';

  @override
  String get deskUpdAvailable => 'มีอัปเดต';

  @override
  String deskUpdNotice(String version) {
    return 'มีอัปเดต · $version';
  }

  @override
  String deskUpdDownload(String version) {
    return 'ดาวน์โหลด $version';
  }

  @override
  String get deskUpdOpensPage => 'เปิดหน้าดาวน์โหลด';

  @override
  String deskUpdDownloading(String percent) {
    return 'กำลังดาวน์โหลด $percent %';
  }

  @override
  String get deskUpdRestart => 'รีสตาร์ทเพื่ออัปเดต';

  @override
  String deskUpdReady(String version) {
    return '$version พร้อมแล้ว';
  }

  @override
  String get deskUpdRestartHint => 'แอปจะปิด ติดตั้งอัปเดต แล้วเปิดใหม่';

  @override
  String get deskUpdFailed => 'ดาวน์โหลดอัปเดตไม่ได้';

  @override
  String get deskUpdTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskUpdInstallFailed => 'ติดตั้งอัปเดตไม่ได้';

  @override
  String get deskUpdOpenPage => 'เปิดหน้าดาวน์โหลด';

  @override
  String get deskUpdErrDamaged => 'ไฟล์ไม่ตรงกับข้อมูลอัปเดตที่ลงลายเซ็นไว้';

  @override
  String get deskUpdErrStopped => 'การดาวน์โหลดหยุดลง';

  @override
  String get deskUpdErrInstall => 'แทนที่ด้วยเวอร์ชันใหม่ไม่ได้';

  @override
  String get deskUpdUnfinished => 'อัปเดตไม่เสร็จ ลองอีกครั้ง';

  @override
  String get advExperimental => 'ทดลอง';

  @override
  String get advTitle => 'ขั้นสูง';

  @override
  String get advStateOff => 'ปิด';

  @override
  String get advIntro =>
      'แต่ละสวิตช์จะแสดงส่วนของกระเป๋าเงินเพิ่มอีกส่วนในตำแหน่งของมัน';

  @override
  String get advShowsHeader => 'แสดงเพิ่ม';

  @override
  String get advNetworkHeader => 'เครือข่าย';

  @override
  String get advOutputs => 'เอาต์พุต';

  @override
  String get advOutputsHint =>
      'แสดงหน้าเอาต์พุตใต้ กระเป๋าเงิน และที่หน้าแรก แสดงเหรียญที่ประกอบเป็นยอดคงเหลือ ให้คุณแยกหรือรวมเหรียญ และตั้งค่าเริ่มต้นที่การส่งใช้ หากกำลังแยกหรือรวมอยู่ หน้านี้จะแสดงต่อไป';

  @override
  String get advTechnical => 'รายละเอียดทางเทคนิค';

  @override
  String get advTechnicalHint =>
      'แสดงแถวทางเทคนิคในรายละเอียดของรายการ ได้แก่ kernel, slate ID, commitment และความสูงบล็อก ในการตั้งค่า ใบแจ้งหนี้ จะแสดงว่าใบแจ้งหนี้ชำระได้นานเท่าใด';

  @override
  String get advSendOptions => 'ตัวเลือกการส่ง';

  @override
  String get advSendOptionsHint =>
      'แสดงวิธีเลือกของการส่งและแยกเงินทอนใน การตั้งค่า › ธุรกรรม คือการส่งใช้เอาต์พุตไหน และแยกเงินทอนหรือไม่ แสดงอยู่ตลอดตราบใดที่ตัวใดตัวหนึ่งไม่ใช่ค่าเริ่มต้น';

  @override
  String get advServerDetails => 'รายละเอียดเซิร์ฟเวอร์';

  @override
  String get advServerDetailsHint =>
      'แสดงโฮสต์ เวลาตอบสนอง เวอร์ชัน และความสูงบล็อกในรายการเซิร์ฟเวอร์และการ์ดสถานะ และแสดงที่อยู่ Epicbox ใน รับ';

  @override
  String get advRecheckHeight => 'ตรวจยอดใหม่จากบล็อกที่กำหนด';

  @override
  String get advRecheckHeightHint =>
      'ให้ ตรวจยอดใหม่ เริ่มจากความสูงบล็อกหรือวันที่แทนการเริ่มจากบล็อกแรก เร็วกว่า และเป็นวิธีเดียวที่ข้ามประวัติช่วงแรกได้ ตอนกู้คืนมีตัวเลือกนี้เสมอ';

  @override
  String get advModeStandard => 'ปกติ';

  @override
  String get advModeTorOnly => 'Tor เท่านั้น';

  @override
  String get advModeTorOnlyLine =>
      'ทุกการเชื่อมต่อผ่าน Tor จนกว่า Tor จะพร้อม จะไม่มีอะไรเชื่อมต่อ';

  @override
  String get advReset => 'ซ่อนทั้งหมดอีกครั้ง';

  @override
  String get advHomeTorOnlyWaiting => 'Tor เท่านั้น · รอ Tor';

  @override
  String get advBuiltInNode => 'โหนดในตัว';

  @override
  String get advLogs => 'บันทึก';

  @override
  String get deskSetFrameAdvanced => 'ขั้นสูง';

  @override
  String get deskSetAdvIntro =>
      'แต่ละสวิตช์จะแสดงส่วนของกระเป๋าเงินเพิ่มอีกส่วนในตำแหน่งของมัน';

  @override
  String get deskSetAdvShows => 'แสดงเพิ่ม';

  @override
  String get deskSetAdvOutputs => 'เอาต์พุต';

  @override
  String get deskSetAdvOutputsHint =>
      'แสดงหน้าเอาต์พุตในแถบด้านข้าง แสดงเหรียญที่ประกอบเป็นยอดคงเหลือ ให้คุณแยกหรือรวมเหรียญ และตั้งค่าเริ่มต้นที่การส่งใช้ หากกำลังแยกหรือรวมอยู่ หน้านี้จะแสดงต่อไป';

  @override
  String get deskSetAdvTechnical => 'รายละเอียดทางเทคนิค';

  @override
  String get deskSetAdvTechnicalHint =>
      'แสดงส่วนรายละเอียดทางเทคนิคในทุกธุรกรรม ได้แก่ slate ID, kernel, ความสูงบล็อก, สถานะและชนิดของแกนหลัก และหลักฐานการชำระเงิน ถ้าไม่เปิด ลิงก์ เพิ่มเติม ที่ธุรกรรมจะแสดงให้ดูครั้งเดียว ใน ใบแจ้งหนี้ จะแสดงส่วนขั้นสูง';

  @override
  String get deskSetAdvSendOptions => 'ตัวเลือกการส่ง';

  @override
  String get deskSetAdvSendOptionsHint =>
      'เพิ่มส่วนที่พับได้ใน ส่ง ซึ่งการส่งครั้งเดียวเลือกได้ว่าจะใช้เอาต์พุตไหน เล็กสุด หรือ ทั้งหมด และจะแยกเงินทอนหรือไม่ ค่าเริ่มต้นยังอยู่ที่ เอาต์พุต';

  @override
  String get deskSetAdvServerDetails => 'รายละเอียดเซิร์ฟเวอร์';

  @override
  String get deskSetAdvServerDetailsHint =>
      'แสดงโฮสต์ เวลาตอบสนอง เวอร์ชัน และความสูงบล็อกในรายการโหนดและ Epicbox แถวสถานะในแถบด้านข้าง และการ์ดสถานะ';

  @override
  String get deskSetAdvRecheck => 'ตรวจยอดใหม่จากบล็อกที่กำหนด';

  @override
  String get deskSetAdvRecheckHint =>
      'ให้ ตรวจยอดใหม่ ทิ้งธุรกรรมที่ยังไม่ยืนยันด้วย ส่วนการกู้คืนเสนอบล็อกเริ่มต้นให้ทุกคน ไม่ว่าจะตั้งตัวเลือกนี้อย่างไร';

  @override
  String get deskSetAdvBuiltInNode => 'โหนดในตัว';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'ให้คอมพิวเตอร์เครื่องนี้รันโหนดของตัวเอง ได้แก่ตัวเลือก คอมพิวเตอร์เครื่องนี้ ใต้ โหนด แผงซิงก์ และ เริ่มโหนด ในภาพรวม การซิงก์เชนใช้เวลาหลายชั่วโมงและพื้นที่ดิสก์หลายกิกะไบต์ โหนดที่กำลังทำงานอยู่จะคงแถวของมันไว้';

  @override
  String get deskSetAdvLogs => 'บันทึก';

  @override
  String get deskSetAdvLogsHint =>
      'แสดงกลุ่มบันทึกใต้ ช่วยเหลือ ได้แก่เปิดโฟลเดอร์บันทึกและล้างบันทึก รายงานปัญหาจะแนบบันทึกไม่ว่าจะเปิดไว้หรือไม่';

  @override
  String get deskSetAdvNetwork => 'เครือข่าย';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'ทุกการเชื่อมต่อผ่าน Tor จนกว่า Tor จะพร้อม จะไม่มีอะไรเชื่อมต่อ';

  @override
  String get deskSetAdvNotInBuild => 'ไม่มีในรุ่นนี้';

  @override
  String get deskSetAdvReset => 'ซ่อนทั้งหมดอีกครั้ง';

  @override
  String deskSetAdvOn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'เปิดอยู่ $n สวิตช์',
    );
    return '$_temp0';
  }

  @override
  String get deskShellOffline => 'ออฟไลน์';

  @override
  String get deskShellTorOnlyWaiting => 'Tor เท่านั้น · รอ Tor';

  @override
  String get deskSetAcctAutoLockHint =>
      'ล็อกกระเป๋าเมื่อไม่มีการกดแป้นหรือขยับเมาส์ตามเวลานี้ ถ้าเลือก “ไม่ล็อก” จะล็อกได้ด้วย “ล็อกกระเป๋า” เท่านั้น';

  @override
  String get netBlockTorOnly => 'โหมด Tor เท่านั้นเปิดอยู่ใน ขั้นสูง';

  @override
  String get netBlockWaitingForTor => 'รอ Tor';

  @override
  String get txDetailsMore => 'เพิ่มเติม';

  @override
  String get restoreStartFromLink => 'เริ่มจากวันที่หรือความสูงบล็อก';

  @override
  String get homeWaitingTorDetail =>
      'โหมด Tor เท่านั้นเปิดอยู่ใน ขั้นสูง กำลังรอ Tor เชื่อมต่อ';

  @override
  String get settingsRescanBodyPlain =>
      'กระเป๋าเงินจะค้นหาเงินของตัวเองอีกครั้ง ตั้งแต่บล็อกแรก';

  @override
  String get slNodeField => 'ที่อยู่โหนด';

  @override
  String get slRelayField => 'เซิร์ฟเวอร์ Epicbox';

  @override
  String get slFieldHint => 'วางหรือพิมพ์เพื่อกรองหรือเพิ่ม';

  @override
  String slSwitchTitle(String host) {
    return 'สลับไปที่ $host ไหม?';
  }

  @override
  String get slSwitchBody =>
      'ที่อยู่ Epicbox ของคุณจะเปลี่ยน แชร์ที่อยู่ใหม่ด้วย';

  @override
  String get slSwitch => 'สลับ';

  @override
  String get slHelpAddable => 'ไม่อยู่ในรายการ';

  @override
  String slHelpMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'พบ $count รายการ',
      zero: 'ไม่พบรายการที่ตรงกัน',
    );
    return '$_temp0';
  }

  @override
  String get slClear => 'ล้าง';

  @override
  String slAddRow(String host) {
    return 'เพิ่ม $host';
  }

  @override
  String get slAddTestsNode => 'ทดสอบโหนดก่อน แล้วจึงเสนอให้เปลี่ยน';

  @override
  String get slAddTestsRelay => 'ทดสอบเซิร์ฟเวอร์ก่อน แล้วจึงเสนอให้เปลี่ยน';

  @override
  String slAdded(String host) {
    return 'เพิ่ม $host แล้ว';
  }

  @override
  String get slRemove => 'นำออก';

  @override
  String slRemoved(String host) {
    return 'นำ $host ออกแล้ว';
  }

  @override
  String get slUndo => 'เลิกทำ';

  @override
  String get slInUseSwitchFirst => 'ใช้อยู่ ต้องเปลี่ยนก่อน';

  @override
  String get slRestore => 'กู้คืนเซิร์ฟเวอร์ที่นำออก';

  @override
  String slRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'นำออก $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get slRestored => 'กู้คืนเซิร์ฟเวอร์ที่นำออกแล้ว';

  @override
  String get slRelayWarning =>
      'การเปลี่ยนเซิร์ฟเวอร์จะทำให้ที่อยู่ Epicbox ของคุณเปลี่ยน แชร์ที่อยู่ใหม่ด้วย';

  @override
  String get slNotAnAddress =>
      'ไม่ใช่ที่อยู่เซิร์ฟเวอร์ ใช้ host หรือ host:port';

  @override
  String get slRelayNoAnswer => 'เซิร์ฟเวอร์นี้ไม่ตอบสนอง ไม่ได้เพิ่มอะไร';

  @override
  String deskSlRemoveHost(String host) {
    return 'นำ $host ออก';
  }

  @override
  String get deskSlInUse => 'ใช้อยู่';

  @override
  String get deskSlHealthUnknown => 'ไม่ทราบสถานะ';

  @override
  String get deskSlNodeNoAnswer => 'โหนดนี้ไม่ตอบสนอง ไม่ได้เพิ่มอะไร';

  @override
  String get deskSlTorWait => 'Tor ยังไม่ได้เชื่อมต่อ ไม่ได้เพิ่มอะไร';

  @override
  String deskSlLatency(String ms) {
    return '$ms มิลลิวินาที';
  }

  @override
  String get deskSlDefault => 'ค่าเริ่มต้น';

  @override
  String deskSlTesting(String host) {
    return 'กำลังทดสอบ $host…';
  }

  @override
  String get deskSlSetupEpicboxOn => 'รับผ่าน Epicbox';

  @override
  String get deskSlHelpChoose =>
      'เลือกหนึ่งรายการ หรือพิมพ์เพื่อกรองรายการหรือเพิ่มเซิร์ฟเวอร์';

  @override
  String get deskOnbRestoreFromLink => 'เริ่มจากความสูงบล็อก';

  @override
  String get deskOnbRestoreFromHide => 'ตรวจทั้งบล็อกเชน';

  @override
  String get deskOnbRestoreFromLabel => 'เริ่มจากบล็อก';

  @override
  String get deskOnbRestoreFromHint => 'ความสูงบล็อก';

  @override
  String get deskOnbRestoreFromHelp =>
      'ใช้เมื่อรายการแรกของกระเป๋าเงินเกิดหลังบล็อกนี้เท่านั้น เว้นว่างไว้เพื่อตรวจทั้งบล็อกเชน';

  @override
  String get deskOnbRestoreFromInvalid => 'ใช้ตัวเลขเท่านั้น หรือเว้นว่างไว้';

  @override
  String get deskNetWaitingTorReason =>
      'รอ Tor โหมด Tor เท่านั้นเปิดอยู่ใน ขั้นสูง';

  @override
  String get deskNetTorOnlyLine => 'Tor เท่านั้นเปิดอยู่ใน ขั้นสูง';

  @override
  String get deskNetOpenAdvanced => 'เปิดขั้นสูง';

  @override
  String get deskNetSendFileHint => 'โอนไฟล์ยังใช้ได้';

  @override
  String get deskNetRecvWaitTorText =>
      'การรับจะเริ่มเมื่อ Tor เชื่อมต่อ โอนไฟล์ยังใช้ได้';

  @override
  String get deskTourAdvancedTitle => 'ขั้นสูง';

  @override
  String get deskTourAdvancedText =>
      'โหมด Tor เท่านั้น เอาต์พุต และรายละเอียดทางเทคนิคอยู่ที่นี่ เปิดเฉพาะที่ต้องการ';

  @override
  String get deskTxMore => 'เพิ่มเติม';

  @override
  String get deskTxLess => 'ย่อ';

  @override
  String get settingsSectionTransactions => 'ธุรกรรม';

  @override
  String get settingsHubMethods => 'วิธี';

  @override
  String get settingsHubDefault => 'วิธีเริ่มต้น';

  @override
  String get settingsHubSendDefaults => 'ค่าเริ่มต้นการส่ง';

  @override
  String get txMethodsHeader => 'วิธีชำระเงิน';

  @override
  String txLinkHttpHint(String port) {
    return 'ลิงก์ · HTTP จ่ายตรงถึงกระเป๋าเงินที่ที่อยู่เว็บ (http://host:$port) และให้โทรศัพท์เครื่องนี้มีที่อยู่ที่กระเป๋าเงินในเครือข่าย Wi-Fi เดียวกันจ่ายมาได้ ต้องเปิดกระเป๋าเงินทั้งสองฝั่ง ไม่เข้ารหัสระหว่างทาง เข้าถึงจากอินเทอร์เน็ตหรือผ่านเน็ตมือถือไม่ได้ และจะปิดขณะเปิด Tor เพิ่ม ลิงก์ · HTTP ใน ส่ง และ รับ';
  }

  @override
  String get txLinkTorHint =>
      'ลิงก์ · Tor จ่ายตรงถึงกระเป๋าเงินที่ที่อยู่ onion และให้โทรศัพท์เครื่องนี้มีที่อยู่ Tor สำหรับรับเงิน ต้องเปิดกระเป๋าเงินทั้งสองฝั่ง ต้องใช้ Tor: สวิตช์ Tor ใน ความเป็นส่วนตัวและเครือข่ายส่งการเชื่อมต่อของกระเป๋าเงินผ่าน Tor สวิตช์นี้เพียงเปิดที่อยู่ เพิ่ม ลิงก์ · Tor ใน ส่ง และ รับ';

  @override
  String get txLinkTorNeedsTor =>
      'ต้องใช้ Tor เปิดได้ที่ ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get txLastMethodNotice => 'ต้องเปิดวิธีชำระเงินไว้อย่างน้อยหนึ่งวิธี';

  @override
  String get txEpicboxHint =>
      'Epicbox จ่ายผ่านเซิร์ฟเวอร์ กระเป๋าเงินอีกฝั่งจึงไม่ต้องเปิดอยู่ เมื่อปิด กระเป๋าเงินจะไม่เชื่อมต่อเซิร์ฟเวอร์ใด ไม่มีการจ่ายผ่าน Epicbox หรือใบแจ้งหนี้ วิธีอื่นยังใช้ได้';

  @override
  String get txDirectLine =>
      'จ่ายไปที่อยู่เว็บและ onion รับเงินตรงจากกระเป๋าเงินอื่น';

  @override
  String get txDirectHint =>
      'ลิงก์จ่ายตรงถึงกระเป๋าเงินอีกฝั่งที่ที่อยู่เว็บหรือ onion และให้โทรศัพท์เครื่องนี้รับเงินแบบเดียวกันได้ ต้องเปิดกระเป๋าเงินทั้งสองฝั่ง HTTP ใช้ได้ในเครือข่าย Wi-Fi นี้ Tor ต้องใช้ Tor เพิ่มลิงก์ใน ส่ง และ รับ';

  @override
  String get txFileHint =>
      'โอนไฟล์สร้างไฟล์ธุรกรรมที่คุณส่งให้อีกฝ่ายด้วยวิธีใดก็ได้ (ข้อความ อีเมล สายเคเบิล) แล้วเขาส่งกลับมาหนึ่งไฟล์ ไม่ต้องมีการเชื่อมต่อระหว่างสองกระเป๋าเงิน เพิ่มโอนไฟล์ใน ส่ง และ รับ';

  @override
  String get txStartHeader => 'วิธีเริ่มต้น';

  @override
  String get txDefaultsHeader => 'ค่าเริ่มต้นการส่ง';

  @override
  String get outputsDefaultsMoved =>
      'ค่าเริ่มต้นการส่งอยู่ที่ การตั้งค่า › ธุรกรรม';

  @override
  String get advNodeFailover => 'สลับโหนดอัตโนมัติ';

  @override
  String get advNodeFailoverHint =>
      'เมื่อโหนดของคุณไม่ตอบสนอง กระเป๋าเงินจะใช้โหนดถัดไปที่ใช้งานได้ในรายการของคุณตลอดช่วงนี้';

  @override
  String get advBalanceHeader => 'ยอดเงิน';

  @override
  String get advConfirmations => 'การยืนยัน';

  @override
  String advConfirmationsHint(int byDefault, int min, int max) {
    return 'จำนวนบล็อกที่การชำระเงินที่ได้รับต้องรอก่อนที่เอาต์พุตจะใช้ได้ ค่าเริ่มต้นคือ $byDefault ตั้งได้ตั้งแต่ $min ถึง $max';
  }

  @override
  String get advConfirmationsDefault => 'ค่าเริ่มต้น';

  @override
  String advConfirmationsReset(int count) {
    return 'รีเซ็ตเป็น $count';
  }

  @override
  String get advConfirmationsFewer => 'ลดการยืนยัน';

  @override
  String get advConfirmationsMore => 'เพิ่มการยืนยัน';

  @override
  String advConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ยืนยัน $count ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get advConfirmationsLowNote =>
      'ยิ่งยืนยันน้อยยิ่งเร็ว แต่ป้องกันการจัดเรียงบล็อกเชนใหม่ได้น้อยลง';

  @override
  String nodeFailoverSwitched(String host) {
    return 'โหนดไม่ตอบสนอง สลับไปที่ $host แล้ว';
  }

  @override
  String nodeFailoverInsteadOf(String host) {
    return 'แทน $host';
  }

  @override
  String get deskSetAdvNodeFailover => 'สลับโหนดอัตโนมัติ';

  @override
  String get deskSetAdvNodeFailoverHint =>
      'เมื่อโหนดของคุณไม่ตอบสนอง กระเป๋าเงินจะใช้โหนดถัดไปที่ใช้งานได้ในรายการของคุณตลอดช่วงนี้';

  @override
  String deskNodeFailoverSwitched(String host) {
    return 'โหนดไม่ตอบสนอง สลับไปที่ $host แล้ว';
  }

  @override
  String deskNodeFailoverInsteadOf(String host) {
    return 'แทน $host';
  }

  @override
  String get netOfflineNoPeers =>
      'โหนดของคุณไม่มีเพียร์ รายการจะรออยู่ในพูลของโหนดจนกว่าจะเชื่อมต่อใหม่';

  @override
  String get netOfflineNodeHint =>
      'ใช้โหนดเพื่ออ่านเชนและส่ง หากต้องการความเป็นส่วนตัวสูงสุด ให้ใช้โหนดในพื้นที่';

  @override
  String get netOfflineNodeLine => 'ใช้โหนด';

  @override
  String get netBlockEpicboxOff => 'Epicbox ปิดอยู่ใน การตั้งค่า › ธุรกรรม';

  @override
  String netBlockMethodOff(String method) {
    return '$method ปิดอยู่ใน ตั้งค่า › ธุรกรรม';
  }

  @override
  String get txEpicboxOffTitle => 'ปิด Epicbox หรือไม่';

  @override
  String txEpicboxOffPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'มี $count รายการกำลังรอการตอบกลับผ่าน Epicbox จะมาถึงเมื่อเปิด Epicbox อีกครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get txEpicboxOffAction => 'ปิด';

  @override
  String sendContactOnlyEpicbox(String name) {
    return '$name มีเฉพาะที่อยู่ Epicbox';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name มีเฉพาะที่อยู่สำหรับ $method';
  }

  @override
  String get receiveEpicboxOffText =>
      'รายการจะรออยู่ที่เซิร์ฟเวอร์ Epicbox จนกว่าจะเปิด Epicbox อีกครั้ง';

  @override
  String get receiveNoMethods => 'ไม่มีวิธีรับเงินที่เปิดอยู่';

  @override
  String get receiveNoMethodsBody => 'เปิดสักวิธีใน การตั้งค่า › ธุรกรรม';

  @override
  String get receiveNoMethodsButton => 'เปิดการตั้งค่า';

  @override
  String get deskNetOfflineNoPeers =>
      'โหนดของคุณไม่มีเพียร์ รายการจะรออยู่ในพูลของโหนดจนกว่าจะเชื่อมต่อใหม่';

  @override
  String get deskOutDefaultsMoved =>
      'วิธีเลือกและแยกเงินทอนของการส่งตั้งได้ที่ การตั้งค่า › ธุรกรรม';

  @override
  String get deskOutDefaultsOpen => 'เปิดธุรกรรม';

  @override
  String get deskSetFrameTransactions => 'ธุรกรรม';

  @override
  String get deskSetTxMethods => 'วิธีชำระเงิน';

  @override
  String get deskSetTxEpicboxHint =>
      'จ่ายและรับเงินผ่านเซิร์ฟเวอร์ Epicbox การชำระเงินส่วนใหญ่ใช้ทางนี้ เมื่อปิด กระเป๋าเงินจะไม่เชื่อมต่อเซิร์ฟเวอร์ Epicbox ใด ไม่มีการจ่ายผ่าน Epicbox หรือใบแจ้งหนี้ วิธีอื่นยังใช้ได้';

  @override
  String deskSetTxDirectHint(String port) {
    return 'จ่ายและรับเงินตรงจากกระเป๋าเงินสู่กระเป๋าเงินที่ที่อยู่เว็บ (http://host:$port) โดยไม่มีเซิร์ฟเวอร์คั่นกลาง ใช้ได้เฉพาะตอนที่กระเป๋าเงินเปิดอยู่ทั้งสองฝั่ง และปิดขณะเปิด Tor เพิ่ม ลิงก์ · HTTP ใน ส่ง และที่อยู่ของมันใน รับ';
  }

  @override
  String get deskSetTxFileHint =>
      'จ่ายและรับเงินโดยส่งต่อไฟล์ธุรกรรม ไม่ต้องใช้เครือข่าย เพิ่มโอนไฟล์ใน ส่ง และเพิ่มขั้นตอนเกี่ยวกับไฟล์ใน รับ';

  @override
  String get deskSetTxSend => 'ส่ง';

  @override
  String get deskSetTxStart => 'วิธีเริ่มต้น';

  @override
  String get deskSetTxStartHint =>
      'วิธีที่หน้า ส่ง เปิดขึ้นมา สำหรับการจ่ายครั้งเดียวยังเปลี่ยนได้ที่หน้า ส่ง';

  @override
  String get deskSendMethodHeader => 'วิธีชำระเงิน';

  @override
  String get sendRequestTitle => 'ใบแจ้งหนี้';

  @override
  String get sendRequestCheck => 'ตรวจสอบจำนวนแล้วดำเนินการต่อ';

  @override
  String get sendRequestDismiss => 'ปิด';

  @override
  String get sendAmountFromCode => 'จำนวนตามโค้ด';

  @override
  String sendAmountCodeAsked(String amount) {
    return 'โค้ดขอจำนวน $amount';
  }

  @override
  String get sendCodeAmountInvalid => 'จำนวนในโค้ดนี้ไม่ถูกต้องและถูกข้ามไป';

  @override
  String get sendCodeAmountTooLarge => 'จำนวนในโค้ดนี้มากเกินไปและถูกข้ามไป';

  @override
  String get sendCodeTooLong => 'บางส่วนของโค้ดนี้ยาวเกินไปและถูกข้ามไป';

  @override
  String get payeeNameLabel => 'ชื่อที่ผู้รับเงินระบุ (ยังไม่ยืนยัน)';

  @override
  String get payeeNoteLabel => 'บันทึกจากผู้รับเงิน (ยังไม่ยืนยัน)';

  @override
  String get payeeUnverifiedTitle => 'ยังไม่ยืนยัน';

  @override
  String get payeeUnverifiedHint =>
      'ชื่อและบันทึกถูกเขียนลงในโค้ดโดยผู้สร้างโค้ด ไม่มีใครตรวจสอบ ให้ตรวจสอบที่อยู่และจำนวน ไม่ใช่ชื่อ';

  @override
  String get sendNoteFromCodeHelper => 'มาจากโค้ด ผู้รับเห็นข้อความนี้ด้วย';

  @override
  String get sendOriginQr => 'จาก QR Code';

  @override
  String get sendOriginLink => 'จากลิงก์';

  @override
  String get sendOriginPasted => 'วางมา';

  @override
  String get sendDirectHost => 'โฮสต์';

  @override
  String get sendPlainHttpRow => 'ไม่ได้เข้ารหัส (HTTP ธรรมดา)';

  @override
  String get scanNotEpicTitle => 'ไม่ใช่โค้ด Epic';

  @override
  String get scanNotEpicBody => 'นี่ไม่ใช่ที่อยู่ Epic หรือโค้ดชำระเงิน';

  @override
  String get scanBadAddress => 'ที่อยู่ในโค้ดนี้ไม่ถูกต้อง';

  @override
  String get scanWrongNetworkTitle => 'เครือข่ายอื่น';

  @override
  String get scanWrongNetworkBody =>
      'ที่อยู่นี้เป็นของเครือข่าย Epic อื่น กระเป๋าเงินนี้จ่ายให้ไม่ได้';

  @override
  String get scanSlateTextBody => 'นี่คือข้อความของไฟล์ธุรกรรม ไม่ใช่ที่อยู่';

  @override
  String get commonOpen => 'เปิด';

  @override
  String get scanPairingTitle => 'ลิงก์จับคู่';

  @override
  String get scanPairingUnavailable => 'เวอร์ชันนี้ยังไม่รองรับการจับคู่';

  @override
  String get scanCodeTextLabel => 'ข้อความที่สแกนได้';

  @override
  String get scanCopied => 'คัดลอกแล้ว';

  @override
  String get linkWaitingPairingNotice => 'ได้รับลิงก์จับคู่';

  @override
  String get linkWaitingNotice => 'ได้รับลิงก์ชำระเงิน';

  @override
  String get linkFinishCurrentFirst => 'ทำรายการปัจจุบันให้เสร็จก่อน';

  @override
  String get deskSendToQrPayment =>
      'โค้ดชำระด้วย QR ให้สแกนด้วย Epic Cash Mobile';

  @override
  String get deskSetRecvTorText =>
      'ตรงจากกระเป๋าเงินอื่นที่ที่อยู่ Tor ของกระเป๋าเงินนี้ ขณะที่เปิดอยู่';

  @override
  String get deskSetTxTorHint =>
      'จ่ายและรับเงินตรงจากกระเป๋าเงินสู่กระเป๋าเงินที่ที่อยู่ onion ผ่าน Tor โดยไม่มีเซิร์ฟเวอร์คั่นกลาง ใช้ได้เฉพาะตอนที่กระเป๋าเงินเปิดอยู่ทั้งสองฝั่ง ต้องใช้ Tor: สวิตช์ Tor ใน ความเป็นส่วนตัว ส่งการเชื่อมต่อของกระเป๋าเงินผ่าน Tor สวิตช์นี้เพียงเปิดที่อยู่ เพิ่ม ลิงก์ · Tor ใน ส่ง และที่อยู่ของมันใน รับ';

  @override
  String get deskSetTxTorNeedsTor =>
      'Tor ปิดอยู่ เปิดได้ที่ ความเป็นส่วนตัว เพื่อรับเงินที่ที่อยู่ Tor';

  @override
  String get deskSetTxLastMethod => 'ต้องเปิดวิธีชำระเงินไว้อย่างน้อยหนึ่งวิธี';

  @override
  String get deskRecvTorOffTitle => 'Link · Tor ต้องใช้ Tor';

  @override
  String get deskRecvTorOffText =>
      'ที่อยู่ Tor ใช้ได้ขณะเปิด Tor Tor คือสวิตช์ใน ตั้งค่า › ความเป็นส่วนตัว ซึ่งส่งการเชื่อมต่อของกระเป๋าเงินผ่าน Tor';

  @override
  String get deskSetupSaveFailedTitle => 'ไม่ได้บันทึกการตั้งค่า';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason บันทึกอีกครั้ง หรือข้ามเพื่อใช้การตั้งค่าที่บันทึกไว้แล้ว';
  }

  @override
  String get deskSetupResumeLead =>
      'การตั้งค่าครั้งก่อนยังไม่เสร็จ กระเป๋าเงินอ่านบล็อกเชนและส่งธุรกรรมผ่านโหนด Epic';

  @override
  String deskErrProofContactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รวมผู้ติดต่อ $count รายเข้ากับรายการที่มีอยู่',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsKnown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ผู้ติดต่อ $count รายบันทึกไว้แล้ว',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้ามผู้ติดต่อ $count ราย: ไม่มีที่อยู่ที่ใช้ได้',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactAddressesLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ไม่ได้เพิ่มที่อยู่ $count รายการ: ขัดกับผู้ติดต่อที่บันทึกไว้',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofContactsUnreadable =>
      'อ่านผู้ติดต่อเดิมบางรายไม่ได้: สมุดที่อยู่เดิมเสียหาย';

  @override
  String get deskErrProofContactsFailed =>
      'บันทึกผู้ติดต่อไม่ครบ: เขียนสมุดที่อยู่ไม่ได้';

  @override
  String get deskTxStatusSenderPosted => 'ผู้ส่งแจ้งว่าส่งแล้ว';

  @override
  String get deskTxNowSenderPosted =>
      'ลงนามและส่งคืนแล้ว ผู้ส่งแจ้งว่าส่งเข้าเครือข่ายแล้ว จะสำเร็จเมื่อได้รับการยืนยัน';

  @override
  String get deskImpWrongTypePasted =>
      'ข้อความที่วางไม่ใช่ธุรกรรม วางข้อความทั้งหมดที่ผู้ส่งให้มา หรือเลือกไฟล์ของผู้ส่ง';

  @override
  String get pairTitle => 'จับคู่';

  @override
  String pairWithName(String name) {
    return 'จับคู่กับ $name';
  }

  @override
  String get pairLead =>
      'จับคู่กับอีกฝ่ายเพียงครั้งเดียว จากนั้นไฟล์ธุรกรรมและใบแจ้งหนี้ระหว่างสองกระเป๋าเงินจะถูกปิดผนึก มีเพียงสองกระเป๋าเงินนี้ที่อ่านได้';

  @override
  String get pairInPerson => 'แบบพบตัว';

  @override
  String get pairInPersonHint => 'แสดงโค้ดของคุณและสแกนโค้ดของอีกฝ่าย';

  @override
  String get pairOnline => 'ออนไลน์';

  @override
  String get pairOnlineHint => 'ส่งลิงก์คำเชิญ หรืออ่านคำจับคู่ให้ฟัง';

  @override
  String get pairOfflineHint => 'คุณออฟไลน์อยู่ คำเชิญและคำตอบต้องส่งด้วยตนเอง';

  @override
  String get pairEnter => 'ใส่ลิงก์หรือคำ';

  @override
  String get pairEnterHint => 'วางลิงก์คำเชิญ หรือพิมพ์คำที่ได้รับ';

  @override
  String get pairNotPaired => 'ยังไม่จับคู่';

  @override
  String get pairNotPairedHint =>
      'จับคู่เพื่อปิดผนึกไฟล์ธุรกรรมและอนุญาตใบแจ้งหนี้';

  @override
  String get pairInPersonTitle => 'จับคู่แบบพบตัว';

  @override
  String get pairShowMyCode => 'แสดงโค้ดของฉัน';

  @override
  String get pairScanTheirs => 'สแกนโค้ดของอีกฝ่าย';

  @override
  String get pairShowCodeCaption =>
      'ให้อีกฝ่ายสแกนโค้ดนี้ แล้วสแกนโค้ดของอีกฝ่าย';

  @override
  String get pairScanCaption =>
      'สแกนทั้งสองฝ่าย การตรวจคำจะเปิดขึ้นเมื่ออ่านโค้ดครบทั้งสอง';

  @override
  String get pairScanPrompt => 'หันกล้องไปที่โค้ดของอีกฝ่าย';

  @override
  String get pairSeenAs => 'อีกฝ่ายจะเห็นคุณเป็น';

  @override
  String get pairUseWords => 'ใช้คำแทน';

  @override
  String get pairCameraDeniedTitle => 'ไม่ได้อนุญาตให้ใช้กล้อง';

  @override
  String get pairCameraDeniedBody => 'อนุญาตกล้องเพื่อสแกน หรือใช้คำแทน';

  @override
  String get pairOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get pairWordsTitle => 'คำจับคู่';

  @override
  String get pairWordsLead =>
      'อ่านคำเหล่านี้ให้อีกฝ่ายฟังตามลำดับ กระเป๋าเงินของอีกฝ่ายจะหาคำเชิญจากคำเหล่านี้';

  @override
  String get pairWordsGoodFor => 'ใช้ได้ 10 นาที';

  @override
  String get pairWordsLastMinute => 'เหลือไม่ถึงหนึ่งนาที';

  @override
  String get pairWordsFooter =>
      'ใครก็ตามที่มีคำเหล่านี้ตอบคำเชิญนี้ได้จนกว่าจะหมดอายุ หลังจากนั้นให้ตรวจคำด้วยกัน';

  @override
  String get pairWordsNew => 'คำชุดใหม่';

  @override
  String get pairWordsCopy => 'คัดลอกคำ';

  @override
  String get pairWordsExpiredTitle => 'คำเหล่านี้หมดอายุแล้ว';

  @override
  String get pairWordsExpiredBody => 'สร้างชุดใหม่แล้วอ่านให้ฟังอีกครั้ง';

  @override
  String get pairWordsNeedEpicbox =>
      'คำเชิญทางวาจาต้องใช้ Epicbox จึงไม่มีให้ใช้ตอนนี้';

  @override
  String pairWordsDesktopChip(String time) {
    return 'คำ: เหลือ $time';
  }

  @override
  String get pairEnterLead => 'วางลิงก์คำเชิญ หรือพิมพ์ห้าคำที่ได้รับ';

  @override
  String get pairEnterField => 'ลิงก์คำเชิญหรือคำ';

  @override
  String get pairEnterNotFound =>
      'ไม่พบคำเชิญสำหรับคำเหล่านี้ ตรวจสอบอีกครั้ง หรือขอคำชุดใหม่';

  @override
  String get pairEnterTryAgain => 'ลองอีกครั้ง';

  @override
  String get pairEnterDesktopHint =>
      'ลิงก์ที่วางหรือคำที่พิมพ์ใช้แทนการสแกนบนโทรศัพท์';

  @override
  String get pairCardCopy => 'คัดลอกลิงก์จับคู่ของฉัน';

  @override
  String get pairCardHint =>
      'พบกันต่อหน้าโดยไม่มีกล้อง: กระเป๋าเงินแต่ละฝั่งวางลิงก์จับคู่ของอีกฝ่ายด้านบน';

  @override
  String pairCardBackTitle(String name) {
    return 'ตอนนี้ส่งโค้ดของคุณให้ $name';
  }

  @override
  String pairCardBackBody(String name) {
    return 'วางลิงก์นี้ในช่อง ใส่ลิงก์หรือคำ ในกระเป๋าเงินของ $name จากนั้นยืนยันด้วยกัน';
  }

  @override
  String get pairEnterDesktopPlaceholder => 'วางลิงก์คำเชิญ หรือพิมพ์ห้าคำ';

  @override
  String get pairOnlineTitle => 'จับคู่ออนไลน์';

  @override
  String get pairOnlineLead =>
      'ส่งคำเชิญผ่านช่องทางที่คุณใช้กับอีกฝ่ายอยู่แล้ว การจับคู่เสร็จเมื่อกระเป๋าเงินของอีกฝ่ายเปิดคำเชิญ';

  @override
  String get pairOnlineLeadByHand =>
      'ส่งคำเชิญผ่านช่องทางที่คุณใช้กับอีกฝ่ายอยู่แล้ว คำตอบจะกลับมาทางเดียวกัน ให้วางไว้ที่ ใส่ลิงก์หรือคำ';

  @override
  String get pairExpiresIn => 'คำเชิญหมดอายุใน';

  @override
  String get pairExpiry1h => '1 ชั่วโมง';

  @override
  String get pairExpiry24h => '24 ชั่วโมง';

  @override
  String get pairExpiry7d => '7 วัน';

  @override
  String get pairWhatTheyReceive => 'สิ่งที่อีกฝ่ายได้รับ';

  @override
  String get contactsPairHint =>
      'จับคู่กับกระเป๋าเงินอีกใบเพื่อปิดผนึกไฟล์ธุรกรรมและใบแจ้งหนี้ระหว่างกัน';

  @override
  String get contactsPairLearn => 'ทำงานอย่างไร';

  @override
  String get contactsPairTooltip => 'จับคู่กับกระเป๋าเงินอีกใบ';

  @override
  String get pairBadgePending => 'กำลังจับคู่…';

  @override
  String get pairBadgePendingTip => 'ส่งหรือตอบคำเชิญแล้ว แต่ยังไม่เสร็จ';

  @override
  String get pairWaysLead =>
      'จับคู่ครั้งเดียว จากนั้นไฟล์ธุรกรรมและใบแจ้งหนี้ระหว่างสองกระเป๋าเงินจะถูกปิดผนึก';

  @override
  String get pairWayWords => 'คำ';

  @override
  String get pairWayAutomatic => 'อัตโนมัติ';

  @override
  String get pairWayWordsHint =>
      'อ่านคำจับคู่ห้าคำให้อีกฝ่ายฟัง กระเป๋าเงินทั้งสองต้องออนไลน์';

  @override
  String get pairWayWordsInfo =>
      'กระเป๋าเงินทั้งสองต้องออนไลน์ กระเป๋าเงินของคุณวางคำเชิญไว้บนเซิร์ฟเวอร์เชื่อมต่อ กระเป๋าเงินของอีกฝ่ายหาคำเชิญจากห้าคำ จากนั้นยืนยันด้วยกัน';

  @override
  String get pairWayMessage => 'เชิญทางข้อความ';

  @override
  String get pairWayMessageHint => 'ส่งลิงก์ในแชตหรืออีเมลใดก็ได้';

  @override
  String get pairWayMessageInfo =>
      'สามข้อความ: คำเชิญของคุณ คำตอบของอีกฝ่าย และลิงก์ปิดท้ายของคุณ คัดลอกแต่ละข้อความเมื่อได้รับ กระเป๋าเงินจะพบในคลิปบอร์ดเมื่อคุณกลับมา ใช้ได้แม้เซิร์ฟเวอร์ถูกบล็อกหรือกระเป๋าเงินออฟไลน์';

  @override
  String get pairWayInPersonDesk => 'โทรศัพท์ของอีกฝ่ายสแกนโค้ดของคุณ';

  @override
  String get pairGotInvite => 'ได้รับคำหรือลิงก์มาแล้ว?';

  @override
  String get pairGotInviteHint => 'พิมพ์คำ หรือวางข้อความที่ได้รับ';

  @override
  String get pairHowItWorks => 'การจับคู่ทำงานอย่างไร';

  @override
  String get pairWordsBothOnline =>
      'กระเป๋าเงินทั้งสองต้องออนไลน์ ที่เหลือจะทำงานเอง';

  @override
  String get pairWordsWaiting => 'กำลังรอกระเป๋าเงินของอีกฝ่าย…';

  @override
  String get pairUseMessageInstead => 'เชิญทางข้อความแทน';

  @override
  String get pairAskForMessage => 'ขอให้อีกฝ่ายเชิญคุณทางข้อความแทน';

  @override
  String get pairStepInvite => 'คำเชิญ';

  @override
  String get pairStepReply => 'คำตอบ';

  @override
  String get pairStepFinish => 'ลิงก์ปิดท้าย';

  @override
  String get pairStepWords => 'คำ';

  @override
  String pairStepOf(int n, String step) {
    return 'ขั้นที่ $n จาก 4: $step';
  }

  @override
  String get pairMessageLead =>
      'ส่งคำเชิญในแชตใดก็ได้ คำตอบจะกลับมาทางเดียวกัน';

  @override
  String pairInviteMessage(String link) {
    return 'จับคู่กับฉันใน Epic Cash: $link';
  }

  @override
  String pairReplyMessage(String link) {
    return 'คำตอบของฉันสำหรับการจับคู่ Epic Cash: $link';
  }

  @override
  String pairFinishMessage(String link) {
    return 'จบการจับคู่ Epic Cash ของเรา: $link';
  }

  @override
  String get pairCopyMessage => 'คัดลอกข้อความ';

  @override
  String get pairMessageCopied => 'คัดลอกแล้ว วางในแชตได้เลย';

  @override
  String get pairAwaitReplyTitle => 'กำลังรอคำตอบ';

  @override
  String get pairAwaitReplyBody =>
      'เมื่อคำตอบมาถึงในแชต ให้คัดลอกแล้วกลับมา กระเป๋าเงินจะพบเอง';

  @override
  String get pairByItself =>
      'หากทั้งสองฝ่ายเข้าถึงเซิร์ฟเวอร์ Epicbox ได้ ขั้นนี้จะเกิดขึ้นเองด้วย';

  @override
  String get pairPasteReply => 'วางคำตอบ';

  @override
  String get pairReplyTitle => 'ส่งคำตอบ';

  @override
  String pairReplyLead(String name) {
    return 'ส่งสิ่งนี้กลับไปยัง $name ในแชตเดิม';
  }

  @override
  String get pairShareReply => 'แชร์คำตอบ';

  @override
  String get pairAwaitFinishTitle => 'กำลังรอลิงก์ปิดท้าย';

  @override
  String pairAwaitFinishBody(String name) {
    return 'กระเป๋าเงินของ $name สร้างจากคำตอบของคุณ คัดลอกเมื่อได้รับแล้วกลับมา';
  }

  @override
  String get pairPasteFinish => 'วางลิงก์ปิดท้าย';

  @override
  String get pairPasteLink => 'วางลิงก์';

  @override
  String get pairFinishTitle => 'ส่งลิงก์ปิดท้าย';

  @override
  String pairFinishLead(String name) {
    return 'อีกหนึ่งข้อความ: กระเป๋าเงินของ $name ต้องใช้เพื่อแสดงคำ';
  }

  @override
  String get pairShareFinish => 'แชร์ลิงก์ปิดท้าย';

  @override
  String get pairFinishThenCheck => 'จากนั้นตรวจคำด้วยกัน';

  @override
  String pairAlreadyPaired(String name) {
    return 'จับคู่กับ $name แล้ว';
  }

  @override
  String get pairReplyNotHere => 'คำตอบนี้เป็นของคำเชิญจากกระเป๋าเงินอื่น';

  @override
  String get helpPairWaysTitle => 'สามวิธีจับคู่';

  @override
  String get helpPairWaysShort =>
      'ทางวาจาเมื่อทั้งสองกระเป๋าเงินออนไลน์ ใช้ข้อความในแชตใดก็ได้ หรือพบตัว';

  @override
  String get helpPairWaysP1 =>
      '**ทางวาจา** กระเป๋าเงินหนึ่งแสดงห้าคำและวางคำเชิญที่ปิดผนึกไว้บนเซิร์ฟเวอร์เชื่อมต่อ อีกกระเป๋าเงินพิมพ์คำแล้วหาคำเชิญพบ กระเป๋าเงินทั้งสองต้องออนไลน์และเข้าถึงเซิร์ฟเวอร์เหล่านี้ได้อย่างน้อยหนึ่งแห่ง';

  @override
  String get helpPairWaysP2 =>
      '**เชิญทางข้อความ** สามข้อความในแชตใดก็ได้: คำเชิญ คำตอบ และลิงก์ปิดท้าย ไม่ต้องใช้เซิร์ฟเวอร์ จึงใช้ได้แม้เครือข่ายบล็อก Epicbox คัดลอกแต่ละข้อความเมื่อได้รับ กระเป๋าเงินจะเสนอให้ใช้เมื่อคุณกลับมา';

  @override
  String get helpPairWaysP3 =>
      '**แบบพบตัว** โทรศัพท์แต่ละเครื่องสแกนโค้ดของอีกเครื่อง ไม่ใช้เครือข่าย';

  @override
  String get helpPairWaysP4 =>
      'ไม่ว่าวิธีใด ตอนท้ายให้ยืนยันด้วยกัน: เทียบรูปสี่รูปและชื่อ ทั้งหมดนี้แสดงว่าไม่มีใครแก้ไขข้อความระหว่างทาง';

  @override
  String get helpPairClipP =>
      'กระเป๋าเงินอ่านคลิปบอร์ดเฉพาะเมื่อเปิดการจับคู่ไว้ เฉพาะตอนกลับมาที่หน้าจอหรือเปิดหน้าจับคู่ และเสนอแต่ละลิงก์เพียงครั้งเดียว ไม่เคยเก็บหรือบันทึกสิ่งที่อ่าน';

  @override
  String get pairShareWarning =>
      'ใครก็ตามที่มีคำเชิญนี้จับคู่ในนามคุณได้จนกว่าจะหมดอายุ ส่งให้เฉพาะคนที่ตั้งใจเท่านั้น แล้วยืนยันด้วยกัน';

  @override
  String get pairShareInvite => 'แชร์คำเชิญ';

  @override
  String get pairCopyInvite => 'คัดลอกคำเชิญ';

  @override
  String get pairUseWordsShort => 'ใช้คำ';

  @override
  String get pairInviteSentTitle => 'ส่งคำเชิญแล้ว';

  @override
  String pairInviteSentBody(String name) {
    return 'การจับคู่เสร็จเมื่อกระเป๋าเงินของ $name เปิดคำเชิญ คุณออกจากหน้านี้ได้ คำเชิญจะอยู่ที่ ผู้ติดต่อ › คำเชิญที่รออยู่';
  }

  @override
  String get pairCancelInvite => 'ยกเลิกคำเชิญ';

  @override
  String pairCancelInviteTitle(String name) {
    return 'ยกเลิกคำเชิญถึง $name หรือไม่';
  }

  @override
  String pairCancelInviteBody(String name) {
    return 'หากกระเป๋าเงินของอีกฝ่ายเปิดภายหลัง จะเห็นว่า “$name ยกเลิกคำเชิญนี้แล้ว”';
  }

  @override
  String pairIncomingTitle(String name) {
    return 'จับคู่กับ $name หรือไม่';
  }

  @override
  String get pairNameClaimed => 'ชื่อที่อีกฝ่ายเลือกเอง · ยังไม่ได้ตรวจ';

  @override
  String get pairNameClaimedShort => 'ชื่อที่อีกฝ่ายเลือกเอง';

  @override
  String pairCallsThemselves(String name) {
    return 'เรียกตัวเองว่า “$name”';
  }

  @override
  String pairIncomingBody(String name) {
    return 'เมื่อจับคู่แล้ว ไฟล์ธุรกรรมและใบแจ้งหนี้ระหว่างคุณกับ $name จะถูกปิดผนึก ขั้นต่อไปคือยืนยันด้วยกัน';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return 'อนุญาตให้ $name ขอให้ชำระเงิน';
  }

  @override
  String get pairIncomingAllowHintDesktop =>
      'เปิดใช้หลังจากคุณยืนยัน ไม่มีการชำระใดๆ หากไม่มีรหัสผ่านกระเป๋าเงิน';

  @override
  String get pairIncomingAllowHint =>
      'เปิดใช้หลังจากคุณยืนยัน ไม่มีการชำระใดๆ หากไม่มี PIN ของคุณ';

  @override
  String get pairNotNow => 'ไว้ทีหลัง';

  @override
  String pairWaitingTitle(String name) {
    return 'กำลังรอกระเป๋าเงินของ $name…';
  }

  @override
  String get pairWaitingBody =>
      'กระเป๋าเงินของอีกฝ่ายจะตอบเมื่อเปิด คุณปิดหน้านี้ได้ การยืนยันจะปรากฏเมื่อจับคู่เสร็จ';

  @override
  String get pairSendByHand => 'ส่งด้วยตนเอง';

  @override
  String get pairRelayUnreachableTitle => 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';

  @override
  String get pairRelayUnreachableBody => 'ส่งคำตอบด้วยตนเองหรือไม่';

  @override
  String get pairRelayUnreachableTor =>
      'เชื่อมต่อเซิร์ฟเวอร์ผ่าน Tor ไม่ได้ ส่งคำตอบด้วยตนเองหรือไม่';

  @override
  String get pairNoRelay =>
      'เชื่อมต่อเซิร์ฟเวอร์เชื่อมต่อไม่ได้เลย ให้จับคู่ด้วยลิงก์คำเชิญแทน';

  @override
  String get pairRelaysBlocked =>
      'เครือข่ายนี้บล็อกเซิร์ฟเวอร์เชื่อมต่อ อาจเกิดจากตัวกรองของเครือข่าย ให้จับคู่ด้วยลิงก์คำเชิญแทน';

  @override
  String get pairByHandTitle => 'ส่งด้วยตนเอง';

  @override
  String pairByHandLead(String name) {
    return 'ส่งสิ่งนี้กลับไปยัง $name ทางช่องทางใดก็ได้ กระเป๋าเงินของอีกฝ่ายจะจับคู่ให้เสร็จเมื่อเปิด';
  }

  @override
  String get pairByHandYourAnswer => 'คำตอบของคุณ';

  @override
  String pairByHandFooter(String name) {
    return 'คำตอบถูกปิดผนึกสำหรับคำเชิญของ $name ไม่มีใครอื่นอ่านได้ และใช้ได้ครั้งเดียว';
  }

  @override
  String pairConfirmByHandLead(String name) {
    return 'ส่งสิ่งนี้กลับไปยัง $name กระเป๋าเงินของอีกฝ่ายจะแสดงการตรวจคำเมื่อเปิด';
  }

  @override
  String get pairExpiredTitle => 'คำเชิญนี้หมดอายุแล้ว';

  @override
  String pairExpiredBody(String name) {
    return 'ขอคำเชิญใหม่จาก $name';
  }

  @override
  String get pairUsedTitle => 'คำเชิญนี้ถูกใช้แล้ว';

  @override
  String get pairUsedBody => 'ขอคำเชิญใหม่';

  @override
  String pairCancelledTitle(String name) {
    return '$name ยกเลิกคำเชิญนี้แล้ว';
  }

  @override
  String get pairCancelledBody => 'ไม่มีการบันทึกสิ่งใด';

  @override
  String pairNoAnswerTitle(String name) {
    return 'ไม่มีคำตอบจาก $name';
  }

  @override
  String get pairNoAnswerBody =>
      'คำเชิญอาจถูกยกเลิก ขอคำเชิญใหม่ หรือจับคู่แบบพบตัว';

  @override
  String pairWaitingFinish(String name) {
    return 'กำลังรอ $name จับคู่ให้เสร็จ…';
  }

  @override
  String get pairNotCompletedTitle => 'ไม่สำเร็จ';

  @override
  String pairNotCompletedBody(String name) {
    return 'กระเป๋าเงินของ $name จับคู่ไม่เสร็จทันเวลา ไม่มีการบันทึกสิ่งใด ลองอีกครั้ง';
  }

  @override
  String get pairLateCheck => 'กำลังตรวจหาคำตอบที่มาช้า…';

  @override
  String noticeUnpaired(String name) {
    return '$name ลบการจับคู่แล้ว การชำระเงินผ่านการจับคู่นี้จะไม่ถึงอีก';
  }

  @override
  String trustRemovedBy(String name) {
    return '$name ลบแล้ว';
  }

  @override
  String get trustRemovedShort => 'ถูกลบ';

  @override
  String get pairChangedTitle => 'คำเชิญนี้ถูกเปลี่ยนระหว่างทาง';

  @override
  String pairChangedBody(String name) {
    return 'ไม่มีการบันทึกสิ่งใด จับคู่อีกครั้งแบบพบตัว หรือด้วยคำเชิญใหม่จาก $name';
  }

  @override
  String get pairNewerTitle => 'อัปเดต Epic Cash เพื่อเปิดสิ่งนี้';

  @override
  String get pairNewerInviteBody =>
      'คำเชิญนี้สร้างโดยกระเป๋าเงินเวอร์ชันใหม่กว่า';

  @override
  String get pairNewerFileBody =>
      'ไฟล์นี้ถูกปิดผนึกโดยกระเป๋าเงินเวอร์ชันใหม่กว่า';

  @override
  String get pairCheckForUpdates => 'ตรวจหาการอัปเดต';

  @override
  String pairSecondReplyTitle(String name) {
    return 'มีคนอื่นตอบคำเชิญของ $name ด้วย ดูที่ คำเชิญที่รออยู่';
  }

  @override
  String get pairAnsweredSameInvite => 'ตอบคำเชิญเดียวกัน · ไม่ได้บันทึก';

  @override
  String get sasTitle => 'เทียบคำตรวจสอบ';

  @override
  String sasLead(String name) {
    return 'กระเป๋าเงินของ $name แสดงคำตรวจสอบสี่คำเดียวกัน เปรียบเทียบทางโทรศัพท์หรือแบบพบตัว';
  }

  @override
  String sasLeadExchange(String name) {
    return 'หน้า $name แสดงสี่คำเดียวกัน เปรียบเทียบแล้วยืนยันทั้งสองฝั่ง';
  }

  @override
  String sasLeadRecheck(String name) {
    return 'กระเป๋าเงินของ $name แสดงคำเหล่านี้ที่ $name › ตรวจคำ เปรียบเทียบทางโทรศัพท์หรือแบบพบตัว';
  }

  @override
  String get sasMatch => 'ตรงกัน';

  @override
  String get sasNoMatch => 'ไม่ตรงกัน';

  @override
  String get sasSkip => 'ข้ามไปก่อน';

  @override
  String get sasLater => 'ภายหลัง';

  @override
  String sasMatchedTitle(String name) {
    return '$name ยืนยันแล้ว';
  }

  @override
  String sasMatchedBody(String name) {
    return 'นับจากนี้ ไฟล์ธุรกรรมและใบแจ้งหนี้กับ $name จะถูกปิดผนึก';
  }

  @override
  String get sasNoMatchTitle => 'คำไม่ตรงกัน';

  @override
  String get sasNoMatchBody =>
      'อาจมีคนเปลี่ยนคำเชิญระหว่างทาง จะไม่เก็บสิ่งใดไว้ จับคู่อีกครั้งแบบพบตัว หรือด้วยคำเชิญใหม่';

  @override
  String get sasStopPairing => 'หยุดการจับคู่';

  @override
  String sasSkippedTitle(String name) {
    return 'จับคู่กับ $name แล้ว';
  }

  @override
  String sasSkippedBody(String name) {
    return 'ไฟล์ธุรกรรมกับ $name ถูกปิดผนึก ตรวจคำจากหน้าผู้ติดต่อของ $name เมื่อสะดวก ใบแจ้งหนี้จะรอจนกว่าจะตรวจ';
  }

  @override
  String get sasCheckNow => 'ตรวจตอนนี้';

  @override
  String get sasAllowAfterMatch => 'เปิดใช้เมื่อคุณยืนยันว่าคำตรงกัน';

  @override
  String sasAllowInvoicesHint(String name) {
    return 'กระเป๋าเงินของ $name ขอให้คุณชำระเงินได้ ไม่มีการชำระใดๆ หากไม่มี PIN ของคุณ';
  }

  @override
  String get trustVerified => 'ยืนยันแล้ว';

  @override
  String get trustPaired => 'จับคู่แล้ว ยังไม่ยืนยัน';

  @override
  String get trustPairedShort => 'จับคู่แล้ว';

  @override
  String get trustKeysChanged => 'คีย์เปลี่ยน';

  @override
  String get trustSealed => 'ปิดผนึก';

  @override
  String trustSealedFor(String name) {
    return 'ปิดผนึกสำหรับ $name';
  }

  @override
  String get trustAllowsInvoices => 'อนุญาตใบแจ้งหนี้';

  @override
  String get contactTitle => 'ผู้ติดต่อ';

  @override
  String get contactAddresses => 'ที่อยู่';

  @override
  String get contactPairing => 'การจับคู่';

  @override
  String contactWordsChecked(String date) {
    return 'ยืนยันเมื่อ $date';
  }

  @override
  String get contactCheckAgain => 'ตรวจอีกครั้ง';

  @override
  String get contactCheckWordsAgain => 'ยืนยันอีกครั้ง';

  @override
  String get contactSealPayments => 'ปิดผนึกการชำระเงิน';

  @override
  String contactSealInfo(String name) {
    return 'การชำระเงินและใบแจ้งหนี้กับ $name เข้ารหัสแบบต้นทางถึงปลายทาง มีเพียงกระเป๋าเงินของอีกฝ่ายที่อ่านได้';
  }

  @override
  String contactSealInfoMore(String name) {
    return 'เมื่อปิด ไฟล์ธุรกรรมถึง $name จะไม่ปิดผนึก ใครที่ได้ไฟล์ก็อ่านได้ ปิดเฉพาะเมื่อกระเป๋าเงินของ $name เปิดไฟล์ที่ปิดผนึกไม่ได้';
  }

  @override
  String get contactAllowInvoices => 'อนุญาตใบแจ้งหนี้';

  @override
  String contactAllowInfoDesktop(String name) {
    return 'กระเป๋าเงินของ $name ส่งใบแจ้งหนี้ถึงคุณได้ แต่ละรายการรอที่ ใบแจ้งหนี้ ให้คุณอนุมัติและใส่รหัสผ่านกระเป๋าเงิน ไม่มีการชำระเอง';
  }

  @override
  String contactAllowInfo(String name) {
    return 'กระเป๋าเงินของ $name ส่งใบแจ้งหนี้ถึงคุณได้ แต่ละรายการรอที่ ใบแจ้งหนี้ ให้คุณอนุมัติและใส่ PIN ไม่มีการชำระเอง';
  }

  @override
  String get contactAllowInfoMore =>
      'อนุญาตได้เฉพาะผู้ติดต่อที่ยืนยันแล้ว การยืนยันช่วยตัดโอกาสที่คำเชิญถูกสลับ';

  @override
  String get contactCheckWordsFirst => 'ยืนยันก่อน';

  @override
  String get contactPausedUntilChecked => 'หยุดไว้จนกว่าจะยืนยัน';

  @override
  String contactDeliveredVia(String relay) {
    return 'ส่งผ่าน $relay';
  }

  @override
  String contactRelayDownTitle(String name) {
    return 'เซิร์ฟเวอร์ของ $name ไม่ตอบสนอง';
  }

  @override
  String get contactRelayDownBody =>
      'กำลังลองใหม่ ใบแจ้งหนี้และการชำระเงินจะรอจนกว่าจะตอบ';

  @override
  String get contactPausedEpicboxOff => 'หยุดไว้ขณะปิด Epicbox';

  @override
  String get contactPausedEpicboxOffBody => 'ไฟล์ที่ปิดผนึกยังใช้ได้';

  @override
  String get contactRemovePairing => 'ลบการจับคู่';

  @override
  String contactRemovePairingTitle(String name) {
    return 'ลบการจับคู่กับ $name หรือไม่';
  }

  @override
  String contactRemovePairingBody(String name) {
    return 'การชำระเงินและใบแจ้งหนี้ที่ปิดผนึกจาก $name จะหยุด ที่อยู่ยังอยู่ในผู้ติดต่อของคุณ';
  }

  @override
  String get contactKeep => 'เก็บไว้';

  @override
  String get contactRemove => 'ลบ';

  @override
  String contactKeysChangedTitle(String name) {
    return 'คีย์ของ $name เปลี่ยน';
  }

  @override
  String get contactKeysChangedBody =>
      'อาจหมายความว่าอีกฝ่ายใช้กระเป๋าเงินใบอื่นแล้ว หรือมีคนอื่นใช้ชื่อนี้ ยืนยันผู้ติดต่ออีกครั้ง';

  @override
  String get contactKeysChangedStatus => 'หยุดการปิดผนึกและใบแจ้งหนี้ไว้';

  @override
  String get contactKeysChangedPaused => 'หยุดการปิดผนึกและใบแจ้งหนี้ไว้';

  @override
  String get contactKeepOldKeys => 'ใช้คีย์เดิม';

  @override
  String get contactUseNewKeys => 'ใช้คีย์ใหม่';

  @override
  String contactKeysBack(String name) {
    return 'คีย์ของ $name กลับมาแล้ว';
  }

  @override
  String get contactKeysBackBody => 'ไม่มีอะไรเปลี่ยนสำหรับคุณ';

  @override
  String contactSealDegradedTitle(String name) {
    return 'การชำระเงินครั้งล่าสุดถึง $name ไม่ได้ปิดผนึก';
  }

  @override
  String contactSealDegradedBody(String name) {
    return 'ครั้งถัดไปจะถามว่าปิดผนึกหรือไม่ การปิดผนึกจะเปิดเองอีกครั้งเมื่อกระเป๋าเงินของ $name ตอบแบบปิดผนึก';
  }

  @override
  String get addrField => 'ที่อยู่';

  @override
  String addrFieldTyped(String type) {
    return 'ที่อยู่ $type';
  }

  @override
  String get addrAddAnother => 'เพิ่มที่อยู่อื่น';

  @override
  String addrOneFree(String type) {
    return 'ยังเหลืออีกหนึ่งประเภท: $type';
  }

  @override
  String addrDuplicateType(String name, String type) {
    return '$name มีที่อยู่ประเภทนี้แล้ว ($type)';
  }

  @override
  String get addrKeepOld => 'ใช้อันเดิม';

  @override
  String get addrReplace => 'แทนที่';

  @override
  String addrDesktopThird(String type) {
    return 'วางที่อยู่ $type หรือเว้นว่างไว้';
  }

  @override
  String get addrDesktopRule => 'หนึ่งที่อยู่ต่อหนึ่งประเภท';

  @override
  String get pendingTitle => 'คำเชิญที่รออยู่';

  @override
  String pendingRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'คำเชิญ $count รายการรอคำตอบ',
    );
    return '$_temp0';
  }

  @override
  String pendingLink(String time) {
    return 'ลิงก์ · หมดอายุใน $time';
  }

  @override
  String pendingWords(String time) {
    return 'คำเชิญทางวาจา · หมดอายุใน $time';
  }

  @override
  String get pendingExpired => 'หมดอายุ';

  @override
  String get pendingInviteAgain => 'เชิญอีกครั้ง';

  @override
  String get pendingWaitingConfirm => 'รออีกฝ่ายยืนยัน';

  @override
  String get pendingPairedCheck => 'จับคู่แล้ว · ยืนยัน';

  @override
  String get pendingEmpty =>
      'ไม่มีคำเชิญที่รออยู่ คำเชิญจะแสดงที่นี่จนกว่ากระเป๋าเงินอีกฝ่ายจะตอบ';

  @override
  String get pendingShareAgain => 'แชร์อีกครั้ง';

  @override
  String get pendingShowWords => 'แสดงคำเชิญ';

  @override
  String get pendingCopyLink => 'คัดลอกลิงก์';

  @override
  String get invSetTitle => 'ใบแจ้งหนี้';

  @override
  String get invSetLead =>
      'ผู้ติดต่อที่จับคู่แล้วซึ่งคุณอนุญาต ส่งใบแจ้งหนี้ถึงคุณได้ แต่ละรายการรอ PIN ของคุณที่ ใบแจ้งหนี้';

  @override
  String get invSetPaired => 'ผู้ติดต่อที่จับคู่แล้ว';

  @override
  String get invSetAllowed => 'อนุญาต';

  @override
  String get invSetOff => 'ปิด';

  @override
  String get invSetPairShop => 'จับคู่กับร้านค้าหรือศูนย์แลกเปลี่ยน';

  @override
  String get invSetEmpty =>
      'ยังไม่มีผู้ติดต่อที่จับคู่ จับคู่กับร้านค้า ศูนย์แลกเปลี่ยน หรือบุคคล ยืนยัน แล้วอนุญาตใบแจ้งหนี้ของอีกฝ่ายที่นี่';

  @override
  String get invSetPausedBody =>
      'ใบแจ้งหนี้จะรออยู่บนเซิร์ฟเวอร์ และมาถึงเมื่อเปิด Epicbox อีกครั้ง';

  @override
  String invSetSwitchedOff(String name) {
    return 'ปิดใบแจ้งหนี้จาก $name แล้ว';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ปฏิเสธใบแจ้งหนี้ที่ค้างอยู่ $count รายการแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get invSetTimeToPay => 'ระยะเวลาชำระ';

  @override
  String invSetTimeToPayHint(int hours) {
    return '$hours ชั่วโมง · ระยะเวลาที่ใบแจ้งหนี้ยังชำระได้';
  }

  @override
  String get invoicesEmptyAction => 'ผู้ติดต่อที่จับคู่แล้ว';

  @override
  String get reqTitle => 'ตรวจสอบใบแจ้งหนี้';

  @override
  String reqRequests(String name) {
    return '$name ขอ';
  }

  @override
  String reqSealedSigned(String name) {
    return 'ปิดผนึกสำหรับกระเป๋าเงินนี้และลงนามโดย $name';
  }

  @override
  String get reqReference => 'เลขอ้างอิง';

  @override
  String reqPaidWaiting(String name) {
    return 'ชำระแล้ว รอ $name ประกาศ';
  }

  @override
  String get reqPaidWaitingBodyPerson =>
      'ส่วนของคุณเสร็จแล้ว กระเป๋าเงินของอีกฝ่ายจะทำให้เสร็จและประกาศ รายการนี้จะปิดเอง';

  @override
  String get reqPaidWaitingBody =>
      'ส่วนของคุณเสร็จแล้ว ศูนย์แลกเปลี่ยนจะทำให้เสร็จและประกาศ รายการนี้จะปิดเอง';

  @override
  String get reqTlPaid => 'ชำระแล้ว';

  @override
  String reqTlDelivered(String name) {
    return 'ส่งถึงเซิร์ฟเวอร์ Epicbox ของ $name แล้ว';
  }

  @override
  String reqTlAnswerDelivered(String name) {
    return 'ส่งคำตอบถึงเซิร์ฟเวอร์ของ $name แล้ว';
  }

  @override
  String reqTlPosted(String name) {
    return 'ประกาศโดย $name';
  }

  @override
  String get reqTlPostedHint => 'โดยปกติภายในไม่กี่นาที';

  @override
  String get reqTlConfirming => 'กำลังยืนยัน';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return 'ยืนยันแล้ว $n จาก $total ครั้ง';
  }

  @override
  String get reqTlConfirmed => 'ยืนยันแล้ว';

  @override
  String reqTlWaiting(String time) {
    return 'รอมา $time';
  }

  @override
  String reqNotPostedTitle(String name) {
    return '$name ยังไม่ได้ประกาศ';
  }

  @override
  String get reqNotPostedBody =>
      'ส่งอีกครั้งจะส่งการชำระเงินเดิมอีกรอบ ไม่สามารถชำระซ้ำสองครั้ง';

  @override
  String get reqSendAgain => 'ส่งอีกครั้ง';

  @override
  String reqUnreachableTitle(String name) {
    return 'ยังติดต่อ $name ไม่ได้';
  }

  @override
  String get reqUnreachableBody =>
      'เหรียญจะปลดล็อกหากไม่มีการประกาศ ระบบยังคงลองส่งต่อไป';

  @override
  String get reqRelayRetrying => 'เซิร์ฟเวอร์ไม่ตอบสนอง · กำลังลองใหม่';

  @override
  String reqWithdrewTitle(String name) {
    return '$name ถอนใบแจ้งหนี้แล้ว';
  }

  @override
  String get reqWithdrewBody => 'เงินของคุณปลดล็อกแล้ว ไม่มีการชำระใดๆ';

  @override
  String reqWithdrewUnpaid(String name) {
    return '$name ถอนใบแจ้งหนี้นี้แล้ว';
  }

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name ส่งใบแจ้งหนี้ $amount EPIC จำนวน $count รายการภายใน 10 นาที ชำระทั้งหมดหรือไม่',
    );
    return '$_temp0';
  }

  @override
  String reqWithdrawalFrom(String name) {
    return 'การถอนจาก $name';
  }

  @override
  String reqReceivedWaiting(String name) {
    return 'ได้รับแล้ว รอ $name ประกาศ';
  }

  @override
  String get reqReceivedWaitingBody =>
      'ไม่ต้องทำอะไร ศูนย์แลกเปลี่ยนจะประกาศ จากนั้นจะมีการยืนยันตามมา';

  @override
  String get reqNewTitle => 'ใบแจ้งหนี้ใหม่';

  @override
  String get reqNewLead =>
      'ขอให้ผู้ติดต่อที่จับคู่แล้วชำระเงินให้คุณ หรือบันทึกใบแจ้งหนี้เป็นไฟล์สำหรับใครก็ได้';

  @override
  String get reqNewLeadContacts => 'ขอให้ผู้ติดต่อที่จับคู่แล้วชำระเงินให้คุณ';

  @override
  String get reqNewTo => 'ถึง';

  @override
  String get reqNewToHintContacts =>
      'ผู้ติดต่อที่จับคู่แล้วซึ่งกระเป๋าเงินชำระใบแจ้งหนี้ได้';

  @override
  String get reqNoPayersContacts =>
      'ยังไม่มีผู้ติดต่อที่จับคู่แล้วซึ่งชำระใบแจ้งหนี้ได้ จับคู่และยืนยันกับอีกฝ่าย';

  @override
  String get reqNewToHint =>
      'ผู้ติดต่อที่จับคู่แล้วซึ่งกระเป๋าเงินชำระใบแจ้งหนี้ได้ สำหรับคนอื่น ให้บันทึกใบแจ้งหนี้เป็นไฟล์';

  @override
  String get reqNewSaveFile => 'บันทึกเป็นไฟล์';

  @override
  String get reqNewSend => 'ส่งใบแจ้งหนี้';

  @override
  String sendViaMailbox(String name) {
    return 'ส่งผ่านเซิร์ฟเวอร์ Epicbox ของ $name';
  }

  @override
  String sendViaMailboxHint(String relay) {
    return 'ปิดผนึก ส่งผ่าน $relay';
  }

  @override
  String sendSealedTitle(String name) {
    return 'ปิดผนึกสำหรับ $name';
  }

  @override
  String sendSealedBody(String name) {
    return 'มีเพียงกระเป๋าเงินของ $name ที่เปิดไฟล์นี้ได้ ส่งด้วยวิธีใดก็ได้ แล้วเปิดไฟล์ที่อีกฝ่ายส่งกลับมา';
  }

  @override
  String get sendSealOrPlainTitle => 'ปิดผนึกไฟล์นี้หรือไม่';

  @override
  String sendSealOrPlainBody(String name) {
    return 'ไฟล์ล่าสุดถึง $name ไม่ได้ปิดผนึก ตอนนี้ค่าเริ่มต้นกลับเป็นปิดผนึก';
  }

  @override
  String get sendSealedOption => 'ปิดผนึก';

  @override
  String sendSealedOptionHint(String name) {
    return 'มีเพียงกระเป๋าเงินของ $name ที่อ่านได้';
  }

  @override
  String get sendPlainOption => 'ไม่ปิดผนึก';

  @override
  String get sendPlainOptionHint => 'ใครที่มีไฟล์ก็อ่านได้';

  @override
  String sendCantOpenTitle(String name) {
    return '$name เปิดไฟล์ที่ปิดผนึกไม่ได้หรือ';
  }

  @override
  String get sendCantOpenBody =>
      'ส่งแบบไม่ปิดผนึกจะส่งการชำระเงินเดิมอีกครั้งโดยไม่ปิดผนึก ยังคงเป็นการชำระเงินเดียว';

  @override
  String get sendAsPlain => 'ส่งแบบไม่ปิดผนึกแทน';

  @override
  String get sendAsPlainTitle => 'ส่งแบบไม่ปิดผนึกแทนหรือไม่';

  @override
  String get sendAsPlainBody =>
      'ไฟล์จะไม่ถูกปิดผนึก ใครที่ได้ไฟล์จะอ่านจำนวนเงินและที่อยู่ในไฟล์ได้ เป็นการชำระเงินเดิม จึงชำระซ้ำสองครั้งไม่ได้';

  @override
  String get sendKeepSealed => 'คงการปิดผนึก';

  @override
  String get sendPlain => 'ส่งแบบไม่ปิดผนึก';

  @override
  String sendNotHeardTitle(String name) {
    return 'ไม่มีข่าวจากกระเป๋าเงินของ $name มา 90 วัน';
  }

  @override
  String sendNotHeardBody(String name) {
    return '$name ต้องใช้ Epic Cash เพื่อเปิดไฟล์นี้';
  }

  @override
  String get sendPlainShort => 'ส่งไม่ปิดผนึก';

  @override
  String get openSealedOtherTitle =>
      'สิ่งนี้ปิดผนึกไว้สำหรับกระเป๋าเงินหรือการติดตั้งอื่น';

  @override
  String get openSealedOtherBody => 'เปิดที่นี่ไม่ได้ ขอให้ผู้ส่งส่งมาอีกครั้ง';

  @override
  String get openArrivedUnsealed => 'สิ่งนี้มาถึงโดยไม่ได้ปิดผนึก';

  @override
  String openArrivedUnsealedBody(String name) {
    return '$name เลือกส่งไฟล์นี้แบบไม่ปิดผนึก';
  }

  @override
  String noticePairingReplied(String name) {
    return '$name ตอบคำเชิญของคุณแล้ว ยืนยันด้วยกัน';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'จับคู่กับ $name แล้ว ยืนยันด้วยกัน';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name ขอ $amount EPIC ตรวจสอบได้ที่ ใบแจ้งหนี้';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return 'ได้รับ $amount EPIC จาก $name รอการประกาศ';
  }

  @override
  String noticeKeysChanged(String name) {
    return 'คีย์ของ $name เปลี่ยน ยืนยันอีกครั้งก่อนชำระ';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return '$name จับคู่ด้วยคีย์ใหม่แล้ว ตรวจคีย์เก่าไม่ได้ เพราะตรวจได้วันละครั้งและตรวจไปแล้ว';
  }

  @override
  String noticeRelayDown(String name) {
    return 'เซิร์ฟเวอร์ Epicbox ของ $name ไม่ตอบสนอง กำลังลองใหม่';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name ถอนใบแจ้งหนี้แล้ว เงินของคุณปลดล็อกแล้ว';
  }

  @override
  String get restoreUseContactsTitle => 'ใช้ผู้ติดต่อของคุณบนอุปกรณ์นี้หรือไม่';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'การจับคู่ $count รายการในไฟล์นี้เคยใช้บนอุปกรณ์อื่น อุปกรณ์อื่นของคุณควรหยุดใช้',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => 'ใช้ที่นี่';

  @override
  String restorePairingsOnOtherDevice(int count) {
    return '$count · บนอุปกรณ์อื่น';
  }

  @override
  String get pairInviteSentBodyAnyone =>
      'การจับคู่เสร็จเมื่อกระเป๋าเงินของอีกฝ่ายเปิดคำเชิญ คุณออกจากหน้านี้ได้ คำเชิญจะอยู่ที่ ผู้ติดต่อ › คำเชิญที่รออยู่';

  @override
  String get pairInvalidLink => 'นี่ไม่ใช่ลิงก์จับคู่';

  @override
  String get pairInvalidBody => 'ตรวจว่าคัดลอกลิงก์ครบทั้งหมด หรือขอลิงก์ใหม่';

  @override
  String get pairWrongNetworkBody =>
      'สร้างโดยกระเป๋าเงินในเครือข่ายอื่น กระเป๋าเงินจับคู่กันได้เฉพาะในเครือข่ายเดียวกัน';

  @override
  String get pairOwnCode => 'นี่คือโค้ดของคุณเอง';

  @override
  String get pairOwnCodeBody => 'สแกนโค้ดบนโทรศัพท์อีกเครื่อง';

  @override
  String get pairUnnamedInvite => 'คำเชิญที่เปิดอยู่';

  @override
  String get pairSeenAsMissing => 'ใส่ชื่อที่อีกฝ่ายจะเห็น';

  @override
  String get pairSeenAsTooLong => 'ใช้ชื่อที่สั้นกว่านี้';

  @override
  String get pairSeenAsEdit => 'เปลี่ยนชื่อที่อีกฝ่ายจะเห็น';

  @override
  String get pairCodeLabel => 'โค้ดจับคู่ของคุณ';

  @override
  String get pairWordsLabel => 'คำจับคู่ของคุณ';

  @override
  String get pairWordsEnteredLabel => 'คำที่ใส่แล้ว';

  @override
  String pairWordSlot(int n) {
    return 'คำที่ $n ยังไม่ได้ใส่';
  }

  @override
  String get pairSuggestions => 'คำแนะนำ';

  @override
  String get pairCopied => 'คัดลอกแล้ว';

  @override
  String get pairPaste => 'วาง';

  @override
  String get pairInPersonDone => 'สแกนโค้ดแล้ว';

  @override
  String get pairEpicboxOffNotice =>
      'หยุดไว้ขณะปิด Epicbox คำเชิญและคำตอบต้องส่งด้วยตนเอง';

  @override
  String get pairWaitingTitleShort => 'การจับคู่';

  @override
  String get pairClosed => 'ปิด';

  @override
  String get sasWordsLabel => 'สี่คำ';

  @override
  String sasDialogTitle(String name) {
    return 'ตรวจคำกับ $name';
  }

  @override
  String get contactMore => 'เพิ่มเติม';

  @override
  String get contactEdit => 'แก้ไข';

  @override
  String get contactDelete => 'ลบผู้ติดต่อ';

  @override
  String contactCopyAddress(String type) {
    return 'คัดลอกที่อยู่ $type';
  }

  @override
  String contactDeletePaired(String name) {
    return 'การลบ $name จะลบการจับคู่ด้วย การชำระเงินและใบแจ้งหนี้ที่ปิดผนึกจากผู้ติดต่อนี้จะหยุด';
  }

  @override
  String get contactNoAddresses => 'ไม่มีที่อยู่ที่บันทึกไว้';

  @override
  String addrRemove(String type) {
    return 'ลบที่อยู่ $type';
  }

  @override
  String get sendVia => 'ส่งผ่าน';

  @override
  String get invSetLeadDesktop =>
      'ผู้ติดต่อที่จับคู่แล้วซึ่งคุณอนุญาต ส่งใบแจ้งหนี้ถึงกระเป๋าเงินนี้ได้ แต่ละรายการรอรหัสผ่านกระเป๋าเงินที่ ใบแจ้งหนี้';

  @override
  String get invSetRowAllowed => 'ยืนยันแล้ว · อนุญาต';

  @override
  String get invSetRowOff => 'ยืนยันแล้ว · ปิด';

  @override
  String get invSetRowCheckFirst => 'จับคู่แล้ว ยังไม่ยืนยัน · ยืนยันก่อน';

  @override
  String invSetAllowFor(String name) {
    return 'อนุญาตใบแจ้งหนี้จาก $name';
  }

  @override
  String get reqNoPayers =>
      'ยังไม่มีผู้ติดต่อที่จับคู่แล้วซึ่งชำระใบแจ้งหนี้ได้ จับคู่และยืนยันกับอีกฝ่าย หรือบันทึกใบแจ้งหนี้เป็นไฟล์';

  @override
  String get reqPickContact => 'เลือกผู้ติดต่อ';

  @override
  String get reqFileSaved => 'บันทึกใบแจ้งหนี้เป็นไฟล์แล้ว';

  @override
  String reqSent(String name) {
    return 'ส่งใบแจ้งหนี้ถึง $name แล้ว';
  }

  @override
  String get reqFileTitle => 'ใบแจ้งหนี้';

  @override
  String noticeOutboxStuck(String name) {
    return 'ยังติดต่อ $name ไม่ได้ กำลังลองใหม่';
  }

  @override
  String noticeTooMany(String name) {
    return '$name ส่งใบแจ้งหนี้มากเกินไป ใบแจ้งหนี้ส่วนเกินถูกทิ้ง ปิดใบแจ้งหนี้ของผู้ติดต่อนี้หากยังเกิดขึ้นต่อ';
  }

  @override
  String get noticeOpen => 'เปิด';

  @override
  String get noticeCheckWords => 'ยืนยัน';

  @override
  String get noticeView => 'ดู';

  @override
  String get restorePairings => 'การจับคู่';

  @override
  String get pairingDesktopShowCodeLead =>
      'ให้อีกฝ่ายสแกนโค้ดนี้ด้วยโทรศัพท์ หรืออ่านคำจับคู่ให้ฟัง';

  @override
  String get pairingDesktopInviteLead =>
      'ส่งคำเชิญผ่านช่องทางที่คุณใช้กับอีกฝ่ายอยู่แล้ว การจับคู่เสร็จเมื่อกระเป๋าเงินของอีกฝ่ายเปิดคำเชิญ';

  @override
  String get pairingInviteOnline => 'เชิญออนไลน์';

  @override
  String pairSaveContactTitle(String name) {
    return 'บันทึก $name ในผู้ติดต่อของคุณหรือไม่';
  }

  @override
  String get pairSaveNewContact => 'บันทึกเป็นผู้ติดต่อใหม่';

  @override
  String pairAddToNamed(String name) {
    return 'เพิ่มในผู้ติดต่อ $name';
  }

  @override
  String get pairAddToAContact => 'เพิ่มในผู้ติดต่อ';

  @override
  String pairSavedAs(String name) {
    return 'บันทึกเป็น $name แล้ว';
  }

  @override
  String pairDurDays(int days, int hours) {
    return '$days วัน $hours ชั่วโมง';
  }

  @override
  String pairDurHours(int hours, int minutes) {
    return '$hours ชั่วโมง $minutes นาที';
  }

  @override
  String pairDurMinutes(int minutes) {
    return '$minutes นาที';
  }

  @override
  String get pairDurUnderMinute => 'ไม่ถึงหนึ่งนาที';

  @override
  String get pairBack => 'กลับ';

  @override
  String get pairNotInContacts => 'ไม่อยู่ในผู้ติดต่อ';

  @override
  String get pairAddToContacts => 'เพิ่มในผู้ติดต่อ';

  @override
  String get helpPairingSection => 'การจับคู่';

  @override
  String get helpPairingLede =>
      'จับคู่ครั้งเดียว ไฟล์ธุรกรรมและใบแจ้งหนี้กับผู้ติดต่อนั้นจะถูกปิดผนึก';

  @override
  String get helpPairWhatTitle => 'การจับคู่คืออะไร';

  @override
  String get helpPairWhatShort =>
      'จับคู่กับอีกฝ่ายครั้งเดียว หลังจากนั้นไฟล์ธุรกรรมและใบแจ้งหนี้ระหว่างสองกระเป๋าเงินจะถูกปิดผนึก';

  @override
  String get helpPairWhatP1 =>
      'การจับคู่เชื่อมสองกระเป๋าเงินเพียงครั้งเดียว แบบพบตัวโดยสแกนโค้ดของกันและกัน หรือออนไลน์ด้วยลิงก์คำเชิญหรือคำจับคู่ห้าคำ แต่ละกระเป๋าเงินเก็บคีย์ที่สร้างขึ้นสำหรับผู้ติดต่อนั้นเท่านั้น และไม่มีข้อมูลใดส่งไปยังเซิร์ฟเวอร์ Epicbox';

  @override
  String get helpPairWhatP2 =>
      'หลังจับคู่ ไฟล์ธุรกรรมถึงผู้ติดต่อนั้นจะ**ปิดผนึก** มีเพียงกระเป๋าเงินของอีกฝ่ายที่เปิดได้ และไม่สามารถถูกเปลี่ยนหรือปลอมระหว่างทาง การชำระเงินผ่าน Epicbox ระหว่างบุคคลยังทำงานเหมือนเดิม';

  @override
  String get helpPairWhatStep1 =>
      'เปิด [[ผู้ติดต่อ|Contacts]] แล้วเลือก **จับคู่**';

  @override
  String get helpPairWhatStep2 =>
      'เลือกวิธี: ทางวาจา, เชิญทางข้อความ หรือ แบบพบตัว';

  @override
  String get helpPairWhatStep3 => 'ยืนยันด้วยกัน แล้วเลือก **ตรงกัน**';

  @override
  String get helpPairWhatP3 =>
      'การจับคู่ต้องใช้ Epic Cash ทั้งสองฝั่ง ผู้ติดต่อที่ไม่ได้จับคู่ยังได้รับไฟล์ธุรกรรมปกติและการชำระเงินผ่าน Epicbox';

  @override
  String get helpPairWhyTitle => 'ทำไมต้องยืนยัน';

  @override
  String get helpPairWhyShort =>
      'การยืนยันพิสูจน์ว่าการจับคู่ไปถึงกระเป๋าเงินที่ถูกต้อง ไม่ใช่คนที่อยู่ตรงกลาง';

  @override
  String get helpPairWhyP1 =>
      'หลังจับคู่ ทั้งสองกระเป๋าเงินจะแสดงภาพและชื่อสี่รายการเดียวกัน ซึ่งมาจากคีย์ของทั้งสองกระเป๋าเงิน ดังนั้นการจับคู่ที่ถูกเปลี่ยนระหว่างทางจะแสดงคำต่างกันบนสองหน้าจอ';

  @override
  String get helpPairWhyP2 =>
      'เปรียบเทียบทางโทรศัพท์หรือแบบพบตัว แล้วแตะ **ตรงกัน** ผู้ติดต่อจะเป็น **ยืนยันแล้ว** ส่วน **ข้ามไปก่อน** จะคงไว้เป็น **จับคู่แล้ว ยังไม่ยืนยัน** ไฟล์ธุรกรรมยังปิดผนึก แต่ผู้ติดต่อจะส่งใบแจ้งหนี้ไม่ได้จนกว่าจะตรวจคำ';

  @override
  String get helpPairWhyP3 =>
      'หากคำต่างกัน ให้แตะ **ไม่ตรงกัน** การจับคู่จะถูกทิ้งที่ฝั่งนี้ จับคู่อีกครั้งแบบพบตัว หรือด้วยคำเชิญใหม่';

  @override
  String get helpPairWhyP4 =>
      'ชื่อของคำจะเป็นภาษาอังกฤษในทุกภาษา เพื่อให้คนสองคนที่ใช้กระเป๋าเงินคนละภาษายังเทียบกันได้';

  @override
  String get helpPairWordsTitle => 'คำเชิญทางวาจา';

  @override
  String get helpPairWordsShort =>
      'ภาพห้าภาพพร้อมชื่อใช้แทนลิงก์ได้เมื่อไม่มีอะไรให้สแกนหรือวาง';

  @override
  String get helpPairWordsP1 =>
      'เมื่อกระเป๋าเงินหนึ่งไม่มีกล้อง หรือส่งคำเชิญเป็นลิงก์ไม่ได้ กระเป๋าเงินที่เชิญจะแสดงคำจับคู่ห้าคำ อีกฝ่ายพิมพ์ชื่อเหล่านั้นที่ **ได้รับคำหรือลิงก์มาแล้ว?** ช่องจะเติมชื่อให้หลังพิมพ์ไม่กี่ตัวอักษร คำเหล่านี้ใช้ได้ 10 นาที';

  @override
  String get helpPairWordsP2 =>
      'คำเหล่านี้ใช้หาคำเชิญเท่านั้น ใครที่มีคำเหล่านี้อยู่ในสถานะเดียวกับคนที่ได้รับลิงก์ หลังจากนั้นจึงต้องตรวจสี่คำด้วยกันตามปกติ';

  @override
  String get helpPairWordsP3 =>
      'คำเชิญทางวาจาต้องใช้ Epicbox ขณะปิด Epicbox ให้ส่งลิงก์คำเชิญแทน';

  @override
  String get helpPairInvTitle => 'ใบแจ้งหนี้จากผู้ติดต่อที่จับคู่แล้ว';

  @override
  String get helpPairInvShortDesktop =>
      'มีเพียงผู้ติดต่อที่ยืนยันแล้วซึ่งคุณอนุญาตที่ขอให้คุณชำระเงินได้ แต่ละใบแจ้งหนี้จะรอ รหัสผ่านกระเป๋าเงิน';

  @override
  String get helpPairInvShort =>
      'มีเพียงผู้ติดต่อที่ยืนยันแล้วซึ่งคุณอนุญาตที่ขอให้คุณชำระเงินได้ แต่ละใบแจ้งหนี้จะรอ PIN ของคุณ';

  @override
  String get helpPairInvP1 =>
      'ร้านค้า ศูนย์แลกเปลี่ยน หรือบุคคลที่คุณจับคู่ด้วย ส่งใบแจ้งหนี้ได้หากคุณอนุญาต: **อนุญาตใบแจ้งหนี้** ที่หน้าผู้ติดต่อ หรือที่ [[การตั้งค่า › ใบแจ้งหนี้|Settings › Invoices]] สวิตช์นี้ใช้ได้เฉพาะผู้ติดต่อที่ยืนยันแล้ว';

  @override
  String get helpPairInvP2Desktop =>
      'ใบแจ้งหนี้จะแสดงที่ [[ใบแจ้งหนี้ › ชำระ|Invoices › Pay]] พร้อมชื่อผู้ติดต่อ จำนวนเงิน และเลขอ้างอิง จะไม่มีการชำระจนกว่าคุณจะอนุมัติด้วยรหัสผ่านกระเป๋าเงิน ใบแจ้งหนี้ไม่เคยเพิ่มเงินเข้ากระเป๋าเงินของคุณ';

  @override
  String get helpPairInvP2 =>
      'ใบแจ้งหนี้จะแสดงที่ [[ใบแจ้งหนี้ › ชำระ|Invoices › Pay]] พร้อมชื่อผู้ติดต่อ จำนวนเงิน และเลขอ้างอิง จะไม่มีการชำระจนกว่าคุณจะอนุมัติด้วย PIN ใบแจ้งหนี้ไม่เคยเพิ่มเงินเข้ากระเป๋าเงินของคุณ';

  @override
  String get helpPairInvP3 =>
      'การปิดสวิตช์มีผลทันที ใบแจ้งหนี้ใหม่จากผู้ติดต่อนั้นจะถูกทิ้ง และใบแจ้งหนี้ที่ค้างอยู่จะถูกปฏิเสธ';

  @override
  String get helpPairInvP4 =>
      'ศูนย์แลกเปลี่ยนที่จับคู่กับคุณใช้วิธีนี้ในการฝากและถอน ฝาก: ศูนย์แลกเปลี่ยนขอ คุณอนุมัติ ศูนย์แลกเปลี่ยนประกาศ ถอน: ศูนย์แลกเปลี่ยนส่งการชำระเงิน กระเป๋าเงินของคุณตอบเอง ศูนย์แลกเปลี่ยนประกาศ';

  @override
  String get helpPairRestoreTitle => 'การกู้คืนทำอะไรบ้าง';

  @override
  String get helpPairRestoreShort =>
      'การกู้คืนจากวลีกู้คืนพร้อมไฟล์ข้อมูลกระเป๋าเงินจะนำการจับคู่ทั้งหมดกลับมา หากไม่มีไฟล์ การจับคู่ใหม่จะพบคีย์เดิม';

  @override
  String get helpPairRestoreP1 =>
      'เมื่อมีไฟล์ข้อมูลกระเป๋าเงิน การกู้คืนจะนำการจับคู่ทั้งหมดกลับมาโดยไม่เปลี่ยน คีย์เดิม เครื่องหมายยืนยันแล้วเดิม การตั้งค่าเดิม ผู้ติดต่อจะไม่สังเกตเห็นอะไร';

  @override
  String get helpPairRestoreP2 =>
      'หากไม่มีไฟล์ การจับคู่จะหายไปจากกระเป๋าเงินนี้ แต่คีย์ไม่หาย เพราะมาจากวลีกู้คืน จับคู่อีกครั้งกับผู้ติดต่อที่ยังเก็บการจับคู่ไว้ แล้วกระเป๋าเงินของอีกฝ่ายจะพบคีย์เดิม และแจ้งว่าคีย์กลับมาแล้ว ผู้ติดต่อยังคงเครื่องหมายยืนยันแล้ว ในกระเป๋าเงินนี้ ปิดผนึกการชำระเงิน และ อนุญาตใบแจ้งหนี้ จะกลับเป็นค่าเริ่มต้น';

  @override
  String get helpPairRestoreP3 =>
      'ผู้ติดต่อจะเห็น **คีย์เปลี่ยน** เฉพาะเมื่อวลีเป็นวลีอื่น ซึ่งอาจหมายถึงกระเป๋าเงินใบใหม่ หรือมีคนอื่นใช้ชื่อนี้ ตรวจคำอีกครั้งก่อนเชื่อถือ';

  @override
  String get helpPairRestoreP4 =>
      'ใช้การจับคู่บนอุปกรณ์เดียวในแต่ละครั้ง ข้อมูลกระเป๋าเงินที่นำเข้าบนอุปกรณ์เครื่องที่สองจะถามก่อนใช้ผู้ติดต่อที่นั่น';

  @override
  String get pairNameForCode =>
      'ใส่ชื่อที่อีกฝ่ายจะเห็น แล้วโค้ดของคุณจะแสดงที่นี่';

  @override
  String get pairYourNamePlaceholder => 'ชื่อของคุณ';

  @override
  String get deskConPickForPairing =>
      'การจับคู่จะเพิ่มไปยังผู้ติดต่อที่คุณเลือก';

  @override
  String txDetailsCancelHold(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ยกเลิกได้ในอีก $minutes นาที ถ้าผู้ส่งยังไม่เผยแพร่รายการ',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsCancelWhileReported =>
      'ยกเลิกไม่ได้ขณะที่ผู้ส่งรายงานว่าเผยแพร่แล้ว';

  @override
  String get txDetailsCancelRefusedOnNetwork =>
      'ไม่ได้ยกเลิก เครือข่ายมีรายการนี้แล้ว รายการจะสำเร็จเมื่อบล็อกเชนยืนยัน';

  @override
  String get contactStar => 'ติดดาว';

  @override
  String get contactUnstar => 'เลิกติดดาว';

  @override
  String get contactStarred => 'ติดดาวแล้ว';

  @override
  String get contactsImport => 'นำเข้าผู้ติดต่อ';

  @override
  String get contactsExport => 'ส่งออกผู้ติดต่อ';

  @override
  String contactsExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ส่งออกผู้ติดต่อ $count รายแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get contactsExportHolds =>
      'ไฟล์มีชื่อ บันทึก และที่อยู่ ไม่มีคีย์หรือการจับคู่';

  @override
  String get contactsImportTitle => 'นำเข้าผู้ติดต่อไหม';

  @override
  String contactsImportNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ผู้ติดต่อใหม่ $count ราย',
    );
    return '$_temp0';
  }

  @override
  String contactsImportMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อัปเดตผู้ติดต่อ $count ราย',
    );
    return '$_temp0';
  }

  @override
  String contactsImportSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'มีอยู่แล้ว $count ราย',
    );
    return '$_temp0';
  }

  @override
  String contactsImportLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้าม $count ราย: ไม่มีที่อยู่ที่กระเป๋าเงินนี้ส่งไปได้',
    );
    return '$_temp0';
  }

  @override
  String contactsImportOtherNet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้าม $count ราย: ที่อยู่ของเครือข่ายอื่น',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportKeeps => 'ข้อมูลที่มีอยู่จะคงไว้';

  @override
  String get contactsImportDo => 'นำเข้า';

  @override
  String get contactsImportNothing => 'ไม่มีอะไรให้นำเข้า';

  @override
  String contactsImported(int added, int same) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $added ราย',
    );
    String _temp1 = intl.Intl.pluralLogic(
      same,
      locale: localeName,
      other: 'มีอยู่แล้ว $same ราย',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String contactsImportedAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'เพิ่มผู้ติดต่อ $added รายแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportNotFile => 'ไฟล์นี้ไม่ใช่ไฟล์ผู้ติดต่อ';

  @override
  String get contactsImportDamaged => 'อ่านไฟล์ไม่ได้ ไฟล์อาจเสียหาย';

  @override
  String get contactsImportNewer =>
      'ไฟล์นี้สร้างจาก Epic Cash เวอร์ชันใหม่กว่า อัปเดตก่อนจึงจะนำเข้าได้';

  @override
  String get contactsImportEmpty => 'ไฟล์นี้ไม่มีผู้ติดต่อ';

  @override
  String get contactsImportAllOtherNet =>
      'ผู้ติดต่อเหล่านี้เป็นของเครือข่ายอื่น ใช้ที่นี่ไม่ได้เลย';

  @override
  String get expPairing => 'การจับคู่';

  @override
  String get expPairingHint =>
      'จับคู่ครั้งเดียวกับคนที่ชำระเงินกันบ่อย จากนั้นไฟล์ธุรกรรมและใบแจ้งหนี้ระหว่างสองกระเป๋าเงินจะถูกปิดผนึก และผู้ติดต่อจะแสดงว่าจับคู่แล้ว เป็นฟีเจอร์ทดลอง: อาจยังเปลี่ยนแปลงได้';

  @override
  String get expInvoices => 'ใบแจ้งหนี้';

  @override
  String get expInvoicesHint =>
      'ขอรับเงินจากผู้ติดต่อที่จับคู่แล้ว และอนุมัติใบแจ้งหนี้ที่ผู้ติดต่อที่จับคู่แล้วส่งมา ต้องเปิดการจับคู่ เป็นฟีเจอร์ทดลอง: อาจยังเปลี่ยนแปลงได้';

  @override
  String get expNeedsPairing => 'ใบแจ้งหนี้ต้องใช้การจับคู่';

  @override
  String get expPairingOffTitle => 'การจับคู่เป็นฟีเจอร์ทดลอง';

  @override
  String get expPairingOffBody => 'เปิดได้ที่ การตั้งค่า › ขั้นสูง';

  @override
  String get expInvoicesOffTitle => 'ใบแจ้งหนี้เป็นฟีเจอร์ทดลอง';

  @override
  String get expInvoicesOffBody => 'เปิดได้ที่ การตั้งค่า › ขั้นสูง';

  @override
  String get expOpenAdvanced => 'เปิดขั้นสูง';

  @override
  String get contactNoAddressPaired => 'การชำระเงินผ่านการจับคู่';

  @override
  String get contactSendKeysChanged => 'ยืนยันผู้ติดต่อก่อนส่ง';

  @override
  String contactSendNoSealed(String name) {
    return 'กระเป๋าของ $name ไม่รับการชำระเงินผ่านการจับคู่ ขอที่อยู่แทน';
  }

  @override
  String sendRecipientPairing(String name) {
    return 'ผ่านการจับคู่กับ $name';
  }

  @override
  String get sendClearRecipient => 'ล้างผู้รับ';

  @override
  String get sendQueuedEpicboxOff =>
      'Epicbox ปิดอยู่ การชำระเงินรออยู่ที่นี่และจะส่งออกเมื่อเปิด Epicbox อีกครั้ง';

  @override
  String get sendQueue => 'เข้าคิวการชำระเงิน';

  @override
  String get sendQueuedHeadline => 'การชำระเงินเข้าคิวแล้ว';

  @override
  String sendQueuedBody(String name) {
    return 'จะส่งออกเมื่อเปิด Epicbox อีกครั้ง คำตอบของ $name จะกลับมาทางเดียวกัน';
  }

  @override
  String txStatusWaitingFor(String name) {
    return 'รอ $name';
  }

  @override
  String txStepSentMailbox(String name) {
    return 'ส่งผ่านเซิร์ฟเวอร์ Epicbox ของ $name แล้ว';
  }

  @override
  String txStepAnswerFrom(String name) {
    return 'คำตอบจาก $name';
  }

  @override
  String txStepCollecting(String name) {
    return 'กำลังตรวจเซิร์ฟเวอร์ Epicbox ของ $name';
  }

  @override
  String deskTxStatusWaitingFor(String name) {
    return 'รอ $name ลงนาม';
  }

  @override
  String deskSendContactNoLink(String name) {
    return '$name ไม่มีที่อยู่ Link';
  }

  @override
  String get reqToFile => 'บันทึกเป็นไฟล์สำหรับใครก็ได้';

  @override
  String reqFileSummary(String amount) {
    return 'ใครก็ตามที่เปิดไฟล์นี้ชำระ $amount ได้ คำตอบจะกลับมาเป็นไฟล์';
  }

  @override
  String get reqSaveFile => 'บันทึกเป็นไฟล์';

  @override
  String get reqFileLead =>
      'ส่งไฟล์นี้ให้คนที่ต้องชำระ กระเป๋าเงินของเขาจะตอบกลับเป็นไฟล์ เปิดไฟล์นั้นที่นี่เพื่อทำรายการให้เสร็จ';

  @override
  String get reqByFile => 'ผ่านไฟล์';

  @override
  String get reqToAnyone => 'ใครก็ได้ที่มีไฟล์';

  @override
  String get reqFileWaitingCard =>
      'รอไฟล์ตอบกลับ เปิดได้จากรับเงินหรือแตะที่ไฟล์';

  @override
  String get reqFromFileTitle => 'ใบแจ้งหนี้จากไฟล์';

  @override
  String get reqFromFileWarn =>
      'ไม่มีข้อมูลว่าใครสร้างใบแจ้งหนี้นี้ ชำระเฉพาะเมื่อคุณรอใบแจ้งหนี้นี้จากคนที่คุณรู้จัก';

  @override
  String get reqFileMessageLabel => 'ข้อความในไฟล์';

  @override
  String get reqApproveSaveAnswer => 'อนุมัติและบันทึกคำตอบ';

  @override
  String get reqNotNow => 'ไว้ทีหลัง';

  @override
  String get reqAnswerTitle => 'บันทึกคำตอบแล้ว';

  @override
  String get reqAnswerLead =>
      'ส่งไฟล์นี้คืนให้คนที่ขอ เขาจะทำรายการให้เสร็จและส่งเข้าเครือข่าย';

  @override
  String get reqFileAlreadyPaid => 'ใบแจ้งหนี้นี้ชำระแล้ว';

  @override
  String get reqFileEnded => 'ใบแจ้งหนี้นี้สิ้นสุดแล้ว';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return 'คำตอบสำหรับใบแจ้งหนี้ $amount ของคุณ';
  }

  @override
  String get reqAnswerUnknown =>
      'นี่เป็นคำตอบของใบแจ้งหนี้ที่กระเป๋าเงินนี้ไม่มีแล้ว';

  @override
  String get deskInvIssuerAnother => 'สร้างใบแจ้งหนี้อีกรายการ';

  @override
  String get deskImpOpenAnother => 'เปิดไฟล์อื่น';

  @override
  String get deskInvIssuerToAnyone => 'ใบแจ้งหนี้ถึงใครก็ได้ที่มีไฟล์';

  @override
  String deskOnbImportRelayTitle(String name) {
    return 'เซิร์ฟเวอร์ Epicbox สำหรับ $name';
  }

  @override
  String deskOnbImportRelayLead(String old) {
    return 'แอปเดิมรับผ่าน $old';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return 'ใช้ $old ต่อไป';
  }

  @override
  String get deskOnbImportRelayKeepHint =>
      'ที่อยู่เดิม เซิร์ฟเวอร์จะถูกเพิ่มในรายการ Epicbox';

  @override
  String deskOnbImportRelayApp(String current) {
    return 'ใช้ $current';
  }

  @override
  String get deskOnbImportRelayAppHint =>
      'ที่อยู่ใหม่: รายการที่ส่งไปที่อยู่เดิมจะไม่ถึง';

  @override
  String get deskOnbImportUnlockOld => 'ปลดล็อกด้วยรหัสผ่านเดิม';

  @override
  String get deskOnbImportUnlockNew =>
      'ปลดล็อกด้วยรหัสผ่านใหม่ที่ตั้งไว้ที่นี่';

  @override
  String get deskOnbWelcomeOtherApps =>
      'มาจาก Stack Wallet หรือ Epic Pay: กู้คืนด้วยวลีกู้คืน';

  @override
  String get deskOnbImportCloseFirstWindows =>
      'ปิด Epic Wallet รุ่นเก่าก่อนนำเข้า บน Windows ตรวจไม่ได้ว่ายังเปิดอยู่หรือไม่';

  @override
  String get deskSetRecvEpicboxOwnHint =>
      'กระเป๋าเงินนี้มีเซิร์ฟเวอร์ Epicbox ของตัวเองที่เก็บไว้จากแอปเดิม การเปลี่ยนที่นี่มีผลกับกระเป๋าเงินนี้เท่านั้น';

  @override
  String get deskErrRestoreScanRequired =>
      'การกู้คืนยังไม่เสร็จ เมื่อสแกนบล็อกเชนเสร็จจึงรับและส่งได้';

  @override
  String get deskSetupSkip => 'ข้ามการตั้งค่า';

  @override
  String get deskOvRestoreTitle => 'การกู้คืนยังไม่เสร็จ';

  @override
  String get deskOvRestoreRunning =>
      'กำลังค้นหายอดเงินของกระเป๋าเงินนี้บนบล็อกเชนตั้งแต่บล็อกแรก EPIC ที่ได้รับจะแสดงตามที่พบ เมื่อสแกนเสร็จจึงรับและส่งได้';

  @override
  String deskOvRestoreAfterHeight(String height) {
    return 'พบยอดเงินหลังบล็อก $height แล้ว กำลังตรวจบล็อกก่อนหน้า เมื่อเสร็จจึงรับและส่งได้';
  }

  @override
  String get deskOvRestoreWaiting => 'การสแกนรอการเชื่อมต่อเครือข่าย';

  @override
  String get deskOvRestoreFailed =>
      'การสแกนหยุดก่อนจบ รับและส่งไม่ได้จนกว่าจะสแกนเสร็จ';

  @override
  String get deskOvRestoreProgress => 'ความคืบหน้าการสแกนกู้คืน';

  @override
  String get deskSetRescanRestoreRunning =>
      'กำลังสแกนหลังกู้คืน: อ่านบล็อกเชนตั้งแต่บล็อกแรก ตรวจยอดใหม่ได้เมื่อสแกนเสร็จ';

  @override
  String get deskSetRescanStartHeading => 'เริ่มจากตรงไหน';

  @override
  String get deskSetRescanRecent => 'บล็อกล่าสุด';

  @override
  String get deskSetRescanRecentHint =>
      'จาก 100 บล็อกก่อนบล็อกล่าสุดที่สแกน เพียงพอหลังส่งไม่สำเร็จหรือยอดดูไม่ถูก';

  @override
  String get deskSetRescanFromHeight => 'จากความสูงบล็อก';

  @override
  String get deskSetRescanHeightInvalid => 'ใส่ความสูงบล็อกตั้งแต่ 1 ขึ้นไป';

  @override
  String get deskSetRescanWholeChain => 'ทั้งบล็อกเชน';

  @override
  String get deskSetRescanWholeChainHint =>
      'ตั้งแต่บล็อกแรก พบทุกอย่างแต่ใช้เวลานาน และทำให้การกู้คืนที่ค้างอยู่เสร็จด้วย';

  @override
  String get deskOnbForgotLink => 'ลืมรหัสผ่าน?';

  @override
  String get deskOnbForgotTitle => 'ตั้งรหัสผ่านใหม่';

  @override
  String deskOnbForgotLead(String name) {
    return 'วลีกู้คืนของ $name ใช้แทนรหัสผ่านได้ ประวัติ บันทึก และป้ายกำกับยังอยู่ ไม่ต้องสแกน';
  }

  @override
  String get deskOnbForgotPasswordLead =>
      'วลีถูกต้อง เลือกรหัสผ่านใหม่สำหรับปลดล็อกกระเป๋าเงินนี้บนคอมพิวเตอร์นี้';

  @override
  String get deskOnbForgotSet => 'ตั้งรหัสผ่าน';

  @override
  String deskOnbForgotOtherWallet(String name) {
    return 'วลีนี้เป็นของกระเป๋าเงินอื่น ไม่ใช่ $name ไม่มีอะไรเปลี่ยน';
  }

  @override
  String get deskOnbSameNewPassword => 'ตั้งรหัสผ่านใหม่';

  @override
  String get deskSetupSkipKeeps =>
      'การข้ามจะคงการตั้งค่าโหนดและ Epicbox ปัจจุบันไว้';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return 'บันทึกว่าตั้งค่าเสร็จไม่ได้: $reason ครั้งหน้าอาจแสดงอีก กด ข้ามการตั้งค่า เพื่อออก';
  }

  @override
  String get deskOvRestoredImportTitle => 'นำประวัติและการตั้งค่ากลับมา?';

  @override
  String get deskOvRestoredImportBody =>
      'วลีกู้คืนนำยอดคงเหลือกลับมาแล้ว ไฟล์ข้อมูลกระเป๋าเงินที่ส่งออกจากกระเป๋าเงินนี้จะนำประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่ากลับมา: คือไฟล์ที่บันทึกไว้นอกคอมพิวเตอร์เครื่องเก่า';

  @override
  String get deskOvRestoredImportButton => 'นำเข้าข้อมูลกระเป๋าเงิน';

  @override
  String get deskOvRestoredImportLater =>
      'ทำทีหลังได้ที่ การตั้งค่า › กระเป๋าเงินนี้ › ข้อมูลกระเป๋าเงิน';

  @override
  String get deskOnbForgotNoCheck =>
      'ไฟล์ของกระเป๋าเงินนี้ยืนยันวลีไม่ได้ รหัสผ่านจึงยังเหมือนเดิม';

  @override
  String deskOnbForgotRestoreHint(String name) {
    return 'ให้กู้คืนจากวลีแทน: $name จะออกจากรายการ และไฟล์ยังอยู่บนคอมพิวเตอร์นี้';
  }

  @override
  String get deskOnbForgotRestoreInstead => 'กู้คืนจากวลี';

  @override
  String get qrShowTitleRequest => 'ใบแจ้งหนี้';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount จากโทรศัพท์ที่อยู่ข้างคุณ';
  }

  @override
  String get qrHiddenBodyRequest =>
      'ใครสแกนก็ชำระใบแจ้งหนี้นี้ได้ แสดงให้เฉพาะคนที่จ่ายเท่านั้น';

  @override
  String get qrStatusRequestHidden => 'แสดงสิ่งนี้ให้คนที่จ่าย';

  @override
  String get qrStatusRequestShowing =>
      'รอเขาสแกนและอนุมัติ แล้วสแกนคำตอบของเขา';

  @override
  String qrSemanticsRequest(String state) {
    return 'QR ของใบแจ้งหนี้, $state';
  }

  @override
  String qrShowSubPaid(String amount) {
    return 'ถึงคนที่ขอ $amount';
  }

  @override
  String get qrHiddenBodyPaid =>
      'แสดงให้โทรศัพท์ที่ขอชำระเงิน เฉพาะกระเป๋านั้นเท่านั้นที่ใช้ได้';

  @override
  String get qrStatusPaidHidden => 'แสดงสิ่งนี้ให้คนที่ขอ';

  @override
  String get qrStatusPaidShowing => 'รอเขาสแกนและส่งเข้าเครือข่าย';

  @override
  String get qrStatusPaid => 'ชำระแล้ว';

  @override
  String get reqToQr => 'แสดงเป็น QR ให้โทรศัพท์ที่อยู่ใกล้';

  @override
  String reqQrSummary(String amount) {
    return 'ใครสแกนโค้ดก็ชำระ $amount ได้ สแกนคำตอบของเขาที่นี่เพื่อทำให้เสร็จ ใบแจ้งหนี้หมดอายุใน 24 ชั่วโมง';
  }

  @override
  String get reqShowQr => 'แสดงเป็น QR';

  @override
  String get receiveQrRequest => 'ขอจำนวนเงิน';

  @override
  String get reqQrPaidTitle => 'ชำระแล้ว';

  @override
  String reqQrPaidHeadline(String amount) {
    return 'ชำระ $amount แล้วและส่งเข้าเครือข่ายแล้ว';
  }

  @override
  String get reqQrNew => 'ใบแจ้งหนี้ใหม่';

  @override
  String get reqQrAlreadyPaid =>
      'ใบแจ้งหนี้นี้ชำระแล้ว ไม่มีอะไรถูกหักจากโทรศัพท์เครื่องนี้ รายการของเขาจะถูกล็อกจนกว่าเขาจะยกเลิกในประวัติ หรือหมดอายุหลังจากหนึ่งวัน';

  @override
  String get reqFromQrTitle => 'ใบแจ้งหนี้จาก QR';

  @override
  String get reqFromQrWarn =>
      'ไม่ได้มาจากผู้ติดต่อที่จับคู่ไว้ ไม่มีข้อมูลในโค้ดว่าใครสร้าง ชำระให้เฉพาะคนหรือร้านที่อยู่ตรงหน้าคุณ และตรวจสอบจำนวนเงิน';

  @override
  String get reqQrMessageLabel => 'ข้อความในโค้ด';

  @override
  String get reqApproveShowAnswer => 'อนุมัติและแสดงคำตอบ';

  @override
  String get reqQrAnswerTitle => 'อนุมัติแล้ว';

  @override
  String get reqQrAnswerLead =>
      'คนที่ขอจะสแกนคำตอบและส่งรายการเข้าเครือข่าย ระหว่างนั้นรายการจะรออยู่ในประวัติเป็น “รอผู้รับ”';

  @override
  String get reqExpired =>
      'ใบแจ้งหนี้นี้หมดอายุแล้ว ขอใบแจ้งหนี้ใหม่ ไม่มีการชำระใดๆ';

  @override
  String get reqOtherChain =>
      'ใบแจ้งหนี้นี้เป็นของเครือข่าย Epic อื่น หรือกำหนดเวลาไม่ตรงกับเครือข่ายนี้ ไม่มีการชำระใดๆ';

  @override
  String get reqQrOpenNote =>
      'เปิดอยู่ใน ใบแจ้งหนี้ › ส่งแล้ว เป็นเวลา 24 ชั่วโมง แล้วจะหมดอายุ';

  @override
  String get reqQrWrongReply =>
      'คำตอบนี้เป็นของใบแจ้งหนี้อื่น สแกนคำตอบของใบแจ้งหนี้นี้';

  @override
  String get backupFileHolds =>
      'เก็บประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่าของกระเป๋าเงินนี้ ถึงปัจจุบัน';

  @override
  String get backupFileRestoreOrder =>
      'การกู้คืน: ใส่วลีกู้คืนก่อน แล้วจึงนำเข้าไฟล์นี้';

  @override
  String get backupImportLead =>
      'นำประวัติรายการ ผู้ติดต่อ ใบแจ้งหนี้ และการตั้งค่าของกระเป๋าเงินนี้กลับมา กู้คืนกระเป๋าเงินจากวลีกู้คืนก่อน';

  @override
  String backupRestoredSummary(String items) {
    return 'นำเข้าแล้ว: $items';
  }

  @override
  String get backupListSeparator => ', ';

  @override
  String get backupListLastSeparator => ' และ ';

  @override
  String backupRestoredPayments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'การชำระเงิน $n รายการ',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredNotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'บันทึก $n รายการ',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredLabels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ป้ายกำกับ $n รายการ',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredContacts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ผู้ติดต่อ $n ราย',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredStars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ผู้ติดต่อติดดาว $n ราย',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredPairings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'การจับคู่ $n รายการ',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredInvoices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ใบแจ้งหนี้ $n ใบ',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoredSettings => 'การตั้งค่า';

  @override
  String get backupRestoredWalletName => 'ชื่อกระเป๋าเงิน';

  @override
  String backupRestoredAlreadyHere(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ส่วนอีก $n รายการมีอยู่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsTitle => 'ใช้การตั้งค่าจากไฟล์นี้?';

  @override
  String backupSettingsBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'การตั้งค่าที่นี่ $n รายการต่างจากไฟล์',
    );
    return '$_temp0 ส่วนที่เหลือของไฟล์นำเข้าแล้ว';
  }

  @override
  String get backupSettingsUseBackup => 'ใช้ของไฟล์';

  @override
  String get backupSettingsKeepMine => 'เก็บของฉัน';

  @override
  String get backupFromOtherWallet =>
      'ไฟล์นี้เป็นของกระเป๋าเงินอื่น เปิดได้เฉพาะกระเป๋าเงินที่กู้คืนจากวลีกู้คืนเดียวกัน';

  @override
  String get deskEpicboxBlockedWord => 'ถูกบล็อก';

  @override
  String deskEpicboxBlockedText(String host) {
    return 'เครือข่ายนี้บล็อก $host เลือกเซิร์ฟเวอร์ Epicbox อื่นหรือใช้ DNS ส่วนตัว';
  }

  @override
  String deskEpicboxBlockedSwitch(String host) {
    return 'สลับไปที่ $host';
  }

  @override
  String get deskSlotNow => 'ตอนนี้';

  @override
  String get deskSlotHelp => 'ช่วยเหลือ';

  @override
  String get deskSlotScanning => 'กำลังสแกนเชน';

  @override
  String get deskSlotScanWaits => 'การสแกนรอเครือข่าย';

  @override
  String get deskSlotScanStopped => 'การสแกนหยุดแล้ว';

  @override
  String get deskSlotTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskSlotSending => 'กำลังส่งการชำระเงิน';

  @override
  String get deskSlotPaymentOut => 'การชำระเงินกำลังดำเนินการ';

  @override
  String get deskSlotPaymentIn => 'การชำระเงินกำลังเข้ามา';

  @override
  String get deskSlotPaymentsOut => 'การชำระเงินกำลังดำเนินการ';

  @override
  String get deskSlotPaymentsMoving => 'กำลังยืนยันการชำระ';

  @override
  String deskSlotOf(String done, String needed) {
    return '$done จาก $needed';
  }

  @override
  String get deskSlotWaitingBlock => 'รอบล็อก';

  @override
  String get deskSlotRequests => 'ใบแจ้งหนี้ใหม่';

  @override
  String get deskSlotNodeStarting => 'โหนดในเครื่องกำลังเริ่ม';

  @override
  String get deskSlotNodeSyncing => 'โหนดในเครื่องกำลังซิงก์';

  @override
  String get deskSlotOpenRecheck => 'เปิดตรวจยอดใหม่';

  @override
  String get deskSlotOpenSend => 'เปิดส่ง';

  @override
  String get deskSlotOpenActivity => 'เปิดในประวัติ';

  @override
  String get deskSlotOpenInvoices => 'เปิดใบแจ้งหนี้';

  @override
  String deskBarMenu(String app) {
    return 'เมนู $app';
  }

  @override
  String get deskBarLock => 'ล็อกกระเป๋าเงิน';

  @override
  String get deskBarShortcuts => 'แป้นพิมพ์ลัด';

  @override
  String deskBarAbout(String app) {
    return 'เกี่ยวกับ $app';
  }

  @override
  String get deskBarQuit => 'ออก';

  @override
  String get deskBarWalletsHere => 'กระเป๋าเงินในคอมพิวเตอร์เครื่องนี้';

  @override
  String get deskBarAddWallet => 'เพิ่มกระเป๋าเงิน';

  @override
  String get deskBarWalletSettings => 'การตั้งค่ากระเป๋าเงิน';

  @override
  String get deskBarStatus => 'สถานะการเชื่อมต่อ';

  @override
  String get deskBarMinimise => 'ย่อ';

  @override
  String get deskBarMaximise => 'ขยายเต็มจอ';

  @override
  String get deskBarRestore => 'คืนขนาด';

  @override
  String get deskBarClose => 'ปิด';

  @override
  String get deskBarSendRunningTitle => 'มีการส่งที่กำลังดำเนินอยู่';

  @override
  String get deskBarSendRunningBody =>
      'หากปิดตอนนี้ จะไม่ทราบผลของการชำระเงิน กระเป๋าเงินปิดเองได้เมื่อการส่งเสร็จแล้ว';

  @override
  String get deskBarKeepOpen => 'เปิดไว้';

  @override
  String get deskBarCloseAfterSend => 'ปิดเมื่อเสร็จ';

  @override
  String get deskBarClosesAfterSend => 'จะปิดเมื่อการส่งเสร็จ';

  @override
  String get deskBarClosing => 'กำลังปิด';

  @override
  String get deskBarKeyBack => 'ย้อนกลับ';

  @override
  String get deskBarKeyForward => 'ไปข้างหน้า';

  @override
  String get deskBarKeyClose => 'ปิดเมนูหรือหน้าต่าง';

  @override
  String get deskBarKeySubmit => 'ทำคำสั่งหลักของแบบฟอร์ม';

  @override
  String get deskBarKeyList => 'รายการนี้';

  @override
  String get deskBarCopyBuild => 'คัดลอกข้อมูลบิลด์';

  @override
  String get deskBarBuildCopied => 'คัดลอกข้อมูลบิลด์แล้ว';

  @override
  String deskBarBuildTip(String version, String commit) {
    return 'เวอร์ชัน $version คอมมิต $commit คลิกเพื่อคัดลอกข้อมูลบิลด์';
  }

  @override
  String deskBarBuildTipRebuild(String version, String rebuild, String commit) {
    return 'เวอร์ชัน $version บิลด์ใหม่ $rebuild คอมมิต $commit คลิกเพื่อคัดลอกข้อมูลบิลด์';
  }

  @override
  String deskBarBuildTipDev(String version) {
    return 'เวอร์ชัน $version บิลด์สำหรับพัฒนา คลิกเพื่อคัดลอกข้อมูลบิลด์';
  }

  @override
  String get deskBarKeyMenu => 'เปิดเมนูแอป';

  @override
  String get txDetailsCancelRequestBody => 'อีกฝ่ายยังทำรายการนี้ให้เสร็จได้';

  @override
  String get txDetailsCancelNotPostedBody =>
      'รายการนี้ยังอาจสำเร็จได้ในภายหลัง';

  @override
  String get cancelMoreInHelp => 'การยกเลิกทำงานอย่างไร';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '$amount EPIC ถึง $who รายการนี้ยังอาจสำเร็จได้ในภายหลัง';
  }

  @override
  String get deskOnbWalletNameEdit => 'แก้ไขชื่อกระเป๋าเงิน';

  @override
  String get deskOnbWalletNameField => 'ชื่อกระเป๋าเงิน';

  @override
  String deskOnbWalletNameIs(String name) {
    return 'ชื่อกระเป๋าเงิน: $name';
  }

  @override
  String sendTurnOnMethod(String method) {
    return 'เปิด $method';
  }

  @override
  String get reqPickContactOrMethod => 'เลือกผู้ติดต่อหรือวิธี';

  @override
  String deskOnbUnlockOpened(String when) {
    return 'เปิดล่าสุด $when';
  }

  @override
  String get deskOwnYourNode => 'โหนดของตัวเอง';

  @override
  String deskOwnLabel(String where) {
    return 'โหนดของตัวเอง · $where';
  }

  @override
  String get deskOwnClassThisComputer => 'คอมพิวเตอร์เครื่องนี้';

  @override
  String get deskOwnClassHome => 'เครือข่ายในบ้าน';

  @override
  String get deskOwnClassVpn => 'VPN';

  @override
  String get deskOwnFactMempool => 'Mempool';

  @override
  String get deskOwnPoolEmpty => 'ว่าง';

  @override
  String deskOwnPoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รอ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String deskOwnSourceSite(String site) {
    return 'ถามโดยตรงทุก 15 วิ · ความสูงล่าสุดจาก $site';
  }

  @override
  String deskOwnSourceNodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ถามโดยตรงทุก 15 วิ · ความสูงล่าสุดจากโหนดสาธารณะ $count โหนด',
    );
    return '$_temp0';
  }

  @override
  String get deskOwnSourceNone =>
      'ถามโดยตรงทุก 15 วิ · ไม่มีความสูงของเครือข่ายให้เทียบ';

  @override
  String get deskOwnSyncingLine =>
      'จนกว่าจะซิงค์เสร็จ กระเป๋าส่งหรือรับผ่านโหนดนี้ไม่ได้';

  @override
  String get deskOwnAccess => 'สิทธิ์เจ้าของ';

  @override
  String get deskOwnAccessHint =>
      'รหัสลับเจ้าของของโหนดจะแสดงขั้นการซิงค์และ peer ที่นี่ และให้แบน peer ได้ เก็บไว้ในพวงกุญแจของคอมพิวเตอร์เครื่องนี้ ไม่อยู่ในการตั้งค่าหรือไฟล์ข้อมูลกระเป๋า';

  @override
  String get deskOwnAccessNotSet => 'ยังไม่ได้ตั้ง';

  @override
  String get deskOwnAccessOn => 'เพิ่มแล้ว';

  @override
  String deskOwnAccessRefused(String time) {
    return 'ถูกปฏิเสธตั้งแต่ $time';
  }

  @override
  String get deskOwnAccessRefusedBadge => 'ถูกปฏิเสธ';

  @override
  String get deskOwnAccessTor => 'ไม่ใช้ขณะเปิด Tor';

  @override
  String get deskOwnAccessNote =>
      'Peer และรายละเอียดการซิงค์มาจาก owner API ของโหนด';

  @override
  String get deskOwnAdd => 'เพิ่ม…';

  @override
  String get deskOwnUpdate => 'อัปเดต…';

  @override
  String get deskOwnRemove => 'ลบ';

  @override
  String get deskOwnAdded => 'เพิ่มสิทธิ์เจ้าของแล้ว';

  @override
  String get deskOwnRemoved => 'ลบสิทธิ์เจ้าของแล้ว';

  @override
  String deskOwnDlgTitle(String host) {
    return 'สิทธิ์เจ้าของของ $host';
  }

  @override
  String get deskOwnDlgWhere =>
      'รหัสลับคือบรรทัดแรกของไฟล์ .api_secret ในโฟลเดอร์ข้อมูลของโหนด (~/.epic/main บนคอมพิวเตอร์ของโหนด)';

  @override
  String get deskOwnDlgPaste => 'วางรหัสลับ';

  @override
  String get deskOwnDlgPick => 'เลือกไฟล์…';

  @override
  String deskOwnDlgFileRead(String file) {
    return 'อ่านจาก $file';
  }

  @override
  String get deskOwnDlgFileEmpty => 'ไฟล์นี้ไม่มีรหัสลับ';

  @override
  String get deskOwnDlgPlainTitle =>
      'รหัสลับจะส่งผ่านเครือข่ายในบ้านโดยไม่เข้ารหัส';

  @override
  String get deskOwnDlgPlainText =>
      'ใช้ได้บนเครือข่ายที่มีแค่คุณใช้ ที่อื่นให้เชื่อมต่อโหนดผ่าน VPN ผ่าน https หรือใช้กระเป๋าบนคอมพิวเตอร์ของโหนด';

  @override
  String get deskOwnDlgPlainAgain => 'ไม่ต้องแสดงอีกสำหรับโหนดนี้';

  @override
  String get deskOwnDlgRefused => 'โหนดปฏิเสธรหัสลับนี้';

  @override
  String get deskOwnDlgNoAnswer => 'โหนดไม่ตอบ จึงเก็บรหัสลับไว้';

  @override
  String get deskOwnDlgAdd => 'เพิ่ม';

  @override
  String get deskOwnDownTitle => 'โหนดของตัวเองไม่ตอบ';

  @override
  String deskOwnDownText(String host) {
    return 'ระหว่างนี้กระเป๋าใช้ $host และจะกลับมาเมื่อโหนดนี้ตอบสองครั้งติดกัน';
  }

  @override
  String deskOwnUsingMeanwhile(String host) {
    return 'ระหว่างนี้ใช้ $host';
  }

  @override
  String deskOwnUsingUntilSynced(String host) {
    return 'ใช้ $host จนกว่าจะซิงค์เสร็จ';
  }

  @override
  String get deskOwnTryNow => 'ลองตอนนี้';

  @override
  String deskOwnUseForGood(String host) {
    return 'ใช้ $host ต่อ';
  }

  @override
  String get deskOwnSyncTitle => 'ใช้โหนดสาธารณะจนกว่าโหนดนี้จะซิงค์เสร็จไหม';

  @override
  String deskOwnSyncText(String host) {
    return '$host ใช้แทนได้จนกว่าโหนดนี้จะซิงก์เสร็จ';
  }

  @override
  String get deskOwnWaitForMine => 'รอโหนดนี้';

  @override
  String deskOwnSyncUsingTitle(String host) {
    return 'ใช้ $host จนกว่าโหนดนี้จะซิงค์เสร็จ';
  }

  @override
  String get deskOwnSyncUsingText => 'กระเป๋าจะกลับมาเมื่อโหนดนี้รับธุรกรรมได้';

  @override
  String get deskOwnMine => 'นี่คือโหนดของฉัน';

  @override
  String deskOwnMineHint(String site) {
    return 'ถามโหนดโดยตรงแทน $site และให้เพิ่มสิทธิ์เจ้าของได้ สำหรับโหนดที่คุณดูแลเอง';
  }

  @override
  String get deskOwnSlotSyncing => 'โหนดของตัวเองกำลังซิงค์';

  @override
  String ownNodeLabel(String where) {
    return 'โหนดของคุณ · $where';
  }

  @override
  String get ownNodeThisPhone => 'โทรศัพท์เครื่องนี้';

  @override
  String get ownNodeHome => 'เครือข่ายในบ้าน';

  @override
  String get ownNodeVpn => 'VPN';

  @override
  String get ownNodeSynced => 'ซิงค์แล้ว';

  @override
  String get ownNodeSyncing => 'กำลังซิงค์';

  @override
  String get ownNodeBehind => 'ตามหลัง';

  @override
  String get ownNodeFactBehind => 'ตามหลัง';

  @override
  String get ownNodeFactLatency => 'เวลาตอบ';

  @override
  String get ownNodeFactAccepts => 'รับธุรกรรม';

  @override
  String get ownNodeFactMempool => 'Mempool';

  @override
  String get ownNodeYes => 'ใช่';

  @override
  String get ownNodeNotYet => 'ยังไม่';

  @override
  String get ownNodeUnknown => 'ไม่ทราบ';

  @override
  String get ownNodePoolEmpty => 'ว่าง';

  @override
  String ownNodePoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รอ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get ownNodeAskedDirectly => 'ถามโดยตรงจากโทรศัพท์เครื่องนี้ทุก 15 วิ';

  @override
  String get deskConExportDo => 'ส่งออก';

  @override
  String get deskSetAboutDownloadPage => 'หน้าดาวน์โหลด';

  @override
  String get deskUpdManual => 'ชุดนี้ติดตั้งอัปเดตเองไม่ได้';

  @override
  String get deskUpdDownloadInstall => 'ดาวน์โหลดและติดตั้ง';

  @override
  String get deskUpdReadyTitle => 'รีสตาร์ทเพื่ออัปเดต';

  @override
  String get deskUpdReadyBody => 'กระเป๋าเงินจะล็อก แล้วแอปจะเปิดใหม่';

  @override
  String get deskUpdRestartNow => 'รีสตาร์ทตอนนี้';

  @override
  String get deskUpdLater => 'ภายหลัง';

  @override
  String get sendTorNotInVersion => 'เวอร์ชันนี้ส่งไปยังที่อยู่ Tor ไม่ได้';

  @override
  String get methodSendDirectLineNoTor => 'กระเป๋าของผู้รับต้องเปิดอยู่';

  @override
  String get sendDirectAddressShapeNoTor =>
      'ที่อยู่ลิงก์ขึ้นต้นด้วย http:// หรือ https://';

  @override
  String get contactsAddressInvalidAnyNoTor =>
      'ที่อยู่ไม่ถูกต้อง ใช้ที่อยู่ Epicbox (es5x…@เซิร์ฟเวอร์) หรือที่อยู่ลิงก์ (https://…)';

  @override
  String get handshakeLink1NoTor =>
      'กระเป๋าของคุณส่งรายการตรงไปยังกระเป๋าของอีกฝ่ายผ่านอินเทอร์เน็ต เหรียญถูกล็อก';

  @override
  String txLinkHttpHintNoTor(String port) {
    return 'ลิงก์ · HTTP จ่ายตรงถึงกระเป๋าเงินที่ที่อยู่เว็บ (http://host:$port) และให้โทรศัพท์เครื่องนี้มีที่อยู่ที่กระเป๋าเงินในเครือข่าย Wi-Fi เดียวกันจ่ายมาได้ ต้องเปิดกระเป๋าเงินทั้งสองฝั่ง ไม่เข้ารหัสระหว่างทาง และเข้าถึงจากอินเทอร์เน็ตหรือผ่านเน็ตมือถือไม่ได้ เพิ่ม ลิงก์ · HTTP ใน ส่ง และ รับ';
  }

  @override
  String get tourPhoneWalletTextNoTor =>
      'ยอดคงเหลือของคุณ และใต้ลงไปคือไอคอนโหนดและ Epicbox สิ่งที่ยังอยู่ระหว่างยืนยันอยู่ในช่องด้านล่าง';

  @override
  String get tourPhonePrivacyTextNoTor =>
      'โหนดและเซิร์ฟเวอร์ Epicbox ที่กระเป๋าเงินใช้ แตะเซิร์ฟเวอร์เพื่อเปลี่ยน';

  @override
  String get tourPhoneAdvancedTextNoTor =>
      'ออฟไลน์ เอาต์พุต และรายละเอียดทางเทคนิคอยู่ที่นี่ เปิดเฉพาะที่ต้องการ';

  @override
  String get deskNoTorSendDirectLine2 =>
      'ที่อยู่ http(s) กระเป๋าเงินของผู้รับต้องเปิดอยู่';

  @override
  String deskNoTorSetTxDirectHint(String port) {
    return 'จ่ายและรับเงินตรงจากกระเป๋าเงินสู่กระเป๋าเงินที่ที่อยู่เว็บ (http://host:$port) โดยไม่มีเซิร์ฟเวอร์คั่นกลาง ใช้ได้เฉพาะตอนที่กระเป๋าเงินเปิดอยู่ทั้งสองฝั่ง เพิ่ม ลิงก์ · HTTP ใน ส่ง และที่อยู่ของมันใน รับ';
  }

  @override
  String get deskNoTorTxDetailsFromBad => 'ใช้ที่อยู่ Epicbox หรือ http(s)';

  @override
  String get deskNoTorTourAdvancedText =>
      'เอาต์พุตและรายละเอียดทางเทคนิคอยู่ที่นี่ เปิดเฉพาะที่ต้องการ';

  @override
  String get errorInputsSpentElsewhere =>
      'โหนดแสดงว่าเหรียญเหล่านี้ถูกใช้ไปแล้ว และกระเป๋าเงินนี้ไม่ได้ใช้ เป็นไปได้มากว่ากระเป๋าเงินอื่นที่ใช้วลีกู้คืนของคุณใช้ไป';

  @override
  String get deskErrInputsSpentElsewhere =>
      'โหนดแสดงว่าเหรียญเหล่านี้ถูกใช้ไปแล้ว และกระเป๋าเงินนี้ไม่ได้ใช้ เป็นไปได้มากว่ากระเป๋าเงินอื่นที่ใช้วลีกู้คืนของคุณใช้ไป';

  @override
  String get slAddedByYou => 'คุณเพิ่มเอง';

  @override
  String slCount(int n, int limit) {
    return '$n จาก $limit';
  }

  @override
  String slLimit(int limit) {
    return 'เลือกครบ $limit จาก $limit แล้ว ยกเลิกหนึ่งรายการเพื่อเลือกรายการอื่น';
  }

  @override
  String get slKeepOne => 'ต้องเลือกอย่างน้อยหนึ่งรายการ';

  @override
  String get slChosenUntick => 'เลือกอยู่ ต้องยกเลิกก่อน';

  @override
  String get slResetDefaults => 'คืนค่าเริ่มต้น';

  @override
  String get slReset => 'คืนค่าเริ่มต้นแล้ว';

  @override
  String slChosen(String host) {
    return 'เลือก $host แล้ว';
  }

  @override
  String slChosenNonDefault(String host) {
    return 'เลือกแล้ว กระเป๋าเงินที่ใช้ $host ด้วยจะพบคุณที่นั่น';
  }

  @override
  String slUnchosen(String host) {
    return 'ยกเลิกการเลือก $host แล้ว';
  }

  @override
  String slAddedNonDefault(String host) {
    return 'เพิ่ม $host แล้ว กระเป๋าเงินที่ใช้เซิร์ฟเวอร์นี้ด้วยจะพบคุณที่นั่น';
  }

  @override
  String slAddedUntick(String host) {
    return 'เพิ่ม $host แล้ว ยกเลิกรายการอื่นเพื่อเลือกรายการนี้';
  }

  @override
  String get connServers => 'เซิร์ฟเวอร์เชื่อมต่อ';

  @override
  String get connServersHint =>
      'ที่ที่กระเป๋าเงินสองใบพบกันเมื่อเชื่อมต่อ กระเป๋าเงินอีกใบต้องใช้อย่างน้อยหนึ่งเซิร์ฟเวอร์เหล่านี้ด้วย';

  @override
  String get connServersNote => 'เลือกได้สูงสุด 3';

  @override
  String connServersDefaults(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n เซิร์ฟเวอร์ · ค่าเริ่มต้น',
    );
    return '$_temp0';
  }

  @override
  String connServersChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n เซิร์ฟเวอร์ · เปลี่ยนแล้ว',
    );
    return '$_temp0';
  }

  @override
  String connServersDown(int down, int n) {
    return '$down จาก $n ไม่ตอบสนอง การเชื่อมต่อยังใช้งานได้ผ่านเซิร์ฟเวอร์ที่เหลือ';
  }

  @override
  String get connServersAllDown =>
      'ไม่มีเซิร์ฟเวอร์เชื่อมต่อใดตอบสนอง ใช้ “เชิญทางข้อความ” หรือ “แบบพบตัว”';

  @override
  String get connServersEpicboxOff =>
      'หยุดชั่วคราวขณะ Epicbox ปิดอยู่ “เชิญทางข้อความ” และ “แบบพบตัว” ยังใช้ได้';

  @override
  String get connServersOffline => 'หยุดชั่วคราวขณะที่ออฟไลน์เปิดอยู่';

  @override
  String connServersNonDefault(String host) {
    return '$host ไม่ใช่ค่าเริ่มต้น กระเป๋าเงินที่ใช้เซิร์ฟเวอร์นี้ด้วยจะพบคุณที่นั่น';
  }

  @override
  String get connServersInfo1 =>
      'เมื่อกระเป๋าเงินสองใบเชื่อมต่อกันครั้งแรก แต่ละใบจะมองหาอีกใบบนเซิร์ฟเวอร์ที่เลือกไว้ที่นี่ ทั้งสองต้องมีอย่างน้อยหนึ่งเซิร์ฟเวอร์ร่วมกัน ไม่เช่นนั้นจะไม่มีวันพบกัน';

  @override
  String get connServersInfo2 =>
      'ค่าเริ่มต้นคือเซิร์ฟเวอร์ที่กระเป๋าเงิน Epic Cash ทุกใบรู้จัก ควรใช้ต่อไป เว้นแต่มีตัวใดถูกบล็อกในเครือข่ายนี้';

  @override
  String get connServersInfo3 =>
      '“เชิญทางข้อความ” และ “แบบพบตัว” ไม่ต้องใช้ และสิ่งที่เกิดหลังการเชื่อมต่อก็ไม่ต้องใช้เช่นกัน: ทั้งหมดนั้นใช้เซิร์ฟเวอร์ Epicbox ของกระเป๋าเงินนี้เอง';

  @override
  String get connServersInfo4 =>
      'แต่ละเซิร์ฟเวอร์ที่เลือกเห็นว่ามีการเริ่มเชื่อมต่อ แต่ไม่เห็นว่ากับใคร';

  @override
  String get connServersInfoTor => 'เมื่อเปิด Tor จะเข้าถึงเซิร์ฟเวอร์ผ่าน Tor';

  @override
  String get txSentFromOtherWallet => 'ส่งจากกระเป๋าเงินอื่น';

  @override
  String txSpokenSentFromOtherWallet(String amount) {
    return 'ส่งจากกระเป๋าเงินอื่น $amount';
  }

  @override
  String get txDetailsOtherWallet =>
      'โหนดแสดงว่าเหรียญเหล่านี้ถูกใช้ไปแล้ว และกระเป๋าเงินนี้ไม่ได้ใช้ เป็นไปได้มากว่ากระเป๋าเงินอื่นที่ใช้วลีกู้คืนของคุณใช้ไป กระเป๋าเงินนี้แสดงจำนวนที่ออกไป ไม่แสดงผู้รับและค่าธรรมเนียม';

  @override
  String get txSentFromOtherWalletUnverified =>
      'ส่งจากกระเป๋าเงินอื่น · ยังไม่ได้ตรวจสอบ';

  @override
  String get txDetailsUnverified =>
      'ยังไม่ได้ตรวจสอบ: ตอนนี้มีเพียงโหนดที่รายงานรายการนี้ ใช้ \"ตรวจยอดใหม่\" เพื่อยืนยัน';

  @override
  String get txDetailsNotKnown => 'ไม่ทราบ';

  @override
  String get txReceivedByOtherWallet => 'รับโดยกระเป๋าเงินอื่น';

  @override
  String txSpokenReceivedByOtherWallet(String amount) {
    return 'รับโดยกระเป๋าเงินอื่น $amount';
  }

  @override
  String get txDetailsOtherWalletIn =>
      'กระเป๋าเงินอื่นที่ใช้วลีกู้คืนของคุณได้รับเหรียญเหล่านี้ กระเป๋าเงินนี้แสดงจำนวน ไม่แสดงผู้ส่ง';

  @override
  String get expLinkedDevices => 'อุปกรณ์ที่เชื่อมโยง';

  @override
  String get expLinkedDevicesHint =>
      'ใช้กระเป๋าเงินนี้บนอุปกรณ์สองเครื่อง: เครื่องนี้และอุปกรณ์ที่เชื่อมโยงหนึ่งเครื่อง แต่ละเครื่องแจ้งรายการของตนให้อีกเครื่องทราบ เหรียญที่เครื่องหนึ่งกำลังใช้จึงถูกพักไว้บนอีกเครื่อง และรายการของมันจะแสดงในประวัติของอีกเครื่อง การเชื่อมโยงปกป้องสิ่งที่แชร์ ไม่ใช่เงิน อุปกรณ์ใดที่มีวลีกู้คืนก็ใช้จ่ายได้ เป็นฟีเจอร์ทดลอง: อาจยังเปลี่ยนแปลงได้';

  @override
  String get devicesThisPhone => 'โทรศัพท์';

  @override
  String get devicesThisComputer => 'คอมพิวเตอร์';

  @override
  String get devicesNone => 'ไม่มี';

  @override
  String get devicesSeenNow => 'เห็นเมื่อสักครู่';

  @override
  String devicesSeenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เห็นเมื่อ $count นาทีที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เห็นเมื่อ $count ชั่วโมงที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เห็นเมื่อ $count วันที่แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get devicesNotSeen => 'ยังไม่เห็น';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count อุปกรณ์',
    );
    return '$_temp0';
  }

  @override
  String devicesServerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เซิร์ฟเวอร์ $count เครื่อง',
    );
    return '$_temp0';
  }

  @override
  String get devicesThisDevice => 'อุปกรณ์นี้';

  @override
  String get devicesOthers => 'อุปกรณ์ที่เชื่อมโยง';

  @override
  String get devicesEmpty => 'ยังไม่ได้เชื่อมโยงอุปกรณ์';

  @override
  String get devicesLink => 'เชื่อมโยงอุปกรณ์';

  @override
  String get devicesServers => 'เซิร์ฟเวอร์';

  @override
  String get devicesServersNote =>
      'ข้อความระหว่างอุปกรณ์ทั้งสองเครื่องจะส่งผ่านทุกเซิร์ฟเวอร์ที่เลือก';

  @override
  String devicesServersWaiting(String name) {
    return 'กำลังรอ $name ยอมรับเซิร์ฟเวอร์ใหม่';
  }

  @override
  String devicesProposal(String name, String servers) {
    return '$name เสนอเซิร์ฟเวอร์เหล่านี้: $servers';
  }

  @override
  String get devicesAccept => 'ยอมรับ';

  @override
  String get devicesNotNow => 'ไม่ใช่ตอนนี้';

  @override
  String get devicesPause => 'หยุดซิงค์ชั่วคราว';

  @override
  String get devicesPauseHint =>
      'ระหว่างหยุดชั่วคราว อุปกรณ์นี้จะไม่อ่านและไม่ส่งข้อความ ข้อความจะรอบนเซิร์ฟเวอร์ได้นานถึง 7 วัน ออฟไลน์ก็หยุดเช่นกัน';

  @override
  String get devicesHeld => 'เหรียญที่ถูกพักไว้';

  @override
  String devicesHeldBy(String name) {
    return 'ถูกพักไว้โดยรายการของ $name';
  }

  @override
  String get devicesRelease => 'ปล่อย';

  @override
  String get devicesReleaseTitle => 'ปล่อยเหรียญเหล่านี้หรือไม่';

  @override
  String devicesReleaseBody(String name) {
    return '$name อาจยังทำรายการนี้ไม่เสร็จ ถ้าเป็นเช่นนั้น รายการที่คุณใช้เหรียญเหล่านี้จะล้มเหลว มีผลกับอุปกรณ์นี้เท่านั้น';
  }

  @override
  String get devicesReleased => 'ปล่อยบนอุปกรณ์นี้แล้ว';

  @override
  String get devicesRename => 'เปลี่ยนชื่อ';

  @override
  String get devicesNameLabel => 'ชื่อ';

  @override
  String get devicesRemove => 'นำออก';

  @override
  String devicesRemoveTitle(String name) {
    return 'นำ $name ออกหรือไม่';
  }

  @override
  String devicesRemoveBody(String name) {
    return '$name จะไม่รับและไม่ส่งข้อความอีก และเหรียญที่มันพักไว้ที่นี่จะถูกปล่อย การนำออกไม่ได้ปกป้องเงิน อุปกรณ์ที่มีวลีกู้คืนใช้จ่ายได้เสมอ ถ้า $name อาจอยู่ในมือคนอื่น ให้ย้ายเงินไปยังกระเป๋าเงินที่มีวลีกู้คืนใหม่';
  }

  @override
  String devicesRemoved(String name) {
    return 'นำ $name ออกแล้ว';
  }

  @override
  String devicesRemovedBy(String name) {
    return '$name นำอุปกรณ์นี้ออกจากการเชื่อมโยงแล้ว';
  }

  @override
  String get devicesRemoving =>
      'กำลังนำออก… อุปกรณ์อีกเครื่องจะได้รับแจ้งเมื่ออุปกรณ์นี้เชื่อมต่อเครือข่าย';

  @override
  String get devicesMoneyNote =>
      'การเชื่อมโยงแชร์รายการระหว่างอุปกรณ์ทั้งสองเครื่อง แต่ไม่ได้ปกป้องเงิน อุปกรณ์ใดที่มีวลีกู้คืนก็ใช้จ่ายได้';

  @override
  String get devicesUnsupported => 'เวอร์ชันนี้ยังเชื่อมโยงอุปกรณ์ไม่ได้';

  @override
  String get linkLead =>
      'อุปกรณ์ทั้งสองต้องมีกระเป๋าเงินนี้ เครื่องหนึ่งแสดงรหัส อีกเครื่องสแกนหรือวาง';

  @override
  String get linkShow => 'แสดงรหัส';

  @override
  String get linkScan => 'สแกนรหัส';

  @override
  String get linkPaste => 'วางรหัส';

  @override
  String get linkShowLead =>
      'บนอุปกรณ์อีกเครื่อง เปิด เชื่อมโยงอุปกรณ์ แล้วสแกนรหัสนี้ หรือคัดลอกไปวางที่นั่น';

  @override
  String get linkCopy => 'คัดลอกรหัส';

  @override
  String get linkCopied => 'คัดลอกรหัสแล้ว';

  @override
  String linkExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รหัสใช้ได้ $count นาที',
    );
    return '$_temp0';
  }

  @override
  String get linkWaiting => 'กำลังรออุปกรณ์อีกเครื่อง…';

  @override
  String linkWaitingFor(String name) {
    return 'กำลังรอ $name…';
  }

  @override
  String get linkPasteLabel => 'รหัสเชื่อมโยง';

  @override
  String get linkGo => 'เชื่อมโยง';

  @override
  String get linkCheckTitle => 'ตรวจภาพ';

  @override
  String linkCheckLead(String name) {
    return '$name ก็แสดงภาพสี่ภาพเช่นกัน เชื่อมโยงเฉพาะเมื่อภาพเหมือนกันและเรียงลำดับเดียวกัน';
  }

  @override
  String get linkPicturesLabel => 'ภาพสี่ภาพ';

  @override
  String linkWaitingCheck(String name) {
    return 'กำลังรอ $name ตรวจภาพ';
  }

  @override
  String get linkDoneTitle => 'เชื่อมโยงแล้ว';

  @override
  String linkDone(String name) {
    return 'เชื่อมโยง $name แล้ว รายการที่อุปกรณ์เครื่องใดทำจะแสดงบนทั้งสองเครื่อง และเหรียญของรายการจะถูกพักไว้บนอีกเครื่อง';
  }

  @override
  String get linkFailedTitle => 'ไม่ได้เชื่อมโยง';

  @override
  String get linkFailInvalid => 'นี่ไม่ใช่รหัสเชื่อมโยงอุปกรณ์ หรือรหัสเสียหาย';

  @override
  String get linkFailExpired => 'รหัสหมดเวลาแล้ว สร้างรหัสใหม่';

  @override
  String get linkFailNotFound => 'รหัสนี้ถูกใช้แล้วหรือถูกยกเลิก';

  @override
  String get linkFailOwn => 'รหัสนี้มาจากอุปกรณ์นี้ ให้สแกนบนอีกเครื่อง';

  @override
  String get linkFailOtherWallet => 'อุปกรณ์นี้มีกระเป๋าเงินอื่น';

  @override
  String get linkFailOtherWalletCode => 'รหัสนี้มาจากกระเป๋าเงินอื่น';

  @override
  String get linkFailMismatch => 'ภาพไม่ตรงกัน จึงไม่ได้เชื่อมโยงอุปกรณ์';

  @override
  String get linkFailCancelled =>
      'อุปกรณ์อีกเครื่องหยุด หรือไม่ได้ตรวจภาพทันเวลา';

  @override
  String get linkFailTooMany =>
      'เชื่อมโยงอุปกรณ์ไว้แล้วหนึ่งเครื่อง นำออกก่อนจึงจะเชื่อมโยงเครื่องอื่นได้';

  @override
  String get linkFailUnreachable => 'ไม่มีเซิร์ฟเวอร์ตอบ ลองใหม่ภายหลัง';

  @override
  String get linkTryAgain => 'ลองอีกครั้ง';

  @override
  String get linkOffTitle => 'อุปกรณ์ที่เชื่อมโยงเป็นฟีเจอร์ทดลอง';

  @override
  String txSentFromDevice(String device) {
    return 'ส่งจาก $device';
  }

  @override
  String txDeviceMadeOn(String device) {
    return 'ทำบน $device รายละเอียดมาจากอุปกรณ์นั้น ส่วนจำนวนเงินและการยืนยันมาจากเชน';
  }

  @override
  String get txDeviceHeld =>
      'เหรียญของรายการถูกพักไว้บนอุปกรณ์นี้จนกว่าเชนจะแสดงรายการ หรืออุปกรณ์อีกเครื่องจะจบรายการ';

  @override
  String sendHeldByDevice(String amount, String name) {
    return '$amount EPIC ถูกพักไว้โดยรายการที่ $name กำลังทำ';
  }

  @override
  String get offerLinkRestore =>
      'ใช้กระเป๋าเงินนี้บนอุปกรณ์อื่นด้วยหรือไม่ เชื่อมโยงเพื่อแชร์ประวัติและเห็นรายการของกันและกัน';

  @override
  String get offerLinkOtherWallet =>
      'นี่คืออุปกรณ์อีกเครื่องของคุณหรือไม่ เชื่อมโยงเพื่อดูว่าจ่ายให้ใคร และให้ทั้งสองเครื่องตรงกัน';

  @override
  String devicesReleasedRow(String name) {
    return 'ปล่อยที่นี่แล้ว · $name อาจยังส่งรายการนี้';
  }

  @override
  String get deskDevServersNote => 'เลือกได้สูงสุด 2';

  @override
  String get deskDevServersCancel => 'ยกเลิกการเปลี่ยน';

  @override
  String deskDevServersDown(int down, int n) {
    return '$down จาก $n ไม่ตอบสนอง ข้อความจะส่งผ่านเซิร์ฟเวอร์อีกตัว';
  }

  @override
  String get deskDevServersAllDown =>
      'ไม่มีเซิร์ฟเวอร์ตอบสนอง ข้อความจะรอและส่งเมื่อมีเซิร์ฟเวอร์กลับมา';

  @override
  String get deskDevServersInfo1 =>
      'อุปกรณ์ที่เชื่อมโยงทั้งสองเครื่องส่งข้อความถึงกันผ่านเซิร์ฟเวอร์เหล่านี้ ทุกข้อความส่งไปยังเซิร์ฟเวอร์ที่เลือกทั้งหมด เซิร์ฟเวอร์ตัวหนึ่งล่มจึงไม่มีผล';

  @override
  String get deskDevServersInfo2 =>
      'การเปลี่ยนจะส่งไปยังอุปกรณ์อีกเครื่องก่อน และมีผลเมื่อเครื่องนั้นยอมรับ ก่อนหน้านั้นยังใช้เซิร์ฟเวอร์เดิม และหลังจากนั้นยังอ่านจากเซิร์ฟเวอร์เดิมอีก 7 วัน';

  @override
  String get deskDevServersInfo3 =>
      'เซิร์ฟเวอร์เห็นว่าอุปกรณ์สองเครื่องแลกเปลี่ยนข้อความและเมื่อใด และหากไม่ใช้ Tor ก็เห็นว่ามาจากที่อยู่ใด แต่ไม่เห็นเนื้อหา เซิร์ฟเวอร์สองตัวหมายความว่าผู้ให้บริการสองรายเห็นสิ่งนี้';

  @override
  String get deskDevPausedOffline => 'หยุดชั่วคราวขณะที่ออฟไลน์เปิดอยู่';

  @override
  String get deskDevPausedEpicboxOff => 'หยุดชั่วคราวขณะ Epicbox ปิดอยู่';

  @override
  String deskDevHeldAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskDevHeldNone => 'ไม่มีเหรียญที่ถูกพักไว้';

  @override
  String get deskDevRenameThis => 'เปลี่ยนชื่อคอมพิวเตอร์เครื่องนี้';

  @override
  String deskDevRenameDevice(String name) {
    return 'เปลี่ยนชื่อ $name';
  }

  @override
  String get deskDevPasteLead => 'วางรหัสที่อุปกรณ์อีกเครื่องแสดง';

  @override
  String get deskDevMakingCode => 'กำลังสร้างรหัส…';

  @override
  String get deskDevConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get deskDevTheOther => 'อุปกรณ์อีกเครื่อง';

  @override
  String deskDevServersLine(String servers) {
    return 'เซิร์ฟเวอร์: $servers';
  }

  @override
  String get deskDevOfferReceived =>
      'นี่คืออุปกรณ์อีกเครื่องของคุณหรือไม่ เชื่อมโยงเพื่อดูว่าใครส่งมา และให้ทั้งสองเครื่องตรงกัน';

  @override
  String devicesEndCancelled(String name) {
    return 'ยกเลิกบน $name';
  }

  @override
  String devicesEndFailed(String name) {
    return 'ล้มเหลวบน $name';
  }

  @override
  String devicesEndExpired(String name) {
    return 'หมดอายุบน $name';
  }

  @override
  String devicesEndLineCancelled(String name) {
    return '$name ยกเลิกรายการนี้ เหรียญของรายการกลับมาใช้ได้อีกครั้ง';
  }

  @override
  String devicesEndLineExpired(String name) {
    return '$name ทำรายการนี้ไม่เสร็จทันเวลา เหรียญของรายการกลับมาใช้ได้อีกครั้ง';
  }

  @override
  String devicesWhyNotDelivered(String name) {
    return '$name ส่งรายการนี้ถึงผู้รับไม่ได้ เหรียญของรายการกลับมาใช้ได้อีกครั้ง';
  }

  @override
  String get devicesWhyRefused =>
      'เซิร์ฟเวอร์ของผู้รับปฏิเสธรายการนี้ เหรียญของรายการกลับมาใช้ได้อีกครั้ง';

  @override
  String get devicesWhyInputsSpent => 'เหรียญของรายการนี้ถูกใช้ไปแล้ว';

  @override
  String devicesWhyOther(String name) {
    return '$name ทำรายการนี้ไม่สำเร็จ เหรียญของรายการกลับมาใช้ได้อีกครั้ง';
  }

  @override
  String devicesStatusInfo(String name) {
    return 'สถานะนี้มาจาก $name สถานะสุดท้ายขึ้นอยู่กับบล็อกเชน';
  }

  @override
  String get syncHelpOtherDevice => 'อุปกรณ์อีกเครื่อง';

  @override
  String get syncHelpServer => 'เซิร์ฟเวอร์';

  @override
  String get syncHelpChain => 'บล็อกเชน';

  @override
  String get syncHelpStep1 => 'อุปกรณ์นี้เริ่มรายการ';

  @override
  String syncHelpStep2(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้อความที่เข้ารหัสส่งไปยังเซิร์ฟเวอร์ทั้งสอง มีเพียงอุปกรณ์เท่านั้นที่อ่านได้',
      one: 'ข้อความที่เข้ารหัสส่งผ่านเซิร์ฟเวอร์ มีเพียงอุปกรณ์เท่านั้นที่อ่านได้',
    );
    return '$_temp0';
  }

  @override
  String get syncHelpStep3 =>
      'อุปกรณ์อีกเครื่องพักเหรียญเหล่านั้นไว้และแสดงรายการ';

  @override
  String get syncHelpStep4 => 'บล็อกเชนยืนยัน เชนเป็นผู้ตัดสินสถานะสุดท้าย';

  @override
  String get syncHelpDiagram =>
      'การซิงค์ทำงานอย่างไร: อุปกรณ์นี้เริ่มรายการ ข้อความที่เข้ารหัสส่งผ่านเซิร์ฟเวอร์ไปยังอุปกรณ์อีกเครื่องซึ่งพักเหรียญเหล่านั้นไว้ แล้วบล็อกเชนยืนยัน';

  @override
  String get syncHelpStatus => 'สถานะปัจจุบัน';

  @override
  String get syncHelpPaused => 'ซิงค์หยุดชั่วคราว';

  @override
  String get syncHelpAnswering => 'ตอบสนอง';

  @override
  String get syncHelpNotAnswering => 'ไม่ตอบสนอง';

  @override
  String get syncHelpNotChecked => 'ยังไม่ได้ตรวจ';

  @override
  String get deskSetAdvBalance => 'ยอดเงิน';

  @override
  String get deskSetAdvConfirmations => 'การยืนยัน';

  @override
  String deskSetAdvConfirmationsHint(int byDefault, int min, int max) {
    return 'จำนวนบล็อกที่การชำระเงินที่ได้รับต้องรอก่อนที่เอาต์พุตจะใช้ได้ ค่าเริ่มต้นคือ $byDefault ตั้งได้ตั้งแต่ $min ถึง $max';
  }

  @override
  String get deskSetAdvConfirmationsDefault => 'ค่าเริ่มต้น';

  @override
  String deskSetAdvConfirmationsReset(int count) {
    return 'รีเซ็ตเป็น $count';
  }

  @override
  String get deskSetAdvConfirmationsFewer => 'ลดการยืนยัน';

  @override
  String get deskSetAdvConfirmationsMore => 'เพิ่มการยืนยัน';

  @override
  String deskSetAdvConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ยืนยัน $count ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAdvConfirmationsLowNote =>
      'ยิ่งยืนยันน้อยยิ่งเร็ว แต่ป้องกันการจัดเรียงบล็อกเชนใหม่ได้น้อยลง';

  @override
  String get deskSetAdvConfirmationsNotSaved => 'ไม่ได้เปลี่ยนการยืนยัน';

  @override
  String get deskSetPeersFirstSeenHint =>
      'เวลาที่แอปนี้เห็น peer เชื่อมต่อครั้งแรกในรอบนี้';

  @override
  String deskAppFirstScanProgress(int percent) {
    return 'กำลังสแกนบล็อกเชน · $percent%';
  }

  @override
  String deskAppFirstScanFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'พบ $countString เอาต์พุต',
    );
    return '$_temp0';
  }

  @override
  String get deskAppFirstScanShowLog => 'แสดงบันทึก';

  @override
  String get deskAppFirstScanHideLog => 'ซ่อนบันทึก';

  @override
  String deskNodeDurationDh(int days, int hours) {
    return '$days วัน $hours ชั่วโมง';
  }

  @override
  String deskNodeDurationH(int hours) {
    return '$hours ชั่วโมง';
  }

  @override
  String deskInvPayerAgoHoursOnly(int hours) {
    return '$hours ชั่วโมง';
  }

  @override
  String get slPlainHttpTitle => 'ใช้โหนดนี้โดยไม่เข้ารหัสหรือไม่';

  @override
  String slPlainHttpBody(String host) {
    return '$host อยู่ในช่วงที่อยู่ที่ใช้ร่วมกัน: อาจเป็น tailnet ของคุณเอง (Tailscale) หรือเครือข่ายของผู้ให้บริการอินเทอร์เน็ตของคุณ วอลเล็ตคุยกับโหนดนี้ผ่าน http ที่ไม่เข้ารหัส ทุกคนในเครือข่ายนั้นจึงอ่านได้ว่าวอลเล็ตถามอะไรจากโหนด เพิ่มโหนดนี้เฉพาะเมื่อที่อยู่นี้เป็น tailnet ของคุณ';
  }

  @override
  String get slPlainHttpUse => 'ใช้โหนดนี้';

  @override
  String get slRefusedLocal =>
      'ไม่ได้เลือก: วอลเล็ตอื่นเข้าถึงเซิร์ฟเวอร์ที่อยู่ในเครือข่ายภายในหรือที่อยู่ส่วนตัวไม่ได้';

  @override
  String get slRefusedOnion =>
      'ไม่ได้เลือก: เซิร์ฟเวอร์ onion ใช้ได้เฉพาะเมื่อเปิด Tor';

  @override
  String get deskOwnAccessOnPlain =>
      'เพิ่มแล้ว · ส่งไปยังโหนดโดยไม่เข้ารหัส (http) อ่านได้ในเครือข่ายนั้น';

  @override
  String get sasNotFromCamera =>
      'รหัสของอีกฝ่ายมาทางข้อความ ไม่ได้มาจากกล้องของคุณ หากวอลเล็ตของอีกฝ่ายไม่ได้สแกนรหัสของคุณจากหน้าจอนี้ คำเหล่านี้พิสูจน์ไม่ได้ว่าใครส่งมา จึงไม่มีการยืนยันที่นี่ เก็บการจับคู่ไว้โดยไม่ตรวจ หรือจับคู่ด้วยคำเชิญ';

  @override
  String get slSwitchFirst => 'สลับก่อน';

  @override
  String get contactPaymentsNone => 'ยังไม่มีรายการกับผู้ติดต่อนี้';

  @override
  String contactPaymentsWith(String name) {
    return 'รายการกับ $name';
  }

  @override
  String get contactPaymentsAll => 'รายการทั้งหมด';

  @override
  String receiveEpicboxNotConnected(String server) {
    return 'ไม่ได้เชื่อมต่อ · $server';
  }

  @override
  String restoreWordsAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทั้ง $count คำถูกต้อง',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คำ',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คำไม่อยู่ในรายการ',
    );
    return '$_temp0';
  }

  @override
  String pairInvitedAt(String clock) {
    return 'เชิญเมื่อ $clock';
  }

  @override
  String get pairInvitedYesterday => 'เชิญเมื่อวานนี้';

  @override
  String pairInvitedOn(String day) {
    return 'เชิญเมื่อ $day';
  }

  @override
  String get deskActNoneUnderFilter => 'ไม่มีรายการในตัวกรองนี้';

  @override
  String get deskRecvHttpIntroInternet =>
      'สำหรับกระเป๋าเงินบนอินเทอร์เน็ต ขณะที่กระเป๋าเงินนี้เปิดอยู่';

  @override
  String get deskKitMethodConnected => 'เชื่อมต่อแล้ว';

  @override
  String get deskOvSendWaitsNode => 'การส่งจะกลับมาเมื่อโหนดตอบสนอง';

  @override
  String get deskSetRescanRecheck => 'ตรวจใหม่';

  @override
  String get deskSetRescanRecheckAgain => 'ตรวจอีกครั้ง';

  @override
  String get deskSetRescanFromDate => 'ตั้งแต่วันที่';

  @override
  String get deskSetRescanPickDate => 'เลือกวันที่';

  @override
  String get deskSetRescanPickDateFirst => 'เลือกวันที่ก่อน';

  @override
  String contactsImportAddsAddress(String name, String method, String address) {
    return '$name ได้ที่อยู่ $method: $address';
  }

  @override
  String get netStatusTurnOnHint => 'ปิดอยู่ เปิดได้ใน ตั้งค่า › ธุรกรรม';

  @override
  String get netStatusTurnOnHintPrivacy =>
      'ปิดอยู่ เปิดได้ใน ตั้งค่า › ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get deskBarTurnOnHint => 'ปิดอยู่ เปิดได้ใน ตั้งค่า › ธุรกรรม';

  @override
  String get deskErrMacKeychain =>
      'macOS ไม่อนุญาตให้แอปอ่านข้อมูลที่บันทึกไว้ในพวงกุญแจ ปิด Epic Cash Desktop แล้วเปิดใหม่ เมื่อ macOS ถาม ให้ป้อนรหัสผ่านเข้าสู่ระบบ Mac แล้วเลือก \"อนุญาตเสมอ\"';

  @override
  String get deskUpdOpenDmg => 'เปิดดิสก์อิมเมจ';

  @override
  String get deskUpdDmgHint =>
      'แอปจะปิดและดิสก์อิมเมจจะเปิดขึ้น: ลาก Epic Cash Desktop ไปไว้ในโฟลเดอร์แอปพลิเคชัน แทนที่เวอร์ชันเก่า แล้วเปิดแอป';

  @override
  String get balanceSheetTitle => 'ยอดคงเหลือ';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รอดำเนินการ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get connectionsSheetTitle => 'การเชื่อมต่อ';

  @override
  String settingsFileSyntaxError(String file, int line) {
    return '$file บรรทัด $line: อ่านบรรทัดนี้ไม่ได้ ยังใช้การตั้งค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotText(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ข้อความในเครื่องหมายคำพูด ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotNumber(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่จำนวนเต็ม ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotSwitch(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ true หรือ false ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotList(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่รายการ ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotNodeAddress(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ที่อยู่โหนด ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotEpicboxServer(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่เซิร์ฟเวอร์ Epicbox ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotHostName(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ชื่อโฮสต์ ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotWebAddress(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ที่อยู่เว็บ ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotOnion(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ที่อยู่ onion ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotPort(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่หมายเลขพอร์ต ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotEmail(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ที่อยู่อีเมล ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileNotEpicboxAddress(String file, int line) {
    return '$file บรรทัด $line: ไม่ใช่ที่อยู่ Epicbox ยังใช้ค่าล่าสุดที่ถูกต้องอยู่';
  }

  @override
  String settingsFileUnknownKey(String file, int line, String key) {
    return '$file บรรทัด $line: ไม่รู้จักคีย์ $key จึงข้ามไป';
  }

  @override
  String settingsFileConflict(String file, String key) {
    return 'มีการแก้ไข $file ในเวลาเดียวกัน จึงคงค่า $key ในไฟล์ไว้';
  }

  @override
  String settingsFileBrokenSaved(String file, String backup) {
    return '$file มีข้อผิดพลาด บันทึกไว้เป็น $backup แล้วเขียนไฟล์ใหม่';
  }

  @override
  String settingsFileRecreated(String file) {
    return 'ไม่พบ $file จึงเขียนไฟล์ใหม่แล้ว';
  }

  @override
  String settingsFileWriteFailed(String file) {
    return 'เขียน $file ไม่ได้ การเปลี่ยนแปลงนี้ใช้ได้จนกว่าจะปิดแอป';
  }

  @override
  String settingsFileReadFailed(String file) {
    return 'อ่าน $file ไม่ได้ จึงใช้การตั้งค่าในตัวแอป';
  }

  @override
  String get deskKitReachTorOff => 'การตรวจนี้ต้องปิด Tor';

  @override
  String get deskSetBackupServersTitle => 'ใช้เซิร์ฟเวอร์จากไฟล์นี้?';

  @override
  String get deskSetBackupServersBody =>
      'รายการโหนดและเซิร์ฟเวอร์ Epicbox ในไฟล์ต่างจากของคอมพิวเตอร์เครื่องนี้ กระเป๋าเงินทุกใบในเครื่องนี้ใช้รายการเดียวกัน';

  @override
  String get deskSetBackupServersKeep => 'ใช้ของเครื่องนี้';

  @override
  String get deskSetBackupServersUse => 'ใช้ของไฟล์';

  @override
  String get deskSlNoNodeTitle => 'ยังไม่ได้ตั้งโหนด';

  @override
  String get deskSlNoNodeText =>
      'รายการโหนดว่างอยู่ เพิ่มโหนดเพื่อตรวจยอดเงินและส่ง';

  @override
  String get deskSlNoEpicboxTitle => 'ยังไม่ได้ตั้งเซิร์ฟเวอร์ Epicbox';

  @override
  String get deskSlNoEpicboxText =>
      'รายการเซิร์ฟเวอร์ Epicbox ว่างอยู่ เพิ่มเซิร์ฟเวอร์เพื่อให้มีที่อยู่ Epicbox';

  @override
  String get devicesOneOnly =>
      'เชื่อมโยงได้หนึ่งเครื่อง นำออกก่อนจึงจะเชื่อมโยงเครื่องอื่นได้';

  @override
  String devicesRelayAsk(String relay, String next) {
    return 'อุปกรณ์ทั้งสองใช้ $relay ใช้ $next บนเครื่องนี้หรือไม่';
  }

  @override
  String get devicesRelayUse => 'ใช้';

  @override
  String get devicesRelayKeep => 'คงไว้';

  @override
  String get devicesRelayWhy =>
      'บนเซิร์ฟเวอร์ Epicbox เดียวกัน อุปกรณ์ทั้งสองจะตอบรายการเดียวกัน บนเซิร์ฟเวอร์ต่างกัน แต่ละเครื่องจะตอบรายการที่ส่งมายังที่อยู่ของตนเอง';

  @override
  String txReceivedOnDevice(String device) {
    return 'รับบน $device';
  }

  @override
  String txSpokenReceivedOnDevice(String device, String amount) {
    return 'รับบน $device $amount';
  }

  @override
  String txDetailsDeviceIn(String device) {
    return '$device ซึ่งเชื่อมโยงกับกระเป๋าเงินนี้ ได้รับเหรียญเหล่านี้';
  }

  @override
  String get deskOnbNodeAdvanced => 'ขั้นสูง';

  @override
  String deskOnbNodePortsSub(String api, String p2p) {
    return 'API $api · P2P $p2p';
  }

  @override
  String get deskOnbNodeApiPort => 'พอร์ต API';

  @override
  String get deskOnbNodeP2pPort => 'พอร์ต P2P';

  @override
  String get deskOnbNodePortsWhy =>
      'จำเป็นเฉพาะเมื่อโหนดอื่นในคอมพิวเตอร์เครื่องนี้หรือในเครือข่ายใช้พอร์ตเหล่านี้';

  @override
  String deskOnbNodePortRange(String min, String max) {
    return 'ตัวเลขตั้งแต่ $min ถึง $max';
  }

  @override
  String get deskOnbNodePortsSame => 'พอร์ตทั้งสองต้องต่างกัน';

  @override
  String deskOnbNodePortTaken(String port, String next) {
    return 'พอร์ต $port ถูกโปรแกรมอื่นใช้อยู่ $next ว่าง';
  }

  @override
  String deskOnbNodePortUse(String port) {
    return 'ใช้ $port';
  }

  @override
  String get deskSetLnodePorts => 'พอร์ต';

  @override
  String get deskSetLnodePortsTitle => 'พอร์ตของโหนด';

  @override
  String get deskSetLnodePortsDesc => 'พอร์ตที่โหนดในตัวรับการเชื่อมต่อ';

  @override
  String get deskSetLnodePortsRestart => 'โหนดจะเริ่มใหม่ด้วยพอร์ตใหม่';

  @override
  String get deskSetLnodePortsSaved => 'บันทึกพอร์ตแล้ว';

  @override
  String get deskSetLnodePortsRestarting => 'โหนดกำลังเริ่มใหม่';

  @override
  String get deskSetLnodePortsNotSaved => 'ไม่ได้บันทึกพอร์ต';

  @override
  String get deskKitInfoLabel => 'ข้อมูลเพิ่มเติม';

  @override
  String get advModeNodeOnly => 'โหนดเท่านั้น';

  @override
  String get advModeKillSwitch => 'สวิตช์ฉุกเฉิน';

  @override
  String get advModeStandardHint =>
      'ทุกอย่างที่กระเป๋าเงินตั้งค่าไว้: โหนด Epicbox ลิงก์ เว็บไซต์สถานะ ราคา และการตรวจหาอัปเดต Tor เป็นสวิตช์แยกต่างหากใน ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get advModeStandardHintNoTor =>
      'ทุกอย่างที่กระเป๋าเงินตั้งค่าไว้: โหนด Epicbox ลิงก์ เว็บไซต์สถานะ ราคา และการตรวจหาอัปเดต';

  @override
  String get advModeTorOnlyHint =>
      'ทุกการเชื่อมต่อผ่าน Tor รวมถึงโหนดและ Epicbox ไม่มีอะไรแตะอินเทอร์เน็ตเปิด จนกว่า Tor จะพร้อมจะไม่มีอะไรเชื่อมต่อ และไอคอนสถานะจะบอกไว้ การรับผ่านลิงก์ · HTTP ยังคงปิด: ที่อยู่ธรรมดาจะเผยอุปกรณ์เครื่องนี้';

  @override
  String get advModeNodeOnlyHint =>
      'กระเป๋าเงินคุยกับโหนดที่ใช้อยู่เท่านั้น คือโหนดแรกในรายการของคุณ สิ่งที่ปิด: Epicbox ลิงก์ เว็บไซต์สถานะ ราคา การตรวจหาอัปเดต ลิงก์ตัวสำรวจบล็อก การรายงานปัญหา การจับคู่ และอุปกรณ์ที่เชื่อมโยง ชำระด้วย QR และโอนไฟล์ใช้ได้ ถ้าเปิด Tor จะเชื่อมต่อโหนดผ่าน Tor เหมาะที่สุดกับโหนดของคุณเอง บนอุปกรณ์นี้หรือในเครือข่ายของคุณ โหนดใดก็ใช้ได้';

  @override
  String get advModeNodeOnlyHintNoTor =>
      'กระเป๋าเงินคุยกับโหนดที่ใช้อยู่เท่านั้น คือโหนดแรกในรายการของคุณ สิ่งที่ปิด: Epicbox ลิงก์ เว็บไซต์สถานะ ราคา การตรวจหาอัปเดต ลิงก์ตัวสำรวจบล็อก การรายงานปัญหา การจับคู่ และอุปกรณ์ที่เชื่อมโยง ชำระด้วย QR และโอนไฟล์ใช้ได้ เหมาะที่สุดกับโหนดของคุณเอง บนอุปกรณ์นี้หรือในเครือข่ายของคุณ โหนดใดก็ใช้ได้';

  @override
  String get advModeKillSwitchHint =>
      'ไม่มีอะไรเชื่อมต่อ แม้แต่โหนด: การเก็บแบบออฟไลน์ กระเป๋าเงินเปิดขึ้นพร้อมยอดคงเหลือและประวัติล่าสุดที่ทราบ คุณสร้าง ลงนาม และทำรายการให้เสร็จด้วยโอนไฟล์และชำระด้วย QR แสดงที่อยู่ สำรองข้อมูล และส่งออกได้ รายการที่เสร็จแล้วส่งเข้าเครือข่ายจากที่นี่ไม่ได้: บันทึกไว้หรือแสดงเป็นคิวอาร์โค้ด แล้วส่งจากอุปกรณ์ที่ออนไลน์ รายการที่รอผู้รับจะหยุดชั่วคราวและดำเนินต่อเมื่อคุณออกจากโหมดนี้';

  @override
  String advModeConfirmTitle(String mode) {
    return 'สลับไปที่ $mode ไหม';
  }

  @override
  String advModeConfirmBody(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'มี $count รายการรอผู้รับผ่าน Epicbox หรือลิงก์ รายการเหล่านั้นจะหยุดชั่วคราวและดำเนินต่อเมื่อคุณออกจาก $mode ไม่มีอะไรถูกยกเลิก',
    );
    return '$_temp0';
  }

  @override
  String get advModeConfirmSwitch => 'สลับ';

  @override
  String netMarkSemantics(String mode) {
    return 'โหมดเครือข่าย: $mode เปิดส่วนเครือข่าย';
  }

  @override
  String netMarkSemanticsDesk(String mode) {
    return 'โหมดเครือข่าย: $mode แสดงว่ามันทำอะไร';
  }

  @override
  String get netMarkLineTorOnly => 'ทุกการเชื่อมต่อผ่าน Tor';

  @override
  String get netMarkLineTorWaiting =>
      'รอ Tor จนกว่าจะพร้อมจะไม่มีอะไรเชื่อมต่อ';

  @override
  String get netMarkLineNodeOnly =>
      'เฉพาะโหนดที่ใช้อยู่ Epicbox ลิงก์ การอัปเดตและราคาปิดอยู่';

  @override
  String get netMarkLineKillSwitch =>
      'ไม่มีอะไรเชื่อมต่อ ยอดคงเหลือและประวัติเป็นข้อมูลล่าสุดที่ทราบ';

  @override
  String get netMarkChange => 'เปลี่ยน';

  @override
  String statusOffByMode(String mode) {
    return 'ปิด ($mode)';
  }

  @override
  String get statusOffByModeDetail =>
      'ปิดโดยโหมดเครือข่าย เปลี่ยนได้ที่ การตั้งค่า › ขั้นสูง › เครือข่าย';

  @override
  String get netBlockEpicboxNodeOnly =>
      'โหนดเท่านั้นเปิดอยู่: Epicbox ปิด ชำระด้วย QR และโอนไฟล์ใช้ได้';

  @override
  String get netBlockLinkNodeOnly =>
      'โหนดเท่านั้นเปิดอยู่: ลิงก์ปิด ชำระด้วย QR และโอนไฟล์ใช้ได้';

  @override
  String get netBlockSendKillSwitch =>
      'สวิตช์ฉุกเฉินเปิดอยู่: ไม่มีอะไรเชื่อมต่อ ชำระด้วย QR และโอนไฟล์ใช้ได้';

  @override
  String get netBlockNodeOnly => 'ปิดในโหมดโหนดเท่านั้น';

  @override
  String get netBlockKillSwitch => 'ปิดในสวิตช์ฉุกเฉิน: ไม่มีอะไรเชื่อมต่อ';

  @override
  String get netBlockWaitingForTorLong =>
      'รอ Tor จนกว่าจะพร้อมจะไม่มีอะไรเชื่อมต่อ';

  @override
  String receiveEpicboxOffMode(String mode) {
    return 'Epicbox ปิดใน $mode';
  }

  @override
  String receiveEpicboxOffModeBody(String mode) {
    return 'รายการที่ส่งมายังที่อยู่นี้จะรออยู่บนเซิร์ฟเวอร์ Epicbox และมาถึงเมื่อคุณออกจาก $mode';
  }

  @override
  String receiveLinkOffMode(String mode) {
    return 'การรับผ่านลิงก์ปิดใน $mode';
  }

  @override
  String updatesOffMode(String mode) {
    return 'การตรวจหาอัปเดตปิดใน $mode';
  }

  @override
  String reportOffMode(String mode) {
    return 'ปิดใน $mode ให้บันทึกรายงานเป็นไฟล์แทน';
  }

  @override
  String get recheckOffKill => 'ตรวจยอดใหม่ต้องใช้โหนด ปิดในสวิตช์ฉุกเฉิน';

  @override
  String get postFinishedOffKill =>
      'ปิดในสวิตช์ฉุกเฉิน: ที่นี่ไม่มีอะไรเชื่อมต่อ';

  @override
  String get postFinishedOffTor => 'รอ Tor การส่งเข้าเครือข่ายต้องใช้โหนด';

  @override
  String get browserOffTorOnly => 'จะเปิดนอก Tor ให้คัดลอกลิงก์แทน';

  @override
  String browserOffMode(String mode) {
    return 'ปิดใน $mode ให้คัดลอกลิงก์แทน';
  }

  @override
  String get netChangeLink => 'เปลี่ยน';

  @override
  String get lastKnownCaption => 'ล่าสุดที่ทราบ';

  @override
  String get lastKnownList => 'ล่าสุดที่ทราบ · สวิตช์ฉุกเฉิน';

  @override
  String lastKnownConfirming(String text) {
    return '$text · ล่าสุดที่ทราบ';
  }

  @override
  String get coldNeedsOnlineCheck => 'ต้องตรวจยอดแบบออนไลน์หนึ่งครั้งก่อน';

  @override
  String get finalizeNotPostedTitle => 'เสร็จแล้ว แต่ยังไม่ได้ส่งเข้าเครือข่าย';

  @override
  String finalizeNotPostedBody(String amount) {
    return '$amount เสร็จแล้ว สวิตช์ฉุกเฉินเปิดอยู่ โทรศัพท์เครื่องนี้จึงส่งเข้าเครือข่ายไม่ได้ ให้บันทึกไว้หรือแสดงเป็นคิวอาร์โค้ด แล้วส่งจากอุปกรณ์ที่ออนไลน์: ประวัติ › ส่งรายการที่เสร็จแล้ว';
  }

  @override
  String get finishedSaveFile => 'บันทึกไฟล์';

  @override
  String get finishedShowQr => 'แสดง QR';

  @override
  String finishedSaved(String name) {
    return 'บันทึก $name แล้ว';
  }

  @override
  String get finishedQrTitle => 'รายการที่เสร็จแล้ว';

  @override
  String get finishedUnavailable =>
      'เวอร์ชันนี้ยังบันทึกรายการที่เสร็จแล้วไม่ได้';

  @override
  String get finishedFailed => 'อ่านรายการที่เสร็จแล้วไม่ได้';

  @override
  String get txPostElsewhere => 'รอส่งจากอุปกรณ์อื่น';

  @override
  String get txPostElsewhereKill =>
      'เสร็จแล้วในสวิตช์ฉุกเฉิน ให้บันทึกไว้หรือแสดงคิวอาร์โค้ด แล้วส่งจากอุปกรณ์ที่ออนไลน์';

  @override
  String get txPostElsewhereAfter =>
      'เสร็จแล้วในสวิตช์ฉุกเฉิน ยังไม่เห็นบนเชน ส่งจากที่นี่ หรือรออุปกรณ์ที่ส่งไว้';

  @override
  String get txPostNow => 'ส่งตอนนี้';

  @override
  String get txModeFinishedKill => 'เสร็จแล้วในสวิตช์ฉุกเฉิน';

  @override
  String get txModeRow => 'โหมด';

  @override
  String get postFinishedTitle => 'ส่งรายการที่เสร็จแล้ว';

  @override
  String get postFinishedIntro =>
      'ส่งรายการที่อุปกรณ์อื่นทำให้เสร็จในสวิตช์ฉุกเฉิน';

  @override
  String get postFinishedOpenFile => 'เปิดไฟล์';

  @override
  String get postFinishedScanQr => 'สแกน QR';

  @override
  String get postFinishedPaste => 'วาง';

  @override
  String get postFinishedChooseFile => 'เลือกไฟล์';

  @override
  String get postFinishedSummary => 'รายการที่เสร็จแล้ว';

  @override
  String get postFinishedAmount => 'จำนวน';

  @override
  String get postFinishedFee => 'ค่าธรรมเนียม';

  @override
  String get postFinishedKernel => 'Kernel';

  @override
  String get postFinishedNote =>
      'การส่งจะนำรายการเข้าสู่เครือข่าย กระเป๋าเงินที่สร้างรายการจะแสดงว่ากำลังยืนยันเมื่อเห็นรายการบนเชน';

  @override
  String get postFinishedPost => 'ส่ง';

  @override
  String get postFinishedPosting => 'กำลังส่ง…';

  @override
  String get postFinishedDone => 'ส่งเข้าเครือข่ายแล้ว';

  @override
  String get postFinishedDoneBody =>
      'โหนดรับไว้แล้ว กระเป๋าเงินที่สร้างรายการจะแสดงว่ากำลังยืนยันเมื่อเห็นรายการบนเชน';

  @override
  String get postFinishedNotFinished =>
      'นี่ไม่ใช่รายการที่เสร็จแล้ว ให้เปิดไฟล์ที่บันทึกไว้ใน รอส่งจากอุปกรณ์อื่น หรือสแกน QR ของไฟล์นั้น';

  @override
  String get postFinishedFailed => 'โหนดไม่รับไว้ ลองอีกครั้ง';

  @override
  String get postFinishedUnreachable => 'โหนดไม่ตอบสนอง';

  @override
  String get postFinishedDeskRow => 'ส่งรายการที่เสร็จแล้ว';

  @override
  String get postFinishedDeskRowText =>
      'ส่งรายการที่อุปกรณ์อื่นทำให้เสร็จในสวิตช์ฉุกเฉิน';

  @override
  String get postFinishedOpen => 'เปิด';

  @override
  String get deskSetAdvModeStandardHint =>
      'ทุกอย่างที่กระเป๋าเงินตั้งค่าไว้: โหนด Epicbox ลิงก์ เว็บไซต์สถานะ ราคา และการตรวจหาอัปเดต Tor เป็นสวิตช์แยกต่างหากใน ความเป็นส่วนตัว';

  @override
  String deskFinNotPostedKillBody(String amount) {
    return '$amount เสร็จแล้ว สวิตช์ฉุกเฉินเปิดอยู่ คอมพิวเตอร์เครื่องนี้จึงส่งเข้าเครือข่ายไม่ได้ ให้บันทึกไว้หรือคัดลอก แล้วส่งจากอุปกรณ์ที่ออนไลน์: รับ › ไฟล์ธุรกรรม › ส่งรายการที่เสร็จแล้ว';
  }

  @override
  String netMarkRowLabel(String mode) {
    return 'โหมดเครือข่าย: $mode';
  }

  @override
  String get qrStatusFinishedHidden => 'ซ่อนอยู่';

  @override
  String get qrStatusFinishedShowing => 'รออุปกรณ์ที่ออนไลน์มาสแกน';

  @override
  String qrShowSubFinished(String amount) {
    return '$amount เสร็จแล้ว';
  }

  @override
  String qrSemanticsFinished(String state) {
    return 'คิวอาร์โค้ดของรายการที่เสร็จแล้ว, $state';
  }

  @override
  String get qrHiddenBodyFinished =>
      'แสดงให้อุปกรณ์ที่ออนไลน์ดู อุปกรณ์นั้นจะส่งรายการเข้าเครือข่าย ไม่ต้องใช้กุญแจ';

  @override
  String get qrScanFinished => 'สแกนรายการที่เสร็จแล้ว';

  @override
  String get qrScanNotFinished => 'โค้ดนี้ไม่ใช่รายการที่เสร็จแล้ว';

  @override
  String get qrScanAimFinished => 'หันกล้องไปที่โค้ดบนอุปกรณ์อีกเครื่อง';

  @override
  String get deskRailOpenNetwork => 'เปิดการตั้งค่าเครือข่าย';

  @override
  String get cancelFeeLine => 'มีค่าธรรมเนียมเครือข่ายตามปกติ';

  @override
  String get cancelForSure => 'ยกเลิกแน่นอน';

  @override
  String get cancelStopWaiting => 'หยุดรอ';

  @override
  String get cancelStopWaitingLine =>
      'ไม่มีค่าธรรมเนียม รายการนี้ยังอาจสำเร็จได้';

  @override
  String get cancelChoicesTitle => 'สองวิธีในการยกเลิก';

  @override
  String get cancelChoicesWhy =>
      'ยกเลิกแน่นอน จะย้ายเหรียญกลับมายังกระเป๋าเงินนี้ก่อน โดยมีค่าธรรมเนียมเครือข่ายตามปกติ หลังจากนั้นรายการเดิมจะสำเร็จไม่ได้อีกเลย จึงเป็นวิธีที่แน่นอน\n\nหยุดรอ ไม่มีค่าธรรมเนียมและไม่ย้ายอะไร เหรียญกลับมาใช้ได้อีก และรายการคงไว้ตามเดิม หากอีกฝ่ายทำรายการให้เสร็จในภายหลัง รายการจะสำเร็จและแสดงว่าจ่ายแล้ว หากไม่ ก็ไม่มีอะไรเกิดขึ้น';

  @override
  String get cancelStoppedWaitingTitle => 'หยุดรอแล้ว';

  @override
  String get cancelStoppedWaitingText =>
      'เหรียญกลับมาใช้ได้อีก รายการนี้ยังอาจสำเร็จได้ หากสำเร็จจะแสดงว่าจ่ายแล้ว';

  @override
  String get txDetailsStoppedWaiting =>
      'หยุดรอแล้ว เหรียญกลับมาใช้ได้อีก รายการนี้ยังอาจสำเร็จได้ หากสำเร็จจะแสดงว่าจ่ายแล้ว';

  @override
  String get errorPaymentCancelledCoinsMoved =>
      'รายการนี้ถูกยกเลิกแล้ว และเหรียญถูกย้ายไปแล้ว รายการจึงสำเร็จไม่ได้อีก';

  @override
  String get errorPaymentAlreadyWentThrough =>
      'ย้ายเหรียญกลับมาไม่ได้: รายการเดิมสำเร็จไปแล้ว รายการแสดงว่าชำระแล้ว';

  @override
  String get errorPinKeyLost =>
      'PIN เปิดกระเป๋าเงินนี้ไม่ได้แล้ว เหรียญของคุณยังปลอดภัย: แตะ \"ลืม PIN\" แล้วกู้คืนกระเป๋าเงินจากวลีกู้คืน';

  @override
  String get settingsUsePassphrase => 'ใช้วลีรหัสผ่านแทน PIN';

  @override
  String get settingsChangePassphrase => 'เปลี่ยนวลีรหัสผ่าน';

  @override
  String get passphraseLabel => 'วลีรหัสผ่าน';

  @override
  String passphraseChoose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เลือกวลีรหัสผ่านอย่างน้อย $count ตัวอักษร ที่ไม่ใช่ตัวเลขล้วน',
    );
    return '$_temp0';
  }

  @override
  String get passphraseRepeat => 'ใส่วลีรหัสผ่านอีกครั้ง';

  @override
  String get passphraseMismatch => 'วลีรหัสผ่านทั้งสองไม่ตรงกัน';

  @override
  String get passphraseSet => 'ตั้งวลีรหัสผ่านแล้ว';

  @override
  String get passphraseSetBiometricsOff =>
      'ตั้งวลีรหัสผ่านแล้ว เปิดการปลดล็อกด้วยไบโอเมตริกอีกครั้งได้ด้านล่าง';

  @override
  String get passphraseForgot => 'ลืมวลีรหัสผ่าน?';

  @override
  String get passphrasePromptTitle => 'ใส่วลีรหัสผ่านของคุณ';

  @override
  String get passphraseEnterCurrent => 'ใส่วลีรหัสผ่านปัจจุบันของคุณ';

  @override
  String get passphraseCurrentLabel => 'วลีรหัสผ่านปัจจุบัน';

  @override
  String get passphraseChooseTitle => 'เลือกวลีรหัสผ่าน';

  @override
  String passphraseRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อย่างน้อย $count ตัวอักษร และไม่ใช่ตัวเลขล้วน',
    );
    return '$_temp0';
  }

  @override
  String get passphraseUsePinInstead => 'ใช้ PIN แทน';

  @override
  String get passphraseUsePassphraseInstead => 'ใช้วลีรหัสผ่านแทน';

  @override
  String get biometricsFromNextStart =>
      'การปลดล็อกด้วยไบโอเมตริกจะใช้ได้ตั้งแต่เปิดแอปครั้งถัดไป';

  @override
  String get invoicePassphraseReason => 'ใส่วลีรหัสผ่านเพื่อชำระใบแจ้งหนี้นี้';

  @override
  String get restoreReplacePassphraseReason =>
      'ใส่วลีรหัสผ่านเพื่อแทนที่กระเป๋าเงินนี้ กระเป๋าเงินที่กู้คืนจะใช้วลีรหัสผ่านนี้ต่อ';

  @override
  String get backupPassphraseReason => 'ใส่วลีรหัสผ่านเพื่อแสดงวลีกู้คืน';

  @override
  String sendQrPassphraseReason(String amount) {
    return 'ใส่วลีรหัสผ่านเพื่อสร้าง QR ของรายการ $amount';
  }

  @override
  String get settingsBiometricsPassphraseReason =>
      'ป้อนวลีรหัสผ่านเพื่อเปิดการปลดล็อกด้วยไบโอเมตริก';

  @override
  String get settingsDeletePassphraseReason =>
      'ป้อนวลีรหัสผ่านเพื่อลบกระเป๋านี้';

  @override
  String sendPassphraseReason(String amount) {
    return 'ใส่วลีรหัสผ่านเพื่อส่ง $amount';
  }

  @override
  String sendFilePassphraseReason(String amount) {
    return 'ใส่วลีรหัสผ่านเพื่อสร้างไฟล์ธุรกรรม $amount';
  }

  @override
  String get passphraseSetTitle => 'ตั้งวลีรหัสผ่าน';
}
