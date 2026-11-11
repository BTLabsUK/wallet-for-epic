// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'BT Wallet';

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
  String get txRestoredFunds => 'Auf der Chain gefunden';

  @override
  String txSpokenLabelled(String label, String row) {
    return '$label, $row';
  }

  @override
  String get txLabel => 'Bezeichnung';

  @override
  String get txLabelAdd => 'Bezeichnung hinzufügen';

  @override
  String get txLabelEdit => 'Bezeichnung bearbeiten';

  @override
  String get txLabelHint => 'Bezeichnung hinzufügen';

  @override
  String get txLabelAddedNotice => 'Bezeichnung hinzugefügt';

  @override
  String get txLabelSavedNotice => 'Bezeichnung gespeichert';

  @override
  String get txLabelRemovedNotice => 'Bezeichnung entfernt';

  @override
  String get txEditAdd => 'Details hinzufügen';

  @override
  String get txEditEdit => 'Details bearbeiten';

  @override
  String get txEditFrom => 'Von';

  @override
  String get txEditFromHint => 'Adresse';

  @override
  String get txEditFromHelper => 'Nicht geprüft. Nur für Ihre Unterlagen.';

  @override
  String get txMethodUnknown => 'Unbekannt';

  @override
  String get txManualTag => 'Von Ihnen hinzugefügt';

  @override
  String txManualTip(String date) {
    return 'Von Ihnen am $date hinzugefügt. Nicht aus der Blockchain.';
  }

  @override
  String get txManualTipNoDate =>
      'Von Ihnen hinzugefügt. Nicht aus der Blockchain.';

  @override
  String txManualTipFrom(String date) {
    return 'Von Ihnen am $date hinzugefügt. Nicht aus der Blockchain, nicht geprüft.';
  }

  @override
  String get txManualTipFromNoDate =>
      'Von Ihnen hinzugefügt. Nicht aus der Blockchain, nicht geprüft.';

  @override
  String get txEditAddedNotice => 'Details hinzugefügt';

  @override
  String get txEditSavedNotice => 'Details gespeichert';

  @override
  String get txEditRemovedNotice => 'Details entfernt';

  @override
  String get histConflictTitle => 'Details weichen ab';

  @override
  String histConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Die Datei hat andere Details für $n Zahlungen. Ihre bleiben erhalten, wenn Sie nicht die der Datei wählen.',
      one: 'Die Datei hat andere Details für 1 Zahlung. Ihre bleiben erhalten, wenn Sie nicht die der Datei wählen.',
    );
    return '$_temp0';
  }

  @override
  String get histConflictMine => 'Meine';

  @override
  String get histConflictBackup => 'Datei';

  @override
  String get histConflictKeepAll => 'Alle meine behalten';

  @override
  String get histConflictImport => 'Importieren';

  @override
  String get histConflictEmpty => 'leer';

  @override
  String histImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Details ersetzt, der Rest bleibt wie von Ihnen eingegeben.',
      one: '1 Detail ersetzt, der Rest bleibt wie von Ihnen eingegeben.',
    );
    return '$_temp0';
  }

  @override
  String get txOutgoingPayment => 'Ausgehende Zahlung';

  @override
  String get txIncomingPayment => 'Eingehende Zahlung';

  @override
  String get txStatusWaitingRecipient => 'Wartet auf Empfänger';

  @override
  String get txStatusWaitingSender => 'Wartet auf Absender';

  @override
  String get txStatusSenderPosted => 'Laut Absender gesendet';

  @override
  String txStatusConfirming(int count, int target) {
    return 'Bestätigung $count/$target';
  }

  @override
  String get txStatusCompleted => 'Abgeschlossen';

  @override
  String get txStatusCancelled => 'Storniert';

  @override
  String get txStatusFromBackup => 'Importiert';

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
    return 'Auf der Chain gefunden: $amount';
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
      'Dies ist keine Wallet-Datendatei dieser App.';

  @override
  String get errorHistoryNewer =>
      'Diese Wallet-Datendatei wurde mit einer neueren Version der App erstellt.';

  @override
  String get errorHistoryDamaged => 'Diese Wallet-Datendatei ist beschädigt.';

  @override
  String get errorHistoryOtherWallet =>
      'Diese Datei gehört zu einer anderen Wallet. Nur die aus derselben Wiederherstellungsphrase wiederhergestellte Wallet kann sie öffnen.';

  @override
  String get errorHistoryOtherNetwork =>
      'Diese Wallet-Datendatei stammt aus einem anderen Netzwerk.';

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
  String get scanResuming => 'Scan wird fortgesetzt';

  @override
  String get scanResumedNotice =>
      'Der Scan war pausiert, solange die App im Hintergrund war. Er läuft dort weiter, wo er stand.';

  @override
  String get languageSetting => 'Sprache';

  @override
  String get languageSystem => 'System';

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
          'Wartet seit $days Tagen. Der Epicbox-Server löscht Zahlungen nach 7 Tagen, daher kann diese Zahlung nicht mehr abgeschlossen werden. Stornieren Sie sie, um die Coins freizugeben, und senden Sie dann erneut.',
      one: 'Wartet seit 1 Tag. Der Epicbox-Server löscht Zahlungen nach 7 Tagen, daher kann diese Zahlung nicht mehr abgeschlossen werden. Stornieren Sie sie, um die Coins freizugeben, und senden Sie dann erneut.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsWaitingEpicbox =>
      'Über Epicbox gesendet. Wird abgeschlossen, sobald die Wallet des Empfängers online ist; bis dahin oder bis zur Stornierung bleibt der Betrag gesperrt.';

  @override
  String get txDetailsWaitingRecipient =>
      'Wartet auf die Antwortdatei des Empfängers. Der Betrag bleibt bis dahin oder bis zur Stornierung gesperrt.';

  @override
  String get txDetailsWaitingSender =>
      'Wartet darauf, dass der Absender sie an das Netzwerk sendet.';

  @override
  String get txDetailsSenderPosted =>
      'Laut Absender ist diese Zahlung gesendet. Sie wird abgeschlossen, sobald das Netzwerk sie bestätigt.';

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
      'Storniert. Es wurde nichts bezahlt und der Betrag ist wieder verfügbar. Falls der Empfänger die Zahlung schon erhalten hat, zeigt seine Wallet sie vielleicht noch als wartend.';

  @override
  String get txDetailsCancelledReleased =>
      'Das Netzwerk hat die Zahlung nie angenommen, daher wurde der Betrag freigegeben. Prüfen Sie vor dem erneuten Senden, ob der Empfänger sie nicht doch erhalten hat.';

  @override
  String get txDetailsCancelledNotOnChain =>
      'Die Zahlung hat das Netzwerk nicht rechtzeitig erreicht und wurde storniert. Prüfen Sie vor dem erneuten Senden, ob der Empfänger sie nicht doch erhalten hat.';

  @override
  String get txDetailsCancelledUnanswered =>
      'Der Empfänger hat nicht innerhalb von 24 Stunden geantwortet, daher hat die Wallet die Zahlung storniert. Es wurde nichts bezahlt und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledLateAnswer =>
      'Der Empfänger hat erst nach Ablauf der 24-Stunden-Frist geantwortet, daher hat die Wallet die Zahlung storniert, statt sie abzuschließen. Es wurde nichts bezahlt und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledUndelivered =>
      'Die Zahlung konnte dem Empfänger nicht zugestellt werden, daher hat die Wallet sie sofort storniert. Es wurde nichts gesendet und der Betrag ist wieder verfügbar.';

  @override
  String get txDetailsCancelledIncoming =>
      'Storniert. Veröffentlicht der Absender sie später doch, trifft sie trotzdem ein.';

  @override
  String get txStatusReceiverDeclined => 'Vom Empfänger abgelehnt';

  @override
  String get txDetailsReceiverDeclined =>
      'Der Empfänger hat diese Zahlung abgelehnt. Sie wurde storniert, und Ihr Guthaben hat sich nicht geändert.';

  @override
  String get txStatusSenderCancelled => 'Vom Absender storniert';

  @override
  String get txDetailsSenderCancelledWaiting =>
      'Der Absender hat diese Zahlung storniert. Die Wallet entfernt sie hier, nachdem sie das Netzwerk geprüft hat.';

  @override
  String get txDetailsSenderCancelled =>
      'Der Absender hat diese Zahlung storniert. Wurde sie vorher doch veröffentlicht, trifft sie trotzdem ein.';

  @override
  String get txDetailsFromBackup =>
      'Diese Zahlung wurde aus einer Wallet-Datendatei importiert und war beim Export dieser Datei noch nicht abgeschlossen. Diese Wallet hat keine eigenen Daten dazu und kann daher nicht feststellen, ob sie abgeschlossen wurde. Es ist nichts gesperrt.';

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
  String get txWaitNoNewBlock => 'Warten, bis der nächste Block gefunden wird.';

  @override
  String get txWaitNotInBlock =>
      'Noch in keinem Block. Die Zahlung ist vielleicht noch auf dem Weg ins Netzwerk.';

  @override
  String get txDetailsStuckBody =>
      'Das Netzwerk hat diese Zahlung nicht aufgenommen. Übertragen Sie sie erneut; sie kann nicht zweimal ausgeführt werden.';

  @override
  String get txDetailsBroadcastAgain => 'Erneut übertragen';

  @override
  String get txDetailsBroadcastAgainDone => 'Erneut übertragen.';

  @override
  String get txDetailsRefusedBody =>
      'Diese Zahlung ist nicht durchgegangen. Die Coins darin können freigegeben werden.';

  @override
  String get txDetailsReleaseFunds => 'Betrag freigeben';

  @override
  String get txDetailsReleaseTitle => 'Betrag freigeben?';

  @override
  String get txDetailsReleaseBody =>
      'Diese Zahlung ist nicht durchgegangen, könnte es aber später noch.';

  @override
  String get txDetailsReleaseKeepWaiting => 'Weiter warten';

  @override
  String get txDetailsFundsReleased => 'Betrag freigegeben';

  @override
  String get txDetailsCancelPayment => 'Zahlung stornieren';

  @override
  String get txDetailsCancelTitle => 'Diese Zahlung stornieren?';

  @override
  String get txDetailsCancelReceiveBody =>
      'Noch ist nichts angekommen. Kommt diese Zahlung später doch an, erscheint sie als empfangen.';

  @override
  String get txDetailsCancelSendBody =>
      'Noch wurde nichts bezahlt: Stornieren ist kostenlos und sicher.';

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
  String get txDetailsNoteLabel => 'Private Notiz';

  @override
  String get txDetailsPrivateNoteLabel => 'Private Notiz';

  @override
  String get txDetailsMessageFromSender => 'Nachricht';

  @override
  String get txDetailsMessageFromRecipient => 'Nachricht des Empfängers';

  @override
  String get txDetailsYourMessage => 'Nachricht';

  @override
  String get txDetailsMessageHintToRecipient => 'An den Empfänger gesendet';

  @override
  String get txDetailsMessageHintFromSender => 'Vom Absender';

  @override
  String get txDetailsMessageHintFromRecipient => 'Vom Empfänger';

  @override
  String get txDetailsMessageHintToSender => 'An den Absender gesendet';

  @override
  String get txDetailsNoNote => 'Keine Notiz';

  @override
  String get txDetailsAddNote => 'Notiz hinzufügen';

  @override
  String get txDetailsEditNote => 'Notiz bearbeiten';

  @override
  String get txDetailsNoteDialogTitle => 'Private Notiz';

  @override
  String get txDetailsNoteHelper =>
      'Nur in dieser App und in den exportierten Wallet-Daten.';

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
  String get txDetailsExplorerBehind =>
      'Der Explorer hat diesen Block noch nicht erreicht.';

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
      'Auf der Chain gefunden. Absender und Gebühr stehen nicht auf der Chain; importieren Sie Wallet-Daten, um sie zu ergänzen.';

  @override
  String get txDetailsSourceImported =>
      'Aus einer Wallet-Datendatei importiert. Status nicht auf der Chain geprüft.';

  @override
  String get historyTitle => 'Aktivität';

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
  String get historyBackupSaveDialogTitle => 'Wallet-Daten speichern';

  @override
  String get importWarnTitle => 'Bevor Sie importieren';

  @override
  String get importWarnEarly => 'Dies ist eine frühe Version einer neuen App.';

  @override
  String get importWarnReads =>
      'Der Import liest Ihre alten Wallets und Dateien nur; er löscht oder ändert sie nie.';

  @override
  String get importWarnBackup =>
      'Stellen Sie vor dem Fortfahren sicher, dass Sie von jeder Wallet eine Sicherung haben: ihre Wiederherstellungsphrase und, falls Sie sie aufbewahren, ihre Wallet-Dateien.';

  @override
  String get importWarnRisk =>
      'Sie importieren auf eigenes Risiko; für Verluste übernehmen wir keine Verantwortung.';

  @override
  String get importWarnRiskPlain =>
      'Der Import erfolgt auf eigenes Risiko. Für Verluste wird keine Haftung übernommen.';

  @override
  String get importWarnAck => 'Ich habe von jeder Wallet eine Sicherung';

  @override
  String get historyBackupOpenDialogTitle => 'Wallet-Datendatei öffnen';

  @override
  String get historyBackupFileTooLarge =>
      'Diese Datei ist zu groß für eine Wallet-Datendatei.';

  @override
  String get historyBackupShare => 'Teilen';

  @override
  String get historyBackupShareSubtitle =>
      'Kopie außerhalb dieses Smartphones, etwa im Cloud-Speicher oder auf einem anderen Gerät.';

  @override
  String get historyBackupSaveToDevice => 'Auf dem Gerät speichern';

  @override
  String get historyBackupSaveToDeviceSubtitle =>
      'Zusätzlich außerhalb dieses Smartphones sichern.';

  @override
  String historyBackupSaved(String fileName) {
    return '$fileName gespeichert';
  }

  @override
  String get historyBackupExportTitle => 'Wallet-Daten exportieren';

  @override
  String get historyBackupCsvTitle => 'CSV exportieren';

  @override
  String get historyBackupCsvWarning =>
      'Nicht verschlüsselt: Jeder mit der Datei kann Beträge, Datumsangaben, Adressen und Notizen lesen. Sie lässt sich nicht importieren; für eine Sicherung „Wallet-Daten exportieren“ nutzen.';

  @override
  String get historyBackupCsvConfirm => 'CSV exportieren';

  @override
  String get historyBackupImportedTitle => 'Wallet-Daten importiert';

  @override
  String historyBackupImportFailed(String reason) {
    return 'Wallet-Daten nicht importiert. $reason';
  }

  @override
  String get historyBackupImportNothingNew =>
      'Die Datei enthielt nichts Neues.';

  @override
  String get homeLockTooltip => 'Wallet sperren';

  @override
  String get shellTitle => 'BT Wallet';

  @override
  String get homeSettingsTooltip => 'Einstellungen';

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
  String get homeBackedUpNotice => 'Wiederherstellungsphrase gesichert';

  @override
  String get homeNoticeView => 'Anzeigen';

  @override
  String get homeNoticeReceived => 'Eine Zahlung ist unterwegs.';

  @override
  String homeNoticeReceivedFrom(String who) {
    return 'Eine Zahlung von $who ist unterwegs.';
  }

  @override
  String homeNoticeReceivedAmount(String amount) {
    return '$amount unterwegs.';
  }

  @override
  String homeNoticeReceivedAmountFrom(String amount, String who) {
    return '$amount von $who unterwegs.';
  }

  @override
  String get homeNoticeSenderPosted =>
      'Laut Absender wurde eine Zahlung gesendet.';

  @override
  String homeNoticeSenderPostedAmount(String amount) {
    return 'Laut Absender wurden $amount gesendet.';
  }

  @override
  String get homeNoticeFinished => 'Zahlung fertiggestellt. Wird bestätigt.';

  @override
  String homeNoticeFinishedTo(String who) {
    return 'Zahlung an $who fertiggestellt. Wird bestätigt.';
  }

  @override
  String get homeNoticeDelayed =>
      'Der Node ist nicht erreichbar. Die Zahlung wartet.';

  @override
  String get homeNoticeRelayProblem =>
      'Der Epicbox-Server meldet ein Problem. Wird erneut versucht.';

  @override
  String get homeNoticePaymentFailed => 'Eine Zahlung ist fehlgeschlagen.';

  @override
  String get homeBackupCardText => 'Phrase nicht gesichert';

  @override
  String get homeBackupCardButton => 'Sichern';

  @override
  String get homeBackupCardDismiss => 'Ausblenden';

  @override
  String get torAddressChangedTitle => 'Ihre Tor-Adresse hat sich geändert';

  @override
  String homeHistoryNotBackedUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen sind in Ihren exportierten Wallet-Daten nicht enthalten.',
      one: '1 Zahlung ist in Ihren exportierten Wallet-Daten nicht enthalten.',
    );
    return '$_temp0';
  }

  @override
  String homeHistoryChangedSinceBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen sind seit dem letzten Export der Wallet-Daten neu oder geändert.',
      one: '1 Zahlung ist seit dem letzten Export der Wallet-Daten neu oder geändert.',
    );
    return '$_temp0';
  }

  @override
  String get homeHistoryReminderNotNow => 'Nicht jetzt';

  @override
  String get homeHistoryExportButton => 'Wallet-Daten exportieren';

  @override
  String get balanceHelpLabel => 'Was diese Guthaben bedeuten';

  @override
  String get homeBalanceSpendableNow => 'Jetzt verfügbar';

  @override
  String get balanceWalletHelp =>
      'Jetzt verfügbar, dazu Zahlungen und Ihr eigenes Wechselgeld, die noch bestätigt werden, und Coins, die für ein verknüpftes Gerät reserviert sind.';

  @override
  String get balanceSpendableNowHelp =>
      'Was Sie jetzt senden können. Der Rest wird verfügbar, sobald er bestätigt ist.';

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
  String balanceExactTip(String amount) {
    return 'Genauer Betrag: $amount';
  }

  @override
  String get homeShowBalances => 'Guthaben anzeigen';

  @override
  String get homeHideBalances => 'Beträge verbergen';

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
  String get homeBalanceImmature => 'Mining-Belohnungen';

  @override
  String get balanceImmatureHelp =>
      'Mining-Belohnungen warten eine feste Zahl von Blöcken, bevor sie verfügbar sind.';

  @override
  String get balanceLineAllConfirmed => 'Alles bestätigt';

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
  String percentValue(String percent) {
    return '$percent %';
  }

  @override
  String get statusNodeConnecting => 'Node: Verbindung…';

  @override
  String get statusNodeOffline => 'Node offline';

  @override
  String get statusEpicboxOnline => 'Epicbox verbunden';

  @override
  String get statusEpicboxConnecting => 'Epicbox: Verbindung…';

  @override
  String get statusEpicboxOffline => 'Epicbox nicht verbunden';

  @override
  String get statusEpicboxBlocked => 'Epicbox blockiert';

  @override
  String epicboxBlockedBody(String host) {
    return 'Dieses Netzwerk blockiert $host. Ursache kann ein Netzwerkfilter sein. Versuchen Sie einen anderen Epicbox-Server oder ein privates DNS.';
  }

  @override
  String epicboxSwitchTo(String host) {
    return 'Zu $host wechseln';
  }

  @override
  String get netStatusBlocked => 'Blockiert';

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
      'Ihre Wallet ist nicht mit ihrem Epicbox-Server verbunden und versucht es weiter.';

  @override
  String get homeEpicboxConnecting =>
      'Verbindung zur Epicbox wird hergestellt…';

  @override
  String homeSyncedAtBlock(String height) {
    return 'Synchronisiert bis Block $height';
  }

  @override
  String contactsStaleOpened(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Zuletzt vor $days Tagen geöffnet. Gekoppelte Kontakte werden geprüft.',
      one:
          'Zuletzt vor $days Tag geöffnet. Gekoppelte Kontakte werden geprüft.',
    );
    return '$_temp0';
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
  String get homeNoPayments => 'Noch keine Zahlungen';

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
      'Keine Rechnungen warten. Wenn Sie ein gekoppelter, erlaubter Kontakt um Zahlung bittet, erscheint die Rechnung hier, und nichts wird bezahlt, bis Sie zustimmen.';

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
  String invoiceReviewAsks(String service) {
    return '$service bittet Sie um Zahlung';
  }

  @override
  String invoiceReviewMessageLabel(String name) {
    return 'Nachricht von $name';
  }

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
  String invoiceDetailsRepliedHelp(String service) {
    return 'Wenn $service sie nicht gebucht hat, sende die Zahlung erneut: Nichts wird zweimal signiert. Wird sie nie gebucht, wird Abbrechen verfügbar, sobald die Zeit der Zahlung abläuft, etwa einen Tag nach dem Bezahlen.';
  }

  @override
  String invoiceDetailsPosted(String service) {
    return '$service meldet, dass die Zahlung veröffentlicht wurde. Sie ist abgeschlossen, sobald das Netzwerk sie bestätigt.';
  }

  @override
  String invoiceDetailsConfirmed(String service) {
    return 'Bezahlt. Das Netzwerk hat die Zahlung an $service bestätigt.';
  }

  @override
  String invoiceDetailsReplyFailed(String service) {
    return '$service hat Ihre Zahlung noch nicht erhalten. „Erneut senden“ schickt sie noch einmal, ohne dass Sie erneut zustimmen.';
  }

  @override
  String invoiceDetailsWithdrawn(String service) {
    return '$service hat diese Rechnung zurückgezogen, nachdem Sie sie bezahlt haben.';
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
  String get requestMessageLabel => 'Nachricht an den Zahler (optional)';

  @override
  String get requestMessageHelper =>
      'Der Zahler sieht diese Nachricht mit Ihrer Rechnung.';

  @override
  String get invoicesToPaySection => 'Zu zahlen';

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
  String get issuedWithdrawTitle => 'Diese Rechnung zurückziehen?';

  @override
  String issuedWithdrawBody(String payer) {
    return '$payer kann sie dann nicht mehr bezahlen. Nichts wurde bezahlt, also bewegen sich keine Coins. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String get issuedWithdrawKeep => 'Behalten';

  @override
  String get issuedDetailsSection => 'Rechnung';

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
      'Der Zahler hat diese Rechnung abgelehnt, daher wurde sie zurückgezogen. Es wurde nichts bezahlt.';

  @override
  String get issuedDetailsWithdrawn =>
      'Sie haben diese Rechnung zurückgezogen. Es wurde nichts bezahlt.';

  @override
  String get issuedDetailsExpired =>
      'Diese Rechnung ist abgelaufen, bevor sie bezahlt wurde. Es wurde nichts bezahlt.';

  @override
  String get issuerNoticePaid => 'Eine Ihrer Rechnungen wurde bezahlt.';

  @override
  String get issuerNoticeDeclined => 'Eine Ihrer Rechnungen wurde abgelehnt.';

  @override
  String get issuerNoticeWithdrawn =>
      'Rechnung zurückgezogen. Sie kann nicht mehr bezahlt werden.';

  @override
  String get issuerNoticeExpired =>
      'Eine Ihrer Rechnungen ist unbezahlt abgelaufen.';

  @override
  String issuerNoticeBouncedFrom(String payer) {
    return 'Die Wallet von $payer kann keine Rechnungen bezahlen und hat Ihre zurückgeschickt, daher wurde sie zurückgezogen. Bitten Sie die Person, Ihnen die Zahlung stattdessen zu senden, an Ihre Adresse oder als Transaktionsdatei.';
  }

  @override
  String get issuedBounced => 'Zurückgeschickt';

  @override
  String get issuedDetailsBounced =>
      'Die Wallet des Zahlers kann keine Rechnungen bezahlen, daher wurde nichts bezahlt. Bitten Sie die Person, die Zahlung an Ihre Adresse oder als Transaktionsdatei zu senden.';

  @override
  String get txStatusWaitingPayer => 'Wartet auf Zahler';

  @override
  String get txStepRequested => 'Angefordert';

  @override
  String get txStepPaid => 'Bezahlt';

  @override
  String get txDetailsWaitingPayer =>
      'Sie haben diese Zahlung angefordert. Bisher ist nichts eingegangen: Die Zahlung kommt, sobald der Zahler die Rechnung bezahlt.';

  @override
  String get txDetailsRequestEnded =>
      'Diese Rechnung wurde nicht bezahlt. Es ist nichts eingegangen.';

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
  String receiveEpicboxConnected(String server) {
    return 'Verbunden · $server';
  }

  @override
  String get receiveQrLabel => 'QR-Code Ihrer Adresse';

  @override
  String get receiveAddressLabel => 'Epicbox-Adresse';

  @override
  String get receiveEpicboxOfflineBody =>
      'Zahlungen warten auf dem Epicbox-Server und kommen an, sobald die Wallet wieder verbunden ist.';

  @override
  String get receiveShareCardHeadline => 'Bezahl mich mit Epic Cash';

  @override
  String get receiveHelpButton => 'So funktioniert Empfangen';

  @override
  String get receiveAddressCopied => 'Adresse kopiert';

  @override
  String get receiveFileTitle => 'Per Transaktionsdatei empfangen';

  @override
  String get receiveFileBody =>
      'Öffnen Sie die Transaktionsdatei oder fügen Sie ihren Text hier ein.';

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
      'Erlauben Sie Installationen von BT Wallet und kehren Sie dann zurück.';

  @override
  String get updateInstallCancelled =>
      'Das Update wurde nicht installiert. Sie können es erneut versuchen.';

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
  String get updateManifestOtherApp =>
      'Die Update-Informationen gehören zu einer anderen App.';

  @override
  String updateDownloadHttpFailed(int status) {
    return 'Der Download ist fehlgeschlagen (HTTP $status).';
  }

  @override
  String get updateDownloadTooLarge =>
      'Der Download ist größer als angekündigt.';

  @override
  String get updateDownloadDamaged =>
      'Der Download ist beschädigt (Prüfsumme stimmt nicht überein).';

  @override
  String get updateDownloadInterrupted => 'Der Download wurde unterbrochen.';

  @override
  String get updateNoTorDownload =>
      'Das Update lässt sich noch nicht über Tor herunterladen. Schalten Sie Tor aus, um es herunterzuladen, oder laden Sie es von der Download-Seite.';

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
  String get setupNetworkSettingsTooltip => 'Node und Epicbox';

  @override
  String get setupNetworkHeading => 'Netzwerk';

  @override
  String get setupWalletPerNetwork =>
      'Jedes Netzwerk hat eine eigene Wallet. Für ein Netzwerk ohne Wallet wird eine neue erstellt.';

  @override
  String get restoreTitle => 'Wallet wiederherstellen';

  @override
  String get restorePhraseLabel => 'Wiederherstellungsphrase';

  @override
  String get restorePhraseHelper =>
      'Alle Wörter (12, 15, 18, 21 oder 24), durch Leerzeichen getrennt.';

  @override
  String get restoreStartByMonth => 'Monat';

  @override
  String get restoreStartByHeight => 'Blockhöhe';

  @override
  String get restoreStartHeightLabel => 'Startblock (optional)';

  @override
  String get restoreStartHeightHelper =>
      'Ab diesem Block scannen. Leer lassen, um die gesamte Blockchain zu scannen.';

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
      'Optional. Bei Unsicherheit ein früheres Datum wählen: Ein späteres kann Guthaben übersehen.';

  @override
  String restoreDateStart(String height) {
    return 'Der Scan beginnt zwei Tage vor diesem Datum, ab Block $height.';
  }

  @override
  String get restorePickMonth => 'Erstellungsmonat der Wallet wählen';

  @override
  String get restorePickMonthShort => 'Monat wählen';

  @override
  String restoreMonthStart(String height) {
    return 'Der Scan beginnt ab Block $height.';
  }

  @override
  String get restoreMonthRecent =>
      'Ein aktueller Monat: Guthaben aus früheren Monaten kann übersehen werden.';

  @override
  String get restoreMonthEarlierYear => 'Früheres Jahr';

  @override
  String get restoreMonthLaterYear => 'Späteres Jahr';

  @override
  String get restoreScanIntro =>
      'Ihr Guthaben wird auf der Blockchain gesucht. Lassen Sie die App geöffnet, bis der Vorgang abgeschlossen ist.';

  @override
  String get restoreOpenWallet => 'Wallet öffnen';

  @override
  String get restoreUnfinishedTitle => 'Wiederherstellung nicht abgeschlossen';

  @override
  String get restoreUnfinishedRunning =>
      'Das Guthaben dieser Wallet wird gesucht. Empfangen und Senden sind möglich, sobald dies abgeschlossen ist.';

  @override
  String get restoreUnfinishedOffline =>
      'Der Scan wird fortgesetzt, sobald Offline ausgeschaltet ist.';

  @override
  String get restoreUnfinishedFailed =>
      'Der Scan wurde abgebrochen und wird automatisch erneut gestartet. Empfangen und Senden bleiben gesperrt, bis er abgeschlossen ist.';

  @override
  String get errorRestoreScanRequired =>
      'Wiederherstellung nicht abgeschlossen. Empfangen und Senden sind möglich, sobald der auf der Startseite angezeigte Scan beendet ist.';

  @override
  String get restoreScanStop => 'Stoppen';

  @override
  String get restoreScanScreenOn =>
      'Der Bildschirm bleibt an, solange dies läuft.';

  @override
  String get restoreScanStopped =>
      'Gestoppt. Empfangen und Senden sind erst möglich, wenn dieser Scan abgeschlossen ist; er läuft von der Startseite weiter.';

  @override
  String get restoreScanUnfinished =>
      'Der Scan wurde vor dem Ende abgebrochen. Empfangen und Senden sind erst möglich, wenn er abgeschlossen ist: Versuchen Sie es hier erneut oder öffnen Sie die Wallet, dann läuft er von der Startseite weiter.';

  @override
  String get restoreFinishOnHome =>
      'Coins ab dem gewählten Start wurden gefunden. Ein Scan ab Block 0 schließt die Wiederherstellung jetzt auf der Startseite ab; Empfangen und Senden sind möglich, sobald er beendet ist.';

  @override
  String get unlockDatabaseRebuilt =>
      'Die Wallet-Datenbank war beschädigt und wurde aus der Phrase neu aufgebaut. Ein Scan holt das Guthaben zurück; Zahlungsdetails, Notizen und Bezeichnungen kommen nur aus einer Wallet-Datendatei zurück.';

  @override
  String get restoreRebuiltImportText =>
      'Eine Wallet-Datendatei bringt Zahlungsverlauf, Kontakte, Rechnungen und Einstellungen zurück.';

  @override
  String get restoreReplaceLead =>
      'Die Phrase stellt eine Wallet anstelle der Wallet auf diesem Smartphone wieder her. Es ändert sich nichts, bevor die Phrase geprüft und der Austausch bestätigt ist.';

  @override
  String get restoreReplacePinReason =>
      'Geben Sie Ihre PIN ein, um diese Wallet zu ersetzen. Die wiederhergestellte Wallet behält diese PIN.';

  @override
  String restorePhraseUnknownWord(int position, String word) {
    return 'Wort $position, „$word“, steht nicht in der Wortliste.';
  }

  @override
  String restorePhraseUnknownWords(String words) {
    return 'Nicht in der Wortliste: $words.';
  }

  @override
  String restorePhraseWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Diese Phrase hat $count Wörter. Eine Wiederherstellungsphrase hat 12, 15, 18, 21 oder 24.',
      one:
          'Diese Phrase hat $count Wort. Eine Wiederherstellungsphrase hat 12, 15, 18, 21 oder 24.',
    );
    return '$_temp0';
  }

  @override
  String get restorePhraseChecksum =>
      'Jedes Wort steht in der Wortliste, aber die Phrase stimmt nicht. Ein Wort ist falsch oder an der falschen Stelle.';

  @override
  String deleteFailedNotice(String error) {
    return 'Wallet nicht gelöscht. $error Entsperren Sie sie und versuchen Sie es in den Einstellungen erneut.';
  }

  @override
  String get restoreDoneIconLabel => 'Fertig';

  @override
  String get restoreDoneTitle => 'Ihre Wallet ist wiederhergestellt';

  @override
  String get restoreImportExplanation =>
      'Die Wiederherstellungsphrase hat das Guthaben wiederhergestellt. Um Verlauf, Kontakte, Rechnungen und Einstellungen zurückzuholen, importieren Sie die exportierte Wallet-Datendatei.';

  @override
  String get restoreImportButton => 'Wallet-Daten importieren';

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
  String get firstRunCreate => 'Neue Wallet erstellen';

  @override
  String get firstRunRestore => 'Mit Phrase wiederherstellen';

  @override
  String get settingsRestoreReplaces =>
      'Diese Wallet wird gelöscht, und die Wallet der eingegebenen Phrase tritt an ihre Stelle, mit derselben PIN.';

  @override
  String get firstRunSecuring => 'Ihre Wallet wird gesichert…';

  @override
  String get workStoppingRecheck => 'Neuprüfung wird beendet…';

  @override
  String get workTellingDevices => 'Verknüpfte Geräte werden benachrichtigt…';

  @override
  String get workRemovingFiles => 'Wallet-Dateien werden entfernt…';

  @override
  String get workClearingKeys => 'Schlüssel werden gelöscht…';

  @override
  String get workChecking => 'Wird geprüft…';

  @override
  String get workOpening => 'Wallet wird geöffnet…';

  @override
  String get workCreating => 'Wallet wird erstellt…';

  @override
  String get workRestoring => 'Wallet wird wiederhergestellt…';

  @override
  String get workStarting => 'Wird gestartet…';

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
      'Wer die Wörter oder ein Foto davon sieht, kann das Guthaben nehmen.';

  @override
  String get backupConsentTitle => 'Bevor Sie die Phrase sehen';

  @override
  String get backupConsentWhat =>
      'Der nächste Bildschirm zeigt die Wörter, mit denen sich diese Wallet wiederherstellen lässt.';

  @override
  String get backupConsentReady => 'Papier und Stift bereithalten.';

  @override
  String get backupCopyAgree => 'Ich halte die Phrase geheim';

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
          'Schreiben Sie diese $count Wörter der Reihe nach auf Papier. Nur mit ihnen lässt sich diese Wallet wiederherstellen.',
    );
    return '$_temp0';
  }

  @override
  String backupWordSpoken(int number, String word) {
    return 'Wort $number: $word';
  }

  @override
  String get backupCopyTitle => 'Wiederherstellungsphrase kopieren?';

  @override
  String get backupCopyBody =>
      'Wer diese Wörter hat, kann Ihr Guthaben nehmen. Bewahren Sie die Kopie sicher auf.';

  @override
  String get backupCopied =>
      'Kopiert. Die Zwischenablage wird in 60 Sekunden geleert.';

  @override
  String get backupNotCopied =>
      'Nicht kopiert. Die Zwischenablage hat den Text abgelehnt.';

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
  String get pinBiometricsQuestion => 'Mit Biometrie entsperren?';

  @override
  String get pinBiometricsPinStillWorks => 'Die PIN funktioniert weiterhin.';

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
  String get scanQrTooltip => 'QR-Code scannen';

  @override
  String get sendScanButton => 'Scannen';

  @override
  String get sendChooseContactTooltip => 'Kontakt auswählen';

  @override
  String get sendContactsButton => 'Kontakte';

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
  String get slateNotTransactionFile =>
      'Diese Datei ist keine Transaktionsdatei.';

  @override
  String get slateReading => 'Datei wird gelesen';

  @override
  String get slateReadingQr => 'Zahlung wird gelesen';

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
  String get scanPhraseFoundQr =>
      'Dieser QR-Code enthält eine Wiederherstellungsphrase. Halten Sie sie geheim.';

  @override
  String get scanPhraseFoundPasted =>
      'Das ist eine Wiederherstellungsphrase, sie wurde nicht eingefügt. Halten Sie sie geheim.';

  @override
  String get scanQrPhraseHint =>
      'Richten Sie die Kamera auf den QR-Code der Wiederherstellungsphrase.';

  @override
  String get restoreScanNoPhrase =>
      'Dieser QR-Code enthält keine Wiederherstellungsphrase.';

  @override
  String get scanQrCameraDenied =>
      'Kamerazugriff ist aus. Erlauben Sie ihn in den Einstellungen des Smartphones oder fügen Sie die Adresse ein.';

  @override
  String get scanQrCameraFailed =>
      'Die Kamera konnte nicht gestartet werden. Fügen Sie stattdessen die Adresse ein oder versuchen Sie es erneut.';

  @override
  String get scanQrTryAgain => 'Erneut versuchen';

  @override
  String get scanQrBack => 'Zurück';

  @override
  String get qrShowReplyAsQr => 'Antwort als QR anzeigen';

  @override
  String get qrShowTitlePayment => 'Zahlungs-QR';

  @override
  String get qrShowTitleReply => 'Antwort-QR';

  @override
  String qrShowSubPayment(String amount) {
    return '$amount an ein Smartphone neben Ihnen';
  }

  @override
  String qrShowSubReply(String amount) {
    return 'An den Absender von $amount';
  }

  @override
  String get qrHiddenTitle => 'Verborgen, bis Sie ihn zeigen';

  @override
  String get qrHiddenBodyPayment =>
      'Wer ihn zuerst scannt, kann diese Zahlung annehmen. Zeigen Sie ihn nur der Person, die Sie bezahlen.';

  @override
  String get qrHiddenBodyReply =>
      'Zeigen Sie ihn dem Smartphone des Absenders. Nur dessen Wallet kann ihn verwenden.';

  @override
  String get qrShow => 'QR anzeigen';

  @override
  String get qrShowAgain => 'Erneut anzeigen';

  @override
  String get qrHide => 'Verbergen';

  @override
  String qrCountdownLabel(int seconds) {
    return 'Anzeige in $seconds';
  }

  @override
  String qrPartOf(int part, int count) {
    return 'Teil $part von $count';
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
      other: 'Noch $seconds Sekunden',
      one: 'Noch 1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get qrHoldHint =>
      'Halten Sie die Kamera des anderen Smartphones auf diesen Code.';

  @override
  String get qrSecureLine => 'Screenshots sind auf diesem Bildschirm aus';

  @override
  String qrTimedOutTitle(int seconds) {
    return 'Nach $seconds s verborgen';
  }

  @override
  String get qrTimedOutBody =>
      'Zeigen Sie ihn erneut, wenn das andere Smartphone bereit ist.';

  @override
  String get qrAwayTitle => 'Verborgen, während die App weg war';

  @override
  String get qrAwayBody =>
      'Der Code wird verborgen, sobald die App den Bildschirm verlässt.';

  @override
  String qrSemanticsPayment(String state) {
    return 'Zahlungs-QR-Code, $state';
  }

  @override
  String qrSemanticsReply(String state) {
    return 'Antwort-QR-Code, $state';
  }

  @override
  String get qrStateHidden => 'verborgen';

  @override
  String get qrStateShowing => 'sichtbar';

  @override
  String get qrScanPayment => 'Zahlungs-QR scannen';

  @override
  String get qrScanReply => 'Antwort scannen';

  @override
  String get qrScanAimPayment =>
      'Richten Sie die Kamera auf den QR-Code auf dem anderen Smartphone.';

  @override
  String get qrScanAimReply =>
      'Richten Sie die Kamera auf die Antwort auf dem anderen Smartphone.';

  @override
  String get qrScanSteady => 'Ruhig halten oder etwas näher herangehen.';

  @override
  String get qrScanGot => 'Code gelesen';

  @override
  String qrScanCount(int got, int count) {
    return '$got von $count';
  }

  @override
  String get qrScanCountLabel => 'Gelesene Teile';

  @override
  String get qrScanNotPayment =>
      'Das ist kein Zahlungs-QR. Bitten Sie die Gegenseite, den Zahlungs-QR anzuzeigen.';

  @override
  String get qrScanNotReply =>
      'Das ist kein Antwort-QR. Bitten Sie die Gegenseite, die Antwort auf ihrem Smartphone anzuzeigen.';

  @override
  String get qrScanOtherPayment =>
      'Dieser Code gehört zu einer anderen Zahlung. Es geht von vorn los.';

  @override
  String get qrScanTorch => 'Taschenlampe';

  @override
  String qrScanZoom(String factor) {
    return 'Zoom $factor×';
  }

  @override
  String get qrScanCameraDenied =>
      'Kamerazugriff ist aus. Erlauben Sie ihn in den Einstellungen des Smartphones oder öffnen Sie eine Datei.';

  @override
  String get qrScanCameraFailed =>
      'Die Kamera ließ sich nicht starten. Versuchen Sie es erneut oder öffnen Sie stattdessen die Datei.';

  @override
  String get qrScanOpenSettings => 'Einstellungen öffnen';

  @override
  String get qrScanOpenFileInstead => 'Stattdessen Datei öffnen';

  @override
  String get qrScanAgain => 'Erneut scannen';

  @override
  String get slateWrongPaymentQr =>
      'Diese Antwort gehört zu einer anderen Zahlung. Scannen Sie die Antwort für diese Zahlung.';

  @override
  String get slateScannedPaymentTitle => 'Gescannte Zahlung';

  @override
  String get slateScannedReplyTitle => 'Gescannte Antwort';

  @override
  String get slateIncomingSendHintQr =>
      'Nehmen Sie sie an und zeigen Sie dann dem Absender die Antwort.';

  @override
  String get slateAcceptedHeadlineQr =>
      'Angenommen. Zeigen Sie dem Absender die Antwort.';

  @override
  String get methodQr => 'QR-Zahlung';

  @override
  String get methodArtCaptionQr => 'Persönlich';

  @override
  String get methodSendQrTitle => 'Für ein Smartphone neben Ihnen.';

  @override
  String get methodSendQrLine =>
      'Zeigen Sie einen Code auf diesem Bildschirm und scannen Sie dann die Antwort mit der Kamera.';

  @override
  String get methodReceiveQrTitle => 'Scannen Sie deren Bildschirm.';

  @override
  String get methodReceiveQrLine =>
      'Nehmen Sie die Zahlung an und zeigen Sie dann Ihre Antwort auf dieselbe Weise.';

  @override
  String get receiveQrTitle => 'Neben dem anderen Smartphone?';

  @override
  String get receiveQrBody =>
      'Oder fordern Sie einen Betrag an: Zeigen Sie einen QR zum Scannen.';

  @override
  String get txQrHint =>
      'QR-Zahlung zeigt die Zahlung als animierten Code, den das andere Smartphone mit der Kamera scannt, und nimmt die Antwort auf dieselbe Weise entgegen. Das geht nur zwischen Smartphones nebeneinander, braucht keine Verbindung zwischen den beiden Wallets, und der Code verbirgt sich nach 40 Sekunden. Fügt QR-Zahlung zu Senden und Empfangen hinzu.';

  @override
  String get advTransactionFiles => 'Direkt · Dateiübertragung';

  @override
  String get advTransactionFilesHint =>
      'Fügt unter Einstellungen › Transaktionen die Dateiübertragung hinzu: mit einer Datei zahlen oder bezahlt werden, die Sie selbst weitergeben.';

  @override
  String get sendMakeQr => 'Zahlungs-QR erstellen';

  @override
  String sendQrPinReason(String amount) {
    return 'Geben Sie die PIN ein, um einen Zahlungs-QR über $amount zu erstellen.';
  }

  @override
  String get sendQrHint =>
      'Zeigen Sie den Code dem Smartphone des Empfängers und scannen Sie dann dessen Antwort.';

  @override
  String get sendCancelRuleQr =>
      'Kann storniert werden, bis Sie die Antwort scannen.';

  @override
  String get qrStatusSendHidden => 'Zeigen Sie dies dem Empfänger.';

  @override
  String get qrStatusSendShowing =>
      'Warten, bis der Empfänger scannt. Scannen Sie dann dessen Antwort.';

  @override
  String get qrStatusHiddenAgain => 'Verborgen';

  @override
  String get qrStatusReplyHidden => 'Verborgen';

  @override
  String get qrStatusReplyShowing => 'Warten, bis der Absender scannt.';

  @override
  String get qrStatusReceivedWaiting =>
      'Zahlung empfangen. Warten, bis der Absender scannt und sie sendet.';

  @override
  String qrStatusPosted(int got, int target) {
    return 'Gesendet. Bestätigung $got/$target';
  }

  @override
  String get qrStatusReceived => 'Empfangen.';

  @override
  String qrScanProgress(int got, int count) {
    return '$got von $count gescannt. Halten Sie den Code im Bild.';
  }

  @override
  String get qrScanReplyScanned => 'Antwort gescannt.';

  @override
  String get qrScanPosting => 'Antwort gescannt. Wird gesendet …';

  @override
  String get qrScanPosted => 'Gesendet.';

  @override
  String get contactsTitle => 'Kontakte';

  @override
  String get contactsPickTitle => 'Kontakt auswählen';

  @override
  String get contactsAdd => 'Kontakt hinzufügen';

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
  String get contactsAddressInvalidAny =>
      'Keine gültige Adresse. Verwenden Sie eine Epicbox-Adresse (es5x…@Server), eine Link-Adresse (https://…) oder eine Onion-Adresse (….onion).';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionDisplay => 'Darstellung';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String settingsCurrencyWithCode(String name, String code) {
    return '$name ($code)';
  }

  @override
  String get settingsShowPrices => 'Kurse anzeigen';

  @override
  String get settingsHideBalances => 'Beträge verbergen';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsPricesOnNotice =>
      'Die Kurse stammen aus der Kopie des CoinGecko-Kurses von BT Labs auf status.btlabs.uk; diese sieht Ihre IP-Adresse. Bei ausgeschaltetem Tor wird CoinGecko gefragt, wenn die Kopie keinen Kurs hat; dann sieht CoinGecko Ihre IP-Adresse.';

  @override
  String get settingsSectionSecurity => 'Sicherheit';

  @override
  String get settingsChangePin => 'PIN ändern';

  @override
  String get settingsBiometrics => 'Mit Biometrie entsperren';

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
  String get settingsSectionHistory => 'Wallet-Daten';

  @override
  String get settingsExportHistory => 'Wallet-Daten exportieren';

  @override
  String get settingsExportCsv => 'CSV exportieren';

  @override
  String get settingsImportHistory => 'Wallet-Daten importieren';

  @override
  String get settingsSectionWallet => 'Diese Wallet';

  @override
  String get settingsContacts => 'Kontakte';

  @override
  String get settingsInvoices => 'Rechnungen';

  @override
  String get settingsInvoicesSubtitle => 'Wer Sie um Zahlung bitten darf';

  @override
  String get settingsRescan => 'Guthaben neu prüfen';

  @override
  String get settingsRescanFinished => 'Guthaben neu geprüft';

  @override
  String get settingsRescanTitle => 'Guthaben neu prüfen';

  @override
  String get settingsRescanBody =>
      'Prüft die Blockchain erneut auf das Guthaben dieser Wallet.';

  @override
  String get settingsRescanButton => 'Neu prüfen';

  @override
  String get settingsDeleteWallet => 'Wallet löschen';

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
      'Dadurch werden die Wallet, ihr Verlauf und ihre PIN von diesem Smartphone entfernt. Nur die Wiederherstellungsphrase kann das Guthaben zurückbringen. Ohne sie ist es endgültig verloren.';

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
  String get settingsCheckUpdates => 'Nach Updates suchen';

  @override
  String settingsUpdatesFrom(String store) {
    return 'Updates liefert $store.';
  }

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsSendFeedback => 'Problem melden';

  @override
  String get settingsSendFeedbackHint =>
      'Ein Problem melden oder den Entwicklern eine Idee vorschlagen. Protokolle gehen nur mit, wenn Sie sie anhängen; Wiederherstellungsphrase, PIN und andere Geheimnisse werden vorher entfernt.';

  @override
  String get settingsSourceCode => 'Quellcode';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsLicences => 'Lizenzen';

  @override
  String get licencesLead =>
      'Open-Source-Software in dieser Wallet, jede unter ihrer eigenen Lizenz.';

  @override
  String get licencesApp => 'BT Wallet von BT Labs: Apache-2.0.';

  @override
  String get licencesFlutter =>
      'Flutter und seine Dart-Pakete: BSD 3-Clause und ähnliche freizügige Lizenzen.';

  @override
  String get licencesLepic =>
      'LEPIC, die Epic-Cash-Wallet-Bibliothek: Apache-2.0, mit dem secp256k1-zkp-Fork von Epic Cash (CC0) und Rust-Crates unter MIT oder Apache-2.0, darunter tokio, rustls, rusqlite und blake2.';

  @override
  String get licencesTor =>
      'Tor: GNU General Public License, Version 3. Die Quelle steht unten.';

  @override
  String get licencesFonts =>
      'Schriften Montserrat, JetBrains Mono, Geist, Geist Mono und Noto Sans Thai: SIL Open Font License 1.1.';

  @override
  String get licencesFull => 'Alle Lizenztexte';

  @override
  String licencesPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lizenzen',
      one: '$count Lizenz',
    );
    return '$_temp0';
  }

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
  String get settingsPinNewLabel => 'Neue PIN';

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
  String get helpSendFeedback => 'Problem melden';

  @override
  String get feedbackTitle => 'Problem melden';

  @override
  String get feedbackIntro =>
      'Beschreiben Sie, was schiefgelaufen ist oder was besser sein könnte.';

  @override
  String get feedbackMessageLabel => 'Was passiert ist';

  @override
  String get feedbackMessageMissing =>
      'Beschreiben Sie in ein paar Worten, was passiert ist.';

  @override
  String get feedbackAttachLogs => 'Protokolle anhängen';

  @override
  String get feedbackAttachLogsHint =>
      'Der neueste Teil des App-Protokolls, ohne Wiederherstellungsphrase, PIN und andere Geheimnisse.';

  @override
  String get feedbackPreviewButton => 'Was gesendet wird';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackShareOrSaveInstead => 'Teilen oder speichern';

  @override
  String get feedbackFileExplanation =>
      'Ihr Feedback wird zu einer Textdatei, die Sie weitergeben oder speichern können.';

  @override
  String get feedbackShareOrSave => 'Teilen oder speichern';

  @override
  String get feedbackShareHint => 'Datei an eine andere App übergeben';

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
  String get settingsSectionPrivacy => 'Datenschutz';

  @override
  String get settingsSectionPrivacyNetwork => 'Datenschutz & Netzwerk';

  @override
  String get settingsSectionNetworkPrivacy => 'Netzwerk & Datenschutz';

  @override
  String get netSummaryTorOn => 'Tor an';

  @override
  String get netSummaryTorOff => 'Tor aus';

  @override
  String get netPageServers => 'Server';

  @override
  String get settingsSectionHelpFeedback => 'Hilfe';

  @override
  String get settingsExperimentTag => 'Experiment';

  @override
  String get settingsStateBackUp => 'Wiederherstellungsphrase sichern';

  @override
  String get settingsStateNotBackedUp => 'Noch nicht gesichert';

  @override
  String settingsStateJoin(String a, String b) {
    return '$a · $b';
  }

  @override
  String settingsUseStatusSite(String site) {
    return '$site nutzen';
  }

  @override
  String get settingsUseStatusSiteSubtitle =>
      'Zeigt, welche Nodes und Epicbox-Server online sind, aus einer öffentlichen Liste auf status.btlabs.uk.';

  @override
  String get txStepStarted => 'Zahlung gestartet';

  @override
  String get txStepAccepted => 'Empfänger hat signiert';

  @override
  String get txStepPosted => 'An das Netzwerk gesendet';

  @override
  String get txStepConfirming => 'Bestätigung';

  @override
  String get txStepConfirmed => 'Bestätigt';

  @override
  String get txStepArrived => 'Zahlung eingegangen';

  @override
  String get txStepSenderFinished => 'Signiert und zurückgeschickt';

  @override
  String get fileHelpTitle => 'So funktioniert eine Transaktionsdatei';

  @override
  String get fileHelpYou => 'Sie';

  @override
  String get fileHelpFriend => 'Gegenüber';

  @override
  String get fileHelpSendStep1 => 'Sie erstellen eine Transaktionsdatei.';

  @override
  String get fileHelpSendStep2 =>
      'Sie schicken sie Ihrem Gegenüber, wie Sie möchten, etwa per Chat-App oder USB-Stick.';

  @override
  String get fileHelpSendStep3 =>
      'Ihr Gegenüber öffnet sie in seiner Wallet und schickt Ihnen die Antwortdatei zurück.';

  @override
  String get fileHelpSendStep4 =>
      'Sie öffnen die Antwortdatei, und die Zahlung ist unterwegs.';

  @override
  String get fileHelpReceiveStep1 =>
      'Ihr Gegenüber erstellt eine Transaktionsdatei für Sie.';

  @override
  String get fileHelpReceiveStep2 =>
      'Es schickt sie Ihnen auf beliebigem Weg, etwa per Chat-App oder USB-Stick.';

  @override
  String get fileHelpReceiveStep3 =>
      'Sie öffnen sie in Ihrer Wallet und schicken die Antwortdatei zurück.';

  @override
  String get fileHelpReceiveStep4 =>
      'Ihr Gegenüber öffnet die Antwortdatei, und die Zahlung ist auf dem Weg zu Ihnen.';

  @override
  String fileHelpStepOf(int step, int count) {
    return 'Schritt $step von $count';
  }

  @override
  String get fileHelpPause => 'Animation anhalten';

  @override
  String get fileHelpPlay => 'Animation abspielen';

  @override
  String get sendStepMethod => 'Zahlungsart';

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
  String get sendAddressMissing => 'Geben Sie die Adresse der Gegenseite ein.';

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
  String get sendAddNote => 'Nachricht hinzufügen';

  @override
  String get sendNoteLabel => 'Nachricht';

  @override
  String get sendNoteHelper => 'Der Empfänger sieht sie.';

  @override
  String get sendReviewMessageKept =>
      'Der Empfänger sieht sie. Eine Kopie bleibt als Ihre private Notiz gespeichert.';

  @override
  String get sendNetworkFee => 'Netzwerkgebühr';

  @override
  String get sendChecking => 'Wird geprüft…';

  @override
  String get sendReady => 'Bereit zum Senden';

  @override
  String get sendNodeDown => 'Das Netzwerk ist gerade nicht erreichbar.';

  @override
  String sendRelayDown(String relay) {
    return 'Der Epicbox-Server der Gegenseite ($relay) antwortet nicht.';
  }

  @override
  String get sendListenerDown =>
      'Noch nicht verbunden. Sie können trotzdem senden.';

  @override
  String get sendPayWithFile => 'Stattdessen mit Datei zahlen';

  @override
  String get sendAnyway => 'Trotzdem senden';

  @override
  String sendTrackWaitingFor(String name) {
    return 'Warten auf die Wallet von $name';
  }

  @override
  String get sendTrackWaiting => 'Warten auf die Wallet der Gegenseite';

  @override
  String sendTrackOffline(String amount) {
    return 'Die Wallet der Gegenseite signiert sie, sobald sie geöffnet wird. Bis dahin bleiben $amount gesperrt.';
  }

  @override
  String get sendTrackIfNot => 'Was, wenn sie nie abgeschlossen wird?';

  @override
  String get sendTrackCancelled => 'Diese Zahlung wurde storniert.';

  @override
  String get sendNoCoins => 'Noch keine Coins zum Senden.';

  @override
  String get sendFileTitle => 'Direkt · Dateiübertragung';

  @override
  String get sendMakeFile => 'Transaktionsdatei erstellen';

  @override
  String sendFileOnHold(String amount) {
    return '$amount gesperrt';
  }

  @override
  String get sendFileWaitingReply => 'Warten auf die Antwortdatei';

  @override
  String get sendFileShareHint =>
      'Senden Sie diese Datei an die Gegenseite. Öffnen Sie dann die Antwortdatei.';

  @override
  String get sendOpenReply => 'Antwortdatei öffnen';

  @override
  String get handshakeRequest => 'Rechnung';

  @override
  String get handshakeYou => 'Sie';

  @override
  String get handshakeThem => 'Gegenseite';

  @override
  String get handshakeNetwork => 'Netzwerk';

  @override
  String get handshakePay1 =>
      'Ihre Wallet sendet die Zahlung an den Epicbox-Server. Die Coins werden gesperrt.';

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
      'Ihre Wallet sendet die Rechnung an den Epicbox-Server.';

  @override
  String get handshakeReq2 =>
      'Der Server leitet sie weiter. Die Gegenseite stimmt zu, ihre Wallet fügt die Coins hinzu und signiert.';

  @override
  String get handshakeRelay => 'Epicbox-Server';

  @override
  String get handshakeFile => 'Dateiübertragung';

  @override
  String get handshakeBack =>
      'Die Wallet der Gegenseite schickt sie an den Epicbox-Server zurück.';

  @override
  String get handshakeRelayBack => 'Der Server gibt sie an Ihre Wallet zurück.';

  @override
  String get handshakeFile1 =>
      'Ihre Wallet speichert eine Transaktionsdatei. Sie senden sie selbst an die Gegenseite.';

  @override
  String get handshakeFile2 =>
      'Die Gegenseite öffnet sie. Ihre Wallet ergänzt ihren Teil, signiert und speichert eine Antwortdatei.';

  @override
  String get handshakeFile3 =>
      'Die Gegenseite schickt Ihnen die Antwortdatei zurück.';

  @override
  String get handshakeFile4 => 'Sie öffnen die Antwortdatei in Ihrer Wallet.';

  @override
  String get handshakePrevious => 'Vorheriger Schritt';

  @override
  String get handshakeLink1 =>
      'Ihre Wallet sendet die Zahlung direkt an die Wallet der Gegenseite, über das Internet oder Tor. Die Coins werden gesperrt.';

  @override
  String get handshakeLink2 =>
      'Die Wallet der Gegenseite ergänzt ihren Teil, signiert und antwortet über dieselbe Verbindung.';

  @override
  String get handshakeQr1 => 'Sie zeigen Ihren Code.';

  @override
  String get handshakeQr2 => 'Die Gegenseite scannt ihn mit ihrer Wallet.';

  @override
  String get handshakeQr3 =>
      'Ihre Gegenseite sieht in ihrer Wallet einen Antwort-Code.';

  @override
  String get handshakeQr4 => 'Sie scannen ihn.';

  @override
  String get handshakeQr5 => 'Ihre Wallet sendet die Zahlung an das Netzwerk.';

  @override
  String get handshakeQrR1 => 'Die Gegenseite zeigt ihren Code.';

  @override
  String get handshakeQrR2 => 'Sie scannen ihn mit Ihrer Wallet.';

  @override
  String get handshakeQrR3 => 'Ihre Wallet zeigt einen Antwort-Code.';

  @override
  String get handshakeQrR4 => 'Die Gegenseite scannt ihn.';

  @override
  String get handshakeQrR5 =>
      'Die Wallet der Gegenseite sendet die Zahlung an das Netzwerk.';

  @override
  String get handshakeNext => 'Nächster Schritt';

  @override
  String sendRelayRefused(int days, String relay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Der Epicbox-Server der Gegenseite ($relay) hat sie abgelehnt. Der Betrag bleibt gesperrt, bis Sie stornieren, höchstens $days Tage.',
      one:
          'Der Epicbox-Server der Gegenseite ($relay) hat sie abgelehnt. Der Betrag bleibt gesperrt, bis Sie stornieren, höchstens 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayRefusedLost(String relay) {
    return 'Der Epicbox-Server der Gegenseite ($relay) hat sie abgelehnt. Prüfen Sie die Wallet, bevor Sie erneut senden.';
  }

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
    return '$amount gesperrt';
  }

  @override
  String balanceLineComingIn(String amount) {
    return '+$amount unterwegs';
  }

  @override
  String get receiveTorAddressLabel => 'Link · Tor-Adresse';

  @override
  String get receiveTorQrLabel => 'QR-Code Ihrer Tor-Adresse';

  @override
  String get torStateOff => 'Empfang über Tor ist aus';

  @override
  String torStateStarting(int percent) {
    return 'Verbindung mit Tor… $percent %';
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
      'Tor konnte keine Verbindung herstellen. Versuchen Sie es erneut oder schalten Sie Tor aus.';

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
  String get sendTorReady => 'Bereit zum Senden über Tor';

  @override
  String get sendTorReaching =>
      'Die Wallet der Gegenseite wird über Tor erreicht… Lassen Sie die App offen.';

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
  String get sendTorTryEpicbox =>
      'Epicbox stellt eine Zahlung auch zu, während die Wallet der Gegenseite offline ist.';

  @override
  String sendTorNothingSent(String reason) {
    return '$reason Es wurde nichts gesendet.';
  }

  @override
  String get sendTryAgain => 'Erneut versuchen';

  @override
  String get sendCancelPayment => 'Zahlung stornieren';

  @override
  String get homeWalletBalance => 'Guthaben';

  @override
  String get homeTileWaitingSender => 'Wartet auf Absender';

  @override
  String get homeTileLocked => 'In Zahlungen gesperrt';

  @override
  String get homeTileTotal => 'Gesamt';

  @override
  String homeViewAll(int count) {
    return 'Alle $count anzeigen';
  }

  @override
  String get tourPhoneSemantics => 'Wallet-Tour';

  @override
  String tourPhoneCounter(int current, int total) {
    return '$current von $total';
  }

  @override
  String get tourPhoneSkip => 'Tour überspringen';

  @override
  String get tourPhoneBack => 'Zurück';

  @override
  String get tourPhoneNext => 'Weiter';

  @override
  String get tourPhoneWalletTitle => 'Wallet';

  @override
  String get tourPhoneWalletText =>
      'Ihr Guthaben und darunter die Symbole für Node, Epicbox und Tor. Was noch bestätigt wird, steht in den Kacheln darunter.';

  @override
  String get tourPhoneSendTitle => 'Senden';

  @override
  String get tourPhoneSendText =>
      'Fügen Sie eine Adresse ein oder scannen Sie sie, oder wählen Sie einen Kontakt. Epicbox zahlt an eine Adresse; QR zeigt einem Smartphone neben Ihnen einen Code. Weitere Wege: Einstellungen › Transaktionen. Zuerst kommt eine Prüfung.';

  @override
  String get tourPhoneReceiveTitle => 'Empfangen';

  @override
  String get tourPhoneReceiveText =>
      'Ihre Epicbox-Adresse. Teilen Sie sie, um bezahlt zu werden. Der Tab Datei ist für Transaktionsdateien zum Signieren oder Abschließen.';

  @override
  String get tourPhoneActivityTitle => 'Aktivität';

  @override
  String get tourPhoneActivityText =>
      'Jede Zahlung mit Stand und Details. Tippen Sie auf eine, um sie zu öffnen.';

  @override
  String get tourPhoneInvoicesTitle => 'Rechnungen';

  @override
  String get tourPhoneInvoicesText =>
      'Bezahlen Sie eine Rechnung, die Ihnen jemand geschickt hat, oder bitten Sie jemanden um eine Zahlung. Die Tabs wechseln zwischen beiden.';

  @override
  String get tourPhoneDevicesText =>
      'Diese Wallet auf einem zweiten Gerät: Jedes zeigt die Zahlungen des anderen. Ein Experiment.';

  @override
  String get tourPhonePrivacyTitle => 'Datenschutz & Netzwerk';

  @override
  String get tourPhonePrivacyText =>
      'Welchen Node und welchen Epicbox-Server die Wallet nutzt, und der Tor-Schalter. Tippen Sie auf einen Server, um ihn zu ändern.';

  @override
  String get tourPhoneNetworkText =>
      'Der Netzwerkmodus, auch Nur Tor, und die Server, die die Wallet nutzt. Tippen Sie auf einen Server, um ihn zu ändern.';

  @override
  String get tourPhoneNetworkTextNoTor =>
      'Der Netzwerkmodus und die Server, die die Wallet nutzt. Tippen Sie auf einen Server, um ihn zu ändern.';

  @override
  String get tourPhoneAdvancedTitle => 'Erweitert';

  @override
  String get tourPhoneAdvancedText =>
      'Der Nur-Tor-Modus, Outputs und technische Details sind hier. Schalten Sie ein, was Sie brauchen.';

  @override
  String get tourAdvancedShowsText =>
      'Outputs und technische Details sind hier. Schalten Sie ein, was Sie brauchen.';

  @override
  String get tourPhoneHelpTitle => 'Hilfe';

  @override
  String get tourPhoneHelpText =>
      'Hilfethemen, Problem melden und Tour erneut zeigen.';

  @override
  String get tourPhoneShowAgain => 'Tour erneut zeigen';

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
    return 'Geben Sie die PIN ein, um eine Transaktionsdatei über $amount zu erstellen.';
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
  String outputsWaitLocked(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '$blocks Bestätigung',
    );
    return 'Warten, bis die laufende Zahlung $_temp0 hat.';
  }

  @override
  String get outputsStrategy => 'Strategie für Zahlungen';

  @override
  String get outputsStrategyHint =>
      'Welche Outputs eine Zahlung verbraucht. Kleinste verbraucht die kleinsten Outputs, die den Betrag decken; Alle verbraucht jeden Output und gibt einen zurück.';

  @override
  String get outputsSmallest => 'Kleinste';

  @override
  String get outputsAll => 'Alle';

  @override
  String get outputsSmallestText =>
      'Verbraucht die kleinsten Outputs, die den Betrag decken; der Rest bleibt verfügbar.';

  @override
  String get outputsAllText =>
      'Verbraucht jeden verfügbaren Output und gibt einen Wechselgeld-Output zurück. Alles ist gesperrt, bis er bestätigt ist; danach weniger, größere Outputs.';

  @override
  String get outputsSplitChange => 'Wechselgeld teilen';

  @override
  String get outputsSplitChangeText =>
      'Blieben nach einer Zahlung weniger als 3 verfügbare Outputs übrig und beträgt das Wechselgeld mindestens 1 EPIC, kommt es als bis zu 4 Outputs zurück, sodass die nächsten Zahlungen nicht auf Bestätigungen warten. Jeder zusätzliche Output kostet 0,004 EPIC.';

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
  String get outputsWordFinalizing => 'Wartet auf die Antwort';

  @override
  String get outputsWordImmature => 'Reift';

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
  String get outputsEmptyHint => 'Die erste empfangene Zahlung erzeugt einen.';

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
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Blöcken',
      one: '$blocks Block',
    );
    return 'Verbraucht $spent ($amount) und erzeugt $made zu je etwa $each. Eine normale Netzwerktransaktion an diese Wallet, nach $_temp0 bestätigt wie jede Zahlung; alles Verfügbare ist bis dahin gesperrt. Mit mehreren Outputs können die nächsten Zahlungen hinausgehen, ohne auf das Wechselgeld der anderen zu warten.';
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
  String outputsFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Blöcke',
      one: '$blocks Block',
    );
    return '$amount, etwa $_temp0';
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
  String outputsConsolidateText(
    String amount,
    String result,
    String spent,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '$blocks Bestätigung',
    );
    return 'Verbraucht $spent ($amount) und erzeugt einen Output über $result. Alles Verfügbare ist für $_temp0 gesperrt.';
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
  String outputsSplitStarted(int count, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Blöcken',
      one: '$blocks Block',
    );
    return 'Aufteilen gestartet: $count Outputs, Bestätigung in etwa $_temp0';
  }

  @override
  String outputsConsolidateStarted(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Blöcken',
      one: '$blocks Block',
    );
    return 'Zusammenführen gestartet: ein Output, Bestätigung in etwa $_temp0';
  }

  @override
  String get outputsAdvanced => 'Outputs verwalten';

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
  String get contactTakesNoPayments => 'Nimmt keine Zahlungen an';

  @override
  String get contactNoPayments => 'Keine Zahlungen';

  @override
  String contactNoPaymentsNamed(String name) {
    return '$name nimmt keine Zahlungen an.';
  }

  @override
  String get linkNoPaymentsTitle => 'Nimmt keine Zahlungen an';

  @override
  String get contactsSendAction => 'Senden';

  @override
  String get contactsNoteHeading => 'Notiz';

  @override
  String get contactsShowCode => 'Code zeigen';

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
  String get invoicesNewRequest => 'Neue Rechnung';

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
  String get invoicesSentEmpty => 'Keine Rechnungen gesendet';

  @override
  String get invoicesSentEmptyCaption =>
      'Eine Rechnung bittet jemanden, Ihnen einen Betrag zu zahlen.';

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
  String get invoicesNodeOk => 'Synchronisiert';

  @override
  String get invoicesNodeDown => 'Antwortet nicht';

  @override
  String get invoicesEpicboxOk => 'Verbunden';

  @override
  String get invoicesEpicboxDown => 'Nicht verbunden';

  @override
  String invoicesRequestSummary(String payer, String amount) {
    return '$payer wird gebeten, $amount zu zahlen. Die Rechnung läuft in 24 h ab.';
  }

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
    return 'Synchronisierung $percent %';
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
  String get netStatusOff => 'Aus';

  @override
  String get netStatusConnected => 'Verbunden';

  @override
  String get netStatusNotConnected => 'Nicht verbunden';

  @override
  String get stateReceiving => 'Empfängt';

  @override
  String get stateUnchecked => 'Nicht geprüft';

  @override
  String get serverUpNotConnected => 'Server erreichbar · nicht verbunden';

  @override
  String get netStatusOn => 'An';

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
      'Öffnet die Adresse für den Link-Empfang';

  @override
  String get netStatusOpenHint => 'Zeigt die Server';

  @override
  String get serverNodeTitle => 'Node';

  @override
  String get serverEpicboxTitle => 'Epicbox';

  @override
  String serverTestFailed(String error) {
    return 'Keine Antwort. $error';
  }

  @override
  String serverHealthUnknown(String site) {
    return '$site nicht erreichbar; Zustand unbekannt';
  }

  @override
  String get serverAtTip => 'synchronisiert';

  @override
  String serverBehindShort(String count) {
    return '$count zurück';
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
  String get serverNotResponding => 'Antwortet nicht';

  @override
  String get serverLocalNotReachable =>
      'Von diesem Computer aus nicht erreichbar';

  @override
  String get serverLocalNotReachablePhone =>
      'Von diesem Smartphone aus nicht erreichbar';

  @override
  String get serverHealthy => 'Funktioniert';

  @override
  String get serverDegraded => 'Im Rückstand';

  @override
  String get serverHealthNone => 'Status unbekannt';

  @override
  String get serverCurrent => 'In Verwendung';

  @override
  String get serverDefault => 'Standard';

  @override
  String serverLatency(String ms) {
    return '$ms ms';
  }

  @override
  String serverUptime(String percent) {
    return '$percent % erreichbar';
  }

  @override
  String get serverAdd => 'Hinzufügen';

  @override
  String get serverAlreadyInUse => 'Wird bereits verwendet.';

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
    return '$height · synchronisiert';
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
  String serverCheckedAt(String time, String site) {
    return '$site, geprüft $time';
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
  String get methodFile => 'Dateiübertragung';

  @override
  String get methodShortHttp => 'Link · HTTP';

  @override
  String get methodShortTor => 'Link · Tor';

  @override
  String get methodShortQr => 'Direkt · QR';

  @override
  String get methodShortFile => 'Direkt · Datei';

  @override
  String get methodGroupHttp => 'HTTP';

  @override
  String get methodGroupTor => 'Tor';

  @override
  String get methodDirectQr => 'Direkt · QR-Zahlung';

  @override
  String get methodDirectFile => 'Direkt · Dateiübertragung';

  @override
  String get methodDirectFamily => 'Direkt';

  @override
  String get methodArtCaptionEpicbox => 'Epicbox-Server hält sie';

  @override
  String get methodArtCaptionHttp => 'Direkt zur Wallet';

  @override
  String get methodArtCaptionFile => 'Datei hin, Antwort zurück';

  @override
  String get methodArtLabelEpicbox =>
      'Epicbox: Die Zahlung geht an den Epicbox-Server, der sie hält, bis die Wallet der Gegenseite wieder da ist';

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
  String get methodSendFileTitle => 'Keine Verbindung nötig.';

  @override
  String get methodSendFileLine =>
      'Datei übergeben, Antwortdatei zurückbekommen, dann hier öffnen.';

  @override
  String get methodReceiveEpicboxTitle => 'Teilen, um bezahlt zu werden.';

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
  String get sendToHint => 'Adresse, Zahlungslink oder Kontakt';

  @override
  String get sendSwitchedEpicbox => 'Über Epicbox';

  @override
  String get sendSwitchedEpicboxAnnounce =>
      'Epicbox-Adresse. Methode auf Epicbox gestellt.';

  @override
  String get sendCancelRuleEpicbox =>
      'Kann storniert werden, solange sie auf die Gegenseite wartet.';

  @override
  String get sendCancelRuleDirect =>
      'Kann nicht storniert werden, sobald die Wallet der Gegenseite sie annimmt.';

  @override
  String get sendCancelRuleFile =>
      'Kann storniert werden, bis Sie die Antwortdatei öffnen.';

  @override
  String get sendHttpReaching =>
      'Wallet der Gegenseite wird erreicht… App geöffnet lassen.';

  @override
  String get sendDeliveredWaitingBlock => 'Zugestellt · Wartet auf einen Block';

  @override
  String get sendPlainHttpOffWithTor =>
      'Reines http:// geht nicht, solange Tor an ist.';

  @override
  String get sendPlainHttpOffWithTorWhy =>
      'Nehmen Sie eine https://- oder Onion-Adresse oder Epicbox.';

  @override
  String get receiveTorCaption =>
      'Manche Wallets zeigen die Adresse ohne .onion; beides ist dieselbe Adresse.';

  @override
  String sendHttpNotReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Die Wallet der Gegenseite war nicht erreichbar. Der Betrag bleibt gesperrt, bis Sie stornieren, höchstens $days Tage.',
      one: 'Die Wallet der Gegenseite war nicht erreichbar. Der Betrag bleibt gesperrt, bis Sie stornieren, höchstens 1 Tag.',
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
      'Die Listen zeigen, was zuvor ankam; die Wallet versucht es erneut.';

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
  String get deskInvPayNotDelivered => 'Nicht zugestellt';

  @override
  String get deskInvPayDelivered => 'Wartet auf Netzwerk';

  @override
  String deskInvPayPosted(String name) {
    return 'Von $name veröffentlicht';
  }

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
  String get deskInvFailed =>
      'Das hat nicht geklappt. Nichts wurde geändert; versuchen Sie es erneut.';

  @override
  String get deskInvHowItWorks => 'So funktionieren Rechnungen';

  @override
  String get deskInvIssuerSoon => 'Demnächst';

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
    return '$used / $max Byte';
  }

  @override
  String get deskInvIssuerMessageLong => 'Die Nachricht ist zu lang.';

  @override
  String deskInvIssuerExpiry(int hours) {
    return 'Der Zahler hat $hours Stunden Zeit zum Zahlen.';
  }

  @override
  String get deskInvIssuerRelayDown =>
      'Der Epicbox-Server antwortet nicht, daher kann jetzt keine Rechnung gesendet werden.';

  @override
  String get deskInvIssuerNotDelivered =>
      'Die Rechnung hat den Epicbox-Server nicht erreicht. Es wurde nichts gesendet. Versuchen Sie es erneut.';

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
    return '$payer kann sie dann nicht mehr bezahlen. Nichts wurde bezahlt, also bewegen sich keine Coins.';
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
    return 'Die Wallet von $payer kann keine Rechnungen bezahlen; bitten Sie $payer stattdessen um eine Zahlung.';
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
    return 'Über Epicbox zugestellt. Nichts ist bezahlt, bis $payer zustimmt.';
  }

  @override
  String get deskInvIssuerCopySlate => 'Slate-ID kopieren';

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
      'Eine Zahlung für eine Rechnung, die dieses Gerät nicht ausgestellt hat, ist eingetroffen. Sie bleibt einen Tag lang auf dem Server für Ihr anderes Gerät mit dieser Wallet: Öffnen Sie die Wallet dort, um sie abzuschließen.';

  @override
  String get deskInvNoticeUnknownAnswer =>
      'Eine Antwort auf eine Zahlung, die dieses Gerät nicht gesendet hat, ist eingetroffen. Sie bleibt einen Tag lang auf dem Server für Ihr anderes Gerät mit dieser Wallet: Öffnen Sie die Wallet dort, um sie abzuschließen.';

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
  String get deskInvPayerEmptyTitle => 'Keine Rechnungen warten';

  @override
  String get deskInvPayerEmptyText =>
      'Rechnungen von erlaubten gekoppelten Kontakten erscheinen hier; bezahlt wird nur nach Zustimmung.';

  @override
  String deskInvPayerNotDeliveredTitle(String service) {
    return 'Ihre Zahlung an $service wurde nicht zugestellt';
  }

  @override
  String get deskInvPayerNotDeliveredText =>
      'Sie ist signiert und auf diesem Computer gespeichert; die EPIC bleiben gesperrt. „Erneut senden“ schickt sie ohne zweite Zustimmung noch einmal.';

  @override
  String deskInvPayerWithdrawnTitle(String service) {
    return '$service hat eine bezahlte Rechnung zurückgezogen';
  }

  @override
  String get deskInvPayerWithdrawnText =>
      'Die Zahlung erreicht die Chain vielleicht nie. Stornieren Sie sie, um die Coins freizugeben.';

  @override
  String deskInvPayerPastTtlTitle(String service) {
    return 'Ihre Zahlung an $service ist nicht in der Blockchain';
  }

  @override
  String get deskInvPayerPastTtlText =>
      'Ihre Frist ist abgelaufen und das Netzwerk hat sie nicht gesehen. Stornieren Sie sie, um die Coins freizugeben.';

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
  String deskInvPayerMessageCaption(String name) {
    return 'Von $name geschrieben. Ihre Wallet prüft sie nicht.';
  }

  @override
  String get deskInvPayerPaysTo => 'Zahlt an';

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
  String deskInvPayerShortText(
    String total,
    String spendable,
    int confirmations,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'ab $confirmations Bestätigungen',
      one: 'ab 1 Bestätigung',
    );
    return 'Sie brauchen $total EPIC verfügbar; Sie haben $spendable EPIC. Guthaben, das noch bestätigt wird, zählt $_temp0.';
  }

  @override
  String get deskInvPayerNodeDownTitle => 'Der Node antwortet nicht';

  @override
  String get deskInvPayerNodeDownText =>
      'Die Wallet kann Ihr Guthaben nicht prüfen und daher nicht zahlen. Zustimmen geht wieder, sobald der Node antwortet; unter Einstellungen › Node können Sie einen anderen wählen.';

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
      'Der Epicbox-Server antwortet nicht. Senden Sie sie unter Rechnungen › Bezahlen erneut; ohne zweite Zustimmung.';

  @override
  String get deskInvPayerRetryFailed => 'Immer noch nicht zugestellt';

  @override
  String get deskInvPayerRetryFailedText =>
      'Der Epicbox-Server antwortet nicht. Die Zahlung bleibt signiert auf diesem Gerät.';

  @override
  String get deskInvPayerCancelTitle => 'Diese Zahlung stornieren?';

  @override
  String get deskInvPayerCancelText =>
      'Die andere Seite kann diese Zahlung noch abschließen.';

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
  String get deskInvPayerSpentText =>
      'Die Coins sind auf dem Weg zurück zu dieser Wallet.';

  @override
  String get deskInvPayerSpendFailedText =>
      'Die Coins konnten noch nicht zurückgeschickt werden. Die Wallet versucht es erneut, solange sie geöffnet ist; bis dahin kann die Zahlung noch durchgehen.';

  @override
  String get deskInvPayerLocked =>
      'Diese Rechnung kann nicht bezahlt werden: Sie ist bis zu einem späteren Block gesperrt. Nichts wurde bezahlt.';

  @override
  String get deskInvPayerRelayDownPay =>
      'Der Epicbox-Server antwortet nicht. Es wurde nichts bezahlt.';

  @override
  String get deskInvSetTitle => 'Rechnungen';

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
  String get deskInvSetReceiveHint =>
      'Bitten Sie einen gekoppelten Kontakt um Zahlung oder speichern Sie die Rechnung als Datei.';

  @override
  String get helpButton => 'Hilfe';

  @override
  String get helpSearchHint => 'Hilfe durchsuchen';

  @override
  String get helpEnglishOnly => 'Die Hilfe ist vorerst auf Englisch.';

  @override
  String get helpLanguageLabel => 'Hilfesprache';

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
  String get sendAvailableWhileConfirms =>
      'Verfügbar, solange dies bestätigt wird';

  @override
  String get sendSpendableUntilChangeHint =>
      'Das Wechselgeld kommt zurück, sobald die Zahlung bestätigt ist.';

  @override
  String serverSwitched(String host) {
    return 'Gewechselt zu $host';
  }

  @override
  String get methodDirect => 'Link';

  @override
  String methodDirectShape(String port) {
    return 'http://host:$port oder xxxx….onion';
  }

  @override
  String get methodSendDirectLine =>
      'Ihre Wallet muss geöffnet sein. Eine Onion-Adresse läuft über Tor.';

  @override
  String methodArtSpokenLink(String method) {
    return '$method: Die Zahlung geht direkt an die Wallet des Empfängers, die geöffnet sein muss';
  }

  @override
  String methodArtSpokenQr(String method) {
    return '$method: Ein Code wandert von einem Smartphone zum Smartphone daneben';
  }

  @override
  String methodArtSpokenFile(String method) {
    return '$method: Eine Transaktionsdatei wird übergeben, eine Antwortdatei kommt zurück, dann schließt der Absender ab';
  }

  @override
  String get methodReceiveEpicboxShort =>
      'Adresse teilen, um bezahlt zu werden.';

  @override
  String get methodReceiveEpicboxMore =>
      'Der Epicbox-Server hält eine Zahlung bereit, bis diese Wallet geöffnet wird.';

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
  String get sendSwitchedDirect => 'Link-Adresse';

  @override
  String get sendSwitchedDirectAnnounce =>
      'Link-Adresse. Methode auf Link gesetzt.';

  @override
  String get sendDirectAddressShape =>
      'Eine Link-Adresse beginnt mit http:// oder https:// oder endet auf .onion.';

  @override
  String get torNotOverTor => 'Ohne Tor';

  @override
  String get torNeeds => 'Link · Tor braucht Tor.';

  @override
  String get torTurnOn => 'Tor einschalten';

  @override
  String get torTurnOff => 'Tor ausschalten';

  @override
  String get torTurnOffCaption =>
      'Gilt für jede Verbindung, nicht nur für diese Zahlung.';

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
      'Die Netzwerkaktivität läuft über das Tor-Netzwerk. Um unter einer Tor-Adresse bezahlt zu werden, schalten Sie Link · Tor unter Einstellungen › Transaktionen ein.';

  @override
  String get receiveTabDirect => 'Link';

  @override
  String get receiveDirectNeedsTor => 'Link · Tor braucht Tor.';

  @override
  String get receiveDirectMeanwhile =>
      'Teilen Sie bis dahin die Epicbox-Adresse.';

  @override
  String get receiveHttpShowQr => 'QR anzeigen';

  @override
  String get receiveHttpHideQr => 'QR ausblenden';

  @override
  String get netStatusOverTor => 'über Tor';

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
      'Die Wallet des Empfängers ist über Tor nicht erreichbar. Epicbox stellt eine Zahlung auch zu, während sie offline ist';

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
      'Das ist eine Test-Wallet und lässt sich nicht importieren.';

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
  String get deskErrProofSeedRead => 'Wiederherstellungsphrase gelesen';

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
      'Der Verlauf liegt in einem älteren Datenbankformat vor und ist nicht lesbar; der Scan stellt das Guthaben wieder her';

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
    return 'Verbindung mit Tor… $percent %';
  }

  @override
  String get deskErrHistOtherWallet => 'Daten einer anderen Wallet';

  @override
  String get deskErrHistOtherChain => 'Falsches Netzwerk';

  @override
  String get deskErrHistNotOurs => 'Keine Wallet-Datendatei';

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
  String get deskErrHistChains =>
      'Die Datei stammt aus einem anderen Netzwerk.';

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
      'Die Datei wurde nicht von BT Wallet erstellt.';

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
    return 'Fehler des Update-Servers ($status).';
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
  String get deskNodeAtTip => 'synchronisiert';

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
  String get deskNodeStartIt => 'Starten Sie ihn unter Einstellungen › Node.';

  @override
  String deskNodeFailPort(String port) {
    return 'Port $port wird von einem anderen Programm genutzt';
  }

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
  String get deskNodeStageKernels => 'Prüfung der Blockchain';

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
    return 'Blockchain wird geprüft · $done von $total Mio.';
  }

  @override
  String get deskNodeLineKernelsBare => 'Blockchain wird geprüft';

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
      'Die Netzwerkaktivität läuft über das Tor-Netzwerk.';

  @override
  String get deskTorOff => 'Aus';

  @override
  String get deskTorStarting => 'Startet…';

  @override
  String get deskTorOn => 'An';

  @override
  String get deskTorNotConnected => 'Nicht verbunden';

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
  String get deskRecvTorDownText =>
      'Tor konnte keine Verbindung herstellen. Versuchen Sie es erneut oder schalten Sie Tor aus.';

  @override
  String get deskRecvTorStartingText =>
      'Die Adressen werden erreichbar, sobald Tor verbunden ist.';

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
  String get deskRecvEpicboxIntro => 'Teilen, um bezahlt zu werden.';

  @override
  String get deskRecvCheckSix =>
      'Beim Vorlesen die ersten sechs und letzten sechs Zeichen prüfen.';

  @override
  String get deskRecvHttpAddress => 'Link · HTTP-Adresse';

  @override
  String get deskRecvCopyHttp => 'Link · HTTP-Adresse kopieren';

  @override
  String get deskRecvHttpIntro =>
      'Für Wallets im lokalen Netzwerk, solange diese Wallet geöffnet ist.';

  @override
  String get deskRecvHttpTorHint =>
      'Schalten Sie Tor unter Einstellungen › Datenschutz ein, um stattdessen eine Tor-Adresse zu erhalten.';

  @override
  String get deskRecvDirectTor => 'Link · Tor-Adresse';

  @override
  String get deskRecvTorIntro =>
      'Direkt von einer anderen Wallet über Tor, solange diese geöffnet ist. Tor wird unter Einstellungen › Datenschutz eingestellt.';

  @override
  String get deskRecvTorAddress => 'Link · Tor-Adresse';

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
      'Die Transaktionsdatei des Absenders signieren und die Antwortdatei speichern.';

  @override
  String get deskRecvOpen => 'Öffnen';

  @override
  String get deskRecvFinalizeTitle => 'Antwortdatei abschließen';

  @override
  String get deskRecvFinalizeText =>
      'Die Antwortdatei des Empfängers abschließen, um die Zahlung an das Netzwerk zu senden.';

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
  String get deskSendSpendableWhile => 'Verfügbar, solange dies bestätigt wird';

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
  String deskSendLockAll(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'etwa $blocks Blöcke',
      one: 'etwa 1 Block',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'etwa $blocks Blöcke',
      one: 'etwa 1 Block',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alles ist gesperrt: $count Outputs, $amount EPIC, $_temp0.',
      one: 'Alles ist gesperrt: 1 Output, $amount EPIC, $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String deskSendLockSome(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'etwa $blocks Blöcke',
      one: 'etwa 1 Block',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'etwa $blocks Blöcke',
      one: 'etwa 1 Block',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Outputs gesperrt, $amount EPIC, $_temp0.',
      one: '1 Output gesperrt, $amount EPIC, $_temp1.',
    );
    return '$_temp2';
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
  String deskSendReviewSetAsideNone(String locked) {
    return '$locked EPIC gehen unverändert raus; nichts wird zurückgehalten.';
  }

  @override
  String deskSendReviewLocksAll(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alles: $locked EPIC in $count Outputs, bis das Wechselgeld bestätigt ist $_temp0. Nichts bleibt verfügbar.',
      one:
          'Alles: $locked EPIC in 1 Output, bis das Wechselgeld bestätigt ist $_temp1. Nichts bleibt verfügbar.',
    );
    return '$_temp2';
  }

  @override
  String deskSendReviewSetAsideAll(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    return 'Alles: $locked EPIC sind zurückgehalten, bis diese Zahlung bestätigt ist $_temp0. Nichts bleibt verfügbar.';
  }

  @override
  String deskSendReviewLocksEverything(int count, String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count Outputs, bis das Wechselgeld bestätigt ist $_temp0. Bis dahin ist nichts anderes verfügbar.',
      one:
          '$locked EPIC in 1 Output, bis das Wechselgeld bestätigt ist $_temp1. Bis dahin ist nichts anderes verfügbar.',
    );
    return '$_temp2';
  }

  @override
  String deskSendReviewSetAsideEverything(String locked, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    return '$locked EPIC sind zurückgehalten, bis diese Zahlung bestätigt ist $_temp0. Bis dahin ist nichts anderes verfügbar.';
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
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$locked EPIC in $count Outputs, bis das Wechselgeld bestätigt ist $_temp0. $spendable EPIC bleiben verfügbar.',
      one:
          '$locked EPIC in 1 Output, bis das Wechselgeld bestätigt ist $_temp1. $spendable EPIC bleiben verfügbar.',
    );
    return '$_temp2';
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
      other: '($blocks Blöcke)',
      one: '(1 Block)',
    );
    return '$locked EPIC sind zurückgehalten, bis diese Zahlung bestätigt ist $_temp0. $spendable EPIC bleiben verfügbar.';
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
  String get deskSendAdvanced => 'Zahlungsoptionen';

  @override
  String get deskSendAdvStrategy => 'Strategie für diese Zahlung';

  @override
  String get deskSendAdvSmallestText =>
      'Verbraucht die kleinsten Outputs, die den Betrag decken; der Rest bleibt verfügbar.';

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
  String get deskSendErrNotDirect => 'Das ist keine Link-Adresse.';

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
      'Geben Sie diese Datei dem Empfänger und schließen Sie dann mit seiner Antwortdatei ab.';

  @override
  String get deskSendFinalize => 'Abschließen';

  @override
  String get deskSendNewSend => 'Weitere Zahlung senden';

  @override
  String get deskSendNodeNotSynced => 'Node nicht synchronisiert';

  @override
  String deskSendNodeSyncingPct(int percent) {
    return 'Senden ist wieder möglich, sobald der Node synchronisiert ist ($percent %).';
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
  String get deskSendTorStartingText => 'Das Senden wartet auf Tor.';

  @override
  String get deskSendEpicboxOff => 'Epicbox nicht verbunden';

  @override
  String get deskSendEpicboxOffText =>
      'Schalten Sie den Epicbox-Empfang ein, um über Epicbox zu senden, oder nutzen Sie Direkt · Dateiübertragung.';

  @override
  String deskSendEpicboxOffTab(String method) {
    return 'Epicbox-Empfang einschalten, um über Epicbox zu senden, oder $method nutzen.';
  }

  @override
  String get deskSendEpicboxTurnOn => 'Epicbox-Empfang einschalten';

  @override
  String get deskSendDoneViaDirect =>
      'Abgeschlossen und an das Netzwerk gesendet.';

  @override
  String get deskSendDoneViaEpicbox =>
      'An Epicbox übergeben. Wird abgeschlossen, sobald der Empfänger antwortet.';

  @override
  String get deskSendViewTx => 'In Aktivität anzeigen';

  @override
  String get deskSendFailedTitle => 'Senden fehlgeschlagen';

  @override
  String get deskSendReviewAgain => 'Erneut prüfen';

  @override
  String get deskSendTo => 'An';

  @override
  String get deskSendToHelp =>
      'Fügen Sie eine Adresse oder einen Zahlungslink ein oder tippen Sie den Namen eines Kontakts.';

  @override
  String get deskSendToHint => 'Adresse, Zahlungslink oder Kontakt';

  @override
  String get deskSendToSem => 'Empfänger';

  @override
  String get deskSendClearTo => 'Empfänger löschen';

  @override
  String get deskSendContacts => 'Kontakte';

  @override
  String get deskSendNeedsTor => 'Link · Tor braucht Tor';

  @override
  String get deskSendNeedsTorText =>
      'Eine Onion-Adresse ist nur über Tor erreichbar.';

  @override
  String get deskSendNoTorBuild => 'Tor ist in dieser Version nicht enthalten.';

  @override
  String get deskSendTurnOnTor => 'Tor einschalten';

  @override
  String get deskSendHttpClearnet => 'Link · HTTP läuft direkt, ohne Tor.';

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
  String get deskSendAllButton => 'Max.';

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
  String get deskSendMessageHelp => 'Der Empfänger sieht sie.';

  @override
  String get deskSendPrivacyOn => 'Privatsphäre · Dandelion++ an';

  @override
  String get deskSendPrivacyOff => 'Privatsphäre · Dandelion++ aus';

  @override
  String get deskSendDandelionText =>
      'Leitet die Transaktion über einige zufällige Nodes, bevor sie sich verbreitet, was ihre Herkunft schwerer nachvollziehbar macht. Der Node, den die Wallet verwendet, erhält sie trotzdem.';

  @override
  String get deskSendHintSent => 'Gesendet.';

  @override
  String get deskSendHintQueued =>
      'Eingereiht. Geben Sie einen neuen Betrag und Empfänger ein, um erneut zu senden.';

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
  String get deskSendHintFix => 'Korrigieren Sie die markierten Felder.';

  @override
  String get deskSendHintChecking =>
      'Die Gebühr für diesen Betrag wird geprüft.';

  @override
  String get deskSendHintDefault => 'Vor der Prüfung wird nichts gesendet.';

  @override
  String get deskSendReviewWaitTor => 'Warten auf Tor';

  @override
  String get deskSendReviewTorOff => 'Tor nicht verbunden';

  @override
  String get deskSendReview => 'Prüfen';

  @override
  String get deskSendSummary => 'Übersicht';

  @override
  String get deskSendNetworkFee => 'Gebühr';

  @override
  String get deskSendTotal => 'Gesamt';

  @override
  String get deskSendUpdating =>
      'Das Guthaben wird aktualisiert, während die Wallet scannt.';

  @override
  String get deskSendEpicboxLine2 =>
      'Der Epicbox-Server hält die Zahlung, bis der Empfänger seine Wallet öffnet.';

  @override
  String get deskSendDirectLine1 => 'Direkt an die Wallet des Empfängers.';

  @override
  String get deskSendDirectLine2 =>
      'Ihre Wallet muss geöffnet sein. Eine Onion-Adresse läuft über Tor.';

  @override
  String get deskSendFileLine1 => 'Keine Verbindung nötig.';

  @override
  String get deskSendFileLine2 =>
      'Datei übergeben, Antwortdatei zurückbekommen, dann hier abschließen.';

  @override
  String get deskSendSwitchedDirect =>
      'Link-Adresse. Methode auf Link gestellt.';

  @override
  String get deskSendSwitchedFile =>
      'Datei-Adresse. Methode auf Direkt · Datei gestellt.';

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
      'Link · HTTP (die Wallet des Empfängers muss geöffnet sein)';

  @override
  String get deskSendViaTor =>
      'Link · Tor (die Wallet des Empfängers muss geöffnet sein)';

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
      'Jede Zahlung fragt das Wallet-Passwort ab.';

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
  String get deskFinPosted => 'Zahlung an das Netzwerk gesendet';

  @override
  String get deskFinTitle => 'Antwortdatei abschließen';

  @override
  String get deskFinNoticeTitle => 'Für Zahlungen per Datei';

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
      'Keine Transaktionsdatei. Wählen Sie die .tx-Datei, die Ihnen der Absender gegeben hat.';

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
  String get deskActSearchHint => 'Zahlungen suchen';

  @override
  String get deskActSearchLabel => 'Zahlungen durchsuchen';

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
  String get deskActDetailReceived => 'Eingehende Zahlung';

  @override
  String get deskActDetailSent => 'Ausgehende Zahlung';

  @override
  String get deskActLoading => 'Zahlungen werden geladen';

  @override
  String get deskActWaitingNode => 'Warten, bis der Node synchronisiert ist.';

  @override
  String get deskActFilterAll => 'Alle';

  @override
  String get deskActFilterReceived => 'Empfangen';

  @override
  String get deskActFilterSent => 'Gesendet';

  @override
  String deskActNoMatchTitle(String query) {
    return 'Keine Treffer für „$query“.';
  }

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
  String get deskActEmptyTitle => 'Noch keine Zahlungen';

  @override
  String get deskActEmptyText =>
      'Gesendete und empfangene Zahlungen, die neueste zuerst.';

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
  String get deskConNone => 'Noch keine Kontakte';

  @override
  String get deskConNoMatchList => 'Keine passenden Kontakte';

  @override
  String get deskConAdd => 'Kontakt hinzufügen';

  @override
  String get deskConIdle => 'Wählen Sie einen Kontakt.';

  @override
  String get deskConEmptyTitle => 'Noch keine Kontakte';

  @override
  String get deskConEmptyText => 'Ein Kontakt ist ein Name für eine Adresse.';

  @override
  String get deskConSendToAddress => 'An Adresse senden';

  @override
  String deskConLastTx(String when) {
    return 'Letzte Zahlung: $when';
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
  String get deskConNote => 'Notiz';

  @override
  String deskConTxWith(String name) {
    return 'Zahlungen mit $name';
  }

  @override
  String get deskConAllTx => 'Alle Zahlungen';

  @override
  String get deskConTxNone =>
      'Noch keine Zahlungen mit diesem Kontakt. Zahlungen an ihn über Senden erscheinen hier.';

  @override
  String get deskConTxReceived => 'Empfangen';

  @override
  String get deskConTxSent => 'Gesendet';

  @override
  String get deskConErrName => 'Geben Sie dem Kontakt einen Namen.';

  @override
  String get deskConErrAddressEmpty => 'Geben Sie eine Adresse ein.';

  @override
  String get deskConErrAddressInvalid =>
      'Keine gültige Adresse. Verwenden Sie eine Epicbox-Adresse (es5x…@Server), eine Link-Adresse (https://…) oder eine Onion-Adresse (….onion).';

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
      'Entfernt den Kontakt; frühere Zahlungen bleiben unter Aktivität. Das lässt sich nicht rückgängig machen.';

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
      'Outputs sind die Stücke, aus denen das Guthaben besteht. Eine Zahlung verbraucht ganze Outputs und gibt das Wechselgeld als neuen Output zurück.';

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
  String deskOutCardWait(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'etwa $blocks Blöcke',
      one: 'etwa 1 Block',
    );
    return 'Warten Sie, bis die Zahlung bestätigt ist ($_temp0).';
  }

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
      other: 'Verbraucht $count Outputs. Gebühr mindestens $fee EPIC.',
      one: 'Verbraucht $count Output. Gebühr mindestens $fee EPIC.',
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
  String get deskOutNoneText => 'Die erste empfangene Zahlung erzeugt einen.';

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
  String get deskOutTileImmature => 'Mining-Belohnungen';

  @override
  String get deskOutTileLocked => 'In Zahlungen gesperrt';

  @override
  String get deskOutTileTotal => 'Gesamt';

  @override
  String get deskOutStrategyTitle => 'Strategie für Zahlungen';

  @override
  String get deskOutStrategySmallest => 'Kleinste';

  @override
  String get deskOutStrategyAll => 'Alle';

  @override
  String get deskOutStrategyHelpTitle => 'Kleinste oder Alle';

  @override
  String get deskOutSplitChangeTitle => 'Wechselgeld aufteilen';

  @override
  String get deskOutSplitChangeText =>
      'Blieben nach einer Zahlung weniger als 3 verfügbare Outputs übrig und beträgt das Wechselgeld mindestens 1 EPIC, kommt es als bis zu 4 Outputs von je mindestens 0,5 EPIC zurück. Kostet 0,004 EPIC je zusätzlichem Output.';

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
  String get deskOutStatusAwaiting => 'Wartet auf die Antwort';

  @override
  String get deskOutNoteWaitingSender => 'wartet auf den Absender';

  @override
  String get deskOutStatusUnpaid => 'Unbezahlte Rechnung';

  @override
  String get deskOutNoteNotInBalance => 'nicht im Guthaben';

  @override
  String get deskOutStatusImmature => 'Reift';

  @override
  String deskOutNoteBlocksToGo(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $number Bestätigungen',
      one: 'noch $number Bestätigung',
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
  String deskOutNoteByPendingSend(String date) {
    return 'durch eine laufende Zahlung · $date';
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
  String deskOutSplitDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '1 Bestätigung',
    );
    return 'Verbraucht $spent und erzeugt $made. Alles Verfügbare ist für $_temp0 gesperrt.';
  }

  @override
  String deskOutConsDialogText(String spent, String made, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '1 Bestätigung',
    );
    return 'Verbraucht $spent und erzeugt $made. Alles Verfügbare ist für $_temp0 gesperrt.';
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
  String deskOutFactLockedValue(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: 'etwa $blocks Blöcke',
      one: 'etwa 1 Block',
    );
    return '$amount EPIC, $_temp0. Nichts bleibt verfügbar.';
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
  String deskOutSplitDoneText(int count, String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '1 Bestätigung',
    );
    String _temp1 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '1 Bestätigung',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Outputs zu je etwa $amount EPIC, werden bestätigt. Gesperrt für $_temp0.',
      one:
          '$count Output zu etwa $amount EPIC, wird bestätigt. Gesperrt für $_temp1.',
    );
    return '$_temp2';
  }

  @override
  String deskOutConsDoneText(String amount, int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks Bestätigungen',
      one: '1 Bestätigung',
    );
    return 'Ein Output über $amount EPIC, wird bestätigt. Gesperrt für $_temp0.';
  }

  @override
  String get deskOutNotPostedTitle => 'Nicht im Netzwerk';

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
  String get deskOutPostingDesc => 'Wird gesendet';

  @override
  String get deskOutDoneDesc => 'Erledigt';

  @override
  String get deskOutSplitDesc =>
      'Mehr Outputs, damit mehrere Zahlungen aufeinander folgen können.';

  @override
  String get deskOutConsDesc => 'Ein Output statt vieler.';

  @override
  String deskOutNothingText(String what) {
    return 'Nichts zum Zusammenführen: Die Wallet hat $what.';
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
  String deskOvNodeAddrText(String node) {
    return 'Gespeichert als $node.';
  }

  @override
  String get deskOvNodeIncompatTitle => 'Node-Version nicht kompatibel';

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
      'Die Guthaben sind möglicherweise nicht aktuell. Prüfen Sie den Node oder wählen Sie in den Node-Einstellungen einen anderen.';

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
    return 'Node wird synchronisiert: $percent %';
  }

  @override
  String get deskOvSyncText => 'Blöcke werden heruntergeladen.';

  @override
  String get deskOvSyncProgress => 'Fortschritt der Node-Synchronisierung';

  @override
  String deskOvSyncOfChain(int percent) {
    return '$percent % der Blockchain';
  }

  @override
  String get deskOvReceiveEpic => 'EPIC empfangen';

  @override
  String get deskOvSend => 'Senden';

  @override
  String get deskOvReceive => 'Empfangen';

  @override
  String get deskOvSendWaits =>
      'Senden ist wieder möglich, sobald der Node synchronisiert ist.';

  @override
  String deskOvAsOfBlock(String block) {
    return 'Stand Block $block';
  }

  @override
  String get deskOvEmptyHint =>
      'Teilen Sie die Epicbox-Adresse, um die ersten EPIC zu empfangen.';

  @override
  String get deskOvFiatNote => '  gesamtes Guthaben';

  @override
  String get deskOvBreakTotal => 'Gesamt';

  @override
  String get deskOvBreakConfirming => 'Wird bestätigt';

  @override
  String get deskOvBreakImmature => 'Mining-Belohnungen';

  @override
  String get deskOvBreakAwaiting => 'Wartet auf Absender';

  @override
  String get deskOvBreakLocked => 'In Zahlungen gesperrt';

  @override
  String get deskOvUpdating => 'Aktualisierung';

  @override
  String get deskOvHiddenAmount => 'Betrag verborgen';

  @override
  String get deskOvLoading => 'Zahlungen werden geladen';

  @override
  String get deskOvEmptyTitle => 'Noch keine Zahlungen';

  @override
  String deskOvEmptyText(int blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other:
          'Empfangene EPIC erscheinen als „Wird bestätigt“, nach $blocks Bestätigungen als verfügbar.',
      one:
          'Empfangene EPIC erscheinen als „Wird bestätigt“, nach $blocks Bestätigung als verfügbar.',
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
      other: '$count Zahlungen per Datei abzuschließen',
      one: '$count Zahlung per Datei abzuschließen',
    );
    return '$_temp0';
  }

  @override
  String get deskOvPendingText =>
      'Schließen Sie sie mit der Antwortdatei des Empfängers ab.';

  @override
  String get deskOvFinalize => 'Abschließen';

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
  String get deskTxNoteBlock => 'Zeit des Blocks. Der Absender ist unbekannt.';

  @override
  String get deskTxNoteScanTime =>
      'Zeit des Scans; die Zeit des Blocks war nicht lesbar. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxNoteUnknown => 'Der Absender ist nicht gespeichert.';

  @override
  String get deskTxFoundRestoredLabel => 'Wiederhergestellt';

  @override
  String get deskTxFoundRestoredLine => 'In der Blockchain gefunden';

  @override
  String get deskTxFoundRestoredStep => 'In der Blockchain gefunden';

  @override
  String get deskTxFoundRestoredTip =>
      'Bei der Wiederherstellung dieser Wallet in der Blockchain gefunden. Der Absender ist nicht gespeichert.';

  @override
  String get deskTxFoundRescanLabel => 'Bei Neuprüfung gefunden';

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
  String get deskTxBackupTip => 'Aus einer Wallet-Datendatei importiert.';

  @override
  String get deskTxFromBackup => 'Importiert';

  @override
  String get deskTxStatusImmature => 'Reift';

  @override
  String get deskTxStatusWaitingSender => 'Wartet auf Absender';

  @override
  String get deskTxStatusWaitingResponseFile => 'Wartet auf die Antwortdatei';

  @override
  String get deskTxStatusWaitingRecipient => 'Wartet auf Empfänger';

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
      'Aus einer Wallet-Datendatei importiert. Status nicht auf der Chain geprüft.';

  @override
  String deskTxNowImmature(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Reift. Verfügbar nach $countString Bestätigungen. Eine Belohnung kann verloren gehen, wenn ihr Block vorher ersetzt wird.',
      one:
          'Reift. Verfügbar nach $countString Bestätigung. Eine Belohnung kann verloren gehen, wenn ihr Block vorher ersetzt wird.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowWaitingSender =>
      'Wartet darauf, dass der Absender sie an das Netzwerk sendet.';

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
    final intl.NumberFormat confirmationsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String confirmationsString = confirmationsNumberFormat.format(
      confirmations,
    );

    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: 'Bestätigt, $confirmationsString Bestätigungen.',
      one: 'Bestätigt, $confirmationsString Bestätigung.',
    );
    return '$_temp0';
  }

  @override
  String get deskTxNowCancelled => 'Storniert';

  @override
  String get deskTxNotCancelled => 'Nicht storniert';

  @override
  String get deskTxCancelled => 'Transaktion storniert';

  @override
  String get deskTxCancelling => 'Wird storniert';

  @override
  String get deskTxHeadRestored => 'wiederhergestellt';

  @override
  String get deskTxHeadFoundOnChain => 'In der Blockchain gefunden';

  @override
  String get deskTxHeadBackup => 'aus einer Wallet-Datendatei importiert';

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
  String get deskTxSignedByRecipient => 'Empfänger hat signiert';

  @override
  String get deskTxTechTitle => 'Technische Details';

  @override
  String get deskTxStepMined => 'In einem Block gemint';

  @override
  String get deskTxStepSpendable => 'Abgeschlossen';

  @override
  String deskTxStepBlocksToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Bestätigungen',
      one: 'noch $count Bestätigung',
    );
    return '$_temp0';
  }

  @override
  String get deskTxStepReceivedSlate => 'Zahlung eingegangen';

  @override
  String get deskTxStepCreated => 'Zahlung gestartet';

  @override
  String get deskTxStepSignedReturned => 'Signiert und zurückgeschickt';

  @override
  String get deskTxStepWaitingFile => 'Wartet auf die Antwortdatei';

  @override
  String get deskTxStepWaitingRecipient => 'Wartet auf Empfänger';

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
  String deskTxCancelOutgoingBody(String amount, String who) {
    return '$amount EPIC an $who. Noch wurde nichts bezahlt: Stornieren ist kostenlos und sicher.';
  }

  @override
  String get deskTxCancelKeep => 'Behalten';

  @override
  String get deskTxCancelIncomingAction => 'Zahlung stornieren';

  @override
  String get deskTxCancelOutgoingAction => 'Zahlung stornieren';

  @override
  String get deskOnbWelcomeAdd => 'Wallet hinzufügen';

  @override
  String get deskOnbWelcomeTagline =>
      'Schlüssel und Coins bleiben auf diesem Computer, mit einem Passwort gesperrt.';

  @override
  String get deskOnbWelcomeCreate => 'Neue Wallet erstellen';

  @override
  String get deskOnbWelcomeImport => 'Wallets importieren';

  @override
  String get deskOnbWelcomeImportSub =>
      'Aus einer älteren Epic Wallet oder einem Ordner';

  @override
  String get deskOnbWelcomeCreateSub =>
      'Mit einer neuen Wiederherstellungsphrase';

  @override
  String get deskOnbWelcomeRestoreSub => 'Auch aus Stack Wallet oder Epic Pay';

  @override
  String get deskOnbWelcomeRestore => 'Mit Phrase wiederherstellen';

  @override
  String get deskOnbWelcomeTestNote =>
      'Neue Wallets werden in diesem Testnetzwerk erstellt.';

  @override
  String get deskOnbWelcomeBack => 'Zurück zum Entsperren';

  @override
  String get deskOnbWelcomeAdvanced => 'Erweitert';

  @override
  String get deskOnbWelcomeNetwork => 'Netzwerk';

  @override
  String get deskOnbWelcomeFolder => 'Datenordner der App';

  @override
  String get deskOnbWelcomeHideDetails => 'Details ausblenden';

  @override
  String get deskOnbWelcomeMoreAbout => 'Mehr dazu';

  @override
  String get deskOnbWelcomeFolderWhere =>
      'Hier speichert die App Wallets und Einstellungen.';

  @override
  String get deskOnbWelcomeFolderDetail =>
      'Mit dem lokalen Node liegt auch die Blockchain hier. Ein neuer Ordner muss leer sein: Die App legt dort ihre Ordner an und nutzt ihn weiter.';

  @override
  String deskOnbWelcomeUsing(String folder) {
    return '$folder wird genutzt. Die App startet dafür neu.';
  }

  @override
  String get deskOnbWelcomeLocked =>
      'Er lässt sich nur ändern, bevor die erste Wallet hinzugefügt wird.';

  @override
  String get deskOnbWelcomeChooseFolder => 'Ordner wählen';

  @override
  String get deskOnbWelcomeDefaultFolder => 'Standardordner';

  @override
  String get deskOnbWelcomeFolderNotEmpty =>
      'Dieser Ordner ist nicht leer. Wählen Sie einen neuen, leeren Ordner.';

  @override
  String get deskOnbWelcomeFolderIsWallet =>
      'Das ist ein Wallet-Ordner. Wählen Sie einen neuen, leeren Ordner.';

  @override
  String get deskOnbWelcomeChoose => 'Wählen';

  @override
  String get deskOnbStepPassword => 'Passwort';

  @override
  String get deskOnbStepPhrase => 'Wiederherstellungsphrase';

  @override
  String get deskOnbCreateStageCreate =>
      'Wiederherstellungsphrase wird erstellt';

  @override
  String get deskOnbCreateStageSave => 'Wallet wird gespeichert';

  @override
  String get deskOnbCreateNotCreated => 'Wallet nicht erstellt';

  @override
  String get deskOnbCreateCreating => 'Wallet wird erstellt';

  @override
  String deskOnbCreateTestLead(String network) {
    return 'Eine Wallet im $network.';
  }

  @override
  String get deskOnbCreateDiskFull =>
      'Wallet nicht gespeichert: Der Datenträger ist voll. Geben Sie Speicherplatz frei und versuchen Sie es erneut.';

  @override
  String get deskOnbCreateWait => 'Lassen Sie die App geöffnet.';

  @override
  String get deskOnbCreateLocking => 'Die geöffnete Wallet wird gesperrt';

  @override
  String get deskOnbCreateSide => 'Neue Wallet';

  @override
  String get deskOnbCreateTitle => 'Wallet erstellen';

  @override
  String get deskOnbCreateLead =>
      'Das Passwort entsperrt diese Wallet auf diesem Computer; nur die Wiederherstellungsphrase stellt die Coins wieder her.';

  @override
  String get deskOnbCreateTestNote =>
      'Eine Wallet in einem Testnetzwerk, nicht für echte EPIC';

  @override
  String get deskOnbCreatePhraseLead =>
      'Schreiben Sie diese Wörter der Reihe nach auf Papier. Nur mit ihnen lässt sich diese Wallet wiederherstellen.';

  @override
  String get deskOnbCreateRevealFirst => 'Zuerst die Phrase aufdecken';

  @override
  String get deskOnbCreateWarn =>
      'Wer diese Wörter hat, kann die Coins nehmen.';

  @override
  String get deskOnbCreateReveal => 'Phrase aufdecken';

  @override
  String get deskOnbCreateCheckScreen =>
      'Achten Sie darauf, dass niemand den Bildschirm sieht.';

  @override
  String get deskOnbCreateHide => 'Verbergen';

  @override
  String get deskOnbCreateShowQr => 'QR zeigen';

  @override
  String get deskOnbCreateHideQr => 'QR-Code ausblenden';

  @override
  String get deskOnbCreateQrWarn =>
      'Wer diesen Code scannt, kann die Coins nehmen';

  @override
  String get deskOnbCreateQrWarnText =>
      'Scannen Sie ihn nur in eine andere Wallet, der Sie vertrauen.';

  @override
  String get deskOnbCreateQrLabel => 'Wiederherstellungsphrase als QR-Code';

  @override
  String deskOnbCreateWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '$count Wort',
    );
    return 'Ich habe alle $_temp0 aufgeschrieben';
  }

  @override
  String get deskOnbRestoreDone => 'Wallet wiederhergestellt.';

  @override
  String get deskOnbRestoreNotRestored => 'Wallet nicht wiederhergestellt';

  @override
  String get deskOnbRestoreRestoring => 'Wallet wird wiederhergestellt';

  @override
  String deskOnbRestorePermission(String folder) {
    return 'Wallet-Dateien nicht geschrieben: keine Berechtigung für $folder. Erlauben Sie das Schreiben in diesen Ordner und versuchen Sie es erneut.';
  }

  @override
  String get deskOnbRestoreWait =>
      'Lassen Sie die App geöffnet. Das Guthaben erscheint nach dem ersten Scan.';

  @override
  String get deskOnbRestoreSide => 'Wallet wiederherstellen';

  @override
  String get deskOnbRestorePasswordLead =>
      'Legen Sie das Passwort fest, das diese Wallet auf diesem Computer entsperrt.';

  @override
  String get deskOnbRestoreNothingToPaste =>
      'Nichts einzufügen: Die Zwischenablage enthält keine Wörter.';

  @override
  String deskOnbRestoreBadWord(int position, String word) {
    return 'Wort $position, „$word“, steht nicht in der Wortliste.';
  }

  @override
  String deskOnbRestoreAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Wörter sind gültig.',
      one: '$count Wort ist gültig.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreChecksumFirm =>
      'Die Prüfsumme dieser Phrase stimmt nicht. Vergleichen Sie jedes Wort mit dem Papier.';

  @override
  String deskOnbRestoreChecksumSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bisher $count Wörter; die Prüfsumme stimmt nicht. Tippen Sie weiter oder vergleichen Sie jedes Wort mit dem Papier.',
      one:
          'Bisher $count Wort; die Prüfsumme stimmt nicht. Tippen Sie weiter oder vergleichen Sie jedes Wort mit dem Papier.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbRestoreWordsLead =>
      'Tippen Sie die Wörter der Reihe nach ein oder fügen Sie die ganze Phrase in ein beliebiges Feld ein.';

  @override
  String get deskOnbRestoreClear => 'Leeren';

  @override
  String get deskOnbRestoreWords => 'Wörter';

  @override
  String deskOnbRestoreFilledOf(int filled, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total Wörtern',
      one: '$total Wort',
    );
    return '$filled von $_temp0';
  }

  @override
  String get deskOnbSameTitle => 'Diese Wallet ist schon vorhanden';

  @override
  String get deskOnbSameBody =>
      'Die Phrase gehört zu einer Wallet in der Liste. Es wurde nichts hinzugefügt.';

  @override
  String get deskOnbSameWallet => 'Wallet';

  @override
  String get deskOnbSameNote =>
      'Öffnen Sie sie mit ihrem Passwort oder legen Sie mit dieser Phrase ein neues Passwort fest.';

  @override
  String get deskOnbSameOpen => 'Öffnen';

  @override
  String get deskOnbUnlockWhoWindows =>
      'Jeder, der diesen Computer als Sie nutzt, kann diese Wallet öffnen.';

  @override
  String get deskOnbUnlockWho =>
      'Jeder, der diesen Computer als Sie nutzt, kann diese Wallet öffnen.';

  @override
  String get deskOnbUnlockWrong =>
      'Falsches Passwort. Prüfen Sie die Feststelltaste und das Tastaturlayout.';

  @override
  String deskOnbUnlockPortInUse(String port) {
    return 'Port $port wird von einem anderen Programm genutzt. Schließen Sie es und versuchen Sie es erneut.';
  }

  @override
  String get deskOnbUnlockStageCheck => 'Wallet-Dateien werden geprüft';

  @override
  String get deskOnbUnlockStageWallet => 'Wallet-Dienst wird gestartet';

  @override
  String get deskOnbUnlockStageUnlock => 'Wallet wird entsperrt';

  @override
  String get deskOnbUnlockEnter => 'Geben Sie das Passwort ein';

  @override
  String get deskOnbUnlockRememberedUnavailable =>
      'Gespeichertes Passwort nicht verfügbar. Geben Sie das Passwort ein.';

  @override
  String get deskOnbUnlockRememberedForgotten =>
      'Das gespeicherte Passwort wurde vergessen. Geben Sie das Passwort ein.';

  @override
  String get deskOnbUnlockNotRemembered => 'Nicht gespeichert';

  @override
  String get deskOnbUnlockKeyStore =>
      'Der Schlüsselspeicher dieses Computers ist nicht verfügbar.';

  @override
  String get deskOnbUnlockThisWallet => 'diese Wallet';

  @override
  String get deskOnbUnlockFailed => 'Entsperren fehlgeschlagen';

  @override
  String deskOnbUnlockUnlocking(String name) {
    return '$name wird entsperrt';
  }

  @override
  String get deskOnbUnlockNote =>
      'Danach werden Node, Guthaben und Empfang im Hintergrund fertig eingerichtet.';

  @override
  String get deskOnbUnlockTitle => 'Wallet entsperren';

  @override
  String get deskOnbUnlockRemember => 'Auf diesem Computer merken';

  @override
  String deskOnbUnlockRememberFor(String who) {
    return 'Für 30 Tage. $who';
  }

  @override
  String get deskOnbUnlockMissingTitle => 'Der Ordner dieser Wallet fehlt';

  @override
  String deskOnbUnlockMissingText(String folder) {
    return 'Er lag unter $folder. Entfernen Sie die Wallet aus der Liste oder stellen Sie sie aus der Wiederherstellungsphrase wieder her.';
  }

  @override
  String get deskOnbUnlockRemove => 'Entfernen';

  @override
  String get deskOnbUnlockTryAgain => 'Erneut versuchen';

  @override
  String get deskOnbUnlockButton => 'Entsperren';

  @override
  String get deskOnbNodeFreeUnknown => 'freier Speicher unbekannt';

  @override
  String deskOnbNodeFreeHere(String size) {
    return '$size frei';
  }

  @override
  String deskOnbNodeDiskAbout(String size) {
    return 'Derzeit etwa $size,';
  }

  @override
  String deskOnbNodeDisk(String size) {
    return 'Derzeit $size,';
  }

  @override
  String get deskOnbNodeFirewall => 'Windows fragt einmal,';

  @override
  String get deskOnbNodeFirewallText =>
      'ob es durch die Firewall darf. Erlauben Sie es für private Netzwerke.';

  @override
  String deskOnbNodeGrowing(String free) {
    return 'wächst langsam · $free';
  }

  @override
  String get deskOnbNodeFound => 'Gefunden';

  @override
  String deskOnbNodeFoundAt(String version, String address) {
    return 'Epic $version unter $address';
  }

  @override
  String deskOnbNodeHeight(String height) {
    return 'Höhe $height';
  }

  @override
  String get deskOnbNodeSynced => 'synchronisiert';

  @override
  String get deskOnbNodeNoAnswer => 'Kein Node antwortet';

  @override
  String deskOnbNodeNoAnswerAt(String address) {
    return 'unter $address. Starten Sie ihn oder prüfen Sie Adresse und Port.';
  }

  @override
  String get deskOnbNodeExisting =>
      'Einen Node nutzen, der schon auf diesem Computer läuft';

  @override
  String get deskOnbNodeExistingText =>
      'Verbindet sich mit dem Node der Epic GUI oder CLI, der hier schon läuft.';

  @override
  String get deskOnbNodeAddress => 'Adresse des Nodes auf diesem Computer';

  @override
  String get deskOnbNodeCheck => 'Prüfen';

  @override
  String get deskOnbNodeBundled => 'Lokalen Node starten';

  @override
  String get deskOnbNodeBundledText =>
      'Lädt die Blockchain nach „Speichern“ in den Ordner der Wallet.';

  @override
  String deskOnbNodeFallback(String host) {
    return '$host nutzen, bis der lokale Node synchronisiert ist';
  }

  @override
  String get deskOnbNodeDialogTitle => 'Lokaler Node';

  @override
  String get deskOnbNodeDialogBody =>
      'Was es bedeutet, den Node hier zu betreiben, und welcher Node genutzt wird.';

  @override
  String get deskOnbNodeUseThis => 'Diesen Node nutzen';

  @override
  String get deskOnbNodeStart => 'Lokalen Node starten';

  @override
  String deskOnbRestorePasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter eingefügt; eine Phrase hat 12, 15, 18, 21 oder 24.',
      one: '$count Wort eingefügt; eine Phrase hat 12, 15, 18, 21 oder 24.',
    );
    return '$_temp0';
  }

  @override
  String deskOnbWordN(int number) {
    return 'Wort $number';
  }

  @override
  String get deskOnbImportEnterOld => 'Geben Sie das alte Passwort ein';

  @override
  String deskOnbImportNewShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeichen',
      one: '$count Zeichen',
    );
    return 'Neues Passwort: mindestens $_temp0';
  }

  @override
  String get deskOnbImportNewDiffer =>
      'Die neuen Passwörter stimmen nicht überein';

  @override
  String deskOnbImportWalletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wallets',
      one: '$count Wallet',
    );
    return '$_temp0';
  }

  @override
  String deskOnbImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wallets importiert.',
      one: 'Wallet importiert.',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportFindingTitle => 'Wallets werden gesucht';

  @override
  String get deskOnbImportFindingLead =>
      'Die Ordner älterer Epic-Wallet-Versionen und des Programms epic werden durchsucht.';

  @override
  String deskOnbImportFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wallets gefunden',
      one: '$count Wallet gefunden',
    );
    return '$_temp0';
  }

  @override
  String get deskOnbImportNoneTitle => 'Keine Wallets gefunden';

  @override
  String get deskOnbImportNoneLead =>
      'Wählen Sie den Wallet-Ordner oder stellen Sie mit der Wiederherstellungsphrase wieder her.';

  @override
  String get deskOnbImportChooseTitle => 'Wallets wählen';

  @override
  String get deskOnbImportChooseLead =>
      'Markierte Wallets werden der App hinzugefügt. Der Verlauf wird per Scan neu aufgebaut.';

  @override
  String get deskOnbImportCheckTitle => 'Wallets werden geprüft';

  @override
  String get deskOnbImportCheckLead =>
      'Eine Wallet, die ein anderes Programm nutzt, wird nicht importiert.';

  @override
  String get deskOnbImportTitle => 'Importieren';

  @override
  String get deskOnbImportLead =>
      'Jede Wallet fragt einmal nach ihrem alten Passwort.';

  @override
  String get deskOnbImportDoneTitle => 'Wallets importiert';

  @override
  String get deskOnbImportDoneLead =>
      'Beim ersten Entsperren durchsucht jede Wallet die Blockchain nach ihrem Verlauf.';

  @override
  String deskOnbImportSelected(int selected, int total) {
    return '$selected von $total ausgewählt';
  }

  @override
  String get deskOnbImportChecking => 'Wird geprüft…';

  @override
  String get deskOnbImportCloseOther =>
      'Schließen Sie das andere Programm oder überspringen Sie die Wallet';

  @override
  String deskOnbImportImportedOf(int done, int total) {
    return '$done von $total importiert';
  }

  @override
  String get deskOnbImportOpen => 'Wallet öffnen';

  @override
  String get deskOnbImportStepFind => 'Suchen';

  @override
  String get deskOnbImportStepChoose => 'Wählen';

  @override
  String get deskOnbImportStepCheck => 'Prüfen';

  @override
  String get deskOnbImportBack => 'Zurück';

  @override
  String get deskOnbImportSkip => 'Überspringen';

  @override
  String get deskOnbImportOlder => 'Ältere Epic Wallet';

  @override
  String get deskOnbImportOlderSub => 'Wallets und Ordner';

  @override
  String get deskOnbImportEpicProgram => 'Das Programm epic';

  @override
  String get deskOnbImportSearching => 'Wird gesucht…';

  @override
  String get deskOnbImportRestore => 'Mit Phrase wiederherstellen';

  @override
  String deskOnbImportLastUsed(String date) {
    return 'Zuletzt genutzt $date';
  }

  @override
  String deskOnbImportSecondCopy(String reason) {
    return '$reason. Markieren für eine zweite Kopie.';
  }

  @override
  String deskOnbImportCannot(String name) {
    return '$name: kann nicht importiert werden';
  }

  @override
  String get deskOnbImportInApp => 'In der App';

  @override
  String get deskOnbImportSameWallet => 'Gleiche Wallet';

  @override
  String get deskOnbImportNotInUse => 'Nicht in Nutzung';

  @override
  String get deskOnbImportNotChecked => 'Nicht geprüft';

  @override
  String get deskOnbImportSkipped => 'Übersprungen';

  @override
  String get deskOnbImportInUse => 'In Nutzung';

  @override
  String get deskOnbImportInUseText =>
      'Wird von einem anderen Programm genutzt. Schließen Sie die ältere Epic Wallet oder das Programm epic und prüfen Sie dann erneut.';

  @override
  String get deskOnbImportCheckAgain => 'Erneut prüfen';

  @override
  String get deskOnbImportImported => 'Importiert';

  @override
  String get deskOnbImportImporting => 'Wird importiert…';

  @override
  String get deskOnbImportWaiting => 'Wartet';

  @override
  String get deskOnbImportOldPassword => 'Altes Passwort';

  @override
  String deskOnbImportOldHelp(String name) {
    return 'Passwort von $name in der älteren App';
  }

  @override
  String deskOnbImportOldOf(String name) {
    return 'Altes Passwort von $name';
  }

  @override
  String deskOnbImportOldShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oder mehr Zeichen.',
      one: '$count oder mehr Zeichen.',
    );
    return 'Das alte Passwort ist zu kurz. Wählen Sie ein neues mit $_temp0';
  }

  @override
  String get deskOnbImportNewPassword => 'Neues Passwort';

  @override
  String get deskOnbImportRepeat => 'Wiederholen';

  @override
  String get deskOnbImportRepeatNew => 'Neues Passwort wiederholen';

  @override
  String get deskOnbImportUnchanged =>
      'Alte Ordner sind unverändert. Die ältere App kann sie weiterhin öffnen.';

  @override
  String get deskOnbImportStopTitle => 'Import abbrechen?';

  @override
  String get deskOnbImportStopBody =>
      'Bisher importierte Wallets werden entfernt. Alte Ordner bleiben unverändert.';

  @override
  String get deskOnbImportGoBack => 'Weiter importieren';

  @override
  String get deskOnbImportStop => 'Import abbrechen';

  @override
  String get deskRailWaitingTor => 'Wartet auf Tor';

  @override
  String get deskRailOn => 'An';

  @override
  String get deskRailConnecting => 'Verbindung…';

  @override
  String get deskRailSlow => 'Langsam';

  @override
  String get deskRailNotAnswering => 'Antwortet nicht';

  @override
  String get deskRailOff => 'Aus';

  @override
  String get deskRailChecking => 'Wird geprüft';

  @override
  String get deskRailOverTor => 'Über Tor';

  @override
  String get deskRailWaitsForTor => 'Wartet, bis Tor verbunden ist.';

  @override
  String get deskRailPaymentsWait => 'Zahlungen warten auf dem Epicbox-Server.';

  @override
  String get deskRailOpenEpicbox => 'Epicbox-Empfang öffnen';

  @override
  String get deskRailStarting => 'Startet';

  @override
  String get deskRailNotReceiving => 'Kein Empfang';

  @override
  String get deskRailOnInternet => 'An · Internet';

  @override
  String get deskRailOnLocal => 'An · lokal';

  @override
  String get deskRailPortInUse => 'Port belegt';

  @override
  String get deskRailStopped => 'Gestoppt';

  @override
  String deskRailPortInternet(String port) {
    return 'Port $port · aus dem Internet';
  }

  @override
  String deskRailPortLocal(String port) {
    return 'Port $port · nur dieser Computer';
  }

  @override
  String get deskRailOpenHttp => 'Link · HTTP-Empfang öffnen';

  @override
  String get deskRailTorNotInBuild => 'Nicht in dieser Version';

  @override
  String get deskRailStartingDots => 'Startet…';

  @override
  String deskRailTorSlow(String problem) {
    return '$problem. Senden funktioniert.';
  }

  @override
  String get deskRailTorNoAddress => 'Tor-Adresse nicht veröffentlicht';

  @override
  String get deskRailOpenPrivacy => 'Datenschutz-Einstellungen öffnen';

  @override
  String get deskRailNode => 'Node';

  @override
  String get deskRailOpenNode => 'Node-Einstellungen öffnen';

  @override
  String get deskAppNodeSyncedTitle => 'Lokaler Node synchronisiert';

  @override
  String get deskAppNodeSyncedBody =>
      'Der lokale Node hat die ganze Blockchain und kann jetzt genutzt werden. Die App startet neu, um zu ihm zu wechseln.';

  @override
  String get deskAppNotNow => 'Nicht jetzt';

  @override
  String get deskAppRestartNow => 'Jetzt neu starten';

  @override
  String get deskAppFirstScanTitle => 'Erster Scan';

  @override
  String get deskAppFirstScanBody =>
      'Die Wallet durchsucht die Blockchain nach ihren Coins und bleibt dabei nutzbar.';

  @override
  String get deskAppScanOutput => 'Scan-Ausgabe';

  @override
  String get deskAppWaitingOutput => 'Warten auf die erste Ausgabe…';

  @override
  String get deskShellNavOverview => 'Übersicht';

  @override
  String get deskShellNavActivity => 'Aktivität';

  @override
  String get deskShellNavSend => 'Senden';

  @override
  String get deskShellNavReceive => 'Empfangen';

  @override
  String get deskShellNavOutputs => 'Outputs';

  @override
  String get deskShellNavContacts => 'Kontakte';

  @override
  String get deskShellNavSettings => 'Einstellungen';

  @override
  String get deskShellTitleImportTx => 'Transaktion importieren';

  @override
  String get deskShellTitleFinalizeTx => 'Transaktion abschließen';

  @override
  String get deskShellLocksAfterSend =>
      'Wird gesperrt, sobald die Zahlung gesendet ist';

  @override
  String get deskShellNotQuitTitle => 'Nicht beendet';

  @override
  String get deskShellNotQuitBody =>
      'Eine Zahlung wird gerade gesendet. Beenden Sie erneut, sobald sie fertig ist.';

  @override
  String get deskShellLockedTitle => 'Wallet gesperrt';

  @override
  String get deskShellLockedBody =>
      'Beenden schließt die App, sobald der Wallet-Kern verbunden ist.';

  @override
  String deskShellLockWallet(String keys) {
    return 'Wallet sperren ($keys)';
  }

  @override
  String get deskShellMainNav => 'Hauptnavigation';

  @override
  String deskShellOpenWalletSettingsNamed(String name) {
    return 'Wallet-Einstellungen öffnen: $name';
  }

  @override
  String get deskShellSwitchWallet => 'Wallet wechseln';

  @override
  String get deskTourOverviewTitle => 'Übersicht';

  @override
  String get deskTourOverviewText =>
      'Das Guthaben und was noch bestätigt wird, darunter die letzten Zahlungen. Alles andere finden Sie in der Seitenleiste.';

  @override
  String get deskTourSendTitle => 'Senden';

  @override
  String get deskTourSendText =>
      'An eine Epicbox-Adresse zahlen oder eine Transaktionsdatei erstellen, die jemand signiert. Vor dem Abschicken kommt eine Prüfung.';

  @override
  String get deskTourReceiveTitle => 'Empfangen';

  @override
  String get deskTourReceiveText =>
      'Die Epicbox-Adresse dieser Wallet: Teilen Sie sie, um bezahlt zu werden. Darunter stehen Transaktionsdateien zum Signieren oder Abschließen.';

  @override
  String get deskTourInvoicesTitle => 'Rechnungen';

  @override
  String get deskTourInvoicesText =>
      'Bezahlen Sie eine Rechnung, die Ihnen jemand geschickt hat, oder stellen Sie jemandem eine aus, der Ihnen etwas schuldet. Die Tabs wechseln zwischen beidem.';

  @override
  String get deskTourActivityTitle => 'Aktivität';

  @override
  String get deskTourActivityText =>
      'Jede Transaktion mit Stand und Details. Eine Zahl an diesem Eintrag der Seitenleiste heißt: Etwas wartet auf Sie.';

  @override
  String get deskTourContactsTitle => 'Kontakte';

  @override
  String get deskTourContactsText =>
      'Gespeicherte Adressen mit Namen. Senden wählt von hier.';

  @override
  String get deskTourNodeTitle => 'Einstellungen › Node';

  @override
  String get deskTourNodeText =>
      'Von welchem Node die Wallet die Blockchain liest. Die übrigen Einstellungsseiten stehen links.';

  @override
  String get deskTourHelpTitle => 'Hilfe';

  @override
  String get deskTourHelpText =>
      'Hilfethemen, Problem melden und Tour erneut zeigen.';

  @override
  String deskTourCounter(int current, int total) {
    return '$current von $total';
  }

  @override
  String get deskTourSemantics => 'Tour durch die Wallet';

  @override
  String get deskTourSkip => 'Tour überspringen';

  @override
  String get deskTourBack => 'Zurück';

  @override
  String get deskTourNext => 'Weiter';

  @override
  String get deskKitUnknown => 'Unbekannt';

  @override
  String get deskKitRingCancelled => 'Storniert';

  @override
  String get deskKitRingConfirmed => 'Bestätigt';

  @override
  String deskKitRingProgress(int confirmations, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      confirmations,
      locale: localeName,
      other: '$confirmations von $needed Bestätigungen',
      one: '$confirmations von $needed Bestätigung',
    );
    return '$_temp0';
  }

  @override
  String get deskKitHiddenAmount => 'Betrag verborgen';

  @override
  String get deskKitChooseFile => 'Datei wählen';

  @override
  String deskKitNeedAction(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warten auf Sie',
      one: '$count wartet auf Sie',
    );
    return '$label, $_temp0';
  }

  @override
  String get deskKitCloseEsc => 'Schließen (Esc)';

  @override
  String get deskKitOptional => 'Optional';

  @override
  String get deskKitBackAlt => 'Zurück (Alt+Links)';

  @override
  String deskKitStepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get deskKitHeroCaptionEpicbox => 'EPICBOX-SERVER HÄLT SIE';

  @override
  String get deskKitHeroCaptionHttp => 'DIREKT ZUR WALLET';

  @override
  String get deskKitHeroCaptionTor => 'DIREKT, ÜBER TOR';

  @override
  String get deskKitHeroCaptionFile => 'DATEI HIN, ANTWORT ZURÜCK';

  @override
  String get deskKitHeroLabelEpicbox =>
      'Epicbox: Die Zahlung geht an den Epicbox-Server, der sie hält, bis die Wallet des Empfängers wieder da ist';

  @override
  String get deskKitHeroLabelHttp =>
      'Link · HTTP: Die Zahlung geht direkt an die Wallet der Gegenseite, die geöffnet sein muss';

  @override
  String get deskKitHeroLabelTor =>
      'Link · Tor: Die Zahlung geht direkt an die Wallet der Gegenseite, über das Tor-Netzwerk';

  @override
  String get deskKitHeroLabelFile =>
      'Direkt · Dateiübertragung: Eine Transaktionsdatei wird übergeben, eine Antwortdatei kommt zurück, dann schließt der Absender ab';

  @override
  String get deskKitReachCheck => 'Prüfen';

  @override
  String get deskKitReachChecking => 'Wird aus dem Internet geprüft…';

  @override
  String get deskKitReachNoIpTitle => 'Öffentliche IP nicht gefunden';

  @override
  String get deskKitReachNoIpText =>
      'Das Internet konnte nicht danach gefragt werden. Versuchen Sie es später erneut.';

  @override
  String deskKitReachNoIpTextLan(String address) {
    return 'Das Internet konnte nicht danach gefragt werden. Versuchen Sie es später erneut. In Ihrem Netzwerk: $address.';
  }

  @override
  String get deskKitReachClosedTitle => 'Aus dem Internet nicht erreichbar';

  @override
  String deskKitReachClosedText(String port) {
    return 'Leiten Sie am Router den TCP-Port $port an diesen Computer weiter und prüfen Sie dann erneut.';
  }

  @override
  String deskKitReachClosedTextLan(String port, String address) {
    return 'Leiten Sie am Router den TCP-Port $port an diesen Computer ($address) weiter und prüfen Sie dann erneut.';
  }

  @override
  String get deskKitReachUnknownTitle => 'Erreichbarkeit unbekannt';

  @override
  String get deskKitReachUnknownText =>
      'Die Portprüfung hat nicht geantwortet. Versuchen Sie es später erneut.';

  @override
  String deskKitReachUnknownTextLan(String address) {
    return 'Die Portprüfung hat nicht geantwortet. Versuchen Sie es später erneut. In Ihrem Netzwerk: $address.';
  }

  @override
  String get deskKitReachOpenTitle => 'Aus dem Internet erreichbar';

  @override
  String deskKitReachOpenText(String port) {
    return 'Port $port ist weitergeleitet.';
  }

  @override
  String deskKitReachOpenTextLan(String port, String address) {
    return 'Port $port ist weitergeleitet. In Ihrem Netzwerk: $address.';
  }

  @override
  String deskKitAgeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count s',
      one: 'vor $count s',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Min.',
      one: 'vor $count Min.',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count h',
      one: 'vor $count h',
    );
    return '$_temp0';
  }

  @override
  String deskKitAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor $count Tag',
    );
    return '$_temp0';
  }

  @override
  String get deskKitNodeBefore410 => 'Node vor 4.1.0';

  @override
  String get deskKitNodeNoAnswer => 'keine Antwort';

  @override
  String get deskKitNodesDisagree => 'Nodes uneinig über den letzten Block';

  @override
  String deskKitNodesAgree(String height) {
    return 'Nodes einig bei $height';
  }

  @override
  String deskKitNodesUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up von $total Nodes erreichbar',
      one: '$up von $total Node erreichbar',
    );
    return '$_temp0';
  }

  @override
  String deskKitEpicboxUp(int up, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      up,
      locale: localeName,
      other: '$up von $total Epicbox-Servern erreichbar',
      one: '$up von $total Epicbox-Server erreichbar',
    );
    return '$_temp0';
  }

  @override
  String deskKitLastBlock(String age) {
    return 'letzter Block $age';
  }

  @override
  String deskKitLimitedNetwork(String site) {
    return '$site ist nicht erreichbar; die Angaben stammen nur vom Node.';
  }

  @override
  String get deskKitFactHeight => 'Höhe';

  @override
  String get deskKitFactVersion => 'Version';

  @override
  String get deskKitFactAccepts => 'Nimmt Transaktionen an';

  @override
  String get deskKitFactYes => 'Ja';

  @override
  String get deskKitFactNotYet => 'Noch nicht';

  @override
  String get deskKitFactUnknown => 'Unbekannt';

  @override
  String get deskKitFactLatency => 'Latenz';

  @override
  String get deskKitFactUptime => 'Verfügbarkeit';

  @override
  String get deskKitFactPeers => 'Peers';

  @override
  String get deskKitFactOperator => 'Betreiber';

  @override
  String get deskKitAtTip => 'synchronisiert';

  @override
  String deskKitBehind(int count, String blocks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$blocks zurück',
      one: '$blocks zurück',
    );
    return '$_temp0';
  }

  @override
  String deskKitVersionOut(String version) {
    return '$version ist erschienen';
  }

  @override
  String get deskKitVersionLatest => 'aktuell';

  @override
  String get deskKitUptimeWindow => 'letzte 24 h';

  @override
  String deskKitAtTime(String time) {
    return 'um $time';
  }

  @override
  String get deskKitListedOfficial => 'als offiziell gelistet';

  @override
  String deskKitSourceChecked(String time, String site) {
    return '$site, geprüft $time';
  }

  @override
  String deskKitLatencyMeasured(String where) {
    return 'Latenz gemessen $where';
  }

  @override
  String deskKitSiteLastReached(String time) {
    return 'Status-Website zuletzt erreicht $time';
  }

  @override
  String deskKitSince(String time) {
    return 'seit $time';
  }

  @override
  String deskKitNodeSemantics(String status, String host) {
    return 'Node $status: $host';
  }

  @override
  String get deskKitNodeDownTitle => 'Node antwortet nicht.';

  @override
  String get deskKitNodeDownHead => 'Node antwortet nicht';

  @override
  String deskKitNodeDownText(String host) {
    return 'Zu $host wechseln, dem besten anderen Node?';
  }

  @override
  String get deskKitSwitch => 'Wechseln';

  @override
  String get deskKitLimitedInfo => 'Wenige Angaben';

  @override
  String deskKitFromStatusSite(String site) {
    return 'von $site';
  }

  @override
  String get deskKitOverTor => 'über Tor';

  @override
  String get deskKitFromThisComputer => 'von diesem Computer';

  @override
  String deskKitNodeUse(String host) {
    return '$host nutzen';
  }

  @override
  String deskKitNodeUseOperator(String host, String operator) {
    return '$host nutzen, $operator';
  }

  @override
  String deskKitNodeUseDown(String host) {
    return '$host nutzen, antwortet nicht';
  }

  @override
  String deskKitNodeUseOperatorDown(String host, String operator) {
    return '$host nutzen, $operator, antwortet nicht';
  }

  @override
  String deskKitLocalNodeUse(String state) {
    return 'Lokalen Node nutzen, $state';
  }

  @override
  String get deskKitMethodWaitingTor => 'Wartet auf Tor';

  @override
  String get deskKitMethodOn => 'An';

  @override
  String deskKitMethodOverTor(String host) {
    return '$host, über Tor';
  }

  @override
  String get deskKitMethodOff => 'Aus';

  @override
  String get deskKitMethodEpicboxOffDetail =>
      'Zahlungen an diese Adresse warten auf dem Epicbox-Server.';

  @override
  String get deskKitMethodConnecting => 'Verbindung…';

  @override
  String get deskKitMethodSlow => 'Langsam';

  @override
  String get deskKitMethodNotAnswering => 'Antwortet nicht';

  @override
  String deskKitMethodEpicboxDown(String host) {
    return '$host. Zahlungen warten auf dem Epicbox-Server.';
  }

  @override
  String get deskKitMethodHttpOffDetail =>
      'Direkt von einer anderen Wallet, solange diese geöffnet ist.';

  @override
  String get deskKitMethodStarting => 'Startet…';

  @override
  String deskKitMethodHttpInternet(String port) {
    return 'aus dem Internet, Port $port';
  }

  @override
  String get deskKitMethodHttpLocal => 'nur dieser Computer (127.0.0.1)';

  @override
  String get deskKitMethodNotReceiving => 'Kein Empfang';

  @override
  String deskKitMethodPortInUse(String port) {
    return 'Port $port wird von einem anderen Programm genutzt. Schließen Sie es oder ändern Sie unten den Port.';
  }

  @override
  String get deskKitMethodNotInBuild => 'Nicht in dieser Version';

  @override
  String get deskKitMethodTorOffDetail =>
      'Langsamer und privater. In manchen Ländern blockiert oder nicht erlaubt.';

  @override
  String get deskKitMethodTorPublishing => 'Tor-Adresse wird veröffentlicht…';

  @override
  String get deskKitMethodTorConnecting => 'Verbindung mit Tor…';

  @override
  String get deskKitMethodTorOnDetail => 'unter der Tor-Adresse erreichbar';

  @override
  String get deskKitMethodTorNotPublished => 'Nicht veröffentlicht';

  @override
  String deskKitMethodTorSendsWork(String reason) {
    return '$reason. Senden funktioniert.';
  }

  @override
  String get deskKitMethodTorNotReachableYet =>
      'Die Tor-Adresse ist noch nicht erreichbar';

  @override
  String get deskKitMethodTorStopped => 'Gestoppt';

  @override
  String get deskKitMethodTorStoppedDetail => 'Tor wurde beendet.';

  @override
  String get deskKitMethodFiles => 'Direkt · Dateiübertragung';

  @override
  String get deskKitChipOverTor => 'Über Tor';

  @override
  String get deskKitChipStarting => 'Tor startet';

  @override
  String get deskKitChipNotConnected => 'Tor nicht verbunden';

  @override
  String get deskKitChipNotOverTor => 'Ohne Tor';

  @override
  String get deskKitPasswordNote =>
      'Auf diesem Gerät geschätzt, aus der Länge und aus gängigen Wörtern, Namen und Mustern, für einen Angreifer mit schneller Hardware, der 100.000 Versuche pro Sekunde gegen die Datei dieser Wallet probiert. Ein Richtwert, keine Garantie.';

  @override
  String get deskKitPasswordNoteLabel => 'So wird die Zeit geschätzt';

  @override
  String get deskKitNotCopied => 'Nicht kopiert';

  @override
  String get deskKitCopied => 'Kopiert';

  @override
  String deskKitQrOf(String title) {
    return 'QR-Code: $title';
  }

  @override
  String deskKitQrOfTag(String title, String tag) {
    return 'QR-Code: $title, $tag';
  }

  @override
  String deskKitQrShowOf(String title) {
    return 'QR-Code anzeigen: $title';
  }

  @override
  String get deskKitQrShow => 'QR zeigen';

  @override
  String get deskKitQrHide => 'QR ausblenden';

  @override
  String get deskKitQrHideCode => 'QR ausblenden';

  @override
  String get deskSetAcctNotForgotten => 'Nicht vergessen';

  @override
  String get deskSetAcctForgotten => 'Auf diesem Computer vergessen';

  @override
  String get deskSetAcctForgottenText =>
      'Beim nächsten Start wird das Passwort abgefragt.';

  @override
  String get deskSetAcctLabelNotSaved => 'Name nicht gespeichert';

  @override
  String get deskSetAcctEnterLabel => 'Geben Sie einen Namen ein';

  @override
  String get deskSetAcctLabelSaved => 'Name gespeichert';

  @override
  String get deskSetAcctLabel => 'Name';

  @override
  String get deskSetAcctLabelHint => 'Wird nur in dieser App angezeigt.';

  @override
  String get deskSetAcctSaveLabel => 'Name speichern';

  @override
  String get deskSetAcctWalletFolder => 'Wallet-Ordner';

  @override
  String get deskSetAcctAppFiles => 'App-Dateien';

  @override
  String get deskSetAcctAppFilesHint => 'Einstellungen und das Protokoll.';

  @override
  String get deskSetAcctNetwork => 'Netzwerk';

  @override
  String get deskSetAcctNetworkHint => 'Beim Erstellen der Wallet festgelegt.';

  @override
  String get deskSetAcctRunSetup => 'Einrichtung starten…';

  @override
  String get deskSetAcctSecurity => 'Sicherheit';

  @override
  String get deskSetAcctRemembered => 'Auf diesem Computer gemerkt';

  @override
  String deskSetAcctRememberedHint(String who) {
    return 'Öffnet beim Start ohne Passwort, 30 Tage ab dem Einrichten. Zahlungen fragen das Passwort weiterhin ab. $who';
  }

  @override
  String get deskSetAcctForget => 'Diesen Computer vergessen';

  @override
  String get deskSetAcctPasswordHint => 'Entsperrt diese Wallet.';

  @override
  String get deskSetAcctChangePassword => 'Passwort ändern…';

  @override
  String get deskSetAcctDeleteHint =>
      'Löscht ihre Schlüssel und ihre Datenbank.';

  @override
  String get deskSetAcctFolderNotFound => 'Ordner nicht gefunden';

  @override
  String deskSetAcctCopyPath(String title) {
    return 'Pfad kopieren: $title';
  }

  @override
  String deskSetBackupWhenToday(String time) {
    return 'heute, $time';
  }

  @override
  String deskSetBackupWhenYesterday(String time) {
    return 'gestern, $time';
  }

  @override
  String deskSetBackupWhenDate(String day, String time) {
    return '$day, $time';
  }

  @override
  String get deskSetBackupNeverExported => 'Noch nie exportiert.';

  @override
  String deskSetBackupLastExportNothingNew(String when) {
    return 'Letzter Export $when · seitdem nichts Neues.';
  }

  @override
  String deskSetBackupLastExportSince(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seitdem $count Zahlungen',
      one: 'seitdem 1 Zahlung',
    );
    return 'Letzter Export $when · $_temp0.';
  }

  @override
  String deskSetBackupWriteFailedHere(String reason) {
    return 'In den Ordner konnte nicht geschrieben werden: $reason. Wählen Sie einen anderen Ordner.';
  }

  @override
  String deskSetBackupWriteFailedIn(String folder, String reason) {
    return 'In $folder konnte nicht geschrieben werden: $reason. Wählen Sie einen anderen Ordner.';
  }

  @override
  String get deskSetBackupWriteFailed =>
      'Die Datei konnte nicht geschrieben werden. Wählen Sie einen anderen Ordner.';

  @override
  String get deskSetBackupExportTitle => 'Wallet-Daten exportieren';

  @override
  String get deskSetBackupExportHint =>
      'Zahlungsverlauf, Kontakte, Rechnungen und Einstellungen, in einer Datei, die nur eine Wallet mit dieser Wiederherstellungsphrase öffnet. Die Phrase allein bringt das Guthaben zurück, nicht diese.';

  @override
  String get deskSetBackupExporting => 'Wird exportiert…';

  @override
  String get deskSetBackupExportButton => 'Exportieren…';

  @override
  String get deskSetBackupImportTitle => 'Wallet-Daten importieren';

  @override
  String get deskSetBackupImportHint =>
      'Bringt Zahlungsverlauf, Kontakte, Rechnungen und Einstellungen dieser Wallet aus einer Wallet-Datendatei zurück. Nichts wird entfernt; dieselbe Datei zweimal ändert nichts.';

  @override
  String get deskSetBackupImportButton => 'Importieren…';

  @override
  String get deskSetBackupCsvHint =>
      'Eine einfache Tabelle für Tabellenkalkulationen. Nicht verschlüsselt, nicht importierbar.';

  @override
  String get deskSetBackupSaveDialogTitle => 'Wallet-Daten speichern';

  @override
  String get deskSetBackupNotSaved => 'Nicht gespeichert';

  @override
  String get deskSetBackupInFile => 'In der Datei';

  @override
  String deskSetBackupInFileCounts(int payments, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments Zahlungen',
      one: '1 Zahlung',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts Kontakte',
      one: '1 Kontakt',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get deskSetBackupInFileSub =>
      'Wer was gezahlt hat, Gebühren, Notizen und Bezeichnungen; Rechnungen; Einstellungen';

  @override
  String get deskSetBackupNotIn => 'Nicht enthalten';

  @override
  String get deskSetBackupNotInValue =>
      'Wiederherstellungsphrase, Schlüssel, Passwort';

  @override
  String get deskSetBackupOpensWith => 'Öffnen mit';

  @override
  String get deskSetBackupOpensWithValue =>
      'Diese Wallet oder eine aus derselben Phrase wiederhergestellte';

  @override
  String get deskSetBackupFile => 'Datei';

  @override
  String get deskSetBackupFileNote => 'Die Datei enthält alles bis jetzt.';

  @override
  String get deskSetBackupExportDesc =>
      'Eine Datei mit Zahlungsverlauf, Kontakten, Rechnungen und Einstellungen dieser Wallet.';

  @override
  String get deskSetBackupSaved => 'Gespeichert';

  @override
  String get deskSetBackupKeepCopy =>
      'Bewahren Sie eine Kopie außerhalb dieses Computers auf: auf einem USB-Stick, einem anderen Laufwerk oder in der Cloud.';

  @override
  String get deskSetBackupOpenFolder => 'Ordner öffnen';

  @override
  String get deskSetBackupSaving => 'Wird gespeichert…';

  @override
  String get deskSetBackupTryAgain => 'Erneut versuchen';

  @override
  String get deskSetBackupSaveAs => 'Speichern unter…';

  @override
  String get deskSetBackupOpenDialogTitle => 'Wallet-Datendatei öffnen';

  @override
  String get deskSetBackupNothingNew => 'Nichts Neues';

  @override
  String deskSetBackupNothingNewBody(String file) {
    return 'Jeder Eintrag in $file war schon vorhanden.';
  }

  @override
  String get deskSetBackupImported => 'Importiert';

  @override
  String deskSetBackupReading(String file) {
    return '$file wird gelesen…';
  }

  @override
  String get deskSetBackupNotImported => 'Nicht importiert';

  @override
  String get deskSetBackupBringsBack => 'Bringt zurück';

  @override
  String get deskSetBackupBringsBackValue =>
      'Zahlungsdetails und Notizen, ältere Zahlungen, die der Liste fehlen, Kontakte, Rechnungen und Einstellungen';

  @override
  String get deskSetBackupNeeds => 'Benötigt';

  @override
  String get deskSetBackupNeedsValue =>
      'Eine Datei dieser Wallet (dieselbe Wiederherstellungsphrase). Stellen Sie die Wallet zuerst aus ihrer Phrase wieder her.';

  @override
  String get deskSetBackupChooseFile => 'Datei wählen…';

  @override
  String get deskSetBackupImportDesc =>
      'Bringt Zahlungsverlauf, Kontakte, Rechnungen und Einstellungen dieser Wallet zurück; vorhandene Einträge bleiben.';

  @override
  String get deskSetBackupSaveCsvDialogTitle => 'Zahlungen als CSV speichern';

  @override
  String get deskSetBackupCsvDialogTitle => 'CSV exportieren';

  @override
  String get deskSetBackupCsvDialogDesc =>
      'Eine einfache Tabelle der Zahlungen dieser Wallet, für Tabellenkalkulationen.';

  @override
  String deskSetBackupCsvSavedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen',
      one: '1 Zahlung',
    );
    return '$_temp0, die neueste zuerst. Beträge in EPIC mit 8 Nachkommastellen; Datumsangaben in UTC.';
  }

  @override
  String get deskSetBackupDateError => 'Geben Sie ein Datum wie 2026-01-31 ein';

  @override
  String get deskSetBackupDateHint => 'JJJJ-MM-TT';

  @override
  String get deskSetBackupRange => 'Zeitraum';

  @override
  String get deskSetBackupRangeAll => 'Alle';

  @override
  String get deskSetBackupRangeThisYear => 'Dieses Jahr';

  @override
  String get deskSetBackupRangeLastYear => 'Letztes Jahr';

  @override
  String get deskSetBackupRangeCustom => 'Eigener';

  @override
  String get deskSetBackupFrom => 'Von';

  @override
  String get deskSetBackupTo => 'Bis';

  @override
  String deskSetBackupCsvInfo(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zahlungen',
      one: '1 Zahlung',
    );
    return '$_temp0 · $file';
  }

  @override
  String deskSetBackupCsvInfoNoCount(String file) {
    return '$file';
  }

  @override
  String get deskSetBackupNotEncrypted => 'Nicht verschlüsselt.';

  @override
  String get deskSetBackupNotEncryptedBody =>
      'Jeder mit der Datei kann Beträge, Datumsangaben, Adressen und Notizen lesen.';

  @override
  String deskSetBackupReminderNever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen sind in Ihren exportierten Wallet-Daten nicht enthalten.',
      one: '1 Zahlung ist in Ihren exportierten Wallet-Daten nicht enthalten.',
    );
    return '$_temp0';
  }

  @override
  String deskSetBackupReminderChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen sind seit dem letzten Export der Wallet-Daten neu oder geändert.',
      one: '1 Zahlung ist seit dem letzten Export der Wallet-Daten neu oder geändert.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetBackupReminderBody =>
      'Eine Wiederherstellung mit der Wiederherstellungsphrase bringt das Guthaben zurück, nicht, wer was gezahlt hat.';

  @override
  String get deskSetBackupNotNow => 'Nicht jetzt';

  @override
  String get deskSetDlgChainTitle => 'Chain-Daten gefunden';

  @override
  String get deskSetDlgChainDesc =>
      'Der lokale Node kann die Epic-Chain-Daten nutzen, die bereits auf diesem Computer liegen, statt sie herunterzuladen.';

  @override
  String get deskSetDlgChainFolder => 'Ordner';

  @override
  String get deskSetDlgChainSize => 'Größe';

  @override
  String get deskSetDlgChainUpdated => 'Zuletzt geändert';

  @override
  String get deskSetDlgChainUpdatedValue => 'vor 3 Tagen';

  @override
  String get deskSetDlgChainOthers =>
      '1 weitere Kopie gefunden; diese ist die neueste.';

  @override
  String get deskSetDlgChainInUse =>
      'Ein anderes Epic-Programm nutzt diesen Ordner. Schließen Sie es und wählen Sie dann erneut den lokalen Node, um diese Daten zu nutzen.';

  @override
  String get deskSetDlgChainUseIt => 'Nutzen?';

  @override
  String get deskSetDlgChainOlderWallet =>
      'Eine ältere Epic Wallet, die diesen Ordner nutzt, synchronisiert danach neu.';

  @override
  String get deskSetDlgChainFresh => 'Neu herunterladen';

  @override
  String get deskSetDlgChainUse => 'Diese Daten nutzen';

  @override
  String get deskSetDlgPwChanged => 'Passwort geändert.';

  @override
  String get deskSetDlgPwTitle => 'Passwort ändern';

  @override
  String get deskSetDlgPwDesc =>
      'Ab jetzt entsperrt das neue Passwort diese Wallet; „Auf diesem Computer merken“ wird ausgeschaltet.';

  @override
  String get deskSetDlgPwDescPlain =>
      'Ab jetzt entsperrt das neue Passwort diese Wallet, und dieser Computer merkt es sich nicht mehr.';

  @override
  String get deskSetDlgPwCurrent => 'Aktuelles Passwort';

  @override
  String get deskSetDlgPwWrong => 'Falsches Passwort';

  @override
  String get deskSetDlgPwNew => 'Neues Passwort';

  @override
  String get deskSetDlgPwRepeat => 'Neues Passwort wiederholen';

  @override
  String deskSetDlgRemoveToastList(String name) {
    return '$name aus der Liste entfernt';
  }

  @override
  String deskSetDlgRemoveToastDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get deskSetDlgRemoveFilesKept => 'Dateien behalten.';

  @override
  String deskSetDlgRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get deskSetDlgRemoveWhat => 'Was entfernt werden soll';

  @override
  String get deskSetDlgRemoveFromList => 'Aus der Liste entfernen';

  @override
  String deskSetDlgRemoveFromListHint(String folder) {
    return 'Die Dateien bleiben in $folder; „Wallet hinzufügen“ holt sie zurück.';
  }

  @override
  String get deskSetDlgDeleteWallet => 'Wallet löschen';

  @override
  String deskSetDlgRemoveDeleteHint(String folder) {
    return 'Löscht ihre Schlüssel und ihre Datenbank aus $folder. Nur die Wiederherstellungsphrase stellt sie wieder her; ohne sie sind die Coins verloren.';
  }

  @override
  String get deskSetDlgRemoveUnlockHint =>
      'Um auch ihre Dateien zu löschen, entsperren Sie diese Wallet und nutzen Sie „Wallet löschen“ unter Einstellungen › Diese Wallet.';

  @override
  String get deskSetDlgRemoveUnlock => 'Diese Wallet entsperren';

  @override
  String get deskSetDlgRemoveIrreversible =>
      'Lässt sich nicht rückgängig machen';

  @override
  String get deskSetDlgRemoveIrreversibleBody =>
      'Nur die Wiederherstellungsphrase stellt die Wallet wieder her; ohne sie sind die Coins endgültig verloren.';

  @override
  String get deskSetDlgRemoveName => 'Name der Wallet';

  @override
  String deskSetDlgRemoveTypeName(String name) {
    return 'Geben Sie zur Bestätigung $name ein.';
  }

  @override
  String get deskSetDlgRemoveNameMismatch => 'Der Name stimmt nicht überein';

  @override
  String get deskSetDlgPassword => 'Passwort';

  @override
  String get deskSetDlgPhraseWritten =>
      'Die Wiederherstellungsphrase ist aufgeschrieben';

  @override
  String get deskSetDlgRemoving => 'Wird entfernt…';

  @override
  String get deskSetDlgWalletLocked => 'Die Wallet ist gesperrt';

  @override
  String get deskSetDlgDeleteTitle => 'Diese Wallet löschen?';

  @override
  String get deskSetDlgDeleteDesc =>
      'Löscht die Wallet und ihren Seed von diesem Computer. Nur die Wiederherstellungsphrase stellt sie wieder her; ohne sie sind die Coins verloren.';

  @override
  String get deskSetFrameTitle => 'Einstellungen';

  @override
  String get deskSetFrameSections => 'Bereiche der Einstellungen';

  @override
  String get deskSetFrameNode => 'Node';

  @override
  String get deskSetFramePrivacy => 'Datenschutz';

  @override
  String get deskSetFrameAppearance => 'Darstellung';

  @override
  String get deskSetFrameThisWallet => 'Diese Wallet';

  @override
  String get deskSetFrameAllWallets => 'Alle Wallets';

  @override
  String get deskSetFramePhrase => 'Seed-Phrase';

  @override
  String get deskSetFrameRescan => 'Guthaben neu prüfen';

  @override
  String get deskSetFrameAbout => 'Über';

  @override
  String get deskSetFrameHelp => 'Hilfe';

  @override
  String get deskSetFrameHealthOn => 'An';

  @override
  String get deskSetFrameHealthSlow => 'Langsam';

  @override
  String get deskSetFrameNotResponding => 'Antwortet nicht';

  @override
  String get deskSetFrameOff => 'Aus';

  @override
  String get deskSetFrameChecking => 'Wird geprüft…';

  @override
  String get deskSetFrameNodeSynced => 'Synchronisiert';

  @override
  String get deskSetFrameNodeSyncing => 'Synchronisierung';

  @override
  String get deskSetFrameNever => 'nie';

  @override
  String get deskSetFrameJustNow => 'gerade eben';

  @override
  String deskSetFrameMinAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Min.',
      one: 'vor $count Min.',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count h',
      one: 'vor $count h',
    );
    return '$_temp0';
  }

  @override
  String deskSetFrameDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor $count Tag',
    );
    return '$_temp0';
  }

  @override
  String get deskSetComboOpens => 'Öffnet die Liste';

  @override
  String get deskSetComboNoAnswer => 'Noch keine Antwort';

  @override
  String deskSetComboUse(String host) {
    return '$host nutzen';
  }

  @override
  String get deskSetLnodeDidNotStart => 'Der Node ist nicht gestartet';

  @override
  String get deskSetLnodeDidNotStop => 'Der Node wurde nicht gestoppt';

  @override
  String get deskSetLnodeDidNotRestart => 'Der Node wurde nicht neu gestartet';

  @override
  String get deskSetLnodeMoved => 'Chain-Daten verschoben';

  @override
  String get deskSetLnodeFolderChanged => 'Datenordner geändert';

  @override
  String get deskSetLnodeFolderFailed => 'Der Ordner wurde nicht geändert';

  @override
  String get deskSetLnodeStart => 'Starten';

  @override
  String get deskSetLnodeStop => 'Stoppen';

  @override
  String get deskSetLnodeRestart => 'Neu starten';

  @override
  String get deskSetLnodeTabStatus => 'Status';

  @override
  String get deskSetLnodeTabPeers => 'Peers';

  @override
  String get deskSetLnodeWhileSyncing => 'Während der Synchronisierung';

  @override
  String deskSetLnodeWhileSyncingText(String host) {
    return '$host nutzen, bis der lokale Node synchronisiert ist';
  }

  @override
  String get deskSetLnodeChange => 'Ändern…';

  @override
  String deskSetLnodeUseWhileSyncing(String host) {
    return '$host während der Synchronisierung nutzen';
  }

  @override
  String get deskSetLnodeDataFolder => 'Datenordner';

  @override
  String deskSetLnodeUsed(String size) {
    return '$size belegt';
  }

  @override
  String get deskSetLnodeFreeUnknown => 'freier Speicher unbekannt';

  @override
  String deskSetLnodeFree(String size) {
    return '$size frei';
  }

  @override
  String get deskSetLnodeOpen => 'Öffnen';

  @override
  String get deskSetLnodeFolderNotOpened => 'Ordner nicht geöffnet';

  @override
  String get deskSetLnodeChainData => 'Chain-Daten';

  @override
  String get deskSetLnodeChainPointed =>
      'Dieser Node liest den Ordner eines anderen Programms; löschen Sie die Daten dort.';

  @override
  String get deskSetLnodeChainText =>
      'Chain-Daten nutzen, die ein anderer Epic-Node auf diesem Computer hinterlassen hat, oder die Daten dieses Nodes löschen und die Blockchain neu herunterladen.';

  @override
  String get deskSetLnodeReuse => 'Vorhandene nutzen…';

  @override
  String get deskSetLnodeDelete => 'Löschen…';

  @override
  String get deskSetLnodeAutostart => 'Mit der App starten';

  @override
  String get deskSetLnodeAutostartHint =>
      'Startet den Node beim Start der App und hält ihn synchron, solange die App geöffnet ist.';

  @override
  String get deskSetLnodeViewLog => 'Protokoll anzeigen';

  @override
  String get deskSetLnodeChangeFolder => 'Ordner ändern…';

  @override
  String deskSetLnodeUseMeanwhile(String host) {
    return 'Solange $host nutzen';
  }

  @override
  String get deskSetLnodeWaitingPeers => 'wartet auf Peers';

  @override
  String get deskSetLnodeSyncingLower => 'Synchronisierung';

  @override
  String deskSetLnodeStageUsing(String stage, String host) {
    return '$stage · solange wird $host genutzt';
  }

  @override
  String get deskSetLnodeNothingUntilSynced =>
      'Bis der lokale Node synchronisiert ist, kann nichts gesendet oder empfangen werden.';

  @override
  String get deskSetLnodeAtTip => 'aktuell';

  @override
  String get deskSetLnodeStalledDetail =>
      'seit 5 Min. kein Fortschritt; bereits einmal neu gestartet';

  @override
  String get deskSetLnodeNoProgress => 'Der Node macht keinen Fortschritt.';

  @override
  String get deskSetLnodeNoProgressText =>
      'Den Node erneut starten oder das Node-Protokoll prüfen.';

  @override
  String deskSetLnodePortInUse(String port) {
    return 'Port $port wird von einem anderen Programm genutzt.';
  }

  @override
  String get deskSetLnodePortInUseText =>
      'Schließen Sie das andere Programm oder wählen Sie diesen Node unter „Node-Server“.';

  @override
  String get deskSetLnodeDiskLow =>
      'Weniger als 2 GB frei auf diesem Laufwerk.';

  @override
  String get deskSetLnodeDiskLowText =>
      'Geben Sie Speicher frei oder ändern Sie den Datenordner.';

  @override
  String get deskSetLnodeMissing =>
      'Das Node-Programm fehlt in dieser Installation.';

  @override
  String get deskSetLnodeMissingText => 'Installieren Sie die Wallet neu.';

  @override
  String get deskSetLnodeStopped => 'Der Node hat sich selbst beendet.';

  @override
  String get deskSetLnodeStoppedText =>
      'Die letzten Protokollzeilen nennen vielleicht den Grund.';

  @override
  String deskSetLnodeUsesMeanwhile(String host) {
    return 'solange nutzt die Wallet $host';
  }

  @override
  String get deskSetLnodeNothingUntilRuns =>
      'bis er läuft, kann nichts gesendet werden';

  @override
  String get deskSetLnodeTilePeers => 'Peers';

  @override
  String get deskSetLnodeTileSync => 'Synchronisierung';

  @override
  String get deskSetLnodeTileDownload => 'Download';

  @override
  String deskSetLnodeSoFar(String size) {
    return 'bisher $size';
  }

  @override
  String get deskSetLnodeTileDisk => 'Chain-Daten auf dem Datenträger';

  @override
  String deskSetLnodeThisSession(String size) {
    return '+$size seit Start';
  }

  @override
  String deskSetLnodeVersion(String version) {
    return 'Version $version';
  }

  @override
  String deskSetLnodeRunning(String duration) {
    return 'läuft seit $duration';
  }

  @override
  String deskSetLnodeStoppedAt(String time) {
    return 'gestoppt $time';
  }

  @override
  String deskSetLnodePeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Peers',
      one: '$count Peer',
    );
    return '$_temp0';
  }

  @override
  String deskSetLnodeMoving(String done, String total) {
    return 'Chain-Daten werden verschoben · $done von $total';
  }

  @override
  String get deskSetLnodeConnectingPeers => 'Verbindung zu Peers';

  @override
  String deskSetLnodeStartedSecAgo(int seconds) {
    return 'vor $seconds s gestartet';
  }

  @override
  String deskSetLnodeStartedAgo(String duration) {
    return 'vor $duration gestartet';
  }

  @override
  String get deskSetLnodeSettingsChanged => 'Einstellungen geändert.';

  @override
  String get deskSetLnodeSettingsChangedText =>
      'Sie gelten ab dem nächsten Neustart.';

  @override
  String get deskSetLnodeRestartNow => 'Jetzt neu starten';

  @override
  String get deskSetLnodeSampled =>
      'Alle 30 s gemessen, solange diese Seite geöffnet ist.';

  @override
  String get deskSetLnodeTomlEdited =>
      'epic-server.toml wurde von Hand bearbeitet; die Peer- und Ordnereinstellungen hier gelten nicht.';

  @override
  String get deskSetLnodeSyncProgress => 'Fortschritt der Synchronisierung';

  @override
  String get deskSetLnodeStepHeaders => 'Header';

  @override
  String get deskSetLnodeStepChainState => 'Chain-Zustand';

  @override
  String get deskSetLnodeStepBlocks => 'Blöcke';

  @override
  String get deskSetLnodeStepsNone =>
      'Synchronisierungsschritte: noch keiner begonnen';

  @override
  String deskSetLnodeStepOf(int n, String name) {
    return 'Synchronisierungsschritt $n von 4: $name';
  }

  @override
  String deskSetLndAskTitle(String host) {
    return '$host nutzen, bis der lokale Node synchronisiert ist?';
  }

  @override
  String deskSetLndAskDesc(String host) {
    return '$host, ein öffentlicher Node, kann einspringen, bis der lokale Node synchronisiert ist.';
  }

  @override
  String get deskSetLndAskNote =>
      'Wird einmal gefragt. Node und Auswahl lassen sich unter Einstellungen › Node › Während der Synchronisierung ändern.';

  @override
  String get deskSetLndAskWait => 'Auf den lokalen Node warten';

  @override
  String deskSetLndAskUse(String host) {
    return '$host nutzen';
  }

  @override
  String get deskSetLndPickTitle => 'Node während der Synchronisierung';

  @override
  String get deskSetLndPickDesc =>
      'Der öffentliche Node, den die Wallet nutzt, bis der lokale Node synchronisiert ist.';

  @override
  String get deskSetLndDeleted => 'Chain-Daten gelöscht';

  @override
  String deskSetLndFreed(String size) {
    return '$size freigegeben';
  }

  @override
  String get deskSetLndNotDeleted => 'Chain-Daten nicht gelöscht';

  @override
  String get deskSetLndDeleteTitle => 'Chain-Daten löschen';

  @override
  String deskSetLndDeleteDesc(String size, String path) {
    return 'Entfernt $size aus $path; die Blockchain wird beim nächsten Start neu heruntergeladen. Schlüssel und Verlauf bleiben.';
  }

  @override
  String deskSetLndDeleteDescNoSize(String path) {
    return 'Entfernt die Chain-Daten aus $path. Der Node stoppt, und beim nächsten Start wird die ganze Blockchain neu heruntergeladen (Stunden). Wallet-Schlüssel und Verlauf bleiben unberührt.';
  }

  @override
  String deskSetLndTypeToConfirm(String word) {
    return 'Zur Bestätigung „$word“ eingeben';
  }

  @override
  String deskSetLndTypeToConfirmLabel(String word) {
    return 'Zur Bestätigung $word eingeben';
  }

  @override
  String get deskSetLndSourceCli => 'epic (der Befehlszeilen-Node)';

  @override
  String get deskSetLndSourceGui => 'Epic GUI';

  @override
  String get deskSetLndSourceBundled => 'eine frühere Epic Wallet';

  @override
  String get deskSetLndSourceCustom => 'ein anderer Ordner';

  @override
  String get deskSetLndInUse => 'Chain-Daten werden genutzt';

  @override
  String get deskSetLndNotInUse => 'Der Ordner wird nicht genutzt';

  @override
  String get deskSetLndReuseTitle => 'Chain-Daten gefunden';

  @override
  String get deskSetLndReuseDesc =>
      'Ein anderer Epic-Node hat hier Chain-Daten hinterlassen. Der lokale Node kann diesen Ordner lesen, statt die Blockchain herunterzuladen.';

  @override
  String get deskSetLndLooking => 'Wird gesucht…';

  @override
  String deskSetLndLastWritten(String date) {
    return 'zuletzt geändert $date';
  }

  @override
  String get deskSetLndLocked => 'Von einem anderen Programm genutzt';

  @override
  String get deskSetLndNothingCopied =>
      'Es wird nichts kopiert: Der Node liest diesen Ordner, und „Chain-Daten löschen“ ist dafür abgeschaltet.';

  @override
  String get deskSetLndFresh => 'Neu herunterladen';

  @override
  String deskSetLndFreshLine(String size) {
    return 'In den eigenen Ordner der Wallet. Etwa $size.';
  }

  @override
  String get deskSetLndLogTitle => 'Node-Protokoll';

  @override
  String get deskSetLndReading => 'Wird gelesen…';

  @override
  String get deskSetLndLogNote =>
      'Die letzten 200 Zeilen von epic-server.log im Datenordner. Die neuesten unten.';

  @override
  String get deskSetLndCopied => 'Kopiert';

  @override
  String deskSetLndLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen',
      one: '$count Zeile',
    );
    return '$_temp0';
  }

  @override
  String get deskSetLndBadFolder => 'Dieser Ordner funktioniert nicht';

  @override
  String get deskSetLndChooseAnother => 'Anderen wählen';

  @override
  String deskSetLndMoveTitle(String size, String folder) {
    return '$size nach $folder verschieben?';
  }

  @override
  String get deskSetLndMoveDesc =>
      'Der Node stoppt, während die Daten verschoben werden, und startet dann aus dem neuen Ordner. „Dort neu beginnen“ lädt die Blockchain stattdessen neu in diesen Ordner.';

  @override
  String get deskSetLndStartFresh => 'Dort neu beginnen';

  @override
  String get deskSetLndMove => 'Verschieben';

  @override
  String get deskSetLndProbNotEmpty => 'Der Ordner ist nicht leer.';

  @override
  String get deskSetLndProbInsideSource => 'Er liegt im aktuellen Ordner.';

  @override
  String get deskSetLndProbSourceInside => 'Der aktuelle Ordner liegt darin.';

  @override
  String deskSetLndProbSpace(String needed, String free) {
    return 'Nicht genug Speicher: $needed nötig, $free frei.';
  }

  @override
  String deskSetLndProbSpaceUnknown(String needed) {
    return 'Nicht genug Speicher: $needed nötig, freier Speicher unbekannt.';
  }

  @override
  String get deskSetLndProbLocked => 'Ein anderes Programm hält ihn.';

  @override
  String get deskSetLndProbMissing => 'Die aktuellen Chain-Daten fehlen.';

  @override
  String get deskSetLndProbNotWritable => 'Er ist nicht beschreibbar.';

  @override
  String get deskSetLndProbIncomplete =>
      'Die aktuellen Chain-Daten sind unvollständig.';

  @override
  String get deskSetLndProbForeign =>
      'Dort liegen Chain-Daten eines anderen Programms.';

  @override
  String get deskSetPeersBannedToast => 'Peer gesperrt';

  @override
  String get deskSetPeersUnbannedToast => 'Peer entsperrt';

  @override
  String deskSetPeersNotAddress(String port) {
    return 'Keine IP-Adresse mit Port, wie 203.0.113.5:$port.';
  }

  @override
  String get deskSetPeersAlreadyPreferred => 'Bereits bevorzugt.';

  @override
  String deskSetPeersMaxRange(int min, int max) {
    return '$min bis $max.';
  }

  @override
  String get deskSetPeersReading => 'Peers werden gelesen…';

  @override
  String deskSetPeersSummary(int connected, int inbound, int outbound) {
    return '$connected verbunden · $inbound eingehend · $outbound ausgehend';
  }

  @override
  String deskSetPeersSummaryBanned(
    int connected,
    int inbound,
    int outbound,
    int banned,
  ) {
    return '$connected verbunden · $inbound eingehend · $outbound ausgehend · $banned gesperrt';
  }

  @override
  String get deskSetPeersIn => 'ein';

  @override
  String get deskSetPeersOut => 'aus';

  @override
  String get deskSetPeersBan => 'Sperren';

  @override
  String get deskSetPeersColAddress => 'Adresse';

  @override
  String get deskSetPeersColDirection => 'Richtung';

  @override
  String get deskSetPeersColVersion => 'Version';

  @override
  String get deskSetPeersColHeight => 'Höhe';

  @override
  String get deskSetPeersColFirstSeen => 'Erstmals';

  @override
  String get deskSetPeersNone => 'Keine Peers verbunden.';

  @override
  String deskSetPeersMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere',
      one: '$count weiterer',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersRefreshed(int seconds) {
    return 'Alle $seconds s aktualisiert';
  }

  @override
  String get deskSetPeersBanned => 'Gesperrt';

  @override
  String deskSetPeersBannedAt(String time) {
    return 'gesperrt $time';
  }

  @override
  String get deskSetPeersUnban => 'Entsperren';

  @override
  String get deskSetPeersPreferred => 'Bevorzugte Peers';

  @override
  String get deskSetPeersPreferredLabel =>
      'Bevorzugter Peer, IP-Adresse und Port';

  @override
  String get deskSetPeersAdd => 'Hinzufügen';

  @override
  String get deskSetPeersMaxIn => 'Max. eingehend';

  @override
  String get deskSetPeersMaxInLabel => 'Max. eingehende Peers';

  @override
  String get deskSetPeersMaxOut => 'Max. ausgehend';

  @override
  String get deskSetPeersMaxOutLabel => 'Max. ausgehende Peers';

  @override
  String deskSetPeersPreferredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bevorzugt:',
      one: '$count bevorzugt:',
    );
    return '$_temp0';
  }

  @override
  String deskSetPeersForget(String peer) {
    return '$peer vergessen';
  }

  @override
  String deskSetPeersNote(int min, int max, int def) {
    return 'Max. eingehend und ausgehend: $min bis $max (Standard $def).';
  }

  @override
  String get deskSetLndDeleteQuestion => 'Chain-Daten löschen?';

  @override
  String get deskSetLogsMemoryOnly =>
      'Das Protokoll wird nur im Arbeitsspeicher gehalten.';

  @override
  String get deskSetLogsClearTitle => 'Protokolle löschen?';

  @override
  String get deskSetLogsClearDesc =>
      'Löscht die Protokolldateien. Ein später gesendeter Bericht enthält nur, was ab jetzt protokolliert wird.';

  @override
  String get deskSetLogsKeep => 'Protokolle behalten';

  @override
  String get deskSetLogsClear => 'Protokolle löschen';

  @override
  String get deskSetLogsCleared => 'Protokolle gelöscht';

  @override
  String deskSetLogsToday(String time) {
    return 'heute $time';
  }

  @override
  String deskSetLogsTomorrow(String time) {
    return 'morgen $time';
  }

  @override
  String get deskSetLogsTitle => 'Protokolle';

  @override
  String get deskSetLogsLevel => 'Protokollstufe';

  @override
  String get deskSetLogsLevelNormal =>
      'Normal. „Ausführlich“ speichert 24 Stunden lang mehr Zeilen; Adressen können in der Datei stehen, Berichte lassen sie weg.';

  @override
  String deskSetLogsLevelDetailed(String until) {
    return 'Ausführlich bis $until, dann Normal. Adressen können in der Datei stehen; Berichte lassen sie weg.';
  }

  @override
  String deskSetLogsLevelDetailedCore(String until) {
    return 'Ausführlich bis $until, dann Normal. Adressen können in der Datei stehen; Berichte lassen sie weg. Zeilen des Wallet-Kerns werden ab dem nächsten App-Start ausführlich.';
  }

  @override
  String get deskSetLogsNormal => 'Normal';

  @override
  String get deskSetLogsDetailed => 'Ausführlich';

  @override
  String get deskSetLogsFiles => 'Protokolldateien';

  @override
  String deskSetLogsSize(String size, String max) {
    return 'Aktuelle Größe $size von $max. Eine ältere Datei wird behalten.';
  }

  @override
  String get deskSetLogsOpenFolder => 'Protokollordner öffnen';

  @override
  String deskSetNodePortNote(String port) {
    return 'Prüfen Sie Adresse und Port (meist $port).';
  }

  @override
  String deskSetNodeListNote(String site) {
    return 'Status von $site; Latenz von diesem Computer aus gemessen.';
  }

  @override
  String get deskSetNodeRowNotSetUp => 'Nicht eingerichtet';

  @override
  String get deskSetNodeRowStopped => 'Gestoppt';

  @override
  String get deskSetNodeRowStarting => 'Startet';

  @override
  String deskSetNodeRowSyncingPct(String percent) {
    return 'Synchronisierung $percent';
  }

  @override
  String get deskSetNodeRowStalled => 'Stockt';

  @override
  String get deskSetNodeRowFailed => 'Fehlgeschlagen';

  @override
  String get deskSetNodeLocalInUse => 'Lokaler Node in Verwendung';

  @override
  String get deskSetNodeLocalInUseText =>
      'Er lädt die ganze Blockchain herunter. Benötigt 5 GB freien Speicher.';

  @override
  String get deskSetNodeLocalNode => 'Lokaler Node';

  @override
  String get deskSetNodeGroupComputer => 'Dieser Computer';

  @override
  String get deskSetNodeServer => 'Node-Server';

  @override
  String get deskSetNodeServerHint =>
      'Der Node, über den die Wallet die Blockchain liest und sendet.';

  @override
  String get deskSetNodeChecking => 'Node wird geprüft…';

  @override
  String get deskSetNodeBackground => 'Im Hintergrund synchronisieren';

  @override
  String get deskSetNodeBackgroundHint =>
      'Beim Schließen des Fensters synchronisiert der Node weiter. Die App bleibt im Infobereich.';

  @override
  String get deskSetPhraseNotCopied => 'Nicht kopiert';

  @override
  String get deskSetPhraseClipboardRefused =>
      'Die Zwischenablage hat den Text abgelehnt.';

  @override
  String get deskSetPhraseCopied => 'Phrase kopiert';

  @override
  String get deskSetPhraseCleared => 'Die Zwischenablage wird in 60 s geleert.';

  @override
  String get deskSetPhraseEnterPassword => 'Geben Sie das Passwort ein.';

  @override
  String get deskSetPhraseWrongPassword => 'Falsches Passwort.';

  @override
  String get deskSetPhraseIntro =>
      'Schreiben Sie diese Wörter der Reihe nach auf Papier. Nur mit ihnen lässt sich diese Wallet wiederherstellen.';

  @override
  String get deskSetPhrasePanel =>
      'Geben Sie das Passwort ein, um die Wörter anzuzeigen';

  @override
  String get deskSetPhraseShowWords => 'Wiederherstellungsphrase anzeigen';

  @override
  String deskSetPhraseWordsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wiederherstellungsphrase, $count Wörter',
      one: 'Wiederherstellungsphrase, $count Wort',
    );
    return '$_temp0';
  }

  @override
  String get deskSetPhraseHideQr => 'QR ausblenden';

  @override
  String get deskSetPhraseShowQr => 'QR zeigen';

  @override
  String get deskSetPhraseHideWords => 'Wiederherstellungsphrase verbergen';

  @override
  String deskSetPhraseHidesIn(int seconds) {
    return 'Wird in $seconds s verborgen';
  }

  @override
  String get deskSetPhraseQrLabel => 'QR-Code der Wiederherstellungsphrase';

  @override
  String get deskSetPhraseBackUp => 'Phrase sichern';

  @override
  String get deskSetPhraseBackUpText =>
      'Wer diese Wörter hat, kann die Coins nehmen. Achten Sie darauf, dass niemand den Bildschirm sieht.';

  @override
  String get deskSetPrivTorOnFailed => 'Tor nicht eingeschaltet';

  @override
  String get deskSetPrivTorOffFailed => 'Tor nicht ausgeschaltet';

  @override
  String get deskSetPrivTor => 'Tor';

  @override
  String get deskSetPrivSwitching => 'Tor wird umgeschaltet';

  @override
  String get deskSetPrivTurnOff => 'Tor ausschalten';

  @override
  String get deskSetPrivNotInBuild => 'Nicht in dieser Version';

  @override
  String get deskSetPrivStarting => 'Startet…';

  @override
  String deskSetPrivStartingDetail(int progress) {
    return '$progress %. Jede Verbindung wartet auf Tor.';
  }

  @override
  String get deskSetPrivNotPublished =>
      'Tor-Adresse noch nicht veröffentlicht. Senden funktioniert.';

  @override
  String deskSetPrivProblemSendsWork(String problem) {
    return '$problem. Senden funktioniert.';
  }

  @override
  String get deskSetPrivConnected => 'Verbunden';

  @override
  String get deskSetPrivNotConnected => 'Nicht verbunden';

  @override
  String get deskSetPrivStoppedDetail =>
      'Tor wurde beendet. Erneut versuchen oder Tor ausschalten.';

  @override
  String deskSetPrivProblemDetail(String problem) {
    return '$problem. Erneut versuchen oder Tor ausschalten.';
  }

  @override
  String get deskSetPrivStatusSite => 'Status-Website';

  @override
  String deskSetPrivUseStatus(String site) {
    return '$site nutzen';
  }

  @override
  String get deskSetPrivUseStatusHint =>
      'Zeigt, welche Nodes und Epicbox-Server online sind, aus einer öffentlichen Liste auf status.btlabs.uk.';

  @override
  String deskSetRecvMethodOnFailed(String method) {
    return '$method nicht eingeschaltet';
  }

  @override
  String deskSetRecvMethodOffFailed(String method) {
    return '$method nicht ausgeschaltet';
  }

  @override
  String get deskSetRecvServerNotChanged => 'Server nicht gewechselt';

  @override
  String get deskSetRecvReceiving => 'Empfang';

  @override
  String deskSetRecvSwitching(String method) {
    return '$method-Empfang wird umgeschaltet';
  }

  @override
  String deskSetRecvMethodReceiving(String method) {
    return '$method-Empfang';
  }

  @override
  String get deskSetRecvNotSaved => 'Nicht gespeichert';

  @override
  String get deskSetRecvAutostart => 'Mit der Wallet starten';

  @override
  String get deskSetRecvAutostartHint => 'Wird beim Entsperren eingeschaltet.';

  @override
  String deskSetRecvMethodAutostart(String method) {
    return '$method: mit der Wallet starten';
  }

  @override
  String get deskSetRecvEpicboxText =>
      'Der Epicbox-Server hält Zahlungen, bis die Wallet geöffnet wird.';

  @override
  String get deskSetRecvEpicboxServer => 'Epicbox-Server';

  @override
  String get deskSetRecvEpicboxServerHint =>
      'Welcher Server Zahlungen für diese Adresse hält. Die beiden Wallets können verschiedene Server nutzen.';

  @override
  String get deskSetRecvSwitchingServer => 'Epicbox-Server wird gewechselt…';

  @override
  String deskSetRecvListNote(String site) {
    return 'Status von $site.';
  }

  @override
  String get deskSetRecvHttpText =>
      'Direkt von einer anderen Wallet an der Web-Adresse dieses Computers, solange diese Wallet geöffnet ist.';

  @override
  String get deskSetRecvHttpOffTitle => 'Aus, solange Tor an ist';

  @override
  String get deskSetRecvHttpOffText =>
      'Zahlungen direkt von einer anderen Wallet kommen stattdessen an der Link · Tor-Adresse an.';

  @override
  String get deskSetRecvPrivacySettings => 'Datenschutz-Einstellungen';

  @override
  String get deskSetHttpNotChanged => 'Nicht geändert';

  @override
  String get deskSetHttpPortError => 'Port muss zwischen 1024 und 65535 liegen';

  @override
  String get deskSetHttpGuideHelp =>
      'Aus dem Internet empfangen: So funktioniert es';

  @override
  String get deskSetHttpPort => 'Port';

  @override
  String deskSetHttpPortHint(String port) {
    return '1024 bis 65535. Standard: $port.';
  }

  @override
  String get deskSetHttpPortLabel => 'HTTP-Port';

  @override
  String get deskSetHttpGuideTitle => 'Aus dem Internet empfangen';

  @override
  String get deskSetHttpGuideNowPublic => 'Jetzt: aus dem Internet.';

  @override
  String get deskSetHttpGuideNowLocal =>
      'Jetzt: nur lokal. Nur Programme auf diesem Computer erreichen die HTTP-Adresse.';

  @override
  String get deskSetHttpStep1 => 'Auf allen Schnittstellen lauschen';

  @override
  String deskSetHttpStep1Text(String port) {
    return 'Die Wallet antwortet auf 0.0.0.0, Port $port, sodass andere Geräte an sie senden können.';
  }

  @override
  String get deskSetHttpStep2 => 'Port weiterleiten';

  @override
  String deskSetHttpStep2Text(String port) {
    return 'Suchen Sie auf der Seite des Routers (oft 192.168.1.1) die Portweiterleitung und leiten Sie TCP $port an diesen Computer weiter.';
  }

  @override
  String get deskSetHttpStep3 => 'Öffentliche Adresse teilen';

  @override
  String deskSetHttpStep3Text(String port) {
    return 'Absender nutzen http://<public IP>:$port. Die öffentliche IP kann sich ändern.';
  }

  @override
  String get deskSetHttpNoRouter => 'Keine Router-Einrichtung?';

  @override
  String get deskSetHttpNoRouterText =>
      'Tor funktioniert von überall, ohne etwas weiterzuleiten.';

  @override
  String get deskSetHttpTurnOnTor => 'Tor einschalten';

  @override
  String get deskSetHttpExposed =>
      'Nur die Empfangs-API ist erreichbar. Einfaches HTTP ist nicht verschlüsselt.';

  @override
  String get deskSetHttpBackLocal => 'Zurück zu „Nur lokal“';

  @override
  String get deskSetReportNotSent =>
      'Der Bericht wurde nicht gesendet. Versuchen Sie es erneut.';

  @override
  String get deskSetReportSaveDialog => 'Bericht speichern';

  @override
  String get deskSetReportSaved =>
      'Gespeichert. Von Geheimnissen bereinigt, nicht verschlüsselt.';

  @override
  String get deskSetReportNotSaved =>
      'Die Datei wurde nicht gespeichert. Versuchen Sie es erneut.';

  @override
  String get deskSetReportText => 'Berichtstext';

  @override
  String deskSetReportAppLog(String size) {
    return 'App-Protokoll (letzte $size)';
  }

  @override
  String get deskSetReportSent => 'Bericht gesendet';

  @override
  String get deskSetReportArrived => 'Der Bericht ist angekommen.';

  @override
  String deskSetReportArrivedRef(String id) {
    return 'Der Bericht ist angekommen. Seine Referenz ist $id.';
  }

  @override
  String get deskSetReportDescribe => 'Beschreiben Sie, was passiert ist.';

  @override
  String get deskSetReportTitle => 'Problem melden';

  @override
  String get deskSetReportDesc =>
      'Verschlüsselt, sodass nur der Entwickler ihn lesen kann. „In Datei speichern“ legt eine unverschlüsselte Kopie ab.';

  @override
  String get deskSetReportWhat => 'Was passiert ist';

  @override
  String get deskSetReportWhatHint =>
      'Was Sie getan haben, was Sie erwartet haben, was stattdessen passiert ist';

  @override
  String get deskSetReportAttach => 'Protokolle anhängen';

  @override
  String get deskSetReportAttachHint =>
      'Der neueste Teil des App-Protokolls, ohne Wiederherstellungsphrase, Passwort und andere Geheimnisse.';

  @override
  String get deskSetReportSentWhat => 'Was gesendet wird';

  @override
  String get deskSetReportNotSentTitle => 'Nicht gesendet';

  @override
  String get deskSetReportOff => 'Senden ist in dieser Version abgeschaltet';

  @override
  String get deskSetReportSaveToFile => 'In Datei speichern';

  @override
  String get deskSetReportSend => 'Senden';

  @override
  String get deskSetRescanComplete => 'Scan abgeschlossen';

  @override
  String get deskSetRescanStoppedLine => 'Scan gestoppt';

  @override
  String get deskSetRescanLog => 'Protokoll der Neuprüfung';

  @override
  String get deskSetRescanText =>
      'Prüft die Blockchain erneut auf das Guthaben dieser Wallet. Nutzen Sie das, wenn das Guthaben falsch aussieht.';

  @override
  String get deskSetRescanDeleteUnconfirmed => 'Unbestätigte löschen';

  @override
  String get deskSetRescanDeleteHint =>
      'Storniert auch unbestätigte Transaktionen und gibt ihre Outputs frei. Eine Zahlung, die schon unterwegs ist, kann dann fehlschlagen.';

  @override
  String get deskSetRescanScanning =>
      'Die Blockchain wird gescannt. Die Wallet bleibt nutzbar; das Guthaben wird aktualisiert, wenn der Scan endet.';

  @override
  String get deskSetRescanStopping => 'Wird gestoppt…';

  @override
  String deskSetRescanChecking(int percent) {
    return 'Wird geprüft… $percent %';
  }

  @override
  String get deskSetRescanFailed => 'Scan fehlgeschlagen';

  @override
  String get deskSetRescanNoneFound =>
      'Es wurde keine unbestätigte Transaktion gefunden.';

  @override
  String get deskSetRescanCancelled =>
      'Unbestätigte Transaktionen wurden storniert und ihre Outputs freigegeben.';

  @override
  String get deskSetRescanNotRead => 'Nicht gelesen';

  @override
  String get deskSetRescanFinished => 'Neuprüfung beendet';

  @override
  String get deskSetRescanUpToDate => 'Das Guthaben ist aktuell.';

  @override
  String get deskSetRescanResumed =>
      'Der Scan hat dort weitergemacht, wo er gestoppt wurde; die Zahlen gelten für diesen Teil.';

  @override
  String get deskSetRescanStoppedEarly =>
      'Vor dem Ende gestoppt. Das Guthaben wurde neu gelesen; starten Sie erneut, um fortzufahren.';

  @override
  String get deskSetRescanNotDeleted =>
      'Unbestätigte Transaktionen wurden nicht gelöscht: Das geschieht nur, wenn ein Scan vollständig durchläuft.';

  @override
  String get deskSetRescanBefore => 'Guthaben vorher';

  @override
  String get deskSetRescanAfter => 'Guthaben danach';

  @override
  String get deskSetRescanFound => 'Gefundene Outputs';

  @override
  String get deskSetRescanRestored => 'Wiederhergestellt';

  @override
  String get deskSetRescanRevived => 'Wieder entsperrt';

  @override
  String get deskSetRescanUnlocked => 'Freigegeben';

  @override
  String get deskSetRescanDeleted => 'Gelöscht';

  @override
  String deskSetWalletsAddedBack(String name) {
    return '$name wieder hinzugefügt';
  }

  @override
  String get deskSetWalletsNotAddedBack => 'Nicht wieder hinzugefügt';

  @override
  String get deskSetWalletsOpenNow => 'Geöffnet';

  @override
  String get deskSetWalletsFolderMissing => 'Ordner fehlt';

  @override
  String deskSetWalletsShowFolder(String name) {
    return '$name im Ordner zeigen';
  }

  @override
  String deskSetWalletsRemove(String name) {
    return '$name entfernen…';
  }

  @override
  String get deskSetWalletsRemovedGroup => 'Aus der Liste entfernt';

  @override
  String get deskSetWalletsAddBack => 'Wieder hinzufügen';

  @override
  String get deskSetWalletsAdd => 'Wallet hinzufügen';

  @override
  String get deskSetWalletsCreate => 'Wallet erstellen';

  @override
  String get deskSetWalletsCreateText =>
      'Eine neue Wallet mit einer neuen Wiederherstellungsphrase.';

  @override
  String get deskSetWalletsImport => 'Wallets importieren';

  @override
  String get deskSetWalletsImportText =>
      'Aus einer älteren Epic Wallet oder einem Ordner';

  @override
  String get deskSetWalletsRestore => 'Mit Phrase wiederherstellen';

  @override
  String get deskSetWalletsRestoreText => 'Aus der Wiederherstellungsphrase';

  @override
  String get deskSetupConfirmPassword => 'Passwort bestätigen';

  @override
  String get deskSetupPasswordShort => 'Mindestens 8 Zeichen';

  @override
  String get deskSetupPasswordsDiffer => 'Passwörter stimmen nicht überein';

  @override
  String get deskSetupBack => 'Zurück';

  @override
  String get deskSetupNewWalletAdded => 'Neue Wallet hinzugefügt.';

  @override
  String get deskSetupCapsLock => 'Feststelltaste ist aktiv';

  @override
  String deskSetupStepSem(int number, int total, String label) {
    return 'Schritt $number von $total: $label';
  }

  @override
  String get deskSetupTryAgain => 'Erneut versuchen';

  @override
  String get deskSetupNotSaved => 'Nicht gespeichert';

  @override
  String get deskSetupStepPrefs => 'Allgemein';

  @override
  String get deskSetupStepNode => 'Node';

  @override
  String get deskSetupStepEpicbox => 'Epicbox';

  @override
  String get deskSetupAgain =>
      'Die Einrichtung läuft erneut. Erst „Einstellungen speichern“ im letzten Schritt ändert etwas.';

  @override
  String get deskSetupPrefsLead => 'Sprache der App';

  @override
  String get deskSetupNodeTitle => 'Node wählen';

  @override
  String get deskSetupNodeLead =>
      'Die Wallet liest die Blockchain und sendet über einen Epic-Node.';

  @override
  String get deskSetupLocalTitle => 'Lokaler Node';

  @override
  String get deskSetupLocalLead =>
      'Was es bedeutet, den Node hier zu betreiben, und welcher Node genutzt wird.';

  @override
  String get deskSetupEpicboxTitle => 'Epicbox';

  @override
  String get deskSetupSideTitle => 'Einrichtung';

  @override
  String get deskSetupBackToWallet => 'Zurück zur Wallet';

  @override
  String get deskSetupSave => 'Einstellungen speichern';

  @override
  String get deskSetupLanguage => 'Sprache';

  @override
  String get deskSetupNodeServer => 'Node-Server';

  @override
  String get deskSetupCheckingNodes => 'Nodes werden geprüft…';

  @override
  String get deskSetupPickNode => 'Node wählen';

  @override
  String get deskSetupRemoteNode => 'Öffentlicher Node';

  @override
  String get deskSetupRemoteNodeText =>
      'Ein beliebiger öffentlicher Node. Sofort bereit.';

  @override
  String get deskSetupLocalNodeText =>
      'Läuft auf diesem Computer: privat, braucht aber Speicherplatz und eine erste Synchronisierung.';

  @override
  String get deskSetupEpicboxText =>
      'Der Epicbox-Server hält Zahlungen, bis die Wallet geöffnet wird.';

  @override
  String get deskSetupEpicboxServer => 'Epicbox-Server';

  @override
  String deskSetupExistingNode(String host) {
    return 'Vorhandener Node unter $host';
  }

  @override
  String deskSetupSaveStartsFallback(String node) {
    return 'Speichern startet den Node; bis er synchronisiert ist, springt $node ein.';
  }

  @override
  String get deskSetupSaveStarts =>
      'Speichern startet den Node. Die erste Synchronisierung dauert Stunden; die Wallet öffnet sich währenddessen.';

  @override
  String get deskSetAboutLicencesLead =>
      'Open-Source-Software in dieser Wallet, jede unter ihrer eigenen Lizenz.';

  @override
  String get deskSetAboutLicenceApp => 'BT Wallet von BT Labs: Apache-2.0.';

  @override
  String get deskSetAboutBrowserNotOpened => 'Browser nicht geöffnet';

  @override
  String get deskSetAboutOpen => 'Öffnen';

  @override
  String deskSetAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String deskSetAboutNode(String version) {
    return 'Node $version';
  }

  @override
  String get deskSetAboutLicences => 'Lizenzen';

  @override
  String get deskSetAboutSource => 'Quellcode';

  @override
  String get deskSetAboutView => 'Ansehen';

  @override
  String deskSetAboutChecked(String ago) {
    return 'Geprüft $ago.';
  }

  @override
  String deskSetAboutLatest(String version) {
    return '$version ist aktuell';
  }

  @override
  String deskSetAboutAvailable(String version) {
    return 'Update verfügbar: $version';
  }

  @override
  String get deskSetAboutCouldNotCheck => 'Prüfung fehlgeschlagen';

  @override
  String get deskSetAboutUpdates => 'Updates';

  @override
  String get deskSetAboutCheckNow => 'Prüfen';

  @override
  String get deskSetAboutAgoNow => 'gerade eben';

  @override
  String deskSetAboutAgoMin(int count) {
    return 'vor $count Min.';
  }

  @override
  String deskSetAboutAgoHours(int count) {
    return 'vor $count h';
  }

  @override
  String deskSetAboutAgoDays(int count) {
    return 'vor $count T.';
  }

  @override
  String get deskSetAboutCopyLink => 'Link kopieren';

  @override
  String get deskSetAboutCopied => 'Kopiert';

  @override
  String get deskSetAboutNotCopied => 'Nicht kopiert';

  @override
  String get deskSetAppearTheme => 'Design';

  @override
  String get deskSetAppearThemeHint =>
      'System folgt der Einstellung des Computers.';

  @override
  String get deskSetAppearSystem => 'System';

  @override
  String get deskSetAppearDark => 'Dunkel';

  @override
  String get deskSetAppearLight => 'Hell';

  @override
  String get deskSetAppearScale => 'Skalierung';

  @override
  String get deskSetAppearScaleHint =>
      'Text und Bedienelemente größer oder kleiner. Gilt sofort.';

  @override
  String get deskSetAppearLanguage => 'Sprache';

  @override
  String get deskSetAppearLanguageHint => 'Gilt sofort.';

  @override
  String get deskSetAppearHideHint =>
      'Zeigt Punkte statt Guthaben und Beträgen.';

  @override
  String deskSetHelpNoMatchText(String query) {
    return 'Kein Thema passt zu „$query“. Versuchen Sie ein anderes Wort.';
  }

  @override
  String deskSetHelpFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Themen gefunden',
      one: '$count Thema gefunden',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpNoMatch => 'Kein passendes Thema';

  @override
  String get deskSetHelpReportText =>
      'Beschreiben Sie, was schiefging; das bereinigte App-Protokoll kann mitgehen, für den Entwickler verschlüsselt.';

  @override
  String get deskSetHelpShowLess => 'Weniger anzeigen';

  @override
  String get deskSetHelpReadMore => 'Mehr lesen';

  @override
  String get deskSetHelpEb1 =>
      'Die sendende Wallet übergibt die Zahlung an Epicbox und sperrt die Outputs.';

  @override
  String get deskSetHelpEb2 =>
      'Epicbox stellt sie zu, sobald die empfangende Wallet online ist. Diese Wallet ergänzt ihren Teil und signiert.';

  @override
  String get deskSetHelpEb3 =>
      'Die empfangende Wallet schickt sie an Epicbox zurück.';

  @override
  String get deskSetHelpEb4 =>
      'Epicbox gibt sie an die sendende Wallet zurück.';

  @override
  String get deskSetHelpSigns =>
      'Die sendende Wallet signiert ebenfalls, schließt die Transaktion ab und sendet sie an das Netzwerk.';

  @override
  String deskSetHelpFinal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Das Netzwerk nimmt sie in einen Block auf. Nach $count Bestätigungen ist sie endgültig.',
      one:
          'Das Netzwerk nimmt sie in einen Block auf. Nach $count Bestätigung ist sie endgültig.',
    );
    return '$_temp0';
  }

  @override
  String get deskSetHelpFile1 =>
      'Die sendende Wallet speichert eine Transaktionsdatei und sperrt die Outputs. Die Datei gelangt auf beliebigem Weg zum Empfänger.';

  @override
  String get deskSetHelpFile2 =>
      'Der Empfänger öffnet sie. Seine Wallet ergänzt ihren Teil, signiert und speichert eine Antwortdatei.';

  @override
  String get deskSetHelpFile3 => 'Die Antwortdatei kommt zum Absender zurück.';

  @override
  String get deskSetHelpFile4 =>
      'Der Absender öffnet die Antwortdatei unter Abschließen.';

  @override
  String get deskSetHelpSender => 'Absender';

  @override
  String get deskSetHelpFile => 'Dateiübertragung';

  @override
  String get deskSetHelpRecipient => 'Empfänger';

  @override
  String get deskSetHelpNetwork => 'Netzwerk';

  @override
  String get deskSetHelpTravels => 'Der Weg einer Transaktion';

  @override
  String get deskSetHelpOverEpicbox => 'Über Epicbox';

  @override
  String get deskSetHelpWithFile => 'Mit Datei';

  @override
  String deskSetHelpStep(int number, int total) {
    return 'Schritt $number von $total';
  }

  @override
  String get deskSetHelpSearch => 'Hilfe durchsuchen';

  @override
  String get deskSetHelpSearchKeys => 'Mit / suchen. Esc leert die Suche.';

  @override
  String get deskSetHelpSearchHint =>
      'Zum Beispiel: Datei, Bestätigungen, Phrase';

  @override
  String get deskSetHelpClear => 'Suche leeren';

  @override
  String get deskSetHelpTourAgain => 'Tour erneut zeigen';

  @override
  String deskSetHelpTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Themen',
      one: '$count Thema',
    );
    return '$_temp0';
  }

  @override
  String get deskErrSecretProtect =>
      'Windows konnte die Geheimnisse der Wallet nicht schützen (DPAPI hat abgelehnt), daher wurde nichts gespeichert. Verwenden Sie Windows direkt als Sie selbst, mit Ihrem eigenen Passwort, nicht über eine Remote- oder Dienstsitzung, und versuchen Sie es erneut.';

  @override
  String get deskKeyringMissingTitle => 'Kein Schlüsselbund gefunden';

  @override
  String get deskKeyringMissingText =>
      'BT Wallet speichert seine Einstellungen und das versiegelte Passwort Ihrer Wallet im Schlüsselbund des Systems, aber keiner hat geantwortet. Installieren oder starten Sie einen Schlüsselbund (GNOME Keyring oder KWallet) oder nutzen Sie eine Desktop-Sitzung, die einen ausführt, und wählen Sie dann Wiederholen.';

  @override
  String get deskKeyringLockedTitle => 'Der Schlüsselbund ist gesperrt';

  @override
  String get deskKeyringLockedText =>
      'BT Wallet speichert seine Einstellungen und das versiegelte Passwort Ihrer Wallet im Schlüsselbund des Systems, und der ist gesperrt. Entsperren Sie ihn (meist mit dem Passwort, mit dem Sie diesen Computer entsperren) und wählen Sie dann Wiederholen, oder wählen Sie Jetzt entsperren, damit das System danach fragt.';

  @override
  String get deskKeyringUnlockNow => 'Jetzt entsperren';

  @override
  String get txStatusNotDelivered => 'Nicht zugestellt';

  @override
  String get txDetailsNotDeliveredBody =>
      'Diese Zahlung hat den Epicbox-Server noch nicht erreicht, deshalb hat der Empfänger sie nicht erhalten. Die Coins bleiben gesperrt, bis sie erneut gesendet oder storniert wird.';

  @override
  String get txDetailsSendAgainDone =>
      'Erneut gesendet. Die Zahlung wird abgeschlossen, sobald die Wallet des Empfängers online ist.';

  @override
  String get deskTxThisWallet => 'Diese Wallet';

  @override
  String get deskErrOldLinks =>
      'Der Ordner dieser Wallet enthält Verknüpfungen und wird deshalb nicht importiert. Stellen Sie die Wallet mit der Wiederherstellungsphrase wieder her.';

  @override
  String get deskErrOldIncomplete =>
      'Der Ordner dieser Wallet konnte nicht vollständig gelesen werden und wird deshalb nicht importiert. Stellen Sie die Wallet mit der Wiederherstellungsphrase wieder her.';

  @override
  String get deskErrOldSeedTooLarge =>
      'Die Datei wallet.seed ist zu groß, um ein Wallet-Seed zu sein.';

  @override
  String get deskErrSendUnbuildable =>
      'Diese Zahlung lässt sich aus den verfügbaren Coins nicht zusammenstellen.';

  @override
  String get deskErrNothingToConsolidate =>
      'Nichts zum Zusammenführen: weniger als zwei verfügbare Outputs.';

  @override
  String deskSetReportFileNone(String name) {
    return '$name (nicht enthalten)';
  }

  @override
  String deskSetReportFileAll(String name, String size) {
    return '$name (vollständig, $size)';
  }

  @override
  String deskSetReportFilePart(String name, String part, String size) {
    return '$name (letzte $part von $size)';
  }

  @override
  String get deskErrTxNotFound => 'Transaktion nicht gefunden';

  @override
  String get deskTxNowUndelivered =>
      'Nicht zugestellt. Die Zahlung hat den Epicbox-Server nicht erreicht, der Empfänger hat sie also nicht erhalten. Senden Sie sie erneut oder stornieren Sie sie, um die Coins freizugeben.';

  @override
  String get deskTxStatusUndelivered => 'Nicht zugestellt';

  @override
  String get deskTxSendAgain => 'Erneut senden';

  @override
  String get deskTxNotSent => 'Nicht gesendet';

  @override
  String get deskTxSentAgain => 'Erneut gesendet';

  @override
  String get deskTxSentAgainText =>
      'Sie wird abgeschlossen, sobald die Wallet des Empfängers online ist.';

  @override
  String get deskSendFeeChangedTitle => 'Die Gebühr hat sich geändert';

  @override
  String deskSendFeeChangedText(String fee, String was) {
    return 'Die Outputs der Wallet haben sich seit dieser Prüfung geändert, daher kostet die Zahlung jetzt $fee EPIC statt $was EPIC Gebühr. Prüfen Sie sie und senden Sie erneut.';
  }

  @override
  String deskSendMessageBytes(int used, int max) {
    return '$used / $max Byte';
  }

  @override
  String deskSendMessageCount(int used, int max) {
    return '$used / $max';
  }

  @override
  String deskSendMessageTooLong(int max) {
    return 'Die Nachricht ist länger als $max Byte. Kürze sie.';
  }

  @override
  String get deskSendMessageTooLongPlain =>
      'Die Nachricht ist zu lang. Bitte kürzen.';

  @override
  String get deskSetPhraseCopyTitle => 'Wiederherstellungsphrase kopieren?';

  @override
  String get deskSetPhraseCopyText =>
      'Wer diese Wörter hat, kann Ihr Guthaben nehmen. Bewahren Sie die Kopie sicher auf.';

  @override
  String get deskOutAdvanced => 'Outputs verwalten';

  @override
  String get deskOutStrategyHint =>
      'Welche Outputs eine Zahlung verbraucht. Kleinste verbraucht die kleinsten Outputs, die den Betrag decken; Alle verbraucht jeden Output und gibt einen zurück.';

  @override
  String get txStatusNotPosted => 'Nicht im Netzwerk';

  @override
  String get txStatusStalled => 'Hängt fest';

  @override
  String get txDetailsStalledBody =>
      'Die Gegenseite hat diese Zahlung noch nicht übertragen.';

  @override
  String get txDetailsNotDeliveredDirectBody =>
      'Diese Zahlung hat die Wallet des Empfängers nicht erreicht, deshalb hat er sie nicht erhalten. Ihr Guthaben bleibt gesperrt, bis sie erneut gesendet oder storniert wird.';

  @override
  String invoiceDetailsStalled(String service) {
    return '$service hat Ihre Zahlung noch nicht veröffentlicht.';
  }

  @override
  String get deskTxStatusNotPosted => 'Nicht im Netzwerk';

  @override
  String get deskTxNowNotPosted =>
      'Nicht im Netzwerk. Der Knoten hat diese Zahlung nicht angenommen. Senden Sie sie erneut ins Netzwerk; sie kann nicht doppelt ausgeführt werden.';

  @override
  String get deskTxBroadcastAgain => 'Erneut übertragen';

  @override
  String get deskTxBroadcastDone => 'An das Netzwerk gesendet';

  @override
  String deskTxNowUndeliveredDirect(String method) {
    return 'Nicht zugestellt. Die Wallet des Empfängers hat die Zahlung ($method) nicht angenommen, er hat sie also nicht erhalten. Senden Sie sie erneut oder stornieren Sie sie, um das Guthaben freizugeben.';
  }

  @override
  String get deskInvPayStalled => 'Hängt fest';

  @override
  String deskInvPayerStalledTitle(String service) {
    return 'Ihre Zahlung an $service hängt fest';
  }

  @override
  String get deskInvPayerStalledText =>
      'Nicht zugestellt: Sie hat das Netzwerk noch nicht erreicht, und das Guthaben bleibt gesperrt. Erneut senden schickt sie noch einmal, ohne zweite Freigabe.';

  @override
  String get deskTxLabelAdd => 'Bezeichnung hinzufügen';

  @override
  String get deskTxLabelEdit => 'Bezeichnung ändern';

  @override
  String get deskTxLabelHint => 'Bezeichnung hinzufügen';

  @override
  String get deskTxLabelField => 'Bezeichnung';

  @override
  String get deskTxLabelAdded => 'Bezeichnung hinzugefügt';

  @override
  String get deskTxLabelSaved => 'Bezeichnung gespeichert';

  @override
  String get deskTxLabelRemoved => 'Bezeichnung entfernt';

  @override
  String get deskTxLabelNotSaved => 'Bezeichnung nicht gespeichert';

  @override
  String get deskTxDetailsAdd => 'Details hinzufügen';

  @override
  String get deskTxDetailsEdit => 'Ändern';

  @override
  String get deskTxDetailsTitleAdd => 'Details hinzufügen';

  @override
  String get deskTxDetailsTitleEdit => 'Details ändern';

  @override
  String get deskTxDetailsTip =>
      'Nur für Zahlungen, die eine Neuprüfung gefunden hat.';

  @override
  String get deskTxDetailsFrom => 'Von';

  @override
  String get deskTxDetailsFromTip =>
      'Wer bezahlt hat, für Ihre Unterlagen. Nicht geprüft.';

  @override
  String get deskTxDetailsFromHint => 'Adresse des Absenders';

  @override
  String get deskTxDetailsFromBad =>
      'Verwenden Sie eine Epicbox-, http(s)- oder .onion-Adresse.';

  @override
  String get deskTxDetailsNote => 'Private Notiz';

  @override
  String get deskTxDetailsAdded => 'Details hinzugefügt';

  @override
  String get deskTxDetailsSaved => 'Details gespeichert';

  @override
  String get deskTxDetailsRemoved => 'Details entfernt';

  @override
  String get deskTxDetailsNotSaved => 'Details nicht gespeichert';

  @override
  String get deskTxManualTag => 'Von Ihnen hinzugefügt';

  @override
  String deskTxManualTip(String date) {
    return 'Am $date von Ihnen hinzugefügt. Nicht aus der Blockchain.';
  }

  @override
  String get deskTxManualTipNoDate =>
      'Von Ihnen hinzugefügt. Nicht aus der Blockchain.';

  @override
  String deskTxManualTipFrom(String date) {
    return 'Am $date von Ihnen hinzugefügt. Nicht aus der Blockchain, nicht geprüft.';
  }

  @override
  String get deskTxManualTipFromNoDate =>
      'Von Ihnen hinzugefügt. Nicht aus der Blockchain, nicht geprüft.';

  @override
  String get deskHistConflictTitle => 'Details weichen ab';

  @override
  String deskHistConflictLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Die Datei hat andere Details für $n Zahlungen. Ihre bleiben erhalten, wenn Sie nicht die der Datei wählen.',
      one: 'Die Datei hat andere Details für 1 Zahlung. Ihre bleiben erhalten, wenn Sie nicht die der Datei wählen.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictMine => 'Meine';

  @override
  String get deskHistConflictBackup => 'Datei';

  @override
  String get deskHistConflictKeepAll => 'Alle meine behalten';

  @override
  String get deskHistConflictImport => 'Importieren';

  @override
  String get deskHistConflictEmpty => 'leer';

  @override
  String deskHistImportedReplaced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Details ersetzt, der Rest bleibt wie von Ihnen.',
      one: '$n Detail ersetzt, der Rest bleibt wie von Ihnen.',
    );
    return '$_temp0';
  }

  @override
  String sendRelayUnknown(String relay) {
    return '$relay ist der App nicht bekannt. Prüfen Sie die Adresse, bevor Sie senden.';
  }

  @override
  String relayNoAnswer(String relay) {
    return '$relay hat nicht geantwortet.';
  }

  @override
  String txDetailsNotDeliveredRelayBody(String relay) {
    return '$relay hat nicht geantwortet, deshalb hat der Empfänger diese Zahlung nicht erhalten. Ihr Guthaben bleibt gesperrt, bis sie erneut gesendet oder storniert wird.';
  }

  @override
  String deskErrNotDeliveredRelay(String relay) {
    return 'Nicht zugestellt: $relay hat nicht geantwortet. Die Zahlung wartet unter Aktivität; stornieren Sie sie dort, um den Betrag freizugeben.';
  }

  @override
  String deskErrRelayNoAnswer(String relay) {
    return '$relay hat nicht geantwortet.';
  }

  @override
  String get deskSendRelayUnknownTitle => 'Unbekannter Epicbox-Server';

  @override
  String deskSendRelayUnknownText(String relay) {
    return '$relay ist der App nicht bekannt. Prüfen Sie die Adresse, bevor Sie senden. Sie können trotzdem senden.';
  }

  @override
  String deskTxNowUndeliveredRelay(String relay) {
    return 'Nicht zugestellt. $relay hat nicht geantwortet, der Empfänger hat die Zahlung also nicht erhalten. Senden Sie sie erneut oder stornieren Sie sie, um das Guthaben freizugeben.';
  }

  @override
  String get deskInvNoticeReceiveSuperseded =>
      'Ihr anderes Gerät mit dieser Wallet hat eine Zahlung angenommen, die auch dieses Gerät empfangen hat. Tippen Sie auf „Guthaben neu prüfen“, um sie hier zu sehen.';

  @override
  String deskHistConflictLeadOldWallet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Der Verlauf des alten Wallets hat andere Details für $n Zahlungen. Ihre bleiben erhalten, wenn Sie nicht die des alten Wallets wählen.',
      one:
          'Der Verlauf des alten Wallets hat andere Details für $n Zahlung. Ihre bleiben erhalten, wenn Sie nicht die des alten Wallets wählen.',
    );
    return '$_temp0';
  }

  @override
  String get deskHistConflictOldWallet => 'Altes Wallet';

  @override
  String get deskHistConflictApply => 'Übernehmen';

  @override
  String get deskUpdAvailable => 'Update verfügbar';

  @override
  String deskUpdDownload(String version) {
    return '$version herunterladen';
  }

  @override
  String get deskUpdOpensPage => 'Öffnet die Download-Seite';

  @override
  String deskUpdDownloading(String percent) {
    return 'Wird heruntergeladen: $percent %';
  }

  @override
  String get deskUpdRestart => 'Neu starten und aktualisieren';

  @override
  String deskUpdReady(String version) {
    return '$version ist bereit';
  }

  @override
  String get deskUpdRestartHint =>
      'Die App schließt sich, installiert das Update und öffnet sich wieder.';

  @override
  String get deskUpdFailed => 'Update nicht heruntergeladen';

  @override
  String get deskUpdTryAgain => 'Erneut versuchen';

  @override
  String get deskUpdInstallFailed => 'Update nicht installiert';

  @override
  String get deskUpdOpenPage => 'Download-Seite öffnen';

  @override
  String get deskUpdErrDamaged =>
      'Die Datei passt nicht zu den signierten Update-Angaben.';

  @override
  String get deskUpdErrStopped => 'Der Download wurde unterbrochen.';

  @override
  String get deskUpdErrInstall =>
      'Die neue Version konnte nicht eingesetzt werden.';

  @override
  String get deskUpdUnfinished =>
      'Update nicht abgeschlossen. Erneut versuchen.';

  @override
  String get advExperimental => 'Experimentell';

  @override
  String get advTitle => 'Erweitert';

  @override
  String get advIntro =>
      'Jeder Schalter blendet einen weiteren Teil der Wallet an der passenden Stelle ein.';

  @override
  String get advShowsHeader => 'Zeigt mehr';

  @override
  String get advNetworkHeader => 'Netzwerk';

  @override
  String get advOutputs => 'Outputs';

  @override
  String get advOutputsHint =>
      'Zeigt die Seite Outputs unter Diese Wallet und auf der Startseite. Sie listet die Coins, aus denen das Guthaben besteht und lässt Sie sie aufteilen oder zusammenführen. Eine laufende Aufteilung oder Zusammenführung hält die Seite sichtbar.';

  @override
  String get advTechnical => 'Technische Details';

  @override
  String get advTechnicalHint =>
      'Zeigt die technischen Zeilen in den Details einer Zahlung: Kernel, Slate-ID, Commitments und Blockhöhe. In den Rechnungs-Einstellungen, wie lange eine Rechnung bezahlbar bleibt.';

  @override
  String get advSendOptions => 'Zahlungsoptionen';

  @override
  String get advSendOptionsHint =>
      'Zeigt Strategie für Zahlungen und Wechselgeld aufteilen unter Einstellungen › Transaktionen: welche Outputs eine Zahlung verbraucht und ob ihr Wechselgeld aufgeteilt wird. Bleibt sichtbar, solange einer der Werte nicht der Vorgabe entspricht.';

  @override
  String get advServerDetails => 'Server-Details';

  @override
  String get advServerDetailsHint =>
      'Zeigt Hosts, Latenz, Version und Blockhöhe in der Serverauswahl und auf der Statuskarte sowie die Epicbox-Adresse unter Empfangen.';

  @override
  String get advRecheckHeight => 'Ab einer Höhe neu prüfen';

  @override
  String get advRecheckHeightHint =>
      'Lässt „Guthaben neu prüfen“ bei einer Blockhöhe oder einem Datum beginnen statt beim ersten Block. Schneller, und der einzige Weg, frühe Blöcke zu überspringen. Beim Wiederherstellen steht die Wahl immer offen.';

  @override
  String get advModeStandard => 'Normal';

  @override
  String get advModeTorOnly => 'Nur Tor';

  @override
  String get advModeTorOnlyLine =>
      'Jede Verbindung läuft über Tor. Bis Tor bereit ist, verbindet sich nichts.';

  @override
  String get advReset => 'Alles wieder ausblenden';

  @override
  String get advBuiltInNode => 'Lokaler Node';

  @override
  String get advLogs => 'Protokolle';

  @override
  String get deskSetFrameAdvanced => 'Erweitert';

  @override
  String get deskSetAdvShows => 'Zeigt mehr';

  @override
  String get deskSetAdvOutputs => 'Outputs';

  @override
  String get deskSetAdvOutputsHint =>
      'Zeigt die Seite Outputs in der Seitenleiste. Sie listet die Coins, aus denen das Guthaben besteht und lässt Sie sie aufteilen oder zusammenführen. Eine laufende Aufteilung oder Zusammenführung hält die Seite sichtbar.';

  @override
  String get deskSetAdvTechnical => 'Technische Details';

  @override
  String get deskSetAdvTechnicalHint =>
      'Zeigt den Bereich Technische Details bei jeder Transaktion: Kernel, Slate-ID, Commitments und Blockhöhe. Ohne den Schalter zeigt ein Link „Mehr“ an einer Transaktion sie einmalig. Bei Rechnungen werden die erweiterten Bereiche gezeigt.';

  @override
  String get deskSetAdvSendOptions => 'Zahlungsoptionen';

  @override
  String get deskSetAdvSendOptionsHint =>
      'Fügt Senden einen Bereich hinzu, in dem eine Zahlung wählen kann, welche Outputs sie verbraucht, Kleinste oder Alle, und ob das Wechselgeld aufgeteilt wird. Die Vorgaben stehen unter Einstellungen › Zahlungen.';

  @override
  String get deskSetAdvServerDetails => 'Server-Details';

  @override
  String get deskSetAdvServerDetailsHint =>
      'Zeigt Hosts, Latenz, Version und Blockhöhe in den Listen für Node und Epicbox, in den Statuszeilen der Seitenleiste und auf der Statuskarte.';

  @override
  String get deskSetAdvRecheck => 'Ab einer Höhe neu prüfen';

  @override
  String get deskSetAdvRecheckHint =>
      'Lässt „Guthaben neu prüfen“ auch unbestätigte Transaktionen verwerfen. Beim Wiederherstellen steht allen ein Startblock zur Wahl, unabhängig von diesem Schalter.';

  @override
  String get deskSetAdvBuiltInNode => 'Lokaler Node';

  @override
  String get deskSetAdvBuiltInNodeHint =>
      'Lässt diesen Computer einen eigenen Node betreiben: die Option Dieser Computer unter Node, deren Synchronisierungsbereich und Node starten auf der Übersicht. Die Chain braucht mehrere Gigabyte Speicher und muss zuerst synchronisiert werden. Ein laufender Node behält seine Zeilen.';

  @override
  String get deskSetAdvLogs => 'Protokolle';

  @override
  String get deskSetAdvLogsHint =>
      'Zeigt die Gruppe Protokolle unter Dateien & Protokolle: Protokollordner öffnen, Protokolle löschen. „Problem melden“ hängt das Protokoll in jedem Fall an.';

  @override
  String get deskSetAdvNetwork => 'Netzwerk';

  @override
  String get deskSetAdvModeTorOnlyText =>
      'Jede Verbindung läuft über Tor. Bis Tor bereit ist, verbindet sich nichts.';

  @override
  String get deskSetAdvNotInBuild => 'Nicht in dieser Version';

  @override
  String get deskSetAdvReset => 'Alles wieder ausblenden';

  @override
  String deskSetAdvOn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Schalter an',
      one: '1 Schalter an',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAcctAutoLockHint =>
      'Sperrt die Wallet nach dieser Zeit ohne Tastendruck oder Mausbewegung. Bei „Nie“ sperrt nur „Wallet sperren“. Alle Wallets.';

  @override
  String get torUndercoverKeepsOn => 'Inkognito lässt Tor eingeschaltet.';

  @override
  String get torLockedTorOnly => 'An bei „Nur Tor“.';

  @override
  String get torUndercoverChange => 'Inkognito ändern';

  @override
  String get torUndercoverChangeShort => 'Ändern';

  @override
  String get txDetailsMore => 'Mehr';

  @override
  String get restoreStartFromLink => 'Ab einem Datum oder einer Höhe starten';

  @override
  String restoreScanningFrom(String month) {
    return 'Scan ab $month';
  }

  @override
  String get restoreScanningFromStart => 'Scan ab dem Anfang';

  @override
  String get restoreScanFromStart => 'Ab dem Anfang scannen';

  @override
  String restoreScanningFromBlock(String height) {
    return 'Scan ab Block $height';
  }

  @override
  String get scanStartChange => 'Start ändern';

  @override
  String get scanStartInfoTitle => 'Scan-Start';

  @override
  String get scanStartInfo =>
      'Gefunden werden nur Coins ab diesem Punkt. Ein früherer Start findet ältere Coins und dauert länger.';

  @override
  String get slNodeField => 'Node-Adresse';

  @override
  String get slRelayField => 'Epicbox-Server';

  @override
  String get slFieldHint =>
      'Einfügen oder tippen, um zu filtern oder hinzuzufügen';

  @override
  String slSwitchTitle(String host) {
    return 'Zu $host wechseln?';
  }

  @override
  String get slSwitchBody =>
      'Beim Wechsel erhalten Sie eine neue Epicbox-Adresse.';

  @override
  String get slSwitch => 'Wechseln';

  @override
  String get slHelpAddable => 'Nicht in der Liste.';

  @override
  String slHelpMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer.',
      one: '$count Treffer.',
      zero: 'Keine Treffer.',
    );
    return '$_temp0';
  }

  @override
  String get slClear => 'Leeren';

  @override
  String slAddRow(String host) {
    return '$host hinzufügen';
  }

  @override
  String get slAddTestsNode =>
      'Prüft zuerst den Node und bietet dann den Wechsel an.';

  @override
  String get slAddTestsRelay =>
      'Prüft zuerst den Server und bietet dann den Wechsel an.';

  @override
  String slAdded(String host) {
    return '$host hinzugefügt.';
  }

  @override
  String get slRemove => 'Entfernen';

  @override
  String slRemoved(String host) {
    return '$host entfernt.';
  }

  @override
  String get slUndo => 'Rückgängig';

  @override
  String get slInUseSwitchFirst => 'In Verwendung. Zuerst wechseln.';

  @override
  String get slRelayWarning =>
      'Beim Wechsel erhalten Sie eine neue Epicbox-Adresse.';

  @override
  String get slNotAnAddress =>
      'Keine Serveradresse. Verwenden Sie host oder host:port.';

  @override
  String get slRelayNoAnswer =>
      'Keine Antwort von diesem Server. Nichts hinzugefügt.';

  @override
  String deskSlRemoveHost(String host) {
    return '$host entfernen';
  }

  @override
  String get deskSlInUse => 'In Verwendung';

  @override
  String get deskSlHealthUnknown => 'Status unbekannt';

  @override
  String get deskSlNodeNoAnswer =>
      'Keine Antwort von diesem Node. Nichts hinzugefügt.';

  @override
  String get deskSlTorWait =>
      'Tor ist noch nicht verbunden. Nichts hinzugefügt.';

  @override
  String deskSlLatency(String ms) {
    return '$ms ms';
  }

  @override
  String get deskSlDefault => 'Standard';

  @override
  String deskSlTesting(String host) {
    return '$host wird getestet…';
  }

  @override
  String get deskSlSetupEpicboxOn => 'Über Epicbox empfangen';

  @override
  String get deskSlHelpChoose =>
      'Wählen Sie einen aus oder tippen Sie, um die Liste zu filtern oder einen Server hinzuzufügen.';

  @override
  String get deskNetWaitingTorReason =>
      'Wartet auf Tor. Nur Tor ist unter Erweitert eingeschaltet.';

  @override
  String get deskNetOpenAdvanced => 'Erweitert öffnen';

  @override
  String get deskNetSendFileHint =>
      'Die Dateiübertragung funktioniert weiterhin.';

  @override
  String get deskNetRecvWaitTorText =>
      'Der Empfang startet, sobald Tor verbunden ist. Die Dateiübertragung funktioniert weiterhin.';

  @override
  String get deskTourAdvancedTitle => 'Erweitert';

  @override
  String get deskTourAdvancedText =>
      'Der Nur-Tor-Modus, Outputs und technische Details sind hier. Schalten Sie ein, was Sie brauchen.';

  @override
  String get deskTxMore => 'Mehr';

  @override
  String get deskTxLess => 'Weniger';

  @override
  String get settingsSectionTransactions => 'Transaktionen';

  @override
  String get txMethodsHeader => 'Zahlungsmethoden';

  @override
  String txLinkHttpHint(String port) {
    return 'Link · HTTP zahlt direkt an eine Wallet unter einer Web-Adresse (http://host:$port) und gibt diesem Telefon eine Adresse, an die Wallets im selben WLAN zahlen können. Beide Wallets müssen geöffnet sein. Es ist unterwegs nicht verschlüsselt, aus dem Internet oder über Mobilfunk nicht erreichbar und aus, solange Tor an ist. Fügt Link · HTTP zu Senden und Empfangen hinzu.';
  }

  @override
  String get txLinkTorHint =>
      'Link · Tor zahlt direkt an eine Wallet unter einer Onion-Adresse und gibt diesem Telefon eine Tor-Adresse, unter der es bezahlt werden kann. Beide Wallets müssen geöffnet sein. Braucht Tor: Der Tor-Schalter unter Datenschutz & Netzwerk leitet die Verbindungen der Wallet über Tor; dieser Schalter schaltet nur die Adresse ein. Fügt Link · Tor zu Senden und Empfangen hinzu.';

  @override
  String get txLinkTorHintNet =>
      'Link · Tor zahlt direkt an eine Wallet unter einer Onion-Adresse und gibt diesem Telefon eine Tor-Adresse, unter der es bezahlt werden kann. Beide Wallets müssen geöffnet sein. Braucht Tor: Der Tor-Schalter unter Netzwerk & Datenschutz leitet die Verbindungen der Wallet über Tor; dieser Schalter schaltet nur die Adresse ein. Fügt Link · Tor zu Senden und Empfangen hinzu.';

  @override
  String get txLinkTorNeedsTor =>
      'Braucht Tor. Schalten Sie es unter Datenschutz & Netzwerk ein.';

  @override
  String get txLinkTorNeedsTorNet =>
      'Braucht Tor. Schalten Sie es unter Netzwerk & Datenschutz ein.';

  @override
  String get txLastMethodNotice =>
      'Mindestens eine Zahlungsmethode bleibt eingeschaltet.';

  @override
  String get txEpicboxHint =>
      'Epicbox zahlt über einen Server, die andere Wallet muss also nicht geöffnet sein. Aus: Die Wallet verbindet sich mit keinem Server, also keine Epicbox-Zahlungen oder Rechnungen. Die anderen Methoden funktionieren weiter.';

  @override
  String get txFileHint =>
      'Die Dateiübertragung erstellt eine Transaktionsdatei, die Sie der anderen Person auf beliebigem Weg weitergeben (Chatnachricht, USB-Stick, Kabel), und sie gibt eine zurück. Zwischen den beiden Wallets ist keine Verbindung nötig. Fügt die Dateiübertragung zu Senden und Empfangen hinzu.';

  @override
  String get txStartHeader => 'Standardmethode';

  @override
  String get txDefaultsHeader => 'Zahlungsvorgaben';

  @override
  String get outputsDefaultsMoved =>
      'Die Zahlungsvorgaben sind unter Einstellungen › Transaktionen';

  @override
  String get advNodeFailover => 'Automatischer Node-Wechsel';

  @override
  String get advNodeFailoverHint =>
      'Antwortet Ihr Node nicht mehr, nutzt die Wallet für diese Sitzung den nächsten funktionierenden Node in Ihrer Liste.';

  @override
  String get advBalanceHeader => 'Guthaben';

  @override
  String get advConfirmations => 'Bestätigungen';

  @override
  String advConfirmationsHint(int byDefault, int min, int max) {
    return 'Wie viele Blöcke eine empfangene Zahlung wartet, bevor ihre Outputs verfügbar sind. Standardmäßig $byDefault; jeder Wert von $min bis $max.';
  }

  @override
  String get advConfirmationsDefault => 'Voreinstellung';

  @override
  String advConfirmationsReset(int count) {
    return 'Auf $count zurücksetzen';
  }

  @override
  String get advConfirmationsFewer => 'Weniger Bestätigungen';

  @override
  String get advConfirmationsMore => 'Mehr Bestätigungen';

  @override
  String advConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bestätigungen',
      one: '$count Bestätigung',
    );
    return '$_temp0';
  }

  @override
  String get advConfirmationsLowNote =>
      'Weniger Bestätigungen sind schneller, aber weniger sicher.';

  @override
  String nodeFailoverSwitched(String host) {
    return 'Node antwortet nicht. Gewechselt zu $host.';
  }

  @override
  String nodeFailoverInsteadOf(String host) {
    return 'Statt $host';
  }

  @override
  String get deskSetAdvNodeFailover => 'Automatischer Node-Wechsel';

  @override
  String get deskSetAdvNodeFailoverHint =>
      'Antwortet Ihr Node nicht mehr oder fällt er zurück, nutzt die Wallet für diese Sitzung den nächsten funktionierenden Node in Ihrer Liste.';

  @override
  String deskNodeFailoverSwitched(String host) {
    return 'Node antwortet nicht. Gewechselt zu $host.';
  }

  @override
  String deskNodeFailoverInsteadOf(String host) {
    return 'Statt $host';
  }

  @override
  String get netOfflineNoPeers =>
      'Ihr Node hat keine Peers: Die Zahlung wartet in seinem Pool, bis er sich wieder verbindet.';

  @override
  String get netOfflineNodeHint =>
      'Nutzt den Node, um die Chain zu lesen und zu senden. Für die größte Privatsphäre einen lokalen Node verwenden.';

  @override
  String get netOfflineNodeLine => 'Nutzt den Node';

  @override
  String get netBlockEpicboxOff =>
      'Epicbox ist in den Zahlungseinstellungen aus.';

  @override
  String netBlockMethodOff(String method) {
    return '$method ist in den Zahlungseinstellungen ausgeschaltet.';
  }

  @override
  String get txEpicboxOffTitle => 'Epicbox ausschalten?';

  @override
  String txEpicboxOffPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen warten auf ihre Antworten über Epicbox. Sie kommen an, sobald Epicbox wieder an ist.',
      one: 'Eine Zahlung wartet auf ihre Antwort über Epicbox. Sie kommt an, sobald Epicbox wieder an ist.',
    );
    return '$_temp0';
  }

  @override
  String get txEpicboxOffAction => 'Ausschalten';

  @override
  String sendContactOnlyEpicbox(String name) {
    return '$name hat nur eine Epicbox-Adresse.';
  }

  @override
  String sendContactOnlyMethod(String name, String method) {
    return '$name hat nur eine Adresse für $method.';
  }

  @override
  String get receiveEpicboxOffText =>
      'Zahlungen warten auf dem Epicbox-Server, bis Epicbox wieder an ist.';

  @override
  String get receiveNoMethods => 'Keine Empfangsmethode ist an';

  @override
  String get receiveNoMethodsBody =>
      'Schalten Sie eine unter Einstellungen › Transaktionen an.';

  @override
  String get receiveNoMethodsButton => 'Einstellungen öffnen';

  @override
  String get deskNetOfflineNoPeers =>
      'Ihr Node hat keine Peers: Die Zahlung wartet in seinem Pool, bis er sich wieder verbindet.';

  @override
  String get deskOutDefaultsMoved =>
      'Strategie und Wechselgeld aufteilen für Zahlungen stellen Sie unter Einstellungen › Transaktionen ein.';

  @override
  String get deskOutDefaultsOpen => 'Transaktionen öffnen';

  @override
  String get deskSetFrameTransactions => 'Transaktionen';

  @override
  String get deskSetTxMethods => 'Methoden';

  @override
  String get deskSetTxEpicboxHint =>
      'Zahlen und bezahlt werden über einen Epicbox-Server. Die meisten Zahlungen laufen so. Aus: Die Wallet verbindet sich mit keinem Epicbox-Server, also keine Epicbox-Zahlungen oder Rechnungen. Die anderen Methoden funktionieren weiter. Alle Wallets.';

  @override
  String deskSetTxDirectHint(String port) {
    return 'Zahlen und bezahlt werden direkt von Wallet zu Wallet unter einer Web-Adresse (http://host:$port), ohne Server dazwischen. Funktioniert nur, solange beide Wallets geöffnet sind; aus, solange Tor an ist. Fügt Link · HTTP zu Senden und seine Adresse zu Empfangen hinzu. Alle Wallets.';
  }

  @override
  String get deskSetTxFileHint =>
      'Zahlen und bezahlt werden, indem Sie eine Transaktionsdatei übergeben, ganz ohne Netzwerk. Fügt die Dateiübertragung zu Senden und die Dateischritte zu Empfangen hinzu. Alle Wallets.';

  @override
  String get deskSetTxStart => 'Standardmethode';

  @override
  String get deskSetTxStartHint =>
      'Die Methode, mit der die Seite Senden sich öffnet. Für eine einzelne Zahlung können Sie sie auf Senden trotzdem ändern. Alle Wallets.';

  @override
  String get deskSendMethodHeader => 'Zahlungsart';

  @override
  String get sendRequestTitle => 'Rechnung';

  @override
  String get sendRequestCheck => 'Prüfen Sie den Betrag und fahren Sie fort.';

  @override
  String get sendRequestDismiss => 'Ausblenden';

  @override
  String get sendAmountFromCode => 'Vom Code angefordert';

  @override
  String sendAmountCodeAsked(String amount) {
    return 'Der Code hat $amount angefordert.';
  }

  @override
  String get sendCodeAmountInvalid =>
      'Der Betrag in diesem Code ist ungültig und wurde ignoriert.';

  @override
  String get sendCodeAmountTooLarge =>
      'Der Betrag in diesem Code ist zu groß und wurde ignoriert.';

  @override
  String get sendCodeTooLong =>
      'Ein Teil dieses Codes war zu lang und wurde ignoriert.';

  @override
  String get payeeNameLabel => 'Name vom Empfänger';

  @override
  String get payeeNoteLabel => 'Nachricht vom Empfänger';

  @override
  String get sendNoteRequiredHelper =>
      'Der Empfänger benötigt diese Nachricht. Lassen Sie sie unverändert.';

  @override
  String sendMinimumAmount(String amount) {
    return 'Mindestens $amount';
  }

  @override
  String get sendBelowMinimumTitle => 'Unter dem Mindestbetrag';

  @override
  String sendBelowMinimum(String amount) {
    return 'Der Mindestbetrag ist $amount. Weniger wird dem Empfänger möglicherweise nicht gutgeschrieben.';
  }

  @override
  String get sendCodeMinimumInvalid =>
      'Der Mindestbetrag in diesem Code ist ungültig und wurde ignoriert.';

  @override
  String get sendNoteMissingTitle => 'Nachricht fehlt';

  @override
  String get sendNoteMissingCode =>
      'Dieser Code verlangt eine Nachricht. Ohne sie wird die Zahlung dem Empfänger möglicherweise nicht gutgeschrieben.';

  @override
  String get serviceHintExchangeCheckNote =>
      'Das sieht nach einer Börsenadresse aus. Prüfen Sie die Nachricht. Börsen nennen sie möglicherweise On-Chain-Notiz.';

  @override
  String get sendNoteFromCodeHelper =>
      'Aus dem Code. Der Empfänger sieht sie auch.';

  @override
  String get sendOriginQr => 'Aus einem QR-Code';

  @override
  String get sendOriginLink => 'Aus einem Link';

  @override
  String get sendOriginPasted => 'Eingefügt';

  @override
  String get sendDirectHost => 'Host';

  @override
  String get scanNotEpicTitle => 'Kein Epic-Code';

  @override
  String get scanNotEpicBody =>
      'Dies ist keine Epic-Adresse und kein Zahlungscode.';

  @override
  String get scanBadAddress => 'Die Adresse in diesem Code ist ungültig.';

  @override
  String get scanWrongNetworkTitle => 'Anderes Netzwerk';

  @override
  String get scanWrongNetworkBody =>
      'Diese Adresse gehört zu einem anderen Epic-Netzwerk. Diese Wallet kann sie nicht bezahlen.';

  @override
  String get scanSlateTextBody =>
      'Dies ist der Text einer Transaktionsdatei, keine Adresse.';

  @override
  String get commonOpen => 'Öffnen';

  @override
  String get scanPairingTitle => 'Kopplungslink';

  @override
  String get scanPairingUnavailable =>
      'Kopplung ist in dieser Version nicht verfügbar.';

  @override
  String get scanCodeTextLabel => 'Gescannter Text';

  @override
  String get scanCopied => 'Kopiert';

  @override
  String get linkWaitingPairingNotice => 'Kopplungslink empfangen';

  @override
  String get linkWaitingNotice => 'Zahlungslink empfangen';

  @override
  String get linkFinishCurrentFirst =>
      'Schließen Sie zuerst die aktuelle Zahlung ab.';

  @override
  String get deskSendToQrPayment =>
      'Ein QR-Zahlungscode. Scannen Sie ihn mit BT Wallet auf dem Telefon.';

  @override
  String get deskSetRecvTorText =>
      'Direkt von einer anderen Wallet an der Tor-Adresse dieser Wallet, solange sie geöffnet ist.';

  @override
  String get deskSetTxTorHint =>
      'Zahlen und bezahlt werden direkt von Wallet zu Wallet unter einer Onion-Adresse, über Tor, ohne Server dazwischen. Funktioniert nur, solange beide Wallets geöffnet sind. Braucht Tor: Der Tor-Schalter unter Datenschutz leitet die Verbindungen der Wallet über Tor; dieser Schalter schaltet nur die Adresse ein. Fügt Link · Tor zu Senden und seine Adresse zu Empfangen hinzu.';

  @override
  String get deskSetTxTorNeedsTor =>
      'Tor ist aus. Schalten Sie es unter Datenschutz ein, um an der Tor-Adresse bezahlt zu werden.';

  @override
  String get deskSetTxLastMethod =>
      'Mindestens eine Zahlungsmethode bleibt eingeschaltet.';

  @override
  String get deskRecvTorOffTitle => 'Link · Tor braucht Tor.';

  @override
  String get deskRecvTorOffText =>
      'Die Tor-Adresse funktioniert, solange Tor an ist. Tor ist der Schalter unter Einstellungen › Datenschutz; er leitet die Verbindungen der Wallet über Tor.';

  @override
  String get deskSetupSaveFailedTitle => 'Einstellungen nicht gespeichert';

  @override
  String deskSetupSaveFailedText(String reason) {
    return '$reason. Speichern Sie erneut oder überspringen Sie, um die bisher gespeicherten Einstellungen zu behalten.';
  }

  @override
  String get deskSetupResumeLead =>
      'Die Einrichtung wurde beim letzten Mal nicht abgeschlossen. Die Wallet liest die Blockchain und sendet über einen Epic-Node.';

  @override
  String deskErrProofContactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte mit vorhandenen zusammengeführt',
      one: '1 Kontakt mit einem vorhandenen zusammengeführt',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsKnown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte waren schon gespeichert',
      one: '1 Kontakt war schon gespeichert',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte übersprungen: keine gültige Adresse',
      one: '1 Kontakt übersprungen: keine gültige Adresse',
    );
    return '$_temp0';
  }

  @override
  String deskErrProofContactAddressesLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Adressen nicht hinzugefügt: Konflikt mit gespeicherten Kontakten',
      one: '1 Adresse nicht hinzugefügt: Konflikt mit einem gespeicherten Kontakt',
    );
    return '$_temp0';
  }

  @override
  String get deskErrProofContactsUnreadable =>
      'Einige alte Kontakte waren nicht lesbar: Das alte Adressbuch ist beschädigt';

  @override
  String get deskErrProofContactsFailed =>
      'Nicht alle Kontakte gespeichert: Das Adressbuch konnte nicht geschrieben werden';

  @override
  String get deskTxStatusSenderPosted => 'Laut Absender gesendet';

  @override
  String get deskTxNowSenderPosted =>
      'Laut Absender ist diese Zahlung gesendet. Sie wird abgeschlossen, sobald das Netzwerk sie bestätigt.';

  @override
  String get deskImpWrongTypePasted =>
      'Der eingefügte Text ist keine Transaktion. Fügen Sie den ganzen Text des Absenders ein oder wählen Sie seine Datei.';

  @override
  String get pairTitle => 'Koppeln';

  @override
  String pairWithName(String name) {
    return 'Mit $name koppeln';
  }

  @override
  String get pairInPerson => 'Persönlich';

  @override
  String get pairInPersonHint => 'Ihren Code zeigen und den anderen scannen';

  @override
  String get pairOfflineHint =>
      'Sie sind offline. Einladung und Antwort gehen von Hand.';

  @override
  String get pairEnterHint =>
      'Einen Einladungslink einfügen oder die erhaltenen Wörter eintippen';

  @override
  String get pairNotPaired => 'Nicht gekoppelt';

  @override
  String get pairNotPairedHint =>
      'Koppeln, um Transaktionsdateien zu versiegeln und Rechnungen zu erlauben.';

  @override
  String get pairInPersonTitle => 'Persönlich koppeln';

  @override
  String get pairShowMyCode => 'Meine Einladung zeigen';

  @override
  String get pairScanTheirs => 'Code scannen';

  @override
  String get pairShowCodeCaption =>
      'Lassen Sie diesen Code scannen und scannen Sie dann den anderen.';

  @override
  String get pairScanCaption =>
      'Beide scannen. Die Wortprüfung öffnet sich, sobald beide Codes gelesen sind.';

  @override
  String get pairScanPrompt => 'Scannen Sie ihren QR';

  @override
  String get pairSeenAs => 'Die andere Seite sieht Sie als';

  @override
  String get pairUseWords => 'Stattdessen Wörter verwenden';

  @override
  String get pairCameraDeniedTitle => 'Die Kamera ist nicht erlaubt';

  @override
  String get pairCameraDeniedBody =>
      'Erlaube die Kamera zum Scannen, oder füge die Einladung ein.';

  @override
  String get pairOpenSettings => 'Einstellungen öffnen';

  @override
  String get pairWordsTitle => 'Kopplungswörter';

  @override
  String get pairWordsLead =>
      'Lesen Sie diese Wörter in dieser Reihenfolge vor. Die andere Wallet findet die Einladung über die Wörter.';

  @override
  String get pairWordsGoodFor => '10 Minuten gültig';

  @override
  String get pairWordsLastMinute => 'Weniger als eine Minute übrig';

  @override
  String get pairWordsFooter =>
      'Wer diese Wörter hat, kann die Einladung beantworten, bis sie abläuft. Prüfen Sie danach gemeinsam die Wörter.';

  @override
  String get pairWordsNew => 'Neue Wörter';

  @override
  String get pairWordsCopy => 'Wörter kopieren';

  @override
  String get pairWordsExpiredTitle => 'Diese Wörter sind abgelaufen';

  @override
  String get pairWordsExpiredBody =>
      'Erstellen Sie neue und lesen Sie sie erneut vor.';

  @override
  String get pairWordsNeedEpicbox =>
      'Gesprochene Einladungen brauchen Epicbox und werden daher gerade nicht angeboten.';

  @override
  String pairWordsDesktopChip(String time) {
    return 'Wörter: noch $time';
  }

  @override
  String get pairEnterLead =>
      'Fügen Sie den Einladungslink ein oder tippen Sie die fünf erhaltenen Wörter.';

  @override
  String get pairEnterField => 'Einladungslink oder Wörter';

  @override
  String get pairEnterNotFound =>
      'Zu diesen Wörtern gibt es keine Einladung. Prüfen Sie sie oder bitten Sie um neue.';

  @override
  String get pairEnterTryAgain => 'Erneut versuchen';

  @override
  String get pairCardCopy => 'Meinen Kopplungslink kopieren';

  @override
  String get pairCardHint =>
      'Persönlich ohne Kamera: Jede Wallet fügt oben den Kopplungslink der anderen ein.';

  @override
  String pairCardBackTitle(String name) {
    return 'Geben Sie $name jetzt Ihren Code';
  }

  @override
  String pairCardBackBody(String name) {
    return 'Fügen Sie diesen Link in der Wallet von $name unter „Link oder Wörter eingeben“ ein. Verifizieren Sie dann gemeinsam.';
  }

  @override
  String get pairEnterDesktopPlaceholder =>
      'Einladungslink einfügen oder die fünf Wörter tippen';

  @override
  String get pairExpiresIn => 'Einladung läuft ab in';

  @override
  String get pairExpiry1h => '1 Stunde';

  @override
  String get pairExpiry24h => '24 Stunden';

  @override
  String get pairExpiry7d => '7 Tage';

  @override
  String get pairWhatTheyReceive => 'Was die andere Seite erhält';

  @override
  String get contactsPairHint =>
      'Koppeln Sie mit einer anderen Wallet, um Transaktionsdateien und Rechnungen zwischen beiden zu versiegeln.';

  @override
  String get contactsPairLearn => 'So funktioniert es';

  @override
  String get contactsPairTooltip => 'Mit einer anderen Wallet koppeln';

  @override
  String get pairBadgePending => 'Kopplung läuft…';

  @override
  String get pairBadgePendingTip =>
      'Einladung gesendet oder beantwortet, noch nicht abgeschlossen.';

  @override
  String get pairWaysLead =>
      'Einmal koppeln. Danach sind Transaktionsdateien und Rechnungen zwischen beiden Wallets versiegelt.';

  @override
  String get pairWayWords => 'Wörter';

  @override
  String get pairWayAutomatic => 'Gesprochen';

  @override
  String get pairWayWordsHint =>
      'Lesen Sie die fünf Kopplungswörter vor. Beide Wallets müssen online sein.';

  @override
  String get pairWayWordsInfo =>
      'Beide Wallets müssen online sein. Ihre Wallet legt die Einladung auf den Verbindungsservern ab; die andere findet sie über die fünf Wörter. Danach verifizieren Sie gemeinsam.';

  @override
  String get pairWayMessage => 'Per Nachricht';

  @override
  String get pairWayMessageHint =>
      'Senden Sie einen Link in einem beliebigen Chat.';

  @override
  String get pairWayMessageInfo =>
      'Drei Nachrichten: Ihre Einladung, die Antwort, Ihr Abschlusslink. Kopieren Sie jede, wenn sie ankommt; die Wallet findet sie in der Zwischenablage, wenn Sie zurückkehren. Funktioniert auch, wenn ein Server gesperrt oder eine Wallet offline ist.';

  @override
  String get pairWayInPersonDesk =>
      'Das Telefon der anderen Seite scannt Ihren Code';

  @override
  String get pairGotInvite => 'Wörter oder Link erhalten?';

  @override
  String get pairGotInviteHint =>
      'Tippen Sie die Wörter oder fügen Sie die erhaltene Nachricht ein.';

  @override
  String get pairHowItWorks => 'So funktioniert Koppeln';

  @override
  String get pairWordsBothOnline =>
      'Beide Wallets müssen online sein. Der Rest geschieht von selbst.';

  @override
  String get pairWordsWaiting => 'Warten auf die andere Wallet…';

  @override
  String get pairUseMessageInstead => 'Stattdessen per Nachricht einladen';

  @override
  String get pairAskForMessage =>
      'Bitten Sie die andere Seite, Sie stattdessen per Nachricht einzuladen.';

  @override
  String get pairStepInvite => 'Einladung';

  @override
  String get pairStepReply => 'Antwort';

  @override
  String get pairStepFinish => 'Abschlusslink';

  @override
  String get pairStepWords => 'Wörter';

  @override
  String pairStepOf(int n, String step) {
    return 'Schritt $n von 4: $step';
  }

  @override
  String get pairMessageLead =>
      'Senden Sie die Einladung in einem beliebigen Chat. Die Antwort kommt auf demselben Weg zurück.';

  @override
  String pairInviteMessage(String link) {
    return 'Einladung zur Kopplung in BT Wallet: $link';
  }

  @override
  String pairReplyMessage(String link) {
    return 'Meine Antwort zur BT-Wallet-Kopplung: $link';
  }

  @override
  String pairFinishMessage(String link) {
    return 'Abschluss unserer BT-Wallet-Kopplung: $link';
  }

  @override
  String pairFinishLinkMessage(String link) {
    return 'BT-Wallet-Kopplung abschließen: $link';
  }

  @override
  String get pairCopyMessage => 'Nachricht kopieren';

  @override
  String get pairMessageCopied => 'Kopiert. Fügen Sie es im Chat ein.';

  @override
  String get pairAwaitReplyTitle => 'Warten auf die Antwort';

  @override
  String get pairAwaitReplyBody =>
      'Wenn die Antwort im Chat ankommt, kopieren Sie sie und kehren Sie zurück. Die Wallet findet sie.';

  @override
  String get pairByItself =>
      'Erreichen beide Wallets einen Epicbox-Server, geschieht dieser Schritt auch von selbst.';

  @override
  String get pairPasteReply => 'Antwort einfügen';

  @override
  String get pairReplyTitle => 'Antwort senden';

  @override
  String pairReplyLead(String name) {
    return 'Senden Sie dies im selben Chat an $name zurück.';
  }

  @override
  String get pairShareReply => 'Antwort teilen';

  @override
  String get pairAwaitFinishTitle => 'Warten auf den Abschlusslink';

  @override
  String pairAwaitFinishBody(String name) {
    return 'Die Wallet von $name erstellt ihn aus Ihrer Antwort. Kopieren Sie ihn, wenn er ankommt, und kehren Sie zurück.';
  }

  @override
  String get pairPasteFinish => 'Abschlusslink einfügen';

  @override
  String get pairPasteLink => 'Link einfügen';

  @override
  String get pairFinishTitle => 'Abschlusslink senden';

  @override
  String pairFinishLead(String name) {
    return 'Noch eine Nachricht: Die Wallet von $name braucht sie, um die Wörter zu zeigen.';
  }

  @override
  String get pairShareFinish => 'Abschlusslink teilen';

  @override
  String get pairFinishThenCheck => 'Prüfen Sie dann gemeinsam die Wörter.';

  @override
  String pairAlreadyPaired(String name) {
    return 'Bereits mit $name gekoppelt.';
  }

  @override
  String get pairReplyNotHere =>
      'Diese Antwort gehört zu einer Einladung einer anderen Wallet.';

  @override
  String get helpPairWaysTitle => 'Drei Wege zu koppeln';

  @override
  String get helpPairWaysShort =>
      'Gesprochen, wenn beide Wallets online sind, eine Nachricht in einem beliebigen Chat oder persönlich.';

  @override
  String get helpPairWaysP1 =>
      '**Gesprochen.** Eine Wallet zeigt fünf Wörter und legt eine versiegelte Einladung auf den Verbindungsservern ab. Die andere Wallet tippt die Wörter und findet sie. Beide Wallets müssen online sein und einen dieser Server erreichen.';

  @override
  String get helpPairWaysP2 =>
      '**Einladung per Nachricht.** Drei Nachrichten in einem beliebigen Chat: die Einladung, die Antwort, der Abschlusslink. Es ist kein Server nötig, daher funktioniert das auch, wenn ein Netz Epicbox sperrt. Kopieren Sie jede Nachricht, wenn sie ankommt; die Wallet bietet sie an, wenn Sie zurückkehren.';

  @override
  String get helpPairWaysP3 =>
      '**Persönlich.** Jedes Telefon scannt den Code des anderen. Es wird kein Netz verwendet.';

  @override
  String get helpPairWaysP4 =>
      'Verifizieren Sie auf jedem Weg am Ende gemeinsam: Vergleichen Sie die vier Bilder und Namen. Sie stimmen nur überein, wenn beide Wallets dieselben Schlüssel sehen.';

  @override
  String get helpPairClipP =>
      'Die Wallet liest die Zwischenablage nur, solange Kopplung eingeschaltet ist, nur wenn sie in den Vordergrund kommt oder der Kopplungsbildschirm öffnet, und bietet jeden Link einmal an. Sie speichert und protokolliert nie, was sie liest.';

  @override
  String get pairShareWarning =>
      'Wer diese Einladung hat, kann sich bis zum Ablauf als Sie koppeln. Senden Sie sie nur an die gemeinte Person und verifizieren Sie danach gemeinsam.';

  @override
  String get pairShareInvite => 'Einladung teilen';

  @override
  String get pairCopyInvite => 'Einladung kopieren';

  @override
  String get pairCancelInvite => 'Einladung zurückziehen';

  @override
  String pairCancelInviteTitle(String name) {
    return 'Einladung an $name zurückziehen?';
  }

  @override
  String pairCancelInviteBody(String name) {
    return 'Wenn die andere Wallet sie später öffnet, sieht sie „$name hat diese Einladung zurückgezogen“.';
  }

  @override
  String pairIncomingTitle(String name) {
    return 'Kopplungsanfrage von $name';
  }

  @override
  String pairIncomingBodyRequest(String name) {
    return 'Nach dem Koppeln sind Transaktionsdateien und Rechnungen zwischen Ihnen und $name versiegelt.';
  }

  @override
  String get pairIncomingServer => 'Server';

  @override
  String get pairIncomingSource => 'Quelle';

  @override
  String get pairIncomingSourceScanned => 'QR gescannt';

  @override
  String get pairIncomingSourcePasted => 'Einladung eingefügt';

  @override
  String get pairIncomingSourceOpened => 'Aus einer anderen App geöffnet';

  @override
  String get pairIncomingSourceRequest => 'An Ihre Epicbox-Adresse gesendet';

  @override
  String get pairVerifiedService => 'Verifizierter BT-Labs-Dienst';

  @override
  String pairCallsThemselves(String name) {
    return 'Nennt sich „$name“';
  }

  @override
  String pairIncomingBody(String name) {
    return 'Nach dem Koppeln sind Transaktionsdateien und Rechnungen zwischen Ihnen und $name versiegelt. Als Nächstes verifizieren Sie gemeinsam.';
  }

  @override
  String pairIncomingAllowInvoices(String name) {
    return '$name Zahlungsanforderungen erlauben';
  }

  @override
  String get pairIncomingAllowHintDesktop =>
      'Gilt, nachdem Sie verifiziert haben. Ohne das Wallet-Passwort wird nichts bezahlt.';

  @override
  String get pairIncomingAllowHint =>
      'Gilt, nachdem Sie verifiziert haben. Ohne Ihre PIN wird nichts bezahlt.';

  @override
  String get pairNotNow => 'Nicht jetzt';

  @override
  String get pairWaitingBody =>
      'Die andere Wallet antwortet, sobald sie geöffnet wird. Sie können diese Seite schließen; die Verifizierung erscheint, wenn die Kopplung fertig ist.';

  @override
  String get pairSendByHand => 'Von Hand senden';

  @override
  String get pairReplyLateTitle => 'Noch nicht gekoppelt?';

  @override
  String pairReplyLateBody(String name) {
    return 'Ihre Antwort ging über den Epicbox-Server an $name. Ist deren Wallet geschlossen oder erreicht keinen, senden Sie die Antwort stattdessen im Chat.';
  }

  @override
  String get pairRelayUnreachableTitle => 'Der Server ist nicht erreichbar';

  @override
  String get pairRelayUnreachableBody => 'Antwort von Hand senden?';

  @override
  String get pairRelayUnreachableTor =>
      'Der Server ist über Tor nicht erreichbar. Antwort von Hand senden?';

  @override
  String get pairNoRelay =>
      'Kein Verbindungsserver ist erreichbar. Koppeln Sie stattdessen mit einem Einladungslink.';

  @override
  String get pairRelaysBlocked =>
      'Dieses Netzwerk blockiert die Verbindungsserver. Ursache kann ein Netzwerkfilter sein. Koppeln Sie stattdessen mit einem Einladungslink.';

  @override
  String get pairByHandTitle => 'Von Hand senden';

  @override
  String pairByHandLead(String name) {
    return 'Senden Sie dies auf beliebigem Weg an $name zurück. Deren Wallet schließt die Kopplung ab, wenn sie es öffnet.';
  }

  @override
  String get pairByHandYourAnswer => 'Ihre Antwort';

  @override
  String pairByHandFooter(String name) {
    return 'Die Antwort ist für die Einladung von $name versiegelt: Nur die Wallet von $name kann sie lesen. Sie funktioniert einmal.';
  }

  @override
  String pairConfirmByHandLead(String name) {
    return 'Senden Sie dies an $name zurück. Deren Wallet zeigt die Wortprüfung, wenn sie es öffnet.';
  }

  @override
  String get pairExpiredTitle => 'Diese Einladung ist abgelaufen';

  @override
  String pairExpiredBody(String name) {
    return 'Bitten Sie um eine neue.';
  }

  @override
  String get pairUsedTitle => 'Diese Einladung wurde schon benutzt';

  @override
  String get pairUsedBody => 'Bitten Sie um eine neue.';

  @override
  String pairCancelledTitle(String name) {
    return '$name hat diese Kopplung abgebrochen';
  }

  @override
  String get pairCancelledBody => 'Es wurde nichts gespeichert.';

  @override
  String pairNoAnswerTitle(String name) {
    return 'Keine Antwort von $name';
  }

  @override
  String get pairNoAnswerBody =>
      'Die Einladung wurde vielleicht zurückgezogen. Bitten Sie um eine neue oder koppeln Sie persönlich.';

  @override
  String pairWaitingFinish(String name) {
    return 'Warten, bis $name die Kopplung abschließt…';
  }

  @override
  String get pairNotCompletedTitle => 'Nicht abgeschlossen';

  @override
  String pairNotCompletedBody(String name) {
    return 'Die Wallet von $name hat die Kopplung nicht rechtzeitig abgeschlossen. Es wurde nichts gespeichert. Versuchen Sie es erneut.';
  }

  @override
  String get pairLateCheck => 'Suche nach einer späten Antwort…';

  @override
  String get noticeEventsMissed =>
      'Einige Updates wurden verpasst. Die Listen wurden neu geladen.';

  @override
  String get msgChecking => 'Nachrichten werden geprüft';

  @override
  String get msgCheckFailed =>
      'Die letzte Nachrichtenprüfung ist fehlgeschlagen';

  @override
  String get msgCheckedJustNow => 'Gerade eben geprüft';

  @override
  String msgCheckedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Min. geprüft',
      one: 'Vor $count Min. geprüft',
    );
    return '$_temp0';
  }

  @override
  String msgCheckedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Std. geprüft',
      one: 'Vor $count Std. geprüft',
    );
    return '$_temp0';
  }

  @override
  String msgCheckedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen geprüft',
      one: 'Vor $count Tag geprüft',
    );
    return '$_temp0';
  }

  @override
  String msgCheckSumRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gelesen',
      one: '$count gelesen',
    );
    return '$_temp0';
  }

  @override
  String msgCheckSumWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warten',
      one: '$count wartet',
    );
    return '$_temp0';
  }

  @override
  String get msgCheckSumMore => 'weitere warten';

  @override
  String msgCheckSumProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zu prüfen',
      one: '$count zu prüfen',
    );
    return '$_temp0';
  }

  @override
  String get msgCheckShowDetails => 'Details anzeigen';

  @override
  String get msgCheckHideDetails => 'Details ausblenden';

  @override
  String get msgCheckGroupRead => 'Gelesen';

  @override
  String get msgCheckGroupWaiting => 'Wartend';

  @override
  String get msgCheckGroupProblems => 'Bitte ansehen';

  @override
  String msgCheckItemRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten gelesen',
      one: '$count Nachricht gelesen',
    );
    return '$_temp0';
  }

  @override
  String msgCheckItemHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten bleiben für die nächste Prüfung',
      one: '$count Nachricht bleibt für die nächste Prüfung',
    );
    return '$_temp0';
  }

  @override
  String get msgCheckItemMore =>
      'Weitere Nachrichten warten auf die nächste Prüfung';

  @override
  String msgCheckItemRefused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten abgewiesen',
      one: '$count Nachricht abgewiesen',
    );
    return '$_temp0';
  }

  @override
  String get msgCheckWhyRefused =>
      'Nicht für diese Wallet, zu groß oder beschädigt.';

  @override
  String msgCheckItemPairingFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kopplungen nicht abgeschlossen',
      one: '$count Kopplung nicht abgeschlossen',
    );
    return '$_temp0';
  }

  @override
  String msgCheckItemUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten konnten nicht gelesen werden',
      one: '$count Nachricht konnte nicht gelesen werden',
    );
    return '$_temp0';
  }

  @override
  String get msgCheckWhyUnreadable => 'Auf diesem Gerät aufbewahrt.';

  @override
  String noticeSealedUnopenable(String name) {
    return 'Eine Nachricht von $name konnte nicht geöffnet werden.';
  }

  @override
  String noticeUnpaired(String name) {
    return '$name hat die Kopplung entfernt.';
  }

  @override
  String trustRemovedBy(String name) {
    return 'Von $name entfernt';
  }

  @override
  String get trustRemovedShort => 'Entfernt';

  @override
  String get pairChangedTitle => 'Diese Einladung wurde unterwegs verändert';

  @override
  String pairChangedBody(String name) {
    return 'Es wurde nichts gespeichert. Koppeln Sie erneut, persönlich oder mit einer neuen Einladung von $name.';
  }

  @override
  String get pairNewerTitle => 'Aktualisieren Sie BT Wallet, um dies zu öffnen';

  @override
  String get pairNewerInviteBody =>
      'Diese Einladung stammt von einer neueren Wallet.';

  @override
  String get pairNewerFileBody =>
      'Die Datei wurde von einer neueren Wallet versiegelt.';

  @override
  String get pairCheckForUpdates => 'Nach Updates suchen';

  @override
  String pairSecondReplyTitle(String name) {
    return 'Jemand anderes hat Ihre Einladung ebenfalls beantwortet';
  }

  @override
  String get pairAnsweredSameInvite =>
      'Hat dieselbe Einladung beantwortet · nicht gespeichert';

  @override
  String get sasTitle => 'Wörter prüfen';

  @override
  String sasLead(String name) {
    return 'Die Wallet von $name zeigt dieselben vier. Vergleicht sie.';
  }

  @override
  String sasLeadExchange(String name) {
    return 'Die Seite von $name zeigt dieselben vier. Vergleichen Sie sie und bestätigen Sie dann auf beiden Seiten.';
  }

  @override
  String sasLeadRecheck(String name) {
    return 'Die Wallet von $name zeigt diese unter $name › Wörter prüfen. Vergleichen Sie sie am Telefon oder persönlich.';
  }

  @override
  String get sasMatch => 'Sie stimmen überein';

  @override
  String get sasNoMatch => 'Sie stimmen nicht überein';

  @override
  String get sasSkip => 'Vorerst überspringen';

  @override
  String get sasLater => 'Später';

  @override
  String sasMatchedTitle(String name) {
    return '$name ist verifiziert';
  }

  @override
  String sasMatchedBody(String name) {
    return 'Transaktionsdateien mit $name sind ab jetzt versiegelt.';
  }

  @override
  String get sasNoMatchTitle => 'Die Wörter stimmen nicht überein';

  @override
  String get sasNoMatchBody =>
      'Die Kopplung endet auf beiden Seiten, und nichts, was hindurch gesendet wurde, wird abgeschlossen. Koppeln Sie erneut mit einer frischen Einladung.';

  @override
  String get sasStopPairing => 'Kopplung abbrechen';

  @override
  String sasSkippedTitle(String name) {
    return 'Mit $name gekoppelt';
  }

  @override
  String sasSkippedBody(String name) {
    return 'Transaktionsdateien mit $name sind versiegelt. Prüfen Sie die Wörter auf der Kontaktseite von $name, sobald es geht; Rechnungen warten bis dahin.';
  }

  @override
  String get sasCheckNow => 'Jetzt prüfen';

  @override
  String sasAllowInvoicesHint(String name) {
    return 'Die Wallet von $name kann Sie um Zahlung bitten. Ohne Ihre PIN wird nichts bezahlt.';
  }

  @override
  String get trustVerified => 'Verifiziert';

  @override
  String get trustPaired => 'Gekoppelt, nicht verifiziert';

  @override
  String get trustPairedShort => 'Gekoppelt';

  @override
  String get trustKeysChanged => 'Schlüssel geändert';

  @override
  String get trustSealed => 'Versiegelt';

  @override
  String trustSealedFor(String name) {
    return 'Versiegelt für $name';
  }

  @override
  String get trustAllowsInvoices => 'Rechnungen erlaubt';

  @override
  String get contactTitle => 'Kontakt';

  @override
  String get contactAddresses => 'Adressen';

  @override
  String get contactPairing => 'Kopplung';

  @override
  String contactWordsChecked(String date) {
    return 'Verifiziert am $date';
  }

  @override
  String get contactCheckAgain => 'Erneut prüfen';

  @override
  String get contactCheckWordsAgain => 'Erneut verifizieren';

  @override
  String get contactSealPayments => 'Transaktionsdateien versiegeln';

  @override
  String contactSealTip(String name) {
    return 'Transaktionsdateien an $name sind versiegelt, sodass nur die Wallet von $name sie lesen kann. Schalten Sie dies nur aus, wenn die Wallet von $name keine versiegelten Dateien öffnen kann.';
  }

  @override
  String get contactAllowInvoices => 'Rechnungen erlauben';

  @override
  String contactAllowInfoDesktop(String name) {
    return 'Die Wallet von $name kann Ihnen Rechnungen senden. Jede wartet unter Rechnungen auf Ihre Zustimmung und das Wallet-Passwort. Nichts wird von selbst bezahlt.';
  }

  @override
  String contactAllowInfo(String name) {
    return 'Die Wallet von $name kann Ihnen Rechnungen senden. Jede wartet unter Rechnungen auf Ihre Zustimmung und PIN. Nichts wird von selbst bezahlt.';
  }

  @override
  String get contactAllowInfoMore =>
      'Nur ein verifizierter Kontakt kann erlaubt werden: Die Verifizierung schließt eine vertauschte Einladung aus.';

  @override
  String get contactCheckWordsFirst => 'Zuerst verifizieren';

  @override
  String get contactPausedUntilChecked => 'Pausiert, bis verifiziert';

  @override
  String contactDeliveredVia(String relay) {
    return 'Zugestellt über $relay';
  }

  @override
  String get contactDomain => 'Domain';

  @override
  String get contactDomainVerified => 'verifiziert';

  @override
  String get contactDomainNotVerified => 'noch nicht verifiziert';

  @override
  String get contactDomainRefused => 'abgelehnt';

  @override
  String relayMoveTitle(String name) {
    return '$name ist zu einem neuen Relay gewechselt';
  }

  @override
  String relayMoveBody(String name, String relay) {
    return '$name bittet Sie, ab jetzt über $relay zu senden. Wenn Sie ablehnen, ändert sich nichts und $name erfährt es nicht.';
  }

  @override
  String relayMoveAddsServer(String relay) {
    return 'Annehmen fügt $relay auch zu Ihren Epicbox-Servern hinzu.';
  }

  @override
  String get relayMoveAccept => 'Annehmen';

  @override
  String get relayMoveRefuse => 'Ablehnen';

  @override
  String contactMoveAsked(String relay) {
    return 'Bittet um Wechsel zu $relay';
  }

  @override
  String contactMoveRefused(String relay) {
    return 'Sie haben den Wechsel zu $relay abgelehnt.';
  }

  @override
  String contactMoveNotPublic(String relay) {
    return 'Bat um Wechsel zu $relay. Nicht übernommen: kein öffentliches Relay.';
  }

  @override
  String contactMovedOn(String date) {
    return 'Hierher gewechselt am $date';
  }

  @override
  String contactRelayDownTitle(String name) {
    return 'Der Server von $name antwortet nicht';
  }

  @override
  String get contactRelayDownBody =>
      'Wird erneut versucht. Rechnungen und Zahlungen warten, bis es antwortet.';

  @override
  String get contactPausedEpicboxOff => 'Pausiert, solange Epicbox aus ist';

  @override
  String get contactPausedEpicboxOffBody =>
      'Versiegelte Dateien funktionieren weiter.';

  @override
  String get contactRemovePairing => 'Kopplung entfernen';

  @override
  String contactRemovePairingTitle(String name) {
    return 'Kopplung mit $name entfernen?';
  }

  @override
  String contactRemovePairingBody(String name) {
    return 'Versiegelte Zahlungen und Rechnungen von $name enden. Die Adressen bleiben in Ihren Kontakten.';
  }

  @override
  String get contactKeep => 'Behalten';

  @override
  String get contactRemove => 'Entfernen';

  @override
  String contactKeysChangedTitle(String name) {
    return 'Die Schlüssel von $name haben sich geändert';
  }

  @override
  String get contactKeysChangedBody =>
      'Das kann bedeuten, dass die Person jetzt eine andere Wallet nutzt oder dass jemand anderes ihren Namen verwendet. Verifizieren Sie den Kontakt erneut.';

  @override
  String get contactKeysChangedStatus => 'Versiegeln und Rechnungen pausiert';

  @override
  String get contactKeysChangedPaused => 'Versiegeln und Rechnungen pausiert';

  @override
  String get contactKeepOldKeys => 'Alte Schlüssel behalten';

  @override
  String get contactUseNewKeys => 'Neue Schlüssel verwenden';

  @override
  String contactKeysBack(String name) {
    return 'Die Schlüssel von $name sind zurück.';
  }

  @override
  String get contactKeysBackBody => 'Für Sie hat sich nichts geändert.';

  @override
  String contactSealDegradedTitle(String name) {
    return 'Die letzte Transaktionsdatei an $name ging unversiegelt';
  }

  @override
  String contactSealDegradedBody(String name) {
    return 'Die nächste fragt: versiegelt oder unversiegelt. Das Versiegeln schaltet sich wieder ein, wenn die Wallet von $name versiegelt antwortet.';
  }

  @override
  String get addrField => 'Adresse';

  @override
  String addrFieldTyped(String type) {
    return 'Adresse ($type)';
  }

  @override
  String get addrAddAnother => 'Weitere Adresse hinzufügen';

  @override
  String addrOneFree(String type) {
    return 'Eine Art ist noch frei: $type.';
  }

  @override
  String addrDuplicateType(String name, String type) {
    return '$name hat bereits eine Adresse dieser Art ($type).';
  }

  @override
  String get addrKeepOld => 'Die alte behalten';

  @override
  String get addrReplace => 'Ersetzen';

  @override
  String addrDesktopThird(String type) {
    return 'Eine Adresse ($type) einfügen oder leer lassen';
  }

  @override
  String get pendingTitle => 'Offene Einladungen';

  @override
  String pendingRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einladungen warten auf Antwort',
      one: '1 Einladung wartet auf Antwort',
    );
    return '$_temp0';
  }

  @override
  String pendingLink(String time) {
    return 'Link · läuft ab in $time';
  }

  @override
  String pendingWords(String time) {
    return 'Gesprochene Einladung · läuft ab in $time';
  }

  @override
  String get pendingExpired => 'Abgelaufen';

  @override
  String get pendingInviteAgain => 'Erneut einladen';

  @override
  String get pendingWaitingConfirm => 'Wartet auf Bestätigung';

  @override
  String get pendingPairedCheck => 'Gekoppelt · verifizieren';

  @override
  String get pendingEmpty =>
      'Keine Einladungen offen. Eine Einladung steht hier, bis die andere Wallet sie beantwortet.';

  @override
  String get pendingShareAgain => 'Erneut teilen';

  @override
  String get pendingShowWords => 'Einladung zeigen';

  @override
  String get invSetTitle => 'Rechnungen';

  @override
  String get invSetLead =>
      'Ein gekoppelter Kontakt, den Sie erlauben, kann Ihnen Rechnungen senden. Jede wartet unter Rechnungen auf Ihre PIN.';

  @override
  String get invSetPaired => 'Gekoppelte Kontakte';

  @override
  String get invSetAllowed => 'Erlaubt';

  @override
  String get invSetOff => 'Aus';

  @override
  String get invSetPairShop => 'Mit einem Shop oder einer Börse koppeln';

  @override
  String get invSetEmpty =>
      'Noch keine gekoppelten Kontakte. Koppeln Sie mit einem Shop, einer Börse oder einer Person, verifizieren Sie und erlauben Sie dann hier deren Rechnungen.';

  @override
  String get invSetPausedBody =>
      'Rechnungen warten auf dem Server und kommen an, sobald Epicbox wieder an ist.';

  @override
  String invSetSwitchedOff(String name) {
    return 'Rechnungen von $name sind aus.';
  }

  @override
  String invSetDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offene Rechnungen wurden abgelehnt.',
      one: '1 offene Rechnung wurde abgelehnt.',
    );
    return '$_temp0';
  }

  @override
  String get invSetTimeToPay => 'Zeit zum Bezahlen';

  @override
  String invSetTimeToPayHint(int hours) {
    return '$hours Stunden · so lange ist eine Rechnung bezahlbar';
  }

  @override
  String get invoicesEmptyAction => 'Gekoppelte Kontakte';

  @override
  String get reqTitle => 'Rechnung prüfen';

  @override
  String reqRequests(String name) {
    return '$name fordert an';
  }

  @override
  String reqSealedSigned(String name) {
    return 'Für diese Wallet versiegelt und von $name signiert';
  }

  @override
  String get reqReference => 'Referenz';

  @override
  String reqPaidWaiting(String name) {
    return 'Bezahlt. Warten, bis $name veröffentlicht';
  }

  @override
  String get reqPaidWaitingBodyPerson =>
      'Ihr Teil ist erledigt. Die Wallet der anderen Seite schließt ab und veröffentlicht; dies erledigt sich von selbst.';

  @override
  String get reqPaidWaitingBody =>
      'Ihr Teil ist erledigt. Die Gegenseite schließt ab und veröffentlicht; dies erledigt sich von selbst.';

  @override
  String get reqTlPaid => 'Bezahlt';

  @override
  String get reqTlDelivered => 'Über Epicbox zugestellt';

  @override
  String get reqTlAnswerDelivered => 'Antwort über Epicbox zugestellt';

  @override
  String reqTlPosted(String name) {
    return 'Von $name veröffentlicht';
  }

  @override
  String get reqTlConfirming => 'Wird bestätigt';

  @override
  String reqTlConfirmingHint(int n, int total) {
    return '$n von $total Bestätigungen';
  }

  @override
  String get reqTlConfirmed => 'Bestätigt';

  @override
  String reqNotPostedTitle(String name) {
    return '$name hat noch nicht veröffentlicht';
  }

  @override
  String get reqNotPostedBody =>
      'Erneut senden stellt dieselbe Zahlung noch einmal zu. Sie kann nicht doppelt bezahlt werden.';

  @override
  String get reqSendAgain => 'Erneut senden';

  @override
  String reqUnreachableTitle(String name) {
    return '$name ist noch nicht erreichbar';
  }

  @override
  String get reqUnreachableBody =>
      'Das Geld wird freigegeben, wenn nicht veröffentlicht wird. Die Zustellung wird weiter versucht.';

  @override
  String get reqRelayRetrying => 'Server antwortet nicht · neuer Versuch';

  @override
  String reqWithdrewTitle(String name) {
    return '$name hat die Rechnung zurückgezogen';
  }

  @override
  String get reqWithdrewBody =>
      'Ihr Geld ist freigegeben. Es wurde nichts bezahlt.';

  @override
  String reqTwoSame(String name, int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name hat innerhalb von 10 Minuten $count Rechnungen über $amount EPIC gesendet. Alle bezahlen?',
      one:
          '$name hat innerhalb von 10 Minuten 1 Rechnung über $amount EPIC gesendet. Bezahlen?',
    );
    return '$_temp0';
  }

  @override
  String reqWithdrawalFrom(String name) {
    return 'Auszahlung von $name';
  }

  @override
  String reqReceivedWaiting(String name) {
    return 'Empfangen. Warten, bis $name veröffentlicht';
  }

  @override
  String get reqReceivedWaitingBody =>
      'Nichts zu tun. Der Absender veröffentlicht; die Bestätigungen folgen.';

  @override
  String get reqNewTitle => 'Neue Rechnung';

  @override
  String get reqNewLead =>
      'Bitten Sie einen gekoppelten Kontakt um Zahlung oder speichern Sie die Rechnung als Datei für jede beliebige Person.';

  @override
  String get reqNewLeadContacts =>
      'Bitten Sie einen gekoppelten Kontakt um Zahlung.';

  @override
  String get reqNewTo => 'An';

  @override
  String get reqNewToHintContacts =>
      'Gekoppelte Kontakte, deren Wallet Rechnungen bezahlt.';

  @override
  String get reqNoPayersContacts =>
      'Noch kein gekoppelter Kontakt bezahlt Rechnungen. Koppeln und verifizieren Sie.';

  @override
  String get reqNewToHint =>
      'Gekoppelte Kontakte, deren Wallet Rechnungen bezahlt. Alle anderen: Rechnung als Datei speichern.';

  @override
  String get reqNewSend => 'Rechnung senden';

  @override
  String get sendRoutePaired => 'Gekoppelte Adresse';

  @override
  String get sendRoutePublic => 'Öffentliche Adresse';

  @override
  String get sendRoutePairedInline => 'gekoppelte Adresse';

  @override
  String sendRoutePairedLine(String relay) {
    return 'Beim Koppeln erstellt. Zugestellt über $relay.';
  }

  @override
  String sendRoutePairedMovedLine(String relay, String date) {
    return 'Beim Koppeln erstellt. Zugestellt über $relay, hierher gewechselt am $date.';
  }

  @override
  String sendRoutePublicLine(String name) {
    return 'Die öffentliche Epicbox-Adresse von $name.';
  }

  @override
  String sendRouteReasonOtherApp(String name) {
    return 'Gewählt, weil die letzte Zahlung von $name von einer anderen Wallet-App beantwortet wurde.';
  }

  @override
  String sendRouteReasonNotHeard(String name, String date) {
    return 'Gewählt, weil seit $date nichts von der Wallet von $name gehört wurde.';
  }

  @override
  String sendRouteReasonUnanswered(String name, String route, String date) {
    return 'Gewählt, weil die Wallet von $name seit $date nicht über die $route geantwortet hat.';
  }

  @override
  String sendRouteReasonNotAnswering(String name, String route) {
    return 'Gewählt, weil die Wallet von $name über die $route nicht antwortet.';
  }

  @override
  String sendRouteReasonRelayDown(String relay, String route) {
    return 'Gewählt, weil $relay, der Epicbox-Server für die $route, nicht antwortet.';
  }

  @override
  String sendRouteServerDown(String relay) {
    return '$relay antwortet nicht. Beide Adressen nutzen diesen Epicbox-Server.';
  }

  @override
  String get sendPublicFallback =>
      'An die öffentliche Epicbox-Adresse des Kontakts senden';

  @override
  String sendSealedTitle(String name) {
    return 'Versiegelt für $name';
  }

  @override
  String sendSealedBody(String name) {
    return 'Nur die Wallet von $name kann diese Datei öffnen. Senden Sie sie auf beliebigem Weg und öffnen Sie dann die Datei, die zurückkommt.';
  }

  @override
  String get sendSealOrPlainTitle => 'Diese Datei versiegeln?';

  @override
  String sendSealOrPlainBody(String name) {
    return 'Die letzte Datei an $name ging unversiegelt. Versiegelt ist wieder die Vorgabe.';
  }

  @override
  String get sendSealedOption => 'Versiegelt';

  @override
  String sendSealedOptionHint(String name) {
    return 'Nur die Wallet von $name kann sie lesen';
  }

  @override
  String get sendPlainOption => 'Unversiegelt';

  @override
  String get sendPlainOptionHint => 'Wer die Datei hat, kann sie lesen';

  @override
  String sendCantOpenTitle(String name) {
    return '$name kann keine versiegelten Dateien öffnen?';
  }

  @override
  String get sendCantOpenBody =>
      'Unversiegelt senden schickt dieselbe Zahlung noch einmal ohne Siegel. Es bleibt eine einzige Zahlung.';

  @override
  String get sendAsPlain => 'Stattdessen unversiegelt senden';

  @override
  String get sendAsPlainTitle => 'Stattdessen unversiegelt senden?';

  @override
  String get sendAsPlainBody =>
      'Die Datei wird nicht versiegelt: Wer sie bekommt, kann den Betrag und die Adressen darin lesen. Es ist dieselbe Zahlung, sie kann also nicht doppelt bezahlt werden.';

  @override
  String get sendKeepSealed => 'Versiegelt lassen';

  @override
  String get sendPlain => 'Unversiegelt senden';

  @override
  String sendNotHeardTitle(String name) {
    return 'Seit 90 Tagen nichts von der Wallet von $name';
  }

  @override
  String sendNotHeardBody(String name) {
    return '$name braucht Epic Cash, um diese Datei zu öffnen.';
  }

  @override
  String get sendPlainShort => 'Unversiegelt senden';

  @override
  String get openSealedOtherTitle =>
      'Dies wurde für eine andere Wallet oder Installation versiegelt';

  @override
  String get openSealedOtherBody =>
      'Es lässt sich hier nicht öffnen. Bitten Sie um erneutes Senden.';

  @override
  String get openArrivedUnsealed => 'Dies kam unversiegelt an.';

  @override
  String openArrivedUnsealedBody(String name) {
    return '$name hat diese Datei unversiegelt gesendet.';
  }

  @override
  String noticePairingReplied(String name) {
    return '$name hat geantwortet. Gemeinsam verifizieren.';
  }

  @override
  String noticePairingConfirmed(String name) {
    return 'Mit $name gekoppelt. Verifizieren Sie gemeinsam.';
  }

  @override
  String noticeRequest(String name, String amount) {
    return '$name fordert $amount EPIC an.';
  }

  @override
  String noticeWithdrawal(String amount, String name) {
    return '$amount EPIC von $name empfangen.';
  }

  @override
  String noticeKeysChanged(String name) {
    return 'Die Schlüssel von $name haben sich geändert. Erneut verifizieren.';
  }

  @override
  String noticeKeyCheckRefused(String name) {
    return '$name ist mit neuen Schlüsseln gekoppelt. Die alten Schlüssel ließen sich nicht prüfen: Es gibt eine Prüfung pro Tag, und sie lief schon.';
  }

  @override
  String noticeRelayDown(String name) {
    return 'Der Epicbox-Server von $name antwortet nicht.';
  }

  @override
  String noticeWithdrew(String name) {
    return '$name hat die Rechnung zurückgezogen. Geld freigegeben.';
  }

  @override
  String get restoreUseContactsTitle =>
      'Ihre Kontakte auf diesem Gerät verwenden?';

  @override
  String restoreUseContactsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Kopplungen in dieser Datei wurden auf einem anderen Gerät verwendet. Ihr anderes Gerät sollte sie nicht mehr verwenden.',
      one: '1 Kopplung in dieser Datei wurde auf einem anderen Gerät verwendet. Ihr anderes Gerät sollte sie nicht mehr verwenden.',
    );
    return '$_temp0';
  }

  @override
  String get restoreUseHere => 'Hier verwenden';

  @override
  String get pairInvalidLink => 'Keine Kopplungs-Einladung.';

  @override
  String get pairInvalidBody =>
      'Prüfen Sie, ob die ganze Einladung kopiert wurde, oder bitten Sie um eine neue.';

  @override
  String get pairWrongNetworkBody =>
      'Diese Einladung ist für ein anderes Netzwerk.';

  @override
  String get pairOwnCode => 'Das ist Ihr eigener Code';

  @override
  String get pairOwnCodeBody => 'Scannen Sie den Code auf dem anderen Telefon.';

  @override
  String get pairUnnamedInvite => 'Offene Einladung';

  @override
  String get pairSeenAsTooLong => 'Verwenden Sie einen kürzeren Namen.';

  @override
  String get pairSeenAsEdit => 'Den angezeigten Namen ändern';

  @override
  String get pairCodeLabel => 'Ihr Kopplungscode';

  @override
  String get pairWordsLabel => 'Ihre Kopplungswörter';

  @override
  String get pairWordsEnteredLabel => 'Eingegebene Wörter';

  @override
  String pairWordSlot(int n) {
    return 'Wort $n, nicht eingegeben';
  }

  @override
  String get pairSuggestions => 'Vorschläge';

  @override
  String get pairCopied => 'Kopiert';

  @override
  String get pairPaste => 'Einfügen';

  @override
  String get pairInPersonDone => 'Codes gescannt';

  @override
  String get pairEpicboxOffNotice =>
      'Pausiert, solange Epicbox aus ist. Einladung und Antwort gehen von Hand.';

  @override
  String get pairWaitingTitleShort => 'Kopplung';

  @override
  String get pairClosed => 'Schließen';

  @override
  String get sasWordsLabel => 'Die vier Wörter';

  @override
  String sasDialogTitle(String name) {
    return 'Wörter prüfen mit $name';
  }

  @override
  String get contactMore => 'Mehr';

  @override
  String get contactEdit => 'Bearbeiten';

  @override
  String get contactDelete => 'Kontakt löschen';

  @override
  String contactCopyAddress(String type) {
    return 'Adresse ($type) kopieren';
  }

  @override
  String contactDeletePaired(String name) {
    return 'Das Löschen von $name entfernt auch die Kopplung. Versiegelte Zahlungen und Rechnungen von diesem Kontakt enden.';
  }

  @override
  String get contactNoAddresses => 'Keine Adressen gespeichert.';

  @override
  String addrRemove(String type) {
    return 'Adresse ($type) entfernen';
  }

  @override
  String get sendVia => 'Senden über';

  @override
  String get invSetLeadDesktop =>
      'Ein gekoppelter Kontakt, den Sie erlauben, kann dieser Wallet Rechnungen senden. Jede wartet unter Rechnungen auf das Wallet-Passwort.';

  @override
  String get invSetRowAllowed => 'Verifiziert · erlaubt';

  @override
  String get invSetRowOff => 'Verifiziert · aus';

  @override
  String get invSetRowCheckFirst =>
      'Gekoppelt, nicht verifiziert · zuerst verifizieren';

  @override
  String invSetAllowFor(String name) {
    return 'Rechnungen von $name erlauben';
  }

  @override
  String get reqNoPayers =>
      'Noch kein gekoppelter Kontakt bezahlt Rechnungen. Koppeln und verifizieren Sie, oder speichern Sie die Rechnung als Datei.';

  @override
  String get reqPickContact => 'Kontakt wählen';

  @override
  String get reqFileSaved => 'Rechnung als Datei gespeichert';

  @override
  String reqSent(String name) {
    return 'Rechnung an $name gesendet';
  }

  @override
  String get reqFileTitle => 'Rechnung';

  @override
  String noticeOutboxStuck(String name) {
    return '$name ist noch nicht erreichbar. Wird erneut versucht.';
  }

  @override
  String noticeTooMany(String name) {
    return '$name hat zu viele Rechnungen gesendet.';
  }

  @override
  String get noticeOpen => 'Öffnen';

  @override
  String get noticeCheckWords => 'Verifizieren';

  @override
  String get noticeView => 'Ansehen';

  @override
  String noticeDigestInvoices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rechnungen',
      one: '$count Rechnung',
    );
    return '$_temp0';
  }

  @override
  String noticeDigestWithdrawals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Auszahlungen',
      one: '$count Auszahlung',
    );
    return '$_temp0';
  }

  @override
  String noticeDigestPaid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rechnungen bezahlt',
      one: '$count Rechnung bezahlt',
    );
    return '$_temp0';
  }

  @override
  String noticeDigestWithdrawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rechnungen zurückgezogen',
      one: '$count Rechnung zurückgezogen',
    );
    return '$_temp0';
  }

  @override
  String noticeDigestExpired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rechnungen abgelaufen',
      one: '$count Rechnung abgelaufen',
    );
    return '$_temp0';
  }

  @override
  String noticeDigestNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Aktualisierungen',
      one: '$count neue Aktualisierung',
    );
    return '$_temp0';
  }

  @override
  String pairSaveContactTitle(String name) {
    return '$name in Ihren Kontakten speichern?';
  }

  @override
  String get pairSaveNewContact => 'Als neuen Kontakt speichern';

  @override
  String pairOtherAddressTitle(String name) {
    return 'Nicht zu $name hinzugefügt';
  }

  @override
  String pairOtherAddressBody(String name) {
    return '$name hat eine Epicbox-Adresse, die diese Kopplung nicht bestätigen kann.';
  }

  @override
  String get pairOtherAddress =>
      'Dieser Kontakt hat eine Epicbox-Adresse, die diese Kopplung nicht bestätigen kann.';

  @override
  String pairAddToNamed(String name) {
    return 'Zu $name hinzufügen';
  }

  @override
  String get pairAddToAContact => 'Zu einem Kontakt hinzufügen';

  @override
  String pairSavedAs(String name) {
    return 'Als $name gespeichert.';
  }

  @override
  String pairDurDays(int days, int hours) {
    return '$days T $hours Std.';
  }

  @override
  String pairDurHours(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String pairDurMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get pairDurUnderMinute => 'unter einer Minute';

  @override
  String get pairBack => 'Zurück';

  @override
  String get pairNotInContacts => 'Nicht in den Kontakten';

  @override
  String get helpPairingSection => 'Kopplung';

  @override
  String get helpPairingLede =>
      'Einmal koppeln; Zahlungen, Transaktionsdateien und Rechnungen mit diesem Kontakt sind versiegelt.';

  @override
  String get helpPairWhatTitle => 'Was Kopplung ist';

  @override
  String get helpPairWhatShort =>
      'Koppeln Sie einmal mit jemandem; danach sind Zahlungen, Transaktionsdateien und Rechnungen zwischen den beiden Wallets versiegelt.';

  @override
  String get helpPairWhatP1 =>
      'Koppeln verbindet zwei Wallets einmal: mit einer Anfrage an einen Kontakt, dem Sie über Epicbox gezahlt haben, oder mit Ihrer Einladung, als QR gescannt oder als Link geöffnet. Jede Wallet behält einen Schlüssel nur für diesen einen Kontakt; mit niemandem sonst wird etwas geteilt.';

  @override
  String get helpPairWhatP2 =>
      'Nach dem Koppeln sind Zahlungen, Transaktionsdateien und Rechnungen zwischen den beiden Wallets **versiegelt**: Nur die andere Wallet kann sie lesen, und die Identität des Kontakts wird geprüft. Zahlungen an einen gekoppelten Kontakt werden standardmäßig versiegelt; siehe „Zahlungen nach dem Koppeln“.';

  @override
  String get helpPairWhatStep1 =>
      'Öffnen Sie [[Kontakte|Contacts]] und wählen Sie **Koppeln**.';

  @override
  String get helpPairWhatStep2 =>
      'Koppeln Sie mit einem Kontakt, oder zeigen Sie Ihre Einladung und lassen Sie sie scannen.';

  @override
  String get helpPairWhatStep3 =>
      'Prüft die Wörter gemeinsam (nach einer Anfrage nicht nötig), dann **Sie stimmen überein**.';

  @override
  String get helpPairWhatP3 =>
      'Kopplung braucht BT Wallet auf beiden Seiten. Ein nicht gekoppelter Kontakt bekommt weiterhin gewöhnliche Transaktionsdateien und Zahlungen an seine öffentliche Epicbox-Adresse.';

  @override
  String get helpPairWhyTitle => 'Warum verifizieren';

  @override
  String get helpPairWhyShort =>
      'Die Verifizierung zeigt, dass die Kopplung die richtige Wallet erreicht hat und niemand dazwischen sitzt.';

  @override
  String get helpPairWhyP1 =>
      'Nach dem Koppeln zeigen beide Wallets dieselben vier Bilder mit Namen. Sie entstehen aus den Schlüsseln der beiden Wallets, daher zeigt eine unterwegs veränderte Kopplung auf den beiden Bildschirmen verschiedene Wörter.';

  @override
  String get helpPairWhyP2 =>
      'Vergleichen Sie sie am Telefon oder persönlich und tippen Sie dann **Sie stimmen überein**. Der Kontakt wird **Verifiziert**. **Vorerst überspringen** lässt ihn bei **Gekoppelt, nicht verifiziert**: Transaktionsdateien sind trotzdem versiegelt, aber der Kontakt kann erst Rechnungen senden, wenn die Wörter geprüft sind.';

  @override
  String get helpPairWhyP3 =>
      'Wenn die Wörter abweichen, tippen Sie **Sie stimmen nicht überein**. Die Kopplung wird auf dieser Seite verworfen. Koppeln Sie erneut, persönlich oder mit einer neuen Einladung.';

  @override
  String get helpPairWhyP4 =>
      'Die Namen der Wörter bleiben in jeder Sprache englisch, damit zwei Personen, deren Wallets verschiedene Sprachen nutzen, sie trotzdem vergleichen können.';

  @override
  String get helpPairWordsTitle => 'Gesprochene Einladungen';

  @override
  String get helpPairWordsShort =>
      'Fünf Bilder mit Namen ersetzen einen Link, wenn es nichts zu scannen oder einzufügen gibt.';

  @override
  String get helpPairWordsP1 =>
      'Wenn eine Wallet keine Kamera hat oder sich die Einladung nicht als Link senden lässt, zeigt die einladende Wallet fünf Kopplungswörter. Die andere Person tippt die Namen unter **Wörter oder Link erhalten?**; das Feld ergänzt jeden Namen nach wenigen Buchstaben. Die Wörter sind 10 Minuten gültig.';

  @override
  String get helpPairWordsP2 =>
      'Die Wörter finden nur die Einladung. Wer sie hat, ist in derselben Lage wie jemand, der den Link bekommen hat; prüfen Sie danach also wie immer gemeinsam die vier Wörter.';

  @override
  String get helpPairWordsP3 =>
      'Gesprochene Einladungen brauchen Epicbox. Solange Epicbox aus ist, senden Sie stattdessen den Einladungslink.';

  @override
  String get helpPairInvTitle => 'Rechnungen von gekoppelten Kontakten';

  @override
  String get helpPairInvShortDesktop =>
      'Nur ein verifizierter Kontakt, den Sie erlauben, kann Sie um Zahlung bitten. Jede Rechnung wartet auf das Wallet-Passwort.';

  @override
  String get helpPairInvShort =>
      'Nur ein verifizierter Kontakt, den Sie erlauben, kann Sie um Zahlung bitten. Jede Rechnung wartet auf Ihre PIN.';

  @override
  String get helpPairInvP1 =>
      'Ein Shop, eine Börse oder eine Person, mit der Sie gekoppelt sind, kann Rechnungen senden, wenn Sie es erlauben: **Rechnungen erlauben** auf der Kontaktseite oder unter [[Einstellungen › Rechnungen|Settings › Invoices]]. Der Schalter funktioniert nur für einen verifizierten Kontakt.';

  @override
  String get helpPairInvP2Desktop =>
      'Eine Rechnung steht unter [[Rechnungen › Bezahlen|Invoices › Pay]] mit dem Namen des Kontakts, dem Betrag und einer Referenz. Nichts wird bezahlt, bis Sie mit dem Wallet-Passwort zustimmen. Eine Rechnung bringt nie Geld in Ihre Wallet.';

  @override
  String get helpPairInvP2 =>
      'Eine Rechnung steht unter [[Rechnungen › Bezahlen|Invoices › Pay]] mit dem Namen des Kontakts, dem Betrag und einer Referenz. Nichts wird bezahlt, bis Sie mit Ihrer PIN zustimmen. Eine Rechnung bringt nie Geld in Ihre Wallet.';

  @override
  String get helpPairInvP3 =>
      'Das Ausschalten wirkt sofort: Neue Rechnungen dieses Kontakts werden verworfen und offene abgelehnt.';

  @override
  String get helpPairInvP4 =>
      'Eine Börse, die mit Ihnen gekoppelt ist, nutzt diesen Weg für Einzahlungen und Auszahlungen. Einzahlung: Die Börse fordert an, Sie stimmen zu, die Börse veröffentlicht. Auszahlung: Die Börse sendet die Zahlung, Ihre Wallet antwortet von selbst, die Börse veröffentlicht.';

  @override
  String get helpPairRestoreTitle => 'Was eine Wiederherstellung bewirkt';

  @override
  String get helpPairRestoreShort =>
      'Mit der Wallet-Datendatei bringt eine Wiederherstellung aus der Wiederherstellungsphrase jede Kopplung zurück; ohne sie findet erneutes Koppeln dieselben Schlüssel.';

  @override
  String get helpPairRestoreP1 =>
      'Mit der Wallet-Datendatei bringt eine Wiederherstellung jede Kopplung unverändert zurück: dieselben Schlüssel, dieselben Verifiziert-Markierungen, dieselben Einstellungen. Die Kontakte merken nichts.';

  @override
  String get helpPairRestoreP2 =>
      'Ohne die Datei sind die Kopplungen aus dieser Wallet verschwunden, die Schlüssel aber nicht: Sie entstehen aus der Wiederherstellungsphrase. Koppeln Sie erneut mit einem Kontakt, der die Kopplung behalten hat, und dessen Wallet findet dieselben Schlüssel. Sie meldet, dass die Schlüssel zurück sind, und der Kontakt behält seine Verifiziert-Markierung. In dieser Wallet starten Transaktionsdateien versiegeln und Rechnungen erlauben mit ihren Vorgaben.';

  @override
  String get helpPairRestoreP3 =>
      'Ein Kontakt sieht **Schlüssel geändert** nur, wenn die Phrase eine andere ist. Das kann eine neue Wallet bedeuten oder jemand anderen, der den Namen verwendet. Prüfen Sie die Wörter erneut, bevor Sie dem vertrauen.';

  @override
  String get helpPairRestoreP4 =>
      'Nutzen Sie eine Kopplung immer nur auf einem Gerät. Auf einem zweiten Gerät importierte Wallet-Daten fragen, bevor sie die Kontakte dort verwenden.';

  @override
  String get pairNameForCode =>
      'Geben Sie den Namen ein, den die andere Seite sieht; dann erscheint hier Ihr Code.';

  @override
  String get deskConPickForPairing =>
      'Die Kopplung kommt zu dem Kontakt, den Sie wählen.';

  @override
  String txDetailsCancelHold(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Stornieren ist in $minutes Minuten möglich, falls der Absender sie bis dahin nicht veröffentlicht hat.',
      one: 'Stornieren ist in 1 Minute möglich, falls der Absender sie bis dahin nicht veröffentlicht hat.',
    );
    return '$_temp0';
  }

  @override
  String get txDetailsCancelWhileReported =>
      'Stornieren ist nicht verfügbar, solange der Absender meldet, sie veröffentlicht zu haben.';

  @override
  String get txDetailsCancelRefusedOnNetwork =>
      'Nicht storniert: das Netzwerk hat diese Zahlung bereits. Sie wird abgeschlossen, sobald die Blockchain sie bestätigt.';

  @override
  String get contactStar => 'Favorit';

  @override
  String get contactUnstar => 'Kein Favorit';

  @override
  String get contactStarred => 'Favorit';

  @override
  String get contactsImport => 'Kontakte importieren';

  @override
  String get contactsExport => 'Kontakte exportieren';

  @override
  String contactsExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte exportiert',
      one: '$count Kontakt exportiert',
    );
    return '$_temp0';
  }

  @override
  String get contactsExportHolds =>
      'Die Datei enthält Namen, Notizen und Adressen. Keine Schlüssel und keine Kopplungen.';

  @override
  String get contactsImportTitle => 'Kontakte importieren?';

  @override
  String contactsImportNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Kontakte',
      one: '$count neuer Kontakt',
    );
    return '$_temp0';
  }

  @override
  String contactsImportMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte aktualisiert',
      one: '$count Kontakt aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String contactsImportSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bereits vorhanden',
      one: '$count bereits vorhanden',
    );
    return '$_temp0';
  }

  @override
  String contactsImportLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ausgelassen: keine Adresse, an die diese Wallet senden kann',
      one: '$count ausgelassen: keine Adresse, an die diese Wallet senden kann',
    );
    return '$_temp0';
  }

  @override
  String contactsImportOtherNet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgelassen: Adressen für ein anderes Netzwerk',
      one: '$count ausgelassen: Adresse für ein anderes Netzwerk',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportKeeps => 'Vorhandene Angaben bleiben erhalten.';

  @override
  String get contactsImportDo => 'Importieren';

  @override
  String get contactsImportNothing => 'Nichts zu importieren.';

  @override
  String contactsImported(int added, int same) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added Kontakte hinzugefügt',
      one: '$added Kontakt hinzugefügt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      same,
      locale: localeName,
      other: '$same bereits vorhanden',
      one: '$same bereits vorhanden',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String contactsImportedAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added Kontakte hinzugefügt',
      one: '$added Kontakt hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get contactsImportNotFile => 'Diese Datei ist keine Kontaktdatei.';

  @override
  String get contactsImportDamaged =>
      'Die Datei konnte nicht gelesen werden. Sie ist möglicherweise beschädigt.';

  @override
  String get contactsImportNewer =>
      'Diese Datei stammt von einer neueren Version von BT Wallet. Aktualisieren Sie, um sie zu importieren.';

  @override
  String get contactsImportEmpty => 'Die Datei enthält keine Kontakte.';

  @override
  String get contactsImportAllOtherNet =>
      'Diese Kontakte gehören zu einem anderen Netzwerk. Keiner kann hier verwendet werden.';

  @override
  String get expPairing => 'Kopplung';

  @override
  String get expPairingHint =>
      'Einmal mit jemandem koppeln, mit dem oft gezahlt wird: Transaktionsdateien und Rechnungen zwischen den beiden Wallets sind dann versiegelt, und der Kontakt erscheint als gekoppelt. Experimentell: Es kann sich noch ändern.';

  @override
  String get expPairingOffTitle => 'Kopplung ist experimentell';

  @override
  String get expPairingOffBody =>
      'Einschalten unter Einstellungen › Erweitert.';

  @override
  String get contactNoAddressPaired => 'Keine öffentliche Adresse';

  @override
  String get contactSendKeysChanged =>
      'Vor dem Senden den Kontakt verifizieren.';

  @override
  String contactSendNoSealed(String name) {
    return 'Die Wallet von $name kann versiegelte Nachrichten nicht öffnen. Nach einer Adresse fragen.';
  }

  @override
  String sendRecipientPairing(String name, String route) {
    return 'Die $route von $name';
  }

  @override
  String get sendClearRecipient => 'Empfänger entfernen';

  @override
  String get sendQueuedEpicboxOff =>
      'Epicbox ist aus. Die Zahlung wartet hier und wird gesendet, sobald Epicbox wieder an ist.';

  @override
  String get sendQueue => 'Zahlung einreihen';

  @override
  String get sendQueuedHeadline => 'Zahlung eingereiht';

  @override
  String sendQueuedBody(String name) {
    return 'Sie wird gesendet, sobald Epicbox wieder an ist. Die Antwort von $name kommt auf demselben Weg zurück.';
  }

  @override
  String txStatusWaitingFor(String name) {
    return 'Wartet auf $name';
  }

  @override
  String txStepSentMailbox(String name) {
    return 'Über den Epicbox-Server von $name gesendet';
  }

  @override
  String txStepAnswerFrom(String name) {
    return 'Antwort von $name';
  }

  @override
  String txStepCollecting(String name) {
    return 'Epicbox-Server von $name wird geprüft';
  }

  @override
  String deskTxStatusWaitingFor(String name) {
    return 'Wartet auf Signatur von $name';
  }

  @override
  String deskSendContactNoLink(String name) {
    return '$name hat keine Link-Adresse.';
  }

  @override
  String get reqToFile => 'Als Datei für jede beliebige Person speichern';

  @override
  String reqFileSummary(String amount) {
    return 'Jede Person, die die Datei öffnet, kann $amount zahlen. Die Antwort kommt als Datei zurück.';
  }

  @override
  String get reqSaveFile => 'Als Datei speichern';

  @override
  String get reqFileLead =>
      'Schicken Sie diese Datei an die Person, die zahlen soll. Deren Wallet antwortet mit einer Datei; öffnen Sie diese hier, um abzuschließen.';

  @override
  String get reqByFile => 'Per Datei';

  @override
  String get reqToAnyone => 'Jede Person mit der Datei';

  @override
  String get reqFileWaitingCard =>
      'Wartet auf die Antwortdatei. Öffnen Sie sie über Empfangen oder durch Antippen.';

  @override
  String get reqFromFileTitle => 'Rechnung aus einer Datei';

  @override
  String get reqFromFileWarn =>
      'Nichts zeigt, wer diese Rechnung erstellt hat. Zahlen Sie nur, wenn Sie sie von jemandem erwartet haben, den Sie kennen.';

  @override
  String get reqFileMessageLabel => 'Nachricht in der Datei';

  @override
  String get reqApproveSaveAnswer => 'Zustimmen und Antwort speichern';

  @override
  String get reqNotNow => 'Nicht jetzt';

  @override
  String get reqAnswerTitle => 'Antwort gespeichert';

  @override
  String get reqAnswerLead =>
      'Schicken Sie diese Datei an die Person zurück, die angefragt hat. Sie schließt die Zahlung ab und sendet sie ins Netzwerk.';

  @override
  String get reqFileAlreadyPaid => 'Diese Rechnung ist bereits bezahlt.';

  @override
  String get reqFileEnded => 'Diese Rechnung ist beendet.';

  @override
  String slateIncomingRequestAnswer(String amount) {
    return 'Die Antwort auf Ihre Rechnung über $amount.';
  }

  @override
  String get reqAnswerUnknown =>
      'Dies beantwortet eine Rechnung, die diese Wallet nicht mehr hat.';

  @override
  String get deskInvIssuerAnother => 'Weitere Rechnung';

  @override
  String get deskImpOpenAnother => 'Weitere Datei öffnen';

  @override
  String get deskInvIssuerToAnyone => 'Rechnung an jede Person mit der Datei';

  @override
  String deskOnbImportRelayTitle(String name) {
    return 'Epicbox-Server für $name';
  }

  @override
  String deskOnbImportRelayLead(String old) {
    return 'Die ältere App hat über $old empfangen.';
  }

  @override
  String deskOnbImportRelayKeep(String old) {
    return '$old behalten';
  }

  @override
  String get deskOnbImportRelayKeepHint =>
      'Gleiche Adresse; der Server kommt in die Epicbox-Liste.';

  @override
  String deskOnbImportRelayApp(String current) {
    return '$current verwenden';
  }

  @override
  String get deskOnbImportRelayAppHint =>
      'Neue Adresse: Zahlungen an die alte kommen nicht an.';

  @override
  String get deskOnbImportUnlockOld => 'Entsperren mit dem alten Passwort.';

  @override
  String get deskOnbImportUnlockNew =>
      'Entsperren mit dem hier gewählten neuen Passwort.';

  @override
  String get deskOnbWelcomeOtherApps =>
      'Aus Stack Wallet oder Epic Pay: mit der Wiederherstellungsphrase wiederherstellen.';

  @override
  String get deskOnbImportCloseFirstWindows =>
      'Schließen Sie die ältere Epic Wallet vor dem Import. Ob sie noch läuft, lässt sich unter Windows nicht prüfen.';

  @override
  String get deskSetRecvEpicboxOwnHint =>
      'Diese Wallet hat einen eigenen Epicbox-Server aus der älteren App. Eine Änderung hier gilt nur für diese Wallet.';

  @override
  String get deskErrRestoreScanRequired =>
      'Wiederherstellung nicht abgeschlossen. Empfangen und Senden sind möglich, sobald der Scan der Blockchain beendet ist.';

  @override
  String get deskSetupSkip => 'Einrichtung überspringen';

  @override
  String get deskOvRestoreTitle => 'Wiederherstellung nicht abgeschlossen';

  @override
  String get deskOvRestoreRunning =>
      'Das Guthaben dieser Wallet wird auf der Blockchain gesucht. Empfangene EPIC erscheinen, sobald sie gefunden werden; Empfangen und Senden sind möglich, sobald der Scan abgeschlossen ist.';

  @override
  String deskOvRestoreAfterHeight(String height) {
    return 'Das Guthaben ab Block $height ist da. Frühere Blöcke werden noch geprüft; Empfangen und Senden sind möglich, sobald das abgeschlossen ist.';
  }

  @override
  String get deskOvRestoreWaiting => 'Der Scan wartet auf das Netzwerk.';

  @override
  String get deskOvRestoreFailed =>
      'Der Scan wurde vor dem Ende abgebrochen. Empfangen und Senden bleiben gesperrt, bis er abgeschlossen ist.';

  @override
  String get deskOvRestoreProgress =>
      'Fortschritt des Wiederherstellungs-Scans';

  @override
  String get deskSetRescanRestoreRunning =>
      'Der Scan der Wiederherstellung läuft. Guthaben neu prüfen ist verfügbar, sobald er abgeschlossen ist.';

  @override
  String get deskSetRescanStartHeading => 'Wo beginnen';

  @override
  String get deskOnbForgotLink => 'Passwort vergessen?';

  @override
  String get deskOnbForgotTitle => 'Neues Passwort festlegen';

  @override
  String deskOnbForgotLead(String name) {
    return 'Die Wiederherstellungsphrase von $name ersetzt das Passwort. Verlauf, Notizen und Bezeichnungen bleiben erhalten; kein Scan nötig.';
  }

  @override
  String get deskOnbForgotPasswordLead =>
      'Die Phrase stimmt. Wählen Sie das neue Passwort, das diese Wallet auf diesem Computer entsperrt.';

  @override
  String get deskOnbForgotSet => 'Passwort festlegen';

  @override
  String deskOnbForgotOtherWallet(String name) {
    return 'Diese Phrase gehört zu einer anderen Wallet, nicht zu $name. Es wurde nichts geändert.';
  }

  @override
  String get deskOnbSameNewPassword => 'Neues Passwort festlegen';

  @override
  String get deskSetupSkipKeeps =>
      'Überspringen behält die aktuellen Node- und Epicbox-Einstellungen.';

  @override
  String deskSetupMarkNotCleared(String reason) {
    return 'Die Einrichtung konnte nicht als abgeschlossen vermerkt werden: $reason. Sie kann sich beim nächsten Start erneut öffnen; „Einrichtung überspringen“ schließt sie.';
  }

  @override
  String get deskOvRestoredImportTitle => 'Ihre Wallet ist wiederhergestellt';

  @override
  String get deskOvRestoredImportBody =>
      'Das Guthaben ist zurück. Eine Wallet-Datendatei dieser Wallet bringt Verlauf, Kontakte, Rechnungen und Einstellungen zurück.';

  @override
  String get deskOvRestoredImportButton => 'Wallet-Daten importieren';

  @override
  String get deskOvRestoredImportLater =>
      'Später unter Einstellungen › Wallet › Sicherung.';

  @override
  String get deskOnbForgotNoCheck =>
      'Nichts in den Dateien dieser Wallet kann die Phrase bestätigen, daher bleibt das Passwort.';

  @override
  String deskOnbForgotRestoreHint(String name) {
    return 'Stellen Sie sie stattdessen aus der Phrase wieder her: $name verlässt die Liste, ihre Dateien bleiben auf diesem Computer.';
  }

  @override
  String get deskOnbForgotRestoreInstead => 'Aus der Phrase wiederherstellen';

  @override
  String get qrShowTitleRequest => 'Rechnung';

  @override
  String qrShowSubRequest(String amount) {
    return '$amount von einem Smartphone neben Ihnen';
  }

  @override
  String get qrHiddenBodyRequest =>
      'Wer ihn scannt, kann diese Rechnung bezahlen. Zeigen Sie ihn nur der zahlenden Person.';

  @override
  String get qrStatusRequestHidden => 'Zeigen Sie dies der zahlenden Person.';

  @override
  String get qrStatusRequestShowing =>
      'Warten, bis die Gegenseite scannt und zustimmt. Scannen Sie dann deren Antwort.';

  @override
  String qrSemanticsRequest(String state) {
    return 'Rechnungs-QR-Code, $state';
  }

  @override
  String qrShowSubPaid(String amount) {
    return 'An die Person, die $amount angefordert hat';
  }

  @override
  String get qrHiddenBodyPaid =>
      'Zeigen Sie ihn dem Smartphone, das die Zahlung angefordert hat. Nur diese Wallet kann ihn verwenden.';

  @override
  String get qrStatusPaidHidden =>
      'Zeigen Sie dies der Person, die angefragt hat.';

  @override
  String get qrStatusPaidShowing =>
      'Warten, bis die Gegenseite scannt und die Zahlung sendet.';

  @override
  String get qrStatusPaid => 'Bezahlt.';

  @override
  String get reqToQr => 'Als QR einem Smartphone in der Nähe zeigen';

  @override
  String reqQrSummary(String amount) {
    return 'Wer den Code scannt, kann $amount zahlen. Scannen Sie hier deren Antwort, um abzuschließen. Die Rechnung läuft in 24 h ab.';
  }

  @override
  String get reqShowQr => 'Als QR anzeigen';

  @override
  String get receiveQrRequest => 'Betrag anfordern';

  @override
  String get reqQrPaidTitle => 'Bezahlt';

  @override
  String reqQrPaidHeadline(String amount) {
    return '$amount bezahlt und an das Netzwerk gesendet.';
  }

  @override
  String get reqQrNew => 'Neue Rechnung';

  @override
  String get reqQrAlreadyPaid =>
      'Diese Rechnung ist bereits bezahlt. Von diesem Smartphone wurde nichts abgebucht: Die Zahlung bleibt dort gesperrt, bis sie in der Aktivität storniert wird oder nach einem Tag abläuft.';

  @override
  String get reqFromQrTitle => 'Rechnung aus einem QR-Code';

  @override
  String get reqFromQrWarn =>
      'Nicht von einem gekoppelten Kontakt. Nichts im Code zeigt, wer ihn erstellt hat: Zahlen Sie nur an die Person oder das Geschäft vor Ihnen, und prüfen Sie den Betrag.';

  @override
  String get reqQrMessageLabel => 'Nachricht im Code';

  @override
  String get reqApproveShowAnswer => 'Zustimmen und Antwort zeigen';

  @override
  String get reqQrAnswerTitle => 'Zugestimmt';

  @override
  String get reqQrAnswerLead =>
      'Die Person, die angefragt hat, scannt die Antwort und sendet die Zahlung. Bis dahin wartet sie in der Aktivität als „Wartet auf Empfänger“.';

  @override
  String get reqExpired =>
      'Diese Rechnung ist abgelaufen. Bitten Sie um eine neue. Es wurde nichts bezahlt.';

  @override
  String get reqOtherChain =>
      'Diese Rechnung gehört zu einem anderen Epic-Netzwerk, oder ihre Frist passt nicht zu diesem. Es wurde nichts bezahlt.';

  @override
  String get reqQrOpenNote =>
      '24 h offen unter Rechnungen › Gesendet, dann läuft sie ab.';

  @override
  String get reqQrWrongReply =>
      'Diese Antwort gehört zu einer anderen Rechnung. Scannen Sie die Antwort auf diese.';

  @override
  String get backupFileHolds =>
      'Enthält Zahlungsverlauf, Kontakte, Rechnungen und Einstellungen dieser Wallet, Stand jetzt.';

  @override
  String get backupFileRestoreOrder =>
      'Zum Wiederherstellen: zuerst die Wiederherstellungsphrase eingeben, dann diese Datei importieren.';

  @override
  String get backupImportLead =>
      'Bringt den Zahlungsverlauf, die Kontakte, Rechnungen und Einstellungen dieser Wallet zurück. Stellen Sie die Wallet zuerst aus ihrer Wiederherstellungsphrase wieder her.';

  @override
  String backupRestoredSummary(String items) {
    return 'Importiert: $items.';
  }

  @override
  String get backupListSeparator => ', ';

  @override
  String get backupListLastSeparator => ' und ';

  @override
  String backupRestoredPayments(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Zahlungen',
      one: '1 Zahlung',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredNotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Notizen',
      one: '1 Notiz',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredLabels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Bezeichnungen',
      one: '1 Bezeichnung',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredContacts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Kontakte',
      one: '1 Kontakt',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredStars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Favoriten',
      one: '1 Favorit',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredPairings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Kopplungen',
      one: '1 Kopplung',
    );
    return '$_temp0';
  }

  @override
  String backupRestoredInvoices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Rechnungen',
      one: '1 Rechnung',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoredSettings => 'Einstellungen';

  @override
  String get backupRestoredWalletName => 'der Wallet-Name';

  @override
  String backupRestoredAlreadyHere(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einträge waren bereits vorhanden.',
      one: '1 Eintrag war bereits vorhanden.',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsTitle =>
      'Einstellungen aus dieser Datei übernehmen?';

  @override
  String backupSettingsBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einstellungen hier unterscheiden sich von der Datei.',
      one: '1 Einstellung hier unterscheidet sich von der Datei.',
    );
    return '$_temp0 Der Rest der Datei ist bereits importiert.';
  }

  @override
  String get backupSettingsUseBackup => 'Die der Datei';

  @override
  String get backupSettingsKeepMine => 'Meine behalten';

  @override
  String get deskEpicboxBlockedWord => 'Blockiert';

  @override
  String deskEpicboxBlockedText(String host) {
    return 'Dieses Netzwerk blockiert $host. Wählen Sie einen anderen Epicbox-Server oder ein privates DNS.';
  }

  @override
  String deskEpicboxBlockedShort(String host) {
    return 'Dieses Netzwerk blockiert $host. Anderen Server oder privates DNS nutzen.';
  }

  @override
  String deskEpicboxBlockedSwitch(String host) {
    return 'Zu $host wechseln';
  }

  @override
  String get deskSlotNow => 'Aktuell';

  @override
  String get deskSlotHelp => 'Hilfe';

  @override
  String get deskSlotScanning => 'Chain wird durchsucht';

  @override
  String get deskSlotScanWaits => 'Durchsuchen wartet auf das Netzwerk';

  @override
  String get deskSlotScanStopped => 'Durchsuchen angehalten';

  @override
  String get deskSlotTryAgain => 'Erneut versuchen';

  @override
  String get deskSlotSending => 'Zahlung wird gesendet';

  @override
  String get deskSlotPaymentOut => 'Zahlung unterwegs';

  @override
  String get deskSlotPaymentIn => 'Zahlung kommt an';

  @override
  String get deskSlotPaymentsOut => 'Zahlungen unterwegs';

  @override
  String get deskSlotPaymentsMoving => 'Zahlungen bestätigen';

  @override
  String deskSlotOf(String done, String needed) {
    return '$done von $needed';
  }

  @override
  String get deskSlotWaitingBlock => 'wartet auf einen Block';

  @override
  String get deskSlotRequests => 'Neue Rechnungen';

  @override
  String get deskSlotNodeStarting => 'Lokaler Node startet';

  @override
  String get deskSlotNodeSyncing => 'Lokaler Node synchronisiert';

  @override
  String get deskSlotOpenRecheck => '„Guthaben neu prüfen“ öffnen';

  @override
  String get deskSlotOpenSend => 'Senden öffnen';

  @override
  String get deskSlotOpenActivity => 'In Aktivität öffnen';

  @override
  String get deskSlotOpenInvoices => 'Rechnungen öffnen';

  @override
  String deskBarMenu(String app) {
    return 'Menü von $app';
  }

  @override
  String get deskBarLock => 'Wallet sperren';

  @override
  String get deskBarShortcuts => 'Tastenkürzel';

  @override
  String deskBarAbout(String app) {
    return 'Über $app';
  }

  @override
  String get deskBarQuit => 'Beenden';

  @override
  String get deskBarWalletsHere => 'Wallets auf diesem Computer';

  @override
  String get deskBarAddWallet => 'Wallet hinzufügen';

  @override
  String get deskBarWalletSettings => 'Wallet-Einstellungen';

  @override
  String get deskBarStatus => 'Verbindungsstatus';

  @override
  String get deskBarMinimise => 'Minimieren';

  @override
  String get deskBarMaximise => 'Maximieren';

  @override
  String get deskBarRestore => 'Wiederherstellen';

  @override
  String get deskBarClose => 'Schließen';

  @override
  String get deskBarSendRunningTitle => 'Eine Zahlung wird gesendet';

  @override
  String get deskBarSendRunningBody =>
      'Jetzt zu schließen ließe offen, wie die Zahlung ausgeht. Die Wallet kann sich selbst schließen, sobald das Senden abgeschlossen ist.';

  @override
  String get deskBarKeepOpen => 'Offen lassen';

  @override
  String get deskBarCloseAfterSend => 'Nach dem Senden schließen';

  @override
  String get deskBarClosesAfterSend => 'Schließt nach dem Senden';

  @override
  String get deskBarClosing => 'Wird geschlossen';

  @override
  String get deskBarKeyBack => 'Zurück';

  @override
  String get deskBarKeyForward => 'Vorwärts';

  @override
  String get deskBarKeyClose => 'Menü oder Dialog schließen';

  @override
  String get deskBarKeySubmit => 'Hauptaktion eines Formulars ausführen';

  @override
  String get deskBarKeyList => 'Diese Liste';

  @override
  String get deskBarCopyBuild => 'Build-Info kopieren';

  @override
  String get deskBarBuildCopied => 'Build-Info kopiert';

  @override
  String get deskBarKeyMenu => 'App-Menü öffnen';

  @override
  String get txDetailsCancelRequestBody =>
      'Die andere Seite kann diese Zahlung noch abschließen.';

  @override
  String get txDetailsCancelNotPostedBody =>
      'Diese Zahlung könnte später noch durchgehen.';

  @override
  String get cancelMoreInHelp => 'So funktioniert Stornieren';

  @override
  String deskTxCancelNotPostedBody(String amount, String who) {
    return '$amount EPIC an $who. Diese Zahlung könnte später noch durchgehen.';
  }

  @override
  String get deskOnbWalletNameEdit => 'Wallet-Namen ändern';

  @override
  String get deskOnbWalletNameField => 'Wallet-Name';

  @override
  String deskOnbWalletNameIs(String name) {
    return 'Wallet-Name: $name';
  }

  @override
  String sendTurnOnMethod(String method) {
    return '$method einschalten';
  }

  @override
  String get reqPickContactOrMethod => 'Kontakt oder Methode wählen';

  @override
  String deskOnbUnlockOpened(String when) {
    return 'Geöffnet $when';
  }

  @override
  String get deskOwnYourNode => 'Eigener Node';

  @override
  String deskOwnLabel(String where) {
    return 'Eigener Node · $where';
  }

  @override
  String get deskOwnClassThisComputer => 'dieser Computer';

  @override
  String get deskOwnClassHome => 'Heimnetz';

  @override
  String get deskOwnClassVpn => 'VPN';

  @override
  String get deskOwnFactMempool => 'Mempool';

  @override
  String get deskOwnPoolEmpty => 'leer';

  @override
  String deskOwnPoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warten',
      one: '1 wartet',
    );
    return '$_temp0';
  }

  @override
  String deskOwnSourceSite(String site) {
    return 'Alle 15 s direkt gefragt · Spitze von $site';
  }

  @override
  String deskOwnSourceNodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle 15 s direkt gefragt · Spitze von $count öffentlichen Nodes',
      one: 'Alle 15 s direkt gefragt · Spitze von 1 öffentlichen Node',
    );
    return '$_temp0';
  }

  @override
  String get deskOwnSourceNone =>
      'Alle 15 s direkt gefragt · keine Netzwerkspitze zum Vergleich';

  @override
  String get deskOwnSyncingLine =>
      'Bis er synchronisiert ist, kann die Wallet über ihn weder senden noch empfangen';

  @override
  String get deskOwnAccess => 'Besitzerzugang';

  @override
  String get deskOwnAccessHint =>
      'Mit dem Besitzer-Secret des Nodes sehen Sie hier seinen Sync-Schritt und seine Peers und können einen Peer sperren. Es liegt im Schlüsselbund dieses Computers, nie in den Einstellungen oder der Wallet-Datendatei.';

  @override
  String get deskOwnAccessNotSet => 'Nicht eingerichtet';

  @override
  String get deskOwnAccessOn => 'Hinzugefügt';

  @override
  String deskOwnAccessRefused(String time) {
    return 'Abgelehnt seit $time';
  }

  @override
  String get deskOwnAccessRefusedBadge => 'Abgelehnt';

  @override
  String get deskOwnAccessTor => 'Bei eingeschaltetem Tor nicht genutzt';

  @override
  String get deskOwnAccessNote =>
      'Peers und Sync-Details kommen von der Owner-API des Nodes.';

  @override
  String get deskOwnAdd => 'Hinzufügen…';

  @override
  String get deskOwnUpdate => 'Ändern…';

  @override
  String get deskOwnRemove => 'Entfernen';

  @override
  String get deskOwnAdded => 'Besitzerzugang hinzugefügt';

  @override
  String get deskOwnRemoved => 'Besitzerzugang entfernt';

  @override
  String deskOwnDlgTitle(String host) {
    return 'Besitzerzugang zu $host';
  }

  @override
  String get deskOwnDlgWhere =>
      'Das Secret ist die erste Zeile der Datei .api_secret im Datenordner des Nodes (~/.epic/main auf dem Computer des Nodes).';

  @override
  String get deskOwnDlgPaste => 'Secret einfügen';

  @override
  String get deskOwnDlgPick => 'Datei wählen…';

  @override
  String deskOwnDlgFileRead(String file) {
    return 'Aus $file gelesen';
  }

  @override
  String get deskOwnDlgFileEmpty => 'Diese Datei enthält kein Secret';

  @override
  String get deskOwnDlgPlainTitle =>
      'Das Secret geht unverschlüsselt durchs Heimnetz';

  @override
  String get deskOwnDlgPlainText =>
      'In einem gemeinsam genutzten Netz erreichen Sie den Node über ein VPN oder https, oder nutzen die Wallet auf dem Computer des Nodes.';

  @override
  String get deskOwnDlgPlainAgain => 'Für diesen Node nicht mehr zeigen';

  @override
  String get deskOwnDlgRefused => 'Der Node hat dieses Secret abgelehnt';

  @override
  String get deskOwnDlgNoAnswer =>
      'Der Node hat nicht geantwortet; das Secret wurde behalten';

  @override
  String get deskOwnDlgAdd => 'Hinzufügen';

  @override
  String get deskOwnDownTitle => 'Eigener Node antwortet nicht';

  @override
  String deskOwnDownText(String host) {
    return 'Die Wallet nutzt solange $host und wechselt zurück, sobald dieser Node zweimal nacheinander antwortet.';
  }

  @override
  String deskOwnUsingMeanwhile(String host) {
    return 'solange $host';
  }

  @override
  String deskOwnUsingUntilSynced(String host) {
    return '$host bis zur Synchronisierung';
  }

  @override
  String get deskOwnTryNow => 'Jetzt versuchen';

  @override
  String deskOwnUseForGood(String host) {
    return '$host behalten';
  }

  @override
  String get deskOwnSyncTitle =>
      'Öffentlichen Node nutzen, bis dieser Node synchronisiert ist?';

  @override
  String deskOwnSyncText(String host) {
    return '$host kann einspringen, bis dieser Node synchronisiert ist.';
  }

  @override
  String get deskOwnWaitForMine => 'Auf diesen Node warten';

  @override
  String deskOwnSyncUsingTitle(String host) {
    return '$host bis zur Synchronisierung dieses Nodes';
  }

  @override
  String get deskOwnSyncUsingText =>
      'Die Wallet wechselt zurück, sobald dieser Node Transaktionen annimmt.';

  @override
  String get deskOwnMine => 'Das ist mein Node';

  @override
  String deskOwnMineHint(String site) {
    return 'Fragt den Node selbst statt $site und bietet Besitzerzugang an. Für einen Node, den Sie selbst betreiben.';
  }

  @override
  String get deskOwnSlotSyncing => 'Eigener Node synchronisiert';

  @override
  String ownNodeLabel(String where) {
    return 'Ihr Node · $where';
  }

  @override
  String get ownNodeThisPhone => 'dieses Handy';

  @override
  String get ownNodeHome => 'Heimnetz';

  @override
  String get ownNodeVpn => 'VPN';

  @override
  String get ownNodeSynced => 'Synchronisiert';

  @override
  String get ownNodeSyncing => 'Synchronisiert…';

  @override
  String get ownNodeBehind => 'Im Rückstand';

  @override
  String get ownNodeFactBehind => 'Rückstand';

  @override
  String get ownNodeFactLatency => 'Latenz';

  @override
  String get ownNodeFactAccepts => 'Nimmt Transaktionen an';

  @override
  String get ownNodeFactMempool => 'Mempool';

  @override
  String get ownNodeYes => 'Ja';

  @override
  String get ownNodeNotYet => 'Noch nicht';

  @override
  String get ownNodeUnknown => 'Unbekannt';

  @override
  String get ownNodePoolEmpty => 'leer';

  @override
  String ownNodePoolWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warten',
      one: '1 wartet',
    );
    return '$_temp0';
  }

  @override
  String get ownNodeAskedDirectly =>
      'Alle 15 s direkt von diesem Handy gefragt';

  @override
  String get deskConExportDo => 'Exportieren';

  @override
  String get deskSetAboutDownloadPage => 'Download-Seite';

  @override
  String get deskUpdManual =>
      'Diese Kopie kann Updates nicht selbst installieren.';

  @override
  String get deskUpdDownloadInstall => 'Herunterladen und installieren';

  @override
  String get deskUpdReadyTitle => 'Neu starten zum Aktualisieren';

  @override
  String get deskUpdReadyBody =>
      'Die Wallet wird gesperrt und die App öffnet sich wieder.';

  @override
  String get deskUpdRestartNow => 'Jetzt neu starten';

  @override
  String get deskUpdLater => 'Später';

  @override
  String get sendTorNotInVersion =>
      'Diese Version kann nicht an Tor-Adressen senden.';

  @override
  String get methodSendDirectLineNoTor => 'Ihre Wallet muss geöffnet sein.';

  @override
  String get sendDirectAddressShapeNoTor =>
      'Eine Link-Adresse beginnt mit http:// oder https://.';

  @override
  String get contactsAddressInvalidAnyNoTor =>
      'Keine gültige Adresse. Verwenden Sie eine Epicbox-Adresse (es5x…@Server) oder eine Link-Adresse (https://…).';

  @override
  String get handshakeLink1NoTor =>
      'Ihre Wallet sendet die Zahlung direkt an die Wallet der Gegenseite, über das Internet. Die Coins werden gesperrt.';

  @override
  String txLinkHttpHintNoTor(String port) {
    return 'Link · HTTP zahlt direkt an eine Wallet unter einer Web-Adresse (http://host:$port) und gibt diesem Telefon eine Adresse, an die Wallets im selben WLAN zahlen können. Beide Wallets müssen geöffnet sein. Es ist unterwegs nicht verschlüsselt und aus dem Internet oder über Mobilfunk nicht erreichbar. Fügt Link · HTTP zu Senden und Empfangen hinzu.';
  }

  @override
  String get tourPhoneWalletTextNoTor =>
      'Ihr Guthaben und darunter die Symbole für Node und Epicbox. Was noch bestätigt wird, steht in den Kacheln darunter.';

  @override
  String get tourPhonePrivacyTextNoTor =>
      'Welchen Node und welchen Epicbox-Server die Wallet nutzt. Tippen Sie auf einen Server, um ihn zu ändern.';

  @override
  String get tourPhoneAdvancedTextNoTor =>
      'Offline, Outputs und technische Details sind hier. Schalten Sie ein, was Sie brauchen.';

  @override
  String get deskNoTorSendDirectLine2 =>
      'Eine http(s)-Adresse. Die Wallet des Empfängers muss geöffnet sein.';

  @override
  String deskNoTorSetTxDirectHint(String port) {
    return 'Zahlen und bezahlt werden direkt von Wallet zu Wallet unter einer Web-Adresse (http://host:$port), ohne Server dazwischen. Funktioniert nur, solange beide Wallets geöffnet sind. Fügt Link · HTTP zu Senden und seine Adresse zu Empfangen hinzu. Alle Wallets.';
  }

  @override
  String get deskNoTorTxDetailsFromBad =>
      'Verwenden Sie eine Epicbox- oder http(s)-Adresse.';

  @override
  String get deskNoTorTourAdvancedText =>
      'Outputs und technische Details sind hier. Schalten Sie ein, was Sie brauchen.';

  @override
  String get errorInputsSpentElsewhere =>
      'Der Node zeigt diese Coins schon als ausgegeben, und diese Wallet hat sie nicht ausgegeben. Wahrscheinlich hat das eine andere Wallet mit Ihrer Wiederherstellungsphrase getan.';

  @override
  String get deskErrInputsSpentElsewhere =>
      'Der Node zeigt diese Coins schon als ausgegeben, und diese Wallet hat sie nicht ausgegeben. Wahrscheinlich hat das eine andere Wallet mit Ihrer Wiederherstellungsphrase getan.';

  @override
  String get slAddedByYou => 'Von Ihnen hinzugefügt';

  @override
  String slCount(int n, int limit) {
    return '$n von $limit';
  }

  @override
  String slLimit(int limit) {
    return '$limit von $limit gewählt. Eines abwählen, um ein anderes zu wählen.';
  }

  @override
  String get slKeepOne => 'Mindestens einen behalten.';

  @override
  String get slChosenUntick => 'Gewählt. Erst abwählen.';

  @override
  String get slResetDefaults => 'Auf Standard zurücksetzen';

  @override
  String get slReset => 'Auf Standard zurückgesetzt.';

  @override
  String slChosen(String host) {
    return '$host gewählt.';
  }

  @override
  String slChosenNonDefault(String host) {
    return 'Gewählt. Wallets, die auch $host nutzen, finden Sie dort.';
  }

  @override
  String slUnchosen(String host) {
    return '$host abgewählt.';
  }

  @override
  String slAddedNonDefault(String host) {
    return '$host hinzugefügt. Wallets, die es auch nutzen, finden Sie dort.';
  }

  @override
  String slAddedUntick(String host) {
    return '$host hinzugefügt. Ein anderes abwählen, um es zu wählen.';
  }

  @override
  String get txSentFromOtherWallet => 'Von einem anderen Gerät gesendet';

  @override
  String txSpokenSentFromOtherWallet(String amount) {
    return 'Von einem anderen Gerät gesendet, $amount';
  }

  @override
  String get txDetailsOtherWallet =>
      'Von einem anderen Gerät mit der Wiederherstellungsphrase dieser Wallet gesendet. Nur der Betrag ist bekannt.';

  @override
  String get txSentFromOtherWalletUnverified =>
      'Von einem anderen Gerät gesendet · ungeprüft';

  @override
  String get txDetailsUnverified =>
      'Ungeprüft: Bisher meldet das nur der Node. Bestätigen Sie es mit „Guthaben neu prüfen“.';

  @override
  String get txDetailsNotKnown => 'Nicht bekannt';

  @override
  String get txReceivedByOtherWallet => 'Von einem anderen Gerät empfangen';

  @override
  String txSpokenReceivedByOtherWallet(String amount) {
    return 'Von einem anderen Gerät empfangen, $amount';
  }

  @override
  String get txDetailsOtherWalletIn =>
      'Von einem anderen Gerät mit der Wiederherstellungsphrase dieser Wallet empfangen. Nur der Betrag ist bekannt.';

  @override
  String get expLinkedDevices => 'Verknüpfte Geräte';

  @override
  String get expLinkedDevicesHint =>
      'Diese Wallet auf zwei Geräten: Jedes zeigt die Zahlungen des anderen und hält die Münzen zurück, die das andere gerade ausgibt. Experimentell.';

  @override
  String get devicesThisPhone => 'Telefon';

  @override
  String get devicesThisComputer => 'Computer';

  @override
  String get devicesNone => 'Keine';

  @override
  String get devicesSeenNow => 'gerade gesehen';

  @override
  String devicesSeenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Min. gesehen',
      one: 'vor $count Min. gesehen',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Std. gesehen',
      one: 'vor $count Std. gesehen',
    );
    return '$_temp0';
  }

  @override
  String devicesSeenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen gesehen',
      one: 'vor $count Tag gesehen',
    );
    return '$_temp0';
  }

  @override
  String get devicesNotSeen => 'noch nicht gesehen';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Geräte',
      one: '$count Gerät',
    );
    return '$_temp0';
  }

  @override
  String get devicesThisDevice => 'Dieses Gerät';

  @override
  String get devicesOthers => 'Verknüpftes Gerät';

  @override
  String get devicesEmpty =>
      'Diese Wallet auf dem anderen Gerät wiederherstellen, dann die beiden hier verknüpfen.';

  @override
  String get devicesLink => 'Gerät verknüpfen';

  @override
  String get devicesServers => 'Server';

  @override
  String get devicesPause => 'Abgleich pausieren';

  @override
  String get devicesPauseHint =>
      'Während der Pause warten Meldungen bis zu 7 Tage auf den Servern. „Nur Node“ und „Notaus“ pausieren ebenfalls.';

  @override
  String get devicesHeld => 'Zurückgehaltene Münzen';

  @override
  String devicesHeldBy(String name) {
    return 'Von einer Zahlung von $name zurückgehalten';
  }

  @override
  String get devicesRelease => 'Freigeben';

  @override
  String get devicesReleaseTitle => 'Diese Münzen freigeben?';

  @override
  String devicesReleaseBody(String name) {
    return '$name schließt diese Zahlung womöglich noch ab. Dann schlägt eine Zahlung mit diesen Münzen fehl. Das betrifft nur dieses Gerät.';
  }

  @override
  String get devicesReleased => 'Auf diesem Gerät freigegeben.';

  @override
  String get devicesRename => 'Umbenennen';

  @override
  String get devicesNameLabel => 'Name';

  @override
  String get devicesRemove => 'Entfernen';

  @override
  String devicesRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String devicesRemoveBody(String name) {
    return '$name erhält keine Meldungen dieser Wallet mehr; Münzen, die es hier zurückhält, werden freigegeben. Mit der Wiederherstellungsphrase kann es weiterhin ausgeben: Könnte es in fremden Händen sein, das Guthaben in eine neue Wallet verschieben.';
  }

  @override
  String devicesRemoved(String name) {
    return '$name entfernt.';
  }

  @override
  String devicesRemovedBy(String name) {
    return '$name hat dieses Gerät entfernt.';
  }

  @override
  String get devicesRemoving =>
      'Wird entfernt … Das andere Gerät erfährt es, sobald dieses wieder verbunden ist.';

  @override
  String get devicesMoneyNote =>
      'Die Verknüpfung teilt Zahlungen zwischen den beiden Geräten. Sie schützt das Geld nicht: Jedes Gerät mit der Wiederherstellungsphrase kann es ausgeben.';

  @override
  String get devicesUnsupported =>
      'Diese Version kann noch keine Geräte verknüpfen.';

  @override
  String get linkLead =>
      'Für diese Wallet auf dem anderen Gerät. Dort zuerst aus der Wiederherstellungsphrase wiederherstellen.';

  @override
  String get linkShow => 'QR zeigen';

  @override
  String get linkScan => 'QR scannen';

  @override
  String get linkPaste => 'Einladung einfügen';

  @override
  String get linkCopy => 'Einladung kopieren';

  @override
  String get linkCopied => 'Einladung kopiert.';

  @override
  String linkExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die Einladung gilt noch $count Min.',
      one: 'Die Einladung gilt noch $count Min.',
    );
    return '$_temp0';
  }

  @override
  String get linkWaiting => 'Warten auf das andere Gerät…';

  @override
  String linkWaitingFor(String name) {
    return 'Warten auf $name…';
  }

  @override
  String get linkPasteLabel => 'Einladung';

  @override
  String get linkGo => 'Verknüpfen';

  @override
  String get linkPicturesLabel => 'Die vier Bilder';

  @override
  String get linkDoneTitle => 'Verknüpft';

  @override
  String linkDone(String name) {
    return 'Mit $name verknüpft.';
  }

  @override
  String get linkFailedTitle => 'Nicht verknüpft';

  @override
  String get linkFailInvalid => 'Keine Geräte-Einladung.';

  @override
  String get linkFailExpired =>
      'Die Einladung ist abgelaufen. Eine neue machen.';

  @override
  String get linkFailNotFound => 'Diese Einladung wurde schon verwendet.';

  @override
  String get linkFailOwn =>
      'Diese Einladung ist von diesem Gerät. Auf dem anderen scannen.';

  @override
  String get linkFailOtherWallet =>
      'Dieses Gerät enthält eine andere Wallet. Verknüpfen braucht dieselbe Wiederherstellungsphrase.';

  @override
  String get linkFailOtherWalletCode =>
      'Diese Einladung ist von einer anderen Wallet. Verknüpfen braucht dieselbe Wiederherstellungsphrase.';

  @override
  String get linkFailTooMany => 'Es ist schon ein Gerät verknüpft.';

  @override
  String get linkFailUnreachable => 'Das andere Gerät war nicht erreichbar.';

  @override
  String get linkTryAgain => 'Erneut versuchen';

  @override
  String txSentFromDevice(String device) {
    return 'Gesendet von $device';
  }

  @override
  String txDeviceMadeOn(String device) {
    return 'Auf $device erstellt. Die Details stammen von diesem Gerät; Betrag und Bestätigungen aus der Blockchain.';
  }

  @override
  String get txDeviceHeld =>
      'Seine Münzen bleiben auf diesem Gerät zurückgehalten, bis die Blockchain die Zahlung zeigt oder das andere Gerät sie beendet.';

  @override
  String sendHeldByDevice(String amount, String name) {
    return '$amount EPIC sind durch eine Zahlung von „$name“ zurückgehalten.';
  }

  @override
  String get offerLinkRestore =>
      'Diese Wallet auch auf einem anderen Gerät? Verknüpfen, um die Zahlungen des anderen zu sehen.';

  @override
  String get offerLinkOtherWallet =>
      'Ist das Ihr anderes Gerät? Verknüpfen, um zu sehen, wer bezahlt wurde, und beide abzugleichen.';

  @override
  String devicesReleasedRow(String name) {
    return 'Hier freigegeben · $name sendet sie womöglich noch';
  }

  @override
  String get deskDevPausedOffline =>
      'Pausiert, solange Offline eingeschaltet ist.';

  @override
  String get deskDevPausedEpicboxOff => 'Pausiert, solange Epicbox aus ist.';

  @override
  String deskDevHeldAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskDevRenameThis => 'Diesen Computer umbenennen';

  @override
  String deskDevRenameDevice(String name) {
    return '$name umbenennen';
  }

  @override
  String get deskDevPasteLead =>
      'Fügen Sie den Code ein, den das andere Gerät zeigt.';

  @override
  String get deskDevMakingCode => 'Code wird erstellt…';

  @override
  String get deskDevConnecting => 'Verbindung wird hergestellt…';

  @override
  String get deskDevTheOther => 'Das andere Gerät';

  @override
  String get deskDevOfferReceived =>
      'Ist das Ihr anderes Gerät? Verknüpfen, um zu sehen, von wem es kam, und beide abzugleichen.';

  @override
  String devicesEndCancelled(String name) {
    return 'Auf $name storniert';
  }

  @override
  String devicesEndFailed(String name) {
    return 'Auf $name fehlgeschlagen';
  }

  @override
  String devicesEndExpired(String name) {
    return 'Auf $name abgelaufen';
  }

  @override
  String devicesEndLineCancelled(String name) {
    return '$name hat diese Zahlung storniert. Ihre Münzen sind wieder frei.';
  }

  @override
  String devicesEndLineExpired(String name) {
    return '$name hat diese Zahlung nicht rechtzeitig abgeschlossen. Ihre Münzen sind wieder frei.';
  }

  @override
  String devicesWhyNotDelivered(String name) {
    return '$name konnte sie dem Empfänger nicht zustellen. Ihre Münzen sind wieder frei.';
  }

  @override
  String get devicesWhyRefused =>
      'Der Server des Empfängers hat sie abgelehnt. Ihre Münzen sind wieder frei.';

  @override
  String get devicesWhyInputsSpent => 'Ihre Münzen waren bereits ausgegeben.';

  @override
  String devicesWhyOther(String name) {
    return '$name konnte sie nicht abschließen. Ihre Münzen sind wieder frei.';
  }

  @override
  String devicesStatusInfo(String name) {
    return 'Dieser Status kommt von $name. Den endgültigen Stand bestimmt die Blockchain.';
  }

  @override
  String get syncHelpOtherDevice => 'Anderes Gerät';

  @override
  String get syncHelpServer => 'Server';

  @override
  String get syncHelpChain => 'Blockchain';

  @override
  String get syncHelpStep1 => 'Dieses Gerät beginnt eine Zahlung.';

  @override
  String syncHelpStep2(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eine verschlüsselte Meldung geht an beide Server. Nur die Geräte können sie lesen.',
      one: 'Eine verschlüsselte Meldung geht über den Server. Nur die Geräte können sie lesen.',
    );
    return '$_temp0';
  }

  @override
  String get syncHelpStep3 =>
      'Das andere Gerät hält diese Münzen zurück und führt die Zahlung auf.';

  @override
  String get syncHelpStep4 =>
      'Die Chain bestätigt. Sie entscheidet über den endgültigen Stand.';

  @override
  String get syncHelpDiagram =>
      'So funktioniert der Abgleich: Dieses Gerät beginnt eine Zahlung; eine verschlüsselte Meldung geht über den Server an das andere Gerät, das diese Münzen zurückhält; die Blockchain bestätigt.';

  @override
  String get syncHelpStatus => 'Aktueller Stand';

  @override
  String get syncHelpPaused => 'Abgleich pausiert';

  @override
  String get syncHelpAnswering => 'Antwortet';

  @override
  String get syncHelpNotAnswering => 'Antwortet nicht';

  @override
  String get syncHelpNotChecked => 'Nicht geprüft';

  @override
  String get deskSetAdvConfirmations => 'Bestätigungen';

  @override
  String deskSetAdvConfirmationsHint(int byDefault, int min, int max) {
    return 'Wie viele Blöcke eine empfangene Zahlung wartet, bevor ihre Outputs verfügbar sind. Standardmäßig $byDefault; jeder Wert von $min bis $max.';
  }

  @override
  String get deskSetAdvConfirmationsDefault => 'Voreinstellung';

  @override
  String deskSetAdvConfirmationsReset(int count) {
    return 'Auf $count zurücksetzen';
  }

  @override
  String get deskSetAdvConfirmationsFewer => 'Weniger Bestätigungen';

  @override
  String get deskSetAdvConfirmationsMore => 'Mehr Bestätigungen';

  @override
  String deskSetAdvConfirmationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bestätigungen',
      one: '$count Bestätigung',
    );
    return '$_temp0';
  }

  @override
  String get deskSetAdvConfirmationsLowNote =>
      'Weniger Bestätigungen sind schneller, aber weniger sicher.';

  @override
  String get deskSetAdvConfirmationsNotSaved => 'Bestätigungen nicht geändert';

  @override
  String get deskSetPeersFirstSeenHint =>
      'Wann diese App den Peer in dieser Sitzung zuerst verbunden sah.';

  @override
  String deskAppFirstScanProgress(int percent) {
    return 'Blockchain wird gescannt · $percent %';
  }

  @override
  String deskAppFirstScanFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Outputs gefunden',
      one: '$countString Output gefunden',
    );
    return '$_temp0';
  }

  @override
  String get deskAppFirstScanShowLog => 'Protokoll zeigen';

  @override
  String get deskAppFirstScanHideLog => 'Protokoll ausblenden';

  @override
  String deskNodeDurationDh(int days, int hours) {
    return '$days T. $hours h';
  }

  @override
  String deskNodeDurationH(int hours) {
    return '$hours h';
  }

  @override
  String deskInvPayerAgoHoursOnly(int hours) {
    return '$hours Std.';
  }

  @override
  String get slPlainHttpTitle => 'Diesen Node ohne Verschlüsselung nutzen?';

  @override
  String slPlainHttpBody(String host) {
    return '$host liegt in einem gemeinsam genutzten Adressbereich: Ihr eigenes Tailnet (Tailscale) oder das Netz Ihres Internetanbieters. Die Wallet spricht mit diesem Node über unverschlüsseltes http, daher kann jeder in diesem Netz mitlesen, was die Wallet ihn fragt. Fügen Sie ihn nur hinzu, wenn die Adresse Ihr Tailnet ist.';
  }

  @override
  String get slPlainHttpUse => 'Node nutzen';

  @override
  String get slRefusedLocal =>
      'Nicht gewählt: Andere Wallets erreichen keinen Server an einer lokalen oder privaten Adresse.';

  @override
  String get slRefusedOnion =>
      'Nicht gewählt: Ein Onion-Server funktioniert nur mit eingeschaltetem Tor.';

  @override
  String get slRefusedOnionNoTor =>
      'Nicht gewählt: Diese Version kann diesen Server nicht erreichen.';

  @override
  String get deskOwnAccessOnPlain =>
      'Hinzugefügt · geht unverschlüsselt (http) an den Node, in diesem Netz mitlesbar';

  @override
  String get sasNotFromCamera =>
      'Der Code kam per Nachricht, nicht von Ihrer Kamera. Sofern die andere Wallet Ihren Code nicht von diesem Bildschirm gescannt hat, beweisen diese Wörter nicht, wer ihn geschickt hat; daher gibt es hier keine Bestätigung: Behalten Sie die Kopplung ungeprüft, oder koppeln Sie per Einladung.';

  @override
  String get slSwitchFirst => 'Erst wechseln';

  @override
  String get contactPaymentsNone => 'Noch keine Zahlungen mit diesem Kontakt.';

  @override
  String contactPaymentsWith(String name) {
    return 'Zahlungen mit $name';
  }

  @override
  String get contactPaymentsAll => 'Alle Zahlungen';

  @override
  String receiveEpicboxNotConnected(String server) {
    return 'Nicht verbunden · $server';
  }

  @override
  String restoreWordsAllOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Wörter stimmen.',
      one: 'Das Wort stimmt.',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String restoreWordsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter stehen nicht in der Liste.',
      one: '1 Wort steht nicht in der Liste.',
    );
    return '$_temp0';
  }

  @override
  String pairInvitedAt(String clock) {
    return 'Eingeladen $clock';
  }

  @override
  String get pairInvitedYesterday => 'Gestern eingeladen';

  @override
  String pairInvitedOn(String day) {
    return 'Eingeladen am $day';
  }

  @override
  String get deskActNoneUnderFilter => 'Nichts unter diesem Filter';

  @override
  String get deskKitMethodConnected => 'Verbunden';

  @override
  String get deskOvSendWaitsNode =>
      'Senden ist wieder möglich, sobald der Node antwortet.';

  @override
  String get deskSetRescanRecheck => 'Neu prüfen';

  @override
  String get deskSetRescanRecheckAgain => 'Noch einmal prüfen';

  @override
  String get deskSetRescanFromDate => 'Ab einem Datum';

  @override
  String get deskSetRescanPickDate => 'Datum wählen';

  @override
  String get deskSetRescanPickDateFirst => 'Zuerst ein Datum wählen.';

  @override
  String contactsImportAddsAddress(String name, String method, String address) {
    return '$name erhält eine $method-Adresse: $address';
  }

  @override
  String get netStatusTurnOnHint =>
      'Aus. Einschalten unter Einstellungen › Transaktionen.';

  @override
  String get netStatusTurnOnHintPrivacy =>
      'Aus. Einschalten unter Einstellungen › Datenschutz & Netzwerk.';

  @override
  String get netStatusTurnOnHintNet =>
      'Aus. Einschalten unter Einstellungen › Netzwerk & Datenschutz.';

  @override
  String get deskBarTurnOnHint =>
      'Aus. Einschalten unter Einstellungen › Transaktionen.';

  @override
  String get deskErrMacKeychain =>
      'macOS hat der App nicht erlaubt, ihre gespeicherten Daten im Schlüsselbund zu lesen. Beenden Sie BT Wallet und öffnen Sie es erneut; wenn macOS fragt, geben Sie das Passwort ein, mit dem Sie Ihren Mac entsperren, und wählen Sie „Immer erlauben“.';

  @override
  String get deskUpdOpenDmg => 'Disk-Image öffnen';

  @override
  String get deskUpdDmgHint =>
      'Die App schließt sich und das Disk-Image öffnet sich: Ziehen Sie BT Wallet in „Programme“ und ersetzen Sie die alte App. Legen Sie Epic Cash Desktop, falls vorhanden, in den Papierkorb.';

  @override
  String get balanceSheetTitle => 'Guthaben';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausstehend',
      one: '1 ausstehend',
    );
    return '$_temp0';
  }

  @override
  String get connectionsSheetTitle => 'Verbindungen';

  @override
  String settingsFileSyntaxError(String file, int line) {
    return '$file, Zeile $line: Diese Zeile ist nicht lesbar. Die letzten gültigen Einstellungen gelten weiter.';
  }

  @override
  String settingsFileNotText(String file, int line) {
    return '$file, Zeile $line: Kein Text in Anführungszeichen. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotNumber(String file, int line) {
    return '$file, Zeile $line: Keine ganze Zahl. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotSwitch(String file, int line) {
    return '$file, Zeile $line: Weder true noch false. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotList(String file, int line) {
    return '$file, Zeile $line: Keine Liste. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotNodeAddress(String file, int line) {
    return '$file, Zeile $line: Keine Node-Adresse. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotEpicboxServer(String file, int line) {
    return '$file, Zeile $line: Kein Epicbox-Server. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotHostName(String file, int line) {
    return '$file, Zeile $line: Kein Hostname. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotWebAddress(String file, int line) {
    return '$file, Zeile $line: Keine Webadresse. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotOnion(String file, int line) {
    return '$file, Zeile $line: Keine Onion-Adresse. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotPort(String file, int line) {
    return '$file, Zeile $line: Keine Portnummer. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileNotEpicboxAddress(String file, int line) {
    return '$file, Zeile $line: Keine Epicbox-Adresse. Der letzte gültige Wert gilt weiter.';
  }

  @override
  String settingsFileUnknownKey(String file, int line, String key) {
    return '$file, Zeile $line: Unbekannter Schlüssel $key, wird ignoriert.';
  }

  @override
  String settingsFileConflict(String file, String key) {
    return '$file wurde gleichzeitig bearbeitet; sein Wert für $key bleibt.';
  }

  @override
  String settingsFileBrokenSaved(String file, String backup) {
    return '$file hatte Fehler. Die Datei wurde als $backup gesichert und neu geschrieben.';
  }

  @override
  String settingsFileRecreated(String file) {
    return '$file fehlte und wurde neu geschrieben.';
  }

  @override
  String settingsFileWriteFailed(String file) {
    return '$file konnte nicht geschrieben werden. Die Änderung gilt, bis die App geschlossen wird.';
  }

  @override
  String settingsFileReadFailed(String file) {
    return '$file konnte nicht gelesen werden. Die eingebauten Einstellungen gelten.';
  }

  @override
  String get deskKitReachTorOff => 'Die Prüfung geht nur ohne Tor.';

  @override
  String get deskSetBackupServersTitle => 'Server aus dieser Datei übernehmen?';

  @override
  String get deskSetBackupServersBody =>
      'Ihre Listen der Nodes und Epicbox-Server weichen von denen dieses Computers ab. Alle Wallets hier nutzen dieselben Listen.';

  @override
  String get deskSetBackupServersKeep => 'Die dieses Computers';

  @override
  String get deskSetBackupServersUse => 'Die der Datei';

  @override
  String get deskSlNoNodeTitle => 'Kein Node eingerichtet';

  @override
  String get deskSlNoNodeText =>
      'Die Node-Liste ist leer. Fügen Sie einen Node hinzu, um Guthaben zu prüfen und zu senden.';

  @override
  String get deskSlNoEpicboxTitle => 'Kein Epicbox-Server eingerichtet';

  @override
  String get deskSlNoEpicboxText =>
      'Die Liste der Epicbox-Server ist leer. Fügen Sie einen Server hinzu, um eine Epicbox-Adresse zu erhalten.';

  @override
  String get devicesOneOnly =>
      'Es kann ein Gerät verknüpft sein. Zum Verknüpfen eines anderen zuerst dieses entfernen.';

  @override
  String txReceivedOnDevice(String device) {
    return 'Empfangen auf $device';
  }

  @override
  String txSpokenReceivedOnDevice(String device, String amount) {
    return 'Empfangen auf $device, $amount';
  }

  @override
  String txDetailsDeviceIn(String device) {
    return '$device, mit dieser Wallet verknüpft, hat diese Coins empfangen.';
  }

  @override
  String get deskOnbNodeAdvanced => 'Erweitert';

  @override
  String deskOnbNodePortsSub(String api, String p2p) {
    return 'API $api · P2P $p2p';
  }

  @override
  String get deskOnbNodeApiPort => 'API-Port';

  @override
  String get deskOnbNodeP2pPort => 'P2P-Port';

  @override
  String get deskOnbNodePortsWhy =>
      'Nur nötig, wenn ein anderer Node auf diesem Computer oder im Netzwerk diese Ports nutzt.';

  @override
  String deskOnbNodePortRange(String min, String max) {
    return 'Eine Zahl von $min bis $max.';
  }

  @override
  String get deskOnbNodePortsSame =>
      'Die beiden Ports müssen sich unterscheiden.';

  @override
  String deskOnbNodePortTaken(String port, String next) {
    return 'Port $port wird von einem anderen Programm genutzt. $next ist frei.';
  }

  @override
  String deskOnbNodePortUse(String port) {
    return '$port nutzen';
  }

  @override
  String get deskSetLnodePorts => 'Ports';

  @override
  String get deskSetLnodePortsTitle => 'Node-Ports';

  @override
  String get deskSetLnodePortsDesc =>
      'Die Ports, auf denen der mitgelieferte Node lauscht.';

  @override
  String get deskSetLnodePortsRestart =>
      'Der Node startet mit den neuen Ports neu.';

  @override
  String get deskSetLnodePortsSaved => 'Ports gespeichert';

  @override
  String get deskSetLnodePortsRestarting => 'Der Node startet neu.';

  @override
  String get deskSetLnodePortsNotSaved => 'Ports nicht gespeichert';

  @override
  String get deskKitInfoLabel => 'Weitere Informationen';

  @override
  String get advModeNodeOnly => 'Nur Node';

  @override
  String get advModeKillSwitch => 'Notaus';

  @override
  String get advModeStandardHintHere =>
      'Verbindet sich direkt. Wählen Sie Nur Tor, um über Tor zu verbinden.';

  @override
  String get advModeStandardHintNoTor =>
      'Verbindet sich direkt mit dem Node und den Diensten, die Sie nutzen.';

  @override
  String get advModeTorOnlyHint =>
      'Alles läuft über Tor. Nichts verbindet sich, bis Tor bereit ist.';

  @override
  String get advModeNodeOnlyHint =>
      'Nur der verwendete Node verbindet sich. Direkt · QR und Direkt · Datei funktionieren.';

  @override
  String get advModeKillSwitchHint =>
      'Nichts verbindet sich. Die Wallet arbeitet offline mit dem zuletzt bekannten Guthaben, Zahlungen laufen per Datei oder QR-Code.';

  @override
  String advModeConfirmTitle(String mode) {
    return 'Zu „$mode“ wechseln?';
  }

  @override
  String advModeConfirmBody(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zahlungen warten über Epicbox oder Link auf den Empfänger. Sie pausieren und laufen weiter, wenn Sie „$mode“ verlassen. Nichts wird abgebrochen.',
      one:
          '1 Zahlung wartet über Epicbox oder Link auf den Empfänger. Sie pausiert und läuft weiter, wenn Sie „$mode“ verlassen. Nichts wird abgebrochen.',
    );
    return '$_temp0';
  }

  @override
  String get advModeConfirmSwitch => 'Wechseln';

  @override
  String netMarkSemanticsDesk(String mode) {
    return 'Netzwerkmodus: $mode. Zeigt, was er bewirkt.';
  }

  @override
  String get netMarkLineTorOnly => 'Jede Verbindung läuft über Tor.';

  @override
  String get netMarkLineTorWaiting =>
      'Wartet auf Tor. Nichts verbindet sich, bis es bereit ist.';

  @override
  String get netMarkLineNodeOnly =>
      'Nur der verwendete Node. Epicbox, Link, Updates und Kurs sind aus.';

  @override
  String get netMarkLineKillSwitch =>
      'Nichts verbindet sich. Guthaben und Verlauf sind, wie zuletzt gesehen.';

  @override
  String get netMarkChange => 'Ändern';

  @override
  String statusOffByMode(String mode) {
    return 'Aus ($mode)';
  }

  @override
  String get statusOffByModeDetail =>
      'Vom Netzwerkmodus ausgeschaltet. Ändern unter Einstellungen › Erweitert › Netzwerk.';

  @override
  String get statusOffByModeDetailNet =>
      'Vom Netzwerkmodus ausgeschaltet. Ändern unter Einstellungen › Netzwerk & Datenschutz.';

  @override
  String get netBlockEpicboxNodeOnly =>
      '„Nur Node“ ist an: Epicbox ist aus. Direkt · QR-Zahlung und Direkt · Dateiübertragung funktionieren.';

  @override
  String get netBlockLinkNodeOnly =>
      '„Nur Node“ ist an: Link ist aus. Direkt · QR-Zahlung und Direkt · Dateiübertragung funktionieren.';

  @override
  String get netBlockSendKillSwitch =>
      '„Notaus“ ist an: Nichts verbindet sich. Direkt · QR-Zahlung und Direkt · Dateiübertragung funktionieren.';

  @override
  String get netBlockNodeOnly => 'Aus bei „Nur Node“.';

  @override
  String get netBlockKillSwitch => 'Aus bei „Notaus“: Nichts verbindet sich.';

  @override
  String get netBlockWaitingForTorLong =>
      'Wartet auf Tor. Nichts verbindet sich, bis es bereit ist.';

  @override
  String receiveEpicboxOffMode(String mode) {
    return 'Epicbox ist bei „$mode“ aus.';
  }

  @override
  String receiveEpicboxOffModeBody(String mode) {
    return 'Zahlungen an diese Adresse warten auf dem Epicbox-Server und kommen an, sobald Sie „$mode“ verlassen.';
  }

  @override
  String receiveLinkOffMode(String mode) {
    return 'Der Link-Empfang ist bei „$mode“ aus.';
  }

  @override
  String updatesOffMode(String mode) {
    return 'Die Update-Prüfung ist bei „$mode“ aus.';
  }

  @override
  String reportOffMode(String mode) {
    return 'Aus bei „$mode“. Speichern Sie den Bericht stattdessen als Datei.';
  }

  @override
  String get recheckOffKill =>
      '„Guthaben neu prüfen“ braucht den Node. Aus bei „Notaus“.';

  @override
  String get postFinishedOffKill =>
      'Aus bei „Notaus“: Hier verbindet sich nichts.';

  @override
  String get postFinishedOffTor =>
      'Wartet auf Tor. Das Senden braucht den Node.';

  @override
  String get browserOffTorOnly =>
      'Öffnet sich außerhalb von Tor. Kopieren Sie stattdessen den Link.';

  @override
  String browserOffMode(String mode) {
    return 'Aus bei „$mode“. Kopieren Sie stattdessen den Link.';
  }

  @override
  String get netChangeLink => 'Ändern';

  @override
  String get lastKnownCaption => 'Zuletzt bekannt';

  @override
  String get lastKnownList => 'Zuletzt bekannt · Notaus';

  @override
  String lastKnownConfirming(String text) {
    return '$text · zuletzt bekannt';
  }

  @override
  String get coldNeedsOnlineCheck =>
      'Braucht zuerst eine Guthabenprüfung online.';

  @override
  String get finalizeNotPostedTitle => 'Abgeschlossen, nicht gesendet';

  @override
  String finalizeNotPostedBody(String amount) {
    return '$amount sind abgeschlossen. „Notaus“ ist an, daher kann dieses Smartphone die Zahlung nicht senden: Speichern Sie sie oder zeigen Sie sie als QR-Code für ein Gerät, das online ist.';
  }

  @override
  String get finishedSaveFile => 'Datei speichern';

  @override
  String get finishedShowQr => 'QR zeigen';

  @override
  String finishedSaved(String name) {
    return '$name gespeichert';
  }

  @override
  String get finishedQrTitle => 'Fertige Zahlung';

  @override
  String get finishedUnavailable =>
      'Diese Version kann eine fertige Zahlung noch nicht speichern.';

  @override
  String get finishedFailed =>
      'Die fertige Zahlung konnte nicht gelesen werden.';

  @override
  String get txPostElsewhere => 'Wird anderswo gesendet';

  @override
  String get txPostElsewhereKill =>
      'Unter „Notaus“ abgeschlossen. Speichern Sie sie oder zeigen Sie den QR-Code und senden Sie sie dann von einem Gerät, das online ist.';

  @override
  String get txPostElsewhereAfter =>
      'Unter „Notaus“ abgeschlossen, noch nicht in der Chain. Senden Sie sie von hier, oder warten Sie auf das Gerät, das sie gesendet hat.';

  @override
  String get txPostNow => 'Jetzt senden';

  @override
  String get txModeFinishedKill => 'Unter „Notaus“ abgeschlossen';

  @override
  String get txModeRow => 'Modus';

  @override
  String get postFinishedTitle => 'Fertige Zahlung senden';

  @override
  String get postFinishedIntro =>
      'Senden Sie eine Zahlung, die ein anderes Gerät unter „Notaus“ abgeschlossen hat.';

  @override
  String get postFinishedIntroOffline =>
      'Eine Zahlung senden, die ein anderes Gerät ohne Verbindung abgeschlossen hat.';

  @override
  String get postFinishedOpenFile => 'Datei öffnen';

  @override
  String get postFinishedScanQr => 'QR scannen';

  @override
  String get postFinishedPaste => 'Einfügen';

  @override
  String get postFinishedChooseFile => 'Datei wählen';

  @override
  String get postFinishedSummary => 'Fertige Zahlung';

  @override
  String get postFinishedAmount => 'Betrag';

  @override
  String get postFinishedFee => 'Gebühr';

  @override
  String get postFinishedKernel => 'Kernel';

  @override
  String get postFinishedNote =>
      'Das Senden bringt sie ins Netzwerk. Die Wallet, die sie erstellt hat, zeigt sie als bestätigend, sobald sie sie in der Chain sieht.';

  @override
  String get postFinishedPost => 'Senden';

  @override
  String get postFinishedPosting => 'Wird gesendet …';

  @override
  String get postFinishedDone => 'An das Netzwerk gesendet';

  @override
  String get postFinishedDoneBody =>
      'Der Node hat sie. Die Wallet, die sie erstellt hat, zeigt sie als bestätigend, sobald sie sie in der Chain sieht.';

  @override
  String get postFinishedNotFinished =>
      'Keine fertige Zahlung. Öffnen Sie die Datei, die unter „Wird anderswo gesendet“ gespeichert wurde, oder scannen Sie ihren QR-Code.';

  @override
  String get postFinishedFailed =>
      'Der Node hat sie nicht angenommen. Versuchen Sie es erneut.';

  @override
  String get postFinishedUnreachable => 'Der Node antwortet nicht.';

  @override
  String get postFinishedDeskRow => 'Fertige Zahlung senden';

  @override
  String get postFinishedDeskRowText =>
      'Senden Sie eine Zahlung, die ein anderes Gerät unter „Notaus“ abgeschlossen hat.';

  @override
  String get postFinishedOpen => 'Öffnen';

  @override
  String deskFinNotPostedKillBody(String amount) {
    return '$amount sind abgeschlossen. „Notaus“ ist an, daher kann dieser Computer die Zahlung nicht senden. Speichern oder kopieren Sie sie und senden Sie sie dann von einem Gerät, das online ist: Empfangen › Transaktionsdateien › Fertige Zahlung senden.';
  }

  @override
  String netMarkRowLabel(String mode) {
    return 'Netzwerkmodus: $mode';
  }

  @override
  String get qrStatusFinishedHidden => 'Verborgen';

  @override
  String get qrStatusFinishedShowing =>
      'Wartet darauf, dass ein Gerät online scannt.';

  @override
  String qrShowSubFinished(String amount) {
    return '$amount, abgeschlossen';
  }

  @override
  String qrSemanticsFinished(String state) {
    return 'QR-Code der fertigen Zahlung, $state';
  }

  @override
  String get qrHiddenBodyFinished =>
      'Zeigen Sie ihn einem Gerät, das online ist. Es sendet die Zahlung; dafür ist kein Schlüssel nötig.';

  @override
  String get qrScanFinished => 'Fertige Zahlung scannen';

  @override
  String get qrScanNotFinished => 'Dieser Code ist keine fertige Zahlung.';

  @override
  String get qrScanAimFinished =>
      'Richten Sie die Kamera auf den Code des anderen Geräts.';

  @override
  String get deskRailOpenNetwork => 'Netzwerk-Einstellungen öffnen';

  @override
  String get cancelFeeLine => 'Kostet die normale Netzwerkgebühr.';

  @override
  String get cancelForSure => 'Sicher stornieren';

  @override
  String get cancelStopWaiting => 'Nicht mehr warten';

  @override
  String get cancelStopWaitingLine =>
      'Kostenlos. Die Zahlung kann noch durchgehen.';

  @override
  String get cancelMoveBack => 'Coins zurückholen';

  @override
  String cancelMoveBackFee(String fee) {
    return 'Coins zurückholen · Gebühr $fee';
  }

  @override
  String get cancelUnlockOpen => 'Coins freigeben, Zahlung offen lassen';

  @override
  String get cancelCompareMoveBack =>
      'Coins zurückholen: sicher, gegen die Netzwerkgebühr.';

  @override
  String get cancelCompareUnlock =>
      'Coins freigeben: kostenlos, die Zahlung kann noch durchgehen.';

  @override
  String get cancelChoicesTitle => 'Zwei Wege zu stornieren';

  @override
  String get cancelChoicesWhy =>
      'Sicher stornieren schickt die Coins zuerst an diese Wallet zurück, gegen die normale Netzwerkgebühr. Danach kann die alte Zahlung nie mehr durchgehen; das ist der sichere Weg.\n\nNicht mehr warten ist kostenlos und verschiebt nichts. Die Coins sind wieder ausgebbar, und die Zahlung bleibt, wie sie ist. Schließt die andere Seite sie später doch ab, geht sie durch und erscheint als bezahlt; wenn nicht, passiert nichts.';

  @override
  String get cancelStoppedWaitingTitle => 'Warten beendet';

  @override
  String get cancelStoppedWaitingText =>
      'Die Coins sind wieder ausgebbar. Die Zahlung kann noch durchgehen; wenn ja, erscheint sie als bezahlt.';

  @override
  String get txDetailsStoppedWaiting =>
      'Warten beendet. Die Coins sind wieder ausgebbar. Die Zahlung kann noch durchgehen; wenn ja, erscheint sie als bezahlt.';

  @override
  String get errorPaymentCancelledCoinsMoved =>
      'Diese Zahlung wurde storniert, und ihre Coins wurden bereits verschoben. Sie kann nicht mehr durchgehen.';

  @override
  String get errorPaymentAlreadyWentThrough =>
      'Die Coins konnten nicht zurückgeschickt werden: Die Zahlung selbst ist bereits durchgegangen. Sie erscheint als bezahlt.';

  @override
  String get errorPinKeyLost =>
      'Die PIN öffnet diese Wallet nicht mehr. Tippen Sie auf „PIN vergessen?“ und stellen Sie die Wallet mit ihrer Wiederherstellungsphrase wieder her. Die Coins bleiben auf der Chain und lassen sich nur mit dieser Phrase wiederherstellen, und mit der Passphrase, falls eine festgelegt wurde.';

  @override
  String get errorKeystoreRefused =>
      'Das Telefon hat den Wallet-Schlüssel nicht freigegeben. Entsperren Sie das Telefon mit seiner eigenen PIN oder seinem Fingerabdruck und versuchen Sie es dann erneut.';

  @override
  String get unlockTryAgain => 'Erneut versuchen';

  @override
  String get settingsUsePassphrase => 'Passphrase verwenden';

  @override
  String get settingsChangePassphrase => 'Passphrase ändern';

  @override
  String get passphraseLabel => 'Passphrase';

  @override
  String passphraseChoose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wählen Sie eine Passphrase mit mindestens $count Zeichen, nicht nur Ziffern',
    );
    return '$_temp0';
  }

  @override
  String get passphraseRepeat => 'Passphrase wiederholen';

  @override
  String get passphraseMismatch => 'Die beiden Passphrasen sind verschieden';

  @override
  String get passphraseSet => 'Passphrase festgelegt';

  @override
  String get passphraseSetBiometricsOff =>
      'Passphrase festgelegt. Schalten Sie biometrisches Entsperren unten wieder ein.';

  @override
  String get passphraseForgot => 'Passphrase vergessen?';

  @override
  String get passphrasePromptTitle => 'Passphrase eingeben';

  @override
  String get passphraseEnterCurrent => 'Geben Sie Ihre aktuelle Passphrase ein';

  @override
  String get passphraseCurrentLabel => 'Aktuelle Passphrase';

  @override
  String get passphraseChooseTitle => 'Passphrase wählen';

  @override
  String passphraseRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mindestens $count Zeichen und nicht nur Ziffern.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseUsePinInstead => 'Stattdessen PIN verwenden';

  @override
  String get passphraseUsePassphraseInstead =>
      'Stattdessen Passphrase verwenden';

  @override
  String get invoicePassphraseReason =>
      'Geben Sie Ihre Passphrase ein, um diese Rechnung zu bezahlen.';

  @override
  String get restoreReplacePassphraseReason =>
      'Geben Sie Ihre Passphrase ein, um diese Wallet zu ersetzen. Die wiederhergestellte Wallet behält diese Passphrase.';

  @override
  String get backupPassphraseReason =>
      'Geben Sie Ihre Passphrase ein, um die Wiederherstellungsphrase anzuzeigen.';

  @override
  String sendQrPassphraseReason(String amount) {
    return 'Geben Sie Ihre Passphrase ein, um einen Zahlungs-QR über $amount zu erstellen.';
  }

  @override
  String get settingsBiometricsPassphraseReason =>
      'Geben Sie Ihre Passphrase ein, um die biometrische Entsperrung zu aktivieren.';

  @override
  String get settingsDeletePassphraseReason =>
      'Geben Sie Ihre Passphrase ein, um diese Wallet zu löschen.';

  @override
  String sendPassphraseReason(String amount) {
    return 'Geben Sie Ihre Passphrase ein, um $amount zu senden.';
  }

  @override
  String sendFilePassphraseReason(String amount) {
    return 'Geben Sie Ihre Passphrase ein, um eine Transaktionsdatei über $amount zu erstellen.';
  }

  @override
  String get passphraseSetTitle => 'Passphrase festlegen';

  @override
  String get deskSetReportFullDetails => 'Alle Details mitsenden';

  @override
  String get deskSetReportPartFullDetails => 'Alle Details';

  @override
  String get deskSetReportFullDetailsInfo =>
      'Sendet Adressen und Beträge unverkürzt. Wiederherstellungsphrasen, Schlüssel und Passwörter werden zuvor entfernt; prüfen Sie die Vorschau vor dem Senden.';

  @override
  String get deskOutNoteWaitingRecipient => 'wartet auf den Empfänger';

  @override
  String get deskSlotNotPosted => 'Zahlung nicht im Netzwerk';

  @override
  String get txOtherWalletMore => 'Zahlungen einer anderen Wallet';

  @override
  String get finalizeNotPostedHelp => 'Zahlen mit „Notaus“';

  @override
  String get deskActSearchHintFull => 'Notiz, Kontakt, Adresse oder Betrag';

  @override
  String get deskOutFilterWaiting => 'Wartend';

  @override
  String deskRecvHeaderTip(String methods) {
    return 'Empfang: $methods';
  }

  @override
  String deskSendHintNeedsMethod(String method) {
    return 'Prüfen braucht $method';
  }

  @override
  String get deskSetAboutVersionLabel => 'Version';

  @override
  String get deskSetAboutNodeLabel => 'Node';

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
      other: 'Bestätigt, $confirmationsString Bestätigungen · Block $block.',
      one: 'Bestätigt, $confirmationsString Bestätigung · Block $block.',
    );
    return '$_temp0';
  }

  @override
  String deskKitNoAnswerSince(String time) {
    return 'Keine Antwort seit $time';
  }

  @override
  String get deskKitMoreInHelp => 'Mehr in der Hilfe';

  @override
  String get homeReceiveEpicButton => 'EPIC empfangen';

  @override
  String txDeviceStatusMadeOn(String device) {
    return 'Erstellt auf $device.';
  }

  @override
  String txDeviceStatusHeld(String device) {
    return 'Erstellt auf $device. Das Geld bleibt hier gehalten, bis die Chain die Zahlung zeigt.';
  }

  @override
  String get deskSendEpicboxNodeOnly =>
      '„Nur Node“ ist an: Epicbox ist aus. Direkt · Dateiübertragung funktioniert.';

  @override
  String deskSendEpicboxNodeOnlyTab(String method) {
    return '„Nur Node“ ist an: Epicbox ist aus. $method funktioniert.';
  }

  @override
  String get deskSendLinkNodeOnly =>
      '„Nur Node“ ist an: Link ist aus. Direkt · Dateiübertragung funktioniert.';

  @override
  String deskSendLinkNodeOnlyTab(String method) {
    return '„Nur Node“ ist an: Link ist aus. $method funktioniert.';
  }

  @override
  String get deskSendKillSwitch =>
      '„Notaus“ ist an: Nichts verbindet sich. Direkt · Dateiübertragung funktioniert.';

  @override
  String deskSendKillSwitchTab(String method) {
    return '„Notaus“ ist an: Nichts verbindet sich. $method funktioniert.';
  }

  @override
  String get levelOneTitle => 'Nur senden und empfangen';

  @override
  String get levelOneLine => 'Geld rein, Geld raus. Nichts zu lernen.';

  @override
  String get levelTwoTitle => 'Nicht zu technisch, aber sag mir, was passiert';

  @override
  String get levelTwoLine => 'Klare Worte dazu, was die Wallet gerade tut.';

  @override
  String get levelThreeTitle => 'Ich will alles erkunden';

  @override
  String get levelThreeLine =>
      'Jeder Schalter, jede Zahl. Vorsicht bei den Reglern.';

  @override
  String get levelUndercoverTitle => 'Nur Tor';

  @override
  String get levelFooter =>
      'Jederzeit änderbar unter Einstellungen › Erweitert.';

  @override
  String get levelRowTitle => 'Wallet-Ansicht';

  @override
  String get levelChangeTitle => 'Ansicht ändern';

  @override
  String get lvPickStopOne => 'Flach';

  @override
  String get lvPickStopTwo => 'Tiefer';

  @override
  String get lvPickStopThree => 'Ganz tief';

  @override
  String get lvPickLineOne =>
      'Senden, empfangen, fertig. Den Rest erledigt die Wallet.';

  @override
  String get lvPickLineTwo =>
      'Sehen Sie, was sie gerade tut, in einfachen Worten.';

  @override
  String get lvPickLineThree =>
      'Jeder Schalter, jede Zahl. Alles gehört Ihnen.';

  @override
  String get lvPickNone => 'Wählen Sie eine Stufe';

  @override
  String get lvPickNoneLine => 'Die Vorschau folgt dem Regler.';

  @override
  String get lvPickDepth => 'Ansicht';

  @override
  String get lvPickPreview =>
      'Vorschau des Startbildschirms. Sie zeigt mehr, je tiefer der Regler steht.';

  @override
  String get lvPickHelpTitle => 'Was das bestimmt';

  @override
  String get lvPickHelpText =>
      'Nur, wie viel die App zeigt. Jede Ansicht sendet und empfängt gleich, mit denselben Schlüsseln und denselben Coins.';

  @override
  String get lvPickUndercoverHelp =>
      'Nur Tor, ab der ersten Verbindung. Jede Verbindung läuft über Tor; der Start dauert länger.\n\nBisher wurde nichts verbunden. Wie Netzwerkmodus › Nur Tor; lässt sich später unter Einstellungen › Erweitert ausschalten.';

  @override
  String get lvPickUndercoverHelpNet =>
      'Nur Tor, ab der ersten Verbindung. Jede Verbindung läuft über Tor; der Start dauert länger.\n\nBisher wurde nichts verbunden. Wie Verbindungsmodus › Nur Tor; lässt sich später unter Einstellungen › Netzwerk & Datenschutz ausschalten.';

  @override
  String get lvPickUndercover => 'Inkognito';

  @override
  String get lvPickUndercoverLaterHelp =>
      'Nur Tor. Jede Verbindung läuft über Tor; der Start dauert länger. Wo Tor gesperrt ist, kann die Wallet sich erst verbinden, wenn das aus ist.';

  @override
  String get lvPickTakesEffect => 'Gilt sofort.';

  @override
  String get lvPickSaved => 'Ansicht gespeichert';

  @override
  String get lvPickTorTitle => 'Verbindung über Tor';

  @override
  String get lvPickTorLead =>
      'Die erste Verbindung über Tor kann eine Minute dauern.';

  @override
  String get lvPickTorBusy => 'Verbindung wird aufgebaut…';

  @override
  String get lvPickTorBlocked =>
      'Ist Tor bei Ihnen gesperrt, kann die Wallet sich erst verbinden, wenn Inkognito aus ist.';

  @override
  String get lvPickTorOff => 'Inkognito ausschalten';

  @override
  String get lvPickTorOffDone => 'Inkognito ist aus. Direkte Verbindung.';

  @override
  String get lvPickNetworkOk => 'Netzwerk OK';

  @override
  String get lvPickEpicboxOk => 'Epicbox OK';

  @override
  String get lvPayArriving => 'Unterwegs';

  @override
  String lvPayConfirming(int count, int target) {
    return 'Bestätigung $count von $target';
  }

  @override
  String lvPayConfirmingOf(int count, int target) {
    return 'Bestätigung $count von $target';
  }

  @override
  String lvPaySigned(String name) {
    return '$name hat signiert';
  }

  @override
  String get lvPaySendQrLink => 'Beide Handys da? QR-Zahlung';

  @override
  String get lvPaySendAddressLink => 'Stattdessen an eine Adresse senden';

  @override
  String get lvPayOnItsWay => 'Unterwegs';

  @override
  String get lvPayCloseNote =>
      'Sie können das schließen. Die Zahlung steht unter Aktivität, bis sie fertig ist.';

  @override
  String lvPayArrivalFrom(String amount, String name) {
    return '$amount von $name';
  }

  @override
  String get lvPayOpen => 'Öffnen';

  @override
  String get lvPayNewToday => 'Neu heute';

  @override
  String get lvPayNewAddress => 'Ihre neue Adresse';

  @override
  String lvPayServerLine(String name) {
    return 'Epicbox-Server: $name.';
  }

  @override
  String get lvPayOldAddressLine =>
      'Wer die alte Adresse hat, braucht die neue.';

  @override
  String get lvPayReceiveBack => 'Zurück zu meiner Adresse';

  @override
  String lvPayDoneSent(String when) {
    return 'Gesendet. Fertig: $when.';
  }

  @override
  String lvPayDoneReceived(String when) {
    return 'Empfangen. Fertig: $when.';
  }

  @override
  String get lvPayShowSteps => 'Schritte anzeigen';

  @override
  String get lvPayHideSteps => 'Schritte ausblenden';

  @override
  String get lvPayDetails => 'Details';

  @override
  String get lvPayStarted => 'Gestartet';

  @override
  String get lvPayPosted => 'An das Netzwerk gesendet';

  @override
  String get lvPayPaymentId => 'Zahlungs-ID';

  @override
  String get lvPayConfirmations => 'Bestätigungen';

  @override
  String lvPayOf(int count, int target) {
    return '$count von $target';
  }

  @override
  String get lvPayCopyDetails => 'Details kopieren';

  @override
  String get lvPayDetailsCopied => 'Details kopiert';

  @override
  String lvShellStatusTip(String name, String state) {
    return '$name · $state';
  }

  @override
  String get lvShellStateBehind => 'Im Rückstand';

  @override
  String get lvShellStateCatchingUp => 'Holt auf';

  @override
  String get lvShellStateConnecting => 'Verbindet';

  @override
  String get lvShellOpensDetails => 'Zeigt Details';

  @override
  String get lvShellLatestBlock => 'Neuester Block';

  @override
  String get lvShellThisWallet => 'Diese Wallet';

  @override
  String get lvShellUpToDate => 'Aktuell';

  @override
  String get lvShellNotChecked => 'Noch nicht geprüft';

  @override
  String get lvShellLastChange => 'Letzte Änderung';

  @override
  String get lvShellBoxListening => 'Verbunden · wartet auf Zahlungen';

  @override
  String get lvShellBoxNotReachable => 'Nicht erreichbar · versucht es weiter';

  @override
  String get lvShellBoxDownBody =>
      'Zahlungen an Sie warten und kommen an, sobald der Server zurück ist. Nichts ändert sich, solange Sie nicht wechseln.';

  @override
  String lvShellOfferReady(String name) {
    return '$name ist bereit';
  }

  @override
  String lvShellOfferBody(String name) {
    return 'Ein Wechsel gibt Ihnen eine neue Adresse bei $name. Wer Ihre alte Adresse hat, braucht die neue.';
  }

  @override
  String lvShellSwitchTo(String name) {
    return 'Zu $name wechseln';
  }

  @override
  String get lvShellKeepWaiting => 'Weiter warten';

  @override
  String get lvShellRelayDownTitle =>
      'Ihr Epicbox-Server ist nicht erreichbar.';

  @override
  String lvShellRelayDownShort(String name) {
    return '$name kann übernehmen; Ihre Adresse ändert sich damit.';
  }

  @override
  String get lvShellSwitch => 'Wechseln';

  @override
  String lvShellSwitchedNotice(String name) {
    return 'Jetzt bei $name. Ihre neue Adresse ist bereit.';
  }

  @override
  String lvShellNowOn(String name) {
    return 'Jetzt bei $name';
  }

  @override
  String get lvShellSwitchedBody =>
      'Ihre neue Adresse ist bereit. Wer Ihre alte Adresse hat, braucht die neue.';

  @override
  String get lvShellShowNewAddress => 'Neue Adresse zeigen';

  @override
  String get lvShellServer => 'Server';

  @override
  String get lvShellAddress => 'Adresse';

  @override
  String lvShellPairNotice(String name) {
    return '$name möchte sich mit dieser Wallet koppeln.';
  }

  @override
  String get lvShellSeeRequest => 'Anfrage ansehen';

  @override
  String lvShellQuietArriving(String amount) {
    return '+$amount unterwegs';
  }

  @override
  String lvShellQuietOnHold(String amount) {
    return '$amount zurückgehalten';
  }

  @override
  String get lvShellLevelCaption =>
      'Eine tiefere Ansicht zeigt mehr von der Wallet. Gespeichertes ändert sich nicht.';

  @override
  String get lvPolPosted => 'Gesendet';

  @override
  String get lvPolInvoiceWaiting => 'Rechnung · wartet auf Ihre Zustimmung';

  @override
  String lvPolAbout(String name) {
    return 'Über $name';
  }

  @override
  String get deskLvStartPreviewLabel =>
      'Vorschau der Übersicht. Sie zeigt mehr, je tiefer der Regler steht.';

  @override
  String get deskLvStartPreviewCaption =>
      'Ihre Übersicht in dieser Ansicht. Gespeichert wird nichts anders.';

  @override
  String get deskLvStartCover => 'Stufe wählen, um die Vorschau zu sehen';

  @override
  String get deskLvStartUndercoverAbout => 'Über Nur Tor';

  @override
  String get deskLvStartHelpShallow =>
      'Flach · eine Adresse, keine Servernamen, keine Schalter.';

  @override
  String get deskLvStartHelpDeeper =>
      'Tiefer · dieselbe Wallet, dazu, was sie gerade tut, in einfachen Worten.';

  @override
  String get deskLvStartHelpDeep =>
      'Ganz tief · jeder Schalter, jede Zahl: die App von heute.';

  @override
  String get deskLvStartMiniWallet => 'Hauptwallet';

  @override
  String get deskLvStartMiniLine => '+12,5 kommen an · 25,0 gehalten';

  @override
  String get deskLvStartMiniFresh => 'Frisch vom Mining';

  @override
  String get deskLvStartMiniWaiting => 'Wartet auf die Gegenseite';

  @override
  String get deskLvSendHowTo => 'So senden';

  @override
  String get deskLvSendButton => 'Senden';

  @override
  String deskLvSendButtonAmount(String amount) {
    return '$amount EPIC senden';
  }

  @override
  String deskLvSendButtonTo(String amount, String name) {
    return '$amount EPIC an $name senden';
  }

  @override
  String get deskLvSendNothingLeaves =>
      'Nichts verlässt die Wallet, bevor Sie auf Senden drücken. Danach lässt es sich nicht zurücknehmen.';

  @override
  String get deskLvSendPasswordTitle => 'Ihr Passwort';

  @override
  String get deskLvSendConfirm => 'Senden';

  @override
  String deskLvSendLiveTo(String name) {
    return 'Unterwegs zu $name';
  }

  @override
  String deskLvSendLiveAmountTo(String amount, String name) {
    return '$amount EPIC an $name';
  }

  @override
  String deskLvSendLiveAmount(String amount) {
    return '$amount EPIC';
  }

  @override
  String get deskLvSendYourAddress => 'Ihre Adresse';

  @override
  String get deskLvSendReady => 'Bereit zum Empfangen';

  @override
  String get deskLvSendClosedInfo =>
      'Zahlungen, die gesendet wurden, während die Wallet geschlossen war, kommen an, sobald sie sich öffnet.';

  @override
  String get deskLvSendPayFiles => 'Zahlungsdateien';

  @override
  String get deskLvSendSignFile => 'Zahlungsdatei signieren';

  @override
  String get deskLvSendSignFileText =>
      'Öffnen Sie die Datei des Absenders und speichern Sie Ihre Antwort.';

  @override
  String get deskLvSendFinishFile => 'Antwortdatei abschließen';

  @override
  String get deskLvSendFinishFileText =>
      'Öffnen Sie die erhaltene Antwort, um die Zahlung zu senden.';

  @override
  String get deskLvSendPrevAddress => 'Frühere Adresse';

  @override
  String deskLvSendPrevText(String server) {
    return 'Die alte Adresse lag auf $server. Wer sie hat, braucht die neue.';
  }

  @override
  String get deskLvPayS1Sent =>
      'Slate S1 über Epicbox gesendet · wartet auf S2';

  @override
  String deskLvPayS1On(String relay) {
    return 'S1 auf $relay · wartet auf S2';
  }

  @override
  String deskLvPayNotOpen(String name) {
    return 'Die Wallet von $name ist noch nicht geöffnet';
  }

  @override
  String deskLvPayWaitingOpen(String name) {
    return 'Warten, bis die Wallet von $name sich öffnet';
  }

  @override
  String get deskLvPaySenderFinished => 'Absender fertig';

  @override
  String get deskLvPayPostedNode => 'An Node gesendet';

  @override
  String deskLvPayConfirmingComma(int count, int target) {
    return 'Wird bestätigt, $count von $target';
  }

  @override
  String deskLvPayConfirmationsOf(int count, int target) {
    return 'Bestätigungen $count / $target';
  }

  @override
  String get deskLvPayDone => 'Fertig';

  @override
  String deskLvPayOnItsWayTo(String name) {
    return 'Unterwegs zu $name';
  }

  @override
  String deskLvPaySendingTo(String name) {
    return 'Senden an $name';
  }

  @override
  String deskLvPayArrivingFrom(String name) {
    return 'Kommt von $name';
  }

  @override
  String deskLvPayStartedAt(String amount, String time) {
    return '$amount EPIC · gestartet $time';
  }

  @override
  String deskLvPayHeroArriving(String amount, String name) {
    return '+$amount kommen von $name';
  }

  @override
  String deskLvPayHeroArrivingMany(String amount) {
    return '+$amount kommen an';
  }

  @override
  String deskLvPayHeroHold(String amount, String name) {
    return '$amount gehalten, bis $name signiert';
  }

  @override
  String deskLvPayHeroHoldMany(String amount) {
    return '$amount gehalten, bis signiert wird';
  }

  @override
  String get deskLvPayHeroNothing => 'Noch nichts unterwegs.';

  @override
  String get deskLvPayReadyTitle => 'Ihre Wallet ist bereit.';

  @override
  String get deskLvPayReadyHead => 'Wallet bereit';

  @override
  String get deskLvPayReadyText =>
      'Adresse teilen, um die ersten EPIC zu erhalten.';

  @override
  String get deskLvPayTileConfirming => 'Wird noch bestätigt';

  @override
  String get deskLvPayTileMining => 'Frisch vom Mining';

  @override
  String get deskLvPayTileWaiting => 'Wartet auf die Gegenseite';

  @override
  String get deskLvPayTileAwaiting => 'Wartet auf Antwort';

  @override
  String get deskLvPayTileLocked => 'Für Sendungen reserviert';

  @override
  String get deskLvPayImmatureCasual =>
      'Frisch vom Mining, noch nicht verfügbar';

  @override
  String get deskLvPayKind => 'Zahlung';

  @override
  String get deskLvShellNewsTitle => 'Neu: Wallet-Ansicht';

  @override
  String get deskLvShellNewsText =>
      'Diese Installation zeigt wie bisher alles. Flach und Tiefer zeigen weniger.';

  @override
  String get deskLvShellNewsLook => 'Ansehen';

  @override
  String get deskLvShellFailover => 'Node-Wechsel';

  @override
  String get deskLvShellOn => 'Ein';

  @override
  String get deskLvShellHeight => 'Höhe';

  @override
  String get deskLvShellVersion => 'Version';

  @override
  String get deskLvShellRecheckHint =>
      'Wirkt der Betrag falsch, liest die Wallet die Chain erneut.';

  @override
  String get lvShellSwitchServer => 'Server wechseln';

  @override
  String get lvShellNoOtherServer => 'Kein anderer Server in der Liste.';

  @override
  String get deskLvShellSwitchServer => 'Server wechseln';

  @override
  String get deskLvShellNoOtherServer => 'Keine anderen Server in der Liste.';

  @override
  String get deskLastSessionFroze =>
      'Die App hat beim letzten Mal nicht mehr reagiert. Protokoll senden?';

  @override
  String get deskLastSessionClosed =>
      'Die App wurde beim letzten Mal unerwartet beendet. Protokoll senden?';

  @override
  String get deskLastSessionSend => 'Senden';

  @override
  String get deskLastSessionNotNow => 'Nicht jetzt';

  @override
  String get deskLastSessionReportFroze => 'Die App hat nicht mehr reagiert.';

  @override
  String get deskLastSessionReportClosed => 'Die App wurde unerwartet beendet.';

  @override
  String get deskLastSessionAttached =>
      'Mit dem Protokoll der letzten Sitzung.';

  @override
  String get deskSetPrivUndercoverLine => 'Inkognito lässt Tor eingeschaltet.';

  @override
  String get deskSetPrivUndercoverChange => 'Inkognito ändern';

  @override
  String get deskNodeEtaCalculating => 'Restzeit wird berechnet…';

  @override
  String deskNodeEtaLeft(String time) {
    return 'noch etwa $time';
  }

  @override
  String get deskNodeEtaMinute => 'eine Minute';

  @override
  String deskNodeEtaMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String deskNodeEtaHours(int hours) {
    return '$hours Std.';
  }

  @override
  String deskNodeEtaHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String deskNodeSwitchConnecting(String host) {
    return 'Verbindung zu $host…';
  }

  @override
  String get deskNodeSwitchStarting => 'Lokaler Node startet…';

  @override
  String get deskNodeSwitchStopping => 'Lokaler Node wird gestoppt…';

  @override
  String get deskNodeSwitchStoppingWord => 'Stoppt';

  @override
  String get deskOnbFailedTitle => 'Nicht abgeschlossen';

  @override
  String deskOnbRestoreBadWords(String words) {
    return 'Nicht in der Wortliste: $words.';
  }

  @override
  String get deskLvPayOnEpicbox => 'Auf Epicbox';

  @override
  String get deskRailReceivingInternet => 'Empfängt · Internet';

  @override
  String get deskRailReceivingLocal => 'Empfängt · lokal';

  @override
  String get deskOnbImportFoundLead =>
      'Weiter, um die Wallets zum Hinzufügen auszuwählen.';

  @override
  String get deskOnbForgotFailedTitle => 'Passwort nicht geändert';

  @override
  String get deskOnbForgotFailedLead =>
      'Das bisherige Passwort öffnet die Wallet weiterhin.';

  @override
  String get deskSetHelpSupportHead => 'Support';

  @override
  String deskKitPasswordRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeichen oder mehr',
      one: '$count Zeichen oder mehr',
    );
    return '$_temp0';
  }

  @override
  String trustLineOtherApp(Object name) {
    return 'Die letzte Zahlung von $name wurde von einer anderen Wallet-App beantwortet.';
  }

  @override
  String trustLineNotHeard(Object name, Object date) {
    return 'Seit $date nichts von der Wallet von $name gehört.';
  }

  @override
  String get mailboxNotAnswered => 'Noch nicht beantwortet';

  @override
  String get mailboxNotPickedUp => 'Nicht abgeholt';

  @override
  String mailboxNeverPickedUp(Object name) {
    return 'Die Wallet von $name hat dies nie abgeholt.';
  }

  @override
  String get mailboxResendTitle =>
      'Stornieren und an die öffentliche Epicbox-Adresse senden';

  @override
  String get mailboxResendTitleShort =>
      'Stornieren und an die öffentliche Adresse senden';

  @override
  String mailboxResendBody(Object name) {
    return 'Die wartende Zahlung wird storniert und derselbe Betrag geht als gewöhnliche Zahlung an die öffentliche Epicbox-Adresse von $name. Beide Zeilen bleiben unter Aktivität.';
  }

  @override
  String get mailboxResendAction => 'Stornieren und senden';

  @override
  String get mailboxKeepWaiting => 'Weiter warten';

  @override
  String get linkPayeeLead => 'Der Empfänger';

  @override
  String get linkPayeeMid => 'der Empfänger';

  @override
  String get linkResendBody =>
      'Die wartende Zahlung wird storniert und Senden öffnet sich mit demselben Betrag. Prüfen Sie die Adresse und senden Sie dann erneut.';

  @override
  String receiptTellSent(Object name) {
    return '$name mitteilen, dass es gesendet ist';
  }

  @override
  String receiptTellPosted(Object name) {
    return '$name mitteilen, dass es im Netzwerk ist';
  }

  @override
  String receiptTold(Object name) {
    return '$name wurde informiert';
  }

  @override
  String receiptSeesSent(Object name, Object id, Object amount, Object time) {
    return '$name sieht: Anfrage $id, $amount, gesendet $time. Mehr wird nicht übermittelt: keine Adresse und keine Transaktions-ID.';
  }

  @override
  String receiptSeesPosted(Object name, Object id, Object amount, Object time) {
    return '$name sieht: Anfrage $id, $amount, im Netzwerk um $time. Mehr wird nicht übermittelt: keine Adresse und keine Transaktions-ID.';
  }

  @override
  String receiptNotSent(Object name) {
    return '$name konnte gerade nicht informiert werden. Versuchen Sie es erneut.';
  }

  @override
  String get receiptHintTitle => 'Beleg';

  @override
  String get mailboxResent =>
      'Storniert und an die öffentliche Epicbox-Adresse gesendet.';

  @override
  String get torRelayCaption =>
      'Mit Tor läuft die Verbindung zum Epicbox-Server über Tor.';

  @override
  String get inviteLinkUnreadable => 'Dieser Link lässt sich nicht öffnen.';

  @override
  String inviteLinkNoHandler(String feature) {
    return '$feature ist ausgeschaltet oder in dieser Wallet nicht verfügbar.';
  }

  @override
  String get linkShowMine => 'Meinen QR zeigen';

  @override
  String get linkPasteAnother => 'Andere Einladung einfügen';

  @override
  String linkLinkingWith(String name) {
    return 'Verknüpfung mit $name…';
  }

  @override
  String linkLinkingSame(String name) {
    return '$name zeigt dieselben vier.';
  }

  @override
  String linkFailFull(String name) {
    return '$name ist schon mit einem anderen Gerät verknüpft. Dieses zuerst auf $name entfernen.';
  }

  @override
  String get linkFailUpdate =>
      'Das andere Gerät hat eine neuere App. Diese aktualisieren und erneut versuchen.';

  @override
  String linkFailUpdateOther(String name) {
    return '$name hat eine ältere App. Dort aktualisieren und erneut versuchen.';
  }

  @override
  String linkReplaceTitle(String name) {
    return '$name ersetzen?';
  }

  @override
  String linkReplaceBody(String name) {
    return 'Ein neues Gerät möchte sich verknüpfen. $name erhält keine Meldungen dieser Wallet mehr; Münzen, die es hier zurückhält, werden freigegeben.';
  }

  @override
  String get linkReplace => 'Ersetzen';

  @override
  String linkKeep(String name) {
    return '$name behalten';
  }

  @override
  String devicesEpicboxOff(String name) {
    return 'Epicbox ist aus: $name sieht die Zahlungen dieses Geräts nicht.';
  }

  @override
  String get devicesEpicboxOffNone => 'Epicbox ist aus.';

  @override
  String devicesUpdateOther(String name) {
    return '$name aktualisieren, damit diese Wallet abgeglichen bleibt.';
  }

  @override
  String get devicesAbout => 'Über das verknüpfte Gerät';

  @override
  String get offerLinkThird =>
      'Ein drittes Gerät hat diese Wallet. Zwei lassen sich verknüpfen.';

  @override
  String devicesForwardedInvoice(String name) {
    return '$name hat eine Zahlungsanfrage erhalten. Dort bezahlen.';
  }

  @override
  String get linkConfirmInvite =>
      'Dieses Gerät mit dem verknüpfen, das die Einladung gesendet hat?';

  @override
  String get pairYourCode => 'Ihre Einladung';

  @override
  String get pairCodeCaption =>
      'Lassen Sie sie den QR scannen, oder senden Sie die Einladung.';

  @override
  String pairCodeCaptionFor(String name) {
    return 'Lassen Sie $name den QR scannen, oder senden Sie die Einladung.';
  }

  @override
  String pairSeenAsLine(String name) {
    return 'Der Kontakt sieht Sie als $name';
  }

  @override
  String get pairChange => 'Ändern';

  @override
  String get pairSeenAsField => 'Der Kontakt sieht Sie als';

  @override
  String get pairCopyLink => 'Einladung kopieren';

  @override
  String get pairHaveTheirCode => 'Haben Sie ihre Einladung?';

  @override
  String pairHaveNamesCode(String name) {
    return 'Haben Sie die Einladung von $name?';
  }

  @override
  String get pairScan => 'QR scannen';

  @override
  String get pairPasteField => 'Einladung einfügen';

  @override
  String get pairNotACode => 'Keine Kopplungs-Einladung.';

  @override
  String get pairEpicboxOffLine =>
      'Epicbox ist aus. Fügen Sie die Antwort unten ein, wenn sie zurückkommt.';

  @override
  String get pairWaitingAnswer => 'Warten auf die Antwort …';

  @override
  String pairAnsweredFinishing(String name) {
    return '$name hat Ihre Einladung beantwortet. Warten, bis die Wallet von $name fertig ist.';
  }

  @override
  String get pairFinishCodeTitle => 'Bestätigung';

  @override
  String pairFinishCodeBody(String name) {
    return 'Senden Sie das an $name. Die Wortprüfung öffnet sich, sobald diese Wallet es liest.';
  }

  @override
  String get pairYourAnswerBody =>
      'Senden Sie sie auf dem Weg zurück, auf dem die Einladung kam. Fügen Sie dann ein, was zurückkommt.';

  @override
  String get pairPasteFinishField => 'Bestätigung einfügen';

  @override
  String pairPairingWith(String name) {
    return 'Koppeln mit $name …';
  }

  @override
  String get pairInContacts => 'In Ihren Kontakten';

  @override
  String get pairRequestBody =>
      'Eine Anfrage geht an die Epicbox-Adresse dieses Kontakts. Seine Wallet zeigt sie, wenn sie offen ist.';

  @override
  String get pairSendRequest => 'Anfrage senden';

  @override
  String get pairShowMyCodeInstead => 'Stattdessen meine Einladung zeigen';

  @override
  String pairRequestSent(String date) {
    return 'Anfrage gesendet · $date';
  }

  @override
  String pairWaitingFor(String name) {
    return 'Warten auf die Wallet von $name';
  }

  @override
  String get pairAnsweredNotHeard =>
      'Hat Ihre Einladung beantwortet · noch nichts gehört';

  @override
  String pairNotChecked(String name) {
    return '$name hat noch nicht geprüft';
  }

  @override
  String contactTakesPaymentsAgain(String name) {
    return '$name nimmt wieder Zahlungen an.';
  }

  @override
  String get pairIsService => 'Automatisierter Dienst.';

  @override
  String pairConfirmedToo(String name) {
    return '$name hat auch bestätigt.';
  }

  @override
  String get pairEndedShort => 'Kopplung beendet';

  @override
  String get pairEndedMismatch =>
      'Sie haben gemeldet, dass die Wörter nicht übereinstimmen.';

  @override
  String pairEndedPeerMismatch(String name) {
    return '$name hat gemeldet, dass die Wörter nicht übereinstimmen.';
  }

  @override
  String pairEndedNeverFinished(String name) {
    return 'Die Wallet von $name hat nie abgeschlossen.';
  }

  @override
  String get pairEndedRowPeerMismatch =>
      'Hat gemeldet, dass die Wörter nicht übereinstimmen.';

  @override
  String get pairEndedRowNeverFinished => 'Die Wallet hat nie abgeschlossen.';

  @override
  String get pairEndedRowUnpaired => 'Hat die Kopplung entfernt.';

  @override
  String pairNoAnswerFrom(String name) {
    return 'Keine Antwort von der Wallet von $name';
  }

  @override
  String get pairAgain => 'Erneut koppeln';

  @override
  String get pairAddressNotConfirmed =>
      'Adresse nicht durch die Kopplung bestätigt.';

  @override
  String get pairHeldSend => 'Wartet auf Empfänger';

  @override
  String pairProvesOther(String name) {
    return 'Die Wallet von $name belegt eine andere Adresse';
  }

  @override
  String get pairUpdateAddress => 'Adresse des Kontakts aktualisieren';

  @override
  String get pairDetach => 'Trennen';

  @override
  String get pairCheckWords => 'Wörter prüfen';

  @override
  String pairWantsToPair(String name) {
    return '$name möchte koppeln.';
  }

  @override
  String pairPairedWith(String name) {
    return 'Gekoppelt mit $name.';
  }

  @override
  String pairPairedOn(String device) {
    return 'Gekoppelt auf $device.';
  }

  @override
  String pairRequestsRow(int count) {
    return 'Kopplungsanfragen · $count';
  }

  @override
  String get pairRequestsTitle => 'Kopplungsanfragen';

  @override
  String get pairEndedNotice =>
      'Die Kopplung ist beendet. Koppeln Sie erneut mit einer frischen Einladung.';

  @override
  String get pairOtherWalletTitle =>
      'Diese Antwort kam von einer anderen Wallet.';

  @override
  String get pairOtherWalletBody => 'Nichts wurde gespeichert.';

  @override
  String get pairKindDiffersTitle => 'Diese Antwort passt nicht zur Einladung.';

  @override
  String get pairKindDiffersBody =>
      'Sie nennt eine andere Kontaktart als die Einladung. Nichts wurde gespeichert. Koppeln Sie erneut.';

  @override
  String pairNotProvenBody(String name) {
    return 'Noch keine Epic-Cash-Zahlung mit $name, daher kann keine Anfrage gesendet werden.';
  }

  @override
  String pairInProgressTitle(String name) {
    return 'Eine Kopplung mit $name läuft bereits.';
  }

  @override
  String pairCrossedTitle(String name) {
    return 'Die Wallet von $name hat ebenfalls eine Kopplung gestartet. Warten auf ihre Antwort.';
  }

  @override
  String pairDismissedTitle(String name) {
    return 'Diese Anfrage wurde abgelehnt. Bitten Sie $name um eine neue.';
  }

  @override
  String get pairEndedBody =>
      'Nichts Neues geht mehr hindurch. Entferne sie, oder kopple erneut mit einer frischen Einladung.';

  @override
  String get pairWaitingSendBody => 'Stattdessen per Epicbox senden.';

  @override
  String get pairNotFoundTitle => 'Keine Kopplung passt dazu.';

  @override
  String get trustWaiting => 'Wartet';

  @override
  String get trustEnded => 'Beendet';

  @override
  String get trustNotAnswering => 'Antwortet nicht';

  @override
  String get contactNotAnsweringBody =>
      'Rechnungen und Zahlungen erreichen sie womöglich nicht.';

  @override
  String get pairRequestPair => 'Koppeln';

  @override
  String get pairCancelPairingTitle => 'Diese Kopplung abbrechen?';

  @override
  String pairCancelPairingBody(String name) {
    return 'Die Wallet von $name erfährt es, falls sie spät antwortet. Nichts wird behalten.';
  }

  @override
  String get pairCancelPairing => 'Kopplung abbrechen';

  @override
  String get pairBackLater => 'Zurück';

  @override
  String get helpPairRouteTitle => 'Zahlungen nach dem Koppeln';

  @override
  String helpPairRouteShort(String paired) {
    return 'Einem gekoppelten Kontakt können Sie mit der Option $paired oder an die öffentliche Epicbox-Adresse zahlen.';
  }

  @override
  String helpPairRouteP1(String paired) {
    return 'Nach dem Koppeln hat ein Kontakt unter [[Senden|Send]] zwei Optionen: **$paired** und **Öffentliche Adresse**. Zuerst ist **$paired** gewählt, und die Zahlung wird versiegelt: Nur dieser Kontakt kann sie lesen.';
  }

  @override
  String get helpPairRouteP2 =>
      'Gekoppelte Zahlungen laufen weiterhin über Epicbox. Der Epicbox-Server wird beim Koppeln vorgeschlagen. Die Wallet übernimmt ihn nur, wenn er schon in ihrer Serverliste steht; sonst fragt sie Sie. Für einen Epicbox-Server ist eine gekoppelte Zahlung eine verschlüsselte Nachricht wie jede andere.';

  @override
  String helpPairRouteP3(String paired) {
    return 'Die Option **$paired** nutzt eigene Schlüssel, und ihre Adresse wird nicht angezeigt. Nur ein gekoppelter Kontakt kann Ihnen eine Rechnung senden.';
  }

  @override
  String helpPairRouteP4(String paired) {
    return 'Stattdessen ist **Öffentliche Adresse** gewählt, wenn: der Kontakt zuletzt aus einer anderen Wallet-App geantwortet hat; vom Kontakt lange nichts zu hören war; eine Zahlung mit **$paired** unbeantwortet blieb; oder sein Server ausgefallen ist. Bleibt eine Zahlung unbeantwortet, erscheint **Stornieren und an die öffentliche Epicbox-Adresse senden**. Die Wallet fragt zuerst.';
  }

  @override
  String get helpPairRouteP5 =>
      '**Transaktionsdateien versiegeln** auf der Kontaktseite verschlüsselt Dateien an diesen Kontakt. Der Schalter betrifft nur Dateien; die Adresse ändert er nicht. Ein Kontakt, der per Einladung oder QR gekoppelt wurde, hat keine öffentliche Epicbox-Adresse, es sei denn, Sie fügen unter [[Kontakte|Contacts]] eine hinzu.';

  @override
  String get helpPairTwoWaysTitle => 'Zwei Wege zum Koppeln';

  @override
  String get helpPairTwoWaysShort =>
      'Eine Anfrage an einen Kontakt, oder Ihre Einladung.';

  @override
  String get helpPairTwoWaysP1 =>
      '**Mit einem Kontakt koppeln.** Bei einem Kontakt, dem Sie über Epicbox gezahlt haben oder von dem Sie Zahlungen erhalten haben, sendet Koppeln eine Anfrage an diese Adresse. Seine Wallet zeigt sie, wenn sie offen ist; ein Tipp antwortet. Beide Wallets enden Verifiziert ohne Wortprüfung: Anfrage und Antwort belegen jeweils die Adresse, die schon in den Kontakten der anderen Seite steht.';

  @override
  String get helpPairTwoWaysP2 =>
      '**Per Einladung koppeln.** Kontakte › Koppeln zeigt Ihre Einladung, 7 Tage gültig. Die andere Wallet scannt sie oder öffnet den Link; beide schließen über Epicbox ab und vergleichen dann die vier Wörter. Ist Epicbox auf einer Seite aus, trägt derselbe Bildschirm Antwort und Bestätigung von Hand: Teilen und Einfügen.';

  @override
  String get helpPairTwoWaysP3 =>
      'Eine Anfrage geht nur an eine Wallet, die gezeigt hat, dass sie BT Wallet ausführt: eine markierte Zahlung zwischen den beiden Adressen in den letzten 30 Tagen. Für alle anderen zeigt Koppeln Ihre Einladung.';

  @override
  String get helpPairWhyTitle2 => 'Warum die Wörter prüfen';

  @override
  String get helpPairWhyShort2 =>
      'Vergleicht sie persönlich, per Sprache oder Video.';

  @override
  String get helpPairWhyP1b =>
      'Nach dem Koppeln per Einladung zeigen beide Wallets dieselben vier Bilder und Namen. Vergleichen Sie sie mit der anderen Person persönlich, per Sprache oder in einem Videoanruf, nie in dem Chat, durch den die Einladung kam: Wer die Einladung unterwegs ändern könnte, könnte auch ändern, was dieser Chat zeigt.';

  @override
  String get helpPairWhyP2b =>
      '**Sie stimmen überein** markiert den Kontakt als Verifiziert; die andere Wallet erfährt es und zeigt „hat auch bestätigt“. **Sie stimmen nicht überein** beendet die Kopplung auf beiden Seiten, und nichts, was hindurch gesendet wurde, wird abgeschlossen. Ein versehentliches Nein beendet sie ebenfalls: kopple erneut mit einer frischen Einladung.';

  @override
  String get helpPairWhyP3b =>
      'Verifiziert bedeutet: die Wallet hinter der Adresse in Ihren Kontakten. Nach einer Anfrage zwischen zwei Kontakten wird es ohne Wörter gesetzt, weil Anfrage und Antwort diese Adresse jeweils belegt haben.';

  @override
  String get helpPairWhyP4b =>
      '„Belegt“ heißt: Eine von beiden Wallets markierte Zahlung ist in den letzten 30 Tagen zwischen den beiden Epicbox-Adressen gelaufen. Ein Kontakt, der seitdem von einer anderen Wallet-App beantwortet wurde, gilt bis zur nächsten markierten Zahlung nicht als belegt.';

  @override
  String get pairStandingFootnote =>
      'Gültig für 7 Tage. Eine neue Einladung erscheint, sobald diese benutzt wurde.';

  @override
  String get storeEncrypting => 'Wallet-Daten werden verschlüsselt…';

  @override
  String get storeRecordsPlain =>
      'Die Wallet-Daten bleiben vorerst unverschlüsselt. Beim nächsten Start wird es erneut versucht.';

  @override
  String get errorStoreWrongKey =>
      'Die Daten dieser Wallet ließen sich mit dieser Phrase nicht öffnen. Nichts wurde geändert.';

  @override
  String get contactsClosedTitle => 'Adressbuch geschlossen';

  @override
  String get contactsClosedText =>
      'Es öffnet sich, sobald eine Wallet entsperrt wird, die es nutzt.';

  @override
  String get pairSeenAsHint => 'Optional';

  @override
  String devicesNameWithCode(String name, String code) {
    return '$name $code';
  }

  @override
  String get deskSetDlgRemoveUnlockHintSecurity =>
      'Um auch ihre Dateien zu löschen, entsperren Sie diese Wallet und nutzen Sie „Wallet löschen“ unter Einstellungen › Wallet.';

  @override
  String get deskRecvHttpTorHintNet =>
      'Schalten Sie Link · Tor unter Einstellungen › Zahlungen ein, um stattdessen eine Tor-Adresse zu erhalten.';

  @override
  String get deskRecvTorIntroNet =>
      'Direkt von einer anderen Wallet über Tor, solange diese geöffnet ist. Link · Tor wird unter Einstellungen › Zahlungen eingestellt.';

  @override
  String get deskRecvTorOffTextNet =>
      'Die Tor-Adresse funktioniert, solange Tor an ist. Tor ist der Schalter unter Einstellungen › Netzwerk & Datenschutz; er leitet die Verbindungen der Wallet über Tor.';

  @override
  String get deskRailOpenNetworkPrivacy => 'Netzwerk & Datenschutz öffnen';

  @override
  String get deskSetSearchHint => 'Einstellungen durchsuchen';

  @override
  String get deskSetSearchKeyHint => 'Strg K';

  @override
  String get deskSetSearchClear => 'Suche leeren';

  @override
  String deskSetSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '1 Treffer',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchFor(String query) {
    return 'für „$query“';
  }

  @override
  String get deskSetSearchKeysMove => 'wählen';

  @override
  String get deskSetSearchKeysGo => 'zur Einstellung';

  @override
  String get deskSetSearchKeysClear => 'leeren';

  @override
  String deskSetSearchMatches(String word) {
    return 'Passt zu „$word“';
  }

  @override
  String get deskSetSearchHelpTopics => 'Hilfethemen';

  @override
  String get deskSetSearchHidden => 'Hier ausgeblendet';

  @override
  String get deskSetSearchHiddenLine =>
      'Eine andere Ansicht oder ein Schalter unter Erweitert zeigt sie';

  @override
  String deskSetSearchShowIn(String view) {
    return 'In $view zeigen';
  }

  @override
  String get deskSetSearchTurnOn => 'Einschalten';

  @override
  String get deskSetSearchOpen => 'Öffnen';

  @override
  String get deskSetSearchRead => 'Lesen';

  @override
  String deskSetSearchNone(String query) {
    return 'Keine Einstellung passt zu „$query“.';
  }

  @override
  String get deskSetSearchTry => 'Versuchen Sie';

  @override
  String get deskSetSearchTryWords =>
      'passwort,tor,seed,sicherung,gebühr,node,sperre';

  @override
  String get deskSetSearchNoResults => 'Keine Treffer';

  @override
  String get deskSetSearchResults => 'Suchergebnisse';

  @override
  String deskSetSearchViewGate(String view) {
    return 'Ansicht $view';
  }

  @override
  String deskSetSearchFeatGate(String feature) {
    return 'Erweitert › $feature';
  }

  @override
  String deskSetSearchGateJoin(String first, String last) {
    return '$first und $last';
  }

  @override
  String deskSetSearchMore(int count, String gates) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Optionen · gezeigt mit $gates',
      one: '1 weitere Option · gezeigt mit $gates',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchLess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die $count zusätzlichen Optionen ausblenden',
      one: 'Die zusätzliche Option ausblenden',
    );
    return '$_temp0';
  }

  @override
  String deskSetSearchViewApplied(String view) {
    return 'Ansicht: $view';
  }

  @override
  String deskSetSearchFeatApplied(String feature) {
    return 'Erweitert › $feature: an';
  }

  @override
  String deskSetSearchFallbackView(String page, String view) {
    return '$page gibt es in der Ansicht $view.';
  }

  @override
  String deskSetSearchFallbackFeat(String page, String feature) {
    return '$page erscheint mit Erweitert › $feature.';
  }

  @override
  String get deskSetSecWallet => 'Wallet';

  @override
  String get deskSetSecDevices => 'Verknüpfte Geräte';

  @override
  String get deskSetSecWallets => 'Wallets';

  @override
  String get deskSetSecFiles => 'Dateien & Protokolle';

  @override
  String get deskSetNavApp => 'App';

  @override
  String get deskSetNavComputer => 'Dieser Computer';

  @override
  String get deskSetGrpBackup => 'Sicherung';

  @override
  String get deskSetGrpBalance => 'Guthaben';

  @override
  String get deskSetGrpRemove => 'Entfernen';

  @override
  String get deskSetGrpMethods => 'Methoden';

  @override
  String get deskSetGrpSending => 'Senden';

  @override
  String get deskSetGrpReceiving => 'Empfangen';

  @override
  String get deskSetGrpThisDevice => 'Dieses Gerät';

  @override
  String get deskSetGrpLinkedDevice => 'Verknüpftes Gerät';

  @override
  String get deskSetGrpSync => 'Abgleich';

  @override
  String get deskSetGrpConnection => 'Verbindung';

  @override
  String get deskSetGrpLocalNode => 'Node auf diesem Computer';

  @override
  String get deskSetGrpConnections => 'Verbindungen';

  @override
  String get deskSetGrpTor => 'Tor';

  @override
  String get deskSetGrpServerStatus => 'Serverstatus';

  @override
  String get deskSetGrpView => 'Ansicht';

  @override
  String get deskSetGrpShowsMore => 'Zeigt mehr';

  @override
  String get deskSetGrpOnComputer => 'Auf diesem Computer';

  @override
  String get deskSetGrpAddWallet => 'Wallet hinzufügen';

  @override
  String get deskSetGrpFolders => 'Ordner';

  @override
  String get deskSetGrpLogs => 'Protokolle';

  @override
  String get deskSetGrpSupport => 'Support';

  @override
  String get deskSetGrpStartAgain => 'Neu beginnen';

  @override
  String get deskSetGrpLinks => 'Links';

  @override
  String get deskSetRowNameHint => 'Nur in dieser App zu sehen.';

  @override
  String get deskSetSynName => 'umbenennen, wallet-name, bezeichnung, name';

  @override
  String get deskSetRowExportDataHint =>
      'Verlauf, Kontakte, Rechnungen und Einstellungen in einer verschlüsselten Datei.';

  @override
  String get deskSetRowExportDataInfo =>
      'Nur eine Wallet mit dieser Seed-Phrase kann die Datei öffnen. Die Coins selbst stellt die Seed-Phrase wieder her.';

  @override
  String get deskSetSynExportData =>
      'sicherung, backup, speichern, verlauf, kontakte, datei';

  @override
  String get deskSetRowImportDataHint =>
      'Holt Verlauf, Kontakte, Rechnungen und Einstellungen aus einem Export zurück.';

  @override
  String get deskSetSynImportData =>
      'wiederherstellen, sicherung, backup, verlauf, laden';

  @override
  String get deskSetRowExportCsvHint =>
      'Eine einfache Tabelle für Tabellenkalkulationen. Nicht verschlüsselt.';

  @override
  String get deskSetSynExportCsv =>
      'csv, excel, tabelle, steuer, verlauf, bericht';

  @override
  String get deskSetRowRecheckGoHint =>
      'Liest die Chain erneut nach den Coins dieser Wallet.';

  @override
  String get deskSetSynRecheckGo =>
      'neu scannen, scan, guthaben falsch, fehlt, resync, aktualisieren, reparieren';

  @override
  String get deskSetRowDeleteWalletHint =>
      'Löscht ihre Schlüssel und Datenbank von diesem Computer.';

  @override
  String get deskSetSynDeleteWallet => 'entfernen, löschen, tilgen';

  @override
  String get deskSetSynRecheckFrom => 'start, datum, höhe, block';

  @override
  String get deskSetRowRecheckDropHint =>
      'Bricht auch unbestätigte Transaktionen ab. Eine Zahlung unterwegs kann dann scheitern.';

  @override
  String get deskSetSynRecheckDrop =>
      'unbestätigt, hängt, abbrechen, freigeben';

  @override
  String get deskSetRowPhraseGoHint =>
      'Die 24 Wörter, die diese Wallet wiederherstellen.';

  @override
  String get deskSetSynPhraseGo =>
      'seed, mnemonic, wörter, sicherung, geheim, wiederherstellen, 24 wörter, privater schlüssel';

  @override
  String get deskSetRowPasswordHint => 'Entsperrt diese Wallet.';

  @override
  String get deskSetSynPassword =>
      'passwort, kennwort, passwort ändern, entsperren, pin';

  @override
  String get deskSetRowRememberedHint =>
      'Öffnet beim Start ohne Passwort. Beim Senden wird es weiter abgefragt.';

  @override
  String get deskSetSynRemembered =>
      'merken, passwort, entsperren, automatisch entsperren, vergessen';

  @override
  String get deskSetRowAutolockHint =>
      'Sperrt, wenn keine Taste gedrückt und die Maus nicht bewegt wird. Alle Wallets.';

  @override
  String get deskSetSynAutolock =>
      'sperre, zeitlimit, leerlauf, inaktivität, bildschirmsperre';

  @override
  String get deskSetRowEpicboxHint =>
      'Bezahlen und bezahlt werden über einen Epicbox-Server. Die meisten Zahlungen laufen so. Alle Wallets.';

  @override
  String get deskSetSynEpicbox =>
      'relay, server, adresse, empfangen, senden, methode';

  @override
  String get deskSetSynEpicboxRecv => 'lauschen, eingehend, empfangen';

  @override
  String get deskSetRowEpicboxServerHint => 'Teil der Adresse dieser Wallet.';

  @override
  String get deskSetSynEpicboxServer => 'relay, server, host, adresse';

  @override
  String get deskSetSynEpicboxStart => 'autostart, beim start';

  @override
  String get deskSetRowHttpHint =>
      'Wallet zu Wallet an einer Webadresse, solange beide offen sind. Alle Wallets.';

  @override
  String get deskSetSynHttp => 'http, ip, port, direkt, listener, methode';

  @override
  String get deskSetSynHttpReach =>
      'internet, router, portweiterleitung, öffentlich';

  @override
  String get deskSetSynHttpPort => 'port, tcp';

  @override
  String get deskSetRowTorPayHint =>
      'Wallet zu Wallet an der Tor-Adresse dieser Wallet, solange beide offen sind. Alle Wallets.';

  @override
  String get deskSetRowTorPayInfo =>
      'Tor läuft nur, um Zahlungen an der Tor-Adresse zu senden und zu empfangen. Node, Preise und Updates folgen der Einstellung unter Netzwerk & Datenschutz.';

  @override
  String get deskSetSynTorPay =>
      'tor, onion, hidden service, datenschutz, methode';

  @override
  String get deskSetRowFileHint =>
      'Durch Übergabe einer Transaktionsdatei. Kein Netzwerk nötig. Alle Wallets.';

  @override
  String get deskSetSynFile =>
      'datei, offline, slate, tx-datei, usb, methode, manuell';

  @override
  String get deskSetRowDefaultMethodHint =>
      'Womit Senden öffnet. Alle Wallets.';

  @override
  String get deskSetSynDefaultMethod => 'senden, methode, standard';

  @override
  String get deskSetRowStrategy => 'Outputs, die ein Senden ausgibt';

  @override
  String get deskSetRowStrategyHint =>
      'Kleinste deckt den Betrag; Alle gibt jeden Output aus.';

  @override
  String get deskSetRowStrategyInfo =>
      'Mehr ausgegebene Outputs bedeuten eine höhere Gebühr.';

  @override
  String get deskSetSynStrategy =>
      'gebühr, gebühren, strategie, coin-auswahl, inputs, utxo, outputs';

  @override
  String get deskSetRowSplitChangeHint =>
      'Wechselgeld kommt als bis zu 4 Outputs zurück, wenn nur wenige übrig sind.';

  @override
  String get deskSetRowSplitChangeInfo =>
      'Nur wenn ein Senden weniger als 3 verfügbare Outputs übrig ließe und das Wechselgeld mindestens 1 EPIC beträgt. Jeder zusätzliche Output kostet 0,004 EPIC.';

  @override
  String get deskSetSynSplitChange =>
      'gebühr, wechselgeld, outputs, utxo, teilen';

  @override
  String get deskSetRowConfirmationsHint =>
      'Blöcke, die eine empfangene Zahlung wartet, bevor sie ausgegeben werden kann.';

  @override
  String get deskSetSynConfirmations =>
      'bestätigen, blöcke, verfügbar, gesperrt, ausstehend, warten';

  @override
  String get deskSetRowPairShopHint =>
      'Ein gekoppelter Kontakt, dem Sie es erlauben, kann dieser Wallet Rechnungen senden.';

  @override
  String get deskSetSynPairShop =>
      'koppeln, kopplung, rechnung, shop, börse, händler';

  @override
  String get deskSetRowTimeToPayHint =>
      'Wie lange eine Rechnung bezahlbar bleibt.';

  @override
  String get deskSetSynTimeToPay => 'rechnung, ablauf, verfällt, frist';

  @override
  String get deskSetSynDeviceName => 'gerätename, umbenennen';

  @override
  String get deskSetRowLinkDeviceHint =>
      'Diese Wallet auf zwei Geräten: jedes zeigt die Zahlungen des anderen.';

  @override
  String get deskSetRowLinkDeviceInfo =>
      'Ein Gerät kann verknüpft werden. Verknüpfte Geräte melden sich gegenseitig, welche Coins sie ausgeben, und wählen daher normalerweise unterschiedliche Coins. Geben beide dieselbe Coin aus, nimmt die Chain eine Zahlung an und die andere schlägt fehl.';

  @override
  String get deskSetSynLinkDevice =>
      'gerät verknüpfen, handy koppeln, zweites gerät, telefon, abgleich, mobil, mehrere geräte';

  @override
  String get deskSetRowPauseSyncHint =>
      'Mitteilungen warten auf den Servern, solange pausiert ist.';

  @override
  String get deskSetSynPauseSync => 'abgleich, sync, pause, verknüpft';

  @override
  String get deskSetSynTheme =>
      'dunkelmodus, hellmodus, farbe, nacht, dark mode';

  @override
  String get deskSetSynLanguage =>
      'sprache, übersetzung, deutsch, english, polski';

  @override
  String get deskSetRowScaleHint =>
      'Text und Bedienelemente, größer oder kleiner.';

  @override
  String get deskSetSynScale =>
      'zoom, größe, schriftgröße, größer, kleiner, textgröße, dpi';

  @override
  String get deskSetRowHideAmountsHint => 'Punkte statt Guthaben und Beträgen.';

  @override
  String get deskSetSynHideAmounts =>
      'datenschutz, guthaben verbergen, maskieren, bildschirmfreigabe, stream';

  @override
  String get deskSetRowNodeServerHint =>
      'Liest die Chain und sendet die Transaktionen dieser Wallet.';

  @override
  String get deskSetSynNodeServer =>
      'node, knoten, server, host, rpc, api, url';

  @override
  String get deskSetRowFailover => 'Node automatisch wechseln';

  @override
  String get deskSetRowFailoverHint =>
      'Antwortet der Node nicht mehr, den nächsten funktionierenden nehmen.';

  @override
  String get deskSetSynFailover => 'failover, ausweich, automatisch';

  @override
  String get deskSetRowMyNodeHint =>
      'Fragt den Node selbst nach seinem Zustand und bietet Besitzerzugriff.';

  @override
  String get deskSetSynMyNode =>
      'eigener node, mein node, selbst gehostet, besitzer, api-secret';

  @override
  String get deskSetRowLocalNode => 'Node auf diesem Computer';

  @override
  String get deskSetRowLocalNodeHint =>
      'Betreibt hier einen eigenen Node. Mehrere Gigabyte Speicher.';

  @override
  String get deskSetSynLocalNode =>
      'lokaler node, eingebauter node, full node, node betreiben, chain synchronisieren';

  @override
  String get deskSetRowLocalStartHint =>
      'Hält den Node synchron, solange die App offen ist.';

  @override
  String get deskSetSynLocalStart => 'autostart, lokaler node';

  @override
  String get deskSetRowNetMode => 'Verbindungsmodus';

  @override
  String get deskSetSynNetMode =>
      'nur tor, undercover, offline, kill switch, nur node, vpn, ip, datenschutz, flugmodus';

  @override
  String get deskSetRowStatusSiteHint =>
      'Zeigt, welche Nodes und Epicbox-Server online sind.';

  @override
  String get deskSetSynStatusSite =>
      'status, zustand, verfügbarkeit, überwachung';

  @override
  String get deskSetRowView => 'Ansicht';

  @override
  String get deskSetRowViewHint =>
      'Flach, Tiefer oder Ganz tief: wie viel der Wallet zu sehen ist.';

  @override
  String get deskSetSynView =>
      'stufe, tiefe, flach, tiefer, ganz tief, einfach, experte, anfänger, erweiterter modus';

  @override
  String get deskSetRowAdvOutputsHint =>
      'Die Seite Outputs: die Coins, aus denen das Guthaben besteht.';

  @override
  String get deskSetSynAdvOutputs =>
      'utxo, coins, outputs, teilen, zusammenführen';

  @override
  String get deskSetRowAdvTechHint =>
      'Kernel, Slate-ID und Commitments bei jeder Transaktion.';

  @override
  String get deskSetSynAdvTech => 'kernel, slate, commitment, tx-id, details';

  @override
  String get deskSetRowAdvSendoptsHint =>
      'Output- und Wechselgeld-Optionen beim Senden und unter Zahlungen.';

  @override
  String get deskSetSynAdvSendopts =>
      'gebühr, coin control, outputs, wechselgeld';

  @override
  String get deskSetRowAdvServersHint =>
      'Hosts, Latenz, Version und Höhe in Serverlisten.';

  @override
  String get deskSetSynAdvServers => 'latenz, ping, höhe, version, host';

  @override
  String get deskSetRowAdvHeightHint =>
      'Wo beginnen und Unbestätigte löschen beim Guthaben neu prüfen.';

  @override
  String get deskSetSynAdvHeight => 'neu scannen, höhe, block';

  @override
  String get deskSetRowAdvLocalHint =>
      'Einen Node auf diesem Computer betreiben, unter Node.';

  @override
  String get deskSetSynAdvLocal => 'full node, lokaler node';

  @override
  String get deskSetRowAdvLogsHint =>
      'Protokollstufe und Protokolldateien unter Dateien & Protokolle.';

  @override
  String get deskSetSynAdvLogs => 'protokoll, log, debug, diagnose';

  @override
  String get deskSetRowWalletRows => 'Wallet-Liste';

  @override
  String get deskSetRowWalletRowsHint =>
      'Die Wallets auf diesem Computer; eine öffnen oder entfernen.';

  @override
  String get deskSetSynWalletRows =>
      'wallets, wallet wechseln, andere wallet, liste';

  @override
  String get deskSetRowCreateWalletHint =>
      'Eine neue Wallet mit neuer Seed-Phrase.';

  @override
  String get deskSetSynCreateWallet => 'neue wallet, wallet hinzufügen';

  @override
  String get deskSetRowImportWalletsHint =>
      'Aus einer älteren Epic Wallet oder einem Ordner.';

  @override
  String get deskSetSynImportWallets =>
      'migrieren, alte wallet, electron, gui-wallet, ordner';

  @override
  String get deskSetRowRestoreWalletHint => 'Aus der 24-Wörter-Seed-Phrase.';

  @override
  String get deskSetSynRestoreWallet => 'seed, wiederherstellen, mnemonic';

  @override
  String get deskSetRowWalletFolderHint =>
      'Schlüssel und Datenbank dieser Wallet.';

  @override
  String get deskSetSynWalletFolder =>
      'datenordner, verzeichnis, pfad, dateien, speicherort';

  @override
  String get deskSetRowAppFilesHint => 'settings.toml und das Protokoll.';

  @override
  String get deskSetSynAppFiles =>
      'einstellungsdatei, settings.toml, konfiguration, toml, verzeichnis';

  @override
  String get deskSetRowLogLevelHint =>
      'Ausführlich behält mehr Zeilen; Berichte lassen Adressen weg.';

  @override
  String get deskSetSynLogLevel => 'protokoll, log, debug, ausführlich';

  @override
  String get deskSetRowLogFilesHint =>
      'Die Protokolldateien leeren oder ihren Ordner öffnen.';

  @override
  String get deskSetSynLogFiles =>
      'protokoll, log, protokolle leeren, protokolle löschen';

  @override
  String get deskSetRowReportHint =>
      'Beschreiben Sie, was schiefging; das bereinigte App-Protokoll kann mitgehen.';

  @override
  String get deskSetSynReport =>
      'fehler, bug, problem, support, absturz, fehlerbericht';

  @override
  String get deskSetSynTour => 'tour, anleitung, einführung, rundgang';

  @override
  String get deskSetRowSetup => 'Einrichtung erneut ausführen';

  @override
  String get deskSetRowSetupHint => 'Node und Empfang, Schritt für Schritt.';

  @override
  String get deskSetSynSetup => 'einrichtung, assistent, neu einrichten, setup';

  @override
  String get deskSetRowUpdatesHint => 'Sucht nach einer neuen Version.';

  @override
  String get deskSetSynUpdates =>
      'update, aktualisierung, neue version, download, release';

  @override
  String get deskSetRowWebsite => 'Website';

  @override
  String get deskSetSynWebsite => 'website, webseite, internet, epic cash';

  @override
  String get deskSetSynSource =>
      'github, quellcode, code, open source, repository';

  @override
  String get deskSetSynPrivacyPolicy => 'datenschutz, richtlinie, dsgvo, daten';

  @override
  String get deskSetAcctBackup => 'Sicherung';

  @override
  String get deskSetAcctBalance => 'Guthaben';

  @override
  String get deskSetAcctRemove => 'Entfernen';

  @override
  String get deskSetAdvViewLineOne =>
      'Senden, Empfangen und Sicherungen. Node und Epicbox-Server werden automatisch gewählt.';

  @override
  String get deskSetAdvViewLineTwo =>
      'Dazu Zahlungsmethoden, der Node, Netzwerkmodi und weitere Wallets.';

  @override
  String get deskSetAdvViewLineThree =>
      'Dazu Outputs, Rechnungen, der lokale Node und jeder Schalter unter Erweitert.';

  @override
  String get deskSetFrameBack => 'Wallet';

  @override
  String get deskSetFrameBackTip => 'Zurück zur Wallet (Esc)';

  @override
  String deskSetFrameBackTo(String page) {
    return 'Zurück zu $page';
  }

  @override
  String get deskSetFrameEscKey => 'Esc';

  @override
  String get deskSetFrameEscHint => 'zurück zur Wallet';

  @override
  String get deskSetFrameExperiment => 'Experiment';

  @override
  String get deskSetHelpReportButton => 'Melden…';

  @override
  String get deskSetHelpSetupAgain => 'Einrichtung erneut ausführen';

  @override
  String get deskSetHelpSetupHint => 'Node und Empfang, Schritt für Schritt.';

  @override
  String get deskSetHelpStartAgain => 'Neu beginnen';

  @override
  String get deskSetHelpTourStart => 'Tour starten';

  @override
  String get deskSetFilesFolders => 'Ordner';

  @override
  String get deskSetNodeConnection => 'Verbindung';

  @override
  String get deskSetNodeFailover => 'Node automatisch wechseln';

  @override
  String get deskSetNodeStatus => 'Status';

  @override
  String get deskSetPrivTorAll => 'Tor für alle Verbindungen';

  @override
  String get deskSetPrivServerStatus => 'Serverstatus';

  @override
  String get deskSetPrivMode => 'Verbindungsmodus';

  @override
  String get deskSetTxSending => 'Senden';

  @override
  String get deskSetTxTorPayHint =>
      'Tor läuft nur, um Zahlungen an der Tor-Adresse zu senden und zu empfangen. Node, Kurse und Updates folgen der Einstellung unter Netzwerk & Datenschutz. Alle Wallets.';

  @override
  String get deskSetWalletsOnComputer => 'Auf diesem Computer';

  @override
  String get deskSetSearchKeyEnter => 'Eingabe';

  @override
  String get deskSetSearchKeyEsc => 'Esc';

  @override
  String get deskTorPayOff => 'Aus';

  @override
  String get deskTorPayStarting => 'Tor startet · nur für Zahlungen';

  @override
  String get deskTorPayReady => 'Empfängt';

  @override
  String deskTorPayBlockedNodeOnly(String mode) {
    return 'Aus in $mode: Nur der Node verbindet sich.';
  }

  @override
  String deskTorPayBlockedKill(String mode) {
    return 'Aus in $mode: Nichts verbindet sich.';
  }

  @override
  String get deskTorPayFailed => 'Tor hat keine Verbindung hergestellt.';

  @override
  String deskTorPayFailedWhy(String problem) {
    return 'Tor hat keine Verbindung hergestellt: $problem.';
  }

  @override
  String get deskTorPayRestOn =>
      'Tor für jede Verbindung: an (Netzwerk & Datenschutz).';

  @override
  String get deskTorPayRestOff =>
      'Tor für jede Verbindung: aus (Netzwerk & Datenschutz).';

  @override
  String get deskRailTorForPayments => 'Für Zahlungen';

  @override
  String get deskBarKeySearch => 'Einstellungen durchsuchen';

  @override
  String get deskBarKeySearchHere => 'Suchen, in den Einstellungen';

  @override
  String get deskHttpLocalTitle => 'Lokales Netzwerk';

  @override
  String get deskHttpLocalSwitch => 'Auf diesem Computer empfangen';

  @override
  String get deskHttpPublicTitle => 'Internet';

  @override
  String deskHttpPublicNote(String port) {
    return 'Für Wallets im Internet. Der Router muss Port $port an diesen Computer weiterleiten.';
  }

  @override
  String deskKitMethodHttpNotReachable(String port) {
    return 'nur im lokalen Netzwerk. Für Zahlungen aus dem Internet muss der Router Port $port an diesen Computer weitergeben.';
  }

  @override
  String get sendRouteLinkHttps => 'Link · HTTPS';

  @override
  String get sendRouteThisPhone => 'Dieses Smartphone';

  @override
  String get sendRouteThisComputer => 'Dieser Computer';

  @override
  String get sendRouteYourNetwork => 'Ihr Netzwerk';

  @override
  String get sendRouteOverTor => 'Über Tor';

  @override
  String get sendRouteTorStarts => 'Tor startet beim Senden.';

  @override
  String get sendRouteChange => 'Ändern';

  @override
  String sendRouteChangeSem(int count) {
    return 'Adresse ändern, $count weitere';
  }

  @override
  String sendRouteAddressesOf(String name) {
    return 'Adressen von $name';
  }

  @override
  String sendRouteMore(int count) {
    return '$count weitere';
  }

  @override
  String sendRouteSemantics(String method, String host) {
    return 'Sendet per $method an $host';
  }

  @override
  String get sendHeldKillSwitch => '„Notaus“ ist an. Nichts verbindet sich.';

  @override
  String get sendHeldNodeOnly =>
      '„Nur Node“ ist an. Nur der Node verbindet sich.';

  @override
  String get sendHeldTorOnly =>
      '„Nur Tor“ ist an. Einfaches http:// kann nicht über Tor laufen.';

  @override
  String get sendHeldTorOn =>
      'Tor ist an. Einfaches http:// kann nicht über Tor laufen.';

  @override
  String get sendHeldFixKillSwitch => '„Notaus“ ausschalten';

  @override
  String get sendHeldFixNodeOnly => '„Nur Node“ ausschalten';

  @override
  String get sendHeldFixTorOnly => '„Nur Tor“ ausschalten';

  @override
  String get sendHeldByKillSwitch => 'Gesperrt durch „Notaus“';

  @override
  String get sendHeldByNodeOnly => 'Gesperrt durch „Nur Node“';

  @override
  String get sendHeldByTorOnly => 'Gesperrt durch „Nur Tor“';

  @override
  String get sendHeldWhileTorOn => 'Gesperrt, solange Tor an ist';

  @override
  String get sendHeldModeNormal => 'Netzwerkmodus: Normal.';

  @override
  String get sendHeldTorIsOff => 'Tor ist aus.';

  @override
  String get sendNoAddress => 'Keine Adresse?';

  @override
  String get sendWithoutConnection => 'Ohne Verbindung:';

  @override
  String get sendPayInPerson => 'Persönlich bezahlen';

  @override
  String get sendPayByFile => 'Per Datei bezahlen';

  @override
  String get sendIsSlateText => 'Das ist ein Transaktionstext, keine Adresse.';

  @override
  String get sendOpenSlateText => 'Öffnen';

  @override
  String get sendSendsTo => 'Sendet an';

  @override
  String get sendProblemNotAddress =>
      'Keine Adresse, und kein Kontakt hat diesen Namen.';

  @override
  String get sendProblemOtherScheme =>
      'Keine Adresse, an die diese Wallet zahlen kann.';

  @override
  String get sendProblemIncomplete => 'Diese Adresse scheint unvollständig.';

  @override
  String get sendProblemOnion =>
      'Das ist keine vollständige Tor-Adresse. Kopieren Sie sie erneut vom Empfänger.';

  @override
  String get sendProblemPort => 'Der Port muss zwischen 1 und 65535 liegen.';

  @override
  String get sendProblemCredentials =>
      'An eine Adresse mit Benutzernamen kann nicht gezahlt werden.';

  @override
  String get sendProblemCharacters =>
      'Diese Adresse enthält Zeichen, die eine Adresse nicht enthalten kann.';

  @override
  String get sendProblemTooLong => 'Diese Adresse ist zu lang.';

  @override
  String get sendProblemOwn => 'Das ist die eigene Adresse dieser Wallet.';

  @override
  String get sendReachChecking => 'Wird geprüft…';

  @override
  String sendReachNone(String host) {
    return 'Unter $host antwortet keine Wallet.';
  }

  @override
  String sendReachNotWallet(String host) {
    return 'Unter $host antwortet etwas, aber keine Epic-Wallet.';
  }

  @override
  String get sendReachTheirOnion => 'der Tor-Adresse des Empfängers';

  @override
  String get sendReachOpenFirst =>
      'Die Wallet des Empfängers muss zum Empfangen geöffnet sein.';

  @override
  String get sendReachCheckAddress =>
      'Prüfen Sie die Adresse mit dem Empfänger.';

  @override
  String get sendReachTryAgain => 'Erneut versuchen';

  @override
  String get sendFactVia => 'Über';

  @override
  String get sendFactHost => 'Host';

  @override
  String get sendFactConnection => 'Verbindung';

  @override
  String get sendFactNotEncrypted => 'Nicht verschlüsselt · http://';

  @override
  String get sendFactTor => 'Tor';

  @override
  String get sendFactTorStarts => 'Startet beim Senden';

  @override
  String get sendFactOffline => 'Die Wallet des Empfängers darf offline sein.';

  @override
  String get sendFactOnline => 'Die Wallet des Empfängers muss geöffnet sein.';

  @override
  String get deskTfOpenTitle => 'Transaktionsdateien öffnen';

  @override
  String get deskTfOpenText =>
      'Wählen Sie eine oder mehrere Dateien. Die Wallet liest jede Datei und signiert sie, schließt sie ab oder sendet sie an das Netzwerk.';

  @override
  String get deskTfPickTitle => 'Transaktionsdateien';

  @override
  String get deskTfResults => 'Geöffnete Dateien';

  @override
  String get deskTfWorking => 'Wird bearbeitet…';

  @override
  String deskTfSigned(String path) {
    return 'Signiert. Antwort gespeichert unter $path';
  }

  @override
  String get deskTfAlreadyPosted => 'Bereits an das Netzwerk gesendet';

  @override
  String deskTfInvoice(String amount) {
    return 'Eine Rechnung über $amount. Prüfen Sie sie, um zu bezahlen.';
  }

  @override
  String get deskTfReview => 'Prüfen';

  @override
  String get deskTfCreate => 'Zahlungsdatei erstellen';

  @override
  String get deskTfDropHint => 'Sie können sie auch hierher ziehen.';

  @override
  String get deskSaToAddress => 'An eine Adresse senden';

  @override
  String deskSaToContactSem(String name) {
    return 'An $name';
  }

  @override
  String get netModesTitle => 'Verbindungsmodi';

  @override
  String get netModesAbout => 'Über die Verbindungsmodi';

  @override
  String get netModesGroup => 'Verbindungsmodus';

  @override
  String get netModesTag => '[NET]';

  @override
  String get netModesTopology => 'Topologie';

  @override
  String get netModesDevice => 'Gerät';

  @override
  String get netModesDeviceSub => 'diese Wallet';

  @override
  String get netModesTorSub => 'integriert';

  @override
  String get netModesEpicboxSub => 'Relay';

  @override
  String get netModesNode => 'Node';

  @override
  String get netModesNodeSub => 'verwendeter Node';

  @override
  String get netModesNetwork => 'Netzwerk';

  @override
  String get netModesNetworkSub => 'Peers';

  @override
  String get netModesPostElsewhere => 'Anderswo senden';

  @override
  String get netModesLeaves => 'Verlässt das Gerät';

  @override
  String get netModesDirect => 'Direkt';

  @override
  String get netModesViaTor => 'Über Tor';

  @override
  String get netModesOptional => 'Optional';

  @override
  String get netModesAllTraffic => 'Gesamter Verkehr';

  @override
  String get netModesOff => 'Aus';

  @override
  String get netModesYes => 'Ja';

  @override
  String get netModesNo => 'Nein';

  @override
  String get netModesDescStandard =>
      'Verbindet sich direkt mit dem Node, mit Epicbox und mit den Diensten, die Sie nutzen. Bei aktivem Tor laufen Zahlungen über Tor.';

  @override
  String get netModesDescNodeOnly =>
      'Nur der verwendete Node verbindet sich, bei aktivem Tor über Tor. Epicbox, Link, verknüpfte Geräte sowie Preis- und Update-Prüfung sind aus.';

  @override
  String get netModesDescNodeOnlyNoTor =>
      'Nur der verwendete Node verbindet sich. Epicbox, Link, verknüpfte Geräte sowie Preis- und Update-Prüfung sind aus.';

  @override
  String get netModesDescKillSwitch =>
      'Nichts verbindet sich, auch nicht der Node. Zahlungen werden offline erstellt und abgeschlossen und dann von einem Gerät gesendet, das online ist.';

  @override
  String netModesLiveLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Verbindungen',
      one: '1 aktive Verbindung',
    );
    return '$_temp0';
  }

  @override
  String netModesDiagramLabel(String mode, String description) {
    return 'Netzwerktopologie, Modus $mode: $description';
  }

  @override
  String get netModesModeTag => '[Modus]';

  @override
  String get deskOldAppTitle => 'Alte App gefunden';

  @override
  String deskOldAppBody(String app, String folder) {
    return '$app ist noch in $folder.';
  }

  @override
  String get deskOldAppTrash => 'In den Papierkorb legen';

  @override
  String get deskOldAppKeep => 'Behalten';

  @override
  String deskOldAppTrashed(String app) {
    return '$app in den Papierkorb gelegt';
  }

  @override
  String deskOldAppNotTrashed(String app) {
    return '$app konnte nicht in den Papierkorb gelegt werden';
  }

  @override
  String deskOvInflightMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Zahlungen unterwegs',
      one: '$count weitere Zahlung unterwegs',
    );
    return '$_temp0';
  }

  @override
  String get deskOvInflightView => 'Anzeigen';

  @override
  String get deskNoTorSetSynNetMode =>
      'offline, kill switch, nur node, vpn, ip, datenschutz, flugmodus';

  @override
  String get deskNoTorSetSearchTryWords =>
      'passwort,datenschutz,seed,sicherung,gebühr,node,sperre';

  @override
  String get deskKitReachDismiss => 'Ausblenden';

  @override
  String deskErrKeyMissing(String name) {
    return 'Die Dateien von $name sind auf diesem Computer, aber der Schlüssel, der sie öffnet, ist nicht mehr in seinem sicheren Speicher (auf einem Mac im Schlüsselbund). Geben Sie die Wiederherstellungsphrase der Wallet ein, um sie wieder zu öffnen; der Verlauf bleibt erhalten.';
  }

  @override
  String get deskOnbUnlockUsePhrase => 'Wiederherstellungsphrase eingeben';

  @override
  String get pairSeenAsNone => 'Sie sehen keinen Namen';

  @override
  String get pairSeenAsAdd => 'Name hinzufügen';

  @override
  String get pairSeenAsOptional => 'Leer lassen, um ohne Namen zu koppeln.';

  @override
  String get pairUnnamed => 'Wallet ohne Namen';

  @override
  String pairDefaultLabel(int n) {
    return 'Kontakt $n';
  }

  @override
  String get linkNotALink => 'Kein Zahlungslink';

  @override
  String get linkMadeForMainnet => 'Für das Hauptnetzwerk erstellt';

  @override
  String get linkMadeForFloonet => 'Für das Testnetzwerk erstellt';

  @override
  String get linkChanged => 'Dieser Link wurde nach der Erstellung geändert.';

  @override
  String linkExpired(String date) {
    return 'Dieser Link ist am $date abgelaufen';
  }

  @override
  String get linkForOther => 'Für jemand anderen erstellt';

  @override
  String get linkPaidTitle => 'Bereits bezahlt';

  @override
  String linkPaidBefore(String date) {
    return 'Sie haben diese Anfrage am $date bezahlt';
  }

  @override
  String get linkPayAgain => 'Erneut bezahlen';

  @override
  String linkTrustListed(String name, String service) {
    return '$name · über $service';
  }

  @override
  String linkTrustListedBy(String service) {
    return 'Über $service';
  }

  @override
  String get linkTrustNameService =>
      'Von einem Dienst, mit dem Sie gekoppelt sind';

  @override
  String get linkTrustOther =>
      'Prüfen Sie, ob sie zur Zahlungsnachricht passen';

  @override
  String linkTrustChanged(String name, String date) {
    return '$name erhält Zahlungen jetzt auf eine andere Wallet als bei Ihrer Zahlung am $date. Zahlen Sie nur, wenn es Ihnen gesagt wurde.';
  }

  @override
  String linkTrustChangedNoName(String date) {
    return 'Der Empfänger erhält Zahlungen jetzt auf eine andere Wallet als bei Ihrer Zahlung am $date. Zahlen Sie nur, wenn es Ihnen gesagt wurde.';
  }

  @override
  String linkCodeLabel(String name) {
    return 'Bilder für $name';
  }

  @override
  String get linkCodeLabelPlain => 'Bilder';

  @override
  String get linkAmountEdited => 'Nicht der angefragte Betrag';

  @override
  String get linkChangedConfirmTitle => 'Vor dem Bezahlen prüfen';

  @override
  String nsWaitingFor(String label) {
    return 'Warten auf $label…';
  }

  @override
  String get nsCodeTitle => 'Code prüfen';

  @override
  String nsCodeLead(String label) {
    return '$label zeigt vier Bilder. Vergleichen Sie sie mit diesen.';
  }

  @override
  String get nsCodeLabel => 'Die vier Bilder';

  @override
  String nsJoin(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Über $label bezahlt werden',
      'other': 'Als $name bezahlt werden',
    });
    return '$_temp0';
  }

  @override
  String get nsNotNow => 'Jetzt nicht';

  @override
  String nsJoinTitle(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Über $label bezahlt werden?',
      'other': 'Als $name bezahlt werden?',
    });
    return '$_temp0';
  }

  @override
  String nsJoinBody(String name, String label, String host) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none':
          'Wer $label nutzt, kann Sie dort bezahlen. Zahlungen kommen über $host',
      'other':
          'Wer $label nutzt, kann Sie als $name bezahlen. Zahlungen kommen über $host',
    });
    return '$_temp0';
  }

  @override
  String nsJoinInfo(String label) {
    return '$label erhält eine Zahlungsadresse und einen Code, beide nur dafür erstellt. Der Dienst kann weder Ihr Guthaben sehen noch Coins bewegen. Er speichert die für Sie oder von Ihnen erstellten Zahlungslinks samt Beträgen 30 Tage lang. Zahlungen kommen an, solange Epic Cash geöffnet ist. Jederzeit verlassen unter Kontakte › $label.';
  }

  @override
  String nsJoinedNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Über $label bezahlt werden: an',
      'other': 'Als $name bezahlt werden: an',
    });
    return '$_temp0';
  }

  @override
  String nsLeftNotice(String name, String label) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Über $label bezahlt werden: aus',
      'other': 'Als $name bezahlt werden: aus',
    });
    return '$_temp0';
  }

  @override
  String nsJoined(String name, String label, String date) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'none': 'Über $label bezahlt werden · seit $date',
      'other': 'Als $name bezahlt werden · seit $date',
    });
    return '$_temp0';
  }

  @override
  String get nsNotListed => 'Aus';

  @override
  String nsNotListedBody(String label) {
    return '$label hat Ihren Namen entfernt.';
  }

  @override
  String get nsNotJoined => 'Aus';

  @override
  String get nsJoinAgain => 'Wieder einschalten';

  @override
  String get nsListingCode => 'Bilder für Ihren Namen';

  @override
  String nsListingCodeInfo(String label) {
    return 'Vier Bilder, erstellt aus der Wallet, an die Ihr Name Zahlungen leitet. $label kann dieselben vier zum Vergleich zeigen.';
  }

  @override
  String get nsLeave => 'Verlassen';

  @override
  String nsRemoveTooTitle(String label) {
    return '$label auch entfernen?';
  }

  @override
  String deskSendErrOwnNamed(String wallet) {
    return 'Das ist „$wallet“, die gerade geöffnete Wallet. Um sie zu bezahlen, öffne zuerst eine andere Wallet.';
  }

  @override
  String get deskConLabelTitle => 'Label';

  @override
  String get deskConLabelWallet => 'Nur eine Wallet';

  @override
  String get deskConLabelExchange => 'Börse';

  @override
  String get deskConLabelVendor => 'Händler';

  @override
  String get deskConLabelService => 'Dienst';

  @override
  String get deskConLabelDefault => 'Standard';

  @override
  String deskConLabelCurrent(String name) {
    return 'Label: $name';
  }

  @override
  String get deskUpdStripAct => 'Aktualisieren';

  @override
  String get deskUpdStripHide => 'Bis zur nächsten Version ausblenden';

  @override
  String get deskTorAddressChangedTitle => 'Ihre Tor-Adresse hat sich geändert';

  @override
  String deskNodeFailoverBehind(String host) {
    return 'Node liegt zurück. Gewechselt zu $host.';
  }

  @override
  String sasAllowOffLine(String name) {
    return 'Rechnungen von $name sind aus.';
  }

  @override
  String get contactAllowFinishCheck =>
      'Zuerst die Schlüsselprüfung abschließen';

  @override
  String sasAllowInvoicesHintDesktop(String name) {
    return 'Die Wallet von $name kann Sie um Zahlung bitten. Ohne Ihr Wallet-Passwort wird nichts bezahlt.';
  }

  @override
  String get deskOvBalance => 'Guthaben';

  @override
  String deskOvSpendableNow(String amount) {
    return '$amount jetzt verfügbar';
  }

  @override
  String get deskNodeFitTitle => 'Soll dieser Computer einen Node betreiben?';

  @override
  String get deskNodeFitDescription =>
      'Zwei Fragen. Das lässt sich jederzeit unter Einstellungen › Node ändern.';

  @override
  String get deskNodeFitOpenQ => 'Wie lange ist die Wallet meist geöffnet?';

  @override
  String get deskNodeFitOpenDay => 'Den Großteil des Tages';

  @override
  String get deskNodeFitOpenHours => 'Ein bis zwei Stunden';

  @override
  String get deskNodeFitOpenMinutes => 'Wenige Minuten';

  @override
  String deskNodeFitOpenHint(int hours) {
    return 'Zuletzt: etwa $hours Std. am Tag';
  }

  @override
  String get deskNodeFitOpenHintUnder => 'Zuletzt: unter einer Stunde am Tag';

  @override
  String get deskNodeFitNetQ => 'Ihre Verbindung';

  @override
  String get deskNodeFitNetFree => 'Ohne Datenlimit';

  @override
  String get deskNodeFitNetMetered => 'Getaktet oder mobil';

  @override
  String get deskNodeFitNetHintFree => 'Windows meldet: nicht getaktet';

  @override
  String get deskNodeFitNetHintMetered => 'Windows meldet: getaktet';

  @override
  String get deskNodeFitDisk => 'Speicherplatz';

  @override
  String deskNodeFitDiskFree(String free, String chain) {
    return '$free frei, die Chain belegt etwa $chain';
  }

  @override
  String deskNodeFitDiskUnknown(String chain) {
    return 'Die Chain belegt etwa $chain';
  }

  @override
  String deskNodeFitFound(String size) {
    return '$size Chain-Daten auf diesem Computer gefunden. Sie lassen sich weiterverwenden.';
  }

  @override
  String get deskNodeFitGood => 'Gut geeignet';

  @override
  String get deskNodeFitGoodText =>
      'Der Node bleibt synchron, solange die Wallet geöffnet ist, hält Abfragen privat und unterstützt das Netzwerk.';

  @override
  String get deskNodeFitWait => 'Funktioniert, mit Wartezeit bei jedem Start';

  @override
  String get deskNodeFitWaitText =>
      'Bei jedem Öffnen der Wallet holt der Node zuerst die verpassten Blöcke nach.';

  @override
  String get deskNodeFitPublic => 'Ein öffentlicher Node passt besser';

  @override
  String get deskNodeFitPublicText =>
      'Kurze Besuche gehen für das Aufholen drauf: Die Wallet wirkt langsamer, und das Netzwerk gewinnt wenig.';

  @override
  String get deskNodeFitMetered => 'Auf den ersten Download achten';

  @override
  String deskNodeFitMeteredText(String size) {
    return 'Der erste Sync lädt etwa $size herunter. Starten Sie ihn mit einer Verbindung ohne Datenlimit.';
  }

  @override
  String get deskNodeFitNoSpace => 'Nicht genug freier Speicher';

  @override
  String deskNodeFitNoSpaceText(String chain, String floor) {
    return 'Die Chain belegt etwa $chain, und auf diesem Laufwerk müssen weitere $floor frei bleiben.';
  }

  @override
  String get deskNodeFitCapDay => 'Fast immer synchron';

  @override
  String get deskNodeFitCapDaySub => 'Und gibt Blöcke an andere weiter';

  @override
  String get deskNodeFitCapHours => 'Holt bei jedem Besuch auf';

  @override
  String get deskNodeFitCapHoursSub =>
      'Danach synchron, solange die App offen ist';

  @override
  String get deskNodeFitCapMinutes => 'Meist am Aufholen';

  @override
  String get deskNodeFitCapMinutesSub =>
      'Die Wallet schließt, bevor der Node synchron ist';

  @override
  String get deskNodeFitInSync => 'synchron';

  @override
  String get deskNodeFitCatchingUp => 'holt auf';

  @override
  String get deskNodeFitThisComputer => 'dieser Computer';

  @override
  String get deskNodeFitChipPrivate => 'Private Abfragen';

  @override
  String get deskNodeFitChipNetwork => 'Unterstützt das Netzwerk';

  @override
  String get deskNodeFitChipInSync => 'Synchron, solange offen';

  @override
  String deskNodeFitDownload(String size) {
    return 'Erster Download etwa $size';
  }

  @override
  String get deskNodeFitDontShow => 'Nicht mehr anzeigen';

  @override
  String get deskNodeFitStart => 'Lokalen Node starten';

  @override
  String get deskNodeFitStartAnyway => 'Trotzdem starten';

  @override
  String get deskNodeFitKeepPublic => 'Öffentlichen Node behalten';

  @override
  String get deskNodeFitNotNow => 'Nicht jetzt';

  @override
  String get deskNodeFitInUse =>
      'Der lokale Node ist in Verwendung. Seine Einstellungen stehen unter Einstellungen › Node.';

  @override
  String get deskNodeFitOpenCheck => 'Eignungsprüfung öffnen';

  @override
  String get deskNodeFitStarted => 'Lokaler Node gestartet';

  @override
  String deskNodeFitStartedText(String host) {
    return 'Die Wallet arbeitet über $host, bis der Node synchron ist.';
  }

  @override
  String get deskNodeFitStartedAlone =>
      'Kontostand und Senden warten, bis der Node synchron ist.';

  @override
  String get deskTrayOpen => 'Wallet öffnen';

  @override
  String deskTrayNode(String state) {
    return 'Node: $state';
  }

  @override
  String deskTrayHeight(String height) {
    return 'Höhe $height';
  }

  @override
  String deskTrayEpicbox(String state) {
    return 'Epicbox: $state';
  }

  @override
  String get deskSetNodeBackgroundNoTray =>
      'Dieser Desktop hat keinen Infobereich, daher beendet das Schließen des Fensters die App.';

  @override
  String get deskE1ErrCannotPay =>
      'Dieser Link nennt keinen Server, den diese Wallet erreicht.';

  @override
  String get deskE1ErrNoMoreRelays => 'Jeder Server im Link wurde versucht.';

  @override
  String get deskE1ErrPrintedFull =>
      'Alle 32 gedruckten Links sind in Gebrauch. Legen Sie zuerst einen still.';

  @override
  String get deskE1ErrOwnRelayLocal =>
      'Dein Epicbox-Server läuft auf diesem Gerät. Wähle einen anderen Server, um Links zu erstellen.';

  @override
  String get deskE1ErrMessageInvalid =>
      'Nachricht zu lang oder mit nicht unterstützten Zeichen.';

  @override
  String get deskE1ErrFinalized => 'Bereits abgeschlossen.';

  @override
  String get deskE1ErrWrongNetwork =>
      'Dieser Link ist für ein anderes Netzwerk.';

  @override
  String get deskE1ErrCodeExpired => 'Dieser Code ist abgelaufen.';

  @override
  String get deskE1ErrNotLink => 'Kein epic1-Link.';

  @override
  String get deskE1ErrRelayInvalid =>
      'Keine Serveradresse. Verwende host oder host:port.';

  @override
  String get deskE1ErrSavedTx => 'Keine Zahlungsdatei.';

  @override
  String get deskE1ErrWalletTooNew =>
      'Mit einer neueren App-Version erstellt. Aktualisiere, um diese Wallet zu öffnen.';

  @override
  String get deskE1ModeClassicAddress =>
      'Klassische Adresse. Schalte epic1-Zahlungen aus, um sie zu bezahlen.';

  @override
  String get deskE1ModeClassicCode =>
      'Klassischer Code. Schalte epic1-Zahlungen aus, um ihn zu verwenden.';

  @override
  String get deskE1ModeClassicFile =>
      'Klassische Datei. Schalte epic1-Zahlungen aus, um sie zu öffnen.';

  @override
  String get deskE1ModeEpic1Link =>
      'epic1-Link. Schalte epic1-Zahlungen ein, um ihn zu bezahlen.';

  @override
  String get deskE1ModeEpic1File =>
      'epic1-Datei. Schalte epic1-Zahlungen ein, um sie zu öffnen.';

  @override
  String get deskE1ClassicOnly => 'Nur klassisch';

  @override
  String get deskE1PaymentStopped => 'Zahlung gestoppt. Nichts wurde gesendet.';

  @override
  String get deskE1SameCodeTwice =>
      'Zwei Telefone haben mit demselben Code geantwortet.';

  @override
  String get deskE1ShowNewCode => 'Neuen Code zeigen';

  @override
  String deskE1RetireAsk(int n) {
    return 'Link $n stilllegen? Zahlungen an ihn kommen nicht mehr an.';
  }

  @override
  String get deskE1Retire => 'Stilllegen';

  @override
  String get deskE1Keep => 'Behalten';

  @override
  String get deskIpRequestTitle => 'Persönlich anfordern';

  @override
  String get deskIpPayTitle => 'Persönlich bezahlen';

  @override
  String get deskIpReceiveTitle => 'Persönlich empfangen';

  @override
  String get deskIpPayRequestTitle => 'Anforderung bezahlen';

  @override
  String get deskIpMakeCode => 'Code zeigen';

  @override
  String get deskIpCodeLeadRequest =>
      'Der Zahlende scannt diesen Code oder fügt seinen Text ein.';

  @override
  String get deskIpCodeLeadPay =>
      'Das andere Telefon scannt diesen Code oder fügt seinen Text ein.';

  @override
  String get deskIpCodeText => 'Code als Text';

  @override
  String get deskIpCodeOf => 'Persönlich-Code';

  @override
  String deskIpExpiresIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Läuft in etwa $count Min. ab.',
      one: 'Läuft in etwa $count Min. ab.',
    );
    return '$_temp0';
  }

  @override
  String get deskIpWaiting => 'Warten auf die Antwort…';

  @override
  String deskIpCheckPayer(String code) {
    return 'Zeigt das Telefon des Zahlenden $code?';
  }

  @override
  String deskIpCheckOther(String code) {
    return 'Zeigt das andere Telefon $code?';
  }

  @override
  String get deskIpMatches => 'Stimmt überein';

  @override
  String get deskIpDifferent => 'Anders';

  @override
  String get deskIpSent => 'Gesendet';

  @override
  String get deskIpReceived => 'Empfangen';

  @override
  String get deskIpPasteAnswer => 'Antwort einfügen';

  @override
  String get deskIpScanAnswer => 'Antwort scannen';

  @override
  String get deskIpAnswerLabel => 'Antwort';

  @override
  String get deskIpNotAnswer => 'Keine Antwort auf diesen Code.';

  @override
  String get deskIpReceiveButton => 'Empfangen';

  @override
  String get deskIpPayButton => 'Bezahlen';

  @override
  String get deskIpCheckTitle => 'Prüfcode';

  @override
  String get deskIpCheckLead =>
      'Das andere Telefon muss denselben Code zeigen.';

  @override
  String get deskIpAnswerLead =>
      'Das andere Telefon scannt diese Antwort oder fügt ihren Text ein.';

  @override
  String get deskIpAnswerOf => 'Persönlich-Antwort';

  @override
  String get deskIpUseServerAsk => 'Über diesen Server senden?';

  @override
  String deskIpNotInList(String host) {
    return '$host ist nicht in Ihrer Serverliste.';
  }

  @override
  String get deskIpUseServer => 'Server verwenden';

  @override
  String get deskIpScanTitle => 'Code scannen';

  @override
  String get deskIpScanAim =>
      'Richten Sie die Kamera auf den Code des anderen Telefons.';

  @override
  String get deskIpCopied => 'Kopiert';

  @override
  String get deskIpPostFailed =>
      'Die Antwort ist nicht angekommen. Erneut versuchen.';

  @override
  String get deskE1PhExperimental => 'Experimentell';

  @override
  String get deskE1PhSwitch => 'epic1-Zahlungen';

  @override
  String get deskE1PhSwitchHint =>
      'Zahlungen laufen nur über epic1: epic1-Links, Codes für persönliche Zahlungen und Kontakte mit epic1. Klassische Zahlungen kommen weiter an. Schalten Sie es aus, um andere Epic-Wallets zu bezahlen. Pro Wallet. Experimentell: Es kann sich noch ändern.';

  @override
  String get deskE1PhConfirmTitle => 'epic1-Zahlungen verwenden?';

  @override
  String get deskE1PhConfirmBody =>
      'Zahlungen gehen dann nur an Wallets mit epic1. Klassische Zahlungen kommen weiter an. Schalten Sie es aus, um eine andere Epic-Wallet zu bezahlen.';

  @override
  String get deskE1PhTurnOn => 'Einschalten';

  @override
  String get deskE1PhAppliesNext => 'Gilt ab dem nächsten Entsperren';

  @override
  String get deskE1PhLockNow => 'Jetzt sperren';

  @override
  String get deskE1PhSection => 'epic1';

  @override
  String get deskE1PhReceiving => 'Empfangen';

  @override
  String get deskE1PhPrinted => 'Gedruckte Links';

  @override
  String deskE1PhPrintedCount(int n, int max) {
    return '$n von $max';
  }

  @override
  String get deskE1PhPrintedEmpty => 'Keine gedruckten Links.';

  @override
  String deskE1PhPrintedCode(int n) {
    return 'Link $n';
  }

  @override
  String deskE1PhPrintedMade(String date) {
    return 'Erstellt $date';
  }

  @override
  String get deskE1PhPrintedUsed => 'Bezahlt';

  @override
  String deskE1PhRetired(int n) {
    return 'Link $n stillgelegt.';
  }

  @override
  String get deskE1PhLinkTitle => 'epic1-Link';

  @override
  String get deskE1PhLinkQrLabel => 'QR-Code des epic1-Links';

  @override
  String get deskE1PhCopyLink => 'Link kopieren';

  @override
  String get deskE1PhLinkCopied => 'Link kopiert.';

  @override
  String get deskE1PhAskAmount => 'Betrag anfordern';

  @override
  String get deskE1PhAmount => 'Betrag';

  @override
  String get deskE1PhMessage => 'Nachricht (optional)';

  @override
  String get deskE1PhMakeLink => 'Link erstellen';

  @override
  String deskE1PhLinkAsks(String amount) {
    return 'Fordert $amount';
  }

  @override
  String get deskE1PhAnyAmount => 'Beliebiger Betrag';

  @override
  String get deskE1PhOtherWays => 'Andere Wege zu empfangen';

  @override
  String get deskE1PhInPerson => 'Persönlich';

  @override
  String get deskE1PhRequestInPerson => 'Persönlich anfordern';

  @override
  String get deskE1PhSettings => 'Einstellungen';

  @override
  String get deskE1PhLanTitle => 'Server im lokalen Netzwerk verwenden?';

  @override
  String deskE1PhLanBody(String host) {
    return '$host ist im lokalen Netzwerk. Nur Wallets in diesem Netzwerk können damit erstellte Links bezahlen.';
  }

  @override
  String get deskE1PhField => 'epic1-Link oder Kontakt';

  @override
  String get deskE1PhPayInPerson => 'Persönlich bezahlen';

  @override
  String get deskE1PhContacts => 'Kontakte';

  @override
  String get deskE1PhUnknownTitle => 'Über diesen Server senden?';

  @override
  String deskE1PhUnknownBody(String host) {
    return '$host ist nicht in deiner Serverliste.';
  }

  @override
  String get deskE1PhUseServer => 'Server verwenden';

  @override
  String get deskE1PhReview => 'Prüfen';

  @override
  String get deskE1PhTo => 'An';

  @override
  String get deskE1PhServer => 'Server';

  @override
  String get deskE1PhNote => 'Nachricht';

  @override
  String get deskE1PhSend => 'Senden';

  @override
  String get deskE1PhWaiting => 'Warten auf den Empfänger';

  @override
  String deskE1PhNotTaken(String host) {
    return '$host hat die Zahlung nicht angenommen.';
  }

  @override
  String get deskE1PhTryNext => 'Nächsten Server versuchen';

  @override
  String get deskE1PhCancelUnlock => 'Abbrechen und freigeben';

  @override
  String get deskE1PhCancelled =>
      'Zahlung abgebrochen. Die Coins sind wieder frei.';

  @override
  String get deskE1PhSent => 'Gesendet';

  @override
  String get deskE1PhDone => 'Fertig';

  @override
  String get deskE1PhClassicOnlyTip =>
      'Schalte epic1-Zahlungen aus, um diesen Kontakt zu bezahlen';

  @override
  String get deskE1SetGroup => 'epic1';

  @override
  String get deskE1SetSwitch => 'epic1-Zahlungen';

  @override
  String get deskE1SetInfo =>
      'Zahlungen laufen nur über epic1: epic1-Links, Codes für persönliche Zahlungen und Kontakte mit epic1. Klassische Zahlungen kommen weiter an. Schalten Sie es aus, um andere Epic-Wallets zu bezahlen. Pro Wallet. Experimentell: Es kann sich noch ändern.';

  @override
  String get deskE1SetSyn =>
      'epic1, versiegelt, experimentell, Links, persönlich, Codes';

  @override
  String get deskE1TurnOnTitle => 'epic1-Zahlungen verwenden?';

  @override
  String get deskE1TurnOnBody =>
      'Zahlungen gehen dann nur an Wallets mit epic1. Klassische Zahlungen kommen weiter an. Schalten Sie es aus, um eine andere Epic-Wallet zu bezahlen.';

  @override
  String get deskE1TurnOn => 'Einschalten';

  @override
  String get deskE1AppliesNext => 'Gilt ab dem nächsten Entsperren';

  @override
  String get deskE1LockNow => 'Jetzt sperren';

  @override
  String get deskE1PrintedCodes => 'Gedruckte Links';

  @override
  String get deskE1PrintedHint =>
      'epic1-Links zum Drucken oder Aufbewahren. Legen Sie einen still, wenn er nicht mehr gebraucht wird.';

  @override
  String deskE1PrintedCount(int n) {
    return '$n von 32';
  }

  @override
  String get deskE1PrintedNone => 'Keine gedruckten Links.';

  @override
  String deskE1CodeN(int n) {
    return 'Link $n';
  }

  @override
  String deskE1CodeIssued(String date) {
    return 'Erstellt $date';
  }

  @override
  String deskE1CodeUsed(String date) {
    return 'Zuletzt bezahlt $date';
  }

  @override
  String get deskE1LinkTitle => 'epic1-Link';

  @override
  String get deskE1LinkSub => 'Jeder mit epic1 kann diesen Link bezahlen.';

  @override
  String get deskE1CopyLink => 'Link kopieren';

  @override
  String get deskE1LinkCopied => 'Link kopiert';

  @override
  String get deskE1AskAmount => 'Betrag anfordern';

  @override
  String get deskE1MakeLink => 'Link erstellen';

  @override
  String deskE1LinkAsks(String amount) {
    return 'Fordert $amount';
  }

  @override
  String get deskE1AnyAmount => 'Beliebiger Betrag';

  @override
  String get deskE1LanTitle => 'Server im lokalen Netzwerk verwenden?';

  @override
  String deskE1LanBody(String host) {
    return '$host ist in deinem lokalen Netzwerk. Nur Zahlende im selben Netzwerk können diesen Link bezahlen.';
  }

  @override
  String get deskE1UseServer => 'Server verwenden';

  @override
  String get deskE1OtherWays => 'Andere Wege zu empfangen';

  @override
  String get deskE1InPerson => 'Persönlich';

  @override
  String get deskE1InPersonSub =>
      'Ein Code, den der Zahlende von diesem Bildschirm liest.';

  @override
  String get deskE1RequestInPerson => 'Persönlich anfordern';

  @override
  String get deskE1SendField => 'epic1-Link oder Kontakt';

  @override
  String get deskE1SendFieldHint => 'epic1-Link einfügen';

  @override
  String get deskE1SendFieldSem => 'epic1-Link';

  @override
  String get deskE1Review => 'Prüfen';

  @override
  String get deskE1ReviewTitle => 'Zahlung prüfen';

  @override
  String get deskE1To => 'An';

  @override
  String get deskE1Server => 'Server';

  @override
  String get deskE1Send => 'Senden';

  @override
  String get deskE1UnknownServerTitle => 'Über diesen Server senden?';

  @override
  String deskE1UnknownServerBody(String host) {
    return '$host ist nicht in deiner Serverliste.';
  }

  @override
  String get deskE1Waiting => 'Warte auf den Empfänger';

  @override
  String get deskE1NotPosted => 'Noch kein Server hat die Zahlung angenommen.';

  @override
  String get deskE1TryNext => 'Nächsten Server versuchen';

  @override
  String get deskE1CancelUnlock => 'Abbrechen und freigeben';

  @override
  String get deskE1Sent => 'Gesendet';

  @override
  String get deskE1Cancelled => 'Zahlung abgebrochen';

  @override
  String get deskE1Done => 'Fertig';

  @override
  String get deskE1ClassicTip =>
      'Schalte epic1-Zahlungen aus, um diesen Kontakt zu bezahlen';

  @override
  String get deskE1PayInPerson => 'Persönlich bezahlen';

  @override
  String get deskE1Back => 'Zurück';

  @override
  String get deskSendFileFor => 'Für';

  @override
  String get deskSendFileForHelp =>
      'Die Datei für einen gekoppelten Kontakt wird versiegelt: nur seine Wallet öffnet sie.';

  @override
  String get deskImpFrom => 'Von';

  @override
  String get deskE1TourPhSendText =>
      'Fügen Sie einen epic1-Link ein oder wählen Sie einen Kontakt. „Persönlich bezahlen“ ist für ein Smartphone neben Ihnen. Zuerst kommt eine Prüfung.';

  @override
  String get deskE1TourPhReceiveText =>
      'Ihr epic1-Link. Teilen Sie ihn, um bezahlt zu werden. „Persönlich anfordern“ ist für ein Smartphone neben Ihnen.';

  @override
  String get deskE1TourSendText =>
      'Einen epic1-Link einfügen oder einen Kontakt wählen. „Persönlich bezahlen“ ist für ein Smartphone neben Ihnen. Vor dem Abschicken kommt eine Prüfung.';

  @override
  String get deskE1TourReceiveText =>
      'Der epic1-Link dieser Wallet: Teilen Sie ihn, um bezahlt zu werden. „Persönlich anfordern“ ist für ein Smartphone neben Ihnen.';

  @override
  String get deskE1Sealed => 'Mit epic1 versiegelt';

  @override
  String deskE1SpokenSealed(String row) {
    return '$row, mit epic1 versiegelt';
  }

  @override
  String get deskLvPaySendingInPerson => 'Persönlich senden';

  @override
  String get deskInvIssuerWaitingInPerson =>
      'Warten auf die Antwort der anderen Wallet. Es wird nichts bezahlt, bis sie zustimmt.';

  @override
  String deskIpOnlineLine(String host) {
    return 'Antwort kommt online · $host';
  }

  @override
  String get deskIpOnlineSending => 'Antwort wird online gesendet…';

  @override
  String get deskIpOnlineDown =>
      'Epicbox-Server nicht erreichbar · neuer Versuch';

  @override
  String get deskIpOnlineTitle => 'Online-Antwort';

  @override
  String get deskIpOnlineServer => 'Epicbox-Server';

  @override
  String get deskIpOnlineStatus => 'Status';

  @override
  String get deskIpOnlineTimeLeft => 'Verbleibende Zeit';

  @override
  String deskIpOnlineMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Etwa $count Min.',
      one: 'Etwa $count Min.',
    );
    return '$_temp0';
  }

  @override
  String get deskIpStepPosting => 'Antwort wird gesendet…';

  @override
  String get deskIpStepSent => 'Antwort gesendet';

  @override
  String get deskIpStepReceived => 'Antwort empfangen';

  @override
  String get deskIpStepDown => 'Nicht erreichbar. Neuer Versuch.';

  @override
  String get deskIpStepFailed => 'Nicht zugestellt';

  @override
  String get deskIpStepCancelled => 'Storniert';

  @override
  String get deskIpOnlineCancel => 'Online-Antwort abbrechen';

  @override
  String get deskIpOnlineCancelCode =>
      'Danach die Antwort des anderen Telefons scannen oder einfügen.';

  @override
  String get deskIpOnlineCancelAnswer =>
      'Danach scannt das andere Telefon Ihre Antwort.';

  @override
  String get deskIpOnlineDetails => 'Details';
}
