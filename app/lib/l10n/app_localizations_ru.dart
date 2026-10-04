// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Кошелёк Epic Cash';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

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
  String get historyBackupImportFailedTitle => 'Не удалось импортировать';

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
  String homeTitle(String network) {
    return 'Epic Cash · $network';
  }

  @override
  String get homeTitleNoNetwork => 'Epic Cash · Кошелёк';

  @override
  String get homeRefreshTooltip => 'Обновить';

  @override
  String get homeLockTooltip => 'Заблокировать кошелёк';

  @override
  String get homeSettingsTooltip => 'Настройки';

  @override
  String get homeSendButton => 'Отправить';

  @override
  String get homeReceiveButton => 'Получить';

  @override
  String get homeScanTooltip => 'Сканировать QR-код для отправки';

  @override
  String get homeRecentActivity => 'Последние операции';

  @override
  String get homeSeeAll => 'Все';

  @override
  String get homeSyncingLabel => 'Синхронизация';

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
  String get homeBalanceHiddenLabel => 'Баланс скрыт';

  @override
  String get homeShowBalances => 'Показать баланс';

  @override
  String get homeHideBalances => 'Скрыть баланс';

  @override
  String homeBalanceNotSpendable(String amount) {
    return '$amount пока недоступно';
  }

  @override
  String homeBalanceAmountWaitingToFinish(String amount) {
    return '$amount ожидает завершения';
  }

  @override
  String get homeShowBreakdown => 'Показать детализацию';

  @override
  String get homeHideBreakdown => 'Скрыть детализацию';

  @override
  String get homeBalanceConfirming => 'Подтверждается';

  @override
  String get homeBalanceWaitingToFinish => 'Ожидает завершения';

  @override
  String get homeBalanceLocked => 'Заблокировано текущим платежом';

  @override
  String get homeBalanceImmature => 'Награды за майнинг (пока недоступны)';

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
  String get homeEpicboxOffline => 'Epicbox недоступен, переподключение.';

  @override
  String get homeEpicboxConnecting => 'Подключение к epicbox…';

  @override
  String homeSyncLineWithRelay(String status, String relay) {
    return '$status $relay';
  }

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
  String get homeShowMyAddress => 'Показать мой адрес';

  @override
  String get receiveTitle => 'Получить';

  @override
  String get receiveHelpTooltip => 'Справка';

  @override
  String get receiveEpicboxConnected => 'Epicbox подключён';

  @override
  String get receiveEpicboxOffline => 'Epicbox недоступен';

  @override
  String get receiveEpicboxConnecting => 'Подключение к epicbox';

  @override
  String get receiveQrLabel => 'QR-код вашего адреса';

  @override
  String get receiveAddressCopied => 'Адрес скопирован';

  @override
  String get receiveFileSection => 'Получение через файл транзакции';

  @override
  String get receiveOpenFile => 'Открыть файл транзакции';

  @override
  String get receivePasteSection => 'Или вставьте текст транзакции';

  @override
  String get receiveSlateLabel => 'Текст транзакции';

  @override
  String get receivePasteFirst => 'Вставьте полученный текст транзакции.';

  @override
  String get receiveAccept => 'Принять платёж';

  @override
  String get receiveResponseTitle => 'Верните этот ответ отправителю';

  @override
  String get receiveAnother => 'Получить ещё один платёж';

  @override
  String get updateChecking => 'Проверка обновлений…';

  @override
  String get updateUpToDate => 'Установлена последняя версия.';

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
  String get updateIconLabel => 'Обновление';

  @override
  String get updateDownloadProgressLabel => 'Ход загрузки';

  @override
  String get updateNeedsPermission =>
      'Разрешите этому приложению устанавливать обновления на открывшемся экране, затем снова нажмите «Обновить».';

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
  String get setupTitle => 'Настройки сети';

  @override
  String get setupNetworkSettingsTooltip => 'Настройки сети';

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
  String get setupRelayHeading => 'Сервер epicbox';

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
  String get restorePhraseHelper => '12 или 24 слова через пробел.';

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
      'На следующем экране можно сделать снимок экрана. Снимок или фото фразы — это полная копия вашего кошелька: любой, кто его увидит, сможет забрать ваши средства, а приложения для фото могут загрузить его в облако. Бумага надёжнее всего.';

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
  String get sendTitle => 'Отправить';

  @override
  String get sendByFileTitle => 'Отправка файлом';

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
  String get sendRecipientLabel => 'Кому';

  @override
  String get sendRecipientHintSimple => 'Адрес получателя';

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
  String get sendRecentLabel => 'Недавние:';

  @override
  String sendRecentTooltip(String address) {
    return 'Отправить на $address';
  }

  @override
  String sendSendingToContact(String name) {
    return 'Получатель: $name';
  }

  @override
  String get sendStillConnecting =>
      'Подключение ещё идёт. Отправить можно уже сейчас: платёж уйдёт, как только приложение подключится.';

  @override
  String get sendFileIntro =>
      'Отправка проходит в два шага: передайте файл транзакции получателю, затем откройте файл .response, который он вернёт, чтобы завершить платёж.';

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
  String sendSpendable(String amount) {
    return 'Доступно: $amount';
  }

  @override
  String sendSpendableWithFiat(String amount, String fiat) {
    return 'Доступно: $amount (≈ $fiat)';
  }

  @override
  String sendFeeAndTotal(String fee, String total) {
    return 'Комиссия: $fee. Итого: $total.';
  }

  @override
  String get sendNoteLabel => 'Заметка (необязательно)';

  @override
  String get sendNoteHelper => 'Эту заметку видите только вы.';

  @override
  String get sendCreateFile => 'Создать файл транзакции';

  @override
  String get sendReview => 'Проверить';

  @override
  String get sendToAddressInstead => 'Отправить на адрес';

  @override
  String get sendOtherWays => 'Другие способы отправки';

  @override
  String get sendOtherWaysExplanation =>
      'Используйте файл транзакции, если получатель не пользуется epicbox: вы передаёте файл, а он возвращает файл ответа.';

  @override
  String get sendByFileButton => 'Отправить файлом транзакции';

  @override
  String sendFileStep1(String file) {
    return 'Шаг 1: передайте $file получателю';
  }

  @override
  String get sendFileLockedNote =>
      'Средства заблокированы до завершения. Если получатель так и не ответит, откройте платёж и нажмите «Отменить платёж».';

  @override
  String sendFileStep2(String file) {
    return 'Шаг 2: откройте файл $file, который вернёт получатель';
  }

  @override
  String get sendOpenResponseFile => 'Открыть файл ответа';

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
  String sendResultStarted(String amount) {
    return 'Платёж начат: $amount';
  }

  @override
  String sendResultSent(String amount) {
    return 'Отправлено: $amount';
  }

  @override
  String get sendResultWaitingBody =>
      'Платёж завершится, когда ответит кошелёк получателя, обычно в течение нескольких минут, если у получателя открыто приложение. Не закрывайте приложение или откройте его снова в течение недели: epicbox хранит ответ примерно столько. Платёж можно найти на главном экране и на экране «История».';

  @override
  String sendResultOnItsWay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подтверждения',
      many: '$count подтверждений',
      few: '$count подтверждений',
      one: '$count подтверждения',
    );
    return 'Платёж передаётся в сеть. Он получит статус «Завершён» после $_temp0.';
  }

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
  String get sendSaveToContacts => 'Сохранить в контакты';

  @override
  String get sendHelp => 'Справка';

  @override
  String get sendReviewTitle => 'Проверьте платёж';

  @override
  String get sendReviewTo => 'Кому';

  @override
  String get sendReviewAmount => 'Сумма';

  @override
  String get sendReviewFee => 'Комиссия';

  @override
  String get sendReviewTotal => 'Итого';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
  }

  @override
  String get sendReviewNote => 'Заметка';

  @override
  String get sendReviewViaEpicbox =>
      'Через epicbox. Платёж завершится, когда ответит кошелёк получателя.';

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
  String get contactsAddressLabel => 'Адрес epicbox';

  @override
  String contactsDuplicate(String name) {
    return 'Этот адрес уже сохранён как «$name».';
  }

  @override
  String get contactsNoteLabel => 'Заметка (необязательно)';

  @override
  String get contactsSave => 'Сохранить контакт';

  @override
  String get contactsAddressMissing => 'Введите адрес epicbox.';

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
  String get settingsSectionNetwork => 'Сеть';

  @override
  String get settingsNetworkAndNode => 'Сеть и узел';

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
  String get settingsPaymentNotifications => 'Уведомления о платежах';

  @override
  String get settingsPushHint => 'Доставляются через Google Firebase.';

  @override
  String get settingsPushOnNotice =>
      'Пока ни один сервер epicbox их не отправляет. Чтобы получить платёж, откройте приложение.';

  @override
  String get settingsPushOffNotice =>
      'Уведомления прекратятся при следующем запуске приложения.';

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
  String get settingsEpicboxServer => 'Сервер epicbox';

  @override
  String get settingsCheckUpdates => 'Проверить обновления';

  @override
  String get settingsCheckingUpdates =>
      'Проверяем обновления. Результат появится на главном экране.';

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
  String get helpWaitingQuestion =>
      'Почему у платежа статус «Ждёт получателя»?';

  @override
  String helpWaitingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Платёж Epic Cash создают оба кошелька вместе: ваш начинает его, кошелёк получателя принимает, затем ваш завершает. Сервис epicbox хранит ваш платёж около недели, пока кошелёк получателя не появится в сети и не ответит. До тех пор сумма заблокирована в вашем кошельке, чтобы её нельзя было потратить дважды. Если платёж не будет завершён, кошелёк сам отменит его через $_temp0 и разблокирует сумму.';
  }

  @override
  String get helpCancellingQuestion => 'Нужно ли отменять платёж?';

  @override
  String helpCancellingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Обычно не нужно: незавершённый платёж сам отменяется через $_temp0, и сумма разблокируется. Чтобы остановить его раньше, например если получатель говорит, что никогда не ответит, откройте платёж, пока у него статус «Ждёт получателя», и нажмите «Отменить платёж»; тогда его придётся отправить заново. Платёж, который уже подтверждается, отменить нельзя. Платежи, созданные в старых версиях этого приложения, сами не отменяются: если такой платёж ждёт больше двух недель, отмените его и отправьте снова.';
  }

  @override
  String get helpReceivingQuestion =>
      'Почему для получения приложение должно быть открыто?';

  @override
  String helpReceivingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Ваш кошелёк должен принять каждый входящий платёж, а сделать это он может, только пока приложение открыто и подключено к epicbox. Платёж, отправленный, когда приложение закрыто, ждёт в epicbox около недели и поступит при следующей разблокировке. После этого epicbox удаляет его; если отправитель пользуется этим приложением, его кошелёк сам отменит платёж через $_temp0, и отправитель сможет отправить его снова. Когда ваш кошелёк примет платёж, его должен завершить кошелёк отправителя; до тех пор у платежа статус «Ждёт отправителя».';
  }

  @override
  String helpConfirmationsQuestion(int count) {
    return 'Что такое подтверждения и почему их $count?';
  }

  @override
  String helpConfirmationsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подтверждения (примерно $count минуты)',
      many: '$count подтверждений (примерно $count минут)',
      few: '$count подтверждений (примерно $count минуты)',
      one: '$count подтверждения (примерно $count минута)',
    );
    return 'Подтверждением называется новый блок, добавленный в блокчейн Epic Cash после блока с вашим платежом; блоки появляются примерно раз в минуту. С каждым блоком отменить платёж всё труднее. После $_temp0 платёж получает статус «Завершён», а полученные монеты можно тратить; таков стандарт кошелька Epic.';
  }

  @override
  String get helpHistoryQuestion =>
      'Почему после восстановления пропала история?';

  @override
  String get helpHistoryAnswer =>
      'Фраза восстановления возвращает баланс: кошелёк ищет в блокчейне принадлежащие ему монеты. Сведения о том, кому вы платили, ваши заметки и большинство дат в блокчейне не хранятся, поэтому при восстановлении их не найти. Если вы сохранили резервную копию истории, импортируйте её, чтобы вернуть их: «Настройки», раздел «История платежей», пункт «Импорт резервной копии истории». Резервная копия должна храниться вне потерянного телефона, например в почте или облаке.';

  @override
  String get helpAddressQuestion => 'Меняется ли мой адрес?';

  @override
  String get helpAddressAnswer =>
      'Ваш адрес создаётся из фразы восстановления и используемого сервера epicbox и заканчивается символом @ и именем этого сервера. Он не меняется, пока вы пользуетесь тем же сервером epicbox. Если выбрать другой сервер в настройках сети, адрес изменится, поэтому сообщите новый адрес тем, кто вам платит.';

  @override
  String get helpPhraseQuestion =>
      'Что такое фраза восстановления и кто её видит?';

  @override
  String get helpPhraseAnswer =>
      'Фраза восстановления представляет собой список слов, который служит ключом к вашим деньгам: любой, у кого она есть, может забрать ваши монеты, а с её помощью вы можете восстановить кошелёк на новом телефоне. Приложение показывает её только после ввода PIN-кода и никуда её не отправляет. Запишите её на бумаге, храните в надёжном месте, никому не сообщайте и не вводите на сайтах.';

  @override
  String get helpFeesQuestion => 'За что взимается комиссия?';

  @override
  String get helpFeesAnswer =>
      'Комиссия достаётся майнерам, которые добавляют ваш платёж в блокчейн. Обычно это малая доля EPIC; она зависит от того, сколько монет кошелёк объединяет для платежа. Точную комиссию вы увидите перед отправкой.';

  @override
  String get helpNodeQuestion => 'Что такое узел?';

  @override
  String get helpNodeAnswer =>
      'Узлом называется компьютер, который хранит копию блокчейна Epic Cash. Кошелёк запрашивает у узла ваш баланс и через него отправляет платежи в сеть. Узел видит ваш IP-адрес и то, о каких монетах спрашивает кошелёк, поэтому выберите в настройках сети узел, которому доверяете. Настройки сети доступны после включения «Расширенных настроек», а также на экране разблокировки.';

  @override
  String get helpOtherWaysQuestion => 'Есть ли другие способы отправки?';

  @override
  String get helpOtherWaysAnswer =>
      'Для опытных пользователей. Без epicbox используйте «Отправить файлом транзакции» в разделе «Другие способы отправки»: вы передаёте файл, получатель принимает его и возвращает файл .response, а вы открываете этот файл, чтобы завершить платёж. Раздел «Другие способы отправки» появляется после включения «Расширенных настроек».';

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
      'Помогает найти проблему. Фраза восстановления, PIN-код и другие секретные данные предварительно удаляются.';

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
  String get feedbackSent => 'Спасибо! Ваш отзыв отправлен.';

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
      'Сеть, узел, сервер epicbox, файлы и журналы';

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
}
