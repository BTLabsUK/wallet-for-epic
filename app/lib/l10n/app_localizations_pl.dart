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
  String get txMiningReward => 'Nagroda za kopanie';

  @override
  String get txRestoredFunds => 'Odzyskane środki';

  @override
  String txSpokenLabelled(String label, String row) {
    return '$label, $row';
  }

  @override
  String get txLabel => 'Etykieta';

  @override
  String get txLabelAdd => 'Dodaj etykietę';

  @override
  String get txLabelEdit => 'Edytuj etykietę';

  @override
  String get txLabelHint => 'Dodaj etykietę';

  @override
  String get txLabelAddedNotice => 'Dodano etykietę';

  @override
  String get txLabelSavedNotice => 'Zapisano etykietę';

  @override
  String get txLabelRemovedNotice => 'Usunięto etykietę';

  @override
  String get txEditAdd => 'Dodaj szczegóły';

  @override
  String get txEditEdit => 'Edytuj szczegóły';

  @override
  String get txEditFrom => 'Od';

  @override
  String get txEditFromHint => 'Adres';

  @override
  String get txEditFromHelper =>
      'Niezweryfikowane. Nigdy nie służy do dowodów płatności.';

  @override
  String get txMethodUnknown => 'Nieznana';

  @override
  String get txManualTag => 'Dodane przez ciebie';

  @override
  String txManualTip(String date) {
    return 'Dodane przez ciebie dnia $date. Nie pochodzi z blockchaina.';
  }

  @override
  String get txManualTipNoDate =>
      'Dodane przez ciebie. Nie pochodzi z blockchaina.';

  @override
  String txManualTipFrom(String date) {
    return 'Dodane przez ciebie dnia $date. Nie pochodzi z blockchaina, niezweryfikowane.';
  }

  @override
  String get txManualTipFromNoDate =>
      'Dodane przez ciebie. Nie pochodzi z blockchaina, niezweryfikowane.';

  @override
  String get txEditAddedNotice => 'Dodano szczegóły';

  @override
  String get txEditSavedNotice => 'Zapisano szczegóły';

  @override
  String get txEditRemovedNotice => 'Usunięto szczegóły';

  @override
  String get histConflictTitle => 'Szczegóły się różnią';

  @override
  String histConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Kopia ma inne szczegóły dla płatności opisanych przez ciebie: $n. Twoje zostają, chyba że wybierzesz inaczej.',
      many:
          'Kopia ma inne szczegóły dla płatności opisanych przez ciebie: $n. Twoje zostają, chyba że wybierzesz inaczej.',
      few:
          'Kopia ma inne szczegóły dla płatności opisanych przez ciebie: $n. Twoje zostają, chyba że wybierzesz inaczej.',
      one:
          'Kopia ma inne szczegóły dla płatności opisanych przez ciebie: $n. Twoje zostają, chyba że wybierzesz inaczej.',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'Moje';

  @override
  String get histConflictBackup => 'Kopia';

  @override
  String get histConflictKeepAll => 'Zachowaj wszystkie moje';

  @override
  String get histConflictImport => 'Importuj';

  @override
  String get histConflictEmpty => 'puste';

  @override
  String histImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Zastąpiono szczegółów: $n. Pozostałe zostają twoje.',
      many: 'Zastąpiono szczegółów: $n. Pozostałe zostają twoje.',
      few: 'Zastąpiono szczegółów: $n. Pozostałe zostają twoje.',
      one: 'Zastąpiono szczegółów: $n. Pozostałe zostają twoje.',
    );
    return '$_temp0';
  }

  @override
  String get txOutgoingPayment => 'Płatność wychodząca';

  @override
  String get txIncomingPayment => 'Płatność przychodząca';

  @override
  String get txStatusWaitingRecipient => 'Czeka na odbiorcę';

  @override
  String get txStatusWaitingSender => 'Czeka na nadawcę';

  @override
  String get txStatusSenderPosted => 'Nadawca zgłasza publikację';

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
    return 'Nagroda za kopanie: $amount';
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
  String get currencyPln => 'Złoty polski';

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
  String get txDetailsSenderPosted =>
      'Według nadawcy ta płatność została opublikowana w sieci. Zakończy się, gdy blockchain ją potwierdzi.';

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
      'Anulowano. Nic nie zostało zapłacone, a środki są znów dostępne. Jeśli odbiorca już ją otrzymał, jego portfel może nadal pokazywać ją jako oczekującą; nie można jej już dokończyć.';

  @override
  String get txDetailsCancelledReleased =>
      'Sieć nie przyjęła tej płatności, więc jej środki zostały zwolnione. Przed ponownym wysłaniem sprawdź, czy odbiorca jej nie otrzymał.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Płatność nie trafiła do sieci w ciągu 14 dni, więc portfel ją anulował. Przed ponownym wysłaniem sprawdź, czy odbiorca jej nie otrzymał.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Odbiorca nie odpowiedział w ciągu 14 dni, więc portfel anulował płatność. Nic nie zostało zapłacone, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Odbiorca odpowiedział po upływie 14 dni, więc portfel anulował płatność, zamiast ją dokończyć. Nic nie zostało zapłacone, a środki są znów dostępne.';

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
  String get demoEndedBody =>
      'Portfel demo i jego monety testowe zostały usunięte.';

  @override
  String get demoStartAgain => 'Zacznij od nowa';

  @override
  String demoEndsAt(String time) {
    return 'Twoje demo kończy się o $time. Jego portfel i monety testowe zostaną wtedy usunięte.';
  }

  @override
  String get demoEndingSoon =>
      'Twoje demo kończy się za 30 minut. Jego portfel i monety testowe zostaną wtedy usunięte.';

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
    return 'Z twojej sieci uruchomiono zbyt wiele wersji demo. Spróbuj ponownie za $minutes min.';
  }

  @override
  String get demoConnectionLost =>
      'Utracono połączenie, trwa ponowne łączenie.';

  @override
  String get demoConnectionBack => 'Połączono ponownie.';

  @override
  String get homeSettingsTooltip => 'Ustawienia';

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
  String get homeNoticeSenderPosted =>
      'Według nadawcy płatność została opublikowana.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Według nadawcy opublikowano $amount.';
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
      'Płatności do ciebie, których nadawca jeszcze nie dokończył lub które nie są jeszcze w bloku, oraz reszta z twoich wysyłek. Liczą się dopiero w bloku: płatność tylko zaproponowana może nigdy nie dotrzeć.';

  @override
  String get homeBalanceLocked => 'Zablokowane przez trwającą płatność';

  @override
  String get balanceLockedHelp =>
      'Zarezerwowane na rozpoczętą płatność; reszta wróci po jej zakończeniu.';

  @override
  String get homeBalanceImmature => 'Nagrody za kopanie jeszcze niedostępne';

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
  String get statusEpicboxOnline => 'Epicbox połączony';

  @override
  String get statusEpicboxConnecting => 'Łączenie z Epicbox';

  @override
  String get statusEpicboxOffline => 'Epicbox niepołączony';

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
      'Portfel nie jest połączony ze swoim serwerem Epicbox i próbuje dalej.';

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
      'Żadne prośby nie czekają. Gdy sparowany kontakt, któremu zezwolisz, poprosi o zapłatę, prośba pojawi się tutaj i nic nie zostanie zapłacone bez twojej zgody.';

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
  String invoiceReviewAsks(String service) {
    return 'Serwis $service prosi o zapłatę';
  }

  @override
  String invoiceReviewMessageLabel(String name) {
    return 'Wiadomość od: $name';
  }

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
  String invoiceDetailsRepliedHelp(String service) {
    return 'Jeśli $service jej nie opublikował, wyślij płatność ponownie: nic nie jest podpisywane dwa razy. Jeśli nigdy nie zostanie opublikowana, Anuluj będzie dostępne, gdy minie czas płatności, około doby po zapłacie.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return 'Serwis $service zgłasza, że płatność została opublikowana. Zakończy się, gdy sieć ją potwierdzi.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return 'Serwis $service nie otrzymał jeszcze twojej płatności. „Ponów” wyśle ją jeszcze raz, bez ponownego zatwierdzania.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return 'Serwis $service wycofał tę fakturę po jej opłaceniu. Jeśli płatność nie zostanie potwierdzona, anuluj ją, aby odblokować środki.';
  }

  @override
  String get invoiceNoticeReceived => 'Faktura czeka na twoje zatwierdzenie.';

  @override
  String get invoiceNoticePosted =>
      'Serwis zgłasza, że opublikował twoją płatność.';

  @override
  String get invoiceNoticeWithdrawnPaid =>
      'Serwis wycofał fakturę, która jest już opłacona.';

  @override
  String get invoiceNoticeWithdrawn =>
      'Serwis wycofał fakturę przed twoją odpowiedzią.';

  @override
  String get invoiceNoticeExpired => 'Faktura wygasła przed twoją odpowiedzią.';

  @override
  String get receiveRequestTitle => 'Poproś o płatność';

  @override
  String get requestMessageLabel => 'Wiadomość do płacącego (opcjonalnie)';

  @override
  String get requestMessageHelper =>
      'Płacący zobaczy tę wiadomość razem z prośbą.';

  @override
  String get requestButton => 'Poproś';

  @override
  String get invoicesToPaySection => 'Do zapłaty';

  @override
  String get invoicesNoneToPay => 'Nic do zapłaty.';

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
    return '$payer nie może już jej zapłacić. Tego nie można cofnąć.';
  }

  @override
  String get issuedWithdrawKeep => 'Zostaw';

  @override
  String get issuedDetailsSection => 'Prośba o płatność';

  @override
  String get issuedDetailsPayer => 'Prośba do';

  @override
  String get issuedDetailsWaiting =>
      'Oczekiwanie na płacącego. Twój portfel zakończy płatność, gdy ona dotrze.';

  @override
  String get issuedDetailsPaid =>
      'Zapłacona. Twój portfel zakończył płatność; zakończy się ona, gdy sieć ją potwierdzi.';

  @override
  String get issuedDetailsDeclined =>
      'Płacący odrzucił tę prośbę, więc została wycofana. Nic nie zapłacono.';

  @override
  String get issuedDetailsWithdrawn =>
      'Ta prośba została przez ciebie wycofana. Nic nie zapłacono.';

  @override
  String get issuedDetailsExpired =>
      'Ta prośba wygasła, zanim ją zapłacono. Nic nie zapłacono.';

  @override
  String get issuerNoticePaid => 'Jedna z twoich próśb została zapłacona.';

  @override
  String get issuerNoticeDeclined => 'Jedna z twoich próśb została odrzucona.';

  @override
  String get issuerNoticeWithdrawn =>
      'Prośba wycofana. Nie można jej już zapłacić.';

  @override
  String get issuerNoticeExpired => 'Jedna z twoich próśb wygasła bez zapłaty.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Portfel $payer nie obsługuje próśb o płatność i odesłał twoją, więc została wycofana. Poproś tę osobę, by zamiast tego wysłała ci płatność na twój adres lub jako plik płatności.';
  }

  @override
  String get issuedBounced => 'Odesłana';

  @override
  String get issuedDetailsBounced =>
      'Portfel płacącego nie obsługuje próśb o płatność i odesłał tę prośbę, więc została wycofana. Nic nie zapłacono. Poproś tę osobę, by zamiast tego wysłała ci płatność na twój adres lub jako plik płatności.';

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
  String get receiveEpicboxConnected => 'Połączono z Epicbox';

  @override
  String get receiveQrLabel => 'Kod QR twojego adresu';

  @override
  String get receiveAddressLabel => 'Adres Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'Płatności wysłane do ciebie czekają teraz w epicbox i dotrą, gdy portfel znów się połączy.';

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
      'Masz od kogoś plik płatności? Otwórz go albo skopiuj jego tekst i wklej tutaj.';

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
  String get updateInstallCancelled =>
      'Aktualizacja nie została zainstalowana. Możesz spróbować ponownie.';

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
  String get updateNoTorDownload =>
      'Aktualizacji nie można jeszcze pobrać przez Tor. Wyłącz Tor, aby ją pobrać, albo pobierz ją ze strony pobierania.';

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
  String get setupNetworkSettingsTooltip => 'Węzeł i Epicbox';

  @override
  String get setupNetworkHeading => 'Sieć';

  @override
  String get setupNodeUrlLabel => 'Adres URL węzła';

  @override
  String get setupCustomRelayLabel =>
      'Inny serwer epicbox (host lub host:port)';

  @override
  String get setupCustomRelayInvalid => 'Wpisz host, np. epicbox.example.com';

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
      'Zrzut ekranu lub zdjęcie frazy to pełna kopia portfela: każdy, kto je zobaczy, może zabrać twoje środki, a aplikacje ze zdjęciami mogą wysłać je do chmury. Papier jest najbezpieczniejszy.';

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
  String get backupCopyTitle => 'Skopiować frazę odzyskiwania?';

  @override
  String get backupCopyBody =>
      'Każdy, kto ma te słowa, może zabrać twoje środki. Przechowuj kopię w bezpiecznym miejscu.';

  @override
  String get backupCopied =>
      'Skopiowano. Schowek zostanie wyczyszczony za 60 sekund.';

  @override
  String get backupNotCopied => 'Nie skopiowano. Schowek odrzucił tekst.';

  @override
  String get unlockTitle => 'Odblokuj portfel';

  @override
  String get pinlessUnlock => 'Odblokuj';

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
  String get sendMethodEpicbox => 'Adres Epicbox';

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
      'Prośby o płatność (faktury) nie są jeszcze obsługiwane.';

  @override
  String get slateNotTransactionFile => 'To nie jest plik transakcji.';

  @override
  String get slateReading => 'Odczytywanie pliku';

  @override
  String get slateReadingQr => 'Odczytuję płatność';

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
    return 'Ktoś wysyła ci $amount.';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'Odpowiedź odbiorcy dotycząca twojej płatności: $amount (opłata $fee).';
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
  String get qrShowReplyAsQr => 'Pokaż odpowiedź jako QR';

  @override
  String get qrShowTitlePayment => 'Kod QR płatności';

  @override
  String get qrShowTitleReply => 'Kod QR odpowiedzi';

  @override
  String qrShowSubPayment(String amount) {
    return '$amount dla telefonu obok ciebie';
  }

  @override
  String qrShowSubReply(String amount) {
    return 'Dla nadawcy $amount';
  }

  @override
  String get qrHiddenTitle => 'Ukryty, dopóki go nie pokażesz';

  @override
  String get qrHiddenBodyPayment =>
      'Kto zeskanuje go pierwszy, może przyjąć tę płatność. Pokaż go tylko osobie, której płacisz.';

  @override
  String get qrHiddenBodyReply =>
      'Pokaż go telefonowi nadawcy. Tylko jego portfel może go użyć.';

  @override
  String get qrShow => 'Pokaż QR';

  @override
  String get qrShowAgain => 'Pokaż ponownie';

  @override
  String get qrHide => 'Ukryj';

  @override
  String qrCountdownLabel(int seconds) {
    return 'Pokażę za $seconds';
  }

  @override
  String qrPartOf(int part, int count) {
    return 'Część $part z $count';
  }

  @override
  String qrSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String qrSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Zostało $seconds sekundy',
      many: 'Zostało $seconds sekund',
      few: 'Zostały $seconds sekundy',
      one: 'Została 1 sekunda',
    );
    return '$_temp0';
  }

  @override
  String get qrHoldHint => 'Przyłóż aparat drugiego telefonu do tego kodu.';

  @override
  String get qrSecureLine => 'Zrzuty ekranu są wyłączone na tym ekranie';

  @override
  String qrTimedOutTitle(int seconds) {
    return 'Ukryty po $seconds s';
  }

  @override
  String get qrTimedOutBody =>
      'Pokaż go ponownie, gdy drugi telefon będzie gotowy.';

  @override
  String qrTimedOutAnnounce(int seconds) {
    return 'Ukryty po $seconds sekundach';
  }

  @override
  String get qrAwayTitle => 'Ukryty, gdy aplikacji nie było na ekranie';

  @override
  String get qrAwayBody => 'Kod ukrywa się, gdy aplikacja opuści ekran.';

  @override
  String qrSemanticsPayment(String state) {
    return 'Kod QR płatności, $state';
  }

  @override
  String qrSemanticsReply(String state) {
    return 'Kod QR odpowiedzi, $state';
  }

  @override
  String get qrStateHidden => 'ukryty';

  @override
  String get qrStateShowing => 'widoczny';

  @override
  String get qrScanPayment => 'Skanuj kod QR płatności';

  @override
  String get qrScanReply => 'Skanuj odpowiedź';

  @override
  String get qrScanAimPayment =>
      'Skieruj aparat na kod QR na telefonie drugiej osoby.';

  @override
  String get qrScanAimReply =>
      'Skieruj aparat na odpowiedź na telefonie drugiej osoby.';

  @override
  String get qrScanSteady => 'Trzymaj stabilnie albo podejdź trochę bliżej.';

  @override
  String get qrScanGot => 'Mam to';

  @override
  String qrScanCount(int got, int count) {
    return '$got z $count';
  }

  @override
  String get qrScanCountLabel => 'Odczytane części';

  @override
  String get qrScanNotPayment =>
      'To nie jest kod QR płatności. Poproś drugą osobę, by pokazała kod płatności na swoim telefonie.';

  @override
  String get qrScanNotReply =>
      'To nie jest kod QR odpowiedzi. Poproś drugą osobę, by pokazała odpowiedź na swoim telefonie.';

  @override
  String get qrScanOtherPayment =>
      'Ten kod należy do innej płatności. Zaczynam od nowa.';

  @override
  String get qrScanTorch => 'Latarka';

  @override
  String qrScanZoom(String factor) {
    return 'Zoom $factor×';
  }

  @override
  String get qrScanCameraDenied =>
      'Portfel nie ma dostępu do aparatu. Aby skanować, zezwól tej aplikacji na dostęp do aparatu w ustawieniach telefonu. Możesz też zamiast tego otworzyć plik.';

  @override
  String get qrScanCameraFailed =>
      'Nie udało się uruchomić aparatu. Spróbuj ponownie albo otwórz plik.';

  @override
  String get qrScanOpenSettings => 'Otwórz ustawienia';

  @override
  String get qrScanOpenFileInstead => 'Zamiast tego otwórz plik';

  @override
  String get qrScanAgain => 'Skanuj ponownie';

  @override
  String get slateWrongPaymentQr =>
      'Ta odpowiedź dotyczy innej płatności. Zeskanuj odpowiedź dla tej wysyłki.';

  @override
  String get slateScannedPaymentTitle => 'Zeskanowana płatność';

  @override
  String get slateScannedReplyTitle => 'Zeskanowana odpowiedź';

  @override
  String get slateIncomingSendHintQr =>
      'Przyjmij ją, a potem pokaż odpowiedź nadawcy.';

  @override
  String get slateAcceptedHeadlineQr => 'Przyjęto. Pokaż odpowiedź nadawcy.';

  @override
  String get methodQr => 'Płatność QR';

  @override
  String get methodQrChip => 'Kod QR';

  @override
  String get receiveTabQr => 'Kod QR';

  @override
  String get methodArtCaptionQr => 'Osobiście';

  @override
  String get methodArtLabelQr =>
      'Bezpośrednio · Płatność QR: kod przechodzi z jednego telefonu na drugi, obok';

  @override
  String get methodSendQrTitle => 'Dla telefonu obok ciebie.';

  @override
  String get methodSendQrLine =>
      'Pokaż kod na tym ekranie, potem zeskanuj odpowiedź aparatem.';

  @override
  String get methodReceiveQrTitle => 'Zeskanuj ich ekran.';

  @override
  String get methodReceiveQrLine =>
      'Przyjmij płatność, potem pokaż swoją odpowiedź w ten sam sposób.';

  @override
  String get receiveQrTitle => 'Stoisz obok nadawcy?';

  @override
  String get receiveQrBody =>
      'Zeskanuj kod na telefonie nadawcy, przyjmij płatność i pokaż swoją odpowiedź.';

  @override
  String get txQrLine =>
      'Płać lub odbieraj płatność obok siebie, z kodem na ekranie.';

  @override
  String get txQrHint =>
      'Płatność QR pokazuje płatność jako animowany kod, który drugi telefon skanuje aparatem, a odpowiedź przyjmuje w ten sam sposób. Działa tylko między telefonami obok siebie, nie wymaga połączenia między portfelami, a kod sam się ukrywa po 40 sekundach. Dodaje Płatność QR do Wyślij i Odbierz.';

  @override
  String get advTransactionFiles => 'Przesyłanie pliku';

  @override
  String get advTransactionFilesHint =>
      'Dodaje Przesyłanie pliku w Ustawienia › Transakcje: płać lub dostawaj zapłatę plikiem, który przekazujesz sam.';

  @override
  String get sendQrTitle => 'Płatność QR';

  @override
  String get sendMakeQr => 'Utwórz kod QR płatności';

  @override
  String sendQrPinReason(String amount) {
    return 'Wpisz PIN, aby utworzyć kod QR płatności na $amount.';
  }

  @override
  String get sendQrMade => 'Płatność utworzona';

  @override
  String get sendQrHint =>
      'Pokaż kod telefonowi odbiorcy, potem zeskanuj jego odpowiedź.';

  @override
  String get sendCancelRuleQr =>
      'Można anulować, dopóki nie zeskanujesz odpowiedzi.';

  @override
  String get qrStatusSendHidden => 'Pokaż to odbiorcy.';

  @override
  String get qrStatusSendShowing =>
      'Czekam, aż odbiorca zeskanuje. Potem zeskanuj jego odpowiedź.';

  @override
  String get qrStatusHiddenAgain =>
      'Ukryty. Pokaż ponownie, jeśli nie skończyli skanować.';

  @override
  String get qrStatusReplyHidden => 'Pokaż to nadawcy.';

  @override
  String get qrStatusReplyShowing => 'Czekam, aż nadawca zeskanuje.';

  @override
  String get qrStatusReceivedWaiting =>
      'Płatność odebrana. Czekam, aż nadawca zeskanuje i wyśle.';

  @override
  String qrStatusPosted(int got, int target) {
    return 'Wysłano. Potwierdzanie $got/$target';
  }

  @override
  String get qrStatusReceived => 'Odebrano.';

  @override
  String qrScanProgress(int got, int count) {
    return 'Zeskanowano $got z $count. Trzymaj kod w kadrze.';
  }

  @override
  String get qrScanReplyScanned => 'Odpowiedź zeskanowana.';

  @override
  String get qrScanPosting => 'Odpowiedź zeskanowana. Wysyłam…';

  @override
  String get qrScanPosted => 'Wysłano.';

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
  String get contactsAddressInvalidAny =>
      'To nie jest prawidłowy adres. Użyj adresu Epicbox (es5x…@epicbox.epiccash.com), adresu Link (https://…) lub adresu onion (….onion).';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsSectionNetwork => 'Serwery';

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
      'Ceny pochodzą z serwisu CoinGecko, który widzi twój adres IP.';

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
  String get settingsInvoices => 'Faktury';

  @override
  String get settingsInvoicesSubtitle => 'Kto może prosić cię o zapłatę';

  @override
  String get settingsRescan => 'Sprawdź saldo';

  @override
  String get settingsRescanFinished => 'Ponowne skanowanie zakończone';

  @override
  String get settingsRescanTitle => 'Sprawdź saldo';

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
  String get settingsCheckUpdates => 'Sprawdź aktualizacje';

  @override
  String get settingsHelp => 'Pomoc';

  @override
  String get settingsSendFeedback => 'Wyślij opinię';

  @override
  String get settingsSendFeedbackHint =>
      'Zgłoś problem lub zaproponuj twórcom pomysł. Logi idą tylko wtedy, gdy je dołączysz; fraza odzyskiwania, PIN i inne poufne dane są wcześniej usuwane.';

  @override
  String get settingsSourceCode => 'Kod źródłowy';

  @override
  String get settingsLicences => 'Licencje';

  @override
  String get licencesLead =>
      'Oprogramowanie open source w tym portfelu. Każdy składnik zachowuje własną licencję; pełne teksty są o jedno dotknięcie dalej.';

  @override
  String get licencesApp => 'Epic Cash Mobile od BT Labs: Apache-2.0.';

  @override
  String get licencesFlutter =>
      'Flutter i jego pakiety Dart: BSD 3-Clause i podobne liberalne licencje.';

  @override
  String get licencesLepic =>
      'LEPIC, biblioteka portfela Epic Cash: Apache 2.0, z forkiem secp256k1-zkp Epic Cash (CC0) i pakietami Rust na licencjach MIT lub Apache 2.0, m.in. tokio, rustls, rusqlite i blake2.';

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
  String get feedbackAttachLogs => 'Dołącz logi diagnostyczne';

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
      'Pokazuje stronę techniczną: szczegóły węzła i serwera Epicbox, wysokości bloków, pliki transakcji i logi. Gdy wyłączone, aplikacja trzyma się tego, czego potrzeba na co dzień.';

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
  String get settingsHubBackup => 'Kopia zapasowa';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'Używaj status.btlabs.uk';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Odczytuje ze status.btlabs.uk, monitora BT Labs, które węzły i serwery Epicbox są online, ich wysokość bloku i czas odpowiedzi, i pokazuje je na listach serwerów oraz na karcie stanu. Gdy wyłączone, status.btlabs.uk nie jest pytany, a listy serwerów nie pokazują stanu.';

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
  String get txStepSenderFinished => 'Nadawca sfinalizował';

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
  String get demoPinSetUpTitle => 'Przygotowywanie portfela demo';

  @override
  String get demoPinUnlockTitle => 'Otwieranie portfela demo';

  @override
  String get sendStepMethod => 'Metoda płatności';

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
  String sendRelayDown(String relay) {
    return 'Przekaźnik odbiorcy ($relay) nie odpowiada.';
  }

  @override
  String get sendListenerDown =>
      'Jeszcze bez połączenia. Możesz mimo to wysłać.';

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
    return 'Oczekiwanie na portfel: $name';
  }

  @override
  String get sendTrackWaiting => 'Oczekiwanie na portfel odbiorcy';

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
  String get sendFileWaitingReply => 'Oczekiwanie na odpowiedź';

  @override
  String get sendFileShareHint =>
      'Wyślij ten plik odbiorcy. Potem otwórz jego odpowiedź.';

  @override
  String get sendOpenReply => 'Otwórz odpowiedź';

  @override
  String get handshakePayment => 'Płatność';

  @override
  String get handshakeRequest => 'Prośba';

  @override
  String get handshakeYou => 'Ty';

  @override
  String get handshakeThem => 'Druga strona';

  @override
  String get handshakeNetwork => 'Sieć';

  @override
  String get handshakePay1 =>
      'Twój portfel wysyła płatność do przekaźnika. Twoje monety są wstrzymane.';

  @override
  String get handshakePay2 =>
      'Przekaźnik przekazuje ją dalej. Portfel drugiej strony dodaje swoją część i podpisuje.';

  @override
  String get handshakeFinish => 'Twój portfel kończy ją i wysyła do sieci.';

  @override
  String get handshakeConfirm => 'Sieć ją potwierdza.';

  @override
  String get handshakeReq1 => 'Twój portfel wysyła prośbę do przekaźnika.';

  @override
  String get handshakeReq2 =>
      'Przekaźnik przekazuje ją dalej. Druga strona ją akceptuje, a jej portfel dodaje monety i podpisuje.';

  @override
  String get handshakeRelay => 'Przekaźnik';

  @override
  String get handshakeFile => 'Przesyłanie pliku';

  @override
  String get handshakeBack =>
      'Portfel drugiej strony odsyła ją do przekaźnika.';

  @override
  String get handshakeRelayBack =>
      'Przekaźnik przekazuje ją z powrotem do twojego portfela.';

  @override
  String get handshakeFile1 =>
      'Twój portfel zapisuje plik płatności. Przekazujesz go drugiej stronie samodzielnie.';

  @override
  String get handshakeFile2 =>
      'Druga strona go otwiera. Jej portfel dodaje swoją część, podpisuje i zapisuje odpowiedź.';

  @override
  String get handshakeFile3 => 'Druga strona odsyła ci plik odpowiedzi.';

  @override
  String get handshakeFile4 => 'Otwierasz odpowiedź w swoim portfelu.';

  @override
  String get handshakePrevious => 'Poprzedni krok';

  @override
  String get handshakeLink1 =>
      'Twój portfel wysyła płatność prosto do portfela drugiej strony, przez internet lub Tor. Twoje monety są wstrzymane.';

  @override
  String get handshakeLink2 =>
      'Portfel drugiej strony dodaje swoją część, podpisuje i odpowiada w tym samym połączeniu.';

  @override
  String get handshakeQr1 => 'Pokazujesz swój kod.';

  @override
  String get handshakeQr2 => 'Druga strona skanuje go swoim portfelem.';

  @override
  String get handshakeQr3 => 'Jej portfel pokazuje kod odpowiedzi.';

  @override
  String get handshakeQr4 => 'Skanujesz go.';

  @override
  String get handshakeQr5 => 'Twój portfel wysyła płatność do sieci.';

  @override
  String get handshakeQrR1 => 'Druga strona pokazuje swój kod.';

  @override
  String get handshakeQrR2 => 'Skanujesz go swoim portfelem.';

  @override
  String get handshakeQrR3 => 'Twój portfel pokazuje kod odpowiedzi.';

  @override
  String get handshakeQrR4 => 'Druga strona go skanuje.';

  @override
  String get handshakeQrR5 => 'Jej portfel wysyła płatność do sieci.';

  @override
  String get handshakeNext => 'Następny krok';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Przekaźnik odbiorcy ($relay) jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dnia.',
      many:
          'Przekaźnik odbiorcy ($relay) jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      few:
          'Przekaźnik odbiorcy ($relay) jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dni.',
      one:
          'Przekaźnik odbiorcy ($relay) jej nie przyjął. Kwota jest wstrzymana, dopóki jej nie anulujesz, najwyżej $days dzień.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Przekaźnik odbiorcy ($relay) jej nie przyjął. Sprawdź Portfel przed ponownym wysłaniem.';
  }

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
      'Zapłać na demo znajomego albo otwórz tę stronę w innej przeglądarce lub w oknie prywatnym.';

  @override
  String get demoGuideOpenSend => 'Przejdź do Wyślij';

  @override
  String get demoGuideAsking =>
      'Prośba do testowego kranu. To może potrwać minutę.';

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
  String get receiveTorAddressLabel => 'Adres Link · Tor';

  @override
  String get receiveTorQrLabel => 'Kod QR twojego adresu Tor';

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
  String get torStatePublishing => 'Publikowanie twojego adresu Tor…';

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
  String get tourPhoneSemantics => 'Przewodnik po portfelu';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current z $total';
  }

  @override
  String get tourPhoneSkip => 'Pomiń';

  @override
  String get tourPhoneBack => 'Wstecz';

  @override
  String get tourPhoneNext => 'Dalej';

  @override
  String get tourPhoneWalletTitle => 'Portfel';

  @override
  String get tourPhoneWalletText =>
      'Twoje saldo, a pod nim ikony węzła, Epicbox i Tora. To, co jeszcze się potwierdza, jest w kafelkach poniżej.';

  @override
  String get tourPhoneSendTitle => 'Wyślij';

  @override
  String get tourPhoneSendText =>
      'Wklej lub zeskanuj adres albo wybierz kontakt. Epicbox płaci na adres; QR pokazuje kod telefonowi obok ciebie. Więcej metod: Ustawienia › Transakcje. Najpierw jest podgląd.';

  @override
  String get tourPhoneReceiveTitle => 'Odbierz';

  @override
  String get tourPhoneReceiveText =>
      'Twój adres Epicbox. Udostępnij go, aby dostać zapłatę. Karta Plik służy do plików transakcji do podpisania lub dokończenia.';

  @override
  String get tourPhoneActivityTitle => 'Aktywność';

  @override
  String get tourPhoneActivityText =>
      'Każda płatność z postępem i szczegółami. Dotknij jednej, aby ją otworzyć.';

  @override
  String get tourPhoneContactsTitle => 'Kontakty';

  @override
  String get tourPhoneContactsText =>
      'Zapisane adresy z nazwami. Wyślij wybiera stąd.';

  @override
  String get tourPhoneInvoicesTitle => 'Faktury';

  @override
  String get tourPhoneInvoicesText =>
      'Zapłać fakturę, którą ktoś przysłał, albo poproś kogoś o płatność. Karty przełączają między jednym a drugim.';

  @override
  String get tourPhonePrivacyTitle => 'Prywatność i sieć';

  @override
  String get tourPhonePrivacyText =>
      'Z jakiego węzła i serwera Epicbox korzysta portfel oraz przełącznik Tora. Dotknij serwera, aby go zmienić.';

  @override
  String get tourPhoneAdvancedTitle => 'Zaawansowane';

  @override
  String get tourPhoneAdvancedText =>
      'Tryb tylko Tor, wyjścia i szczegóły techniczne są tutaj. Włącz to, czego potrzebujesz.';

  @override
  String get tourPhoneHelpTitle => 'Pomoc';

  @override
  String get tourPhoneHelpText =>
      'Przeszukaj tematy albo wyślij opinię. „Pokaż przewodnik ponownie” jest na dole listy.';

  @override
  String get tourPhoneShowAgain => 'Pokaż przewodnik ponownie';

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
  String get outputsStrategyHint =>
      'Które wyjścia wydaje wysyłka. Najmniejsze wydaje jak najmniej małych wyjść, więc pozostała część salda zostaje do wydania, gdy reszta się potwierdza. Wszystkie wydaje wszystkie wyjścia do wydania i zwraca jedno wyjście reszty: wszystko jest zablokowane do potwierdzenia, a potem zostaje mniej, ale większych wyjść.';

  @override
  String get outputsSmallest => 'Najmniejsze';

  @override
  String get outputsAll => 'Wszystkie';

  @override
  String get outputsSmallestText =>
      'Wydaje jak najmniej małych wyjść; pozostała część salda jest do wydania, gdy reszta się potwierdza.';

  @override
  String get outputsAllText =>
      'Wydaje wszystkie wyjścia do wydania i zwraca jedno wyjście reszty. Wszystko jest zablokowane do potwierdzenia; potem jest mniej, ale większych wyjść.';

  @override
  String get outputsSplitChange => 'Podziel resztę';

  @override
  String get outputsSplitChangeText =>
      'Gdy po wysyłce zostałyby mniej niż 3 wyjścia do wydania, a reszta wynosi co najmniej 1 EPIC, reszta wraca jako maksymalnie 4 wyjścia, więc następne wysyłki nie czekają na potwierdzenia. Każde dodatkowe wyjście kosztuje 0,004 EPIC.';

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
    return 'Potwierdzenia potrzebne do wydania: $need.';
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
    return 'Wydaje $spent ($amount) i tworzy $made po około $each. Zwykła transakcja sieciowa do tego portfela, potwierdzona po 3 blokach jak każda wysyłka; wszystko do wydania jest do tego czasu zablokowane. Więcej wyjść pozwala następnym wysyłkom wyjść bez czekania na resztę z poprzednich.';
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
    return 'Podział rozpoczęty, nowe wyjścia: $count; potwierdzenie za około 3 bloki';
  }

  @override
  String get outputsConsolidateStarted =>
      'Scalanie rozpoczęte: jedno wyjście, potwierdzenie za około 3 bloki';

  @override
  String get outputsAdvanced => 'Zarządzaj wyjściami';

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
  String get contactsNoteHeading => 'Notatka';

  @override
  String get contactsShowCode => 'Pokaż kod';

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
  String get invoicesSentEmpty => 'Brak wysłanych próśb';

  @override
  String get invoicesSentEmptyCaption =>
      'Prośbą o płatność prosisz kogoś, by zapłacił ci określoną kwotę.';

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
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer otrzyma prośbę o zapłatę $amount. Prośba wygasa za 24 h.';
  }

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
  String get netStatusConnected => 'Połączono';

  @override
  String get netStatusNotConnected => 'Brak połączenia';

  @override
  String get serverUpNotConnected => 'Serwer działa · brak połączenia';

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
  String get serverMenuDelete => 'Usuń';

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
  String get netStatusDirectOpenHint => 'Otwiera adres odbioru Link';

  @override
  String get netStatusOpenHint => 'Pokazuje serwery';

  @override
  String get serverNodeTitle => 'Węzeł';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'Znajdź węzeł';

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
  String get serverRelayWarning =>
      'Twój adres zawiera ten serwer. Zmiana zmienia adres; nadawcy potrzebują nowego.';

  @override
  String get serverOtherRelay => 'Inny serwer, host lub host:port';

  @override
  String get serverMyListNote => 'Używany teraz i dodane przez ciebie.';

  @override
  String get serverPublicNote => 'Stuknij, aby przełączyć.';

  @override
  String get serverOtherNode => 'Inny węzeł, host lub host:port';

  @override
  String get serverOtherNodeInvalid =>
      'Wpisz adres węzła, np. node.example.com:3413';

  @override
  String get serverAdd => 'Dodaj';

  @override
  String get serverAddedNode => 'Dodano do: Moje węzły.';

  @override
  String get serverAddedRelay => 'Dodano do: Moje serwery.';

  @override
  String serverDeleted(String host) {
    return 'Usunięto $host.';
  }

  @override
  String get serverAlreadyInUse => 'Już używany.';

  @override
  String get serverNoMatch => 'Brak wyników.';

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
  String get methodDirectHttp => 'Link · HTTP';

  @override
  String get methodDirectTor => 'Link · Tor';

  @override
  String get methodFile => 'Przesyłanie pliku';

  @override
  String get methodShortHttp => 'Link · HTTP';

  @override
  String get methodShortTor => 'Link · Tor';

  @override
  String get methodShortQr => 'Bezpośrednio · QR';

  @override
  String get methodShortFile => 'Bezpośrednio · Plik';

  @override
  String get methodGroupHttp => 'HTTP';

  @override
  String get methodGroupTor => 'Tor';

  @override
  String get methodDirectQr => 'Bezpośrednio · Płatność QR';

  @override
  String get methodDirectFile => 'Bezpośrednio · Przesyłanie pliku';

  @override
  String get methodDirectFamily => 'Bezpośrednio';

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
      'Link · HTTP: płatność trafia prosto do portfela odbiorcy, który musi być otwarty';

  @override
  String get methodArtLabelTor =>
      'Link · Tor: płatność trafia prosto do portfela odbiorcy, przez sieć Tor';

  @override
  String get methodArtLabelFile =>
      'Bezpośrednio · Przesyłanie pliku: plik transakcji jest przekazywany, wraca plik odpowiedzi, potem nadawca finalizuje';

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
  String get methodReceiveFileTitle => 'Wymiana pliku w obie strony.';

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
  String get sendSwitchedHttp => 'Link · HTTP';

  @override
  String get sendSwitchedEpicbox => 'Przez Epicbox';

  @override
  String get sendSwitchedTorAnnounce =>
      'Adres Tor. Ustawiono metodę Link · Tor.';

  @override
  String get sendSwitchedHttpAnnounce =>
      'Adres HTTP. Ustawiono metodę Link · HTTP.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Adres Epicbox. Ustawiono metodę Epicbox.';

  @override
  String get sendReviewMethodHttp => 'Link · HTTP, prosto do portfela';

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
  String get deskInvReqPosted => 'Opublikowano';

  @override
  String deskInvConfirming(int count, int total) {
    return 'Potwierdzanie $count z $total';
  }

  @override
  String get deskInvCompleted => 'Zakończono';

  @override
  String get deskInvReqNotPosted => 'Nie opublikowano';

  @override
  String get deskInvDeclined => 'Odrzucono';

  @override
  String get deskInvExpired => 'Wygasła';

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
  String get deskInvPayDelivered => 'Czeka na publikację';

  @override
  String get deskInvPayPosted => 'Opublikowane przez serwis';

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
  String get deskInvFailed =>
      'To się nie udało. Nic się nie zmieniło; spróbuj ponownie.';

  @override
  String get deskInvHowItWorks => 'Jak działają faktury';

  @override
  String get deskInvIssuerSoon => 'Wkrótce';

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
      'Nic nie opuszcza twojego portfela: płacący płaci tę kwotę plus własną opłatę.';

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
  String get deskInvIssuerRelayDown =>
      'Serwer Epicbox nie odpowiada, więc teraz nie można wysłać faktury.';

  @override
  String get deskInvIssuerNotDelivered =>
      'Faktura nie dotarła do serwera Epicbox. Nic nie wysłano. Spróbuj ponownie.';

  @override
  String get deskInvIssuerEmpty =>
      'Nie wystawiono jeszcze faktur. Faktura prosi kontakt lub serwis o zapłatę; niczego nie wydaje.';

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
    return '$payer nie może już jej zapłacić.';
  }

  @override
  String get deskInvIssuerKeep => 'Zostaw';

  @override
  String get deskInvIssuerWithdrawn => 'Fakturę wycofano.';

  @override
  String get deskInvIssuerRepost => 'Opublikuj ponownie';

  @override
  String get deskInvIssuerReposted => 'Płatność opublikowano ponownie.';

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
    return 'Zapłacono ($payer). Twój portfel sfinalizował płatność i opublikował ją.';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return 'Dostarczono do skrzynki płacącego ($payer). Nic nie jest zapłacone, dopóki tego nie zatwierdzi.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Kopiuj ID slate';

  @override
  String get deskInvIssuerStepIssued => 'Wystawiono';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return 'Zapłata od $payer: $amount EPIC.';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return 'Faktura odrzucona przez: $payer.';
  }

  @override
  String get deskInvNoticeIssuedExpired =>
      'Wystawiona przez ciebie faktura wygasła bez zapłaty.';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return 'Faktura od $service została wycofana przed twoją odpowiedzią.';
  }

  @override
  String get deskInvNoticeExpired => 'Faktura wygasła przed twoją odpowiedzią.';

  @override
  String get deskInvNoticeUnknownPayment =>
      'Nadeszła płatność za rachunek, którego to urządzenie nie wystawiło. Przez dobę czeka na przekaźniku na Twoje drugie urządzenie z tym portfelem: otwórz tam portfel, aby ją dokończyć.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Nadeszła odpowiedź na płatność, której to urządzenie nie wysłało. Przez dobę czeka na przekaźniku na Twoje drugie urządzenie z tym portfelem: otwórz tam portfel, aby ją dokończyć.';

  @override
  String get deskInvPayerWaitingHead => 'Czeka na ciebie';

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
  String get deskInvPayerEmptyTitle => 'Żadne faktury nie czekają';

  @override
  String get deskInvPayerEmptyText =>
      'Gdy sparowany kontakt, któremu zezwolisz, poprosi o zapłatę, prośba pojawi się tutaj i nic nie zostanie zapłacone bez twojej zgody.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Twoja płatność dla: $service nie została dostarczona';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Jest podpisana i zapisana na tym urządzeniu; środki pozostają zablokowane. Ponów wysyła ją jeszcze raz bez ponownego zatwierdzania.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return 'Serwis $service wycofał opłaconą fakturę';
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
  String get deskInvPayerSafetyTitle =>
      'Płać tylko faktury, których się spodziewasz';

  @override
  String get deskInvPayerSafetyText =>
      'Faktura nigdy nie dodaje pieniędzy do portfela. Zatwierdzenie jej wysyła pieniądze.';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return 'Ta sama kwota została zapłacona dla $service $ago temu';
  }

  @override
  String get deskInvPayerSameBillText =>
      'Zanim zapłacisz, sprawdź, czy to nowa faktura.';

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
  String deskInvPayerMessageCaption(String name) {
    return 'Napisane przez: $name. Twój portfel tego nie sprawdza.';
  }

  @override
  String get deskInvPayerPaysTo => 'Płatność dla';

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
      'Ta faktura została odrzucona. Nic nie zapłacono.';

  @override
  String get deskInvPayerBack => 'Wróć do Faktur';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return 'Zapłacić $amount EPIC + $fee opłaty dla: $service?';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC opuści twój portfel. Wpisz hasło portfela, aby zatwierdzić.';
  }

  @override
  String get deskInvPayerPassword => 'Hasło portfela';

  @override
  String get deskInvPayerWrongPassword =>
      'Nieprawidłowe hasło. Nic nie zapłacono.';

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
      'Anulowanie odblokowuje tutaj twoje środki. Serwis nadal ma twoją podpisaną płatność, więc może ją jeszcze sfinalizować, dopóki te środki nie zostaną ponownie wydane.';

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
      'Czyni anulowanie ostatecznym: podpisanej kopii w serwisie nie da się już zrealizować. Kosztuje opłatę sieciową.';

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
  String get deskInvSetExpiry => 'Czas na zapłatę';

  @override
  String get deskInvSetExpiryHint =>
      'Jak długo wystawiona faktura pozostaje do zapłaty i jak długo otrzymana na ciebie czeka. Najwyżej 48 godzin.';

  @override
  String deskInvSetHours(int hours) {
    return '$hours godz.';
  }

  @override
  String get deskInvSetReceiveHint =>
      'Poproś sparowany kontakt o zapłatę lub zapisz prośbę jako plik.';

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
      one: '$count temat',
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
  String get methodDirect => 'Link';

  @override
  String get methodLinkPayment => 'Płatność linkiem';

  @override
  String get methodDirectShape => 'http://host:3415 lub xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Portfel odbiorcy musi być otwarty. Adres onion działa przez Tor.';

  @override
  String get methodArtLabelDirect =>
      'Link: płatność trafia prosto do portfela odbiorcy, który musi być otwarty';

  @override
  String methodArtSpokenLink(String method) {
    return '$method: płatność trafia prosto do portfela odbiorcy, który musi być otwarty';
  }

  @override
  String methodArtSpokenQr(String method) {
    return '$method: kod przechodzi z jednego telefonu na drugi, obok';
  }

  @override
  String methodArtSpokenFile(String method) {
    return '$method: plik transakcji jest przekazywany, wraca plik odpowiedzi, potem nadawca finalizuje';
  }

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
  String get sendSwitchedDirect => 'Adres Link';

  @override
  String get sendSwitchedDirectAnnounce =>
      'Adres Link. Metoda ustawiona na Link.';

  @override
  String get sendDirectAddressShape =>
      'Adres Link zaczyna się od http:// lub https:// albo kończy na .onion.';

  @override
  String get torNotOverTor => 'Nie przez Tor';

  @override
  String get torNeeds => 'Wymaga Tora.';

  @override
  String get torTurnOn => 'Włącz Tor';

  @override
  String get torTurnOff => 'Wyłącz Tor';

  @override
  String get torNotConnectedNotice => 'Tor nie jest połączony.';

  @override
  String get torWaiting => 'Oczekiwanie na Tor';

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
      'Ruch sieciowy przechodzi przez sieć Tor. Tor ukrywa adres internetowy portfela: każde połączenie przechodzi przez kilka przekaźników prowadzonych przez wolontariuszy, więc żaden serwer nie dowiaduje się, gdzie jest portfel. Powiadomienia są wyłączone, gdy Tor jest włączony. Przyjmowanie płatności na adres Tor to przełącznik Link · Tor w Transakcje.';

  @override
  String get receiveTabDirect => 'Link';

  @override
  String get receiveDirectNeedsTor =>
      'Odbieranie przez Link · Tor wymaga Tora.';

  @override
  String get receiveDirectMeanwhile =>
      'Do tego czasu nadawcy używają adresu Epicbox.';

  @override
  String get receiveHttpTitle => 'Adres Link · HTTP';

  @override
  String get receiveHttpLanLine =>
      'Dla portfeli w tej sieci Wi-Fi, gdy ten portfel jest otwarty.';

  @override
  String get receiveHttpNoNetwork =>
      'Brak sieci Wi-Fi. Nie ma adresu do podania.';

  @override
  String get receiveHttpOffWhileTor => 'Wyłączone, gdy Tor jest włączony.';

  @override
  String receiveHttpPortInUse(String port) {
    return 'Port $port jest używany przez inny program.';
  }

  @override
  String get receiveHttpFailed => 'Nie udało się uruchomić.';

  @override
  String get receiveHttpShowQr => 'Pokaż QR';

  @override
  String get receiveHttpHideQr => 'Ukryj QR';

  @override
  String get receiveHttpQrLabel => 'Kod QR adresu Link · HTTP';

  @override
  String get netStatusOverTor => 'przez Tor';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsNotificationsHint =>
      'Informuje, gdy przychodzi płatność lub faktura, kiedy aplikacja jest zamknięta. Korzysta z Epicboxa BT Labs i usługi powiadomień Google; wiadomość tylko budzi aplikację i nie zawiera kwoty, nadawcy ani adresu. Wyłączone, gdy Tor jest włączony, bo rejestracja zdradziłaby adres telefonu.';

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
  String get pushNoticeAvailable =>
      'Powiadomienia są w Ustawieniach › Zaawansowane.';

  @override
  String get torWayOver => 'Przez Tor';

  @override
  String get torWayWaiting => 'Oczekiwanie na Tor';

  @override
  String get torWayNotConnected => 'Tor nie jest połączony.';

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
      many: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
      few: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
      one: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSomethingWrong => 'Coś poszło nie tak';

  @override
  String get deskErrWrongPassword => 'Nieprawidłowe hasło';

  @override
  String get deskErrPhraseInvalid => 'Nieprawidłowa fraza odzyskiwania';

  @override
  String get deskErrWalletExists => 'Portfel już istnieje';

  @override
  String get deskErrWalletNotFound => 'Nie znaleziono portfela';

  @override
  String get deskErrNodeNotAnswering => 'Węzeł nie odpowiada';

  @override
  String get deskErrNotEnoughFunds => 'Za mało środków';

  @override
  String get deskErrNotTxFile => 'To nie jest plik transakcji tego portfela';

  @override
  String get deskErrEpicboxUnreachable => 'Serwer Epicbox jest nieosiągalny';

  @override
  String get deskErrNotHttpAddress => 'To nie jest adres http(s)';

  @override
  String get deskErrPlainHttp => 'Nie potwierdzono zwykłego HTTP';

  @override
  String get deskErrNotOnion => 'To nie jest adres onion';

  @override
  String get deskErrTorNotConnected => 'Tor nie jest połączony';

  @override
  String get deskErrOnionUnreachable =>
      'Portfel odbiorcy jest nieosiągalny przez Tor';

  @override
  String get deskErrWalletBusy =>
      'Portfel jest zajęty. Spróbuj ponownie za chwilę.';

  @override
  String get deskErrDbDamaged =>
      'Baza danych portfela uszkodzona, trwa odbudowa';

  @override
  String get deskErrPaymentExpired => 'Płatność wygasła';

  @override
  String get deskErrInvoiceNotFound => 'Nie znaleziono faktury';

  @override
  String get deskErrAmountMismatch => 'Kwota różni się od faktury';

  @override
  String get deskErrInvoicePaid => 'Faktura jest już zapłacona';

  @override
  String get deskErrInvoiceLocked =>
      'Faktura zablokowana do późniejszego bloku';

  @override
  String get deskErrInvoiceChanged => 'Faktura się zmieniła';

  @override
  String get deskErrNotAccepted => 'Nie przyjęto';

  @override
  String deskErrNotAcceptedDetail(String detail) {
    return 'Nie przyjęto: $detail';
  }

  @override
  String get deskErrDisk => 'Błąd dysku';

  @override
  String deskErrDiskDetail(String detail) {
    return 'Błąd dysku: $detail';
  }

  @override
  String get deskErrTorMissing => 'Ta wersja nie zawiera Tora';

  @override
  String get deskErrTorNetwork => 'Brak połączenia z siecią Tor';

  @override
  String get deskErrTorClock => 'Zegar komputera jest źle ustawiony';

  @override
  String get deskErrOnionNotPublished => 'Adres onion nie jest opublikowany';

  @override
  String get deskErrTorStart => 'Tor się nie uruchomił';

  @override
  String get deskErrTorStopped => 'Tor się zatrzymał';

  @override
  String get deskErrScanRunning => 'Skanowanie już trwa.';

  @override
  String get deskErrCancelRefused => 'Nie anulowano: węzeł ma już tę płatność.';

  @override
  String get deskErrWalletLocked => 'Portfel jest zablokowany';

  @override
  String get deskErrWalletLocking => 'Portfel się blokuje';

  @override
  String deskErrDbDamagedDetail(String detail) {
    return 'Baza danych portfela uszkodzona. $detail';
  }

  @override
  String deskErrWalletClosed(String detail) {
    return 'Portfel zamknięty: $detail. Odblokuj go ponownie.';
  }

  @override
  String deskErrNotChanged(String detail) {
    return 'Nie zmieniono: $detail';
  }

  @override
  String deskErrPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Użyj co najmniej $count znaku',
      many: 'Użyj co najmniej $count znaków',
      few: 'Użyj co najmniej $count znaków',
      one: 'Użyj co najmniej $count znaku',
    );
    return '$_temp0';
  }

  @override
  String get deskErrWalletNotListed => 'Portfela nie ma na liście';

  @override
  String get deskErrUpdateApp => 'Zaktualizuj aplikację, aby zmienić listę';

  @override
  String get deskErrListNotChanged => 'Nie zmieniono listy portfeli';

  @override
  String get deskErrOpenToDelete => 'Otwórz portfel, aby go usunąć';

  @override
  String get deskErrEnterPassword => 'Wpisz hasło';

  @override
  String get deskErrFolderNotFound => 'Nie znaleziono folderu portfela';

  @override
  String deskErrAlreadyHere(String name) {
    return 'Ten portfel już tu jest: $name';
  }

  @override
  String get deskErrTestNet =>
      'Portfel sieci testowej. Importować można tylko portfele Mainnet.';

  @override
  String get deskErrWalletInApp => 'Ten portfel już jest w aplikacji.';

  @override
  String get deskErrWalletNotFoundSearch =>
      'Nie znaleziono portfela. Wyszukaj ponownie.';

  @override
  String get deskErrEnterOldPassword => 'Wpisz stare hasło';

  @override
  String deskErrOldPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Stare hasło jest za krótkie. Wybierz nowe, co najmniej $count znaku.',
      many:
          'Stare hasło jest za krótkie. Wybierz nowe, co najmniej $count znaków.',
      few:
          'Stare hasło jest za krótkie. Wybierz nowe, co najmniej $count znaki.',
      one:
          'Stare hasło jest za krótkie. Wybierz nowe, co najmniej $count znak.',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSeedUnreadable =>
      'Nie udało się odczytać pliku wallet.seed';

  @override
  String get deskErrNotSeedFile => 'To nie jest plik wallet.seed';

  @override
  String deskErrAlreadyInApp(String name) {
    return 'Już jest w aplikacji jako $name';
  }

  @override
  String get deskErrWrongOldPassword => 'Nieprawidłowe stare hasło';

  @override
  String get deskErrListNotSaved => 'Nie zapisano listy portfeli';

  @override
  String get deskErrProofSeedRead => 'Odczytano seed';

  @override
  String get deskErrProofWalletCreated => 'Utworzono portfel';

  @override
  String deskErrProofContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodano $count kontaktu',
      many: 'Dodano $count kontaktów',
      few: 'Dodano $count kontakty',
      one: 'Dodano $count kontakt',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofNode(String name) {
    return 'Dodano węzeł $name do listy węzłów';
  }

  @override
  String deskErrProofEpicbox(String old, String current) {
    return 'Starsza aplikacja używała serwera Epicbox $old; ta używa $current';
  }

  @override
  String get deskErrProofFolderUnchanged => 'Stary folder bez zmian';

  @override
  String get deskErrProofFolderChanged =>
      'Stary folder zmieniony przez inny program';

  @override
  String deskErrProofHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Historia: $count transakcji',
      many: 'Historia: $count transakcji',
      few: 'Historia: $count transakcje',
      one: 'Historia: $count transakcja',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofHistoryAlready => 'Historia już zaimportowana';

  @override
  String get deskErrProofHistoryNone =>
      'Brak historii w starym folderze; skanowanie odtworzy saldo';

  @override
  String get deskErrProofHistoryOld =>
      'Historii z Epic Wallet 5.3 lub starszego nie da się odczytać; skanowanie odtworzy saldo';

  @override
  String get deskErrProofHistoryBusy =>
      'Nie zaimportowano historii: starszy portfel jest uruchomiony. Zostanie zaimportowana przy następnym odblokowaniu';

  @override
  String get deskErrProofHistoryOther =>
      'Nie zaimportowano historii: należy do innego portfela';

  @override
  String get deskErrProofHistoryUnreadable =>
      'Nie zaimportowano historii: nie udało się odczytać starej bazy danych; skanowanie odtworzy saldo';

  @override
  String get deskErrNodeNoAnswer => 'Węzeł nie odpowiedział';

  @override
  String get deskErrNotPosted => 'Nie opublikowano';

  @override
  String get deskErrNotEpicboxAddress => 'To nie jest adres Epicbox';

  @override
  String get deskErrFileNotSaved =>
      'Nie zapisano pliku. Płatność czeka w Aktywności; anuluj ją tam, aby odblokować środki.';

  @override
  String get deskErrTorOffSend =>
      'Tor jest wyłączony. Włącz Tor, aby wysłać na adres onion.';

  @override
  String get deskErrTorConnecting =>
      'Tor wciąż się łączy. Spróbuj ponownie za chwilę.';

  @override
  String get deskErrRecipientNoAnswer =>
      'Portfel odbiorcy nie odpowiedział albo odmówił.';

  @override
  String get deskErrRecipientNoAnswerWaits =>
      'Portfel odbiorcy nie odpowiedział albo odmówił. Płatność czeka w Aktywności; anuluj ją tam, aby odblokować środki.';

  @override
  String get deskErrNotDelivered =>
      'Nie dostarczono. Płatność czeka w Aktywności; anuluj ją tam, aby odblokować środki.';

  @override
  String get deskErrInterruptedLock =>
      'Przerwano przez zablokowanie. Płatność mogła wyjść: po odblokowaniu sprawdź Aktywność.';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail. Płatność czeka w Aktywności; anuluj ją tam, aby odblokować środki.';
  }

  @override
  String get deskErrNodeRefused =>
      'Podpisana przez oba portfele, ale węzeł ją odrzucił. Anuluj ją w Aktywności, aby odblokować środki.';

  @override
  String get deskErrFileNotReadable => 'Nie można odczytać pliku';

  @override
  String get deskErrNotTxFile2 => 'To nie jest plik transakcji';

  @override
  String get deskErrResponseNotSaved => 'Nie zapisano pliku odpowiedzi';

  @override
  String get deskErrCannotCancel => 'Tej płatności nie można anulować';

  @override
  String get deskErrNoLocalNode => 'Ta wersja nie zawiera węzła lokalnego';

  @override
  String get deskErrLocalNodeStopped => 'Węzeł lokalny zatrzymany';

  @override
  String get deskErrNotChangedLocked =>
      'Nie zmieniono: portfel został zablokowany';

  @override
  String deskErrLocalNodeNotStarted(String detail) {
    return 'Nie uruchomiono węzła lokalnego: $detail';
  }

  @override
  String get deskErrUnknown => 'nieznany błąd';

  @override
  String get deskErrNotServerName => 'To nie jest nazwa serwera';

  @override
  String deskErrPortInUse(int port) {
    return 'Port $port jest zajęty';
  }

  @override
  String deskErrPortUnavailable(int port) {
    return 'Port $port jest niedostępny';
  }

  @override
  String get deskErrStoppedWithError => 'Zatrzymano z błędem';

  @override
  String get deskErrPasswordNotChanged =>
      'Nie zmieniono hasła. Portfel nadal otwiera obecne hasło.';

  @override
  String get deskErrNothingToSpend => 'Nie ma czego wydać';

  @override
  String get deskTorLineOff => 'Wyłączony';

  @override
  String get deskTorLineReady => 'Gotowy';

  @override
  String deskTorLineSendsWork(String problem) {
    return '$problem. Wysyłanie działa.';
  }

  @override
  String get deskTorLinePublishing => 'Publikowanie adresu onion…';

  @override
  String deskTorLineConnecting(int percent) {
    return 'Łączenie z Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'Kopia innego portfela';

  @override
  String get deskErrHistOtherChain => 'Niewłaściwa sieć';

  @override
  String get deskErrHistNotOurs => 'To nie jest kopia historii';

  @override
  String get deskErrHistNewer => 'Nowszy plik';

  @override
  String get deskErrHistDamaged => 'Plik uszkodzony';

  @override
  String get deskErrOldGui => 'Starszy Epic Wallet';

  @override
  String get deskErrOldCli => 'Program epic';

  @override
  String get deskErrOldPicked => 'Wybrane foldery';

  @override
  String get deskErrHistTooLarge => 'Plik jest za duży jak na kopię historii.';

  @override
  String deskErrHistChains(String from, String to) {
    return 'Plik pochodzi z sieci $from; ten portfel działa w sieci $to.';
  }

  @override
  String get deskErrHistOtherWalletText =>
      'Plik wyeksportowano z portfela o innej frazie odzyskiwania.';

  @override
  String get deskErrHistNewerText =>
      'Ten plik utworzyła nowsza wersja aplikacji. Zaktualizuj aplikację, a potem go zaimportuj.';

  @override
  String get deskErrHistDamagedText =>
      'Plik jest niekompletny albo został zmieniony.';

  @override
  String get deskErrHistNotOursText =>
      'Tego pliku nie utworzył Epic Cash Desktop ani Epic Cash Mobile.';

  @override
  String get deskDataHttpEnter => 'Wpisz adres odbiorcy';

  @override
  String get deskDataHttpScheme => 'Zacznij od https:// lub http://';

  @override
  String get deskDataHttpOnion => 'Adresy onion wymagają Tora';

  @override
  String get deskDataHttpNot => 'To nie jest adres http(s)';

  @override
  String get deskDataHttpPort => 'Port musi być od 1 do 65535';

  @override
  String get deskDataUpdTimeout => 'Serwer aktualizacji nie odpowiedział.';

  @override
  String get deskDataUpdUnreachable =>
      'Nie udało się połączyć z serwerem aktualizacji.';

  @override
  String deskDataUpdStatus(int status) {
    return 'Serwer aktualizacji zwrócił $status.';
  }

  @override
  String get deskDataUpdNone =>
      'Nie opublikowano jeszcze informacji o aktualizacjach wersji desktopowej.';

  @override
  String get deskNodeSynced => 'Zsynchronizowany';

  @override
  String get deskNodeBehind => 'Opóźniony';

  @override
  String get deskNodeNotAnswering => 'Nie odpowiada';

  @override
  String get deskNodeChecking => 'Sprawdzanie';

  @override
  String get deskNodeStarting => 'Uruchamianie';

  @override
  String get deskNodeSyncing => 'Synchronizacja';

  @override
  String get deskNodeStalled => 'Zatrzymany';

  @override
  String get deskNodeFailed => 'Błąd';

  @override
  String get deskNodeStopped => 'Wyłączony';

  @override
  String get deskNodeMarkerNoAnswer => 'brak odpowiedzi';

  @override
  String deskNodeMarkerBehind(String count) {
    return '$count w tyle';
  }

  @override
  String get deskNodeMarkerStarting => 'uruchamianie';

  @override
  String get deskNodeMarkerStalled => 'zatrzymany';

  @override
  String get deskNodeMarkerFailed => 'błąd';

  @override
  String get deskNodeMarkerStopped => 'wyłączony';

  @override
  String deskNodeHostSince(String host, String time) {
    return '$host · od $time';
  }

  @override
  String get deskNodeNotAnsweringLine => 'Węzeł nie odpowiada.';

  @override
  String deskNodeLatency(String ms) {
    return '$ms ms';
  }

  @override
  String deskNodeLatencyOverTor(String ms) {
    return '$ms ms przez Tor';
  }

  @override
  String deskNodeNewerOut(String version) {
    return 'Dostępna wersja $version';
  }

  @override
  String get deskNodeBehindLine => 'Opóźniony względem sieci; nadrabia.';

  @override
  String deskNodeHeightOf(String height, String total) {
    return '$height z $total';
  }

  @override
  String get deskNodeAtTip => 'na bieżąco';

  @override
  String get deskNodeLocal => 'Węzeł lokalny';

  @override
  String get deskNodeConnectingPeers => 'Łączenie z peerami';

  @override
  String deskNodeUsingUntilSynced(String host) {
    return 'Do czasu synchronizacji używany jest $host.';
  }

  @override
  String get deskNodeNothingUntilSynced =>
      'Do czasu synchronizacji nie można nic wysłać.';

  @override
  String deskNodePeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peera',
      many: '$count peerów',
      few: '$count peery',
      one: '$count peer',
    );
    return '$_temp0';
  }

  @override
  String deskNodeRunning(String duration) {
    return 'działa $duration';
  }

  @override
  String deskNodeStillUsing(String host) {
    return 'Nadal używany jest $host; węzeł lokalny wkrótce go zastąpi.';
  }

  @override
  String get deskNodeNoProgress =>
      'Brak postępu od 5 min. Raz już uruchomiono ponownie.';

  @override
  String deskNodeUsingMeanwhile(String host) {
    return 'W międzyczasie używany jest $host.';
  }

  @override
  String get deskNodeStartIt => 'Uruchom go w Ustawienia › Węzeł.';

  @override
  String get deskNodeFailPort => 'port 3413 zajmuje inny program';

  @override
  String get deskNodeFailDisk => 'za mało miejsca na dysku';

  @override
  String get deskNodeFailMissing => 'brak programu węzła';

  @override
  String get deskNodeFailExited => 'program węzła się zatrzymał';

  @override
  String deskNodeFailExitedCode(String code) {
    return 'program węzła się zatrzymał (kod wyjścia $code)';
  }

  @override
  String get deskNodeFailDefault => 'węzeł się nie uruchomił';

  @override
  String get deskNodeStageWaiting => 'łączenie z peerami';

  @override
  String get deskNodeStageHeaders => 'nagłówki';

  @override
  String get deskNodeStageChainDownload => 'pobieranie stanu łańcucha';

  @override
  String get deskNodeStageKernels => 'sprawdzanie kerneli';

  @override
  String get deskNodeStageRangeProofs => 'sprawdzanie dowodów zakresu';

  @override
  String get deskNodeStageProcessing => 'przetwarzanie stanu łańcucha';

  @override
  String get deskNodeStageBlocks => 'bloki';

  @override
  String get deskNodeStageCompacting => 'kompaktowanie';

  @override
  String get deskNodeStageStopping => 'zatrzymywanie';

  @override
  String get deskNodeStageSyncing => 'synchronizacja';

  @override
  String get deskNodeLineWaiting => 'Łączenie z peerami';

  @override
  String deskNodeLineHeaders(String done, String total) {
    return 'Nagłówki · $done z $total';
  }

  @override
  String get deskNodeLineHeadersBare => 'Nagłówki';

  @override
  String deskNodeLineChain(String done, String total) {
    return 'Stan łańcucha · $done z $total GB';
  }

  @override
  String get deskNodeLineChainBare => 'Stan łańcucha';

  @override
  String deskNodeLineKernels(String done, String total) {
    return 'Sprawdzanie kerneli · $done z $total mln';
  }

  @override
  String get deskNodeLineKernelsBare => 'Sprawdzanie kerneli';

  @override
  String deskNodeLineRangeProofs(String done, String total) {
    return 'Sprawdzanie dowodów zakresu · $done z $total mln';
  }

  @override
  String get deskNodeLineRangeProofsBare => 'Sprawdzanie dowodów zakresu';

  @override
  String get deskNodeLineProcessing => 'Przetwarzanie stanu łańcucha';

  @override
  String deskNodeLineBlocks(String done, String total) {
    return 'Bloki · $done z $total';
  }

  @override
  String get deskNodeLineBlocksBare => 'Bloki';

  @override
  String get deskNodeLineCompacting => 'Kompaktowanie danych łańcucha';

  @override
  String get deskNodeLineStopping => 'Zatrzymywanie…';

  @override
  String get deskNodeLineSyncing => 'Synchronizacja';

  @override
  String get deskNodeNoEstimate => 'brak szacunku; do godziny';

  @override
  String get deskNodeEstimating => 'szacowanie…';

  @override
  String deskNodeAboutHours(int hours) {
    return 'zostało około $hours h';
  }

  @override
  String deskNodeAboutMinutes(int minutes) {
    return 'zostało około $minutes min';
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
  String get deskTorNetworkLabel => 'Sieć Tor';

  @override
  String get deskTorNetworkHint =>
      'Ruch sieciowy przechodzi przez sieć Tor. Tor ukrywa adres internetowy portfela: każde połączenie przechodzi przez kilka przekaźników prowadzonych przez wolontariuszy, więc żaden serwer nie dowiaduje się, gdzie jest portfel.';

  @override
  String get deskTorOff => 'Wyłączony';

  @override
  String get deskTorStarting => 'Uruchamianie…';

  @override
  String get deskTorOn => 'Włączony';

  @override
  String get deskTorNotConnected => 'Brak połączenia';

  @override
  String get deskTorRoutes =>
      'Epicbox, węzeł, stan, kurs, aktualizacje, wsparcie i adresy Tor';

  @override
  String get deskTorCoverage =>
      'Przez Tor: Epicbox, węzeł, stan, kurs, aktualizacje, wsparcie i adresy Tor.';

  @override
  String get deskTorNodeOver => 'Przez Tor';

  @override
  String get deskTorNodeNotEncrypted => 'Za Torem bez szyfrowania';

  @override
  String get deskTorNodeWaits => 'Czeka na połączenie z Torem.';

  @override
  String get deskRecvTitle => 'Odbierz';

  @override
  String get deskRecvReceiving => 'Odbieranie';

  @override
  String get deskRecvNameFile => 'Bezpośrednio · Przesyłanie pliku';

  @override
  String deskRecvTurnOnFailed(String method) {
    return 'Nie włączono: $method';
  }

  @override
  String deskRecvTurnOffFailed(String method) {
    return 'Nie wyłączono: $method';
  }

  @override
  String get deskRecvOtherWays => 'Inne sposoby odbierania';

  @override
  String get deskRecvSettings => 'Ustawienia';

  @override
  String get deskRecvTorNotConnected => 'Tor nie jest połączony.';

  @override
  String get deskRecvTorStarting => 'Tor się uruchamia.';

  @override
  String deskRecvTorDownText(String routes) {
    return 'Przez $routes nic nie dotrze, dopóki Tor się nie połączy albo nie zostanie wyłączony.';
  }

  @override
  String get deskRecvTorStartingText =>
      'Adresy będą osiągalne, gdy Tor się połączy. Do tego czasu nic nie idzie przez zwykły internet.';

  @override
  String get deskRecvTurnTorOff => 'Wyłącz Tor';

  @override
  String get deskRecvTryAgain => 'Spróbuj ponownie';

  @override
  String get deskRecvStateOn => 'włączone';

  @override
  String get deskRecvStateOff => 'wyłączone';

  @override
  String get deskRecvStateChecking => 'sprawdzanie';

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
    return '$method · Sprawdzanie';
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
  String get deskRecvTagPaused => 'Wstrzymane';

  @override
  String get deskRecvTagStarting => 'Uruchamianie';

  @override
  String get deskRecvTagNotReachable => 'Nieosiągalny';

  @override
  String get deskRecvAddressUnreadable =>
      'Nie udało się odczytać adresu. Za chwilę otwórz Odbierz ponownie.';

  @override
  String get deskRecvEpicboxAddress => 'Adres Epicbox';

  @override
  String get deskRecvCopyEpicbox => 'Kopiuj adres Epicbox';

  @override
  String get deskRecvEpicboxIntro =>
      'Udostępnij go, aby dostać płatność. Działa, gdy portfel jest zamknięty: serwer Epicbox przechowuje płatności, aż portfel wróci.';

  @override
  String get deskRecvCheckSix =>
      'Czytając go na głos, sprawdź pierwsze sześć i ostatnie sześć znaków.';

  @override
  String get deskRecvHttpAddress => 'Adres Link · HTTP';

  @override
  String get deskRecvCopyHttp => 'Kopiuj adres Link · HTTP';

  @override
  String deskRecvHttpPublic(int port) {
    return 'Publiczny adres twojego routera. Nadawcy z internetu mogą go używać, gdy router przekierowuje port $port.';
  }

  @override
  String get deskRecvHttpLocal =>
      'Na ten adres mogą płacić programy na tym komputerze. Inne urządzenia: zobacz Ustawienia › Transakcje.';

  @override
  String get deskRecvHttpIntro =>
      'Prosto z innego portfela, gdy ten jest otwarty. Tylko na tym komputerze, chyba że Ustawienia mówią inaczej.';

  @override
  String get deskRecvHttpTorHint =>
      'Aby zamiast tego mieć adres Tor, włącz Tor w Ustawienia › Prywatność.';

  @override
  String get deskRecvDirectTor => 'Adres Link · Tor';

  @override
  String get deskRecvTorIntro =>
      'Prosto z innego portfela przez Tor, gdy ten jest otwarty. Tor ustawisz w Ustawienia › Prywatność.';

  @override
  String get deskRecvTorAddress => 'Adres Link · Tor';

  @override
  String get deskRecvCopyTor => 'Kopiuj adres Tor';

  @override
  String get deskRecvTorOnion =>
      'Niektóre portfele pokazują adres bez .onion; to ten sam adres.';

  @override
  String get deskRecvFiles => 'Pliki transakcji';

  @override
  String get deskRecvSignTitle => 'Podpisz plik transakcji';

  @override
  String get deskRecvSignText =>
      'Nadawca przekazał plik transakcji. Portfel go podpisze i zapisze dla niego odpowiedź.';

  @override
  String get deskRecvOpen => 'Otwórz';

  @override
  String get deskRecvFinalizeTitle => 'Sfinalizuj plik odpowiedzi';

  @override
  String get deskRecvFinalizeText =>
      'Na wysyłkę plikiem przyszła odpowiedź. Finalizacja publikuje płatność.';

  @override
  String deskRecvSwitchLabel(String title) {
    return '$title, odbieranie';
  }

  @override
  String get deskSendStrategySmallest => 'Najmniejsze';

  @override
  String get deskSendStrategyAll => 'Wszystkie';

  @override
  String get deskSendBalanceAfter => 'Saldo po wysłaniu';

  @override
  String get deskSendSpendableUntil => 'Do wydania do potwierdzenia reszty';

  @override
  String deskSendSplitLine(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Reszta podzielona na $outputs wyjścia (+$fee EPIC opłaty)',
      many: 'Reszta podzielona na $outputs wyjść (+$fee EPIC opłaty)',
      few: 'Reszta podzielona na $outputs wyjścia (+$fee EPIC opłaty)',
      one: 'Reszta podzielona na $outputs wyjście (+$fee EPIC opłaty)',
    );
    return '$_temp0';
  }

  @override
  String deskSendSplitWhy(int outputs, String each) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other:
          'Aby następna wysyłka nie czekała na potwierdzenie tej. Reszta wraca jako $outputs wyjścia po około $each EPIC zamiast jednego.',
      many:
          'Aby następna wysyłka nie czekała na potwierdzenie tej. Reszta wraca jako $outputs wyjść po około $each EPIC zamiast jednego.',
      few:
          'Aby następna wysyłka nie czekała na potwierdzenie tej. Reszta wraca jako $outputs wyjścia po około $each EPIC zamiast jednego.',
      one:
          'Aby następna wysyłka nie czekała na potwierdzenie tej. Reszta wraca jako $outputs wyjście po około $each EPIC zamiast jednego.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendSplitWhyLabel => 'Dlaczego reszta jest dzielona';

  @override
  String deskSendLockNoChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bez reszty: $count wyjścia wydane co do grosza, nic nie czeka.',
      many: 'Bez reszty: $count wyjść wydanych co do grosza, nic nie czeka.',
      few: 'Bez reszty: $count wyjścia wydane co do grosza, nic nie czeka.',
      one: 'Bez reszty: $count wyjście wydane co do grosza, nic nie czeka.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockAll(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wszystko jest zablokowane: $count wyjścia, $amount EPIC, około 3 bloków.',
      many:
          'Wszystko jest zablokowane: $count wyjść, $amount EPIC, około 3 bloków.',
      few:
          'Wszystko jest zablokowane: $count wyjścia, $amount EPIC, około 3 bloków.',
      one:
          'Wszystko jest zablokowane: $count wyjście, $amount EPIC, około 3 bloków.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia zablokowane, $amount EPIC, około 3 bloków.',
      many: '$count wyjść zablokowanych, $amount EPIC, około 3 bloków.',
      few: '$count wyjścia zablokowane, $amount EPIC, około 3 bloków.',
      one: '$count wyjście zablokowane, $amount EPIC, około 3 bloków.',
    );
    return '$_temp0';
  }

  @override
  String deskSendStrategyLine(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Strategia tej wysyłki: $strategy · $count wyjścia.',
      many: 'Strategia tej wysyłki: $strategy · $count wyjść.',
      few: 'Strategia tej wysyłki: $strategy · $count wyjścia.',
      one: 'Strategia tej wysyłki: $strategy · $count wyjście.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSplit(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Reszta podzielona na $outputs wyjścia (+$fee EPIC).',
      many: 'Reszta podzielona na $outputs wyjść (+$fee EPIC).',
      few: 'Reszta podzielona na $outputs wyjścia (+$fee EPIC).',
      one: 'Reszta podzielona na $outputs wyjście (+$fee EPIC).',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksNone(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$locked EPIC w $count wyjścia; reszta nie wraca.',
      many: '$locked EPIC w $count wyjściach; reszta nie wraca.',
      few: '$locked EPIC w $count wyjściach; reszta nie wraca.',
      one: '$locked EPIC w $count wyjściu; reszta nie wraca.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wszystko: $locked EPIC w $count wyjścia do potwierdzenia reszty (3 bloki). Nic nie zostaje do wydania.',
      many:
          'Wszystko: $locked EPIC w $count wyjściach do potwierdzenia reszty (3 bloki). Nic nie zostaje do wydania.',
      few:
          'Wszystko: $locked EPIC w $count wyjściach do potwierdzenia reszty (3 bloki). Nic nie zostaje do wydania.',
      one:
          'Wszystko: $locked EPIC w $count wyjściu do potwierdzenia reszty (3 bloki). Nic nie zostaje do wydania.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC w $count wyjścia do potwierdzenia reszty (3 bloki). W tym czasie nic innego nie jest do wydania.',
      many:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty (3 bloki). W tym czasie nic innego nie jest do wydania.',
      few:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty (3 bloki). W tym czasie nic innego nie jest do wydania.',
      one:
          '$locked EPIC w $count wyjściu do potwierdzenia reszty (3 bloki). W tym czasie nic innego nie jest do wydania.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksSome(int count, String locked, String spendable) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC w $count wyjścia do potwierdzenia reszty (3 bloki). $spendable EPIC zostaje do wydania.',
      many:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty (3 bloki). $spendable EPIC zostaje do wydania.',
      few:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty (3 bloki). $spendable EPIC zostaje do wydania.',
      one:
          '$locked EPIC w $count wyjściu do potwierdzenia reszty (3 bloki). $spendable EPIC zostaje do wydania.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendFactLocks => 'Blokuje';

  @override
  String get deskSendFactStrategy => 'Strategia';

  @override
  String deskSendFactStrategyValue(String strategy) {
    return '$strategy wyjścia, dla tej wysyłki';
  }

  @override
  String get deskSendAdvSmallest => '· Najmniejsze wyjścia';

  @override
  String get deskSendAdvSmallestNoSplit =>
      '· Najmniejsze wyjścia, reszta niedzielona';

  @override
  String get deskSendAdvAll => '· Wszystkie wyjścia';

  @override
  String get deskSendAdvAllNoSplit => '· Wszystkie wyjścia, reszta niedzielona';

  @override
  String get deskSendAdvanced => 'Opcje wysyłki';

  @override
  String get deskSendAdvStrategy => 'Strategia tej wysyłki';

  @override
  String get deskSendAdvSmallestText =>
      'Wydaje jak najmniej małych wyjść; pozostała część salda jest do wydania, gdy reszta się potwierdza.';

  @override
  String get deskSendAdvAllText =>
      'Wydaje wszystkie wyjścia do wydania i zwraca jedno wyjście reszty. Wszystko jest zablokowane do potwierdzenia; potem jest mniej, ale większych wyjść.';

  @override
  String get deskSendDefaultTag => 'domyślna';

  @override
  String get deskSendAdvAllNote =>
      'Wysłanie wszystkiego wydaje wszystkie wyjścia.';

  @override
  String get deskSendAdvSplit => 'Podziel resztę';

  @override
  String get deskSendAdvSplitText =>
      'Zwraca resztę jako kilka wyjść, gdy zostałoby ich mało, aby następna wysyłka nie musiała czekać.';

  @override
  String get deskSendAdvDefaults => 'Tylko dla tej wysyłki. Domyślne: ';

  @override
  String get deskSendAdvOutputsLink => 'Wyjścia';

  @override
  String get deskSendPickNone => 'Brak kontaktów';

  @override
  String get deskSendPickNoneText =>
      'Zapisz osoby, którym płacisz, w Kontaktach, a potem wybieraj je tutaj.';

  @override
  String get deskSendPickOpen => 'Otwórz kontakty';

  @override
  String deskSendPickNoMatch(String query) {
    return 'Żaden kontakt nie pasuje do „$query”.';
  }

  @override
  String get deskSendPickTitle => 'Wybierz kontakt';

  @override
  String get deskSendPickDesc => 'Adres trafi do pola odbiorcy.';

  @override
  String get deskSendPickSearch => 'Szukaj w kontaktach';

  @override
  String get deskSendTitle => 'Wyślij';

  @override
  String get deskSendErrNoAddress => 'Dodaj adres, na który chcesz wysłać.';

  @override
  String get deskSendErrEpicbox => 'To nie jest prawidłowy adres Epicbox.';

  @override
  String get deskSendErrNotDirect => 'To nie jest adres Link.';

  @override
  String get deskSendErrOnion => 'To nie jest prawidłowy adres onion.';

  @override
  String get deskSendErrOwn => 'To własny adres tego portfela.';

  @override
  String get deskSendNoAnswer =>
      'Odbiorca nie odpowiedział. Nic nie zostało wysłane.';

  @override
  String get deskSendTorOnFailed => 'Nie włączono Tora';

  @override
  String get deskSendTorOffFailed => 'Nie wyłączono Tora';

  @override
  String get deskSendEpicboxOnFailed => 'Nie włączono Epicbox';

  @override
  String get deskSendNothingSpendable => 'Nie ma nic do wydania.';

  @override
  String get deskSendAllFailed =>
      'Nie udało się ustalić, ile można wysłać. Spróbuj ponownie za chwilę.';

  @override
  String get deskSendErrAmountEnter => 'Wpisz kwotę.';

  @override
  String get deskSendErrAmountDecimals =>
      'EPIC ma najwyżej 8 miejsc po przecinku.';

  @override
  String get deskSendErrAmountZero => 'Kwota musi być większa od 0.';

  @override
  String get deskSendErrAmountMore => 'Więcej niż dostępne saldo.';

  @override
  String get deskSendSent => 'Wysłano';

  @override
  String get deskSendFileReadyTitle => 'Plik transakcji gotowy';

  @override
  String get deskSendFileReadyText =>
      'Przekaż ten plik odbiorcy. Portfel czeka na plik odpowiedzi; sfinalizuj go, gdy wróci.';

  @override
  String get deskSendFinalize => 'Sfinalizuj';

  @override
  String get deskSendNewSend => 'Nowa wysyłka';

  @override
  String get deskSendNodeNotSynced => 'Węzeł niezsynchronizowany';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Wysyłanie będzie możliwe po synchronizacji węzła. Gotowe: $percent%; formularz możesz wypełnić już teraz.';
  }

  @override
  String get deskSendNodeSyncing =>
      'Wysyłanie będzie możliwe po synchronizacji węzła.';

  @override
  String get deskSendTorBlocked => 'Tor nie jest połączony';

  @override
  String get deskSendTorBlockedText =>
      'Nic nie zostanie wysłane, dopóki Tor się nie połączy albo nie zostanie wyłączony.';

  @override
  String get deskSendTurnTorOff => 'Wyłącz Tor';

  @override
  String get deskSendTorStarting => 'Tor się uruchamia';

  @override
  String get deskSendTorStartingText =>
      'Wysyłanie czeka na połączenie z Torem. Do tego czasu nic nie idzie przez zwykły internet.';

  @override
  String get deskSendEpicboxOff => 'Epicbox niepołączony';

  @override
  String get deskSendEpicboxOffText =>
      'Wysyłki przez Epicbox działają, gdy odbieranie przez Epicbox jest włączone. Do tego czasu użyj: Bezpośrednio · Przesyłanie pliku.';

  @override
  String get deskSendEpicboxTurnOn => 'Włącz odbieranie przez Epicbox';

  @override
  String get deskSendDoneViaDirect => 'Sfinalizowano i opublikowano w sieci.';

  @override
  String get deskSendDoneViaEpicbox =>
      'Przekazano do Epicbox. Zakończy się, gdy odbiorca odpowie.';

  @override
  String get deskSendViewTx => 'Pokaż transakcję';

  @override
  String get deskSendFailedTitle => 'Wysyłka nie powiodła się';

  @override
  String get deskSendReviewAgain => 'Sprawdź ponownie';

  @override
  String get deskSendMethodDirect => 'Link';

  @override
  String get deskSendMethodFile => 'Bezpośrednio · Plik';

  @override
  String get deskSendTo => 'Do';

  @override
  String get deskSendToHelp => 'Wklej adres albo wpisz nazwę kontaktu.';

  @override
  String get deskSendToHint => 'Adres lub kontakt';

  @override
  String get deskSendToSem => 'Odbiorca';

  @override
  String get deskSendClearTo => 'Wyczyść odbiorcę';

  @override
  String get deskSendContacts => 'Kontakty';

  @override
  String get deskSendNeedsTor => 'Wymaga Tora';

  @override
  String get deskSendNeedsTorText =>
      'Adres onion jest osiągalny tylko przez Tor.';

  @override
  String get deskSendNoTorBuild => 'Ta wersja nie zawiera Tora.';

  @override
  String get deskSendTurnOnTor => 'Włącz Tor';

  @override
  String get deskSendHttpClearnet =>
      'Link · HTTP idzie przez zwykły internet, nie przez Tor.';

  @override
  String get deskSendClear => 'Wyczyść';

  @override
  String get deskSendAmount => 'Kwota';

  @override
  String get deskSendAvailableNone => 'Dostępne —';

  @override
  String deskSendAvailable(String amount) {
    return 'Dostępne $amount EPIC';
  }

  @override
  String get deskSendAmountSem => 'Kwota w EPIC';

  @override
  String get deskSendAllButton => 'Całość';

  @override
  String get deskSendConfirmingHidden =>
      'Część salda wciąż się potwierdza i nie można jej jeszcze wysłać.';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC wciąż się potwierdza i nie można tego jeszcze wysłać.';
  }

  @override
  String get deskSendMessage => 'Wiadomość';

  @override
  String get deskSendMessageHelp => 'Odbiorca zobaczy tę wiadomość.';

  @override
  String get deskSendPrivacyOn => 'Prywatność · Dandelion++ włączony';

  @override
  String get deskSendPrivacyOff => 'Prywatność · Dandelion++ wyłączony';

  @override
  String get deskSendDandelionText =>
      'Przepuszcza transakcję przez kilka losowych węzłów, zanim się rozejdzie, więc sieć nie wie, skąd pochodzi.';

  @override
  String get deskSendHintSent =>
      'Wysłano. Wpisz nową kwotę i odbiorcę, aby wysłać ponownie.';

  @override
  String get deskSendHintNode => 'Oczekiwanie na synchronizację węzła.';

  @override
  String get deskSendHintEpicbox => 'Oczekiwanie na połączenie z Epicbox.';

  @override
  String get deskSendHintTorWait => 'Oczekiwanie na połączenie z Torem.';

  @override
  String get deskSendHintTorBlocked => 'Ponów próbę z Torem albo go wyłącz.';

  @override
  String get deskSendHintNeedsTor => 'Włącz Tor, aby wysłać na adres onion.';

  @override
  String get deskSendHintFix => 'Popraw pola zaznaczone na czerwono.';

  @override
  String get deskSendHintChecking => 'Sprawdzanie opłaty dla tej kwoty.';

  @override
  String get deskSendHintDefault =>
      'Nic nie zostanie wysłane bez potwierdzenia.';

  @override
  String get deskSendReviewWaitTor => 'Oczekiwanie na Tor';

  @override
  String get deskSendReviewTorOff => 'Tor niepołączony';

  @override
  String get deskSendReview => 'Sprawdź wysyłkę';

  @override
  String get deskSendSummary => 'Podsumowanie';

  @override
  String get deskSendNetworkFee => 'Opłata sieciowa';

  @override
  String get deskSendTotal => 'Razem';

  @override
  String get deskSendUpdating =>
      'Saldo aktualizuje się podczas skanowania portfela.';

  @override
  String get deskSendEpicboxLine1 => 'Odbiorca może być offline.';

  @override
  String get deskSendEpicboxLine2 =>
      'Serwer Epicbox trzyma płatność, aż odbiorca otworzy portfel.';

  @override
  String get deskSendDirectLine1 => 'Prosto do portfela odbiorcy.';

  @override
  String get deskSendDirectLine2 =>
      'Adres http(s) lub .onion; onion idzie przez Tor. Portfel odbiorcy musi być otwarty.';

  @override
  String get deskSendFileLine1 => 'Bez połączenia.';

  @override
  String get deskSendFileLine2 =>
      'Przekaż plik, odbierz plik odpowiedzi, potem sfinalizuj go tutaj.';

  @override
  String get deskSendTagDirect => 'Link';

  @override
  String get deskSendTagFile => 'Bezpośrednio · Plik';

  @override
  String get deskSendTagEpicbox => 'Przez Epicbox';

  @override
  String get deskSendSwitchedDirect => 'Adres Link. Ustawiono metodę Link.';

  @override
  String get deskSendSwitchedFile =>
      'Adres plikowy. Ustawiono metodę Bezpośrednio · Plik.';

  @override
  String get deskSendSwitchedEpicbox =>
      'Adres Epicbox. Ustawiono metodę Epicbox.';

  @override
  String get deskSendMatching => 'Pasujące kontakty';

  @override
  String deskSendMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pasuje $count kontaktu',
      many: 'Pasuje $count kontaktów',
      few: 'Pasują $count kontakty',
      one: 'Pasuje $count kontakt',
    );
    return '$_temp0';
  }

  @override
  String get deskSendWrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get deskSendNotConfirmed =>
      'Niepotwierdzone. Sprawdź Aktywność przed ponownym wysłaniem.';

  @override
  String get deskSendViaEpicbox => 'Epicbox (odbiorca może być offline)';

  @override
  String get deskSendViaDirect =>
      'Link · HTTP (portfel odbiorcy musi być otwarty)';

  @override
  String get deskSendViaTor => 'Link · Tor (portfel odbiorcy musi być otwarty)';

  @override
  String get deskSendViaFile => 'Plik transakcji';

  @override
  String deskSendUsesAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
      many: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
      few: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
      one: 'Używa wszystkich wyjść: $count · reszta: 1 wyjście',
    );
    return '$_temp0';
  }

  @override
  String get deskSendReviewTitle => 'Sprawdź i wyślij';

  @override
  String get deskSendReviewDesc => 'Opublikowanej wysyłki nie można cofnąć.';

  @override
  String get deskSendFactTo => 'Do';

  @override
  String get deskSendCheckChars =>
      'Porównaj wyróżnione znaki z adresem od odbiorcy.';

  @override
  String get deskSendFactVia => 'Przez';

  @override
  String get deskSendFactPrivacy => 'Prywatność';

  @override
  String get deskSendDandelionOn => 'Dandelion++ włączony';

  @override
  String get deskSendDandelionOff => 'Dandelion++ wyłączony';

  @override
  String get deskSendFactMessage => 'Wiadomość';

  @override
  String get deskSendPassword => 'Hasło';

  @override
  String get deskSendPasswordHelp => 'Każda wysyłka prosi o hasło portfela.';

  @override
  String get deskSendBusyFile => 'Tworzenie pliku.';

  @override
  String get deskSendBusyTor =>
      'Łączenie z portfelem odbiorcy przez Tor… To może potrwać. Nie zamykaj aplikacji.';

  @override
  String get deskSendBusy =>
      'Wysyłanie. Może to potrwać kilka sekund; nie zamykaj tego okna.';

  @override
  String get deskSendBack => 'Wstecz';

  @override
  String get deskSendSending => 'Wysyłanie';

  @override
  String deskSendConfirm(String amount) {
    return 'Wyślij $amount EPIC';
  }

  @override
  String get deskSendPlainTitle => 'Bez szyfrowania. Wysłać mimo to?';

  @override
  String get deskSendPlainDesc =>
      'Zwykłe HTTP do innego komputera. Każdy po drodze może odczytać transakcję. https:// jest szyfrowane.';

  @override
  String get deskSendPlainConfirm => 'Wyślij mimo to';

  @override
  String deskSendEpicboxSwitched(String domain) {
    return 'Przełączono na $domain';
  }

  @override
  String get deskSendEpicboxNotSwitched => 'Nie przełączono';

  @override
  String get deskSendEpicboxDownTitle => 'Serwer Epicbox nie odpowiada';

  @override
  String get deskSendEpicboxDownWait => 'Płatności czekają, aż wróci.';

  @override
  String deskSendEpicboxSwitchTo(String domain) {
    return 'Przełączyć na $domain?';
  }

  @override
  String get deskSendEpicboxSwitch => 'Przełącz';

  @override
  String get deskFinOpenFolder => 'Otwórz folder';

  @override
  String get deskFinFolderNotOpened => 'Nie otwarto folderu';

  @override
  String get deskFinWrongType => 'To nie plik odpowiedzi';

  @override
  String get deskFinWrongTypeText =>
      'Ten plik nie jest plikiem odpowiedzi. Wybierz plik odesłany przez odbiorcę.';

  @override
  String get deskFinUnreadable => 'Nie można odczytać pliku';

  @override
  String get deskFinUnreadableText =>
      'Nie udało się odczytać pliku. Może być uszkodzony albo wciąż kopiowany.';

  @override
  String get deskFinFailed => 'Finalizacja nie powiodła się';

  @override
  String get deskFinFailedText =>
      'Portfel nie mógł sfinalizować tego pliku. Może należy do innej transakcji albo jest już sfinalizowany.';

  @override
  String get deskFinNotPosted => 'Nie opublikowano';

  @override
  String get deskFinNotPostedText =>
      'Transakcja została sfinalizowana, ale węzeł jej nie przyjął. Sprawdź węzeł i spróbuj ponownie.';

  @override
  String get deskFinPickTitle => 'Plik odpowiedzi';

  @override
  String get deskFinPosted => 'Transakcja opublikowana';

  @override
  String get deskFinTitle => 'Sfinalizuj plik odpowiedzi';

  @override
  String get deskFinNoticeTitle => 'Dla transakcji utworzonej jako plik';

  @override
  String get deskFinNoticeText =>
      'Użyj pliku odpowiedzi odesłanego przez odbiorcę.';

  @override
  String get deskFinTryAgain => 'Spróbuj ponownie';

  @override
  String get deskFinPostedText =>
      'Płatność została sfinalizowana i wysłana do sieci. Śledź ją w Aktywności.';

  @override
  String get deskFinAnother => 'Sfinalizuj kolejny plik';

  @override
  String get deskFinViewActivity => 'Pokaż w Aktywności';

  @override
  String get deskFinBusy => 'Finalizowanie i publikowanie';

  @override
  String get deskFinChoose => 'Wybierz plik odpowiedzi';

  @override
  String get deskFinChooseText =>
      'Portfel dokończy transakcję i opublikuje ją w sieci.';

  @override
  String get deskFinChooseFile => 'Wybierz plik';

  @override
  String get deskImpWrongType => 'To nie plik transakcji';

  @override
  String get deskImpWrongTypeText =>
      'Ten plik nie jest plikiem transakcji. Wybierz plik .slate lub .tx od nadawcy.';

  @override
  String get deskImpUnreadable => 'Nie można odczytać pliku';

  @override
  String get deskImpUnreadableText =>
      'Nie udało się odczytać pliku. Może być uszkodzony albo wciąż kopiowany.';

  @override
  String get deskImpNoPlace => 'Nic nie podpisano';

  @override
  String get deskImpNoPlaceText =>
      'Nie wybrano miejsca na plik odpowiedzi, więc nic nie zostało podpisane.';

  @override
  String get deskImpFailed => 'Podpisanie nie powiodło się';

  @override
  String get deskImpFailedText =>
      'Portfel nie mógł podpisać tego pliku. Może być przeznaczony dla innego portfela albo już użyty.';

  @override
  String deskImpFailedDetail(String detail) {
    return 'Portfel nie mógł podpisać tego pliku. Może być przeznaczony dla innego portfela albo już użyty. $detail.';
  }

  @override
  String get deskImpPickTitle => 'Plik transakcji';

  @override
  String get deskImpTitle => 'Podpisz plik transakcji';

  @override
  String get deskImpNoticeTitle => 'Podpisanie niczego nie wydaje';

  @override
  String get deskImpNoticeText =>
      'Odeślij plik odpowiedzi nadawcy tym samym kanałem, którym przyszedł plik.';

  @override
  String get deskImpSaved => 'Zapisano odpowiedź';

  @override
  String get deskImpSavedText =>
      'Odeślij plik odpowiedzi nadawcy. EPIC dotrą, gdy nadawca go sfinalizuje.';

  @override
  String get deskImpAmount => 'Kwota ';

  @override
  String get deskImpAnother => 'Podpisz kolejny plik';

  @override
  String get deskImpBusy => 'Podpisywanie pliku';

  @override
  String get deskImpChoose => 'Wybierz plik transakcji';

  @override
  String get deskImpChooseText =>
      'Portfel go podpisze i zapisze odpowiedź dla nadawcy.';

  @override
  String get deskActNotUpdated => 'Nie zaktualizowano';

  @override
  String get deskActSearchHint => 'Adres lub ID slate';

  @override
  String get deskActSearchHintEmpty => 'Na razie nie ma czego szukać';

  @override
  String get deskActSearchLabel => 'Szukaj transakcji';

  @override
  String get deskActClearSearch => 'Wyczyść wyszukiwanie';

  @override
  String get deskActShowAmounts => 'Pokaż kwoty';

  @override
  String get deskActHideAmounts => 'Ukryj kwoty';

  @override
  String get deskActRefresh => 'Odśwież';

  @override
  String get deskActTitle => 'Aktywność';

  @override
  String get deskActDetailReceived => 'Odebrana transakcja';

  @override
  String get deskActDetailSent => 'Wysłana transakcja';

  @override
  String get deskActLoading => 'Wczytywanie transakcji';

  @override
  String get deskActWaitingNode => 'Oczekiwanie na synchronizację węzła.';

  @override
  String get deskActFilterAll => 'Wszystkie';

  @override
  String get deskActFilterReceived => 'Odebrane';

  @override
  String get deskActFilterSent => 'Wysłane';

  @override
  String get deskActNoMatchTitle => 'Brak pasujących transakcji';

  @override
  String get deskActNoMatchText =>
      'Spróbuj innego adresu lub ID slate albo wyczyść filtr.';

  @override
  String deskActPageOf(int page, int pages) {
    return 'Strona $page z $pages';
  }

  @override
  String get deskActPrevPage => 'Poprzednia strona';

  @override
  String get deskActNextPage => 'Następna strona';

  @override
  String get deskActPages => 'Strony';

  @override
  String get deskActColFromTo => 'Od / do';

  @override
  String get deskActColStatus => 'Stan';

  @override
  String get deskActColTime => 'Godzina';

  @override
  String get deskActColAmount => 'Kwota';

  @override
  String get deskActEmptyTitle => 'Brak transakcji';

  @override
  String get deskActEmptyText =>
      'Tutaj widać każdą wysłaną i odebraną płatność, od najnowszej: z kim była i na jakim jest etapie.';

  @override
  String get deskActStageWaiting => 'Oczekiwanie';

  @override
  String get deskActStageWaitingText =>
      'Oba portfele ją podpisują. Przez Epicbox dzieje się to automatycznie.';

  @override
  String get deskActStageConfirming => 'Potwierdzanie';

  @override
  String get deskActStageConfirmingText =>
      'W łańcuchu. Mniej więcej jeden blok na minutę.';

  @override
  String get deskActStageSpendable => 'Do wydania';

  @override
  String deskActStageSpendableText(int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'Po $needed potwierdzenia, czyli po około $needed minuty.',
      many: 'Po $needed potwierdzeniach, czyli po około $needed minutach.',
      few: 'Po $needed potwierdzeniach, czyli po około $needed minutach.',
      one: 'Po $needed potwierdzeniu, czyli po około $needed minucie.',
    );
    return '$_temp0';
  }

  @override
  String get deskActShowAddress => 'Pokaż adres';

  @override
  String get deskActReceiveFile => 'Odbierz plik';

  @override
  String get deskConTitle => 'Kontakty';

  @override
  String get deskConLoading => 'Wczytywanie kontaktów';

  @override
  String get deskConNewTitle => 'Nowy kontakt';

  @override
  String get deskConEditTitle => 'Edytuj kontakt';

  @override
  String get deskConDetailsTitle => 'Szczegóły';

  @override
  String get deskConSearchHint => 'Nazwa lub adres';

  @override
  String get deskConSearchLabel => 'Szukaj w kontaktach';

  @override
  String get deskConClearSearch => 'Wyczyść wyszukiwanie';

  @override
  String deskConCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kontaktu',
      many: '$count kontaktów',
      few: '$count kontakty',
      one: '$count kontakt',
    );
    return '$_temp0';
  }

  @override
  String get deskConNoMatches => 'Brak wyników';

  @override
  String deskConMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyniku',
      many: '$count wyników',
      few: '$count wyniki',
      one: '$count wynik',
    );
    return '$_temp0';
  }

  @override
  String get deskConSortName => 'Nazwa';

  @override
  String get deskConSortRecent => 'Ostatnie';

  @override
  String get deskConNone => 'Brak kontaktów.';

  @override
  String get deskConNoMatchList => 'Brak pasujących kontaktów';

  @override
  String get deskConAdd => 'Dodaj kontakt';

  @override
  String get deskConIdle =>
      'Wybierz kontakt, aby zobaczyć szczegóły, wysłać mu płatność, edytować go lub usunąć.';

  @override
  String get deskConEmptyTitle => 'Brak kontaktów';

  @override
  String get deskConEmptyText =>
      'Zapisz osoby i sklepy, którym często płacisz. W Wyślij wybierzesz nazwę zamiast wklejać adres.';

  @override
  String get deskConEmptyLocal =>
      'Kontakty zostają na tym komputerze. Nie są częścią frazy odzyskiwania.';

  @override
  String get deskConSendToAddress => 'Wyślij na adres';

  @override
  String deskConLastTx(String when) {
    return 'Ostatnia transakcja: $when';
  }

  @override
  String get deskConSend => 'Wyślij';

  @override
  String get deskConEdit => 'Edytuj';

  @override
  String get deskConStar => 'Oznacz gwiazdką';

  @override
  String get deskConUnstar => 'Usuń gwiazdkę';

  @override
  String get deskConDelete => 'Usuń';

  @override
  String get deskConNotDeleted => 'Nie usunięto';

  @override
  String deskConDeleted(String name) {
    return 'Usunięto: $name';
  }

  @override
  String get deskConNote => 'Notatka';

  @override
  String deskConTxWith(String name) {
    return 'Transakcje z: $name';
  }

  @override
  String get deskConAllTx => 'Wszystkie transakcje';

  @override
  String get deskConTxNone =>
      'Brak transakcji z tym kontaktem. Pojawią się tu płatności wysłane do niego z Wyślij.';

  @override
  String get deskConTxReceived => 'Odebrana';

  @override
  String get deskConTxSent => 'Wysłana';

  @override
  String get deskConErrName => 'Nadaj kontaktowi nazwę.';

  @override
  String get deskConErrAddressEmpty => 'Dodaj adres.';

  @override
  String get deskConErrAddressInvalid =>
      'To nie jest prawidłowy adres. Użyj adresu Epicbox (es5x…@epicbox.epiccash.com), adresu Link (https://…) lub adresu onion (….onion).';

  @override
  String get deskConAddPicture => 'Dodaj zdjęcie';

  @override
  String get deskConChangePicture => 'Zmień zdjęcie';

  @override
  String get deskConRemovePicture => 'Usuń';

  @override
  String get deskConPictureHelp =>
      'PNG, JPEG, WebP lub GIF, do 10 MB. Aplikacja przechowuje małą kopię.';

  @override
  String get deskConFieldName => 'Nazwa';

  @override
  String get deskConFieldAddress => 'Adres';

  @override
  String get deskConSaveFailed => 'Nie zapisano kontaktu';

  @override
  String get deskConSave => 'Zapisz kontakt';

  @override
  String deskConDeleteTitle(String name) {
    return 'Usunąć kontakt $name?';
  }

  @override
  String get deskConDeleteBody =>
      'Adres i notatka kontaktu zostaną usunięte z tego portfela. Wcześniejsze transakcje zostaną w Aktywności. Tego nie można cofnąć.';

  @override
  String get deskConKeep => 'Zachowaj kontakt';

  @override
  String get deskConDeleteAction => 'Usuń kontakt';

  @override
  String get deskOutNotUpdated => 'Nie zaktualizowano';

  @override
  String get deskOutTitle => 'Wyjścia';

  @override
  String get deskOutShowAmounts => 'Pokaż kwoty';

  @override
  String get deskOutHideAmounts => 'Ukryj kwoty';

  @override
  String get deskOutRefresh => 'Odśwież';

  @override
  String get deskOutLockedNote =>
      'Zablokowane wyjścia są wydawane przez trwającą transakcję. Ich reszta jest widoczna jako czekająca na sfinalizowanie i nie wlicza się do sumy Razem, dopóki wysyłka nie zostanie sfinalizowana, więc Razem liczy monety tylko raz.';

  @override
  String get deskOutIntro =>
      'Wyjścia to części, z których składa się saldo. Wysyłka wydaje całe wyjścia, płaci odbiorcy i zwraca resztę jako nowe wyjście; wydane wyjścia są zablokowane, dopóki wysyłka się nie potwierdzi.';

  @override
  String deskOutCount(int count) {
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
  String get deskOutCardWait =>
      'Poczekaj na potwierdzenie wysyłki (około 3 bloków).';

  @override
  String get deskOutSplitNothing => 'Na razie nie ma czego dzielić.';

  @override
  String deskOutSplitSpends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wydaje $count wyjścia.',
      many: 'Wydaje $count wyjść.',
      few: 'Wydaje $count wyjścia.',
      one: 'Wydaje $count wyjście.',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitSpendsFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wydaje $count wyjścia. Opłata od $fee EPIC.',
      many: 'Wydaje $count wyjść. Opłata od $fee EPIC.',
      few: 'Wydaje $count wyjścia. Opłata od $fee EPIC.',
      one: 'Wydaje $count wyjście. Opłata od $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutConsNothing => 'Na razie nie ma czego scalać.';

  @override
  String get deskOutConsOne => 'Nie ma czego scalać: jedno wyjście do wydania.';

  @override
  String deskOutConsInto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia w 1.',
      many: '$count wyjść w 1.',
      few: '$count wyjścia w 1.',
      one: '$count wyjście w 1.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsIntoFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia w 1. Opłata $fee EPIC.',
      many: '$count wyjść w 1. Opłata $fee EPIC.',
      few: '$count wyjścia w 1. Opłata $fee EPIC.',
      one: '$count wyjście w 1. Opłata $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutSplitCardTitle => 'Podziel';

  @override
  String get deskOutSplitCardText =>
      'Tworzy więcej wyjść z salda do wydania, aby kilka wysyłek mogło iść jedna po drugiej bez czekania.';

  @override
  String get deskOutSplitCardButton => 'Podziel…';

  @override
  String get deskOutConsCardTitle => 'Scal';

  @override
  String get deskOutConsCardText =>
      'Łączy wszystkie wyjścia do wydania w jedno. Niższa opłata przy następnej wysyłce; wszystko jest zablokowane do potwierdzenia.';

  @override
  String get deskOutConsCardButton => 'Scal…';

  @override
  String get deskOutNotLoadedTitle => 'Nie wczytano wyjść';

  @override
  String get deskOutNotLoadedText => 'Odśwież, aby spróbować ponownie.';

  @override
  String get deskOutLoading => 'Wczytywanie danych portfela';

  @override
  String get deskOutNoneTitle => 'Brak wyjść';

  @override
  String get deskOutNoneText =>
      'Pierwsza odebrana płatność utworzy jedno. Podział i scalanie potrzebują wyjść, żeby działać.';

  @override
  String get deskOutFilterAll => 'Wszystkie';

  @override
  String get deskOutFilterSpendable => 'Do wydania';

  @override
  String get deskOutFilterConfirming => 'Potwierdzane';

  @override
  String get deskOutFilterLocked => 'Zablokowane';

  @override
  String get deskOutSearchHint => 'Zobowiązanie';

  @override
  String get deskOutSearchLabel => 'Szukaj wyjść';

  @override
  String get deskOutClearSearch => 'Wyczyść wyszukiwanie';

  @override
  String get deskOutShowSpent => 'Pokaż wydane';

  @override
  String get deskOutNoMatchTitle => 'Brak pasujących wyjść';

  @override
  String get deskOutNoMatchText =>
      'Spróbuj innego zobowiązania albo wyczyść filtr.';

  @override
  String get deskOutClearFilter => 'Wyczyść filtr';

  @override
  String get deskOutTileSpendable => 'Do wydania';

  @override
  String get deskOutTileConfirming => 'Potwierdzane';

  @override
  String get deskOutTileImmature => 'Niedojrzałe';

  @override
  String get deskOutTileLocked => 'Zablokowane w wysyłkach';

  @override
  String get deskOutTileTotal => 'Razem';

  @override
  String get deskOutStrategyTitle => 'Strategia wysyłek';

  @override
  String get deskOutStrategySmallest => 'Najmniejsze';

  @override
  String get deskOutStrategyAll => 'Wszystkie';

  @override
  String get deskOutStrategyHelpTitle => 'Najmniejsze czy Wszystkie';

  @override
  String get deskOutSplitChangeTitle => 'Podziel resztę';

  @override
  String get deskOutSplitChangeText =>
      'Gdy po wysyłce zostałyby mniej niż 3 wyjścia do wydania, a reszta wynosi co najmniej 1 EPIC, reszta wraca jako maksymalnie 4 wyjścia po co najmniej 0,5 EPIC każde. Każde dodatkowe wyjście kosztuje 0,004 EPIC.';

  @override
  String get deskOutColValue => 'Wartość';

  @override
  String get deskOutColStatus => 'Stan';

  @override
  String get deskOutColConfirmations => 'Potwierdzenia';

  @override
  String get deskOutColHeight => 'Wysokość';

  @override
  String get deskOutColTransaction => 'Transakcja';

  @override
  String get deskOutColCommitment => 'Zobowiązanie';

  @override
  String get deskOutStatusSpendable => 'Do wydania';

  @override
  String get deskOutStatusConfirming => 'Potwierdzane';

  @override
  String deskOutConfirmations(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number potwierdzenia',
      many: '$number potwierdzeń',
      few: '$number potwierdzenia',
      one: '$number potwierdzenie',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusAwaiting => 'Czeka na sfinalizowanie';

  @override
  String get deskOutNoteWaitingSender => 'czeka na nadawcę';

  @override
  String get deskOutStatusUnpaid => 'Niezapłacona faktura';

  @override
  String get deskOutNoteNotInBalance => 'poza saldem';

  @override
  String get deskOutStatusImmature => 'Niedojrzałe';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jeszcze $number bloku',
      many: 'jeszcze $number bloków',
      few: 'jeszcze $number bloki',
      one: 'jeszcze $number blok',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusMining => 'Kopanie';

  @override
  String get deskOutStatusLocked => 'Zablokowane';

  @override
  String deskOutNoteBySend(int id) {
    return 'przez wysyłkę #$id';
  }

  @override
  String get deskOutStatusSpent => 'Wydane';

  @override
  String deskOutTxReceived(String date) {
    return 'Odebrano $date';
  }

  @override
  String deskOutTxSent(String date) {
    return 'Wysłano $date';
  }

  @override
  String deskOutCopyCommitment(String short) {
    return 'Kopiuj zobowiązanie $short';
  }

  @override
  String deskOutSplitSpentPart(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia ($amount EPIC)',
      many: '$count wyjść ($amount EPIC)',
      few: '$count wyjścia ($amount EPIC)',
      one: '$count wyjście ($amount EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitMadePart(int count, String amount) {
    return 'nowe wyjścia ($count) po około $amount EPIC';
  }

  @override
  String deskOutConsMadePart(String amount) {
    return 'jedno wyjście na $amount EPIC';
  }

  @override
  String deskOutSplitDialogText(String spent, String made) {
    return 'Wydaje $spent i tworzy $made. Zwykła transakcja sieciowa do tego portfela, potwierdzona po 3 blokach jak każda wysyłka; do tego czasu wszystko do wydania jest zablokowane.';
  }

  @override
  String deskOutConsDialogText(String spent, String made) {
    return 'Wydaje $spent i tworzy $made. Zwykła transakcja sieciowa do tego portfela, potwierdzona po 3 blokach jak każda wysyłka; do tego czasu wszystko do wydania jest zablokowane. Następna wysyłka wyda jedno wyjście, więc jej opłata będzie najmniejsza.';
  }

  @override
  String get deskOutFactFee => 'Opłata sieciowa';

  @override
  String get deskOutFactEach => 'Każde wyjście';

  @override
  String deskOutFactAbout(String amount) {
    return 'około $amount EPIC';
  }

  @override
  String get deskOutFactLocked => 'Zablokowane';

  @override
  String deskOutFactLockedValue(String amount) {
    return '$amount EPIC, około 3 bloków. Nic nie zostaje do wydania.';
  }

  @override
  String get deskOutMakeLabel => 'Liczba wyjść';

  @override
  String get deskOutMakeRange => 'Od 2 do 10.';

  @override
  String get deskOutStepperFewer => 'Mniej';

  @override
  String get deskOutStepperMore => 'Więcej';

  @override
  String get deskOutFeeWorking => 'Obliczanie opłaty';

  @override
  String get deskOutNoEstimate => 'Brak wyceny';

  @override
  String get deskOutEachMin => 'Każde wyjście musi mieć co najmniej 0,5 EPIC.';

  @override
  String get deskOutNotEnoughFee => 'Za mało, by pokryć opłatę.';

  @override
  String deskOutSplitInto(int count) {
    return 'Podziel na $count';
  }

  @override
  String get deskOutConsolidateButton => 'Scal';

  @override
  String get deskOutPostingSplit =>
      'Tworzenie i publikowanie podziału. Nie zamykaj aplikacji.';

  @override
  String get deskOutPostingCons =>
      'Tworzenie i publikowanie scalenia. Nie zamykaj aplikacji.';

  @override
  String get deskOutSplitPosted => 'Podział opublikowany';

  @override
  String get deskOutConsPosted => 'Scalenie opublikowane';

  @override
  String deskOutSplitDoneText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Portfel ma teraz $count wyjścia po około $amount EPIC, w trakcie potwierdzania. Wszystko jest zablokowane do potwierdzenia (3 bloki). Aktywność pokazuje dwa wpisy: wysyłkę i odbiór, oba do tego portfela.',
      many:
          'Portfel ma teraz $count wyjść po około $amount EPIC, w trakcie potwierdzania. Wszystko jest zablokowane do potwierdzenia (3 bloki). Aktywność pokazuje dwa wpisy: wysyłkę i odbiór, oba do tego portfela.',
      few:
          'Portfel ma teraz $count wyjścia po około $amount EPIC, w trakcie potwierdzania. Wszystko jest zablokowane do potwierdzenia (3 bloki). Aktywność pokazuje dwa wpisy: wysyłkę i odbiór, oba do tego portfela.',
      one:
          'Portfel ma teraz $count wyjście po około $amount EPIC, w trakcie potwierdzania. Wszystko jest zablokowane do potwierdzenia (3 bloki). Aktywność pokazuje dwa wpisy: wysyłkę i odbiór, oba do tego portfela.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount) {
    return 'Jedno wyjście na $amount EPIC, w trakcie potwierdzania. Wszystko jest zablokowane do potwierdzenia (3 bloki). Aktywność pokazuje dwa wpisy: wysyłkę i odbiór, oba do tego portfela.';
  }

  @override
  String get deskOutNotPostedTitle => 'Nie opublikowano.';

  @override
  String get deskOutNotPostedSplit =>
      'Podział został utworzony i zapisany, ale węzeł go nie przyjął. Opublikuj go ponownie albo anuluj, aby odblokować wyjścia.';

  @override
  String get deskOutNotPostedCons =>
      'Scalenie zostało utworzone i zapisane, ale węzeł go nie przyjął. Opublikuj je ponownie albo anuluj, aby odblokować wyjścia.';

  @override
  String get deskOutCancelSplit => 'Anuluj podział';

  @override
  String get deskOutCancelCons => 'Anuluj scalenie';

  @override
  String get deskOutPostAgain => 'Opublikuj ponownie';

  @override
  String get deskOutNotDoneTitle => 'Nie wykonano';

  @override
  String deskOutNotDoneText(String error) {
    return '$error. Wyjścia są bez zmian.';
  }

  @override
  String get deskOutSomethingWrong => 'Coś poszło nie tak';

  @override
  String get deskOutTryAgain => 'Spróbuj ponownie';

  @override
  String get deskOutToastNotPosted => 'Nie opublikowano';

  @override
  String get deskOutToastNotCancelled => 'Nie anulowano';

  @override
  String get deskOutSplitDialogTitle => 'Podział wyjść';

  @override
  String get deskOutConsDialogTitle => 'Scalanie wyjść';

  @override
  String get deskOutPostingDesc => 'Publikowanie.';

  @override
  String get deskOutDoneDesc => 'Gotowe.';

  @override
  String get deskOutSplitDesc =>
      'Więcej wyjść, aby kilka wysyłek mogło iść jedna po drugiej.';

  @override
  String get deskOutConsDesc => 'Jedno wyjście zamiast wielu.';

  @override
  String deskOutNothingText(String what) {
    return 'Nie ma czego scalać: portfel ma $what. Scalanie łączy kilka wyjść w jedno.';
  }

  @override
  String get deskOutWhatFewer => 'mniej niż dwa wyjścia do wydania';

  @override
  String get deskOutWhatOne => 'jedno wyjście do wydania';

  @override
  String get deskOvNotUpdated => 'Nie zaktualizowano';

  @override
  String get deskOvNodeNotStarted => 'Nie uruchomiono węzła';

  @override
  String get deskOvNodeAddrTitle => 'Zaktualizowano adres węzła';

  @override
  String get deskOvNodeAddrText =>
      'Teraz używany jest node.epiccash.com zamiast node.epiccash.com:3413.';

  @override
  String get deskOvNodeIncompatTitle =>
      'Wersja tego węzła nie jest zgodna z tym portfelem';

  @override
  String deskOvNodeUrl(String url) {
    return 'Węzeł: $url';
  }

  @override
  String get deskOvUsePublicNode => 'Użyj węzła publicznego';

  @override
  String get deskOvUseLocalNode => 'Użyj węzła lokalnego';

  @override
  String get deskOvHide => 'Ukryj';

  @override
  String deskOvCantReachNode(String url) {
    return 'Brak połączenia z węzłem $url';
  }

  @override
  String get deskOvCantReachNodeText =>
      'Sprawdź, czy działa i jest osiągalny. Salda mogą być nieaktualne, a wysyłanie jest wstrzymane.';

  @override
  String get deskOvStarting => 'Uruchamianie';

  @override
  String get deskOvStartNode => 'Uruchom węzeł';

  @override
  String get deskOvNodeSettings => 'Ustawienia węzła';

  @override
  String get deskOvTitle => 'Przegląd';

  @override
  String get deskOvShowAmounts => 'Pokaż kwoty';

  @override
  String get deskOvHideAmounts => 'Ukryj kwoty';

  @override
  String get deskOvRefresh => 'Odśwież';

  @override
  String get deskOvStepDone => 'gotowe';

  @override
  String get deskOvStepNow => 'w toku';

  @override
  String get deskOvStepWait => 'oczekuje';

  @override
  String deskOvStepSemantics(String text, String state) {
    return '$text, $state';
  }

  @override
  String get deskOvStartingUp => 'Uruchamianie';

  @override
  String get deskOvStepUnlocked => 'Portfel odblokowany';

  @override
  String get deskOvStepConnected => 'Połączono z węzłem';

  @override
  String get deskOvStepUpdating => 'Aktualizowanie sald';

  @override
  String get deskOvStepEpicbox => 'Uruchamianie odbioru przez Epicbox';

  @override
  String deskOvSyncTitle(int percent) {
    return 'Synchronizacja węzła: $percent%';
  }

  @override
  String deskOvSyncText(String block) {
    return 'Pobieranie bloków. Salda pokazują stan znany portfelowi w bloku $block. Wysyłanie będzie możliwe, gdy węzeł nadrobi zaległości.';
  }

  @override
  String get deskOvSyncProgress => 'Postęp synchronizacji węzła';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent% łańcucha';
  }

  @override
  String get deskOvReceiveEpic => 'Odbierz EPIC';

  @override
  String get deskOvSend => 'Wyślij';

  @override
  String get deskOvReceive => 'Odbierz';

  @override
  String get deskOvSendWaits =>
      'Wysyłanie będzie możliwe po synchronizacji węzła.';

  @override
  String get deskOvAvailable => 'Do wydania';

  @override
  String deskOvAsOfBlock(String block) {
    return 'Stan na blok $block';
  }

  @override
  String get deskOvEmptyHint =>
      'Udostępnij adres Epicbox, aby odebrać pierwsze EPIC.';

  @override
  String get deskOvFiatNote => '  całe saldo, CoinGecko';

  @override
  String get deskOvBreakTotal => 'Razem';

  @override
  String get deskOvBreakConfirming => 'Potwierdzane';

  @override
  String get deskOvBreakImmature => 'Niedojrzałe';

  @override
  String get deskOvBreakAwaiting => 'Czeka na sfinalizowanie';

  @override
  String get deskOvBreakLocked => 'Zablokowane w wysyłkach';

  @override
  String get deskOvUpdating => 'Aktualizacja';

  @override
  String get deskOvHiddenAmount => 'Ukryta kwota';

  @override
  String get deskOvLoading => 'Wczytywanie transakcji';

  @override
  String get deskOvEmptyTitle => 'Brak transakcji';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Odebrane EPIC pojawią się tu najpierw jako potwierdzane, a po $blocks bloku jako do wydania.',
      many:
          'Odebrane EPIC pojawią się tu najpierw jako potwierdzane, a po $blocks blokach jako do wydania.',
      few:
          'Odebrane EPIC pojawią się tu najpierw jako potwierdzane, a po $blocks blokach jako do wydania.',
      one:
          'Odebrane EPIC pojawią się tu najpierw jako potwierdzane, a po $blocks bloku jako do wydania.',
    );
    return '$_temp0';
  }

  @override
  String get deskOvShowAddress => 'Pokaż adres';

  @override
  String get deskOvReceiveFile => 'Odbierz plik';

  @override
  String get deskOvRecent => 'Ostatnia aktywność';

  @override
  String deskOvViewAll(int count) {
    return 'Zobacz wszystkie: $count';
  }

  @override
  String deskOvPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count otwartej wysyłki plikiem',
      many: '$count otwartych wysyłek plikiem',
      few: '$count otwarte wysyłki plikiem',
      one: '$count otwarta wysyłka plikiem',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => 'Sfinalizuj plikiem odpowiedzi od odbiorcy.';

  @override
  String get deskOvFinalize => 'Sfinalizuj';

  @override
  String get deskTxMethodFile => 'Bezpośrednio · Plik';

  @override
  String get deskTxMiningReward => 'Nagroda za kopanie';

  @override
  String get deskTxReceived => 'Odebrana';

  @override
  String get deskTxSent => 'Wysłana';

  @override
  String get deskTxUnknownSender => 'Nieznany nadawca';

  @override
  String get deskTxUnknownRecipient => 'Nieznany odbiorca';

  @override
  String get deskTxNoteBlock => 'Czas bloku. Nadawca nie jest zapisany.';

  @override
  String get deskTxNoteScanTime =>
      'Czas skanowania; nie udało się odczytać czasu bloku. Nadawca nie jest zapisany.';

  @override
  String get deskTxNoteUnknown => 'Nadawca nie jest zapisany.';

  @override
  String get deskTxFoundRestoredLabel => 'Przywrócona';

  @override
  String get deskTxFoundRestoredLine => 'Znaleziona przy przywracaniu';

  @override
  String get deskTxFoundRestoredStep =>
      'Znaleziona przy przywracaniu tego portfela';

  @override
  String get deskTxFoundRestoredTip =>
      'Znaleziona w łańcuchu przy przywracaniu tego portfela. Nadawca nie jest zapisany.';

  @override
  String get deskTxFoundRescanLabel => 'Ze skanowania';

  @override
  String get deskTxFoundRescanLine => 'Znaleziona przy sprawdzaniu salda';

  @override
  String get deskTxFoundRescanStep =>
      'Znaleziona przy ponownym sprawdzaniu salda';

  @override
  String get deskTxFoundRescanTip =>
      'Znaleziona w łańcuchu przy ponownym sprawdzaniu salda. Nadawca nie jest zapisany.';

  @override
  String get deskTxFoundScanLine => 'Znaleziona przy skanowaniu';

  @override
  String get deskTxFoundScanStep => 'Znaleziona przy skanowaniu';

  @override
  String get deskTxFoundScanTip =>
      'Znaleziona w łańcuchu przy skanowaniu. Nadawca nie jest zapisany.';

  @override
  String get deskTxBackupTip => 'Dodana z kopii historii.';

  @override
  String get deskTxFromBackup => 'Z kopii';

  @override
  String get deskTxStatusImmature => 'Niedojrzała';

  @override
  String get deskTxStatusWaitingSender => 'Czeka na finalizację przez nadawcę';

  @override
  String get deskTxStatusWaitingResponseFile => 'Czeka na plik odpowiedzi';

  @override
  String get deskTxStatusWaitingRecipient => 'Czeka na podpis odbiorcy';

  @override
  String get deskTxStatusWaitingBlock => 'Czeka na blok';

  @override
  String deskTxStatusConfirming(int confirmations, int needed) {
    return 'Potwierdzanie $confirmations/$needed';
  }

  @override
  String get deskTxStatusCancelled => 'Anulowana';

  @override
  String get deskTxToday => 'dzisiaj';

  @override
  String get deskTxYesterday => 'wczoraj';

  @override
  String deskTxDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia temu',
      many: '$count dni temu',
      few: '$count dni temu',
      one: '$count dzień temu',
    );
    return '$_temp0';
  }

  @override
  String deskTxTodayAt(String time) {
    return 'Dzisiaj $time';
  }

  @override
  String deskTxDayToday(String date) {
    return 'Dzisiaj · $date';
  }

  @override
  String deskTxDayYesterday(String date) {
    return 'Wczoraj · $date';
  }

  @override
  String deskTxFee(String amount) {
    return 'Opłata $amount';
  }

  @override
  String get deskTxPaymentProof => 'Dowód płatności';

  @override
  String get deskTxFinalize => 'Sfinalizuj';

  @override
  String deskTxSemReceived(String amount, String who, String status) {
    return 'Odebrano $amount, $who, $status';
  }

  @override
  String deskTxSemSent(String amount, String who, String status) {
    return 'Wysłano $amount, $who, $status';
  }

  @override
  String deskTxSemKind(String kind, String amount, String who, String status) {
    return '$kind $amount, $who, $status';
  }

  @override
  String get deskTxHiddenAmount => 'ukryta kwota';

  @override
  String get deskTxNowBackup => 'Z kopii; łańcucha nie sprawdzano.';

  @override
  String deskTxNowImmature(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $count potwierdzenia.',
      many:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $count potwierdzeniach.',
      few:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $count potwierdzeniach.',
      one:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $count potwierdzeniu.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Podpisana i odesłana. Czeka na finalizację przez nadawcę.';

  @override
  String get deskTxNowWaitingResponseFile =>
      'Czeka na plik odpowiedzi. Sfinalizuj, gdy dotrze.';

  @override
  String get deskTxNowWaitingRecipient =>
      'Czeka na podpis odbiorcy. Nic nie opuści portfela przed finalizacją.';

  @override
  String get deskTxNowPosted => 'Opublikowana w sieci, czeka na blok.';

  @override
  String deskTxNowConfirming(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'W bloku, $confirmations z $needed potwierdzenia.',
      many: 'W bloku, $confirmations z $needed potwierdzeń.',
      few: 'W bloku, $confirmations z $needed potwierdzeń.',
      one: 'W bloku, $confirmations z $needed potwierdzenia.',
    );
    return '$_temp0';
  }

  @override
  String deskTxNowConfirmed(int confirmations) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Potwierdzona, $confirmations potwierdzenia.',
      many: 'Potwierdzona, $confirmations potwierdzeń.',
      few: 'Potwierdzona, $confirmations potwierdzenia.',
      one: 'Potwierdzona, $confirmations potwierdzenie.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Anulowana.';

  @override
  String get deskTxNotCancelled => 'Nie anulowano';

  @override
  String get deskTxCancelled => 'Transakcja anulowana';

  @override
  String get deskTxCancelling => 'Anulowanie';

  @override
  String get deskTxHeadRestored => 'przywrócona';

  @override
  String get deskTxHeadFoundOnChain => 'znaleziona w łańcuchu';

  @override
  String get deskTxHeadBackup => 'dodana z kopii historii';

  @override
  String deskTxHeadFrom(String who) {
    return 'od $who';
  }

  @override
  String deskTxHeadTo(String who) {
    return 'do $who';
  }

  @override
  String get deskTxSubProgress => 'Postęp';

  @override
  String get deskTxSubDetails => 'Szczegóły';

  @override
  String get deskTxFactDate => 'Data';

  @override
  String get deskTxFactFrom => 'Od';

  @override
  String get deskTxFactTo => 'Do';

  @override
  String get deskTxCopyAddress => 'Kopiuj adres';

  @override
  String get deskTxFactMethod => 'Metoda';

  @override
  String get deskTxFactAmount => 'Kwota';

  @override
  String get deskTxFactFee => 'Opłata';

  @override
  String get deskTxFactTotal => 'Razem';

  @override
  String get deskTxFactMessage => 'Wiadomość';

  @override
  String get deskTxSignedByRecipient => 'Podpisana przez odbiorcę';

  @override
  String get deskTxProofView => 'Pokaż';

  @override
  String get deskTxTechTitle => 'Szczegóły techniczne';

  @override
  String get deskTxTechId => 'ID';

  @override
  String get deskTxTechSlate => 'ID slate';

  @override
  String get deskTxCopySlate => 'Kopiuj ID slate';

  @override
  String get deskTxTechHeight => 'Wysokość';

  @override
  String get deskTxTechKernel => 'Kernel';

  @override
  String get deskTxTechConfirmed => 'Potwierdzona';

  @override
  String get deskTxTechCredited => 'Uznano';

  @override
  String get deskTxTechDebited => 'Obciążono';

  @override
  String get deskTxTechStatus => 'Stan';

  @override
  String get deskTxTechType => 'Typ';

  @override
  String get deskTxStepMined => 'Wykopana w bloku';

  @override
  String get deskTxStepSpendable => 'Do wydania';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jeszcze $count bloku',
      many: 'jeszcze $count bloków',
      few: 'jeszcze $count bloki',
      one: 'jeszcze $count blok',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Odebrano slate';

  @override
  String get deskTxStepCreated => 'Utworzona i podpisana';

  @override
  String get deskTxStepSignedReturned => 'Podpisana i odesłana';

  @override
  String get deskTxStepWaitingFile => 'Czeka na plik odpowiedzi';

  @override
  String get deskTxStepWaitingRecipient => 'Czeka na odbiorcę';

  @override
  String get deskTxStepPosted => 'Opublikowana w sieci';

  @override
  String get deskTxStepConfirming => 'Potwierdzanie';

  @override
  String deskTxStepProgress(int confirmations, int needed) {
    return '$confirmations z $needed';
  }

  @override
  String get deskTxCancelIncomingTitle => 'Anulować tę płatność?';

  @override
  String get deskTxCancelOutgoingTitle => 'Anulować tę wysyłkę?';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '$amount EPIC od $who zniknie z twojego salda. Portfel najpierw pyta węzeł i odmawia, jeśli płatność jest już w puli węzła albo w bloku. Jeśli nadawca opublikuje ją później, może jednak dotrzeć.';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC do $who. Zablokowana kwota wróci do salda. Jeśli odbiorca już ją sfinalizował, może jednak zostać potwierdzona.';
  }

  @override
  String get deskTxCancelKeep => 'Zostaw';

  @override
  String get deskTxCancelIncomingAction => 'Anuluj płatność';

  @override
  String get deskTxCancelOutgoingAction => 'Anuluj wysyłkę';

  @override
  String deskTxProofIncoming(String amount) {
    return 'Dowodzi, że ten portfel odebrał $amount EPIC w tym kernelu.';
  }

  @override
  String deskTxProofOutgoing(String amount) {
    return 'Dowodzi, że odbiorca odebrał $amount EPIC w tym kernelu.';
  }

  @override
  String get deskTxProofSenderAddress => 'Adres nadawcy';

  @override
  String get deskTxProofRecipientAddress => 'Adres odbiorcy';

  @override
  String get deskTxProofRecipientSignature => 'Podpis odbiorcy';

  @override
  String get deskTxProofCopyKernel => 'Kopiuj kernel';

  @override
  String get deskTxProofCopySender => 'Kopiuj adres nadawcy';

  @override
  String get deskTxProofCopyRecipient => 'Kopiuj adres odbiorcy';

  @override
  String get deskTxProofCopySignature => 'Kopiuj podpis odbiorcy';

  @override
  String get deskTxProofExport => 'Eksportuj';

  @override
  String get deskTxProofSaved => 'Zapisano dowód';

  @override
  String get deskOnbWelcomeAdd => 'Dodaj portfel';

  @override
  String get deskOnbWelcomeTagline =>
      'Klucze i monety zostają na tym komputerze, chronione hasłem.';

  @override
  String get deskOnbWelcomeCreate => 'Utwórz nowy portfel';

  @override
  String get deskOnbWelcomeCreateSub => 'Nowa fraza odzyskiwania';

  @override
  String get deskOnbWelcomeImport => 'Importuj portfele';

  @override
  String get deskOnbWelcomeImportSub =>
      'Ze starszego Epic Wallet lub z folderu';

  @override
  String get deskOnbWelcomeRestore => 'Przywróć z frazy';

  @override
  String get deskOnbWelcomeRestoreSub => 'Ze słów odzyskiwania';

  @override
  String get deskOnbWelcomeTestNote =>
      'Nowe portfele powstają w tej sieci testowej.';

  @override
  String get deskOnbWelcomeBack => 'Wróć do odblokowania';

  @override
  String get deskOnbWelcomeAdvanced => 'Zaawansowane';

  @override
  String get deskOnbWelcomeNetwork => 'Sieć';

  @override
  String get deskOnbWelcomeNetworkHelp =>
      'Mainnet zawiera prawdziwe EPIC. Floonet i Usernet to sieci testowe.';

  @override
  String get deskOnbWelcomeFolder => 'Folder danych aplikacji';

  @override
  String get deskOnbWelcomeHideDetails => 'Ukryj szczegóły';

  @override
  String get deskOnbWelcomeMoreAbout => 'Więcej o tym';

  @override
  String get deskOnbWelcomeFolderWhere =>
      'Tu aplikacja przechowuje portfele i ustawienia.';

  @override
  String get deskOnbWelcomeFolderDetail =>
      'Przy węźle lokalnym jest tu też blockchain. Nowy folder musi być pusty: aplikacja utworzy w nim swoje foldery i będzie go dalej używać.';

  @override
  String deskOnbWelcomeUsing(String folder) {
    return 'Używany folder: $folder. Aplikacja uruchomi się ponownie, aby go użyć.';
  }

  @override
  String get deskOnbWelcomeLocked =>
      'Można go zmienić tylko przed dodaniem pierwszego portfela.';

  @override
  String get deskOnbWelcomeChooseFolder => 'Wybierz folder';

  @override
  String get deskOnbWelcomeDefaultFolder => 'Folder domyślny';

  @override
  String get deskOnbWelcomeFolderNotEmpty =>
      'Ten folder nie jest pusty. Wybierz nowy, pusty folder.';

  @override
  String get deskOnbWelcomeFolderIsWallet =>
      'To folder portfela. Wybierz nowy, pusty folder.';

  @override
  String get deskOnbWelcomeChoose => 'Wybierz';

  @override
  String get deskOnbStepPassword => 'Hasło';

  @override
  String get deskOnbStepPhrase => 'Fraza odzyskiwania';

  @override
  String get deskOnbCreateStageCreate =>
      'Tworzenie portfela i jego frazy odzyskiwania';

  @override
  String get deskOnbCreateStageSave => 'Zapisywanie konta';

  @override
  String get deskOnbCreateNotCreated => 'Nie utworzono portfela';

  @override
  String get deskOnbCreateCreating => 'Tworzenie portfela';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'Portfel w sieci $network, sieci testowej.';
  }

  @override
  String get deskOnbCreateFailedTitle => 'Nie udało się utworzyć portfela';

  @override
  String get deskOnbCreateDiskFull =>
      'Nie udało się zapisać konta: dysk jest pełny.';

  @override
  String get deskOnbCreateWait =>
      'To może potrwać do minuty. Nie zamykaj aplikacji.';

  @override
  String get deskOnbCreateLocking => 'Blokowanie otwartego portfela';

  @override
  String get deskOnbCreateSide => 'Nowy portfel';

  @override
  String get deskOnbCreateTitle => 'Utwórz portfel';

  @override
  String get deskOnbCreateLead =>
      'Hasło odblokowuje ten portfel na tym komputerze. Nie odzyska monet; robi to fraza z następnego kroku.';

  @override
  String get deskOnbCreateTestNote =>
      'Portfel w sieci testowej, nie na prawdziwe EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'Te słowa to jedyny sposób na odzyskanie monet, jeśli ten komputer się zepsuje. Zapisz je na papierze w podanej kolejności.';

  @override
  String get deskOnbCreateRevealFirst => 'Najpierw odkryj frazę';

  @override
  String get deskOnbCreateWarn => 'Każdy, kto zna te słowa, może zabrać monety';

  @override
  String get deskOnbCreateReveal => 'Odkryj frazę';

  @override
  String get deskOnbCreateCheckScreen =>
      'Upewnij się, że nikt nie widzi ekranu.';

  @override
  String get deskOnbCreateHide => 'Ukryj';

  @override
  String get deskOnbCreateShowQr => 'Pokaż kod QR';

  @override
  String get deskOnbCreateHideQr => 'Ukryj kod QR';

  @override
  String get deskOnbCreateQrWarn =>
      'Każdy, kto zeskanuje ten kod, może zabrać monety';

  @override
  String get deskOnbCreateQrWarnText =>
      'Skanuj go tylko do innego portfela, któremu ufasz.';

  @override
  String get deskOnbCreateQrLabel => 'Fraza odzyskiwania jako kod QR';

  @override
  String deskOnbCreateWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wszystkie $count słowa',
      many: 'wszystkie $count słów',
      few: 'wszystkie $count słowa',
      one: '$count słowo',
    );
    return 'Zapisane na papierze: $_temp0';
  }

  @override
  String get deskOnbRestoreDone => 'Portfel przywrócony.';

  @override
  String get deskOnbRestoreNotRestored => 'Nie przywrócono portfela';

  @override
  String get deskOnbRestoreRestoring => 'Przywracanie portfela';

  @override
  String get deskOnbRestoreFailedTitle => 'Nie udało się przywrócić portfela';

  @override
  String get deskOnbRestorePermission =>
      'Nie udało się zapisać plików portfela: brak uprawnień w ~/.config/Epic Cash Desktop.';

  @override
  String get deskOnbRestoreWait =>
      'To może potrwać do minuty. Saldo pojawi się po pierwszym skanowaniu łańcucha.';

  @override
  String get deskOnbRestoreSide => 'Przywróć portfel';

  @override
  String get deskOnbRestoreChoosePassword => 'Wybierz hasło';

  @override
  String deskOnbRestorePasswordLead(int count) {
    return 'Fraza z $count słów jest poprawna. Ustaw hasło, które odblokowuje ten portfel na tym komputerze.';
  }

  @override
  String get deskOnbRestoreNothingToPaste =>
      'Nie ma czego wkleić: w schowku nie ma słów.';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return 'Słowo $position, „$word”, nie występuje na liście słów.';
  }

  @override
  String deskOnbRestoreAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wszystkie $count słowa są poprawne.',
      many: 'Wszystkie $count słów jest poprawnych.',
      few: 'Wszystkie $count słowa są poprawne.',
      one: '$count słowo jest poprawne.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreStaysHere =>
      'Fraza nigdy nie opuszcza tego komputera.';

  @override
  String get deskOnbRestoreChecksumFirm =>
      'Suma kontrolna tej frazy się nie zgadza. Porównaj każde słowo z kartką.';

  @override
  String deskOnbRestoreChecksumSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Na razie $count słowa; suma kontrolna się nie zgadza. Pisz dalej albo porównaj każde słowo z kartką.',
      many:
          'Na razie $count słów; suma kontrolna się nie zgadza. Pisz dalej albo porównaj każde słowo z kartką.',
      few:
          'Na razie $count słowa; suma kontrolna się nie zgadza. Pisz dalej albo porównaj każde słowo z kartką.',
      one:
          'Na razie $count słowo; suma kontrolna się nie zgadza. Pisz dalej albo porównaj każde słowo z kartką.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWordsLead =>
      'Wpisz słowa po kolei albo wklej całą frazę do dowolnego pola. Podziały wierszy, przecinki i numeracja są pomijane.';

  @override
  String get deskOnbRestoreClear => 'Wyczyść';

  @override
  String deskOnbRestoreUseWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Użyj $count słowa',
      many: 'Użyj $count słów',
      few: 'Użyj $count słów',
      one: 'Użyj $count słowa',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWords => 'Słowa';

  @override
  String deskOnbRestoreFilledOf(int filled, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total słowa',
      many: '$total słów',
      few: '$total słów',
      one: '$total słowa',
    );
    return '$filled z $_temp0';
  }

  @override
  String get deskOnbKillTitle => 'Epic już działa';

  @override
  String get deskOnbKillBody =>
      'Inny proces portfela lub węzła używa plików i portów portfela. Zamknij go, aby odblokować tutaj, albo anuluj i zamknij go samodzielnie.';

  @override
  String get deskOnbKillProcesses => 'Uruchomione procesy';

  @override
  String get deskOnbKillRoleWallet => 'usługa portfela';

  @override
  String get deskOnbKillRoleNode => 'węzeł';

  @override
  String get deskOnbKillNote =>
      'Zamknięcie przerwie to, co robią, np. synchronizację węzła lub odbieranie płatności. Po odblokowaniu uruchomią się ponownie z tej aplikacji.';

  @override
  String get deskOnbKillClosing => 'Zamykanie…';

  @override
  String get deskOnbKillClose => 'Zamknij i odblokuj';

  @override
  String get deskOnbSameTitle => 'Ten portfel już tu jest';

  @override
  String get deskOnbSameBody =>
      'Fraza należy do portfela z listy. Nic nie dodano.';

  @override
  String get deskOnbSameWallet => 'Portfel';

  @override
  String get deskOnbSameNote =>
      'Otwórz poprosi o hasło tego portfela. Anuluj zostawi frazę w polach.';

  @override
  String get deskOnbSameOpen => 'Otwórz';

  @override
  String get deskOnbUnlockWhoWindows =>
      'Każdy, kto używa tego konta Windows, może otworzyć ten portfel.';

  @override
  String get deskOnbUnlockWho =>
      'Każdy, kto używa tego konta, może otworzyć ten portfel.';

  @override
  String get deskOnbUnlockWrong =>
      'Nieprawidłowe hasło. Sprawdź Caps Lock i układ klawiatury.';

  @override
  String get deskOnbUnlockPortInUse =>
      'Usługa portfela się nie uruchomiła: port 3415 zajmuje inny program.';

  @override
  String get deskOnbUnlockStageCheck => 'Sprawdzanie plików portfela';

  @override
  String get deskOnbUnlockStageProcesses =>
      'Szukanie wciąż działających procesów portfela';

  @override
  String get deskOnbUnlockStageClosing => 'Zamykanie starych procesów portfela';

  @override
  String get deskOnbUnlockStageWallet => 'Uruchamianie usługi portfela';

  @override
  String get deskOnbUnlockStageUnlock => 'Odblokowywanie portfela';

  @override
  String get deskOnbUnlockEnter => 'Wpisz hasło';

  @override
  String get deskOnbUnlockCloseOthers =>
      'Zamknij pozostałe procesy Epic, a potem odblokuj.';

  @override
  String get deskOnbUnlockRememberedUnavailable =>
      'Zapamiętane hasło jest niedostępne. Wpisz hasło.';

  @override
  String get deskOnbUnlockRememberedForgotten =>
      'Zapamiętane hasło zostało zapomniane. Wpisz hasło.';

  @override
  String get deskOnbUnlockNotRemembered => 'Nie zapamiętano';

  @override
  String get deskOnbUnlockKeyStore =>
      'Magazyn kluczy tego komputera jest niedostępny.';

  @override
  String get deskOnbUnlockThisWallet => 'ten portfel';

  @override
  String get deskOnbUnlockFailed => 'Odblokowanie nie powiodło się';

  @override
  String get deskOnbUnlockFailedLead =>
      'Portfel się nie otworzył. Przyczyna jest poniżej.';

  @override
  String get deskOnbUnlockFailedBox => 'Portfel się nie otworzył';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return 'Odblokowywanie: $name';
  }

  @override
  String get deskOnbUnlockStepsLead => 'Każdy krok pojawia się po zakończeniu.';

  @override
  String get deskOnbUnlockNote =>
      'Potem otworzy się Przegląd i dokończy resztę w tle: połączenie z węzłem, aktualizację sald, włączenie odbierania.';

  @override
  String get deskOnbUnlockTitle => 'Odblokuj portfel';

  @override
  String get deskOnbUnlockLead => 'Klucze zostają na tym komputerze.';

  @override
  String get deskOnbUnlockRemember => 'Zapamiętaj na tym komputerze';

  @override
  String deskOnbUnlockRememberFor(String who) {
    return 'Na 30 dni. $who';
  }

  @override
  String get deskOnbUnlockMissingTitle => 'Brak folderu tego portfela';

  @override
  String deskOnbUnlockMissingText(String folder) {
    return 'Był w $folder';
  }

  @override
  String get deskOnbUnlockRemove => 'Usuń';

  @override
  String get deskOnbUnlockTryAgain => 'Spróbuj ponownie';

  @override
  String get deskOnbUnlockButton => 'Odblokuj';

  @override
  String get deskOnbNodeFreeUnknown => 'Wolne miejsce nieznane';

  @override
  String deskOnbNodeFreeHere(String size) {
    return 'Wolne tutaj: $size';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'Około $size na dysku';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return '$size na dysku';
  }

  @override
  String get deskOnbNodeSeparate => 'Osobny program.';

  @override
  String get deskOnbNodeSeparateText =>
      'Portfel uruchamia węzeł Epic i zatrzymuje go razem z aplikacją.';

  @override
  String get deskOnbNodeFirewall => 'Windows zapyta raz';

  @override
  String get deskOnbNodeFirewallText =>
      'o przepuszczenie go przez zaporę. Zezwól w sieciach prywatnych.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'i powoli przybywa. $free.';
  }

  @override
  String get deskOnbNodeHours => 'Godziny synchronizacji';

  @override
  String get deskOnbNodeHoursText =>
      'za pierwszym razem, od 2 do 6 przy typowym łączu. Portfel pokazuje postęp i w tym czasie może używać węzła publicznego.';

  @override
  String get deskOnbNodeDownload => 'Około 4 GB do pobrania';

  @override
  String get deskOnbNodeDownloadText =>
      'za pierwszym razem, potem trochę każdego dnia.';

  @override
  String get deskOnbNodeFound => 'Znaleziono';

  @override
  String deskOnbNodeFoundAt(String version, String address) {
    return 'Epic $version pod $address';
  }

  @override
  String deskOnbNodeHeight(String height) {
    return 'wysokość $height';
  }

  @override
  String get deskOnbNodeSynced => 'zsynchronizowany';

  @override
  String get deskOnbNodeNoAnswer => 'Żaden węzeł nie odpowiada';

  @override
  String deskOnbNodeNoAnswerAt(String address) {
    return 'pod $address. Uruchom go albo sprawdź adres i port.';
  }

  @override
  String get deskOnbNodeExisting =>
      'Użyj węzła, który już działa na tym komputerze';

  @override
  String get deskOnbNodeExistingText =>
      'Węzeł Epic z GUI lub CLI. Portfel łączy się z nim i niczego nie uruchamia.';

  @override
  String get deskOnbNodeAddress => 'Adres węzła na tym komputerze';

  @override
  String get deskOnbNodeCheck => 'Sprawdź';

  @override
  String get deskOnbNodeBundled => 'Uruchom wbudowany węzeł';

  @override
  String get deskOnbNodeBundledText =>
      'Pobiera i synchronizuje łańcuch do własnego folderu portfela. Nic nie jest pobierane przed kliknięciem Zapisz w ostatnim kroku.';

  @override
  String deskOnbNodeFallback(String host) {
    return 'Używaj $host, dopóki węzeł lokalny się nie zsynchronizuje. Węzeł lokalny przejmie pracę sam.';
  }

  @override
  String get deskOnbNodeDialogTitle => 'Węzeł lokalny';

  @override
  String get deskOnbNodeDialogBody =>
      'Co oznacza uruchomienie węzła tutaj i którego węzła używać.';

  @override
  String get deskOnbNodeUseThis => 'Użyj tego węzła';

  @override
  String get deskOnbNodeStart => 'Uruchom węzeł lokalny';

  @override
  String deskOnbRestorePasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wklejono $count słowa; fraza ma 12, 15, 18, 21 lub 24 słowa',
      many: 'Wklejono $count słów; fraza ma 12, 15, 18, 21 lub 24 słowa',
      few: 'Wklejono $count słowa; fraza ma 12, 15, 18, 21 lub 24 słowa',
      one: 'Wklejono $count słowo; fraza ma 12, 15, 18, 21 lub 24 słowa',
    );
    return '$_temp0';
  }

  @override
  String deskOnbWordN(int number) {
    return 'Słowo $number';
  }

  @override
  String get deskOnbImportEnterOld => 'Wpisz stare hasło';

  @override
  String deskOnbImportNewShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count znaku',
      many: '$count znaków',
      few: '$count znaki',
      one: '$count znak',
    );
    return 'Nowe hasło: co najmniej $_temp0';
  }

  @override
  String get deskOnbImportNewDiffer => 'Nowe hasła się różnią';

  @override
  String deskOnbImportWalletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portfela',
      many: '$count portfeli',
      few: '$count portfele',
      one: '$count portfel',
    );
    return '$_temp0';
  }

  @override
  String deskOnbImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaimportowano $count portfela.',
      many: 'Zaimportowano $count portfeli.',
      few: 'Zaimportowano $count portfele.',
      one: 'Zaimportowano portfel.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFindingTitle => 'Szukanie portfeli';

  @override
  String get deskOnbImportFindingLead =>
      'Przeszukiwanie folderów starszych wersji Epic Wallet i programu epic. Nic nie jest zmieniane.';

  @override
  String deskOnbImportFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znaleziono $count portfela',
      many: 'Znaleziono $count portfeli',
      few: 'Znaleziono $count portfele',
      one: 'Znaleziono $count portfel',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFoundLead => 'Stare foldery są tylko odczytywane.';

  @override
  String get deskOnbImportNoneTitle => 'Nie znaleziono portfeli';

  @override
  String get deskOnbImportNoneLead =>
      'Wybierz folder portfela albo przywróć go z frazy odzyskiwania.';

  @override
  String get deskOnbImportChooseTitle => 'Wybierz portfele';

  @override
  String get deskOnbImportChooseLead =>
      'Zaznaczone portfele zostaną dodane do aplikacji. Historię odtworzy skanowanie.';

  @override
  String get deskOnbImportCheckTitle => 'Sprawdzanie użycia';

  @override
  String get deskOnbImportCheckLead =>
      'Portfel używany przez inny program nie zostanie zaimportowany.';

  @override
  String get deskOnbImportTitle => 'Import';

  @override
  String get deskOnbImportLead =>
      'Każdy portfel raz poprosi o swoje stare hasło.';

  @override
  String get deskOnbImportDoneTitle => 'Portfele zaimportowane';

  @override
  String get deskOnbImportDoneLead =>
      'Przy pierwszym odblokowaniu każdy portfel przeskanuje łańcuch w poszukiwaniu swojej historii.';

  @override
  String deskOnbImportSelected(int selected, int total) {
    return 'Wybrano $selected z $total';
  }

  @override
  String get deskOnbImportChecking => 'Sprawdzanie…';

  @override
  String get deskOnbImportCloseOther =>
      'Zamknij inny program albo pomiń portfel';

  @override
  String deskOnbImportImportedOf(int done, int total) {
    return 'Zaimportowano $done z $total';
  }

  @override
  String get deskOnbImportOpen => 'Otwórz portfel';

  @override
  String get deskOnbImportStepFind => 'Szukaj';

  @override
  String get deskOnbImportStepChoose => 'Wybór';

  @override
  String get deskOnbImportStepCheck => 'Kontrola';

  @override
  String get deskOnbImportBack => 'Wstecz';

  @override
  String get deskOnbImportSkip => 'Pomiń';

  @override
  String get deskOnbImportOlder => 'Starszy Epic Wallet';

  @override
  String get deskOnbImportOlderSub => 'Konta i foldery';

  @override
  String get deskOnbImportEpicProgram => 'Program epic';

  @override
  String get deskOnbImportSearching => 'Szukanie…';

  @override
  String get deskOnbImportRestore => 'Przywróć z frazy';

  @override
  String deskOnbImportLastUsed(String date) {
    return 'Ostatnio używany $date';
  }

  @override
  String deskOnbImportSecondCopy(String reason) {
    return '$reason. Zaznacz, aby dodać drugą kopię.';
  }

  @override
  String deskOnbImportCannot(String name) {
    return '$name: nie można zaimportować';
  }

  @override
  String get deskOnbImportInApp => 'W aplikacji';

  @override
  String get deskOnbImportSameWallet => 'Ten sam portfel';

  @override
  String get deskOnbImportNotInUse => 'Nieużywany';

  @override
  String get deskOnbImportNotChecked => 'Niesprawdzony';

  @override
  String get deskOnbImportSkipped => 'Pominięty';

  @override
  String get deskOnbImportInUse => 'W użyciu';

  @override
  String get deskOnbImportInUseText =>
      'Używany przez inny program. Zamknij starszy Epic Wallet lub program epic, a potem sprawdź ponownie.';

  @override
  String get deskOnbImportCheckAgain => 'Sprawdź ponownie';

  @override
  String get deskOnbImportImported => 'Zaimportowany';

  @override
  String get deskOnbImportImporting => 'Importowanie…';

  @override
  String get deskOnbImportWaiting => 'Czeka';

  @override
  String get deskOnbImportOldPassword => 'Stare hasło';

  @override
  String deskOnbImportOldHelp(String name) {
    return 'Hasło portfela $name w starszej aplikacji.';
  }

  @override
  String deskOnbImportOldOf(String name) {
    return 'Stare hasło portfela $name';
  }

  @override
  String deskOnbImportOldShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'co najmniej $count znaku.',
      many: 'co najmniej $count znaków.',
      few: 'co najmniej $count znaki.',
      one: 'co najmniej $count znak.',
    );
    return 'Stare hasło jest za krótkie. Wybierz nowe, $_temp0';
  }

  @override
  String get deskOnbImportNewPassword => 'Nowe hasło';

  @override
  String get deskOnbImportRepeat => 'Powtórz';

  @override
  String get deskOnbImportRepeatNew => 'Powtórz nowe hasło';

  @override
  String get deskOnbImportUnchanged =>
      'Stare foldery są bez zmian. Starsza aplikacja nadal może je otworzyć.';

  @override
  String get deskOnbImportStopTitle => 'Przerwać import?';

  @override
  String get deskOnbImportStopBody =>
      'Zaimportowane do tej pory portfele zostaną usunięte. Stare foldery są bez zmian.';

  @override
  String get deskOnbImportGoBack => 'Wróć';

  @override
  String get deskOnbImportStop => 'Przerwij import';

  @override
  String get deskRailWaitingTor => 'Czeka na Tor';

  @override
  String get deskRailOn => 'Włączony';

  @override
  String get deskRailConnecting => 'Łączenie';

  @override
  String get deskRailSlow => 'Wolno';

  @override
  String get deskRailNotAnswering => 'Nie odpowiada';

  @override
  String get deskRailOff => 'Wyłączony';

  @override
  String get deskRailChecking => 'Sprawdzanie';

  @override
  String get deskRailOverTor => 'Przez Tor';

  @override
  String get deskRailWaitsForTor => 'Czeka na połączenie z Torem.';

  @override
  String get deskRailPaymentsWait => 'Płatności czekają na serwerze Epicbox.';

  @override
  String get deskRailOpenEpicbox => 'Otwórz odbieranie przez Epicbox';

  @override
  String get deskRailStarting => 'Uruchamianie';

  @override
  String get deskRailNotReceiving => 'Nie odbiera';

  @override
  String get deskRailOnInternet => 'Włączony · internet';

  @override
  String get deskRailOnLocal => 'Włączony · lokalnie';

  @override
  String get deskRailPortInUse => 'Port zajęty';

  @override
  String get deskRailStopped => 'Zatrzymany';

  @override
  String deskRailPortInternet(String port) {
    return 'Port $port · z internetu';
  }

  @override
  String deskRailPortLocal(String port) {
    return 'Port $port · tylko ten komputer';
  }

  @override
  String get deskRailOpenHttp => 'Otwórz odbieranie: Link · HTTP';

  @override
  String get deskRailTorNotInBuild => 'Brak w tej wersji';

  @override
  String get deskRailStartingDots => 'Uruchamianie…';

  @override
  String deskRailTorSlow(String problem) {
    return '$problem. Wysyłanie działa.';
  }

  @override
  String get deskRailTorNoAddress => 'Adres Tor nieopublikowany';

  @override
  String get deskRailOpenPrivacy => 'Otwórz ustawienia prywatności';

  @override
  String get deskRailNode => 'Węzeł';

  @override
  String get deskRailOpenNode => 'Otwórz ustawienia węzła';

  @override
  String get deskAppNodeSyncedTitle => 'Węzeł lokalny zsynchronizowany';

  @override
  String get deskAppNodeSyncedBody =>
      'Węzeł lokalny ma cały łańcuch i można go już używać. Aplikacja uruchomi się ponownie, aby się na niego przełączyć.';

  @override
  String get deskAppNotNow => 'Nie teraz';

  @override
  String get deskAppRestartNow => 'Uruchom ponownie';

  @override
  String get deskAppFirstScanTitle => 'Pierwsze skanowanie portfela';

  @override
  String get deskAppFirstScanBody =>
      'Portfel przeszukuje łańcuch w poszukiwaniu swoich wyjść. Można go dalej używać; saldo zaktualizuje się po zakończeniu skanowania.';

  @override
  String get deskAppScanOutput => 'Przebieg skanowania';

  @override
  String get deskAppWaitingOutput => 'Oczekiwanie na pierwsze wyniki…';

  @override
  String get deskShellNavOverview => 'Przegląd';

  @override
  String get deskShellNavActivity => 'Aktywność';

  @override
  String get deskShellNavSend => 'Wyślij';

  @override
  String get deskShellNavReceive => 'Odbierz';

  @override
  String get deskShellNavOutputs => 'Wyjścia';

  @override
  String get deskShellNavContacts => 'Kontakty';

  @override
  String get deskShellNavSettings => 'Ustawienia';

  @override
  String get deskShellTitleImportTx => 'Import transakcji';

  @override
  String get deskShellTitleFinalizeTx => 'Finalizacja transakcji';

  @override
  String get deskShellLocksAfterSend => 'Zablokuje się po wysłaniu płatności';

  @override
  String get deskShellNotQuitTitle => 'Nie zamknięto';

  @override
  String get deskShellNotQuitBody =>
      'Trwa wysyłka. Zamknij ponownie, gdy się zakończy.';

  @override
  String get deskShellLockedTitle => 'Portfel zablokowany';

  @override
  String get deskShellLockedBody =>
      'Zamknij zamyka aplikację, gdy rdzeń portfela jest połączony.';

  @override
  String deskShellLockWallet(String keys) {
    return 'Zablokuj portfel ($keys)';
  }

  @override
  String get deskShellMainNav => 'Główna nawigacja';

  @override
  String deskShellVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String get deskShellOpenWalletSettings => 'Otwórz ustawienia portfela';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Otwórz ustawienia portfela: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Zmień portfel';

  @override
  String deskShellWalletBy(String maker) {
    return 'Portfel od $maker';
  }

  @override
  String get deskTourOverviewTitle => 'Przegląd';

  @override
  String get deskTourOverviewText =>
      'Saldo i to, co jeszcze się potwierdza, a pod nim ostatnie transakcje. Wszystko inne jest na pasku bocznym.';

  @override
  String get deskTourSendTitle => 'Wyślij';

  @override
  String get deskTourSendText =>
      'Zapłać na adres Epicbox albo utwórz plik transakcji do podpisania przez kogoś. Przed wysłaniem jest podgląd.';

  @override
  String get deskTourReceiveTitle => 'Odbierz';

  @override
  String get deskTourReceiveText =>
      'Adres Epicbox tego portfela: udostępnij go, aby dostać zapłatę. Pliki transakcji do podpisania lub sfinalizowania są pod nim.';

  @override
  String get deskTourInvoicesTitle => 'Faktury';

  @override
  String get deskTourInvoicesText =>
      'Zapłać fakturę, którą ktoś przysłał, albo wystaw ją komuś, kto jest ci winien. Karty przełączają między nimi.';

  @override
  String get deskTourActivityTitle => 'Aktywność';

  @override
  String get deskTourActivityText =>
      'Każda transakcja z jej postępem i szczegółami. Liczba przy tej pozycji paska oznacza, że coś czeka na działanie.';

  @override
  String get deskTourContactsTitle => 'Kontakty';

  @override
  String get deskTourContactsText =>
      'Zapisane adresy z nazwami. Wyślij wybiera stąd.';

  @override
  String get deskTourNodeTitle => 'Ustawienia › Węzeł';

  @override
  String get deskTourNodeText =>
      'Z którego węzła portfel czyta łańcuch. Pozostałe strony ustawień są wymienione po lewej.';

  @override
  String get deskTourHelpTitle => 'Pomoc';

  @override
  String get deskTourHelpText =>
      'Tematy według sekcji i Zgłoś problem. Więcej o każdej stronie jest tutaj, a przewodnik można pokazać ponownie.';

  @override
  String deskTourCounter(int current, int total) {
    return '$current z $total';
  }

  @override
  String get deskTourSemantics => 'Przewodnik po portfelu';

  @override
  String get deskTourSkip => 'Pomiń przewodnik';

  @override
  String get deskTourBack => 'Wstecz';

  @override
  String get deskTourNext => 'Dalej';

  @override
  String get deskKitUnknown => 'Nieznany';

  @override
  String get deskKitRingCancelled => 'Anulowana';

  @override
  String get deskKitRingConfirmed => 'Potwierdzona';

  @override
  String deskKitRingProgress(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '$confirmations z $needed potwierdzeń',
      many: '$confirmations z $needed potwierdzeń',
      few: '$confirmations z $needed potwierdzeń',
      one: '$confirmations z $needed potwierdzeń',
    );
    return '$_temp0';
  }

  @override
  String get deskKitHiddenAmount => 'Ukryta kwota';

  @override
  String get deskKitChooseFile => 'Wybierz plik';

  @override
  String deskKitNeedAction(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wymaga działania',
      many: '$count wymaga działania',
      few: '$count wymagają działania',
      one: '$count wymaga działania',
    );
    return '$label, $_temp0';
  }

  @override
  String get deskKitHealthOn => 'Działa';

  @override
  String get deskKitHealthSlow => 'Wolno';

  @override
  String get deskKitHealthOffline => 'Offline';

  @override
  String get deskKitHealthOff => 'Wyłączony';

  @override
  String get deskKitHealthChecking => 'Sprawdzanie';

  @override
  String get deskKitCloseEsc => 'Zamknij (Esc)';

  @override
  String get deskKitOptional => 'Opcjonalne';

  @override
  String get deskKitBackAlt => 'Wstecz (Alt+Lewo)';

  @override
  String deskKitStepOf(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get deskKitHeroCaptionEpicbox => 'SERWER EPICBOX JĄ TRZYMA';

  @override
  String get deskKitHeroCaptionHttp => 'PROSTO DO PORTFELA';

  @override
  String get deskKitHeroCaptionTor => 'PROSTO, PRZEZ TOR';

  @override
  String get deskKitHeroCaptionFile => 'PLIK I ODPOWIEDŹ';

  @override
  String get deskKitHeroLabelEpicbox =>
      'Epicbox: płatność trafia na serwer Epicbox, który trzyma ją, aż portfel odbiorcy wróci';

  @override
  String get deskKitHeroLabelHttp =>
      'Link · HTTP: płatność trafia prosto do portfela odbiorcy, który musi być otwarty';

  @override
  String get deskKitHeroLabelTor =>
      'Link · Tor: płatność trafia prosto do portfela odbiorcy, przez sieć Tor';

  @override
  String get deskKitHeroLabelFile =>
      'Bezpośrednio · Przesyłanie pliku: plik transakcji jest przekazywany, wraca plik odpowiedzi, potem nadawca finalizuje';

  @override
  String get deskKitReachCheck => 'Sprawdź';

  @override
  String get deskKitReachChecking => 'Sprawdzanie z internetu…';

  @override
  String get deskKitReachNoIpTitle => 'Nie znaleziono publicznego IP';

  @override
  String get deskKitReachNoIpText =>
      'Nie udało się go ustalić przez internet. Spróbuj później.';

  @override
  String deskKitReachNoIpTextLan(String address) {
    return 'Nie udało się go ustalić przez internet. Spróbuj później. W twojej sieci: $address.';
  }

  @override
  String get deskKitReachClosedTitle => 'Nieosiągalny z internetu';

  @override
  String deskKitReachClosedText(String port) {
    return 'Przekieruj port TCP $port na routerze do tego komputera, a potem sprawdź ponownie.';
  }

  @override
  String deskKitReachClosedTextLan(String port, String address) {
    return 'Przekieruj port TCP $port na routerze do tego komputera ($address), a potem sprawdź ponownie.';
  }

  @override
  String get deskKitReachUnknownTitle => 'Osiągalność nieznana';

  @override
  String get deskKitReachUnknownText =>
      'Usługa sprawdzania portu nie odpowiedziała. Spróbuj później.';

  @override
  String deskKitReachUnknownTextLan(String address) {
    return 'Usługa sprawdzania portu nie odpowiedziała. Spróbuj później. W twojej sieci: $address.';
  }

  @override
  String get deskKitReachOpenTitle => 'Osiągalny z internetu';

  @override
  String deskKitReachOpenText(String port) {
    return 'Port $port jest przekierowany.';
  }

  @override
  String deskKitReachOpenTextLan(String port, String address) {
    return 'Port $port jest przekierowany. W twojej sieci: $address.';
  }

  @override
  String deskKitAgeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count s temu',
      many: '$count s temu',
      few: '$count s temu',
      one: '$count s temu',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min temu',
      many: '$count min temu',
      few: '$count min temu',
      one: '$count min temu',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h temu',
      many: '$count h temu',
      few: '$count h temu',
      one: '$count h temu',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d temu',
      many: '$count d temu',
      few: '$count d temu',
      one: '$count d temu',
    );
    return '$_temp0';
  }

  @override
  String get deskKitNodeBefore410 => 'węzeł starszy niż 4.1.0';

  @override
  String get deskKitNodeNoAnswer => 'brak odpowiedzi';

  @override
  String get deskKitNodesDisagree => 'Węzły nie zgadzają się co do szczytu';

  @override
  String deskKitNodesAgree(String height) {
    return 'Węzły zgodne co do $height';
  }

  @override
  String deskKitNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up z $total węzłów działa',
      many: '$up z $total węzłów działa',
      few: '$up z $total węzłów działają',
      one: '$up z $total węzłów działa',
    );
    return '$_temp0';
  }

  @override
  String deskKitEpicboxUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up z $total serwerów Epicbox działa',
      many: '$up z $total serwerów Epicbox działa',
      few: '$up z $total serwerów Epicbox działają',
      one: '$up z $total serwerów Epicbox działa',
    );
    return '$_temp0';
  }

  @override
  String deskKitLastBlock(String age) {
    return 'ostatni blok $age';
  }

  @override
  String get deskKitLimitedNetwork =>
      'status.btlabs.uk jest nieosiągalny. Te dane pochodzą od samego węzła: brak szczytu do porównania, brak dostępności, brak liczby peerów.';

  @override
  String get deskKitFactHeight => 'Wysokość';

  @override
  String get deskKitFactVersion => 'Wersja';

  @override
  String get deskKitFactAccepts => 'Przyjmuje transakcje';

  @override
  String get deskKitFactYes => 'Tak';

  @override
  String get deskKitFactNotYet => 'Jeszcze nie';

  @override
  String get deskKitFactUnknown => 'Nieznane';

  @override
  String get deskKitFactLatency => 'Opóźnienie';

  @override
  String get deskKitFactUptime => 'Dostępność';

  @override
  String get deskKitFactPeers => 'Peery';

  @override
  String get deskKitFactOperator => 'Operator';

  @override
  String get deskKitAtTip => 'na bieżąco';

  @override
  String deskKitBehind(int count, String blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$blocks w tyle',
      many: '$blocks w tyle',
      few: '$blocks w tyle',
      one: '$blocks w tyle',
    );
    return '$_temp0';
  }

  @override
  String deskKitVersionOut(String version) {
    return 'dostępna $version';
  }

  @override
  String get deskKitVersionLatest => 'najnowsza';

  @override
  String get deskKitUptimeWindow => 'ostatnie 24 h';

  @override
  String deskKitAtTime(String time) {
    return 'o $time';
  }

  @override
  String get deskKitListedOfficial => 'na liście oficjalnych';

  @override
  String deskKitSourceChecked(String time) {
    return 'status.btlabs.uk, sprawdzono $time';
  }

  @override
  String deskKitLatencyMeasured(String where) {
    return 'opóźnienie mierzone $where';
  }

  @override
  String deskKitSiteLastReached(String time) {
    return 'Strona stanu ostatnio osiągalna o $time';
  }

  @override
  String deskKitSince(String time) {
    return 'od $time';
  }

  @override
  String deskKitNodeSemantics(String status, String host) {
    return 'Węzeł $status: $host';
  }

  @override
  String get deskKitNodeDownTitle => 'Węzeł nie odpowiada.';

  @override
  String deskKitNodeDownText(String host) {
    return 'Przełączyć na $host, najsprawniejszy z pozostałych węzłów?';
  }

  @override
  String get deskKitSwitch => 'Przełącz';

  @override
  String get deskKitLimitedInfo => 'Niepełne dane';

  @override
  String get deskKitFromStatusSite => 'ze status.btlabs.uk';

  @override
  String get deskKitOverTor => 'przez Tor';

  @override
  String get deskKitFromThisComputer => 'z tego komputera';

  @override
  String deskKitNodeUse(String host) {
    return 'Użyj $host';
  }

  @override
  String deskKitNodeUseOperator(String host, String operator) {
    return 'Użyj $host, $operator';
  }

  @override
  String deskKitNodeUseDown(String host) {
    return 'Użyj $host, nie odpowiada';
  }

  @override
  String deskKitNodeUseOperatorDown(String host, String operator) {
    return 'Użyj $host, $operator, nie odpowiada';
  }

  @override
  String deskKitLocalNodeUse(String state) {
    return 'Użyj węzła lokalnego, $state';
  }

  @override
  String get deskKitLocalNode => 'Węzeł lokalny';

  @override
  String get deskKitMethodWaitingTor => 'Czeka na Tor';

  @override
  String deskKitMethodTorNotConnected(String host) {
    return '$host. Tor nie jest połączony.';
  }

  @override
  String get deskKitMethodOn => 'Włączony';

  @override
  String deskKitMethodOverTor(String host) {
    return '$host, przez Tor';
  }

  @override
  String get deskKitMethodOff => 'Wyłączony';

  @override
  String get deskKitMethodEpicboxOffDetail =>
      'Płatności na ten adres czekają na serwerze Epicbox.';

  @override
  String get deskKitMethodConnecting => 'Łączenie';

  @override
  String get deskKitMethodSlow => 'Wolno';

  @override
  String get deskKitMethodNotAnswering => 'Nie odpowiada';

  @override
  String deskKitMethodEpicboxDown(String host) {
    return '$host. Płatności czekają na serwerze Epicbox.';
  }

  @override
  String get deskKitMethodHttpOffDetail =>
      'Prosto z innego portfela, gdy ten jest otwarty.';

  @override
  String get deskKitMethodStarting => 'Uruchamianie…';

  @override
  String deskKitMethodHttpInternet(String port) {
    return 'z internetu, port $port';
  }

  @override
  String get deskKitMethodHttpLocal => 'tylko ten komputer (127.0.0.1)';

  @override
  String get deskKitMethodNotReceiving => 'Nie odbiera';

  @override
  String deskKitMethodPortInUse(String port) {
    return 'Port $port zajmuje inny program. Zamknij go albo wybierz inny port w Ustawieniach.';
  }

  @override
  String get deskKitMethodNotInBuild => 'Brak w tej wersji';

  @override
  String get deskKitMethodTorOffDetail =>
      'Wolniej i bardziej prywatnie. W niektórych krajach blokowany lub niedozwolony.';

  @override
  String get deskKitMethodTorPublishing => 'Publikowanie adresu Tor…';

  @override
  String get deskKitMethodTorConnecting => 'Łączenie z Tor…';

  @override
  String get deskKitMethodTorOnDetail => 'osiągalny pod adresem Tor';

  @override
  String get deskKitMethodTorNotPublished => 'Nieopublikowany';

  @override
  String deskKitMethodTorSendsWork(String reason) {
    return '$reason. Wysyłanie działa.';
  }

  @override
  String get deskKitMethodTorNotReachableYet =>
      'Adres Tor nie jest jeszcze osiągalny';

  @override
  String get deskKitMethodTorStopped => 'Zatrzymany';

  @override
  String get deskKitMethodTorStoppedDetail => 'Tor się zatrzymał.';

  @override
  String get deskKitMethodFiles => 'Bezpośrednio · Przesyłanie pliku';

  @override
  String get deskKitChipOverTor => 'Przez Tor';

  @override
  String get deskKitChipStarting => 'Tor startuje';

  @override
  String get deskKitChipNotConnected => 'Tor niepołączony';

  @override
  String get deskKitChipNotOverTor => 'Nie przez Tor';

  @override
  String get deskKitPasswordNote =>
      'Szacowane na tym urządzeniu na podstawie długości oraz popularnych słów, imion i wzorców, dla atakującego z szybkim sprzętem, który próbuje 100 000 haseł na sekundę na pliku tego portfela. To wskazówka, nie gwarancja.';

  @override
  String get deskKitPasswordNoteLabel => 'Jak szacowany jest czas';

  @override
  String get deskKitNotCopied => 'Nie skopiowano';

  @override
  String get deskKitCopied => 'Skopiowano';

  @override
  String deskKitQrOf(String title) {
    return 'Kod QR: $title';
  }

  @override
  String deskKitQrOfTag(String title, String tag) {
    return 'Kod QR: $title, $tag';
  }

  @override
  String deskKitQrShowOf(String title) {
    return 'Pokaż kod QR: $title';
  }

  @override
  String get deskKitQrShow => 'Pokaż QR';

  @override
  String get deskKitQrHide => 'Ukryj QR';

  @override
  String get deskKitQrHideCode => 'Ukryj kod QR';

  @override
  String get deskSetAcctNotForgotten => 'Nie zapomniano';

  @override
  String get deskSetAcctForgotten => 'Zapomniano na tym komputerze';

  @override
  String get deskSetAcctForgottenText =>
      'Przy następnym uruchomieniu portfel zapyta o hasło.';

  @override
  String get deskSetAcctLabelNotSaved => 'Nie zapisano etykiety';

  @override
  String get deskSetAcctEnterLabel => 'Wpisz etykietę';

  @override
  String get deskSetAcctLabelSaved => 'Zapisano etykietę';

  @override
  String get deskSetAcctLabel => 'Etykieta';

  @override
  String get deskSetAcctLabelHint => 'Widoczna tylko w tej aplikacji.';

  @override
  String get deskSetAcctSaveLabel => 'Zapisz etykietę';

  @override
  String get deskSetAcctPhraseHint =>
      'Słowa, które przywracają ten portfel. Nikomu ich nie pokazuj.';

  @override
  String get deskSetAcctShowPhrase => 'Pokaż frazę…';

  @override
  String get deskSetAcctRescanHint =>
      'Ponownie czyta łańcuch, gdy saldo wygląda na błędne.';

  @override
  String get deskSetAcctRecheck => 'Sprawdź…';

  @override
  String get deskSetAcctFiles => 'Pliki';

  @override
  String get deskSetAcctWalletFolder => 'Folder portfela';

  @override
  String get deskSetAcctAppFiles => 'Pliki aplikacji';

  @override
  String get deskSetAcctAppFilesHint => 'Ustawienia i log.';

  @override
  String get deskSetAcctNetwork => 'Sieć';

  @override
  String get deskSetAcctNetworkHint => 'Ustalona przy tworzeniu portfela.';

  @override
  String get deskSetAcctSetup => 'Asystent konfiguracji';

  @override
  String get deskSetAcctSetupHint =>
      'Przejdź jeszcze raz przez ustawienia węzła i odbierania. Nic nie przepadnie.';

  @override
  String get deskSetAcctRunSetup => 'Uruchom asystenta…';

  @override
  String get deskSetAcctSecurity => 'Bezpieczeństwo';

  @override
  String get deskSetAcctRemembered => 'Zapamiętany na tym komputerze';

  @override
  String deskSetAcctRememberedHint(String who) {
    return 'Otwiera się przy starcie bez hasła przez 30 dni od ustawienia. Wysyłki nadal proszą o hasło. $who';
  }

  @override
  String get deskSetAcctForget => 'Zapomnij ten komputer';

  @override
  String get deskSetAcctPasswordHint => 'Odblokowuje ten portfel.';

  @override
  String get deskSetAcctChangePassword => 'Zmień hasło…';

  @override
  String get deskSetAcctDeleteHint => 'Usuwa jego klucze i bazę danych.';

  @override
  String get deskSetAcctFolderNotFound => 'Nie znaleziono folderu';

  @override
  String deskSetAcctCopyPath(String title) {
    return 'Kopiuj ścieżkę: $title';
  }

  @override
  String deskSetBackupWhenToday(String time) {
    return 'dzisiaj, $time';
  }

  @override
  String deskSetBackupWhenYesterday(String time) {
    return 'wczoraj, $time';
  }

  @override
  String deskSetBackupWhenDate(String day, String time) {
    return '$day, $time';
  }

  @override
  String get deskSetBackupNeverExported => 'Nigdy nie eksportowano.';

  @override
  String deskSetBackupLastExportNothingNew(String when) {
    return 'Ostatni eksport $when · od tego czasu nic nowego.';
  }

  @override
  String deskSetBackupLastExportSince(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności',
      many: '$count płatności',
      few: '$count płatności',
      one: '$count płatność',
    );
    return 'Ostatni eksport $when · od tego czasu $_temp0.';
  }

  @override
  String deskSetBackupWriteFailedHere(String reason) {
    return 'Nie udało się zapisać w folderze: $reason. Wybierz inny folder.';
  }

  @override
  String deskSetBackupWriteFailedIn(String folder, String reason) {
    return 'Nie udało się zapisać w $folder: $reason. Wybierz inny folder.';
  }

  @override
  String get deskSetBackupWriteFailed =>
      'Nie udało się zapisać pliku. Wybierz inny folder.';

  @override
  String get deskSetBackupGroup => 'Kopia zapasowa';

  @override
  String get deskSetBackupExportTitle => 'Eksportuj kopię historii';

  @override
  String get deskSetBackupExportHint =>
      'Płatności ze szczegółami i kontakty, w pliku, który otworzy tylko portfel z tą frazą odzyskiwania. Sama fraza przywraca saldo, ale nie zapisy.';

  @override
  String get deskSetBackupExporting => 'Eksportowanie…';

  @override
  String get deskSetBackupExportButton => 'Eksportuj…';

  @override
  String get deskSetBackupImportTitle => 'Importuj kopię historii';

  @override
  String get deskSetBackupImportHint =>
      'Scala kopię tego portfela z Aktywnością. Nic nie jest usuwane; ten sam plik drugi raz niczego nie zmienia.';

  @override
  String get deskSetBackupImportButton => 'Importuj…';

  @override
  String get deskSetBackupCsvTitle => 'Płatności jako CSV';

  @override
  String get deskSetBackupCsvHint =>
      'Zwykła tabela do arkuszy kalkulacyjnych. Bez szyfrowania, nie do importu.';

  @override
  String get deskSetBackupCsvButton => 'Eksportuj CSV…';

  @override
  String get deskSetBackupSaveDialogTitle => 'Zapisz historię płatności';

  @override
  String get deskSetBackupNotSaved => 'Nie zapisano';

  @override
  String get deskSetBackupInFile => 'W pliku';

  @override
  String deskSetBackupInFileCounts(int payments, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments płatności',
      many: '$payments płatności',
      few: '$payments płatności',
      one: '$payments płatność',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts kontaktu',
      many: '$contacts kontaktów',
      few: '$contacts kontakty',
      one: '$contacts kontakt',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get deskSetBackupInFileSub =>
      'Kto komu zapłacił, opłaty, notatki, ID slate';

  @override
  String get deskSetBackupNotIn => 'Poza plikiem';

  @override
  String get deskSetBackupNotInValue => 'Klucze, fraza odzyskiwania, hasło';

  @override
  String get deskSetBackupOpensWith => 'Otwiera go';

  @override
  String get deskSetBackupOpensWithValue =>
      'Ten portfel lub portfel przywrócony z jego frazy';

  @override
  String get deskSetBackupFile => 'Plik';

  @override
  String get deskSetBackupFileNote =>
      'Plik zawiera płatności do tej chwili. Po nowych płatnościach wyeksportuj go ponownie.';

  @override
  String get deskSetBackupExportDesc =>
      'Plik z płatnościami tego portfela, ich szczegółami i kontaktami. Otworzy go tylko portfel z tą samą frazą odzyskiwania.';

  @override
  String get deskSetBackupSaved => 'Zapisano';

  @override
  String get deskSetBackupKeepCopy =>
      'Zachowaj też kopię poza tym komputerem: na pendrivie, innym dysku lub w chmurze. Po nowych płatnościach wyeksportuj ponownie.';

  @override
  String get deskSetBackupOpenFolder => 'Otwórz folder';

  @override
  String get deskSetBackupSaving => 'Zapisywanie…';

  @override
  String get deskSetBackupTryAgain => 'Spróbuj ponownie';

  @override
  String get deskSetBackupSaveAs => 'Zapisz jako…';

  @override
  String get deskSetBackupOpenDialogTitle => 'Otwórz kopię historii';

  @override
  String get deskSetBackupDetailsRestored => 'Przywrócone szczegóły';

  @override
  String get deskSetBackupDetailsRestoredSub =>
      'Płatności, które już tu są, odzyskały drugą stronę, opłatę lub notatkę';

  @override
  String get deskSetBackupOlderAdded => 'Dodane starsze płatności';

  @override
  String get deskSetBackupOlderAddedSub =>
      'Nie było ich już na liście; widoczne jako Z kopii';

  @override
  String get deskSetBackupContactsAdded => 'Dodane kontakty';

  @override
  String get deskSetBackupAlreadyHere => 'Już były';

  @override
  String get deskSetBackupUnchanged => 'Bez zmian';

  @override
  String get deskSetBackupNothingNew => 'Nic nowego';

  @override
  String deskSetBackupNothingNewBody(String file) {
    return 'Każdy wpis z $file już tu był.';
  }

  @override
  String get deskSetBackupImported => 'Zaimportowano';

  @override
  String deskSetBackupReading(String file) {
    return 'Odczytywanie $file…';
  }

  @override
  String get deskSetBackupNotImported => 'Nie zaimportowano';

  @override
  String get deskSetBackupBringsBack => 'Przywraca';

  @override
  String get deskSetBackupBringsBackValue =>
      'Kto komu zapłacił, opłaty i notatki płatności, które już tu są; starsze płatności, których lista nie ma; kontakty';

  @override
  String get deskSetBackupNeeds => 'Wymaga';

  @override
  String deskSetBackupNeedsValue(String network) {
    return 'Pliku z tego portfela (ta sama fraza odzyskiwania), z sieci $network';
  }

  @override
  String get deskSetBackupNever => 'Nigdy';

  @override
  String get deskSetBackupNeverValue =>
      'Nie usuwa ani nie zmienia płatności, która tu jest';

  @override
  String get deskSetBackupChooseFile => 'Wybierz plik…';

  @override
  String get deskSetBackupImportDesc =>
      'Scala kopię historii tego portfela z Aktywnością. Nic nie jest usuwane, a ten sam plik drugi raz niczego nie zmienia.';

  @override
  String get deskSetBackupSaveCsvDialogTitle => 'Zapisz płatności jako CSV';

  @override
  String get deskSetBackupCsvDialogTitle => 'Eksportuj CSV';

  @override
  String get deskSetBackupCsvDialogDesc =>
      'Zwykła tabela płatności tego portfela do arkuszy kalkulacyjnych.';

  @override
  String deskSetBackupCsvSavedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności',
      many: '$count płatności',
      few: '$count płatności',
      one: '$count płatność',
    );
    return '$_temp0, od najnowszych. Kwoty w EPIC z 8 miejscami po przecinku; daty w UTC.';
  }

  @override
  String get deskSetBackupDateError => 'Wpisz datę w formacie 2026-01-31';

  @override
  String get deskSetBackupDateHint => 'RRRR-MM-DD';

  @override
  String get deskSetBackupRange => 'Zakres';

  @override
  String get deskSetBackupRangeAll => 'Wszystkie';

  @override
  String get deskSetBackupRangeThisYear => 'Ten rok';

  @override
  String get deskSetBackupRangeLastYear => 'Zeszły rok';

  @override
  String get deskSetBackupRangeCustom => 'Własny';

  @override
  String get deskSetBackupFrom => 'Od';

  @override
  String get deskSetBackupTo => 'Do';

  @override
  String deskSetBackupCsvInfo(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności',
      many: '$count płatności',
      few: '$count płatności',
      one: '$count płatność',
    );
    return '$_temp0 · kolumny: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. Plik $file.';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '– · kolumny: date, type, status, amount, fee, counterparty, note, slate id, kernel, block height. Plik $file.';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Bez szyfrowania.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Każdy, kto ma plik, odczyta kwoty, daty, adresy i notatki. Nie da się go zaimportować; do tego służy kopia historii.';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności nie ma kopii historii.',
      many: '$count płatności nie ma kopii historii.',
      few: '$count płatności nie mają kopii historii.',
      one: '$count płatność nie ma kopii historii.',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności jest nowych lub zmienionych od ostatniej kopii historii.',
      many:
          '$count płatności jest nowych lub zmienionych od ostatniej kopii historii.',
      few:
          '$count płatności są nowe lub zmienione od ostatniej kopii historii.',
      one:
          '$count płatność jest nowa lub zmieniona od ostatniej kopii historii.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'Przywrócenie z frazy odzyskiwania odtwarza saldo, ale nie to, kto komu zapłacił.';

  @override
  String get deskSetBackupNotNow => 'Nie teraz';

  @override
  String get deskSetDlgChainTitle => 'Znaleziono istniejące dane blockchaina';

  @override
  String get deskSetDlgChainDesc =>
      'Ten komputer ma już dane blockchaina Epic, których może użyć węzeł lokalny.';

  @override
  String get deskSetDlgChainFolder => 'Folder';

  @override
  String get deskSetDlgChainSize => 'Rozmiar';

  @override
  String get deskSetDlgChainUpdated => 'Ostatnia zmiana';

  @override
  String get deskSetDlgChainUpdatedValue => '3 dni temu';

  @override
  String get deskSetDlgChainOthers =>
      'Znaleziono też inne kopie (1). Ta była aktualizowana najpóźniej.';

  @override
  String get deskSetDlgChainInUse =>
      'Inny program Epic używa tego folderu. Zamknij go, a potem ponownie wybierz węzeł lokalny, aby użyć tych danych.';

  @override
  String get deskSetDlgChainUseIt =>
      'Użyć ich? Oszczędza to pobierania i synchronizacji całego blockchaina.';

  @override
  String get deskSetDlgChainOlderWallet =>
      'Starszy Epic Wallet, który używa tego folderu, może potem wymagać ponownej synchronizacji. Nie dotyczy to monet.';

  @override
  String get deskSetDlgChainFresh => 'Pobierz od nowa';

  @override
  String get deskSetDlgChainUse => 'Użyj tych danych';

  @override
  String get deskSetDlgPwChanged => 'Zmieniono hasło.';

  @override
  String get deskSetDlgPwTitle => 'Zmień hasło';

  @override
  String get deskSetDlgPwDesc =>
      'Od teraz ten portfel odblokowuje nowe hasło. Zapamiętane hasło zostanie zapomniane.';

  @override
  String get deskSetDlgPwCurrent => 'Obecne hasło';

  @override
  String get deskSetDlgPwWrong => 'Nieprawidłowe hasło';

  @override
  String get deskSetDlgPwNew => 'Nowe hasło';

  @override
  String get deskSetDlgPwRepeat => 'Powtórz nowe hasło';

  @override
  String deskSetDlgRemoveToastList(String name) {
    return 'Usunięto z listy: $name';
  }

  @override
  String deskSetDlgRemoveToastDeleted(String name) {
    return 'Usunięto: $name';
  }

  @override
  String get deskSetDlgRemoveFilesKept => 'Pliki zachowane.';

  @override
  String deskSetDlgRemoveTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String get deskSetDlgRemoveDesc => 'Nic się nie zmieni bez potwierdzenia.';

  @override
  String get deskSetDlgRemoveWhat => 'Co usunąć';

  @override
  String get deskSetDlgRemoveFromList => 'Usuń z listy';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Pliki zostają w $folder. Wszystkie portfele mogą go przywrócić na listę.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Usuń portfel';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Usuwa jego klucze i bazę danych z $folder. Przywróci go tylko fraza odzyskiwania; bez niej monety przepadną.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'Aby usunąć także jego pliki, odblokuj ten portfel i użyj Usuń portfel w Ustawienia › Ten portfel.';

  @override
  String get deskSetDlgRemoveUnlock => 'Odblokuj ten portfel';

  @override
  String get deskSetDlgRemoveIrreversible => 'Tego nie można cofnąć';

  @override
  String get deskSetDlgRemoveIrreversibleBody =>
      'Portfel przywróci tylko fraza odzyskiwania; bez niej monety przepadną na zawsze.';

  @override
  String get deskSetDlgRemoveName => 'Nazwa portfela';

  @override
  String deskSetDlgRemoveTypeName(String name) {
    return 'Wpisz $name, aby potwierdzić.';
  }

  @override
  String get deskSetDlgRemoveNameMismatch => 'Nazwa się nie zgadza';

  @override
  String get deskSetDlgPassword => 'Hasło';

  @override
  String get deskSetDlgPhraseWritten => 'Fraza odzyskiwania jest zapisana';

  @override
  String get deskSetDlgRemoving => 'Usuwanie…';

  @override
  String get deskSetDlgWalletLocked => 'Portfel jest zablokowany';

  @override
  String get deskSetDlgDeleteTitle => 'Usunąć ten portfel?';

  @override
  String get deskSetDlgDeleteDesc =>
      'Usuwa portfel i jego seed z tego komputera. Przywróci go tylko fraza odzyskiwania; bez niej monety przepadną.';

  @override
  String get deskSetFrameTitle => 'Ustawienia';

  @override
  String get deskSetFrameSections => 'Sekcje ustawień';

  @override
  String get deskSetFrameNode => 'Węzeł';

  @override
  String get deskSetFramePrivacy => 'Prywatność';

  @override
  String get deskSetFrameAppearance => 'Wygląd';

  @override
  String get deskSetFrameThisWallet => 'Ten portfel';

  @override
  String get deskSetFrameAllWallets => 'Wszystkie portfele';

  @override
  String get deskSetFramePhrase => 'Fraza odzyskiwania';

  @override
  String get deskSetFrameRescan => 'Sprawdź saldo';

  @override
  String get deskSetFrameAbout => 'O aplikacji';

  @override
  String get deskSetFrameHelp => 'Pomoc';

  @override
  String get deskSetFrameHealthOn => 'Działa';

  @override
  String get deskSetFrameHealthSlow => 'Wolno';

  @override
  String get deskSetFrameNotResponding => 'Nie odpowiada';

  @override
  String get deskSetFrameOff => 'Wyłączony';

  @override
  String get deskSetFrameChecking => 'Sprawdzanie…';

  @override
  String get deskSetFrameNodeSynced => 'Zsynchronizowany';

  @override
  String get deskSetFrameNodeSyncing => 'Synchronizacja';

  @override
  String get deskSetFrameConnecting => 'Łączenie…';

  @override
  String get deskSetFrameListening => 'Nasłuchuje';

  @override
  String deskSetFrameHealthLatency(String word, int ms) {
    return '$word · $ms ms';
  }

  @override
  String get deskSetFrameNever => 'nigdy';

  @override
  String get deskSetFrameJustNow => 'przed chwilą';

  @override
  String deskSetFrameMinAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min temu',
      many: '$count min temu',
      few: '$count min temu',
      one: '$count min temu',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h temu',
      many: '$count h temu',
      few: '$count h temu',
      one: '$count h temu',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d temu',
      many: '$count d temu',
      few: '$count d temu',
      one: '$count d temu',
    );
    return '$_temp0';
  }

  @override
  String get deskSetComboOpens => 'Otwiera listę';

  @override
  String get deskSetComboNoAnswer => 'Jeszcze bez odpowiedzi';

  @override
  String deskSetComboUse(String host) {
    return 'Użyj $host';
  }

  @override
  String get deskSetLnodeDidNotStart => 'Węzeł się nie uruchomił';

  @override
  String get deskSetLnodeDidNotStop => 'Węzeł się nie zatrzymał';

  @override
  String get deskSetLnodeDidNotRestart => 'Węzeł nie uruchomił się ponownie';

  @override
  String get deskSetLnodeMoved => 'Przeniesiono dane łańcucha';

  @override
  String get deskSetLnodeFolderChanged => 'Zmieniono folder danych';

  @override
  String get deskSetLnodeFolderFailed => 'Folder się nie zmienił';

  @override
  String get deskSetLnodeStart => 'Uruchom';

  @override
  String get deskSetLnodeStop => 'Zatrzymaj';

  @override
  String get deskSetLnodeRestart => 'Uruchom ponownie';

  @override
  String get deskSetLnodeTabStatus => 'Stan';

  @override
  String get deskSetLnodeTabPeers => 'Peery';

  @override
  String get deskSetLnodeWhileSyncing => 'Podczas synchronizacji';

  @override
  String deskSetLnodeWhileSyncingText(String host) {
    return 'Używaj $host, dopóki węzeł lokalny się nie zsynchronizuje. Węzeł lokalny przejmie pracę sam.';
  }

  @override
  String get deskSetLnodeChange => 'Zmień…';

  @override
  String deskSetLnodeUseWhileSyncing(String host) {
    return 'Używaj $host podczas synchronizacji';
  }

  @override
  String get deskSetLnodeDataFolder => 'Folder danych';

  @override
  String deskSetLnodeUsed(String size) {
    return 'Zajęte: $size';
  }

  @override
  String get deskSetLnodeFreeUnknown => 'wolne miejsce nieznane';

  @override
  String deskSetLnodeFree(String size) {
    return 'Wolne: $size';
  }

  @override
  String get deskSetLnodeOpen => 'Otwórz';

  @override
  String get deskSetLnodeFolderNotOpened => 'Nie otwarto folderu';

  @override
  String get deskSetLnodeChainData => 'Dane łańcucha';

  @override
  String get deskSetLnodeChainPointed =>
      'Ten węzeł czyta folder innego programu; usuń dane tam.';

  @override
  String get deskSetLnodeChainText =>
      'Użyj danych łańcucha, które zostawił na tym komputerze inny węzeł Epic, albo usuń dane tego węzła i pobierz łańcuch od nowa.';

  @override
  String get deskSetLnodeReuse => 'Użyj istniejących…';

  @override
  String get deskSetLnodeDelete => 'Usuń…';

  @override
  String get deskSetLnodeAutostart => 'Uruchamiaj z aplikacją';

  @override
  String get deskSetLnodeAutostartHint =>
      'Uruchamia węzeł przy starcie i synchronizuje go, dopóki aplikacja jest otwarta.';

  @override
  String get deskSetLnodeViewLog => 'Pokaż log węzła';

  @override
  String get deskSetLnodeChangeFolder => 'Zmień folder…';

  @override
  String deskSetLnodeUseMeanwhile(String host) {
    return 'W międzyczasie używaj $host';
  }

  @override
  String get deskSetLnodeWaitingPeers => 'czeka na peery';

  @override
  String get deskSetLnodeSyncingLower => 'synchronizacja';

  @override
  String deskSetLnodeStageUsing(String stage, String host) {
    return '$stage · w międzyczasie używany $host';
  }

  @override
  String get deskSetLnodeNothingUntilSynced =>
      'Do czasu synchronizacji węzła lokalnego nie można niczego wysłać ani odebrać.';

  @override
  String get deskSetLnodeAtTip => 'na bieżąco';

  @override
  String get deskSetLnodeStalledDetail =>
      'brak postępu od 5 min; raz już uruchomiono ponownie';

  @override
  String get deskSetLnodeNoProgress => 'Węzeł nie robi postępów.';

  @override
  String get deskSetLnodeNoProgressText =>
      'Ponowne uruchomienie zwykle pomaga; jeśli nie, przyczynę podaje log.';

  @override
  String get deskSetLnodePortInUse => 'Port 3413 zajmuje inny program.';

  @override
  String get deskSetLnodePortInUseText =>
      'Zamknij go (inny węzeł Epic?) albo wybierz węzeł, który już tam działa, w Serwer węzła.';

  @override
  String get deskSetLnodeDiskLow => 'Na tym woluminie zostało mniej niż 2 GB.';

  @override
  String get deskSetLnodeDiskLowText =>
      'Zwolnij miejsce albo zmień folder danych.';

  @override
  String get deskSetLnodeMissing => 'W tej instalacji brakuje programu węzła.';

  @override
  String get deskSetLnodeMissingText => 'Zainstaluj portfel ponownie.';

  @override
  String get deskSetLnodeStopped => 'Węzeł zatrzymał się sam.';

  @override
  String get deskSetLnodeStoppedText =>
      'Ostatnie wiersze logu mogą wyjaśnić dlaczego.';

  @override
  String deskSetLnodeUsesMeanwhile(String host) {
    return 'w międzyczasie portfel używa $host';
  }

  @override
  String get deskSetLnodeNothingUntilRuns =>
      'nic nie można wysłać, dopóki nie działa';

  @override
  String get deskSetLnodeTilePeers => 'Peery';

  @override
  String get deskSetLnodeTileSync => 'Synchronizacja';

  @override
  String get deskSetLnodeTileDownload => 'Pobieranie';

  @override
  String deskSetLnodeSoFar(String size) {
    return '$size do tej pory';
  }

  @override
  String get deskSetLnodeTileDisk => 'Dane łańcucha na dysku';

  @override
  String deskSetLnodeThisSession(String size) {
    return '+$size w tej sesji';
  }

  @override
  String deskSetLnodeVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String deskSetLnodeRunning(String duration) {
    return 'działa $duration';
  }

  @override
  String deskSetLnodeStoppedAt(String time) {
    return 'zatrzymany $time';
  }

  @override
  String deskSetLnodePeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peera',
      many: '$count peerów',
      few: '$count peery',
      one: '$count peer',
    );
    return '$_temp0';
  }

  @override
  String deskSetLnodeMoving(String done, String total) {
    return 'Przenoszenie danych łańcucha · $done z $total';
  }

  @override
  String get deskSetLnodeConnectingPeers => 'Łączenie z peerami';

  @override
  String deskSetLnodeStartedSecAgo(int seconds) {
    return 'uruchomiony $seconds s temu';
  }

  @override
  String deskSetLnodeStartedAgo(String duration) {
    return 'uruchomiony $duration temu';
  }

  @override
  String get deskSetLnodeSettingsChanged => 'Zmieniono ustawienia.';

  @override
  String get deskSetLnodeSettingsChangedText =>
      'Zadziałają po następnym uruchomieniu.';

  @override
  String get deskSetLnodeRestartNow => 'Uruchom ponownie teraz';

  @override
  String get deskSetLnodeSampled =>
      'Odczyt co 30 s, gdy ta strona jest otwarta.';

  @override
  String get deskSetLnodeTomlEdited =>
      'Plik epic-server.toml zmieniono ręcznie; ustawienia peerów i folderu z tego miejsca nie działają.';

  @override
  String get deskSetLnodeSyncProgress => 'Postęp synchronizacji';

  @override
  String get deskSetLnodeStepHeaders => 'Nagłówki';

  @override
  String get deskSetLnodeStepChainState => 'Stan łańcucha';

  @override
  String get deskSetLnodeStepBlocks => 'Bloki';

  @override
  String get deskSetLnodeStepsNone =>
      'Kroki synchronizacji: żaden nie rozpoczęty';

  @override
  String deskSetLnodeStepOf(int n, String name) {
    return 'Krok synchronizacji $n z 4: $name';
  }

  @override
  String deskSetLndAskTitle(String host) {
    return 'Używać $host, dopóki węzeł lokalny się nie zsynchronizuje?';
  }

  @override
  String deskSetLndAskDesc(String host) {
    return 'Synchronizacja trwa godzinami. W tym czasie portfel może czytać łańcuch i wysyłać przez $host, węzeł publiczny. Węzeł lokalny przejmie pracę sam po synchronizacji.';
  }

  @override
  String get deskSetLndAskNote =>
      'Pytanie pada raz. Węzeł i wybór można zmienić w Ustawienia › Węzeł › Podczas synchronizacji.';

  @override
  String get deskSetLndAskWait => 'Czekaj na węzeł lokalny';

  @override
  String deskSetLndAskUse(String host) {
    return 'Używaj $host';
  }

  @override
  String get deskSetLndPickTitle => 'Węzeł podczas synchronizacji';

  @override
  String get deskSetLndPickDesc =>
      'Węzeł publiczny, którego portfel używa, dopóki węzeł lokalny się nie zsynchronizuje.';

  @override
  String get deskSetLndDeleted => 'Usunięto dane łańcucha';

  @override
  String deskSetLndFreed(String size) {
    return 'Zwolniono $size';
  }

  @override
  String get deskSetLndNotDeleted => 'Nie usunięto danych łańcucha';

  @override
  String get deskSetLndDeleteTitle => 'Usuń dane łańcucha';

  @override
  String deskSetLndDeleteDesc(String size, String path) {
    return 'Usuwa $size z $path. Węzeł się zatrzyma, a przy następnym uruchomieniu cały łańcuch pobierze się od nowa (godziny). Klucze i historia portfela pozostają nietknięte.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Usuwa dane łańcucha z $path. Węzeł się zatrzyma, a przy następnym uruchomieniu cały łańcuch pobierze się od nowa (godziny). Klucze i historia portfela pozostają nietknięte.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Wpisz $word, aby potwierdzić.';
  }

  @override
  String deskSetLndTypeToConfirmLabel(String word) {
    return 'Wpisz $word, aby potwierdzić';
  }

  @override
  String get deskSetLndSourceCli => 'epic (węzeł wiersza poleceń)';

  @override
  String get deskSetLndSourceGui => 'Epic GUI';

  @override
  String get deskSetLndSourceBundled => 'wcześniejszy Epic Wallet';

  @override
  String get deskSetLndSourceCustom => 'inny folder';

  @override
  String get deskSetLndInUse => 'Używane dane łańcucha';

  @override
  String get deskSetLndNotInUse => 'Folder nie jest używany';

  @override
  String get deskSetLndReuseTitle =>
      'Znaleziono dane łańcucha na tym komputerze';

  @override
  String get deskSetLndReuseDesc =>
      'Inny węzeł Epic zostawił tu dane łańcucha. Węzeł lokalny może czytać ten folder zamiast pobierać łańcuch.';

  @override
  String get deskSetLndLooking => 'Szukanie…';

  @override
  String get deskSetLndUseIt => 'Użyj ich';

  @override
  String deskSetLndLastWritten(String date) {
    return 'ostatni zapis $date';
  }

  @override
  String get deskSetLndLocked => 'Używany przez inny program';

  @override
  String get deskSetLndNothingCopied =>
      'Nic nie jest kopiowane: węzeł czyta ten folder, a Usuń dane łańcucha jest dla niego wyłączone.';

  @override
  String get deskSetLndFresh => 'Pobierz od nowa';

  @override
  String deskSetLndFreshLine(String size) {
    return 'Do własnego folderu portfela. Około $size.';
  }

  @override
  String get deskSetLndLogTitle => 'Log węzła';

  @override
  String get deskSetLndReading => 'Odczytywanie…';

  @override
  String get deskSetLndLogNote =>
      'Ostatnie 200 wierszy epic-server.log z folderu danych. Najnowsze na dole.';

  @override
  String get deskSetLndCopied => 'Skopiowano';

  @override
  String deskSetLndLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wiersza',
      many: '$count wierszy',
      few: '$count wiersze',
      one: '$count wiersz',
    );
    return '$_temp0';
  }

  @override
  String get deskSetLndBadFolder => 'Ten folder się nie nadaje';

  @override
  String get deskSetLndChooseAnother => 'Wybierz inny';

  @override
  String deskSetLndMoveTitle(String size, String folder) {
    return 'Przenieść $size do $folder?';
  }

  @override
  String get deskSetLndMoveDesc =>
      'Węzeł zatrzyma się na czas przenoszenia danych, a potem uruchomi z nowego folderu. Zacznij tam od nowa zamiast tego pobierze do niego łańcuch od nowa.';

  @override
  String get deskSetLndStartFresh => 'Zacznij tam od nowa';

  @override
  String get deskSetLndMove => 'Przenieś';

  @override
  String get deskSetLndProbNotEmpty => 'Folder nie jest pusty.';

  @override
  String get deskSetLndProbInsideSource => 'Jest wewnątrz obecnego folderu.';

  @override
  String get deskSetLndProbSourceInside => 'Obecny folder jest wewnątrz niego.';

  @override
  String deskSetLndProbSpace(String needed, String free) {
    return 'Za mało miejsca: potrzeba $needed, wolne $free.';
  }

  @override
  String deskSetLndProbSpaceUnknown(String needed) {
    return 'Za mało miejsca: potrzeba $needed, wolne miejsce nieznane.';
  }

  @override
  String get deskSetLndProbLocked => 'Używa go inny program.';

  @override
  String get deskSetLndProbMissing => 'Brak obecnych danych łańcucha.';

  @override
  String get deskSetLndProbNotWritable => 'Nie można w nim zapisywać.';

  @override
  String get deskSetLndProbIncomplete =>
      'Obecne dane łańcucha są niekompletne.';

  @override
  String get deskSetLndProbForeign => 'Są tam dane łańcucha innego programu.';

  @override
  String get deskSetPeersBannedToast => 'Zablokowano peera';

  @override
  String get deskSetPeersUnbannedToast => 'Odblokowano peera';

  @override
  String get deskSetPeersNotAddress =>
      'To nie jest adres IP z portem, np. 203.0.113.5:3414.';

  @override
  String get deskSetPeersAlreadyPreferred => 'Już jest preferowany.';

  @override
  String deskSetPeersMaxRange(int min, int max) {
    return 'Od $min do $max.';
  }

  @override
  String get deskSetPeersReading => 'Odczytywanie peerów…';

  @override
  String deskSetPeersSummary(int connected, int inbound, int outbound) {
    return 'Połączone: $connected · przychodzące: $inbound · wychodzące: $outbound';
  }

  @override
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  ) {
    return 'Połączone: $connected · przychodzące: $inbound · wychodzące: $outbound · zablokowane: $banned';
  }

  @override
  String get deskSetPeersIn => 'przych.';

  @override
  String get deskSetPeersOut => 'wych.';

  @override
  String get deskSetPeersBan => 'Zablokuj';

  @override
  String get deskSetPeersColAddress => 'Adres';

  @override
  String get deskSetPeersColDirection => 'Kierunek';

  @override
  String get deskSetPeersColVersion => 'Wersja';

  @override
  String get deskSetPeersColHeight => 'Wysokość';

  @override
  String get deskSetPeersColFirstSeen => 'Od';

  @override
  String get deskSetPeersNone => 'Brak połączonych peerów.';

  @override
  String deskSetPeersMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jeszcze $count',
      many: 'Jeszcze $count',
      few: 'Jeszcze $count',
      one: 'Jeszcze $count',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPeersRefreshed => 'Odświeżane co 10 s';

  @override
  String get deskSetPeersBanned => 'Zablokowane';

  @override
  String deskSetPeersBannedAt(String time) {
    return 'zablokowany $time';
  }

  @override
  String get deskSetPeersUnban => 'Odblokuj';

  @override
  String get deskSetPeersPreferred => 'Preferowane peery';

  @override
  String get deskSetPeersPreferredLabel => 'Preferowany peer, adres IP i port';

  @override
  String get deskSetPeersAdd => 'Dodaj';

  @override
  String get deskSetPeersMaxIn => 'Maks. przychodzących';

  @override
  String get deskSetPeersMaxInLabel =>
      'Maksymalna liczba peerów przychodzących';

  @override
  String get deskSetPeersMaxOut => 'Maks. wychodzących';

  @override
  String get deskSetPeersMaxOutLabel => 'Maksymalna liczba peerów wychodzących';

  @override
  String deskSetPeersPreferredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preferowane: $count',
      many: 'Preferowane: $count',
      few: 'Preferowane: $count',
      one: 'Preferowane: $count',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersForget(String peer) {
    return 'Zapomnij $peer';
  }

  @override
  String deskSetPeersNote(int min, int max, int def) {
    return 'Kolumna Od pokazuje, kiedy aplikacja w tej sesji pierwszy raz zobaczyła połączonego peera; węzeł nie podaje, kiedy połączenie się zaczęło. Blokowanie i odblokowanie używa API właściciela węzła. Enter zapisuje maksimum (od $min do $max, domyślnie $def).';
  }

  @override
  String get deskSetLndDeleteQuestion => 'Usunąć dane łańcucha?';

  @override
  String get deskSetLogsMemoryOnly => 'Log jest przechowywany tylko w pamięci.';

  @override
  String get deskSetLogsClearTitle => 'Wyczyścić logi?';

  @override
  String get deskSetLogsClearDesc =>
      'Usuwa pliki logów. Raport wysłany później będzie zawierał tylko to, co zostanie zapisane od teraz.';

  @override
  String get deskSetLogsKeep => 'Zachowaj logi';

  @override
  String get deskSetLogsClear => 'Wyczyść logi';

  @override
  String get deskSetLogsCleared => 'Wyczyszczono logi';

  @override
  String deskSetLogsToday(String time) {
    return 'dzisiaj o $time';
  }

  @override
  String deskSetLogsTomorrow(String time) {
    return 'jutro o $time';
  }

  @override
  String get deskSetLogsTitle => 'Logi';

  @override
  String get deskSetLogsLevel => 'Poziom logowania';

  @override
  String get deskSetLogsLevelNormal =>
      'Normalny. Szczegółowy zapisuje na dysku więcej wierszy przez 24 godziny; w pliku mogą się pojawić adresy, raporty je pomijają.';

  @override
  String deskSetLogsLevelDetailed(String until) {
    return 'Szczegółowy do $until, potem Normalny. W pliku mogą się pojawić adresy; raporty je pomijają.';
  }

  @override
  String deskSetLogsLevelDetailedCore(String until) {
    return 'Szczegółowy do $until, potem Normalny. W pliku mogą się pojawić adresy; raporty je pomijają. Wiersze rdzenia portfela będą szczegółowe od następnego uruchomienia aplikacji.';
  }

  @override
  String get deskSetLogsNormal => 'Normalny';

  @override
  String get deskSetLogsDetailed => 'Szczegółowy';

  @override
  String get deskSetLogsFiles => 'Pliki logów';

  @override
  String deskSetLogsSize(String size, String max) {
    return 'Obecny rozmiar $size z $max. Zachowuje jeden starszy plik.';
  }

  @override
  String get deskSetLogsOpenFolder => 'Otwórz folder logów';

  @override
  String get deskSetNodePortNote => 'Sprawdź adres i port (zwykle 3413).';

  @override
  String get deskSetNodeListNote =>
      'Stan z status.btlabs.uk, sprawdzany co kilka minut. Opóźnienie mierzone z tego komputera.';

  @override
  String get deskSetNodeStartTitle => 'Uruchomić węzeł lokalny?';

  @override
  String get deskSetNodeStartDesc =>
      'Osobny program synchronizuje łańcuch Epic na tym komputerze.';

  @override
  String get deskSetNodeStartLine1 =>
      'Pobiera cały łańcuch: kilka GB miejsca na dysku i transferu.';

  @override
  String get deskSetNodeStartLine2 =>
      'Pierwsza synchronizacja trwa godzinami. Do jej końca węzeł pokazuje Synchronizacja.';

  @override
  String get deskSetNodeStartLine3 =>
      'Zapora może zapytać o zgodę dla programu węzła.';

  @override
  String get deskSetNodeStartButton => 'Uruchom węzeł lokalny';

  @override
  String get deskSetNodeRowNotSetUp => 'Nieskonfigurowany';

  @override
  String get deskSetNodeRowStopped => 'Wyłączony';

  @override
  String get deskSetNodeRowStarting => 'Uruchamianie';

  @override
  String deskSetNodeRowSyncingPct(String percent) {
    return 'Synchronizacja $percent';
  }

  @override
  String get deskSetNodeRowStalled => 'Zatrzymany';

  @override
  String get deskSetNodeRowFailed => 'Błąd';

  @override
  String get deskSetNodeLocalInUse => 'Używany jest węzeł lokalny';

  @override
  String get deskSetNodeLocalInUseText =>
      'Pobiera cały łańcuch. Potrzebuje 5 GB wolnego miejsca.';

  @override
  String get deskSetNodeLocalNode => 'Węzeł lokalny';

  @override
  String get deskSetNodeGroupComputer => 'Ten komputer';

  @override
  String get deskSetNodeServer => 'Serwer węzła';

  @override
  String get deskSetNodeServerHint =>
      'Węzeł, przez który portfel czyta łańcuch i wysyła płatności.';

  @override
  String get deskSetNodeChecking => 'Sprawdzanie węzła…';

  @override
  String get deskSetNodeBackground => 'Synchronizuj w tle';

  @override
  String get deskSetNodeBackgroundHint =>
      'Synchronizuje dalej, gdy aplikacja jest zamknięta.';

  @override
  String get deskSetPhraseNotCopied => 'Nie skopiowano';

  @override
  String get deskSetPhraseClipboardRefused => 'Schowek odrzucił tekst.';

  @override
  String get deskSetPhraseCopied => 'Skopiowano frazę';

  @override
  String get deskSetPhraseCleared => 'Schowek zostanie wyczyszczony za 60 s.';

  @override
  String get deskSetPhraseEnterPassword => 'Wpisz hasło.';

  @override
  String get deskSetPhraseWrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get deskSetPhraseIntro =>
      'Zapisz słowa na papierze w tej kolejności. Nigdy nie wpisuj ich na stronie internetowej ani na czacie.';

  @override
  String get deskSetPhrasePanel => 'Wpisz hasło, aby pokazać słowa';

  @override
  String get deskSetPhraseShowWords => 'Pokaż słowa';

  @override
  String deskSetPhraseWordsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fraza odzyskiwania, $count słowa',
      many: 'Fraza odzyskiwania, $count słów',
      few: 'Fraza odzyskiwania, $count słowa',
      one: 'Fraza odzyskiwania, $count słowo',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPhraseHideQr => 'Ukryj kod QR';

  @override
  String get deskSetPhraseShowQr => 'Pokaż kod QR';

  @override
  String get deskSetPhraseHideWords => 'Ukryj słowa';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return 'Ukryje się za $seconds s';
  }

  @override
  String get deskSetPhraseQrLabel => 'Kod QR frazy odzyskiwania';

  @override
  String get deskSetPhraseBackUp => 'Zabezpiecz frazę';

  @override
  String get deskSetPhraseBackUpText =>
      'Każdy, kto zna te słowa, może zabrać EPIC. Upewnij się, że nikt nie widzi ekranu.';

  @override
  String get deskSetPrivTorOnFailed => 'Nie włączono Tora';

  @override
  String get deskSetPrivTorOffFailed => 'Nie wyłączono Tora';

  @override
  String get deskSetPrivTor => 'Tor';

  @override
  String get deskSetPrivSwitching => 'Przełączanie Tora';

  @override
  String get deskSetPrivTurnOff => 'Wyłącz Tor';

  @override
  String get deskSetPrivNotInBuild => 'Brak w tej wersji';

  @override
  String get deskSetPrivStarting => 'Uruchamianie…';

  @override
  String deskSetPrivStartingDetail(int progress, String waiting) {
    return '$progress %. $waiting czekają, aż Tor się połączy.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Adres Tor nie jest jeszcze opublikowany. Wysyłanie działa.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Wysyłanie działa.';
  }

  @override
  String get deskSetPrivConnected => 'Połączono.';

  @override
  String get deskSetPrivNotConnected => 'Brak połączenia';

  @override
  String deskSetPrivStoppedDetail(String waiting) {
    return 'Tor się zatrzymał. $waiting czekają na Ponów albo wyłączenie Tora.';
  }

  @override
  String deskSetPrivProblemDetail(String problem, String waiting) {
    return '$problem. $waiting czekają na Ponów albo wyłączenie Tora.';
  }

  @override
  String get deskSetPrivStatusSite => 'Strona stanu';

  @override
  String get deskSetPrivUseStatus => 'Używaj status.btlabs.uk';

  @override
  String get deskSetPrivUseStatusHint =>
      'Stan sieci i informacje dostarczane przez status.btlabs.uk';

  @override
  String deskSetRecvMethodOnFailed(String method) {
    return 'Nie włączono: $method';
  }

  @override
  String deskSetRecvMethodOffFailed(String method) {
    return 'Nie wyłączono: $method';
  }

  @override
  String get deskSetRecvServerNotChanged => 'Nie zmieniono serwera';

  @override
  String get deskSetRecvReceiving => 'Odbieranie';

  @override
  String deskSetRecvSwitching(String method) {
    return 'Przełączanie odbierania: $method';
  }

  @override
  String deskSetRecvMethodReceiving(String method) {
    return 'Odbieranie: $method';
  }

  @override
  String get deskSetRecvNotSaved => 'Nie zapisano';

  @override
  String get deskSetRecvAutostart => 'Uruchamiaj z portfelem';

  @override
  String get deskSetRecvAutostartHint => 'Włącza się po odblokowaniu.';

  @override
  String deskSetRecvMethodAutostart(String method) {
    return '$method: uruchamiaj z portfelem';
  }

  @override
  String get deskSetRecvHeadStopped => 'Zatrzymany';

  @override
  String get deskSetRecvHeadStarting => 'Uruchamianie';

  @override
  String get deskSetRecvEpicboxTitle => 'Odbieranie przez Epicbox';

  @override
  String get deskSetRecvEpicboxText =>
      'Płatności docierają przez serwer Epicbox, także gdy portfel jest zamknięty.';

  @override
  String get deskSetRecvEpicboxServer => 'Serwer Epicbox';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Który serwer przechowuje płatności na ten adres. Oba portfele mogą używać różnych serwerów.';

  @override
  String get deskSetRecvSwitchingServer => 'Przełączanie serwera Epicbox…';

  @override
  String get deskSetRecvListNote =>
      'Stan z status.btlabs.uk, sprawdzany co kilka minut.';

  @override
  String get deskSetRecvHttpTitle => 'Link · HTTP, odbieranie';

  @override
  String get deskSetRecvHttpText =>
      'Prosto z innego portfela na adres internetowy tego komputera, gdy ten portfel jest otwarty.';

  @override
  String get deskSetRecvHttpOffTitle => 'Wyłączone, gdy Tor jest włączony';

  @override
  String get deskSetRecvHttpOffText =>
      'Płatności prosto z innego portfela docierają wtedy na adres Link · Tor.';

  @override
  String get deskSetRecvPrivacySettings => 'Ustawienia prywatności';

  @override
  String get deskSetHttpNotChanged => 'Nie zmieniono';

  @override
  String get deskSetHttpPortError => 'Port musi być od 1 do 65535';

  @override
  String get deskSetHttpReachable => 'Dostępność';

  @override
  String get deskSetHttpReachableHint => 'Kto może płacić na adres HTTP.';

  @override
  String get deskSetHttpLocalOnly => 'Tylko lokalnie';

  @override
  String get deskSetHttpFromInternet => 'Z internetu';

  @override
  String get deskSetHttpGuideHelp => 'Odbieranie z internetu: jak to działa';

  @override
  String deskSetHttpPublicNote(String port) {
    return 'Odpowiada na wszystkich interfejsach. Router musi przekierować TCP $port do tego komputera. Nadawcy z internetu używają http://<publiczne IP>:$port.';
  }

  @override
  String get deskSetHttpPort => 'Port';

  @override
  String get deskSetHttpPortHint => 'Od 1 do 65535. Używany przez adres HTTP.';

  @override
  String get deskSetHttpPortLabel => 'Port HTTP';

  @override
  String get deskSetHttpGuideTitle => 'Odbieraj z internetu';

  @override
  String get deskSetHttpGuideNowPublic => 'Teraz: z internetu.';

  @override
  String get deskSetHttpGuideNowLocal =>
      'Teraz: tylko lokalnie. Do adresu HTTP docierają tylko programy na tym komputerze.';

  @override
  String get deskSetHttpStep1 => 'Nasłuchuj na wszystkich interfejsach';

  @override
  String deskSetHttpStep1Text(String port) {
    return 'Portfel odpowiada na 0.0.0.0, port $port. Inne urządzenia i internet mogą wtedy wysyłać płatności do tego portfela. Zapora może poprosić o zgodę.';
  }

  @override
  String get deskSetHttpStep2 => 'Przekieruj port';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'Na stronie routera (często 10.0.1.1) znajdź Przekierowanie portów i przekieruj TCP $port do tego komputera.';
  }

  @override
  String get deskSetHttpStep3 => 'Udostępnij adres publiczny';

  @override
  String deskSetHttpStep3Text(String port) {
    return 'Nadawcy używają http://<publiczne IP>:$port. Publiczne IP może się zmieniać.';
  }

  @override
  String get deskSetHttpNoRouter => 'Bez konfiguracji routera?';

  @override
  String get deskSetHttpNoRouterText =>
      'Tor działa z każdego miejsca i nie wymaga przekierowań.';

  @override
  String get deskSetHttpTurnOnTor => 'Włącz Tor';

  @override
  String get deskSetHttpExposed =>
      'Udostępnione jest tylko API odbierania. Zwykłe HTTP nie jest szyfrowane.';

  @override
  String get deskSetHttpBackLocal => 'Wróć do trybu lokalnego';

  @override
  String get deskSetReportNotSent =>
      'Raport nie został wysłany. Spróbuj ponownie.';

  @override
  String get deskSetReportSaveDialog => 'Zapisz raport';

  @override
  String get deskSetReportSaved => 'Zapisano. Bez sekretów, niezaszyfrowany.';

  @override
  String get deskSetReportNotSaved => 'Nie zapisano pliku. Spróbuj ponownie.';

  @override
  String get deskSetReportText => 'Treść raportu';

  @override
  String deskSetReportAppLog(String size) {
    return 'Log aplikacji (ostatnie $size)';
  }

  @override
  String get deskSetReportSent => 'Raport wysłany';

  @override
  String get deskSetReportArrived => 'Raport dotarł.';

  @override
  String deskSetReportArrivedRef(String id) {
    return 'Raport dotarł. Jego numer referencyjny to $id.';
  }

  @override
  String get deskSetReportDescribe => 'Opisz, co się stało.';

  @override
  String get deskSetReportTitle => 'Zgłoś problem';

  @override
  String get deskSetReportDesc =>
      'Raport jest szyfrowany, więc przeczyta go tylko twórca aplikacji. Nic nie zostanie wysłane przed kliknięciem Wyślij. Zapisz do pliku zachowuje ten sam oczyszczony raport, bez szyfrowania.';

  @override
  String get deskSetReportWhat => 'Co się stało';

  @override
  String get deskSetReportWhatHint =>
      'Co było robione, czego oczekiwano, co stało się zamiast tego';

  @override
  String get deskSetReportContact => 'Kontakt';

  @override
  String get deskSetReportContactHint =>
      'Adres e-mail lub inny kontakt do odpowiedzi';

  @override
  String get deskSetReportAttach => 'Dołącz logi (zalecane)';

  @override
  String get deskSetReportAttachHint =>
      'Najnowsza część logu aplikacji, bez fraz, haseł, adresów, IP i folderów domowych.';

  @override
  String get deskSetReportSentWhat => 'Co zostanie wysłane';

  @override
  String get deskSetReportNotSentTitle => 'Nie wysłano';

  @override
  String get deskSetReportOff => 'Wysyłanie jest wyłączone w tej wersji';

  @override
  String get deskSetReportSaveToFile => 'Zapisz do pliku';

  @override
  String get deskSetReportSend => 'Wyślij';

  @override
  String get deskSetRescanComplete => 'Skanowanie zakończone';

  @override
  String get deskSetRescanStoppedLine => 'Skanowanie zatrzymane';

  @override
  String get deskSetRescanLog => 'Log skanowania';

  @override
  String get deskSetRescanText =>
      'Ponownie czyta łańcuch i odbudowuje saldo ze znalezionych wyjść. Użyj tego, gdy saldo wygląda na błędne, po przywróceniu portfela albo gdy wyjścia zostają zablokowane po nieudanej wysyłce. W tym czasie portfela można dalej używać.';

  @override
  String get deskSetRescanStartAgain => 'Zacznij od nowa';

  @override
  String get deskSetRescanDeleteUnconfirmed => 'Usuń niepotwierdzone';

  @override
  String get deskSetRescanDeleteHint =>
      'Anuluje też niepotwierdzone transakcje i odblokowuje ich wyjścia. Płatność, która jest już w drodze, może się wtedy nie udać.';

  @override
  String get deskSetRescanScanning =>
      'Skanowanie łańcucha. Portfela można dalej używać; saldo zaktualizuje się po zakończeniu skanowania.';

  @override
  String get deskSetRescanStopping => 'Zatrzymywanie…';

  @override
  String deskSetRescanChecking(int percent) {
    return 'Sprawdzanie… $percent %';
  }

  @override
  String get deskSetRescanFailed => 'Skanowanie nie powiodło się';

  @override
  String get deskSetRescanNoneFound =>
      'Nie znaleziono niepotwierdzonych transakcji.';

  @override
  String get deskSetRescanCancelled =>
      'Niepotwierdzone transakcje zostały anulowane, a ich wyjścia odblokowane.';

  @override
  String get deskSetRescanNotRead => 'Nie odczytano';

  @override
  String get deskSetRescanFinished => 'Skanowanie zakończone';

  @override
  String get deskSetRescanUpToDate => 'Saldo jest aktualne.';

  @override
  String get deskSetRescanResumed =>
      'Skanowanie było kontynuowane od miejsca zatrzymania; liczby dotyczą tej części.';

  @override
  String get deskSetRescanStoppedEarly =>
      'Zatrzymano przed końcem. Saldo odczytano ponownie; zacznij od nowa, aby kontynuować.';

  @override
  String get deskSetRescanNotDeleted =>
      'Niepotwierdzone transakcje nie zostały usunięte: dzieje się to tylko po pełnym skanowaniu.';

  @override
  String get deskSetRescanBefore => 'Saldo przed';

  @override
  String get deskSetRescanAfter => 'Saldo po';

  @override
  String get deskSetRescanFound => 'Znalezione wyjścia';

  @override
  String get deskSetRescanRestored => 'Przywrócone';

  @override
  String get deskSetRescanRevived => 'Znów niewydane';

  @override
  String get deskSetRescanUnlocked => 'Odblokowane';

  @override
  String get deskSetRescanDeleted => 'Usunięte';

  @override
  String deskSetWalletsAddedBack(String name) {
    return 'Przywrócono na listę: $name';
  }

  @override
  String get deskSetWalletsNotAddedBack => 'Nie przywrócono na listę';

  @override
  String get deskSetWalletsOpenNow => 'Otwarty';

  @override
  String get deskSetWalletsFolderMissing => 'Brak folderu';

  @override
  String deskSetWalletsShowFolder(String name) {
    return 'Pokaż $name w folderze';
  }

  @override
  String deskSetWalletsRemove(String name) {
    return 'Usuń $name…';
  }

  @override
  String get deskSetWalletsRemovedGroup => 'Usunięte z listy';

  @override
  String get deskSetWalletsAddBack => 'Przywróć na listę';

  @override
  String get deskSetWalletsAdd => 'Dodaj portfel';

  @override
  String get deskSetWalletsCreate => 'Utwórz portfel';

  @override
  String get deskSetWalletsCreateText =>
      'Nowy portfel z nową frazą odzyskiwania.';

  @override
  String get deskSetWalletsImport => 'Importuj';

  @override
  String get deskSetWalletsImportText =>
      'Ze starszego Epic Wallet lub z folderu.';

  @override
  String get deskSetWalletsRestore => 'Przywróć';

  @override
  String get deskSetWalletsRestoreText => 'Z frazy odzyskiwania.';

  @override
  String get deskSetupConfirmPassword => 'Potwierdź hasło';

  @override
  String get deskSetupPasswordShort => 'Co najmniej 8 znaków';

  @override
  String get deskSetupPasswordsDiffer => 'Hasła się różnią';

  @override
  String get deskSetupBack => 'Wstecz';

  @override
  String get deskSetupNewWalletAdded => 'Dodano nowy portfel.';

  @override
  String get deskSetupCapsLock => 'Caps Lock jest włączony';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return 'Krok $number z $total: $label';
  }

  @override
  String get deskSetupTryAgain => 'Spróbuj ponownie';

  @override
  String get deskSetupNotSaved => 'Nie zapisano';

  @override
  String get deskSetupStepPrefs => 'Preferencje';

  @override
  String get deskSetupStepNode => 'Węzeł';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupStepReview => 'Podsumowanie';

  @override
  String get deskSetupAgain =>
      'Ponowna konfiguracja. Nic się nie zmieni przed kliknięciem Zapisz ustawienia na ostatnim kroku.';

  @override
  String get deskSetupPrefsLead =>
      'Język aplikacji. Możesz go później zmienić.';

  @override
  String get deskSetupNodeTitle => 'Wybierz węzeł';

  @override
  String get deskSetupNodeLead =>
      'Portfel czyta łańcuch i wysyła płatności przez węzeł Epic.';

  @override
  String get deskSetupLocalTitle => 'Węzeł lokalny';

  @override
  String get deskSetupLocalLead =>
      'Co oznacza węzeł na tym komputerze i którego węzła użyć.';

  @override
  String get deskSetupEpicboxTitle => 'Odbieranie offline';

  @override
  String get deskSetupReviewTitle => 'Sprawdź ustawienia';

  @override
  String get deskSetupReviewLead => 'Popraw to, co się nie zgadza, i zapisz.';

  @override
  String get deskSetupSideTitle => 'Konfiguracja';

  @override
  String get deskSetupBackToWallet => 'Wróć do portfela';

  @override
  String get deskSetupLaterNote =>
      'Wszystko to możesz później zmienić w Ustawieniach.';

  @override
  String get deskSetupSave => 'Zapisz ustawienia';

  @override
  String get deskSetupLanguage => 'Język';

  @override
  String get deskSetupNodeServer => 'Serwer węzła';

  @override
  String get deskSetupCheckingNodes => 'Sprawdzanie węzłów…';

  @override
  String get deskSetupPickNode => 'Wybierz węzeł';

  @override
  String get deskSetupRemoteNode => 'Węzeł zdalny';

  @override
  String get deskSetupRemoteNodeText =>
      'Dowolny węzeł publiczny. Gotowy od razu.';

  @override
  String get deskSetupLocalNodeText =>
      'Uruchamia węzeł Epic na tym komputerze. Nic nie trafia do operatora. Wymaga miejsca na dysku i kilku godzin synchronizacji.';

  @override
  String get deskSetupEpicboxText =>
      'Epicbox dostarcza płatności na adres Epicbox i przechowuje je, dopóki portfel nie będzie online.';

  @override
  String get deskSetupEpicboxPrivacy =>
      'Nie ukrywa adresu IP przed serwerem Epicbox. Jeśli to ważne, użyj VPN.';

  @override
  String get deskSetupEpicboxServer => 'Serwer Epicbox';

  @override
  String get deskSetupChangePrefsSem => 'Zmień preferencje';

  @override
  String get deskSetupChangeNodeSem => 'Zmień węzeł';

  @override
  String get deskSetupChangeEpicboxSem => 'Zmień Epicbox';

  @override
  String get deskSetupChange => 'Zmień';

  @override
  String get deskSetupType => 'Typ';

  @override
  String get deskSetupAddress => 'Adres';

  @override
  String deskSetupExistingNode(String host) {
    return 'Istniejący węzeł na $host';
  }

  @override
  String get deskSetupBundledNode => 'Węzeł lokalny, wbudowany';

  @override
  String get deskSetupWhileSyncing => 'Do synchronizacji';

  @override
  String get deskSetupWait => 'czeka';

  @override
  String get deskSetupDataFolder => 'Folder danych';

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Zapisanie uruchomi węzeł. Pierwsza synchronizacja trwa kilka godzin; portfel otworzy się wcześniej i do tego czasu użyje węzła $node.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Zapisanie uruchomi węzeł. Pierwsza synchronizacja trwa kilka godzin; portfel otworzy się wcześniej.';

  @override
  String get deskSetupServer => 'Serwer';

  @override
  String get deskSetupOff => 'Wyłączony';

  @override
  String get deskSetAboutLicencesLead =>
      'Oprogramowanie open source w tym portfelu. Każdy składnik ma własną licencję; pełne teksty są o jedno kliknięcie stąd.';

  @override
  String get deskSetAboutLicenceApp =>
      'Epic Cash Desktop od BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Nie otwarto przeglądarki';

  @override
  String get deskSetAboutOpen => 'Otwórz';

  @override
  String deskSetAboutVersion(String version) {
    return 'Wersja  $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Węzeł  $version';
  }

  @override
  String get deskSetAboutCommunity => 'Społeczność';

  @override
  String get deskSetAboutLicences => 'Licencje';

  @override
  String get deskSetAboutSource => 'Kod źródłowy';

  @override
  String get deskSetAboutView => 'Pokaż';

  @override
  String deskSetAboutChecked(String ago) {
    return 'Sprawdzono $ago.';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version to najnowsza wersja';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return 'Dostępna aktualizacja: $version';
  }

  @override
  String get deskSetAboutCouldNotCheck => 'Nie udało się sprawdzić';

  @override
  String get deskSetAboutUpdates => 'Aktualizacje';

  @override
  String get deskSetAboutCheckNow => 'Sprawdź teraz';

  @override
  String get deskSetAboutAgoNow => 'przed chwilą';

  @override
  String deskSetAboutAgoMin(int count) {
    return '$count min temu';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return '$count h temu';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return '$count d temu';
  }

  @override
  String get deskSetAboutCopyLink => 'Kopiuj link';

  @override
  String get deskSetAboutCopied => 'Skopiowano';

  @override
  String get deskSetAboutNotCopied => 'Nie skopiowano';

  @override
  String get deskSetAppearTheme => 'Motyw';

  @override
  String get deskSetAppearThemeHint =>
      'Systemowy to motyw ustawiony w komputerze.';

  @override
  String get deskSetAppearSystem => 'Systemowy';

  @override
  String get deskSetAppearDark => 'Ciemny';

  @override
  String get deskSetAppearLight => 'Jasny';

  @override
  String get deskSetAppearScale => 'Skala interfejsu';

  @override
  String get deskSetAppearScaleHint =>
      'Większy lub mniejszy tekst i przyciski. Działa od razu.';

  @override
  String get deskSetAppearLanguage => 'Język';

  @override
  String get deskSetAppearLanguageHint => 'Działa od razu.';

  @override
  String get deskSetAppearHideHint => 'Pokazuje kropki zamiast sald i kwot.';

  @override
  String deskSetHelpNoMatchText(String query) {
    return 'Żaden temat nie pasuje do „$query”. Spróbuj innego słowa.';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znalezione tematy: $count',
      many: 'Znalezione tematy: $count',
      few: 'Znalezione tematy: $count',
      one: 'Znalezione tematy: $count',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'Brak pasujących tematów';

  @override
  String get deskSetHelpReportText =>
      'Opisz, co poszło nie tak. Możesz dołączyć log aplikacji, oczyszczony z sekretów i zaszyfrowany dla twórcy aplikacji. Zapisz do pliku zachowuje kopię do wysłania samodzielnie.';

  @override
  String get deskSetHelpShowLess => 'Zwiń';

  @override
  String get deskSetHelpReadMore => 'Czytaj dalej';

  @override
  String get deskSetHelpEb1 =>
      'Portfel nadawcy przekazuje płatność do Epicbox i blokuje wyjścia.';

  @override
  String get deskSetHelpEb2 =>
      'Epicbox dostarcza ją, gdy portfel odbiorcy jest online. Ten portfel dodaje swoją część i podpisuje.';

  @override
  String get deskSetHelpEb3 => 'Portfel odbiorcy odsyła ją do Epicbox.';

  @override
  String get deskSetHelpEb4 =>
      'Epicbox przekazuje ją z powrotem do portfela nadawcy.';

  @override
  String get deskSetHelpSigns =>
      'Portfel nadawcy też podpisuje, kończy transakcję i publikuje ją w sieci.';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sieć umieszcza ją w bloku. Po $count potwierdzenia jest ostateczna.',
      many:
          'Sieć umieszcza ją w bloku. Po $count potwierdzeniach jest ostateczna.',
      few:
          'Sieć umieszcza ją w bloku. Po $count potwierdzeniach jest ostateczna.',
      one:
          'Sieć umieszcza ją w bloku. Po $count potwierdzeniu jest ostateczna.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 =>
      'Portfel nadawcy zapisuje plik transakcji i blokuje wyjścia. Plik trafia do odbiorcy w dowolny sposób.';

  @override
  String get deskSetHelpFile2 =>
      'Odbiorca go otwiera. Jego portfel dodaje swoją część, podpisuje i zapisuje plik odpowiedzi.';

  @override
  String get deskSetHelpFile3 => 'Plik odpowiedzi wraca do nadawcy.';

  @override
  String get deskSetHelpFile4 =>
      'Nadawca otwiera plik odpowiedzi przyciskiem Sfinalizuj.';

  @override
  String get deskSetHelpSender => 'Nadawca';

  @override
  String get deskSetHelpFile => 'Przesyłanie pliku';

  @override
  String get deskSetHelpRecipient => 'Odbiorca';

  @override
  String get deskSetHelpNetwork => 'Sieć';

  @override
  String get deskSetHelpTravels => 'Jak przebiega transakcja';

  @override
  String get deskSetHelpOverEpicbox => 'Przez Epicbox';

  @override
  String get deskSetHelpWithFile => 'Plikiem';

  @override
  String deskSetHelpStep(int number, int total) {
    return 'Krok $number z $total';
  }

  @override
  String get deskSetHelpSearch => 'Szukaj w pomocy';

  @override
  String get deskSetHelpSearchKeys =>
      'Naciśnij /, aby szukać. Esc czyści wyszukiwanie.';

  @override
  String get deskSetHelpSearchHint => 'Na przykład: plik, potwierdzenia, fraza';

  @override
  String get deskSetHelpClear => 'Wyczyść wyszukiwanie';

  @override
  String get deskSetHelpTourAgain => 'Pokaż przewodnik ponownie';

  @override
  String deskSetHelpTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tematu',
      many: '$count tematów',
      few: '$count tematy',
      one: '$count temat',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSecretProtect =>
      'Windows nie mógł zabezpieczyć sekretów portfela (DPAPI odmówiło), więc nic nie zapisano. Zaloguj się do Windows na własne konto i jego hasłem, nie przez sesję zdalną ani usługową, i spróbuj ponownie.';

  @override
  String get deskKeyringMissingTitle => 'Nie znaleziono pęku kluczy';

  @override
  String get deskKeyringMissingText =>
      'Epic Cash przechowuje swoje ustawienia i zapieczętowane hasło portfela w systemowym pęku kluczy, ale żaden nie odpowiedział. Zainstaluj lub uruchom pęk kluczy (GNOME Keyring lub KWallet), zaloguj się do sesji pulpitu, która go uruchamia, a potem wybierz Ponów.';

  @override
  String get deskKeyringLockedTitle => 'Pęk kluczy jest zablokowany';

  @override
  String get deskKeyringLockedText =>
      'Epic Cash przechowuje swoje ustawienia i zapieczętowane hasło portfela w systemowym pęku kluczy, który jest zablokowany. Odblokuj go (otwiera się hasłem logowania), a potem wybierz Ponów, albo wybierz Odblokuj teraz, aby system o nie poprosił.';

  @override
  String get deskKeyringUnlockNow => 'Odblokuj teraz';

  @override
  String get txStatusNotDelivered => 'Nie dostarczono';

  @override
  String get txDetailsNotDeliveredBody =>
      'Ta płatność nie dotarła jeszcze do epicboxa, więc odbiorca jej nie dostał. Środki pozostają zablokowane, dopóki nie zostanie wysłana ponownie lub anulowana.';

  @override
  String get txDetailsSendAgainDone =>
      'Wysłano ponownie. Płatność zakończy się, gdy portfel odbiorcy będzie online.';

  @override
  String get deskTxThisWallet => 'Ten portfel';

  @override
  String get deskErrOldLinks =>
      'Folder tego portfela zawiera dowiązania; skopiuj go ręcznie albo przywróć portfel z frazy odzyskiwania.';

  @override
  String get deskErrOldIncomplete =>
      'Nie udało się odczytać całego folderu tego portfela; skopiuj go ręcznie albo przywróć portfel z frazy odzyskiwania.';

  @override
  String get deskErrOldSeedTooLarge =>
      'Plik wallet.seed jest za duży, by był seedem portfela.';

  @override
  String get deskErrSendUnbuildable =>
      'Tej płatności nie da się złożyć z dostępnych środków.';

  @override
  String get deskErrNothingToConsolidate =>
      'Nie ma czego scalać: mniej niż dwa wyjścia do wydania.';

  @override
  String deskSetReportFileNone(String name) {
    return '$name (niedołączony)';
  }

  @override
  String deskSetReportFileAll(String name, String size) {
    return '$name (cały, $size)';
  }

  @override
  String deskSetReportFilePart(String name, String part, String size) {
    return '$name (ostatnie $part z $size)';
  }

  @override
  String get deskErrTxNotFound => 'Nie znaleziono transakcji';

  @override
  String get deskTxNowUndelivered =>
      'Nie dostarczono. Płatność nie dotarła do serwera Epicbox, więc odbiorca jej nie otrzymał. Wyślij ją ponownie albo anuluj, żeby odblokować środki.';

  @override
  String get deskTxStatusUndelivered => 'Nie dostarczono';

  @override
  String get deskTxSendAgain => 'Wyślij ponownie';

  @override
  String get deskTxNotSent => 'Nie wysłano';

  @override
  String get deskTxSentAgain => 'Wysłano ponownie';

  @override
  String get deskTxSentAgainText =>
      'Zakończy się, gdy portfel odbiorcy będzie online.';

  @override
  String get deskSendFeeChangedTitle => 'Opłata się zmieniła';

  @override
  String deskSendFeeChangedText(String fee, String was) {
    return 'Wyjścia portfela zmieniły się od tego przeglądu, więc wysyłka kosztuje teraz $fee EPIC zamiast $was EPIC opłaty. Sprawdź ją i wyślij ponownie.';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max bajtów';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'Wiadomość jest dłuższa niż $max bajtów. Skróć ją.';
  }

  @override
  String get deskSetPhraseCopyTitle => 'Skopiować frazę odzyskiwania?';

  @override
  String get deskSetPhraseCopyText =>
      'Każdy, kto ma te słowa, może zabrać twoje środki. Przechowuj kopię w bezpiecznym miejscu.';

  @override
  String get deskOutAdvanced => 'Zarządzaj wyjściami';

  @override
  String get deskOutStrategyHint =>
      'Które wyjścia wydaje wysyłka. Najmniejsze wydaje jak najmniej małych wyjść, a reszta zostaje do wydania; Wszystkie wydaje wszystko i zwraca jedno wyjście. W Wyślij możesz to zmienić dla jednej wysyłki w sekcji Zaawansowane.';

  @override
  String get txStatusNotPosted => 'Nie ma w sieci';

  @override
  String get txStatusStalled => 'Utknęło';

  @override
  String get txDetailsStalledBody =>
      'Utknęło, nie dostarczono. Twoja płatność jeszcze nie dotarła do sieci. Wyślij ją ponownie.';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      'Ta płatność nie dotarła do portfela odbiorcy, więc jej nie otrzymał. Twoje środki pozostaną zablokowane, dopóki nie wyślesz jej ponownie lub jej nie anulujesz.';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service jeszcze nie opublikował Twojej płatności.';
  }

  @override
  String get deskTxStatusNotPosted => 'Nie ma w sieci';

  @override
  String get deskTxNowNotPosted =>
      'Nie ma w sieci. Węzeł nie przyjął tej płatności. Roześlij ją ponownie; nie może przejść dwa razy.';

  @override
  String get deskTxBroadcastAgain => 'Roześlij ponownie';

  @override
  String get deskTxBroadcastDone => 'Wysłano do sieci';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return 'Nie dostarczono. Portfel odbiorcy nie przyjął płatności ($method), więc jej nie otrzymał. Wyślij ją ponownie albo anuluj, żeby odblokować środki.';
  }

  @override
  String get deskInvPayStalled => 'Utknęło';

  @override
  String deskInvPayerStalledTitle(String service) {
    return 'Twoja płatność dla $service utknęła';
  }

  @override
  String get deskInvPayerStalledText =>
      'Nie dostarczono: płatność jeszcze nie dotarła do sieci, a środki pozostają zablokowane. Wyślij ponownie wysyła ją jeszcze raz bez drugiej zgody.';

  @override
  String get deskTxLabelAdd => 'Dodaj etykietę';

  @override
  String get deskTxLabelEdit => 'Edytuj etykietę';

  @override
  String get deskTxLabelHint => 'Dodaj etykietę';

  @override
  String get deskTxLabelField => 'Etykieta';

  @override
  String get deskTxLabelTip =>
      'Nazwa tej płatności, dla ciebie. Widoczna w Aktywności i w eksportach.';

  @override
  String get deskTxLabelAdded => 'Dodano etykietę';

  @override
  String get deskTxLabelSaved => 'Zapisano etykietę';

  @override
  String get deskTxLabelRemoved => 'Usunięto etykietę';

  @override
  String get deskTxLabelNotSaved => 'Nie zapisano etykiety';

  @override
  String get deskTxDetailsAdd => 'Dodaj szczegóły';

  @override
  String get deskTxDetailsEdit => 'Edytuj';

  @override
  String get deskTxDetailsTitleAdd => 'Dodaj szczegóły';

  @override
  String get deskTxDetailsTitleEdit => 'Edytuj szczegóły';

  @override
  String get deskTxDetailsTip =>
      'Tylko dla płatności znalezionych przez skanowanie. W Aktywności, szczegółach i eksportach widoczne jako dodane przez ciebie. Kwoty, daty i potwierdzenia się nie zmieniają.';

  @override
  String get deskTxDetailsFrom => 'Od';

  @override
  String get deskTxDetailsFromTip =>
      'Kto zapłacił, do Twoich zapisów. Niezweryfikowane i nigdy nie używane w potwierdzeniach płatności.';

  @override
  String get deskTxDetailsFromHint => 'Adres nadawcy';

  @override
  String get deskTxDetailsFromBad => 'Użyj adresu Epicbox, http(s) lub .onion.';

  @override
  String get deskTxDetailsNote => 'Notatka';

  @override
  String get deskTxDetailsAdded => 'Dodano szczegóły';

  @override
  String get deskTxDetailsSaved => 'Zapisano szczegóły';

  @override
  String get deskTxDetailsRemoved => 'Usunięto szczegóły';

  @override
  String get deskTxDetailsNotSaved => 'Nie zapisano szczegółów';

  @override
  String get deskTxManualTag => 'Dodane przez ciebie';

  @override
  String deskTxManualTip(String date) {
    return 'Dodane przez ciebie $date. Nie z łańcucha.';
  }

  @override
  String get deskTxManualTipNoDate => 'Dodane przez ciebie. Nie z łańcucha.';

  @override
  String deskTxManualTipFrom(String date) {
    return 'Dodane przez ciebie $date. Nie z łańcucha, niezweryfikowane.';
  }

  @override
  String get deskTxManualTipFromNoDate =>
      'Dodane przez ciebie. Nie z łańcucha, niezweryfikowane.';

  @override
  String get deskHistConflictTitle => 'Szczegóły się różnią';

  @override
  String deskHistConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Kopia ma inne szczegóły dla $n płatności, które opisano. Twoje zostają, chyba że wybierzesz inaczej.',
      many:
          'Kopia ma inne szczegóły dla $n płatności, które opisano. Twoje zostają, chyba że wybierzesz inaczej.',
      few:
          'Kopia ma inne szczegóły dla $n płatności, które opisano. Twoje zostają, chyba że wybierzesz inaczej.',
      one:
          'Kopia ma inne szczegóły dla $n płatności, którą opisano. Twoje zostają, chyba że wybierzesz inaczej.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'Moje';

  @override
  String get deskHistConflictBackup => 'Kopia';

  @override
  String get deskHistConflictKeepAll => 'Zachowaj wszystkie moje';

  @override
  String get deskHistConflictImport => 'Importuj';

  @override
  String get deskHistConflictEmpty => 'puste';

  @override
  String deskHistImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Zastąpiono $n szczegółu, reszta zostaje jak ją wpisano.',
      many: 'Zastąpiono $n szczegółów, reszta zostaje jak ją wpisano.',
      few: 'Zastąpiono $n szczegóły, reszta zostaje jak ją wpisano.',
      one: 'Zastąpiono $n szczegół, reszta zostaje jak ją wpisano.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayUnknown(String relay) {
    return 'Aplikacja nie zna serwera $relay. Sprawdź adres przed wysłaniem.';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay nie odpowiedział.';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay nie odpowiedział, więc odbiorca nie dostał tej płatności. Środki pozostają zablokowane, dopóki nie zostanie wysłana ponownie lub anulowana.';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return 'Nie dostarczono: $relay nie odpowiedział. Płatność czeka w Aktywności; anuluj ją tam, aby odblokować środki.';
  }

  @override
  String deskErrRelayNoAnswer(String relay) {
    return '$relay nie odpowiedział.';
  }

  @override
  String get deskSendRelayUnknownTitle => 'Nieznany serwer Epicbox';

  @override
  String deskSendRelayUnknownText(String relay) {
    return 'Aplikacja nie zna serwera $relay. Sprawdź adres przed wysłaniem. Nadal możesz wysłać.';
  }

  @override
  String deskTxNowUndeliveredRelay(String relay) {
    return 'Nie dostarczono. $relay nie odpowiedział, więc odbiorca nie otrzymał płatności. Wyślij ją ponownie albo anuluj, żeby odblokować środki.';
  }

  @override
  String get deskInvNoticeReceiveSuperseded =>
      'Twoje drugie urządzenie z tym portfelem przyjęło płatność, którą odbierało też to urządzenie. Użyj „Sprawdź saldo”, aby zobaczyć ją tutaj.';

  @override
  String deskHistConflictLeadOldWallet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Historia starego portfela ma inne szczegóły dla $n płatności, które opisano. Twoje zostają, chyba że wybierzesz inaczej.',
      many:
          'Historia starego portfela ma inne szczegóły dla $n płatności, które opisano. Twoje zostają, chyba że wybierzesz inaczej.',
      few:
          'Historia starego portfela ma inne szczegóły dla $n płatności, które opisano. Twoje zostają, chyba że wybierzesz inaczej.',
      one:
          'Historia starego portfela ma inne szczegóły dla $n płatności, którą opisano. Twoje zostają, chyba że wybierzesz inaczej.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Stary portfel';

  @override
  String get deskHistConflictApply => 'Zastosuj';

  @override
  String get deskTxProofNone => 'Brak dowodu płatności dla tej płatności.';

  @override
  String get deskUpdAvailable => 'Dostępna aktualizacja';

  @override
  String deskUpdNotice(String version) {
    return 'Dostępna aktualizacja · $version';
  }

  @override
  String deskUpdDownload(String version) {
    return 'Pobierz $version';
  }

  @override
  String get deskUpdOpensPage => 'Otwiera stronę pobierania';

  @override
  String deskUpdDownloading(String percent) {
    return 'Pobieranie: $percent %';
  }

  @override
  String get deskUpdRestart => 'Uruchom ponownie i zaktualizuj';

  @override
  String deskUpdReady(String version) {
    return '$version jest gotowa';
  }

  @override
  String get deskUpdRestartHint =>
      'Aplikacja zamknie się, zainstaluje aktualizację i otworzy ponownie.';

  @override
  String get deskUpdFailed => 'Nie udało się pobrać aktualizacji';

  @override
  String get deskUpdTryAgain => 'Spróbuj ponownie';

  @override
  String get deskUpdInstallFailed => 'Nie udało się zainstalować aktualizacji';

  @override
  String get deskUpdOpenPage => 'Otwórz stronę pobierania';

  @override
  String get deskUpdErrDamaged =>
      'Plik nie zgadza się z podpisanymi danymi aktualizacji.';

  @override
  String get deskUpdErrStopped => 'Pobieranie przerwane.';

  @override
  String get deskUpdErrInstall =>
      'Nie udało się podmienić aplikacji na nową wersję.';

  @override
  String get deskUpdUnfinished =>
      'Aktualizacja nie została dokończona. Spróbuj ponownie.';

  @override
  String get advExperimental => 'Eksperymentalne';

  @override
  String get advTitle => 'Zaawansowane';

  @override
  String get advStateOff => 'Wyłączone';

  @override
  String get advIntro =>
      'Na początku wszystko jest wyłączone. Każdy przełącznik dodaje jedną część portfela w miejscu, do którego należy.';

  @override
  String get advShowsHeader => 'Pokazuje więcej';

  @override
  String get advNetworkHeader => 'Sieć';

  @override
  String get advNetworkHint =>
      'Jak portfel łączy się z siecią. Standardowy łączy się bezpośrednio; Tora można włączyć w Prywatność i sieć. Tylko Tor nigdy nie łączy się bezpośrednio: bez Tora portfel pozostaje offline i mówi o tym na ekranie głównym. Offline zostaje na tym telefonie i w twojej sieci lokalnej: Płatność QR i Przesyłanie pliku nadal działają przez używany węzeł; z węzłem w twojej sieci możesz też wysyłać na adresy lokalne, a saldo się odświeża.';

  @override
  String get advOutputs => 'Wyjścia';

  @override
  String get advOutputsHint =>
      'Pokazuje stronę Wyjścia pod Portfelem i na ekranie głównym. Wymienia monety, z których składa się saldo, pozwala je dzielić lub scalać i ustawia domyślne zasady wysyłki. Trwający podział lub scalanie utrzymuje stronę widoczną.';

  @override
  String get advTechnical => 'Szczegóły techniczne';

  @override
  String get advTechnicalHint =>
      'Pokazuje wiersze techniczne w szczegółach płatności: kernel, ID slate, commitmenty i wysokość bloku. W Fakturach pokazuje rotację adresów i liczbę odrzuconych wiadomości.';

  @override
  String get advSendOptions => 'Opcje wysyłki';

  @override
  String get advSendOptionsHint =>
      'Pokazuje Strategię wysyłki i Podziel resztę w Ustawienia › Transakcje: które wyjścia wydaje wysyłka i czy jej reszta jest dzielona. Pozostaje widoczne, dopóki któraś z nich nie jest domyślna.';

  @override
  String get advServerDetails => 'Szczegóły serwerów';

  @override
  String get advServerDetailsHint =>
      'Pokazuje hosty, opóźnienie, wersję i wysokość bloku na listach serwerów i na karcie stanu oraz adres przekaźnika w Odbierz.';

  @override
  String get advRecheckHeight => 'Sprawdź od wysokości';

  @override
  String get advRecheckHeightHint =>
      'Pozwala Sprawdź saldo zacząć od wysokości bloku lub daty zamiast od pierwszego bloku. Szybciej, i jedyny sposób, by pominąć wczesną historię. Przywracanie zawsze daje taki wybór.';

  @override
  String get advModeStandard => 'Standardowy';

  @override
  String get advModeStandardLine =>
      'Łączy się bezpośrednio. Tora można włączyć w Prywatność i sieć.';

  @override
  String get advModeTorOnly => 'Tylko Tor';

  @override
  String get advModeTorOnlyLine =>
      'Każde połączenie idzie przez Tor. Bez Tora portfel pozostaje offline i mówi o tym.';

  @override
  String get advModeOffline => 'Offline';

  @override
  String get advModeOfflineLine =>
      'Tylko ten telefon i twoja sieć lokalna. Płatność QR i Przesyłanie pliku nadal działają przez używany węzeł; wszystko inne czeka, aż wrócisz do poprzedniego trybu.';

  @override
  String get advTorOnlyNote =>
      'Tylko Tor wstrzymuje powiadomienia: zapisanie się na nie ujawniłoby adres tego telefonu.';

  @override
  String get advOfflineNote =>
      'Offline wstrzymuje Epicbox, Tor, sprawdzanie stanu i powiadomienia. Płatność QR i Przesyłanie pliku nadal działają: korzystają z bieżącego węzła do odczytu łańcucha i wysłania, także publicznego. Z węzłem w twojej sieci lokalnej działają też Sprawdź saldo i wysyłki przez Link na adresy lokalne. Peery węzła to ustawienie samego węzła.';

  @override
  String get advReset => 'Ukryj wszystko ponownie';

  @override
  String get advHomeOffline => 'Tryb offline';

  @override
  String get advHomeTorOnlyWaiting => 'Tylko Tor · czeka na Tor';

  @override
  String get advBuiltInNode => 'Wbudowany węzeł';

  @override
  String get advLogs => 'Logi';

  @override
  String get deskSetFrameAdvanced => 'Zaawansowane';

  @override
  String get deskSetAdvIntro =>
      'Na początku wszystko jest wyłączone. Każdy przełącznik dodaje jedną część portfela w miejscu, do którego należy.';

  @override
  String get deskSetAdvShows => 'Pokazuje więcej';

  @override
  String get deskSetAdvOutputs => 'Wyjścia';

  @override
  String get deskSetAdvOutputsHint =>
      'Pokazuje stronę Wyjścia na pasku bocznym. Wymienia monety, z których składa się saldo, pozwala je dzielić lub scalać i ustawia domyślne zasady wysyłki. Trwający podział lub scalanie utrzymuje stronę widoczną.';

  @override
  String get deskSetAdvTechnical => 'Szczegóły techniczne';

  @override
  String get deskSetAdvTechnicalHint =>
      'Pokazuje sekcję Szczegóły techniczne przy każdej transakcji: ID slate, kernel, wysokość bloku, stan i typ rdzenia oraz dowód płatności. Bez tego link Więcej przy transakcji pokazuje je jednorazowo. W Fakturach pokazuje sekcje zaawansowane.';

  @override
  String get deskSetAdvSendOptions => 'Opcje wysyłki';

  @override
  String get deskSetAdvSendOptionsHint =>
      'Dodaje do Wyślij sekcję, w której jedna wysyłka może wybrać, które wyjścia wydaje, Najmniejsze lub Wszystkie, i czy dzielić resztę. Wartości domyślne zostają w Wyjściach.';

  @override
  String get deskSetAdvServerDetails => 'Szczegóły serwerów';

  @override
  String get deskSetAdvServerDetailsHint =>
      'Pokazuje hosty, opóźnienie, wersję i wysokość bloku na listach węzłów i Epicbox, w wierszach stanu na pasku bocznym i na karcie stanu.';

  @override
  String get deskSetAdvRecheck => 'Sprawdź od wysokości';

  @override
  String get deskSetAdvRecheckHint =>
      'Pozwala Sprawdź saldo odrzucić także niepotwierdzone transakcje. Przywracanie każdemu daje wybór bloku początkowego, niezależnie od tego przełącznika.';

  @override
  String get deskSetAdvBuiltInNode => 'Wbudowany węzeł';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'Pozwala temu komputerowi uruchomić własny węzeł: opcja Ten komputer w Węźle, jej panel synchronizacji i Uruchom węzeł na Przeglądzie. Synchronizacja łańcucha trwa godziny i zajmuje kilka gigabajtów dysku. Działający węzeł zachowuje swoje wiersze.';

  @override
  String get deskSetAdvLogs => 'Logi';

  @override
  String get deskSetAdvLogsHint =>
      'Pokazuje grupę Logi w Pomocy: otwórz folder logów, wyczyść logi. Zgłoszenie problemu i tak dołącza log.';

  @override
  String get deskSetAdvNetwork => 'Sieć';

  @override
  String get deskSetAdvNetworkHint =>
      'Jak portfel łączy się z siecią. Standardowy łączy się bezpośrednio; Tora można włączyć w Prywatności. Tylko Tor nigdy nie łączy się bezpośrednio: bez Tora portfel pozostaje offline i mówi o tym na pasku bocznym. Offline zostaje na tym komputerze i w twojej sieci lokalnej: Przesyłanie pliku nadal działa przez używany węzeł; z węzłem tutaj lub w twojej sieci możesz też wysyłać na adresy lokalne i odbierać przez Link, a saldo się odświeża. Wbudowany węzeł działa dalej, a jego peery to ustawienie samego węzła.';

  @override
  String get deskSetAdvModeStandard => 'Standardowy';

  @override
  String get deskSetAdvModeStandardText =>
      'Łączy się bezpośrednio. Tora można włączyć w Prywatności.';

  @override
  String get deskSetAdvModeTorOnly => 'Tylko Tor';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'Każde połączenie idzie przez Tor. Bez Tora portfel pozostaje offline i mówi o tym.';

  @override
  String get deskSetAdvModeOffline => 'Offline';

  @override
  String get deskSetAdvModeOfflineText =>
      'Tylko ten komputer i twoja sieć lokalna. Twój węzeł działa dalej; jego peery to ustawienie samego węzła.';

  @override
  String get deskSetAdvTorOnlyNote =>
      'Tylko Tor wyłącza odbieranie przez Link · HTTP: zwykły adres ujawniłby ten komputer.';

  @override
  String get deskSetAdvOfflineNote =>
      'Epicbox, Tor i sprawdzanie stanu są wstrzymane. Przesyłanie pliku nadal działa przez używany węzeł, także publiczny. Z węzłem na tym komputerze lub w twojej sieci działają też Sprawdź saldo i wysyłki przez Link na adresy lokalne.';

  @override
  String get deskSetAdvNotInBuild => 'Brak w tej wersji';

  @override
  String get deskSetAdvReset => 'Ukryj wszystko ponownie';

  @override
  String deskSetAdvOn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n przełącznika włączonego',
      many: '$n przełączników włączonych',
      few: '$n przełączniki włączone',
      one: '1 przełącznik włączony',
    );
    return '$_temp0';
  }

  @override
  String get deskShellOffline => 'Tryb offline';

  @override
  String get deskShellTorOnlyWaiting => 'Tylko Tor · czeka na Tor';

  @override
  String get deskSetAcctAutoLockHint =>
      'Blokuje portfel po tym czasie bez naciśnięcia klawisza lub ruchu myszy. Wyłączona: portfel blokuje tylko „Zablokuj portfel”.';

  @override
  String get netBlockOffline => 'Tryb offline jest włączony w Zaawansowanych.';

  @override
  String get netBlockTorOnly => 'Tylko Tor jest włączony w Zaawansowanych.';

  @override
  String get netBlockWaitingForTor => 'Czeka na Tor.';

  @override
  String get receiveOfflineLine =>
      'W trybie offline nie można odbierać tą metodą.';

  @override
  String get txDetailsMore => 'Więcej';

  @override
  String get restoreStartFromLink => 'Zacznij od daty lub wysokości';

  @override
  String get homeOfflineDetail =>
      'Tryb offline jest włączony w Zaawansowanych. Saldo jest z ostatniego odczytu.';

  @override
  String get homeWaitingTorDetail =>
      'Tylko Tor jest włączony w Zaawansowanych. Czekam na połączenie Tora.';

  @override
  String get settingsRescanBodyPlain =>
      'Portfel ponownie szuka swoich środków, od pierwszego bloku. To może potrwać długo.';

  @override
  String get slNodeField => 'Adres węzła';

  @override
  String get slRelayField => 'Serwer Epicbox';

  @override
  String get slFieldHint => 'Wklej lub wpisz, aby filtrować lub dodać';

  @override
  String slSwitchTitle(String host) {
    return 'Przełączyć na $host?';
  }

  @override
  String get slSwitchBody => 'Twój adres Epicbox się zmieni. Udostępnij nowy.';

  @override
  String get slSwitch => 'Przełącz';

  @override
  String get slHelpAddable => 'Nie ma go na liście.';

  @override
  String slHelpMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyniku.',
      many: '$count wyników.',
      few: '$count wyniki.',
      one: '$count wynik.',
      zero: 'Brak wyników.',
    );
    return '$_temp0';
  }

  @override
  String get slClear => 'Wyczyść';

  @override
  String slAddRow(String host) {
    return 'Dodaj $host';
  }

  @override
  String get slAddTestsNode =>
      'Najpierw sprawdza węzeł, potem proponuje przełączenie.';

  @override
  String get slAddTestsRelay =>
      'Najpierw sprawdza serwer, potem proponuje przełączenie.';

  @override
  String slAdded(String host) {
    return 'Dodano $host.';
  }

  @override
  String get slRemove => 'Usuń';

  @override
  String slRemoved(String host) {
    return 'Usunięto $host.';
  }

  @override
  String get slUndo => 'Cofnij';

  @override
  String get slInUseSwitchFirst => 'W użyciu. Najpierw przełącz.';

  @override
  String get slRestore => 'Przywróć usunięte serwery';

  @override
  String slRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usuniętego',
      many: '$count usuniętych',
      few: '$count usunięte',
      one: '$count usunięty',
    );
    return '$_temp0';
  }

  @override
  String get slRestored => 'Przywrócono usunięte serwery.';

  @override
  String get slRelayWarning =>
      'Przełączenie zmieni twój adres; nadawcy potrzebują nowego.';

  @override
  String get slNotAnAddress =>
      'To nie jest adres serwera. Użyj host lub host:port.';

  @override
  String get slRelayNoAnswer => 'Ten serwer nie odpowiada. Nic nie dodano.';

  @override
  String deskSlRemoveHost(String host) {
    return 'Usuń $host';
  }

  @override
  String get deskSlInUse => 'W użyciu';

  @override
  String get deskSlHealthUnknown => 'Stan nieznany';

  @override
  String get deskSlNodeNoAnswer => 'Ten węzeł nie odpowiada. Nic nie dodano.';

  @override
  String get deskSlTorWait => 'Tor nie jest jeszcze połączony. Nic nie dodano.';

  @override
  String deskSlLatency(String ms) {
    return '$ms ms';
  }

  @override
  String get deskSlDefault => 'Domyślny';

  @override
  String deskSlTesting(String host) {
    return 'Sprawdzanie $host…';
  }

  @override
  String get deskSlSetupEpicboxOn => 'Odbieraj przez Epicbox';

  @override
  String get deskSlHelpChoose =>
      'Wybierz jeden albo wpisz, aby przefiltrować listę lub dodać serwer.';

  @override
  String get deskOnbRestoreFromLink => 'Zacznij od wysokości bloku';

  @override
  String get deskOnbRestoreFromHide => 'Sprawdź cały łańcuch';

  @override
  String get deskOnbRestoreFromLabel => 'Zacznij od bloku';

  @override
  String get deskOnbRestoreFromHint => 'Wysokość bloku';

  @override
  String get deskOnbRestoreFromHelp =>
      'Tylko jeśli pierwsza płatność portfela przyszła po tym bloku. Zostaw puste, aby sprawdzić cały łańcuch.';

  @override
  String get deskOnbRestoreFromInvalid => 'Użyj samych cyfr albo zostaw puste.';

  @override
  String get deskNetOfflineReason =>
      'Tryb offline jest włączony w Zaawansowanych.';

  @override
  String get deskNetWaitingTorReason =>
      'Czeka na Tor. Tylko Tor jest włączony w Zaawansowanych.';

  @override
  String get deskNetTorOnlyLine => 'Tylko Tor jest włączony w Zaawansowanych.';

  @override
  String get deskNetOpenAdvanced => 'Otwórz Zaawansowane';

  @override
  String get deskNetSendFileHint => 'Przesyłanie pliku nadal działa.';

  @override
  String get deskNetRecvOfflineText =>
      'Twój adres się nie zmienia. Nic nie dotrze, dopóki tryb offline jest włączony.';

  @override
  String get deskNetRecvWaitTorText =>
      'Odbieranie zacznie się, gdy Tor się połączy. Przesyłanie pliku nadal działa.';

  @override
  String get deskNetCantReceive => 'Offline nie można odbierać.';

  @override
  String get deskRailOffline => 'Offline';

  @override
  String get deskTourAdvancedTitle => 'Zaawansowane';

  @override
  String get deskTourAdvancedText =>
      'Tryb tylko Tor, wyjścia i szczegóły techniczne są tutaj. Włącz to, czego potrzebujesz.';

  @override
  String get deskTxMore => 'Więcej';

  @override
  String get deskTxLess => 'Mniej';

  @override
  String get settingsSectionTransactions => 'Transakcje';

  @override
  String get settingsHubMethods => 'Metody';

  @override
  String get settingsHubDefault => 'Domyślna';

  @override
  String get settingsHubSendDefaults => 'Zasady wysyłki';

  @override
  String get txMethodsHeader => 'Metody płatności';

  @override
  String get txFamilyLinkLine =>
      'Prosto do drugiego portfela, gdy oba są otwarte.';

  @override
  String get txFamilyDirectLine =>
      'Z rąk do rąk, bez połączenia między portfelami.';

  @override
  String get txLinkHttpLine =>
      'Płać na adresy internetowe; dostawaj zapłatę z tej sieci Wi-Fi.';

  @override
  String get txLinkHttpHint =>
      'Link · HTTP płaci prosto do portfela pod adresem internetowym (http://host:3415) i daje temu telefonowi adres, na który mogą płacić portfele z tej samej sieci Wi-Fi. Oba portfele muszą być otwarte. Po drodze nie jest szyfrowany, nie jest osiągalny z internetu ani przez dane komórkowe i jest wyłączony, gdy Tor jest włączony. Dodaje Link · HTTP do Wyślij i Odbierz.';

  @override
  String get txLinkTorLine =>
      'Płać na adresy onion; dostawaj zapłatę na adres Tor tego telefonu.';

  @override
  String get txLinkTorHint =>
      'Link · Tor płaci prosto do portfela pod adresem onion i daje temu telefonowi adres Tor, na który można mu płacić. Oba portfele muszą być otwarte. Wymaga Tora: przełącznik Tor w Prywatność i sieć kieruje połączenia portfela przez Tor; ten przełącznik tylko włącza adres. Dodaje Link · Tor do Wyślij i Odbierz.';

  @override
  String get txLinkTorNeedsTor => 'Wymaga Tora. Włącz go w Prywatność i sieć.';

  @override
  String get txLastMethodNotice =>
      'Przynajmniej jedna metoda płatności musi zostać włączona.';

  @override
  String get txEpicboxHint =>
      'Epicbox płaci przez przekaźnik, więc drugi portfel nie musi być otwarty. Wyłączony: portfel nie łączy się z żadnym przekaźnikiem, więc bez płatności Epicbox, faktur i powiadomień. Pozostałe metody nadal działają.';

  @override
  String get txDirectLine =>
      'Płać na adresy internetowe i onion; dostawaj zapłatę prosto z innych portfeli.';

  @override
  String get txDirectHint =>
      'Link płaci prosto do drugiego portfela pod adresem internetowym lub onion i pozwala temu telefonowi przyjmować płatności w ten sam sposób. Oba portfele muszą być otwarte. HTTP działa w tej sieci Wi-Fi; Tor wymaga Tora. Dodaje Link do Wyślij i Odbierz.';

  @override
  String get txFileLine =>
      'Płać lub dostawaj zapłatę plikiem, który przekazujesz sam.';

  @override
  String get txFileHint =>
      'Przesyłanie pliku tworzy plik transakcji, który przekazujesz drugiej osobie dowolnym sposobem (wiadomość, mail, kabel), a ona odsyła ci drugi. Nie potrzeba połączenia między portfelami. Dodaje Przesyłanie pliku do Wyślij i Odbierz.';

  @override
  String get txStartHeader => 'Wysyłanie zaczyna od';

  @override
  String get txStartNote =>
      'Na ekranie Wyślij nadal możesz wybrać inną metodę.';

  @override
  String get txDefaultsHeader => 'Zasady wysyłki';

  @override
  String get outputsDefaultsMoved =>
      'Domyślne zasady wysyłki są w Ustawienia › Transakcje';

  @override
  String get advNodeFailover => 'Automatyczna zmiana węzła';

  @override
  String get advNodeFailoverHint =>
      'Gdy twój węzeł przestaje odpowiadać, portfel na czas tej sesji używa następnego działającego węzła z twojej listy.';

  @override
  String nodeFailoverSwitched(String host) {
    return 'Węzeł nie odpowiada. Przełączono na $host.';
  }

  @override
  String nodeFailoverInsteadOf(String host) {
    return 'Zamiast $host';
  }

  @override
  String get deskSetAdvNodeFailover => 'Automatyczna zmiana węzła';

  @override
  String get deskSetAdvNodeFailoverHint =>
      'Gdy twój węzeł przestaje odpowiadać, portfel na czas tej sesji używa następnego działającego węzła z twojej listy.';

  @override
  String deskNodeFailoverSwitched(String host) {
    return 'Węzeł nie odpowiada. Przełączono na $host.';
  }

  @override
  String deskNodeFailoverInsteadOf(String host) {
    return 'Zamiast $host';
  }

  @override
  String get netOfflineOnlyLocal => 'Offline: tylko adresy lokalne.';

  @override
  String get netOfflineNoPeers =>
      'Twój węzeł nie ma peerów: płatność czeka w jego puli, aż się ponownie połączy.';

  @override
  String get netOfflineNodeHint =>
      'Używa węzła do odczytu łańcucha i wysłania. Dla największej prywatności użyj lokalnego węzła.';

  @override
  String get netOfflineNodeLine => 'Używa węzła';

  @override
  String get netBlockEpicboxOff =>
      'Epicbox jest wyłączony w Ustawienia › Transakcje.';

  @override
  String netBlockMethodOff(String method) {
    return 'Metoda $method jest wyłączona w Ustawienia › Transakcje.';
  }

  @override
  String get txEpicboxLine =>
      'Płać lub dostawaj zapłatę przez przekaźnik. Drugi portfel może być zamknięty.';

  @override
  String get txEpicboxOffTitle => 'Wyłączyć Epicbox?';

  @override
  String txEpicboxOffPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności czeka na odpowiedzi przez Epicbox. Dotrą, gdy Epicbox znów będzie włączony.',
      many:
          '$count płatności czeka na odpowiedzi przez Epicbox. Dotrą, gdy Epicbox znów będzie włączony.',
      few:
          '$count płatności czekają na odpowiedzi przez Epicbox. Dotrą, gdy Epicbox znów będzie włączony.',
      one: 'Jedna płatność czeka na odpowiedź przez Epicbox. Dotrze, gdy Epicbox znów będzie włączony.',
    );
    return '$_temp0';
  }

  @override
  String get txEpicboxOffAction => 'Wyłącz';

  @override
  String get pushNoticeOffEpicbox =>
      'Powiadomienia wyłączone: potrzebują Epicbox.';

  @override
  String get settingsPushNeedsEpicbox => 'Wymaga Epicbox';

  @override
  String sendContactOnlyEpicbox(String name) {
    return '$name ma tylko adres Epicbox.';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name ma tylko adres dla metody $method.';
  }

  @override
  String get receiveEpicboxOffText =>
      'Płatności od nadawców czekają na przekaźniku, aż Epicbox znów będzie włączony.';

  @override
  String get receiveNoMethods => 'Żadna metoda odbioru nie jest włączona';

  @override
  String get receiveNoMethodsBody => 'Włącz jedną w Ustawienia › Transakcje.';

  @override
  String get receiveNoMethodsButton => 'Otwórz ustawienia';

  @override
  String get deskErrOfflineOnlyLocal => 'Offline: tylko adresy lokalne.';

  @override
  String get deskNetOfflineNoPeers =>
      'Twój węzeł nie ma peerów: płatność czeka w jego puli, aż się ponownie połączy.';

  @override
  String get deskOutDefaultsMoved =>
      'Strategię i Podziel resztę dla wysyłek ustawisz w Ustawienia › Transakcje.';

  @override
  String get deskOutDefaultsOpen => 'Otwórz Transakcje';

  @override
  String get deskSetFrameTransactions => 'Transakcje';

  @override
  String get deskSetTxMethods => 'Metody płatności';

  @override
  String get deskSetTxEpicboxHint =>
      'Płać i dostawaj zapłatę przez serwer Epicbox. Tak idzie większość płatności. Wyłączony: portfel nie łączy się z żadnym serwerem Epicbox, więc bez płatności Epicbox i faktur. Pozostałe metody nadal działają.';

  @override
  String get deskSetTxDirectHint =>
      'Płać i dostawaj zapłatę prosto z portfela do portfela pod adresem internetowym (http://host:3415), bez serwera pośrodku. Działa tylko, gdy oba portfele są otwarte; wyłączony, gdy Tor jest włączony. Dodaje Link · HTTP do Wyślij, a jego adres do Odbierz.';

  @override
  String get deskSetTxFileHint =>
      'Płać i dostawaj zapłatę, przekazując plik transakcji, bez potrzeby sieci. Dodaje Przesyłanie pliku do Wyślij, a kroki z plikami do Odbierz.';

  @override
  String get deskSetTxSend => 'Wyślij';

  @override
  String get deskSetTxStart => 'Wysyłanie zaczyna od';

  @override
  String get deskSetTxStartHint =>
      'Metoda, z którą otwiera się strona Wyślij. Dla jednej płatności nadal możesz ją zmienić na stronie Wyślij.';

  @override
  String get deskSendMethodHeader => 'Metoda płatności';

  @override
  String get sendRequestTitle => 'Prośba o płatność';

  @override
  String get sendRequestCheck => 'Sprawdź kwotę, potem przejdź dalej.';

  @override
  String get sendRequestDismiss => 'Zamknij';

  @override
  String get sendAmountFromCode => 'Kwota z kodu';

  @override
  String sendAmountCodeAsked(String amount) {
    return 'Kod prosił o $amount.';
  }

  @override
  String get sendCodeAmountInvalid =>
      'Kwota w tym kodzie jest nieprawidłowa i została pominięta.';

  @override
  String get sendCodeAmountTooLarge =>
      'Kwota w tym kodzie jest zbyt duża i została pominięta.';

  @override
  String get sendCodeTooLong =>
      'Część tego kodu była zbyt długa i została pominięta.';

  @override
  String get payeeNameLabel => 'Nazwa podana przez odbiorcę (niezweryfikowana)';

  @override
  String get payeeNoteLabel => 'Notatka od odbiorcy (niezweryfikowana)';

  @override
  String get payeeUnverifiedTitle => 'Niezweryfikowane';

  @override
  String get payeeUnverifiedHint =>
      'Nazwę i notatkę wpisuje do kodu ten, kto go tworzy. Nikt ich nie sprawdza. Sprawdź adres i kwotę, nie nazwę.';

  @override
  String get sendNoteFromCodeHelper => 'Z kodu. Odbiorca też ją zobaczy.';

  @override
  String get sendOriginQr => 'Z kodu QR';

  @override
  String get sendOriginLink => 'Z linku';

  @override
  String get sendOriginPasted => 'Wklejone';

  @override
  String get sendDirectHost => 'Host';

  @override
  String get sendPlainHttpRow => 'Bez szyfrowania (zwykły HTTP)';

  @override
  String get scanNotEpicTitle => 'To nie jest kod Epic';

  @override
  String get scanNotEpicBody => 'To nie jest adres Epic ani kod płatności.';

  @override
  String get scanBadAddress => 'Adres w tym kodzie jest nieprawidłowy.';

  @override
  String get scanWrongNetworkTitle => 'Inna sieć';

  @override
  String get scanWrongNetworkBody =>
      'Ten adres należy do innej sieci Epic. Ten portfel nie może na niego zapłacić.';

  @override
  String get scanSlateTextBody =>
      'To jest tekst pliku transakcji, a nie adres.';

  @override
  String get commonOpen => 'Otwórz';

  @override
  String get scanPairingTitle => 'Link parowania';

  @override
  String get scanPairingUnavailable =>
      'Parowanie nie jest dostępne w tej wersji.';

  @override
  String get scanCodeTextLabel => 'Zeskanowany tekst';

  @override
  String get scanCopied => 'Skopiowano';

  @override
  String get linkWaitingNotice => 'Otrzymano link płatności';

  @override
  String get linkFinishCurrentFirst => 'Najpierw dokończ bieżącą płatność.';

  @override
  String get deskSendToQrPayment =>
      'Kod Płatności QR. Zeskanuj go w Epic Cash Mobile.';

  @override
  String get deskSetRecvTorTitle => 'Link · Tor, odbieranie';

  @override
  String get deskSetRecvTorText =>
      'Prosto z innego portfela na adres Tor tego portfela, gdy jest otwarty.';

  @override
  String get deskSetTxTorHint =>
      'Płać i dostawaj zapłatę prosto z portfela do portfela pod adresem onion, przez Tor, bez serwera pośrodku. Działa tylko, gdy oba portfele są otwarte. Wymaga Tora: przełącznik Tor w Prywatności kieruje połączenia portfela przez Tor; ten przełącznik tylko włącza adres. Dodaje Link · Tor do Wyślij, a jego adres do Odbierz.';

  @override
  String get deskSetTxTorNeedsTor =>
      'Tor jest wyłączony. Włącz go w Prywatności, aby przyjmować płatności na adres Tor.';

  @override
  String get deskSetTxLastMethod =>
      'Przynajmniej jedna metoda płatności musi zostać włączona.';

  @override
  String get deskRecvTorOffTitle => 'Odbieranie przez Link · Tor wymaga Tora.';

  @override
  String get deskRecvTorOffText =>
      'Adres Tor działa, gdy Tor jest włączony. Tor to przełącznik w Ustawienia › Prywatność; kieruje połączenia portfela przez Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Ustawienia nie zostały zapisane';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Bez zapisu portfel używa ustawień zapisanych do tej pory. Można je później zmienić w Ustawieniach.';
  }

  @override
  String get deskSetupSkipSave => 'Kontynuuj bez zapisywania';

  @override
  String get deskSetupResumeLead =>
      'Konfiguracja nie została ostatnio dokończona. Portfel czyta łańcuch i wysyła płatności przez węzeł Epic.';

  @override
  String deskErrProofContactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scalono $count kontaktu z istniejącymi',
      many: 'Scalono $count kontaktów z istniejącymi',
      few: 'Scalono $count kontakty z istniejącymi',
      one: 'Scalono $count kontakt z istniejącym',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsKnown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kontaktu było już zapisanych',
      many: '$count kontaktów było już zapisanych',
      few: '$count kontakty były już zapisane',
      one: '$count kontakt był już zapisany',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pominięto $count kontaktu: brak poprawnego adresu',
      many: 'Pominięto $count kontaktów: brak poprawnego adresu',
      few: 'Pominięto $count kontakty: brak poprawnego adresu',
      one: 'Pominięto $count kontakt: brak poprawnego adresu',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactAddressesLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nie dodano $count adresu: konflikt z zapisanymi kontaktami',
      many: 'Nie dodano $count adresów: konflikt z zapisanymi kontaktami',
      few: 'Nie dodano $count adresów: konflikt z zapisanymi kontaktami',
      one: 'Nie dodano $count adresu: konflikt z zapisanym kontaktem',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofContactsUnreadable =>
      'Nie udało się odczytać części starych kontaktów: stara książka adresowa jest uszkodzona';

  @override
  String get deskErrProofContactsFailed =>
      'Nie wszystkie kontakty zostały zapisane: błąd zapisu książki adresowej';

  @override
  String get deskTxStatusSenderPosted => 'Nadawca zgłasza publikację';

  @override
  String get deskTxNowSenderPosted =>
      'Podpisana i odesłana. Według nadawcy opublikowana w sieci; zakończy się, gdy blockchain ją potwierdzi.';

  @override
  String get deskImpWrongTypePasted =>
      'Wklejony tekst nie jest transakcją. Wklej cały tekst od nadawcy albo wybierz jego plik.';

  @override
  String get pairTitle => 'Sparuj';

  @override
  String pairWithName(String name) {
    return 'Sparuj z: $name';
  }

  @override
  String get pairLead =>
      'Sparuj się raz z drugą osobą. Pliki płatności i faktury między dwoma portfelami są wtedy zapieczętowane: tylko te dwa portfele mogą je odczytać.';

  @override
  String get pairInPerson => 'Osobiście';

  @override
  String get pairInPersonHint => 'Pokaż swój kod i zeskanuj kod drugiej osoby';

  @override
  String get pairOnline => 'Online';

  @override
  String get pairOnlineHint =>
      'Wyślij link z zaproszeniem lub przeczytaj słowa parowania';

  @override
  String get pairOfflineHint =>
      'Jesteś offline. Zaproszenie i odpowiedź przekazuje się ręcznie.';

  @override
  String get pairEnter => 'Wpisz link lub słowa';

  @override
  String get pairEnterHint =>
      'Wklej link z zaproszeniem lub wpisz otrzymane słowa';

  @override
  String get pairNotPaired => 'Niesparowany';

  @override
  String get pairNotPairedHint =>
      'Sparuj, aby pieczętować pliki płatności i zezwalać na faktury.';

  @override
  String get pairInPersonTitle => 'Parowanie osobiście';

  @override
  String get pairShowMyCode => 'Pokaż mój kod';

  @override
  String get pairScanTheirs => 'Zeskanuj ich kod';

  @override
  String get pairShowCodeCaption =>
      'Daj zeskanować ten kod, potem zeskanuj kod drugiej osoby.';

  @override
  String get pairScanCaption =>
      'Skanujecie oboje. Sprawdzanie słów otworzy się, gdy oba kody zostaną odczytane.';

  @override
  String get pairScanPrompt => 'Skieruj aparat na kod drugiej osoby';

  @override
  String get pairSeenAs => 'Druga strona zobaczy cię jako';

  @override
  String get pairUseWords => 'Użyj słów';

  @override
  String get pairCameraDeniedTitle => 'Aparat jest niedozwolony';

  @override
  String get pairCameraDeniedBody =>
      'Zezwól na aparat, aby skanować, albo użyj słów.';

  @override
  String get pairOpenSettings => 'Otwórz ustawienia';

  @override
  String get pairWordsTitle => 'Słowa parowania';

  @override
  String get pairWordsLead =>
      'Przeczytaj je drugiej osobie w tej kolejności. Jej portfel znajdzie zaproszenie po słowach.';

  @override
  String get pairWordsGoodFor => 'Ważne przez 10 minut';

  @override
  String get pairWordsLastMinute => 'Została niecała minuta';

  @override
  String get pairWordsFooter =>
      'Każdy, kto zna te słowa, może odpowiedzieć na zaproszenie, dopóki nie wygaśnie. Potem sprawdźcie razem słowa.';

  @override
  String get pairWordsNew => 'Nowe słowa';

  @override
  String get pairWordsCopy => 'Kopiuj słowa';

  @override
  String get pairWordsExpiredTitle => 'Te słowa wygasły';

  @override
  String get pairWordsExpiredBody => 'Utwórz nowe i przeczytaj je ponownie.';

  @override
  String get pairWordsNeedEpicbox =>
      'Słowa parowania wymagają Epicbox, więc teraz nie są dostępne.';

  @override
  String pairWordsDesktopChip(String time) {
    return 'Słowa: zostało $time';
  }

  @override
  String get pairEnterLead =>
      'Wklej link z zaproszeniem lub wpisz pięć otrzymanych słów.';

  @override
  String get pairEnterField => 'Link z zaproszeniem lub słowa';

  @override
  String get pairEnterNotFound =>
      'Nie znaleziono zaproszenia dla tych słów. Sprawdź je lub poproś o nowe.';

  @override
  String get pairEnterTryAgain => 'Spróbuj ponownie';

  @override
  String get pairEnterDesktopHint =>
      'Wklejony link lub wpisane słowa działają jak skan w telefonie.';

  @override
  String get pairCardCopy => 'Kopiuj mój link parowania';

  @override
  String get pairCardHint =>
      'Osobiście bez aparatu: każdy portfel wkleja powyżej link parowania drugiego.';

  @override
  String pairCardBackTitle(String name) {
    return 'Teraz przekaż $name swój kod';
  }

  @override
  String pairCardBackBody(String name) {
    return 'Wklej ten link w portfelu $name w polu „Wpisz link lub słowa”. Potem sprawdźcie razem słowa.';
  }

  @override
  String get pairEnterDesktopPlaceholder =>
      'Wklej link z zaproszeniem lub wpisz pięć słów';

  @override
  String get pairOnlineTitle => 'Parowanie online';

  @override
  String get pairOnlineLead =>
      'Wyślij zaproszenie kanałem, którego już używacie. Parowanie kończy się, gdy portfel drugiej osoby je otworzy.';

  @override
  String get pairOnlineLeadByHand =>
      'Wyślij zaproszenie kanałem, którego już używacie. Odpowiedź wróci tą samą drogą: wklej ją w Wpisz link lub słowa.';

  @override
  String get pairExpiresIn => 'Zaproszenie wygasa za';

  @override
  String get pairExpiry1h => '1 godzina';

  @override
  String get pairExpiry24h => '24 godziny';

  @override
  String get pairExpiry7d => '7 dni';

  @override
  String get pairWhatTheyReceive => 'Co otrzyma druga osoba';

  @override
  String pairShareText(String name, String link, String date) {
    return '$name chce sparować z tobą portfele Epic Cash. Wygasa: $date.\n\nOtwórz w Epic Cash:\n$link';
  }

  @override
  String get pairShareWarning =>
      'Każdy, kto ma to zaproszenie, może się sparować jako ty, dopóki nie wygaśnie. Wyślij je tylko właściwej osobie, a potem sprawdźcie razem słowa.';

  @override
  String get pairShareInvite => 'Udostępnij zaproszenie';

  @override
  String get pairCopyInvite => 'Kopiuj zaproszenie';

  @override
  String get pairUseWordsShort => 'Użyj słów';

  @override
  String get pairInviteSentTitle => 'Zaproszenie wysłane';

  @override
  String pairInviteSentBody(String name) {
    return 'Parowanie kończy się, gdy portfel $name otworzy zaproszenie. Możesz opuścić ten ekran; zaproszenie zostaje w Kontakty › Oczekujące zaproszenia.';
  }

  @override
  String get pairCancelInvite => 'Anuluj zaproszenie';

  @override
  String pairCancelInviteTitle(String name) {
    return 'Anulować zaproszenie dla $name?';
  }

  @override
  String pairCancelInviteBody(String name) {
    return 'Jeśli drugi portfel otworzy je później, zobaczy „$name anulował(a) to zaproszenie”.';
  }

  @override
  String pairIncomingTitle(String name) {
    return 'Sparować z: $name?';
  }

  @override
  String get pairNameClaimed =>
      'Nazwa wybrana przez drugą stronę · jeszcze niesprawdzona';

  @override
  String get pairNameClaimedShort => 'Nazwa wybrana przez drugą stronę';

  @override
  String pairCallsThemselves(String name) {
    return 'Przedstawia się jako „$name”';
  }

  @override
  String pairIncomingBody(String name) {
    return 'Po sparowaniu pliki płatności i faktury między tobą a $name są zapieczętowane. Następnie sprawdzicie razem słowa.';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return 'Zezwól $name na prośby o płatność';
  }

  @override
  String get pairIncomingAllowHint =>
      'Włącza się po sprawdzeniu słów. Nic nie zostanie zapłacone bez twojego PIN-u.';

  @override
  String get pairNotNow => 'Nie teraz';

  @override
  String pairWaitingTitle(String name) {
    return 'Czekam na portfel $name…';
  }

  @override
  String get pairWaitingBody =>
      'Drugi portfel odpowie, gdy zostanie otwarty. Możesz to zamknąć; parowanie trwa w tle, a sprawdzanie słów pojawi się po jego zakończeniu.';

  @override
  String get pairSendByHand => 'Wyślij ręcznie';

  @override
  String get pairRelayUnreachableTitle => 'Brak połączenia z przekaźnikiem';

  @override
  String get pairRelayUnreachableBody => 'Wysłać odpowiedź ręcznie?';

  @override
  String get pairRelayUnreachableTor =>
      'Brak połączenia z przekaźnikiem przez Tor. Wysłać odpowiedź ręcznie?';

  @override
  String get pairByHandTitle => 'Wyślij ręcznie';

  @override
  String pairByHandLead(String name) {
    return 'Odeślij to do $name dowolnym kanałem. Portfel drugiej osoby dokończy parowanie, gdy to otworzy.';
  }

  @override
  String get pairByHandYourAnswer => 'Twoja odpowiedź';

  @override
  String pairByHandFooter(String name) {
    return 'Odpowiedź jest zapieczętowana dla zaproszenia od $name. Nikt inny jej nie odczyta i działa tylko raz.';
  }

  @override
  String pairConfirmByHandLead(String name) {
    return 'Odeślij to do $name. Portfel drugiej osoby pokaże sprawdzanie słów, gdy to otworzy.';
  }

  @override
  String get pairExpiredTitle => 'To zaproszenie wygasło';

  @override
  String pairExpiredBody(String name) {
    return 'Poproś $name o nowe.';
  }

  @override
  String get pairUsedTitle => 'To zaproszenie zostało już użyte';

  @override
  String get pairUsedBody => 'Poproś o nowe.';

  @override
  String pairCancelledTitle(String name) {
    return '$name: zaproszenie anulowane';
  }

  @override
  String get pairCancelledBody => 'Nic nie zostało zapisane.';

  @override
  String pairNoAnswerTitle(String name) {
    return 'Brak odpowiedzi od $name';
  }

  @override
  String get pairNoAnswerBody =>
      'Zaproszenie mogło zostać anulowane. Poproś o nowe lub sparuj się osobiście.';

  @override
  String get pairChangedTitle => 'To zaproszenie zostało zmienione po drodze';

  @override
  String pairChangedBody(String name) {
    return 'Nic nie zostało zapisane. Sparuj się ponownie, osobiście lub z nowym zaproszeniem od $name.';
  }

  @override
  String get pairNewerTitle => 'Zaktualizuj Epic Cash, aby to otworzyć';

  @override
  String get pairNewerInviteBody => 'To zaproszenie utworzył nowszy portfel.';

  @override
  String get pairNewerFileBody => 'Plik zapieczętował nowszy portfel.';

  @override
  String get pairCheckForUpdates => 'Sprawdź aktualizacje';

  @override
  String pairSecondReplyTitle(String name) {
    return 'Ktoś inny też odpowiedział na zaproszenie od $name. Zobacz Oczekujące zaproszenia.';
  }

  @override
  String get pairAnsweredSameInvite =>
      'Odpowiedź na to samo zaproszenie · niezapisana';

  @override
  String get sasTitle => 'Sprawdź słowa';

  @override
  String sasLead(String name) {
    return 'Portfel $name pokazuje te same cztery. Porównajcie je przez telefon lub osobiście.';
  }

  @override
  String sasLeadExchange(String name) {
    return 'Strona $name pokazuje te same cztery. Porównaj je, a potem potwierdź po obu stronach.';
  }

  @override
  String sasLeadRecheck(String name) {
    return 'Portfel $name pokazuje je w $name › Sprawdź słowa. Porównajcie je przez telefon lub osobiście.';
  }

  @override
  String get sasMatch => 'Zgadzają się';

  @override
  String get sasNoMatch => 'Nie zgadzają się';

  @override
  String get sasSkip => 'Pomiń na razie';

  @override
  String get sasLater => 'Później';

  @override
  String sasMatchedTitle(String name) {
    return '$name: zweryfikowano';
  }

  @override
  String sasMatchedBody(String name) {
    return 'Pliki płatności i faktury z $name są od teraz zapieczętowane.';
  }

  @override
  String get sasNoMatchTitle => 'Słowa się nie zgadzają';

  @override
  String get sasNoMatchBody =>
      'Ktoś mógł zmienić zaproszenie po drodze. Nic nie zostaje zachowane. Sparuj się ponownie, osobiście lub z nowym zaproszeniem.';

  @override
  String get sasStopPairing => 'Przerwij parowanie';

  @override
  String sasSkippedTitle(String name) {
    return 'Sparowano z: $name';
  }

  @override
  String sasSkippedBody(String name) {
    return 'Pliki płatności z $name są zapieczętowane. Sprawdź słowa na stronie kontaktu $name, gdy tylko możesz; faktury czekają do tego czasu.';
  }

  @override
  String get sasCheckNow => 'Sprawdź teraz';

  @override
  String get sasAllowAfterMatch =>
      'Włącza się, gdy potwierdzisz, że słowa się zgadzają.';

  @override
  String sasAllowInvoicesHint(String name) {
    return 'Portfel $name może prosić cię o zapłatę. Nic nie zostanie zapłacone bez twojego PIN-u.';
  }

  @override
  String get trustVerified => 'Zweryfikowany';

  @override
  String get trustPaired => 'Sparowany, niezweryfikowany';

  @override
  String get trustPairedShort => 'Sparowany';

  @override
  String get trustKeysChanged => 'Klucze zmienione';

  @override
  String get trustSealed => 'Zapieczętowane';

  @override
  String trustSealedFor(String name) {
    return 'Zapieczętowane dla $name';
  }

  @override
  String get trustAllowsInvoices => 'Faktury dozwolone';

  @override
  String get contactTitle => 'Kontakt';

  @override
  String get contactAddresses => 'Adresy';

  @override
  String get contactPairing => 'Parowanie';

  @override
  String contactWordsChecked(String date) {
    return 'Słowa sprawdzone $date';
  }

  @override
  String get contactCheckAgain => 'Sprawdź ponownie';

  @override
  String get contactCheckWordsAgain => 'Sprawdź słowa ponownie';

  @override
  String get contactSealPayments => 'Pieczętuj płatności';

  @override
  String contactSealInfo(String name) {
    return 'Płatności i faktury z $name są szyfrowane od końca do końca. Tylko portfel $name może je odczytać.';
  }

  @override
  String contactSealInfoMore(String name) {
    return 'Po wyłączeniu plik płatności dla $name jest jawny: każdy, kto go dostanie, może go odczytać. Wyłącz tylko wtedy, gdy portfel $name nie otwiera zapieczętowanych plików.';
  }

  @override
  String get contactAllowInvoices => 'Zezwól na faktury';

  @override
  String contactAllowInfo(String name) {
    return 'Portfel $name może wysyłać ci prośby o zapłatę. Każda czeka w Fakturach na twoją zgodę i PIN. Nic nie płaci się samo.';
  }

  @override
  String get contactAllowInfoMore =>
      'Zezwolić można tylko zweryfikowanemu kontaktowi: sprawdzenie słów wyklucza podmienione zaproszenie.';

  @override
  String get contactCheckWordsFirst => 'Najpierw sprawdź słowa';

  @override
  String get contactPausedUntilChecked => 'Wstrzymane do sprawdzenia słów';

  @override
  String contactDeliveredVia(String relay) {
    return 'Dostarczane przez $relay';
  }

  @override
  String contactRelayDownTitle(String name) {
    return 'Przekaźnik $name nie odpowiada';
  }

  @override
  String get contactRelayDownBody =>
      'Ponawianie. Prośby i płatności czekają, aż odpowie; nic nie przepada.';

  @override
  String get contactPausedEpicboxOff =>
      'Wstrzymane, gdy Epicbox jest wyłączony';

  @override
  String get contactPausedEpicboxOffBody =>
      'Zapieczętowane pliki nadal działają.';

  @override
  String get contactRemovePairing => 'Usuń parowanie';

  @override
  String contactRemovePairingTitle(String name) {
    return 'Usunąć parowanie z $name?';
  }

  @override
  String contactRemovePairingBody(String name) {
    return 'Zapieczętowane płatności i faktury od $name ustaną. Adresy zostają w twoich kontaktach.';
  }

  @override
  String get contactKeep => 'Zachowaj';

  @override
  String get contactRemove => 'Usuń';

  @override
  String contactKeysChangedTitle(String name) {
    return 'Klucze $name się zmieniły';
  }

  @override
  String get contactKeysChangedBody =>
      'Może to oznaczać, że ta osoba używa teraz innego portfela albo że ktoś inny używa jej nazwy. Sprawdź słowa ponownie.';

  @override
  String get contactKeysChangedStatus => 'pieczętowanie i faktury wstrzymane';

  @override
  String get contactKeysChangedPaused => 'Pieczętowanie i faktury wstrzymane';

  @override
  String get contactKeepOldKeys => 'Zachowaj stare klucze';

  @override
  String get contactUseNewKeys => 'Użyj nowych kluczy';

  @override
  String contactKeysBack(String name) {
    return 'Klucze $name wróciły.';
  }

  @override
  String get contactKeysBackBody => 'Dla ciebie nic się nie zmieniło.';

  @override
  String contactSealDegradedTitle(String name) {
    return 'Ostatnia płatność dla $name poszła jawnie';
  }

  @override
  String contactSealDegradedBody(String name) {
    return 'Następna zapyta: zapieczętować czy jawnie. Pieczętowanie włączy się samo, gdy portfel $name odpowie zapieczętowanym plikiem.';
  }

  @override
  String get addrField => 'Adres';

  @override
  String addrFieldTyped(String type) {
    return 'Adres ($type)';
  }

  @override
  String get addrAddAnother => 'Dodaj kolejny adres';

  @override
  String addrOneFree(String type) {
    return 'Wolny jest jeszcze jeden typ: $type.';
  }

  @override
  String addrDuplicateType(String name, String type) {
    return '$name ma już adres tego typu ($type).';
  }

  @override
  String get addrKeepOld => 'Zachowaj stary';

  @override
  String get addrReplace => 'Zastąp';

  @override
  String addrDesktopThird(String type) {
    return 'Wklej adres ($type) lub zostaw puste';
  }

  @override
  String get addrDesktopRule =>
      'Jeden adres na typ. Trzecie pole pojawia się tylko, gdy jakiś typ jest wolny.';

  @override
  String get pendingTitle => 'Oczekujące zaproszenia';

  @override
  String pendingRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zaproszenia czeka na odpowiedź',
      many: '$count zaproszeń czeka na odpowiedź',
      few: '$count zaproszenia czekają na odpowiedź',
      one: '$count zaproszenie czeka na odpowiedź',
    );
    return '$_temp0';
  }

  @override
  String pendingLink(String time) {
    return 'Link · wygasa za $time';
  }

  @override
  String pendingWords(String time) {
    return 'Słowa parowania · wygasają za $time';
  }

  @override
  String get pendingExpired => 'Wygasło';

  @override
  String get pendingInviteAgain => 'Zaproś ponownie';

  @override
  String pendingWaitingConfirm(String time) {
    return 'Czeka na potwierdzenie · $time';
  }

  @override
  String get pendingPairedCheck => 'Sparowany · sprawdź słowa';

  @override
  String get pendingEmpty =>
      'Brak oczekujących zaproszeń. Zaproszenie widać tutaj, dopóki drugi portfel na nie nie odpowie.';

  @override
  String get pendingShareAgain => 'Udostępnij ponownie';

  @override
  String get pendingShowWords => 'Pokaż słowa';

  @override
  String get pendingCopyLink => 'Kopiuj link';

  @override
  String get invSetTitle => 'Faktury';

  @override
  String get invSetLead =>
      'Sparowany kontakt, któremu zezwolisz, może wysyłać ci prośby o zapłatę. Każda czeka w Fakturach na twój PIN.';

  @override
  String get invSetPaired => 'Sparowane kontakty';

  @override
  String get invSetAllowed => 'Dozwolone';

  @override
  String get invSetOff => 'Wyłączone';

  @override
  String get invSetPairShop => 'Sparuj ze sklepem lub giełdą';

  @override
  String get invSetEmpty =>
      'Brak sparowanych kontaktów. Sparuj się ze sklepem, giełdą lub osobą, sprawdź słowa, a potem zezwól tutaj na ich faktury.';

  @override
  String get invSetPausedBody =>
      'Prośby czekają na przekaźniku i dotrą, gdy Epicbox znów będzie włączony.';

  @override
  String invSetSwitchedOff(String name) {
    return 'Faktury od $name są wyłączone.';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odrzucono $count otwartej prośby.',
      many: 'Odrzucono $count otwartych próśb.',
      few: 'Odrzucono $count otwarte prośby.',
      one: 'Odrzucono $count otwartą prośbę.',
    );
    return '$_temp0';
  }

  @override
  String get invSetTimeToPay => 'Czas na zapłatę';

  @override
  String invSetTimeToPayHint(int hours) {
    return '$hours godz. · tyle faktura pozostaje do zapłacenia';
  }

  @override
  String get invoicesEmptyAction => 'Sparowane kontakty';

  @override
  String get reqTitle => 'Sprawdź prośbę';

  @override
  String reqRequests(String name) {
    return '$name prosi o';
  }

  @override
  String reqSealedSigned(String name) {
    return 'Zapieczętowane dla tego portfela i podpisane przez $name';
  }

  @override
  String get reqReference => 'Numer referencyjny';

  @override
  String reqPaidWaiting(String name) {
    return 'Zapłacono. Czekam, aż $name opublikuje';
  }

  @override
  String get reqPaidWaitingBody =>
      'Twoja część jest skończona. Giełda finalizuje i publikuje; to zamknie się samo.';

  @override
  String get reqTlPaid => 'Zapłacono';

  @override
  String reqTlDelivered(String name) {
    return 'Dostarczono do przekaźnika $name';
  }

  @override
  String reqTlAnswerDelivered(String name) {
    return 'Odpowiedź dostarczona do przekaźnika $name';
  }

  @override
  String reqTlPosted(String name) {
    return 'Opublikowane przez $name';
  }

  @override
  String get reqTlPostedHint => 'Zwykle w ciągu kilku minut';

  @override
  String get reqTlConfirming => 'Potwierdzanie';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n z $total potwierdzeń';
  }

  @override
  String get reqTlConfirmed => 'Potwierdzone';

  @override
  String reqTlWaiting(String time) {
    return 'Czeka od $time';
  }

  @override
  String reqNotPostedTitle(String name) {
    return '$name jeszcze nie opublikował(a)';
  }

  @override
  String get reqNotPostedBody =>
      'Wyślij ponownie dostarcza tę samą płatność jeszcze raz. Nie da się jej zapłacić dwa razy.';

  @override
  String get reqSendAgain => 'Wyślij ponownie';

  @override
  String reqUnreachableTitle(String name) {
    return 'Brak kontaktu z $name';
  }

  @override
  String get reqUnreachableBody =>
      'Twoje środki są bezpieczne; zostaną odblokowane, jeśli płatność nie zostanie opublikowana. Dostarczanie jest ponawiane.';

  @override
  String get reqRelayRetrying => 'Przekaźnik nie odpowiada · ponawianie';

  @override
  String reqWithdrewTitle(String name) {
    return '$name wycofał(a) prośbę';
  }

  @override
  String get reqWithdrewBody =>
      'Twoje środki są odblokowane. Nic nie zostało zapłacone.';

  @override
  String reqWithdrewUnpaid(String name) {
    return '$name wycofał(a) tę prośbę';
  }

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name wysłał(a) w ciągu 10 minut $count prośby o $amount EPIC. Zapłacić wszystkie?',
      many:
          '$name wysłał(a) w ciągu 10 minut $count próśb o $amount EPIC. Zapłacić wszystkie?',
      few:
          '$name wysłał(a) w ciągu 10 minut $count prośby o $amount EPIC. Zapłacić wszystkie?',
      one:
          '$name wysłał(a) w ciągu 10 minut $count prośbę o $amount EPIC. Zapłacić?',
    );
    return '$_temp0';
  }

  @override
  String reqWithdrawalFrom(String name) {
    return 'Wypłata z: $name';
  }

  @override
  String reqReceivedWaiting(String name) {
    return 'Odebrano. Czekam, aż $name opublikuje';
  }

  @override
  String get reqReceivedWaitingBody =>
      'Nic nie musisz robić. Giełda publikuje płatność; potwierdzenia przyjdą później.';

  @override
  String get reqNewTitle => 'Nowa prośba';

  @override
  String get reqNewLead =>
      'Poproś sparowany kontakt o zapłatę lub zapisz prośbę jako plik dla kogokolwiek.';

  @override
  String get reqNewLeadContacts => 'Poproś sparowany kontakt o zapłatę.';

  @override
  String get reqNewTo => 'Do';

  @override
  String get reqNewToHintContacts =>
      'Sparowane kontakty, których portfel opłaca prośby.';

  @override
  String get reqNoPayersContacts =>
      'Żaden sparowany kontakt nie opłaca jeszcze próśb. Sparuj się i sprawdź słowa.';

  @override
  String get reqNewToHint =>
      'Sparowane kontakty, których portfel opłaca prośby. Dla innych: zapisz prośbę jako plik.';

  @override
  String get reqNewSaveFile => 'Zapisz jako plik';

  @override
  String get reqNewSend => 'Wyślij prośbę';

  @override
  String sendViaMailbox(String name) {
    return 'Wyślij przez skrzynkę $name';
  }

  @override
  String sendViaMailboxHint(String relay) {
    return 'Zapieczętowane. Dostarczane przez $relay';
  }

  @override
  String sendSealedTitle(String name) {
    return 'Zapieczętowane dla $name';
  }

  @override
  String sendSealedBody(String name) {
    return 'Tylko portfel $name może otworzyć ten plik. Wyślij go w dowolny sposób, a potem otwórz plik, który wróci.';
  }

  @override
  String get sendSealOrPlainTitle => 'Zapieczętować ten plik?';

  @override
  String sendSealOrPlainBody(String name) {
    return 'Ostatni plik dla $name poszedł jawnie. Zapieczętowanie jest znów domyślne.';
  }

  @override
  String get sendSealedOption => 'Zapieczętowany';

  @override
  String sendSealedOptionHint(String name) {
    return 'Tylko portfel $name może go odczytać';
  }

  @override
  String get sendPlainOption => 'Jawny';

  @override
  String get sendPlainOptionHint => 'Każdy, kto ma plik, może go odczytać';

  @override
  String sendCantOpenTitle(String name) {
    return '$name nie może otworzyć zapieczętowanych plików?';
  }

  @override
  String get sendCantOpenBody =>
      'Wyślij jawnie wysyła tę samą płatność ponownie, bez pieczęci. To nadal jedna płatność.';

  @override
  String get sendAsPlain => 'Wyślij jawnie';

  @override
  String get sendAsPlainTitle => 'Wysłać jawnie?';

  @override
  String get sendAsPlainBody =>
      'Plik nie zostanie zapieczętowany: każdy, kto go dostanie, odczyta kwotę i adresy. To ta sama płatność, więc nie da się jej zapłacić dwa razy.';

  @override
  String get sendKeepSealed => 'Zostaw zapieczętowany';

  @override
  String get sendPlain => 'Wyślij jawnie';

  @override
  String sendNotHeardTitle(String name) {
    return 'Brak wieści z portfela $name od 90 dni';
  }

  @override
  String sendNotHeardBody(String name) {
    return '$name będzie potrzebować Epic Cash, aby otworzyć ten plik.';
  }

  @override
  String get sendPlainShort => 'Wyślij jawnie';

  @override
  String get openSealedOtherTitle =>
      'To zapieczętowano dla innego portfela lub instalacji';

  @override
  String get openSealedOtherBody =>
      'Nie da się tego tutaj otworzyć. Poproś nadawcę o ponowne wysłanie.';

  @override
  String get openArrivedUnsealed => 'To dotarło bez pieczęci.';

  @override
  String openArrivedUnsealedBody(String name) {
    return '$name wysłał(a) ten plik jawnie.';
  }

  @override
  String noticePairingReplied(String name) {
    return '$name odpowiada na twoje zaproszenie. Sprawdźcie razem słowa.';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'Sparowano z: $name. Sprawdźcie razem słowa.';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name prosi o $amount EPIC. Sprawdź w Fakturach.';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return 'Odebrano $amount EPIC od $name. Czekam na publikację.';
  }

  @override
  String noticeKeysChanged(String name) {
    return 'Klucze $name się zmieniły. Sprawdź słowa ponownie przed zapłatą.';
  }

  @override
  String noticeRelayDown(String name) {
    return 'Przekaźnik $name nie odpowiada. Ponawianie.';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name wycofał(a) prośbę. Twoje środki są odblokowane.';
  }

  @override
  String get restoreUseContactsTitle => 'Używać kontaktów na tym urządzeniu?';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count parowania z tej kopii było używane na innym urządzeniu. Drugie urządzenie powinno przestać ich używać.',
      many:
          '$count parowań z tej kopii było używanych na innym urządzeniu. Drugie urządzenie powinno przestać ich używać.',
      few:
          '$count parowania z tej kopii były używane na innym urządzeniu. Drugie urządzenie powinno przestać ich używać.',
      one:
          '$count parowanie z tej kopii było używane na innym urządzeniu. Drugie urządzenie powinno przestać go używać.',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => 'Używaj tutaj';

  @override
  String restorePairingsOnOtherDevice(int count) {
    return '$count · na innym urządzeniu';
  }

  @override
  String get pairInviteSentBodyAnyone =>
      'Parowanie kończy się, gdy drugi portfel otworzy zaproszenie. Możesz opuścić ten ekran; zaproszenie zostaje w Kontakty › Oczekujące zaproszenia.';

  @override
  String get pairInvalidLink => 'To nie jest link do parowania';

  @override
  String get pairInvalidBody =>
      'Sprawdź, czy skopiowano cały link, lub poproś o nowy.';

  @override
  String get pairOwnCode => 'To twój własny kod';

  @override
  String get pairOwnCodeBody => 'Zeskanuj kod na drugim telefonie.';

  @override
  String get pairUnnamedInvite => 'Otwarte zaproszenie';

  @override
  String get pairSeenAsMissing => 'Wpisz nazwę, którą zobaczy druga strona.';

  @override
  String get pairSeenAsTooLong => 'Użyj krótszej nazwy.';

  @override
  String get pairSeenAsEdit => 'Zmień nazwę widoczną dla drugiej strony';

  @override
  String get pairCodeLabel => 'Twój kod parowania';

  @override
  String get pairWordsLabel => 'Twoje słowa parowania';

  @override
  String get pairWordsEnteredLabel => 'Wpisane słowa';

  @override
  String pairWordSlot(int n) {
    return 'Słowo $n, niewpisane';
  }

  @override
  String get pairSuggestions => 'Podpowiedzi';

  @override
  String get pairCopied => 'Skopiowano';

  @override
  String get pairPaste => 'Wklej';

  @override
  String get pairInPersonDone => 'Kody zeskanowane';

  @override
  String get pairEpicboxOffNotice =>
      'Wstrzymane, gdy Epicbox jest wyłączony. Zaproszenie i odpowiedź przekazuje się ręcznie.';

  @override
  String get pairWaitingTitleShort => 'Parowanie';

  @override
  String get pairClosed => 'Zamknij';

  @override
  String get sasWordsLabel => 'Cztery słowa';

  @override
  String sasDialogTitle(String name) {
    return 'Sprawdź słowa z $name';
  }

  @override
  String get contactMore => 'Więcej';

  @override
  String get contactEdit => 'Edytuj';

  @override
  String get contactDelete => 'Usuń kontakt';

  @override
  String contactCopyAddress(String type) {
    return 'Kopiuj adres ($type)';
  }

  @override
  String contactDeletePaired(String name) {
    return 'Usunięcie $name usuwa też parowanie. Zapieczętowane płatności i faktury od tego kontaktu ustaną.';
  }

  @override
  String get contactNoAddresses => 'Brak zapisanych adresów.';

  @override
  String addrRemove(String type) {
    return 'Usuń adres ($type)';
  }

  @override
  String get sendVia => 'Wyślij przez';

  @override
  String get invSetLeadDesktop =>
      'Sparowany kontakt, któremu zezwolisz, może wysyłać do tego portfela prośby o zapłatę. Każda czeka w Fakturach na hasło portfela.';

  @override
  String get invSetRowAllowed => 'Zweryfikowany · dozwolone';

  @override
  String get invSetRowOff => 'Zweryfikowany · wyłączone';

  @override
  String get invSetRowCheckFirst =>
      'Sparowany, niezweryfikowany · najpierw sprawdź słowa';

  @override
  String invSetAllowFor(String name) {
    return 'Zezwól na faktury od $name';
  }

  @override
  String get reqNoPayers =>
      'Żaden sparowany kontakt nie opłaca jeszcze próśb. Sparuj się i sprawdź słowa lub zapisz prośbę jako plik.';

  @override
  String get reqPickContact => 'Wybierz kontakt';

  @override
  String get reqFileSaved => 'Prośba zapisana jako plik';

  @override
  String reqSent(String name) {
    return 'Prośba wysłana do $name';
  }

  @override
  String get reqFileTitle => 'Prośba o płatność';

  @override
  String noticeOutboxStuck(String name) {
    return 'Brak kontaktu z $name. Twoje środki są bezpieczne.';
  }

  @override
  String noticeTooMany(String name) {
    return '$name wysyła za dużo próśb. Nadmiarowe zostały odrzucone. Wyłącz faktury od tego kontaktu, jeśli to się powtarza.';
  }

  @override
  String get noticeOpen => 'Otwórz';

  @override
  String get noticeCheckWords => 'Sprawdź słowa';

  @override
  String get noticeView => 'Pokaż';

  @override
  String get restorePairings => 'Parowania';

  @override
  String get pairingDesktopShowCodeLead =>
      'Daj zeskanować ten kod telefonem lub przeczytaj słowa parowania.';

  @override
  String get pairingDesktopInviteLead =>
      'Wyślij zaproszenie kanałem, którego już używacie. Parowanie kończy się, gdy portfel drugiej osoby je otworzy.';

  @override
  String get pairingInviteOnline => 'Zaproś online';

  @override
  String pairSaveContactTitle(String name) {
    return 'Zapisać $name w kontaktach?';
  }

  @override
  String get pairSaveNewContact => 'Zapisz jako nowy kontakt';

  @override
  String get pairAddToAContact => 'Dodaj do kontaktu';

  @override
  String pairSavedAs(String name) {
    return 'Zapisano jako $name.';
  }

  @override
  String pairDurDays(int days, int hours) {
    return '$days d $hours godz.';
  }

  @override
  String pairDurHours(int hours, int minutes) {
    return '$hours godz. $minutes min';
  }

  @override
  String pairDurMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get pairDurUnderMinute => 'mniej niż minuta';

  @override
  String get pairBack => 'Wstecz';

  @override
  String get pairNotInContacts => 'Nie ma w kontaktach';

  @override
  String get pairAddToContacts => 'Dodaj do kontaktów';

  @override
  String get helpPairingSection => 'Parowanie';

  @override
  String get helpPairingLede =>
      'Sparuj się raz; pliki płatności i faktury z tym kontaktem są zapieczętowane.';

  @override
  String get helpPairWhatTitle => 'Czym jest parowanie';

  @override
  String get helpPairWhatShort =>
      'Sparuj się raz z drugą osobą; potem pliki płatności i faktury między dwoma portfelami są zapieczętowane.';

  @override
  String get helpPairWhatP1 =>
      'Parowanie łączy dwa portfele jeden raz: osobiście, gdy skanujecie nawzajem swoje kody, lub online przez link z zaproszeniem albo pięć słów parowania. Każdy portfel trzyma klucz utworzony dla tego jednego kontaktu; nic z tego nie trafia na serwer Epicbox.';

  @override
  String get helpPairWhatP2 =>
      'Po sparowaniu plik płatności dla tego kontaktu jest **zapieczętowany**: tylko jego portfel może go otworzyć i po drodze nie da się go zmienić ani podrobić. Płatności przez Epicbox między osobami działają jak dotąd.';

  @override
  String get helpPairWhatStep1 =>
      'Otwórz [[Kontakty|Contacts]] i wybierz **Sparuj**.';

  @override
  String get helpPairWhatStep2 =>
      'Osobiście: pokaż swój kod, zeskanuj kod drugiej osoby. Online: wyślij zaproszenie lub przeczytaj słowa parowania.';

  @override
  String get helpPairWhatStep3 =>
      'Sprawdźcie razem słowa, potem **Zgadzają się**.';

  @override
  String get helpPairWhatP3 =>
      'Parowanie wymaga Epic Cash po obu stronach. Niesparowany kontakt nadal dostaje zwykłe pliki płatności i płatności Epicbox.';

  @override
  String get helpPairWhyTitle => 'Po co sprawdzać słowa';

  @override
  String get helpPairWhyShort =>
      'Cztery słowa dowodzą, że parowanie trafiło do właściwego portfela, a nie do kogoś pośrodku.';

  @override
  String get helpPairWhyP1 =>
      'Po sparowaniu oba portfele pokazują te same cztery obrazki z nazwami. Powstają z kluczy obu portfeli, więc parowanie zmienione po drodze pokaże na dwóch ekranach różne słowa.';

  @override
  String get helpPairWhyP2 =>
      'Porównajcie je przez telefon lub osobiście, a potem dotknij **Zgadzają się**. Kontakt staje się **Zweryfikowany**. **Pomiń na razie** zostawia go jako **Sparowany, niezweryfikowany**: pliki płatności są nadal zapieczętowane, ale kontakt nie może wysyłać faktur, dopóki słowa nie zostaną sprawdzone.';

  @override
  String get helpPairWhyP3 =>
      'Jeśli słowa się różnią, dotknij **Nie zgadzają się**. Parowanie zostaje odrzucone po tej stronie. Sparuj się ponownie, osobiście lub z nowym zaproszeniem.';

  @override
  String get helpPairWordsTitle => 'Słowa parowania';

  @override
  String get helpPairWordsShort =>
      'Pięć obrazków z nazwami zastępuje link, gdy nie ma czego zeskanować ani wkleić.';

  @override
  String get helpPairWordsP1 =>
      'Gdy jeden portfel nie ma aparatu albo zaproszenia nie da się wysłać jako linku, zapraszający portfel pokazuje pięć słów parowania. Druga osoba wpisuje ich nazwy w **Wpisz link lub słowa**; pole uzupełnia każdą nazwę po kilku literach. Słowa są ważne przez 10 minut.';

  @override
  String get helpPairWordsP2 =>
      'Słowa tylko odnajdują zaproszenie. Kto je zna, jest w tej samej sytuacji co ktoś, kto dostał link, więc jak zwykle sprawdźcie potem razem cztery słowa.';

  @override
  String get helpPairWordsP3 =>
      'Słowa parowania wymagają serwera Epicbox. Gdy Epicbox jest wyłączony, wyślij link z zaproszeniem.';

  @override
  String get helpPairInvTitle => 'Faktury od sparowanych kontaktów';

  @override
  String get helpPairInvShort =>
      'Tylko zweryfikowany kontakt, któremu zezwolisz, może prosić cię o zapłatę. Każda prośba czeka na twój PIN.';

  @override
  String get helpPairInvP1 =>
      'Sklep, giełda lub osoba, z którą jesteś sparowany, może wysyłać prośby o zapłatę, jeśli na to zezwolisz: **Zezwól na faktury** na stronie kontaktu lub w [[Ustawienia › Faktury|Settings › Invoices]]. Przełącznik działa tylko dla zweryfikowanego kontaktu.';

  @override
  String get helpPairInvP2 =>
      'Prośba pojawia się w [[Faktury › Zapłać|Invoices › Pay]] z nazwą kontaktu, kwotą i numerem referencyjnym. Nic nie zostanie zapłacone, dopóki nie zatwierdzisz jej PIN-em. Prośba nigdy nie dodaje pieniędzy do portfela.';

  @override
  String get helpPairInvP3 =>
      'Wyłączenie przełącznika działa od razu: nowe prośby od tego kontaktu przepadają, a otwarte zostają odrzucone.';

  @override
  String get helpPairInvP4 =>
      'Giełda sparowana z tobą tędy obsługuje wpłaty i wypłaty. Wpłata: giełda prosi, ty zatwierdzasz, giełda publikuje. Wypłata: giełda wysyła płatność, twój portfel sam odpowiada, giełda publikuje.';

  @override
  String get helpPairRestoreTitle => 'Co daje przywrócenie';

  @override
  String get helpPairRestoreShort =>
      'Przywrócenie z frazy odzyskiwania z kopią historii przywraca każde parowanie; bez niej ponowne parowanie odnajduje te same klucze.';

  @override
  String get helpPairRestoreP1 =>
      'Z kopią historii przywrócenie odtwarza każde parowanie bez zmian: te same klucze, te same oznaczenia Zweryfikowany, te same ustawienia. Kontakty niczego nie zauważą.';

  @override
  String get helpPairRestoreP2 =>
      'Bez kopii parowania znikają z tego portfela, ale klucze nie: powstają z frazy odzyskiwania. Sparuj się ponownie z kontaktem, który zachował parowanie, a jego portfel odnajdzie te same klucze. Pokaże, że klucze wróciły, a kontakt zachowa oznaczenie Zweryfikowany. W tym portfelu Pieczętuj płatności i Zezwól na faktury wracają do ustawień domyślnych.';

  @override
  String get helpPairRestoreP3 =>
      'Kontakt widzi **Klucze zmienione** tylko wtedy, gdy fraza jest inna. Może to oznaczać nowy portfel albo kogoś innego, kto używa tej nazwy. Sprawdź słowa ponownie, zanim temu zaufasz.';

  @override
  String get helpPairRestoreP4 =>
      'Używaj parowania na jednym urządzeniu naraz. Kopia przywrócona na drugim urządzeniu zapyta, zanim użyje tam kontaktów.';

  @override
  String get pairNameForCode =>
      'Wpisz nazwę, którą zobaczy druga strona, a tutaj pojawi się twój kod.';

  @override
  String get pairYourNamePlaceholder => 'Twoje imię';

  @override
  String get restoreDone => 'Historia przywrócona.';

  @override
  String restoreDoneBody(int payments, int contacts, int pairings) {
    return 'Wróciły płatności: $payments, kontakty: $contacts i parowania: $pairings.';
  }
}
