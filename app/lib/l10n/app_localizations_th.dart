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
          'ข้อมูลสำรองมีรายละเอียดต่างจากที่คุณระบุไว้ใน $n รายการ ระบบจะใช้ของคุณ เว้นแต่คุณเลือกอย่างอื่น',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'ของฉัน';

  @override
  String get histConflictBackup => 'ข้อมูลสำรอง';

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
      'ยกเลิกแล้ว ไม่มีการชำระเงิน และยอดเงินกลับมาใช้ได้แล้ว หากผู้รับได้รับรายการนี้ไปแล้ว กระเป๋าเงินของผู้รับอาจยังแสดงว่ากำลังรอ แต่รายการนี้ทำให้เสร็จไม่ได้อีกแล้ว';

  @override
  String get txDetailsCancelledReleased =>
      'เครือข่ายไม่รับรายการนี้ จึงปลดยอดเงินแล้ว ตรวจสอบว่าผู้รับไม่ได้รับเงินก่อนส่งใหม่';

  @override
  String get txDetailsCancelledNotOnChain =>
      'รายการไม่เข้าสู่เครือข่ายภายใน 14 วัน กระเป๋าเงินจึงยกเลิก ตรวจสอบว่าผู้รับไม่ได้รับเงินก่อนส่งใหม่';

  @override
  String get txDetailsCancelledUnanswered =>
      'ผู้รับไม่ตอบภายใน 14 วัน กระเป๋าเงินจึงยกเลิก ไม่มีการชำระเงิน และยอดเงินกลับมาใช้ได้แล้ว';

  @override
  String get txDetailsCancelledLateAnswer =>
      'ผู้รับตอบหลังครบกำหนด 14 วัน กระเป๋าเงินจึงยกเลิกแทนการทำรายการให้เสร็จ ไม่มีการชำระเงิน และยอดเงินกลับมาใช้ได้แล้ว';

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
  String get statusEpicboxOnline => 'เชื่อมต่อ Epicbox แล้ว';

  @override
  String get statusEpicboxConnecting => 'กำลังเชื่อมต่อ Epicbox';

  @override
  String get statusEpicboxOffline => 'ไม่ได้เชื่อมต่อ Epicbox';

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
  String invoiceDetailsRepliedHelp(String service) {
    return 'หาก $service ยังไม่ได้โพสต์การชำระเงิน ให้ส่งอีกครั้ง โดยไม่มีการลงนามซ้ำ หากไม่ได้โพสต์เลย ปุ่มยกเลิกจะใช้ได้เมื่อหมดเวลาของการชำระเงิน ประมาณหนึ่งวันหลังจากชำระ';
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
      'กระเป๋าไม่ได้รับอนุญาตให้ใช้กล้อง หากต้องการสแกน ให้อนุญาตการเข้าถึงกล้องสำหรับแอปนี้ในการตั้งค่าโทรศัพท์ หรือวางที่อยู่แทน';

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
      'กระเป๋าไม่ได้รับอนุญาตให้ใช้กล้อง หากต้องการสแกน ให้อนุญาตการเข้าถึงกล้องของแอปนี้ในการตั้งค่าของโทรศัพท์ หรือจะเปิดไฟล์แทนก็ได้';

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
      'ชำระด้วย QR: โค้ดส่งจากโทรศัพท์เครื่องหนึ่งไปยังอีกเครื่องที่อยู่ข้างกัน';

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
  String get receiveQrTitle => 'อยู่ข้างผู้ส่งไหม?';

  @override
  String get receiveQrBody =>
      'สแกนโค้ดบนโทรศัพท์ของผู้ส่ง รับรายการ แล้วแสดงคำตอบของคุณ';

  @override
  String get txQrLine => 'จ่ายหรือรับเงินเมื่ออยู่ข้างกัน ด้วยโค้ดบนหน้าจอ';

  @override
  String get txQrHint =>
      'ชำระด้วย QR แสดงรายการเป็นโค้ดเคลื่อนไหวที่โทรศัพท์อีกเครื่องสแกนด้วยกล้อง และรับคำตอบด้วยวิธีเดียวกัน ใช้ได้เฉพาะโทรศัพท์ที่อยู่ข้างกัน ไม่ต้องมีการเชื่อมต่อระหว่างกระเป๋าทั้งสอง และโค้ดจะซ่อนเองหลัง 40 วินาที เพิ่ม ชำระด้วย QR ในส่งและรับ';

  @override
  String get advTransactionFiles => 'ไฟล์ธุรกรรม';

  @override
  String get advTransactionFilesHint =>
      'เพิ่มสวิตช์ไฟล์ใน ตั้งค่า › ธุรกรรม: จ่ายหรือรับเงินด้วยไฟล์ที่คุณส่งต่อเอง';

  @override
  String get sendQrTitle => 'ชำระด้วย QR';

  @override
  String get sendMakeQr => 'สร้าง QR ของรายการ';

  @override
  String sendQrPinReason(String amount) {
    return 'ใส่ PIN เพื่อสร้าง QR ของรายการ $amount';
  }

  @override
  String get sendQrMade => 'สร้างรายการแล้ว';

  @override
  String get sendQrHint => 'แสดงโค้ดให้โทรศัพท์ของผู้รับ แล้วสแกนคำตอบของเขา';

  @override
  String get sendCancelRuleQr => 'ยกเลิกได้จนกว่าคุณจะสแกนคำตอบของเขา';

  @override
  String get qrStatusSendHidden => 'แสดงสิ่งนี้ให้ผู้รับ';

  @override
  String get qrStatusSendShowing => 'รอผู้รับสแกน แล้วสแกนคำตอบของเขา';

  @override
  String get qrStatusHiddenAgain => 'ซ่อนอยู่ แสดงอีกครั้งถ้าเขาสแกนไม่ทัน';

  @override
  String get qrStatusReplyHidden => 'แสดงสิ่งนี้ให้ผู้ส่ง';

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
  String get contactsAddressInvalidAny =>
      'ที่อยู่ไม่ถูกต้อง ใช้ที่อยู่ Epicbox (es5x…@epicbox.epiccash.com) ที่อยู่ลิงก์ (https://…) หรือที่อยู่ onion (….onion)';

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
      'ที่อยู่ที่สองสำหรับใบแจ้งหนี้โดยเฉพาะ ให้บริการที่เชื่อถือส่งใบแจ้งหนี้มาได้ ข้อความจากคนอื่นจะถูกทิ้ง และจะไม่จ่ายอะไรจนกว่าคุณจะอนุมัติใบแจ้งหนี้แต่ละใบด้วย PIN ที่อยู่นี้แยกจากที่อยู่สำหรับรับชำระเงินของคุณ';

  @override
  String get invoiceSettingsTitle => 'ใบแจ้งหนี้';

  @override
  String get invoiceSettingsAddressTitle => 'ที่อยู่สำหรับใบแจ้งหนี้';

  @override
  String get invoiceSettingsAddressBody =>
      'ให้ที่อยู่นี้กับบริการที่เชื่อถือ เพื่อให้ส่งใบแจ้งหนี้ได้ ที่อยู่นี้แยกจากที่อยู่สำหรับรับชำระเงินของคุณ';

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
  String get settingsCheckUpdates => 'ตรวจหาอัปเดต';

  @override
  String get settingsHelp => 'ช่วยเหลือ';

  @override
  String get settingsSendFeedback => 'ส่งความคิดเห็น';

  @override
  String get settingsSendFeedbackHint =>
      'แจ้งปัญหาหรือเสนอไอเดียให้ผู้พัฒนา ล็อกจะส่งไปเฉพาะเมื่อคุณแนบ โดยลบวลีกู้คืน PIN และข้อมูลลับอื่นๆ ออกก่อน';

  @override
  String get settingsSourceCode => 'ซอร์สโค้ด';

  @override
  String get settingsLicences => 'สัญญาอนุญาต';

  @override
  String get licencesLead =>
      'ซอฟต์แวร์โอเพนซอร์สในกระเป๋านี้ แต่ละส่วนใช้สัญญาอนุญาตของตนเอง ดูข้อความเต็มได้ในแตะเดียว';

  @override
  String get licencesApp => 'Epic Cash Mobile โดย BT Labs: Apache-2.0';

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
      'แสดงด้านเทคนิค รายละเอียดโหนดและเซิร์ฟเวอร์ Epicbox ความสูงบล็อก ไฟล์ธุรกรรม และล็อก เมื่อปิด แอปจะแสดงเฉพาะสิ่งที่ใช้ในชีวิตประจำวัน';

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
  String get settingsHubBackup => 'สำรองข้อมูล';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'ใช้ status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'อ่านจาก status.btlabs.uk ระบบติดตามของ BT Labs ว่าโหนดและเซิร์ฟเวอร์ Epicbox ใดออนไลน์ ความสูงบล็อกและเวลาตอบสนอง แล้วแสดงในรายการเซิร์ฟเวอร์และการ์ดสถานะ เมื่อปิด จะไม่ถาม status.btlabs.uk เลย และรายการเซิร์ฟเวอร์จะไม่แสดงสถานะ';

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
  String sendRelayDown(String relay) {
    return 'เซิร์ฟเวอร์ของผู้รับ ($relay)ไม่ตอบสนอง';
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
  String get handshakeLink1 =>
      'กระเป๋าของคุณส่งรายการตรงไปยังกระเป๋าของอีกฝ่ายผ่านอินเทอร์เน็ตหรือ Tor เหรียญของคุณถูกพักไว้';

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
          'เซิร์ฟเวอร์ของผู้รับ ($relay)ไม่รับรายการ จำนวนเงินจะถูกพักไว้จนกว่าจะยกเลิก หรือไม่เกิน $days วัน',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'เซิร์ฟเวอร์ของผู้รับ ($relay)ไม่รับรายการ ตรวจสอบหน้ากระเป๋าก่อนส่งอีกครั้ง';
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
  String get receiveTorAddressLabel => 'ลิงก์ของคุณ';

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
  String get tourPhoneSemantics => 'ทัวร์กระเป๋าเงิน';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current จาก $total';
  }

  @override
  String get tourPhoneSkip => 'ข้าม';

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
  ) {
    return 'ใช้ $spent ($amount) และสร้าง $made ประมาณ $each ต่อเอาต์พุต เป็นธุรกรรมปกติบนเครือข่ายที่ส่งเข้ากระเป๋านี้ ยืนยันหลัง 3 บล็อกเหมือนการส่งทั่วไป ยอดที่ใช้ได้ทั้งหมดจะถูกล็อกจนกว่าจะยืนยัน เอาต์พุตที่มากขึ้นช่วยให้การส่งครั้งถัดไปหลายรายการออกไปได้โดยไม่ต้องรอเงินทอนของกันและกัน';
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
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => 'สถานะเครือข่าย';

  @override
  String get serverMyRelays => 'เซิร์ฟเวอร์ของฉัน';

  @override
  String get serverMenuDelete => 'ลบ';

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
  String get serverOtherNodeInvalid =>
      'ใส่ที่อยู่โหนด เช่น node.example.com:3413';

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
  String get methodDirectHttp => 'จ่ายผ่านลิงก์ · HTTP';

  @override
  String get methodDirectTor => 'จ่ายผ่านลิงก์ · Tor';

  @override
  String get methodFile => 'ไฟล์';

  @override
  String get methodShortHttp => 'Link · HTTP';

  @override
  String get methodShortTor => 'Link · Tor';

  @override
  String get methodShortQr => 'QR';

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
      'ผู้ชำระเปิดใบแจ้งหนี้ใน [[ใบแจ้งหนี้ › ชำระ|Invoices › Pay]] ตรวจผู้ส่ง จำนวน และข้อความ แล้วเลือก **อนุมัติและชำระ** ด้วยรหัสผ่านกระเป๋า';

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
      'ใบแจ้งหนี้ที่กระเป๋านี้ออกอยู่ใน [[ใบแจ้งหนี้ › ออก|Invoices › Issue]]';

  @override
  String get deskInvHelpTrustTitle => 'ทำไมรับเฉพาะผู้ส่งที่เชื่อถือ';

  @override
  String get deskInvHelpTrustShort =>
      'เฉพาะผู้ส่งในรายการที่เชื่อถือเท่านั้นที่ส่งใบแจ้งหนี้เข้ามาได้ ช่วยกันสแปมและบิลปลอม';

  @override
  String get deskInvHelpTrustP1 =>
      'กระเป๋ารับใบแจ้งหนี้เฉพาะที่ที่อยู่สำหรับใบแจ้งหนี้ และเฉพาะจากผู้ส่งในรายการที่เชื่อถือ โดยจับคู่จากที่อยู่ของผู้ส่ง สิ่งอื่นจะถูกทิ้งโดยไม่เปิดอ่าน และไม่แสดงใน [[ใบแจ้งหนี้ › ชำระ|Invoices › Pay]]';

  @override
  String get deskInvHelpTrustP2 =>
      'หากไม่มีรายการนี้ ใครก็ตามที่รู้ที่อยู่สำหรับใบแจ้งหนี้อาจส่งสแปมหรือบิลที่ดูเหมือนจริงเข้ามาได้';

  @override
  String get deskInvHelpTrustP3 =>
      'การเชื่อถือเพียงอนุญาตให้ผู้ส่งขอเงินได้ ผู้ส่งที่เชื่อถือไม่สามารถเอาเงินไปได้ ใบแจ้งหนี้ทุกใบยังต้องรอ **อนุมัติและชำระ**';

  @override
  String get deskInvHelpTrustWhere1 =>
      'เพิ่มผู้ส่งที่เชื่อถือได้ใน [[การตั้งค่า › ใบแจ้งหนี้|Settings › Invoices]]';

  @override
  String get deskInvHelpTrustWhere2 =>
      'หรือเปิด **เชื่อถือสำหรับใบแจ้งหนี้** ที่ผู้ติดต่อใน [[ผู้ติดต่อ|Contacts]]';

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
      'กระเป๋ามีที่อยู่ Epicbox สองที่อยู่ **ที่อยู่รับเงิน** ใน [[รับ|Receive]] ใช้รับเงิน **ที่อยู่สำหรับใบแจ้งหนี้** รับเฉพาะใบแจ้งหนี้';

  @override
  String get deskInvHelpAddrP2 =>
      'การแยกกันทำให้ให้ที่อยู่สำหรับใบแจ้งหนี้กับบริการต่างๆ หรือเปลี่ยนใหม่ได้ โดยไม่เปิดเผยหรือเปลี่ยนที่อยู่ที่ผู้อื่นใช้ชำระ';

  @override
  String get deskInvHelpAddrP3 =>
      'ที่อยู่สำหรับใบแจ้งหนี้ไม่รับเงิน เงินที่ส่งมาที่อยู่นี้จะถูกทิ้ง หากต้องการรับเงิน ให้ใช้ที่อยู่รับเงิน';

  @override
  String get deskInvHelpAddrWhere1 =>
      'ดู คัดลอก หรือแสดงที่อยู่สำหรับใบแจ้งหนี้เป็น QR Code ได้ใน [[การตั้งค่า › ใบแจ้งหนี้|Settings › Invoices]]';

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
  String get deskInvIssuerDirect => 'ลิงก์';

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
      'มีการชำระเงินสำหรับใบแจ้งหนี้ที่อุปกรณ์นี้ไม่ได้ออกเข้ามา ระบบจะเก็บไว้บนรีเลย์หนึ่งวันสำหรับอุปกรณ์อีกเครื่องของคุณที่ใช้กระเป๋านี้ เปิดกระเป๋าที่เครื่องนั้นเพื่อทำให้เสร็จ';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'มีคำตอบของการชำระเงินที่อุปกรณ์นี้ไม่ได้ส่งเข้ามา ระบบจะเก็บไว้บนรีเลย์หนึ่งวันสำหรับอุปกรณ์อีกเครื่องของคุณที่ใช้กระเป๋านี้ เปิดกระเป๋าที่เครื่องนั้นเพื่อทำให้เสร็จ';

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
  String get methodDirect => 'ลิงก์';

  @override
  String get methodLinkPayment => 'จ่ายผ่านลิงก์';

  @override
  String get methodDirectShape => 'http://host:3415 หรือ xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'กระเป๋าของผู้รับต้องเปิดอยู่ ที่อยู่ onion จะส่งผ่าน Tor';

  @override
  String get methodArtLabelDirect =>
      'จ่ายผ่านลิงก์: รายการจะไปถึงกระเป๋าของผู้รับโดยตรง ซึ่งต้องเปิดอยู่';

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
  String get receiveTabDirect => 'ลิงก์';

  @override
  String get receiveDirectNeedsTor => 'การรับผ่านลิงก์ต้องใช้ Tor';

  @override
  String get receiveDirectMeanwhile => 'ระหว่างนี้ผู้ส่งใช้ที่อยู่ Epicbox';

  @override
  String get receiveHttpTitle => 'Link · HTTP address';

  @override
  String get receiveHttpLanLine =>
      'For wallets on this Wi-Fi network, while the app is open.';

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
  String get netStatusOverTor => 'ผ่าน Tor';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsNotificationsHint =>
      'แจ้งเมื่อมีการชำระเงินหรือใบแจ้งหนี้เข้ามาขณะที่แอปปิดอยู่ ใช้ Epicbox ของ BT Labs และบริการแจ้งเตือนของ Google ข้อความใช้เพียงปลุกแอป ไม่มีจำนวนเงิน ผู้ส่ง หรือที่อยู่ ปิดขณะเปิด Tor เพราะการลงทะเบียนจะเปิดเผยที่อยู่ของโทรศัพท์';

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
  String get pushNoticeAvailable => 'เปิดการแจ้งเตือนได้ในการตั้งค่า › ขั้นสูง';

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
      'ติดต่อกระเป๋าเงินของผู้รับผ่าน Tor ไม่ได้';

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
  String get deskErrTestNet =>
      'กระเป๋าเงินของเครือข่ายทดสอบ นำเข้าได้เฉพาะกระเป๋าเงิน Mainnet';

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
      'อ่านประวัติของ Epic Wallet 5.3 หรือเก่ากว่าไม่ได้ การสแกนจะกู้ยอดคงเหลือคืน';

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
    return 'กำลังเชื่อมต่อ Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'ข้อมูลสำรองของกระเป๋าเงินอื่น';

  @override
  String get deskErrHistOtherChain => 'เครือข่ายไม่ตรง';

  @override
  String get deskErrHistNotOurs => 'ไม่ใช่ข้อมูลสำรองประวัติ';

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
  String deskErrHistChains(String from, String to) {
    return 'ไฟล์มาจาก $from แต่กระเป๋าเงินนี้อยู่บน $to';
  }

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
    return 'เซิร์ฟเวอร์อัปเดตตอบกลับ $status';
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
  String get deskNodeFailPort => 'พอร์ต 3413 ถูกโปรแกรมอื่นใช้อยู่';

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
  String get deskNodeNoEstimate => 'ประเมินไม่ได้ อาจถึงหนึ่งชั่วโมง';

  @override
  String get deskNodeEstimating => 'กำลังประเมิน…';

  @override
  String deskNodeAboutHours(int hours) {
    return 'เหลือประมาณ $hours ชั่วโมง';
  }

  @override
  String deskNodeAboutMinutes(int minutes) {
    return 'เหลือประมาณ $minutes นาที';
  }

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
  String get deskTorRoutes =>
      'Epicbox, โหนด, สถานะ, ราคา, อัปเดต, ฝ่ายช่วยเหลือ และที่อยู่ Tor';

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
  String get deskRecvNameFile => 'ไฟล์';

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
  String deskRecvTorDownText(String routes) {
    return 'จะไม่มีอะไรเข้าผ่าน $routes จนกว่า Tor จะเชื่อมต่อ หรือจนกว่าจะปิด Tor';
  }

  @override
  String get deskRecvTorStartingText =>
      'ที่อยู่จะเข้าถึงได้เมื่อ Tor เชื่อมต่อแล้ว ระหว่างนี้ไม่มีอะไรผ่านอินเทอร์เน็ตปกติ';

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
      'แชร์เพื่อรับเงิน ใช้ได้แม้กระเป๋าเงินปิดอยู่: เซิร์ฟเวอร์ Epicbox จะเก็บรายการไว้จนกว่ากระเป๋าเงินจะกลับมา';

  @override
  String get deskRecvCheckSix =>
      'เวลาอ่านให้กัน ให้เทียบ 6 ตัวแรกและ 6 ตัวสุดท้าย';

  @override
  String get deskRecvHttpAddress => 'ลิงก์ · ที่อยู่ HTTP';

  @override
  String get deskRecvCopyHttp => 'คัดลอกที่อยู่ HTTP';

  @override
  String deskRecvHttpPublic(int port) {
    return 'ที่อยู่สาธารณะของเราเตอร์ ผู้ส่งบนอินเทอร์เน็ตใช้ได้เมื่อเราเตอร์ forward พอร์ต $port แล้ว';
  }

  @override
  String get deskRecvHttpLocal =>
      'โปรแกรมบนคอมพิวเตอร์นี้จ่ายมาที่ที่อยู่นี้ได้ สำหรับอุปกรณ์อื่น ดูที่ การตั้งค่า › ธุรกรรม';

  @override
  String get deskRecvHttpIntro =>
      'ตรงจากกระเป๋าเงินอื่นขณะที่กระเป๋าเงินนี้เปิดอยู่ ใช้ได้บนคอมพิวเตอร์นี้เท่านั้น เว้นแต่ตั้งค่าไว้เป็นอื่น';

  @override
  String get deskRecvHttpTorHint =>
      'เปิด Tor ที่ การตั้งค่า › ความเป็นส่วนตัว เพื่อใช้ที่อยู่ Tor แทน';

  @override
  String get deskRecvDirectTor => 'ลิงก์ · ที่อยู่ Tor';

  @override
  String get deskRecvTorIntro =>
      'ตรงจากกระเป๋าเงินอื่นผ่าน Tor ขณะที่กระเป๋าเงินนี้เปิดอยู่ ตั้งค่า Tor ได้ที่ การตั้งค่า › ความเป็นส่วนตัว';

  @override
  String get deskRecvTorAddress => 'ลิงก์ · ที่อยู่ Tor';

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
      'ผู้ส่งให้ไฟล์ธุรกรรมมา กระเป๋าเงินจะลงนามและบันทึกไฟล์ตอบกลับให้ผู้ส่ง';

  @override
  String get deskRecvOpen => 'เปิด';

  @override
  String get deskRecvFinalizeTitle => 'ทำรายการให้เสร็จด้วยไฟล์ตอบกลับ';

  @override
  String get deskRecvFinalizeText =>
      'การส่งด้วยไฟล์ได้ไฟล์ตอบกลับมาแล้ว การทำให้เสร็จจะส่งรายการเข้าเครือข่าย';

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
  String deskSendLockAll(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทุกอย่างถูกล็อก: $count เอาต์พุต $amount EPIC ประมาณ 3 บล็อก',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ล็อก $count เอาต์พุต $amount EPIC ประมาณ 3 บล็อก',
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
  String deskSendReviewLocksAll(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ทั้งหมด: $locked EPIC ใน $count เอาต์พุต จนกว่าเงินทอนจะยืนยัน (3 บล็อก) ไม่มีส่วนไหนใช้ได้ระหว่างนั้น',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC ใน $count เอาต์พุต จนกว่าเงินทอนจะยืนยัน (3 บล็อก) ไม่มีส่วนอื่นใช้ได้ระหว่างนั้น',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksSome(int count, String locked, String spendable) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC ใน $count เอาต์พุต จนกว่าเงินทอนจะยืนยัน (3 บล็อก) ยังใช้ได้ $spendable EPIC',
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
      'ให้ไฟล์นี้กับผู้รับ กระเป๋าเงินกำลังรอไฟล์ตอบกลับ ทำรายการให้เสร็จเมื่อได้รับคืนมา';

  @override
  String get deskSendFinalize => 'ทำให้เสร็จ';

  @override
  String get deskSendNewSend => 'ส่งใหม่';

  @override
  String get deskSendNodeNotSynced => 'โหนดยังไม่ซิงก์';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'ส่งได้เมื่อโหนดซิงก์เสร็จ ตอนนี้ $percent% กรอกฟอร์มไว้ก่อนได้';
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
  String get deskSendTorStartingText =>
      'การส่งจะรอจนกว่า Tor จะเชื่อมต่อ ระหว่างนี้ไม่มีอะไรผ่านอินเทอร์เน็ตปกติ';

  @override
  String get deskSendEpicboxOff => 'Epicbox ไม่ได้เชื่อมต่อ';

  @override
  String get deskSendEpicboxOffText =>
      'การส่งผ่าน Epicbox ใช้ได้เมื่อเปิดการรับผ่าน Epicbox ระหว่างนี้ส่งด้วยไฟล์ได้';

  @override
  String get deskSendEpicboxTurnOn => 'เปิดการรับผ่าน Epicbox';

  @override
  String get deskSendDoneViaDirect => 'ทำรายการเสร็จและส่งเข้าเครือข่ายแล้ว';

  @override
  String get deskSendDoneViaEpicbox =>
      'ส่งให้ Epicbox แล้ว จะสำเร็จเมื่อผู้รับตอบกลับ';

  @override
  String get deskSendViewTx => 'ดูธุรกรรม';

  @override
  String get deskSendFailedTitle => 'ส่งไม่สำเร็จ';

  @override
  String get deskSendReviewAgain => 'ตรวจสอบอีกครั้ง';

  @override
  String get deskSendMethodDirect => 'ลิงก์';

  @override
  String get deskSendMethodFile => 'ไฟล์';

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
  String get deskSendNeedsTor => 'ต้องใช้ Tor';

  @override
  String get deskSendNeedsTorText =>
      'ที่อยู่ onion เข้าถึงได้ผ่าน Tor เท่านั้น';

  @override
  String get deskSendNoTorBuild => 'รุ่นนี้ไม่มี Tor';

  @override
  String get deskSendTurnOnTor => 'เปิด Tor';

  @override
  String get deskSendHttpClearnet =>
      'การส่งผ่านลิงก์ไปที่อยู่ http(s) ผ่านอินเทอร์เน็ตปกติ ไม่ผ่าน Tor';

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
  String get deskSendAllButton => 'ทั้งหมด';

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
  String get deskSendHintSent =>
      'ส่งแล้ว ใส่จำนวนและผู้รับใหม่เพื่อส่งอีกครั้ง';

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
  String get deskSendReview => 'ตรวจสอบการส่ง';

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
      'ที่อยู่ http(s) หรือ .onion โดย onion จะผ่าน Tor กระเป๋าเงินของผู้รับต้องเปิดอยู่';

  @override
  String get deskSendFileLine1 => 'ไม่ต้องเชื่อมต่อ';

  @override
  String get deskSendFileLine2 =>
      'ส่งไฟล์ให้ผู้รับ รับไฟล์ตอบกลับคืนมา แล้วทำรายการให้เสร็จที่นี่';

  @override
  String get deskSendTagDirect => 'ลิงก์';

  @override
  String get deskSendTagFile => 'ไฟล์';

  @override
  String get deskSendTagEpicbox => 'ผ่าน Epicbox';

  @override
  String get deskSendSwitchedDirect =>
      'ที่อยู่ลิงก์ ตั้งวิธีส่งเป็น ลิงก์ แล้ว';

  @override
  String get deskSendSwitchedFile => 'ที่อยู่แบบไฟล์ ตั้งวิธีส่งเป็น ไฟล์ แล้ว';

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
      'จ่ายผ่านลิงก์ · HTTP (กระเป๋าเงินของผู้รับต้องเปิดอยู่)';

  @override
  String get deskSendViaTor =>
      'จ่ายผ่านลิงก์ · Tor (กระเป๋าเงินของผู้รับต้องเปิดอยู่)';

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
  String get deskFinPosted => 'ส่งธุรกรรมเข้าเครือข่ายแล้ว';

  @override
  String get deskFinTitle => 'ทำรายการให้เสร็จด้วยไฟล์ตอบกลับ';

  @override
  String get deskFinNoticeTitle => 'สำหรับธุรกรรมที่สร้างเป็นไฟล์';

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
      'ไฟล์นี้ไม่ใช่ไฟล์ธุรกรรม เลือกไฟล์ .slate หรือ .tx ที่ผู้ส่งให้มา';

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
  String get deskActSearchHint => 'ที่อยู่หรือ slate ID';

  @override
  String get deskActSearchHintEmpty => 'ยังไม่มีอะไรให้ค้นหา';

  @override
  String get deskActSearchLabel => 'ค้นหาธุรกรรม';

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
  String get deskActDetailReceived => 'ธุรกรรมรับเข้า';

  @override
  String get deskActDetailSent => 'ธุรกรรมส่งออก';

  @override
  String get deskActLoading => 'กำลังโหลดธุรกรรม';

  @override
  String get deskActWaitingNode => 'รอให้โหนดซิงก์เสร็จ';

  @override
  String get deskActFilterAll => 'ทั้งหมด';

  @override
  String get deskActFilterReceived => 'รับ';

  @override
  String get deskActFilterSent => 'ส่ง';

  @override
  String get deskActNoMatchTitle => 'ไม่มีธุรกรรมที่ตรงกัน';

  @override
  String get deskActNoMatchText =>
      'ลองที่อยู่หรือ slate ID อื่น หรือล้างตัวกรอง';

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
  String get deskActEmptyTitle => 'ยังไม่มีธุรกรรม';

  @override
  String get deskActEmptyText =>
      'ทุกรายการที่ส่งหรือรับจะแสดงที่นี่ ใหม่สุดก่อน พร้อมคู่ธุรกรรมและความคืบหน้า';

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
  String get deskConIdle =>
      'เลือกผู้ติดต่อเพื่อดูรายละเอียด ส่งเงิน แก้ไข หรือลบ';

  @override
  String get deskConEmptyTitle => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get deskConEmptyText =>
      'บันทึกคนและร้านค้าที่จ่ายบ่อย ที่หน้า ส่ง เลือกชื่อแทนการวางที่อยู่';

  @override
  String get deskConEmptyLocal =>
      'ผู้ติดต่ออยู่บนคอมพิวเตอร์นี้ ไม่ได้รวมอยู่ในวลีกู้คืน';

  @override
  String get deskConSendToAddress => 'ส่งไปยังที่อยู่';

  @override
  String deskConLastTx(String when) {
    return 'ธุรกรรมล่าสุด: $when';
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
  String get deskConAddrEpicbox => 'ที่อยู่ Epicbox';

  @override
  String get deskConAddrTor => 'ลิงก์ · ที่อยู่ Tor';

  @override
  String get deskConAddrHttp => 'ลิงก์ · ที่อยู่ HTTP';

  @override
  String get deskConNote => 'บันทึก';

  @override
  String deskConTxWith(String name) {
    return 'ธุรกรรมกับ $name';
  }

  @override
  String get deskConAllTx => 'ธุรกรรมทั้งหมด';

  @override
  String get deskConTxNone =>
      'ยังไม่มีธุรกรรมกับผู้ติดต่อนี้ รายการที่ส่งจากหน้า ส่ง จะแสดงที่นี่';

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
      'ที่อยู่ไม่ถูกต้อง ใช้ที่อยู่ Epicbox (es5x…@epicbox.epiccash.com) ที่อยู่ลิงก์ (https://…) หรือที่อยู่ onion (….onion)';

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
      'ที่อยู่และบันทึกของผู้ติดต่อจะถูกลบออกจากกระเป๋าเงินนี้ ธุรกรรมที่ผ่านมายังอยู่ในประวัติ ย้อนกลับไม่ได้';

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
      'เอาต์พุตคือชิ้นส่วนที่ประกอบเป็นยอดคงเหลือ การส่งจะใช้เอาต์พุตทั้งก้อน จ่ายให้ผู้รับ และคืนส่วนที่เหลือเป็นเอาต์พุตใหม่ เอาต์พุตที่ใช้ไปจะถูกล็อกจนกว่าการส่งจะได้รับการยืนยัน';

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
  String get deskOutCardWait =>
      'รอจนกว่าการส่งจะได้รับการยืนยัน (ประมาณ 3 บล็อก)';

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
  String get deskOutNoneText =>
      'รายการแรกที่ได้รับจะสร้างเอาต์พุตขึ้น การแยกและรวมต้องมีเอาต์พุตก่อน';

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
  String deskOutSplitDialogText(String spent, String made) {
    return 'ใช้ $spent และสร้าง $made เป็นธุรกรรมปกติบนเครือข่ายถึงกระเป๋าเงินนี้ ได้รับการยืนยันหลัง 3 บล็อกเหมือนการส่งทั่วไป ทุกอย่างที่ใช้ได้จะถูกล็อกจนถึงตอนนั้น';
  }

  @override
  String deskOutConsDialogText(String spent, String made) {
    return 'ใช้ $spent และสร้าง $made เป็นธุรกรรมปกติบนเครือข่ายถึงกระเป๋าเงินนี้ ได้รับการยืนยันหลัง 3 บล็อกเหมือนการส่งทั่วไป ทุกอย่างที่ใช้ได้จะถูกล็อกจนถึงตอนนั้น การส่งครั้งถัดไปใช้เอาต์พุตเดียว ค่าธรรมเนียมจึงต่ำที่สุด';
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
  String deskOutFactLockedValue(String amount) {
    return '$amount EPIC ประมาณ 3 บล็อก ไม่มีส่วนไหนใช้ได้ระหว่างนั้น';
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
  String deskOutSplitDoneText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ตอนนี้กระเป๋าเงินมี $count เอาต์พุต ก้อนละประมาณ $amount EPIC กำลังยืนยัน ทุกอย่างถูกล็อกจนกว่าจะได้รับการยืนยัน (3 บล็อก) ประวัติแสดงสองรายการ: การส่งและการรับ ทั้งคู่ถึงกระเป๋าเงินนี้',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount) {
    return 'เอาต์พุตเดียว $amount EPIC กำลังยืนยัน ทุกอย่างถูกล็อกจนกว่าจะได้รับการยืนยัน (3 บล็อก) ประวัติแสดงสองรายการ: การส่งและการรับ ทั้งคู่ถึงกระเป๋าเงินนี้';
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
    return 'ไม่มีอะไรให้รวม: กระเป๋าเงินมี$what การรวมจะผสานหลายเอาต์พุตเป็นก้อนเดียว';
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
  String get deskOvNodeAddrText =>
      'ตอนนี้ใช้ node.epiccash.com แทน node.epiccash.com:3413';

  @override
  String get deskOvNodeIncompatTitle =>
      'เวอร์ชันของโหนดนี้ใช้กับกระเป๋าเงินนี้ไม่ได้';

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
  String deskOvSyncText(String block) {
    return 'กำลังดาวน์โหลดบล็อก ยอดเงินเป็นค่าที่กระเป๋าเงินรู้ ณ บล็อก $block การส่งจะเปิดเมื่อโหนดตามทันแล้ว';
  }

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
  String get deskOvSendWaits => 'การส่งจะเปิดเมื่อโหนดซิงก์แล้ว';

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
  String get deskOvBreakAwaiting => 'รอทำรายการให้เสร็จ';

  @override
  String get deskOvBreakLocked => 'ล็อกในการส่ง';

  @override
  String get deskOvUpdating => 'กำลังอัปเดต';

  @override
  String get deskOvHiddenAmount => 'จำนวนที่ซ่อนไว้';

  @override
  String get deskOvLoading => 'กำลังโหลดธุรกรรม';

  @override
  String get deskOvEmptyTitle => 'ยังไม่มีธุรกรรม';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'EPIC ที่ได้รับจะแสดงที่นี่เป็นกำลังยืนยันก่อน แล้วจึงใช้ได้หลัง $blocks บล็อก',
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
      other: 'มีการส่งด้วยไฟล์ค้างอยู่ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => 'ทำรายการให้เสร็จด้วยไฟล์ตอบกลับจากผู้รับ';

  @override
  String get deskOvFinalize => 'ทำให้เสร็จ';

  @override
  String get deskTxMethodFile => 'ไฟล์';

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
  String get deskTxFoundRescanLabel => 'พบจากการสแกน';

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
  String get deskTxBackupTip => 'เพิ่มจากข้อมูลสำรองประวัติ';

  @override
  String get deskTxFromBackup => 'จากข้อมูลสำรอง';

  @override
  String get deskTxStatusImmature => 'รอครบกำหนด';

  @override
  String get deskTxStatusWaitingSender => 'รอผู้ส่งทำรายการให้เสร็จ';

  @override
  String get deskTxStatusWaitingResponseFile => 'รอไฟล์ตอบกลับ';

  @override
  String get deskTxStatusWaitingRecipient => 'รอผู้รับลงนาม';

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
  String get deskTxNowBackup => 'จากข้อมูลสำรอง ไม่ได้ตรวจกับบล็อกเชน';

  @override
  String deskTxNowImmature(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ยืนยันแล้ว แต่รางวัลการขุดใช้ได้หลังยืนยันครบ $count ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'ลงนามและส่งคืนแล้ว รอผู้ส่งทำรายการให้เสร็จ';

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
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'ยืนยันแล้ว $confirmations ครั้ง',
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
  String get deskTxHeadBackup => 'เพิ่มจากข้อมูลสำรองประวัติ';

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
  String get deskTxStepSpendable => 'ใช้ได้';

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
  String get deskTxStepReceivedSlate => 'ได้รับ slate';

  @override
  String get deskTxStepCreated => 'สร้างและลงนามแล้ว';

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
  String get deskTxCancelOutgoingTitle => 'ยกเลิกการส่งนี้ไหม?';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '$amount EPIC จาก $who จะออกจากยอดคงเหลือ กระเป๋าเงินจะถามโหนดก่อน และไม่ยกเลิกถ้ารายการอยู่ใน pool ของโหนดหรืออยู่ในบล็อกแล้ว ถ้าผู้ส่งส่งเข้าเครือข่ายภายหลัง เงินอาจยังเข้า';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC ถึง $who ยอดที่ถูกล็อกจะกลับเข้ายอดคงเหลือ ถ้าผู้รับทำรายการเสร็จไปแล้ว รายการอาจยังได้รับการยืนยัน';
  }

  @override
  String get deskTxCancelKeep => 'เก็บไว้';

  @override
  String get deskTxCancelIncomingAction => 'ยกเลิกรายการ';

  @override
  String get deskTxCancelOutgoingAction => 'ยกเลิกการส่ง';

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
  String get deskOnbWelcomeRestoreSub => 'จากคำในวลีกู้คืน';

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
  String get deskOnbWelcomeNetworkHelp =>
      'Mainnet มี EPIC จริง Floonet และ Usernet เป็นเครือข่ายทดสอบ';

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
  String get deskOnbCreateStageCreate => 'กำลังสร้างกระเป๋าเงินและวลีกู้คืน';

  @override
  String get deskOnbCreateStageSave => 'กำลังบันทึกบัญชี';

  @override
  String get deskOnbCreateNotCreated => 'ไม่ได้สร้างกระเป๋าเงิน';

  @override
  String get deskOnbCreateCreating => 'กำลังสร้างกระเป๋าเงิน';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'กระเป๋าเงินบน $network ซึ่งเป็นเครือข่ายทดสอบ';
  }

  @override
  String get deskOnbCreateFailedTitle => 'สร้างกระเป๋าเงินไม่ได้';

  @override
  String get deskOnbCreateDiskFull => 'บันทึกบัญชีไม่ได้: ดิสก์เต็ม';

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
      'รหัสผ่านใช้ปลดล็อกกระเป๋าเงินนี้บนคอมพิวเตอร์นี้ แต่กู้เหรียญคืนไม่ได้ วลีในขั้นตอนถัดไปทำได้';

  @override
  String get deskOnbCreateTestNote =>
      'กระเป๋าเงินบนเครือข่ายทดสอบ ไม่ใช่สำหรับ EPIC จริง';

  @override
  String get deskOnbCreatePhraseLead =>
      'คำเหล่านี้เป็นทางเดียวที่จะได้เหรียญคืนถ้าคอมพิวเตอร์นี้เสีย จดลงกระดาษตามลำดับ';

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
  String get deskOnbCreateShowQr => 'แสดง QR Code';

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
    return 'จดลงกระดาษครบ $_temp0 แล้ว';
  }

  @override
  String get deskOnbRestoreDone => 'กู้คืนกระเป๋าเงินแล้ว';

  @override
  String get deskOnbRestoreNotRestored => 'ไม่ได้กู้คืนกระเป๋าเงิน';

  @override
  String get deskOnbRestoreRestoring => 'กำลังกู้คืนกระเป๋าเงิน';

  @override
  String get deskOnbRestoreFailedTitle => 'กู้คืนกระเป๋าเงินไม่ได้';

  @override
  String get deskOnbRestorePermission =>
      'เขียนไฟล์กระเป๋าเงินไม่ได้: ไม่มีสิทธิ์ใน ~/.config/Epic Cash Desktop';

  @override
  String get deskOnbRestoreWait =>
      'อาจใช้เวลาถึงหนึ่งนาที ยอดคงเหลือจะแสดงหลังสแกนบล็อกเชนครั้งแรก';

  @override
  String get deskOnbRestoreSide => 'กู้คืนกระเป๋าเงิน';

  @override
  String get deskOnbRestoreChoosePassword => 'ตั้งรหัสผ่าน';

  @override
  String deskOnbRestorePasswordLead(int count) {
    return 'วลี $count คำถูกต้อง ตั้งรหัสผ่านที่ใช้ปลดล็อกกระเป๋าเงินนี้บนคอมพิวเตอร์นี้ กระเป๋าเงินจะเปิดเมื่อกู้คืนเสร็จ';
  }

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
      'พิมพ์คำตามลำดับ หรือวางทั้งวลีลงช่องไหนก็ได้ การขึ้นบรรทัด จุลภาค และเลขลำดับจะถูกข้าม';

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
      'การปิดจะหยุดงานที่ทำอยู่ เช่น การซิงก์โหนดหรือการรับเงิน จะเริ่มใหม่จากแอปนี้หลังปลดล็อก';

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
      'เปิดกระเป๋าเงิน จะถามรหัสผ่านของกระเป๋าเงินนั้น ยกเลิก จะเก็บวลีไว้ในตาราง';

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
  String get deskOnbUnlockPortInUse =>
      'บริการกระเป๋าเงินไม่เริ่มทำงาน: พอร์ต 3415 ถูกโปรแกรมอื่นใช้อยู่';

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
  String get deskOnbUnlockFailedLead => 'กระเป๋าเงินไม่เปิด สาเหตุอยู่ด้านล่าง';

  @override
  String get deskOnbUnlockFailedBox => 'กระเป๋าเงินไม่เปิด';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'กำลังปลดล็อก $name';
  }

  @override
  String get deskOnbUnlockStepsLead => 'แต่ละขั้นตอนจะแสดงเมื่อเสร็จ';

  @override
  String get deskOnbUnlockNote =>
      'จากนั้นหน้าภาพรวมจะเปิดและทำงานที่เหลือเบื้องหลัง: เชื่อมต่อโหนด อัปเดตยอดเงิน และเปิดการรับเงิน';

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
    return 'ที่นี่ว่าง $size';
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
  String get deskOnbNodeSeparateText =>
      'กระเป๋าเงินเริ่มโหนด Epic และหยุดพร้อมกับแอป';

  @override
  String get deskOnbNodeFirewall => 'Windows จะถามครั้งเดียว';

  @override
  String get deskOnbNodeFirewallText =>
      'ว่าจะอนุญาตผ่านไฟร์วอลล์ไหม อนุญาตสำหรับเครือข่ายส่วนตัว';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'และเพิ่มขึ้นช้า ๆ $free';
  }

  @override
  String get deskOnbNodeHours => 'ซิงก์หลายชั่วโมง';

  @override
  String get deskOnbNodeHoursText =>
      'ในครั้งแรก 2 ถึง 6 ชั่วโมงกับอินเทอร์เน็ตทั่วไป กระเป๋าเงินแสดงความคืบหน้าและใช้โหนดสาธารณะระหว่างนั้นได้';

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
      'โหนดของ Epic GUI หรือ CLI กระเป๋าเงินเชื่อมต่อเข้าไปโดยไม่เริ่มอะไรเอง';

  @override
  String get deskOnbNodeAddress => 'ที่อยู่ของโหนดบนคอมพิวเตอร์นี้';

  @override
  String get deskOnbNodeCheck => 'ตรวจ';

  @override
  String get deskOnbNodeBundled => 'เริ่มโหนดที่มากับแอป';

  @override
  String get deskOnbNodeBundledText =>
      'ดาวน์โหลดและซิงก์บล็อกเชนลงในโฟลเดอร์ของกระเป๋าเงินเอง ไม่มีการดาวน์โหลดก่อนกด บันทึก ในขั้นตอนสุดท้าย';

  @override
  String deskOnbNodeFallback(String host) {
    return 'ใช้ $host จนกว่าโหนดในเครื่องจะซิงก์เสร็จ แล้วโหนดในเครื่องจะทำงานแทนเอง';
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
      'กำลังค้นหาโฟลเดอร์ของ Epic Wallet รุ่นเก่าและโปรแกรม epic ไม่มีอะไรถูกเปลี่ยน';

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
  String get deskOnbImportCheckTitle => 'กำลังตรวจการใช้งาน';

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
  String get deskOnbImportOlderSub => 'บัญชีและโฟลเดอร์';

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
  String get deskRailOpenHttp => 'เปิดการรับ: จ่ายผ่านลิงก์ · HTTP';

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
  String get deskAppFirstScanTitle => 'การสแกนครั้งแรกของกระเป๋าเงิน';

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
      'หัวข้อแยกตามหมวดและรายงานปัญหา คำอธิบายเพิ่มเติมของทุกหน้าอยู่ที่นี่ และแสดงทัวร์นี้ซ้ำได้';

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
      'จ่ายผ่านลิงก์ · HTTP: รายการไปตรงถึงกระเป๋าเงินของผู้รับ ซึ่งต้องเปิดอยู่';

  @override
  String get deskKitHeroLabelTor =>
      'จ่ายผ่านลิงก์ · Tor: รายการไปตรงถึงกระเป๋าเงินของผู้รับ ผ่านเครือข่าย Tor';

  @override
  String get deskKitHeroLabelFile =>
      'ไฟล์: ส่งไฟล์ธุรกรรมไป ได้ไฟล์ตอบกลับมา แล้วผู้ส่งทำรายการให้เสร็จ';

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
  String get deskKitLimitedNetwork =>
      'เข้าถึง status.btlabs.uk ไม่ได้ ข้อมูลนี้มาจากตัวโหนดเอง: ไม่มีบล็อกล่าสุดให้เทียบ ไม่มี uptime และไม่มีจำนวน peer';

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
  String deskKitSourceChecked(String time) {
    return 'status.btlabs.uk ตรวจเมื่อ $time';
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
  String get deskKitFromStatusSite => 'จาก status.btlabs.uk';

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
  String deskKitMethodTorNotConnected(String host) {
    return '$host Tor ไม่ได้เชื่อมต่อ';
  }

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
  String get deskKitMethodFiles => 'ไฟล์';

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
  String get deskKitQrHideCode => 'ซ่อน QR Code';

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
  String get deskSetAcctShowPhrase => 'แสดงวลี…';

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
  String get deskSetBackupGroup => 'ข้อมูลสำรอง';

  @override
  String get deskSetBackupExportTitle => 'ส่งออกข้อมูลสำรองประวัติ';

  @override
  String get deskSetBackupExportHint =>
      'รายการพร้อมรายละเอียดและผู้ติดต่อ ในไฟล์ที่เปิดได้เฉพาะกระเป๋าเงินที่มีวลีกู้คืนนี้ วลีอย่างเดียวได้คืนแค่ยอดคงเหลือ ไม่ได้คืนบันทึกรายการ';

  @override
  String get deskSetBackupExporting => 'กำลังส่งออก…';

  @override
  String get deskSetBackupExportButton => 'ส่งออก…';

  @override
  String get deskSetBackupImportTitle => 'นำเข้าข้อมูลสำรองประวัติ';

  @override
  String get deskSetBackupImportHint =>
      'รวมข้อมูลสำรองของกระเป๋าเงินนี้เข้ากับประวัติ ไม่มีอะไรถูกลบ และนำเข้าไฟล์เดิมซ้ำก็ไม่เปลี่ยนอะไร';

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
  String get deskSetBackupSaveDialogTitle => 'บันทึกประวัติรายการ';

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
      'ใครจ่ายอะไร ค่าธรรมเนียม บันทึก slate ID';

  @override
  String get deskSetBackupNotIn => 'ไม่มีในไฟล์';

  @override
  String get deskSetBackupNotInValue => 'คีย์ วลีกู้คืน รหัสผ่าน';

  @override
  String get deskSetBackupOpensWith => 'เปิดได้ด้วย';

  @override
  String get deskSetBackupOpensWithValue =>
      'กระเป๋าเงินนี้ หรือที่กู้คืนจากวลีเดียวกัน';

  @override
  String get deskSetBackupFile => 'ไฟล์';

  @override
  String get deskSetBackupFileNote =>
      'ไฟล์เก็บรายการถึงปัจจุบัน ส่งออกใหม่หลังมีรายการใหม่';

  @override
  String get deskSetBackupExportDesc =>
      'ไฟล์ที่มีรายการของกระเป๋าเงินนี้ พร้อมรายละเอียดและผู้ติดต่อ เปิดได้เฉพาะกระเป๋าเงินที่มีวลีกู้คืนเดียวกัน';

  @override
  String get deskSetBackupSaved => 'บันทึกแล้ว';

  @override
  String get deskSetBackupKeepCopy =>
      'เก็บสำเนาไว้นอกคอมพิวเตอร์นี้ด้วย เช่น USB ไดรฟ์อื่น หรือคลาวด์ ส่งออกใหม่หลังมีรายการใหม่';

  @override
  String get deskSetBackupOpenFolder => 'เปิดโฟลเดอร์';

  @override
  String get deskSetBackupSaving => 'กำลังบันทึก…';

  @override
  String get deskSetBackupTryAgain => 'ลองอีกครั้ง';

  @override
  String get deskSetBackupSaveAs => 'บันทึกเป็น…';

  @override
  String get deskSetBackupOpenDialogTitle => 'เปิดข้อมูลสำรองประวัติ';

  @override
  String get deskSetBackupDetailsRestored => 'กู้รายละเอียดคืนแล้ว';

  @override
  String get deskSetBackupDetailsRestoredSub =>
      'รายการที่มีอยู่แล้วได้คู่ธุรกรรม ค่าธรรมเนียม หรือบันทึกคืน';

  @override
  String get deskSetBackupOlderAdded => 'เพิ่มรายการเก่าแล้ว';

  @override
  String get deskSetBackupOlderAddedSub =>
      'ไม่อยู่ในรายการแล้ว แสดงเป็น จากข้อมูลสำรอง';

  @override
  String get deskSetBackupContactsAdded => 'เพิ่มผู้ติดต่อแล้ว';

  @override
  String get deskSetBackupAlreadyHere => 'มีอยู่แล้ว';

  @override
  String get deskSetBackupUnchanged => 'ไม่เปลี่ยนแปลง';

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
      'ใครจ่ายอะไร ค่าธรรมเนียมและบันทึกของรายการที่มีอยู่ รายการเก่าที่หายไปจากรายการ และผู้ติดต่อ';

  @override
  String get deskSetBackupNeeds => 'ต้องใช้';

  @override
  String deskSetBackupNeedsValue(String network) {
    return 'ไฟล์จากกระเป๋าเงินนี้ (วลีกู้คืนเดียวกัน) บน $network';
  }

  @override
  String get deskSetBackupNever => 'ไม่มีวัน';

  @override
  String get deskSetBackupNeverValue => 'ลบหรือแก้ไขรายการที่มีอยู่';

  @override
  String get deskSetBackupChooseFile => 'เลือกไฟล์…';

  @override
  String get deskSetBackupImportDesc =>
      'รวมข้อมูลสำรองประวัติของกระเป๋าเงินนี้เข้ากับประวัติ ไม่มีอะไรถูกลบ และนำเข้าไฟล์เดิมซ้ำก็ไม่เปลี่ยนอะไร';

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
  String get deskSetBackupRangeAll => 'ทั้งหมด';

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
      'ใครมีไฟล์ก็อ่านจำนวน วันที่ ที่อยู่ และบันทึกได้ และนำเข้ากลับไม่ได้ ถ้าจะนำเข้าให้ใช้ข้อมูลสำรองประวัติ';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการยังไม่อยู่ในข้อมูลสำรองประวัติ',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count รายการเป็นรายการใหม่หรือเปลี่ยนไปหลังสำรองประวัติครั้งล่าสุด',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'การกู้คืนจากวลีกู้คืนได้คืนยอดคงเหลือ แต่ไม่ได้คืนว่าใครจ่ายอะไร';

  @override
  String get deskSetBackupNotNow => 'ไว้ทีหลัง';

  @override
  String get deskSetDlgChainTitle => 'พบข้อมูลบล็อกเชนที่มีอยู่';

  @override
  String get deskSetDlgChainDesc =>
      'คอมพิวเตอร์นี้มีข้อมูลบล็อกเชน Epic ที่โหนดในเครื่องใช้ได้อยู่แล้ว';

  @override
  String get deskSetDlgChainFolder => 'โฟลเดอร์';

  @override
  String get deskSetDlgChainSize => 'ขนาด';

  @override
  String get deskSetDlgChainUpdated => 'อัปเดตล่าสุด';

  @override
  String get deskSetDlgChainUpdatedValue => '3 วันที่แล้ว';

  @override
  String get deskSetDlgChainOthers => 'พบสำเนาอื่นด้วย (1) ชุดนี้อัปเดตล่าสุด';

  @override
  String get deskSetDlgChainInUse =>
      'โปรแกรม Epic อื่นกำลังใช้โฟลเดอร์นี้ ปิดโปรแกรมนั้น แล้วเลือกโหนดในเครื่องอีกครั้งเพื่อใช้ข้อมูลนี้';

  @override
  String get deskSetDlgChainUseIt =>
      'ใช้ข้อมูลนี้ไหม? ไม่ต้องดาวน์โหลดและซิงก์บล็อกเชนทั้งหมด';

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
      'ตั้งแต่นี้รหัสผ่านใหม่จะใช้ปลดล็อกกระเป๋าเงินนี้ รหัสผ่านที่จำไว้จะถูกลืม';

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
  String get deskSetDlgRemoveDesc => 'ไม่มีอะไรเปลี่ยนจนกว่าจะยืนยัน';

  @override
  String get deskSetDlgRemoveWhat => 'สิ่งที่จะนำออก';

  @override
  String get deskSetDlgRemoveFromList => 'นำออกจากรายการ';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'ไฟล์ยังอยู่ใน $folder เพิ่มกลับได้ที่ กระเป๋าเงินทั้งหมด';
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
    return 'ใช้ $host จนกว่าโหนดในเครื่องจะซิงก์เสร็จ แล้วโหนดในเครื่องจะทำงานแทนเอง';
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
  String get deskSetLnodeNoProgressText =>
      'การเริ่มใหม่มักช่วยได้ ถ้าไม่ได้ บันทึกจะบอกสาเหตุ';

  @override
  String get deskSetLnodePortInUse => 'พอร์ต 3413 ถูกโปรแกรมอื่นใช้อยู่';

  @override
  String get deskSetLnodePortInUseText =>
      'ปิดโปรแกรมนั้น (โหนด Epic อีกตัว?) หรือเลือกโหนดที่ทำงานอยู่ที่นั่นใน เซิร์ฟเวอร์โหนด';

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
    return 'การซิงก์ใช้เวลาหลายชั่วโมง ระหว่างนี้กระเป๋าเงินอ่านบล็อกเชนและส่งผ่าน $host ซึ่งเป็นโหนดสาธารณะได้ เมื่อโหนดในเครื่องซิงก์เสร็จจะทำงานแทนเอง';
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
    return 'ลบ $size ออกจาก $path โหนดจะหยุด และบล็อกเชนทั้งหมดจะดาวน์โหลดใหม่เมื่อเริ่มครั้งถัดไป (หลายชั่วโมง) คีย์และประวัติของกระเป๋าเงินไม่ได้รับผลกระทบ';
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
  String get deskSetLndReuseTitle => 'พบข้อมูลบล็อกเชนบนคอมพิวเตอร์นี้';

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
  String get deskSetPeersNotAddress =>
      'ไม่ใช่ IP address และพอร์ต เช่น 203.0.113.5:3414';

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
  String get deskSetPeersRefreshed => 'รีเฟรชทุก 10 วินาที';

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
    return 'พบครั้งแรก คือเวลาที่แอปนี้เห็น peer เชื่อมต่อครั้งแรกในรอบนี้ โหนดไม่ได้บอกว่าการเชื่อมต่อเริ่มเมื่อไร การแบนและยกเลิกแบนใช้ owner API ของโหนด Enter บันทึกค่าสูงสุด ($min ถึง $max ค่าเริ่มต้น $def)';
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
  String get deskSetNodePortNote => 'ตรวจที่อยู่และพอร์ต (ปกติคือ 3413)';

  @override
  String get deskSetNodeListNote =>
      'สถานะจาก status.btlabs.uk ตรวจทุกไม่กี่นาที เวลาตอบสนองวัดจากคอมพิวเตอร์นี้';

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
  String get deskSetPhraseShowWords => 'แสดงคำ';

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
  String get deskSetPhraseHideQr => 'ซ่อน QR Code';

  @override
  String get deskSetPhraseShowQr => 'แสดง QR Code';

  @override
  String get deskSetPhraseHideWords => 'ซ่อนคำ';

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
  String deskSetPrivStartingDetail(int progress, String waiting) {
    return '$progress % $waiting รอจนกว่า Tor จะพร้อม';
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
  String deskSetPrivStoppedDetail(String waiting) {
    return 'Tor หยุดแล้ว $waiting รอ ลองอีกครั้ง หรือปิด Tor';
  }

  @override
  String deskSetPrivProblemDetail(String problem, String waiting) {
    return '$problem $waiting รอ ลองอีกครั้ง หรือปิด Tor';
  }

  @override
  String get deskSetPrivStatusSite => 'เว็บสถานะ';

  @override
  String get deskSetPrivUseStatus => 'ใช้ status.btlabs.uk';

  @override
  String get deskSetPrivUseStatusHint =>
      'สถานะเครือข่ายและข้อมูลจาก status.btlabs.uk';

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
  String get deskSetRecvHeadStopped => 'หยุดอยู่';

  @override
  String get deskSetRecvHeadStarting => 'กำลังเริ่ม';

  @override
  String get deskSetRecvEpicboxTitle => 'รับผ่าน Epicbox';

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
  String get deskSetRecvListNote =>
      'สถานะจาก status.btlabs.uk ตรวจทุกไม่กี่นาที';

  @override
  String get deskSetRecvHttpTitle => 'จ่ายผ่านลิงก์ · HTTP: การรับ';

  @override
  String get deskSetRecvHttpText =>
      'ตรงจากกระเป๋าเงินอื่นขณะที่กระเป๋าเงินนี้เปิดอยู่';

  @override
  String get deskSetRecvHttpOffTitle => 'ปิดอยู่ขณะเปิด Tor';

  @override
  String get deskSetRecvHttpOffText =>
      'รายการผ่านลิงก์จะเข้าที่ที่อยู่ Tor ของกระเป๋าเงินนี้แทน';

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
    return 'ตอบทุก interface เราเตอร์ต้อง forward TCP $port มายังคอมพิวเตอร์นี้ ผู้ส่งบนอินเทอร์เน็ตใช้ http://<public IP>:$port';
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
    return 'กระเป๋าเงินจะตอบที่ 0.0.0.0 พอร์ต $port อุปกรณ์อื่นและอินเทอร์เน็ตจึงส่งเงินมาที่กระเป๋าเงินนี้ได้ ไฟร์วอลล์อาจถามว่าจะอนุญาตไหม';
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
      'รายงานถูกเข้ารหัสให้นักพัฒนาอ่านได้เท่านั้น ไม่มีอะไรถูกส่งก่อนกด ส่ง ส่วน บันทึกเป็นไฟล์ เก็บรายงานเดียวกันที่ลบข้อมูลลับแล้ว แต่ไม่ได้เข้ารหัส';

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
  String get deskSetRescanLog => 'บันทึกการสแกน';

  @override
  String get deskSetRescanText =>
      'อ่านบล็อกเชนอีกครั้งและคำนวณยอดคงเหลือใหม่จากเอาต์พุตที่พบ ใช้เมื่อยอดดูไม่ถูกต้อง หลังกู้คืน หรือเมื่อเอาต์พุตยังถูกล็อกหลังส่งไม่สำเร็จ ระหว่างนี้ยังใช้กระเป๋าเงินได้';

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
  String get deskSetRescanFinished => 'สแกนเสร็จแล้ว';

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
  String get deskSetWalletsImport => 'นำเข้า';

  @override
  String get deskSetWalletsImportText => 'จาก Epic Wallet รุ่นเก่าหรือโฟลเดอร์';

  @override
  String get deskSetWalletsRestore => 'กู้คืน';

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
  String get deskSetupPrefsLead => 'ภาษาของแอป เปลี่ยนได้ภายหลัง';

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
  String get deskSetupLaterNote =>
      'ทุกอย่างที่นี่เปลี่ยนได้ภายหลังในการตั้งค่า';

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
      'รันโหนด Epic บนคอมพิวเตอร์นี้ ไม่มีข้อมูลแชร์กับผู้ดูแลโหนด ต้องใช้พื้นที่ดิสก์และซิงก์หลายชั่วโมง';

  @override
  String get deskSetupEpicboxText =>
      'Epicbox ส่งรายการไปยังที่อยู่ Epicbox และเก็บไว้จนกว่ากระเป๋าเงินจะออนไลน์';

  @override
  String get deskSetupEpicboxPrivacy =>
      'Epicbox ไม่ได้ซ่อนที่อยู่ IP จากเซิร์ฟเวอร์ Epicbox ใช้ VPN ถ้าเรื่องนี้สำคัญ';

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
    return 'บันทึก จะเริ่มโหนด การซิงก์ครั้งแรกใช้เวลาหลายชั่วโมง ระหว่างนั้นกระเป๋าเงินจะเปิดและใช้ $node';
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
      'ซอฟต์แวร์โอเพนซอร์สในกระเป๋าเงินนี้ แต่ละส่วนใช้สัญญาอนุญาตของตัวเอง ข้อความเต็มอยู่ห่างไปแค่คลิกเดียว';

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
  String get deskSetAboutCheckNow => 'ตรวจตอนนี้';

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
      'อธิบายสิ่งที่ผิดพลาด แนบบันทึกของแอปไปด้วยได้ โดยลบข้อมูลลับออกและเข้ารหัสให้นักพัฒนา บันทึกเป็นไฟล์ เก็บสำเนาไว้ส่งเอง';

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
  String get deskSetHelpFile => 'ไฟล์';

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
      'การชำระเงินนี้ยังไปไม่ถึง epicbox ผู้รับจึงยังไม่ได้รับ เงินของคุณจะถูกล็อกไว้จนกว่าจะส่งอีกครั้งหรือยกเลิก';

  @override
  String get txDetailsSendAgainDone =>
      'ส่งอีกครั้งแล้ว การชำระเงินจะเสร็จสมบูรณ์เมื่อกระเป๋าของผู้รับออนไลน์';

  @override
  String get deskTxThisWallet => 'กระเป๋าเงินนี้';

  @override
  String get deskErrOldLinks =>
      'โฟลเดอร์ของกระเป๋าเงินนี้มีลิงก์อยู่ คัดลอกด้วยตนเองหรือกู้คืนจากวลีกู้คืน';

  @override
  String get deskErrOldIncomplete =>
      'อ่านโฟลเดอร์ของกระเป๋าเงินนี้ได้ไม่ครบ คัดลอกด้วยตนเองหรือกู้คืนจากวลีกู้คืน';

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
      'ส่งไม่ถึง รายการนี้ไปไม่ถึง Epicbox ผู้รับจึงยังไม่ได้รับ ส่งอีกครั้ง หรือยกเลิกเพื่อปลดเงินคืน';

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
  String get deskTxDetailsTip =>
      'ใช้ได้เฉพาะรายการที่พบจากการสแกน จะแสดงว่าคุณเพิ่มเองในกิจกรรม รายละเอียด และไฟล์ที่ส่งออก ยอดเงิน วันที่ และการยืนยันจะไม่เปลี่ยน';

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
  String get deskTxDetailsNote => 'บันทึก';

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
          'ข้อมูลสำรองมีรายละเอียดต่างจากที่คุณใส่ไว้ใน $n รายการ จะใช้ของคุณต่อไป เว้นแต่คุณเลือกอย่างอื่น',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'ของฉัน';

  @override
  String get deskHistConflictBackup => 'ข้อมูลสำรอง';

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
      'ทุกอย่างปิดอยู่ตอนแรก แต่ละสวิตช์เพิ่มส่วนของกระเป๋าเงินอีกส่วนหนึ่งในที่ที่มันอยู่';

  @override
  String get advShowsHeader => 'แสดงเพิ่ม';

  @override
  String get advNetworkHeader => 'เครือข่าย';

  @override
  String get advNetworkHint =>
      'วิธีที่กระเป๋าเงินเชื่อมต่อเครือข่าย มาตรฐานเชื่อมต่อตรง เปิด Tor ได้ที่ ความเป็นส่วนตัวและเครือข่าย Tor เท่านั้นไม่เชื่อมต่อตรงเด็ดขาด ถ้าไม่มี Tor กระเป๋าเงินจะออฟไลน์และบอกที่หน้าแรก ออฟไลน์ใช้เฉพาะโทรศัพท์เครื่องนี้และเครือข่ายในพื้นที่ของคุณ ถ้ามีโหนดในเครือข่ายของคุณ ยังส่งไปที่อยู่ในพื้นที่และใช้ไฟล์ได้ นอกนั้นคุณเห็นยอดและประวัติตามที่เห็นล่าสุด';

  @override
  String get advOutputs => 'เอาต์พุต';

  @override
  String get advOutputsHint =>
      'แสดงหน้าเอาต์พุตใต้ กระเป๋าเงิน และที่หน้าแรก แสดงเหรียญที่ประกอบเป็นยอดคงเหลือ ให้คุณแยกหรือรวมเหรียญ และตั้งค่าเริ่มต้นที่การส่งใช้ หากกำลังแยกหรือรวมอยู่ หน้านี้จะแสดงต่อไป';

  @override
  String get advTechnical => 'รายละเอียดทางเทคนิค';

  @override
  String get advTechnicalHint =>
      'แสดงแถวทางเทคนิคในรายละเอียดของรายการ ได้แก่ kernel, slate ID, commitment และความสูงบล็อก ใน ใบแจ้งหนี้ จะแสดงการหมุนเวียนที่อยู่และจำนวนข้อความที่ถูกทิ้ง';

  @override
  String get advSendOptions => 'ตัวเลือกการส่ง';

  @override
  String get advSendOptionsHint =>
      'แสดงวิธีเลือกของการส่งและแยกเงินทอนใน การตั้งค่า › ธุรกรรม คือการส่งใช้เอาต์พุตไหน และแยกเงินทอนหรือไม่ แสดงอยู่ตลอดตราบใดที่ตัวใดตัวหนึ่งไม่ใช่ค่าเริ่มต้น';

  @override
  String get advServerDetails => 'รายละเอียดเซิร์ฟเวอร์';

  @override
  String get advServerDetailsHint =>
      'แสดงโฮสต์ เวลาตอบสนอง เวอร์ชัน และความสูงบล็อกในรายการเซิร์ฟเวอร์และการ์ดสถานะ แสดงที่อยู่รีเลย์ใน รับ และแสดงที่อยู่ใบแจ้งหนี้แบบเต็ม';

  @override
  String get advRecheckHeight => 'ตรวจยอดใหม่จากบล็อกที่กำหนด';

  @override
  String get advRecheckHeightHint =>
      'ให้ ตรวจยอดใหม่ เริ่มจากความสูงบล็อกหรือวันที่แทนการเริ่มจากบล็อกแรก เร็วกว่า และเป็นวิธีเดียวที่ข้ามประวัติช่วงแรกได้ ตอนกู้คืนมีตัวเลือกนี้เสมอ';

  @override
  String get advModeStandard => 'มาตรฐาน';

  @override
  String get advModeStandardLine =>
      'เชื่อมต่อตรง เปิด Tor ได้ที่ ความเป็นส่วนตัวและเครือข่าย';

  @override
  String get advModeTorOnly => 'Tor เท่านั้น';

  @override
  String get advModeTorOnlyLine =>
      'ทุกการเชื่อมต่อผ่าน Tor ถ้าไม่มี Tor กระเป๋าเงินจะออฟไลน์และบอกให้ทราบ';

  @override
  String get advModeOffline => 'ออฟไลน์';

  @override
  String get advModeOfflineLine =>
      'เฉพาะโทรศัพท์เครื่องนี้และเครือข่ายในพื้นที่ของคุณ โหนดในเครือข่ายของคุณยังใช้ได้ ส่วนอย่างอื่นรอจนกว่าคุณจะสลับกลับ';

  @override
  String get advTorOnlyNote =>
      'Tor เท่านั้นจะหยุดการแจ้งเตือน เพราะการลงทะเบียนรับแจ้งเตือนจะเปิดเผยที่อยู่ของโทรศัพท์เครื่องนี้';

  @override
  String get advOfflineNote =>
      'ออฟไลน์จะหยุด Epicbox, Tor, การตรวจสถานะ และการแจ้งเตือน ถ้ามีโหนดในเครือข่ายในพื้นที่ของคุณ ตรวจยอดใหม่ ไฟล์ และการส่งผ่านลิงก์ไปที่อยู่ในพื้นที่ยังใช้ได้ เพียร์ของโหนดเป็นการตั้งค่าของตัวโหนดเอง';

  @override
  String get advReset => 'ซ่อนทั้งหมดอีกครั้ง';

  @override
  String get advHomeOffline => 'โหมดออฟไลน์';

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
      'ทุกอย่างปิดอยู่ตอนแรก แต่ละสวิตช์เพิ่มส่วนของกระเป๋าเงินอีกส่วนหนึ่งในที่ที่มันอยู่';

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
  String get deskSetAdvNetworkHint =>
      'วิธีที่กระเป๋าเงินเชื่อมต่อเครือข่าย มาตรฐานเชื่อมต่อตรง เปิด Tor ได้ที่ ความเป็นส่วนตัว Tor เท่านั้นไม่เชื่อมต่อตรงเด็ดขาด ถ้าไม่มี Tor กระเป๋าเงินจะออฟไลน์และบอกที่แถบด้านข้าง ออฟไลน์ใช้เฉพาะคอมพิวเตอร์เครื่องนี้และเครือข่ายในพื้นที่ของคุณ ถ้ามีโหนดที่นี่หรือในเครือข่ายของคุณ ยังส่งไปที่อยู่ในพื้นที่ รับผ่านลิงก์ และใช้ไฟล์ได้ โหนดในตัวทำงานต่อไป และเพียร์ของมันเป็นการตั้งค่าของตัวโหนดเอง';

  @override
  String get deskSetAdvModeStandard => 'มาตรฐาน';

  @override
  String get deskSetAdvModeStandardText =>
      'เชื่อมต่อตรง เปิด Tor ได้ที่ ความเป็นส่วนตัว';

  @override
  String get deskSetAdvModeTorOnly => 'Tor เท่านั้น';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'ทุกการเชื่อมต่อผ่าน Tor ถ้าไม่มี Tor กระเป๋าเงินจะออฟไลน์และบอกให้ทราบ';

  @override
  String get deskSetAdvModeOffline => 'ออฟไลน์';

  @override
  String get deskSetAdvModeOfflineText =>
      'เฉพาะคอมพิวเตอร์เครื่องนี้และเครือข่ายในพื้นที่ของคุณ โหนดของคุณทำงานต่อไป เพียร์ของมันเป็นการตั้งค่าของตัวโหนดเอง';

  @override
  String get deskSetAdvTorOnlyNote =>
      'Tor เท่านั้นจะปิดการรับผ่าน HTTP เพราะที่อยู่ธรรมดาจะเปิดเผยคอมพิวเตอร์เครื่องนี้';

  @override
  String get deskSetAdvOfflineNote =>
      'Epicbox, Tor และการตรวจสถานะหยุดชั่วคราว ถ้ามีโหนดบนคอมพิวเตอร์เครื่องนี้หรือในเครือข่ายของคุณ ตรวจยอดใหม่ ไฟล์ และลิงก์ไปที่อยู่ในพื้นที่ยังใช้ได้';

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
  String get deskShellOffline => 'โหมดออฟไลน์';

  @override
  String get deskShellTorOnlyWaiting => 'Tor เท่านั้น · รอ Tor';

  @override
  String get deskSetAcctAutoLockHint =>
      'ล็อกกระเป๋าเมื่อไม่มีการกดแป้นหรือขยับเมาส์ตามเวลานี้ ถ้าปิดไว้ จะล็อกได้ด้วย “ล็อกกระเป๋า” เท่านั้น';

  @override
  String get netBlockOffline => 'โหมดออฟไลน์เปิดอยู่ใน ขั้นสูง';

  @override
  String get netBlockTorOnly => 'โหมด Tor เท่านั้นเปิดอยู่ใน ขั้นสูง';

  @override
  String get netBlockWaitingForTor => 'รอ Tor';

  @override
  String get receiveOfflineLine => 'รับด้วยวิธีนี้ไม่ได้ขณะอยู่ในโหมดออฟไลน์';

  @override
  String get txDetailsMore => 'เพิ่มเติม';

  @override
  String get restoreStartFromLink => 'เริ่มจากวันที่หรือความสูงบล็อก';

  @override
  String get homeOfflineDetail =>
      'โหมดออฟไลน์เปิดอยู่ใน ขั้นสูง ยอดคงเหลือเป็นยอดที่เห็นล่าสุด';

  @override
  String get homeWaitingTorDetail =>
      'โหมด Tor เท่านั้นเปิดอยู่ใน ขั้นสูง กำลังรอ Tor เชื่อมต่อ';

  @override
  String get settingsRescanBodyPlain =>
      'กระเป๋าเงินจะค้นหาเงินของตัวเองอีกครั้ง ตั้งแต่บล็อกแรก อาจใช้เวลานาน';

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
      'การเปลี่ยนจะทำให้ที่อยู่ของคุณเปลี่ยน ผู้ส่งต้องใช้ที่อยู่ใหม่';

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
  String get deskNetOfflineReason => 'โหมดออฟไลน์เปิดอยู่ใน ขั้นสูง';

  @override
  String get deskNetWaitingTorReason =>
      'รอ Tor โหมด Tor เท่านั้นเปิดอยู่ใน ขั้นสูง';

  @override
  String get deskNetTorOnlyLine => 'Tor เท่านั้นเปิดอยู่ใน ขั้นสูง';

  @override
  String get deskNetOpenAdvanced => 'เปิดขั้นสูง';

  @override
  String get deskNetSendFileHint => 'ไฟล์ธุรกรรมยังใช้ได้';

  @override
  String get deskNetRecvOfflineText =>
      'ที่อยู่ของคุณเหมือนเดิม จะไม่มีอะไรเข้ามาจนกว่าจะปิดโหมดออฟไลน์';

  @override
  String get deskNetRecvWaitTorText =>
      'การรับจะเริ่มเมื่อ Tor เชื่อมต่อ ไฟล์ธุรกรรมยังใช้ได้';

  @override
  String get deskNetCantReceive => 'รับไม่ได้ตอนออฟไลน์';

  @override
  String get deskRailOffline => 'ออฟไลน์';

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
  String get settingsHubDefault => 'ค่าเริ่มต้น';

  @override
  String get settingsHubSendDefaults => 'ค่าเริ่มต้นการส่ง';

  @override
  String get txMethodsHeader => 'วิธีชำระเงิน';

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
      'Epicbox จ่ายผ่านรีเลย์ กระเป๋าเงินอีกฝั่งจึงไม่ต้องเปิดอยู่ เมื่อปิด กระเป๋าเงินจะไม่เชื่อมต่อรีเลย์ใด ไม่มีการจ่ายผ่าน Epicbox ใบแจ้งหนี้ หรือการแจ้งเตือน ชำระด้วย QR และไฟล์ยังใช้ได้';

  @override
  String get txDirectLine =>
      'จ่ายไปที่อยู่ onion และเว็บ รับเงินที่ที่อยู่ Tor ของโทรศัพท์เครื่องนี้';

  @override
  String get txDirectHint =>
      'ลิงก์ส่งไปยังกระเป๋าเงินอีกฝั่งโดยตรงที่ที่อยู่ onion หรือเว็บ และให้โทรศัพท์เครื่องนี้มีที่อยู่ Tor สำหรับรับเงิน กระเป๋าเงินอีกฝั่งต้องเปิดอยู่ และเครื่องนี้ก็เช่นกัน ต้องใช้ Tor เพิ่มลิงก์ใน ส่ง และ รับ';

  @override
  String get txFileLine => 'จ่ายหรือรับเงินด้วยไฟล์ที่คุณส่งต่อเอง';

  @override
  String get txFileHint =>
      'ไฟล์สร้างไฟล์ธุรกรรมที่คุณส่งให้อีกฝ่ายด้วยวิธีใดก็ได้ (ข้อความ อีเมล สายเคเบิล) แล้วเขาส่งกลับมาหนึ่งไฟล์ ไม่ต้องมีการเชื่อมต่อระหว่างสองกระเป๋าเงิน เพิ่มไฟล์ใน ส่ง และ รับ';

  @override
  String get txStartHeader => 'การส่งเริ่มด้วย';

  @override
  String get txStartNote => 'ใน ส่ง ยังเลือกวิธีอื่นได้';

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
  String get netOfflineOnlyLocal => 'ออฟไลน์: เฉพาะที่อยู่ในพื้นที่';

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
    return '$method is off in Settings › Transactions.';
  }

  @override
  String get txEpicboxLine =>
      'จ่ายหรือรับเงินผ่านรีเลย์ กระเป๋าเงินอีกฝั่งปิดอยู่ได้';

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
  String get pushNoticeOffEpicbox =>
      'ปิดการแจ้งเตือนแล้ว การแจ้งเตือนต้องใช้ Epicbox';

  @override
  String get settingsPushNeedsEpicbox => 'ต้องใช้ Epicbox';

  @override
  String sendContactOnlyEpicbox(String name) {
    return '$name มีเฉพาะที่อยู่ Epicbox';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name has only a $method address.';
  }

  @override
  String get receiveEpicboxOffText =>
      'รายการจากผู้ส่งจะรออยู่ที่รีเลย์จนกว่าจะเปิด Epicbox อีกครั้ง';

  @override
  String get receiveNoMethods => 'ไม่มีวิธีรับเงินที่เปิดอยู่';

  @override
  String get receiveNoMethodsBody => 'เปิดสักวิธีใน การตั้งค่า › ธุรกรรม';

  @override
  String get receiveNoMethodsButton => 'เปิดการตั้งค่า';

  @override
  String get deskErrOfflineOnlyLocal => 'ออฟไลน์: เฉพาะที่อยู่ในพื้นที่';

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
      'จ่ายและรับเงินผ่านเซิร์ฟเวอร์ Epicbox การชำระเงินส่วนใหญ่ใช้ทางนี้ เมื่อปิด กระเป๋าเงินจะไม่เชื่อมต่อเซิร์ฟเวอร์ Epicbox ใด ไม่มีการจ่ายผ่าน Epicbox หรือใบแจ้งหนี้ ไฟล์ยังใช้ได้';

  @override
  String get deskSetTxDirectHint =>
      'จ่ายและรับเงินตรงจากกระเป๋าเงินสู่กระเป๋าเงิน ผ่าน HTTP หรือ Tor โดยไม่มีเซิร์ฟเวอร์คั่นกลาง ใช้ได้เฉพาะตอนที่กระเป๋าเงินเปิดอยู่ เพิ่มลิงก์ใน ส่ง และเพิ่มที่อยู่ของมันใน รับ';

  @override
  String get deskSetTxFileHint =>
      'จ่ายและรับเงินโดยส่งต่อไฟล์ธุรกรรม ไม่ต้องใช้เครือข่าย เพิ่มไฟล์ใน ส่ง และเพิ่มขั้นตอนเกี่ยวกับไฟล์ใน รับ';

  @override
  String get deskSetTxSend => 'ส่ง';

  @override
  String get deskSetTxStart => 'การส่งเริ่มด้วย';

  @override
  String get deskSetTxStartHint =>
      'วิธีที่หน้า ส่ง เปิดขึ้นมา สำหรับการจ่ายครั้งเดียวยังเปลี่ยนได้ที่หน้า ส่ง';

  @override
  String get deskSendMethodHeader => 'วิธีชำระเงิน';

  @override
  String get sendRequestTitle => 'คำขอชำระเงิน';

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
  String get sendNoteFromCodeHelper => 'มาจากโค้ด ผู้รับเห็นบันทึกนี้ด้วย';

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
  String get linkWaitingNotice => 'ได้รับลิงก์ชำระเงิน';

  @override
  String get linkFinishCurrentFirst => 'ทำรายการปัจจุบันให้เสร็จก่อน';

  @override
  String get deskSendToQrPayment =>
      'โค้ดชำระด้วย QR ให้สแกนด้วย Epic Cash Mobile';

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
}
