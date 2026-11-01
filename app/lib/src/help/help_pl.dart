// SPDX-License-Identifier: Apache-2.0
/// Polish help: the topics and sections of help_content.dart in Polish, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';
import 'help_devices.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;

const List<HelpSection> helpSectionsPl = [
  (id: 'start', title: 'Pierwsze kroki', lede: 'Odbieranie, wysyłanie i płacenie plikiem.', art: 'help-start'),
  (id: 'how', title: 'Jak działa Epic Cash', lede: 'Udział obu portfeli. Potwierdzenia, prywatność, reszta i opłaty.', art: 'help-how'),
  (id: 'safety', title: 'Bezpieczeństwo portfela', lede: 'Fraza odzyskiwania to kopia zapasowa i klucz.', art: 'help-safety'),
  (id: 'network', title: 'Węzły i Epicbox', lede: 'Z czym łączy się portfel, oraz Tor.', art: 'help-network'),
  (id: 'trouble', title: 'Gdy coś nie działa', lede: 'Typowe przyczyny i co zrobić.', art: 'help-trouble'),
  (id: 'maintenance', title: 'Konserwacja', lede: 'Stare foldery portfeli na dysku i plik ustawień.', art: 'help-maintenance'),
];

List<HelpTopic> helpTopicsPl(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'tym telefonie' : 'tym komputerze';
  final secret = phone ? 'swój PIN lub hasło' : 'hasło portfela';
  final nodePlace = phone ? '[[Ustawienia › Sieć i prywatność › Węzeł|Settings › Network & privacy › Node]]' : '[[Ustawienia › Węzeł|Settings › Node]]';
  final epicboxPlace = phone ? '[[Ustawienia › Sieć i prywatność › Epicbox|Settings › Network & privacy › Epicbox]]' : '[[Ustawienia › Transakcje › Epicbox|Settings › Transactions › Epicbox]]';
  final torPlace = phone ? '[[Ustawienia › Sieć i prywatność › Sieć Tor|Settings › Network & privacy › Tor network]]' : '[[Ustawienia › Sieć i prywatność › Tor|Settings › Network & privacy › Tor]]';
  final netPlace = '[[Ustawienia › Sieć i prywatność|Settings › Network & privacy]]';
  final cancelPlace = phone
      ? '[[Aktywność|Activity]] (otwórz płatność, potem „Anuluj płatność”)'
      : '[[Aktywność › transakcja › Anuluj|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[Ustawienia › Ten portfel › Eksportuj dane portfela|Settings › This wallet › Export wallet data]]'
      : '[[Ustawienia › Ten portfel › Eksportuj dane portfela|Settings › This wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**Przywróć z frazy** (na pierwszym ekranie lub w [[Ustawienia › Ten portfel|Settings › This wallet]])'
      : '**Przywróć z frazy** (na pierwszym ekranie, w Odblokuj › Dodaj portfel lub w [[Ustawienia › Wszystkie portfele|Settings › All wallets]])';
  final recheckPlace = phone ? '[[Ustawienia › Ten portfel › Sprawdź saldo|Settings › This wallet › Recheck balance]]' : '[[Ustawienia › Sprawdź saldo|Settings › Recheck balance]]';
  final phrasePlace = phone ? '[[Ustawienia › Bezpieczeństwo › Zabezpiecz frazę odzyskiwania|Settings › Security › Back up recovery phrase]]' : '[[Ustawienia › Bezpieczeństwo › Fraza odzyskiwania|Settings › Security › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Odbierz pierwsze EPIC',
      'Otwórz Odbierz, skopiuj adres Epicbox i przekaż go nadawcy. Płatność dotrze sama.',
      [
        HelpBlock.p('Adres Epicbox to długi kod, który kończy się znakiem **@** i nazwą serwera Epicbox, na przykład **…@${hostSettings.epicboxUse}**. Można go bezpiecznie udostępniać: inni potrzebują go, aby zapłacić, i nikt nie może nim nic zabrać.'),
        const HelpBlock.ol(['Otwórz [[Odbierz|Receive]].', 'Skopiuj adres (lub pokaż jego kod QR) i wyślij go osobie, która płaci.', 'Płatność sama pojawi się w Aktywności.']),
        if (phone)
          const HelpBlock.p('Odbieranie działa, gdy aplikacja jest otwarta, a węzeł zsynchronizowany. Płatność wysłana przy zamkniętej aplikacji czeka na serwerze Epicbox jak w skrytce pocztowej i dociera po następnym odblokowaniu.')
        else
          const HelpBlock.p('Odbieranie włącza się samo po odblokowaniu, gdy węzeł jest zsynchronizowany. Jeśli portfel jest zamknięty, gdy ktoś płaci, Epicbox przechowuje płatność, a portfel odbiera ją po następnym odblokowaniu.'),
        HelpBlock.p('Nowa płatność najpierw czeka, aż portfel nadawcy ją zakończy, a potem ma stan „Potwierdzanie”. Po osiągnięciu wymaganej liczby potwierdzeń ($confirmations) można ją wydać.'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      'Wyślij komuś',
      'Otwórz Wyślij, wklej adres Epicbox odbiorcy, wpisz kwotę, sprawdź opłatę i wyślij.',
      [
        HelpBlock.ol(['Otwórz [[Wyślij|Send]] i wklej adres odbiorcy lub wybierz kontakt.', 'Wpisz kwotę. Opłata jest widoczna przed wysłaniem.', phone ? 'Dotknij **Dalej**, sprawdź dane, potem **Wyślij … EPIC**.' : 'Naciśnij **Sprawdź**, sprawdź dane, potem **Wyślij … EPIC**.']),
        const HelpBlock.p('Teraz musi odpowiedzieć portfel odbiorcy (zobacz „Dlaczego transakcja wymaga obu stron?”). Przez Epicbox odbiorca nie musi być teraz online: płatność poczeka, aż jego portfel się otworzy. W tym czasie użyte monety są zablokowane, więc nie da się ich wydać dwa razy.'),
        HelpBlock.p('Gdy odpowiedź wróci, portfel sam zakończy płatność i opublikuje ją w sieci. Staje się ostateczna po osiągnięciu wymaganej liczby potwierdzeń ($confirmations).'),
        HelpBlock.p('**Brak odpowiedzi?** Po kilku minutach stan zmienia się na „Czeka na odbiorcę”. Poproś odbiorcę, by otworzył portfel. Jeśli odpowiedź nigdy nie przyjdzie, anuluj płatność w $cancelPlace, aby odblokować monety. Płatność, na którą nikt nie odpowie, anuluje się sama po około jednym dniu.'),
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
        const HelpBlock.p('Bezpośrednio · Przesyłanie pliku to ten sam uścisk dłoni co przez Epicbox, tylko wiadomości przekazujesz ręcznie, na przykład e-mailem, na czacie lub na pendrivie. Działa to bez Epicbox i bez tego, by oba portfele były online w tym samym czasie.'),
        if (phone)
          const HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Bezpośrednio · Przesyłanie pliku**, wpisuje kwotę i udostępnia plik (kończy się na .tx). Od teraz monety są zablokowane.', '**Odbiorca:** otwiera plik w [[Odbierz › Bezpośrednio · Plik|Receive › Direct · File]]. Jego portfel podpisuje go i udostępnia plik odpowiedzi (kończy się na .response). Ten plik odsyła.', '**Nadawca:** otwiera plik odpowiedzi w [[Odbierz › Bezpośrednio · Plik|Receive › Direct · File]]. Portfel kończy płatność i wysyła ją do sieci.'])
        else
          const HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Bezpośrednio · Przesyłanie pliku**, wpisuje kwotę i zapisuje plik (kończy się na .tx). Od teraz monety są zablokowane.', '**Odbiorca:** otwiera plik w [[Odbierz › Pliki transakcji › Podpisz plik transakcji|Receive › Transaction files › Sign a transaction file]]. Jego portfel podpisuje go i zapisuje plik odpowiedzi (kończy się na .response). Ten plik odsyła.', '**Nadawca:** otwiera plik odpowiedzi w [[Odbierz › Pliki transakcji › Sfinalizuj plik odpowiedzi|Receive › Transaction files › Finalize a response file]]. Portfel kończy płatność i wysyła ją do sieci.']),
        const HelpBlock.p('Inne portfele Epic Cash nazywają te kroki po swojemu. Jeśli plik odpowiedzi nigdy nie przyjdzie, anuluj płatność w Aktywności, aby odblokować monety.'),
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
          HelpBlock.ol(['**Nadawca:** w Wyślij wybiera **Bezpośrednio · Płatność QR**, wpisuje kwotę, dotyka **Utwórz kod QR płatności**, a potem **Pokaż QR**. Kod pozostaje ukryty, dopóki go nie pokażesz, odlicza 3, 2, 1 i sam znika po 40 sekundach.', '**Odbiorca:** w [[Odbierz › Bezpośrednio · QR|Receive › Direct · QR]] dotyka **Skanuj kod QR płatności**, przyjmuje płatność i pokazuje odpowiedź w ten sam sposób.', '**Nadawca:** dotyka **Skanuj odpowiedź**. Portfel wysyła płatność, a śledzenie pokazuje jej postęp.']),
          HelpBlock.p('Trzymaj kod w kadrze, aż wszystkie części zostaną odczytane: pierścień i licznik pokazują postęp. Kod, który nie jest kodem QR płatności, jest pomijany, z komunikatem. Na ekranie z kodem zrzuty ekranu są zablokowane.'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      'Metody płatności i zasady wysyłki',
      'Każda metoda to przełącznik; Epicbox jest domyślnie włączony. Wysyłanie otwiera się na metodzie domyślnej.',
      [
        const HelpBlock.p('Strona Transakcje w [[Ustawienia › Transakcje|Settings › Transactions]] zawiera trzy rzeczy.'),
        HelpBlock.ul([
          '**Metody płatności.** Po jednym przełączniku. **Epicbox** jest domyślnie włączony; wyłączony, portfel nie łączy się z żadnym serwerem, więc nie ma płatności Epicbox ani faktur, a Odbierz nie pokazuje adresu Epicbox (płatności wysłane na niego czekają na serwerze). ${tor ? "**Link · HTTP** (na adresy internetowe), **Link · Tor** (na adresy .onion${phone ? ' oraz z adresem Tor tego telefonu, na który można ci płacić' : ''}) i ${phone ? '**Bezpośrednio · Płatność QR** oraz ' : ''}**Bezpośrednio · Przesyłanie pliku**" : "**Link · HTTP** (na adresy internetowe)${phone ? ', **Bezpośrednio · Płatność QR**' : ''} i **Bezpośrednio · Przesyłanie pliku**"} nie potrzebują serwera Epicbox. Wyłączona metoda nie pojawia się w Wyślij i Odbierz.${phone ? ' Na telefonie **Link · HTTP** odbiera tylko w sieci Wi-Fi, której ufasz: **Ufaj tej sieci** w Odbierz dodaje ją; w [[Ustawienia › Transakcje|Settings › Transactions]] › **Zaufane sieci** można je wyświetlić i usunąć.' : ''}',
          '**Domyślna metoda.** Metoda, z którą otwiera się ekran Wyślij; na ekranie Wyślij można wybrać inną.',
          '**Zasady wysyłki.** Które wyjścia wydaje wysyłka, Najmniejsze czy Wszystkie, i czy jej reszta jest dzielona. Widać je tylko wtedy, gdy w Zaawansowanych włączone są **Opcje wysyłki**.',
        ]),
      ],
      id: HelpId.methods,
    ),
    HelpTopic(
        'start',
        'Jak wygląda adres',
        tor ? 'Adres Epicbox zaczyna się od es i kończy znakiem @ i nazwą serwera. Adres bezpośredni to adres internetowy lub kończy się na .onion.' : 'Adres Epicbox zaczyna się od es i kończy znakiem @ i nazwą serwera. Adres bezpośredni to adres internetowy.',
        [
          HelpBlock.ul([
            '**Epicbox**: około 52 znaków zaczynających się od **es**, potem **@** i serwer, na przykład **esXXXX…XXXX@${hostSettings.epicboxUse}**. Domyślny sposób; odbiorca może być offline.',
            if (tor)
              '**Link · HTTP** i **Link · Tor**: własny portfel odbiorcy, otwarty w tej chwili. Adres internetowy, np. **http://host:${appConfig.httpListenPort}**, idzie przez Link · HTTP; adres Tor z 56 znaków kończący się na **.onion** — przez Link · Tor, czyli przez Tor.'
            else
              '**Link · HTTP**: własny portfel odbiorcy, otwarty w tej chwili. Adres internetowy, np. **http://host:${appConfig.httpListenPort}**, idzie przez Link · HTTP.',
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
        HelpBlock.p('Coś musi przenosić wiadomości między portfelami. **Epicbox** przechowuje każdą wiadomość, gdy drugi portfel jest offline, więc oba nie muszą być online jednocześnie. ${tor ? '**Link · HTTP** i **Link · Tor** trafiają prosto' : '**Link · HTTP** trafia prosto'} do drugiego portfela, gdy jest otwarty. **Bezpośrednio · Przesyłanie pliku** z plikiem transakcji to sposób ręczny.'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      'Potwierdzenia',
      'Płatność jest ostateczna po osiągnięciu wymaganej liczby potwierdzeń ($confirmations).',
      [
        const HelpBlock.p('Gdy sieć przyjmie transakcję, górnik umieszcza ją w bloku. Blok z transakcją to pierwsze potwierdzenie, a każdy kolejny blok dodaje następne i utrudnia cofnięcie transakcji.'),
        HelpBlock.p('Ten portfel uznaje transakcję za ostateczną, gdy liczba potwierdzeń osiągnie **$confirmations**. Do tego czasu ma ona stan **Potwierdzanie**, a odebranych wyjść nie można jeszcze wydać. Tę liczbę można zmienić w ustawieniach: domyślnie 6, od 1 do 30. Mniej potwierdzeń to szybciej, ale mniej bezpiecznie: od czasu do czasu łańcuch zastępuje swoje najnowsze bloki (reorganizacja) i płatność z małą liczbą potwierdzeń może zostać przez to cofnięta.'),
        const HelpBlock.ul(['**Oczekiwanie**: oba portfele muszą podpisać płatność. Przez Epicbox dzieje się to samo.', '**Potwierdzanie**: płatność jest w łańcuchu i zbiera potwierdzenia.', '**Do wydania**: potwierdzenia są, a monety można wydać.']),
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
        if (tor) const HelpBlock.p('**Epicbox.** Przez Tor serwer Epicbox nie widzi adresu tego urządzenia.'),
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
        HelpBlock.p('Przed wysłaniem jest widoczna jako **Opłata sieciowa**. **Maks.** obok kwoty wpisuje całe saldo do wydania pomniejszone o dokładną opłatę, więc nie zostaje reszta.'),
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
    if (phone)
      const HelpTopic(
        'safety',
        'PIN lub hasło',
        'PIN lub hasło odblokowuje ten portfel na tym telefonie. Monety przywraca tylko fraza odzyskiwania.',
        [
          HelpBlock.p('PIN lub hasło odblokowuje ten portfel na tym telefonie; monety przywraca tylko fraza odzyskiwania. Hasło jest dłuższe i trudniejsze do odgadnięcia: co najmniej 10 znaków, nie same cyfry. Włączysz je w [[Ustawienia › Bezpieczeństwo|Settings › Security]].'),
          HelpBlock.p('Czas łamania pokazywany przy wyborze hasła to szacunek dla tego telefonu.'),
          HelpBlock.p('**Zapomniane?** Przywróć portfel z jego frazy odzyskiwania i wybierz nowe.'),
        ],
        id: HelpId.passphrase,
      ),
    HelpTopic(
      'safety',
      'Kopie zapasowe i przywracanie',
      'Fraza odzyskiwania to kopia zapasowa. Aby przywrócić portfel, wpisz jej słowa w „Przywróć z frazy”.',
      [
        const HelpBlock.p('Fraza odzyskiwania przywraca wszystko, co jest w łańcuchu bloków, czyli saldo.'),
        HelpBlock.p('**Aby przywrócić** portfel na nowym ${phone ? 'telefonie' : 'komputerze'} lub po utracie: otwórz $restorePlace, wpisz słowa i wybierz ${phone ? 'PIN' : 'hasło'}. Po otwarciu portfel skanuje łańcuch bloków w poszukiwaniu swoich wyjść. Saldo pojawi się po tym pierwszym skanowaniu; znalezione płatności są oznaczone jako **Odzyskane środki**.'),
        HelpBlock.p('**Czego przywracanie nie odtworzy:** tego, czego nigdy nie było w łańcuchu bloków, np. kto komu zapłacił, notatek i etykiet, kontaktów, faktur, ustawień i nazw portfeli. Plik danych portfela je zachowuje: $historyBackupPlace.${phone ? ' Trzymaj ten plik poza telefonem, na przykład w e-mailu lub w chmurze.' : ''}'),
        const HelpBlock.p('**Plik danych portfela to nie fraza odzyskiwania.** Nie zawiera słów i sam nie przywróci portfela. Aby przywrócić: najpierw wpisz frazę odzyskiwania, potem zaimportuj plik; portfel zaproponuje to zaraz po przywróceniu.'),
        HelpBlock.p('**Saldo wygląda na błędne?** Uruchom $recheckPlace. Portfel jeszcze raz przeszukuje cały łańcuch bloków w poszukiwaniu swoich wyjść.'),
        if (!phone)
          const HelpBlock.p('**Eksportuj CSV** zapisuje listę płatności jako plik arkusza o nazwie **epic-payments-<portfel>-<data>.csv**, z kolumnami: data, typ, stan, kwota, opłata, druga strona, notatka, ID slate, kernel i wysokość bloku. Plik nie jest szyfrowany: każdy, kto go ma, odczyta kwoty, daty, adresy i notatki. Nie można go ponownie zaimportować; do tego służy **Eksportuj dane portfela**.'),
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
          const HelpBlock.ul(['**Węzeł publiczny** (domyślnie): jeden z publicznych węzłów prowadzonych przez innych. Działa od razu. Jego operator widzi adres IP portfela i o które wyjścia portfel pyta.', '**Węzeł lokalny**: działa na tym komputerze jako osobny program, który uruchamia się i zatrzymuje razem z aplikacją. Najpierw pobiera cały łańcuch (za pierwszym razem około 4 GB, potem codziennie trochę), co trwa; na dysku zajmuje około 5 GB i powoli rośnie. Gdy się synchronizuje, portfel pokazuje jego postęp i używa węzła publicznego. Zobacz „Uruchamianie węzła lokalnego”.']),
        if (phone)
          HelpBlock.p('Zmienisz go, dotykając ikony węzła na karcie Portfel lub w $nodePlace: węzły są wymienione wraz ze stanem. Dotknij jednego, aby od razu przełączyć się na niego, albo wpisz adres, aby przefiltrować listę lub dodać węzeł. Wysyłanie wymaga zsynchronizowanego węzła; **{n} w tyle** lub **Nie odpowiada** oznacza, że trzeba wybrać inny.')
        else
          HelpBlock.p('Zmienisz go w $nodePlace: węzły są wymienione wraz ze stanem. Kliknij jednego, aby od razu przełączyć się na niego, albo wpisz adres, aby przefiltrować listę lub dodać węzeł. Wysyłanie wymaga zsynchronizowanego węzła; gdy węzeł zostaje w tyle, portfel proponuje inny.'),
      ],
      id: HelpId.node,
    ),
    if (!phone)
      HelpTopic(
        'network',
        'Uruchamianie węzła lokalnego',
        'Porty, peery, dane łańcucha i dostęp właściciela węzła, który działa na tym komputerze.',
        [
          HelpBlock.p('Węzeł lokalny to osobny program dołączony do aplikacji. Ma własną kopię łańcucha, więc portfel nie pyta nikogo innego. Zajmuje na dysku około 5 GB i powoli rośnie; pierwsze pobieranie to około 4 GB, potem codziennie trochę. Dopóki nie jest zsynchronizowany, nic nie da się przez niego wysłać ani odebrać, a portfel może w tym czasie używać węzła publicznego.'),
          HelpBlock.ul([
            '**Uruchamiaj z aplikacją** uruchamia węzeł przy starcie i synchronizuje go, dopóki aplikacja jest otwarta. Zatrzymuje się, gdy aplikacja się zamyka.',
            '**Porty.** Port API (3413) to ten, z którym rozmawia portfel; port P2P (3414) to ten, przez który inne węzły łączą się z tym. Zmieniaj je tylko wtedy, gdy inny węzeł na tym komputerze lub w tej sieci już ich używa. Węzeł uruchamia się ponownie z nowymi portami.',
            '**Peery.** Węzeł sam znajduje peery. Preferowane peery są dodawane najpierw. Maks. przychodzących i Maks. wychodzących przyjmują liczbę od 8 do 500. Peery można zablokować i odblokować na karcie Peery.',
            '**Dane łańcucha.** **Użyj istniejących** pozwala węzłowi czytać dane łańcucha, które zostawił inny węzeł Epic na tym komputerze, zamiast je pobierać; nic nie jest kopiowane, a Usuń dane łańcucha jest dla tego folderu wyłączone. **Usuń** kasuje dane łańcucha tego węzła; cały łańcuch pobierze się ponownie przy następnym uruchomieniu. Klucze i historia zostają.',
            '**Dostęp właściciela.** Etap synchronizacji i peery pochodzą z API właściciela węzła. Jego sekret to pierwsza linia pliku **.api_secret** w folderze danych węzła. Portfel trzyma sekret w kluczowniku tego komputera, nigdy w ustawieniach ani w pliku danych portfela. Do węzła na innym komputerze sekret idzie jawnie przez http, czytelny w tej sieci: w sieci współdzielonej użyj VPN lub https.',
          ]),
        ],
        id: HelpId.localNode,
      ),
    HelpTopic(
      'network',
      'Epicbox',
      'Epicbox dostarcza transakcje między portfelami i przechowuje je, gdy drugi portfel jest offline.',
      [
        const HelpBlock.p('Oba portfele biorą udział w każdej transakcji, więc ich wiadomości potrzebują miejsca spotkań. Serwer Epicbox jest takim miejscem: przechowuje płatność wysłaną do tego portfela, aż portfel będzie online, i przekazuje odpowiedź portfela. Wiadomości są szyfrowane, a Epicbox nie może wydać monet.'),
        const HelpBlock.p('Adres Epicbox to klucz publiczny portfela, potem **@** i nazwa jego serwera Epicbox.'),
        if (phone)
          HelpBlock.p('Serwer ustawisz, dotykając ikony Epicbox na karcie Portfel lub w $epicboxPlace: serwery są wymienione wraz ze stanem. Dotknij jednego i potwierdź albo wpisz adres, aby przefiltrować listę lub dodać serwer. Wybór innego serwera zmienia część po @, więc przekaż nowy adres osobom, które płacą. Inne portfele Epic Cash też używają Epicbox; dwa portfele mogą używać różnych serwerów.')
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
            'Węzeł, serwer Epicbox i adresy pozostają te same.',
            'Płatność Link na adres onion idzie przez Tor; Wyślij pokazuje, czy płatność idzie przez Tor.',
            'Wolniej niż bez Tora. W niektórych krajach Tor jest blokowany; tam się nie połączy.',
            'Odbieranie na adres .onion działa, gdy aplikacja jest otwarta; Epicbox działa obok.',
            'W trybie sieci Tylko Tor przełącznik zostaje włączony i nie da się go wyłączyć.',
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
            'Włącz go w [[Ustawienia › Sieć i prywatność › Tor|Settings › Network & privacy › Tor]]. Wiersz Tor na pasku bocznym pokazuje jego stan.',
            'Gdy Tor się uruchamia lub nie jest połączony, to, co idzie przez Tor, czeka; nic nie idzie obok. Ponów lub wyłącz Tor.',
            'Link · HTTP na adres http(s) nie idzie przez Tor; Wyślij o tym informuje.',
            'Odbieranie przez Link · HTTP jest wyłączone, gdy Tor jest włączony: płatności prosto z innego portfela docierają na adres Link · Tor.',
            'W niektórych krajach Tor jest blokowany lub niedozwolony; tam się nie połączy.',
            'W trybie sieci Tylko Tor przełącznik zostaje włączony i nie da się go wyłączyć.',
          ]),
          HelpBlock.p('Niektóre portfele pokazują adres bez .onion; to ten sam adres.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      'Tryby sieci',
      tor
          ? 'Normalny, Tylko Tor, Tylko węzeł lub Wyłącznik awaryjny: z czym łączy się każdy z nich i jak płacić z portfela, który nigdy nie wchodzi online.'
          : 'Normalny, Tylko węzeł lub Wyłącznik awaryjny: z czym łączy się każdy z nich i jak płacić z portfela, który nigdy nie wchodzi online.',
      [
        HelpBlock.p('To, ile internetu używa portfel, to jeden wybór w $netPlace, a portfel go zapamiętuje. Poza trybem **Normalny** oznaczenie ${phone ? 'na ekranie głównym' : 'na pasku tytułu'} podaje tryb; dotknij go, by go zmienić.'),
        HelpBlock.ul([
          tor
              ? '**Normalny**: wszystko, do czego portfel jest skonfigurowany: węzeł, Epicbox, Link, strona statusu, kurs i sprawdzanie aktualizacji. Tor to osobny przełącznik w $torPlace.'
              : '**Normalny**: wszystko, do czego portfel jest skonfigurowany: węzeł, Epicbox, Link, strona statusu, kurs i sprawdzanie aktualizacji.',
          if (tor)
            '**Tylko Tor**: każde połączenie idzie przez Tor, także z węzłem i Epicbox; nic nie dotyka otwartego internetu. Dopóki Tor nie jest gotowy, nic się nie łączy, a ikony statusu mówią **Oczekiwanie na Tor**. Odbieranie przez Link · HTTP zostaje wyłączone: zwykły adres ujawniłby to urządzenie.',
          '**Tylko węzeł**: portfel rozmawia tylko z używanym węzłem, pierwszym na twojej liście węzłów. Wyłączone są Epicbox, Link, strona statusu, kurs, sprawdzanie aktualizacji, linki do eksploratora, zgłoszenia problemów, parowanie i połączone urządzenia. ${phone ? '**Bezpośrednio · Płatność QR** i **Bezpośrednio · Przesyłanie pliku**' : '**Bezpośrednio · Przesyłanie pliku**'} działają.${tor ? ' Gdy Tor jest włączony, z węzłem łączy się przez Tor.' : ''}',
          '**Wyłącznik awaryjny**: nic się nie łączy, także węzeł. Portfel otwiera się z ostatnio znanym saldem i historią. Możesz tworzyć, podpisywać i kończyć płatności przez ${phone ? '**Bezpośrednio · Przesyłanie pliku** i **Bezpośrednio · Płatność QR**' : '**Bezpośrednio · Przesyłanie pliku**'}, pokazywać swój adres, robić kopię zapasową i eksportować. Płatności czekające na odbiorcę są wstrzymane i wznawiają się po wyjściu z trybu.',
        ]),
        const HelpBlock.h('Dlaczego własny węzeł przy trybie Tylko węzeł', anchor: HelpAnchor.ownNode),
        HelpBlock.p('Używany węzeł widzi każde zapytanie portfela. Węzeł na $device lub w twojej sieci zachowuje to dla ciebie i odpowiada szybko. Działa każdy węzeł. Wybierz go w $nodePlace.'),
        const HelpBlock.h('Płacenie z Wyłącznika awaryjnego', anchor: HelpAnchor.coldStorage),
        HelpBlock.ol([
          'Utwórz płatność jak zwykle przez ${phone ? '**Bezpośrednio · Przesyłanie pliku** lub **Bezpośrednio · Płatność QR**' : '**Bezpośrednio · Przesyłanie pliku**'} i dokończ ją, gdy wróci odpowiedź.',
          'Portfel pokaże **Gotowa, niewysłana**: płatność jest kompletna, ale wysłać ją może tylko urządzenie online.',
          '**Zapisz plik** i ${phone ? '**Pokaż QR**' : '**skopiuj** tekst'}, a potem zanieś na urządzenie online.',
          'Tam ${phone ? 'w menu Aktywności wybierz **Wyślij gotową płatność**' : 'w Odbierz, w Plikach transakcji wybierz **Wyślij gotową płatność**'}, wczytaj plik${phone ? ' lub zeskanuj kod' : ' lub wklej tekst'} i naciśnij **Wyślij**. Zrobi to każdy portfel Epic Cash; klucz nie jest potrzebny.',
          'Tutaj płatność pokaże **Do wysłania z innego urządzenia**, a po wyjściu z trybu i gdy portfel zobaczy ją w łańcuchu, **Potwierdzanie**.',
        ]),
        HelpBlock.p('Usługi wyłączone przez tryb są szare jako **Wyłączone (Tylko węzeł)**: to tryb, nie błąd. Przy przełączaniu nic nie jest anulowane; płatność czekająca na odbiorcę przez Epicbox wznawia się po wyjściu z trybu${tor ? ' (lub po przejściu na Tylko Tor)' : ''}.'),
        HelpBlock.p('**Automatyczna zmiana węzła** jest domyślnie włączona. Gdy twój węzeł nie odpowiada przez 30 sekund, portfel przechodzi na następny działający węzeł z twojej listy, tylko na czas tej sesji: twój własny węzeł zostaje zapisany, a portfel wraca na niego przy następnym uruchomieniu albo gdy sam wybierzesz węzeł. Nigdy nie zmienia węzła w trybach Tylko węzeł i Wyłącznik awaryjny${phone ? '' : ' ani nie odchodzi od węzła na tym komputerze'}${tor ? ', a przy Tylko Tor przechodzi tylko na węzeł osiągalny przez Tor' : ''}.'),
      ],
      id: HelpId.modes,
    ),
    HelpTopic(
      'network',
      'Zaawansowane',
      'Na początku wyłączone. Każdy przełącznik pokazuje kolejną część portfela w miejscu, do którego należy.',
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
          if (!phone) '**Węzeł lokalny**: pozwala temu komputerowi uruchomić własny węzeł, w $nodePlace.',
          if (!phone) '**Logi**: grupa Logi w Pomocy, by otworzyć folder logów lub wyczyścić logi. Zgłoszenie problemu i tak dołącza log.',
        ]),
        const HelpBlock.p('**Potwierdzenia** określają, ile bloków odebrana płatność czeka, zanim jej wyjścia będzie można wydać: domyślnie 6, od 1 do 30. Mniej potwierdzeń to szybciej, ale mniej bezpiecznie.'),
        const HelpBlock.p('**Eksperymentalne** zawiera **Faktury**, na początku wyłączone: prośby o płatność i faktury między sparowanymi kontaktami. Wyłączone są ukryte i nic nie jest dla nich sprawdzane. Samo parowanie jest zawsze włączone.'),
        HelpBlock.p('Tryb sieci i **automatyczna zmiana węzła** są w $netPlace: zobacz „Tryby sieci”.'),
      ],
      id: HelpId.advanced,
    ),
    HelpTopic(
      'trouble',
      'Rozwiązywanie problemów',
      phone
          ? 'Najczęściej węzeł wciąż się synchronizuje albo odbiorca jeszcze nie odpowiedział.'
          : 'Najczęściej węzeł wciąż się synchronizuje, odbiorca jeszcze nie odpowiedział albo port jest zajęty.',
      [
        if (phone)
          const HelpBlock.p('**„Węzeł niezsynchronizowany”: nie można wysłać.** Wysyłanie będzie możliwe, gdy węzeł nadrobi zaległości. Poczekaj chwilę albo dotknij ikony węzła na karcie Portfel i wybierz inny węzeł.')
        else
          const HelpBlock.p('**„Węzeł niezsynchronizowany”: nie można wysłać.** Wysyłanie będzie możliwe, gdy węzeł nadrobi zaległości. Poczekaj chwilę albo wybierz inny węzeł w [[Ustawienia › Węzeł|Settings › Node]].'),
        if (phone)
          const HelpBlock.p('**„Epicbox nie odpowiada”.** Portfel nie może połączyć się ze swoim serwerem Epicbox. Poczekaj chwilę; jeśli to nie minie, sprawdź połączenie albo dotknij ikony Epicbox na karcie Portfel i wybierz inny serwer. W tym czasie działa Bezpośrednio · Przesyłanie pliku.')
        else
          const HelpBlock.p('**„Epicbox nie odpowiada”.** Portfel nie może połączyć się ze swoim serwerem Epicbox. Poczekaj chwilę; jeśli to nie minie, sprawdź połączenie albo wybierz inny serwer w [[Ustawienia › Transakcje|Settings › Transactions]]. W tym czasie działa Bezpośrednio · Przesyłanie pliku.'),
        const HelpBlock.p('**Płatność ma stan „Czeka na odbiorcę”.** Portfel odbiorcy jeszcze nie odpowiedział. Poproś odbiorcę, by go otworzył. Jeśli nigdy tego nie zrobi, anuluj płatność w Aktywności, aby odblokować monety.'),
        if (phone)
          const HelpBlock.p('**Płatność nie dotarła.** Sprawdź ikony stanu na karcie Portfel: węzeł zsynchronizowany, Epicbox połączony. Po zmianie serwera Epicbox nadawca potrzebuje nowego adresu. Portfel nadawcy musi też zakończyć transakcję; potem kilka minut na potwierdzenia.')
        else
          const HelpBlock.p('**Płatność nie dotarła.** Sprawdź w Odbierz, czy odbieranie jest włączone, a węzeł zsynchronizowany. Po zmianie serwera Epicbox nadawca potrzebuje nowego adresu. Portfel nadawcy musi też zakończyć transakcję; potem kilka minut na potwierdzenia.'),
        if (phone && tor)
          const HelpBlock.p('**Tor pokazuje „Brak połączenia”.** Tor nie mógł połączyć się ze swoją siecią. Naciśnij Ponów w [[Ustawienia › Sieć i prywatność|Settings › Network & privacy]] albo wyłącz Tor; w tym czasie nic nie wychodzi.'),
        if (!phone) ...[
          HelpBlock.p('**„Port ${appConfig.httpListenPort} jest używany przez inny program”.** Inny program, często inny portfel Epic, używa tego portu do płatności Link · HTTP. Zamknij go, potem naciśnij Spróbuj ponownie w Odbierz. ${tor ? 'Epicbox, Link · Tor i Bezpośrednio · Przesyłanie pliku działają' : 'Epicbox i Bezpośrednio · Przesyłanie pliku działają'} w tym czasie dalej.'),
          const HelpBlock.p('**„Inny program Epic używa tego folderu”.** Inny portfel lub węzeł Epic ma otwarte te same pliki. Zamknij go i spróbuj ponownie.'),
        ],
        if (phone)
          const HelpBlock.p('**Zapomniany PIN.** Usuń portfel na ekranie odblokowania i przywróć go z frazy odzyskiwania z nowym PIN-em. Bez frazy EPIC nie da się odzyskać.')
        else
          const HelpBlock.p('**„Nieprawidłowe hasło”.** Sprawdź Caps Lock i układ klawiatury. Zapomniane hasło: przywróć portfel z frazy odzyskiwania i wybierz nowe.'),
        HelpBlock.p(tor
            ? '**Akcja jest wyszarzona i wymienia tryb albo mówi „Czeka na Tor”.** W $netPlace włączono Tylko Tor, Tylko węzeł lub Wyłącznik awaryjny. Przywróć tam tryb Normalny albo poczekaj, aż Tor się połączy.'
            : '**Akcja jest wyszarzona i wymienia tryb.** W $netPlace włączono Tylko węzeł lub Wyłącznik awaryjny. Przywróć tam tryb Normalny.'),
        HelpBlock.p('**Saldo wygląda na błędne.** Uruchom $recheckPlace.'),
      ],
      id: HelpId.trouble,
    ),
    const HelpTopic(
      'trouble',
      'Płatności z innego portfela',
      'Płatności, których ten portfel nie wykonał ani nie odebrał sam: ta sama fraza odzyskiwania jest używana w innym portfelu.',
      [
        HelpBlock.p('Wiersz **Wysłano z innego urządzenia** lub **Odebrano na innym urządzeniu** to płatność innego portfela używającego tej samej frazy odzyskiwania. Łańcuch pokazuje te monety jako wydane lub odebrane, więc ten portfel ją wyświetla.'),
        HelpBlock.p('Kwota to to, co opuściło ten portfel po odjęciu reszty, która wróciła, albo to, co wpłynęło. Druga strona i opłata nie są tu znane.'),
        HelpBlock.p('**Jeśli nie używasz z tą frazą innego portfela**, najpierw zapytaj inny węzeł: przełącz węzeł i użyj „Sprawdź saldo”. Węzeł, który pomija monety w odpowiedziach, może sprawić, że wyglądają na wydane. Jeśli nadal są wydane, ktoś inny może znać frazę odzyskiwania: przenieś EPIC do nowego portfela z nową frazą.'),
        HelpBlock.p('**Wysyłka, która kończy się komunikatem „Węzeł pokazuje te monety jako już wydane, a ten portfel ich nie wydał. Najpewniej zrobił to inny portfel z Twoją frazą odzyskiwania.”**, została zwolniona. Portfel się odświeża; wyślij ponownie, gdy saldo będzie poprawne.'),
      ],
      id: HelpId.otherWallet,
    ),
    HelpTopic(
      'trouble',
      'Anulowanie płatności',
      'Kiedy anulowanie jest pewne, kiedy nie, i co dzieje się z monetami.',
      [
        const HelpBlock.p('Anulowanie zatrzymuje płatność, która jeszcze nie przeszła. Czy jest pewne, zależy od jednej rzeczy: czy druga strona ma już wszystko, czego potrzebuje, by dokończyć płatność. Jeśli nie, anulowanie jest pewne: płatność nie może przejść bez tego portfela, a anulowanie jest bez opłaty. Jeśli tak, druga strona wciąż mogłaby dokończyć płatność, a portfel daje dwa sposoby anulowania.'),
        const HelpBlock.h('Przenieść monety z powrotem czy odblokować', anchor: HelpAnchor.twoWays),
        const HelpBlock.p('**Przenieś monety z powrotem** najpierw przenosi monety z powrotem do tego portfela, za zwykłą opłatą sieciową; potem stara płatność już nigdy nie przejdzie. **Odblokuj monety** jest bez opłaty i nic nie przenosi: monety znów można wydać, a płatność zostaje, jak jest. Jeśli druga strona mimo to ją dokończy, pokaże się jako zapłacona; jeśli nie, nic się nie stanie.'),
        const HelpBlock.h('Wysyłanie', anchor: HelpAnchor.sending),
        const HelpBlock.p('Płatność wysłana z tego portfela najpierw czeka na odpowiedź drugiej strony. Dopóki czeka, anulowanie jest pewne: bez tego portfela nic nie może przejść, a monety są od razu odblokowane. Bez opłaty. Drugi portfel może nadal pokazywać płatność jako oczekującą, ale nie może jej dokończyć.'),
        HelpBlock.p('Gdy odpowiedź wróci, ten portfel kończy płatność i publikuje ją w sieci w jednym kroku. Płatności, która dotarła do sieci, nie da się anulować, cofnąć ani zwrócić; tylko odbiorca może ją odesłać. Jeśli sieć jej nie przyjmie, płatność i tak jest kompletna i wciąż może przejść później. ${phone ? 'Po około dniu portfel proponuje „Zwolnij środki”, z tymi samymi dwoma sposobami: Przenieś monety z powrotem przenosi monety z powrotem do tego portfela, za zwykłą opłatą sieciową; Odblokuj monety jest bez opłaty.' : 'Portfel proponuje opublikować ją ponownie albo anulować. To anulowanie najpierw sprawdza sieć i odmawia, gdy sieć już ma płatność. W przeciwnym razie daje te same dwa sposoby: Przenieś monety z powrotem przenosi monety z powrotem do tego portfela, za zwykłą opłatą sieciową; Odblokuj monety jest bez opłaty.'}'),
        const HelpBlock.p('Płatność, na którą nikt nie odpowiada, anuluje się sama po około jednym dniu (1 440 blokach), a monety są odblokowane. Dotyczy to tak samo płatności Epicbox, Link i Bezpośrednio: anulowanie jest pewne, dopóki odpowiedź drugiej strony nie trafi do tego portfela.'),
        HelpBlock.p('**Płatność wygląda na zablokowaną.** Zwykle drugi portfel jest offline. Poczekaj albo anuluj ją w $cancelPlace i wyślij ponownie. Anulowana płatność nie może przejść później.'),
        const HelpBlock.h('Odbieranie', anchor: HelpAnchor.receiving),
        const HelpBlock.p('Gdy płatność przychodzi, ten portfel odpowiada od razu i żadne jego monety nie są blokowane. Od tej chwili portfel nadawcy kończy płatność i publikuje ją w sieci, zwykle w ciągu minut. Anulowanie jest niedostępne przez 15 minut, a dłużej, gdy nadawca zgłasza, że ją opublikował.'),
        const HelpBlock.p('Potem anulowanie usuwa płatność, której nadawca nigdy nie opublikował. Nie jest pewne: portfel najpierw sprawdza sieć i odmawia, gdy płatność już tam jest. Anulowana płatność pozostaje pod obserwacją. Jeśli nadawca opublikuje ją później, i tak dotrze i pokaże się jako odebrana.'),
        const HelpBlock.h('Faktury (eksperymentalne)', anchor: HelpAnchor.requests),
        const HelpBlock.p('Faktura wysłana z tego portfela nie trzyma żadnych monet, dopóki nie zostanie zapłacona. Do tego czasu można ją wycofać w każdej chwili: płacący nie może już jej zapłacić i żadne monety się nie przenoszą. Faktura, której nikt nie zapłaci, wygasa po 24 godzinach. Fakturę pokazaną jako kod QR można zapłacić raz; drugi skan jest odrzucany, więc nic nie jest płacone dwa razy.'),
        const HelpBlock.p('Faktura zapłacona z tego portfela działa odwrotnie: druga strona ma już wszystko, czego potrzebuje, by dokończyć płatność. Anulowanie pojawia się, gdy minie czas faktury, około dnia po zapłacie, albo wcześniej, gdy druga strona ją wycofa. Daje te same dwa sposoby: Przenieś monety z powrotem przenosi monety z powrotem do tego portfela, za zwykłą opłatą sieciową, więc stara płatność nie może już przejść; Odblokuj monety jest bez opłaty i zostawia ją drugiej stronie. Jeśli monet nie da się przenieść od razu, portfel ponawia próbę, dopóki jest otwarty. Do tego czasu druga strona wciąż mogłaby dokończyć płatność, a jeśli to zrobi, pokaże się ona jako zapłacona.'),
      ],
      id: HelpId.cancel,
    ),
    if (!phone)
      const HelpTopic(
        'maintenance',
        'Porządkowanie starych folderów portfeli',
        '„Usuń z listy” zostawia folder portfela na dysku. Folder usuwa się ręcznie, mając zapisaną frazę odzyskiwania lub gdy portfel jest pusty.',
        [
          HelpBlock.ul([
            '**Usuń z listy** w [[Ustawienia › Wszystkie portfele|Settings › All wallets]] zdejmuje portfel z listy. Jego folder zostaje na dysku, a strona proponuje go ponownie w grupie **Usunięte z listy**.',
            '**Usunięcie folderu portfela bez jego frazy odzyskiwania oznacza utratę EPIC, które zawiera.** Usuwać tylko portfel z zapisaną frazą albo pusty i już niepotrzebny.',
            'Foldery leżą w **wallets** w folderze danych (**Otwórz folder** obok [[Ustawienia › Ten portfel › Pliki aplikacji|Settings › This wallet › App files]]), po jednym na portfel, nazwane jego identyfikatorem; **WALLET.txt** w środku podaje nazwę portfela. Przy zamkniętym Epic Cash Desktop usunąć tylko ten jeden folder identyfikatora, a resztę zostawić bez zmian.',
          ]),
        ],
        id: HelpId.cleanup,
      ),
    HelpTopic(
      'maintenance',
      'Plik ustawień',
      'Jeden plik zawiera Twoje listy węzłów i serwerów Epicbox. Błąd w nim nigdy nie kosztuje ostatnich dobrych ustawień.',
      [
        if (phone) ...[
          HelpBlock.p(
            'Aplikacja prowadzi plik z Twoimi listami węzłów i serwerów Epicbox oraz trzema przełącznikami: strona stanu, sprawdzanie aktualizacji i ceny. Wszystko inne przychodzi z aplikacją. Plik zmienia się w aplikacji, na przykład w $nodePlace i $epicboxPlace, nie ręcznie.',
          ),
          HelpBlock.ul([
            '**Pierwszy serwer każdej listy jest tym używanym.** Wybrany serwer przechodzi na górę; zmiana kolejności zmienia używany. Gdy pierwszy węzeł nie odpowiada, próbowany jest następny.',
            '**Pierwszy serwer Epicbox jest w adresie Epicbox każdego portfela.** Gdy na górę trafi inny, każdy portfel dostaje nowy adres; płatności wysłane na stary adres nie dochodzą.',
            '**Plik, którego nie da się odczytać:** ostatnie dobre ustawienia pozostają w użyciu. Zanim aplikacja zapisze nowy plik, zachowuje stary jako **settings.toml.bad-<time>**.',
            'Usunięty plik jest zapisywany ponownie.',
          ]),
        ] else ...[
          HelpBlock.p(
            'Plik **settings.toml** zawiera Twoje listy węzłów i serwerów Epicbox oraz trzy przełączniki: strona stanu, sprawdzanie aktualizacji i ceny. Wszystko inne przychodzi z aplikacją. Leży w folderze danych: **~/.epic_cash_desktop/settings.toml** w Linuksie i macOS, **%USERPROFILE%\\.epic_cash_desktop\\settings.toml** w Windows (**Otwórz folder** obok [[Ustawienia › Ten portfel › Pliki aplikacji|Settings › This wallet › App files]]).',
          ),
          HelpBlock.ul([
            'Zmiana w aplikacji jest od razu zapisywana do pliku. Zmiana zapisana w pliku działa, gdy aplikacja pracuje, po chwili.',
            '**Pierwszy serwer każdej listy jest tym używanym.** Wybrany serwer przechodzi na górę; zmiana kolejności zmienia używany. Gdy pierwszy węzeł nie odpowiada, próbowany jest następny.',
            '**Pierwszy serwer Epicbox jest w adresie Epicbox każdego portfela.** Gdy na górę trafi inny, każdy portfel dostaje nowy adres; płatności wysłane na stary adres nie dochodzą.',
            '**Błąd w pliku:** ostatnie dobre ustawienia pozostają w użyciu, komunikat wskazuje wiersz, a uszkodzony plik nigdy nie jest nadpisywany.',
            'Gdy aplikacja musi zapisać plik z błędami, najpierw zachowuje go jako **settings.toml.bad-<time>**, a potem zapisuje dobry.',
            'Usunięty plik jest zapisywany ponownie.',
          ]),
        ],
      ],
      id: HelpId.settingsFile,
    ),
    ...deviceHelpTopics('pl', phone: phone),
  ];
}
