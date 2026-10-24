/// Polish help: the topics and sections of help_content.dart in Polish, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';

const List<HelpSection> helpSectionsPl = [
  (id: 'start', title: 'Pierwsze kroki', lede: 'Odbieranie, wysyłanie i sposób z plikiem.', art: 'help-start'),
  (id: 'how', title: 'Jak działa Epic Cash', lede: 'Udział obu portfeli; potwierdzenia, prywatność, reszta i opłaty.', art: 'help-how'),
  (id: 'safety', title: 'Bezpieczeństwo portfela', lede: 'Fraza odzyskiwania to kopia zapasowa i klucz.', art: 'help-safety'),
  (id: 'network', title: 'Węzły i Epicbox', lede: 'Z czym łączy się portfel, oraz Tor.', art: 'help-network'),
  (id: 'trouble', title: 'Gdy coś nie działa', lede: 'Typowe przyczyny i co zrobić.', art: 'help-trouble'),
];

List<HelpTopic> helpTopicsPl(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'tym telefonie' : 'tym komputerze';
  final secret = phone ? 'swój PIN' : 'hasło portfela';
  final nodePlace = phone ? '[[Ustawienia › Prywatność i sieć › Węzeł|Settings › Privacy & network › Node]]' : '[[Ustawienia › Węzeł|Settings › Node]]';
  final epicboxPlace = phone ? '[[Ustawienia › Prywatność i sieć › Epicbox|Settings › Privacy & network › Epicbox]]' : '[[Ustawienia › Odbieranie › Odbieranie przez Epicbox|Settings › Receiving › Epicbox receiving]]';
  final torPlace = phone ? '[[Ustawienia › Prywatność i sieć › Sieć Tor|Settings › Privacy & network › Tor Network]]' : '[[Ustawienia › Prywatność › Tor|Settings › Privacy › Tor]]';
  final cancelPlace = phone
      ? '[[Aktywność|Activity]] (otwórz płatność, potem „Anuluj płatność”)'
      : '[[Aktywność › transakcja › Anuluj|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[Ustawienia › Portfel › Eksportuj kopię historii|Settings › Wallet › Export history backup]]'
      : '[[Ustawienia › Ten portfel › Eksportuj kopię historii|Settings › This wallet › Export history backup]]';
  final restorePlace = phone
      ? '**Mam już portfel: przywróć go** (na pierwszym ekranie lub po usunięciu tego portfela w [[Ustawienia › Portfel|Settings › Wallet]])'
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
        HelpBlock.p('**Brak odpowiedzi?** Po kilku minutach stan zmienia się na „Czeka na odbiorcę”. Poproś odbiorcę, by otworzył portfel. Jeśli odpowiedź nigdy nie przyjdzie, anuluj płatność w $cancelPlace, aby odblokować wyjścia. Płatność nigdy nie jest anulowana sama.'),
        if (phone)
          const HelpBlock.p('Wysyłanie wymaga zsynchronizowanego węzła. Adres Epicbox wymaga też odpowiadającego serwera Epicbox; adres bezpośredni (http lub .onion) wymaga, by portfel odbiorcy był w tej chwili otwarty i osiągalny.')
        else
          const HelpBlock.p('Wysyłanie wymaga zsynchronizowanego węzła. Adres Epicbox wymaga też włączonego odbierania przez Epicbox; adres Bezpośrednio (http lub .onion) wymaga, by portfel odbiorcy był w tej chwili otwarty i osiągalny.'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      'Wyślij plikiem',
      'Sposób ręczny: zapisz plik transakcji, przekaż go odbiorcy, a potem otwórz plik odpowiedzi, który odeśle.',
      [
        const HelpBlock.p('Pliki to ten sam uścisk dłoni co przez Epicbox, tylko wiadomości przekazujesz ręcznie, na przykład e-mailem, na czacie lub na pendrivie. Działa to bez Epicbox i bez tego, by oba portfele były online w tym samym czasie.'),
        if (phone)
          const HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Plik**, wpisuje kwotę i udostępnia plik (kończy się na .tx). Od teraz wyjścia są zablokowane.', '**Odbiorca:** otwiera plik w [[Odbierz › Plik|Receive › File]]. Jego portfel podpisuje go i udostępnia plik odpowiedzi (kończy się na .response). Ten plik odsyła.', '**Nadawca:** otwiera plik odpowiedzi w [[Odbierz › Plik|Receive › File]]. Portfel kończy transakcję i wysyła ją do sieci.'])
        else
          const HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Plik**, wpisuje kwotę i zapisuje plik (kończy się na .tx). Od teraz wyjścia są zablokowane.', '**Odbiorca:** otwiera plik w [[Odbierz › Pliki transakcji › Podpisz plik transakcji|Receive › Transaction files › Sign a transaction file]]. Jego portfel podpisuje go i zapisuje plik odpowiedzi (kończy się na .response). Ten plik odsyła.', '**Nadawca:** otwiera plik odpowiedzi w [[Odbierz › Pliki transakcji › Sfinalizuj plik odpowiedzi|Receive › Transaction files › Finalize a response file]]. Portfel kończy transakcję i wysyła ją do sieci.']),
        const HelpBlock.p('Inne portfele Epic Cash nazywają te kroki po swojemu. Jeśli plik odpowiedzi nigdy nie przyjdzie, anuluj płatność w Aktywności, aby odblokować wyjścia.'),
      ],
      id: HelpId.file,
    ),
    HelpTopic(
      'start',
      'Metody płatności i zasady wysyłki',
      'Epicbox jest zawsze włączony. Bezpośrednio i Plik to przełączniki. Wysyłanie zaczyna od wybranej metody.',
      [
        phone
            ? const HelpBlock.p('Strona Transakcje w [[Ustawienia › Transakcje|Settings › Transactions]] zawiera trzy rzeczy.')
            : const HelpBlock.p('Strona **Transakcje** w ustawieniach zawiera trzy rzeczy.'),
        HelpBlock.ul([
          '**Metody płatności.** Epicbox jest zawsze włączony. **Bezpośrednio** (na adresy .onion i internetowe${phone ? ' oraz z adresem Tor tego telefonu, na który można ci płacić' : ''}) i **Plik** to przełączniki: wyłączona metoda nie pojawia się w Wyślij i Odbierz.',
          '**Wysyłanie zaczyna od.** Metoda, z którą otwiera się ekran Wyślij. Na ekranie Wyślij nadal możesz wybrać inną.',
          '**Zasady wysyłki.** Które wyjścia wydaje wysyłka, Najmniejsze czy Wszystkie, i czy jej reszta jest dzielona. Widać je tylko wtedy, gdy w Zaawansowanych włączone są **Opcje wysyłki**.',
        ]),
      ],
      id: HelpId.methods,
    ),
    if (phone)
      const HelpTopic(
        'start',
        'Jak wygląda adres',
        'Adres Epicbox zaczyna się od es i kończy znakiem @ i nazwą serwera. Adres bezpośredni to adres internetowy lub kończy się na .onion.',
        [
          HelpBlock.ul([
            '**Epicbox**: około 52 znaków zaczynających się od **es**, potem **@** i serwer, na przykład **esXXXX…XXXX@epicbox.epiccash.com**. Domyślny sposób; odbiorca może być offline.',
            '**Bezpośrednio**: własny portfel odbiorcy, otwarty w tej chwili. Albo adres internetowy, np. **http://host:3415**, albo adres Tor z 56 znaków kończący się na **.onion**, który działa przez Tor.',
          ]),
          HelpBlock.p('Wyślij wybiera sposób na podstawie adresu wklejonego w pole Do. Gdy odczytujesz adres na głos, porównaj pierwsze sześć i ostatnie sześć znaków.'),
        ],
        id: HelpId.addresses,
      ),
    const HelpTopic(
      'how',
      'Dlaczego transakcja wymaga obu stron?',
      'W Epic Cash portfel odbiorcy pomaga zbudować każdą transakcję, więc oba portfele muszą wziąć w niej udział.',
      [
        HelpBlock.p('Epic Cash używa Mimblewimble. Zamiast zapisywać w łańcuchu bloków adres i kwotę, oba portfele budują każdą transakcję razem, jak w uścisku dłoni:'),
        HelpBlock.ol(['Portfel nadawcy ją rozpoczyna i blokuje wysyłane wyjścia.', 'Portfel odbiorcy dodaje swoją część i podpisuje.', 'Portfel nadawcy też podpisuje, kończy transakcję i wysyła ją do sieci.']),
        HelpBlock.p('Coś musi więc przenosić wiadomości między portfelami. Robi to **Epicbox**: przechowuje wiadomość, gdy drugi portfel jest offline, więc oba nie muszą być online w tej samej chwili. **Bezpośrednio · HTTP** i **Bezpośrednio · Tor** trafiają prosto do drugiego portfela, gdy jest otwarty. **Plik transakcji** to sposób ręczny.'),
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
        HelpBlock.p('Ten portfel uznaje transakcję za ostateczną, gdy liczba potwierdzeń osiągnie **$confirmations**. Do tego czasu ma ona stan **Potwierdzanie**, a odebranych wyjść nie można jeszcze wydać. Ta liczba jest stała.'),
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
        const HelpBlock.p('Czego nie ukrywa: węzeł i serwer Epicbox widzą adres IP portfela, a węzeł publiczny może zobaczyć, o które wyjścia portfel pyta. Tor lub VPN ukrywa adres IP.'),
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
        HelpBlock.p('**Czego przywracanie nie odtworzy:** tego, czego nigdy nie było w łańcuchu bloków, np. kto komu zapłacił, wiadomości transakcji, kontaktów i nazw portfeli. Kopia historii zachowuje szczegóły płatności i kontakty: $historyBackupPlace.${phone ? ' Trzymaj plik kopii poza telefonem, na przykład w e-mailu lub w chmurze.' : ''}'),
        HelpBlock.p('**Saldo wygląda na błędne?** Uruchom $recheckPlace. Portfel jeszcze raz przeszukuje cały łańcuch bloków w poszukiwaniu swoich wyjść.'),
        if (!phone)
          const HelpBlock.p('**Pliki portfela** są w [[Ustawienia › Ten portfel › Folder portfela|Settings › This wallet › Wallet folder]]. Zachowaj frazę odzyskiwania nawet przy ich kopii: zadziała, gdy pliki zginą.'),
      ],
      id: HelpId.backup,
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
          const HelpBlock.p('**Węzeł publiczny** to jeden z węzłów prowadzonych przez innych. Działa od razu. Jego operator widzi adres IP portfela i o które wyjścia portfel pyta; Tor ukrywa ten adres.')
        else
          const HelpBlock.ul(['**Węzeł publiczny** (domyślnie): jeden z publicznych węzłów prowadzonych przez innych. Działa od razu. Jego operator widzi adres IP portfela i o które wyjścia portfel pyta.', '**Węzeł lokalny**: działa na tym komputerze. Najpierw pobiera cały łańcuch bloków, co trwa i wymaga miejsca na dysku, a potem jest twój. Gdy się synchronizuje, portfel używa węzła publicznego.']),
        if (phone)
          HelpBlock.p('Zmienisz go, dotykając wiersza Węzeł na karcie Portfel lub w $nodePlace: węzły publiczne są wymienione wraz ze stanem, możesz też wpisać adres węzła. Wysyłanie wymaga zsynchronizowanego węzła; **Opóźniony** lub **Nie odpowiada** oznacza, że trzeba wybrać inny.')
        else
          HelpBlock.p('Zmienisz go w $nodePlace: wybierz jeden z węzłów publicznych, wymienionych wraz ze stanem, lub wpisz adres węzła. Wysyłanie wymaga zsynchronizowanego węzła; gdy węzeł zostaje w tyle, portfel proponuje inny.'),
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
          HelpBlock.p('Serwer ustawisz, dotykając wiersza Epicbox na karcie Portfel lub w $epicboxPlace: wybierz jeden z serwerów publicznych, wymienionych wraz ze stanem, lub wpisz własny. Wybór innego serwera zmienia część po @, więc przekaż nowy adres osobom, które płacą. Inne portfele Epic Cash też używają Epicbox; dwa portfele mogą używać różnych serwerów.')
        else
          HelpBlock.p('Serwer ustawisz w $epicboxPlace: wybierz jeden z serwerów publicznych, wymienionych wraz ze stanem, lub wpisz własny. Wybór innego serwera zmienia część po @, więc przekaż nowy adres osobom, które płacą. Inne portfele Epic Cash też używają Epicbox; dwa portfele mogą używać różnych serwerów.'),
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
            'Płatności bezpośrednie na adres http(s) nie idą przez Tor; Wyślij o tym informuje.',
            'Odbieranie Bezpośrednio · HTTP jest wyłączone, gdy Tor jest włączony: płatności prosto z innego portfela docierają na adres Bezpośrednio · Tor.',
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
      'Standardowy łączy się bezpośrednio. Tylko Tor nigdy. Offline nie używa niczego poza ${phone ? 'tym telefonem' : 'tym komputerem'} i siecią lokalną.',
      [
        const HelpBlock.p('Sposób, w jaki portfel łączy się z siecią, to jeden wybór na stronie **Zaawansowane** w ustawieniach, w sekcji Sieć.'),
        HelpBlock.ul([
          '**Standardowy**: łączy się bezpośrednio. Tor to przełącznik w $torPlace.',
          '**Tylko Tor**: Tor jest zawsze włączony, a jego przełącznik zablokowany. Nic nie idzie przez otwarty internet. Gdy Tor się uruchamia lub zawiódł, portfel mówi **Czeka na Tor**, a wszystko, co wymaga sieci, czeka; powód podaje wyszarzona akcja. ${phone ? 'Powiadomienia są wyłączone, bo zapisanie się na nie ujawniłoby ten telefon.' : 'Odbieranie przez HTTP jest wyłączone, bo zwykły adres ujawniłby ten komputer.'}',
          '**Offline**: nic poza ${phone ? 'tym telefonem' : 'tym komputerem'} i siecią lokalną. Saldo i historia zostają takie, jakie widziano ostatnio. Z węzłem ${phone ? 'w sieci lokalnej' : 'na tym komputerze lub w sieci lokalnej'} portfel nadal może tworzyć, podpisywać, finalizować i wysyłać płatności oraz płacić bezpośrednio na adresy lokalne. Bez niego wysyłanie i odbieranie czekają.',
        ]),
        if (!phone) const HelpBlock.p('Peery wbudowanego węzła to ustawienie samego węzła, nie trybu.'),
        HelpBlock.p('${phone ? 'Ekran główny' : 'Pasek boczny'} pokazuje, gdy portfel jest offline albo czeka na Tor. Po wróceniu do trybu **Standardowy** wszystko znów działa.'),
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
        HelpBlock.p('**Automatyczna zmiana węzła** jest domyślnie włączona. Gdy twój węzeł nie odpowiada przez 30 sekund, portfel przechodzi na następny działający węzeł z twojej listy, tylko na czas tej sesji: twój własny węzeł zostaje zapisany, a portfel wraca na niego przy następnym uruchomieniu albo gdy sam wybierzesz węzeł. Nigdy nie zmienia węzła w trybie offline${phone ? '' : ' ani nie odchodzi od węzła na tym komputerze'}, a przy Tylko Tor przechodzi tylko na węzeł osiągalny przez Tor.'),
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
          const HelpBlock.p('**„Epicbox nie odpowiada”.** Portfel nie może połączyć się ze swoim serwerem Epicbox. Poczekaj chwilę; jeśli to nie minie, sprawdź połączenie albo dotknij wiersza Epicbox na karcie Portfel i wybierz inny serwer. W tym czasie działa plik.')
        else
          const HelpBlock.p('**„Epicbox nie odpowiada”.** Portfel nie może połączyć się ze swoim serwerem Epicbox. Poczekaj chwilę; jeśli to nie minie, sprawdź połączenie albo wybierz inny serwer w [[Ustawienia › Odbieranie|Settings › Receiving]]. W tym czasie działa plik.'),
        const HelpBlock.p('**Płatność ma stan „Czeka na odbiorcę”.** Portfel odbiorcy jeszcze nie odpowiedział. Poproś odbiorcę, by go otworzył. Jeśli nigdy tego nie zrobi, anuluj płatność w Aktywności, aby odblokować wyjścia.'),
        if (phone)
          const HelpBlock.p('**Płatność nie dotarła.** Sprawdź na karcie Portfel, czy węzeł jest zsynchronizowany, a Epicbox online. Po zmianie serwera Epicbox nadawca potrzebuje nowego adresu. Portfel nadawcy musi też zakończyć transakcję; potem kilka minut na potwierdzenia.')
        else
          const HelpBlock.p('**Płatność nie dotarła.** Sprawdź w Odbierz, czy odbieranie jest włączone, a węzeł zsynchronizowany. Po zmianie serwera Epicbox nadawca potrzebuje nowego adresu. Portfel nadawcy musi też zakończyć transakcję; potem kilka minut na potwierdzenia.'),
        if (phone)
          const HelpBlock.p('**Tor pokazuje „Brak połączenia”.** Tor nie mógł połączyć się ze swoją siecią. Naciśnij Ponów w [[Ustawienia › Prywatność i sieć|Settings › Privacy & network]] albo wyłącz Tor; w tym czasie nic nie wychodzi.'),
        if (!phone) ...const [
          HelpBlock.p('**„Port 3415 jest używany przez inny program”.** Inny program, często inny portfel Epic, używa tego portu do płatności Bezpośrednio · HTTP. Zamknij go, potem naciśnij Spróbuj ponownie w Odbierz. Epicbox, Bezpośrednio · Tor i pliki działają w tym czasie dalej.'),
          HelpBlock.p('**„Inny program Epic używa tego folderu”.** Inny portfel lub węzeł Epic ma otwarte te same pliki. Zamknij go i spróbuj ponownie.'),
        ],
        if (phone)
          const HelpBlock.p('**Zapomniany PIN.** Usuń portfel na ekranie odblokowania i przywróć go z frazy odzyskiwania z nowym PIN-em. Bez frazy EPIC nie da się odzyskać.')
        else
          const HelpBlock.p('**„Nieprawidłowe hasło”.** Sprawdź Caps Lock i układ klawiatury. Zapomniane hasło: przywróć portfel z frazy odzyskiwania i wybierz nowe.'),
        HelpBlock.p('**Saldo wygląda na błędne.** Uruchom $recheckPlace.'),
        const HelpBlock.p('**Akcja jest wyszarzona i mówi „Tryb offline” albo „Czeka na Tor”.** W Zaawansowanych włączono Offline lub Tylko Tor. Przywróć tam tryb Standardowy albo poczekaj, aż Tor się połączy.'),
      ],
      id: HelpId.trouble,
    ),
  ];
}
