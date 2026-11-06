// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'BT Wallet';

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
  String get txRestoredFunds => 'Znaleziono w łańcuchu';

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
  String get txEditFromHelper => 'Niezweryfikowane. Tylko do Twoich zapisów.';

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
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
      many:
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
      few:
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
      one:
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'Moje';

  @override
  String get histConflictBackup => 'Plik';

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
  String get txStatusFromBackup => 'Zaimportowana';

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
    return 'Znaleziono w łańcuchu: $amount';
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
      'To nie jest plik danych portfela z tej aplikacji.';

  @override
  String get errorHistoryNewer =>
      'Ten plik danych portfela utworzono w nowszej wersji aplikacji.';

  @override
  String get errorHistoryDamaged => 'Ten plik danych portfela jest uszkodzony.';

  @override
  String get errorHistoryOtherWallet =>
      'Ten plik należy do innego portfela. Otworzy go tylko portfel przywrócony z tej samej frazy odzyskiwania.';

  @override
  String get errorHistoryOtherNetwork =>
      'Ten plik danych portfela pochodzi z innej sieci.';

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
    return 'Skanowanie łańcucha ($percent %)';
  }

  @override
  String get scanComplete => 'Skanowanie zakończone';

  @override
  String get scanResuming => 'Wznawianie skanowania';

  @override
  String get scanResumedNotice =>
      'Skanowanie było wstrzymane, gdy aplikacja działała w tle. Jest kontynuowane od miejsca, w którym się zatrzymało.';

  @override
  String get languageSetting => 'Język';

  @override
  String get languageSystem => 'Systemowy';

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
          'Płatność czeka już $days dnia. Serwer Epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować monety, a potem wyślij ponownie.',
      many:
          'Płatność czeka już $days dni. Serwer Epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować monety, a potem wyślij ponownie.',
      few:
          'Płatność czeka już $days dni. Serwer Epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować monety, a potem wyślij ponownie.',
      one:
          'Płatność czeka już $days dzień. Serwer Epicbox usuwa płatności po 7 dniach, więc tej nie da się już dokończyć. Anuluj ją, aby odblokować monety, a potem wyślij ponownie.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Wysłano przez Epicbox. Zakończy się, gdy portfel odbiorcy będzie online; do tego czasu lub do anulowania kwota pozostaje zablokowana.';

  @override
  String get txDetailsWaitingRecipient =>
      'Oczekiwanie na plik odpowiedzi odbiorcy. Kwota pozostaje zablokowana do tego czasu lub do anulowania.';

  @override
  String get txDetailsWaitingSender =>
      'Czeka, aż nadawca opublikuje ją w sieci.';

  @override
  String get txDetailsSenderPosted =>
      'Według nadawcy ta płatność została opublikowana w sieci. Zakończy się, gdy sieć ją potwierdzi.';

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
      'Anulowano. Nic nie zostało zapłacone, a środki są znów dostępne. Jeśli odbiorca już ją otrzymał, jego portfel może nadal pokazywać ją jako oczekującą.';

  @override
  String get txDetailsCancelledReleased =>
      'Sieć nie przyjęła tej płatności, więc jej środki zostały zwolnione. Przed ponownym wysłaniem sprawdź, czy odbiorca jej nie otrzymał.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Płatność nie trafiła do sieci na czas i została anulowana. Przed ponownym wysłaniem sprawdź, czy odbiorca jej nie otrzymał.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Odbiorca nie odpowiedział w ciągu 24 godzin, więc portfel anulował płatność. Nic nie zostało zapłacone, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Odbiorca odpowiedział po upływie 24 godzin, więc portfel anulował płatność, zamiast ją dokończyć. Nic nie zostało zapłacone, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Nie udało się dostarczyć płatności do odbiorcy, więc portfel od razu ją anulował. Nic nie zostało wysłane, a środki są znów dostępne.';

  @override
  String get txDetailsCancelledIncoming =>
      'Anulowano. Jeśli nadawca opublikuje płatność później, i tak dotrze.';

  @override
  String get txStatusSenderCancelled => 'Anulowana przez nadawcę';

  @override
  String get txDetailsSenderCancelledWaiting =>
      'Nadawca anulował tę płatność. Portfel usunie ją tutaj po sprawdzeniu sieci.';

  @override
  String get txDetailsSenderCancelled =>
      'Nadawca anulował tę płatność. Jeśli została wcześniej opublikowana, i tak dotrze.';

  @override
  String get txDetailsFromBackup =>
      'Ta płatność została zaimportowana z pliku danych portfela i nie była zakończona, gdy ten plik eksportowano. Ten portfel nie ma własnego zapisu tej płatności, więc nie wie, czy się zakończyła. Nic nie jest zablokowane.';

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
  String get txWaitNoNewBlock => 'Oczekiwanie na wykopanie kolejnego bloku.';

  @override
  String get txWaitNotInBlock =>
      'Jeszcze nie w bloku. Płatność może być wciąż w drodze do sieci.';

  @override
  String get txDetailsStuckBody =>
      'Sieć nie przyjęła tej płatności. Rozgłoś ją ponownie; nie może przejść dwa razy.';

  @override
  String get txDetailsBroadcastAgain => 'Rozgłoś ponownie';

  @override
  String get txDetailsBroadcastAgainDone => 'Rozgłoszono ponownie.';

  @override
  String get txDetailsRefusedBody =>
      'Ta płatność nie przeszła. Monety, które trzyma, można zwolnić.';

  @override
  String get txDetailsReleaseFunds => 'Zwolnij środki';

  @override
  String get txDetailsReleaseTitle => 'Zwolnić środki?';

  @override
  String get txDetailsReleaseBody =>
      'Ta płatność nie przeszła, ale wciąż może przejść później.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Czekaj dalej';

  @override
  String get txDetailsFundsReleased => 'Środki zwolnione';

  @override
  String get txDetailsCancelPayment => 'Anuluj płatność';

  @override
  String get txDetailsCancelTitle => 'Anulować tę płatność?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Nic jeszcze nie dotarło. Jeśli ta płatność dotrze później, pokaże się jako odebrana.';

  @override
  String get txDetailsCancelSendBody =>
      'Nic jeszcze nie zapłacono: anulowanie jest bez opłaty i pewne.';

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
  String get txDetailsNoteLabel => 'Prywatna notatka';

  @override
  String get txDetailsPrivateNoteLabel => 'Prywatna notatka';

  @override
  String get txDetailsMessageFromSender => 'Wiadomość';

  @override
  String get txDetailsMessageFromRecipient => 'Wiadomość od odbiorcy';

  @override
  String get txDetailsYourMessage => 'Wiadomość';

  @override
  String get txDetailsMessageHintToRecipient => 'Wysłana do odbiorcy';

  @override
  String get txDetailsMessageHintFromSender => 'Od nadawcy';

  @override
  String get txDetailsMessageHintFromRecipient => 'Od odbiorcy';

  @override
  String get txDetailsMessageHintToSender => 'Wysłana do nadawcy';

  @override
  String get txDetailsNoNote => 'Brak notatki';

  @override
  String get txDetailsAddNote => 'Dodaj notatkę';

  @override
  String get txDetailsEditNote => 'Edytuj notatkę';

  @override
  String get txDetailsNoteDialogTitle => 'Prywatna notatka';

  @override
  String get txDetailsNoteHelper =>
      'Tylko w tej aplikacji i w wyeksportowanych danych portfela.';

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
  String get txDetailsExplorerBehind =>
      'Eksplorator nie dotarł jeszcze do tego bloku.';

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
      'Znaleziono w łańcuchu. Nadawcy i opłaty nie ma w łańcuchu; zaimportuj dane portfela, aby je dodać.';

  @override
  String get txDetailsSourceImported =>
      'Zaimportowano z pliku danych portfela. Status nie został sprawdzony w łańcuchu.';

  @override
  String get historyTitle => 'Aktywność';

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
  String get historyBackupSaveDialogTitle => 'Zapisz dane portfela';

  @override
  String get importWarnTitle => 'Zanim zaimportujesz';

  @override
  String get importWarnEarly => 'To wczesna wersja nowej aplikacji.';

  @override
  String get importWarnReads =>
      'Import tylko odczytuje twoje stare portfele i pliki; nigdy ich nie usuwa ani nie zmienia.';

  @override
  String get importWarnBackup =>
      'Zanim przejdziesz dalej, upewnij się, że masz kopię zapasową każdego portfela: jego frazę odzyskiwania oraz pliki portfela, jeśli je przechowujesz.';

  @override
  String get importWarnRisk =>
      'Importujesz na własne ryzyko; nie bierzemy odpowiedzialności za żadne straty.';

  @override
  String get importWarnRiskPlain =>
      'Import odbywa się na własne ryzyko. Za straty nie przyjmuje się odpowiedzialności.';

  @override
  String get importWarnAck => 'Mam kopię zapasową każdego portfela';

  @override
  String get historyBackupOpenDialogTitle => 'Otwórz plik danych portfela';

  @override
  String get historyBackupFileTooLarge =>
      'Ten plik jest za duży, aby mógł być plikiem danych portfela.';

  @override
  String get historyBackupShare => 'Udostępnij';

  @override
  String get historyBackupShareSubtitle =>
      'Kopia poza telefonem, np. w chmurze lub na innym urządzeniu.';

  @override
  String get historyBackupSaveToDevice => 'Zapisz na urządzeniu';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Skopiuj go także poza ten telefon.';

  @override
  String historyBackupSaved(String fileName) {
    return 'Zapisano $fileName';
  }

  @override
  String get historyBackupExportTitle => 'Eksportuj dane portfela';

  @override
  String get historyBackupCsvTitle => 'Eksportuj CSV';

  @override
  String get historyBackupCsvWarning =>
      'Bez szyfrowania: każdy, kto ma plik, odczyta kwoty, daty, adresy i notatki. Nie da się go zaimportować; kopię zapasową zrobisz przez „Eksportuj dane portfela”.';

  @override
  String get historyBackupCsvConfirm => 'Eksportuj CSV';

  @override
  String get historyBackupImportedTitle => 'Zaimportowano dane portfela';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Nie zaimportowano danych portfela. $reason';
  }

  @override
  String get historyBackupImportNothingNew =>
      'Plik nie zawierał niczego nowego.';

  @override
  String get homeLockTooltip => 'Zablokuj portfel';

  @override
  String get shellTitle => 'BT Wallet';

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
  String get homeBackedUpNotice => 'Fraza odzyskiwania zabezpieczona';

  @override
  String get homeNoticeView => 'Pokaż';

  @override
  String get homeNoticeReceived => 'Płatność jest w drodze.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return '$who wysyła płatność.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount w drodze.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$who wysyła $amount.';
  }

  @override
  String get homeNoticeSenderPosted =>
      'Według nadawcy płatność została opublikowana.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Według nadawcy opublikowano $amount.';
  }

  @override
  String get homeNoticeFinished => 'Płatność sfinalizowana. Potwierdzanie.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Płatność do $who sfinalizowana. Potwierdzanie.';
  }

  @override
  String get homeNoticeDelayed => 'Brak połączenia z węzłem. Płatność czeka.';

  @override
  String get homeNoticeRelayProblem =>
      'Serwer epicbox zgłosił problem. Ponawianie próby.';

  @override
  String get homeNoticePaymentFailed => 'Płatność nie powiodła się.';

  @override
  String get homeBackupCardText => 'Fraza bez kopii';

  @override
  String get homeBackupCardButton => 'Zabezpiecz';

  @override
  String get homeBackupCardDismiss => 'Ukryj';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności nie ma w wyeksportowanych danych portfela.',
      many: '$count płatności nie ma w wyeksportowanych danych portfela.',
      few: '$count płatności nie ma w wyeksportowanych danych portfela.',
      one: '$count płatności nie ma w wyeksportowanych danych portfela.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności jest nowych lub zmienionych od ostatniego eksportu danych portfela.',
      many:
          '$count płatności jest nowych lub zmienionych od ostatniego eksportu danych portfela.',
      few:
          '$count płatności są nowe lub zmienione od ostatniego eksportu danych portfela.',
      one:
          '$count płatność jest nowa lub zmieniona od ostatniego eksportu danych portfela.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Nie teraz';

  @override
  String get homeHistoryExportButton => 'Eksportuj dane portfela';

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
  String balanceExactTip(String amount) {
    return 'Dokładna kwota: $amount';
  }

  @override
  String get homeShowBalances => 'Pokaż salda';

  @override
  String get homeHideBalances => 'Ukryj kwoty';

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
  String get homeBalanceImmature => 'Nagrody za kopanie';

  @override
  String get balanceImmatureHelp =>
      'Nagrody za kopanie czekają określoną liczbę bloków, zanim można je wydać.';

  @override
  String get balanceLineAllConfirmed => 'Wszystko potwierdzone';

  @override
  String get homeSyncSyncing => 'Synchronizacja…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'Synchronizacja… $percent %';
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
    return 'Synchronizacja węzła $percent %';
  }

  @override
  String percentValue(String percent) {
    return '$percent %';
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
  String get statusEpicboxBlocked => 'Epicbox zablokowany';

  @override
  String epicboxBlockedBody(String host) {
    return 'Ta sieć blokuje $host. Przyczyną może być filtr sieciowy. Spróbuj innego serwera Epicbox lub prywatnego DNS.';
  }

  @override
  String epicboxSwitchTo(String host) {
    return 'Przełącz na $host';
  }

  @override
  String get netStatusBlocked => 'Zablokowany';

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
  String get homeEpicboxConnecting => 'Łączenie z Epicbox…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Zsynchronizowano do bloku $height';
  }

  @override
  String contactsStaleOpened(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Ostatnio otwarto $days dnia temu. Sprawdzanie sparowanych kontaktów.',
      many:
          'Ostatnio otwarto $days dni temu. Sprawdzanie sparowanych kontaktów.',
      few:
          'Ostatnio otwarto $days dni temu. Sprawdzanie sparowanych kontaktów.',
      one:
          'Ostatnio otwarto $days dzień temu. Sprawdzanie sparowanych kontaktów.',
    );
    return '$_temp0';
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
  String get homeNoPayments => 'Brak płatności';

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
      'Żadne faktury nie czekają. Gdy sparowany kontakt, któremu zezwolisz, poprosi o zapłatę, faktura pojawi się tutaj i nic nie zostanie zapłacone bez twojej zgody.';

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
  String invoiceDetailsConfirmed(String service) {
    return 'Zapłacono. Sieć potwierdziła płatność dla $service.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return 'Serwis $service nie otrzymał jeszcze twojej płatności. „Ponów” wyśle ją jeszcze raz, bez ponownego zatwierdzania.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return 'Serwis $service wycofał tę fakturę po jej opłaceniu.';
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
      'Płacący zobaczy tę wiadomość razem z fakturą.';

  @override
  String get invoicesToPaySection => 'Do zapłaty';

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
  String get issuedWithdrawTitle => 'Wycofać tę fakturę?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer nie może już jej zapłacić. Nic nie zapłacono, więc żadne monety się nie przenoszą. Tego nie można cofnąć.';
  }

  @override
  String get issuedWithdrawKeep => 'Zostaw';

  @override
  String get issuedDetailsSection => 'Faktura';

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
      'Płacący odrzucił tę fakturę, więc została wycofana. Nic nie zapłacono.';

  @override
  String get issuedDetailsWithdrawn =>
      'Ta faktura została przez ciebie wycofana. Nic nie zapłacono.';

  @override
  String get issuedDetailsExpired =>
      'Ta faktura wygasła, zanim ją zapłacono. Nic nie zapłacono.';

  @override
  String get issuerNoticePaid => 'Jedna z twoich faktur została zapłacona.';

  @override
  String get issuerNoticeDeclined => 'Jedna z twoich faktur została odrzucona.';

  @override
  String get issuerNoticeWithdrawn =>
      'Faktura wycofana. Nie można jej już zapłacić.';

  @override
  String get issuerNoticeExpired =>
      'Jedna z twoich faktur wygasła bez zapłaty.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Portfel $payer nie obsługuje faktur i odesłał twoją, więc została wycofana. Poproś tę osobę, by zamiast tego wysłała ci płatność na twój adres lub jako plik transakcji.';
  }

  @override
  String get issuedBounced => 'Odesłana';

  @override
  String get issuedDetailsBounced =>
      'Portfel płacącego nie obsługuje faktur, więc nic nie zapłacono. Poproś tę osobę o wysłanie płatności na twój adres lub jako plik transakcji.';

  @override
  String get txStatusWaitingPayer => 'Czeka na płacącego';

  @override
  String get txStepRequested => 'Wysłano prośbę';

  @override
  String get txStepPaid => 'Opłacono';

  @override
  String get txDetailsWaitingPayer =>
      'Poproszono o tę płatność. Nic jeszcze nie dotarło: płatność przyjdzie, gdy płacący opłaci fakturę.';

  @override
  String get txDetailsRequestEnded =>
      'Ta faktura zakończyła się bez płatności. Nic nie dotarło.';

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
  String receiveEpicboxConnected(String server) {
    return 'Połączono · $server';
  }

  @override
  String get receiveQrLabel => 'Kod QR twojego adresu';

  @override
  String get receiveAddressLabel => 'Adres Epicbox';

  @override
  String get receiveEpicboxOfflineBody =>
      'Płatności czekają na serwerze Epicbox i dotrą, gdy portfel znów się połączy.';

  @override
  String get receiveShareCardHeadline => 'Zapłać mi w Epic Cash';

  @override
  String get receiveHelpButton => 'Jak działa odbieranie';

  @override
  String get receiveAddressCopied => 'Skopiowano adres';

  @override
  String get receiveFileTitle => 'Odbierz przez plik transakcji';

  @override
  String get receiveFileBody =>
      'Otwórz plik transakcji albo wklej tutaj jego tekst.';

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
    return 'Pobieranie wersji $version… $percent %';
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
      'Zezwól na instalacje z BT Wallet, a potem wróć.';

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
  String get updateManifestOtherApp =>
      'Informacje o aktualizacji dotyczą innej aplikacji.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'Pobieranie nie powiodło się (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge =>
      'Pobierany plik jest większy niż zapowiedziano.';

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
  String get setupWalletPerNetwork =>
      'Każda sieć ma własny portfel. W sieci, która go nie ma, zostanie utworzony nowy.';

  @override
  String get restoreTitle => 'Przywróć portfel';

  @override
  String get restorePhraseLabel => 'Fraza odzyskiwania';

  @override
  String get restorePhraseHelper =>
      'Wszystkie słowa (12, 15, 18, 21 lub 24) oddzielone spacjami.';

  @override
  String get restoreStartByMonth => 'Miesiąc';

  @override
  String get restoreStartByHeight => 'Wysokość bloku';

  @override
  String get restoreStartHeightLabel => 'Wysokość początkowa (opcjonalnie)';

  @override
  String get restoreStartHeightHelper =>
      'Skanuj od tego bloku. Zostaw puste, aby przeskanować cały łańcuch.';

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
      'Opcjonalnie. W razie wątpliwości wybierz wcześniejszą datę: późniejsza może pominąć część środków.';

  @override
  String restoreDateStart(String height) {
    return 'Skanowanie zacznie się dwa dni przed tą datą, od bloku $height.';
  }

  @override
  String get restorePickMonth => 'Wybierz miesiąc utworzenia portfela';

  @override
  String get restorePickMonthShort => 'Wybierz miesiąc';

  @override
  String restoreMonthStart(String height) {
    return 'Skanowanie zacznie się od bloku $height.';
  }

  @override
  String get restoreMonthRecent =>
      'Niedawny miesiąc: środki sprzed niego mogą zostać pominięte.';

  @override
  String get restoreMonthEarlierYear => 'Wcześniejszy rok';

  @override
  String get restoreMonthLaterYear => 'Późniejszy rok';

  @override
  String get restoreScanIntro =>
      'Wyszukiwanie środków w łańcuchu bloków. Nie zamykaj aplikacji, dopóki się nie zakończy.';

  @override
  String get restoreOpenWallet => 'Otwórz portfel';

  @override
  String get restoreUnfinishedTitle => 'Przywracanie nieukończone';

  @override
  String get restoreUnfinishedRunning =>
      'Wyszukiwanie środków tego portfela. Odbieranie i wysyłanie będą dostępne, gdy to się zakończy.';

  @override
  String get restoreUnfinishedOffline =>
      'Skanowanie będzie kontynuowane po wyłączeniu Offline.';

  @override
  String get restoreUnfinishedFailed =>
      'Skanowanie zatrzymało się i zostanie automatycznie powtórzone. Odbieranie i wysyłanie pozostają niedostępne, dopóki się nie zakończy.';

  @override
  String get errorRestoreScanRequired =>
      'Przywracanie nieukończone. Odbieranie i wysyłanie będą dostępne, gdy skanowanie widoczne na ekranie głównym się zakończy.';

  @override
  String get restoreScanStop => 'Zatrzymaj';

  @override
  String get restoreScanScreenOn =>
      'Ekran pozostaje włączony podczas skanowania.';

  @override
  String get restoreScanStopped =>
      'Zatrzymano. Odbieranie i wysyłanie będą dostępne dopiero po zakończeniu tego skanowania; będzie ono kontynuowane z ekranu głównego.';

  @override
  String get restoreScanUnfinished =>
      'Skanowanie zatrzymało się przed końcem. Odbieranie i wysyłanie będą dostępne dopiero po jego zakończeniu: spróbuj ponownie tutaj albo otwórz portfel, a będzie kontynuowane z ekranu głównego.';

  @override
  String get restoreFinishOnHome =>
      'Monety od wybranego początku zostały znalezione. Skanowanie od bloku 0 kończy teraz przywracanie na ekranie głównym; odbieranie i wysyłanie będą dostępne, gdy się zakończy.';

  @override
  String get unlockDatabaseRebuilt =>
      'Baza danych portfela była uszkodzona i została odbudowana z frazy. Skanowanie przywraca środki; szczegóły płatności, notatki i etykiety wracają tylko z pliku danych portfela.';

  @override
  String get restoreRebuiltImportText =>
      'Plik danych portfela przywraca historię płatności, kontakty, faktury i ustawienia.';

  @override
  String get restoreReplaceLead =>
      'Fraza przywraca portfel w miejsce portfela na tym telefonie. Nic się nie zmienia, zanim fraza nie zostanie sprawdzona, a zamiana potwierdzona.';

  @override
  String get restoreReplacePinReason =>
      'Wpisz PIN, aby zastąpić ten portfel. Przywrócony portfel zachowa ten PIN.';

  @override
  String restorePhraseUnknownWord(int position, String word) {
    return 'Słowo $position, „$word”, nie występuje na liście słów.';
  }

  @override
  String restorePhraseUnknownWords(String words) {
    return 'Nie ma na liście słów: $words.';
  }

  @override
  String restorePhraseWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ta fraza ma $count słowa. Fraza odzyskiwania ma 12, 15, 18, 21 lub 24 słowa.',
      many:
          'Ta fraza ma $count słów. Fraza odzyskiwania ma 12, 15, 18, 21 lub 24 słowa.',
      few:
          'Ta fraza ma $count słowa. Fraza odzyskiwania ma 12, 15, 18, 21 lub 24 słowa.',
      one:
          'Ta fraza ma $count słowo. Fraza odzyskiwania ma 12, 15, 18, 21 lub 24 słowa.',
    );
    return '$_temp0';
  }

  @override
  String get restorePhraseChecksum =>
      'Każde słowo jest na liście słów, ale fraza się nie zgadza. Jedno słowo jest błędne albo w złym miejscu.';

  @override
  String deleteFailedNotice(String error) {
    return 'Portfel nie został usunięty. $error Odblokuj go i spróbuj ponownie w Ustawieniach.';
  }

  @override
  String get restoreDoneIconLabel => 'Gotowe';

  @override
  String get restoreDoneTitle => 'Portfel przywrócony';

  @override
  String get restoreImportExplanation =>
      'Fraza odzyskiwania przywróciła saldo. Aby odzyskać historię, kontakty, faktury i ustawienia, zaimportuj wyeksportowany plik danych portfela.';

  @override
  String get restoreImportButton => 'Importuj dane portfela';

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
  String get firstRunCreate => 'Utwórz nowy portfel';

  @override
  String get firstRunRestore => 'Przywróć z frazy';

  @override
  String get settingsRestoreReplaces =>
      'Ten portfel zostanie usunięty, a jego miejsce zajmie portfel z wpisanej frazy, z tym samym PIN-em.';

  @override
  String get firstRunSecuring => 'Zabezpieczanie portfela…';

  @override
  String get workStoppingRecheck => 'Zatrzymywanie sprawdzania salda…';

  @override
  String get workTellingDevices => 'Powiadamianie połączonych urządzeń…';

  @override
  String get workRemovingFiles => 'Usuwanie plików portfela…';

  @override
  String get workClearingKeys => 'Usuwanie kluczy…';

  @override
  String get workChecking => 'Sprawdzanie…';

  @override
  String get workOpening => 'Otwieranie portfela…';

  @override
  String get workCreating => 'Tworzenie portfela…';

  @override
  String get workRestoring => 'Przywracanie portfela…';

  @override
  String get workStarting => 'Uruchamianie…';

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
      'Kto zobaczy te słowa lub ich zdjęcie, może zabrać środki.';

  @override
  String get backupConsentTitle => 'Zanim zobaczysz frazę';

  @override
  String get backupConsentWhat =>
      'Następny ekran pokazuje słowa, które przywracają ten portfel.';

  @override
  String get backupConsentReady => 'Przygotuj papier i długopis.';

  @override
  String get backupCopyAgree => 'Zachowam frazę tylko dla siebie';

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
          'Zapisz te $count słowa na papierze w podanej kolejności. Tylko za ich pomocą można przywrócić ten portfel.',
      many:
          'Zapisz te $count słów na papierze w podanej kolejności. Tylko za ich pomocą można przywrócić ten portfel.',
      few:
          'Zapisz te $count słowa na papierze w podanej kolejności. Tylko za ich pomocą można przywrócić ten portfel.',
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
  String get pinBiometricsQuestion => 'Odblokowywać biometrią?';

  @override
  String get pinBiometricsPinStillWorks => 'Kod PIN nadal działa.';

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
  String get scanQrTooltip => 'Zeskanuj kod QR';

  @override
  String get sendScanButton => 'Skanuj';

  @override
  String get sendChooseContactTooltip => 'Wybierz kontakt';

  @override
  String get sendContactsButton => 'Kontakty';

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
  String get scanPhraseFoundQr =>
      'Ten kod QR zawiera frazę odzyskiwania. Zachowaj ją w tajemnicy.';

  @override
  String get scanPhraseFoundPasted =>
      'To jest fraza odzyskiwania, więc nie została wklejona. Zachowaj ją w tajemnicy.';

  @override
  String get scanQrPhraseHint => 'Skieruj aparat na kod QR frazy odzyskiwania.';

  @override
  String get restoreScanNoPhrase =>
      'Ten kod QR nie zawiera frazy odzyskiwania.';

  @override
  String get scanQrCameraDenied =>
      'Dostęp do aparatu jest wyłączony. Zezwól na niego w ustawieniach telefonu lub wklej adres.';

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
  String get qrScanGot => 'Kod odczytany';

  @override
  String qrScanCount(int got, int count) {
    return '$got z $count';
  }

  @override
  String get qrScanCountLabel => 'Odczytane części';

  @override
  String get qrScanNotPayment =>
      'To nie jest kod QR płatności. Poproś drugą osobę, by pokazała kod QR płatności.';

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
      'Dostęp do aparatu jest wyłączony. Zezwól na niego w ustawieniach telefonu lub otwórz plik.';

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
  String get methodArtCaptionQr => 'Osobiście';

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
  String get receiveQrTitle => 'Stoisz obok drugiego telefonu?';

  @override
  String get receiveQrBody =>
      'Albo poproś o kwotę: pokaż kod QR do zeskanowania.';

  @override
  String get txQrHint =>
      'Płatność QR pokazuje płatność jako animowany kod, który drugi telefon skanuje aparatem, a odpowiedź przyjmuje w ten sam sposób. Działa tylko między telefonami obok siebie, nie wymaga połączenia między portfelami, a kod sam się ukrywa po 40 sekundach. Dodaje Płatność QR do Wyślij i Odbierz.';

  @override
  String get advTransactionFiles => 'Bezpośrednio · Przesyłanie pliku';

  @override
  String get advTransactionFilesHint =>
      'Dodaje Przesyłanie pliku w Ustawienia › Transakcje: płać lub dostawaj zapłatę plikiem, który przekazujesz sam.';

  @override
  String get sendMakeQr => 'Utwórz kod QR płatności';

  @override
  String sendQrPinReason(String amount) {
    return 'Wpisz PIN, aby utworzyć kod QR płatności na $amount.';
  }

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
  String get qrStatusHiddenAgain => 'Ukryty';

  @override
  String get qrStatusReplyHidden => 'Ukryty';

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
      'To nie jest prawidłowy adres. Użyj adresu Epicbox (es5x…@serwer), adresu Link (https://…) lub adresu onion (….onion).';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsSectionDisplay => 'Wygląd';

  @override
  String get settingsCurrency => 'Waluta';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Pokazuj ceny';

  @override
  String get settingsHideBalances => 'Ukryj kwoty';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get settingsThemeSystem => 'Systemowy';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsPricesOnNotice =>
      'Ceny pochodzą z serwisu CoinGecko, który widzi twój adres IP.';

  @override
  String get settingsSectionSecurity => 'Bezpieczeństwo';

  @override
  String get settingsChangePin => 'Zmień PIN';

  @override
  String get settingsBiometrics => 'Odblokowanie biometryczne';

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
  String get settingsSectionHistory => 'Dane portfela';

  @override
  String get settingsExportHistory => 'Eksportuj dane portfela';

  @override
  String get settingsExportCsv => 'Eksportuj CSV';

  @override
  String get settingsImportHistory => 'Importuj dane portfela';

  @override
  String get settingsSectionWallet => 'Ten portfel';

  @override
  String get settingsContacts => 'Kontakty';

  @override
  String get settingsInvoices => 'Faktury';

  @override
  String get settingsInvoicesSubtitle => 'Kto może prosić cię o zapłatę';

  @override
  String get settingsRescan => 'Sprawdź saldo';

  @override
  String get settingsRescanFinished => 'Saldo sprawdzone';

  @override
  String get settingsRescanTitle => 'Sprawdź saldo';

  @override
  String get settingsRescanBody =>
      'Ponownie sprawdza łańcuch pod kątem środków tego portfela.';

  @override
  String get settingsRescanButton => 'Sprawdź';

  @override
  String get settingsDeleteWallet => 'Usuń portfel';

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
      'Portfel, jego historia i PIN zostaną usunięte z tego telefonu. Tylko fraza odzyskiwania pozwoli odzyskać środki. Bez niej zostaną utracone na zawsze.';

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
  String settingsUpdatesFrom(String store) {
    return 'Aktualizacje dostarcza $store.';
  }

  @override
  String get settingsHelp => 'Pomoc';

  @override
  String get settingsSendFeedback => 'Zgłoś problem';

  @override
  String get settingsSendFeedbackHint =>
      'Zgłoś problem lub zaproponuj twórcom pomysł. Logi idą tylko wtedy, gdy je dołączysz; fraza odzyskiwania, PIN i inne poufne dane są wcześniej usuwane.';

  @override
  String get settingsSourceCode => 'Kod źródłowy';

  @override
  String get settingsPrivacyPolicy => 'Polityka prywatności';

  @override
  String get settingsLicences => 'Licencje';

  @override
  String get licencesLead =>
      'Oprogramowanie open source w tym portfelu, każde na własnej licencji.';

  @override
  String get licencesApp => 'BT Wallet od BT Labs: Apache-2.0.';

  @override
  String get licencesFlutter =>
      'Flutter i jego pakiety Dart: BSD 3-Clause i podobne liberalne licencje.';

  @override
  String get licencesLepic =>
      'LEPIC, biblioteka portfela Epic Cash: Apache-2.0, z forkiem secp256k1-zkp Epic Cash (CC0) i pakietami Rust na licencjach MIT lub Apache-2.0, m.in. tokio, rustls, rusqlite i blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, wersja 3. Źródło podano poniżej.';

  @override
  String get licencesFonts =>
      'Czcionki Montserrat, JetBrains Mono, Geist, Geist Mono i Noto Sans Thai: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'Wszystkie teksty licencji';

  @override
  String licencesPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licencji',
      many: '$count licencji',
      few: '$count licencje',
      one: '$count licencja',
    );
    return '$_temp0';
  }

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
  String get settingsPinNewLabel => 'Nowy PIN';

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
  String get helpSendFeedback => 'Zgłoś problem';

  @override
  String get feedbackTitle => 'Zgłoś problem';

  @override
  String get feedbackIntro => 'Opisz, co poszło nie tak lub co można poprawić.';

  @override
  String get feedbackMessageLabel => 'Co się stało';

  @override
  String get feedbackMessageMissing => 'Napisz kilka słów o tym, co się stało.';

  @override
  String get feedbackAttachLogs => 'Dołącz logi';

  @override
  String get feedbackAttachLogsHint =>
      'Najnowsza część logu aplikacji, bez frazy odzyskiwania, PIN-u i innych poufnych danych.';

  @override
  String get feedbackPreviewButton => 'Co zostanie wysłane';

  @override
  String get feedbackSend => 'Wyślij';

  @override
  String get feedbackShareOrSaveInstead => 'Udostępnij lub zapisz';

  @override
  String get feedbackFileExplanation =>
      'Opinia zostanie zapisana jako plik tekstowy, który możesz udostępnić albo zachować.';

  @override
  String get feedbackShareOrSave => 'Udostępnij lub zapisz';

  @override
  String get feedbackShareHint => 'Przekaż plik innej aplikacji';

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
  String get settingsSectionPrivacy => 'Prywatność';

  @override
  String get settingsSectionPrivacyNetwork => 'Prywatność i sieć';

  @override
  String get settingsSectionNetworkPrivacy => 'Sieć i prywatność';

  @override
  String get netSummaryTorOn => 'Tor włączony';

  @override
  String get netSummaryTorOff => 'Tor wyłączony';

  @override
  String get netPageServers => 'Serwery';

  @override
  String get settingsSectionHelpFeedback => 'Pomoc';

  @override
  String get settingsExperimentTag => 'Eksperyment';

  @override
  String get settingsStateBackUp => 'Zapisz frazę odzyskiwania';

  @override
  String get settingsStateNotBackedUp => 'Jeszcze nie zapisano';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String settingsUseStatusSite(String site) {
    return 'Używaj $site';
  }

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Pokazuje, które węzły i serwery Epicbox są online, z publicznej listy na status.btlabs.uk.';

  @override
  String get txStepStarted => 'Rozpoczęto płatność';

  @override
  String get txStepAccepted => 'Odbiorca podpisał';

  @override
  String get txStepPosted => 'Wysłano do sieci';

  @override
  String get txStepConfirming => 'Potwierdzanie';

  @override
  String get txStepConfirmed => 'Potwierdzona';

  @override
  String get txStepArrived => 'Płatność dotarła';

  @override
  String get txStepSenderFinished => 'Podpisana i odesłana';

  @override
  String get fileHelpTitle => 'Jak działa plik transakcji';

  @override
  String get fileHelpYou => 'Ty';

  @override
  String get fileHelpFriend => 'Znajomy';

  @override
  String get fileHelpSendStep1 => 'Tworzysz plik transakcji.';

  @override
  String get fileHelpSendStep2 =>
      'Wysyłasz go znajomemu w dowolny sposób, na przykład w komunikatorze lub na pendrivie.';

  @override
  String get fileHelpSendStep3 =>
      'Znajomy otwiera go w swoim portfelu i odsyła ci plik odpowiedzi.';

  @override
  String get fileHelpSendStep4 =>
      'Otwierasz plik odpowiedzi i płatność jest w drodze.';

  @override
  String get fileHelpReceiveStep1 =>
      'Znajomy tworzy dla ciebie plik transakcji.';

  @override
  String get fileHelpReceiveStep2 =>
      'Wysyła ci go w dowolny sposób, na przykład w komunikatorze lub na pendrivie.';

  @override
  String get fileHelpReceiveStep3 =>
      'Otwierasz go w swoim portfelu i odsyłasz plik odpowiedzi.';

  @override
  String get fileHelpReceiveStep4 =>
      'Znajomy otwiera plik odpowiedzi i płatność jest w drodze do ciebie.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Krok $step z $count';
  }

  @override
  String get fileHelpPause => 'Wstrzymaj animację';

  @override
  String get fileHelpPlay => 'Odtwórz animację';

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
  String get sendAddressMissing => 'Wpisz adres odbiorcy.';

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
  String get sendAddNote => 'Dodaj wiadomość';

  @override
  String get sendNoteLabel => 'Wiadomość';

  @override
  String get sendNoteHelper => 'Odbiorca ją zobaczy.';

  @override
  String get sendReviewMessageKept =>
      'Odbiorca ją zobaczy. Jej kopia zostaje jako Twoja prywatna notatka.';

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
    return 'Serwer Epicbox odbiorcy ($relay) nie odpowiada.';
  }

  @override
  String get sendListenerDown =>
      'Jeszcze bez połączenia. Możesz mimo to wysłać.';

  @override
  String get sendPayWithFile => 'Zapłać plikiem';

  @override
  String get sendAnyway => 'Wyślij mimo to';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Oczekiwanie na portfel: $name';
  }

  @override
  String get sendTrackWaiting => 'Oczekiwanie na portfel odbiorcy';

  @override
  String sendTrackOffline(String amount) {
    return 'Portfel odbiorcy podpisze ją po otwarciu. Do tego czasu $amount pozostaje zablokowane.';
  }

  @override
  String get sendTrackIfNot => 'A jeśli się nie zakończy?';

  @override
  String get sendTrackCancelled => 'Ta płatność została anulowana.';

  @override
  String get sendNoCoins => 'Nie masz jeszcze monet do wysłania.';

  @override
  String get sendFileTitle => 'Bezpośrednio · Przesyłanie pliku';

  @override
  String get sendMakeFile => 'Utwórz plik transakcji';

  @override
  String sendFileOnHold(String amount) {
    return '$amount zablokowane';
  }

  @override
  String get sendFileWaitingReply => 'Oczekiwanie na plik odpowiedzi';

  @override
  String get sendFileShareHint =>
      'Wyślij ten plik odbiorcy. Potem otwórz jego plik odpowiedzi.';

  @override
  String get sendOpenReply => 'Otwórz plik odpowiedzi';

  @override
  String get handshakeRequest => 'Faktura';

  @override
  String get handshakeYou => 'Ty';

  @override
  String get handshakeThem => 'Druga strona';

  @override
  String get handshakeNetwork => 'Sieć';

  @override
  String get handshakePay1 =>
      'Twój portfel wysyła płatność na serwer Epicbox. Monety zostają zablokowane.';

  @override
  String get handshakePay2 =>
      'Serwer przekazuje ją dalej. Portfel drugiej strony dodaje swoją część i podpisuje.';

  @override
  String get handshakeFinish => 'Twój portfel kończy ją i wysyła do sieci.';

  @override
  String get handshakeConfirm => 'Sieć ją potwierdza.';

  @override
  String get handshakeReq1 => 'Twój portfel wysyła fakturę na serwer Epicbox.';

  @override
  String get handshakeReq2 =>
      'Serwer przekazuje ją dalej. Druga strona ją akceptuje, a jej portfel dodaje monety i podpisuje.';

  @override
  String get handshakeRelay => 'Serwer Epicbox';

  @override
  String get handshakeFile => 'Przesyłanie pliku';

  @override
  String get handshakeBack =>
      'Portfel drugiej strony odsyła ją na serwer Epicbox.';

  @override
  String get handshakeRelayBack =>
      'Serwer przekazuje ją z powrotem do twojego portfela.';

  @override
  String get handshakeFile1 =>
      'Twój portfel zapisuje plik transakcji. Przekazujesz go drugiej stronie samodzielnie.';

  @override
  String get handshakeFile2 =>
      'Druga strona go otwiera. Jej portfel dodaje swoją część, podpisuje i zapisuje plik odpowiedzi.';

  @override
  String get handshakeFile3 => 'Druga strona odsyła ci plik odpowiedzi.';

  @override
  String get handshakeFile4 => 'Otwierasz plik odpowiedzi w swoim portfelu.';

  @override
  String get handshakePrevious => 'Poprzedni krok';

  @override
  String get handshakeLink1 =>
      'Twój portfel wysyła płatność prosto do portfela drugiej strony, przez internet lub Tor. Monety zostają zablokowane.';

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
          'Serwer Epicbox odbiorcy ($relay) ją odrzucił. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dnia.',
      many:
          'Serwer Epicbox odbiorcy ($relay) ją odrzucił. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dni.',
      few:
          'Serwer Epicbox odbiorcy ($relay) ją odrzucił. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dni.',
      one:
          'Serwer Epicbox odbiorcy ($relay) ją odrzucił. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dzień.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Serwer Epicbox odbiorcy ($relay) ją odrzucił. Sprawdź Portfel przed ponownym wysłaniem.';
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
    return '$amount zablokowane';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount w drodze';
  }

  @override
  String get receiveTorAddressLabel => 'Adres Link · Tor';

  @override
  String get receiveTorQrLabel => 'Kod QR twojego adresu Tor';

  @override
  String get torStateOff => 'Odbieranie przez Tor jest wyłączone';

  @override
  String torStateStarting(int percent) {
    return 'Łączenie z Tor… $percent %';
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
      'Tor nie mógł się połączyć. Ponów albo wyłącz Tor.';

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
  String get sendTorReady => 'Gotowe do wysłania przez Tor';

  @override
  String get sendTorReaching =>
      'Łączenie z portfelem odbiorcy przez Tor… Nie zamykaj aplikacji.';

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
  String get sendTorTryEpicbox =>
      'Epicbox dostarcza płatność także wtedy, gdy portfel odbiorcy jest offline.';

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Nic nie zostało wysłane.';
  }

  @override
  String get sendTryAgain => 'Spróbuj ponownie';

  @override
  String get sendCancelPayment => 'Anuluj płatność';

  @override
  String get homeAvailableToSpend => 'Do wydania';

  @override
  String get homeTileWaitingSender => 'Czeka na nadawcę';

  @override
  String get homeTileLocked => 'Zablokowane w wysyłkach';

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
  String get tourPhoneSkip => 'Pomiń przewodnik';

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
      'Wklej lub zeskanuj adres albo wybierz kontakt. Epicbox płaci na adres; QR pokazuje kod telefonowi obok ciebie. Więcej metod: Ustawienia › Transakcje. Najpierw jest podgląd.';

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
  String get tourPhoneInvoicesTitle => 'Faktury';

  @override
  String get tourPhoneInvoicesText =>
      'Zapłać fakturę, którą ktoś przysłał, albo poproś kogoś o płatność. Karty przełączają między jednym a drugim.';

  @override
  String get tourPhoneDevicesText =>
      'Ten portfel na drugim urządzeniu: każde pokazuje płatności drugiego. Eksperyment.';

  @override
  String get tourPhonePrivacyTitle => 'Prywatność i sieć';

  @override
  String get tourPhonePrivacyText =>
      'Z jakiego węzła i serwera Epicbox korzysta portfel oraz przełącznik Tora. Dotknij serwera, aby go zmienić.';

  @override
  String get tourPhoneNetworkText =>
      'Tryb sieci, przełącznik Tora i serwery, z których korzysta portfel. Dotknij serwera, aby go zmienić.';

  @override
  String get tourPhoneNetworkTextNoTor =>
      'Tryb sieci i serwery, z których korzysta portfel. Dotknij serwera, aby go zmienić.';

  @override
  String get tourPhoneAdvancedTitle => 'Zaawansowane';

  @override
  String get tourPhoneAdvancedText =>
      'Tryb tylko Tor, wyjścia i szczegóły techniczne są tutaj. Włącz to, czego potrzebujesz.';

  @override
  String get tourAdvancedShowsText =>
      'Wyjścia i szczegóły techniczne są tutaj. Włącz to, czego potrzebujesz.';

  @override
  String get tourPhoneHelpTitle => 'Pomoc';

  @override
  String get tourPhoneHelpText =>
      'Tematy pomocy, Zgłoś problem i Pokaż przewodnik ponownie.';

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
    return 'Wpisz PIN, aby utworzyć plik transakcji na $amount.';
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
  String outputsWaitLocked(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '$blocks potwierdzenie',
    );
    return 'Poczekaj, aż trwająca płatność będzie miała $_temp0.';
  }

  @override
  String get outputsStrategy => 'Strategia wysyłek';

  @override
  String get outputsStrategyHint =>
      'Które wyjścia wydaje wysyłka. Najmniejsze wydaje najmniejsze wyjścia, które pokrywają kwotę; Wszystkie wydaje każde wyjście i zwraca jedno.';

  @override
  String get outputsSmallest => 'Najmniejsze';

  @override
  String get outputsAll => 'Wszystkie';

  @override
  String get outputsSmallestText =>
      'Wydaje najmniejsze wyjścia, które pokrywają kwotę; reszta zostaje do wydania.';

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
  String get outputsWordFinalizing => 'Czeka na odpowiedź';

  @override
  String get outputsWordImmature => 'Dojrzewa';

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
  String get outputsEmptyHint => 'Pierwsza otrzymana płatność utworzy jedno.';

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
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks bloku',
      many: '$blocks blokach',
      few: '$blocks blokach',
      one: '$blocks bloku',
    );
    return 'Wydaje $spent ($amount) i tworzy $made po około $each. Zwykła transakcja sieciowa do tego portfela, potwierdzona po $_temp0 jak każda wysyłka; wszystko do wydania jest do tego czasu zablokowane. Więcej wyjść pozwala następnym wysyłkom wyjść bez czekania na resztę z poprzednich.';
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
  String outputsFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks bloku',
      many: '$blocks bloków',
      few: '$blocks bloków',
      one: '$blocks bloku',
    );
    return '$amount, około $_temp0';
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
  String outputsConsolidateText(
    String amount,
    String result,
    String spent,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '$blocks potwierdzenie',
    );
    return 'Wydaje $spent ($amount) i tworzy jedno wyjście na $result. Wszystko do wydania jest zablokowane na $_temp0.';
  }

  @override
  String get outputsConsolidateAction => 'Scal';

  @override
  String get outputsSplitPin => 'Potwierdź PIN-em, aby podzielić wyjścia';

  @override
  String get outputsConsolidatePin => 'Potwierdź PIN-em, aby scalić wyjścia';

  @override
  String outputsSplitStarted(int count, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks bloku',
      many: '$blocks bloków',
      few: '$blocks bloków',
      one: '$blocks bloku',
    );
    return 'Podział rozpoczęty, nowe wyjścia: $count; potwierdzenie za około $_temp0';
  }

  @override
  String outputsConsolidateStarted(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks bloku',
      many: '$blocks bloków',
      few: '$blocks bloków',
      one: '$blocks bloku',
    );
    return 'Scalanie rozpoczęte: jedno wyjście, potwierdzenie za około $_temp0';
  }

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
  String get contactTakesNoPayments => 'Nie przyjmuje płatności';

  @override
  String get contactNoPayments => 'Bez płatności';

  @override
  String contactNoPaymentsNamed(String name) {
    return '$name nie przyjmuje płatności.';
  }

  @override
  String get linkNoPaymentsTitle => 'Nie przyjmuje płatności';

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
  String get invoicesNewRequest => 'Nowa faktura';

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
  String get invoicesSentEmpty => 'Brak wysłanych faktur';

  @override
  String get invoicesSentEmptyCaption =>
      'Fakturą prosisz kogoś, by zapłacił ci określoną kwotę.';

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
  String get invoicesNodeOk => 'Zsynchronizowany';

  @override
  String get invoicesNodeDown => 'Nie odpowiada';

  @override
  String get invoicesEpicboxOk => 'Połączono';

  @override
  String get invoicesEpicboxDown => 'Brak połączenia';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer otrzyma fakturę $amount. Faktura wygasa za 24 h.';
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
    return 'Synchronizacja $percent %';
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
  String get netStatusOff => 'Wyłączony';

  @override
  String get netStatusConnected => 'Połączono';

  @override
  String get netStatusNotConnected => 'Brak połączenia';

  @override
  String get stateReceiving => 'Odbiera';

  @override
  String get stateUnchecked => 'Nie sprawdzono';

  @override
  String get serverUpNotConnected => 'Serwer działa · brak połączenia';

  @override
  String get netStatusOn => 'Włączony';

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
  String get netStatusDirectOpenHint => 'Otwiera adres odbioru Link';

  @override
  String get netStatusOpenHint => 'Pokazuje serwery';

  @override
  String get serverNodeTitle => 'Węzeł';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String serverTestFailed(String error) {
    return 'Brak odpowiedzi. $error';
  }

  @override
  String serverHealthUnknown(String site) {
    return '$site nieosiągalny; stan nieznany';
  }

  @override
  String get serverAtTip => 'zsynchronizowany';

  @override
  String serverBehindShort(String count) {
    return '$count w tyle';
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
  String get serverLocalNotReachable => 'Nieosiągalny z tego komputera';

  @override
  String get serverLocalNotReachablePhone => 'Nieosiągalny z tego telefonu';

  @override
  String get serverHealthy => 'Sprawny';

  @override
  String get serverDegraded => 'Opóźniony';

  @override
  String get serverHealthNone => 'Stan nieznany';

  @override
  String get serverCurrent => 'W użyciu';

  @override
  String get serverDefault => 'Domyślny';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % dostępności';
  }

  @override
  String get serverAdd => 'Dodaj';

  @override
  String get serverAlreadyInUse => 'Już używany.';

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
    return '$height · zsynchronizowany';
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
  String serverCheckedAt(String time, String site) {
    return '$site, sprawdzono $time';
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
  String get methodArtCaptionFile => 'Plik tam, odpowiedź z powrotem';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: płatność trafia na serwer Epicbox, który trzyma ją, aż portfel odbiorcy wróci';

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
  String get methodSendFileTitle => 'Bez połączenia.';

  @override
  String get methodSendFileLine =>
      'Przekaż plik, odbierz plik odpowiedzi, potem otwórz go tutaj.';

  @override
  String get methodReceiveEpicboxTitle => 'Udostępnij go, aby dostać płatność.';

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
  String get sendSwitchedEpicbox => 'Przez Epicbox';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Adres Epicbox. Ustawiono metodę Epicbox.';

  @override
  String get sendCancelRuleEpicbox =>
      'Można anulować, dopóki czeka na odbiorcę.';

  @override
  String get sendCancelRuleDirect =>
      'Nie można anulować, gdy portfel odbiorcy ją przyjmie.';

  @override
  String get sendCancelRuleFile =>
      'Można anulować, dopóki nie otworzysz pliku odpowiedzi.';

  @override
  String get sendHttpReaching =>
      'Łączenie z portfelem odbiorcy… Nie zamykaj aplikacji.';

  @override
  String get sendDeliveredWaitingBlock => 'Dostarczono · Czeka na blok';

  @override
  String get sendPlainHttpOffWithTor =>
      'Zwykłe http:// nie działa przy włączonym Torze.';

  @override
  String get sendPlainHttpOffWithTorWhy =>
      'Użyj adresu https:// lub onion albo Epicbox.';

  @override
  String get receiveTorCaption =>
      'Niektóre portfele pokazują adres bez .onion; to ten sam adres.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dnia.',
      many:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dni.',
      few:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dni.',
      one:
          'Nie udało się połączyć z portfelem odbiorcy. Kwota pozostaje zablokowana, dopóki jej nie anulujesz, najwyżej $days dzień.',
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
      'Listy pokazują to, co dotarło wcześniej; portfel ponowi próbę.';

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
  String get deskInvPayNotDelivered => 'Nie dostarczono';

  @override
  String get deskInvPayDelivered => 'Czeka na publikację';

  @override
  String deskInvPayPosted(String name) {
    return 'Opublikowane przez $name';
  }

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
    return '$used / $max bajtów';
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
    return '$payer nie może już jej zapłacić. Nic nie zapłacono, więc żadne monety się nie przenoszą.';
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
    return 'Portfel płacącego ($payer) nie może płacić faktur; poproś o przesłanie płatności.';
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
    return 'Dostarczono przez Epicbox. Nic nie jest zapłacone, dopóki $payer tego nie zatwierdzi.';
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
      'Nadeszła płatność za rachunek, którego to urządzenie nie wystawiło. Przez dobę czeka na serwerze na Twoje drugie urządzenie z tym portfelem: otwórz tam portfel, aby ją dokończyć.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Nadeszła odpowiedź na płatność, której to urządzenie nie wysłało. Przez dobę czeka na serwerze na Twoje drugie urządzenie z tym portfelem: otwórz tam portfel, aby ją dokończyć.';

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
      'Tu pojawiają się faktury od dozwolonych sparowanych kontaktów; nic nie zostanie zapłacone bez zatwierdzenia.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Twoja płatność dla: $service nie została dostarczona';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Jest podpisana i zapisana na tym komputerze; EPIC pozostają zablokowane. Ponów wysyła ją jeszcze raz bez ponownego zatwierdzania.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return 'Serwis $service wycofał opłaconą fakturę';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'Płatność może nigdy nie trafić do łańcucha. Anuluj ją, aby uwolnić monety.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Twojej płatności dla: $service nie ma w łańcuchu';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Jej czas minął, a sieć jej nie widziała. Anuluj ją, aby uwolnić monety.';

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
  String deskInvPayerShortText(
    String total,
    String spendable,
    int confirmations,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'po $confirmations potwierdzenia',
      many: 'po $confirmations potwierdzeniach',
      few: 'po $confirmations potwierdzeniach',
      one: 'po 1 potwierdzeniu',
    );
    return 'Potrzebujesz $total EPIC dostępnych; masz $spendable EPIC. Środki w trakcie potwierdzania liczą się $_temp0.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Węzeł nie odpowiada';

  @override
  String get deskInvPayerNodeDownText =>
      'Portfel nie może sprawdzić środków, więc nie może zapłacić. Zatwierdzanie zadziała, gdy węzeł odpowie; inny węzeł wybierzesz w Ustawienia › Węzeł.';

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
      'Serwer Epicbox nie odpowiada. Ponów w Faktury › Zapłać; bez ponownego zatwierdzania.';

  @override
  String get deskInvPayerRetryFailed => 'Nadal nie dostarczono';

  @override
  String get deskInvPayerRetryFailedText =>
      'Serwer Epicbox nie odpowiada. Płatność pozostaje podpisana na tym urządzeniu.';

  @override
  String get deskInvPayerCancelTitle => 'Anulować tę płatność?';

  @override
  String get deskInvPayerCancelText =>
      'Druga strona wciąż może dokończyć tę płatność.';

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
  String get deskInvPayerSpentText => 'Monety wracają do tego portfela.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Monet nie udało się jeszcze przenieść z powrotem. Portfel ponawia próbę, dopóki jest otwarty; do tego czasu płatność wciąż może przejść.';

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
      'Poproś sparowany kontakt o zapłatę lub zapisz fakturę jako plik.';

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
  String get sendAvailableWhileConfirms => 'Dostępne do potwierdzenia';

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
  String methodDirectShape(String port) {
    return 'http://host:$port lub xxxx….onion';
  }

  @override
  String get methodSendDirectLine =>
      'Portfel odbiorcy musi być otwarty. Adres onion działa przez Tor.';

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
  String get methodReceiveEpicboxShort =>
      'Udostępnij adres, aby dostać płatność.';

  @override
  String get methodReceiveEpicboxMore =>
      'Serwer Epicbox przechowuje płatność, dopóki ten portfel nie zostanie otwarty.';

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
  String get torNotOverTor => 'Bez Tora';

  @override
  String get torNeeds => 'Link · Tor wymaga Tora.';

  @override
  String get torTurnOn => 'Włącz Tor';

  @override
  String get torTurnOff => 'Wyłącz Tor';

  @override
  String get torTurnOffCaption =>
      'Dotyczy każdego połączenia, nie tylko tej płatności.';

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
      'Ruch sieciowy przechodzi przez sieć Tor. Aby przyjmować płatności na adres Tor, włącz Link · Tor w Ustawienia › Transakcje.';

  @override
  String get receiveTabDirect => 'Link';

  @override
  String get receiveDirectNeedsTor => 'Link · Tor wymaga Tora.';

  @override
  String get receiveDirectMeanwhile =>
      'Do tego czasu udostępnij adres Epicbox.';

  @override
  String get receiveHttpShowQr => 'Pokaż QR';

  @override
  String get receiveHttpHideQr => 'Ukryj QR';

  @override
  String get netStatusOverTor => 'przez Tor';

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
      'Portfel odbiorcy jest nieosiągalny przez Tor. Epicbox dostarcza płatność także wtedy, gdy portfel jest offline';

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
      'To portfel testowy i nie można go zaimportować.';

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
  String get deskErrProofSeedRead => 'Odczytano frazę odzyskiwania';

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
      'Historia jest w starszym formacie bazy danych i nie da się jej odczytać; skanowanie przywraca saldo';

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
    return 'Łączenie z Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'Dane innego portfela';

  @override
  String get deskErrHistOtherChain => 'Niewłaściwa sieć';

  @override
  String get deskErrHistNotOurs => 'To nie jest plik danych portfela';

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
  String get deskErrHistChains => 'Plik pochodzi z innej sieci.';

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
  String get deskErrHistNotOursText => 'Tego pliku nie utworzył BT Wallet.';

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
    return 'Błąd serwera aktualizacji ($status).';
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
  String get deskNodeAtTip => 'zsynchronizowany';

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
  String get deskNodeStartIt => 'Uruchom go w Ustawienia › Węzeł.';

  @override
  String deskNodeFailPort(String port) {
    return 'port $port zajmuje inny program';
  }

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
  String get deskNodeStageKernels => 'sprawdzanie łańcucha';

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
    return 'Sprawdzanie łańcucha · $done z $total mln';
  }

  @override
  String get deskNodeLineKernelsBare => 'Sprawdzanie łańcucha';

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
  String get deskTorNetworkHint => 'Ruch sieciowy przechodzi przez sieć Tor.';

  @override
  String get deskTorOff => 'Wyłączony';

  @override
  String get deskTorStarting => 'Uruchamianie…';

  @override
  String get deskTorOn => 'Włączony';

  @override
  String get deskTorNotConnected => 'Brak połączenia';

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
  String get deskRecvTorDownText =>
      'Tor nie mógł się połączyć. Ponów albo wyłącz Tor.';

  @override
  String get deskRecvTorStartingText =>
      'Adresy będą osiągalne, gdy Tor się połączy.';

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
  String get deskRecvEpicboxIntro => 'Udostępnij go, aby dostać płatność.';

  @override
  String get deskRecvCheckSix =>
      'Czytając go na głos, sprawdź pierwsze sześć i ostatnie sześć znaków.';

  @override
  String get deskRecvHttpAddress => 'Adres Link · HTTP';

  @override
  String get deskRecvCopyHttp => 'Kopiuj adres Link · HTTP';

  @override
  String get deskRecvHttpIntro =>
      'Dla portfeli w sieci lokalnej, gdy ten portfel jest otwarty.';

  @override
  String get deskRecvHttpTorHint =>
      'Aby zamiast tego mieć adres Tor, włącz Tor w Ustawienia › Prywatność.';

  @override
  String get deskRecvDirectTor => 'Adres Link · Tor';

  @override
  String get deskRecvTorIntro =>
      'Prosto z innego portfela przez Tor, gdy ten jest otwarty. Tor ustawisz w Ustawienia › Prywatność.';

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
      'Podpisz plik transakcji od nadawcy i zapisz plik odpowiedzi.';

  @override
  String get deskRecvOpen => 'Otwórz';

  @override
  String get deskRecvFinalizeTitle => 'Sfinalizuj plik odpowiedzi';

  @override
  String get deskRecvFinalizeText =>
      'Sfinalizuj plik odpowiedzi od odbiorcy, aby opublikować płatność.';

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
  String get deskSendSpendableWhile => 'Dostępne do potwierdzenia';

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
  String deskSendLockAll(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wszystko jest zablokowane: $count wyjścia, $amount EPIC, $_temp0.',
      many: 'Wszystko jest zablokowane: $count wyjść, $amount EPIC, $_temp1.',
      few: 'Wszystko jest zablokowane: $count wyjścia, $amount EPIC, $_temp2.',
      one: 'Wszystko jest zablokowane: $count wyjście, $amount EPIC, $_temp3.',
    );
    return '$_temp4';
  }

  @override
  String deskSendLockSome(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyjścia zablokowane, $amount EPIC, $_temp0.',
      many: '$count wyjść zablokowanych, $amount EPIC, $_temp1.',
      few: '$count wyjścia zablokowane, $amount EPIC, $_temp2.',
      one: '$count wyjście zablokowane, $amount EPIC, $_temp3.',
    );
    return '$_temp4';
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
  String deskSendReviewSetAsideNone(String locked) {
    return '$locked EPIC wychodzi w całości; nic nie jest odkładane.';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wszystko: $locked EPIC w $count wyjścia do potwierdzenia reszty $_temp0. Nic nie zostaje do wydania.',
      many:
          'Wszystko: $locked EPIC w $count wyjściach do potwierdzenia reszty $_temp1. Nic nie zostaje do wydania.',
      few:
          'Wszystko: $locked EPIC w $count wyjściach do potwierdzenia reszty $_temp2. Nic nie zostaje do wydania.',
      one:
          'Wszystko: $locked EPIC w $count wyjściu do potwierdzenia reszty $_temp3. Nic nie zostaje do wydania.',
    );
    return '$_temp4';
  }

  @override
  String deskSendReviewSetAsideAll(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    return 'Wszystko: $locked EPIC jest odłożone do potwierdzenia tej płatności $_temp0. Nic nie zostaje dostępne.';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC w $count wyjścia do potwierdzenia reszty $_temp0. W tym czasie nic innego nie jest do wydania.',
      many:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty $_temp1. W tym czasie nic innego nie jest do wydania.',
      few:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty $_temp2. W tym czasie nic innego nie jest do wydania.',
      one:
          '$locked EPIC w $count wyjściu do potwierdzenia reszty $_temp3. W tym czasie nic innego nie jest do wydania.',
    );
    return '$_temp4';
  }

  @override
  String deskSendReviewSetAsideEverything(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    return '$locked EPIC jest odłożone do potwierdzenia tej płatności $_temp0. Do tego czasu nic innego nie jest dostępne.';
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
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC w $count wyjścia do potwierdzenia reszty $_temp0. $spendable EPIC zostaje do wydania.',
      many:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty $_temp1. $spendable EPIC zostaje do wydania.',
      few:
          '$locked EPIC w $count wyjściach do potwierdzenia reszty $_temp2. $spendable EPIC zostaje do wydania.',
      one:
          '$locked EPIC w $count wyjściu do potwierdzenia reszty $_temp3. $spendable EPIC zostaje do wydania.',
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
      other: '($blocks bloku)',
      many: '($blocks bloków)',
      few: '($blocks bloki)',
      one: '(1 blok)',
    );
    return '$locked EPIC jest odłożone do potwierdzenia tej płatności $_temp0. $spendable EPIC pozostaje dostępne.';
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
      'Wydaje najmniejsze wyjścia, które pokrywają kwotę; reszta zostaje do wydania.';

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
      'Przekaż ten plik odbiorcy, a potem sfinalizuj jego plikiem odpowiedzi.';

  @override
  String get deskSendFinalize => 'Sfinalizuj';

  @override
  String get deskSendNewSend => 'Wyślij kolejną';

  @override
  String get deskSendNodeNotSynced => 'Węzeł niezsynchronizowany';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Wysyłanie wróci po synchronizacji węzła ($percent %).';
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
  String get deskSendTorStartingText => 'Wysyłanie czeka na Tor.';

  @override
  String get deskSendEpicboxOff => 'Epicbox niepołączony';

  @override
  String get deskSendEpicboxOffText =>
      'Włącz odbieranie przez Epicbox, aby wysyłać przez Epicbox, albo użyj: Bezpośrednio · Przesyłanie pliku.';

  @override
  String deskSendEpicboxOffTab(String method) {
    return 'Włącz odbieranie przez Epicbox, aby wysyłać przez Epicbox, albo użyj: $method.';
  }

  @override
  String get deskSendEpicboxTurnOn => 'Włącz odbieranie przez Epicbox';

  @override
  String get deskSendDoneViaDirect => 'Sfinalizowano i opublikowano w sieci.';

  @override
  String get deskSendDoneViaEpicbox =>
      'Przekazano do Epicbox. Zakończy się, gdy odbiorca odpowie.';

  @override
  String get deskSendViewTx => 'Pokaż w Aktywności';

  @override
  String get deskSendFailedTitle => 'Wysyłka nie powiodła się';

  @override
  String get deskSendReviewAgain => 'Sprawdź ponownie';

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
  String get deskSendNeedsTor => 'Link · Tor wymaga Tora';

  @override
  String get deskSendNeedsTorText =>
      'Adres onion jest osiągalny tylko przez Tor.';

  @override
  String get deskSendNoTorBuild => 'Ta wersja nie zawiera Tora.';

  @override
  String get deskSendTurnOnTor => 'Włącz Tor';

  @override
  String get deskSendHttpClearnet =>
      'Link · HTTP idzie bezpośrednio, bez Tora.';

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
  String get deskSendAllButton => 'Maks.';

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
  String get deskSendMessageHelp => 'Odbiorca ją zobaczy.';

  @override
  String get deskSendPrivacyOn => 'Prywatność · Dandelion++ włączony';

  @override
  String get deskSendPrivacyOff => 'Prywatność · Dandelion++ wyłączony';

  @override
  String get deskSendDandelionText =>
      'Przepuszcza transakcję przez kilka losowych węzłów, zanim się rozejdzie, więc sieć nie wie, skąd pochodzi.';

  @override
  String get deskSendHintSent => 'Wysłano.';

  @override
  String get deskSendHintQueued =>
      'W kolejce. Wpisz nową kwotę i odbiorcę, aby wysłać ponownie.';

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
  String get deskSendHintFix => 'Popraw zaznaczone pola.';

  @override
  String get deskSendHintChecking => 'Sprawdzanie opłaty dla tej kwoty.';

  @override
  String get deskSendHintDefault =>
      'Przed sprawdzeniem nic nie zostanie wysłane.';

  @override
  String get deskSendReviewWaitTor => 'Oczekiwanie na Tor';

  @override
  String get deskSendReviewTorOff => 'Tor niepołączony';

  @override
  String get deskSendReview => 'Sprawdź';

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
  String get deskSendEpicboxLine2 =>
      'Serwer Epicbox trzyma płatność, aż odbiorca otworzy portfel.';

  @override
  String get deskSendDirectLine1 => 'Prosto do portfela odbiorcy.';

  @override
  String get deskSendDirectLine2 =>
      'Portfel odbiorcy musi być otwarty. Adres onion działa przez Tor.';

  @override
  String get deskSendFileLine1 => 'Bez połączenia.';

  @override
  String get deskSendFileLine2 =>
      'Przekaż plik, odbierz plik odpowiedzi, potem sfinalizuj go tutaj.';

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
  String get deskFinPosted => 'Płatność opublikowana w sieci';

  @override
  String get deskFinTitle => 'Sfinalizuj plik odpowiedzi';

  @override
  String get deskFinNoticeTitle => 'Dla płatności plikiem';

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
      'To nie jest plik transakcji. Wybierz plik .tx od nadawcy.';

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
  String get deskActSearchHint => 'Szukaj płatności';

  @override
  String get deskActSearchLabel => 'Szukaj płatności';

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
  String get deskActDetailReceived => 'Płatność przychodząca';

  @override
  String get deskActDetailSent => 'Płatność wychodząca';

  @override
  String get deskActLoading => 'Wczytywanie płatności';

  @override
  String get deskActWaitingNode => 'Oczekiwanie na synchronizację węzła.';

  @override
  String get deskActFilterAll => 'Wszystkie';

  @override
  String get deskActFilterReceived => 'Odebrane';

  @override
  String get deskActFilterSent => 'Wysłane';

  @override
  String deskActNoMatchTitle(String query) {
    return 'Brak wyników dla „$query”.';
  }

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
  String get deskActEmptyTitle => 'Brak płatności';

  @override
  String get deskActEmptyText => 'Wysłane i odebrane płatności, od najnowszej.';

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
  String get deskConNone => 'Brak kontaktów';

  @override
  String get deskConNoMatchList => 'Brak pasujących kontaktów';

  @override
  String get deskConAdd => 'Dodaj kontakt';

  @override
  String get deskConIdle => 'Wybierz kontakt.';

  @override
  String get deskConEmptyTitle => 'Brak kontaktów';

  @override
  String get deskConEmptyText => 'Kontakt to nazwa dla adresu.';

  @override
  String get deskConSendToAddress => 'Wyślij na adres';

  @override
  String deskConLastTx(String when) {
    return 'Ostatnia płatność: $when';
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
    return 'Płatności z: $name';
  }

  @override
  String get deskConAllTx => 'Wszystkie płatności';

  @override
  String get deskConTxNone =>
      'Brak płatności z tym kontaktem. Płatności wysłane do niego z ekranu Wyślij pojawią się tutaj.';

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
      'To nie jest prawidłowy adres. Użyj adresu Epicbox (es5x…@serwer), adresu Link (https://…) lub adresu onion (….onion).';

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
      'Usuwa kontakt; wcześniejsze płatności zostają w Aktywności. Tego nie można cofnąć.';

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
      'Wyjścia to części, z których składa się saldo. Wysyłka wydaje całe wyjścia i zwraca resztę jako nowe wyjście.';

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
  String deskOutCardWait(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    return 'Poczekaj na potwierdzenie wysyłki ($_temp0).';
  }

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
      other: 'Wydaje $count wyjścia. Opłata co najmniej $fee EPIC.',
      many: 'Wydaje $count wyjść. Opłata co najmniej $fee EPIC.',
      few: 'Wydaje $count wyjścia. Opłata co najmniej $fee EPIC.',
      one: 'Wydaje $count wyjście. Opłata co najmniej $fee EPIC.',
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
  String get deskOutNoneText => 'Pierwsza odebrana płatność utworzy jedno.';

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
  String get deskOutTileImmature => 'Nagrody za kopanie';

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
  String get deskOutStatusAwaiting => 'Czeka na odpowiedź';

  @override
  String get deskOutNoteWaitingSender => 'czeka na nadawcę';

  @override
  String get deskOutStatusUnpaid => 'Niezapłacona faktura';

  @override
  String get deskOutNoteNotInBalance => 'poza saldem';

  @override
  String get deskOutStatusImmature => 'Dojrzewa';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jeszcze $number potwierdzenia',
      many: 'jeszcze $number potwierdzeń',
      few: 'jeszcze $number potwierdzenia',
      one: 'jeszcze $number potwierdzenie',
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
  String deskOutNoteByPendingSend(String date) {
    return 'przez trwającą wysyłkę · $date';
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
  String deskOutSplitDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    return 'Wydaje $spent i tworzy $made. Wszystko do wydania jest zablokowane na $_temp0.';
  }

  @override
  String deskOutConsDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    return 'Wydaje $spent i tworzy $made. Wszystko do wydania jest zablokowane na $_temp0.';
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
  String deskOutFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'około $blocks bloku',
      many: 'około $blocks bloków',
      few: 'około $blocks bloków',
      one: 'około 1 bloku',
    );
    return '$amount EPIC, $_temp0. Nic nie zostaje do wydania.';
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
  String deskOutSplitDoneText(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    String _temp2 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count wyjścia po około $amount EPIC, w trakcie potwierdzania. Zablokowane na $_temp0.',
      many:
          '$count wyjść po około $amount EPIC, w trakcie potwierdzania. Zablokowane na $_temp1.',
      few:
          '$count wyjścia po około $amount EPIC, w trakcie potwierdzania. Zablokowane na $_temp2.',
      one:
          '$count wyjście po około $amount EPIC, w trakcie potwierdzania. Zablokowane na $_temp3.',
    );
    return '$_temp4';
  }

  @override
  String deskOutConsDoneText(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks potwierdzenia',
      many: '$blocks potwierdzeń',
      few: '$blocks potwierdzenia',
      one: '1 potwierdzenie',
    );
    return 'Jedno wyjście na $amount EPIC, w trakcie potwierdzania. Zablokowane na $_temp0.';
  }

  @override
  String get deskOutNotPostedTitle => 'Nie opublikowano';

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
  String get deskOutPostingDesc => 'Publikowanie';

  @override
  String get deskOutDoneDesc => 'Gotowe';

  @override
  String get deskOutSplitDesc =>
      'Więcej wyjść, aby kilka wysyłek mogło iść jedna po drugiej.';

  @override
  String get deskOutConsDesc => 'Jedno wyjście zamiast wielu.';

  @override
  String deskOutNothingText(String what) {
    return 'Nie ma czego scalać: portfel ma $what.';
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
  String deskOvNodeAddrText(String node) {
    return 'Zapisano jako $node.';
  }

  @override
  String get deskOvNodeIncompatTitle => 'Niezgodna wersja węzła';

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
      'Salda mogą być nieaktualne. Sprawdź węzeł albo wybierz inny w ustawieniach węzła.';

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
    return 'Synchronizacja węzła: $percent %';
  }

  @override
  String get deskOvSyncText => 'Pobieranie bloków.';

  @override
  String get deskOvSyncProgress => 'Postęp synchronizacji węzła';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent % łańcucha';
  }

  @override
  String get deskOvReceiveEpic => 'Odbierz EPIC';

  @override
  String get deskOvSend => 'Wyślij';

  @override
  String get deskOvReceive => 'Odbierz';

  @override
  String get deskOvSendWaits => 'Wysyłanie wróci po synchronizacji węzła.';

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
  String get deskOvFiatNote => '  całe saldo';

  @override
  String get deskOvBreakTotal => 'Razem';

  @override
  String get deskOvBreakConfirming => 'Potwierdzane';

  @override
  String get deskOvBreakImmature => 'Nagrody za kopanie';

  @override
  String get deskOvBreakAwaiting => 'Czeka na nadawcę';

  @override
  String get deskOvBreakLocked => 'Zablokowane w wysyłkach';

  @override
  String get deskOvUpdating => 'Aktualizacja';

  @override
  String get deskOvHiddenAmount => 'Ukryta kwota';

  @override
  String get deskOvLoading => 'Wczytywanie płatności';

  @override
  String get deskOvEmptyTitle => 'Brak płatności';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Odebrane EPIC są najpierw potwierdzane, a po $blocks potwierdzenia do wydania.',
      many:
          'Odebrane EPIC są najpierw potwierdzane, a po $blocks potwierdzeniach do wydania.',
      few:
          'Odebrane EPIC są najpierw potwierdzane, a po $blocks potwierdzeniach do wydania.',
      one:
          'Odebrane EPIC są najpierw potwierdzane, a po $blocks potwierdzeniu do wydania.',
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
      other: '$count płatności plikiem do sfinalizowania',
      many: '$count płatności plikiem do sfinalizowania',
      few: '$count płatności plikiem do sfinalizowania',
      one: '$count płatność plikiem do sfinalizowania',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText => 'Sfinalizuj plikiem odpowiedzi od odbiorcy.';

  @override
  String get deskOvFinalize => 'Sfinalizuj';

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
  String get deskTxNoteBlock => 'Czas bloku. Nadawca jest nieznany.';

  @override
  String get deskTxNoteScanTime =>
      'Czas skanowania; nie udało się odczytać czasu bloku. Nadawca nie jest zapisany.';

  @override
  String get deskTxNoteUnknown => 'Nadawca nie jest zapisany.';

  @override
  String get deskTxFoundRestoredLabel => 'Przywrócona';

  @override
  String get deskTxFoundRestoredLine => 'Znaleziona w łańcuchu';

  @override
  String get deskTxFoundRestoredStep => 'Znaleziona w łańcuchu';

  @override
  String get deskTxFoundRestoredTip =>
      'Znaleziona w łańcuchu przy przywracaniu tego portfela. Nadawca nie jest zapisany.';

  @override
  String get deskTxFoundRescanLabel => 'Ze sprawdzenia salda';

  @override
  String get deskTxFoundRescanLine => 'Znaleziona przy sprawdzaniu salda';

  @override
  String get deskTxFoundRescanStep => 'Znaleziona przy sprawdzaniu salda';

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
  String get deskTxBackupTip => 'Zaimportowano z pliku danych portfela.';

  @override
  String get deskTxFromBackup => 'Zaimportowana';

  @override
  String get deskTxStatusImmature => 'Dojrzewa';

  @override
  String get deskTxStatusWaitingSender => 'Czeka na nadawcę';

  @override
  String get deskTxStatusWaitingResponseFile => 'Czeka na plik odpowiedzi';

  @override
  String get deskTxStatusWaitingRecipient => 'Czeka na odbiorcę';

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
  String get deskTxNowBackup =>
      'Zaimportowano z pliku danych portfela. Status nie został sprawdzony w łańcuchu.';

  @override
  String deskTxNowImmature(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $countString potwierdzenia.',
      many:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $countString potwierdzeniach.',
      few:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $countString potwierdzeniach.',
      one:
          'Potwierdzona, ale nagrodę za kopanie można wydać dopiero po $countString potwierdzeniu.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Czeka, aż nadawca opublikuje ją w sieci.';

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
    final intl.NumberFormat confirmationsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String confirmationsString = confirmationsNumberFormat.format(
      confirmations,
    );

    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Potwierdzona, $confirmationsString potwierdzenia.',
      many: 'Potwierdzona, $confirmationsString potwierdzeń.',
      few: 'Potwierdzona, $confirmationsString potwierdzenia.',
      one: 'Potwierdzona, $confirmationsString potwierdzenie.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Anulowana';

  @override
  String get deskTxNotCancelled => 'Nie anulowano';

  @override
  String get deskTxCancelled => 'Transakcja anulowana';

  @override
  String get deskTxCancelling => 'Anulowanie';

  @override
  String get deskTxHeadRestored => 'przywrócona';

  @override
  String get deskTxHeadFoundOnChain => 'Znaleziona w łańcuchu';

  @override
  String get deskTxHeadBackup => 'zaimportowana z pliku danych portfela';

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
  String get deskTxSignedByRecipient => 'Odbiorca podpisał';

  @override
  String get deskTxTechTitle => 'Szczegóły techniczne';

  @override
  String get deskTxStepMined => 'Wykopana w bloku';

  @override
  String get deskTxStepSpendable => 'Zakończona';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jeszcze $count potwierdzenia',
      many: 'jeszcze $count potwierdzeń',
      few: 'jeszcze $count potwierdzenia',
      one: 'jeszcze $count potwierdzenie',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Płatność dotarła';

  @override
  String get deskTxStepCreated => 'Rozpoczęto płatność';

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
  String get deskTxCancelOutgoingTitle => 'Anulować tę płatność?';

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC do $who. Nic jeszcze nie zapłacono: anulowanie jest bez opłaty i pewne.';
  }

  @override
  String get deskTxCancelKeep => 'Zostaw';

  @override
  String get deskTxCancelIncomingAction => 'Anuluj płatność';

  @override
  String get deskTxCancelOutgoingAction => 'Anuluj płatność';

  @override
  String get deskOnbWelcomeAdd => 'Dodaj portfel';

  @override
  String get deskOnbWelcomeTagline =>
      'Klucze i monety zostają na tym komputerze, chronione hasłem.';

  @override
  String get deskOnbWelcomeCreate => 'Utwórz nowy portfel';

  @override
  String get deskOnbWelcomeImport => 'Importuj portfele';

  @override
  String get deskOnbWelcomeImportSub =>
      'Ze starszego Epic Wallet lub z folderu';

  @override
  String get deskOnbWelcomeCreateSub => 'Z nową frazą odzyskiwania';

  @override
  String get deskOnbWelcomeRestoreSub => 'Także ze Stack Wallet lub Epic Pay';

  @override
  String get deskOnbWelcomeRestore => 'Przywróć z frazy';

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
  String get deskOnbCreateStageCreate => 'Tworzenie frazy odzyskiwania';

  @override
  String get deskOnbCreateStageSave => 'Zapisywanie portfela';

  @override
  String get deskOnbCreateNotCreated => 'Nie utworzono portfela';

  @override
  String get deskOnbCreateCreating => 'Tworzenie portfela';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'Portfel w sieci $network, sieci testowej.';
  }

  @override
  String get deskOnbCreateDiskFull =>
      'Nie zapisano portfela: dysk jest pełny. Zwolnij trochę miejsca i spróbuj ponownie.';

  @override
  String get deskOnbCreateWait => 'Nie zamykaj aplikacji.';

  @override
  String get deskOnbCreateLocking => 'Blokowanie otwartego portfela';

  @override
  String get deskOnbCreateSide => 'Nowy portfel';

  @override
  String get deskOnbCreateTitle => 'Utwórz portfel';

  @override
  String get deskOnbCreateLead =>
      'Hasło odblokowuje ten portfel na tym komputerze; tylko fraza odzyskiwania przywraca monety.';

  @override
  String get deskOnbCreateTestNote =>
      'Portfel w sieci testowej, nie na prawdziwe EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'Zapisz te słowa na papierze w podanej kolejności. Tylko za ich pomocą można przywrócić ten portfel.';

  @override
  String get deskOnbCreateRevealFirst => 'Najpierw odkryj frazę';

  @override
  String get deskOnbCreateWarn =>
      'Każdy, kto zna te słowa, może zabrać monety.';

  @override
  String get deskOnbCreateReveal => 'Odkryj frazę';

  @override
  String get deskOnbCreateCheckScreen =>
      'Upewnij się, że nikt nie widzi ekranu.';

  @override
  String get deskOnbCreateHide => 'Ukryj';

  @override
  String get deskOnbCreateShowQr => 'Pokaż QR';

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
      other: 'Mam zapisane wszystkie $count słowa',
      many: 'Mam zapisane wszystkie $count słów',
      few: 'Mam zapisane wszystkie $count słowa',
      one: 'Mam zapisane $count słowo',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreDone => 'Portfel przywrócony.';

  @override
  String get deskOnbRestoreNotRestored => 'Nie przywrócono portfela';

  @override
  String get deskOnbRestoreRestoring => 'Przywracanie portfela';

  @override
  String deskOnbRestorePermission(String folder) {
    return 'Nie zapisano plików portfela: brak uprawnień do $folder. Zezwól na zapis w tym folderze i spróbuj ponownie.';
  }

  @override
  String get deskOnbRestoreWait =>
      'Nie zamykaj aplikacji. Saldo pojawi się po pierwszym skanowaniu.';

  @override
  String get deskOnbRestoreSide => 'Przywróć portfel';

  @override
  String get deskOnbRestorePasswordLead =>
      'Ustaw hasło, które odblokowuje ten portfel na tym komputerze.';

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
      'Wpisz słowa po kolei albo wklej całą frazę do dowolnego pola.';

  @override
  String get deskOnbRestoreClear => 'Wyczyść';

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
  String get deskOnbSameTitle => 'Ten portfel już tu jest';

  @override
  String get deskOnbSameBody =>
      'Fraza należy do portfela z listy. Nic nie dodano.';

  @override
  String get deskOnbSameWallet => 'Portfel';

  @override
  String get deskOnbSameNote =>
      'Otwórz go jego hasłem albo ustaw nowe hasło za pomocą tej frazy.';

  @override
  String get deskOnbSameOpen => 'Otwórz';

  @override
  String get deskOnbUnlockWhoWindows =>
      'Każdy, kto używa tego komputera jako ty, może otworzyć ten portfel.';

  @override
  String get deskOnbUnlockWho =>
      'Każdy, kto używa tego komputera jako ty, może otworzyć ten portfel.';

  @override
  String get deskOnbUnlockWrong =>
      'Nieprawidłowe hasło. Sprawdź Caps Lock i układ klawiatury.';

  @override
  String deskOnbUnlockPortInUse(String port) {
    return 'Port $port zajmuje inny program. Zamknij go i spróbuj ponownie.';
  }

  @override
  String get deskOnbUnlockStageCheck => 'Sprawdzanie plików portfela';

  @override
  String get deskOnbUnlockStageWallet => 'Uruchamianie usługi portfela';

  @override
  String get deskOnbUnlockStageUnlock => 'Odblokowywanie portfela';

  @override
  String get deskOnbUnlockEnter => 'Wpisz hasło';

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
  String deskOnbUnlockUnlocking(String name) {
    return 'Odblokowywanie: $name';
  }

  @override
  String get deskOnbUnlockNote =>
      'Potem węzeł, salda i odbieranie kończą się ładować w tle.';

  @override
  String get deskOnbUnlockTitle => 'Odblokuj portfel';

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
    return 'Był w $folder. Usuń portfel z listy albo przywróć go z frazy odzyskiwania.';
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
    return 'wolne: $size';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'Około $size na dysku,';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return '$size na dysku,';
  }

  @override
  String get deskOnbNodeFirewall => 'Windows zapyta raz';

  @override
  String get deskOnbNodeFirewallText =>
      'o przepuszczenie go przez zaporę. Zezwól w sieciach prywatnych.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'powoli przybywa · $free';
  }

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
      'Łączy się z węzłem Epic GUI lub CLI, który już tu działa.';

  @override
  String get deskOnbNodeAddress => 'Adres węzła na tym komputerze';

  @override
  String get deskOnbNodeCheck => 'Sprawdź';

  @override
  String get deskOnbNodeBundled => 'Uruchom węzeł lokalny';

  @override
  String get deskOnbNodeBundledText =>
      'Po kliknięciu Zapisz pobiera łańcuch do folderu portfela.';

  @override
  String deskOnbNodeFallback(String host) {
    return 'Używaj $host, dopóki węzeł lokalny się nie zsynchronizuje';
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
      other: 'Wklejono $count słowa; fraza ma 12, 15, 18, 21 lub 24 słowa.',
      many: 'Wklejono $count słów; fraza ma 12, 15, 18, 21 lub 24 słowa.',
      few: 'Wklejono $count słowa; fraza ma 12, 15, 18, 21 lub 24 słowa.',
      one: 'Wklejono $count słowo; fraza ma 12, 15, 18, 21 lub 24 słowa.',
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
      'Przeszukiwanie folderów starszych wersji Epic Wallet i programu epic.';

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
  String get deskOnbImportCheckTitle => 'Sprawdzanie portfeli';

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
  String get deskOnbImportOlderSub => 'Portfele i foldery';

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
    return 'Hasło portfela $name w starszej aplikacji';
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
  String get deskAppFirstScanTitle => 'Pierwsze skanowanie';

  @override
  String get deskAppFirstScanBody =>
      'Portfel skanuje łańcuch w poszukiwaniu swoich monet i w tym czasie można go używać.';

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
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Otwórz ustawienia portfela: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Zmień portfel';

  @override
  String get deskTourOverviewTitle => 'Przegląd';

  @override
  String get deskTourOverviewText =>
      'Saldo i to, co jeszcze się potwierdza, a pod nim ostatnie płatności. Wszystko inne jest na pasku bocznym.';

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
  String get deskTourNodeTitle => 'Ustawienia › Węzeł';

  @override
  String get deskTourNodeText =>
      'Z którego węzła portfel czyta łańcuch. Pozostałe strony ustawień są wymienione po lewej.';

  @override
  String get deskTourHelpTitle => 'Pomoc';

  @override
  String get deskTourHelpText =>
      'Tematy pomocy, Zgłoś problem i Pokaż przewodnik ponownie.';

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
  String deskKitLimitedNetwork(String site) {
    return '$site jest nieosiągalny; dane pochodzą tylko z węzła.';
  }

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
  String get deskKitAtTip => 'zsynchronizowany';

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
  String deskKitSourceChecked(String time, String site) {
    return '$site, sprawdzono $time';
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
  String get deskKitNodeDownHead => 'Węzeł nie odpowiada';

  @override
  String deskKitNodeDownText(String host) {
    return 'Przełączyć na $host, najsprawniejszy z pozostałych węzłów?';
  }

  @override
  String get deskKitSwitch => 'Przełącz';

  @override
  String get deskKitLimitedInfo => 'Niepełne dane';

  @override
  String deskKitFromStatusSite(String site) {
    return 'ze $site';
  }

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
  String get deskKitMethodWaitingTor => 'Czeka na Tor';

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
    return 'Port $port zajmuje inny program. Zamknij go albo zmień port poniżej.';
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
  String get deskKitChipNotOverTor => 'Bez Tora';

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
  String get deskKitQrHideCode => 'Ukryj QR';

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
  String get deskSetAcctLabel => 'Nazwa';

  @override
  String get deskSetAcctLabelHint => 'Widoczna tylko w tej aplikacji.';

  @override
  String get deskSetAcctSaveLabel => 'Zapisz etykietę';

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
  String get deskSetBackupExportTitle => 'Eksportuj dane portfela';

  @override
  String get deskSetBackupExportHint =>
      'Historia płatności, kontakty, faktury i ustawienia, w pliku, który otworzy tylko portfel z tą frazą odzyskiwania. Sama fraza przywraca saldo, nie te dane.';

  @override
  String get deskSetBackupExporting => 'Eksportowanie…';

  @override
  String get deskSetBackupExportButton => 'Eksportuj…';

  @override
  String get deskSetBackupImportTitle => 'Importuj dane portfela';

  @override
  String get deskSetBackupImportHint =>
      'Przywraca z pliku danych portfela historię płatności, kontakty, faktury i ustawienia tego portfela. Nic nie jest usuwane; ten sam plik dwa razy niczego nie zmienia.';

  @override
  String get deskSetBackupImportButton => 'Importuj…';

  @override
  String get deskSetBackupCsvHint =>
      'Zwykła tabela do arkuszy kalkulacyjnych. Bez szyfrowania, nie do importu.';

  @override
  String get deskSetBackupSaveDialogTitle => 'Zapisz dane portfela';

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
      'Kto komu zapłacił, opłaty, notatki i etykiety; faktury; ustawienia';

  @override
  String get deskSetBackupNotIn => 'Poza plikiem';

  @override
  String get deskSetBackupNotInValue => 'Fraza odzyskiwania, klucze, hasło';

  @override
  String get deskSetBackupOpensWith => 'Otwiera go';

  @override
  String get deskSetBackupOpensWithValue =>
      'Ten portfel lub portfel przywrócony z jego frazy odzyskiwania';

  @override
  String get deskSetBackupFile => 'Plik';

  @override
  String get deskSetBackupFileNote => 'Plik obejmuje wszystko do tej chwili.';

  @override
  String get deskSetBackupExportDesc =>
      'Plik z historią płatności, kontaktami, fakturami i ustawieniami tego portfela.';

  @override
  String get deskSetBackupSaved => 'Zapisano';

  @override
  String get deskSetBackupKeepCopy =>
      'Zachowaj kopię poza tym komputerem: na pendrivie, innym dysku lub w chmurze.';

  @override
  String get deskSetBackupOpenFolder => 'Otwórz folder';

  @override
  String get deskSetBackupSaving => 'Zapisywanie…';

  @override
  String get deskSetBackupTryAgain => 'Spróbuj ponownie';

  @override
  String get deskSetBackupSaveAs => 'Zapisz jako…';

  @override
  String get deskSetBackupOpenDialogTitle => 'Otwórz plik danych portfela';

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
      'Szczegóły i notatki płatności, starsze płatności, których brakuje na liście, kontakty, faktury i ustawienia';

  @override
  String get deskSetBackupNeeds => 'Wymaga';

  @override
  String get deskSetBackupNeedsValue =>
      'Plik z tego portfela (ta sama fraza odzyskiwania). Najpierw przywróć portfel z jego frazy.';

  @override
  String get deskSetBackupChooseFile => 'Wybierz plik…';

  @override
  String get deskSetBackupImportDesc =>
      'Przywraca historię płatności, kontakty, faktury i ustawienia tego portfela; istniejące wpisy zostają.';

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
  String get deskSetBackupRangeAll => 'Cały czas';

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
    return '$_temp0 · $file';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '$file';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Bez szyfrowania.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Każdy, kto ma plik, odczyta kwoty, daty, adresy i notatki.';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count płatności nie ma w wyeksportowanych danych portfela.',
      many: '$count płatności nie ma w wyeksportowanych danych portfela.',
      few: '$count płatności nie ma w wyeksportowanych danych portfela.',
      one: '$count płatności nie ma w wyeksportowanych danych portfela.',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności jest nowych lub zmienionych od ostatniego eksportu danych portfela.',
      many:
          '$count płatności jest nowych lub zmienionych od ostatniego eksportu danych portfela.',
      few:
          '$count płatności są nowe lub zmienione od ostatniego eksportu danych portfela.',
      one:
          '$count płatność jest nowa lub zmieniona od ostatniego eksportu danych portfela.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'Przywrócenie z frazy odzyskiwania odtwarza saldo, ale nie to, kto komu zapłacił.';

  @override
  String get deskSetBackupNotNow => 'Nie teraz';

  @override
  String get deskSetDlgChainTitle => 'Znaleziono dane łańcucha';

  @override
  String get deskSetDlgChainDesc =>
      'Węzeł lokalny może użyć danych łańcucha Epic, które są już na tym komputerze, zamiast je pobierać.';

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
      'Znaleziono 1 inną kopię; ta jest najnowsza.';

  @override
  String get deskSetDlgChainInUse =>
      'Inny program Epic używa tego folderu. Zamknij go, a potem ponownie wybierz węzeł lokalny, aby użyć tych danych.';

  @override
  String get deskSetDlgChainUseIt => 'Użyć ich?';

  @override
  String get deskSetDlgChainOlderWallet =>
      'Starszy Epic Wallet, który używa tego folderu, synchronizuje się potem ponownie.';

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
      'Od teraz ten portfel odblokowuje nowe hasło; Zapamiętaj na tym komputerze zostaje wyłączone.';

  @override
  String get deskSetDlgPwDescPlain =>
      'Od teraz ten portfel odblokowuje nowe hasło, a ten komputer już go nie pamięta.';

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
  String get deskSetDlgRemoveWhat => 'Co usunąć';

  @override
  String get deskSetDlgRemoveFromList => 'Usuń z listy';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Pliki zostają w $folder; Dodaj portfel przywróci go na listę.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Usuń portfel';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Usuwa jego klucze i bazę danych z $folder. Przywróci go tylko fraza odzyskiwania; bez niej monety przepadną.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'Aby usunąć także jego pliki, odblokuj ten portfel i użyj Usuń portfel w Ustawienia › Ten portfel.';

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
    return 'Używaj $host, dopóki węzeł lokalny się nie zsynchronizuje';
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
      'Uruchom węzeł ponownie albo sprawdź log węzła.';

  @override
  String deskSetLnodePortInUse(String port) {
    return 'Port $port zajmuje inny program.';
  }

  @override
  String get deskSetLnodePortInUseText =>
      'Zamknij drugi program albo wybierz ten węzeł w Serwer węzła.';

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
    return '$host, węzeł publiczny, może go zastąpić do czasu synchronizacji węzła lokalnego.';
  }

  @override
  String get deskSetLndAskNote =>
      'Pytanie pada raz. Węzeł i wybór można zmienić w Ustawienia › Węzeł › Podczas synchronizacji.';

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
    return 'Usuwa $size z $path; łańcuch pobierze się od nowa przy następnym uruchomieniu. Klucze i historia zostają.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Usuwa dane łańcucha z $path. Węzeł się zatrzyma, a przy następnym uruchomieniu cały łańcuch pobierze się od nowa (godziny). Klucze i historia portfela pozostają nietknięte.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Wpisz „$word”, aby potwierdzić';
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
  String get deskSetLndReuseTitle => 'Znaleziono dane łańcucha';

  @override
  String get deskSetLndReuseDesc =>
      'Inny węzeł Epic zostawił tu dane łańcucha. Węzeł lokalny może czytać ten folder zamiast pobierać łańcuch.';

  @override
  String get deskSetLndLooking => 'Szukanie…';

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
  String deskSetPeersNotAddress(String port) {
    return 'To nie jest adres IP z portem, np. 203.0.113.5:$port.';
  }

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
  String deskSetPeersRefreshed(int seconds) {
    return 'Odświeżane co $seconds s';
  }

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
    return 'Maks. przychodzących i wychodzących: od $min do $max (domyślnie $def).';
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
  String deskSetNodePortNote(String port) {
    return 'Sprawdź adres i port (zwykle $port).';
  }

  @override
  String deskSetNodeListNote(String site) {
    return 'Stan ze $site; opóźnienie mierzone z tego komputera.';
  }

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
      'Zapisz te słowa na papierze w podanej kolejności. Tylko za ich pomocą można przywrócić ten portfel.';

  @override
  String get deskSetPhrasePanel => 'Wpisz hasło, aby pokazać słowa';

  @override
  String get deskSetPhraseShowWords => 'Pokaż frazę odzyskiwania';

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
  String get deskSetPhraseHideQr => 'Ukryj QR';

  @override
  String get deskSetPhraseShowQr => 'Pokaż QR';

  @override
  String get deskSetPhraseHideWords => 'Ukryj frazę odzyskiwania';

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
      'Każdy, kto zna te słowa, może zabrać monety. Upewnij się, że nikt nie widzi ekranu.';

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
  String deskSetPrivStartingDetail(int progress) {
    return '$progress %. Każde połączenie czeka na Tor.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Adres Tor nie jest jeszcze opublikowany. Wysyłanie działa.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Wysyłanie działa.';
  }

  @override
  String get deskSetPrivConnected => 'Połączono';

  @override
  String get deskSetPrivNotConnected => 'Brak połączenia';

  @override
  String get deskSetPrivStoppedDetail =>
      'Tor się zatrzymał. Ponów albo wyłącz Tor.';

  @override
  String deskSetPrivProblemDetail(String problem) {
    return '$problem. Ponów albo wyłącz Tor.';
  }

  @override
  String get deskSetPrivStatusSite => 'Strona stanu';

  @override
  String deskSetPrivUseStatus(String site) {
    return 'Używaj $site';
  }

  @override
  String get deskSetPrivUseStatusHint =>
      'Pokazuje, które węzły i serwery Epicbox są online, z publicznej listy na status.btlabs.uk.';

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
  String get deskSetRecvEpicboxText =>
      'Serwer Epicbox przechowuje płatności, dopóki portfel się nie otworzy.';

  @override
  String get deskSetRecvEpicboxServer => 'Serwer Epicbox';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Który serwer przechowuje płatności na ten adres. Oba portfele mogą używać różnych serwerów.';

  @override
  String get deskSetRecvSwitchingServer => 'Przełączanie serwera Epicbox…';

  @override
  String deskSetRecvListNote(String site) {
    return 'Stan ze $site.';
  }

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
  String get deskSetHttpPortError => 'Port musi być od 1024 do 65535';

  @override
  String get deskSetHttpGuideHelp => 'Odbieranie z internetu: jak to działa';

  @override
  String get deskSetHttpPort => 'Port';

  @override
  String deskSetHttpPortHint(String port) {
    return 'Od 1024 do 65535. Domyślnie $port.';
  }

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
    return 'Portfel odpowiada na 0.0.0.0, port $port, więc inne urządzenia mogą do niego wysyłać.';
  }

  @override
  String get deskSetHttpStep2 => 'Przekieruj port';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'Na stronie routera (często 192.168.1.1) znajdź Przekierowanie portów i przekieruj TCP $port do tego komputera.';
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
      'Zaszyfrowany, więc przeczyta go tylko twórca aplikacji. Zapisz do pliku zachowuje kopię bez szyfrowania.';

  @override
  String get deskSetReportWhat => 'Co się stało';

  @override
  String get deskSetReportWhatHint =>
      'Co było robione, czego oczekiwano, co stało się zamiast tego';

  @override
  String get deskSetReportAttach => 'Dołącz logi';

  @override
  String get deskSetReportAttachHint =>
      'Najnowsza część logu aplikacji, bez frazy odzyskiwania, hasła i innych poufnych danych.';

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
  String get deskSetRescanLog => 'Log sprawdzania salda';

  @override
  String get deskSetRescanText =>
      'Ponownie sprawdza łańcuch pod kątem środków tego portfela. Użyj tego, gdy saldo wygląda na błędne.';

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
    return 'Sprawdzanie… $percent %';
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
  String get deskSetRescanFinished => 'Sprawdzanie salda zakończone';

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
  String get deskSetRescanRevived => 'Znów odblokowane';

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
  String get deskSetWalletsImport => 'Importuj portfele';

  @override
  String get deskSetWalletsImportText =>
      'Ze starszego Epic Wallet lub z folderu';

  @override
  String get deskSetWalletsRestore => 'Przywróć z frazy';

  @override
  String get deskSetWalletsRestoreText => 'Z frazy odzyskiwania';

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
  String get deskSetupAgain =>
      'Ponowna konfiguracja. Nic się nie zmieni przed kliknięciem Zapisz ustawienia na ostatnim kroku.';

  @override
  String get deskSetupPrefsLead => 'Język aplikacji';

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
  String get deskSetupEpicboxTitle => 'Epicbox';

  @override
  String get deskSetupSideTitle => 'Konfiguracja';

  @override
  String get deskSetupBackToWallet => 'Wróć do portfela';

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
      'Działa na tym komputerze: prywatnie, ale wymaga miejsca na dysku i pierwszej synchronizacji.';

  @override
  String get deskSetupEpicboxText =>
      'Serwer Epicbox przechowuje płatności, dopóki portfel się nie otworzy.';

  @override
  String get deskSetupEpicboxServer => 'Serwer Epicbox';

  @override
  String deskSetupExistingNode(String host) {
    return 'Istniejący węzeł na $host';
  }

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Zapisanie uruchomi węzeł; do czasu synchronizacji zastąpi go $node.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Zapisanie uruchomi węzeł. Pierwsza synchronizacja trwa kilka godzin; portfel otworzy się wcześniej.';

  @override
  String get deskSetAboutLicencesLead =>
      'Oprogramowanie open source w tym portfelu, każde na własnej licencji.';

  @override
  String get deskSetAboutLicenceApp => 'BT Wallet od BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Nie otwarto przeglądarki';

  @override
  String get deskSetAboutOpen => 'Otwórz';

  @override
  String deskSetAboutVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Węzeł $version';
  }

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
  String get deskSetAboutCheckNow => 'Sprawdź';

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
      other: 'Znaleziono $count tematu',
      many: 'Znaleziono $count tematów',
      few: 'Znaleziono $count tematy',
      one: 'Znaleziono $count temat',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'Brak pasujących tematów';

  @override
  String get deskSetHelpReportText =>
      'Opisz, co poszło nie tak; możesz dołączyć oczyszczony log aplikacji, zaszyfrowany dla twórcy aplikacji.';

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
      'Windows nie mógł zabezpieczyć sekretów portfela (DPAPI odmówiło), więc nic nie zapisano. Używaj Windows bezpośrednio, jako ty, ze swoim hasłem, nie przez sesję zdalną ani usługową, i spróbuj ponownie.';

  @override
  String get deskKeyringMissingTitle => 'Nie znaleziono pęku kluczy';

  @override
  String get deskKeyringMissingText =>
      'BT Wallet przechowuje swoje ustawienia i zapieczętowane hasło portfela w systemowym pęku kluczy, ale żaden nie odpowiedział. Zainstaluj lub uruchom pęk kluczy (GNOME Keyring lub KWallet) albo użyj sesji pulpitu, która go uruchamia, a potem wybierz Ponów.';

  @override
  String get deskKeyringLockedTitle => 'Pęk kluczy jest zablokowany';

  @override
  String get deskKeyringLockedText =>
      'BT Wallet przechowuje swoje ustawienia i zapieczętowane hasło portfela w systemowym pęku kluczy, który jest zablokowany. Odblokuj go (zwykle hasłem, którym odblokowujesz ten komputer), a potem wybierz Ponów, albo wybierz Odblokuj teraz, aby system o nie poprosił.';

  @override
  String get deskKeyringUnlockNow => 'Odblokuj teraz';

  @override
  String get txStatusNotDelivered => 'Nie dostarczono';

  @override
  String get txDetailsNotDeliveredBody =>
      'Ta płatność nie dotarła jeszcze do serwera Epicbox, więc odbiorca jej nie dostał. Monety pozostają zablokowane, dopóki nie zostanie wysłana ponownie lub anulowana.';

  @override
  String get txDetailsSendAgainDone =>
      'Wysłano ponownie. Płatność zakończy się, gdy portfel odbiorcy będzie online.';

  @override
  String get deskTxThisWallet => 'Ten portfel';

  @override
  String get deskErrOldLinks =>
      'Folder tego portfela zawiera dowiązania, więc nie zostanie zaimportowany. Przywróć portfel z frazy odzyskiwania.';

  @override
  String get deskErrOldIncomplete =>
      'Folderu tego portfela nie udało się odczytać w całości, więc nie zostanie zaimportowany. Przywróć portfel z frazy odzyskiwania.';

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
      'Nie dostarczono. Płatność nie dotarła do serwera Epicbox, więc odbiorca jej nie otrzymał. Wyślij ją ponownie albo anuluj, żeby odblokować monety.';

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
  String deskSendMessageCount(int used, int max) {
    return '$used / $max';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'Wiadomość jest dłuższa niż $max bajtów. Skróć ją.';
  }

  @override
  String get deskSendMessageTooLongPlain =>
      'Wiadomość jest za długa. Skróć ją.';

  @override
  String get deskSetPhraseCopyTitle => 'Skopiować frazę odzyskiwania?';

  @override
  String get deskSetPhraseCopyText =>
      'Każdy, kto ma te słowa, może zabrać twoje środki. Przechowuj kopię w bezpiecznym miejscu.';

  @override
  String get deskOutAdvanced => 'Zarządzaj wyjściami';

  @override
  String get deskOutStrategyHint =>
      'Które wyjścia wydaje wysyłka. Najmniejsze wydaje najmniejsze wyjścia, które pokrywają kwotę; Wszystkie wydaje każde wyjście i zwraca jedno.';

  @override
  String get txStatusNotPosted => 'Nie ma w sieci';

  @override
  String get txStatusStalled => 'Utknęło';

  @override
  String get txDetailsStalledBody =>
      'Druga strona jeszcze nie rozgłosiła tej płatności.';

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
      'Tylko dla płatności znalezionych przy sprawdzaniu salda.';

  @override
  String get deskTxDetailsFrom => 'Od';

  @override
  String get deskTxDetailsFromTip =>
      'Kto zapłacił, do Twoich zapisów. Niezweryfikowane.';

  @override
  String get deskTxDetailsFromHint => 'Adres nadawcy';

  @override
  String get deskTxDetailsFromBad => 'Użyj adresu Epicbox, http(s) lub .onion.';

  @override
  String get deskTxDetailsNote => 'Prywatna notatka';

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
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
      many:
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
      few:
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
      one:
          'Plik ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te z pliku.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'Moje';

  @override
  String get deskHistConflictBackup => 'Plik';

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
          'Historia starego portfela ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te ze starego portfela.',
      many:
          'Historia starego portfela ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te ze starego portfela.',
      few:
          'Historia starego portfela ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te ze starego portfela.',
      one:
          'Historia starego portfela ma inne szczegóły dla płatności: $n. Twoje zostają, chyba że wybierzesz te ze starego portfela.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Stary portfel';

  @override
  String get deskHistConflictApply => 'Zastosuj';

  @override
  String get deskUpdAvailable => 'Dostępna aktualizacja';

  @override
  String deskUpdDownload(String version) {
    return 'Pobierz $version';
  }

  @override
  String get deskUpdOpensPage => 'Otwiera stronę pobierania';

  @override
  String deskUpdDownloading(String percent) {
    return 'Pobieranie: $percent %';
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
  String get advIntro =>
      'Każdy przełącznik pokazuje kolejną część portfela w miejscu, do którego należy.';

  @override
  String get advShowsHeader => 'Pokazuje więcej';

  @override
  String get advNetworkHeader => 'Sieć';

  @override
  String get advOutputs => 'Wyjścia';

  @override
  String get advOutputsHint =>
      'Pokazuje stronę Wyjścia pod Portfelem i na ekranie głównym. Wymienia monety, z których składa się saldo, pozwala je dzielić lub scalać i ustawia domyślne zasady wysyłki. Trwający podział lub scalanie utrzymuje stronę widoczną.';

  @override
  String get advTechnical => 'Szczegóły techniczne';

  @override
  String get advTechnicalHint =>
      'Pokazuje wiersze techniczne w szczegółach płatności: kernel, ID slate, commitmenty i wysokość bloku. W ustawieniach Faktur pokazuje, jak długo faktura pozostaje do zapłaty.';

  @override
  String get advSendOptions => 'Opcje wysyłki';

  @override
  String get advSendOptionsHint =>
      'Pokazuje Strategię wysyłki i Podziel resztę w Ustawienia › Transakcje: które wyjścia wydaje wysyłka i czy jej reszta jest dzielona. Pozostaje widoczne, dopóki któraś z nich nie jest domyślna.';

  @override
  String get advServerDetails => 'Szczegóły serwerów';

  @override
  String get advServerDetailsHint =>
      'Pokazuje hosty, opóźnienie, wersję i wysokość bloku na listach serwerów i na karcie stanu oraz adres Epicbox w Odbierz.';

  @override
  String get advRecheckHeight => 'Sprawdź od wysokości';

  @override
  String get advRecheckHeightHint =>
      'Pozwala Sprawdź saldo zacząć od wysokości bloku lub daty zamiast od pierwszego bloku. Szybciej, i jedyny sposób, by pominąć wczesną historię. Przywracanie zawsze daje taki wybór.';

  @override
  String get advModeStandard => 'Normalny';

  @override
  String get advModeTorOnly => 'Tylko Tor';

  @override
  String get advModeTorOnlyLine =>
      'Każde połączenie idzie przez Tor. Dopóki Tor nie jest gotowy, nic się nie łączy.';

  @override
  String get advReset => 'Ukryj wszystko ponownie';

  @override
  String get advBuiltInNode => 'Węzeł lokalny';

  @override
  String get advLogs => 'Logi';

  @override
  String get deskSetFrameAdvanced => 'Zaawansowane';

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
      'Pokazuje sekcję Szczegóły techniczne przy każdej transakcji: kernel, ID slate, commitmenty i wysokość bloku. Bez tego link Więcej przy transakcji pokazuje je jednorazowo. W Fakturach pokazuje sekcje zaawansowane.';

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
  String get deskSetAdvBuiltInNode => 'Węzeł lokalny';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'Pozwala temu komputerowi uruchomić własny węzeł: opcja Ten komputer w Węźle, jej panel synchronizacji i Uruchom węzeł na Przeglądzie. Synchronizacja łańcucha trwa godziny i zajmuje kilka gigabajtów dysku. Działający węzeł zachowuje swoje wiersze.';

  @override
  String get deskSetAdvLogs => 'Logi';

  @override
  String get deskSetAdvLogsHint =>
      'Pokazuje grupę Logi w Pliki i logi: otwórz folder logów, wyczyść logi. Zgłoszenie problemu i tak dołącza log.';

  @override
  String get deskSetAdvNetwork => 'Sieć';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'Każde połączenie idzie przez Tor. Dopóki Tor nie jest gotowy, nic się nie łączy.';

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
  String get deskSetAcctAutoLockHint =>
      'Blokuje portfel po tym czasie bez naciśnięcia klawisza lub ruchu myszy. Przy „Nigdy” portfel blokuje tylko „Zablokuj portfel”. Wszystkie portfele.';

  @override
  String get torUndercoverKeepsOn => 'Incognito utrzymuje Tor włączony.';

  @override
  String get torLockedTorOnly => 'Włączony w trybie Tylko Tor.';

  @override
  String get torUndercoverChange => 'Zmień Incognito';

  @override
  String get torUndercoverChangeShort => 'Zmień';

  @override
  String get txDetailsMore => 'Więcej';

  @override
  String get restoreStartFromLink => 'Zacznij od daty lub wysokości';

  @override
  String restoreScanningFrom(String month) {
    return 'Początek skanowania: $month';
  }

  @override
  String get restoreScanningFromStart => 'Skanowanie od początku';

  @override
  String get restoreScanFromStart => 'Skanuj od początku';

  @override
  String restoreScanningFromBlock(String height) {
    return 'Początek skanowania: blok $height';
  }

  @override
  String get scanStartChange => 'Zmień początek';

  @override
  String get scanStartInfoTitle => 'Początek skanowania';

  @override
  String get scanStartInfo =>
      'Znajdowane są tylko monety od tego miejsca. Wcześniejszy początek znajdzie starsze monety, ale potrwa dłużej.';

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
  String get slSwitchBody => 'Po zmianie otrzymasz nowy adres Epicbox.';

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
  String get slRelayWarning => 'Po zmianie otrzymasz nowy adres Epicbox.';

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
  String get deskNetWaitingTorReason =>
      'Czeka na Tor. Tylko Tor jest włączony w Zaawansowanych.';

  @override
  String get deskNetOpenAdvanced => 'Otwórz Zaawansowane';

  @override
  String get deskNetSendFileHint => 'Przesyłanie pliku nadal działa.';

  @override
  String get deskNetRecvWaitTorText =>
      'Odbieranie zacznie się, gdy Tor się połączy. Przesyłanie pliku nadal działa.';

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
  String get txMethodsHeader => 'Metody płatności';

  @override
  String txLinkHttpHint(String port) {
    return 'Link · HTTP płaci prosto do portfela pod adresem internetowym (http://host:$port) i daje temu telefonowi adres, na który mogą płacić portfele z tej samej sieci Wi-Fi. Oba portfele muszą być otwarte. Po drodze nie jest szyfrowany, nie jest osiągalny z internetu ani przez dane komórkowe i jest wyłączony, gdy Tor jest włączony. Dodaje Link · HTTP do Wyślij i Odbierz.';
  }

  @override
  String get txLinkTorHint =>
      'Link · Tor płaci prosto do portfela pod adresem onion i daje temu telefonowi adres Tor, na który można mu płacić. Oba portfele muszą być otwarte. Wymaga Tora: przełącznik Tor w Prywatność i sieć kieruje połączenia portfela przez Tor; ten przełącznik tylko włącza adres. Dodaje Link · Tor do Wyślij i Odbierz.';

  @override
  String get txLinkTorHintNet =>
      'Link · Tor płaci prosto do portfela pod adresem onion i daje temu telefonowi adres Tor, na który można mu płacić. Oba portfele muszą być otwarte. Wymaga Tora: przełącznik Tor w Sieć i prywatność kieruje połączenia portfela przez Tor; ten przełącznik tylko włącza adres. Dodaje Link · Tor do Wyślij i Odbierz.';

  @override
  String get txLinkTorNeedsTor => 'Wymaga Tora. Włącz go w Prywatność i sieć.';

  @override
  String get txLinkTorNeedsTorNet =>
      'Wymaga Tora. Włącz go w Sieć i prywatność.';

  @override
  String get txLastMethodNotice =>
      'Przynajmniej jedna metoda płatności musi zostać włączona.';

  @override
  String get txEpicboxHint =>
      'Epicbox płaci przez serwer, więc drugi portfel nie musi być otwarty. Wyłączony: portfel nie łączy się z żadnym serwerem, więc bez płatności Epicbox i faktur. Pozostałe metody nadal działają.';

  @override
  String get txFileHint =>
      'Przesyłanie pliku tworzy plik transakcji, który przekazujesz drugiej osobie dowolnym sposobem (wiadomość na czacie, pendrive, kabel), a ona odsyła ci drugi. Nie potrzeba połączenia między portfelami. Dodaje Przesyłanie pliku do Wyślij i Odbierz.';

  @override
  String get txStartHeader => 'Domyślna metoda';

  @override
  String get txDefaultsHeader => 'Zasady wysyłki';

  @override
  String get outputsDefaultsMoved =>
      'Domyślne zasady wysyłki są w Ustawienia › Transakcje';

  @override
  String get advNodeFailover => 'Automatyczna zmiana węzła';

  @override
  String get advNodeFailoverHint =>
      'Gdy twój węzeł przestaje odpowiadać, portfel na czas tej sesji używa następnego działającego węzła z twojej listy.';

  @override
  String get advBalanceHeader => 'Saldo';

  @override
  String get advConfirmations => 'Potwierdzenia';

  @override
  String advConfirmationsHint(int byDefault, int min, int max) {
    return 'Ile bloków odebrana płatność czeka, zanim jej wyjścia będzie można wydać. Domyślnie $byDefault; od $min do $max.';
  }

  @override
  String get advConfirmationsDefault => 'Domyślnie';

  @override
  String advConfirmationsReset(int count) {
    return 'Przywróć $count';
  }

  @override
  String get advConfirmationsFewer => 'Mniej potwierdzeń';

  @override
  String get advConfirmationsMore => 'Więcej potwierdzeń';

  @override
  String advConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count potwierdzenia',
      many: '$count potwierdzeń',
      few: '$count potwierdzenia',
      one: '$count potwierdzenie',
    );
    return '$_temp0';
  }

  @override
  String get advConfirmationsLowNote =>
      'Mniej potwierdzeń to szybciej, ale mniej bezpiecznie.';

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
  String get netOfflineNoPeers =>
      'Twój węzeł nie ma peerów: płatność czeka w jego puli, aż się ponownie połączy.';

  @override
  String get netOfflineNodeHint =>
      'Używa węzła do odczytu łańcucha i wysłania. Dla największej prywatności użyj lokalnego węzła.';

  @override
  String get netOfflineNodeLine => 'Używa węzła';

  @override
  String get netBlockEpicboxOff =>
      'Epicbox jest wyłączony w Ustawienia › Transakcje.';

  @override
  String netBlockMethodOff(String method) {
    return 'Metoda $method jest wyłączona w Ustawienia › Transakcje.';
  }

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
  String sendContactOnlyEpicbox(String name) {
    return '$name ma tylko adres Epicbox.';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name ma tylko adres dla metody $method.';
  }

  @override
  String get receiveEpicboxOffText =>
      'Płatności czekają na serwerze Epicbox, aż Epicbox znów będzie włączony.';

  @override
  String get receiveNoMethods => 'Żadna metoda odbioru nie jest włączona';

  @override
  String get receiveNoMethodsBody => 'Włącz jedną w Ustawienia › Transakcje.';

  @override
  String get receiveNoMethodsButton => 'Otwórz ustawienia';

  @override
  String get deskNetOfflineNoPeers =>
      'Twój węzeł nie ma peerów: płatność czeka w jego puli, aż się ponownie połączy.';

  @override
  String get deskOutDefaultsMoved =>
      'Strategię i Podziel resztę dla wysyłek ustawisz w Ustawienia › Płatności.';

  @override
  String get deskOutDefaultsOpen => 'Otwórz Płatności';

  @override
  String get deskSetFrameTransactions => 'Transakcje';

  @override
  String get deskSetTxMethods => 'Metody';

  @override
  String get deskSetTxEpicboxHint =>
      'Płać i dostawaj zapłatę przez serwer Epicbox. Tak idzie większość płatności. Wyłączony: portfel nie łączy się z żadnym serwerem Epicbox, więc bez płatności Epicbox i faktur. Pozostałe metody nadal działają. Wszystkie portfele.';

  @override
  String deskSetTxDirectHint(String port) {
    return 'Płać i dostawaj zapłatę prosto z portfela do portfela pod adresem internetowym (http://host:$port), bez serwera pośrodku. Działa tylko, gdy oba portfele są otwarte; wyłączony, gdy Tor jest włączony. Dodaje Link · HTTP do Wyślij, a jego adres do Odbierz. Wszystkie portfele.';
  }

  @override
  String get deskSetTxFileHint =>
      'Płać i dostawaj zapłatę, przekazując plik transakcji, bez potrzeby sieci. Dodaje Przesyłanie pliku do Wyślij, a kroki z plikami do Odbierz. Wszystkie portfele.';

  @override
  String get deskSetTxStart => 'Domyślna metoda';

  @override
  String get deskSetTxStartHint =>
      'Metoda, z którą otwiera się strona Wyślij. Dla jednej płatności nadal możesz ją zmienić na stronie Wyślij. Wszystkie portfele.';

  @override
  String get deskSendMethodHeader => 'Metoda płatności';

  @override
  String get sendRequestTitle => 'Faktura';

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
  String get payeeNameLabel => 'Nazwa od odbiorcy';

  @override
  String get payeeNoteLabel => 'Wiadomość od odbiorcy';

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
  String get linkWaitingPairingNotice => 'Otrzymano link parowania';

  @override
  String get linkWaitingNotice => 'Otrzymano link płatności';

  @override
  String get linkFinishCurrentFirst => 'Najpierw dokończ bieżącą płatność.';

  @override
  String get deskSendToQrPayment =>
      'Kod Płatności QR. Zeskanuj go w BT Wallet na telefonie.';

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
  String get deskRecvTorOffTitle => 'Link · Tor wymaga Tora.';

  @override
  String get deskRecvTorOffText =>
      'Adres Tor działa, gdy Tor jest włączony. Tor to przełącznik w Ustawienia › Prywatność; kieruje połączenia portfela przez Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Ustawienia nie zostały zapisane';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Zapisz ponownie albo pomiń, aby zachować dotychczas zapisane ustawienia.';
  }

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
      'Według nadawcy ta płatność została opublikowana w sieci. Zakończy się, gdy sieć ją potwierdzi.';

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
  String get pairInPerson => 'Osobiście';

  @override
  String get pairInPersonHint => 'Pokaż swój kod i zeskanuj kod drugiej osoby';

  @override
  String get pairOfflineHint =>
      'Jesteś offline. Zaproszenie i odpowiedź przekazuje się ręcznie.';

  @override
  String get pairEnterHint =>
      'Wklej link z zaproszeniem lub wpisz otrzymane słowa';

  @override
  String get pairNotPaired => 'Niesparowany';

  @override
  String get pairNotPairedHint =>
      'Sparuj, aby pieczętować pliki transakcji i zezwalać na faktury.';

  @override
  String get pairInPersonTitle => 'Parowanie osobiście';

  @override
  String get pairShowMyCode => 'Pokaż moje zaproszenie';

  @override
  String get pairScanTheirs => 'Zeskanuj ich kod';

  @override
  String get pairShowCodeCaption =>
      'Daj zeskanować ten kod, potem zeskanuj kod drugiej osoby.';

  @override
  String get pairScanCaption =>
      'Skanujecie oboje. Sprawdzanie słów otworzy się, gdy oba kody zostaną odczytane.';

  @override
  String get pairScanPrompt => 'Zeskanuj ich kod QR';

  @override
  String get pairSeenAs => 'Druga strona zobaczy cię jako';

  @override
  String get pairUseWords => 'Użyj słów';

  @override
  String get pairCameraDeniedTitle => 'Aparat jest niedozwolony';

  @override
  String get pairCameraDeniedBody =>
      'Zezwól na aparat, aby skanować, albo wklej zaproszenie.';

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
      'Zaproszenia głosowe wymagają Epicbox, więc teraz nie są dostępne.';

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
    return 'Wklej ten link w portfelu $name w polu „Wpisz link lub słowa”. Potem zweryfikujcie razem.';
  }

  @override
  String get pairEnterDesktopPlaceholder =>
      'Wklej link z zaproszeniem lub wpisz pięć słów';

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
  String get contactsPairHint =>
      'Sparuj z innym portfelem, aby zapieczętować pliki transakcji i faktury między nimi.';

  @override
  String get contactsPairLearn => 'Jak to działa';

  @override
  String get contactsPairTooltip => 'Sparuj z innym portfelem';

  @override
  String get pairBadgePending => 'Parowanie…';

  @override
  String get pairBadgePendingTip =>
      'Zaproszenie wysłane lub przyjęte, jeszcze nie zakończone.';

  @override
  String get pairWaysLead =>
      'Sparuj raz. Potem pliki transakcji i faktury między oboma portfelami są zapieczętowane.';

  @override
  String get pairWayWords => 'Słowa';

  @override
  String get pairWayAutomatic => 'Głosowo';

  @override
  String get pairWayWordsHint =>
      'Przeczytaj drugiej osobie pięć słów parowania. Oba portfele muszą być online.';

  @override
  String get pairWayWordsInfo =>
      'Oba portfele muszą być online. Twój portfel zostawia zaproszenie na serwerach połączeń; portfel drugiej osoby znajduje je po pięciu słowach. Potem zweryfikujcie razem.';

  @override
  String get pairWayMessage => 'Przez wiadomość';

  @override
  String get pairWayMessageHint => 'Wyślij link w dowolnym czacie.';

  @override
  String get pairWayMessageInfo =>
      'Trzy wiadomości: twoje zaproszenie, odpowiedź, twój link kończący. Kopiuj każdą, gdy przyjdzie; portfel znajdzie ją w schowku, gdy wrócisz. Działa, gdy serwer jest zablokowany albo portfel jest offline.';

  @override
  String get pairWayInPersonDesk => 'Telefon drugiej osoby skanuje twój kod';

  @override
  String get pairGotInvite => 'Masz słowa lub link?';

  @override
  String get pairGotInviteHint => 'Wpisz słowa lub wklej otrzymaną wiadomość.';

  @override
  String get pairHowItWorks => 'Jak działa parowanie';

  @override
  String get pairWordsBothOnline =>
      'Oba portfele muszą być online. Reszta dzieje się sama.';

  @override
  String get pairWordsWaiting => 'Czekam na portfel drugiej osoby…';

  @override
  String get pairUseMessageInstead => 'Zaproś w wiadomości';

  @override
  String get pairAskForMessage =>
      'Poproś drugą osobę o zaproszenie w wiadomości.';

  @override
  String get pairStepInvite => 'Zaproszenie';

  @override
  String get pairStepReply => 'Odpowiedź';

  @override
  String get pairStepFinish => 'Link kończący';

  @override
  String get pairStepWords => 'Słowa';

  @override
  String pairStepOf(int n, String step) {
    return 'Krok $n z 4: $step';
  }

  @override
  String get pairMessageLead =>
      'Wyślij zaproszenie w dowolnym czacie. Odpowiedź wróci tą samą drogą.';

  @override
  String pairInviteMessage(String link) {
    return 'Sparuj się ze mną w BT Wallet: $link';
  }

  @override
  String pairReplyMessage(String link) {
    return 'Moja odpowiedź na parowanie w BT Wallet: $link';
  }

  @override
  String pairFinishMessage(String link) {
    return 'Dokończ nasze parowanie w BT Wallet: $link';
  }

  @override
  String pairFinishLinkMessage(String link) {
    return 'Dokończ parowanie w BT Wallet: $link';
  }

  @override
  String get pairCopyMessage => 'Kopiuj wiadomość';

  @override
  String get pairMessageCopied => 'Skopiowano. Wklej to w czacie.';

  @override
  String get pairAwaitReplyTitle => 'Czekam na odpowiedź';

  @override
  String get pairAwaitReplyBody =>
      'Gdy odpowiedź przyjdzie w czacie, skopiuj ją i wróć. Portfel ją znajdzie.';

  @override
  String get pairByItself =>
      'Gdy oba portfele mają dostęp do serwera Epicbox, ten krok dzieje się też sam.';

  @override
  String get pairPasteReply => 'Wklej odpowiedź';

  @override
  String get pairReplyTitle => 'Wyślij odpowiedź';

  @override
  String pairReplyLead(String name) {
    return 'Odeślij to do $name w tym samym czacie.';
  }

  @override
  String get pairShareReply => 'Udostępnij odpowiedź';

  @override
  String get pairAwaitFinishTitle => 'Czekam na link kończący';

  @override
  String pairAwaitFinishBody(String name) {
    return 'Portfel $name tworzy go z twojej odpowiedzi. Skopiuj go, gdy przyjdzie, i wróć.';
  }

  @override
  String get pairPasteFinish => 'Wklej link kończący';

  @override
  String get pairPasteLink => 'Wklej link';

  @override
  String get pairFinishTitle => 'Wyślij link kończący';

  @override
  String pairFinishLead(String name) {
    return 'Jeszcze jedna wiadomość: portfel $name potrzebuje jej, by pokazać słowa.';
  }

  @override
  String get pairShareFinish => 'Udostępnij link kończący';

  @override
  String get pairFinishThenCheck => 'Potem sprawdźcie razem słowa.';

  @override
  String pairAlreadyPaired(String name) {
    return 'Już sparowano z: $name.';
  }

  @override
  String get pairReplyNotHere =>
      'Ta odpowiedź dotyczy zaproszenia z innego portfela.';

  @override
  String get helpPairWaysTitle => 'Trzy sposoby parowania';

  @override
  String get helpPairWaysShort =>
      'Głosowo, gdy oba portfele są online, wiadomość w dowolnym czacie albo osobiście.';

  @override
  String get helpPairWaysP1 =>
      '**Głosowo.** Jeden portfel pokazuje pięć słów i zostawia zapieczętowane zaproszenie na serwerach połączeń. Drugi portfel wpisuje słowa i je znajduje. Oba portfele muszą być online i mieć dostęp do jednego z tych serwerów.';

  @override
  String get helpPairWaysP2 =>
      '**Zaproszenie w wiadomości.** Trzy wiadomości w dowolnym czacie: zaproszenie, odpowiedź, link kończący. Serwer nie jest potrzebny, więc to działa, gdy sieć blokuje Epicbox. Kopiuj każdą wiadomość, gdy przyjdzie; portfel zaproponuje jej użycie, gdy wrócisz.';

  @override
  String get helpPairWaysP3 =>
      '**Osobiście.** Każdy telefon skanuje kod drugiego. Sieć nie jest używana.';

  @override
  String get helpPairWaysP4 =>
      'Niezależnie od sposobu, na końcu zweryfikujcie razem: porównajcie cztery obrazki i nazwy. Pokazują, że nikt nie zmienił wiadomości po drodze.';

  @override
  String get helpPairClipP =>
      'Portfel czyta schowek tylko wtedy, gdy parowanie jest włączone, tylko gdy wraca na pierwszy plan lub otwiera się ekran parowania, i proponuje każdy link raz. Nigdy nie zapisuje ani nie loguje tego, co przeczytał.';

  @override
  String get pairShareWarning =>
      'Każdy, kto ma to zaproszenie, może się sparować jako ty, dopóki nie wygaśnie. Wyślij je tylko właściwej osobie, a potem zweryfikujcie razem.';

  @override
  String get pairShareInvite => 'Udostępnij zaproszenie';

  @override
  String get pairCopyInvite => 'Kopiuj zaproszenie';

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
    return 'Prośba o sparowanie od: $name';
  }

  @override
  String get pairVerifiedService => 'Zweryfikowana usługa BT Labs';

  @override
  String pairCallsThemselves(String name) {
    return 'Przedstawia się jako „$name”';
  }

  @override
  String pairIncomingBody(String name) {
    return 'Po sparowaniu pliki transakcji i faktury między tobą a $name są zapieczętowane. Następnie zweryfikujecie razem.';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return 'Zezwól $name na prośby o płatność';
  }

  @override
  String get pairIncomingAllowHintDesktop =>
      'Włącza się po weryfikacji. Nic nie zostanie zapłacone bez hasła portfela.';

  @override
  String get pairIncomingAllowHint =>
      'Włącza się po weryfikacji. Nic nie zostanie zapłacone bez twojego PIN-u.';

  @override
  String get pairNotNow => 'Nie teraz';

  @override
  String get pairWaitingBody =>
      'Drugi portfel odpowie, gdy zostanie otwarty. Możesz zamknąć ten ekran; weryfikacja pojawi się po zakończeniu parowania.';

  @override
  String get pairSendByHand => 'Wyślij ręcznie';

  @override
  String get pairReplyLateTitle => 'Jeszcze nie sparowane?';

  @override
  String pairReplyLateBody(String name) {
    return 'Twoja odpowiedź poszła do $name przez serwer Epicbox. Jeśli ich portfel jest zamknięty albo nie ma dostępu do serwera, wyślij odpowiedź w czacie.';
  }

  @override
  String get pairRelayUnreachableTitle => 'Brak połączenia z serwerem';

  @override
  String get pairRelayUnreachableBody => 'Wysłać odpowiedź ręcznie?';

  @override
  String get pairRelayUnreachableTor =>
      'Brak połączenia z serwerem przez Tor. Wysłać odpowiedź ręcznie?';

  @override
  String get pairNoRelay =>
      'Brak połączenia z żadnym serwerem połączeń. Sparuj zamiast tego linkiem z zaproszeniem.';

  @override
  String get pairRelaysBlocked =>
      'Ta sieć blokuje serwery połączeń. Przyczyną może być filtr sieciowy. Sparuj zamiast tego linkiem z zaproszeniem.';

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
    return 'Poproś o nowe.';
  }

  @override
  String get pairUsedTitle => 'To zaproszenie zostało już użyte';

  @override
  String get pairUsedBody => 'Poproś o nowe.';

  @override
  String pairCancelledTitle(String name) {
    return '$name anulował(a) to parowanie';
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
  String pairWaitingFinish(String name) {
    return 'Czekam, aż $name zakończy parowanie…';
  }

  @override
  String get pairNotCompletedTitle => 'Nie ukończono';

  @override
  String pairNotCompletedBody(String name) {
    return 'Portfel $name nie zakończył parowania na czas. Nic nie zostało zapisane. Spróbuj ponownie.';
  }

  @override
  String get pairLateCheck => 'Sprawdzam, czy przyszła spóźniona odpowiedź…';

  @override
  String noticeUnpaired(String name) {
    return '$name: parowanie usunięte.';
  }

  @override
  String trustRemovedBy(String name) {
    return 'Usunięte przez $name';
  }

  @override
  String get trustRemovedShort => 'Usunięte';

  @override
  String get pairChangedTitle => 'To zaproszenie zostało zmienione po drodze';

  @override
  String pairChangedBody(String name) {
    return 'Nic nie zostało zapisane. Sparuj się ponownie, osobiście lub z nowym zaproszeniem od $name.';
  }

  @override
  String get pairNewerTitle => 'Zaktualizuj BT Wallet, aby to otworzyć';

  @override
  String get pairNewerInviteBody => 'To zaproszenie utworzył nowszy portfel.';

  @override
  String get pairNewerFileBody => 'Plik zapieczętował nowszy portfel.';

  @override
  String get pairCheckForUpdates => 'Sprawdź aktualizacje';

  @override
  String pairSecondReplyTitle(String name) {
    return 'Ktoś inny też odpowiedział na twoje zaproszenie';
  }

  @override
  String get pairAnsweredSameInvite =>
      'Odpowiedź na to samo zaproszenie · nie zapisano';

  @override
  String get sasTitle => 'Sprawdź słowa';

  @override
  String sasLead(String name) {
    return 'Portfel $name pokazuje te same cztery. Porównajcie je.';
  }

  @override
  String sasLeadExchange(String name) {
    return 'Strona $name pokazuje te same cztery. Porównaj je, a potem potwierdź po obu stronach.';
  }

  @override
  String sasLeadRecheck(String name) {
    return 'Portfel $name pokazuje je w $name › Sprawdź słowa. Porównajcie je przez telefon lub osobiście.';
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
      'Parowanie kończy się po obu stronach i nic, co przez nie wysłano, nie zostanie dokończone. Sparuj ponownie z nowym zaproszeniem.';

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
    return 'Zweryfikowano $date';
  }

  @override
  String get contactCheckAgain => 'Sprawdź ponownie';

  @override
  String get contactCheckWordsAgain => 'Zweryfikuj ponownie';

  @override
  String get contactSealPayments => 'Pieczętuj pliki transakcji';

  @override
  String contactSealInfo(String name) {
    return 'Pliki transakcji są szyfrowane (pieczętowane). Tylko portfel $name może je odczytać.';
  }

  @override
  String contactSealInfoMore(String name) {
    return 'Po wyłączeniu plik transakcji dla $name jest jawny: każdy, kto go dostanie, może go odczytać. Wyłącz tylko wtedy, gdy portfel $name nie otwiera zapieczętowanych plików.';
  }

  @override
  String get contactAllowInvoices => 'Zezwól na faktury';

  @override
  String contactAllowInfoDesktop(String name) {
    return 'Portfel $name może wysyłać ci faktury. Każda czeka w Fakturach na twoją zgodę i hasło portfela. Nic nie płaci się samo.';
  }

  @override
  String contactAllowInfo(String name) {
    return 'Portfel $name może wysyłać ci faktury. Każda czeka w Fakturach na twoją zgodę i PIN. Nic nie płaci się samo.';
  }

  @override
  String get contactAllowInfoMore =>
      'Zezwolić można tylko zweryfikowanemu kontaktowi: weryfikacja wyklucza podmienione zaproszenie.';

  @override
  String get contactCheckWordsFirst => 'Najpierw zweryfikuj';

  @override
  String get contactPausedUntilChecked => 'Wstrzymane do weryfikacji';

  @override
  String contactDeliveredVia(String relay) {
    return 'Dostarczane przez $relay';
  }

  @override
  String get contactDomain => 'Domena';

  @override
  String get contactDomainVerified => 'zweryfikowana';

  @override
  String get contactDomainNotVerified => 'jeszcze niezweryfikowana';

  @override
  String get contactDomainRefused => 'odrzucona';

  @override
  String relayMoveTitle(String name) {
    return '$name ma nowy przekaźnik';
  }

  @override
  String relayMoveBody(String name, String relay) {
    return '$name prosi, żeby od teraz wysyłać przez $relay. Jeśli odmówisz, nic się nie zmieni, a $name się o tym nie dowie.';
  }

  @override
  String relayMoveAddsServer(String relay) {
    return 'Akceptacja doda też $relay do twoich serwerów Epicbox.';
  }

  @override
  String get relayMoveAccept => 'Akceptuj';

  @override
  String get relayMoveRefuse => 'Odmów';

  @override
  String contactMoveAsked(String relay) {
    return 'Prosi o przejście na $relay';
  }

  @override
  String contactMoveRefused(String relay) {
    return 'Przejście na $relay odrzucone.';
  }

  @override
  String contactMoveNotPublic(String relay) {
    return 'Prośba o przejście na $relay. Nie wykonano: to nie jest publiczny przekaźnik.';
  }

  @override
  String contactMovedOn(String date) {
    return 'Przejście tutaj: $date';
  }

  @override
  String sendViaMailboxMovedHint(String relay, String date) {
    return 'Zapieczętowane. Dostarczane przez $relay, przejście tutaj: $date';
  }

  @override
  String contactRelayDownTitle(String name) {
    return 'Serwer $name nie odpowiada';
  }

  @override
  String get contactRelayDownBody =>
      'Ponawianie. Faktury i płatności czekają, aż odpowie.';

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
      'Może to oznaczać, że ta osoba używa teraz innego portfela albo że ktoś inny używa jej nazwy. Zweryfikuj kontakt ponownie.';

  @override
  String get contactKeysChangedStatus => 'Pieczętowanie i faktury wstrzymane';

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
    return 'Ostatni plik transakcji dla $name poszedł jawnie';
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
    return 'Zaproszenie głosowe · wygasa za $time';
  }

  @override
  String get pendingExpired => 'Wygasło';

  @override
  String get pendingInviteAgain => 'Zaproś ponownie';

  @override
  String get pendingWaitingConfirm => 'Czeka na potwierdzenie';

  @override
  String get pendingPairedCheck => 'Sparowany · zweryfikuj';

  @override
  String get pendingEmpty =>
      'Brak oczekujących zaproszeń. Zaproszenie widać tutaj, dopóki drugi portfel na nie nie odpowie.';

  @override
  String get pendingShareAgain => 'Udostępnij ponownie';

  @override
  String get pendingShowWords => 'Pokaż zaproszenie';

  @override
  String get invSetTitle => 'Faktury';

  @override
  String get invSetLead =>
      'Sparowany kontakt, któremu zezwolisz, może wysyłać ci faktury. Każda czeka w Fakturach na twój PIN.';

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
      'Brak sparowanych kontaktów. Sparuj się ze sklepem, giełdą lub osobą, zweryfikuj, a potem zezwól tutaj na ich faktury.';

  @override
  String get invSetPausedBody =>
      'Faktury czekają na serwerze i dotrą, gdy Epicbox znów będzie włączony.';

  @override
  String invSetSwitchedOff(String name) {
    return 'Faktury od $name są wyłączone.';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odrzucono $count otwartej faktury.',
      many: 'Odrzucono $count otwartych faktur.',
      few: 'Odrzucono $count otwarte faktury.',
      one: 'Odrzucono $count otwartą fakturę.',
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
  String get reqTitle => 'Sprawdź fakturę';

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
  String get reqPaidWaitingBodyPerson =>
      'Twoja część jest skończona. Portfel drugiej strony finalizuje i publikuje; to zamknie się samo.';

  @override
  String get reqPaidWaitingBody =>
      'Twoja część jest skończona. Druga strona finalizuje i publikuje; to zamknie się samo.';

  @override
  String get reqTlPaid => 'Zapłacono';

  @override
  String get reqTlDelivered => 'Dostarczono przez Epicbox';

  @override
  String get reqTlAnswerDelivered => 'Odpowiedź dostarczona przez Epicbox';

  @override
  String reqTlPosted(String name) {
    return 'Opublikowane przez $name';
  }

  @override
  String get reqTlConfirming => 'Potwierdzanie';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n z $total potwierdzeń';
  }

  @override
  String get reqTlConfirmed => 'Potwierdzone';

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
      'Monety zostaną odblokowane, jeśli płatność nie zostanie opublikowana. Dostarczanie jest ponawiane.';

  @override
  String get reqRelayRetrying => 'Serwer nie odpowiada · ponawianie';

  @override
  String reqWithdrewTitle(String name) {
    return '$name wycofał(a) fakturę';
  }

  @override
  String get reqWithdrewBody =>
      'Twoje środki są odblokowane. Nic nie zostało zapłacone.';

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name wysłał(a) w ciągu 10 minut $count faktury o $amount EPIC. Zapłacić wszystkie?',
      many:
          '$name wysłał(a) w ciągu 10 minut $count faktur o $amount EPIC. Zapłacić wszystkie?',
      few:
          '$name wysłał(a) w ciągu 10 minut $count faktury o $amount EPIC. Zapłacić wszystkie?',
      one:
          '$name wysłał(a) w ciągu 10 minut $count fakturę o $amount EPIC. Zapłacić?',
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
      'Nic nie musisz robić. Nadawca publikuje płatność; potwierdzenia przyjdą później.';

  @override
  String get reqNewTitle => 'Nowa faktura';

  @override
  String get reqNewLead =>
      'Poproś sparowany kontakt o zapłatę lub zapisz fakturę jako plik dla kogokolwiek.';

  @override
  String get reqNewLeadContacts => 'Poproś sparowany kontakt o zapłatę.';

  @override
  String get reqNewTo => 'Do';

  @override
  String get reqNewToHintContacts =>
      'Sparowane kontakty, których portfel opłaca faktury.';

  @override
  String get reqNoPayersContacts =>
      'Żaden sparowany kontakt nie opłaca jeszcze faktur. Sparuj się i zweryfikuj.';

  @override
  String get reqNewToHint =>
      'Sparowane kontakty, których portfel opłaca faktury. Dla innych: zapisz fakturę jako plik.';

  @override
  String get reqNewSend => 'Wyślij fakturę';

  @override
  String get sendViaMailbox => 'Wyślij przez parowanie';

  @override
  String sendViaMailboxHint(String relay) {
    return 'Zapieczętowane. Dostarczane przez $relay';
  }

  @override
  String sendViaPublicHint(String name) {
    return 'Trafi na publiczny adres Epicbox $name.';
  }

  @override
  String sendMailboxUnanswered(String date) {
    return 'Brak odpowiedzi przez parowanie od $date.';
  }

  @override
  String get sendPublicFallback => 'Wyślij na publiczny adres Epicbox kontaktu';

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
    return '$name odpowiada. Zweryfikujcie razem.';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'Sparowano z: $name. Zweryfikujcie razem.';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name prosi o $amount EPIC.';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return 'Odebrano $amount EPIC od $name.';
  }

  @override
  String noticeKeysChanged(String name) {
    return 'Klucze $name się zmieniły. Zweryfikuj ponownie.';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return 'Kontakt $name jest sparowany z nowymi kluczami. Starych kluczy nie dało się sprawdzić: jest jedno sprawdzenie na dobę i już się odbyło.';
  }

  @override
  String noticeRelayDown(String name) {
    return 'Serwer Epicbox $name nie odpowiada.';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name wycofał(a) fakturę. Środki odblokowane.';
  }

  @override
  String get restoreUseContactsTitle => 'Używać kontaktów na tym urządzeniu?';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count parowania z tego pliku było używane na innym urządzeniu. Drugie urządzenie powinno przestać ich używać.',
      many:
          '$count parowań z tego pliku było używanych na innym urządzeniu. Drugie urządzenie powinno przestać ich używać.',
      few:
          '$count parowania z tego pliku były używane na innym urządzeniu. Drugie urządzenie powinno przestać ich używać.',
      one:
          '$count parowanie z tego pliku było używane na innym urządzeniu. Drugie urządzenie powinno przestać go używać.',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => 'Używaj tutaj';

  @override
  String get pairInvalidLink => 'To nie jest zaproszenie do parowania.';

  @override
  String get pairInvalidBody =>
      'Sprawdź, czy skopiowano całe zaproszenie, albo poproś o nowe.';

  @override
  String get pairWrongNetworkBody => 'To zaproszenie jest dla innej sieci.';

  @override
  String get pairOwnCode => 'To twój własny kod';

  @override
  String get pairOwnCodeBody => 'Zeskanuj kod na drugim telefonie.';

  @override
  String get pairUnnamedInvite => 'Otwarte zaproszenie';

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
      'Sparowany kontakt, któremu zezwolisz, może wysyłać do tego portfela faktury. Każda czeka w Fakturach na hasło portfela.';

  @override
  String get invSetRowAllowed => 'Zweryfikowany · dozwolone';

  @override
  String get invSetRowOff => 'Zweryfikowany · wyłączone';

  @override
  String get invSetRowCheckFirst =>
      'Sparowany, niezweryfikowany · najpierw zweryfikuj';

  @override
  String invSetAllowFor(String name) {
    return 'Zezwól na faktury od $name';
  }

  @override
  String get reqNoPayers =>
      'Żaden sparowany kontakt nie opłaca jeszcze faktur. Sparuj się i zweryfikuj lub zapisz fakturę jako plik.';

  @override
  String get reqPickContact => 'Wybierz kontakt';

  @override
  String get reqFileSaved => 'Faktura zapisana jako plik';

  @override
  String reqSent(String name) {
    return 'Faktura wysłana do $name';
  }

  @override
  String get reqFileTitle => 'Faktura';

  @override
  String noticeOutboxStuck(String name) {
    return 'Brak kontaktu z $name. Ponawianie próby.';
  }

  @override
  String noticeTooMany(String name) {
    return '$name wysyła za dużo faktur.';
  }

  @override
  String get noticeOpen => 'Otwórz';

  @override
  String get noticeCheckWords => 'Zweryfikuj';

  @override
  String get noticeView => 'Pokaż';

  @override
  String pairSaveContactTitle(String name) {
    return 'Zapisać $name w kontaktach?';
  }

  @override
  String get pairSaveNewContact => 'Zapisz jako nowy kontakt';

  @override
  String pairOtherAddressTitle(String name) {
    return 'Nie dodano do kontaktu $name';
  }

  @override
  String pairOtherAddressBody(String name) {
    return 'Kontakt $name ma adres Epicbox, którego to parowanie nie może potwierdzić.';
  }

  @override
  String get pairOtherAddress =>
      'Ten kontakt ma adres Epicbox, którego to parowanie nie może potwierdzić.';

  @override
  String pairAddToNamed(String name) {
    return 'Dodaj do kontaktu $name';
  }

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
  String get helpPairingSection => 'Parowanie';

  @override
  String get helpPairingLede =>
      'Sparuj się raz; płatności, pliki transakcji i faktury z tym kontaktem są zapieczętowane.';

  @override
  String get helpPairWhatTitle => 'Czym jest parowanie';

  @override
  String get helpPairWhatShort =>
      'Sparuj się raz z drugą osobą; potem płatności, pliki transakcji i faktury między dwoma portfelami są zapieczętowane.';

  @override
  String get helpPairWhatP1 =>
      'Parowanie łączy dwa portfele raz: prośbą do kontaktu, któremu płaciłeś przez Epicbox, albo twoim zaproszeniem, zeskanowanym jako QR lub otwartym jako link. Każdy portfel trzyma klucz zrobiony tylko dla tego jednego kontaktu; z nikim innym nic nie jest dzielone.';

  @override
  String get helpPairWhatP2 =>
      'Po sparowaniu płatności, pliki transakcji i faktury między dwoma portfelami są **zapieczętowane**: odczytać je może tylko drugi portfel, a tożsamość kontaktu jest sprawdzana. Płatności domyślnie idą przez parowanie; zobacz „Płatności po sparowaniu”.';

  @override
  String get helpPairWhatStep1 =>
      'Otwórz [[Kontakty|Contacts]] i wybierz **Sparuj**.';

  @override
  String get helpPairWhatStep2 =>
      'Sparuj z kontaktem albo pokaż swoje zaproszenie i daj je zeskanować.';

  @override
  String get helpPairWhatStep3 =>
      'Sprawdźcie słowa razem (po prośbie niepotrzebne), potem **Zgadzają się**.';

  @override
  String get helpPairWhatP3 =>
      'Parowanie wymaga BT Wallet po obu stronach. Niesparowany kontakt nadal dostaje zwykłe pliki transakcji i płatności na swój publiczny adres Epicbox.';

  @override
  String get helpPairWhyTitle => 'Po co weryfikować';

  @override
  String get helpPairWhyShort =>
      'Weryfikacja dowodzi, że parowanie trafiło do właściwego portfela, a nie do kogoś pośrodku.';

  @override
  String get helpPairWhyP1 =>
      'Po sparowaniu oba portfele pokazują te same cztery obrazki z nazwami. Powstają z kluczy obu portfeli, więc parowanie zmienione po drodze pokaże na dwóch ekranach różne słowa.';

  @override
  String get helpPairWhyP2 =>
      'Porównajcie je przez telefon lub osobiście, a potem dotknij **Zgadzają się**. Kontakt staje się **Zweryfikowany**. **Pomiń na razie** zostawia go jako **Sparowany, niezweryfikowany**: pliki transakcji są nadal zapieczętowane, ale kontakt nie może wysyłać faktur, dopóki słowa nie zostaną sprawdzone.';

  @override
  String get helpPairWhyP3 =>
      'Jeśli słowa się różnią, dotknij **Nie zgadzają się**. Parowanie zostaje odrzucone po tej stronie. Sparuj się ponownie, osobiście lub z nowym zaproszeniem.';

  @override
  String get helpPairWhyP4 =>
      'Nazwy słów pozostają po angielsku w każdym języku, aby dwie osoby, których portfele działają w różnych językach, mogły je porównać.';

  @override
  String get helpPairWordsTitle => 'Zaproszenia głosowe';

  @override
  String get helpPairWordsShort =>
      'Pięć obrazków z nazwami zastępuje link, gdy nie ma czego zeskanować ani wkleić.';

  @override
  String get helpPairWordsP1 =>
      'Gdy jeden portfel nie ma aparatu albo zaproszenia nie da się wysłać jako linku, zapraszający portfel pokazuje pięć słów parowania. Druga osoba wpisuje ich nazwy w **Masz słowa lub link?**; pole uzupełnia każdą nazwę po kilku literach. Słowa są ważne przez 10 minut.';

  @override
  String get helpPairWordsP2 =>
      'Słowa tylko odnajdują zaproszenie. Kto je zna, jest w tej samej sytuacji co ktoś, kto dostał link, więc jak zwykle sprawdźcie potem razem cztery słowa.';

  @override
  String get helpPairWordsP3 =>
      'Zaproszenia głosowe wymagają Epicbox. Gdy Epicbox jest wyłączony, wyślij link z zaproszeniem.';

  @override
  String get helpPairInvTitle => 'Faktury od sparowanych kontaktów';

  @override
  String get helpPairInvShortDesktop =>
      'Tylko zweryfikowany kontakt, któremu zezwolisz, może prosić cię o zapłatę. Każda faktura czeka na hasło portfela.';

  @override
  String get helpPairInvShort =>
      'Tylko zweryfikowany kontakt, któremu zezwolisz, może prosić cię o zapłatę. Każda faktura czeka na twój PIN.';

  @override
  String get helpPairInvP1 =>
      'Sklep, giełda lub osoba, z którą jesteś sparowany, może wysyłać faktury, jeśli na to zezwolisz: **Zezwól na faktury** na stronie kontaktu lub w [[Ustawienia › Faktury|Settings › Invoices]]. Przełącznik działa tylko dla zweryfikowanego kontaktu.';

  @override
  String get helpPairInvP2Desktop =>
      'Faktura pojawia się w [[Faktury › Zapłać|Invoices › Pay]] z nazwą kontaktu, kwotą i numerem referencyjnym. Nic nie zostanie zapłacone, dopóki nie zatwierdzisz jej hasłem portfela. Faktura nigdy nie dodaje pieniędzy do portfela.';

  @override
  String get helpPairInvP2 =>
      'Faktura pojawia się w [[Faktury › Zapłać|Invoices › Pay]] z nazwą kontaktu, kwotą i numerem referencyjnym. Nic nie zostanie zapłacone, dopóki nie zatwierdzisz jej PIN-em. Faktura nigdy nie dodaje pieniędzy do portfela.';

  @override
  String get helpPairInvP3 =>
      'Wyłączenie przełącznika działa od razu: nowe faktury od tego kontaktu przepadają, a otwarte zostają odrzucone.';

  @override
  String get helpPairInvP4 =>
      'Giełda sparowana z tobą tędy obsługuje wpłaty i wypłaty. Wpłata: giełda prosi, ty zatwierdzasz, giełda publikuje. Wypłata: giełda wysyła płatność, twój portfel sam odpowiada, giełda publikuje.';

  @override
  String get helpPairRestoreTitle => 'Co daje przywrócenie';

  @override
  String get helpPairRestoreShort =>
      'Przywrócenie z frazy odzyskiwania z plikiem danych portfela przywraca każde parowanie; bez niego ponowne parowanie odnajduje te same klucze.';

  @override
  String get helpPairRestoreP1 =>
      'Z plikiem danych portfela przywrócenie odtwarza każde parowanie bez zmian: te same klucze, te same oznaczenia Zweryfikowany, te same ustawienia. Kontakty niczego nie zauważą.';

  @override
  String get helpPairRestoreP2 =>
      'Bez pliku parowania znikają z tego portfela, ale klucze nie: powstają z frazy odzyskiwania. Sparuj się ponownie z kontaktem, który zachował parowanie, a jego portfel odnajdzie te same klucze. Pokaże, że klucze wróciły, a kontakt zachowa oznaczenie Zweryfikowany. W tym portfelu Pieczętuj pliki transakcji i Zezwól na faktury wracają do ustawień domyślnych.';

  @override
  String get helpPairRestoreP3 =>
      'Kontakt widzi **Klucze zmienione** tylko wtedy, gdy fraza jest inna. Może to oznaczać nowy portfel albo kogoś innego, kto używa tej nazwy. Sprawdź słowa ponownie, zanim temu zaufasz.';

  @override
  String get helpPairRestoreP4 =>
      'Używaj parowania na jednym urządzeniu naraz. Dane portfela zaimportowane na drugim urządzeniu zapytają, zanim użyją tam kontaktów.';

  @override
  String get pairNameForCode =>
      'Wpisz nazwę, którą zobaczy druga strona, a tutaj pojawi się twój kod.';

  @override
  String get deskConPickForPairing =>
      'Parowanie zostanie dodane do wybranego kontaktu.';

  @override
  String txDetailsCancelHold(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Anulowanie będzie możliwe za $minutes minuty, jeśli nadawca do tego czasu nie opublikuje płatności.',
      many:
          'Anulowanie będzie możliwe za $minutes minut, jeśli nadawca do tego czasu nie opublikuje płatności.',
      few:
          'Anulowanie będzie możliwe za $minutes minuty, jeśli nadawca do tego czasu nie opublikuje płatności.',
      one:
          'Anulowanie będzie możliwe za $minutes minutę, jeśli nadawca do tego czasu nie opublikuje płatności.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsCancelWhileReported =>
      'Anulowanie jest niedostępne, gdy nadawca zgłasza, że opublikował płatność.';

  @override
  String get txDetailsCancelRefusedOnNetwork =>
      'Nie anulowano: sieć już ma tę płatność. Zakończy się, gdy blockchain ją potwierdzi.';

  @override
  String get contactStar => 'Oznacz gwiazdką';

  @override
  String get contactUnstar => 'Usuń gwiazdkę';

  @override
  String get contactStarred => 'Oznaczony gwiazdką';

  @override
  String get contactsImport => 'Importuj kontakty';

  @override
  String get contactsExport => 'Eksportuj kontakty';

  @override
  String contactsExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wyeksportowano $count kontaktu',
      many: 'Wyeksportowano $count kontaktów',
      few: 'Wyeksportowano $count kontakty',
      one: 'Wyeksportowano $count kontakt',
    );
    return '$_temp0';
  }

  @override
  String get contactsExportHolds =>
      'Plik zawiera nazwy, notatki i adresy. Bez kluczy i parowań.';

  @override
  String get contactsImportTitle => 'Zaimportować kontakty?';

  @override
  String contactsImportNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nowego kontaktu',
      many: '$count nowych kontaktów',
      few: '$count nowe kontakty',
      one: '$count nowy kontakt',
    );
    return '$_temp0';
  }

  @override
  String contactsImportMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kontaktu zaktualizowanego',
      many: '$count kontaktów zaktualizowanych',
      few: '$count kontakty zaktualizowane',
      one: '$count kontakt zaktualizowany',
    );
    return '$_temp0';
  }

  @override
  String contactsImportSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count już zapisanego',
      many: '$count już zapisanych',
      few: '$count już zapisane',
      one: '$count już zapisany',
    );
    return '$_temp0';
  }

  @override
  String contactsImportLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pominięto $count: brak adresu, na który ten portfel może wysłać',
      many: 'Pominięto $count: brak adresu, na który ten portfel może wysłać',
      few: 'Pominięto $count: brak adresu, na który ten portfel może wysłać',
      one: 'Pominięto $count: brak adresu, na który ten portfel może wysłać',
    );
    return '$_temp0';
  }

  @override
  String contactsImportOtherNet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pominięto $count: adresy innej sieci',
      many: 'Pominięto $count: adresy innej sieci',
      few: 'Pominięto $count: adresy innej sieci',
      one: 'Pominięto $count: adres innej sieci',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportKeeps => 'Istniejące dane pozostają.';

  @override
  String get contactsImportDo => 'Importuj';

  @override
  String get contactsImportNothing => 'Nie ma czego importować.';

  @override
  String contactsImported(int added, int same) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Dodano $added kontaktu',
      many: 'Dodano $added kontaktów',
      few: 'Dodano $added kontakty',
      one: 'Dodano $added kontakt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      same,
      locale: localeName,
      other: '$same już zapisanego',
      many: '$same już zapisanych',
      few: '$same już zapisane',
      one: '$same już zapisany',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String contactsImportedAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Dodano $added kontaktu',
      many: 'Dodano $added kontaktów',
      few: 'Dodano $added kontakty',
      one: 'Dodano $added kontakt',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportNotFile => 'Ten plik nie jest plikiem kontaktów.';

  @override
  String get contactsImportDamaged =>
      'Nie udało się odczytać pliku. Może być uszkodzony.';

  @override
  String get contactsImportNewer =>
      'Ten plik pochodzi z nowszej wersji BT Wallet. Zaktualizuj aplikację, aby go zaimportować.';

  @override
  String get contactsImportEmpty => 'Plik nie zawiera kontaktów.';

  @override
  String get contactsImportAllOtherNet =>
      'Te kontakty są z innej sieci. Żadnego nie można tu użyć.';

  @override
  String get expPairing => 'Parowanie';

  @override
  String get expPairingHint =>
      'Jednorazowe sparowanie z kimś, z kim często są płatności: pliki transakcji i faktury między dwoma portfelami są wtedy zapieczętowane, a kontakt jest oznaczony jako sparowany. Eksperymentalne: może się jeszcze zmienić.';

  @override
  String get expInvoices => 'Faktury';

  @override
  String get expInvoicesHint =>
      'Prośba o płatność do sparowanego kontaktu i zatwierdzanie faktur od sparowanych kontaktów. Wymaga parowania. Eksperymentalne: może się jeszcze zmienić.';

  @override
  String get expNeedsPairing => 'Faktury wymagają parowania.';

  @override
  String get expPairingOffTitle => 'Parowanie jest eksperymentalne';

  @override
  String get expPairingOffBody =>
      'Można je włączyć w Ustawienia › Zaawansowane.';

  @override
  String get expInvoicesOffTitle => 'Faktury są eksperymentalne';

  @override
  String get expInvoicesOffBody =>
      'Można je włączyć w Ustawienia › Zaawansowane.';

  @override
  String get expOpenAdvanced => 'Otwórz Zaawansowane';

  @override
  String get contactNoAddressPaired => 'Płatności idą przez parowanie';

  @override
  String get contactSendKeysChanged => 'Przed wysłaniem zweryfikuj kontakt.';

  @override
  String contactSendNoSealed(String name) {
    return 'Portfel $name nie przyjmuje płatności przez parowanie. Poproś o adres.';
  }

  @override
  String sendRecipientPairing(String name) {
    return 'Przez parowanie z $name';
  }

  @override
  String get sendClearRecipient => 'Wyczyść odbiorcę';

  @override
  String get sendQueuedEpicboxOff =>
      'Epicbox jest wyłączony. Płatność czeka tutaj i wyjdzie, gdy Epicbox znów będzie włączony.';

  @override
  String get sendQueue => 'Dodaj płatność do kolejki';

  @override
  String get sendQueuedHeadline => 'Płatność w kolejce';

  @override
  String sendQueuedBody(String name) {
    return 'Wyjdzie, gdy Epicbox znów będzie włączony. Odpowiedź $name wróci tą samą drogą.';
  }

  @override
  String txStatusWaitingFor(String name) {
    return 'Czeka na: $name';
  }

  @override
  String txStepSentMailbox(String name) {
    return 'Wysłano przez serwer Epicbox $name';
  }

  @override
  String txStepAnswerFrom(String name) {
    return 'Odpowiedź od $name';
  }

  @override
  String txStepCollecting(String name) {
    return 'Sprawdzanie serwera Epicbox $name';
  }

  @override
  String deskTxStatusWaitingFor(String name) {
    return 'Czeka na podpis: $name';
  }

  @override
  String deskSendContactNoLink(String name) {
    return '$name nie ma adresu Link.';
  }

  @override
  String get reqToFile => 'Zapisz jako plik dla kogokolwiek';

  @override
  String reqFileSummary(String amount) {
    return 'Każdy, kto otworzy plik, może zapłacić $amount. Odpowiedź wraca jako plik.';
  }

  @override
  String get reqSaveFile => 'Zapisz jako plik';

  @override
  String get reqFileLead =>
      'Wyślij ten plik osobie, która ma zapłacić. Jej portfel odpowie plikiem; otwórz go tutaj, aby dokończyć.';

  @override
  String get reqByFile => 'Plikiem';

  @override
  String get reqToAnyone => 'Każdy, kto ma plik';

  @override
  String get reqFileWaitingCard =>
      'Czeka na plik odpowiedzi. Otwórz go w Odbierz lub dotykając go.';

  @override
  String get reqFromFileTitle => 'Faktura z pliku';

  @override
  String get reqFromFileWarn =>
      'Nic nie wskazuje, kto utworzył tę fakturę. Zapłać tylko, jeśli spodziewałeś się jej od kogoś, kogo znasz.';

  @override
  String get reqFileMessageLabel => 'Wiadomość w pliku';

  @override
  String get reqApproveSaveAnswer => 'Zatwierdź i zapisz odpowiedź';

  @override
  String get reqNotNow => 'Nie teraz';

  @override
  String get reqAnswerTitle => 'Zapisano odpowiedź';

  @override
  String get reqAnswerLead =>
      'Odeślij ten plik osobie, która prosiła. Ona dokończy płatność i wyśle ją do sieci.';

  @override
  String get reqFileAlreadyPaid => 'Ta faktura jest już opłacona.';

  @override
  String get reqFileEnded => 'Ta faktura jest już nieaktualna.';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return 'Odpowiedź na twoją fakturę: $amount.';
  }

  @override
  String get reqAnswerUnknown =>
      'To odpowiedź na fakturę, której ten portfel już nie ma.';

  @override
  String get deskInvIssuerAnother => 'Kolejna faktura';

  @override
  String get deskImpOpenAnother => 'Otwórz kolejny plik';

  @override
  String get deskInvIssuerToAnyone => 'Faktura dla każdego, kto ma plik';

  @override
  String deskOnbImportRelayTitle(String name) {
    return 'Serwer Epicbox dla $name';
  }

  @override
  String deskOnbImportRelayLead(String old) {
    return 'Starsza aplikacja odbierała przez $old.';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return 'Zachowaj $old';
  }

  @override
  String get deskOnbImportRelayKeepHint =>
      'Ten sam adres; serwer trafia na listę Epicbox.';

  @override
  String deskOnbImportRelayApp(String current) {
    return 'Użyj $current';
  }

  @override
  String get deskOnbImportRelayAppHint =>
      'Nowy adres: płatności na stary nie dotrą.';

  @override
  String get deskOnbImportUnlockOld => 'Odblokuj starym hasłem.';

  @override
  String get deskOnbImportUnlockNew => 'Odblokuj nowym hasłem wybranym tutaj.';

  @override
  String get deskOnbWelcomeOtherApps =>
      'Ze Stack Wallet lub Epic Pay: przywróć z frazy odzyskiwania.';

  @override
  String get deskOnbImportCloseFirstWindows =>
      'Zamknij starszy Epic Wallet przed importem. W systemie Windows nie da się sprawdzić, czy nadal działa.';

  @override
  String get deskSetRecvEpicboxOwnHint =>
      'Ten portfel ma własny serwer Epicbox, zachowany ze starszej aplikacji. Zmiana tutaj dotyczy tylko tego portfela.';

  @override
  String get deskErrRestoreScanRequired =>
      'Przywracanie nieukończone. Odbieranie i wysyłanie będą dostępne, gdy skanowanie łańcucha się zakończy.';

  @override
  String get deskSetupSkip => 'Pomiń konfigurację';

  @override
  String get deskOvRestoreTitle => 'Przywracanie nieukończone';

  @override
  String get deskOvRestoreRunning =>
      'Wyszukiwanie środków tego portfela w łańcuchu. Odebrane EPIC pojawiają się w miarę znajdowania; odbieranie i wysyłanie będą dostępne, gdy skanowanie się zakończy.';

  @override
  String deskOvRestoreAfterHeight(String height) {
    return 'Środki od bloku $height są już widoczne. Wcześniejsze bloki są jeszcze sprawdzane; odbieranie i wysyłanie będą dostępne, gdy to się zakończy.';
  }

  @override
  String get deskOvRestoreWaiting => 'Skanowanie czeka na sieć.';

  @override
  String get deskOvRestoreFailed =>
      'Skanowanie zatrzymało się przed końcem. Odbieranie i wysyłanie pozostają niedostępne, dopóki się nie zakończy.';

  @override
  String get deskOvRestoreProgress => 'Postęp skanowania po przywróceniu';

  @override
  String get deskSetRescanRestoreRunning =>
      'Trwa skanowanie po przywróceniu. Sprawdź saldo będzie dostępne, gdy się zakończy.';

  @override
  String get deskSetRescanStartHeading => 'Od czego zacząć';

  @override
  String get deskOnbForgotLink => 'Nie pamiętasz hasła?';

  @override
  String get deskOnbForgotTitle => 'Ustaw nowe hasło';

  @override
  String deskOnbForgotLead(String name) {
    return 'Fraza odzyskiwania portfela $name zastępuje jego hasło. Historia, notatki i etykiety zostają; skanowanie nie jest potrzebne.';
  }

  @override
  String get deskOnbForgotPasswordLead =>
      'Fraza się zgadza. Wybierz nowe hasło, które odblokuje ten portfel na tym komputerze.';

  @override
  String get deskOnbForgotSet => 'Ustaw hasło';

  @override
  String deskOnbForgotOtherWallet(String name) {
    return 'Ta fraza należy do innego portfela, nie do $name. Nic nie zmieniono.';
  }

  @override
  String get deskOnbSameNewPassword => 'Ustaw nowe hasło';

  @override
  String get deskSetupSkipKeeps =>
      'Pominięcie zachowuje obecne ustawienia węzła i Epicbox.';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return 'Nie udało się zapisać, że konfiguracja jest ukończona: $reason. Może otworzyć się ponownie przy następnym uruchomieniu; „Pomiń konfigurację” ją zamyka.';
  }

  @override
  String get deskOvRestoredImportTitle => 'Portfel przywrócony';

  @override
  String get deskOvRestoredImportBody =>
      'Saldo wróciło. Plik danych tego portfela przywraca historię, kontakty, faktury i ustawienia.';

  @override
  String get deskOvRestoredImportButton => 'Importuj dane portfela';

  @override
  String get deskOvRestoredImportLater =>
      'Później w Ustawienia › Portfel › Kopia zapasowa.';

  @override
  String get deskOnbForgotNoCheck =>
      'Nic w plikach tego portfela nie potwierdzi frazy, więc hasło zostaje.';

  @override
  String deskOnbForgotRestoreHint(String name) {
    return 'Zamiast tego przywróć go z frazy: $name znika z listy, a jego pliki zostają na tym komputerze.';
  }

  @override
  String get deskOnbForgotRestoreInstead => 'Przywróć z frazy';

  @override
  String get qrShowTitleRequest => 'Faktura';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount od telefonu obok ciebie';
  }

  @override
  String get qrHiddenBodyRequest =>
      'Kto go zeskanuje, może opłacić tę fakturę. Pokaż go tylko osobie, która płaci.';

  @override
  String get qrStatusRequestHidden => 'Pokaż to osobie, która płaci.';

  @override
  String get qrStatusRequestShowing =>
      'Czekam, aż zeskanują i zatwierdzą. Potem zeskanuj ich odpowiedź.';

  @override
  String qrSemanticsRequest(String state) {
    return 'Kod QR faktury, $state';
  }

  @override
  String qrShowSubPaid(String amount) {
    return 'Dla osoby, która prosiła o $amount';
  }

  @override
  String get qrHiddenBodyPaid =>
      'Pokaż go telefonowi, który prosił o płatność. Tylko ten portfel może go użyć.';

  @override
  String get qrStatusPaidHidden => 'Pokaż to osobie, która prosiła.';

  @override
  String get qrStatusPaidShowing => 'Czekam, aż zeskanują i wyślą do sieci.';

  @override
  String get qrStatusPaid => 'Zapłacono.';

  @override
  String get reqToQr => 'Pokaż jako QR telefonowi obok';

  @override
  String reqQrSummary(String amount) {
    return 'Kto zeskanuje kod, może zapłacić $amount. Zeskanuj tu ich odpowiedź, by dokończyć. Faktura wygasa za 24 h.';
  }

  @override
  String get reqShowQr => 'Pokaż jako QR';

  @override
  String get receiveQrRequest => 'Poproś o kwotę';

  @override
  String get reqQrPaidTitle => 'Zapłacono';

  @override
  String reqQrPaidHeadline(String amount) {
    return '$amount zapłacone i wysłane do sieci.';
  }

  @override
  String get reqQrNew => 'Nowa faktura';

  @override
  String get reqQrAlreadyPaid =>
      'Ta faktura jest już opłacona. Z tego telefonu nic nie pobrano: jego płatność pozostaje zablokowana, dopóki nie zostanie anulowana w Aktywności albo nie wygaśnie po dniu.';

  @override
  String get reqFromQrTitle => 'Faktura z kodu QR';

  @override
  String get reqFromQrWarn =>
      'Nie od sparowanego kontaktu. Nic w kodzie nie wskazuje, kto go utworzył: zapłać tylko osobie lub sklepowi przed tobą i sprawdź kwotę.';

  @override
  String get reqQrMessageLabel => 'Wiadomość w kodzie';

  @override
  String get reqApproveShowAnswer => 'Zatwierdź i pokaż odpowiedź';

  @override
  String get reqQrAnswerTitle => 'Zatwierdzono';

  @override
  String get reqQrAnswerLead =>
      'Osoba, która prosiła, skanuje odpowiedź i wysyła płatność do sieci. Do tego czasu płatność czeka w Aktywności jako „Czeka na odbiorcę”.';

  @override
  String get reqExpired =>
      'Ta faktura wygasła. Poproś o nową. Nic nie zostało zapłacone.';

  @override
  String get reqOtherChain =>
      'Ta faktura należy do innej sieci Epic albo jej termin nie pasuje do tej sieci. Nic nie zostało zapłacone.';

  @override
  String get reqQrOpenNote =>
      'Otwarta w Faktury › Wysłane przez 24 h, potem wygasa.';

  @override
  String get reqQrWrongReply =>
      'Ta odpowiedź dotyczy innej faktury. Zeskanuj odpowiedź na tę.';

  @override
  String get backupFileHolds =>
      'Zawiera historię płatności, kontakty, faktury i ustawienia tego portfela, stan na teraz.';

  @override
  String get backupFileRestoreOrder =>
      'Aby przywrócić: najpierw wpisz frazę odzyskiwania, potem zaimportuj ten plik.';

  @override
  String get backupImportLead =>
      'Przywraca historię płatności, kontakty, faktury i ustawienia tego portfela. Najpierw przywróć portfel z jego frazy odzyskiwania.';

  @override
  String backupRestoredSummary(String items) {
    return 'Zaimportowano: $items.';
  }

  @override
  String get backupListSeparator => ', ';

  @override
  String get backupListLastSeparator => ' i ';

  @override
  String backupRestoredPayments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n płatności',
      many: '$n płatności',
      few: '$n płatności',
      one: '$n płatność',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredNotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notatki',
      many: '$n notatek',
      few: '$n notatki',
      one: '$n notatkę',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredLabels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n etykiety',
      many: '$n etykiet',
      few: '$n etykiety',
      one: '$n etykietę',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredContacts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kontaktu',
      many: '$n kontaktów',
      few: '$n kontakty',
      one: '$n kontakt',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredStars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kontaktu z gwiazdką',
      many: '$n kontaktów z gwiazdką',
      few: '$n kontakty z gwiazdką',
      one: '$n kontakt z gwiazdką',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredPairings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n parowania',
      many: '$n parowań',
      few: '$n parowania',
      one: '$n parowanie',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredInvoices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n faktury',
      many: '$n faktur',
      few: '$n faktury',
      one: '$n fakturę',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoredSettings => 'ustawienia';

  @override
  String get backupRestoredWalletName => 'nazwę portfela';

  @override
  String backupRestoredAlreadyHere(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n wpisu już istniało.',
      many: '$n wpisów już istniało.',
      few: '$n wpisy już istniały.',
      one: '$n wpis już istniał.',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsTitle => 'Użyć ustawień z tego pliku?';

  @override
  String backupSettingsBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ustawienia tutaj różni się od pliku.',
      many: '$n ustawień tutaj różni się od pliku.',
      few: '$n ustawienia tutaj różnią się od pliku.',
      one: '$n ustawienie tutaj różni się od pliku.',
    );
    return '$_temp0 Reszta pliku jest już zaimportowana.';
  }

  @override
  String get backupSettingsUseBackup => 'Z pliku';

  @override
  String get backupSettingsKeepMine => 'Zachowaj moje';

  @override
  String get deskEpicboxBlockedWord => 'Zablokowany';

  @override
  String deskEpicboxBlockedText(String host) {
    return 'Ta sieć blokuje $host. Wybierz inny serwer Epicbox lub użyj prywatnego DNS.';
  }

  @override
  String deskEpicboxBlockedShort(String host) {
    return 'Ta sieć blokuje $host. Wybierz inny serwer lub prywatny DNS.';
  }

  @override
  String deskEpicboxBlockedSwitch(String host) {
    return 'Przełącz na $host';
  }

  @override
  String get deskSlotNow => 'Teraz';

  @override
  String get deskSlotHelp => 'Pomoc';

  @override
  String get deskSlotScanning => 'Skanowanie łańcucha';

  @override
  String get deskSlotScanWaits => 'Skanowanie czeka na sieć';

  @override
  String get deskSlotScanStopped => 'Skanowanie zatrzymane';

  @override
  String get deskSlotTryAgain => 'Spróbuj ponownie';

  @override
  String get deskSlotSending => 'Wysyłanie płatności';

  @override
  String get deskSlotPaymentOut => 'Płatność w drodze';

  @override
  String get deskSlotPaymentIn => 'Płatność nadchodzi';

  @override
  String get deskSlotPaymentsOut => 'Płatności w drodze';

  @override
  String get deskSlotPaymentsMoving => 'Płatności w toku';

  @override
  String deskSlotOf(String done, String needed) {
    return '$done z $needed';
  }

  @override
  String get deskSlotWaitingBlock => 'czeka na blok';

  @override
  String get deskSlotRequests => 'Nowe faktury';

  @override
  String get deskSlotNodeStarting => 'Uruchamianie węzła lokalnego';

  @override
  String get deskSlotNodeSyncing => 'Synchronizacja węzła lokalnego';

  @override
  String get deskSlotOpenRecheck => 'Otwórz Sprawdź saldo';

  @override
  String get deskSlotOpenSend => 'Otwórz Wyślij';

  @override
  String get deskSlotOpenActivity => 'Otwórz w Aktywności';

  @override
  String get deskSlotOpenInvoices => 'Otwórz Faktury';

  @override
  String deskBarMenu(String app) {
    return 'Menu $app';
  }

  @override
  String get deskBarLock => 'Zablokuj portfel';

  @override
  String get deskBarShortcuts => 'Skróty klawiszowe';

  @override
  String deskBarAbout(String app) {
    return 'O aplikacji $app';
  }

  @override
  String get deskBarQuit => 'Zakończ';

  @override
  String get deskBarWalletsHere => 'Portfele na tym komputerze';

  @override
  String get deskBarAddWallet => 'Dodaj portfel';

  @override
  String get deskBarWalletSettings => 'Ustawienia portfela';

  @override
  String get deskBarStatus => 'Stan połączeń';

  @override
  String get deskBarMinimise => 'Minimalizuj';

  @override
  String get deskBarMaximise => 'Maksymalizuj';

  @override
  String get deskBarRestore => 'Przywróć';

  @override
  String get deskBarClose => 'Zamknij';

  @override
  String get deskBarSendRunningTitle => 'Trwa wysyłka';

  @override
  String get deskBarSendRunningBody =>
      'Zamknięcie teraz zostawiłoby wynik płatności nieznany. Portfel może zamknąć się sam, gdy wysyłka się zakończy.';

  @override
  String get deskBarKeepOpen => 'Nie zamykaj';

  @override
  String get deskBarCloseAfterSend => 'Zamknij po zakończeniu';

  @override
  String get deskBarClosesAfterSend => 'Zamknie się po zakończeniu wysyłki';

  @override
  String get deskBarClosing => 'Zamykanie';

  @override
  String get deskBarKeyBack => 'Wstecz';

  @override
  String get deskBarKeyForward => 'Dalej';

  @override
  String get deskBarKeyClose => 'Zamknij menu lub okno';

  @override
  String get deskBarKeySubmit => 'Wykonaj główną akcję formularza';

  @override
  String get deskBarKeyList => 'Ta lista';

  @override
  String get deskBarCopyBuild => 'Kopiuj informacje o wersji';

  @override
  String get deskBarBuildCopied => 'Skopiowano informacje o wersji';

  @override
  String get deskBarKeyMenu => 'Otwórz menu aplikacji';

  @override
  String get txDetailsCancelRequestBody =>
      'Druga strona wciąż może dokończyć tę płatność.';

  @override
  String get txDetailsCancelNotPostedBody =>
      'Ta płatność wciąż może przejść później.';

  @override
  String get cancelMoreInHelp => 'Jak działa anulowanie';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '$amount EPIC do $who. Ta płatność wciąż może przejść później.';
  }

  @override
  String get deskOnbWalletNameEdit => 'Zmień nazwę portfela';

  @override
  String get deskOnbWalletNameField => 'Nazwa portfela';

  @override
  String deskOnbWalletNameIs(String name) {
    return 'Nazwa portfela: $name';
  }

  @override
  String sendTurnOnMethod(String method) {
    return 'Włącz $method';
  }

  @override
  String get reqPickContactOrMethod => 'Wybierz kontakt lub metodę';

  @override
  String deskOnbUnlockOpened(String when) {
    return 'Otwarty $when';
  }

  @override
  String get deskOwnYourNode => 'Własny węzeł';

  @override
  String deskOwnLabel(String where) {
    return 'Własny węzeł · $where';
  }

  @override
  String get deskOwnClassThisComputer => 'ten komputer';

  @override
  String get deskOwnClassHome => 'sieć domowa';

  @override
  String get deskOwnClassVpn => 'VPN';

  @override
  String get deskOwnFactMempool => 'Mempool';

  @override
  String get deskOwnPoolEmpty => 'pusty';

  @override
  String deskOwnPoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count czeka',
      many: '$count czeka',
      few: '$count czekają',
      one: '1 czeka',
    );
    return '$_temp0';
  }

  @override
  String deskOwnSourceSite(String site) {
    return 'Pytany bezpośrednio co 15 s · szczyt z $site';
  }

  @override
  String deskOwnSourceNodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pytany bezpośrednio co 15 s · szczyt z $count publicznych węzłów',
      many: 'Pytany bezpośrednio co 15 s · szczyt z $count publicznych węzłów',
      few: 'Pytany bezpośrednio co 15 s · szczyt z $count publicznych węzłów',
      one: 'Pytany bezpośrednio co 15 s · szczyt z 1 publicznego węzła',
    );
    return '$_temp0';
  }

  @override
  String get deskOwnSourceNone =>
      'Pytany bezpośrednio co 15 s · brak szczytu sieci do porównania';

  @override
  String get deskOwnSyncingLine =>
      'Dopóki się nie zsynchronizuje, portfel nie wyśle ani nie odbierze przez niego płatności';

  @override
  String get deskOwnAccess => 'Dostęp właściciela';

  @override
  String get deskOwnAccessHint =>
      'Sekret właściciela węzła pokazuje tu etap synchronizacji i peery oraz pozwala zablokować peera. Jest w pęku kluczy tego komputera, nigdy w ustawieniach ani w pliku danych portfela.';

  @override
  String get deskOwnAccessNotSet => 'Nie ustawiono';

  @override
  String get deskOwnAccessOn => 'Dodano';

  @override
  String deskOwnAccessRefused(String time) {
    return 'Odrzucany od $time';
  }

  @override
  String get deskOwnAccessRefusedBadge => 'Odrzucony';

  @override
  String get deskOwnAccessTor => 'Nieużywany, gdy Tor jest włączony';

  @override
  String get deskOwnAccessNote =>
      'Peery i szczegóły synchronizacji pochodzą z API właściciela węzła.';

  @override
  String get deskOwnAdd => 'Dodaj…';

  @override
  String get deskOwnUpdate => 'Zmień…';

  @override
  String get deskOwnRemove => 'Usuń';

  @override
  String get deskOwnAdded => 'Dodano dostęp właściciela';

  @override
  String get deskOwnRemoved => 'Usunięto dostęp właściciela';

  @override
  String deskOwnDlgTitle(String host) {
    return 'Dostęp właściciela do $host';
  }

  @override
  String get deskOwnDlgWhere =>
      'Sekret to pierwszy wiersz pliku .api_secret w folderze danych węzła (~/.epic/main na komputerze węzła).';

  @override
  String get deskOwnDlgPaste => 'Wklej sekret';

  @override
  String get deskOwnDlgPick => 'Wybierz plik…';

  @override
  String deskOwnDlgFileRead(String file) {
    return 'Odczytano z $file';
  }

  @override
  String get deskOwnDlgFileEmpty => 'Ten plik nie zawiera sekretu';

  @override
  String get deskOwnDlgPlainTitle =>
      'Sekret idzie przez sieć domową bez szyfrowania';

  @override
  String get deskOwnDlgPlainText =>
      'W sieci współdzielonej łącz się z węzłem przez VPN lub https albo uruchom portfel na komputerze węzła.';

  @override
  String get deskOwnDlgPlainAgain => 'Nie pokazuj więcej dla tego węzła';

  @override
  String get deskOwnDlgRefused => 'Węzeł odrzucił ten sekret';

  @override
  String get deskOwnDlgNoAnswer => 'Węzeł nie odpowiedział; sekret zachowano';

  @override
  String get deskOwnDlgAdd => 'Dodaj';

  @override
  String get deskOwnDownTitle => 'Własny węzeł nie odpowiada';

  @override
  String deskOwnDownText(String host) {
    return 'Portfel w międzyczasie używa $host i wraca, gdy ten węzeł odpowie dwa razy z rzędu.';
  }

  @override
  String deskOwnUsingMeanwhile(String host) {
    return 'w międzyczasie $host';
  }

  @override
  String deskOwnUsingUntilSynced(String host) {
    return '$host do synchronizacji';
  }

  @override
  String get deskOwnTryNow => 'Spróbuj teraz';

  @override
  String deskOwnUseForGood(String host) {
    return 'Zostaw $host';
  }

  @override
  String get deskOwnSyncTitle =>
      'Używać publicznego węzła, dopóki ten węzeł się nie zsynchronizuje?';

  @override
  String deskOwnSyncText(String host) {
    return '$host może go zastąpić do czasu synchronizacji tego węzła.';
  }

  @override
  String get deskOwnWaitForMine => 'Czekaj na ten węzeł';

  @override
  String deskOwnSyncUsingTitle(String host) {
    return '$host do synchronizacji tego węzła';
  }

  @override
  String get deskOwnSyncUsingText =>
      'Portfel wróci, gdy ten węzeł zacznie przyjmować transakcje.';

  @override
  String get deskOwnMine => 'To mój węzeł';

  @override
  String deskOwnMineHint(String site) {
    return 'Pyta sam węzeł zamiast $site i oferuje dostęp właściciela. Dla węzła, który prowadzisz sam.';
  }

  @override
  String get deskOwnSlotSyncing => 'Własny węzeł się synchronizuje';

  @override
  String ownNodeLabel(String where) {
    return 'Twój węzeł · $where';
  }

  @override
  String get ownNodeThisPhone => 'ten telefon';

  @override
  String get ownNodeHome => 'sieć domowa';

  @override
  String get ownNodeVpn => 'VPN';

  @override
  String get ownNodeSynced => 'Zsynchronizowany';

  @override
  String get ownNodeSyncing => 'Synchronizacja…';

  @override
  String get ownNodeBehind => 'W tyle';

  @override
  String get ownNodeFactBehind => 'Zaległość';

  @override
  String get ownNodeFactLatency => 'Opóźnienie';

  @override
  String get ownNodeFactAccepts => 'Przyjmuje transakcje';

  @override
  String get ownNodeFactMempool => 'Mempool';

  @override
  String get ownNodeYes => 'Tak';

  @override
  String get ownNodeNotYet => 'Jeszcze nie';

  @override
  String get ownNodeUnknown => 'Nieznane';

  @override
  String get ownNodePoolEmpty => 'pusty';

  @override
  String ownNodePoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count czeka',
      many: '$count czeka',
      few: '$count czekają',
      one: '1 czeka',
    );
    return '$_temp0';
  }

  @override
  String get ownNodeAskedDirectly =>
      'Pytany bezpośrednio z tego telefonu co 15 s';

  @override
  String get deskConExportDo => 'Eksportuj';

  @override
  String get deskSetAboutDownloadPage => 'Strona pobierania';

  @override
  String get deskUpdManual => 'Ta kopia nie może sama instalować aktualizacji.';

  @override
  String get deskUpdDownloadInstall => 'Pobierz i zainstaluj';

  @override
  String get deskUpdReadyTitle => 'Uruchom ponownie, aby zaktualizować';

  @override
  String get deskUpdReadyBody =>
      'Portfel zostanie zablokowany, a aplikacja otworzy się ponownie.';

  @override
  String get deskUpdRestartNow => 'Uruchom ponownie';

  @override
  String get deskUpdLater => 'Później';

  @override
  String get sendTorNotInVersion => 'Ta wersja nie może wysyłać na adresy Tor.';

  @override
  String get methodSendDirectLineNoTor => 'Portfel odbiorcy musi być otwarty.';

  @override
  String get sendDirectAddressShapeNoTor =>
      'Adres Link zaczyna się od http:// lub https://.';

  @override
  String get contactsAddressInvalidAnyNoTor =>
      'To nie jest prawidłowy adres. Użyj adresu Epicbox (es5x…@serwer) lub adresu Link (https://…).';

  @override
  String get handshakeLink1NoTor =>
      'Twój portfel wysyła płatność prosto do portfela drugiej strony, przez internet. Monety zostają zablokowane.';

  @override
  String txLinkHttpHintNoTor(String port) {
    return 'Link · HTTP płaci prosto do portfela pod adresem internetowym (http://host:$port) i daje temu telefonowi adres, na który mogą płacić portfele z tej samej sieci Wi-Fi. Oba portfele muszą być otwarte. Po drodze nie jest szyfrowany i nie jest osiągalny z internetu ani przez dane komórkowe. Dodaje Link · HTTP do Wyślij i Odbierz.';
  }

  @override
  String get tourPhoneWalletTextNoTor =>
      'Twoje saldo, a pod nim ikony węzła i Epicbox. To, co jeszcze się potwierdza, jest w kafelkach poniżej.';

  @override
  String get tourPhonePrivacyTextNoTor =>
      'Z jakiego węzła i serwera Epicbox korzysta portfel. Dotknij serwera, aby go zmienić.';

  @override
  String get tourPhoneAdvancedTextNoTor =>
      'Offline, wyjścia i szczegóły techniczne są tutaj. Włącz to, czego potrzebujesz.';

  @override
  String get deskNoTorSendDirectLine2 =>
      'Adres http(s). Portfel odbiorcy musi być otwarty.';

  @override
  String deskNoTorSetTxDirectHint(String port) {
    return 'Płać i dostawaj zapłatę prosto z portfela do portfela pod adresem internetowym (http://host:$port), bez serwera pośrodku. Działa tylko, gdy oba portfele są otwarte. Dodaje Link · HTTP do Wyślij, a jego adres do Odbierz. Wszystkie portfele.';
  }

  @override
  String get deskNoTorTxDetailsFromBad => 'Użyj adresu Epicbox lub http(s).';

  @override
  String get deskNoTorTourAdvancedText =>
      'Wyjścia i szczegóły techniczne są tutaj. Włącz to, czego potrzebujesz.';

  @override
  String get errorInputsSpentElsewhere =>
      'Węzeł pokazuje te monety jako już wydane, a ten portfel ich nie wydał. Najpewniej zrobił to inny portfel z Twoją frazą odzyskiwania.';

  @override
  String get deskErrInputsSpentElsewhere =>
      'Węzeł pokazuje te monety jako już wydane, a ten portfel ich nie wydał. Najpewniej zrobił to inny portfel z Twoją frazą odzyskiwania.';

  @override
  String get slAddedByYou => 'Dodane przez ciebie';

  @override
  String slCount(int n, int limit) {
    return '$n z $limit';
  }

  @override
  String slLimit(int limit) {
    return 'Wybrano $limit z $limit. Odznacz jeden, aby wybrać inny.';
  }

  @override
  String get slKeepOne => 'Zostaw co najmniej jeden.';

  @override
  String get slChosenUntick => 'Wybrany. Najpierw odznacz.';

  @override
  String get slResetDefaults => 'Przywróć domyślne';

  @override
  String get slReset => 'Przywrócono domyślne.';

  @override
  String slChosen(String host) {
    return 'Wybrano $host.';
  }

  @override
  String slChosenNonDefault(String host) {
    return 'Wybrano. Portfele, które też używają $host, znajdą cię tam.';
  }

  @override
  String slUnchosen(String host) {
    return 'Odznaczono $host.';
  }

  @override
  String slAddedNonDefault(String host) {
    return 'Dodano $host. Portfele, które też z niego korzystają, znajdą cię tam.';
  }

  @override
  String slAddedUntick(String host) {
    return 'Dodano $host. Odznacz inny, aby go wybrać.';
  }

  @override
  String get txSentFromOtherWallet => 'Wysłano z innego urządzenia';

  @override
  String txSpokenSentFromOtherWallet(String amount) {
    return 'Wysłano z innego urządzenia, $amount';
  }

  @override
  String get txDetailsOtherWallet =>
      'Wysłano z innego urządzenia z frazą odzyskiwania tego portfela. Znana jest tylko kwota.';

  @override
  String get txSentFromOtherWalletUnverified =>
      'Wysłano z innego urządzenia · niezweryfikowane';

  @override
  String get txDetailsUnverified =>
      'Niezweryfikowane: na razie zgłasza to tylko węzeł. Potwierdź to przez „Sprawdź saldo”.';

  @override
  String get txDetailsNotKnown => 'Nieznane';

  @override
  String get txReceivedByOtherWallet => 'Odebrano na innym urządzeniu';

  @override
  String txSpokenReceivedByOtherWallet(String amount) {
    return 'Odebrano na innym urządzeniu, $amount';
  }

  @override
  String get txDetailsOtherWalletIn =>
      'Odebrano na innym urządzeniu z frazą odzyskiwania tego portfela. Znana jest tylko kwota.';

  @override
  String get expLinkedDevices => 'Połączone urządzenia';

  @override
  String get expLinkedDevicesHint =>
      'Ten portfel na dwóch urządzeniach: każde pokazuje płatności drugiego i wstrzymuje monety, które drugie właśnie wydaje. Funkcja eksperymentalna.';

  @override
  String get devicesThisPhone => 'Telefon';

  @override
  String get devicesThisComputer => 'Komputer';

  @override
  String get devicesNone => 'Brak';

  @override
  String get devicesSeenNow => 'widziane przed chwilą';

  @override
  String devicesSeenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'widziane $count min temu',
      many: 'widziane $count min temu',
      few: 'widziane $count min temu',
      one: 'widziane $count min temu',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'widziane $count godz. temu',
      many: 'widziane $count godz. temu',
      few: 'widziane $count godz. temu',
      one: 'widziane $count godz. temu',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'widziane $count dni temu',
      many: 'widziane $count dni temu',
      few: 'widziane $count dni temu',
      one: 'widziane $count dzień temu',
    );
    return '$_temp0';
  }

  @override
  String get devicesNotSeen => 'jeszcze niewidziane';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count urządzenia',
      many: '$count urządzeń',
      few: '$count urządzenia',
      one: '$count urządzenie',
    );
    return '$_temp0';
  }

  @override
  String get devicesThisDevice => 'To urządzenie';

  @override
  String get devicesOthers => 'Połączone urządzenie';

  @override
  String get devicesEmpty =>
      'Przywróć ten portfel na drugim urządzeniu, a potem połącz oba tutaj.';

  @override
  String get devicesLink => 'Połącz urządzenie';

  @override
  String get devicesServers => 'Serwery';

  @override
  String get devicesPause => 'Wstrzymaj synchronizację';

  @override
  String get devicesPauseHint =>
      'Podczas wstrzymania komunikaty czekają na serwerach do 7 dni. Tryby Tylko węzeł i Wyłącznik awaryjny też wstrzymują.';

  @override
  String get devicesHeld => 'Wstrzymane monety';

  @override
  String devicesHeldBy(String name) {
    return 'Wstrzymane przez płatność z: $name';
  }

  @override
  String get devicesRelease => 'Zwolnij';

  @override
  String get devicesReleaseTitle => 'Zwolnić te monety?';

  @override
  String devicesReleaseBody(String name) {
    return '$name może jeszcze kończyć tę płatność. Wtedy płatność z tych monet się nie powiedzie. Dotyczy to tylko tego urządzenia.';
  }

  @override
  String get devicesReleased => 'Zwolniono na tym urządzeniu.';

  @override
  String get devicesRename => 'Zmień nazwę';

  @override
  String get devicesNameLabel => 'Nazwa';

  @override
  String get devicesRemove => 'Usuń';

  @override
  String devicesRemoveTitle(String name) {
    return 'Usunąć: $name?';
  }

  @override
  String devicesRemoveBody(String name) {
    return '$name przestaje dostawać komunikaty tego portfela; monety, które tu wstrzymuje, zostają zwolnione. Z frazą odzyskiwania nadal może wydawać: jeśli może być w cudzych rękach, przenieś środki do nowego portfela.';
  }

  @override
  String devicesRemoved(String name) {
    return 'Usunięto: $name.';
  }

  @override
  String devicesRemovedBy(String name) {
    return '$name usunął to urządzenie.';
  }

  @override
  String get devicesRemoving =>
      'Usuwanie… Drugie urządzenie dostanie informację, gdy to połączy się z siecią.';

  @override
  String get devicesMoneyNote =>
      'Połączenie udostępnia płatności między dwoma urządzeniami. Nie chroni pieniędzy: każde urządzenie z frazą odzyskiwania może je wydać.';

  @override
  String get devicesUnsupported =>
      'Ta wersja nie może jeszcze łączyć urządzeń.';

  @override
  String get linkLead =>
      'Dla tego portfela na drugim urządzeniu. Najpierw przywróć go tam z frazy odzyskiwania.';

  @override
  String get linkShow => 'Pokaż QR';

  @override
  String get linkScan => 'Skanuj QR';

  @override
  String get linkPaste => 'Wklej zaproszenie';

  @override
  String get linkCopy => 'Kopiuj zaproszenie';

  @override
  String get linkCopied => 'Skopiowano zaproszenie.';

  @override
  String linkExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaproszenie działa jeszcze $count min.',
      many: 'Zaproszenie działa jeszcze $count min.',
      few: 'Zaproszenie działa jeszcze $count min.',
      one: 'Zaproszenie działa jeszcze $count min.',
    );
    return '$_temp0';
  }

  @override
  String get linkWaiting => 'Czekanie na drugie urządzenie…';

  @override
  String linkWaitingFor(String name) {
    return 'Czekanie na: $name…';
  }

  @override
  String get linkPasteLabel => 'Zaproszenie';

  @override
  String get linkGo => 'Połącz';

  @override
  String get linkPicturesLabel => 'Cztery obrazki';

  @override
  String get linkDoneTitle => 'Połączono';

  @override
  String linkDone(String name) {
    return 'Połączono z $name.';
  }

  @override
  String get linkFailedTitle => 'Nie połączono';

  @override
  String get linkFailInvalid => 'To nie jest zaproszenie urządzenia.';

  @override
  String get linkFailExpired => 'Zaproszenie wygasło. Utwórz nowe.';

  @override
  String get linkFailNotFound => 'To zaproszenie zostało już użyte.';

  @override
  String get linkFailOwn =>
      'To zaproszenie pochodzi z tego urządzenia. Zeskanuj je na drugim.';

  @override
  String get linkFailOtherWallet =>
      'To urządzenie ma inny portfel. Połączenie wymaga tej samej frazy odzyskiwania.';

  @override
  String get linkFailOtherWalletCode =>
      'To zaproszenie pochodzi z innego portfela. Łączenie wymaga tej samej frazy odzyskiwania.';

  @override
  String get linkFailTooMany => 'Jedno urządzenie jest już połączone.';

  @override
  String get linkFailUnreachable =>
      'Nie udało się połączyć z drugim urządzeniem.';

  @override
  String get linkTryAgain => 'Spróbuj ponownie';

  @override
  String get linkOffTitle => 'Połączone urządzenia są eksperymentalne';

  @override
  String txSentFromDevice(String device) {
    return 'Wysłano z: $device';
  }

  @override
  String txDeviceMadeOn(String device) {
    return 'Utworzono na: $device. Szczegóły pochodzą z tego urządzenia; kwota i potwierdzenia z łańcucha.';
  }

  @override
  String get txDeviceHeld =>
      'Jej monety są wstrzymane na tym urządzeniu, dopóki łańcuch nie pokaże płatności albo drugie urządzenie jej nie zakończy.';

  @override
  String sendHeldByDevice(String amount, String name) {
    return '$amount EPIC jest wstrzymane przez płatność, którą wykonuje „$name”.';
  }

  @override
  String get offerLinkRestore =>
      'Ten portfel jest też na innym urządzeniu? Połącz je, aby widzieć wzajemnie płatności.';

  @override
  String get offerLinkOtherWallet =>
      'Czy to twoje drugie urządzenie? Połącz je, aby widzieć, komu zapłacono, i trzymać oba w zgodzie.';

  @override
  String devicesReleasedRow(String name) {
    return 'Zwolniono tutaj · $name może ją jeszcze wysłać';
  }

  @override
  String get deskDevPausedOffline => 'Wstrzymano, gdy Offline jest włączone.';

  @override
  String get deskDevPausedEpicboxOff =>
      'Wstrzymane, gdy Epicbox jest wyłączony.';

  @override
  String deskDevHeldAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskDevRenameThis => 'Zmień nazwę tego komputera';

  @override
  String deskDevRenameDevice(String name) {
    return 'Zmień nazwę: $name';
  }

  @override
  String get deskDevPasteLead => 'Wklej kod, który pokazuje drugie urządzenie.';

  @override
  String get deskDevMakingCode => 'Tworzenie kodu…';

  @override
  String get deskDevConnecting => 'Łączenie…';

  @override
  String get deskDevTheOther => 'Drugie urządzenie';

  @override
  String get deskDevOfferReceived =>
      'Czy to twoje drugie urządzenie? Połącz je, aby widzieć, kto wysłał, i trzymać oba w zgodzie.';

  @override
  String devicesEndCancelled(String name) {
    return 'Anulowano na: $name';
  }

  @override
  String devicesEndFailed(String name) {
    return 'Nie powiodło się na: $name';
  }

  @override
  String devicesEndExpired(String name) {
    return 'Wygasło na: $name';
  }

  @override
  String devicesEndLineCancelled(String name) {
    return 'Płatność została anulowana na: $name. Jej monety są znów wolne.';
  }

  @override
  String devicesEndLineExpired(String name) {
    return 'Płatność nie została ukończona na czas na: $name. Jej monety są znów wolne.';
  }

  @override
  String devicesWhyNotDelivered(String name) {
    return 'Nie udało się dostarczyć jej odbiorcy z: $name. Jej monety są znów wolne.';
  }

  @override
  String get devicesWhyRefused =>
      'Serwer odbiorcy ją odrzucił. Jej monety są znów wolne.';

  @override
  String get devicesWhyInputsSpent => 'Jej monety zostały już wydane.';

  @override
  String devicesWhyOther(String name) {
    return 'Nie udało się jej dokończyć na: $name. Jej monety są znów wolne.';
  }

  @override
  String devicesStatusInfo(String name) {
    return 'Ten status pochodzi z: $name. Ostateczny stan określa blockchain.';
  }

  @override
  String get syncHelpOtherDevice => 'Inne urządzenie';

  @override
  String get syncHelpServer => 'Serwer';

  @override
  String get syncHelpChain => 'Łańcuch bloków';

  @override
  String get syncHelpStep1 => 'To urządzenie zaczyna płatność.';

  @override
  String syncHelpStep2(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaszyfrowany komunikat idzie do obu serwerów. Odczytać go mogą tylko urządzenia.',
      many: 'Zaszyfrowany komunikat idzie do obu serwerów. Odczytać go mogą tylko urządzenia.',
      few: 'Zaszyfrowany komunikat idzie do obu serwerów. Odczytać go mogą tylko urządzenia.',
      one: 'Zaszyfrowany komunikat idzie przez serwer. Odczytać go mogą tylko urządzenia.',
    );
    return '$_temp0';
  }

  @override
  String get syncHelpStep3 =>
      'Drugie urządzenie wstrzymuje te monety i pokazuje płatność.';

  @override
  String get syncHelpStep4 =>
      'Łańcuch potwierdza. To on decyduje o ostatecznym stanie.';

  @override
  String get syncHelpDiagram =>
      'Jak działa synchronizacja: to urządzenie zaczyna płatność; zaszyfrowany komunikat idzie przez serwer do drugiego urządzenia, które wstrzymuje te monety; łańcuch potwierdza.';

  @override
  String get syncHelpStatus => 'Stan na żywo';

  @override
  String get syncHelpPaused => 'Synchronizacja wstrzymana';

  @override
  String get syncHelpAnswering => 'Odpowiada';

  @override
  String get syncHelpNotAnswering => 'Nie odpowiada';

  @override
  String get syncHelpNotChecked => 'Nie sprawdzono';

  @override
  String get deskSetAdvConfirmations => 'Potwierdzenia';

  @override
  String deskSetAdvConfirmationsHint(int byDefault, int min, int max) {
    return 'Ile bloków odebrana płatność czeka, zanim jej wyjścia będzie można wydać. Domyślnie $byDefault; od $min do $max.';
  }

  @override
  String get deskSetAdvConfirmationsDefault => 'Domyślnie';

  @override
  String deskSetAdvConfirmationsReset(int count) {
    return 'Przywróć $count';
  }

  @override
  String get deskSetAdvConfirmationsFewer => 'Mniej potwierdzeń';

  @override
  String get deskSetAdvConfirmationsMore => 'Więcej potwierdzeń';

  @override
  String deskSetAdvConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count potwierdzenia',
      many: '$count potwierdzeń',
      few: '$count potwierdzenia',
      one: '$count potwierdzenie',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAdvConfirmationsLowNote =>
      'Mniej potwierdzeń to szybciej, ale mniej bezpiecznie.';

  @override
  String get deskSetAdvConfirmationsNotSaved => 'Nie zmieniono potwierdzeń';

  @override
  String get deskSetPeersFirstSeenHint =>
      'Kiedy aplikacja w tej sesji pierwszy raz zobaczyła połączonego peera.';

  @override
  String deskAppFirstScanProgress(int percent) {
    return 'Skanowanie łańcucha · $percent %';
  }

  @override
  String deskAppFirstScanFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znaleziono $countString wyjścia',
      many: 'Znaleziono $countString wyjść',
      few: 'Znaleziono $countString wyjścia',
      one: 'Znaleziono $countString wyjście',
    );
    return '$_temp0';
  }

  @override
  String get deskAppFirstScanShowLog => 'Pokaż log';

  @override
  String get deskAppFirstScanHideLog => 'Ukryj log';

  @override
  String deskNodeDurationDh(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String deskNodeDurationH(int hours) {
    return '$hours h';
  }

  @override
  String deskInvPayerAgoHoursOnly(int hours) {
    return '$hours godz.';
  }

  @override
  String get slPlainHttpTitle => 'Używać tego węzła bez szyfrowania?';

  @override
  String slPlainHttpBody(String host) {
    return '$host należy do współdzielonej puli adresów: twojego tailnetu (Tailscale) albo sieci twojego dostawcy internetu. Portfel łączy się z tym węzłem przez nieszyfrowane http, więc każdy w tej sieci może odczytać, o co portfel go pyta. Dodaj go tylko wtedy, gdy ten adres to twój tailnet.';
  }

  @override
  String get slPlainHttpUse => 'Użyj tego węzła';

  @override
  String get slRefusedLocal =>
      'Nie wybrano: inne portfele nie dotrą do serwera pod adresem lokalnym lub prywatnym.';

  @override
  String get slRefusedOnion =>
      'Nie wybrano: serwer onion działa tylko z włączonym Torem.';

  @override
  String get slRefusedOnionNoTor =>
      'Nie wybrano: ta wersja nie może połączyć się z tym serwerem.';

  @override
  String get deskOwnAccessOnPlain =>
      'Dodano · trafia do węzła bez szyfrowania (http), widoczny w tej sieci';

  @override
  String get sasNotFromCamera =>
      'Ich kod przyszedł w wiadomości, a nie z twojego aparatu. Jeśli ich portfel nie zeskanował twojego kodu z tego ekranu, te słowa nie dowodzą, kto go wysłał, więc nie ma tu potwierdzenia: zachowaj parowanie bez sprawdzania albo sparuj przez zaproszenie.';

  @override
  String get slSwitchFirst => 'Najpierw przełącz';

  @override
  String get contactPaymentsNone => 'Brak płatności z tym kontaktem.';

  @override
  String contactPaymentsWith(String name) {
    return 'Płatności z: $name';
  }

  @override
  String get contactPaymentsAll => 'Wszystkie płatności';

  @override
  String receiveEpicboxNotConnected(String server) {
    return 'Brak połączenia · $server';
  }

  @override
  String restoreWordsAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wszystkie $count słowa się zgadzają.',
      many: 'Wszystkie $count słów się zgadza.',
      few: 'Wszystkie $count słowa się zgadzają.',
      one: '$count słowo się zgadza.',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count słowa',
      many: '$count słów',
      few: '$count słowa',
      one: '$count słowo',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count słowa nie ma na liście.',
      many: '$count słów nie ma na liście.',
      few: '$count słów nie ma na liście.',
      one: '$count słowa nie ma na liście.',
    );
    return '$_temp0';
  }

  @override
  String pairInvitedAt(String clock) {
    return 'Zaproszenie wysłano $clock';
  }

  @override
  String get pairInvitedYesterday => 'Zaproszenie wysłano wczoraj';

  @override
  String pairInvitedOn(String day) {
    return 'Zaproszenie wysłano $day';
  }

  @override
  String get deskActNoneUnderFilter => 'Nic pod tym filtrem';

  @override
  String get deskKitMethodConnected => 'Połączono';

  @override
  String get deskOvSendWaitsNode =>
      'Wysyłanie będzie możliwe, gdy węzeł odpowie.';

  @override
  String get deskSetRescanRecheck => 'Sprawdź';

  @override
  String get deskSetRescanRecheckAgain => 'Sprawdź ponownie';

  @override
  String get deskSetRescanFromDate => 'Od daty';

  @override
  String get deskSetRescanPickDate => 'Wybierz datę';

  @override
  String get deskSetRescanPickDateFirst => 'Najpierw wybierz datę.';

  @override
  String contactsImportAddsAddress(String name, String method, String address) {
    return '$name dostaje adres $method: $address';
  }

  @override
  String get netStatusTurnOnHint =>
      'Wyłączone. Włącz w Ustawienia › Transakcje.';

  @override
  String get netStatusTurnOnHintPrivacy =>
      'Wyłączone. Włącz w Ustawienia › Prywatność i sieć.';

  @override
  String get netStatusTurnOnHintNet =>
      'Wyłączone. Włącz w Ustawienia › Sieć i prywatność.';

  @override
  String get deskBarTurnOnHint => 'Wyłączone. Włącz w Ustawienia › Transakcje.';

  @override
  String get deskErrMacKeychain =>
      'macOS nie pozwolił aplikacji odczytać jej zapisanych danych z pęku kluczy. Zamknij BT Wallet i otwórz go ponownie; gdy macOS zapyta, wpisz hasło, którym odblokowujesz Maca, i wybierz „Zawsze pozwalaj”.';

  @override
  String get deskUpdOpenDmg => 'Otwórz obraz dysku';

  @override
  String get deskUpdDmgHint =>
      'Aplikacja zamknie się i otworzy się obraz dysku: przeciągnij BT Wallet do folderu Aplikacje i zastąp starą wersję. Epic Cash Desktop, jeśli tam jest, przenieś do Kosza.';

  @override
  String get balanceSheetTitle => 'Salda';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count w toku',
      many: '$count w toku',
      few: '$count w toku',
      one: '1 w toku',
    );
    return '$_temp0';
  }

  @override
  String get connectionsSheetTitle => 'Połączenia';

  @override
  String settingsFileSyntaxError(String file, int line) {
    return '$file, wiersz $line: tego wiersza nie da się odczytać. Obowiązują ostatnie poprawne ustawienia.';
  }

  @override
  String settingsFileNotText(String file, int line) {
    return '$file, wiersz $line: to nie tekst w cudzysłowie. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotNumber(String file, int line) {
    return '$file, wiersz $line: to nie liczba całkowita. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotSwitch(String file, int line) {
    return '$file, wiersz $line: to nie true ani false. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotList(String file, int line) {
    return '$file, wiersz $line: to nie lista. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotNodeAddress(String file, int line) {
    return '$file, wiersz $line: to nie adres węzła. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotEpicboxServer(String file, int line) {
    return '$file, wiersz $line: to nie serwer Epicbox. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotHostName(String file, int line) {
    return '$file, wiersz $line: to nie nazwa hosta. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotWebAddress(String file, int line) {
    return '$file, wiersz $line: to nie adres strony. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotOnion(String file, int line) {
    return '$file, wiersz $line: to nie adres onion. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotPort(String file, int line) {
    return '$file, wiersz $line: to nie numer portu. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileNotEpicboxAddress(String file, int line) {
    return '$file, wiersz $line: to nie adres Epicbox. Obowiązuje ostatnia poprawna wartość.';
  }

  @override
  String settingsFileUnknownKey(String file, int line, String key) {
    return '$file, wiersz $line: nieznany klucz $key, pominięty.';
  }

  @override
  String settingsFileConflict(String file, String key) {
    return '$file edytowano w tym samym czasie; zostaje jego wartość $key.';
  }

  @override
  String settingsFileBrokenSaved(String file, String backup) {
    return '$file zawierał błędy. Zapisano go jako $backup i utworzono na nowo.';
  }

  @override
  String settingsFileRecreated(String file) {
    return 'Brakowało pliku $file, utworzono go na nowo.';
  }

  @override
  String settingsFileWriteFailed(String file) {
    return 'Nie udało się zapisać $file. Zmiana obowiązuje do zamknięcia aplikacji.';
  }

  @override
  String settingsFileReadFailed(String file) {
    return 'Nie udało się odczytać $file. Obowiązują wbudowane ustawienia.';
  }

  @override
  String get deskKitReachTorOff => 'Sprawdzenie wymaga wyłączenia Tora.';

  @override
  String get deskSetBackupServersTitle => 'Użyć serwerów z tego pliku?';

  @override
  String get deskSetBackupServersBody =>
      'Jego listy węzłów i serwerów Epicbox różnią się od list tego komputera. Wszystkie portfele tutaj używają tych samych list.';

  @override
  String get deskSetBackupServersKeep => 'Z tego komputera';

  @override
  String get deskSetBackupServersUse => 'Z pliku';

  @override
  String get deskSlNoNodeTitle => 'Brak węzła';

  @override
  String get deskSlNoNodeText =>
      'Lista węzłów jest pusta. Dodaj węzeł, aby sprawdzać saldo i wysyłać.';

  @override
  String get deskSlNoEpicboxTitle => 'Brak serwera Epicbox';

  @override
  String get deskSlNoEpicboxText =>
      'Lista serwerów Epicbox jest pusta. Dodaj serwer, aby mieć adres Epicbox.';

  @override
  String get devicesOneOnly =>
      'Można połączyć jedno urządzenie. Aby połączyć inne, najpierw je usuń.';

  @override
  String txReceivedOnDevice(String device) {
    return 'Odebrano na: $device';
  }

  @override
  String txSpokenReceivedOnDevice(String device, String amount) {
    return 'Odebrano na: $device, $amount';
  }

  @override
  String txDetailsDeviceIn(String device) {
    return '$device, połączone z tym portfelem, odebrało te monety.';
  }

  @override
  String get deskOnbNodeAdvanced => 'Zaawansowane';

  @override
  String deskOnbNodePortsSub(String api, String p2p) {
    return 'API $api · P2P $p2p';
  }

  @override
  String get deskOnbNodeApiPort => 'Port API';

  @override
  String get deskOnbNodeP2pPort => 'Port P2P';

  @override
  String get deskOnbNodePortsWhy =>
      'Potrzebne tylko wtedy, gdy inny węzeł na tym komputerze lub w sieci używa tych portów.';

  @override
  String deskOnbNodePortRange(String min, String max) {
    return 'Liczba od $min do $max.';
  }

  @override
  String get deskOnbNodePortsSame => 'Oba porty muszą się różnić.';

  @override
  String deskOnbNodePortTaken(String port, String next) {
    return 'Port $port zajmuje inny program. $next jest wolny.';
  }

  @override
  String deskOnbNodePortUse(String port) {
    return 'Użyj $port';
  }

  @override
  String get deskSetLnodePorts => 'Porty';

  @override
  String get deskSetLnodePortsTitle => 'Porty węzła';

  @override
  String get deskSetLnodePortsDesc =>
      'Porty, na których nasłuchuje wbudowany węzeł.';

  @override
  String get deskSetLnodePortsRestart =>
      'Węzeł uruchomi się ponownie z nowymi portami.';

  @override
  String get deskSetLnodePortsSaved => 'Porty zapisane';

  @override
  String get deskSetLnodePortsRestarting => 'Węzeł uruchamia się ponownie.';

  @override
  String get deskSetLnodePortsNotSaved => 'Porty nie zostały zapisane';

  @override
  String get deskKitInfoLabel => 'Więcej informacji';

  @override
  String get advModeNodeOnly => 'Tylko węzeł';

  @override
  String get advModeKillSwitch => 'Wyłącznik awaryjny';

  @override
  String get advModeStandardHintHere =>
      'Łączy się bezpośrednio. Włącz Tor poniżej, aby łączyć się przez Tor.';

  @override
  String get advModeStandardHintNoTor =>
      'Łączy się bezpośrednio z węzłem i usługami, których używasz.';

  @override
  String get advModeTorOnlyHint =>
      'Wszystko idzie przez Tor. Nic się nie łączy, dopóki Tor nie będzie gotowy.';

  @override
  String get advModeNodeOnlyHint =>
      'Łączy się tylko używany węzeł. Bezpośrednio · QR i Bezpośrednio · Plik działają.';

  @override
  String get advModeKillSwitchHint =>
      'Nic się nie łączy. Portfel działa offline z ostatnio znanym saldem, a płatności idą plikiem lub kodem QR.';

  @override
  String advModeConfirmTitle(String mode) {
    return 'Przełączyć na „$mode”?';
  }

  @override
  String advModeConfirmBody(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count płatności czeka na odbiorcę przez Epicbox lub Link. Zostają wstrzymane i wznawiają się po wyjściu z trybu „$mode”. Nic nie jest anulowane.',
      many:
          '$count płatności czeka na odbiorcę przez Epicbox lub Link. Zostają wstrzymane i wznawiają się po wyjściu z trybu „$mode”. Nic nie jest anulowane.',
      few:
          '$count płatności czekają na odbiorcę przez Epicbox lub Link. Zostają wstrzymane i wznawiają się po wyjściu z trybu „$mode”. Nic nie jest anulowane.',
      one:
          '1 płatność czeka na odbiorcę przez Epicbox lub Link. Zostaje wstrzymana i wznawia się po wyjściu z trybu „$mode”. Nic nie jest anulowane.',
    );
    return '$_temp0';
  }

  @override
  String get advModeConfirmSwitch => 'Przełącz';

  @override
  String netMarkSemantics(String mode) {
    return 'Tryb sieci: $mode. Otwiera sekcję Sieć.';
  }

  @override
  String netMarkSemanticsDesk(String mode) {
    return 'Tryb sieci: $mode. Pokazuje, co robi.';
  }

  @override
  String get netMarkLineTorOnly => 'Każde połączenie idzie przez Tor.';

  @override
  String get netMarkLineTorWaiting =>
      'Oczekiwanie na Tor. Nic się nie łączy, dopóki nie jest gotowy.';

  @override
  String get netMarkLineNodeOnly =>
      'Tylko używany węzeł. Epicbox, Link, aktualizacje i kurs są wyłączone.';

  @override
  String get netMarkLineKillSwitch =>
      'Nic się nie łączy. Saldo i historia są takie, jak ostatnio widziane.';

  @override
  String get netMarkChange => 'Zmień';

  @override
  String statusOffByMode(String mode) {
    return 'Wyłączone ($mode)';
  }

  @override
  String get statusOffByModeDetail =>
      'Wyłączone przez tryb sieci. Zmienisz to w Ustawienia › Zaawansowane › Sieć.';

  @override
  String get statusOffByModeDetailNet =>
      'Wyłączone przez tryb sieci. Zmienisz to w Ustawienia › Sieć i prywatność.';

  @override
  String get netBlockEpicboxNodeOnly =>
      'Tryb Tylko węzeł jest włączony: Epicbox jest wyłączony. Bezpośrednio · Płatność QR i Bezpośrednio · Przesyłanie pliku działają.';

  @override
  String get netBlockLinkNodeOnly =>
      'Tryb Tylko węzeł jest włączony: Link jest wyłączony. Bezpośrednio · Płatność QR i Bezpośrednio · Przesyłanie pliku działają.';

  @override
  String get netBlockSendKillSwitch =>
      'Wyłącznik awaryjny jest włączony: nic się nie łączy. Bezpośrednio · Płatność QR i Bezpośrednio · Przesyłanie pliku działają.';

  @override
  String get netBlockNodeOnly => 'Wyłączone w trybie Tylko węzeł.';

  @override
  String get netBlockKillSwitch =>
      'Wyłączone przy Wyłączniku awaryjnym: nic się nie łączy.';

  @override
  String get netBlockWaitingForTorLong =>
      'Oczekiwanie na Tor. Nic się nie łączy, dopóki nie jest gotowy.';

  @override
  String receiveEpicboxOffMode(String mode) {
    return 'Epicbox jest wyłączony w trybie „$mode”.';
  }

  @override
  String receiveEpicboxOffModeBody(String mode) {
    return 'Płatności na ten adres czekają na serwerze Epicbox i dotrą po wyjściu z trybu „$mode”.';
  }

  @override
  String receiveLinkOffMode(String mode) {
    return 'Odbieranie przez Link jest wyłączone w trybie „$mode”.';
  }

  @override
  String updatesOffMode(String mode) {
    return 'Sprawdzanie aktualizacji jest wyłączone w trybie „$mode”.';
  }

  @override
  String reportOffMode(String mode) {
    return 'Wyłączone w trybie „$mode”. Zapisz raport jako plik.';
  }

  @override
  String get recheckOffKill =>
      'Sprawdzenie salda potrzebuje węzła. Wyłączone przy Wyłączniku awaryjnym.';

  @override
  String get postFinishedOffKill =>
      'Wyłączone przy Wyłączniku awaryjnym: nic się tu nie łączy.';

  @override
  String get postFinishedOffTor => 'Oczekiwanie na Tor. Wysłanie wymaga węzła.';

  @override
  String get browserOffTorOnly =>
      'Otworzyłoby się poza Torem. Skopiuj zamiast tego link.';

  @override
  String browserOffMode(String mode) {
    return 'Wyłączone w trybie „$mode”. Skopiuj zamiast tego link.';
  }

  @override
  String get netChangeLink => 'Zmień';

  @override
  String get lastKnownCaption => 'Ostatnio znane';

  @override
  String get lastKnownList => 'Ostatnio znane · Wyłącznik awaryjny';

  @override
  String lastKnownConfirming(String text) {
    return '$text · ostatnio znane';
  }

  @override
  String get coldNeedsOnlineCheck =>
      'Najpierw trzeba raz sprawdzić saldo online.';

  @override
  String get finalizeNotPostedTitle => 'Gotowa, niewysłana';

  @override
  String finalizeNotPostedBody(String amount) {
    return '$amount gotowe. Wyłącznik awaryjny jest włączony, więc ten telefon nie może tego wysłać: zapisz płatność lub pokaż ją jako kod QR dla urządzenia, które jest online.';
  }

  @override
  String get finishedSaveFile => 'Zapisz plik';

  @override
  String get finishedShowQr => 'Pokaż QR';

  @override
  String finishedSaved(String name) {
    return 'Zapisano $name';
  }

  @override
  String get finishedQrTitle => 'Gotowa płatność';

  @override
  String get finishedUnavailable =>
      'Ta wersja nie potrafi jeszcze zapisać gotowej płatności.';

  @override
  String get finishedFailed => 'Nie udało się odczytać gotowej płatności.';

  @override
  String get txPostElsewhere => 'Do wysłania z innego urządzenia';

  @override
  String get txPostElsewhereKill =>
      'Gotowa przy Wyłączniku awaryjnym. Zapisz ją lub pokaż kod QR, a potem wyślij z urządzenia, które jest online.';

  @override
  String get txPostElsewhereAfter =>
      'Gotowa przy Wyłączniku awaryjnym, jeszcze nieobecna w łańcuchu. Wyślij ją stąd albo poczekaj na urządzenie, które ją wysłało.';

  @override
  String get txPostNow => 'Wyślij teraz';

  @override
  String get txModeFinishedKill => 'Gotowa przy Wyłączniku awaryjnym';

  @override
  String get txModeRow => 'Tryb';

  @override
  String get postFinishedTitle => 'Wyślij gotową płatność';

  @override
  String get postFinishedIntro =>
      'Wyślij płatność, którą inne urządzenie przygotowało przy Wyłączniku awaryjnym.';

  @override
  String get postFinishedIntroOffline =>
      'Wyślij płatność, którą inne urządzenie dokończyło bez połączenia.';

  @override
  String get postFinishedOpenFile => 'Otwórz plik';

  @override
  String get postFinishedScanQr => 'Skanuj QR';

  @override
  String get postFinishedPaste => 'Wklej';

  @override
  String get postFinishedChooseFile => 'Wybierz plik';

  @override
  String get postFinishedSummary => 'Gotowa płatność';

  @override
  String get postFinishedAmount => 'Kwota';

  @override
  String get postFinishedFee => 'Opłata';

  @override
  String get postFinishedKernel => 'Kernel';

  @override
  String get postFinishedNote =>
      'Wysłanie wprowadza ją do sieci. Portfel, który ją utworzył, pokaże ją jako potwierdzaną, gdy zobaczy ją w łańcuchu.';

  @override
  String get postFinishedPost => 'Wyślij';

  @override
  String get postFinishedPosting => 'Wysyłanie…';

  @override
  String get postFinishedDone => 'Wysłano do sieci';

  @override
  String get postFinishedDoneBody =>
      'Węzeł ją ma. Portfel, który ją utworzył, pokaże ją jako potwierdzaną, gdy zobaczy ją w łańcuchu.';

  @override
  String get postFinishedNotFinished =>
      'To nie jest gotowa płatność. Otwórz plik zapisany pod „Do wysłania z innego urządzenia” lub zeskanuj jego kod QR.';

  @override
  String get postFinishedFailed => 'Węzeł jej nie przyjął. Spróbuj ponownie.';

  @override
  String get postFinishedUnreachable => 'Węzeł nie odpowiada.';

  @override
  String get postFinishedDeskRow => 'Wyślij gotową płatność';

  @override
  String get postFinishedDeskRowText =>
      'Wyślij płatność, którą inne urządzenie przygotowało przy Wyłączniku awaryjnym.';

  @override
  String get postFinishedOpen => 'Otwórz';

  @override
  String deskFinNotPostedKillBody(String amount) {
    return '$amount gotowe. Wyłącznik awaryjny jest włączony, więc ten komputer nie może tego wysłać. Zapisz płatność lub skopiuj ją, a potem wyślij z urządzenia, które jest online: Odbierz › Pliki transakcji › Wyślij gotową płatność.';
  }

  @override
  String netMarkRowLabel(String mode) {
    return 'Tryb sieci: $mode';
  }

  @override
  String get qrStatusFinishedHidden => 'Ukryty';

  @override
  String get qrStatusFinishedShowing =>
      'Czeka, aż urządzenie online zeskanuje kod.';

  @override
  String qrShowSubFinished(String amount) {
    return '$amount, gotowa';
  }

  @override
  String qrSemanticsFinished(String state) {
    return 'Kod QR gotowej płatności, $state';
  }

  @override
  String get qrHiddenBodyFinished =>
      'Pokaż go urządzeniu, które jest online. Wyśle płatność; klucz nie jest potrzebny.';

  @override
  String get qrScanFinished => 'Skanuj gotową płatność';

  @override
  String get qrScanNotFinished => 'Ten kod nie jest gotową płatnością.';

  @override
  String get qrScanAimFinished => 'Skieruj aparat na kod na drugim urządzeniu.';

  @override
  String get deskRailOpenNetwork => 'Otwórz ustawienia sieci';

  @override
  String get cancelFeeLine => 'Kosztuje zwykłą opłatę sieciową.';

  @override
  String get cancelForSure => 'Anuluj na pewno';

  @override
  String get cancelStopWaiting => 'Przestań czekać';

  @override
  String get cancelStopWaitingLine =>
      'Bez opłaty. Płatność wciąż może przejść.';

  @override
  String get cancelMoveBack => 'Przenieś monety z powrotem';

  @override
  String cancelMoveBackFee(String fee) {
    return 'Przenieś monety z powrotem · opłata $fee';
  }

  @override
  String get cancelUnlockOpen => 'Odblokuj monety, płatność zostaje otwarta';

  @override
  String get cancelCompareMoveBack =>
      'Przenieś monety z powrotem: na pewno, za opłatą sieciową.';

  @override
  String get cancelCompareUnlock =>
      'Odblokuj monety: bez opłaty, płatność wciąż może przejść.';

  @override
  String get cancelChoicesTitle => 'Dwa sposoby anulowania';

  @override
  String get cancelChoicesWhy =>
      'Anuluj na pewno najpierw przenosi monety z powrotem do tego portfela, za zwykłą opłatą sieciową. Potem stara płatność już nigdy nie przejdzie; to pewny sposób.\n\nPrzestań czekać jest bez opłaty i nic nie przenosi. Monety znów można wydać, a płatność zostaje, jak jest. Jeśli druga strona mimo to dokończy ją później, płatność przejdzie i pokaże się jako zapłacona; jeśli nie, nic się nie stanie.';

  @override
  String get cancelStoppedWaitingTitle => 'Czekanie zakończone';

  @override
  String get cancelStoppedWaitingText =>
      'Monety znów można wydać. Płatność wciąż może przejść; jeśli tak, pokaże się jako zapłacona.';

  @override
  String get txDetailsStoppedWaiting =>
      'Czekanie zakończone. Monety znów można wydać. Płatność wciąż może przejść; jeśli tak, pokaże się jako zapłacona.';

  @override
  String get errorPaymentCancelledCoinsMoved =>
      'Ta płatność została anulowana, a jej monety już przeniesiono. Nie może już przejść.';

  @override
  String get errorPaymentAlreadyWentThrough =>
      'Nie udało się przenieść monet z powrotem: sama płatność już przeszła. Pokazuje się jako zapłacona.';

  @override
  String get errorPinKeyLost =>
      'PIN nie otwiera już tego portfela. Twoje monety są bezpieczne: dotknij „Nie pamiętasz kodu PIN?” i przywróć portfel z frazy odzyskiwania.';

  @override
  String get errorKeystoreRefused =>
      'Telefon nie udostępnił klucza portfela. Odblokuj telefon jego własnym kodem PIN lub odciskiem palca, a potem spróbuj ponownie.';

  @override
  String get unlockTryAgain => 'Spróbuj ponownie';

  @override
  String get settingsUsePassphrase => 'Użyj hasła';

  @override
  String get settingsChangePassphrase => 'Zmień hasło';

  @override
  String get passphraseLabel => 'Hasło';

  @override
  String passphraseChoose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wybierz hasło o długości co najmniej $count znaku, nie same cyfry',
      many:
          'Wybierz hasło o długości co najmniej $count znaków, nie same cyfry',
      few: 'Wybierz hasło o długości co najmniej $count znaków, nie same cyfry',
      one: 'Wybierz hasło o długości co najmniej $count znaku, nie same cyfry',
    );
    return '$_temp0';
  }

  @override
  String get passphraseRepeat => 'Powtórz hasło';

  @override
  String get passphraseMismatch => 'Hasła się różnią';

  @override
  String get passphraseSet => 'Ustawiono hasło';

  @override
  String get passphraseSetBiometricsOff =>
      'Ustawiono hasło. Włącz odblokowanie biometryczne ponownie poniżej.';

  @override
  String get passphraseForgot => 'Nie pamiętasz hasła?';

  @override
  String get passphrasePromptTitle => 'Wpisz hasło';

  @override
  String get passphraseEnterCurrent => 'Wpisz obecne hasło';

  @override
  String get passphraseCurrentLabel => 'Obecne hasło';

  @override
  String get passphraseChooseTitle => 'Wybierz hasło';

  @override
  String passphraseRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Co najmniej $count znaku, nie same cyfry.',
      many: 'Co najmniej $count znaków, nie same cyfry.',
      few: 'Co najmniej $count znaki, nie same cyfry.',
      one: 'Co najmniej $count znak, nie same cyfry.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseUsePinInstead => 'Użyj zamiast tego PIN-u';

  @override
  String get passphraseUsePassphraseInstead => 'Użyj zamiast tego hasła';

  @override
  String get invoicePassphraseReason => 'Wpisz hasło, aby zapłacić tę fakturę.';

  @override
  String get restoreReplacePassphraseReason =>
      'Wpisz hasło, aby zastąpić ten portfel. Przywrócony portfel zachowa to hasło.';

  @override
  String get backupPassphraseReason =>
      'Wpisz hasło, aby wyświetlić frazę odzyskiwania.';

  @override
  String sendQrPassphraseReason(String amount) {
    return 'Wpisz hasło, aby utworzyć kod QR płatności na $amount.';
  }

  @override
  String get settingsBiometricsPassphraseReason =>
      'Wpisz hasło, aby włączyć odblokowanie biometryczne.';

  @override
  String get settingsDeletePassphraseReason =>
      'Wpisz hasło, aby usunąć ten portfel.';

  @override
  String sendPassphraseReason(String amount) {
    return 'Wpisz hasło, aby wysłać $amount.';
  }

  @override
  String sendFilePassphraseReason(String amount) {
    return 'Wpisz hasło, aby utworzyć plik transakcji na $amount.';
  }

  @override
  String get passphraseSetTitle => 'Ustaw hasło';

  @override
  String get deskSetReportFullDetails => 'Dołącz pełne szczegóły';

  @override
  String get deskSetReportPartFullDetails => 'Pełne szczegóły';

  @override
  String get deskSetReportFullDetailsInfo =>
      'Wysyła adresy i kwoty w całości zamiast skróconych. Frazy odzyskiwania, klucze i hasła nigdy nie są wysyłane.';

  @override
  String get deskOutNoteWaitingRecipient => 'czeka na odbiorcę';

  @override
  String get deskSlotNotPosted => 'Płatności nie ma w sieci';

  @override
  String get txOtherWalletMore => 'Płatności z innego portfela';

  @override
  String get finalizeNotPostedHelp => 'Płacenie z Wyłącznika awaryjnego';

  @override
  String get deskActSearchHintFull => 'Notatka, kontakt, adres lub kwota';

  @override
  String get deskOutFilterWaiting => 'Oczekujące';

  @override
  String deskRecvHeaderTip(String methods) {
    return 'Odbieranie: $methods';
  }

  @override
  String deskSendHintNeedsMethod(String method) {
    return 'Sprawdzenie wymaga: $method';
  }

  @override
  String get deskSetAboutVersionLabel => 'Wersja';

  @override
  String get deskSetAboutNodeLabel => 'Węzeł';

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
      other: 'Potwierdzona, $confirmationsString potwierdzenia · blok $block.',
      many: 'Potwierdzona, $confirmationsString potwierdzeń · blok $block.',
      few: 'Potwierdzona, $confirmationsString potwierdzenia · blok $block.',
      one: 'Potwierdzona, $confirmationsString potwierdzenie · blok $block.',
    );
    return '$_temp0';
  }

  @override
  String deskKitNoAnswerSince(String time) {
    return 'Brak odpowiedzi od $time';
  }

  @override
  String get deskKitMoreInHelp => 'Więcej w Pomocy';

  @override
  String get homeReceiveEpicButton => 'Odbierz EPIC';

  @override
  String txDeviceStatusMadeOn(String device) {
    return 'Utworzona na: $device.';
  }

  @override
  String txDeviceStatusHeld(String device) {
    return 'Utworzona na: $device. Środki są zatrzymane tutaj, dopóki łańcuch nie pokaże płatności.';
  }

  @override
  String get deskSendEpicboxNodeOnly =>
      'Tryb Tylko węzeł jest włączony: Epicbox jest wyłączony. Bezpośrednio · Przesyłanie pliku działa.';

  @override
  String deskSendEpicboxNodeOnlyTab(String method) {
    return 'Tryb Tylko węzeł jest włączony: Epicbox jest wyłączony. $method działa.';
  }

  @override
  String get deskSendLinkNodeOnly =>
      'Tryb Tylko węzeł jest włączony: Link jest wyłączony. Bezpośrednio · Przesyłanie pliku działa.';

  @override
  String deskSendLinkNodeOnlyTab(String method) {
    return 'Tryb Tylko węzeł jest włączony: Link jest wyłączony. $method działa.';
  }

  @override
  String get deskSendKillSwitch =>
      'Wyłącznik awaryjny jest włączony: nic się nie łączy. Bezpośrednio · Przesyłanie pliku działa.';

  @override
  String deskSendKillSwitchTab(String method) {
    return 'Wyłącznik awaryjny jest włączony: nic się nie łączy. $method działa.';
  }

  @override
  String get levelOneTitle => 'Tylko wysyłanie i odbieranie';

  @override
  String get levelOneLine =>
      'Pieniądze wpływają, pieniądze wychodzą. Nic do nauki.';

  @override
  String get levelTwoTitle => 'Nie za technicznie, ale mów, co się dzieje';

  @override
  String get levelTwoLine => 'Prostymi słowami o tym, co robi portfel.';

  @override
  String get levelThreeTitle => 'Chcę zobaczyć wszystko';

  @override
  String get levelThreeLine =>
      'Każdy przełącznik, każda liczba. Uważaj na pokrętła.';

  @override
  String get levelUndercoverTitle => 'Tylko Tor';

  @override
  String get levelFooter =>
      'Zmienisz to w każdej chwili w Ustawienia › Zaawansowane.';

  @override
  String get levelRowTitle => 'Widok portfela';

  @override
  String get levelChangeTitle => 'Zmień widok';

  @override
  String get lvPickStopOne => 'Płytko';

  @override
  String get lvPickStopTwo => 'Głębiej';

  @override
  String get lvPickStopThree => 'Na głęboką wodę';

  @override
  String get lvPickLineOne =>
      'Wysyłasz, odbierasz, gotowe. Resztą zajmie się portfel.';

  @override
  String get lvPickLineTwo => 'Widzisz, co robi, prostymi słowami.';

  @override
  String get lvPickLineThree =>
      'Każdy przełącznik, każda liczba. Wszystko twoje.';

  @override
  String get lvPickNone => 'Wybierz poziom';

  @override
  String get lvPickNoneLine => 'Podgląd podąża za pokrętłem.';

  @override
  String get lvPickDepth => 'Widok';

  @override
  String get lvPickPreview =>
      'Podgląd ekranu głównego. Pokazuje więcej, im głębiej ustawisz pokrętło.';

  @override
  String get lvPickHelpTitle => 'Co to zmienia';

  @override
  String get lvPickHelpText =>
      'Tylko to, ile pokazuje aplikacja. Każdy widok wysyła i odbiera tak samo, tymi samymi kluczami i tymi samymi monetami.';

  @override
  String get lvPickUndercoverHelp =>
      'Tylko Tor, od pierwszego połączenia. Każde połączenie idzie przez Tor; start trwa dłużej.\n\nNic jeszcze się nie połączyło. To samo co Tryb sieci › Tylko Tor; można to później wyłączyć w Ustawienia › Zaawansowane.';

  @override
  String get lvPickUndercoverHelpNet =>
      'Tylko Tor, od pierwszego połączenia. Każde połączenie idzie przez Tor; start trwa dłużej.\n\nNic jeszcze się nie połączyło. To samo co Tryb połączenia › Tylko Tor; można to później wyłączyć w Ustawienia › Sieć i prywatność.';

  @override
  String get lvPickUndercover => 'Incognito';

  @override
  String get lvPickUndercoverLaterHelp =>
      'Tylko Tor. Każde połączenie idzie przez Tor; start trwa dłużej. Tam, gdzie Tor jest zablokowany, portfel nie połączy się, dopóki tego nie wyłączysz.';

  @override
  String get lvPickTakesEffect => 'Działa od razu.';

  @override
  String get lvPickSaved => 'Widok zapisany';

  @override
  String get lvPickTorTitle => 'Łączenie przez Tor';

  @override
  String get lvPickTorLead =>
      'Pierwsze połączenie przez Tor może potrwać minutę.';

  @override
  String get lvPickTorBusy => 'Budowanie obwodu…';

  @override
  String get lvPickTorBlocked =>
      'Jeśli Tor jest u ciebie zablokowany, portfel nie połączy się, dopóki nie wyłączysz Incognito.';

  @override
  String get lvPickTorOff => 'Wyłącz Incognito';

  @override
  String get lvPickTorOffDone => 'Incognito wyłączone. Łączenie bezpośrednio.';

  @override
  String get lvPickNetworkOk => 'Sieć OK';

  @override
  String get lvPickEpicboxOk => 'Epicbox OK';

  @override
  String get lvPayArriving => 'W drodze';

  @override
  String lvPayConfirming(int count, int target) {
    return 'Potwierdzanie $count z $target';
  }

  @override
  String lvPayConfirmingOf(int count, int target) {
    return 'Potwierdzanie $count z $target';
  }

  @override
  String lvPaySigned(String name) {
    return '$name podpisał(a)';
  }

  @override
  String get lvPaySendQrLink => 'Oba telefony obok? Płatność QR';

  @override
  String get lvPaySendAddressLink => 'Wyślij raczej na adres';

  @override
  String get lvPayOnItsWay => 'W drodze';

  @override
  String get lvPayCloseNote =>
      'Możesz to zamknąć. Płatność jest w Aktywności, aż się zakończy.';

  @override
  String lvPayArrivalFrom(String amount, String name) {
    return '$amount od $name';
  }

  @override
  String get lvPayOpen => 'Otwórz';

  @override
  String get lvPayNewToday => 'Nowy dzisiaj';

  @override
  String get lvPayNewAddress => 'Twój nowy adres';

  @override
  String lvPayServerLine(String name) {
    return 'Serwer Epicbox: $name.';
  }

  @override
  String get lvPayOldAddressLine => 'Kto ma stary adres, potrzebuje nowego.';

  @override
  String get lvPayReceiveBack => 'Wróć do mojego adresu';

  @override
  String lvPayDoneSent(String when) {
    return 'Wysłano. Zakończono: $when.';
  }

  @override
  String lvPayDoneReceived(String when) {
    return 'Otrzymano. Zakończono: $when.';
  }

  @override
  String get lvPayShowSteps => 'Pokaż kroki';

  @override
  String get lvPayHideSteps => 'Ukryj kroki';

  @override
  String get lvPayDetails => 'Szczegóły';

  @override
  String get lvPayStarted => 'Rozpoczęto';

  @override
  String get lvPayPosted => 'Wysłano do sieci';

  @override
  String get lvPayPaymentId => 'ID płatności';

  @override
  String get lvPayConfirmations => 'Potwierdzenia';

  @override
  String lvPayOf(int count, int target) {
    return '$count z $target';
  }

  @override
  String get lvPayCopyDetails => 'Kopiuj szczegóły';

  @override
  String get lvPayDetailsCopied => 'Skopiowano szczegóły';

  @override
  String lvShellStatusTip(String name, String state) {
    return '$name · $state';
  }

  @override
  String get lvShellStateBehind => 'Opóźniony';

  @override
  String get lvShellStateCatchingUp => 'Nadrabia';

  @override
  String get lvShellStateConnecting => 'Łączenie';

  @override
  String get lvShellOpensDetails => 'Pokazuje szczegóły';

  @override
  String get lvShellLatestBlock => 'Najnowszy blok';

  @override
  String get lvShellThisWallet => 'Ten portfel';

  @override
  String get lvShellUpToDate => 'Aktualny';

  @override
  String get lvShellNotChecked => 'Jeszcze nie sprawdzono';

  @override
  String get lvShellLastChange => 'Ostatnia zmiana';

  @override
  String get lvShellBoxListening => 'Połączono · czeka na płatności';

  @override
  String get lvShellBoxNotReachable => 'Nieosiągalny · próbuje dalej';

  @override
  String get lvShellBoxDownBody =>
      'Płatności do Ciebie czekają i dotrą, gdy serwer wróci. Nic się nie zmienia, dopóki nie przełączysz.';

  @override
  String lvShellOfferReady(String name) {
    return '$name jest gotowy';
  }

  @override
  String lvShellOfferBody(String name) {
    return 'Przełączenie da Ci nowy adres na $name. Każdy, kto ma Twój stary adres, potrzebuje nowego.';
  }

  @override
  String lvShellSwitchTo(String name) {
    return 'Przełącz na $name';
  }

  @override
  String get lvShellKeepWaiting => 'Czekaj dalej';

  @override
  String get lvShellRelayDownTitle => 'Twój serwer Epicbox jest nieosiągalny.';

  @override
  String lvShellRelayDownShort(String name) {
    return '$name może przejąć; Twój adres zmieni się razem z nim.';
  }

  @override
  String get lvShellSwitch => 'Przełącz';

  @override
  String lvShellSwitchedNotice(String name) {
    return 'Teraz na $name. Twój nowy adres jest gotowy.';
  }

  @override
  String lvShellNowOn(String name) {
    return 'Teraz na $name';
  }

  @override
  String get lvShellSwitchedBody =>
      'Twój nowy adres jest gotowy. Każdy, kto ma Twój stary adres, potrzebuje nowego.';

  @override
  String get lvShellShowNewAddress => 'Pokaż nowy adres';

  @override
  String get lvShellServer => 'Serwer';

  @override
  String get lvShellAddress => 'Adres';

  @override
  String lvShellPairNotice(String name) {
    return '$name chce sparować się z tym portfelem.';
  }

  @override
  String get lvShellSeeRequest => 'Zobacz prośbę';

  @override
  String lvShellQuietArriving(String amount) {
    return '+$amount w drodze';
  }

  @override
  String lvShellQuietOnHold(String amount) {
    return '$amount wstrzymane';
  }

  @override
  String get lvShellLevelCaption =>
      'Głębszy widok pokazuje więcej portfela. Nic zapisanego się nie zmienia.';

  @override
  String get lvPolPosted => 'Wysłano';

  @override
  String get lvPolInvoiceWaiting => 'Faktura · czeka na twoje zatwierdzenie';

  @override
  String lvPolAbout(String name) {
    return 'O $name';
  }

  @override
  String get deskLvStartPreviewLabel =>
      'Podgląd Przeglądu. Pokazuje więcej, im głębiej ustawisz pokrętło.';

  @override
  String get deskLvStartPreviewCaption =>
      'Twój Przegląd w tym widoku. Nic zapisanego się nie zmienia.';

  @override
  String get deskLvStartCover => 'Wybierz punkt, aby zobaczyć podgląd';

  @override
  String get deskLvStartUndercoverAbout => 'O trybie Tylko Tor';

  @override
  String get deskLvStartHelpShallow =>
      'Płytko · jeden adres, bez nazw serwerów, bez przełączników.';

  @override
  String get deskLvStartHelpDeeper =>
      'Głębiej · ten sam portfel, plus to, co robi, prostymi słowami.';

  @override
  String get deskLvStartHelpDeep =>
      'Na głęboką wodę · każdy przełącznik, każda liczba: dzisiejsza aplikacja.';

  @override
  String get deskLvStartMiniWallet => 'Główny portfel';

  @override
  String get deskLvStartMiniLine => '+12,5 nadchodzi · 25,0 wstrzymane';

  @override
  String get deskLvStartMiniFresh => 'Świeże z kopania';

  @override
  String get deskLvStartMiniWaiting => 'Czeka na drugą stronę';

  @override
  String get deskLvSendHowTo => 'Jak to wysłać';

  @override
  String get deskLvSendButton => 'Wyślij';

  @override
  String deskLvSendButtonAmount(String amount) {
    return 'Wyślij $amount EPIC';
  }

  @override
  String deskLvSendButtonTo(String amount, String name) {
    return 'Wyślij $amount EPIC do $name';
  }

  @override
  String get deskLvSendNothingLeaves =>
      'Nic nie wychodzi, dopóki nie naciśniesz Wyślij. Potem nie da się tego cofnąć.';

  @override
  String get deskLvSendPasswordTitle => 'Twoje hasło';

  @override
  String get deskLvSendConfirm => 'Wyślij';

  @override
  String deskLvSendLiveTo(String name) {
    return 'W drodze do $name';
  }

  @override
  String deskLvSendLiveAmountTo(String amount, String name) {
    return '$amount EPIC do $name';
  }

  @override
  String deskLvSendLiveAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskLvSendYourAddress => 'Twój adres';

  @override
  String get deskLvSendReady => 'Gotowe do odbioru';

  @override
  String get deskLvSendClosedInfo =>
      'Płatności wysłane, gdy portfel był zamknięty, dotrą po jego otwarciu.';

  @override
  String get deskLvSendPayFiles => 'Pliki płatności';

  @override
  String get deskLvSendSignFile => 'Podpisz plik płatności';

  @override
  String get deskLvSendSignFileText =>
      'Otwórz plik od nadawcy i zapisz swoją odpowiedź.';

  @override
  String get deskLvSendFinishFile => 'Dokończ plik odpowiedzi';

  @override
  String get deskLvSendFinishFileText =>
      'Otwórz otrzymaną odpowiedź, aby opublikować płatność.';

  @override
  String get deskLvSendPrevAddress => 'Poprzedni adres';

  @override
  String deskLvSendPrevText(String server) {
    return 'Stary adres był na $server. Każdy, kto go ma, potrzebuje nowego.';
  }

  @override
  String get deskLvPayS1Sent => 'Slate S1 wysłany przez Epicbox · czeka na S2';

  @override
  String deskLvPayS1On(String relay) {
    return 'S1 na $relay · czeka na S2';
  }

  @override
  String deskLvPayNotOpen(String name) {
    return 'Portfel $name nie jest jeszcze otwarty';
  }

  @override
  String deskLvPayWaitingOpen(String name) {
    return 'Czekanie na otwarcie portfela $name';
  }

  @override
  String get deskLvPaySenderFinished => 'Nadawca skończył';

  @override
  String get deskLvPayPostedNode => 'Opublikowano w węźle';

  @override
  String deskLvPayConfirmingComma(int count, int target) {
    return 'Potwierdzanie, $count z $target';
  }

  @override
  String deskLvPayConfirmationsOf(int count, int target) {
    return 'Potwierdzenia $count / $target';
  }

  @override
  String get deskLvPayDone => 'Gotowe';

  @override
  String deskLvPayOnItsWayTo(String name) {
    return 'W drodze do $name';
  }

  @override
  String deskLvPaySendingTo(String name) {
    return 'Wysyłanie do $name';
  }

  @override
  String deskLvPayArrivingFrom(String name) {
    return 'Nadchodzi od $name';
  }

  @override
  String deskLvPayStartedAt(String amount, String time) {
    return '$amount EPIC · rozpoczęto $time';
  }

  @override
  String deskLvPayHeroArriving(String amount, String name) {
    return '+$amount nadchodzi od $name';
  }

  @override
  String deskLvPayHeroArrivingMany(String amount) {
    return '+$amount nadchodzi';
  }

  @override
  String deskLvPayHeroHold(String amount, String name) {
    return '$amount wstrzymane, dopóki $name nie podpisze';
  }

  @override
  String deskLvPayHeroHoldMany(String amount) {
    return '$amount wstrzymane do podpisania';
  }

  @override
  String get deskLvPayHeroNothing => 'Nic jeszcze nie nadchodzi.';

  @override
  String get deskLvPayReadyTitle => 'Twój portfel jest gotowy.';

  @override
  String get deskLvPayReadyHead => 'Portfel gotowy';

  @override
  String get deskLvPayReadyText =>
      'Udostępnij adres, aby dostać pierwsze EPIC.';

  @override
  String get deskLvPayTileConfirming => 'Wciąż potwierdzane';

  @override
  String get deskLvPayTileMining => 'Świeże z kopania';

  @override
  String get deskLvPayTileWaiting => 'Czeka na drugą stronę';

  @override
  String get deskLvPayTileAwaiting => 'Czeka na odpowiedź';

  @override
  String get deskLvPayTileLocked => 'Odłożone na wysyłki';

  @override
  String get deskLvPayImmatureCasual => 'Świeże z kopania, jeszcze niedostępne';

  @override
  String get deskLvPayKind => 'Płatność';

  @override
  String get deskLvShellNewsTitle => 'Nowość: widok portfela';

  @override
  String get deskLvShellNewsText =>
      'Ta instalacja pokazuje wszystko, jak dotąd. Płytko i Głębiej pokazują mniej.';

  @override
  String get deskLvShellNewsLook => 'Zobacz';

  @override
  String get deskLvShellFailover => 'Przełączanie węzła';

  @override
  String get deskLvShellOn => 'Włączone';

  @override
  String get deskLvShellHeight => 'Wysokość';

  @override
  String get deskLvShellVersion => 'Wersja';

  @override
  String get deskLvShellRecheckHint =>
      'Jeśli kwota wygląda źle, portfel czyta łańcuch ponownie.';

  @override
  String get lvShellSwitchServer => 'Zmień serwer';

  @override
  String get lvShellNoOtherServer => 'Brak innego serwera na liście.';

  @override
  String get deskLvShellSwitchServer => 'Zmień serwer';

  @override
  String get deskLvShellNoOtherServer => 'Na liście nie ma innego serwera.';

  @override
  String get deskLastSessionFroze =>
      'Aplikacja nie odpowiadała ostatnim razem. Wysłać log?';

  @override
  String get deskLastSessionClosed =>
      'Aplikacja zamknęła się nieoczekiwanie ostatnim razem. Wysłać log?';

  @override
  String get deskLastSessionSend => 'Wyślij';

  @override
  String get deskLastSessionNotNow => 'Nie teraz';

  @override
  String get deskLastSessionReportFroze => 'Aplikacja nie odpowiadała.';

  @override
  String get deskLastSessionReportClosed =>
      'Aplikacja zamknęła się nieoczekiwanie.';

  @override
  String get deskLastSessionAttached => 'Z logiem z ostatniej sesji.';

  @override
  String get deskSetPrivUndercoverLine => 'Incognito utrzymuje Tor włączony.';

  @override
  String get deskSetPrivUndercoverChange => 'Zmień Incognito';

  @override
  String get deskNodeEtaCalculating => 'Obliczanie pozostałego czasu…';

  @override
  String deskNodeEtaLeft(String time) {
    return 'zostało około $time';
  }

  @override
  String get deskNodeEtaMinute => 'minuty';

  @override
  String deskNodeEtaMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String deskNodeEtaHours(int hours) {
    return '$hours godz.';
  }

  @override
  String deskNodeEtaHoursMinutes(int hours, int minutes) {
    return '$hours godz. $minutes min';
  }

  @override
  String deskNodeSwitchConnecting(String host) {
    return 'Łączenie z $host…';
  }

  @override
  String get deskNodeSwitchStarting => 'Uruchamianie węzła lokalnego…';

  @override
  String get deskNodeSwitchStopping => 'Zatrzymywanie węzła lokalnego…';

  @override
  String get deskNodeSwitchStoppingWord => 'Zatrzymywanie';

  @override
  String get deskOnbFailedTitle => 'Nie ukończono';

  @override
  String deskOnbRestoreBadWords(String words) {
    return 'Nie ma na liście słów: $words.';
  }

  @override
  String get deskLvPayOnEpicbox => 'Na Epicbox';

  @override
  String get deskRailReceivingInternet => 'Odbiera · internet';

  @override
  String get deskRailReceivingLocal => 'Odbiera · lokalnie';

  @override
  String get deskOnbImportFoundLead => 'Dalej, aby wybrać portfele do dodania.';

  @override
  String get deskOnbForgotFailedTitle => 'Hasło nie zostało zmienione';

  @override
  String get deskOnbForgotFailedLead => 'Obecne hasło nadal otwiera portfel.';

  @override
  String get deskSetHelpSupportHead => 'Wsparcie';

  @override
  String deskKitPasswordRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count znaku lub więcej',
      many: '$count znaków lub więcej',
      few: '$count znaki lub więcej',
      one: '$count znak lub więcej',
    );
    return '$_temp0';
  }

  @override
  String trustLineOtherApp(Object name) {
    return 'Na ostatnią płatność $name odpowiedziała inna aplikacja portfela.';
  }

  @override
  String trustLineNotHeard(Object name, Object date) {
    return 'Brak wieści od portfela $name od $date.';
  }

  @override
  String get mailboxNotAnswered => 'Jeszcze bez odpowiedzi';

  @override
  String get mailboxNotPickedUp => 'Nieodebrana';

  @override
  String mailboxNeverPickedUp(Object name) {
    return 'Portfel $name nigdy tego nie odebrał.';
  }

  @override
  String get mailboxResendTitle => 'Anuluj i wyślij na publiczny adres Epicbox';

  @override
  String get mailboxResendTitleShort => 'Anuluj i wyślij na publiczny adres';

  @override
  String mailboxResendBody(Object name) {
    return 'Oczekująca płatność zostanie anulowana, a ta sama kwota trafi na publiczny adres Epicbox $name jako zwykła płatność. W Aktywności zostaną dwa wiersze.';
  }

  @override
  String get mailboxResendAction => 'Anuluj i wyślij';

  @override
  String get mailboxKeepWaiting => 'Czekaj dalej';

  @override
  String get linkPayeeLead => 'Odbiorca';

  @override
  String get linkPayeeMid => 'odbiorca';

  @override
  String get linkResendBody =>
      'Oczekująca płatność zostanie anulowana, a Wyślij otworzy się z tą samą kwotą. Sprawdź adres i wyślij ponownie.';

  @override
  String receiptTellSent(Object name) {
    return 'Powiadom $name, że wysłano';
  }

  @override
  String receiptTellPosted(Object name) {
    return 'Powiadom $name, że trafiło do sieci';
  }

  @override
  String receiptTold(Object name) {
    return 'Powiadomiono $name';
  }

  @override
  String receiptSeesSent(Object name, Object id, Object amount, Object time) {
    return '$name zobaczy: prośba $id, $amount, wysłano $time. Nic więcej nie jest przekazywane: ani adres, ani identyfikator transakcji.';
  }

  @override
  String receiptSeesPosted(Object name, Object id, Object amount, Object time) {
    return '$name zobaczy: prośba $id, $amount, w sieci od $time. Nic więcej nie jest przekazywane: ani adres, ani identyfikator transakcji.';
  }

  @override
  String receiptNotSent(Object name) {
    return 'Teraz nie udało się powiadomić $name. Spróbuj ponownie.';
  }

  @override
  String get receiptHintTitle => 'Potwierdzenie';

  @override
  String get mailboxResent => 'Anulowano i wysłano na publiczny adres Epicbox.';

  @override
  String get torRelayCaption =>
      'Z włączonym Torem połączenie z serwerem Epicbox idzie przez Tor.';

  @override
  String get inviteLinkUnreadable => 'Nie można otworzyć tego linku.';

  @override
  String inviteLinkNoHandler(String feature) {
    return '$feature: wyłączone lub niedostępne w tym portfelu.';
  }

  @override
  String get linkShowMine => 'Pokaż mój QR';

  @override
  String get linkPasteAnother => 'Wklej inne zaproszenie';

  @override
  String linkLinkingWith(String name) {
    return 'Łączenie z $name…';
  }

  @override
  String linkLinkingSame(String name) {
    return '$name pokazuje te same cztery.';
  }

  @override
  String linkFailFull(String name) {
    return '$name jest już połączony z innym urządzeniem. Najpierw usuń je na $name.';
  }

  @override
  String get linkFailUpdate =>
      'Drugie urządzenie ma nowszą aplikację. Zaktualizuj tę i spróbuj ponownie.';

  @override
  String linkFailUpdateOther(String name) {
    return '$name ma starszą aplikację. Zaktualizuj ją tam i spróbuj ponownie.';
  }

  @override
  String linkReplaceTitle(String name) {
    return 'Zastąpić $name?';
  }

  @override
  String linkReplaceBody(String name) {
    return 'Nowe urządzenie prosi o połączenie. $name przestaje dostawać komunikaty tego portfela; monety, które tu wstrzymuje, zostają zwolnione.';
  }

  @override
  String get linkReplace => 'Zastąp';

  @override
  String linkKeep(String name) {
    return 'Zostaw $name';
  }

  @override
  String devicesEpicboxOff(String name) {
    return 'Epicbox jest wyłączony: $name nie widzi płatności tego urządzenia.';
  }

  @override
  String get devicesEpicboxOffNone => 'Epicbox jest wyłączony.';

  @override
  String devicesUpdateOther(String name) {
    return 'Zaktualizuj $name, aby ten portfel pozostał zsynchronizowany.';
  }

  @override
  String get devicesAbout => 'O połączonym urządzeniu';

  @override
  String get offerLinkThird =>
      'Trzecie urządzenie ma ten portfel. Połączyć można dwa.';

  @override
  String devicesForwardedInvoice(String name) {
    return '$name otrzymał prośbę o zapłatę. Zapłać tam.';
  }

  @override
  String get linkConfirmInvite =>
      'Połączyć to urządzenie z tym, które wysłało zaproszenie?';

  @override
  String get pairYourCode => 'Twoje zaproszenie';

  @override
  String get pairCodeCaption =>
      'Niech zeskanują kod QR albo wyślij zaproszenie.';

  @override
  String pairCodeCaptionFor(String name) {
    return 'Niech $name zeskanuje kod QR albo wyślij zaproszenie.';
  }

  @override
  String pairSeenAsLine(String name) {
    return 'Widzą cię jako $name';
  }

  @override
  String get pairChange => 'Zmień';

  @override
  String get pairSeenAsField => 'Widzą cię jako';

  @override
  String get pairCopyLink => 'Kopiuj zaproszenie';

  @override
  String get pairHaveTheirCode => 'Masz ich zaproszenie?';

  @override
  String pairHaveNamesCode(String name) {
    return 'Masz zaproszenie od $name?';
  }

  @override
  String get pairScan => 'Skanuj QR';

  @override
  String get pairPasteField => 'Wklej zaproszenie';

  @override
  String get pairNotACode => 'To nie jest zaproszenie do parowania.';

  @override
  String get pairEpicboxOffLine =>
      'Epicbox jest wyłączony. Wklej odpowiedź poniżej, gdy wróci.';

  @override
  String get pairWaitingAnswer => 'Czekanie na odpowiedź…';

  @override
  String pairAnsweredFinishing(String name) {
    return '$name odpowiedział(a) na zaproszenie. Czekanie, aż portfel $name dokończy.';
  }

  @override
  String get pairFinishCodeTitle => 'Potwierdzenie';

  @override
  String pairFinishCodeBody(String name) {
    return 'Wyślij to do $name. Sprawdzanie słów otworzy się, gdy ten portfel to odczyta.';
  }

  @override
  String get pairYourAnswerBody =>
      'Odeślij ją tą samą drogą, którą przyszło zaproszenie. Potem wklej to, co wróci.';

  @override
  String get pairPasteFinishField => 'Wklej potwierdzenie';

  @override
  String pairPairingWith(String name) {
    return 'Parowanie z $name…';
  }

  @override
  String get pairInContacts => 'W twoich kontaktach';

  @override
  String get pairRequestBody =>
      'Prośba trafia na adres Epicbox tego kontaktu. Jego portfel pokaże ją, gdy będzie otwarty.';

  @override
  String get pairSendRequest => 'Wyślij prośbę';

  @override
  String get pairShowMyCodeInstead => 'Pokaż zamiast tego moje zaproszenie';

  @override
  String pairRequestSent(String date) {
    return 'Prośba wysłana · $date';
  }

  @override
  String pairWaitingFor(String name) {
    return 'Czekanie na portfel $name';
  }

  @override
  String get pairAnsweredNotHeard =>
      'Odpowiedź na twoje zaproszenie · jeszcze bez wieści';

  @override
  String pairNotChecked(String name) {
    return '$name jeszcze nie sprawdził(a)';
  }

  @override
  String contactTakesPaymentsAgain(String name) {
    return '$name znów przyjmuje płatności.';
  }

  @override
  String get pairIsService => 'Usługa automatyczna.';

  @override
  String pairConfirmedToo(String name) {
    return '$name też potwierdził(a).';
  }

  @override
  String get pairEndedShort => 'Parowanie zakończone';

  @override
  String get pairEndedMismatch => 'Zgłoszono, że słowa się nie zgadzają.';

  @override
  String pairEndedPeerMismatch(String name) {
    return '$name zgłosił(a), że słowa się nie zgadzają.';
  }

  @override
  String pairEndedNeverFinished(String name) {
    return 'Portfel $name nigdy nie dokończył.';
  }

  @override
  String get pairEndedRowPeerMismatch =>
      'Zgłoszono, że słowa się nie zgadzają.';

  @override
  String get pairEndedRowNeverFinished => 'Portfel nigdy nie dokończył.';

  @override
  String get pairEndedRowUnpaired => 'Parowanie usunięte po tamtej stronie.';

  @override
  String pairNoAnswerFrom(String name) {
    return 'Brak odpowiedzi od portfela $name';
  }

  @override
  String get pairAgain => 'Paruj ponownie';

  @override
  String get pairAddressNotConfirmed =>
      'Adres niepotwierdzony przez parowanie.';

  @override
  String get pairHeldSend => 'Czeka na odbiorcę';

  @override
  String pairProvesOther(String name) {
    return 'Portfel $name potwierdza inny adres';
  }

  @override
  String get pairUpdateAddress => 'Zaktualizuj adres kontaktu';

  @override
  String get pairDetach => 'Odłącz';

  @override
  String get pairCheckWords => 'Sprawdź słowa';

  @override
  String pairWantsToPair(String name) {
    return '$name chce sparować.';
  }

  @override
  String pairPairedWith(String name) {
    return 'Sparowano z $name.';
  }

  @override
  String pairPairedOn(String device) {
    return 'Sparowano na $device.';
  }

  @override
  String pairRequestsRow(int count) {
    return 'Prośby o parowanie · $count';
  }

  @override
  String get pairRequestsTitle => 'Prośby o parowanie';

  @override
  String get pairEndedNotice =>
      'Parowanie zakończone. Sparuj ponownie z nowym zaproszeniem.';

  @override
  String get pairOtherWalletTitle => 'Ta odpowiedź przyszła z innego portfela.';

  @override
  String get pairOtherWalletBody => 'Niczego nie zapisano.';

  @override
  String get pairKindDiffersTitle => 'Ta odpowiedź nie pasuje do zaproszenia.';

  @override
  String get pairKindDiffersBody =>
      'Podaje inny rodzaj kontaktu niż zaproszenie. Niczego nie zapisano. Sparuj ponownie.';

  @override
  String pairNotProvenBody(String name) {
    return 'Nie było jeszcze płatności Epic Cash z $name, więc nie można wysłać prośby.';
  }

  @override
  String pairInProgressTitle(String name) {
    return 'Parowanie z $name już trwa.';
  }

  @override
  String pairCrossedTitle(String name) {
    return 'Portfel $name też zaczął parowanie. Czekanie na jego odpowiedź.';
  }

  @override
  String pairDismissedTitle(String name) {
    return 'Ta prośba została odrzucona. Poproś $name o nową.';
  }

  @override
  String get pairEndedBody =>
      'Nic nowego już przez nie nie przejdzie. Usuń je albo sparuj ponownie z nowym zaproszeniem.';

  @override
  String get pairWaitingSendBody => 'Wyślij zamiast tego przez Epicbox.';

  @override
  String get pairNotFoundTitle => 'Żadne parowanie do tego nie pasuje.';

  @override
  String get trustWaiting => 'Oczekuje';

  @override
  String get trustEnded => 'Zakończone';

  @override
  String get trustNotAnswering => 'Brak odpowiedzi';

  @override
  String get contactNotAnsweringBody =>
      'Faktury i płatności mogą do nich nie dotrzeć.';

  @override
  String get pairRequestPair => 'Paruj';

  @override
  String get pairCancelPairingTitle => 'Anulować to parowanie?';

  @override
  String pairCancelPairingBody(String name) {
    return 'Portfel $name dowie się, jeśli odpowie późno. Nic nie zostanie zachowane.';
  }

  @override
  String get pairCancelPairing => 'Anuluj parowanie';

  @override
  String get pairBackLater => 'Wstecz';

  @override
  String get helpPairRouteTitle => 'Płatności po sparowaniu';

  @override
  String get helpPairRouteShort =>
      'Płatności do sparowanego kontaktu idą przez parowanie; publiczny adres Epicbox jest drogą zapasową.';

  @override
  String get helpPairRouteP1 =>
      'Po sparowaniu płatność do tego kontaktu domyślnie idzie przez parowanie, czyli prywatną trasą. W [[Wyślij|Send]] przełącznik **Wyślij przez parowanie** jest na początku włączony.';

  @override
  String get helpPairRouteP2 =>
      'Płatność idzie zamiast tego na publiczny adres Epicbox kontaktu, gdy: kontakt nie jest sparowany; przełącznik jest wyłączony; kontakt ostatnio odpowiedział z innej aplikacji portfela; od kontaktu nie było wieści od 90 dni; wysyłka przez parowanie została bez odpowiedzi przez dobę; albo jego serwer nie działa.';

  @override
  String get helpPairRouteP3 =>
      'Wysyłka przez parowanie, na którą nikt nie odpowiada przez dobę, pokazuje **Anuluj i wyślij na publiczny adres Epicbox**. Portfel najpierw pyta; kolejne wysyłki do tego kontaktu zaczynają się wtedy od adresu publicznego.';

  @override
  String get helpPairRouteP4 =>
      '**Pieczętuj pliki transakcji** na stronie kontaktu szyfruje pliki wysyłane do tego kontaktu. Są zapieczętowane i tylko ten kontakt może je odczytać. Przełącznik dotyczy samych plików; nie włącza ani nie wyłącza trasy przez parowanie.';

  @override
  String get helpPairRouteP5 =>
      'Parowanie przez zaproszenie lub kod QR nie ma publicznego adresu Epicbox jako drogi zapasowej, chyba że kontakt ma adres Epicbox w [[Kontakty|Contacts]].';

  @override
  String get helpPairTwoWaysTitle => 'Dwa sposoby parowania';

  @override
  String get helpPairTwoWaysShort =>
      'Prośba do kontaktu albo twoje zaproszenie.';

  @override
  String get helpPairTwoWaysP1 =>
      '**Paruj z kontaktem.** Przy kontakcie, któremu płaciłeś lub który płacił tobie przez Epicbox, Paruj wysyła prośbę na ten adres. Jego portfel pokaże ją, gdy będzie otwarty; jedno dotknięcie odpowiada. Oba portfele kończą jako Zweryfikowane bez sprawdzania słów: prośba i odpowiedź potwierdzają adres, który już jest w kontaktach drugiej strony.';

  @override
  String get helpPairTwoWaysP2 =>
      '**Paruj zaproszeniem.** Kontakty › Paruj pokazuje twoje zaproszenie, ważne 7 dni. Drugi portfel skanuje je albo otwiera link; oba kończą przez Epicbox, a potem porównują cztery słowa. Gdy po którejś stronie Epicbox jest wyłączony, ten sam ekran przenosi odpowiedź i potwierdzenie ręcznie: Udostępnij i Wklej.';

  @override
  String get helpPairTwoWaysP3 =>
      'Prośba idzie tylko do portfela, który pokazał, że działa na BT Wallet: oznaczona płatność między tymi dwoma adresami w ostatnich 30 dniach. Dla każdego innego Paruj pokazuje twoje zaproszenie.';

  @override
  String get helpPairWhyTitle2 => 'Po co sprawdzać słowa';

  @override
  String get helpPairWhyShort2 =>
      'Porównajcie je osobiście, głosem albo wideo.';

  @override
  String get helpPairWhyP1b =>
      'Po parowaniu zaproszeniem oba portfele pokazują te same cztery obrazki i nazwy. Porównaj je z drugą osobą osobiście, głosem albo na wideorozmowie, nigdy w czacie, którym przyszło zaproszenie: kto mógłby podmienić zaproszenie po drodze, mógłby też podmienić to, co pokazuje ten czat.';

  @override
  String get helpPairWhyP2b =>
      '**Zgadzają się** oznacza kontakt jako Zweryfikowany; drugi portfel dowiaduje się o tym i pokazuje „też potwierdził(a)”. **Nie zgadzają się** kończy parowanie po obu stronach i nic, co przez nie wysłano, nie zostanie dokończone. Omyłkowe Nie też je kończy: sparuj ponownie z nowym zaproszeniem.';

  @override
  String get helpPairWhyP3b =>
      'Zweryfikowany oznacza portfel stojący za adresem w twoich kontaktach. Po prośbie między dwoma kontaktami ustawia się bez słów, bo prośba i odpowiedź potwierdziły ten adres.';

  @override
  String get helpPairWhyP4b =>
      '„Potwierdzony” znaczy, że w ostatnich 30 dniach między tymi dwoma adresami Epicbox przeszła płatność oznaczona przez oba portfele. Kontakt, na który od tego czasu odpowiedziała inna aplikacja portfela, nie jest potwierdzony do następnej oznaczonej płatności.';

  @override
  String get pairStandingFootnote =>
      'Ważne 7 dni. Nowe zaproszenie pojawi się, gdy to zostanie użyte.';

  @override
  String get storeEncrypting => 'Szyfrowanie danych portfela…';

  @override
  String get storeRecordsPlain =>
      'Dane portfela na razie pozostają niezaszyfrowane. Kolejna próba nastąpi przy następnym uruchomieniu.';

  @override
  String get errorStoreWrongKey =>
      'Danych tego portfela nie udało się otworzyć tą frazą. Nic nie zostało zmienione.';

  @override
  String get contactsClosedTitle => 'Książka adresowa zamknięta';

  @override
  String get contactsClosedText =>
      'Otworzy się po odblokowaniu portfela, który z niej korzysta.';

  @override
  String get pairSeenAsHint => 'Opcjonalnie';

  @override
  String devicesNameWithCode(String name, String code) {
    return '$name $code';
  }

  @override
  String get deskSetDlgRemoveUnlockHintSecurity =>
      'Aby usunąć także jego pliki, odblokuj ten portfel i użyj Usuń portfel w Ustawienia › Portfel.';

  @override
  String get deskRecvHttpTorHintNet =>
      'Aby zamiast tego mieć adres Tor, włącz Tor w Ustawienia › Sieć i prywatność.';

  @override
  String get deskRecvTorIntroNet =>
      'Prosto z innego portfela przez Tor, gdy ten jest otwarty. Tor ustawisz w Ustawienia › Sieć i prywatność.';

  @override
  String get deskRecvTorOffTextNet =>
      'Adres Tor działa, gdy Tor jest włączony. Tor to przełącznik w Ustawienia › Sieć i prywatność; kieruje połączenia portfela przez Tor.';

  @override
  String get deskRailOpenNetworkPrivacy => 'Otwórz Sieć i prywatność';

  @override
  String get deskSetSearchHint => 'Szukaj w ustawieniach';

  @override
  String get deskSetSearchKeyHint => 'Ctrl K';

  @override
  String get deskSetSearchClear => 'Wyczyść wyszukiwanie';

  @override
  String deskSetSearchCount(int count) {
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
  String deskSetSearchFor(String query) {
    return 'dla „$query”';
  }

  @override
  String get deskSetSearchKeysMove => 'wybór';

  @override
  String get deskSetSearchKeysGo => 'przejdź do ustawienia';

  @override
  String get deskSetSearchKeysClear => 'wyczyść';

  @override
  String deskSetSearchMatches(String word) {
    return 'Pasuje do „$word”';
  }

  @override
  String get deskSetSearchHelpTopics => 'Tematy pomocy';

  @override
  String get deskSetSearchHidden => 'Ukryte tutaj';

  @override
  String get deskSetSearchHiddenLine =>
      'Pokazuje je inny widok lub przełącznik w Zaawansowanych';

  @override
  String deskSetSearchShowIn(String view) {
    return 'Pokaż w: $view';
  }

  @override
  String get deskSetSearchTurnOn => 'Włącz';

  @override
  String get deskSetSearchOpen => 'Otwórz';

  @override
  String get deskSetSearchRead => 'Czytaj';

  @override
  String deskSetSearchNone(String query) {
    return 'Żadne ustawienie nie pasuje do „$query”.';
  }

  @override
  String get deskSetSearchTry => 'Spróbuj';

  @override
  String get deskSetSearchTryWords =>
      'hasło,tor,fraza,kopia,opłata,węzeł,blokada';

  @override
  String get deskSetSearchNoResults => 'Brak wyników';

  @override
  String get deskSetSearchResults => 'Wyniki wyszukiwania';

  @override
  String deskSetSearchViewGate(String view) {
    return 'widok $view';
  }

  @override
  String deskSetSearchFeatGate(String feature) {
    return 'Zaawansowane › $feature';
  }

  @override
  String deskSetSearchGateJoin(String first, String last) {
    return '$first i $last';
  }

  @override
  String deskSetSearchMore(int count, String gates) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opcji więcej · pokazuje je $gates',
      many: '$count opcji więcej · pokazuje je $gates',
      few: '$count opcje więcej · pokazuje je $gates',
      one: '$count opcja więcej · pokazuje ją $gates',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchLess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ukryj $count dodatkowej opcji',
      many: 'Ukryj $count dodatkowych opcji',
      few: 'Ukryj $count dodatkowe opcje',
      one: 'Ukryj dodatkową opcję',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchViewApplied(String view) {
    return 'Widok: $view';
  }

  @override
  String deskSetSearchFeatApplied(String feature) {
    return 'Zaawansowane › $feature: wł.';
  }

  @override
  String deskSetSearchFallbackView(String page, String view) {
    return '$page jest w widoku $view.';
  }

  @override
  String deskSetSearchFallbackFeat(String page, String feature) {
    return '$page pojawia się po włączeniu Zaawansowane › $feature.';
  }

  @override
  String get deskSetSecWallet => 'Portfel';

  @override
  String get deskSetSecPayments => 'Płatności';

  @override
  String get deskSetSecDevices => 'Połączone urządzenia';

  @override
  String get deskSetSecWallets => 'Portfele';

  @override
  String get deskSetSecFiles => 'Pliki i logi';

  @override
  String get deskSetNavApp => 'Aplikacja';

  @override
  String get deskSetNavComputer => 'Ten komputer';

  @override
  String get deskSetGrpBackup => 'Kopia zapasowa';

  @override
  String get deskSetGrpBalance => 'Saldo';

  @override
  String get deskSetGrpRemove => 'Usuwanie';

  @override
  String get deskSetGrpMethods => 'Metody';

  @override
  String get deskSetGrpSending => 'Wysyłanie';

  @override
  String get deskSetGrpReceiving => 'Odbieranie';

  @override
  String get deskSetGrpThisDevice => 'To urządzenie';

  @override
  String get deskSetGrpLinkedDevice => 'Połączone urządzenie';

  @override
  String get deskSetGrpSync => 'Synchronizacja';

  @override
  String get deskSetGrpConnection => 'Połączenie';

  @override
  String get deskSetGrpLocalNode => 'Węzeł na tym komputerze';

  @override
  String get deskSetGrpConnections => 'Połączenia';

  @override
  String get deskSetGrpTor => 'Tor';

  @override
  String get deskSetGrpServerStatus => 'Stan serwerów';

  @override
  String get deskSetGrpView => 'Widok';

  @override
  String get deskSetGrpShowsMore => 'Pokazuje więcej';

  @override
  String get deskSetGrpExperiments => 'Eksperymenty';

  @override
  String get deskSetGrpOnComputer => 'Na tym komputerze';

  @override
  String get deskSetGrpAddWallet => 'Dodaj portfel';

  @override
  String get deskSetGrpFolders => 'Foldery';

  @override
  String get deskSetGrpLogs => 'Logi';

  @override
  String get deskSetGrpSupport => 'Wsparcie';

  @override
  String get deskSetGrpStartAgain => 'Od nowa';

  @override
  String get deskSetGrpLinks => 'Linki';

  @override
  String get deskSetRowNameHint => 'Widoczna tylko w tej aplikacji.';

  @override
  String get deskSetSynName => 'zmień nazwę, nazwa portfela, etykieta, nazwa';

  @override
  String get deskSetRowExportDataHint =>
      'Historia, kontakty, faktury i ustawienia w jednym zaszyfrowanym pliku.';

  @override
  String get deskSetRowExportDataInfo =>
      'Plik otworzy tylko portfel z tą frazą odzyskiwania. Same monety przywraca fraza odzyskiwania.';

  @override
  String get deskSetSynExportData =>
      'kopia, backup, zapisz, historia, kontakty, plik';

  @override
  String get deskSetRowImportDataHint =>
      'Przywraca historię, kontakty, faktury i ustawienia z eksportu.';

  @override
  String get deskSetSynImportData =>
      'przywróć, kopia, backup, historia, wczytaj';

  @override
  String get deskSetRowExportCsvHint =>
      'Zwykła tabela do arkusza kalkulacyjnego. Bez szyfrowania.';

  @override
  String get deskSetSynExportCsv =>
      'csv, excel, arkusz, podatek, historia, raport';

  @override
  String get deskSetRowRecheckGoHint =>
      'Ponownie odczytuje łańcuch w poszukiwaniu monet tego portfela.';

  @override
  String get deskSetSynRecheckGo =>
      'skanuj ponownie, skan, złe saldo, brakuje, resync, odśwież, napraw';

  @override
  String get deskSetRowDeleteWalletHint =>
      'Usuwa jego klucze i bazę danych z tego komputera.';

  @override
  String get deskSetSynDeleteWallet => 'usuń, skasuj, wymaż';

  @override
  String get deskSetSynRecheckFrom => 'początek, data, wysokość, blok';

  @override
  String get deskSetRowRecheckDropHint =>
      'Anuluje też niepotwierdzone transakcje. Płatność w drodze może się wtedy nie udać.';

  @override
  String get deskSetSynRecheckDrop =>
      'niepotwierdzone, utknęła, anuluj, odblokuj';

  @override
  String get deskSetRowPhraseGoHint =>
      '24 słowa, które przywracają ten portfel.';

  @override
  String get deskSetSynPhraseGo =>
      'seed, fraza, mnemonik, słowa, kopia, sekret, przywróć, 24 słowa, klucz prywatny';

  @override
  String get deskSetRowPasswordHint => 'Odblokowuje ten portfel.';

  @override
  String get deskSetSynPassword => 'hasło, zmień hasło, odblokuj, pin';

  @override
  String get deskSetRowRememberedHint =>
      'Otwiera się przy starcie bez hasła. Wysyłka nadal o nie prosi.';

  @override
  String get deskSetSynRemembered =>
      'zapamiętaj, hasło, odblokuj, automatyczne odblokowanie, zapomnij';

  @override
  String get deskSetRowAutolockHint =>
      'Blokuje, gdy nie ma naciśnięć klawiszy ani ruchu myszy. Wszystkie portfele.';

  @override
  String get deskSetSynAutolock =>
      'blokada, czas, bezczynność, nieaktywność, blokada ekranu';

  @override
  String get deskSetRowEpicboxHint =>
      'Płać i otrzymuj płatności przez serwer Epicbox. Tędy idzie większość płatności. Wszystkie portfele.';

  @override
  String get deskSetSynEpicbox =>
      'relay, serwer, adres, odbiór, wysyłka, metoda';

  @override
  String get deskSetSynEpicboxRecv => 'nasłuch, przychodzące, odbiór';

  @override
  String get deskSetRowEpicboxServerHint => 'Część adresu tego portfela.';

  @override
  String get deskSetSynEpicboxServer => 'relay, serwer, host, adres';

  @override
  String get deskSetSynEpicboxStart => 'autostart, przy starcie';

  @override
  String get deskSetRowHttpHint =>
      'Portfel do portfela pod adresem internetowym, gdy oba są otwarte. Wszystkie portfele.';

  @override
  String get deskSetSynHttp => 'http, ip, port, bezpośrednio, nasłuch, metoda';

  @override
  String get deskSetSynHttpReach =>
      'internet, router, przekierowanie portu, publiczny';

  @override
  String get deskSetSynHttpPort => 'port, tcp';

  @override
  String get deskSetRowTorPayHint =>
      'Portfel do portfela pod adresem Tor tego portfela, gdy oba są otwarte. Wszystkie portfele.';

  @override
  String get deskSetRowTorPayInfo =>
      'Tor działa tylko do wysyłania i odbierania płatności pod adresem Tor. Węzeł, ceny i aktualizacje zachowują ustawienie z Sieć i prywatność.';

  @override
  String get deskSetSynTorPay =>
      'tor, onion, ukryta usługa, prywatność, metoda';

  @override
  String get deskSetRowFileHint =>
      'Przez przekazanie pliku transakcji. Sieć nie jest potrzebna. Wszystkie portfele.';

  @override
  String get deskSetSynFile =>
      'plik, offline, slate, plik tx, usb, metoda, ręcznie';

  @override
  String get deskSetRowDefaultMethodHint =>
      'Od czego zaczyna Wyślij. Wszystkie portfele.';

  @override
  String get deskSetSynDefaultMethod => 'wyślij, metoda, domyślna';

  @override
  String get deskSetRowStrategy => 'Wyjścia, które wydaje wysyłka';

  @override
  String get deskSetRowStrategyHint =>
      'Najmniejsze pokrywają kwotę; Wszystkie wydaje każde wyjście.';

  @override
  String get deskSetRowStrategyInfo =>
      'Więcej wydanych wyjść to wyższa opłata.';

  @override
  String get deskSetSynStrategy =>
      'opłata, opłaty, strategia, wybór monet, wejścia, utxo, wyjścia';

  @override
  String get deskSetRowSplitChangeHint =>
      'Reszta wraca jako maksymalnie 4 wyjścia, gdy zostało ich niewiele.';

  @override
  String get deskSetRowSplitChangeInfo =>
      'Tylko gdy wysyłka zostawiłaby mniej niż 3 wyjścia do wydania, a reszta to co najmniej 1 EPIC. Każde dodatkowe wyjście kosztuje 0,004 EPIC.';

  @override
  String get deskSetSynSplitChange => 'opłata, reszta, wyjścia, utxo, podział';

  @override
  String get deskSetRowConfirmationsHint =>
      'Ile bloków odebrana płatność czeka, zanim można ją wydać.';

  @override
  String get deskSetSynConfirmations =>
      'potwierdzenia, bloki, do wydania, zablokowane, oczekujące, czekaj';

  @override
  String get deskSetRowPairShopHint =>
      'Sparowany kontakt, któremu pozwolisz, może wysyłać temu portfelowi faktury.';

  @override
  String get deskSetSynPairShop =>
      'paruj, parowanie, faktura, sklep, giełda, sprzedawca';

  @override
  String get deskSetRowTimeToPayHint =>
      'Jak długo faktura pozostaje do zapłaty.';

  @override
  String get deskSetSynTimeToPay => 'faktura, termin, wygasa, ważność';

  @override
  String get deskSetSynDeviceName => 'nazwa urządzenia, zmień nazwę';

  @override
  String get deskSetRowLinkDeviceHint =>
      'Ten portfel na dwóch urządzeniach: każde pokazuje płatności drugiego.';

  @override
  String get deskSetRowLinkDeviceInfo =>
      'Można połączyć jedno urządzenie. Każde trzyma monety, które wydaje drugie, więc nigdy nie wydadzą tej samej monety.';

  @override
  String get deskSetSynLinkDevice =>
      'połącz urządzenie, paruj telefon, drugie urządzenie, telefon, synchronizacja, komórka, wiele urządzeń';

  @override
  String get deskSetRowPauseSyncHint =>
      'Powiadomienia czekają na serwerach podczas pauzy.';

  @override
  String get deskSetSynPauseSync => 'synchronizacja, sync, pauza, połączone';

  @override
  String get deskSetSynTheme =>
      'tryb ciemny, tryb jasny, kolor, noc, dark mode';

  @override
  String get deskSetSynLanguage =>
      'język, tłumaczenie, polski, english, deutsch';

  @override
  String get deskSetRowScaleHint => 'Tekst i kontrolki, większe lub mniejsze.';

  @override
  String get deskSetSynScale =>
      'powiększenie, zoom, rozmiar, rozmiar czcionki, większe, mniejsze, dpi';

  @override
  String get deskSetRowHideAmountsHint => 'Kropki zamiast sald i kwot.';

  @override
  String get deskSetSynHideAmounts =>
      'prywatność, ukryj saldo, maskuj, udostępnianie ekranu, stream';

  @override
  String get deskSetRowNodeServerHint =>
      'Odczytuje łańcuch i wysyła transakcje tego portfela.';

  @override
  String get deskSetSynNodeServer => 'węzeł, node, serwer, host, rpc, api, url';

  @override
  String get deskSetRowFailover => 'Zmieniaj węzeł automatycznie';

  @override
  String get deskSetRowFailoverHint =>
      'Gdy węzeł przestaje odpowiadać, użyj następnego działającego.';

  @override
  String get deskSetSynFailover => 'failover, zapasowy, automatycznie';

  @override
  String get deskSetRowMyNodeHint =>
      'Pyta sam węzeł o jego stan i daje dostęp właściciela.';

  @override
  String get deskSetSynMyNode =>
      'własny węzeł, mój węzeł, self-hosted, właściciel, api secret';

  @override
  String get deskSetRowLocalNode => 'Węzeł na tym komputerze';

  @override
  String get deskSetRowLocalNodeHint =>
      'Uruchamia tutaj własny węzeł. Kilka gigabajtów na dysku.';

  @override
  String get deskSetSynLocalNode =>
      'lokalny węzeł, wbudowany węzeł, pełny węzeł, uruchom węzeł, synchronizuj łańcuch';

  @override
  String get deskSetRowLocalStartHint =>
      'Utrzymuje synchronizację węzła, gdy aplikacja jest otwarta.';

  @override
  String get deskSetSynLocalStart => 'autostart, lokalny węzeł';

  @override
  String get deskSetRowNetMode => 'Tryb połączenia';

  @override
  String get deskSetSynNetMode =>
      'tylko tor, undercover, offline, kill switch, tylko węzeł, vpn, ip, prywatność, tryb samolotowy';

  @override
  String get deskSetRowStatusSiteHint =>
      'Pokazuje, które węzły i serwery Epicbox są dostępne.';

  @override
  String get deskSetSynStatusSite => 'stan, status, dostępność, monitor';

  @override
  String get deskSetRowView => 'Widok';

  @override
  String get deskSetRowViewHint =>
      'Płytko, Głębiej lub Na głęboką wodę: ile portfela widać.';

  @override
  String get deskSetSynView =>
      'poziom, głębokość, płytko, głębiej, głęboka woda, prosty, ekspert, początkujący, tryb zaawansowany';

  @override
  String get deskSetRowAdvOutputsHint =>
      'Strona Wyjścia: monety, z których składa się saldo.';

  @override
  String get deskSetSynAdvOutputs => 'utxo, monety, wyjścia, podział, scalanie';

  @override
  String get deskSetRowAdvTechHint =>
      'Kernel, ID slate i commitmenty przy każdej transakcji.';

  @override
  String get deskSetSynAdvTech => 'kernel, slate, commitment, id tx, szczegóły';

  @override
  String get deskSetRowAdvSendoptsHint =>
      'Wybór wyjść i reszty przy wysyłce i w Płatnościach.';

  @override
  String get deskSetSynAdvSendopts => 'opłata, kontrola monet, wyjścia, reszta';

  @override
  String get deskSetRowAdvServersHint =>
      'Hosty, opóźnienie, wersja i wysokość na listach serwerów.';

  @override
  String get deskSetSynAdvServers => 'opóźnienie, ping, wysokość, wersja, host';

  @override
  String get deskSetRowAdvHeightHint =>
      'Gdzie zacząć i Usuń niepotwierdzone przy sprawdzaniu salda.';

  @override
  String get deskSetSynAdvHeight => 'skanuj ponownie, wysokość, blok';

  @override
  String get deskSetRowAdvLocalHint =>
      'Węzeł na tym komputerze, w sekcji Węzeł.';

  @override
  String get deskSetSynAdvLocal => 'pełny węzeł, lokalny węzeł';

  @override
  String get deskSetRowAdvLogsHint =>
      'Poziom logów i pliki logów w Pliki i logi.';

  @override
  String get deskSetSynAdvLogs => 'log, logi, debug, diagnostyka';

  @override
  String get deskSetRowXInvoicesHint =>
      'Proś sparowane kontakty o płatności; zatwierdzaj ich prośby.';

  @override
  String get deskSetSynXInvoices =>
      'faktura, prośba o płatność, parowanie, rachunek';

  @override
  String get deskSetRowWalletRows => 'Lista portfeli';

  @override
  String get deskSetRowWalletRowsHint =>
      'Portfele na tym komputerze; otwórz lub usuń jeden.';

  @override
  String get deskSetSynWalletRows =>
      'portfele, zmień portfel, inny portfel, lista';

  @override
  String get deskSetRowCreateWalletHint =>
      'Nowy portfel z nową frazą odzyskiwania.';

  @override
  String get deskSetSynCreateWallet => 'nowy portfel, dodaj portfel';

  @override
  String get deskSetRowImportWalletsHint =>
      'Ze starszego Epic Wallet lub z folderu.';

  @override
  String get deskSetSynImportWallets =>
      'migracja, stary portfel, electron, portfel gui, folder';

  @override
  String get deskSetRowRestoreWalletHint => 'Z 24-słowowej frazy odzyskiwania.';

  @override
  String get deskSetSynRestoreWallet =>
      'seed, odzyskaj, przywróć, mnemonik, fraza';

  @override
  String get deskSetRowWalletFolderHint =>
      'Klucze i baza danych tego portfela.';

  @override
  String get deskSetSynWalletFolder =>
      'folder danych, katalog, ścieżka, pliki, lokalizacja';

  @override
  String get deskSetRowAppFilesHint => 'settings.toml i log.';

  @override
  String get deskSetSynAppFiles =>
      'plik ustawień, settings.toml, konfiguracja, toml, katalog';

  @override
  String get deskSetRowLogLevelHint =>
      'Szczegółowy zachowuje więcej linii; raporty pomijają adresy.';

  @override
  String get deskSetSynLogLevel => 'log, debug, szczegółowy';

  @override
  String get deskSetRowLogFilesHint =>
      'Wyczyść pliki logów lub otwórz ich folder.';

  @override
  String get deskSetSynLogFiles => 'log, wyczyść logi, usuń logi';

  @override
  String get deskSetRowReportHint =>
      'Opisz, co poszło nie tak; może dołączyć oczyszczony log aplikacji.';

  @override
  String get deskSetSynReport =>
      'błąd, bug, problem, wsparcie, awaria, zgłoszenie';

  @override
  String get deskSetSynTour => 'przewodnik, samouczek, wprowadzenie, tour';

  @override
  String get deskSetRowSetup => 'Uruchom konfigurację ponownie';

  @override
  String get deskSetRowSetupHint => 'Węzeł i odbieranie, krok po kroku.';

  @override
  String get deskSetSynSetup =>
      'konfiguracja, kreator, asystent, skonfiguruj ponownie';

  @override
  String get deskSetRowUpdatesHint => 'Sprawdza, czy jest nowa wersja.';

  @override
  String get deskSetSynUpdates =>
      'aktualizacja, nowa wersja, pobierz, wydanie, update';

  @override
  String get deskSetRowWebsite => 'Strona internetowa';

  @override
  String get deskSetSynWebsite => 'strona, witryna, www, epic cash';

  @override
  String get deskSetSynSource =>
      'github, kod, kod źródłowy, open source, repozytorium';

  @override
  String get deskSetSynPrivacyPolicy => 'prywatność, polityka, rodo, dane';

  @override
  String get deskSetAcctBackup => 'Kopia zapasowa';

  @override
  String get deskSetAcctBalance => 'Saldo';

  @override
  String get deskSetAcctRemove => 'Usuwanie';

  @override
  String get deskSetAdvViewLineOne =>
      'Wysyłanie, odbieranie i kopie zapasowe. Węzeł i serwer Epicbox są wybierane automatycznie.';

  @override
  String get deskSetAdvViewLineTwo =>
      'Dodaje metody płatności, węzeł, tryby sieci i kolejne portfele.';

  @override
  String get deskSetAdvViewLineThree =>
      'Dodaje wyjścia, faktury, lokalny węzeł i każdy przełącznik Zaawansowanych.';

  @override
  String get deskSetAdvExperiments => 'Eksperymenty';

  @override
  String get deskSetFrameBack => 'Portfel';

  @override
  String get deskSetFrameBackTip => 'Wróć do portfela (Esc)';

  @override
  String deskSetFrameBackTo(String page) {
    return 'Wróć do: $page';
  }

  @override
  String get deskSetFrameEscKey => 'Esc';

  @override
  String get deskSetFrameEscHint => 'powrót do portfela';

  @override
  String get deskSetFrameExperiment => 'Eksperyment';

  @override
  String get deskSetHelpReportButton => 'Zgłoś…';

  @override
  String get deskSetHelpSetupAgain => 'Uruchom konfigurację ponownie';

  @override
  String get deskSetHelpSetupHint => 'Węzeł i odbieranie, krok po kroku.';

  @override
  String get deskSetHelpStartAgain => 'Od nowa';

  @override
  String get deskSetHelpTourStart => 'Rozpocznij przewodnik';

  @override
  String get deskSetFilesFolders => 'Foldery';

  @override
  String get deskSetNodeConnection => 'Połączenie';

  @override
  String get deskSetNodeFailover => 'Zmieniaj węzeł automatycznie';

  @override
  String get deskSetNodeStatus => 'Stan';

  @override
  String get deskSetPrivTorAll => 'Tor dla wszystkich połączeń';

  @override
  String get deskSetPrivServerStatus => 'Stan serwerów';

  @override
  String get deskSetPrivMode => 'Tryb połączenia';

  @override
  String get deskSetTxSending => 'Wysyłanie';

  @override
  String get deskSetTxTorPayHint =>
      'Tor działa tylko do wysyłania i odbierania płatności pod adresem Tor. Węzeł, kursy i aktualizacje zachowują ustawienie z sekcji Sieć i prywatność. Wszystkie portfele.';

  @override
  String get deskSetWalletsOnComputer => 'Na tym komputerze';

  @override
  String get deskSetSearchKeyEnter => 'Enter';

  @override
  String get deskSetSearchKeyEsc => 'Esc';

  @override
  String get deskTorPayOff => 'Wyłączone';

  @override
  String get deskTorPayStarting => 'Uruchamianie Tor · tylko dla płatności';

  @override
  String get deskTorPayReady => 'Odbiera';

  @override
  String deskTorPayBlockedNodeOnly(String mode) {
    return 'Wyłączone w trybie $mode: łączy się tylko węzeł.';
  }

  @override
  String deskTorPayBlockedKill(String mode) {
    return 'Wyłączone w trybie $mode: nic się nie łączy.';
  }

  @override
  String get deskTorPayFailed => 'Tor nie połączył się.';

  @override
  String deskTorPayFailedWhy(String problem) {
    return 'Tor nie połączył się: $problem.';
  }

  @override
  String get deskTorPayRestOn =>
      'Tor dla każdego połączenia: włączony (Sieć i prywatność).';

  @override
  String get deskTorPayRestOff =>
      'Tor dla każdego połączenia: wyłączony (Sieć i prywatność).';

  @override
  String get deskRailTorForPayments => 'Dla płatności';

  @override
  String get deskBarKeySearch => 'Szukaj w ustawieniach';

  @override
  String get deskBarKeySearchHere => 'Szukaj, gdy otwarte są Ustawienia';

  @override
  String get deskHttpLocalTitle => 'Sieć lokalna';

  @override
  String get deskHttpLocalSwitch => 'Odbieraj na tym komputerze';

  @override
  String get deskHttpPublicTitle => 'Internet';

  @override
  String deskHttpPublicNote(String port) {
    return 'Dla portfeli w internecie. Router musi przekierować port $port na ten komputer.';
  }

  @override
  String deskKitMethodHttpNotReachable(String port) {
    return 'tylko w sieci lokalnej. Aby dostawać płatności z internetu, router musi przekazywać port $port do tego komputera.';
  }

  @override
  String get sendRouteLinkHttps => 'Link · HTTPS';

  @override
  String get sendRouteThisPhone => 'Ten telefon';

  @override
  String get sendRouteThisComputer => 'Ten komputer';

  @override
  String get sendRouteYourNetwork => 'Twoja sieć';

  @override
  String get sendRouteOverTor => 'Przez Tor';

  @override
  String get sendRouteTorStarts => 'Tor uruchomi się przy wysyłaniu.';

  @override
  String get sendRouteChange => 'Zmień';

  @override
  String sendRouteChangeSem(int count) {
    return 'Zmień adres, jeszcze $count';
  }

  @override
  String sendRouteAddressesOf(String name) {
    return 'Adresy kontaktu $name';
  }

  @override
  String sendRouteMore(int count) {
    return 'jeszcze $count';
  }

  @override
  String sendRouteSemantics(String method, String host) {
    return 'Wysyła przez $method do $host';
  }

  @override
  String get sendHeldKillSwitch =>
      'Wyłącznik awaryjny jest włączony. Nic się nie łączy.';

  @override
  String get sendHeldNodeOnly =>
      'Tryb Tylko węzeł jest włączony. Łączy się tylko węzeł.';

  @override
  String get sendHeldTorOnly =>
      'Tryb Tylko Tor jest włączony. Zwykłe http:// nie może iść przez Tor.';

  @override
  String get sendHeldTorOn =>
      'Tor jest włączony. Zwykłe http:// nie może iść przez Tor.';

  @override
  String get sendHeldFixKillSwitch => 'Wyłącz wyłącznik awaryjny';

  @override
  String get sendHeldFixNodeOnly => 'Wyłącz tryb Tylko węzeł';

  @override
  String get sendHeldFixTorOnly => 'Wyłącz tryb Tylko Tor';

  @override
  String get sendHeldByKillSwitch => 'Wstrzymany przez wyłącznik awaryjny';

  @override
  String get sendHeldByNodeOnly => 'Wstrzymany przez tryb Tylko węzeł';

  @override
  String get sendHeldByTorOnly => 'Wstrzymany przez tryb Tylko Tor';

  @override
  String get sendHeldWhileTorOn => 'Wstrzymany, gdy Tor jest włączony';

  @override
  String get sendHeldModeNormal => 'Tryb sieci: Normalny.';

  @override
  String get sendHeldTorIsOff => 'Tor jest wyłączony.';

  @override
  String get sendNoAddress => 'Nie masz adresu?';

  @override
  String get sendWithoutConnection => 'Bez połączenia:';

  @override
  String get sendPayInPerson => 'Zapłać osobiście';

  @override
  String get sendPayByFile => 'Zapłać plikiem';

  @override
  String get sendIsSlateText => 'To jest tekst transakcji, a nie adres.';

  @override
  String get sendOpenSlateText => 'Otwórz';

  @override
  String get sendSendsTo => 'Wysyła do';

  @override
  String get sendProblemNotAddress =>
      'To nie jest adres i żaden kontakt nie ma tej nazwy.';

  @override
  String get sendProblemOtherScheme =>
      'Ten portfel nie może zapłacić na taki adres.';

  @override
  String get sendProblemIncomplete => 'Ten adres wygląda na niepełny.';

  @override
  String get sendProblemOnion =>
      'To nie jest pełny adres Tor. Skopiuj go ponownie od odbiorcy.';

  @override
  String get sendProblemPort => 'Port musi mieć wartość od 1 do 65535.';

  @override
  String get sendProblemCredentials =>
      'Nie można zapłacić na adres zawierający nazwę użytkownika.';

  @override
  String get sendProblemCharacters =>
      'Ten adres zawiera znaki, których adres nie może mieć.';

  @override
  String get sendProblemTooLong => 'Ten adres jest za długi.';

  @override
  String get sendProblemOwn => 'To własny adres tego portfela.';

  @override
  String get sendReachChecking => 'Sprawdzanie…';

  @override
  String sendReachNone(String host) {
    return 'Pod $host nie odpowiada żaden portfel.';
  }

  @override
  String sendReachNotWallet(String host) {
    return 'Pod $host coś odpowiada, ale nie portfel Epic.';
  }

  @override
  String get sendReachTheirOnion => 'adresem Tor odbiorcy';

  @override
  String get sendReachOpenFirst =>
      'Portfel odbiorcy musi być otwarty, aby odebrać płatność.';

  @override
  String get sendReachCheckAddress => 'Sprawdź adres z odbiorcą.';

  @override
  String get sendReachTryAgain => 'Spróbuj ponownie';

  @override
  String get sendFactVia => 'Przez';

  @override
  String get sendFactHost => 'Host';

  @override
  String get sendFactConnection => 'Połączenie';

  @override
  String get sendFactNotEncrypted => 'Bez szyfrowania · http://';

  @override
  String get sendFactTor => 'Tor';

  @override
  String get sendFactTorStarts => 'Uruchomi się przy wysyłaniu';

  @override
  String get sendFactOffline => 'Portfel odbiorcy może być offline.';

  @override
  String get sendFactOnline => 'Portfel odbiorcy musi być otwarty.';

  @override
  String get deskTfOpenTitle => 'Otwórz pliki transakcji';

  @override
  String get deskTfOpenText =>
      'Wybierz jeden plik lub kilka. Portfel odczyta każdy z nich i podpisze go, sfinalizuje lub wyśle do sieci.';

  @override
  String get deskTfPickTitle => 'Pliki transakcji';

  @override
  String get deskTfResults => 'Otwarte pliki';

  @override
  String get deskTfWorking => 'Przetwarzanie…';

  @override
  String deskTfSigned(String path) {
    return 'Podpisano. Odpowiedź zapisano w $path';
  }

  @override
  String get deskTfAlreadyPosted => 'Już wysłana do sieci';

  @override
  String deskTfInvoice(String amount) {
    return 'Faktura na $amount. Sprawdź ją, aby zapłacić.';
  }

  @override
  String get deskTfReview => 'Sprawdź';

  @override
  String get deskTfCreate => 'Utwórz plik płatności';

  @override
  String get deskTfDropHint => 'Możesz też upuścić je tutaj.';

  @override
  String get deskSaToAddress => 'Wyślij na adres';

  @override
  String deskSaToContactSem(String name) {
    return 'Do: $name';
  }

  @override
  String get netModesTitle => 'Tryby połączenia';

  @override
  String get netModesAbout => 'O trybach połączenia';

  @override
  String get netModesGroup => 'Tryb połączenia';

  @override
  String get netModesTag => '[NET]';

  @override
  String get netModesTopology => 'Topologia';

  @override
  String get netModesDevice => 'Urządzenie';

  @override
  String get netModesDeviceSub => 'ten portfel';

  @override
  String get netModesTorSub => 'wbudowany';

  @override
  String get netModesEpicboxSub => 'przekaźnik';

  @override
  String get netModesNode => 'Węzeł';

  @override
  String get netModesNodeSub => 'używany węzeł';

  @override
  String get netModesNetwork => 'Sieć';

  @override
  String get netModesNetworkSub => 'węzły równorzędne';

  @override
  String get netModesPostElsewhere => 'Wyślij gdzie indziej';

  @override
  String get netModesLeaves => 'Opuszcza urządzenie';

  @override
  String get netModesDirect => 'Bezpośrednio';

  @override
  String get netModesViaTor => 'Przez Tor';

  @override
  String get netModesOptional => 'Opcjonalnie';

  @override
  String get netModesAllTraffic => 'Cały ruch';

  @override
  String get netModesOff => 'Wyłączone';

  @override
  String get netModesYes => 'Tak';

  @override
  String get netModesNo => 'Nie';

  @override
  String get netModesDescStandard =>
      'Łączy się bezpośrednio z węzłem, Epicbox i usługami, z których korzystasz. Gdy Tor jest włączony, płatności idą przez Tor.';

  @override
  String get netModesDescNodeOnly =>
      'Łączy się tylko używany węzeł, przez Tor, gdy Tor jest włączony. Epicbox, Link, połączone urządzenia oraz sprawdzanie kursu i aktualizacji są wyłączone.';

  @override
  String get netModesDescNodeOnlyNoTor =>
      'Łączy się tylko używany węzeł. Epicbox, Link, połączone urządzenia oraz sprawdzanie kursu i aktualizacji są wyłączone.';

  @override
  String get netModesDescKillSwitch =>
      'Nic się nie łączy, nawet węzeł. Płatności są tworzone i kończone offline, a potem wysyłane z urządzenia, które jest online.';

  @override
  String netModesLiveLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktywnego połączenia',
      many: '$count aktywnych połączeń',
      few: '$count aktywne połączenia',
      one: '1 aktywne połączenie',
    );
    return '$_temp0';
  }

  @override
  String netModesDiagramLabel(String mode, String description) {
    return 'Topologia sieci, tryb $mode: $description';
  }

  @override
  String get netModesModeTag => '[Tryb]';

  @override
  String get deskOldAppTitle => 'Znaleziono starą aplikację';

  @override
  String deskOldAppBody(String app, String folder) {
    return '$app nadal jest w folderze $folder.';
  }

  @override
  String get deskOldAppTrash => 'Przenieś do Kosza';

  @override
  String get deskOldAppKeep => 'Zachowaj';

  @override
  String deskOldAppTrashed(String app) {
    return 'Przeniesiono $app do Kosza';
  }

  @override
  String deskOldAppNotTrashed(String app) {
    return 'Nie można przenieść $app do Kosza';
  }

  @override
  String deskOvInflightMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kolejnej płatności w toku',
      many: '$count kolejnych płatności w toku',
      few: '$count kolejne płatności w toku',
      one: '$count kolejna płatność w toku',
    );
    return '$_temp0';
  }

  @override
  String get deskOvInflightView => 'Zobacz';

  @override
  String get deskNoTorSetSynNetMode =>
      'offline, kill switch, tylko węzeł, vpn, ip, prywatność, tryb samolotowy';

  @override
  String get deskNoTorSetSearchTryWords =>
      'hasło,prywatność,fraza,kopia,opłata,węzeł,blokada';

  @override
  String get deskKitReachDismiss => 'Ukryj';

  @override
  String deskErrKeyMissing(String name) {
    return 'Pliki portfela $name są na tym komputerze, ale klucza, który je otwiera, nie ma już w jego bezpiecznym magazynie (na Macu w pęku kluczy). Wpisz frazę odzyskiwania portfela, aby otworzyć go ponownie; historia zostaje.';
  }

  @override
  String get deskOnbUnlockUsePhrase => 'Wpisz frazę odzyskiwania';

  @override
  String get pairSeenAsNone => 'Nie widzą nazwy';

  @override
  String get pairSeenAsAdd => 'Dodaj nazwę';

  @override
  String get pairSeenAsOptional => 'Zostaw puste, aby sparować bez nazwy.';

  @override
  String get pairUnnamed => 'Portfel bez nazwy';

  @override
  String pairDefaultLabel(int n) {
    return 'Kontakt $n';
  }

  @override
  String get linkNotALink => 'To nie jest link płatności';

  @override
  String get linkMadeForMainnet => 'Utworzono dla mainnet';

  @override
  String get linkMadeForFloonet => 'Utworzono dla floonet';

  @override
  String get linkChanged => 'Ten link zmieniono po utworzeniu.';

  @override
  String linkExpired(String date) {
    return 'Ten link wygasł $date';
  }

  @override
  String get linkForOther => 'Utworzono dla kogoś innego';

  @override
  String get linkPaidTitle => 'Już zapłacono';

  @override
  String linkPaidBefore(String date) {
    return 'Tę prośbę opłacono $date';
  }

  @override
  String get linkPayAgain => 'Zapłać ponownie';

  @override
  String linkTrustListed(String name, String service) {
    return '$name · przez $service';
  }

  @override
  String linkTrustListedBy(String service) {
    return 'Przez $service';
  }

  @override
  String get linkTrustNameService => 'Z sparowanej usługi';

  @override
  String get linkTrustOther => 'Sprawdź, czy pasują do wiadomości z płatnością';

  @override
  String linkTrustChanged(String name, String date) {
    return '$name otrzymuje teraz płatności na inny portfel niż w dniu płatności $date. Zapłać tylko wtedy, gdy ktoś ci o tym powiedział.';
  }

  @override
  String linkTrustChangedNoName(String date) {
    return 'Odbiorca otrzymuje teraz płatności na inny portfel niż w dniu płatności $date. Zapłać tylko wtedy, gdy ktoś ci o tym powiedział.';
  }

  @override
  String linkCodeLabel(String name) {
    return 'Obrazki dla $name';
  }

  @override
  String get linkCodeLabelPlain => 'Obrazki';

  @override
  String get linkAmountEdited => 'To nie jest żądana kwota';

  @override
  String get linkChangedConfirmTitle => 'Sprawdź przed zapłatą';

  @override
  String nsWaitingFor(String label) {
    return 'Oczekiwanie na $label…';
  }

  @override
  String get nsCodeTitle => 'Sprawdź kod';

  @override
  String nsCodeLead(String label) {
    return '$label pokazuje cztery obrazki. Porównaj je z tymi.';
  }

  @override
  String get nsCodeLabel => 'Cztery obrazki';

  @override
  String nsJoin(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Płać mi przez $label',
      'other': 'Płać mi jako $name',
    });
    return '$_temp0';
  }

  @override
  String get nsNotNow => 'Nie teraz';

  @override
  String nsJoinTitle(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Płać mi przez $label?',
      'other': 'Płać mi jako $name?',
    });
    return '$_temp0';
  }

  @override
  String nsJoinBody(String name, String label, String host) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none':
          'Osoby korzystające z $label mogą tam płacić ci. Płatności przychodzą przez $host',
      'other':
          'Osoby korzystające z $label mogą płacić ci jako $name. Płatności przychodzą przez $host',
    });
    return '$_temp0';
  }

  @override
  String nsJoinInfo(String label) {
    return '$label dostaje jeden adres płatności i jeden kod, oba utworzone tylko dla niego. Nie widzi twojego salda, nie przenosi monet i nie czyta płatności. Płatności docierają, gdy Epic Cash jest otwarty. Możesz opuścić w każdej chwili w Kontakty › $label.';
  }

  @override
  String nsJoinedNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Płać mi przez $label: włączone',
      'other': 'Płać mi jako $name: włączone',
    });
    return '$_temp0';
  }

  @override
  String nsLeftNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Płać mi przez $label: wyłączone',
      'other': 'Płać mi jako $name: wyłączone',
    });
    return '$_temp0';
  }

  @override
  String nsJoined(String name, String label, String date) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Płać mi przez $label · od $date',
      'other': 'Płać mi jako $name · od $date',
    });
    return '$_temp0';
  }

  @override
  String get nsNotListed => 'Wyłączone';

  @override
  String nsNotListedBody(String label) {
    return 'Twoja nazwa została usunięta przez $label.';
  }

  @override
  String get nsNotJoined => 'Wyłączone';

  @override
  String get nsJoinAgain => 'Włącz ponownie';

  @override
  String get nsListingCode => 'Obrazki dla twojej nazwy';

  @override
  String nsListingCodeInfo(String label) {
    return 'Cztery obrazki utworzone z portfela, na który wpływają płatności pod twoją nazwą. $label może pokazać te same cztery do porównania.';
  }

  @override
  String get nsLeave => 'Opuść';

  @override
  String nsRemoveTooTitle(String label) {
    return 'Usunąć też $label?';
  }

  @override
  String deskSendErrOwnNamed(String wallet) {
    return 'To „$wallet”, portfel otwarty teraz. Aby na niego zapłacić, najpierw otwórz inny portfel.';
  }

  @override
  String get deskConLabelTitle => 'Etykieta';

  @override
  String get deskConLabelWallet => 'Tylko portfel';

  @override
  String get deskConLabelExchange => 'Giełda';

  @override
  String get deskConLabelVendor => 'Sprzedawca';

  @override
  String get deskConLabelService => 'Usługa';

  @override
  String get deskConLabelDefault => 'Domyślna';

  @override
  String deskConLabelCurrent(String name) {
    return 'Etykieta: $name';
  }

  @override
  String get deskUpdStripAct => 'Aktualizuj';

  @override
  String get deskUpdStripHide => 'Ukryj do następnej wersji';
}
