/// German help: the topics and sections of help_content.dart in German, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';

const List<HelpSection> helpSectionsDe = [
  (id: 'start', title: 'Erste Schritte', lede: 'Empfangen, senden und der Weg per Datei.', art: 'help-start'),
  (id: 'how', title: 'So funktioniert Epic Cash', lede: 'Beide Wallets wirken mit; Bestätigungen, Privatsphäre, Wechselgeld und Gebühren.', art: 'help-how'),
  (id: 'safety', title: 'Die Wallet schützen', lede: 'Die Wiederherstellungsphrase ist Sicherung und Schlüssel zugleich.', art: 'help-safety'),
  (id: 'network', title: 'Nodes und Epicbox', lede: 'Womit sich die Wallet verbindet, und Tor.', art: 'help-network'),
  (id: 'trouble', title: 'Wenn etwas nicht klappt', lede: 'Die üblichen Ursachen und was zu tun ist.', art: 'help-trouble'),
];

List<HelpTopic> helpTopicsDe(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'diesem Smartphone' : 'diesem Computer';
  final secret = phone ? 'Ihre PIN' : 'das Wallet-Passwort';
  final nodePlace = phone ? '[[Einstellungen › Datenschutz & Netzwerk › Node und Epicbox|Settings › Privacy & network › Node and Epicbox]]' : '[[Einstellungen › Node|Settings › Node]]';
  final epicboxPlace = phone ? '[[Einstellungen › Datenschutz & Netzwerk › Node und Epicbox|Settings › Privacy & network › Node and Epicbox]]' : '[[Einstellungen › Empfangen › Epicbox-Empfang|Settings › Receiving › Epicbox receiving]]';
  final torPlace = phone ? '[[Einstellungen › Datenschutz & Netzwerk › Tor-Netzwerk|Settings › Privacy & network › Tor Network]]' : '[[Einstellungen › Datenschutz › Tor|Settings › Privacy › Tor]]';
  final cancelPlace = phone
      ? '[[Aktivität|Activity]] (die Zahlung öffnen, dann „Zahlung stornieren“)'
      : '[[Aktivität › die Transaktion › Zahlung stornieren|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[Einstellungen › Wallet › Verlaufssicherung exportieren|Settings › Wallet › Export history backup]]'
      : '[[Einstellungen › Diese Wallet › Verlaufssicherung exportieren|Settings › This wallet › Export history backup]]';
  final restorePlace = phone
      ? '**Ich habe bereits eine Wallet: wiederherstellen** (auf dem ersten Bildschirm oder nach dem Löschen dieser Wallet unter [[Einstellungen › Wallet|Settings › Wallet]])'
      : '**Mit Phrase wiederherstellen** (auf dem ersten Bildschirm, unter Entsperren › Wallet hinzufügen oder unter [[Einstellungen › Alle Wallets|Settings › All wallets]])';
  final recheckPlace = phone ? '[[Einstellungen › Wallet › Guthaben neu prüfen|Settings › Wallet › Recheck balance]] (erscheint, wenn „Erweiterte Optionen“ an ist)' : '[[Einstellungen › Guthaben neu prüfen|Settings › Recheck balance]]';
  final phrasePlace = phone ? '[[Einstellungen › Sicherheit › Wiederherstellungsphrase sichern|Settings › Security › Back up recovery phrase]]' : '[[Einstellungen › Wiederherstellungsphrase|Settings › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Die ersten EPIC empfangen',
      'Öffnen Sie Empfangen, kopieren Sie die Epicbox-Adresse und geben Sie sie dem Absender. Die Zahlung kommt von selbst an.',
      [
        const HelpBlock.p('Die Epicbox-Adresse ist ein langer Code, der auf **@** und den Namen des Epicbox-Servers endet, zum Beispiel **…@epicbox.epiccash.com**. Sie kann gefahrlos weitergegeben werden: Andere brauchen sie zum Bezahlen, und niemand kann damit etwas wegnehmen.'),
        const HelpBlock.ol(['Öffnen Sie [[Empfangen|Receive]].', 'Kopieren Sie die Adresse (oder zeigen Sie ihren QR-Code) und senden Sie sie der Person, die bezahlt.', 'Die Zahlung erscheint von selbst unter Aktivität. Sie müssen nichts tun.']),
        if (phone)
          const HelpBlock.p('Empfangen funktioniert, solange die App geöffnet und der Node synchronisiert ist. Eine Zahlung, die bei geschlossener App gesendet wird, wartet etwa eine Woche auf dem Epicbox-Server und kommt beim nächsten Entsperren an.')
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
        HelpBlock.p('**Keine Antwort?** Nach einigen Minuten zeigt der Status „Wartet auf den Empfänger“. Bitten Sie den Empfänger, seine Wallet zu öffnen. Kommt die Antwort nie, stornieren Sie die Zahlung unter $cancelPlace, um die Outputs freizugeben. Eine Zahlung wird nie von selbst storniert.'),
        if (phone)
          const HelpBlock.p('Zum Senden braucht es einen synchronisierten Node. Eine Epicbox-Adresse braucht außerdem einen antwortenden Epicbox-Server; eine direkte Adresse (http oder .onion) braucht die Wallet des Empfängers, geöffnet und in diesem Moment erreichbar.')
        else
          const HelpBlock.p('Zum Senden braucht es einen synchronisierten Node. Eine Epicbox-Adresse braucht außerdem eingeschalteten Empfang über Epicbox; eine Direkt-Adresse (http oder .onion) braucht die Wallet des Empfängers, geöffnet und in diesem Moment erreichbar.'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      'Per Datei senden',
      'Der manuelle Weg: Transaktionsdatei speichern, dem Empfänger geben, dann die Antwortdatei öffnen, die er zurückschickt.',
      [
        const HelpBlock.p('Dateien durchlaufen denselben Handschlag wie Epicbox, nur werden die Nachrichten von Hand übergeben, zum Beispiel per E-Mail, Chat oder USB-Stick. Das funktioniert ohne Epicbox und ohne dass beide Wallets gleichzeitig online sind.'),
        if (phone)
          const HelpBlock.ol(['**Absender:** wählt unter Senden **Datei**, gibt den Betrag ein und teilt die Datei (sie endet auf .tx). Ab jetzt sind die Outputs gesperrt.', '**Empfänger:** öffnet die Datei unter [[Empfangen › Datei|Receive › File]]. Seine Wallet signiert sie und teilt eine Antwortdatei (ihr Name beginnt mit finalize_). Diese Datei schickt er zurück.', '**Absender:** öffnet die Antwortdatei unter [[Empfangen › Datei|Receive › File]]. Die Wallet schließt die Transaktion ab und sendet sie.'])
        else
          const HelpBlock.ol(['**Absender:** wählt unter Senden **Datei**, gibt den Betrag ein und speichert die Datei (sie endet auf .tx). Ab jetzt sind die Outputs gesperrt.', '**Empfänger:** öffnet die Datei unter [[Empfangen › Transaktionsdateien › Transaktionsdatei signieren|Receive › Transaction files › Sign a transaction file]]. Seine Wallet signiert sie und speichert eine Antwortdatei (ihr Name beginnt mit finalize_). Diese Datei schickt er zurück.', '**Absender:** öffnet die Antwortdatei unter [[Empfangen › Transaktionsdateien › Antwortdatei abschließen|Receive › Transaction files › Finalize a response file]]. Die Wallet schließt die Transaktion ab und sendet sie.']),
        const HelpBlock.p('Andere Epic-Cash-Wallets nennen diese Schritte anders. Kommt die Antwortdatei nie, stornieren Sie die Zahlung unter Aktivität, um die Outputs freizugeben.'),
      ],
      id: HelpId.file,
    ),
    if (phone)
      const HelpTopic(
        'start',
        'So sieht eine Adresse aus',
        'Eine Epicbox-Adresse beginnt mit es und endet auf @ und einen Servernamen. Eine direkte Adresse ist eine Webadresse oder endet auf .onion.',
        [
          HelpBlock.ul([
            '**Epicbox**: etwa 52 Zeichen, beginnend mit **es**, dann **@** und der Server, zum Beispiel **esXXXX…XXXX@epicbox.epiccash.com**. Die Standardmethode; der Empfänger darf offline sein.',
            '**Direkt**: die eigene Wallet des Empfängers, gerade geöffnet. Entweder eine Webadresse wie **http://host:3415** oder eine Tor-Adresse aus 56 Zeichen, die auf **.onion** endet und über Tor läuft.',
          ]),
          HelpBlock.p('Senden wählt die Methode anhand der Adresse, die im Feld „An“ eingefügt wird. Wer eine Adresse vorliest, vergleicht die ersten sechs und die letzten sechs Zeichen.'),
        ],
        id: HelpId.addresses,
      ),
    const HelpTopic(
      'how',
      'Warum braucht eine Transaktion beide Seiten?',
      'Bei Epic Cash hilft die Wallet des Empfängers, jede Transaktion zu bauen, daher müssen beide Wallets mitwirken.',
      [
        HelpBlock.p('Epic Cash nutzt Mimblewimble. Statt eine Adresse und einen Betrag in die Blockchain zu schreiben, bauen die beiden Wallets jede Transaktion gemeinsam, wie bei einem Handschlag:'),
        HelpBlock.ol(['Die Wallet des Absenders beginnt und sperrt die Outputs, die gesendet werden.', 'Die Wallet des Empfängers fügt ihren Teil hinzu und signiert.', 'Die Wallet des Absenders signiert ebenfalls, schließt die Transaktion ab und sendet sie ins Netzwerk.']),
        HelpBlock.p('Etwas muss also die Nachrichten zwischen den beiden Wallets übermitteln. Das übernimmt **Epicbox**: Es hält die Nachricht bereit, solange die andere Wallet offline ist, sodass nicht beide gleichzeitig online sein müssen. **Direkt · HTTP** und **Direkt · Tor** gehen direkt zur anderen Wallet, solange sie geöffnet ist. Eine **Transaktionsdatei** ist der manuelle Weg.'),
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
        HelpBlock.p('Diese Wallet betrachtet eine Transaktion ab der **$confirmations. Bestätigung** als endgültig. Bis dahin wird sie als **Wird bestätigt** angezeigt, und empfangene Outputs sind noch nicht verfügbar. Die Zahl ist fest.'),
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
        const HelpBlock.p('Was nicht verborgen ist: Der Node und der Epicbox-Server sehen die IP-Adresse der Wallet, und ein öffentlicher Node kann sehen, nach welchen Outputs die Wallet fragt. Tor oder ein VPN verbirgt die IP-Adresse.'),
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
          const HelpBlock.p('Die Standardeinstellung legen Sie unter [[Outputs › Erweitert|Outputs › Advanced]] fest.')
        else
          const HelpBlock.p('Die Standardeinstellung legen Sie unter [[Outputs › Erweitert|Outputs › Advanced]] fest; Senden kann sie für eine einzelne Zahlung unter **Erweitert** ändern.'),
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
        const HelpBlock.p('Aktivität zeigt beides als zwei Einträge, eine gesendete und eine empfangene Zahlung, beide mit dieser Wallet. Beides finden Sie unter [[Outputs › Erweitert|Outputs › Advanced]].'),
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
        HelpBlock.p('**Was eine Wiederherstellung nicht zurückholt:** was nie auf der Blockchain stand, etwa wer was bezahlt hat, Transaktionsnachrichten, Kontakte und Wallet-Namen. Eine Verlaufssicherung bewahrt die Zahlungsdetails und Kontakte: $historyBackupPlace.${phone ? ' Bewahren Sie die Sicherungsdatei außerhalb des Smartphones auf, zum Beispiel in einer E-Mail oder einem Cloud-Speicher.' : ''}'),
        HelpBlock.p('**Guthaben sieht falsch aus?** Starten Sie $recheckPlace. Dabei wird die ganze Blockchain erneut nach den Outputs dieser Wallet durchsucht.'),
        if (!phone)
          const HelpBlock.p('**Die Dateien der Wallet** liegen unter [[Einstellungen › Diese Wallet › Wallet-Ordner|Settings › This wallet › Wallet folder]]. Bewahren Sie die Wiederherstellungsphrase auch mit einer Kopie davon auf: Sie hilft, wenn die Dateien verloren gehen.'),
      ],
      id: HelpId.backup,
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
          const HelpBlock.p('Ein **öffentlicher Node** ist einer der Nodes, die andere betreiben. Er funktioniert sofort. Wer ihn betreibt, kann die IP-Adresse der Wallet sehen und nach welchen Outputs sie fragt; Tor verbirgt die Adresse.')
        else
          const HelpBlock.ul(['**Öffentlicher Node** (Standard): einer der öffentlichen Nodes, die andere betreiben. Er funktioniert sofort. Wer ihn betreibt, kann die IP-Adresse der Wallet sehen und nach welchen Outputs sie fragt.', '**Lokaler Node**: läuft auf diesem Computer. Er lädt zuerst die ganze Blockchain herunter, was eine Weile dauert und Speicherplatz braucht, und gehört dann Ihnen. Während er synchronisiert, nutzt die Wallet einen öffentlichen Node.']),
        if (phone)
          HelpBlock.p('Ändern Sie ihn mit einem Tipp auf die Node-Zeile im Tab Wallet oder unter $nodePlace: Die öffentlichen Nodes sind mit ihrem Zustand aufgelistet, oder Sie geben die Adresse eines Nodes ein. Zum Senden braucht es einen synchronisierten Node; **zurück** oder **Antwortet nicht** heißt: einen anderen wählen.')
        else
          HelpBlock.p('Ändern Sie ihn unter $nodePlace: Wählen Sie einen der öffentlichen Nodes, die mit ihrem Zustand aufgelistet sind, oder geben Sie die Adresse eines Nodes ein. Zum Senden braucht es einen synchronisierten Node; fällt der Node zurück, bietet die Wallet einen anderen an.'),
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
          HelpBlock.p('Den Server legen Sie mit einem Tipp auf die Epicbox-Zeile im Tab Wallet fest oder unter $epicboxPlace: Wählen Sie einen der öffentlichen Server, die mit ihrem Zustand aufgelistet sind, oder geben Sie einen ein. Ein anderer Server ändert den Teil nach @, geben Sie die neue Adresse also den Personen, die bezahlen. Andere Epic-Cash-Wallets nutzen ebenfalls Epicbox; zwei Wallets können verschiedene Server nutzen.')
        else
          HelpBlock.p('Den Server legen Sie unter $epicboxPlace fest: Wählen Sie einen der öffentlichen Server, die mit ihrem Zustand aufgelistet sind, oder geben Sie einen ein. Ein anderer Server ändert den Teil nach @, geben Sie die neue Adresse also den Personen, die bezahlen. Andere Epic-Cash-Wallets nutzen ebenfalls Epicbox; zwei Wallets können verschiedene Server nutzen.'),
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
            'Push-Benachrichtigungen sind aus, solange Tor an ist.',
            'Langsamer als Epicbox ohne Tor. In manchen Ländern ist Tor blockiert; dort verbindet es sich nicht.',
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
        'Langsamer und privater: Ein Schalter leitet die Verbindungen der Wallet über Tor, ohne Ports zu öffnen. Standardmäßig aus.',
        [
          HelpBlock.p('Mit Tor läuft die Verbindung zum Epicbox-Server über Tor, und die Wallet hat eine Tor-Adresse (sie endet auf .onion), an die andere Wallets direkt zahlen können, von überall, ohne Weiterleitung am Router. Die Adressen, die Sie weitergeben, bleiben dieselben.'),
          HelpBlock.ul([
            'Schalten Sie es unter [[Einstellungen › Datenschutz › Tor|Settings › Privacy › Tor]] ein. Die Tor-Zeile in der Seitenleiste zeigt den Zustand.',
            'Solange Tor startet oder nicht verbunden ist, wartet, was über Tor läuft; nichts geht daran vorbei. Wiederholen oder Tor ausschalten.',
            'Direkte Zahlungen an eine http(s)-Adresse laufen nicht über Tor; Senden weist darauf hin.',
            'Direkt · HTTP-Empfang ist aus, solange Tor an ist: Zahlungen direkt von einer anderen Wallet kommen an der Direkt · Tor-Adresse an.',
            'In manchen Ländern ist Tor blockiert oder nicht erlaubt; dort verbindet es sich nicht.',
          ]),
          HelpBlock.p('Manche Wallets zeigen die Adresse ohne .onion; beides ist dieselbe Adresse.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'trouble',
      'Fehlerbehebung',
      'Meist ist ein Node noch nicht synchronisiert, ein Empfänger hat noch nicht geantwortet, oder ein Port ist belegt.',
      [
        if (phone)
          const HelpBlock.p('**„Node nicht synchronisiert“: Senden nicht möglich.** Senden ist möglich, sobald der Node aufgeholt hat. Warten Sie kurz oder tippen Sie im Tab Wallet auf die Node-Zeile und wählen Sie einen anderen Node.')
        else
          const HelpBlock.p('**„Node nicht synchronisiert“: Senden nicht möglich.** Senden ist möglich, sobald der Node aufgeholt hat. Warten Sie kurz oder wählen Sie unter [[Einstellungen › Node|Settings › Node]] einen anderen Node.'),
        if (phone)
          const HelpBlock.p('**„Epicbox antwortet nicht“.** Die Wallet erreicht ihren Epicbox-Server nicht. Warten Sie einen Moment; bleibt es so, prüfen Sie die Verbindung oder tippen Sie im Tab Wallet auf die Epicbox-Zeile und wählen Sie einen anderen Server. In der Zwischenzeit funktioniert eine Datei.')
        else
          const HelpBlock.p('**„Epicbox antwortet nicht“.** Die Wallet erreicht ihren Epicbox-Server nicht. Warten Sie einen Moment; bleibt es so, prüfen Sie die Verbindung oder wählen Sie unter [[Einstellungen › Empfangen|Settings › Receiving]] einen anderen Server. In der Zwischenzeit funktioniert eine Datei.'),
        const HelpBlock.p('**Eine Zahlung zeigt „Wartet auf den Empfänger“.** Die Wallet des Empfängers hat noch nicht geantwortet. Bitten Sie ihn, sie zu öffnen. Wird er das nie tun, stornieren Sie die Zahlung unter Aktivität, um die Outputs freizugeben.'),
        if (phone)
          const HelpBlock.p('**Eine Zahlung ist nicht angekommen.** Prüfen Sie im Tab Wallet, ob der Node synchronisiert und Epicbox online ist. Nach einem Wechsel des Epicbox-Servers braucht der Absender die neue Adresse. Außerdem muss die Wallet des Absenders die Transaktion abschließen; danach dauern die Bestätigungen einige Minuten.')
        else
          const HelpBlock.p('**Eine Zahlung ist nicht angekommen.** Prüfen Sie unter Empfangen, ob der Empfang eingeschaltet und der Node synchronisiert ist. Nach einem Wechsel des Epicbox-Servers braucht der Absender die neue Adresse. Außerdem muss die Wallet des Absenders die Transaktion abschließen; danach dauern die Bestätigungen einige Minuten.'),
        if (phone)
          const HelpBlock.p('**Tor zeigt „Nicht verbunden“.** Tor konnte sein Netzwerk nicht erreichen. Drücken Sie unter [[Einstellungen › Datenschutz & Netzwerk|Settings › Privacy & network]] auf „Wiederholen“ oder schalten Sie Tor aus; in der Zwischenzeit geht nichts hinaus.'),
        if (!phone) ...const [
          HelpBlock.p('**„Port 3415 wird von einem anderen Programm genutzt“.** Ein anderes Programm, oft eine andere Epic-Wallet, nutzt den Port für Direkt · HTTP-Zahlungen. Schließen Sie es und drücken Sie dann unter Empfangen auf „Erneut versuchen“. Epicbox, Direkt · Tor und Dateien funktionieren in der Zwischenzeit weiter.'),
          HelpBlock.p('**„Ein anderes Epic-Programm nutzt diesen Ordner“.** Eine andere Epic-Wallet oder ein Node hat dieselben Dateien geöffnet. Schließen Sie sie und versuchen Sie es erneut.'),
        ],
        if (phone)
          const HelpBlock.p('**PIN vergessen.** Löschen Sie die Wallet auf dem Entsperrbildschirm und stellen Sie sie mit ihrer Wiederherstellungsphrase und einer neuen PIN wieder her. Ohne die Phrase lassen sich die EPIC nicht zurückholen.')
        else
          const HelpBlock.p('**„Falsches Passwort“.** Prüfen Sie die Feststelltaste und das Tastaturlayout. Passwort vergessen: Stellen Sie die Wallet mit ihrer Wiederherstellungsphrase wieder her und wählen Sie ein neues.'),
        HelpBlock.p('**Das Guthaben sieht falsch aus.** Starten Sie $recheckPlace.'),
      ],
      id: HelpId.trouble,
    ),
  ];
}
