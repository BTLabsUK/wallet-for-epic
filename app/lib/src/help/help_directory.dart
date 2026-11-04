// SPDX-License-Identifier: Apache-2.0
/// Help on payment links and paying you as your name, for the phone and the desktop, in the app's
/// six languages: what a payment link is and how the wallet checks it, the line above Send,
/// contacts that take no payments, Pay me as @name, telling the service a payment is sent, and a
/// link payment nobody answers. Each
/// language's topic list (help_content.dart, help_`<lang>`.dart) ends with these; they show
/// always, as the wallet pairs with a service and a link can arrive at any time.
library;

import 'help_content.dart';

/// The payment link and directory topics in [lang] (`en`, `de`, `pl`, `ru`, `zh`, `th`).
List<HelpTopic> directoryHelpTopics(String lang, {required bool phone}) => switch (lang) {
  'de' => _de(phone),
  'pl' => _pl(phone),
  'ru' => _ru(phone),
  'zh' => _zh(phone),
  'th' => _th(phone),
  _ => _en(phone),
};

List<HelpTopic> _en(bool phone) {
  final secret = phone ? 'your PIN' : 'the wallet password';
  return [
    HelpTopic(
      'start',
      'Payment links',
      'A payment link is a request to pay, made by a service you paired with. Open it and Send is filled in. You still confirm the payment yourself.',
      [
        const HelpBlock.p('A payment link is a payment request made by a service you paired with: who to pay, the amount (or you choose it) and when the request expires. It starts with **epiccash://pay/1/…** or is a web link that ends in **/p#1/…**.'),
        const HelpBlock.p('Open one by tapping it, scanning it, pasting it or sharing it to the app. [[Send]] opens already filled in.'),
        const HelpBlock.p('Before it fills anything, the wallet checks the link on this device:'),
        const HelpBlock.ul([
          'the service’s signature,',
          'the payee wallet’s own signature for their name,',
          'the network,',
          'the expiry,',
          'and that the link was not made for someone else.',
        ]),
        const HelpBlock.p('A link that fails shows why and fills nothing.'),
        HelpBlock.p('You can change the amount. Send then notes that it is not the amount requested. Paying needs $secret, as any payment does.'),
      ],
      id: HelpId.paymentLinks,
    ),
    HelpTopic(
      'start',
      'The line above Send',
      'It says where the request came from. “Not from a service you paired with” can still be right: ask the payee.',
      [
        const HelpBlock.p('When Send opens from a payment link, a line above the amount says where the request came from. The four pictures belong to the payee’s name: the payee can see the same four in the service, so you can compare them.'),
        const HelpBlock.ul([
          '**@name · via** a contact name: the request came through a service you paired with in this wallet.',
          '**Not from a service you paired with**: the payment can still be right. Ask the payee.',
          '**You paid this request on** a date: you already paid it. **Pay again** is there if you mean to.',
          '**@name now gets paid to a different wallet than when you paid on** a date: the payee’s wallet changed since you last paid them by link. Pay only if they told you.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'start',
      'Contacts that take no payments',
      'Some contacts take no payments.',
      [
        const HelpBlock.p('Some contacts take no payments. A service where people pay you as your @name is one. It says so when you pair.'),
        const HelpBlock.p('In Contacts and in the list of recipients, such a contact carries a coin struck through; its page says **No payments**. Pasting or scanning its address into Send is refused.'),
        const HelpBlock.p('A payment sent to such a contact from another wallet is never collected. It stays pending there until the sender cancels it.'),
      ],
      id: HelpId.noPayments,
    ),
    HelpTopic(
      'network',
      'Pay me as @name',
      'A service you paired with can let people pay you as your @name. The wallet has none built in. Turning it on sends the service one address made only for it.',
      [
        const HelpBlock.p('Some services, run by someone else, let people pay each other as an @name through a payment link. The wallet has none built in.'),
        const HelpBlock.p('Pairing with a service is a contact pairing. Open its invite and **Check the code**: compare the pictures shown by both. Then choose **Pay me as @name**. The service appears in [[Contacts]].'),
        const HelpBlock.p('Turning it on sends the service a payment address made only for it, signed by this wallet. Nothing else: no balance and no other address.'),
        const HelpBlock.p('**Leave** on the service’s contact page takes your name off it. The wallet keeps receiving to that address for 7 days, then stops.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Telling the service a payment is sent',
      'Optional, and per payment. The service sees the request’s short id, the amount and the time. Nothing else.',
      [
        const HelpBlock.p('After you pay a link, an unticked line offers to tell the service the payment is sent. It is your choice each time. The wallet never does it by itself.'),
        const HelpBlock.p('If you tick it, the service sees the request’s short id, the amount and the time. It does not see an address or a transaction id.'),
      ],
      id: HelpId.directoryTell,
    ),
    HelpTopic(
      'trouble',
      'A link payment nobody answers',
      'It waits for the payee’s wallet like any Epicbox payment. After 24 hours you can cancel and send another way.',
      [
        const HelpBlock.p('A link payment waits for the payee’s wallet like any Epicbox payment. The payee does not have to be online right now.'),
        const HelpBlock.ul([
          'After 24 hours it shows **Not answered yet**, with **Cancel and send by Epicbox**.',
          'At 7 days the Epicbox server has dropped the payment. Cancel it to free the coins.',
        ]),
      ],
      id: HelpId.linkUnanswered,
    ),
  ];
}

List<HelpTopic> _de(bool phone) {
  final secret = phone ? 'Ihre PIN oder Passphrase' : 'das Wallet-Passwort';
  return [
    HelpTopic(
      'start',
      'Zahlungslinks',
      'Ein Zahlungslink ist eine Zahlungsaufforderung eines Dienstes, mit dem Sie gekoppelt sind. Öffnen Sie ihn, und Senden ist ausgefüllt. Die Zahlung bestätigen Sie weiterhin selbst.',
      [
        const HelpBlock.p('Ein Zahlungslink ist eine Zahlungsaufforderung, die ein Dienst erstellt hat, mit dem Sie gekoppelt sind: wer bezahlt wird, der Betrag (oder Sie wählen ihn) und wann die Aufforderung abläuft. Er beginnt mit **epiccash://pay/1/…** oder ist ein Weblink, der auf **/p#1/…** endet.'),
        const HelpBlock.p('Öffnen Sie ihn per Tippen, Scannen, Einfügen oder indem Sie ihn mit der App teilen. [[Senden|Send]] öffnet sich dann schon ausgefüllt.'),
        const HelpBlock.p('Bevor etwas ausgefüllt wird, prüft die Wallet den Link auf diesem Gerät:'),
        const HelpBlock.ul([
          'die Signatur des Dienstes,',
          'die eigene Signatur der Empfänger-Wallet für ihren Namen,',
          'das Netzwerk,',
          'das Ablaufdatum,',
          'und dass der Link nicht für jemand anderen erstellt wurde.',
        ]),
        const HelpBlock.p('Ein Link, der die Prüfung nicht besteht, zeigt den Grund und füllt nichts aus.'),
        HelpBlock.p('Sie können den Betrag ändern. Senden weist dann darauf hin, dass es nicht der angeforderte Betrag ist. Zum Bezahlen braucht es $secret, wie bei jeder Zahlung.'),
      ],
      id: HelpId.paymentLinks,
    ),
    HelpTopic(
      'start',
      'Die Zeile über Senden',
      'Sie sagt, woher die Aufforderung kommt. „Nicht von einem Dienst, mit dem Sie gekoppelt sind“ kann trotzdem stimmen: Fragen Sie den Empfänger.',
      [
        const HelpBlock.p('Wenn Senden aus einem Zahlungslink geöffnet wird, sagt eine Zeile über dem Betrag, woher die Aufforderung kommt. Die vier Bilder gehören zum Namen des Empfängers: Der Empfänger sieht dieselben vier im Dienst, so können Sie vergleichen.'),
        const HelpBlock.ul([
          '**@name · über** ein Kontaktname: Die Aufforderung kam über einen Dienst, mit dem Sie in dieser Wallet gekoppelt sind.',
          '**Nicht von einem Dienst, mit dem Sie gekoppelt sind**: Die Zahlung kann trotzdem richtig sein. Fragen Sie den Empfänger.',
          '**Sie haben diese Anfrage bezahlt am** Datum: Sie haben sie schon bezahlt. **Erneut bezahlen** steht bereit, falls Sie es wollen.',
          '**@name wird jetzt auf eine andere Wallet bezahlt als bei Ihrer Zahlung am** Datum: Die Wallet des Empfängers hat sich geändert, seit Sie ihn zuletzt per Link bezahlt haben. Zahlen Sie nur, wenn er es Ihnen gesagt hat.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'start',
      'Kontakte, die keine Zahlungen annehmen',
      'Manche Kontakte nehmen keine Zahlungen an.',
      [
        const HelpBlock.p('Manche Kontakte nehmen keine Zahlungen an. Ein Dienst, bei dem man Sie als Ihren @name bezahlt, gehört dazu. Er sagt es beim Koppeln.'),
        const HelpBlock.p('In Kontakte und in der Liste der Empfänger trägt ein solcher Kontakt eine durchgestrichene Münze; seine Seite zeigt **Keine Zahlungen**. Seine Adresse in Senden einzufügen oder zu scannen wird abgelehnt.'),
        const HelpBlock.p('Eine Zahlung von einer anderen Wallet an einen solchen Kontakt wird nie abgeholt. Sie bleibt dort offen, bis der Absender sie storniert.'),
      ],
      id: HelpId.noPayments,
    ),
    HelpTopic(
      'network',
      'Als @name bezahlt werden',
      'Ein Dienst, mit dem Sie gekoppelt sind, kann es anderen ermöglichen, Sie als Ihren @name zu bezahlen. Die Wallet hat keinen eingebaut. Beim Einschalten erhält der Dienst eine Adresse, die nur für ihn gemacht ist.',
      [
        const HelpBlock.p('Manche Dienste, die jemand betreibt, ermöglichen es, sich über einen Zahlungslink als @name zu bezahlen. Die Wallet hat keinen eingebaut.'),
        const HelpBlock.p('Die Kopplung mit einem Dienst ist eine Kontaktkopplung. Öffnen Sie seine Einladung und wählen Sie **Code prüfen**: Vergleichen Sie die Bilder, die beide zeigen. Wählen Sie dann **Als @name bezahlt werden**. Der Dienst erscheint unter [[Kontakte|Contacts]].'),
        const HelpBlock.p('Beim Einschalten sendet diese Wallet dem Dienst eine Zahlungsadresse, die nur für ihn gemacht und von der Wallet signiert ist. Sonst nichts: kein Guthaben und keine andere Adresse.'),
        const HelpBlock.p('**Verlassen** auf der Kontaktseite des Dienstes nimmt Ihren Namen dort heraus. Die Wallet empfängt an dieser Adresse noch 7 Tage lang weiter und hört dann auf.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Dem Dienst eine Zahlung melden',
      'Freiwillig und pro Zahlung. Der Dienst sieht die Kurz-ID der Aufforderung, den Betrag und die Zeit. Sonst nichts.',
      [
        const HelpBlock.p('Nachdem Sie einen Link bezahlt haben, bietet eine nicht angehakte Zeile an, dem Dienst die Zahlung zu melden. Das entscheiden Sie jedes Mal neu. Die Wallet tut es nie von selbst.'),
        const HelpBlock.p('Wenn Sie es ankreuzen, sieht der Dienst die Kurz-ID der Aufforderung, den Betrag und die Zeit. Eine Adresse oder eine Transaktions-ID sieht es nicht.'),
      ],
      id: HelpId.directoryTell,
    ),
    HelpTopic(
      'trouble',
      'Eine Link-Zahlung, die niemand beantwortet',
      'Sie wartet auf die Wallet des Empfängers wie jede Epicbox-Zahlung. Nach 24 Stunden können Sie abbrechen und anders senden.',
      [
        const HelpBlock.p('Eine Link-Zahlung wartet auf die Wallet des Empfängers wie jede Epicbox-Zahlung. Der Empfänger muss nicht gerade online sein.'),
        const HelpBlock.ul([
          'Nach 24 Stunden zeigt sie **Noch nicht beantwortet**, mit **Stornieren und per Epicbox senden**.',
          'Nach 7 Tagen hat der Epicbox-Server die Zahlung verworfen. Brechen Sie sie ab, um die Coins freizugeben.',
        ]),
      ],
      id: HelpId.linkUnanswered,
    ),
  ];
}

List<HelpTopic> _pl(bool phone) {
  final secret = phone ? 'swojego PINu lub hasła' : 'hasła portfela';
  return [
    HelpTopic(
      'start',
      'Linki płatności',
      'Link płatności to prośba o zapłatę, którą tworzy usługa, z którą się sparowano. Otwórz go, a Wyślij będzie wypełnione. Płatność nadal potwierdzasz sam.',
      [
        const HelpBlock.p('Link płatności to prośba o zapłatę utworzona przez usługę, z którą się sparowano: komu zapłacić, kwota (albo wybierasz ją sam) i kiedy prośba wygasa. Zaczyna się od **epiccash://pay/1/…** albo jest linkiem internetowym kończącym się na **/p#1/…**.'),
        const HelpBlock.p('Otwórz go, dotykając, skanując, wklejając albo udostępniając go aplikacji. [[Wyślij|Send]] otworzy się od razu wypełnione.'),
        const HelpBlock.p('Zanim cokolwiek wypełni, portfel sprawdza link na tym urządzeniu:'),
        const HelpBlock.ul([
          'podpis usługi,',
          'własny podpis portfela odbiorcy dla jego nazwy,',
          'sieć,',
          'termin ważności,',
          'oraz to, że link nie został utworzony dla kogoś innego.',
        ]),
        const HelpBlock.p('Link, który nie przejdzie sprawdzenia, pokazuje powód i niczego nie wypełnia.'),
        HelpBlock.p('Możesz zmienić kwotę. Wyślij zaznaczy wtedy, że to nie jest żądana kwota. Zapłata wymaga $secret, jak każda płatność.'),
      ],
      id: HelpId.paymentLinks,
    ),
    HelpTopic(
      'start',
      'Wiersz nad Wyślij',
      'Mówi, skąd pochodzi prośba. „Nie z usługi, z którą się sparowano” może być w porządku: zapytaj odbiorcę.',
      [
        const HelpBlock.p('Gdy Wyślij otwiera się z linku płatności, wiersz nad kwotą mówi, skąd pochodzi prośba. Cztery obrazki należą do nazwy odbiorcy: odbiorca widzi te same cztery w usłudze, więc możesz je porównać.'),
        const HelpBlock.ul([
          '**@nazwa · przez** nazwa kontaktu: prośba przyszła przez usługę, z którą sparowano ten portfel.',
          '**Nie z usługi, z którą się sparowano**: płatność nadal może być właściwa. Zapytaj odbiorcę.',
          '**Tę prośbę opłacono** data: już ją zapłacono. **Zapłać ponownie** jest dostępne, jeśli tak chcesz.',
          '**@nazwa dostaje teraz płatności na inny portfel niż w dniu Twojej płatności** data: portfel odbiorcy zmienił się od Twojej ostatniej płatności linkiem. Płać tylko wtedy, gdy odbiorca Cię o tym poinformował.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'start',
      'Kontakty, które nie przyjmują płatności',
      'Niektóre kontakty nie przyjmują płatności.',
      [
        const HelpBlock.p('Niektóre kontakty nie przyjmują płatności. Należy do nich usługa, w której ludzie płacą Ci jako @name. Mówi o tym przy parowaniu.'),
        const HelpBlock.p('W Kontaktach i na liście odbiorców taki kontakt ma przekreśloną monetę; jego strona pokazuje **Bez płatności**. Wklejenie lub zeskanowanie jego adresu w Wyślij jest odrzucane.'),
        const HelpBlock.p('Płatność wysłana do takiego kontaktu z innego portfela nigdy nie zostanie odebrana. Czeka tam, aż nadawca ją anuluje.'),
      ],
      id: HelpId.noPayments,
    ),
    HelpTopic(
      'network',
      'Płać mi jako @name',
      'Usługa, z którą się sparowano, może pozwolić innym płacić Ci jako @name. Portfel nie ma żadnej wbudowanej. Włączenie wysyła usłudze jeden adres zrobiony tylko dla niej.',
      [
        const HelpBlock.p('Niektóre usługi, które ktoś prowadzi, pozwalają płacić sobie nawzajem jako @name przez link płatności. Portfel nie ma żadnej wbudowanej.'),
        const HelpBlock.p('Parowanie z usługą to parowanie kontaktu. Otwórz jego zaproszenie i **Sprawdź kod**: porównaj obrazki widoczne po obu stronach. Potem wybierz **Płać mi jako @name**. Usługa pojawi się w [[Kontakty|Contacts]].'),
        const HelpBlock.p('Włączenie wysyła usłudze adres płatności zrobiony tylko dla niej i podpisany przez ten portfel. Nic więcej: ani salda, ani żadnego innego adresu.'),
        const HelpBlock.p('**Opuść** na stronie kontaktu usługi zdejmuje tam Twoją nazwę. Portfel nadal odbiera na ten adres przez 7 dni, a potem przestaje.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Powiadomienie usługi o wysłanej płatności',
      'Dobrowolne i osobno przy każdej płatności. Usługa widzi krótki identyfikator prośby, kwotę i czas. Nic więcej.',
      [
        const HelpBlock.p('Po zapłaceniu linku niezaznaczony wiersz proponuje powiadomić usługę, że płatność została wysłana. Decydujesz za każdym razem. Portfel nigdy nie robi tego sam.'),
        const HelpBlock.p('Jeśli to zaznaczysz, usługa widzi krótki identyfikator prośby, kwotę i czas. Nie widzi adresu ani identyfikatora transakcji.'),
      ],
      id: HelpId.directoryTell,
    ),
    HelpTopic(
      'trouble',
      'Płatność linkiem, na którą nikt nie odpowiada',
      'Czeka na portfel odbiorcy jak każda płatność przez Epicbox. Po 24 godzinach możesz anulować i wysłać inaczej.',
      [
        const HelpBlock.p('Płatność linkiem czeka na portfel odbiorcy jak każda płatność przez Epicbox. Odbiorca nie musi być teraz online.'),
        const HelpBlock.ul([
          'Po 24 godzinach pokazuje **Jeszcze bez odpowiedzi** z przyciskiem **Anuluj i wyślij przez Epicbox**.',
          'Po 7 dniach serwer Epicbox porzucił płatność. Anuluj ją, aby zwolnić monety.',
        ]),
      ],
      id: HelpId.linkUnanswered,
    ),
  ];
}

List<HelpTopic> _ru(bool phone) {
  final secret = phone ? 'PIN-код или пароль' : 'пароль кошелька';
  return [
    HelpTopic(
      'start',
      'Платёжные ссылки',
      'Платёжная ссылка — это запрос на оплату от сервиса, с которым вы связались. Откройте её, и «Отправить» заполнится. Платёж вы подтверждаете сами.',
      [
        const HelpBlock.p('Платёжная ссылка — это запрос на оплату, созданный сервисом, с которым вы связались: кому платить, сумма (или вы выбираете её сами) и до какого времени запрос действует. Она начинается с **epiccash://pay/1/…** или это веб-ссылка, которая заканчивается на **/p#1/…**.'),
        const HelpBlock.p('Откройте её нажатием, сканированием, вставкой или поделившись ею с приложением. [[Отправить|Send]] откроется уже заполненным.'),
        const HelpBlock.p('Прежде чем что-то заполнить, кошелёк проверяет ссылку на этом устройстве:'),
        const HelpBlock.ul([
          'подпись сервиса,',
          'собственную подпись кошелька получателя для его имени,',
          'сеть,',
          'срок действия,',
          'и то, что ссылка не создана для кого-то другого.',
        ]),
        const HelpBlock.p('Ссылка, не прошедшая проверку, показывает причину и ничего не заполняет.'),
        HelpBlock.p('Сумму можно изменить. Тогда «Отправить» отметит, что это не запрошенная сумма. Для оплаты нужен $secret, как для любого платежа.'),
      ],
      id: HelpId.paymentLinks,
    ),
    HelpTopic(
      'start',
      'Строка над «Отправить»',
      'Она говорит, откуда пришёл запрос. «Не из сервиса, с которым вы связались» тоже может быть верным: спросите получателя.',
      [
        const HelpBlock.p('Когда «Отправить» открывается из платёжной ссылки, строка над суммой говорит, откуда пришёл запрос. Четыре картинки относятся к имени получателя: получатель видит те же четыре в сервисе, и вы можете сравнить.'),
        const HelpBlock.ul([
          '**@имя · через** имя контакта: запрос пришёл через сервис, с которым связан этот кошелёк.',
          '**Не из сервиса, с которым вы связались**: платёж всё равно может быть верным. Спросите получателя.',
          '**Вы оплатили этот запрос** дата: он уже оплачен. **Оплатить снова** доступно, если это нужно.',
          '**@имя теперь получает платежи на другой кошелёк, чем когда вы платили** дата: кошелёк получателя изменился с вашей прошлой оплаты по ссылке. Платите, только если он вам об этом сказал.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'start',
      'Контакты, которые не принимают платежи',
      'Некоторые контакты не принимают платежи.',
      [
        const HelpBlock.p('Некоторые контакты не принимают платежи. Таков сервис, где люди платят вам как @name. Он сообщает об этом при сопряжении.'),
        const HelpBlock.p('В Контактах и в списке получателей такой контакт отмечен перечёркнутой монетой; на его странице написано **Без платежей**. Адрес такого контакта, вставленный или отсканированный в «Отправить», отклоняется.'),
        const HelpBlock.p('Платёж такому контакту из другого кошелька никогда не будет получен. Он остаётся ожидающим, пока отправитель его не отменит.'),
      ],
      id: HelpId.noPayments,
    ),
    HelpTopic(
      'network',
      'Платите мне как @name',
      'Сервис, с которым вы связались, может позволить другим платить вам как @name. В кошельке нет встроенных. При включении сервису отправляется один адрес, созданный только для него.',
      [
        const HelpBlock.p('Некоторые сервисы, которые кто-то ведёт, позволяют платить друг другу как @name через платёжную ссылку. В кошельке нет встроенных сервисов.'),
        const HelpBlock.p('Сопряжение с сервисом — это сопряжение контакта. Откройте его приглашение и **Проверьте код**: сравните картинки, которые показывают обе стороны. Затем выберите **Платите мне как @name**. Сервис появится в [[Контакты|Contacts]].'),
        const HelpBlock.p('При включении сервису отправляется платёжный адрес, созданный только для него и подписанный этим кошельком. Больше ничего: ни баланса, ни других адресов.'),
        const HelpBlock.p('**Выйти** на странице контакта сервиса снимает там ваше имя. Кошелёк ещё 7 дней принимает платежи на этот адрес, потом перестаёт.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Сообщить сервису об отправленном платеже',
      'По желанию и для каждого платежа отдельно. Сервис видит короткий номер запроса, сумму и время. Больше ничего.',
      [
        const HelpBlock.p('После оплаты по ссылке строка без галочки предлагает сообщить сервису, что платёж отправлен. Вы решаете каждый раз. Кошелёк никогда не делает этого сам.'),
        const HelpBlock.p('Если поставить галочку, сервис видит короткий номер запроса, сумму и время. Адрес и идентификатор транзакции он не видит.'),
      ],
      id: HelpId.directoryTell,
    ),
    HelpTopic(
      'trouble',
      'Платёж по ссылке, на который никто не отвечает',
      'Он ждёт кошелёк получателя, как любой платёж через Epicbox. Через 24 часа его можно отменить и отправить иначе.',
      [
        const HelpBlock.p('Платёж по ссылке ждёт кошелёк получателя, как любой платёж через Epicbox. Получателю не нужно быть онлайн прямо сейчас.'),
        const HelpBlock.ul([
          'Через 24 часа он показывает **Пока без ответа** с кнопкой **Отменить и отправить через Epicbox**.',
          'Через 7 дней сервер Epicbox отбросил платёж. Отмените его, чтобы освободить монеты.',
        ]),
      ],
      id: HelpId.linkUnanswered,
    ),
  ];
}

List<HelpTopic> _zh(bool phone) {
  final secret = phone ? '你的 PIN 码或密码短语' : '钱包密码';
  return [
    HelpTopic(
      'start',
      '付款链接',
      '付款链接是你配对过的服务发出的付款请求。打开它，“发送”就会填好。付款仍需你自己确认。',
      [
        const HelpBlock.p('付款链接是你配对过的服务发出的付款请求：向谁付款、金额（或由你自己决定）以及请求何时到期。它以 **epiccash://pay/1/…** 开头，或是以 **/p#1/…** 结尾的网页链接。'),
        const HelpBlock.p('点按、扫描、粘贴或分享给应用都可以打开它。[[发送|Send]]会直接填好。'),
        const HelpBlock.p('在填入任何内容之前，钱包会在本设备上检查链接：'),
        const HelpBlock.ul([
          '服务的签名，',
          '收款方钱包为其名称做的自有签名，',
          '网络，',
          '有效期，',
          '以及链接不是为别人生成的。',
        ]),
        const HelpBlock.p('未通过检查的链接会显示原因，并且不填入任何内容。'),
        HelpBlock.p('你可以修改金额。“发送”随后会注明这不是请求的金额。付款需要$secret，与任何付款一样。'),
      ],
      id: HelpId.paymentLinks,
    ),
    HelpTopic(
      'start',
      '“发送”上方的一行',
      '它说明请求来自哪里。“不是来自你配对过的服务”也可能没问题：请询问收款方。',
      [
        const HelpBlock.p('从付款链接打开“发送”时，金额上方的一行会说明请求来自哪里。四个图案属于收款方的名称：收款方在服务中能看到同样的四个，你可以对比。'),
        const HelpBlock.ul([
          '**@名称 · 经由** 联系人名称：请求来自这个钱包配对过的服务。',
          '**不是来自你配对过的服务**：付款仍可能是对的。请询问收款方。',
          '**你已在某日支付此请求**：你已经付过了。如果确实要再付，可用 **再次付款**。',
          '**@名称现在收款到的钱包，与你在某日付款时不同**：自你上次通过链接向对方付款以来，对方的钱包变了。只有对方告诉过你时才付款。',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'start',
      '不接受付款的联系人',
      '有些联系人不接受付款。',
      [
        const HelpBlock.p('有些联系人不接受付款。让人以你的 @name 向你付款的服务就是其中之一。配对时它会说明。'),
        const HelpBlock.p('在联系人和收款人列表中，这样的联系人带有一枚划掉的硬币；它的页面显示 **不收款**。把它的地址粘贴或扫描到发送中会被拒绝。'),
        const HelpBlock.p('从其他钱包发给这样联系人的付款永远不会被收取。它会一直处于待处理，直到发送方取消。'),
      ],
      id: HelpId.noPayments,
    ),
    HelpTopic(
      'network',
      '以 @name 收款',
      '你配对过的服务可以让别人以你的 @name 向你付款。钱包没有内置服务。开启时只会把一个专为该服务生成的地址发给它。',
      [
        const HelpBlock.p('有些由他人运营的服务，让人们通过付款链接以 @name 互相付款。钱包没有内置任何服务。'),
        const HelpBlock.p('与服务配对属于联系人配对。打开它的邀请并 **核对代码**：比较双方显示的图案。然后选择 **以 @name 收款**。该服务会出现在[[联系人|Contacts]]中。'),
        const HelpBlock.p('开启时，这个钱包会向服务发送一个专为它生成并由本钱包签名的收款地址。除此之外什么都不发：没有余额，也没有其他地址。'),
        const HelpBlock.p('在该服务的联系人页面点 **退出** 会撤下你在那里的名称。钱包会继续接收该地址的付款 7 天，之后停止。'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      '告知服务付款已发出',
      '可选，并且每笔单独决定。服务会看到请求的短编号、金额和时间。仅此而已。',
      [
        const HelpBlock.p('通过链接付款后，一行未勾选的选项可以让你告知服务付款已发出。每次都由你决定，钱包从不自动这样做。'),
        const HelpBlock.p('勾选后，服务会看到请求的短编号、金额和时间。它看不到地址或交易编号。'),
      ],
      id: HelpId.directoryTell,
    ),
    HelpTopic(
      'trouble',
      '无人回应的链接付款',
      '它和任何 Epicbox 付款一样等待收款方的钱包。24 小时后可以取消并改用其他方式发送。',
      [
        const HelpBlock.p('链接付款和任何 Epicbox 付款一样，会等待收款方的钱包。对方不必此刻在线。'),
        const HelpBlock.ul([
          '24 小时后会显示 **尚未应答**，并带有 **取消并经 Epicbox 发送**。',
          '7 天后 Epicbox 服务器已丢弃该付款。取消它即可释放币。',
        ]),
      ],
      id: HelpId.linkUnanswered,
    ),
  ];
}

List<HelpTopic> _th(bool phone) {
  final secret = phone ? 'PIN หรือวลีรหัสผ่าน' : 'รหัสผ่านกระเป๋าเงิน';
  return [
    HelpTopic(
      'start',
      'ลิงก์ชำระเงิน',
      'ลิงก์ชำระเงินคือคำขอชำระเงินที่บริการซึ่งคุณจับคู่ไว้สร้างขึ้น เปิดแล้วหน้าส่งจะถูกกรอกให้ ส่วนการยืนยันการชำระเงินคุณทำเอง',
      [
        const HelpBlock.p('ลิงก์ชำระเงินคือคำขอชำระเงินที่บริการซึ่งคุณจับคู่ไว้สร้างขึ้น ระบุว่าจ่ายให้ใคร จำนวนเท่าใด (หรือคุณเลือกเอง) และคำขอหมดอายุเมื่อใด ลิงก์ขึ้นต้นด้วย **epiccash://pay/1/…** หรือเป็นลิงก์เว็บที่ลงท้ายด้วย **/p#1/…**'),
        const HelpBlock.p('เปิดได้โดยแตะ สแกน วาง หรือแชร์ไปยังแอป [[ส่ง|Send]] จะเปิดขึ้นมาพร้อมข้อมูลที่กรอกไว้แล้ว'),
        const HelpBlock.p('ก่อนกรอกอะไร กระเป๋าเงินจะตรวจลิงก์บนอุปกรณ์นี้:'),
        const HelpBlock.ul([
          'ลายเซ็นของบริการ',
          'ลายเซ็นของกระเป๋าเงินผู้รับเองสำหรับชื่อของเขา',
          'เครือข่าย',
          'วันหมดอายุ',
          'และลิงก์นั้นไม่ได้ทำขึ้นสำหรับคนอื่น',
        ]),
        const HelpBlock.p('ลิงก์ที่ไม่ผ่านการตรวจจะแสดงเหตุผลและไม่กรอกอะไรเลย'),
        HelpBlock.p('คุณเปลี่ยนจำนวนได้ หน้าส่งจะระบุว่าไม่ใช่จำนวนที่ขอ การชำระเงินต้องใช้$secretเหมือนการชำระเงินทั่วไป'),
      ],
      id: HelpId.paymentLinks,
    ),
    HelpTopic(
      'start',
      'บรรทัดเหนือหน้าส่ง',
      'บอกว่าคำขอมาจากที่ใด “ไม่ได้มาจากบริการที่คุณจับคู่ไว้” อาจยังถูกต้องได้ ให้ถามผู้รับ',
      [
        const HelpBlock.p('เมื่อหน้าส่งเปิดจากลิงก์ชำระเงิน บรรทัดเหนือจำนวนเงินจะบอกว่าคำขอมาจากที่ใด รูปภาพสี่รูปเป็นของชื่อผู้รับ ผู้รับเห็นสี่รูปเดียวกันในบริการ คุณจึงเทียบกันได้'),
        const HelpBlock.ul([
          '**@ชื่อ · ผ่าน** ชื่อผู้ติดต่อ คำขอมาจากบริการที่กระเป๋าเงินนี้จับคู่ไว้',
          '**ไม่ได้มาจากบริการที่คุณจับคู่ไว้** การชำระเงินอาจยังถูกต้องได้ ให้ถามผู้รับ',
          '**คุณชำระคำขอนี้แล้วเมื่อ** วันที่ คุณจ่ายไปแล้ว มี **จ่ายอีกครั้ง** ให้ถ้าคุณตั้งใจจะจ่ายอีก',
          '**@ชื่อ ตอนนี้รับเงินเข้ากระเป๋าเงินอื่น ต่างจากตอนที่คุณจ่ายเมื่อ** วันที่ กระเป๋าเงินของผู้รับเปลี่ยนไปหลังจากที่คุณจ่ายให้ด้วยลิงก์ครั้งล่าสุด ให้จ่ายเมื่อผู้รับบอกคุณเท่านั้น',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'start',
      'ผู้ติดต่อที่ไม่รับการจ่ายเงิน',
      'ผู้ติดต่อบางรายไม่รับการจ่ายเงิน',
      [
        const HelpBlock.p('ผู้ติดต่อบางรายไม่รับการจ่ายเงิน บริการที่คนจ่ายเงินให้คุณในชื่อ @name เป็นหนึ่งในนั้น บริการจะบอกตอนจับคู่'),
        const HelpBlock.p('ในผู้ติดต่อและในรายชื่อผู้รับ ผู้ติดต่อแบบนี้มีเหรียญที่ขีดฆ่า หน้าของผู้ติดต่อแสดง **ไม่รับเงิน** การวางหรือสแกนที่อยู่ของผู้ติดต่อนี้ในส่งเงินจะถูกปฏิเสธ'),
        const HelpBlock.p('การจ่ายเงินจากกระเป๋าเงินอื่นให้ผู้ติดต่อแบบนี้จะไม่ถูกรับ ค้างอยู่จนกว่าผู้ส่งจะยกเลิก'),
      ],
      id: HelpId.noPayments,
    ),
    HelpTopic(
      'network',
      'รับเงินในชื่อ @name',
      'บริการที่คุณจับคู่ไว้ให้คนอื่นจ่ายเงินให้คุณในชื่อ @name ได้ กระเป๋าเงินไม่มีบริการในตัว เมื่อเปิดใช้ จะส่งที่อยู่หนึ่งที่อยู่ที่สร้างเฉพาะสำหรับบริการนั้น',
      [
        const HelpBlock.p('บริการบางแห่งที่มีผู้ดูแลให้คนจ่ายเงินให้กันในชื่อ @name ผ่านลิงก์ชำระเงิน กระเป๋าเงินไม่มีบริการในตัว'),
        const HelpBlock.p('การจับคู่กับบริการเป็นการจับคู่ผู้ติดต่อ เปิดคำเชิญของบริการแล้ว **ตรวจรหัส** เทียบรูปภาพที่ทั้งสองฝั่งแสดง จากนั้นเลือก **รับเงินในชื่อ @name** บริการจะอยู่ใน [[ผู้ติดต่อ|Contacts]]'),
        const HelpBlock.p('เมื่อเปิดใช้ กระเป๋าเงินนี้จะส่งที่อยู่รับเงินที่สร้างเฉพาะสำหรับบริการนั้นและลงนามโดยกระเป๋าเงินนี้ ไม่ส่งอย่างอื่นเลย ไม่มียอดคงเหลือและไม่มีที่อยู่อื่น'),
        const HelpBlock.p('**ออก** บนหน้าผู้ติดต่อของบริการจะถอนชื่อของคุณออกจากที่นั่น กระเป๋าเงินยังรับเงินเข้าที่อยู่นั้นต่อไปอีก 7 วัน แล้วจึงหยุด'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'แจ้งบริการว่าส่งเงินแล้ว',
      'ไม่บังคับ และเลือกทีละรายการ บริการเห็นรหัสสั้นของคำขอ จำนวนเงิน และเวลา ไม่เห็นอย่างอื่น',
      [
        const HelpBlock.p('หลังจากจ่ายด้วยลิงก์ จะมีบรรทัดที่ยังไม่ได้ติ๊กให้เลือกแจ้งบริการว่าส่งเงินแล้ว คุณตัดสินใจทุกครั้ง กระเป๋าเงินไม่เคยทำเองโดยอัตโนมัติ'),
        const HelpBlock.p('ถ้าติ๊ก บริการจะเห็นรหัสสั้นของคำขอ จำนวนเงิน และเวลา ไม่เห็นที่อยู่หรือรหัสธุรกรรม'),
      ],
      id: HelpId.directoryTell,
    ),
    HelpTopic(
      'trouble',
      'การจ่ายด้วยลิงก์ที่ไม่มีใครตอบ',
      'จะรอกระเป๋าเงินของผู้รับเหมือนการจ่ายผ่าน Epicbox ทั่วไป หลัง 24 ชั่วโมงคุณยกเลิกแล้วส่งด้วยวิธีอื่นได้',
      [
        const HelpBlock.p('การจ่ายด้วยลิงก์จะรอกระเป๋าเงินของผู้รับเหมือนการจ่ายผ่าน Epicbox ทั่วไป ผู้รับไม่จำเป็นต้องออนไลน์ในตอนนี้'),
        const HelpBlock.ul([
          'หลัง 24 ชั่วโมง จะแสดง **ยังไม่มีการตอบ** พร้อม **ยกเลิกและส่งผ่าน Epicbox**',
          'เมื่อครบ 7 วัน เซิร์ฟเวอร์ Epicbox ทิ้งการจ่ายนี้แล้ว ให้ยกเลิกเพื่อปล่อยเหรียญ',
        ]),
      ],
      id: HelpId.linkUnanswered,
    ),
  ];
}
