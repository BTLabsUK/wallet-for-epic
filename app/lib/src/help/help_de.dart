// SPDX-License-Identifier: Apache-2.0
/// German help: the topics and sections of help_content.dart in German, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';
import 'help_devices.dart';

const List<HelpSection> helpSectionsDe = [
  (id: 'start', title: 'Erste Schritte', lede: 'Empfangen, senden und per Datei bezahlen.', art: 'help-start'),
  (id: 'how', title: 'So funktioniert Epic Cash', lede: 'Beide Wallets wirken mit. Bestätigungen, Privatsphäre, Wechselgeld und Gebühren.', art: 'help-how'),
  (id: 'safety', title: 'Die Wallet schützen', lede: 'Die Wiederherstellungsphrase ist Sicherung und Schlüssel zugleich.', art: 'help-safety'),
  (id: 'network', title: 'Nodes und Epicbox', lede: 'Womit sich die Wallet verbindet, und Tor.', art: 'help-network'),
  (id: 'trouble', title: 'Wenn etwas nicht klappt', lede: 'Die üblichen Ursachen und was zu tun ist.', art: 'help-trouble'),
  (id: 'maintenance', title: 'Wartung', lede: 'Alte Wallet-Ordner auf der Festplatte.', art: 'help-maintenance'),
];

List<HelpTopic> helpTopicsDe(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'diesem Smartphone' : 'diesem Computer';
  final secret = phone ? 'Ihre PIN' : 'das Wallet-Passwort';
  final nodePlace = phone ? '[[Einstellungen › Datenschutz & Netzwerk › Node|Settings › Privacy & network › Node]]' : '[[Einstellungen › Node|Settings › Node]]';
  final epicboxPlace = phone ? '[[Einstellungen › Datenschutz & Netzwerk › Epicbox|Settings › Privacy & network › Epicbox]]' : '[[Einstellungen › Transaktionen › Epicbox|Settings › Transactions › Epicbox]]';
  final torPlace = phone ? '[[Einstellungen › Datenschutz & Netzwerk › Tor-Netzwerk|Settings › Privacy & network › Tor network]]' : '[[Einstellungen › Datenschutz › Tor|Settings › Privacy › Tor]]';
  final cancelPlace = phone
      ? '[[Aktivität|Activity]] (die Zahlung öffnen, dann „Zahlung stornieren“)'
      : '[[Aktivität › die Transaktion › Zahlung stornieren|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[Einstellungen › Diese Wallet › Wallet-Daten exportieren|Settings › This wallet › Export wallet data]]'
      : '[[Einstellungen › Diese Wallet › Wallet-Daten exportieren|Settings › This wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**Mit Phrase wiederherstellen** (auf dem ersten Bildschirm oder unter [[Einstellungen › Diese Wallet|Settings › This wallet]])'
      : '**Mit Phrase wiederherstellen** (auf dem ersten Bildschirm, unter Entsperren › Wallet hinzufügen oder unter [[Einstellungen › Alle Wallets|Settings › All wallets]])';
  final recheckPlace = phone ? '[[Einstellungen › Diese Wallet › Guthaben neu prüfen|Settings › This wallet › Recheck balance]]' : '[[Einstellungen › Guthaben neu prüfen|Settings › Recheck balance]]';
  final phrasePlace = phone ? '[[Einstellungen › Sicherheit › Wiederherstellungsphrase sichern|Settings › Security › Back up recovery phrase]]' : '[[Einstellungen › Seed-Phrase|Settings › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Die ersten EPIC empfangen',
      'Öffnen Sie Empfangen, kopieren Sie die Epicbox-Adresse und geben Sie sie dem Absender. Die Zahlung kommt von selbst an.',
      [
        const HelpBlock.p('Die Epicbox-Adresse ist ein langer Code, der auf **@** und den Namen des Epicbox-Servers endet, zum Beispiel **…@epicbox.epiccash.com**. Sie kann gefahrlos weitergegeben werden: Andere brauchen sie zum Bezahlen, und niemand kann damit etwas wegnehmen.'),
        const HelpBlock.ol(['Öffnen Sie [[Empfangen|Receive]].', 'Kopieren Sie die Adresse (oder zeigen Sie ihren QR-Code) und senden Sie sie der Person, die bezahlt.', 'Die Zahlung erscheint von selbst unter Aktivität.']),
        if (phone)
          const HelpBlock.p('Empfangen funktioniert, solange die App geöffnet und der Node synchronisiert ist. Eine Zahlung, die bei geschlossener App gesendet wird, wartet auf dem Epicbox-Server, wie in einem Postfach, und kommt beim nächsten Entsperren an.')
        else
          const HelpBlock.p('Der Empfang startet nach dem Entsperren von selbst, sobald der Node synchronisiert ist. Ist die Wallet beim Bezahlen geschlossen, hält Epicbox die Zahlung bereit, und die Wallet holt sie beim nächsten Entsperren ab.'),
        HelpBlock.p('Eine neue Zahlung wartet zuerst darauf, dass die Wallet des Absenders sie abschließt, und wird dann als „Wird bestätigt“ angezeigt. Ab der $confirmations. Bestätigung (nach etwa $confirmations Min.) ist sie verfügbar.'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      'An jemanden senden',
      'Öffnen Sie Senden, fügen Sie die Epicbox-Adresse ein, geben Sie den Betrag ein, prüfen Sie die Gebühr und senden Sie.',
      [
        const HelpBlock.ol(['Öffnen Sie [[Senden|Send]] und fügen Sie die Adresse des Empfängers ein oder wählen Sie einen Kontakt.', 'Geben Sie den Betrag ein. Die Gebühr wird vor dem Senden angezeigt.', 'Drücken Sie **Zahlung prüfen**, kontrollieren Sie alles und drücken Sie dann **… EPIC senden**.']),
        const HelpBlock.p('Jetzt muss die Wallet des Empfängers antworten (siehe „Warum braucht eine Transaktion beide Seiten?“). Über Epicbox muss der Empfänger nicht gerade online sein: Die Zahlung wartet, bis seine Wallet geöffnet wird. Bis dahin sind die verwendeten Outputs gesperrt, damit sie nicht doppelt ausgegeben werden.'),
        HelpBlock.p('Kommt die Antwort zurück, schließt die Wallet die Transaktion ab und sendet sie von selbst ins Netzwerk. Ab der $confirmations. Bestätigung ist sie endgültig.'),
        HelpBlock.p('**Keine Antwort?** Nach einigen Minuten zeigt der Status „Wartet auf Empfänger“. Bitten Sie den Empfänger, seine Wallet zu öffnen. Kommt die Antwort nie, stornieren Sie die Zahlung unter $cancelPlace, um die Outputs freizugeben. Eine Zahlung, die niemand beantwortet, wird nach etwa einem Tag von selbst storniert.'),
        if (phone)
          HelpBlock.p('Zum Senden braucht es einen synchronisierten Node. Eine Epicbox-Adresse braucht außerdem einen antwortenden Epicbox-Server; eine direkte Adresse (${tor ? 'http oder .onion' : 'http'}) braucht die Wallet des Empfängers, geöffnet und in diesem Moment erreichbar.')
        else
          HelpBlock.p('Zum Senden braucht es einen synchronisierten Node. Eine Epicbox-Adresse braucht außerdem eingeschalteten Empfang über Epicbox; eine Link-Adresse (${tor ? 'http oder .onion' : 'http'}) braucht die Wallet des Empfängers, geöffnet und in diesem Moment erreichbar.'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      'Per Datei senden',
      'Der manuelle Weg: Transaktionsdatei speichern, dem Empfänger geben, dann die Antwortdatei öffnen, die er zurückschickt.',
      [
        const HelpBlock.p('Die Dateiübertragung durchläuft denselben Handschlag wie Epicbox, nur werden die Nachrichten von Hand übergeben, zum Beispiel per E-Mail, Chat oder USB-Stick. Das funktioniert ohne Epicbox und ohne dass beide Wallets gleichzeitig online sind.'),
        if (phone)
          const HelpBlock.ol(['**Absender:** wählt unter Senden **Direkt · Dateiübertragung**, gibt den Betrag ein und teilt die Datei (sie endet auf .tx). Ab jetzt sind die Outputs gesperrt.', '**Empfänger:** öffnet die Datei unter [[Empfangen › Direkt · Datei|Receive › Direct · File]]. Seine Wallet signiert sie und teilt eine Antwortdatei (sie endet auf .response). Diese Datei schickt er zurück.', '**Absender:** öffnet die Antwortdatei unter [[Empfangen › Direkt · Datei|Receive › Direct · File]]. Die Wallet schließt die Transaktion ab und sendet sie.'])
        else
          const HelpBlock.ol(['**Absender:** wählt unter Senden **Direkt · Dateiübertragung**, gibt den Betrag ein und speichert die Datei (sie endet auf .tx). Ab jetzt sind die Outputs gesperrt.', '**Empfänger:** öffnet die Datei unter [[Empfangen › Transaktionsdateien › Transaktionsdatei signieren|Receive › Transaction files › Sign a transaction file]]. Seine Wallet signiert sie und speichert eine Antwortdatei (sie endet auf .response). Diese Datei schickt er zurück.', '**Absender:** öffnet die Antwortdatei unter [[Empfangen › Transaktionsdateien › Antwortdatei abschließen|Receive › Transaction files › Finalize a response file]]. Die Wallet schließt die Transaktion ab und sendet sie.']),
        const HelpBlock.p('Andere Epic-Cash-Wallets nennen diese Schritte anders. Kommt die Antwortdatei nie, stornieren Sie die Zahlung unter Aktivität, um die Outputs freizugeben.'),
      ],
      id: HelpId.file,
    ),
    if (phone)
      const HelpTopic(
        'start',
        'Persönlich zahlen: Direkt · QR-Zahlung',
        'Zwei Smartphones nebeneinander zahlen mit einem animierten QR-Code, ohne Verbindung zwischen ihnen.',
        [
          HelpBlock.p('Die Zahlung reist als animierter QR-Code, den das andere Smartphone mit der Kamera scannt. Nichts ist verschlüsselt, zeigen Sie den Code also nur der Person, die Sie bezahlen.'),
          HelpBlock.ol(['**Absender:** wählt unter Senden **Direkt · QR-Zahlung**, gibt den Betrag ein und tippt auf **QR anzeigen**. Der Code bleibt verborgen, bis Sie ihn zeigen, zählt 3, 2, 1 und verbirgt sich nach 40 Sekunden von selbst.', '**Empfänger:** tippt unter [[Empfangen › Direkt · QR|Receive › Direct · QR]] auf **Zahlungs-QR scannen**, nimmt die Zahlung an und zeigt dann die Antwort auf dieselbe Weise.', '**Absender:** tippt auf **Antwort scannen**. Die Wallet sendet die Zahlung, und der Verlauf zeigt den Fortgang.']),
          HelpBlock.p('Halten Sie den Code im Bild, bis alle Teile gelesen sind: Ring und Zähler zeigen, wie weit es ist. Ein Code, der keine Zahlung ist, wird gemeldet und ignoriert. Auf dem Code-Bildschirm sind Screenshots gesperrt.'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      'Zahlungsmethoden und Vorgaben fürs Senden',
      'Jede Methode ist ein Schalter; Epicbox ist standardmäßig an. Senden beginnt mit der Methode, die Sie wählen.',
      [
        const HelpBlock.p('Die Seite Transaktionen unter [[Einstellungen › Transaktionen|Settings › Transactions]] enthält drei Dinge.'),
        HelpBlock.ul([
          '**Zahlungsmethoden.** Je ein Schalter. **Epicbox** ist standardmäßig an; ist es aus, verbindet sich die Wallet mit keinem Server, also gibt es keine Epicbox-Zahlungen oder Rechnungen, und Empfangen zeigt keine Epicbox-Adresse (Zahlungen an sie warten auf dem Server). ${tor ? "**Link · HTTP** (an Web-Adressen), **Link · Tor** (an .onion-Adressen${phone ? ' und mit einer Tor-Adresse dieses Smartphones, unter der Sie bezahlt werden' : ''}) und ${phone ? '**Direkt · QR-Zahlung** und ' : ''}**Direkt · Dateiübertragung**" : "**Link · HTTP** (an Web-Adressen)${phone ? ', **Direkt · QR-Zahlung**' : ''} und **Direkt · Dateiübertragung**"} brauchen keinen Epicbox-Server. Eine Methode, die aus ist, erscheint nicht bei Senden und Empfangen.',
          '**Senden beginnt mit.** Die Methode, mit der der Bildschirm Senden sich öffnet. Auf Senden können Sie trotzdem eine andere wählen.',
          '**Vorgaben fürs Senden.** Welche Outputs eine Zahlung ausgibt, Kleinste oder Alle, und ob ihr Wechselgeld aufgeteilt wird. Sie erscheinen nur, solange **Zahlungsoptionen** unter Erweitert an ist.',
        ]),
      ],
      id: HelpId.methods,
    ),
    HelpTopic(
        'start',
        'So sieht eine Adresse aus',
        tor ? 'Eine Epicbox-Adresse beginnt mit es und endet auf @ und einen Servernamen. Eine direkte Adresse ist eine Webadresse oder endet auf .onion.' : 'Eine Epicbox-Adresse beginnt mit es und endet auf @ und einen Servernamen. Eine direkte Adresse ist eine Webadresse.',
        [
          HelpBlock.ul([
            '**Epicbox**: etwa 52 Zeichen, beginnend mit **es**, dann **@** und der Server, zum Beispiel **esXXXX…XXXX@epicbox.epiccash.com**. Die Standardmethode; der Empfänger darf offline sein.',
            if (tor)
              '**Link · HTTP** und **Link · Tor**: die eigene Wallet des Empfängers, gerade geöffnet. Eine Webadresse wie **http://host:3415** läuft über Link · HTTP; eine Tor-Adresse aus 56 Zeichen, die auf **.onion** endet, über Link · Tor, also über Tor.'
            else
              '**Link · HTTP**: die eigene Wallet des Empfängers, gerade geöffnet. Eine Webadresse wie **http://host:3415** läuft über Link · HTTP.',
          ]),
          HelpBlock.p('Senden wählt die Methode anhand der Adresse, die im Feld „An“ eingefügt wird. Wer eine Adresse vorliest, vergleicht die ersten sechs und die letzten sechs Zeichen.'),
        ],
        id: HelpId.addresses,
      ),
    HelpTopic(
      'how',
      'Warum braucht eine Transaktion beide Seiten?',
      'Bei Epic Cash hilft die Wallet des Empfängers, jede Transaktion zu bauen, daher müssen beide Wallets mitwirken.',
      [
        HelpBlock.p('Epic Cash nutzt Mimblewimble. Statt eine Adresse und einen Betrag in die Blockchain zu schreiben, bauen die beiden Wallets jede Transaktion gemeinsam, wie bei einem Handschlag:'),
        HelpBlock.ol(['Die Wallet des Absenders beginnt und sperrt die Outputs, die gesendet werden.', 'Die Wallet des Empfängers fügt ihren Teil hinzu und signiert.', 'Die Wallet des Absenders signiert ebenfalls, schließt die Transaktion ab und sendet sie ins Netzwerk.']),
        HelpBlock.p('Etwas muss die Nachrichten zwischen den beiden Wallets übermitteln. **Epicbox** hält jede Nachricht bereit, solange die andere Wallet offline ist, sodass nicht beide gleichzeitig online sein müssen. ${tor ? '**Link · HTTP** und **Link · Tor** gehen direkt' : '**Link · HTTP** geht direkt'} zur anderen Wallet, solange sie geöffnet ist. **Direkt · Dateiübertragung** mit einer Transaktionsdatei ist der manuelle Weg.'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      'Bestätigungen',
      'Eine Transaktion ist ab der $confirmations. Bestätigung endgültig, meist nach etwa $confirmations Min.',
      [
        const HelpBlock.p('Nimmt das Netzwerk eine Transaktion an, legt ein Miner sie in einen Block. Etwa jede Minute kommt ein neuer Block. Der Block mit der Transaktion ist die erste Bestätigung; jeder weitere Block fügt eine hinzu und macht die Transaktion schwerer rückgängig zu machen.'),
        HelpBlock.p('Diese Wallet betrachtet eine Transaktion ab der **$confirmations. Bestätigung** als endgültig. Bis dahin wird sie als **Wird bestätigt** angezeigt, und empfangene Outputs sind noch nicht verfügbar. Die Zahl ist eine Einstellung: standardmäßig 6, jeder Wert von 1 bis 30. Weniger Bestätigungen sind schneller, schützen aber weniger vor einer Reorganisation der Blockchain.'),
        const HelpBlock.p('Dauert es länger als üblich? Die Wallet sieht neue Blöcke nur über ihren Node: Prüfen Sie, ob der Node synchronisiert ist.'),
      ],
      id: HelpId.confirmations,
    ),
    HelpTopic(
      'how',
      'Was die Blockchain zeigt',
      'Keine Adressen und keine Beträge: nur Münzdatensätze, die das Netzwerk prüfen kann, ohne zu sehen, wer oder wie viel.',
      [
        const HelpBlock.p('Bei vielen Blockchains kann jeder eine Adresse nachschlagen und ihr Guthaben und ihren Verlauf sehen. Epic Cash ist anders:'),
        HelpBlock.ul(['**Keine Adressen auf der Blockchain.** Die Epicbox-Adresse sagt Epicbox nur, wohin Nachrichten zugestellt werden. Sie wird nie in die Blockchain geschrieben.', '**Keine Beträge auf der Blockchain.** Beträge sind kryptografisch verborgen, und das Netzwerk kann trotzdem prüfen, dass keine Münzen aus dem Nichts entstanden sind.', '**Notizen bleiben außerhalb der Blockchain.** Eine Nachricht zu einer Zahlung geht nur an die andere Wallet. Kontakte und Wallet-Namen bleiben auf $device.']),
        HelpBlock.p('Was nicht verborgen ist: Der Node und der Epicbox-Server sehen die IP-Adresse der Wallet, und ein öffentlicher Node kann sehen, nach welchen Outputs die Wallet fragt. ${tor ? 'Tor oder ein VPN verbirgt' : 'Ein VPN verbirgt'} die IP-Adresse.'),
      ],
      id: HelpId.privacy,
    ),
    HelpTopic(
      'how',
      'Gesperrte Beträge und Wechselgeld',
      'Das Guthaben besteht aus einzelnen Outputs. Eine Zahlung gibt ganze Outputs aus und gibt den Rest als Wechselgeld zurück.',
      [
        const HelpBlock.p('Das Guthaben ist eine Menge von Outputs. Um 3 EPIC aus einem Output von 5 EPIC zu senden, gibt die Wallet den ganzen Output aus: 3 EPIC gehen an den Empfänger, eine kleine Gebühr an die Miner, und der Rest kommt als neuer Output zurück, das **Wechselgeld**.'),
        const HelpBlock.p('Deshalb kann ein Teil des Guthabens nach einer Zahlung einige Minuten lang nicht verfügbar sein:'),
        HelpBlock.ul(['**Gesperrt**: Outputs in einer Zahlung, die noch nicht abgeschlossen ist. Sie werden freigegeben, wenn die Zahlung storniert wird.', '**Wartet auf Abschluss**: eine Transaktion, die noch auf die andere Wallet wartet.', '**Wird bestätigt**: Outputs in einem Block, der die $confirmations. Bestätigung noch nicht erreicht hat, einschließlich des Wechselgelds.']),
        const HelpBlock.p('Die Outputs sind unter [[Outputs|Outputs]] aufgelistet.'),
      ],
      id: HelpId.locked,
    ),
    HelpTopic(
      'how',
      'Kleinste oder Alle: welche Outputs eine Zahlung ausgibt',
      'Kleinste (die Standardeinstellung) nutzt möglichst wenige kleine Outputs und lässt den Rest verfügbar. Alle nutzt jeden Output.',
      [
        const HelpBlock.p('**Kleinste** sortiert die verfügbaren Outputs nach Wert und nimmt die kleinsten, bis Betrag und Gebühr gedeckt sind. Nur diese sind gesperrt, solange die Zahlung bestätigt wird; der Rest kann sofort gesendet werden.'),
        HelpBlock.p('**Alle** gibt jeden verfügbaren Output aus und gibt einen einzigen Wechselgeld-Output zurück. Alles ist bis zur $confirmations. Bestätigung gesperrt, die Wallet hat danach weniger, größere Outputs, und die Gebühr ist etwas höher, weil jeder Input kostet. Wird das ganze Guthaben gesendet, gilt immer Alle.'),
        if (phone)
          const HelpBlock.p('Die Standardeinstellung legen Sie unter [[Einstellungen › Transaktionen|Settings › Transactions]] fest, mit eingeschalteten Zahlungsoptionen unter Erweitert.')
        else
          const HelpBlock.p('Die Standardeinstellung legen Sie unter [[Outputs › Outputs verwalten|Outputs › Manage outputs]] fest; Senden kann sie für eine einzelne Zahlung unter **Zahlungsoptionen** ändern.'),
      ],
      id: HelpId.strategy,
    ),
    HelpTopic(
      'how',
      'Aufteilen und zusammenführen',
      'Aufteilen erzeugt mehr Outputs, damit Zahlungen direkt aufeinander folgen können; Zusammenführen vereint sie zu einem.',
      [
        HelpBlock.p('Beides sind normale Netzwerktransaktionen dieser Wallet an sich selbst, ab der $confirmations. Bestätigung endgültig wie jede Zahlung, und beide sperren bis dahin jeden verfügbaren Output.'),
        const HelpBlock.ul(['**Aufteilen** nimmt das verfügbare Guthaben und erzeugt 2 bis 10 Outputs mit fast gleichem Wert.', '**Zusammenführen** nimmt jeden verfügbaren Output und erzeugt einen.', '**Wechselgeld aufteilen** (standardmäßig an) tut dasselbe innerhalb einer gewöhnlichen Zahlung, wenn nur wenige Outputs übrig blieben, für 0,004 EPIC pro zusätzlichem Output.']),
        const HelpBlock.p('Aktivität zeigt beides als zwei Einträge, eine gesendete und eine empfangene Zahlung, beide mit dieser Wallet. Beides finden Sie unter [[Outputs › Outputs verwalten|Outputs › Manage outputs]].'),
      ],
      id: HelpId.split,
    ),
    const HelpTopic(
      'how',
      'Gebühren',
      'Jede Transaktion zahlt eine kleine Netzwerkgebühr, die vor dem Senden angezeigt wird. Sie geht an die Miner.',
      [
        HelpBlock.p('Die Gebühr hängt davon ab, wie viele Outputs die Transaktion ausgibt und erzeugt, nicht vom Betrag. Meist ist sie ein kleiner Bruchteil eines EPIC.'),
        HelpBlock.p('Sie wird vor dem Senden als **Netzwerkgebühr** angezeigt. **Alles** neben dem Betrag trägt das ganze verfügbare Guthaben abzüglich der genauen Gebühr ein, sodass kein Wechselgeld übrig bleibt.'),
      ],
      id: HelpId.fees,
    ),
    HelpTopic(
      'safety',
      'Ihre Wiederherstellungsphrase',
      'Nur mit diesen Wörtern lassen sich die EPIC zurückholen. Schreiben Sie sie auf Papier und geben Sie sie niemals weiter.',
      [
        HelpBlock.p('Die Wiederherstellungsphrase (24 Wörter bei einer neuen Wallet) ist der Schlüssel zum Geld. Mit ihr lässt sich die Wallet auf jedem ${phone ? 'Smartphone oder Computer' : 'Computer'} wiederherstellen, und jeder andere, der sie hat, kann die EPIC nehmen.'),
        const HelpBlock.ul(['Schreiben Sie die Wörter in dieser Reihenfolge auf Papier und bewahren Sie es sicher und offline auf.', 'Speichern Sie sie nie als Foto, Screenshot oder Datei. Geben Sie sie nie auf einer Website oder in einem Chat ein.', 'Niemand von Epic Cash oder dieser Wallet wird je danach fragen.']),
        if (phone)
          HelpBlock.p('Um die Wörter erneut zu sehen, öffnen Sie $phrasePlace und geben $secret ein. Die App sendet sie nirgendwohin. Besser nicht kopieren: Nach dem Kopieren leert die Wallet die Zwischenablage nach 60 Sekunden und wenn die Wallet gesperrt oder geschlossen wird.')
        else
          HelpBlock.p('Um die Wörter erneut zu sehen, öffnen Sie $phrasePlace und geben $secret ein. Besser nicht kopieren: Nach dem Kopieren leert die Wallet die Zwischenablage nach 60 Sekunden und wenn die Wallet gesperrt oder geschlossen wird.'),
      ],
      id: HelpId.phrase,
    ),
    HelpTopic(
      'safety',
      'Sicherungen und Wiederherstellen',
      'Die Wiederherstellungsphrase ist die Sicherung. Um eine Wallet wiederherzustellen, geben Sie beim Wiederherstellen ihre Wörter ein.',
      [
        const HelpBlock.p('Die Wiederherstellungsphrase holt alles zurück, was auf der Blockchain steht, also das Guthaben.'),
        HelpBlock.p('**Zum Wiederherstellen** auf einem neuen ${phone ? 'Smartphone' : 'Computer'} oder nach einem Verlust: Öffnen Sie $restorePlace, geben Sie die Wörter ein und wählen Sie ${phone ? 'eine PIN' : 'ein Passwort'}. Wenn die Wallet geöffnet wird, durchsucht sie die Blockchain nach ihren Outputs. Das Guthaben erscheint nach diesem ersten Scan; die gefundenen Zahlungen sind als **Wiederhergestelltes Guthaben** gekennzeichnet.'),
        HelpBlock.p('**Was eine Wiederherstellung nicht zurückholt:** was nie auf der Blockchain stand, etwa wer was bezahlt hat, Notizen und Bezeichnungen, Kontakte, Rechnungen, Einstellungen und Wallet-Namen. Eine Wallet-Datendatei bewahrt sie: $historyBackupPlace.${phone ? ' Bewahren Sie die Datei außerhalb des Smartphones auf, zum Beispiel in einer E-Mail oder einem Cloud-Speicher.' : ''}'),
        const HelpBlock.p('**Die Wallet-Datendatei ist nicht die Wiederherstellungsphrase.** Sie enthält keine Wörter und kann die Wallet allein nicht wiederherstellen. Zum Wiederherstellen: zuerst die Wiederherstellungsphrase eingeben, dann die Datei importieren; die Wallet bietet das direkt nach der Wiederherstellung an.'),
        HelpBlock.p('**Guthaben sieht falsch aus?** Starten Sie $recheckPlace. Dabei wird die ganze Blockchain erneut nach den Outputs dieser Wallet durchsucht.'),
        if (!phone)
          const HelpBlock.p('**Die Dateien der Wallet** liegen unter [[Einstellungen › Diese Wallet › Wallet-Ordner|Settings › This wallet › Wallet folder]]. Bewahren Sie die Wiederherstellungsphrase auch mit einer Kopie davon auf: Sie hilft, wenn die Dateien verloren gehen.'),
      ],
      id: HelpId.backup,
    ),
    const HelpTopic(
      'safety',
      'Bevor Sie importieren',
      'Der Import liest ältere Wallets und Dateien nur. Sichern Sie zuerst jede Wallet; Sie importieren auf eigenes Risiko.',
      [
        HelpBlock.p('Dies ist eine frühe Version einer neuen App.'),
        HelpBlock.p('Der Import liest Ihre alten Wallets und Dateien nur; er löscht oder ändert sie nie.'),
        HelpBlock.p('Stellen Sie vor dem Fortfahren sicher, dass Sie von jeder Wallet eine Sicherung haben: ihre Wiederherstellungsphrase und, falls Sie sie aufbewahren, ihre Wallet-Dateien.'),
        HelpBlock.p('Sie importieren auf eigenes Risiko; für Verluste wird keine Verantwortung übernommen.'),
      ],
      id: HelpId.importWarning,
    ),
    HelpTopic(
      'network',
      phone ? 'Nodes' : 'Nodes: ein öffentlicher oder ein lokaler',
      phone
          ? 'Ein Node verbindet die Wallet mit dem Epic-Cash-Netzwerk. Die Wallet nutzt einen öffentlichen; wählen Sie einen anderen, wenn er zurückfällt.'
          : 'Ein Node verbindet die Wallet mit dem Epic-Cash-Netzwerk. Ein öffentlicher Node ist am schnellsten; ein lokaler gehört Ihnen.',
      [
        const HelpBlock.p('Die Wallet braucht einen Node, um die Blockchain zu lesen (Guthaben und Bestätigungen) und Transaktionen ins Netzwerk zu senden.'),
        if (phone)
          HelpBlock.p('Ein **öffentlicher Node** ist einer der Nodes, die andere betreiben. Er funktioniert sofort. Wer ihn betreibt, kann die IP-Adresse der Wallet sehen und nach welchen Outputs sie fragt${tor ? '; Tor verbirgt die Adresse' : ''}.')
        else
          const HelpBlock.ul(['**Öffentlicher Node** (Standard): einer der öffentlichen Nodes, die andere betreiben. Er funktioniert sofort. Wer ihn betreibt, kann die IP-Adresse der Wallet sehen und nach welchen Outputs sie fragt.', '**Lokaler Node**: läuft auf diesem Computer. Er lädt zuerst die ganze Blockchain herunter, was eine Weile dauert und Speicherplatz braucht, und gehört dann Ihnen. Während er synchronisiert, nutzt die Wallet einen öffentlichen Node.']),
        if (phone)
          HelpBlock.p('Ändern Sie ihn mit einem Tipp auf das Node-Symbol im Tab Wallet oder unter $nodePlace: Die Nodes sind mit ihrem Zustand aufgelistet. Tippen Sie auf einen, um sofort zu ihm zu wechseln, oder geben Sie eine Adresse ein, um die Liste zu filtern oder einen Node hinzuzufügen. Zum Senden braucht es einen synchronisierten Node; **zurück** oder **Antwortet nicht** heißt: einen anderen wählen.')
        else
          HelpBlock.p('Ändern Sie ihn unter $nodePlace: Die Nodes sind mit ihrem Zustand aufgelistet. Klicken Sie auf einen, um sofort zu ihm zu wechseln, oder geben Sie eine Adresse ein, um die Liste zu filtern oder einen Node hinzuzufügen. Zum Senden braucht es einen synchronisierten Node; fällt der Node zurück, bietet die Wallet einen anderen an.'),
      ],
      id: HelpId.node,
    ),
    HelpTopic(
      'network',
      'Epicbox',
      'Epicbox stellt Transaktionen zwischen Wallets zu und hält sie bereit, solange die andere Wallet offline ist.',
      [
        const HelpBlock.p('Beide Wallets wirken an jeder Transaktion mit, daher brauchen ihre Nachrichten einen Treffpunkt. Ein Epicbox-Server ist dieser Treffpunkt: Er hält eine an diese Wallet gesendete Zahlung bereit, bis die Wallet online kommt, und bringt die Antwort der Wallet zurück. Die Nachrichten sind verschlüsselt, und Epicbox kann die Münzen nicht ausgeben.'),
        const HelpBlock.p('Die Epicbox-Adresse ist der öffentliche Schlüssel der Wallet, dann **@** und der Name ihres Epicbox-Servers.'),
        if (phone)
          HelpBlock.p('Den Server legen Sie mit einem Tipp auf das Epicbox-Symbol im Tab Wallet fest oder unter $epicboxPlace: Die Server sind mit ihrem Zustand aufgelistet. Tippen Sie auf einen und bestätigen Sie, oder geben Sie eine Adresse ein, um die Liste zu filtern oder einen Server hinzuzufügen. Ein anderer Server ändert den Teil nach @, geben Sie die neue Adresse also den Personen, die bezahlen. Andere Epic-Cash-Wallets nutzen ebenfalls Epicbox; zwei Wallets können verschiedene Server nutzen.')
        else
          HelpBlock.p('Den Server legen Sie unter $epicboxPlace fest: Die Server sind mit ihrem Zustand aufgelistet. Klicken Sie auf einen und bestätigen Sie, oder geben Sie eine Adresse ein, um die Liste zu filtern oder einen Server hinzuzufügen. Ein anderer Server ändert den Teil nach @, geben Sie die neue Adresse also den Personen, die bezahlen. Andere Epic-Cash-Wallets nutzen ebenfalls Epicbox; zwei Wallets können verschiedene Server nutzen.'),
      ],
      id: HelpId.epicbox,
    ),
    if (tor && phone)
      HelpTopic(
        'network',
        'Tor',
        'Ein Schalter leitet die Verbindungen der Wallet über Tor und gibt ihr eine .onion-Adresse. Langsamer, privater. Standardmäßig aus.',
        [
          HelpBlock.p('Tor verbirgt die IP-Adresse der Wallet vor den Servern, mit denen sie spricht. Ist der Schalter unter $torPlace an, läuft die Epicbox-Verbindung über Tor, eine Zahlung an eine .onion-Adresse läuft über Tor, und die Wallet hat eine eigene Tor-Adresse (sie endet auf .onion), an die andere Wallets direkt zahlen können.'),
          const HelpBlock.ul([
            'Nichts, was die Wallet nutzt, ändert sich: derselbe Node, derselbe Epicbox-Server, dieselbe Adresse.',
            'Eine direkte Zahlung an eine Onion-Adresse läuft über Tor. Senden zeigt bei jeder Zahlung, welchen Weg sie nimmt.',
            'Langsamer als Epicbox ohne Tor. In manchen Ländern ist Tor blockiert; dort verbindet es sich nicht.',
            'Empfangen an der .onion-Adresse funktioniert, solange die App geöffnet ist; Epicbox arbeitet daneben weiter.',
            'Mit „Nur Tor“ unter Erweitert bleibt der Schalter an und lässt sich nicht ausschalten.',
          ]),
          const HelpBlock.p('**Startet…** heißt, Tor verbindet sich; die abgedeckten Verbindungen warten und weichen nie aus. **Nicht verbunden** heißt, es ist fehlgeschlagen: Wiederholen oder Tor ausschalten. Manche Wallets zeigen eine Tor-Adresse ohne .onion; beides ist dieselbe Adresse.'),
        ],
        id: HelpId.tor,
      )
    else if (tor)
      const HelpTopic(
        'network',
        'Tor',
        'Langsamer und privater: Ein Schalter leitet die Verbindungen der Wallet über Tor, ohne Ports zu öffnen. Standardmäßig aus.',
        [
          HelpBlock.p('Mit Tor läuft die Verbindung zum Epicbox-Server über Tor, und die Wallet hat eine Tor-Adresse (sie endet auf .onion), an die andere Wallets direkt zahlen können, von überall, ohne Weiterleitung am Router. Tor ändert die Adressen nicht, die Sie weitergeben.'),
          HelpBlock.ul([
            'Schalten Sie es unter [[Einstellungen › Datenschutz › Tor|Settings › Privacy › Tor]] ein. Die Tor-Zeile in der Seitenleiste zeigt den Zustand.',
            'Solange Tor startet oder nicht verbunden ist, wartet, was über Tor läuft; nichts geht daran vorbei. Wiederholen oder Tor ausschalten.',
            'Link · HTTP an eine http(s)-Adresse läuft nicht über Tor; Senden weist darauf hin.',
            'Link · HTTP-Empfang ist aus, solange Tor an ist: Zahlungen direkt von einer anderen Wallet kommen an der Link · Tor-Adresse an.',
            'In manchen Ländern ist Tor blockiert oder nicht erlaubt; dort verbindet es sich nicht.',
            'Mit „Nur Tor“ unter Erweitert bleibt der Schalter an und lässt sich nicht ausschalten.',
          ]),
          HelpBlock.p('Manche Wallets zeigen die Adresse ohne .onion; beides ist dieselbe Adresse.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      'Netzwerkmodi',
      tor ? 'Standard verbindet direkt. Nur Tor nie. Offline nutzt nichts außer ${phone ? 'diesem Smartphone' : 'diesem Computer'} und dem lokalen Netzwerk.' : 'Standard verbindet direkt. Offline nutzt nichts außer ${phone ? 'diesem Smartphone' : 'diesem Computer'} und dem lokalen Netzwerk.',
      [
        const HelpBlock.p('Wie die Wallet das Netzwerk erreicht, ist eine einzige Wahl auf der Seite **Erweitert** in den Einstellungen, unter Netzwerk.'),
        HelpBlock.ul([
          tor ? '**Standard**: verbindet direkt. Tor ist der Schalter unter $torPlace.' : '**Standard**: verbindet direkt.',
          if (tor)
            '**Nur Tor**: Tor ist immer an, und sein Schalter ist gesperrt. Nichts läuft über das offene Internet. Solange Tor startet oder fehlgeschlagen ist, sagt die Wallet **Wartet auf Tor**, und alles, was das Netzwerk braucht, wartet; den Grund nennt die ausgegraute Aktion.${phone ? '' : ' Der HTTP-Empfang ist aus, weil eine einfache Adresse diesen Computer verraten würde.'}',
          '**Offline**: kein Epicbox, kein Link außer an lokale Adressen, ${!phone && tor ? 'kein Tor, ' : ''}keine Statusprüfungen. Guthaben und Verlauf bleiben, wie zuletzt gesehen. ${phone ? '**Direkt · QR-Zahlung** und **Direkt · Dateiübertragung**' : '**Direkt · Dateiübertragung**'} funktionieren weiterhin: Sie nutzen den verwendeten Node, um die Chain zu lesen und zu senden, auch einen öffentlichen, und der Bildschirm sagt es. Für die meiste Privatsphäre nutzen Sie einen Node ${phone ? 'im lokalen Netzwerk' : 'auf diesem Computer oder im lokalen Netzwerk'}: Dann aktualisiert sich das Guthaben${phone ? '' : ', Link · HTTP empfängt über das lokale Netzwerk, wenn der HTTP-Empfang auf **Aus dem Internet** steht,'} und Guthaben neu prüfen läuft ebenfalls.',
        ]),
        const HelpBlock.p('Geben Sie den Node im Offline-Modus mit seiner IP-Adresse an, zum Beispiel **10.100.10.20:3413**. Namen werden nicht aufgelöst.'),
        if (!phone) const HelpBlock.p('Die Peers des integrierten Nodes sind eine Einstellung des Nodes, nicht des Modus.'),
        HelpBlock.p('${phone ? 'Der Startbildschirm' : 'Die Seitenleiste'} zeigt, wenn die Wallet offline ist${tor ? ' oder auf Tor wartet' : ''}. Mit dem Modus **Standard** ist wieder alles da.'),
      ],
      id: HelpId.modes,
    ),
    HelpTopic(
      'network',
      'Erweitert',
      'Zunächst alles aus. Jeder Schalter blendet einen weiteren Teil der Wallet an der passenden Stelle ein.',
      [
        const HelpBlock.p('**Erweitert** ist eine Seite in den Einstellungen für Teile, die die meisten nie brauchen. Alles darauf ist zunächst aus, damit die Wallet einfach bleibt. Ein Schalter blendet seinen Teil dort ein, wo er hingehört, und **Alles wieder ausblenden** schaltet alle aus.'),
        HelpBlock.ul([
          '**Outputs**: die Seite Outputs mit den Coins, aus denen das Guthaben besteht, und was Sie damit tun können.',
          '**Technische Details**: Slate-ID, Kernel, Commitments und Blockhöhe bei ${phone ? 'den Details einer Zahlung' : 'einer Transaktion'}. Ohne den Schalter zeigt der Link **Mehr** an einer Transaktion sie einmalig.',
          if (phone)
            '**Zahlungsoptionen**: Strategie und Wechselgeld aufteilen, unter [[Einstellungen › Transaktionen|Settings › Transactions]]: welche Outputs eine Zahlung ausgibt und ob ihr Wechselgeld aufgeteilt wird.'
          else
            '**Zahlungsoptionen**: ein Bereich auf Senden, in dem eine einzelne Zahlung Kleinste oder Alle wählt und ob das Wechselgeld aufgeteilt wird.',
          '**Server-Details**: Hosts, Latenz, Version und Blockhöhe in den Listen für Node und Epicbox und auf der Statuskarte.',
          if (phone)
            '**Ab einer Höhe neu prüfen**: lässt „Guthaben neu prüfen“ bei einer Blockhöhe oder einem Datum beginnen statt beim ersten Block. Beim Wiederherstellen steht die Wahl immer offen.'
          else
            '**Ab einer Höhe neu prüfen**: lässt „Guthaben neu prüfen“ auch unbestätigte Transaktionen verwerfen. Beim Wiederherstellen steht allen ein Startblock zur Wahl.',
          if (!phone) '**Integrierter Node**: lässt diesen Computer einen eigenen Node betreiben: Lokaler Node unter $nodePlace.',
          if (!phone) '**Protokolle**: die Gruppe Protokolle unter Hilfe, um den Protokollordner zu öffnen oder die Protokolle zu löschen. „Problem melden“ hängt das Protokoll in jedem Fall an.',
        ]),
        HelpBlock.p('Der **automatische Node-Wechsel** ist standardmäßig an. Antwortet Ihr Node 30 Sekunden lang nicht, wechselt die Wallet zum nächsten funktionierenden Node Ihrer Liste, nur für diese Sitzung: Ihr eigener Node bleibt gespeichert, und die Wallet ist beim nächsten Start wieder darauf, oder sobald Sie selbst einen Node wählen. Im Offline-Modus wechselt sie nie${phone ? '' : ', und auch nie weg von einem Node auf diesem Computer'}${tor ? '; mit „Nur Tor“ wechselt sie nur zu einem Node, der über Tor erreichbar ist' : ''}.'),
        const HelpBlock.p('**Bestätigungen** legt fest, wie viele Blöcke eine empfangene Zahlung wartet, bevor ihre Outputs verfügbar sind: standardmäßig 6, jeder Wert von 1 bis 30. Weniger Bestätigungen sind schneller, schützen aber weniger vor einer Reorganisation der Blockchain.'),
        const HelpBlock.p('**Experimentell** enthält **Kopplung** und **Rechnungen**, beide zu Beginn aus. Kopplung bringt Koppeln und gekoppelte Kontakte; Rechnungen bringt Zahlungsanforderungen und Rechnungen zwischen gekoppelten Kontakten und braucht Kopplung. Aus sind sie verborgen, und nichts wird für sie abgerufen; bestehende Kopplungen bleiben gespeichert und kommen zurück, sobald der Schalter wieder an ist.'),
        const HelpBlock.p('Dieselbe Seite legt den Netzwerkmodus fest: siehe „Netzwerkmodi“.'),
      ],
      id: HelpId.advanced,
    ),
    HelpTopic(
      'trouble',
      'Fehlerbehebung',
      phone
          ? 'Meist ist ein Node noch nicht synchronisiert oder ein Empfänger hat noch nicht geantwortet.'
          : 'Meist ist ein Node noch nicht synchronisiert, ein Empfänger hat noch nicht geantwortet, oder ein Port ist belegt.',
      [
        if (phone)
          const HelpBlock.p('**„Node nicht synchronisiert“: Senden nicht möglich.** Senden ist möglich, sobald der Node aufgeholt hat. Warten Sie kurz oder tippen Sie im Tab Wallet auf das Node-Symbol und wählen Sie einen anderen Node.')
        else
          const HelpBlock.p('**„Node nicht synchronisiert“: Senden nicht möglich.** Senden ist möglich, sobald der Node aufgeholt hat. Warten Sie kurz oder wählen Sie unter [[Einstellungen › Node|Settings › Node]] einen anderen Node.'),
        if (phone)
          const HelpBlock.p('**„Epicbox antwortet nicht“.** Die Wallet erreicht ihren Epicbox-Server nicht. Warten Sie einen Moment; bleibt es so, prüfen Sie die Verbindung oder tippen Sie im Tab Wallet auf das Epicbox-Symbol und wählen Sie einen anderen Server. In der Zwischenzeit funktioniert Direkt · Dateiübertragung.')
        else
          const HelpBlock.p('**„Epicbox antwortet nicht“.** Die Wallet erreicht ihren Epicbox-Server nicht. Warten Sie einen Moment; bleibt es so, prüfen Sie die Verbindung oder wählen Sie unter [[Einstellungen › Transaktionen|Settings › Transactions]] einen anderen Server. In der Zwischenzeit funktioniert Direkt · Dateiübertragung.'),
        const HelpBlock.p('**Eine Zahlung zeigt „Wartet auf Empfänger“.** Die Wallet des Empfängers hat noch nicht geantwortet. Bitten Sie ihn, sie zu öffnen. Wird er das nie tun, stornieren Sie die Zahlung unter Aktivität, um die Outputs freizugeben.'),
        if (phone)
          const HelpBlock.p('**Eine Zahlung ist nicht angekommen.** Prüfen Sie die Statussymbole im Tab Wallet: Node synchronisiert, Epicbox verbunden. Nach einem Wechsel des Epicbox-Servers braucht der Absender die neue Adresse. Außerdem muss die Wallet des Absenders die Transaktion abschließen; danach dauern die Bestätigungen einige Minuten.')
        else
          const HelpBlock.p('**Eine Zahlung ist nicht angekommen.** Prüfen Sie unter Empfangen, ob der Empfang eingeschaltet und der Node synchronisiert ist. Nach einem Wechsel des Epicbox-Servers braucht der Absender die neue Adresse. Außerdem muss die Wallet des Absenders die Transaktion abschließen; danach dauern die Bestätigungen einige Minuten.'),
        if (phone && tor)
          const HelpBlock.p('**Tor zeigt „Nicht verbunden“.** Tor konnte sein Netzwerk nicht erreichen. Drücken Sie unter [[Einstellungen › Datenschutz & Netzwerk|Settings › Privacy & network]] auf „Wiederholen“ oder schalten Sie Tor aus; in der Zwischenzeit geht nichts hinaus.'),
        if (!phone) ...[
          HelpBlock.p('**„Port 3415 wird von einem anderen Programm genutzt“.** Ein anderes Programm, oft eine andere Epic-Wallet, nutzt den Port für Link · HTTP-Zahlungen. Schließen Sie es und drücken Sie dann unter Empfangen auf „Erneut versuchen“. ${tor ? 'Epicbox, Link · Tor und Direkt · Dateiübertragung funktionieren' : 'Epicbox und Direkt · Dateiübertragung funktionieren'} in der Zwischenzeit weiter.'),
          const HelpBlock.p('**„Ein anderes Epic-Programm nutzt diesen Ordner“.** Eine andere Epic-Wallet oder ein Node hat dieselben Dateien geöffnet. Schließen Sie sie und versuchen Sie es erneut.'),
        ],
        if (phone)
          const HelpBlock.p('**PIN vergessen.** Löschen Sie die Wallet auf dem Entsperrbildschirm und stellen Sie sie mit ihrer Wiederherstellungsphrase und einer neuen PIN wieder her. Ohne die Phrase lassen sich die EPIC nicht zurückholen.')
        else
          const HelpBlock.p('**„Falsches Passwort“.** Prüfen Sie die Feststelltaste und das Tastaturlayout. Passwort vergessen: Stellen Sie die Wallet mit ihrer Wiederherstellungsphrase wieder her und wählen Sie ein neues.'),
        HelpBlock.p('**Das Guthaben sieht falsch aus.** Starten Sie $recheckPlace.'),
        HelpBlock.p(tor
            ? '**Eine Aktion ist ausgegraut und nennt „Offline-Modus“ oder „Wartet auf Tor“.** Offline oder Nur Tor ist unter Erweitert an. Stellen Sie dort den Modus auf Standard zurück oder warten Sie, bis Tor verbunden ist.'
            : '**Eine Aktion ist ausgegraut und nennt „Offline-Modus“.** Offline ist unter Erweitert an. Stellen Sie dort den Modus auf Standard zurück.'),
      ],
      id: HelpId.trouble,
    ),
    const HelpTopic(
      'trouble',
      'Zahlungen einer anderen Wallet',
      'Zahlungen, die diese Wallet nicht selbst gemacht oder empfangen hat: Dieselbe Wiederherstellungsphrase wird in einer anderen Wallet verwendet.',
      [
        HelpBlock.p('Eine Zeile **Von einer anderen Wallet gesendet** oder **Von einer anderen Wallet empfangen** ist eine Zahlung einer anderen Wallet, die dieselbe Wiederherstellungsphrase verwendet. Die Blockchain zeigt diese Coins als ausgegeben oder empfangen, deshalb führt diese Wallet sie auf.'),
        HelpBlock.p('Der Betrag ist, was diese Wallet nach Abzug des zurückgekommenen Wechselgelds verlassen hat, oder was angekommen ist. Die Gegenseite und die Gebühr sind hier nicht bekannt.'),
        HelpBlock.p('**Wenn Sie mit dieser Phrase keine andere Wallet nutzen**, fragen Sie zuerst einen anderen Node: Wechseln Sie den Node und nutzen Sie „Guthaben neu prüfen“. Ein Node, der Coins in seinen Antworten auslässt, kann sie ausgegeben aussehen lassen. Zeigt er sie weiter als ausgegeben, kennt vielleicht jemand anderes die Wiederherstellungsphrase: Bringen Sie die EPIC in eine neue Wallet mit neuer Phrase.'),
        HelpBlock.p('**Ein Versand, der mit „Der Node zeigt diese Coins schon als ausgegeben, und diese Wallet hat sie nicht ausgegeben. Wahrscheinlich hat das eine andere Wallet mit Ihrer Wiederherstellungsphrase getan.“ scheitert**, wurde freigegeben. Die Wallet aktualisiert sich; senden Sie erneut, wenn das Guthaben stimmt.'),
      ],
      id: HelpId.otherWallet,
    ),
    HelpTopic(
      'trouble',
      'Eine Zahlung stornieren',
      'Wann Stornieren sicher ist, wann nicht, und was mit den Coins geschieht.',
      [
        const HelpBlock.h('Senden', anchor: HelpAnchor.sending),
        const HelpBlock.p('Eine Zahlung, die Sie senden, wartet auf die Antwort der anderen Wallet. Solange sie wartet, ist Stornieren sicher: Ohne Ihre Wallet kann nichts ins Netzwerk gelangen, und die Coins gehören sofort wieder Ihnen. Die andere Wallet zeigt die Zahlung vielleicht noch als wartend, kann sie aber nicht abschließen.'),
        const HelpBlock.p('Sobald die Antwort da ist, schließt Ihre Wallet die Zahlung ab und sendet sie in einem Schritt ins Netzwerk. Eine gesendete Zahlung lässt sich nicht stornieren, rückgängig machen oder erstatten; nur der Empfänger kann sie zurückzahlen. Hat das Netzwerk sie abgelehnt, bietet die Wallet an, sie erneut zu senden oder zu stornieren. Dieses Stornieren fragt zuerst das Netzwerk und geht nur weiter, wenn das Netzwerk die Zahlung nicht hat.'),
        const HelpBlock.p('Eine Zahlung, die unbeantwortet bleibt, storniert sich nach etwa einem Tag (1.440 Blöcken) von selbst, und die Coins sind wieder frei. Das gilt für Epicbox-, Link- und Direkt-Zahlungen gleichermaßen: Stornieren ist sicher, bis die Antwort der anderen Seite in Ihrer Wallet ist.'),
        HelpBlock.p('**Eine Zahlung scheint festzuhängen.** Meist ist die andere Wallet offline. Warten Sie, oder stornieren Sie sie unter $cancelPlace und senden Sie neu; eine stornierte Zahlung kann später nicht mehr durchgehen.'),
        const HelpBlock.h('Empfangen', anchor: HelpAnchor.receiving),
        const HelpBlock.p('Kommt eine Zahlung an, antwortet Ihre Wallet sofort, und nichts von Ihnen ist gesperrt. Von da an schließt die Wallet des Absenders sie ab und sendet sie ins Netzwerk, meist innerhalb von Minuten. Darum bleibt Stornieren 15 Minuten lang aus dem Weg, und länger, solange der Absender meldet, dass er gesendet hat.'),
        const HelpBlock.p('Danach räumt Stornieren eine Zahlung ab, die der Absender nie gesendet hat. Es ist nicht sicher: Die Wallet fragt zuerst das Netzwerk und lehnt ab, wenn die Zahlung schon dort ist. Eine stornierte Zahlung bleibt im Blick. Sendet der Absender sie später doch, kommt sie trotzdem an und erscheint als empfangen.'),
        const HelpBlock.h('Rechnungen (experimentell)', anchor: HelpAnchor.requests),
        const HelpBlock.p('Eine Anforderung, die Sie gesendet haben, hält keine Coins, bis sie bezahlt ist. Ziehen Sie sie vorher jederzeit zurück: Der Zahler kann sie dann nicht mehr bezahlen, und nichts bewegt sich. Eine Anforderung, die niemand bezahlt, läuft nach 24 Stunden ab. Eine als QR-Code gezeigte Anforderung kann einmal bezahlt werden; ein zweiter Scan wird abgelehnt, es wird also nichts doppelt bezahlt.'),
        if (phone)
          const HelpBlock.p('Eine Anforderung, die Sie bezahlt haben, ist umgekehrt: Die andere Seite hält Ihre signierte Zahlung und schließt sie ab. Stornieren kommt, wenn ihre Zeit abläuft, etwa einen Tag nach dem Bezahlen, oder früher, wenn die andere Seite sie zurückzieht. Stornieren gibt die Coins hier frei, aber die andere Seite könnte die Zahlung noch senden, bis diese Coins wieder ausgegeben sind.')
        else
          const HelpBlock.p('Eine Anforderung, die Sie bezahlt haben, ist umgekehrt: Die andere Seite hält Ihre signierte Zahlung und schließt sie ab. Stornieren kommt, wenn ihre Zeit abläuft, etwa einen Tag nach dem Bezahlen, oder früher, wenn die andere Seite sie zurückzieht. Stornieren gibt die Coins hier frei, aber die andere Seite könnte die Zahlung noch senden, bis diese Coins wieder ausgegeben sind. Sie an sich selbst zu senden, was mit dem Stornieren angeboten wird, macht es endgültig.'),
      ],
      id: HelpId.cancel,
    ),
    if (!phone)
      const HelpTopic(
        'maintenance',
        'Alte Wallet-Ordner aufräumen',
        '„Aus der Liste entfernen“ lässt den Ordner der Wallet auf der Festplatte. Gelöscht wird er von Hand, mit notierter Wiederherstellungsphrase oder bei leerer Wallet.',
        [
          HelpBlock.ul([
            '**Aus der Liste entfernen** unter [[Einstellungen › Alle Wallets|Settings › All wallets]] nimmt eine Wallet aus der Liste. Ihr Ordner bleibt auf der Festplatte, und die Seite bietet sie unter **Aus der Liste entfernt** wieder an.',
            '**Wer einen Wallet-Ordner ohne seine Wiederherstellungsphrase löscht, verliert die EPIC darin.** Nur eine Wallet löschen, deren Phrase notiert ist, oder eine, die leer ist und nicht mehr gebraucht wird.',
            'Die Ordner liegen unter **wallets** im Datenordner (**Ordner öffnen** neben [[Einstellungen › Diese Wallet › App-Dateien|Settings › This wallet › App files]]), einer je Wallet, benannt nach ihrer Kennung; **WALLET.txt** darin nennt den Namen der Wallet. Bei geschlossenem Epic Cash Desktop nur diesen einen Kennungsordner löschen und alles andere lassen, wie es ist.',
          ]),
        ],
        id: HelpId.cleanup,
      ),
    ...deviceHelpTopics('de', phone: phone),
  ];
}
