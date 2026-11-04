// SPDX-License-Identifier: Apache-2.0
/// German help: the topics and sections of help_content.dart in German, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';
import 'help_devices.dart';
import 'help_directory.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;

const List<HelpSection> helpSectionsDe = [
  (id: 'start', title: 'Erste Schritte', lede: 'Empfangen, senden und per Datei bezahlen.', art: 'help-start'),
  (id: 'how', title: 'So funktioniert Epic Cash', lede: 'Beide Wallets wirken mit. Bestätigungen, Privatsphäre, Wechselgeld und Gebühren.', art: 'help-how'),
  (id: 'safety', title: 'Die Wallet schützen', lede: 'Die Wiederherstellungsphrase ist Sicherung und Schlüssel zugleich.', art: 'help-safety'),
  (id: 'network', title: 'Nodes und Epicbox', lede: 'Womit sich die Wallet verbindet, und Tor.', art: 'help-network'),
  (id: 'trouble', title: 'Wenn etwas nicht klappt', lede: 'Die üblichen Ursachen und was zu tun ist.', art: 'help-trouble'),
  (id: 'maintenance', title: 'Wartung', lede: 'Alte Wallet-Ordner auf der Festplatte und die Einstellungsdatei.', art: 'help-maintenance'),
];

List<HelpTopic> helpTopicsDe(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'diesem Smartphone' : 'diesem Computer';
  final secret = phone ? 'Ihre PIN oder Passphrase' : 'das Wallet-Passwort';
  final nodePlace = phone ? '[[Einstellungen › Netzwerk & Datenschutz › Node|Settings › Network & privacy › Node]]' : '[[Einstellungen › Node|Settings › Node]]';
  final epicboxPlace = phone ? '[[Einstellungen › Netzwerk & Datenschutz › Epicbox|Settings › Network & privacy › Epicbox]]' : '[[Einstellungen › Zahlungen › Epicbox|Settings › Payments › Epicbox]]';
  final torPlace = phone ? '[[Einstellungen › Netzwerk & Datenschutz › Nur Tor|Settings › Network & privacy › Tor only]]' : '[[Einstellungen › Netzwerk & Datenschutz › Nur Tor|Settings › Network & privacy › Tor only]]';
  final netPlace = '[[Einstellungen › Netzwerk & Datenschutz|Settings › Network & privacy]]';
  final cancelPlace = phone
      ? '[[Aktivität|Activity]] (die Zahlung öffnen, dann „Zahlung stornieren“)'
      : '[[Aktivität › die Transaktion › Zahlung stornieren|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[Einstellungen › Diese Wallet › Wallet-Daten exportieren|Settings › This wallet › Export wallet data]]'
      : '[[Einstellungen › Wallet › Wallet-Daten exportieren|Settings › Wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**Mit Phrase wiederherstellen** (auf dem ersten Bildschirm oder unter [[Einstellungen › Diese Wallet|Settings › This wallet]])'
      : '**Mit Phrase wiederherstellen** (auf dem ersten Bildschirm, unter Entsperren › Wallet hinzufügen oder unter [[Einstellungen › Wallets|Settings › Wallets]])';
  final recheckPlace = phone ? '[[Einstellungen › Diese Wallet › Guthaben neu prüfen|Settings › This wallet › Recheck balance]]' : '[[Einstellungen › Wallet › Guthaben neu prüfen|Settings › Wallet › Recheck balance]]';
  final payPlace = phone ? '[[Einstellungen › Transaktionen|Settings › Transactions]]' : '[[Einstellungen › Zahlungen|Settings › Payments]]';
  final filesPlace = '[[Einstellungen › Dateien & Protokolle|Settings › Files & logs]]';
  final phrasePlace = phone ? '[[Einstellungen › Sicherheit › Wiederherstellungsphrase sichern|Settings › Security › Back up recovery phrase]]' : '[[Einstellungen › Sicherheit › Seed-Phrase|Settings › Security › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Die ersten EPIC empfangen',
      'Öffnen Sie Empfangen, kopieren Sie die Epicbox-Adresse und geben Sie sie dem Absender. Die Zahlung kommt von selbst an.',
      [
        HelpBlock.p('Die Epicbox-Adresse ist ein langer Code, der auf **@** und den Namen des Epicbox-Servers endet, zum Beispiel **…@${hostSettings.epicboxUse}**. Sie kann gefahrlos weitergegeben werden: Andere brauchen sie zum Bezahlen, und niemand kann damit etwas wegnehmen.'),
        const HelpBlock.ol(['Öffnen Sie [[Empfangen|Receive]].', 'Kopieren Sie die Adresse (oder zeigen Sie ihren QR-Code) und senden Sie sie der Person, die bezahlt.', 'Die Zahlung erscheint von selbst unter Aktivität.']),
        if (phone)
          const HelpBlock.p('Empfangen funktioniert, solange die App geöffnet und der Node synchronisiert ist. Eine Zahlung, die bei geschlossener App gesendet wird, wartet auf dem Epicbox-Server, wie in einem Postfach, und kommt beim nächsten Entsperren an.')
        else
          const HelpBlock.p('Der Empfang startet nach dem Entsperren von selbst, sobald der Node synchronisiert ist. Ist die Wallet beim Bezahlen geschlossen, hält Epicbox die Zahlung bereit, und die Wallet holt sie beim nächsten Entsperren ab.'),
        HelpBlock.p('Eine neue Zahlung wartet zuerst darauf, dass die Wallet des Absenders sie abschließt, und wird dann als „Wird bestätigt“ angezeigt. Ab der $confirmations. Bestätigung ist sie verfügbar.'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      'An jemanden senden',
      'Öffnen Sie Senden, fügen Sie die Epicbox-Adresse ein, geben Sie den Betrag ein, prüfen Sie die Gebühr und senden Sie.',
      [
        HelpBlock.ol(['Öffnen Sie [[Senden|Send]] und fügen Sie die Adresse des Empfängers ein oder wählen Sie einen Kontakt.', 'Geben Sie den Betrag ein. Die Gebühr wird vor dem Senden angezeigt.', phone ? 'Tippen Sie auf **Weiter**, kontrollieren Sie alles und tippen Sie dann auf **… EPIC senden**.' : 'Drücken Sie **Prüfen**, kontrollieren Sie alles und drücken Sie dann **… EPIC senden**.']),
        const HelpBlock.p('Jetzt muss die Wallet des Empfängers antworten (siehe „Warum braucht eine Transaktion beide Seiten?“). Über Epicbox muss der Empfänger nicht gerade online sein: Die Zahlung wartet, bis seine Wallet geöffnet wird. Bis dahin sind die verwendeten Coins gesperrt, damit sie nicht doppelt ausgegeben werden.'),
        HelpBlock.p('Kommt die Antwort zurück, schließt die Wallet die Zahlung ab und stellt sie von selbst ins Netzwerk. Ab der $confirmations. Bestätigung ist sie endgültig.'),
        HelpBlock.p('**Keine Antwort?** Nach einigen Minuten zeigt der Status „Wartet auf Empfänger“. Bitten Sie den Empfänger, seine Wallet zu öffnen. Kommt die Antwort nie, stornieren Sie die Zahlung unter $cancelPlace, um die Coins freizugeben. Eine Zahlung, die niemand beantwortet, wird nach etwa einem Tag von selbst storniert.'),
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
        const HelpBlock.p('Direkt · Dateiübertragung durchläuft denselben Handschlag wie Epicbox, nur werden die Nachrichten von Hand übergeben, zum Beispiel per Chat oder USB-Stick. Das funktioniert ohne Epicbox und ohne dass beide Wallets gleichzeitig online sind.'),
        if (phone)
          const HelpBlock.ol(['**Absender:** wählt unter Senden **Direkt · Dateiübertragung**, gibt den Betrag ein und teilt die Datei (sie endet auf .tx). Ab jetzt sind die Coins gesperrt.', '**Empfänger:** öffnet die Datei unter [[Empfangen › Direkt · Datei|Receive › Direct · File]]. Seine Wallet signiert sie und teilt eine Antwortdatei (sie endet auf .response). Diese Datei schickt er zurück.', '**Absender:** öffnet die Antwortdatei unter [[Empfangen › Direkt · Datei|Receive › Direct · File]]. Die Wallet schließt die Zahlung ab und sendet sie.'])
        else
          const HelpBlock.ol(['**Absender:** wählt unter Senden **Direkt · Dateiübertragung**, gibt den Betrag ein und speichert die Datei (sie endet auf .tx). Ab jetzt sind die Coins gesperrt.', '**Empfänger:** öffnet die Datei unter [[Empfangen › Transaktionsdateien › Transaktionsdatei signieren|Receive › Transaction files › Sign a transaction file]]. Seine Wallet signiert sie und speichert eine Antwortdatei (sie endet auf .response). Diese Datei schickt er zurück.', '**Absender:** öffnet die Antwortdatei unter [[Empfangen › Transaktionsdateien › Antwortdatei abschließen|Receive › Transaction files › Finalize a response file]]. Die Wallet schließt die Zahlung ab und sendet sie.']),
        const HelpBlock.p('Andere Epic-Cash-Wallets nennen diese Schritte anders. Kommt die Antwortdatei nie, stornieren Sie die Zahlung unter Aktivität, um die Coins freizugeben.'),
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
          HelpBlock.ol(['**Absender:** wählt unter Senden **Direkt · QR-Zahlung**, gibt den Betrag ein, tippt auf **Zahlungs-QR erstellen** und dann auf **QR anzeigen**. Der Code bleibt verborgen, bis Sie ihn zeigen, zählt 3, 2, 1 und verbirgt sich nach 40 Sekunden von selbst.', '**Empfänger:** tippt unter [[Empfangen › Direkt · QR|Receive › Direct · QR]] auf **Zahlungs-QR scannen**, nimmt die Zahlung an und zeigt dann die Antwort auf dieselbe Weise.', '**Absender:** tippt auf **Antwort scannen**. Die Wallet sendet die Zahlung, und der Verlauf zeigt den Fortgang.']),
          HelpBlock.p('Halten Sie den Code im Bild, bis alle Teile gelesen sind: Ring und Zähler zeigen, wie weit es ist. Ein Code, der kein Zahlungs-QR ist, wird ignoriert, mit einem Hinweis. Auf dem Code-Bildschirm sind Screenshots gesperrt.'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      'Zahlungsmethoden und Vorgaben fürs Senden',
      'Jede Methode ist ein Schalter; Epicbox ist standardmäßig an. Senden öffnet sich mit der Standardmethode.',
      [
        HelpBlock.p('Die Seite ${phone ? 'Transaktionen' : 'Zahlungen'} unter $payPlace enthält drei Dinge.'),
        HelpBlock.ul([
          '**Zahlungsmethoden.** Je ein Schalter. **Epicbox** ist standardmäßig an; ist es aus, verbindet sich die Wallet mit keinem Server, also gibt es keine Epicbox-Zahlungen oder Rechnungen, und Empfangen zeigt keine Epicbox-Adresse (Zahlungen an sie warten auf dem Server). ${tor ? "**Link · HTTP** (an Web-Adressen), **Link · Tor** (an .onion-Adressen${phone ? ' und mit einer Tor-Adresse dieses Smartphones, unter der Sie bezahlt werden' : ''}) und ${phone ? '**Direkt · QR-Zahlung** und ' : ''}**Direkt · Dateiübertragung**" : "**Link · HTTP** (an Web-Adressen)${phone ? ', **Direkt · QR-Zahlung**' : ''} und **Direkt · Dateiübertragung**"} brauchen keinen Epicbox-Server. Eine Methode, die aus ist, erscheint nicht bei Senden und Empfangen.${phone ? ' Auf einem Smartphone hat **Link · HTTP** keinen Schalter: es sendet nur, an jede eingefügte http(s)-Adresse.' : ''}',
          '**Standardmethode.** Die Methode, mit der sich der Bildschirm Senden öffnet; auf Senden lässt sich eine andere wählen.',
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
            '**Epicbox**: etwa 52 Zeichen, beginnend mit **es**, dann **@** und der Server, zum Beispiel **esXXXX…XXXX@${hostSettings.epicboxUse}**. Die Standardmethode; der Empfänger darf offline sein.',
            if (tor)
              '**Link · HTTP** und **Link · Tor**: die eigene Wallet des Empfängers, gerade geöffnet. Eine Webadresse wie **http://host:${appConfig.httpListenPort}** läuft über Link · HTTP; eine Tor-Adresse aus 56 Zeichen, die auf **.onion** endet, über Link · Tor, also über Tor.'
            else
              '**Link · HTTP**: die eigene Wallet des Empfängers, gerade geöffnet. Eine Webadresse wie **http://host:${appConfig.httpListenPort}** läuft über Link · HTTP.',
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
        HelpBlock.p('Epic Cash nutzt Mimblewimble. Statt eine Adresse und einen Betrag in die Chain zu schreiben, bauen die beiden Wallets jede Transaktion gemeinsam, wie bei einem Handschlag:'),
        HelpBlock.ol(['Die Wallet des Absenders beginnt und sperrt die Outputs, die gesendet werden.', 'Die Wallet des Empfängers fügt ihren Teil hinzu und signiert.', 'Die Wallet des Absenders signiert ebenfalls, schließt die Transaktion ab und sendet sie ins Netzwerk.']),
        HelpBlock.p('Etwas muss die Nachrichten zwischen den beiden Wallets übermitteln. **Epicbox** hält jede Nachricht bereit, solange die andere Wallet offline ist, sodass nicht beide gleichzeitig online sein müssen. ${tor ? '**Link · HTTP** und **Link · Tor** gehen direkt' : '**Link · HTTP** geht direkt'} zur anderen Wallet, solange sie geöffnet ist. **Direkt · Dateiübertragung** mit einer Transaktionsdatei ist der manuelle Weg.'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      'Bestätigungen',
      'Eine Zahlung ist ab der $confirmations. Bestätigung endgültig.',
      [
        const HelpBlock.p('Nimmt das Netzwerk eine Transaktion an, legt ein Miner sie in einen Block. Der Block mit der Transaktion ist die erste Bestätigung; jeder weitere Block fügt eine hinzu und macht die Transaktion schwerer rückgängig zu machen.'),
        HelpBlock.p('Diese Wallet betrachtet eine Transaktion ab der **$confirmations. Bestätigung** als endgültig. Bis dahin wird sie als **Wird bestätigt** angezeigt, und empfangene Outputs sind noch nicht verfügbar. Die Zahl ist eine Einstellung: standardmäßig 6, jeder Wert von 1 bis 30. Weniger Bestätigungen sind schneller, sind aber weniger sicher: Hin und wieder ersetzt die Chain ihre neuesten Blöcke (eine Reorganisation), und eine Zahlung mit wenigen Bestätigungen kann dadurch rückgängig gemacht werden.'),
        const HelpBlock.ul(['**Wartet**: Beide Wallets müssen die Zahlung signieren. Über Epicbox geschieht das von selbst.', '**Wird bestätigt**: Die Zahlung ist in der Chain und sammelt Bestätigungen.', '**Verfügbar**: Die Bestätigungen sind da, und die Coins können ausgegeben werden.']),
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
        HelpBlock.p('Was nicht verborgen ist: Der Node und der Epicbox-Server sehen die IP-Adresse der Wallet, und ein öffentlicher Node kann sehen, nach welchen Outputs die Wallet fragt. ${tor ? 'Mit **Nur Tor** verbindet sich die Wallet über Tor mit dem Node und dem Epicbox-Server. ' : ''}Ein VPN verbirgt die IP-Adresse.'),
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
        HelpBlock.p('Die Standardeinstellung legen Sie unter $payPlace fest, mit eingeschalteten Zahlungsoptionen unter Erweitert.'),
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
        HelpBlock.p('Sie wird vor dem Senden als **Netzwerkgebühr** angezeigt. **Max.** neben dem Betrag trägt das ganze verfügbare Guthaben abzüglich der genauen Gebühr ein, sodass kein Wechselgeld übrig bleibt.'),
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
    if (phone)
      const HelpTopic(
        'safety',
        'PIN oder Passphrase',
        'Die PIN oder eine Passphrase entsperrt diese Wallet auf diesem Smartphone. Nur die Wiederherstellungsphrase stellt die Coins wieder her.',
        [
          HelpBlock.p('Die PIN oder eine Passphrase entsperrt diese Wallet auf diesem Smartphone; nur die Wiederherstellungsphrase stellt die Coins wieder her. Eine Passphrase ist länger und schwerer zu erraten: mindestens 10 Zeichen, nicht nur Ziffern. Einschalten unter [[Einstellungen › Sicherheit|Settings › Security]].'),
          HelpBlock.p('Die Zeit zum Knacken, die bei der Wahl einer Passphrase angezeigt wird, ist eine Schätzung für dieses Smartphone.'),
          HelpBlock.p('**Vergessen?** Stellen Sie die Wallet aus ihrer Wiederherstellungsphrase wieder her und wählen Sie eine neue.'),
        ],
        id: HelpId.passphrase,
      ),
    HelpTopic(
      'safety',
      'Sicherungen und Wiederherstellen',
      'Die Wiederherstellungsphrase ist die Sicherung. Um eine Wallet wiederherzustellen, geben Sie ihre Wörter unter Mit Phrase wiederherstellen ein.',
      [
        const HelpBlock.p('Die Wiederherstellungsphrase holt alles zurück, was in der Chain steht, also das Guthaben.'),
        HelpBlock.p('**Zum Wiederherstellen** auf einem neuen ${phone ? 'Smartphone' : 'Computer'} oder nach einem Verlust: Öffnen Sie $restorePlace, geben Sie die Wörter ein und wählen Sie ${phone ? 'eine PIN' : 'ein Passwort'}. Wenn die Wallet geöffnet wird, durchsucht sie die Chain nach ihren Outputs. Das Guthaben erscheint nach diesem ersten Scan; die gefundenen Zahlungen sind als **Wiederhergestelltes Guthaben** gekennzeichnet.'),
        HelpBlock.p('**Was eine Wiederherstellung nicht zurückholt:** was nie in der Chain stand, etwa wer was bezahlt hat, Notizen und Bezeichnungen, Kontakte, Rechnungen, Einstellungen und Wallet-Namen. Eine Wallet-Datendatei bewahrt sie: $historyBackupPlace.${phone ? ' Bewahren Sie die Datei außerhalb des Smartphones auf, zum Beispiel in einem Cloud-Speicher oder auf einem USB-Stick.' : ''}'),
        const HelpBlock.p('**Die Wallet-Datendatei ist nicht die Wiederherstellungsphrase.** Sie enthält keine Wörter und kann die Wallet allein nicht wiederherstellen. Zum Wiederherstellen: zuerst die Wiederherstellungsphrase eingeben, dann die Datei importieren; die Wallet bietet das direkt nach der Wiederherstellung an.'),
        HelpBlock.p('**Guthaben sieht falsch aus?** Starten Sie $recheckPlace. Dabei wird die ganze Chain erneut nach den Outputs dieser Wallet durchsucht.'),
        if (!phone)
          const HelpBlock.p('**CSV exportieren** speichert die Zahlungsliste als Tabellendatei mit dem Namen **epic-payments-<Wallet>-<Datum>.csv**, mit den Spalten Datum, Typ, Status, Betrag, Gebühr, Gegenpartei, Notiz, Slate-ID, Kernel und Blockhöhe. Sie ist nicht verschlüsselt: Jeder, der die Datei hat, kann Beträge, Daten, Adressen und Notizen lesen. Sie lässt sich nicht wieder importieren; dafür gibt es **Wallet-Daten exportieren**.'),
        if (!phone)
          const HelpBlock.p('**Die Dateien der Wallet** liegen unter [[Einstellungen › Dateien & Protokolle › Wallet-Ordner|Settings › Files & logs › Wallet folder]]. Bewahren Sie die Wiederherstellungsphrase auch mit einer Kopie davon auf: Sie hilft, wenn die Dateien verloren gehen.'),
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
        const HelpBlock.p('Die Wallet braucht einen Node, um die Chain zu lesen (Guthaben und Bestätigungen) und Transaktionen ins Netzwerk zu senden.'),
        if (phone)
          HelpBlock.p('Ein **öffentlicher Node** ist einer der Nodes, die andere betreiben. Er funktioniert sofort. Wer ihn betreibt, kann die IP-Adresse der Wallet sehen und nach welchen Outputs sie fragt${tor ? '; mit **Nur Tor** erreicht die Wallet ihn über Tor' : ''}.')
        else
          const HelpBlock.ul(['**Öffentlicher Node** (Standard): einer der öffentlichen Nodes, die andere betreiben. Er funktioniert sofort. Wer ihn betreibt, kann die IP-Adresse der Wallet sehen und nach welchen Outputs sie fragt.', '**Lokaler Node**: läuft auf diesem Computer als eigenes Programm, das mit der App startet und stoppt. Er lädt zuerst die ganze Chain herunter (beim ersten Mal etwa 4 GB, danach täglich ein wenig), was eine Weile dauert; auf der Festplatte belegt er etwa 5 GB und wächst langsam. Während er synchronisiert, zeigt die Wallet seinen Fortschritt und nutzt einen öffentlichen Node. Siehe „Den lokalen Node betreiben“.']),
        if (phone)
          HelpBlock.p('Ändern Sie ihn mit einem Tipp auf das Node-Symbol im Tab Wallet oder unter $nodePlace: Die Nodes sind mit ihrem Zustand aufgelistet. Tippen Sie auf einen, um sofort zu ihm zu wechseln, oder geben Sie eine Adresse ein, um die Liste zu filtern oder einen Node hinzuzufügen. Zum Senden braucht es einen synchronisierten Node; **{n} zurück** oder **Antwortet nicht** heißt: einen anderen wählen.')
        else
          HelpBlock.p('Ändern Sie ihn unter $nodePlace: Die Nodes sind mit ihrem Zustand aufgelistet. Klicken Sie auf einen, um sofort zu ihm zu wechseln, oder geben Sie eine Adresse ein, um die Liste zu filtern oder einen Node hinzuzufügen. Zum Senden braucht es einen synchronisierten Node; fällt der Node zurück, bietet die Wallet einen anderen an.'),
      ],
      id: HelpId.node,
    ),
    if (!phone)
      HelpTopic(
        'network',
        'Den lokalen Node betreiben',
        'Ports, Peers, Chain-Daten und Besitzerzugang des Nodes, der auf diesem Computer läuft.',
        [
          HelpBlock.p('Der lokale Node ist ein eigenes Programm, das mit der App kommt. Er hat seine eigene Kopie der Chain, die Wallet fragt also niemand anderen. Er belegt etwa 5 GB auf der Festplatte und wächst langsam; der erste Download ist etwa 4 GB, danach kommt täglich ein wenig dazu. Solange er nicht synchronisiert ist, lässt sich über ihn nichts senden oder empfangen, und die Wallet kann in der Zwischenzeit einen öffentlichen Node nutzen.'),
          HelpBlock.ul([
            '**Mit der App starten** startet den Node beim Start und hält ihn synchron, solange die App offen ist. Er stoppt, wenn die App schließt.',
            '**Ports.** Der API-Port (3413) ist der, mit dem die Wallet spricht; der P2P-Port (3414) ist der, über den andere Nodes diesen erreichen. Ändern Sie sie nur, wenn ein anderer Node auf diesem Computer oder in diesem Netzwerk sie schon nutzt. Der Node startet mit den neuen Ports neu.',
            '**Peers.** Die Peers findet der Node von selbst. Bevorzugte Peers kommen zuerst. Max. eingehend und Max. ausgehend nehmen eine Zahl von 8 bis 500. Peers lassen sich im Tab Peers sperren und wieder freigeben.',
            '**Chain-Daten.** **Vorhandene nutzen** lässt den Node Chain-Daten lesen, die ein anderer Epic-Node auf diesem Computer hinterlassen hat, statt sie herunterzuladen; nichts wird kopiert, und Chain-Daten löschen ist für diesen Ordner aus. **Löschen** entfernt die Chain-Daten dieses Nodes; beim nächsten Start wird die ganze Chain neu geladen. Schlüssel und Verlauf bleiben.',
            '**Besitzerzugang.** Sync-Stufe und Peers kommen von der Besitzer-API des Nodes. Ihr Geheimnis steht in der ersten Zeile der Datei **.api_secret** im Datenordner des Nodes. Die Wallet bewahrt es im Schlüsselbund dieses Computers auf, nie in den Einstellungen oder in der Wallet-Datendatei. Bei einem Node auf einem anderen Computer reist es unverschlüsselt über http und ist in diesem Netzwerk lesbar: Nutzen Sie in einem gemeinsamen Netzwerk ein VPN oder https.',
          ]),
        ],
        id: HelpId.localNode,
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
        'Der Netzwerkmodus „Nur Tor“ leitet die Verbindungen der Wallet über Tor und gibt ihr eine .onion-Adresse. Langsamer. Standardmäßig aus.',
        [
          HelpBlock.p('Mit $torPlace läuft die Epicbox-Verbindung über Tor, eine Zahlung an eine .onion-Adresse läuft über Tor, und die Wallet hat eine eigene Tor-Adresse (sie endet auf .onion), an die andere Wallets direkt zahlen können.'),
          const HelpBlock.ul([
            'Node, Epicbox-Server und Adressen bleiben dieselben.',
            'Eine Link-Zahlung an eine Onion-Adresse läuft über Tor; Senden zeigt, ob eine Zahlung über Tor läuft.',
            'Langsamer als ohne Tor. In manchen Ländern ist Tor blockiert; dort verbindet es sich nicht.',
            'Empfangen an der .onion-Adresse funktioniert, solange die App geöffnet ist; Epicbox arbeitet daneben weiter.',
          ]),
          const HelpBlock.p('**Startet…** heißt, Tor verbindet sich; die abgedeckten Verbindungen warten und weichen nie aus. **Nicht verbunden** heißt, es ist fehlgeschlagen: Wiederholen oder Tor ausschalten. Manche Wallets zeigen eine Tor-Adresse ohne .onion; beides ist dieselbe Adresse.'),
        ],
        id: HelpId.tor,
      )
    else if (tor)
      const HelpTopic(
        'network',
        'Tor',
        'Der Netzwerkmodus „Nur Tor“ leitet die Verbindungen der Wallet über Tor, ohne Ports zu öffnen. Langsamer. Standardmäßig aus.',
        [
          HelpBlock.p('Mit Tor läuft die Verbindung zum Epicbox-Server über Tor, und die Wallet hat eine Tor-Adresse (sie endet auf .onion), an die andere Wallets direkt zahlen können, von überall, ohne Weiterleitung am Router. Tor ändert die Adressen nicht, die Sie weitergeben.'),
          HelpBlock.ul([
            'Schalten Sie es mit [[Einstellungen › Netzwerk & Datenschutz › Nur Tor|Settings › Network & privacy › Tor only]] ein. Die Tor-Zeile in der Seitenleiste zeigt den Zustand.',
            'Solange Tor startet oder nicht verbunden ist, wartet, was über Tor läuft; nichts geht daran vorbei. Wiederholen oder Tor ausschalten.',
            'Link · HTTP an eine http(s)-Adresse läuft nicht über Tor; Senden weist darauf hin.',
            'Link · HTTP-Empfang ist aus, solange Tor an ist: Zahlungen direkt von einer anderen Wallet kommen an der Link · Tor-Adresse an.',
            'In manchen Ländern ist Tor blockiert oder nicht erlaubt; dort verbindet es sich nicht.',
          ]),
          HelpBlock.p('Manche Wallets zeigen die Adresse ohne .onion; beides ist dieselbe Adresse.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      'Netzwerkmodi',
      tor
          ? 'Normal, Nur Tor, Nur Node oder Notaus: womit sich jeder verbindet und wie man von einer Wallet zahlt, die nie online geht.'
          : 'Normal, Nur Node oder Notaus: womit sich jeder verbindet und wie man von einer Wallet zahlt, die nie online geht.',
      [
        HelpBlock.p('Wie viel vom Internet die Wallet nutzt, ist eine einzige Wahl unter $netPlace, und die Wallet merkt sie sich. Außerhalb von **Normal** nennt eine Markierung ${phone ? 'auf dem Startbildschirm' : 'in der Titelleiste'} den Modus; tippen Sie darauf, um ihn zu ändern.'),
        HelpBlock.ul([
          tor
              ? '**Normal**: alles, wofür die Wallet eingerichtet ist: der Node, Epicbox, Link, die Statusseite, der Kurs und die Update-Prüfung.'
              : '**Normal**: alles, wofür die Wallet eingerichtet ist: der Node, Epicbox, Link, die Statusseite, der Kurs und die Update-Prüfung.',
          if (tor)
            '**Nur Tor**: Jede Verbindung läuft über Tor, auch die zum Node und zu Epicbox. Bis Tor bereit ist, verbindet sich nichts, und die Statussymbole sagen **Warten auf Tor**. Der Link-·-HTTP-Empfang bleibt aus.',
          '**Nur Node**: Die Wallet spricht nur mit dem verwendeten Node, dem ersten in Ihrer Node-Liste. Aus sind Epicbox, Link, die Statusseite, der Kurs, die Update-Prüfung, Explorer-Links, Problemberichte, Kopplung und verknüpfte Geräte. ${phone ? '**Direkt · QR-Zahlung** und **Direkt · Dateiübertragung**' : '**Direkt · Dateiübertragung**'} funktionieren.${tor ? ' Ist Tor an, wird der Node über Tor erreicht.' : ''}',
          '**Notaus**: Nichts verbindet sich, auch nicht der Node. Die Wallet öffnet sich mit dem zuletzt bekannten Guthaben und Verlauf. Sie können Zahlungen per ${phone ? '**Direkt · Dateiübertragung** und **Direkt · QR-Zahlung**' : '**Direkt · Dateiübertragung**'} erstellen, signieren und abschließen, Ihre Adresse zeigen, sichern und exportieren. Zahlungen, die auf einen Empfänger warten, pausieren und laufen weiter, wenn Sie den Modus verlassen.',
        ]),
        const HelpBlock.h('Warum ein eigener Node bei „Nur Node“', anchor: HelpAnchor.ownNode),
        HelpBlock.p('Der verwendete Node sieht jede Anfrage der Wallet. Ein Node auf $device oder in Ihrem Netzwerk behält das für Sie und antwortet schnell. Jeder Node funktioniert. Wählen Sie ihn unter $nodePlace.'),
        const HelpBlock.h('Zahlen mit „Notaus“', anchor: HelpAnchor.coldStorage),
        HelpBlock.ol([
          'Erstellen Sie die Zahlung wie gewohnt per ${phone ? '**Direkt · Dateiübertragung** oder **Direkt · QR-Zahlung**' : '**Direkt · Dateiübertragung**'} und schließen Sie sie ab, wenn die Antwort zurück ist.',
          'Die Wallet meldet **Abgeschlossen, nicht gesendet**: Sie ist vollständig, aber nur ein Gerät, das online ist, kann sie senden.',
          '**Datei speichern** und ${phone ? '**QR zeigen**' : 'den Text **kopieren**'}, dann zu einem Gerät bringen, das online ist.',
          'Dort ${phone ? 'im Menü von „Aktivität“ **Fertige Zahlung senden** wählen' : 'unter „Empfangen“ bei „Transaktionsdateien“ **Fertige Zahlung senden** wählen'}, die Datei laden${phone ? ' oder den Code scannen' : ' oder den Text einfügen'} und **Senden** drücken. Jede Epic-Cash-Wallet kann das; es ist kein Schlüssel nötig.',
          'Zurück hier steht bei der Zahlung **Wird anderswo gesendet**, danach **Bestätigung**, sobald die Wallet sie in der Chain sieht, nachdem Sie „Notaus“ verlassen haben.',
        ]),
        HelpBlock.p('Dienste, die ein Modus abschaltet, erscheinen grau als **Aus (Nur Node)**: Das ist der Modus, kein Fehler. Beim Wechsel wird nichts abgebrochen; eine Zahlung, die über Epicbox auf den Empfänger wartet, läuft weiter, wenn Sie den Modus verlassen${tor ? ' (oder zu „Nur Tor“ wechseln)' : ''}.'),
        HelpBlock.p('Der **automatische Node-Wechsel** ist standardmäßig an. Antwortet Ihr Node 30 Sekunden lang nicht, wechselt die Wallet zum nächsten funktionierenden Node Ihrer Liste, nur für diese Sitzung: Ihr eigener Node bleibt gespeichert, und die Wallet ist beim nächsten Start wieder darauf, oder sobald Sie selbst einen Node wählen. Bei „Nur Node“ und „Notaus“ wechselt sie nie${phone ? '' : ', und auch nie weg von einem Node auf diesem Computer'}${tor ? '; mit „Nur Tor“ wechselt sie nur zu einem Node, der über Tor erreichbar ist' : ''}.'),
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
            '**Zahlungsoptionen**: Strategie und Wechselgeld aufteilen, unter $payPlace: welche Outputs eine Zahlung ausgibt und ob ihr Wechselgeld aufgeteilt wird.'
          else
            '**Zahlungsoptionen**: ein Bereich auf Senden, in dem eine einzelne Zahlung Kleinste oder Alle wählt und ob das Wechselgeld aufgeteilt wird.',
          '**Server-Details**: Hosts, Latenz, Version und Blockhöhe in den Listen für Node und Epicbox und auf der Statuskarte.',
          if (phone)
            '**Ab einer Höhe neu prüfen**: lässt „Guthaben neu prüfen“ bei einer Blockhöhe oder einem Datum beginnen statt beim ersten Block. Beim Wiederherstellen steht die Wahl immer offen.'
          else
            '**Ab einer Höhe neu prüfen**: lässt „Guthaben neu prüfen“ auch unbestätigte Transaktionen verwerfen. Beim Wiederherstellen steht allen ein Startblock zur Wahl.',
          if (!phone) '**Lokaler Node**: lässt diesen Computer einen eigenen Node betreiben, unter $nodePlace.',
          if (!phone) '**Protokolle**: die Gruppe Protokolle unter $filesPlace, um den Protokollordner zu öffnen oder die Protokolle zu löschen. „Problem melden“ hängt das Protokoll in jedem Fall an.',
        ]),
        HelpBlock.p('**Bestätigungen** legt fest, wie viele Blöcke eine empfangene Zahlung wartet, bevor ihre Outputs verfügbar sind: standardmäßig 6, jeder Wert von 1 bis 30. Weniger Bestätigungen sind schneller, sind aber weniger sicher.${phone ? '' : ' Sie werden unter $payPlace eingestellt.'}'),
        const HelpBlock.p('**Experimentell** enthält **Rechnungen**, zu Beginn aus: Zahlungsanforderungen und Rechnungen zwischen gekoppelten Kontakten. Aus sind sie verborgen, und nichts wird für sie geprüft. Kopplung selbst ist immer an.'),
        HelpBlock.p(phone ? 'Netzwerkmodus und **automatischer Node-Wechsel** stehen unter $netPlace: siehe „Netzwerkmodi“.' : 'Der Netzwerkmodus steht unter $netPlace: siehe „Netzwerkmodi“. **Node automatisch wechseln** steht unter $nodePlace.'),
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
          HelpBlock.p('**„Epicbox antwortet nicht“.** Die Wallet erreicht ihren Epicbox-Server nicht. Warten Sie einen Moment; bleibt es so, prüfen Sie die Verbindung oder wählen Sie unter $payPlace einen anderen Server. In der Zwischenzeit funktioniert Direkt · Dateiübertragung.'),
        const HelpBlock.p('**Eine Zahlung zeigt „Wartet auf Empfänger“.** Die Wallet des Empfängers hat noch nicht geantwortet. Bitten Sie ihn, sie zu öffnen. Wird er das nie tun, stornieren Sie die Zahlung unter Aktivität, um die Coins freizugeben.'),
        if (phone)
          const HelpBlock.p('**Eine Zahlung ist nicht angekommen.** Prüfen Sie die Statussymbole im Tab Wallet: Node synchronisiert, Epicbox verbunden. Nach einem Wechsel des Epicbox-Servers braucht der Absender die neue Adresse. Außerdem muss die Wallet des Absenders die Transaktion abschließen; danach dauern die Bestätigungen einige Minuten.')
        else
          const HelpBlock.p('**Eine Zahlung ist nicht angekommen.** Prüfen Sie unter Empfangen, ob der Empfang eingeschaltet und der Node synchronisiert ist. Nach einem Wechsel des Epicbox-Servers braucht der Absender die neue Adresse. Außerdem muss die Wallet des Absenders die Transaktion abschließen; danach dauern die Bestätigungen einige Minuten.'),
        if (phone && tor)
          const HelpBlock.p('**Tor zeigt „Nicht verbunden“.** Tor konnte sein Netzwerk nicht erreichen. Drücken Sie unter [[Einstellungen › Netzwerk & Datenschutz|Settings › Network & privacy]] auf „Wiederholen“ oder schalten Sie Tor aus; in der Zwischenzeit geht nichts hinaus.'),
        if (!phone) ...[
          HelpBlock.p('**„Port ${appConfig.httpListenPort} wird von einem anderen Programm genutzt“.** Ein anderes Programm, oft eine andere Epic-Wallet, nutzt den Port für Link · HTTP-Zahlungen. Schließen Sie es und drücken Sie dann unter Empfangen auf „Erneut versuchen“. ${tor ? 'Epicbox, Link · Tor und Direkt · Dateiübertragung funktionieren' : 'Epicbox und Direkt · Dateiübertragung funktionieren'} in der Zwischenzeit weiter.'),
          const HelpBlock.p('**„Ein anderes Epic-Programm nutzt diesen Ordner“.** Eine andere Epic-Wallet oder ein Node hat dieselben Dateien geöffnet. Schließen Sie sie und versuchen Sie es erneut.'),
        ],
        if (phone)
          const HelpBlock.p('**PIN vergessen.** Löschen Sie die Wallet auf dem Entsperrbildschirm und stellen Sie sie mit ihrer Wiederherstellungsphrase und einer neuen PIN wieder her. Ohne die Phrase lassen sich die EPIC nicht zurückholen.')
        else
          const HelpBlock.p('**„Falsches Passwort“.** Prüfen Sie die Feststelltaste und das Tastaturlayout. Passwort vergessen: Stellen Sie die Wallet mit ihrer Wiederherstellungsphrase wieder her und wählen Sie ein neues.'),
        HelpBlock.p(tor
            ? '**Eine Aktion ist ausgegraut und nennt einen Modus oder „Wartet auf Tor“.** „Nur Tor“, „Nur Node“ oder „Notaus“ ist unter $netPlace an. Stellen Sie dort den Modus auf Normal zurück oder warten Sie, bis Tor verbunden ist.'
            : '**Eine Aktion ist ausgegraut und nennt einen Modus.** „Nur Node“ oder „Notaus“ ist unter $netPlace an. Stellen Sie dort den Modus auf Normal zurück.'),
        HelpBlock.p('**Das Guthaben sieht falsch aus.** Starten Sie $recheckPlace.'),
      ],
      id: HelpId.trouble,
    ),
    const HelpTopic(
      'trouble',
      'Zahlungen einer anderen Wallet',
      'Zahlungen, die diese Wallet nicht selbst gemacht oder empfangen hat: Dieselbe Wiederherstellungsphrase wird in einer anderen Wallet verwendet.',
      [
        HelpBlock.p('Eine Zeile **Von einem anderen Gerät gesendet** oder **Von einem anderen Gerät empfangen** ist eine Zahlung einer anderen Wallet, die dieselbe Wiederherstellungsphrase verwendet. Die Blockchain zeigt diese Coins als ausgegeben oder empfangen, deshalb führt diese Wallet sie auf.'),
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
        const HelpBlock.p('Stornieren stoppt eine Zahlung, die noch nicht durchgegangen ist. Ob es sicher ist, hängt von einer Sache ab: ob die andere Seite schon alles hat, um die Zahlung abzuschließen. Wenn nicht, ist Stornieren sicher: Die Zahlung kann ohne diese Wallet nicht durchgehen, und Stornieren ist kostenlos. Wenn doch, könnte die andere Seite die Zahlung noch abschließen, und die Wallet bietet zwei Wege zu stornieren.'),
        const HelpBlock.h('Coins zurückholen oder freigeben', anchor: HelpAnchor.twoWays),
        const HelpBlock.p('**Coins zurückholen** schickt die Coins zuerst an diese Wallet zurück, gegen die normale Netzwerkgebühr; danach kann die alte Zahlung nie mehr durchgehen. **Coins freigeben** ist kostenlos und verschiebt nichts: Die Coins sind wieder ausgebbar, und die Zahlung bleibt, wie sie ist. Schließt die andere Seite sie doch noch ab, erscheint sie als bezahlt; wenn nicht, passiert nichts.'),
        const HelpBlock.h('Senden', anchor: HelpAnchor.sending),
        const HelpBlock.p('Eine von dieser Wallet gesendete Zahlung wartet zuerst auf die Antwort der anderen Seite. Solange sie wartet, ist Stornieren sicher: Ohne diese Wallet kann nichts durchgehen, und die Coins sind sofort wieder frei. Keine Gebühr. Die andere Wallet zeigt die Zahlung vielleicht noch als wartend, kann sie aber nicht abschließen.'),
        HelpBlock.p('Sobald die Antwort da ist, schließt diese Wallet die Zahlung ab und stellt sie in einem Schritt ins Netzwerk. Eine Zahlung, die das Netzwerk erreicht hat, lässt sich nicht stornieren, rückgängig machen oder erstatten; nur der Empfänger kann sie zurückzahlen. Nimmt das Netzwerk sie nicht an, ist die Zahlung trotzdem vollständig und könnte später noch durchgehen. ${phone ? 'Nach etwa einem Tag bietet die Wallet „Betrag freigeben“ an, mit denselben zwei Wegen: Coins zurückholen schickt die Coins gegen die normale Netzwerkgebühr an diese Wallet zurück; Coins freigeben ist kostenlos.' : 'Die Wallet bietet an, sie erneut ins Netzwerk zu stellen oder zu stornieren. Dieses Stornieren prüft zuerst das Netzwerk und lehnt ab, wenn das Netzwerk die Zahlung schon hat. Sonst bietet es dieselben zwei Wege: Coins zurückholen schickt die Coins gegen die normale Netzwerkgebühr an diese Wallet zurück; Coins freigeben ist kostenlos.'}'),
        const HelpBlock.p('Eine Zahlung, die niemand beantwortet, storniert sich nach etwa einem Tag (1.440 Blöcken) von selbst, und die Coins sind wieder frei. Das gilt für Epicbox-, Link- und Direkt-Zahlungen gleichermaßen: Stornieren ist sicher, bis die Antwort der anderen Seite in dieser Wallet ist.'),
        HelpBlock.p('**Eine Zahlung scheint festzuhängen.** Meist ist die andere Wallet offline. Warten, oder die Zahlung unter $cancelPlace stornieren und neu senden. Eine stornierte Zahlung kann später nicht mehr durchgehen.'),
        const HelpBlock.h('Empfangen', anchor: HelpAnchor.receiving),
        const HelpBlock.p('Kommt eine Zahlung an, antwortet diese Wallet sofort, und keine ihrer Coins werden gesperrt. Von da an schließt die Wallet des Absenders die Zahlung ab und stellt sie ins Netzwerk, meist innerhalb von Minuten. Stornieren ist 15 Minuten lang nicht verfügbar, und länger, solange der Absender meldet, dass er sie ins Netzwerk gestellt hat.'),
        const HelpBlock.p('Danach räumt Stornieren eine Zahlung ab, die der Absender nie ins Netzwerk gestellt hat. Es ist nicht sicher: Die Wallet prüft zuerst das Netzwerk und lehnt ab, wenn die Zahlung schon dort ist. Eine stornierte Zahlung bleibt im Blick. Stellt der Absender sie später doch ins Netzwerk, kommt sie trotzdem an und erscheint als empfangen.'),
        const HelpBlock.h('Rechnungen (experimentell)', anchor: HelpAnchor.requests),
        const HelpBlock.p('Eine von dieser Wallet gesendete Rechnung hält keine Coins, bis sie bezahlt ist. Bis dahin lässt sie sich jederzeit zurückziehen: Der Zahler kann sie dann nicht mehr bezahlen, und keine Coins bewegen sich. Eine Rechnung, die niemand bezahlt, läuft nach 24 Stunden ab. Eine als QR-Code gezeigte Rechnung kann einmal bezahlt werden; ein zweiter Scan wird abgelehnt, es wird also nichts doppelt bezahlt.'),
        const HelpBlock.p('Eine von dieser Wallet bezahlte Rechnung ist umgekehrt: Die andere Seite hat schon alles, um die Zahlung abzuschließen. Stornieren erscheint, wenn die Zeit der Rechnung abläuft, etwa einen Tag nach dem Bezahlen, oder früher, wenn die andere Seite sie zurückzieht. Es bietet dieselben zwei Wege: Coins zurückholen schickt die Coins gegen die normale Netzwerkgebühr an diese Wallet zurück, damit die alte Zahlung nicht mehr durchgehen kann; Coins freigeben ist kostenlos und überlässt sie der anderen Seite. Lassen sich die Coins nicht sofort zurückschicken, versucht es die Wallet erneut, solange sie geöffnet ist. Bis dahin könnte die andere Seite die Zahlung noch abschließen, und dann erscheint sie als bezahlt.'),
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
            '**Aus der Liste entfernen** unter [[Einstellungen › Wallets|Settings › Wallets]] nimmt eine Wallet aus der Liste. Ihr Ordner bleibt auf der Festplatte, und die Seite bietet sie unter **Aus der Liste entfernt** wieder an.',
            '**Wer einen Wallet-Ordner ohne seine Wiederherstellungsphrase löscht, verliert die EPIC darin.** Nur eine Wallet löschen, deren Phrase notiert ist, oder eine, die leer ist und nicht mehr gebraucht wird.',
            'Die Ordner liegen unter **wallets** im Datenordner (**Ordner öffnen** neben [[Einstellungen › Dateien & Protokolle › App-Dateien|Settings › Files & logs › App files]]), einer je Wallet, benannt nach ihrer Kennung; **WALLET.txt** darin nennt den Namen der Wallet. Wenn BT Wallet geschlossen ist, nur diesen einen Kennungsordner löschen und alles andere lassen, wie es ist.',
          ]),
        ],
        id: HelpId.cleanup,
      ),
    HelpTopic(
      'maintenance',
      'Die Einstellungsdatei',
      'Eine Datei enthält Ihre Node- und Epicbox-Listen. Ein Fehler darin kostet nie die letzten guten Einstellungen.',
      [
        if (phone) ...[
          HelpBlock.p(
            'Die App führt eine Datei mit Ihren Node- und Epicbox-Listen und drei Schaltern: Statusseite, Update-Prüfung und Preise. Alles andere kommt mit der App. Die Datei wird in der App geändert, zum Beispiel unter $nodePlace und $epicboxPlace, nicht von Hand.',
          ),
          HelpBlock.ul([
            '**Der erste Server jeder Liste ist der verwendete.** Wählen Sie einen Server, rückt er nach oben; eine neue Reihenfolge ändert den verwendeten. Antwortet der erste Node nicht, wird der nächste versucht.',
            '**Der erste Epicbox-Server steht in der Epicbox-Adresse jeder Wallet.** Rückt ein anderer nach oben, bekommt jede Wallet eine neue Adresse; Zahlungen an eine alte Adresse kommen nicht an.',
            '**Eine Datei, die sich nicht lesen lässt:** Die letzten guten Einstellungen bleiben in Gebrauch. Bevor die App eine neue Datei schreibt, speichert sie die alte als **settings.toml.bad-<time>**.',
            'Eine gelöschte Datei wird neu geschrieben.',
          ]),
        ] else ...[
          HelpBlock.p(
            'Die Datei **settings.toml** enthält Ihre Node- und Epicbox-Listen und drei Schalter: Statusseite, Update-Prüfung und Preise. Alles andere kommt mit der App. Sie liegt im Datenordner: **~/.epic_cash_desktop/settings.toml** unter Linux und macOS, **%USERPROFILE%\\.epic_cash_desktop\\settings.toml** unter Windows (**Ordner öffnen** neben [[Einstellungen › Dateien & Protokolle › App-Dateien|Settings › Files & logs › App files]]).',
          ),
          HelpBlock.ul([
            'Eine Änderung in der App wird sofort in die Datei geschrieben. Eine Änderung, die Sie in der Datei speichern, gilt bei laufender App nach einem Moment.',
            '**Der erste Server jeder Liste ist der verwendete.** Wählen Sie einen Server, rückt er nach oben; eine neue Reihenfolge ändert den verwendeten. Antwortet der erste Node nicht, wird der nächste versucht.',
            '**Der erste Epicbox-Server steht in der Epicbox-Adresse jeder Wallet.** Rückt ein anderer nach oben, bekommt jede Wallet eine neue Adresse; Zahlungen an eine alte Adresse kommen nicht an.',
            '**Ein Fehler in der Datei:** Die letzten guten Einstellungen bleiben in Gebrauch, ein Hinweis nennt die Zeile, und eine fehlerhafte Datei wird nie überschrieben.',
            'Muss die App schreiben, während die Datei Fehler hat, speichert sie die Datei zuerst als **settings.toml.bad-<time>** und schreibt dann eine gute.',
            'Eine gelöschte Datei wird neu geschrieben.',
          ]),
        ],
      ],
      id: HelpId.settingsFile,
    ),
    ...deviceHelpTopics('de', phone: phone),
    ...directoryHelpTopics('de', phone: phone),
  ];
}
