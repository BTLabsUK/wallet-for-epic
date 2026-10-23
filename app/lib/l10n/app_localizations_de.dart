// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Epic Cash Mobile';

  @override
  String get appTitleDesktop => 'Epic Cash Desktop';

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
  String get errorTorNotRunning => 'Tor ist nicht verbunden.';

  @override
  String get errorOnionUnreachable =>
      'Die Wallet der Gegenseite war über Tor nicht erreichbar.';

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
  String get shellTitle => 'Epic Cash Mobile';

  @override
  String get demoWelcomeTitle => 'Epic Cash ausprobieren';

  @override
  String get demoWelcomeLine =>
      'Eine echte Wallet mit kostenlosen Test-Coins ohne Wert. Sie wird nach 24 Stunden gelöscht.';

  @override
  String get demoStart => 'Demo starten';

  @override
  String get demoEndedTitle => 'Ihre Demo ist beendet';

  @override
  String get demoEndedBody => 'Ihre Wallet und die Test-Coins wurden gelöscht.';

  @override
  String get demoStartAgain => 'Neu starten';

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
  String get homeBalanceNotOnChain => 'Noch nicht in der Blockchain';

  @override
  String get balanceNotOnChainHelp =>
      'Zahlungen an Sie, die der Absender noch nicht abgeschlossen hat oder die noch in keinem Block sind, und Wechselgeld Ihrer Sendungen. Sie zählen erst, wenn sie in einem Block sind: Eine nur angebotene Zahlung kommt vielleicht nie an.';

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
  String get balanceLineAllConfirmed => 'Alles bestätigt';

  @override
  String get balanceLineNothingYet => 'Noch nichts da';

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
  String get receiveAddressLabel => 'Epicbox-Adresse';

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
  String get updateNoInformation => 'Keine Update-Informationen verfügbar.';

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
  String get updateNeedsReinstall =>
      'Dieses Update ist mit einem neuen Schlüssel signiert und kann diese Version nicht ersetzen. Eine Neuinstallation ist nötig, und beim Deinstallieren wird diese Wallet vom Gerät entfernt: Schreiben Sie zuerst Ihre Wiederherstellungsphrase auf, deinstallieren Sie dann diese App und installieren Sie die neue Version.';

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
  String get setupTitle => 'Node und Epicbox';

  @override
  String get setupNetworkSettingsTooltip => 'Node und Epicbox';

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
      'Alle Wörter (12 bis 24), durch Leerzeichen getrennt.';

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
      'Ein Screenshot oder Foto der Phrase ist eine vollständige Kopie Ihrer Wallet: Wer ihn sieht, kann Ihr Guthaben nehmen, und Foto-Apps laden ihn unter Umständen in die Cloud hoch. Papier ist am sichersten.';

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
  String get unlockStranded =>
      'Diese Wallet konnte nicht wie erwartet gelesen werden. Es wurde nichts gelöscht. Versuchen Sie es nach einem Neustart des Geräts erneut. Bleibt es dabei, können Sie die Wallet über „PIN vergessen?“ entfernen und mit ihrer Wiederherstellungsphrase wiederherstellen.';

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
  String get sendMethodEpicbox => 'Epicbox-Adresse';

  @override
  String get sendMethodFile => 'Zahlungsdatei';

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
  String sendMessageCounter(int used, int limit) {
    return '$used/$limit';
  }

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
  String get sendHelp => 'Hilfe';

  @override
  String get sendReviewTotal => 'Gesamt';

  @override
  String sendReviewTotalWithFiat(String amount, String fiat) {
    return '$amount (≈ $fiat)';
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
  String get contactsAddressLabel => 'Adresse';

  @override
  String contactsDuplicate(String name) {
    return 'Diese Adresse ist bereits als $name gespeichert.';
  }

  @override
  String get contactsNoteLabel => 'Notiz (optional)';

  @override
  String get contactsSave => 'Kontakt speichern';

  @override
  String get contactsAddressMissing => 'Geben Sie die Adresse ein.';

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
  String get settingsSectionNetwork => 'Server';

  @override
  String get settingsNetworkAndNode => 'Node und Epicbox';

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
  String get settingsLicences => 'Lizenzen';

  @override
  String get licencesLead =>
      'Open-Source-Software in dieser Wallet. Jede Komponente behält ihre eigene Lizenz; die vollständigen Texte sind einen Tipp entfernt.';

  @override
  String get licencesApp =>
      'Epic Cash Mobile von BT Labs: Apache-2.0. Der Code ist auf GitHub.';

  @override
  String get licencesFlutter =>
      'Flutter und seine Dart-Pakete: BSD 3-Clause und ähnliche freizügige Lizenzen.';

  @override
  String get licencesLepic =>
      'LEPIC, die Epic-Cash-Wallet-Bibliothek: Apache 2.0, mit dem secp256k1-zkp-Fork von Epic Cash (CC0) und Rust-Crates unter MIT oder Apache 2.0, darunter tokio, rustls, rusqlite und blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, Version 3. Die Quelle steht unten.';

  @override
  String get licencesFonts =>
      'Schriften Montserrat und JetBrains Mono: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'Alle Lizenztexte';

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
  String get helpStillStuck => 'Kommen Sie nicht weiter?';

  @override
  String get helpTellUs =>
      'Beschreiben Sie, was passiert ist oder was unklar ist.';

  @override
  String get helpSendFeedback => 'Feedback senden';

  @override
  String get feedbackTitle => 'Feedback senden';

  @override
  String get feedbackIntro =>
      'Beschreiben Sie, was schiefgelaufen ist oder was besser sein könnte.';

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
      'Protokolle helfen, das Problem zu finden. Wiederherstellungsphrase, PIN und andere Geheimnisse werden vorher entfernt.';

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
      'Technische Details, Dateien und Protokolle';

  @override
  String get settingsSectionPrivacy => 'Datenschutz';

  @override
  String get settingsSectionPrivacyNetwork => 'Datenschutz & Netzwerk';

  @override
  String get settingsSectionHelpFeedback => 'Hilfe & Feedback';

  @override
  String get settingsStateBackUp => 'Wiederherstellungsphrase sichern';

  @override
  String get settingsStatePin => 'PIN';

  @override
  String get settingsStatePinBiometrics => 'PIN und Biometrie';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String get settingsUseStatusSite => 'status.btlabs.uk nutzen';

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Netzwerkstatus und Informationen von status.btlabs.uk';

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
  String get sendAddressNotEpic => 'Das ist keine Epicbox-Adresse.';

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
      'Ihre Wallet sendet die Zahlung an das Relay. Ihre Coins werden zurückgehalten.';

  @override
  String get handshakePay2 =>
      'Das Relay leitet sie weiter. Die Wallet der Gegenseite ergänzt ihren Teil und signiert.';

  @override
  String get handshakeFinish =>
      'Ihre Wallet schließt sie ab und sendet sie an das Netzwerk.';

  @override
  String get handshakeConfirm => 'Das Netzwerk bestätigt sie.';

  @override
  String get handshakeReq1 =>
      'Ihre Wallet sendet die Anforderung an das Relay.';

  @override
  String get handshakeReq2 =>
      'Das Relay leitet sie weiter. Die Gegenseite stimmt zu, ihre Wallet fügt die Coins hinzu und signiert.';

  @override
  String get handshakeRelay => 'Relay';

  @override
  String get handshakeFile => 'Datei';

  @override
  String get handshakeBack =>
      'Die Wallet der Gegenseite schickt sie an das Relay zurück.';

  @override
  String get handshakeRelayBack => 'Das Relay gibt sie an Ihre Wallet zurück.';

  @override
  String get handshakeFile1 =>
      'Ihre Wallet speichert eine Zahlungsdatei. Sie senden sie selbst an die Gegenseite.';

  @override
  String get handshakeFile2 =>
      'Die Gegenseite öffnet sie. Ihre Wallet ergänzt ihren Teil, signiert und speichert eine Antwort.';

  @override
  String get handshakeFile3 =>
      'Die Gegenseite schickt Ihnen die Antwortdatei zurück.';

  @override
  String get handshakeFile4 => 'Sie öffnen die Antwort in Ihrer Wallet.';

  @override
  String get handshakePrevious => 'Vorheriger Schritt';

  @override
  String get handshakeNext => 'Nächster Schritt';

  @override
  String sendRelayRefused(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Das Relay der Gegenseite hat sie nicht angenommen. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens $days Tage.',
      one: 'Das Relay der Gegenseite hat sie nicht angenommen. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost =>
      'Das Relay der Gegenseite hat sie nicht angenommen. Prüfen Sie die Wallet, bevor Sie erneut senden.';

  @override
  String get sendCancelAndFile => 'Stornieren und mit Datei zahlen';

  @override
  String get sendLeaveIt => 'Vorerst so lassen';

  @override
  String get sendSending => 'Wird gesendet…';

  @override
  String trackStepDone(String step) {
    return '$step, erledigt';
  }

  @override
  String trackStepNow(String step) {
    return '$step, jetzt';
  }

  @override
  String trackStepLater(String step) {
    return '$step, später';
  }

  @override
  String balanceLineOnHold(String amount) {
    return '$amount zurückgehalten';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount unterwegs';
  }

  @override
  String get demoTestCoinsPill => 'Test-Coins';

  @override
  String get demoTestCoinsPillTip =>
      'Floonet, das Testnetz von Epic. Die Coins haben keinen Wert.';

  @override
  String demoLeftHours(int hours) {
    return 'noch $hours h';
  }

  @override
  String demoLeftMinutes(int minutes) {
    return 'noch $minutes Min.';
  }

  @override
  String get demoReceiveKeepOpen =>
      'Lassen Sie diesen Tab offen, um zu empfangen.';

  @override
  String get demoGuideTitle => 'Eine Zahlung ausprobieren';

  @override
  String get demoGuideSend => 'Jemandem etwas senden';

  @override
  String get demoGuideSendHint =>
      'Bezahlen Sie die Demo eines Freundes, oder öffnen Sie diese Seite in einem anderen Browser oder einem privaten Fenster.';

  @override
  String get demoGuideOpenSend => 'Zu Senden';

  @override
  String get demoGuideAsking =>
      'Der Test-Faucet wird gefragt. Das kann eine Minute dauern.';

  @override
  String get demoGuideDone =>
      'Beides erledigt. Sehen Sie sich um, solange die Demo läuft.';

  @override
  String get demoGuideHide => 'Ausblenden';

  @override
  String get demoGuideHideLabel => 'Demo-Schritte ausblenden';

  @override
  String demoGuideStepDone(String step) {
    return '$step, erledigt';
  }

  @override
  String demoGuideStepToDo(String step) {
    return '$step, noch offen';
  }

  @override
  String get receiveTabEpicbox => 'Epicbox';

  @override
  String get receiveTabTor => 'Tor';

  @override
  String get receiveTabFile => 'Datei';

  @override
  String get receiveTorAddressLabel => 'Tor-Adresse';

  @override
  String get receiveTorQrLabel => 'QR-Code Ihrer Tor-Adresse';

  @override
  String get torReceivingTitle => 'Empfang über Tor';

  @override
  String get torHonestLine =>
      'Tor-Empfang funktioniert, solange die App geöffnet oder kurz im Hintergrund ist.';

  @override
  String get torStateOff => 'Empfang über Tor ist aus';

  @override
  String torStateStarting(int percent) {
    return 'Verbindung mit Tor… $percent %';
  }

  @override
  String get torStatePublishing => 'Ihre Tor-Adresse wird veröffentlicht…';

  @override
  String get torStateReady => 'Empfang über Tor ist an';

  @override
  String torStateNotReachable(String reason) {
    return 'Ihre Tor-Adresse ist noch nicht erreichbar. $reason';
  }

  @override
  String get torFailureMissing => 'Tor ist in dieser App nicht enthalten.';

  @override
  String get torFailureStart => 'Tor ist nicht gestartet.';

  @override
  String get torFailureNetwork =>
      'Das Tor-Netzwerk ist nicht erreichbar. Prüfen Sie die Verbindung.';

  @override
  String get torFailureClock =>
      'Die Uhr des Telefons geht falsch. Tor braucht die richtige Zeit.';

  @override
  String get torFailureListener =>
      'Die Wallet konnte ihre Tor-Adresse nicht öffnen.';

  @override
  String get torFailureStopped => 'Tor wurde beendet.';

  @override
  String get torFailurePublish =>
      'Die Tor-Adresse konnte nicht veröffentlicht werden.';

  @override
  String get torFailureKeys =>
      'Tor hat den Adressschlüssel der Wallet nicht angenommen.';

  @override
  String get sendOnionIncomplete =>
      'Das ist keine vollständige Tor-Adresse. Kopieren Sie sie erneut vom Empfänger.';

  @override
  String get sendTorUnavailable =>
      'Diese App kann nicht über Tor senden, daher lässt sich eine Tor-Adresse hier nicht bezahlen.';

  @override
  String get sendOverTor => 'Über Tor';

  @override
  String get sendTorConnectsOnSend => 'Tor verbindet sich beim Senden.';

  @override
  String get sendTorReady => 'Bereit zum Senden über Tor';

  @override
  String get sendTorReaching =>
      'Die Wallet der Gegenseite wird über Tor erreicht… Das kann dauern. Lassen Sie die App offen.';

  @override
  String sendTorNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Die Wallet der Gegenseite war über Tor nicht erreichbar. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens $days Tage.',
      one: 'Die Wallet der Gegenseite war über Tor nicht erreichbar. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Es wurde nichts gesendet.';
  }

  @override
  String get sendTryAgain => 'Erneut versuchen';

  @override
  String get sendCancelPayment => 'Zahlung stornieren';

  @override
  String get settingsSectionReceiving => 'Empfangen';

  @override
  String get homeAvailableToSpend => 'Verfügbar';

  @override
  String get homeTileWaitingSender => 'Wartet auf Absender';

  @override
  String get homeTileLocked => 'In Sendungen gesperrt';

  @override
  String get homeTileMaturing => 'Belohnungen reifen';

  @override
  String get homeTileTotal => 'Gesamt';

  @override
  String homeViewAll(int count) {
    return 'Alle $count anzeigen';
  }

  @override
  String get homeDestActivity => 'Aktivität';

  @override
  String get homeDestOutputs => 'Outputs';

  @override
  String get txStatusReceived => 'Empfangen';

  @override
  String get txStatusSent => 'Gesendet';

  @override
  String sendPinReason(String amount) {
    return 'PIN eingeben, um $amount zu senden.';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'PIN eingeben, um eine Zahlungsdatei über $amount zu erstellen.';
  }

  @override
  String get outputsTitle => 'Outputs';

  @override
  String get outputsSpendable => 'Verfügbar';

  @override
  String get outputsConfirming => 'Wird bestätigt';

  @override
  String get outputsLockedTile => 'In Sendungen gesperrt';

  @override
  String get outputsImmature => 'Noch nicht reif';

  @override
  String outputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs',
      one: '1 Output',
    );
    return '$_temp0';
  }

  @override
  String get outputsSplitButton => 'Teilen…';

  @override
  String get outputsConsolidateButton => 'Zusammenführen…';

  @override
  String get outputsSplitNeeds => 'Teilen braucht mindestens 1 EPIC verfügbar.';

  @override
  String get outputsConsolidateNeeds =>
      'Zusammenführen braucht mindestens 2 verfügbare Outputs.';

  @override
  String get outputsWaitLocked =>
      'Warten, bis die laufende Zahlung bestätigt ist (etwa 3 Blöcke).';

  @override
  String get outputsStrategy => 'Strategie für Zahlungen';

  @override
  String get outputsSmallest => 'Kleinste';

  @override
  String get outputsAll => 'Alle';

  @override
  String get outputsSmallestText =>
      'Verbraucht möglichst wenige kleine Outputs; der Rest bleibt verfügbar, bis das Wechselgeld bestätigt ist.';

  @override
  String get outputsAllText =>
      'Verbraucht jeden verfügbaren Output und gibt einen Wechselgeld-Output zurück. Alles ist gesperrt, bis er bestätigt ist; danach weniger, größere Outputs.';

  @override
  String get outputsSplitChange => 'Wechselgeld teilen';

  @override
  String get outputsSplitChangeText => 'Wenn nur wenige Outputs übrig blieben';

  @override
  String outputsFilterAll(int count) {
    return 'Alle $count';
  }

  @override
  String outputsFilterSpendable(int count) {
    return 'Verfügbar $count';
  }

  @override
  String outputsFilterConfirming(int count) {
    return 'Bestätigung $count';
  }

  @override
  String outputsFilterLocked(int count) {
    return 'Gesperrt $count';
  }

  @override
  String get outputsShowSpent => 'Ausgegebene zeigen';

  @override
  String get outputsHideSpent => 'Ausgegebene ausblenden';

  @override
  String get outputsWordSpendable => 'Verfügbar';

  @override
  String get outputsWordConfirming => 'Wird bestätigt';

  @override
  String get outputsWordFinalizing => 'Wartet auf Abschluss';

  @override
  String get outputsWordImmature => 'Noch nicht reif';

  @override
  String get outputsWordMining => 'Mining';

  @override
  String get outputsWordLocked => 'Gesperrt';

  @override
  String get outputsWordSpent => 'Ausgegeben';

  @override
  String get outputsMeanSpendable => 'Kann jetzt ausgegeben werden.';

  @override
  String outputsMeanConfirming(int need) {
    return 'Braucht $need Bestätigungen, bevor er ausgegeben werden kann.';
  }

  @override
  String get outputsMeanFinalizing =>
      'Wartet darauf, dass der Absender die Zahlung abschließt.';

  @override
  String get outputsMeanImmature =>
      'Eine Mining-Belohnung. Sie kann nach einer Wartezeit ausgegeben werden.';

  @override
  String get outputsMeanMining =>
      'Eine Mining-Belohnung, noch nicht bestätigt.';

  @override
  String get outputsMeanLocked =>
      'Wird von einer laufenden Zahlung ausgegeben.';

  @override
  String get outputsMeanSpent => 'Bereits ausgegeben.';

  @override
  String outputsNoteReceived(String date) {
    return 'Empfangen $date';
  }

  @override
  String outputsNoteSend(String who) {
    return 'Zahlung an $who';
  }

  @override
  String get outputsNoteSendPlain => 'Zahlung läuft';

  @override
  String get outputsFactHeight => 'Höhe';

  @override
  String get outputsFactConfirmations => 'Bestätigungen';

  @override
  String get outputsFactTransaction => 'Transaktion';

  @override
  String get outputsFactCommitment => 'Commitment';

  @override
  String get outputsCopy => 'Kopieren';

  @override
  String get outputsCopied => 'Commitment kopiert';

  @override
  String get outputsEmpty => 'Noch keine Outputs';

  @override
  String get outputsEmptyHint =>
      'Die erste empfangene Zahlung erzeugt einen. Unter Empfangen steht die Adresse.';

  @override
  String get outputsNoMatch => 'Keine Outputs in dieser Ansicht';

  @override
  String get outputsRetry => 'Erneut versuchen';

  @override
  String outputsSettingsSubtitle(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs · $strategy',
      one: '1 Output · $strategy',
    );
    return '$_temp0';
  }

  @override
  String get outputsCancel => 'Abbrechen';

  @override
  String get outputsSplitTitle => 'Outputs teilen';

  @override
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  ) {
    return 'Verbraucht $spent ($amount) und erzeugt $made zu je etwa $each. Eine normale Netzwerktransaktion an dieses Wallet, nach 3 Blöcken bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt.';
  }

  @override
  String get outputsToMake => 'Zu erzeugende Outputs';

  @override
  String get outputsStepperHint => '2 bis 10';

  @override
  String get outputsFactFee => 'Netzwerkgebühr';

  @override
  String get outputsFactEach => 'Jeder Output';

  @override
  String outputsFactAbout(String amount) {
    return 'etwa $amount';
  }

  @override
  String get outputsFactLocked => 'Gesperrt';

  @override
  String outputsFactLockedValue(String amount) {
    return '$amount, etwa 3 Blöcke';
  }

  @override
  String get outputsNothingSpendable =>
      'Währenddessen bleibt nichts verfügbar.';

  @override
  String get outputsMinEach =>
      'Jeder Output muss mindestens 0,5 EPIC betragen.';

  @override
  String outputsSplitInto(int count) {
    return 'In $count teilen';
  }

  @override
  String get outputsConsolidateTitle => 'Outputs zusammenführen';

  @override
  String outputsConsolidateText(String amount, String result, String spent) {
    return 'Verbraucht $spent ($amount) und erzeugt einen Output über $result. Eine normale Netzwerktransaktion an dieses Wallet, nach 3 Blöcken bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt. Die nächste Zahlung verbraucht einen Output, daher ist ihre Gebühr am kleinsten.';
  }

  @override
  String get outputsConsolidateAction => 'Zusammenführen';

  @override
  String get outputsSplitPin => 'Mit der PIN bestätigen, um Outputs zu teilen';

  @override
  String get outputsConsolidatePin =>
      'Mit der PIN bestätigen, um Outputs zusammenzuführen';

  @override
  String outputsSplitStarted(int count) {
    return 'Teilen gestartet: $count Outputs, Bestätigung in etwa 3 Blöcken';
  }

  @override
  String get outputsConsolidateStarted =>
      'Zusammenführen gestartet: ein Output, Bestätigung in etwa 3 Blöcken';

  @override
  String get outputsAdvanced => 'Erweitert';

  @override
  String get outputsColState => 'Status';

  @override
  String get outputsColValue => 'Wert';

  @override
  String get outputsColConfirmations => 'Bestätigungen';

  @override
  String homePendingShort(String amount) {
    return '$amount bleiben gesperrt, bis die Wallet des Empfängers antwortet.';
  }

  @override
  String get contactsSearchHint => 'Name oder Adresse';

  @override
  String get contactsEmptyTitle => 'Noch keine Kontakte';

  @override
  String get contactsEmptyCaption =>
      'Ein Kontakt ist ein Name für eine Adresse.';

  @override
  String contactsNoMatchQuery(String query) {
    return 'Kein Kontakt passt zu „$query“';
  }

  @override
  String get contactsSendAction => 'Senden';

  @override
  String get contactsEditAction => 'Bearbeiten';

  @override
  String get contactsAddressHeading => 'Adresse';

  @override
  String get contactsNoteHeading => 'Notiz';

  @override
  String get contactsShowCode => 'Code zeigen';

  @override
  String get contactsHideCode => 'Code ausblenden';

  @override
  String contactsQrLabel(String name) {
    return 'QR-Code der Adresse von $name';
  }

  @override
  String get contactsDeleteConfirmBody =>
      'Zahlungen an diese Adresse zeigen danach die Adresse statt des Namens.';

  @override
  String contactsDeleted(String name) {
    return '$name gelöscht.';
  }

  @override
  String get contactsCopied => 'Adresse kopiert.';

  @override
  String get invoicesNewRequest => 'Neue Anforderung';

  @override
  String get invoicesSegmentSent => 'Gesendet';

  @override
  String invoicesSegmentCount(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'keine',
    );
    return '$label, $_temp0';
  }

  @override
  String get invoicesToPayEmpty => 'Keine Rechnungen zu zahlen';

  @override
  String get invoicesToPayEmptyCaption =>
      'Dienste auf Ihrer Vertrauensliste können dieser Wallet Rechnungen stellen. Jede Rechnung wartet hier auf Ihre Freigabe.';

  @override
  String get invoicesSentEmpty => 'Keine Anforderungen gesendet';

  @override
  String get invoicesSentEmptyCaption =>
      'Eine Anforderung bittet jemanden, Ihnen einen Betrag zu zahlen.';

  @override
  String get invoicesWaitingPayment => 'Wartet auf Zahlung';

  @override
  String get invoicesExpires => 'Läuft ab';

  @override
  String invoicesUntil(String time) {
    return 'bis $time';
  }

  @override
  String get invoicesMessage => 'Nachricht';

  @override
  String get invoicesFrom => 'Von';

  @override
  String get invoicesPaysFrom => 'Zahlt aus';

  @override
  String invoicesAvailable(String amount) {
    return 'Verfügbar $amount';
  }

  @override
  String invoicesShort(String amount) {
    return 'Nicht genug zum Bezahlen. Es fehlen $amount.';
  }

  @override
  String get invoicesCheckNode => 'Node';

  @override
  String get invoicesCheckEpicbox => 'Epicbox';

  @override
  String get invoicesNodeOk => 'Antwortet';

  @override
  String get invoicesNodeDown => 'Antwortet nicht';

  @override
  String get invoicesEpicboxOk => 'Verbunden';

  @override
  String get invoicesEpicboxDown => 'Nicht verbunden';

  @override
  String get invoicesSendRequest => 'Anforderung senden';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer wird gebeten, $amount zu zahlen. Die Anforderung läuft in 24 h ab.';
  }

  @override
  String get invoicesRequestHowTitle => 'Bevor Sie anfordern';

  @override
  String get netStatusNode => 'Node';

  @override
  String get netStatusEpicbox => 'Epicbox';

  @override
  String get netStatusTor => 'Tor';

  @override
  String get netStatusSynced => 'Synchron';

  @override
  String get netStatusSyncing => 'Synchronisiert';

  @override
  String netStatusSyncingPercent(int percent) {
    return 'Synchronisiert $percent %';
  }

  @override
  String get netStatusConnecting => 'Verbindet';

  @override
  String netStatusBehind(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString zurück',
      one: '$countString zurück',
    );
    return '$_temp0';
  }

  @override
  String get netStatusOffline => 'Offline';

  @override
  String get netStatusOnline => 'Online';

  @override
  String get netStatusOff => 'Aus';

  @override
  String get netStatusOn => 'An';

  @override
  String get netStatusFailed => 'Fehlgeschlagen';

  @override
  String netStatusStarting(int percent) {
    return 'Startet $percent %';
  }

  @override
  String netStatusTestHost(String network, String host) {
    return '$network · $host';
  }

  @override
  String get netStatusTitle => 'Netzwerkstatus';

  @override
  String get netStatusReachable => 'Erreichbar';

  @override
  String get netStatusPublishing => 'Wird veröffentlicht…';

  @override
  String get netStatusNotReachable => 'Nicht erreichbar';

  @override
  String get netStatusTorOpenHint => 'Öffnet die Privatsphäre-Einstellungen';

  @override
  String get netStatusDirectOpenHint =>
      'Öffnet die Adresse für den Direkt-Empfang';

  @override
  String get netStatusOpenHint => 'Zeigt die Server';

  @override
  String get serverNodeTitle => 'Node';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String get serverSearchHint => 'Node suchen oder Adresse eingeben';

  @override
  String serverUseAddress(String address) {
    return '$address verwenden';
  }

  @override
  String get serverTesting => 'Wird geprüft…';

  @override
  String serverTestAnswer(String height, String version) {
    return 'Block $height · v$version';
  }

  @override
  String serverTestFailed(String error) {
    return 'Keine Antwort. $error';
  }

  @override
  String get serverMyNodes => 'Meine Nodes';

  @override
  String get serverPublicNodes => 'Öffentliche Nodes';

  @override
  String get serverPublicRelays => 'Öffentliche Server';

  @override
  String get serverHealthUnknown =>
      'status.btlabs.uk nicht erreichbar; Zustand unbekannt';

  @override
  String get serverAtTip => 'aktuell';

  @override
  String serverBehindShort(String count) {
    return '−$count';
  }

  @override
  String serverBehindLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Blöcke zurück',
      one: '$count Block zurück',
    );
    return '$_temp0';
  }

  @override
  String get serverAddMine => 'Zu meinen Nodes hinzufügen';

  @override
  String get serverRemoveMine => 'Aus meinen Nodes entfernen';

  @override
  String get serverNotResponding => 'Antwortet nicht';

  @override
  String get serverHealthy => 'Gesund';

  @override
  String get serverDegraded => 'Eingeschränkt';

  @override
  String get serverHealthNone => 'Zustand unbekannt';

  @override
  String get serverCurrent => 'Aktuell';

  @override
  String get serverDefault => 'Standard';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % erreichbar';
  }

  @override
  String serverSwitchTo(String host) {
    return 'Zu $host wechseln';
  }

  @override
  String get serverNodeSwitchNote =>
      'Die Wallet verbindet sich neu. Die Guthaben werden mit der neuen Node erneut geprüft.';

  @override
  String get serverRelayWarning =>
      'Deine Adresse enthält diesen Server. Ein Wechsel ändert deine Adresse; Absender brauchen die neue.';

  @override
  String get serverRelaySwitchNote =>
      'Deine Adresse ändert sich; Absender brauchen die neue.';

  @override
  String get serverOtherRelay => 'Anderer Server, host oder host:port';

  @override
  String get serverFactHeight => 'Höhe';

  @override
  String get serverFactVersion => 'Version';

  @override
  String get serverFactPeers => 'Peers';

  @override
  String get serverFactUptime => 'Verfügbarkeit 24 h';

  @override
  String serverHeightAtTip(String height) {
    return '$height · aktuell';
  }

  @override
  String serverNodesAgree(String height) {
    return 'Nodes einig bei $height';
  }

  @override
  String serverNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$up von $total Nodes erreichbar',
      one: '$up von $total Node erreichbar',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'letzter Block vor $seconds s',
      one: 'letzter Block vor $seconds s',
    );
    return '$_temp0';
  }

  @override
  String serverLastBlockMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'letzter Block vor $minutes min',
      one: 'letzter Block vor $minutes min',
    );
    return '$_temp0';
  }

  @override
  String serverCheckedAt(String time) {
    return 'status.btlabs.uk, geprüft $time';
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
  String get methodFile => 'Datei';

  @override
  String get methodArtCaptionEpicbox => 'Epicbox-Server hält sie';

  @override
  String get methodArtCaptionHttp => 'Direkt zur Wallet';

  @override
  String get methodArtCaptionTor => 'Direkt, über Tor';

  @override
  String get methodArtCaptionFile => 'Datei hin, Antwort zurück';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: Die Zahlung geht an den Epicbox-Server, der sie hält, bis die Wallet der Gegenseite wieder da ist';

  @override
  String get methodArtLabelHttp =>
      'HTTP: Die Zahlung geht direkt an die Wallet der Gegenseite, die geöffnet sein muss';

  @override
  String get methodArtLabelTor =>
      'Tor: Die Zahlung geht direkt an die Wallet der Gegenseite, über das Tor-Netzwerk';

  @override
  String get methodArtLabelFile =>
      'Datei: Eine Transaktionsdatei wird übergeben, eine Antwortdatei kommt zurück, dann schließt der Absender ab';

  @override
  String get methodSendEpicboxTitle => 'Die Gegenseite kann offline sein.';

  @override
  String get settingsShowTipsAgain => 'Tipps wieder zeigen';

  @override
  String get settingsShowTipsAgainDone => 'Tipps werden wieder gezeigt';

  @override
  String get tipHide => 'Tipp ausblenden';

  @override
  String get methodSendEpicboxLine =>
      'Der Epicbox-Server hält die Zahlung, bis die Gegenseite ihre Wallet öffnet.';

  @override
  String get methodSendHttpTitle => 'Direkt zur Wallet der Gegenseite.';

  @override
  String get methodSendHttpLine =>
      'Sie muss geöffnet und unter ihrer HTTP-Adresse erreichbar sein.';

  @override
  String get methodSendTorTitle =>
      'Direkt zur Wallet der Gegenseite, über Tor.';

  @override
  String get methodSendTorLine =>
      'Langsamer und privater. Ihre Wallet muss geöffnet sein.';

  @override
  String get methodSendFileTitle => 'Keine Verbindung nötig.';

  @override
  String get methodSendFileLine =>
      'Datei übergeben, Antwortdatei zurückbekommen, dann hier abschließen.';

  @override
  String get methodReceiveEpicboxTitle => 'Teilen, um bezahlt zu werden.';

  @override
  String get methodReceiveEpicboxLine =>
      'Funktioniert auch bei geschlossener Wallet: der Epicbox-Server hält Zahlungen, bis sie wieder da ist.';

  @override
  String get methodReceiveTorTitle => 'Langsamer und privater.';

  @override
  String get methodReceiveTorLine =>
      'Funktioniert nur, solange die App geöffnet oder kurz im Hintergrund ist.';

  @override
  String get methodReceiveFileTitle => 'Eine Datei hin und her geben.';

  @override
  String get methodReceiveFileLine =>
      'Funktioniert ohne Verbindung zwischen den Wallets.';

  @override
  String get methodAddressKindsTooltip => 'Adressarten';

  @override
  String get sendMethodLabel => 'Methode';

  @override
  String get sendToLabel => 'An';

  @override
  String get sendToHint => 'Adresse oder Kontakt';

  @override
  String get sendSwitchedHttp => 'Über HTTP';

  @override
  String get sendSwitchedEpicbox => 'Über Epicbox';

  @override
  String get sendSwitchedTorAnnounce =>
      'Tor-Adresse. Methode auf Tor gestellt.';

  @override
  String get sendSwitchedHttpAnnounce =>
      'HTTP-Adresse. Methode auf HTTP gestellt.';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Epicbox-Adresse. Methode auf Epicbox gestellt.';

  @override
  String get sendReviewMethodHttp => 'HTTP, direkt zur Wallet';

  @override
  String get sendCancelRuleEpicbox =>
      'Kann storniert werden, solange sie auf die Gegenseite wartet.';

  @override
  String get sendCancelRuleDirect =>
      'Kann nicht storniert werden, sobald die Wallet der Gegenseite sie annimmt.';

  @override
  String get sendCancelRuleFile =>
      'Kann storniert werden, bis die Antwortdatei abgeschlossen ist.';

  @override
  String get sendHttpReaching =>
      'Wallet der Gegenseite wird erreicht… App geöffnet lassen.';

  @override
  String get sendDeliveredWaitingBlock => 'Zugestellt · Wartet auf einen Block';

  @override
  String get sendHttpAddressShape =>
      'Eine HTTP-Adresse beginnt mit http:// oder https://.';

  @override
  String get sendPlainHttpTitle => 'Nicht verschlüsselt. Trotzdem senden?';

  @override
  String get sendPlainHttpBody =>
      'Unverschlüsseltes HTTP zu einem anderen Gerät. Jeder auf dem Weg kann die Transaktion lesen. Eine https://-Adresse ist verschlüsselt.';

  @override
  String get sendCancelPossibleWhileWaiting =>
      'Möglich, solange die Zahlung auf die Gegenseite wartet.';

  @override
  String get receiveEpicboxCaption =>
      'Beim Vorlesen die ersten sechs und letzten sechs Zeichen prüfen.';

  @override
  String get receiveTorCaption =>
      'Manche Wallets zeigen die Adresse ohne .onion; beides ist dieselbe Adresse.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Die Wallet der Gegenseite war nicht erreichbar. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens $days Tage.',
      one: 'Die Wallet der Gegenseite war nicht erreichbar. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String deskInvActFrom(String label) {
    return 'Rechnung von $label';
  }

  @override
  String get deskInvActFilter => 'Rechnungen';

  @override
  String get deskInvActBlock => 'Rechnung';

  @override
  String get deskInvActOpen => 'In Rechnungen öffnen';

  @override
  String get deskInvActBilledBy => 'Gestellt von';

  @override
  String get deskInvActOverviewTitle => 'Rechnungen';

  @override
  String deskInvActOverviewToPay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rechnungen zu zahlen',
      one: '1 Rechnung zu zahlen',
      zero: 'Nichts zu zahlen',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgestellte Rechnungen warten auf die Zahler',
      one: '1 ausgestellte Rechnung wartet auf den Zahler',
      zero: 'Keine ausgestellte Rechnung wartet',
    );
    return '$_temp0';
  }

  @override
  String deskInvActOverviewAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen brauchen Sie: erneut senden oder stornieren',
      one: '1 Zahlung braucht Sie: erneut senden oder stornieren',
    );
    return '$_temp0';
  }

  @override
  String get deskInvActReview => 'Prüfen';

  @override
  String get deskInvActOpenInvoices => 'Rechnungen öffnen';

  @override
  String get deskInvNav => 'Rechnungen';

  @override
  String get deskInvTitle => 'Rechnungen';

  @override
  String get deskInvTabPay => 'Bezahlen';

  @override
  String get deskInvTabIssue => 'Ausstellen';

  @override
  String deskInvTabCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get deskInvIssueAction => 'Rechnung ausstellen';

  @override
  String get deskInvChecking => 'Wird geprüft';

  @override
  String deskInvCheckedAt(String time) {
    return 'Geprüft um $time';
  }

  @override
  String get deskInvCheckFailedTitle => 'Der Epicbox-Server antwortet nicht';

  @override
  String get deskInvCheckFailedBody =>
      'Die Listen zeigen, was zuvor ankam. Nichts ging verloren; die Wallet versucht es alle 2 Minuten erneut.';

  @override
  String get deskInvReqWaiting => 'Wartet auf Zahler';

  @override
  String get deskInvReqPaid => 'Bezahlt, wird abgeschlossen';

  @override
  String get deskInvReqPosted => 'Gesendet ans Netzwerk';

  @override
  String deskInvConfirming(int count, int total) {
    return 'Bestätigung $count von $total';
  }

  @override
  String get deskInvCompleted => 'Abgeschlossen';

  @override
  String get deskInvReqNotPosted => 'Nicht gesendet';

  @override
  String get deskInvDeclined => 'Abgelehnt';

  @override
  String get deskInvExpired => 'Abgelaufen';

  @override
  String get deskInvWithdrawn => 'Zurückgezogen';

  @override
  String get deskInvReqBounced => 'Zurückgeschickt';

  @override
  String get deskInvPayWaiting => 'Zu zahlen';

  @override
  String get deskInvPayPaying => 'Wird bezahlt';

  @override
  String get deskInvPayNotDelivered => 'Nicht zugestellt';

  @override
  String get deskInvPayDelivered => 'Wartet auf Senden';

  @override
  String get deskInvPayPosted => 'Vom Dienst gesendet';

  @override
  String get deskInvPayWithdrawnAfterPay => 'Nach Zahlung zurückgezogen';

  @override
  String get deskInvPayPastTtl => 'Nicht in der Blockchain';

  @override
  String get deskInvPayCancelled => 'Storniert';

  @override
  String get deskInvUnpaid => 'Unbezahlt';

  @override
  String get deskInvYouPay => 'Sie zahlen';

  @override
  String deskInvExpiresAt(String time) {
    return 'Läuft ab $time';
  }

  @override
  String get deskInvSlateId => 'Slate-ID';

  @override
  String get deskInvAdvanced => 'Erweitert';

  @override
  String get deskInvOneDevice =>
      'Nutzen Sie Rechnungen nur auf einem Gerät. Ein anderes Gerät mit dieser Wallet kann eine Zahlung annehmen, die für dieses bestimmt ist.';

  @override
  String get deskInvFailed =>
      'Das hat nicht geklappt. Nichts wurde geändert; versuchen Sie es erneut.';

  @override
  String get deskInvHowItWorks => 'So funktionieren Rechnungen';

  @override
  String get deskInvAddressHint => 'es…@epicbox.epiccash.com';

  @override
  String get deskInvEpicboxAddress => 'Epicbox-Adresse';

  @override
  String get deskInvHelpTitle => 'Rechnungen';

  @override
  String get deskInvHelpLede =>
      'Rechnungen von vertrauenswürdigen Absendern, bezahlt erst nach Zustimmung.';

  @override
  String get deskInvHelpFlowTitle => 'So funktioniert eine Rechnung';

  @override
  String get deskInvHelpFlowShort =>
      'Der Aussteller schickt eine Rechnung an die Rechnungsadresse des Zahlers. Bezahlt wird erst, wenn der Zahler zustimmt.';

  @override
  String get deskInvHelpFlowIntro =>
      'Eine Rechnung bittet um eine Zahlung. Der **Aussteller** wird bezahlt; der **Zahler** entscheidet.';

  @override
  String get deskInvHelpFlowStep1 =>
      'Die Wallet des Ausstellers schickt die Rechnung über den Epicbox-Server an die **Rechnungsadresse** des Zahlers.';

  @override
  String get deskInvHelpFlowStep2 =>
      'Der Zahler öffnet sie unter [[Rechnungen › Bezahlen]], prüft Absender, Betrag und Nachricht und wählt **Zustimmen und zahlen** mit dem Wallet-Passwort.';

  @override
  String get deskInvHelpFlowStep3 =>
      'Die Wallet des Zahlers schickt die Zahlung an die **Zahlungsadresse** des Ausstellers.';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return 'Die Wallet des Ausstellers schließt die Zahlung ab und sendet sie ans Netzwerk. Nach $confirmations Bestätigungen ist sie endgültig.';
  }

  @override
  String get deskInvHelpFlowNever =>
      'Ohne Zustimmung wird nichts bezahlt, und eine Rechnung bringt dem Zahler nie Geld in die Wallet. Jede Rechnung hat eine Zahlungsfrist von höchstens 48 Stunden; danach kann sie nicht mehr bezahlt werden.';

  @override
  String get deskInvHelpFlowIssued =>
      'Rechnungen, die diese Wallet ausgestellt hat, stehen unter [[Rechnungen › Ausstellen]].';

  @override
  String get deskInvHelpTrustTitle => 'Warum nur vertrauenswürdige Absender';

  @override
  String get deskInvHelpTrustShort =>
      'Nur Absender auf der Vertrauensliste können eine Rechnung in den Posteingang legen. Das hält Spam und gefälschte Rechnungen fern.';

  @override
  String get deskInvHelpTrustP1 =>
      'Die Wallet nimmt eine Rechnung nur an ihrer Rechnungsadresse an und nur von einem Absender auf der Vertrauensliste, erkannt an seiner Adresse. Alles andere wird ungelesen verworfen, bevor es geöffnet wird, und erscheint nie unter [[Rechnungen › Bezahlen]].';

  @override
  String get deskInvHelpTrustP2 =>
      'Ohne die Liste könnte jeder, der die Rechnungsadresse kennt, den Posteingang mit Spam oder mit echt wirkenden Rechnungen füllen.';

  @override
  String get deskInvHelpTrustP3 =>
      'Vertrauen erlaubt einem Absender nur zu fragen. Ein vertrauenswürdiger Absender kann nichts nehmen: Jede Rechnung wartet weiter auf **Zustimmen und zahlen**.';

  @override
  String get deskInvHelpTrustWhere1 =>
      'Einem Absender vertrauen unter [[Einstellungen › Rechnungen]].';

  @override
  String get deskInvHelpTrustWhere2 =>
      'Oder bei einem Kontakt unter [[Kontakte]] **Vertraut für Rechnungen** einschalten.';

  @override
  String get deskInvHelpTrustWhere3 =>
      'Ein Absender kann jederzeit von der Liste entfernt werden. Seine neuen Rechnungen werden dann verworfen.';

  @override
  String get deskInvHelpAddrTitle => 'Warum eine eigene Rechnungsadresse';

  @override
  String get deskInvHelpAddrShort =>
      'Rechnungen kommen an einer eigenen Adresse an, getrennt von der Zahlungsadresse, an die gezahlt wird.';

  @override
  String get deskInvHelpAddrP1 =>
      'Die Wallet hat zwei Epicbox-Adressen. Die **Zahlungsadresse** unter [[Empfangen]] empfängt Zahlungen. Die **Rechnungsadresse** empfängt nur Rechnungen.';

  @override
  String get deskInvHelpAddrP2 =>
      'So kann die Rechnungsadresse an Dienste gegeben oder ersetzt werden, ohne die Adresse preiszugeben oder zu ändern, an die gezahlt wird.';

  @override
  String get deskInvHelpAddrP3 =>
      'Die Rechnungsadresse empfängt keine Zahlungen: Eine Zahlung an sie wird verworfen. Für Zahlungen die Zahlungsadresse weitergeben.';

  @override
  String get deskInvHelpAddrWhere1 =>
      'Die Rechnungsadresse finden, kopieren oder als QR-Code zeigen unter [[Einstellungen › Rechnungen]].';

  @override
  String get deskInvHelpAddrWhere2 =>
      '**Neue Rechnungsadresse** ersetzt sie. Dienste mit der alten können dann keine Rechnungen mehr schicken, bis sie die neue haben.';

  @override
  String get deskInvHelpDiagramTitle => 'Wie eine Rechnung reist';

  @override
  String get deskInvHelpDiagramIssuer => 'Aussteller';

  @override
  String get deskInvHelpDiagramPayer => 'Zahler';

  @override
  String get deskInvHelpDiagramIssues => 'Stellt die Rechnung aus';

  @override
  String get deskInvHelpDiagramInvoice => 'Rechnung';

  @override
  String get deskInvHelpDiagramGate => 'Rechnungsadresse';

  @override
  String get deskInvHelpDiagramGateSub => 'Nur vertraute Absender';

  @override
  String get deskInvHelpDiagramDropped => 'Andere Absender';

  @override
  String get deskInvHelpDiagramDroppedSub => 'Ungelesen verworfen';

  @override
  String get deskInvHelpDiagramReview => 'Prüft und stimmt zu';

  @override
  String get deskInvHelpDiagramReviewSub => 'Zustimmen und zahlen';

  @override
  String get deskInvHelpDiagramPayment => 'Zahlung';

  @override
  String get deskInvHelpDiagramPayAddr => 'Zahlungsadresse';

  @override
  String get deskInvHelpDiagramPayAddrSub => 'Nicht die Rechnungsadresse';

  @override
  String get deskInvHelpDiagramFinal => 'Schließt ab und sendet';

  @override
  String deskInvHelpDiagramFinalSub(int confirmations) {
    return 'Endgültig nach Bestätigungen: $confirmations';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      'Der Aussteller schickt eine Rechnung an die Rechnungsadresse des Zahlers, die nur vertraute Absender annimmt und den Rest verwirft; der Zahler prüft sie und stimmt zu; die Zahlung geht an die Zahlungsadresse des Ausstellers; dessen Wallet schließt sie ab und sendet sie ans Netzwerk.';

  @override
  String get deskInvIssuerFormTitle => 'Rechnung ausstellen';

  @override
  String get deskInvIssuerFirstTitle => 'Vor der ersten Rechnung';

  @override
  String get deskInvIssuerYourAddress => 'Ihre Zahlungsadresse';

  @override
  String get deskInvIssuerMethod => 'Methode';

  @override
  String get deskInvIssuerEpicbox => 'Epicbox';

  @override
  String get deskInvIssuerFile => 'Datei';

  @override
  String get deskInvIssuerDirect => 'Direkt';

  @override
  String get deskInvIssuerSoon => 'Demnächst';

  @override
  String get deskInvIssuerPayer => 'Rechnungsadresse der anderen Seite';

  @override
  String get deskInvIssuerPayerHelp =>
      'Die Wallet der anderen Seite zeigt sie unter Einstellungen › Rechnungen.';

  @override
  String get deskInvIssuerPayerMissing =>
      'Fügen Sie die Rechnungsadresse der anderen Seite ein.';

  @override
  String get deskInvIssuerPayerInvalid =>
      'Das ist keine gültige Epicbox-Adresse.';

  @override
  String get deskInvIssuerPayerOwn =>
      'Das ist eine Ihrer eigenen Adressen. Verwenden Sie die Rechnungsadresse, die Ihnen der Zahler gibt.';

  @override
  String get deskInvIssuerPayerHttp =>
      'Rechnungen über Epicbox brauchen eine Epicbox-Adresse, keine HTTP- oder Tor-Adresse.';

  @override
  String get deskInvIssuerContacts => 'Kontakte';

  @override
  String get deskInvIssuerNoContacts =>
      'Noch kein Kontakt hat eine Rechnungsadresse. Fügen Sie sie unter Kontakte hinzu.';

  @override
  String get deskInvIssuerNoInvoices =>
      'Diese Wallet hat schon einmal eine Rechnung zurückgeschickt: Sie kann Rechnungen über Epicbox nicht bezahlen. Senden Sie stattdessen eine Rechnungsdatei oder bitten Sie um die Zahlung.';

  @override
  String get deskInvIssuerUseFile => 'Datei verwenden';

  @override
  String get deskInvIssuerUnknown =>
      'Nur wallet-for-epic und andere LEPIC-Wallets können eine Rechnung über Epicbox bezahlen. Die Epic GUI wallet und Stack Wallet können gar keine Rechnungen bezahlen; die Befehlszeile epic-wallet kann eine Rechnungsdatei bezahlen.';

  @override
  String get deskInvIssuerAmount => 'Betrag';

  @override
  String get deskInvIssuerAmountMissing => 'Geben Sie einen Betrag ein.';

  @override
  String get deskInvIssuerAmountZero => 'Der Betrag muss größer als 0 sein.';

  @override
  String get deskInvIssuerAmountDecimals =>
      'EPIC hat höchstens 8 Nachkommastellen.';

  @override
  String get deskInvIssuerAmountCap =>
      'Mehr als alle EPIC, die es je geben wird.';

  @override
  String get deskInvIssuerAmountHelp =>
      'Nichts verlässt Ihre Wallet: Der Zahler zahlt diesen Betrag plus seine eigene Gebühr.';

  @override
  String get deskInvIssuerMessage => 'Nachricht an den Zahler';

  @override
  String deskInvIssuerMessageCount(int used, int max) {
    return '$used von $max Byte';
  }

  @override
  String get deskInvIssuerMessageLong => 'Die Nachricht ist zu lang.';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'Der Zahler hat $hours Stunden Zeit zum Zahlen.';
  }

  @override
  String get deskInvIssuerIssue => 'Ausstellen';

  @override
  String get deskInvIssuerRelayDown =>
      'Der Epicbox-Server antwortet nicht, daher kann jetzt keine Rechnung gesendet werden.';

  @override
  String get deskInvIssuerFixFields =>
      'Korrigieren Sie die rot markierten Felder.';

  @override
  String get deskInvIssuerNotDelivered =>
      'Die Rechnung hat den Epicbox-Server nicht erreicht. Es wurde nichts gesendet. Versuchen Sie es erneut.';

  @override
  String deskInvIssuerSent(String payer) {
    return 'Rechnung an $payer gesendet.';
  }

  @override
  String get deskInvIssuerEmpty =>
      'Noch keine Rechnungen ausgestellt. Eine Rechnung bittet einen Kontakt oder Dienst, Sie zu bezahlen; sie kostet nichts.';

  @override
  String deskInvIssuerTo(String payer) {
    return 'Rechnung an $payer';
  }

  @override
  String deskInvIssuerIssued(String time) {
    return 'Ausgestellt $time';
  }

  @override
  String get deskInvIssuerPayerFact => 'Zahler';

  @override
  String get deskInvIssuerAmountFact => 'Betrag';

  @override
  String get deskInvIssuerMessageFact => 'Nachricht';

  @override
  String get deskInvIssuerSentFact => 'Ausgestellt';

  @override
  String get deskInvIssuerExpiresFact => 'Läuft ab';

  @override
  String get deskInvIssuerAnsweredFact => 'Beendet';

  @override
  String get deskInvIssuerStepPaid => 'Bezahlt';

  @override
  String get deskInvIssuerStepConfirming => 'Bestätigung';

  @override
  String get deskInvIssuerEnded =>
      'Diese Rechnung endete unbezahlt. Nichts ist angekommen.';

  @override
  String get deskInvIssuerWithdraw => 'Zurückziehen';

  @override
  String get deskInvIssuerWithdrawTitle => 'Diese Rechnung zurückziehen?';

  @override
  String deskInvIssuerWithdrawBody(String payer) {
    return '$payer kann sie dann nicht mehr bezahlen.';
  }

  @override
  String get deskInvIssuerKeep => 'Behalten';

  @override
  String get deskInvIssuerWithdrawn => 'Rechnung zurückgezogen.';

  @override
  String get deskInvIssuerRepost => 'Erneut senden';

  @override
  String get deskInvIssuerReposted => 'Zahlung erneut gesendet.';

  @override
  String get deskInvIssuerNodeDown =>
      'Der Knoten antwortet nicht. Versuchen Sie es erneut, wenn er erreichbar ist.';

  @override
  String get deskInvIssuerNotPostedText =>
      'Die Zahlung ist fertig, aber nicht im Netzwerk: Der Knoten hat sie abgelehnt oder war nicht erreichbar.';

  @override
  String get deskInvIssuerCancel => 'Zahlung stornieren';

  @override
  String get deskInvIssuerCancelTitle => 'Diese Zahlung stornieren?';

  @override
  String deskInvIssuerCancelBody(String payer) {
    return 'Sie kommt dann nicht an. Das Guthaben von $payer bleibt in dessen Wallet gesperrt, bis dort storniert wird.';
  }

  @override
  String deskInvIssuerBounced(String payer) {
    return 'Die Wallet von $payer hat die Rechnung zurückgeschickt: Sie kann keine Rechnungen bezahlen. Bitten Sie stattdessen um eine Zahlung.';
  }

  @override
  String get deskInvIssuerSendFile => 'Datei verwenden';

  @override
  String get deskInvIssuerLate =>
      'Nach dem Ende dieser Rechnung kam eine Zahlung an. Sie wurde abgelehnt; nichts hat sich geändert.';

  @override
  String deskInvIssuerPaidText(String payer) {
    return '$payer hat bezahlt. Ihre Wallet hat die Zahlung abgeschlossen und gesendet.';
  }

  @override
  String deskInvIssuerWaitingText(String payer) {
    return 'An die Rechnungsadresse von $payer zugestellt. Nichts ist bezahlt, bis dort zugestimmt wird.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Slate-ID kopieren';

  @override
  String get deskInvIssuerStepsIntro =>
      'Die Wallet der anderen Seite muss Rechnungen annehmen. Vor der ersten Rechnung:';

  @override
  String get deskInvIssuerStepTrust =>
      '1. Die andere Seite fügt Ihre Zahlungsadresse unten zu ihren vertrauenswürdigen Absendern hinzu.';

  @override
  String get deskInvIssuerStepAddress =>
      '2. Die andere Seite gibt Ihnen ihre Rechnungsadresse.';

  @override
  String get deskInvIssuerStepIssued => 'Ausgestellt';

  @override
  String deskInvNoticePaid(String payer, String amount) {
    return '$payer hat $amount EPIC bezahlt.';
  }

  @override
  String deskInvNoticeDeclined(String payer) {
    return '$payer hat Ihre Rechnung abgelehnt.';
  }

  @override
  String get deskInvNoticeIssuedExpired =>
      'Eine von Ihnen ausgestellte Rechnung ist unbezahlt abgelaufen.';

  @override
  String deskInvNoticeWithdrawn(String service) {
    return '$service hat eine Rechnung zurückgezogen, bevor Sie sie beantwortet haben.';
  }

  @override
  String get deskInvNoticeExpired =>
      'Eine Rechnung ist abgelaufen, bevor Sie sie beantwortet haben.';

  @override
  String get deskInvNoticeUnknownPayment =>
      'Eine Zahlung für eine Rechnung, die dieses Gerät nicht ausgestellt hat, ist eingetroffen und wurde abgelehnt. Hat ein anderes Gerät mit dieser Wallet sie ausgestellt, bitten Sie den Zahler, zu stornieren und erneut zu zahlen.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Eine Antwort auf eine Zahlung, die dieses Gerät nicht gesendet hat, ist eingetroffen und wurde abgelehnt. Hat ein anderes Gerät mit dieser Wallet sie gesendet, stornieren Sie sie dort und senden Sie erneut.';

  @override
  String get deskInvPayerWaitingHead => 'Wartet auf Sie';

  @override
  String get deskInvPayerNeedsHead => 'Offene Zahlungen';

  @override
  String get deskInvPayerReview => 'Prüfen';

  @override
  String get deskInvPayerPaidHead => 'Bezahlt';

  @override
  String get deskInvPayerView => 'Ansehen';

  @override
  String get deskInvPayerNoMessage => 'Keine Nachricht';

  @override
  String deskInvPayerDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Nachrichten nicht vertrauenswürdiger Absender wurden ignoriert.',
      one: '1 Nachricht eines nicht vertrauenswürdigen Absenders wurde ignoriert.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvPayerTrustService => 'Dienst vertrauen…';

  @override
  String get deskInvPayerYourInvoiceAddress => 'Ihre Rechnungsadresse';

  @override
  String get deskInvPayerEmptyTitle => 'Keine Rechnungen warten';

  @override
  String get deskInvPayerEmptyText =>
      'Wenn Ihnen ein vertrauenswürdiger Dienst eine Rechnung stellt, erscheint sie hier. Bezahlt wird erst, wenn Sie zustimmen.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Ihre Zahlung an $service wurde nicht zugestellt';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Sie ist signiert und auf diesem Gerät gespeichert; das Guthaben bleibt gesperrt. „Erneut senden“ schickt sie ohne zweite Zustimmung noch einmal.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service hat eine bezahlte Rechnung zurückgezogen';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'Die Zahlung erreicht die Blockchain vielleicht nie. Stornieren Sie sie, um Ihr Guthaben freizugeben.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Ihre Zahlung an $service ist nicht in der Blockchain';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Ihre Frist ist abgelaufen und das Netzwerk hat sie nicht gesehen. Stornieren Sie sie, um Ihr Guthaben freizugeben.';

  @override
  String get deskInvPayerCancelPayment => 'Zahlung stornieren';

  @override
  String get deskInvPayerSafetyTitle => 'Bezahlen Sie nur erwartete Rechnungen';

  @override
  String get deskInvPayerSafetyText =>
      'Eine Rechnung bringt nie Geld in Ihre Wallet. Wer zustimmt, sendet Geld.';

  @override
  String deskInvPayerSameBillTitle(String service, String ago) {
    return 'Sie haben $service vor $ago denselben Betrag gezahlt';
  }

  @override
  String get deskInvPayerSameBillText =>
      'Prüfen Sie, ob das eine neue Rechnung ist, bevor Sie zahlen.';

  @override
  String deskInvPayerAgoHours(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String deskInvPayerAgoMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get deskInvPayerFee => 'Gebühr';

  @override
  String get deskInvPayerTotal => 'Gesamt';

  @override
  String get deskInvPayerBalanceAfter => 'Guthaben danach';

  @override
  String get deskInvPayerMessageCaption =>
      'Vom Dienst geschrieben. Ihre Wallet prüft sie nicht.';

  @override
  String get deskInvPayerPaysTo => 'Zahlt an';

  @override
  String deskInvPayerTrustedSince(String service, String date) {
    return '$service, vertraut seit $date';
  }

  @override
  String get deskInvPayerExpires => 'Läuft ab';

  @override
  String get deskInvPayerLockHeight => 'Sperrhöhe';

  @override
  String get deskInvPayerLockNone => 'Keine';

  @override
  String get deskInvPayerReceived => 'Empfangen';

  @override
  String get deskInvPayerShort => 'Nicht genug verfügbares Guthaben';

  @override
  String deskInvPayerShortText(String total, String spendable) {
    return 'Sie brauchen $total EPIC verfügbar; Sie haben $spendable EPIC. Noch bestätigendes Guthaben zählt ab 3 Bestätigungen.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Der Knoten antwortet nicht';

  @override
  String get deskInvPayerNodeDownText =>
      'Die Wallet kann Ihr Guthaben nicht prüfen und daher nicht zahlen. Zustimmen geht wieder, sobald der Knoten antwortet; unter Einstellungen › Knoten können Sie einen anderen wählen.';

  @override
  String get deskInvPayerPaid =>
      'Diese Rechnung ist bezahlt. Darauf kann nichts mehr gezahlt werden.';

  @override
  String get deskInvPayerDeclinedText =>
      'Sie haben diese Rechnung abgelehnt. Es wurde nichts bezahlt.';

  @override
  String get deskInvPayerBack => 'Zurück zu Rechnungen';

  @override
  String deskInvPayerApproveTitle(String amount, String fee, String service) {
    return '$amount EPIC + $fee Gebühr an $service zahlen?';
  }

  @override
  String deskInvPayerApproveText(String total) {
    return '$total EPIC verlassen Ihre Wallet. Geben Sie zum Zustimmen das Wallet-Passwort ein.';
  }

  @override
  String get deskInvPayerPassword => 'Wallet-Passwort';

  @override
  String get deskInvPayerWrongPassword =>
      'Falsches Passwort. Es wurde nichts bezahlt.';

  @override
  String get deskInvPayerEnterPassword => 'Geben Sie das Wallet-Passwort ein.';

  @override
  String get deskInvPayerPay => 'Zahlen';

  @override
  String get deskInvPayerCancel => 'Abbrechen';

  @override
  String get deskInvPayerClose => 'Schließen';

  @override
  String get deskInvPayerNodeDownPay =>
      'Der Knoten antwortet nicht. Es wurde nichts bezahlt.';

  @override
  String get deskInvPayerAlreadyAnswered =>
      'Diese Rechnung wurde bereits beantwortet. Es wurde nichts weiter bezahlt.';

  @override
  String get deskInvPayerCannotPay =>
      'Diese Rechnung kann nicht bezahlt werden. Es wurde nichts bezahlt.';

  @override
  String get deskInvPayerNotDeliveredToast => 'Signiert, nicht zugestellt';

  @override
  String get deskInvPayerNotDeliveredToastText =>
      'Der Epicbox-Server antwortet nicht. Senden Sie sie unter Rechnungen › Bezahlen erneut; ohne zweite Zustimmung.';

  @override
  String get deskInvPayerRetryFailed => 'Immer noch nicht zugestellt';

  @override
  String get deskInvPayerRetryFailedText =>
      'Der Epicbox-Server antwortet nicht. Die Zahlung bleibt signiert auf diesem Gerät.';

  @override
  String get deskInvPayerCancelTitle => 'Diese Zahlung stornieren?';

  @override
  String get deskInvPayerCancelText =>
      'Das Stornieren gibt Ihr Guthaben hier frei. Der Dienst hat Ihre signierte Zahlung noch und könnte sie abschließen, bis dieses Guthaben erneut ausgegeben ist.';

  @override
  String deskInvPayerCancelWho(String amount, String service) {
    return '$amount EPIC an $service';
  }

  @override
  String get deskInvPayerKeepPayment => 'Behalten';

  @override
  String get deskInvPayerOnItsWay =>
      'Bereits unterwegs: kann nicht storniert werden.';

  @override
  String get deskInvPayerCannotCheck =>
      'Das Netzwerk kann gerade nicht geprüft werden; versuchen Sie es erneut, wenn der Knoten erreichbar ist.';

  @override
  String get deskInvPayerCancelled => 'Zahlung storniert';

  @override
  String get deskInvPayerCancelledText => 'Ihr Guthaben ist freigegeben.';

  @override
  String get deskInvPayerDeclined =>
      'Rechnung abgelehnt. Es wurde nichts bezahlt.';

  @override
  String get deskInvPayerSpendToSelf => 'Jetzt an mich selbst senden';

  @override
  String get deskInvPayerSpendToSelfHelp =>
      'Macht die Stornierung endgültig: Die signierte Kopie des Dienstes kann nicht mehr abgeschlossen werden. Kostet eine Netzwerkgebühr.';

  @override
  String get deskInvPayerSpentText =>
      'Ihr Guthaben ist freigegeben und innerhalb dieser Wallet verschoben. Die Stornierung ist endgültig.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Ihr Guthaben ist freigegeben, aber das Verschieben hat nicht geklappt. Die Stornierung ist noch nicht endgültig.';

  @override
  String get deskInvPayerLocked =>
      'Diese Rechnung kann nicht bezahlt werden: Sie ist bis zu einem späteren Block gesperrt. Nichts wurde bezahlt.';

  @override
  String get deskInvPayerRelayDownPay =>
      'Der Epicbox-Server antwortet nicht. Es wurde nichts bezahlt.';

  @override
  String get deskInvSetTitle => 'Rechnungen';

  @override
  String get deskInvSetIntro =>
      'Dienste, denen Sie vertrauen, stellen dieser Wallet Rechnungen an ihre Rechnungsadresse. Bezahlt wird erst, wenn Sie jeder Rechnung zustimmen.';

  @override
  String get deskInvSetAddressLabel => 'Rechnungsadresse';

  @override
  String get deskInvSetAddressWarning =>
      'Geben Sie sie nur Diensten, denen Sie vertrauen. Sie empfängt keine Zahlungen.';

  @override
  String get deskInvSetCopy => 'Kopieren';

  @override
  String get deskInvSetCopied =>
      'Rechnungsadresse kopiert. Geben Sie sie nur Diensten, denen Sie vertrauen; sie empfängt keine Zahlungen.';

  @override
  String get deskInvSetQrShow => 'QR zeigen';

  @override
  String get deskInvSetQrHide => 'QR ausblenden';

  @override
  String get deskInvSetQrLabel => 'QR-Code Ihrer Rechnungsadresse';

  @override
  String deskInvSetIndex(int index) {
    return 'Rechnungsadresse $index';
  }

  @override
  String get deskInvSetTrusted => 'Vertrauenswürdige Absender';

  @override
  String get deskInvSetTrustedNone =>
      'Keine vertrauenswürdigen Absender. Rechnungen von allen anderen werden ungelesen ignoriert.';

  @override
  String deskInvSetSince(String date) {
    return 'Vertraut seit $date';
  }

  @override
  String get deskInvSetContactTag => 'Kontakt';

  @override
  String get deskInvSetRemove => 'Entfernen';

  @override
  String deskInvSetRemoveTitle(String name) {
    return '$name nicht mehr vertrauen?';
  }

  @override
  String deskInvSetRemoveBody(String name) {
    return '$name kann Ihnen dann keine Rechnungen mehr senden. Bereits wartende Rechnungen bleiben, bis Sie sie beantworten oder sie ablaufen.';
  }

  @override
  String deskInvSetRemoved(String name) {
    return '$name kann Ihnen keine Rechnungen mehr senden.';
  }

  @override
  String get deskInvSetKeep => 'Behalten';

  @override
  String get deskInvSetAdd => 'Absender vertrauen';

  @override
  String get deskInvSetAddBody =>
      'Ein vertrauenswürdiger Absender kann dieser Wallet Rechnungen an ihre Rechnungsadresse stellen. Bezahlt wird erst, wenn Sie jeder Rechnung mit Ihrem Wallet-Passwort zustimmen.';

  @override
  String get deskInvSetName => 'Name';

  @override
  String get deskInvSetNameMissing => 'Geben Sie dem Absender einen Namen.';

  @override
  String get deskInvSetSenderAddress => 'Seine Zahlungsadresse';

  @override
  String get deskInvSetSenderMissing =>
      'Fügen Sie die Adresse ein, die der Dienst anzeigt.';

  @override
  String get deskInvSetSenderInvalid =>
      'Das ist keine gültige Epicbox-Adresse.';

  @override
  String get deskInvSetTrust => 'Vertrauen';

  @override
  String deskInvSetAdded(String name) {
    return '$name kann Ihnen jetzt Rechnungen senden.';
  }

  @override
  String deskInvSetDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Nachrichten nicht vertrauenswürdiger Absender wurden ungelesen ignoriert.',
      one: '1 Nachricht eines nicht vertrauenswürdigen Absenders wurde ungelesen ignoriert.',
    );
    return '$_temp0';
  }

  @override
  String get deskInvSetRotate => 'Neue Rechnungsadresse';

  @override
  String get deskInvSetRotateHint =>
      'Dienste mit der alten Adresse können Ihnen dann keine Rechnungen mehr senden.';

  @override
  String get deskInvSetRotateTitle => 'Neue Rechnungsadresse erzeugen?';

  @override
  String get deskInvSetRotateBody =>
      'Dienste mit der alten Adresse können Ihnen dann keine Rechnungen mehr senden. Geben Sie die neue jedem Dienst, der Ihnen Rechnungen stellt.';

  @override
  String get deskInvSetRotateConfirm => 'Neue Adresse erzeugen';

  @override
  String get deskInvSetRotated =>
      'Neue Rechnungsadresse bereit. Geben Sie sie Ihren Diensten.';

  @override
  String get deskInvSetExpiry => 'Zahlungsfrist';

  @override
  String get deskInvSetExpiryHint =>
      'Wie lange eine ausgestellte Rechnung bezahlbar bleibt und wie lange eine empfangene auf Sie wartet. Höchstens 48 Stunden.';

  @override
  String deskInvSetHours(int hours) {
    return '$hours Stunden';
  }

  @override
  String get deskInvSetCancel => 'Abbrechen';

  @override
  String get deskInvSetContactSection => 'Rechnungen';

  @override
  String get deskInvSetTheirInvoice => 'Rechnungsadresse der anderen Seite';

  @override
  String get deskInvSetTheirInvoiceNone =>
      'Keine Rechnungsadresse gespeichert. Fragen Sie danach, um Rechnungen auszustellen.';

  @override
  String get deskInvSetTrustedSwitch => 'Vertrauenswürdig für Rechnungen';

  @override
  String get deskInvSetTrustedSwitchHelp =>
      'Erlaubt diesem Kontakt, Ihnen Rechnungen zu stellen. Bezahlt wird erst, wenn Sie einer Rechnung zustimmen.';

  @override
  String get deskInvSetIssueNeeds =>
      'Braucht die Rechnungsadresse der anderen Seite.';

  @override
  String get deskInvSetShare => 'Rechnungsadresse teilen';

  @override
  String get deskInvSetReceiveHint =>
      'Bitten Sie einen Kontakt oder Dienst, Sie zu bezahlen. Dessen Wallet muss Rechnungen annehmen.';

  @override
  String get deskInvSetRestoredHint =>
      'Diese Wallet aus der Wiederherstellungsphrase wiederhergestellt? Geben Sie Diensten diese Rechnungsadresse erneut.';

  @override
  String get serverSwitchRelayTitle => 'epicbox-Server wechseln?';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'Die epicbox-Adresse ändert sich zu …@$relay. Absender brauchen die neue Adresse. An die alte Adresse gesendete Zahlungen bleiben auf dem alten Server.';
  }

  @override
  String get serverSwitchRelayConfirm => 'Wechseln';

  @override
  String get helpButton => 'Hilfe';

  @override
  String get helpSearchHint => 'Hilfe durchsuchen';

  @override
  String get helpEnglishOnly => 'Die Hilfe ist vorerst auf Englisch.';

  @override
  String helpNoMatch(String query) {
    return 'Keine Hilfe zu „$query“';
  }

  @override
  String helpMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Themen',
      one: '1 Thema',
    );
    return '$_temp0';
  }

  @override
  String get helpShowHandshake => 'So funktioniert es';

  @override
  String get helpMoreInSection => 'Mehr in diesem Abschnitt';

  @override
  String get sendBalanceAfter => 'Saldo danach';

  @override
  String get sendSpendableUntilChange =>
      'Verfügbar, bis das Wechselgeld bestätigt ist';

  @override
  String get sendSpendableUntilChangeHint =>
      'Das Wechselgeld kommt zurück, sobald die Zahlung bestätigt ist.';

  @override
  String serverSwitched(String host) {
    return 'Gewechselt zu $host';
  }

  @override
  String get methodDirect => 'Direkt';

  @override
  String get methodDirectShape => 'http://host:3415 oder xxxx….onion';

  @override
  String get methodSendDirectLine =>
      'Ihre Wallet muss geöffnet sein. Eine Onion-Adresse läuft über Tor.';

  @override
  String get methodArtLabelDirect =>
      'Direkt: Die Zahlung geht direkt an die Wallet des Empfängers, die geöffnet sein muss';

  @override
  String get methodReceiveEpicboxShort =>
      'Funktioniert bei geschlossener Wallet.';

  @override
  String get methodReceiveDirectTitle => 'Direkt an diese Wallet.';

  @override
  String get methodReceiveDirectLine =>
      'Funktioniert, solange die App geöffnet ist.';

  @override
  String methodLineOverTor(String line) {
    return '$line Über Tor.';
  }

  @override
  String get sendSwitchedDirect => 'Direkte Adresse';

  @override
  String get sendSwitchedDirectAnnounce =>
      'Direkte Adresse. Methode auf Direkt gesetzt.';

  @override
  String get sendDirectAddressShape =>
      'Eine direkte Adresse beginnt mit http:// oder https:// oder endet auf .onion.';

  @override
  String get torNotOverTor => 'Nicht über Tor';

  @override
  String get torNeeds => 'Benötigt Tor.';

  @override
  String get torTurnOn => 'Tor einschalten';

  @override
  String get torTurnOff => 'Tor ausschalten';

  @override
  String get torNotConnectedNotice => 'Tor ist nicht verbunden.';

  @override
  String get torWaiting => 'Warten auf Tor';

  @override
  String get torWordStarting => 'Startet…';

  @override
  String get torWordNotConnected => 'Nicht verbunden';

  @override
  String get torSettingsLink => 'Tor-Einstellungen';

  @override
  String get torNetworkLabel => 'Tor-Netzwerk';

  @override
  String get torNetworkHint =>
      'Die Netzwerkaktivität läuft über das Tor-Netzwerk. Tor verbirgt die Internetadresse der Wallet: Jede Verbindung geht über mehrere ehrenamtlich betriebene Relays, sodass kein Server erfährt, wo die Wallet ist. Benachrichtigungen sind aus, solange Tor an ist.';

  @override
  String get receiveTabDirect => 'Direkt';

  @override
  String get receiveDirectNeedsTor => 'Direkter Empfang benötigt Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Absender nutzen bis dahin die Epicbox-Adresse.';

  @override
  String get netStatusOverTor => 'über Tor';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsNotificationsHint =>
      'Nutzt den Benachrichtigungsdienst von Google. Es werden keine sensiblen Daten geteilt.';

  @override
  String get settingsPushPaused => 'Pausiert, solange Tor an ist';

  @override
  String get pushConfirmRelayBody =>
      'Benachrichtigungen nutzen die Epicbox von BT Labs und den Benachrichtigungsdienst von Google. Es werden keine sensiblen Daten geteilt.';

  @override
  String get pushConfirmRelayAddress =>
      'Deine Epicbox-Adresse ändert sich. Teile die neue.';

  @override
  String get pushRelaySwitchFailed =>
      'Der Server konnte nicht gewechselt werden. Benachrichtigungen bleiben aus.';

  @override
  String get pushConfirmTitle => 'Benachrichtigungen einschalten?';

  @override
  String get pushConfirmBody =>
      'Benachrichtigungen nutzen den Benachrichtigungsdienst von Google. Es werden keine sensiblen Daten geteilt.';

  @override
  String get pushConfirmAction => 'Einschalten';

  @override
  String get pushNoticeOn => 'Benachrichtigungen an';

  @override
  String get pushNoticeOff => 'Benachrichtigungen aus';

  @override
  String get pushNoticeAvailable =>
      'Benachrichtigungen sind in den Einstellungen verfügbar.';

  @override
  String get torWayOver => 'Über Tor';

  @override
  String get torWayWaiting => 'Warten auf Tor';

  @override
  String get torWayNotConnected => 'Tor ist nicht verbunden.';
}
