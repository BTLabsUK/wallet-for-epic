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
  String get txStatusCancelled => 'Storniert';

  @override
  String get txStatusFromBackup => 'Aus Sicherung, Status unbekannt';

  @override
  String get txIconCancelled => 'Storniert';

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
    return 'Zahlung storniert: $amount';
  }

  @override
  String txSpokenCancelledSendTo(String amount, String who) {
    return 'Zahlung an $who storniert: $amount';
  }

  @override
  String txSpokenCancelledReceive(String amount) {
    return 'Eingehende Zahlung storniert: $amount';
  }

  @override
  String txSpokenCancelledReceiveFrom(String amount, String who) {
    return 'Zahlung von $who storniert: $amount';
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
      'Die Antwort auf diese Zahlung kam zu spät, daher wurde die Zahlung storniert. Es wurde nichts gesendet.';

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
    return ' ($network, Test-Coins)';
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
          'Wartet seit $days Tagen. Die Epicbox löscht Zahlungen nach 7 Tagen, daher kann diese Zahlung nicht mehr abgeschlossen werden. Stornieren Sie sie, um den Betrag freizugeben, und senden Sie dann erneut.',
      one: 'Wartet seit 1 Tag. Die Epicbox löscht Zahlungen nach 7 Tagen, daher kann diese Zahlung nicht mehr abgeschlossen werden. Stornieren Sie sie, um den Betrag freizugeben, und senden Sie dann erneut.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'An die Epicbox des Empfängers gesendet. Die Zahlung wird abgeschlossen, sobald dessen Wallet online ist. Bis dahin bleibt der Betrag gesperrt, es sei denn, Sie stornieren.';

  @override
  String get txDetailsWaitingRecipient =>
      'Wartet darauf, dass der Empfänger mit seiner Transaktionsdatei antwortet. Bis dahin bleibt der Betrag gesperrt, es sei denn, Sie stornieren.';

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
      'Storniert. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledReleased =>
      'Das Netzwerk hat die Zahlung nie angenommen, daher wurde der Betrag freigegeben. Prüfen Sie vor dem erneuten Senden, ob der Empfänger sie nicht doch erhalten hat.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Die Zahlung hat das Netzwerk nicht innerhalb von 14 Tagen erreicht, daher hat die Wallet sie storniert. Prüfen Sie vor dem erneuten Senden, ob der Empfänger sie nicht doch erhalten hat.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Der Empfänger hat nicht innerhalb von 14 Tagen geantwortet, daher hat die Wallet die Zahlung storniert. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Der Empfänger hat erst nach Ablauf der 14-Tage-Frist geantwortet, daher hat die Wallet die Zahlung storniert, statt sie abzuschließen. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Die Zahlung konnte dem Empfänger nicht zugestellt werden, daher hat die Wallet sie sofort storniert. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledIncoming =>
      'Storniert. Diese Zahlung wird nicht eintreffen.';

  @override
  String get txDetailsFromBackup =>
      'Diese Zahlung stammt aus einer Verlaufssicherung und war beim Erstellen der Sicherung noch nicht abgeschlossen. Diese Wallet hat keine eigenen Daten dazu und kann daher nicht feststellen, ob sie abgeschlossen wurde. Es ist nichts gesperrt.';

  @override
  String txDetailsCancelsAtBlock(String height) {
    return 'Wird automatisch storniert, wenn sie bis Block $height nicht abgeschlossen ist.';
  }

  @override
  String txDetailsCancelsAtBlockInMinutes(String height, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return 'Wird automatisch storniert, wenn sie bis Block $height nicht abgeschlossen ist (in etwa $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInHours(String height, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '1 Stunde',
    );
    return 'Wird automatisch storniert, wenn sie bis Block $height nicht abgeschlossen ist (in etwa $_temp0).';
  }

  @override
  String txDetailsCancelsAtBlockInDays(String height, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return 'Wird automatisch storniert, wenn sie bis Block $height nicht abgeschlossen ist (in etwa $_temp0).';
  }

  @override
  String txDetailsExpiredAtBlock(String height) {
    return 'Bei Block $height abgelaufen. Die Wallet storniert sie bei der nächsten Aktualisierung.';
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
  String get txDetailsCancelPayment => 'Zahlung stornieren';

  @override
  String get txDetailsCancelTitle => 'Zahlung stornieren?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Der Absender kann diese Zahlung noch abschließen. Tut er das nach der Stornierung, erscheint sie erst nach einem erneuten Scan.';

  @override
  String get txDetailsCancelSendBody =>
      'Diese Zahlung stornieren und den Betrag freigeben? Tun Sie das nur, wenn der Empfänger sie nicht abgeschlossen hat.';

  @override
  String get txDetailsCancelKeep => 'Behalten';

  @override
  String get txDetailsPaymentCancelled => 'Zahlung storniert';

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
  String get historyFilterCancelled => 'Storniert';

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
  String get historyNoCancelled => 'Keine stornierten Zahlungen.';

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
  String get demoEndedBody =>
      'Die Demo-Wallet und die Test-Coins wurden gelöscht.';

  @override
  String get demoStartAgain => 'Neu starten';

  @override
  String demoEndsAt(String time) {
    return 'Ihre Demo endet um $time. Dann werden die Demo-Wallet und die Test-Coins gelöscht.';
  }

  @override
  String get demoEndingSoon =>
      'Ihre Demo endet in 30 Minuten. Dann werden die Demo-Wallet und die Test-Coins gelöscht.';

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
      'In Ihrer Epicbox wartet eine Zahlung, die eintrifft, sobald die App verbunden ist.';

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
      'Der Epicbox-Server meldet ein Problem. Wird erneut versucht.';

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
      'In der Blockchain, wartet auf genug Bestätigungen.';

  @override
  String get homeBalanceNotOnChain => 'Noch nicht in der Blockchain';

  @override
  String get balanceNotOnChainHelp =>
      'Zahlungen an Sie, die der Absender noch nicht abgeschlossen hat oder die noch in keinem Block sind, und Wechselgeld Ihrer Zahlungen. Sie zählen erst, wenn sie in einem Block sind: Eine nur angebotene Zahlung kommt vielleicht nie an.';

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
  String get statusNodeSyncing => 'Node: Synchronisierung';

  @override
  String statusNodeSyncingPercent(int percent) {
    return 'Node: Synchronisierung $percent %';
  }

  @override
  String get statusNodeConnecting => 'Node: Verbindung…';

  @override
  String get statusNodeOffline => 'Node offline';

  @override
  String get statusEpicboxOnline => 'Epicbox online';

  @override
  String get statusEpicboxConnecting => 'Epicbox: Verbindung…';

  @override
  String get statusEpicboxOffline => 'Epicbox offline';

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
      'Verbindung zur Epicbox getrennt, wird wiederhergestellt.';

  @override
  String get homeEpicboxConnecting =>
      'Verbindung zur Epicbox wird hergestellt…';

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
          'Für $amount stehen die Antworten der Wallets der Empfänger noch aus. Bis dahin bleibt der Betrag gesperrt. Falls eine davon nie antwortet, öffnen Sie die Zahlung und tippen Sie auf „Zahlung stornieren“.',
      one:
          'Für $amount steht die Antwort der Wallet des Empfängers noch aus. Bis dahin bleibt der Betrag gesperrt. Falls keine Antwort kommt, öffnen Sie die Zahlung und tippen Sie auf „Zahlung stornieren“.',
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
    return '$service hat diese Rechnung zurückgezogen, nachdem Sie sie bezahlt haben. Wenn die Zahlung nicht bestätigt wird, stornieren Sie sie, um Ihr Guthaben freizugeben.';
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
  String get receiveEpicboxConnected => 'Mit Epicbox verbunden';

  @override
  String get receiveQrLabel => 'QR-Code Ihrer Adresse';

  @override
  String get receiveAddressLabel => 'Epicbox-Adresse';

  @override
  String get receiveEpicboxOfflineBody =>
      'An Sie gesendete Zahlungen warten jetzt auf dem Epicbox-Server und kommen an, sobald die Wallet wieder verbunden ist.';

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
  String get updateAllowInstalls =>
      'Erlauben Sie Installationen von Epic Cash Mobile und kehren Sie dann zurück.';

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
  String get setupRelayHeading => 'Epicbox-Server';

  @override
  String get setupRelayHint => 'Dieser Server ist Teil Ihrer Adresse.';

  @override
  String get setupCustomRelayLabel =>
      'Anderer Epicbox-Server (Host oder host:port)';

  @override
  String get setupCustomRelayUse => 'Diesen Server verwenden';

  @override
  String get setupCustomRelayInvalid =>
      'Geben Sie einen Host ein, z. B. epicbox.example.com';

  @override
  String get setupRelayChangeWarning =>
      'Wenn Sie den Epicbox-Server wechseln, ändert sich Ihre Adresse. Geben Sie Absendern die neue Adresse. An die alte Adresse gesendete Zahlungen warten auf dem alten Server, bis Sie zurückwechseln.';

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
      'Zahlungen an eine Wallet-URL werden nicht unterstützt. Fragen Sie den Empfänger nach seiner Epicbox-Adresse.';

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
          'Ist die Zahlung nach $days Tagen noch nicht abgeschlossen, wird sie automatisch storniert und der Betrag freigegeben. Um sie früher zu stoppen, öffnen Sie die Zahlung und tippen Sie auf „Zahlung stornieren“.',
      one: 'Ist die Zahlung nach 1 Tag noch nicht abgeschlossen, wird sie automatisch storniert und der Betrag freigegeben. Um sie früher zu stoppen, öffnen Sie die Zahlung und tippen Sie auf „Zahlung stornieren“.',
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
  String get settingsEpicboxServer => 'Epicbox-Server';

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
  String get settingsStateNotBackedUp => 'Noch nicht gesichert';

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
  String get fileHelpYou => 'Sie';

  @override
  String get fileHelpFriend => 'Gegenüber';

  @override
  String get fileHelpSendStep1 => 'Sie erstellen eine Zahlungsdatei.';

  @override
  String get fileHelpSendStep2 =>
      'Sie schicken sie Ihrem Gegenüber, wie Sie möchten, etwa per Chat oder E-Mail.';

  @override
  String get fileHelpSendStep3 =>
      'Ihr Gegenüber öffnet sie in seiner Wallet und schickt Ihnen die signierte Antwort zurück.';

  @override
  String get fileHelpSendStep4 =>
      'Sie öffnen die Antwort, und die Zahlung ist unterwegs.';

  @override
  String get fileHelpReceiveStep1 =>
      'Ihr Gegenüber erstellt eine Zahlungsdatei für Sie.';

  @override
  String get fileHelpReceiveStep2 =>
      'Es schickt sie Ihnen auf beliebigem Weg, etwa per Chat oder E-Mail.';

  @override
  String get fileHelpReceiveStep3 =>
      'Sie öffnen sie in Ihrer Wallet und schicken die signierte Antwort zurück.';

  @override
  String get fileHelpReceiveStep4 =>
      'Ihr Gegenüber öffnet die Antwort, und die Zahlung ist auf dem Weg zu Ihnen.';

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
  String get sendRelayDown =>
      'Der Epicbox-Server der Gegenseite antwortet nicht.';

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
      'Ihre Wallet sendet die Zahlung an den Server. Ihre Coins werden zurückgehalten.';

  @override
  String get handshakePay2 =>
      'Der Server leitet sie weiter. Die Wallet der Gegenseite ergänzt ihren Teil und signiert.';

  @override
  String get handshakeFinish =>
      'Ihre Wallet schließt sie ab und sendet sie an das Netzwerk.';

  @override
  String get handshakeConfirm => 'Das Netzwerk bestätigt sie.';

  @override
  String get handshakeReq1 =>
      'Ihre Wallet sendet die Anforderung an den Server.';

  @override
  String get handshakeReq2 =>
      'Der Server leitet sie weiter. Die Gegenseite stimmt zu, ihre Wallet fügt die Coins hinzu und signiert.';

  @override
  String get handshakeRelay => 'Server';

  @override
  String get handshakeFile => 'Datei';

  @override
  String get handshakeBack =>
      'Die Wallet der Gegenseite schickt sie an den Server zurück.';

  @override
  String get handshakeRelayBack => 'Der Server gibt sie an Ihre Wallet zurück.';

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
          'Der Epicbox-Server der Gegenseite hat sie nicht angenommen. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens $days Tage.',
      one: 'Der Epicbox-Server der Gegenseite hat sie nicht angenommen. Der Betrag bleibt zurückgehalten, bis Sie stornieren, höchstens 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String get sendRelayRefusedLost =>
      'Der Epicbox-Server der Gegenseite hat sie nicht angenommen. Prüfen Sie die Wallet, bevor Sie erneut senden.';

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
  String get homeTileLocked => 'In Zahlungen gesperrt';

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
    return 'Geben Sie die PIN ein, um $amount zu senden.';
  }

  @override
  String sendFilePinReason(String amount) {
    return 'Geben Sie die PIN ein, um eine Zahlungsdatei über $amount zu erstellen.';
  }

  @override
  String get outputsTitle => 'Outputs';

  @override
  String get outputsSpendable => 'Verfügbar';

  @override
  String get outputsConfirming => 'Wird bestätigt';

  @override
  String get outputsLockedTile => 'In Zahlungen gesperrt';

  @override
  String get outputsImmature => 'Unreif';

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
  String get outputsSplitButton => 'Aufteilen…';

  @override
  String get outputsConsolidateButton => 'Zusammenführen…';

  @override
  String get outputsSplitNeeds =>
      'Zum Aufteilen muss mindestens 1 EPIC verfügbar sein.';

  @override
  String get outputsConsolidateNeeds =>
      'Zum Zusammenführen sind mindestens 2 verfügbare Outputs nötig.';

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
  String get outputsWordImmature => 'Unreif';

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
  String get outputsSplitTitle => 'Outputs aufteilen';

  @override
  String outputsSplitText(
    String amount,
    String each,
    String made,
    String spent,
  ) {
    return 'Verbraucht $spent ($amount) und erzeugt $made zu je etwa $each. Eine normale Netzwerktransaktion an diese Wallet, nach 3 Blöcken bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt.';
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
    return 'In $count aufteilen';
  }

  @override
  String get outputsConsolidateTitle => 'Outputs zusammenführen';

  @override
  String outputsConsolidateText(String amount, String result, String spent) {
    return 'Verbraucht $spent ($amount) und erzeugt einen Output über $result. Eine normale Netzwerktransaktion an diese Wallet, nach 3 Blöcken bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt. Die nächste Zahlung verbraucht einen Output, daher ist ihre Gebühr am kleinsten.';
  }

  @override
  String get outputsConsolidateAction => 'Zusammenführen';

  @override
  String get outputsSplitPin =>
      'Mit der PIN bestätigen, um Outputs aufzuteilen';

  @override
  String get outputsConsolidatePin =>
      'Mit der PIN bestätigen, um Outputs zusammenzuführen';

  @override
  String outputsSplitStarted(int count) {
    return 'Aufteilen gestartet: $count Outputs, Bestätigung in etwa 3 Blöcken';
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
  String get invoicesPaysFrom => 'Zahlung aus';

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
  String get netStatusSynced => 'Synchronisiert';

  @override
  String get netStatusSyncing => 'Synchronisierung';

  @override
  String netStatusSyncingPercent(int percent) {
    return 'Synchronisierung $percent %';
  }

  @override
  String get netStatusConnecting => 'Verbindung…';

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
  String get serverMyRelays => 'Meine Server';

  @override
  String get serverRemoveRelay => 'Aus meinen Servern entfernen';

  @override
  String get serverRemoveInUse =>
      'In Verwendung. Wechseln Sie zuerst zu einem anderen Server.';

  @override
  String get serverRemoveRelayTitle => 'Diesen Server entfernen?';

  @override
  String get serverRemoveNodeTitle => 'Diesen Node entfernen?';

  @override
  String serverRemoveBody(String host) {
    return '$host verschwindet aus dieser Liste. Geben Sie ihn erneut ein, um ihn später zu nutzen.';
  }

  @override
  String get serverRemoveConfirm => 'Entfernen';

  @override
  String get serverSupportsNotifications => 'Unterstützt Benachrichtigungen';

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
  String get serverHealthy => 'Funktioniert';

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
      'Die Wallet verbindet sich neu. Die Guthaben werden mit dem neuen Node erneut geprüft.';

  @override
  String get serverRelayWarning =>
      'Ihre Adresse enthält diesen Server. Ein Wechsel ändert Ihre Adresse; Absender brauchen die neue.';

  @override
  String get serverRelaySwitchNote =>
      'Ihre Adresse ändert sich; Absender brauchen die neue.';

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
  String get deskInvReqPosted => 'Im Netzwerk';

  @override
  String deskInvConfirming(int count, int total) {
    return 'Bestätigung $count von $total';
  }

  @override
  String get deskInvCompleted => 'Abgeschlossen';

  @override
  String get deskInvReqNotPosted => 'Nicht im Netzwerk';

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
  String get deskInvPayDelivered => 'Wartet auf Netzwerk';

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
      'Der Zahler öffnet sie unter [[Rechnungen › Bezahlen]], prüft Absender, Betrag und Nachricht und wählt **Zustimmen und bezahlen** mit dem Wallet-Passwort.';

  @override
  String get deskInvHelpFlowStep3 =>
      'Die Wallet des Zahlers schickt die Zahlung an die **Zahlungsadresse** des Ausstellers.';

  @override
  String deskInvHelpFlowStep4(int confirmations) {
    return 'Die Wallet des Ausstellers schließt die Zahlung ab und sendet sie an das Netzwerk. Nach $confirmations Bestätigungen ist sie endgültig.';
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
      'Vertrauen erlaubt einem Absender nur zu fragen. Ein vertrauenswürdiger Absender kann nichts nehmen: Jede Rechnung wartet weiter auf **Zustimmen und bezahlen**.';

  @override
  String get deskInvHelpTrustWhere1 =>
      'Einem Absender vertrauen unter [[Einstellungen › Rechnungen]].';

  @override
  String get deskInvHelpTrustWhere2 =>
      'Oder bei einem Kontakt unter [[Kontakte]] **Vertrauenswürdig für Rechnungen** einschalten.';

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
  String get deskInvHelpDiagramTitle => 'Der Weg einer Rechnung';

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
  String get deskInvHelpDiagramGateSub => 'Nur vertrauenswürdige Absender';

  @override
  String get deskInvHelpDiagramDropped => 'Andere Absender';

  @override
  String get deskInvHelpDiagramDroppedSub => 'Ungelesen verworfen';

  @override
  String get deskInvHelpDiagramReview => 'Prüft und stimmt zu';

  @override
  String get deskInvHelpDiagramReviewSub => 'Zustimmen und bezahlen';

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
    return 'Endgültig nach $confirmations Bestätigungen';
  }

  @override
  String get deskInvHelpDiagramSemantics =>
      'Der Aussteller schickt eine Rechnung an die Rechnungsadresse des Zahlers, die nur vertrauenswürdige Absender annimmt und den Rest verwirft; der Zahler prüft sie und stimmt zu; die Zahlung geht an die Zahlungsadresse des Ausstellers; dessen Wallet schließt sie ab und sendet sie an das Netzwerk.';

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
      'Nur wallet-for-epic und andere LEPIC-Wallets können eine Rechnung über Epicbox bezahlen. Die Epic GUI Wallet und Stack Wallet können gar keine Rechnungen bezahlen; das Befehlszeilenprogramm epic-wallet kann eine Rechnungsdatei bezahlen.';

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
  String get deskInvIssuerRepost => 'Erneut übertragen';

  @override
  String get deskInvIssuerReposted => 'Zahlung erneut übertragen.';

  @override
  String get deskInvIssuerNodeDown =>
      'Der Node antwortet nicht. Versuchen Sie es erneut, wenn er erreichbar ist.';

  @override
  String get deskInvIssuerNotPostedText =>
      'Die Zahlung ist abgeschlossen, aber nicht im Netzwerk: Der Node hat sie abgelehnt oder war nicht erreichbar.';

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
    return '$payer hat bezahlt. Ihre Wallet hat die Zahlung abgeschlossen und an das Netzwerk gesendet.';
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
      'Eine Rechnung bringt nie Geld in Ihre Wallet. Wenn Sie zustimmen, geht Geld hinaus.';

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
    return 'Sie brauchen $total EPIC verfügbar; Sie haben $spendable EPIC. Guthaben, das noch bestätigt wird, zählt ab 3 Bestätigungen.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Der Node antwortet nicht';

  @override
  String get deskInvPayerNodeDownText =>
      'Die Wallet kann Ihr Guthaben nicht prüfen und daher nicht zahlen. Zustimmen geht wieder, sobald der Node antwortet; unter Einstellungen › Node können Sie einen anderen wählen.';

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
  String get deskInvPayerPay => 'Bezahlen';

  @override
  String get deskInvPayerCancel => 'Abbrechen';

  @override
  String get deskInvPayerClose => 'Schließen';

  @override
  String get deskInvPayerNodeDownPay =>
      'Der Node antwortet nicht. Es wurde nichts bezahlt.';

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
      'Das Netzwerk kann gerade nicht geprüft werden; versuchen Sie es erneut, wenn der Node erreichbar ist.';

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
  String get deskInvSetSenderAddress => 'Zahlungsadresse des Absenders';

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
  String get serverSwitchRelayTitle => 'Epicbox-Server wechseln?';

  @override
  String serverSwitchRelayBody(String relay) {
    return 'Die Epicbox-Adresse ändert sich zu …@$relay. Absender brauchen die neue Adresse. An die alte Adresse gesendete Zahlungen bleiben auf dem alten Server.';
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
  String get sendBalanceAfter => 'Guthaben danach';

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
      'Ihre Epicbox-Adresse ändert sich. Teilen Sie die neue.';

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

  @override
  String sendUsesAllOutputs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nutzt alle $count Outputs · Wechselgeld 1 Output',
      one: 'Nutzt den 1 Output · Wechselgeld 1 Output',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSomethingWrong => 'Etwas ist schiefgelaufen';

  @override
  String get deskErrWrongPassword => 'Falsches Passwort';

  @override
  String get deskErrPhraseInvalid => 'Wiederherstellungsphrase ungültig';

  @override
  String get deskErrWalletExists => 'Diese Wallet gibt es bereits';

  @override
  String get deskErrWalletNotFound => 'Keine Wallet gefunden';

  @override
  String get deskErrNodeNotAnswering => 'Node antwortet nicht';

  @override
  String get deskErrNotEnoughFunds => 'Nicht genug Guthaben';

  @override
  String get deskErrNotTxFile => 'Keine Transaktionsdatei für diese Wallet';

  @override
  String get deskErrEpicboxUnreachable => 'Epicbox-Server nicht erreichbar';

  @override
  String get deskErrNotHttpAddress => 'Keine http(s)-Adresse';

  @override
  String get deskErrPlainHttp => 'Unverschlüsseltes HTTP nicht bestätigt';

  @override
  String get deskErrNotOnion => 'Keine Onion-Adresse';

  @override
  String get deskErrTorNotConnected => 'Tor ist nicht verbunden';

  @override
  String get deskErrOnionUnreachable =>
      'Die Wallet des Empfängers ist über Tor nicht erreichbar';

  @override
  String get deskErrWalletBusy =>
      'Wallet beschäftigt. Versuchen Sie es gleich noch einmal.';

  @override
  String get deskErrDbDamaged =>
      'Wallet-Datenbank beschädigt, wird neu aufgebaut';

  @override
  String get deskErrPaymentExpired => 'Zahlung abgelaufen';

  @override
  String get deskErrInvoiceNotFound => 'Rechnung nicht gefunden';

  @override
  String get deskErrAmountMismatch => 'Betrag weicht von der Rechnung ab';

  @override
  String get deskErrInvoicePaid => 'Rechnung bereits bezahlt';

  @override
  String get deskErrInvoiceLocked =>
      'Rechnung bis zu einem späteren Block gesperrt';

  @override
  String get deskErrInvoiceChanged => 'Rechnung geändert';

  @override
  String get deskErrNotAccepted => 'Nicht angenommen';

  @override
  String deskErrNotAcceptedDetail(String detail) {
    return 'Nicht angenommen: $detail';
  }

  @override
  String get deskErrDisk => 'Datenträgerfehler';

  @override
  String deskErrDiskDetail(String detail) {
    return 'Datenträgerfehler: $detail';
  }

  @override
  String get deskErrTorMissing => 'Tor ist in dieser Version nicht enthalten';

  @override
  String get deskErrTorNetwork => 'Tor-Netzwerk nicht erreichbar';

  @override
  String get deskErrTorClock => 'Die Uhr des Computers geht falsch';

  @override
  String get deskErrOnionNotPublished => 'Onion-Adresse nicht veröffentlicht';

  @override
  String get deskErrTorStart => 'Tor ist nicht gestartet';

  @override
  String get deskErrTorStopped => 'Tor wurde beendet';

  @override
  String get deskErrScanRunning => 'Es läuft bereits ein Scan.';

  @override
  String get deskErrCancelRefused =>
      'Nicht storniert: Der Node hat diese Zahlung bereits.';

  @override
  String get deskErrWalletLocked => 'Die Wallet ist gesperrt';

  @override
  String get deskErrWalletLocking => 'Die Wallet wird gesperrt';

  @override
  String deskErrDbDamagedDetail(String detail) {
    return 'Wallet-Datenbank beschädigt. $detail';
  }

  @override
  String deskErrWalletClosed(String detail) {
    return 'Wallet geschlossen: $detail. Entsperren Sie sie erneut.';
  }

  @override
  String deskErrNotChanged(String detail) {
    return 'Nicht geändert: $detail';
  }

  @override
  String deskErrPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mindestens $count Zeichen verwenden',
      one: 'Mindestens $count Zeichen verwenden',
    );
    return '$_temp0';
  }

  @override
  String get deskErrWalletNotListed => 'Wallet nicht in der Liste';

  @override
  String get deskErrUpdateApp =>
      'Aktualisieren Sie die App, um die Liste zu ändern';

  @override
  String get deskErrListNotChanged => 'Wallet-Liste nicht geändert';

  @override
  String get deskErrOpenToDelete => 'Öffnen Sie die Wallet, um sie zu löschen';

  @override
  String get deskErrEnterPassword => 'Geben Sie das Passwort ein';

  @override
  String get deskErrFolderNotFound => 'Wallet-Ordner nicht gefunden';

  @override
  String deskErrAlreadyHere(String name) {
    return 'Diese Wallet ist schon vorhanden: $name';
  }

  @override
  String get deskErrTestNet =>
      'Wallet im Testnetzwerk. Nur Mainnet-Wallets lassen sich importieren.';

  @override
  String get deskErrWalletInApp => 'Diese Wallet ist bereits in der App.';

  @override
  String get deskErrWalletNotFoundSearch =>
      'Wallet nicht gefunden. Suchen Sie erneut.';

  @override
  String get deskErrEnterOldPassword => 'Geben Sie das alte Passwort ein';

  @override
  String deskErrOldPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Das alte Passwort ist zu kurz. Wählen Sie ein neues mit mindestens $count Zeichen.',
      one:
          'Das alte Passwort ist zu kurz. Wählen Sie ein neues mit mindestens $count Zeichen.',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSeedUnreadable =>
      'Die Datei wallet.seed konnte nicht gelesen werden';

  @override
  String get deskErrNotSeedFile => 'Keine wallet.seed-Datei';

  @override
  String deskErrAlreadyInApp(String name) {
    return 'Bereits in der App als $name';
  }

  @override
  String get deskErrWrongOldPassword => 'Falsches altes Passwort';

  @override
  String get deskErrListNotSaved => 'Wallet-Liste nicht gespeichert';

  @override
  String get deskErrProofSeedRead => 'Seed gelesen';

  @override
  String get deskErrProofWalletCreated => 'Wallet erstellt';

  @override
  String deskErrProofContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte hinzugefügt',
      one: '1 Kontakt hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofNode(String name) {
    return 'Node $name zur Node-Liste hinzugefügt';
  }

  @override
  String deskErrProofEpicbox(String old, String current) {
    return 'Die ältere App nutzte den Epicbox-Server $old; diese App nutzt $current';
  }

  @override
  String get deskErrProofFolderUnchanged => 'Alter Ordner unverändert';

  @override
  String get deskErrProofFolderChanged =>
      'Alter Ordner wurde von einem anderen Programm geändert';

  @override
  String deskErrProofHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verlauf: $count Transaktionen',
      one: 'Verlauf: 1 Transaktion',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofHistoryAlready => 'Verlauf bereits importiert';

  @override
  String get deskErrProofHistoryNone =>
      'Kein Verlauf im alten Ordner; der Scan stellt das Guthaben wieder her';

  @override
  String get deskErrProofHistoryOld =>
      'Der Verlauf von Epic Wallet 5.3 oder älter ist nicht lesbar; der Scan stellt das Guthaben wieder her';

  @override
  String get deskErrProofHistoryBusy =>
      'Verlauf nicht importiert: Die ältere Wallet läuft. Er wird beim nächsten Entsperren importiert';

  @override
  String get deskErrProofHistoryOther =>
      'Verlauf nicht importiert: Er gehört zu einer anderen Wallet';

  @override
  String get deskErrProofHistoryUnreadable =>
      'Verlauf nicht importiert: Die alte Datenbank konnte nicht gelesen werden; der Scan stellt das Guthaben wieder her';

  @override
  String get deskErrNodeNoAnswer => 'Der Node hat nicht geantwortet';

  @override
  String get deskErrNotPosted => 'Nicht im Netzwerk';

  @override
  String get deskErrNotEpicboxAddress => 'Keine Epicbox-Adresse';

  @override
  String get deskErrFileNotSaved =>
      'Datei nicht gespeichert. Die Zahlung wartet unter Aktivität; stornieren Sie sie dort, um den Betrag freizugeben.';

  @override
  String get deskErrTorOffSend =>
      'Tor ist aus. Schalten Sie Tor ein, um an eine Onion-Adresse zu senden.';

  @override
  String get deskErrTorConnecting =>
      'Tor verbindet sich noch. Versuchen Sie es gleich noch einmal.';

  @override
  String get deskErrRecipientNoAnswer =>
      'Die Wallet des Empfängers hat nicht geantwortet oder abgelehnt.';

  @override
  String get deskErrRecipientNoAnswerWaits =>
      'Die Wallet des Empfängers hat nicht geantwortet oder abgelehnt. Die Zahlung wartet unter Aktivität; stornieren Sie sie dort, um den Betrag freizugeben.';

  @override
  String get deskErrNotDelivered =>
      'Nicht zugestellt. Die Zahlung wartet unter Aktivität; stornieren Sie sie dort, um den Betrag freizugeben.';

  @override
  String get deskErrInterruptedLock =>
      'Durch das Sperren unterbrochen. Sie ist vielleicht trotzdem hinausgegangen: Prüfen Sie nach dem Entsperren die Aktivität.';

  @override
  String deskErrStoredWaits(String detail) {
    return '$detail. Die Zahlung wartet unter Aktivität; stornieren Sie sie dort, um den Betrag freizugeben.';
  }

  @override
  String get deskErrNodeRefused =>
      'Von beiden Wallets signiert, aber der Node hat sie abgelehnt. Stornieren Sie sie unter Aktivität, um den Betrag freizugeben.';

  @override
  String get deskErrFileNotReadable => 'Datei nicht lesbar';

  @override
  String get deskErrNotTxFile2 => 'Keine Transaktionsdatei';

  @override
  String get deskErrResponseNotSaved => 'Antwortdatei nicht gespeichert';

  @override
  String get deskErrCannotCancel => 'Diese Zahlung lässt sich nicht stornieren';

  @override
  String get deskErrNoLocalNode => 'Kein lokaler Node in dieser Version';

  @override
  String get deskErrLocalNodeStopped => 'Lokaler Node gestoppt';

  @override
  String get deskErrNotChangedLocked =>
      'Nicht geändert: Die Wallet wurde gesperrt';

  @override
  String deskErrLocalNodeNotStarted(String detail) {
    return 'Lokaler Node nicht gestartet: $detail';
  }

  @override
  String get deskErrUnknown => 'unbekannter Fehler';

  @override
  String get deskErrNotServerName => 'Kein gültiger Servername';

  @override
  String deskErrPortInUse(int port) {
    return 'Port $port belegt';
  }

  @override
  String deskErrPortUnavailable(int port) {
    return 'Port $port nicht verfügbar';
  }

  @override
  String get deskErrStoppedWithError => 'Mit einem Fehler beendet';

  @override
  String get deskErrPasswordNotChanged =>
      'Passwort nicht geändert. Das bisherige Passwort öffnet die Wallet weiterhin.';

  @override
  String get deskErrNothingToSpend => 'Nichts auszugeben';

  @override
  String get deskTorLineOff => 'Aus';

  @override
  String get deskTorLineReady => 'Bereit';

  @override
  String deskTorLineSendsWork(String problem) {
    return '$problem. Senden funktioniert.';
  }

  @override
  String get deskTorLinePublishing => 'Onion-Adresse wird veröffentlicht…';

  @override
  String deskTorLineConnecting(int percent) {
    return 'Verbindung mit Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'Sicherung einer anderen Wallet';

  @override
  String get deskErrHistOtherChain => 'Falsches Netzwerk';

  @override
  String get deskErrHistNotOurs => 'Keine Verlaufssicherung';

  @override
  String get deskErrHistNewer => 'Neuere Datei';

  @override
  String get deskErrHistDamaged => 'Datei beschädigt';

  @override
  String get deskErrOldGui => 'Ältere Epic Wallet';

  @override
  String get deskErrOldCli => 'Das Programm epic';

  @override
  String get deskErrOldPicked => 'Gewählte Ordner';

  @override
  String get deskErrHistTooLarge => 'Die Datei ist zu groß für eine Sicherung.';

  @override
  String deskErrHistChains(String from, String to) {
    return 'Die Datei stammt aus dem $from; diese Wallet läuft im $to.';
  }

  @override
  String get deskErrHistOtherWalletText =>
      'Die Datei wurde aus einer Wallet mit einer anderen Wiederherstellungsphrase exportiert.';

  @override
  String get deskErrHistNewerText =>
      'Eine neuere Version der App hat diese Datei erstellt. Aktualisieren Sie die App und importieren Sie sie dann.';

  @override
  String get deskErrHistDamagedText =>
      'Die Datei ist unvollständig oder wurde verändert.';

  @override
  String get deskErrHistNotOursText =>
      'Die Datei wurde nicht von Epic Cash Desktop oder Epic Cash Mobile erstellt.';

  @override
  String get deskDataHttpEnter => 'Geben Sie die Adresse des Empfängers ein';

  @override
  String get deskDataHttpScheme => 'Mit https:// oder http:// beginnen';

  @override
  String get deskDataHttpOnion => 'Onion-Adressen benötigen Tor';

  @override
  String get deskDataHttpNot => 'Keine http(s)-Adresse';

  @override
  String get deskDataHttpPort => 'Port muss zwischen 1 und 65535 liegen';

  @override
  String get deskDataUpdTimeout => 'Der Update-Server hat nicht geantwortet.';

  @override
  String get deskDataUpdUnreachable =>
      'Der Update-Server war nicht erreichbar.';

  @override
  String deskDataUpdStatus(int status) {
    return 'Der Update-Server hat mit $status geantwortet.';
  }

  @override
  String get deskDataUpdNone =>
      'Für die Desktop-App sind noch keine Update-Informationen veröffentlicht.';

  @override
  String get deskNodeSynced => 'Synchronisiert';

  @override
  String get deskNodeBehind => 'Im Rückstand';

  @override
  String get deskNodeNotAnswering => 'Antwortet nicht';

  @override
  String get deskNodeChecking => 'Wird geprüft';

  @override
  String get deskNodeStarting => 'Startet';

  @override
  String get deskNodeSyncing => 'Synchronisierung';

  @override
  String get deskNodeStalled => 'Stockt';

  @override
  String get deskNodeFailed => 'Fehlgeschlagen';

  @override
  String get deskNodeStopped => 'Gestoppt';

  @override
  String get deskNodeMarkerNoAnswer => 'keine Antwort';

  @override
  String deskNodeMarkerBehind(String count) {
    return '$count zurück';
  }

  @override
  String get deskNodeMarkerStarting => 'startet';

  @override
  String get deskNodeMarkerStalled => 'stockt';

  @override
  String get deskNodeMarkerFailed => 'fehlgeschlagen';

  @override
  String get deskNodeMarkerStopped => 'gestoppt';

  @override
  String deskNodeHostSince(String host, String time) {
    return '$host · seit $time';
  }

  @override
  String get deskNodeNotAnsweringLine => 'Der Node antwortet nicht.';

  @override
  String deskNodeLatency(String ms) {
    return '$ms ms';
  }

  @override
  String deskNodeLatencyOverTor(String ms) {
    return '$ms ms über Tor';
  }

  @override
  String deskNodeNewerOut(String version) {
    return '$version ist erschienen';
  }

  @override
  String get deskNodeBehindLine => 'Im Rückstand zum Netzwerk; holt auf.';

  @override
  String deskNodeHeightOf(String height, String total) {
    return '$height von $total';
  }

  @override
  String get deskNodeAtTip => 'aktuell';

  @override
  String get deskNodeLocal => 'Lokaler Node';

  @override
  String get deskNodeConnectingPeers => 'Verbindung zu Peers';

  @override
  String deskNodeUsingUntilSynced(String host) {
    return '$host wird genutzt, bis der lokale Node synchronisiert ist.';
  }

  @override
  String get deskNodeNothingUntilSynced =>
      'Bis der lokale Node synchronisiert ist, kann nichts gesendet werden.';

  @override
  String deskNodePeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Peers',
      one: '$count Peer',
    );
    return '$_temp0';
  }

  @override
  String deskNodeRunning(String duration) {
    return 'läuft seit $duration';
  }

  @override
  String deskNodeStillUsing(String host) {
    return 'Noch wird $host genutzt; der lokale Node übernimmt in Kürze.';
  }

  @override
  String get deskNodeNoProgress =>
      'Seit 5 Min. kein Fortschritt. Bereits einmal neu gestartet.';

  @override
  String deskNodeUsingMeanwhile(String host) {
    return 'Solange wird $host genutzt.';
  }

  @override
  String get deskNodeStartIt => 'Starten Sie ihn unter Einstellungen › Node.';

  @override
  String get deskNodeFailPort =>
      'Port 3413 wird von einem anderen Programm genutzt';

  @override
  String get deskNodeFailDisk => 'nicht genug Speicherplatz';

  @override
  String get deskNodeFailMissing => 'das Node-Programm fehlt';

  @override
  String get deskNodeFailExited => 'das Node-Programm wurde beendet';

  @override
  String deskNodeFailExitedCode(String code) {
    return 'das Node-Programm wurde beendet (Exit-Code $code)';
  }

  @override
  String get deskNodeFailDefault => 'der Node ist nicht gestartet';

  @override
  String get deskNodeStageWaiting => 'Verbindung zu Peers';

  @override
  String get deskNodeStageHeaders => 'Header';

  @override
  String get deskNodeStageChainDownload => 'Download des Chain-Zustands';

  @override
  String get deskNodeStageKernels => 'Prüfung der Kernels';

  @override
  String get deskNodeStageRangeProofs => 'Prüfung der Range Proofs';

  @override
  String get deskNodeStageProcessing => 'Verarbeitung des Chain-Zustands';

  @override
  String get deskNodeStageBlocks => 'Blöcke';

  @override
  String get deskNodeStageCompacting => 'Komprimierung';

  @override
  String get deskNodeStageStopping => 'wird beendet';

  @override
  String get deskNodeStageSyncing => 'Synchronisierung';

  @override
  String get deskNodeLineWaiting => 'Verbindung zu Peers';

  @override
  String deskNodeLineHeaders(String done, String total) {
    return 'Header · $done von $total';
  }

  @override
  String get deskNodeLineHeadersBare => 'Header';

  @override
  String deskNodeLineChain(String done, String total) {
    return 'Chain-Zustand · $done von $total GB';
  }

  @override
  String get deskNodeLineChainBare => 'Chain-Zustand';

  @override
  String deskNodeLineKernels(String done, String total) {
    return 'Kernels werden geprüft · $done von $total Mio.';
  }

  @override
  String get deskNodeLineKernelsBare => 'Kernels werden geprüft';

  @override
  String deskNodeLineRangeProofs(String done, String total) {
    return 'Range Proofs werden geprüft · $done von $total Mio.';
  }

  @override
  String get deskNodeLineRangeProofsBare => 'Range Proofs werden geprüft';

  @override
  String get deskNodeLineProcessing => 'Chain-Zustand wird verarbeitet';

  @override
  String deskNodeLineBlocks(String done, String total) {
    return 'Blöcke · $done von $total';
  }

  @override
  String get deskNodeLineBlocksBare => 'Blöcke';

  @override
  String get deskNodeLineCompacting => 'Chain-Daten werden komprimiert';

  @override
  String get deskNodeLineStopping => 'Wird beendet…';

  @override
  String get deskNodeLineSyncing => 'Synchronisierung';

  @override
  String get deskNodeNoEstimate => 'keine Schätzung; bis zu einer Stunde';

  @override
  String get deskNodeEstimating => 'wird geschätzt…';

  @override
  String deskNodeAboutHours(int hours) {
    return 'noch etwa $hours h';
  }

  @override
  String deskNodeAboutMinutes(int minutes) {
    return 'noch etwa $minutes Min.';
  }

  @override
  String deskNodeDurationHm(int hours, int minutes) {
    return '$hours h $minutes Min.';
  }

  @override
  String deskNodeDurationM(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get deskTorNetworkLabel => 'Tor-Netzwerk';

  @override
  String get deskTorNetworkHint =>
      'Die Netzwerkaktivität läuft über das Tor-Netzwerk. Tor verbirgt die Internetadresse der Wallet: Jede Verbindung geht über mehrere ehrenamtlich betriebene Relays, sodass kein Server erfährt, wo die Wallet ist.';

  @override
  String get deskTorOff => 'Aus';

  @override
  String get deskTorStarting => 'Startet…';

  @override
  String get deskTorOn => 'An';

  @override
  String get deskTorNotConnected => 'Nicht verbunden';

  @override
  String get deskTorRoutes =>
      'Epicbox, Node, Status, Kurse, Updates, Support und Tor-Adressen';

  @override
  String get deskTorCoverage =>
      'Über Tor: Epicbox, Node, Status, Kurse, Updates, Support und Tor-Adressen.';

  @override
  String get deskTorNodeOver => 'Über Tor';

  @override
  String get deskTorNodeNotEncrypted => 'Nach Tor nicht verschlüsselt';

  @override
  String get deskTorNodeWaits => 'Wartet, bis Tor verbunden ist.';

  @override
  String get deskRecvTitle => 'Empfangen';

  @override
  String get deskRecvReceiving => 'Empfang';

  @override
  String get deskRecvNameFile => 'Datei';

  @override
  String deskRecvTurnOnFailed(String method) {
    return '$method nicht eingeschaltet';
  }

  @override
  String deskRecvTurnOffFailed(String method) {
    return '$method nicht ausgeschaltet';
  }

  @override
  String get deskRecvOtherWays => 'Weitere Empfangswege';

  @override
  String get deskRecvSettings => 'Einstellungen';

  @override
  String get deskRecvTorNotConnected => 'Tor ist nicht verbunden.';

  @override
  String get deskRecvTorStarting => 'Tor startet.';

  @override
  String deskRecvTorDownText(String routes) {
    return 'Über $routes kommt nichts an, bis Tor verbunden ist oder ausgeschaltet wird.';
  }

  @override
  String get deskRecvTorStartingText =>
      'Die Adressen werden erreichbar, sobald Tor verbunden ist. Bis dahin geht nichts über das Clearnet.';

  @override
  String get deskRecvTurnTorOff => 'Tor ausschalten';

  @override
  String get deskRecvTryAgain => 'Erneut versuchen';

  @override
  String get deskRecvStateOn => 'an';

  @override
  String get deskRecvStateOff => 'aus';

  @override
  String get deskRecvStateChecking => 'wird geprüft';

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
    return '$method · Wird geprüft';
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
  String get deskRecvTagPaused => 'Pausiert';

  @override
  String get deskRecvTagStarting => 'Startet';

  @override
  String get deskRecvTagNotReachable => 'Nicht erreichbar';

  @override
  String get deskRecvAddressUnreadable =>
      'Die Adresse konnte nicht gelesen werden. Öffnen Sie Empfangen gleich noch einmal.';

  @override
  String get deskRecvEpicboxAddress => 'Epicbox-Adresse';

  @override
  String get deskRecvCopyEpicbox => 'Epicbox-Adresse kopieren';

  @override
  String get deskRecvEpicboxIntro =>
      'Teilen Sie sie, um bezahlt zu werden. Funktioniert auch bei geschlossener Wallet: Der Epicbox-Server hält Zahlungen, bis die Wallet wieder da ist.';

  @override
  String get deskRecvCheckSix =>
      'Beim Vorlesen die ersten sechs und letzten sechs Zeichen prüfen.';

  @override
  String get deskRecvHttpAddress => 'HTTP-Adresse';

  @override
  String get deskRecvCopyHttp => 'HTTP-Adresse kopieren';

  @override
  String deskRecvHttpPublic(int port) {
    return 'Die öffentliche Adresse Ihres Routers. Absender im Internet nutzen sie, sobald der Router Port $port weiterleitet.';
  }

  @override
  String get deskRecvHttpLocal =>
      'Programme auf diesem Computer können an diese Adresse zahlen. Für andere Geräte siehe Einstellungen › Empfangen.';

  @override
  String get deskRecvHttpIntro =>
      'Direkt von einer anderen Wallet, solange diese geöffnet ist. Nur auf diesem Computer, sofern die Einstellungen nichts anderes sagen.';

  @override
  String get deskRecvHttpTorHint =>
      'Schalten Sie Tor unter Einstellungen › Datenschutz ein, um stattdessen eine Tor-Adresse zu erhalten.';

  @override
  String get deskRecvDirectTor => 'Direkt, Tor-Adresse';

  @override
  String get deskRecvTorIntro =>
      'Direkt von einer anderen Wallet über Tor, solange diese geöffnet ist. Tor wird unter Einstellungen › Datenschutz eingestellt.';

  @override
  String get deskRecvTorAddress => 'Tor-Adresse';

  @override
  String get deskRecvCopyTor => 'Tor-Adresse kopieren';

  @override
  String get deskRecvTorOnion =>
      'Manche Wallets zeigen die Adresse ohne .onion; beides ist dieselbe Adresse.';

  @override
  String get deskRecvFiles => 'Transaktionsdateien';

  @override
  String get deskRecvSignTitle => 'Transaktionsdatei signieren';

  @override
  String get deskRecvSignText =>
      'Ein Absender hat Ihnen eine Transaktionsdatei gegeben. Die Wallet signiert sie und speichert eine Antwort für ihn.';

  @override
  String get deskRecvOpen => 'Öffnen';

  @override
  String get deskRecvFinalizeTitle => 'Antwortdatei abschließen';

  @override
  String get deskRecvFinalizeText =>
      'Eine Zahlung per Datei hat eine Antwort erhalten. Beim Abschließen wird die Zahlung an das Netzwerk gesendet.';

  @override
  String deskRecvSwitchLabel(String title) {
    return '$title, Empfang';
  }

  @override
  String get deskSendStrategySmallest => 'Kleinste';

  @override
  String get deskSendStrategyAll => 'Alle';

  @override
  String get deskSendBalanceAfter => 'Guthaben danach';

  @override
  String get deskSendSpendableUntil =>
      'Verfügbar, bis das Wechselgeld bestätigt ist';

  @override
  String deskSendSplitLine(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Wechselgeld aufgeteilt in $outputs Outputs (+$fee EPIC Gebühr)',
      one: 'Wechselgeld als $outputs Output (+$fee EPIC Gebühr)',
    );
    return '$_temp0';
  }

  @override
  String deskSendSplitWhy(int outputs, String each) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other:
          'Damit die nächste Zahlung nicht auf die Bestätigung dieser warten muss. Das Wechselgeld kommt als $outputs Outputs zu je etwa $each EPIC zurück statt als einer.',
      one:
          'Damit die nächste Zahlung nicht auf die Bestätigung dieser warten muss. Das Wechselgeld kommt als $outputs Output zu je etwa $each EPIC zurück statt als einer.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendSplitWhyLabel => 'Warum das Wechselgeld aufgeteilt wird';

  @override
  String deskSendLockNoChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Kein Wechselgeld: $count Outputs werden genau verbraucht, nichts wartet.',
      one: 'Kein Wechselgeld: 1 Output wird genau verbraucht, nichts wartet.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockAll(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alles ist gesperrt: $count Outputs, $amount EPIC, etwa 3 Blöcke.',
      one: 'Alles ist gesperrt: 1 Output, $amount EPIC, etwa 3 Blöcke.',
    );
    return '$_temp0';
  }

  @override
  String deskSendLockSome(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs gesperrt, $amount EPIC, etwa 3 Blöcke.',
      one: '1 Output gesperrt, $amount EPIC, etwa 3 Blöcke.',
    );
    return '$_temp0';
  }

  @override
  String deskSendStrategyLine(int count, String strategy) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Strategie für diese Zahlung: $strategy · $count Outputs.',
      one: 'Strategie für diese Zahlung: $strategy · 1 Output.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewSplit(int outputs, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      outputs,
      locale: localeName,
      other: 'Wechselgeld aufgeteilt in $outputs Outputs (+$fee EPIC).',
      one: 'Wechselgeld als $outputs Output (+$fee EPIC).',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksNone(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count Outputs; es kommt kein Wechselgeld zurück.',
      one: '$locked EPIC in 1 Output; es kommt kein Wechselgeld zurück.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alles: $locked EPIC in $count Outputs, bis das Wechselgeld bestätigt ist (3 Blöcke). Nichts bleibt verfügbar.',
      one:
          'Alles: $locked EPIC in 1 Output, bis das Wechselgeld bestätigt ist (3 Blöcke). Nichts bleibt verfügbar.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count Outputs, bis das Wechselgeld bestätigt ist (3 Blöcke). Bis dahin ist nichts anderes verfügbar.',
      one:
          '$locked EPIC in 1 Output, bis das Wechselgeld bestätigt ist (3 Blöcke). Bis dahin ist nichts anderes verfügbar.',
    );
    return '$_temp0';
  }

  @override
  String deskSendReviewLocksSome(int count, String locked, String spendable) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count Outputs, bis das Wechselgeld bestätigt ist (3 Blöcke). $spendable EPIC bleiben verfügbar.',
      one:
          '$locked EPIC in 1 Output, bis das Wechselgeld bestätigt ist (3 Blöcke). $spendable EPIC bleiben verfügbar.',
    );
    return '$_temp0';
  }

  @override
  String get deskSendFactLocks => 'Sperrt';

  @override
  String get deskSendFactStrategy => 'Strategie';

  @override
  String deskSendFactStrategyValue(String strategy) {
    return '$strategy Outputs, für diese Zahlung';
  }

  @override
  String get deskSendAdvSmallest => '· Kleinste Outputs';

  @override
  String get deskSendAdvSmallestNoSplit =>
      '· Kleinste Outputs, Wechselgeld nicht aufgeteilt';

  @override
  String get deskSendAdvAll => '· Alle Outputs';

  @override
  String get deskSendAdvAllNoSplit =>
      '· Alle Outputs, Wechselgeld nicht aufgeteilt';

  @override
  String get deskSendAdvanced => 'Erweitert';

  @override
  String get deskSendAdvStrategy => 'Strategie für diese Zahlung';

  @override
  String get deskSendAdvSmallestText =>
      'Verbraucht möglichst wenige kleine Outputs; der Rest des Guthabens bleibt verfügbar, während das Wechselgeld bestätigt wird.';

  @override
  String get deskSendAdvAllText =>
      'Verbraucht jeden verfügbaren Output und gibt einen Wechselgeld-Output zurück. Alles ist gesperrt, bis er bestätigt ist; danach weniger, größere Outputs.';

  @override
  String get deskSendDefaultTag => 'Standard';

  @override
  String get deskSendAdvAllNote => 'Wer alles sendet, verbraucht jeden Output.';

  @override
  String get deskSendAdvSplit => 'Wechselgeld aufteilen';

  @override
  String get deskSendAdvSplitText =>
      'Gibt das Wechselgeld als mehrere Outputs zurück, wenn nur wenige übrig blieben, damit die nächste Zahlung nicht warten muss.';

  @override
  String get deskSendAdvDefaults => 'Nur für diese Zahlung. Standardwerte: ';

  @override
  String get deskSendAdvOutputsLink => 'Outputs';

  @override
  String get deskSendPickNone => 'Noch keine Kontakte';

  @override
  String get deskSendPickNoneText =>
      'Speichern Sie die Personen, die Sie bezahlen, unter Kontakte und wählen Sie sie dann hier.';

  @override
  String get deskSendPickOpen => 'Kontakte öffnen';

  @override
  String deskSendPickNoMatch(String query) {
    return 'Kein Kontakt passt zu „$query“.';
  }

  @override
  String get deskSendPickTitle => 'Kontakt wählen';

  @override
  String get deskSendPickDesc =>
      'Die Adresse wird ins Empfängerfeld übernommen.';

  @override
  String get deskSendPickSearch => 'Kontakte durchsuchen';

  @override
  String get deskSendTitle => 'Senden';

  @override
  String get deskSendErrNoAddress => 'Geben Sie eine Empfängeradresse ein.';

  @override
  String get deskSendErrEpicbox => 'Das ist keine gültige Epicbox-Adresse.';

  @override
  String get deskSendErrNotDirect => 'Das ist keine Direkt-Adresse.';

  @override
  String get deskSendErrOnion => 'Das ist keine gültige Onion-Adresse.';

  @override
  String get deskSendErrOwn => 'Das ist die eigene Adresse dieser Wallet.';

  @override
  String get deskSendNoAnswer =>
      'Der Empfänger hat nicht geantwortet. Es wurde nichts gesendet.';

  @override
  String get deskSendTorOnFailed => 'Tor nicht eingeschaltet';

  @override
  String get deskSendTorOffFailed => 'Tor nicht ausgeschaltet';

  @override
  String get deskSendEpicboxOnFailed => 'Epicbox nicht eingeschaltet';

  @override
  String get deskSendNothingSpendable => 'Nichts Verfügbares zum Senden.';

  @override
  String get deskSendAllFailed =>
      'Der sendbare Betrag konnte nicht ermittelt werden. Versuchen Sie es gleich noch einmal.';

  @override
  String get deskSendErrAmountEnter => 'Geben Sie einen Betrag ein.';

  @override
  String get deskSendErrAmountDecimals =>
      'EPIC hat höchstens 8 Nachkommastellen.';

  @override
  String get deskSendErrAmountZero => 'Der Betrag muss größer als 0 sein.';

  @override
  String get deskSendErrAmountMore => 'Mehr als das verfügbare Guthaben.';

  @override
  String get deskSendSent => 'Gesendet';

  @override
  String get deskSendFileReadyTitle => 'Transaktionsdatei bereit';

  @override
  String get deskSendFileReadyText =>
      'Geben Sie diese Datei dem Empfänger. Die Wallet wartet auf die Antwortdatei; schließen Sie sie ab, wenn sie zurückkommt.';

  @override
  String get deskSendFinalize => 'Abschließen';

  @override
  String get deskSendNewSend => 'Neue Zahlung';

  @override
  String get deskSendNodeNotSynced => 'Node nicht synchronisiert';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Senden ist möglich, sobald der Node synchronisiert ist. $percent % erledigt; das Formular können Sie schon ausfüllen.';
  }

  @override
  String get deskSendNodeSyncing =>
      'Senden ist möglich, sobald der Node synchronisiert ist.';

  @override
  String get deskSendTorBlocked => 'Tor ist nicht verbunden';

  @override
  String get deskSendTorBlockedText =>
      'Es wird nichts gesendet, bis Tor verbunden ist oder ausgeschaltet wird.';

  @override
  String get deskSendTurnTorOff => 'Tor ausschalten';

  @override
  String get deskSendTorStarting => 'Tor startet';

  @override
  String get deskSendTorStartingText =>
      'Das Senden wartet, bis Tor verbunden ist. Bis dahin geht nichts über das Clearnet.';

  @override
  String get deskSendEpicboxOff => 'Epicbox nicht verbunden';

  @override
  String get deskSendEpicboxOffText =>
      'Zahlungen über Epicbox funktionieren, sobald der Epicbox-Empfang an ist. Senden Sie bis dahin per Datei.';

  @override
  String get deskSendEpicboxTurnOn => 'Epicbox-Empfang einschalten';

  @override
  String get deskSendDoneViaDirect =>
      'Abgeschlossen und an das Netzwerk gesendet.';

  @override
  String get deskSendDoneViaEpicbox =>
      'An Epicbox übergeben. Wird abgeschlossen, sobald der Empfänger antwortet.';

  @override
  String get deskSendViewTx => 'Transaktion anzeigen';

  @override
  String get deskSendFailedTitle => 'Senden fehlgeschlagen';

  @override
  String get deskSendReviewAgain => 'Erneut prüfen';

  @override
  String get deskSendMethodDirect => 'Direkt';

  @override
  String get deskSendMethodFile => 'Datei';

  @override
  String get deskSendTo => 'An';

  @override
  String get deskSendToHelp =>
      'Fügen Sie eine Adresse ein oder tippen Sie den Namen eines Kontakts.';

  @override
  String get deskSendToHint => 'Adresse oder Kontakt';

  @override
  String get deskSendToSem => 'Empfänger';

  @override
  String get deskSendClearTo => 'Empfänger löschen';

  @override
  String get deskSendContacts => 'Kontakte';

  @override
  String get deskSendNeedsTor => 'Benötigt Tor';

  @override
  String get deskSendNeedsTorText =>
      'Eine Onion-Adresse ist nur über Tor erreichbar.';

  @override
  String get deskSendNoTorBuild => 'Tor ist in dieser Version nicht enthalten.';

  @override
  String get deskSendTurnOnTor => 'Tor einschalten';

  @override
  String get deskSendHttpClearnet =>
      'Direkt an http(s)-Adressen läuft über das Clearnet, nicht über Tor.';

  @override
  String get deskSendClear => 'Entfernen';

  @override
  String get deskSendAmount => 'Betrag';

  @override
  String get deskSendAvailableNone => 'Verfügbar —';

  @override
  String deskSendAvailable(String amount) {
    return 'Verfügbar $amount EPIC';
  }

  @override
  String get deskSendAmountSem => 'Betrag in EPIC';

  @override
  String get deskSendAllButton => 'Alles';

  @override
  String get deskSendConfirmingHidden =>
      'Ein Teil des Guthabens wird noch bestätigt und kann noch nicht gesendet werden.';

  @override
  String deskSendConfirming(String amount) {
    return '$amount EPIC werden noch bestätigt und können noch nicht gesendet werden.';
  }

  @override
  String get deskSendMessage => 'Nachricht';

  @override
  String get deskSendMessageHelp => 'Der Empfänger sieht diese Nachricht.';

  @override
  String get deskSendPrivacyOn => 'Privatsphäre · Dandelion++ an';

  @override
  String get deskSendPrivacyOff => 'Privatsphäre · Dandelion++ aus';

  @override
  String get deskSendDandelionText =>
      'Leitet die Transaktion über einige zufällige Nodes, bevor sie sich verbreitet, sodass das Netzwerk nicht erkennt, woher sie kam.';

  @override
  String get deskSendHintSent =>
      'Gesendet. Geben Sie einen neuen Betrag und Empfänger ein, um erneut zu senden.';

  @override
  String get deskSendHintNode => 'Warten, bis der Node synchronisiert ist.';

  @override
  String get deskSendHintEpicbox => 'Warten auf die Verbindung zu Epicbox.';

  @override
  String get deskSendHintTorWait => 'Warten auf die Verbindung zu Tor.';

  @override
  String get deskSendHintTorBlocked => 'Tor erneut versuchen oder ausschalten.';

  @override
  String get deskSendHintNeedsTor =>
      'Schalten Sie Tor ein, um an eine Onion-Adresse zu senden.';

  @override
  String get deskSendHintFix => 'Korrigieren Sie die rot markierten Felder.';

  @override
  String get deskSendHintChecking =>
      'Die Gebühr für diesen Betrag wird geprüft.';

  @override
  String get deskSendHintDefault =>
      'Gesendet wird erst nach Ihrer Bestätigung.';

  @override
  String get deskSendReviewWaitTor => 'Warten auf Tor';

  @override
  String get deskSendReviewTorOff => 'Tor nicht verbunden';

  @override
  String get deskSendReview => 'Zahlung prüfen';

  @override
  String get deskSendSummary => 'Übersicht';

  @override
  String get deskSendNetworkFee => 'Netzwerkgebühr';

  @override
  String get deskSendTotal => 'Gesamt';

  @override
  String get deskSendUpdating =>
      'Das Guthaben wird aktualisiert, während die Wallet scannt.';

  @override
  String get deskSendEpicboxLine1 => 'Der Empfänger kann offline sein.';

  @override
  String get deskSendEpicboxLine2 =>
      'Der Epicbox-Server hält die Zahlung, bis der Empfänger seine Wallet öffnet.';

  @override
  String get deskSendDirectLine1 => 'Direkt an die Wallet des Empfängers.';

  @override
  String get deskSendDirectLine2 =>
      'Eine http(s)- oder .onion-Adresse; Onion läuft über Tor. Die Wallet des Empfängers muss geöffnet sein.';

  @override
  String get deskSendFileLine1 => 'Keine Verbindung nötig.';

  @override
  String get deskSendFileLine2 =>
      'Datei übergeben, Antwortdatei zurückbekommen, dann hier abschließen.';

  @override
  String get deskSendTagDirect => 'Direkt';

  @override
  String get deskSendTagFile => 'Datei';

  @override
  String get deskSendTagEpicbox => 'Über Epicbox';

  @override
  String get deskSendSwitchedDirect =>
      'Direkt-Adresse. Methode auf Direkt gestellt.';

  @override
  String get deskSendSwitchedFile =>
      'Datei-Adresse. Methode auf Datei gestellt.';

  @override
  String get deskSendSwitchedEpicbox =>
      'Epicbox-Adresse. Methode auf Epicbox gestellt.';

  @override
  String get deskSendMatching => 'Passende Kontakte';

  @override
  String deskSendMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte passen',
      one: '1 Kontakt passt',
    );
    return '$_temp0';
  }

  @override
  String get deskSendWrongPassword => 'Falsches Passwort.';

  @override
  String get deskSendNotConfirmed =>
      'Nicht bestätigt. Prüfen Sie die Aktivität, bevor Sie erneut senden.';

  @override
  String get deskSendViaEpicbox => 'Epicbox (der Empfänger kann offline sein)';

  @override
  String get deskSendViaDirect =>
      'Direkt (die Wallet des Empfängers muss geöffnet sein)';

  @override
  String get deskSendViaTor =>
      'Direkt über Tor (die Wallet des Empfängers muss geöffnet sein)';

  @override
  String get deskSendViaFile => 'Transaktionsdatei';

  @override
  String deskSendUsesAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nutzt alle $count Outputs · Wechselgeld 1 Output',
      one: 'Nutzt den 1 Output · Wechselgeld 1 Output',
    );
    return '$_temp0';
  }

  @override
  String get deskSendReviewTitle => 'Prüfen und senden';

  @override
  String get deskSendReviewDesc =>
      'Eine gesendete Zahlung lässt sich nicht rückgängig machen.';

  @override
  String get deskSendFactTo => 'An';

  @override
  String get deskSendCheckChars =>
      'Vergleichen Sie die hervorgehobenen Zeichen mit der Adresse, die Ihnen der Empfänger gegeben hat.';

  @override
  String get deskSendFactVia => 'Über';

  @override
  String get deskSendFactPrivacy => 'Privatsphäre';

  @override
  String get deskSendDandelionOn => 'Dandelion++ an';

  @override
  String get deskSendDandelionOff => 'Dandelion++ aus';

  @override
  String get deskSendFactMessage => 'Nachricht';

  @override
  String get deskSendPassword => 'Passwort';

  @override
  String get deskSendPasswordHelp =>
      'Mit gespeichertem Passwort geöffnet: Für diese Zahlung wird es abgefragt.';

  @override
  String get deskSendBusyFile => 'Die Datei wird erstellt.';

  @override
  String get deskSendBusyTor =>
      'Die Wallet des Empfängers wird über Tor erreicht… Das kann dauern. Lassen Sie die App geöffnet.';

  @override
  String get deskSendBusy =>
      'Wird gesendet. Das kann einige Sekunden dauern; lassen Sie dieses Fenster geöffnet.';

  @override
  String get deskSendBack => 'Zurück';

  @override
  String get deskSendSending => 'Wird gesendet';

  @override
  String deskSendConfirm(String amount) {
    return '$amount EPIC senden';
  }

  @override
  String get deskSendPlainTitle => 'Nicht verschlüsselt. Trotzdem senden?';

  @override
  String get deskSendPlainDesc =>
      'Unverschlüsseltes HTTP zu einem anderen Computer. Jeder auf dem Weg kann die Transaktion lesen. https:// ist verschlüsselt.';

  @override
  String get deskSendPlainConfirm => 'Trotzdem senden';

  @override
  String deskSendEpicboxSwitched(String domain) {
    return 'Gewechselt zu $domain';
  }

  @override
  String get deskSendEpicboxNotSwitched => 'Nicht gewechselt';

  @override
  String get deskSendEpicboxDownTitle => 'Epicbox-Server antwortet nicht';

  @override
  String get deskSendEpicboxDownWait =>
      'Zahlungen warten, bis er wieder da ist.';

  @override
  String deskSendEpicboxSwitchTo(String domain) {
    return 'Zu $domain wechseln?';
  }

  @override
  String get deskSendEpicboxSwitch => 'Wechseln';

  @override
  String get deskFinOpenFolder => 'Ordner öffnen';

  @override
  String get deskFinFolderNotOpened => 'Ordner nicht geöffnet';

  @override
  String get deskFinWrongType => 'Keine Antwortdatei';

  @override
  String get deskFinWrongTypeText =>
      'Die Datei ist keine Antwortdatei. Wählen Sie die Datei, die der Empfänger zurückgeschickt hat.';

  @override
  String get deskFinUnreadable => 'Datei nicht lesbar';

  @override
  String get deskFinUnreadableText =>
      'Die Datei konnte nicht gelesen werden. Sie ist vielleicht beschädigt oder wird noch kopiert.';

  @override
  String get deskFinFailed => 'Abschließen fehlgeschlagen';

  @override
  String get deskFinFailedText =>
      'Die Wallet konnte diese Datei nicht abschließen. Sie gehört vielleicht zu einer anderen Transaktion oder ist bereits abgeschlossen.';

  @override
  String get deskFinNotPosted => 'Nicht im Netzwerk';

  @override
  String get deskFinNotPostedText =>
      'Die Transaktion wurde abgeschlossen, aber der Node hat sie nicht angenommen. Prüfen Sie den Node und versuchen Sie es erneut.';

  @override
  String get deskFinPickTitle => 'Antwortdatei';

  @override
  String get deskFinPosted => 'Transaktion gesendet';

  @override
  String get deskFinTitle => 'Antwortdatei abschließen';

  @override
  String get deskFinNoticeTitle => 'Für eine als Datei erstellte Transaktion';

  @override
  String get deskFinNoticeText =>
      'Verwenden Sie die Antwortdatei, die der Empfänger zurückgeschickt hat.';

  @override
  String get deskFinTryAgain => 'Erneut versuchen';

  @override
  String get deskFinPostedText =>
      'Die Zahlung wurde abgeschlossen und an das Netzwerk gesendet. Verfolgen Sie sie unter Aktivität.';

  @override
  String get deskFinAnother => 'Weitere Datei abschließen';

  @override
  String get deskFinViewActivity => 'In Aktivität anzeigen';

  @override
  String get deskFinBusy => 'Wird abgeschlossen und gesendet';

  @override
  String get deskFinChoose => 'Antwortdatei wählen';

  @override
  String get deskFinChooseText =>
      'Die Wallet schließt die Transaktion ab und sendet sie an das Netzwerk.';

  @override
  String get deskFinChooseFile => 'Datei wählen';

  @override
  String get deskImpWrongType => 'Keine Transaktionsdatei';

  @override
  String get deskImpWrongTypeText =>
      'Die Datei ist keine Transaktionsdatei. Wählen Sie die .slate- oder .tx-Datei, die Ihnen der Absender gegeben hat.';

  @override
  String get deskImpUnreadable => 'Datei nicht lesbar';

  @override
  String get deskImpUnreadableText =>
      'Die Datei konnte nicht gelesen werden. Sie ist vielleicht beschädigt oder wird noch kopiert.';

  @override
  String get deskImpNoPlace => 'Nichts signiert';

  @override
  String get deskImpNoPlaceText =>
      'Es wurde kein Speicherort für die Antwortdatei gewählt, daher wurde nichts signiert.';

  @override
  String get deskImpFailed => 'Signieren fehlgeschlagen';

  @override
  String get deskImpFailedText =>
      'Die Wallet konnte diese Datei nicht signieren. Sie ist vielleicht für eine andere Wallet oder schon verwendet.';

  @override
  String deskImpFailedDetail(String detail) {
    return 'Die Wallet konnte diese Datei nicht signieren. Sie ist vielleicht für eine andere Wallet oder schon verwendet. $detail.';
  }

  @override
  String get deskImpPickTitle => 'Transaktionsdatei';

  @override
  String get deskImpTitle => 'Transaktionsdatei signieren';

  @override
  String get deskImpNoticeTitle => 'Signieren gibt nichts aus';

  @override
  String get deskImpNoticeText =>
      'Schicken Sie die Antwortdatei auf demselben Weg an den Absender zurück, auf dem er sie Ihnen geschickt hat.';

  @override
  String get deskImpSaved => 'Antwort gespeichert';

  @override
  String get deskImpSavedText =>
      'Schicken Sie die Antwortdatei an den Absender zurück. Die EPIC kommen an, sobald der Absender sie abschließt.';

  @override
  String get deskImpAmount => 'Betrag ';

  @override
  String get deskImpAnother => 'Weitere Datei signieren';

  @override
  String get deskImpBusy => 'Die Datei wird signiert';

  @override
  String get deskImpChoose => 'Transaktionsdatei wählen';

  @override
  String get deskImpChooseText =>
      'Die Wallet signiert sie und speichert eine Antwort für den Absender.';

  @override
  String get deskActNotUpdated => 'Nicht aktualisiert';

  @override
  String get deskActSearchHint => 'Adresse oder Slate-ID';

  @override
  String get deskActSearchHintEmpty => 'Noch nichts zu suchen';

  @override
  String get deskActSearchLabel => 'Transaktionen durchsuchen';

  @override
  String get deskActClearSearch => 'Suche löschen';

  @override
  String get deskActShowAmounts => 'Beträge anzeigen';

  @override
  String get deskActHideAmounts => 'Beträge verbergen';

  @override
  String get deskActRefresh => 'Aktualisieren';

  @override
  String get deskActTitle => 'Aktivität';

  @override
  String get deskActDetailReceived => 'Empfangene Transaktion';

  @override
  String get deskActDetailSent => 'Gesendete Transaktion';

  @override
  String get deskActLoading => 'Transaktionen werden geladen';

  @override
  String get deskActWaitingNode => 'Warten, bis der Node synchronisiert ist.';

  @override
  String get deskActFilterAll => 'Alle';

  @override
  String get deskActFilterReceived => 'Empfangen';

  @override
  String get deskActFilterSent => 'Gesendet';

  @override
  String get deskActNoMatchTitle => 'Keine passenden Transaktionen';

  @override
  String get deskActNoMatchText =>
      'Versuchen Sie eine andere Adresse oder Slate-ID, oder setzen Sie den Filter zurück.';

  @override
  String deskActPageOf(int page, int pages) {
    return 'Seite $page von $pages';
  }

  @override
  String get deskActPrevPage => 'Vorherige Seite';

  @override
  String get deskActNextPage => 'Nächste Seite';

  @override
  String get deskActPages => 'Seiten';

  @override
  String get deskActColFromTo => 'Von / an';

  @override
  String get deskActColStatus => 'Status';

  @override
  String get deskActColTime => 'Uhrzeit';

  @override
  String get deskActColAmount => 'Betrag';

  @override
  String get deskActEmptyTitle => 'Noch keine Transaktionen';

  @override
  String get deskActEmptyText =>
      'Jede gesendete oder empfangene Zahlung steht hier, die neueste zuerst, mit Gegenseite und Stand.';

  @override
  String get deskActStageWaiting => 'Wartet';

  @override
  String get deskActStageWaitingText =>
      'Beide Wallets signieren sie. Über Epicbox geschieht das automatisch.';

  @override
  String get deskActStageConfirming => 'Wird bestätigt';

  @override
  String get deskActStageConfirmingText =>
      'In der Blockchain. Etwa ein Block pro Minute.';

  @override
  String get deskActStageSpendable => 'Verfügbar';

  @override
  String deskActStageSpendableText(int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'Nach $needed Bestätigungen, etwa $needed Minuten.',
      one: 'Nach $needed Bestätigung, etwa $needed Minute.',
    );
    return '$_temp0';
  }

  @override
  String get deskActShowAddress => 'Adresse anzeigen';

  @override
  String get deskActReceiveFile => 'Datei empfangen';

  @override
  String get deskConTitle => 'Kontakte';

  @override
  String get deskConLoading => 'Kontakte werden geladen';

  @override
  String get deskConNewTitle => 'Neuer Kontakt';

  @override
  String get deskConEditTitle => 'Kontakt bearbeiten';

  @override
  String get deskConDetailsTitle => 'Details';

  @override
  String get deskConSearchHint => 'Name oder Adresse';

  @override
  String get deskConSearchLabel => 'Kontakte durchsuchen';

  @override
  String get deskConClearSearch => 'Suche löschen';

  @override
  String deskConCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte',
      one: '$count Kontakt',
    );
    return '$_temp0';
  }

  @override
  String get deskConNoMatches => 'Keine Treffer';

  @override
  String deskConMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '$count Treffer',
    );
    return '$_temp0';
  }

  @override
  String get deskConSortName => 'Name';

  @override
  String get deskConSortRecent => 'Zuletzt';

  @override
  String get deskConNone => 'Noch keine Kontakte.';

  @override
  String get deskConNoMatchList => 'Keine passenden Kontakte';

  @override
  String get deskConAdd => 'Kontakt hinzufügen';

  @override
  String get deskConIdle =>
      'Wählen Sie einen Kontakt, um die Details zu sehen, an ihn zu senden, ihn zu bearbeiten oder zu löschen.';

  @override
  String get deskConEmptyTitle => 'Noch keine Kontakte';

  @override
  String get deskConEmptyText =>
      'Speichern Sie Personen und Shops, die Sie oft bezahlen. Unter Senden wählen Sie dann einen Namen, statt eine Adresse einzufügen.';

  @override
  String get deskConEmptyLocal =>
      'Kontakte bleiben auf diesem Computer. Sie sind nicht Teil der Wiederherstellungsphrase.';

  @override
  String get deskConSendToAddress => 'An Adresse senden';

  @override
  String deskConLastTx(String when) {
    return 'Letzte Transaktion: $when';
  }

  @override
  String get deskConSend => 'Senden';

  @override
  String get deskConEdit => 'Bearbeiten';

  @override
  String get deskConStar => 'Favorit';

  @override
  String get deskConUnstar => 'Kein Favorit';

  @override
  String get deskConDelete => 'Löschen';

  @override
  String get deskConNotDeleted => 'Nicht gelöscht';

  @override
  String deskConDeleted(String name) {
    return '$name wurde gelöscht';
  }

  @override
  String get deskConAddrEpicbox => 'Epicbox-Adresse';

  @override
  String get deskConAddrTor => 'Tor-Adresse';

  @override
  String get deskConAddrHttp => 'HTTP-Adresse';

  @override
  String get deskConNote => 'Notiz';

  @override
  String deskConTxWith(String name) {
    return 'Transaktionen mit $name';
  }

  @override
  String get deskConAllTx => 'Alle Transaktionen';

  @override
  String get deskConTxNone =>
      'Noch keine Transaktionen mit diesem Kontakt. Zahlungen, die Sie ihm unter Senden schicken, erscheinen hier.';

  @override
  String get deskConTxReceived => 'Empfangen';

  @override
  String get deskConTxSent => 'Gesendet';

  @override
  String get deskConErrName => 'Geben Sie dem Kontakt einen Namen.';

  @override
  String get deskConErrAddressEmpty => 'Geben Sie eine Adresse ein.';

  @override
  String get deskConErrAddressInvalid => 'Keine erkannte Adresse';

  @override
  String get deskConAddPicture => 'Bild hinzufügen';

  @override
  String get deskConChangePicture => 'Bild ändern';

  @override
  String get deskConRemovePicture => 'Entfernen';

  @override
  String get deskConPictureHelp =>
      'PNG, JPEG, WebP oder GIF, bis 10 MB. Eine kleine Kopie wird in dieser App gespeichert.';

  @override
  String get deskConFieldName => 'Name';

  @override
  String get deskConFieldAddress => 'Adresse';

  @override
  String get deskConSaveFailed => 'Kontakt nicht gespeichert';

  @override
  String get deskConSave => 'Kontakt speichern';

  @override
  String deskConDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get deskConDeleteBody =>
      'Adresse und Notiz des Kontakts werden aus dieser Wallet entfernt. Frühere Transaktionen bleiben unter Aktivität. Das lässt sich nicht rückgängig machen.';

  @override
  String get deskConKeep => 'Kontakt behalten';

  @override
  String get deskConDeleteAction => 'Kontakt löschen';

  @override
  String get deskOutNotUpdated => 'Nicht aktualisiert';

  @override
  String get deskOutTitle => 'Outputs';

  @override
  String get deskOutShowAmounts => 'Beträge anzeigen';

  @override
  String get deskOutHideAmounts => 'Beträge verbergen';

  @override
  String get deskOutRefresh => 'Aktualisieren';

  @override
  String get deskOutLockedNote =>
      'Gesperrte Outputs werden von einer laufenden Transaktion ausgegeben. Ihr Wechselgeld erscheint als „Wartet auf Abschluss“ und zählt erst zu Gesamt, wenn die Zahlung abgeschlossen ist, damit Gesamt die Coins nur einmal zählt.';

  @override
  String get deskOutIntro =>
      'Outputs sind die Stücke, aus denen das Guthaben besteht. Eine Zahlung verbraucht ganze Outputs, zahlt den Empfänger und gibt den Rest als neuen Output zurück; die verbrauchten sind gesperrt, bis die Zahlung bestätigt ist.';

  @override
  String deskOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs',
      one: '$count Output',
    );
    return '$_temp0';
  }

  @override
  String get deskOutCardWait =>
      'Warten Sie, bis die Zahlung bestätigt ist (etwa 3 Blöcke).';

  @override
  String get deskOutSplitNothing => 'Noch nichts zum Aufteilen.';

  @override
  String deskOutSplitSpends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbraucht $count Outputs.',
      one: 'Verbraucht $count Output.',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitSpendsFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbraucht $count Outputs. Gebühr ab $fee EPIC.',
      one: 'Verbraucht $count Output. Gebühr ab $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutConsNothing => 'Noch nichts zum Zusammenführen.';

  @override
  String get deskOutConsOne =>
      'Nichts zum Zusammenführen: ein verfügbarer Output.';

  @override
  String deskOutConsInto(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs zu 1.',
      one: '$count Output zu 1.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsIntoFee(int count, String fee) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs zu 1. Gebühr $fee EPIC.',
      one: '$count Output zu 1. Gebühr $fee EPIC.',
    );
    return '$_temp0';
  }

  @override
  String get deskOutSplitCardTitle => 'Aufteilen';

  @override
  String get deskOutSplitCardText =>
      'Macht aus dem verfügbaren Guthaben mehr Outputs, damit mehrere Zahlungen ohne Warten aufeinander folgen können.';

  @override
  String get deskOutSplitCardButton => 'Aufteilen…';

  @override
  String get deskOutConsCardTitle => 'Zusammenführen';

  @override
  String get deskOutConsCardText =>
      'Führt jeden verfügbaren Output zu einem zusammen. Kleinere Gebühren bei der nächsten Zahlung; alles ist gesperrt, bis er bestätigt ist.';

  @override
  String get deskOutConsCardButton => 'Zusammenführen…';

  @override
  String get deskOutNotLoadedTitle => 'Outputs nicht geladen';

  @override
  String get deskOutNotLoadedText =>
      'Aktualisieren Sie, um es erneut zu versuchen.';

  @override
  String get deskOutLoading => 'Wallet-Daten werden geladen';

  @override
  String get deskOutNoneTitle => 'Noch keine Outputs';

  @override
  String get deskOutNoneText =>
      'Die erste empfangene Zahlung erzeugt einen. Aufteilen und Zusammenführen brauchen etwas, womit sie arbeiten können.';

  @override
  String get deskOutFilterAll => 'Alle';

  @override
  String get deskOutFilterSpendable => 'Verfügbar';

  @override
  String get deskOutFilterConfirming => 'Wird bestätigt';

  @override
  String get deskOutFilterLocked => 'Gesperrt';

  @override
  String get deskOutSearchHint => 'Commitment';

  @override
  String get deskOutSearchLabel => 'Outputs durchsuchen';

  @override
  String get deskOutClearSearch => 'Suche löschen';

  @override
  String get deskOutShowSpent => 'Ausgegebene zeigen';

  @override
  String get deskOutNoMatchTitle => 'Keine passenden Outputs';

  @override
  String get deskOutNoMatchText =>
      'Versuchen Sie ein anderes Commitment, oder setzen Sie den Filter zurück.';

  @override
  String get deskOutClearFilter => 'Filter zurücksetzen';

  @override
  String get deskOutTileSpendable => 'Verfügbar';

  @override
  String get deskOutTileConfirming => 'Wird bestätigt';

  @override
  String get deskOutTileImmature => 'Unreif';

  @override
  String get deskOutTileLocked => 'In Zahlungen gesperrt';

  @override
  String get deskOutTileTotal => 'Gesamt';

  @override
  String get deskOutDefaultsTitle => 'Standards für Zahlungen';

  @override
  String get deskOutStrategyTitle => 'Strategie für Zahlungen';

  @override
  String get deskOutStrategyText =>
      'Welche Outputs eine Zahlung verbraucht. Unter Senden › Erweitert lässt sich das für eine Zahlung ändern.';

  @override
  String get deskOutStrategySmallest => 'Kleinste';

  @override
  String get deskOutStrategyAll => 'Alle';

  @override
  String get deskOutStrategyHelp =>
      'Kleinste verbraucht möglichst wenige kleine Outputs und lässt den Rest verfügbar. Alle verbraucht alles und gibt einen Output zurück.';

  @override
  String get deskOutStrategyHelpTitle => 'Kleinste oder Alle';

  @override
  String get deskOutSplitChangeTitle => 'Wechselgeld aufteilen';

  @override
  String get deskOutSplitChangeText =>
      'Blieben nach einer Zahlung weniger als 3 verfügbare Outputs übrig, kommt ihr Wechselgeld als bis zu 4 Outputs zurück. Kostet 0,004 EPIC je zusätzlichem Output.';

  @override
  String get deskOutColValue => 'Wert';

  @override
  String get deskOutColStatus => 'Status';

  @override
  String get deskOutColConfirmations => 'Bestätigungen';

  @override
  String get deskOutColHeight => 'Höhe';

  @override
  String get deskOutColTransaction => 'Transaktion';

  @override
  String get deskOutColCommitment => 'Commitment';

  @override
  String get deskOutStatusSpendable => 'Verfügbar';

  @override
  String get deskOutStatusConfirming => 'Wird bestätigt';

  @override
  String deskOutConfirmations(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number Bestätigungen',
      one: '$number Bestätigung',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusAwaiting => 'Wartet auf Abschluss';

  @override
  String get deskOutNoteWaitingSender => 'wartet auf den Absender';

  @override
  String get deskOutStatusUnpaid => 'Unbezahlte Rechnung';

  @override
  String get deskOutNoteNotInBalance => 'nicht im Guthaben';

  @override
  String get deskOutStatusImmature => 'Unreif';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $number Blöcke',
      one: 'noch $number Block',
    );
    return '$_temp0';
  }

  @override
  String get deskOutStatusMining => 'Mining';

  @override
  String get deskOutStatusLocked => 'Gesperrt';

  @override
  String deskOutNoteBySend(int id) {
    return 'durch Zahlung #$id';
  }

  @override
  String get deskOutStatusSpent => 'Ausgegeben';

  @override
  String deskOutTxReceived(String date) {
    return 'Empfangen $date';
  }

  @override
  String deskOutTxSent(String date) {
    return 'Gesendet $date';
  }

  @override
  String deskOutCopyCommitment(String short) {
    return 'Commitment $short kopieren';
  }

  @override
  String deskOutSplitSpentPart(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs ($amount EPIC)',
      one: '$count Output ($amount EPIC)',
    );
    return '$_temp0';
  }

  @override
  String deskOutSplitMadePart(int count, String amount) {
    return '$count Outputs zu etwa $amount EPIC';
  }

  @override
  String deskOutConsMadePart(String amount) {
    return 'einen Output über $amount EPIC';
  }

  @override
  String deskOutSplitDialogText(String spent, String made) {
    return 'Verbraucht $spent und erzeugt $made. Eine normale Netzwerktransaktion an diese Wallet, nach 3 Blöcken bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt.';
  }

  @override
  String deskOutConsDialogText(String spent, String made) {
    return 'Verbraucht $spent und erzeugt $made. Eine normale Netzwerktransaktion an diese Wallet, nach 3 Blöcken bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt. Die nächste Zahlung verbraucht einen Output, daher ist ihre Gebühr am kleinsten.';
  }

  @override
  String get deskOutFactFee => 'Netzwerkgebühr';

  @override
  String get deskOutFactEach => 'Jeder Output';

  @override
  String deskOutFactAbout(String amount) {
    return 'etwa $amount EPIC';
  }

  @override
  String get deskOutFactLocked => 'Gesperrt';

  @override
  String deskOutFactLockedValue(String amount) {
    return '$amount EPIC, etwa 3 Blöcke. Nichts bleibt verfügbar.';
  }

  @override
  String get deskOutMakeLabel => 'Zu erzeugende Outputs';

  @override
  String get deskOutMakeRange => '2 bis 10.';

  @override
  String get deskOutStepperFewer => 'Weniger';

  @override
  String get deskOutStepperMore => 'Mehr';

  @override
  String get deskOutFeeWorking => 'Gebühr wird berechnet';

  @override
  String get deskOutNoEstimate => 'Keine Schätzung';

  @override
  String get deskOutEachMin =>
      'Jeder Output muss mindestens 0,5 EPIC betragen.';

  @override
  String get deskOutNotEnoughFee => 'Nicht genug, um die Gebühr zu zahlen.';

  @override
  String deskOutSplitInto(int count) {
    return 'In $count aufteilen';
  }

  @override
  String get deskOutConsolidateButton => 'Zusammenführen';

  @override
  String get deskOutPostingSplit =>
      'Die Aufteilung wird erstellt und gesendet. Lassen Sie die App geöffnet.';

  @override
  String get deskOutPostingCons =>
      'Die Zusammenführung wird erstellt und gesendet. Lassen Sie die App geöffnet.';

  @override
  String get deskOutSplitPosted => 'Aufteilung gesendet';

  @override
  String get deskOutConsPosted => 'Zusammenführung gesendet';

  @override
  String deskOutSplitDoneText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die Wallet hat jetzt $count Outputs zu je etwa $amount EPIC, die bestätigt werden. Alles ist gesperrt, bis sie bestätigt sind (3 Blöcke). Die Aktivität zeigt zwei Einträge: eine gesendete und eine empfangene Zahlung, beide an diese Wallet.',
      one:
          'Die Wallet hat jetzt $count Output zu etwa $amount EPIC, der bestätigt wird. Alles ist gesperrt, bis er bestätigt ist (3 Blöcke). Die Aktivität zeigt zwei Einträge: eine gesendete und eine empfangene Zahlung, beide an diese Wallet.',
    );
    return '$_temp0';
  }

  @override
  String deskOutConsDoneText(String amount) {
    return 'Ein Output über $amount EPIC, wird bestätigt. Alles ist gesperrt, bis er bestätigt ist (3 Blöcke). Die Aktivität zeigt zwei Einträge: eine gesendete und eine empfangene Zahlung, beide an diese Wallet.';
  }

  @override
  String get deskOutNotPostedTitle => 'Nicht im Netzwerk.';

  @override
  String get deskOutNotPostedSplit =>
      'Die Aufteilung wurde erstellt und gespeichert, aber der Node hat sie nicht angenommen. Übertragen Sie sie erneut, oder stornieren Sie sie, um die Outputs freizugeben.';

  @override
  String get deskOutNotPostedCons =>
      'Die Zusammenführung wurde erstellt und gespeichert, aber der Node hat sie nicht angenommen. Übertragen Sie sie erneut, oder stornieren Sie sie, um die Outputs freizugeben.';

  @override
  String get deskOutCancelSplit => 'Aufteilung stornieren';

  @override
  String get deskOutCancelCons => 'Zusammenführung stornieren';

  @override
  String get deskOutPostAgain => 'Erneut übertragen';

  @override
  String get deskOutNotDoneTitle => 'Nicht ausgeführt';

  @override
  String deskOutNotDoneText(String error) {
    return '$error. Die Outputs sind unverändert.';
  }

  @override
  String get deskOutSomethingWrong => 'Etwas ist schiefgelaufen';

  @override
  String get deskOutTryAgain => 'Erneut versuchen';

  @override
  String get deskOutToastNotPosted => 'Nicht übertragen';

  @override
  String get deskOutToastNotCancelled => 'Nicht storniert';

  @override
  String get deskOutSplitDialogTitle => 'Outputs aufteilen';

  @override
  String get deskOutConsDialogTitle => 'Outputs zusammenführen';

  @override
  String get deskOutPostingDesc => 'Wird gesendet.';

  @override
  String get deskOutDoneDesc => 'Erledigt.';

  @override
  String get deskOutSplitDesc =>
      'Mehr Outputs, damit mehrere Zahlungen aufeinander folgen können.';

  @override
  String get deskOutConsDesc => 'Ein Output statt vieler.';

  @override
  String deskOutNothingText(String what) {
    return 'Nichts zum Zusammenführen: Die Wallet hat $what. Zusammenführen macht aus mehreren Outputs einen.';
  }

  @override
  String get deskOutWhatFewer => 'weniger als zwei verfügbare Outputs';

  @override
  String get deskOutWhatOne => 'einen verfügbaren Output';

  @override
  String get deskOvNotUpdated => 'Nicht aktualisiert';

  @override
  String get deskOvNodeNotStarted => 'Node nicht gestartet';

  @override
  String get deskOvNodeAddrTitle => 'Node-Adresse aktualisiert';

  @override
  String get deskOvNodeAddrText =>
      'Jetzt wird node.epiccash.com statt node.epiccash.com:3413 genutzt.';

  @override
  String get deskOvNodeIncompatTitle =>
      'Die Version dieses Nodes ist mit dieser Wallet nicht kompatibel';

  @override
  String deskOvNodeUrl(String url) {
    return 'Node: $url';
  }

  @override
  String get deskOvUsePublicNode => 'Öffentlichen Node nutzen';

  @override
  String get deskOvUseLocalNode => 'Lokalen Node nutzen';

  @override
  String get deskOvHide => 'Ausblenden';

  @override
  String deskOvCantReachNode(String url) {
    return 'Der Node unter $url ist nicht erreichbar';
  }

  @override
  String get deskOvCantReachNodeText =>
      'Prüfen Sie, ob er läuft und erreichbar ist. Die Guthaben sind möglicherweise nicht aktuell, und das Senden ist pausiert.';

  @override
  String get deskOvStarting => 'Startet';

  @override
  String get deskOvStartNode => 'Node starten';

  @override
  String get deskOvNodeSettings => 'Node-Einstellungen';

  @override
  String get deskOvTitle => 'Übersicht';

  @override
  String get deskOvShowAmounts => 'Beträge anzeigen';

  @override
  String get deskOvHideAmounts => 'Beträge verbergen';

  @override
  String get deskOvRefresh => 'Aktualisieren';

  @override
  String get deskOvStepDone => 'erledigt';

  @override
  String get deskOvStepNow => 'läuft';

  @override
  String get deskOvStepWait => 'ausstehend';

  @override
  String deskOvStepSemantics(String text, String state) {
    return '$text, $state';
  }

  @override
  String get deskOvStartingUp => 'Wird gestartet';

  @override
  String get deskOvStepUnlocked => 'Wallet entsperrt';

  @override
  String get deskOvStepConnected => 'Mit dem Node verbunden';

  @override
  String get deskOvStepUpdating => 'Guthaben werden aktualisiert';

  @override
  String get deskOvStepEpicbox => 'Epicbox-Empfang wird gestartet';

  @override
  String deskOvSyncTitle(int percent) {
    return 'Node wird synchronisiert: $percent %';
  }

  @override
  String deskOvSyncText(String block) {
    return 'Blöcke werden heruntergeladen. Die Guthaben zeigen den Stand bei Block $block. Senden ist möglich, sobald der Node aufgeholt hat.';
  }

  @override
  String get deskOvSyncProgress => 'Fortschritt der Node-Synchronisierung';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent % der Blockchain';
  }

  @override
  String get deskOvReceiveEpic => 'EPIC empfangen';

  @override
  String get deskOvSend => 'Senden';

  @override
  String get deskOvReceive => 'Empfangen';

  @override
  String get deskOvSendWaits =>
      'Senden ist möglich, sobald der Node synchronisiert ist.';

  @override
  String get deskOvAvailable => 'Verfügbar';

  @override
  String deskOvAsOfBlock(String block) {
    return 'Stand Block $block';
  }

  @override
  String get deskOvEmptyHint =>
      'Teilen Sie die Epicbox-Adresse, um die ersten EPIC zu empfangen.';

  @override
  String get deskOvFiatNote => '  gesamtes Guthaben, CoinGecko';

  @override
  String get deskOvBreakTotal => 'Gesamt';

  @override
  String get deskOvBreakConfirming => 'Wird bestätigt';

  @override
  String get deskOvBreakImmature => 'Unreif';

  @override
  String get deskOvBreakAwaiting => 'Wartet auf Abschluss';

  @override
  String get deskOvBreakLocked => 'In Zahlungen gesperrt';

  @override
  String get deskOvUpdating => 'Aktualisierung';

  @override
  String get deskOvHiddenAmount => 'Betrag verborgen';

  @override
  String get deskOvLoading => 'Transaktionen werden geladen';

  @override
  String get deskOvEmptyTitle => 'Noch keine Transaktionen';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Empfangene EPIC erscheinen hier zuerst als „Wird bestätigt“, nach $blocks Blöcken dann als verfügbar.',
      one:
          'Empfangene EPIC erscheinen hier zuerst als „Wird bestätigt“, nach $blocks Block dann als verfügbar.',
    );
    return '$_temp0';
  }

  @override
  String get deskOvShowAddress => 'Adresse anzeigen';

  @override
  String get deskOvReceiveFile => 'Datei empfangen';

  @override
  String get deskOvRecent => 'Letzte Aktivitäten';

  @override
  String deskOvViewAll(int count) {
    return 'Alle $count anzeigen';
  }

  @override
  String deskOvPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen per Datei offen',
      one: '$count Zahlung per Datei offen',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText =>
      'Schließen Sie sie mit der Antwortdatei des Empfängers ab.';

  @override
  String get deskOvFinalize => 'Abschließen';

  @override
  String get deskTxMethodFile => 'Datei';

  @override
  String get deskTxMiningReward => 'Mining-Belohnung';

  @override
  String get deskTxReceived => 'Empfangen';

  @override
  String get deskTxSent => 'Gesendet';

  @override
  String get deskTxUnknownSender => 'Unbekannter Absender';

  @override
  String get deskTxUnknownRecipient => 'Unbekannter Empfänger';

  @override
  String get deskTxNoteBlock =>
      'Zeit des Blocks. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxNoteScanTime =>
      'Zeit des Scans; die Zeit des Blocks war nicht lesbar. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxNoteUnknown => 'Der Absender ist nicht gespeichert.';

  @override
  String get deskTxFoundRestoredLabel => 'Wiederhergestellt';

  @override
  String get deskTxFoundRestoredLine => 'Bei der Wiederherstellung gefunden';

  @override
  String get deskTxFoundRestoredStep =>
      'Bei der Wiederherstellung dieser Wallet gefunden';

  @override
  String get deskTxFoundRestoredTip =>
      'Bei der Wiederherstellung dieser Wallet in der Blockchain gefunden. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxFoundRescanLabel => 'Per Scan gefunden';

  @override
  String get deskTxFoundRescanLine => 'Beim Neuprüfen des Guthabens gefunden';

  @override
  String get deskTxFoundRescanStep => 'Beim Neuprüfen des Guthabens gefunden';

  @override
  String get deskTxFoundRescanTip =>
      'Beim Neuprüfen des Guthabens in der Blockchain gefunden. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxFoundScanLine => 'Per Scan gefunden';

  @override
  String get deskTxFoundScanStep => 'Per Scan gefunden';

  @override
  String get deskTxFoundScanTip =>
      'Per Scan in der Blockchain gefunden. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxBackupTip => 'Aus einer Verlaufssicherung hinzugefügt.';

  @override
  String get deskTxFromBackup => 'Aus Sicherung';

  @override
  String get deskTxStatusImmature => 'Unreif';

  @override
  String get deskTxStatusWaitingSender => 'Wartet auf Abschluss durch Absender';

  @override
  String get deskTxStatusWaitingResponseFile => 'Wartet auf die Antwortdatei';

  @override
  String get deskTxStatusWaitingRecipient =>
      'Wartet auf Signatur des Empfängers';

  @override
  String get deskTxStatusWaitingBlock => 'Wartet auf einen Block';

  @override
  String deskTxStatusConfirming(int confirmations, int needed) {
    return 'Bestätigung $confirmations/$needed';
  }

  @override
  String get deskTxStatusCancelled => 'Storniert';

  @override
  String get deskTxToday => 'heute';

  @override
  String get deskTxYesterday => 'gestern';

  @override
  String deskTxDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor $count Tag',
    );
    return '$_temp0';
  }

  @override
  String deskTxTodayAt(String time) {
    return 'Heute $time';
  }

  @override
  String deskTxDayToday(String date) {
    return 'Heute · $date';
  }

  @override
  String deskTxDayYesterday(String date) {
    return 'Gestern · $date';
  }

  @override
  String deskTxFee(String amount) {
    return 'Gebühr $amount';
  }

  @override
  String get deskTxPaymentProof => 'Zahlungsnachweis';

  @override
  String get deskTxFinalize => 'Abschließen';

  @override
  String deskTxSemReceived(String amount, String who, String status) {
    return 'Empfangen $amount, $who, $status';
  }

  @override
  String deskTxSemSent(String amount, String who, String status) {
    return 'Gesendet $amount, $who, $status';
  }

  @override
  String deskTxSemKind(String kind, String amount, String who, String status) {
    return '$kind $amount, $who, $status';
  }

  @override
  String get deskTxHiddenAmount => 'Betrag verborgen';

  @override
  String get deskTxNowBackup =>
      'Aus einer Sicherung; die Blockchain wurde nicht abgefragt.';

  @override
  String deskTxNowImmature(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bestätigt, aber eine Mining-Belohnung ist erst nach $count Bestätigungen verfügbar.',
      one:
          'Bestätigt, aber eine Mining-Belohnung ist erst nach $count Bestätigung verfügbar.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Signiert und zurückgeschickt. Wartet auf den Abschluss durch den Absender.';

  @override
  String get deskTxNowWaitingResponseFile =>
      'Wartet auf die Antwortdatei. Schließen Sie ab, sobald sie da ist.';

  @override
  String get deskTxNowWaitingRecipient =>
      'Wartet auf die Signatur des Empfängers. Bis zum Abschluss verlässt nichts die Wallet.';

  @override
  String get deskTxNowPosted =>
      'An das Netzwerk gesendet, wartet auf einen Block.';

  @override
  String deskTxNowConfirming(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      needed,
      locale: localeName,
      other: 'In einem Block, $confirmations von $needed Bestätigungen.',
      one: 'In einem Block, $confirmations von $needed Bestätigung.',
    );
    return '$_temp0';
  }

  @override
  String deskTxNowConfirmed(int confirmations) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Bestätigt, $confirmations Bestätigungen.',
      one: 'Bestätigt, $confirmations Bestätigung.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Storniert.';

  @override
  String get deskTxNotCancelled => 'Nicht storniert';

  @override
  String get deskTxCancelled => 'Transaktion storniert';

  @override
  String get deskTxCancelling => 'Wird storniert';

  @override
  String get deskTxHeadRestored => 'wiederhergestellt';

  @override
  String get deskTxHeadFoundOnChain => 'in der Blockchain gefunden';

  @override
  String get deskTxHeadBackup => 'aus einer Verlaufssicherung hinzugefügt';

  @override
  String deskTxHeadFrom(String who) {
    return 'von $who';
  }

  @override
  String deskTxHeadTo(String who) {
    return 'an $who';
  }

  @override
  String get deskTxSubProgress => 'Fortschritt';

  @override
  String get deskTxSubDetails => 'Details';

  @override
  String get deskTxFactDate => 'Datum';

  @override
  String get deskTxFactFrom => 'Von';

  @override
  String get deskTxFactTo => 'An';

  @override
  String get deskTxCopyAddress => 'Adresse kopieren';

  @override
  String get deskTxFactMethod => 'Methode';

  @override
  String get deskTxFactAmount => 'Betrag';

  @override
  String get deskTxFactFee => 'Gebühr';

  @override
  String get deskTxFactTotal => 'Gesamt';

  @override
  String get deskTxFactMessage => 'Nachricht';

  @override
  String get deskTxSignedByRecipient => 'Vom Empfänger signiert';

  @override
  String get deskTxProofView => 'Anzeigen';

  @override
  String get deskTxTechTitle => 'Technische Details';

  @override
  String get deskTxTechId => 'ID';

  @override
  String get deskTxTechSlate => 'Slate-ID';

  @override
  String get deskTxCopySlate => 'Slate-ID kopieren';

  @override
  String get deskTxTechHeight => 'Höhe';

  @override
  String get deskTxTechKernel => 'Kernel';

  @override
  String get deskTxTechConfirmed => 'Bestätigt';

  @override
  String get deskTxTechCredited => 'Gutgeschrieben';

  @override
  String get deskTxTechDebited => 'Abgebucht';

  @override
  String get deskTxTechStatus => 'Status';

  @override
  String get deskTxTechType => 'Typ';

  @override
  String get deskTxStepMined => 'In einem Block gemint';

  @override
  String get deskTxStepSpendable => 'Verfügbar';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Blöcke',
      one: 'noch $count Block',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Slate empfangen';

  @override
  String get deskTxStepCreated => 'Erstellt und signiert';

  @override
  String get deskTxStepSignedReturned => 'Signiert und zurückgeschickt';

  @override
  String get deskTxStepWaitingFile => 'Wartet auf die Antwortdatei';

  @override
  String get deskTxStepWaitingRecipient => 'Wartet auf den Empfänger';

  @override
  String get deskTxStepPosted => 'An das Netzwerk gesendet';

  @override
  String get deskTxStepConfirming => 'Wird bestätigt';

  @override
  String deskTxStepProgress(int confirmations, int needed) {
    return '$confirmations von $needed';
  }

  @override
  String get deskTxCancelIncomingTitle => 'Diese Zahlung stornieren?';

  @override
  String get deskTxCancelOutgoingTitle => 'Diese Zahlung stornieren?';

  @override
  String deskTxCancelIncomingBody(String amount, String who) {
    return '$amount EPIC von $who verlassen Ihr Guthaben. Die Wallet fragt zuerst den Node und lehnt ab, wenn die Zahlung schon in seinem Pool oder in einem Block ist. Sendet der Absender sie später, kann sie trotzdem ankommen.';
  }

  @override
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC an $who. Der gesperrte Betrag kehrt ins Guthaben zurück. Hat der Empfänger sie schon abgeschlossen, kann sie trotzdem bestätigt werden.';
  }

  @override
  String get deskTxCancelKeep => 'Behalten';

  @override
  String get deskTxCancelIncomingAction => 'Zahlung stornieren';

  @override
  String get deskTxCancelOutgoingAction => 'Zahlung stornieren';

  @override
  String deskTxProofIncoming(String amount) {
    return 'Belegt, dass diese Wallet $amount EPIC in diesem Kernel empfangen hat.';
  }

  @override
  String deskTxProofOutgoing(String amount) {
    return 'Belegt, dass der Empfänger $amount EPIC in diesem Kernel empfangen hat.';
  }

  @override
  String get deskTxProofSenderAddress => 'Absenderadresse';

  @override
  String get deskTxProofRecipientAddress => 'Empfängeradresse';

  @override
  String get deskTxProofRecipientSignature => 'Signatur des Empfängers';

  @override
  String get deskTxProofCopyKernel => 'Kernel kopieren';

  @override
  String get deskTxProofCopySender => 'Absenderadresse kopieren';

  @override
  String get deskTxProofCopyRecipient => 'Empfängeradresse kopieren';

  @override
  String get deskTxProofCopySignature => 'Signatur des Empfängers kopieren';

  @override
  String get deskTxProofExport => 'Exportieren';

  @override
  String get deskTxProofSaved => 'Nachweis gespeichert';
}
