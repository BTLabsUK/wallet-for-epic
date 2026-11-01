// SPDX-License-Identifier: Apache-2.0
/// Help on linked devices, for the phone and the desktop, in the app's six languages: how linked
/// devices work (with the sync picture and the live status panel, `HelpTopic.devices`), a lost
/// device, coins held by another device. Each language's topic list
/// (help_content.dart, help_`<lang>`.dart) ends with these; they show while Linked devices is on
/// ([helpTopicFeature]).
library;

import 'help_content.dart';

/// The linked devices topics in [lang] (`en`, `de`, `pl`, `ru`, `zh`, `th`).
List<HelpTopic> deviceHelpTopics(String lang, {required bool phone}) => switch (lang) {
  'de' => _de(),
  'pl' => _pl(),
  'ru' => _ru(),
  'zh' => _zh(),
  'th' => _th(),
  _ => _en(),
};

List<HelpTopic> _en() {
  final place = '[[Settings › This wallet › Linked devices]]';
  return [
    HelpTopic(
      'how',
      'How linked devices work',
      'Both devices get the balance from the chain. Linked, they also tell each other what they are paying, encrypted, over the servers, so they do not spend the same coins.',
      [
        const HelpBlock.p('**Both devices must already have this same wallet**, restored from the same recovery phrase: linking does not create it on the other device. Two different wallets cannot be linked.'),
        const HelpBlock.p('The recovery phrase opens the same wallet on any device. The chain gives each device the balance and every confirmed payment, so the money always adds up.'),
        const HelpBlock.p('What the chain does not show is what only the device that made a payment knows: who was paid, the message, and a payment still under way. Without a link, the other device shows such a payment as **Sent from another device**, with the amount only, once it is confirmed.'),
        const HelpBlock.p('Linking adds that. Each device tells the other when it starts a payment and how it ends. The coins it spends are held on the other until the chain shows them spent, so the two devices do not pick the same coins, and the payment shows as **Sent from** and the device’s name, with its details. Coins this wallet received on the linked device (a payment it received, or the change of its own send) show as **Received on** and the device’s name.'),
        const HelpBlock.p('Both devices answer payments to the wallet’s address. The sender takes the first answer; the payment shows once, as received on the device the sender used.'),
        HelpBlock.ol([
          'Open $place on both devices and choose **Link a device**.',
          'On one device open Link a device and scan the QR shown on the other.',
          'Both show the same four pictures while they link. Nothing to tap: the app checks the other device itself.',
        ]),
        const HelpBlock.h('Security', anchor: HelpAnchor.security),
        const HelpBlock.ul([
          '**Own keys for each link.** They are made when the devices link and cannot be worked out from the recovery phrase alone.',
          '**Encrypted end to end.** Only the linked devices can read a notice. The servers carry it and cannot read it.',
          '**Removing the link cuts it off.** Removing it on either device ends it on both: no more notices pass.',
          '**The link does not protect the money.** A device that holds the recovery phrase can still spend. Linking protects the channel and what is shared.',
        ]),
        const HelpBlock.h('Limits', anchor: HelpAnchor.limits),
        const HelpBlock.ul([
          '**Only while the app is open.** Nothing syncs in the background. The app catches up when it starts, resumes, unlocks or refreshes.',
          '**The chain decides.** A notice is a heads-up. The blockchain is the source of truth, and a payment counts once the chain shows it.',
          '**A server down delays notices.** With two servers, every notice goes to both, and the second carries it.',
          '**A third app on the same recovery phrase is not supported.** It hears nothing of the link; its payments show once the chain confirms them.',
        ]),
        const HelpBlock.p('Notices go through the first one or two servers of the Epicbox list, shown under the device. One other device can be linked: remove it to link a different one. **Pause sync** stops the notices for a while.'),
      ],
      devices: true,
      id: HelpId.linkedDevices,
    ),
    HelpTopic(
      'safety',
      'Linked devices and a lost device',
      'Remove stops sync with the device. It does not protect the money: move the coins to a new recovery phrase.',
      [
        HelpBlock.p('If the linked device is lost, sold or given away, open $place, choose it and choose **Remove**. The link ends on both devices: it stops getting this wallet’s notices, and coins it held are released. The device that did not remove it shows who did.'),
        const HelpBlock.p('**Removing a device does not protect the money.** The device still holds the recovery phrase, and a device with the phrase can always spend. If it may be in someone else’s hands, make a new wallet with a new recovery phrase and send all the coins to it.'),
        const HelpBlock.p('A device restored from the phrase is not linked: link it again.'),
      ],
      id: HelpId.lostDevice,
    ),
    HelpTopic(
      'trouble',
      'Coins held by another device',
      'A linked device is spending these coins. They come back on their own when its payment ends; Release frees them by hand.',
      [
        const HelpBlock.p('When a linked device starts a payment, the coins it spends are held on this device: they are left out of sends, Send all and the fee estimates, Outputs shows them as **Held by** that device’s payment, and Send says how much is held.'),
        const HelpBlock.ul([
          'They become the payment **Sent from** that device once the chain shows them spent.',
          'They come back when that device cancels the payment, or it fails or expires.',
          'With no word from that device they come back on their own: 10 blocks after the payment’s time ran out, 1,440 blocks (about a day) after it was posted without reaching the chain, after 7 days at the latest, or when the device is removed.',
        ]),
        HelpBlock.p('**Release** beside the held coins in $place frees them at once, on this device only. If the other device still finishes its payment, a payment made here with the same coins fails; nothing is lost, as the chain takes only one.'),
      ],
      id: HelpId.heldCoins,
    ),
  ];
}

List<HelpTopic> _de() {
  final place = '[[Einstellungen › Diese Wallet › Verknüpfte Geräte|Settings › This wallet › Linked devices]]';
  return [
    HelpTopic(
      'how',
      'So funktionieren verknüpfte Geräte',
      'Beide Geräte erhalten das Guthaben aus der Blockchain. Verknüpft melden sie sich außerdem verschlüsselt über die Server, was sie bezahlen, damit sie nicht dieselben Münzen ausgeben.',
      [
        const HelpBlock.p('**Beide Geräte müssen schon dieselbe Wallet haben**, aus derselben Wiederherstellungsphrase wiederhergestellt: Die Verknüpfung legt sie auf dem anderen Gerät nicht an. Zwei verschiedene Wallets lassen sich nicht verknüpfen.'),
        const HelpBlock.p('Die Wiederherstellungsphrase öffnet dieselbe Wallet auf jedem Gerät. Die Blockchain liefert jedem Gerät das Guthaben und jede bestätigte Zahlung, daher stimmt das Geld immer.'),
        const HelpBlock.p('Was die Blockchain nicht zeigt, weiß nur das Gerät, das eine Zahlung gemacht hat: wer bezahlt wurde, die Nachricht und eine noch laufende Zahlung. Ohne Verknüpfung zeigt das andere Gerät eine solche Zahlung erst nach der Bestätigung als **Von einem anderen Gerät gesendet**, nur mit dem Betrag.'),
        const HelpBlock.p('Die Verknüpfung ergänzt das. Jedes Gerät meldet dem anderen, wenn es eine Zahlung beginnt und wie sie endet. Die Münzen, die es ausgibt, bleiben auf dem anderen zurückgehalten, bis die Blockchain sie als ausgegeben zeigt; so wählen die beiden Geräte nicht dieselben Münzen, und die Zahlung erscheint als **Gesendet von** mit dem Gerätenamen und ihren Details. Münzen, die diese Wallet auf dem verknüpften Gerät empfangen hat (eine empfangene Zahlung oder das Wechselgeld seiner eigenen Zahlung), erscheinen als **Empfangen auf** mit dem Gerätenamen.'),
        const HelpBlock.p('Beide Geräte beantworten Zahlungen an die Adresse der Wallet. Der Absender nimmt die erste Antwort; die Zahlung erscheint einmal, als auf dem Gerät empfangen, das der Absender genutzt hat.'),
        HelpBlock.ol([
          'Auf beiden Geräten $place öffnen und **Gerät verknüpfen** wählen.',
          'Auf einem Gerät Gerät verknüpfen öffnen und den QR scannen, den das andere zeigt.',
          'Beide zeigen beim Verknüpfen dieselben vier Bilder. Nichts anzutippen: Die App prüft das andere Gerät selbst.',
        ]),
        const HelpBlock.h('Sicherheit', anchor: HelpAnchor.security),
        const HelpBlock.ul([
          '**Eigene Schlüssel für jede Verknüpfung.** Sie entstehen beim Verknüpfen und lassen sich nicht allein aus der Wiederherstellungsphrase ableiten.',
          '**Ende-zu-Ende verschlüsselt.** Nur die verknüpften Geräte können eine Meldung lesen. Die Server tragen sie weiter und können sie nicht lesen.',
          '**Das Entfernen trennt das Gerät ab.** Wird die Verknüpfung auf einem der beiden Geräte entfernt, endet sie auf beiden: Es laufen keine Meldungen mehr.',
          '**Die Verknüpfung schützt das Geld nicht.** Ein Gerät mit der Wiederherstellungsphrase kann weiterhin ausgeben. Die Verknüpfung schützt den Kanal und das, was geteilt wird.',
        ]),
        const HelpBlock.h('Grenzen', anchor: HelpAnchor.limits),
        const HelpBlock.ul([
          '**Nur bei geöffneter App.** Im Hintergrund wird nichts abgeglichen. Die App holt beim Start, beim Fortsetzen, beim Entsperren und beim Aktualisieren nach.',
          '**Die Blockchain entscheidet.** Eine Meldung ist ein Hinweis. Die Blockchain ist die Quelle der Wahrheit, und eine Zahlung zählt, sobald sie dort steht.',
          '**Ein ausgefallener Server verzögert Meldungen.** Mit zwei Servern geht jede Meldung an beide, und der zweite trägt sie weiter.',
          '**Eine dritte App mit derselben Wiederherstellungsphrase wird nicht unterstützt.** Sie erfährt nichts von der Verknüpfung; ihre Zahlungen erscheinen, sobald die Blockchain sie bestätigt.',
        ]),
        const HelpBlock.p('Meldungen laufen über die ersten ein oder zwei Server der Epicbox-Liste, angezeigt unter dem Gerät. Ein weiteres Gerät lässt sich verknüpfen: Zum Verknüpfen eines anderen zuerst dieses entfernen. **Abgleich pausieren** hält die Meldungen eine Weile an.'),
      ],
      devices: true,
      id: HelpId.linkedDevices,
    ),
    HelpTopic(
      'safety',
      'Verknüpfte Geräte und ein verlorenes Gerät',
      'Entfernen beendet den Abgleich mit dem Gerät. Das Geld schützt es nicht: das Guthaben auf eine neue Wiederherstellungsphrase verschieben.',
      [
        HelpBlock.p('Ist das verknüpfte Gerät verloren, verkauft oder weitergegeben, $place öffnen, das Gerät wählen und **Entfernen** wählen. Die Verknüpfung endet auf beiden Geräten: Es erhält keine Meldungen dieser Wallet mehr, und Münzen, die es zurückhielt, werden freigegeben. Das Gerät, das sie nicht entfernt hat, zeigt, wer es war.'),
        const HelpBlock.p('**Das Entfernen schützt das Geld nicht.** Das Gerät hat weiterhin die Wiederherstellungsphrase, und ein Gerät mit der Phrase kann immer ausgeben. Könnte es in fremden Händen sein, eine neue Wallet mit neuer Wiederherstellungsphrase anlegen und das gesamte Guthaben dorthin senden.'),
        const HelpBlock.p('Ein aus der Phrase wiederhergestelltes Gerät ist nicht verknüpft: es erneut verknüpfen.'),
      ],
      id: HelpId.lostDevice,
    ),
    HelpTopic(
      'trouble',
      'Von einem anderen Gerät zurückgehaltene Münzen',
      'Ein verknüpftes Gerät gibt diese Münzen gerade aus. Sie kommen von selbst zurück, wenn seine Zahlung endet; Freigeben gibt sie von Hand frei.',
      [
        const HelpBlock.p('Beginnt ein verknüpftes Gerät eine Zahlung, werden die Münzen, die es ausgibt, auf diesem Gerät zurückgehalten: Sie fehlen beim Senden, bei „Alles senden“ und in den Gebührenschätzungen, Outputs zeigt sie als **Zurückgehalten**, und Senden nennt den zurückgehaltenen Betrag.'),
        const HelpBlock.ul([
          'Sie werden zur Zahlung **Gesendet von** diesem Gerät, sobald die Blockchain sie als ausgegeben zeigt.',
          'Sie kommen zurück, wenn das Gerät die Zahlung storniert oder sie fehlschlägt oder abläuft.',
          'Ohne Meldung des Geräts kommen sie von selbst zurück: 10 Blöcke nach Ablauf der Zahlung, 1.440 Blöcke (etwa ein Tag) nachdem sie übertragen wurde, ohne in der Blockchain anzukommen, spätestens nach 7 Tagen oder wenn das Gerät entfernt wird.',
        ]),
        HelpBlock.p('**Freigeben** neben den zurückgehaltenen Münzen in $place gibt sie sofort frei, nur auf diesem Gerät. Schließt das andere Gerät seine Zahlung doch ab, schlägt eine Zahlung mit denselben Münzen hier fehl; verloren geht nichts, denn die Blockchain nimmt nur eine.'),
      ],
      id: HelpId.heldCoins,
    ),
  ];
}

List<HelpTopic> _pl() {
  final place = '[[Ustawienia › Ten portfel › Połączone urządzenia|Settings › This wallet › Linked devices]]';
  return [
    HelpTopic(
      'how',
      'Jak działają połączone urządzenia',
      'Oba urządzenia biorą saldo z łańcucha. Połączone informują się też nawzajem o płatnościach, szyfrując komunikaty przez serwery, więc nie wydają tych samych monet.',
      [
        const HelpBlock.p('**Oba urządzenia muszą już mieć ten sam portfel**, przywrócony z tej samej frazy odzyskiwania: połączenie nie tworzy go na drugim urządzeniu. Dwóch różnych portfeli nie można połączyć.'),
        const HelpBlock.p('Fraza odzyskiwania otwiera ten sam portfel na każdym urządzeniu. Łańcuch daje każdemu urządzeniu saldo i każdą potwierdzoną płatność, więc pieniądze zawsze się zgadzają.'),
        const HelpBlock.p('Łańcuch nie pokazuje tego, co wie tylko urządzenie, które wykonało płatność: komu zapłacono, wiadomości i płatności w toku. Bez połączenia drugie urządzenie pokazuje taką płatność dopiero po potwierdzeniu jako **Wysłano z innego urządzenia**, tylko z kwotą.'),
        const HelpBlock.p('Połączenie to uzupełnia. Każde urządzenie informuje drugie, gdy zaczyna płatność i jak się ona kończy. Monety, które wydaje, są wstrzymane na drugim, dopóki łańcuch nie pokaże ich jako wydanych; dzięki temu dwa urządzenia nie wybiorą tych samych monet, a płatność widać jako **Wysłano z** z nazwą urządzenia i szczegółami. Monety tego portfela odebrane na połączonym urządzeniu (odebrana płatność albo reszta z jego własnej płatności) widać jako **Odebrano na** z nazwą urządzenia.'),
        const HelpBlock.p('Oba urządzenia odpowiadają na płatności na adres portfela. Nadawca bierze pierwszą odpowiedź; płatność widać raz, jako odebraną na urządzeniu, którego użył nadawca.'),
        HelpBlock.ol([
          'Na obu urządzeniach otwórz $place i wybierz **Połącz urządzenie**.',
          'Na jednym urządzeniu otwórz Połącz urządzenie i zeskanuj QR pokazany na drugim.',
          'Oba pokazują te same cztery obrazki podczas łączenia. Nic nie trzeba wybierać: aplikacja sama sprawdza drugie urządzenie.',
        ]),
        const HelpBlock.h('Bezpieczeństwo', anchor: HelpAnchor.security),
        const HelpBlock.ul([
          '**Własne klucze dla każdego połączenia.** Powstają przy łączeniu urządzeń i nie da się ich wyprowadzić z samej frazy odzyskiwania.',
          '**Szyfrowanie od końca do końca.** Komunikat odczytają tylko połączone urządzenia. Serwery go przenoszą i nie mogą go odczytać.',
          '**Usunięcie połączenia odcina urządzenie.** Usunięte na jednym urządzeniu, kończy się na obu: komunikaty już nie idą.',
          '**Połączenie nie chroni pieniędzy.** Urządzenie z frazą odzyskiwania nadal może wydawać. Połączenie chroni kanał i to, co jest udostępniane.',
        ]),
        const HelpBlock.h('Ograniczenia', anchor: HelpAnchor.limits),
        const HelpBlock.ul([
          '**Tylko gdy aplikacja jest otwarta.** W tle nic się nie synchronizuje. Aplikacja nadrabia przy uruchomieniu, wznowieniu, odblokowaniu i odświeżeniu.',
          '**Decyduje łańcuch.** Komunikat to zapowiedź. Źródłem prawdy jest łańcuch bloków, a płatność liczy się, gdy łańcuch ją pokaże.',
          '**Niedostępny serwer opóźnia komunikaty.** Przy dwóch serwerach każdy komunikat idzie do obu, a drugi go przenosi.',
          '**Trzecia aplikacja z tą samą frazą odzyskiwania nie jest obsługiwana.** Nie słyszy połączenia; jej płatności widać, gdy łańcuch je potwierdzi.',
        ]),
        const HelpBlock.p('Komunikaty idą przez pierwszy jeden lub dwa serwery z listy Epicbox, widoczne pod urządzeniem. Można połączyć jedno inne urządzenie: aby połączyć inne, najpierw je usuń. **Wstrzymaj synchronizację** zatrzymuje komunikaty na jakiś czas.'),
      ],
      devices: true,
      id: HelpId.linkedDevices,
    ),
    HelpTopic(
      'safety',
      'Połączone urządzenia i zgubione urządzenie',
      'Usunięcie kończy synchronizację z urządzeniem. Nie chroni pieniędzy: przenieś środki na nową frazę odzyskiwania.',
      [
        HelpBlock.p('Jeśli połączone urządzenie zostało zgubione, sprzedane lub oddane, otwórz $place, wybierz je i wybierz **Usuń**. Połączenie kończy się na obu urządzeniach: przestaje ono dostawać komunikaty tego portfela, a wstrzymane przez nie monety zostają zwolnione. Urządzenie, które go nie usunęło, pokazuje, kto to zrobił.'),
        const HelpBlock.p('**Usunięcie urządzenia nie chroni pieniędzy.** Urządzenie nadal ma frazę odzyskiwania, a urządzenie z frazą zawsze może wydawać. Jeśli może być w cudzych rękach, utwórz nowy portfel z nową frazą odzyskiwania i wyślij do niego wszystkie środki.'),
        const HelpBlock.p('Urządzenie odtworzone z frazy nie jest połączone: połącz je ponownie.'),
      ],
      id: HelpId.lostDevice,
    ),
    HelpTopic(
      'trouble',
      'Monety wstrzymane przez inne urządzenie',
      'Połączone urządzenie wydaje te monety. Wracają same, gdy jego płatność się kończy; Zwolnij uwalnia je ręcznie.',
      [
        const HelpBlock.p('Gdy połączone urządzenie zaczyna płatność, monety, które wydaje, są wstrzymane na tym urządzeniu: nie biorą udziału w wysyłkach, „Wyślij wszystko” ani w szacowaniu opłat, Wyjścia pokazują je jako **Wstrzymane**, a Wyślij podaje, ile jest wstrzymane.'),
        const HelpBlock.ul([
          'Stają się płatnością **Wysłano z** tego urządzenia, gdy łańcuch pokaże je jako wydane.',
          'Wracają, gdy to urządzenie anuluje płatność albo gdy ona się nie powiedzie lub wygaśnie.',
          'Bez wiadomości od urządzenia wracają same: 10 bloków po upływie czasu płatności, 1440 bloków (około doby) po jej rozgłoszeniu bez trafienia do łańcucha, najpóźniej po 7 dniach albo po usunięciu urządzenia.',
        ]),
        HelpBlock.p('**Zwolnij** przy wstrzymanych monetach w $place uwalnia je od razu, tylko na tym urządzeniu. Jeśli drugie urządzenie jednak dokończy płatność, płatność z tych samych monet tutaj się nie powiedzie; nic nie przepada, bo łańcuch przyjmie tylko jedną.'),
      ],
      id: HelpId.heldCoins,
    ),
  ];
}

List<HelpTopic> _ru() {
  final place = '[[Настройки › Этот кошелёк › Связанные устройства|Settings › This wallet › Linked devices]]';
  return [
    HelpTopic(
      'how',
      'Как работают связанные устройства',
      'Оба устройства берут баланс из блокчейна. Связанные, они ещё и сообщают друг другу о платежах, зашифрованно через серверы, чтобы не тратить одни и те же монеты.',
      [
        const HelpBlock.p('**На обоих устройствах уже должен быть один и тот же кошелёк**, восстановленный из той же фразы восстановления: связь не создаёт его на другом устройстве. Два разных кошелька связать нельзя.'),
        const HelpBlock.p('Фраза восстановления открывает один и тот же кошелёк на любом устройстве. Блокчейн даёт каждому устройству баланс и все подтверждённые платежи, поэтому деньги всегда сходятся.'),
        const HelpBlock.p('Блокчейн не показывает то, что знает только устройство, сделавшее платёж: кому заплачено, сообщение и платёж, который ещё идёт. Без связи другое устройство покажет такой платёж только после подтверждения, как **Отправлено с другого устройства**, лишь с суммой.'),
        const HelpBlock.p('Связь добавляет это. Каждое устройство сообщает другому, когда начинает платёж и чем он закончился. Монеты, которые оно тратит, удерживаются на другом, пока блокчейн не покажет их потраченными; так два устройства не выберут одни и те же монеты, а платёж виден как **Отправлено с** с именем устройства и подробностями. Монеты этого кошелька, полученные на связанном устройстве (принятый платёж или сдача от его собственного платежа), видны как **Получено на** с именем устройства.'),
        const HelpBlock.p('Оба устройства отвечают на платежи на адрес кошелька. Отправитель берёт первый ответ; платёж виден один раз, как полученный на устройстве, которое выбрал отправитель.'),
        HelpBlock.ol([
          'На обоих устройствах откройте $place и выберите **Связать устройство**.',
          'На одном устройстве откройте Связать устройство и отсканируйте QR, показанный на другом.',
          'Оба показывают одни и те же четыре картинки, пока связываются. Нажимать ничего не нужно: приложение само проверяет другое устройство.',
        ]),
        const HelpBlock.h('Безопасность', anchor: HelpAnchor.security),
        const HelpBlock.ul([
          '**Свои ключи для каждой связи.** Они создаются при связывании устройств, и из одной фразы восстановления их не вывести.',
          '**Сквозное шифрование.** Прочитать сообщение могут только связанные устройства. Серверы передают его и не могут прочитать.',
          '**Удаление связи отключает устройство.** Если удалить её на одном устройстве, она заканчивается на обоих: сообщения больше не идут.',
          '**Связь не защищает деньги.** Устройство с фразой восстановления по-прежнему может тратить. Связь защищает канал и то, чем делятся устройства.',
        ]),
        const HelpBlock.h('Ограничения', anchor: HelpAnchor.limits),
        const HelpBlock.ul([
          '**Только пока приложение открыто.** В фоне ничего не синхронизируется. Приложение догоняет при запуске, возобновлении, разблокировке и обновлении.',
          '**Решает блокчейн.** Сообщение лишь предупреждает. Источник истины блокчейн, и платёж считается, когда он там виден.',
          '**Недоступный сервер задерживает сообщения.** При двух серверах каждое сообщение идёт на оба, и второй его доносит.',
          '**Третье приложение с той же фразой восстановления не поддерживается.** Оно ничего не знает о связи; его платежи видны, когда их подтвердит блокчейн.',
        ]),
        const HelpBlock.p('Сообщения идут через первые один или два сервера списка Epicbox, показанные под устройством. Связать можно одно другое устройство: чтобы связать другое, сначала удалите его. **Приостановить синхронизацию** ненадолго останавливает сообщения.'),
      ],
      devices: true,
      id: HelpId.linkedDevices,
    ),
    HelpTopic(
      'safety',
      'Связанные устройства и потерянное устройство',
      'Удаление останавливает синхронизацию с устройством. Деньги оно не защищает: переведите средства на новую фразу восстановления.',
      [
        HelpBlock.p('Если связанное устройство потеряно, продано или отдано, откройте $place, выберите его и выберите **Удалить**. Связь заканчивается на обоих устройствах: оно больше не получает сообщений этого кошелька, а удержанные им монеты освобождаются. Устройство, которое его не удаляло, показывает, кто это сделал.'),
        const HelpBlock.p('**Удаление устройства не защищает деньги.** На устройстве остаётся фраза восстановления, а устройство с фразой всегда может тратить. Если оно может быть в чужих руках, создайте новый кошелёк с новой фразой восстановления и отправьте на него все средства.'),
        const HelpBlock.p('Устройство, восстановленное из фразы, не связано: свяжите его снова.'),
      ],
      id: HelpId.lostDevice,
    ),
    HelpTopic(
      'trouble',
      'Монеты, удержанные другим устройством',
      'Связанное устройство тратит эти монеты. Они вернутся сами, когда его платёж закончится; Освободить возвращает их вручную.',
      [
        const HelpBlock.p('Когда связанное устройство начинает платёж, тратимые им монеты удерживаются на этом устройстве: они не участвуют в отправках, «Отправить всё» и оценке комиссии, Выходы показывают их как **Удержано**, а Отправка сообщает, сколько удержано.'),
        const HelpBlock.ul([
          'Они становятся платежом **Отправлено с** этого устройства, когда блокчейн покажет их потраченными.',
          'Они возвращаются, когда устройство отменяет платёж, или он не проходит или истекает.',
          'Без вестей от устройства они возвращаются сами: через 10 блоков после окончания срока платежа, через 1440 блоков (около суток) после его отправки в сеть без попадания в блокчейн, не позже чем через 7 дней или при удалении устройства.',
        ]),
        HelpBlock.p('**Освободить** рядом с удержанными монетами в $place сразу освобождает их, только на этом устройстве. Если другое устройство всё же завершит платёж, платёж с теми же монетами здесь не пройдёт; ничего не теряется, блокчейн примет только один.'),
      ],
      id: HelpId.heldCoins,
    ),
  ];
}

List<HelpTopic> _zh() {
  final place = '[[设置 › 此钱包 › 关联设备|Settings › This wallet › Linked devices]]';
  return [
    HelpTopic(
      'how',
      '关联设备的工作方式',
      '两台设备都从区块链获取余额。关联后，它们还会经服务器加密互相告知正在进行的付款，避免花费相同的币。',
      [
        const HelpBlock.p('**两台设备都必须已有同一个钱包**，即用同一个助记词恢复：关联不会在另一台设备上创建钱包。两个不同的钱包无法关联。'),
        const HelpBlock.p('助记词可以在任何设备上打开同一个钱包。区块链为每台设备提供余额和每笔已确认的付款，所以资金总是对得上。'),
        const HelpBlock.p('区块链不会显示只有发起付款的设备才知道的内容：付给了谁、留言，以及仍在进行中的付款。未关联时，另一台设备要等付款确认后才会显示为 **从另一台设备发送**，且只有金额。'),
        const HelpBlock.p('关联补上了这些。每台设备在开始付款和付款结束时都会告知另一台。它花费的币会在另一台设备上被保留，直到区块链显示它们已花费；这样两台设备不会选中相同的币，付款也会显示为 **从某设备发送**，并带有详情。本钱包在关联设备上收到的币（收到的付款，或它自己付款的找零）会显示为 **在某设备上收到**，并带有设备名称。'),
        const HelpBlock.p('两台设备都会回应发往钱包地址的付款。发送方采用最先到达的回应；付款只显示一次，显示为在发送方所用的设备上收到。'),
        HelpBlock.ol([
          '在两台设备上打开 $place，选择 **关联设备**。',
          '在一台设备上打开关联设备，扫描另一台设备显示的二维码。',
          '关联过程中两台设备显示相同的四张图片。无需点按：应用会自行核对另一台设备。',
        ]),
        const HelpBlock.h('安全', anchor: HelpAnchor.security),
        const HelpBlock.ul([
          '**每个关联有自己的密钥。** 密钥在设备关联时生成，无法仅凭助记词推算出来。',
          '**端到端加密。** 只有关联的设备能读取消息。服务器只负责传递，无法读取。',
          '**移除关联即切断该设备。** 在任一台设备上移除，关联在两台设备上都会结束：不再传递消息。',
          '**关联不能保护资金。** 持有助记词的设备仍然可以花费。关联保护的是通道和共享的内容。',
        ]),
        const HelpBlock.h('限制', anchor: HelpAnchor.limits),
        const HelpBlock.ul([
          '**仅在应用打开时。** 后台不会同步。应用在启动、恢复、解锁和刷新时补上。',
          '**由区块链决定。** 消息只是提前告知。区块链是最终依据，付款以区块链显示为准。',
          '**服务器故障会延迟消息。** 使用两个服务器时，每条消息都发到两个，由第二个传递。',
          '**不支持使用同一助记词的第三个应用。** 它收不到关联消息；它的付款在区块链确认后才会显示。',
        ]),
        const HelpBlock.p('消息经过 Epicbox 列表中排在最前的一到两个服务器，显示在设备下方。可以关联另一台设备：要关联别的设备，请先移除它。**暂停同步** 可暂时停止传递消息。'),
      ],
      devices: true,
      id: HelpId.linkedDevices,
    ),
    HelpTopic(
      'safety',
      '关联设备与丢失的设备',
      '移除会停止与该设备的同步。它不能保护资金：请把资金转到新的助记词。',
      [
        HelpBlock.p('如果关联设备丢失、出售或送人，打开 $place，选择该设备并选择 **移除**。关联在两台设备上都会结束：它将不再收到这个钱包的消息，它保留的币也会被释放。没有执行移除的那台设备会显示是谁移除的。'),
        const HelpBlock.p('**移除设备不能保护资金。** 该设备仍持有助记词，而持有助记词的设备始终可以花费。如果它可能落入他人之手，请用新的助记词创建新钱包，并把全部资金发送过去。'),
        const HelpBlock.p('从助记词恢复的设备不会自动关联：请重新关联。'),
      ],
      id: HelpId.lostDevice,
    ),
    HelpTopic(
      'trouble',
      '被另一台设备保留的币',
      '一台关联设备正在花费这些币。它的付款结束后会自动退回；也可用 释放 手动解除。',
      [
        const HelpBlock.p('关联设备开始付款时，它花费的币会在本设备上被保留：发送、全部发送和手续费估算都不会使用它们，输出页把它们显示为 **被保留**，发送页会说明保留了多少。'),
        const HelpBlock.ul([
          '区块链显示这些币已花费后，它们成为 **从该设备发送** 的付款。',
          '该设备取消付款，或付款失败、过期时，它们会退回。',
          '若该设备没有消息，它们会自动退回：付款期限过后 10 个区块、广播后 1,440 个区块（约一天）仍未上链、最迟 7 天后，或该设备被移除时。',
        ]),
        HelpBlock.p('在 $place 中保留的币旁边选择 **释放**，会立即在本设备上释放它们（仅本设备）。如果另一台设备仍完成了付款，本设备用同样的币进行的付款会失败；不会损失任何东西，区块链只接受其中一笔。'),
      ],
      id: HelpId.heldCoins,
    ),
  ];
}

List<HelpTopic> _th() {
  final place = '[[การตั้งค่า › กระเป๋าเงินนี้ › อุปกรณ์ที่เชื่อมโยง|Settings › This wallet › Linked devices]]';
  return [
    HelpTopic(
      'how',
      'อุปกรณ์ที่เชื่อมโยงทำงานอย่างไร',
      'ทั้งสองอุปกรณ์รับยอดเงินจากเชน เมื่อเชื่อมโยงแล้ว จะแจ้งกันแบบเข้ารหัสผ่านเซิร์ฟเวอร์ด้วยว่ากำลังจ่ายอะไร จึงไม่ใช้เหรียญเดียวกัน',
      [
        const HelpBlock.p('**ทั้งสองอุปกรณ์ต้องมีกระเป๋าเงินเดียวกันอยู่แล้ว** โดยกู้คืนจากวลีกู้คืนเดียวกัน การเชื่อมโยงไม่ได้สร้างกระเป๋าเงินบนอีกอุปกรณ์ให้ ไม่สามารถเชื่อมโยงกระเป๋าเงินสองใบที่ต่างกันได้'),
        const HelpBlock.p('วลีกู้คืนเปิดกระเป๋าเงินเดียวกันได้บนทุกอุปกรณ์ เชนให้ยอดเงินและทุกรายการที่ยืนยันแล้วแก่แต่ละอุปกรณ์ เงินจึงตรงกันเสมอ'),
        const HelpBlock.p('สิ่งที่เชนไม่แสดงคือสิ่งที่รู้เฉพาะอุปกรณ์ที่ทำรายการ: จ่ายให้ใคร ข้อความ และรายการที่ยังไม่เสร็จ หากไม่ได้เชื่อมโยง อุปกรณ์อีกเครื่องจะแสดงรายการนั้นหลังยืนยันแล้วเท่านั้น ว่า **ส่งจากอุปกรณ์อื่น** พร้อมจำนวนเงินอย่างเดียว'),
        const HelpBlock.p('การเชื่อมโยงเติมส่วนนี้ แต่ละอุปกรณ์แจ้งอีกเครื่องเมื่อเริ่มรายการและเมื่อรายการจบ เหรียญที่มันใช้จะถูกพักไว้บนอีกเครื่องจนกว่าเชนจะแสดงว่าใช้ไปแล้ว สองอุปกรณ์จึงไม่เลือกเหรียญเดียวกัน และรายการจะแสดงว่า **ส่งจาก** ตามด้วยชื่ออุปกรณ์พร้อมรายละเอียด เหรียญของกระเป๋าเงินนี้ที่อุปกรณ์ที่เชื่อมโยงได้รับ (รายการที่รับ หรือเงินทอนจากรายการที่ส่งเอง) จะแสดงว่า **รับบน** ตามด้วยชื่ออุปกรณ์'),
        const HelpBlock.p('ทั้งสองอุปกรณ์ตอบรายการที่ส่งมายังที่อยู่ของกระเป๋าเงิน ผู้ส่งรับคำตอบแรก รายการจะแสดงครั้งเดียว ว่ารับบนเครื่องที่ผู้ส่งใช้'),
        HelpBlock.ol([
          'เปิด $place บนทั้งสองอุปกรณ์ แล้วเลือก **เชื่อมโยงอุปกรณ์**',
          'บนเครื่องหนึ่งเปิดเชื่อมโยงอุปกรณ์ แล้วสแกน QR ที่แสดงบนอีกเครื่อง',
          'ระหว่างเชื่อมโยง ทั้งสองเครื่องแสดงภาพสี่ภาพเดียวกัน ไม่ต้องแตะอะไร แอปตรวจสอบอีกเครื่องเอง',
        ]),
        const HelpBlock.h('ความปลอดภัย', anchor: HelpAnchor.security),
        const HelpBlock.ul([
          '**กุญแจของตัวเองสำหรับแต่ละการเชื่อมโยง** สร้างขึ้นเมื่อเชื่อมโยงอุปกรณ์ และคำนวณจากวลีกู้คืนอย่างเดียวไม่ได้',
          '**เข้ารหัสจากต้นทางถึงปลายทาง** มีเพียงอุปกรณ์ที่เชื่อมโยงเท่านั้นที่อ่านข้อความได้ เซิร์ฟเวอร์เป็นผู้ส่งต่อและอ่านไม่ได้',
          '**การนำการเชื่อมโยงออกจะตัดอุปกรณ์นั้นออกไป** หากนำออกบนเครื่องใดเครื่องหนึ่ง การเชื่อมโยงจะสิ้นสุดบนทั้งสองเครื่อง และไม่มีข้อความส่งถึงกันอีก',
          '**การเชื่อมโยงไม่ได้ปกป้องเงิน** อุปกรณ์ที่มีวลีกู้คืนยังใช้จ่ายได้ การเชื่อมโยงปกป้องช่องทางและสิ่งที่แชร์กัน',
        ]),
        const HelpBlock.h('ข้อจำกัด', anchor: HelpAnchor.limits),
        const HelpBlock.ul([
          '**เฉพาะเมื่อแอปเปิดอยู่** ไม่มีการซิงค์ในพื้นหลัง แอปจะตามให้ทันเมื่อเริ่ม กลับมาใช้ ปลดล็อก หรือรีเฟรช',
          '**เชนเป็นผู้ตัดสิน** ข้อความเป็นเพียงการบอกล่วงหน้า บล็อกเชนคือแหล่งความจริง และรายการจะนับเมื่อเชนแสดง',
          '**เซิร์ฟเวอร์ล่มทำให้ข้อความช้า** เมื่อใช้สองเซิร์ฟเวอร์ ทุกข้อความส่งไปทั้งสอง และเครื่องที่สองจะส่งต่อให้',
          '**ไม่รองรับแอปที่สามที่ใช้วลีกู้คืนเดียวกัน** แอปนั้นไม่รู้เรื่องการเชื่อมโยง รายการของมันจะแสดงเมื่อเชนยืนยันแล้ว',
        ]),
        const HelpBlock.p('ข้อความส่งผ่านเซิร์ฟเวอร์หนึ่งหรือสองเครื่องแรกของรายการ Epicbox ที่แสดงใต้อุปกรณ์ เชื่อมโยงอุปกรณ์อื่นได้หนึ่งเครื่อง: นำออกก่อนจึงจะเชื่อมโยงเครื่องอื่นได้ **หยุดซิงค์ชั่วคราว** จะหยุดข้อความชั่วคราว'),
      ],
      devices: true,
      id: HelpId.linkedDevices,
    ),
    HelpTopic(
      'safety',
      'อุปกรณ์ที่เชื่อมโยงกับอุปกรณ์ที่หาย',
      'นำออกจะหยุดการซิงค์กับอุปกรณ์นั้น แต่ไม่ได้ปกป้องเงิน ให้ย้ายเงินไปยังวลีกู้คืนใหม่',
      [
        HelpBlock.p('หากอุปกรณ์ที่เชื่อมโยงหาย ถูกขาย หรือยกให้คนอื่น เปิด $place เลือกอุปกรณ์นั้นแล้วเลือก **นำออก** การเชื่อมโยงจะสิ้นสุดบนทั้งสองเครื่อง อุปกรณ์นั้นจะไม่ได้รับข้อความของกระเป๋าเงินนี้อีก และเหรียญที่มันพักไว้จะถูกปล่อย เครื่องที่ไม่ได้นำออกจะแสดงว่าใครเป็นผู้นำออก'),
        const HelpBlock.p('**การนำอุปกรณ์ออกไม่ได้ปกป้องเงิน** อุปกรณ์นั้นยังมีวลีกู้คืน และอุปกรณ์ที่มีวลีกู้คืนใช้จ่ายได้เสมอ ถ้าอาจอยู่ในมือคนอื่น ให้สร้างกระเป๋าเงินใหม่ด้วยวลีกู้คืนใหม่ แล้วส่งเงินทั้งหมดไปที่นั่น'),
        const HelpBlock.p('อุปกรณ์ที่กู้คืนจากวลีจะไม่ได้เชื่อมโยง ให้เชื่อมโยงอีกครั้ง'),
      ],
      id: HelpId.lostDevice,
    ),
    HelpTopic(
      'trouble',
      'เหรียญที่อุปกรณ์อื่นพักไว้',
      'อุปกรณ์ที่เชื่อมโยงกำลังใช้เหรียญเหล่านี้ เหรียญจะกลับมาเองเมื่อรายการของมันจบ หรือกด ปล่อย เพื่อปล่อยเอง',
      [
        const HelpBlock.p('เมื่ออุปกรณ์ที่เชื่อมโยงเริ่มรายการ เหรียญที่มันใช้จะถูกพักไว้บนอุปกรณ์นี้ จะไม่ถูกใช้ในการส่ง ส่งทั้งหมด และการประมาณค่าธรรมเนียม หน้าเอาต์พุตแสดงว่า **ถูกพักไว้** และหน้าส่งจะบอกว่าพักไว้เท่าไร'),
        const HelpBlock.ul([
          'เหรียญจะกลายเป็นรายการ **ส่งจาก** อุปกรณ์นั้น เมื่อเชนแสดงว่าใช้ไปแล้ว',
          'เหรียญจะกลับมาเมื่ออุปกรณ์นั้นยกเลิกรายการ หรือรายการล้มเหลวหรือหมดเวลา',
          'หากไม่มีข่าวจากอุปกรณ์นั้น เหรียญจะกลับมาเอง: 10 บล็อกหลังรายการหมดเวลา 1,440 บล็อก (ประมาณหนึ่งวัน) หลังส่งขึ้นเครือข่ายแล้วยังไม่เข้าเชน อย่างช้า 7 วัน หรือเมื่อนำอุปกรณ์ออก',
        ]),
        HelpBlock.p('**ปล่อย** ข้างเหรียญที่ถูกพักไว้ใน $place จะปล่อยทันที เฉพาะบนอุปกรณ์นี้ ถ้าอุปกรณ์อีกเครื่องยังทำรายการเสร็จ รายการที่ใช้เหรียญเดียวกันบนเครื่องนี้จะล้มเหลว ไม่มีอะไรสูญหาย เพราะเชนรับเพียงรายการเดียว'),
      ],
      id: HelpId.heldCoins,
    ),
  ];
}
