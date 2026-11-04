// SPDX-License-Identifier: Apache-2.0
/// Help on payment links and directories, for the phone and the desktop, in the app's six
/// languages: what a payment link is and how the wallet checks it, the line above Send, joining a
/// directory, telling the directory a payment is sent, and a link payment nobody answers. Each
/// language's topic list (help_content.dart, help_`<lang>`.dart) ends with these; they show
/// always, as the wallet joins a directory by pairing and a link can arrive at any time.
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
      'A payment link is a request to pay, made by a directory. Open it and Send is filled in. You still confirm the payment yourself.',
      [
        const HelpBlock.p('A payment link is a payment request made by a directory: who to pay, the amount (or you choose it) and when the request expires. It starts with **epiccash://pay/1/…** or is a web link that ends in **/p#1/…**.'),
        const HelpBlock.p('Open one by tapping it, scanning it, pasting it or sharing it to the app. [[Send]] opens already filled in.'),
        const HelpBlock.p('Before it fills anything, the wallet checks the link on this device:'),
        const HelpBlock.ul([
          'the directory’s signature,',
          'the payee wallet’s own signature on its listing,',
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
      'It says where the request came from. “Not from a directory you use” can still be right: ask the payee.',
      [
        const HelpBlock.p('When Send opens from a payment link, a line above the amount says where the request came from. The four pictures are the listing code: the payee can read theirs on the directory, so you can compare them.'),
        const HelpBlock.ul([
          '**@name · listed by directory**: the directory is one this wallet joined or checked.',
          '**Not from a directory you use**: the payment can still be right. Ask the payee.',
          '**You paid this request on** a date: you already paid it. **Pay again** is there if you mean to.',
          '**This listing now points to a different wallet…**: the payee’s wallet changed since you last paid them by link. Pay only if they told you.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'network',
      'Directories and joining one',
      'A directory lets its users pay each other by link. The wallet has none built in. Joining sends it one address made only for it.',
      [
        const HelpBlock.p('A directory is a service someone runs that lets its users pay each other by a payment link. The wallet has none built in.'),
        const HelpBlock.p('Pairing with one is a contact pairing. Open its invite and **Check the code**: compare the pictures shown by both. Then choose **Join**. It appears in [[Contacts]].'),
        const HelpBlock.p('Joining sends the directory a payment address made only for it, signed by this wallet. Nothing else: no balance and no other address.'),
        const HelpBlock.p('**Leave** on the directory’s contact page takes your listing down. The wallet keeps receiving to that address for 7 days, then stops.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Telling the directory a payment is sent',
      'Optional, and per payment. The directory sees the request’s short id, the amount and the time. Nothing else.',
      [
        const HelpBlock.p('After you pay a link, an unticked line offers to tell the directory the payment is sent. It is your choice each time. The wallet never does it by itself.'),
        const HelpBlock.p('If you tick it, the directory sees the request’s short id, the amount and the time. It does not see an address or a transaction id.'),
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
      'Ein Zahlungslink ist eine Zahlungsaufforderung eines Verzeichnisses. Öffnen Sie ihn, und Senden ist ausgefüllt. Die Zahlung bestätigen Sie weiterhin selbst.',
      [
        const HelpBlock.p('Ein Zahlungslink ist eine Zahlungsaufforderung, die ein Verzeichnis erstellt hat: wer bezahlt wird, der Betrag (oder Sie wählen ihn) und wann die Aufforderung abläuft. Er beginnt mit **epiccash://pay/1/…** oder ist ein Weblink, der auf **/p#1/…** endet.'),
        const HelpBlock.p('Öffnen Sie ihn per Tippen, Scannen, Einfügen oder indem Sie ihn mit der App teilen. [[Senden|Send]] öffnet sich dann schon ausgefüllt.'),
        const HelpBlock.p('Bevor etwas ausgefüllt wird, prüft die Wallet den Link auf diesem Gerät:'),
        const HelpBlock.ul([
          'die Signatur des Verzeichnisses,',
          'die eigene Signatur der Empfänger-Wallet auf ihrem Eintrag,',
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
      'Sie sagt, woher die Aufforderung kommt. „Nicht von einem Verzeichnis, das Sie nutzen“ kann trotzdem stimmen: Fragen Sie den Empfänger.',
      [
        const HelpBlock.p('Wenn Senden aus einem Zahlungslink geöffnet wird, sagt eine Zeile über dem Betrag, woher die Aufforderung kommt. Die vier Bilder sind der Eintragscode: Der Empfänger kann seinen im Verzeichnis ablesen, so können Sie vergleichen.'),
        const HelpBlock.ul([
          '**@name · eingetragen bei Verzeichnis**: Das Verzeichnis ist eines, dem diese Wallet beigetreten ist oder das sie geprüft hat.',
          '**Nicht von einem Verzeichnis, das Sie nutzen**: Die Zahlung kann trotzdem richtig sein. Fragen Sie den Empfänger.',
          '**Sie haben diese Aufforderung bezahlt am** Datum: Sie haben sie schon bezahlt. **Erneut bezahlen** steht bereit, falls Sie es wollen.',
          '**Dieser Eintrag verweist jetzt auf eine andere Wallet…**: Die Wallet des Empfängers hat sich geändert, seit Sie ihn zuletzt per Link bezahlt haben. Zahlen Sie nur, wenn er es Ihnen gesagt hat.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'network',
      'Verzeichnisse und der Beitritt',
      'Ein Verzeichnis lässt seine Nutzer sich per Link bezahlen. Die Wallet hat keines eingebaut. Der Beitritt sendet ihm eine Adresse, die nur für es gemacht ist.',
      [
        const HelpBlock.p('Ein Verzeichnis ist ein Dienst, den jemand betreibt und über den sich seine Nutzer per Zahlungslink bezahlen können. Die Wallet hat keines eingebaut.'),
        const HelpBlock.p('Die Kopplung mit einem Verzeichnis ist eine Kontaktkopplung. Öffnen Sie seine Einladung und wählen Sie **Code prüfen**: Vergleichen Sie die Bilder, die beide zeigen. Wählen Sie dann **Beitreten**. Es erscheint unter [[Kontakte|Contacts]].'),
        const HelpBlock.p('Beim Beitritt sendet diese Wallet dem Verzeichnis eine Zahlungsadresse, die nur für es gemacht und von der Wallet signiert ist. Sonst nichts: kein Guthaben und keine andere Adresse.'),
        const HelpBlock.p('**Verlassen** auf der Kontaktseite des Verzeichnisses nimmt Ihren Eintrag heraus. Die Wallet empfängt an dieser Adresse noch 7 Tage lang weiter und hört dann auf.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Dem Verzeichnis eine Zahlung melden',
      'Freiwillig und pro Zahlung. Das Verzeichnis sieht die Kurz-ID der Aufforderung, den Betrag und die Zeit. Sonst nichts.',
      [
        const HelpBlock.p('Nachdem Sie einen Link bezahlt haben, bietet eine nicht angehakte Zeile an, dem Verzeichnis die Zahlung zu melden. Das entscheiden Sie jedes Mal neu. Die Wallet tut es nie von selbst.'),
        const HelpBlock.p('Wenn Sie es ankreuzen, sieht das Verzeichnis die Kurz-ID der Aufforderung, den Betrag und die Zeit. Eine Adresse oder eine Transaktions-ID sieht es nicht.'),
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
          'Nach 24 Stunden zeigt sie **Noch nicht beantwortet**, mit **Abbrechen und per Epicbox senden**.',
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
      'Link płatności to prośba o zapłatę, którą tworzy katalog. Otwórz go, a Wyślij będzie wypełnione. Płatność nadal potwierdzasz sam.',
      [
        const HelpBlock.p('Link płatności to prośba o zapłatę utworzona przez katalog: komu zapłacić, kwota (albo wybierasz ją sam) i kiedy prośba wygasa. Zaczyna się od **epiccash://pay/1/…** albo jest linkiem internetowym kończącym się na **/p#1/…**.'),
        const HelpBlock.p('Otwórz go, dotykając, skanując, wklejając albo udostępniając go aplikacji. [[Wyślij|Send]] otworzy się od razu wypełnione.'),
        const HelpBlock.p('Zanim cokolwiek wypełni, portfel sprawdza link na tym urządzeniu:'),
        const HelpBlock.ul([
          'podpis katalogu,',
          'własny podpis portfela odbiorcy na jego wpisie,',
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
      'Mówi, skąd pochodzi prośba. „Nie z katalogu, z którego korzystasz” może być w porządku: zapytaj odbiorcę.',
      [
        const HelpBlock.p('Gdy Wyślij otwiera się z linku płatności, wiersz nad kwotą mówi, skąd pochodzi prośba. Cztery obrazki to kod wpisu: odbiorca może odczytać swój w katalogu, więc możesz je porównać.'),
        const HelpBlock.ul([
          '**@nazwa · w katalogu katalog**: to katalog, do którego ten portfel dołączył albo który sprawdził.',
          '**Nie z katalogu, z którego korzystasz**: płatność nadal może być właściwa. Zapytaj odbiorcę.',
          '**Ta prośba została zapłacona dnia** data: już ją zapłacono. **Zapłać ponownie** jest dostępne, jeśli tak chcesz.',
          '**Ten wpis wskazuje teraz inny portfel…**: portfel odbiorcy zmienił się od Twojej ostatniej płatności linkiem. Płać tylko wtedy, gdy odbiorca Cię o tym poinformował.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'network',
      'Katalogi i dołączanie do nich',
      'Katalog pozwala swoim użytkownikom płacić sobie linkiem. Portfel nie ma żadnego wbudowanego. Dołączenie wysyła mu jeden adres zrobiony tylko dla niego.',
      [
        const HelpBlock.p('Katalog to usługa, którą ktoś prowadzi i która pozwala jej użytkownikom płacić sobie nawzajem linkiem płatności. Portfel nie ma żadnego wbudowanego.'),
        const HelpBlock.p('Parowanie z katalogiem to parowanie kontaktu. Otwórz jego zaproszenie i **Sprawdź kod**: porównaj obrazki widoczne po obu stronach. Potem wybierz **Dołącz**. Katalog pojawi się w [[Kontakty|Contacts]].'),
        const HelpBlock.p('Dołączenie wysyła katalogowi adres płatności zrobiony tylko dla niego i podpisany przez ten portfel. Nic więcej: ani salda, ani żadnego innego adresu.'),
        const HelpBlock.p('**Opuść** na stronie kontaktu katalogu zdejmuje Twój wpis. Portfel nadal odbiera na ten adres przez 7 dni, a potem przestaje.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Powiadomienie katalogu o wysłanej płatności',
      'Dobrowolne i osobno przy każdej płatności. Katalog widzi krótki identyfikator prośby, kwotę i czas. Nic więcej.',
      [
        const HelpBlock.p('Po zapłaceniu linku niezaznaczony wiersz proponuje powiadomić katalog, że płatność została wysłana. Decydujesz za każdym razem. Portfel nigdy nie robi tego sam.'),
        const HelpBlock.p('Jeśli to zaznaczysz, katalog widzi krótki identyfikator prośby, kwotę i czas. Nie widzi adresu ani identyfikatora transakcji.'),
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
      'Платёжная ссылка — это запрос на оплату от каталога. Откройте её, и «Отправить» заполнится. Платёж вы подтверждаете сами.',
      [
        const HelpBlock.p('Платёжная ссылка — это запрос на оплату, созданный каталогом: кому платить, сумма (или вы выбираете её сами) и до какого времени запрос действует. Она начинается с **epiccash://pay/1/…** или это веб-ссылка, которая заканчивается на **/p#1/…**.'),
        const HelpBlock.p('Откройте её нажатием, сканированием, вставкой или поделившись ею с приложением. [[Отправить|Send]] откроется уже заполненным.'),
        const HelpBlock.p('Прежде чем что-то заполнить, кошелёк проверяет ссылку на этом устройстве:'),
        const HelpBlock.ul([
          'подпись каталога,',
          'собственную подпись кошелька получателя на его записи,',
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
      'Она говорит, откуда пришёл запрос. «Не из каталога, которым вы пользуетесь» тоже может быть верным: спросите получателя.',
      [
        const HelpBlock.p('Когда «Отправить» открывается из платёжной ссылки, строка над суммой говорит, откуда пришёл запрос. Четыре картинки — это код записи: получатель может прочитать свой в каталоге, и вы можете сравнить.'),
        const HelpBlock.ul([
          '**@имя · в каталоге каталог**: каталог, к которому этот кошелёк присоединился или который проверил.',
          '**Не из каталога, которым вы пользуетесь**: платёж всё равно может быть верным. Спросите получателя.',
          '**Вы оплатили этот запрос** дата: он уже оплачен. **Заплатить снова** доступно, если это нужно.',
          '**Эта запись теперь указывает на другой кошелёк…**: кошелёк получателя изменился с вашей прошлой оплаты по ссылке. Платите, только если он вам об этом сказал.',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'network',
      'Каталоги и вступление в каталог',
      'Каталог позволяет его пользователям платить друг другу по ссылке. В кошельке нет встроенных. При вступлении ему отправляется один адрес, созданный только для него.',
      [
        const HelpBlock.p('Каталог — это сервис, который кто-то ведёт и который позволяет его пользователям платить друг другу по платёжной ссылке. В кошельке нет встроенных каталогов.'),
        const HelpBlock.p('Сопряжение с каталогом — это сопряжение контакта. Откройте его приглашение и **Проверьте код**: сравните картинки, которые показывают обе стороны. Затем выберите **Вступить**. Каталог появится в [[Контакты|Contacts]].'),
        const HelpBlock.p('При вступлении каталогу отправляется платёжный адрес, созданный только для него и подписанный этим кошельком. Больше ничего: ни баланса, ни других адресов.'),
        const HelpBlock.p('**Покинуть** на странице контакта каталога снимает вашу запись. Кошелёк ещё 7 дней принимает платежи на этот адрес, потом перестаёт.'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'Сообщить каталогу об отправленном платеже',
      'По желанию и для каждого платежа отдельно. Каталог видит короткий номер запроса, сумму и время. Больше ничего.',
      [
        const HelpBlock.p('После оплаты по ссылке строка без галочки предлагает сообщить каталогу, что платёж отправлен. Вы решаете каждый раз. Кошелёк никогда не делает этого сам.'),
        const HelpBlock.p('Если поставить галочку, каталог видит короткий номер запроса, сумму и время. Адрес и идентификатор транзакции он не видит.'),
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
          'Через 24 часа он показывает **Ответа пока нет** с кнопкой **Отменить и отправить через Epicbox**.',
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
      '付款链接是目录发出的付款请求。打开它，“发送”就会填好。付款仍需你自己确认。',
      [
        const HelpBlock.p('付款链接是目录发出的付款请求：向谁付款、金额（或由你自己决定）以及请求何时到期。它以 **epiccash://pay/1/…** 开头，或是以 **/p#1/…** 结尾的网页链接。'),
        const HelpBlock.p('点按、扫描、粘贴或分享给应用都可以打开它。[[发送|Send]]会直接填好。'),
        const HelpBlock.p('在填入任何内容之前，钱包会在本设备上检查链接：'),
        const HelpBlock.ul([
          '目录的签名，',
          '收款方钱包在其条目上的自有签名，',
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
      '它说明请求来自哪里。“不是来自你使用的目录”也可能没问题：请询问收款方。',
      [
        const HelpBlock.p('从付款链接打开“发送”时，金额上方的一行会说明请求来自哪里。四个图案是条目码：收款方可以在目录上读到自己的，你可以对比。'),
        const HelpBlock.ul([
          '**@名称 · 由目录列出**：该目录是这个钱包已加入或检查过的。',
          '**不是来自你使用的目录**：付款仍可能是对的。请询问收款方。',
          '**你已在某日支付过此请求**：你已经付过了。如果确实要再付，可用 **再付一次**。',
          '**此条目现在指向另一个钱包……**：自你上次通过链接向对方付款以来，对方的钱包变了。只有对方告诉过你时才付款。',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'network',
      '目录与加入目录',
      '目录让其用户通过链接互相付款。钱包没有内置目录。加入时只会把一个专为它生成的地址发给它。',
      [
        const HelpBlock.p('目录是由某人运营的服务，让其用户通过付款链接互相付款。钱包没有内置任何目录。'),
        const HelpBlock.p('与目录配对属于联系人配对。打开它的邀请并 **核对代码**：比较双方显示的图案。然后选择 **加入**。它会出现在[[联系人|Contacts]]中。'),
        const HelpBlock.p('加入时，这个钱包会向目录发送一个专为它生成并由本钱包签名的收款地址。除此之外什么都不发：没有余额，也没有其他地址。'),
        const HelpBlock.p('在目录的联系人页面点 **退出** 会撤下你的条目。钱包会继续接收该地址的付款 7 天，之后停止。'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      '告知目录付款已发出',
      '可选，并且每笔单独决定。目录会看到请求的短编号、金额和时间。仅此而已。',
      [
        const HelpBlock.p('通过链接付款后，一行未勾选的选项可以让你告知目录付款已发出。每次都由你决定，钱包从不自动这样做。'),
        const HelpBlock.p('勾选后，目录会看到请求的短编号、金额和时间。它看不到地址或交易编号。'),
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
          '24 小时后会显示 **尚无回应**，并带有 **取消并通过 Epicbox 发送**。',
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
      'ลิงก์ชำระเงินคือคำขอชำระเงินที่ไดเรกทอรีสร้างขึ้น เปิดแล้วหน้าส่งจะถูกกรอกให้ ส่วนการยืนยันการชำระเงินคุณทำเอง',
      [
        const HelpBlock.p('ลิงก์ชำระเงินคือคำขอชำระเงินที่ไดเรกทอรีสร้างขึ้น ระบุว่าจ่ายให้ใคร จำนวนเท่าใด (หรือคุณเลือกเอง) และคำขอหมดอายุเมื่อใด ลิงก์ขึ้นต้นด้วย **epiccash://pay/1/…** หรือเป็นลิงก์เว็บที่ลงท้ายด้วย **/p#1/…**'),
        const HelpBlock.p('เปิดได้โดยแตะ สแกน วาง หรือแชร์ไปยังแอป [[ส่ง|Send]] จะเปิดขึ้นมาพร้อมข้อมูลที่กรอกไว้แล้ว'),
        const HelpBlock.p('ก่อนกรอกอะไร กระเป๋าเงินจะตรวจลิงก์บนอุปกรณ์นี้:'),
        const HelpBlock.ul([
          'ลายเซ็นของไดเรกทอรี',
          'ลายเซ็นของกระเป๋าเงินผู้รับเองบนรายการของมัน',
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
      'บอกว่าคำขอมาจากที่ใด “ไม่ได้มาจากไดเรกทอรีที่คุณใช้” อาจยังถูกต้องได้ ให้ถามผู้รับ',
      [
        const HelpBlock.p('เมื่อหน้าส่งเปิดจากลิงก์ชำระเงิน บรรทัดเหนือจำนวนเงินจะบอกว่าคำขอมาจากที่ใด รูปภาพสี่รูปคือรหัสของรายการ ผู้รับอ่านรหัสของตนได้บนไดเรกทอรี คุณจึงเทียบกันได้'),
        const HelpBlock.ul([
          '**@ชื่อ · ลงรายการโดยไดเรกทอรี** ไดเรกทอรีนี้เป็นแห่งที่กระเป๋าเงินนี้เข้าร่วมหรือตรวจสอบแล้ว',
          '**ไม่ได้มาจากไดเรกทอรีที่คุณใช้** การชำระเงินอาจยังถูกต้องได้ ให้ถามผู้รับ',
          '**คุณชำระคำขอนี้แล้วเมื่อ** วันที่ คุณจ่ายไปแล้ว มี **จ่ายอีกครั้ง** ให้ถ้าคุณตั้งใจจะจ่ายอีก',
          '**รายการนี้ชี้ไปยังกระเป๋าเงินอื่นแล้ว…** กระเป๋าเงินของผู้รับเปลี่ยนไปหลังจากที่คุณจ่ายให้ด้วยลิงก์ครั้งล่าสุด ให้จ่ายเมื่อผู้รับบอกคุณเท่านั้น',
        ]),
      ],
      id: HelpId.linkLine,
    ),
    HelpTopic(
      'network',
      'ไดเรกทอรีและการเข้าร่วม',
      'ไดเรกทอรีให้ผู้ใช้จ่ายเงินให้กันด้วยลิงก์ กระเป๋าเงินไม่มีไดเรกทอรีในตัว การเข้าร่วมจะส่งที่อยู่หนึ่งที่อยู่ที่สร้างเฉพาะสำหรับไดเรกทอรีนั้น',
      [
        const HelpBlock.p('ไดเรกทอรีคือบริการที่มีผู้ดูแล ให้ผู้ใช้จ่ายเงินให้กันด้วยลิงก์ชำระเงิน กระเป๋าเงินไม่มีไดเรกทอรีในตัว'),
        const HelpBlock.p('การจับคู่กับไดเรกทอรีเป็นการจับคู่ผู้ติดต่อ เปิดคำเชิญของไดเรกทอรีแล้ว **ตรวจรหัส** เทียบรูปภาพที่ทั้งสองฝั่งแสดง จากนั้นเลือก **เข้าร่วม** ไดเรกทอรีจะอยู่ใน [[ผู้ติดต่อ|Contacts]]'),
        const HelpBlock.p('เมื่อเข้าร่วม กระเป๋าเงินนี้จะส่งที่อยู่รับเงินที่สร้างเฉพาะสำหรับไดเรกทอรีนั้นและลงนามโดยกระเป๋าเงินนี้ ไม่ส่งอย่างอื่นเลย ไม่มียอดคงเหลือและไม่มีที่อยู่อื่น'),
        const HelpBlock.p('**ออก** บนหน้าผู้ติดต่อของไดเรกทอรีจะถอนรายการของคุณออก กระเป๋าเงินยังรับเงินเข้าที่อยู่นั้นต่อไปอีก 7 วัน แล้วจึงหยุด'),
      ],
      id: HelpId.directories,
    ),
    HelpTopic(
      'network',
      'แจ้งไดเรกทอรีว่าส่งเงินแล้ว',
      'ไม่บังคับ และเลือกทีละรายการ ไดเรกทอรีเห็นรหัสสั้นของคำขอ จำนวนเงิน และเวลา ไม่เห็นอย่างอื่น',
      [
        const HelpBlock.p('หลังจากจ่ายด้วยลิงก์ จะมีบรรทัดที่ยังไม่ได้ติ๊กให้เลือกแจ้งไดเรกทอรีว่าส่งเงินแล้ว คุณตัดสินใจทุกครั้ง กระเป๋าเงินไม่เคยทำเองโดยอัตโนมัติ'),
        const HelpBlock.p('ถ้าติ๊ก ไดเรกทอรีจะเห็นรหัสสั้นของคำขอ จำนวนเงิน และเวลา ไม่เห็นที่อยู่หรือรหัสธุรกรรม'),
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
