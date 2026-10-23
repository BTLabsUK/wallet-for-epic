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
  String get updateNeedsPermission =>
      'Na ekranie, który się otworzył, zezwól tej aplikacji na instalowanie aktualizacji, a potem ponownie dotknij „Aktualizuj”.';

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
      'Czcionki Montserrat i JetBrains Mono: SIL Open Font License 1.1.';

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
}
