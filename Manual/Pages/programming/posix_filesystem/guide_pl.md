<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: MOVIE+PDF merged, extended
-->

System plików
=============

System plików ma strukturę hierarchiczną (drzewiastą) i rozpoczyna się w korzeniu oznaczanym ukośnikiem: `/`. Wchodząc w jego podkatalogi, ich podkatalogi i tak dalej, możemy dojść do dowolnego pliku w systemie. Zapisując nazwy katalogów przez które przechodziliśmy i rozdzielając je od siebie oraz od nazwy pliku przy pomocy ukośników tworzymy bezwzględną ścieżkę do danego pliku, czyli taką która właśnie rozpoczyna się od tego korzenia.

Możliwe jest wyrażanie wszystkich ścieżek od korzenia, jednak nie zawsze jest to wygodne. W wielu wypadkach chcemy móc wyrazić ścieżkę względem jakiegoś innego katalogu i w tym celu stosuje się ścieżki względne. Katalogiem względem którego, wyrażana jest ścieżka względna może być katalog, w którym znajduje się obiekt ją zawierający lub, znacznie częściej, jest to tak zwany bieżący katalog roboczy.

## Katalog roboczy

Interpreter poleceń taki jak *bash* potrafi znajdować się gdzieś w tej strukturze plików i miejsce to nazywane jest bieżącym katalogiem roboczym (*Present Working Directory*). Względem niego będą wyrażane ścieżki nie zaczynające się od korzenia, może być też oznaczony jawnie przy pomocy pojedynczej kropki.

Bieżący katalog roboczy (*Present Working Directory*) jest określany niezależnie dla każdego z działających programów. Typowo pierwotna jego wartość jest ustawiana na bieżący katalog roboczy powłoki która uruchomiła dany program. Może być on zmieniony przez działający program przy użyciu odpowiedniej funkcji systemowej.

W przypadku powłoki zgodnej z `sh` informację o jej bieżącym katalogu roboczym możemy wypisać przy pomocy polecenia `pwd`. Często jest ona także podawana przed znakiem zachęty. Natomiast zmiany tego katalogu możemy dokonać przy pomocy polecenia `cd`, po którym podawana jest ścieżka do katalogu który ma być ustawiony jako katalog roboczy. W ten sposób zmienimy katalog względem którego będą interpretowane ścieżki względne w danej powłoce i w programach przez nią uruchamianych po wykonaniu polecenia `cd`. Zmiana ta nie wpłynie na uruchomione wcześniej i nadal działające w tle programy.

## Ścieżki względne

Ścieżką względną jest dowolna ścieżka nie zaczynająca się od korzenia, czyli nie rozpoczynająca się od ukośnika.

Zarówno w ścieżkach bezwzględnych jak i względnych można użyć pojedynczej kropki (`.`) oznaczającej aktualny katalog w ścieżce oraz dwóch kropek (`..`) oznaczających katalog nadżędny. W ścieżkach bezwględnych są one jednak zawsze nadmiarowe i dlatego żadko spotykane, natomiast w ścieżkach względnych pełnią bardzo istotną rolę. Dwie kropki (`..`) użyte odpowiednio wiele razy (z rozdzielającym je `/`) pozwalają wrócić ścieżką względną z dowolnego katalogu nawet aż do korzenia, a zatem dojść także do dowolnego innego pliku w naszym drzewie.

Pojedyncza kropka (`.`) użyteczna jest praktycznie jedynie na początku ścieżki (gdzie oznacza katalog względem którego jest interpretowana ścieżka względna, na przykład bieżący katalog roboczy). Nierzadko jest używana nawet jako cała ścieżka do aktualnego katalogu.

Sama nazwa pliku lub katalogu również stanowi ścieżkę względną (względem katalogu w którym się on znajduje), niekiedy jednak stosowany jest zapis kropka ukośnik nazwa pliku (`./nazwa`), który pozwala na bardziej jednoznaczne zasugerowanie iż mamy na myśli ścieżkę a nie jakąś nazwę. Dotyczy to zwłaszcza uruchamiania programów znajdujących się w bieżącym katalogu, gdyż w tym wypadku nazwa polecenia nie zawierająca ukośnika nie jest traktowana jako ścieżka.

## Pliki ukryte

Pliki (i katalogi) których nazwy zaczynają się od kropki (`.`) traktowane są jako pliki ukryte i nie będą domyślnie pokazywane przez niektóre z programów.

## Linki

Linki są odniesieniami do jakiś plików, z użyciem innej ścieżki / nazwy. Wyróżnia się dwa ich typy – link twardy (*hard link*) i link symboliczny (*symbolic link*).

[img]Manual/Pages/programming/posix_filesystem/links_pl.svg[/img]

**Link twardy** jest innym dowiązaniem na te same dane na dysku twardym. Mamy tutaj kilka poziomów dostępu do danych znajdujących się na dysku twardym – fizyczną lokalizację tych danych gdzieś na dysku, coś co można by w uproszczeniu nazwać uchwytem do takich danych (nazywany i-node), oraz wpis w katalogu, który określa nazwę pliku i odnośnik go odpowiedniego uchwytu (i-node'a).

Link twardy `link1.txt`, pokazany ilustracji zaznaczony kolorem czerwonym, utworzony komendą `ln plik2.txt link1.txt`, stanowi po prostu kolejne dowiązanie do tych samych danych do których dowiązaniem był `plik2.txt`. Jest on równoprawny oryginalnemu dowiązaniu do tych danych, czyli:

* modyfikacja danych z jego pomocą zmieni wspólne dane na które wskazują oba dowiązania, zatem będzie widoczna także poprzez nazwę `plik2.txt`, podobnie w drógą stronę - modyfikacja dokonana za pomocą `plik2.txt` będzie widoczna przy dostępie poprzez nazwę `link1.txt`
* może być używany (i zapewnia dostęp do danych) także po skasowaniu oryginalnego pliku, dane zostaną usunięte (a dokładniej oznaczone jako do nadpisania) w momencie gdy ten liczba odwołań do nich spadnie do zera

Liczbę dowiązań do danego pliku pokazuje m.in. komenda `ls` z opcją `-l`. Warto także zwrócić uwagę na wpisy związane z kropką i dwiema kropkami – są to automatycznie tworzone dowiązania typu link twardy odpowiednio do katalogu bieżącego i nadrzędnego. Liczba dowiązań do `.` to 2 plus liczba podkatalogów, a liczba dowiązań do `..` równa jest liczbie dowiązań do kropki w katalogu nadrzędnym. 

Ze względu na taką naturę linków twardych ograniczają się one do pojedynczego systemu plików (urządzenia) na którym znajdują się dane. Typowo nie jest również dopuszczalne tworzenie linków twardych do katalogów.

**Link symboliczny** wskazuje na konkretną ścieżkę (względną lub bezwzględną – co może mieć znaczenie przy przenoszeniu takiego linku) do dowolnego (nawet nie istniejącego – wtedy mówimy o zerwanym linku) pliku lub katalogu. Dzięki takim cechom linki te mogą wskazywać na pliki położone na innych urządzeniach, systemach plików. Linki symboliczne możemy tworzyć do dowolnych obiektów w systemie plików – także katalogów.

Link symboliczny, pokazany ilustracji zaznaczony kolorem niebieskim, stanowi wpis w strukturze katalogu informujący że pod daną nazwą (w tym przykładzie `link2.txt`) jest odniesienie do innej ścieżki (w tym przykładzie `./plik1.txt`). Jest on w istocie odniesieniem do innej ścieżki, a nie danych na dysku jako takich.

Link symboliczny funkcjonuje podobnie do linku twardego, zapewniając dostęp do tych samych danych przez dwie różne ścieżki.

Dla obiektów typu link symboliczny polecenie ls będzie pokazywać typ pliku `l` a podawany rozmiar wynika z długości przechowywanej ścieżki – tyle danych zawiera sam link symboliczny. Zajętość dysku (podawana przez `du`) dla linku symbolicznego będzie wynosiła zero, gdyż sam link nie zajmuje osobnego miejsca na dysku, a jedynie zwiększa rozmiar zajmowany przez strukturę opisującą katalog.

Należy mieć świadomość, iż w przypadku linków symbolicznych nie mamy takiego podobieństwa linku do obiektu na który wskazuje ten link, jak w przypadku linków twardych. W przypadku linków symbolicznych, usunięcie pliku na który wskazywał link, czy też nawet zmiana lokalizacji bądź nazwy takiego pliku, prowadzi do tego że link symboliczny staje się linkiem zerwanym i tracimy dostęp do danych z wykorzystaniem tego linku. Jeżeli plik na który wskazywał link zostanie skutecznie usunięty, czyli nie będzie ani tego pliku ani linków twardych do niego to dane też zostaną usunięte, bez względu na to czy już wskazywały na nie jakieś linki symboliczne, czy nie.

Należy mieć także świadomość iż:
* ścieżki względne zapisane w linku nie są interpretowane względem bieżącego katalogu roboczego, czy nawet katalogu użytego w ścieżce dostępu do linku
a względem katalogu w którym znajduje się link
* polecenie `ln` (używane do tworzenia linków) standardowo zapisze do tworzonego linku literalnie podaną w linii poleceń ścieżkę. Oznacza to że możemy tworzyć linki symboliczne do nieistniejących plików, ale też przez pomyłkę możemy utworzyć błędne dowiązania.

## Znaki uogólniające

W napisie opisującym ścieżkę możemy także umieścić pewne znaki specjalne, pozwalające na uogólnienie takiej ścieżki, tak aby opisywała wiele plików lub plik, którego pewnych szczegółów położenia/nazwy nie chcemy określić jednoznacznie. Tymi snakami specjalnymi są znaki uogólniające powłoki (*glob*):

* `?` oznacza dowolny znak
* `*` oznacza dowolny (także pusty) ciąg znaków
* ```[a-z AD]``` oznacza dowolny znak z wymienionych w zbiorze ujętym w nawiasach kwadratowych, zbiór może być definiowany z użyciem zakresów, np. a-z AD oznacza dowolną małą literę od a do z włącznie, spację, dużą literą A lub D
* ```[!a-z]``` oznacza dowolny znak z wyjątkiem znaków wymienionych w podanym zbiorze, zbiór może być definiowany z użyciem zakresów, np. a-z oznacza dowolną małą literę od a do z włącznie

Na przykład:

* `a[0-9]/*` oznacza wszystkie (nieukryte) pliki i katalogi znajdujące się wewnątrz katalogów których nazwa jest dwuznakowa, gdzie pierwszym znakiem jest `a` a kolejnym cyfra.
* ```[^ad]*``` oznacza wszystkie (nieukryte) pliki i katalogi w bieżącym katalogu których nazwa nie zaczyna się na literę a lub d
* `.[!.]*` oznacza wszystkie ukryte pliki i katalogi w bieżącym katalogu (z wyjątkiem odwołania do katalogu bieżącego i nadrzędnego

**Uwaga:** Znaki uogólniające rozwijane są (t.j. zamieniane na listę pasujących ścieżek) przez powłokę. A jedynie w przypadku braku dopasowań przekazywane w niezmienionej postaci do uruchamianego programu. Niektóre programy oczekują jednak otrzymania i operowania na znakach uogólniających. Niekiedy też chcemy przekazać jako argument jakiegoś polecenia coś co ścieżką nie jest a zawiera któreś z tych znaków. W obu wypadkach dla poprawnego działania polecenia niezależnie od ewentualnego istnienia pasujących plików ciąg zawierający te znaki należy zabezpieczyć cudzysłowami lub apostrofami (ew. użyć odwrotnych ukośników do zabezpieczenia tych znaków).

## Katalog domowy

Często w ścieżkach stosowana jest też tylda (`~`) oznaczająca katalog domowy aktualnego użytkownika lub tylda po której występuje nazwa użytkownika (`~nazwa`) oznaczająca katalog domowy wskazanego użytkownika. Mianem katalogu domowego określa się katalog przeznaczony na przechowywanie plików użytkownika (zarówno indywidualnej konfiguracji programów, jak i plików przez niego tworzonych bądź gromadzonych) określony w konfiguracji konta danego użytkownika.

Podobnie jak przy znakach uogólniających jeżeli mamy potrzebę przekazania tyldy wśród argumentów programu należy zabezpieczyć ją przed interpretacją jako znak specjalny z użyciem cudzysłowów, apostrofów lub odwrotnego ukośnika.
