// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'BT Wallet';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get noticeLevelInfo => 'Информация';

  @override
  String get noticeLevelSuccess => 'Готово';

  @override
  String get noticeLevelWarning => 'Предупреждение';

  @override
  String get noticeLevelError => 'Ошибка';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonPaste => 'Вставить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonShare => 'Поделиться';

  @override
  String get commonUnknown => 'Неизвестно';

  @override
  String get passwordShow => 'Показать пароль';

  @override
  String get passwordHide => 'Скрыть пароль';

  @override
  String get slateCopyTooltip => 'Копировать текст транзакции';

  @override
  String get slateCopied => 'Текст транзакции скопирован';

  @override
  String get slatePastedTitle => 'Вставленный платёж';

  @override
  String get slateCopyReply => 'Копировать ответ';

  @override
  String get biometricPromptTitle => 'Разблокировать кошелёк';

  @override
  String get biometricPromptSubtitle =>
      'Подтвердите отпечатком пальца или лицом';

  @override
  String get biometricPromptUsePin => 'Ввести PIN-код';

  @override
  String get amountEnterExample => 'Введите сумму, например 1,5';

  @override
  String amountTooManyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не более $count знака после запятой',
      many: 'Не более $count знаков после запятой',
      few: 'Не более $count знаков после запятой',
      one: 'Не более $count знака после запятой',
    );
    return '$_temp0';
  }

  @override
  String dateWithTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get dateToday => 'Сегодня';

  @override
  String get dateYesterday => 'Вчера';

  @override
  String get txMiningReward => 'Награда за майнинг';

  @override
  String get txRestoredFunds => 'Найдено в блокчейне';

  @override
  String txSpokenLabelled(String label, String row) {
    return '$label, $row';
  }

  @override
  String get txLabel => 'Метка';

  @override
  String get txLabelAdd => 'Добавить метку';

  @override
  String get txLabelEdit => 'Изменить метку';

  @override
  String get txLabelHint => 'Добавить метку';

  @override
  String get txLabelAddedNotice => 'Метка добавлена';

  @override
  String get txLabelSavedNotice => 'Метка сохранена';

  @override
  String get txLabelRemovedNotice => 'Метка удалена';

  @override
  String get txEditAdd => 'Добавить сведения';

  @override
  String get txEditEdit => 'Изменить сведения';

  @override
  String get txEditFrom => 'Отправитель';

  @override
  String get txEditFromHint => 'Адрес';

  @override
  String get txEditFromHelper => 'Не проверено. Только для ваших записей.';

  @override
  String get txMethodUnknown => 'Неизвестно';

  @override
  String get txManualTag => 'Добавлено вами';

  @override
  String txManualTip(String date) {
    return 'Добавлено вами $date. Не из блокчейна.';
  }

  @override
  String get txManualTipNoDate => 'Добавлено вами. Не из блокчейна.';

  @override
  String txManualTipFrom(String date) {
    return 'Добавлено вами $date. Не из блокчейна, не проверено.';
  }

  @override
  String get txManualTipFromNoDate =>
      'Добавлено вами. Не из блокчейна, не проверено.';

  @override
  String get txEditAddedNotice => 'Сведения добавлены';

  @override
  String get txEditSavedNotice => 'Сведения сохранены';

  @override
  String get txEditRemovedNotice => 'Сведения удалены';

  @override
  String get histConflictTitle => 'Сведения различаются';

  @override
  String histConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
      many:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
      few:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
      one:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'Мои';

  @override
  String get histConflictBackup => 'Файл';

  @override
  String get histConflictKeepAll => 'Оставить все мои';

  @override
  String get histConflictImport => 'Импортировать';

  @override
  String get histConflictEmpty => 'пусто';

  @override
  String histImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Заменено сведений: $n. Остальные остаются вашими.',
      many: 'Заменено сведений: $n. Остальные остаются вашими.',
      few: 'Заменено сведений: $n. Остальные остаются вашими.',
      one: 'Заменено сведений: $n. Остальные остаются вашими.',
    );
    return '$_temp0';
  }

  @override
  String get txOutgoingPayment => 'Исходящий платёж';

  @override
  String get txIncomingPayment => 'Входящий платёж';

  @override
  String get txStatusWaitingRecipient => 'Ждёт получателя';

  @override
  String get txStatusWaitingSender => 'Ждёт отправителя';

  @override
  String get txStatusSenderPosted => 'Отправитель сообщил об отправке';

  @override
  String txStatusConfirming(int count, int target) {
    return 'Подтверждение $count/$target';
  }

  @override
  String get txStatusCompleted => 'Завершён';

  @override
  String get txStatusCancelled => 'Отменён';

  @override
  String get txStatusFromBackup => 'Импортирован';

  @override
  String get txIconCancelled => 'Отменён';

  @override
  String get txIconIncoming => 'Входящий';

  @override
  String get txIconOutgoing => 'Исходящий';

  @override
  String get txSpokenHiddenAmount => 'сумма скрыта';

  @override
  String txSpokenMiningReward(String amount) {
    return 'Награда за майнинг: $amount';
  }

  @override
  String txSpokenRestoredFunds(String amount) {
    return 'Найдено в блокчейне: $amount';
  }

  @override
  String txSpokenCancelledSend(String amount) {
    return 'Отменённая отправка: $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return 'Отменённая отправка: $amount, получатель: $who';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return 'Отменённое получение: $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return 'Отменённое получение: $amount, отправитель: $who';
  }

  @override
  String txSpokenSending(String amount) {
    return 'Отправка: $amount';
  }

  @override
  String txSpokenSendingTo(String amount, String who) {
    return 'Отправка: $amount, получатель: $who';
  }

  @override
  String txSpokenReceiving(String amount) {
    return 'Получение: $amount';
  }

  @override
  String txSpokenReceivingFrom(String amount, String who) {
    return 'Получение: $amount, отправитель: $who';
  }

  @override
  String txSpokenSent(String amount) {
    return 'Отправлено: $amount';
  }

  @override
  String txSpokenSentTo(String amount, String who) {
    return 'Отправлено: $amount, получатель: $who';
  }

  @override
  String txSpokenReceived(String amount) {
    return 'Получено: $amount';
  }

  @override
  String txSpokenReceivedFrom(String amount, String who) {
    return 'Получено: $amount, отправитель: $who';
  }

  @override
  String txSpokenRow(String what, String status, String date) {
    return '$what, $status, $date';
  }

  @override
  String get errorInvalidMnemonic =>
      'Неверная фраза восстановления. Проверьте каждое слово и порядок слов.';

  @override
  String get errorWrongPassword => 'Неверный пароль.';

  @override
  String get errorWalletAlreadyExists =>
      'Кошелёк для этой сети уже существует.';

  @override
  String get errorWalletNotFound => 'Кошелёк для этой сети не найден.';

  @override
  String get errorNodeUnreachable =>
      'Не удаётся подключиться к узлу. Проверьте адрес узла и подключение к сети.';

  @override
  String get errorNotEnoughFunds =>
      'Недостаточно доступных средств для этой суммы с учётом комиссии.';

  @override
  String get errorInvalidSlate =>
      'Этот текст транзакции не подходит для данного шага. Проверьте, что он вставлен целиком.';

  @override
  String get errorInvalidInput => 'Неверные данные.';

  @override
  String get errorTransportFailed => 'Не удалось связаться с получателем.';

  @override
  String get errorTorNotRunning => 'Tor не подключён.';

  @override
  String get errorOnionUnreachable =>
      'Не удалось связаться с кошельком получателя через Tor.';

  @override
  String get errorChainBusy =>
      'Кошелёк ещё занят в другой сети. Подождите немного и повторите попытку или перезапустите приложение.';

  @override
  String get errorWalletBusy =>
      'Кошелёк ещё завершает задачу. Повторите попытку чуть позже.';

  @override
  String get errorPaymentExpired =>
      'Ответ на этот платёж пришёл слишком поздно, поэтому платёж отменён. Ничего не отправлено.';

  @override
  String get errorIo => 'Не удалось прочитать или записать файлы кошелька.';

  @override
  String get errorOther => 'Ошибка кошелька.';

  @override
  String get errorScanFailed => 'Ошибка сканирования.';

  @override
  String get errorUnexpected => 'Непредвиденная ошибка. Повторите попытку.';

  @override
  String get errorHistoryNotOurs =>
      'Это не файл данных кошелька из этого приложения.';

  @override
  String get errorHistoryNewer =>
      'Этот файл данных кошелька создан более новой версией приложения.';

  @override
  String get errorHistoryDamaged => 'Этот файл данных кошелька повреждён.';

  @override
  String get errorHistoryOtherWallet =>
      'Этот файл принадлежит другому кошельку. Открыть его может только кошелёк, восстановленный по той же фразе восстановления.';

  @override
  String get errorHistoryOtherNetwork =>
      'Этот файл данных кошелька из другой сети.';

  @override
  String get autoLockNever => 'Никогда';

  @override
  String get autoLockImmediately => 'Сразу';

  @override
  String autoLockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Через $minutes минуты',
      many: 'Через $minutes минут',
      few: 'Через $minutes минуты',
      one: 'Через $minutes минуту',
    );
    return '$_temp0';
  }

  @override
  String get scanStarting => 'Запуск сканирования';

  @override
  String scanProgress(int percent) {
    return 'Сканирование блокчейна ($percent %)';
  }

  @override
  String get scanComplete => 'Сканирование завершено';

  @override
  String get scanResuming => 'Возобновление сканирования';

  @override
  String get scanResumedNotice =>
      'Сканирование было приостановлено, пока приложение было в фоне. Оно продолжается с того места, где остановилось.';

  @override
  String get languageSetting => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get currencyUsd => 'Доллар США';

  @override
  String get currencyEur => 'Евро';

  @override
  String get currencyGbp => 'Британский фунт';

  @override
  String get currencyBtc => 'Биткоин';

  @override
  String get currencyJpy => 'Японская иена';

  @override
  String get currencyCny => 'Китайский юань';

  @override
  String get currencyCad => 'Канадский доллар';

  @override
  String get currencyAud => 'Австралийский доллар';

  @override
  String get currencyChf => 'Швейцарский франк';

  @override
  String get currencyInr => 'Индийская рупия';

  @override
  String get currencyBrl => 'Бразильский реал';

  @override
  String get currencyKrw => 'Южнокорейская вона';

  @override
  String get currencyPln => 'Польский злотый';

  @override
  String get currencyTry => 'Турецкая лира';

  @override
  String txDetailsWaitingTooLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Платёж ждёт уже $_temp0. Сервер Epicbox удаляет платежи через 7 дней, поэтому этот платёж уже не завершится. Отмените его, чтобы разблокировать монеты, а затем отправьте снова.';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Отправлено через Epicbox. Завершится, когда кошелёк получателя выйдет в сеть; до этого или до отмены сумма остаётся заблокированной.';

  @override
  String get txDetailsWaitingRecipient =>
      'Ожидается файл ответа получателя. Сумма остаётся заблокированной до этого или до отмены.';

  @override
  String get txDetailsWaitingSender =>
      'Ждёт, пока отправитель отправит её в сеть.';

  @override
  String get txDetailsSenderPosted =>
      'По словам отправителя, этот платёж отправлен в сеть. Он будет выполнен, когда сеть его подтвердит.';

  @override
  String get txDetailsPublished =>
      'Опубликовано в сети. Ожидается первое подтверждение.';

  @override
  String get txDetailsWaitingConfirmation => 'Ожидается подтверждение сетью.';

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
      other: '$target подтверждения',
      many: '$target подтверждений',
      few: '$target подтверждений',
      one: '$target подтверждения',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минуту',
    );
    return 'В блоке $height. $count из $_temp0; станет окончательным примерно через $_temp1.';
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
      other: '$target подтверждения',
      many: '$target подтверждений',
      few: '$target подтверждений',
      one: '$target подтверждения',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours часа',
      many: '$hours часов',
      few: '$hours часа',
      one: '$hours час',
    );
    return 'В блоке $height. $count из $_temp0; станет окончательным примерно через $_temp1.';
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
      other: '$target подтверждения',
      many: '$target подтверждений',
      few: '$target подтверждений',
      one: '$target подтверждения',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'В блоке $height. $count из $_temp0; станет окончательным примерно через $_temp1.';
  }

  @override
  String get txDetailsCompleted => 'Завершено.';

  @override
  String txDetailsCompletedInBlock(String height) {
    return 'Завершено в блоке $height.';
  }

  @override
  String get txDetailsCancelledByUser =>
      'Отменено. Ничего не оплачено, средства снова доступны. Если получатель уже получил платёж, его кошелёк может ещё показывать его как ожидающий.';

  @override
  String get txDetailsCancelledReleased =>
      'Сеть так и не приняла этот платёж, поэтому его средства разблокированы. Прежде чем отправлять снова, убедитесь, что получатель его не получил.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Платёж не попал в сеть вовремя и был отменён. Прежде чем отправлять снова, убедитесь, что получатель его не получил.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Получатель не ответил за 24 часа, поэтому кошелёк отменил платёж. Ничего не оплачено, средства снова доступны.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Получатель ответил после 24-часового срока, поэтому кошелёк отменил платёж вместо завершения. Ничего не оплачено, средства снова доступны.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Платёж не удалось доставить получателю, поэтому кошелёк сразу отменил его. Ничего не отправлено, средства снова доступны.';

  @override
  String get txDetailsCancelledIncoming =>
      'Отменено. Если отправитель опубликует платёж позже, он всё равно поступит.';

  @override
  String get txStatusReceiverDeclined => 'Отклонён получателем';

  @override
  String get txDetailsReceiverDeclined =>
      'Получатель отклонил этот платёж. Он отменён, средства снова доступны.';

  @override
  String get txStatusSenderCancelled => 'Отменён отправителем';

  @override
  String get txDetailsSenderCancelledWaiting =>
      'Отправитель отменил этот платёж. Кошелёк уберёт его здесь после проверки сети.';

  @override
  String get txDetailsSenderCancelled =>
      'Отправитель отменил этот платёж. Если он был опубликован раньше, он всё равно поступит.';

  @override
  String get txDetailsFromBackup =>
      'Этот платёж импортирован из файла данных кошелька и не был завершён на момент экспорта этого файла. У этого кошелька нет собственной записи о нём, поэтому неизвестно, завершился ли он. Ничего не заблокировано.';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return 'Автоматически отменится, если не завершится к блоку $height.';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минуту',
    );
    return 'Автоматически отменится, если не завершится к блоку $height (примерно через $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours часа',
      many: '$hours часов',
      few: '$hours часа',
      one: '$hours час',
    );
    return 'Автоматически отменится, если не завершится к блоку $height (примерно через $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Автоматически отменится, если не завершится к блоку $height (примерно через $_temp0).';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return 'Срок истёк на блоке $height. Кошелёк отменит платёж при следующем обновлении.';
  }

  @override
  String get txDetailsTitle => 'Платёж';

  @override
  String get txDetailsLoading => 'Загрузка';

  @override
  String get txDetailsGone => 'Этого платежа больше нет в кошельке.';

  @override
  String get txDetailsWorking => 'Выполняется';

  @override
  String get txDetailsAmountHidden => 'Сумма скрыта';

  @override
  String get txWaitNoNewBlock => 'Ожидание следующего блока.';

  @override
  String get txWaitNotInBlock =>
      'Пока не в блоке. Платёж, возможно, ещё на пути в сеть.';

  @override
  String get txDetailsStuckBody =>
      'Сеть не приняла этот платёж. Отправьте его снова; он не может пройти дважды.';

  @override
  String get txDetailsBroadcastAgain => 'Отправить повторно';

  @override
  String get txDetailsBroadcastAgainDone => 'Отправлено повторно.';

  @override
  String get txDetailsRefusedBody =>
      'Этот платёж не прошёл. Монеты, которые он держит, можно освободить.';

  @override
  String get txDetailsReleaseFunds => 'Разблокировать средства';

  @override
  String get txDetailsReleaseTitle => 'Разблокировать средства?';

  @override
  String get txDetailsReleaseBody =>
      'Этот платёж не прошёл, но ещё может пройти позже.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Подождать ещё';

  @override
  String get txDetailsFundsReleased => 'Средства разблокированы';

  @override
  String get txDetailsCancelPayment => 'Отменить платёж';

  @override
  String get txDetailsCancelTitle => 'Отменить этот платёж?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Пока ничего не пришло. Если этот платёж придёт позже, он будет показан как полученный.';

  @override
  String get txDetailsCancelSendBody =>
      'Пока ничего не оплачено: отмена бесплатна и надёжна.';

  @override
  String get txDetailsCancelKeep => 'Оставить';

  @override
  String get txDetailsPaymentCancelled => 'Платёж отменён';

  @override
  String get txDetailsDate => 'Дата';

  @override
  String get txDetailsCreated => 'Создан';

  @override
  String get txDetailsSentTo => 'Получатель';

  @override
  String get txDetailsReceivedFrom => 'Отправитель';

  @override
  String get txDetailsCopyAddress => 'Копировать адрес';

  @override
  String get txDetailsAddressCopied => 'Адрес скопирован';

  @override
  String get txDetailsAddToContacts => 'Добавить в контакты';

  @override
  String get txDetailsSendAgain => 'Отправить снова';

  @override
  String get txDetailsFee => 'Комиссия';

  @override
  String get txDetailsNoteLabel => 'Личная заметка';

  @override
  String get txDetailsPrivateNoteLabel => 'Личная заметка';

  @override
  String get txDetailsMessageFromSender => 'Сообщение';

  @override
  String get txDetailsMessageFromRecipient => 'Сообщение получателя';

  @override
  String get txDetailsYourMessage => 'Сообщение';

  @override
  String get txDetailsMessageHintToRecipient => 'Отправлено получателю';

  @override
  String get txDetailsMessageHintFromSender => 'От отправителя';

  @override
  String get txDetailsMessageHintFromRecipient => 'От получателя';

  @override
  String get txDetailsMessageHintToSender => 'Отправлено отправителю';

  @override
  String get txDetailsNoNote => 'Заметки нет';

  @override
  String get txDetailsAddNote => 'Добавить заметку';

  @override
  String get txDetailsEditNote => 'Изменить заметку';

  @override
  String get txDetailsNoteDialogTitle => 'Личная заметка';

  @override
  String get txDetailsNoteHelper =>
      'Хранится только в этом приложении и в экспортированных данных кошелька.';

  @override
  String get txDetailsNoteSaved => 'Заметка сохранена';

  @override
  String get txDetailsNoteRemoved => 'Заметка удалена';

  @override
  String get txDetailsExplorerLink =>
      'Копировать ссылку на обозреватель блоков';

  @override
  String get txDetailsExplorerLinkCopy =>
      'Копировать ссылку на обозреватель блоков';

  @override
  String get txDetailsLinkCopied => 'Ссылка скопирована';

  @override
  String get txDetailsExplorerBehind =>
      'Обозреватель ещё не дошёл до этого блока.';

  @override
  String get txDetailsTechnical => 'Технические сведения';

  @override
  String get txDetailsBlockHeight => 'Высота блока';

  @override
  String get txDetailsSlateId => 'ID слейта';

  @override
  String get txDetailsSlateIdCopy => 'Копировать ID слейта';

  @override
  String get txDetailsSlateIdCopied => 'ID слейта скопирован';

  @override
  String get txDetailsKernel => 'Ядро';

  @override
  String get txDetailsKernelCopy => 'Копировать ядро';

  @override
  String get txDetailsKernelCopied => 'Ядро скопировано';

  @override
  String get txDetailsOutputCommitment => 'Коммитмент выхода';

  @override
  String get txDetailsOutputCommitmentCopy => 'Копировать коммитмент выхода';

  @override
  String get txDetailsOutputCommitmentCopied => 'Коммитмент выхода скопирован';

  @override
  String txDetailsOutputCommitmentNumbered(int number) {
    return 'Коммитмент выхода $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopy(int number) {
    return 'Копировать коммитмент выхода $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopied(int number) {
    return 'Коммитмент выхода $number скопирован';
  }

  @override
  String get txDetailsExpiryHeight => 'Высота истечения срока';

  @override
  String get txDetailsLocalId => 'Локальный ID';

  @override
  String get txDetailsSourceRestored =>
      'Найдено в блокчейне. Отправителя и комиссии в блокчейне нет; импортируйте данные кошелька, чтобы добавить их.';

  @override
  String get txDetailsSourceImported =>
      'Импортировано из файла данных кошелька. Статус в цепочке не проверялся.';

  @override
  String get historyTitle => 'Активность';

  @override
  String get historyLoading => 'Загрузка платежей';

  @override
  String get historyRefreshing => 'Обновление';

  @override
  String get historySearchLabel => 'Поиск';

  @override
  String get historySearchHint => 'Заметка, контакт, адрес или сумма';

  @override
  String get historyClearSearch => 'Очистить поиск';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterSent => 'Отправленные';

  @override
  String get historyFilterReceived => 'Полученные';

  @override
  String get historyFilterPending => 'Ожидающие';

  @override
  String get historyFilterCancelled => 'Отменённые';

  @override
  String get historySectionPending => 'В ожидании';

  @override
  String get historyEmpty =>
      'Пока пусто. Здесь появятся отправленные и полученные платежи.';

  @override
  String get historyNoSent => 'Нет отправленных платежей.';

  @override
  String get historyNoReceived => 'Нет полученных платежей.';

  @override
  String get historyNoPending => 'Нет ожидающих платежей.';

  @override
  String get historyNoCancelled => 'Нет отменённых платежей.';

  @override
  String historyNoMatch(String query) {
    return 'По запросу «$query» ничего не найдено.';
  }

  @override
  String get historyBackupSaveDialogTitle => 'Сохранить данные кошелька';

  @override
  String get importWarnTitle => 'Перед импортом';

  @override
  String get importWarnEarly => 'Это ранняя версия нового приложения.';

  @override
  String get importWarnReads =>
      'Импорт только читает ваши старые кошельки и файлы; он никогда не удаляет и не изменяет их.';

  @override
  String get importWarnBackup =>
      'Прежде чем продолжить, убедитесь, что у вас есть резервная копия каждого кошелька: его фраза восстановления и, если вы их храните, файлы кошелька.';

  @override
  String get importWarnRisk =>
      'Вы импортируете на свой риск; мы не несём ответственности за какие-либо потери.';

  @override
  String get importWarnRiskPlain =>
      'Импорт выполняется на ваш риск. Ответственность за потери не принимается.';

  @override
  String get importWarnAck => 'У меня есть резервная копия каждого кошелька';

  @override
  String get historyBackupOpenDialogTitle => 'Открыть файл данных кошелька';

  @override
  String get historyBackupFileTooLarge =>
      'Этот файл слишком большой для файла данных кошелька.';

  @override
  String get historyBackupShare => 'Поделиться';

  @override
  String get historyBackupShareSubtitle =>
      'Копия вне телефона, например в облаке или на другом устройстве.';

  @override
  String get historyBackupSaveToDevice => 'Сохранить на устройстве';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Скопируйте его также вне телефона.';

  @override
  String historyBackupSaved(String fileName) {
    return 'Сохранено: $fileName';
  }

  @override
  String get historyBackupExportTitle => 'Экспорт данных кошелька';

  @override
  String get historyBackupCsvTitle => 'Экспорт в CSV';

  @override
  String get historyBackupCsvWarning =>
      'Не зашифрован: любой, у кого есть файл, увидит суммы, даты, адреса и заметки. Импортировать его нельзя; для резервной копии используйте «Экспорт данных кошелька».';

  @override
  String get historyBackupCsvConfirm => 'Экспортировать CSV';

  @override
  String get historyBackupImportedTitle => 'Данные кошелька импортированы';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Данные кошелька не импортированы. $reason';
  }

  @override
  String get historyBackupImportNothingNew => 'В файле нет ничего нового.';

  @override
  String get homeLockTooltip => 'Заблокировать кошелёк';

  @override
  String get shellTitle => 'BT Wallet';

  @override
  String get homeSettingsTooltip => 'Настройки';

  @override
  String get homeSendButton => 'Отправить';

  @override
  String get shellWalletTab => 'Кошелёк';

  @override
  String get homeReceiveButton => 'Получить';

  @override
  String get homeScanTooltip => 'Сканировать QR-код для отправки';

  @override
  String get homeRecentActivity => 'Последние операции';

  @override
  String get homeBackedUpNotice => 'Фраза восстановления сохранена';

  @override
  String get homeNoticeView => 'Открыть';

  @override
  String get homeNoticeReceived => 'Платёж в пути.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return '$who отправляет вам платёж.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount в пути.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$who отправляет вам $amount.';
  }

  @override
  String get homeNoticeSenderPosted => 'Отправитель сообщил об отправке.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Отправитель: $amount отправлено.';
  }

  @override
  String get homeNoticeFinished => 'Платёж завершён. Подтверждается.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Платёж для $who завершён. Подтверждается.';
  }

  @override
  String get homeNoticeDelayed => 'Нет связи с узлом. Платёж ждёт.';

  @override
  String get homeNoticeRelayProblem =>
      'Сервер epicbox сообщил о проблеме. Пробуем снова.';

  @override
  String get homeNoticePaymentFailed => 'Платёж не удался.';

  @override
  String get homeBackupCardText => 'Фраза не сохранена';

  @override
  String get homeBackupCardButton => 'Сохранить';

  @override
  String get homeBackupCardDismiss => 'Скрыть';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа не входят в экспортированные данные кошелька.',
      many: '$count платежей не входят в экспортированные данные кошелька.',
      few: '$count платежа не входят в экспортированные данные кошелька.',
      one: '$count платёж не входит в экспортированные данные кошелька.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count платежа добавлены или изменены после последнего экспорта данных кошелька.',
      many:
          '$count платежей добавлены или изменены после последнего экспорта данных кошелька.',
      few:
          '$count платежа добавлены или изменены после последнего экспорта данных кошелька.',
      one:
          '$count платёж добавлен или изменён после последнего экспорта данных кошелька.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Не сейчас';

  @override
  String get homeHistoryExportButton => 'Экспорт данных кошелька';

  @override
  String get homeBalanceSpendable => 'Доступно';

  @override
  String get balanceHelpLabel => 'Что означают эти балансы';

  @override
  String get balanceTotal => 'Всего';

  @override
  String balanceHelpRow(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get balanceTotalHelp => 'Всё в этом кошельке, доступное и нет.';

  @override
  String get homeBalanceHiddenLabel => 'Баланс скрыт';

  @override
  String balanceExactTip(String amount) {
    return 'Точная сумма: $amount';
  }

  @override
  String get homeShowBalances => 'Показать баланс';

  @override
  String get homeHideBalances => 'Скрыть суммы';

  @override
  String get homeBalanceConfirming => 'Подтверждается';

  @override
  String get balanceConfirmingHelp =>
      'В блокчейне, ждёт достаточно подтверждений.';

  @override
  String get homeBalanceNotOnChain => 'Ещё не в блокчейне';

  @override
  String get balanceNotOnChainHelp =>
      'Платежи вам, которые отправитель ещё не завершил или которые ещё не попали в блок, и сдача с ваших отправок. Учитываются только после попадания в блок: просто предложенный платёж может так и не прийти.';

  @override
  String get homeBalanceLocked => 'Заблокировано текущим платежом';

  @override
  String get balanceLockedHelp =>
      'Зарезервировано для начатого платежа; сдача вернётся после его завершения.';

  @override
  String get homeBalanceImmature => 'Награды за майнинг';

  @override
  String get balanceImmatureHelp =>
      'Награды за майнинг ждут определённое число блоков, прежде чем их можно потратить.';

  @override
  String get balanceLineAllConfirmed => 'Всё подтверждено';

  @override
  String get homeSyncSyncing => 'Синхронизация…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'Синхронизация… $percent %';
  }

  @override
  String get homeSyncNodeUnreachable =>
      'Узел недоступен. Баланс может быть устаревшим.';

  @override
  String get homeSyncNotValidated =>
      'Не проверено узлом. Баланс может быть устаревшим.';

  @override
  String get homeSyncUpToDate => 'Актуально.';

  @override
  String get homeSyncContactingNode => 'Подключение к узлу…';

  @override
  String get statusNodeOnline => 'Узел в сети';

  @override
  String get statusNodeSyncing => 'Синхронизация узла';

  @override
  String statusNodeSyncingPercent(int percent) {
    return 'Синхронизация узла $percent %';
  }

  @override
  String percentValue(String percent) {
    return '$percent %';
  }

  @override
  String get statusNodeConnecting => 'Подключение к узлу';

  @override
  String get statusNodeOffline => 'Узел не в сети';

  @override
  String get statusEpicboxOnline => 'Epicbox подключён';

  @override
  String get statusEpicboxConnecting => 'Подключение к epicbox';

  @override
  String get statusEpicboxOffline => 'Epicbox не подключён';

  @override
  String get statusEpicboxBlocked => 'Epicbox заблокирован';

  @override
  String epicboxBlockedBody(String host) {
    return 'Эта сеть блокирует $host. Причиной может быть сетевой фильтр. Попробуйте другой сервер Epicbox или частный DNS-сервер.';
  }

  @override
  String epicboxSwitchTo(String host) {
    return 'Переключиться на $host';
  }

  @override
  String get netStatusBlocked => 'Заблокирован';

  @override
  String statusNodeHost(Object host) {
    return 'Узел: $host';
  }

  @override
  String statusNodeVersion(Object version) {
    return 'Версия узла $version';
  }

  @override
  String statusRelay(Object relay) {
    return 'Сервер: $relay';
  }

  @override
  String get homeEpicboxOffline =>
      'Кошелёк не подключён к своему серверу Epicbox и продолжает попытки.';

  @override
  String get homeEpicboxConnecting => 'Подключение к Epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Синхронизировано на блоке $height';
  }

  @override
  String contactsStaleOpened(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Последнее открытие $days дня назад. Проверка сопряжённых контактов.',
      many:
          'Последнее открытие $days дней назад. Проверка сопряжённых контактов.',
      few:
          'Последнее открытие $days дня назад. Проверка сопряжённых контактов.',
      one:
          'Последнее открытие $days день назад. Проверка сопряжённых контактов.',
    );
    return '$_temp0';
  }

  @override
  String homePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа ждут ответа получателей',
      many: '$count платежей ждут ответа получателей',
      few: '$count платежа ждут ответа получателей',
      one: '$count платёж ждёт ответа получателя',
    );
    return '$_temp0';
  }

  @override
  String get homePendingWhy => 'Почему задержка?';

  @override
  String homePendingView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Открыть все',
      many: 'Открыть все',
      few: 'Открыть все',
      one: 'Открыть',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPayments => 'Платежей пока нет';

  @override
  String get invoicesTitle => 'Счета';

  @override
  String invoicesEntryTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Счета, $count ждут',
      many: 'Счета, $count ждут',
      few: 'Счета, $count ждут',
      one: 'Счета, $count ждёт',
      zero: 'Счета',
    );
    return '$_temp0';
  }

  @override
  String get invoicesChecking => 'Проверка счетов';

  @override
  String get invoicesEmpty =>
      'Счетов нет. Когда сопряжённый контакт, которому вы разрешили, попросит об оплате, счёт появится здесь, и ничего не будет оплачено без вашего одобрения.';

  @override
  String get invoicesUnnamedService => 'Сервис без названия';

  @override
  String invoiceTimeLeftHours(int hours, int minutes) {
    return 'Осталось $hours ч $minutes мин';
  }

  @override
  String invoiceTimeLeftMinutes(int minutes) {
    return 'Осталось $minutes мин';
  }

  @override
  String get invoiceTimeLeftUnderMinute => 'Осталось меньше минуты';

  @override
  String get invoiceExpired => 'Срок этого счёта истёк. Ничего не оплачено.';

  @override
  String get invoiceGone => 'Этот счёт больше не открыт. Ничего не оплачено.';

  @override
  String invoiceReviewAsks(String service) {
    return 'Сервис $service просит оплатить';
  }

  @override
  String invoiceReviewMessageLabel(String name) {
    return 'Сообщение от $name';
  }

  @override
  String get invoiceApprove => 'Одобрить и оплатить';

  @override
  String get invoiceDecline => 'Отклонить';

  @override
  String get invoicePinReason => 'Введите PIN-код, чтобы оплатить этот счёт.';

  @override
  String get invoiceDeclineTitle => 'Отклонить этот счёт?';

  @override
  String invoiceDeclineBody(String service) {
    return 'Сервис $service узнает, что вы отказались. Ничего не оплачивается.';
  }

  @override
  String get invoiceDeclineKeep => 'Оставить';

  @override
  String get invoiceDeclinedNotice => 'Счёт отклонён.';

  @override
  String invoicePaidNotice(String service) {
    return 'Оплачено. Сервис $service завершает платёж.';
  }

  @override
  String invoiceReplyFailedTitle(String service) {
    return 'Платёж ещё не дошёл до сервиса $service';
  }

  @override
  String get invoiceReplyFailedBody =>
      'Он подписан и сохранён на этом устройстве. «Повторить» отправит его снова, без повторного одобрения.';

  @override
  String get invoiceReplyFailedNotice =>
      'Платёж не дошёл до сервиса. Нажмите «Повторить», чтобы отправить его снова.';

  @override
  String get invoiceRetry => 'Повторить';

  @override
  String get invoiceDetailsSection => 'Счёт';

  @override
  String get invoiceDetailsService => 'Выставил';

  @override
  String invoiceDetailsReplied(String service) {
    return 'Ожидание, пока сервис $service опубликует платёж.';
  }

  @override
  String invoiceDetailsRepliedHelp(String service) {
    return 'Если $service не опубликовал платёж, отправьте его снова: ничего не подписывается дважды. Если он так и не будет опубликован, отмена станет доступна, когда истечёт время платежа, примерно через сутки после оплаты.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return 'Сервис $service сообщает, что опубликовал платёж. Он завершится, когда сеть его подтвердит.';
  }

  @override
  String invoiceDetailsConfirmed(String service) {
    return 'Оплачено. Сеть подтвердила платёж для $service.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return 'Сервис $service ещё не получил ваш платёж. «Повторить» отправит его снова, без повторного одобрения.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return 'Сервис $service отозвал этот счёт после оплаты.';
  }

  @override
  String get invoiceNoticeReceived => 'Счёт ждёт вашего одобрения.';

  @override
  String get invoiceNoticePosted =>
      'Сервис сообщает, что опубликовал ваш платёж.';

  @override
  String get invoiceNoticeWithdrawnPaid =>
      'Сервис отозвал уже оплаченный счёт.';

  @override
  String get invoiceNoticeWithdrawn => 'Сервис отозвал счёт до вашего ответа.';

  @override
  String get invoiceNoticeExpired => 'Срок счёта истёк до вашего ответа.';

  @override
  String get receiveRequestTitle => 'Запросить платёж';

  @override
  String get requestMessageLabel => 'Сообщение (необязательно)';

  @override
  String get requestMessageHelper =>
      'Плательщик увидит это сообщение вместе с счётом.';

  @override
  String get invoicesToPaySection => 'К оплате';

  @override
  String get issuedPaid => 'Оплачен';

  @override
  String get issuedDeclined => 'Отклонён';

  @override
  String get issuedWithdrawn => 'Отозван';

  @override
  String get issuedExpired => 'Истёк';

  @override
  String get issuedWithdraw => 'Отозвать';

  @override
  String get issuedWithdrawTitle => 'Отозвать этот счёт?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer больше не сможет его оплатить. Ничего не оплачено, монеты не перемещаются. Это нельзя отменить.';
  }

  @override
  String get issuedWithdrawKeep => 'Оставить';

  @override
  String get issuedDetailsSection => 'Счёт';

  @override
  String get issuedDetailsPayer => 'Запрошено у';

  @override
  String get issuedDetailsWaiting =>
      'Ждём плательщика. Ваш кошелёк завершит платёж, когда он придёт.';

  @override
  String get issuedDetailsPaid =>
      'Оплачен. Ваш кошелёк завершил платёж; он завершится, когда сеть его подтвердит.';

  @override
  String get issuedDetailsDeclined =>
      'Плательщик отклонил этот счёт, поэтому он отозван. Ничего не оплачено.';

  @override
  String get issuedDetailsWithdrawn =>
      'Вы отозвали этот счёт. Ничего не оплачено.';

  @override
  String get issuedDetailsExpired =>
      'Срок этого счёта истёк до оплаты. Ничего не оплачено.';

  @override
  String get issuerNoticePaid => 'Один из ваших счетов оплачен.';

  @override
  String get issuerNoticeDeclined => 'Один из ваших счетов отклонён.';

  @override
  String get issuerNoticeWithdrawn =>
      'Счёт отозван. Его больше нельзя оплатить.';

  @override
  String get issuerNoticeExpired =>
      'Срок одного из ваших счетов истёк без оплаты.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Кошелёк $payer не умеет оплачивать счета и вернул ваш, поэтому он отозван. Попросите этого человека отправить вам платёж обычным способом: на ваш адрес или файлом транзакции.';
  }

  @override
  String get issuedBounced => 'Возвращён';

  @override
  String get issuedDetailsBounced =>
      'Кошелёк плательщика не умеет оплачивать счета, поэтому ничего не оплачено. Попросите отправить платёж на ваш адрес или как файл транзакции.';

  @override
  String get txStatusWaitingPayer => 'Ждёт плательщика';

  @override
  String get txStepRequested => 'Запрошено';

  @override
  String get txStepPaid => 'Оплачено';

  @override
  String get txDetailsWaitingPayer =>
      'Вы запросили этот платёж. Пока ничего не поступило: платёж придёт, когда плательщик оплатит счёт.';

  @override
  String get txDetailsRequestEnded =>
      'Этот счёт завершён без оплаты. Ничего не поступило.';

  @override
  String get txDetailsRequestedFrom => 'Запрошено у';

  @override
  String get txPaymentRequest => 'Запрошенный платёж';

  @override
  String txSpokenRequesting(String amount) {
    return 'Запрошено: $amount';
  }

  @override
  String txSpokenRequestingFrom(String amount, String who) {
    return 'Запрошено: $amount, плательщик: $who';
  }

  @override
  String receiveEpicboxConnected(String server) {
    return 'Подключено · $server';
  }

  @override
  String get receiveQrLabel => 'QR-код вашего адреса';

  @override
  String get receiveAddressLabel => 'Адрес Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'Платежи ждут на сервере Epicbox и поступят, когда кошелёк снова подключится.';

  @override
  String get receiveShareCardHeadline => 'Заплатите мне в Epic Cash';

  @override
  String get receiveHelpButton => 'Как работает получение';

  @override
  String get receiveAddressCopied => 'Адрес скопирован';

  @override
  String get receiveFileTitle => 'Получить по файлу транзакции';

  @override
  String get receiveFileBody =>
      'Откройте файл транзакции или вставьте сюда его текст.';

  @override
  String get receiveFileOpen => 'Открыть файл';

  @override
  String get receivePasteEmpty =>
      'Сначала скопируйте текст платежа, затем нажмите «Вставить».';

  @override
  String get updateChecking => 'Проверка обновлений…';

  @override
  String get updateUpToDate => 'Установлена последняя версия.';

  @override
  String get updateNoInformation => 'Нет сведений об обновлениях.';

  @override
  String updateAvailable(String version) {
    return 'Доступна версия $version.';
  }

  @override
  String updateDownloading(String version, int percent) {
    return 'Загрузка версии $version… $percent %';
  }

  @override
  String updateInstalling(String version) {
    return 'Установка версии $version…';
  }

  @override
  String get updateFailed => 'Не удалось обновить приложение.';

  @override
  String get updateInstallButton => 'Обновить';

  @override
  String get updateTryAgain => 'Повторить';

  @override
  String get updateDownloadProgressLabel => 'Ход загрузки';

  @override
  String get updateAllowInstalls =>
      'Разрешите установку из BT Wallet, затем вернитесь.';

  @override
  String get updateInstallCancelled =>
      'Обновление не установлено. Можно попробовать снова.';

  @override
  String updateNotInstalled(String detail) {
    return 'Обновление не установлено: $detail';
  }

  @override
  String updateCannotInstall(String detail) {
    return 'Не удаётся установить обновление: $detail.';
  }

  @override
  String get updateCannotInstallUnknown =>
      'Не удаётся установить обновление: неизвестная ошибка.';

  @override
  String get updateNeedsReinstall =>
      'Это обновление подписано новым ключом, поэтому не может установиться поверх этой версии. Нужна переустановка, а удаление приложения удалит этот кошелёк с устройства: сначала запишите фразу восстановления, затем удалите это приложение и установите новую версию.';

  @override
  String get updateManifestOtherApp =>
      'Сведения об обновлении относятся к другому приложению.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'Ошибка загрузки (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge =>
      'Загруженный файл больше заявленного размера.';

  @override
  String get updateDownloadDamaged =>
      'Загруженный файл повреждён (контрольная сумма не совпадает).';

  @override
  String get updateDownloadInterrupted => 'Загрузка прервана.';

  @override
  String get updateNoTorDownload =>
      'Обновление пока нельзя скачать через Tor. Отключите Tor, чтобы скачать его, или скачайте его со страницы загрузки.';

  @override
  String get updateServerUnreachable =>
      'Не удаётся связаться с сервером обновлений.';

  @override
  String updateServerHttpStatus(int status) {
    return 'Сервер обновлений ответил: HTTP $status.';
  }

  @override
  String get updateServerTimeout => 'Сервер обновлений не ответил вовремя.';

  @override
  String get updateConnectionFailed =>
      'Не удалось подключиться к серверу обновлений.';

  @override
  String get updateCheckFailed => 'Не удалось проверить обновления.';

  @override
  String get setupNetworkSettingsTooltip => 'Узел и Epicbox';

  @override
  String get setupNetworkHeading => 'Сеть';

  @override
  String get setupWalletPerNetwork =>
      'У каждой сети свой кошелёк. Для сети без кошелька будет создан новый.';

  @override
  String get restoreTitle => 'Восстановление кошелька';

  @override
  String get restorePhraseLabel => 'Фраза восстановления';

  @override
  String get restorePhraseHelper =>
      'Все слова (12, 15, 18, 21 или 24) через пробел.';

  @override
  String get restoreStartByMonth => 'Месяц';

  @override
  String get restoreStartByHeight => 'Высота блока';

  @override
  String get restoreStartHeightLabel => 'Начальная высота (необязательно)';

  @override
  String get restoreStartHeightHelper =>
      'Сканировать с этого блока. Оставьте пустым, чтобы просканировать весь блокчейн.';

  @override
  String get restoreBackToPhrase => 'Вернуться к фразе';

  @override
  String get restoreDatePickerTitle => 'Когда вы создали кошелёк?';

  @override
  String get restorePickDate => 'Выберите дату создания кошелька';

  @override
  String restoreFromDate(String date) {
    return 'С $date';
  }

  @override
  String get restoreDateHint =>
      'Необязательно. Если не уверены, выберите более раннюю дату: при более поздней часть средств может не найтись.';

  @override
  String restoreDateStart(String height) {
    return 'Сканирование начнётся за два дня до этой даты, с блока $height.';
  }

  @override
  String get restorePickMonth => 'Выберите месяц создания кошелька';

  @override
  String get restorePickMonthShort => 'Выбрать месяц';

  @override
  String restoreMonthStart(String height) {
    return 'Сканирование начнётся с блока $height.';
  }

  @override
  String get restoreMonthRecent =>
      'Недавний месяц: средства, полученные раньше, могут не найтись.';

  @override
  String get restoreMonthEarlierYear => 'Предыдущий год';

  @override
  String get restoreMonthLaterYear => 'Следующий год';

  @override
  String get restoreScanIntro =>
      'Ищем ваши средства в блокчейне. Не закрывайте приложение до завершения.';

  @override
  String get restoreOpenWallet => 'Открыть кошелёк';

  @override
  String get restoreUnfinishedTitle => 'Восстановление не завершено';

  @override
  String get restoreUnfinishedRunning =>
      'Поиск средств этого кошелька. Получение и отправка станут доступны после завершения.';

  @override
  String get restoreUnfinishedOffline =>
      'Сканирование продолжится, когда «Офлайн» будет выключен.';

  @override
  String get restoreUnfinishedFailed =>
      'Сканирование остановилось и будет повторено автоматически. Получение и отправка недоступны, пока оно не завершится.';

  @override
  String get errorRestoreScanRequired =>
      'Восстановление не завершено. Получение и отправка станут доступны, когда закончится сканирование, показанное на главном экране.';

  @override
  String get restoreScanStop => 'Остановить';

  @override
  String get restoreScanScreenOn => 'Экран не гаснет, пока идёт сканирование.';

  @override
  String get restoreScanStopped =>
      'Остановлено. Получение и отправка станут доступны только после завершения этого сканирования; оно продолжится с главного экрана.';

  @override
  String get restoreScanUnfinished =>
      'Сканирование остановилось раньше конца. Получение и отправка станут доступны только после его завершения: повторите здесь или откройте кошелёк, и оно продолжится с главного экрана.';

  @override
  String get restoreFinishOnHome =>
      'Монеты после выбранного начала найдены. Сканирование с блока 0 завершает восстановление на главном экране; получение и отправка станут доступны после его окончания.';

  @override
  String get unlockDatabaseRebuilt =>
      'База данных кошелька была повреждена и создана заново по фразе. Сканирование возвращает средства; детали платежей, заметки и метки вернутся только из файла данных кошелька.';

  @override
  String get restoreRebuiltImportText =>
      'Файл данных кошелька возвращает историю платежей, контакты, счета и настройки.';

  @override
  String get restoreReplaceLead =>
      'Фраза восстанавливает кошелёк вместо кошелька на этом телефоне. Ничего не меняется, пока фраза не проверена и замена не подтверждена.';

  @override
  String get restoreReplacePinReason =>
      'Введите PIN-код, чтобы заменить этот кошелёк. Восстановленный кошелёк сохранит этот PIN-код.';

  @override
  String restorePhraseUnknownWord(int position, String word) {
    return 'Слова $position («$word») нет в списке слов.';
  }

  @override
  String restorePhraseUnknownWords(String words) {
    return 'Нет в списке слов: $words.';
  }

  @override
  String restorePhraseWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'В этой фразе $count слова. Во фразе восстановления 12, 15, 18, 21 или 24 слова.',
      many:
          'В этой фразе $count слов. Во фразе восстановления 12, 15, 18, 21 или 24 слова.',
      few:
          'В этой фразе $count слова. Во фразе восстановления 12, 15, 18, 21 или 24 слова.',
      one:
          'В этой фразе $count слово. Во фразе восстановления 12, 15, 18, 21 или 24 слова.',
    );
    return '$_temp0';
  }

  @override
  String get restorePhraseChecksum =>
      'Все слова есть в списке, но фраза не сходится. Одно слово неверно или стоит не на своём месте.';

  @override
  String deleteFailedNotice(String error) {
    return 'Кошелёк не удалён. $error Разблокируйте его и повторите попытку в настройках.';
  }

  @override
  String get restoreDoneIconLabel => 'Готово';

  @override
  String get restoreDoneTitle => 'Кошелёк восстановлен';

  @override
  String get restoreImportExplanation =>
      'Фраза восстановления вернула баланс. Чтобы вернуть историю, контакты, счета и настройки, импортируйте экспортированный файл данных кошелька.';

  @override
  String get restoreImportButton => 'Импорт данных кошелька';

  @override
  String get restoreImportNotNow => 'Не сейчас';

  @override
  String get restoreImportLater => 'Импортировать её можно позже в настройках.';

  @override
  String get restoreScanProgressLabel => 'Ход сканирования';

  @override
  String get firstRunTitle => 'Добро пожаловать';

  @override
  String get firstRunCreate => 'Создать новый кошелёк';

  @override
  String get firstRunRestore => 'Восстановить по фразе';

  @override
  String get settingsRestoreReplaces =>
      'Этот кошелёк будет удалён, и его место займёт кошелёк введённой фразы, с тем же PIN-кодом.';

  @override
  String get firstRunSecuring => 'Защищаем кошелёк…';

  @override
  String get workStoppingRecheck => 'Остановка сверки…';

  @override
  String get workTellingDevices => 'Уведомление связанных устройств…';

  @override
  String get workRemovingFiles => 'Удаление файлов кошелька…';

  @override
  String get workClearingKeys => 'Удаление ключей…';

  @override
  String get workChecking => 'Проверка…';

  @override
  String get workOpening => 'Открытие кошелька…';

  @override
  String get workCreating => 'Создание кошелька…';

  @override
  String get workRestoring => 'Восстановление кошелька…';

  @override
  String get workStarting => 'Запуск…';

  @override
  String get firstRunTryAgain => 'Повторить';

  @override
  String get firstRunBiometricsNotSetUp =>
      'Биометрическая разблокировка не настроена. Её можно включить в настройках.';

  @override
  String get backupTitle => 'Фраза восстановления';

  @override
  String get backupPinReason =>
      'Введите PIN-код, чтобы показать фразу восстановления.';

  @override
  String get backupCopyWarning =>
      'Любой, кто увидит слова или их фото, сможет забрать средства.';

  @override
  String get backupConsentTitle => 'Прежде чем увидеть фразу';

  @override
  String get backupConsentWhat =>
      'На следующем экране показаны слова, которые восстанавливают этот кошелёк.';

  @override
  String get backupConsentReady => 'Приготовьте бумагу и ручку.';

  @override
  String get backupCopyAgree => 'Я буду хранить фразу в тайне';

  @override
  String get backupShowPhrase => 'Показать фразу восстановления';

  @override
  String get backupWarningIconLabel => 'Предупреждение';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Запишите эти $count слова на бумаге по порядку. Только с их помощью можно восстановить этот кошелёк.',
      many:
          'Запишите эти $count слов на бумаге по порядку. Только с их помощью можно восстановить этот кошелёк.',
      few:
          'Запишите эти $count слова на бумаге по порядку. Только с их помощью можно восстановить этот кошелёк.',
      one:
          'Запишите это $count слово на бумаге по порядку. Только с его помощью можно восстановить этот кошелёк.',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return 'Слово $number: $word';
  }

  @override
  String get backupCopyTitle => 'Скопировать фразу восстановления?';

  @override
  String get backupCopyBody =>
      'Любой, у кого есть эти слова, может забрать ваши средства. Храните копию в надёжном месте.';

  @override
  String get backupCopied =>
      'Скопировано. Буфер обмена будет очищен через 60 секунд.';

  @override
  String get backupNotCopied => 'Не скопировано. Буфер обмена отклонил текст.';

  @override
  String get unlockTitle => 'Разблокировать кошелёк';

  @override
  String get pinLabel => 'PIN-код';

  @override
  String get pinRepeatLabel => 'Повторите PIN-код';

  @override
  String pinChooseTitle(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Придумайте $digits-значный PIN-код',
      many: 'Придумайте $digits-значный PIN-код',
      few: 'Придумайте $digits-значный PIN-код',
    );
    return '$_temp0';
  }

  @override
  String get pinConfirmTitle => 'Введите PIN-код ещё раз';

  @override
  String get pinChooseDifferent => 'Выбрать другой PIN-код';

  @override
  String get pinMismatch => 'PIN-коды не совпадают. Придумайте PIN-код заново.';

  @override
  String get pinBiometricsIconLabel => 'Биометрия';

  @override
  String get pinBiometricsQuestion => 'Разблокировать по биометрии?';

  @override
  String get pinBiometricsPinStillWorks => 'PIN-код по-прежнему работает.';

  @override
  String get pinBiometricsEnable => 'Использовать биометрию';

  @override
  String get pinBiometricsNotNow => 'Не сейчас';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'До паузы осталось $count попытки.',
      many: 'До паузы осталось $count попыток.',
      few: 'До паузы осталось $count попытки.',
      one: 'До паузы осталась $count попытка.',
    );
    return 'Неверный PIN-код. $_temp0';
  }

  @override
  String pinWrongWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунду',
    );
    return 'Неверный PIN-код. Следующая попытка будет проверена через $_temp0.';
  }

  @override
  String pinWrongWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return 'Неверный PIN-код. Следующая попытка будет проверена через $_temp0.';
  }

  @override
  String pinCheckingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунду',
    );
    return 'Проверка PIN-кода через $_temp0…';
  }

  @override
  String pinCheckingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return 'Проверка PIN-кода через $_temp0…';
  }

  @override
  String get pinChecking => 'Проверка PIN-кода…';

  @override
  String get pinPromptTitle => 'Введите PIN-код';

  @override
  String get pinUseBiometrics => 'Использовать биометрию';

  @override
  String get pinForgot => 'Забыли PIN-код?';

  @override
  String get pinResetTitle => 'Забыли PIN-код';

  @override
  String get pinResetBody =>
      'PIN-код невозможно восстановить. Можно удалить этот кошелёк с устройства и восстановить его с помощью фразы восстановления. Без фразы средства будут потеряны навсегда.';

  @override
  String get pinResetConfirm => 'У меня есть фраза восстановления';

  @override
  String get pinResetKeep => 'Оставить кошелёк';

  @override
  String get pinResetDelete => 'Удалить кошелёк';

  @override
  String get launchTryAgain => 'Повторить';

  @override
  String get unlockStranded =>
      'Этот кошелёк не удалось прочитать как положено. Ничего не удалено. Попробуйте снова после перезагрузки устройства. Если ошибка останется, удалите кошелёк через «Забыли PIN-код?» и восстановите его по фразе восстановления.';

  @override
  String get sendAmountNegative => 'Сумма не может быть отрицательной.';

  @override
  String sendAmountAmbiguous(String asWhole, String asDecimal) {
    return 'Напишите $asWhole или $asDecimal, чтобы сумма была однозначной.';
  }

  @override
  String get sendAmountUnclear =>
      'Напишите сумму без разделителей, например 1234,5, чтобы она была однозначной.';

  @override
  String get sendAmountNoPrice => 'Сейчас нет курса. Введите сумму в EPIC.';

  @override
  String get sendAmountEnterFiatExample => 'Введите сумму, например 10,50';

  @override
  String get sendAmountTooLarge =>
      'Столько EPIC никогда не будет существовать. Проверьте сумму.';

  @override
  String get sendAmountZero => 'Введите сумму больше нуля.';

  @override
  String get scanQrTooltip => 'Сканировать QR-код';

  @override
  String get sendScanButton => 'Сканировать';

  @override
  String get sendChooseContactTooltip => 'Выбрать контакт';

  @override
  String get sendContactsButton => 'Контакты';

  @override
  String get sendFileHelpTooltip => 'Как работает оплата файлом';

  @override
  String sendAmountLabel(String unit) {
    return 'Сумма ($unit)';
  }

  @override
  String sendUseUnit(String unit) {
    return 'В $unit';
  }

  @override
  String get sendMax => 'Макс.';

  @override
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String get sendCopyPasteInstead => 'Или скопируйте и вставьте текст';

  @override
  String get sendSlateBoxTitle => 'Текст транзакции';

  @override
  String get sendPasteResponseLabel => 'Вставьте ответ получателя';

  @override
  String get sendPasteResponseMissing => 'Вставьте текст ответа от получателя.';

  @override
  String get slateFinishPayment => 'Завершить платёж';

  @override
  String sendResultAutoCancel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Если через $_temp0 платёж всё ещё не будет завершён, он отменится сам и сумма разблокируется. Чтобы остановить его раньше, откройте платёж и нажмите «Отменить платёж».';
  }

  @override
  String sendResultFeeChanged(String charged, String reviewed) {
    return 'Списана комиссия $charged, а не $reviewed, как было показано ранее: при отправке кошелёк заново подобрал монеты.';
  }

  @override
  String get sendResultNoteNotSaved =>
      'Не удалось сохранить заметку. Её можно добавить, открыв платёж.';

  @override
  String get sendHelp => 'Справка';

  @override
  String get sendReviewTotal => 'Итого';

  @override
  String sendReviewSendButton(String amount) {
    return 'Отправить $amount';
  }

  @override
  String get sendReviewEdit => 'Изменить';

  @override
  String get slateFileTitle => 'Файл транзакции';

  @override
  String get slateWrongPayment =>
      'Этот ответ относится к другому платежу. Откройте файл, который получатель вернул для этой отправки.';

  @override
  String get slateNotTransactionFile => 'Это не файл транзакции.';

  @override
  String get slateReading => 'Чтение файла';

  @override
  String get slateReadingQr => 'Чтение платежа';

  @override
  String get slateFileTooLarge =>
      'Этот файл слишком большой для файла транзакции.';

  @override
  String slatePostedHeadline(String amount) {
    return 'Платёж на $amount отправлен в сеть.';
  }

  @override
  String slatePostedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подтверждения',
      many: '$count подтверждений',
      few: '$count подтверждений',
      one: '$count подтверждения',
    );
    return 'Статус «Завершён» появится после $_temp0.';
  }

  @override
  String slateAcceptedHeadline(String file) {
    return 'Принято. Верните $file отправителю.';
  }

  @override
  String slateAcceptedBody(String amount) {
    return 'Сумма $amount поступит, когда отправитель завершит платёж и он попадёт в блокчейн.';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return 'Уже принято. Верните $file отправителю ещё раз.';
  }

  @override
  String slateRepeatedBody(String amount) {
    return 'Вы уже приняли этот платёж, поэтому это тот же ответ, а не второй платёж. Сумма $amount поступит, когда отправитель завершит платёж и он попадёт в блокчейн.';
  }

  @override
  String slateIncomingSend(String amount) {
    return 'Вам отправляют $amount.';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'Ответ получателя на вашу отправку: $amount (комиссия $fee).';
  }

  @override
  String get slateIncomingSendHint =>
      'Примите его, затем верните файл ответа отправителю.';

  @override
  String get slateIncomingResponseHint =>
      'Завершите платёж, чтобы отправить его в сеть.';

  @override
  String get slateAcceptPayment => 'Принять платёж';

  @override
  String slateHandOverFailed(String file) {
    return 'Не удалось передать $file. Повторите попытку.';
  }

  @override
  String get slateSaveToDevice => 'Сохранить на устройстве';

  @override
  String slateSaved(String file) {
    return 'Сохранено: $file';
  }

  @override
  String get slateSaveDialogTitle => 'Сохранить файл транзакции';

  @override
  String get slateOpenDialogTitle => 'Открыть файл транзакции';

  @override
  String get slateNotPostedTitle => 'Пока не в сети';

  @override
  String get slateNotPostedBody =>
      'Платёж завершён, но сеть его ещё не приняла. Он будет повторно передан в сеть со страницы платежа. Не отправляйте эту сумму ещё раз.';

  @override
  String get slateOpenPayment => 'Открыть платёж';

  @override
  String get scanQrTitle => 'Сканирование QR-кода';

  @override
  String get scanQrHint => 'Наведите камеру на QR-код получателя.';

  @override
  String get scanPhraseFoundQr =>
      'Этот QR-код содержит фразу восстановления. Храните её в тайне.';

  @override
  String get scanPhraseFoundPasted =>
      'Это фраза восстановления, поэтому она не вставлена. Храните её в тайне.';

  @override
  String get scanQrPhraseHint =>
      'Наведите камеру на QR-код фразы восстановления.';

  @override
  String get restoreScanNoPhrase => 'В этом QR-коде нет фразы восстановления.';

  @override
  String get scanQrCameraDenied =>
      'Доступ к камере выключен. Разрешите его в настройках телефона или вставьте адрес.';

  @override
  String get scanQrCameraFailed =>
      'Не удалось запустить камеру. Вставьте адрес вручную или повторите попытку.';

  @override
  String get scanQrTryAgain => 'Повторить';

  @override
  String get scanQrBack => 'Назад';

  @override
  String get qrShowReplyAsQr => 'Показать ответ как QR';

  @override
  String get qrShowTitlePayment => 'QR платежа';

  @override
  String get qrShowTitleReply => 'QR ответа';

  @override
  String qrShowSubPayment(String amount) {
    return '$amount на телефон рядом с вами';
  }

  @override
  String qrShowSubReply(String amount) {
    return 'Отправителю $amount';
  }

  @override
  String get qrHiddenTitle => 'Скрыт, пока вы его не покажете';

  @override
  String get qrHiddenBodyPayment =>
      'Тот, кто отсканирует его первым, сможет принять этот платёж. Показывайте его только тому, кому платите.';

  @override
  String get qrHiddenBodyReply =>
      'Покажите его телефону отправителя. Использовать его сможет только его кошелёк.';

  @override
  String get qrShow => 'Показать QR';

  @override
  String get qrShowAgain => 'Показать снова';

  @override
  String get qrHide => 'Скрыть';

  @override
  String qrCountdownLabel(int seconds) {
    return 'Показ через $seconds';
  }

  @override
  String qrPartOf(int part, int count) {
    return 'Часть $part из $count';
  }

  @override
  String qrSecondsShort(int seconds) {
    return '$seconds с';
  }

  @override
  String qrSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Осталось $seconds секунды',
      many: 'Осталось $seconds секунд',
      few: 'Осталось $seconds секунды',
      one: 'Осталась 1 секунда',
    );
    return '$_temp0';
  }

  @override
  String get qrHoldHint => 'Поднесите камеру другого телефона к этому коду.';

  @override
  String get qrSecureLine => 'Скриншоты на этом экране отключены';

  @override
  String qrTimedOutTitle(int seconds) {
    return 'Скрыт через $seconds с';
  }

  @override
  String get qrTimedOutBody =>
      'Покажите его снова, когда другой телефон будет готов.';

  @override
  String get qrAwayTitle => 'Скрыт, пока приложение было свёрнуто';

  @override
  String get qrAwayBody => 'Код скрывается, когда приложение уходит с экрана.';

  @override
  String qrSemanticsPayment(String state) {
    return 'QR-код платежа, $state';
  }

  @override
  String qrSemanticsReply(String state) {
    return 'QR-код ответа, $state';
  }

  @override
  String get qrStateHidden => 'скрыт';

  @override
  String get qrStateShowing => 'виден';

  @override
  String get qrScanPayment => 'Сканировать QR платежа';

  @override
  String get qrScanReply => 'Сканировать ответ';

  @override
  String get qrScanAimPayment => 'Наведите камеру на QR-код на их телефоне.';

  @override
  String get qrScanAimReply => 'Наведите камеру на ответ на их телефоне.';

  @override
  String get qrScanSteady => 'Держите ровнее или подойдите немного ближе.';

  @override
  String get qrScanGot => 'Код считан';

  @override
  String qrScanCount(int got, int count) {
    return '$got из $count';
  }

  @override
  String get qrScanCountLabel => 'Прочитанные части';

  @override
  String get qrScanNotPayment =>
      'Это не QR платежа. Попросите их показать QR платежа.';

  @override
  String get qrScanNotReply =>
      'Это не QR ответа. Попросите их показать ответ на своём телефоне.';

  @override
  String get qrScanOtherPayment =>
      'Этот код относится к другому платежу. Начинаем сначала.';

  @override
  String get qrScanTorch => 'Фонарик';

  @override
  String qrScanZoom(String factor) {
    return 'Масштаб $factor×';
  }

  @override
  String get qrScanCameraDenied =>
      'Доступ к камере выключен. Разрешите его в настройках телефона или откройте файл.';

  @override
  String get qrScanCameraFailed =>
      'Не удалось запустить камеру. Попробуйте ещё раз или откройте файл.';

  @override
  String get qrScanOpenSettings => 'Открыть настройки';

  @override
  String get qrScanOpenFileInstead => 'Открыть файл вместо этого';

  @override
  String get qrScanAgain => 'Сканировать снова';

  @override
  String get slateWrongPaymentQr =>
      'Этот ответ относится к другому платежу. Отсканируйте ответ для этой отправки.';

  @override
  String get slateScannedPaymentTitle => 'Отсканированный платёж';

  @override
  String get slateScannedReplyTitle => 'Отсканированный ответ';

  @override
  String get slateIncomingSendHintQr =>
      'Примите его, затем покажите ответ отправителю.';

  @override
  String get slateAcceptedHeadlineQr => 'Принято. Покажите ответ отправителю.';

  @override
  String get methodQr => 'Оплата по QR';

  @override
  String get methodArtCaptionQr => 'Лично';

  @override
  String get methodSendQrTitle => 'Для телефона рядом с вами.';

  @override
  String get methodSendQrLine =>
      'Покажите код на этом экране, затем отсканируйте их ответ камерой.';

  @override
  String get methodReceiveQrTitle => 'Отсканируйте их экран.';

  @override
  String get methodReceiveQrLine =>
      'Примите платёж, затем покажите свой ответ так же.';

  @override
  String get receiveQrTitle => 'Рядом с другим телефоном?';

  @override
  String get receiveQrBody =>
      'Или запросите сумму: покажите QR для сканирования.';

  @override
  String get txQrHint =>
      'Оплата по QR показывает платёж как анимированный код, который другой телефон сканирует камерой, а ответ принимает так же. Работает только между телефонами рядом, не требует связи между двумя кошельками, а код сам скрывается через 40 секунд. Добавляет «Оплата по QR» в «Отправить» и «Получить».';

  @override
  String get advTransactionFiles => 'Напрямую · Передача файла';

  @override
  String get advTransactionFilesHint =>
      'Добавляет «Передачу файла» в Настройки › Транзакции: платите или получайте платежи файлом, который вы передаёте сами.';

  @override
  String get sendMakeQr => 'Создать QR платежа';

  @override
  String sendQrPinReason(String amount) {
    return 'Введите PIN, чтобы создать QR платежа на $amount.';
  }

  @override
  String get sendQrHint =>
      'Покажите код телефону получателя, затем отсканируйте его ответ.';

  @override
  String get sendCancelRuleQr =>
      'Можно отменить, пока вы не отсканировали ответ.';

  @override
  String get qrStatusSendHidden => 'Покажите это получателю.';

  @override
  String get qrStatusSendShowing =>
      'Ждём, пока получатель отсканирует. Затем отсканируйте его ответ.';

  @override
  String get qrStatusHiddenAgain => 'Скрыт';

  @override
  String get qrStatusReplyHidden => 'Скрыт';

  @override
  String get qrStatusReplyShowing => 'Ждём, пока отправитель отсканирует.';

  @override
  String get qrStatusReceivedWaiting =>
      'Платёж получен. Ждём, пока отправитель отсканирует и отправит его.';

  @override
  String qrStatusPosted(int got, int target) {
    return 'Отправлено. Подтверждение $got/$target';
  }

  @override
  String get qrStatusReceived => 'Получено.';

  @override
  String qrScanProgress(int got, int count) {
    return 'Отсканировано $got из $count. Держите код в кадре.';
  }

  @override
  String get qrScanReplyScanned => 'Ответ отсканирован.';

  @override
  String get qrScanPosting => 'Ответ отсканирован. Отправляем…';

  @override
  String get qrScanPosted => 'Отправлено.';

  @override
  String get contactsTitle => 'Контакты';

  @override
  String get contactsPickTitle => 'Выберите контакт';

  @override
  String get contactsAdd => 'Добавить контакт';

  @override
  String get contactsNameMissing => 'Введите имя.';

  @override
  String contactsDeleteTitle(String name) {
    return 'Удалить контакт «$name»?';
  }

  @override
  String get contactsDeleteBody =>
      'Адрес будет удалён из контактов. Прошлые платежи это не затронет.';

  @override
  String get contactsKeep => 'Оставить';

  @override
  String get contactsEditTitle => 'Изменить контакт';

  @override
  String get contactsNewTitle => 'Новый контакт';

  @override
  String get contactsDeleteTooltip => 'Удалить контакт';

  @override
  String get contactsNameLabel => 'Имя';

  @override
  String contactsDuplicate(String name) {
    return 'Этот адрес уже сохранён как «$name».';
  }

  @override
  String get contactsNoteLabel => 'Заметка (необязательно)';

  @override
  String get contactsSave => 'Сохранить контакт';

  @override
  String get contactsAddressMissing => 'Введите адрес.';

  @override
  String contactsUrlIncomplete(String example) {
    return 'Введите полный URL кошелька, например $example';
  }

  @override
  String get contactsAddressInvalidAny =>
      'Недействительный адрес. Используйте адрес Epicbox (es5x…@сервер), адрес ссылки (https://…) или onion-адрес (….onion).';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionDisplay => 'Внешний вид';

  @override
  String get settingsCurrency => 'Валюта';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Показывать цены';

  @override
  String get settingsHideBalances => 'Скрыть суммы';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsPricesOnNotice =>
      'Цены берутся из CoinGecko; этот сервис видит ваш IP-адрес.';

  @override
  String get settingsSectionSecurity => 'Безопасность';

  @override
  String get settingsChangePin => 'Изменить PIN-код';

  @override
  String get settingsBiometrics => 'Разблокировка биометрией';

  @override
  String get settingsBiometricsOff => 'Биометрическая разблокировка выключена';

  @override
  String get settingsBiometricsFailed =>
      'Биометрическая разблокировка не настроена';

  @override
  String get settingsBiometricsPinReason =>
      'Введите PIN-код, чтобы включить биометрическую разблокировку.';

  @override
  String get settingsAutoLock => 'Автоблокировка';

  @override
  String get settingsBackupPhrase => 'Сохранить фразу восстановления';

  @override
  String get settingsPhraseConfirmed => 'Фраза восстановления подтверждена';

  @override
  String get settingsLockWallet => 'Заблокировать кошелёк';

  @override
  String get settingsSectionHistory => 'Данные кошелька';

  @override
  String get settingsExportHistory => 'Экспорт данных кошелька';

  @override
  String get settingsExportCsv => 'Экспорт в CSV';

  @override
  String get settingsImportHistory => 'Импорт данных кошелька';

  @override
  String get settingsSectionWallet => 'Этот кошелёк';

  @override
  String get settingsContacts => 'Контакты';

  @override
  String get settingsInvoices => 'Счета';

  @override
  String get settingsInvoicesSubtitle => 'Кто может просить вас об оплате';

  @override
  String get settingsRescan => 'Сверка баланса';

  @override
  String get settingsRescanFinished => 'Баланс сверен';

  @override
  String get settingsRescanTitle => 'Сверка баланса';

  @override
  String get settingsRescanBody =>
      'Заново проверяет блокчейн на наличие средств этого кошелька.';

  @override
  String get settingsRescanButton => 'Сверить';

  @override
  String get settingsDeleteWallet => 'Удалить кошелёк';

  @override
  String get settingsDeleteDuringScan =>
      'Дождитесь окончания сканирования, прежде чем удалять кошелёк.';

  @override
  String get settingsDeletePinReason =>
      'Введите PIN-код, чтобы удалить этот кошелёк.';

  @override
  String get settingsDeleteWarningIcon => 'Предупреждение';

  @override
  String get settingsDeleteTitle => 'Удалить этот кошелёк?';

  @override
  String get settingsDeleteBody =>
      'Кошелёк, его история и PIN-код будут удалены с этого телефона. Вернуть средства можно только с помощью фразы восстановления. Без неё они будут потеряны навсегда.';

  @override
  String get settingsDeleteHavePhrase => 'Фраза восстановления у меня записана';

  @override
  String get settingsDeleteConfirmWord => 'удалить';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return 'Введите «$word»';
  }

  @override
  String get settingsDeleteKeep => 'Оставить кошелёк';

  @override
  String get settingsDeleteConfirm => 'Удалить кошелёк';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsAboutNetwork => 'Сеть';

  @override
  String get settingsCheckUpdates => 'Проверить обновления';

  @override
  String settingsUpdatesFrom(String store) {
    return 'Обновления устанавливает $store.';
  }

  @override
  String get settingsHelp => 'Справка';

  @override
  String get settingsSendFeedback => 'Сообщить о проблеме';

  @override
  String get settingsSendFeedbackHint =>
      'Сообщите о проблеме или предложите разработчикам идею. Журналы отправляются, только если вы их приложите; фраза восстановления, PIN-код и другие секретные данные удаляются заранее.';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsLicences => 'Лицензии';

  @override
  String get licencesLead =>
      'Открытое ПО в этом кошельке, каждое под своей лицензией.';

  @override
  String get licencesApp => 'BT Wallet от BT Labs: Apache-2.0.';

  @override
  String get licencesFlutter =>
      'Flutter и его пакеты Dart: BSD 3-Clause и похожие разрешительные лицензии.';

  @override
  String get licencesLepic =>
      'LEPIC, библиотека кошелька Epic Cash: Apache-2.0, с форком secp256k1-zkp от Epic Cash (CC0) и крейтами Rust под MIT или Apache-2.0, среди них tokio, rustls, rusqlite и blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, версия 3. Исходный код указан ниже.';

  @override
  String get licencesFonts =>
      'Шрифты Montserrat, JetBrains Mono, Geist, Geist Mono и Noto Sans Thai: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'Все тексты лицензий';

  @override
  String licencesPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лицензии',
      many: '$count лицензий',
      few: '$count лицензии',
      one: '$count лицензия',
    );
    return '$_temp0';
  }

  @override
  String get settingsCopyLink => 'Копировать ссылку';

  @override
  String get settingsLinkCopied => 'Ссылка скопирована';

  @override
  String get settingsPinTitle => 'Изменить PIN-код';

  @override
  String get settingsPinEnterCurrent => 'Введите текущий PIN-код';

  @override
  String get settingsPinCurrentLabel => 'Текущий PIN-код';

  @override
  String get settingsPinNewLabel => 'Новый PIN-код';

  @override
  String settingsPinChooseNew(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Придумайте новый $digits-значный PIN-код',
      many: 'Придумайте новый $digits-значный PIN-код',
      few: 'Придумайте новый $digits-значный PIN-код',
    );
    return '$_temp0';
  }

  @override
  String get settingsPinChanged => 'PIN-код изменён';

  @override
  String get settingsPinChangedBiometricsOff =>
      'PIN-код изменён. Биометрическая разблокировка выключена; включите её снова ниже.';

  @override
  String get helpTitle => 'Справка';

  @override
  String get helpStillStuck => 'Остались вопросы?';

  @override
  String get helpTellUs => 'Расскажите, что произошло или что непонятно.';

  @override
  String get helpSendFeedback => 'Сообщить о проблеме';

  @override
  String get feedbackTitle => 'Сообщить о проблеме';

  @override
  String get feedbackIntro =>
      'Расскажите, что пошло не так или что можно улучшить.';

  @override
  String get feedbackMessageLabel => 'Что произошло';

  @override
  String get feedbackMessageMissing =>
      'Напишите пару слов о том, что произошло.';

  @override
  String get feedbackAttachLogs => 'Приложить журналы';

  @override
  String get feedbackAttachLogsHint =>
      'Последняя часть журнала приложения, без фразы восстановления, PIN-кода и других секретных данных.';

  @override
  String get feedbackPreviewButton => 'Что отправляется';

  @override
  String get feedbackSend => 'Отправить';

  @override
  String get feedbackShareOrSaveInstead => 'Поделиться или сохранить';

  @override
  String get feedbackFileExplanation =>
      'Ваш отзыв будет сохранён в текстовый файл, которым можно поделиться или который можно сохранить.';

  @override
  String get feedbackShareOrSave => 'Поделиться или сохранить';

  @override
  String get feedbackShareHint => 'Передайте файл другому приложению';

  @override
  String get feedbackSaveToDevice => 'Сохранить на устройстве';

  @override
  String get feedbackSaveDialogTitle => 'Сохранить отзыв';

  @override
  String feedbackSavedFile(String name) {
    return 'Сохранено: $name';
  }

  @override
  String get feedbackSent => 'Спасибо. Ваш отзыв отправлен.';

  @override
  String get feedbackThanks => 'Спасибо за отзыв.';

  @override
  String feedbackServerAnswered(int status) {
    return 'Сервер отзывов ответил: $status.';
  }

  @override
  String get feedbackServerNoAnswer => 'Сервер отзывов не ответил.';

  @override
  String get feedbackServerUnreachable =>
      'Не удалось связаться с сервером отзывов.';

  @override
  String get feedbackPreviewTitle => 'Что будет отправлено';

  @override
  String get settingsSectionPrivacy => 'Приватность';

  @override
  String get settingsSectionPrivacyNetwork => 'Приватность и сеть';

  @override
  String get settingsSectionNetworkPrivacy => 'Сеть и приватность';

  @override
  String get netSummaryTorOn => 'Tor включён';

  @override
  String get netSummaryTorOff => 'Tor выключен';

  @override
  String get netPageServers => 'Серверы';

  @override
  String get settingsSectionHelpFeedback => 'Справка';

  @override
  String get settingsExperimentTag => 'Эксперимент';

  @override
  String get settingsStateBackUp => 'Сохраните фразу восстановления';

  @override
  String get settingsStateNotBackedUp => 'Ещё не сохранена';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String settingsUseStatusSite(String site) {
    return 'Использовать $site';
  }

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Показывает, какие узлы и серверы Epicbox в сети, по публичному списку на status.btlabs.uk.';

  @override
  String get txStepStarted => 'Платёж начат';

  @override
  String get txStepAccepted => 'Получатель подписал';

  @override
  String get txStepPosted => 'Отправлен в сеть';

  @override
  String get txStepConfirming => 'Подтверждение';

  @override
  String get txStepConfirmed => 'Подтверждён';

  @override
  String get txStepArrived => 'Платёж получен';

  @override
  String get txStepSenderFinished => 'Подписано и возвращено';

  @override
  String get fileHelpTitle => 'Как работает файл транзакции';

  @override
  String get fileHelpYou => 'Вы';

  @override
  String get fileHelpFriend => 'Друг';

  @override
  String get fileHelpSendStep1 => 'Вы создаёте файл транзакции.';

  @override
  String get fileHelpSendStep2 =>
      'Вы отправляете его другу любым удобным способом, например в мессенджере или на флешке.';

  @override
  String get fileHelpSendStep3 =>
      'Друг открывает его в своём кошельке и присылает вам файл ответа.';

  @override
  String get fileHelpSendStep4 =>
      'Вы открываете файл ответа, и платёж уже в пути.';

  @override
  String get fileHelpReceiveStep1 => 'Друг создаёт для вас файл транзакции.';

  @override
  String get fileHelpReceiveStep2 =>
      'Он отправляет его вам любым удобным способом, например в мессенджере или на флешке.';

  @override
  String get fileHelpReceiveStep3 =>
      'Вы открываете его в своём кошельке и отправляете файл ответа.';

  @override
  String get fileHelpReceiveStep4 =>
      'Друг открывает файл ответа, и платёж уже в пути к вам.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Шаг $step из $count';
  }

  @override
  String get fileHelpPause => 'Приостановить анимацию';

  @override
  String get fileHelpPlay => 'Воспроизвести анимацию';

  @override
  String get sendStepMethod => 'Способ оплаты';

  @override
  String get sendStepAmount => 'Сумма';

  @override
  String get sendStepReview => 'Проверка';

  @override
  String sendStepOf(int step, int total) {
    return '$step из $total';
  }

  @override
  String get sendHowItWorks => 'Как это работает';

  @override
  String get sendAddressMissing => 'Введите адрес получателя.';

  @override
  String get sendAddressIncomplete => 'Адрес выглядит неполным.';

  @override
  String get sendAddressNotEpic => 'Это не адрес Epicbox.';

  @override
  String get sendNewRecipient => 'Новый получатель';

  @override
  String get sendSaveContact => 'Сохранить в контакты';

  @override
  String get sendRecent => 'Недавние';

  @override
  String sendTo(String who) {
    return 'Кому: $who';
  }

  @override
  String sendAvailable(String amount) {
    return 'Доступно $amount';
  }

  @override
  String sendFeeQuiet(String fee) {
    return 'Комиссия сети $fee';
  }

  @override
  String get sendAddNote => 'Добавить сообщение';

  @override
  String get sendNoteLabel => 'Сообщение';

  @override
  String get sendNoteHelper => 'Получатель его увидит.';

  @override
  String get sendReviewMessageKept =>
      'Получатель его увидит. Копия сохранится как ваша личная заметка.';

  @override
  String get sendNetworkFee => 'Комиссия сети';

  @override
  String get sendChecking => 'Проверка…';

  @override
  String get sendReady => 'Готово к отправке';

  @override
  String get sendNodeDown => 'Сеть сейчас недоступна.';

  @override
  String sendRelayDown(String relay) {
    return 'Сервер Epicbox получателя ($relay) не отвечает.';
  }

  @override
  String get sendListenerDown => 'Ещё нет подключения. Отправить можно.';

  @override
  String get sendPayWithFile => 'Оплатить файлом';

  @override
  String get sendAnyway => 'Всё равно отправить';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Ждём кошелёк: $name';
  }

  @override
  String get sendTrackWaiting => 'Ждём кошелёк получателя';

  @override
  String sendTrackOffline(String amount) {
    return 'Кошелёк получателя подпишет платёж, когда откроется. До тех пор $amount заблокировано.';
  }

  @override
  String get sendTrackIfNot => 'А если платёж не завершится?';

  @override
  String get sendTrackCancelled => 'Этот платёж отменён.';

  @override
  String get sendNoCoins => 'Пока нет монет для отправки.';

  @override
  String get sendFileTitle => 'Напрямую · Передача файла';

  @override
  String get sendMakeFile => 'Создать файл транзакции';

  @override
  String sendFileOnHold(String amount) {
    return '$amount заблокировано';
  }

  @override
  String get sendFileWaitingReply => 'Ждём файл ответа';

  @override
  String get sendFileShareHint =>
      'Отправьте им этот файл, затем откройте их файл ответа.';

  @override
  String get sendOpenReply => 'Открыть файл ответа';

  @override
  String get handshakeRequest => 'Счёт';

  @override
  String get handshakeYou => 'Вы';

  @override
  String get handshakeThem => 'Они';

  @override
  String get handshakeNetwork => 'Сеть';

  @override
  String get handshakePay1 =>
      'Ваш кошелёк отправляет платёж на сервер Epicbox. Монеты блокируются.';

  @override
  String get handshakePay2 =>
      'Сервер передаёт его дальше. Их кошелёк добавляет свою часть и подписывает.';

  @override
  String get handshakeFinish =>
      'Ваш кошелёк завершает его и отправляет в сеть.';

  @override
  String get handshakeConfirm => 'Сеть его подтверждает.';

  @override
  String get handshakeReq1 => 'Ваш кошелёк отправляет счёт на сервер Epicbox.';

  @override
  String get handshakeReq2 =>
      'Сервер передаёт его дальше. Они одобряют его, их кошелёк добавляет монеты и подписывает.';

  @override
  String get handshakeRelay => 'Сервер Epicbox';

  @override
  String get handshakeFile => 'Передача файла';

  @override
  String get handshakeBack =>
      'Их кошелёк отправляет его обратно на сервер Epicbox.';

  @override
  String get handshakeRelayBack =>
      'Сервер передаёт его обратно вашему кошельку.';

  @override
  String get handshakeFile1 =>
      'Ваш кошелёк сохраняет файл транзакции. Вы сами отправляете его им.';

  @override
  String get handshakeFile2 =>
      'Они открывают его. Их кошелёк добавляет свою часть, подписывает и сохраняет файл ответа.';

  @override
  String get handshakeFile3 => 'Они отправляют вам файл ответа.';

  @override
  String get handshakeFile4 => 'Вы открываете их файл ответа в своём кошельке.';

  @override
  String get handshakePrevious => 'Предыдущий шаг';

  @override
  String get handshakeLink1 =>
      'Ваш кошелёк отправляет платёж прямо их кошельку, через интернет или Tor. Монеты блокируются.';

  @override
  String get handshakeLink2 =>
      'Их кошелёк добавляет свою часть, подписывает и отвечает по тому же соединению.';

  @override
  String get handshakeQr1 => 'Вы показываете свой код.';

  @override
  String get handshakeQr2 => 'Они сканируют его своим кошельком.';

  @override
  String get handshakeQr3 => 'Их кошелёк показывает код ответа.';

  @override
  String get handshakeQr4 => 'Вы сканируете его.';

  @override
  String get handshakeQr5 => 'Ваш кошелёк отправляет платёж в сеть.';

  @override
  String get handshakeQrR1 => 'Они показывают свой код.';

  @override
  String get handshakeQrR2 => 'Вы сканируете его своим кошельком.';

  @override
  String get handshakeQrR3 => 'Ваш кошелёк показывает код ответа.';

  @override
  String get handshakeQrR4 => 'Они сканируют его.';

  @override
  String get handshakeQrR5 => 'Их кошелёк отправляет платёж в сеть.';

  @override
  String get handshakeNext => 'Следующий шаг';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Сервер Epicbox получателя ($relay) отклонил платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дня.',
      many:
          'Сервер Epicbox получателя ($relay) отклонил платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дней.',
      few:
          'Сервер Epicbox получателя ($relay) отклонил платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дней.',
      one:
          'Сервер Epicbox получателя ($relay) отклонил платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дня.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Сервер Epicbox получателя ($relay) отклонил платёж. Проверьте «Кошелёк», прежде чем отправлять снова.';
  }

  @override
  String get sendCancelAndFile => 'Отменить и оплатить файлом';

  @override
  String get sendLeaveIt => 'Оставить пока';

  @override
  String get sendSending => 'Отправка…';

  @override
  String trackStepDone(String step) {
    return '$step, выполнено';
  }

  @override
  String trackStepNow(String step) {
    return '$step, сейчас';
  }

  @override
  String trackStepLater(String step) {
    return '$step, позже';
  }

  @override
  String balanceLineOnHold(String amount) {
    return '$amount заблокировано';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount поступает';
  }

  @override
  String get receiveTorAddressLabel => 'Адрес Ссылка · Tor';

  @override
  String get receiveTorQrLabel => 'QR-код вашего адреса Tor';

  @override
  String get torStateOff => 'Приём через Tor выключен';

  @override
  String torStateStarting(int percent) {
    return 'Подключение к Tor… $percent %';
  }

  @override
  String get torStatePublishing => 'Публикация вашего адреса Tor…';

  @override
  String get torStateReady => 'Приём через Tor включён';

  @override
  String torStateNotReachable(String reason) {
    return 'Ваш адрес Tor пока недоступен. $reason';
  }

  @override
  String get torFailureMissing => 'Tor не входит в это приложение.';

  @override
  String get torFailureStart => 'Tor не запустился.';

  @override
  String get torFailureNetwork =>
      'Tor не удалось подключить. Повторите попытку или выключите Tor.';

  @override
  String get torFailureClock =>
      'Часы телефона идут неверно. Tor нужно правильное время.';

  @override
  String get torFailureListener => 'Кошелёк не смог открыть свой адрес Tor.';

  @override
  String get torFailureStopped => 'Tor остановился.';

  @override
  String get torFailurePublish => 'Не удалось опубликовать адрес Tor.';

  @override
  String get torFailureKeys => 'Tor не принял ключ адреса кошелька.';

  @override
  String get sendOnionIncomplete =>
      'Это неполный адрес Tor. Скопируйте его у получателя ещё раз.';

  @override
  String get sendTorUnavailable =>
      'Это приложение не отправляет через Tor, поэтому заплатить на адрес Tor здесь нельзя.';

  @override
  String get sendOverTor => 'Через Tor';

  @override
  String get sendTorReady => 'Готово к отправке через Tor';

  @override
  String get sendTorReaching =>
      'Связываемся с кошельком получателя через Tor… Не закрывайте приложение.';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Не удалось связаться с кошельком получателя через Tor. Сумма заблокирована, пока вы её не отмените, но не дольше $days дня.',
      many:
          'Не удалось связаться с кошельком получателя через Tor. Сумма заблокирована, пока вы её не отмените, но не дольше $days дней.',
      few:
          'Не удалось связаться с кошельком получателя через Tor. Сумма заблокирована, пока вы её не отмените, но не дольше $days дней.',
      one:
          'Не удалось связаться с кошельком получателя через Tor. Сумма заблокирована, пока вы её не отмените, но не дольше $days дня.',
    );
    return '$_temp0';
  }

  @override
  String get sendTorTryEpicbox =>
      'Epicbox доставляет платёж, даже когда кошелёк получателя не в сети.';

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Ничего не отправлено.';
  }

  @override
  String get sendTryAgain => 'Повторить';

  @override
  String get sendCancelPayment => 'Отменить платёж';

  @override
  String get homeAvailableToSpend => 'Доступно';

  @override
  String get homeTileWaitingSender => 'Ожидает отправителя';

  @override
  String get homeTileLocked => 'Заблокировано в отправках';

  @override
  String get homeTileTotal => 'Всего';

  @override
  String homeViewAll(int count) {
    return 'Все $count';
  }

  @override
  String get tourPhoneSemantics => 'Тур по кошельку';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current из $total';
  }

  @override
  String get tourPhoneSkip => 'Пропустить тур';

  @override
  String get tourPhoneBack => 'Назад';

  @override
  String get tourPhoneNext => 'Далее';

  @override
  String get tourPhoneWalletTitle => 'Кошелёк';

  @override
  String get tourPhoneWalletText =>
      'Ваш баланс, а под ним значки узла, Epicbox и Tor. То, что ещё подтверждается, — в плитках ниже.';

  @override
  String get tourPhoneSendTitle => 'Отправить';

  @override
  String get tourPhoneSendText =>
      'Вставьте или отсканируйте адрес либо выберите контакт. Epicbox платит на адрес; QR показывает код телефону рядом с вами. Другие способы: Настройки › Транзакции. Сначала — проверка.';

  @override
  String get tourPhoneReceiveTitle => 'Получить';

  @override
  String get tourPhoneReceiveText =>
      'Ваш адрес Epicbox. Поделитесь им, чтобы получить платёж. Вкладка «Файл» — для файлов транзакций, которые нужно подписать или завершить.';

  @override
  String get tourPhoneActivityTitle => 'Активность';

  @override
  String get tourPhoneActivityText =>
      'Каждый платёж с ходом выполнения и подробностями. Нажмите на платёж, чтобы открыть его.';

  @override
  String get tourPhoneInvoicesTitle => 'Счета';

  @override
  String get tourPhoneInvoicesText =>
      'Оплатите присланный вам счёт или попросите кого-то о платеже. Вкладки переключают между этим и тем.';

  @override
  String get tourPhoneDevicesText =>
      'Этот кошелёк на втором устройстве: каждое показывает платежи другого. Эксперимент.';

  @override
  String get tourPhonePrivacyTitle => 'Приватность и сеть';

  @override
  String get tourPhonePrivacyText =>
      'Какой узел и сервер Epicbox использует кошелёк, и переключатель Tor. Нажмите на сервер, чтобы изменить его.';

  @override
  String get tourPhoneNetworkText =>
      'Режим сети, переключатель Tor и серверы, которые использует кошелёк. Нажмите на сервер, чтобы изменить его.';

  @override
  String get tourPhoneNetworkTextNoTor =>
      'Режим сети и серверы, которые использует кошелёк. Нажмите на сервер, чтобы изменить его.';

  @override
  String get tourPhoneAdvancedTitle => 'Дополнительно';

  @override
  String get tourPhoneAdvancedText =>
      'Режим «Только Tor», выходы и технические сведения собраны здесь. Включайте то, что нужно.';

  @override
  String get tourAdvancedShowsText =>
      'Выходы и технические сведения собраны здесь. Включайте то, что нужно.';

  @override
  String get tourPhoneHelpTitle => 'Справка';

  @override
  String get tourPhoneHelpText =>
      'Темы справки, «Сообщить о проблеме» и «Показать тур снова».';

  @override
  String get tourPhoneShowAgain => 'Показать тур снова';

  @override
  String get homeDestActivity => 'Активность';

  @override
  String get homeDestOutputs => 'Выходы';

  @override
  String get txStatusReceived => 'Получено';

  @override
  String get txStatusSent => 'Отправлено';

  @override
  String sendPinReason(String amount) {
    return 'Введите PIN-код, чтобы отправить $amount.';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'Введите PIN-код, чтобы создать файл транзакции на $amount.';
  }

  @override
  String get outputsTitle => 'Выходы';

  @override
  String get outputsSpendable => 'Доступно';

  @override
  String get outputsConfirming => 'Подтверждается';

  @override
  String get outputsLockedTile => 'Заблокировано в отправках';

  @override
  String outputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выхода',
      many: '$count выходов',
      few: '$count выхода',
      one: '$count выход',
    );
    return '$_temp0';
  }

  @override
  String get outputsSplitButton => 'Разделить…';

  @override
  String get outputsConsolidateButton => 'Объединить…';

  @override
  String get outputsSplitNeeds =>
      'Для разделения нужен минимум 1 EPIC доступных.';

  @override
  String get outputsConsolidateNeeds =>
      'Для объединения нужно минимум 2 доступных выхода.';

  @override
  String outputsWaitLocked(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    return 'Дождитесь, пока у текущего платежа будет $_temp0.';
  }

  @override
  String get outputsStrategy => 'Стратегия отправок';

  @override
  String get outputsStrategyHint =>
      'Какие выходы тратит отправка. «Наименьшие» тратит наименьшие выходы, которых хватает на сумму; «Все» тратит каждый выход и возвращает один.';

  @override
  String get outputsSmallest => 'Наименьшие';

  @override
  String get outputsAll => 'Все';

  @override
  String get outputsSmallestText =>
      'Тратит наименьшие выходы, которых хватает на сумму; остальное остаётся доступным.';

  @override
  String get outputsAllText =>
      'Тратит все доступные выходы и возвращает один выход сдачи. Всё заблокировано до подтверждения; потом выходов меньше и они крупнее.';

  @override
  String get outputsSplitChange => 'Делить сдачу';

  @override
  String get outputsSplitChangeText =>
      'Если после отправки осталось бы меньше 3 доступных выходов, а сдача не меньше 1 EPIC, она вернётся несколькими выходами, до 4, и следующие отправки не будут ждать подтверждений. Каждый лишний выход стоит 0,004 EPIC.';

  @override
  String outputsFilterAll(int count) {
    return 'Все $count';
  }

  @override
  String outputsFilterSpendable(int count) {
    return 'Доступно $count';
  }

  @override
  String outputsFilterConfirming(int count) {
    return 'Подтв. $count';
  }

  @override
  String outputsFilterLocked(int count) {
    return 'Заблок. $count';
  }

  @override
  String get outputsShowSpent => 'Показать потраченные';

  @override
  String get outputsHideSpent => 'Скрыть потраченные';

  @override
  String get outputsWordSpendable => 'Доступно';

  @override
  String get outputsWordConfirming => 'Подтверждается';

  @override
  String get outputsWordFinalizing => 'Ждёт ответа';

  @override
  String get outputsWordImmature => 'Созревает';

  @override
  String get outputsWordMining => 'Майнинг';

  @override
  String get outputsWordLocked => 'Заблокирован';

  @override
  String get outputsWordSpent => 'Потрачен';

  @override
  String get outputsMeanSpendable => 'Можно потратить сейчас.';

  @override
  String outputsMeanConfirming(int need) {
    return 'Можно потратить после подтверждений: $need.';
  }

  @override
  String get outputsMeanFinalizing => 'Ждёт, пока отправитель завершит платёж.';

  @override
  String get outputsMeanImmature =>
      'Награда за майнинг. Её можно потратить после задержки.';

  @override
  String get outputsMeanMining => 'Награда за майнинг, ещё не подтверждена.';

  @override
  String get outputsMeanLocked => 'Тратится отправкой в процессе.';

  @override
  String get outputsMeanSpent => 'Уже потрачен.';

  @override
  String outputsNoteReceived(String date) {
    return 'Получено $date';
  }

  @override
  String outputsNoteSend(String who) {
    return 'Отправка: $who';
  }

  @override
  String get outputsNoteSendPlain => 'Отправка в процессе';

  @override
  String get outputsFactHeight => 'Высота';

  @override
  String get outputsFactConfirmations => 'Подтверждения';

  @override
  String get outputsFactTransaction => 'Транзакция';

  @override
  String get outputsFactCommitment => 'Коммитмент';

  @override
  String get outputsCopy => 'Копировать';

  @override
  String get outputsCopied => 'Коммитмент скопирован';

  @override
  String get outputsEmpty => 'Выходов пока нет';

  @override
  String get outputsEmptyHint => 'Первый полученный платёж создаст его.';

  @override
  String get outputsNoMatch => 'В этом виде выходов нет';

  @override
  String get outputsRetry => 'Повторить';

  @override
  String outputsSettingsSubtitle(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выхода · $strategy',
      many: '$count выходов · $strategy',
      few: '$count выхода · $strategy',
      one: '$count выход · $strategy',
    );
    return '$_temp0';
  }

  @override
  String get outputsCancel => 'Отмена';

  @override
  String get outputsSplitTitle => 'Разделение выходов';

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
      other: '$blocks блока',
      many: '$blocks блоков',
      few: '$blocks блока',
      one: '$blocks блок',
    );
    return 'Тратит $spent ($amount) и создаёт $made по $each. Обычная сетевая транзакция на этот кошелёк, подтверждается через $_temp0, как любая отправка; всё доступное блокируется до этого момента. Несколько выходов позволяют следующим отправкам уходить, не дожидаясь сдачи друг друга.';
  }

  @override
  String get outputsToMake => 'Сколько выходов';

  @override
  String get outputsStepperHint => 'от 2 до 10';

  @override
  String get outputsFactFee => 'Комиссия сети';

  @override
  String get outputsFactEach => 'Каждый выход';

  @override
  String outputsFactAbout(String amount) {
    return 'около $amount';
  }

  @override
  String get outputsFactLocked => 'Заблокировано';

  @override
  String outputsFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks блока',
      many: '$blocks блоков',
      few: '$blocks блоков',
      one: '$blocks блока',
    );
    return '$amount, около $_temp0';
  }

  @override
  String get outputsNothingSpendable =>
      'Тем временем ничего не останется доступным.';

  @override
  String get outputsMinEach => 'Каждый выход должен быть не меньше 0,5 EPIC.';

  @override
  String outputsSplitInto(int count) {
    return 'Разделить на $count';
  }

  @override
  String get outputsConsolidateTitle => 'Объединение выходов';

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
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    return 'Тратит $spent ($amount) и создаёт один выход на $result. Всё доступное заблокировано на $_temp0.';
  }

  @override
  String get outputsConsolidateAction => 'Объединить';

  @override
  String get outputsSplitPin => 'Подтвердите PIN-кодом, чтобы разделить выходы';

  @override
  String get outputsConsolidatePin =>
      'Подтвердите PIN-кодом, чтобы объединить выходы';

  @override
  String outputsSplitStarted(int count, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks блока',
      many: '$blocks блоков',
      few: '$blocks блока',
      one: '$blocks блок',
    );
    return 'Разделение начато, выходов: $count; подтверждение примерно через $_temp0';
  }

  @override
  String outputsConsolidateStarted(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks блока',
      many: '$blocks блоков',
      few: '$blocks блока',
      one: '$blocks блок',
    );
    return 'Объединение начато: один выход, подтверждение примерно через $_temp0';
  }

  @override
  String get outputsAdvanced => 'Управление выходами';

  @override
  String get outputsColState => 'Статус';

  @override
  String get outputsColValue => 'Сумма';

  @override
  String get outputsColConfirmations => 'Подтверждения';

  @override
  String homePendingShort(String amount) {
    return '$amount остаются заблокированными, пока кошелёк получателя не ответит.';
  }

  @override
  String get contactsSearchHint => 'Имя или адрес';

  @override
  String get contactsEmptyTitle => 'Контактов пока нет';

  @override
  String get contactsEmptyCaption => 'Контакт — это имя для адреса.';

  @override
  String contactsNoMatchQuery(String query) {
    return 'Нет контактов по запросу «$query»';
  }

  @override
  String get contactTakesNoPayments => 'Не принимает платежи';

  @override
  String get contactNoPayments => 'Без платежей';

  @override
  String contactNoPaymentsNamed(String name) {
    return '$name не принимает платежи.';
  }

  @override
  String get linkNoPaymentsTitle => 'Не принимает платежи';

  @override
  String get contactsSendAction => 'Отправить';

  @override
  String get contactsNoteHeading => 'Заметка';

  @override
  String get contactsShowCode => 'Показать код';

  @override
  String contactsQrLabel(String name) {
    return 'QR-код адреса: $name';
  }

  @override
  String get contactsDeleteConfirmBody =>
      'После этого платежи на этот адрес показывают адрес вместо имени.';

  @override
  String contactsDeleted(String name) {
    return '$name: удалено.';
  }

  @override
  String get contactsCopied => 'Адрес скопирован.';

  @override
  String get invoicesNewRequest => 'Новый счёт';

  @override
  String get invoicesSegmentSent => 'Отправленные';

  @override
  String invoicesSegmentCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
      zero: 'нет',
    );
    return '$label, $_temp0';
  }

  @override
  String get invoicesSentEmpty => 'Счетов не отправлено';

  @override
  String get invoicesSentEmptyCaption =>
      'Счёт просит кого-то заплатить вам сумму.';

  @override
  String get invoicesWaitingPayment => 'Ожидает оплаты';

  @override
  String get invoicesExpires => 'Истекает';

  @override
  String invoicesUntil(String time) {
    return 'до $time';
  }

  @override
  String get invoicesMessage => 'Сообщение';

  @override
  String get invoicesFrom => 'От';

  @override
  String get invoicesPaysFrom => 'Оплата из';

  @override
  String invoicesAvailable(String amount) {
    return 'Доступно $amount';
  }

  @override
  String invoicesShort(String amount) {
    return 'Недостаточно для оплаты. Не хватает $amount.';
  }

  @override
  String get invoicesCheckNode => 'Узел';

  @override
  String get invoicesCheckEpicbox => 'Epicbox';

  @override
  String get invoicesNodeOk => 'Синхронизирован';

  @override
  String get invoicesNodeDown => 'Не отвечает';

  @override
  String get invoicesEpicboxOk => 'Подключено';

  @override
  String get invoicesEpicboxDown => 'Не подключено';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer получит счёт на оплату $amount. Счёт истекает через 24 ч.';
  }

  @override
  String get netStatusNode => 'Узел';

  @override
  String get netStatusEpicbox => 'Epicbox';

  @override
  String get netStatusTor => 'Tor';

  @override
  String get netStatusSynced => 'Синхронизирован';

  @override
  String get netStatusSyncing => 'Синхронизация';

  @override
  String netStatusSyncingPercent(int percent) {
    return 'Синхронизация $percent %';
  }

  @override
  String get netStatusConnecting => 'Подключение';

  @override
  String netStatusBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отстаёт на $countString',
      many: 'Отстаёт на $countString',
      few: 'Отстаёт на $countString',
      one: 'Отстаёт на $countString',
    );
    return '$_temp0';
  }

  @override
  String get netStatusOffline => 'Не в сети';

  @override
  String get netStatusOff => 'Выключен';

  @override
  String get netStatusConnected => 'Подключено';

  @override
  String get netStatusNotConnected => 'Нет подключения';

  @override
  String get stateReceiving => 'Принимает';

  @override
  String get stateUnchecked => 'Не проверен';

  @override
  String get serverUpNotConnected => 'Сервер работает · нет подключения';

  @override
  String get netStatusOn => 'Включён';

  @override
  String get netStatusTitle => 'Состояние сети';

  @override
  String get netStatusReachable => 'Доступен';

  @override
  String get netStatusPublishing => 'Публикация…';

  @override
  String get netStatusNotReachable => 'Недоступен';

  @override
  String get netStatusTorOpenHint => 'Открывает настройки приватности';

  @override
  String get netStatusDirectOpenHint => 'Открывает адрес для приёма по ссылке';

  @override
  String get netStatusOpenHint => 'Показывает серверы';

  @override
  String get serverNodeTitle => 'Узел';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String serverTestFailed(String error) {
    return 'Нет ответа. $error';
  }

  @override
  String serverHealthUnknown(String site) {
    return '$site недоступен; состояние неизвестно';
  }

  @override
  String get serverAtTip => 'синхронизирован';

  @override
  String serverBehindShort(String count) {
    return 'отстаёт на $count';
  }

  @override
  String serverBehindLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отстаёт на $count блока',
      many: 'отстаёт на $count блоков',
      few: 'отстаёт на $count блока',
      one: 'отстаёт на $count блок',
    );
    return '$_temp0';
  }

  @override
  String get serverNotResponding => 'Не отвечает';

  @override
  String get serverLocalNotReachable => 'Недоступен с этого компьютера';

  @override
  String get serverLocalNotReachablePhone => 'Недоступен с этого телефона';

  @override
  String get serverHealthy => 'Исправен';

  @override
  String get serverDegraded => 'Отстаёт';

  @override
  String get serverHealthNone => 'Состояние неизвестно';

  @override
  String get serverCurrent => 'Используется';

  @override
  String get serverDefault => 'По умолчанию';

  @override
  String serverLatency(String ms) {
    return '$ms мс';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % в сети';
  }

  @override
  String get serverAdd => 'Добавить';

  @override
  String get serverAlreadyInUse => 'Уже используется.';

  @override
  String get serverFactHeight => 'Высота';

  @override
  String get serverFactVersion => 'Версия';

  @override
  String get serverFactPeers => 'Пиры';

  @override
  String get serverFactUptime => 'Доступность 24 ч';

  @override
  String serverHeightAtTip(String height) {
    return '$height · синхронизирован';
  }

  @override
  String serverNodesAgree(String height) {
    return 'Узлы согласны на $height';
  }

  @override
  String serverNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$up из $total узла в сети',
      many: '$up из $total узлов в сети',
      few: '$up из $total узлов в сети',
      one: '$up из $total узла в сети',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'последний блок $seconds с назад',
      many: 'последний блок $seconds с назад',
      few: 'последний блок $seconds с назад',
      one: 'последний блок $seconds с назад',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'последний блок $minutes мин назад',
      many: 'последний блок $minutes мин назад',
      few: 'последний блок $minutes мин назад',
      one: 'последний блок $minutes мин назад',
    );
    return '$_temp0';
  }

  @override
  String serverCheckedAt(String time, String site) {
    return '$site, проверено $time';
  }

  @override
  String serverRowLabel(String host, String facts) {
    return '$host, $facts';
  }

  @override
  String get methodEpicbox => 'Epicbox';

  @override
  String get methodDirectHttp => 'Ссылка · HTTP';

  @override
  String get methodDirectTor => 'Ссылка · Tor';

  @override
  String get methodFile => 'Передача файла';

  @override
  String get methodShortHttp => 'Ссылка · HTTP';

  @override
  String get methodShortTor => 'Ссылка · Tor';

  @override
  String get methodShortQr => 'Напрямую · QR';

  @override
  String get methodShortFile => 'Напрямую · Файл';

  @override
  String get methodGroupHttp => 'HTTP';

  @override
  String get methodGroupTor => 'Tor';

  @override
  String get methodDirectQr => 'Напрямую · Оплата по QR';

  @override
  String get methodDirectFile => 'Напрямую · Передача файла';

  @override
  String get methodDirectFamily => 'Напрямую';

  @override
  String get methodArtCaptionEpicbox => 'Её хранит сервер Epicbox';

  @override
  String get methodArtCaptionHttp => 'Прямо в кошелёк';

  @override
  String get methodArtCaptionFile => 'Файл туда, ответ обратно';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: платёж уходит на сервер Epicbox, который хранит его, пока кошелёк получателя не вернётся';

  @override
  String get methodSendEpicboxTitle => 'Получатель может быть офлайн.';

  @override
  String get settingsShowTipsAgain => 'Снова показывать подсказки';

  @override
  String get settingsShowTipsAgainDone => 'Подсказки снова будут видны';

  @override
  String get tipHide => 'Скрыть подсказку';

  @override
  String get methodSendEpicboxLine =>
      'Сервер Epicbox хранит платёж, пока получатель не откроет кошелёк.';

  @override
  String get methodSendHttpTitle => 'Прямо в кошелёк получателя.';

  @override
  String get methodSendFileTitle => 'Соединение не нужно.';

  @override
  String get methodSendFileLine =>
      'Передайте файл, получите файл ответа и откройте его здесь.';

  @override
  String get methodReceiveEpicboxTitle =>
      'Поделитесь им, чтобы получить оплату.';

  @override
  String get methodReceiveFileTitle => 'Передавайте файл туда и обратно.';

  @override
  String get methodReceiveFileLine =>
      'Работает без соединения между кошельками.';

  @override
  String get methodAddressKindsTooltip => 'Виды адресов';

  @override
  String get sendMethodLabel => 'Способ';

  @override
  String get sendToLabel => 'Кому';

  @override
  String get sendToHint => 'Адрес или контакт';

  @override
  String get sendSwitchedEpicbox => 'Через Epicbox';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Адрес Epicbox. Выбран способ Epicbox.';

  @override
  String get sendCancelRuleEpicbox =>
      'Можно отменить, пока платёж ждёт получателя.';

  @override
  String get sendCancelRuleDirect =>
      'Нельзя отменить после того, как кошелёк получателя его примет.';

  @override
  String get sendCancelRuleFile =>
      'Можно отменить, пока вы не откроете файл ответа.';

  @override
  String get sendHttpReaching =>
      'Связь с кошельком получателя… Не закрывайте приложение.';

  @override
  String get sendDeliveredWaitingBlock => 'Доставлено · Ждёт блок';

  @override
  String get sendPlainHttpOffWithTor =>
      'Обычный http:// не работает при включённом Tor.';

  @override
  String get sendPlainHttpOffWithTorWhy =>
      'Используйте адрес https:// или onion либо Epicbox.';

  @override
  String get receiveTorCaption =>
      'Некоторые кошельки показывают адрес без .onion; это один и тот же адрес.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Не удалось связаться с кошельком получателя. Сумма заблокирована, пока вы её не отмените, но не дольше $days дня.',
      many:
          'Не удалось связаться с кошельком получателя. Сумма заблокирована, пока вы её не отмените, но не дольше $days дней.',
      few:
          'Не удалось связаться с кошельком получателя. Сумма заблокирована, пока вы её не отмените, но не дольше $days дней.',
      one:
          'Не удалось связаться с кошельком получателя. Сумма заблокирована, пока вы её не отмените, но не дольше $days дня.',
    );
    return '$_temp0';
  }

  @override
  String deskInvActFrom(String label) {
    return 'Счёт от $label';
  }

  @override
  String get deskInvActFilter => 'Счета';

  @override
  String get deskInvActBlock => 'Счёт';

  @override
  String get deskInvActOpen => 'Открыть в «Счетах»';

  @override
  String get deskInvActBilledBy => 'Выставил';

  @override
  String get deskInvActOverviewTitle => 'Счета';

  @override
  String deskInvActOverviewToPay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count счёта к оплате',
      many: '$count счетов к оплате',
      few: '$count счёта к оплате',
      one: '$count счёт к оплате',
      zero: 'Нечего оплачивать',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выставленных счёта ждут плательщиков',
      many: '$count выставленных счетов ждут плательщиков',
      few: '$count выставленных счёта ждут плательщиков',
      one: '$count выставленный счёт ждёт плательщика',
      zero: 'Нет ожидающих выставленных счетов',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа требуют действия: повторите или отмените',
      many: '$count платежей требуют действия: повторите или отмените',
      few: '$count платежа требуют действия: повторите или отмените',
      one: '$count платёж требует действия: повторите или отмените',
    );
    return '$_temp0';
  }

  @override
  String get deskInvActReview => 'Проверить';

  @override
  String get deskInvActOpenInvoices => 'Открыть счета';

  @override
  String get deskInvNav => 'Счета';

  @override
  String get deskInvTitle => 'Счета';

  @override
  String get deskInvTabPay => 'Оплатить';

  @override
  String get deskInvTabIssue => 'Выставить';

  @override
  String get deskInvIssueAction => 'Выставить счёт';

  @override
  String get deskInvChecking => 'Проверка';

  @override
  String deskInvCheckedAt(String time) {
    return 'Проверено в $time';
  }

  @override
  String get deskInvCheckFailedTitle => 'Сервер Epicbox не отвечает';

  @override
  String get deskInvCheckFailedBody =>
      'Списки показывают то, что пришло раньше; кошелёк повторит попытку.';

  @override
  String get deskInvReqWaiting => 'Ждёт плательщика';

  @override
  String get deskInvReqPaid => 'Оплачено, завершается';

  @override
  String get deskInvReqPosted => 'Отправлено в сеть';

  @override
  String deskInvConfirming(int count, int total) {
    return 'Подтверждение $count из $total';
  }

  @override
  String get deskInvCompleted => 'Завершено';

  @override
  String get deskInvReqNotPosted => 'Не отправлено';

  @override
  String get deskInvDeclined => 'Отклонено';

  @override
  String get deskInvExpired => 'Истёк';

  @override
  String get deskInvWithdrawn => 'Отозван';

  @override
  String get deskInvReqBounced => 'Возвращён';

  @override
  String get deskInvPayWaiting => 'К оплате';

  @override
  String get deskInvPayNotDelivered => 'Не доставлено';

  @override
  String get deskInvPayDelivered => 'Ждёт отправки';

  @override
  String deskInvPayPosted(String name) {
    return 'Опубликовано: $name';
  }

  @override
  String get deskInvPayWithdrawnAfterPay => 'Отозван после оплаты';

  @override
  String get deskInvPayPastTtl => 'Нет в блокчейне';

  @override
  String get deskInvPayCancelled => 'Отменено';

  @override
  String get deskInvUnpaid => 'Не оплачен';

  @override
  String get deskInvYouPay => 'Вы платите';

  @override
  String deskInvExpiresAt(String time) {
    return 'Истекает $time';
  }

  @override
  String get deskInvSlateId => 'ID слейта';

  @override
  String get deskInvAdvanced => 'Дополнительно';

  @override
  String get deskInvFailed =>
      'Не получилось. Ничего не изменилось; попробуйте ещё раз.';

  @override
  String get deskInvHowItWorks => 'Как работают счета';

  @override
  String get deskInvIssuerSoon => 'Скоро';

  @override
  String get deskInvIssuerAmount => 'Сумма';

  @override
  String get deskInvIssuerAmountMissing => 'Введите сумму.';

  @override
  String get deskInvIssuerAmountZero => 'Сумма должна быть больше 0.';

  @override
  String get deskInvIssuerAmountDecimals =>
      'У EPIC не больше 8 знаков после запятой.';

  @override
  String get deskInvIssuerAmountCap =>
      'Больше, чем всех EPIC, которые когда-либо будут.';

  @override
  String get deskInvIssuerAmountHelp =>
      'Из вашего кошелька ничего не уходит: плательщик платит эту сумму плюс свою комиссию.';

  @override
  String get deskInvIssuerMessage => 'Сообщение плательщику';

  @override
  String deskInvIssuerMessageCount(int used, int max) {
    return '$used / $max байт';
  }

  @override
  String get deskInvIssuerMessageLong => 'Сообщение слишком длинное.';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'У плательщика есть $hours ч на оплату.';
  }

  @override
  String get deskInvIssuerRelayDown =>
      'Сервер Epicbox не отвечает, поэтому счёт сейчас не отправить.';

  @override
  String get deskInvIssuerNotDelivered =>
      'Счёт не дошёл до сервера Epicbox. Ничего не отправлено. Попробуйте ещё раз.';

  @override
  String get deskInvIssuerEmpty =>
      'Счетов пока не выставлено. Счёт просит контакт или сервис заплатить вам; он ничего не тратит.';

  @override
  String deskInvIssuerTo(String payer) {
    return 'Счёт для $payer';
  }

  @override
  String deskInvIssuerIssued(String time) {
    return 'Выставлен $time';
  }

  @override
  String get deskInvIssuerPayerFact => 'Плательщик';

  @override
  String get deskInvIssuerMessageFact => 'Сообщение';

  @override
  String get deskInvIssuerSentFact => 'Выставлен';

  @override
  String get deskInvIssuerExpiresFact => 'Истекает';

  @override
  String get deskInvIssuerAnsweredFact => 'Завершено';

  @override
  String get deskInvIssuerStepPaid => 'Оплачено';

  @override
  String get deskInvIssuerStepConfirming => 'Подтверждение';

  @override
  String get deskInvIssuerEnded =>
      'Этот счёт завершился без оплаты. Ничего не поступило.';

  @override
  String get deskInvIssuerWithdraw => 'Отозвать';

  @override
  String get deskInvIssuerWithdrawTitle => 'Отозвать этот счёт?';

  @override
  String deskInvIssuerWithdrawBody(String payer) {
    return '$payer больше не сможет его оплатить. Ничего не оплачено, монеты не перемещаются.';
  }

  @override
  String get deskInvIssuerKeep => 'Оставить';

  @override
  String get deskInvIssuerWithdrawn => 'Счёт отозван.';

  @override
  String get deskInvIssuerRepost => 'Отправить снова';

  @override
  String get deskInvIssuerReposted => 'Платёж отправлен снова.';

  @override
  String get deskInvIssuerNodeDown =>
      'Узел не отвечает. Попробуйте снова, когда он будет доступен.';

  @override
  String get deskInvIssuerNotPostedText =>
      'Платёж готов, но его нет в сети: узел отклонил его или был недоступен.';

  @override
  String get deskInvIssuerCancel => 'Отменить платёж';

  @override
  String get deskInvIssuerCancelTitle => 'Отменить этот платёж?';

  @override
  String deskInvIssuerCancelBody(String payer) {
    return 'Он не поступит. Средства $payer останутся заблокированными в его кошельке, пока он не отменит платёж у себя.';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return 'Кошелёк $payer не может оплачивать счета; попросите $payer прислать платёж.';
  }

  @override
  String get deskInvIssuerSendFile => 'Через файл';

  @override
  String get deskInvIssuerLate =>
      'После завершения этого счёта пришёл платёж. Он отклонён; ничего не изменилось.';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer оплатил. Ваш кошелёк завершил платёж и отправил его в сеть.';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return 'Доставлено через Epicbox. Ничего не оплачено, пока $payer не одобрит.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Копировать ID слейта';

  @override
  String get deskInvIssuerStepIssued => 'Выставлен';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return 'Оплата от $payer: $amount EPIC.';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return 'Плательщик $payer отклонил ваш счёт.';
  }

  @override
  String get deskInvNoticeIssuedExpired =>
      'Выставленный вами счёт истёк неоплаченным.';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return 'Сервис $service отозвал счёт до вашего ответа.';
  }

  @override
  String get deskInvNoticeExpired => 'Счёт истёк до вашего ответа.';

  @override
  String get deskInvNoticeUnknownPayment =>
      'Пришла оплата счёта, который это устройство не выставляло. Она сутки ждёт на сервере ваше другое устройство с этим кошельком: откройте кошелёк там, чтобы завершить её.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Пришёл ответ на платёж, который это устройство не отправляло. Он сутки ждёт на сервере ваше другое устройство с этим кошельком: откройте кошелёк там, чтобы завершить платёж.';

  @override
  String get deskInvPayerWaitingHead => 'Ждёт вас';

  @override
  String get deskInvPayerNeedsHead => 'Платежи, требующие действия';

  @override
  String get deskInvPayerReview => 'Проверить';

  @override
  String get deskInvPayerPaidHead => 'Оплаченные';

  @override
  String get deskInvPayerView => 'Открыть';

  @override
  String get deskInvPayerNoMessage => 'Нет сообщения';

  @override
  String get deskInvPayerEmptyTitle => 'Нет ожидающих счетов';

  @override
  String get deskInvPayerEmptyText =>
      'Здесь появляются счета от разрешённых сопряжённых контактов; без одобрения ничего не оплачивается.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Ваш платёж сервису $service не доставлен';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Он подписан и хранится на этом компьютере; EPIC остаются заблокированными. «Повторить» отправит его снова без повторного одобрения.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return 'Сервис $service отозвал оплаченный вами счёт';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'Платёж может так и не попасть в блокчейн. Отмените его, чтобы освободить монеты.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Вашего платежа сервису $service нет в блокчейне';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Его срок истёк, и сеть его не видела. Отмените его, чтобы освободить монеты.';

  @override
  String get deskInvPayerCancelPayment => 'Отменить платёж';

  @override
  String get deskInvPayerSafetyTitle => 'Оплачивайте только ожидаемые счета';

  @override
  String get deskInvPayerSafetyText =>
      'Счёт никогда не добавляет деньги в кошелёк. Одобрив его, вы отправляете деньги.';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return 'Вы заплатили сервису $service ту же сумму $ago назад';
  }

  @override
  String get deskInvPayerSameBillText =>
      'Убедитесь, что это новый счёт, прежде чем платить.';

  @override
  String deskInvPayerAgoHours(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String deskInvPayerAgoMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get deskInvPayerFee => 'Комиссия';

  @override
  String get deskInvPayerTotal => 'Итого';

  @override
  String get deskInvPayerBalanceAfter => 'Баланс после';

  @override
  String deskInvPayerMessageCaption(String name) {
    return 'Написано: $name. Кошелёк это не проверяет.';
  }

  @override
  String get deskInvPayerPaysTo => 'Получатель';

  @override
  String get deskInvPayerExpires => 'Истекает';

  @override
  String get deskInvPayerLockHeight => 'Высота блокировки';

  @override
  String get deskInvPayerLockNone => 'Нет';

  @override
  String get deskInvPayerReceived => 'Получено';

  @override
  String get deskInvPayerShort => 'Недостаточно доступных средств';

  @override
  String deskInvPayerShortText(
    String total,
    String spendable,
    int confirmations,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'после $confirmations подтверждения',
      many: 'после $confirmations подтверждений',
      few: 'после $confirmations подтверждений',
      one: 'после $confirmations подтверждения',
    );
    return 'Нужно $total EPIC доступных; у вас $spendable EPIC. Средства на подтверждении учитываются $_temp0.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Узел не отвечает';

  @override
  String get deskInvPayerNodeDownText =>
      'Кошелёк не может проверить средства, поэтому не может заплатить. Одобрение снова заработает, когда узел ответит; другой узел можно выбрать в разделе «Настройки › Узел».';

  @override
  String get deskInvPayerPaid =>
      'Этот счёт оплачен. По нему больше ничего нельзя заплатить.';

  @override
  String get deskInvPayerDeclinedText =>
      'Вы отклонили этот счёт. Ничего не оплачено.';

  @override
  String get deskInvPayerBack => 'Назад к счетам';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return 'Заплатить сервису $service $amount EPIC + $fee комиссии?';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC уйдут из кошелька. Введите пароль кошелька для одобрения.';
  }

  @override
  String get deskInvPayerPassword => 'Пароль кошелька';

  @override
  String get deskInvPayerWrongPassword =>
      'Неверный пароль. Ничего не оплачено.';

  @override
  String get deskInvPayerEnterPassword => 'Введите пароль кошелька.';

  @override
  String get deskInvPayerPay => 'Оплатить';

  @override
  String get deskInvPayerCancel => 'Отмена';

  @override
  String get deskInvPayerClose => 'Закрыть';

  @override
  String get deskInvPayerNodeDownPay => 'Узел не отвечает. Ничего не оплачено.';

  @override
  String get deskInvPayerAlreadyAnswered =>
      'На этот счёт уже ответили. Больше ничего не оплачено.';

  @override
  String get deskInvPayerCannotPay =>
      'Этот счёт нельзя оплатить. Ничего не оплачено.';

  @override
  String get deskInvPayerNotDeliveredToast => 'Подписано, не доставлено';

  @override
  String get deskInvPayerNotDeliveredToastText =>
      'Сервер Epicbox не отвечает. Повторите в разделе «Счета › Оплатить»; повторное одобрение не нужно.';

  @override
  String get deskInvPayerRetryFailed => 'Всё ещё не доставлено';

  @override
  String get deskInvPayerRetryFailedText =>
      'Сервер Epicbox не отвечает. Платёж остаётся подписанным на этом устройстве.';

  @override
  String get deskInvPayerCancelTitle => 'Отменить этот платёж?';

  @override
  String get deskInvPayerCancelText =>
      'Другая сторона ещё может завершить этот платёж.';

  @override
  String deskInvPayerCancelWho(String amount, String service) {
    return '$amount EPIC сервису $service';
  }

  @override
  String get deskInvPayerKeepPayment => 'Оставить';

  @override
  String get deskInvPayerOnItsWay => 'Уже в пути: отменить нельзя.';

  @override
  String get deskInvPayerCannotCheck =>
      'Сейчас нельзя проверить сеть; попробуйте снова, когда узел будет доступен.';

  @override
  String get deskInvPayerCancelled => 'Платёж отменён';

  @override
  String get deskInvPayerCancelledText => 'Ваши средства разблокированы.';

  @override
  String get deskInvPayerDeclined => 'Счёт отклонён. Ничего не оплачено.';

  @override
  String get deskInvPayerSpentText => 'Монеты возвращаются на этот кошелёк.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Монеты пока не удалось перевести обратно. Кошелёк повторяет попытку, пока открыт; до этого платёж ещё может пройти.';

  @override
  String get deskInvPayerLocked =>
      'Этот счёт нельзя оплатить: он заблокирован до более позднего блока. Ничего не оплачено.';

  @override
  String get deskInvPayerRelayDownPay =>
      'Сервер Epicbox не отвечает. Ничего не оплачено.';

  @override
  String get deskInvSetTitle => 'Счета';

  @override
  String get deskInvSetExpiry => 'Срок оплаты';

  @override
  String get deskInvSetExpiryHint =>
      'Сколько выставленный счёт остаётся оплачиваемым и сколько полученный ждёт вас. Не больше 48 часов.';

  @override
  String deskInvSetHours(int hours) {
    return '$hours ч';
  }

  @override
  String get deskInvSetReceiveHint =>
      'Попросите сопряжённый контакт оплатить или сохраните счёт файлом.';

  @override
  String get helpButton => 'Справка';

  @override
  String get helpSearchHint => 'Поиск по справке';

  @override
  String get helpEnglishOnly => 'Справка пока на английском.';

  @override
  String get helpLanguageLabel => 'Язык справки';

  @override
  String helpNoMatch(String query) {
    return 'Ничего не найдено по запросу «$query»';
  }

  @override
  String helpMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count темы',
      many: '$count тем',
      few: '$count темы',
      one: '$count тема',
    );
    return '$_temp0';
  }

  @override
  String get helpShowHandshake => 'Показать, как это работает';

  @override
  String get helpMoreInSection => 'Ещё в этом разделе';

  @override
  String get sendBalanceAfter => 'Баланс после';

  @override
  String get sendSpendableUntilChange => 'Доступно до подтверждения сдачи';

  @override
  String get sendAvailableWhileConfirms => 'Доступно до подтверждения';

  @override
  String get sendSpendableUntilChangeHint =>
      'Сдача вернётся, когда отправка подтвердится.';

  @override
  String serverSwitched(String host) {
    return 'Переключено на $host';
  }

  @override
  String get methodDirect => 'Ссылка';

  @override
  String methodDirectShape(String port) {
    return 'http://host:$port или xxxx….onion';
  }

  @override
  String get methodSendDirectLine =>
      'Кошелёк получателя должен быть открыт. Платёж на адрес .onion идёт через Tor.';

  @override
  String methodArtSpokenLink(String method) {
    return '$method: платёж идёт прямо в кошелёк получателя, который должен быть открыт';
  }

  @override
  String methodArtSpokenQr(String method) {
    return '$method: код передаётся с одного телефона на другой, стоящий рядом';
  }

  @override
  String methodArtSpokenFile(String method) {
    return '$method: файл транзакции передаётся, возвращается файл ответа, затем отправитель завершает платёж';
  }

  @override
  String get methodReceiveEpicboxShort =>
      'Поделитесь адресом, чтобы получить оплату.';

  @override
  String get methodReceiveEpicboxMore =>
      'Сервер Epicbox хранит платёж, пока этот кошелёк не откроется.';

  @override
  String get methodReceiveDirectTitle => 'Прямо в этот кошелёк.';

  @override
  String get methodReceiveDirectLine => 'Работает, пока приложение открыто.';

  @override
  String methodLineOverTor(String line) {
    return '$line Через Tor.';
  }

  @override
  String get sendSwitchedDirect => 'Адрес ссылки';

  @override
  String get sendSwitchedDirectAnnounce => 'Адрес ссылки. Способ: Ссылка.';

  @override
  String get sendDirectAddressShape =>
      'Адрес ссылки начинается с http:// или https:// либо заканчивается на .onion.';

  @override
  String get torNotOverTor => 'Без Tor';

  @override
  String get torNeeds => 'Link · Tor требует Tor.';

  @override
  String get torTurnOn => 'Включить Tor';

  @override
  String get torTurnOff => 'Выключить Tor';

  @override
  String get torTurnOffCaption =>
      'Действует на все соединения, а не только на этот платёж.';

  @override
  String get torNotConnectedNotice => 'Tor не подключён.';

  @override
  String get torWaiting => 'Ожидание Tor';

  @override
  String get torWordStarting => 'Запуск…';

  @override
  String get torWordNotConnected => 'Нет подключения';

  @override
  String get torSettingsLink => 'Настройки Tor';

  @override
  String get torNetworkLabel => 'Сеть Tor';

  @override
  String get torNetworkHint =>
      'Сетевая активность идёт через сеть Tor. Чтобы получать платежи на адрес Tor, включите «Ссылка · Tor» в Настройки › Транзакции.';

  @override
  String get receiveTabDirect => 'Ссылка';

  @override
  String get receiveDirectNeedsTor => 'Ссылка · Tor требует Tor.';

  @override
  String get receiveDirectMeanwhile => 'Пока поделитесь адресом Epicbox.';

  @override
  String get receiveHttpShowQr => 'Показать QR';

  @override
  String get receiveHttpHideQr => 'Скрыть QR';

  @override
  String get netStatusOverTor => 'через Tor';

  @override
  String get torWayOver => 'Через Tor';

  @override
  String get torWayWaiting => 'Ожидание Tor';

  @override
  String get torWayNotConnected => 'Tor не подключён.';

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Использует все $count выхода · сдача 1 выход',
      many: 'Использует все $count выходов · сдача 1 выход',
      few: 'Использует все $count выхода · сдача 1 выход',
      one: 'Использует все выходы ($count) · сдача 1 выход',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSomethingWrong => 'Что-то пошло не так';

  @override
  String get deskErrWrongPassword => 'Неверный пароль';

  @override
  String get deskErrPhraseInvalid => 'Неверная фраза восстановления';

  @override
  String get deskErrWalletExists => 'Такой кошелёк уже есть';

  @override
  String get deskErrWalletNotFound => 'Кошелёк не найден';

  @override
  String get deskErrNodeNotAnswering => 'Узел не отвечает';

  @override
  String get deskErrNotEnoughFunds => 'Недостаточно средств';

  @override
  String get deskErrNotTxFile => 'Это не файл транзакции для этого кошелька';

  @override
  String get deskErrEpicboxUnreachable => 'Сервер Epicbox недоступен';

  @override
  String get deskErrNotHttpAddress => 'Это не адрес http(s)';

  @override
  String get deskErrPlainHttp => 'Отправка по обычному HTTP не подтверждена';

  @override
  String get deskErrNotOnion => 'Это не адрес .onion';

  @override
  String get deskErrTorNotConnected => 'Tor не подключён';

  @override
  String get deskErrOnionUnreachable =>
      'Кошелёк получателя недоступен через Tor. Epicbox доставляет платёж, даже когда кошелёк не в сети';

  @override
  String get deskErrWalletBusy => 'Кошелёк занят. Повторите через минуту.';

  @override
  String get deskErrDbDamaged =>
      'База данных кошелька повреждена, идёт восстановление';

  @override
  String get deskErrPaymentExpired => 'Срок платежа истёк';

  @override
  String get deskErrInvoiceNotFound => 'Счёт не найден';

  @override
  String get deskErrAmountMismatch => 'Сумма не совпадает со счётом';

  @override
  String get deskErrInvoicePaid => 'Счёт уже оплачен';

  @override
  String get deskErrInvoiceLocked =>
      'Счёт заблокирован до более позднего блока';

  @override
  String get deskErrInvoiceChanged => 'Счёт изменился';

  @override
  String get deskErrNotAccepted => 'Не принято';

  @override
  String deskErrNotAcceptedDetail(String detail) {
    return 'Не принято: $detail';
  }

  @override
  String get deskErrDisk => 'Ошибка диска';

  @override
  String deskErrDiskDetail(String detail) {
    return 'Ошибка диска: $detail';
  }

  @override
  String get deskErrTorMissing => 'Tor не входит в эту сборку';

  @override
  String get deskErrTorNetwork => 'Не удаётся подключиться к сети Tor';

  @override
  String get deskErrTorClock => 'Часы компьютера идут неверно';

  @override
  String get deskErrOnionNotPublished => 'Адрес .onion не опубликован';

  @override
  String get deskErrTorStart => 'Tor не запустился';

  @override
  String get deskErrTorStopped => 'Tor остановился';

  @override
  String get deskErrScanRunning => 'Сканирование уже идёт.';

  @override
  String get deskErrCancelRefused =>
      'Не отменено: этот платёж уже есть у узла.';

  @override
  String get deskErrWalletLocked => 'Кошелёк заблокирован';

  @override
  String get deskErrWalletLocking => 'Кошелёк блокируется';

  @override
  String deskErrDbDamagedDetail(String detail) {
    return 'База данных кошелька повреждена. $detail';
  }

  @override
  String deskErrWalletClosed(String detail) {
    return 'Кошелёк закрыт: $detail. Разблокируйте его снова.';
  }

  @override
  String deskErrNotChanged(String detail) {
    return 'Не изменено: $detail';
  }

  @override
  String deskErrPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не меньше $count символа',
      many: 'Не меньше $count символов',
      few: 'Не меньше $count символов',
      one: 'Не меньше $count символа',
    );
    return '$_temp0';
  }

  @override
  String get deskErrWalletNotListed => 'Кошелька нет в списке';

  @override
  String get deskErrUpdateApp => 'Чтобы изменить список, обновите приложение';

  @override
  String get deskErrListNotChanged => 'Список кошельков не изменён';

  @override
  String get deskErrOpenToDelete => 'Чтобы удалить кошелёк, откройте его';

  @override
  String get deskErrEnterPassword => 'Введите пароль';

  @override
  String get deskErrFolderNotFound => 'Папка кошелька не найдена';

  @override
  String deskErrAlreadyHere(String name) {
    return 'Этот кошелёк уже здесь: $name';
  }

  @override
  String get deskErrTestNet =>
      'Это тестовый кошелёк, его нельзя импортировать.';

  @override
  String get deskErrWalletInApp => 'Этот кошелёк уже есть в приложении.';

  @override
  String get deskErrWalletNotFoundSearch => 'Кошелёк не найден. Поищите снова.';

  @override
  String get deskErrEnterOldPassword => 'Введите старый пароль';

  @override
  String deskErrOldPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Старый пароль слишком короткий. Придумайте новый, не короче $count символа.',
      many:
          'Старый пароль слишком короткий. Придумайте новый, не короче $count символов.',
      few:
          'Старый пароль слишком короткий. Придумайте новый, не короче $count символов.',
      one:
          'Старый пароль слишком короткий. Придумайте новый, не короче $count символа.',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSeedUnreadable => 'Не удалось прочитать файл wallet.seed';

  @override
  String get deskErrNotSeedFile => 'Это не файл wallet.seed';

  @override
  String deskErrAlreadyInApp(String name) {
    return 'Уже есть в приложении как $name';
  }

  @override
  String get deskErrWrongOldPassword => 'Неверный старый пароль';

  @override
  String get deskErrListNotSaved => 'Список кошельков не сохранён';

  @override
  String get deskErrProofSeedRead => 'Фраза восстановления прочитана';

  @override
  String get deskErrProofWalletCreated => 'Кошелёк создан';

  @override
  String deskErrProofContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено $count контакта',
      many: 'Добавлено $count контактов',
      few: 'Добавлено $count контакта',
      one: 'Добавлен $count контакт',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofNode(String name) {
    return 'Узел $name добавлен в список узлов';
  }

  @override
  String get deskErrProofFolderUnchanged => 'Старая папка не изменена';

  @override
  String get deskErrProofFolderChanged =>
      'Старая папка изменена другой программой';

  @override
  String deskErrProofHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'История: $count транзакции',
      many: 'История: $count транзакций',
      few: 'История: $count транзакции',
      one: 'История: $count транзакция',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofHistoryAlready => 'История уже импортирована';

  @override
  String get deskErrProofHistoryNone =>
      'В старой папке нет истории; баланс восстановит сканирование';

  @override
  String get deskErrProofHistoryOld =>
      'История в старом формате базы данных не читается; баланс восстанавливает сканирование';

  @override
  String get deskErrProofHistoryBusy =>
      'История не импортирована: старый кошелёк запущен. Она будет импортирована при следующей разблокировке';

  @override
  String get deskErrProofHistoryOther =>
      'История не импортирована: она относится к другому кошельку';

  @override
  String get deskErrProofHistoryUnreadable =>
      'История не импортирована: не удалось прочитать старую базу данных; баланс восстановит сканирование';

  @override
  String get deskErrNodeNoAnswer => 'Узел не ответил';

  @override
  String get deskErrNotPosted => 'Не отправлено в сеть';

  @override
  String get deskErrNotEpicboxAddress => 'Это не адрес Epicbox';

  @override
  String get deskErrFileNotSaved =>
      'Файл не сохранён. Платёж ждёт в «Активности»; отмените его там, чтобы разблокировать средства.';

  @override
  String get deskErrTorOffSend =>
      'Tor выключен. Чтобы отправить на адрес .onion, включите Tor.';

  @override
  String get deskErrTorConnecting =>
      'Tor ещё подключается. Повторите через минуту.';

  @override
  String get deskErrRecipientNoAnswer =>
      'Кошелёк получателя не ответил или отказал.';

  @override
  String get deskErrRecipientNoAnswerWaits =>
      'Кошелёк получателя не ответил или отказал. Платёж ждёт в «Активности»; отмените его там, чтобы разблокировать средства.';

  @override
  String get deskErrNotDelivered =>
      'Не доставлено. Платёж ждёт в «Активности»; отмените его там, чтобы разблокировать средства.';

  @override
  String get deskErrInterruptedLock =>
      'Прервано блокировкой. Возможно, платёж ушёл: после разблокировки проверьте «Активность».';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail. Платёж ждёт в «Активности»; отмените его там, чтобы разблокировать средства.';
  }

  @override
  String get deskErrNodeRefused =>
      'Оба кошелька подписали, но узел отклонил транзакцию. Отмените её в «Активности», чтобы разблокировать средства.';

  @override
  String get deskErrFileNotReadable => 'Файл не читается';

  @override
  String get deskErrNotTxFile2 => 'Это не файл транзакции';

  @override
  String get deskErrResponseNotSaved => 'Файл ответа не сохранён';

  @override
  String get deskErrCannotCancel => 'Этот платёж нельзя отменить';

  @override
  String get deskErrNoLocalNode => 'В этой сборке нет локального узла';

  @override
  String get deskErrLocalNodeStopped => 'Локальный узел остановлен';

  @override
  String get deskErrNotChangedLocked => 'Не изменено: кошелёк был заблокирован';

  @override
  String deskErrLocalNodeNotStarted(String detail) {
    return 'Локальный узел не запущен: $detail';
  }

  @override
  String get deskErrUnknown => 'неизвестная ошибка';

  @override
  String get deskErrNotServerName => 'Это не имя сервера';

  @override
  String deskErrPortInUse(int port) {
    return 'Порт $port занят';
  }

  @override
  String deskErrPortUnavailable(int port) {
    return 'Порт $port недоступен';
  }

  @override
  String get deskErrStoppedWithError => 'Остановлен с ошибкой';

  @override
  String get deskErrPasswordNotChanged =>
      'Пароль не изменён. Кошелёк по-прежнему открывается текущим паролем.';

  @override
  String get deskTorLineOff => 'Выкл.';

  @override
  String get deskTorLineReady => 'Готов';

  @override
  String deskTorLineSendsWork(String problem) {
    return '$problem. Отправка работает.';
  }

  @override
  String get deskTorLinePublishing => 'Публикация адреса .onion…';

  @override
  String deskTorLineConnecting(int percent) {
    return 'Подключение к Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'Данные другого кошелька';

  @override
  String get deskErrHistOtherChain => 'Не та сеть';

  @override
  String get deskErrHistNotOurs => 'Это не файл данных кошелька';

  @override
  String get deskErrHistNewer => 'Файл новее';

  @override
  String get deskErrHistDamaged => 'Файл повреждён';

  @override
  String get deskErrOldGui => 'Старый Epic Wallet';

  @override
  String get deskErrOldCli => 'Программа epic';

  @override
  String get deskErrOldPicked => 'Выбранные папки';

  @override
  String get deskErrHistTooLarge => 'Файл слишком большой для резервной копии.';

  @override
  String get deskErrHistChains => 'Файл из другой сети.';

  @override
  String get deskErrHistOtherWalletText =>
      'Файл экспортирован из кошелька с другой фразой восстановления.';

  @override
  String get deskErrHistNewerText =>
      'Этот файл создан более новой версией приложения. Обновите приложение, затем импортируйте его.';

  @override
  String get deskErrHistDamagedText => 'Файл неполный или был изменён.';

  @override
  String get deskErrHistNotOursText => 'Файл создан не в BT Wallet.';

  @override
  String get deskDataHttpEnter => 'Введите адрес получателя';

  @override
  String get deskDataHttpScheme => 'Начните с https:// или http://';

  @override
  String get deskDataHttpOnion => 'Для адресов .onion нужен Tor';

  @override
  String get deskDataHttpNot => 'Это не адрес http(s)';

  @override
  String get deskDataHttpPort => 'Порт должен быть от 1 до 65535';

  @override
  String get deskDataUpdTimeout => 'Сервер обновлений не ответил.';

  @override
  String get deskDataUpdUnreachable =>
      'Не удалось связаться с сервером обновлений.';

  @override
  String deskDataUpdStatus(int status) {
    return 'Ошибка сервера обновлений ($status).';
  }

  @override
  String get deskDataUpdNone =>
      'Сведений об обновлениях для настольной версии пока нет.';

  @override
  String get deskNodeSynced => 'Синхронизирован';

  @override
  String get deskNodeBehind => 'Отстаёт';

  @override
  String get deskNodeNotAnswering => 'Не отвечает';

  @override
  String get deskNodeChecking => 'Проверка';

  @override
  String get deskNodeStarting => 'Запуск';

  @override
  String get deskNodeSyncing => 'Синхронизация';

  @override
  String get deskNodeStalled => 'Застрял';

  @override
  String get deskNodeFailed => 'Ошибка';

  @override
  String get deskNodeStopped => 'Остановлен';

  @override
  String get deskNodeMarkerNoAnswer => 'нет ответа';

  @override
  String deskNodeMarkerBehind(String count) {
    return 'отстаёт на $count';
  }

  @override
  String get deskNodeMarkerStarting => 'запуск';

  @override
  String get deskNodeMarkerStalled => 'застрял';

  @override
  String get deskNodeMarkerFailed => 'ошибка';

  @override
  String get deskNodeMarkerStopped => 'остановлен';

  @override
  String deskNodeHostSince(String host, String time) {
    return '$host · с $time';
  }

  @override
  String get deskNodeNotAnsweringLine => 'Узел не отвечает.';

  @override
  String deskNodeLatency(String ms) {
    return '$ms мс';
  }

  @override
  String deskNodeLatencyOverTor(String ms) {
    return '$ms мс через Tor';
  }

  @override
  String deskNodeNewerOut(String version) {
    return 'вышла версия $version';
  }

  @override
  String get deskNodeBehindLine => 'Отстаёт от сети; догоняет.';

  @override
  String deskNodeHeightOf(String height, String total) {
    return '$height из $total';
  }

  @override
  String get deskNodeAtTip => 'синхронизирован';

  @override
  String get deskNodeLocal => 'Локальный узел';

  @override
  String get deskNodeConnectingPeers => 'Подключение к пирам';

  @override
  String deskNodeUsingUntilSynced(String host) {
    return 'Пока он не синхронизирован, используется $host.';
  }

  @override
  String get deskNodeNothingUntilSynced =>
      'Пока он не синхронизирован, отправить ничего нельзя.';

  @override
  String deskNodePeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пира',
      many: '$count пиров',
      few: '$count пира',
      one: '$count пир',
    );
    return '$_temp0';
  }

  @override
  String deskNodeRunning(String duration) {
    return 'работает $duration';
  }

  @override
  String deskNodeStillUsing(String host) {
    return 'Пока используется $host; скоро его заменит локальный узел.';
  }

  @override
  String get deskNodeNoProgress =>
      'Нет прогресса 5 мин. Один перезапуск уже был.';

  @override
  String deskNodeUsingMeanwhile(String host) {
    return 'Пока используется $host.';
  }

  @override
  String get deskNodeStartIt => 'Запустите его в разделе «Настройки › Узел».';

  @override
  String deskNodeFailPort(String port) {
    return 'порт $port занят другой программой';
  }

  @override
  String get deskNodeFailDisk => 'недостаточно места на диске';

  @override
  String get deskNodeFailMissing => 'программа узла не найдена';

  @override
  String get deskNodeFailExited => 'программа узла остановилась';

  @override
  String deskNodeFailExitedCode(String code) {
    return 'программа узла остановилась (код выхода $code)';
  }

  @override
  String get deskNodeFailDefault => 'узел не запустился';

  @override
  String get deskNodeStageWaiting => 'подключение к пирам';

  @override
  String get deskNodeStageHeaders => 'заголовки';

  @override
  String get deskNodeStageChainDownload => 'загрузка состояния цепочки';

  @override
  String get deskNodeStageKernels => 'проверка блокчейна';

  @override
  String get deskNodeStageRangeProofs => 'проверка доказательств диапазона';

  @override
  String get deskNodeStageProcessing => 'обработка состояния цепочки';

  @override
  String get deskNodeStageBlocks => 'блоки';

  @override
  String get deskNodeStageCompacting => 'сжатие';

  @override
  String get deskNodeStageStopping => 'остановка';

  @override
  String get deskNodeStageSyncing => 'синхронизация';

  @override
  String get deskNodeLineWaiting => 'Подключение к пирам';

  @override
  String deskNodeLineHeaders(String done, String total) {
    return 'Заголовки · $done из $total';
  }

  @override
  String get deskNodeLineHeadersBare => 'Заголовки';

  @override
  String deskNodeLineChain(String done, String total) {
    return 'Состояние цепочки · $done из $total ГБ';
  }

  @override
  String get deskNodeLineChainBare => 'Состояние цепочки';

  @override
  String deskNodeLineKernels(String done, String total) {
    return 'Проверка блокчейна · $done из $total млн';
  }

  @override
  String get deskNodeLineKernelsBare => 'Проверка блокчейна';

  @override
  String deskNodeLineRangeProofs(String done, String total) {
    return 'Проверка доказательств диапазона · $done из $total млн';
  }

  @override
  String get deskNodeLineRangeProofsBare => 'Проверка доказательств диапазона';

  @override
  String get deskNodeLineProcessing => 'Обработка состояния цепочки';

  @override
  String deskNodeLineBlocks(String done, String total) {
    return 'Блоки · $done из $total';
  }

  @override
  String get deskNodeLineBlocksBare => 'Блоки';

  @override
  String get deskNodeLineCompacting => 'Сжатие данных цепочки';

  @override
  String get deskNodeLineStopping => 'Остановка…';

  @override
  String get deskNodeLineSyncing => 'Синхронизация';

  @override
  String deskNodeDurationHm(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String deskNodeDurationM(int minutes) {
    return '$minutes мин';
  }

  @override
  String get deskTorNetworkLabel => 'Сеть Tor';

  @override
  String get deskTorNetworkHint => 'Сетевая активность идёт через сеть Tor.';

  @override
  String get deskTorOff => 'Выкл.';

  @override
  String get deskTorStarting => 'Запуск…';

  @override
  String get deskTorOn => 'Вкл.';

  @override
  String get deskTorNotConnected => 'Нет подключения';

  @override
  String get deskTorCoverage =>
      'Через Tor: Epicbox, узел, статус, курс, обновления, поддержка и адреса Tor.';

  @override
  String get deskTorNodeOver => 'Через Tor';

  @override
  String get deskTorNodeNotEncrypted => 'После Tor без шифрования';

  @override
  String get deskTorNodeWaits => 'Ждёт подключения Tor.';

  @override
  String get deskRecvTitle => 'Получить';

  @override
  String get deskRecvReceiving => 'Приём';

  @override
  String deskRecvTurnOnFailed(String method) {
    return '$method: не удалось включить';
  }

  @override
  String deskRecvTurnOffFailed(String method) {
    return '$method: не удалось выключить';
  }

  @override
  String get deskRecvOtherWays => 'Другие способы приёма';

  @override
  String get deskRecvSettings => 'Настройки';

  @override
  String get deskRecvTorNotConnected => 'Tor не подключён.';

  @override
  String get deskRecvTorStarting => 'Tor запускается.';

  @override
  String get deskRecvTorDownText =>
      'Tor не удалось подключить. Повторите попытку или выключите Tor.';

  @override
  String get deskRecvTorStartingText =>
      'Адреса станут доступны, когда Tor подключится.';

  @override
  String get deskRecvTurnTorOff => 'Выключить Tor';

  @override
  String get deskRecvTryAgain => 'Повторить';

  @override
  String get deskRecvStateOn => 'вкл.';

  @override
  String get deskRecvStateOff => 'выкл.';

  @override
  String get deskRecvStateChecking => 'проверка';

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
    return '$method · Проверка';
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
  String get deskRecvTagPaused => 'Приостановлен';

  @override
  String get deskRecvTagStarting => 'Запуск';

  @override
  String get deskRecvTagNotReachable => 'Недоступен';

  @override
  String get deskRecvAddressUnreadable =>
      'Не удалось прочитать адрес. Откройте «Получить» снова через минуту.';

  @override
  String get deskRecvEpicboxAddress => 'Адрес Epicbox';

  @override
  String get deskRecvCopyEpicbox => 'Копировать адрес Epicbox';

  @override
  String get deskRecvEpicboxIntro => 'Поделитесь им, чтобы получить оплату.';

  @override
  String get deskRecvCheckSix =>
      'Читая его вслух, сверьте первые шесть и последние шесть символов.';

  @override
  String get deskRecvHttpAddress => 'Адрес Ссылка · HTTP';

  @override
  String get deskRecvCopyHttp => 'Копировать адрес Ссылка · HTTP';

  @override
  String get deskRecvHttpIntro =>
      'Для кошельков в локальной сети, пока этот кошелёк открыт.';

  @override
  String get deskRecvHttpTorHint =>
      'Чтобы получить адрес Tor, включите Tor в разделе «Настройки › Приватность».';

  @override
  String get deskRecvDirectTor => 'Адрес Ссылка · Tor';

  @override
  String get deskRecvTorIntro =>
      'Напрямую из другого кошелька через Tor, пока этот открыт. Tor настраивается в разделе «Настройки › Приватность».';

  @override
  String get deskRecvTorAddress => 'Адрес Ссылка · Tor';

  @override
  String get deskRecvCopyTor => 'Копировать адрес Tor';

  @override
  String get deskRecvTorOnion =>
      'Некоторые кошельки показывают адрес без .onion; это один и тот же адрес.';

  @override
  String get deskRecvFiles => 'Файлы транзакций';

  @override
  String get deskRecvSignTitle => 'Подписать файл транзакции';

  @override
  String get deskRecvSignText =>
      'Подпишите файл транзакции отправителя и сохраните файл ответа.';

  @override
  String get deskRecvOpen => 'Открыть';

  @override
  String get deskRecvFinalizeTitle => 'Завершить по файлу ответа';

  @override
  String get deskRecvFinalizeText =>
      'Завершите по файлу ответа получателя, чтобы отправить платёж в сеть.';

  @override
  String deskRecvSwitchLabel(String title) {
    return '$title, приём';
  }

  @override
  String get deskSendStrategySmallest => 'Наименьшие';

  @override
  String get deskSendStrategyAll => 'Все';

  @override
  String get deskSendBalanceAfter => 'Баланс после';

  @override
  String get deskSendSpendableUntil => 'Доступно до подтверждения сдачи';

  @override
  String get deskSendSpendableWhile => 'Доступно до подтверждения';

  @override
  String deskSendSplitLine(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Сдача делится на $outputs выхода (+$fee EPIC комиссии)',
      many: 'Сдача делится на $outputs выходов (+$fee EPIC комиссии)',
      few: 'Сдача делится на $outputs выхода (+$fee EPIC комиссии)',
      one: 'Сдача делится на $outputs выход (+$fee EPIC комиссии)',
    );
    return '$_temp0';
  }

  @override
  String deskSendSplitWhy(int outputs, String each) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other:
          'Чтобы следующая отправка не ждала подтверждения этой. Сдача вернётся $outputs выхода примерно по $each EPIC, а не одним.',
      many:
          'Чтобы следующая отправка не ждала подтверждения этой. Сдача вернётся $outputs выходами примерно по $each EPIC, а не одним.',
      few:
          'Чтобы следующая отправка не ждала подтверждения этой. Сдача вернётся $outputs выходами примерно по $each EPIC, а не одним.',
      one:
          'Чтобы следующая отправка не ждала подтверждения этой. Сдача вернётся $outputs выходом примерно по $each EPIC, а не одним.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendSplitWhyLabel => 'Почему сдача делится';

  @override
  String deskSendLockNoChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Без сдачи: $count выхода потрачено без остатка, ничего не ждёт.',
      many: 'Без сдачи: $count выходов потрачено без остатка, ничего не ждёт.',
      few: 'Без сдачи: $count выхода потрачены без остатка, ничего не ждёт.',
      one: 'Без сдачи: $count выход потрачен без остатка, ничего не ждёт.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockAll(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заблокировано всё: $count выхода, $amount EPIC, $_temp0.',
      many: 'Заблокировано всё: $count выходов, $amount EPIC, $_temp1.',
      few: 'Заблокировано всё: $count выхода, $amount EPIC, $_temp2.',
      one: 'Заблокировано всё: $count выход, $amount EPIC, $_temp3.',
    );
    return '$_temp4';
  }

  @override
  String deskSendLockSome(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заблокировано $count выхода, $amount EPIC, $_temp0.',
      many: 'Заблокировано $count выходов, $amount EPIC, $_temp1.',
      few: 'Заблокированы $count выхода, $amount EPIC, $_temp2.',
      one: 'Заблокирован $count выход, $amount EPIC, $_temp3.',
    );
    return '$_temp4';
  }

  @override
  String deskSendStrategyLine(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Стратегия для этой отправки: $strategy · $count выхода.',
      many: 'Стратегия для этой отправки: $strategy · $count выходов.',
      few: 'Стратегия для этой отправки: $strategy · $count выхода.',
      one: 'Стратегия для этой отправки: $strategy · $count выход.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSplit(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Сдача делится на $outputs выхода (+$fee EPIC).',
      many: 'Сдача делится на $outputs выходов (+$fee EPIC).',
      few: 'Сдача делится на $outputs выхода (+$fee EPIC).',
      one: 'Сдача делится на $outputs выход (+$fee EPIC).',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksNone(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$locked EPIC в $count выхода; сдачи не будет.',
      many: '$locked EPIC в $count выходах; сдачи не будет.',
      few: '$locked EPIC в $count выходах; сдачи не будет.',
      one: '$locked EPIC в $count выходе; сдачи не будет.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSetAsideNone(String locked) {
    return '$locked EPIC уходит целиком; ничего не откладывается.';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Всё: $locked EPIC в $count выхода до подтверждения сдачи $_temp0. Доступного не остаётся.',
      many:
          'Всё: $locked EPIC в $count выходах до подтверждения сдачи $_temp1. Доступного не остаётся.',
      few:
          'Всё: $locked EPIC в $count выходах до подтверждения сдачи $_temp2. Доступного не остаётся.',
      one:
          'Всё: $locked EPIC в $count выходе до подтверждения сдачи $_temp3. Доступного не остаётся.',
    );
    return '$_temp4';
  }

  @override
  String deskSendReviewSetAsideAll(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    return 'Всё: $locked EPIC отложено до подтверждения этого платежа $_temp0. Ничего не остаётся доступным.';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC в $count выхода до подтверждения сдачи $_temp0. Больше ничего пока не доступно.',
      many:
          '$locked EPIC в $count выходах до подтверждения сдачи $_temp1. Больше ничего пока не доступно.',
      few:
          '$locked EPIC в $count выходах до подтверждения сдачи $_temp2. Больше ничего пока не доступно.',
      one:
          '$locked EPIC в $count выходе до подтверждения сдачи $_temp3. Больше ничего пока не доступно.',
    );
    return '$_temp4';
  }

  @override
  String deskSendReviewSetAsideEverything(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    return '$locked EPIC отложено до подтверждения этого платежа $_temp0. До тех пор больше ничего не доступно.';
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
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC в $count выхода до подтверждения сдачи $_temp0. Доступными остаются $spendable EPIC.',
      many:
          '$locked EPIC в $count выходах до подтверждения сдачи $_temp1. Доступными остаются $spendable EPIC.',
      few:
          '$locked EPIC в $count выходах до подтверждения сдачи $_temp2. Доступными остаются $spendable EPIC.',
      one:
          '$locked EPIC в $count выходе до подтверждения сдачи $_temp3. Доступными остаются $spendable EPIC.',
    );
    return '$_temp4';
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
      other: '($blocks блока)',
      many: '($blocks блоков)',
      few: '($blocks блока)',
      one: '($blocks блок)',
    );
    return '$locked EPIC отложено до подтверждения этого платежа $_temp0. $spendable EPIC остаётся доступным.';
  }

  @override
  String get deskSendFactLocks => 'Блокирует';

  @override
  String get deskSendFactStrategy => 'Стратегия';

  @override
  String deskSendFactStrategyValue(String strategy) {
    return '$strategy выходы, для этой отправки';
  }

  @override
  String get deskSendAdvSmallest => '· Наименьшие выходы';

  @override
  String get deskSendAdvSmallestNoSplit =>
      '· Наименьшие выходы, сдача не делится';

  @override
  String get deskSendAdvAll => '· Все выходы';

  @override
  String get deskSendAdvAllNoSplit => '· Все выходы, сдача не делится';

  @override
  String get deskSendAdvanced => 'Параметры отправки';

  @override
  String get deskSendAdvStrategy => 'Стратегия для этой отправки';

  @override
  String get deskSendAdvSmallestText =>
      'Тратит наименьшие выходы, которых хватает на сумму; остальное остаётся доступным.';

  @override
  String get deskSendAdvAllText =>
      'Тратит все доступные выходы и возвращает один выход сдачи. Всё заблокировано до подтверждения; потом выходов меньше и они крупнее.';

  @override
  String get deskSendDefaultTag => 'по умолчанию';

  @override
  String get deskSendAdvAllNote =>
      'При отправке всего баланса тратятся все выходы.';

  @override
  String get deskSendAdvSplit => 'Делить сдачу';

  @override
  String get deskSendAdvSplitText =>
      'Возвращает сдачу несколькими выходами, если их осталось бы мало, чтобы следующая отправка не ждала.';

  @override
  String get deskSendAdvDefaults =>
      'Только для этой отправки. Значения по умолчанию: ';

  @override
  String get deskSendAdvOutputsLink => 'Выходы';

  @override
  String get deskSendPickNone => 'Контактов пока нет';

  @override
  String get deskSendPickNoneText =>
      'Сохраните тех, кому платите, в «Контактах», а потом выбирайте их здесь.';

  @override
  String get deskSendPickOpen => 'Открыть контакты';

  @override
  String deskSendPickNoMatch(String query) {
    return 'Нет контактов по запросу «$query».';
  }

  @override
  String get deskSendPickTitle => 'Выбор контакта';

  @override
  String get deskSendPickDesc => 'Адрес подставится в поле получателя.';

  @override
  String get deskSendPickSearch => 'Поиск контактов';

  @override
  String get deskSendTitle => 'Отправить';

  @override
  String get deskSendErrNoAddress => 'Укажите адрес получателя.';

  @override
  String get deskSendErrEpicbox => 'Это недействительный адрес Epicbox.';

  @override
  String get deskSendErrNotDirect => 'Это не адрес ссылки.';

  @override
  String get deskSendErrOnion => 'Это недействительный адрес .onion.';

  @override
  String get deskSendErrOwn => 'Это собственный адрес кошелька.';

  @override
  String get deskSendNoAnswer => 'Получатель не ответил. Ничего не отправлено.';

  @override
  String get deskSendTorOnFailed => 'Tor не включён';

  @override
  String get deskSendTorOffFailed => 'Tor не выключен';

  @override
  String get deskSendEpicboxOnFailed => 'Epicbox не включён';

  @override
  String get deskSendNothingSpendable => 'Нет доступных средств для отправки.';

  @override
  String get deskSendAllFailed =>
      'Не удалось посчитать, сколько можно отправить. Повторите через минуту.';

  @override
  String get deskSendErrAmountEnter => 'Введите сумму.';

  @override
  String get deskSendErrAmountDecimals =>
      'У EPIC не больше 8 знаков после запятой.';

  @override
  String get deskSendErrAmountZero => 'Сумма должна быть больше 0.';

  @override
  String get deskSendErrAmountMore => 'Больше доступного баланса.';

  @override
  String get deskSendSent => 'Отправлено';

  @override
  String get deskSendFileReadyTitle => 'Файл транзакции готов';

  @override
  String get deskSendFileReadyText =>
      'Передайте этот файл получателю, затем завершите по его файлу ответа.';

  @override
  String get deskSendFinalize => 'Завершить';

  @override
  String get deskSendNewSend => 'Отправить ещё';

  @override
  String get deskSendNodeNotSynced => 'Узел не синхронизирован';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Отправка возобновится, когда узел синхронизируется ($percent %).';
  }

  @override
  String get deskSendNodeSyncing =>
      'Отправка станет возможна, когда узел синхронизируется.';

  @override
  String get deskSendTorBlocked => 'Tor не подключён';

  @override
  String get deskSendTorBlockedText =>
      'Ничего не отправится, пока Tor не подключится или пока его не выключат.';

  @override
  String get deskSendTurnTorOff => 'Выключить Tor';

  @override
  String get deskSendTorStarting => 'Tor запускается';

  @override
  String get deskSendTorStartingText => 'Отправка ждёт Tor.';

  @override
  String get deskSendEpicboxOff => 'Epicbox не подключён';

  @override
  String get deskSendEpicboxOffText =>
      'Включите приём через Epicbox, чтобы отправлять через Epicbox, или используйте «Напрямую · Передача файла».';

  @override
  String deskSendEpicboxOffTab(String method) {
    return 'Включите приём через Epicbox, чтобы отправлять через Epicbox, или используйте «$method».';
  }

  @override
  String get deskSendEpicboxTurnOn => 'Включить приём через Epicbox';

  @override
  String get deskSendDoneViaDirect => 'Завершено и отправлено в сеть.';

  @override
  String get deskSendDoneViaEpicbox =>
      'Передано в Epicbox. Завершится, когда получатель ответит.';

  @override
  String get deskSendViewTx => 'Открыть в «Активности»';

  @override
  String get deskSendFailedTitle => 'Отправка не удалась';

  @override
  String get deskSendReviewAgain => 'Проверить снова';

  @override
  String get deskSendTo => 'Кому';

  @override
  String get deskSendToHelp => 'Вставьте адрес или введите имя контакта.';

  @override
  String get deskSendToHint => 'Адрес или контакт';

  @override
  String get deskSendToSem => 'Получатель';

  @override
  String get deskSendClearTo => 'Очистить получателя';

  @override
  String get deskSendContacts => 'Контакты';

  @override
  String get deskSendNeedsTor => 'Link · Tor требует Tor';

  @override
  String get deskSendNeedsTorText => 'Адрес .onion доступен только через Tor.';

  @override
  String get deskSendNoTorBuild => 'В этой сборке нет Tor.';

  @override
  String get deskSendTurnOnTor => 'Включить Tor';

  @override
  String get deskSendHttpClearnet => 'Ссылка · HTTP идёт напрямую, без Tor.';

  @override
  String get deskSendClear => 'Очистить';

  @override
  String get deskSendAmount => 'Сумма';

  @override
  String get deskSendAvailableNone => 'Доступно —';

  @override
  String deskSendAvailable(String amount) {
    return 'Доступно $amount EPIC';
  }

  @override
  String get deskSendAmountSem => 'Сумма в EPIC';

  @override
  String get deskSendAllButton => 'Макс.';

  @override
  String get deskSendConfirmingHidden =>
      'Часть баланса ещё подтверждается, её пока нельзя отправить.';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC ещё подтверждаются, их пока нельзя отправить.';
  }

  @override
  String get deskSendMessage => 'Сообщение';

  @override
  String get deskSendMessageHelp => 'Получатель его увидит.';

  @override
  String get deskSendPrivacyOn => 'Приватность · Dandelion++ вкл.';

  @override
  String get deskSendPrivacyOff => 'Приватность · Dandelion++ выкл.';

  @override
  String get deskSendDandelionText =>
      'Пропускает транзакцию через несколько случайных узлов, прежде чем она разойдётся по сети, и сеть не может узнать, откуда она пришла.';

  @override
  String get deskSendHintSent => 'Отправлено.';

  @override
  String get deskSendHintQueued =>
      'В очереди. Чтобы отправить снова, введите новую сумму и получателя.';

  @override
  String get deskSendHintNode => 'Ждём синхронизации узла.';

  @override
  String get deskSendHintEpicbox => 'Ждём подключения Epicbox.';

  @override
  String get deskSendHintTorWait => 'Ждём подключения Tor.';

  @override
  String get deskSendHintTorBlocked =>
      'Повторите подключение Tor или выключите его.';

  @override
  String get deskSendHintNeedsTor =>
      'Чтобы отправить на адрес .onion, включите Tor.';

  @override
  String get deskSendHintFix => 'Исправьте отмеченные поля.';

  @override
  String get deskSendHintChecking => 'Считаем комиссию для этой суммы.';

  @override
  String get deskSendHintDefault => 'Ничего не отправится до проверки.';

  @override
  String get deskSendReviewWaitTor => 'Ждём Tor';

  @override
  String get deskSendReviewTorOff => 'Tor не подключён';

  @override
  String get deskSendReview => 'Проверка';

  @override
  String get deskSendSummary => 'Итог';

  @override
  String get deskSendNetworkFee => 'Комиссия сети';

  @override
  String get deskSendTotal => 'Итого';

  @override
  String get deskSendUpdating => 'Баланс обновляется, пока кошелёк сканирует.';

  @override
  String get deskSendEpicboxLine2 =>
      'Сервер Epicbox хранит платёж, пока получатель не откроет кошелёк.';

  @override
  String get deskSendDirectLine1 => 'Прямо в кошелёк получателя.';

  @override
  String get deskSendDirectLine2 =>
      'Кошелёк получателя должен быть открыт. Платёж на адрес .onion идёт через Tor.';

  @override
  String get deskSendFileLine1 => 'Соединение не нужно.';

  @override
  String get deskSendFileLine2 =>
      'Передайте файл, получите файл ответа и завершите платёж здесь.';

  @override
  String get deskSendSwitchedDirect => 'Адрес ссылки. Выбран способ «Ссылка».';

  @override
  String get deskSendSwitchedFile =>
      'Адрес файла. Выбран способ «Напрямую · Файл».';

  @override
  String get deskSendSwitchedEpicbox => 'Адрес Epicbox. Выбран способ Epicbox.';

  @override
  String get deskSendMatching => 'Подходящие контакты';

  @override
  String deskSendMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Подходят $count контакта',
      many: 'Подходят $count контактов',
      few: 'Подходят $count контакта',
      one: 'Подходит $count контакт',
    );
    return '$_temp0';
  }

  @override
  String get deskSendWrongPassword => 'Неверный пароль.';

  @override
  String get deskSendNotConfirmed =>
      'Не подтверждено. Проверьте «Активность», прежде чем отправлять снова.';

  @override
  String get deskSendViaEpicbox => 'Epicbox (получатель может быть офлайн)';

  @override
  String get deskSendViaDirect =>
      'Ссылка · HTTP (кошелёк получателя должен быть открыт)';

  @override
  String get deskSendViaTor =>
      'Ссылка · Tor (кошелёк получателя должен быть открыт)';

  @override
  String get deskSendViaFile => 'Файл транзакции';

  @override
  String deskSendUsesAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Использует все $count выхода · сдача 1 выход',
      many: 'Использует все $count выходов · сдача 1 выход',
      few: 'Использует все $count выхода · сдача 1 выход',
      one: 'Использует свой $count выход · сдача 1 выход',
    );
    return '$_temp0';
  }

  @override
  String get deskSendReviewTitle => 'Проверка и отправка';

  @override
  String get deskSendReviewDesc =>
      'После публикации в сети отправку нельзя отменить.';

  @override
  String get deskSendFactTo => 'Кому';

  @override
  String get deskSendCheckChars =>
      'Сверьте выделенные символы с тем, что дал получатель.';

  @override
  String get deskSendFactVia => 'Способ';

  @override
  String get deskSendFactPrivacy => 'Приватность';

  @override
  String get deskSendDandelionOn => 'Dandelion++ вкл.';

  @override
  String get deskSendDandelionOff => 'Dandelion++ выкл.';

  @override
  String get deskSendFactMessage => 'Сообщение';

  @override
  String get deskSendPassword => 'Пароль';

  @override
  String get deskSendPasswordHelp =>
      'Каждая отправка запрашивает пароль кошелька.';

  @override
  String get deskSendBusyFile => 'Создаём файл.';

  @override
  String get deskSendBusyTor =>
      'Связываемся с кошельком получателя через Tor… Это может занять время. Не закрывайте приложение.';

  @override
  String get deskSendBusy =>
      'Отправка. Это может занять несколько секунд; не закрывайте окно.';

  @override
  String get deskSendBack => 'Назад';

  @override
  String get deskSendSending => 'Отправка';

  @override
  String deskSendConfirm(String amount) {
    return 'Отправить $amount EPIC';
  }

  @override
  String deskSendEpicboxSwitched(String domain) {
    return 'Переключено на $domain';
  }

  @override
  String get deskSendEpicboxNotSwitched => 'Не переключено';

  @override
  String get deskSendEpicboxDownTitle => 'Сервер Epicbox не отвечает';

  @override
  String get deskSendEpicboxDownWait =>
      'Платежи подождут, пока он не вернётся.';

  @override
  String deskSendEpicboxSwitchTo(String domain) {
    return 'Переключиться на $domain?';
  }

  @override
  String get deskSendEpicboxSwitch => 'Переключить';

  @override
  String get deskFinOpenFolder => 'Открыть папку';

  @override
  String get deskFinFolderNotOpened => 'Папка не открыта';

  @override
  String get deskFinWrongType => 'Это не файл ответа';

  @override
  String get deskFinWrongTypeText =>
      'Этот файл не является файлом ответа. Выберите файл, который вернул получатель.';

  @override
  String get deskFinUnreadable => 'Файл не читается';

  @override
  String get deskFinUnreadableText =>
      'Не удалось прочитать файл. Возможно, он повреждён или ещё копируется.';

  @override
  String get deskFinFailed => 'Не удалось завершить';

  @override
  String get deskFinFailedText =>
      'Кошелёк не смог завершить этот файл. Возможно, он относится к другой транзакции или уже завершён.';

  @override
  String get deskFinNotPosted => 'Не отправлено в сеть';

  @override
  String get deskFinNotPostedText =>
      'Транзакция завершена, но узел её не принял. Проверьте узел и повторите попытку.';

  @override
  String get deskFinPickTitle => 'Файл ответа';

  @override
  String get deskFinPosted => 'Платёж отправлен в сеть';

  @override
  String get deskFinTitle => 'Завершить по файлу ответа';

  @override
  String get deskFinNoticeTitle => 'Для платежей файлом';

  @override
  String get deskFinNoticeText =>
      'Используйте файл ответа, который прислал получатель.';

  @override
  String get deskFinTryAgain => 'Повторить';

  @override
  String get deskFinPostedText =>
      'Платёж завершён и отправлен в сеть. Следите за ним в «Активности».';

  @override
  String get deskFinAnother => 'Завершить другой файл';

  @override
  String get deskFinViewActivity => 'Открыть в «Активности»';

  @override
  String get deskFinBusy => 'Завершение и отправка в сеть';

  @override
  String get deskFinChoose => 'Выберите файл ответа';

  @override
  String get deskFinChooseText =>
      'Кошелёк завершит транзакцию и отправит её в сеть.';

  @override
  String get deskFinChooseFile => 'Выбрать файл';

  @override
  String get deskImpWrongType => 'Это не файл транзакции';

  @override
  String get deskImpWrongTypeText =>
      'Это не файл транзакции. Выберите файл .tx, который передал отправитель.';

  @override
  String get deskImpUnreadable => 'Файл не читается';

  @override
  String get deskImpUnreadableText =>
      'Не удалось прочитать файл. Возможно, он повреждён или ещё копируется.';

  @override
  String get deskImpNoPlace => 'Ничего не подписано';

  @override
  String get deskImpNoPlaceText =>
      'Место для файла ответа не выбрано, поэтому ничего не подписано.';

  @override
  String get deskImpFailed => 'Не удалось подписать';

  @override
  String get deskImpFailedText =>
      'Кошелёк не смог подписать этот файл. Возможно, он для другого кошелька или уже использован.';

  @override
  String deskImpFailedDetail(String detail) {
    return 'Кошелёк не смог подписать этот файл. Возможно, он для другого кошелька или уже использован. $detail.';
  }

  @override
  String get deskImpPickTitle => 'Файл транзакции';

  @override
  String get deskImpTitle => 'Подписать файл транзакции';

  @override
  String get deskImpNoticeTitle => 'Подпись ничего не тратит';

  @override
  String get deskImpNoticeText =>
      'Отправьте файл ответа отправителю тем же способом, которым он передал файл.';

  @override
  String get deskImpSaved => 'Ответ сохранён';

  @override
  String get deskImpSavedText =>
      'Отправьте файл ответа отправителю. EPIC поступят, когда отправитель завершит транзакцию.';

  @override
  String get deskImpAmount => 'Сумма ';

  @override
  String get deskImpAnother => 'Подписать другой файл';

  @override
  String get deskImpBusy => 'Подпись файла';

  @override
  String get deskImpChoose => 'Выберите файл транзакции';

  @override
  String get deskImpChooseText =>
      'Кошелёк подпишет его и сохранит ответ для отправителя.';

  @override
  String get deskActNotUpdated => 'Не обновлено';

  @override
  String get deskActSearchHint => 'Поиск платежей';

  @override
  String get deskActSearchLabel => 'Поиск платежей';

  @override
  String get deskActClearSearch => 'Очистить поиск';

  @override
  String get deskActShowAmounts => 'Показать суммы';

  @override
  String get deskActHideAmounts => 'Скрыть суммы';

  @override
  String get deskActRefresh => 'Обновить';

  @override
  String get deskActTitle => 'Активность';

  @override
  String get deskActDetailReceived => 'Входящий платёж';

  @override
  String get deskActDetailSent => 'Исходящий платёж';

  @override
  String get deskActLoading => 'Загрузка платежей';

  @override
  String get deskActWaitingNode => 'Ждём синхронизации узла.';

  @override
  String get deskActFilterAll => 'Все';

  @override
  String get deskActFilterReceived => 'Полученные';

  @override
  String get deskActFilterSent => 'Отправленные';

  @override
  String deskActNoMatchTitle(String query) {
    return 'По запросу «$query» ничего не найдено.';
  }

  @override
  String deskActPageOf(int page, int pages) {
    return 'Страница $page из $pages';
  }

  @override
  String get deskActPrevPage => 'Предыдущая страница';

  @override
  String get deskActNextPage => 'Следующая страница';

  @override
  String get deskActPages => 'Страницы';

  @override
  String get deskActColFromTo => 'От / кому';

  @override
  String get deskActColStatus => 'Статус';

  @override
  String get deskActColTime => 'Время';

  @override
  String get deskActColAmount => 'Сумма';

  @override
  String get deskActEmptyTitle => 'Платежей пока нет';

  @override
  String get deskActEmptyText =>
      'Отправленные и полученные платежи, сначала новые.';

  @override
  String get deskActShowAddress => 'Показать адрес';

  @override
  String get deskActReceiveFile => 'Получить файл';

  @override
  String get deskConTitle => 'Контакты';

  @override
  String get deskConLoading => 'Загрузка контактов';

  @override
  String get deskConNewTitle => 'Новый контакт';

  @override
  String get deskConEditTitle => 'Изменить контакт';

  @override
  String get deskConDetailsTitle => 'Подробности';

  @override
  String get deskConSearchHint => 'Имя или адрес';

  @override
  String get deskConSearchLabel => 'Поиск контактов';

  @override
  String get deskConClearSearch => 'Очистить поиск';

  @override
  String deskConCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count контакта',
      many: '$count контактов',
      few: '$count контакта',
      one: '$count контакт',
    );
    return '$_temp0';
  }

  @override
  String get deskConNoMatches => 'Ничего не найдено';

  @override
  String deskConMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count',
      many: 'Найдено $count',
      few: 'Найдено $count',
      one: 'Найден $count',
    );
    return '$_temp0';
  }

  @override
  String get deskConSortName => 'Имя';

  @override
  String get deskConSortRecent => 'Недавние';

  @override
  String get deskConNone => 'Контактов пока нет';

  @override
  String get deskConNoMatchList => 'Контакты не найдены';

  @override
  String get deskConAdd => 'Добавить контакт';

  @override
  String get deskConIdle => 'Выберите контакт.';

  @override
  String get deskConEmptyTitle => 'Контактов пока нет';

  @override
  String get deskConEmptyText => 'Контакт — это имя для адреса.';

  @override
  String get deskConSendToAddress => 'Отправить на адрес';

  @override
  String deskConLastTx(String when) {
    return 'Последний платёж: $when';
  }

  @override
  String get deskConSend => 'Отправить';

  @override
  String get deskConEdit => 'Изменить';

  @override
  String get deskConStar => 'В избранное';

  @override
  String get deskConUnstar => 'Из избранного';

  @override
  String get deskConDelete => 'Удалить';

  @override
  String get deskConNotDeleted => 'Не удалено';

  @override
  String deskConDeleted(String name) {
    return 'Контакт «$name» удалён';
  }

  @override
  String get deskConNote => 'Заметка';

  @override
  String deskConTxWith(String name) {
    return 'Платежи с контактом «$name»';
  }

  @override
  String get deskConAllTx => 'Все платежи';

  @override
  String get deskConTxNone =>
      'Платежей с этим контактом пока нет. Платежи ему со страницы «Отправить» появятся здесь.';

  @override
  String get deskConTxReceived => 'Получено';

  @override
  String get deskConTxSent => 'Отправлено';

  @override
  String get deskConErrName => 'Дайте контакту имя.';

  @override
  String get deskConErrAddressEmpty => 'Добавьте адрес.';

  @override
  String get deskConErrAddressInvalid =>
      'Недействительный адрес. Используйте адрес Epicbox (es5x…@сервер), адрес ссылки (https://…) или onion-адрес (….onion).';

  @override
  String get deskConAddPicture => 'Добавить фото';

  @override
  String get deskConChangePicture => 'Сменить фото';

  @override
  String get deskConRemovePicture => 'Удалить';

  @override
  String get deskConPictureHelp =>
      'PNG, JPEG, WebP или GIF, до 10 МБ. В приложении хранится уменьшенная копия.';

  @override
  String get deskConFieldName => 'Имя';

  @override
  String get deskConFieldAddress => 'Адрес';

  @override
  String get deskConSaveFailed => 'Контакт не сохранён';

  @override
  String get deskConSave => 'Сохранить контакт';

  @override
  String deskConDeleteTitle(String name) {
    return 'Удалить контакт «$name»?';
  }

  @override
  String get deskConDeleteBody =>
      'Удаляет контакт; прошлые платежи остаются в «Активности». Это нельзя отменить.';

  @override
  String get deskConKeep => 'Оставить';

  @override
  String get deskConDeleteAction => 'Удалить контакт';

  @override
  String get deskOutNotUpdated => 'Не обновлено';

  @override
  String get deskOutTitle => 'Выходы';

  @override
  String get deskOutShowAmounts => 'Показать суммы';

  @override
  String get deskOutHideAmounts => 'Скрыть суммы';

  @override
  String get deskOutRefresh => 'Обновить';

  @override
  String get deskOutLockedNote =>
      'Заблокированные выходы тратятся текущей транзакцией. Их сдача показана как ждущая завершения и не входит во «Всего», пока отправка не завершена, поэтому монеты учитываются один раз.';

  @override
  String get deskOutIntro =>
      'Выходы — это части, из которых состоит баланс. Отправка тратит выходы целиком и возвращает сдачу новым выходом.';

  @override
  String deskOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выхода',
      many: '$count выходов',
      few: '$count выхода',
      one: '$count выход',
    );
    return '$_temp0';
  }

  @override
  String deskOutCardWait(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    return 'Дождитесь подтверждения отправки ($_temp0).';
  }

  @override
  String get deskOutSplitNothing => 'Пока нечего разделять.';

  @override
  String deskOutSplitSpends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Тратит $count выхода.',
      many: 'Тратит $count выходов.',
      few: 'Тратит $count выхода.',
      one: 'Тратит $count выход.',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitSpendsFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Тратит $count выхода. Комиссия не менее $fee EPIC.',
      many: 'Тратит $count выходов. Комиссия не менее $fee EPIC.',
      few: 'Тратит $count выхода. Комиссия не менее $fee EPIC.',
      one: 'Тратит $count выход. Комиссия не менее $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutConsNothing => 'Пока нечего объединять.';

  @override
  String get deskOutConsOne => 'Нечего объединять: доступен один выход.';

  @override
  String deskOutConsInto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выхода в 1.',
      many: '$count выходов в 1.',
      few: '$count выхода в 1.',
      one: '$count выход в 1.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsIntoFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выхода в 1. Комиссия $fee EPIC.',
      many: '$count выходов в 1. Комиссия $fee EPIC.',
      few: '$count выхода в 1. Комиссия $fee EPIC.',
      one: '$count выход в 1. Комиссия $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutSplitCardTitle => 'Разделить';

  @override
  String get deskOutSplitCardText =>
      'Делает из доступного баланса больше выходов, чтобы несколько отправок могли идти друг за другом без ожидания.';

  @override
  String get deskOutSplitCardButton => 'Разделить…';

  @override
  String get deskOutConsCardTitle => 'Объединить';

  @override
  String get deskOutConsCardText =>
      'Сливает все доступные выходы в один. Следующая отправка дешевле; всё заблокировано до подтверждения.';

  @override
  String get deskOutConsCardButton => 'Объединить…';

  @override
  String get deskOutNotLoadedTitle => 'Выходы не загружены';

  @override
  String get deskOutNotLoadedText => 'Обновите, чтобы попробовать снова.';

  @override
  String get deskOutLoading => 'Загрузка данных кошелька';

  @override
  String get deskOutNoneTitle => 'Выходов пока нет';

  @override
  String get deskOutNoneText => 'Первый полученный платёж создаст выход.';

  @override
  String get deskOutFilterAll => 'Все';

  @override
  String get deskOutFilterSpendable => 'Доступные';

  @override
  String get deskOutFilterConfirming => 'Подтверждаются';

  @override
  String get deskOutFilterLocked => 'Заблокированы';

  @override
  String get deskOutSearchHint => 'Коммитмент';

  @override
  String get deskOutSearchLabel => 'Поиск выходов';

  @override
  String get deskOutClearSearch => 'Очистить поиск';

  @override
  String get deskOutShowSpent => 'Показать потраченные';

  @override
  String get deskOutNoMatchTitle => 'Выходы не найдены';

  @override
  String get deskOutNoMatchText =>
      'Попробуйте другой коммитмент или сбросьте фильтр.';

  @override
  String get deskOutClearFilter => 'Сбросить фильтр';

  @override
  String get deskOutTileSpendable => 'Доступно';

  @override
  String get deskOutTileConfirming => 'Подтверждается';

  @override
  String get deskOutTileImmature => 'Награды за майнинг';

  @override
  String get deskOutTileLocked => 'Заблокировано в отправках';

  @override
  String get deskOutTileTotal => 'Всего';

  @override
  String get deskOutStrategyTitle => 'Стратегия отправок';

  @override
  String get deskOutStrategySmallest => 'Наименьшие';

  @override
  String get deskOutStrategyAll => 'Все';

  @override
  String get deskOutStrategyHelpTitle => '«Наименьшие» или «Все»';

  @override
  String get deskOutSplitChangeTitle => 'Делить сдачу';

  @override
  String get deskOutSplitChangeText =>
      'Если после отправки осталось бы меньше 3 доступных выходов, а сдача не меньше 1 EPIC, она вернётся несколькими выходами, до 4, не меньше 0,5 EPIC каждый. Каждый лишний выход стоит 0,004 EPIC.';

  @override
  String get deskOutColValue => 'Сумма';

  @override
  String get deskOutColStatus => 'Статус';

  @override
  String get deskOutColConfirmations => 'Подтв.';

  @override
  String get deskOutColHeight => 'Высота';

  @override
  String get deskOutColTransaction => 'Транзакция';

  @override
  String get deskOutColCommitment => 'Коммитмент';

  @override
  String get deskOutStatusSpendable => 'Доступен';

  @override
  String get deskOutStatusConfirming => 'Подтверждается';

  @override
  String deskOutConfirmations(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number подтверждения',
      many: '$number подтверждений',
      few: '$number подтверждения',
      one: '$number подтверждение',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusAwaiting => 'Ждёт ответа';

  @override
  String get deskOutNoteWaitingSender => 'ждёт отправителя';

  @override
  String get deskOutStatusUnpaid => 'Неоплаченный счёт';

  @override
  String get deskOutNoteNotInBalance => 'не входит в баланс';

  @override
  String get deskOutStatusImmature => 'Созревает';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'остаётся $number подтверждения',
      many: 'остаётся $number подтверждений',
      few: 'остаётся $number подтверждения',
      one: 'остаётся $number подтверждение',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusMining => 'Майнинг';

  @override
  String get deskOutStatusLocked => 'Заблокирован';

  @override
  String deskOutNoteBySend(int id) {
    return 'отправкой #$id';
  }

  @override
  String deskOutNoteByPendingSend(String date) {
    return 'незавершённой отправкой · $date';
  }

  @override
  String get deskOutStatusSpent => 'Потрачен';

  @override
  String deskOutTxReceived(String date) {
    return 'Получено $date';
  }

  @override
  String deskOutTxSent(String date) {
    return 'Отправлено $date';
  }

  @override
  String deskOutCopyCommitment(String short) {
    return 'Копировать коммитмент $short';
  }

  @override
  String deskOutSplitSpentPart(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выхода ($amount EPIC)',
      many: '$count выходов ($amount EPIC)',
      few: '$count выхода ($amount EPIC)',
      one: '$count выход ($amount EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitMadePart(int count, String amount) {
    return 'новые выходы ($count) примерно по $amount EPIC';
  }

  @override
  String deskOutConsMadePart(String amount) {
    return 'один выход на $amount EPIC';
  }

  @override
  String deskOutSplitDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    return 'Тратит $spent и создаёт $made. Всё доступное заблокировано на $_temp0.';
  }

  @override
  String deskOutConsDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    return 'Тратит $spent и создаёт $made. Всё доступное заблокировано на $_temp0.';
  }

  @override
  String get deskOutFactFee => 'Комиссия сети';

  @override
  String get deskOutFactEach => 'Каждый выход';

  @override
  String deskOutFactAbout(String amount) {
    return 'около $amount EPIC';
  }

  @override
  String get deskOutFactLocked => 'Заблокировано';

  @override
  String deskOutFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'около $blocks блока',
      many: 'около $blocks блоков',
      few: 'около $blocks блоков',
      one: 'около $blocks блока',
    );
    return '$amount EPIC, $_temp0. Доступного не остаётся.';
  }

  @override
  String get deskOutMakeLabel => 'Сколько выходов';

  @override
  String get deskOutMakeRange => 'От 2 до 10.';

  @override
  String get deskOutStepperFewer => 'Меньше';

  @override
  String get deskOutStepperMore => 'Больше';

  @override
  String get deskOutFeeWorking => 'Считаем комиссию';

  @override
  String get deskOutNoEstimate => 'Нет оценки';

  @override
  String get deskOutEachMin => 'Каждый выход должен быть не меньше 0,5 EPIC.';

  @override
  String get deskOutNotEnoughFee => 'Не хватает на комиссию.';

  @override
  String deskOutSplitInto(int count) {
    return 'Разделить на $count';
  }

  @override
  String get deskOutConsolidateButton => 'Объединить';

  @override
  String get deskOutPostingSplit =>
      'Создаём и отправляем разделение в сеть. Не закрывайте приложение.';

  @override
  String get deskOutPostingCons =>
      'Создаём и отправляем объединение в сеть. Не закрывайте приложение.';

  @override
  String get deskOutSplitPosted => 'Разделение отправлено в сеть';

  @override
  String get deskOutConsPosted => 'Объединение отправлено в сеть';

  @override
  String deskOutSplitDoneText(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count выхода примерно по $amount EPIC, подтверждаются. Заблокировано на $_temp0.',
      many:
          '$count выходов примерно по $amount EPIC, подтверждаются. Заблокировано на $_temp1.',
      few:
          '$count выхода примерно по $amount EPIC, подтверждаются. Заблокировано на $_temp2.',
      one:
          '$count выход примерно по $amount EPIC, подтверждается. Заблокировано на $_temp3.',
    );
    return '$_temp4';
  }

  @override
  String deskOutConsDoneText(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks подтверждения',
      many: '$blocks подтверждений',
      few: '$blocks подтверждения',
      one: '$blocks подтверждение',
    );
    return 'Один выход на $amount EPIC, подтверждается. Заблокировано на $_temp0.';
  }

  @override
  String get deskOutNotPostedTitle => 'Не отправлено в сеть';

  @override
  String get deskOutNotPostedSplit =>
      'Разделение создано и сохранено, но узел его не принял. Отправьте его снова или отмените, чтобы разблокировать выходы.';

  @override
  String get deskOutNotPostedCons =>
      'Объединение создано и сохранено, но узел его не принял. Отправьте его снова или отмените, чтобы разблокировать выходы.';

  @override
  String get deskOutCancelSplit => 'Отменить разделение';

  @override
  String get deskOutCancelCons => 'Отменить объединение';

  @override
  String get deskOutPostAgain => 'Отправить снова';

  @override
  String get deskOutNotDoneTitle => 'Не выполнено';

  @override
  String deskOutNotDoneText(String error) {
    return '$error. Выходы не изменились.';
  }

  @override
  String get deskOutSomethingWrong => 'Что-то пошло не так';

  @override
  String get deskOutTryAgain => 'Повторить';

  @override
  String get deskOutToastNotPosted => 'Не отправлено в сеть';

  @override
  String get deskOutToastNotCancelled => 'Не отменено';

  @override
  String get deskOutSplitDialogTitle => 'Разделение выходов';

  @override
  String get deskOutConsDialogTitle => 'Объединение выходов';

  @override
  String get deskOutPostingDesc => 'Отправка в сеть';

  @override
  String get deskOutDoneDesc => 'Готово';

  @override
  String get deskOutSplitDesc =>
      'Больше выходов, чтобы несколько отправок могли идти друг за другом.';

  @override
  String get deskOutConsDesc => 'Один выход вместо многих.';

  @override
  String deskOutNothingText(String what) {
    return 'Нечего объединять: у кошелька $what.';
  }

  @override
  String get deskOutWhatFewer => 'меньше двух доступных выходов';

  @override
  String get deskOutWhatOne => 'один доступный выход';

  @override
  String get deskOvNotUpdated => 'Не обновлено';

  @override
  String get deskOvNodeNotStarted => 'Узел не запущен';

  @override
  String get deskOvNodeAddrTitle => 'Адрес узла обновлён';

  @override
  String deskOvNodeAddrText(String node) {
    return 'Сохранено как $node.';
  }

  @override
  String get deskOvNodeIncompatTitle => 'Несовместимая версия узла';

  @override
  String deskOvNodeUrl(String url) {
    return 'Узел: $url';
  }

  @override
  String get deskOvUsePublicNode => 'Публичный узел';

  @override
  String get deskOvUseLocalNode => 'Локальный узел';

  @override
  String get deskOvHide => 'Скрыть';

  @override
  String deskOvCantReachNode(String url) {
    return 'Не удаётся связаться с узлом $url';
  }

  @override
  String get deskOvCantReachNodeText =>
      'Баланс может быть устаревшим. Проверьте узел или выберите другой в настройках узла.';

  @override
  String get deskOvStarting => 'Запуск';

  @override
  String get deskOvStartNode => 'Запустить узел';

  @override
  String get deskOvNodeSettings => 'Настройки узла';

  @override
  String get deskOvTitle => 'Обзор';

  @override
  String get deskOvShowAmounts => 'Показать суммы';

  @override
  String get deskOvHideAmounts => 'Скрыть суммы';

  @override
  String get deskOvRefresh => 'Обновить';

  @override
  String get deskOvStepDone => 'готово';

  @override
  String get deskOvStepNow => 'выполняется';

  @override
  String get deskOvStepWait => 'ожидает';

  @override
  String deskOvStepSemantics(String text, String state) {
    return '$text, $state';
  }

  @override
  String get deskOvStartingUp => 'Запуск';

  @override
  String get deskOvStepUnlocked => 'Кошелёк разблокирован';

  @override
  String get deskOvStepConnected => 'Подключено к узлу';

  @override
  String get deskOvStepUpdating => 'Обновление баланса';

  @override
  String get deskOvStepEpicbox => 'Запуск приёма через Epicbox';

  @override
  String deskOvSyncTitle(int percent) {
    return 'Синхронизация узла: $percent %';
  }

  @override
  String get deskOvSyncText => 'Загружаются блоки.';

  @override
  String get deskOvSyncProgress => 'Ход синхронизации узла';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent % блокчейна';
  }

  @override
  String get deskOvReceiveEpic => 'Получить EPIC';

  @override
  String get deskOvSend => 'Отправить';

  @override
  String get deskOvReceive => 'Получить';

  @override
  String get deskOvSendWaits =>
      'Отправка возобновится, когда узел синхронизируется.';

  @override
  String get deskOvAvailable => 'Доступно';

  @override
  String deskOvAsOfBlock(String block) {
    return 'На блоке $block';
  }

  @override
  String get deskOvEmptyHint =>
      'Поделитесь адресом Epicbox, чтобы получить первые EPIC.';

  @override
  String get deskOvFiatNote => '  весь баланс';

  @override
  String get deskOvBreakTotal => 'Всего';

  @override
  String get deskOvBreakConfirming => 'Подтверждается';

  @override
  String get deskOvBreakImmature => 'Награды за майнинг';

  @override
  String get deskOvBreakAwaiting => 'Ждёт отправителя';

  @override
  String get deskOvBreakLocked => 'Заблокировано в отправках';

  @override
  String get deskOvUpdating => 'Обновление';

  @override
  String get deskOvHiddenAmount => 'Сумма скрыта';

  @override
  String get deskOvLoading => 'Загрузка платежей';

  @override
  String get deskOvEmptyTitle => 'Платежей пока нет';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Полученные EPIC сначала подтверждаются, а после $blocks подтверждения становятся доступны.',
      many:
          'Полученные EPIC сначала подтверждаются, а после $blocks подтверждений становятся доступны.',
      few:
          'Полученные EPIC сначала подтверждаются, а после $blocks подтверждений становятся доступны.',
      one:
          'Полученные EPIC сначала подтверждаются, а после $blocks подтверждения становятся доступны.',
    );
    return '$_temp0';
  }

  @override
  String get deskOvShowAddress => 'Показать адрес';

  @override
  String get deskOvReceiveFile => 'Получить файл';

  @override
  String get deskOvRecent => 'Последние операции';

  @override
  String deskOvViewAll(int count) {
    return 'Все ($count)';
  }

  @override
  String deskOvPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа файлом ждут завершения',
      many: '$count платежей файлом ждут завершения',
      few: '$count платежа файлом ждут завершения',
      one: '$count платёж файлом ждёт завершения',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => 'Завершите их файлом ответа от получателя.';

  @override
  String get deskOvFinalize => 'Завершить';

  @override
  String get deskTxMiningReward => 'Награда за майнинг';

  @override
  String get deskTxReceived => 'Получено';

  @override
  String get deskTxSent => 'Отправлено';

  @override
  String get deskTxUnknownSender => 'Отправитель неизвестен';

  @override
  String get deskTxUnknownRecipient => 'Получатель неизвестен';

  @override
  String get deskTxNoteBlock => 'Время блока. Отправитель неизвестен.';

  @override
  String get deskTxNoteScanTime =>
      'Время сканирования; время блока прочитать не удалось. Отправитель не записан.';

  @override
  String get deskTxNoteUnknown => 'Отправитель не записан.';

  @override
  String get deskTxFoundRestoredLabel => 'Восстановлено';

  @override
  String get deskTxFoundRestoredLine => 'Найдено в блокчейне';

  @override
  String get deskTxFoundRestoredStep => 'Найдено в блокчейне';

  @override
  String get deskTxFoundRestoredTip =>
      'Найдено в блокчейне при восстановлении этого кошелька. Отправитель не записан.';

  @override
  String get deskTxFoundRescanLabel => 'Найдено при сверке';

  @override
  String get deskTxFoundRescanLine => 'Найдено при сверке баланса';

  @override
  String get deskTxFoundRescanStep => 'Найдено при сверке баланса';

  @override
  String get deskTxFoundRescanTip =>
      'Найдено в блокчейне при сверке баланса. Отправитель не записан.';

  @override
  String get deskTxFoundScanLine => 'Найдено сканированием';

  @override
  String get deskTxFoundScanStep => 'Найдено сканированием';

  @override
  String get deskTxFoundScanTip =>
      'Найдено в блокчейне сканированием. Отправитель не записан.';

  @override
  String get deskTxBackupTip => 'Импортировано из файла данных кошелька.';

  @override
  String get deskTxFromBackup => 'Импортирован';

  @override
  String get deskTxStatusImmature => 'Созревает';

  @override
  String get deskTxStatusWaitingSender => 'Ждёт отправителя';

  @override
  String get deskTxStatusWaitingResponseFile => 'Ждёт файл ответа';

  @override
  String get deskTxStatusWaitingRecipient => 'Ждёт получателя';

  @override
  String get deskTxStatusWaitingBlock => 'Ждёт блок';

  @override
  String deskTxStatusConfirming(int confirmations, int needed) {
    return 'Подтверждение $confirmations/$needed';
  }

  @override
  String get deskTxStatusCancelled => 'Отменено';

  @override
  String get deskTxToday => 'сегодня';

  @override
  String get deskTxYesterday => 'вчера';

  @override
  String deskTxDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String deskTxTodayAt(String time) {
    return 'Сегодня $time';
  }

  @override
  String deskTxDayToday(String date) {
    return 'Сегодня · $date';
  }

  @override
  String deskTxDayYesterday(String date) {
    return 'Вчера · $date';
  }

  @override
  String deskTxFee(String amount) {
    return 'Комиссия $amount';
  }

  @override
  String get deskTxFinalize => 'Завершить';

  @override
  String deskTxSemReceived(String amount, String who, String status) {
    return 'Получено $amount, $who, $status';
  }

  @override
  String deskTxSemSent(String amount, String who, String status) {
    return 'Отправлено $amount, $who, $status';
  }

  @override
  String deskTxSemKind(String kind, String amount, String who, String status) {
    return '$kind $amount, $who, $status';
  }

  @override
  String get deskTxHiddenAmount => 'сумма скрыта';

  @override
  String get deskTxNowBackup =>
      'Импортировано из файла данных кошелька. Статус в цепочке не проверялся.';

  @override
  String deskTxNowImmature(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Подтверждено, но награду за майнинг можно потратить только после $countString подтверждения.',
      many:
          'Подтверждено, но награду за майнинг можно потратить только после $countString подтверждений.',
      few:
          'Подтверждено, но награду за майнинг можно потратить только после $countString подтверждений.',
      one:
          'Подтверждено, но награду за майнинг можно потратить только после $countString подтверждения.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Ждёт, пока отправитель отправит её в сеть.';

  @override
  String get deskTxNowWaitingResponseFile =>
      'Ждём файл ответа. Когда он придёт, завершите транзакцию.';

  @override
  String get deskTxNowWaitingRecipient =>
      'Ждём подписи получателя. Ничего не уйдёт из кошелька, пока транзакция не завершена.';

  @override
  String get deskTxNowPosted => 'Отправлено в сеть, ждёт блок.';

  @override
  String deskTxNowConfirming(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'В блоке, $confirmations из $needed подтверждения.',
      many: 'В блоке, $confirmations из $needed подтверждений.',
      few: 'В блоке, $confirmations из $needed подтверждений.',
      one: 'В блоке, $confirmations из $needed подтверждения.',
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
      other: 'Подтверждено, $confirmationsString подтверждения.',
      many: 'Подтверждено, $confirmationsString подтверждений.',
      few: 'Подтверждено, $confirmationsString подтверждения.',
      one: 'Подтверждено, $confirmationsString подтверждение.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Отменено';

  @override
  String get deskTxNotCancelled => 'Не отменено';

  @override
  String get deskTxCancelled => 'Транзакция отменена';

  @override
  String get deskTxCancelling => 'Отмена';

  @override
  String get deskTxHeadRestored => 'восстановлено';

  @override
  String get deskTxHeadFoundOnChain => 'Найдено в блокчейне';

  @override
  String get deskTxHeadBackup => 'импортирован из файла данных кошелька';

  @override
  String deskTxHeadFrom(String who) {
    return 'от $who';
  }

  @override
  String deskTxHeadTo(String who) {
    return 'для $who';
  }

  @override
  String get deskTxSubProgress => 'Ход';

  @override
  String get deskTxSubDetails => 'Подробности';

  @override
  String get deskTxFactDate => 'Дата';

  @override
  String get deskTxFactFrom => 'От';

  @override
  String get deskTxFactTo => 'Кому';

  @override
  String get deskTxCopyAddress => 'Копировать адрес';

  @override
  String get deskTxFactMethod => 'Способ';

  @override
  String get deskTxFactAmount => 'Сумма';

  @override
  String get deskTxFactFee => 'Комиссия';

  @override
  String get deskTxFactTotal => 'Итого';

  @override
  String get deskTxFactMessage => 'Сообщение';

  @override
  String get deskTxSignedByRecipient => 'Получатель подписал';

  @override
  String get deskTxTechTitle => 'Технические сведения';

  @override
  String get deskTxStepMined => 'Добыто в блоке';

  @override
  String get deskTxStepSpendable => 'Завершён';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'остаётся $count подтверждения',
      many: 'остаётся $count подтверждений',
      few: 'остаётся $count подтверждения',
      one: 'остаётся $count подтверждение',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Платёж получен';

  @override
  String get deskTxStepCreated => 'Платёж начат';

  @override
  String get deskTxStepSignedReturned => 'Подписано и возвращено';

  @override
  String get deskTxStepWaitingFile => 'Ждём файл ответа';

  @override
  String get deskTxStepWaitingRecipient => 'Ждёт получателя';

  @override
  String get deskTxStepPosted => 'Отправлено в сеть';

  @override
  String get deskTxStepConfirming => 'Подтверждение';

  @override
  String deskTxStepProgress(int confirmations, int needed) {
    return '$confirmations из $needed';
  }

  @override
  String get deskTxCancelIncomingTitle => 'Отменить этот платёж?';

  @override
  String get deskTxCancelOutgoingTitle => 'Отменить этот платёж?';

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC для $who. Пока ничего не оплачено: отмена бесплатна и надёжна.';
  }

  @override
  String get deskTxCancelKeep => 'Оставить';

  @override
  String get deskTxCancelIncomingAction => 'Отменить платёж';

  @override
  String get deskTxCancelOutgoingAction => 'Отменить платёж';

  @override
  String get deskOnbWelcomeAdd => 'Добавить кошелёк';

  @override
  String get deskOnbWelcomeTagline =>
      'Ключи и монеты остаются на этом компьютере под защитой пароля.';

  @override
  String get deskOnbWelcomeCreate => 'Создать новый кошелёк';

  @override
  String get deskOnbWelcomeImport => 'Импортировать кошельки';

  @override
  String get deskOnbWelcomeImportSub => 'Из старого Epic Wallet или из папки';

  @override
  String get deskOnbWelcomeCreateSub => 'С новой фразой восстановления';

  @override
  String get deskOnbWelcomeRestoreSub => 'Также из Stack Wallet или Epic Pay';

  @override
  String get deskOnbWelcomeRestore => 'Восстановить по фразе';

  @override
  String get deskOnbWelcomeTestNote =>
      'Новые кошельки создаются в этой тестовой сети.';

  @override
  String get deskOnbWelcomeBack => 'Назад к разблокировке';

  @override
  String get deskOnbWelcomeAdvanced => 'Дополнительно';

  @override
  String get deskOnbWelcomeNetwork => 'Сеть';

  @override
  String get deskOnbWelcomeFolder => 'Папка данных приложения';

  @override
  String get deskOnbWelcomeHideDetails => 'Скрыть подробности';

  @override
  String get deskOnbWelcomeMoreAbout => 'Подробнее';

  @override
  String get deskOnbWelcomeFolderWhere =>
      'Где приложение хранит кошельки и настройки.';

  @override
  String get deskOnbWelcomeFolderDetail =>
      'С локальным узлом здесь хранится и блокчейн. Новая папка должна быть пустой: приложение создаст в ней свои папки и будет пользоваться ею дальше.';

  @override
  String deskOnbWelcomeUsing(String folder) {
    return 'Используется $folder. Чтобы перейти на неё, приложение перезапустится.';
  }

  @override
  String get deskOnbWelcomeLocked =>
      'Её можно изменить только до добавления первого кошелька.';

  @override
  String get deskOnbWelcomeChooseFolder => 'Выбрать папку';

  @override
  String get deskOnbWelcomeDefaultFolder => 'Папка по умолчанию';

  @override
  String get deskOnbWelcomeFolderNotEmpty =>
      'Эта папка не пустая. Выберите новую пустую папку.';

  @override
  String get deskOnbWelcomeFolderIsWallet =>
      'Это папка кошелька. Выберите новую пустую папку.';

  @override
  String get deskOnbWelcomeChoose => 'Выбрать';

  @override
  String get deskOnbStepPassword => 'Пароль';

  @override
  String get deskOnbStepPhrase => 'Фраза восстановления';

  @override
  String get deskOnbCreateStageCreate => 'Создание фразы восстановления';

  @override
  String get deskOnbCreateStageSave => 'Сохранение кошелька';

  @override
  String get deskOnbCreateNotCreated => 'Кошелёк не создан';

  @override
  String get deskOnbCreateCreating => 'Создание кошелька';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'Кошелёк в $network, тестовой сети.';
  }

  @override
  String get deskOnbCreateDiskFull =>
      'Кошелёк не сохранён: диск заполнен. Освободите место и попробуйте снова.';

  @override
  String get deskOnbCreateWait => 'Не закрывайте приложение.';

  @override
  String get deskOnbCreateLocking => 'Блокировка открытого кошелька';

  @override
  String get deskOnbCreateSide => 'Новый кошелёк';

  @override
  String get deskOnbCreateTitle => 'Создать кошелёк';

  @override
  String get deskOnbCreateLead =>
      'Пароль открывает этот кошелёк на этом компьютере; вернуть монеты можно только по фразе восстановления.';

  @override
  String get deskOnbCreateTestNote =>
      'Кошелёк в тестовой сети, не для настоящих EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'Запишите эти слова на бумаге по порядку. Только с их помощью можно восстановить этот кошелёк.';

  @override
  String get deskOnbCreateRevealFirst => 'Сначала откройте фразу';

  @override
  String get deskOnbCreateWarn =>
      'Любой, у кого есть эти слова, может забрать монеты.';

  @override
  String get deskOnbCreateReveal => 'Показать фразу';

  @override
  String get deskOnbCreateCheckScreen => 'Убедитесь, что никто не видит экран.';

  @override
  String get deskOnbCreateHide => 'Скрыть';

  @override
  String get deskOnbCreateShowQr => 'Показать QR';

  @override
  String get deskOnbCreateHideQr => 'Скрыть QR-код';

  @override
  String get deskOnbCreateQrWarn =>
      'Любой, кто отсканирует этот код, может забрать монеты';

  @override
  String get deskOnbCreateQrWarnText =>
      'Сканируйте его только в другой кошелёк, которому доверяете.';

  @override
  String get deskOnbCreateQrLabel => 'Фраза восстановления в виде QR-кода';

  @override
  String deskOnbCreateWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return 'У меня записаны все $_temp0';
  }

  @override
  String get deskOnbRestoreDone => 'Кошелёк восстановлен.';

  @override
  String get deskOnbRestoreNotRestored => 'Кошелёк не восстановлен';

  @override
  String get deskOnbRestoreRestoring => 'Восстановление кошелька';

  @override
  String deskOnbRestorePermission(String folder) {
    return 'Файлы кошелька не записаны: нет прав на $folder. Разрешите запись в эту папку и повторите попытку.';
  }

  @override
  String get deskOnbRestoreWait =>
      'Не закрывайте приложение. Баланс появится после первого сканирования.';

  @override
  String get deskOnbRestoreSide => 'Восстановить кошелёк';

  @override
  String get deskOnbRestorePasswordLead =>
      'Задайте пароль, который открывает этот кошелёк на этом компьютере.';

  @override
  String get deskOnbRestoreNothingToPaste =>
      'Нечего вставить: в буфере обмена нет слов.';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return 'Слова $position («$word») нет в списке слов.';
  }

  @override
  String deskOnbRestoreAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Все $count слова верны.',
      many: 'Все $count слов верны.',
      few: 'Все $count слова верны.',
      one: 'Все $count слово верны.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreChecksumFirm =>
      'Контрольная сумма фразы не сходится. Сверьте каждое слово с бумагой.';

  @override
  String deskOnbRestoreChecksumSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Пока $count слова; контрольная сумма не сходится. Продолжайте ввод или сверьте каждое слово с бумагой.',
      many:
          'Пока $count слов; контрольная сумма не сходится. Продолжайте ввод или сверьте каждое слово с бумагой.',
      few:
          'Пока $count слова; контрольная сумма не сходится. Продолжайте ввод или сверьте каждое слово с бумагой.',
      one:
          'Пока $count слово; контрольная сумма не сходится. Продолжайте ввод или сверьте каждое слово с бумагой.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWordsLead =>
      'Введите слова по порядку или вставьте всю фразу в любое поле.';

  @override
  String get deskOnbRestoreClear => 'Очистить';

  @override
  String get deskOnbRestoreWords => 'Слова';

  @override
  String deskOnbRestoreFilledOf(int filled, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total слова',
      many: '$total слов',
      few: '$total слов',
      one: '$total слова',
    );
    return '$filled из $_temp0';
  }

  @override
  String get deskOnbSameTitle => 'Этот кошелёк уже здесь';

  @override
  String get deskOnbSameBody =>
      'Фраза принадлежит кошельку из списка. Ничего не добавлено.';

  @override
  String get deskOnbSameWallet => 'Кошелёк';

  @override
  String get deskOnbSameNote =>
      'Откройте его с его паролем или задайте новый пароль по этой фразе.';

  @override
  String get deskOnbSameOpen => 'Открыть его';

  @override
  String get deskOnbUnlockWhoWindows =>
      'Этот кошелёк может открыть любой, кто пользуется этим компьютером как вы.';

  @override
  String get deskOnbUnlockWho =>
      'Этот кошелёк может открыть любой, кто пользуется этим компьютером как вы.';

  @override
  String get deskOnbUnlockWrong =>
      'Неверный пароль. Проверьте Caps Lock и раскладку клавиатуры.';

  @override
  String deskOnbUnlockPortInUse(String port) {
    return 'Порт $port занят другой программой. Закройте её и повторите попытку.';
  }

  @override
  String get deskOnbUnlockStageCheck => 'Проверка файлов кошелька';

  @override
  String get deskOnbUnlockStageWallet => 'Запуск службы кошелька';

  @override
  String get deskOnbUnlockStageUnlock => 'Разблокировка кошелька';

  @override
  String get deskOnbUnlockEnter => 'Введите пароль';

  @override
  String get deskOnbUnlockRememberedUnavailable =>
      'Запомненный пароль недоступен. Введите пароль.';

  @override
  String get deskOnbUnlockRememberedForgotten =>
      'Запомненный пароль удалён. Введите пароль.';

  @override
  String get deskOnbUnlockNotRemembered => 'Не запомнено';

  @override
  String get deskOnbUnlockKeyStore =>
      'Хранилище ключей этого компьютера недоступно.';

  @override
  String get deskOnbUnlockThisWallet => 'этот кошелёк';

  @override
  String get deskOnbUnlockFailed => 'Не удалось разблокировать';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'Разблокировка: $name';
  }

  @override
  String get deskOnbUnlockNote =>
      'Затем узел, баланс и приём завершают загрузку в фоне.';

  @override
  String get deskOnbUnlockTitle => 'Разблокировка кошелька';

  @override
  String get deskOnbUnlockRemember => 'Запомнить на этом компьютере';

  @override
  String deskOnbUnlockRememberFor(String who) {
    return 'На 30 дней. $who';
  }

  @override
  String get deskOnbUnlockMissingTitle => 'Папка этого кошелька пропала';

  @override
  String deskOnbUnlockMissingText(String folder) {
    return 'Она была в $folder. Удалите кошелёк из списка или восстановите его по фразе восстановления.';
  }

  @override
  String get deskOnbUnlockRemove => 'Удалить';

  @override
  String get deskOnbUnlockTryAgain => 'Повторить';

  @override
  String get deskOnbUnlockButton => 'Разблокировать';

  @override
  String get deskOnbNodeFreeUnknown => 'свободное место неизвестно';

  @override
  String deskOnbNodeFreeHere(String size) {
    return 'свободно: $size';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'Сейчас около $size на диске,';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return 'Сейчас $size на диске,';
  }

  @override
  String get deskOnbNodeFirewall => 'Windows один раз спросит,';

  @override
  String get deskOnbNodeFirewallText =>
      'пропустить ли его через брандмауэр. Разрешите для частных сетей.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'объём медленно растёт · $free';
  }

  @override
  String get deskOnbNodeFound => 'Найден';

  @override
  String deskOnbNodeFoundAt(String version, String address) {
    return 'Epic $version по адресу $address';
  }

  @override
  String deskOnbNodeHeight(String height) {
    return 'высота $height';
  }

  @override
  String get deskOnbNodeSynced => 'синхронизирован';

  @override
  String get deskOnbNodeNoAnswer => 'Узел не отвечает';

  @override
  String deskOnbNodeNoAnswerAt(String address) {
    return 'по адресу $address. Запустите его или проверьте адрес и порт.';
  }

  @override
  String get deskOnbNodeExisting =>
      'Использовать узел, уже запущенный на этом компьютере';

  @override
  String get deskOnbNodeExistingText =>
      'Подключается к уже запущенному здесь узлу Epic GUI или CLI.';

  @override
  String get deskOnbNodeAddress => 'Адрес узла на этом компьютере';

  @override
  String get deskOnbNodeCheck => 'Проверить';

  @override
  String get deskOnbNodeBundled => 'Запустить локальный узел';

  @override
  String get deskOnbNodeBundledText =>
      'После «Сохранить» загружает блокчейн в папку кошелька.';

  @override
  String deskOnbNodeFallback(String host) {
    return 'Использовать $host, пока локальный узел не синхронизирован';
  }

  @override
  String get deskOnbNodeDialogTitle => 'Локальный узел';

  @override
  String get deskOnbNodeDialogBody =>
      'Что значит запускать узел здесь и какой узел использовать.';

  @override
  String get deskOnbNodeUseThis => 'Использовать этот узел';

  @override
  String get deskOnbNodeStart => 'Запустить локальный узел';

  @override
  String deskOnbRestorePasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Вставлено $count слова; во фразе 12, 15, 18, 21 или 24 слова.',
      many: 'Вставлено $count слов; во фразе 12, 15, 18, 21 или 24 слова.',
      few: 'Вставлено $count слова; во фразе 12, 15, 18, 21 или 24 слова.',
      one: 'Вставлено $count слово; во фразе 12, 15, 18, 21 или 24 слова.',
    );
    return '$_temp0';
  }

  @override
  String deskOnbWordN(int number) {
    return 'Слово $number';
  }

  @override
  String get deskOnbImportEnterOld => 'Введите старый пароль';

  @override
  String deskOnbImportNewShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count символа',
      many: '$count символов',
      few: '$count символов',
      one: '$count символа',
    );
    return 'Новый пароль: не меньше $_temp0';
  }

  @override
  String get deskOnbImportNewDiffer => 'Новые пароли не совпадают';

  @override
  String deskOnbImportWalletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кошелька',
      many: '$count кошельков',
      few: '$count кошелька',
      one: '$count кошелёк',
    );
    return '$_temp0';
  }

  @override
  String deskOnbImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count кошелька.',
      many: 'Импортировано $count кошельков.',
      few: 'Импортировано $count кошелька.',
      one: 'Импортирован $count кошелёк.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFindingTitle => 'Поиск кошельков';

  @override
  String get deskOnbImportFindingLead =>
      'Поиск в папках старых версий Epic Wallet и программы epic.';

  @override
  String deskOnbImportFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count кошелька',
      many: 'Найдено $count кошельков',
      few: 'Найдено $count кошелька',
      one: 'Найден $count кошелёк',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportNoneTitle => 'Кошельки не найдены';

  @override
  String get deskOnbImportNoneLead =>
      'Выберите папку кошелька или восстановите его по фразе восстановления.';

  @override
  String get deskOnbImportChooseTitle => 'Выбор кошельков';

  @override
  String get deskOnbImportChooseLead =>
      'Отмеченные кошельки будут добавлены в приложение. История восстанавливается сканированием.';

  @override
  String get deskOnbImportCheckTitle => 'Проверка кошельков';

  @override
  String get deskOnbImportCheckLead =>
      'Кошелёк, который использует другая программа, не импортируется.';

  @override
  String get deskOnbImportTitle => 'Импорт';

  @override
  String get deskOnbImportLead =>
      'Каждый кошелёк один раз запросит свой старый пароль.';

  @override
  String get deskOnbImportDoneTitle => 'Кошельки импортированы';

  @override
  String get deskOnbImportDoneLead =>
      'При первой разблокировке каждого кошелька блокчейн сканируется в поисках его истории.';

  @override
  String deskOnbImportSelected(int selected, int total) {
    return 'Выбрано $selected из $total';
  }

  @override
  String get deskOnbImportChecking => 'Проверка…';

  @override
  String get deskOnbImportCloseOther =>
      'Закройте другую программу или пропустите кошелёк';

  @override
  String deskOnbImportImportedOf(int done, int total) {
    return 'Импортировано $done из $total';
  }

  @override
  String get deskOnbImportOpen => 'Открыть кошелёк';

  @override
  String get deskOnbImportStepFind => 'Поиск';

  @override
  String get deskOnbImportStepChoose => 'Выбор';

  @override
  String get deskOnbImportStepCheck => 'Проверка';

  @override
  String get deskOnbImportBack => 'Назад';

  @override
  String get deskOnbImportSkip => 'Пропустить';

  @override
  String get deskOnbImportOlder => 'Старый Epic Wallet';

  @override
  String get deskOnbImportOlderSub => 'Кошельки и папки';

  @override
  String get deskOnbImportEpicProgram => 'Программа epic';

  @override
  String get deskOnbImportSearching => 'Поиск…';

  @override
  String get deskOnbImportRestore => 'Восстановить по фразе';

  @override
  String deskOnbImportLastUsed(String date) {
    return 'Использовался $date';
  }

  @override
  String deskOnbImportSecondCopy(String reason) {
    return '$reason. Отметьте, чтобы добавить вторую копию.';
  }

  @override
  String deskOnbImportCannot(String name) {
    return '$name: импорт невозможен';
  }

  @override
  String get deskOnbImportInApp => 'Уже в приложении';

  @override
  String get deskOnbImportSameWallet => 'Тот же кошелёк';

  @override
  String get deskOnbImportNotInUse => 'Не используется';

  @override
  String get deskOnbImportNotChecked => 'Не проверен';

  @override
  String get deskOnbImportSkipped => 'Пропущен';

  @override
  String get deskOnbImportInUse => 'Используется';

  @override
  String get deskOnbImportInUseText =>
      'Используется другой программой. Закройте старый Epic Wallet или программу epic и проверьте снова.';

  @override
  String get deskOnbImportCheckAgain => 'Проверить снова';

  @override
  String get deskOnbImportImported => 'Импортирован';

  @override
  String get deskOnbImportImporting => 'Импорт…';

  @override
  String get deskOnbImportWaiting => 'Ожидает';

  @override
  String get deskOnbImportOldPassword => 'Старый пароль';

  @override
  String deskOnbImportOldHelp(String name) {
    return 'Пароль кошелька $name в старом приложении';
  }

  @override
  String deskOnbImportOldOf(String name) {
    return 'Старый пароль кошелька $name';
  }

  @override
  String deskOnbImportOldShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'не меньше $count символа.',
      many: 'не меньше $count символов.',
      few: 'не меньше $count символов.',
      one: 'не меньше $count символа.',
    );
    return 'Старый пароль слишком короткий. Придумайте новый, $_temp0';
  }

  @override
  String get deskOnbImportNewPassword => 'Новый пароль';

  @override
  String get deskOnbImportRepeat => 'Повтор';

  @override
  String get deskOnbImportRepeatNew => 'Повторите новый пароль';

  @override
  String get deskOnbImportUnchanged =>
      'Старые папки не изменены. Старое приложение по-прежнему может их открыть.';

  @override
  String get deskOnbImportStopTitle => 'Остановить импорт?';

  @override
  String get deskOnbImportStopBody =>
      'Уже импортированные кошельки будут удалены. Старые папки не изменены.';

  @override
  String get deskOnbImportGoBack => 'Вернуться';

  @override
  String get deskOnbImportStop => 'Остановить импорт';

  @override
  String get deskRailWaitingTor => 'Ждёт Tor';

  @override
  String get deskRailOn => 'Вкл.';

  @override
  String get deskRailConnecting => 'Подключение';

  @override
  String get deskRailSlow => 'Медленно';

  @override
  String get deskRailNotAnswering => 'Не отвечает';

  @override
  String get deskRailOff => 'Выкл.';

  @override
  String get deskRailChecking => 'Проверка';

  @override
  String get deskRailOverTor => 'Через Tor';

  @override
  String get deskRailWaitsForTor => 'Ждёт подключения Tor.';

  @override
  String get deskRailPaymentsWait => 'Платежи ждут на сервере Epicbox.';

  @override
  String get deskRailOpenEpicbox => 'Открыть приём через Epicbox';

  @override
  String get deskRailStarting => 'Запуск';

  @override
  String get deskRailNotReceiving => 'Приём не работает';

  @override
  String get deskRailOnInternet => 'Вкл. · интернет';

  @override
  String get deskRailOnLocal => 'Вкл. · локально';

  @override
  String get deskRailPortInUse => 'Порт занят';

  @override
  String get deskRailStopped => 'Остановлен';

  @override
  String deskRailPortInternet(String port) {
    return 'Порт $port · из интернета';
  }

  @override
  String deskRailPortLocal(String port) {
    return 'Порт $port · только этот компьютер';
  }

  @override
  String get deskRailOpenHttp => 'Открыть приём: Ссылка · HTTP';

  @override
  String get deskRailTorNotInBuild => 'Нет в этой сборке';

  @override
  String get deskRailStartingDots => 'Запуск…';

  @override
  String deskRailTorSlow(String problem) {
    return '$problem. Отправка работает.';
  }

  @override
  String get deskRailTorNoAddress => 'Адрес Tor не опубликован';

  @override
  String get deskRailOpenPrivacy => 'Открыть настройки приватности';

  @override
  String get deskRailNode => 'Узел';

  @override
  String get deskRailOpenNode => 'Открыть настройки узла';

  @override
  String get deskAppNodeSyncedTitle => 'Локальный узел синхронизирован';

  @override
  String get deskAppNodeSyncedBody =>
      'У локального узла есть весь блокчейн, им уже можно пользоваться. Чтобы переключиться на него, приложение перезапустится.';

  @override
  String get deskAppNotNow => 'Не сейчас';

  @override
  String get deskAppRestartNow => 'Перезапустить';

  @override
  String get deskAppFirstScanTitle => 'Первое сканирование';

  @override
  String get deskAppFirstScanBody =>
      'Кошелёк сканирует блокчейн в поисках своих монет, и им можно пользоваться.';

  @override
  String get deskAppScanOutput => 'Ход сканирования';

  @override
  String get deskAppWaitingOutput => 'Ждём первых строк…';

  @override
  String get deskShellNavOverview => 'Обзор';

  @override
  String get deskShellNavActivity => 'Активность';

  @override
  String get deskShellNavSend => 'Отправить';

  @override
  String get deskShellNavReceive => 'Получить';

  @override
  String get deskShellNavOutputs => 'Выходы';

  @override
  String get deskShellNavContacts => 'Контакты';

  @override
  String get deskShellNavSettings => 'Настройки';

  @override
  String get deskShellTitleImportTx => 'Импорт транзакции';

  @override
  String get deskShellTitleFinalizeTx => 'Завершение транзакции';

  @override
  String get deskShellLocksAfterSend =>
      'Кошелёк заблокируется, когда платёж будет отправлен';

  @override
  String get deskShellNotQuitTitle => 'Выход отложен';

  @override
  String get deskShellNotQuitBody =>
      'Идёт отправка. Выйдите снова, когда она закончится.';

  @override
  String get deskShellLockedTitle => 'Кошелёк заблокирован';

  @override
  String get deskShellLockedBody =>
      'Выход закроет приложение, когда ядро кошелька будет подключено.';

  @override
  String deskShellLockWallet(String keys) {
    return 'Заблокировать кошелёк ($keys)';
  }

  @override
  String get deskShellMainNav => 'Основная навигация';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Открыть настройки кошелька: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Сменить кошелёк';

  @override
  String get deskTourOverviewTitle => 'Обзор';

  @override
  String get deskTourOverviewText =>
      'Баланс и то, что ещё подтверждается, а ниже последние платежи. Всё остальное — в боковой панели.';

  @override
  String get deskTourSendTitle => 'Отправить';

  @override
  String get deskTourSendText =>
      'Заплатите на адрес Epicbox или создайте файл транзакции, который кто-то подпишет. Перед отправкой — проверка.';

  @override
  String get deskTourReceiveTitle => 'Получить';

  @override
  String get deskTourReceiveText =>
      'Адрес Epicbox этого кошелька: поделитесь им, чтобы получить платёж. Файлы транзакций для подписи или завершения — ниже.';

  @override
  String get deskTourInvoicesTitle => 'Счета';

  @override
  String get deskTourInvoicesText =>
      'Оплатите присланный вам счёт или выставьте счёт тому, кто вам должен. Вкладки переключают между ними.';

  @override
  String get deskTourActivityTitle => 'Активность';

  @override
  String get deskTourActivityText =>
      'Все транзакции с ходом выполнения и подробностями. Число у этого пункта боковой панели значит, что что-то ждёт вашего действия.';

  @override
  String get deskTourContactsTitle => 'Контакты';

  @override
  String get deskTourContactsText =>
      'Сохранённые адреса с именами. «Отправить» выбирает отсюда.';

  @override
  String get deskTourNodeTitle => 'Настройки › Узел';

  @override
  String get deskTourNodeText =>
      'Из какого узла кошелёк читает цепочку. Остальные страницы настроек перечислены слева.';

  @override
  String get deskTourHelpTitle => 'Справка';

  @override
  String get deskTourHelpText =>
      'Темы справки, «Сообщить о проблеме» и «Показать тур снова».';

  @override
  String deskTourCounter(int current, int total) {
    return '$current из $total';
  }

  @override
  String get deskTourSemantics => 'Тур по кошельку';

  @override
  String get deskTourSkip => 'Пропустить тур';

  @override
  String get deskTourBack => 'Назад';

  @override
  String get deskTourNext => 'Далее';

  @override
  String get deskKitUnknown => 'Неизвестно';

  @override
  String get deskKitRingCancelled => 'Отменено';

  @override
  String get deskKitRingConfirmed => 'Подтверждено';

  @override
  String deskKitRingProgress(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '$confirmations из $needed подтверждений',
      many: '$confirmations из $needed подтверждений',
      few: '$confirmations из $needed подтверждений',
      one: '$confirmations из $needed подтверждений',
    );
    return '$_temp0';
  }

  @override
  String get deskKitHiddenAmount => 'Сумма скрыта';

  @override
  String get deskKitChooseFile => 'Выбрать файл';

  @override
  String deskKitNeedAction(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ждут действия',
      many: '$count ждут действия',
      few: '$count ждут действия',
      one: '$count ждёт действия',
    );
    return '$label, $_temp0';
  }

  @override
  String get deskKitCloseEsc => 'Закрыть (Esc)';

  @override
  String get deskKitOptional => 'Необязательно';

  @override
  String get deskKitBackAlt => 'Назад (Alt+←)';

  @override
  String deskKitStepOf(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get deskKitHeroCaptionEpicbox => 'ХРАНИТ СЕРВЕР EPICBOX';

  @override
  String get deskKitHeroCaptionHttp => 'ПРЯМО В КОШЕЛЁК';

  @override
  String get deskKitHeroCaptionTor => 'НАПРЯМУЮ, ЧЕРЕЗ TOR';

  @override
  String get deskKitHeroCaptionFile => 'ФАЙЛ ТУДА, ОТВЕТ ОБРАТНО';

  @override
  String get deskKitHeroLabelEpicbox =>
      'Epicbox: платёж уходит на сервер Epicbox, который хранит его, пока кошелёк получателя не вернётся';

  @override
  String get deskKitHeroLabelHttp =>
      'Ссылка · HTTP: платёж идёт прямо в кошелёк получателя, который должен быть открыт';

  @override
  String get deskKitHeroLabelTor =>
      'Ссылка · Tor: платёж идёт прямо в кошелёк получателя через сеть Tor';

  @override
  String get deskKitHeroLabelFile =>
      'Напрямую · Передача файла: файл транзакции передаётся, возвращается файл ответа, затем отправитель завершает платёж';

  @override
  String get deskKitReachCheck => 'Проверить';

  @override
  String get deskKitReachChecking => 'Проверка из интернета…';

  @override
  String get deskKitReachNoIpTitle => 'Публичный IP не найден';

  @override
  String get deskKitReachNoIpText =>
      'Не удалось узнать его через интернет. Попробуйте позже.';

  @override
  String deskKitReachNoIpTextLan(String address) {
    return 'Не удалось узнать его через интернет. Попробуйте позже. В вашей сети: $address.';
  }

  @override
  String get deskKitReachClosedTitle => 'Недоступен из интернета';

  @override
  String deskKitReachClosedText(String port) {
    return 'Перенаправьте TCP-порт $port на роутере на этот компьютер и проверьте снова.';
  }

  @override
  String deskKitReachClosedTextLan(String port, String address) {
    return 'Перенаправьте TCP-порт $port на роутере на этот компьютер ($address) и проверьте снова.';
  }

  @override
  String get deskKitReachUnknownTitle => 'Доступность неизвестна';

  @override
  String get deskKitReachUnknownText =>
      'Проверка порта не ответила. Попробуйте позже.';

  @override
  String deskKitReachUnknownTextLan(String address) {
    return 'Проверка порта не ответила. Попробуйте позже. В вашей сети: $address.';
  }

  @override
  String get deskKitReachOpenTitle => 'Доступен из интернета';

  @override
  String deskKitReachOpenText(String port) {
    return 'Порт $port перенаправлен.';
  }

  @override
  String deskKitReachOpenTextLan(String port, String address) {
    return 'Порт $port перенаправлен. В вашей сети: $address.';
  }

  @override
  String deskKitAgeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count с назад',
      many: '$count с назад',
      few: '$count с назад',
      one: '$count с назад',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин назад',
      many: '$count мин назад',
      few: '$count мин назад',
      one: '$count мин назад',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч назад',
      many: '$count ч назад',
      few: '$count ч назад',
      one: '$count ч назад',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн. назад',
      many: '$count дн. назад',
      few: '$count дн. назад',
      one: '$count дн. назад',
    );
    return '$_temp0';
  }

  @override
  String get deskKitNodeBefore410 => 'узел старше 4.1.0';

  @override
  String get deskKitNodeNoAnswer => 'нет ответа';

  @override
  String get deskKitNodesDisagree => 'Узлы расходятся в последнем блоке';

  @override
  String deskKitNodesAgree(String height) {
    return 'Узлы согласны на $height';
  }

  @override
  String deskKitNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up из $total узлов работают',
      many: '$up из $total узлов работают',
      few: '$up из $total узлов работают',
      one: '$up из $total узлов работает',
    );
    return '$_temp0';
  }

  @override
  String deskKitEpicboxUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up из $total серверов Epicbox работают',
      many: '$up из $total серверов Epicbox работают',
      few: '$up из $total серверов Epicbox работают',
      one: '$up из $total серверов Epicbox работает',
    );
    return '$_temp0';
  }

  @override
  String deskKitLastBlock(String age) {
    return 'последний блок $age';
  }

  @override
  String deskKitLimitedNetwork(String site) {
    return '$site недоступен; сведения получены только от узла.';
  }

  @override
  String get deskKitFactHeight => 'Высота';

  @override
  String get deskKitFactVersion => 'Версия';

  @override
  String get deskKitFactAccepts => 'Принимает транзакции';

  @override
  String get deskKitFactYes => 'Да';

  @override
  String get deskKitFactNotYet => 'Пока нет';

  @override
  String get deskKitFactUnknown => 'Неизвестно';

  @override
  String get deskKitFactLatency => 'Задержка';

  @override
  String get deskKitFactUptime => 'Доступность';

  @override
  String get deskKitFactPeers => 'Пиры';

  @override
  String get deskKitFactOperator => 'Оператор';

  @override
  String get deskKitAtTip => 'синхронизирован';

  @override
  String deskKitBehind(int count, String blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отстаёт на $blocks блока',
      many: 'отстаёт на $blocks блоков',
      few: 'отстаёт на $blocks блока',
      one: 'отстаёт на $blocks блок',
    );
    return '$_temp0';
  }

  @override
  String deskKitVersionOut(String version) {
    return 'вышла $version';
  }

  @override
  String get deskKitVersionLatest => 'последняя';

  @override
  String get deskKitUptimeWindow => 'за 24 ч';

  @override
  String deskKitAtTime(String time) {
    return 'в $time';
  }

  @override
  String get deskKitListedOfficial => 'в списке официальных';

  @override
  String deskKitSourceChecked(String time, String site) {
    return '$site, проверено в $time';
  }

  @override
  String deskKitLatencyMeasured(String where) {
    return 'задержка измерена $where';
  }

  @override
  String deskKitSiteLastReached(String time) {
    return 'Сайт статуса последний раз отвечал в $time';
  }

  @override
  String deskKitSince(String time) {
    return 'с $time';
  }

  @override
  String deskKitNodeSemantics(String status, String host) {
    return 'Узел $status: $host';
  }

  @override
  String get deskKitNodeDownTitle => 'Узел не отвечает.';

  @override
  String get deskKitNodeDownHead => 'Узел не отвечает';

  @override
  String deskKitNodeDownText(String host) {
    return 'Переключиться на $host, самый исправный из других узлов?';
  }

  @override
  String get deskKitSwitch => 'Переключить';

  @override
  String get deskKitLimitedInfo => 'Неполные данные';

  @override
  String deskKitFromStatusSite(String site) {
    return 'с $site';
  }

  @override
  String get deskKitOverTor => 'через Tor';

  @override
  String get deskKitFromThisComputer => 'с этого компьютера';

  @override
  String deskKitNodeUse(String host) {
    return 'Использовать $host';
  }

  @override
  String deskKitNodeUseOperator(String host, String operator) {
    return 'Использовать $host, $operator';
  }

  @override
  String deskKitNodeUseDown(String host) {
    return 'Использовать $host, не отвечает';
  }

  @override
  String deskKitNodeUseOperatorDown(String host, String operator) {
    return 'Использовать $host, $operator, не отвечает';
  }

  @override
  String deskKitLocalNodeUse(String state) {
    return 'Использовать локальный узел, $state';
  }

  @override
  String get deskKitMethodWaitingTor => 'Ждёт Tor';

  @override
  String get deskKitMethodOn => 'Вкл.';

  @override
  String deskKitMethodOverTor(String host) {
    return '$host, через Tor';
  }

  @override
  String get deskKitMethodOff => 'Выкл.';

  @override
  String get deskKitMethodEpicboxOffDetail =>
      'Платежи на этот адрес ждут на сервере Epicbox.';

  @override
  String get deskKitMethodConnecting => 'Подключение';

  @override
  String get deskKitMethodSlow => 'Медленно';

  @override
  String get deskKitMethodNotAnswering => 'Не отвечает';

  @override
  String deskKitMethodEpicboxDown(String host) {
    return '$host. Платежи ждут на сервере Epicbox.';
  }

  @override
  String get deskKitMethodHttpOffDetail =>
      'Напрямую из другого кошелька, пока этот открыт.';

  @override
  String get deskKitMethodStarting => 'Запуск…';

  @override
  String deskKitMethodHttpInternet(String port) {
    return 'из интернета, порт $port';
  }

  @override
  String get deskKitMethodHttpLocal => 'только этот компьютер (127.0.0.1)';

  @override
  String get deskKitMethodNotReceiving => 'Приём не работает';

  @override
  String deskKitMethodPortInUse(String port) {
    return 'Порт $port занят другой программой. Закройте её или измените порт ниже.';
  }

  @override
  String get deskKitMethodNotInBuild => 'Нет в этой сборке';

  @override
  String get deskKitMethodTorOffDetail =>
      'Медленнее и приватнее. В некоторых странах заблокирован или запрещён.';

  @override
  String get deskKitMethodTorPublishing => 'Публикация адреса Tor…';

  @override
  String get deskKitMethodTorConnecting => 'Подключение к Tor…';

  @override
  String get deskKitMethodTorOnDetail => 'доступен по адресу Tor';

  @override
  String get deskKitMethodTorNotPublished => 'Не опубликован';

  @override
  String deskKitMethodTorSendsWork(String reason) {
    return '$reason. Отправка работает.';
  }

  @override
  String get deskKitMethodTorNotReachableYet => 'Адрес Tor пока недоступен';

  @override
  String get deskKitMethodTorStopped => 'Остановлен';

  @override
  String get deskKitMethodTorStoppedDetail => 'Tor остановился.';

  @override
  String get deskKitMethodFiles => 'Напрямую · Передача файла';

  @override
  String get deskKitChipOverTor => 'Через Tor';

  @override
  String get deskKitChipStarting => 'Tor запускается';

  @override
  String get deskKitChipNotConnected => 'Tor не подключён';

  @override
  String get deskKitChipNotOverTor => 'Без Tor';

  @override
  String get deskKitPasswordNote =>
      'Оценка сделана на этом устройстве по длине и по распространённым словам, именам и шаблонам — для атакующего с быстрым оборудованием, который перебирает 100 000 вариантов в секунду против файла этого кошелька. Это ориентир, а не гарантия.';

  @override
  String get deskKitPasswordNoteLabel => 'Как оценивается время';

  @override
  String get deskKitNotCopied => 'Не скопировано';

  @override
  String get deskKitCopied => 'Скопировано';

  @override
  String deskKitQrOf(String title) {
    return 'QR-код: $title';
  }

  @override
  String deskKitQrOfTag(String title, String tag) {
    return 'QR-код: $title, $tag';
  }

  @override
  String deskKitQrShowOf(String title) {
    return 'Показать QR-код: $title';
  }

  @override
  String get deskKitQrShow => 'Показать QR';

  @override
  String get deskKitQrHide => 'Скрыть QR';

  @override
  String get deskKitQrHideCode => 'Скрыть QR';

  @override
  String get deskSetAcctNotForgotten => 'Не забыт';

  @override
  String get deskSetAcctForgotten => 'Пароль забыт на этом компьютере';

  @override
  String get deskSetAcctForgottenText =>
      'При следующем запуске нужно будет ввести пароль.';

  @override
  String get deskSetAcctLabelNotSaved => 'Название не сохранено';

  @override
  String get deskSetAcctEnterLabel => 'Введите название';

  @override
  String get deskSetAcctLabelSaved => 'Название сохранено';

  @override
  String get deskSetAcctLabel => 'Название';

  @override
  String get deskSetAcctLabelHint => 'Видно только в этом приложении.';

  @override
  String get deskSetAcctSaveLabel => 'Сохранить название';

  @override
  String get deskSetAcctWalletFolder => 'Папка кошелька';

  @override
  String get deskSetAcctAppFiles => 'Файлы приложения';

  @override
  String get deskSetAcctAppFilesHint => 'Настройки и журнал.';

  @override
  String get deskSetAcctNetwork => 'Сеть';

  @override
  String get deskSetAcctNetworkHint => 'Задаётся при создании кошелька.';

  @override
  String get deskSetAcctRunSetup => 'Запустить…';

  @override
  String get deskSetAcctSecurity => 'Безопасность';

  @override
  String get deskSetAcctRemembered => 'Запомнен на этом компьютере';

  @override
  String deskSetAcctRememberedHint(String who) {
    return 'Открывается при запуске без пароля в течение 30 дней с момента настройки. Для отправки пароль всё равно нужен. $who';
  }

  @override
  String get deskSetAcctForget => 'Забыть на этом компьютере';

  @override
  String get deskSetAcctPasswordHint => 'Открывает этот кошелёк.';

  @override
  String get deskSetAcctChangePassword => 'Сменить пароль…';

  @override
  String get deskSetAcctDeleteHint => 'Удаляет его ключи и базу данных.';

  @override
  String get deskSetAcctFolderNotFound => 'Папка не найдена';

  @override
  String deskSetAcctCopyPath(String title) {
    return 'Копировать путь: $title';
  }

  @override
  String deskSetBackupWhenToday(String time) {
    return 'сегодня, $time';
  }

  @override
  String deskSetBackupWhenYesterday(String time) {
    return 'вчера, $time';
  }

  @override
  String deskSetBackupWhenDate(String day, String time) {
    return '$day, $time';
  }

  @override
  String get deskSetBackupNeverExported => 'Ещё не экспортировалась.';

  @override
  String deskSetBackupLastExportNothingNew(String when) {
    return 'Последний экспорт: $when · с тех пор ничего нового.';
  }

  @override
  String deskSetBackupLastExportSince(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'с тех пор $count платежа',
      many: 'с тех пор $count платежей',
      few: 'с тех пор $count платежа',
      one: 'с тех пор $count платёж',
    );
    return 'Последний экспорт: $when · $_temp0.';
  }

  @override
  String deskSetBackupWriteFailedHere(String reason) {
    return 'Не удалось записать в папку: $reason. Выберите другую папку.';
  }

  @override
  String deskSetBackupWriteFailedIn(String folder, String reason) {
    return 'Не удалось записать в $folder: $reason. Выберите другую папку.';
  }

  @override
  String get deskSetBackupWriteFailed =>
      'Не удалось записать файл. Выберите другую папку.';

  @override
  String get deskSetBackupExportTitle => 'Экспорт данных кошелька';

  @override
  String get deskSetBackupExportHint =>
      'История платежей, контакты, счета и настройки в файле, который откроет только кошелёк с этой фразой восстановления. Сама фраза возвращает баланс, но не их.';

  @override
  String get deskSetBackupExporting => 'Экспорт…';

  @override
  String get deskSetBackupExportButton => 'Экспорт…';

  @override
  String get deskSetBackupImportTitle => 'Импорт данных кошелька';

  @override
  String get deskSetBackupImportHint =>
      'Возвращает из файла данных кошелька историю платежей, контакты, счета и настройки этого кошелька. Ничего не удаляется; тот же файл дважды ничего не меняет.';

  @override
  String get deskSetBackupImportButton => 'Импорт…';

  @override
  String get deskSetBackupCsvHint =>
      'Простая таблица для электронных таблиц. Без шифрования, импортировать нельзя.';

  @override
  String get deskSetBackupSaveDialogTitle => 'Сохранить данные кошелька';

  @override
  String get deskSetBackupNotSaved => 'Не сохранено';

  @override
  String get deskSetBackupInFile => 'В файле';

  @override
  String deskSetBackupInFileCounts(int payments, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments платежа',
      many: '$payments платежей',
      few: '$payments платежа',
      one: '$payments платёж',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта',
      many: '$contacts контактов',
      few: '$contacts контакта',
      one: '$contacts контакт',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get deskSetBackupInFileSub =>
      'Кто кому платил, комиссии, заметки и метки; счета; настройки';

  @override
  String get deskSetBackupNotIn => 'Не входит';

  @override
  String get deskSetBackupNotInValue => 'Фраза восстановления, ключи, пароль';

  @override
  String get deskSetBackupOpensWith => 'Откроет';

  @override
  String get deskSetBackupOpensWithValue =>
      'Этот кошелёк или кошелёк, восстановленный по его фразе восстановления';

  @override
  String get deskSetBackupFile => 'Файл';

  @override
  String get deskSetBackupFileNote => 'Файл содержит всё на текущий момент.';

  @override
  String get deskSetBackupExportDesc =>
      'Файл с историей платежей, контактами, счетами и настройками этого кошелька.';

  @override
  String get deskSetBackupSaved => 'Сохранено';

  @override
  String get deskSetBackupKeepCopy =>
      'Храните копию вне этого компьютера: на флешке, другом диске или в облаке.';

  @override
  String get deskSetBackupOpenFolder => 'Открыть папку';

  @override
  String get deskSetBackupSaving => 'Сохранение…';

  @override
  String get deskSetBackupTryAgain => 'Повторить';

  @override
  String get deskSetBackupSaveAs => 'Сохранить как…';

  @override
  String get deskSetBackupOpenDialogTitle => 'Открыть файл данных кошелька';

  @override
  String get deskSetBackupNothingNew => 'Ничего нового';

  @override
  String deskSetBackupNothingNewBody(String file) {
    return 'Все записи из $file уже здесь.';
  }

  @override
  String get deskSetBackupImported => 'Импортировано';

  @override
  String deskSetBackupReading(String file) {
    return 'Чтение $file…';
  }

  @override
  String get deskSetBackupNotImported => 'Не импортировано';

  @override
  String get deskSetBackupBringsBack => 'Вернёт';

  @override
  String get deskSetBackupBringsBackValue =>
      'Детали и заметки платежей, старые платежи, которых нет в списке, контакты, счета и настройки';

  @override
  String get deskSetBackupNeeds => 'Нужен';

  @override
  String get deskSetBackupNeedsValue =>
      'Файл этого кошелька (та же фраза восстановления). Сначала восстановите кошелёк по его фразе.';

  @override
  String get deskSetBackupChooseFile => 'Выбрать файл…';

  @override
  String get deskSetBackupImportDesc =>
      'Возвращает историю платежей, контакты, счета и настройки этого кошелька; существующие записи остаются.';

  @override
  String get deskSetBackupSaveCsvDialogTitle => 'Сохранить платежи в CSV';

  @override
  String get deskSetBackupCsvDialogTitle => 'Экспорт CSV';

  @override
  String get deskSetBackupCsvDialogDesc =>
      'Простая таблица платежей этого кошелька для электронных таблиц.';

  @override
  String deskSetBackupCsvSavedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа',
      many: '$count платежей',
      few: '$count платежа',
      one: '$count платёж',
    );
    return '$_temp0, сначала новые. Суммы в EPIC с 8 знаками после запятой; даты в UTC.';
  }

  @override
  String get deskSetBackupDateError => 'Введите дату в виде 2026-01-31';

  @override
  String get deskSetBackupDateHint => 'ГГГГ-ММ-ДД';

  @override
  String get deskSetBackupRange => 'Период';

  @override
  String get deskSetBackupRangeAll => 'Всё время';

  @override
  String get deskSetBackupRangeThisYear => 'Этот год';

  @override
  String get deskSetBackupRangeLastYear => 'Прошлый год';

  @override
  String get deskSetBackupRangeCustom => 'Свой';

  @override
  String get deskSetBackupFrom => 'С';

  @override
  String get deskSetBackupTo => 'По';

  @override
  String deskSetBackupCsvInfo(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа',
      many: '$count платежей',
      few: '$count платежа',
      one: '$count платёж',
    );
    return '$_temp0 · $file';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '$file';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Без шифрования.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Любой, у кого есть файл, увидит суммы, даты, адреса и заметки.';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа не входят в экспортированные данные кошелька.',
      many: '$count платежей не входят в экспортированные данные кошелька.',
      few: '$count платежа не входят в экспортированные данные кошелька.',
      one: '$count платёж не входит в экспортированные данные кошелька.',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count платежа добавлены или изменены после последнего экспорта данных кошелька.',
      many:
          '$count платежей добавлены или изменены после последнего экспорта данных кошелька.',
      few:
          '$count платежа добавлены или изменены после последнего экспорта данных кошелька.',
      one:
          '$count платёж добавлен или изменён после последнего экспорта данных кошелька.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'Восстановление по фразе вернёт баланс, но не историю того, кто кому платил.';

  @override
  String get deskSetBackupNotNow => 'Не сейчас';

  @override
  String get deskSetDlgChainTitle => 'Найдены данные блокчейна';

  @override
  String get deskSetDlgChainDesc =>
      'Локальный узел может использовать данные блокчейна Epic, которые уже есть на этом компьютере, вместо загрузки.';

  @override
  String get deskSetDlgChainFolder => 'Папка';

  @override
  String get deskSetDlgChainSize => 'Размер';

  @override
  String get deskSetDlgChainUpdated => 'Обновлено';

  @override
  String get deskSetDlgChainUpdatedValue => '3 дня назад';

  @override
  String get deskSetDlgChainOthers => 'Найдена ещё 1 копия; эта самая новая.';

  @override
  String get deskSetDlgChainInUse =>
      'Эту папку использует другая программа Epic. Закройте её и снова выберите локальный узел, чтобы использовать эти данные.';

  @override
  String get deskSetDlgChainUseIt => 'Использовать их?';

  @override
  String get deskSetDlgChainOlderWallet =>
      'Старый Epic Wallet, который использует эту папку, после этого синхронизируется заново.';

  @override
  String get deskSetDlgChainFresh => 'Загрузить заново';

  @override
  String get deskSetDlgChainUse => 'Использовать эти данные';

  @override
  String get deskSetDlgPwChanged => 'Пароль изменён.';

  @override
  String get deskSetDlgPwTitle => 'Сменить пароль';

  @override
  String get deskSetDlgPwDesc =>
      'Теперь этот кошелёк открывается новым паролем; «Запомнить на этом компьютере» выключается.';

  @override
  String get deskSetDlgPwDescPlain =>
      'Теперь кошелёк открывается новым паролем, и этот компьютер его больше не запоминает.';

  @override
  String get deskSetDlgPwCurrent => 'Текущий пароль';

  @override
  String get deskSetDlgPwWrong => 'Неверный пароль';

  @override
  String get deskSetDlgPwNew => 'Новый пароль';

  @override
  String get deskSetDlgPwRepeat => 'Повторите новый пароль';

  @override
  String deskSetDlgRemoveToastList(String name) {
    return '$name удалён из списка';
  }

  @override
  String deskSetDlgRemoveToastDeleted(String name) {
    return '$name удалён';
  }

  @override
  String get deskSetDlgRemoveFilesKept => 'Файлы сохранены.';

  @override
  String deskSetDlgRemoveTitle(String name) {
    return 'Убрать $name?';
  }

  @override
  String get deskSetDlgRemoveWhat => 'Что убрать';

  @override
  String get deskSetDlgRemoveFromList => 'Убрать из списка';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Файлы останутся в $folder; «Добавить кошелёк» вернёт его.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Удалить кошелёк';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Удаляет его ключи и базу данных из $folder. Восстановить его можно только по фразе восстановления; без неё монеты потеряны.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'Чтобы удалить и его файлы, разблокируйте этот кошелёк и выберите «Удалить кошелёк» в разделе «Настройки › Этот кошелёк».';

  @override
  String get deskSetDlgRemoveUnlock => 'Разблокировать этот кошелёк';

  @override
  String get deskSetDlgRemoveIrreversible => 'Это нельзя отменить';

  @override
  String get deskSetDlgRemoveIrreversibleBody =>
      'Восстановить кошелёк можно только по фразе восстановления; без неё монеты будут потеряны навсегда.';

  @override
  String get deskSetDlgRemoveName => 'Название кошелька';

  @override
  String deskSetDlgRemoveTypeName(String name) {
    return 'Введите $name для подтверждения.';
  }

  @override
  String get deskSetDlgRemoveNameMismatch => 'Название не совпадает';

  @override
  String get deskSetDlgPassword => 'Пароль';

  @override
  String get deskSetDlgPhraseWritten => 'Фраза восстановления записана';

  @override
  String get deskSetDlgRemoving => 'Удаление…';

  @override
  String get deskSetDlgWalletLocked => 'Кошелёк заблокирован';

  @override
  String get deskSetDlgDeleteTitle => 'Удалить этот кошелёк?';

  @override
  String get deskSetDlgDeleteDesc =>
      'Удаляет кошелёк и его seed с этого компьютера. Восстановить его можно только по фразе восстановления; без неё монеты потеряны.';

  @override
  String get deskSetFrameTitle => 'Настройки';

  @override
  String get deskSetFrameSections => 'Разделы настроек';

  @override
  String get deskSetFrameNode => 'Узел';

  @override
  String get deskSetFramePrivacy => 'Приватность';

  @override
  String get deskSetFrameAppearance => 'Внешний вид';

  @override
  String get deskSetFrameThisWallet => 'Этот кошелёк';

  @override
  String get deskSetFrameAllWallets => 'Все кошельки';

  @override
  String get deskSetFramePhrase => 'Сид-фраза';

  @override
  String get deskSetFrameRescan => 'Сверка баланса';

  @override
  String get deskSetFrameAbout => 'О приложении';

  @override
  String get deskSetFrameHelp => 'Справка';

  @override
  String get deskSetFrameHealthOn => 'Работает';

  @override
  String get deskSetFrameHealthSlow => 'Медленно';

  @override
  String get deskSetFrameNotResponding => 'Не отвечает';

  @override
  String get deskSetFrameOff => 'Выкл.';

  @override
  String get deskSetFrameChecking => 'Проверка…';

  @override
  String get deskSetFrameNodeSynced => 'Синхронизирован';

  @override
  String get deskSetFrameNodeSyncing => 'Синхронизация';

  @override
  String get deskSetFrameNever => 'никогда';

  @override
  String get deskSetFrameJustNow => 'только что';

  @override
  String deskSetFrameMinAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин назад',
      many: '$count мин назад',
      few: '$count мин назад',
      one: '$count мин назад',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч назад',
      many: '$count ч назад',
      few: '$count ч назад',
      one: '$count ч назад',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн. назад',
      many: '$count дн. назад',
      few: '$count дн. назад',
      one: '$count дн. назад',
    );
    return '$_temp0';
  }

  @override
  String get deskSetComboOpens => 'Открывает список';

  @override
  String get deskSetComboNoAnswer => 'Ответа пока нет';

  @override
  String deskSetComboUse(String host) {
    return 'Использовать $host';
  }

  @override
  String get deskSetLnodeDidNotStart => 'Узел не запустился';

  @override
  String get deskSetLnodeDidNotStop => 'Узел не остановился';

  @override
  String get deskSetLnodeDidNotRestart => 'Узел не перезапустился';

  @override
  String get deskSetLnodeMoved => 'Данные блокчейна перемещены';

  @override
  String get deskSetLnodeFolderChanged => 'Папка данных изменена';

  @override
  String get deskSetLnodeFolderFailed => 'Папка не изменена';

  @override
  String get deskSetLnodeStart => 'Запустить';

  @override
  String get deskSetLnodeStop => 'Остановить';

  @override
  String get deskSetLnodeRestart => 'Перезапустить';

  @override
  String get deskSetLnodeTabStatus => 'Состояние';

  @override
  String get deskSetLnodeTabPeers => 'Пиры';

  @override
  String get deskSetLnodeWhileSyncing => 'Во время синхронизации';

  @override
  String deskSetLnodeWhileSyncingText(String host) {
    return 'Использовать $host, пока локальный узел не синхронизирован';
  }

  @override
  String get deskSetLnodeChange => 'Изменить…';

  @override
  String deskSetLnodeUseWhileSyncing(String host) {
    return 'Использовать $host во время синхронизации';
  }

  @override
  String get deskSetLnodeDataFolder => 'Папка данных';

  @override
  String deskSetLnodeUsed(String size) {
    return 'Занято $size';
  }

  @override
  String get deskSetLnodeFreeUnknown => 'свободное место неизвестно';

  @override
  String deskSetLnodeFree(String size) {
    return 'свободно $size';
  }

  @override
  String get deskSetLnodeOpen => 'Открыть';

  @override
  String get deskSetLnodeFolderNotOpened => 'Папка не открыта';

  @override
  String get deskSetLnodeChainData => 'Данные блокчейна';

  @override
  String get deskSetLnodeChainPointed =>
      'Этот узел читает папку другой программы; удаляйте данные там.';

  @override
  String get deskSetLnodeChainText =>
      'Используйте данные блокчейна, которые оставил на этом компьютере другой узел Epic, или удалите данные этого узла и загрузите блокчейн заново.';

  @override
  String get deskSetLnodeReuse => 'Использовать найденные…';

  @override
  String get deskSetLnodeDelete => 'Удалить…';

  @override
  String get deskSetLnodeAutostart => 'Запускать вместе с приложением';

  @override
  String get deskSetLnodeAutostartHint =>
      'Запускает узел при старте и держит его синхронизированным, пока приложение открыто.';

  @override
  String get deskSetLnodeViewLog => 'Журнал узла';

  @override
  String get deskSetLnodeChangeFolder => 'Сменить папку…';

  @override
  String deskSetLnodeUseMeanwhile(String host) {
    return 'Пока использовать $host';
  }

  @override
  String get deskSetLnodeWaitingPeers => 'ждёт пиров';

  @override
  String get deskSetLnodeSyncingLower => 'синхронизация';

  @override
  String deskSetLnodeStageUsing(String stage, String host) {
    return '$stage · пока используется $host';
  }

  @override
  String get deskSetLnodeNothingUntilSynced =>
      'Пока локальный узел не синхронизирован, ничего нельзя отправить или получить.';

  @override
  String get deskSetLnodeAtTip => 'актуален';

  @override
  String get deskSetLnodeStalledDetail =>
      'нет прогресса 5 мин; один перезапуск уже был';

  @override
  String get deskSetLnodeNoProgress => 'Узел не продвигается.';

  @override
  String get deskSetLnodeNoProgressText =>
      'Запустите узел снова или проверьте журнал узла.';

  @override
  String deskSetLnodePortInUse(String port) {
    return 'Порт $port занят другой программой.';
  }

  @override
  String get deskSetLnodePortInUseText =>
      'Закройте другую программу или выберите этот узел в строке «Сервер узла».';

  @override
  String get deskSetLnodeDiskLow => 'На этом томе свободно меньше 2 ГБ.';

  @override
  String get deskSetLnodeDiskLowText =>
      'Освободите место или смените папку данных.';

  @override
  String get deskSetLnodeMissing => 'В этой установке нет программы узла.';

  @override
  String get deskSetLnodeMissingText => 'Переустановите кошелёк.';

  @override
  String get deskSetLnodeStopped => 'Узел остановился сам.';

  @override
  String get deskSetLnodeStoppedText =>
      'Причина может быть в последних строках журнала.';

  @override
  String deskSetLnodeUsesMeanwhile(String host) {
    return 'пока кошелёк использует $host';
  }

  @override
  String get deskSetLnodeNothingUntilRuns =>
      'пока он не запущен, отправить ничего нельзя';

  @override
  String get deskSetLnodeTilePeers => 'Пиры';

  @override
  String get deskSetLnodeTileSync => 'Синхронизация';

  @override
  String get deskSetLnodeTileDownload => 'Загрузка';

  @override
  String deskSetLnodeSoFar(String size) {
    return 'всего $size';
  }

  @override
  String get deskSetLnodeTileDisk => 'Блокчейн на диске';

  @override
  String deskSetLnodeThisSession(String size) {
    return '+$size за сеанс';
  }

  @override
  String deskSetLnodeVersion(String version) {
    return 'Версия $version';
  }

  @override
  String deskSetLnodeRunning(String duration) {
    return 'работает $duration';
  }

  @override
  String deskSetLnodeStoppedAt(String time) {
    return 'остановлен в $time';
  }

  @override
  String deskSetLnodePeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пира',
      many: '$count пиров',
      few: '$count пира',
      one: '$count пир',
    );
    return '$_temp0';
  }

  @override
  String deskSetLnodeMoving(String done, String total) {
    return 'Перемещение данных блокчейна · $done из $total';
  }

  @override
  String get deskSetLnodeConnectingPeers => 'Подключение к пирам';

  @override
  String deskSetLnodeStartedSecAgo(int seconds) {
    return 'запущен $seconds с назад';
  }

  @override
  String deskSetLnodeStartedAgo(String duration) {
    return 'запущен $duration назад';
  }

  @override
  String get deskSetLnodeSettingsChanged => 'Настройки изменены.';

  @override
  String get deskSetLnodeSettingsChangedText =>
      'Они вступят в силу после перезапуска.';

  @override
  String get deskSetLnodeRestartNow => 'Перезапустить';

  @override
  String get deskSetLnodeSampled =>
      'Обновляется каждые 30 с, пока открыта эта страница.';

  @override
  String get deskSetLnodeTomlEdited =>
      'epic-server.toml изменён вручную; настройки пиров и папки здесь не действуют.';

  @override
  String get deskSetLnodeSyncProgress => 'Ход синхронизации';

  @override
  String get deskSetLnodeStepHeaders => 'Заголовки';

  @override
  String get deskSetLnodeStepChainState => 'Состояние';

  @override
  String get deskSetLnodeStepBlocks => 'Блоки';

  @override
  String get deskSetLnodeStepsNone => 'Шаги синхронизации: ни один не начат';

  @override
  String deskSetLnodeStepOf(int n, String name) {
    return 'Шаг синхронизации $n из 4: $name';
  }

  @override
  String deskSetLndAskTitle(String host) {
    return 'Использовать $host, пока локальный узел не синхронизирован?';
  }

  @override
  String deskSetLndAskDesc(String host) {
    return '$host, публичный узел, может заменить локальный, пока тот не синхронизируется.';
  }

  @override
  String get deskSetLndAskNote =>
      'Спрашиваем один раз. Узел и выбор можно изменить в разделе «Настройки › Узел › Во время синхронизации».';

  @override
  String get deskSetLndAskWait => 'Ждать локальный узел';

  @override
  String deskSetLndAskUse(String host) {
    return 'Использовать $host';
  }

  @override
  String get deskSetLndPickTitle => 'Узел на время синхронизации';

  @override
  String get deskSetLndPickDesc =>
      'Публичный узел, который кошелёк использует, пока локальный узел не синхронизирован.';

  @override
  String get deskSetLndDeleted => 'Данные блокчейна удалены';

  @override
  String deskSetLndFreed(String size) {
    return 'Освобождено $size';
  }

  @override
  String get deskSetLndNotDeleted => 'Данные блокчейна не удалены';

  @override
  String get deskSetLndDeleteTitle => 'Удалить данные блокчейна';

  @override
  String deskSetLndDeleteDesc(String size, String path) {
    return 'Удаляет $size из $path; при следующем запуске блокчейн загрузится заново. Ключи и история остаются.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Удаляет данные блокчейна из $path. Узел остановится, и при следующем запуске весь блокчейн загрузится заново (часы). Ключи и история кошелька не затрагиваются.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Введите «$word» для подтверждения';
  }

  @override
  String deskSetLndTypeToConfirmLabel(String word) {
    return 'Введите $word для подтверждения';
  }

  @override
  String get deskSetLndSourceCli => 'epic (узел для командной строки)';

  @override
  String get deskSetLndSourceGui => 'Epic GUI';

  @override
  String get deskSetLndSourceBundled => 'прежний Epic Wallet';

  @override
  String get deskSetLndSourceCustom => 'другая папка';

  @override
  String get deskSetLndInUse => 'Данные блокчейна используются';

  @override
  String get deskSetLndNotInUse => 'Папка не используется';

  @override
  String get deskSetLndReuseTitle => 'Найдены данные блокчейна';

  @override
  String get deskSetLndReuseDesc =>
      'Другой узел Epic оставил здесь данные блокчейна. Локальный узел может читать эту папку вместо загрузки блокчейна.';

  @override
  String get deskSetLndLooking => 'Поиск…';

  @override
  String deskSetLndLastWritten(String date) {
    return 'последняя запись $date';
  }

  @override
  String get deskSetLndLocked => 'Используется другой программой';

  @override
  String get deskSetLndNothingCopied =>
      'Ничего не копируется: узел читает эту папку, а «Удалить данные блокчейна» для неё отключено.';

  @override
  String get deskSetLndFresh => 'Загрузить заново';

  @override
  String deskSetLndFreshLine(String size) {
    return 'В собственную папку кошелька. Около $size.';
  }

  @override
  String get deskSetLndLogTitle => 'Журнал узла';

  @override
  String get deskSetLndReading => 'Чтение…';

  @override
  String get deskSetLndLogNote =>
      'Последние 200 строк epic-server.log из папки данных. Новые внизу.';

  @override
  String get deskSetLndCopied => 'Скопировано';

  @override
  String deskSetLndLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count строки',
      many: '$count строк',
      few: '$count строки',
      one: '$count строка',
    );
    return '$_temp0';
  }

  @override
  String get deskSetLndBadFolder => 'Эта папка не подходит';

  @override
  String get deskSetLndChooseAnother => 'Выбрать другую';

  @override
  String deskSetLndMoveTitle(String size, String folder) {
    return 'Переместить $size в $folder?';
  }

  @override
  String get deskSetLndMoveDesc =>
      'Узел остановится на время перемещения, затем запустится из новой папки. «Начать там заново» вместо этого загрузит в неё блокчейн с нуля.';

  @override
  String get deskSetLndStartFresh => 'Начать там заново';

  @override
  String get deskSetLndMove => 'Переместить';

  @override
  String get deskSetLndProbNotEmpty => 'Папка не пустая.';

  @override
  String get deskSetLndProbInsideSource => 'Она внутри текущей папки.';

  @override
  String get deskSetLndProbSourceInside =>
      'Текущая папка находится внутри неё.';

  @override
  String deskSetLndProbSpace(String needed, String free) {
    return 'Недостаточно места: нужно $needed, свободно $free.';
  }

  @override
  String deskSetLndProbSpaceUnknown(String needed) {
    return 'Недостаточно места: нужно $needed, сколько свободно — неизвестно.';
  }

  @override
  String get deskSetLndProbLocked => 'Её занимает другая программа.';

  @override
  String get deskSetLndProbMissing => 'Текущих данных блокчейна нет.';

  @override
  String get deskSetLndProbNotWritable => 'В неё нельзя записывать.';

  @override
  String get deskSetLndProbIncomplete => 'Текущие данные блокчейна неполные.';

  @override
  String get deskSetLndProbForeign => 'Там данные блокчейна другой программы.';

  @override
  String get deskSetPeersBannedToast => 'Пир заблокирован';

  @override
  String get deskSetPeersUnbannedToast => 'Пир разблокирован';

  @override
  String deskSetPeersNotAddress(String port) {
    return 'Это не IP-адрес с портом, например 203.0.113.5:$port.';
  }

  @override
  String get deskSetPeersAlreadyPreferred => 'Уже в предпочтительных.';

  @override
  String deskSetPeersMaxRange(int min, int max) {
    return 'От $min до $max.';
  }

  @override
  String get deskSetPeersReading => 'Чтение пиров…';

  @override
  String deskSetPeersSummary(int connected, int inbound, int outbound) {
    return 'Подключено $connected · входящих $inbound · исходящих $outbound';
  }

  @override
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  ) {
    return 'Подключено $connected · входящих $inbound · исходящих $outbound · заблокировано $banned';
  }

  @override
  String get deskSetPeersIn => 'вх.';

  @override
  String get deskSetPeersOut => 'исх.';

  @override
  String get deskSetPeersBan => 'Заблокировать';

  @override
  String get deskSetPeersColAddress => 'Адрес';

  @override
  String get deskSetPeersColDirection => 'Направл.';

  @override
  String get deskSetPeersColVersion => 'Версия';

  @override
  String get deskSetPeersColHeight => 'Высота';

  @override
  String get deskSetPeersColFirstSeen => 'Впервые';

  @override
  String get deskSetPeersNone => 'Нет подключённых пиров.';

  @override
  String deskSetPeersMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count',
      many: 'Ещё $count',
      few: 'Ещё $count',
      one: 'Ещё $count',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersRefreshed(int seconds) {
    return 'Обновляется каждые $seconds с';
  }

  @override
  String get deskSetPeersBanned => 'Заблокированные';

  @override
  String deskSetPeersBannedAt(String time) {
    return 'заблокирован в $time';
  }

  @override
  String get deskSetPeersUnban => 'Разблокировать';

  @override
  String get deskSetPeersPreferred => 'Предпочтительные пиры';

  @override
  String get deskSetPeersPreferredLabel =>
      'Предпочтительный пир, IP-адрес и порт';

  @override
  String get deskSetPeersAdd => 'Добавить';

  @override
  String get deskSetPeersMaxIn => 'Макс. входящих';

  @override
  String get deskSetPeersMaxInLabel => 'Максимум входящих пиров';

  @override
  String get deskSetPeersMaxOut => 'Макс. исходящих';

  @override
  String get deskSetPeersMaxOutLabel => 'Максимум исходящих пиров';

  @override
  String deskSetPeersPreferredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Предпочтительных $count:',
      many: 'Предпочтительных $count:',
      few: 'Предпочтительных $count:',
      one: 'Предпочтительных $count:',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersForget(String peer) {
    return 'Забыть $peer';
  }

  @override
  String deskSetPeersNote(int min, int max, int def) {
    return 'Макс. входящих и исходящих: от $min до $max (по умолчанию $def).';
  }

  @override
  String get deskSetLndDeleteQuestion => 'Удалить данные блокчейна?';

  @override
  String get deskSetLogsMemoryOnly => 'Журнал хранится только в памяти.';

  @override
  String get deskSetLogsClearTitle => 'Очистить журналы?';

  @override
  String get deskSetLogsClearDesc =>
      'Удаляет файлы журналов. В отчёт, отправленный позже, попадёт только то, что записано с этого момента.';

  @override
  String get deskSetLogsKeep => 'Оставить журналы';

  @override
  String get deskSetLogsClear => 'Очистить журналы';

  @override
  String get deskSetLogsCleared => 'Журналы очищены';

  @override
  String deskSetLogsToday(String time) {
    return 'сегодня в $time';
  }

  @override
  String deskSetLogsTomorrow(String time) {
    return 'завтра в $time';
  }

  @override
  String get deskSetLogsTitle => 'Журналы';

  @override
  String get deskSetLogsLevel => 'Уровень журнала';

  @override
  String get deskSetLogsLevelNormal =>
      'Обычный. «Подробный» хранит больше строк на диске в течение 24 часов; в файле могут быть адреса, в отчётах их нет.';

  @override
  String deskSetLogsLevelDetailed(String until) {
    return 'Подробный до $until, затем обычный. В файле могут быть адреса; в отчётах их нет.';
  }

  @override
  String deskSetLogsLevelDetailedCore(String until) {
    return 'Подробный до $until, затем обычный. В файле могут быть адреса; в отчётах их нет. Строки ядра кошелька станут подробными со следующего запуска приложения.';
  }

  @override
  String get deskSetLogsNormal => 'Обычный';

  @override
  String get deskSetLogsDetailed => 'Подробный';

  @override
  String get deskSetLogsFiles => 'Файлы журнала';

  @override
  String deskSetLogsSize(String size, String max) {
    return 'Текущий размер $size из $max. Хранится ещё один старый файл.';
  }

  @override
  String get deskSetLogsOpenFolder => 'Открыть папку журналов';

  @override
  String deskSetNodePortNote(String port) {
    return 'Проверьте адрес и порт (обычно $port).';
  }

  @override
  String deskSetNodeListNote(String site) {
    return 'Состояние по данным $site; задержка измерена с этого компьютера.';
  }

  @override
  String get deskSetNodeRowNotSetUp => 'Не настроен';

  @override
  String get deskSetNodeRowStopped => 'Остановлен';

  @override
  String get deskSetNodeRowStarting => 'Запуск';

  @override
  String deskSetNodeRowSyncingPct(String percent) {
    return 'Синхронизация $percent';
  }

  @override
  String get deskSetNodeRowStalled => 'Застрял';

  @override
  String get deskSetNodeRowFailed => 'Ошибка';

  @override
  String get deskSetNodeLocalInUse => 'Используется локальный узел';

  @override
  String get deskSetNodeLocalInUseText =>
      'Он загружает весь блокчейн. Нужно 5 ГБ свободного места.';

  @override
  String get deskSetNodeLocalNode => 'Локальный узел';

  @override
  String get deskSetNodeGroupComputer => 'Этот компьютер';

  @override
  String get deskSetNodeServer => 'Сервер узла';

  @override
  String get deskSetNodeServerHint =>
      'Узел, через который кошелёк читает блокчейн и отправляет платежи.';

  @override
  String get deskSetNodeChecking => 'Проверка узла…';

  @override
  String get deskSetNodeBackground => 'Синхронизация в фоне';

  @override
  String get deskSetNodeBackgroundHint =>
      'Продолжает синхронизацию, когда приложение закрыто.';

  @override
  String get deskSetPhraseNotCopied => 'Не скопировано';

  @override
  String get deskSetPhraseClipboardRefused => 'Буфер обмена не принял текст.';

  @override
  String get deskSetPhraseCopied => 'Фраза скопирована';

  @override
  String get deskSetPhraseCleared => 'Буфер обмена очистится через 60 с.';

  @override
  String get deskSetPhraseEnterPassword => 'Введите пароль.';

  @override
  String get deskSetPhraseWrongPassword => 'Неверный пароль.';

  @override
  String get deskSetPhraseIntro =>
      'Запишите эти слова на бумаге по порядку. Только с их помощью можно восстановить этот кошелёк.';

  @override
  String get deskSetPhrasePanel => 'Введите пароль, чтобы показать слова';

  @override
  String get deskSetPhraseShowWords => 'Показать фразу восстановления';

  @override
  String deskSetPhraseWordsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Фраза восстановления, $count слова',
      many: 'Фраза восстановления, $count слов',
      few: 'Фраза восстановления, $count слова',
      one: 'Фраза восстановления, $count слово',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPhraseHideQr => 'Скрыть QR';

  @override
  String get deskSetPhraseShowQr => 'Показать QR';

  @override
  String get deskSetPhraseHideWords => 'Скрыть фразу восстановления';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return 'Скроется через $seconds с';
  }

  @override
  String get deskSetPhraseQrLabel => 'QR-код фразы восстановления';

  @override
  String get deskSetPhraseBackUp => 'Сохраните фразу';

  @override
  String get deskSetPhraseBackUpText =>
      'Любой, у кого есть эти слова, может забрать монеты. Убедитесь, что никто не видит экран.';

  @override
  String get deskSetPrivTorOnFailed => 'Tor не включён';

  @override
  String get deskSetPrivTorOffFailed => 'Tor не выключен';

  @override
  String get deskSetPrivTor => 'Tor';

  @override
  String get deskSetPrivSwitching => 'Переключение Tor';

  @override
  String get deskSetPrivTurnOff => 'Выключить Tor';

  @override
  String get deskSetPrivNotInBuild => 'Нет в этой сборке';

  @override
  String get deskSetPrivStarting => 'Запуск…';

  @override
  String deskSetPrivStartingDetail(int progress) {
    return '$progress %. Все соединения ждут Tor.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Адрес Tor ещё не опубликован. Отправка работает.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Отправка работает.';
  }

  @override
  String get deskSetPrivConnected => 'Подключено';

  @override
  String get deskSetPrivNotConnected => 'Нет подключения';

  @override
  String get deskSetPrivStoppedDetail =>
      'Tor остановился. Повторите попытку или выключите Tor.';

  @override
  String deskSetPrivProblemDetail(String problem) {
    return '$problem. Повторите попытку или выключите Tor.';
  }

  @override
  String get deskSetPrivStatusSite => 'Сайт статуса';

  @override
  String deskSetPrivUseStatus(String site) {
    return 'Использовать $site';
  }

  @override
  String get deskSetPrivUseStatusHint =>
      'Показывает, какие узлы и серверы Epicbox в сети, по публичному списку на status.btlabs.uk.';

  @override
  String deskSetRecvMethodOnFailed(String method) {
    return '$method: не удалось включить';
  }

  @override
  String deskSetRecvMethodOffFailed(String method) {
    return '$method: не удалось выключить';
  }

  @override
  String get deskSetRecvServerNotChanged => 'Сервер не изменён';

  @override
  String get deskSetRecvReceiving => 'Приём';

  @override
  String deskSetRecvSwitching(String method) {
    return 'Переключение приёма: $method';
  }

  @override
  String deskSetRecvMethodReceiving(String method) {
    return 'Приём: $method';
  }

  @override
  String get deskSetRecvNotSaved => 'Не сохранено';

  @override
  String get deskSetRecvAutostart => 'Запускать вместе с кошельком';

  @override
  String get deskSetRecvAutostartHint => 'Включается при разблокировке.';

  @override
  String deskSetRecvMethodAutostart(String method) {
    return '$method: запускать вместе с кошельком';
  }

  @override
  String get deskSetRecvEpicboxText =>
      'Сервер Epicbox хранит платежи, пока кошелёк не откроется.';

  @override
  String get deskSetRecvEpicboxServer => 'Сервер Epicbox';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Какой сервер хранит платежи для этого адреса. У двух кошельков могут быть разные серверы.';

  @override
  String get deskSetRecvSwitchingServer => 'Переключение сервера Epicbox…';

  @override
  String deskSetRecvListNote(String site) {
    return 'Состояние по данным $site.';
  }

  @override
  String get deskSetRecvHttpText =>
      'Напрямую из другого кошелька на веб-адрес этого компьютера, пока этот кошелёк открыт.';

  @override
  String get deskSetRecvHttpOffTitle => 'Выключен, пока включён Tor';

  @override
  String get deskSetRecvHttpOffText =>
      'Платежи напрямую из другого кошелька вместо этого приходят на адрес Ссылка · Tor.';

  @override
  String get deskSetRecvPrivacySettings => 'Настройки приватности';

  @override
  String get deskSetHttpNotChanged => 'Не изменено';

  @override
  String get deskSetHttpPortError => 'Порт должен быть от 1024 до 65535';

  @override
  String get deskSetHttpGuideHelp => 'Приём из интернета: как это работает';

  @override
  String get deskSetHttpPort => 'Порт';

  @override
  String deskSetHttpPortHint(String port) {
    return 'От 1024 до 65535. По умолчанию $port.';
  }

  @override
  String get deskSetHttpPortLabel => 'Порт HTTP';

  @override
  String get deskSetHttpGuideTitle => 'Приём из интернета';

  @override
  String get deskSetHttpGuideNowPublic => 'Сейчас: из интернета.';

  @override
  String get deskSetHttpGuideNowLocal =>
      'Сейчас: только локально. Адрес HTTP доступен только программам на этом компьютере.';

  @override
  String get deskSetHttpStep1 => 'Слушать на всех интерфейсах';

  @override
  String deskSetHttpStep1Text(String port) {
    return 'Кошелёк отвечает на 0.0.0.0, порт $port, и другие устройства могут отправлять на него платежи.';
  }

  @override
  String get deskSetHttpStep2 => 'Перенаправить порт';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'На странице роутера (часто 192.168.1.1) найдите «Перенаправление портов» (Port forwarding) и перенаправьте TCP $port на этот компьютер.';
  }

  @override
  String get deskSetHttpStep3 => 'Поделиться публичным адресом';

  @override
  String deskSetHttpStep3Text(String port) {
    return 'Отправители используют http://<public IP>:$port. Публичный IP может меняться.';
  }

  @override
  String get deskSetHttpNoRouter => 'Не хотите настраивать роутер?';

  @override
  String get deskSetHttpNoRouterText =>
      'Tor работает откуда угодно, ничего перенаправлять не нужно.';

  @override
  String get deskSetHttpTurnOnTor => 'Включить Tor';

  @override
  String get deskSetHttpExposed =>
      'Открыт только API приёма. Обычный HTTP не шифруется.';

  @override
  String get deskSetHttpBackLocal => 'Вернуть «Только локально»';

  @override
  String get deskSetReportNotSent => 'Отчёт не отправлен. Попробуйте ещё раз.';

  @override
  String get deskSetReportSaveDialog => 'Сохранить отчёт';

  @override
  String get deskSetReportSaved =>
      'Сохранено. Секретные данные удалены, без шифрования.';

  @override
  String get deskSetReportNotSaved => 'Файл не сохранён. Попробуйте ещё раз.';

  @override
  String get deskSetReportText => 'Текст отчёта';

  @override
  String deskSetReportAppLog(String size) {
    return 'Журнал приложения (последние $size)';
  }

  @override
  String get deskSetReportSent => 'Отчёт отправлен';

  @override
  String get deskSetReportArrived => 'Отчёт получен.';

  @override
  String deskSetReportArrivedRef(String id) {
    return 'Отчёт получен. Его номер: $id.';
  }

  @override
  String get deskSetReportDescribe => 'Опишите, что произошло.';

  @override
  String get deskSetReportTitle => 'Сообщить о проблеме';

  @override
  String get deskSetReportDesc =>
      'Зашифрован, чтобы прочитать его мог только разработчик. «Сохранить в файл» сохраняет незашифрованную копию.';

  @override
  String get deskSetReportWhat => 'Что произошло';

  @override
  String get deskSetReportWhatHint =>
      'Что вы делали, чего ожидали и что произошло вместо этого';

  @override
  String get deskSetReportAttach => 'Приложить журналы';

  @override
  String get deskSetReportAttachHint =>
      'Последняя часть журнала приложения, без фразы восстановления, пароля и других секретных данных.';

  @override
  String get deskSetReportSentWhat => 'Что отправляется';

  @override
  String get deskSetReportNotSentTitle => 'Не отправлено';

  @override
  String get deskSetReportOff => 'В этой сборке отправка отключена';

  @override
  String get deskSetReportSaveToFile => 'Сохранить в файл';

  @override
  String get deskSetReportSend => 'Отправить';

  @override
  String get deskSetRescanComplete => 'Сканирование завершено';

  @override
  String get deskSetRescanStoppedLine => 'Сканирование остановлено';

  @override
  String get deskSetRescanLog => 'Журнал сверки';

  @override
  String get deskSetRescanText =>
      'Заново проверяет блокчейн на наличие средств этого кошелька. Используйте, если баланс выглядит неверным.';

  @override
  String get deskSetRescanDeleteUnconfirmed => 'Удалить неподтверждённые';

  @override
  String get deskSetRescanDeleteHint =>
      'Также отменяет неподтверждённые транзакции и разблокирует их выходы. Платёж, который уже в пути, может после этого не пройти.';

  @override
  String get deskSetRescanScanning =>
      'Сканирование блокчейна. Кошельком можно пользоваться; баланс обновится по окончании.';

  @override
  String get deskSetRescanStopping => 'Остановка…';

  @override
  String deskSetRescanChecking(int percent) {
    return 'Проверка… $percent %';
  }

  @override
  String get deskSetRescanFailed => 'Сканирование не удалось';

  @override
  String get deskSetRescanNoneFound =>
      'Неподтверждённых транзакций не найдено.';

  @override
  String get deskSetRescanCancelled =>
      'Неподтверждённые транзакции отменены, их выходы разблокированы.';

  @override
  String get deskSetRescanNotRead => 'Не прочитано';

  @override
  String get deskSetRescanFinished => 'Сверка завершена';

  @override
  String get deskSetRescanUpToDate => 'Баланс актуален.';

  @override
  String get deskSetRescanResumed =>
      'Сканирование продолжилось с места остановки; числа относятся к этой части.';

  @override
  String get deskSetRescanStoppedEarly =>
      'Остановлено до конца. Баланс прочитан заново; запустите снова, чтобы продолжить.';

  @override
  String get deskSetRescanNotDeleted =>
      'Неподтверждённые транзакции не удалены: это выполняется только после полного сканирования.';

  @override
  String get deskSetRescanBefore => 'Баланс до';

  @override
  String get deskSetRescanAfter => 'Баланс после';

  @override
  String get deskSetRescanFound => 'Найдено выходов';

  @override
  String get deskSetRescanRestored => 'Восстановлено';

  @override
  String get deskSetRescanRevived => 'Снова разблокированы';

  @override
  String get deskSetRescanUnlocked => 'Разблокировано';

  @override
  String get deskSetRescanDeleted => 'Удалено';

  @override
  String deskSetWalletsAddedBack(String name) {
    return '$name снова в списке';
  }

  @override
  String get deskSetWalletsNotAddedBack => 'Не добавлен обратно';

  @override
  String get deskSetWalletsOpenNow => 'Открыт';

  @override
  String get deskSetWalletsFolderMissing => 'Нет папки';

  @override
  String deskSetWalletsShowFolder(String name) {
    return 'Показать $name в папке';
  }

  @override
  String deskSetWalletsRemove(String name) {
    return 'Убрать $name…';
  }

  @override
  String get deskSetWalletsRemovedGroup => 'Убраны из списка';

  @override
  String get deskSetWalletsAddBack => 'Вернуть в список';

  @override
  String get deskSetWalletsAdd => 'Добавить кошелёк';

  @override
  String get deskSetWalletsCreate => 'Создать кошелёк';

  @override
  String get deskSetWalletsCreateText =>
      'Новый кошелёк с новой фразой восстановления.';

  @override
  String get deskSetWalletsImport => 'Импорт кошельков';

  @override
  String get deskSetWalletsImportText => 'Из старого Epic Wallet или из папки';

  @override
  String get deskSetWalletsRestore => 'Восстановить по фразе';

  @override
  String get deskSetWalletsRestoreText => 'По фразе восстановления';

  @override
  String get deskSetupConfirmPassword => 'Повторите пароль';

  @override
  String get deskSetupPasswordShort => 'Не меньше 8 символов';

  @override
  String get deskSetupPasswordsDiffer => 'Пароли не совпадают';

  @override
  String get deskSetupBack => 'Назад';

  @override
  String get deskSetupNewWalletAdded => 'Новый кошелёк добавлен.';

  @override
  String get deskSetupCapsLock => 'Включён Caps Lock';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return 'Шаг $number из $total: $label';
  }

  @override
  String get deskSetupTryAgain => 'Повторить';

  @override
  String get deskSetupNotSaved => 'Не сохранено';

  @override
  String get deskSetupStepPrefs => 'Параметры';

  @override
  String get deskSetupStepNode => 'Узел';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupAgain =>
      'Повторная настройка. Ничего не изменится до нажатия «Сохранить настройки» на последнем шаге.';

  @override
  String get deskSetupPrefsLead => 'Язык приложения';

  @override
  String get deskSetupNodeTitle => 'Выберите узел';

  @override
  String get deskSetupNodeLead =>
      'Кошелёк читает блокчейн и отправляет платежи через узел Epic.';

  @override
  String get deskSetupLocalTitle => 'Локальный узел';

  @override
  String get deskSetupLocalLead =>
      'Что значит запускать узел здесь и какой узел использовать.';

  @override
  String get deskSetupEpicboxTitle => 'Epicbox';

  @override
  String get deskSetupSideTitle => 'Настройка';

  @override
  String get deskSetupBackToWallet => 'Назад к кошельку';

  @override
  String get deskSetupSave => 'Сохранить настройки';

  @override
  String get deskSetupLanguage => 'Язык';

  @override
  String get deskSetupNodeServer => 'Сервер узла';

  @override
  String get deskSetupCheckingNodes => 'Проверка узлов…';

  @override
  String get deskSetupPickNode => 'Выберите узел';

  @override
  String get deskSetupRemoteNode => 'Удалённый узел';

  @override
  String get deskSetupRemoteNodeText => 'Любой публичный узел. Готов сразу.';

  @override
  String get deskSetupLocalNodeText =>
      'Работает на этом компьютере: приватно, но нужны место на диске и первая синхронизация.';

  @override
  String get deskSetupEpicboxText =>
      'Сервер Epicbox хранит платежи, пока кошелёк не откроется.';

  @override
  String get deskSetupEpicboxServer => 'Сервер Epicbox';

  @override
  String deskSetupExistingNode(String host) {
    return 'Уже запущенный узел на $host';
  }

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Сохранение запустит узел; пока он не синхронизирован, его заменяет $node.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Сохранение запустит узел. Первая синхронизация занимает часы; кошелёк тем временем откроется.';

  @override
  String get deskSetAboutLicencesLead =>
      'Открытое программное обеспечение в этом кошельке, каждое под своей лицензией.';

  @override
  String get deskSetAboutLicenceApp => 'BT Wallet от BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Браузер не открылся';

  @override
  String get deskSetAboutOpen => 'Открыть';

  @override
  String deskSetAboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Узел $version';
  }

  @override
  String get deskSetAboutLicences => 'Лицензии';

  @override
  String get deskSetAboutSource => 'Исходный код';

  @override
  String get deskSetAboutView => 'Открыть';

  @override
  String deskSetAboutChecked(String ago) {
    return 'Проверено $ago.';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version — последняя версия';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return 'Доступно обновление: $version';
  }

  @override
  String get deskSetAboutCouldNotCheck => 'Не удалось проверить';

  @override
  String get deskSetAboutUpdates => 'Обновления';

  @override
  String get deskSetAboutCheckNow => 'Проверить';

  @override
  String get deskSetAboutAgoNow => 'только что';

  @override
  String deskSetAboutAgoMin(int count) {
    return '$count мин назад';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return '$count ч назад';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return '$count дн. назад';
  }

  @override
  String get deskSetAboutCopyLink => 'Копировать ссылку';

  @override
  String get deskSetAboutCopied => 'Скопировано';

  @override
  String get deskSetAboutNotCopied => 'Не скопировано';

  @override
  String get deskSetAppearTheme => 'Тема';

  @override
  String get deskSetAppearThemeHint =>
      '«Системная» следует настройке компьютера.';

  @override
  String get deskSetAppearSystem => 'Системная';

  @override
  String get deskSetAppearDark => 'Тёмная';

  @override
  String get deskSetAppearLight => 'Светлая';

  @override
  String get deskSetAppearScale => 'Масштаб интерфейса';

  @override
  String get deskSetAppearScaleHint =>
      'Текст и элементы управления крупнее или мельче. Применяется сразу.';

  @override
  String get deskSetAppearLanguage => 'Язык';

  @override
  String get deskSetAppearLanguageHint => 'Применяется сразу.';

  @override
  String get deskSetAppearHideHint => 'Показывает точки вместо баланса и сумм.';

  @override
  String deskSetHelpNoMatchText(String query) {
    return 'Нет тем по запросу «$query». Попробуйте другое слово.';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count темы',
      many: 'Найдено $count тем',
      few: 'Найдено $count темы',
      one: 'Найдена $count тема',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'Темы не найдены';

  @override
  String get deskSetHelpReportText =>
      'Опишите, что пошло не так; можно приложить очищенный журнал приложения, зашифрованный для разработчика.';

  @override
  String get deskSetHelpShowLess => 'Свернуть';

  @override
  String get deskSetHelpReadMore => 'Читать дальше';

  @override
  String get deskSetHelpEb1 =>
      'Кошелёк отправителя передаёт платёж в Epicbox и блокирует выходы.';

  @override
  String get deskSetHelpEb2 =>
      'Epicbox доставляет его, когда кошелёк получателя в сети. Тот добавляет свою часть и подписывает.';

  @override
  String get deskSetHelpEb3 =>
      'Кошелёк получателя отправляет его обратно в Epicbox.';

  @override
  String get deskSetHelpEb4 =>
      'Epicbox передаёт его обратно кошельку отправителя.';

  @override
  String get deskSetHelpSigns =>
      'Кошелёк отправителя тоже подписывает, завершает транзакцию и отправляет её в сеть.';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Сеть включает её в блок. После $count подтверждения она окончательна.',
      many:
          'Сеть включает её в блок. После $count подтверждений она окончательна.',
      few:
          'Сеть включает её в блок. После $count подтверждений она окончательна.',
      one:
          'Сеть включает её в блок. После $count подтверждения она окончательна.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 =>
      'Кошелёк отправителя сохраняет файл транзакции и блокирует выходы. Файл попадает к получателю любым способом.';

  @override
  String get deskSetHelpFile2 =>
      'Получатель открывает его. Его кошелёк добавляет свою часть, подписывает и сохраняет файл ответа.';

  @override
  String get deskSetHelpFile3 => 'Файл ответа возвращается к отправителю.';

  @override
  String get deskSetHelpFile4 =>
      'Отправитель открывает файл ответа на странице «Завершить по файлу ответа».';

  @override
  String get deskSetHelpSender => 'Отправитель';

  @override
  String get deskSetHelpFile => 'Передача файла';

  @override
  String get deskSetHelpRecipient => 'Получатель';

  @override
  String get deskSetHelpNetwork => 'Сеть';

  @override
  String get deskSetHelpTravels => 'Путь транзакции';

  @override
  String get deskSetHelpOverEpicbox => 'Через Epicbox';

  @override
  String get deskSetHelpWithFile => 'Файлом';

  @override
  String deskSetHelpStep(int number, int total) {
    return 'Шаг $number из $total';
  }

  @override
  String get deskSetHelpSearch => 'Поиск по справке';

  @override
  String get deskSetHelpSearchKeys =>
      'Нажмите /, чтобы искать. Esc очищает поиск.';

  @override
  String get deskSetHelpSearchHint => 'Например: файл, подтверждения, фраза';

  @override
  String get deskSetHelpClear => 'Очистить поиск';

  @override
  String get deskSetHelpTourAgain => 'Показать тур снова';

  @override
  String deskSetHelpTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count темы',
      many: '$count тем',
      few: '$count темы',
      one: '$count тема',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSecretProtect =>
      'Windows не смог защитить секреты кошелька (DPAPI отказал), поэтому ничего не сохранено. Работайте в Windows напрямую от своего имени, со своим паролем, а не через удалённый или служебный сеанс, и попробуйте снова.';

  @override
  String get deskKeyringMissingTitle => 'Связка ключей не найдена';

  @override
  String get deskKeyringMissingText =>
      'BT Wallet хранит свои настройки и запечатанный пароль кошелька в системной связке ключей, но ни одна не ответила. Установите или запустите связку ключей (GNOME Keyring или KWallet) либо используйте сеанс рабочего стола, где она работает, затем нажмите «Повторить».';

  @override
  String get deskKeyringLockedTitle => 'Связка ключей заблокирована';

  @override
  String get deskKeyringLockedText =>
      'BT Wallet хранит свои настройки и запечатанный пароль кошелька в системной связке ключей, а она заблокирована. Разблокируйте её (обычно паролем, которым вы разблокируете этот компьютер), затем нажмите «Повторить», или нажмите «Разблокировать сейчас», чтобы система запросила пароль.';

  @override
  String get deskKeyringUnlockNow => 'Разблокировать сейчас';

  @override
  String get txStatusNotDelivered => 'Не доставлено';

  @override
  String get txDetailsNotDeliveredBody =>
      'Этот платёж ещё не дошёл до сервера Epicbox, поэтому получатель его не получил. Монеты остаются заблокированными, пока платёж не отправят повторно или не отменят.';

  @override
  String get txDetailsSendAgainDone =>
      'Отправлено снова. Платёж завершится, когда кошелёк получателя выйдет в сеть.';

  @override
  String get deskTxThisWallet => 'Этот кошелёк';

  @override
  String get deskErrOldLinks =>
      'В папке этого кошелька есть ссылки, поэтому он не импортируется. Восстановите его по фразе восстановления.';

  @override
  String get deskErrOldIncomplete =>
      'Папку этого кошелька не удалось прочитать полностью, поэтому он не импортируется. Восстановите его по фразе восстановления.';

  @override
  String get deskErrOldSeedTooLarge =>
      'Файл wallet.seed слишком велик для сида кошелька.';

  @override
  String get deskErrSendUnbuildable =>
      'Этот перевод нельзя собрать из доступных монет.';

  @override
  String get deskErrNothingToConsolidate =>
      'Нечего объединять: доступно меньше двух выходов.';

  @override
  String deskSetReportFileNone(String name) {
    return '$name (не включён)';
  }

  @override
  String deskSetReportFileAll(String name, String size) {
    return '$name (целиком, $size)';
  }

  @override
  String deskSetReportFilePart(String name, String part, String size) {
    return '$name (последние $part из $size)';
  }

  @override
  String get deskErrTxNotFound => 'Транзакция не найдена';

  @override
  String get deskTxNowUndelivered =>
      'Не доставлено. Платёж не дошёл до сервера Epicbox, поэтому получатель его не получил. Отправьте его снова или отмените, чтобы освободить монеты.';

  @override
  String get deskTxStatusUndelivered => 'Не доставлено';

  @override
  String get deskTxSendAgain => 'Отправить снова';

  @override
  String get deskTxNotSent => 'Не отправлено';

  @override
  String get deskTxSentAgain => 'Отправлено снова';

  @override
  String get deskTxSentAgainText =>
      'Платёж завершится, когда кошелёк получателя появится в сети.';

  @override
  String get deskSendFeeChangedTitle => 'Комиссия изменилась';

  @override
  String deskSendFeeChangedText(String fee, String was) {
    return 'Выходы кошелька изменились после этой проверки, поэтому комиссия перевода теперь $fee EPIC вместо $was EPIC. Проверьте её и отправьте снова.';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max байт';
  }

  @override
  String deskSendMessageCount(int used, int max) {
    return '$used / $max';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'Сообщение длиннее $max байт. Сократите его.';
  }

  @override
  String get deskSendMessageTooLongPlain =>
      'Сообщение слишком длинное. Сократите его.';

  @override
  String get deskSetPhraseCopyTitle => 'Скопировать фразу восстановления?';

  @override
  String get deskSetPhraseCopyText =>
      'Любой, у кого есть эти слова, может забрать ваши средства. Храните копию в надёжном месте.';

  @override
  String get deskOutAdvanced => 'Управление выходами';

  @override
  String get deskOutStrategyHint =>
      'Какие выходы тратит отправка. «Наименьшие» тратит наименьшие выходы, которых хватает на сумму; «Все» тратит каждый выход и возвращает один.';

  @override
  String get txStatusNotPosted => 'Не в сети';

  @override
  String get txStatusStalled => 'Застряло';

  @override
  String get txDetailsStalledBody =>
      'Другая сторона ещё не отправила этот платёж в сеть.';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      'Этот платёж не дошёл до кошелька получателя, поэтому он его не получил. Ваши средства остаются заблокированными, пока платёж не будет отправлен снова или отменён.';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service ещё не опубликовал ваш платёж.';
  }

  @override
  String get deskTxStatusNotPosted => 'Не в сети';

  @override
  String get deskTxNowNotPosted =>
      'Не в сети. Узел не принял этот платёж. Отправьте его в сеть снова: дважды он пройти не может.';

  @override
  String get deskTxBroadcastAgain => 'Отправить в сеть снова';

  @override
  String get deskTxBroadcastDone => 'Отправлено в сеть';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return 'Не доставлено. Кошелёк получателя не принял платёж ($method), поэтому получатель его не получил. Отправьте его снова или отмените, чтобы освободить средства.';
  }

  @override
  String get deskInvPayStalled => 'Застряло';

  @override
  String deskInvPayerStalledTitle(String service) {
    return 'Ваш платёж для $service застрял';
  }

  @override
  String get deskInvPayerStalledText =>
      'Не доставлено: платёж ещё не попал в сеть, средства остаются заблокированными. «Отправить снова» отправит его ещё раз без повторного подтверждения.';

  @override
  String get deskTxLabelAdd => 'Добавить метку';

  @override
  String get deskTxLabelEdit => 'Изменить метку';

  @override
  String get deskTxLabelHint => 'Добавить метку';

  @override
  String get deskTxLabelField => 'Метка';

  @override
  String get deskTxLabelAdded => 'Метка добавлена';

  @override
  String get deskTxLabelSaved => 'Метка сохранена';

  @override
  String get deskTxLabelRemoved => 'Метка удалена';

  @override
  String get deskTxLabelNotSaved => 'Метка не сохранена';

  @override
  String get deskTxDetailsAdd => 'Добавить подробности';

  @override
  String get deskTxDetailsEdit => 'Изменить';

  @override
  String get deskTxDetailsTitleAdd => 'Добавить подробности';

  @override
  String get deskTxDetailsTitleEdit => 'Изменить подробности';

  @override
  String get deskTxDetailsTip =>
      'Только для платежей, найденных при сверке баланса.';

  @override
  String get deskTxDetailsFrom => 'От';

  @override
  String get deskTxDetailsFromTip =>
      'Кто заплатил, для ваших записей. Не проверяется.';

  @override
  String get deskTxDetailsFromHint => 'Адрес отправителя';

  @override
  String get deskTxDetailsFromBad =>
      'Укажите адрес Epicbox, http(s) или .onion.';

  @override
  String get deskTxDetailsNote => 'Личная заметка';

  @override
  String get deskTxDetailsAdded => 'Подробности добавлены';

  @override
  String get deskTxDetailsSaved => 'Подробности сохранены';

  @override
  String get deskTxDetailsRemoved => 'Подробности удалены';

  @override
  String get deskTxDetailsNotSaved => 'Подробности не сохранены';

  @override
  String get deskTxManualTag => 'Добавлено вами';

  @override
  String deskTxManualTip(String date) {
    return 'Добавлено вами $date. Не из блокчейна.';
  }

  @override
  String get deskTxManualTipNoDate => 'Добавлено вами. Не из блокчейна.';

  @override
  String deskTxManualTipFrom(String date) {
    return 'Добавлено вами $date. Не из блокчейна, не проверено.';
  }

  @override
  String get deskTxManualTipFromNoDate =>
      'Добавлено вами. Не из блокчейна, не проверено.';

  @override
  String get deskHistConflictTitle => 'Подробности различаются';

  @override
  String deskHistConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
      many:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
      few:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
      one:
          'В файле другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из файла.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'Мои';

  @override
  String get deskHistConflictBackup => 'Файл';

  @override
  String get deskHistConflictKeepAll => 'Оставить все мои';

  @override
  String get deskHistConflictImport => 'Импортировать';

  @override
  String get deskHistConflictEmpty => 'пусто';

  @override
  String deskHistImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Заменено $n подробности, остальные оставлены как у вас.',
      many: 'Заменено $n подробностей, остальные оставлены как у вас.',
      few: 'Заменены $n подробности, остальные оставлены как у вас.',
      one: 'Заменена $n подробность, остальные оставлены как у вас.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayUnknown(String relay) {
    return 'Приложение не знает сервер $relay. Проверьте адрес перед отправкой.';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay не ответил.';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay не ответил, поэтому получатель не получил этот платёж. Средства остаются заблокированными, пока платёж не отправят повторно или не отменят.';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return 'Не доставлено: $relay не ответил. Платёж ждёт в «Активности»; отмените его там, чтобы разблокировать средства.';
  }

  @override
  String deskErrRelayNoAnswer(String relay) {
    return '$relay не ответил.';
  }

  @override
  String get deskSendRelayUnknownTitle => 'Неизвестный сервер Epicbox';

  @override
  String deskSendRelayUnknownText(String relay) {
    return 'Приложение не знает сервер $relay. Проверьте адрес перед отправкой. Отправить всё равно можно.';
  }

  @override
  String deskTxNowUndeliveredRelay(String relay) {
    return 'Не доставлено. $relay не ответил, поэтому получатель не получил платёж. Отправьте его снова или отмените, чтобы освободить средства.';
  }

  @override
  String get deskInvNoticeReceiveSuperseded =>
      'Ваше другое устройство с этим кошельком приняло платёж, который получало и это устройство. Запустите «Сверка баланса», чтобы увидеть его здесь.';

  @override
  String deskHistConflictLeadOldWallet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'В истории старого кошелька другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из старого кошелька.',
      many:
          'В истории старого кошелька другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из старого кошелька.',
      few:
          'В истории старого кошелька другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из старого кошелька.',
      one:
          'В истории старого кошелька другие сведения для платежей: $n. Ваши сохраняются, если не выберете сведения из старого кошелька.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Старый кошелёк';

  @override
  String get deskHistConflictApply => 'Применить';

  @override
  String get deskUpdAvailable => 'Доступно обновление';

  @override
  String deskUpdDownload(String version) {
    return 'Скачать $version';
  }

  @override
  String get deskUpdOpensPage => 'Открывает страницу загрузки';

  @override
  String deskUpdDownloading(String percent) {
    return 'Загрузка: $percent %';
  }

  @override
  String get deskUpdRestart => 'Перезапустить и обновить';

  @override
  String deskUpdReady(String version) {
    return '$version готова';
  }

  @override
  String get deskUpdRestartHint =>
      'Приложение закроется, установит обновление и откроется снова.';

  @override
  String get deskUpdFailed => 'Не удалось скачать обновление';

  @override
  String get deskUpdTryAgain => 'Повторить';

  @override
  String get deskUpdInstallFailed => 'Не удалось установить обновление';

  @override
  String get deskUpdOpenPage => 'Открыть страницу загрузки';

  @override
  String get deskUpdErrDamaged =>
      'Файл не совпадает с подписанными данными обновления.';

  @override
  String get deskUpdErrStopped => 'Загрузка прервалась.';

  @override
  String get deskUpdErrInstall =>
      'Не удалось заменить приложение новой версией.';

  @override
  String get deskUpdUnfinished =>
      'Обновление не завершилось. Повторите попытку.';

  @override
  String get advExperimental => 'Экспериментально';

  @override
  String get advTitle => 'Дополнительно';

  @override
  String get advIntro =>
      'Каждый переключатель показывает ещё одну часть кошелька там, где ей место.';

  @override
  String get advShowsHeader => 'Показывает больше';

  @override
  String get advNetworkHeader => 'Сеть';

  @override
  String get advOutputs => 'Выходы';

  @override
  String get advOutputsHint =>
      'Показывает страницу «Выходы» в разделе «Кошелёк» и на главном экране. Она перечисляет монеты, из которых состоит баланс, позволяет разделять и объединять их и задаёт настройки по умолчанию для отправки. Пока идёт разделение или объединение, страница остаётся видимой.';

  @override
  String get advTechnical => 'Технические сведения';

  @override
  String get advTechnicalHint =>
      'Показывает технические строки в сведениях о платеже: ядро, ID слейта, коммитменты и высоту блока. В настройках «Счетов» показывает, сколько времени счёт можно оплатить.';

  @override
  String get advSendOptions => 'Параметры отправки';

  @override
  String get advSendOptionsHint =>
      'Показывает «Стратегию» отправки и «Делить сдачу» в «Настройки › Транзакции»: какие выходы тратит отправка и делится ли её сдача. Остаётся видимым, пока что-то из этого не по умолчанию.';

  @override
  String get advServerDetails => 'Сведения о серверах';

  @override
  String get advServerDetailsHint =>
      'Показывает хосты, задержку, версию и высоту блока в списках серверов и на карточке состояния, а также адрес Epicbox в «Получить».';

  @override
  String get advRecheckHeight => 'Сверка с заданной высоты';

  @override
  String get advRecheckHeightHint =>
      'Позволяет начать «Сверку баланса» с высоты блока или с даты, а не с первого блока. Быстрее, и это единственный способ пропустить раннюю историю. При восстановлении выбор есть всегда.';

  @override
  String get advModeStandard => 'Обычный';

  @override
  String get advModeTorOnly => 'Только Tor';

  @override
  String get advModeTorOnlyLine =>
      'Каждое соединение идёт через Tor. Пока Tor не готов, ничего не подключается.';

  @override
  String get advReset => 'Скрыть всё снова';

  @override
  String get advBuiltInNode => 'Локальный узел';

  @override
  String get advLogs => 'Журналы';

  @override
  String get deskSetFrameAdvanced => 'Дополнительно';

  @override
  String get deskSetAdvShows => 'Показывает больше';

  @override
  String get deskSetAdvOutputs => 'Выходы';

  @override
  String get deskSetAdvOutputsHint =>
      'Показывает страницу «Выходы» в боковой панели. Она перечисляет монеты, из которых состоит баланс, позволяет разделять и объединять их и задаёт настройки по умолчанию для отправки. Пока идёт разделение или объединение, страница остаётся видимой.';

  @override
  String get deskSetAdvTechnical => 'Технические сведения';

  @override
  String get deskSetAdvTechnicalHint =>
      'Показывает раздел «Технические сведения» у каждой транзакции: ядро, ID слейта, коммитменты и высоту блока. Без этого ссылка «Ещё» у транзакции показывает их один раз. В «Счетах» показывает дополнительные разделы.';

  @override
  String get deskSetAdvSendOptions => 'Параметры отправки';

  @override
  String get deskSetAdvSendOptionsHint =>
      'Добавляет в «Отправить» раздел, где отдельная отправка может выбрать, какие выходы тратить, «Наименьшие» или «Все», и делить ли сдачу. Значения по умолчанию остаются в «Выходах».';

  @override
  String get deskSetAdvServerDetails => 'Сведения о серверах';

  @override
  String get deskSetAdvServerDetailsHint =>
      'Показывает хосты, задержку, версию и высоту блока в списках узлов и Epicbox, в строках состояния боковой панели и на карточке состояния.';

  @override
  String get deskSetAdvRecheck => 'Сверка с заданной высоты';

  @override
  String get deskSetAdvRecheckHint =>
      'Позволяет «Сверке баланса» также сбрасывать неподтверждённые транзакции. Восстановление предлагает начальный блок всем, что бы здесь ни было выбрано.';

  @override
  String get deskSetAdvBuiltInNode => 'Локальный узел';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'Позволяет этому компьютеру запускать собственный узел: пункт «Этот компьютер» в разделе «Узел», его панель синхронизации и «Запустить узел» на обзоре. Синхронизация цепочки занимает часы и несколько гигабайт на диске. Работающий узел сохраняет свои строки.';

  @override
  String get deskSetAdvLogs => 'Журналы';

  @override
  String get deskSetAdvLogsHint =>
      'Показывает группу «Журналы» в разделе «Файлы и журналы»: открыть папку журналов, очистить журналы. «Сообщить о проблеме» прикладывает журнал в любом случае.';

  @override
  String get deskSetAdvNetwork => 'Сеть';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'Каждое соединение идёт через Tor. Пока Tor не готов, ничего не подключается.';

  @override
  String get deskSetAdvNotInBuild => 'Нет в этой сборке';

  @override
  String get deskSetAdvReset => 'Скрыть всё снова';

  @override
  String deskSetAdvOn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n переключателя включено',
      many: '$n переключателей включено',
      few: '$n переключателя включены',
      one: '$n переключатель включён',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAcctAutoLockHint =>
      'Блокирует кошелёк, если столько времени не нажимали клавиши и не двигали мышь. При «Никогда» кошелёк блокируется только кнопкой «Заблокировать кошелёк». Все кошельки.';

  @override
  String get torUndercoverKeepsOn => 'Инкогнито держит Tor включённым.';

  @override
  String get torLockedTorOnly => 'Включён в режиме «Только Tor».';

  @override
  String get torUndercoverChange => 'Изменить «Инкогнито»';

  @override
  String get torUndercoverChangeShort => 'Изменить';

  @override
  String get txDetailsMore => 'Ещё';

  @override
  String get restoreStartFromLink => 'Начать с даты или высоты';

  @override
  String restoreScanningFrom(String month) {
    return 'Начало сканирования: $month';
  }

  @override
  String get restoreScanningFromStart => 'Сканирование с начала';

  @override
  String get restoreScanFromStart => 'Сканировать с начала';

  @override
  String restoreScanningFromBlock(String height) {
    return 'Начало сканирования: блок $height';
  }

  @override
  String get scanStartChange => 'Изменить начало';

  @override
  String get scanStartInfoTitle => 'Начало сканирования';

  @override
  String get scanStartInfo =>
      'Находятся только монеты начиная с этой точки. Более раннее начало найдёт старые монеты, но займёт больше времени.';

  @override
  String get slNodeField => 'Адрес узла';

  @override
  String get slRelayField => 'Сервер Epicbox';

  @override
  String get slFieldHint =>
      'Вставьте или введите, чтобы отфильтровать или добавить';

  @override
  String slSwitchTitle(String host) {
    return 'Переключиться на $host?';
  }

  @override
  String get slSwitchBody =>
      'После переключения у вас будет новый адрес Epicbox.';

  @override
  String get slSwitch => 'Переключить';

  @override
  String get slHelpAddable => 'Нет в списке.';

  @override
  String slHelpMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count совпадения.',
      many: '$count совпадений.',
      few: '$count совпадения.',
      one: '$count совпадение.',
      zero: 'Ничего не найдено.',
    );
    return '$_temp0';
  }

  @override
  String get slClear => 'Очистить';

  @override
  String slAddRow(String host) {
    return 'Добавить $host';
  }

  @override
  String get slAddTestsNode =>
      'Сначала проверит узел, затем предложит переключиться.';

  @override
  String get slAddTestsRelay =>
      'Сначала проверит сервер, затем предложит переключиться.';

  @override
  String slAdded(String host) {
    return 'Добавлено: $host.';
  }

  @override
  String get slRemove => 'Удалить';

  @override
  String slRemoved(String host) {
    return 'Удалено: $host.';
  }

  @override
  String get slUndo => 'Отменить';

  @override
  String get slInUseSwitchFirst => 'Используется. Сначала переключитесь.';

  @override
  String get slRelayWarning =>
      'После переключения у вас будет новый адрес Epicbox.';

  @override
  String get slNotAnAddress =>
      'Это не адрес сервера. Введите host или host:port.';

  @override
  String get slRelayNoAnswer => 'Сервер не отвечает. Ничего не добавлено.';

  @override
  String deskSlRemoveHost(String host) {
    return 'Удалить $host';
  }

  @override
  String get deskSlInUse => 'Используется';

  @override
  String get deskSlHealthUnknown => 'Состояние неизвестно';

  @override
  String get deskSlNodeNoAnswer => 'Узел не отвечает. Ничего не добавлено.';

  @override
  String get deskSlTorWait => 'Tor ещё не подключён. Ничего не добавлено.';

  @override
  String deskSlLatency(String ms) {
    return '$ms мс';
  }

  @override
  String get deskSlDefault => 'По умолчанию';

  @override
  String deskSlTesting(String host) {
    return 'Проверка $host…';
  }

  @override
  String get deskSlSetupEpicboxOn => 'Получать через Epicbox';

  @override
  String get deskSlHelpChoose =>
      'Выберите сервер или введите текст, чтобы отфильтровать список или добавить сервер.';

  @override
  String get deskNetWaitingTorReason =>
      'Ждёт Tor. Режим «Только Tor» включён в «Дополнительно».';

  @override
  String get deskNetOpenAdvanced => 'Открыть «Дополнительно»';

  @override
  String get deskNetSendFileHint => 'Передача файла по-прежнему работает.';

  @override
  String get deskNetRecvWaitTorText =>
      'Приём начнётся, когда Tor подключится. Передача файла по-прежнему работает.';

  @override
  String get deskTourAdvancedTitle => 'Дополнительно';

  @override
  String get deskTourAdvancedText =>
      'Режим «Только Tor», выходы и технические сведения собраны здесь. Включайте то, что нужно.';

  @override
  String get deskTxMore => 'Ещё';

  @override
  String get deskTxLess => 'Меньше';

  @override
  String get settingsSectionTransactions => 'Транзакции';

  @override
  String get txMethodsHeader => 'Способы оплаты';

  @override
  String txLinkHttpHint(String port) {
    return 'Ссылка · HTTP платит прямо в кошелёк по веб-адресу (http://host:$port) и даёт этому телефону адрес, на который могут платить кошельки из той же сети Wi-Fi. Оба кошелька должны быть открыты. По дороге он не шифруется, недоступен из интернета и по мобильным данным и выключен, пока включён Tor. Добавляет Ссылка · HTTP в «Отправить» и «Получить».';
  }

  @override
  String get txLinkTorHint =>
      'Ссылка · Tor платит прямо в кошелёк по адресу onion и даёт этому телефону адрес Tor, на который ему можно платить. Оба кошелька должны быть открыты. Нужен Tor: переключатель Tor в «Приватность и сеть» направляет соединения кошелька через Tor; этот переключатель только включает адрес. Добавляет Ссылка · Tor в «Отправить» и «Получить».';

  @override
  String get txLinkTorHintNet =>
      'Ссылка · Tor платит прямо в кошелёк по адресу onion и даёт этому телефону адрес Tor, на который ему можно платить. Оба кошелька должны быть открыты. Нужен Tor: переключатель Tor в «Сеть и приватность» направляет соединения кошелька через Tor; этот переключатель только включает адрес. Добавляет Ссылка · Tor в «Отправить» и «Получить».';

  @override
  String get txLinkTorNeedsTor =>
      'Нужен Tor. Включите его в «Приватность и сеть».';

  @override
  String get txLinkTorNeedsTorNet =>
      'Нужен Tor. Включите его в «Сеть и приватность».';

  @override
  String get txLastMethodNotice =>
      'Хотя бы один способ оплаты должен остаться включённым.';

  @override
  String get txEpicboxHint =>
      'Epicbox платит через сервер, поэтому другому кошельку не нужно быть открытым. Выключен: кошелёк не подключается ни к одному серверу, то есть без платежей Epicbox и счетов. Остальные способы по-прежнему работают.';

  @override
  String get txFileHint =>
      '«Передача файла» создаёт файл транзакции, который вы передаёте другому человеку любым способом (сообщением в чате, флешкой, кабелем), а он передаёт вам ответный. Связь между кошельками не нужна. Добавляет «Передачу файла» в «Отправить» и «Получить».';

  @override
  String get txStartHeader => 'Способ по умолчанию';

  @override
  String get txDefaultsHeader => 'Настройки отправки';

  @override
  String get outputsDefaultsMoved =>
      'Настройки отправки теперь в «Настройки › Транзакции»';

  @override
  String get advNodeFailover => 'Автопереключение узла';

  @override
  String get advNodeFailoverHint =>
      'Когда ваш узел перестаёт отвечать, кошелёк на время этого сеанса берёт следующий работающий узел из вашего списка.';

  @override
  String get advBalanceHeader => 'Баланс';

  @override
  String get advConfirmations => 'Подтверждения';

  @override
  String advConfirmationsHint(int byDefault, int min, int max) {
    return 'Сколько блоков полученный платёж ждёт, прежде чем его выходы можно тратить. По умолчанию $byDefault; от $min до $max.';
  }

  @override
  String get advConfirmationsDefault => 'По умолчанию';

  @override
  String advConfirmationsReset(int count) {
    return 'Сбросить до $count';
  }

  @override
  String get advConfirmationsFewer => 'Меньше подтверждений';

  @override
  String get advConfirmationsMore => 'Больше подтверждений';

  @override
  String advConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подтверждения',
      many: '$count подтверждений',
      few: '$count подтверждения',
      one: '$count подтверждение',
    );
    return '$_temp0';
  }

  @override
  String get advConfirmationsLowNote =>
      'Меньше подтверждений — быстрее, но менее надёжно.';

  @override
  String nodeFailoverSwitched(String host) {
    return 'Узел не отвечает. Переключено на $host.';
  }

  @override
  String nodeFailoverInsteadOf(String host) {
    return 'Вместо $host';
  }

  @override
  String get deskSetAdvNodeFailover => 'Автопереключение узла';

  @override
  String get deskSetAdvNodeFailoverHint =>
      'Когда ваш узел перестаёт отвечать, кошелёк на время этого сеанса берёт следующий работающий узел из вашего списка.';

  @override
  String deskNodeFailoverSwitched(String host) {
    return 'Узел не отвечает. Переключено на $host.';
  }

  @override
  String deskNodeFailoverInsteadOf(String host) {
    return 'Вместо $host';
  }

  @override
  String get netOfflineNoPeers =>
      'У вашего узла нет пиров: платёж ждёт в его пуле, пока он не подключится снова.';

  @override
  String get netOfflineNodeHint =>
      'Использует узел для чтения цепочки и отправки. Для наибольшей приватности используйте локальный узел.';

  @override
  String get netOfflineNodeLine => 'Использует узел';

  @override
  String get netBlockEpicboxOff =>
      'Epicbox выключен в разделе Настройки › Транзакции.';

  @override
  String netBlockMethodOff(String method) {
    return 'Способ «$method» выключен в Настройки › Транзакции.';
  }

  @override
  String get txEpicboxOffTitle => 'Выключить Epicbox?';

  @override
  String txEpicboxOffPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count платежа ждут ответов через Epicbox. Они придут, когда Epicbox снова включён.',
      many:
          '$count платежей ждут ответов через Epicbox. Они придут, когда Epicbox снова включён.',
      few:
          '$count платежа ждут ответов через Epicbox. Они придут, когда Epicbox снова включён.',
      one:
          '$count платёж ждёт ответа через Epicbox. Он придёт, когда Epicbox снова включён.',
    );
    return '$_temp0';
  }

  @override
  String get txEpicboxOffAction => 'Выключить';

  @override
  String sendContactOnlyEpicbox(String name) {
    return 'У $name есть только адрес Epicbox.';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return 'У $name есть только адрес для способа «$method».';
  }

  @override
  String get receiveEpicboxOffText =>
      'Платежи ждут на сервере Epicbox, пока Epicbox снова не будет включён.';

  @override
  String get receiveNoMethods => 'Ни один способ приёма не включён';

  @override
  String get receiveNoMethodsBody =>
      'Включите один в разделе Настройки › Транзакции.';

  @override
  String get receiveNoMethodsButton => 'Открыть настройки';

  @override
  String get deskNetOfflineNoPeers =>
      'У вашего узла нет пиров: платёж ждёт в его пуле, пока он не подключится снова.';

  @override
  String get deskOutDefaultsMoved =>
      '«Стратегия» и «Делить сдачу» для отправок задаются в «Настройки › Платежи».';

  @override
  String get deskOutDefaultsOpen => 'Открыть «Платежи»';

  @override
  String get deskSetFrameTransactions => 'Транзакции';

  @override
  String get deskSetTxMethods => 'Способы';

  @override
  String get deskSetTxEpicboxHint =>
      'Платите и получайте платежи через сервер Epicbox. Так идёт большинство платежей. Выключен: кошелёк не подключается ни к одному серверу Epicbox, то есть без платежей Epicbox и счетов. Остальные способы по-прежнему работают. Все кошельки.';

  @override
  String deskSetTxDirectHint(String port) {
    return 'Платите и получайте платежи напрямую от кошелька к кошельку по веб-адресу (http://host:$port), без сервера посередине. Работает, только пока оба кошелька открыты; выключен, пока включён Tor. Добавляет Ссылка · HTTP в «Отправить», а его адрес — в «Получить». Все кошельки.';
  }

  @override
  String get deskSetTxFileHint =>
      'Платите и получайте платежи, передавая файл транзакции, сеть не нужна. Добавляет «Передачу файла» в «Отправить», а шаги с файлами — в «Получить». Все кошельки.';

  @override
  String get deskSetTxStart => 'Способ по умолчанию';

  @override
  String get deskSetTxStartHint =>
      'Способ, с которого открывается страница «Отправить». Для одного платежа его всё равно можно изменить на странице «Отправить». Все кошельки.';

  @override
  String get deskSendMethodHeader => 'Способ оплаты';

  @override
  String get sendRequestTitle => 'Счёт на оплату';

  @override
  String get sendRequestCheck => 'Проверьте сумму, затем продолжите.';

  @override
  String get sendRequestDismiss => 'Скрыть';

  @override
  String get sendAmountFromCode => 'Запрошено кодом';

  @override
  String sendAmountCodeAsked(String amount) {
    return 'В коде указана сумма $amount.';
  }

  @override
  String get sendCodeAmountInvalid =>
      'Сумма в этом коде недействительна и была пропущена.';

  @override
  String get sendCodeAmountTooLarge =>
      'Сумма в этом коде слишком велика и была пропущена.';

  @override
  String get sendCodeTooLong =>
      'Часть этого кода слишком длинная и была пропущена.';

  @override
  String get payeeNameLabel => 'Имя от получателя';

  @override
  String get payeeNoteLabel => 'Сообщение от получателя';

  @override
  String get sendNoteFromCodeHelper => 'Из кода. Получатель тоже его увидит.';

  @override
  String get sendOriginQr => 'Из QR-кода';

  @override
  String get sendOriginLink => 'Из ссылки';

  @override
  String get sendOriginPasted => 'Вставлено';

  @override
  String get sendDirectHost => 'Хост';

  @override
  String get scanNotEpicTitle => 'Это не код Epic';

  @override
  String get scanNotEpicBody => 'Это не адрес Epic и не код оплаты.';

  @override
  String get scanBadAddress => 'Адрес в этом коде недействителен.';

  @override
  String get scanWrongNetworkTitle => 'Другая сеть';

  @override
  String get scanWrongNetworkBody =>
      'Этот адрес принадлежит другой сети Epic. Этот кошелёк не может его оплатить.';

  @override
  String get scanSlateTextBody => 'Это текст файла транзакции, а не адрес.';

  @override
  String get commonOpen => 'Открыть';

  @override
  String get scanPairingTitle => 'Ссылка для сопряжения';

  @override
  String get scanPairingUnavailable => 'Сопряжение недоступно в этой версии.';

  @override
  String get scanCodeTextLabel => 'Отсканированный текст';

  @override
  String get scanCopied => 'Скопировано';

  @override
  String get linkWaitingPairingNotice => 'Получена ссылка для сопряжения';

  @override
  String get linkWaitingNotice => 'Получена ссылка на оплату';

  @override
  String get linkFinishCurrentFirst => 'Сначала завершите текущий платёж.';

  @override
  String get deskSendToQrPayment =>
      'Код «Оплата по QR». Отсканируйте его в BT Wallet на телефоне.';

  @override
  String get deskSetRecvTorText =>
      'Напрямую из другого кошелька на адрес Tor этого кошелька, пока он открыт.';

  @override
  String get deskSetTxTorHint =>
      'Платите и получайте платежи напрямую от кошелька к кошельку по адресу onion, через Tor, без сервера посередине. Работает, только пока оба кошелька открыты. Нужен Tor: переключатель Tor в разделе «Приватность» направляет соединения кошелька через Tor; этот переключатель только включает адрес. Добавляет Ссылка · Tor в «Отправить», а его адрес — в «Получить».';

  @override
  String get deskSetTxTorNeedsTor =>
      'Tor выключен. Включите его в разделе «Приватность», чтобы получать платежи на адрес Tor.';

  @override
  String get deskSetTxLastMethod =>
      'Хотя бы один способ оплаты должен остаться включённым.';

  @override
  String get deskRecvTorOffTitle => 'Link · Tor требует Tor.';

  @override
  String get deskRecvTorOffText =>
      'Адрес Tor работает, пока включён Tor. Tor — переключатель в Настройки › Приватность; он направляет соединения кошелька через Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Настройки не сохранены';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Сохраните ещё раз или пропустите, чтобы оставить уже сохранённые настройки.';
  }

  @override
  String get deskSetupResumeLead =>
      'Настройка в прошлый раз не была завершена. Кошелёк читает блокчейн и отправляет платежи через узел Epic.';

  @override
  String deskErrProofContactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count контакта объединены с существующими',
      many: '$count контактов объединены с существующими',
      few: '$count контакта объединены с существующими',
      one: '$count контакт объединён с существующим',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsKnown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count контакта уже были сохранены',
      many: '$count контактов уже были сохранены',
      few: '$count контакта уже были сохранены',
      one: '$count контакт уже был сохранён',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропущено $count контакта: нет действительного адреса',
      many: 'Пропущено $count контактов: нет действительного адреса',
      few: 'Пропущено $count контакта: нет действительного адреса',
      one: 'Пропущен $count контакт: нет действительного адреса',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactAddressesLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count адреса не добавлены: конфликт с сохранёнными контактами',
      many: '$count адресов не добавлены: конфликт с сохранёнными контактами',
      few: '$count адреса не добавлены: конфликт с сохранёнными контактами',
      one: '$count адрес не добавлен: конфликт с сохранённым контактом',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofContactsUnreadable =>
      'Часть старых контактов не удалось прочитать: старая адресная книга повреждена';

  @override
  String get deskErrProofContactsFailed =>
      'Не все контакты сохранены: не удалось записать адресную книгу';

  @override
  String get deskTxStatusSenderPosted => 'Отправитель сообщил об отправке';

  @override
  String get deskTxNowSenderPosted =>
      'По словам отправителя, этот платёж отправлен в сеть. Он будет выполнен, когда сеть его подтвердит.';

  @override
  String get deskImpWrongTypePasted =>
      'Вставленный текст не является транзакцией. Вставьте весь текст от отправителя или выберите его файл.';

  @override
  String get pairTitle => 'Сопрячь';

  @override
  String pairWithName(String name) {
    return 'Сопрячь: $name';
  }

  @override
  String get pairInPerson => 'Лично';

  @override
  String get pairInPersonHint =>
      'Покажите свой код и отсканируйте код собеседника';

  @override
  String get pairOfflineHint =>
      'Вы офлайн. Приглашение и ответ передаются вручную.';

  @override
  String get pairEnterHint =>
      'Вставьте ссылку-приглашение или введите полученные слова';

  @override
  String get pairNotPaired => 'Не сопряжён';

  @override
  String get pairNotPairedHint =>
      'Сопряжение запечатывает файлы транзакций и позволяет разрешить счета.';

  @override
  String get pairInPersonTitle => 'Сопряжение лично';

  @override
  String get pairShowMyCode => 'Показать моё приглашение';

  @override
  String get pairScanTheirs => 'Сканировать код';

  @override
  String get pairShowCodeCaption =>
      'Дайте отсканировать этот код, затем отсканируйте код собеседника.';

  @override
  String get pairScanCaption =>
      'Сканируют оба. Проверка слов откроется, когда оба кода считаны.';

  @override
  String get pairScanPrompt => 'Отсканируйте их QR';

  @override
  String get pairSeenAs => 'Собеседник увидит вас как';

  @override
  String get pairUseWords => 'Использовать слова';

  @override
  String get pairCameraDeniedTitle => 'Доступ к камере не разрешён';

  @override
  String get pairCameraDeniedBody =>
      'Разрешите камеру для сканирования или вставьте приглашение.';

  @override
  String get pairOpenSettings => 'Открыть настройки';

  @override
  String get pairWordsTitle => 'Слова сопряжения';

  @override
  String get pairWordsLead =>
      'Зачитайте их собеседнику в этом порядке. Его кошелёк найдёт приглашение по словам.';

  @override
  String get pairWordsGoodFor => 'Действуют 10 минут';

  @override
  String get pairWordsLastMinute => 'Осталось меньше минуты';

  @override
  String get pairWordsFooter =>
      'Любой, у кого есть эти слова, может ответить на приглашение, пока оно действует. Затем проверьте слова вместе.';

  @override
  String get pairWordsNew => 'Новые слова';

  @override
  String get pairWordsCopy => 'Копировать слова';

  @override
  String get pairWordsExpiredTitle => 'Срок этих слов истёк';

  @override
  String get pairWordsExpiredBody => 'Создайте новые и зачитайте их снова.';

  @override
  String get pairWordsNeedEpicbox =>
      'Для устных приглашений нужен Epicbox, поэтому сейчас они недоступны.';

  @override
  String pairWordsDesktopChip(String time) {
    return 'Слова: осталось $time';
  }

  @override
  String get pairEnterLead =>
      'Вставьте ссылку-приглашение или введите пять полученных слов.';

  @override
  String get pairEnterField => 'Ссылка-приглашение или слова';

  @override
  String get pairEnterNotFound =>
      'По этим словам приглашение не найдено. Проверьте их или попросите новые.';

  @override
  String get pairEnterTryAgain => 'Повторить';

  @override
  String get pairCardCopy => 'Скопировать мою ссылку для сопряжения';

  @override
  String get pairCardHint =>
      'Лично без камеры: каждый кошелёк вставляет выше ссылку для сопряжения другого.';

  @override
  String pairCardBackTitle(String name) {
    return 'Теперь передайте $name свой код';
  }

  @override
  String pairCardBackBody(String name) {
    return 'Вставьте эту ссылку в кошельке $name в поле «Ввести ссылку или слова». Затем проверьте вместе.';
  }

  @override
  String get pairEnterDesktopPlaceholder =>
      'Вставьте ссылку-приглашение или введите пять слов';

  @override
  String get pairExpiresIn => 'Приглашение истекает через';

  @override
  String get pairExpiry1h => '1 час';

  @override
  String get pairExpiry24h => '24 часа';

  @override
  String get pairExpiry7d => '7 дней';

  @override
  String get pairWhatTheyReceive => 'Что получит собеседник';

  @override
  String get contactsPairHint =>
      'Выполните сопряжение с другим кошельком, чтобы запечатать файлы транзакций и счета между ними.';

  @override
  String get contactsPairLearn => 'Как это работает';

  @override
  String get contactsPairTooltip => 'Сопрячь с другим кошельком';

  @override
  String get pairBadgePending => 'Сопряжение…';

  @override
  String get pairBadgePendingTip =>
      'Приглашение отправлено или принято, сопряжение не завершено.';

  @override
  String get pairWaysLead =>
      'Сопряжение выполняется один раз. После него файлы транзакций и счета между двумя кошельками запечатаны.';

  @override
  String get pairWayWords => 'Слова';

  @override
  String get pairWayAutomatic => 'Устно';

  @override
  String get pairWayWordsHint =>
      'Зачитайте собеседнику пять слов для связывания. Оба кошелька должны быть онлайн.';

  @override
  String get pairWayWordsInfo =>
      'Оба кошелька должны быть онлайн. Ваш кошелёк оставляет приглашение на серверах подключения; кошелёк собеседника находит его по пяти словам. Затем проверьте вместе.';

  @override
  String get pairWayMessage => 'Через сообщение';

  @override
  String get pairWayMessageHint => 'Отправьте ссылку в любом чате.';

  @override
  String get pairWayMessageInfo =>
      'Три сообщения: ваше приглашение, ответ, ваша завершающая ссылка. Копируйте каждое, когда оно придёт; кошелёк найдёт его в буфере обмена, когда вы вернётесь. Работает, когда сервер заблокирован или кошелёк офлайн.';

  @override
  String get pairWayInPersonDesk => 'Телефон собеседника сканирует ваш код';

  @override
  String get pairGotInvite => 'Слова или ссылка?';

  @override
  String get pairGotInviteHint =>
      'Введите слова или вставьте полученное сообщение.';

  @override
  String get pairHowItWorks => 'Как работает сопряжение';

  @override
  String get pairWordsBothOnline =>
      'Оба кошелька должны быть онлайн. Остальное произойдёт само.';

  @override
  String get pairWordsWaiting => 'Ожидание кошелька собеседника…';

  @override
  String get pairUseMessageInstead => 'Пригласить сообщением';

  @override
  String get pairAskForMessage =>
      'Попросите собеседника прислать приглашение сообщением.';

  @override
  String get pairStepInvite => 'Приглашение';

  @override
  String get pairStepReply => 'Ответ';

  @override
  String get pairStepFinish => 'Завершающая ссылка';

  @override
  String get pairStepWords => 'Слова';

  @override
  String pairStepOf(int n, String step) {
    return 'Шаг $n из 4: $step';
  }

  @override
  String get pairMessageLead =>
      'Отправьте приглашение в любом чате. Ответ придёт тем же путём.';

  @override
  String pairInviteMessage(String link) {
    return 'Приглашение к сопряжению в BT Wallet: $link';
  }

  @override
  String pairReplyMessage(String link) {
    return 'Мой ответ на сопряжение в BT Wallet: $link';
  }

  @override
  String pairFinishMessage(String link) {
    return 'Завершение нашего сопряжения в BT Wallet: $link';
  }

  @override
  String pairFinishLinkMessage(String link) {
    return 'Завершите сопряжение в BT Wallet: $link';
  }

  @override
  String get pairCopyMessage => 'Копировать сообщение';

  @override
  String get pairMessageCopied => 'Скопировано. Вставьте в чат.';

  @override
  String get pairAwaitReplyTitle => 'Ожидание ответа';

  @override
  String get pairAwaitReplyBody =>
      'Когда ответ придёт в чат, скопируйте его и вернитесь. Кошелёк найдёт его.';

  @override
  String get pairByItself =>
      'Если обе стороны видят сервер Epicbox, этот шаг происходит и сам.';

  @override
  String get pairPasteReply => 'Вставить ответ';

  @override
  String get pairReplyTitle => 'Отправьте ответ';

  @override
  String pairReplyLead(String name) {
    return 'Отправьте это $name в том же чате.';
  }

  @override
  String get pairShareReply => 'Поделиться ответом';

  @override
  String get pairAwaitFinishTitle => 'Ожидание завершающей ссылки';

  @override
  String pairAwaitFinishBody(String name) {
    return 'Кошелёк $name создаёт её из вашего ответа. Скопируйте её, когда она придёт, и вернитесь.';
  }

  @override
  String get pairPasteFinish => 'Вставить завершающую ссылку';

  @override
  String get pairPasteLink => 'Вставить ссылку';

  @override
  String get pairFinishTitle => 'Отправьте завершающую ссылку';

  @override
  String pairFinishLead(String name) {
    return 'Ещё одно сообщение: кошельку $name оно нужно, чтобы показать слова.';
  }

  @override
  String get pairShareFinish => 'Поделиться ссылкой';

  @override
  String get pairFinishThenCheck => 'Затем вместе проверьте слова.';

  @override
  String pairAlreadyPaired(String name) {
    return 'Уже сопряжено: $name.';
  }

  @override
  String get pairReplyNotHere =>
      'Этот ответ относится к приглашению другого кошелька.';

  @override
  String get helpPairWaysTitle => 'Три способа сопряжения';

  @override
  String get helpPairWaysShort =>
      'Устно, когда оба кошелька онлайн, сообщение в любом чате или лично.';

  @override
  String get helpPairWaysP1 =>
      '**Устно.** Один кошелёк показывает пять слов и оставляет запечатанное приглашение на серверах подключения. Второй кошелёк вводит слова и находит его. Оба кошелька должны быть онлайн и иметь доступ к одному из этих серверов.';

  @override
  String get helpPairWaysP2 =>
      '**Приглашение в сообщении.** Три сообщения в любом чате: приглашение, ответ, завершающая ссылка. Сервер не нужен, поэтому способ работает, когда сеть блокирует Epicbox. Копируйте каждое сообщение, когда оно придёт; кошелёк предложит его, когда вы вернётесь.';

  @override
  String get helpPairWaysP3 =>
      '**Лично.** Каждый телефон сканирует код другого. Сеть не используется.';

  @override
  String get helpPairWaysP4 =>
      'Каким бы способом вы ни воспользовались, в конце проверьте вместе: сравните четыре картинки и имена. Они показывают, что никто не изменил сообщения по пути.';

  @override
  String get helpPairClipP =>
      'Кошелёк читает буфер обмена, только пока сопряжение включено, только когда выходит на передний план или открывается экран сопряжения, и предлагает каждую ссылку один раз. Он никогда не сохраняет и не записывает в журнал прочитанное.';

  @override
  String get pairShareWarning =>
      'Любой, у кого есть это приглашение, может выполнить сопряжение от вашего имени, пока оно действует. Отправляйте его только нужному человеку, затем проверьте вместе.';

  @override
  String get pairShareInvite => 'Поделиться приглашением';

  @override
  String get pairCopyInvite => 'Копировать приглашение';

  @override
  String get pairCancelInvite => 'Отменить приглашение';

  @override
  String pairCancelInviteTitle(String name) {
    return 'Отменить приглашение для $name?';
  }

  @override
  String pairCancelInviteBody(String name) {
    return 'Если другой кошелёк откроет его позже, он увидит «$name: приглашение отменено».';
  }

  @override
  String pairIncomingTitle(String name) {
    return 'Запрос на сопряжение от: $name';
  }

  @override
  String get pairVerifiedService => 'Проверенный сервис BT Labs';

  @override
  String pairCallsThemselves(String name) {
    return 'Называет себя «$name»';
  }

  @override
  String pairIncomingBody(String name) {
    return 'После сопряжения файлы транзакций и счета между вами и $name запечатаны. Затем вы вместе проверите.';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return 'Разрешить $name запрашивать оплату';
  }

  @override
  String get pairIncomingAllowHintDesktop =>
      'Включится после проверки. Без пароля кошелька ничего не оплачивается.';

  @override
  String get pairIncomingAllowHint =>
      'Включится после проверки. Без вашего PIN ничего не оплачивается.';

  @override
  String get pairNotNow => 'Не сейчас';

  @override
  String get pairWaitingBody =>
      'Другой кошелёк ответит, когда его откроют. Этот экран можно закрыть; проверка появится, когда сопряжение завершится.';

  @override
  String get pairSendByHand => 'Отправить вручную';

  @override
  String get pairReplyLateTitle => 'Ещё не связаны?';

  @override
  String pairReplyLateBody(String name) {
    return 'Ваш ответ ушёл к $name через сервер Epicbox. Если их кошелёк закрыт или не видит сервер, отправьте ответ в чате.';
  }

  @override
  String get pairRelayUnreachableTitle => 'Сервер недоступен';

  @override
  String get pairRelayUnreachableBody => 'Отправить ответ вручную?';

  @override
  String get pairRelayUnreachableTor =>
      'Сервер недоступен через Tor. Отправить ответ вручную?';

  @override
  String get pairNoRelay =>
      'Ни один сервер подключения недоступен. Сопрягите кошельки по ссылке-приглашению.';

  @override
  String get pairRelaysBlocked =>
      'Эта сеть блокирует серверы подключения. Причиной может быть сетевой фильтр. Сопрягите кошельки по ссылке-приглашению.';

  @override
  String get pairByHandTitle => 'Отправить вручную';

  @override
  String pairByHandLead(String name) {
    return 'Отправьте это обратно $name по любому каналу. Его кошелёк завершит сопряжение, когда откроет это.';
  }

  @override
  String get pairByHandYourAnswer => 'Ваш ответ';

  @override
  String pairByHandFooter(String name) {
    return 'Ответ запечатан для приглашения $name. Никто другой не сможет его прочитать, и он срабатывает один раз.';
  }

  @override
  String pairConfirmByHandLead(String name) {
    return 'Отправьте это обратно $name. Его кошелёк покажет проверку слов, когда откроет это.';
  }

  @override
  String get pairExpiredTitle => 'Это приглашение истекло';

  @override
  String pairExpiredBody(String name) {
    return 'Попросите новое.';
  }

  @override
  String get pairUsedTitle => 'Это приглашение уже использовано';

  @override
  String get pairUsedBody => 'Попросите новое.';

  @override
  String pairCancelledTitle(String name) {
    return '$name отменил(а) это сопряжение';
  }

  @override
  String get pairCancelledBody => 'Ничего не сохранено.';

  @override
  String pairNoAnswerTitle(String name) {
    return 'Нет ответа от $name';
  }

  @override
  String get pairNoAnswerBody =>
      'Возможно, приглашение отменено. Попросите новое или выполните сопряжение лично.';

  @override
  String pairWaitingFinish(String name) {
    return 'Ожидание, пока $name завершит сопряжение…';
  }

  @override
  String get pairNotCompletedTitle => 'Не завершено';

  @override
  String pairNotCompletedBody(String name) {
    return 'Кошелёк $name не завершил сопряжение вовремя. Ничего не сохранено. Попробуйте снова.';
  }

  @override
  String get pairLateCheck => 'Проверка запоздалого ответа…';

  @override
  String noticeUnpaired(String name) {
    return '$name: сопряжение удалено.';
  }

  @override
  String trustRemovedBy(String name) {
    return 'Удалено: $name';
  }

  @override
  String get trustRemovedShort => 'Удалено';

  @override
  String get pairChangedTitle => 'Приглашение изменено в пути';

  @override
  String pairChangedBody(String name) {
    return 'Ничего не сохранено. Повторите сопряжение лично или с новым приглашением от $name.';
  }

  @override
  String get pairNewerTitle => 'Обновите BT Wallet, чтобы открыть это';

  @override
  String get pairNewerInviteBody =>
      'Это приглашение создано более новым кошельком.';

  @override
  String get pairNewerFileBody => 'Файл запечатан более новым кошельком.';

  @override
  String get pairCheckForUpdates => 'Проверить обновления';

  @override
  String pairSecondReplyTitle(String name) {
    return 'Кто-то ещё тоже ответил на ваше приглашение';
  }

  @override
  String get pairAnsweredSameInvite =>
      'Ответ на то же приглашение · не сохранён';

  @override
  String get sasTitle => 'Проверьте слова';

  @override
  String sasLead(String name) {
    return 'Кошелёк $name показывает те же четыре. Сравните их.';
  }

  @override
  String sasLeadExchange(String name) {
    return 'Страница $name показывает те же четыре. Сравните их, затем подтвердите с обеих сторон.';
  }

  @override
  String sasLeadRecheck(String name) {
    return 'Кошелёк $name показывает их в «$name › Проверить слова». Сравните их по телефону или лично.';
  }

  @override
  String get sasMatch => 'Совпадают';

  @override
  String get sasNoMatch => 'Не совпадают';

  @override
  String get sasSkip => 'Пропустить пока';

  @override
  String get sasLater => 'Позже';

  @override
  String sasMatchedTitle(String name) {
    return '$name: проверено';
  }

  @override
  String sasMatchedBody(String name) {
    return 'Файлы платежей и счета с $name теперь запечатаны.';
  }

  @override
  String get sasNoMatchTitle => 'Слова не совпадают';

  @override
  String get sasNoMatchBody =>
      'Сопряжение завершится с обеих сторон, и ничего отправленного через него не будет завершено. Сопрягите снова с новым приглашением.';

  @override
  String get sasStopPairing => 'Прервать сопряжение';

  @override
  String sasSkippedTitle(String name) {
    return 'Сопряжено: $name';
  }

  @override
  String sasSkippedBody(String name) {
    return 'Файлы платежей с $name запечатаны. Проверьте слова на странице контакта $name, когда сможете; счета до тех пор ждут.';
  }

  @override
  String get sasCheckNow => 'Проверить сейчас';

  @override
  String get sasAllowAfterMatch =>
      'Включится, когда вы подтвердите, что слова совпадают.';

  @override
  String sasAllowInvoicesHint(String name) {
    return 'Кошелёк $name сможет просить вас об оплате. Без вашего PIN ничего не оплачивается.';
  }

  @override
  String get trustVerified => 'Проверено';

  @override
  String get trustPaired => 'Сопряжено, не проверено';

  @override
  String get trustPairedShort => 'Сопряжено';

  @override
  String get trustKeysChanged => 'Ключи изменились';

  @override
  String get trustSealed => 'Запечатано';

  @override
  String trustSealedFor(String name) {
    return 'Запечатано для $name';
  }

  @override
  String get trustAllowsInvoices => 'Счета разрешены';

  @override
  String get contactTitle => 'Контакт';

  @override
  String get contactAddresses => 'Адреса';

  @override
  String get contactPairing => 'Сопряжение';

  @override
  String contactWordsChecked(String date) {
    return 'Проверено $date';
  }

  @override
  String get contactCheckAgain => 'Проверить снова';

  @override
  String get contactCheckWordsAgain => 'Проверить снова';

  @override
  String get contactSealPayments => 'Запечатывать платежи';

  @override
  String contactSealInfo(String name) {
    return 'Платежи и счета с $name зашифрованы сквозным шифрованием. Прочитать их может только кошелёк $name.';
  }

  @override
  String contactSealInfoMore(String name) {
    return 'Если выключено, файл транзакции для $name открытый: любой, кто получит файл, может его прочитать. Выключайте, только если кошелёк $name не открывает запечатанные файлы.';
  }

  @override
  String get contactAllowInvoices => 'Разрешить счета';

  @override
  String contactAllowInfoDesktop(String name) {
    return 'Кошелёк $name может присылать вам счета на оплату. Каждый ждёт в «Счетах» вашего одобрения и пароля кошелька. Само по себе ничего не оплачивается.';
  }

  @override
  String contactAllowInfo(String name) {
    return 'Кошелёк $name может присылать вам счета на оплату. Каждый ждёт в «Счетах» вашего одобрения и PIN. Само по себе ничего не оплачивается.';
  }

  @override
  String get contactAllowInfoMore =>
      'Разрешить можно только проверенному контакту: проверка исключает подменённое приглашение.';

  @override
  String get contactCheckWordsFirst => 'Сначала проверьте';

  @override
  String get contactPausedUntilChecked => 'Приостановлено до проверки';

  @override
  String contactDeliveredVia(String relay) {
    return 'Доставка через $relay';
  }

  @override
  String get contactDomain => 'Домен';

  @override
  String get contactDomainVerified => 'подтверждён';

  @override
  String get contactDomainNotVerified => 'ещё не подтверждён';

  @override
  String get contactDomainRefused => 'отклонён';

  @override
  String relayMoveTitle(String name) {
    return '$name: переход на новое реле';
  }

  @override
  String relayMoveBody(String name, String relay) {
    return '$name просит с этого момента отправлять через $relay. Если вы откажетесь, ничего не изменится, и $name об этом не узнает.';
  }

  @override
  String relayMoveAddsServer(String relay) {
    return 'Принятие также добавит $relay в ваши серверы Epicbox.';
  }

  @override
  String get relayMoveAccept => 'Принять';

  @override
  String get relayMoveRefuse => 'Отказать';

  @override
  String contactMoveAsked(String relay) {
    return 'Просит перейти на $relay';
  }

  @override
  String contactMoveRefused(String relay) {
    return 'Вы отказались от перехода на $relay.';
  }

  @override
  String contactMoveNotPublic(String relay) {
    return 'Просьба перейти на $relay. Не выполнено: это не публичное реле.';
  }

  @override
  String contactMovedOn(String date) {
    return 'Переход сюда: $date';
  }

  @override
  String sendViaMailboxMovedHint(String relay, String date) {
    return 'Запечатано. Доставка через $relay, переход сюда: $date';
  }

  @override
  String contactRelayDownTitle(String name) {
    return 'Сервер $name не отвечает';
  }

  @override
  String get contactRelayDownBody =>
      'Повторная попытка. Счета и платежи ждут, пока он ответит.';

  @override
  String get contactPausedEpicboxOff => 'Приостановлено, пока Epicbox выключен';

  @override
  String get contactPausedEpicboxOffBody =>
      'Запечатанные файлы по-прежнему работают.';

  @override
  String get contactRemovePairing => 'Удалить сопряжение';

  @override
  String contactRemovePairingTitle(String name) {
    return 'Удалить сопряжение с $name?';
  }

  @override
  String contactRemovePairingBody(String name) {
    return 'Запечатанные платежи и счета от $name прекратятся. Адреса останутся в ваших контактах.';
  }

  @override
  String get contactKeep => 'Оставить';

  @override
  String get contactRemove => 'Удалить';

  @override
  String contactKeysChangedTitle(String name) {
    return 'Ключи $name изменились';
  }

  @override
  String get contactKeysChangedBody =>
      'Это может значить, что теперь у этого человека другой кошелёк или что кто-то другой использует это имя. Проверьте контакт снова.';

  @override
  String get contactKeysChangedStatus => 'Запечатывание и счета приостановлены';

  @override
  String get contactKeysChangedPaused => 'Запечатывание и счета приостановлены';

  @override
  String get contactKeepOldKeys => 'Оставить старые ключи';

  @override
  String get contactUseNewKeys => 'Использовать новые ключи';

  @override
  String contactKeysBack(String name) {
    return 'Ключи $name вернулись.';
  }

  @override
  String get contactKeysBackBody => 'Для вас ничего не изменилось.';

  @override
  String contactSealDegradedTitle(String name) {
    return 'Последний платёж для $name ушёл открытым';
  }

  @override
  String contactSealDegradedBody(String name) {
    return 'Следующий спросит: запечатать или открыто. Запечатывание включится само, когда кошелёк $name ответит запечатанным файлом.';
  }

  @override
  String get addrField => 'Адрес';

  @override
  String addrFieldTyped(String type) {
    return 'Адрес ($type)';
  }

  @override
  String get addrAddAnother => 'Добавить ещё адрес';

  @override
  String addrOneFree(String type) {
    return 'Свободен ещё один тип: $type.';
  }

  @override
  String addrDuplicateType(String name, String type) {
    return 'У $name уже есть адрес этого типа ($type).';
  }

  @override
  String get addrKeepOld => 'Оставить старый';

  @override
  String get addrReplace => 'Заменить';

  @override
  String addrDesktopThird(String type) {
    return 'Вставьте адрес ($type) или оставьте пустым';
  }

  @override
  String get pendingTitle => 'Ожидающие приглашения';

  @override
  String pendingRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приглашения ждут ответа',
      many: '$count приглашений ждут ответа',
      few: '$count приглашения ждут ответа',
      one: '$count приглашение ждёт ответа',
    );
    return '$_temp0';
  }

  @override
  String pendingLink(String time) {
    return 'Ссылка · истекает через $time';
  }

  @override
  String pendingWords(String time) {
    return 'Устное приглашение · истекает через $time';
  }

  @override
  String get pendingExpired => 'Истекло';

  @override
  String get pendingInviteAgain => 'Пригласить снова';

  @override
  String get pendingWaitingConfirm => 'Ждёт подтверждения';

  @override
  String get pendingPairedCheck => 'Сопряжено · проверьте';

  @override
  String get pendingEmpty =>
      'Ожидающих приглашений нет. Приглашение видно здесь, пока другой кошелёк не ответит на него.';

  @override
  String get pendingShareAgain => 'Поделиться снова';

  @override
  String get pendingShowWords => 'Показать приглашение';

  @override
  String get invSetTitle => 'Счета';

  @override
  String get invSetLead =>
      'Сопряжённый контакт, которому вы разрешите, может присылать вам счета на оплату. Каждый ждёт в «Счетах» вашего PIN.';

  @override
  String get invSetPaired => 'Сопряжённые контакты';

  @override
  String get invSetAllowed => 'Разрешено';

  @override
  String get invSetOff => 'Выкл.';

  @override
  String get invSetPairShop => 'Сопрячь с магазином или биржей';

  @override
  String get invSetEmpty =>
      'Сопряжённых контактов пока нет. Выполните сопряжение с магазином, биржей или человеком, проверьте, затем разрешите здесь их счета.';

  @override
  String get invSetPausedBody =>
      'Счета ждут на сервере и придут, когда Epicbox снова включится.';

  @override
  String invSetSwitchedOff(String name) {
    return 'Счета от $name выключены.';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отклонено $count открытого счёта.',
      many: 'Отклонено $count открытых счетов.',
      few: 'Отклонено $count открытых счёта.',
      one: 'Отклонён $count открытый счёт.',
    );
    return '$_temp0';
  }

  @override
  String get invSetTimeToPay => 'Время на оплату';

  @override
  String invSetTimeToPayHint(int hours) {
    return '$hours ч · столько счёт остаётся доступным для оплаты';
  }

  @override
  String get invoicesEmptyAction => 'Сопряжённые контакты';

  @override
  String get reqTitle => 'Проверить счёт';

  @override
  String reqRequests(String name) {
    return '$name запрашивает';
  }

  @override
  String reqSealedSigned(String name) {
    return 'Запечатано для этого кошелька и подписано $name';
  }

  @override
  String get reqReference => 'Номер';

  @override
  String reqPaidWaiting(String name) {
    return 'Оплачено. Ждём публикации от $name';
  }

  @override
  String get reqPaidWaitingBodyPerson =>
      'Ваша часть выполнена. Кошелёк другой стороны завершает и публикует; это закроется само.';

  @override
  String get reqPaidWaitingBody =>
      'Ваша часть выполнена. Другая сторона завершает и публикует; это закроется само.';

  @override
  String get reqTlPaid => 'Оплачено';

  @override
  String get reqTlDelivered => 'Доставлено через Epicbox';

  @override
  String get reqTlAnswerDelivered => 'Ответ доставлен через Epicbox';

  @override
  String reqTlPosted(String name) {
    return 'Опубликовано: $name';
  }

  @override
  String get reqTlConfirming => 'Подтверждается';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n из $total подтверждений';
  }

  @override
  String get reqTlConfirmed => 'Подтверждено';

  @override
  String reqNotPostedTitle(String name) {
    return '$name: ещё не опубликовано';
  }

  @override
  String get reqNotPostedBody =>
      '«Отправить снова» доставляет тот же платёж ещё раз. Дважды его оплатить нельзя.';

  @override
  String get reqSendAgain => 'Отправить снова';

  @override
  String reqUnreachableTitle(String name) {
    return '$name пока недоступен';
  }

  @override
  String get reqUnreachableBody =>
      'Монеты разблокируются, если платёж не опубликуют. Доставка повторяется.';

  @override
  String get reqRelayRetrying => 'Сервер не отвечает · повтор';

  @override
  String reqWithdrewTitle(String name) {
    return '$name: счёт отозван';
  }

  @override
  String get reqWithdrewBody =>
      'Ваши средства разблокированы. Ничего не оплачено.';

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name: $count счёта на $amount EPIC за 10 минут. Оплатить все?',
      many: '$name: $count счетов на $amount EPIC за 10 минут. Оплатить все?',
      few: '$name: $count счёта на $amount EPIC за 10 минут. Оплатить все?',
      one: '$name: $count счёт на $amount EPIC за 10 минут. Оплатить?',
    );
    return '$_temp0';
  }

  @override
  String reqWithdrawalFrom(String name) {
    return 'Вывод с $name';
  }

  @override
  String reqReceivedWaiting(String name) {
    return 'Получено. Ждём публикации от $name';
  }

  @override
  String get reqReceivedWaitingBody =>
      'Ничего делать не нужно. Отправитель публикует платёж; подтверждения последуют.';

  @override
  String get reqNewTitle => 'Новый счёт';

  @override
  String get reqNewLead =>
      'Попросите сопряжённый контакт оплатить или сохраните счёт файлом для кого угодно.';

  @override
  String get reqNewLeadContacts => 'Попросите сопряжённый контакт оплатить.';

  @override
  String get reqNewTo => 'Кому';

  @override
  String get reqNewToHintContacts =>
      'Сопряжённые контакты, чей кошелёк оплачивает счета.';

  @override
  String get reqNoPayersContacts =>
      'Пока ни один сопряжённый контакт не оплачивает счета. Выполните сопряжение и проверьте.';

  @override
  String get reqNewToHint =>
      'Сопряжённые контакты, чей кошелёк оплачивает счета. Для остальных: сохраните счёт файлом.';

  @override
  String get reqNewSend => 'Отправить счёт';

  @override
  String sendViaMailbox(String name) {
    return 'Отправить через сервер Epicbox $name';
  }

  @override
  String sendViaMailboxHint(String relay) {
    return 'Запечатано. Доставка через $relay';
  }

  @override
  String sendSealedTitle(String name) {
    return 'Запечатано для $name';
  }

  @override
  String sendSealedBody(String name) {
    return 'Открыть этот файл может только кошелёк $name. Отправьте его любым способом, затем откройте файл, который придёт в ответ.';
  }

  @override
  String get sendSealOrPlainTitle => 'Запечатать этот файл?';

  @override
  String sendSealOrPlainBody(String name) {
    return 'Последний файл для $name ушёл открытым. Запечатывание снова по умолчанию.';
  }

  @override
  String get sendSealedOption => 'Запечатанный';

  @override
  String sendSealedOptionHint(String name) {
    return 'Прочитать может только кошелёк $name';
  }

  @override
  String get sendPlainOption => 'Открытый';

  @override
  String get sendPlainOptionHint => 'Прочитать может любой, у кого есть файл';

  @override
  String sendCantOpenTitle(String name) {
    return '$name не может открыть запечатанные файлы?';
  }

  @override
  String get sendCantOpenBody =>
      '«Отправить открытым» отправляет тот же платёж снова без печати. Это по-прежнему один платёж.';

  @override
  String get sendAsPlain => 'Отправить открытым';

  @override
  String get sendAsPlainTitle => 'Отправить открытым?';

  @override
  String get sendAsPlainBody =>
      'Файл не будет запечатан: любой, кто его получит, увидит сумму и адреса в нём. Это тот же платёж, поэтому дважды его оплатить нельзя.';

  @override
  String get sendKeepSealed => 'Оставить запечатанным';

  @override
  String get sendPlain => 'Отправить открытым';

  @override
  String sendNotHeardTitle(String name) {
    return 'Кошелёк $name молчит уже 90 дней';
  }

  @override
  String sendNotHeardBody(String name) {
    return 'Чтобы открыть этот файл, $name понадобится Epic Cash.';
  }

  @override
  String get sendPlainShort => 'Открыто';

  @override
  String get openSealedOtherTitle =>
      'Это запечатано для другого кошелька или установки';

  @override
  String get openSealedOtherBody =>
      'Здесь это открыть нельзя. Попросите отправителя прислать снова.';

  @override
  String get openArrivedUnsealed => 'Это пришло без печати.';

  @override
  String openArrivedUnsealedBody(String name) {
    return '$name: файл отправлен открытым.';
  }

  @override
  String noticePairingReplied(String name) {
    return '$name: есть ответ. Проверьте вместе.';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'Сопряжено: $name. Проверьте вместе.';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name запрашивает $amount EPIC.';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return 'Получено $amount EPIC от $name.';
  }

  @override
  String noticeKeysChanged(String name) {
    return 'Ключи $name изменились. Проверьте снова.';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return '$name: пара с новыми ключами. Старые ключи проверить не удалось: проверка одна в сутки, и она уже была.';
  }

  @override
  String noticeRelayDown(String name) {
    return 'Сервер Epicbox $name не отвечает.';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name: счёт отозван. Средства разблокированы.';
  }

  @override
  String get restoreUseContactsTitle =>
      'Использовать контакты на этом устройстве?';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count сопряжения из этого файла использовались на другом устройстве. Другое устройство должно перестать их использовать.',
      many:
          '$count сопряжений из этого файла использовались на другом устройстве. Другое устройство должно перестать их использовать.',
      few:
          '$count сопряжения из этого файла использовались на другом устройстве. Другое устройство должно перестать их использовать.',
      one:
          '$count сопряжение из этого файла использовалось на другом устройстве. Другое устройство должно перестать его использовать.',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => 'Использовать здесь';

  @override
  String get pairInvalidLink => 'Это не приглашение к сопряжению.';

  @override
  String get pairInvalidBody =>
      'Проверьте, что приглашение скопировано целиком, или попросите новое.';

  @override
  String get pairWrongNetworkBody => 'Это приглашение для другой сети.';

  @override
  String get pairOwnCode => 'Это ваш собственный код';

  @override
  String get pairOwnCodeBody => 'Отсканируйте код на другом телефоне.';

  @override
  String get pairUnnamedInvite => 'Открытое приглашение';

  @override
  String get pairSeenAsTooLong => 'Используйте имя покороче.';

  @override
  String get pairSeenAsEdit => 'Изменить имя, которое видит собеседник';

  @override
  String get pairCodeLabel => 'Ваш код сопряжения';

  @override
  String get pairWordsLabel => 'Ваши слова сопряжения';

  @override
  String get pairWordsEnteredLabel => 'Введённые слова';

  @override
  String pairWordSlot(int n) {
    return 'Слово $n, не введено';
  }

  @override
  String get pairSuggestions => 'Подсказки';

  @override
  String get pairCopied => 'Скопировано';

  @override
  String get pairPaste => 'Вставить';

  @override
  String get pairInPersonDone => 'Коды отсканированы';

  @override
  String get pairEpicboxOffNotice =>
      'Приостановлено, пока Epicbox выключен. Приглашение и ответ передаются вручную.';

  @override
  String get pairWaitingTitleShort => 'Сопряжение';

  @override
  String get pairClosed => 'Закрыть';

  @override
  String get sasWordsLabel => 'Четыре слова';

  @override
  String sasDialogTitle(String name) {
    return 'Проверьте слова с $name';
  }

  @override
  String get contactMore => 'Ещё';

  @override
  String get contactEdit => 'Изменить';

  @override
  String get contactDelete => 'Удалить контакт';

  @override
  String contactCopyAddress(String type) {
    return 'Копировать адрес ($type)';
  }

  @override
  String contactDeletePaired(String name) {
    return 'Удаление $name удаляет и сопряжение. Запечатанные платежи и счета от этого контакта прекратятся.';
  }

  @override
  String get contactNoAddresses => 'Адреса не сохранены.';

  @override
  String addrRemove(String type) {
    return 'Удалить адрес ($type)';
  }

  @override
  String get sendVia => 'Отправить через';

  @override
  String get invSetLeadDesktop =>
      'Сопряжённый контакт, которому вы разрешите, может присылать этому кошельку счета на оплату. Каждый ждёт в «Счетах» пароля кошелька.';

  @override
  String get invSetRowAllowed => 'Проверено · разрешено';

  @override
  String get invSetRowOff => 'Проверено · выключено';

  @override
  String get invSetRowCheckFirst =>
      'Сопряжено, не проверено · сначала проверьте';

  @override
  String invSetAllowFor(String name) {
    return 'Разрешить счета от $name';
  }

  @override
  String get reqNoPayers =>
      'Пока ни один сопряжённый контакт не оплачивает счета. Выполните сопряжение и проверьте или сохраните счёт файлом.';

  @override
  String get reqPickContact => 'Выберите контакт';

  @override
  String get reqFileSaved => 'Счёт сохранён файлом';

  @override
  String reqSent(String name) {
    return 'Счёт отправлен: $name';
  }

  @override
  String get reqFileTitle => 'Счёт на оплату';

  @override
  String noticeOutboxStuck(String name) {
    return '$name пока недоступен. Пробуем снова.';
  }

  @override
  String noticeTooMany(String name) {
    return '$name: слишком много счетов.';
  }

  @override
  String get noticeOpen => 'Открыть';

  @override
  String get noticeCheckWords => 'Проверить';

  @override
  String get noticeView => 'Показать';

  @override
  String pairSaveContactTitle(String name) {
    return 'Сохранить $name в контактах?';
  }

  @override
  String get pairSaveNewContact => 'Сохранить как новый контакт';

  @override
  String pairOtherAddressTitle(String name) {
    return 'Не добавлено к контакту $name';
  }

  @override
  String pairOtherAddressBody(String name) {
    return 'У контакта $name есть адрес Epicbox, который это сопряжение не может подтвердить.';
  }

  @override
  String get pairOtherAddress =>
      'У этого контакта есть адрес Epicbox, который это сопряжение не может подтвердить.';

  @override
  String pairAddToNamed(String name) {
    return 'Добавить к контакту $name';
  }

  @override
  String get pairAddToAContact => 'Добавить к контакту';

  @override
  String pairSavedAs(String name) {
    return 'Сохранено как $name.';
  }

  @override
  String pairDurDays(int days, int hours) {
    return '$days д $hours ч';
  }

  @override
  String pairDurHours(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String pairDurMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get pairDurUnderMinute => 'меньше минуты';

  @override
  String get pairBack => 'Назад';

  @override
  String get pairNotInContacts => 'Нет в контактах';

  @override
  String get helpPairingSection => 'Сопряжение';

  @override
  String get helpPairingLede =>
      'Сопряжение выполняется один раз; файлы транзакций и счета с этим контактом запечатаны.';

  @override
  String get helpPairWhatTitle => 'Что такое сопряжение';

  @override
  String get helpPairWhatShort =>
      'Выполните сопряжение с собеседником один раз; после этого файлы транзакций и счета между двумя кошельками запечатаны.';

  @override
  String get helpPairWhatP1 =>
      'Сопряжение связывает два кошелька один раз: запросом контакту, которому вы платили через Epicbox, или вашим приглашением, отсканированным как QR или открытым как ссылка. Каждый кошелёк хранит ключ, созданный только для этого контакта; ни с кем другим ничего не делится.';

  @override
  String get helpPairWhatP2 =>
      'После сопряжения файл транзакции для этого контакта **запечатан**: открыть его может только кошелёк контакта, и в пути его нельзя изменить или подделать. Платежи через Epicbox между людьми работают как прежде.';

  @override
  String get helpPairWhatStep1 =>
      'Откройте [[Контакты|Contacts]] и выберите **Сопрячь**.';

  @override
  String get helpPairWhatStep2 =>
      'Сопрягитесь с контактом или покажите своё приглашение и дайте его отсканировать.';

  @override
  String get helpPairWhatStep3 =>
      'Проверьте слова вместе (после запроса не нужно), затем **Совпадают**.';

  @override
  String get helpPairWhatP3 =>
      'Для сопряжения нужен BT Wallet с обеих сторон. Несопряжённый контакт по-прежнему получает обычные файлы транзакций и платежи Epicbox.';

  @override
  String get helpPairWhyTitle => 'Зачем проверять';

  @override
  String get helpPairWhyShort =>
      'Проверка доказывает, что сопряжение дошло до нужного кошелька, а не до посредника.';

  @override
  String get helpPairWhyP1 =>
      'После сопряжения оба кошелька показывают одни и те же четыре картинки с названиями. Они получаются из ключей обоих кошельков, поэтому сопряжение, изменённое в пути, покажет на двух экранах разные слова.';

  @override
  String get helpPairWhyP2 =>
      'Сравните их по телефону или лично, затем нажмите **Совпадают**. Контакт становится **Проверено**. **Пропустить пока** оставляет его в состоянии **Сопряжено, не проверено**: файлы транзакций всё равно запечатаны, но контакт не может присылать счета, пока слова не проверены.';

  @override
  String get helpPairWhyP3 =>
      'Если слова различаются, нажмите **Не совпадают**. Сопряжение удаляется с этой стороны. Повторите сопряжение лично или с новым приглашением.';

  @override
  String get helpPairWhyP4 =>
      'Названия слов остаются на английском во всех языках, чтобы их могли сравнить и люди, чьи кошельки работают на разных языках.';

  @override
  String get helpPairWordsTitle => 'Устные приглашения';

  @override
  String get helpPairWordsShort =>
      'Пять картинок с названиями заменяют ссылку, когда нечего сканировать или вставлять.';

  @override
  String get helpPairWordsP1 =>
      'Когда у одного кошелька нет камеры или приглашение нельзя отправить ссылкой, приглашающий кошелёк показывает пять слов сопряжения. Собеседник вводит их названия в **Слова или ссылка?**; поле дополняет каждое название после нескольких букв. Слова действуют 10 минут.';

  @override
  String get helpPairWordsP2 =>
      'Слова только находят приглашение. У того, кто их знает, те же возможности, что у получившего ссылку, поэтому, как обычно, затем проверьте вместе четыре слова.';

  @override
  String get helpPairWordsP3 =>
      'Для устных приглашений нужен Epicbox. Пока Epicbox выключен, отправьте ссылку-приглашение.';

  @override
  String get helpPairInvTitle => 'Счета от сопряжённых контактов';

  @override
  String get helpPairInvShortDesktop =>
      'Просить вас об оплате может только проверенный контакт, которому вы разрешили. Каждый счёт ждёт пароля кошелька.';

  @override
  String get helpPairInvShort =>
      'Просить вас об оплате может только проверенный контакт, которому вы разрешили. Каждый счёт ждёт вашего PIN.';

  @override
  String get helpPairInvP1 =>
      'Магазин, биржа или человек, с которым вы выполнили сопряжение, может присылать счета на оплату, если вы разрешите: **Разрешить счета** на странице контакта или в [[Настройки › Счета|Settings › Invoices]]. Переключатель работает только для проверенного контакта.';

  @override
  String get helpPairInvP2Desktop =>
      'Счёт появляется в [[Счета › Оплатить|Invoices › Pay]] с именем контакта, суммой и номером. Ничего не оплачивается, пока вы не одобрите счёт паролем кошелька. Счёт никогда не добавляет деньги в кошелёк.';

  @override
  String get helpPairInvP2 =>
      'Счёт появляется в [[Счета › Оплатить|Invoices › Pay]] с именем контакта, суммой и номером. Ничего не оплачивается, пока вы не одобрите счёт своим PIN. Счёт никогда не добавляет деньги в кошелёк.';

  @override
  String get helpPairInvP3 =>
      'Выключение действует сразу: новые счета от этого контакта отбрасываются, а открытые отклоняются.';

  @override
  String get helpPairInvP4 =>
      'Биржа, сопряжённая с вами, так проводит пополнения и выводы. Пополнение: биржа запрашивает, вы одобряете, биржа публикует. Вывод: биржа отправляет платёж, ваш кошелёк отвечает сам, биржа публикует.';

  @override
  String get helpPairRestoreTitle => 'Что даёт восстановление';

  @override
  String get helpPairRestoreShort =>
      'Восстановление из фразы восстановления с файлом данных кошелька возвращает все сопряжения; без него повторное сопряжение находит те же ключи.';

  @override
  String get helpPairRestoreP1 =>
      'С файлом данных кошелька восстановление возвращает все сопряжения без изменений: те же ключи, те же отметки «Проверено», те же настройки. Контакты ничего не заметят.';

  @override
  String get helpPairRestoreP2 =>
      'Без файла сопряжения пропадают из этого кошелька, но ключи нет: они получаются из фразы восстановления. Повторите сопряжение с контактом, у которого оно сохранилось, и его кошелёк найдёт те же ключи. Он сообщит, что ключи вернулись, и контакт сохранит отметку «Проверено». В этом кошельке «Запечатывать платежи» и «Разрешить счета» возвращаются к значениям по умолчанию.';

  @override
  String get helpPairRestoreP3 =>
      'Контакт видит **Ключи изменились**, только если фраза другая. Это может значить новый кошелёк или то, что кто-то другой использует это имя. Проверьте слова снова, прежде чем доверять.';

  @override
  String get helpPairRestoreP4 =>
      'Используйте сопряжение только на одном устройстве за раз. Данные кошелька, импортированные на втором устройстве, спросят, прежде чем использовать там контакты.';

  @override
  String get pairNameForCode =>
      'Введите имя, которое увидит собеседник, и здесь появится ваш код.';

  @override
  String get deskConPickForPairing =>
      'Сопряжение будет добавлено к выбранному контакту.';

  @override
  String txDetailsCancelHold(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Отмена станет возможна через $minutes минуты, если отправитель к тому времени не опубликует платёж.',
      many:
          'Отмена станет возможна через $minutes минут, если отправитель к тому времени не опубликует платёж.',
      few:
          'Отмена станет возможна через $minutes минуты, если отправитель к тому времени не опубликует платёж.',
      one:
          'Отмена станет возможна через $minutes минуту, если отправитель к тому времени не опубликует платёж.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsCancelWhileReported =>
      'Отмена недоступна, пока отправитель сообщает, что опубликовал платёж.';

  @override
  String get txDetailsCancelRefusedOnNetwork =>
      'Не отменено: платёж уже есть в сети. Он будет выполнен, когда блокчейн его подтвердит.';

  @override
  String get contactStar => 'В избранное';

  @override
  String get contactUnstar => 'Из избранного';

  @override
  String get contactStarred => 'В избранном';

  @override
  String get contactsImport => 'Импортировать контакты';

  @override
  String get contactsExport => 'Экспортировать контакты';

  @override
  String contactsExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Экспортировано $count контакта',
      many: 'Экспортировано $count контактов',
      few: 'Экспортировано $count контакта',
      one: 'Экспортирован $count контакт',
    );
    return '$_temp0';
  }

  @override
  String get contactsExportHolds =>
      'Файл содержит имена, заметки и адреса. Без ключей и сопряжений.';

  @override
  String get contactsImportTitle => 'Импортировать контакты?';

  @override
  String contactsImportNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нового контакта',
      many: '$count новых контактов',
      few: '$count новых контакта',
      one: '$count новый контакт',
    );
    return '$_temp0';
  }

  @override
  String contactsImportMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count контакта обновлены',
      many: '$count контактов обновлены',
      few: '$count контакта обновлены',
      one: '$count контакт обновлён',
    );
    return '$_temp0';
  }

  @override
  String contactsImportSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уже сохранены',
      many: '$count уже сохранены',
      few: '$count уже сохранены',
      one: '$count уже сохранён',
    );
    return '$_temp0';
  }

  @override
  String contactsImportLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Пропущено $count: нет адреса, на который этот кошелёк может отправить',
      many:
          'Пропущено $count: нет адреса, на который этот кошелёк может отправить',
      few:
          'Пропущено $count: нет адреса, на который этот кошелёк может отправить',
      one:
          'Пропущен $count: нет адреса, на который этот кошелёк может отправить',
    );
    return '$_temp0';
  }

  @override
  String contactsImportOtherNet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропущено $count: адреса другой сети',
      many: 'Пропущено $count: адреса другой сети',
      few: 'Пропущено $count: адреса другой сети',
      one: 'Пропущен $count: адрес другой сети',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportKeeps => 'Существующие данные сохраняются.';

  @override
  String get contactsImportDo => 'Импортировать';

  @override
  String get contactsImportNothing => 'Импортировать нечего.';

  @override
  String contactsImported(int added, int same) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Добавлено $added контакта',
      many: 'Добавлено $added контактов',
      few: 'Добавлено $added контакта',
      one: 'Добавлен $added контакт',
    );
    String _temp1 = intl.Intl.pluralLogic(
      same,
      locale: localeName,
      other: '$same уже сохранены',
      many: '$same уже сохранены',
      few: '$same уже сохранены',
      one: '$same уже сохранён',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String contactsImportedAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Добавлено $added контакта',
      many: 'Добавлено $added контактов',
      few: 'Добавлено $added контакта',
      one: 'Добавлен $added контакт',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportNotFile => 'Этот файл не является файлом контактов.';

  @override
  String get contactsImportDamaged =>
      'Не удалось прочитать файл. Возможно, он повреждён.';

  @override
  String get contactsImportNewer =>
      'Этот файл создан более новой версией BT Wallet. Обновите приложение, чтобы импортировать его.';

  @override
  String get contactsImportEmpty => 'В файле нет контактов.';

  @override
  String get contactsImportAllOtherNet =>
      'Эти контакты относятся к другой сети. Ни один нельзя использовать здесь.';

  @override
  String get expPairing => 'Сопряжение';

  @override
  String get expPairingHint =>
      'Однократное сопряжение с тем, с кем часто бывают платежи: файлы транзакций и счета между двумя кошельками запечатаны, а контакт отмечен как сопряжённый. Экспериментально: может ещё измениться.';

  @override
  String get expInvoices => 'Счета';

  @override
  String get expInvoicesHint =>
      'Запрос платежа у сопряжённого контакта и одобрение счетов от сопряжённых контактов. Нужно сопряжение. Экспериментально: может ещё измениться.';

  @override
  String get expNeedsPairing => 'Счетам нужно сопряжение.';

  @override
  String get expPairingOffTitle => 'Сопряжение — экспериментальная функция';

  @override
  String get expPairingOffBody => 'Включается в Настройки › Дополнительно.';

  @override
  String get expInvoicesOffTitle => 'Счета — экспериментальная функция';

  @override
  String get expInvoicesOffBody => 'Включаются в Настройки › Дополнительно.';

  @override
  String get expOpenAdvanced => 'Открыть Дополнительно';

  @override
  String get contactNoAddressPaired => 'Платежи идут через сопряжение';

  @override
  String get contactSendKeysChanged => 'Перед отправкой проверьте контакт.';

  @override
  String contactSendNoSealed(String name) {
    return 'Кошелёк $name не принимает платежи через сопряжение. Попросите адрес.';
  }

  @override
  String sendRecipientPairing(String name) {
    return 'Через сопряжение с $name';
  }

  @override
  String get sendClearRecipient => 'Очистить получателя';

  @override
  String get sendQueuedEpicboxOff =>
      'Epicbox выключен. Платёж ждёт здесь и уйдёт, когда Epicbox снова включится.';

  @override
  String get sendQueue => 'В очередь';

  @override
  String get sendQueuedHeadline => 'Платёж в очереди';

  @override
  String sendQueuedBody(String name) {
    return 'Он уйдёт, когда Epicbox снова включится. Ответ $name придёт тем же путём.';
  }

  @override
  String txStatusWaitingFor(String name) {
    return 'Ждёт: $name';
  }

  @override
  String txStepSentMailbox(String name) {
    return 'Отправлено через сервер Epicbox $name';
  }

  @override
  String txStepAnswerFrom(String name) {
    return 'Ответ от $name';
  }

  @override
  String txStepCollecting(String name) {
    return 'Проверка сервера Epicbox $name';
  }

  @override
  String deskTxStatusWaitingFor(String name) {
    return 'Ждёт подписи: $name';
  }

  @override
  String deskSendContactNoLink(String name) {
    return 'У $name нет адреса Link.';
  }

  @override
  String get reqToFile => 'Сохранить файлом для кого угодно';

  @override
  String reqFileSummary(String amount) {
    return 'Любой, кто откроет файл, может оплатить $amount. Ответ вернётся файлом.';
  }

  @override
  String get reqSaveFile => 'Сохранить файлом';

  @override
  String get reqFileLead =>
      'Отправьте этот файл тому, кто должен заплатить. Его кошелёк ответит файлом; откройте его здесь, чтобы завершить.';

  @override
  String get reqByFile => 'Файлом';

  @override
  String get reqToAnyone => 'Любой, у кого есть файл';

  @override
  String get reqFileWaitingCard =>
      'Ожидает файл ответа. Откройте его в разделе «Получить» или нажав на него.';

  @override
  String get reqFromFileTitle => 'Счёт на оплату из файла';

  @override
  String get reqFromFileWarn =>
      'Ничто не говорит, кто создал этот счёт. Оплачивайте, только если ждали его от знакомого человека.';

  @override
  String get reqFileMessageLabel => 'Сообщение в файле';

  @override
  String get reqApproveSaveAnswer => 'Одобрить и сохранить ответ';

  @override
  String get reqNotNow => 'Не сейчас';

  @override
  String get reqAnswerTitle => 'Ответ сохранён';

  @override
  String get reqAnswerLead =>
      'Отправьте этот файл обратно тому, кто запросил. Он завершит платёж и отправит его в сеть.';

  @override
  String get reqFileAlreadyPaid => 'Этот счёт уже оплачен.';

  @override
  String get reqFileEnded => 'Этот счёт больше не действует.';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return 'Ответ на ваш счёт на оплату: $amount.';
  }

  @override
  String get reqAnswerUnknown =>
      'Это ответ на счёт, которого в этом кошельке больше нет.';

  @override
  String get deskInvIssuerAnother => 'Ещё один счёт';

  @override
  String get deskImpOpenAnother => 'Открыть другой файл';

  @override
  String get deskInvIssuerToAnyone => 'Счёт для любого, у кого есть файл';

  @override
  String deskOnbImportRelayTitle(String name) {
    return 'Сервер Epicbox для $name';
  }

  @override
  String deskOnbImportRelayLead(String old) {
    return 'Старое приложение принимало через $old.';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return 'Оставить $old';
  }

  @override
  String get deskOnbImportRelayKeepHint =>
      'Адрес тот же; сервер добавляется в список Epicbox.';

  @override
  String deskOnbImportRelayApp(String current) {
    return 'Использовать $current';
  }

  @override
  String get deskOnbImportRelayAppHint =>
      'Новый адрес: платежи на старый не придут.';

  @override
  String get deskOnbImportUnlockOld => 'Разблокировка старым паролем.';

  @override
  String get deskOnbImportUnlockNew =>
      'Разблокировка новым паролем, выбранным здесь.';

  @override
  String get deskOnbWelcomeOtherApps =>
      'Из Stack Wallet или Epic Pay: восстановите по фразе восстановления.';

  @override
  String get deskOnbImportCloseFirstWindows =>
      'Закройте старый Epic Wallet перед импортом. В Windows нельзя проверить, запущен ли он ещё.';

  @override
  String get deskSetRecvEpicboxOwnHint =>
      'У этого кошелька свой сервер Epicbox, сохранённый из старого приложения. Изменение здесь касается только этого кошелька.';

  @override
  String get deskErrRestoreScanRequired =>
      'Восстановление не завершено. Получение и отправка станут доступны, когда закончится сканирование блокчейна.';

  @override
  String get deskSetupSkip => 'Пропустить настройку';

  @override
  String get deskOvRestoreTitle => 'Восстановление не завершено';

  @override
  String get deskOvRestoreRunning =>
      'Поиск средств этого кошелька в блокчейне. Полученные EPIC появляются по мере нахождения; получение и отправка станут доступны после завершения сканирования.';

  @override
  String deskOvRestoreAfterHeight(String height) {
    return 'Средства после блока $height уже найдены. Более ранние блоки ещё проверяются; получение и отправка станут доступны после завершения.';
  }

  @override
  String get deskOvRestoreWaiting => 'Сканирование ждёт сети.';

  @override
  String get deskOvRestoreFailed =>
      'Сканирование остановилось раньше конца. Получение и отправка недоступны, пока оно не завершится.';

  @override
  String get deskOvRestoreProgress => 'Ход сканирования после восстановления';

  @override
  String get deskSetRescanRestoreRunning =>
      'Идёт сканирование после восстановления. Сверка баланса станет доступна после его завершения.';

  @override
  String get deskSetRescanStartHeading => 'Откуда начать';

  @override
  String get deskOnbForgotLink => 'Забыли пароль?';

  @override
  String get deskOnbForgotTitle => 'Новый пароль';

  @override
  String deskOnbForgotLead(String name) {
    return 'Фраза восстановления кошелька $name заменяет его пароль. История, заметки и метки сохраняются; сканирование не нужно.';
  }

  @override
  String get deskOnbForgotPasswordLead =>
      'Фраза верна. Выберите новый пароль, который разблокирует этот кошелёк на этом компьютере.';

  @override
  String get deskOnbForgotSet => 'Установить пароль';

  @override
  String deskOnbForgotOtherWallet(String name) {
    return 'Эта фраза принадлежит другому кошельку, а не $name. Ничего не изменено.';
  }

  @override
  String get deskOnbSameNewPassword => 'Новый пароль';

  @override
  String get deskSetupSkipKeeps =>
      'Пропуск оставляет текущие настройки узла и Epicbox.';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return 'Не удалось отметить настройку как завершённую: $reason. Она может открыться снова при следующем запуске; «Пропустить настройку» закрывает её.';
  }

  @override
  String get deskOvRestoredImportTitle => 'Кошелёк восстановлен';

  @override
  String get deskOvRestoredImportBody =>
      'Баланс вернулся. Файл данных этого кошелька возвращает историю, контакты, счета и настройки.';

  @override
  String get deskOvRestoredImportButton => 'Импорт данных кошелька';

  @override
  String get deskOvRestoredImportLater =>
      'Позже: Настройки › Кошелёк › Резервная копия.';

  @override
  String get deskOnbForgotNoCheck =>
      'Ничто в файлах этого кошелька не может подтвердить фразу, поэтому пароль остаётся прежним.';

  @override
  String deskOnbForgotRestoreHint(String name) {
    return 'Вместо этого восстановите его по фразе: $name уйдёт из списка, а его файлы останутся на этом компьютере.';
  }

  @override
  String get deskOnbForgotRestoreInstead => 'Восстановить по фразе';

  @override
  String get qrShowTitleRequest => 'Счёт на оплату';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount с телефона рядом с вами';
  }

  @override
  String get qrHiddenBodyRequest =>
      'Тот, кто его отсканирует, сможет оплатить этот счёт. Показывайте его только тому, кто платит.';

  @override
  String get qrStatusRequestHidden => 'Покажите это тому, кто платит.';

  @override
  String get qrStatusRequestShowing =>
      'Ждём, пока они отсканируют и одобрят. Затем отсканируйте их ответ.';

  @override
  String qrSemanticsRequest(String state) {
    return 'QR-код счёта на оплату, $state';
  }

  @override
  String qrShowSubPaid(String amount) {
    return 'Тому, кто запросил $amount';
  }

  @override
  String get qrHiddenBodyPaid =>
      'Покажите его телефону, который запросил платёж. Использовать его сможет только тот кошелёк.';

  @override
  String get qrStatusPaidHidden => 'Покажите это тому, кто запросил.';

  @override
  String get qrStatusPaidShowing =>
      'Ждём, пока они отсканируют и отправят его в сеть.';

  @override
  String get qrStatusPaid => 'Оплачено.';

  @override
  String get reqToQr => 'Показать как QR телефону рядом';

  @override
  String reqQrSummary(String amount) {
    return 'Тот, кто отсканирует код, сможет оплатить $amount. Отсканируйте здесь их ответ, чтобы завершить. Счёт истекает через 24 ч.';
  }

  @override
  String get reqShowQr => 'Показать как QR';

  @override
  String get receiveQrRequest => 'Запросить сумму';

  @override
  String get reqQrPaidTitle => 'Оплачено';

  @override
  String reqQrPaidHeadline(String amount) {
    return '$amount оплачено и отправлено в сеть.';
  }

  @override
  String get reqQrNew => 'Новый счёт';

  @override
  String get reqQrAlreadyPaid =>
      'Этот счёт уже оплачен. С этого телефона ничего не списано: его платёж остаётся заблокированным, пока его не отменят в «Активности» или он не истечёт через день.';

  @override
  String get reqFromQrTitle => 'Счёт на оплату из QR-кода';

  @override
  String get reqFromQrWarn =>
      'Не от сопряжённого контакта. Ничто в коде не говорит, кто его создал: платите только человеку или магазину перед вами и проверьте сумму.';

  @override
  String get reqQrMessageLabel => 'Сообщение в коде';

  @override
  String get reqApproveShowAnswer => 'Одобрить и показать ответ';

  @override
  String get reqQrAnswerTitle => 'Одобрено';

  @override
  String get reqQrAnswerLead =>
      'Тот, кто запросил, сканирует ответ и отправляет платёж в сеть. До тех пор он ждёт в Активности как «Ждёт получателя».';

  @override
  String get reqExpired =>
      'Этот счёт истёк. Попросите новый. Ничего не оплачено.';

  @override
  String get reqOtherChain =>
      'Этот счёт принадлежит другой сети Epic, или его срок не подходит этой сети. Ничего не оплачено.';

  @override
  String get reqQrOpenNote =>
      'Открыт в Счета › Отправленные 24 ч, затем истекает.';

  @override
  String get reqQrWrongReply =>
      'Этот ответ относится к другому счёту. Отсканируйте ответ на этот.';

  @override
  String get backupFileHolds =>
      'Содержит историю платежей, контакты, счета и настройки этого кошелька на текущий момент.';

  @override
  String get backupFileRestoreOrder =>
      'Чтобы восстановить: сначала введите фразу восстановления, затем импортируйте этот файл.';

  @override
  String get backupImportLead =>
      'Возвращает историю платежей, контакты, счета и настройки этого кошелька. Сначала восстановите кошелёк по его фразе восстановления.';

  @override
  String backupRestoredSummary(String items) {
    return 'Импортировано: $items.';
  }

  @override
  String get backupListSeparator => ', ';

  @override
  String get backupListLastSeparator => ' и ';

  @override
  String backupRestoredPayments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n платежа',
      many: '$n платежей',
      few: '$n платежа',
      one: '$n платёж',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredNotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n заметки',
      many: '$n заметок',
      few: '$n заметки',
      one: '$n заметка',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredLabels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n метки',
      many: '$n меток',
      few: '$n метки',
      one: '$n метка',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredContacts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n контакта',
      many: '$n контактов',
      few: '$n контакта',
      one: '$n контакт',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredStars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n избранных контакта',
      many: '$n избранных контактов',
      few: '$n избранных контакта',
      one: '$n избранный контакт',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredPairings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n сопряжения',
      many: '$n сопряжений',
      few: '$n сопряжения',
      one: '$n сопряжение',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredInvoices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n счёта',
      many: '$n счетов',
      few: '$n счёта',
      one: '$n счёт',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoredSettings => 'настройки';

  @override
  String get backupRestoredWalletName => 'название кошелька';

  @override
  String backupRestoredAlreadyHere(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n записи уже были здесь.',
      many: '$n записей уже были здесь.',
      few: '$n записи уже были здесь.',
      one: '$n запись уже была здесь.',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsTitle => 'Использовать настройки из этого файла?';

  @override
  String backupSettingsBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n настройки здесь отличаются от файла.',
      many: '$n настроек здесь отличаются от файла.',
      few: '$n настройки здесь отличаются от файла.',
      one: '$n настройка здесь отличается от файла.',
    );
    return '$_temp0 Остальное из файла уже импортировано.';
  }

  @override
  String get backupSettingsUseBackup => 'Из файла';

  @override
  String get backupSettingsKeepMine => 'Оставить мои';

  @override
  String get deskEpicboxBlockedWord => 'Заблокирован';

  @override
  String deskEpicboxBlockedText(String host) {
    return 'Эта сеть блокирует $host. Выберите другой сервер Epicbox или используйте частный DNS.';
  }

  @override
  String deskEpicboxBlockedShort(String host) {
    return 'Эта сеть блокирует $host. Выберите другой сервер или частный DNS.';
  }

  @override
  String deskEpicboxBlockedSwitch(String host) {
    return 'Переключиться на $host';
  }

  @override
  String get deskSlotNow => 'Сейчас';

  @override
  String get deskSlotHelp => 'Справка';

  @override
  String get deskSlotScanning => 'Сканирование цепочки';

  @override
  String get deskSlotScanWaits => 'Сканирование ждёт сети';

  @override
  String get deskSlotScanStopped => 'Сканирование остановлено';

  @override
  String get deskSlotTryAgain => 'Повторить';

  @override
  String get deskSlotSending => 'Отправка платежа';

  @override
  String get deskSlotPaymentOut => 'Платёж в пути';

  @override
  String get deskSlotPaymentIn => 'Платёж поступает';

  @override
  String get deskSlotPaymentsOut => 'Платежи в пути';

  @override
  String get deskSlotPaymentsMoving => 'Платежи в пути';

  @override
  String deskSlotOf(String done, String needed) {
    return '$done из $needed';
  }

  @override
  String get deskSlotWaitingBlock => 'ждёт блока';

  @override
  String get deskSlotRequests => 'Новые счета';

  @override
  String get deskSlotNodeStarting => 'Запуск локального узла';

  @override
  String get deskSlotNodeSyncing => 'Синхронизация локального узла';

  @override
  String get deskSlotOpenRecheck => 'Открыть «Сверка баланса»';

  @override
  String get deskSlotOpenSend => 'Открыть «Отправить»';

  @override
  String get deskSlotOpenActivity => 'Открыть в «Активности»';

  @override
  String get deskSlotOpenInvoices => 'Открыть «Счета»';

  @override
  String deskBarMenu(String app) {
    return 'Меню $app';
  }

  @override
  String get deskBarLock => 'Заблокировать кошелёк';

  @override
  String get deskBarShortcuts => 'Сочетания клавиш';

  @override
  String deskBarAbout(String app) {
    return 'О программе $app';
  }

  @override
  String get deskBarQuit => 'Выйти';

  @override
  String get deskBarWalletsHere => 'Кошельки на этом компьютере';

  @override
  String get deskBarAddWallet => 'Добавить кошелёк';

  @override
  String get deskBarWalletSettings => 'Настройки кошелька';

  @override
  String get deskBarStatus => 'Состояние подключений';

  @override
  String get deskBarMinimise => 'Свернуть';

  @override
  String get deskBarMaximise => 'Развернуть';

  @override
  String get deskBarRestore => 'Восстановить';

  @override
  String get deskBarClose => 'Закрыть';

  @override
  String get deskBarSendRunningTitle => 'Идёт отправка';

  @override
  String get deskBarSendRunningBody =>
      'Если закрыть сейчас, исход платежа останется неизвестным. Кошелёк может закрыться сам, когда отправка завершится.';

  @override
  String get deskBarKeepOpen => 'Не закрывать';

  @override
  String get deskBarCloseAfterSend => 'Закрыть после отправки';

  @override
  String get deskBarClosesAfterSend => 'Закроется после отправки';

  @override
  String get deskBarClosing => 'Закрытие';

  @override
  String get deskBarKeyBack => 'Назад';

  @override
  String get deskBarKeyForward => 'Вперёд';

  @override
  String get deskBarKeyClose => 'Закрыть меню или окно';

  @override
  String get deskBarKeySubmit => 'Выполнить основное действие формы';

  @override
  String get deskBarKeyList => 'Этот список';

  @override
  String get deskBarCopyBuild => 'Скопировать сведения о сборке';

  @override
  String get deskBarBuildCopied => 'Сведения о сборке скопированы';

  @override
  String get deskBarKeyMenu => 'Открыть меню приложения';

  @override
  String get txDetailsCancelRequestBody =>
      'Другая сторона ещё может завершить этот платёж.';

  @override
  String get txDetailsCancelNotPostedBody =>
      'Этот платёж ещё может пройти позже.';

  @override
  String get cancelMoreInHelp => 'Как работает отмена';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '$amount EPIC для $who. Этот платёж ещё может пройти позже.';
  }

  @override
  String get deskOnbWalletNameEdit => 'Изменить название кошелька';

  @override
  String get deskOnbWalletNameField => 'Название кошелька';

  @override
  String deskOnbWalletNameIs(String name) {
    return 'Название кошелька: $name';
  }

  @override
  String sendTurnOnMethod(String method) {
    return 'Включить $method';
  }

  @override
  String get reqPickContactOrMethod => 'Выберите контакт или способ';

  @override
  String deskOnbUnlockOpened(String when) {
    return 'Открыт $when';
  }

  @override
  String get deskOwnYourNode => 'Свой узел';

  @override
  String deskOwnLabel(String where) {
    return 'Свой узел · $where';
  }

  @override
  String get deskOwnClassThisComputer => 'этот компьютер';

  @override
  String get deskOwnClassHome => 'домашняя сеть';

  @override
  String get deskOwnClassVpn => 'VPN';

  @override
  String get deskOwnFactMempool => 'Мемпул';

  @override
  String get deskOwnPoolEmpty => 'пусто';

  @override
  String deskOwnPoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ждут',
      many: '$count ждут',
      few: '$count ждут',
      one: '$count ждёт',
    );
    return '$_temp0';
  }

  @override
  String deskOwnSourceSite(String site) {
    return 'Опрашивается напрямую каждые 15 с · вершина от $site';
  }

  @override
  String deskOwnSourceNodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Опрашивается напрямую каждые 15 с · вершина от $count публичных узлов',
      many:
          'Опрашивается напрямую каждые 15 с · вершина от $count публичных узлов',
      few:
          'Опрашивается напрямую каждые 15 с · вершина от $count публичных узлов',
      one:
          'Опрашивается напрямую каждые 15 с · вершина от $count публичного узла',
    );
    return '$_temp0';
  }

  @override
  String get deskOwnSourceNone =>
      'Опрашивается напрямую каждые 15 с · нет вершины сети для сравнения';

  @override
  String get deskOwnSyncingLine =>
      'Пока он не синхронизирован, кошелёк не может через него отправлять и получать';

  @override
  String get deskOwnAccess => 'Доступ владельца';

  @override
  String get deskOwnAccessHint =>
      'Секрет владельца узла показывает здесь этап синхронизации и пиров и позволяет заблокировать пира. Он хранится в связке ключей этого компьютера, никогда в настройках или файле данных кошелька.';

  @override
  String get deskOwnAccessNotSet => 'Не настроен';

  @override
  String get deskOwnAccessOn => 'Добавлен';

  @override
  String deskOwnAccessRefused(String time) {
    return 'Отклоняется с $time';
  }

  @override
  String get deskOwnAccessRefusedBadge => 'Отклонён';

  @override
  String get deskOwnAccessTor => 'Не используется, пока включён Tor';

  @override
  String get deskOwnAccessNote =>
      'Пиры и детали синхронизации берутся из API владельца узла.';

  @override
  String get deskOwnAdd => 'Добавить…';

  @override
  String get deskOwnUpdate => 'Обновить…';

  @override
  String get deskOwnRemove => 'Удалить';

  @override
  String get deskOwnAdded => 'Доступ владельца добавлен';

  @override
  String get deskOwnRemoved => 'Доступ владельца удалён';

  @override
  String deskOwnDlgTitle(String host) {
    return 'Доступ владельца к $host';
  }

  @override
  String get deskOwnDlgWhere =>
      'Секрет — первая строка файла .api_secret в папке данных узла (~/.epic/main на компьютере узла).';

  @override
  String get deskOwnDlgPaste => 'Вставьте секрет';

  @override
  String get deskOwnDlgPick => 'Выбрать файл…';

  @override
  String deskOwnDlgFileRead(String file) {
    return 'Прочитано из $file';
  }

  @override
  String get deskOwnDlgFileEmpty => 'В этом файле нет секрета';

  @override
  String get deskOwnDlgPlainTitle =>
      'Секрет идёт по домашней сети без шифрования';

  @override
  String get deskOwnDlgPlainText =>
      'В общей сети подключайтесь к узлу через VPN или https либо запустите кошелёк на компьютере узла.';

  @override
  String get deskOwnDlgPlainAgain => 'Больше не показывать для этого узла';

  @override
  String get deskOwnDlgRefused => 'Узел отклонил этот секрет';

  @override
  String get deskOwnDlgNoAnswer => 'Узел не ответил; секрет сохранён';

  @override
  String get deskOwnDlgAdd => 'Добавить';

  @override
  String get deskOwnDownTitle => 'Свой узел не отвечает';

  @override
  String deskOwnDownText(String host) {
    return 'Пока кошелёк использует $host и вернётся, когда этот узел ответит два раза подряд.';
  }

  @override
  String deskOwnUsingMeanwhile(String host) {
    return 'пока используется $host';
  }

  @override
  String deskOwnUsingUntilSynced(String host) {
    return '$host до синхронизации';
  }

  @override
  String get deskOwnTryNow => 'Повторить';

  @override
  String deskOwnUseForGood(String host) {
    return 'Оставить $host';
  }

  @override
  String get deskOwnSyncTitle =>
      'Использовать публичный узел, пока этот узел синхронизируется?';

  @override
  String deskOwnSyncText(String host) {
    return '$host может заменить его, пока этот узел не синхронизируется.';
  }

  @override
  String get deskOwnWaitForMine => 'Ждать этот узел';

  @override
  String deskOwnSyncUsingTitle(String host) {
    return '$host до синхронизации этого узла';
  }

  @override
  String get deskOwnSyncUsingText =>
      'Кошелёк вернётся, когда этот узел начнёт принимать транзакции.';

  @override
  String get deskOwnMine => 'Это мой узел';

  @override
  String deskOwnMineHint(String site) {
    return 'Опрашивает сам узел вместо $site и предлагает доступ владельца. Для узла, который вы держите сами.';
  }

  @override
  String get deskOwnSlotSyncing => 'Свой узел синхронизируется';

  @override
  String ownNodeLabel(String where) {
    return 'Ваш узел · $where';
  }

  @override
  String get ownNodeThisPhone => 'этот телефон';

  @override
  String get ownNodeHome => 'домашняя сеть';

  @override
  String get ownNodeVpn => 'VPN';

  @override
  String get ownNodeSynced => 'Синхронизирован';

  @override
  String get ownNodeSyncing => 'Синхронизация…';

  @override
  String get ownNodeBehind => 'Отстаёт';

  @override
  String get ownNodeFactBehind => 'Отставание';

  @override
  String get ownNodeFactLatency => 'Задержка';

  @override
  String get ownNodeFactAccepts => 'Принимает транзакции';

  @override
  String get ownNodeFactMempool => 'Мемпул';

  @override
  String get ownNodeYes => 'Да';

  @override
  String get ownNodeNotYet => 'Пока нет';

  @override
  String get ownNodeUnknown => 'Неизвестно';

  @override
  String get ownNodePoolEmpty => 'пусто';

  @override
  String ownNodePoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ждут',
      many: '$count ждут',
      few: '$count ждут',
      one: '$count ждёт',
    );
    return '$_temp0';
  }

  @override
  String get ownNodeAskedDirectly =>
      'Опрашивается напрямую с этого телефона каждые 15 с';

  @override
  String get deskConExportDo => 'Экспортировать';

  @override
  String get deskSetAboutDownloadPage => 'Страница загрузки';

  @override
  String get deskUpdManual =>
      'Эта копия не может сама устанавливать обновления.';

  @override
  String get deskUpdDownloadInstall => 'Скачать и установить';

  @override
  String get deskUpdReadyTitle => 'Перезапустите для обновления';

  @override
  String get deskUpdReadyBody =>
      'Кошелёк заблокируется, а приложение откроется снова.';

  @override
  String get deskUpdRestartNow => 'Перезапустить';

  @override
  String get deskUpdLater => 'Позже';

  @override
  String get sendTorNotInVersion =>
      'Эта версия не может отправлять на адреса Tor.';

  @override
  String get methodSendDirectLineNoTor =>
      'Кошелёк получателя должен быть открыт.';

  @override
  String get sendDirectAddressShapeNoTor =>
      'Адрес ссылки начинается с http:// или https://.';

  @override
  String get contactsAddressInvalidAnyNoTor =>
      'Недействительный адрес. Используйте адрес Epicbox (es5x…@сервер) или адрес ссылки (https://…).';

  @override
  String get handshakeLink1NoTor =>
      'Ваш кошелёк отправляет платёж прямо их кошельку, через интернет. Монеты блокируются.';

  @override
  String txLinkHttpHintNoTor(String port) {
    return 'Ссылка · HTTP платит прямо в кошелёк по веб-адресу (http://host:$port) и даёт этому телефону адрес, на который могут платить кошельки из той же сети Wi-Fi. Оба кошелька должны быть открыты. По дороге он не шифруется и недоступен из интернета и по мобильным данным. Добавляет Ссылка · HTTP в «Отправить» и «Получить».';
  }

  @override
  String get tourPhoneWalletTextNoTor =>
      'Ваш баланс, а под ним значки узла и Epicbox. То, что ещё подтверждается, — в плитках ниже.';

  @override
  String get tourPhonePrivacyTextNoTor =>
      'Какой узел и сервер Epicbox использует кошелёк. Нажмите на сервер, чтобы изменить его.';

  @override
  String get tourPhoneAdvancedTextNoTor =>
      '«Офлайн», выходы и технические сведения собраны здесь. Включайте то, что нужно.';

  @override
  String get deskNoTorSendDirectLine2 =>
      'Адрес http(s). Кошелёк получателя должен быть открыт.';

  @override
  String deskNoTorSetTxDirectHint(String port) {
    return 'Платите и получайте платежи напрямую от кошелька к кошельку по веб-адресу (http://host:$port), без сервера посередине. Работает, только пока оба кошелька открыты. Добавляет Ссылка · HTTP в «Отправить», а его адрес — в «Получить». Все кошельки.';
  }

  @override
  String get deskNoTorTxDetailsFromBad => 'Укажите адрес Epicbox или http(s).';

  @override
  String get deskNoTorTourAdvancedText =>
      'Выходы и технические сведения собраны здесь. Включайте то, что нужно.';

  @override
  String get errorInputsSpentElsewhere =>
      'Узел показывает эти монеты уже потраченными, а этот кошелёк их не тратил. Скорее всего, это сделал другой кошелёк с вашей фразой восстановления.';

  @override
  String get deskErrInputsSpentElsewhere =>
      'Узел показывает эти монеты уже потраченными, а этот кошелёк их не тратил. Скорее всего, это сделал другой кошелёк с вашей фразой восстановления.';

  @override
  String get slAddedByYou => 'Добавлено вами';

  @override
  String slCount(int n, int limit) {
    return '$n из $limit';
  }

  @override
  String slLimit(int limit) {
    return 'Выбрано $limit из $limit. Снимите отметку, чтобы выбрать другой.';
  }

  @override
  String get slKeepOne => 'Оставьте хотя бы один.';

  @override
  String get slChosenUntick => 'Выбран. Сначала снимите отметку.';

  @override
  String get slResetDefaults => 'Сбросить на стандартные';

  @override
  String get slReset => 'Сброшено на стандартные.';

  @override
  String slChosen(String host) {
    return 'Выбран: $host.';
  }

  @override
  String slChosenNonDefault(String host) {
    return 'Выбрано. Кошельки, которые тоже используют $host, найдут вас там.';
  }

  @override
  String slUnchosen(String host) {
    return 'Снята отметка: $host.';
  }

  @override
  String slAddedNonDefault(String host) {
    return 'Добавлено: $host. Кошельки, которые тоже его используют, найдут вас там.';
  }

  @override
  String slAddedUntick(String host) {
    return 'Добавлено: $host. Снимите другую отметку, чтобы выбрать его.';
  }

  @override
  String get txSentFromOtherWallet => 'Отправлено с другого устройства';

  @override
  String txSpokenSentFromOtherWallet(String amount) {
    return 'Отправлено с другого устройства, $amount';
  }

  @override
  String get txDetailsOtherWallet =>
      'Отправлено с другого устройства с фразой восстановления этого кошелька. Известна только сумма.';

  @override
  String get txSentFromOtherWalletUnverified =>
      'Отправлено с другого устройства · не проверено';

  @override
  String get txDetailsUnverified =>
      'Не проверено: пока об этом сообщает только узел. Подтвердите через «Сверка баланса».';

  @override
  String get txDetailsNotKnown => 'Неизвестно';

  @override
  String get txReceivedByOtherWallet => 'Получено на другом устройстве';

  @override
  String txSpokenReceivedByOtherWallet(String amount) {
    return 'Получено на другом устройстве, $amount';
  }

  @override
  String get txDetailsOtherWalletIn =>
      'Получено на другом устройстве с фразой восстановления этого кошелька. Известна только сумма.';

  @override
  String get expLinkedDevices => 'Связанные устройства';

  @override
  String get expLinkedDevicesHint =>
      'Этот кошелёк на двух устройствах: каждое показывает платежи другого и удерживает монеты, которые другое сейчас тратит. Экспериментально.';

  @override
  String get devicesThisPhone => 'Телефон';

  @override
  String get devicesThisComputer => 'Компьютер';

  @override
  String get devicesNone => 'Нет';

  @override
  String get devicesSeenNow => 'был на связи только что';

  @override
  String devicesSeenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'был на связи $count мин назад',
      many: 'был на связи $count мин назад',
      few: 'был на связи $count мин назад',
      one: 'был на связи $count мин назад',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'был на связи $count ч назад',
      many: 'был на связи $count ч назад',
      few: 'был на связи $count ч назад',
      one: 'был на связи $count ч назад',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'был на связи $count д назад',
      many: 'был на связи $count д назад',
      few: 'был на связи $count д назад',
      one: 'был на связи $count д назад',
    );
    return '$_temp0';
  }

  @override
  String get devicesNotSeen => 'ещё не был на связи';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count устройства',
      many: '$count устройств',
      few: '$count устройства',
      one: '$count устройство',
    );
    return '$_temp0';
  }

  @override
  String get devicesThisDevice => 'Это устройство';

  @override
  String get devicesOthers => 'Связанное устройство';

  @override
  String get devicesEmpty =>
      'Восстановите этот кошелёк на другом устройстве, затем свяжите их здесь.';

  @override
  String get devicesLink => 'Связать устройство';

  @override
  String get devicesServers => 'Серверы';

  @override
  String get devicesPause => 'Приостановить синхронизацию';

  @override
  String get devicesPauseHint =>
      'На паузе сообщения ждут на серверах до 7 дней. «Только узел» и «Аварийное отключение» тоже ставят на паузу.';

  @override
  String get devicesHeld => 'Удержанные монеты';

  @override
  String devicesHeldBy(String name) {
    return 'Удержано платежом с $name';
  }

  @override
  String get devicesRelease => 'Освободить';

  @override
  String get devicesReleaseTitle => 'Освободить эти монеты?';

  @override
  String devicesReleaseBody(String name) {
    return '$name может ещё завершать этот платёж. Тогда платёж с этими монетами не пройдёт. Это касается только этого устройства.';
  }

  @override
  String get devicesReleased => 'Освобождено на этом устройстве.';

  @override
  String get devicesRename => 'Переименовать';

  @override
  String get devicesNameLabel => 'Имя';

  @override
  String get devicesRemove => 'Удалить';

  @override
  String devicesRemoveTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String devicesRemoveBody(String name) {
    return '$name больше не получает сообщений этого кошелька; удержанные здесь монеты освобождаются. С фразой восстановления оно по-прежнему может тратить: если оно может быть в чужих руках, переведите средства в новый кошелёк.';
  }

  @override
  String devicesRemoved(String name) {
    return '$name: удалено.';
  }

  @override
  String devicesRemovedBy(String name) {
    return '$name удалило это устройство.';
  }

  @override
  String get devicesRemoving =>
      'Удаление… Другое устройство узнает об этом, когда это будет в сети.';

  @override
  String get devicesMoneyNote =>
      'Связь делится платежами между двумя устройствами. Она не защищает деньги: любое устройство с фразой восстановления может их потратить.';

  @override
  String get devicesUnsupported =>
      'Эта версия пока не умеет связывать устройства.';

  @override
  String get linkLead =>
      'Для этого кошелька на другом устройстве. Сначала восстановите его там из фразы восстановления.';

  @override
  String get linkShow => 'Показать QR';

  @override
  String get linkScan => 'Сканировать QR';

  @override
  String get linkPaste => 'Вставить приглашение';

  @override
  String get linkCopy => 'Копировать приглашение';

  @override
  String get linkCopied => 'Приглашение скопировано.';

  @override
  String linkExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Приглашение действует ещё $count мин.',
      many: 'Приглашение действует ещё $count мин.',
      few: 'Приглашение действует ещё $count мин.',
      one: 'Приглашение действует ещё $count мин.',
    );
    return '$_temp0';
  }

  @override
  String get linkWaiting => 'Ожидание другого устройства…';

  @override
  String linkWaitingFor(String name) {
    return 'Ожидание $name…';
  }

  @override
  String get linkPasteLabel => 'Приглашение';

  @override
  String get linkGo => 'Связать';

  @override
  String get linkPicturesLabel => 'Четыре картинки';

  @override
  String get linkDoneTitle => 'Связано';

  @override
  String linkDone(String name) {
    return 'Связано с $name.';
  }

  @override
  String get linkFailedTitle => 'Не связано';

  @override
  String get linkFailInvalid => 'Это не приглашение устройства.';

  @override
  String get linkFailExpired => 'Срок приглашения истёк. Создайте новое.';

  @override
  String get linkFailNotFound => 'Это приглашение уже использовано.';

  @override
  String get linkFailOwn =>
      'Это приглашение с этого устройства. Отсканируйте его на другом.';

  @override
  String get linkFailOtherWallet =>
      'На этом устройстве другой кошелёк. Для связи нужна та же фраза восстановления.';

  @override
  String get linkFailOtherWalletCode =>
      'Это приглашение от другого кошелька. Для связи нужна та же фраза восстановления.';

  @override
  String get linkFailTooMany => 'Одно устройство уже связано.';

  @override
  String get linkFailUnreachable =>
      'Не удалось связаться с другим устройством.';

  @override
  String get linkTryAgain => 'Попробовать снова';

  @override
  String get linkOffTitle => 'Связанные устройства — экспериментальная функция';

  @override
  String txSentFromDevice(String device) {
    return 'Отправлено с $device';
  }

  @override
  String txDeviceMadeOn(String device) {
    return 'Создано на $device. Подробности пришли с этого устройства; сумма и подтверждения — из блокчейна.';
  }

  @override
  String get txDeviceHeld =>
      'Его монеты удерживаются на этом устройстве, пока блокчейн не покажет платёж или другое устройство его не завершит.';

  @override
  String sendHeldByDevice(String amount, String name) {
    return '$amount EPIC удерживается платежом, который выполняет «$name».';
  }

  @override
  String get offerLinkRestore =>
      'Этот кошелёк есть и на другом устройстве? Свяжите их, чтобы видеть платежи друг друга.';

  @override
  String get offerLinkOtherWallet =>
      'Это ваше другое устройство? Свяжите его, чтобы видеть, кому заплачено, и держать оба в согласии.';

  @override
  String devicesReleasedRow(String name) {
    return 'Освобождено здесь · $name ещё может его отправить';
  }

  @override
  String get deskDevPausedOffline => 'Приостановлено, пока включён «Офлайн».';

  @override
  String get deskDevPausedEpicboxOff =>
      'Приостановлено, пока Epicbox выключен.';

  @override
  String deskDevHeldAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskDevRenameThis => 'Переименовать этот компьютер';

  @override
  String deskDevRenameDevice(String name) {
    return 'Переименовать: $name';
  }

  @override
  String get deskDevPasteLead =>
      'Вставьте код, который показывает другое устройство.';

  @override
  String get deskDevMakingCode => 'Создание кода…';

  @override
  String get deskDevConnecting => 'Подключение…';

  @override
  String get deskDevTheOther => 'Другое устройство';

  @override
  String get deskDevOfferReceived =>
      'Это ваше другое устройство? Свяжите его, чтобы видеть, от кого оно, и держать оба в согласии.';

  @override
  String devicesEndCancelled(String name) {
    return 'Отменено на $name';
  }

  @override
  String devicesEndFailed(String name) {
    return 'Не удалось на $name';
  }

  @override
  String devicesEndExpired(String name) {
    return 'Истекло на $name';
  }

  @override
  String devicesEndLineCancelled(String name) {
    return 'Платёж отменён на $name. Его монеты снова свободны.';
  }

  @override
  String devicesEndLineExpired(String name) {
    return 'Платёж не завершён вовремя на $name. Его монеты снова свободны.';
  }

  @override
  String devicesWhyNotDelivered(String name) {
    return 'Платёж не удалось доставить получателю с $name. Его монеты снова свободны.';
  }

  @override
  String get devicesWhyRefused =>
      'Сервер получателя отклонил его. Его монеты снова свободны.';

  @override
  String get devicesWhyInputsSpent => 'Его монеты уже были потрачены.';

  @override
  String devicesWhyOther(String name) {
    return 'Платёж не удалось завершить на $name. Его монеты снова свободны.';
  }

  @override
  String devicesStatusInfo(String name) {
    return 'Этот статус сообщило устройство $name. Окончательное состояние определяет блокчейн.';
  }

  @override
  String get syncHelpOtherDevice => 'Другое устройство';

  @override
  String get syncHelpServer => 'Сервер';

  @override
  String get syncHelpChain => 'Блокчейн';

  @override
  String get syncHelpStep1 => 'Это устройство начинает платёж.';

  @override
  String syncHelpStep2(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Зашифрованное сообщение идёт на оба сервера. Прочитать его могут только устройства.',
      many: 'Зашифрованное сообщение идёт на оба сервера. Прочитать его могут только устройства.',
      few: 'Зашифрованное сообщение идёт на оба сервера. Прочитать его могут только устройства.',
      one: 'Зашифрованное сообщение идёт через сервер. Прочитать его могут только устройства.',
    );
    return '$_temp0';
  }

  @override
  String get syncHelpStep3 =>
      'Другое устройство удерживает эти монеты и показывает платёж.';

  @override
  String get syncHelpStep4 =>
      'Блокчейн подтверждает. Он решает окончательное состояние.';

  @override
  String get syncHelpDiagram =>
      'Как работает синхронизация: это устройство начинает платёж; зашифрованное сообщение идёт через сервер на другое устройство, которое удерживает эти монеты; блокчейн подтверждает.';

  @override
  String get syncHelpStatus => 'Текущее состояние';

  @override
  String get syncHelpPaused => 'Синхронизация приостановлена';

  @override
  String get syncHelpAnswering => 'Отвечает';

  @override
  String get syncHelpNotAnswering => 'Не отвечает';

  @override
  String get syncHelpNotChecked => 'Не проверен';

  @override
  String get deskSetAdvConfirmations => 'Подтверждения';

  @override
  String deskSetAdvConfirmationsHint(int byDefault, int min, int max) {
    return 'Сколько блоков полученный платёж ждёт, прежде чем его выходы можно тратить. По умолчанию $byDefault; от $min до $max.';
  }

  @override
  String get deskSetAdvConfirmationsDefault => 'По умолчанию';

  @override
  String deskSetAdvConfirmationsReset(int count) {
    return 'Сбросить до $count';
  }

  @override
  String get deskSetAdvConfirmationsFewer => 'Меньше подтверждений';

  @override
  String get deskSetAdvConfirmationsMore => 'Больше подтверждений';

  @override
  String deskSetAdvConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подтверждения',
      many: '$count подтверждений',
      few: '$count подтверждения',
      one: '$count подтверждение',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAdvConfirmationsLowNote =>
      'Меньше подтверждений — быстрее, но менее надёжно.';

  @override
  String get deskSetAdvConfirmationsNotSaved => 'Подтверждения не изменены';

  @override
  String get deskSetPeersFirstSeenHint =>
      'Когда это приложение впервые увидело пир подключённым за этот сеанс.';

  @override
  String deskAppFirstScanProgress(int percent) {
    return 'Сканирование блокчейна · $percent %';
  }

  @override
  String deskAppFirstScanFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $countString выхода',
      many: 'Найдено $countString выходов',
      few: 'Найдено $countString выхода',
      one: 'Найден $countString выход',
    );
    return '$_temp0';
  }

  @override
  String get deskAppFirstScanShowLog => 'Показать журнал';

  @override
  String get deskAppFirstScanHideLog => 'Скрыть журнал';

  @override
  String deskNodeDurationDh(int days, int hours) {
    return '$days д $hours ч';
  }

  @override
  String deskNodeDurationH(int hours) {
    return '$hours ч';
  }

  @override
  String deskInvPayerAgoHoursOnly(int hours) {
    return '$hours ч';
  }

  @override
  String get slPlainHttpTitle => 'Использовать этот узел без шифрования?';

  @override
  String slPlainHttpBody(String host) {
    return '$host относится к общему диапазону адресов: это ваш tailnet (Tailscale) или сеть вашего интернет-провайдера. Кошелёк обращается к этому узлу по незашифрованному http, поэтому любой в этой сети может прочитать, что кошелёк у него запрашивает. Добавляйте его, только если этот адрес — ваш tailnet.';
  }

  @override
  String get slPlainHttpUse => 'Использовать узел';

  @override
  String get slRefusedLocal =>
      'Не выбран: другие кошельки не могут достучаться до сервера с локальным или частным адресом.';

  @override
  String get slRefusedOnion =>
      'Не выбран: onion-сервер работает только при включённом Tor.';

  @override
  String get slRefusedOnionNoTor =>
      'Не выбран: эта версия не может подключиться к этому серверу.';

  @override
  String get deskOwnAccessOnPlain =>
      'Добавлен · передаётся узлу без шифрования (http), виден в этой сети';

  @override
  String get sasNotFromCamera =>
      'Их код пришёл сообщением, а не с вашей камеры. Если их кошелёк не сканировал ваш код с этого экрана, эти слова не доказывают, кто его отправил, поэтому подтверждения здесь нет: оставьте связь без проверки или свяжитесь через приглашение.';

  @override
  String get slSwitchFirst => 'Сначала переключитесь';

  @override
  String get contactPaymentsNone => 'Платежей с этим контактом пока нет.';

  @override
  String contactPaymentsWith(String name) {
    return 'Платежи с контактом «$name»';
  }

  @override
  String get contactPaymentsAll => 'Все платежи';

  @override
  String receiveEpicboxNotConnected(String server) {
    return 'Нет подключения · $server';
  }

  @override
  String restoreWordsAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Все $count слова верные.',
      many: 'Все $count слов верные.',
      few: 'Все $count слова верные.',
      one: '$count слово верное.',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова нет в списке.',
      many: '$count слов нет в списке.',
      few: '$count слов нет в списке.',
      one: '$count слова нет в списке.',
    );
    return '$_temp0';
  }

  @override
  String pairInvitedAt(String clock) {
    return 'Приглашение отправлено в $clock';
  }

  @override
  String get pairInvitedYesterday => 'Приглашение отправлено вчера';

  @override
  String pairInvitedOn(String day) {
    return 'Приглашение отправлено $day';
  }

  @override
  String get deskActNoneUnderFilter => 'Под этим фильтром ничего нет';

  @override
  String get deskKitMethodConnected => 'Подключено';

  @override
  String get deskOvSendWaitsNode =>
      'Отправка станет доступна, когда узел ответит.';

  @override
  String get deskSetRescanRecheck => 'Сверить';

  @override
  String get deskSetRescanRecheckAgain => 'Сверить снова';

  @override
  String get deskSetRescanFromDate => 'С даты';

  @override
  String get deskSetRescanPickDate => 'Выбрать дату';

  @override
  String get deskSetRescanPickDateFirst => 'Сначала выберите дату.';

  @override
  String contactsImportAddsAddress(String name, String method, String address) {
    return '$name получает адрес $method: $address';
  }

  @override
  String get netStatusTurnOnHint =>
      'Выключено. Включите в «Настройки › Транзакции».';

  @override
  String get netStatusTurnOnHintPrivacy =>
      'Выключено. Включите в «Настройки › Приватность и сеть».';

  @override
  String get netStatusTurnOnHintNet =>
      'Выключено. Включите в «Настройки › Сеть и приватность».';

  @override
  String get deskBarTurnOnHint =>
      'Выключено. Включите в «Настройки › Транзакции».';

  @override
  String get deskErrMacKeychain =>
      'macOS не разрешила приложению прочитать его сохранённые данные в связке ключей. Закройте BT Wallet и откройте снова; когда macOS спросит, введите пароль, которым вы разблокируете Mac, и выберите «Всегда разрешать».';

  @override
  String get deskUpdOpenDmg => 'Открыть образ диска';

  @override
  String get deskUpdDmgHint =>
      'Приложение закроется и откроется образ диска: перетащите BT Wallet в «Программы» и замените старую версию. Epic Cash Desktop, если он там есть, переместите в Корзину.';

  @override
  String get balanceSheetTitle => 'Балансы';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count в ожидании',
      many: '$count в ожидании',
      few: '$count в ожидании',
      one: '$count в ожидании',
    );
    return '$_temp0';
  }

  @override
  String get connectionsSheetTitle => 'Подключения';

  @override
  String settingsFileSyntaxError(String file, int line) {
    return '$file, строка $line: строку не удаётся прочитать. Действуют последние верные настройки.';
  }

  @override
  String settingsFileNotText(String file, int line) {
    return '$file, строка $line: это не текст в кавычках. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotNumber(String file, int line) {
    return '$file, строка $line: это не целое число. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotSwitch(String file, int line) {
    return '$file, строка $line: это не true и не false. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotList(String file, int line) {
    return '$file, строка $line: это не список. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotNodeAddress(String file, int line) {
    return '$file, строка $line: это не адрес узла. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotEpicboxServer(String file, int line) {
    return '$file, строка $line: это не сервер Epicbox. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotHostName(String file, int line) {
    return '$file, строка $line: это не имя хоста. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotWebAddress(String file, int line) {
    return '$file, строка $line: это не веб-адрес. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotOnion(String file, int line) {
    return '$file, строка $line: это не onion-адрес. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotPort(String file, int line) {
    return '$file, строка $line: это не номер порта. Действует последнее верное значение.';
  }

  @override
  String settingsFileNotEpicboxAddress(String file, int line) {
    return '$file, строка $line: это не адрес Epicbox. Действует последнее верное значение.';
  }

  @override
  String settingsFileUnknownKey(String file, int line, String key) {
    return '$file, строка $line: неизвестный ключ $key, пропущен.';
  }

  @override
  String settingsFileConflict(String file, String key) {
    return '$file изменили одновременно с приложением; его значение $key сохранено.';
  }

  @override
  String settingsFileBrokenSaved(String file, String backup) {
    return 'В $file были ошибки. Файл сохранён как $backup и записан заново.';
  }

  @override
  String settingsFileRecreated(String file) {
    return 'Файл $file отсутствовал и записан заново.';
  }

  @override
  String settingsFileWriteFailed(String file) {
    return 'Не удалось записать $file. Изменение действует до закрытия приложения.';
  }

  @override
  String settingsFileReadFailed(String file) {
    return 'Не удалось прочитать $file. Действуют встроенные настройки.';
  }

  @override
  String get deskKitReachTorOff =>
      'Проверка работает только с выключенным Tor.';

  @override
  String get deskSetBackupServersTitle =>
      'Использовать серверы из этого файла?';

  @override
  String get deskSetBackupServersBody =>
      'Его списки узлов и серверов Epicbox отличаются от списков этого компьютера. Все кошельки здесь используют одни и те же списки.';

  @override
  String get deskSetBackupServersKeep => 'Этого компьютера';

  @override
  String get deskSetBackupServersUse => 'Из файла';

  @override
  String get deskSlNoNodeTitle => 'Узел не задан';

  @override
  String get deskSlNoNodeText =>
      'Список узлов пуст. Добавьте узел, чтобы проверять баланс и отправлять.';

  @override
  String get deskSlNoEpicboxTitle => 'Сервер Epicbox не задан';

  @override
  String get deskSlNoEpicboxText =>
      'Список серверов Epicbox пуст. Добавьте сервер, чтобы получить адрес Epicbox.';

  @override
  String get devicesOneOnly =>
      'Можно связать одно устройство. Чтобы связать другое, сначала удалите его.';

  @override
  String txReceivedOnDevice(String device) {
    return 'Получено на $device';
  }

  @override
  String txSpokenReceivedOnDevice(String device, String amount) {
    return 'Получено на $device, $amount';
  }

  @override
  String txDetailsDeviceIn(String device) {
    return 'Эти монеты получило устройство $device, связанное с этим кошельком.';
  }

  @override
  String get deskOnbNodeAdvanced => 'Дополнительно';

  @override
  String deskOnbNodePortsSub(String api, String p2p) {
    return 'API $api · P2P $p2p';
  }

  @override
  String get deskOnbNodeApiPort => 'Порт API';

  @override
  String get deskOnbNodeP2pPort => 'Порт P2P';

  @override
  String get deskOnbNodePortsWhy =>
      'Нужно только если другой узел на этом компьютере или в сети использует эти порты.';

  @override
  String deskOnbNodePortRange(String min, String max) {
    return 'Число от $min до $max.';
  }

  @override
  String get deskOnbNodePortsSame => 'Порты должны различаться.';

  @override
  String deskOnbNodePortTaken(String port, String next) {
    return 'Порт $port занят другой программой. $next свободен.';
  }

  @override
  String deskOnbNodePortUse(String port) {
    return 'Использовать $port';
  }

  @override
  String get deskSetLnodePorts => 'Порты';

  @override
  String get deskSetLnodePortsTitle => 'Порты узла';

  @override
  String get deskSetLnodePortsDesc => 'Порты, которые слушает встроенный узел.';

  @override
  String get deskSetLnodePortsRestart =>
      'Узел перезапустится с новыми портами.';

  @override
  String get deskSetLnodePortsSaved => 'Порты сохранены';

  @override
  String get deskSetLnodePortsRestarting => 'Узел перезапускается.';

  @override
  String get deskSetLnodePortsNotSaved => 'Порты не сохранены';

  @override
  String get deskKitInfoLabel => 'Подробнее';

  @override
  String get advModeNodeOnly => 'Только узел';

  @override
  String get advModeKillSwitch => 'Аварийное отключение';

  @override
  String get advModeStandardHintHere =>
      'Подключается напрямую. Включите Tor ниже, чтобы подключаться через Tor.';

  @override
  String get advModeStandardHintNoTor =>
      'Подключается напрямую к узлу и сервисам, которыми вы пользуетесь.';

  @override
  String get advModeTorOnlyHint =>
      'Всё идёт через Tor. Ничего не подключается, пока Tor не готов.';

  @override
  String get advModeNodeOnlyHint =>
      'Подключается только используемый узел. «Напрямую · QR» и «Напрямую · Файл» работают.';

  @override
  String get advModeKillSwitchHint =>
      'Ничего не подключается. Кошелёк работает офлайн с последним известным балансом, а платежи идут файлом или QR-кодом.';

  @override
  String advModeConfirmTitle(String mode) {
    return 'Переключить на «$mode»?';
  }

  @override
  String advModeConfirmBody(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count платежа ждут получателя через Epicbox или «Ссылку». Они приостанавливаются и продолжатся, когда вы выйдете из режима «$mode». Ничто не отменяется.',
      many:
          '$count платежей ждут получателя через Epicbox или «Ссылку». Они приостанавливаются и продолжатся, когда вы выйдете из режима «$mode». Ничто не отменяется.',
      few:
          '$count платежа ждут получателя через Epicbox или «Ссылку». Они приостанавливаются и продолжатся, когда вы выйдете из режима «$mode». Ничто не отменяется.',
      one:
          '$count платёж ждёт получателя через Epicbox или «Ссылку». Он приостанавливается и продолжится, когда вы выйдете из режима «$mode». Ничто не отменяется.',
    );
    return '$_temp0';
  }

  @override
  String get advModeConfirmSwitch => 'Переключить';

  @override
  String netMarkSemantics(String mode) {
    return 'Режим сети: $mode. Открывает раздел «Сеть».';
  }

  @override
  String netMarkSemanticsDesk(String mode) {
    return 'Режим сети: $mode. Показывает, что он делает.';
  }

  @override
  String get netMarkLineTorOnly => 'Каждое соединение идёт через Tor.';

  @override
  String get netMarkLineTorWaiting =>
      'Ожидание Tor. Пока он не готов, ничего не подключается.';

  @override
  String get netMarkLineNodeOnly =>
      'Только используемый узел. Epicbox, Ссылка, обновления и курс выключены.';

  @override
  String get netMarkLineKillSwitch =>
      'Ничего не подключается. Баланс и история — последние известные.';

  @override
  String get netMarkChange => 'Изменить';

  @override
  String statusOffByMode(String mode) {
    return 'Выключено ($mode)';
  }

  @override
  String get statusOffByModeDetail =>
      'Выключено режимом сети. Изменить: «Настройки» › «Дополнительно» › «Сеть».';

  @override
  String get statusOffByModeDetailNet =>
      'Выключено режимом сети. Изменить: «Настройки» › «Сеть и приватность».';

  @override
  String get netBlockEpicboxNodeOnly =>
      'Включён режим «Только узел»: Epicbox выключен. «Напрямую · Оплата по QR» и «Напрямую · Передача файла» работают.';

  @override
  String get netBlockLinkNodeOnly =>
      'Включён режим «Только узел»: «Ссылка» выключена. «Напрямую · Оплата по QR» и «Напрямую · Передача файла» работают.';

  @override
  String get netBlockSendKillSwitch =>
      'Включено «Аварийное отключение»: ничего не подключается. «Напрямую · Оплата по QR» и «Напрямую · Передача файла» работают.';

  @override
  String get netBlockNodeOnly => 'Выключено в режиме «Только узел».';

  @override
  String get netBlockKillSwitch =>
      'Выключено при «Аварийном отключении»: ничего не подключается.';

  @override
  String get netBlockWaitingForTorLong =>
      'Ожидание Tor. Пока он не готов, ничего не подключается.';

  @override
  String receiveEpicboxOffMode(String mode) {
    return 'Epicbox выключен в режиме «$mode».';
  }

  @override
  String receiveEpicboxOffModeBody(String mode) {
    return 'Платежи на этот адрес ждут на сервере Epicbox и поступят, когда вы выйдете из режима «$mode».';
  }

  @override
  String receiveLinkOffMode(String mode) {
    return 'Приём по «Ссылке» выключен в режиме «$mode».';
  }

  @override
  String updatesOffMode(String mode) {
    return 'Проверка обновлений выключена в режиме «$mode».';
  }

  @override
  String reportOffMode(String mode) {
    return 'Выключено в режиме «$mode». Сохраните отчёт в файл.';
  }

  @override
  String get recheckOffKill =>
      'Для сверки баланса нужен узел. Выключено при «Аварийном отключении».';

  @override
  String get postFinishedOffKill =>
      'Выключено при «Аварийном отключении»: здесь ничего не подключается.';

  @override
  String get postFinishedOffTor => 'Ожидание Tor. Для отправки нужен узел.';

  @override
  String get browserOffTorOnly => 'Откроется вне Tor. Лучше скопируйте ссылку.';

  @override
  String browserOffMode(String mode) {
    return 'Выключено в режиме «$mode». Лучше скопируйте ссылку.';
  }

  @override
  String get netChangeLink => 'Изменить';

  @override
  String get lastKnownCaption => 'Последние данные';

  @override
  String get lastKnownList => 'Последние данные · Аварийное отключение';

  @override
  String lastKnownConfirming(String text) {
    return '$text · последние данные';
  }

  @override
  String get coldNeedsOnlineCheck =>
      'Сначала нужна одна сверка баланса онлайн.';

  @override
  String get finalizeNotPostedTitle => 'Готов, не отправлен';

  @override
  String finalizeNotPostedBody(String amount) {
    return '$amount: платёж готов. Включено «Аварийное отключение», поэтому этот телефон не может его отправить: сохраните его или покажите как QR-код для устройства, которое в сети.';
  }

  @override
  String get finishedSaveFile => 'Сохранить файл';

  @override
  String get finishedShowQr => 'Показать QR';

  @override
  String finishedSaved(String name) {
    return 'Сохранено: $name';
  }

  @override
  String get finishedQrTitle => 'Готовый платёж';

  @override
  String get finishedUnavailable =>
      'Эта версия пока не умеет сохранять готовый платёж.';

  @override
  String get finishedFailed => 'Не удалось прочитать готовый платёж.';

  @override
  String get txPostElsewhere => 'Отправить с другого устройства';

  @override
  String get txPostElsewhereKill =>
      'Завершён при «Аварийном отключении». Сохраните его или покажите QR-код, затем отправьте с устройства, которое в сети.';

  @override
  String get txPostElsewhereAfter =>
      'Завершён при «Аварийном отключении», в блокчейне пока нет. Отправьте его отсюда или дождитесь устройства, которое его отправило.';

  @override
  String get txPostNow => 'Отправить сейчас';

  @override
  String get txModeFinishedKill => 'Завершён при «Аварийном отключении»';

  @override
  String get txModeRow => 'Режим';

  @override
  String get postFinishedTitle => 'Отправить готовый платёж';

  @override
  String get postFinishedIntro =>
      'Отправьте платёж, который другое устройство завершило при «Аварийном отключении».';

  @override
  String get postFinishedIntroOffline =>
      'Отправьте платёж, который другое устройство завершило без сети.';

  @override
  String get postFinishedOpenFile => 'Открыть файл';

  @override
  String get postFinishedScanQr => 'Сканировать QR';

  @override
  String get postFinishedPaste => 'Вставить';

  @override
  String get postFinishedChooseFile => 'Выбрать файл';

  @override
  String get postFinishedSummary => 'Готовый платёж';

  @override
  String get postFinishedAmount => 'Сумма';

  @override
  String get postFinishedFee => 'Комиссия';

  @override
  String get postFinishedKernel => 'Ядро';

  @override
  String get postFinishedNote =>
      'Отправка выводит платёж в сеть. Кошелёк, который его создал, покажет его как подтверждаемый, когда увидит в блокчейне.';

  @override
  String get postFinishedPost => 'Отправить';

  @override
  String get postFinishedPosting => 'Отправка…';

  @override
  String get postFinishedDone => 'Отправлено в сеть';

  @override
  String get postFinishedDoneBody =>
      'Узел его принял. Кошелёк, который его создал, покажет его как подтверждаемый, когда увидит в блокчейне.';

  @override
  String get postFinishedNotFinished =>
      'Это не готовый платёж. Откройте файл, сохранённый в разделе «Отправить с другого устройства», или отсканируйте его QR-код.';

  @override
  String get postFinishedFailed => 'Узел его не принял. Попробуйте ещё раз.';

  @override
  String get postFinishedUnreachable => 'Узел не отвечает.';

  @override
  String get postFinishedDeskRow => 'Отправить готовый платёж';

  @override
  String get postFinishedDeskRowText =>
      'Отправьте платёж, который другое устройство завершило при «Аварийном отключении».';

  @override
  String get postFinishedOpen => 'Открыть';

  @override
  String deskFinNotPostedKillBody(String amount) {
    return '$amount: платёж готов. Включено «Аварийное отключение», поэтому этот компьютер не может его отправить. Сохраните его или скопируйте, затем отправьте с устройства, которое в сети: «Получить» › «Файлы транзакций» › «Отправить готовый платёж».';
  }

  @override
  String netMarkRowLabel(String mode) {
    return 'Режим сети: $mode';
  }

  @override
  String get qrStatusFinishedHidden => 'Скрыт';

  @override
  String get qrStatusFinishedShowing =>
      'Ждём, пока устройство в сети отсканирует.';

  @override
  String qrShowSubFinished(String amount) {
    return '$amount, готов';
  }

  @override
  String qrSemanticsFinished(String state) {
    return 'QR-код готового платежа, $state';
  }

  @override
  String get qrHiddenBodyFinished =>
      'Покажите его устройству, которое в сети. Оно отправит платёж; ключ не нужен.';

  @override
  String get qrScanFinished => 'Сканировать готовый платёж';

  @override
  String get qrScanNotFinished => 'Этот код — не готовый платёж.';

  @override
  String get qrScanAimFinished =>
      'Наведите камеру на код на другом устройстве.';

  @override
  String get deskRailOpenNetwork => 'Открыть настройки сети';

  @override
  String get cancelFeeLine => 'Стоит обычную сетевую комиссию.';

  @override
  String get cancelForSure => 'Отменить наверняка';

  @override
  String get cancelStopWaiting => 'Перестать ждать';

  @override
  String get cancelStopWaitingLine => 'Бесплатно. Платёж ещё может пройти.';

  @override
  String get cancelMoveBack => 'Вернуть монеты';

  @override
  String cancelMoveBackFee(String fee) {
    return 'Вернуть монеты · комиссия $fee';
  }

  @override
  String get cancelUnlockOpen =>
      'Разблокировать монеты, платёж остаётся открытым';

  @override
  String get cancelCompareMoveBack =>
      'Вернуть монеты: наверняка, за сетевую комиссию.';

  @override
  String get cancelCompareUnlock =>
      'Разблокировать монеты: бесплатно, платёж ещё может пройти.';

  @override
  String get cancelChoicesTitle => 'Два способа отменить';

  @override
  String get cancelChoicesWhy =>
      'Отменить наверняка сначала переводит монеты обратно на этот кошелёк за обычную сетевую комиссию. После этого старый платёж уже никогда не пройдёт; это надёжный способ.\n\nПерестать ждать бесплатно и ничего не переводит. Монеты снова можно тратить, а платёж остаётся как есть. Если другая сторона всё же завершит его позже, он пройдёт и будет показан как оплаченный; если нет, ничего не произойдёт.';

  @override
  String get cancelStoppedWaitingTitle => 'Ожидание прекращено';

  @override
  String get cancelStoppedWaitingText =>
      'Монеты снова можно тратить. Платёж ещё может пройти; если пройдёт, он будет показан как оплаченный.';

  @override
  String get txDetailsStoppedWaiting =>
      'Ожидание прекращено. Монеты снова можно тратить. Платёж ещё может пройти; если пройдёт, он будет показан как оплаченный.';

  @override
  String get errorPaymentCancelledCoinsMoved =>
      'Этот платёж был отменён, а его монеты уже переведены. Он больше не может пройти.';

  @override
  String get errorPaymentAlreadyWentThrough =>
      'Монеты не удалось перевести обратно: сам платёж уже прошёл. Он показан как оплаченный.';

  @override
  String get errorPinKeyLost =>
      'PIN-код больше не открывает этот кошелёк. Ваши монеты в безопасности: нажмите «Забыли PIN-код?» и восстановите кошелёк по фразе восстановления.';

  @override
  String get errorKeystoreRefused =>
      'Телефон не выдал ключ кошелька. Разблокируйте телефон его собственным PIN-кодом или отпечатком пальца и повторите попытку.';

  @override
  String get unlockTryAgain => 'Повторить';

  @override
  String get settingsUsePassphrase => 'Использовать пароль';

  @override
  String get settingsChangePassphrase => 'Сменить пароль';

  @override
  String get passphraseLabel => 'Пароль';

  @override
  String passphraseChoose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выберите пароль не короче $count символа, не только из цифр',
      many: 'Выберите пароль не короче $count символов, не только из цифр',
      few: 'Выберите пароль не короче $count символов, не только из цифр',
      one: 'Выберите пароль не короче $count символа, не только из цифр',
    );
    return '$_temp0';
  }

  @override
  String get passphraseRepeat => 'Повторите пароль';

  @override
  String get passphraseMismatch => 'Пароли не совпадают';

  @override
  String get passphraseSet => 'Пароль установлен';

  @override
  String get passphraseSetBiometricsOff =>
      'Пароль установлен. Включите биометрическую разблокировку снова ниже.';

  @override
  String get passphraseForgot => 'Забыли пароль?';

  @override
  String get passphrasePromptTitle => 'Введите пароль';

  @override
  String get passphraseEnterCurrent => 'Введите текущий пароль';

  @override
  String get passphraseCurrentLabel => 'Текущий пароль';

  @override
  String get passphraseChooseTitle => 'Выберите пароль';

  @override
  String passphraseRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не короче $count символа и не только из цифр.',
      many: 'Не короче $count символов и не только из цифр.',
      few: 'Не короче $count символов и не только из цифр.',
      one: 'Не короче $count символа и не только из цифр.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseUsePinInstead => 'Ввести PIN вместо пароля';

  @override
  String get passphraseUsePassphraseInstead => 'Ввести пароль вместо PIN';

  @override
  String get invoicePassphraseReason =>
      'Введите пароль, чтобы оплатить этот счёт.';

  @override
  String get restoreReplacePassphraseReason =>
      'Введите пароль, чтобы заменить этот кошелёк. Восстановленный кошелёк сохранит этот пароль.';

  @override
  String get backupPassphraseReason =>
      'Введите пароль, чтобы показать фразу восстановления.';

  @override
  String sendQrPassphraseReason(String amount) {
    return 'Введите пароль, чтобы создать QR платежа на $amount.';
  }

  @override
  String get settingsBiometricsPassphraseReason =>
      'Введите пароль, чтобы включить биометрическую разблокировку.';

  @override
  String get settingsDeletePassphraseReason =>
      'Введите пароль, чтобы удалить этот кошелёк.';

  @override
  String sendPassphraseReason(String amount) {
    return 'Введите пароль, чтобы отправить $amount.';
  }

  @override
  String sendFilePassphraseReason(String amount) {
    return 'Введите пароль, чтобы создать файл транзакции на $amount.';
  }

  @override
  String get passphraseSetTitle => 'Задать пароль';

  @override
  String get deskSetReportFullDetails => 'Приложить все подробности';

  @override
  String get deskSetReportPartFullDetails => 'Полные детали';

  @override
  String get deskSetReportFullDetailsInfo =>
      'Адреса и суммы отправляются целиком, а не сокращёнными. Фразы восстановления, ключи и пароли не отправляются никогда.';

  @override
  String get deskOutNoteWaitingRecipient => 'ждёт получателя';

  @override
  String get deskSlotNotPosted => 'Платёж не в сети';

  @override
  String get txOtherWalletMore => 'Платежи другого кошелька';

  @override
  String get finalizeNotPostedHelp => 'Оплата при «Аварийном отключении»';

  @override
  String get deskActSearchHintFull => 'Заметка, контакт, адрес или сумма';

  @override
  String get deskOutFilterWaiting => 'Ожидают';

  @override
  String deskRecvHeaderTip(String methods) {
    return 'Приём: $methods';
  }

  @override
  String deskSendHintNeedsMethod(String method) {
    return 'Для проверки нужен $method';
  }

  @override
  String get deskSetAboutVersionLabel => 'Версия';

  @override
  String get deskSetAboutNodeLabel => 'Узел';

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
      other: 'Подтверждено, $confirmationsString подтверждения · блок $block.',
      many: 'Подтверждено, $confirmationsString подтверждений · блок $block.',
      few: 'Подтверждено, $confirmationsString подтверждения · блок $block.',
      one: 'Подтверждено, $confirmationsString подтверждение · блок $block.',
    );
    return '$_temp0';
  }

  @override
  String deskKitNoAnswerSince(String time) {
    return 'Нет ответа с $time';
  }

  @override
  String get deskKitMoreInHelp => 'Подробнее в справке';

  @override
  String get homeReceiveEpicButton => 'Получить EPIC';

  @override
  String txDeviceStatusMadeOn(String device) {
    return 'Создан на $device.';
  }

  @override
  String txDeviceStatusHeld(String device) {
    return 'Создан на $device. Средства удерживаются здесь, пока платёж не появится в цепочке.';
  }

  @override
  String get deskSendEpicboxNodeOnly =>
      'Включён режим «Только узел»: Epicbox выключен. «Напрямую · Передача файла» работает.';

  @override
  String deskSendEpicboxNodeOnlyTab(String method) {
    return 'Включён режим «Только узел»: Epicbox выключен. «$method» работает.';
  }

  @override
  String get deskSendLinkNodeOnly =>
      'Включён режим «Только узел»: «Ссылка» выключена. «Напрямую · Передача файла» работает.';

  @override
  String deskSendLinkNodeOnlyTab(String method) {
    return 'Включён режим «Только узел»: «Ссылка» выключена. «$method» работает.';
  }

  @override
  String get deskSendKillSwitch =>
      'Включено «Аварийное отключение»: ничего не подключается. «Напрямую · Передача файла» работает.';

  @override
  String deskSendKillSwitchTab(String method) {
    return 'Включено «Аварийное отключение»: ничего не подключается. «$method» работает.';
  }

  @override
  String get levelOneTitle => 'Только отправка и получение';

  @override
  String get levelOneLine => 'Деньги пришли, деньги ушли. Учиться нечему.';

  @override
  String get levelTwoTitle =>
      'Не слишком технично, но говорите, что происходит';

  @override
  String get levelTwoLine => 'Простыми словами о том, что делает кошелёк.';

  @override
  String get levelThreeTitle => 'Хочу изучить всё';

  @override
  String get levelThreeLine =>
      'Каждый переключатель, каждое число. Осторожно с настройками.';

  @override
  String get levelUndercoverTitle => 'Только Tor';

  @override
  String get levelFooter =>
      'Изменить можно в любой момент: Настройки › Дополнительно.';

  @override
  String get levelRowTitle => 'Вид кошелька';

  @override
  String get levelChangeTitle => 'Сменить вид';

  @override
  String get lvPickStopOne => 'Мелко';

  @override
  String get lvPickStopTwo => 'Глубже';

  @override
  String get lvPickStopThree => 'В самую глубь';

  @override
  String get lvPickLineOne =>
      'Отправили, получили, готово. Об остальном позаботится кошелёк.';

  @override
  String get lvPickLineTwo => 'Видно, что он делает, простыми словами.';

  @override
  String get lvPickLineThree => 'Каждый переключатель, каждая цифра. Всё ваше.';

  @override
  String get lvPickNone => 'Выберите уровень';

  @override
  String get lvPickNoneLine => 'Превью следует за переключателем.';

  @override
  String get lvPickDepth => 'Вид';

  @override
  String get lvPickPreview =>
      'Превью главного экрана. Чем глубже уровень, тем больше на нём видно.';

  @override
  String get lvPickHelpTitle => 'На что это влияет';

  @override
  String get lvPickHelpText =>
      'Только то, сколько показывает приложение. В любом виде отправка и получение одинаковы: те же ключи и те же монеты.';

  @override
  String get lvPickUndercoverHelp =>
      'Только Tor, с первого подключения. Каждое подключение идёт через Tor; запуск дольше.\n\nПока ничего не подключалось. То же, что Режим сети › Только Tor; позже можно выключить в Настройки › Дополнительно.';

  @override
  String get lvPickUndercoverHelpNet =>
      'Только Tor, с первого подключения. Каждое подключение идёт через Tor; запуск дольше.\n\nПока ничего не подключалось. То же, что Режим соединения › Только Tor; позже можно выключить в Настройки › Сеть и приватность.';

  @override
  String get lvPickUndercover => 'Инкогнито';

  @override
  String get lvPickUndercoverLaterHelp =>
      'Только Tor. Каждое подключение идёт через Tor; запуск дольше. Там, где Tor заблокирован, кошелёк не подключится, пока это не выключить.';

  @override
  String get lvPickTakesEffect => 'Действует сразу.';

  @override
  String get lvPickSaved => 'Вид сохранён';

  @override
  String get lvPickTorTitle => 'Подключение через Tor';

  @override
  String get lvPickTorLead =>
      'Первое подключение через Tor может занять минуту.';

  @override
  String get lvPickTorBusy => 'Строится цепочка…';

  @override
  String get lvPickTorBlocked =>
      'Если у вас Tor заблокирован, кошелёк не подключится, пока не выключить Инкогнито.';

  @override
  String get lvPickTorOff => 'Выключить Инкогнито';

  @override
  String get lvPickTorOffDone => 'Инкогнито выключено. Подключение напрямую.';

  @override
  String get lvPickNetworkOk => 'Сеть OK';

  @override
  String get lvPickEpicboxOk => 'Epicbox OK';

  @override
  String get lvPayArriving => 'Поступает';

  @override
  String lvPayConfirming(int count, int target) {
    return 'Подтверждение $count из $target';
  }

  @override
  String lvPayConfirmingOf(int count, int target) {
    return 'Подтверждение $count из $target';
  }

  @override
  String lvPaySigned(String name) {
    return '$name подписал(а)';
  }

  @override
  String get lvPaySendQrLink => 'Оба телефона рядом? QR-платёж';

  @override
  String get lvPaySendAddressLink => 'Отправить на адрес';

  @override
  String get lvPayOnItsWay => 'В пути';

  @override
  String get lvPayCloseNote =>
      'Можно закрыть. Платёж виден в «Активности», пока не завершится.';

  @override
  String lvPayArrivalFrom(String amount, String name) {
    return '$amount от $name';
  }

  @override
  String get lvPayOpen => 'Открыть';

  @override
  String get lvPayNewToday => 'Новый сегодня';

  @override
  String get lvPayNewAddress => 'Ваш новый адрес';

  @override
  String lvPayServerLine(String name) {
    return 'Сервер Epicbox: $name.';
  }

  @override
  String get lvPayOldAddressLine => 'Тем, у кого старый адрес, нужен новый.';

  @override
  String get lvPayReceiveBack => 'Назад к моему адресу';

  @override
  String lvPayDoneSent(String when) {
    return 'Отправлено. Завершено: $when.';
  }

  @override
  String lvPayDoneReceived(String when) {
    return 'Получено. Завершено: $when.';
  }

  @override
  String get lvPayShowSteps => 'Показать шаги';

  @override
  String get lvPayHideSteps => 'Скрыть шаги';

  @override
  String get lvPayDetails => 'Подробности';

  @override
  String get lvPayStarted => 'Начато';

  @override
  String get lvPayPosted => 'Отправлено в сеть';

  @override
  String get lvPayPaymentId => 'ID платежа';

  @override
  String get lvPayConfirmations => 'Подтверждения';

  @override
  String lvPayOf(int count, int target) {
    return '$count из $target';
  }

  @override
  String get lvPayCopyDetails => 'Скопировать данные';

  @override
  String get lvPayDetailsCopied => 'Данные скопированы';

  @override
  String lvShellStatusTip(String name, String state) {
    return '$name · $state';
  }

  @override
  String get lvShellStateBehind => 'Отстаёт';

  @override
  String get lvShellStateCatchingUp => 'Догоняет';

  @override
  String get lvShellStateConnecting => 'Подключение';

  @override
  String get lvShellOpensDetails => 'Показывает подробности';

  @override
  String get lvShellLatestBlock => 'Последний блок';

  @override
  String get lvShellThisWallet => 'Этот кошелёк';

  @override
  String get lvShellUpToDate => 'Актуален';

  @override
  String get lvShellNotChecked => 'Ещё не проверен';

  @override
  String get lvShellLastChange => 'Последнее изменение';

  @override
  String get lvShellBoxListening => 'Подключено · ждёт платежей';

  @override
  String get lvShellBoxNotReachable => 'Недоступен · продолжает попытки';

  @override
  String get lvShellBoxDownBody =>
      'Платежи вам ждут и придут, когда сервер вернётся. Ничего не меняется, пока вы не переключитесь.';

  @override
  String lvShellOfferReady(String name) {
    return '$name готов';
  }

  @override
  String lvShellOfferBody(String name) {
    return 'При переключении вы получите новый адрес на $name. Всем, у кого ваш старый адрес, нужен новый.';
  }

  @override
  String lvShellSwitchTo(String name) {
    return 'Переключиться на $name';
  }

  @override
  String get lvShellKeepWaiting => 'Подождать';

  @override
  String get lvShellRelayDownTitle => 'Ваш сервер Epicbox недоступен.';

  @override
  String lvShellRelayDownShort(String name) {
    return '$name может заменить его; ваш адрес при этом изменится.';
  }

  @override
  String get lvShellSwitch => 'Переключить';

  @override
  String lvShellSwitchedNotice(String name) {
    return 'Теперь на $name. Ваш новый адрес готов.';
  }

  @override
  String lvShellNowOn(String name) {
    return 'Теперь на $name';
  }

  @override
  String get lvShellSwitchedBody =>
      'Ваш новый адрес готов. Всем, у кого ваш старый адрес, нужен новый.';

  @override
  String get lvShellShowNewAddress => 'Показать новый адрес';

  @override
  String get lvShellServer => 'Сервер';

  @override
  String get lvShellAddress => 'Адрес';

  @override
  String lvShellPairNotice(String name) {
    return '$name хочет связаться с этим кошельком.';
  }

  @override
  String get lvShellSeeRequest => 'Посмотреть запрос';

  @override
  String lvShellQuietArriving(String amount) {
    return '+$amount поступает';
  }

  @override
  String lvShellQuietOnHold(String amount) {
    return '$amount удерживается';
  }

  @override
  String get lvShellLevelCaption =>
      'Более глубокий вид показывает больше. Сохранённые данные не меняются.';

  @override
  String get lvPolPosted => 'Отправлен';

  @override
  String get lvPolInvoiceWaiting => 'Счёт · ждёт вашего одобрения';

  @override
  String lvPolAbout(String name) {
    return 'О $name';
  }

  @override
  String get deskLvStartPreviewLabel =>
      'Превью обзора. Чем глубже уровень, тем больше на нём видно.';

  @override
  String get deskLvStartPreviewCaption =>
      'Ваш обзор в этом виде. Сохранённые данные не меняются.';

  @override
  String get deskLvStartCover => 'Выберите положение, чтобы увидеть превью';

  @override
  String get deskLvStartUndercoverAbout => 'О режиме «Только Tor»';

  @override
  String get deskLvStartHelpShallow =>
      'Мелко · один адрес, без имён серверов, без переключателей.';

  @override
  String get deskLvStartHelpDeeper =>
      'Глубже · тот же кошелёк, плюс что он делает, простыми словами.';

  @override
  String get deskLvStartHelpDeep =>
      'В самую глубь · каждый переключатель, каждая цифра: приложение как сейчас.';

  @override
  String get deskLvStartMiniWallet => 'Основной кошелёк';

  @override
  String get deskLvStartMiniLine => '+12,5 поступает · 25,0 удерживается';

  @override
  String get deskLvStartMiniFresh => 'Свежие с майнинга';

  @override
  String get deskLvStartMiniWaiting => 'Ожидание другой стороны';

  @override
  String get deskLvSendHowTo => 'Как отправить';

  @override
  String get deskLvSendButton => 'Отправить';

  @override
  String deskLvSendButtonAmount(String amount) {
    return 'Отправить $amount EPIC';
  }

  @override
  String deskLvSendButtonTo(String amount, String name) {
    return 'Отправить $amount EPIC — $name';
  }

  @override
  String get deskLvSendNothingLeaves =>
      'Ничего не уходит, пока вы не нажмёте «Отправить». После этого вернуть нельзя.';

  @override
  String get deskLvSendPasswordTitle => 'Ваш пароль';

  @override
  String get deskLvSendConfirm => 'Отправить';

  @override
  String deskLvSendLiveTo(String name) {
    return 'Идёт к $name';
  }

  @override
  String deskLvSendLiveAmountTo(String amount, String name) {
    return '$amount EPIC — $name';
  }

  @override
  String deskLvSendLiveAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskLvSendYourAddress => 'Ваш адрес';

  @override
  String get deskLvSendReady => 'Готов к приёму';

  @override
  String get deskLvSendClosedInfo =>
      'Платежи, отправленные при закрытом кошельке, придут, когда он откроется.';

  @override
  String get deskLvSendPayFiles => 'Файлы платежей';

  @override
  String get deskLvSendSignFile => 'Подписать файл платежа';

  @override
  String get deskLvSendSignFileText =>
      'Откройте файл от отправителя и сохраните свой ответ.';

  @override
  String get deskLvSendFinishFile => 'Завершить файл ответа';

  @override
  String get deskLvSendFinishFileText =>
      'Откройте полученный ответ, чтобы опубликовать платёж.';

  @override
  String get deskLvSendPrevAddress => 'Прежний адрес';

  @override
  String deskLvSendPrevText(String server) {
    return 'Старый адрес был на $server. Всем, у кого он есть, нужен новый.';
  }

  @override
  String get deskLvPayS1Sent =>
      'Слейт S1 отправлен через Epicbox · ожидается S2';

  @override
  String deskLvPayS1On(String relay) {
    return 'S1 на $relay · ожидается S2';
  }

  @override
  String deskLvPayNotOpen(String name) {
    return 'Кошелёк $name ещё не открыт';
  }

  @override
  String deskLvPayWaitingOpen(String name) {
    return 'Ожидание, пока откроется кошелёк $name';
  }

  @override
  String get deskLvPaySenderFinished => 'Отправитель закончил';

  @override
  String get deskLvPayPostedNode => 'Отправлено в узел';

  @override
  String deskLvPayConfirmingComma(int count, int target) {
    return 'Подтверждение, $count из $target';
  }

  @override
  String deskLvPayConfirmationsOf(int count, int target) {
    return 'Подтверждения $count / $target';
  }

  @override
  String get deskLvPayDone => 'Готово';

  @override
  String deskLvPayOnItsWayTo(String name) {
    return 'Идёт к $name';
  }

  @override
  String deskLvPaySendingTo(String name) {
    return 'Отправка: $name';
  }

  @override
  String deskLvPayArrivingFrom(String name) {
    return 'Поступает от $name';
  }

  @override
  String deskLvPayStartedAt(String amount, String time) {
    return '$amount EPIC · начато $time';
  }

  @override
  String deskLvPayHeroArriving(String amount, String name) {
    return '+$amount поступает от $name';
  }

  @override
  String deskLvPayHeroArrivingMany(String amount) {
    return '+$amount поступает';
  }

  @override
  String deskLvPayHeroHold(String amount, String name) {
    return '$amount удерживается, пока $name не подпишет';
  }

  @override
  String deskLvPayHeroHoldMany(String amount) {
    return '$amount удерживается до подписи';
  }

  @override
  String get deskLvPayHeroNothing => 'Пока ничего не поступает.';

  @override
  String get deskLvPayReadyTitle => 'Кошелёк готов.';

  @override
  String get deskLvPayReadyHead => 'Кошелёк готов';

  @override
  String get deskLvPayReadyText =>
      'Поделитесь адресом, чтобы получить первые EPIC.';

  @override
  String get deskLvPayTileConfirming => 'Ещё подтверждается';

  @override
  String get deskLvPayTileMining => 'Свежие с майнинга';

  @override
  String get deskLvPayTileWaiting => 'Ожидание другой стороны';

  @override
  String get deskLvPayTileAwaiting => 'Ждёт ответа';

  @override
  String get deskLvPayTileLocked => 'Отложено для отправок';

  @override
  String get deskLvPayImmatureCasual => 'Свежие с майнинга, пока недоступны';

  @override
  String get deskLvPayKind => 'Платёж';

  @override
  String get deskLvShellNewsTitle => 'Новое: вид кошелька';

  @override
  String get deskLvShellNewsText =>
      'Эта установка показывает всё, как и раньше. «Мелко» и «Глубже» показывают меньше.';

  @override
  String get deskLvShellNewsLook => 'Посмотреть';

  @override
  String get deskLvShellFailover => 'Переключение узла';

  @override
  String get deskLvShellOn => 'Вкл.';

  @override
  String get deskLvShellHeight => 'Высота';

  @override
  String get deskLvShellVersion => 'Версия';

  @override
  String get deskLvShellRecheckHint =>
      'Если сумма выглядит неверно, кошелёк заново читает цепочку.';

  @override
  String get lvShellSwitchServer => 'Сменить сервер';

  @override
  String get lvShellNoOtherServer => 'Других серверов в списке нет.';

  @override
  String get deskLvShellSwitchServer => 'Сменить сервер';

  @override
  String get deskLvShellNoOtherServer => 'В списке нет другого сервера.';

  @override
  String get deskLastSessionFroze =>
      'В прошлый раз приложение перестало отвечать. Отправить журнал?';

  @override
  String get deskLastSessionClosed =>
      'В прошлый раз приложение неожиданно закрылось. Отправить журнал?';

  @override
  String get deskLastSessionSend => 'Отправить';

  @override
  String get deskLastSessionNotNow => 'Не сейчас';

  @override
  String get deskLastSessionReportFroze => 'Приложение перестало отвечать.';

  @override
  String get deskLastSessionReportClosed => 'Приложение неожиданно закрылось.';

  @override
  String get deskLastSessionAttached => 'С журналом последнего сеанса.';

  @override
  String get deskSetPrivUndercoverLine => 'Инкогнито держит Tor включённым.';

  @override
  String get deskSetPrivUndercoverChange => 'Изменить «Инкогнито»';

  @override
  String get deskNodeEtaCalculating => 'Расчёт оставшегося времени…';

  @override
  String deskNodeEtaLeft(String time) {
    return 'осталось около $time';
  }

  @override
  String get deskNodeEtaMinute => 'минуты';

  @override
  String deskNodeEtaMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String deskNodeEtaHours(int hours) {
    return '$hours ч';
  }

  @override
  String deskNodeEtaHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String deskNodeSwitchConnecting(String host) {
    return 'Подключение к $host…';
  }

  @override
  String get deskNodeSwitchStarting => 'Запуск локального узла…';

  @override
  String get deskNodeSwitchStopping => 'Остановка локального узла…';

  @override
  String get deskNodeSwitchStoppingWord => 'Остановка';

  @override
  String get deskOnbFailedTitle => 'Не завершено';

  @override
  String deskOnbRestoreBadWords(String words) {
    return 'Нет в списке слов: $words.';
  }

  @override
  String get deskLvPayOnEpicbox => 'На Epicbox';

  @override
  String get deskRailReceivingInternet => 'Принимает · интернет';

  @override
  String get deskRailReceivingLocal => 'Принимает · локально';

  @override
  String get deskOnbImportFoundLead =>
      'Далее — выбор кошельков для добавления.';

  @override
  String get deskOnbForgotFailedTitle => 'Пароль не изменён';

  @override
  String get deskOnbForgotFailedLead =>
      'Текущий пароль по-прежнему открывает кошелёк.';

  @override
  String get deskSetHelpSupportHead => 'Поддержка';

  @override
  String deskKitPasswordRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count символа или больше',
      many: '$count символов или больше',
      few: '$count символа или больше',
      one: '$count символ или больше',
    );
    return '$_temp0';
  }

  @override
  String trustLineOtherApp(Object name) {
    return 'На последний платёж $name ответило другое приложение-кошелёк.';
  }

  @override
  String trustLineNotHeard(Object name, Object date) {
    return 'От кошелька $name ничего не слышно с $date.';
  }

  @override
  String get mailboxNotAnswered => 'Пока без ответа';

  @override
  String get mailboxNotPickedUp => 'Не забран';

  @override
  String mailboxNeverPickedUp(Object name) {
    return 'Кошелёк $name так и не забрал этот платёж.';
  }

  @override
  String get mailboxResendTitle => 'Отменить и отправить через Epicbox';

  @override
  String mailboxResendBody(Object name) {
    return 'Ожидающий платёж отменяется, и та же сумма уходит на адрес Epicbox $name обычным платежом. В истории остаются две строки.';
  }

  @override
  String get mailboxResendAction => 'Отменить и отправить';

  @override
  String get mailboxKeepWaiting => 'Подождать ещё';

  @override
  String get linkPayeeLead => 'Получатель';

  @override
  String get linkPayeeMid => 'получатель';

  @override
  String get linkResendBody =>
      'Ожидающий платёж будет отменён, и «Отправить» откроется с той же суммой. Проверьте адрес и отправьте снова.';

  @override
  String receiptTellSent(Object name) {
    return 'Сообщить $name, что отправлено';
  }

  @override
  String receiptTellPosted(Object name) {
    return 'Сообщить $name, что платёж ушёл в сеть';
  }

  @override
  String receiptTold(Object name) {
    return 'Уведомление отправлено: $name';
  }

  @override
  String receiptSeesSent(Object name, Object id, Object amount, Object time) {
    return '$name увидит: запрос $id, $amount, отправлено $time. Больше ничего не передаётся: ни адреса, ни ID транзакции.';
  }

  @override
  String receiptSeesPosted(Object name, Object id, Object amount, Object time) {
    return '$name увидит: запрос $id, $amount, в сети с $time. Больше ничего не передаётся: ни адреса, ни ID транзакции.';
  }

  @override
  String receiptNotSent(Object name) {
    return 'Сейчас не удалось сообщить $name. Попробуйте ещё раз.';
  }

  @override
  String get receiptHintTitle => 'Квитанция';

  @override
  String get mailboxResent => 'Отменено и отправлено через Epicbox.';

  @override
  String get torRelayCaption =>
      'Когда Tor включён, подключение к серверу Epicbox идёт через Tor.';

  @override
  String get inviteLinkUnreadable => 'Эту ссылку нельзя открыть.';

  @override
  String inviteLinkNoHandler(String feature) {
    return '«$feature» выключено или недоступно в этом кошельке.';
  }

  @override
  String get linkShowMine => 'Показать мой QR';

  @override
  String get linkPasteAnother => 'Вставить другое приглашение';

  @override
  String linkLinkingWith(String name) {
    return 'Связь с $name…';
  }

  @override
  String linkLinkingSame(String name) {
    return '$name показывает те же четыре.';
  }

  @override
  String linkFailFull(String name) {
    return '$name уже связано с другим устройством. Сначала удалите его на $name.';
  }

  @override
  String get linkFailUpdate =>
      'На другом устройстве более новая версия приложения. Обновите это и попробуйте снова.';

  @override
  String linkFailUpdateOther(String name) {
    return 'На $name более старая версия приложения. Обновите её там и попробуйте снова.';
  }

  @override
  String linkReplaceTitle(String name) {
    return 'Заменить $name?';
  }

  @override
  String linkReplaceBody(String name) {
    return 'Новое устройство просит связать его. $name больше не получает сообщений этого кошелька; удержанные здесь монеты освобождаются.';
  }

  @override
  String get linkReplace => 'Заменить';

  @override
  String linkKeep(String name) {
    return 'Оставить $name';
  }

  @override
  String devicesEpicboxOff(String name) {
    return 'Epicbox выключен: $name не видит платежей этого устройства.';
  }

  @override
  String get devicesEpicboxOffNone => 'Epicbox выключен.';

  @override
  String devicesUpdateOther(String name) {
    return 'Обновите $name, чтобы этот кошелёк оставался синхронизированным.';
  }

  @override
  String get devicesAbout => 'О связанном устройстве';

  @override
  String get offerLinkThird =>
      'Этот кошелёк есть на третьем устройстве. Связать можно два.';

  @override
  String devicesForwardedInvoice(String name) {
    return '$name получило запрос на оплату. Оплатите его там.';
  }

  @override
  String get linkConfirmInvite =>
      'Связать это устройство с тем, что прислало приглашение?';

  @override
  String get pairYourCode => 'Ваше приглашение';

  @override
  String get pairCodeCaption =>
      'Пусть отсканируют QR или отправьте приглашение.';

  @override
  String pairCodeCaptionFor(String name) {
    return 'Пусть $name отсканирует QR, или отправьте приглашение.';
  }

  @override
  String pairSeenAsLine(String name) {
    return 'Вас видят как $name';
  }

  @override
  String get pairChange => 'Изменить';

  @override
  String get pairSeenAsField => 'Вас видят как';

  @override
  String get pairCopyLink => 'Копировать приглашение';

  @override
  String get pairHaveTheirCode => 'Есть их приглашение?';

  @override
  String pairHaveNamesCode(String name) {
    return 'Есть приглашение от $name?';
  }

  @override
  String get pairScan => 'Сканировать QR';

  @override
  String get pairPasteField => 'Вставьте приглашение';

  @override
  String get pairNotACode => 'Это не приглашение к сопряжению.';

  @override
  String get pairEpicboxOffLine =>
      'Epicbox выключен. Вставьте ответ ниже, когда он придёт.';

  @override
  String get pairWaitingAnswer => 'Ожидание ответа…';

  @override
  String pairAnsweredFinishing(String name) {
    return '$name ответил(а) на приглашение. Ожидание, пока кошелёк $name завершит.';
  }

  @override
  String get pairFinishCodeTitle => 'Подтверждение';

  @override
  String pairFinishCodeBody(String name) {
    return 'Отправьте это $name. Проверка слов откроется, когда тот кошелёк это прочитает.';
  }

  @override
  String get pairYourAnswerBody =>
      'Отправьте его тем же путём, которым пришло приглашение. Затем вставьте то, что вернётся.';

  @override
  String get pairPasteFinishField => 'Вставьте подтверждение';

  @override
  String pairPairingWith(String name) {
    return 'Сопряжение с $name…';
  }

  @override
  String get pairInContacts => 'В ваших контактах';

  @override
  String get pairRequestBody =>
      'Запрос уходит на Epicbox-адрес этого контакта. Его кошелёк покажет запрос, когда будет открыт.';

  @override
  String get pairSendRequest => 'Отправить запрос';

  @override
  String get pairShowMyCodeInstead => 'Вместо этого показать моё приглашение';

  @override
  String pairRequestSent(String date) {
    return 'Запрос отправлен · $date';
  }

  @override
  String pairWaitingFor(String name) {
    return 'Ожидание кошелька $name';
  }

  @override
  String get pairAnsweredNotHeard =>
      'Ответ на ваше приглашение · пока нет вестей';

  @override
  String pairNotChecked(String name) {
    return '$name ещё не проверил(а)';
  }

  @override
  String contactTakesPaymentsAgain(String name) {
    return '$name снова принимает платежи.';
  }

  @override
  String get pairIsService => 'Автоматический сервис.';

  @override
  String pairConfirmedToo(String name) {
    return '$name тоже подтвердил(а).';
  }

  @override
  String get pairEndedShort => 'Сопряжение завершено';

  @override
  String get pairEndedMismatch => 'Вы сообщили, что слова не совпадают.';

  @override
  String pairEndedPeerMismatch(String name) {
    return '$name сообщил(а), что слова не совпадают.';
  }

  @override
  String pairEndedNeverFinished(String name) {
    return 'Кошелёк $name так и не завершил.';
  }

  @override
  String get pairEndedRowPeerMismatch => 'Сообщено, что слова не совпадают.';

  @override
  String get pairEndedRowNeverFinished => 'Кошелёк так и не завершил.';

  @override
  String get pairEndedRowUnpaired => 'Сопряжение удалено с той стороны.';

  @override
  String pairNoAnswerFrom(String name) {
    return 'Нет ответа от кошелька $name';
  }

  @override
  String get pairAgain => 'Сопрячь снова';

  @override
  String get pairAddressNotConfirmed => 'Адрес не подтверждён сопряжением.';

  @override
  String get pairHeldSend => 'Ожидает получателя';

  @override
  String pairProvesOther(String name) {
    return 'Кошелёк $name подтверждает другой адрес';
  }

  @override
  String get pairUpdateAddress => 'Обновить адрес контакта';

  @override
  String get pairDetach => 'Отвязать';

  @override
  String get pairCheckWords => 'Проверить слова';

  @override
  String pairWantsToPair(String name) {
    return '$name хочет сопряжение.';
  }

  @override
  String pairPairedWith(String name) {
    return 'Сопряжено с $name.';
  }

  @override
  String pairPairedOn(String device) {
    return 'Сопряжено на $device.';
  }

  @override
  String pairRequestsRow(int count) {
    return 'Запросы на сопряжение · $count';
  }

  @override
  String get pairRequestsTitle => 'Запросы на сопряжение';

  @override
  String get pairEndedNotice =>
      'Сопряжение завершено. Сопрягите снова с новым приглашением.';

  @override
  String get pairOtherWalletTitle => 'Этот ответ пришёл из другого кошелька.';

  @override
  String get pairOtherWalletBody => 'Ничего не сохранено.';

  @override
  String get pairKindDiffersTitle => 'Этот ответ не подходит к приглашению.';

  @override
  String get pairKindDiffersBody =>
      'В нём указан другой тип контакта, чем в приглашении. Ничего не сохранено. Выполните сопряжение заново.';

  @override
  String pairNotProvenBody(String name) {
    return 'С $name ещё не было платежа Epic Cash, поэтому запрос отправить нельзя.';
  }

  @override
  String pairInProgressTitle(String name) {
    return 'Сопряжение с $name уже идёт.';
  }

  @override
  String pairCrossedTitle(String name) {
    return 'Кошелёк $name тоже начал сопряжение. Ожидание его ответа.';
  }

  @override
  String pairDismissedTitle(String name) {
    return 'Этот запрос был отклонён. Попросите $name прислать новый.';
  }

  @override
  String get pairEndedBody =>
      'Ничего нового через него не пройдёт. Удалите его или сопрягите снова с новым приглашением.';

  @override
  String get pairWaitingSendBody => 'Отправьте вместо этого через Epicbox.';

  @override
  String get pairNotFoundTitle => 'Ни одно сопряжение этому не соответствует.';

  @override
  String get trustWaiting => 'Ожидание';

  @override
  String get trustEnded => 'Завершено';

  @override
  String get trustNotAnswering => 'Нет ответа';

  @override
  String get contactNotAnsweringBody =>
      'Счета и платежи могут до них не дойти.';

  @override
  String get pairRequestPair => 'Сопрячь';

  @override
  String get pairCancelPairingTitle => 'Отменить это сопряжение?';

  @override
  String pairCancelPairingBody(String name) {
    return 'Кошелёк $name узнает об этом, если ответит поздно. Ничего не сохраняется.';
  }

  @override
  String get pairCancelPairing => 'Отменить сопряжение';

  @override
  String get pairBackLater => 'Назад';

  @override
  String get helpPairTwoWaysTitle => 'Два способа сопряжения';

  @override
  String get helpPairTwoWaysShort => 'Запрос контакту или ваше приглашение.';

  @override
  String get helpPairTwoWaysP1 =>
      '**Сопряжение с контактом.** У контакта, которому вы платили или который платил вам через Epicbox, кнопка Сопрячь отправляет запрос на этот адрес. Его кошелёк покажет запрос, когда будет открыт; одно нажатие отвечает. Оба кошелька получают статус Проверено без проверки слов: запрос и ответ подтверждают адрес, который уже есть в контактах другой стороны.';

  @override
  String get helpPairTwoWaysP2 =>
      '**Сопряжение по приглашению.** Контакты › Сопрячь показывает ваше приглашение, действующее 7 дней. Другой кошелёк сканирует его или открывает ссылку; оба завершают через Epicbox и затем сравнивают четыре слова. Если на одной из сторон Epicbox выключен, тот же экран переносит ответ и подтверждение вручную: Поделиться и Вставить.';

  @override
  String get helpPairTwoWaysP3 =>
      'Запрос уходит только кошельку, который показал, что работает на BT Wallet: отмеченный платёж между двумя адресами за последние 30 дней. Для всех остальных Сопрячь показывает ваше приглашение.';

  @override
  String get helpPairWhyTitle2 => 'Зачем проверять слова';

  @override
  String get helpPairWhyShort2 => 'Сравните их лично, голосом или по видео.';

  @override
  String get helpPairWhyP1b =>
      'После сопряжения по приглашению оба кошелька показывают одни и те же четыре картинки и названия. Сравните их с другим человеком лично, голосом или по видеосвязи, но никогда в том чате, через который пришло приглашение: кто мог подменить приглашение по пути, мог подменить и то, что показывает этот чат.';

  @override
  String get helpPairWhyP2b =>
      '**Совпадают** отмечает контакт как Проверено; другой кошелёк узнаёт об этом и показывает «тоже подтвердил(а)». **Не совпадают** завершает сопряжение с обеих сторон, и ничего отправленного через него не будет завершено. Ошибочное «нет» тоже его завершает: сопрягите снова с новым приглашением.';

  @override
  String get helpPairWhyP3b =>
      'Проверено означает: кошелёк за адресом в ваших контактах. После запроса между двумя контактами статус ставится без слов, потому что запрос и ответ уже подтвердили этот адрес.';

  @override
  String get helpPairWhyP4b =>
      '«Подтверждённый» означает, что за последние 30 дней между двумя Epicbox-адресами прошёл платёж, отмеченный обоими кошельками. Контакт, которому с тех пор ответило другое приложение-кошелёк, не считается подтверждённым до следующего отмеченного платежа.';

  @override
  String get pairStandingFootnote =>
      'Действует 7 дней. Новое приглашение появится, когда это будет использовано.';

  @override
  String get storeEncrypting => 'Шифрование данных кошелька…';

  @override
  String get storeRecordsPlain =>
      'Данные кошелька пока остаются незашифрованными. Следующая попытка — при следующем запуске.';

  @override
  String get errorStoreWrongKey =>
      'Данные этого кошелька не удалось открыть этой фразой. Ничего не изменено.';

  @override
  String get contactsClosedTitle => 'Адресная книга закрыта';

  @override
  String get contactsClosedText =>
      'Она откроется, когда будет разблокирован кошелёк, который её использует.';

  @override
  String get pairSeenAsHint => 'Необязательно';

  @override
  String devicesNameWithCode(String name, String code) {
    return '$name $code';
  }

  @override
  String get deskSetDlgRemoveUnlockHintSecurity =>
      'Чтобы удалить и его файлы, разблокируйте этот кошелёк и выберите «Удалить кошелёк» в разделе «Настройки › Кошелёк».';

  @override
  String get deskRecvHttpTorHintNet =>
      'Чтобы получить адрес Tor, включите Tor в разделе «Настройки › Сеть и приватность».';

  @override
  String get deskRecvTorIntroNet =>
      'Напрямую из другого кошелька через Tor, пока этот открыт. Tor настраивается в разделе «Настройки › Сеть и приватность».';

  @override
  String get deskRecvTorOffTextNet =>
      'Адрес Tor работает, пока включён Tor. Tor — переключатель в Настройки › Сеть и приватность; он направляет соединения кошелька через Tor.';

  @override
  String get deskRailOpenNetworkPrivacy => 'Открыть «Сеть и приватность»';

  @override
  String get deskSetSearchHint => 'Поиск по настройкам';

  @override
  String get deskSetSearchKeyHint => 'Ctrl K';

  @override
  String get deskSetSearchClear => 'Очистить поиск';

  @override
  String deskSetSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '$count результат',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchFor(String query) {
    return 'по запросу «$query»';
  }

  @override
  String get deskSetSearchKeysMove => 'выбор';

  @override
  String get deskSetSearchKeysGo => 'к настройке';

  @override
  String get deskSetSearchKeysClear => 'очистить';

  @override
  String deskSetSearchMatches(String word) {
    return 'Совпадает с «$word»';
  }

  @override
  String get deskSetSearchHelpTopics => 'Темы справки';

  @override
  String get deskSetSearchHidden => 'Скрыто здесь';

  @override
  String get deskSetSearchHiddenLine =>
      'Их показывает другой вид или переключатель в Дополнительно';

  @override
  String deskSetSearchShowIn(String view) {
    return 'Показать в виде «$view»';
  }

  @override
  String get deskSetSearchTurnOn => 'Включить';

  @override
  String get deskSetSearchOpen => 'Открыть';

  @override
  String get deskSetSearchRead => 'Читать';

  @override
  String deskSetSearchNone(String query) {
    return 'Нет настроек по запросу «$query».';
  }

  @override
  String get deskSetSearchTry => 'Попробуйте';

  @override
  String get deskSetSearchTryWords =>
      'пароль,tor,сид,резервная,комиссия,узел,блокировка';

  @override
  String get deskSetSearchNoResults => 'Нет результатов';

  @override
  String get deskSetSearchResults => 'Результаты поиска';

  @override
  String deskSetSearchViewGate(String view) {
    return 'вид «$view»';
  }

  @override
  String deskSetSearchFeatGate(String feature) {
    return 'Дополнительно › $feature';
  }

  @override
  String deskSetSearchGateJoin(String first, String last) {
    return '$first и $last';
  }

  @override
  String deskSetSearchMore(int count, String gates) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count параметра · показывает $gates',
      many: 'Ещё $count параметров · показывает $gates',
      few: 'Ещё $count параметра · показывает $gates',
      one: 'Ещё $count параметр · показывает $gates',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchLess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Скрыть $count дополнительного параметра',
      many: 'Скрыть $count дополнительных параметров',
      few: 'Скрыть $count дополнительных параметра',
      one: 'Скрыть $count дополнительный параметр',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchViewApplied(String view) {
    return 'Вид: $view';
  }

  @override
  String deskSetSearchFeatApplied(String feature) {
    return 'Дополнительно › $feature: вкл.';
  }

  @override
  String deskSetSearchFallbackView(String page, String view) {
    return '$page есть в виде «$view».';
  }

  @override
  String deskSetSearchFallbackFeat(String page, String feature) {
    return '$page появляется с Дополнительно › $feature.';
  }

  @override
  String get deskSetSecWallet => 'Кошелёк';

  @override
  String get deskSetSecPayments => 'Платежи';

  @override
  String get deskSetSecDevices => 'Связанные устройства';

  @override
  String get deskSetSecWallets => 'Кошельки';

  @override
  String get deskSetSecFiles => 'Файлы и журналы';

  @override
  String get deskSetNavApp => 'Приложение';

  @override
  String get deskSetNavComputer => 'Этот компьютер';

  @override
  String get deskSetGrpBackup => 'Резервная копия';

  @override
  String get deskSetGrpBalance => 'Баланс';

  @override
  String get deskSetGrpRemove => 'Удаление';

  @override
  String get deskSetGrpMethods => 'Способы';

  @override
  String get deskSetGrpSending => 'Отправка';

  @override
  String get deskSetGrpReceiving => 'Получение';

  @override
  String get deskSetGrpThisDevice => 'Это устройство';

  @override
  String get deskSetGrpLinkedDevice => 'Связанное устройство';

  @override
  String get deskSetGrpSync => 'Синхронизация';

  @override
  String get deskSetGrpConnection => 'Подключение';

  @override
  String get deskSetGrpLocalNode => 'Узел на этом компьютере';

  @override
  String get deskSetGrpConnections => 'Подключения';

  @override
  String get deskSetGrpTor => 'Tor';

  @override
  String get deskSetGrpServerStatus => 'Состояние серверов';

  @override
  String get deskSetGrpView => 'Вид';

  @override
  String get deskSetGrpShowsMore => 'Показывает больше';

  @override
  String get deskSetGrpExperiments => 'Эксперименты';

  @override
  String get deskSetGrpOnComputer => 'На этом компьютере';

  @override
  String get deskSetGrpAddWallet => 'Добавить кошелёк';

  @override
  String get deskSetGrpFolders => 'Папки';

  @override
  String get deskSetGrpLogs => 'Журналы';

  @override
  String get deskSetGrpSupport => 'Поддержка';

  @override
  String get deskSetGrpStartAgain => 'Начать заново';

  @override
  String get deskSetGrpLinks => 'Ссылки';

  @override
  String get deskSetRowNameHint => 'Видно только в этом приложении.';

  @override
  String get deskSetSynName => 'переименовать, имя кошелька, метка, название';

  @override
  String get deskSetRowExportDataHint =>
      'История, контакты, счета и настройки в одном зашифрованном файле.';

  @override
  String get deskSetRowExportDataInfo =>
      'Открыть файл может только кошелёк с этой сид-фразой. Сами монеты восстанавливает сид-фраза.';

  @override
  String get deskSetSynExportData =>
      'резервная копия, бэкап, сохранить, история, контакты, файл';

  @override
  String get deskSetRowImportDataHint =>
      'Возвращает историю, контакты, счета и настройки из экспорта.';

  @override
  String get deskSetSynImportData =>
      'восстановить, резервная копия, бэкап, история, загрузить';

  @override
  String get deskSetRowExportCsvHint =>
      'Простая таблица для электронных таблиц. Без шифрования.';

  @override
  String get deskSetSynExportCsv =>
      'csv, excel, таблица, налог, история, отчёт';

  @override
  String get deskSetRowRecheckGoHint =>
      'Заново читает блокчейн в поисках монет этого кошелька.';

  @override
  String get deskSetSynRecheckGo =>
      'пересканировать, скан, неверный баланс, пропали, ресинхронизация, обновить, исправить';

  @override
  String get deskSetRowDeleteWalletHint =>
      'Удаляет его ключи и базу данных с этого компьютера.';

  @override
  String get deskSetSynDeleteWallet => 'удалить, стереть, очистить';

  @override
  String get deskSetSynRecheckFrom => 'начало, дата, высота, блок';

  @override
  String get deskSetRowRecheckDropHint =>
      'Также отменяет неподтверждённые транзакции. Платёж в пути может тогда не пройти.';

  @override
  String get deskSetSynRecheckDrop =>
      'неподтверждённые, зависла, отменить, разблокировать';

  @override
  String get deskSetRowPhraseGoHint =>
      '24 слова, которые восстанавливают этот кошелёк.';

  @override
  String get deskSetSynPhraseGo =>
      'сид, seed, мнемоника, слова, резервная копия, секрет, восстановить, 24 слова, приватный ключ';

  @override
  String get deskSetRowPasswordHint => 'Разблокирует этот кошелёк.';

  @override
  String get deskSetSynPassword =>
      'пароль, сменить пароль, разблокировать, пин';

  @override
  String get deskSetRowRememberedHint =>
      'Открывается при запуске без пароля. При отправке он всё равно нужен.';

  @override
  String get deskSetSynRemembered =>
      'запомнить, пароль, разблокировать, автоматическая разблокировка, забыть';

  @override
  String get deskSetRowAutolockHint =>
      'Блокирует, когда нет нажатий клавиш и движения мыши. Все кошельки.';

  @override
  String get deskSetSynAutolock =>
      'блокировка, тайм-аут, бездействие, неактивность, блокировка экрана';

  @override
  String get deskSetRowEpicboxHint =>
      'Платите и получайте платежи через сервер Epicbox. Так идёт большинство платежей. Все кошельки.';

  @override
  String get deskSetSynEpicbox =>
      'релей, сервер, адрес, получить, отправить, способ';

  @override
  String get deskSetSynEpicboxRecv => 'прослушивание, входящие, получение';

  @override
  String get deskSetRowEpicboxServerHint => 'Часть адреса этого кошелька.';

  @override
  String get deskSetSynEpicboxServer => 'релей, сервер, хост, адрес';

  @override
  String get deskSetSynEpicboxStart => 'автозапуск, при запуске';

  @override
  String get deskSetRowHttpHint =>
      'Кошелёк к кошельку по веб-адресу, пока оба открыты. Все кошельки.';

  @override
  String get deskSetSynHttp => 'http, ip, порт, напрямую, слушатель, способ';

  @override
  String get deskSetSynHttpReach =>
      'интернет, роутер, проброс порта, публичный';

  @override
  String get deskSetSynHttpPort => 'порт, tcp';

  @override
  String get deskSetRowTorPayHint =>
      'Кошелёк к кошельку по Tor-адресу этого кошелька, пока оба открыты. Все кошельки.';

  @override
  String get deskSetRowTorPayInfo =>
      'Tor работает только для отправки и получения платежей по Tor-адресу. Узел, цены и обновления следуют настройке в разделе Сеть и приватность.';

  @override
  String get deskSetSynTorPay =>
      'tor, onion, скрытый сервис, приватность, способ';

  @override
  String get deskSetRowFileHint =>
      'Передачей файла транзакции. Сеть не нужна. Все кошельки.';

  @override
  String get deskSetSynFile =>
      'файл, офлайн, slate, файл транзакции, usb, способ, вручную';

  @override
  String get deskSetRowDefaultMethodHint =>
      'С чего открывается Отправка. Все кошельки.';

  @override
  String get deskSetSynDefaultMethod => 'отправить, способ, по умолчанию';

  @override
  String get deskSetRowStrategy => 'Какие выходы тратит отправка';

  @override
  String get deskSetRowStrategyHint =>
      'Наименьшие покрывают сумму; Все тратит каждый выход.';

  @override
  String get deskSetRowStrategyInfo =>
      'Чем больше потрачено выходов, тем выше комиссия.';

  @override
  String get deskSetSynStrategy =>
      'комиссия, комиссии, стратегия, выбор монет, входы, utxo, выходы';

  @override
  String get deskSetRowSplitChangeHint =>
      'Сдача возвращается до 4 выходов, когда их осталось мало.';

  @override
  String get deskSetRowSplitChangeInfo =>
      'Только если отправка оставила бы меньше 3 доступных выходов, а сдача не меньше 1 EPIC. Каждый лишний выход стоит 0,004 EPIC.';

  @override
  String get deskSetSynSplitChange =>
      'комиссия, сдача, выходы, utxo, разделить';

  @override
  String get deskSetRowConfirmationsHint =>
      'Сколько блоков полученный платёж ждёт, прежде чем его можно потратить.';

  @override
  String get deskSetSynConfirmations =>
      'подтверждения, блоки, доступно, заблокировано, в ожидании, ждать';

  @override
  String get deskSetRowPairShopHint =>
      'Сопряжённый контакт, которому вы разрешите, может присылать этому кошельку счета.';

  @override
  String get deskSetSynPairShop =>
      'сопряжение, связать, счёт, магазин, биржа, продавец';

  @override
  String get deskSetRowTimeToPayHint => 'Сколько времени счёт можно оплатить.';

  @override
  String get deskSetSynTimeToPay => 'счёт, срок, истекает, дедлайн';

  @override
  String get deskSetSynDeviceName => 'имя устройства, переименовать';

  @override
  String get deskSetRowLinkDeviceHint =>
      'Этот кошелёк на двух устройствах: каждое показывает платежи другого.';

  @override
  String get deskSetRowLinkDeviceInfo =>
      'Можно связать одно устройство. Каждое держит монеты, которые тратит другое, поэтому они никогда не потратят одну и ту же монету.';

  @override
  String get deskSetSynLinkDevice =>
      'связать устройство, телефон, второе устройство, синхронизация, мобильный, несколько устройств';

  @override
  String get deskSetRowPauseSyncHint =>
      'Пока синхронизация на паузе, уведомления ждут на серверах.';

  @override
  String get deskSetSynPauseSync => 'синхронизация, пауза, связанные';

  @override
  String get deskSetSynTheme =>
      'тёмная тема, светлая тема, цвет, ночь, dark mode';

  @override
  String get deskSetSynLanguage => 'язык, перевод, русский, english, polski';

  @override
  String get deskSetRowScaleHint =>
      'Текст и элементы управления, крупнее или мельче.';

  @override
  String get deskSetSynScale =>
      'масштаб, зум, размер, размер шрифта, крупнее, мельче, dpi';

  @override
  String get deskSetRowHideAmountsHint => 'Точки вместо балансов и сумм.';

  @override
  String get deskSetSynHideAmounts =>
      'приватность, скрыть баланс, маска, демонстрация экрана, стрим';

  @override
  String get deskSetRowNodeServerHint =>
      'Читает блокчейн и отправляет транзакции этого кошелька.';

  @override
  String get deskSetSynNodeServer => 'узел, нода, сервер, хост, rpc, api, url';

  @override
  String get deskSetRowFailover => 'Переключать узел автоматически';

  @override
  String get deskSetRowFailoverHint =>
      'Когда узел перестаёт отвечать, взять следующий рабочий.';

  @override
  String get deskSetSynFailover => 'failover, резервный, автоматически';

  @override
  String get deskSetRowMyNodeHint =>
      'Спрашивает сам узел о его состоянии и даёт доступ владельца.';

  @override
  String get deskSetSynMyNode =>
      'свой узел, мой узел, своя нода, владелец, api secret';

  @override
  String get deskSetRowLocalNode => 'Узел на этом компьютере';

  @override
  String get deskSetRowLocalNodeHint =>
      'Запускает здесь собственный узел. Несколько гигабайт на диске.';

  @override
  String get deskSetSynLocalNode =>
      'локальный узел, встроенный узел, полный узел, запустить узел, синхронизация блокчейна';

  @override
  String get deskSetRowLocalStartHint =>
      'Держит узел синхронизированным, пока приложение открыто.';

  @override
  String get deskSetSynLocalStart => 'автозапуск, локальный узел';

  @override
  String get deskSetRowNetMode => 'Режим подключения';

  @override
  String get deskSetSynNetMode =>
      'только tor, undercover, офлайн, kill switch, только узел, vpn, ip, приватность, авиарежим';

  @override
  String get deskSetRowStatusSiteHint =>
      'Показывает, какие узлы и серверы Epicbox в сети.';

  @override
  String get deskSetSynStatusSite =>
      'статус, состояние, доступность, мониторинг';

  @override
  String get deskSetRowView => 'Вид';

  @override
  String get deskSetRowViewHint =>
      'Мелко, Глубже или В самую глубь: сколько кошелька видно.';

  @override
  String get deskSetSynView =>
      'уровень, глубина, мелко, глубже, в самую глубь, просто, эксперт, новичок, расширенный режим';

  @override
  String get deskSetRowAdvOutputsHint =>
      'Страница Выходы: монеты, из которых состоит баланс.';

  @override
  String get deskSetSynAdvOutputs =>
      'utxo, монеты, выходы, разделить, объединить';

  @override
  String get deskSetRowAdvTechHint =>
      'Kernel, ID slate и коммитменты у каждой транзакции.';

  @override
  String get deskSetSynAdvTech =>
      'kernel, slate, коммитмент, id транзакции, детали';

  @override
  String get deskSetRowAdvSendoptsHint =>
      'Выбор выходов и сдачи при отправке и в Платежах.';

  @override
  String get deskSetSynAdvSendopts => 'комиссия, контроль монет, выходы, сдача';

  @override
  String get deskSetRowAdvServersHint =>
      'Хосты, задержка, версия и высота в списках серверов.';

  @override
  String get deskSetSynAdvServers => 'задержка, пинг, высота, версия, хост';

  @override
  String get deskSetRowAdvHeightHint =>
      'С чего начать и Удалить неподтверждённые при перепроверке баланса.';

  @override
  String get deskSetSynAdvHeight => 'пересканировать, высота, блок';

  @override
  String get deskSetRowAdvLocalHint =>
      'Узел на этом компьютере, в разделе Узел.';

  @override
  String get deskSetSynAdvLocal => 'полный узел, локальный узел';

  @override
  String get deskSetRowAdvLogsHint =>
      'Уровень журнала и файлы журнала в Файлы и журналы.';

  @override
  String get deskSetSynAdvLogs => 'журнал, лог, отладка, диагностика';

  @override
  String get deskSetRowXInvoicesHint =>
      'Просить сопряжённые контакты о платежах; одобрять их запросы.';

  @override
  String get deskSetSynXInvoices => 'счёт, запрос платежа, сопряжение, оплата';

  @override
  String get deskSetRowWalletRows => 'Список кошельков';

  @override
  String get deskSetRowWalletRowsHint =>
      'Кошельки на этом компьютере; открыть или убрать один.';

  @override
  String get deskSetSynWalletRows =>
      'кошельки, сменить кошелёк, другой кошелёк, список';

  @override
  String get deskSetRowCreateWalletHint => 'Новый кошелёк с новой сид-фразой.';

  @override
  String get deskSetSynCreateWallet => 'новый кошелёк, добавить кошелёк';

  @override
  String get deskSetRowImportWalletsHint =>
      'Из старого Epic Wallet или из папки.';

  @override
  String get deskSetSynImportWallets =>
      'миграция, старый кошелёк, electron, gui-кошелёк, папка';

  @override
  String get deskSetRowRestoreWalletHint => 'Из сид-фразы из 24 слов.';

  @override
  String get deskSetSynRestoreWallet => 'сид, seed, восстановить, мнемоника';

  @override
  String get deskSetRowWalletFolderHint =>
      'Ключи и база данных этого кошелька.';

  @override
  String get deskSetSynWalletFolder =>
      'папка данных, каталог, путь, файлы, расположение';

  @override
  String get deskSetRowAppFilesHint => 'settings.toml и журнал.';

  @override
  String get deskSetSynAppFiles =>
      'файл настроек, settings.toml, конфиг, toml, каталог';

  @override
  String get deskSetRowLogLevelHint =>
      'Подробный хранит больше строк; в отчётах нет адресов.';

  @override
  String get deskSetSynLogLevel => 'журнал, лог, отладка, подробно';

  @override
  String get deskSetRowLogFilesHint =>
      'Очистить файлы журнала или открыть их папку.';

  @override
  String get deskSetSynLogFiles =>
      'журнал, лог, очистить журналы, удалить журналы';

  @override
  String get deskSetRowReportHint =>
      'Опишите, что пошло не так; можно приложить очищенный журнал приложения.';

  @override
  String get deskSetSynReport =>
      'ошибка, баг, проблема, поддержка, сбой, отчёт об ошибке';

  @override
  String get deskSetSynTour => 'тур, обучение, введение, знакомство';

  @override
  String get deskSetRowSetup => 'Запустить настройку снова';

  @override
  String get deskSetRowSetupHint => 'Узел и получение, шаг за шагом.';

  @override
  String get deskSetSynSetup => 'настройка, мастер, помощник, перенастроить';

  @override
  String get deskSetRowUpdatesHint => 'Проверяет, есть ли новая версия.';

  @override
  String get deskSetSynUpdates => 'обновление, новая версия, скачать, релиз';

  @override
  String get deskSetRowWebsite => 'Сайт';

  @override
  String get deskSetSynWebsite => 'сайт, веб, интернет, epic cash';

  @override
  String get deskSetSynSource =>
      'github, код, исходный код, open source, репозиторий';

  @override
  String get deskSetSynPrivacyPolicy => 'приватность, политика, gdpr, данные';

  @override
  String get deskSetAcctBackup => 'Резервная копия';

  @override
  String get deskSetAcctBalance => 'Баланс';

  @override
  String get deskSetAcctRemove => 'Удаление';

  @override
  String get deskSetAdvViewLineOne =>
      'Отправка, получение и резервные копии. Узел и сервер Epicbox выбираются автоматически.';

  @override
  String get deskSetAdvViewLineTwo =>
      'Добавляет способы оплаты, узел, режимы сети и другие кошельки.';

  @override
  String get deskSetAdvViewLineThree =>
      'Добавляет выходы, счета, локальный узел и все переключатели раздела «Дополнительно».';

  @override
  String get deskSetAdvExperiments => 'Эксперименты';

  @override
  String get deskSetFrameBack => 'Кошелёк';

  @override
  String get deskSetFrameBackTip => 'Назад к кошельку (Esc)';

  @override
  String deskSetFrameBackTo(String page) {
    return 'Назад: $page';
  }

  @override
  String get deskSetFrameEscKey => 'Esc';

  @override
  String get deskSetFrameEscHint => 'назад к кошельку';

  @override
  String get deskSetFrameExperiment => 'Эксперимент';

  @override
  String get deskSetHelpReportButton => 'Сообщить…';

  @override
  String get deskSetHelpSetupAgain => 'Запустить настройку снова';

  @override
  String get deskSetHelpSetupHint => 'Узел и получение, шаг за шагом.';

  @override
  String get deskSetHelpStartAgain => 'Начать заново';

  @override
  String get deskSetHelpTourStart => 'Начать тур';

  @override
  String get deskSetFilesFolders => 'Папки';

  @override
  String get deskSetNodeConnection => 'Подключение';

  @override
  String get deskSetNodeFailover => 'Менять узел автоматически';

  @override
  String get deskSetNodeStatus => 'Состояние';

  @override
  String get deskSetPrivTorAll => 'Tor для всех соединений';

  @override
  String get deskSetPrivServerStatus => 'Состояние серверов';

  @override
  String get deskSetPrivMode => 'Режим соединения';

  @override
  String get deskSetTxSending => 'Отправка';

  @override
  String get deskSetTxTorPayHint =>
      'Tor работает только для отправки и получения платежей по адресу Tor. Узел, курсы и обновления следуют настройке в разделе «Сеть и приватность». Все кошельки.';

  @override
  String get deskSetWalletsOnComputer => 'На этом компьютере';

  @override
  String get deskSetSearchKeyEnter => 'Enter';

  @override
  String get deskSetSearchKeyEsc => 'Esc';

  @override
  String get deskTorPayOff => 'Выкл.';

  @override
  String get deskTorPayStarting => 'Запуск Tor · только для платежей';

  @override
  String get deskTorPayReady => 'Принимает';

  @override
  String deskTorPayBlockedNodeOnly(String mode) {
    return 'Выкл. в режиме $mode: подключается только узел.';
  }

  @override
  String deskTorPayBlockedKill(String mode) {
    return 'Выкл. в режиме $mode: ничего не подключается.';
  }

  @override
  String get deskTorPayFailed => 'Tor не подключился.';

  @override
  String deskTorPayFailedWhy(String problem) {
    return 'Tor не подключился: $problem.';
  }

  @override
  String get deskTorPayRestOn =>
      'Tor для всех подключений: вкл. (Сеть и конфиденциальность).';

  @override
  String get deskTorPayRestOff =>
      'Tor для всех подключений: выкл. (Сеть и конфиденциальность).';

  @override
  String get deskRailTorForPayments => 'Для платежей';

  @override
  String get deskBarKeySearch => 'Поиск по настройкам';

  @override
  String get deskBarKeySearchHere => 'Поиск, когда открыты Настройки';

  @override
  String get deskHttpLocalTitle => 'Локальная сеть';

  @override
  String get deskHttpLocalSwitch => 'Получать на этом компьютере';

  @override
  String get deskHttpPublicTitle => 'Интернет';

  @override
  String deskHttpPublicNote(String port) {
    return 'Для кошельков в интернете. Роутер должен перенаправлять порт $port на этот компьютер.';
  }

  @override
  String deskKitMethodHttpNotReachable(String port) {
    return 'только в локальной сети. Чтобы получать платежи из интернета, роутер должен передавать порт $port на этот компьютер.';
  }

  @override
  String get sendRouteLinkHttps => 'Ссылка · HTTPS';

  @override
  String get sendRouteThisPhone => 'Этот телефон';

  @override
  String get sendRouteThisComputer => 'Этот компьютер';

  @override
  String get sendRouteYourNetwork => 'Ваша сеть';

  @override
  String get sendRouteOverTor => 'Через Tor';

  @override
  String get sendRouteTorStarts => 'Tor запустится при отправке.';

  @override
  String get sendRouteChange => 'Изменить';

  @override
  String sendRouteChangeSem(int count) {
    return 'Изменить адрес, ещё $count';
  }

  @override
  String sendRouteAddressesOf(String name) {
    return 'Адреса контакта $name';
  }

  @override
  String sendRouteMore(int count) {
    return 'ещё $count';
  }

  @override
  String sendRouteSemantics(String method, String host) {
    return 'Отправка через $method на $host';
  }

  @override
  String get sendHeldKillSwitch =>
      'Включено «Аварийное отключение». Ничего не подключается.';

  @override
  String get sendHeldNodeOnly =>
      'Включён режим «Только узел». Подключается только узел.';

  @override
  String get sendHeldTorOnly =>
      'Включён режим «Только Tor». Обычный http:// не может идти через Tor.';

  @override
  String get sendHeldTorOn =>
      'Tor включён. Обычный http:// не может идти через Tor.';

  @override
  String get sendHeldFixKillSwitch => 'Выключить «Аварийное отключение»';

  @override
  String get sendHeldFixNodeOnly => 'Выключить «Только узел»';

  @override
  String get sendHeldFixTorOnly => 'Выключить «Только Tor»';

  @override
  String get sendHeldByKillSwitch => 'Недоступно: «Аварийное отключение»';

  @override
  String get sendHeldByNodeOnly => 'Недоступно: «Только узел»';

  @override
  String get sendHeldByTorOnly => 'Недоступно: «Только Tor»';

  @override
  String get sendHeldWhileTorOn => 'Недоступно, пока включён Tor';

  @override
  String get sendHeldModeNormal => 'Режим сети: Обычный.';

  @override
  String get sendHeldTorIsOff => 'Tor выключен.';

  @override
  String get sendNoAddress => 'Нет адреса?';

  @override
  String get sendWithoutConnection => 'Без подключения:';

  @override
  String get sendPayInPerson => 'Оплатить лично';

  @override
  String get sendPayByFile => 'Оплатить файлом';

  @override
  String get sendIsSlateText => 'Это текст транзакции, а не адрес.';

  @override
  String get sendOpenSlateText => 'Открыть';

  @override
  String get sendSendsTo => 'Отправка на';

  @override
  String get sendProblemNotAddress =>
      'Это не адрес, и нет контакта с таким именем.';

  @override
  String get sendProblemOtherScheme =>
      'Этот кошелёк не может платить на такой адрес.';

  @override
  String get sendProblemIncomplete => 'Этот адрес выглядит неполным.';

  @override
  String get sendProblemOnion =>
      'Это неполный адрес Tor. Скопируйте его у получателя ещё раз.';

  @override
  String get sendProblemPort => 'Порт должен быть от 1 до 65535.';

  @override
  String get sendProblemCredentials =>
      'Нельзя заплатить на адрес, в котором есть имя пользователя.';

  @override
  String get sendProblemCharacters =>
      'В этом адресе есть символы, которых не может быть в адресе.';

  @override
  String get sendProblemTooLong => 'Этот адрес слишком длинный.';

  @override
  String get sendProblemOwn => 'Это собственный адрес этого кошелька.';

  @override
  String get sendReachChecking => 'Проверка…';

  @override
  String sendReachNone(String host) {
    return 'По адресу $host не отвечает ни один кошелёк.';
  }

  @override
  String sendReachNotWallet(String host) {
    return 'По адресу $host что-то отвечает, но это не кошелёк Epic.';
  }

  @override
  String get sendReachTheirOnion => 'Tor получателя';

  @override
  String get sendReachOpenFirst =>
      'Кошелёк получателя должен быть открыт, чтобы принять платёж.';

  @override
  String get sendReachCheckAddress => 'Уточните адрес у получателя.';

  @override
  String get sendReachTryAgain => 'Повторить';

  @override
  String get sendFactVia => 'Через';

  @override
  String get sendFactHost => 'Хост';

  @override
  String get sendFactConnection => 'Подключение';

  @override
  String get sendFactNotEncrypted => 'Без шифрования · http://';

  @override
  String get sendFactTor => 'Tor';

  @override
  String get sendFactTorStarts => 'Запустится при отправке';

  @override
  String get sendFactOffline => 'Кошелёк получателя может быть не в сети.';

  @override
  String get sendFactOnline => 'Кошелёк получателя должен быть открыт.';

  @override
  String get deskTfOpenTitle => 'Открыть файлы транзакций';

  @override
  String get deskTfOpenText =>
      'Выберите один файл или несколько. Кошелёк прочитает каждый и подпишет, завершит или отправит его в сеть.';

  @override
  String get deskTfPickTitle => 'Файлы транзакций';

  @override
  String get deskTfResults => 'Открытые файлы';

  @override
  String get deskTfWorking => 'Обработка…';

  @override
  String deskTfSigned(String path) {
    return 'Подписано. Ответ сохранён в $path';
  }

  @override
  String get deskTfAlreadyPosted => 'Уже отправлено в сеть';

  @override
  String deskTfInvoice(String amount) {
    return 'Счёт на $amount. Проверьте его, чтобы оплатить.';
  }

  @override
  String get deskTfReview => 'Проверить';

  @override
  String get deskTfCreate => 'Создать файл платежа';

  @override
  String get deskTfDropHint => 'Их также можно перетащить сюда.';

  @override
  String get deskSaToAddress => 'Отправить на адрес';

  @override
  String deskSaToContactSem(String name) {
    return 'Кому: $name';
  }

  @override
  String get netModesTitle => 'Режимы соединения';

  @override
  String get netModesAbout => 'О режимах соединения';

  @override
  String get netModesGroup => 'Режим соединения';

  @override
  String get netModesTag => '[NET]';

  @override
  String get netModesTopology => 'Топология';

  @override
  String get netModesDevice => 'Устройство';

  @override
  String get netModesDeviceSub => 'этот кошелёк';

  @override
  String get netModesTorSub => 'встроен';

  @override
  String get netModesEpicboxSub => 'ретранслятор';

  @override
  String get netModesNode => 'Узел';

  @override
  String get netModesNodeSub => 'используемый узел';

  @override
  String get netModesNetwork => 'Сеть';

  @override
  String get netModesNetworkSub => 'пиры';

  @override
  String get netModesPostElsewhere => 'С другого устройства';

  @override
  String get netModesLeaves => 'Покидает устройство';

  @override
  String get netModesDirect => 'Напрямую';

  @override
  String get netModesViaTor => 'Через Tor';

  @override
  String get netModesOptional => 'По выбору';

  @override
  String get netModesAllTraffic => 'Весь трафик';

  @override
  String get netModesOff => 'Выкл.';

  @override
  String get netModesYes => 'Да';

  @override
  String get netModesNo => 'Нет';

  @override
  String get netModesDescStandard =>
      'Подключается напрямую к узлу, Epicbox и сервисам, которыми вы пользуетесь. Если Tor включён, платежи идут через Tor.';

  @override
  String get netModesDescNodeOnly =>
      'Подключается только используемый узел, через Tor, если Tor включён. Epicbox, Ссылка, связанные устройства, проверка курса и обновлений выключены.';

  @override
  String get netModesDescNodeOnlyNoTor =>
      'Подключается только используемый узел. Epicbox, Ссылка, связанные устройства, проверка курса и обновлений выключены.';

  @override
  String get netModesDescKillSwitch =>
      'Ничего не подключается, даже узел. Платежи создаются и завершаются офлайн, а затем отправляются с устройства, которое в сети.';

  @override
  String netModesLiveLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активного соединения',
      many: '$count активных соединений',
      few: '$count активных соединения',
      one: '$count активное соединение',
    );
    return '$_temp0';
  }

  @override
  String netModesDiagramLabel(String mode, String description) {
    return 'Топология сети, режим «$mode»: $description';
  }

  @override
  String get netModesModeTag => '[Режим]';

  @override
  String get deskOldAppTitle => 'Найдено старое приложение';

  @override
  String deskOldAppBody(String app, String folder) {
    return '$app всё ещё в папке $folder.';
  }

  @override
  String get deskOldAppTrash => 'Переместить в Корзину';

  @override
  String get deskOldAppKeep => 'Оставить';

  @override
  String deskOldAppTrashed(String app) {
    return '$app перемещено в Корзину';
  }

  @override
  String deskOldAppNotTrashed(String app) {
    return 'Не удалось переместить $app в Корзину';
  }

  @override
  String deskOvInflightMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count платежа в пути',
      many: 'Ещё $count платежей в пути',
      few: 'Ещё $count платежа в пути',
      one: 'Ещё $count платёж в пути',
    );
    return '$_temp0';
  }

  @override
  String get deskOvInflightView => 'Показать';

  @override
  String get deskNoTorSetSynNetMode =>
      'офлайн, kill switch, только узел, vpn, ip, приватность, авиарежим';

  @override
  String get deskNoTorSetSearchTryWords =>
      'пароль,приватность,сид,резервная,комиссия,узел,блокировка';

  @override
  String get deskKitReachDismiss => 'Скрыть';

  @override
  String deskErrKeyMissing(String name) {
    return 'Файлы кошелька $name на этом компьютере, но ключа, который их открывает, больше нет в его защищённом хранилище (на Mac — в связке ключей). Введите фразу восстановления кошелька, чтобы открыть его снова; история сохранится.';
  }

  @override
  String get deskOnbUnlockUsePhrase => 'Ввести фразу восстановления';

  @override
  String get pairSeenAsNone => 'Они не видят имени';

  @override
  String get pairSeenAsAdd => 'Добавить имя';

  @override
  String get pairSeenAsOptional => 'Оставьте пустым, чтобы сопрячь без имени.';

  @override
  String get pairUnnamed => 'Кошелёк без имени';

  @override
  String pairDefaultLabel(int n) {
    return 'Контакт $n';
  }

  @override
  String get linkNotALink => 'Это не платёжная ссылка';

  @override
  String get linkMadeForMainnet => 'Ссылка создана для mainnet';

  @override
  String get linkMadeForFloonet => 'Ссылка создана для floonet';

  @override
  String get linkChanged => 'Эту ссылку изменили после создания.';

  @override
  String linkExpired(String date) {
    return 'Срок действия ссылки истёк $date';
  }

  @override
  String get linkForOther => 'Ссылка создана для другого человека';

  @override
  String get linkPaidTitle => 'Уже оплачено';

  @override
  String linkPaidBefore(String date) {
    return 'Вы оплатили этот запрос $date';
  }

  @override
  String get linkPayAgain => 'Оплатить снова';

  @override
  String linkTrustListed(String name, String service) {
    return '$name · через $service';
  }

  @override
  String linkTrustListedBy(String service) {
    return 'Через $service';
  }

  @override
  String get linkTrustNameService => 'От сервиса, с которым вы сопряжены';

  @override
  String get linkTrustOther =>
      'Проверьте, что они совпадают с сообщением о платеже';

  @override
  String linkTrustChanged(String name, String date) {
    return '$name теперь получает платежи на другой кошелёк, чем при вашем платеже $date. Платите, только если вам об этом сказали.';
  }

  @override
  String linkTrustChangedNoName(String date) {
    return 'Получатель теперь получает платежи на другой кошелёк, чем при вашем платеже $date. Платите, только если вам об этом сказали.';
  }

  @override
  String linkCodeLabel(String name) {
    return 'Картинки для $name';
  }

  @override
  String get linkCodeLabelPlain => 'Картинки';

  @override
  String get linkAmountEdited => 'Не запрошенная сумма';

  @override
  String get linkChangedConfirmTitle => 'Проверьте перед оплатой';

  @override
  String nsWaitingFor(String label) {
    return 'Ожидание $label…';
  }

  @override
  String get nsCodeTitle => 'Проверьте код';

  @override
  String nsCodeLead(String label) {
    return '$label показывает четыре картинки. Сравните их с этими.';
  }

  @override
  String get nsCodeLabel => 'Четыре картинки';

  @override
  String nsJoin(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Платите мне через $label',
      'other': 'Платите мне как $name',
    });
    return '$_temp0';
  }

  @override
  String get nsNotNow => 'Не сейчас';

  @override
  String nsJoinTitle(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Платите мне через $label?',
      'other': 'Платите мне как $name?',
    });
    return '$_temp0';
  }

  @override
  String nsJoinBody(String name, String label, String host) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none':
          'Те, кто пользуется $label, могут платить вам там. Платежи приходят через $host',
      'other':
          'Те, кто пользуется $label, могут платить вам как $name. Платежи приходят через $host',
    });
    return '$_temp0';
  }

  @override
  String nsJoinInfo(String label) {
    return '$label получает один платёжный адрес и один код, оба созданы только для него. Он не видит ваш баланс, не двигает монеты и не читает платежи. Платежи приходят, пока Epic Cash открыт. Выйти можно в любой момент: Контакты › $label.';
  }

  @override
  String nsJoinedNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Платите мне через $label: включено',
      'other': 'Платите мне как $name: включено',
    });
    return '$_temp0';
  }

  @override
  String nsLeftNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Платите мне через $label: выключено',
      'other': 'Платите мне как $name: выключено',
    });
    return '$_temp0';
  }

  @override
  String nsJoined(String name, String label, String date) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Платите мне через $label · с $date',
      'other': 'Платите мне как $name · с $date',
    });
    return '$_temp0';
  }

  @override
  String get nsNotListed => 'Выключено';

  @override
  String nsNotListedBody(String label) {
    return '$label: ваше имя удалено.';
  }

  @override
  String get nsNotJoined => 'Выключено';

  @override
  String get nsJoinAgain => 'Включить снова';

  @override
  String get nsListingCode => 'Картинки для вашего имени';

  @override
  String nsListingCodeInfo(String label) {
    return 'Четыре картинки, созданные из кошелька, на который приходят платежи по вашему имени. $label может показать те же четыре для сравнения.';
  }

  @override
  String get nsLeave => 'Выйти';

  @override
  String nsRemoveTooTitle(String label) {
    return 'Удалить также $label?';
  }

  @override
  String deskSendErrOwnNamed(String wallet) {
    return 'Это «$wallet», открытый сейчас кошелёк. Чтобы отправить на него, сначала откройте другой кошелёк.';
  }

  @override
  String get deskConLabelTitle => 'Метка';

  @override
  String get deskConLabelWallet => 'Просто кошелёк';

  @override
  String get deskConLabelExchange => 'Биржа';

  @override
  String get deskConLabelVendor => 'Продавец';

  @override
  String get deskConLabelService => 'Сервис';

  @override
  String get deskConLabelDefault => 'По умолчанию';

  @override
  String deskConLabelCurrent(String name) {
    return 'Метка: $name';
  }
}
