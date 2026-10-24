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
  String get txOutgoingPayment => 'Исходящий платёж';

  @override
  String get txIncomingPayment => 'Входящий платёж';

  @override
  String get txStatusWaitingRecipient => 'Ждёт получателя';

  @override
  String get txStatusWaitingSender => 'Ждёт отправителя';

  @override
  String txStatusConfirming(int count, int target) {
    return 'Подтверждение $count/$target';
  }

  @override
  String get txStatusCompleted => 'Завершён';

  @override
  String get txStatusCancelled => 'Отменён';

  @override
  String get txStatusFromBackup => 'Из резервной копии, статус неизвестен';

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
      'Это не файл истории, экспортированный этим приложением.';

  @override
  String get errorHistoryNewer =>
      'Этот файл истории создан более новой версией приложения.';

  @override
  String get errorHistoryDamaged => 'Этот файл истории повреждён.';

  @override
  String get errorHistoryOtherWallet =>
      'Этот файл истории относится к другому кошельку.';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return 'Этот файл истории из сети $fileNetwork, а этот кошелёк работает в сети $walletNetwork.';
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
      'Отменено. Ничего не отправлено, средства снова доступны.';

  @override
  String get txDetailsCancelledReleased =>
      'Сеть так и не приняла этот платёж, поэтому его средства разблокированы. Прежде чем отправлять снова, убедитесь, что получатель его не получил.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Платёж не попал в сеть за 14 дней, поэтому кошелёк отменил его. Прежде чем отправлять снова, убедитесь, что получатель его не получил.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Получатель не ответил за 14 дней, поэтому кошелёк отменил платёж. Ничего не отправлено, средства снова доступны.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Получатель ответил после 14-дневного срока, поэтому кошелёк отменил платёж вместо завершения. Ничего не отправлено, средства снова доступны.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Платёж не удалось доставить получателю, поэтому кошелёк сразу отменил его. Ничего не отправлено, средства снова доступны.';

  @override
  String get txDetailsCancelledIncoming => 'Отменено. Этот платёж не поступит.';

  @override
  String get txDetailsFromBackup =>
      'Этот платёж взят из резервной копии истории и не был завершён на момент её создания. У этого кошелька нет собственной записи о нём, поэтому неизвестно, завершился ли он. Ничего не заблокировано.';

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
      'Отправитель ещё может завершить этот платёж. Если это произойдёт после отмены, платёж не отобразится до повторного сканирования.';

  @override
  String get txDetailsCancelSendBody =>
      'Отменить этот платёж и разблокировать его средства? Делайте это, только если получатель его не завершил.';

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
  String get txDetailsSendAgain => 'Отправить ещё раз';

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
      'Хранится только на этом устройстве и в ваших резервных копиях истории.';

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
      'Найден при сканировании блокчейна. Такие сведения, как отправитель и комиссия, в блокчейне не хранятся; импортируйте резервную копию истории, чтобы восстановить их.';

  @override
  String get txDetailsSourceImported =>
      'Импортирован из резервной копии истории. У этого кошелька нет собственной записи о нём, поэтому его статус может быть устаревшим.';

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
  String get historyBackupSaveDialogTitle => 'Сохранить историю платежей';

  @override
  String get historyBackupOpenDialogTitle => 'Открыть резервную копию истории';

  @override
  String get historyBackupFileTooLarge =>
      'Этот файл слишком большой для резервной копии.';

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
  String get historyBackupExportTitle => 'Экспорт резервной копии истории';

  @override
  String get historyBackupExportNote =>
      'Резервная копия истории содержит платежи на текущий момент. После новых платежей экспортируйте её снова.';

  @override
  String get historyBackupCsvTitle => 'Экспорт в CSV';

  @override
  String get historyBackupCsvWarning =>
      'Файл CSV не зашифрован. Любой, кто его получит, увидит ваши суммы, даты, адреса и заметки. Импортировать его обратно нельзя; для этого используйте «Экспорт резервной копии истории».';

  @override
  String get historyBackupCsvConfirm => 'Экспортировать CSV';

  @override
  String get historyBackupImportedTitle => 'История импортирована';

  @override
  String historyBackupImportFailed(String reason) {
    return 'История не импортирована. $reason';
  }

  @override
  String get historyBackupImportNothingNew =>
      'В резервной копии нет ничего нового.';

  @override
  String historyBackupImportMerged(int merged) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedAdded(int merged, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportSkipped(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedSkipped(int merged, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    return '$_temp0, $_temp1.';
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
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportContacts(int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedContacts(int merged, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedContacts(int added, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1.';
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
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportSkippedContacts(int skipped, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1.';
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
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1, $_temp2.';
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
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1, $_temp2.';
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
      other: '$merged платежа дополнены данными из копии',
      many: '$merged платежей дополнены данными из копии',
      few: '$merged платежа дополнены данными из копии',
      one: '$merged платёж дополнен данными из копии',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added старых платежа добавлены',
      many: '$added старых платежей добавлены',
      few: '$added старых платежа добавлены',
      one: '$added старый платёж добавлен',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped записи уже были в кошельке',
      many: '$skipped записей уже были в кошельке',
      few: '$skipped записи уже были в кошельке',
      one: '$skipped запись уже была в кошельке',
    );
    String _temp3 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts контакта добавлены',
      many: '$contacts контактов добавлены',
      few: '$contacts контакта добавлены',
      one: '$contacts контакт добавлен',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3.';
  }

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
  String get homeSettingsUpdateTooltip => 'Настройки: доступно обновление';

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
      other: '$count платежа не входят в резервную копию истории',
      many: '$count платежей не входят в резервную копию истории',
      few: '$count платежа не входят в резервную копию истории',
      one: '$count платёж не входит в резервную копию истории',
    );
    return '$_temp0. Фраза восстановления вернёт только баланс.';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count платежа добавлены или изменены после последней резервной копии истории',
      many:
          '$count платежей добавлены или изменены после последней резервной копии истории',
      few:
          '$count платежа добавлены или изменены после последней резервной копии истории',
      one:
          '$count платёж добавлен или изменён после последней резервной копии истории',
    );
    return '$_temp0. Фраза восстановления вернёт только баланс.';
  }

  @override
  String get homeHistoryReminderNotNow => 'Не сейчас';

  @override
  String get homeHistoryExportButton => 'Экспортировать копию';

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
  String get statusEpicboxOnline => 'Epicbox в сети';

  @override
  String get statusEpicboxConnecting => 'Подключение к epicbox';

  @override
  String get statusEpicboxOffline => 'Epicbox не в сети';

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
  String get homeEpicboxOffline => 'Epicbox недоступен, переподключение.';

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
      'Нет ожидающих счетов. Когда доверенный сервис выставит вам счёт, он появится здесь. Ничего не оплачивается без вашего одобрения.';

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
  String get invoiceReviewTitle => 'Проверка счёта';

  @override
  String invoiceReviewAsks(String service) {
    return 'Сервис $service просит оплатить';
  }

  @override
  String get invoiceReviewMessageLabel => 'Сообщение от сервиса';

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
  String invoiceDetailsPosted(String service) {
    return 'Сервис $service сообщает, что опубликовал платёж. Он завершится, когда сеть его подтвердит.';
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
  String get requestTitle => 'Запросить платёж';

  @override
  String get requestStepsIntro =>
      'Кошелёк плательщика должен принимать счета. Перед запросом:';

  @override
  String get requestStepTrust =>
      '1. Плательщик добавляет ваш адрес ниже в свои доверенные сервисы.';

  @override
  String get requestStepAddress =>
      '2. Плательщик даёт вам свой адрес для счетов.';

  @override
  String get requestYourAddress => 'Ваш адрес';

  @override
  String get requestPayerLabel => 'Адрес для счетов плательщика';

  @override
  String get requestPayerMissing =>
      'Вставьте или отсканируйте адрес для счетов плательщика.';

  @override
  String get requestPayerOwn =>
      'Это один из ваших собственных адресов. Введите адрес для счетов, который даст вам плательщик.';

  @override
  String get requestMessageLabel => 'Сообщение плательщику (необязательно)';

  @override
  String get requestMessageHelper =>
      'Плательщик увидит это сообщение вместе с запросом.';

  @override
  String get requestButton => 'Запросить';

  @override
  String requestSentNotice(String payer) {
    return 'Запрос отправлен: $payer.';
  }

  @override
  String get invoicesToPaySection => 'К оплате';

  @override
  String get invoicesNoneToPay => 'Нечего оплачивать.';

  @override
  String get invoicesSentSection => 'Отправленные запросы';

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
    return '$payer больше не сможет его оплатить. Это нельзя отменить.';
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
  String get requestPayerNoInvoices =>
      'Этот кошелёк уже возвращал запрос: он не умеет оплачивать запросы. Попросите этого человека отправить вам платёж обычным способом: на ваш адрес или платёжным файлом.';

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
  String get setupTitle => 'Узел и Epicbox';

  @override
  String get setupNetworkSettingsTooltip => 'Узел и Epicbox';

  @override
  String get setupNetworkHeading => 'Сеть';

  @override
  String get setupNodeUrlLabel => 'URL узла';

  @override
  String get setupNodeUrlInvalid =>
      'Введите полный URL, например https://node.example.com';

  @override
  String get setupTestConnection => 'Проверить подключение';

  @override
  String setupTestConnected(String height, String version) {
    return 'Подключено. Узел на блоке $height, версия $version.';
  }

  @override
  String setupTestFailed(String error) {
    return 'Не удалось подключиться. $error';
  }

  @override
  String get setupConnectedIconLabel => 'Подключено';

  @override
  String get setupRelayHeading => 'Сервер Epicbox';

  @override
  String get setupRelayHint => 'Этот сервер входит в ваш адрес.';

  @override
  String get setupCustomRelayLabel =>
      'Другой сервер epicbox (хост или host:port)';

  @override
  String get setupCustomRelayUse => 'Использовать этот сервер';

  @override
  String get setupCustomRelayInvalid =>
      'Введите хост, например epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      'При смене сервера epicbox меняется ваш адрес. Сообщите отправителям новый адрес. Платежи, отправленные на старый, будут ждать на старом сервере, пока вы не переключитесь обратно.';

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
  String get restorePhraseHelper => 'Все слова (от 12 до 24) через пробел.';

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
  String get restoreRescanLater =>
      'Полное повторное сканирование можно запустить позже в настройках.';

  @override
  String get restoreDoneIconLabel => 'Готово';

  @override
  String get restoreDoneTitle => 'Кошелёк восстановлен';

  @override
  String get restoreImportExplanation =>
      'В блокчейне хранится ваш баланс, но не получатели платежей, комиссии и заметки. Если вы экспортировали резервную копию истории из этого кошелька, импортируйте её сейчас, чтобы вернуть их. Это файл .wfeh, который вы отправили или сохранили вне старого телефона.';

  @override
  String get restoreImportButton => 'Импортировать резервную копию истории';

  @override
  String get restoreImportNotNow => 'Не сейчас';

  @override
  String get restoreImportLater => 'Импортировать её можно позже в настройках.';

  @override
  String get restoreScanProgressLabel => 'Ход сканирования';

  @override
  String get firstRunTitle => 'Добро пожаловать';

  @override
  String get firstRunRestore => 'У меня уже есть кошелёк: восстановить';

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
  String get slateInvoiceUnsupported =>
      'Запросы на оплату (счета) пока не поддерживаются.';

  @override
  String get slateNotTransactionFile => 'Это не файл транзакции.';

  @override
  String get slateReading => 'Чтение файла';

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
  String get contactsAddressLabel => 'Адрес';

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
  String contactsAddressInvalid(String example) {
    return 'Это недействительный адрес. Правильный адрес выглядит так: $example';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionNetwork => 'Серверы';

  @override
  String get settingsNetworkAndNode => 'Узел и Epicbox';

  @override
  String settingsNetworkSubtitle(String network, String node) {
    return '$network · $node';
  }

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
  String get settingsSectionHistory => 'История платежей';

  @override
  String get settingsExportHistory => 'Экспорт резервной копии истории';

  @override
  String get settingsExportCsv => 'Экспорт в CSV';

  @override
  String get settingsImportHistory => 'Импорт резервной копии истории';

  @override
  String get settingsSectionWallet => 'Кошелёк';

  @override
  String get settingsContacts => 'Контакты';

  @override
  String get settingsSectionInvoices => 'Счета';

  @override
  String get settingsInvoices => 'Адрес для счетов и доверенные сервисы';

  @override
  String get settingsInvoicesSubtitle =>
      'Доверенные сервисы могут выставлять вам счета. Каждый счёт вы подтверждаете сами.';

  @override
  String get invoiceSettingsTitle => 'Счета';

  @override
  String get invoiceSettingsAddressTitle => 'Ваш адрес для счетов';

  @override
  String get invoiceSettingsAddressBody =>
      'Передайте этот адрес сервису, которому доверяете, чтобы он мог присылать вам счета. Ваш адрес для платежей не меняется.';

  @override
  String get invoiceSettingsQrLabel => 'QR-код вашего адреса для счетов';

  @override
  String get invoiceSettingsAddressCopied => 'Адрес для счетов скопирован.';

  @override
  String get invoiceSettingsServicesTitle => 'Доверенные сервисы';

  @override
  String get invoiceSettingsNoServices =>
      'Доверенных сервисов пока нет. Счета от других до вас не доходят.';

  @override
  String get invoiceSettingsAddService => 'Добавить сервис';

  @override
  String invoiceSettingsRemoveTooltip(String name) {
    return 'Удалить $name';
  }

  @override
  String invoiceSettingsRemoveTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get invoiceSettingsRemoveBody =>
      'Этот сервис больше не сможет присылать вам счета. Уже сделанные платежи это не затрагивает.';

  @override
  String get invoiceSettingsKeep => 'Оставить';

  @override
  String get invoiceSettingsRemoveConfirm => 'Удалить';

  @override
  String invoiceSettingsRemoved(String name) {
    return '$name больше не может присылать вам счета.';
  }

  @override
  String get invoiceSettingsRotate => 'Получить новый адрес для счетов';

  @override
  String get invoiceSettingsRotateHint => 'Текущий перестанет работать.';

  @override
  String get invoiceSettingsRotateTitle => 'Получить новый адрес для счетов?';

  @override
  String get invoiceSettingsRotateBody =>
      'Текущий адрес для счетов перестанет работать навсегда. Каждому сервису, который выставляет вам счета, нужен новый.';

  @override
  String get invoiceSettingsRotateConfirm => 'Новый адрес';

  @override
  String get invoiceSettingsRotated =>
      'Новый адрес для счетов готов. Передайте его своим сервисам.';

  @override
  String invoiceSettingsDropped(int count) {
    return 'Отброшено за сеанс (неизвестные отправители): $count';
  }

  @override
  String get invoiceSettingsAddTitle => 'Добавить доверенный сервис';

  @override
  String get invoiceSettingsAddExplanation =>
      'Доверенный сервис может присылать счета на ваш адрес для счетов; сообщения от других отбрасываются. Ничего не оплачивается, пока вы не подтвердите каждый счёт PIN-кодом или отпечатком пальца.';

  @override
  String get invoiceSettingsLabelLabel => 'Название';

  @override
  String get invoiceSettingsLabelMissing => 'Дайте сервису название.';

  @override
  String get invoiceSettingsServiceAddressLabel => 'Адрес epicbox сервиса';

  @override
  String get invoiceSettingsAddressMissing =>
      'Вставьте или отсканируйте адрес, который показывает сервис.';

  @override
  String get invoiceSettingsAddButton => 'Добавить сервис';

  @override
  String invoiceSettingsAdded(String name) {
    return '$name теперь может присылать вам счета.';
  }

  @override
  String get settingsRescan => 'Пересканировать блокчейн';

  @override
  String get settingsRescanFinished => 'Повторное сканирование завершено';

  @override
  String get settingsRescanTitle => 'Пересканировать блокчейн';

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
  String get settingsEpicboxServer => 'Сервер Epicbox';

  @override
  String settingsUpdateTo(String version) {
    return 'Обновить до $version';
  }

  @override
  String get settingsUpdateInstall => 'Установить';

  @override
  String get settingsCheckUpdates => 'Проверить обновления';

  @override
  String get settingsHelp => 'Справка';

  @override
  String get settingsSendFeedback => 'Отправить отзыв';

  @override
  String get settingsSendFeedbackHint =>
      'Сообщите о проблеме или предложите идею';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsLicences => 'Лицензии';

  @override
  String get licencesLead =>
      'Открытое ПО в этом кошельке. Каждый компонент сохраняет свою лицензию; полные тексты в одном касании.';

  @override
  String get licencesApp =>
      'Epic Cash Mobile от BT Labs: Apache-2.0. Код на GitHub.';

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
      'Шрифты Montserrat и JetBrains Mono: SIL Open Font License 1.1.';

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
      'Технические детали, файлы и журналы';

  @override
  String get settingsSectionPrivacy => 'Конфиденциальность';

  @override
  String get settingsSectionPrivacyNetwork => 'Конфиденциальность и сеть';

  @override
  String get settingsSectionHelpFeedback => 'Справка и отзывы';

  @override
  String get settingsStateBackUp => 'Сохраните фразу восстановления';

  @override
  String get settingsStateNotBackedUp => 'Ещё не сохранена';

  @override
  String get settingsStatePin => 'PIN-код';

  @override
  String get settingsStatePinBiometrics => 'PIN-код и биометрия';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'Использовать status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Состояние сети и информация предоставляются status.btlabs.uk';

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
  String get sendStepRecipient => 'Получатель';

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
  String get sendRelayDown => 'Сервер Epicbox получателя не отвечает.';

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
  String get handshakeFile => 'Файл';

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
  String get handshakeNext => 'Следующий шаг';

  @override
  String sendRelayRefused(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Сервер Epicbox получателя не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дня.',
      many:
          'Сервер Epicbox получателя не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дней.',
      few:
          'Сервер Epicbox получателя не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дней.',
      one:
          'Сервер Epicbox получателя не принял платёж. Сумма заблокирована, пока вы его не отмените, но не дольше $days дня.',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost =>
      'Сервер Epicbox получателя не принял платёж. Проверьте «Кошелёк», прежде чем отправлять снова.';

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
  String get receiveTorAddressLabel => 'Адрес Tor';

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
  String get outputsSplitChangeText => 'Когда осталось бы мало выходов';

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
    return 'Тратит $spent ($amount) и создаёт $made по $each. Обычная сетевая транзакция на этот кошелёк, подтверждается через 3 блока, как любая отправка; всё доступное блокируется до этого момента.';
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
  String get outputsAdvanced => 'Дополнительно';

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
  String get contactsEditAction => 'Изменить';

  @override
  String get contactsAddressHeading => 'Адрес';

  @override
  String get contactsNoteHeading => 'Заметка';

  @override
  String get contactsShowCode => 'Показать код';

  @override
  String get contactsHideCode => 'Скрыть код';

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
  String get invoicesToPayEmpty => 'Нет счетов к оплате';

  @override
  String get invoicesToPayEmptyCaption =>
      'Сервисы из вашего доверенного списка могут выставлять счета этому кошельку. Каждый счёт ждёт здесь вашего одобрения.';

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
  String get invoicesSendRequest => 'Отправить запрос';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer получит запрос на оплату $amount. Запрос истекает через 24 ч.';
  }

  @override
  String get invoicesRequestHowTitle => 'Перед запросом';

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
  String get serverRemoveRelay => 'Удалить из моих серверов';

  @override
  String get serverRemoveInUse =>
      'Используется. Сначала переключитесь на другой сервер.';

  @override
  String get serverRemoveRelayTitle => 'Удалить этот сервер?';

  @override
  String get serverRemoveNodeTitle => 'Удалить этот узел?';

  @override
  String serverRemoveBody(String host) {
    return '$host исчезнет из этого списка. Введите его снова, чтобы использовать позже.';
  }

  @override
  String get serverRemoveConfirm => 'Удалить';

  @override
  String get serverSupportsNotifications => 'Поддерживает уведомления';

  @override
  String get netStatusReachable => 'Доступен';

  @override
  String get netStatusPublishing => 'Публикация…';

  @override
  String get netStatusNotReachable => 'Недоступен';

  @override
  String get netStatusTorOpenHint => 'Открывает настройки конфиденциальности';

  @override
  String get netStatusDirectOpenHint => 'Открывает прямой адрес для приёма';

  @override
  String get netStatusOpenHint => 'Показывает серверы';

  @override
  String get serverNodeTitle => 'Узел';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'Найдите или введите адрес узла';

  @override
  String serverUseAddress(String address) {
    return 'Использовать $address';
  }

  @override
  String get serverTesting => 'Проверка…';

  @override
  String serverTestAnswer(String height, String version) {
    return 'Блок $height · v$version';
  }

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
  String get serverAddMine => 'Добавить в мои узлы';

  @override
  String get serverRemoveMine => 'Удалить из моих узлов';

  @override
  String get serverNotResponding => 'Не отвечает';

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
  String serverSwitchTo(String host) {
    return 'Переключиться на $host';
  }

  @override
  String get serverNodeSwitchNote =>
      'Кошелёк переподключится. Балансы будут заново проверены по новому узлу.';

  @override
  String get serverRelayWarning =>
      'Ваш адрес содержит этот сервер. При смене сервера адрес изменится; отправителям нужен новый.';

  @override
  String get serverRelaySwitchNote =>
      'Ваш адрес изменится; отправителям нужен новый.';

  @override
  String get serverOtherRelay => 'Другой сервер, host или host:port';

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
  String get methodHttp => 'HTTP';

  @override
  String get methodTor => 'Tor';

  @override
  String get methodFile => 'Файл';

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
      'HTTP: платёж идёт прямо в кошелёк получателя, который должен быть открыт';

  @override
  String get methodArtLabelTor =>
      'Tor: платёж идёт прямо в кошелёк получателя через сеть Tor';

  @override
  String get methodArtLabelFile =>
      'Файл: файл транзакции передаётся, возвращается файл ответа, затем отправитель завершает платёж';

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
  String get sendSwitchedHttp => 'Через HTTP';

  @override
  String get sendSwitchedEpicbox => 'Через Epicbox';

  @override
  String get sendSwitchedTorAnnounce => 'Адрес Tor. Выбран способ Tor.';

  @override
  String get sendSwitchedHttpAnnounce => 'Адрес HTTP. Выбран способ HTTP.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Адрес Epicbox. Выбран способ Epicbox.';

  @override
  String get sendReviewMethodHttp => 'HTTP, прямо в кошелёк';

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
  String get sendCancelPossibleWhileWaiting =>
      'Возможно, пока платёж ждёт получателя.';

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
  String get deskInvOneDevice =>
      'Используйте счета только на одном устройстве. Другое устройство с этим кошельком может принять платёж, предназначенный для этого.';

  @override
  String get deskInvFailed =>
      'Не получилось. Ничего не изменилось; попробуйте ещё раз.';

  @override
  String get deskInvHowItWorks => 'Как работают счета';

  @override
  String get deskInvAddressHint => 'es…@epicbox.epiccash.com';

  @override
  String get deskInvEpicboxAddress => 'Адрес Epicbox';

  @override
  String get deskInvHelpTitle => 'Счета';

  @override
  String get deskInvHelpLede =>
      'Счета от доверенных отправителей, оплата только после одобрения.';

  @override
  String get deskInvHelpFlowTitle => 'Как работает счёт';

  @override
  String get deskInvHelpFlowShort =>
      'Выставитель отправляет счёт на адрес для счетов плательщика. Ничего не оплачивается, пока плательщик не одобрит.';

  @override
  String get deskInvHelpFlowIntro =>
      'Счёт — это просьба об оплате. **Выставитель** получает деньги; **плательщик** решает.';

  @override
  String get deskInvHelpFlowStep1 =>
      'Кошелёк выставителя отправляет счёт через сервер Epicbox на **адрес для счетов** плательщика.';

  @override
  String get deskInvHelpFlowStep2 =>
      'Плательщик открывает его в [[Счета › Оплатить]], проверяет отправителя, сумму и сообщение и выбирает **Одобрить и оплатить**, вводя пароль кошелька.';

  @override
  String get deskInvHelpFlowStep3 =>
      'Кошелёк плательщика отправляет платёж на **адрес для платежей** выставителя.';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return 'Кошелёк выставителя завершает платёж и публикует его в сети. Подтверждений до окончательности: $confirmations.';
  }

  @override
  String get deskInvHelpFlowNever =>
      'Без одобрения ничего не оплачивается, а счёт никогда не добавляет деньги в кошелёк плательщика. У каждого счёта есть срок оплаты, не больше 48 часов; после него счёт оплатить нельзя.';

  @override
  String get deskInvHelpFlowIssued =>
      'Счета, выставленные этим кошельком, — в [[Счета › Выставить]].';

  @override
  String get deskInvHelpTrustTitle => 'Почему только доверенные отправители';

  @override
  String get deskInvHelpTrustShort =>
      'Только отправители из списка доверенных могут положить счёт во входящие. Это защищает от спама и поддельных счетов.';

  @override
  String get deskInvHelpTrustP1 =>
      'Кошелёк принимает счёт только на свой адрес для счетов и только от отправителя из списка доверенных, которого узнаёт по адресу. Всё остальное отбрасывается непрочитанным, до открытия, и никогда не появляется в [[Счета › Оплатить]].';

  @override
  String get deskInvHelpTrustP2 =>
      'Без списка любой, кто узнал адрес для счетов, мог бы заполнить входящие спамом или счетами, похожими на настоящие.';

  @override
  String get deskInvHelpTrustP3 =>
      'Доверие позволяет отправителю только просить. Доверенный отправитель ничего не может взять: каждый счёт по-прежнему ждёт **Одобрить и оплатить**.';

  @override
  String get deskInvHelpTrustWhere1 =>
      'Добавить доверенного отправителя можно в [[Настройки › Счета]].';

  @override
  String get deskInvHelpTrustWhere2 =>
      'Или включите **Доверенный для счетов** у контакта в [[Контакты]].';

  @override
  String get deskInvHelpTrustWhere3 =>
      'Отправителя можно убрать из списка в любой момент. Его новые счета тогда отбрасываются.';

  @override
  String get deskInvHelpAddrTitle => 'Почему отдельный адрес для счетов';

  @override
  String get deskInvHelpAddrShort =>
      'Счета приходят на свой адрес, отдельно от адреса для платежей, на который платят.';

  @override
  String get deskInvHelpAddrP1 =>
      'У кошелька два адреса Epicbox. **Адрес для платежей** в [[Получить]] принимает платежи. **Адрес для счетов** принимает только счета.';

  @override
  String get deskInvHelpAddrP2 =>
      'Раздельные адреса позволяют давать адрес для счетов сервисам или заменять его, не раскрывая и не меняя адрес, на который платят.';

  @override
  String get deskInvHelpAddrP3 =>
      'Адрес для счетов не принимает платежи: платёж, отправленный на него, отбрасывается. Чтобы получить оплату, дайте адрес для платежей.';

  @override
  String get deskInvHelpAddrWhere1 =>
      'Найти, скопировать или показать адрес для счетов QR-кодом можно в [[Настройки › Счета]].';

  @override
  String get deskInvHelpAddrWhere2 =>
      '**Новый адрес для счетов** заменяет его. Сервисы со старым адресом не смогут присылать счета, пока не получат новый.';

  @override
  String get deskInvHelpDiagramTitle => 'Путь счёта';

  @override
  String get deskInvHelpDiagramIssuer => 'Выставитель';

  @override
  String get deskInvHelpDiagramPayer => 'Плательщик';

  @override
  String get deskInvHelpDiagramIssues => 'Выставляет счёт';

  @override
  String get deskInvHelpDiagramInvoice => 'Счёт';

  @override
  String get deskInvHelpDiagramGate => 'Адрес для счетов';

  @override
  String get deskInvHelpDiagramGateSub => 'Только доверенные';

  @override
  String get deskInvHelpDiagramDropped => 'Другие отправители';

  @override
  String get deskInvHelpDiagramDroppedSub => 'Отброшено непрочитанным';

  @override
  String get deskInvHelpDiagramReview => 'Проверяет и одобряет';

  @override
  String get deskInvHelpDiagramReviewSub => 'Одобрить и оплатить';

  @override
  String get deskInvHelpDiagramPayment => 'Платёж';

  @override
  String get deskInvHelpDiagramPayAddr => 'Адрес для платежей';

  @override
  String get deskInvHelpDiagramPayAddrSub => 'Не адрес для счетов';

  @override
  String get deskInvHelpDiagramFinal => 'Завершает и публикует';

  @override
  String deskInvHelpDiagramFinalSub(int confirmations) {
    return 'Окончательно после подтверждений: $confirmations';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      'Выставитель отправляет счёт на адрес для счетов плательщика, который принимает только доверенных отправителей и отбрасывает остальных; плательщик проверяет и одобряет его; платёж идёт на адрес для платежей выставителя; кошелёк выставителя завершает его и публикует в сети.';

  @override
  String get deskInvIssuerFormTitle => 'Выставить счёт';

  @override
  String get deskInvIssuerFirstTitle => 'Перед первым счётом';

  @override
  String get deskInvIssuerYourAddress => 'Ваш адрес для платежей';

  @override
  String get deskInvIssuerMethod => 'Способ';

  @override
  String get deskInvIssuerEpicbox => 'Epicbox';

  @override
  String get deskInvIssuerFile => 'Файл';

  @override
  String get deskInvIssuerDirect => 'Напрямую';

  @override
  String get deskInvIssuerSoon => 'Скоро';

  @override
  String get deskInvIssuerPayer => 'Адрес для счетов плательщика';

  @override
  String get deskInvIssuerPayerHelp =>
      'Кошелёк плательщика показывает его в разделе «Настройки › Счета».';

  @override
  String get deskInvIssuerPayerMissing =>
      'Вставьте адрес для счетов плательщика.';

  @override
  String get deskInvIssuerPayerInvalid => 'Это недействительный адрес Epicbox.';

  @override
  String get deskInvIssuerPayerOwn =>
      'Это один из ваших собственных адресов. Используйте адрес для счетов, который даст плательщик.';

  @override
  String get deskInvIssuerPayerHttp =>
      'Счетам через Epicbox нужен адрес Epicbox, а не HTTP или Tor.';

  @override
  String get deskInvIssuerContacts => 'Контакты';

  @override
  String get deskInvIssuerNoContacts =>
      'Пока ни у одного контакта нет адреса для счетов. Добавьте его в разделе «Контакты».';

  @override
  String get deskInvIssuerNoInvoices =>
      'Этот кошелёк уже возвращал счёт: он не может оплачивать счета через Epicbox. Отправьте вместо этого файл счёта или попросите прислать платёж.';

  @override
  String get deskInvIssuerUseFile => 'Использовать файл';

  @override
  String get deskInvIssuerUnknown =>
      'Только wallet-for-epic и другие кошельки LEPIC могут оплатить счёт через Epicbox. Epic GUI wallet и Stack Wallet вообще не оплачивают счета; командная строка epic-wallet может оплатить файл счёта.';

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
  String get deskInvIssuerIssue => 'Выставить';

  @override
  String get deskInvIssuerRelayDown =>
      'Сервер Epicbox не отвечает, поэтому счёт сейчас не отправить.';

  @override
  String get deskInvIssuerFixFields => 'Исправьте поля, отмеченные красным.';

  @override
  String get deskInvIssuerNotDelivered =>
      'Счёт не дошёл до сервера Epicbox. Ничего не отправлено. Попробуйте ещё раз.';

  @override
  String deskInvIssuerSent(String payer) {
    return 'Счёт отправлен: $payer.';
  }

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
    return '$payer больше не сможет его оплатить.';
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
    return 'Доставлено на адрес для счетов $payer. Ничего не оплачено, пока плательщик не одобрит.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Копировать ID слейта';

  @override
  String get deskInvIssuerStepsIntro =>
      'Кошелёк плательщика должен принимать счета. Перед первым счётом:';

  @override
  String get deskInvIssuerStepTrust =>
      '1. Плательщик добавляет ваш адрес для платежей ниже в доверенные отправители.';

  @override
  String get deskInvIssuerStepAddress =>
      '2. Плательщик даёт вам свой адрес для счетов.';

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
      'Пришла оплата счёта, который это устройство не выставляло, и была отклонена. Если его выставило другое устройство с этим кошельком, попросите плательщика отменить и оплатить снова.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Пришёл ответ на платёж, который это устройство не отправляло, и был отклонён. Если его отправило другое устройство с этим кошельком, отмените его там и отправьте снова.';

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
  String deskInvPayerDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения от недоверенных отправителей проигнорированы.',
      many: '$count сообщений от недоверенных отправителей проигнорированы.',
      few: '$count сообщения от недоверенных отправителей проигнорированы.',
      one: '$count сообщение от недоверенного отправителя проигнорировано.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvPayerTrustService => 'Доверять сервису…';

  @override
  String get deskInvPayerYourInvoiceAddress => 'Ваш адрес для счетов';

  @override
  String get deskInvPayerEmptyTitle => 'Нет ожидающих счетов';

  @override
  String get deskInvPayerEmptyText =>
      'Когда доверенный сервис выставит вам счёт, он появится здесь. Ничего не оплачивается, пока вы не одобрите.';

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
  String get deskInvPayerMessageCaption =>
      'Написано сервисом. Кошелёк это не проверяет.';

  @override
  String get deskInvPayerPaysTo => 'Получатель';

  @override
  String deskInvPayerTrustedSince(String service, String date) {
    return '$service, в доверенных с $date';
  }

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
  String get deskInvSetIntro =>
      'Доверенные сервисы выставляют счета на адрес для счетов этого кошелька. Ничего не оплачивается, пока вы не одобрите каждый счёт.';

  @override
  String get deskInvSetAddressLabel => 'Адрес для счетов';

  @override
  String get deskInvSetAddressWarning =>
      'Давайте его только доверенным сервисам. Он не принимает платежи.';

  @override
  String get deskInvSetCopy => 'Копировать';

  @override
  String get deskInvSetCopied =>
      'Адрес для счетов скопирован. Давайте его только доверенным сервисам; он не принимает платежи.';

  @override
  String get deskInvSetQrShow => 'Показать QR';

  @override
  String get deskInvSetQrHide => 'Скрыть QR';

  @override
  String get deskInvSetQrLabel => 'QR-код вашего адреса для счетов';

  @override
  String deskInvSetIndex(int index) {
    return 'Адрес для счетов $index';
  }

  @override
  String get deskInvSetTrusted => 'Доверенные отправители';

  @override
  String get deskInvSetTrustedNone =>
      'Нет доверенных отправителей. Счета от всех остальных игнорируются непрочитанными.';

  @override
  String deskInvSetSince(String date) {
    return 'В доверенных с $date';
  }

  @override
  String get deskInvSetContactTag => 'Контакт';

  @override
  String get deskInvSetRemove => 'Удалить';

  @override
  String deskInvSetRemoveTitle(String name) {
    return 'Больше не доверять $name?';
  }

  @override
  String deskInvSetRemoveBody(String name) {
    return '$name больше не сможет присылать вам счета. Уже ожидающие счета останутся, пока вы не ответите или они не истекут.';
  }

  @override
  String deskInvSetRemoved(String name) {
    return '$name больше не может присылать вам счета.';
  }

  @override
  String get deskInvSetKeep => 'Оставить';

  @override
  String get deskInvSetAdd => 'Доверять отправителю';

  @override
  String get deskInvSetAddBody =>
      'Доверенный отправитель может выставлять счета на адрес для счетов этого кошелька. Ничего не оплачивается, пока вы не одобрите каждый счёт паролем кошелька.';

  @override
  String get deskInvSetName => 'Название';

  @override
  String get deskInvSetNameMissing => 'Дайте отправителю название.';

  @override
  String get deskInvSetSenderAddress => 'Его адрес для платежей';

  @override
  String get deskInvSetSenderMissing =>
      'Вставьте адрес, который показывает сервис.';

  @override
  String get deskInvSetSenderInvalid => 'Это недействительный адрес Epicbox.';

  @override
  String get deskInvSetTrust => 'Доверять';

  @override
  String deskInvSetAdded(String name) {
    return '$name теперь может присылать вам счета.';
  }

  @override
  String deskInvSetDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count сообщения от недоверенных отправителей проигнорированы непрочитанными.',
      many:
          '$count сообщений от недоверенных отправителей проигнорированы непрочитанными.',
      few:
          '$count сообщения от недоверенных отправителей проигнорированы непрочитанными.',
      one:
          '$count сообщение от недоверенного отправителя проигнорировано непрочитанным.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvSetRotate => 'Новый адрес для счетов';

  @override
  String get deskInvSetRotateHint =>
      'Сервисы со старым адресом больше не смогут присылать вам счета.';

  @override
  String get deskInvSetRotateTitle => 'Создать новый адрес для счетов?';

  @override
  String get deskInvSetRotateBody =>
      'Сервисы со старым адресом больше не смогут присылать вам счета. Передайте новый каждому сервису, который выставляет вам счета.';

  @override
  String get deskInvSetRotateConfirm => 'Создать новый адрес';

  @override
  String get deskInvSetRotated =>
      'Новый адрес для счетов готов. Передайте его своим сервисам.';

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
  String get deskInvSetCancel => 'Отмена';

  @override
  String get deskInvSetContactSection => 'Счета';

  @override
  String get deskInvSetTheirInvoice => 'Адрес для счетов контакта';

  @override
  String get deskInvSetTheirInvoiceNone =>
      'Адрес для счетов не сохранён. Попросите его, чтобы выставлять счета.';

  @override
  String get deskInvSetTrustedSwitch => 'Доверенный для счетов';

  @override
  String get deskInvSetTrustedSwitchHelp =>
      'Позволяет этому контакту выставлять вам счета. Ничего не оплачивается, пока вы не одобрите счёт.';

  @override
  String get deskInvSetIssueNeeds => 'Нужен адрес для счетов контакта.';

  @override
  String get deskInvSetShare => 'Поделиться адресом для счетов';

  @override
  String get deskInvSetReceiveHint =>
      'Попросите контакт или сервис заплатить вам. Его кошелёк должен принимать счета.';

  @override
  String get deskInvSetRestoredHint =>
      'Восстановили кошелёк из фразы восстановления? Передайте сервисам этот адрес для счетов заново.';

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
  String get methodDirect => 'Напрямую';

  @override
  String get methodDirectShape => 'http://host:3415 или xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Кошелёк получателя должен быть открыт. Платёж на адрес .onion идёт через Tor.';

  @override
  String get methodArtLabelDirect =>
      'Напрямую: платёж идёт прямо в кошелёк получателя, который должен быть открыт';

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
  String get sendSwitchedDirect => 'Прямой адрес';

  @override
  String get sendSwitchedDirectAnnounce => 'Прямой адрес. Способ: Напрямую.';

  @override
  String get sendDirectAddressShape =>
      'Прямой адрес начинается с http:// или https:// либо заканчивается на .onion.';

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
      'Сетевая активность идёт через сеть Tor. Tor скрывает интернет-адрес кошелька: каждое соединение проходит через несколько добровольческих узлов, и ни один сервер не узнаёт, где находится кошелёк. Уведомления выключены, пока включён Tor.';

  @override
  String get receiveTabDirect => 'Напрямую';

  @override
  String get receiveDirectNeedsTor => 'Для прямого приёма нужен Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Пока отправители используют адрес Epicbox.';

  @override
  String get netStatusOverTor => 'через Tor';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsHint =>
      'Использует сервис уведомлений Google. Конфиденциальные данные не передаются.';

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
  String get pushNoticeAvailable => 'Уведомления доступны в настройках.';

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
