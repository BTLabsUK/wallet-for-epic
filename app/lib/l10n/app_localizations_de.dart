// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Wallet';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get noticeLevelInfo => 'Hinweis';

  @override
  String get noticeLevelSuccess => 'Erledigt';

  @override
  String get noticeLevelWarning => 'Warnung';

  @override
  String get noticeLevelError => 'Fehler';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonError => 'Fehler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonPaste => 'Einfügen';

  @override
  String get commonRetry => 'Wiederholen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonUnknown => 'Unbekannt';

  @override
  String get passwordShow => 'Passwort anzeigen';

  @override
  String get passwordHide => 'Passwort verbergen';

  @override
  String get slateCopyTooltip => 'Transaktionstext kopieren';

  @override
  String get slateCopied => 'Transaktionstext kopiert';

  @override
  String get slatePastedTitle => 'Eingefügte Zahlung';

  @override
  String get slateCopyReply => 'Antwort kopieren';

  @override
  String get biometricPromptTitle => 'Wallet entsperren';

  @override
  String get biometricPromptSubtitle =>
      'Mit Fingerabdruck oder Gesicht bestätigen';

  @override
  String get biometricPromptUsePin => 'PIN verwenden';

  @override
  String get amountEnterExample => 'Geben Sie einen Betrag ein, z. B. 1,5';

  @override
  String amountTooManyDecimals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Höchstens $count Nachkommastellen',
      one: 'Höchstens 1 Nachkommastelle',
    );
    return '$_temp0';
  }

  @override
  String dateWithTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String get txMiningReward => 'Mining-Belohnung';

  @override
  String get txRestoredFunds => 'Wiederhergestelltes Guthaben';

  @override
  String get txOutgoingPayment => 'Ausgehende Zahlung';

  @override
  String get txIncomingPayment => 'Eingehende Zahlung';

  @override
  String get txStatusWaitingRecipient => 'Wartet auf Empfänger';

  @override
  String get txStatusWaitingSender => 'Wartet auf Absender';

  @override
  String txStatusConfirming(int count, int target) {
    return 'Bestätigung $count/$target';
  }

  @override
  String get txStatusCompleted => 'Abgeschlossen';

  @override
  String get txStatusCancelled => 'Abgebrochen';

  @override
  String get txStatusFromBackup => 'Aus Sicherung, Status unbekannt';

  @override
  String get txIconCancelled => 'Abgebrochen';

  @override
  String get txIconIncoming => 'Eingehend';

  @override
  String get txIconOutgoing => 'Ausgehend';

  @override
  String get txSpokenHiddenAmount => 'Betrag verborgen';

  @override
  String txSpokenMiningReward(String amount) {
    return 'Mining-Belohnung: $amount';
  }

  @override
  String txSpokenRestoredFunds(String amount) {
    return 'Wiederhergestelltes Guthaben: $amount';
  }

  @override
  String txSpokenCancelledSend(String amount) {
    return 'Senden abgebrochen: $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return 'Senden an $who abgebrochen: $amount';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return 'Empfang abgebrochen: $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return 'Empfang von $who abgebrochen: $amount';
  }

  @override
  String txSpokenSending(String amount) {
    return 'Wird gesendet: $amount';
  }

  @override
  String txSpokenSendingTo(String amount, String who) {
    return 'Wird an $who gesendet: $amount';
  }

  @override
  String txSpokenReceiving(String amount) {
    return 'Wird empfangen: $amount';
  }

  @override
  String txSpokenReceivingFrom(String amount, String who) {
    return 'Wird von $who empfangen: $amount';
  }

  @override
  String txSpokenSent(String amount) {
    return 'Gesendet: $amount';
  }

  @override
  String txSpokenSentTo(String amount, String who) {
    return 'An $who gesendet: $amount';
  }

  @override
  String txSpokenReceived(String amount) {
    return 'Empfangen: $amount';
  }

  @override
  String txSpokenReceivedFrom(String amount, String who) {
    return 'Von $who empfangen: $amount';
  }

  @override
  String txSpokenRow(String what, String status, String date) {
    return '$what, $status, $date';
  }

  @override
  String get errorInvalidMnemonic =>
      'Die Wiederherstellungsphrase ist ungültig. Prüfen Sie jedes Wort und die Reihenfolge der Wörter.';

  @override
  String get errorWrongPassword => 'Falsches Passwort.';

  @override
  String get errorWalletAlreadyExists =>
      'Für dieses Netzwerk gibt es bereits eine Wallet.';

  @override
  String get errorWalletNotFound =>
      'Für dieses Netzwerk wurde keine Wallet gefunden.';

  @override
  String get errorNodeUnreachable =>
      'Der Node ist nicht erreichbar. Prüfen Sie die Node-URL und Ihre Verbindung.';

  @override
  String get errorNotEnoughFunds =>
      'Das verfügbare Guthaben reicht für diesen Betrag plus Gebühr nicht aus.';

  @override
  String get errorInvalidSlate =>
      'Dieser Transaktionstext ist für diesen Schritt ungültig. Prüfen Sie, ob Sie ihn vollständig eingefügt haben.';

  @override
  String get errorInvalidInput => 'Ungültige Eingabe.';

  @override
  String get errorTransportFailed => 'Der Empfänger war nicht erreichbar.';

  @override
  String get errorChainBusy =>
      'Die Wallet ist im anderen Netzwerk noch beschäftigt. Warten Sie einen Moment und versuchen Sie es erneut, oder schließen Sie die App und öffnen Sie sie wieder.';

  @override
  String get errorWalletBusy =>
      'Die Wallet schließt noch eine Aufgabe ab. Versuchen Sie es gleich noch einmal.';

  @override
  String get errorPaymentExpired =>
      'Die Antwort auf diese Zahlung kam zu spät, daher wurde die Zahlung abgebrochen. Es wurde nichts gesendet.';

  @override
  String get errorIo =>
      'Wallet-Dateien konnten nicht gelesen oder geschrieben werden.';

  @override
  String get errorOther => 'Wallet-Fehler.';

  @override
  String get errorScanFailed => 'Der Scan ist fehlgeschlagen.';

  @override
  String get errorUnexpected =>
      'Unerwarteter Fehler. Bitte versuchen Sie es erneut.';

  @override
  String get errorHistoryNotOurs =>
      'Dies ist keine von dieser App exportierte Verlaufsdatei.';

  @override
  String get errorHistoryNewer =>
      'Diese Verlaufsdatei wurde mit einer neueren Version der App erstellt.';

  @override
  String get errorHistoryDamaged => 'Diese Verlaufsdatei ist beschädigt.';

  @override
  String get errorHistoryOtherWallet =>
      'Diese Verlaufsdatei gehört zu einer anderen Wallet.';

  @override
  String errorHistoryOtherNetwork(String fileNetwork, String walletNetwork) {
    return 'Diese Verlaufsdatei stammt aus dem $fileNetwork, diese Wallet läuft aber im $walletNetwork.';
  }

  @override
  String get networkMainnet => 'Mainnet';

  @override
  String get networkFloonet => 'Floonet';

  @override
  String get networkUsernet => 'Usernet';

  @override
  String get networkMainnetDescription => 'Das echte Netzwerk von Epic Cash.';

  @override
  String get networkFloonetDescription =>
      'Ein öffentliches Testnetzwerk zum Ausprobieren der App. Die Coins dort haben keinen Wert; kostenlose erhalten Sie bei floo-explorer.btlabs.uk.';

  @override
  String get networkUsernetDescription =>
      'Ein Testnetzwerk auf diesem Computer, für Entwickler.';

  @override
  String networkTestSuffix(String network) {
    return ' ($network, Testcoins)';
  }

  @override
  String get autoLockNever => 'Nie';

  @override
  String get autoLockImmediately => 'Sofort';

  @override
  String autoLockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Nach $minutes Minuten',
      one: 'Nach 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get scanStarting => 'Scan wird gestartet';

  @override
  String scanProgress(int percent) {
    return 'Blockchain wird gescannt ($percent %)';
  }

  @override
  String get scanComplete => 'Scan abgeschlossen';

  @override
  String get languageSetting => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get currencyUsd => 'US-Dollar';

  @override
  String get currencyEur => 'Euro';

  @override
  String get currencyGbp => 'Britisches Pfund';

  @override
  String get currencyBtc => 'Bitcoin';

  @override
  String get currencyJpy => 'Japanischer Yen';

  @override
  String get currencyCny => 'Chinesischer Yuan';

  @override
  String get currencyCad => 'Kanadischer Dollar';

  @override
  String get currencyAud => 'Australischer Dollar';

  @override
  String get currencyChf => 'Schweizer Franken';

  @override
  String get currencyInr => 'Indische Rupie';

  @override
  String get currencyBrl => 'Brasilianischer Real';

  @override
  String get currencyKrw => 'Südkoreanischer Won';

  @override
  String get currencyPln => 'Polnischer Złoty';

  @override
  String get currencyTry => 'Türkische Lira';

  @override
  String txDetailsWaitingTooLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Wartet seit $days Tagen. Die epicbox löscht Zahlungen nach 7 Tagen, daher kann diese Zahlung nicht mehr abgeschlossen werden. Brechen Sie sie ab, um den Betrag freizugeben, und senden Sie dann erneut.',
      one: 'Wartet seit 1 Tag. Die epicbox löscht Zahlungen nach 7 Tagen, daher kann diese Zahlung nicht mehr abgeschlossen werden. Brechen Sie sie ab, um den Betrag freizugeben, und senden Sie dann erneut.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'An die epicbox des Empfängers gesendet. Die Zahlung wird abgeschlossen, sobald dessen Wallet online ist. Bis dahin bleibt der Betrag gesperrt, es sei denn, Sie brechen ab.';

  @override
  String get txDetailsWaitingRecipient =>
      'Wartet darauf, dass der Empfänger mit seiner Transaktionsdatei antwortet. Bis dahin bleibt der Betrag gesperrt, es sei denn, Sie brechen ab.';

  @override
  String get txDetailsWaitingSender =>
      'Sie haben diese Zahlung angenommen. Die Zahlung wird abgeschlossen, sobald der Absender sie fertigstellt und im Netzwerk veröffentlicht.';

  @override
  String get txDetailsPublished =>
      'Im Netzwerk veröffentlicht. Warten auf die erste Bestätigung.';

  @override
  String get txDetailsWaitingConfirmation =>
      'Warten auf die Bestätigung durch das Netzwerk.';

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
      other: '$target Bestätigungen',
      one: '1 Bestätigung',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return 'In Block $height. $count von $_temp0; endgültig in etwa $_temp1.';
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
      other: '$target Bestätigungen',
      one: '1 Bestätigung',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '1 Stunde',
    );
    return 'In Block $height. $count von $_temp0; endgültig in etwa $_temp1.';
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
      other: '$target Bestätigungen',
      one: '1 Bestätigung',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'In Block $height. $count von $_temp0; endgültig in etwa $_temp1.';
  }

  @override
  String get txDetailsCompleted => 'Abgeschlossen.';

  @override
  String txDetailsCompletedInBlock(String height) {
    return 'In Block $height abgeschlossen.';
  }

  @override
  String get txDetailsCancelledByUser =>
      'Abgebrochen. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledReleased =>
      'Das Netzwerk hat die Zahlung nie angenommen, daher wurde der Betrag freigegeben. Prüfen Sie vor dem erneuten Senden, ob der Empfänger sie nicht doch erhalten hat.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Die Zahlung hat das Netzwerk nicht innerhalb von 14 Tagen erreicht, daher hat die Wallet sie abgebrochen. Prüfen Sie vor dem erneuten Senden, ob der Empfänger sie nicht doch erhalten hat.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Der Empfänger hat nicht innerhalb von 14 Tagen geantwortet, daher hat die Wallet die Zahlung abgebrochen. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Der Empfänger hat erst nach Ablauf der 14-Tage-Frist geantwortet, daher hat die Wallet die Zahlung abgebrochen, statt sie abzuschließen. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Die Zahlung konnte dem Empfänger nicht zugestellt werden, daher hat die Wallet sie sofort abgebrochen. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledIncoming =>
      'Abgebrochen. Diese Zahlung wird nicht eintreffen.';

  @override
  String get txDetailsFromBackup =>
      'Diese Zahlung stammt aus einer Verlaufssicherung und war beim Erstellen der Sicherung noch nicht abgeschlossen. Diese Wallet hat keine eigenen Daten dazu und kann daher nicht feststellen, ob sie abgeschlossen wurde. Es ist nichts gesperrt.';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return 'Wird automatisch abgebrochen, wenn sie bis Block $height nicht abgeschlossen ist.';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return 'Wird automatisch abgebrochen, wenn sie bis Block $height nicht abgeschlossen ist (in etwa $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '1 Stunde',
    );
    return 'Wird automatisch abgebrochen, wenn sie bis Block $height nicht abgeschlossen ist (in etwa $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'Wird automatisch abgebrochen, wenn sie bis Block $height nicht abgeschlossen ist (in etwa $_temp0).';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return 'Bei Block $height abgelaufen. Die Wallet bricht sie bei der nächsten Aktualisierung ab.';
  }

  @override
  String get txDetailsTitle => 'Zahlung';

  @override
  String get txDetailsLoading => 'Wird geladen';

  @override
  String get txDetailsGone => 'Diese Zahlung ist nicht mehr in der Wallet.';

  @override
  String get txDetailsWorking => 'Wird ausgeführt';

  @override
  String get txDetailsAmountHidden => 'Betrag verborgen';

  @override
  String get txDetailsNotConfirmedYet => 'Noch nicht bestätigt';

  @override
  String get txDetailsStuckBody =>
      'Das Netzwerk hat diese Zahlung noch nicht aufgenommen. Sie können sie gefahrlos erneut übertragen. Dieselbe Zahlung kann nicht zweimal ausgeführt werden.';

  @override
  String get txDetailsBroadcastAgain => 'Erneut übertragen';

  @override
  String get txDetailsBroadcastAgainDone =>
      'Erneut übertragen. Die Zahlung sollte innerhalb weniger Minuten bestätigt werden.';

  @override
  String get txDetailsRefusedBody =>
      'Das Netzwerk hat diese Zahlung abgelehnt; sie hat die Blockchain nie erreicht. Sie können den dadurch gesperrten Betrag freigeben.';

  @override
  String get txDetailsReleaseFunds => 'Betrag freigeben';

  @override
  String get txDetailsReleaseTitle => 'Betrag freigeben?';

  @override
  String get txDetailsReleaseBody =>
      'Nutzen Sie dies nur, wenn die Zahlung niemals bestätigt wird. Wird sie doch bestätigt, sehen Sie möglicherweise ein falsches Guthaben, bis Sie neu scannen.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Weiter warten';

  @override
  String get txDetailsFundsReleased => 'Betrag freigegeben';

  @override
  String get txDetailsCancelPayment => 'Zahlung abbrechen';

  @override
  String get txDetailsCancelTitle => 'Zahlung abbrechen?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Der Absender kann diese Zahlung noch abschließen. Tut er das nach Ihrem Abbruch, erscheint sie erst nach einem erneuten Scan.';

  @override
  String get txDetailsCancelSendBody =>
      'Diese Zahlung abbrechen und den Betrag freigeben? Tun Sie das nur, wenn der Empfänger sie nicht abgeschlossen hat.';

  @override
  String get txDetailsCancelKeep => 'Behalten';

  @override
  String get txDetailsPaymentCancelled => 'Zahlung abgebrochen';

  @override
  String get txDetailsDate => 'Datum';

  @override
  String get txDetailsCreated => 'Erstellt';

  @override
  String get txDetailsSentTo => 'Gesendet an';

  @override
  String get txDetailsReceivedFrom => 'Empfangen von';

  @override
  String get txDetailsCopyAddress => 'Adresse kopieren';

  @override
  String get txDetailsAddressCopied => 'Adresse kopiert';

  @override
  String get txDetailsAddToContacts => 'Zu Kontakten hinzufügen';

  @override
  String get txDetailsSendAgain => 'Erneut senden';

  @override
  String get txDetailsFee => 'Gebühr';

  @override
  String get txDetailsNoteLabel => 'Notiz';

  @override
  String get txDetailsPrivateNoteLabel => 'Private Notiz, nur auf diesem Gerät';

  @override
  String get txDetailsMessageFromSender => 'Nachricht des Absenders';

  @override
  String get txDetailsMessageFromRecipient => 'Nachricht des Empfängers';

  @override
  String get txDetailsYourMessage => 'Ihre Nachricht';

  @override
  String get txDetailsNoNote =>
      'Keine Notiz. Fügen Sie eine hinzu, um sich zu merken, wofür diese Zahlung war.';

  @override
  String get txDetailsAddNote => 'Notiz hinzufügen';

  @override
  String get txDetailsEditNote => 'Notiz bearbeiten';

  @override
  String get txDetailsNoteDialogTitle => 'Notiz';

  @override
  String get txDetailsNoteHelper =>
      'Nur auf diesem Gerät und in Ihren Verlaufssicherungen.';

  @override
  String get txDetailsNoteSaved => 'Notiz gespeichert';

  @override
  String get txDetailsNoteRemoved => 'Notiz entfernt';

  @override
  String get txDetailsExplorerLink => 'Explorer-Link kopieren';

  @override
  String get txDetailsExplorerLinkCopy => 'Explorer-Link kopieren';

  @override
  String get txDetailsLinkCopied => 'Link kopiert';

  @override
  String get txDetailsTechnical => 'Technische Details';

  @override
  String get txDetailsBlockHeight => 'Blockhöhe';

  @override
  String get txDetailsSlateId => 'Slate-ID';

  @override
  String get txDetailsSlateIdCopy => 'Slate-ID kopieren';

  @override
  String get txDetailsSlateIdCopied => 'Slate-ID kopiert';

  @override
  String get txDetailsKernel => 'Kernel';

  @override
  String get txDetailsKernelCopy => 'Kernel kopieren';

  @override
  String get txDetailsKernelCopied => 'Kernel kopiert';

  @override
  String get txDetailsOutputCommitment => 'Output-Commitment';

  @override
  String get txDetailsOutputCommitmentCopy => 'Output-Commitment kopieren';

  @override
  String get txDetailsOutputCommitmentCopied => 'Output-Commitment kopiert';

  @override
  String txDetailsOutputCommitmentNumbered(int number) {
    return 'Output-Commitment $number';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopy(int number) {
    return 'Output-Commitment $number kopieren';
  }

  @override
  String txDetailsOutputCommitmentNumberedCopied(int number) {
    return 'Output-Commitment $number kopiert';
  }

  @override
  String get txDetailsExpiryHeight => 'Ablauf-Blockhöhe';

  @override
  String get txDetailsLocalId => 'Lokale ID';

  @override
  String get txDetailsSourceRestored =>
      'Durch Scannen der Blockchain gefunden. Angaben wie Absender und Gebühr werden nicht auf der Blockchain gespeichert. Importieren Sie eine Verlaufssicherung, um sie wiederherzustellen.';

  @override
  String get txDetailsSourceImported =>
      'Aus einer Verlaufssicherung importiert. Diese Wallet hat keine eigenen Daten dazu, daher ist der Status möglicherweise veraltet.';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historyLoading => 'Zahlungen werden geladen';

  @override
  String get historyRefreshing => 'Wird aktualisiert';

  @override
  String get historySearchLabel => 'Suche';

  @override
  String get historySearchHint => 'Notiz, Kontakt, Adresse oder Betrag';

  @override
  String get historyClearSearch => 'Suche löschen';

  @override
  String get historyFilterAll => 'Alle';

  @override
  String get historyFilterSent => 'Gesendet';

  @override
  String get historyFilterReceived => 'Empfangen';

  @override
  String get historyFilterPending => 'Ausstehend';

  @override
  String get historyFilterCancelled => 'Abgebrochen';

  @override
  String get historySectionPending => 'Ausstehend';

  @override
  String get historyEmpty =>
      'Noch nichts da. Gesendete und empfangene Zahlungen erscheinen hier.';

  @override
  String get historyNoSent => 'Keine gesendeten Zahlungen.';

  @override
  String get historyNoReceived => 'Keine empfangenen Zahlungen.';

  @override
  String get historyNoPending => 'Keine ausstehenden Zahlungen.';

  @override
  String get historyNoCancelled => 'Keine abgebrochenen Zahlungen.';

  @override
  String historyNoMatch(String query) {
    return 'Keine Treffer für „$query“.';
  }

  @override
  String get historyBackupSaveDialogTitle => 'Zahlungsverlauf speichern';

  @override
  String get historyBackupOpenDialogTitle => 'Verlaufssicherung öffnen';

  @override
  String get historyBackupFileTooLarge =>
      'Diese Datei ist zu groß für eine Sicherung.';

  @override
  String get historyBackupShare => 'Teilen';

  @override
  String get historyBackupShareSubtitle =>
      'Kopie außerhalb dieses Smartphones, etwa per E-Mail oder in der Cloud';

  @override
  String get historyBackupSaveToDevice => 'Auf dem Gerät speichern';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Nur sinnvoll, wenn Sie die Datei auch außerhalb dieses Smartphones sichern.';

  @override
  String historyBackupSaved(String fileName) {
    return '$fileName gespeichert';
  }

  @override
  String get historyBackupExportTitle => 'Verlaufssicherung exportieren';

  @override
  String get historyBackupExportNote =>
      'Verlaufssicherungen enthalten die Zahlungen bis heute. Exportieren Sie nach neuen Zahlungen erneut.';

  @override
  String get historyBackupCsvTitle => 'CSV exportieren';

  @override
  String get historyBackupCsvWarning =>
      'Die CSV-Datei ist nicht verschlüsselt. Wer sie erhält, kann Ihre Beträge, Datumsangaben, Adressen und Notizen lesen. Sie lässt sich nicht wieder importieren; nutzen Sie dafür „Verlaufssicherung exportieren“.';

  @override
  String get historyBackupCsvConfirm => 'CSV exportieren';

  @override
  String get historyBackupImportedTitle => 'Verlauf importiert';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Verlauf nicht importiert. $reason';
  }

  @override
  String get historyBackupImportNothingNew =>
      'Die Sicherung enthielt nichts Neues.';

  @override
  String historyBackupImportMerged(int merged) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedAdded(int merged, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportSkipped(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedSkipped(int merged, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
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
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportContacts(int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
    );
    return '$_temp0.';
  }

  @override
  String historyBackupImportMergedContacts(int merged, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      merged,
      locale: localeName,
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String historyBackupImportAddedContacts(int added, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
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
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
    );
    return '$_temp0, $_temp1, $_temp2.';
  }

  @override
  String historyBackupImportSkippedContacts(int skipped, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
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
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
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
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    String _temp2 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
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
      other: 'Details von $merged Zahlungen wiederhergestellt',
      one: 'Details von 1 Zahlung wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added ältere Zahlungen hinzugefügt',
      one: '1 ältere Zahlung hinzugefügt',
    );
    String _temp2 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped Einträge waren bereits vorhanden',
      one: '1 Eintrag war bereits vorhanden',
    );
    String _temp3 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3.';
  }

  @override
  String get homeLockTooltip => 'Wallet sperren';

  @override
  String get shellTitle => 'Epic Cash';

  @override
  String get demoWelcomeTitle => 'Epic Cash Wallet ausprobieren';

  @override
  String get demoWelcomeLine =>
      'Eine echte Epic-Cash-Wallet im Testnetz Floonet.';

  @override
  String get demoWelcomeNoValue => 'Die Coins haben keinen Wert.';

  @override
  String get demoWelcomeNothingToInstall => 'Nichts zu installieren.';

  @override
  String get demoWelcomeDeleted =>
      'Ihre Demo-Wallet wird 24 Stunden nach dem Start gelöscht.';

  @override
  String get demoStart => 'Demo starten';

  @override
  String get demoGetApp => 'App holen';

  @override
  String get demoEndedTitle => 'Ihre Demo ist beendet';

  @override
  String get demoEndedBody =>
      'Ihre Wallet und die Test-Coins wurden 24 Stunden nach dem Start gelöscht. Mit Neu starten beginnen Sie eine neue.';

  @override
  String get demoStartAgain => 'Neu starten';

  @override
  String demoEndsInHours(int hours) {
    return 'Demo, endet in $hours h';
  }

  @override
  String demoEndsInMinutes(int minutes) {
    return 'Demo, endet in $minutes Min.';
  }

  @override
  String demoEndsAt(String time) {
    return 'Ihre Demo endet am $time. Dann werden ihre Wallet und die Test-Coins gelöscht.';
  }

  @override
  String get demoEndingSoon =>
      'Ihre Demo endet in 30 Minuten. Dann werden ihre Wallet und die Test-Coins gelöscht.';

  @override
  String get demoTestCoins => 'Test-Coins holen';

  @override
  String get demoTestCoinsPaid =>
      'Die Test-Coins sind unterwegs. Sie kommen in ein bis zwei Minuten an.';

  @override
  String demoTestCoinsCooldown(int seconds) {
    return 'Der Faucet braucht eine Pause. Versuchen Sie es in $seconds s erneut.';
  }

  @override
  String get demoTestCoinsFailed =>
      'Der Faucet hat diesmal nichts gesendet. Versuchen Sie es in einer Minute erneut.';

  @override
  String get demoEnd => 'Demo beenden';

  @override
  String get demoEndTitle => 'Demo beenden?';

  @override
  String get demoEndBody =>
      'Ihre Demo-Wallet und ihre Test-Coins werden jetzt gelöscht. Danach können Sie eine neue Demo starten.';

  @override
  String get demoServerUnreachable =>
      'Der Demo-Server ist nicht erreichbar. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String demoStartFull(int minutes) {
    return 'Die Demo ist gerade voll. Versuchen Sie es in $minutes Min. erneut.';
  }

  @override
  String demoStartTooMany(int minutes) {
    return 'Aus Ihrem Netzwerk wurden zu viele Demos gestartet. Versuchen Sie es in $minutes Min. erneut.';
  }

  @override
  String get demoConnectionLost =>
      'Verbindung unterbrochen, wird wiederhergestellt.';

  @override
  String get demoConnectionBack => 'Wieder verbunden.';

  @override
  String get homeSettingsTooltip => 'Einstellungen';

  @override
  String get homeSettingsUpdateTooltip =>
      'Einstellungen: Ein Update ist verfügbar';

  @override
  String get homeSendButton => 'Senden';

  @override
  String get shellWalletTab => 'Wallet';

  @override
  String get homeReceiveButton => 'Empfangen';

  @override
  String get homeScanTooltip => 'QR-Code zum Senden scannen';

  @override
  String get homeRecentActivity => 'Letzte Aktivitäten';

  @override
  String get homeSeeAll => 'Alle anzeigen';

  @override
  String get homeBackedUpNotice => 'Wiederherstellungsphrase gesichert';

  @override
  String get homeNoticeView => 'Anzeigen';

  @override
  String get homePushNotice =>
      'In Ihrer epicbox wartet eine Zahlung, die eintrifft, sobald die App verbunden ist.';

  @override
  String get homeNoticeReceived =>
      'Eine Zahlung ist unterwegs und wird abgeschlossen, sobald der Absender sie fertigstellt.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return 'Eine Zahlung von $who ist unterwegs und wird abgeschlossen, sobald der Absender sie fertigstellt.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount unterwegs. Die Zahlung wird abgeschlossen, sobald der Absender sie fertigstellt.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$amount von $who unterwegs. Die Zahlung wird abgeschlossen, sobald der Absender sie fertigstellt.';
  }

  @override
  String get homeNoticeFinished =>
      'Zahlung fertiggestellt. Warten auf Bestätigungen.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Zahlung an $who fertiggestellt. Warten auf Bestätigungen.';
  }

  @override
  String get homeNoticeRepeated =>
      'Diese Zahlung wurde bereits angenommen. Der Absender hat dieselbe Antwort erneut erhalten; es ist keine zweite Zahlung unterwegs.';

  @override
  String homeNoticeRepeatedFrom(String who) {
    return 'Die Zahlung von $who wurde bereits angenommen. Der Absender hat dieselbe Antwort erneut erhalten; es ist keine zweite Zahlung unterwegs.';
  }

  @override
  String get homeNoticeDelayed =>
      'Der Node ist nicht erreichbar. Die Zahlung wird abgeschlossen, sobald er wieder erreichbar ist.';

  @override
  String get homeNoticeRelayProblem =>
      'Der epicbox-Server meldet ein Problem. Wird erneut versucht.';

  @override
  String get homeNoticePaymentFailed =>
      'Eine Zahlung konnte nicht abgeschlossen werden.';

  @override
  String get homeBackupCardText => 'Sichern Sie Ihre Wiederherstellungsphrase.';

  @override
  String get homeBackupCardButton => 'Sichern';

  @override
  String get homeBackupCardDismiss => 'Ausblenden';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen sind in keiner Verlaufssicherung enthalten. Eine Wiederherstellung mit Ihrer Wiederherstellungsphrase bringt nur Ihr Guthaben zurück.',
      one: '1 Zahlung ist in keiner Verlaufssicherung enthalten. Eine Wiederherstellung mit Ihrer Wiederherstellungsphrase bringt nur Ihr Guthaben zurück.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen sind seit Ihrer letzten Verlaufssicherung neu oder geändert. Eine Wiederherstellung mit Ihrer Wiederherstellungsphrase bringt nur Ihr Guthaben zurück.',
      one: '1 Zahlung ist seit Ihrer letzten Verlaufssicherung neu oder geändert. Eine Wiederherstellung mit Ihrer Wiederherstellungsphrase bringt nur Ihr Guthaben zurück.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Nicht jetzt';

  @override
  String get homeHistoryExportButton => 'Verlaufssicherung exportieren';

  @override
  String get homeBalanceSpendable => 'Verfügbar';

  @override
  String get balanceHelpLabel => 'Was diese Guthaben bedeuten';

  @override
  String get balanceTotal => 'Gesamt';

  @override
  String balanceHelpRow(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get balanceTotalHelp =>
      'Alles in dieser Wallet, verfügbar oder nicht.';

  @override
  String get homeBalanceHiddenLabel => 'Guthaben verborgen';

  @override
  String get homeShowBalances => 'Guthaben anzeigen';

  @override
  String get homeHideBalances => 'Guthaben verbergen';

  @override
  String get homeBalanceConfirming => 'Wird bestätigt';

  @override
  String get balanceConfirmingHelp =>
      'In der Chain, wartet auf genug Bestätigungen.';

  @override
  String get homeBalanceWaitingToFinish => 'Wartet auf Abschluss';

  @override
  String get balanceWaitingHelp =>
      'Von Ihnen angenommen; der Absender muss sie noch abschließen.';

  @override
  String get homeBalanceLocked => 'Durch laufende Zahlung gesperrt';

  @override
  String get balanceLockedHelp =>
      'Für eine begonnene Zahlung reserviert; das Wechselgeld kommt nach Abschluss zurück.';

  @override
  String get homeBalanceImmature => 'Mining-Belohnungen noch nicht verfügbar';

  @override
  String get balanceImmatureHelp =>
      'Mining-Belohnungen warten eine feste Zahl von Blöcken, bevor sie verfügbar sind.';

  @override
  String balanceLineConfirming(String amount) {
    return '+$amount wird bestätigt';
  }

  @override
  String balanceLineWaiting(String amount) {
    return '+$amount wartet auf Absender';
  }

  @override
  String balanceLineLocked(String amount) {
    return '$amount durch eine Zahlung gesperrt';
  }

  @override
  String balanceLineMining(String amount) {
    return '$amount Mining-Belohnungen reifen';
  }

  @override
  String get balanceLineAllConfirmed => 'Alles bestätigt';

  @override
  String get balanceLineNothingYet => 'Noch nichts da';

  @override
  String get shellPendingLabel => 'Zahlungen unterwegs';

  @override
  String get homeSyncSyncing => 'Wird synchronisiert…';

  @override
  String homeSyncSyncingPercent(int percent) {
    return 'Wird synchronisiert… $percent %';
  }

  @override
  String get homeSyncNodeUnreachable =>
      'Node nicht erreichbar. Guthaben möglicherweise nicht aktuell.';

  @override
  String get homeSyncNotValidated =>
      'Nicht mit dem Node abgeglichen. Guthaben möglicherweise nicht aktuell.';

  @override
  String get homeSyncUpToDate => 'Aktuell.';

  @override
  String get homeSyncContactingNode => 'Node wird kontaktiert…';

  @override
  String get statusNodeOnline => 'Node online';

  @override
  String get statusNodeSyncing => 'Node synchronisiert';

  @override
  String statusNodeSyncingPercent(int percent) {
    return 'Node synchronisiert $percent %';
  }

  @override
  String get statusNodeConnecting => 'Node verbindet';

  @override
  String get statusNodeOffline => 'Node offline';

  @override
  String get statusEpicboxOnline => 'epicbox online';

  @override
  String get statusEpicboxConnecting => 'epicbox verbindet';

  @override
  String get statusEpicboxOffline => 'epicbox offline';

  @override
  String statusNodeTestNetwork(String network) {
    return '$network, Test-Coins';
  }

  @override
  String statusNodeHost(Object host) {
    return 'Node: $host';
  }

  @override
  String statusNodeVersion(Object version) {
    return 'Node-Version $version';
  }

  @override
  String statusRelay(Object relay) {
    return 'Server: $relay';
  }

  @override
  String get homeEpicboxOffline =>
      'Verbindung zur epicbox getrennt, wird wiederhergestellt.';

  @override
  String get homeEpicboxConnecting =>
      'Verbindung zur epicbox wird hergestellt…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Synchronisiert bis Block $height';
  }

  @override
  String homePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen warten auf ihre Empfänger',
      one: 'Eine Zahlung wartet auf den Empfänger',
    );
    return '$_temp0';
  }

  @override
  String homePendingBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Für $amount stehen die Antworten der Wallets der Empfänger noch aus. Bis dahin bleibt der Betrag gesperrt. Falls eine davon nie antwortet, öffnen Sie die Zahlung und tippen Sie auf „Zahlung abbrechen“.',
      one:
          'Für $amount steht die Antwort der Wallet des Empfängers noch aus. Bis dahin bleibt der Betrag gesperrt. Falls keine Antwort kommt, öffnen Sie die Zahlung und tippen Sie auf „Zahlung abbrechen“.',
    );
    return '$_temp0';
  }

  @override
  String get homePendingWhy => 'Warum noch offen?';

  @override
  String homePendingView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zahlungen anzeigen',
      one: 'Zahlung anzeigen',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPayments => 'Noch keine Zahlungen.';

  @override
  String get invoicesTitle => 'Rechnungen';

  @override
  String invoicesEntryTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rechnungen, $count offen',
      one: 'Rechnungen, 1 offen',
      zero: 'Rechnungen',
    );
    return '$_temp0';
  }

  @override
  String get invoicesChecking => 'Rechnungen werden abgerufen';

  @override
  String get invoicesEmpty =>
      'Keine offenen Rechnungen. Wenn Ihnen ein vertrauenswürdiger Dienst eine Rechnung schickt, erscheint sie hier. Bezahlt wird nichts, bevor Sie zustimmen.';

  @override
  String get invoicesUnnamedService => 'Unbenannter Dienst';

  @override
  String invoiceTimeLeftHours(int hours, int minutes) {
    return 'Noch $hours Std. $minutes Min.';
  }

  @override
  String invoiceTimeLeftMinutes(int minutes) {
    return 'Noch $minutes Min.';
  }

  @override
  String get invoiceTimeLeftUnderMinute => 'Weniger als eine Minute übrig';

  @override
  String get invoiceExpired =>
      'Diese Rechnung ist abgelaufen. Es wurde nichts bezahlt.';

  @override
  String get invoiceGone =>
      'Diese Rechnung ist nicht mehr offen. Es wurde nichts bezahlt.';

  @override
  String get invoiceReviewTitle => 'Rechnung prüfen';

  @override
  String invoiceReviewAsks(String service) {
    return '$service bittet Sie um Zahlung';
  }

  @override
  String get invoiceReviewMessageLabel => 'Nachricht des Dienstes';

  @override
  String get invoiceReviewNote =>
      'Ihre Wallet fügt die Netzwerkgebühr hinzu. Bezahlt wird erst, wenn Sie zustimmen.';

  @override
  String get invoiceApprove => 'Zustimmen und bezahlen';

  @override
  String get invoiceDecline => 'Ablehnen';

  @override
  String get invoicePinReason =>
      'Geben Sie Ihre PIN ein, um diese Rechnung zu bezahlen.';

  @override
  String get invoiceDeclineTitle => 'Diese Rechnung ablehnen?';

  @override
  String invoiceDeclineBody(String service) {
    return '$service erfährt, dass Sie abgelehnt haben. Es wird nichts bezahlt.';
  }

  @override
  String get invoiceDeclineKeep => 'Behalten';

  @override
  String get invoiceDeclinedNotice => 'Rechnung abgelehnt.';

  @override
  String invoicePaidNotice(String service) {
    return 'Bezahlt. $service schließt die Zahlung jetzt ab.';
  }

  @override
  String invoiceReplyFailedTitle(String service) {
    return 'Ihre Zahlung hat $service noch nicht erreicht';
  }

  @override
  String get invoiceReplyFailedBody =>
      'Sie ist signiert und auf diesem Gerät gespeichert. „Erneut senden“ schickt sie noch einmal, ohne dass Sie erneut zustimmen.';

  @override
  String get invoiceReplyFailedNotice =>
      'Ihre Zahlung konnte den Dienst nicht erreichen. Tippen Sie auf „Erneut senden“.';

  @override
  String get invoiceRetry => 'Erneut senden';

  @override
  String get invoiceDetailsSection => 'Rechnung';

  @override
  String get invoiceDetailsService => 'Gestellt von';

  @override
  String invoiceDetailsReplied(String service) {
    return 'Warten, bis $service die Zahlung veröffentlicht.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service meldet, dass die Zahlung veröffentlicht wurde. Sie ist abgeschlossen, sobald das Netzwerk sie bestätigt.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service hat Ihre Zahlung noch nicht erhalten. „Erneut senden“ schickt sie noch einmal, ohne dass Sie erneut zustimmen.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '$service hat diese Rechnung zurückgezogen, nachdem Sie sie bezahlt haben. Wenn die Zahlung nicht bestätigt wird, brechen Sie sie ab, um Ihr Guthaben freizugeben.';
  }

  @override
  String get invoiceNoticeReceived =>
      'Eine Rechnung wartet auf Ihre Zustimmung.';

  @override
  String get invoiceNoticePosted =>
      'Ein Dienst meldet, dass er Ihre Zahlung veröffentlicht hat.';

  @override
  String get invoiceNoticeWithdrawnPaid =>
      'Ein Dienst hat eine bereits bezahlte Rechnung zurückgezogen.';

  @override
  String get invoiceNoticeWithdrawn =>
      'Ein Dienst hat eine Rechnung zurückgezogen, bevor Sie geantwortet haben.';

  @override
  String get invoiceNoticeExpired =>
      'Eine Rechnung ist abgelaufen, bevor Sie geantwortet haben.';

  @override
  String get receiveRequestTitle => 'Zahlung anfordern';

  @override
  String get requestTitle => 'Zahlung anfordern';

  @override
  String get requestStepsIntro =>
      'Die Wallet der anderen Seite muss Rechnungen annehmen. Vor der Anforderung:';

  @override
  String get requestStepTrust =>
      '1. Die andere Seite fügt Ihre Adresse unten zu ihren vertrauenswürdigen Diensten hinzu.';

  @override
  String get requestStepAddress =>
      '2. Die andere Seite gibt Ihnen ihre Rechnungsadresse.';

  @override
  String get requestYourAddress => 'Ihre Adresse';

  @override
  String get requestPayerLabel => 'Rechnungsadresse der anderen Seite';

  @override
  String get requestPayerMissing =>
      'Fügen Sie die Rechnungsadresse ein oder scannen Sie sie.';

  @override
  String get requestPayerOwn =>
      'Das ist eine Ihrer eigenen Adressen. Geben Sie die Rechnungsadresse ein, die Ihnen der Zahler gibt.';

  @override
  String get requestMessageLabel => 'Nachricht an den Zahler (optional)';

  @override
  String get requestMessageHelper =>
      'Der Zahler sieht diese Nachricht mit Ihrer Anforderung.';

  @override
  String get requestButton => 'Anfordern';

  @override
  String requestSentNotice(String payer) {
    return 'Anforderung an $payer gesendet.';
  }

  @override
  String get invoicesToPaySection => 'Zu zahlen';

  @override
  String get invoicesNoneToPay => 'Nichts zu zahlen.';

  @override
  String get invoicesSentSection => 'Ihre Anforderungen';

  @override
  String get issuedPaid => 'Bezahlt';

  @override
  String get issuedDeclined => 'Abgelehnt';

  @override
  String get issuedWithdrawn => 'Zurückgezogen';

  @override
  String get issuedExpired => 'Abgelaufen';

  @override
  String get issuedWithdraw => 'Zurückziehen';

  @override
  String get issuedWithdrawTitle => 'Diese Anforderung zurückziehen?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer kann sie dann nicht mehr bezahlen. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String get issuedWithdrawKeep => 'Behalten';

  @override
  String get issuedDetailsSection => 'Zahlungsanforderung';

  @override
  String get issuedDetailsPayer => 'Angefordert bei';

  @override
  String get issuedDetailsWaiting =>
      'Warten auf den Zahler. Ihre Wallet schließt die Zahlung ab, sobald sie eintrifft.';

  @override
  String get issuedDetailsPaid =>
      'Bezahlt. Ihre Wallet hat die Zahlung abgeschlossen; sie ist fertig, sobald das Netzwerk sie bestätigt.';

  @override
  String get issuedDetailsDeclined =>
      'Der Zahler hat diese Anforderung abgelehnt, daher wurde sie zurückgezogen. Es wurde nichts bezahlt.';

  @override
  String get issuedDetailsWithdrawn =>
      'Sie haben diese Anforderung zurückgezogen. Es wurde nichts bezahlt.';

  @override
  String get issuedDetailsExpired =>
      'Diese Anforderung ist abgelaufen, bevor sie bezahlt wurde. Es wurde nichts bezahlt.';

  @override
  String get issuerNoticePaid => 'Eine Ihrer Anforderungen wurde bezahlt.';

  @override
  String get issuerNoticeDeclined =>
      'Eine Ihrer Anforderungen wurde abgelehnt.';

  @override
  String get issuerNoticeWithdrawn =>
      'Anforderung zurückgezogen. Sie kann nicht mehr bezahlt werden.';

  @override
  String get issuerNoticeExpired =>
      'Eine Ihrer Anforderungen ist unbezahlt abgelaufen.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Die Wallet von $payer kann keine Anforderungen bezahlen und hat Ihre zurückgeschickt, daher wurde sie zurückgezogen. Bitten Sie die Person, Ihnen die Zahlung stattdessen zu senden, an Ihre Adresse oder als Zahlungsdatei.';
  }

  @override
  String get issuedBounced => 'Zurückgeschickt';

  @override
  String get issuedDetailsBounced =>
      'Die Wallet des Zahlers kann keine Anforderungen bezahlen und hat diese zurückgeschickt, daher wurde sie zurückgezogen. Es wurde nichts bezahlt. Bitten Sie die Person, Ihnen die Zahlung stattdessen zu senden, an Ihre Adresse oder als Zahlungsdatei.';

  @override
  String get requestPayerNoInvoices =>
      'Diese Wallet hat schon einmal eine Anforderung zurückgeschickt: Sie kann keine Anforderungen bezahlen. Bitten Sie die Person, Ihnen die Zahlung stattdessen zu senden, an Ihre Adresse oder als Zahlungsdatei.';

  @override
  String get txStatusWaitingPayer => 'Wartet auf Zahler';

  @override
  String get txStepRequested => 'Angefordert';

  @override
  String get txStepPaid => 'Bezahlt';

  @override
  String get txDetailsWaitingPayer =>
      'Sie haben diese Zahlung angefordert. Bisher ist nichts eingegangen: Die Zahlung kommt, sobald der Zahler die Anforderung bezahlt.';

  @override
  String get txDetailsRequestEnded =>
      'Diese Anforderung wurde nicht bezahlt. Es ist nichts eingegangen.';

  @override
  String get txDetailsRequestedFrom => 'Angefordert von';

  @override
  String get txPaymentRequest => 'Angeforderte Zahlung';

  @override
  String txSpokenRequesting(String amount) {
    return 'Angefordert: $amount';
  }

  @override
  String txSpokenRequestingFrom(String amount, String who) {
    return 'Von $who angefordert: $amount';
  }

  @override
  String get receiveEpicboxConnected => 'Mit epicbox verbunden';

  @override
  String get receiveQrLabel => 'QR-Code Ihrer Adresse';

  @override
  String get receiveAddressLabel => 'Ihre Adresse';

  @override
  String get receiveEpicboxOfflineBody =>
      'An Sie gesendete Zahlungen warten jetzt bei epicbox und kommen an, sobald die Wallet wieder verbunden ist.';

  @override
  String get receiveShareCardHeadline => 'Bezahl mich mit Epic Cash';

  @override
  String get receiveHelpButton => 'So funktioniert Empfangen';

  @override
  String get receiveAddressCopied => 'Adresse kopiert';

  @override
  String get receiveFileTitle => 'Per Zahlungsdatei empfangen';

  @override
  String get receiveFileBody =>
      'Sie haben eine Zahlungsdatei bekommen? Öffnen Sie sie, oder kopieren Sie ihren Text und fügen Sie ihn hier ein.';

  @override
  String get receiveFileOpen => 'Datei öffnen';

  @override
  String get receivePasteEmpty =>
      'Kopieren Sie zuerst den Zahlungstext und tippen Sie dann auf Einfügen.';

  @override
  String get updateChecking => 'Suche nach Updates…';

  @override
  String get updateUpToDate => 'Dies ist die neueste Version.';

  @override
  String updateAvailable(String version) {
    return 'Version $version ist verfügbar.';
  }

  @override
  String updateDownloading(String version, int percent) {
    return 'Version $version wird heruntergeladen… $percent %';
  }

  @override
  String updateInstalling(String version) {
    return 'Version $version wird installiert…';
  }

  @override
  String get updateFailed => 'Das Update ist fehlgeschlagen.';

  @override
  String get updateInstallButton => 'Aktualisieren';

  @override
  String get updateTryAgain => 'Wiederholen';

  @override
  String get updateDownloadProgressLabel => 'Download-Fortschritt';

  @override
  String get updateNeedsPermission =>
      'Erlauben Sie dieser App im geöffneten Bildschirm, Updates zu installieren, und tippen Sie dann erneut auf „Aktualisieren“.';

  @override
  String updateNotInstalled(String detail) {
    return 'Das Update wurde nicht installiert: $detail';
  }

  @override
  String updateCannotInstall(String detail) {
    return 'Das Update kann nicht installiert werden: $detail.';
  }

  @override
  String get updateCannotInstallUnknown =>
      'Das Update kann nicht installiert werden: unbekannter Fehler.';

  @override
  String get updateManifestNotJson =>
      'Die Update-Informationen sind kein gültiges JSON.';

  @override
  String get updateManifestWrongShape =>
      'Die Update-Informationen haben ein falsches Format.';

  @override
  String get updateManifestOtherApp =>
      'Die Update-Informationen gehören zu einer anderen App.';

  @override
  String get updateManifestNoApks =>
      'Die Update-Informationen enthalten keine APKs.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'Der Download ist fehlgeschlagen (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge =>
      'Der Download ist größer als angekündigt.';

  @override
  String get updateDownloadIncomplete => 'Der Download ist unvollständig.';

  @override
  String get updateDownloadDamaged =>
      'Der Download ist beschädigt (Prüfsumme stimmt nicht überein).';

  @override
  String get updateDownloadInterrupted => 'Der Download wurde unterbrochen.';

  @override
  String get updateServerUnreachable =>
      'Der Update-Server ist nicht erreichbar.';

  @override
  String updateServerHttpStatus(int status) {
    return 'Der Update-Server hat mit HTTP $status geantwortet.';
  }

  @override
  String get updateServerTimeout =>
      'Der Update-Server hat nicht rechtzeitig geantwortet.';

  @override
  String get updateConnectionFailed =>
      'Die Verbindung zum Update-Server ist fehlgeschlagen.';

  @override
  String get updateCheckFailed => 'Die Suche nach Updates ist fehlgeschlagen.';

  @override
  String get setupTitle => 'Netzwerkeinstellungen';

  @override
  String get setupNetworkSettingsTooltip => 'Netzwerkeinstellungen';

  @override
  String get setupNetworkHeading => 'Netzwerk';

  @override
  String get setupNodeUrlLabel => 'Node-URL';

  @override
  String get setupNodeUrlInvalid =>
      'Geben Sie eine vollständige URL ein, z. B. https://node.example.com';

  @override
  String get setupTestConnection => 'Verbindung testen';

  @override
  String setupTestConnected(String height, String version) {
    return 'Verbunden. Der Node steht bei Block $height und läuft mit Version $version.';
  }

  @override
  String setupTestFailed(String error) {
    return 'Keine Verbindung möglich. $error';
  }

  @override
  String get setupConnectedIconLabel => 'Verbunden';

  @override
  String get setupRelayHeading => 'epicbox-Server';

  @override
  String get setupRelayHint => 'Dieser Server ist Teil Ihrer Adresse.';

  @override
  String get setupCustomRelayLabel =>
      'Anderer epicbox-Server (Host oder host:port)';

  @override
  String get setupCustomRelayUse => 'Diesen Server verwenden';

  @override
  String get setupCustomRelayInvalid =>
      'Geben Sie einen Host ein, z. B. epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      'Wenn Sie den epicbox-Server wechseln, ändert sich Ihre Adresse. Geben Sie Absendern die neue Adresse. An die alte Adresse gesendete Zahlungen warten auf dem alten Server, bis Sie zurückwechseln.';

  @override
  String get setupWalletPerNetwork =>
      'Jedes Netzwerk hat eine eigene Wallet. Für ein Netzwerk ohne Wallet wird eine neue erstellt.';

  @override
  String get setupRelayHealthyIconLabel => 'Funktioniert';

  @override
  String get setupRelayDownIconLabel => 'Ausgefallen';

  @override
  String get setupRelayHealthUnavailable =>
      'Der Serverstatus ist bei status.btlabs.uk nicht abrufbar.';

  @override
  String get setupRelayHealthSource =>
      'Status von status.btlabs.uk, gemessen von dessen Server aus.';

  @override
  String get setupRelayNotMonitored => 'Nicht überwacht';

  @override
  String get setupRelayUp => 'Online';

  @override
  String get setupRelayDown => 'Offline';

  @override
  String get setupRelayOfficial => 'offiziell';

  @override
  String setupRelayUptime(String percent) {
    return '$percent % erreichbar in den letzten 24 h';
  }

  @override
  String get restoreTitle => 'Wallet wiederherstellen';

  @override
  String get restorePhraseLabel => 'Wiederherstellungsphrase';

  @override
  String get restorePhraseHelper =>
      'Die 12 oder 24 Wörter, durch Leerzeichen getrennt.';

  @override
  String get restoreStartHeading => 'Beginn des Scans';

  @override
  String get restoreStartByDate => 'Datum';

  @override
  String get restoreStartByHeight => 'Blockhöhe';

  @override
  String get restoreStartHeightLabel => 'Startblock (optional)';

  @override
  String get restoreStartHeightHelper =>
      'Ab diesem Block scannen. Leer lassen, um die gesamte Blockchain zu scannen.';

  @override
  String get restoreStartHeightInvalid =>
      'Der Startblock muss eine ganze Zahl sein.';

  @override
  String get restoreBackToPhrase => 'Zurück zur Phrase';

  @override
  String get restoreDatePickerTitle => 'Wann haben Sie die Wallet erstellt?';

  @override
  String get restorePickDate => 'Erstellungsdatum der Wallet wählen';

  @override
  String restoreFromDate(String date) {
    return 'Ab $date';
  }

  @override
  String get restoreDateHint =>
      'Optional. Wenn Sie unsicher sind, wählen Sie ein früheres Datum. Bei einem Datum nach Ihrer ersten Zahlung wird Guthaben übersehen. Ohne Datum wird die gesamte Blockchain gescannt, was länger dauert.';

  @override
  String restoreDateStart(String height) {
    return 'Der Scan beginnt zwei Tage vor diesem Datum, ab Block $height.';
  }

  @override
  String get restoreWholeChain => 'Stattdessen die gesamte Blockchain scannen';

  @override
  String get restoreScanIntro =>
      'Ihr Guthaben wird auf der Blockchain gesucht. Lassen Sie die App geöffnet, bis der Vorgang abgeschlossen ist.';

  @override
  String get restoreOpenWallet => 'Wallet öffnen';

  @override
  String get restoreRescanLater =>
      'Einen vollständigen neuen Scan können Sie später in den Einstellungen starten.';

  @override
  String get restoreDoneIconLabel => 'Fertig';

  @override
  String get restoreDoneTitle => 'Ihre Wallet ist wiederhergestellt';

  @override
  String get restoreImportExplanation =>
      'Die Blockchain enthält Ihr Guthaben, aber nicht, wen Sie bezahlt haben, Gebühren oder Notizen. Wenn Sie aus dieser Wallet eine Verlaufssicherung exportiert haben, importieren Sie sie jetzt, um diese Angaben zurückzuholen. Es ist die .wfeh-Datei, die Sie außerhalb Ihres alten Smartphones geteilt oder gespeichert haben.';

  @override
  String get restoreImportButton => 'Verlaufssicherung importieren';

  @override
  String get restoreImportNotNow => 'Nicht jetzt';

  @override
  String get restoreImportLater =>
      'Sie können sie später in den Einstellungen importieren.';

  @override
  String get restoreScanProgressLabel => 'Scan-Fortschritt';

  @override
  String get firstRunTitle => 'Willkommen';

  @override
  String get firstRunRestore =>
      'Ich habe bereits eine Wallet: wiederherstellen';

  @override
  String get firstRunSecuring => 'Ihre Wallet wird gesichert…';

  @override
  String get firstRunTryAgain => 'Erneut versuchen';

  @override
  String get firstRunBiometricsNotSetUp =>
      'Die biometrische Entsperrung wurde nicht eingerichtet. Sie können sie in den Einstellungen aktivieren.';

  @override
  String get backupTitle => 'Wiederherstellungsphrase';

  @override
  String get backupPinReason =>
      'Geben Sie Ihre PIN ein, um die Wiederherstellungsphrase anzuzeigen.';

  @override
  String get backupCopyWarning =>
      'Auf dem nächsten Bildschirm sind Screenshots erlaubt. Ein Screenshot oder Foto der Phrase ist eine vollständige Kopie Ihrer Wallet: Wer ihn sieht, kann Ihr Guthaben nehmen, und Foto-Apps laden ihn unter Umständen in die Cloud hoch. Papier ist am sichersten.';

  @override
  String get backupCopyAgree => 'Ich halte jede Kopie der Phrase geheim';

  @override
  String get backupShowPhrase => 'Wiederherstellungsphrase anzeigen';

  @override
  String get backupWarningIconLabel => 'Warnung';

  @override
  String backupWriteDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Schreiben Sie diese $count Wörter der Reihe nach auf Papier und halten Sie sie geheim. Nur mit ihnen lässt sich diese Wallet wiederherstellen.',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return 'Wort $number: $word';
  }

  @override
  String get unlockTitle => 'Wallet entsperren';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinRepeatLabel => 'PIN wiederholen';

  @override
  String pinChooseTitle(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Wählen Sie eine $digits-stellige PIN',
    );
    return '$_temp0';
  }

  @override
  String get pinConfirmTitle => 'Geben Sie die PIN erneut ein';

  @override
  String get pinChooseDifferent => 'Andere PIN wählen';

  @override
  String get pinMismatch =>
      'Die PINs stimmen nicht überein. Wählen Sie erneut eine PIN.';

  @override
  String get pinBiometricsIconLabel => 'Biometrie';

  @override
  String get pinBiometricsQuestion =>
      'Mit Fingerabdruck oder Gesicht entsperren?';

  @override
  String get pinBiometricsPinStillWorks =>
      'Ihre PIN können Sie weiterhin jederzeit verwenden.';

  @override
  String get pinBiometricsEnable => 'Biometrie verwenden';

  @override
  String get pinBiometricsNotNow => 'Nicht jetzt';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Falsche PIN. Noch $count Versuche vor einer Pause.',
      one: 'Falsche PIN. Noch 1 Versuch vor einer Pause.',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Falsche PIN. Der nächste Versuch wird nach $count Sekunden geprüft.',
      one: 'Falsche PIN. Der nächste Versuch wird nach 1 Sekunde geprüft.',
    );
    return '$_temp0';
  }

  @override
  String pinWrongWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Falsche PIN. Der nächste Versuch wird nach $count Minuten geprüft.',
      one: 'Falsche PIN. Der nächste Versuch wird nach 1 Minute geprüft.',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN wird in $count Sekunden geprüft…',
      one: 'PIN wird in 1 Sekunde geprüft…',
    );
    return '$_temp0';
  }

  @override
  String pinCheckingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN wird in $count Minuten geprüft…',
      one: 'PIN wird in 1 Minute geprüft…',
    );
    return '$_temp0';
  }

  @override
  String get pinChecking => 'PIN wird geprüft…';

  @override
  String get pinPromptTitle => 'Geben Sie Ihre PIN ein';

  @override
  String get pinUseBiometrics => 'Biometrie verwenden';

  @override
  String get pinForgot => 'PIN vergessen?';

  @override
  String get pinResetTitle => 'PIN vergessen';

  @override
  String get pinResetBody =>
      'Die PIN kann nicht wiederhergestellt werden. Sie können diese Wallet vom Gerät löschen und mit ihrer Wiederherstellungsphrase wiederherstellen. Ohne die Phrase ist das Guthaben endgültig verloren.';

  @override
  String get pinResetConfirm => 'Ich habe meine Wiederherstellungsphrase';

  @override
  String get pinResetKeep => 'Wallet behalten';

  @override
  String get pinResetDelete => 'Wallet löschen';

  @override
  String get launchTryAgain => 'Erneut versuchen';

  @override
  String get sendAmountNegative => 'Der Betrag darf nicht negativ sein.';

  @override
  String sendAmountAmbiguous(String asWhole, String asDecimal) {
    return 'Schreiben Sie $asWhole oder $asDecimal, damit der Betrag eindeutig ist.';
  }

  @override
  String get sendAmountUnclear =>
      'Schreiben Sie den Betrag ohne Trennzeichen, z. B. 1234,5, damit er eindeutig ist.';

  @override
  String get sendAmountNoPrice =>
      'Derzeit kein Kurs verfügbar. Geben Sie den Betrag in EPIC ein.';

  @override
  String get sendAmountEnterFiatExample =>
      'Geben Sie einen Betrag ein, z. B. 10,50';

  @override
  String get sendAmountTooLarge =>
      'Das ist mehr EPIC, als es jemals geben wird. Prüfen Sie den Betrag.';

  @override
  String get sendAmountZero => 'Geben Sie einen Betrag über null ein.';

  @override
  String get sendRecipientLabel => 'An';

  @override
  String get sendRecipientHintSimple => 'Adresse des Empfängers';

  @override
  String get sendUrlUnsupported =>
      'Zahlungen an eine Wallet-URL werden nicht unterstützt. Fragen Sie den Empfänger nach seiner epicbox-Adresse.';

  @override
  String get scanQrTooltip => 'QR-Code scannen';

  @override
  String get sendScanButton => 'Scannen';

  @override
  String get sendChooseContactTooltip => 'Kontakt auswählen';

  @override
  String get sendContactsButton => 'Kontakte';

  @override
  String get sendRecentLabel => 'Zuletzt:';

  @override
  String sendRecentTooltip(String address) {
    return 'An $address senden';
  }

  @override
  String sendSendingToContact(String name) {
    return 'Senden an $name';
  }

  @override
  String get sendStillConnecting =>
      'Verbindung wird noch hergestellt. Sie können jetzt senden; die Zahlung wird abgeschlossen, sobald die App verbunden ist.';

  @override
  String get sendMethodEpicbox => 'Epicbox-Adresse';

  @override
  String get sendMethodFile => 'Zahlungsdatei';

  @override
  String get sendFileIntro =>
      'Erstellen Sie eine Zahlungsdatei, schicken Sie sie auf beliebigem Weg an den Empfänger und öffnen Sie dann die Antwort, die er zurückschickt.';

  @override
  String get sendFileHelpTooltip => 'So funktioniert das Bezahlen per Datei';

  @override
  String sendAmountLabel(String unit) {
    return 'Betrag ($unit)';
  }

  @override
  String sendUseUnit(String unit) {
    return 'In $unit';
  }

  @override
  String get sendMax => 'Max.';

  @override
  String sendSpendable(String amount) {
    return 'Verfügbar: $amount';
  }

  @override
  String sendSpendableWithFiat(String amount, String fiat) {
    return 'Verfügbar: $amount (≈ $fiat)';
  }

  @override
  String sendFeeAndTotal(String fee, String total) {
    return 'Gebühr: $fee. Gesamt: $total.';
  }

  @override
  String get sendMessageLabel => 'Nachricht an den Empfänger (optional)';

  @override
  String get sendMessageHelper =>
      'Der Empfänger sieht diese Nachricht. Sie behalten sie auch als Notiz.';

  @override
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String get sendCreateFile => 'Zahlungsdatei erstellen';

  @override
  String get sendReview => 'Prüfen';

  @override
  String sendFileStep1(String file) {
    return 'Schritt 1: $file an den Empfänger übergeben';
  }

  @override
  String get sendFileLockedNote =>
      'Der Betrag bleibt gesperrt, bis Sie abschließen. Falls der Empfänger nie antwortet, öffnen Sie die Zahlung und tippen Sie auf „Zahlung abbrechen“.';

  @override
  String sendFileStep2(String file) {
    return 'Schritt 2: zurückgesendete Datei $file öffnen';
  }

  @override
  String get sendOpenResponseFile => 'Antwortdatei öffnen';

  @override
  String get sendCopyPasteInstead => 'Stattdessen kopieren und einfügen';

  @override
  String get sendSlateBoxTitle => 'Transaktionstext';

  @override
  String get sendPasteResponseLabel => 'Antwort des Empfängers einfügen';

  @override
  String get sendPasteResponseMissing =>
      'Fügen Sie den Antworttext des Empfängers ein.';

  @override
  String get slateFinishPayment => 'Zahlung abschließen';

  @override
  String sendResultStarted(String amount) {
    return 'Zahlung gestartet: $amount';
  }

  @override
  String sendResultSent(String amount) {
    return '$amount gesendet';
  }

  @override
  String get sendResultWaitingBody =>
      'Die Zahlung wird abgeschlossen, sobald die Wallet des Empfängers antwortet, meist innerhalb weniger Minuten, wenn dessen App geöffnet ist. Lassen Sie diese App geöffnet oder öffnen Sie sie innerhalb einer Woche wieder: So lange bewahrt die epicbox die Antwort etwa auf. Sie finden die Zahlung auf dem Startbildschirm und unter „Verlauf“.';

  @override
  String sendResultOnItsWay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die Zahlung ist auf dem Weg ins Netzwerk. Nach $count Bestätigungen wird sie als „Abgeschlossen“ angezeigt.',
      one: 'Die Zahlung ist auf dem Weg ins Netzwerk. Nach 1 Bestätigung wird sie als „Abgeschlossen“ angezeigt.',
    );
    return '$_temp0';
  }

  @override
  String sendResultAutoCancel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Ist die Zahlung nach $days Tagen noch nicht abgeschlossen, wird sie automatisch abgebrochen und der Betrag freigegeben. Um sie früher zu stoppen, öffnen Sie die Zahlung und tippen Sie auf „Zahlung abbrechen“.',
      one: 'Ist die Zahlung nach 1 Tag noch nicht abgeschlossen, wird sie automatisch abgebrochen und der Betrag freigegeben. Um sie früher zu stoppen, öffnen Sie die Zahlung und tippen Sie auf „Zahlung abbrechen“.',
    );
    return '$_temp0';
  }

  @override
  String sendResultFeeChanged(String charged, String reviewed) {
    return 'Die berechnete Gebühr betrug $charged statt der zuvor angezeigten $reviewed, weil die Wallet beim Senden ihre Coins neu ausgewählt hat.';
  }

  @override
  String get sendResultNoteNotSaved =>
      'Die Notiz konnte nicht gespeichert werden. Sie können sie hinzufügen, indem Sie die Zahlung öffnen.';

  @override
  String get sendSaveToContacts => 'In Kontakten speichern';

  @override
  String get sendHelp => 'Hilfe';

  @override
  String get sendReviewTitle => 'Zahlung prüfen';

  @override
  String get sendReviewTo => 'An';

  @override
  String get sendReviewAmount => 'Betrag';

  @override
  String get sendReviewFee => 'Gebühr';

  @override
  String get sendReviewTotal => 'Gesamt';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
  }

  @override
  String get sendReviewMessage => 'Nachricht';

  @override
  String get sendReviewViaEpicbox =>
      'Läuft über epicbox. Wird abgeschlossen, sobald die Wallet des Empfängers antwortet.';

  @override
  String get sendCheckNodeRunning => 'Node wird geprüft…';

  @override
  String get sendCheckNodeOk => 'Der Node antwortet';

  @override
  String get sendCheckNodeFailed =>
      'Der Node antwortet nicht, daher kann diese Zahlung jetzt nicht gesendet werden.';

  @override
  String get sendCheckListenerOk => 'Mit epicbox verbunden';

  @override
  String get sendCheckListenerFailed =>
      'Noch nicht mit epicbox verbunden. Sie können trotzdem senden; die Zahlung wird abgeschlossen, sobald die App verbunden ist.';

  @override
  String sendCheckRelayRunning(String relay) {
    return '$relay wird geprüft…';
  }

  @override
  String sendCheckRelayOk(String relay) {
    return '$relay ist erreichbar';
  }

  @override
  String sendCheckRelayFailed(String relay) {
    return '$relay antwortet gerade nicht. Sie können trotzdem senden; die Zahlung kommt eventuell später an.';
  }

  @override
  String sendReviewSendButton(String amount) {
    return '$amount senden';
  }

  @override
  String get sendReviewEdit => 'Bearbeiten';

  @override
  String get slateFileTitle => 'Transaktionsdatei';

  @override
  String get slateWrongPayment =>
      'Diese Antwort gehört zu einer anderen Zahlung. Öffnen Sie die Datei, die der Empfänger für diese Zahlung zurückgeschickt hat.';

  @override
  String get slateInvoiceUnsupported =>
      'Zahlungsanforderungen (Rechnungen) werden noch nicht unterstützt.';

  @override
  String get slateNotTransactionFile =>
      'Diese Datei ist keine Transaktionsdatei.';

  @override
  String get slateReading => 'Datei wird gelesen';

  @override
  String get slateFileTooLarge =>
      'Diese Datei ist zu groß für eine Transaktionsdatei.';

  @override
  String slatePostedHeadline(String amount) {
    return 'Zahlung über $amount an das Netzwerk gesendet.';
  }

  @override
  String slatePostedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nach $count Bestätigungen wird sie als „Abgeschlossen“ angezeigt.',
      one: 'Nach 1 Bestätigung wird sie als „Abgeschlossen“ angezeigt.',
    );
    return '$_temp0';
  }

  @override
  String slateAcceptedHeadline(String file) {
    return 'Angenommen. Senden Sie $file an den Absender zurück.';
  }

  @override
  String slateAcceptedBody(String amount) {
    return 'Der Betrag von $amount trifft ein, sobald der Absender die Zahlung abschließt und sie in der Blockchain steht.';
  }

  @override
  String slateRepeatedHeadline(String file) {
    return 'Bereits angenommen. Senden Sie $file erneut an den Absender zurück.';
  }

  @override
  String slateRepeatedBody(String amount) {
    return 'Sie haben diese Zahlung bereits angenommen. Dies ist dieselbe Antwort, keine zweite Zahlung. Der Betrag von $amount trifft ein, sobald der Absender sie abschließt und sie in der Blockchain steht.';
  }

  @override
  String slateIncomingSend(String amount) {
    return 'Jemand sendet Ihnen $amount.';
  }

  @override
  String slateIncomingResponse(String amount, String fee) {
    return 'Die Antwort des Empfängers auf Ihre Zahlung über $amount (Gebühr $fee).';
  }

  @override
  String get slateIncomingSendHint =>
      'Nehmen Sie sie an und senden Sie dann die Antwortdatei an den Absender zurück.';

  @override
  String get slateIncomingResponseHint =>
      'Schließen Sie sie ab, um die Zahlung an das Netzwerk zu senden.';

  @override
  String get slateAcceptPayment => 'Zahlung annehmen';

  @override
  String slateHandOverFailed(String file) {
    return '$file konnte nicht übergeben werden. Bitte versuchen Sie es erneut.';
  }

  @override
  String get slateSaveToDevice => 'Auf dem Gerät speichern';

  @override
  String slateSaved(String file) {
    return '$file gespeichert';
  }

  @override
  String get slateSaveDialogTitle => 'Transaktionsdatei speichern';

  @override
  String get slateOpenDialogTitle => 'Transaktionsdatei öffnen';

  @override
  String get slateNotPostedTitle => 'Noch nicht im Netzwerk';

  @override
  String get slateNotPostedBody =>
      'Die Zahlung ist abgeschlossen, aber das Netzwerk hat sie noch nicht aufgenommen. In den Zahlungsdetails lässt sie sich erneut übertragen. Senden Sie den Betrag nicht noch einmal.';

  @override
  String get slateOpenPayment => 'Zahlung öffnen';

  @override
  String get scanQrTitle => 'QR-Code scannen';

  @override
  String get scanQrHint =>
      'Richten Sie die Kamera auf den QR-Code des Empfängers.';

  @override
  String get scanQrCameraDenied =>
      'Die Wallet darf die Kamera nicht verwenden. Erlauben Sie dieser App zum Scannen den Kamerazugriff in den Einstellungen Ihres Smartphones. Sie können die Adresse auch einfügen.';

  @override
  String get scanQrCameraFailed =>
      'Die Kamera konnte nicht gestartet werden. Fügen Sie stattdessen die Adresse ein oder versuchen Sie es erneut.';

  @override
  String get scanQrTryAgain => 'Erneut versuchen';

  @override
  String get scanQrBack => 'Zurück';

  @override
  String get contactsTitle => 'Kontakte';

  @override
  String get contactsPickTitle => 'Kontakt auswählen';

  @override
  String get contactsAdd => 'Kontakt hinzufügen';

  @override
  String get contactsEmpty =>
      'Noch keine Kontakte. Fügen Sie Personen hinzu, die Sie oft bezahlen, damit Sie deren Adresse nicht jedes Mal einfügen müssen.';

  @override
  String get contactsSearchLabel => 'Kontakte durchsuchen';

  @override
  String get contactsNoMatch => 'Kein passender Kontakt.';

  @override
  String get contactsNameMissing => 'Geben Sie einen Namen ein.';

  @override
  String contactsDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get contactsDeleteBody =>
      'Die Adresse wird aus Ihren Kontakten entfernt. Frühere Zahlungen sind davon nicht betroffen.';

  @override
  String get contactsKeep => 'Behalten';

  @override
  String get contactsEditTitle => 'Kontakt bearbeiten';

  @override
  String get contactsNewTitle => 'Neuer Kontakt';

  @override
  String get contactsDeleteTooltip => 'Kontakt löschen';

  @override
  String get contactsNameLabel => 'Name';

  @override
  String get contactsAddressLabel => 'epicbox-Adresse';

  @override
  String contactsDuplicate(String name) {
    return 'Diese Adresse ist bereits als $name gespeichert.';
  }

  @override
  String get contactsNoteLabel => 'Notiz (optional)';

  @override
  String get contactsSave => 'Kontakt speichern';

  @override
  String get contactsAddressMissing => 'Geben Sie die epicbox-Adresse ein.';

  @override
  String contactsUrlIncomplete(String example) {
    return 'Geben Sie die vollständige Wallet-URL ein, z. B. $example';
  }

  @override
  String contactsAddressInvalid(String example) {
    return 'Dies ist keine gültige Adresse. Eine Adresse sieht etwa so aus: $example';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionNetwork => 'Netzwerk';

  @override
  String get settingsNetworkAndNode => 'Netzwerk und Node';

  @override
  String settingsNetworkSubtitle(String network, String node) {
    return '$network · $node';
  }

  @override
  String get settingsSectionDisplay => 'Anzeige';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Kurse anzeigen';

  @override
  String get settingsHideBalances => 'Guthaben verbergen';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'Systemeinstellung';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsPricesOnNotice =>
      'Die Kurse stammen von CoinGecko; der Dienst sieht Ihre IP-Adresse.';

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsPaymentNotifications => 'Zahlungsbenachrichtigungen';

  @override
  String get settingsPushHint => 'Zugestellt über Google Firebase.';

  @override
  String get settingsPushOnNotice =>
      'Noch sendet kein epicbox-Server solche Benachrichtigungen. Öffnen Sie die App, um eine Zahlung zu empfangen.';

  @override
  String get settingsPushOffNotice =>
      'Die Benachrichtigungen enden beim nächsten Start der App.';

  @override
  String get settingsPushBlocked =>
      'Benachrichtigungen sind in den Systemeinstellungen blockiert';

  @override
  String get settingsPushUnavailable =>
      'Benachrichtigungen sind in dieser Version nicht verfügbar';

  @override
  String get settingsSectionSecurity => 'Sicherheit';

  @override
  String get settingsChangePin => 'PIN ändern';

  @override
  String get settingsBiometrics => 'Mit Biometrie entsperren';

  @override
  String get settingsBiometricsOn => 'Biometrische Entsperrung aktiviert';

  @override
  String get settingsBiometricsOff => 'Biometrische Entsperrung deaktiviert';

  @override
  String get settingsBiometricsFailed =>
      'Biometrische Entsperrung wurde nicht eingerichtet';

  @override
  String get settingsBiometricsPinReason =>
      'Geben Sie Ihre PIN ein, um die biometrische Entsperrung zu aktivieren.';

  @override
  String get settingsAutoLock => 'Automatische Sperre';

  @override
  String get settingsBackupPhrase => 'Wiederherstellungsphrase sichern';

  @override
  String get settingsPhraseConfirmed => 'Wiederherstellungsphrase bestätigt';

  @override
  String get settingsLockWallet => 'Wallet sperren';

  @override
  String get settingsSectionHistory => 'Zahlungsverlauf';

  @override
  String get settingsExportHistory => 'Verlaufssicherung exportieren';

  @override
  String get settingsExportCsv => 'CSV exportieren';

  @override
  String get settingsImportHistory => 'Verlaufssicherung importieren';

  @override
  String get settingsSectionWallet => 'Wallet';

  @override
  String get settingsContacts => 'Kontakte';

  @override
  String get settingsSectionInvoices => 'Rechnungen';

  @override
  String get settingsInvoices =>
      'Rechnungsadresse und vertrauenswürdige Dienste';

  @override
  String get settingsInvoicesSubtitle =>
      'Vertrauenswürdige Dienste dürfen Ihnen Rechnungen schicken. Sie bestätigen jede Rechnung.';

  @override
  String get invoiceSettingsTitle => 'Rechnungen';

  @override
  String get invoiceSettingsAddressTitle => 'Ihre Rechnungsadresse';

  @override
  String get invoiceSettingsAddressBody =>
      'Geben Sie diese Adresse einem Dienst, dem Sie vertrauen, damit er Ihnen Rechnungen schicken kann. Ihre Adresse für Zahlungen bleibt dieselbe.';

  @override
  String get invoiceSettingsQrLabel => 'QR-Code Ihrer Rechnungsadresse';

  @override
  String get invoiceSettingsAddressCopied => 'Rechnungsadresse kopiert.';

  @override
  String get invoiceSettingsServicesTitle => 'Vertrauenswürdige Dienste';

  @override
  String get invoiceSettingsNoServices =>
      'Noch keine vertrauenswürdigen Dienste. Rechnungen von anderen erreichen Sie nie.';

  @override
  String get invoiceSettingsAddService => 'Dienst hinzufügen';

  @override
  String invoiceSettingsRemoveTooltip(String name) {
    return '$name entfernen';
  }

  @override
  String invoiceSettingsRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get invoiceSettingsRemoveBody =>
      'Dieser Dienst kann Ihnen dann keine Rechnungen mehr schicken. Bereits geleistete Zahlungen sind nicht betroffen.';

  @override
  String get invoiceSettingsKeep => 'Behalten';

  @override
  String get invoiceSettingsRemoveConfirm => 'Entfernen';

  @override
  String invoiceSettingsRemoved(String name) {
    return '$name kann Ihnen keine Rechnungen mehr schicken.';
  }

  @override
  String get invoiceSettingsRotate => 'Neue Rechnungsadresse erzeugen';

  @override
  String get invoiceSettingsRotateHint =>
      'Die aktuelle funktioniert dann nicht mehr.';

  @override
  String get invoiceSettingsRotateTitle => 'Neue Rechnungsadresse erzeugen?';

  @override
  String get invoiceSettingsRotateBody =>
      'Ihre aktuelle Rechnungsadresse funktioniert danach nie wieder. Jeder Dienst, der Ihnen Rechnungen schickt, braucht die neue.';

  @override
  String get invoiceSettingsRotateConfirm => 'Neue Adresse';

  @override
  String get invoiceSettingsRotated =>
      'Neue Rechnungsadresse bereit. Geben Sie sie Ihren Diensten.';

  @override
  String invoiceSettingsDropped(int count) {
    return 'In dieser Sitzung verworfen (unbekannte Absender): $count';
  }

  @override
  String get invoiceSettingsAddTitle => 'Vertrauenswürdigen Dienst hinzufügen';

  @override
  String get invoiceSettingsAddExplanation =>
      'Ein vertrauenswürdiger Dienst kann Rechnungen an Ihre Rechnungsadresse schicken; Nachrichten von anderen werden verworfen. Bezahlt wird nichts, bevor Sie jede Rechnung mit Ihrer PIN oder Ihrem Fingerabdruck bestätigen.';

  @override
  String get invoiceSettingsLabelLabel => 'Name';

  @override
  String get invoiceSettingsLabelMissing => 'Geben Sie dem Dienst einen Namen.';

  @override
  String get invoiceSettingsServiceAddressLabel =>
      'Epicbox-Adresse des Dienstes';

  @override
  String get invoiceSettingsAddressMissing =>
      'Fügen Sie die Adresse ein, die der Dienst anzeigt, oder scannen Sie sie.';

  @override
  String get invoiceSettingsAddButton => 'Dienst hinzufügen';

  @override
  String invoiceSettingsAdded(String name) {
    return '$name kann Ihnen jetzt Rechnungen schicken.';
  }

  @override
  String get settingsRescan => 'Blockchain neu scannen';

  @override
  String get settingsRescanFinished => 'Neuer Scan abgeschlossen';

  @override
  String get settingsRescanTitle => 'Blockchain neu scannen';

  @override
  String get settingsRescanBody =>
      'Die Wallet sucht erneut nach ihrem Guthaben. Ein früherer Startpunkt findet mehr, dauert aber länger; die gesamte Blockchain kann sehr lange dauern.';

  @override
  String get settingsRescanFromDate => 'Ab einem Datum';

  @override
  String get settingsRescanFromHeight => 'Ab einer Blockhöhe';

  @override
  String get settingsRescanWholeChain => 'Gesamte Blockchain';

  @override
  String get settingsRescanPickDate => 'Datum wählen';

  @override
  String get settingsRescanPickDateFirst => 'Wählen Sie zuerst ein Datum.';

  @override
  String get settingsRescanStartHeight => 'Startblock';

  @override
  String get settingsRescanHeightInvalid =>
      'Geben Sie eine Blockhöhe von 1 oder höher ein.';

  @override
  String get settingsRescanButton => 'Neu scannen';

  @override
  String get settingsDeleteWallet => 'Diese Wallet löschen';

  @override
  String get settingsDeleteDuringScan =>
      'Warten Sie, bis der Scan abgeschlossen ist, bevor Sie die Wallet löschen.';

  @override
  String get settingsDeletePinReason =>
      'Geben Sie Ihre PIN ein, um diese Wallet zu löschen.';

  @override
  String get settingsDeleteWarningIcon => 'Warnung';

  @override
  String get settingsDeleteTitle => 'Diese Wallet löschen?';

  @override
  String get settingsDeleteBody =>
      'Dadurch werden die Wallet, ihr Verlauf und ihre PIN von diesem Gerät entfernt. Nur die Wiederherstellungsphrase kann das Guthaben zurückbringen. Ohne sie ist es endgültig verloren.';

  @override
  String get settingsDeleteHavePhrase =>
      'Ich habe meine Wiederherstellungsphrase aufgeschrieben';

  @override
  String get settingsDeleteConfirmWord => 'löschen';

  @override
  String settingsDeleteTypeToConfirm(String word) {
    return '„$word“ eingeben';
  }

  @override
  String get settingsDeleteKeep => 'Wallet behalten';

  @override
  String get settingsDeleteConfirm => 'Wallet löschen';

  @override
  String get settingsSectionAbout => 'Über die App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAboutNetwork => 'Netzwerk';

  @override
  String get settingsEpicboxServer => 'epicbox-Server';

  @override
  String settingsUpdateTo(String version) {
    return 'Auf $version aktualisieren';
  }

  @override
  String get settingsUpdateInstall => 'Installieren';

  @override
  String get settingsCheckUpdates => 'Nach Updates suchen';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsSendFeedback => 'Feedback senden';

  @override
  String get settingsSendFeedbackHint =>
      'Ein Problem melden oder eine Idee vorschlagen';

  @override
  String get settingsSourceCode => 'Quellcode';

  @override
  String get settingsCopyLink => 'Link kopieren';

  @override
  String get settingsLinkCopied => 'Link kopiert';

  @override
  String get settingsPinTitle => 'PIN ändern';

  @override
  String get settingsPinEnterCurrent => 'Geben Sie Ihre aktuelle PIN ein';

  @override
  String get settingsPinCurrentLabel => 'Aktuelle PIN';

  @override
  String settingsPinChooseNew(int digits) {
    String _temp0 = intl.Intl.pluralLogic(
      digits,
      locale: localeName,
      other: 'Wählen Sie eine neue $digits-stellige PIN',
    );
    return '$_temp0';
  }

  @override
  String get settingsPinChanged => 'PIN geändert';

  @override
  String get settingsPinChangedBiometricsOff =>
      'PIN geändert. Die biometrische Entsperrung ist aus; schalten Sie sie unten wieder ein.';

  @override
  String get helpTitle => 'Hilfe';

  @override
  String get helpWaitingQuestion =>
      'Warum steht bei meiner Zahlung „Wartet auf Empfänger“?';

  @override
  String helpWaitingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'Eine Zahlung mit Epic Cash erstellen beide Wallets gemeinsam: Ihre Wallet beginnt sie, die Wallet des Empfängers nimmt sie an, dann schließt Ihre Wallet sie ab. Der epicbox-Dienst von Epic bewahrt Ihre Zahlung etwa eine Woche lang auf, bis die Wallet des Empfängers online ist und antwortet. Bis dahin bleibt der Betrag in Ihrer Wallet gesperrt, damit Sie ihn nicht doppelt ausgeben können. Wird die Zahlung nicht abgeschlossen, bricht Ihre Wallet sie nach $_temp0 automatisch ab und gibt den Betrag frei.';
  }

  @override
  String get helpCancellingQuestion => 'Sollte ich eine Zahlung abbrechen?';

  @override
  String helpCancellingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'Normalerweise müssen Sie das nicht: Eine nicht abgeschlossene Zahlung bricht sich nach $_temp0 selbst ab und gibt den Betrag frei. Um sie früher zu stoppen, etwa wenn der Empfänger sagt, dass er nie antworten wird, öffnen Sie sie, solange dort noch „Wartet auf Empfänger“ steht, und tippen Sie auf „Zahlung abbrechen“; danach müssten Sie sie erneut senden. Eine Zahlung, die bereits bestätigt wird, kann nicht abgebrochen werden. Zahlungen aus älteren Versionen dieser App brechen sich nicht selbst ab: Wartet eine davon schon länger als zwei Wochen, brechen Sie sie ab und senden Sie erneut.';
  }

  @override
  String get helpReceivingQuestion =>
      'Warum muss die App zum Empfangen geöffnet bleiben?';

  @override
  String helpReceivingAnswer(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'Ihre Wallet muss jede eingehende Zahlung annehmen, und das kann sie nur, solange die App geöffnet und mit epicbox verbunden ist. Eine Zahlung, die gesendet wird, während die App geschlossen ist, wartet etwa eine Woche in der epicbox und trifft ein, wenn Sie das nächste Mal entsperren. Danach löscht die epicbox sie; nutzt der Absender diese App, bricht seine Wallet sie nach $_temp0 automatisch ab, und er kann sie erneut senden. Sobald Ihre Wallet eine Zahlung annimmt, muss die Wallet des Absenders sie abschließen; bis dahin wird sie als „Wartet auf Absender“ angezeigt.';
  }

  @override
  String helpConfirmationsQuestion(int count) {
    return 'Was sind Bestätigungen und warum $count?';
  }

  @override
  String helpConfirmationsAnswer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bestätigungen, etwa $count Minuten',
      one: '1 Bestätigung, etwa 1 Minute',
    );
    return 'Eine Bestätigung ist ein neuer Block, der nach dem Block mit Ihrer Zahlung zur Blockchain von Epic Cash hinzukommt; etwa einmal pro Minute entsteht ein Block. Jeder Block macht es schwerer, die Zahlung rückgängig zu machen. Nach $_temp0 wird eine Zahlung als „Abgeschlossen“ angezeigt und empfangene Coins können ausgegeben werden; das ist der Standard der Epic-Wallet.';
  }

  @override
  String get helpHistoryQuestion =>
      'Warum fehlt mein Verlauf nach einer Wiederherstellung?';

  @override
  String get helpHistoryAnswer =>
      'Die Wiederherstellungsphrase bringt Ihr Guthaben zurück: Die Wallet durchsucht die Blockchain nach Coins, die ihr gehören. Wen Sie bezahlt haben, Ihre Notizen und die meisten Datumsangaben werden nie auf der Blockchain gespeichert, daher kann eine Wiederherstellung sie nicht finden. Wenn Sie eine Verlaufssicherung gespeichert haben, importieren Sie sie in den „Einstellungen“ unter „Zahlungsverlauf“ mit „Verlaufssicherung importieren“, um diese Angaben zurückzuholen. Die Sicherung muss eine Kopie sein, die Sie außerhalb des verlorenen Smartphones aufbewahrt haben, zum Beispiel per E-Mail oder in einem Cloud-Speicher.';

  @override
  String get helpAddressQuestion => 'Ändert sich meine Adresse jemals?';

  @override
  String get helpAddressAnswer =>
      'Ihre Adresse entsteht aus Ihrer Wiederherstellungsphrase und dem epicbox-Server, den Sie nutzen, und endet auf @ und dem Namen dieses Servers. Sie bleibt gleich, solange Sie denselben epicbox-Server behalten. Wählen Sie in den Netzwerkeinstellungen einen anderen, ändert sich Ihre Adresse; geben Sie die neue dann an alle weiter, die Sie bezahlen.';

  @override
  String get helpPhraseQuestion =>
      'Was ist die Wiederherstellungsphrase und wer kann sie sehen?';

  @override
  String get helpPhraseAnswer =>
      'Die Wiederherstellungsphrase ist eine Liste von Wörtern, die den Schlüssel zu Ihrem Geld bildet: Wer sie hat, kann Ihre Coins an sich nehmen, und mit ihr können Sie Ihre Wallet auf einem neuen Smartphone wiederherstellen. Die App zeigt sie nur nach Eingabe Ihrer PIN an und sendet sie nirgendwohin. Schreiben Sie sie auf Papier, bewahren Sie sie an einem sicheren Ort auf und geben Sie sie niemals weiter oder auf einer Website ein.';

  @override
  String get helpFeesQuestion => 'Wofür ist die Gebühr?';

  @override
  String get helpFeesAnswer =>
      'Die Gebühr geht an die Miner, die Ihre Zahlung zur Blockchain hinzufügen. Sie beträgt meist nur einen kleinen Bruchteil eines EPIC und hängt davon ab, wie viele Coins Ihre Wallet für die Zahlung zusammenführt. Die genaue Gebühr sehen Sie vor dem Senden.';

  @override
  String get helpNodeQuestion => 'Was ist ein Node?';

  @override
  String get helpNodeAnswer =>
      'Ein Node ist ein Computer, der eine Kopie der Blockchain von Epic Cash vorhält. Die Wallet fragt einen Node nach Ihrem Guthaben und sendet Ihre Zahlungen über ihn ins Netzwerk. Der Node sieht Ihre IP-Adresse und nach welchen Coins die Wallet fragt; wählen Sie daher in den Netzwerkeinstellungen einen, dem Sie vertrauen. Die Netzwerkeinstellungen finden Sie in den Einstellungen, sobald „Erweiterte Optionen“ eingeschaltet ist, und auf dem Entsperrbildschirm.';

  @override
  String get helpOtherWaysQuestion => 'Gibt es andere Möglichkeiten zu senden?';

  @override
  String get helpOtherWaysAnswer =>
      'Für fortgeschrittene Nutzer. Ohne epicbox nutzen Sie „Per Transaktionsdatei senden“ unter „Weitere Sendeoptionen“: Sie teilen eine Datei, der Empfänger nimmt sie an und schickt eine .response-Datei zurück, und Sie öffnen diese Datei, um die Zahlung abzuschließen. „Weitere Sendeoptionen“ erscheint, sobald Sie in den Einstellungen „Erweiterte Optionen“ einschalten.';

  @override
  String get helpStillStuck => 'Kommen Sie nicht weiter?';

  @override
  String get helpTellUs =>
      'Schreiben Sie uns, was passiert ist oder was unklar ist.';

  @override
  String get helpSendFeedback => 'Feedback senden';

  @override
  String get feedbackTitle => 'Feedback senden';

  @override
  String get feedbackIntro =>
      'Schreiben Sie uns, was schiefgelaufen ist oder was besser sein könnte.';

  @override
  String get feedbackMessageLabel => 'Ihre Nachricht';

  @override
  String get feedbackMessageMissing =>
      'Beschreiben Sie in ein paar Worten, was passiert ist.';

  @override
  String get feedbackEmailLabel => 'E-Mail für eine Antwort (optional)';

  @override
  String get feedbackEmailInvalid =>
      'Das sieht nicht nach einer E-Mail-Adresse aus.';

  @override
  String get feedbackAttachLogs => 'Diagnoseprotokolle anhängen';

  @override
  String get feedbackAttachLogsHint =>
      'Hilft uns, das Problem zu finden. Ihre Wiederherstellungsphrase, PIN und andere Geheimnisse werden vorher entfernt.';

  @override
  String get feedbackPreviewButton => 'Vorschau der gesendeten Daten';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackShareOrSaveInstead => 'Stattdessen teilen oder speichern';

  @override
  String get feedbackFileExplanation =>
      'Ihr Feedback wird zu einer Textdatei, die Sie per E-Mail oder Chat senden oder speichern können.';

  @override
  String get feedbackShareOrSave => 'Teilen oder speichern';

  @override
  String get feedbackShareHint => 'Per E-Mail oder Chat-App senden';

  @override
  String get feedbackSaveToDevice => 'Auf dem Gerät speichern';

  @override
  String get feedbackSaveDialogTitle => 'Feedback speichern';

  @override
  String feedbackSavedFile(String name) {
    return '$name gespeichert';
  }

  @override
  String get feedbackSent => 'Vielen Dank. Ihr Feedback wurde gesendet.';

  @override
  String get feedbackThanks => 'Vielen Dank für Ihr Feedback.';

  @override
  String feedbackServerAnswered(int status) {
    return 'Der Feedback-Server hat mit $status geantwortet.';
  }

  @override
  String get feedbackServerNoAnswer =>
      'Der Feedback-Server hat nicht geantwortet.';

  @override
  String get feedbackServerUnreachable =>
      'Der Feedback-Server ist nicht erreichbar.';

  @override
  String get feedbackPreviewTitle => 'Was gesendet wird';

  @override
  String get settingsAdvancedOptions => 'Erweiterte Optionen';

  @override
  String get settingsAdvancedOptionsSubtitle =>
      'Netzwerk, Node, epicbox-Server, Dateien und Protokolle';

  @override
  String get txStepStarted => 'Zahlung gestartet';

  @override
  String get txStepAccepted => 'Empfänger hat angenommen';

  @override
  String get txStepPosted => 'An das Netzwerk gesendet';

  @override
  String get txStepConfirming => 'Bestätigung';

  @override
  String get txStepConfirmed => 'Bestätigt';

  @override
  String get txStepArrived => 'Zahlung eingegangen';

  @override
  String get txStepSenderFinished => 'Absender hat abgeschlossen';

  @override
  String get fileHelpTitle => 'So funktioniert eine Zahlungsdatei';

  @override
  String get fileHelpYou => 'Du';

  @override
  String get fileHelpFriend => 'Freund';

  @override
  String get fileHelpSendStep1 => 'Du erstellst eine Zahlungsdatei.';

  @override
  String get fileHelpSendStep2 =>
      'Du schickst sie deinem Freund, wie du möchtest, etwa per Chat oder E-Mail.';

  @override
  String get fileHelpSendStep3 =>
      'Dein Freund öffnet sie in seiner Wallet und schickt dir die unterschriebene Antwort zurück.';

  @override
  String get fileHelpSendStep4 =>
      'Du öffnest die Antwort, und die Zahlung ist unterwegs.';

  @override
  String get fileHelpReceiveStep1 =>
      'Dein Freund erstellt eine Zahlungsdatei für dich.';

  @override
  String get fileHelpReceiveStep2 =>
      'Er schickt sie dir, wie er möchte, etwa per Chat oder E-Mail.';

  @override
  String get fileHelpReceiveStep3 =>
      'Du öffnest sie in deiner Wallet und schickst die unterschriebene Antwort zurück.';

  @override
  String get fileHelpReceiveStep4 =>
      'Dein Freund öffnet die Antwort, und die Zahlung ist auf dem Weg zu dir.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Schritt $step von $count';
  }

  @override
  String get fileHelpPause => 'Animation anhalten';

  @override
  String get fileHelpPlay => 'Animation abspielen';

  @override
  String get demoPinFilled => 'Demo-PIN, für Sie ausgefüllt';

  @override
  String get demoPinOwnInApp => 'In der App wählen Sie Ihre eigene PIN.';

  @override
  String get demoPinSkip => 'Überspringen';

  @override
  String get demoPinSetUpTitle => 'Ihre Demo-Wallet wird eingerichtet';

  @override
  String get demoPinUnlockTitle => 'Ihre Demo-Wallet wird geöffnet';

  @override
  String get sendStepRecipient => 'Empfänger';

  @override
  String get sendStepAmount => 'Betrag';

  @override
  String get sendStepReview => 'Prüfen';

  @override
  String sendStepOf(int step, int total) {
    return '$step von $total';
  }

  @override
  String get sendHowItWorks => 'So funktioniert es';

  @override
  String get sendAddressLabel => 'Epic-Adresse';

  @override
  String get sendAddressMissing => 'Geben Sie die Adresse der Gegenseite ein.';

  @override
  String get sendAddressWebLink => 'Das ist ein Weblink, keine Epic-Adresse.';

  @override
  String get sendAddressIncomplete => 'Diese Adresse scheint unvollständig.';

  @override
  String get sendAddressNotEpic => 'Das ist keine Epic-Adresse.';

  @override
  String get sendNewRecipient => 'Neuer Empfänger';

  @override
  String get sendSaveContact => 'Als Kontakt speichern';

  @override
  String get sendRecent => 'Zuletzt';

  @override
  String get sendUseFile => 'Keine Adresse? Mit Zahlungsdatei zahlen';

  @override
  String sendTo(String who) {
    return 'An $who';
  }

  @override
  String sendAvailable(String amount) {
    return 'Verfügbar $amount';
  }

  @override
  String sendOnHold(String amount) {
    return '$amount sind bis zur Bestätigung zurückgehalten.';
  }

  @override
  String sendFeeQuiet(String fee) {
    return 'Netzwerkgebühr $fee';
  }

  @override
  String get sendAddNote => 'Notiz hinzufügen';

  @override
  String get sendNoteLabel => 'Notiz';

  @override
  String get sendNoteHelper => 'Der Empfänger sieht sie auch.';

  @override
  String get sendNetworkFee => 'Netzwerkgebühr';

  @override
  String get sendChecking => 'Wird geprüft…';

  @override
  String get sendReady => 'Bereit zum Senden';

  @override
  String get sendNodeDown => 'Das Netzwerk ist gerade nicht erreichbar.';

  @override
  String get sendRelayDown => 'Das Relay der Gegenseite antwortet nicht.';

  @override
  String get sendListenerDown =>
      'Noch nicht verbunden. Sie können trotzdem senden.';

  @override
  String get sendPayWithFile => 'Stattdessen mit Datei zahlen';

  @override
  String get sendAnyway => 'Trotzdem senden';

  @override
  String sendTrackSentTo(String name) {
    return 'An $name gesendet';
  }

  @override
  String get sendTrackSent => 'Gesendet';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Warten auf die Wallet von $name';
  }

  @override
  String get sendTrackWaiting => 'Warten auf die Wallet der Gegenseite';

  @override
  String sendTrackSignedBy(String name) {
    return 'Wallet von $name hat signiert';
  }

  @override
  String get sendTrackSigned => 'Die Wallet der Gegenseite hat signiert';

  @override
  String get sendTrackOnNetwork => 'An das Netzwerk gesendet';

  @override
  String get sendTrackConfirmed => 'Bestätigt';

  @override
  String sendTrackOffline(String amount) {
    return 'Die Wallet der Gegenseite schließt sie ab, sobald sie geöffnet wird. Bis dahin bleiben $amount zurückgehalten.';
  }

  @override
  String get sendTrackIfNot => 'Was, wenn sie nie abgeschlossen wird?';

  @override
  String get sendTrackCancelled => 'Diese Zahlung wurde storniert.';

  @override
  String get sendNoCoins => 'Noch keine Coins zum Senden.';

  @override
  String get sendFileTitle => 'Mit Datei zahlen';

  @override
  String get sendMakeFile => 'Zahlungsdatei erstellen';

  @override
  String get sendFileMade => 'Datei erstellt';

  @override
  String sendFileOnHold(String amount) {
    return '$amount zurückgehalten';
  }

  @override
  String get sendFileWaitingReply => 'Warten auf die Antwort';

  @override
  String get sendFileShareHint =>
      'Senden Sie diese Datei an die Gegenseite. Öffnen Sie dann die Antwort.';

  @override
  String get sendOpenReply => 'Antwort öffnen';

  @override
  String get handshakePayment => 'Zahlung';

  @override
  String get handshakeRequest => 'Anforderung';

  @override
  String get handshakeYou => 'Sie';

  @override
  String get handshakeThem => 'Gegenseite';

  @override
  String get handshakeNetwork => 'Netzwerk';

  @override
  String get handshakePay1 =>
      'Ihre Wallet sendet der Gegenseite die Zahlung. Ihre Coins werden zurückgehalten.';

  @override
  String get handshakePay2 =>
      'Die Wallet der Gegenseite ergänzt ihren Teil, signiert und schickt sie zurück.';

  @override
  String get handshakeFinish =>
      'Ihre Wallet schließt sie ab und sendet sie an das Netzwerk.';

  @override
  String get handshakeConfirm => 'Das Netzwerk bestätigt sie.';

  @override
  String get handshakeReq1 =>
      'Ihre Wallet sendet der Gegenseite die Anforderung.';

  @override
  String get handshakeReq2 =>
      'Die Wallet der Gegenseite fügt die Coins hinzu, signiert und schickt sie zurück.';

  @override
  String get handshakePrevious => 'Vorheriger Schritt';

  @override
  String get handshakeNext => 'Nächster Schritt';
}
