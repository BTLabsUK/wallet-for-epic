// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Mobile';

  @override
  String get appTitleDesktop => 'Epic Cash Desktop';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get noticeLevelInfo => 'Informacja';

  @override
  String get noticeLevelSuccess => 'Gotowe';

  @override
  String get noticeLevelWarning => 'Ostrzeżenie';

  @override
  String get noticeLevelError => 'Błąd';

  @override
  String get commonContinue => 'Dalej';

  @override
  String get commonCopy => 'Kopiuj';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonDone => 'Gotowe';

  @override
  String get commonError => 'Błąd';

  @override
  String get commonOk => 'OK';

  @override
  String get commonPaste => 'Wklej';

  @override
  String get commonRetry => 'Ponów';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonShare => 'Udostępnij';

  @override
  String get commonUnknown => 'Nieznane';

  @override
  String get passwordShow => 'Pokaż hasło';

  @override
  String get passwordHide => 'Ukryj hasło';

  @override
  String get slateCopyTooltip => 'Kopiuj tekst transakcji';

  @override
  String get slateCopied => 'Skopiowano tekst transakcji';

  @override
  String get slatePastedTitle => 'Wklejona płatność';

  @override
  String get slateCopyReply => 'Kopiuj odpowiedź';

  @override
  String get biometricPromptTitle => 'Odblokuj portfel';

  @override
  String get biometricPromptSubtitle => 'Potwierdź odciskiem palca lub twarzą';

  @override
  String get biometricPromptUsePin => 'Użyj kodu PIN';

  @override
  String get amountEnterExample => 'Wpisz kwotę, np. 1,5';

  @override
  String amountTooManyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Maksymalnie $count miejsca po przecinku',
      many: 'Maksymalnie $count miejsc po przecinku',
      few: 'Maksymalnie $count miejsca po przecinku',
      one: 'Maksymalnie $count miejsce po przecinku',
    );
    return '$_temp0';
  }

  @override
  String dateWithTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get dateToday => 'Dzisiaj';

  @override
  String get dateYesterday => 'Wczoraj';

  @override
  String get txMiningReward => 'Nagroda za wydobycie';

  @override
  String get txRestoredFunds => 'Odzyskane środki';

  @override
  String get txOutgoingPayment => 'Płatność wychodząca';

  @override
  String get txIncomingPayment => 'Płatność przychodząca';

  @override
  String get txStatusWaitingRecipient => 'Czeka na odbiorcę';

  @override
  String get txStatusWaitingSender => 'Czeka na nadawcę';

  @override
  String txStatusConfirming(int count, int target) {
    return 'Potwierdzanie $count/$target';
  }

  @override
  String get txStatusCompleted => 'Zakończona';

  @override
  String get txStatusCancelled => 'Anulowana';

  @override
  String get txStatusFromBackup => 'Z kopii, stan nieznany';

  @override
  String get txIconCancelled => 'Anulowana';

  @override
  String get txIconIncoming => 'Przychodząca';

  @override
  String get txIconOutgoing => 'Wychodząca';

  @override
  String get txSpokenHiddenAmount => 'ukryta kwota';

  @override
  String txSpokenMiningReward(String amount) {
    return 'Nagroda za wydobycie: $amount';
  }

  @override
  String txSpokenRestoredFunds(String amount) {
    return 'Odzyskane środki: $amount';
  }

  @override
  String txSpokenCancelledSend(String amount) {
    return 'Anulowana wysyłka: $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return 'Anulowana wysyłka: $amount, odbiorca: $who';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return 'Anulowany odbiór: $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return 'Anulowany odbiór: $amount, nadawca: $who';
  }

  @override
  String txSpokenSending(String amount) {
    return 'Wysyłanie: $amount';
  }

  @override
  String txSpokenSendingTo(String amount, String who) {
    return 'Wysyłanie: $amount, odbiorca: $who';
  }

  @override
  String txSpokenReceiving(String amount) {
    return 'Odbieranie: $amount';
  }

  @override
  String txSpokenReceivingFrom(String amount, String who) {
    return 'Odbieranie: $amount, nadawca: $who';
  }

  @override
  String txSpokenSent(String amount) {
    return 'Wysłano: $amount';
  }

  @override
  String txSpokenSentTo(String amount, String who) {
    return 'Wysłano: $amount, odbiorca: $who';
  }

  @override
  String txSpokenReceived(String amount) {
    return 'Odebrano: $amount';
  }

  @override
  String txSpokenReceivedFrom(String amount, String who) {
    return 'Odebrano: $amount, nadawca: $who';
  }

  @override
  String txSpokenRow(String what, String status, String date) {
    return '$what, $status, $date';
  }

  @override
  String get errorInvalidMnemonic =>
      'Fraza odzyskiwania jest nieprawidłowa. Sprawdź każde słowo i ich kolejność.';

  @override
  String get errorWrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get errorWalletAlreadyExists => 'Portfel dla tej sieci już istnieje.';

  @override
  String get errorWalletNotFound => 'Nie znaleziono portfela dla tej sieci.';

  @override
  String get errorNodeUnreachable =>
      'Nie można połączyć się z węzłem. Sprawdź adres URL węzła i połączenie z internetem.';

  @override
  String get errorNotEnoughFunds =>
      'Za mało dostępnych środków na tę kwotę wraz z opłatą.';

  @override
  String get errorInvalidSlate =>
      'Ten tekst transakcji nie pasuje do tego kroku. Sprawdź, czy wklejono go w całości.';

  @override
  String get errorInvalidInput => 'Nieprawidłowe dane.';

  @override
  String get errorTransportFailed => 'Nie udało się połączyć z odbiorcą.';

  @override
  String get errorTorNotRunning => 'Tor nie jest połączony.';

  @override
  String get errorOnionUnreachable =>
      'Nie udało się połączyć z portfelem odbiorcy przez Tor.';

  @override
  String get errorChainBusy =>
      'Portfel jest jeszcze zajęty w drugiej sieci. Poczekaj chwilę i spróbuj ponownie albo zamknij i ponownie otwórz aplikację.';

  @override
  String get errorWalletBusy =>
      'Portfel kończy jeszcze zadanie. Spróbuj ponownie za chwilę.';

  @override
  String get errorPaymentExpired =>
      'Odpowiedź na tę płatność nadeszła za późno, więc płatność anulowano. Nic nie zostało wysłane.';

  @override
  String get errorIo => 'Nie można odczytać ani zapisać plików portfela.';

  @override
  String get errorOther => 'Błąd portfela.';

  @override
  String get errorScanFailed => 'Skanowanie nie powiodło się.';

  @override
  String get errorUnexpected => 'Nieoczekiwany błąd. Spróbuj ponownie.';

  @override
  String get errorHistoryNotOurs =>
      'To nie jest plik historii wyeksportowany z tej aplikacji.';

  @override
  String get errorHistoryNewer =>
      'Ten plik historii utworzono w nowszej wersji aplikacji.';

  @override
  String get errorHistoryDamaged => 'Ten plik historii jest uszkodzony.';

  @override
  String get errorHistoryOtherWallet =>
      'Ten plik historii należy do innego portfela.';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return 'Ten plik historii pochodzi z sieci $fileNetwork, a ten portfel działa w sieci $walletNetwork.';
  }

  @override
  String get networkMainnet => 'Mainnet';

  @override
  String get networkFloonet => 'Floonet';

  @override
  String get networkUsernet => 'Usernet';

  @override
  String get networkMainnetDescription => 'Prawdziwa sieć Epic Cash.';

  @override
  String get networkFloonetDescription =>
      'Publiczna sieć testowa do wypróbowania aplikacji. Jej monety nie mają wartości; darmowe można zdobyć na floo-explorer.btlabs.uk.';

  @override
  String get networkUsernetDescription =>
      'Sieć testowa działająca na tym komputerze, dla programistów.';

  @override
  String networkTestSuffix(String network) {
    return ' ($network, monety testowe)';
  }

  @override
  String get autoLockNever => 'Nigdy';

  @override
  String get autoLockImmediately => 'Natychmiast';

  @override
  String autoLockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Po $minutes minuty',
      many: 'Po $minutes minutach',
      few: 'Po $minutes minutach',
      one: 'Po $minutes minucie',
    );
    return '$_temp0';
  }

  @override
  String get scanStarting => 'Rozpoczynanie skanowania';

  @override
  String scanProgress(int percent) {
    return 'Skanowanie łańcucha ($percent%)';
  }

  @override
  String get scanComplete => 'Skanowanie zakończone';

  @override
  String get languageSetting => 'Język';

  @override
  String get languageSystem => 'Język systemu';

  @override
  String get currencyUsd => 'Dolar amerykański';

  @override
  String get currencyEur => 'Euro';

  @override
  String get currencyGbp => 'Funt brytyjski';

  @override
  String get currencyBtc => 'Bitcoin';

  @override
  String get currencyJpy => 'Jen japoński';

  @override
  String get currencyCny => 'Juan chiński';

  @override
  String get currencyCad => 'Dolar kanadyjski';

  @override
  String get currencyAud => 'Dolar australijski';

  @override
  String get currencyChf => 'Frank szwajcarski';

  @override
  String get currencyInr => 'Rupia indyjska';

  @override
  String get currencyBrl => 'Real brazylijski';

  @override
  String get currencyKrw => 'Won południowokoreański';

  @override
  String get currencyPln => 'Polski złoty';

  @override
  String get currencyTry => 'Lira turecka';

  @override
  String txDetailsWaitingTooLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Płatność czeka już $days dnia. Serwer epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować środki, a potem wyślij ponownie.',
      many:
          'Płatność czeka już $days dni. Serwer epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować środki, a potem wyślij ponownie.',
      few:
          'Płatność czeka już $days dni. Serwer epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować środki, a potem wyślij ponownie.',
      one:
          'Płatność czeka już $days dzień. Serwer epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować środki, a potem wyślij ponownie.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Wysłano na serwer epicbox odbiorcy. Płatność zakończy się, gdy portfel odbiorcy połączy się z siecią. Do tego czasu lub do anulowania środki pozostaną zablokowane.';

  @override
  String get txDetailsWaitingRecipient =>
      'Oczekiwanie, aż odbiorca odeśle plik transakcji. Do tego czasu lub do anulowania środki pozostaną zablokowane.';

  @override
  String get txDetailsWaitingSender =>
      'Ta płatność została przyjęta. Zakończy się, gdy nadawca ją sfinalizuje i opublikuje w sieci.';

  @override
  String get txDetailsPublished =>
      'Opublikowano w sieci. Oczekiwanie na pierwsze potwierdzenie.';

  @override
  String get txDetailsWaitingConfirmation =>
      'Oczekiwanie na potwierdzenie przez sieć.';

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
      other: '$target potwierdzenia',
      many: '$target potwierdzeń',
      few: '$target potwierdzeń',
      one: '$target potwierdzenia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuty',
      many: '$minutes minut',
      few: '$minutes minuty',
      one: '$minutes minutę',
    );
    return 'W bloku $height. $count z $_temp0; pełne potwierdzenie za około $_temp1.';
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
      other: '$target potwierdzenia',
      many: '$target potwierdzeń',
      few: '$target potwierdzeń',
      one: '$target potwierdzenia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours godziny',
      many: '$hours godzin',
      few: '$hours godziny',
      one: '$hours godzinę',
    );
    return 'W bloku $height. $count z $_temp0; pełne potwierdzenie za około $_temp1.';
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
      other: '$target potwierdzenia',
      many: '$target potwierdzeń',
      few: '$target potwierdzeń',
      one: '$target potwierdzenia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dnia',
      many: '$days dni',
      few: '$days dni',
      one: '$days dzień',
    );
    return 'W bloku $height. $count z $_temp0; pełne potwierdzenie za około $_temp1.';
  }

  @override
  String get txDetailsCompleted => 'Płatność zakończona.';

  @override
  String txDetailsCompletedInBlock(String height) {
    return 'Płatność zakończona w bloku $height.';
  }

  @override
  String get txDetailsCancelledByUser =>
      'Anulowano. Nic nie zostało wysłane, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledReleased =>
      'Sieć nie przyjęła tej płatności, więc jej środki zostały zwolnione. Przed ponownym wysłaniem sprawdź, czy odbiorca jej nie otrzymał.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Płatność nie trafiła do sieci w ciągu 14 dni, więc portfel ją anulował. Przed ponownym wysłaniem sprawdź, czy odbiorca jej nie otrzymał.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Odbiorca nie odpowiedział w ciągu 14 dni, więc portfel anulował płatność. Nic nie zostało wysłane, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Odbiorca odpowiedział po upływie 14 dni, więc portfel anulował płatność, zamiast ją dokończyć. Nic nie zostało wysłane, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Nie udało się dostarczyć płatności do odbiorcy, więc portfel od razu ją anulował. Nic nie zostało wysłane, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledIncoming => 'Anulowano. Ta płatność nie dotrze.';

  @override
  String get txDetailsFromBackup =>
      'Ta płatność pochodzi z kopii historii i nie była zakończona, gdy kopię tworzono. Ten portfel nie ma własnego zapisu tej płatności, więc nie wie, czy się zakończyła. Nic nie jest zablokowane.';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return 'Zostanie automatycznie anulowana, jeśli nie zakończy się do bloku $height.';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuty',
      many: '$minutes minut',
      few: '$minutes minuty',
      one: '$minutes minutę',
    );
    return 'Zostanie automatycznie anulowana, jeśli nie zakończy się do bloku $height (za około $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours godziny',
      many: '$hours godzin',
      few: '$hours godziny',
      one: '$hours godzinę',
    );
    return 'Zostanie automatycznie anulowana, jeśli nie zakończy się do bloku $height (za około $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dnia',
      many: '$days dni',
      few: '$days dni',
      one: '$days dzień',
    );
    return 'Zostanie automatycznie anulowana, jeśli nie zakończy się do bloku $height (za około $_temp0).';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return 'Wygasła w bloku $height. Portfel anuluje ją przy następnym odświeżeniu.';
  }

  @override
  String get txDetailsTitle => 'Płatność';

  @override
  String get txDetailsLoading => 'Wczytywanie';

  @override
  String get txDetailsGone => 'Tej płatności nie ma już w portfelu.';

  @override
  String get txDetailsWorking => 'Przetwarzanie';

  @override
  String get txDetailsAmountHidden => 'Kwota ukryta';

  @override
  String get txDetailsNotConfirmedYet => 'Jeszcze niepotwierdzona';

  @override
  String get txDetailsStuckBody =>
      'Sieć jeszcze nie przyjęła tej płatności. Ponowne rozgłoszenie jest bezpieczne. Ta sama płatność nie może przejść dwa razy.';

  @override
  String get txDetailsBroadcastAgain => 'Rozgłoś ponownie';

  @override
  String get txDetailsBroadcastAgainDone =>
      'Rozgłoszono ponownie. Płatność powinna zostać potwierdzona w ciągu kilku minut.';

  @override
  String get txDetailsRefusedBody =>
      'Sieć odrzuciła tę płatność i nigdy nie trafiła ona do łańcucha. Możesz zwolnić zablokowane przez nią środki.';

  @override
  String get txDetailsReleaseFunds => 'Zwolnij środki';

  @override
  String get txDetailsReleaseTitle => 'Zwolnić środki?';

  @override
  String get txDetailsReleaseBody =>
      'Użyj tej opcji tylko wtedy, gdy płatność nigdy nie zostanie potwierdzona. Jeśli jednak zostanie, saldo może być błędne do czasu ponownego skanowania.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Czekaj dalej';

  @override
  String get txDetailsFundsReleased => 'Środki zwolnione';

  @override
  String get txDetailsCancelPayment => 'Anuluj płatność';

  @override
  String get txDetailsCancelTitle => 'Anulować płatność?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Nadawca może jeszcze dokończyć tę płatność. Jeśli zrobi to po anulowaniu, płatność nie będzie widoczna do czasu ponownego skanowania.';

  @override
  String get txDetailsCancelSendBody =>
      'Anulować tę płatność i odblokować jej środki? Zrób to tylko wtedy, gdy odbiorca jej nie sfinalizował.';

  @override
  String get txDetailsCancelKeep => 'Zachowaj';

  @override
  String get txDetailsPaymentCancelled => 'Płatność anulowana';

  @override
  String get txDetailsDate => 'Data';

  @override
  String get txDetailsCreated => 'Utworzono';

  @override
  String get txDetailsSentTo => 'Wysłano do';

  @override
  String get txDetailsReceivedFrom => 'Otrzymano od';

  @override
  String get txDetailsCopyAddress => 'Kopiuj adres';

  @override
  String get txDetailsAddressCopied => 'Skopiowano adres';

  @override
  String get txDetailsAddToContacts => 'Dodaj do kontaktów';

  @override
  String get txDetailsSendAgain => 'Wyślij ponownie';

  @override
  String get txDetailsFee => 'Opłata';

  @override
  String get txDetailsNoteLabel => 'Notatka';

  @override
  String get txDetailsPrivateNoteLabel =>
      'Prywatna notatka, tylko na tym urządzeniu';

  @override
  String get txDetailsMessageFromSender => 'Wiadomość od nadawcy';

  @override
  String get txDetailsMessageFromRecipient => 'Wiadomość od odbiorcy';

  @override
  String get txDetailsYourMessage => 'Twoja wiadomość';

  @override
  String get txDetailsNoNote =>
      'Brak notatki. Dodaj ją, aby pamiętać, czego dotyczyła płatność.';

  @override
  String get txDetailsAddNote => 'Dodaj notatkę';

  @override
  String get txDetailsEditNote => 'Edytuj notatkę';

  @override
  String get txDetailsNoteDialogTitle => 'Notatka';

  @override
  String get txDetailsNoteHelper =>
      'Tylko na tym urządzeniu i w kopiach historii.';

  @override
  String get txDetailsNoteSaved => 'Zapisano notatkę';

  @override
  String get txDetailsNoteRemoved => 'Usunięto notatkę';

  @override
  String get txDetailsExplorerLink => 'Kopiuj link do eksploratora';

  @override
  String get txDetailsExplorerLinkCopy => 'Kopiuj link do eksploratora';

  @override
  String get txDetailsLinkCopied => 'Skopiowano link';

  @override
  String get txDetailsTechnical => 'Szczegóły techniczne';

  @override
  String get txDetailsBlockHeight => 'Wysokość bloku';

  @override
  String get txDetailsSlateId => 'ID slate';

  @override
  String get txDetailsSlateIdCopy => 'Kopiuj ID slate';

  @override
  String get txDetailsSlateIdCopied => 'Skopiowano ID slate';

  @override
  String get txDetailsKernel => 'Kernel';

  @override
  String get txDetailsKernelCopy => 'Kopiuj kernel';

  @override
  String get txDetailsKernelCopied => 'Skopiowano kernel';

  @override
  String get txDetailsOutputCommitment => 'Zobowiązanie wyjścia';

  @override
  String get txDetailsOutputCommitmentCopy => 'Kopiuj zobowiązanie wyjścia';

  @override
  String get txDetailsOutputCommitmentCopied =>
      'Skopiowano zobowiązanie wyjścia';

  @override
  String txDetailsOutputCommitmentNumbered(int number) {
    return 'Zobowiązanie wyjścia $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopy(int number) {
    return 'Kopiuj zobowiązanie wyjścia $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopied(int number) {
    return 'Skopiowano zobowiązanie wyjścia $number';
  }

  @override
  String get txDetailsExpiryHeight => 'Wysokość wygaśnięcia';

  @override
  String get txDetailsLocalId => 'Lokalny identyfikator';

  @override
  String get txDetailsSourceRestored =>
      'Znaleziono podczas skanowania łańcucha. Szczegóły, takie jak nadawca i opłata, nie są zapisywane w łańcuchu; zaimportuj kopię historii, aby je przywrócić.';

  @override
  String get txDetailsSourceImported =>
      'Zaimportowano z kopii historii. Ten portfel nie ma własnego zapisu tej płatności, więc jej stan może być nieaktualny.';

  @override
  String get historyTitle => 'Historia';

  @override
  String get historyLoading => 'Wczytywanie płatności';

  @override
  String get historyRefreshing => 'Odświeżanie';

  @override
  String get historySearchLabel => 'Szukaj';

  @override
  String get historySearchHint => 'Notatka, kontakt, adres lub kwota';

  @override
  String get historyClearSearch => 'Wyczyść wyszukiwanie';

  @override
  String get historyFilterAll => 'Wszystkie';

  @override
  String get historyFilterSent => 'Wysłane';

  @override
  String get historyFilterReceived => 'Odebrane';

  @override
  String get historyFilterPending => 'Oczekujące';

  @override
  String get historyFilterCancelled => 'Anulowane';

  @override
  String get historySectionPending => 'Oczekujące';

  @override
  String get historyEmpty =>
      'Nic tu jeszcze nie ma. Tutaj pojawią się wysłane i odebrane płatności.';

  @override
  String get historyNoSent => 'Brak wysłanych płatności.';

  @override
  String get historyNoReceived => 'Brak odebranych płatności.';

  @override
  String get historyNoPending => 'Brak oczekujących płatności.';

  @override
  String get historyNoCancelled => 'Brak anulowanych płatności.';

  @override
  String historyNoMatch(String query) {
    return 'Brak wyników dla „$query”.';
  }

  @override
  String get historyBackupSaveDialogTitle => 'Zapisz historię płatności';

  @override
  String get historyBackupOpenDialogTitle => 'Otwórz kopię historii';

  @override
  String get historyBackupFileTooLarge =>
      'Ten plik jest za duży, aby mógł być kopią.';

  @override
  String get historyBackupShare => 'Udostępnij';

  @override
  String get historyBackupShareSubtitle =>
      'Zachowaj kopię poza telefonem, np. w e-mailu lub w chmurze';

  @override
  String get historyBackupSaveToDevice => 'Zapisz na urządzeniu';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Ma sens tylko, jeśli skopiujesz plik także poza ten telefon.';

  @override
  String historyBackupSaved(String fileName) {
    return 'Zapisano $fileName';
  }

  @override
  String get historyBackupExportTitle => 'Eksportuj kopię historii';

  @override
  String get historyBackupExportNote =>
      'Kopia historii obejmuje płatności do tej chwili. Po nowych płatnościach wyeksportuj ją ponownie.';

  @override
  String get historyBackupCsvTitle => 'Eksportuj CSV';

  @override
  String get historyBackupCsvWarning =>
      'Plik CSV nie jest zaszyfrowany. Każdy, kto go zdobędzie, odczyta kwoty, daty, adresy i notatki. Nie da się go z powrotem zaimportować; do tego służy „Eksportuj kopię historii”.';

  @override
  String get historyBackupCsvConfirm => 'Eksportuj CSV';

  @override
  String get historyBackupImportedTitle => 'Zaimportowano historię';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Nie zaimportowano historii. $reason';
  }

  @override
  String get historyBackupImportNothingNew =>
      'Kopia nie zawierała niczego nowego.';

  @override
  String historyBackupImportMerged(int merged) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Dodano $added starszych płatności',
      many: 'Dodano $added starszych płatności',
      few: 'Dodano $added starsze płatności',
      one: 'Dodano $added starszą płatność',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedAdded(int merged, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'dodano $added starszych płatności',
      many: 'dodano $added starszych płatności',
      few: 'dodano $added starsze płatności',
      one: 'dodano $added starszą płatność',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportSkipped(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedSkipped(int merged, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Dodano $added starszych płatności',
      many: 'Dodano $added starszych płatności',
      few: 'Dodano $added starsze płatności',
      one: 'Dodano $added starszą płatność',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
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
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'dodano $added starszych płatności',
      many: 'dodano $added starszych płatności',
      few: 'dodano $added starsze płatności',
      one: 'dodano $added starszą płatność',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportContacts(int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'Dodano $contacts kontaktu',
      many: 'Dodano $contacts kontaktów',
      few: 'Dodano $contacts kontakty',
      one: 'Dodano $contacts kontakt',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedContacts(int merged, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedContacts(int added, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Dodano $added starszych płatności',
      many: 'Dodano $added starszych płatności',
      few: 'Dodano $added starsze płatności',
      one: 'Dodano $added starszą płatność',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
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
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'dodano $added starszych płatności',
      many: 'dodano $added starszych płatności',
      few: 'dodano $added starsze płatności',
      one: 'dodano $added starszą płatność',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportSkippedContacts(int skipped, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
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
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
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
      other: 'Dodano $added starszych płatności',
      many: 'Dodano $added starszych płatności',
      few: 'Dodano $added starsze płatności',
      one: 'Dodano $added starszą płatność',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
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
      other: 'Uzupełniono szczegóły $merged płatności',
      many: 'Uzupełniono szczegóły $merged płatności',
      few: 'Uzupełniono szczegóły $merged płatności',
      one: 'Uzupełniono szczegóły $merged płatności',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'dodano $added starszych płatności',
      many: 'dodano $added starszych płatności',
      few: 'dodano $added starsze płatności',
      one: 'dodano $added starszą płatność',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wpisu już istniało',
      many: '$skipped wpisów już istniało',
      few: '$skipped wpisy już istniały',
      one: '$skipped wpis już istniał',
    );
    String _temp3 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: 'dodano $contacts kontaktu',
      many: 'dodano $contacts kontaktów',
      few: 'dodano $contacts kontakty',
      one: 'dodano $contacts kontakt',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3.';
  }

  @override
  String get homeLockTooltip => 'Zablokuj portfel';

  @override
  String get shellTitle => 'Epic Cash Mobile';

  @override
  String get demoWelcomeTitle => 'Wypróbuj Epic Cash';

  @override
  String get demoWelcomeLine =>
      'Prawdziwy portfel z darmowymi monetami testowymi bez wartości. Zostanie usunięty po 24 godzinach.';

  @override
  String get demoStart => 'Uruchom demo';

  @override
  String get demoEndedTitle => 'Twoje demo się skończyło';

  @override
  String get demoEndedBody => 'Jego portfel i monety testowe zostały usunięte.';

  @override
  String get demoStartAgain => 'Zacznij od nowa';

  @override
  String demoEndsAt(String time) {
    return 'Twoje demo kończy się $time. Wtedy jego portfel i monety testowe zostaną usunięte.';
  }

  @override
  String get demoEndingSoon =>
      'Twoje demo kończy się za 30 minut. Wtedy jego portfel i monety testowe zostaną usunięte.';

  @override
  String get demoTestCoins => 'Pobierz monety testowe';

  @override
  String get demoTestCoinsPaid =>
      'Monety testowe są w drodze. Dotrą w ciągu minuty lub dwóch.';

  @override
  String demoTestCoinsCooldown(int seconds) {
    return 'Kran potrzebuje przerwy. Spróbuj ponownie za $seconds s.';
  }

  @override
  String get demoTestCoinsFailed =>
      'Kran tym razem nic nie wysłał. Spróbuj ponownie za minutę.';

  @override
  String get demoEnd => 'Zakończ demo';

  @override
  String get demoEndTitle => 'Zakończyć demo?';

  @override
  String get demoEndBody =>
      'Portfel demo i jego monety testowe zostaną teraz usunięte. Potem możesz uruchomić nowe demo.';

  @override
  String get demoServerUnreachable =>
      'Nie można połączyć się z serwerem demo. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String demoStartFull(int minutes) {
    return 'Demo jest teraz pełne. Spróbuj ponownie za $minutes min.';
  }

  @override
  String demoStartTooMany(int minutes) {
    return 'Z Twojej sieci uruchomiono zbyt wiele wersji demo. Spróbuj ponownie za $minutes min.';
  }

  @override
  String get demoConnectionLost =>
      'Utracono połączenie, trwa ponowne łączenie.';

  @override
  String get demoConnectionBack => 'Połączono ponownie.';

  @override
  String get homeSettingsTooltip => 'Ustawienia';

  @override
  String get homeSettingsUpdateTooltip =>
      'Ustawienia: dostępna jest aktualizacja';

  @override
  String get homeSendButton => 'Wyślij';

  @override
  String get shellWalletTab => 'Portfel';

  @override
  String get homeReceiveButton => 'Odbierz';

  @override
  String get homeScanTooltip => 'Zeskanuj kod QR, aby wysłać';

  @override
  String get homeRecentActivity => 'Ostatnia aktywność';

  @override
  String get homeSeeAll => 'Wszystkie';

  @override
  String get homeBackedUpNotice => 'Fraza odzyskiwania zabezpieczona';

  @override
  String get homeNoticeView => 'Pokaż';

  @override
  String get homePushNotice =>
      'Na serwerze epicbox czeka płatność. Dotrze, gdy aplikacja się połączy.';

  @override
  String get homeNoticeReceived =>
      'Płatność jest w drodze. Zakończy się, gdy nadawca ją sfinalizuje.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return '$who wysyła płatność. Zakończy się, gdy nadawca ją sfinalizuje.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount w drodze. Płatność zakończy się, gdy nadawca ją sfinalizuje.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$who wysyła $amount. Płatność zakończy się, gdy nadawca ją sfinalizuje.';
  }

  @override
  String get homeNoticeFinished =>
      'Płatność sfinalizowana. Oczekiwanie na potwierdzenia.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Płatność sfinalizowana (odbiorca: $who). Oczekiwanie na potwierdzenia.';
  }

  @override
  String get homeNoticeRepeated =>
      'Ta płatność została już przyjęta. Nadawca ponownie otrzymał tę samą odpowiedź; żadna druga płatność nie jest w drodze.';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return 'Płatność od $who została już przyjęta. Nadawca ponownie otrzymał tę samą odpowiedź; żadna druga płatność nie jest w drodze.';
  }

  @override
  String get homeNoticeDelayed =>
      'Nie można połączyć się z węzłem. Płatność zostanie sfinalizowana, gdy będzie to możliwe.';

  @override
  String get homeNoticeRelayProblem =>
      'Serwer epicbox zgłosił problem. Ponawianie próby.';

  @override
  String get homeNoticePaymentFailed => 'Nie udało się zrealizować płatności.';

  @override
  String get homeBackupCardText => 'Zabezpiecz frazę odzyskiwania.';

  @override
  String get homeBackupCardButton => 'Zabezpiecz';

  @override
  String get homeBackupCardDismiss => 'Ukryj';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności nie ma jeszcze kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
      many:
          '$count płatności nie ma jeszcze kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
      few:
          '$count płatności nie mają jeszcze kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
      one:
          '$count płatność nie ma jeszcze kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności jest nowych lub zmienionych od ostatniej kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
      many:
          '$count płatności jest nowych lub zmienionych od ostatniej kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
      few:
          '$count płatności są nowe lub zmienione od ostatniej kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
      one:
          '$count płatność jest nowa lub zmieniona od ostatniej kopii historii. Przywrócenie z frazy odzyskiwania odtwarza tylko saldo.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Nie teraz';

  @override
  String get homeHistoryExportButton => 'Eksportuj kopię historii';

  @override
  String get homeBalanceSpendable => 'Dostępne';

  @override
  String get balanceHelpLabel => 'Co oznaczają te salda';

  @override
  String get balanceTotal => 'Łącznie';

  @override
  String balanceHelpRow(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get balanceTotalHelp => 'Wszystko w tym portfelu, dostępne lub nie.';

  @override
  String get homeBalanceHiddenLabel => 'Saldo ukryte';

  @override
  String get homeShowBalances => 'Pokaż salda';

  @override
  String get homeHideBalances => 'Ukryj salda';

  @override
  String get homeBalanceConfirming => 'Potwierdzanie';

  @override
  String get balanceConfirmingHelp =>
      'W łańcuchu, czeka na wystarczającą liczbę potwierdzeń.';

  @override
  String get homeBalanceNotOnChain => 'Jeszcze nie w łańcuchu';

  @override
  String get balanceNotOnChainHelp =>
      'Płatności do Ciebie, których nadawca jeszcze nie dokończył lub które nie są jeszcze w bloku, oraz reszta z Twoich wysyłek. Liczą się dopiero w bloku: płatność tylko zaproponowana może nigdy nie dotrzeć.';

  @override
  String get homeBalanceLocked => 'Zablokowane przez trwającą płatność';

  @override
  String get balanceLockedHelp =>
      'Zarezerwowane na rozpoczętą płatność; reszta wróci po jej zakończeniu.';

  @override
  String get homeBalanceImmature => 'Nagrody za wydobycie jeszcze niedostępne';

  @override
  String get balanceImmatureHelp =>
      'Nagrody za kopanie czekają określoną liczbę bloków, zanim można je wydać.';

  @override
  String get balanceLineAllConfirmed => 'Wszystko potwierdzone';

  @override
  String get balanceLineNothingYet => 'Jeszcze nic tu nie ma';

  @override
  String get homeSyncSyncing => 'Synchronizacja…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'Synchronizacja… $percent%';
  }

  @override
  String get homeSyncNodeUnreachable =>
      'Węzeł nieosiągalny. Salda mogą być nieaktualne.';

  @override
  String get homeSyncNotValidated =>
      'Niezweryfikowane przez węzeł. Salda mogą być nieaktualne.';

  @override
  String get homeSyncUpToDate => 'Aktualne.';

  @override
  String get homeSyncContactingNode => 'Łączenie z węzłem…';

  @override
  String get statusNodeOnline => 'Węzeł online';

  @override
  String get statusNodeSyncing => 'Synchronizacja węzła';

  @override
  String statusNodeSyncingPercent(int percent) {
    return 'Synchronizacja węzła $percent%';
  }

  @override
  String get statusNodeConnecting => 'Łączenie z węzłem';

  @override
  String get statusNodeOffline => 'Węzeł offline';

  @override
  String get statusEpicboxOnline => 'epicbox online';

  @override
  String get statusEpicboxConnecting => 'Łączenie z epicbox';

  @override
  String get statusEpicboxOffline => 'epicbox offline';

  @override
  String statusNodeTestNetwork(String network) {
    return '$network, monety testowe';
  }

  @override
  String statusNodeHost(Object host) {
    return 'Węzeł: $host';
  }

  @override
  String statusNodeVersion(Object version) {
    return 'Wersja węzła $version';
  }

  @override
  String statusRelay(Object relay) {
    return 'Serwer: $relay';
  }

  @override
  String get homeEpicboxOffline =>
      'Brak połączenia z epicbox, ponowne łączenie.';

  @override
  String get homeEpicboxConnecting => 'Łączenie z epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Zsynchronizowano do bloku $height';
  }

  @override
  String homePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności czeka na odbiorców',
      many: '$count płatności czeka na odbiorców',
      few: '$count płatności czekają na odbiorców',
      one: 'Płatność czeka na odbiorcę',
    );
    return '$_temp0';
  }

  @override
  String homePendingBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$amount czeka na odpowiedź portfeli odbiorców. Do tego czasu środki pozostaną zablokowane. Jeśli któraś odpowiedź nigdy nie nadejdzie, otwórz płatność i dotknij „Anuluj płatność”.',
      many:
          '$amount czeka na odpowiedź portfeli odbiorców. Do tego czasu środki pozostaną zablokowane. Jeśli któraś odpowiedź nigdy nie nadejdzie, otwórz płatność i dotknij „Anuluj płatność”.',
      few:
          '$amount czeka na odpowiedź portfeli odbiorców. Do tego czasu środki pozostaną zablokowane. Jeśli któraś odpowiedź nigdy nie nadejdzie, otwórz płatność i dotknij „Anuluj płatność”.',
      one:
          '$amount czeka na odpowiedź portfela odbiorcy. Do tego czasu środki pozostaną zablokowane. Jeśli odpowiedź nigdy nie nadejdzie, otwórz płatność i dotknij „Anuluj płatność”.',
    );
    return '$_temp0';
  }

  @override
  String get homePendingWhy => 'Dlaczego czeka?';

  @override
  String homePendingView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pokaż płatności',
      many: 'Pokaż płatności',
      few: 'Pokaż płatności',
      one: 'Pokaż płatność',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPayments => 'Brak płatności.';

  @override
  String get invoicesTitle => 'Faktury';

  @override
  String invoicesEntryTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faktury, $count oczekuje',
      many: 'Faktury, $count oczekuje',
      few: 'Faktury, $count oczekują',
      one: 'Faktury, $count oczekuje',
      zero: 'Faktury',
    );
    return '$_temp0';
  }

  @override
  String get invoicesChecking => 'Sprawdzanie faktur';

  @override
  String get invoicesEmpty =>
      'Brak oczekujących faktur. Gdy zaufany serwis wystawi Ci fakturę, pojawi się tutaj. Nic nie zostanie zapłacone bez Twojej zgody.';

  @override
  String get invoicesUnnamedService => 'Serwis bez nazwy';

  @override
  String invoiceTimeLeftHours(int hours, int minutes) {
    return 'Zostało $hours godz. $minutes min';
  }

  @override
  String invoiceTimeLeftMinutes(int minutes) {
    return 'Zostało $minutes min';
  }

  @override
  String get invoiceTimeLeftUnderMinute => 'Została niecała minuta';

  @override
  String get invoiceExpired => 'Ta faktura wygasła. Nic nie zostało zapłacone.';

  @override
  String get invoiceGone =>
      'Ta faktura nie jest już otwarta. Nic nie zostało zapłacone.';

  @override
  String get invoiceReviewTitle => 'Sprawdź fakturę';

  @override
  String invoiceReviewAsks(String service) {
    return 'Serwis $service prosi o zapłatę';
  }

  @override
  String get invoiceReviewMessageLabel => 'Wiadomość od serwisu';

  @override
  String get invoiceReviewNote =>
      'Portfel doliczy opłatę sieciową. Nic nie zostanie zapłacone, dopóki nie zatwierdzisz.';

  @override
  String get invoiceApprove => 'Zatwierdź i zapłać';

  @override
  String get invoiceDecline => 'Odrzuć';

  @override
  String get invoicePinReason => 'Wpisz PIN, aby zapłacić tę fakturę.';

  @override
  String get invoiceDeclineTitle => 'Odrzucić tę fakturę?';

  @override
  String invoiceDeclineBody(String service) {
    return 'Serwis $service dowie się, że odrzucasz fakturę. Nic nie zostanie zapłacone.';
  }

  @override
  String get invoiceDeclineKeep => 'Zostaw';

  @override
  String get invoiceDeclinedNotice => 'Faktura odrzucona.';

  @override
  String invoicePaidNotice(String service) {
    return 'Zapłacono. Serwis $service teraz kończy płatność.';
  }

  @override
  String invoiceReplyFailedTitle(String service) {
    return 'Płatność nie dotarła jeszcze do serwisu $service';
  }

  @override
  String get invoiceReplyFailedBody =>
      'Jest podpisana i zapisana na tym urządzeniu. „Ponów” wyśle ją jeszcze raz, bez ponownego zatwierdzania.';

  @override
  String get invoiceReplyFailedNotice =>
      'Płatność nie dotarła do serwisu. Dotknij „Ponów”, aby wysłać ją ponownie.';

  @override
  String get invoiceRetry => 'Ponów';

  @override
  String get invoiceDetailsSection => 'Faktura';

  @override
  String get invoiceDetailsService => 'Wystawca';

  @override
  String invoiceDetailsReplied(String service) {
    return 'Oczekiwanie, aż serwis $service opublikuje płatność.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return 'Serwis $service zgłasza, że płatność została opublikowana. Zakończy się, gdy sieć ją potwierdzi.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return 'Serwis $service nie otrzymał jeszcze Twojej płatności. „Ponów” wyśle ją jeszcze raz, bez ponownego zatwierdzania.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return 'Serwis $service wycofał tę fakturę po jej opłaceniu. Jeśli płatność nie zostanie potwierdzona, anuluj ją, aby odblokować środki.';
  }

  @override
  String get invoiceNoticeReceived => 'Faktura czeka na Twoje zatwierdzenie.';

  @override
  String get invoiceNoticePosted =>
      'Serwis zgłasza, że opublikował Twoją płatność.';

  @override
  String get invoiceNoticeWithdrawnPaid =>
      'Serwis wycofał fakturę, która jest już opłacona.';

  @override
  String get invoiceNoticeWithdrawn =>
      'Serwis wycofał fakturę przed Twoją odpowiedzią.';

  @override
  String get invoiceNoticeExpired => 'Faktura wygasła przed Twoją odpowiedzią.';

  @override
  String get receiveRequestTitle => 'Poproś o płatność';

  @override
  String get requestTitle => 'Poproś o płatność';

  @override
  String get requestStepsIntro =>
      'Portfel płacącego musi przyjmować faktury. Przed prośbą:';

  @override
  String get requestStepTrust =>
      '1. Płacący dodaje Twój adres poniżej do swoich zaufanych serwisów.';

  @override
  String get requestStepAddress => '2. Płacący podaje Ci swój adres do faktur.';

  @override
  String get requestYourAddress => 'Twój adres';

  @override
  String get requestPayerLabel => 'Adres do faktur płacącego';

  @override
  String get requestPayerMissing =>
      'Wklej lub zeskanuj adres do faktur płacącego.';

  @override
  String get requestPayerOwn =>
      'To jeden z Twoich własnych adresów. Wpisz adres do faktur, który poda Ci płacący.';

  @override
  String get requestMessageLabel => 'Wiadomość do płacącego (opcjonalnie)';

  @override
  String get requestMessageHelper =>
      'Płacący zobaczy tę wiadomość razem z prośbą.';

  @override
  String get requestButton => 'Poproś';

  @override
  String requestSentNotice(String payer) {
    return 'Wysłano prośbę do: $payer.';
  }

  @override
  String get invoicesToPaySection => 'Do zapłaty';

  @override
  String get invoicesNoneToPay => 'Nic do zapłaty.';

  @override
  String get invoicesSentSection => 'Wysłane prośby';

  @override
  String get issuedPaid => 'Zapłacona';

  @override
  String get issuedDeclined => 'Odrzucona';

  @override
  String get issuedWithdrawn => 'Wycofana';

  @override
  String get issuedExpired => 'Wygasła';

  @override
  String get issuedWithdraw => 'Wycofaj';

  @override
  String get issuedWithdrawTitle => 'Wycofać tę prośbę?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer nie będzie mógł już jej zapłacić. Tego nie można cofnąć.';
  }

  @override
  String get issuedWithdrawKeep => 'Zostaw';

  @override
  String get issuedDetailsSection => 'Prośba o płatność';

  @override
  String get issuedDetailsPayer => 'Prośba do';

  @override
  String get issuedDetailsWaiting =>
      'Czekamy na płacącego. Twój portfel zakończy płatność, gdy ona dotrze.';

  @override
  String get issuedDetailsPaid =>
      'Zapłacona. Twój portfel zakończył płatność; będzie gotowa, gdy sieć ją potwierdzi.';

  @override
  String get issuedDetailsDeclined =>
      'Płacący odrzucił tę prośbę, więc została wycofana. Nic nie zapłacono.';

  @override
  String get issuedDetailsWithdrawn =>
      'Ta prośba została przez Ciebie wycofana. Nic nie zapłacono.';

  @override
  String get issuedDetailsExpired =>
      'Ta prośba wygasła, zanim ją zapłacono. Nic nie zapłacono.';

  @override
  String get issuerNoticePaid => 'Jedna z Twoich próśb została zapłacona.';

  @override
  String get issuerNoticeDeclined => 'Jedna z Twoich próśb została odrzucona.';

  @override
  String get issuerNoticeWithdrawn =>
      'Prośba wycofana. Nie można jej już zapłacić.';

  @override
  String get issuerNoticeExpired => 'Jedna z Twoich próśb wygasła bez zapłaty.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Portfel $payer nie umie płacić próśb i odesłał Twoją, więc została wycofana. Poproś tę osobę, by zamiast tego wysłała Ci płatność na Twój adres lub jako plik płatności.';
  }

  @override
  String get issuedBounced => 'Odesłana';

  @override
  String get issuedDetailsBounced =>
      'Portfel płacącego nie umie płacić próśb i odesłał tę, więc została wycofana. Nic nie zapłacono. Poproś tę osobę, by zamiast tego wysłała Ci płatność na Twój adres lub jako plik płatności.';

  @override
  String get requestPayerNoInvoices =>
      'Ten portfel odesłał już prośbę: nie umie płacić próśb. Poproś tę osobę, by zamiast tego wysłała Ci płatność na Twój adres lub jako plik płatności.';

  @override
  String get txStatusWaitingPayer => 'Czeka na płacącego';

  @override
  String get txStepRequested => 'Wysłano prośbę';

  @override
  String get txStepPaid => 'Opłacono';

  @override
  String get txDetailsWaitingPayer =>
      'Poproszono o tę płatność. Nic jeszcze nie dotarło: płatność przyjdzie, gdy płacący opłaci prośbę.';

  @override
  String get txDetailsRequestEnded =>
      'Ta prośba zakończyła się bez płatności. Nic nie dotarło.';

  @override
  String get txDetailsRequestedFrom => 'Prośba do';

  @override
  String get txPaymentRequest => 'Wysłana prośba o płatność';

  @override
  String txSpokenRequesting(String amount) {
    return 'Prośba o $amount';
  }

  @override
  String txSpokenRequestingFrom(String amount, String who) {
    return 'Prośba o $amount, płacący: $who';
  }

  @override
  String get receiveEpicboxConnected => 'Połączono z epicbox';

  @override
  String get receiveQrLabel => 'Kod QR Twojego adresu';

  @override
  String get receiveAddressLabel => 'Adres Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'Płatności wysłane do Ciebie czekają teraz w epicbox i dotrą, gdy portfel znów się połączy.';

  @override
  String get receiveShareCardHeadline => 'Zapłać mi w Epic Cash';

  @override
  String get receiveHelpButton => 'Jak działa odbieranie';

  @override
  String get receiveAddressCopied => 'Skopiowano adres';

  @override
  String get receiveFileTitle => 'Odbierz przez plik płatności';

  @override
  String get receiveFileBody =>
      'Dostałeś plik płatności? Otwórz go albo skopiuj jego tekst i wklej tutaj.';

  @override
  String get receiveFileOpen => 'Otwórz plik';

  @override
  String get receivePasteEmpty =>
      'Najpierw skopiuj tekst płatności, a potem dotknij Wklej.';

  @override
  String get updateChecking => 'Sprawdzanie aktualizacji…';

  @override
  String get updateUpToDate => 'To najnowsza wersja.';

  @override
  String get updateNoInformation => 'Brak informacji o aktualizacjach.';

  @override
  String updateAvailable(String version) {
    return 'Dostępna jest wersja $version.';
  }

  @override
  String updateDownloading(String version, int percent) {
    return 'Pobieranie wersji $version… $percent%';
  }

  @override
  String updateInstalling(String version) {
    return 'Instalowanie wersji $version…';
  }

  @override
  String get updateFailed => 'Aktualizacja nie powiodła się.';

  @override
  String get updateInstallButton => 'Aktualizuj';

  @override
  String get updateTryAgain => 'Ponów';

  @override
  String get updateDownloadProgressLabel => 'Postęp pobierania';

  @override
  String get updateAllowInstalls =>
      'Zezwól na instalacje z Epic Cash Mobile, a potem wróć.';

  @override
  String updateNotInstalled(String detail) {
    return 'Aktualizacja nie została zainstalowana: $detail';
  }

  @override
  String updateCannotInstall(String detail) {
    return 'Nie można zainstalować aktualizacji: $detail.';
  }

  @override
  String get updateCannotInstallUnknown =>
      'Nie można zainstalować aktualizacji: nieznany błąd.';

  @override
  String get updateNeedsReinstall =>
      'Ta aktualizacja jest podpisana nowym kluczem, więc nie może zastąpić tej wersji. Potrzebna jest ponowna instalacja, a odinstalowanie usuwa ten portfel z urządzenia: najpierw zapisz swoją frazę odzyskiwania, potem odinstaluj tę aplikację i zainstaluj nową wersję.';

  @override
  String get updateManifestNotJson =>
      'Informacje o aktualizacji nie są poprawnym plikiem JSON.';

  @override
  String get updateManifestWrongShape =>
      'Informacje o aktualizacji mają nieprawidłową strukturę.';

  @override
  String get updateManifestOtherApp =>
      'Informacje o aktualizacji dotyczą innej aplikacji.';

  @override
  String get updateManifestNoApks =>
      'Informacje o aktualizacji nie zawierają żadnych plików APK.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'Pobieranie nie powiodło się (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge =>
      'Pobierany plik jest większy niż zapowiedziano.';

  @override
  String get updateDownloadIncomplete => 'Pobrany plik jest niekompletny.';

  @override
  String get updateDownloadDamaged =>
      'Pobrany plik jest uszkodzony (niezgodna suma kontrolna).';

  @override
  String get updateDownloadInterrupted => 'Pobieranie zostało przerwane.';

  @override
  String get updateServerUnreachable =>
      'Nie można połączyć się z serwerem aktualizacji.';

  @override
  String updateServerHttpStatus(int status) {
    return 'Serwer aktualizacji zwrócił HTTP $status.';
  }

  @override
  String get updateServerTimeout =>
      'Serwer aktualizacji nie odpowiedział na czas.';

  @override
  String get updateConnectionFailed =>
      'Połączenie z serwerem aktualizacji nie powiodło się.';

  @override
  String get updateCheckFailed => 'Sprawdzanie aktualizacji nie powiodło się.';

  @override
  String get setupTitle => 'Węzeł i Epicbox';

  @override
  String get setupNetworkSettingsTooltip => 'Węzeł i Epicbox';

  @override
  String get setupNetworkHeading => 'Sieć';

  @override
  String get setupNodeUrlLabel => 'Adres URL węzła';

  @override
  String get setupNodeUrlInvalid =>
      'Wpisz pełny adres URL, np. https://node.example.com';

  @override
  String get setupTestConnection => 'Sprawdź połączenie';

  @override
  String setupTestConnected(String height, String version) {
    return 'Połączono. Węzeł jest na bloku $height i działa w wersji $version.';
  }

  @override
  String setupTestFailed(String error) {
    return 'Nie udało się połączyć. $error';
  }

  @override
  String get setupConnectedIconLabel => 'Połączono';

  @override
  String get setupRelayHeading => 'Serwer epicbox';

  @override
  String get setupRelayHint => 'Ten serwer jest częścią Twojego adresu.';

  @override
  String get setupCustomRelayLabel =>
      'Inny serwer epicbox (host lub host:port)';

  @override
  String get setupCustomRelayUse => 'Użyj tego serwera';

  @override
  String get setupCustomRelayInvalid => 'Wpisz host, np. epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      'Zmiana serwera epicbox zmienia Twój adres. Przekaż nadawcom nowy adres. Płatności wysłane na stary adres czekają na starym serwerze, dopóki do niego nie wrócisz.';

  @override
  String get setupWalletPerNetwork =>
      'Każda sieć ma własny portfel. W sieci, która go nie ma, zostanie utworzony nowy.';

  @override
  String get setupRelayHealthyIconLabel => 'Działa';

  @override
  String get setupRelayDownIconLabel => 'Nie działa';

  @override
  String get setupRelayHealthUnavailable =>
      'Brak danych o stanie serwerów z status.btlabs.uk.';

  @override
  String get setupRelayHealthSource =>
      'Stan według status.btlabs.uk, mierzony z jego serwera.';

  @override
  String get setupRelayNotMonitored => 'Niemonitorowany';

  @override
  String get setupRelayUp => 'Działa';

  @override
  String get setupRelayDown => 'Nie działa';

  @override
  String get setupRelayOfficial => 'oficjalny';

  @override
  String setupRelayUptime(String percent) {
    return '$percent% dostępności w ostatniej dobie';
  }

  @override
  String get restoreTitle => 'Przywróć portfel';

  @override
  String get restorePhraseLabel => 'Fraza odzyskiwania';

  @override
  String get restorePhraseHelper =>
      'Wszystkie słowa (od 12 do 24) oddzielone spacjami.';

  @override
  String get restoreStartHeading => 'Początek skanowania';

  @override
  String get restoreStartByDate => 'Data';

  @override
  String get restoreStartByHeight => 'Wysokość bloku';

  @override
  String get restoreStartHeightLabel => 'Wysokość początkowa (opcjonalnie)';

  @override
  String get restoreStartHeightHelper =>
      'Skanuj od tego bloku. Zostaw puste, aby przeskanować cały łańcuch.';

  @override
  String get restoreStartHeightInvalid =>
      'Wysokość początkowa musi być liczbą całkowitą.';

  @override
  String get restoreBackToPhrase => 'Wróć do frazy';

  @override
  String get restoreDatePickerTitle => 'Kiedy utworzono portfel?';

  @override
  String get restorePickDate => 'Wybierz datę utworzenia portfela';

  @override
  String restoreFromDate(String date) {
    return 'Od $date';
  }

  @override
  String get restoreDateHint =>
      'Opcjonalnie. W razie wątpliwości wybierz wcześniejszą datę. Data późniejsza niż pierwsza płatność pominie część środków. Bez daty skanowany jest cały łańcuch, co trwa dłużej.';

  @override
  String restoreDateStart(String height) {
    return 'Skanowanie zacznie się dwa dni przed tą datą, od bloku $height.';
  }

  @override
  String get restoreWholeChain => 'Skanuj cały łańcuch';

  @override
  String get restoreScanIntro =>
      'Wyszukiwanie środków w łańcuchu bloków. Nie zamykaj aplikacji, dopóki się nie zakończy.';

  @override
  String get restoreOpenWallet => 'Otwórz portfel';

  @override
  String get restoreRescanLater =>
      'Pełne ponowne skanowanie możesz później uruchomić w Ustawieniach.';

  @override
  String get restoreDoneIconLabel => 'Gotowe';

  @override
  String get restoreDoneTitle => 'Portfel przywrócony';

  @override
  String get restoreImportExplanation =>
      'Łańcuch bloków przechowuje saldo, ale nie odbiorców płatności, opłaty ani notatki. Jeśli z tego portfela eksportowano kopię historii, zaimportuj ją teraz, aby je odzyskać. To plik .wfeh udostępniony lub zapisany poza starym telefonem.';

  @override
  String get restoreImportButton => 'Importuj kopię historii';

  @override
  String get restoreImportNotNow => 'Nie teraz';

  @override
  String get restoreImportLater =>
      'Możesz ją zaimportować później w Ustawieniach.';

  @override
  String get restoreScanProgressLabel => 'Postęp skanowania';

  @override
  String get firstRunTitle => 'Witaj';

  @override
  String get firstRunRestore => 'Mam już portfel: przywróć go';

  @override
  String get firstRunSecuring => 'Zabezpieczanie portfela…';

  @override
  String get firstRunTryAgain => 'Spróbuj ponownie';

  @override
  String get firstRunBiometricsNotSetUp =>
      'Nie skonfigurowano odblokowania biometrycznego. Możesz je włączyć w Ustawieniach.';

  @override
  String get backupTitle => 'Fraza odzyskiwania';

  @override
  String get backupPinReason => 'Wpisz PIN, aby wyświetlić frazę odzyskiwania.';

  @override
  String get backupCopyWarning =>
      'Zrzut lub zdjęcie frazy to pełna kopia portfela: każdy, kto je zobaczy, może zabrać twoje środki, a aplikacje ze zdjęciami mogą wysłać je do chmury. Papier jest najbezpieczniejszy.';

  @override
  String get backupCopyAgree => 'Każdą kopię frazy zachowam tylko dla siebie';

  @override
  String get backupShowPhrase => 'Pokaż frazę odzyskiwania';

  @override
  String get backupWarningIconLabel => 'Ostrzeżenie';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Zapisz te $count słowa na papierze w podanej kolejności i nikomu ich nie pokazuj. Tylko za ich pomocą można przywrócić ten portfel.',
      many:
          'Zapisz te $count słów na papierze w podanej kolejności i nikomu ich nie pokazuj. Tylko za ich pomocą można przywrócić ten portfel.',
      few:
          'Zapisz te $count słowa na papierze w podanej kolejności i nikomu ich nie pokazuj. Tylko za ich pomocą można przywrócić ten portfel.',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return 'Słowo $number: $word';
  }

  @override
  String get unlockTitle => 'Odblokuj portfel';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinRepeatLabel => 'Powtórz PIN';

  @override
  String pinChooseTitle(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Wybierz $digits-cyfrowy PIN',
      many: 'Wybierz $digits-cyfrowy PIN',
      few: 'Wybierz $digits-cyfrowy PIN',
    );
    return '$_temp0';
  }

  @override
  String get pinConfirmTitle => 'Wpisz PIN ponownie';

  @override
  String get pinChooseDifferent => 'Wybierz inny PIN';

  @override
  String get pinMismatch => 'Kody PIN nie są zgodne. Wybierz PIN ponownie.';

  @override
  String get pinBiometricsIconLabel => 'Biometria';

  @override
  String get pinBiometricsQuestion =>
      'Odblokowywać odciskiem palca lub twarzą?';

  @override
  String get pinBiometricsPinStillWorks =>
      'Kodu PIN możesz nadal używać w każdej chwili.';

  @override
  String get pinBiometricsEnable => 'Użyj biometrii';

  @override
  String get pinBiometricsNotNow => 'Nie teraz';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nieprawidłowy PIN. Pozostało $count próby do czasowej blokady.',
      many: 'Nieprawidłowy PIN. Pozostało $count prób do czasowej blokady.',
      few: 'Nieprawidłowy PIN. Pozostały $count próby do czasowej blokady.',
      one: 'Nieprawidłowy PIN. Pozostała $count próba do czasowej blokady.',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count sekundy.',
      many:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count sekundach.',
      few:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count sekundach.',
      one:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count sekundzie.',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count minuty.',
      many:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count minutach.',
      few:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count minutach.',
      one:
          'Nieprawidłowy PIN. Następna próba zostanie sprawdzona po $count minucie.',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprawdzanie PIN-u za $count sekundy…',
      many: 'Sprawdzanie PIN-u za $count sekund…',
      few: 'Sprawdzanie PIN-u za $count sekundy…',
      one: 'Sprawdzanie PIN-u za $count sekundę…',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprawdzanie PIN-u za $count minuty…',
      many: 'Sprawdzanie PIN-u za $count minut…',
      few: 'Sprawdzanie PIN-u za $count minuty…',
      one: 'Sprawdzanie PIN-u za $count minutę…',
    );
    return '$_temp0';
  }

  @override
  String get pinChecking => 'Sprawdzanie PIN-u…';

  @override
  String get pinPromptTitle => 'Wpisz PIN';

  @override
  String get pinUseBiometrics => 'Użyj biometrii';

  @override
  String get pinForgot => 'Nie pamiętasz kodu PIN?';

  @override
  String get pinResetTitle => 'Zapomniany PIN';

  @override
  String get pinResetBody =>
      'Kodu PIN nie da się odzyskać. Możesz usunąć ten portfel z urządzenia i przywrócić go z frazy odzyskiwania. Bez frazy środki zostaną utracone na zawsze.';

  @override
  String get pinResetConfirm => 'Mam swoją frazę odzyskiwania';

  @override
  String get pinResetKeep => 'Zachowaj portfel';

  @override
  String get pinResetDelete => 'Usuń portfel';

  @override
  String get launchTryAgain => 'Spróbuj ponownie';

  @override
  String get unlockStranded =>
      'Nie udało się poprawnie odczytać tego portfela. Nic nie zostało usunięte. Spróbuj ponownie po ponownym uruchomieniu urządzenia. Jeśli to nie pomoże, możesz usunąć portfel przez „Nie pamiętasz kodu PIN?” i przywrócić go z frazy odzyskiwania.';

  @override
  String get sendAmountNegative => 'Kwota nie może być ujemna.';

  @override
  String sendAmountAmbiguous(String asWhole, String asDecimal) {
    return 'Wpisz $asWhole lub $asDecimal, aby kwota była jednoznaczna.';
  }

  @override
  String get sendAmountUnclear =>
      'Wpisz kwotę bez separatorów, np. 1234,5, aby była jednoznaczna.';

  @override
  String get sendAmountNoPrice => 'Brak aktualnego kursu. Wpisz kwotę w EPIC.';

  @override
  String get sendAmountEnterFiatExample => 'Wpisz kwotę, np. 10,50';

  @override
  String get sendAmountTooLarge =>
      'To więcej EPIC, niż kiedykolwiek będzie istnieć. Sprawdź kwotę.';

  @override
  String get sendAmountZero => 'Wpisz kwotę większą od zera.';

  @override
  String get sendUrlUnsupported =>
      'Płatności na URL portfela nie są obsługiwane. Poproś odbiorcę o jego adres epicbox.';

  @override
  String get scanQrTooltip => 'Zeskanuj kod QR';

  @override
  String get sendScanButton => 'Skanuj';

  @override
  String get sendChooseContactTooltip => 'Wybierz kontakt';

  @override
  String get sendContactsButton => 'Kontakty';

  @override
  String get sendMethodEpicbox => 'Adres epicbox';

  @override
  String get sendMethodFile => 'Plik płatności';

  @override
  String get sendFileHelpTooltip => 'Jak działa płatność plikiem';

  @override
  String sendAmountLabel(String unit) {
    return 'Kwota ($unit)';
  }

  @override
  String sendUseUnit(String unit) {
    return 'Użyj $unit';
  }

  @override
  String get sendMax => 'Maks.';

  @override
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String get sendCopyPasteInstead => 'Albo skopiuj i wklej';

  @override
  String get sendSlateBoxTitle => 'Tekst transakcji';

  @override
  String get sendPasteResponseLabel => 'Wklej odpowiedź odbiorcy';

  @override
  String get sendPasteResponseMissing => 'Wklej tekst odpowiedzi od odbiorcy.';

  @override
  String get slateFinishPayment => 'Sfinalizuj płatność';

  @override
  String sendResultAutoCancel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Jeśli po $days dnia płatność nadal nie będzie zakończona, anuluje się sama, a kwota zostanie odblokowana. Aby zatrzymać ją wcześniej, otwórz płatność i dotknij „Anuluj płatność”.',
      many:
          'Jeśli po $days dniach płatność nadal nie będzie zakończona, anuluje się sama, a kwota zostanie odblokowana. Aby zatrzymać ją wcześniej, otwórz płatność i dotknij „Anuluj płatność”.',
      few:
          'Jeśli po $days dniach płatność nadal nie będzie zakończona, anuluje się sama, a kwota zostanie odblokowana. Aby zatrzymać ją wcześniej, otwórz płatność i dotknij „Anuluj płatność”.',
      one:
          'Jeśli po $days dniu płatność nadal nie będzie zakończona, anuluje się sama, a kwota zostanie odblokowana. Aby zatrzymać ją wcześniej, otwórz płatność i dotknij „Anuluj płatność”.',
    );
    return '$_temp0';
  }

  @override
  String sendResultFeeChanged(String charged, String reviewed) {
    return 'Pobrano opłatę $charged zamiast wcześniej pokazanej $reviewed, ponieważ przy wysyłce portfel ponownie dobrał monety.';
  }

  @override
  String get sendResultNoteNotSaved =>
      'Nie udało się zapisać notatki. Możesz ją dodać, otwierając płatność.';

  @override
  String get sendHelp => 'Pomoc';

  @override
  String get sendReviewTotal => 'Razem';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
  }

  @override
  String sendReviewSendButton(String amount) {
    return 'Wyślij $amount';
  }

  @override
  String get sendReviewEdit => 'Edytuj';

  @override
  String get slateFileTitle => 'Plik transakcji';

  @override
  String get slateWrongPayment =>
      'Ta odpowiedź dotyczy innej płatności. Otwórz plik, który odbiorca odesłał dla tej wysyłki.';

  @override
  String get slateInvoiceUnsupported =>
      'Żądania płatności (faktury) nie są jeszcze obsługiwane.';

  @override
  String get slateNotTransactionFile => 'To nie jest plik transakcji.';

  @override
  String get slateReading => 'Odczytywanie pliku';

  @override
  String get slateFileTooLarge =>
      'Ten plik jest za duży, aby mógł być plikiem transakcji.';

  @override
  String slatePostedHeadline(String amount) {
    return 'Płatność na kwotę $amount wysłana do sieci.';
  }

  @override
  String slatePostedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Otrzyma status „Zakończona” po $count potwierdzenia.',
      many: 'Otrzyma status „Zakończona” po $count potwierdzeniach.',
      few: 'Otrzyma status „Zakończona” po $count potwierdzeniach.',
      one: 'Otrzyma status „Zakończona” po $count potwierdzeniu.',
    );
    return '$_temp0';
  }

  @override
  String slateAcceptedHeadline(String file) {
    return 'Przyjęto. Odeślij $file nadawcy.';
  }

  @override
  String slateAcceptedBody(String amount) {
    return 'Kwota $amount dotrze, gdy nadawca sfinalizuje płatność i trafi ona do łańcucha.';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return 'Już przyjęto. Odeślij $file nadawcy ponownie.';
  }

  @override
  String slateRepeatedBody(String amount) {
    return 'Ta płatność została już przyjęta, więc to ta sama odpowiedź, a nie druga płatność. Kwota $amount dotrze, gdy nadawca ją sfinalizuje i trafi ona do łańcucha.';
  }

  @override
  String slateIncomingSend(String amount) {
    return 'Ktoś wysyła Ci $amount.';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'Odpowiedź odbiorcy dotycząca Twojej płatności: $amount (opłata $fee).';
  }

  @override
  String get slateIncomingSendHint =>
      'Przyjmij ją, a potem odeślij plik odpowiedzi nadawcy.';

  @override
  String get slateIncomingResponseHint =>
      'Sfinalizuj ją, aby wysłać płatność do sieci.';

  @override
  String get slateAcceptPayment => 'Przyjmij płatność';

  @override
  String slateHandOverFailed(String file) {
    return 'Nie udało się przekazać pliku $file. Spróbuj ponownie.';
  }

  @override
  String get slateSaveToDevice => 'Zapisz na urządzeniu';

  @override
  String slateSaved(String file) {
    return 'Zapisano $file';
  }

  @override
  String get slateSaveDialogTitle => 'Zapisz plik transakcji';

  @override
  String get slateOpenDialogTitle => 'Otwórz plik transakcji';

  @override
  String get slateNotPostedTitle => 'Jeszcze nie w sieci';

  @override
  String get slateNotPostedBody =>
      'Płatność jest sfinalizowana, ale sieć jeszcze jej nie przyjęła. Zostanie ponownie rozgłoszona z poziomu płatności. Nie wysyłaj jej ponownie.';

  @override
  String get slateOpenPayment => 'Otwórz płatność';

  @override
  String get scanQrTitle => 'Zeskanuj kod QR';

  @override
  String get scanQrHint => 'Skieruj aparat na kod QR odbiorcy.';

  @override
  String get scanQrCameraDenied =>
      'Portfel nie ma dostępu do aparatu. Aby skanować, zezwól tej aplikacji na dostęp do aparatu w ustawieniach telefonu. Możesz też wkleić adres.';

  @override
  String get scanQrCameraFailed =>
      'Nie udało się uruchomić aparatu. Wklej adres albo spróbuj ponownie.';

  @override
  String get scanQrTryAgain => 'Spróbuj ponownie';

  @override
  String get scanQrBack => 'Wstecz';

  @override
  String get contactsTitle => 'Kontakty';

  @override
  String get contactsPickTitle => 'Wybierz kontakt';

  @override
  String get contactsAdd => 'Dodaj kontakt';

  @override
  String get contactsEmpty =>
      'Brak kontaktów. Dodaj osoby, którym często płacisz, aby nie wklejać ich adresu za każdym razem.';

  @override
  String get contactsSearchLabel => 'Szukaj w kontaktach';

  @override
  String get contactsNoMatch => 'Brak pasujących kontaktów.';

  @override
  String get contactsNameMissing => 'Wpisz nazwę.';

  @override
  String contactsDeleteTitle(String name) {
    return 'Usunąć kontakt $name?';
  }

  @override
  String get contactsDeleteBody =>
      'Adres zostanie usunięty z kontaktów. Nie wpłynie to na wcześniejsze płatności.';

  @override
  String get contactsKeep => 'Zachowaj';

  @override
  String get contactsEditTitle => 'Edytuj kontakt';

  @override
  String get contactsNewTitle => 'Nowy kontakt';

  @override
  String get contactsDeleteTooltip => 'Usuń kontakt';

  @override
  String get contactsNameLabel => 'Nazwa';

  @override
  String get contactsAddressLabel => 'Adres';

  @override
  String contactsDuplicate(String name) {
    return 'Ten adres jest już zapisany jako $name.';
  }

  @override
  String get contactsNoteLabel => 'Notatka (opcjonalnie)';

  @override
  String get contactsSave => 'Zapisz kontakt';

  @override
  String get contactsAddressMissing => 'Wpisz adres.';

  @override
  String contactsUrlIncomplete(String example) {
    return 'Wpisz pełny URL portfela, np. $example';
  }

  @override
  String contactsAddressInvalid(String example) {
    return 'To nie jest prawidłowy adres. Prawidłowy wygląda tak: $example';
  }

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsSectionNetwork => 'Serwery';

  @override
  String get settingsNetworkAndNode => 'Węzeł i Epicbox';

  @override
  String settingsNetworkSubtitle(String network, String node) {
    return '$network · $node';
  }

  @override
  String get settingsSectionDisplay => 'Wyświetlanie';

  @override
  String get settingsCurrency => 'Waluta';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Pokazuj ceny';

  @override
  String get settingsHideBalances => 'Ukrywaj salda';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get settingsThemeSystem => 'Jak w urządzeniu';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsPricesOnNotice =>
      'Ceny pochodzą z serwisu CoinGecko, który widzi Twój adres IP.';

  @override
  String get settingsSectionNotifications => 'Powiadomienia';

  @override
  String get settingsPushBlocked =>
      'Powiadomienia są zablokowane w ustawieniach systemu';

  @override
  String get settingsPushUnavailable =>
      'Powiadomienia nie są dostępne w tej wersji aplikacji';

  @override
  String get settingsSectionSecurity => 'Bezpieczeństwo';

  @override
  String get settingsChangePin => 'Zmień PIN';

  @override
  String get settingsBiometrics => 'Odblokowanie biometryczne';

  @override
  String get settingsBiometricsOn => 'Włączono odblokowanie biometryczne';

  @override
  String get settingsBiometricsOff => 'Wyłączono odblokowanie biometryczne';

  @override
  String get settingsBiometricsFailed =>
      'Nie skonfigurowano odblokowania biometrycznego';

  @override
  String get settingsBiometricsPinReason =>
      'Wpisz PIN, aby włączyć odblokowanie biometryczne.';

  @override
  String get settingsAutoLock => 'Automatyczna blokada';

  @override
  String get settingsBackupPhrase => 'Zabezpiecz frazę odzyskiwania';

  @override
  String get settingsPhraseConfirmed => 'Fraza odzyskiwania potwierdzona';

  @override
  String get settingsLockWallet => 'Zablokuj portfel';

  @override
  String get settingsSectionHistory => 'Historia płatności';

  @override
  String get settingsExportHistory => 'Eksportuj kopię historii';

  @override
  String get settingsExportCsv => 'Eksportuj CSV';

  @override
  String get settingsImportHistory => 'Importuj kopię historii';

  @override
  String get settingsSectionWallet => 'Portfel';

  @override
  String get settingsContacts => 'Kontakty';

  @override
  String get settingsSectionInvoices => 'Faktury';

  @override
  String get settingsInvoices => 'Adres do faktur i zaufane serwisy';

  @override
  String get settingsInvoicesSubtitle =>
      'Zaufane serwisy mogą wystawiać Ci faktury. Każdą zatwierdzasz sam.';

  @override
  String get invoiceSettingsTitle => 'Faktury';

  @override
  String get invoiceSettingsAddressTitle => 'Twój adres do faktur';

  @override
  String get invoiceSettingsAddressBody =>
      'Podaj ten adres serwisowi, któremu ufasz, aby mógł wysyłać Ci faktury. Twój adres do płatności się nie zmienia.';

  @override
  String get invoiceSettingsQrLabel => 'Kod QR Twojego adresu do faktur';

  @override
  String get invoiceSettingsAddressCopied => 'Skopiowano adres do faktur.';

  @override
  String get invoiceSettingsServicesTitle => 'Zaufane serwisy';

  @override
  String get invoiceSettingsNoServices =>
      'Brak zaufanych serwisów. Faktury od innych nigdy do Ciebie nie dotrą.';

  @override
  String get invoiceSettingsAddService => 'Dodaj serwis';

  @override
  String invoiceSettingsRemoveTooltip(String name) {
    return 'Usuń $name';
  }

  @override
  String invoiceSettingsRemoveTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String get invoiceSettingsRemoveBody =>
      'Ten serwis nie będzie mógł już wysyłać Ci faktur. Dokonane płatności pozostają bez zmian.';

  @override
  String get invoiceSettingsKeep => 'Zostaw';

  @override
  String get invoiceSettingsRemoveConfirm => 'Usuń';

  @override
  String invoiceSettingsRemoved(String name) {
    return '$name nie może już wysyłać Ci faktur.';
  }

  @override
  String get invoiceSettingsRotate => 'Utwórz nowy adres do faktur';

  @override
  String get invoiceSettingsRotateHint => 'Obecny przestanie działać.';

  @override
  String get invoiceSettingsRotateTitle => 'Utworzyć nowy adres do faktur?';

  @override
  String get invoiceSettingsRotateBody =>
      'Obecny adres do faktur przestanie działać na zawsze. Każdy serwis, który wystawia Ci faktury, potrzebuje nowego.';

  @override
  String get invoiceSettingsRotateConfirm => 'Nowy adres';

  @override
  String get invoiceSettingsRotated =>
      'Nowy adres do faktur gotowy. Przekaż go swoim serwisom.';

  @override
  String invoiceSettingsDropped(int count) {
    return 'Odrzucone w tej sesji (nieznani nadawcy): $count';
  }

  @override
  String get invoiceSettingsAddTitle => 'Dodaj zaufany serwis';

  @override
  String get invoiceSettingsAddExplanation =>
      'Zaufany serwis może wysyłać faktury na Twój adres do faktur; wiadomości od innych są odrzucane. Nic nie zostanie zapłacone, dopóki nie zatwierdzisz każdej faktury PIN-em lub odciskiem palca.';

  @override
  String get invoiceSettingsLabelLabel => 'Nazwa';

  @override
  String get invoiceSettingsLabelMissing => 'Nadaj serwisowi nazwę.';

  @override
  String get invoiceSettingsServiceAddressLabel => 'Adres epicbox serwisu';

  @override
  String get invoiceSettingsAddressMissing =>
      'Wklej lub zeskanuj adres, który pokazuje serwis.';

  @override
  String get invoiceSettingsAddButton => 'Dodaj serwis';

  @override
  String invoiceSettingsAdded(String name) {
    return '$name może teraz wysyłać Ci faktury.';
  }

  @override
  String get settingsRescan => 'Skanuj łańcuch ponownie';

  @override
  String get settingsRescanFinished => 'Ponowne skanowanie zakończone';

  @override
  String get settingsRescanTitle => 'Skanuj łańcuch ponownie';

  @override
  String get settingsRescanBody =>
      'Portfel ponownie wyszuka swoje środki. Wcześniejszy początek znajdzie więcej, ale potrwa dłużej; skanowanie całego łańcucha może zająć dużo czasu.';

  @override
  String get settingsRescanFromDate => 'Od daty';

  @override
  String get settingsRescanFromHeight => 'Od wysokości bloku';

  @override
  String get settingsRescanWholeChain => 'Cały łańcuch';

  @override
  String get settingsRescanPickDate => 'Wybierz datę';

  @override
  String get settingsRescanPickDateFirst => 'Najpierw wybierz datę.';

  @override
  String get settingsRescanStartHeight => 'Wysokość początkowa';

  @override
  String get settingsRescanHeightInvalid =>
      'Wpisz wysokość bloku równą 1 lub większą.';

  @override
  String get settingsRescanButton => 'Skanuj';

  @override
  String get settingsDeleteWallet => 'Usuń ten portfel';

  @override
  String get settingsDeleteDuringScan =>
      'Przed usunięciem portfela poczekaj na zakończenie skanowania.';

  @override
  String get settingsDeletePinReason => 'Wpisz PIN, aby usunąć ten portfel.';

  @override
  String get settingsDeleteWarningIcon => 'Ostrzeżenie';

  @override
  String get settingsDeleteTitle => 'Usunąć ten portfel?';

  @override
  String get settingsDeleteBody =>
      'Portfel, jego historia i PIN zostaną usunięte z tego urządzenia. Tylko fraza odzyskiwania pozwoli odzyskać środki. Bez niej zostaną utracone na zawsze.';

  @override
  String get settingsDeleteHavePhrase => 'Mam zapisaną frazę odzyskiwania';

  @override
  String get settingsDeleteConfirmWord => 'skasuj';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return 'Wpisz „$word”';
  }

  @override
  String get settingsDeleteKeep => 'Zachowaj portfel';

  @override
  String get settingsDeleteConfirm => 'Usuń portfel';

  @override
  String get settingsSectionAbout => 'O aplikacji';

  @override
  String get settingsVersion => 'Wersja';

  @override
  String get settingsAboutNetwork => 'Sieć';

  @override
  String get settingsEpicboxServer => 'Serwer epicbox';

  @override
  String settingsUpdateTo(String version) {
    return 'Zaktualizuj do $version';
  }

  @override
  String get settingsUpdateInstall => 'Zainstaluj';

  @override
  String get settingsCheckUpdates => 'Sprawdź aktualizacje';

  @override
  String get settingsHelp => 'Pomoc';

  @override
  String get settingsSendFeedback => 'Wyślij opinię';

  @override
  String get settingsSendFeedbackHint => 'Zgłoś problem lub zaproponuj pomysł';

  @override
  String get settingsSourceCode => 'Kod źródłowy';

  @override
  String get settingsLicences => 'Licencje';

  @override
  String get licencesLead =>
      'Oprogramowanie open source w tym portfelu. Każdy składnik zachowuje własną licencję; pełne teksty są o jedno dotknięcie dalej.';

  @override
  String get licencesApp =>
      'Epic Cash Mobile od BT Labs: Apache-2.0. Kod jest na GitHubie.';

  @override
  String get licencesFlutter =>
      'Flutter i jego pakiety Dart: BSD 3-Clause i podobne liberalne licencje.';

  @override
  String get licencesLepic =>
      'LEPIC, biblioteka portfela Epic Cash: Apache 2.0, z forkiem secp256k1-zkp Epic Cash (CC0) i skrzynkami Rust na licencjach MIT lub Apache 2.0, m.in. tokio, rustls, rusqlite i blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, wersja 3. Źródło podano poniżej.';

  @override
  String get licencesFonts =>
      'Czcionki Montserrat, JetBrains Mono i Noto Sans Thai: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'Wszystkie teksty licencji';

  @override
  String get settingsCopyLink => 'Kopiuj link';

  @override
  String get settingsLinkCopied => 'Skopiowano link';

  @override
  String get settingsPinTitle => 'Zmień PIN';

  @override
  String get settingsPinEnterCurrent => 'Wpisz obecny PIN';

  @override
  String get settingsPinCurrentLabel => 'Obecny PIN';

  @override
  String settingsPinChooseNew(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Wybierz nowy $digits-cyfrowy PIN',
      many: 'Wybierz nowy $digits-cyfrowy PIN',
      few: 'Wybierz nowy $digits-cyfrowy PIN',
    );
    return '$_temp0';
  }

  @override
  String get settingsPinChanged => 'Zmieniono PIN';

  @override
  String get settingsPinChangedBiometricsOff =>
      'Zmieniono PIN. Odblokowanie biometryczne jest wyłączone; włącz je ponownie poniżej.';

  @override
  String get helpTitle => 'Pomoc';

  @override
  String get helpStillStuck => 'Nadal masz problem?';

  @override
  String get helpTellUs => 'Opisz, co się stało lub co jest niejasne.';

  @override
  String get helpSendFeedback => 'Wyślij opinię';

  @override
  String get feedbackTitle => 'Wyślij opinię';

  @override
  String get feedbackIntro => 'Opisz, co poszło nie tak lub co można poprawić.';

  @override
  String get feedbackMessageLabel => 'Twoja wiadomość';

  @override
  String get feedbackMessageMissing => 'Napisz kilka słów o tym, co się stało.';

  @override
  String get feedbackEmailLabel => 'E-mail do odpowiedzi (opcjonalnie)';

  @override
  String get feedbackEmailInvalid => 'To nie wygląda na adres e-mail.';

  @override
  String get feedbackAttachLogs => 'Dołącz dzienniki diagnostyczne';

  @override
  String get feedbackAttachLogsHint =>
      'Logi pomagają znaleźć problem. Fraza odzyskiwania, PIN i inne poufne dane są wcześniej usuwane.';

  @override
  String get feedbackPreviewButton => 'Podgląd wysyłanych danych';

  @override
  String get feedbackSend => 'Wyślij';

  @override
  String get feedbackShareOrSaveInstead => 'Zamiast tego udostępnij lub zapisz';

  @override
  String get feedbackFileExplanation =>
      'Opinia zostanie zapisana jako plik tekstowy, który możesz wysłać e-mailem lub w komunikatorze albo zachować.';

  @override
  String get feedbackShareOrSave => 'Udostępnij lub zapisz';

  @override
  String get feedbackShareHint => 'Wyślij e-mailem lub w komunikatorze';

  @override
  String get feedbackSaveToDevice => 'Zapisz na urządzeniu';

  @override
  String get feedbackSaveDialogTitle => 'Zapisz opinię';

  @override
  String feedbackSavedFile(String name) {
    return 'Zapisano $name';
  }

  @override
  String get feedbackSent => 'Dziękujemy. Opinia została wysłana.';

  @override
  String get feedbackThanks => 'Dziękujemy za opinię.';

  @override
  String feedbackServerAnswered(int status) {
    return 'Serwer opinii odpowiedział kodem $status.';
  }

  @override
  String get feedbackServerNoAnswer => 'Serwer opinii nie odpowiedział.';

  @override
  String get feedbackServerUnreachable =>
      'Nie można połączyć się z serwerem opinii.';

  @override
  String get feedbackPreviewTitle => 'Co zostanie wysłane';

  @override
  String get settingsAdvancedOptions => 'Opcje zaawansowane';

  @override
  String get settingsAdvancedOptionsSubtitle =>
      'Szczegóły techniczne, pliki i dzienniki';

  @override
  String get settingsSectionPrivacy => 'Prywatność';

  @override
  String get settingsSectionPrivacyNetwork => 'Prywatność i sieć';

  @override
  String get settingsSectionHelpFeedback => 'Pomoc i opinie';

  @override
  String get settingsStateBackUp => 'Zapisz frazę odzyskiwania';

  @override
  String get settingsStateNotBackedUp => 'Jeszcze nie zapisano';

  @override
  String get settingsStatePin => 'PIN';

  @override
  String get settingsStatePinBiometrics => 'PIN i biometria';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'Używaj status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Stan sieci i informacje dostarczane przez status.btlabs.uk';

  @override
  String get txStepStarted => 'Rozpoczęto płatność';

  @override
  String get txStepAccepted => 'Odbiorca przyjął';

  @override
  String get txStepPosted => 'Wysłano do sieci';

  @override
  String get txStepConfirming => 'Potwierdzanie';

  @override
  String get txStepConfirmed => 'Potwierdzona';

  @override
  String get txStepArrived => 'Płatność dotarła';

  @override
  String get txStepSenderFinished => 'Nadawca ją zakończył';

  @override
  String get fileHelpTitle => 'Jak działa plik płatności';

  @override
  String get fileHelpYou => 'Ty';

  @override
  String get fileHelpFriend => 'Znajomy';

  @override
  String get fileHelpSendStep1 => 'Tworzysz plik płatności.';

  @override
  String get fileHelpSendStep2 =>
      'Wysyłasz go znajomemu w dowolny sposób, na przykład czatem lub e-mailem.';

  @override
  String get fileHelpSendStep3 =>
      'Znajomy otwiera go w swoim portfelu i odsyła ci podpisaną odpowiedź.';

  @override
  String get fileHelpSendStep4 =>
      'Otwierasz odpowiedź i płatność jest w drodze.';

  @override
  String get fileHelpReceiveStep1 =>
      'Znajomy tworzy dla ciebie plik płatności.';

  @override
  String get fileHelpReceiveStep2 =>
      'Wysyła ci go w dowolny sposób, na przykład czatem lub e-mailem.';

  @override
  String get fileHelpReceiveStep3 =>
      'Otwierasz go w swoim portfelu i odsyłasz podpisaną odpowiedź.';

  @override
  String get fileHelpReceiveStep4 =>
      'Znajomy otwiera odpowiedź i płatność jest w drodze do ciebie.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Krok $step z $count';
  }

  @override
  String get fileHelpPause => 'Wstrzymaj animację';

  @override
  String get fileHelpPlay => 'Odtwórz animację';

  @override
  String get demoPinFilled => 'PIN demo, wpisany za ciebie';

  @override
  String get demoPinSkip => 'Pomiń';

  @override
  String get demoPinSetUpTitle => 'Przygotowujemy twój portfel demo';

  @override
  String get demoPinUnlockTitle => 'Otwieramy twój portfel demo';

  @override
  String get sendStepRecipient => 'Odbiorca';

  @override
  String get sendStepAmount => 'Kwota';

  @override
  String get sendStepReview => 'Sprawdź';

  @override
  String sendStepOf(int step, int total) {
    return '$step z $total';
  }

  @override
  String get sendHowItWorks => 'Jak to działa';

  @override
  String get sendAddressLabel => 'Adres Epic';

  @override
  String get sendAddressMissing => 'Wpisz adres odbiorcy.';

  @override
  String get sendAddressWebLink => 'To link internetowy, a nie adres Epic.';

  @override
  String get sendAddressIncomplete => 'Ten adres wygląda na niepełny.';

  @override
  String get sendAddressNotEpic => 'To nie jest adres Epicbox.';

  @override
  String get sendNewRecipient => 'Nowy odbiorca';

  @override
  String get sendSaveContact => 'Zapisz jako kontakt';

  @override
  String get sendRecent => 'Ostatnio';

  @override
  String get sendUseFile => 'Brak adresu? Użyj pliku płatności';

  @override
  String sendTo(String who) {
    return 'Do $who';
  }

  @override
  String sendAvailable(String amount) {
    return 'Dostępne $amount';
  }

  @override
  String sendFeeQuiet(String fee) {
    return 'Opłata sieciowa $fee';
  }

  @override
  String get sendAddNote => 'Dodaj notatkę';

  @override
  String get sendNoteLabel => 'Notatka';

  @override
  String get sendNoteHelper => 'Odbiorca też ją zobaczy.';

  @override
  String get sendNetworkFee => 'Opłata sieciowa';

  @override
  String get sendChecking => 'Sprawdzanie…';

  @override
  String get sendReady => 'Gotowe do wysłania';

  @override
  String get sendNodeDown => 'Brak połączenia z siecią.';

  @override
  String get sendRelayDown => 'Ich przekaźnik nie odpowiada.';

  @override
  String get sendListenerDown => 'Jeszcze bez połączenia. Możesz już wysłać.';

  @override
  String get sendPayWithFile => 'Zapłać plikiem';

  @override
  String get sendAnyway => 'Wyślij mimo to';

  @override
  String sendTrackSentTo(String name) {
    return 'Wysłano do: $name';
  }

  @override
  String get sendTrackSent => 'Wysłano';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Czekamy na portfel: $name';
  }

  @override
  String get sendTrackWaiting => 'Czekamy na portfel odbiorcy';

  @override
  String sendTrackSignedBy(String name) {
    return 'Portfel $name podpisał';
  }

  @override
  String get sendTrackSigned => 'Portfel odbiorcy podpisał';

  @override
  String get sendTrackOnNetwork => 'Wysłano do sieci';

  @override
  String get sendTrackConfirmed => 'Potwierdzono';

  @override
  String sendTrackOffline(String amount) {
    return 'Portfel odbiorcy dokończy ją po otwarciu. Do tego czasu $amount jest wstrzymane.';
  }

  @override
  String get sendTrackIfNot => 'A jeśli się nie zakończy?';

  @override
  String get sendTrackCancelled => 'Ta płatność została anulowana.';

  @override
  String get sendNoCoins => 'Nie masz jeszcze monet do wysłania.';

  @override
  String get sendFileTitle => 'Płatność plikiem';

  @override
  String get sendMakeFile => 'Utwórz plik płatności';

  @override
  String get sendFileMade => 'Plik utworzony';

  @override
  String sendFileOnHold(String amount) {
    return '$amount wstrzymane';
  }

  @override
  String get sendFileWaitingReply => 'Czekamy na odpowiedź';

  @override
  String get sendFileShareHint =>
      'Wyślij im ten plik. Potem otwórz ich odpowiedź.';

  @override
  String get sendOpenReply => 'Otwórz odpowiedź';

  @override
  String get handshakePayment => 'Płatność';

  @override
  String get handshakeRequest => 'Prośba';

  @override
  String get handshakeYou => 'Ty';

  @override
  String get handshakeThem => 'Oni';

  @override
  String get handshakeNetwork => 'Sieć';

  @override
  String get handshakePay1 =>
      'Twój portfel wysyła płatność do przekaźnika. Twoje monety są wstrzymane.';

  @override
  String get handshakePay2 =>
      'Przekaźnik przekazuje ją dalej. Ich portfel dodaje swoją część i podpisuje.';

  @override
  String get handshakeFinish => 'Twój portfel kończy ją i wysyła do sieci.';

  @override
  String get handshakeConfirm => 'Sieć ją potwierdza.';

  @override
  String get handshakeReq1 => 'Twój portfel wysyła prośbę do przekaźnika.';

  @override
  String get handshakeReq2 =>
      'Przekaźnik przekazuje ją dalej. Oni ją akceptują, a ich portfel dodaje monety i podpisuje.';

  @override
  String get handshakeRelay => 'Przekaźnik';

  @override
  String get handshakeFile => 'Plik';

  @override
  String get handshakeBack => 'Ich portfel odsyła ją do przekaźnika.';

  @override
  String get handshakeRelayBack =>
      'Przekaźnik przekazuje ją z powrotem do twojego portfela.';

  @override
  String get handshakeFile1 =>
      'Twój portfel zapisuje plik płatności. Sam wysyłasz go do nich.';

  @override
  String get handshakeFile2 =>
      'Oni go otwierają. Ich portfel dodaje swoją część, podpisuje i zapisuje odpowiedź.';

  @override
  String get handshakeFile3 => 'Odsyłają ci plik odpowiedzi.';

  @override
  String get handshakeFile4 => 'Otwierasz ich odpowiedź w swoim portfelu.';

  @override
  String get handshakePrevious => 'Poprzedni krok';

  @override
  String get handshakeNext => 'Następny krok';

  @override
  String sendRelayRefused(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Ich przekaźnik jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dnia.',
      many:
          'Ich przekaźnik jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      few:
          'Ich przekaźnik jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      one:
          'Ich przekaźnik jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dzień.',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost =>
      'Ich przekaźnik jej nie przyjął. Sprawdź Portfel przed ponownym wysłaniem.';

  @override
  String get sendCancelAndFile => 'Anuluj i zapłać plikiem';

  @override
  String get sendLeaveIt => 'Zostaw na razie';

  @override
  String get sendSending => 'Wysyłanie…';

  @override
  String trackStepDone(String step) {
    return '$step, gotowe';
  }

  @override
  String trackStepNow(String step) {
    return '$step, teraz';
  }

  @override
  String trackStepLater(String step) {
    return '$step, później';
  }

  @override
  String balanceLineOnHold(String amount) {
    return '$amount wstrzymane';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount w drodze';
  }

  @override
  String get demoTestCoinsPill => 'Monety testowe';

  @override
  String get demoTestCoinsPillTip =>
      'Floonet, sieć testowa Epic. Monety nie mają wartości.';

  @override
  String demoLeftHours(int hours) {
    return 'zostało $hours h';
  }

  @override
  String demoLeftMinutes(int minutes) {
    return 'zostało $minutes min';
  }

  @override
  String get demoReceiveKeepOpen => 'Nie zamykaj tej karty, aby odbierać.';

  @override
  String get demoGuideTitle => 'Wypróbuj płatność';

  @override
  String get demoGuideSend => 'Wyślij komuś trochę';

  @override
  String get demoGuideSendHint =>
      'Zapłać do demo znajomego albo otwórz tę stronę w innej przeglądarce lub oknie prywatnym.';

  @override
  String get demoGuideOpenSend => 'Przejdź do Wyślij';

  @override
  String get demoGuideAsking => 'Pytamy testowy kran. To może potrwać minutę.';

  @override
  String get demoGuideDone => 'Gotowe. Rozejrzyj się, póki trwa demo.';

  @override
  String get demoGuideHide => 'Ukryj';

  @override
  String get demoGuideHideLabel => 'Ukryj kroki demo';

  @override
  String demoGuideStepDone(String step) {
    return '$step, zrobione';
  }

  @override
  String demoGuideStepToDo(String step) {
    return '$step, jeszcze nie';
  }

  @override
  String get receiveTabEpicbox => 'Epicbox';

  @override
  String get receiveTabTor => 'Tor';

  @override
  String get receiveTabFile => 'Plik';

  @override
  String get receiveTorAddressLabel => 'Adres Tor';

  @override
  String get receiveTorQrLabel => 'Kod QR Twojego adresu Tor';

  @override
  String get torReceivingTitle => 'Odbieranie przez Tor';

  @override
  String get torHonestLine =>
      'Odbiór przez Tor działa, gdy aplikacja jest otwarta lub krótko w tle.';

  @override
  String get torStateOff => 'Odbieranie przez Tor jest wyłączone';

  @override
  String torStateStarting(int percent) {
    return 'Łączenie z Tor… $percent%';
  }

  @override
  String get torStatePublishing => 'Publikowanie Twojego adresu Tor…';

  @override
  String get torStateReady => 'Odbieranie przez Tor jest włączone';

  @override
  String torStateNotReachable(String reason) {
    return 'Twój adres Tor nie jest jeszcze osiągalny. $reason';
  }

  @override
  String get torFailureMissing => 'Ta aplikacja nie zawiera Tora.';

  @override
  String get torFailureStart => 'Tor się nie uruchomił.';

  @override
  String get torFailureNetwork =>
      'Nie udało się połączyć z siecią Tor. Sprawdź połączenie.';

  @override
  String get torFailureClock =>
      'Zegar telefonu jest źle ustawiony. Tor potrzebuje właściwego czasu.';

  @override
  String get torFailureListener =>
      'Portfel nie mógł otworzyć swojego adresu Tor.';

  @override
  String get torFailureStopped => 'Tor został zatrzymany.';

  @override
  String get torFailurePublish => 'Nie udało się opublikować adresu Tor.';

  @override
  String get torFailureKeys => 'Tor nie przyjął klucza adresu portfela.';

  @override
  String get sendOnionIncomplete =>
      'To nie jest pełny adres Tor. Skopiuj go ponownie od odbiorcy.';

  @override
  String get sendTorUnavailable =>
      'Ta aplikacja nie wysyła przez Tor, więc nie da się tu zapłacić na adres Tor.';

  @override
  String get sendOverTor => 'Przez Tor';

  @override
  String get sendTorConnectsOnSend => 'Tor łączy się przy wysyłaniu.';

  @override
  String get sendTorReady => 'Gotowe do wysłania przez Tor';

  @override
  String get sendTorReaching =>
      'Łączenie z portfelem odbiorcy przez Tor… To może potrwać. Nie zamykaj aplikacji.';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Nie udało się połączyć z portfelem odbiorcy przez Tor. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dnia.',
      many:
          'Nie udało się połączyć z portfelem odbiorcy przez Tor. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      few:
          'Nie udało się połączyć z portfelem odbiorcy przez Tor. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      one:
          'Nie udało się połączyć z portfelem odbiorcy przez Tor. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dzień.',
    );
    return '$_temp0';
  }

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Nic nie zostało wysłane.';
  }

  @override
  String get sendTryAgain => 'Spróbuj ponownie';

  @override
  String get sendCancelPayment => 'Anuluj płatność';

  @override
  String get settingsSectionReceiving => 'Odbieranie';

  @override
  String get homeAvailableToSpend => 'Do wydania';

  @override
  String get homeTileWaitingSender => 'Czeka na nadawcę';

  @override
  String get homeTileLocked => 'Zablokowane w wysyłkach';

  @override
  String get homeTileMaturing => 'Nagrody dojrzewają';

  @override
  String get homeTileTotal => 'Razem';

  @override
  String homeViewAll(int count) {
    return 'Zobacz wszystkie: $count';
  }

  @override
  String get homeDestActivity => 'Aktywność';

  @override
  String get homeDestOutputs => 'Wyjścia';

  @override
  String get txStatusReceived => 'Otrzymano';

  @override
  String get txStatusSent => 'Wysłano';

  @override
  String sendPinReason(String amount) {
    return 'Wpisz PIN, aby wysłać $amount.';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'Wpisz PIN, aby utworzyć plik płatności na $amount.';
  }

  @override
  String get outputsTitle => 'Wyjścia';

  @override
  String get outputsSpendable => 'Do wydania';

  @override
  String get outputsConfirming => 'Potwierdzane';

  @override
  String get outputsLockedTile => 'Zablokowane w wysyłkach';

  @override
  String get outputsImmature => 'Niedojrzałe';

  @override
  String outputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia',
      many: '$count wyjść',
      few: '$count wyjścia',
      one: '$count wyjście',
    );
    return '$_temp0';
  }

  @override
  String get outputsSplitButton => 'Podziel…';

  @override
  String get outputsConsolidateButton => 'Scal…';

  @override
  String get outputsSplitNeeds =>
      'Podział wymaga co najmniej 1 EPIC do wydania.';

  @override
  String get outputsConsolidateNeeds =>
      'Scalanie wymaga co najmniej 2 wyjść do wydania.';

  @override
  String get outputsWaitLocked =>
      'Poczekaj na potwierdzenie trwającej wysyłki (około 3 bloków).';

  @override
  String get outputsStrategy => 'Strategia wysyłek';

  @override
  String get outputsSmallest => 'Najmniejsze';

  @override
  String get outputsAll => 'Wszystkie';

  @override
  String get outputsSmallestText =>
      'Wydaje jak najmniej małych wyjść; reszta salda pozostaje do wydania, gdy reszta się potwierdza.';

  @override
  String get outputsAllText =>
      'Wydaje wszystkie wyjścia i zwraca jedno wyjście reszty. Wszystko jest zablokowane do potwierdzenia; potem mniej, większych wyjść.';

  @override
  String get outputsSplitChange => 'Podziel resztę';

  @override
  String get outputsSplitChangeText => 'Gdy zostałoby mało wyjść';

  @override
  String outputsFilterAll(int count) {
    return 'Wszystkie $count';
  }

  @override
  String outputsFilterSpendable(int count) {
    return 'Do wydania $count';
  }

  @override
  String outputsFilterConfirming(int count) {
    return 'Potwierdzane $count';
  }

  @override
  String outputsFilterLocked(int count) {
    return 'Zablok. $count';
  }

  @override
  String get outputsShowSpent => 'Pokaż wydane';

  @override
  String get outputsHideSpent => 'Ukryj wydane';

  @override
  String get outputsWordSpendable => 'Do wydania';

  @override
  String get outputsWordConfirming => 'Potwierdzane';

  @override
  String get outputsWordFinalizing => 'Czeka na sfinalizowanie';

  @override
  String get outputsWordImmature => 'Niedojrzałe';

  @override
  String get outputsWordMining => 'Kopanie';

  @override
  String get outputsWordLocked => 'Zablokowane';

  @override
  String get outputsWordSpent => 'Wydane';

  @override
  String get outputsMeanSpendable => 'Można wydać teraz.';

  @override
  String outputsMeanConfirming(int need) {
    return 'Wymaga $need potwierdzeń, zanim będzie można go wydać.';
  }

  @override
  String get outputsMeanFinalizing => 'Czeka, aż nadawca zakończy płatność.';

  @override
  String get outputsMeanImmature =>
      'Nagroda za kopanie. Można ją wydać po pewnym czasie.';

  @override
  String get outputsMeanMining =>
      'Nagroda za kopanie, jeszcze niepotwierdzona.';

  @override
  String get outputsMeanLocked => 'Jest wydawane przez trwającą wysyłkę.';

  @override
  String get outputsMeanSpent => 'Już wydane.';

  @override
  String outputsNoteReceived(String date) {
    return 'Odebrano $date';
  }

  @override
  String outputsNoteSend(String who) {
    return 'Wysyłka do $who';
  }

  @override
  String get outputsNoteSendPlain => 'Wysyłka w toku';

  @override
  String get outputsFactHeight => 'Wysokość';

  @override
  String get outputsFactConfirmations => 'Potwierdzenia';

  @override
  String get outputsFactTransaction => 'Transakcja';

  @override
  String get outputsFactCommitment => 'Zobowiązanie';

  @override
  String get outputsCopy => 'Kopiuj';

  @override
  String get outputsCopied => 'Skopiowano zobowiązanie';

  @override
  String get outputsEmpty => 'Brak wyjść';

  @override
  String get outputsEmptyHint =>
      'Pierwsza otrzymana płatność utworzy jedno. Adres jest w zakładce Odbierz.';

  @override
  String get outputsNoMatch => 'Brak wyjść w tym widoku';

  @override
  String get outputsRetry => 'Ponów';

  @override
  String outputsSettingsSubtitle(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia · $strategy',
      many: '$count wyjść · $strategy',
      few: '$count wyjścia · $strategy',
      one: '$count wyjście · $strategy',
    );
    return '$_temp0';
  }

  @override
  String get outputsCancel => 'Anuluj';

  @override
  String get outputsSplitTitle => 'Podział wyjść';

  @override
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  ) {
    return 'Wydaje $spent ($amount) i tworzy $made po około $each. Zwykła transakcja sieciowa do tego portfela, potwierdzona po 3 blokach jak każda wysyłka; wszystko do wydania jest do tego czasu zablokowane.';
  }

  @override
  String get outputsToMake => 'Liczba wyjść';

  @override
  String get outputsStepperHint => 'od 2 do 10';

  @override
  String get outputsFactFee => 'Opłata sieciowa';

  @override
  String get outputsFactEach => 'Każde wyjście';

  @override
  String outputsFactAbout(String amount) {
    return 'około $amount';
  }

  @override
  String get outputsFactLocked => 'Zablokowane';

  @override
  String outputsFactLockedValue(String amount) {
    return '$amount, około 3 bloków';
  }

  @override
  String get outputsNothingSpendable =>
      'W tym czasie nic nie zostaje do wydania.';

  @override
  String get outputsMinEach => 'Każde wyjście musi mieć co najmniej 0,5 EPIC.';

  @override
  String outputsSplitInto(int count) {
    return 'Podziel na $count';
  }

  @override
  String get outputsConsolidateTitle => 'Scalanie wyjść';

  @override
  String outputsConsolidateText(String amount, String result, String spent) {
    return 'Wydaje $spent ($amount) i tworzy jedno wyjście na $result. Zwykła transakcja sieciowa do tego portfela, potwierdzona po 3 blokach jak każda wysyłka; wszystko do wydania jest do tego czasu zablokowane. Następna wysyłka wyda jedno wyjście, więc jej opłata będzie najmniejsza.';
  }

  @override
  String get outputsConsolidateAction => 'Scal';

  @override
  String get outputsSplitPin => 'Potwierdź PIN-em, aby podzielić wyjścia';

  @override
  String get outputsConsolidatePin => 'Potwierdź PIN-em, aby scalić wyjścia';

  @override
  String outputsSplitStarted(int count) {
    return 'Podział rozpoczęty: $count wyjść, potwierdzenie za około 3 bloki';
  }

  @override
  String get outputsConsolidateStarted =>
      'Scalanie rozpoczęte: jedno wyjście, potwierdzenie za około 3 bloki';

  @override
  String get outputsAdvanced => 'Zaawansowane';

  @override
  String get outputsColState => 'Stan';

  @override
  String get outputsColValue => 'Wartość';

  @override
  String get outputsColConfirmations => 'Potwierdzenia';

  @override
  String homePendingShort(String amount) {
    return '$amount pozostaje zablokowane, dopóki portfel odbiorcy nie odpowie.';
  }

  @override
  String get contactsSearchHint => 'Nazwa lub adres';

  @override
  String get contactsEmptyTitle => 'Brak kontaktów';

  @override
  String get contactsEmptyCaption => 'Kontakt to nazwa dla adresu.';

  @override
  String contactsNoMatchQuery(String query) {
    return 'Żaden kontakt nie pasuje do „$query”';
  }

  @override
  String get contactsSendAction => 'Wyślij';

  @override
  String get contactsEditAction => 'Edytuj';

  @override
  String get contactsAddressHeading => 'Adres';

  @override
  String get contactsNoteHeading => 'Notatka';

  @override
  String get contactsShowCode => 'Pokaż kod';

  @override
  String get contactsHideCode => 'Ukryj kod';

  @override
  String contactsQrLabel(String name) {
    return 'Kod QR adresu: $name';
  }

  @override
  String get contactsDeleteConfirmBody =>
      'Płatności na ten adres pokażą potem adres zamiast nazwy.';

  @override
  String contactsDeleted(String name) {
    return 'Usunięto: $name.';
  }

  @override
  String get contactsCopied => 'Adres skopiowany.';

  @override
  String get invoicesNewRequest => 'Nowa prośba';

  @override
  String get invoicesSegmentSent => 'Wysłane';

  @override
  String invoicesSegmentCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pozycji',
      many: '$count pozycji',
      few: '$count pozycje',
      one: '$count pozycja',
      zero: 'brak',
    );
    return '$label, $_temp0';
  }

  @override
  String get invoicesToPayEmpty => 'Brak faktur do zapłaty';

  @override
  String get invoicesToPayEmptyCaption =>
      'Serwisy z twojej zaufanej listy mogą wystawiać rachunki temu portfelowi. Każda faktura czeka tu na twoją zgodę.';

  @override
  String get invoicesSentEmpty => 'Brak wysłanych próśb';

  @override
  String get invoicesSentEmptyCaption =>
      'Prośba prosi kogoś o zapłacenie ci kwoty.';

  @override
  String get invoicesWaitingPayment => 'Czeka na płatność';

  @override
  String get invoicesExpires => 'Wygasa';

  @override
  String invoicesUntil(String time) {
    return 'do $time';
  }

  @override
  String get invoicesMessage => 'Wiadomość';

  @override
  String get invoicesFrom => 'Od';

  @override
  String get invoicesPaysFrom => 'Płaci z';

  @override
  String invoicesAvailable(String amount) {
    return 'Dostępne $amount';
  }

  @override
  String invoicesShort(String amount) {
    return 'Za mało, by zapłacić. Brakuje $amount.';
  }

  @override
  String get invoicesCheckNode => 'Węzeł';

  @override
  String get invoicesCheckEpicbox => 'Epicbox';

  @override
  String get invoicesNodeOk => 'Odpowiada';

  @override
  String get invoicesNodeDown => 'Nie odpowiada';

  @override
  String get invoicesEpicboxOk => 'Połączono';

  @override
  String get invoicesEpicboxDown => 'Brak połączenia';

  @override
  String get invoicesSendRequest => 'Wyślij prośbę';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer otrzyma prośbę o zapłatę $amount. Prośba wygasa za 24 h.';
  }

  @override
  String get invoicesRequestHowTitle => 'Zanim poprosisz';

  @override
  String get netStatusNode => 'Węzeł';

  @override
  String get netStatusEpicbox => 'Epicbox';

  @override
  String get netStatusTor => 'Tor';

  @override
  String get netStatusSynced => 'Zsynchronizowany';

  @override
  String get netStatusSyncing => 'Synchronizacja';

  @override
  String netStatusSyncingPercent(int percent) {
    return 'Synchronizacja $percent %';
  }

  @override
  String get netStatusConnecting => 'Łączenie';

  @override
  String netStatusBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Opóźniony o $countString',
      many: 'Opóźniony o $countString',
      few: 'Opóźniony o $countString',
      one: 'Opóźniony o $countString',
    );
    return '$_temp0';
  }

  @override
  String get netStatusOffline => 'Offline';

  @override
  String get netStatusOnline => 'Online';

  @override
  String get netStatusOff => 'Wyłączony';

  @override
  String get netStatusOn => 'Włączony';

  @override
  String get netStatusFailed => 'Błąd';

  @override
  String netStatusStarting(int percent) {
    return 'Uruchamianie $percent %';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => 'Stan sieci';

  @override
  String get serverMyRelays => 'Moje serwery';

  @override
  String get serverRemoveRelay => 'Usuń z moich serwerów';

  @override
  String get serverRemoveInUse => 'W użyciu. Najpierw przełącz na inny serwer.';

  @override
  String get serverRemoveRelayTitle => 'Usunąć ten serwer?';

  @override
  String get serverRemoveNodeTitle => 'Usunąć ten węzeł?';

  @override
  String serverRemoveBody(String host) {
    return '$host zniknie z tej listy. Wpisz go ponownie, aby użyć go później.';
  }

  @override
  String get serverRemoveConfirm => 'Usuń';

  @override
  String get serverSupportsNotifications => 'Obsługuje powiadomienia';

  @override
  String get netStatusReachable => 'Osiągalny';

  @override
  String get netStatusPublishing => 'Publikowanie…';

  @override
  String get netStatusNotReachable => 'Nieosiągalny';

  @override
  String get netStatusTorOpenHint => 'Otwiera ustawienia prywatności';

  @override
  String get netStatusDirectOpenHint => 'Otwiera adres odbioru bezpośredniego';

  @override
  String get netStatusOpenHint => 'Pokazuje serwery';

  @override
  String get serverNodeTitle => 'Węzeł';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'Znajdź lub wpisz adres węzła';

  @override
  String serverUseAddress(String address) {
    return 'Użyj $address';
  }

  @override
  String get serverTesting => 'Sprawdzanie…';

  @override
  String serverTestAnswer(String height, String version) {
    return 'Blok $height · v$version';
  }

  @override
  String serverTestFailed(String error) {
    return 'Brak odpowiedzi. $error';
  }

  @override
  String get serverMyNodes => 'Moje węzły';

  @override
  String get serverPublicNodes => 'Węzły publiczne';

  @override
  String get serverPublicRelays => 'Serwery publiczne';

  @override
  String get serverHealthUnknown =>
      'status.btlabs.uk nieosiągalny; stan nieznany';

  @override
  String get serverAtTip => 'na bieżąco';

  @override
  String serverBehindShort(String count) {
    return '−$count';
  }

  @override
  String serverBehindLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bloku w tyle',
      many: '$count bloków w tyle',
      few: '$count bloki w tyle',
      one: '$count blok w tyle',
    );
    return '$_temp0';
  }

  @override
  String get serverAddMine => 'Dodaj do moich węzłów';

  @override
  String get serverRemoveMine => 'Usuń z moich węzłów';

  @override
  String get serverNotResponding => 'Nie odpowiada';

  @override
  String get serverHealthy => 'Sprawny';

  @override
  String get serverDegraded => 'Ograniczony';

  @override
  String get serverHealthNone => 'Stan nieznany';

  @override
  String get serverCurrent => 'Bieżący';

  @override
  String get serverDefault => 'Domyślny';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % dostępności';
  }

  @override
  String serverSwitchTo(String host) {
    return 'Przełącz na $host';
  }

  @override
  String get serverNodeSwitchNote =>
      'Portfel połączy się ponownie. Salda zostaną ponownie sprawdzone z nowym węzłem.';

  @override
  String get serverRelayWarning =>
      'Twój adres zawiera ten serwer. Zmiana zmienia adres; nadawcy potrzebują nowego.';

  @override
  String get serverRelaySwitchNote =>
      'Twój adres się zmieni; nadawcy potrzebują nowego.';

  @override
  String get serverOtherRelay => 'Inny serwer, host lub host:port';

  @override
  String get serverFactHeight => 'Wysokość';

  @override
  String get serverFactVersion => 'Wersja';

  @override
  String get serverFactPeers => 'Peery';

  @override
  String get serverFactUptime => 'Dostępność 24 h';

  @override
  String serverHeightAtTip(String height) {
    return '$height · na bieżąco';
  }

  @override
  String serverNodesAgree(String height) {
    return 'Węzły zgodne co do $height';
  }

  @override
  String serverNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$up z $total węzła działa',
      many: '$up z $total węzłów działa',
      few: '$up z $total węzłów działa',
      one: '$up z $total węzła działa',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'ostatni blok $seconds s temu',
      many: 'ostatni blok $seconds s temu',
      few: 'ostatni blok $seconds s temu',
      one: 'ostatni blok $seconds s temu',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ostatni blok $minutes min temu',
      many: 'ostatni blok $minutes min temu',
      few: 'ostatni blok $minutes min temu',
      one: 'ostatni blok $minutes min temu',
    );
    return '$_temp0';
  }

  @override
  String serverCheckedAt(String time) {
    return 'status.btlabs.uk, sprawdzono $time';
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
  String get methodFile => 'Plik';

  @override
  String get methodArtCaptionEpicbox => 'Serwer Epicbox ją trzyma';

  @override
  String get methodArtCaptionHttp => 'Prosto do portfela';

  @override
  String get methodArtCaptionTor => 'Prosto, przez Tor';

  @override
  String get methodArtCaptionFile => 'Plik tam, odpowiedź z powrotem';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: płatność trafia na serwer Epicbox, który trzyma ją, aż portfel odbiorcy wróci';

  @override
  String get methodArtLabelHttp =>
      'HTTP: płatność trafia prosto do portfela odbiorcy, który musi być otwarty';

  @override
  String get methodArtLabelTor =>
      'Tor: płatność trafia prosto do portfela odbiorcy, przez sieć Tor';

  @override
  String get methodArtLabelFile =>
      'Plik: plik transakcji jest przekazywany, wraca plik odpowiedzi, potem nadawca finalizuje';

  @override
  String get methodSendEpicboxTitle => 'Odbiorca może być offline.';

  @override
  String get settingsShowTipsAgain => 'Pokaż wskazówki ponownie';

  @override
  String get settingsShowTipsAgainDone => 'Wskazówki znów będą widoczne';

  @override
  String get tipHide => 'Ukryj wskazówkę';

  @override
  String get methodSendEpicboxLine =>
      'Serwer Epicbox trzyma płatność, aż odbiorca otworzy portfel.';

  @override
  String get methodSendHttpTitle => 'Prosto do portfela odbiorcy.';

  @override
  String get methodSendHttpLine =>
      'Musi być otwarty i osiągalny pod swoim adresem HTTP.';

  @override
  String get methodSendTorTitle => 'Prosto do portfela odbiorcy, przez Tor.';

  @override
  String get methodSendTorLine =>
      'Wolniej i bardziej prywatnie. Portfel odbiorcy musi być otwarty.';

  @override
  String get methodSendFileTitle => 'Bez połączenia.';

  @override
  String get methodSendFileLine =>
      'Przekaż plik, odbierz plik odpowiedzi, potem sfinalizuj go tutaj.';

  @override
  String get methodReceiveEpicboxTitle => 'Udostępnij go, aby dostać płatność.';

  @override
  String get methodReceiveEpicboxLine =>
      'Działa, gdy portfel jest zamknięty: serwer Epicbox przechowuje płatności, aż wróci.';

  @override
  String get methodReceiveTorTitle => 'Wolniej i bardziej prywatnie.';

  @override
  String get methodReceiveTorLine =>
      'Działa tylko, gdy aplikacja jest otwarta lub krótko w tle.';

  @override
  String get methodReceiveFileTitle => 'Przekazujcie plik tam i z powrotem.';

  @override
  String get methodReceiveFileLine =>
      'Działa bez połączenia między portfelami.';

  @override
  String get methodAddressKindsTooltip => 'Rodzaje adresów';

  @override
  String get sendMethodLabel => 'Metoda';

  @override
  String get sendToLabel => 'Do';

  @override
  String get sendToHint => 'Adres lub kontakt';

  @override
  String get sendSwitchedHttp => 'Przez HTTP';

  @override
  String get sendSwitchedEpicbox => 'Przez Epicbox';

  @override
  String get sendSwitchedTorAnnounce => 'Adres Tor. Ustawiono metodę Tor.';

  @override
  String get sendSwitchedHttpAnnounce => 'Adres HTTP. Ustawiono metodę HTTP.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Adres Epicbox. Ustawiono metodę Epicbox.';

  @override
  String get sendReviewMethodHttp => 'HTTP, prosto do portfela';

  @override
  String get sendCancelRuleEpicbox =>
      'Można anulować, dopóki czeka na odbiorcę.';

  @override
  String get sendCancelRuleDirect =>
      'Nie można anulować, gdy portfel odbiorcy ją przyjmie.';

  @override
  String get sendCancelRuleFile =>
      'Można anulować, dopóki plik odpowiedzi nie zostanie sfinalizowany.';

  @override
  String get sendHttpReaching =>
      'Łączenie z portfelem odbiorcy… Nie zamykaj aplikacji.';

  @override
  String get sendDeliveredWaitingBlock => 'Dostarczono · Czeka na blok';

  @override
  String get sendHttpAddressShape =>
      'Adres HTTP zaczyna się od http:// lub https://.';

  @override
  String get sendPlainHttpTitle => 'Bez szyfrowania. Wysłać mimo to?';

  @override
  String get sendPlainHttpBody =>
      'Zwykłe HTTP do innego urządzenia. Każdy po drodze może odczytać transakcję. Adres https:// jest szyfrowany.';

  @override
  String get sendCancelPossibleWhileWaiting =>
      'Możliwe, dopóki płatność czeka na odbiorcę.';

  @override
  String get receiveEpicboxCaption =>
      'Czytając go na głos, sprawdź pierwsze sześć i ostatnie sześć znaków.';

  @override
  String get receiveTorCaption =>
      'Niektóre portfele pokazują adres bez .onion; to ten sam adres.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dnia.',
      many:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      few:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      one:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dzień.',
    );
    return '$_temp0';
  }

  @override
  String deskInvActFrom(String label) {
    return 'Faktura od: $label';
  }

  @override
  String get deskInvActFilter => 'Faktury';

  @override
  String get deskInvActBlock => 'Faktura';

  @override
  String get deskInvActOpen => 'Otwórz w Fakturach';

  @override
  String get deskInvActBilledBy => 'Wystawił';

  @override
  String get deskInvActOverviewTitle => 'Faktury';

  @override
  String deskInvActOverviewToPay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faktury do zapłaty',
      many: '$count faktur do zapłaty',
      few: '$count faktury do zapłaty',
      one: '$count faktura do zapłaty',
      zero: 'Nic do zapłaty',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wystawione faktury czekają na płacących',
      many: '$count wystawionych faktur czeka na płacących',
      few: '$count wystawione faktury czekają na płacących',
      one: '$count wystawiona faktura czeka na płacącego',
      zero: 'Żadna wystawiona faktura nie czeka',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności wymaga działania: ponów lub anuluj',
      many: '$count płatności wymaga działania: ponów lub anuluj',
      few: '$count płatności wymagają działania: ponów lub anuluj',
      one: '$count płatność wymaga działania: ponów lub anuluj',
    );
    return '$_temp0';
  }

  @override
  String get deskInvActReview => 'Sprawdź';

  @override
  String get deskInvActOpenInvoices => 'Otwórz Faktury';

  @override
  String get deskInvNav => 'Faktury';

  @override
  String get deskInvTitle => 'Faktury';

  @override
  String get deskInvTabPay => 'Zapłać';

  @override
  String get deskInvTabIssue => 'Wystaw';

  @override
  String deskInvTabCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get deskInvIssueAction => 'Wystaw fakturę';

  @override
  String get deskInvChecking => 'Sprawdzanie';

  @override
  String deskInvCheckedAt(String time) {
    return 'Sprawdzono o $time';
  }

  @override
  String get deskInvCheckFailedTitle => 'Serwer Epicbox nie odpowiada';

  @override
  String get deskInvCheckFailedBody =>
      'Listy pokazują to, co dotarło wcześniej. Nic nie zginęło; portfel ponawia próbę co 2 minuty.';

  @override
  String get deskInvReqWaiting => 'Czeka na płacącego';

  @override
  String get deskInvReqPaid => 'Zapłacono, finalizowanie';

  @override
  String get deskInvReqPosted => 'Wysłano do sieci';

  @override
  String deskInvConfirming(int count, int total) {
    return 'Potwierdzanie $count z $total';
  }

  @override
  String get deskInvCompleted => 'Zakończono';

  @override
  String get deskInvReqNotPosted => 'Nie wysłano';

  @override
  String get deskInvDeclined => 'Odrzucono';

  @override
  String get deskInvExpired => 'Wygasło';

  @override
  String get deskInvWithdrawn => 'Wycofano';

  @override
  String get deskInvReqBounced => 'Odesłano';

  @override
  String get deskInvPayWaiting => 'Do zapłaty';

  @override
  String get deskInvPayPaying => 'Płacenie';

  @override
  String get deskInvPayNotDelivered => 'Nie dostarczono';

  @override
  String get deskInvPayDelivered => 'Czeka na wysłanie';

  @override
  String get deskInvPayPosted => 'Wysłane przez serwis';

  @override
  String get deskInvPayWithdrawnAfterPay => 'Wycofano po zapłacie';

  @override
  String get deskInvPayPastTtl => 'Brak w łańcuchu';

  @override
  String get deskInvPayCancelled => 'Anulowano';

  @override
  String get deskInvUnpaid => 'Nieopłacona';

  @override
  String get deskInvYouPay => 'Płacisz';

  @override
  String deskInvExpiresAt(String time) {
    return 'Wygasa $time';
  }

  @override
  String get deskInvSlateId => 'ID slate';

  @override
  String get deskInvAdvanced => 'Zaawansowane';

  @override
  String get deskInvOneDevice =>
      'Korzystaj z faktur tylko na jednym urządzeniu. Inne urządzenie z tym portfelem może przejąć płatność przeznaczoną dla tego.';

  @override
  String get deskInvFailed =>
      'To się nie udało. Nic się nie zmieniło; spróbuj ponownie.';

  @override
  String get deskInvHowItWorks => 'Jak działają faktury';

  @override
  String get deskInvAddressHint => 'es…@epicbox.epiccash.com';

  @override
  String get deskInvEpicboxAddress => 'Adres Epicbox';

  @override
  String get deskInvHelpTitle => 'Faktury';

  @override
  String get deskInvHelpLede =>
      'Rachunki od zaufanych nadawców, płacone dopiero po zatwierdzeniu.';

  @override
  String get deskInvHelpFlowTitle => 'Jak działa faktura';

  @override
  String get deskInvHelpFlowShort =>
      'Wystawca wysyła fakturę na adres do faktur płatnika. Nic nie zostaje zapłacone, dopóki płatnik jej nie zatwierdzi.';

  @override
  String get deskInvHelpFlowIntro =>
      'Faktura to prośba o płatność. **Wystawca** otrzymuje pieniądze; **płatnik** decyduje.';

  @override
  String get deskInvHelpFlowStep1 =>
      'Portfel wystawcy wysyła fakturę przez serwer Epicbox na **adres do faktur** płatnika.';

  @override
  String get deskInvHelpFlowStep2 =>
      'Płatnik otwiera ją w [[Faktury › Zapłać]], sprawdza nadawcę, kwotę i wiadomość, i wybiera **Zatwierdź i zapłać**, podając hasło portfela.';

  @override
  String get deskInvHelpFlowStep3 =>
      'Portfel płatnika wysyła płatność na **adres płatności** wystawcy.';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return 'Portfel wystawcy finalizuje płatność i publikuje ją w sieci. Liczba potwierdzeń, po której jest ostateczna: $confirmations.';
  }

  @override
  String get deskInvHelpFlowNever =>
      'Bez zatwierdzenia nic nie zostaje zapłacone, a faktura nigdy nie dodaje pieniędzy do portfela płatnika. Każda faktura ma termin płatności, najwyżej 48 godzin; po nim nie da się jej już zapłacić.';

  @override
  String get deskInvHelpFlowIssued =>
      'Faktury wystawione przez ten portfel są w [[Faktury › Wystaw]].';

  @override
  String get deskInvHelpTrustTitle => 'Dlaczego tylko zaufani nadawcy';

  @override
  String get deskInvHelpTrustShort =>
      'Tylko nadawcy z listy zaufanych mogą umieścić fakturę w skrzynce. To chroni przed spamem i fałszywymi rachunkami.';

  @override
  String get deskInvHelpTrustP1 =>
      'Portfel przyjmuje fakturę tylko na swój adres do faktur i tylko od nadawcy z listy zaufanych, rozpoznanego po adresie. Wszystko inne jest odrzucane bez czytania, zanim zostanie otwarte, i nigdy nie pojawia się w [[Faktury › Zapłać]].';

  @override
  String get deskInvHelpTrustP2 =>
      'Bez tej listy każdy, kto poznał adres do faktur, mógłby zapełnić skrzynkę spamem albo rachunkami, które wyglądają na prawdziwe.';

  @override
  String get deskInvHelpTrustP3 =>
      'Zaufanie pozwala nadawcy tylko prosić. Zaufany nadawca nie może niczego zabrać: każda faktura nadal czeka na **Zatwierdź i zapłać**.';

  @override
  String get deskInvHelpTrustWhere1 =>
      'Zaufaj nadawcy w [[Ustawienia › Faktury]].';

  @override
  String get deskInvHelpTrustWhere2 =>
      'Albo włącz **Zaufany dla faktur** przy kontakcie w [[Kontakty]].';

  @override
  String get deskInvHelpTrustWhere3 =>
      'Nadawcę można w każdej chwili usunąć z listy. Jego nowe faktury są wtedy odrzucane.';

  @override
  String get deskInvHelpAddrTitle => 'Dlaczego osobny adres do faktur';

  @override
  String get deskInvHelpAddrShort =>
      'Faktury przychodzą na własny adres, oddzielny od adresu płatności, na który się płaci.';

  @override
  String get deskInvHelpAddrP1 =>
      'Portfel ma dwa adresy Epicbox. **Adres płatności**, w [[Odbierz]], przyjmuje płatności. **Adres do faktur** przyjmuje tylko faktury.';

  @override
  String get deskInvHelpAddrP2 =>
      'Dzięki rozdzieleniu adres do faktur można dać serwisom albo wymienić, nie ujawniając ani nie zmieniając adresu, na który się płaci.';

  @override
  String get deskInvHelpAddrP3 =>
      'Adres do faktur nie przyjmuje płatności: płatność wysłana na niego jest odrzucana. Aby otrzymać płatność, podaj adres płatności.';

  @override
  String get deskInvHelpAddrWhere1 =>
      'Adres do faktur można znaleźć, skopiować lub pokazać jako kod QR w [[Ustawienia › Faktury]].';

  @override
  String get deskInvHelpAddrWhere2 =>
      '**Nowy adres do faktur** go zastępuje. Serwisy ze starym adresem nie mogą wysyłać faktur, dopóki nie dostaną nowego.';

  @override
  String get deskInvHelpDiagramTitle => 'Jak podróżuje faktura';

  @override
  String get deskInvHelpDiagramIssuer => 'Wystawca';

  @override
  String get deskInvHelpDiagramPayer => 'Płatnik';

  @override
  String get deskInvHelpDiagramIssues => 'Wystawia fakturę';

  @override
  String get deskInvHelpDiagramInvoice => 'Faktura';

  @override
  String get deskInvHelpDiagramGate => 'Adres do faktur';

  @override
  String get deskInvHelpDiagramGateSub => 'Tylko zaufani nadawcy';

  @override
  String get deskInvHelpDiagramDropped => 'Inni nadawcy';

  @override
  String get deskInvHelpDiagramDroppedSub => 'Odrzucone bez czytania';

  @override
  String get deskInvHelpDiagramReview => 'Sprawdza i zatwierdza';

  @override
  String get deskInvHelpDiagramReviewSub => 'Zatwierdź i zapłać';

  @override
  String get deskInvHelpDiagramPayment => 'Płatność';

  @override
  String get deskInvHelpDiagramPayAddr => 'Adres płatności';

  @override
  String get deskInvHelpDiagramPayAddrSub => 'Nie adres do faktur';

  @override
  String get deskInvHelpDiagramFinal => 'Finalizuje i publikuje';

  @override
  String deskInvHelpDiagramFinalSub(int confirmations) {
    return 'Ostateczna po potwierdzeniach: $confirmations';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      'Wystawca wysyła fakturę na adres do faktur płatnika, który przyjmuje tylko zaufanych nadawców i odrzuca resztę; płatnik ją sprawdza i zatwierdza; płatność trafia na adres płatności wystawcy; portfel wystawcy ją finalizuje i publikuje w sieci.';

  @override
  String get deskInvIssuerFormTitle => 'Wystaw fakturę';

  @override
  String get deskInvIssuerFirstTitle => 'Przed pierwszą fakturą';

  @override
  String get deskInvIssuerYourAddress => 'Twój adres do płatności';

  @override
  String get deskInvIssuerMethod => 'Metoda';

  @override
  String get deskInvIssuerEpicbox => 'Epicbox';

  @override
  String get deskInvIssuerFile => 'Plik';

  @override
  String get deskInvIssuerDirect => 'Bezpośrednio';

  @override
  String get deskInvIssuerSoon => 'Wkrótce';

  @override
  String get deskInvIssuerPayer => 'Adres do faktur płacącego';

  @override
  String get deskInvIssuerPayerHelp =>
      'Jego portfel pokazuje go w Ustawienia › Faktury.';

  @override
  String get deskInvIssuerPayerMissing => 'Wklej adres do faktur płacącego.';

  @override
  String get deskInvIssuerPayerInvalid =>
      'To nie jest prawidłowy adres Epicbox.';

  @override
  String get deskInvIssuerPayerOwn =>
      'To jeden z Twoich własnych adresów. Użyj adresu do faktur, który poda płacący.';

  @override
  String get deskInvIssuerPayerHttp =>
      'Faktury przez Epicbox wymagają adresu Epicbox, a nie HTTP ani Tor.';

  @override
  String get deskInvIssuerContacts => 'Kontakty';

  @override
  String get deskInvIssuerNoContacts =>
      'Żaden kontakt nie ma jeszcze adresu do faktur. Dodaj go w Kontaktach.';

  @override
  String get deskInvIssuerNoInvoices =>
      'Ten portfel odesłał już kiedyś fakturę: nie może płacić faktur przez Epicbox. Wyślij zamiast tego plik z fakturą albo poproś o przesłanie płatności.';

  @override
  String get deskInvIssuerUseFile => 'Użyj pliku';

  @override
  String get deskInvIssuerUnknown =>
      'Tylko wallet-for-epic i inne portfele LEPIC mogą zapłacić fakturę przez Epicbox. Epic GUI wallet i Stack Wallet w ogóle nie płacą faktur; wiersz poleceń epic-wallet może zapłacić plik z fakturą.';

  @override
  String get deskInvIssuerAmount => 'Kwota';

  @override
  String get deskInvIssuerAmountMissing => 'Wpisz kwotę.';

  @override
  String get deskInvIssuerAmountZero => 'Kwota musi być większa niż 0.';

  @override
  String get deskInvIssuerAmountDecimals =>
      'EPIC ma najwyżej 8 miejsc po przecinku.';

  @override
  String get deskInvIssuerAmountCap =>
      'Więcej niż wszystkie EPIC, jakie kiedykolwiek powstaną.';

  @override
  String get deskInvIssuerAmountHelp =>
      'Nic nie opuszcza Twojego portfela: płacący płaci tę kwotę plus własną opłatę.';

  @override
  String get deskInvIssuerMessage => 'Wiadomość dla płacącego';

  @override
  String deskInvIssuerMessageCount(int used, int max) {
    return '$used z $max bajtów';
  }

  @override
  String get deskInvIssuerMessageLong => 'Wiadomość jest za długa.';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'Płacący ma $hours godz. na zapłatę.';
  }

  @override
  String get deskInvIssuerIssue => 'Wystaw';

  @override
  String get deskInvIssuerRelayDown =>
      'Serwer Epicbox nie odpowiada, więc teraz nie można wysłać faktury.';

  @override
  String get deskInvIssuerFixFields => 'Popraw pola zaznaczone na czerwono.';

  @override
  String get deskInvIssuerNotDelivered =>
      'Faktura nie dotarła do serwera Epicbox. Nic nie wysłano. Spróbuj ponownie.';

  @override
  String deskInvIssuerSent(String payer) {
    return 'Wysłano fakturę do: $payer.';
  }

  @override
  String get deskInvIssuerEmpty =>
      'Nie wystawiono jeszcze faktur. Faktura prosi kontakt lub serwis o zapłatę; nic nie kosztuje.';

  @override
  String deskInvIssuerTo(String payer) {
    return 'Faktura dla: $payer';
  }

  @override
  String deskInvIssuerIssued(String time) {
    return 'Wystawiono $time';
  }

  @override
  String get deskInvIssuerPayerFact => 'Płacący';

  @override
  String get deskInvIssuerAmountFact => 'Kwota';

  @override
  String get deskInvIssuerMessageFact => 'Wiadomość';

  @override
  String get deskInvIssuerSentFact => 'Wystawiono';

  @override
  String get deskInvIssuerExpiresFact => 'Wygasa';

  @override
  String get deskInvIssuerAnsweredFact => 'Zakończono';

  @override
  String get deskInvIssuerStepPaid => 'Zapłacono';

  @override
  String get deskInvIssuerStepConfirming => 'Potwierdzanie';

  @override
  String get deskInvIssuerEnded =>
      'Ta faktura zakończyła się bez zapłaty. Nic nie dotarło.';

  @override
  String get deskInvIssuerWithdraw => 'Wycofaj';

  @override
  String get deskInvIssuerWithdrawTitle => 'Wycofać tę fakturę?';

  @override
  String deskInvIssuerWithdrawBody(String payer) {
    return '$payer nie będzie już mógł jej zapłacić.';
  }

  @override
  String get deskInvIssuerKeep => 'Zostaw';

  @override
  String get deskInvIssuerWithdrawn => 'Fakturę wycofano.';

  @override
  String get deskInvIssuerRepost => 'Wyślij ponownie';

  @override
  String get deskInvIssuerReposted => 'Płatność wysłano ponownie.';

  @override
  String get deskInvIssuerNodeDown =>
      'Węzeł nie odpowiada. Spróbuj ponownie, gdy będzie dostępny.';

  @override
  String get deskInvIssuerNotPostedText =>
      'Płatność jest gotowa, ale nie ma jej w sieci: węzeł ją odrzucił albo był nieosiągalny.';

  @override
  String get deskInvIssuerCancel => 'Anuluj płatność';

  @override
  String get deskInvIssuerCancelTitle => 'Anulować tę płatność?';

  @override
  String deskInvIssuerCancelBody(String payer) {
    return 'Nie dotrze. Środki płacącego ($payer) pozostaną zablokowane w jego portfelu, dopóki tam jej nie anuluje.';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return 'Portfel płacącego ($payer) odesłał fakturę: nie może płacić faktur. Poproś zamiast tego o przesłanie płatności.';
  }

  @override
  String get deskInvIssuerSendFile => 'Użyj pliku';

  @override
  String get deskInvIssuerLate =>
      'Po zakończeniu tej faktury dotarła płatność. Została odrzucona; nic się nie zmieniło.';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer zapłacił. Twój portfel sfinalizował płatność i wysłał ją do sieci.';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return 'Dostarczono na adres do faktur płacącego ($payer). Nic nie jest zapłacone, dopóki tego nie zatwierdzi.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Kopiuj ID slate';

  @override
  String get deskInvIssuerStepsIntro =>
      'Portfel płacącego musi obsługiwać faktury. Przed pierwszą fakturą:';

  @override
  String get deskInvIssuerStepTrust =>
      '1. Płacący dodaje Twój adres do płatności poniżej do zaufanych nadawców.';

  @override
  String get deskInvIssuerStepAddress =>
      '2. Płacący podaje Ci swój adres do faktur.';

  @override
  String get deskInvIssuerStepIssued => 'Wystawiono';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return '$payer zapłacił(a) $amount EPIC.';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return '$payer odrzucił(a) Twoją fakturę.';
  }

  @override
  String get deskInvNoticeIssuedExpired =>
      'Wystawiona przez Ciebie faktura wygasła bez zapłaty.';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return '$service wycofał(a) fakturę, zanim na nią odpowiedziałeś(-aś).';
  }

  @override
  String get deskInvNoticeExpired =>
      'Faktura wygasła, zanim na nią odpowiedziałeś(-aś).';

  @override
  String get deskInvNoticeUnknownPayment =>
      'Nadeszła płatność za fakturę, której to urządzenie nie wystawiło, i została odrzucona. Jeśli wystawiło ją inne urządzenie z tym portfelem, poproś płacącego o anulowanie i ponowną płatność.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Nadeszła odpowiedź na płatność, której to urządzenie nie wysłało, i została odrzucona. Jeśli wysłało ją inne urządzenie z tym portfelem, anuluj ją tam i wyślij ponownie.';

  @override
  String get deskInvPayerWaitingHead => 'Czeka na Ciebie';

  @override
  String get deskInvPayerNeedsHead => 'Płatności do rozliczenia';

  @override
  String get deskInvPayerReview => 'Sprawdź';

  @override
  String get deskInvPayerPaidHead => 'Zapłacone';

  @override
  String get deskInvPayerView => 'Pokaż';

  @override
  String get deskInvPayerNoMessage => 'Brak wiadomości';

  @override
  String deskInvPayerDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wiadomości od niezaufanych nadawców zignorowano.',
      many: '$count wiadomości od niezaufanych nadawców zignorowano.',
      few: '$count wiadomości od niezaufanych nadawców zignorowano.',
      one: '$count wiadomość od niezaufanego nadawcy zignorowano.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvPayerTrustService => 'Zaufaj serwisowi…';

  @override
  String get deskInvPayerYourInvoiceAddress => 'Twój adres do faktur';

  @override
  String get deskInvPayerEmptyTitle => 'Żadne faktury nie czekają';

  @override
  String get deskInvPayerEmptyText =>
      'Gdy zaufany serwis wystawi Ci fakturę, pojawi się tutaj. Nic nie jest płacone, dopóki jej nie zatwierdzisz.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Twoja płatność dla: $service nie została dostarczona';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Jest podpisana i zapisana na tym urządzeniu; środki pozostają zablokowane. Ponów wysyła ją jeszcze raz bez ponownego zatwierdzania.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service wycofał opłaconą fakturę';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'Płatność może nigdy nie trafić do łańcucha. Anuluj ją, aby odblokować środki.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Twojej płatności dla: $service nie ma w łańcuchu';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Jej czas minął, a sieć jej nie widziała. Anuluj ją, aby odblokować środki.';

  @override
  String get deskInvPayerCancelPayment => 'Anuluj płatność';

  @override
  String get deskInvPayerSafetyTitle => 'Płać tylko oczekiwane rachunki';

  @override
  String get deskInvPayerSafetyText =>
      'Faktura nigdy nie dodaje pieniędzy do portfela. Zatwierdzenie jej wysyła pieniądze.';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return 'Zapłaciłeś: $service tę samą kwotę $ago temu';
  }

  @override
  String get deskInvPayerSameBillText =>
      'Sprawdź, czy to nowy rachunek, zanim zapłacisz.';

  @override
  String deskInvPayerAgoHours(int hours, int minutes) {
    return '$hours godz. $minutes min';
  }

  @override
  String deskInvPayerAgoMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get deskInvPayerFee => 'Opłata';

  @override
  String get deskInvPayerTotal => 'Razem';

  @override
  String get deskInvPayerBalanceAfter => 'Saldo po';

  @override
  String get deskInvPayerMessageCaption =>
      'Napisane przez serwis. Twój portfel tego nie sprawdza.';

  @override
  String get deskInvPayerPaysTo => 'Płatność dla';

  @override
  String deskInvPayerTrustedSince(String service, String date) {
    return '$service, zaufany od $date';
  }

  @override
  String get deskInvPayerExpires => 'Wygasa';

  @override
  String get deskInvPayerLockHeight => 'Wysokość blokady';

  @override
  String get deskInvPayerLockNone => 'Brak';

  @override
  String get deskInvPayerReceived => 'Otrzymano';

  @override
  String get deskInvPayerShort => 'Za mało dostępnych środków';

  @override
  String deskInvPayerShortText(String total, String spendable) {
    return 'Potrzebujesz $total EPIC dostępnych; masz $spendable EPIC. Środki w trakcie potwierdzania liczą się po 3 potwierdzeniach.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Węzeł nie odpowiada';

  @override
  String get deskInvPayerNodeDownText =>
      'Portfel nie może sprawdzić środków, więc nie może zapłacić. Zatwierdzanie zadziała, gdy węzeł odpowie; inny węzeł wybierzesz w Ustawienia › Węzeł.';

  @override
  String get deskInvPayerPaid =>
      'Ta faktura jest opłacona. Nie można już na nią nic zapłacić.';

  @override
  String get deskInvPayerDeclinedText =>
      'Odrzuciłeś tę fakturę. Nic nie zapłacono.';

  @override
  String get deskInvPayerBack => 'Wróć do Faktur';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return 'Zapłacić $amount EPIC + $fee opłaty dla: $service?';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC opuści Twój portfel. Wpisz hasło portfela, aby zatwierdzić.';
  }

  @override
  String get deskInvPayerPassword => 'Hasło portfela';

  @override
  String get deskInvPayerWrongPassword => 'Błędne hasło. Nic nie zapłacono.';

  @override
  String get deskInvPayerEnterPassword => 'Wpisz hasło portfela.';

  @override
  String get deskInvPayerPay => 'Zapłać';

  @override
  String get deskInvPayerCancel => 'Anuluj';

  @override
  String get deskInvPayerClose => 'Zamknij';

  @override
  String get deskInvPayerNodeDownPay =>
      'Węzeł nie odpowiada. Nic nie zapłacono.';

  @override
  String get deskInvPayerAlreadyAnswered =>
      'Na tę fakturę już odpowiedziano. Nic więcej nie zapłacono.';

  @override
  String get deskInvPayerCannotPay =>
      'Tej faktury nie można zapłacić. Nic nie zapłacono.';

  @override
  String get deskInvPayerNotDeliveredToast => 'Podpisano, nie dostarczono';

  @override
  String get deskInvPayerNotDeliveredToastText =>
      'Serwer Epicbox nie odpowiada. Ponów w Faktury › Zapłać; bez ponownego zatwierdzania.';

  @override
  String get deskInvPayerRetryFailed => 'Nadal nie dostarczono';

  @override
  String get deskInvPayerRetryFailedText =>
      'Serwer Epicbox nie odpowiada. Płatność pozostaje podpisana na tym urządzeniu.';

  @override
  String get deskInvPayerCancelTitle => 'Anulować tę płatność?';

  @override
  String get deskInvPayerCancelText =>
      'Anulowanie odblokowuje tutaj Twoje środki. Serwis nadal ma Twoją podpisaną płatność, więc może ją jeszcze sfinalizować, dopóki te środki nie zostaną ponownie wydane.';

  @override
  String deskInvPayerCancelWho(String amount, String service) {
    return '$amount EPIC dla: $service';
  }

  @override
  String get deskInvPayerKeepPayment => 'Zostaw';

  @override
  String get deskInvPayerOnItsWay => 'Już w drodze: nie można anulować.';

  @override
  String get deskInvPayerCannotCheck =>
      'Nie można teraz sprawdzić sieci; spróbuj ponownie, gdy węzeł będzie dostępny.';

  @override
  String get deskInvPayerCancelled => 'Płatność anulowana';

  @override
  String get deskInvPayerCancelledText => 'Twoje środki są odblokowane.';

  @override
  String get deskInvPayerDeclined => 'Faktura odrzucona. Nic nie zapłacono.';

  @override
  String get deskInvPayerSpendToSelf => 'Wyślij je teraz do siebie';

  @override
  String get deskInvPayerSpendToSelfHelp =>
      'Czyni anulowanie ostatecznym: podpisana kopia usługi nie może już zostać zrealizowana. Kosztuje opłatę sieciową.';

  @override
  String get deskInvPayerSpentText =>
      'Twoje środki są odblokowane i przeniesione w obrębie tego portfela. Anulowanie jest ostateczne.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Twoje środki są odblokowane, ale przeniesienie się nie udało. Anulowanie nie jest jeszcze ostateczne.';

  @override
  String get deskInvPayerLocked =>
      'Tej faktury nie można zapłacić: jest zablokowana do późniejszego bloku. Nic nie zostało zapłacone.';

  @override
  String get deskInvPayerRelayDownPay =>
      'Serwer Epicbox nie odpowiada. Nic nie zostało zapłacone.';

  @override
  String get deskInvSetTitle => 'Faktury';

  @override
  String get deskInvSetIntro =>
      'Zaufane serwisy wystawiają faktury na adres do faktur tego portfela. Nic nie jest płacone, dopóki nie zatwierdzisz każdej faktury.';

  @override
  String get deskInvSetAddressLabel => 'Adres do faktur';

  @override
  String get deskInvSetAddressWarning =>
      'Podawaj go tylko zaufanym serwisom. Nie służy do odbierania płatności.';

  @override
  String get deskInvSetCopy => 'Kopiuj';

  @override
  String get deskInvSetCopied =>
      'Skopiowano adres do faktur. Podawaj go tylko zaufanym serwisom; nie służy do odbierania płatności.';

  @override
  String get deskInvSetQrShow => 'Pokaż QR';

  @override
  String get deskInvSetQrHide => 'Ukryj QR';

  @override
  String get deskInvSetQrLabel => 'Kod QR Twojego adresu do faktur';

  @override
  String deskInvSetIndex(int index) {
    return 'Adres do faktur $index';
  }

  @override
  String get deskInvSetTrusted => 'Zaufani nadawcy';

  @override
  String get deskInvSetTrustedNone =>
      'Brak zaufanych nadawców. Faktury od innych są ignorowane bez czytania.';

  @override
  String deskInvSetSince(String date) {
    return 'Zaufany od $date';
  }

  @override
  String get deskInvSetContactTag => 'Kontakt';

  @override
  String get deskInvSetRemove => 'Usuń';

  @override
  String deskInvSetRemoveTitle(String name) {
    return 'Przestać ufać: $name?';
  }

  @override
  String deskInvSetRemoveBody(String name) {
    return '$name nie będzie mógł wysyłać Ci faktur. Faktury, które już czekają, zostaną, dopóki na nie nie odpowiesz albo nie wygasną.';
  }

  @override
  String deskInvSetRemoved(String name) {
    return '$name nie może już wysyłać Ci faktur.';
  }

  @override
  String get deskInvSetKeep => 'Zostaw';

  @override
  String get deskInvSetAdd => 'Zaufaj nadawcy';

  @override
  String get deskInvSetAddBody =>
      'Zaufany nadawca może wystawiać faktury na adres do faktur tego portfela. Nic nie jest płacone, dopóki nie zatwierdzisz każdej faktury hasłem portfela.';

  @override
  String get deskInvSetName => 'Nazwa';

  @override
  String get deskInvSetNameMissing => 'Nadaj nadawcy nazwę.';

  @override
  String get deskInvSetSenderAddress => 'Jego adres do płatności';

  @override
  String get deskInvSetSenderMissing => 'Wklej adres, który pokazuje serwis.';

  @override
  String get deskInvSetSenderInvalid => 'To nie jest prawidłowy adres Epicbox.';

  @override
  String get deskInvSetTrust => 'Zaufaj';

  @override
  String deskInvSetAdded(String name) {
    return '$name może teraz wysyłać Ci faktury.';
  }

  @override
  String deskInvSetDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count wiadomości od niezaufanych nadawców zignorowano bez czytania.',
      many:
          '$count wiadomości od niezaufanych nadawców zignorowano bez czytania.',
      few:
          '$count wiadomości od niezaufanych nadawców zignorowano bez czytania.',
      one: '$count wiadomość od niezaufanego nadawcy zignorowano bez czytania.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvSetRotate => 'Nowy adres do faktur';

  @override
  String get deskInvSetRotateHint =>
      'Serwisy ze starym adresem nie będą mogły wysyłać Ci faktur.';

  @override
  String get deskInvSetRotateTitle => 'Utworzyć nowy adres do faktur?';

  @override
  String get deskInvSetRotateBody =>
      'Serwisy ze starym adresem nie będą mogły wysyłać Ci faktur. Przekaż nowy każdemu serwisowi, który wystawia Ci faktury.';

  @override
  String get deskInvSetRotateConfirm => 'Utwórz nowy adres';

  @override
  String get deskInvSetRotated =>
      'Nowy adres do faktur gotowy. Przekaż go swoim serwisom.';

  @override
  String get deskInvSetExpiry => 'Czas na zapłatę';

  @override
  String get deskInvSetExpiryHint =>
      'Jak długo wystawiona faktura pozostaje do zapłaty i jak długo otrzymana na Ciebie czeka. Najwyżej 48 godzin.';

  @override
  String deskInvSetHours(int hours) {
    return '$hours godz.';
  }

  @override
  String get deskInvSetCancel => 'Anuluj';

  @override
  String get deskInvSetContactSection => 'Faktury';

  @override
  String get deskInvSetTheirInvoice => 'Adres do faktur kontaktu';

  @override
  String get deskInvSetTheirInvoiceNone =>
      'Nie zapisano adresu do faktur. Poproś o niego, aby wystawiać faktury.';

  @override
  String get deskInvSetTrustedSwitch => 'Zaufany dla faktur';

  @override
  String get deskInvSetTrustedSwitchHelp =>
      'Pozwala temu kontaktowi wystawiać Ci faktury. Nic nie jest płacone, dopóki nie zatwierdzisz faktury.';

  @override
  String get deskInvSetIssueNeeds => 'Wymaga adresu do faktur kontaktu.';

  @override
  String get deskInvSetShare => 'Udostępnij adres faktur';

  @override
  String get deskInvSetReceiveHint =>
      'Poproś kontakt lub serwis o zapłatę. Jego portfel musi obsługiwać faktury.';

  @override
  String get deskInvSetRestoredHint =>
      'Portfel odtworzony z frazy odzyskiwania? Przekaż usługom ten adres do faktur ponownie.';

  @override
  String get serverSwitchRelayTitle => 'Zmienić serwer epicbox?';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'Adres epicbox zmieni się na …@$relay. Nadawcy potrzebują nowego adresu. Płatności wysłane na stary adres zostają na starym serwerze.';
  }

  @override
  String get serverSwitchRelayConfirm => 'Zmień';

  @override
  String get helpButton => 'Pomoc';

  @override
  String get helpSearchHint => 'Szukaj w pomocy';

  @override
  String get helpEnglishOnly => 'Pomoc jest na razie po angielsku.';

  @override
  String get helpLanguageLabel => 'Język pomocy';

  @override
  String helpNoMatch(String query) {
    return 'Brak pomocy dla „$query”';
  }

  @override
  String helpMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tematu',
      many: '$count tematów',
      few: '$count tematy',
      one: '1 temat',
    );
    return '$_temp0';
  }

  @override
  String get helpShowHandshake => 'Pokaż, jak to działa';

  @override
  String get helpMoreInSection => 'Więcej w tej sekcji';

  @override
  String get sendBalanceAfter => 'Saldo po wysłaniu';

  @override
  String get sendSpendableUntilChange => 'Dostępne do potwierdzenia reszty';

  @override
  String get sendSpendableUntilChangeHint =>
      'Reszta wraca, gdy wysyłka zostanie potwierdzona.';

  @override
  String serverSwitched(String host) {
    return 'Przełączono na $host';
  }

  @override
  String get methodDirect => 'Bezpośrednio';

  @override
  String get methodDirectShape => 'http://host:3415 lub xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Ich portfel musi być otwarty. Adres onion idzie przez Tor.';

  @override
  String get methodArtLabelDirect =>
      'Bezpośrednio: płatność trafia prosto do portfela odbiorcy, który musi być otwarty';

  @override
  String get methodReceiveEpicboxShort => 'Działa przy zamkniętym portfelu.';

  @override
  String get methodReceiveDirectTitle => 'Prosto do tego portfela.';

  @override
  String get methodReceiveDirectLine => 'Działa, gdy aplikacja jest otwarta.';

  @override
  String methodLineOverTor(String line) {
    return '$line Przez Tor.';
  }

  @override
  String get sendSwitchedDirect => 'Adres bezpośredni';

  @override
  String get sendSwitchedDirectAnnounce =>
      'Adres bezpośredni. Metoda ustawiona na Bezpośrednio.';

  @override
  String get sendDirectAddressShape =>
      'Adres bezpośredni zaczyna się od http:// lub https:// albo kończy na .onion.';

  @override
  String get torNotOverTor => 'Nie przez Tor';

  @override
  String get torNeeds => 'Wymaga Tor.';

  @override
  String get torTurnOn => 'Włącz Tor';

  @override
  String get torTurnOff => 'Wyłącz Tor';

  @override
  String get torNotConnectedNotice => 'Tor nie jest połączony.';

  @override
  String get torWaiting => 'Czekam na Tor';

  @override
  String get torWordStarting => 'Uruchamianie…';

  @override
  String get torWordNotConnected => 'Brak połączenia';

  @override
  String get torSettingsLink => 'Ustawienia Tor';

  @override
  String get torNetworkLabel => 'Sieć Tor';

  @override
  String get torNetworkHint =>
      'Ruch sieciowy przechodzi przez sieć Tor. Tor ukrywa adres internetowy portfela: każde połączenie przechodzi przez kilka przekaźników prowadzonych przez wolontariuszy, więc żaden serwer nie dowiaduje się, gdzie jest portfel. Powiadomienia są wyłączone, gdy Tor jest włączony.';

  @override
  String get receiveTabDirect => 'Bezpośrednio';

  @override
  String get receiveDirectNeedsTor => 'Odbiór bezpośredni wymaga Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Do tego czasu nadawcy używają adresu Epicbox.';

  @override
  String get netStatusOverTor => 'przez Tor';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsNotificationsHint =>
      'Korzysta z usługi powiadomień Google. Żadne wrażliwe dane nie są udostępniane.';

  @override
  String get settingsPushPaused => 'Wstrzymane, gdy Tor jest włączony';

  @override
  String get pushConfirmRelayBody =>
      'Powiadomienia korzystają z Epicbox BT Labs i usługi powiadomień Google. Żadne wrażliwe dane nie są udostępniane.';

  @override
  String get pushConfirmRelayAddress =>
      'Twój adres Epicbox się zmieni. Udostępnij nowy.';

  @override
  String get pushRelaySwitchFailed =>
      'Nie udało się zmienić serwera. Powiadomienia pozostają wyłączone.';

  @override
  String get pushConfirmTitle => 'Włączyć powiadomienia?';

  @override
  String get pushConfirmBody =>
      'Powiadomienia korzystają z usługi powiadomień Google. Żadne wrażliwe dane nie są udostępniane.';

  @override
  String get pushConfirmAction => 'Włącz';

  @override
  String get pushNoticeOn => 'Powiadomienia włączone';

  @override
  String get pushNoticeOff => 'Powiadomienia wyłączone';

  @override
  String get pushNoticeAvailable => 'Powiadomienia są dostępne w Ustawieniach.';

  @override
  String get torWayOver => 'Przez Tor';

  @override
  String get torWayWaiting => 'Czekam na Tor';

  @override
  String get torWayNotConnected => 'Tor nie jest połączony.';

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Używa wszystkich $count wyjścia · reszta 1 wyjście',
      many: 'Używa wszystkich $count wyjść · reszta 1 wyjście',
      few: 'Używa wszystkich $count wyjść · reszta 1 wyjście',
      one: 'Używa wszystkich wyjść ($count) · reszta 1 wyjście',
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

  @override
  String get deskSetupConfirmPassword => 'Confirm password';

  @override
  String get deskSetupPasswordShort => 'At least 8 characters';

  @override
  String get deskSetupPasswordsDiffer => 'Passwords differ';

  @override
  String get deskSetupBack => 'Back';

  @override
  String get deskSetupNewWalletAdded => 'New wallet added.';

  @override
  String get deskSetupCapsLock => 'Caps Lock is on';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return 'Step $number of $total: $label';
  }

  @override
  String get deskSetupTryAgain => 'Try again';

  @override
  String get deskSetupNotSaved => 'Not saved';

  @override
  String get deskSetupStepPrefs => 'Preferences';

  @override
  String get deskSetupStepNode => 'Node';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupStepReview => 'Review';

  @override
  String get deskSetupAgain =>
      'Running setup again. Nothing changes until Save on the last step.';

  @override
  String get deskSetupPrefsLead => 'App language. It can be changed later.';

  @override
  String get deskSetupNodeTitle => 'Choose a node';

  @override
  String get deskSetupNodeLead =>
      'The wallet reads the chain and sends through an Epic node.';

  @override
  String get deskSetupLocalTitle => 'Local node';

  @override
  String get deskSetupLocalLead =>
      'What running the node here means, and which node to use.';

  @override
  String get deskSetupEpicboxTitle => 'Receive when offline';

  @override
  String get deskSetupReviewTitle => 'Check settings';

  @override
  String get deskSetupReviewLead =>
      'Change anything that is not right, then save.';

  @override
  String get deskSetupSideTitle => 'Set up';

  @override
  String get deskSetupBackToWallet => 'Back to wallet';

  @override
  String get deskSetupLaterNote =>
      'Everything here can be changed later in Settings.';

  @override
  String get deskSetupSave => 'Save settings';

  @override
  String get deskSetupLanguage => 'Language';

  @override
  String get deskSetupNodeServer => 'Node server';

  @override
  String get deskSetupNodeHint => 'Find or type a node address';

  @override
  String get deskSetupCheckingNodes => 'Checking nodes…';

  @override
  String get deskSetupPickNode => 'Pick a node';

  @override
  String get deskSetupPublicNodes => 'Public nodes';

  @override
  String get deskSetupNotInList => 'not in the public list';

  @override
  String get deskSetupEnterUses => 'Enter uses it.';

  @override
  String get deskSetupNoNodes => 'No nodes to show.';

  @override
  String get deskSetupRemoteNode => 'Remote node';

  @override
  String get deskSetupRemoteNodeText => 'Any public node. Ready at once.';

  @override
  String get deskSetupLocalNodeText =>
      'Runs the Epic node on this computer. Nothing is shared with an operator. Needs disk space and hours to sync.';

  @override
  String get deskSetupEpicboxText =>
      'Epicbox delivers payments to the Epicbox address and holds them until the wallet is online.';

  @override
  String get deskSetupEpicboxPrivacy =>
      'It does not hide the IP address from the Epicbox server. Use a VPN if that matters.';

  @override
  String get deskSetupEpicboxServer => 'Epicbox server';

  @override
  String get deskSetupEpicboxHelp =>
      'Leave empty to turn receiving through Epicbox off.';

  @override
  String get deskSetupChangePrefsSem => 'Change preferences';

  @override
  String get deskSetupChangeNodeSem => 'Change node';

  @override
  String get deskSetupChangeEpicboxSem => 'Change epicbox';

  @override
  String get deskSetupChange => 'Change';

  @override
  String get deskSetupType => 'Type';

  @override
  String get deskSetupAddress => 'Address';

  @override
  String deskSetupExistingNode(String host) {
    return 'Existing node at $host';
  }

  @override
  String get deskSetupBundledNode => 'Local node, bundled';

  @override
  String get deskSetupWhileSyncing => 'While syncing';

  @override
  String get deskSetupWait => 'wait';

  @override
  String get deskSetupDataFolder => 'Data folder';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Save starts the node. The first sync takes hours; the wallet opens meanwhile and uses $node until then.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Save starts the node. The first sync takes hours; the wallet opens meanwhile.';

  @override
  String get deskSetupServer => 'Server';

  @override
  String get deskSetupOff => 'Off';

  @override
  String get deskSetAboutLicencesLead =>
      'Open-source software in this wallet. Each component keeps its own licence; the full texts are one click away.';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop by BT Labs: Apache-2.0. The code is on GitHub.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Browser not opened';

  @override
  String get deskSetAboutOpen => 'Open';

  @override
  String deskSetAboutVersion(String version) {
    return 'Version  $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Node  $version';
  }

  @override
  String get deskSetAboutCommunity => 'Community';

  @override
  String get deskSetAboutLicences => 'Licences';

  @override
  String get deskSetAboutSource => 'Source code';

  @override
  String get deskSetAboutView => 'View';

  @override
  String deskSetAboutChecked(String ago) {
    return 'Checked $ago.';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version is the latest';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return 'Update available: $version';
  }

  @override
  String get deskSetAboutCouldNotCheck => 'Could not check';

  @override
  String get deskSetAboutUpdates => 'Updates';

  @override
  String deskSetAboutGet(String version) {
    return 'Get $version';
  }

  @override
  String get deskSetAboutCheckNow => 'Check now';

  @override
  String get deskSetAboutAgoNow => 'just now';

  @override
  String deskSetAboutAgoMin(int count) {
    return '$count min ago';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return '$count h ago';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return '$count d ago';
  }

  @override
  String get deskSetAboutCopyLink => 'Copy link';

  @override
  String get deskSetAboutCopied => 'Copied';

  @override
  String get deskSetAboutNotCopied => 'Not copied';

  @override
  String get deskSetAppearTheme => 'Theme';

  @override
  String get deskSetAppearThemeHint => 'System follows the computer’s setting.';

  @override
  String get deskSetAppearSystem => 'System';

  @override
  String get deskSetAppearDark => 'Dark';

  @override
  String get deskSetAppearLight => 'Light';

  @override
  String get deskSetAppearScale => 'Interface scale';

  @override
  String get deskSetAppearScaleHint =>
      'Text and controls, larger or smaller. Applies at once.';

  @override
  String get deskSetAppearLanguage => 'Language';

  @override
  String get deskSetAppearLanguageHint => 'Applies at once.';

  @override
  String get deskSetAppearHideHint =>
      'Shows dots in place of balances and amounts.';

  @override
  String deskSetHelpNoMatchText(String query) {
    return 'No topic matches “$query”. Try another word.';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Topics found: $count',
      one: 'Topics found: $count',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'No topic matches';

  @override
  String get deskSetHelpReportText =>
      'Describe what went wrong. The app log can go with it, cleaned of secrets and encrypted to the developer. Save to file keeps a copy to send by hand.';

  @override
  String get deskSetHelpShowLess => 'Show less';

  @override
  String get deskSetHelpReadMore => 'Read more';

  @override
  String get deskSetHelpEb1 =>
      'The sending wallet passes the payment to Epicbox and locks the outputs.';

  @override
  String get deskSetHelpEb2 =>
      'Epicbox delivers it when the receiving wallet is online. That wallet adds its part and signs.';

  @override
  String get deskSetHelpEb3 => 'The receiving wallet sends it back to Epicbox.';

  @override
  String get deskSetHelpEb4 => 'Epicbox passes it back to the sending wallet.';

  @override
  String get deskSetHelpSigns =>
      'The sending wallet signs too, finishes the transaction and posts it to the network.';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The network puts it in a block. After $count confirmations it is final.',
      one:
          'The network puts it in a block. After $count confirmation it is final.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 =>
      'The sending wallet saves a transaction file and locks the outputs. The file goes to the recipient by any means.';

  @override
  String get deskSetHelpFile2 =>
      'The recipient opens it. Their wallet adds its part, signs and saves a response file.';

  @override
  String get deskSetHelpFile3 => 'The response file comes back to the sender.';

  @override
  String get deskSetHelpFile4 =>
      'The sender opens the response file under Finalize.';

  @override
  String get deskSetHelpSender => 'Sender';

  @override
  String get deskSetHelpFile => 'File';

  @override
  String get deskSetHelpRecipient => 'Recipient';

  @override
  String get deskSetHelpNetwork => 'Network';

  @override
  String get deskSetHelpTravels => 'How a transaction travels';

  @override
  String get deskSetHelpOverEpicbox => 'Over Epicbox';

  @override
  String get deskSetHelpWithFile => 'With a file';

  @override
  String deskSetHelpStep(int number, int total) {
    return 'Step $number of $total';
  }
}
