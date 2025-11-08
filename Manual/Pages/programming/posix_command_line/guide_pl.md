<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Praca w terminalu
=================

Komputer nazywany jest elektroniczną maszyną liczącą. Oznacza to że zajmuje się on głównie wykonywaniem jakiś operacji arytmetycznych, logicznych. W zależności od wyniku takich operacji może wykonywać skoki do innego miejsca, co pozwala czyli wykonanie innego zbioru instrukcji w zależności od danych lub działań użytkownika.

Komputer zajmuje się jedynie wykonywaniem takich ciągów instrukcji składających się na program komputerowy. Z punktu widzenia procesora je wykonującego, mają one zawsze postać kodu maszynowego, czyli numeru instrukcji do wykonania i jej argumentów. Z punktu widzenia programisty, mogą być one reprezentowane przez złożone instrukcje języków wyższego poziomu lub wywołania funkcji bibliotecznych. Natomiast z punktu widzenia użytkownika, często są nimi całe gotowe programy, czy też jakieś konkretne funkcje w ramach danego programu.

Zawsze jednak potrzebna jest metoda wprowadzenia takiego ciągu instrukcji oraz odebrania wyników działania programu. Dawno temu polegało to na przygotowaniu całości programu na jakimś nośniku (np. kartach perforowanych), uruchomieniu komputera, a następnie odebraniu wygenerowanych wyników na jakimś nośniku (np. w postaci wydruku). Interakcja z komputerem ograniczała się do możliwości niskopoziomowego podglądania stanu jego działania i ewentualnie możliwości wpłynięcia na działanie programu, z poziomu pulpitu technicznego.

Pracę interaktywną umożliwiła dopiero komunikacja tekstowa, pozwalająca na prowadzenie swego rodzaju dialogu z komputerem, w trakcie jego pracy. Dialogu polegającego na przesyłaniu do komputera poleceń i danych oraz odbieraniu wyników jego działania. Urządzenie umożliwiające taką tekstową komunikację z komputerem nazywamy terminalem.

Podstawowym sposobem wydawania poleceń w systemach typu Unix jest wpisywanie ich w terminalu.

## Terminal

Terminal może pracować zarówno w środowisku graficznym - jako tak zwany emulator terminala, działający pod kontrolą X serwera. Może on także działać w ramach linuxowej wirtualnej konsoli - czyli w trybie tekstowym lub pseudo tekstowym nie wymagającym środowiska graficznego lub być uruchomiony na prawdziwym połączeniu czysto tekstowym, takim jak na przykład port szeregowy.

Terminal zapewnia obsługę wejścia-wyjścia czyli wprowadzania znaków (przyjmowanych typowo z klawiatury) oraz wyświetlania znaków, typowo na ekranie. Szczegóły tego działania zależne są od konkretnej implementacji terminala i sprzętu na którym funkcjonuje. Inaczej będzie realizowane działanie terminala na porcie szeregowym, a inaczej w środowisku X serwera. Terminal zapewnia też obsługę sekwencji sterujących związanych z ruchem kursora, ustalaniem miejsca wypisywania informacji, przełączania kolorów i innego formatowania tekstu.

## Powłoka

Wprowadzane polecenia interpretowane są przez działający w terminalu program nazywany powłoką (interpreterem poleceń). W terminalu mogą być uruchamiane kolejne (takie same lub różne) interpretery poleceń. Różne interpretery korzystają z różnych składni oraz często różnią się znakiem zachęty (czyli wypisanym tekstem poprzedzającym wprowadzane polecenia).

### Język programowania

Praca w POSIXowej (Unix'owej / Linux'owej) linii poleceń (*command line*) jest pracą w interpreterze skryptowego języka programowania. Możemy wykonywać interaktywnie poszczególne „linie kodu” (komendy), możemy także zapisać je w pliku i wykonywać jako całość. Możemy definiować funkcje, korzystać z instrukcji warunkowych i pętli, itd. Standardowa powłoka w systemach POSIXowych jest jednak specyficznym językiem, przeznaczonym głównie do uruchamiania innych programów, operowania na plikach (dokładniej raczej ścieżkach w systemie plików), itd. a nie wykonywania obliczeń. Dlatego na przykład uruchomienie programu, operowanie na jego standardowym wejściu i wyjściu będzie realizowane prostą składnią (będzie wymagało mniej kodu niż chyba w jakimkolwiek innym języku), za to zapis zwykłego dodawania będzie wyglądał dość egzotycznie.

Powłoka na ogół używana jest albo do wyciągania jakieś rzeczy z plików albo do wykonywania operacji typu przenoszenie, czy zmiany nazw plików, czyli wywoływania jakiś innych komend na plikach lub odpowiednio przygotowanych nazwach przyszłych plików. Programowanie w tym języku polega w dużej mierze właśnie na wywoływaniu zewnętrznych programów, na które można patrzeć trochę jak na funkcje biblioteczne, a w przypadku bardziej rozbudowanych programów całe biblioteki. Powłoka jest też traktowana jako język mający przygotować środowisko pracy dla innej aplikacji, ustawić odpowiednie zmienne środowiskowe, przygotować katalogi, przetworzyć ścieżki, itd.

### Bash, Zsh, ...

Chyba najpopularniejszymi powłoki systemowymi (interpreteremi poleceń) jest bash i zsh. Są one zgodne ze składnią z sh, zapewniają m.in. obsługę zmiennych (zasadniczo napisowych), znaków uogólniających, itd.

#### Edycja i historia linii poleceń

Oba programy pozwalają na edycję linii poleceń oraz korzystanie z historii, dzięki czemu przy pomocy strzałek góra-dół możemy przeglądać historię wprowadzonych poleceń, a za pomocą skrótu Control R możemy ją przeszukiwać. Wprowadzane lub wybrane z historii polecenia możemy także edytować poruszając się po nich strzałkami prawo-lewo i uruchomić naciskając Enter.

Istotnym ułatwieniem przy wprowadzaniu poleceń jest funkcja auto uzupełniania z użyciem przycisku Tab. Obejmująca zarówno same nazwy poleceń, jak również ścieżki, a nierzadko także inne argumenty poleceń. W przypadku bash'a pojedyncze naciśnięcie klawisza Tab powoduje dopełnienie wpisywanego tekstu, jeżeli jest ono jednoznaczne. Jeżeli jest kilka możliwości, dopełniony zostanie najdłuższy jednoznaczny fragment. Dwukrotne naciśnięcie klawisza Tab spowoduje wyświetlenie dostępnych możliwości. Po ujednoznacznieniu możemy ponownie użyć klawisza Tab, aby nastąpiło dopełnienie, i tak dalej. Domyślne zachowanie zsh jest trochę inne.

Warto zauważyć że taka obsługa linii poleceń i jej historii nie jest cechą terminala, tylko samej powłoki. A jako że jest to często funkcjonalność dostarczana przez dedykowaną bibliotekę można ją także wielu innych programach.

### screen i tmux

`screen` i `tmux` są tzw. multiplexerami terminala - pozwala na uzyskanie wielu okien konsoli (także np. wyświetlanych jedno obok drugiego) na pojedynczym terminalu.
Ponadto pozwalają na odłączanie i podłączanie sesji, co pozwala na łatwe pozostawienie działającego programu po wylogowaniu i powrót do niego później.

## Komendy

Unixowe komendy (czyli polecenia rozumiane przez bash lub inny interpreter zgodny z sh) składają się z nazwy polecenia oraz opcji i argumentów. Nazwą polecenia może być nazwa funkcji wbudowanej, nazwa programu (znajdującego się w ścieżce wyszukiwania programów) lub pełna ścieżka do programu. Po nazwie polecenia mogą występować opcje i/lub argumenty. Są one oddzielane od nazwy polecenia i od siebie przy pomocy spacji (zasadniczo dowolnego ciągu białych znaków: spacji, tabulatorów itd.).

Nie ma silnego rozróżnienia opcji od argumentów, typowo stosowaną konwencją jest rozpoczynanie opcji od pojedynczego myślnika (opcje krótkie - jednoliterowe) lub dwóch myślników (opcje długie). W przypadku stosowania tej konwencji po pojedynczym myślniku może występować kilka bezargumentowych opcji jednoliterowych. Typowo argumenty opcji oddzielane są od nich spacją (w przypadku opcji krótkich) lub znakiem równości (w przypadku opcji długich). Jeżeli któryś z składników komendy (np. argument) zawiera spacje należy je zabezpieczyć przy pomocy odwrotnego ukośnika (`\\`) lub ujęcia zawierającego je napisu w apostrofy (`'`) lub cudzysłowa (`"`).

## Przekierowania

[img=800%]Manual/Pages/programming/posix_command_line/streams_pl.svg[/img]

Typowo program posiada trzy strumienie danych: jeden wejściowy (stdin) i dwa wyjściowe (stdout i stderr). Standardowe wyjście możemy przekierować na standardowe wejście innego programu przy pomocy `|`, np: `ls --help | less` Konstrukcja ta przekieruje wynik komendy `ls` uruchomionej z opcją `--help` do komendy `less`.

Możemy także przekierować standardowe wyjście do pliku (przy pomocy `>` lub `>>`, gdy chcemy dopisywać do pliku) lub pobrać standardowe wejście z pliku (przy pomocy `<`). `2>` pozwala na przekierowanie standardowego wyjścia błędu do pliku.

Jeżeli zachodzi potrzeba połączenia obu strumieni możemy użyć `2>&1` w celu przekierowania strumienia drugiego do pierwszego. Następnie możemy użyć  `|` aby przekierować połączony strumień do następnej komendy. Jeżeli chcemy przekierować go do pliku połączenie strumieni powinno mieć miejsce po przekierowaniu pierwszego z nich do pliku, np.: `ls . "Nie Istniejący Plik" >log.txt 2>&1`. Bash pozwala użyć `>&` i `|&`, które przekierowują oba strumienie odpowiednio do pliku lub standardowego wejścia innego polecenia, ale jest to rozszerzenie wykraczające poza standardową składnię sh.

## Kod powrotu polecenia oraz łączenie poleceń

Każde uruchamiane polecenie po zakończeniu działania zwraca liczbowy kod powrotu (w przypadku programów w C jest to wartość zwracana z funkcji `main`). Zero oznacza że polecenie zakończyło się sukcesem (np. znaleziono szukane pliki), wartość nie zerowa że zakończyło się porażką (np. nie ma pasujących plików) lub błędem (np. składnia wprowadzonego polecenia była niepoprawna).

Polecenia mogą być łączone na różne sposoby – z wykorzystaniem tej informacji lub nie:

* `a && b` – polecenie b wykona się gdy a zakończyło się sukcesem (zwróciło kod 0)
* `a || b` – polecenie b wykona się gdy a zakończyło się porażką lub błędem (zwróciło kod różny od 0)
* `a ; b` – polecenie b po zakończeniu polecenia a (bez względu na jego kod powrotu)
* `a & b` – polecenie b będzie wykonywane równocześnie z a (dokładniej polecenie a zostanie uruchomione w tle, a na terminal zajmie polecenie b)

Spacje w powyższych konstrukcjach są opcjonalne. Średnik i pojedynczy `&` mogą być dodane do polecenia także gdy nie ma kolejnego w ciągu:

* `a&` uruchomi polecenie a w tle i odda linię poleceń,
* `a;` uruchomi polecenie a (dokładnie tak samo jakby nie było tego średnika).

## Uzyskiwanie pomocy

Informację na temat działania danej komendy oraz jej opcji można uzyskać w wbudowanym systemie pomocy przy pomocy poleceń `man` lub `info` / `pinfo`.
Większość poleceń obsługuje także opcje `--help` lub `-h`, które wyświetlają informację na temat ich użycia.

### notacja

Zarówno w tekstach pomocy jak i w tym dokumencie stosowana jest konwencja polegająca na oznaczaniu opcjonalnych argumentów poprzez umieszczanie ich w nawiasach kwadratowych (jeżeli podajemy ten argument do komendy nie obejmujemy go już tymi nawiasami) oraz rozdzielaniu alternatywnych opcji przy pomocy `|`. Np. `a [b] c|d` oznacza iż polecenie `a` wymaga argumentu postaci `c` albo `d`, który może być poprzedzony argumentem `b`.

## more i less

Jeżeli wynik jakiejś komendy nie mieści się na ekranie do jego obejrzenia możemy użyć poleceń `more` lub `less`. Są to programy umożliwiające przeglądanie tekstu ekran po ekranie.
`less` posiada większe możliwości od more (w szczególności posiada możliwość przeglądanie dokumentu w tył). Programy te kończą się po wciśnięciu klawisza `q`. `less` umożliwia także wyszukiwanie -- klawisz `/` pozwala na wprowadzenie szukanej frazy, a `n` na wyszukanie kolejnego wystąpienia. Programy te umożliwiają też wyświetlanie wskazanych jako argumenty plików.  Wybrane przydatne opcje polecenia `less`:

* `-X` nie czyści ekranu przy wychodzeniu z less'a (całość historii wyświetlania pliku pozostaje w historii terminala)
* `-F` automatycznie kończy gdy wyświetlany tekst mieści się na jednym ekranie
* `-R` przepuszcza surowe sekwencje sterujące terminalem dotyczące kolorów
