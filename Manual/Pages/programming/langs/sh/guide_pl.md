<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Podstawy programowania w powłoce „sh”
=====================================

Uruchamianie kodu
-----------------

Kod shellowy może być tworzony i wykonywany w linii poleceń interpretera. Dłuższe fragmenty kodu shellowego często wygodniej jest pisać w pliku tekstowym niż bezpośrednio w linii poleceń. Plik taki może zostać wykonany przy pomocy polecenia: `./nazwa_pliku` pod warunkiem że ma prawo wykonalności (powinien także zawierać w pierwszą linii komentarz określający program używany do interpretacji tekstowego pliku wykonywalnego, w postaci: `#!/bin/bash` dla bash'a lub odpowiednio dla innych odmian sh). Może też być wykonany za pomocą wywołania: `bash nazwa_pliku`, `zsh nazwa_pliku`, `sh nazwa_pliku` zaleznie jakiej powłoki chcemy użyć.

Przydatną alternatywą dla powyższych metod wykonania kodu zawartego w pliku jest włączenie go do aktualnej sesji basha przy pomocy `. ./nazwa_pliku`.
W odróżnieniu od poprzednich metod kod zostanie wykonany w bieżącej instancji powłoki. Pozwala to na korzystanie z funkcji i zmiennych zdefiniowanych w tym pliku w kolejnych poleceniach.

### Skrypty

Plik zawierający polecenia powłoki określany jest mianem skryptu. Wykonywanie skryptu powłoki rozpocznie się od pierwszej jego linii. Skrypt może przyjmować dowolną ilość parametrów pozycyjnych. Ilość parametrów znajduje się w zmiennej `$#`, lista wszystkich parametrów w `$@`, a do kolejnych parametrów możemy odwoływać się z użyciem `$1`, `$2`, itd.

```bash
#!/bin/bash

echo "wywołano z $# argumentami, argumenty to: $@"
echo "pierwszy argument to $1"

# skrypt może zwracać tylko wartość numeryczną -- tzw kod powrotu
exit 0
```

Powyższy kod po zapisaniu w pliku skrypt.sh być uruchomiony poprzez `bash skrypt.sh argumnet_A agrument_B`.

* tekst tekst od `#` do końca linii stanowi komentarz, czyli informacje dla programisty (np. opis działania algorytmu) ignorowane przez kompilator
	* komentarz w pierwszej linii rozpoczynający się od `!` jest komentarzem sterującym określającym program który ma być użyty do interpretacji kodu z pliku tekstowego
* polecenie `echo` wypisuje tekst określony w argumentach na standardowe wyjście
* słowo kluczowe `exit` kończy działanie skryptu i ustawia kod powrotu, stosowanie jej na końcu skryptu (jak w tym przykładzie) nie jest obowiązkowe


Dokumentacja
------------

Informację na temat komend będących osobnymi programami można uzyskać w wbudowanym systemie pomocy przy pomocy poleceń `man` lub `info` / `pinfo`. Na temat poleceń wbudowanych bash przy pomocy polecenia `help` (np. `help while`), a w przypadku zsh poprzez `man zshbuiltins`.


Zmienne
-------

Określanie typów zmiennych w bashu odbywa się na podstawie wartości znajdującej się w zmiennej. Zasadniczo wszystkie zmienne są napisami, a interpretacja typu ma miejsce przy ich użyciu (a nie przy tworzeniu). Obsługiwane są liczby całkowite oraz napisy, bash nie posiada wbudowanej obsługi liczb zmiennoprzecinkowych.

```bash
zmiennaA=-91
zmiennaB="qa   z"
zmiennaC=98.6 # to będzie traktowane jako napis a nie liczba
```
Brak spacji pomiędzy nazwą zmiennej a znakiem równości jest wymogiem składniowym. Wynika to ze znaczenia spacji w składni powłoki. Spacja oddziela nazwy poleceń i argumenty od siebie, czyli pełni istotną funkcję składniową, odpowiadającą nawiasom okrągłym i przecinkom, używanym do oddzielania nazwy funkcji i argumentów od siebie, z wielu innych języków programowania.

Odwołanie do zmiennej odbywa się z użyciem znaku dolara (`$`), po którym występuje nazwa zmiennej. Nazwa może być ujęta w klamry, ale nie musi (jest to przydatne gdy nie chcemy dawać spacji pomiędzy nazwą zmiennej a np. fragmentem napisu). Rozwijaniu ulegają nazwy zmiennych znajdujące się w napisach umieszczonych w podwójnych cudzysłowach. Umieszczenie odwołania do zmiennej w podwójnych cudzysłowach zabezpiecza białe znaki (spacje nowe linie) przy przekazywaniu do funkcji i programów (w tym przy przekazywaniu do echo, celem wypisywania).

```bash
echo  $zmiennaA ${zmiennaA}AA
echo "$zmiennaA ${zmiennaA}AA"
echo '$zmiennaA ${zmiennaA}AA'
```

### Zmienne środowiskowe

Jeżeli chcemy aby zmienna była widoczna przez programy uruchamiane z tej powłoki (w tym przez kolejne instancje bash'a, odpowiedzialne np. za wykonywanie kodu skryptu uruchamianego z pliku) należy ją wyeksportować za pomocą polecenia `export zmiennaA`. Do polecenia przekazujemy nazwę zmiennej a nie jej wartość, więc nie używamy znaku dolara. Taka zmienna jest dostępna jako zmienna środowiskowa dla wszystkich potomków tej powłoki.

Zmienne środowiskowe mogą być także ustawiane bez użycia `export` dla pojedynczego nowego programu poprzez podanie ich nazw i wartości przed nazwą polecenia:

```bash
ABCD=678 bash -c 'echo $ABCD'
ABCD=135 EFG=098 bash -c 'echo $ABCD $EFG'
echo $ABCD
```

Są one jedynie widoczne w tak uruchomionym procesie potomnym (nie mogą być użyte w bieżącej powłoce, czy jako jako argumenty w linii poleceń). Dlatego w powyższych przykładach wywoływana jest nowa powłoka która korzysta z tak ustawionych zmiennych. Takie ustawianie zmiennych jest szczególnie przydatne gdy chcemy uruchomić pojedyncze polecenie w zmienionym środowisku - np. polecenie date w innej strefie czasowej: `TZ=America/New_York date`

### printf

Do wypisywania wartości zmiennych może być użyte także polecenie `printf` będące odpowiednikiem funkcji języka C o tej samej nazwie:

```bash
x=13.123
printf "%.2f\n" $x
```

### zmienna nie zdefiniowana

Odwołaniu do nie zdefiniowanej zmiennej nie zgłaszane jako błąd, taka zmienna ma wartość napisu pustego.

```bash
echo "AAA $niezdefiniowana BBB"
```

Należy jednak pamiętać że taki napis pusty będzie inaczej traktowany gdy znajduje się wewnątrz cudzysłowów a inaczej gdy nie (wtedy jest pomijany jako argument poleceń).

```bash
printf "> %s < %s\n" $niezdefiniowana BBB
printf "> %s < %s\n" "$niezdefiniowana" BBB
```

Podstawowe operacje
-------------------

Aby wykonać działania arytmetyczne należy umieścić je wewnątrz `$((` i `))` Dodawanie, mnożenie, odejmowanie zapisuje się i działają one tak jak w normalnej matematyce, dzielenie zapisuje się przy pomocy ukośnika i jest ono zawsze dzieleniem całkowitym:

```bash
a=12; b=3; x=5; y=6

e=$(( ($a + $b) * 4 - $y ))
c=$((  $x / $y ))

echo $e $c
```

Do operacji arytmetycznych może być też jest wykorzystywane polecenie `let`. Najczęściej jest stosowane do inkrementacji podanej zmiennej, tak jak w poniższym przykładzie.

```bash
echo $a
let a++
echo $a
```

Zarówno operator podwójnych nawiasów okrągłych jak i komenda `let` mogą obsługiwać wyrażenia logiczne. Mimo to operacje logiczne najczęściej obsługiwane są komendą `test` lub operatorem ```[ ]``` wynik zwracany jest jako *kod powrotu*. Należy zwrócić uwagę na escapowanie odwrotnym ukośnikiem nawiasów i na to że spacje mają znaczenie. Negację realizuje `!`, należy pamiętać jednak że wynikiem negacji dowolnej liczby jest FALSE.

```bash
a=12; b=3; c=4

[ \( $a -ge 0 -a $b -lt 2 \) -o $c -eq 5 ]; z=$?

echo $z
```

Wartość zmiennej `z` jest wynikiem warunku: `((a większe równe od zera) AND (b mniejsze od dwóch)) OR (c równe 5)`. Został on zwrócony jako *kod powrotu*, który jest dostępny (dla ostatnio wykonanego polecenia) poprzez `$?`. Wartość tej zmiennej została przypisana do zmiennej `z`. Kody powrotu stosują logikę odwróconą 0 oznacza prawdę, coś nie zerowego to fałsz.


### wykonywanie innych programów

Jako operacje podstawowe powinniśmy patrzyć także na wykonanie innych programów i pobieranie ich standardowego wyjścia i/lub kodu powrotu. Pobieranie standardowego wyjścia możemy realizować za pomocą ujęcia polecenia w *backquotes* lub operatora `$( )` (pozwala on na zagnieżdżanie takich operacji). Natomiast kod powrotu ostatniej komendy znajduje się w zmiennej `$?`.

```bash
a=`cat /etc/issuse`
b=$(cat /etc/issuse; cat /etc/resolv.conf)

echo  $a
echo  $b
echo "$b"
```

Zwróć uwagę na różnicę w wypisaniu zmiennej zawierającej znaki nowej linii objętej cudzysłowami i nie objętej nimi.

Bash nie obsługuje liczb zmiennoprzecinkowych, nieobsługiwane operacje można wykonać za pomocą innego programu np:

```bash
a=`echo 'print(3/2)' | python3`
b=$(echo '3/2' | bc -l)
echo $a $b
```

Programowanie w powłoce w dużej mierze polega na wywoływaniu innych programów (np. takich jak sed, grep, find, awk). Sama powłoka oferuje jedynie podstawowe konstrukcje składniowe, obsługę zmiennych i pewnych podstawowych operacji na nich.

Na te zewnętrzne polecenia można patrzeć trochę jak na biblioteki w innych językach programowania – komendy gwarantowane przez standard stanowią „bibliotekę standardową” basha, a inne (np. użyty w powyższym przykładzie arytmetyki zmiennoprzecinkowej python) stanowią dodatkowe opcjonalne „biblioteki”, które pozwalają na łatwiejsze i szybsze rozwiązywanie problemów. W zasadzie podobnie można patrzeć na wywołania zewnętrznych programów w ramach kodu Pythona, C czy innych języków (niekiedy łatwiej jest zrobić np. `system("mv plik nowyplik")` niż zakodować to bezpośrednio w Pythonie czy w C).


Pętle i warunki
---------------

### Pętla for

W bashu możemy korzystać z kilku wariantów pętli for. Jednym z najczęściej używanych jest przypadek iterowania po liście elementów, najczęściej liście plików:

```bash
for nazwa in /tmp/* ; do
	echo $nazwa;
done
```

Możliwe jest też iterowanie po wartościach całkowitych zarówno w stylu „shellowym” jak i w stylu C

```bash
for i in `seq 0 20`; do
	echo $i;
done

for (( i=0 ; $i<=20 ; i++ )) ; do
	echo $i;
done
```

### Pętla while

Pętla wile powtarzana jest dopóki podany w niej warunek jest prawdziwy:

```bash
x=0
while [ $x -le 2 ]; do
	echo $x;
	x=$(($x+1));
done
```

### while - read

Często używana jest pętla while w połączeniu z instrukcją `read` co umożliwia przetwarzanie jakiegoś wejścia (wyniku komendy lub pliku) linia po linii (także z podziałem linii na słowa):

```bash
cat /etc/fstab | while read slowo reszta; do
	echo $reszta;
done
```

Powyższa pętla wypisze po kolei wszystkie wiersze pliku `/etc/fstab` przekazanego przez stdin (przy pomocy komendy `cat`) z pominięciem pierwszego słowa (które wczytywane było do zmiennej slowo).

Polecenie `read` można także wykorzystać do wczytania danych podawanych przez użytkownika do jakiejś zmiennej – np. `read -p "wpisz coś >> " xyz` wczyta tekst do zmiennej `xyz`. `read` z opcją `-e` potrafi korzystać z biblioteki readline, jednak np. współdzieli historię z historią basha. Dlatego często wygodniejsze może być zainstalowanie i użycie `rlwrap`, np: `xyz=$(rlwrap -H historia.txt -S "wpisz coś >> " head -n1)`.

#### martwe koty

Przekazanie danych do *while-read* poprzez strumień stdout → stdin z innego programu jest często stosowane np. w celu przefiltrowania lub posortowania danych przekazywanych do tej pętli. Jednak użycie w tym rozwiązaniu `cat` jest nadmiarowe (nazywane jest *martwym kotem*) i powinno się go unikać. Lepszym rozwiązaniem jest przekazywanie pliku przez przekierowanie strumienia wejściowego przy pomocy `< plik`, który w tym przypadku powinien znaleźć się za kończącym pętle słowem kluczowym `done`. Między innymi oszczędza ono zasoby (i czas wykonania) związany z tworzeniem dodatkowego procesu dla polecenia `cat`.

#### przekierowania strumieni a zmienne

Przekierowanie standardowego wyjścia na standardowe wejście odbywa się między dwoma różnymi procesami. Zatem w konstrukcjach typu *while-read* pętla while uruchamiana może być w procesie potomnym obecnej powłoki. Efektem tego jest iż w niektórych przypadkach wykonywane modyfikacje zmiennych wewnątrz takiej pętli nie będą widoczne poza nią.

Przykładem takiej sytuacji jest poniższy kod (polecenie ps dodano aby pokazać utworzenie procesu potomnego powłoki):

```bash
zm=0; ps -f
cat /etc/fstab | while read x; do
	[ $zm -lt 1 ] && ps -f
	zm=13
done
echo $zm
```

Jednak analogiczny kod w którym następuje przekierowanie z pliku zadziała poprawnie:

```bash
zm=0; ps -f
while read x; do
	[ $zm -lt 1 ] && ps -f
	zm=13
done < /etc/fstab
echo $zm
```

Jeżeli do pętli ma trafić wyjście jakiegoś polecenia możemy użyć składni bash'a pozwalającej na podstawienie wyniku polecenia jako pliku w postaci `<(polecenie)` wraz z przekierowaniem z pliku, na przykład:
```bash
zm=0; ps -f
while read x; do
	[ $zm -lt 1 ] && ps -f
	zm=13
done < <$(cat /etc/fstab)
echo $zm
```

Zauważ spację pomiędzy dwoma znakami `<` i brak spacji pomiędzy drugim `<` i znakiem dolara).

Inną możliwością jest użycie kodu powrotu do odebrania wartości z wnętrza pętli:
```bash
zm=0; ps -f
my_code() {
	while read x; do
		[ $zm -lt 1 ] && ps -f
		zm=13
	done;
	return $zm;
}
cat /etc/fstab | my_code
zm=$?
echo $zm
```

Została tu zdefiniowana funkcja (`my_code`), o których więcej informacji znajdziesz w odpowiednim rozdziale poniżej.

#### separator słów

Słowa domyślnie rozdzielane są przy pomocy dowolnego ciągu spacji lub tabulatorów. Separator ten można zmienić za pomocą zmiennej `IFS`, np:

```bash
IFS=":"
while read a b c; do echo "$a -- $c"; done < /etc/passwd
unset IFS # przywracamy domyślne zachowanie read poprzez usunięcie zmiennej IFS
```
Należy mieć na uwadze, że cudzysłów wokół wypisania zmiennej c są istotne – bez nich znak dwukropka mógłby być zmieniony na spacje.

Zamiast modyfikowania wartości zmiennej IFS możemy ustawić wartość tej zmiennej środowiskowej dla pojedynczego wywołania programu (polecenia `read`):

```bash
while IFS=":" read a b c; do echo "$a -- $c"; done < /etc/passwd
```


### Instrukcja if

Poznane wcześniej obliczanie wartości wyrażeń logicznych najczęściej stosowane jest w instrukcji warunkowej `if`.

```bash
# instruikcja if - else
if [ "$xx" = "kot" -o "$xx" = "pies" ]; then
	echo  "kot lub pies";
elif [ "$xx" = "ryba" ];  then
	echo  "ryba"
else
	echo  "coś innego"
fi
```

Zauważ że spacje wokół i wewnątrz nawiasów kwadratowych przy warunku są istotne składniowo, zawartość nawiasów kwadratowych to tak naprawdę argumenty dla komendy `test`. Oprócz typowych warunków logicznych możemy sprawdzać np. istnienie plików, czy też ich typ (link, katalog, etc). Szczegółowy opis dostępnych warunków które mogą być użyte w tej konstrukcji znajduje się w `man test`.

Jako warunek może wystąpić dowolne polecenie wtedy sprawdzany jest jego kod powrotu 0 oznacza prawdę / zakończenie sukcesem, a wartość nie zerowa fałsz / błąd

```bash
if grep '^root:' /etc/passwd > /dev/null; then
	echo /etc/passwd zawiera root-a;
fi
```

Istnieje możliwość skróconego zapisu warunków z użyciem łączenia instrukcji przy pomocy `&&` (wykonaj gdy poprzednia zwróciła zero -- true) lub `||` (wykonaj gdy poprzednia zwróciła nie zero -- false):

```bash
[ -f /etc/issuse ] && echo "jest plik /etc/issuse"

grep '^root:' /etc/passwd > /dev/null && echo /etc/passwd zawiera root-a;
```

### Instrukcja case

Instrukcja `case` służy do rozważania wielu przypadków opartych na równości zmiennej z podanymi napisami.

```bash
case $xx in
	kot | pies)
		echo  "kot lub pies"
		;;
	ryba)
		echo  "ryba"
		;;
	*)
		echo  "cos innego"
		;;
esac
```



Funkcje
-------

W powłoce `sh` każda funkcja może przyjmować dowolną ilość parametrów pozycyjnych (w identyczny sposób obsługiwane są argumenty linii poleceń dla całego skryptu). Ilość parametrów znajduje się w zmiennej `$#`, lista wszystkich parametrów w `$@`, a do kolejnych parametrów możemy odwoływać się z użyciem `$1`, `$2`, itd.

```bash
f1() {
	echo "wywołano z $# parametrami, parametry to: $@"
	
	[ $# -lt 2 ] && return;
	
	echo -e "drugi: $2\npierwszy: $1"
	
	# albo kolejnych w pętli
	for a in "$@"; do  echo $a;  done
	
	# lub z użyciem polecenia shift
	for i in `seq 1 $#`; do
		echo $1
		shift # powoduje zapomnienie $1
		      # i przenumerowanie argumentów pozycyjnych o 1
		      # wpływa na wartości $@ $# itp
	done
	
	# funkcja może zwracać tylko wartość numeryczną -- tzw kod powrotu
	return 83
}
```

Zwróć uwagę że w nawiasach po nazwie funkcji nie podajemy przyjmowanych argumentów, natomiast puste nawiasy te są elementem składniowym i muszą wystąpić. Jeżeli zapisujesz definicję funkcji w jednej linii, np. `abc() { echo "abc"; }` to pamiętaj, że spacja po otwierającym nawiasie klamrowym jest obowiązkowa, podobnie jak średniki występujące po każdej (także ostatniej) instrukcji w ciele funkcji.

Wywołanie funkcji nie różni się niczym od wywołania programów czy instrukcji wbudowanych
(możemy używać przekierowań strumieni wejścia, wyjścia, czy też przechwycić wyjście do zmiennej). Powyższą funkcję możemy wywołać np. w następujący sposób: `f1 a "b c"   d`

### Grupowanie poleceń

Funkcje są przykładem grupowania poleceń – funkcja stanowi nazwany blok kodu, czyli nazwaną grupę poleceń. Polecenia możemy też grupować bez definiowania funkcji. W tym celu możemy zastosować nawiasy klamrowe (tak jak w definicji funkcji) lub nawiasy okrągłe.

Stosując nawiasy klamrowe musimy pamiętać (tak samo jak było to w przypadku funkcji) o spacji po otwierającym nawiasie klamrowym i średniku (lub nowej linii) przed zamykającym. Instrukcje podane w nawiasach klamrowych będą wykonane w bieżącej powłoce, czyli mogą modyfikować zmienne.

Polecenia podane w nawiasach okrągłych będą wykonane w podpowłoce, czyli ustawione lub zmodyfikowane w nich zmienne nie będą widoczne po zakończeniu bloku. Nawiasy okrągłe nie wymagają spacji i ostatniego średnika.

```bash
a=0;
{ echo abc; a=1; }
echo $a
(echo abc; a=2)
echo $a
```

Grupowanie poleceń jest przydatne na przykład w celu grupowania ich przy używaniu operatorów łączenia poleceń w oparciu o kod powrotu (`&&` i `||`), a także w celu przekazania standardowego wyjścia wielu poleceń w ramach jednego strumienia.

```bash
a=0;
{ echo AbC; echo abc; echo XyZ; a=1; } | grep b
echo $a
```

Zauważ że w tym wypadku nawiasy klamrowe zachowały się jak nawiasy okrągłe – modyfikacja zmiennej a nie jest widoczna po zakończeniu bloku. Wynika to z użycia przekierowania strumienia podobnie jak w sytuacji omawianej przy pętli while.


Napisy
------

### grep, cut, sed, ...

Jako że większość operacji wykonywanych w powłoce takiej jak bash wiąże się z uruchamianiem zewnętrznych programów, to także przetwarzanie napisów może być realizowane w ten sposób. Opiera się na tym jedno z podejść do obsługi napisów w bashu, którym jest korzystanie z standardowych komend POSIX, takich jak `grep`, `cut`, `sed`.

```bash
# obliczanie długości napisu w znakach, w bajtach i ilości słów w napisie
echo -n "aąbcć 123" | wc -m
echo -n "aąbcć 123" | wc -c
echo -n "aąbcć 123" | wc -w

# obliczanie ilości linii (dokładniej ilości znaków nowej linii)
wc -l < /etc/passwd

# wypisanie 5 pola (rozdzielanego :) z pliku /etc/passwd  z eliminacją
# pustych linii oraz linii złożonych tylko ze spacji i przecinków
cut -f5 -d: /etc/passwd | grep -v '^[ ,]*$'
# komenda cut wybiera wskazane pola, opcja -d określa separator
```

Inną bardzo przydatną komendą jest sed pozwala ona m.in na zastępowanie wyszukiwanego na podstawie wyrażenia regularnego tekstu innym:

```bash
echo "aa bb cc bb dd bb ee" | sed -e 's@\([bc]\+\) \([bc]\+\)@X-\2-X@g'
```

Sedowe polecenie s przyjmuje 3 argumenty (oddzielane mogą być dowolnym znakiem który wystąpi za `s`), pierwszy to wyszukiwane wyrażenie, drugi tekst którym ma zostać zastąpione, a trzeci gdy jest `g` to powoduje zastępowanie wszystkich wystąpień a nie tylko pierwszego.

Należy zwrócić uwagę na różnicę w składni wyrażenia regularnego polegającą na poprzedzaniu `(`, `)` i `+` odwrotnym ukośnikiem aby miały znaczenie specjalne (jeżeli nie chcemy tego robić możemy włączyć obsługę ERE w sed poprzez opcję `-E`).

Innymi przydatnymi komendami przetwarzającymi (specyficznej postaci) napisy są polecenia `basename` i `dirname`. Służą one do uzyskania nazwy najgłębszego elementu ścieżki oraz ścieżki bez tego najgłębszego elementu. Zobacz wynik działania:

```bash
basename /proc/sys/net/core/
dirname /proc/sys/net/core/
```

### Wbudowane przetwarzanie napisów w bash'u

Wbudowane przetwarzanie napisów w bashu opiera się na odwołaniach do zmiennych w postaci `${}`:


* `${zmienna:-"napis"}` zwróci napis gdy zmienna nie jest zdefiniowana lub jest pusta
* `${zmienna:="napis"}` zwróci napis oraz wykona podstawienie zmienna="napis" gdy zmienna nie jest zdefiniowana lub jest pusta
* `${zmienna:+"napis"}` zwróci napis gdy zmienna jest zdefiniowana i nie pusta
* `${#str}`    zwróci długość napisu w zmiennej str
* `${str:n}`   zwróci pod-napis zmiennej str od n do końca
* `${str:n:m}` zwróci pod-napis zmiennej str od n o długości m
* `${str/"n1"/"n2"}`  zwróci wartość str z zastąpionym pierwszym wystąpieniem n1 przez n2
* `${str//"n1"/"n2"}`  zwróci wartość str z zastąpionymi wszystkimi wystąpieniami n1 przez n2
* `${str#"ab"}` zwróci wartość str z obciętym "ab" z początku
* `${str%"fg"}` zwróci wartość str z obciętym "fg" z końca
* `${!x}` zwróci wartość zmiennej, której nazwa jest w zmiennej x

W napisach do obcięcia możliwe jest stosowanie shellowych znaków uogólniających, czyli `*`, `?`, ```[abc]```, itd operator `#` i `%` dopasowują minimalny napis do usunięcia, natomiast operatory `##` i `%%` dopasowują maksymalny napis do usunięcia.
Należy pamiętać że wiele z powyższych zapisów jest rozszerzeniami basha niedostępnymi w podstawowej składni sh.

Przykład:

```bash
a=""; b=""; c=""
echo ${a:-"aa"} ${b:="bb"} ${c:+"cc"}
echo $a $b $c

a="x"; b="y"; c="z"
echo ${a:-"aa"} ${b:="bb"} ${c:+"cc"}
echo $a $b $c

x=abcdefg
echo ${#x} ${x:2} ${x:0:3} ${x:0:$((${#x}-2))}
echo ${x#"abc"} ${x%"efg"}
echo ${x#"ac"}  ${x%"eg"}

x=abcd.e.fg
echo ${x#*.} ${x##*.} ${x%.*} ${x%%.*}

y="aa bb cc bb dd bb ee"
echo ${y/"bb"/"XX"}
echo ${y//"bb"/"XX"}
```


### awk

Awk jest interpreterem prostego skryptowego języka umożliwiający przetwarzanie tekstowych baz danych postaci *linia == rekord*, gdzie pola oddzielane ustalonym separatorem (można powiedzieć że łączy funkcjonalność komend takich jak grep, cut, sed z prostym językiem programowania).

Wyżej zaprezentowane wypisanie 5 pola (rozdzielanego dwukropkiem) z pliku `/etc/passwd`  z eliminacją pustych linii oraz linii złożonych tylko ze spacji i przecinków, realizowane przy użyciu poleceń `cut` i `grep` może być zrealizowane za pomocą samego awk:

```bash
awk -F: '$5 !  "^[ ,]*$" {print $5}' /etc/passwd
```

Awk daje duże możliwości przy przetwarzaniu tego typu tekstowych baz danych -- możemy np. wypisywać wypisywać pierwsze pole w oparciu o warunki nałożone na inne:

```bash
awk -F: '$5 !  "^[ ,]*$" && $3 >= 1000 {print $1}' /etc/passwd
```

Jak widać w powyższych przykładach do poszczególnych pól odwołujemy się poprzez `$n`, gdzie `n` jest numerem pola, `$0` oznacza cały rekord

Program dla każdego rekordu przetwarza kolejne instrukcje postaci `warunek { komendy }`, instrukcji takich może być wiele w programie (przetwarzane są kolejno), komenda `next` kończy przetwarzanie danego rekordu.

Separator pola ustawiamy opcją `-F` (lub zmienną `FS`), domyślnym separatorem pola jest dowolny ciąg spacji i tabulatorów (w odróżnieniu od cut separator może być wieloznakowym napisem lub wyrażeniem regularnym). Domyślnym separatorem rekordu jest znak nowej linii (można go zmienić zmienną `RS`).

Awk jest prostym językiem programowania obsługującym podstawowe pętle i instrukcje warunkowe oraz funkcje wyszukujące i modyfikujące napisy:

`echo "aba aab bab baa bba bba" | awk '`
```awk
	# dla każdego pola w rekordzie
	for (i=1; i<=NF; ++i) {
		# jeżeli jego numer jest parzysty
		# to zastąp wszystkie ciągi b pojedynczym B
		if (i%2==0)
			gsub("b+", "B", $i);
		
		# wyszukaj pozycję pod-napisu B
		ii = index($i, "B")
		# jeżeli znalazł
		# to wypisz pozycję i pod-napis od tej pozycji do końca
		if (ii)
			printf("# %d %s\n", ii, substr($i, ii))
		# zwróć uwagę że w AWK liczy elementy napisy od 1 a nie od 0
	}
	print $0
```
`'`

AWK obsługuje także tablice asocjacyjne pozwala to np. policzyć powtórzenia słów:

`echo "aa bb aa ee dd aa dd" | awk '`
```awk
	BEGIN {RS="[ \t\n]+"; FS=""}
	{slowa[$0]++}
	# może być kilka bloków {} pasujących do rekordu
	# jeżeli nie użyjemy next przetworzone zostaną wszystkie
	# {printf("rekord: %d done\n", NR)}
	END {for (s in slowa) printf("%s: %s\n", s, slowa[s])}
```
`'`

Podobny efekt możemy uzyskać stosując "uniq -c" (który wypisuje unikalne wiersze wraz z ich ilością) na odpowiednio przygotowanym napisie (spacje zastąpione nową linią, a linie posortowane):

```bash
echo "aa bb aa ee dd aa dd" | tr ' ' '\n' | sort | uniq -c
```

Jednak rozwiązanie awk można łatwo zmodyfikować aby wypisywało pierwsze wystąpienie linii bez sortowania pliku.

Innym użytecznym zastosowaniem AWK może być wypisanie pliku bez linii pasujących do wzorca oraz linii poprzednich:

`echo -e "aa\nbb\nWZORZEC\ncc" | awk'`
```awk
	# dla linii pasującej do wzorca ustawiamy flagę print_last na zero i przechodzimy do następnej linii
	/WZORZEC/ {print_last=0; next}
	# jeżeli flaga print_last jest nie zero wypisujemy zapamiętaną poprzednią linię
	print_last == 1 {print last}
	# zapamiętujemy bieżacą linię do wypisania przy przetwarzaniu kolejnej (jeżeli nie będzie pasować do wzorca)
	{last=$0; print_last=1}
	# jeżeli osiągneliśmy koniec pliku i mamy linię do wypisania to ją wypisujemy
	END {if (print_last == 1) print last}
```
`'`

AWK pozwala także na definiowanie funkcji:
```bash
awk 'function f(x) {return 2*x} { print f($1+$2) }'
```
