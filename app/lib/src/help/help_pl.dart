/// Polish help: the topics and sections of help_content.dart in Polish, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';
import 'help_devices.dart';

const List<HelpSection> helpSectionsPl = [
  (id: 'start', title: 'Pierwsze kroki', lede: 'Odbieranie, wysyłanie i sposób z plikiem.', art: 'help-start'),
  (id: 'how', title: 'Jak działa Epic Cash', lede: 'Udział obu portfeli; potwierdzenia, prywatność, reszta i opłaty.', art: 'help-how'),
  (id: 'safety', title: 'Bezpieczeństwo portfela', lede: 'Fraza odzyskiwania to kopia zapasowa i klucz.', art: 'help-safety'),
  (id: 'network', title: 'Węzły i Epicbox', lede: 'Z czym łączy się portfel, oraz Tor.', art: 'help-network'),
  (id: 'trouble', title: 'Gdy coś nie działa', lede: 'Typowe przyczyny i co zrobić.', art: 'help-trouble'),
  (id: 'maintenance', title: 'Konserwacja', lede: 'Stare foldery portfeli i foldery wcześniejszych wersji.', art: 'help-maintenance'),
];

List<HelpTopic> helpTopicsPl(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'tym telefonie' : 'tym komputerze';
  final secret = phone ? 'swój PIN' : 'hasło portfela';
  final nodePlace = phone ? '[[Ustawienia › Prywatność i sieć › Węzeł|Settings › Privacy & network › Node]]' : '[[Ustawienia › Węzeł|Settings › Node]]';
  final epicboxPlace = phone ? '[[Ustawienia › Prywatność i sieć › Epicbox|Settings › Privacy & network › Epicbox]]' : '[[Ustawienia › Transakcje › Epicbox|Settings › Transactions › Epicbox]]';
  final torPlace = phone ? '[[Ustawienia › Prywatność i sieć › Sieć Tor|Settings › Privacy & network › Tor network]]' : '[[Ustawienia › Prywatność › Tor|Settings › Privacy › Tor]]';
  final cancelPlace = phone
      ? '[[Aktywność|Activity]] (otwórz płatność, potem „Anuluj płatność”)'
      : '[[Aktywność › transakcja › Anuluj|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[Ustawienia › Portfel › Eksportuj dane portfela|Settings › Wallet › Export wallet data]]'
      : '[[Ustawienia › Ten portfel › Eksportuj dane portfela|Settings › This wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**Przywróć z frazy** (na pierwszym ekranie lub w [[Ustawienia › Portfel|Settings › Wallet]])'
      : '**Przywróć z frazy** (na pierwszym ekranie, w Odblokuj › Dodaj portfel lub w [[Ustawienia › Wszystkie portfele|Settings › All wallets]])';
  final recheckPlace = phone ? '[[Ustawienia › Portfel › Sprawdź saldo|Settings › Wallet › Recheck balance]]' : '[[Ustawienia › Sprawdź saldo|Settings › Recheck balance]]';
  final phrasePlace = phone ? '[[Ustawienia › Bezpieczeństwo › Zabezpiecz frazę odzyskiwania|Settings › Security › Back up recovery phrase]]' : '[[Ustawienia › Fraza odzyskiwania|Settings › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Odbierz pierwsze EPIC',
      'Otwórz Odbierz, skopiuj adres Epicbox i przekaż go nadawcy. Płatność dotrze sama.',
      [
        const HelpBlock.p('Adres Epicbox to długi kod, który kończy się znakiem **@** i nazwą serwera Epicbox, na przykład **…@epicbox.epiccash.com**. Można go bezpiecznie udostępniać: inni potrzebują go, aby zapłacić, i nikt nie może nim nic zabrać.'),
        const HelpBlock.ol(['Otwórz [[Odbierz|Receive]].', 'Skopiuj adres (lub pokaż jego kod QR) i wyślij go osobie, która płaci.', 'Płatność sama pojawi się w Aktywności. Nie trzeba nic naciskać.']),
        if (phone)
          const HelpBlock.p('Odbieranie działa, gdy aplikacja jest otwarta, a węzeł zsynchronizowany. Płatność wysłana przy zamkniętej aplikacji czeka na serwerze Epicbox około tygodnia i dociera po następnym odblokowaniu.')
        else
          const HelpBlock.p('Odbieranie włącza się samo po odblokowaniu, gdy węzeł jest zsynchronizowany. Jeśli portfel jest zamknięty, gdy ktoś płaci, Epicbox przechowuje płatność, a portfel odbiera ją po następnym odblokowaniu.'),
        HelpBlock.p('Nowa płatność najpierw czeka, aż portfel nadawcy ją zakończy, a potem ma stan „Potwierdzanie”. Po osiągnięciu wymaganej liczby potwierdzeń ($confirmations, około $confirmations min) można ją wydać.'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      'Wyślij komuś',
      'Otwórz Wyślij, wklej adres Epicbox odbiorcy, wpisz kwotę, sprawdź opłatę i wyślij.',
      [
        const HelpBlock.ol(['Otwórz [[Wyślij|Send]] i wklej adres odbiorcy lub wybierz kontakt.', 'Wpisz kwotę. Opłata jest widoczna przed wysłaniem.', 'Naciśnij **Sprawdź wysyłkę**, sprawdź dane, potem **Wyślij … EPIC**.']),
        const HelpBlock.p('Teraz musi odpowiedzieć portfel odbiorcy (zobacz „Dlaczego transakcja wymaga obu stron?”). Przez Epicbox odbiorca nie musi być teraz online: płatność poczeka, aż jego portfel się otworzy. W tym czasie użyte wyjścia są zablokowane, więc nie da się ich wydać dwa razy.'),
        HelpBlock.p('Gdy odpowiedź wróci, portfel sam zakończy transakcję i wyśle ją do sieci. Staje się ostateczna po osiągnięciu wymaganej liczby potwierdzeń ($confirmations).'),
        HelpBlock.p('**Brak odpowiedzi?** Po kilku minutach stan zmienia się na „Czeka na odbiorcę”. Poproś odbiorcę, by otworzył portfel. Jeśli odpowiedź nigdy nie przyjdzie, anuluj płatność w $cancelPlace, aby odblokować wyjścia. Płatność, na którą nikt nie odpowie, anuluje się sama po około jednym dniu.'),
        if (phone)
          HelpBlock.p('Wysyłanie wymaga zsynchronizowanego węzła. Adres Epicbox wymaga też odpowiadającego serwera Epicbox; adres bezpośredni (${tor ? 'http lub .onion' : 'http'}) wymaga, by portfel odbiorcy był w tej chwili otwarty i osiągalny.')
        else
          HelpBlock.p('Wysyłanie wymaga zsynchronizowanego węzła. Adres Epicbox wymaga też włączonego odbierania przez Epicbox; adres Link (${tor ? 'http lub .onion' : 'http'}) wymaga, by portfel odbiorcy był w tej chwili otwarty i osiągalny.'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      'Wyślij plikiem',
      'Sposób ręczny: zapisz plik transakcji, przekaż go odbiorcy, a potem otwórz plik odpowiedzi, który odeśle.',
      [
        const HelpBlock.p('Przesyłanie pliku to ten sam uścisk dłoni co przez Epicbox, tylko wiadomości przekazujesz ręcznie, na przykład e-mailem, na czacie lub na pendrivie. Działa to bez Epicbox i bez tego, by oba portfele były online w tym samym czasie.'),
        if (phone)
          const HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Bezpośrednio · Przesyłanie pliku**, wpisuje kwotę i udostępnia plik (kończy się na .tx). Od teraz wyjścia są zablokowane.', '**Odbiorca:** otwiera plik w [[Odbierz › Bezpośrednio · Plik|Receive › Direct · File]]. Jego portfel podpisuje go i udostępnia plik odpowiedzi (kończy się na .response). Ten plik odsyła.', '**Nadawca:** otwiera plik odpowiedzi w [[Odbierz › Bezpośrednio · Plik|Receive › Direct · File]]. Portfel kończy transakcję i wysyła ją do sieci.'])
        else
          const HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Bezpośrednio · Przesyłanie pliku**, wpisuje kwotę i zapisuje plik (kończy się na .tx). Od teraz wyjścia są zablokowane.', '**Odbiorca:** otwiera plik w [[Odbierz › Pliki transakcji › Podpisz plik transakcji|Receive › Transaction files › Sign a transaction file]]. Jego portfel podpisuje go i zapisuje plik odpowiedzi (kończy się na .response). Ten plik odsyła.', '**Nadawca:** otwiera plik odpowiedzi w [[Odbierz › Pliki transakcji › Sfinalizuj plik odpowiedzi|Receive › Transaction files › Finalize a response file]]. Portfel kończy transakcję i wysyła ją do sieci.']),
        const HelpBlock.p('Inne portfele Epic Cash nazywają te kroki po swojemu. Jeśli plik odpowiedzi nigdy nie przyjdzie, anuluj płatność w Aktywności, aby odblokować wyjścia.'),
      ],
      id: HelpId.file,
    ),
    if (phone)
      const HelpTopic(
        'start',
        'Płatność osobiście: Bezpośrednio · Płatność QR',
        'Dwa telefony obok siebie płacą animowanym kodem QR, bez połączenia między nimi.',
        [
          HelpBlock.p('Płatność wędruje jako animowany kod QR, który drugi telefon skanuje aparatem. Nic nie jest szyfrowane, więc pokazuj kod tylko osobie, której płacisz.'),
          HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Bezpośrednio · Płatność QR**, wpisuje kwotę i dotyka **Pokaż QR**. Kod pozostaje ukryty, dopóki go nie pokażesz, odlicza 3, 2, 1 i sam znika po 40 sekundach.', '**Odbiorca:** w [[Odbierz › Bezpośrednio · QR|Receive › Direct · QR]] dotyka **Skanuj kod QR płatności**, przyjmuje płatność i pokazuje odpowiedź w ten sam sposób.', '**Nadawca:** dotyka **Skanuj odpowiedź**. Portfel wysyła płatność, a śledzenie pokazuje jej postęp.']),
          HelpBlock.p('Trzymaj kod w kadrze, aż wszystkie części zostaną odczytane: pierścień i licznik pokazują postęp. Kod, który nie jest płatnością, jest zgłaszany i pomijany. Na ekranie z kodem zrzuty ekranu są zablokowane.'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      'Metody płatności i zasady wysyłki',
      'Każda metoda to przełącznik; Epicbox jest domyślnie włączony. Wysyłanie zaczyna od wybranej metody.',
      [
        const HelpBlock.p('Strona Transakcje w [[Ustawienia › Transakcje|Settings › Transactions]] zawiera trzy rzeczy.'),
        HelpBlock.ul([
          '**Metody płatności.** Po jednym przełączniku. **Epicbox** jest domyślnie włączony; wyłączony, portfel nie łączy się z żadnym serwerem, więc nie ma płatności Epicbox, faktur ani powiadomień, a Odbierz nie pokazuje adresu Epicbox (płatności wysłane na niego czekają na serwerze). ${tor ? "**Link · HTTP** (na adresy internetowe), **Link · Tor** (na adresy .onion${phone ? ' oraz z adresem Tor tego telefonu, na który można ci płacić' : ''}) i ${phone ? '**Bezpośrednio · Płatność QR** oraz ' : ''}**Bezpośrednio · Przesyłanie pliku**" : "**Link · HTTP** (na adresy internetowe)${phone ? ', **Bezpośrednio · Płatność QR**' : ''} i **Bezpośrednio · Przesyłanie pliku**"} nie potrzebują serwera Epicbox. Wyłączona metoda nie pojawia się w Wyślij i Odbierz.',
          '**Wysyłanie zaczyna od.** Metoda, z którą otwiera się ekran Wyślij. Na ekranie Wyślij nadal możesz wybrać inną.',
          '**Zasady wysyłki.** Które wyjścia wydaje wysyłka, Najmniejsze czy Wszystkie, i czy jej reszta jest dzielona. Widać je tylko wtedy, gdy w Zaawansowanych włączone są **Opcje wysyłki**.',
        ]),
      ],
      id: HelpId.methods,
    ),
    if (phone)
      HelpTopic(
        'start',
        'Jak wygląda adres',
        tor ? 'Adres Epicbox zaczyna się od es i kończy znakiem @ i nazwą serwera. Adres bezpośredni to adres internetowy lub kończy się na .onion.' : 'Adres Epicbox zaczyna się od es i kończy znakiem @ i nazwą serwera. Adres bezpośredni to adres internetowy.',
        [
          HelpBlock.ul([
            '**Epicbox**: około 52 znaków zaczynających się od **es**, potem **@** i serwer, na przykład **esXXXX…XXXX@epicbox.epiccash.com**. Domyślny sposób; odbiorca może być offline.',
            if (tor)
              '**Link · HTTP** i **Link · Tor**: własny portfel odbiorcy, otwarty w tej chwili. Adres internetowy, np. **http://host:3415**, idzie przez Link · HTTP; adres Tor z 56 znaków kończący się na **.onion** — przez Link · Tor, czyli przez Tor.'
            else
              '**Link · HTTP**: własny portfel odbiorcy, otwarty w tej chwili. Adres internetowy, np. **http://host:3415**, idzie przez Link · HTTP.',
          ]),
          HelpBlock.p('Wyślij wybiera sposób na podstawie adresu wklejonego w pole Do. Gdy odczytujesz adres na głos, porównaj pierwsze sześć i ostatnie sześć znaków.'),
        ],
        id: HelpId.addresses,
      ),
    HelpTopic(
      'how',
      'Dlaczego transakcja wymaga obu stron?',
      'W Epic Cash portfel odbiorcy pomaga zbudować każdą transakcję, więc oba portfele muszą wziąć w niej udział.',
      [
        HelpBlock.p('Epic Cash używa Mimblewimble. Zamiast zapisywać w łańcuchu bloków adres i kwotę, oba portfele budują każdą transakcję razem, jak w uścisku dłoni:'),
        HelpBlock.ol(['Portfel nadawcy ją rozpoczyna i blokuje wysyłane wyjścia.', 'Portfel odbiorcy dodaje swoją część i podpisuje.', 'Portfel nadawcy też podpisuje, kończy transakcję i wysyła ją do sieci.']),
        HelpBlock.p('Coś musi więc przenosić wiadomości między portfelami. Robi to **Epicbox**: przechowuje wiadomość, gdy drugi portfel jest offline, więc oba nie muszą być online w tej samej chwili. ${tor ? '**Link · HTTP** i **Link · Tor** trafiają prosto' : '**Link · HTTP** trafia prosto'} do drugiego portfela, gdy jest otwarty. **Bezpośrednio · Przesyłanie pliku** (plik transakcji) to sposób ręczny.'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      'Potwierdzenia',
      'Transakcja jest ostateczna po osiągnięciu wymaganej liczby potwierdzeń ($confirmations), zwykle po około $confirmations min.',
      [
        const HelpBlock.p('Gdy sieć przyjmie transakcję, górnik umieszcza ją w bloku. Nowy blok powstaje mniej więcej co minutę. Blok z transakcją to pierwsze potwierdzenie, a każdy kolejny blok dodaje następne i utrudnia cofnięcie transakcji.'),
        HelpBlock.p('Ten portfel uznaje transakcję za ostateczną, gdy liczba potwierdzeń osiągnie **$confirmations**. Do tego czasu ma ona stan **Potwierdzanie**, a odebranych wyjść nie można jeszcze wydać. Tę liczbę można zmienić w ustawieniach: domyślnie 6, od 1 do 30. Mniej potwierdzeń to szybciej, ale słabsza ochrona przed reorganizacją łańcucha.'),
        const HelpBlock.p('Trwa dłużej niż zwykle? Portfel widzi nowe bloki tylko przez swój węzeł: sprawdź, czy węzeł jest zsynchronizowany.'),
      ],
      id: HelpId.confirmations,
    ),
    HelpTopic(
      'how',
      'Co pokazuje łańcuch bloków',
      'Żadnych adresów ani kwot: tylko zapisy monet, które sieć może sprawdzić, nie widząc, kto ani ile.',
      [
        const HelpBlock.p('W wielu łańcuchach bloków każdy może wyszukać adres i zobaczyć jego saldo i historię. Epic Cash działa inaczej:'),
        HelpBlock.ul(['**Brak adresów w łańcuchu bloków.** Adres Epicbox mówi tylko serwerowi Epicbox, dokąd dostarczać wiadomości. Nigdy nie jest zapisywany w łańcuchu bloków.', '**Brak kwot w łańcuchu bloków.** Kwoty są ukryte kryptograficznie, a sieć i tak może sprawdzić, że żadne monety nie powstały z niczego.', '**Notatki poza łańcuchem bloków.** Wiadomość dodana do płatności trafia tylko do drugiego portfela. Kontakty i nazwy portfeli zostają na $device.']),
        HelpBlock.p('Czego nie ukrywa: węzeł i serwer Epicbox widzą adres IP portfela, a węzeł publiczny może zobaczyć, o które wyjścia portfel pyta. ${tor ? 'Tor lub VPN ukrywa' : 'VPN ukrywa'} adres IP.'),
      ],
      id: HelpId.privacy,
    ),
    HelpTopic(
      'how',
      'Zablokowane kwoty i reszta',
      'Saldo składa się z osobnych wyjść. Płatność wydaje całe wyjścia, a nadwyżkę zwraca jako resztę.',
      [
        const HelpBlock.p('Saldo to zbiór wyjść. Aby wysłać 3 EPIC z wyjścia o wartości 5 EPIC, portfel wydaje całe wyjście: 3 EPIC trafiają do odbiorcy, niewielka opłata do górników, a pozostała kwota wraca jako nowe wyjście, czyli **reszta**.'),
        const HelpBlock.p('Dlatego po wysłaniu część salda może być przez kilka minut niedostępna:'),
        HelpBlock.ul(['**Zablokowane**: wyjścia w płatności, która nie jest jeszcze zakończona. Zostaną odblokowane, jeśli płatność zostanie anulowana.', '**Czeka na sfinalizowanie**: transakcja, która wciąż czeka na drugi portfel.', '**Potwierdzane**: wyjścia w bloku, który nie ma jeszcze wymaganej liczby potwierdzeń ($confirmations), w tym reszta.']),
        const HelpBlock.p('Wyjścia są wymienione na stronie [[Wyjścia|Outputs]].'),
      ],
      id: HelpId.locked,
    ),
    HelpTopic(
      'how',
      'Najmniejsze czy Wszystkie: które wyjścia wydaje płatność',
      'Najmniejsze (domyślnie) używa jak najmniej małych wyjść, a resztę zostawia do wydania. Wszystkie używa każdego wyjścia.',
      [
        const HelpBlock.p('**Najmniejsze** sortuje wyjścia do wydania według wartości i bierze najmniejsze, aż pokryją kwotę i opłatę. Tylko one są zablokowane, dopóki płatność się potwierdza; resztę można od razu wysłać.'),
        HelpBlock.p('**Wszystkie** wydaje każde wyjście do wydania i zwraca jedno wyjście reszty. Wszystko jest zablokowane do osiągnięcia wymaganej liczby potwierdzeń ($confirmations), portfel ma potem mniej, ale większych wyjść, a opłata jest nieco wyższa, bo każde wejście kosztuje. Wysłanie całego salda zawsze używa Wszystkie.'),
        if (phone)
          const HelpBlock.p('Domyślny sposób ustawisz w [[Ustawienia › Transakcje|Settings › Transactions]], gdy w Zaawansowanych włączone są Opcje wysyłki.')
        else
          const HelpBlock.p('Domyślny sposób ustawisz w [[Wyjścia › Zarządzaj wyjściami|Outputs › Manage outputs]]; w Wyślij możesz go zmienić dla jednej płatności w sekcji **Opcje wysyłki**.'),
      ],
      id: HelpId.strategy,
    ),
    HelpTopic(
      'how',
      'Podział i scalanie',
      'Podziel tworzy więcej wyjść, aby płatności mogły iść jedna po drugiej; Scal łączy je w jedno.',
      [
        HelpBlock.p('Oba to zwykłe transakcje sieciowe z tego portfela do niego samego, ostateczne po osiągnięciu wymaganej liczby potwierdzeń ($confirmations) jak każda płatność, i oba do tego czasu blokują każde wyjście do wydania.'),
        const HelpBlock.ul(['**Podziel** bierze saldo do wydania i tworzy od 2 do 10 wyjść o prawie równej wartości.', '**Scal** bierze każde wyjście do wydania i tworzy jedno.', '**Podziel resztę** (domyślnie włączone) robi to samo w zwykłej płatności, gdy zostałoby mało wyjść, za 0,004 EPIC za każde dodatkowe wyjście.']),
        const HelpBlock.p('Aktywność pokazuje każde z nich jako dwa wpisy, wysłanie i odbiór, oba z tym portfelem. Oba znajdziesz w [[Wyjścia › Zarządzaj wyjściami|Outputs › Manage outputs]].'),
      ],
      id: HelpId.split,
    ),
    HelpTopic(
      'how',
      'Opłaty',
      'Każda transakcja płaci niewielką opłatę sieciową, widoczną przed wysłaniem. Trafia ona do górników.',
      [
        const HelpBlock.p('Opłata zależy od tego, ile wyjść transakcja wydaje i tworzy, a nie od kwoty. Zwykle to mały ułamek jednego EPIC.'),
        HelpBlock.p('Przed wysłaniem jest widoczna jako **Opłata sieciowa**. **${phone ? 'Maks.' : 'Całość'}** obok kwoty wpisuje całe saldo do wydania pomniejszone o dokładną opłatę, więc nie zostaje reszta.'),
      ],
      id: HelpId.fees,
    ),
    HelpTopic(
      'safety',
      'Twoja fraza odzyskiwania',
      'Te słowa to jedyny sposób, by odzyskać EPIC. Zapisz je na papierze i nigdy nikomu ich nie udostępniaj.',
      [
        HelpBlock.p('Fraza odzyskiwania (24 słowa w nowym portfelu) to klucz do pieniędzy. Dzięki niej portfel można przywrócić na dowolnym ${phone ? 'telefonie lub komputerze' : 'komputerze'}, a każdy inny, kto ją ma, może zabrać EPIC.'),
        const HelpBlock.ul(['Zapisz słowa na papierze w tej kolejności i przechowuj go w bezpiecznym miejscu, offline.', 'Nigdy nie przechowuj ich jako zdjęcia, zrzutu ekranu ani pliku. Nigdy nie wpisuj ich na stronie internetowej ani na czacie.', 'Nikt z Epic Cash ani z tego portfela nigdy o nie nie poprosi.']),
        if (phone)
          HelpBlock.p('Aby znów zobaczyć słowa, otwórz $phrasePlace i wpisz $secret. Aplikacja nigdzie ich nie wysyła. Lepiej ich nie kopiować: po skopiowaniu portfel czyści schowek po 60 sekundach oraz gdy portfel się zablokuje lub zamknie.')
        else
          HelpBlock.p('Aby znów zobaczyć słowa, otwórz $phrasePlace i wpisz $secret. Lepiej ich nie kopiować: po skopiowaniu portfel czyści schowek po 60 sekundach oraz gdy portfel się zablokuje lub zamknie.'),
      ],
      id: HelpId.phrase,
    ),
    HelpTopic(
      'safety',
      'Kopie zapasowe i przywracanie',
      'Fraza odzyskiwania to kopia zapasowa. Aby przywrócić portfel, wpisz jej słowa w „${phone ? 'Mam już portfel: przywróć go' : 'Przywróć z frazy'}”.',
      [
        const HelpBlock.p('Fraza odzyskiwania przywraca wszystko, co jest w łańcuchu bloków, czyli saldo.'),
        HelpBlock.p('**Aby przywrócić** portfel na nowym ${phone ? 'telefonie' : 'komputerze'} lub po utracie: otwórz $restorePlace, wpisz słowa i wybierz ${phone ? 'PIN' : 'hasło'}. Po otwarciu portfel skanuje łańcuch bloków w poszukiwaniu swoich wyjść. Saldo pojawi się po tym pierwszym skanowaniu; znalezione płatności są oznaczone jako **Odzyskane środki**.'),
        HelpBlock.p('**Czego przywracanie nie odtworzy:** tego, czego nigdy nie było w łańcuchu bloków, np. kto komu zapłacił, notatek i etykiet, kontaktów, faktur, ustawień i nazw portfeli. Plik danych portfela je zachowuje: $historyBackupPlace.${phone ? ' Trzymaj ten plik poza telefonem, na przykład w e-mailu lub w chmurze.' : ''}'),
        const HelpBlock.p('**Plik danych portfela to nie fraza odzyskiwania.** Nie zawiera słów i sam nie przywróci portfela. Aby przywrócić: najpierw wpisz frazę odzyskiwania, potem zaimportuj plik; portfel zaproponuje to zaraz po przywróceniu.'),
        HelpBlock.p('**Saldo wygląda na błędne?** Uruchom $recheckPlace. Portfel jeszcze raz przeszukuje cały łańcuch bloków w poszukiwaniu swoich wyjść.'),
        if (!phone)
          const HelpBlock.p('**Pliki portfela** są w [[Ustawienia › Ten portfel › Folder portfela|Settings › This wallet › Wallet folder]]. Zachowaj frazę odzyskiwania nawet przy ich kopii: zadziała, gdy pliki zginą.'),
      ],
      id: HelpId.backup,
    ),
    const HelpTopic(
      'safety',
      'Zanim zaimportujesz',
      'Import tylko odczytuje starsze portfele i pliki. Najpierw zrób kopię zapasową każdego portfela; importujesz na własne ryzyko.',
      [
        HelpBlock.p('To wczesna wersja nowej aplikacji.'),
        HelpBlock.p('Import tylko odczytuje twoje stare portfele i pliki; nigdy ich nie usuwa ani nie zmienia.'),
        HelpBlock.p('Zanim przejdziesz dalej, upewnij się, że masz kopię zapasową każdego portfela: jego frazę odzyskiwania oraz pliki portfela, jeśli je przechowujesz.'),
        HelpBlock.p('Importujesz na własne ryzyko, a odpowiedzialność za ewentualne straty spoczywa na tobie.'),
      ],
      id: HelpId.importWarning,
    ),
    HelpTopic(
      'network',
      phone ? 'Węzły' : 'Węzły: publiczny lub lokalny',
      phone
          ? 'Węzeł łączy portfel z siecią Epic Cash. Portfel używa węzła publicznego; wybierz inny, gdy zostaje w tyle.'
          : 'Węzeł łączy portfel z siecią Epic Cash. Węzeł publiczny działa od razu; lokalny jest twój.',
      [
        const HelpBlock.p('Portfel potrzebuje węzła, aby czytać łańcuch bloków (saldo i potwierdzenia) i wysyłać transakcje do sieci.'),
        if (phone)
          HelpBlock.p('**Węzeł publiczny** to jeden z węzłów prowadzonych przez innych. Działa od razu. Jego operator widzi adres IP portfela i o które wyjścia portfel pyta${tor ? '; Tor ukrywa ten adres' : ''}.')
        else
          const HelpBlock.ul(['**Węzeł publiczny** (domyślnie): jeden z publicznych węzłów prowadzonych przez innych. Działa od razu. Jego operator widzi adres IP portfela i o które wyjścia portfel pyta.', '**Węzeł lokalny**: działa na tym komputerze. Najpierw pobiera cały łańcuch bloków, co trwa i wymaga miejsca na dysku, a potem jest twój. Gdy się synchronizuje, portfel używa węzła publicznego.']),
        if (phone)
          HelpBlock.p('Zmienisz go, dotykając wiersza Węzeł na karcie Portfel lub w $nodePlace: węzły są wymienione wraz ze stanem. Dotknij jednego, aby od razu przełączyć się na niego, albo wpisz adres, aby przefiltrować listę lub dodać węzeł. Wysyłanie wymaga zsynchronizowanego węzła; **Opóźniony** lub **Nie odpowiada** oznacza, że trzeba wybrać inny.')
        else
          HelpBlock.p('Zmienisz go w $nodePlace: węzły są wymienione wraz ze stanem. Kliknij jednego, aby od razu przełączyć się na niego, albo wpisz adres, aby przefiltrować listę lub dodać węzeł. Wysyłanie wymaga zsynchronizowanego węzła; gdy węzeł zostaje w tyle, portfel proponuje inny.'),
      ],
      id: HelpId.node,
    ),
    HelpTopic(
      'network',
      'Epicbox',
      'Epicbox dostarcza transakcje między portfelami i przechowuje je, gdy drugi portfel jest offline.',
      [
        const HelpBlock.p('Oba portfele biorą udział w każdej transakcji, więc ich wiadomości potrzebują miejsca spotkań. Serwer Epicbox jest takim miejscem: przechowuje płatność wysłaną do tego portfela, aż portfel będzie online, i przekazuje odpowiedź portfela. Wiadomości są szyfrowane, a Epicbox nie może wydać monet.'),
        const HelpBlock.p('Adres Epicbox to klucz publiczny portfela, potem **@** i nazwa jego serwera Epicbox.'),
        if (phone)
          HelpBlock.p('Serwer ustawisz, dotykając wiersza Epicbox na karcie Portfel lub w $epicboxPlace: serwery są wymienione wraz ze stanem. Dotknij jednego i potwierdź albo wpisz adres, aby przefiltrować listę lub dodać serwer. Wybór innego serwera zmienia część po @, więc przekaż nowy adres osobom, które płacą. Inne portfele Epic Cash też używają Epicbox; dwa portfele mogą używać różnych serwerów.')
        else
          HelpBlock.p('Serwer ustawisz w $epicboxPlace: serwery są wymienione wraz ze stanem. Kliknij jednego i potwierdź albo wpisz adres, aby przefiltrować listę lub dodać serwer. Wybór innego serwera zmienia część po @, więc przekaż nowy adres osobom, które płacą. Inne portfele Epic Cash też używają Epicbox; dwa portfele mogą używać różnych serwerów.'),
      ],
      id: HelpId.epicbox,
    ),
    if (tor && phone)
      HelpTopic(
        'network',
        'Tor',
        'Jeden przełącznik kieruje połączenia portfela przez Tor i daje mu adres .onion. Wolniej, bardziej prywatnie. Domyślnie wyłączony.',
        [
          HelpBlock.p('Tor ukrywa adres IP portfela przed serwerami, z którymi się łączy. Gdy przełącznik w $torPlace jest włączony, połączenie z Epicbox idzie przez Tor, płatność na adres .onion idzie przez Tor, a portfel ma własny adres Tor (kończy się na .onion), na który inne portfele mogą płacić bezpośrednio.'),
          const HelpBlock.ul([
            'Nic, czego używa portfel, się nie zmienia: ten sam węzeł, ten sam serwer Epicbox, ten sam adres.',
            'Płatność bezpośrednia na adres onion idzie przez Tor. Wyślij pokazuje przy każdej płatności, którędy idzie.',
            'Powiadomienia push są wyłączone, gdy Tor jest włączony.',
            'Wolniej niż Epicbox bez Tora. W niektórych krajach Tor jest blokowany; tam się nie połączy.',
            'Odbieranie na adres .onion działa, gdy aplikacja jest otwarta; Epicbox działa obok.',
            'Przy Tylko Tor w Zaawansowanych przełącznik zostaje włączony i nie da się go wyłączyć.',
          ]),
          const HelpBlock.p('**Uruchamianie…** oznacza, że Tor się łączy; objęte nim połączenia czekają i nigdy nie idą inną drogą. **Brak połączenia** oznacza niepowodzenie: Ponów lub wyłącz Tor. Niektóre portfele pokazują adres Tor bez .onion; to ten sam adres.'),
        ],
        id: HelpId.tor,
      )
    else if (tor)
      const HelpTopic(
        'network',
        'Tor',
        'Wolniej i bardziej prywatnie: jeden przełącznik kieruje połączenia portfela przez Tor, bez otwierania portów. Domyślnie wyłączony.',
        [
          HelpBlock.p('Z włączonym Torem połączenie z serwerem Epicbox idzie przez Tor, a portfel ma adres Tor (kończy się na .onion), na który inne portfele mogą płacić bezpośrednio, z dowolnego miejsca, bez przekierowywania czegokolwiek na routerze. Włączenie Tora nie zmienia adresów, które udostępniasz.'),
          HelpBlock.ul([
            'Włącz go w [[Ustawienia › Prywatność › Tor|Settings › Privacy › Tor]]. Wiersz Tor na pasku bocznym pokazuje jego stan.',
            'Gdy Tor się uruchamia lub nie jest połączony, to, co idzie przez Tor, czeka; nic nie idzie obok. Ponów lub wyłącz Tor.',
            'Link · HTTP na adres http(s) nie idzie przez Tor; Wyślij o tym informuje.',
            'Odbieranie przez Link · HTTP jest wyłączone, gdy Tor jest włączony: płatności prosto z innego portfela docierają na adres Link · Tor.',
            'W niektórych krajach Tor jest blokowany lub niedozwolony; tam się nie połączy.',
            'Przy Tylko Tor w Zaawansowanych przełącznik zostaje włączony i nie da się go wyłączyć.',
          ]),
          HelpBlock.p('Niektóre portfele pokazują adres bez .onion; to ten sam adres.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      'Tryby sieci',
      tor ? 'Standardowy łączy się bezpośrednio. Tylko Tor nigdy. Offline nie używa niczego poza ${phone ? 'tym telefonem' : 'tym komputerem'} i siecią lokalną.' : 'Standardowy łączy się bezpośrednio. Offline nie używa niczego poza ${phone ? 'tym telefonem' : 'tym komputerem'} i siecią lokalną.',
      [
        const HelpBlock.p('Sposób, w jaki portfel łączy się z siecią, to jeden wybór na stronie **Zaawansowane** w ustawieniach, w sekcji Sieć.'),
        HelpBlock.ul([
          tor ? '**Standardowy**: łączy się bezpośrednio. Tor to przełącznik w $torPlace.' : '**Standardowy**: łączy się bezpośrednio.',
          if (tor)
            '**Tylko Tor**: Tor jest zawsze włączony, a jego przełącznik zablokowany. Nic nie idzie przez otwarty internet. Gdy Tor się uruchamia lub zawiódł, portfel mówi **Czeka na Tor**, a wszystko, co wymaga sieci, czeka; powód podaje wyszarzona akcja. ${phone ? 'Powiadomienia są wyłączone, bo zapisanie się na nie ujawniłoby ten telefon.' : 'Odbieranie przez HTTP jest wyłączone, bo zwykły adres ujawniłby ten komputer.'}',
          '**Offline**: bez Epicbox, bez Link poza adresami lokalnymi, ${phone ? 'bez powiadomień, ' : (tor ? 'bez Tora, ' : '')}bez sprawdzania stanu. Saldo i historia zostają takie, jakie widziano ostatnio. ${phone ? '**Bezpośrednio · Płatność QR** i **Bezpośrednio · Przesyłanie pliku**' : '**Bezpośrednio · Przesyłanie pliku**'} nadal działają: używają używanego węzła, by czytać łańcuch i go wysyłać, także publicznego, a ekran o tym mówi. Dla największej prywatności użyj węzła ${phone ? 'w sieci lokalnej' : 'na tym komputerze lub w sieci lokalnej'}: wtedy saldo się odświeża${phone ? '' : ', Link · HTTP odbiera przez sieć lokalną przy odbieraniu przez HTTP ustawionym na **Z internetu**,'} i Sprawdź saldo też działa.',
        ]),
        const HelpBlock.p('W trybie Offline podaj węzeł jego adresem IP, na przykład **10.100.10.20:3413**. Nazwy nie są wyszukiwane.'),
        if (!phone) const HelpBlock.p('Peery wbudowanego węzła to ustawienie samego węzła, nie trybu.'),
        HelpBlock.p('${phone ? 'Ekran główny' : 'Pasek boczny'} pokazuje, gdy portfel jest offline${tor ? ' albo czeka na Tor' : ''}. Po wróceniu do trybu **Standardowy** wszystko znów działa.'),
      ],
      id: HelpId.modes,
    ),
    HelpTopic(
      'network',
      'Zaawansowane',
      'Na początku wyłączone. Każdy przełącznik dodaje jedną część portfela w miejscu, do którego należy.',
      [
        const HelpBlock.p('**Zaawansowane** to strona w ustawieniach z częściami, których większość osób nigdy nie potrzebuje. Wszystko na niej jest na początku wyłączone, żeby portfel pozostał prosty. Przełącznik dodaje swoją część tam, gdzie jej miejsce, a **Ukryj wszystko ponownie** wyłącza je wszystkie.'),
        HelpBlock.ul([
          '**Wyjścia**: strona Wyjścia z monetami, z których składa się saldo, i to, co można z nimi zrobić.',
          '**Szczegóły techniczne**: ID slate, kernel, commitmenty i wysokość bloku w ${phone ? 'szczegółach płatności' : 'transakcji'}. Bez tego link **Więcej** przy transakcji pokazuje je jednorazowo.',
          if (phone)
            '**Opcje wysyłki**: Strategia i Podziel resztę, w [[Ustawienia › Transakcje|Settings › Transactions]]: które wyjścia wydaje wysyłka i czy jej reszta jest dzielona.'
          else
            '**Opcje wysyłki**: sekcja w Wyślij, w której jedna wysyłka wybiera Najmniejsze lub Wszystkie i czy dzielić resztę.',
          '**Szczegóły serwerów**: hosty, opóźnienie, wersja i wysokość bloku na listach węzłów i Epicbox oraz na karcie stanu.',
          if (phone)
            '**Sprawdź od wysokości**: pozwala Sprawdź saldo zacząć od wysokości bloku lub daty zamiast od pierwszego bloku. Przywracanie zawsze daje taki wybór.'
          else
            '**Sprawdź od wysokości**: pozwala Sprawdź saldo odrzucić także niepotwierdzone transakcje. Przywracanie każdemu daje wybór bloku początkowego.',
          if (!phone) '**Wbudowany węzeł**: pozwala temu komputerowi uruchomić własny węzeł: opcja Ten komputer w Węźle i Uruchom węzeł na Przeglądzie.',
          if (!phone) '**Logi**: grupa Logi w Pomocy, by otworzyć folder logów lub wyczyścić logi. Zgłoszenie problemu i tak dołącza log.',
        ]),
        HelpBlock.p('**Automatyczna zmiana węzła** jest domyślnie włączona. Gdy twój węzeł nie odpowiada przez 30 sekund, portfel przechodzi na następny działający węzeł z twojej listy, tylko na czas tej sesji: twój własny węzeł zostaje zapisany, a portfel wraca na niego przy następnym uruchomieniu albo gdy sam wybierzesz węzeł. Nigdy nie zmienia węzła w trybie offline${phone ? '' : ' ani nie odchodzi od węzła na tym komputerze'}${tor ? ', a przy Tylko Tor przechodzi tylko na węzeł osiągalny przez Tor' : ''}.'),
        const HelpBlock.p('**Potwierdzenia** określają, ile bloków odebrana płatność czeka, zanim jej wyjścia będzie można wydać: domyślnie 6, od 1 do 30. Mniej potwierdzeń to szybciej, ale słabsza ochrona przed reorganizacją łańcucha.'),
        const HelpBlock.p('**Eksperymentalne** zawiera **Parowanie** i **Faktury**, na początku wyłączone. Parowanie dodaje Sparuj i sparowane kontakty; Faktury dodają prośby o płatność i faktury między sparowanymi kontaktami i wymagają parowania. Wyłączone są ukryte i nic nie jest dla nich sprawdzane; istniejące parowania zostają zapisane i wracają po ponownym włączeniu.'),
        if (phone) HelpBlock.p('**Powiadomienia** (eksperymentalne) to ostatni przełącznik na tej stronie. Informuje, gdy płatność lub faktura przychodzi przy zamkniętej aplikacji${tor ? '; gdy Tor jest włączony, jest wyłączony' : ''}.'),
        const HelpBlock.p('Ta sama strona ustawia tryb sieci: zobacz „Tryby sieci”.'),
      ],
      id: HelpId.advanced,
    ),
    HelpTopic(
      'trouble',
      'Rozwiązywanie problemów',
      'Najczęściej węzeł wciąż się synchronizuje, odbiorca jeszcze nie odpowiedział albo port jest zajęty.',
      [
        if (phone)
          const HelpBlock.p('**„Węzeł niezsynchronizowany”: nie można wysłać.** Wysyłanie będzie możliwe, gdy węzeł nadrobi zaległości. Poczekaj chwilę albo dotknij wiersza Węzeł na karcie Portfel i wybierz inny węzeł.')
        else
          const HelpBlock.p('**„Węzeł niezsynchronizowany”: nie można wysłać.** Wysyłanie będzie możliwe, gdy węzeł nadrobi zaległości. Poczekaj chwilę albo wybierz inny węzeł w [[Ustawienia › Węzeł|Settings › Node]].'),
        if (phone)
          const HelpBlock.p('**„Epicbox nie odpowiada”.** Portfel nie może połączyć się ze swoim serwerem Epicbox. Poczekaj chwilę; jeśli to nie minie, sprawdź połączenie albo dotknij wiersza Epicbox na karcie Portfel i wybierz inny serwer. W tym czasie działa Bezpośrednio · Przesyłanie pliku.')
        else
          const HelpBlock.p('**„Epicbox nie odpowiada”.** Portfel nie może połączyć się ze swoim serwerem Epicbox. Poczekaj chwilę; jeśli to nie minie, sprawdź połączenie albo wybierz inny serwer w [[Ustawienia › Transakcje|Settings › Transactions]]. W tym czasie działa Bezpośrednio · Przesyłanie pliku.'),
        const HelpBlock.p('**Płatność ma stan „Czeka na odbiorcę”.** Portfel odbiorcy jeszcze nie odpowiedział. Poproś odbiorcę, by go otworzył. Jeśli nigdy tego nie zrobi, anuluj płatność w Aktywności, aby odblokować wyjścia.'),
        if (phone)
          const HelpBlock.p('**Płatność nie dotarła.** Sprawdź na karcie Portfel, czy węzeł jest zsynchronizowany, a Epicbox online. Po zmianie serwera Epicbox nadawca potrzebuje nowego adresu. Portfel nadawcy musi też zakończyć transakcję; potem kilka minut na potwierdzenia.')
        else
          const HelpBlock.p('**Płatność nie dotarła.** Sprawdź w Odbierz, czy odbieranie jest włączone, a węzeł zsynchronizowany. Po zmianie serwera Epicbox nadawca potrzebuje nowego adresu. Portfel nadawcy musi też zakończyć transakcję; potem kilka minut na potwierdzenia.'),
        if (phone && tor)
          const HelpBlock.p('**Tor pokazuje „Brak połączenia”.** Tor nie mógł połączyć się ze swoją siecią. Naciśnij Ponów w [[Ustawienia › Prywatność i sieć|Settings › Privacy & network]] albo wyłącz Tor; w tym czasie nic nie wychodzi.'),
        if (!phone) ...[
          HelpBlock.p('**„Port 3415 jest używany przez inny program”.** Inny program, często inny portfel Epic, używa tego portu do płatności Link · HTTP. Zamknij go, potem naciśnij Spróbuj ponownie w Odbierz. ${tor ? 'Epicbox, Link · Tor i Bezpośrednio · Przesyłanie pliku działają' : 'Epicbox i Bezpośrednio · Przesyłanie pliku działają'} w tym czasie dalej.'),
          const HelpBlock.p('**„Inny program Epic używa tego folderu”.** Inny portfel lub węzeł Epic ma otwarte te same pliki. Zamknij go i spróbuj ponownie.'),
        ],
        if (phone)
          const HelpBlock.p('**Zapomniany PIN.** Usuń portfel na ekranie odblokowania i przywróć go z frazy odzyskiwania z nowym PIN-em. Bez frazy EPIC nie da się odzyskać.')
        else
          const HelpBlock.p('**„Nieprawidłowe hasło”.** Sprawdź Caps Lock i układ klawiatury. Zapomniane hasło: przywróć portfel z frazy odzyskiwania i wybierz nowe.'),
        HelpBlock.p('**Saldo wygląda na błędne.** Uruchom $recheckPlace.'),
        HelpBlock.p(tor
            ? '**Akcja jest wyszarzona i mówi „Tryb offline” albo „Czeka na Tor”.** W Zaawansowanych włączono Offline lub Tylko Tor. Przywróć tam tryb Standardowy albo poczekaj, aż Tor się połączy.'
            : '**Akcja jest wyszarzona i mówi „Tryb offline”.** W Zaawansowanych włączono Offline. Przywróć tam tryb Standardowy.'),
      ],
      id: HelpId.trouble,
    ),
    const HelpTopic(
      'trouble',
      'Płatności z innego portfela',
      'Płatności, których ten portfel nie wykonał ani nie odebrał sam: ta sama fraza odzyskiwania jest używana w innym portfelu.',
      [
        HelpBlock.p('Wiersz **Wysłano z innego portfela** lub **Odebrano w innym portfelu** to płatność innego portfela używającego tej samej frazy odzyskiwania. Łańcuch pokazuje te monety jako wydane lub odebrane, więc ten portfel ją wyświetla.'),
        HelpBlock.p('Kwota to to, co opuściło ten portfel po odjęciu reszty, która wróciła, albo to, co wpłynęło. Druga strona i opłata nie są tu znane.'),
        HelpBlock.p('**Jeśli nie używasz z tą frazą innego portfela**, ktoś inny zna frazę odzyskiwania. Przenieś EPIC do nowego portfela z nową frazą.'),
        HelpBlock.p('**Wysyłka, która kończy się komunikatem „Te monety zostały przed chwilą wydane przez inny portfel z użyciem Twojej frazy odzyskiwania.”**, została zwolniona. Portfel się odświeża; wyślij ponownie, gdy saldo będzie poprawne.'),
      ],
      id: HelpId.otherWallet,
    ),
    HelpTopic(
      'trouble',
      'Anulowanie płatności',
      'Kiedy anulowanie jest pewne, kiedy nie, i co dzieje się z monetami.',
      [
        const HelpBlock.h('Wysyłanie', anchor: HelpAnchor.sending),
        const HelpBlock.p('Wysłana płatność czeka na odpowiedź drugiego portfela. Dopóki czeka, anulowanie jest pewne: bez twojego portfela nic nie trafi do sieci, a monety od razu znów są twoje. Drugi portfel może nadal pokazywać płatność jako oczekującą, ale nie może jej dokończyć.'),
        const HelpBlock.p('Gdy odpowiedź wróci, twój portfel kończy płatność i wysyła ją do sieci w jednym kroku. Wysłanej płatności nie da się anulować, cofnąć ani zwrócić; tylko odbiorca może ją odesłać. Jeśli sieć ją odrzuciła, portfel proponuje wysłać ją ponownie albo anulować. To anulowanie najpierw pyta sieć i idzie dalej tylko wtedy, gdy sieć nie ma tej płatności.'),
        const HelpBlock.p('Płatność, która pozostaje bez odpowiedzi, anuluje się sama po około jednym dniu (1 440 blokach), a monety znów są wolne. Dotyczy to tak samo płatności Epicbox, Link i Bezpośrednio: anulowanie jest pewne, dopóki odpowiedź drugiej strony nie trafi do twojego portfela.'),
        HelpBlock.p('**Płatność wygląda na zablokowaną.** Zwykle drugi portfel jest offline. Poczekaj albo anuluj ją w $cancelPlace i wyślij ponownie; anulowana płatność nie przejdzie później.'),
        const HelpBlock.h('Odbieranie', anchor: HelpAnchor.receiving),
        const HelpBlock.p('Gdy płatność przychodzi, twój portfel odpowiada od razu i nic twojego nie jest blokowane. Od tej chwili portfel nadawcy kończy ją i wysyła do sieci, zwykle w ciągu minut, więc anulowanie schodzi z drogi na 15 minut, a dłużej, gdy nadawca zgłasza, że wysłał.'),
        const HelpBlock.p('Potem anulowanie to porządki po płatności, której nadawca nigdy nie wysłał. Nie jest pewne: portfel najpierw pyta sieć i odmawia, gdy płatność już tam jest. Anulowana płatność pozostaje pod obserwacją. Jeśli nadawca wyśle ją później, i tak dotrze i pokaże się jako odebrana.'),
        const HelpBlock.h('Faktury (eksperymentalne)', anchor: HelpAnchor.requests),
        const HelpBlock.p('Wysłana prośba nie trzyma żadnych monet, dopóki nie zostanie zapłacona. Do tego czasu możesz ją wycofać w każdej chwili: płacący nie może już jej zapłacić i nic się nie przenosi. Prośba, której nikt nie zapłaci, wygasa po 24 godzinach. Prośbę pokazaną jako kod QR można zapłacić raz; drugi skan jest odrzucany, więc nic nie jest płacone dwa razy.'),
        if (phone)
          const HelpBlock.p('Zapłacona przez ciebie prośba działa odwrotnie: druga strona ma twoją podpisaną płatność i ją kończy. Anulowanie pojawia się, gdy minie jej czas, około dnia po zapłacie, albo wcześniej, gdy druga strona ją wycofa. Anulowanie uwalnia monety tutaj, ale druga strona wciąż może wysłać płatność, dopóki te monety nie zostaną ponownie wydane.')
        else
          const HelpBlock.p('Zapłacona przez ciebie prośba działa odwrotnie: druga strona ma twoją podpisaną płatność i ją kończy. Anulowanie pojawia się, gdy minie jej czas, około dnia po zapłacie, albo wcześniej, gdy druga strona ją wycofa. Anulowanie uwalnia monety tutaj, ale druga strona wciąż może wysłać płatność, dopóki te monety nie zostaną ponownie wydane. Wysłanie ich do siebie, proponowane razem z anulowaniem, czyni je ostatecznym.'),
      ],
      id: HelpId.cancel,
    ),
    if (!phone)
      const HelpTopic(
        'maintenance',
        'Porządkowanie starych folderów portfeli',
        '„Usuń z listy” zostawia folder portfela na dysku. Usuń go ręcznie, mając zapisaną frazę odzyskiwania lub gdy portfel nie jest już potrzebny.',
        [
          HelpBlock.p('**Usuń z listy** w [[Ustawienia › Wszystkie portfele|Settings › All wallets]] zdejmuje portfel z listy, ale zostawia jego folder na dysku, a strona proponuje go ponownie w grupie **Usunięte z listy**. Aby pozbyć się folderu, usuń go ręcznie.'),
          HelpBlock.p('**Usunięcie folderu portfela bez jego frazy odzyskiwania oznacza utratę EPIC, które zawiera.** Najpierw sprawdź słowa albo upewnij się, że portfel jest pusty i już niepotrzebny.'),
          HelpBlock.ol([
            'Otwórz folder danych: przyciskiem **Otwórz folder** obok [[Ustawienia › Ten portfel › Pliki aplikacji|Settings › This wallet › App files]] albo wchodząc do **.epic_cash_desktop** w swoim folderze domowym (w Windows **C:\\Users\\<nazwa>\\.epic_cash_desktop**).',
            'Otwórz **wallets**. Każdy dodany portfel ma własny folder o nazwie będącej długim identyfikatorem; folder pierwszego portfela nazywa się **mainnet**.',
            'Aby je rozróżnić, otwórz folder identyfikatora, w nim folder **mainnet**, i przeczytaj **WALLET.txt**: podaje nazwę portfela.',
            'Upewnij się, że masz zapisaną frazę odzyskiwania tego portfela albo że nie ma w nim EPIC, które chcesz zachować.',
            'Zamknij Epic Cash Desktop.',
            'Usuń tylko ten jeden folder identyfikatora. Zostaw **mainnet**, **wallets.json** i całą resztę bez zmian.',
          ]),
          HelpBlock.p('**Foldery wcześniejszych wersji.** Wersje sprzed 26.10.16 trzymały dane w **~/.local/share/com.blacktyger.epicwallet** w Linuksie i w **%APPDATA%\\com.blacktyger\\EpicWallet** w Windows. Gdy każdy portfel stamtąd zostanie odtworzony w tej aplikacji i pokaże saldo, ten stary folder też można usunąć.'),
        ],
        id: HelpId.cleanup,
      ),
    ...deviceHelpTopics('pl', phone: phone),
  ];
}
