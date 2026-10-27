// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Mobile';

  @override
  String get appTitleDesktop => 'Epic Cash Desktop';

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
  String get txRestoredFunds => 'Восстановленные средства';

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
  String get txEditFromHelper =>
      'Не проверено. Не используется для подтверждений платежа.';

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
          'В файле другие сведения для платежей, которые вы описали: $n. Ваши сохраняются, если не выберете иначе.',
      many:
          'В файле другие сведения для платежей, которые вы описали: $n. Ваши сохраняются, если не выберете иначе.',
      few:
          'В файле другие сведения для платежей, которые вы описали: $n. Ваши сохраняются, если не выберете иначе.',
      one:
          'В файле другие сведения для платежей, которые вы описали: $n. Ваши сохраняются, если не выберете иначе.',
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
  String get txStatusFromBackup => 'Импортирован, статус неизвестен';

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
    return 'Восстановленные средства: $amount';
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
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return 'Этот файл данных кошелька из сети $fileNetwork, а этот кошелёк работает в сети $walletNetwork.';
  }

  @override
  String get networkMainnet => 'Mainnet';

  @override
  String get networkFloonet => 'Floonet';

  @override
  String get networkUsernet => 'Usernet';

  @override
  String get networkMainnetDescription =>
      'Основная сеть Epic Cash с настоящими монетами.';

  @override
  String get networkFloonetDescription =>
      'Публичная тестовая сеть, чтобы попробовать приложение. Её монеты ничего не стоят; бесплатные можно получить на floo-explorer.btlabs.uk.';

  @override
  String get networkUsernetDescription =>
      'Тестовая сеть на этом компьютере, для разработчиков.';

  @override
  String networkTestSuffix(String network) {
    return ' ($network, тестовые монеты)';
  }

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
    return 'Сканирование блокчейна ($percent%)';
  }

  @override
  String get scanComplete => 'Сканирование завершено';

  @override
  String get languageSetting => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

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
    return 'Платёж ждёт уже $_temp0. Сервер epicbox удаляет платежи через 7 дней, поэтому этот платёж уже не завершится. Отмените его, чтобы разблокировать средства, а затем отправьте снова.';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Отправлено в epicbox получателя. Платёж завершится, когда кошелёк получателя появится в сети. До этого или до отмены ваши средства остаются заблокированными.';

  @override
  String get txDetailsWaitingRecipient =>
      'Ожидается ответ получателя с файлом транзакции. До этого или до отмены ваши средства остаются заблокированными.';

  @override
  String get txDetailsWaitingSender =>
      'Вы приняли этот платёж. Он будет выполнен, когда отправитель завершит его и опубликует в сети.';

  @override
  String get txDetailsSenderPosted =>
      'По словам отправителя, этот платёж отправлен в сеть. Он будет выполнен, когда блокчейн его подтвердит.';

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
      'Отменено. Ничего не оплачено, средства снова доступны. Если получатель уже получил платёж, его кошелёк может ещё показывать его как ожидающий; завершить его больше нельзя.';

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
  String get txDetailsNotConfirmedYet => 'Пока не подтверждено';

  @override
  String get txWaitNoNewBlock => 'Ожидание следующего блока.';

  @override
  String get txWaitNotInBlock =>
      'Пока не в блоке. Платёж, возможно, ещё на пути в сеть.';

  @override
  String get txDetailsStuckBody =>
      'Сеть ещё не приняла этот платёж. Повторная отправка безопасна: один и тот же платёж не может пройти дважды.';

  @override
  String get txDetailsBroadcastAgain => 'Отправить повторно';

  @override
  String get txDetailsBroadcastAgainDone =>
      'Отправлено повторно. Подтверждение ожидается в течение нескольких минут.';

  @override
  String get txDetailsRefusedBody =>
      'Сеть отклонила этот платёж, и он не попал в блокчейн. Вы можете разблокировать средства, которые он удерживает.';

  @override
  String get txDetailsReleaseFunds => 'Разблокировать средства';

  @override
  String get txDetailsReleaseTitle => 'Разблокировать средства?';

  @override
  String get txDetailsReleaseBody =>
      'Делайте это, только если платёж точно не подтвердится. Если он всё же подтвердится, баланс может отображаться неверно до повторного сканирования.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Подождать ещё';

  @override
  String get txDetailsFundsReleased => 'Средства разблокированы';

  @override
  String get txDetailsCancelPayment => 'Отменить платёж';

  @override
  String get txDetailsCancelTitle => 'Отменить платёж?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Отправитель, возможно, уже опубликовал платёж. Кошелёк сначала спрашивает узел и отменяет только платёж, которого нет в сети. Если отправитель опубликует его позже, он всё равно поступит.';

  @override
  String get txDetailsCancelSendBody =>
      'Кошелёк получателя не может завершить этот платёж без вашего. Отмена освобождает ваши монеты.';

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
  String get txDetailsNoteLabel => 'Заметка';

  @override
  String get txDetailsPrivateNoteLabel =>
      'Личная заметка, только на этом устройстве';

  @override
  String get txDetailsMessageFromSender => 'Сообщение отправителя';

  @override
  String get txDetailsMessageFromRecipient => 'Сообщение получателя';

  @override
  String get txDetailsYourMessage => 'Ваше сообщение';

  @override
  String get txDetailsNoNote =>
      'Заметки нет. Добавьте её, чтобы помнить, за что этот платёж.';

  @override
  String get txDetailsAddNote => 'Добавить заметку';

  @override
  String get txDetailsEditNote => 'Изменить заметку';

  @override
  String get txDetailsNoteDialogTitle => 'Заметка';

  @override
  String get txDetailsNoteHelper =>
      'Хранится только на этом устройстве и в экспортированных данных кошелька.';

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
      'Найден при сканировании блокчейна. Такие сведения, как отправитель и комиссия, в блокчейне не хранятся; импортируйте данные кошелька, чтобы восстановить их.';

  @override
  String get txDetailsSourceImported =>
      'Импортирован из файла данных кошелька. У этого кошелька нет собственной записи о нём, поэтому его статус может быть устаревшим.';

  @override
  String get historyTitle => 'История';

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
      'Сохраните копию вне телефона, например в почте или облаке';

  @override
  String get historyBackupSaveToDevice => 'Сохранить на устройстве';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Имеет смысл, только если вы также скопируете файл с телефона.';

  @override
  String historyBackupSaved(String fileName) {
    return 'Сохранено: $fileName';
  }

  @override
  String get historyBackupExportTitle => 'Экспорт данных кошелька';

  @override
  String get historyBackupExportNote =>
      'Файл содержит всё на текущий момент. После новых платежей или изменений экспортируйте его снова.';

  @override
  String get historyBackupCsvTitle => 'Экспорт в CSV';

  @override
  String get historyBackupCsvWarning =>
      'Файл CSV не зашифрован. Любой, кто его получит, увидит ваши суммы, даты, адреса и заметки. Импортировать его обратно нельзя; для этого используйте «Экспорт данных кошелька».';

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
  String get shellTitle => 'Epic Cash Mobile';

  @override
  String get demoWelcomeTitle => 'Попробуйте Epic Cash';

  @override
  String get demoWelcomeLine =>
      'Настоящий кошелёк с бесплатными тестовыми монетами, которые ничего не стоят. Он удаляется через 24 часа.';

  @override
  String get demoStart => 'Начать демо';

  @override
  String get demoEndedTitle => 'Ваше демо закончилось';

  @override
  String get demoEndedBody => 'Его кошелёк и тестовые монеты удалены.';

  @override
  String get demoStartAgain => 'Начать заново';

  @override
  String demoEndsAt(String time) {
    return 'Ваше демо закончится $time. Тогда его кошелёк и тестовые монеты будут удалены.';
  }

  @override
  String get demoEndingSoon =>
      'Ваше демо закончится через 30 минут. Тогда его кошелёк и тестовые монеты будут удалены.';

  @override
  String get demoTestCoins => 'Получить тестовые монеты';

  @override
  String get demoTestCoinsPaid =>
      'Тестовые монеты в пути. Они придут через минуту-две.';

  @override
  String demoTestCoinsCooldown(int seconds) {
    return 'Крану нужна пауза. Попробуйте снова через $seconds с.';
  }

  @override
  String get demoTestCoinsFailed =>
      'На этот раз кран ничего не отправил. Попробуйте снова через минуту.';

  @override
  String get demoEnd => 'Завершить демо';

  @override
  String get demoEndTitle => 'Завершить демо?';

  @override
  String get demoEndBody =>
      'Демо-кошелёк и его тестовые монеты будут удалены сейчас. Потом можно начать новое демо.';

  @override
  String get demoServerUnreachable =>
      'Не удаётся связаться с демо-сервером. Проверьте подключение и попробуйте снова.';

  @override
  String demoStartFull(int minutes) {
    return 'Сейчас демо заполнено. Попробуйте снова через $minutes мин.';
  }

  @override
  String demoStartTooMany(int minutes) {
    return 'Из вашей сети запущено слишком много демо. Попробуйте снова через $minutes мин.';
  }

  @override
  String get demoConnectionLost => 'Соединение потеряно, переподключение.';

  @override
  String get demoConnectionBack => 'Соединение восстановлено.';

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
  String get homeSeeAll => 'Все';

  @override
  String get homeBackedUpNotice => 'Фраза восстановления сохранена';

  @override
  String get homeNoticeView => 'Открыть';

  @override
  String get homePushNotice =>
      'В вашем epicbox ждёт платёж. Он поступит, как только приложение подключится.';

  @override
  String get homeNoticeReceived =>
      'Платёж в пути. Он поступит, когда отправитель его завершит.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return '$who отправляет вам платёж. Он поступит, когда отправитель его завершит.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount в пути. Платёж поступит, когда отправитель его завершит.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$who отправляет вам $amount. Платёж поступит, когда отправитель его завершит.';
  }

  @override
  String get homeNoticeSenderPosted => 'Отправитель сообщил об отправке.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Отправитель: $amount отправлено.';
  }

  @override
  String get homeNoticeFinished => 'Платёж завершён. Ожидаются подтверждения.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Платёж завершён, получатель: $who. Ожидаются подтверждения.';
  }

  @override
  String get homeNoticeRepeated =>
      'Этот платёж уже принят. Отправитель снова получил тот же ответ; второго платежа не будет.';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return 'Платёж от $who уже принят. Отправитель снова получил тот же ответ; второго платежа не будет.';
  }

  @override
  String get homeNoticeDelayed =>
      'Не удаётся подключиться к узлу. Платёж будет завершён, как только это станет возможно.';

  @override
  String get homeNoticeRelayProblem =>
      'Сервер epicbox сообщил о проблеме. Пробуем снова.';

  @override
  String get homeNoticePaymentFailed => 'Не удалось завершить платёж.';

  @override
  String get homeBackupCardText => 'Сохраните фразу восстановления.';

  @override
  String get homeBackupCardButton => 'Сохранить';

  @override
  String get homeBackupCardDismiss => 'Скрыть';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа не входят в экспортированные данные кошелька',
      many: '$count платежей не входят в экспортированные данные кошелька',
      few: '$count платежа не входят в экспортированные данные кошелька',
      one: '$count платёж не входит в экспортированные данные кошелька',
    );
    return '$_temp0. Фраза восстановления вернёт только баланс.';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count платежа добавлены или изменены после последнего экспорта данных кошелька',
      many:
          '$count платежей добавлены или изменены после последнего экспорта данных кошелька',
      few:
          '$count платежа добавлены или изменены после последнего экспорта данных кошелька',
      one:
          '$count платёж добавлен или изменён после последнего экспорта данных кошелька',
    );
    return '$_temp0. Фраза восстановления вернёт только баланс.';
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
  String get homeShowBalances => 'Показать баланс';

  @override
  String get homeHideBalances => 'Скрыть баланс';

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
  String get homeBalanceImmature => 'Награды за майнинг (пока недоступны)';

  @override
  String get balanceImmatureHelp =>
      'Награды за майнинг ждут определённое число блоков, прежде чем их можно потратить.';

  @override
  String get balanceLineAllConfirmed => 'Всё подтверждено';

  @override
  String get balanceLineNothingYet => 'Пока ничего нет';

  @override
  String get homeSyncSyncing => 'Синхронизация…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'Синхронизация… $percent%';
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
    return 'Синхронизация узла $percent%';
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
  String statusNodeTestNetwork(String network) {
    return '$network, тестовые монеты';
  }

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
  String get homeEpicboxConnecting => 'Подключение к epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Синхронизировано на блоке $height';
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
  String homePendingBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$amount ждёт ответа кошельков получателей. До тех пор средства заблокированы. Если кто-то не ответит, откройте платёж и нажмите «Отменить платёж».',
      many:
          '$amount ждёт ответа кошельков получателей. До тех пор средства заблокированы. Если кто-то не ответит, откройте платёж и нажмите «Отменить платёж».',
      few:
          '$amount ждёт ответа кошельков получателей. До тех пор средства заблокированы. Если кто-то не ответит, откройте платёж и нажмите «Отменить платёж».',
      one:
          '$amount ждёт ответа кошелька получателя. До тех пор средства заблокированы. Если ответа не будет, откройте платёж и нажмите «Отменить платёж».',
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
  String get homeNoPayments => 'Платежей пока нет.';

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
      'Запросов нет. Когда сопряжённый контакт, которому вы разрешили, попросит об оплате, запрос появится здесь, и ничего не будет оплачено без вашего одобрения.';

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
  String get invoiceReviewNote =>
      'Кошелёк добавит сетевую комиссию. Ничего не оплачивается, пока вы не одобрите.';

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
    return 'Сервис $service отозвал этот счёт после оплаты. Если платёж не подтвердится, отмените его, чтобы разблокировать средства.';
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
      'Плательщик увидит это сообщение вместе с запросом.';

  @override
  String get requestButton => 'Запросить';

  @override
  String get invoicesToPaySection => 'К оплате';

  @override
  String get invoicesNoneToPay => 'Нечего оплачивать.';

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
  String get issuedWithdrawTitle => 'Отозвать этот запрос?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer больше не сможет его оплатить. Ничего не оплачено, монеты не перемещаются. Это нельзя отменить.';
  }

  @override
  String get issuedWithdrawKeep => 'Оставить';

  @override
  String get issuedDetailsSection => 'Запрос платежа';

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
      'Плательщик отклонил этот запрос, поэтому он отозван. Ничего не оплачено.';

  @override
  String get issuedDetailsWithdrawn =>
      'Вы отозвали этот запрос. Ничего не оплачено.';

  @override
  String get issuedDetailsExpired =>
      'Срок этого запроса истёк до оплаты. Ничего не оплачено.';

  @override
  String get issuerNoticePaid => 'Один из ваших запросов оплачен.';

  @override
  String get issuerNoticeDeclined => 'Один из ваших запросов отклонён.';

  @override
  String get issuerNoticeWithdrawn =>
      'Запрос отозван. Его больше нельзя оплатить.';

  @override
  String get issuerNoticeExpired =>
      'Срок одного из ваших запросов истёк без оплаты.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Кошелёк $payer не умеет оплачивать запросы и вернул ваш, поэтому он отозван. Попросите этого человека отправить вам платёж обычным способом: на ваш адрес или платёжным файлом.';
  }

  @override
  String get issuedBounced => 'Возвращён';

  @override
  String get issuedDetailsBounced =>
      'Кошелёк плательщика не умеет оплачивать запросы и вернул этот, поэтому он отозван. Ничего не оплачено. Попросите этого человека отправить вам платёж обычным способом: на ваш адрес или платёжным файлом.';

  @override
  String get txStatusWaitingPayer => 'Ждёт плательщика';

  @override
  String get txStepRequested => 'Запрошено';

  @override
  String get txStepPaid => 'Оплачено';

  @override
  String get txDetailsWaitingPayer =>
      'Вы запросили этот платёж. Пока ничего не поступило: платёж придёт, когда плательщик оплатит запрос.';

  @override
  String get txDetailsRequestEnded =>
      'Этот запрос завершён без оплаты. Ничего не поступило.';

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
  String get receiveEpicboxConnected => 'Epicbox подключён';

  @override
  String get receiveQrLabel => 'QR-код вашего адреса';

  @override
  String get receiveAddressLabel => 'Адрес Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'Отправленные вам платежи сейчас ждут в epicbox и придут, когда кошелёк снова подключится.';

  @override
  String get receiveShareCardHeadline => 'Заплатите мне в Epic Cash';

  @override
  String get receiveHelpButton => 'Как работает получение';

  @override
  String get receiveAddressCopied => 'Адрес скопирован';

  @override
  String get receiveFileTitle => 'Получить по платёжному файлу';

  @override
  String get receiveFileBody =>
      'Получили платёжный файл? Откройте его или скопируйте его текст и вставьте сюда.';

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
    return 'Загрузка версии $version… $percent%';
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
      'Разрешите установку из Epic Cash Mobile, затем вернитесь.';

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
  String get updateManifestNotJson =>
      'Сведения об обновлении не являются корректным JSON.';

  @override
  String get updateManifestWrongShape =>
      'Сведения об обновлении имеют неверную структуру.';

  @override
  String get updateManifestOtherApp =>
      'Сведения об обновлении относятся к другому приложению.';

  @override
  String get updateManifestNoApks =>
      'В сведениях об обновлении нет ни одного APK.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'Ошибка загрузки (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge =>
      'Загруженный файл больше заявленного размера.';

  @override
  String get updateDownloadIncomplete => 'Файл загружен не полностью.';

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
  String get setupNodeUrlLabel => 'URL узла';

  @override
  String get setupCustomRelayLabel =>
      'Другой сервер epicbox (хост или host:port)';

  @override
  String get setupCustomRelayInvalid =>
      'Введите хост, например epicbox.example.com';

  @override
  String get setupWalletPerNetwork =>
      'У каждой сети свой кошелёк. Для сети без кошелька будет создан новый.';

  @override
  String get setupRelayHealthyIconLabel => 'Работает';

  @override
  String get setupRelayDownIconLabel => 'Не работает';

  @override
  String get setupRelayHealthUnavailable =>
      'Не удалось получить состояние серверов с status.btlabs.uk.';

  @override
  String get setupRelayHealthSource =>
      'Состояние по данным status.btlabs.uk, проверка ведётся с его сервера.';

  @override
  String get setupRelayNotMonitored => 'Не отслеживается';

  @override
  String get setupRelayUp => 'Работает';

  @override
  String get setupRelayDown => 'Не работает';

  @override
  String get setupRelayOfficial => 'официальный';

  @override
  String setupRelayUptime(String percent) {
    return 'доступность $percent% за сутки';
  }

  @override
  String get restoreTitle => 'Восстановление кошелька';

  @override
  String get restorePhraseLabel => 'Фраза восстановления';

  @override
  String get restorePhraseHelper =>
      'Все слова (12, 15, 18, 21 или 24) через пробел.';

  @override
  String get restoreStartHeading => 'Начало сканирования';

  @override
  String get restoreStartByDate => 'Дата';

  @override
  String get restoreStartByHeight => 'Высота блока';

  @override
  String get restoreStartHeightLabel => 'Начальная высота (необязательно)';

  @override
  String get restoreStartHeightHelper =>
      'Сканировать с этого блока. Оставьте пустым, чтобы просканировать весь блокчейн.';

  @override
  String get restoreStartHeightInvalid =>
      'Начальная высота должна быть целым числом.';

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
      'Необязательно. Если не уверены, выберите более раннюю дату. Если дата позже вашего первого платежа, часть средств не найдётся. Без даты сканируется весь блокчейн, это дольше.';

  @override
  String restoreDateStart(String height) {
    return 'Сканирование начнётся за два дня до этой даты, с блока $height.';
  }

  @override
  String get restoreWholeChain => 'Сканировать весь блокчейн';

  @override
  String get restoreScanIntro =>
      'Ищем ваши средства в блокчейне. Не закрывайте приложение до завершения.';

  @override
  String get restoreOpenWallet => 'Открыть кошелёк';

  @override
  String get restoreUnfinishedTitle => 'Восстановление не завершено';

  @override
  String get restoreUnfinishedRunning =>
      'Поиск средств этого кошелька с блока 0. Получение и отправка станут доступны после завершения.';

  @override
  String get restoreUnfinishedOffline =>
      'Сканирование продолжится, когда офлайн-режим будет выключен.';

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
      'Средства после выбранного начала найдены. Сканирование с блока 0 завершает восстановление на главном экране; получение и отправка станут доступны после его окончания.';

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
      'Фраза восстановления вернула баланс. Файл данных кошелька возвращает историю платежей, контакты, счета и настройки этого кошелька. Если вы его экспортировали, импортируйте сейчас: это файл, который вы отправили или сохранили вне старого телефона.';

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
      'Снимок или фото фразы — это полная копия вашего кошелька: любой, кто его увидит, сможет забрать ваши средства, а приложения для фото могут загрузить его в облако. Бумага надёжнее всего.';

  @override
  String get backupCopyAgree => 'Я буду хранить любую копию фразы в тайне';

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
          'Запишите эти $count слова на бумаге по порядку и никому их не показывайте. Только с их помощью можно восстановить этот кошелёк.',
      many:
          'Запишите эти $count слов на бумаге по порядку и никому их не показывайте. Только с их помощью можно восстановить этот кошелёк.',
      few:
          'Запишите эти $count слова на бумаге по порядку и никому их не показывайте. Только с их помощью можно восстановить этот кошелёк.',
      one:
          'Запишите это $count слово на бумаге по порядку и никому их не показывайте. Только с его помощью можно восстановить этот кошелёк.',
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
  String get pinlessUnlock => 'Разблокировать';

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
  String get pinBiometricsQuestion =>
      'Разблокировать отпечатком пальца или лицом?';

  @override
  String get pinBiometricsPinStillWorks =>
      'PIN-код по-прежнему можно использовать в любой момент.';

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
  String get sendUrlUnsupported =>
      'Платежи на URL кошелька не поддерживаются. Попросите у получателя его адрес epicbox.';

  @override
  String get scanQrTooltip => 'Сканировать QR-код';

  @override
  String get sendScanButton => 'Сканировать';

  @override
  String get sendChooseContactTooltip => 'Выбрать контакт';

  @override
  String get sendContactsButton => 'Контакты';

  @override
  String get sendMethodEpicbox => 'Адрес Epicbox';

  @override
  String get sendMethodFile => 'Платёжный файл';

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
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
  }

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
  String get scanQrCameraDenied =>
      'У кошелька нет доступа к камере. Чтобы сканировать, разрешите этому приложению доступ к камере в настройках телефона. Можно также вставить адрес вручную.';

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
  String qrTimedOutAnnounce(int seconds) {
    return 'Скрыт через $seconds секунд';
  }

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
  String get qrScanGot => 'Готово';

  @override
  String qrScanCount(int got, int count) {
    return '$got из $count';
  }

  @override
  String get qrScanCountLabel => 'Прочитанные части';

  @override
  String get qrScanNotPayment =>
      'Это не QR платежа. Попросите их показать код платежа на своём телефоне.';

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
      'У кошелька нет доступа к камере. Чтобы сканировать, разрешите этому приложению доступ к камере в настройках телефона. Можно также открыть файл.';

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
  String get methodQrChip => 'QR-код';

  @override
  String get receiveTabQr => 'QR-код';

  @override
  String get methodArtCaptionQr => 'Лично';

  @override
  String get methodArtLabelQr =>
      'Напрямую · Оплата по QR: код передаётся с одного телефона на другой, стоящий рядом';

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
      'Отсканируйте платёж с их экрана и покажите свой ответ, или запросите сумму и покажите её кодом для сканирования.';

  @override
  String get txQrLine =>
      'Платите или получайте платёж рядом друг с другом, по коду на экране.';

  @override
  String get txQrHint =>
      'Оплата по QR показывает платёж как анимированный код, который другой телефон сканирует камерой, а ответ принимает так же. Работает только между телефонами рядом, не требует связи между двумя кошельками, а код сам скрывается через 40 секунд. Добавляет «Оплата по QR» в «Отправить» и «Получить».';

  @override
  String get advTransactionFiles => 'Передача файла';

  @override
  String get advTransactionFilesHint =>
      'Добавляет «Передачу файла» в Настройки › Транзакции: платите или получайте платежи файлом, который вы передаёте сами.';

  @override
  String get sendQrTitle => 'Оплата по QR';

  @override
  String get sendMakeQr => 'Создать QR платежа';

  @override
  String sendQrPinReason(String amount) {
    return 'Введите PIN, чтобы создать QR платежа на $amount.';
  }

  @override
  String get sendQrMade => 'Платёж создан';

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
  String get qrStatusHiddenAgain =>
      'Скрыт. Покажите снова, если они не успели отсканировать.';

  @override
  String get qrStatusReplyHidden => 'Покажите это отправителю.';

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
  String get contactsEmpty =>
      'Контактов пока нет. Добавьте тех, кому часто платите, чтобы не вставлять их адрес каждый раз.';

  @override
  String get contactsSearchLabel => 'Поиск контактов';

  @override
  String get contactsNoMatch => 'Контакты не найдены.';

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
      'Недействительный адрес. Используйте адрес Epicbox (es5x…@epicbox.epiccash.com), адрес ссылки (https://…) или onion-адрес (….onion).';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionNetwork => 'Серверы';

  @override
  String get settingsSectionDisplay => 'Отображение';

  @override
  String get settingsCurrency => 'Валюта';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Показывать цены';

  @override
  String get settingsHideBalances => 'Скрывать баланс';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Как на устройстве';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsPricesOnNotice =>
      'Цены берутся из CoinGecko; этот сервис видит ваш IP-адрес.';

  @override
  String get settingsSectionNotifications => 'Уведомления';

  @override
  String get settingsPushBlocked =>
      'Уведомления заблокированы в настройках системы';

  @override
  String get settingsPushUnavailable => 'Уведомления недоступны в этой сборке';

  @override
  String get settingsSectionSecurity => 'Безопасность';

  @override
  String get settingsChangePin => 'Изменить PIN-код';

  @override
  String get settingsBiometrics => 'Разблокировка биометрией';

  @override
  String get settingsBiometricsOn => 'Биометрическая разблокировка включена';

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
  String get settingsSectionWallet => 'Кошелёк';

  @override
  String get settingsContacts => 'Контакты';

  @override
  String get settingsSectionInvoices => 'Счета';

  @override
  String get settingsInvoices => 'Счета';

  @override
  String get settingsInvoicesSubtitle => 'Кто может просить вас об оплате';

  @override
  String get settingsRescan => 'Сверка баланса';

  @override
  String get settingsRescanFinished => 'Повторное сканирование завершено';

  @override
  String get settingsRescanTitle => 'Сверка баланса';

  @override
  String get settingsRescanBody =>
      'Кошелёк заново ищет свои средства. Чем раньше начало, тем больше найдётся, но тем дольше это займёт; сканирование всего блокчейна может занять много времени.';

  @override
  String get settingsRescanFromDate => 'С даты';

  @override
  String get settingsRescanFromHeight => 'С высоты блока';

  @override
  String get settingsRescanWholeChain => 'Весь блокчейн';

  @override
  String get settingsRescanPickDate => 'Выбрать дату';

  @override
  String get settingsRescanPickDateFirst => 'Сначала выберите дату.';

  @override
  String get settingsRescanStartHeight => 'Начальная высота';

  @override
  String get settingsRescanHeightInvalid => 'Введите высоту блока не меньше 1.';

  @override
  String get settingsRescanButton => 'Сканировать';

  @override
  String get settingsDeleteWallet => 'Удалить этот кошелёк';

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
      'Кошелёк, его история и PIN-код будут удалены с этого устройства. Вернуть средства можно только с помощью фразы восстановления. Без неё они будут потеряны навсегда.';

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
  String get settingsHelp => 'Справка';

  @override
  String get settingsSendFeedback => 'Отправить отзыв';

  @override
  String get settingsSendFeedbackHint =>
      'Сообщите о проблеме или предложите разработчикам идею. Журналы отправляются, только если вы их приложите; фраза восстановления, PIN-код и другие секретные данные удаляются заранее.';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsLicences => 'Лицензии';

  @override
  String get licencesLead =>
      'Открытое ПО в этом кошельке. Каждый компонент сохраняет свою лицензию; полные тексты в одном касании.';

  @override
  String get licencesApp => 'Epic Cash Mobile от BT Labs: Apache-2.0.';

  @override
  String get licencesFlutter =>
      'Flutter и его пакеты Dart: BSD 3-Clause и похожие разрешительные лицензии.';

  @override
  String get licencesLepic =>
      'LEPIC, библиотека кошелька Epic Cash: Apache 2.0, с форком secp256k1-zkp от Epic Cash (CC0) и крейтами Rust под MIT или Apache 2.0, среди них tokio, rustls, rusqlite и blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, версия 3. Исходный код указан ниже.';

  @override
  String get licencesFonts =>
      'Шрифты Montserrat, JetBrains Mono и Noto Sans Thai: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'Все тексты лицензий';

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
  String get helpSendFeedback => 'Отправить отзыв';

  @override
  String get feedbackTitle => 'Отправить отзыв';

  @override
  String get feedbackIntro =>
      'Расскажите, что пошло не так или что можно улучшить.';

  @override
  String get feedbackMessageLabel => 'Ваше сообщение';

  @override
  String get feedbackMessageMissing =>
      'Напишите пару слов о том, что произошло.';

  @override
  String get feedbackEmailLabel => 'Эл. почта для ответа (необязательно)';

  @override
  String get feedbackEmailInvalid =>
      'Это не похоже на адрес электронной почты.';

  @override
  String get feedbackAttachLogs => 'Приложить журналы диагностики';

  @override
  String get feedbackAttachLogsHint =>
      'Журналы помогают найти проблему. Фраза восстановления, PIN-код и другие секретные данные удаляются заранее.';

  @override
  String get feedbackPreviewButton => 'Посмотреть, что будет отправлено';

  @override
  String get feedbackSend => 'Отправить';

  @override
  String get feedbackShareOrSaveInstead => 'Поделиться или сохранить файл';

  @override
  String get feedbackFileExplanation =>
      'Ваш отзыв будет сохранён в текстовый файл, который можно отправить по почте или в мессенджере либо сохранить.';

  @override
  String get feedbackShareOrSave => 'Поделиться или сохранить';

  @override
  String get feedbackShareHint => 'Отправьте по почте или в мессенджере';

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
  String get settingsAdvancedOptions => 'Расширенные настройки';

  @override
  String get settingsAdvancedOptionsSubtitle =>
      'Показывает техническую сторону: сведения об узле и сервере Epicbox, высоты блоков, файлы транзакций и журналы. Если выключено, приложение ограничивается тем, что нужно каждый день.';

  @override
  String get settingsSectionPrivacy => 'Приватность';

  @override
  String get settingsSectionPrivacyNetwork => 'Приватность и сеть';

  @override
  String get settingsSectionHelpFeedback => 'Справка и отзывы';

  @override
  String get settingsStateBackUp => 'Сохраните фразу восстановления';

  @override
  String get settingsStateNotBackedUp => 'Ещё не сохранена';

  @override
  String get settingsHubBackup => 'Резервная копия';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'Использовать status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Читает со status.btlabs.uk, монитора BT Labs, какие узлы и серверы Epicbox в сети, их высоту блока и время ответа, и показывает это в списках серверов и на карточке состояния. Если выключено, status.btlabs.uk не опрашивается, а списки серверов не показывают состояние.';

  @override
  String get txStepStarted => 'Платёж начат';

  @override
  String get txStepAccepted => 'Получатель принял';

  @override
  String get txStepPosted => 'Отправлен в сеть';

  @override
  String get txStepConfirming => 'Подтверждение';

  @override
  String get txStepConfirmed => 'Подтверждён';

  @override
  String get txStepArrived => 'Платёж получен';

  @override
  String get txStepSenderFinished => 'Отправитель завершил его';

  @override
  String get fileHelpTitle => 'Как работает платёжный файл';

  @override
  String get fileHelpYou => 'Вы';

  @override
  String get fileHelpFriend => 'Друг';

  @override
  String get fileHelpSendStep1 => 'Вы создаёте платёжный файл.';

  @override
  String get fileHelpSendStep2 =>
      'Вы отправляете его другу любым удобным способом, например в чате или по почте.';

  @override
  String get fileHelpSendStep3 =>
      'Друг открывает его в своём кошельке и присылает вам подписанный ответ.';

  @override
  String get fileHelpSendStep4 => 'Вы открываете ответ, и платёж уже в пути.';

  @override
  String get fileHelpReceiveStep1 => 'Друг создаёт для вас платёжный файл.';

  @override
  String get fileHelpReceiveStep2 =>
      'Он отправляет его вам любым удобным способом, например в чате или по почте.';

  @override
  String get fileHelpReceiveStep3 =>
      'Вы открываете его в своём кошельке и отправляете подписанный ответ.';

  @override
  String get fileHelpReceiveStep4 =>
      'Друг открывает ответ, и платёж уже в пути к вам.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Шаг $step из $count';
  }

  @override
  String get fileHelpPause => 'Приостановить анимацию';

  @override
  String get fileHelpPlay => 'Воспроизвести анимацию';

  @override
  String get demoPinFilled => 'Демо-PIN введён за вас';

  @override
  String get demoPinSkip => 'Пропустить';

  @override
  String get demoPinSetUpTitle => 'Настраиваем ваш демо-кошелёк';

  @override
  String get demoPinUnlockTitle => 'Открываем ваш демо-кошелёк';

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
  String get sendAddressLabel => 'Адрес Epic';

  @override
  String get sendAddressMissing => 'Введите адрес получателя.';

  @override
  String get sendAddressWebLink => 'Это веб-ссылка, а не адрес Epic.';

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
  String get sendUseFile => 'Нет адреса? Используйте платёжный файл';

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
  String get sendAddNote => 'Добавить заметку';

  @override
  String get sendNoteLabel => 'Заметка';

  @override
  String get sendNoteHelper => 'Получатель тоже её увидит.';

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
  String sendTrackSentTo(String name) {
    return 'Отправлено: $name';
  }

  @override
  String get sendTrackSent => 'Отправлено';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Ждём кошелёк: $name';
  }

  @override
  String get sendTrackWaiting => 'Ждём кошелёк получателя';

  @override
  String sendTrackSignedBy(String name) {
    return 'Кошелёк $name подписал';
  }

  @override
  String get sendTrackSigned => 'Кошелёк получателя подписал';

  @override
  String get sendTrackOnNetwork => 'Отправлено в сеть';

  @override
  String get sendTrackConfirmed => 'Подтверждено';

  @override
  String sendTrackOffline(String amount) {
    return 'Кошелёк получателя завершит платёж, когда откроется. До тех пор $amount заблокировано.';
  }

  @override
  String get sendTrackIfNot => 'А если платёж не завершится?';

  @override
  String get sendTrackCancelled => 'Этот платёж отменён.';

  @override
  String get sendNoCoins => 'Пока нет монет для отправки.';

  @override
  String get sendFileTitle => 'Оплата файлом';

  @override
  String get sendMakeFile => 'Создать платёжный файл';

  @override
  String get sendFileMade => 'Файл создан';

  @override
  String sendFileOnHold(String amount) {
    return '$amount заблокировано';
  }

  @override
  String get sendFileWaitingReply => 'Ждём ответный файл';

  @override
  String get sendFileShareHint =>
      'Отправьте им этот файл, затем откройте их ответ.';

  @override
  String get sendOpenReply => 'Открыть ответ';

  @override
  String get handshakePayment => 'Платёж';

  @override
  String get handshakeRequest => 'Запрос';

  @override
  String get handshakeYou => 'Вы';

  @override
  String get handshakeThem => 'Они';

  @override
  String get handshakeNetwork => 'Сеть';

  @override
  String get handshakePay1 =>
      'Ваш кошелёк отправляет платёж на ретранслятор. Ваши монеты блокируются.';

  @override
  String get handshakePay2 =>
      'Ретранслятор передаёт его дальше. Их кошелёк добавляет свою часть и подписывает.';

  @override
  String get handshakeFinish =>
      'Ваш кошелёк завершает его и отправляет в сеть.';

  @override
  String get handshakeConfirm => 'Сеть его подтверждает.';

  @override
  String get handshakeReq1 => 'Ваш кошелёк отправляет запрос на ретранслятор.';

  @override
  String get handshakeReq2 =>
      'Ретранслятор передаёт его дальше. Они одобряют его, их кошелёк добавляет монеты и подписывает.';

  @override
  String get handshakeRelay => 'Ретранслятор';

  @override
  String get handshakeFile => 'Передача файла';

  @override
  String get handshakeBack =>
      'Их кошелёк отправляет его обратно на ретранслятор.';

  @override
  String get handshakeRelayBack =>
      'Ретранслятор передаёт его обратно вашему кошельку.';

  @override
  String get handshakeFile1 =>
      'Ваш кошелёк сохраняет платёжный файл. Вы сами отправляете его им.';

  @override
  String get handshakeFile2 =>
      'Они открывают его. Их кошелёк добавляет свою часть, подписывает и сохраняет ответ.';

  @override
  String get handshakeFile3 => 'Они отправляют вам файл ответа.';

  @override
  String get handshakeFile4 => 'Вы открываете их ответ в своём кошельке.';

  @override
  String get handshakePrevious => 'Предыдущий шаг';

  @override
  String get handshakeLink1 =>
      'Ваш кошелёк отправляет платёж прямо их кошельку, через интернет или Tor. Ваши монеты блокируются.';

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
          'Сервер Epicbox получателя ($relay) не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дня.',
      many:
          'Сервер Epicbox получателя ($relay) не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дней.',
      few:
          'Сервер Epicbox получателя ($relay) не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дней.',
      one:
          'Сервер Epicbox получателя ($relay) не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дня.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Сервер Epicbox получателя ($relay) не принял платёж. Проверьте «Кошелёк», прежде чем отправлять снова.';
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
  String get demoTestCoinsPill => 'Тестовые монеты';

  @override
  String get demoTestCoinsPillTip =>
      'Floonet, тестовая сеть Epic. Монеты ничего не стоят.';

  @override
  String demoLeftHours(int hours) {
    return 'осталось $hours ч';
  }

  @override
  String demoLeftMinutes(int minutes) {
    return 'осталось $minutes мин';
  }

  @override
  String get demoReceiveKeepOpen =>
      'Не закрывайте эту вкладку, чтобы получать платежи.';

  @override
  String get demoGuideTitle => 'Попробуйте платёж';

  @override
  String get demoGuideSend => 'Отправьте немного кому-нибудь';

  @override
  String get demoGuideSendHint =>
      'Заплатите в демо друга или откройте эту страницу в другом браузере или приватном окне.';

  @override
  String get demoGuideOpenSend => 'К отправке';

  @override
  String get demoGuideAsking =>
      'Запрашиваем тестовый кран. Это может занять минуту.';

  @override
  String get demoGuideDone => 'Готово. Осматривайтесь, пока идёт демо.';

  @override
  String get demoGuideHide => 'Скрыть';

  @override
  String get demoGuideHideLabel => 'Скрыть шаги демо';

  @override
  String demoGuideStepDone(String step) {
    return '$step, готово';
  }

  @override
  String demoGuideStepToDo(String step) {
    return '$step, ещё не сделано';
  }

  @override
  String get receiveTabEpicbox => 'Epicbox';

  @override
  String get receiveTabTor => 'Tor';

  @override
  String get receiveTabFile => 'Файл';

  @override
  String get receiveTorAddressLabel => 'Адрес Ссылка · Tor';

  @override
  String get receiveTorQrLabel => 'QR-код вашего адреса Tor';

  @override
  String get torReceivingTitle => 'Приём через Tor';

  @override
  String get torHonestLine =>
      'Приём через Tor работает, пока приложение открыто или ненадолго в фоне.';

  @override
  String get torStateOff => 'Приём через Tor выключен';

  @override
  String torStateStarting(int percent) {
    return 'Подключение к Tor… $percent%';
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
      'Не удалось подключиться к сети Tor. Проверьте соединение.';

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
  String get sendTorConnectsOnSend => 'Tor подключается при отправке.';

  @override
  String get sendTorReady => 'Готово к отправке через Tor';

  @override
  String get sendTorReaching =>
      'Связываемся с кошельком получателя через Tor… Это может занять время. Не закрывайте приложение.';

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
  String sendTorNothingSent(String reason) {
    return '$reason Ничего не отправлено.';
  }

  @override
  String get sendTryAgain => 'Повторить';

  @override
  String get sendCancelPayment => 'Отменить платёж';

  @override
  String get settingsSectionReceiving => 'Приём';

  @override
  String get homeAvailableToSpend => 'Доступно';

  @override
  String get homeTileWaitingSender => 'Ожидает отправителя';

  @override
  String get homeTileLocked => 'Заблокировано в отправках';

  @override
  String get homeTileMaturing => 'Награды созревают';

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
  String get tourPhoneSkip => 'Пропустить';

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
      'Вставьте или отсканируйте адрес либо выберите контакт. Epicbox платит на адрес; QR показывает код телефону рядом с вами. Другие способы: Настройки › Транзакции. Сначала — проверка.';

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
  String get tourPhoneContactsTitle => 'Контакты';

  @override
  String get tourPhoneContactsText =>
      'Сохранённые адреса с именами. «Отправить» выбирает отсюда.';

  @override
  String get tourPhoneInvoicesTitle => 'Счета';

  @override
  String get tourPhoneInvoicesText =>
      'Оплатите присланный вам счёт или попросите кого-то о платеже. Вкладки переключают между этим и тем.';

  @override
  String get tourPhonePrivacyTitle => 'Приватность и сеть';

  @override
  String get tourPhonePrivacyText =>
      'Какой узел и сервер Epicbox использует кошелёк, и переключатель Tor. Нажмите на сервер, чтобы изменить его.';

  @override
  String get tourPhoneAdvancedTitle => 'Дополнительно';

  @override
  String get tourPhoneAdvancedText =>
      'Режим «Только Tor», выходы и технические сведения собраны здесь. Включайте то, что нужно.';

  @override
  String get tourPhoneHelpTitle => 'Справка';

  @override
  String get tourPhoneHelpText =>
      'Ищите по темам или отправьте отзыв. «Показать тур снова» — внизу списка.';

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
    return 'Введите PIN-код, чтобы создать платёжный файл на $amount.';
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
  String get outputsImmature => 'Не созрели';

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
  String get outputsWaitLocked =>
      'Дождитесь подтверждения текущей отправки (около 3 блоков).';

  @override
  String get outputsStrategy => 'Стратегия отправок';

  @override
  String get outputsStrategyHint =>
      'Какие выходы тратит отправка. «Наименьшие» тратит как можно меньше мелких выходов, и остальное остаётся доступным, пока сдача подтверждается. «Все» тратит все доступные выходы и возвращает один выход сдачи: всё заблокировано до подтверждения, а потом выходов меньше и они крупнее.';

  @override
  String get outputsSmallest => 'Наименьшие';

  @override
  String get outputsAll => 'Все';

  @override
  String get outputsSmallestText =>
      'Тратит как можно меньше мелких выходов; остальное остаётся доступным, пока сдача подтверждается.';

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
  String get outputsWordFinalizing => 'Ждёт завершения';

  @override
  String get outputsWordImmature => 'Не созрел';

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
  String get outputsEmptyHint =>
      'Первый полученный платёж создаст его. Адрес — на вкладке «Получить».';

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
  ) {
    return 'Тратит $spent ($amount) и создаёт $made по $each. Обычная сетевая транзакция на этот кошелёк, подтверждается через 3 блока, как любая отправка; всё доступное блокируется до этого момента. Несколько выходов позволяют следующим отправкам уходить, не дожидаясь сдачи друг друга.';
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
  String outputsFactLockedValue(String amount) {
    return '$amount, около 3 блоков';
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
  String outputsConsolidateText(String amount, String result, String spent) {
    return 'Тратит $spent ($amount) и создаёт один выход на $result. Обычная сетевая транзакция на этот кошелёк, подтверждается через 3 блока, как любая отправка; всё доступное блокируется до этого момента. Следующая отправка потратит один выход, поэтому её комиссия будет наименьшей.';
  }

  @override
  String get outputsConsolidateAction => 'Объединить';

  @override
  String get outputsSplitPin => 'Подтвердите PIN-кодом, чтобы разделить выходы';

  @override
  String get outputsConsolidatePin =>
      'Подтвердите PIN-кодом, чтобы объединить выходы';

  @override
  String outputsSplitStarted(int count) {
    return 'Разделение начато, выходов: $count; подтверждение примерно через 3 блока';
  }

  @override
  String get outputsConsolidateStarted =>
      'Объединение начато: один выход, подтверждение примерно через 3 блока';

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
  String get invoicesNewRequest => 'Новый запрос';

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
  String get invoicesSentEmpty => 'Запросов не отправлено';

  @override
  String get invoicesSentEmptyCaption =>
      'Запрос просит кого-то заплатить вам сумму.';

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
  String get invoicesNodeOk => 'Отвечает';

  @override
  String get invoicesNodeDown => 'Не отвечает';

  @override
  String get invoicesEpicboxOk => 'Подключено';

  @override
  String get invoicesEpicboxDown => 'Не подключено';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer получит запрос на оплату $amount. Запрос истекает через 24 ч.';
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
    return 'Синхронизация $percent %';
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
  String get netStatusOnline => 'В сети';

  @override
  String get netStatusOff => 'Выключен';

  @override
  String get netStatusConnected => 'Подключено';

  @override
  String get netStatusNotConnected => 'Нет подключения';

  @override
  String get serverUpNotConnected => 'Сервер работает · нет подключения';

  @override
  String get netStatusOn => 'Включён';

  @override
  String get netStatusFailed => 'Ошибка';

  @override
  String netStatusStarting(int percent) {
    return 'Запуск $percent %';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => 'Состояние сети';

  @override
  String get serverMyRelays => 'Мои серверы';

  @override
  String get serverMenuDelete => 'Удалить';

  @override
  String get serverSupportsNotifications => 'Поддерживает уведомления';

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
  String get serverSearchHint => 'Найдите узел';

  @override
  String serverTestFailed(String error) {
    return 'Нет ответа. $error';
  }

  @override
  String get serverMyNodes => 'Мои узлы';

  @override
  String get serverPublicNodes => 'Публичные узлы';

  @override
  String get serverPublicRelays => 'Публичные серверы';

  @override
  String get serverHealthUnknown =>
      'status.btlabs.uk недоступен; состояние неизвестно';

  @override
  String get serverAtTip => 'актуален';

  @override
  String serverBehindShort(String count) {
    return '−$count';
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
  String get serverDegraded => 'Работает с перебоями';

  @override
  String get serverHealthNone => 'Состояние неизвестно';

  @override
  String get serverCurrent => 'Текущий';

  @override
  String get serverDefault => 'По умолчанию';

  @override
  String serverLatency(String ms) {
    return '$ms мс';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % в сети';
  }

  @override
  String get serverRelayWarning =>
      'Ваш адрес содержит этот сервер. При смене сервера адрес изменится; отправителям нужен новый.';

  @override
  String get serverOtherRelay => 'Другой сервер, host или host:port';

  @override
  String get serverMyListNote => 'Используемый сейчас и добавленные вами.';

  @override
  String get serverPublicNote => 'Нажмите, чтобы переключиться.';

  @override
  String get serverOtherNode => 'Другой узел, host или host:port';

  @override
  String get serverOtherNodeInvalid =>
      'Введите адрес узла, например node.example.com:3413';

  @override
  String get serverAdd => 'Добавить';

  @override
  String get serverAddedNode => 'Добавлено в «Мои узлы».';

  @override
  String get serverAddedRelay => 'Добавлено в «Мои серверы».';

  @override
  String serverDeleted(String host) {
    return 'Удалено: $host.';
  }

  @override
  String get serverAlreadyInUse => 'Уже используется.';

  @override
  String get serverNoMatch => 'Ничего не найдено.';

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
    return '$height · актуален';
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
  String serverCheckedAt(String time) {
    return 'status.btlabs.uk, проверено $time';
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
  String get methodArtCaptionTor => 'Напрямую, через Tor';

  @override
  String get methodArtCaptionFile => 'Файл туда, ответ обратно';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: платёж уходит на сервер Epicbox, который хранит его, пока кошелёк получателя не вернётся';

  @override
  String get methodArtLabelHttp =>
      'Ссылка · HTTP: платёж идёт прямо в кошелёк получателя, который должен быть открыт';

  @override
  String get methodArtLabelTor =>
      'Ссылка · Tor: платёж идёт прямо в кошелёк получателя через сеть Tor';

  @override
  String get methodArtLabelFile =>
      'Напрямую · Передача файла: файл транзакции передаётся, возвращается файл ответа, затем отправитель завершает платёж';

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
  String get methodSendHttpLine =>
      'Он должен быть открыт и доступен по своему HTTP-адресу.';

  @override
  String get methodSendTorTitle => 'Прямо в кошелёк получателя, через Tor.';

  @override
  String get methodSendTorLine =>
      'Медленнее и приватнее. Кошелёк получателя должен быть открыт.';

  @override
  String get methodSendFileTitle => 'Соединение не нужно.';

  @override
  String get methodSendFileLine =>
      'Передайте файл, получите файл ответа и завершите платёж здесь.';

  @override
  String get methodReceiveEpicboxTitle =>
      'Поделитесь им, чтобы получить оплату.';

  @override
  String get methodReceiveEpicboxLine =>
      'Работает, пока кошелёк закрыт: сервер Epicbox хранит платежи, пока он не вернётся.';

  @override
  String get methodReceiveTorTitle => 'Медленнее и приватнее.';

  @override
  String get methodReceiveTorLine =>
      'Работает, только пока приложение открыто или ненадолго в фоне.';

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
  String get sendSwitchedHttp => 'Ссылка · HTTP';

  @override
  String get sendSwitchedEpicbox => 'Через Epicbox';

  @override
  String get sendSwitchedTorAnnounce =>
      'Адрес Tor. Выбран способ Ссылка · Tor.';

  @override
  String get sendSwitchedHttpAnnounce =>
      'Адрес HTTP. Выбран способ Ссылка · HTTP.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Адрес Epicbox. Выбран способ Epicbox.';

  @override
  String get sendReviewMethodHttp => 'Ссылка · HTTP, прямо в кошелёк';

  @override
  String get sendCancelRuleEpicbox =>
      'Можно отменить, пока платёж ждёт получателя.';

  @override
  String get sendCancelRuleDirect =>
      'Нельзя отменить после того, как кошелёк получателя его примет.';

  @override
  String get sendCancelRuleFile =>
      'Можно отменить, пока файл ответа не завершён.';

  @override
  String get sendHttpReaching =>
      'Связь с кошельком получателя… Не закрывайте приложение.';

  @override
  String get sendDeliveredWaitingBlock => 'Доставлено · Ждёт блок';

  @override
  String get sendHttpAddressShape =>
      'HTTP-адрес начинается с http:// или https://.';

  @override
  String get sendPlainHttpTitle => 'Без шифрования. Всё равно отправить?';

  @override
  String get sendPlainHttpBody =>
      'Обычный HTTP к другому устройству. Любой на пути может прочитать транзакцию. Адрес https:// зашифрован.';

  @override
  String get receiveEpicboxCaption =>
      'Читая его вслух, сверьте первые шесть и последние шесть символов.';

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
  String deskInvTabCount(String label, int count) {
    return '$label ($count)';
  }

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
      'Списки показывают то, что пришло раньше. Ничего не потеряно; кошелёк повторяет попытку каждые 2 минуты.';

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
  String get deskInvPayPaying => 'Оплата';

  @override
  String get deskInvPayNotDelivered => 'Не доставлено';

  @override
  String get deskInvPayDelivered => 'Ждёт отправки';

  @override
  String get deskInvPayPosted => 'Отправлено сервисом';

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
    return '$used из $max байт';
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
  String get deskInvIssuerAmountFact => 'Сумма';

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
    return 'Кошелёк $payer вернул счёт: он не может оплачивать счета. Попросите вместо этого прислать платёж.';
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
    return 'Доставлено в почтовый ящик $payer. Ничего не оплачено, пока плательщик не одобрит.';
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
      'Пришла оплата счёта, который это устройство не выставляло. Она сутки ждёт на ретрансляторе ваше другое устройство с этим кошельком: откройте кошелёк там, чтобы завершить её.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Пришёл ответ на платёж, который это устройство не отправляло. Он сутки ждёт на ретрансляторе ваше другое устройство с этим кошельком: откройте кошелёк там, чтобы завершить платёж.';

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
      'Когда сопряжённый контакт, которому вы разрешили, попросит об оплате, запрос появится здесь, и ничего не будет оплачено без вашего одобрения.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Ваш платёж сервису $service не доставлен';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Он подписан и хранится на этом устройстве; средства заблокированы. «Повторить» отправит его снова без повторного одобрения.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return 'Сервис $service отозвал оплаченный вами счёт';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'Платёж может так и не попасть в блокчейн. Отмените его, чтобы разблокировать средства.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Вашего платежа сервису $service нет в блокчейне';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Его срок истёк, и сеть его не видела. Отмените его, чтобы разблокировать средства.';

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
  String deskInvPayerShortText(String total, String spendable) {
    return 'Нужно $total EPIC доступных; у вас $spendable EPIC. Средства на подтверждении учитываются после 3 подтверждений.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Узел не отвечает';

  @override
  String get deskInvPayerNodeDownText =>
      'Кошелёк не может проверить средства, поэтому не может заплатить. Одобрение снова заработает, когда узел ответит; другой узел можно выбрать в разделе «Настройки › Узел».';

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
      'Сервер Epicbox не отвечает. Повторите в разделе «Счета › Оплатить»; повторное одобрение не нужно.';

  @override
  String get deskInvPayerRetryFailed => 'Всё ещё не доставлено';

  @override
  String get deskInvPayerRetryFailedText =>
      'Сервер Epicbox не отвечает. Платёж остаётся подписанным на этом устройстве.';

  @override
  String get deskInvPayerCancelTitle => 'Отменить этот платёж?';

  @override
  String get deskInvPayerCancelText =>
      'Отмена разблокирует средства здесь. У сервиса остаётся ваш подписанный платёж, и он может завершить его, пока эти средства не будут потрачены снова.';

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
  String get deskInvPayerSpendToSelf => 'Отправить их себе сейчас';

  @override
  String get deskInvPayerSpendToSelfHelp =>
      'Делает отмену окончательной: подписанная копия у сервиса больше не сможет завершиться. Требует сетевой комиссии.';

  @override
  String get deskInvPayerSpentText =>
      'Ваши средства разблокированы и перемещены внутри этого кошелька. Отмена окончательная.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Ваши средства разблокированы, но переместить их не удалось. Отмена ещё не окончательная.';

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
      'Попросите сопряжённый контакт оплатить или сохраните запрос файлом.';

  @override
  String get serverSwitchRelayTitle => 'Сменить сервер epicbox?';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'Адрес epicbox изменится на …@$relay. Отправителям нужен новый адрес. Платежи, отправленные на старый адрес, остаются на старом сервере.';
  }

  @override
  String get serverSwitchRelayConfirm => 'Сменить';

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
  String get sendSpendableUntilChangeHint =>
      'Сдача вернётся, когда отправка подтвердится.';

  @override
  String serverSwitched(String host) {
    return 'Переключено на $host';
  }

  @override
  String get methodDirect => 'Ссылка';

  @override
  String get methodLinkPayment => 'Платёж по ссылке';

  @override
  String get methodDirectShape => 'http://host:3415 или xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Кошелёк получателя должен быть открыт. Платёж на адрес .onion идёт через Tor.';

  @override
  String get methodArtLabelDirect =>
      'Ссылка: платёж идёт прямо в кошелёк получателя, который должен быть открыт';

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
  String get methodReceiveEpicboxShort => 'Работает при закрытом кошельке.';

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
  String get torNotOverTor => 'Не через Tor';

  @override
  String get torNeeds => 'Нужен Tor.';

  @override
  String get torTurnOn => 'Включить Tor';

  @override
  String get torTurnOff => 'Выключить Tor';

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
      'Сетевая активность идёт через сеть Tor. Tor скрывает интернет-адрес кошелька: каждое соединение проходит через несколько добровольческих узлов, и ни один сервер не узнаёт, где находится кошелёк. Уведомления выключены, пока включён Tor. Получать платежи на адрес Tor позволяет переключатель Ссылка · Tor в «Транзакциях».';

  @override
  String get receiveTabDirect => 'Ссылка';

  @override
  String get receiveDirectNeedsTor =>
      'Для приёма через Ссылка · Tor нужен Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Пока отправители используют адрес Epicbox.';

  @override
  String get receiveHttpTitle => 'Адрес Ссылка · HTTP';

  @override
  String get receiveHttpLanLine =>
      'Для кошельков в этой сети Wi-Fi, пока этот кошелёк открыт.';

  @override
  String get receiveHttpNoNetwork =>
      'Нет подключения к Wi-Fi. Адреса, который можно передать, нет.';

  @override
  String get receiveHttpOffWhileTor => 'Выключено, пока включён Tor.';

  @override
  String receiveHttpPortInUse(String port) {
    return 'Порт $port занят другой программой.';
  }

  @override
  String get receiveHttpFailed => 'Не удалось запустить.';

  @override
  String get receiveHttpShowQr => 'Показать QR';

  @override
  String get receiveHttpHideQr => 'Скрыть QR';

  @override
  String get receiveHttpQrLabel => 'QR-код адреса Ссылка · HTTP';

  @override
  String get netStatusOverTor => 'через Tor';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsHint =>
      'Экспериментально: может измениться или давать сбои. Сообщает, когда приходит платёж или счёт, пока приложение закрыто. Использует Epicbox BT Labs и сервис уведомлений Google; сообщение лишь будит приложение и не содержит ни суммы, ни отправителя, ни адреса. Выключено, пока включён Tor: регистрация раскрыла бы адрес телефона.';

  @override
  String get settingsPushPaused => 'Приостановлено, пока включён Tor';

  @override
  String get pushConfirmRelayBody =>
      'Уведомления используют Epicbox BT Labs и сервис уведомлений Google. Конфиденциальные данные не передаются.';

  @override
  String get pushConfirmRelayAddress =>
      'Ваш адрес Epicbox изменится. Поделитесь новым.';

  @override
  String get pushRelaySwitchFailed =>
      'Не удалось сменить сервер. Уведомления остаются выключенными.';

  @override
  String get pushConfirmTitle => 'Включить уведомления?';

  @override
  String get pushConfirmBody =>
      'Уведомления используют сервис уведомлений Google. Конфиденциальные данные не передаются.';

  @override
  String get pushConfirmAction => 'Включить';

  @override
  String get pushNoticeOn => 'Уведомления включены';

  @override
  String get pushNoticeOff => 'Уведомления выключены';

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
      'Кошелёк получателя недоступен через Tor';

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
      'Кошелёк тестовой сети. Импортировать можно только кошельки Mainnet.';

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
  String get deskErrProofSeedRead => 'Seed прочитан';

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
  String deskErrProofEpicbox(String old, String current) {
    return 'Старое приложение использовало сервер Epicbox $old; это приложение использует $current';
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
  String get deskErrNothingToSpend => 'Нечего тратить';

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
    return 'Подключение к Tor… $percent %';
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
  String deskErrHistChains(String from, String to) {
    return 'Файл из сети $from; этот кошелёк в сети $to.';
  }

  @override
  String get deskErrHistOtherWalletText =>
      'Файл экспортирован из кошелька с другой фразой восстановления.';

  @override
  String get deskErrHistNewerText =>
      'Этот файл создан более новой версией приложения. Обновите приложение, затем импортируйте его.';

  @override
  String get deskErrHistDamagedText => 'Файл неполный или был изменён.';

  @override
  String get deskErrHistNotOursText =>
      'Файл создан не в Epic Cash Desktop и не в Epic Cash Mobile.';

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
    return 'Сервер обновлений ответил: $status.';
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
  String get deskNodeAtTip => 'актуален';

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
  String get deskNodeStartIt => 'Запустите его в разделе «Настройки › Узел».';

  @override
  String get deskNodeFailPort => 'порт 3413 занят другой программой';

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
  String get deskNodeStageKernels => 'проверка ядер';

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
    return 'Проверка ядер · $done из $total млн';
  }

  @override
  String get deskNodeLineKernelsBare => 'Проверка ядер';

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
  String get deskNodeNoEstimate => 'без оценки; до часа';

  @override
  String get deskNodeEstimating => 'оценка…';

  @override
  String deskNodeAboutHours(int hours) {
    return 'осталось около $hours ч';
  }

  @override
  String deskNodeAboutMinutes(int minutes) {
    return 'осталось около $minutes мин';
  }

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
  String get deskTorNetworkHint =>
      'Сетевая активность идёт через сеть Tor. Tor скрывает интернет-адрес кошелька: каждое соединение проходит через несколько узлов, которые держат добровольцы, и ни один сервер не узнаёт, где находится кошелёк.';

  @override
  String get deskTorOff => 'Выкл.';

  @override
  String get deskTorStarting => 'Запуск…';

  @override
  String get deskTorOn => 'Вкл.';

  @override
  String get deskTorNotConnected => 'Нет подключения';

  @override
  String get deskTorRoutes =>
      'Epicbox, узел, статус, курс, обновления, поддержка и адреса Tor';

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
  String get deskRecvNameFile => 'Напрямую · Передача файла';

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
  String deskRecvTorDownText(String routes) {
    return '$routes: ничего не придёт, пока Tor не подключится или пока его не выключат.';
  }

  @override
  String get deskRecvTorStartingText =>
      'Адреса станут доступны, когда он подключится. Тем временем ничего не идёт в обход Tor.';

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
  String get deskRecvEpicboxIntro =>
      'Поделитесь им, чтобы получить оплату. Работает и при закрытом кошельке: сервер Epicbox хранит платежи, пока кошелёк не вернётся.';

  @override
  String get deskRecvCheckSix =>
      'Читая его вслух, сверьте первые шесть и последние шесть символов.';

  @override
  String get deskRecvHttpAddress => 'Адрес Ссылка · HTTP';

  @override
  String get deskRecvCopyHttp => 'Копировать адрес Ссылка · HTTP';

  @override
  String deskRecvHttpPublic(int port) {
    return 'Публичный адрес вашего роутера. Отправители из интернета смогут им пользоваться, когда роутер перенаправит порт $port.';
  }

  @override
  String get deskRecvHttpLocal =>
      'На этот адрес могут платить программы на этом компьютере. Для других устройств см. «Настройки › Транзакции».';

  @override
  String get deskRecvHttpIntro =>
      'Напрямую из другого кошелька, пока этот открыт. Только на этом компьютере, если в настройках не указано иное.';

  @override
  String get deskRecvHttpTorHint =>
      'Чтобы получить адрес Tor, включите Tor в разделе «Настройки › Приватность».';

  @override
  String get deskRecvDirectTor => 'Адрес Ссылка · Tor';

  @override
  String get deskRecvTorIntro =>
      'Напрямую из другого кошелька через Tor, пока этот открыт. Tor настраивается в разделе «Настройки › Приватность».';

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
      'Отправитель передал файл транзакции. Кошелёк подписывает его и сохраняет ответ для отправителя.';

  @override
  String get deskRecvOpen => 'Открыть';

  @override
  String get deskRecvFinalizeTitle => 'Завершить по файлу ответа';

  @override
  String get deskRecvFinalizeText =>
      'На отправку файлом пришёл ответ. Завершение отправляет платёж в сеть.';

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
  String deskSendLockAll(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заблокировано всё: $count выхода, $amount EPIC, около 3 блоков.',
      many: 'Заблокировано всё: $count выходов, $amount EPIC, около 3 блоков.',
      few: 'Заблокировано всё: $count выхода, $amount EPIC, около 3 блоков.',
      one: 'Заблокировано всё: $count выход, $amount EPIC, около 3 блоков.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заблокировано $count выхода, $amount EPIC, около 3 блоков.',
      many: 'Заблокировано $count выходов, $amount EPIC, около 3 блоков.',
      few: 'Заблокированы $count выхода, $amount EPIC, около 3 блоков.',
      one: 'Заблокирован $count выход, $amount EPIC, около 3 блоков.',
    );
    return '$_temp0';
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
  String deskSendReviewLocksAll(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Всё: $locked EPIC в $count выхода до подтверждения сдачи (3 блока). Доступного не остаётся.',
      many:
          'Всё: $locked EPIC в $count выходах до подтверждения сдачи (3 блока). Доступного не остаётся.',
      few:
          'Всё: $locked EPIC в $count выходах до подтверждения сдачи (3 блока). Доступного не остаётся.',
      one:
          'Всё: $locked EPIC в $count выходе до подтверждения сдачи (3 блока). Доступного не остаётся.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC в $count выхода до подтверждения сдачи (3 блока). Больше ничего пока не доступно.',
      many:
          '$locked EPIC в $count выходах до подтверждения сдачи (3 блока). Больше ничего пока не доступно.',
      few:
          '$locked EPIC в $count выходах до подтверждения сдачи (3 блока). Больше ничего пока не доступно.',
      one:
          '$locked EPIC в $count выходе до подтверждения сдачи (3 блока). Больше ничего пока не доступно.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksSome(int count, String locked, String spendable) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC в $count выхода до подтверждения сдачи (3 блока). Доступными остаются $spendable EPIC.',
      many:
          '$locked EPIC в $count выходах до подтверждения сдачи (3 блока). Доступными остаются $spendable EPIC.',
      few:
          '$locked EPIC в $count выходах до подтверждения сдачи (3 блока). Доступными остаются $spendable EPIC.',
      one:
          '$locked EPIC в $count выходе до подтверждения сдачи (3 блока). Доступными остаются $spendable EPIC.',
    );
    return '$_temp0';
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
      'Тратит как можно меньше мелких выходов; остальной баланс остаётся доступным, пока сдача подтверждается.';

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
      'Передайте этот файл получателю. Кошелёк ждёт файл ответа; когда он вернётся, завершите транзакцию.';

  @override
  String get deskSendFinalize => 'Завершить';

  @override
  String get deskSendNewSend => 'Новая отправка';

  @override
  String get deskSendNodeNotSynced => 'Узел не синхронизирован';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Отправка станет возможна, когда узел синхронизируется. Готово $percent%; форму можно заполнить уже сейчас.';
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
  String get deskSendTorStartingText =>
      'Отправка ждёт, пока он подключится. Тем временем ничего не идёт в обход Tor.';

  @override
  String get deskSendEpicboxOff => 'Epicbox не подключён';

  @override
  String get deskSendEpicboxOffText =>
      'Отправка через Epicbox заработает, когда будет включён приём через Epicbox. А пока используйте «Напрямую · Передача файла».';

  @override
  String get deskSendEpicboxTurnOn => 'Включить приём через Epicbox';

  @override
  String get deskSendDoneViaDirect => 'Завершено и отправлено в сеть.';

  @override
  String get deskSendDoneViaEpicbox =>
      'Передано в Epicbox. Завершится, когда получатель ответит.';

  @override
  String get deskSendViewTx => 'Открыть транзакцию';

  @override
  String get deskSendFailedTitle => 'Отправка не удалась';

  @override
  String get deskSendReviewAgain => 'Проверить снова';

  @override
  String get deskSendMethodDirect => 'Ссылка';

  @override
  String get deskSendMethodFile => 'Напрямую · Файл';

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
  String get deskSendNeedsTor => 'Нужен Tor';

  @override
  String get deskSendNeedsTorText => 'Адрес .onion доступен только через Tor.';

  @override
  String get deskSendNoTorBuild => 'В этой сборке нет Tor.';

  @override
  String get deskSendTurnOnTor => 'Включить Tor';

  @override
  String get deskSendHttpClearnet =>
      'Ссылка · HTTP идёт через обычный интернет, не через Tor.';

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
  String get deskSendAllButton => 'Всё';

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
  String get deskSendMessageHelp => 'Получатель увидит это сообщение.';

  @override
  String get deskSendPrivacyOn => 'Приватность · Dandelion++ вкл.';

  @override
  String get deskSendPrivacyOff => 'Приватность · Dandelion++ выкл.';

  @override
  String get deskSendDandelionText =>
      'Пропускает транзакцию через несколько случайных узлов, прежде чем она разойдётся по сети, и сеть не может узнать, откуда она пришла.';

  @override
  String get deskSendHintSent =>
      'Отправлено. Чтобы отправить снова, введите новую сумму и получателя.';

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
  String get deskSendHintFix => 'Исправьте поля, отмеченные красным.';

  @override
  String get deskSendHintChecking => 'Считаем комиссию для этой суммы.';

  @override
  String get deskSendHintDefault => 'Ничего не отправится без подтверждения.';

  @override
  String get deskSendReviewWaitTor => 'Ждём Tor';

  @override
  String get deskSendReviewTorOff => 'Tor не подключён';

  @override
  String get deskSendReview => 'Проверить отправку';

  @override
  String get deskSendSummary => 'Итог';

  @override
  String get deskSendNetworkFee => 'Комиссия сети';

  @override
  String get deskSendTotal => 'Итого';

  @override
  String get deskSendUpdating => 'Баланс обновляется, пока кошелёк сканирует.';

  @override
  String get deskSendEpicboxLine1 => 'Получатель может быть офлайн.';

  @override
  String get deskSendEpicboxLine2 =>
      'Сервер Epicbox хранит платёж, пока получатель не откроет кошелёк.';

  @override
  String get deskSendDirectLine1 => 'Прямо в кошелёк получателя.';

  @override
  String get deskSendDirectLine2 =>
      'Адрес http(s) или .onion; .onion идёт через Tor. Кошелёк получателя должен быть открыт.';

  @override
  String get deskSendFileLine1 => 'Соединение не нужно.';

  @override
  String get deskSendFileLine2 =>
      'Передайте файл, получите файл ответа и завершите платёж здесь.';

  @override
  String get deskSendTagDirect => 'Ссылка';

  @override
  String get deskSendTagFile => 'Напрямую · Файл';

  @override
  String get deskSendTagEpicbox => 'Через Epicbox';

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
  String get deskSendPlainTitle => 'Без шифрования. Всё равно отправить?';

  @override
  String get deskSendPlainDesc =>
      'Обычный HTTP к другому компьютеру. Любой на пути может прочитать транзакцию. https:// зашифрован.';

  @override
  String get deskSendPlainConfirm => 'Всё равно отправить';

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
  String get deskFinPosted => 'Транзакция отправлена в сеть';

  @override
  String get deskFinTitle => 'Завершить по файлу ответа';

  @override
  String get deskFinNoticeTitle => 'Для транзакции, созданной файлом';

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
      'Этот файл не является файлом транзакции. Выберите файл .slate или .tx, который передал отправитель.';

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
  String get deskActSearchHint => 'Адрес или слейт';

  @override
  String get deskActSearchHintEmpty => 'Пока искать нечего';

  @override
  String get deskActSearchLabel => 'Поиск транзакций';

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
  String get deskActDetailReceived => 'Полученная транзакция';

  @override
  String get deskActDetailSent => 'Отправленная транзакция';

  @override
  String get deskActLoading => 'Загрузка транзакций';

  @override
  String get deskActWaitingNode => 'Ждём синхронизации узла.';

  @override
  String get deskActFilterAll => 'Все';

  @override
  String get deskActFilterReceived => 'Полученные';

  @override
  String get deskActFilterSent => 'Отправленные';

  @override
  String get deskActNoMatchTitle => 'Транзакции не найдены';

  @override
  String get deskActNoMatchText =>
      'Попробуйте другой адрес или ID слейта либо сбросьте фильтр.';

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
  String get deskActEmptyTitle => 'Транзакций пока нет';

  @override
  String get deskActEmptyText =>
      'Здесь появится каждый отправленный и полученный платёж, сначала новые: с кем он и на каком он этапе.';

  @override
  String get deskActStageWaiting => 'Ожидание';

  @override
  String get deskActStageWaitingText =>
      'Оба кошелька подписывают платёж. Через Epicbox это происходит само.';

  @override
  String get deskActStageConfirming => 'Подтверждение';

  @override
  String get deskActStageConfirmingText =>
      'Платёж в блокчейне. Примерно один блок в минуту.';

  @override
  String get deskActStageSpendable => 'Доступно';

  @override
  String deskActStageSpendableText(int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'После $needed подтверждения, примерно через $needed минуты.',
      many: 'После $needed подтверждений, примерно через $needed минут.',
      few: 'После $needed подтверждений, примерно через $needed минуты.',
      one: 'После $needed подтверждения, примерно через $needed минуту.',
    );
    return '$_temp0';
  }

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
  String get deskConNone => 'Контактов пока нет.';

  @override
  String get deskConNoMatchList => 'Контакты не найдены';

  @override
  String get deskConAdd => 'Добавить контакт';

  @override
  String get deskConIdle =>
      'Выберите контакт, чтобы увидеть подробности, отправить ему платёж, изменить или удалить его.';

  @override
  String get deskConEmptyTitle => 'Контактов пока нет';

  @override
  String get deskConEmptyText =>
      'Сохраните людей и магазины, которым часто платите. На странице «Отправить» выберите имя, а не вставляйте адрес.';

  @override
  String get deskConEmptyLocal =>
      'Контакты хранятся на этом компьютере. Они не входят во фразу восстановления.';

  @override
  String get deskConSendToAddress => 'Отправить на адрес';

  @override
  String deskConLastTx(String when) {
    return 'Последняя транзакция: $when';
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
    return 'Транзакции с контактом «$name»';
  }

  @override
  String get deskConAllTx => 'Все транзакции';

  @override
  String get deskConTxNone =>
      'Транзакций с этим контактом пока нет. Здесь появятся платежи, отправленные ему со страницы «Отправить».';

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
      'Недействительный адрес. Используйте адрес Epicbox (es5x…@epicbox.epiccash.com), адрес ссылки (https://…) или onion-адрес (….onion).';

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
      'Адрес и заметка контакта будут удалены из этого кошелька. Прошлые транзакции останутся в «Активности». Это нельзя отменить.';

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
      'Выходы — это части, из которых состоит баланс. Отправка тратит выходы целиком, платит получателю и возвращает остаток новым выходом; потраченные выходы заблокированы, пока отправка не подтвердится.';

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
  String get deskOutCardWait =>
      'Дождитесь подтверждения отправки (около 3 блоков).';

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
      other: 'Тратит $count выхода. Комиссия от $fee EPIC.',
      many: 'Тратит $count выходов. Комиссия от $fee EPIC.',
      few: 'Тратит $count выхода. Комиссия от $fee EPIC.',
      one: 'Тратит $count выход. Комиссия от $fee EPIC.',
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
  String get deskOutNoneText =>
      'Первый полученный платёж создаст выход. Разделению и объединению нужно, с чем работать.';

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
  String get deskOutTileImmature => 'Не созрело';

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
  String get deskOutStatusAwaiting => 'Ждёт завершения';

  @override
  String get deskOutNoteWaitingSender => 'ждёт отправителя';

  @override
  String get deskOutStatusUnpaid => 'Неоплаченный счёт';

  @override
  String get deskOutNoteNotInBalance => 'не входит в баланс';

  @override
  String get deskOutStatusImmature => 'Не созрел';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'осталось $number блока',
      many: 'осталось $number блоков',
      few: 'осталось $number блока',
      one: 'остался $number блок',
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
  String deskOutSplitDialogText(String spent, String made) {
    return 'Тратит $spent и создаёт $made. Обычная сетевая транзакция на этот кошелёк, подтверждается через 3 блока, как любая отправка; до этого всё доступное заблокировано.';
  }

  @override
  String deskOutConsDialogText(String spent, String made) {
    return 'Тратит $spent и создаёт $made. Обычная сетевая транзакция на этот кошелёк, подтверждается через 3 блока, как любая отправка; до этого всё доступное заблокировано. Следующая отправка потратит один выход, поэтому её комиссия будет наименьшей.';
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
  String deskOutFactLockedValue(String amount) {
    return '$amount EPIC, около 3 блоков. Доступного не остаётся.';
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
  String deskOutSplitDoneText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Теперь в кошельке $count выхода примерно по $amount EPIC, они подтверждаются. Всё заблокировано до подтверждения (3 блока). В «Активности» две записи: отправка и получение, обе на этот кошелёк.',
      many:
          'Теперь в кошельке $count выходов примерно по $amount EPIC, они подтверждаются. Всё заблокировано до подтверждения (3 блока). В «Активности» две записи: отправка и получение, обе на этот кошелёк.',
      few:
          'Теперь в кошельке $count выхода примерно по $amount EPIC, они подтверждаются. Всё заблокировано до подтверждения (3 блока). В «Активности» две записи: отправка и получение, обе на этот кошелёк.',
      one:
          'Теперь в кошельке $count выход примерно по $amount EPIC, он подтверждается. Всё заблокировано до подтверждения (3 блока). В «Активности» две записи: отправка и получение, обе на этот кошелёк.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount) {
    return 'Один выход на $amount EPIC, подтверждается. Всё заблокировано до подтверждения (3 блока). В «Активности» две записи: отправка и получение, обе на этот кошелёк.';
  }

  @override
  String get deskOutNotPostedTitle => 'Не отправлено в сеть.';

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
  String get deskOutPostingDesc => 'Отправка в сеть.';

  @override
  String get deskOutDoneDesc => 'Готово.';

  @override
  String get deskOutSplitDesc =>
      'Больше выходов, чтобы несколько отправок могли идти друг за другом.';

  @override
  String get deskOutConsDesc => 'Один выход вместо многих.';

  @override
  String deskOutNothingText(String what) {
    return 'Нечего объединять: у кошелька $what. Объединение сливает несколько выходов в один.';
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
  String get deskOvNodeAddrText =>
      'Теперь используется node.epiccash.com вместо node.epiccash.com:3413.';

  @override
  String get deskOvNodeIncompatTitle =>
      'Версия этого узла несовместима с этим кошельком';

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
      'Проверьте, что он запущен и доступен. Баланс может быть устаревшим, отправка приостановлена.';

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
    return 'Синхронизация узла: $percent%';
  }

  @override
  String deskOvSyncText(String block) {
    return 'Загружаются блоки. Баланс показан на момент блока $block. Отправка станет доступна, когда узел догонит сеть.';
  }

  @override
  String get deskOvSyncProgress => 'Ход синхронизации узла';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent% блокчейна';
  }

  @override
  String get deskOvReceiveEpic => 'Получить EPIC';

  @override
  String get deskOvSend => 'Отправить';

  @override
  String get deskOvReceive => 'Получить';

  @override
  String get deskOvSendWaits =>
      'Отправка станет доступна, когда узел синхронизируется.';

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
  String get deskOvFiatNote => '  весь баланс, CoinGecko';

  @override
  String get deskOvBreakTotal => 'Всего';

  @override
  String get deskOvBreakConfirming => 'Подтверждается';

  @override
  String get deskOvBreakImmature => 'Не созрело';

  @override
  String get deskOvBreakAwaiting => 'Ждёт завершения';

  @override
  String get deskOvBreakLocked => 'Заблокировано в отправках';

  @override
  String get deskOvUpdating => 'Обновление';

  @override
  String get deskOvHiddenAmount => 'Сумма скрыта';

  @override
  String get deskOvLoading => 'Загрузка транзакций';

  @override
  String get deskOvEmptyTitle => 'Транзакций пока нет';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Полученные EPIC сначала появятся здесь как подтверждающиеся, а после $blocks блока станут доступны.',
      many:
          'Полученные EPIC сначала появятся здесь как подтверждающиеся, а после $blocks блоков станут доступны.',
      few:
          'Полученные EPIC сначала появятся здесь как подтверждающиеся, а после $blocks блоков станут доступны.',
      one:
          'Полученные EPIC сначала появятся здесь как подтверждающиеся, а после $blocks блока станут доступны.',
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
      other: '$count отправки файлом открыты',
      many: '$count отправок файлом открыты',
      few: '$count отправки файлом открыты',
      one: '$count отправка файлом открыта',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => 'Завершите их файлом ответа от получателя.';

  @override
  String get deskOvFinalize => 'Завершить';

  @override
  String get deskTxMethodFile => 'Напрямую · Файл';

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
  String get deskTxNoteBlock => 'Время блока. Отправитель не записан.';

  @override
  String get deskTxNoteScanTime =>
      'Время сканирования; время блока прочитать не удалось. Отправитель не записан.';

  @override
  String get deskTxNoteUnknown => 'Отправитель не записан.';

  @override
  String get deskTxFoundRestoredLabel => 'Восстановлено';

  @override
  String get deskTxFoundRestoredLine => 'Найдено при восстановлении';

  @override
  String get deskTxFoundRestoredStep =>
      'Найдено при восстановлении этого кошелька';

  @override
  String get deskTxFoundRestoredTip =>
      'Найдено в блокчейне при восстановлении этого кошелька. Отправитель не записан.';

  @override
  String get deskTxFoundRescanLabel => 'Найдено сканированием';

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
  String get deskTxBackupTip => 'Добавлено из файла данных кошелька.';

  @override
  String get deskTxFromBackup => 'Импортирован';

  @override
  String get deskTxStatusImmature => 'Не созрело';

  @override
  String get deskTxStatusWaitingSender => 'Ждёт завершения отправителем';

  @override
  String get deskTxStatusWaitingResponseFile => 'Ждёт файл ответа';

  @override
  String get deskTxStatusWaitingRecipient => 'Ждёт подписи получателя';

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
  String get deskTxPaymentProof => 'Подтверждение платежа';

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
  String get deskTxNowBackup => 'Импортирован; блокчейн не запрашивался.';

  @override
  String deskTxNowImmature(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Подтверждено, но награду за майнинг можно потратить только после $count подтверждения.',
      many:
          'Подтверждено, но награду за майнинг можно потратить только после $count подтверждений.',
      few:
          'Подтверждено, но награду за майнинг можно потратить только после $count подтверждений.',
      one:
          'Подтверждено, но награду за майнинг можно потратить только после $count подтверждения.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Подписано и возвращено. Ждём, пока отправитель завершит.';

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
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Подтверждено, $confirmations подтверждения.',
      many: 'Подтверждено, $confirmations подтверждений.',
      few: 'Подтверждено, $confirmations подтверждения.',
      one: 'Подтверждено, $confirmations подтверждение.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Отменено.';

  @override
  String get deskTxNotCancelled => 'Не отменено';

  @override
  String get deskTxCancelled => 'Транзакция отменена';

  @override
  String get deskTxCancelling => 'Отмена';

  @override
  String get deskTxHeadRestored => 'восстановлено';

  @override
  String get deskTxHeadFoundOnChain => 'найдено в блокчейне';

  @override
  String get deskTxHeadBackup => 'добавлено из файла данных кошелька';

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
  String get deskTxSignedByRecipient => 'Подписано получателем';

  @override
  String get deskTxProofView => 'Открыть';

  @override
  String get deskTxTechTitle => 'Технические сведения';

  @override
  String get deskTxTechId => 'ID';

  @override
  String get deskTxTechSlate => 'ID слейта';

  @override
  String get deskTxCopySlate => 'Копировать ID слейта';

  @override
  String get deskTxTechHeight => 'Высота';

  @override
  String get deskTxTechKernel => 'Ядро';

  @override
  String get deskTxTechConfirmed => 'Подтверждено';

  @override
  String get deskTxTechCredited => 'Зачислено';

  @override
  String get deskTxTechDebited => 'Списано';

  @override
  String get deskTxTechStatus => 'Статус';

  @override
  String get deskTxTechType => 'Тип';

  @override
  String get deskTxStepMined => 'Добыто в блоке';

  @override
  String get deskTxStepSpendable => 'Доступно';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'осталось $count блока',
      many: 'осталось $count блоков',
      few: 'осталось $count блока',
      one: 'остался $count блок',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Получен слейт';

  @override
  String get deskTxStepCreated => 'Создано и подписано';

  @override
  String get deskTxStepSignedReturned => 'Подписано и возвращено';

  @override
  String get deskTxStepWaitingFile => 'Ждём файл ответа';

  @override
  String get deskTxStepWaitingRecipient => 'Ждём получателя';

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
  String get deskTxCancelOutgoingTitle => 'Отменить эту отправку?';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '$amount EPIC от $who уйдут из баланса. Кошелёк сначала спросит узел и откажет, если платёж уже в пуле узла или в блоке. Если отправитель опубликует его позже, он всё равно поступит.';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC для $who. Кошелёк получателя не может завершить платёж без вашего: заблокированная сумма вернётся в баланс.';
  }

  @override
  String get deskTxCancelKeep => 'Оставить';

  @override
  String get deskTxCancelIncomingAction => 'Отменить платёж';

  @override
  String get deskTxCancelOutgoingAction => 'Отменить отправку';

  @override
  String deskTxProofIncoming(String amount) {
    return 'Подтверждает, что этот кошелёк получил $amount EPIC в этом ядре.';
  }

  @override
  String deskTxProofOutgoing(String amount) {
    return 'Подтверждает, что получатель получил $amount EPIC в этом ядре.';
  }

  @override
  String get deskTxProofSenderAddress => 'Адрес отправителя';

  @override
  String get deskTxProofRecipientAddress => 'Адрес получателя';

  @override
  String get deskTxProofRecipientSignature => 'Подпись получателя';

  @override
  String get deskTxProofCopyKernel => 'Копировать ядро';

  @override
  String get deskTxProofCopySender => 'Копировать адрес отправителя';

  @override
  String get deskTxProofCopyRecipient => 'Копировать адрес получателя';

  @override
  String get deskTxProofCopySignature => 'Копировать подпись получателя';

  @override
  String get deskTxProofExport => 'Экспорт';

  @override
  String get deskTxProofSaved => 'Подтверждение сохранено';

  @override
  String get deskOnbWelcomeAdd => 'Добавить кошелёк';

  @override
  String get deskOnbWelcomeTagline =>
      'Ключи и монеты остаются на этом компьютере под защитой пароля.';

  @override
  String get deskOnbWelcomeCreate => 'Создать новый кошелёк';

  @override
  String get deskOnbWelcomeCreateSub => 'Новая фраза восстановления';

  @override
  String get deskOnbWelcomeImport => 'Импортировать кошельки';

  @override
  String get deskOnbWelcomeImportSub => 'Из старого Epic Wallet или из папки';

  @override
  String get deskOnbWelcomeRestore => 'Восстановить по фразе';

  @override
  String get deskOnbWelcomeRestoreSub => 'По словам фразы восстановления';

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
  String get deskOnbWelcomeNetworkHelp =>
      'В Mainnet настоящие EPIC. Floonet и Usernet — тестовые сети.';

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
  String get deskOnbCreateStageCreate =>
      'Создание кошелька и его фразы восстановления';

  @override
  String get deskOnbCreateStageSave => 'Сохранение учётной записи';

  @override
  String get deskOnbCreateNotCreated => 'Кошелёк не создан';

  @override
  String get deskOnbCreateCreating => 'Создание кошелька';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'Кошелёк в $network, тестовой сети.';
  }

  @override
  String get deskOnbCreateFailedTitle => 'Не удалось создать кошелёк';

  @override
  String get deskOnbCreateDiskFull =>
      'Не удалось сохранить учётную запись: диск заполнен.';

  @override
  String get deskOnbCreateWait =>
      'Это может занять до минуты. Не закрывайте приложение.';

  @override
  String get deskOnbCreateLocking => 'Блокировка открытого кошелька';

  @override
  String get deskOnbCreateSide => 'Новый кошелёк';

  @override
  String get deskOnbCreateTitle => 'Создать кошелёк';

  @override
  String get deskOnbCreateLead =>
      'Пароль открывает этот кошелёк на этом компьютере. Он не поможет вернуть монеты — это делает фраза на следующем шаге.';

  @override
  String get deskOnbCreateTestNote =>
      'Кошелёк в тестовой сети, не для настоящих EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'Эти слова — единственный способ вернуть монеты, если компьютер сломается. Запишите их на бумаге по порядку.';

  @override
  String get deskOnbCreateRevealFirst => 'Сначала откройте фразу';

  @override
  String get deskOnbCreateWarn =>
      'Любой, у кого есть эти слова, может забрать монеты';

  @override
  String get deskOnbCreateReveal => 'Показать фразу';

  @override
  String get deskOnbCreateCheckScreen => 'Убедитесь, что никто не видит экран.';

  @override
  String get deskOnbCreateHide => 'Скрыть';

  @override
  String get deskOnbCreateShowQr => 'Показать QR-код';

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
    return 'Записано: все $_temp0 на бумаге';
  }

  @override
  String get deskOnbRestoreDone => 'Кошелёк восстановлен.';

  @override
  String get deskOnbRestoreNotRestored => 'Кошелёк не восстановлен';

  @override
  String get deskOnbRestoreRestoring => 'Восстановление кошелька';

  @override
  String get deskOnbRestoreFailedTitle => 'Не удалось восстановить кошелёк';

  @override
  String get deskOnbRestorePermission =>
      'Не удалось записать файлы кошелька: нет доступа к ~/.config/Epic Cash Desktop.';

  @override
  String get deskOnbRestoreWait =>
      'Это может занять до минуты. Баланс появится после первого сканирования блокчейна.';

  @override
  String get deskOnbRestoreSide => 'Восстановить кошелёк';

  @override
  String deskOnbRestorePasswordLead(int count) {
    return 'Фраза из $count слов верна. Задайте пароль, который открывает этот кошелёк на этом компьютере.';
  }

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
  String get deskOnbRestoreStaysHere =>
      'Фраза никогда не покидает этот компьютер.';

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
      'Введите слова по порядку или вставьте всю фразу в любое поле. Переносы строк, запятые и нумерация не учитываются.';

  @override
  String get deskOnbRestoreClear => 'Очистить';

  @override
  String deskOnbRestoreUseWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Использовать $count слова',
      many: 'Использовать $count слов',
      few: 'Использовать $count слова',
      one: 'Использовать $count слово',
    );
    return '$_temp0';
  }

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
  String get deskOnbKillTitle => 'Epic уже запущен';

  @override
  String get deskOnbKillBody =>
      'Другой процесс кошелька или узла использует файлы и порты кошелька. Закройте его, чтобы разблокировать здесь, или отмените и закройте его сами.';

  @override
  String get deskOnbKillProcesses => 'Запущенные процессы';

  @override
  String get deskOnbKillRoleWallet => 'служба кошелька';

  @override
  String get deskOnbKillRoleNode => 'узел';

  @override
  String get deskOnbKillNote =>
      'Закрытие остановит то, что они делали, например синхронизацию узла или приём платежей. После разблокировки это приложение запустит их снова.';

  @override
  String get deskOnbKillClosing => 'Закрытие…';

  @override
  String get deskOnbKillClose => 'Закрыть и разблокировать';

  @override
  String get deskOnbSameTitle => 'Этот кошелёк уже здесь';

  @override
  String get deskOnbSameBody =>
      'Фраза принадлежит кошельку из списка. Ничего не добавлено.';

  @override
  String get deskOnbSameWallet => 'Кошелёк';

  @override
  String get deskOnbSameNote =>
      '«Открыть его» запросит пароль этого кошелька. «Новый пароль» заменит его по этой фразе. «Отмена» оставит фразу в полях.';

  @override
  String get deskOnbSameOpen => 'Открыть его';

  @override
  String get deskOnbUnlockWhoWindows =>
      'Этот кошелёк может открыть любой, кто пользуется этой учётной записью Windows.';

  @override
  String get deskOnbUnlockWho =>
      'Этот кошелёк может открыть любой, кто пользуется этой учётной записью.';

  @override
  String get deskOnbUnlockWrong =>
      'Неверный пароль. Проверьте Caps Lock и раскладку клавиатуры.';

  @override
  String get deskOnbUnlockPortInUse =>
      'Служба кошелька не запустилась: порт 3415 занят другой программой.';

  @override
  String get deskOnbUnlockStageCheck => 'Проверка файлов кошелька';

  @override
  String get deskOnbUnlockStageProcesses =>
      'Поиск ещё работающих процессов кошелька';

  @override
  String get deskOnbUnlockStageClosing => 'Закрытие старых процессов кошелька';

  @override
  String get deskOnbUnlockStageWallet => 'Запуск службы кошелька';

  @override
  String get deskOnbUnlockStageUnlock => 'Разблокировка кошелька';

  @override
  String get deskOnbUnlockEnter => 'Введите пароль';

  @override
  String get deskOnbUnlockCloseOthers =>
      'Закройте другие процессы Epic и разблокируйте снова.';

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
  String get deskOnbUnlockFailedLead => 'Кошелёк не открылся. Причина ниже.';

  @override
  String get deskOnbUnlockFailedBox => 'Кошелёк не открылся';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'Разблокировка: $name';
  }

  @override
  String get deskOnbUnlockStepsLead =>
      'Каждый шаг появляется по мере выполнения.';

  @override
  String get deskOnbUnlockNote =>
      'Затем откроется обзор, а остальное завершится в фоне: подключение к узлу, обновление баланса, включение приёма.';

  @override
  String get deskOnbUnlockTitle => 'Разблокировка кошелька';

  @override
  String get deskOnbUnlockLead => 'Ключи остаются на этом компьютере.';

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
    return 'Она была в $folder';
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
    return 'Свободно здесь: $size';
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
  String get deskOnbNodeSeparate => 'Отдельная программа.';

  @override
  String get deskOnbNodeSeparateText =>
      'Кошелёк запускает узел Epic и останавливает его вместе с приложением.';

  @override
  String get deskOnbNodeFirewall => 'Windows один раз спросит,';

  @override
  String get deskOnbNodeFirewallText =>
      'пропустить ли его через брандмауэр. Разрешите для частных сетей.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'и объём медленно растёт. $free.';
  }

  @override
  String get deskOnbNodeHours => 'Несколько часов на синхронизацию';

  @override
  String get deskOnbNodeHoursText =>
      'в первый раз, от 2 до 6 при обычном подключении. Кошелёк показывает ход и тем временем может пользоваться публичным узлом.';

  @override
  String get deskOnbNodeDownload => 'Около 4 ГБ загрузки';

  @override
  String get deskOnbNodeDownloadText =>
      'в первый раз, потом понемногу каждый день.';

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
      'Узел Epic GUI или CLI. Кошелёк подключается к нему и ничего не запускает.';

  @override
  String get deskOnbNodeAddress => 'Адрес узла на этом компьютере';

  @override
  String get deskOnbNodeCheck => 'Проверить';

  @override
  String get deskOnbNodeBundled => 'Запустить встроенный узел';

  @override
  String get deskOnbNodeBundledText =>
      'Загружает и синхронизирует блокчейн в собственную папку кошелька. До нажатия «Сохранить» на последнем шаге ничего не загружается.';

  @override
  String deskOnbNodeFallback(String host) {
    return 'Использовать $host, пока локальный узел не синхронизирован. Потом локальный узел сам займёт его место.';
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
      other: 'Вставлено $count слова; во фразе 12, 15, 18, 21 или 24 слова',
      many: 'Вставлено $count слов; во фразе 12, 15, 18, 21 или 24 слова',
      few: 'Вставлено $count слова; во фразе 12, 15, 18, 21 или 24 слова',
      one: 'Вставлено $count слово; во фразе 12, 15, 18, 21 или 24 слова',
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
      'Ищем в папках старых версий Epic Wallet и программы epic. Ничего не меняется.';

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
  String get deskOnbImportFoundLead => 'Старые папки только читаются.';

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
  String get deskOnbImportCheckTitle => 'Проверка использования';

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
  String get deskOnbImportOlderSub => 'Учётные записи и папки';

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
    return 'Пароль кошелька $name в старом приложении.';
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
  String get deskAppFirstScanTitle => 'Первое сканирование кошелька';

  @override
  String get deskAppFirstScanBody =>
      'Кошелёк ищет в блокчейне свои выходы. Им можно пользоваться; баланс обновится, когда сканирование закончится.';

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
  String deskShellVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get deskShellOpenWalletSettings => 'Открыть настройки кошелька';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Открыть настройки кошелька: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Сменить кошелёк';

  @override
  String deskShellWalletBy(String maker) {
    return 'Кошелёк от $maker';
  }

  @override
  String get deskTourOverviewTitle => 'Обзор';

  @override
  String get deskTourOverviewText =>
      'Баланс и то, что ещё подтверждается, а ниже последние транзакции. Всё остальное — в боковой панели.';

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
  String get deskTourNodeTitle => 'Настройки › Узел';

  @override
  String get deskTourNodeText =>
      'Из какого узла кошелёк читает цепочку. Остальные страницы настроек перечислены слева.';

  @override
  String get deskTourHelpTitle => 'Справка';

  @override
  String get deskTourHelpText =>
      'Темы по разделам и «Сообщить о проблеме». Подробнее о каждой странице — здесь, а тур можно показать снова.';

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
  String get deskKitHealthOn => 'Работает';

  @override
  String get deskKitHealthSlow => 'Медленно';

  @override
  String get deskKitHealthOffline => 'Не в сети';

  @override
  String get deskKitHealthOff => 'Выкл.';

  @override
  String get deskKitHealthChecking => 'Проверка';

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
  String get deskKitLimitedNetwork =>
      'status.btlabs.uk недоступен. Эти сведения получены от самого узла: не с чем сравнить последний блок, нет данных о доступности и числе пиров.';

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
  String get deskKitAtTip => 'актуален';

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
  String deskKitSourceChecked(String time) {
    return 'status.btlabs.uk, проверено в $time';
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
  String deskKitNodeDownText(String host) {
    return 'Переключиться на $host, самый исправный из других узлов?';
  }

  @override
  String get deskKitSwitch => 'Переключить';

  @override
  String get deskKitLimitedInfo => 'Неполные данные';

  @override
  String get deskKitFromStatusSite => 'с status.btlabs.uk';

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
  String get deskKitLocalNode => 'Локальный узел';

  @override
  String get deskKitMethodWaitingTor => 'Ждёт Tor';

  @override
  String deskKitMethodTorNotConnected(String host) {
    return '$host. Tor не подключён.';
  }

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
    return 'Порт $port занят другой программой. Закройте её или выберите другой порт в настройках.';
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
  String get deskKitChipNotOverTor => 'Не через Tor';

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
  String get deskKitQrHideCode => 'Скрыть QR-код';

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
  String get deskSetAcctPhraseHint =>
      'Слова, которые восстанавливают этот кошелёк. Никому их не показывайте.';

  @override
  String get deskSetAcctShowPhrase => 'Показать фразу…';

  @override
  String get deskSetAcctRescanHint =>
      'Заново читает блокчейн, если баланс выглядит неверным.';

  @override
  String get deskSetAcctRecheck => 'Сверить…';

  @override
  String get deskSetAcctFiles => 'Файлы';

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
  String get deskSetAcctSetup => 'Мастер настройки';

  @override
  String get deskSetAcctSetupHint =>
      'Пройти настройку узла и приёма заново. Ничего не потеряется.';

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
  String get deskSetBackupGroup => 'Данные кошелька';

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
  String get deskSetBackupCsvTitle => 'Платежи в CSV';

  @override
  String get deskSetBackupCsvHint =>
      'Простая таблица для электронных таблиц. Без шифрования, импортировать нельзя.';

  @override
  String get deskSetBackupCsvButton => 'Экспорт CSV…';

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
  String get deskSetBackupFileNote =>
      'Файл содержит всё на текущий момент. После новых платежей или изменений экспортируйте его снова.';

  @override
  String get deskSetBackupExportDesc =>
      'Файл с историей платежей, контактами, счетами и настройками этого кошелька. Сам по себе он кошелёк не восстановит: сначала восстановите по фразе восстановления, затем импортируйте этот файл.';

  @override
  String get deskSetBackupSaved => 'Сохранено';

  @override
  String get deskSetBackupKeepCopy =>
      'Храните копию и вне этого компьютера: на флешке, другом диске или в облаке. После новых платежей экспортируйте снова.';

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
  String deskSetBackupNeedsValue(String network) {
    return 'Файл этого кошелька (та же фраза восстановления), сеть $network. Сначала восстановите кошелёк по его фразе.';
  }

  @override
  String get deskSetBackupNever => 'Никогда не';

  @override
  String get deskSetBackupNeverValue =>
      'удаляет и не меняет платёж, который уже здесь';

  @override
  String get deskSetBackupChooseFile => 'Выбрать файл…';

  @override
  String get deskSetBackupImportDesc =>
      'Возвращает историю платежей, контакты, счета и настройки этого кошелька. Ничего не удаляется, и тот же файл дважды ничего не меняет.';

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
  String get deskSetBackupRangeAll => 'Все';

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
    return '$_temp0 · столбцы: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. Файл $file.';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '– · столбцы: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. Файл $file.';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Без шифрования.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Любой, у кого есть файл, увидит суммы, даты, адреса и заметки. Импортировать его нельзя; для этого есть «Экспорт данных кошелька».';

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
      'На этом компьютере уже есть данные блокчейна Epic, которые может использовать локальный узел.';

  @override
  String get deskSetDlgChainFolder => 'Папка';

  @override
  String get deskSetDlgChainSize => 'Размер';

  @override
  String get deskSetDlgChainUpdated => 'Обновлено';

  @override
  String get deskSetDlgChainUpdatedValue => '3 дня назад';

  @override
  String get deskSetDlgChainOthers =>
      'Найдены и другие копии (1). Эта обновлялась последней.';

  @override
  String get deskSetDlgChainInUse =>
      'Эту папку использует другая программа Epic. Закройте её и снова выберите локальный узел, чтобы использовать эти данные.';

  @override
  String get deskSetDlgChainUseIt =>
      'Использовать их? Это избавит от загрузки и синхронизации всего блокчейна.';

  @override
  String get deskSetDlgChainOlderWallet =>
      'Старому Epic Wallet, который использует эту папку, после этого может понадобиться повторная синхронизация. Монеты это не затрагивает.';

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
      'Теперь этот кошелёк будет открываться новым паролем. Запомненный пароль будет забыт.';

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
  String get deskSetDlgRemoveDesc => 'Ничего не изменится без подтверждения.';

  @override
  String get deskSetDlgRemoveWhat => 'Что убрать';

  @override
  String get deskSetDlgRemoveFromList => 'Убрать из списка';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Файлы останутся в $folder. На странице «Все кошельки» его можно добавить обратно.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Удалить кошелёк';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Удаляет его ключи и базу данных из $folder. Восстановить его можно только по фразе восстановления; без неё монеты потеряны.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'Чтобы удалить и его файлы, разблокируйте этот кошелёк и выберите «Удалить кошелёк» в разделе «Настройки › Этот кошелёк».';

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
  String get deskSetFrameConnecting => 'Подключение…';

  @override
  String get deskSetFrameListening => 'Слушает';

  @override
  String deskSetFrameHealthLatency(String word, int ms) {
    return '$word · $ms мс';
  }

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
    return 'Использовать $host, пока локальный узел не синхронизирован. Потом локальный узел сам займёт его место.';
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
      'Обычно помогает перезапуск; если нет, причина будет в журнале.';

  @override
  String get deskSetLnodePortInUse => 'Порт 3413 занят другой программой.';

  @override
  String get deskSetLnodePortInUseText =>
      'Закройте её (другой узел Epic?) или выберите уже запущенный там узел в строке «Сервер узла».';

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
    return 'Синхронизация занимает часы. Тем временем кошелёк может читать блокчейн и отправлять через $host, публичный узел. Когда локальный узел синхронизируется, он сам займёт его место.';
  }

  @override
  String get deskSetLndAskNote =>
      'Спрашиваем один раз. Узел и выбор можно изменить в разделе «Настройки › Узел › Во время синхронизации».';

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
    return 'Удаляет $size из $path. Узел остановится, и при следующем запуске весь блокчейн загрузится заново (часы). Ключи и история кошелька не затрагиваются.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Удаляет данные блокчейна из $path. Узел остановится, и при следующем запуске весь блокчейн загрузится заново (часы). Ключи и история кошелька не затрагиваются.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Введите $word для подтверждения.';
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
  String get deskSetLndReuseTitle =>
      'На этом компьютере найдены данные блокчейна';

  @override
  String get deskSetLndReuseDesc =>
      'Другой узел Epic оставил здесь данные блокчейна. Локальный узел может читать эту папку вместо загрузки блокчейна.';

  @override
  String get deskSetLndLooking => 'Поиск…';

  @override
  String get deskSetLndUseIt => 'Использовать';

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
  String get deskSetPeersNotAddress =>
      'Это не IP-адрес с портом, например 203.0.113.5:3414.';

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
  String get deskSetPeersRefreshed => 'Обновляется каждые 10 с';

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
    return '«Впервые» — когда это приложение впервые увидело пир подключённым за этот сеанс; узел не сообщает, когда началось соединение. Блокировка и разблокировка идут через owner API узла. Enter сохраняет максимум (от $min до $max, по умолчанию $def).';
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
  String get deskSetNodePortNote => 'Проверьте адрес и порт (обычно 3413).';

  @override
  String get deskSetNodeListNote =>
      'Состояние по данным status.btlabs.uk, проверяется раз в несколько минут. Задержка измерена с этого компьютера.';

  @override
  String get deskSetNodeStartTitle => 'Запустить локальный узел?';

  @override
  String get deskSetNodeStartDesc =>
      'Отдельная программа синхронизирует блокчейн Epic на этом компьютере.';

  @override
  String get deskSetNodeStartLine1 =>
      'Загружает весь блокчейн: несколько ГБ места на диске и трафика.';

  @override
  String get deskSetNodeStartLine2 =>
      'Первая синхронизация занимает часы. Пока она не закончится, у узла статус «Синхронизация».';

  @override
  String get deskSetNodeStartLine3 =>
      'Брандмауэр может спросить, разрешить ли программу узла.';

  @override
  String get deskSetNodeStartButton => 'Запустить локальный узел';

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
      'Запишите слова на бумаге в этом порядке. Никогда не вводите их на сайтах и в чатах.';

  @override
  String get deskSetPhrasePanel => 'Введите пароль, чтобы показать слова';

  @override
  String get deskSetPhraseShowWords => 'Показать слова';

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
  String get deskSetPhraseHideQr => 'Скрыть QR-код';

  @override
  String get deskSetPhraseShowQr => 'Показать QR-код';

  @override
  String get deskSetPhraseHideWords => 'Скрыть слова';

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
      'Любой, у кого есть эти слова, может забрать EPIC. Убедитесь, что никто не видит экран.';

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
  String deskSetPrivStartingDetail(int progress, String waiting) {
    return '$progress %. $waiting ждут, пока Tor подключится.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Адрес Tor ещё не опубликован. Отправка работает.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Отправка работает.';
  }

  @override
  String get deskSetPrivConnected => 'Подключено.';

  @override
  String get deskSetPrivNotConnected => 'Нет подключения';

  @override
  String deskSetPrivStoppedDetail(String waiting) {
    return 'Tor остановился. $waiting ждут повторной попытки или выключения Tor.';
  }

  @override
  String deskSetPrivProblemDetail(String problem, String waiting) {
    return '$problem. $waiting ждут повторной попытки или выключения Tor.';
  }

  @override
  String get deskSetPrivStatusSite => 'Сайт статуса';

  @override
  String get deskSetPrivUseStatus => 'Использовать status.btlabs.uk';

  @override
  String get deskSetPrivUseStatusHint =>
      'Состояние сети и информация предоставляются status.btlabs.uk';

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
      'Платежи приходят через сервер Epicbox, даже когда кошелёк закрыт.';

  @override
  String get deskSetRecvEpicboxServer => 'Сервер Epicbox';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Какой сервер хранит платежи для этого адреса. У двух кошельков могут быть разные серверы.';

  @override
  String get deskSetRecvSwitchingServer => 'Переключение сервера Epicbox…';

  @override
  String get deskSetRecvListNote =>
      'Состояние по данным status.btlabs.uk, проверяется раз в несколько минут.';

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
  String get deskSetHttpPortError => 'Порт должен быть от 1 до 65535';

  @override
  String get deskSetHttpReachable => 'Доступность';

  @override
  String get deskSetHttpReachableHint => 'Кто может платить на адрес HTTP.';

  @override
  String get deskSetHttpLocalOnly => 'Только локально';

  @override
  String get deskSetHttpFromInternet => 'Из интернета';

  @override
  String get deskSetHttpGuideHelp => 'Приём из интернета: как это работает';

  @override
  String deskSetHttpPublicNote(String port) {
    return 'Отвечает на всех интерфейсах. Роутер должен перенаправлять TCP $port на этот компьютер. Отправители из интернета используют http://<public IP>:$port.';
  }

  @override
  String get deskSetHttpPort => 'Порт';

  @override
  String get deskSetHttpPortHint => 'От 1 до 65535. Используется адресом HTTP.';

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
    return 'Кошелёк отвечает на 0.0.0.0, порт $port. Тогда другие устройства и интернет смогут отправлять платежи на этот кошелёк. Брандмауэр может спросить разрешение.';
  }

  @override
  String get deskSetHttpStep2 => 'Перенаправить порт';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'На странице роутера (часто 10.0.1.1) найдите «Перенаправление портов» (Port forwarding) и перенаправьте TCP $port на этот компьютер.';
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
      'Отчёт шифруется, чтобы прочитать его мог только разработчик. До нажатия «Отправить» ничего не отправляется. «Сохранить в файл» сохраняет тот же очищенный отчёт, но без шифрования.';

  @override
  String get deskSetReportWhat => 'Что произошло';

  @override
  String get deskSetReportWhatHint =>
      'Что вы делали, чего ожидали и что произошло вместо этого';

  @override
  String get deskSetReportContact => 'Контакт';

  @override
  String get deskSetReportContactHint =>
      'Эл. почта или другой контакт для ответа';

  @override
  String get deskSetReportAttach => 'Приложить журналы (рекомендуется)';

  @override
  String get deskSetReportAttachHint =>
      'Последняя часть журнала приложения, очищенная от фраз, паролей, адресов, IP и домашних папок.';

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
  String get deskSetRescanLog => 'Журнал сканирования';

  @override
  String get deskSetRescanText =>
      'Заново читает блокчейн и пересобирает баланс из найденных выходов. Используйте, если баланс выглядит неверным, после восстановления или если выходы остались заблокированными после неудачной отправки. Кошельком можно пользоваться и во время проверки.';

  @override
  String get deskSetRescanStartAgain => 'Запустить снова';

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
    return 'Проверка… $percent %';
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
  String get deskSetRescanFinished => 'Сканирование закончено';

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
  String get deskSetRescanRevived => 'Снова не потрачены';

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
  String get deskSetWalletsImport => 'Импорт';

  @override
  String get deskSetWalletsImportText => 'Из старого Epic Wallet или из папки.';

  @override
  String get deskSetWalletsRestore => 'Восстановление';

  @override
  String get deskSetWalletsRestoreText => 'По фразе восстановления.';

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
  String get deskSetupStepReview => 'Проверка';

  @override
  String get deskSetupAgain =>
      'Повторная настройка. Ничего не изменится до нажатия «Сохранить настройки» на последнем шаге.';

  @override
  String get deskSetupPrefsLead => 'Язык приложения. Его можно изменить позже.';

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
  String get deskSetupEpicboxTitle => 'Приём, пока кошелёк закрыт';

  @override
  String get deskSetupReviewTitle => 'Проверьте настройки';

  @override
  String get deskSetupReviewLead => 'Исправьте то, что не так, и сохраните.';

  @override
  String get deskSetupSideTitle => 'Настройка';

  @override
  String get deskSetupBackToWallet => 'Назад к кошельку';

  @override
  String get deskSetupLaterNote => 'Всё это можно изменить позже в настройках.';

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
      'Запускает узел Epic на этом компьютере. Оператору ничего не передаётся. Нужны место на диске и часы на синхронизацию.';

  @override
  String get deskSetupEpicboxText =>
      'Epicbox доставляет платежи на адрес Epicbox и хранит их, пока кошелёк не появится в сети.';

  @override
  String get deskSetupEpicboxPrivacy =>
      'Он не скрывает IP-адрес от сервера Epicbox. Если это важно, используйте VPN.';

  @override
  String get deskSetupEpicboxServer => 'Сервер Epicbox';

  @override
  String get deskSetupChangePrefsSem => 'Изменить параметры';

  @override
  String get deskSetupChangeNodeSem => 'Изменить узел';

  @override
  String get deskSetupChangeEpicboxSem => 'Изменить Epicbox';

  @override
  String get deskSetupChange => 'Изменить';

  @override
  String get deskSetupType => 'Тип';

  @override
  String get deskSetupAddress => 'Адрес';

  @override
  String deskSetupExistingNode(String host) {
    return 'Уже запущенный узел на $host';
  }

  @override
  String get deskSetupBundledNode => 'Локальный узел, встроенный';

  @override
  String get deskSetupWhileSyncing => 'Во время синхронизации';

  @override
  String get deskSetupWait => 'ждать';

  @override
  String get deskSetupDataFolder => 'Папка данных';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Сохранение запустит узел. Первая синхронизация занимает часы; кошелёк тем временем откроется и до её конца будет использовать $node.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Сохранение запустит узел. Первая синхронизация занимает часы; кошелёк тем временем откроется.';

  @override
  String get deskSetupServer => 'Сервер';

  @override
  String get deskSetupOff => 'Выкл.';

  @override
  String get deskSetAboutLicencesLead =>
      'Открытое ПО в этом кошельке. Каждый компонент сохраняет свою лицензию; полные тексты в одном клике.';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop от BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Браузер не открылся';

  @override
  String get deskSetAboutOpen => 'Открыть';

  @override
  String deskSetAboutVersion(String version) {
    return 'Версия  $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Узел  $version';
  }

  @override
  String get deskSetAboutCommunity => 'Сообщество';

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
  String get deskSetAboutCheckNow => 'Проверить сейчас';

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
      other: 'Найдено тем: $count',
      many: 'Найдено тем: $count',
      few: 'Найдено тем: $count',
      one: 'Найдено тем: $count',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'Темы не найдены';

  @override
  String get deskSetHelpReportText =>
      'Опишите, что пошло не так. Можно приложить журнал приложения: он очищается от секретных данных и шифруется для разработчика. «Сохранить в файл» сохранит копию, чтобы отправить её вручную.';

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
      'Windows не смог защитить секреты кошелька (DPAPI отказал), поэтому ничего не сохранено. Войдите в Windows под своей учётной записью с её паролем, а не через удалённый или служебный сеанс, и попробуйте снова.';

  @override
  String get deskKeyringMissingTitle => 'Связка ключей не найдена';

  @override
  String get deskKeyringMissingText =>
      'Epic Cash хранит свои настройки и запечатанный пароль кошелька в системной связке ключей, но ни одна не ответила. Установите или запустите связку ключей (GNOME Keyring или KWallet), войдите в сеанс рабочего стола, где она работает, затем нажмите «Повторить».';

  @override
  String get deskKeyringLockedTitle => 'Связка ключей заблокирована';

  @override
  String get deskKeyringLockedText =>
      'Epic Cash хранит свои настройки и запечатанный пароль кошелька в системной связке ключей, а она заблокирована. Разблокируйте её (она открывается паролем входа), затем нажмите «Повторить», или нажмите «Разблокировать сейчас», чтобы система запросила пароль.';

  @override
  String get deskKeyringUnlockNow => 'Разблокировать сейчас';

  @override
  String get txStatusNotDelivered => 'Не доставлено';

  @override
  String get txDetailsNotDeliveredBody =>
      'Этот платёж ещё не дошёл до epicbox, поэтому получатель его не получил. Средства остаются заблокированными, пока платёж не отправят повторно или не отменят.';

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
      'Не доставлено. Платёж не дошёл до сервера Epicbox, поэтому получатель его не получил. Отправьте его снова или отмените, чтобы освободить средства.';

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
  String deskSendMessageTooLong(int max) {
    return 'Сообщение длиннее $max байт. Сократите его.';
  }

  @override
  String get deskSetPhraseCopyTitle => 'Скопировать фразу восстановления?';

  @override
  String get deskSetPhraseCopyText =>
      'Любой, у кого есть эти слова, может забрать ваши средства. Храните копию в надёжном месте.';

  @override
  String get deskOutAdvanced => 'Управление выходами';

  @override
  String get deskOutStrategyHint =>
      'Какие выходы тратит отправка. «Наименьшие» тратит как можно меньше мелких выходов, остальные остаются доступными; «Все» тратит всё и возвращает один выход. На странице «Отправить» её можно изменить для одной отправки в разделе «Дополнительно».';

  @override
  String get txStatusNotPosted => 'Не в сети';

  @override
  String get txStatusStalled => 'Застряло';

  @override
  String get txDetailsStalledBody =>
      'Застряло, не доставлено. Ваш платёж ещё не попал в сеть. Отправьте его снова.';

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
  String get deskTxLabelTip =>
      'Название этого платежа, для вас. Показывается в «Активности» и в экспорте.';

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
      'Только для платежей, найденных при сканировании. В «Активности», подробностях и экспорте они помечены как добавленные вами. Суммы, даты и подтверждения не меняются.';

  @override
  String get deskTxDetailsFrom => 'От';

  @override
  String get deskTxDetailsFromTip =>
      'Кто заплатил, для ваших записей. Не проверяется и не используется в подтверждениях платежа.';

  @override
  String get deskTxDetailsFromHint => 'Адрес отправителя';

  @override
  String get deskTxDetailsFromBad =>
      'Укажите адрес Epicbox, http(s) или .onion.';

  @override
  String get deskTxDetailsNote => 'Заметка';

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
          'В файле другие подробности для $n платежа, которые вы описали. Ваши сохраняются, если вы не выберете иначе.',
      many:
          'В файле другие подробности для $n платежей, которые вы описали. Ваши сохраняются, если вы не выберете иначе.',
      few:
          'В файле другие подробности для $n платежей, которые вы описали. Ваши сохраняются, если вы не выберете иначе.',
      one:
          'В файле другие подробности для $n платежа, который вы описали. Ваши сохраняются, если вы не выберете иначе.',
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
          'В истории старого кошелька другие подробности для $n платежа, которые вы описали. Ваши сохраняются, если вы не выберете иначе.',
      many:
          'В истории старого кошелька другие подробности для $n платежей, которые вы описали. Ваши сохраняются, если вы не выберете иначе.',
      few:
          'В истории старого кошелька другие подробности для $n платежей, которые вы описали. Ваши сохраняются, если вы не выберете иначе.',
      one:
          'В истории старого кошелька другие подробности для $n платежа, который вы описали. Ваши сохраняются, если вы не выберете иначе.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Старый кошелёк';

  @override
  String get deskHistConflictApply => 'Применить';

  @override
  String get deskTxProofNone => 'Для этого платежа нет подтверждения платежа.';

  @override
  String get deskUpdAvailable => 'Доступно обновление';

  @override
  String deskUpdNotice(String version) {
    return 'Доступно обновление · $version';
  }

  @override
  String deskUpdDownload(String version) {
    return 'Скачать $version';
  }

  @override
  String get deskUpdOpensPage => 'Открывает страницу загрузки';

  @override
  String deskUpdDownloading(String percent) {
    return 'Загрузка: $percent %';
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
  String get advStateOff => 'Выкл.';

  @override
  String get advIntro =>
      'Сначала всё выключено. Каждый переключатель добавляет ещё одну часть кошелька в то место, которому она принадлежит.';

  @override
  String get advShowsHeader => 'Показывает больше';

  @override
  String get advNetworkHeader => 'Сеть';

  @override
  String get advNetworkHint =>
      'Как кошелёк выходит в сеть. «Стандартный» подключается напрямую; Tor можно включить в разделе «Приватность и сеть». «Только Tor» никогда не подключается напрямую: без Tor кошелёк остаётся офлайн и говорит об этом на главном экране. «Офлайн» остаётся на этом телефоне и в вашей локальной сети: «Оплата по QR» и «Передача файла» по-прежнему работают через используемый узел; с узлом в вашей сети можно также отправлять на локальные адреса, и баланс обновляется.';

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
      'Показывает «Стратегию» отправки и «Делить сдачу» в «Настройки › Транзакции»: какие выходы тратит отправка и делится ли её сдача. Остаётся видимым, пока что-то из этого не по умолчанию.';

  @override
  String get advServerDetails => 'Сведения о серверах';

  @override
  String get advServerDetailsHint =>
      'Показывает хосты, задержку, версию и высоту блока в списках серверов и на карточке состояния, а также адрес ретранслятора в «Получить».';

  @override
  String get advRecheckHeight => 'Сверка с заданной высоты';

  @override
  String get advRecheckHeightHint =>
      'Позволяет начать «Сверку баланса» с высоты блока или с даты, а не с первого блока. Быстрее, и это единственный способ пропустить раннюю историю. При восстановлении выбор есть всегда.';

  @override
  String get advModeStandard => 'Стандартный';

  @override
  String get advModeStandardLine =>
      'Подключается напрямую. Tor можно включить в разделе «Приватность и сеть».';

  @override
  String get advModeTorOnly => 'Только Tor';

  @override
  String get advModeTorOnlyLine =>
      'Каждое соединение идёт через Tor. Без Tor кошелёк остаётся офлайн и сообщает об этом.';

  @override
  String get advModeOffline => 'Офлайн';

  @override
  String get advModeOfflineLine =>
      'Только этот телефон и ваша локальная сеть. «Оплата по QR» и «Передача файла» по-прежнему работают через используемый узел; всё остальное ждёт, пока вы не переключитесь обратно.';

  @override
  String get advTorOnlyNote =>
      'Режим «Только Tor» приостанавливает уведомления: подписка на них раскрыла бы адрес этого телефона.';

  @override
  String get advOfflineNote =>
      'Офлайн приостанавливает Epicbox, Tor, проверки состояния и уведомления. «Оплата по QR» и «Передача файла» по-прежнему работают: они используют текущий узел для чтения цепочки и отправки, в том числе публичный. С узлом в вашей локальной сети также работают «Сверка баланса» и отправка через «Ссылку» на локальные адреса. Пиры узла — настройка самого узла.';

  @override
  String get advReset => 'Скрыть всё снова';

  @override
  String get advHomeOffline => 'Офлайн-режим';

  @override
  String get advHomeTorOnlyWaiting => 'Только Tor · ждёт Tor';

  @override
  String get advBuiltInNode => 'Встроенный узел';

  @override
  String get advLogs => 'Журналы';

  @override
  String get deskSetFrameAdvanced => 'Дополнительно';

  @override
  String get deskSetAdvIntro =>
      'Сначала всё выключено. Каждый переключатель добавляет ещё одну часть кошелька в то место, которому она принадлежит.';

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
      'Показывает раздел «Технические сведения» у каждой транзакции: ID слейта, ядро, высоту блока, состояние и тип ядра и подтверждение платежа. Без этого ссылка «Ещё» у транзакции показывает их один раз. В «Счетах» показывает дополнительные разделы.';

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
  String get deskSetAdvBuiltInNode => 'Встроенный узел';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'Позволяет этому компьютеру запускать собственный узел: пункт «Этот компьютер» в разделе «Узел», его панель синхронизации и «Запустить узел» на обзоре. Синхронизация цепочки занимает часы и несколько гигабайт на диске. Работающий узел сохраняет свои строки.';

  @override
  String get deskSetAdvLogs => 'Журналы';

  @override
  String get deskSetAdvLogsHint =>
      'Показывает группу «Журналы» в разделе «Справка»: открыть папку журналов, очистить журналы. «Сообщить о проблеме» прикладывает журнал в любом случае.';

  @override
  String get deskSetAdvNetwork => 'Сеть';

  @override
  String get deskSetAdvNetworkHint =>
      'Как кошелёк выходит в сеть. «Стандартный» подключается напрямую; Tor можно включить в разделе «Приватность». «Только Tor» никогда не подключается напрямую: без Tor кошелёк остаётся офлайн и говорит об этом в боковой панели. «Офлайн» остаётся на этом компьютере и в вашей локальной сети: «Передача файла» по-прежнему работает через используемый узел; с узлом здесь или в вашей сети можно также отправлять на локальные адреса и получать через «Ссылку», и баланс обновляется. Встроенный узел продолжает работать, а его пиры — настройка самого узла.';

  @override
  String get deskSetAdvModeStandard => 'Стандартный';

  @override
  String get deskSetAdvModeStandardText =>
      'Подключается напрямую. Tor можно включить в разделе «Приватность».';

  @override
  String get deskSetAdvModeTorOnly => 'Только Tor';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'Каждое соединение идёт через Tor. Без Tor кошелёк остаётся офлайн и сообщает об этом.';

  @override
  String get deskSetAdvModeOffline => 'Офлайн';

  @override
  String get deskSetAdvModeOfflineText =>
      'Только этот компьютер и ваша локальная сеть. Ваш узел продолжает работать; его пиры — настройка самого узла.';

  @override
  String get deskSetAdvTorOnlyNote =>
      'Режим «Только Tor» отключает приём по Ссылка · HTTP: обычный адрес раскрыл бы этот компьютер.';

  @override
  String get deskSetAdvOfflineNote =>
      'Epicbox, Tor и проверки состояния приостановлены. «Передача файла» по-прежнему работает через используемый узел, в том числе публичный. С узлом на этом компьютере или в вашей сети также работают «Сверка баланса» и отправка через «Ссылку» на локальные адреса.';

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
  String get deskShellOffline => 'Офлайн-режим';

  @override
  String get deskShellTorOnlyWaiting => 'Только Tor · ждёт Tor';

  @override
  String get deskSetAcctAutoLockHint =>
      'Блокирует кошелёк, если столько времени не нажимали клавиши и не двигали мышь. При «Никогда» кошелёк блокируется только кнопкой «Заблокировать кошелёк».';

  @override
  String get netBlockOffline => 'Офлайн-режим включён в «Дополнительно».';

  @override
  String get netBlockTorOnly => 'Режим «Только Tor» включён в «Дополнительно».';

  @override
  String get netBlockWaitingForTor => 'Ждёт Tor.';

  @override
  String get receiveOfflineLine => 'В офлайн-режиме так получать нельзя.';

  @override
  String get txDetailsMore => 'Ещё';

  @override
  String get restoreStartFromLink => 'Начать с даты или высоты';

  @override
  String get homeOfflineDetail =>
      'Офлайн-режим включён в «Дополнительно». Баланс — последний из виденных.';

  @override
  String get homeWaitingTorDetail =>
      'Режим «Только Tor» включён в «Дополнительно». Ждём подключения Tor.';

  @override
  String get settingsRescanBodyPlain =>
      'Кошелёк заново ищет свои средства, с первого блока. Это может занять много времени.';

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
  String get slSwitchBody => 'Ваш адрес Epicbox изменится. Поделитесь новым.';

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
  String get slRestore => 'Восстановить удалённые серверы';

  @override
  String slRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count удалено',
      many: '$count удалено',
      few: '$count удалено',
      one: '$count удалён',
    );
    return '$_temp0';
  }

  @override
  String get slRestored => 'Удалённые серверы восстановлены.';

  @override
  String get slRelayWarning =>
      'При переключении ваш адрес изменится; отправителям нужен новый.';

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
  String get deskOnbRestoreFromLink => 'Начать с высоты блока';

  @override
  String get deskOnbRestoreFromHide => 'Проверить весь блокчейн';

  @override
  String get deskOnbRestoreFromLabel => 'Начать с блока';

  @override
  String get deskOnbRestoreFromHint => 'Высота блока';

  @override
  String get deskOnbRestoreFromHelp =>
      'Только если первый платёж кошелька пришёл после этого блока. Оставьте пустым, чтобы проверить весь блокчейн.';

  @override
  String get deskOnbRestoreFromInvalid =>
      'Введите только цифры или оставьте пустым.';

  @override
  String get deskNetOfflineReason => 'Офлайн-режим включён в «Дополнительно».';

  @override
  String get deskNetWaitingTorReason =>
      'Ждёт Tor. Режим «Только Tor» включён в «Дополнительно».';

  @override
  String get deskNetTorOnlyLine =>
      'Режим «Только Tor» включён в «Дополнительно».';

  @override
  String get deskNetOpenAdvanced => 'Открыть «Дополнительно»';

  @override
  String get deskNetSendFileHint => 'Передача файла по-прежнему работает.';

  @override
  String get deskNetRecvOfflineText =>
      'Ваш адрес не меняется. Ничего не придёт, пока включён офлайн-режим.';

  @override
  String get deskNetRecvWaitTorText =>
      'Приём начнётся, когда Tor подключится. Передача файла по-прежнему работает.';

  @override
  String get deskNetCantReceive => 'Офлайн получать нельзя.';

  @override
  String get deskRailOffline => 'Офлайн';

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
  String get settingsHubMethods => 'Способы';

  @override
  String get settingsHubDefault => 'По умолчанию';

  @override
  String get settingsHubSendDefaults => 'Настройки отправки';

  @override
  String get txMethodsHeader => 'Способы оплаты';

  @override
  String get txFamilyLinkLine => 'Прямо в другой кошелёк, пока оба открыты.';

  @override
  String get txFamilyDirectLine => 'Из рук в руки, без связи между кошельками.';

  @override
  String get txLinkHttpLine =>
      'Платите на веб-адреса; получайте платежи из этой сети Wi-Fi.';

  @override
  String get txLinkHttpHint =>
      'Ссылка · HTTP платит прямо в кошелёк по веб-адресу (http://host:3415) и даёт этому телефону адрес, на который могут платить кошельки из той же сети Wi-Fi. Оба кошелька должны быть открыты. По дороге он не шифруется, недоступен из интернета и по мобильным данным и выключен, пока включён Tor. Добавляет Ссылка · HTTP в «Отправить» и «Получить».';

  @override
  String get txLinkTorLine =>
      'Платите на адреса onion; получайте платежи на адрес Tor этого телефона.';

  @override
  String get txLinkTorHint =>
      'Ссылка · Tor платит прямо в кошелёк по адресу onion и даёт этому телефону адрес Tor, на который ему можно платить. Оба кошелька должны быть открыты. Нужен Tor: переключатель Tor в «Приватность и сеть» направляет соединения кошелька через Tor; этот переключатель только включает адрес. Добавляет Ссылка · Tor в «Отправить» и «Получить».';

  @override
  String get txLinkTorNeedsTor =>
      'Нужен Tor. Включите его в «Приватность и сеть».';

  @override
  String get txLastMethodNotice =>
      'Хотя бы один способ оплаты должен остаться включённым.';

  @override
  String get txEpicboxHint =>
      'Epicbox платит через релей, поэтому другому кошельку не нужно быть открытым. Выключен: кошелёк не подключается ни к одному релею, то есть без платежей Epicbox, счетов и уведомлений. Остальные способы по-прежнему работают.';

  @override
  String get txDirectLine =>
      'Платите на веб-адреса и адреса onion; получайте платежи напрямую от других кошельков.';

  @override
  String get txDirectHint =>
      '«Ссылка» платит прямо в другой кошелёк по веб-адресу или адресу onion и позволяет этому телефону получать платежи так же. Оба кошелька должны быть открыты. HTTP работает в этой сети Wi-Fi; Tor требует Tor. Добавляет «Ссылку» в «Отправить» и «Получить».';

  @override
  String get txFileLine =>
      'Платите или получайте платежи файлом, который вы передаёте сами.';

  @override
  String get txFileHint =>
      '«Передача файла» создаёт файл транзакции, который вы передаёте другому человеку любым способом (сообщением, письмом, кабелем), а он передаёт вам ответный. Связь между кошельками не нужна. Добавляет «Передачу файла» в «Отправить» и «Получить».';

  @override
  String get txStartHeader => 'Отправка начинается с';

  @override
  String get txStartNote =>
      'В «Отправить» можно по-прежнему выбрать другой способ.';

  @override
  String get txDefaultsHeader => 'Настройки отправки';

  @override
  String get outputsDefaultsMoved =>
      'Настройки отправки теперь в «Настройки › Транзакции»';

  @override
  String get advNodeFailover => 'Автопереключение узла';

  @override
  String get advNodeFailoverHint =>
      'Когда ваш узел перестаёт отвечать, кошелёк на время этого сеанса берёт следующий работающий узел из вашего списка.';

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
  String get netOfflineOnlyLocal => 'Офлайн: только локальные адреса.';

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
      'Epicbox выключен в разделе Настройки › Транзакции.';

  @override
  String netBlockMethodOff(String method) {
    return 'Способ «$method» выключен в Настройки › Транзакции.';
  }

  @override
  String get txEpicboxLine =>
      'Платите или получайте платежи через релей. Другой кошелёк может быть закрыт.';

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
  String get pushNoticeOffEpicbox => 'Уведомления выключены: им нужен Epicbox.';

  @override
  String get settingsPushNeedsEpicbox => 'Нужен Epicbox';

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
      'Платежи отправителей ждут на релее, пока Epicbox снова не включён.';

  @override
  String get receiveNoMethods => 'Ни один способ приёма не включён';

  @override
  String get receiveNoMethodsBody =>
      'Включите один в разделе Настройки › Транзакции.';

  @override
  String get receiveNoMethodsButton => 'Открыть настройки';

  @override
  String get deskErrOfflineOnlyLocal => 'Офлайн: только локальные адреса.';

  @override
  String get deskNetOfflineNoPeers =>
      'У вашего узла нет пиров: платёж ждёт в его пуле, пока он не подключится снова.';

  @override
  String get deskOutDefaultsMoved =>
      '«Стратегия» и «Делить сдачу» для отправок задаются в «Настройки › Транзакции».';

  @override
  String get deskOutDefaultsOpen => 'Открыть «Транзакции»';

  @override
  String get deskSetFrameTransactions => 'Транзакции';

  @override
  String get deskSetTxMethods => 'Способы оплаты';

  @override
  String get deskSetTxEpicboxHint =>
      'Платите и получайте платежи через сервер Epicbox. Так идёт большинство платежей. Выключен: кошелёк не подключается ни к одному серверу Epicbox, то есть без платежей Epicbox и счетов. Остальные способы по-прежнему работают.';

  @override
  String get deskSetTxDirectHint =>
      'Платите и получайте платежи напрямую от кошелька к кошельку по веб-адресу (http://host:3415), без сервера посередине. Работает, только пока оба кошелька открыты; выключен, пока включён Tor. Добавляет Ссылка · HTTP в «Отправить», а его адрес — в «Получить».';

  @override
  String get deskSetTxFileHint =>
      'Платите и получайте платежи, передавая файл транзакции, сеть не нужна. Добавляет «Передачу файла» в «Отправить», а шаги с файлами — в «Получить».';

  @override
  String get deskSetTxSend => 'Отправка';

  @override
  String get deskSetTxStart => 'Отправка начинается с';

  @override
  String get deskSetTxStartHint =>
      'Способ, с которого открывается страница «Отправить». Для одного платежа его всё равно можно изменить на странице «Отправить».';

  @override
  String get deskSendMethodHeader => 'Способ оплаты';

  @override
  String get sendRequestTitle => 'Запрос на оплату';

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
  String get payeeNameLabel => 'Имя, указанное получателем (не проверено)';

  @override
  String get payeeNoteLabel => 'Заметка получателя (не проверена)';

  @override
  String get payeeUnverifiedTitle => 'Не проверено';

  @override
  String get payeeUnverifiedHint =>
      'Имя и заметку записывает в код тот, кто его создал. Их никто не проверяет. Проверяйте адрес и сумму, а не имя.';

  @override
  String get sendNoteFromCodeHelper => 'Из кода. Получатель тоже её увидит.';

  @override
  String get sendOriginQr => 'Из QR-кода';

  @override
  String get sendOriginLink => 'Из ссылки';

  @override
  String get sendOriginPasted => 'Вставлено';

  @override
  String get sendDirectHost => 'Хост';

  @override
  String get sendPlainHttpRow => 'Без шифрования (обычный HTTP)';

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
      'Код «Оплата по QR». Отсканируйте его в Epic Cash Mobile.';

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
  String get deskRecvTorOffTitle => 'Для приёма через Ссылка · Tor нужен Tor.';

  @override
  String get deskRecvTorOffText =>
      'Адрес Tor работает, пока включён Tor. Tor — переключатель в Настройки › Приватность; он направляет соединения кошелька через Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Настройки не сохранены';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Без сохранения кошелёк использует настройки, сохранённые до сих пор. Их можно изменить позже в настройках.';
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
      'Подписано и возвращено. По словам отправителя, отправлено в сеть; платёж будет выполнен, когда блокчейн его подтвердит.';

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
  String get pairLead =>
      'Выполните сопряжение с собеседником один раз. После этого файлы платежей и счета между двумя кошельками запечатаны: прочитать их могут только эти два кошелька.';

  @override
  String get pairInPerson => 'Лично';

  @override
  String get pairInPersonHint =>
      'Покажите свой код и отсканируйте код собеседника';

  @override
  String get pairOnline => 'Онлайн';

  @override
  String get pairOnlineHint =>
      'Отправьте ссылку-приглашение или зачитайте слова сопряжения';

  @override
  String get pairOfflineHint =>
      'Вы офлайн. Приглашение и ответ передаются вручную.';

  @override
  String get pairEnter => 'Ввести ссылку или слова';

  @override
  String get pairEnterHint =>
      'Вставьте ссылку-приглашение или введите полученные слова';

  @override
  String get pairNotPaired => 'Не сопряжён';

  @override
  String get pairNotPairedHint =>
      'Сопряжение запечатывает файлы платежей и позволяет разрешить счета.';

  @override
  String get pairInPersonTitle => 'Сопряжение лично';

  @override
  String get pairShowMyCode => 'Показать мой код';

  @override
  String get pairScanTheirs => 'Сканировать код';

  @override
  String get pairShowCodeCaption =>
      'Дайте отсканировать этот код, затем отсканируйте код собеседника.';

  @override
  String get pairScanCaption =>
      'Сканируют оба. Проверка слов откроется, когда оба кода считаны.';

  @override
  String get pairScanPrompt => 'Наведите камеру на код собеседника';

  @override
  String get pairSeenAs => 'Собеседник увидит вас как';

  @override
  String get pairUseWords => 'Использовать слова';

  @override
  String get pairCameraDeniedTitle => 'Доступ к камере не разрешён';

  @override
  String get pairCameraDeniedBody =>
      'Разрешите камеру для сканирования или используйте слова.';

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
      'Для слов сопряжения нужен Epicbox, поэтому сейчас они недоступны.';

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
  String get pairEnterDesktopHint =>
      'Вставленная ссылка или введённые слова заменяют сканирование на телефоне.';

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
    return 'Вставьте эту ссылку в кошельке $name в поле «Ввести ссылку или слова». Затем вместе сверьте слова.';
  }

  @override
  String get pairEnterDesktopPlaceholder =>
      'Вставьте ссылку-приглашение или введите пять слов';

  @override
  String get pairOnlineTitle => 'Сопряжение онлайн';

  @override
  String get pairOnlineLead =>
      'Отправьте приглашение по любому каналу, которым вы уже пользуетесь с собеседником. Сопряжение завершится, когда его кошелёк откроет приглашение.';

  @override
  String get pairOnlineLeadByHand =>
      'Отправьте приглашение по любому каналу, которым вы уже пользуетесь с собеседником. Ответ придёт тем же путём: вставьте его в «Ввести ссылку или слова».';

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
  String pairShareText(String name, String link, String date) {
    return '$name предлагает сопрячь кошельки Epic Cash. Действует до: $date.\n\nОткрыть в Epic Cash:\n$link';
  }

  @override
  String get pairShareWarning =>
      'Любой, у кого есть это приглашение, может выполнить сопряжение от вашего имени, пока оно действует. Отправляйте его только нужному человеку, затем проверьте слова вместе.';

  @override
  String get pairShareInvite => 'Поделиться';

  @override
  String get pairCopyInvite => 'Копировать приглашение';

  @override
  String get pairUseWordsShort => 'Слова';

  @override
  String get pairInviteSentTitle => 'Приглашение отправлено';

  @override
  String pairInviteSentBody(String name) {
    return 'Сопряжение завершится, когда кошелёк $name откроет приглашение. Можно уйти с этого экрана; приглашение останется в «Контакты › Ожидающие приглашения».';
  }

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
    return 'Сопрячь: $name?';
  }

  @override
  String get pairNameClaimed => 'Имя выбрано собеседником · ещё не проверено';

  @override
  String get pairNameClaimedShort => 'Имя выбрано собеседником';

  @override
  String pairCallsThemselves(String name) {
    return 'Называет себя «$name»';
  }

  @override
  String pairIncomingBody(String name) {
    return 'После сопряжения файлы платежей и счета между вами и $name запечатаны. Затем вы вместе проверите слова.';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return 'Разрешить $name запрашивать оплату';
  }

  @override
  String get pairIncomingAllowHintDesktop =>
      'Включится после проверки слов. Без пароля кошелька ничего не оплачивается.';

  @override
  String get pairIncomingAllowHint =>
      'Включится после проверки слов. Без вашего PIN ничего не оплачивается.';

  @override
  String get pairNotNow => 'Не сейчас';

  @override
  String pairWaitingTitle(String name) {
    return 'Ожидание кошелька $name…';
  }

  @override
  String get pairWaitingBody =>
      'Другой кошелёк ответит, когда его откроют. Это можно закрыть; сопряжение продолжится в фоне, а проверка слов появится, когда оно завершится.';

  @override
  String get pairSendByHand => 'Отправить вручную';

  @override
  String get pairRelayUnreachableTitle => 'Ретранслятор недоступен';

  @override
  String get pairRelayUnreachableBody => 'Отправить ответ вручную?';

  @override
  String get pairRelayUnreachableTor =>
      'Ретранслятор недоступен через Tor. Отправить ответ вручную?';

  @override
  String get pairNoRelay =>
      'Ни один ретранслятор для сопряжения недоступен. Сопрягите кошельки по ссылке-приглашению.';

  @override
  String get pairRelaysBlocked =>
      'Эта сеть блокирует ретрансляторы для сопряжения. Причиной может быть сетевой фильтр. Сопрягите кошельки по ссылке-приглашению.';

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
  String get pairExpiredTitle => 'Срок приглашения истёк';

  @override
  String pairExpiredBody(String name) {
    return 'Попросите у $name новое.';
  }

  @override
  String get pairUsedTitle => 'Это приглашение уже использовано';

  @override
  String get pairUsedBody => 'Попросите новое.';

  @override
  String pairCancelledTitle(String name) {
    return '$name: приглашение отменено';
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
  String get pairChangedTitle => 'Приглашение изменено в пути';

  @override
  String pairChangedBody(String name) {
    return 'Ничего не сохранено. Повторите сопряжение лично или с новым приглашением от $name.';
  }

  @override
  String get pairNewerTitle => 'Обновите Epic Cash, чтобы открыть это';

  @override
  String get pairNewerInviteBody =>
      'Это приглашение создано более новым кошельком.';

  @override
  String get pairNewerFileBody => 'Файл запечатан более новым кошельком.';

  @override
  String get pairCheckForUpdates => 'Проверить обновления';

  @override
  String pairSecondReplyTitle(String name) {
    return 'На приглашение $name ответил кто-то ещё. См. «Ожидающие приглашения».';
  }

  @override
  String get pairAnsweredSameInvite =>
      'Ответ на то же приглашение · не сохранён';

  @override
  String get sasTitle => 'Проверить слова';

  @override
  String sasLead(String name) {
    return 'Кошелёк $name показывает те же четыре. Сравните их по телефону или лично.';
  }

  @override
  String sasLeadExchange(String name) {
    return 'Страница $name показывает те же четыре. Сравните их, затем подтвердите с обеих сторон.';
  }

  @override
  String sasLeadRecheck(String name) {
    return 'Кошелёк $name показывает их в «$name › Проверить слова». Сравните их по телефону или лично.';
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
      'Возможно, кто-то изменил приглашение в пути. Ничего не сохраняется. Повторите сопряжение лично или с новым приглашением.';

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
    return 'Слова проверены $date';
  }

  @override
  String get contactCheckAgain => 'Проверить снова';

  @override
  String get contactCheckWordsAgain => 'Проверить слова снова';

  @override
  String get contactSealPayments => 'Запечатывать платежи';

  @override
  String contactSealInfo(String name) {
    return 'Платежи и счета с $name зашифрованы сквозным шифрованием. Прочитать их может только кошелёк $name.';
  }

  @override
  String contactSealInfoMore(String name) {
    return 'Если выключено, файл платежа для $name открытый: любой, кто получит файл, может его прочитать. Выключайте, только если кошелёк $name не открывает запечатанные файлы.';
  }

  @override
  String get contactAllowInvoices => 'Разрешить счета';

  @override
  String contactAllowInfoDesktop(String name) {
    return 'Кошелёк $name может присылать вам запросы на оплату. Каждый ждёт в «Счетах» вашего одобрения и пароля кошелька. Само по себе ничего не оплачивается.';
  }

  @override
  String contactAllowInfo(String name) {
    return 'Кошелёк $name может присылать вам запросы на оплату. Каждый ждёт в «Счетах» вашего одобрения и PIN. Само по себе ничего не оплачивается.';
  }

  @override
  String get contactAllowInfoMore =>
      'Разрешить можно только проверенному контакту: проверка слов исключает подменённое приглашение.';

  @override
  String get contactCheckWordsFirst => 'Сначала проверьте слова';

  @override
  String get contactPausedUntilChecked => 'Приостановлено до проверки слов';

  @override
  String contactDeliveredVia(String relay) {
    return 'Доставка через $relay';
  }

  @override
  String contactRelayDownTitle(String name) {
    return 'Ретранслятор $name не отвечает';
  }

  @override
  String get contactRelayDownBody =>
      'Повторная попытка. Запросы и платежи ждут, пока он ответит; ничего не теряется.';

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
      'Это может значить, что теперь у этого человека другой кошелёк или что кто-то другой использует это имя. Проверьте слова снова.';

  @override
  String get contactKeysChangedStatus => 'запечатывание и счета приостановлены';

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
  String get addrDesktopRule =>
      'Один адрес на тип. Третье поле появляется, только пока какой-то тип свободен.';

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
    return 'Слова сопряжения · истекают через $time';
  }

  @override
  String get pendingExpired => 'Истекло';

  @override
  String get pendingInviteAgain => 'Пригласить снова';

  @override
  String pendingWaitingConfirm(String time) {
    return 'Ждёт подтверждения · $time';
  }

  @override
  String get pendingPairedCheck => 'Сопряжено · проверьте слова';

  @override
  String get pendingEmpty =>
      'Ожидающих приглашений нет. Приглашение видно здесь, пока другой кошелёк не ответит на него.';

  @override
  String get pendingShareAgain => 'Поделиться снова';

  @override
  String get pendingShowWords => 'Показать слова';

  @override
  String get pendingCopyLink => 'Копировать ссылку';

  @override
  String get invSetTitle => 'Счета';

  @override
  String get invSetLead =>
      'Сопряжённый контакт, которому вы разрешите, может присылать вам запросы на оплату. Каждый ждёт в «Счетах» вашего PIN.';

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
      'Сопряжённых контактов пока нет. Выполните сопряжение с магазином, биржей или человеком, проверьте слова, затем разрешите здесь их счета.';

  @override
  String get invSetPausedBody =>
      'Запросы ждут на ретрансляторе и придут, когда Epicbox снова включится.';

  @override
  String invSetSwitchedOff(String name) {
    return 'Счета от $name выключены.';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отклонено $count открытого запроса.',
      many: 'Отклонено $count открытых запросов.',
      few: 'Отклонено $count открытых запроса.',
      one: 'Отклонён $count открытый запрос.',
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
  String get reqTitle => 'Проверить запрос';

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
      'Ваша часть выполнена. Биржа завершает и публикует; это закроется само.';

  @override
  String get reqTlPaid => 'Оплачено';

  @override
  String reqTlDelivered(String name) {
    return 'Доставлено на ретранслятор $name';
  }

  @override
  String reqTlAnswerDelivered(String name) {
    return 'Ответ доставлен на ретранслятор $name';
  }

  @override
  String reqTlPosted(String name) {
    return 'Опубликовано: $name';
  }

  @override
  String get reqTlPostedHint => 'Обычно в течение нескольких минут';

  @override
  String get reqTlConfirming => 'Подтверждается';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n из $total подтверждений';
  }

  @override
  String get reqTlConfirmed => 'Подтверждено';

  @override
  String reqTlWaiting(String time) {
    return 'Ожидание $time';
  }

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
      'Ваши средства в безопасности; они разблокируются, если платёж не опубликуют. Доставка повторяется.';

  @override
  String get reqRelayRetrying => 'Ретранслятор не отвечает · повтор';

  @override
  String reqWithdrewTitle(String name) {
    return '$name: запрос отозван';
  }

  @override
  String get reqWithdrewBody =>
      'Ваши средства разблокированы. Ничего не оплачено.';

  @override
  String reqWithdrewUnpaid(String name) {
    return '$name: этот запрос отозван';
  }

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name: $count запроса на $amount EPIC за 10 минут. Оплатить все?',
      many: '$name: $count запросов на $amount EPIC за 10 минут. Оплатить все?',
      few: '$name: $count запроса на $amount EPIC за 10 минут. Оплатить все?',
      one: '$name: $count запрос на $amount EPIC за 10 минут. Оплатить?',
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
      'Ничего делать не нужно. Биржа публикует платёж; подтверждения последуют.';

  @override
  String get reqNewTitle => 'Новый запрос';

  @override
  String get reqNewLead =>
      'Попросите сопряжённый контакт оплатить или сохраните запрос файлом для кого угодно.';

  @override
  String get reqNewLeadContacts => 'Попросите сопряжённый контакт оплатить.';

  @override
  String get reqNewTo => 'Кому';

  @override
  String get reqNewToHintContacts =>
      'Сопряжённые контакты, чей кошелёк оплачивает запросы.';

  @override
  String get reqNoPayersContacts =>
      'Пока ни один сопряжённый контакт не оплачивает запросы. Выполните сопряжение и проверьте слова.';

  @override
  String get reqNewToHint =>
      'Сопряжённые контакты, чей кошелёк оплачивает запросы. Для остальных: сохраните запрос файлом.';

  @override
  String get reqNewSaveFile => 'Сохранить файлом';

  @override
  String get reqNewSend => 'Отправить запрос';

  @override
  String sendViaMailbox(String name) {
    return 'Отправить через почтовый ящик $name';
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
    return '$name: ответ на ваше приглашение. Проверьте слова вместе.';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'Сопряжено: $name. Проверьте слова вместе.';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name запрашивает $amount EPIC. Проверьте в «Счетах».';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return 'Получено $amount EPIC от $name. Ждём публикации.';
  }

  @override
  String noticeKeysChanged(String name) {
    return 'Ключи $name изменились. Проверьте слова снова перед оплатой.';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return '$name: пара с новыми ключами. Старые ключи проверить не удалось: проверка одна в сутки, и она уже была.';
  }

  @override
  String noticeRelayDown(String name) {
    return 'Ретранслятор $name не отвечает. Повторная попытка.';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name: запрос отозван. Ваши средства разблокированы.';
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
  String restorePairingsOnOtherDevice(int count) {
    return '$count · на другом устройстве';
  }

  @override
  String get pairInviteSentBodyAnyone =>
      'Сопряжение завершится, когда другой кошелёк откроет приглашение. Можно уйти с этого экрана; приглашение останется в «Контакты › Ожидающие приглашения».';

  @override
  String get pairInvalidLink => 'Это не ссылка для сопряжения';

  @override
  String get pairInvalidBody =>
      'Проверьте, что ссылка скопирована целиком, или попросите новую.';

  @override
  String get pairWrongNetworkBody =>
      'Его создал кошелёк в другой сети. Кошельки сопрягаются только в одной сети.';

  @override
  String get pairOwnCode => 'Это ваш собственный код';

  @override
  String get pairOwnCodeBody => 'Отсканируйте код на другом телефоне.';

  @override
  String get pairUnnamedInvite => 'Открытое приглашение';

  @override
  String get pairSeenAsMissing => 'Введите имя, которое увидит собеседник.';

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
    return 'Проверить слова с $name';
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
      'Сопряжённый контакт, которому вы разрешите, может присылать этому кошельку запросы на оплату. Каждый ждёт в «Счетах» пароля кошелька.';

  @override
  String get invSetRowAllowed => 'Проверено · разрешено';

  @override
  String get invSetRowOff => 'Проверено · выключено';

  @override
  String get invSetRowCheckFirst =>
      'Сопряжено, не проверено · сначала проверьте слова';

  @override
  String invSetAllowFor(String name) {
    return 'Разрешить счета от $name';
  }

  @override
  String get reqNoPayers =>
      'Пока ни один сопряжённый контакт не оплачивает запросы. Выполните сопряжение и проверьте слова или сохраните запрос файлом.';

  @override
  String get reqPickContact => 'Выберите контакт';

  @override
  String get reqFileSaved => 'Запрос сохранён файлом';

  @override
  String reqSent(String name) {
    return 'Запрос отправлен: $name';
  }

  @override
  String get reqFileTitle => 'Запрос на оплату';

  @override
  String noticeOutboxStuck(String name) {
    return '$name пока недоступен. Ваши средства в безопасности.';
  }

  @override
  String noticeTooMany(String name) {
    return '$name: слишком много запросов. Лишние отброшены. Выключите счета этого контакта, если это повторяется.';
  }

  @override
  String get noticeOpen => 'Открыть';

  @override
  String get noticeCheckWords => 'Проверить слова';

  @override
  String get noticeView => 'Показать';

  @override
  String get restorePairings => 'Сопряжения';

  @override
  String get pairingDesktopShowCodeLead =>
      'Дайте отсканировать этот код телефоном или зачитайте слова сопряжения.';

  @override
  String get pairingDesktopInviteLead =>
      'Отправьте приглашение по любому каналу, которым вы уже пользуетесь с собеседником. Сопряжение завершится, когда его кошелёк откроет приглашение.';

  @override
  String get pairingInviteOnline => 'Пригласить онлайн';

  @override
  String pairSaveContactTitle(String name) {
    return 'Сохранить $name в контактах?';
  }

  @override
  String get pairSaveNewContact => 'Сохранить как новый контакт';

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
  String get pairAddToContacts => 'Добавить в контакты';

  @override
  String get helpPairingSection => 'Сопряжение';

  @override
  String get helpPairingLede =>
      'Сопряжение выполняется один раз; файлы платежей и счета с этим контактом запечатаны.';

  @override
  String get helpPairWhatTitle => 'Что такое сопряжение';

  @override
  String get helpPairWhatShort =>
      'Выполните сопряжение с собеседником один раз; после этого файлы платежей и счета между двумя кошельками запечатаны.';

  @override
  String get helpPairWhatP1 =>
      'Сопряжение связывает два кошелька один раз: лично, когда вы сканируете коды друг друга, или онлайн через ссылку-приглашение или пять слов сопряжения. Каждый кошелёк хранит ключ, созданный только для этого контакта; ничего из этого не передаётся серверу Epicbox.';

  @override
  String get helpPairWhatP2 =>
      'После сопряжения файл платежа для этого контакта **запечатан**: открыть его может только кошелёк контакта, и в пути его нельзя изменить или подделать. Платежи через Epicbox между людьми работают как прежде.';

  @override
  String get helpPairWhatStep1 =>
      'Откройте [[Контакты|Contacts]] и выберите **Сопрячь**.';

  @override
  String get helpPairWhatStep2 =>
      'Лично: покажите свой код, отсканируйте код собеседника. Онлайн: отправьте приглашение или зачитайте слова сопряжения.';

  @override
  String get helpPairWhatStep3 =>
      'Проверьте слова вместе, затем **Совпадают**.';

  @override
  String get helpPairWhatP3 =>
      'Для сопряжения нужен Epic Cash с обеих сторон. Несопряжённый контакт по-прежнему получает обычные файлы платежей и платежи Epicbox.';

  @override
  String get helpPairWhyTitle => 'Зачем проверять слова';

  @override
  String get helpPairWhyShort =>
      'Четыре слова доказывают, что сопряжение дошло до нужного кошелька, а не до посредника.';

  @override
  String get helpPairWhyP1 =>
      'После сопряжения оба кошелька показывают одни и те же четыре картинки с названиями. Они получаются из ключей обоих кошельков, поэтому сопряжение, изменённое в пути, покажет на двух экранах разные слова.';

  @override
  String get helpPairWhyP2 =>
      'Сравните их по телефону или лично, затем нажмите **Совпадают**. Контакт становится **Проверено**. **Пропустить пока** оставляет его в состоянии **Сопряжено, не проверено**: файлы платежей всё равно запечатаны, но контакт не может присылать счета, пока слова не проверены.';

  @override
  String get helpPairWhyP3 =>
      'Если слова различаются, нажмите **Не совпадают**. Сопряжение удаляется с этой стороны. Повторите сопряжение лично или с новым приглашением.';

  @override
  String get helpPairWhyP4 =>
      'Названия слов остаются на английском во всех языках, чтобы их могли сравнить и люди, чьи кошельки работают на разных языках.';

  @override
  String get helpPairWordsTitle => 'Слова сопряжения';

  @override
  String get helpPairWordsShort =>
      'Пять картинок с названиями заменяют ссылку, когда нечего сканировать или вставлять.';

  @override
  String get helpPairWordsP1 =>
      'Когда у одного кошелька нет камеры или приглашение нельзя отправить ссылкой, приглашающий кошелёк показывает пять слов сопряжения. Собеседник вводит их названия в **Ввести ссылку или слова**; поле дополняет каждое название после нескольких букв. Слова действуют 10 минут.';

  @override
  String get helpPairWordsP2 =>
      'Слова только находят приглашение. У того, кто их знает, те же возможности, что у получившего ссылку, поэтому, как обычно, затем проверьте вместе четыре слова.';

  @override
  String get helpPairWordsP3 =>
      'Для слов сопряжения нужен сервер Epicbox. Пока Epicbox выключен, отправьте ссылку-приглашение.';

  @override
  String get helpPairInvTitle => 'Счета от сопряжённых контактов';

  @override
  String get helpPairInvShortDesktop =>
      'Просить вас об оплате может только проверенный контакт, которому вы разрешили. Каждый запрос ждёт пароля кошелька.';

  @override
  String get helpPairInvShort =>
      'Просить вас об оплате может только проверенный контакт, которому вы разрешили. Каждый запрос ждёт вашего PIN.';

  @override
  String get helpPairInvP1 =>
      'Магазин, биржа или человек, с которым вы выполнили сопряжение, может присылать запросы на оплату, если вы разрешите: **Разрешить счета** на странице контакта или в [[Настройки › Счета|Settings › Invoices]]. Переключатель работает только для проверенного контакта.';

  @override
  String get helpPairInvP2Desktop =>
      'Запрос появляется в [[Счета › Оплатить|Invoices › Pay]] с именем контакта, суммой и номером. Ничего не оплачивается, пока вы не одобрите запрос паролем кошелька. Запрос никогда не добавляет деньги в кошелёк.';

  @override
  String get helpPairInvP2 =>
      'Запрос появляется в [[Счета › Оплатить|Invoices › Pay]] с именем контакта, суммой и номером. Ничего не оплачивается, пока вы не одобрите запрос своим PIN. Запрос никогда не добавляет деньги в кошелёк.';

  @override
  String get helpPairInvP3 =>
      'Выключение действует сразу: новые запросы от этого контакта отбрасываются, а открытые отклоняются.';

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
  String get pairYourNamePlaceholder => 'Ваше имя';

  @override
  String get deskConPickForPairing =>
      'Сопряжение будет добавлено к выбранному контакту.';

  @override
  String txDetailsAcceptedAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Принят $minutes минуты назад.',
      many: 'Принят $minutes минут назад.',
      few: 'Принят $minutes минуты назад.',
      one: 'Принят $minutes минуту назад.',
      zero: 'Принят только что.',
    );
    return '$_temp0';
  }

  @override
  String txDetailsAcceptedAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Принят $hours часа назад.',
      many: 'Принят $hours часов назад.',
      few: 'Принят $hours часа назад.',
      one: 'Принят $hours час назад.',
    );
    return '$_temp0';
  }

  @override
  String txDetailsAcceptedAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Принят $days дня назад.',
      many: 'Принят $days дней назад.',
      few: 'Принят $days дня назад.',
      one: 'Принят $days день назад.',
    );
    return '$_temp0';
  }

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
  String get txDetailsCancelOffered =>
      'Отменяйте, только если платёж так и не поступил: кошелёк сначала проверяет сеть.';

  @override
  String get txDetailsCancelWhileReported =>
      'Отмена не предлагается, пока отправитель сообщает, что опубликовал платёж.';

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
      other: '$count сохранённого контакта получат адрес или заметку',
      many: '$count сохранённых контактов получат адрес или заметку',
      few: '$count сохранённых контакта получат адрес или заметку',
      one: '$count сохранённый контакт получит адрес или заметку',
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
  String get contactsImportKeeps => 'Сохранённые контакты не меняются.';

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
      other: '$same уже были',
      many: '$same уже были',
      few: '$same уже были',
      one: '$same уже был',
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
      'Этот файл создан более новой версией Epic Cash. Обновите приложение, чтобы импортировать его.';

  @override
  String get contactsImportEmpty => 'В файле нет контактов.';

  @override
  String get contactsImportAllOtherNet =>
      'Эти контакты относятся к другой сети. Ни один нельзя использовать здесь.';

  @override
  String get expPairing => 'Сопряжение';

  @override
  String get expPairingHint =>
      'Однократное сопряжение с тем, с кем часто бывают платежи: файлы платежей и счета между двумя кошельками запечатаны, а контакт отмечен как сопряжённый. Экспериментально: может ещё измениться.';

  @override
  String get expInvoices => 'Счета';

  @override
  String get expInvoicesHint =>
      'Запрос платежа у сопряжённого контакта и одобрение счетов от сопряжённых контактов. Нужно сопряжение. Экспериментально: может ещё измениться.';

  @override
  String get expNeedsPairing =>
      'Счетам нужно сопряжение: включение счетов включает сопряжение, выключение сопряжения выключает счета.';

  @override
  String get expPairingOffTitle => 'Сопряжение — экспериментальная функция';

  @override
  String get expPairingOffBody => 'Включается в Настройки › Дополнительно.';

  @override
  String get expInvoicesOffTitle => 'Счета — экспериментальная функция';

  @override
  String get expInvoicesOffBody => 'Включаются в Настройки › Дополнительно.';

  @override
  String get expOpenAdvanced => 'Открыть Дополнительно';

  @override
  String get contactNoAddressPaired => 'Платежи идут через сопряжение';

  @override
  String get contactSendKeysChanged => 'Перед отправкой проверьте слова.';

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
    return 'Отправлено через почтовый ящик $name';
  }

  @override
  String txStepAnswerFrom(String name) {
    return 'Ответ от $name';
  }

  @override
  String txStepCollecting(String name) {
    return 'Проверка почтового ящика $name';
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
  String get reqFromFileTitle => 'Запрос на оплату из файла';

  @override
  String get reqFromFileWarn =>
      'Ничто не говорит, кто создал этот запрос. Оплачивайте, только если ждали его от знакомого человека.';

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
  String get reqFileAlreadyPaid => 'Этот запрос уже оплачен.';

  @override
  String get reqFileEnded => 'Этот запрос больше не действует.';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return 'Ответ на ваш запрос на оплату: $amount.';
  }

  @override
  String get reqAnswerUnknown =>
      'Это ответ на запрос, которого в этом кошельке больше нет.';

  @override
  String get deskInvIssuerAnother => 'Ещё один запрос';

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
    return 'Старое приложение принимало через $old. Все, кто сохранил адрес этого кошелька, отправляют туда.';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return 'Оставить $old';
  }

  @override
  String get deskOnbImportRelayKeepHint =>
      'Адрес не меняется. Сервер добавляется в список Epicbox и используется для этого кошелька.';

  @override
  String deskOnbImportRelayApp(String current) {
    return 'Использовать $current';
  }

  @override
  String get deskOnbImportRelayAppHint =>
      'Адрес изменится. Тем, у кого старый адрес, нужен новый; платежи на старый адрес не придут.';

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
      'Поиск средств этого кошелька в блокчейне с первого блока. Полученные EPIC появляются по мере нахождения; получение и отправка станут доступны после завершения сканирования.';

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
      'Идёт сканирование после восстановления: блокчейн читается с первого блока. Сверка баланса станет доступна после его завершения.';

  @override
  String get deskSetRescanStartHeading => 'Откуда начать';

  @override
  String get deskSetRescanRecent => 'Последние блоки';

  @override
  String get deskSetRescanRecentHint =>
      'С 100 блоков до последнего просканированного. Достаточно после неудачной отправки или когда баланс выглядит неверно.';

  @override
  String get deskSetRescanFromHeight => 'С высоты блока';

  @override
  String get deskSetRescanHeightInvalid => 'Введите высоту блока от 1.';

  @override
  String get deskSetRescanWholeChain => 'Весь блокчейн';

  @override
  String get deskSetRescanWholeChainHint =>
      'С первого блока. Находит всё, но занимает много времени. Также завершает незаконченное восстановление.';

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
      'Пропуск оставляет настройки узла и Epicbox как есть.';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return 'Не удалось отметить настройку как завершённую: $reason. Она может открыться снова при следующем запуске; «Пропустить настройку» закрывает её.';
  }

  @override
  String get deskOvRestoredImportTitle => 'Вернуть историю и настройки?';

  @override
  String get deskOvRestoredImportBody =>
      'Фраза восстановления вернула баланс. Файл данных кошелька, экспортированный из этого кошелька, возвращает историю платежей, контакты, счета и настройки: это файл, сохранённый вне старого компьютера.';

  @override
  String get deskOvRestoredImportButton => 'Импорт данных кошелька';

  @override
  String get deskOvRestoredImportLater =>
      'Позже: Настройки › Этот кошелёк › Данные кошелька.';

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
  String get qrShowTitleRequest => 'Запрос на оплату';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount с телефона рядом с вами';
  }

  @override
  String get qrHiddenBodyRequest =>
      'Тот, кто его отсканирует, сможет оплатить этот запрос. Показывайте его только тому, кто платит.';

  @override
  String get qrStatusRequestHidden => 'Покажите это тому, кто платит.';

  @override
  String get qrStatusRequestShowing =>
      'Ждём, пока они отсканируют и одобрят. Затем отсканируйте их ответ.';

  @override
  String qrSemanticsRequest(String state) {
    return 'QR-код запроса на оплату, $state';
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
    return 'Тот, кто отсканирует код, сможет оплатить $amount. Отсканируйте здесь их ответ, чтобы завершить. Запрос истекает через 24 ч.';
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
  String get reqQrNew => 'Новый запрос';

  @override
  String get reqQrAlreadyPaid =>
      'Этот запрос уже оплачен. С этого телефона ничего не списано: его платёж остаётся на удержании, пока его не отменят в Активности или он не истечёт через день.';

  @override
  String get reqFromQrTitle => 'Запрос на оплату из QR-кода';

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
      'Этот запрос истёк. Попросите новый. Ничего не оплачено.';

  @override
  String get reqOtherChain =>
      'Этот запрос принадлежит другой сети Epic, или его срок не подходит этой сети. Ничего не оплачено.';

  @override
  String get reqQrOpenNote =>
      'Открыт в Счета › Отправленные 24 ч, затем истекает.';

  @override
  String get reqQrWrongReply =>
      'Этот ответ относится к другому запросу. Отсканируйте ответ на этот.';

  @override
  String get backupFileHolds =>
      'Этот файл содержит историю платежей, контакты, счета и настройки этого кошелька.';

  @override
  String get backupFileNoPhrase =>
      'Он не содержит фразу восстановления и сам по себе не восстановит кошелёк.';

  @override
  String get backupFileRestoreOrder =>
      'Чтобы восстановить: сначала введите фразу восстановления, затем импортируйте этот файл.';

  @override
  String get backupImportLead =>
      'Возвращает историю платежей, контакты, счета и настройки этого кошелька. Сначала восстановите кошелёк по его фразе восстановления.';

  @override
  String backupRestoredSummary(String items) {
    return 'Восстановлено: $items.';
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
  String get backupFromOtherWallet =>
      'Этот файл принадлежит другому кошельку. Открыть его может только кошелёк, восстановленный по той же фразе восстановления.';

  @override
  String get deskEpicboxBlockedWord => 'Заблокирован';

  @override
  String deskEpicboxBlockedText(String host) {
    return 'Эта сеть блокирует $host. Причиной может быть сетевой фильтр. Попробуйте другой сервер Epicbox или частный DNS-сервер.';
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
  String get deskSlotOffline => 'Режим офлайн';

  @override
  String get deskSlotOfflineDetail => 'ничего не отправляется и не принимается';

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
  String get deskSlotRequests => 'Новые запросы';

  @override
  String get deskSlotNodeStarting => 'Запуск локального узла';

  @override
  String get deskSlotNodeSyncing => 'Синхронизация локального узла';

  @override
  String deskSlotUpdateDot(String version) {
    return 'Доступно обновление, $version. Показывает обновление.';
  }

  @override
  String get deskSlotOpenAdvanced => 'Открыть «Дополнительно»';

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
  String deskBarBuildTip(String version, String commit) {
    return 'Версия $version, коммит $commit. Щелчок копирует сведения о сборке.';
  }

  @override
  String deskBarBuildTipRebuild(String version, String rebuild, String commit) {
    return 'Версия $version, пересборка $rebuild, коммит $commit. Щелчок копирует сведения о сборке.';
  }

  @override
  String deskBarBuildTipDev(String version) {
    return 'Версия $version. Сборка для разработки. Щелчок копирует сведения о сборке.';
  }

  @override
  String get deskBarKeyMenu => 'Открыть меню приложения';

  @override
  String get txDetailsCancelRequestBody =>
      'Другая сторона хранит ваш подписанный платёж и ещё может его отправить, пока эти монеты не будут потрачены снова. Отмена освобождает ваши монеты здесь.';

  @override
  String get cancelMoreInHelp => 'Подробнее в справке';

  @override
  String get cancelNoteSendWaiting =>
      'Ещё не отправлено в сеть: отмена освобождает ваши монеты.';

  @override
  String get cancelNoteNotPosted =>
      'Ещё не в сети: отмена освобождает ваши монеты. Кошелёк сначала проверяет сеть.';

  @override
  String get cancelNoteDirectFailed =>
      'До получателя ничего не дошло: отмена освобождает ваши монеты.';

  @override
  String get cancelNoteRequestPaid =>
      'Другая сторона хранит ваш подписанный платёж и ещё может его отправить. Отмена освобождает ваши монеты здесь.';

  @override
  String get cancelNoteRequestWithdraw =>
      'Ничего не оплачено: отзыв не перемещает монеты.';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '$amount EPIC для $who. Оба кошелька его подписали, но сеть его не приняла. Кошелёк сначала спрашивает узел и отказывает, если платёж уже в сети; иначе заблокированная сумма вернётся в баланс.';
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
}
