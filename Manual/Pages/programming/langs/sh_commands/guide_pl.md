<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
--> 

Podstawowe polecenia powłoki
============================

Operacje na systemie plików
---------------------------

### wypisywanie

Polecenie echo służy do wypisania przekazanych do niego argumentów na ekran – np.:

* `echo abc   xyz` wypisze *abc xyz*
* `echo *` wypisze pliki nie ukryte w bieżącym katalogu (ze względu na [url=guide://programming/posix_filesystem]znaki uogólniające powłoki[/url]).

Aby poprawnie wypisywać wiele spacji, znaki nowej linii i inne znaki specjalne należy użyć cudzysłowów lub apostrofów (te drugi w odróżnieniu od cudzysłowów zabezpieczają także znak dolara `$`):

* `echo "abc   xyz"` oraz `echo 'abc   xyz'` wypiszą *abc   xyz*
* `echo "*"` oraz `echo '*'` wypiszą [i]*[/i]
* `echo "$abc"` najprawdopodobniej wypisze nic, natomiast `echo '$abc'` wypisze *$abc*

### listowanie i  wyszukiwanie plików

* `ls [opcje] [ścieżka]` – listowanie zawartości katalogu, do ważniejszych opcji należy zaliczyć:
	* `-a` wyświetlaj pliki ukryte (zaczynających się od kropki)
	* `-l` wyświetlaj pliki w formie listy z szczegółowymi informacjami (uprawnienia, rozmiar, data modyfikacji, właściciel, grupa, rozmiar)
	* `-1` wyświetlaj pliki w formie 1 plik w jednej linii (bez dodatkowych informacji; stosowane domyślne gdy wynik komendy przekazywany jest strumieniem do innej komendy lub pliku)
	* `-h` stosuj jednostki typu k, M, G zamiast podawać rozmiar w bajtach
	* `-t` sortuj wg daty modyfikacji
	* `-S` sortuj wg rozmiaru
	* `-r` odwróć kolejność sortowania
	* `-c` użyj daty utworzenia zamiast daty modyfikacji (stosowane w połączeniu z `-l` i/lub `-t`)
	* `-d` wyświetlaj informacje o katalogu zamiast jego zawartości
* `find [opcje] [katalog startowy] [wyrażenie]` – wyszukiwanie w systemie plików w oparciu o nazwę/ścieżkę lub właściwości pliku, do ważniejszych opcji należy zaliczyć:
	* `-P` wypisuj informacje o linkach symbolicznych a nie plikach przez nie wskazywanych (domyślne)
	* `-L` wypisuj informacje o wskazywanych przez linki symboliczne plikach
. do ważniejszych elementów wyrażenia należy zaliczyć:
	* `-name "wyrażenie"` pliki których nazwa pasuje do wyrażenia korzystającego z shellowych znaków uogólniających
	* 	komenda find (w odróżnieniu np. od `ls`) samodzielnie interpretują wyrażenia zawierające shellowe znaki uogólniające, w związku z czym konieczne może się okazać zabezpieczenie ich przed interpretacją przez powłokę np. przy pomocy umieszczenia wewnątrz pojedynczych cudzysłowów
	* `-iname "wyrażenie"` jak `-name`, tyle że nie rozróżnia wielkości liter
	* `-path "wyrażenie"` pliki których ścieżka pasuje do wyrażenia korzystającego z shellowych znaków uogólniających
	* `-ipath "wyrażenie"` jak `-path`, tyle że nie rozróżnia wielkości liter
	* `-regex "wyrażenie"` pliki których ścieżka pasuje do wyrażenia regularnego
	* `-iregex "wyrażenie"` jak `-regexp`, tyle że nie rozróżnia wielkości liter
	* `warunek -o warunek` łączy warunki sumą logiczną „OR” (zamiast domyślnego iloczynu logicznego „AND”)
	* `! warunek` negacja warunku
	* `-mtime [+|-]n` pliki których modyfikacja odbyła się `n`*24 godziny temu
	* `-mmin [+|-]n` pliki których modyfikacja odbyła się `n` minut temu
	* `-ctime [+|-]n` pliki które zostały utworzone `n`*24 godziny temu
	* `-cmin [+|-]n` pliki które zostały utworzone `n` minut temu
	* `-size [+|-]n[c|k|M|G]` pliki których rozmiar wynosi `n` (c - bajtów, k - kilobajtów, M - Megabajtów, G - gigabajtów)
	* *w powyższych testach `+` oznacza więcej niż, `-` oznacza mniej niż, uwaga: porównywaniu podlegają liczby całkowite, np. +1 oznacza *>1* w liczbach całkowitych tzn. *\ge2**
	* `-exec polecenie \{\} \;` dla każdego znalezionego pliku wykonaj `polecenie` podstawiając ścieżkę do tego pliku pod `\{\}` (zastosowane odwrotne ukośniki służą zabezpieczeniu nawiasów klamrowych i średnika przed zinterpretowaniem ich przez powłokę)
	* `-execdir polecenie \{\} \;`, podobnie jak `-exec` tyle że polecenie zostanie uruchomione w katalogu w którym znajduje się wyszukany plik
* `du [opcje] ścieżka1 [ścieżka2 [...]]` – wyświetlanie informacji o zajętej przestrzeni dyskowej przez wskazane pliki / katalogi, do ważniejszych opcji należy zaliczyć:
	* `-s` podaje łączną ilość zajętego miejsca dla każdego argumentów (zamiast wypisywać rozmiar każdego pliku)
	* `-c` podaje łączną ilość zajętego miejsca dla wszystkich argumentów
	* `-h` stosuje jednostki typu k, M, G
. podawany rozmiar może się różnić (w obie strony) od wyniku ls: ls podaje rozmiar pliku (ile zawiera informacji lub ile zostało zadeklarowane że może jej zawierać), a du to ile zajmuje na dysku
* `df [opcje]` – wyświetlanie informacji o zajętości miejsca na poszczególnych systemach plików

Należy zwrócić uwagę iż komenda `find` potrafi sama rozwijać znaki uogólniające (w przypadku argumentów niektórych z jej) i w przypadku argumentów opcji takich jak np. `-name` na ogół chcemy aby znaki uogólniające nie były rozwijane przez powłokę, a interpretowane przez samą komendę `find` – w tym celu powinniśmy je zabezpieczyć przed rozwinięciem przy pomocy cudzysłowów. W przypadku określania katalogu startowego `find` zachowuje się jak inne komendy (np. `ls`) dla których znaki uogólniające musi rozwinąć powłoka. Na przykład jeżeli chcemy przeszukać wszystkie katalogi zaczynające się na *a* w poszukiwaniu plików zaczynających się na *b* to należy wykonać: `find a* -name "b*"`, a nie `find "a*" -name "b*"` czy też `find a* -name b*`, itd.

Warto zauważyć także, że jeżeli komanda `ls` w wyniku rozwinięcia znaków uogólniających dostanie jako argument ścieżkę do katalogu to wylistuje jego zawartość (zachowanie to zmienia opcja `-d`).

## kopiowanie, przenoszenie, usuwanie, ...

* `cp [opcje] źródło1 [źródło2 [...]] cel` – kopiuje wskazany plik (lub pliki) do wskazanej lokalizacji, w przypadku kopiowania wielu plików cel powinien być katalogiem, do ważniejszych opcji należy zaliczyć:
	* `-r` pozwala na (rekursywne) kopiowanie katalogów
	* `-a` podobnie jak `-r`, dodatkowo zachowując atrybuty plików
	* `-l` zamiast kopiować tworzy twarde dowiązania (hard links)
	* `-s` zamiast kopiować tworzy linki symboliczne do plików
	* `-f` nadpisywanie bez pytania
	* `-i` zawsze pytaj przed nadpisaniem
* `ln źródło1 [źródło2 [...]] cel` – tworzy link (domyślnie „twardy”) do wskazanego pliku (lub plików) w wskazanej lokalizacji, w przypadku wskazania wielu plików źródłowych cel powinien być katalogiem, do ważniejszych opcji należy zaliczyć:
	* `-s` tworzy dowiązania symboliczne (wskazujące na ścieżkę do oryginalnego pliku) zamiast twardych (wskazujących na te same dane co oryginalny plik)
	* `-r` używa ścieżki względnej zamiast bezwzględnej przy tworzeniu dowiązań symbolicznych
* `mv [opcje] źródło1 [źródło2 [...]] cel` – przenosi wskazane pliki / katalogi do wskazanej lokalizacji, w przypadku przenoszenia wielu plików cel powinien być katalogiem, do ważniejszych opcji należy zaliczyć:
	* `-f` nadpisywanie bez pytania
	* `-i` zawsze pytaj przed nadpisaniem
* `rm [opcje] ścieżka1 [ścieżka2 [...]]` – usuwa wskazane pliki, do ważniejszych opcji należy zaliczyć:
	* `-r` pozwala na na (rekursywne) kasowanie katalogów wraz z zawartością
	* `-f` usuwanie bez pytania
	* `-i` zawsze pytaj przed usunięciem
* `mkdir [opcje] ścieżka1 [ścieżka2 [...]]` – tworzy wskazane katalogi, do ważniejszych opcji należy zaliczyć:
	* `-p` pozwala na tworzenie całej ścieżki a nie tylko ostatniego elementu, nie zgłasza błędu gdy wskazany katalog istnieje

### zdalne kopiowanie

Najprostszą metą kopiowania plików pomiędzy różnymi systemami jest wykorzystanie do tego ssh, typowo robi się to na jeden z kilku sposobów:

* poleceniem `scp [opcje] źródło1 [źródło2 [...]] cel`, które kopiuje wskazany plik (lub pliki) do wskazanej lokalizacji, w przypadku kopiowania wielu plików cel powinien być katalogiem, do ważniejszych opcji należy zaliczyć:
	* `-r` pozwala na (rekursywne) kopiowanie katalogów
	* `-P port` określa port SSH
. W odróżnieniu od `cp` źródło lub cel w postaci ```[user@]host:[ścieżka]``` wskazują na zdalny system dostępny poprzez SSH.
* poleceniem `rsync [opcje] źródło cel` , które kopiuje (synchronizacjiuje) pliki i drzewa katalogów (zarówno lokalnie jak i zdalnie), do ważniejszych opcji należy zaliczyć:
	* `-r` pozwala na (rekursywne) kopiowanie katalogów
	* `-l` kopiuje linki symboliczne jako linki symboliczne (zamiast kopiowania zawartości pliku na który wskazują)
	* `-t` zachowuje czas modyfikacji plików
	* `-u` kopiuje tylko gdy plik źródłowy nowszy niż docelowy
	* `-c` kopiuje tylko gdy plik źródłowy i docelowy mają inne sumy kontrolne
	* `--delete` usuwa z docelowego drzewa katalogów elementy nie występujące w drzewie źródłowym
	* `-e 'ssh'` pozwala na kopiowanie na/z zdalnych systemów za pośrednictwem ssh, źródło lub cel w postaci ```[user@]host:[ścieżka]``` wskazują na zdalny system
	* `--partial --partial-dir=."-tmp-"` zachowuje skopiowane częściowo pliki w katalogu .-tmp- (pozwala na przerwanie i wznowienie transferu pliku)
	* `--progress` pokazuje postęp kopiowania
	* `--exclude="wzorzec"` pomija (w kopiowaniu i kasowaniu) pliki pasujące do wzorzec (wzorzec może zawierać znaki uogólniające powłoki)
	* `-n` symuluje pracę (pokazuje co zostałoby skopiowane, ale nie kopiuje)
* stosując `sshfs [opcje] host:scieżka` , który montuje zdalny system plików z użyciem FUSE (filesystem in userspace) oraz SSH, do ważniejszych opcji należy zaliczyć:
	* `-p port` określa inny niż domyślny port serwera SSH
	* `-o workaround=rename`, który zapewnia poprawne `mv` na istniejący plik
* złożonego polecenia opartego na przekierowaniu wyjścia jakiejś komendy do ssh, które uruchamia po zdalnej stronie proces odbierający te dane na swoim standardowym wejściu, np.:
	* `tar -czf - ścieżka1 [ścieżka2 [...]] | ssh [user@]host 'cat > plik.tgz'`
		archiwizuje wskazane pliki/katalogi bezpośrednio na zdalny system z użyciem tar i kompresji gzip do pliku `plik.tgz`
	* `tar -cf - ścieżka1 [ścieżka2 [...]] | ssh [user@]host 'tar -xf - -C cel'`
		kopiuje wskazane pliki/katalogi na zdalny system z użyciem tar do katalogu `cel`


Operacje na zawartości plików
-----------------------------

### grep i wyrażenia regularne

Polecenie `grep [opcje] wyrażenie [plik1 [plik2 [...]]]` wyszukuje pasujące do wyrażenia regularnego wyrażenie linie w plikach, przydatne opcje:

* `-v` zamiast pasujących wypisz nie pasujące
* `-i` ignoruj wielkość liter
* `-a` przetwarzaj pliki binarne jak tekstowe
* `-E` korzystaj z ,,*Extended Regular Expressions*'' (ERE) zamiast ,,*Basic Regular Expressions*'' (BRE)
* `-P` korzystaj z ,,*Perl-compatible Regular Expressions*'' (PCRE) zamiast ,,*Basic Regular Expressions*'' (BRE)
* `-r` rekursywnie przetwarzaj podane katalogi wyszukując w wszystkich znalezionych plikach
* `-R` jak -r, ale zawsze podąża za linkami symbolicznymi
* `--exclude="wyrażenie"` pomiń pliki pasujące do wyrażenie (może zawierać znaki uogólniające powłoki)
* `-l` wypisuje pliki z pasującymi liniami
* `-L` wypisuje pliki z bez pasujących linii
* `-f` wczytaj wyrażenia z podanego pliku
* `-e` może być użyta do poprzedzenia wyrażenia (przydatne zwłaszcza jeżeli chcemy podać kilka)

Wyrażenia regularne (podana składnia dotyczy „**Extended Regular Expressions**”, przy BRE niektóre z znaków sterujących wymagają zabezpieczenia odwrotnym ukośnikiem) konstruuje się w oparciu o następujące znaki specjalne:
```
.      - dowolny znak
[a-z]  - znak z zakresu
[^a-z] - znak z poza zakresu (aby mieć zakres z ^ należy dać go nie na początku)
^      - początek napisu/linii
$      - koniec napisu/linii

*      - dowolna ilość powtórzeń
?      - 0 lub jedno powtórzenie
+      - jedno lub więcej powtórzeń
{n,m}  - od n do m powtórzeń

()     - pod-wyrażenie (może być używane dla powtórzeń, a także referencji wstecznych)
|      - alternatywa: wystąpienie wyrażenia podanego po lewej stronie albo wyrażenia podanego prawej stronie
```

Występowanie przełączników `-E` i `-P` wiąże  się z ewolucją składni wyrażeń regularnych przy jednoczesnym zachowywaniu kompatybilności z poprzednimi wersjami polecenia grep.
Jeżeli  coś było traktowane jako zwykły znak nie mogło się tak po prostu stać znakiem specjalnym i należało zastosować zabezpieczanie przy pomocy odwrotnym ukośnikiem lub wybór innego wariantu składni przy pomocy odpowiedniej opcji. W efekcie `grep '^.\?*'` to to samo co `grep -E '^.?*'`, a `grep '^.?*'` to to samo co `grep -E '^.\?*'`.

## sed i inne narzędzia przetwarzania tekstów

* `sed [opcje] [pliki]` – edytuje plik zgodnie z podanymi poleceniami, przydatne opcje:
	* `-e "polecenie"` - wykonuj na pliku polecenie (może wystąpić wielokrotnie celem podania wielu poleceń)
	* `-f "plik"` - wczytaj polecenia z pliku plik
	* `-E` - używaj rozszerzonych wyrażeń regularnych
	* `-i` - modyfikuj podany plik zamiast wypisywać zmieniony na stdout
	* `-n` - wyłącza domyślne wypisywanie linii, wypisanie musi być wykonane jawnie poleceniem `p`
. przykładowe przydatne polecenia (sed jest dość rozbudowanym narzędziem stanowiącym praktycznie coś na kształt interpretera języka programowania (o trochę dziwnej składni) i nie ogranicza się jedynie do tych prostych przypadków):
	* `s@regexp@napis@[g]` - wyszukaj dopasowania do wyrażenia regularnego regexp i zastąp je przez napis, podanie opcji g powoduje zastępowanie wszystkich wystąpień a nie tylko pierwszego, znak `@` pełni rolę separatora i może zostać zamiast niego użyty inny znak
	* `y@zbiór1@zbiór2@` - zastąp znaki z zbiór1 znakami odpowiadającymi im pod względem kolejności znakami z zbiór2, znak `@` pełni rolę separatora i może zostać zamiast niego użyty inny znak
. możliwe jest też m.in. adresowanie linii na których ma być wykonywana operacja, np: `0,/regexp/ s@regexp@napis@` wykona polecenie s na liniach od początku pliku do linii pasującej do wyrażenia regularnego regexp, czyli zastąpi tylko pierwsze wystąpienie w pliku

* `tail [opcje] [plik]` – wyświetla ostatnie linie pliku, przydatne opcje:
	* `-n x` określa że ma zostać wyświetlone x ostatnich linii
	* `-f` uruchamia dopisywania (gdy do pliku zostaną dopisane nowe linie tail je wyświetli)
* `head [opcje] [plik]` – wyświetla początkowe linie pliku, przydatne opcje:
	* `-n x` określa że ma zostać wyświetlone x pierwszych linii

* `diff ścieżka1 ścieżka2` – porównuje pliki lub katalogi (w przypadku tych drugich porównuje ze sobą pliki o takich samych nazwach oraz zgłasza fakt występowania pliku tylko w jednym z katalogów), przydatne opcje:
	* `-r` rekursywnie przetwarzaj podane katalogi
	* `-u` wypisuje różnice w formacie "unified"
	* `-c` wypisuje różnice w formacie "context"
* `vimdiff ścieżka1 ścieżka2` – porównuje pliki wyświetlając je jeden obok drugiego (podobnie jak `diff` z opcją `-y`), pozwalając jednak na edycję tych plików
* `patch` – stosuje plik łaty (wynik diff'a) w celu zmodyfikowania plików, typowo:
	`patch -pn < plik.diff` co powoduje zastosowanie zmian opisanych w plik.diff na plikach w bieżącym katalogu,
	n określa ilość poziomów ścieżek podanych w pliku łaty które mają zostać zignorowane

* `sort [plik]` – sortuje linie w wskazanym pliku, przydatne opcje:
	* `-n` traktuj liczby jako wartości numeryczne a nie napisy
	* `-i` ignoruj wielkość liter
	* `-r` odwróć kolejność sortowania
	* `-k n` sortuj wg kolumny n
	* `-t sep` kolumny rozdzielane są przy pomocy separatora sep
* `uniq` – usuwa powtarzające się linie z posortowanego pliku, przydatne opcje:
	* `-c` wypisz liczbę powtórzeń
	* `-d` wypisz tylko linie z 2 lub więcej wystąpieniami
	* `-u` wypisz tylko linie z 1 wystąpieniem

* `cut [opcje] [pliki]` – wybiera z pliku zadany zestaw kolumn, przydatne opcje:
	* `-f nnn` wypierz kolumny określone przez nnn (np. 1,3-4,6- oznacza kolumnę 1, kolumny od 3 do 4 i od 6, a -3 oznacza 3 pierwsze kolumny)
	* `-d sep` kolumny rozdzielane są przy pomocy separatora sep (musi być pojedynczym jedno bajtowym znakiem, aby ominąć to ograniczenie należy skorzystać z awk)
* `paste` – łączy (odpowiadające sobie pod względem numerów) linie z dwóch plików
* `join` – łączy linie  z dwóch plików w oparciu o porównanie wskazanego pola
* `comm` – porównuje dwa posortowane pliki pod względem unikalności linii (może wypisać wspólne lub występujące tylko w jednym z plików)


Sygnały i skróty klawiszowe
---------------------------

### kill

Polecenie `kill` domyślnie wysyła sygnał `SIGTERM`, który jest prośbą o zakończenie procesu (proces może ją uszanować lub nie, np. zignorować). Więc sam `kill` nie zabija procesu.

Wiele sygnałów może zostać przechwyconych i obsłużonych (zignorowanych) przez proces do którego są adresowane. Istnieją także sygnały, które nie mogą zostać obsłużone bądź zignorowane są to m.in.:
	`SIGKILL` (zakończenie procesu bez dania mu jakiejkolwiek szansy zrobienia czegoś na „do widzenia”, wysyłany przez `kill -9`),
	`SIGSTOP` (wstrzymanie procesu).


### Ctrl+C / Ctrl+Z / Ctrl+D

**Ctrl+C** wysyła sygnał `SIGINT` do procesu zajmującego terminal na którym został on wprowadzony. Sygnał ten jest prośbą o zakończenie procesu, którą proces może uszanować lub nie (np. może całkiem zignorować lub poprosić o potwierdzenie). Jest on podobny do `SIGTERM`, jednak jest innym sygnałem i może być inaczej obsłużony (np. w `SIGTERM` nie ma większego sensu pytać o potwierdzenie).

**Ctrl+Z** wysyła sygnał `SIGTSTP` do procesu zajmującego terminal na którym został on wprowadzony. Sygnał ten jest prośbą o wstrzymanie procesu i oddanie terminala, prośba ta może być zignorowana przez proces. Proces przerwany w ten sposób może być wznowiony poleceniem `fg` (które wznowi go jako pierwszoplanowy – okupujący terminal) lub `bg` (które wznowi go jako jako proces w tle – oddając terminal, przodkowi który go posiadał wcześniej).

**Ctrl+D** nie wysyła żadnego sygnału, działa tylko gdy proces czyta dane z terminala (podłączonego zazwyczaj do jego standardowego wejścia). Wysyła on do terminala znak EOT (End-of-Transmission), w efekcie czego:

* (jeżeli bufor wejściowy jest niepusty) terminal wypycha bufor wejściowy do programu (tak jak po wprowadzeniu nowej linii), albo
* (jeżeli nie ma znaków w buforze) terminal zamyka strumień wprowadzanych danych do programu

Program nie otrzymuje w strumieniu znaku EOT (jest on przechwycony przez terminal).
Zamknięcie strumienia wejściowego na ogół prowadzi także do zakończenia działania programu, jednak (w odróżnieniu od Ctrl-C) pozwala programowi na normalne przetworzenie wprowadzonych danych.

### Ctrl+S / Ctrl+Q

**Ctrl+S** wstrzymuje przewijanie (odświeżanie) terminala, aby wznowić należy użyć **Ctrl+Q**.
