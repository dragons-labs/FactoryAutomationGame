<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
--> 

Podstawowe polecenia powłoki
============================

Użytkownicy, uprawnienia i procesy
----------------------------------

### Uprawnienia do plików

Podstawowe unixowe uprawnienia do plików składają się z trzech członów: uprawnienia dla właściciela (u), grupy (g) i pozostałych użytkowników (o).
W każdym z członów mogą być przyznane uprawnienia do czytania (r), pisania (w) i wykonywania (x); w odniesieniu do plików jest to intuicyjne (uprawnienie do wykonywania jest potrzebne do uruchomienia programów), natomiast w stosunku do katalogów wygląda to następująco: uprawnienia do czytania pozwalają na listowanie zawartości, do wykonania pozwalają na dostęp, do zawartości katalogu (wejścia do niego) do pisania na tworzenie nowych obiektów wewnątrz niego i zmienianie nazw istniejących.

Rozszerzeniem podstawowych uprawnień opisanych powyżej jest mechanizm Filesystem Access Control List (ACL, fACL).\\
Jest on opcjonalnym mechanizmem który (na wspierających go systemach plików) pozwala na definiowanie indywidualnych uprawnień do pliku dla poszczególnych użytkowników i grup – plik ma nadal swojego właściciela, grupę i wszystkich pozostałych, ale przed prawami dla "others" wchodzą prawa użytkowników i grup definiowanych w ACL. Wypadkowe prawa obliczane są jako suma wynikła z praw użytkownika i grup do których należy.\\
ACL pozwala ponadto definiować uprawnienia domyślne dla nowo powstałych plików w katalogu (są one opcją katalogu).

Wszystkie poniższe komendy przyjmują opcję `-R` powodującą rekursywne wykonywanie zmian na drzewku katalogów/plików rozpoczynającym się w podanej ścieżce.

* `chown [opcje] właściciel ścieżka` – zmiana właściciela pliku
* `chgrp [opcje] grupa ścieżka` – zmiana grupy do której należy plik pliku
* `chmod [opcje] uprawnienia ścieżka` – zmiana prawa dostępu do pliku(ów)

* `getfacl [opcje] [ścieżka]` – odczyt uprawnień związanych z listami kontroli dostępu fACL
* `setfacl [opcje] [ścieżka]` – ustawianie uprawnień związanych z listami kontroli dostępu fACL

Dodatkowo należy wspomnieć też o poleceniach takich jak:

* `lsattr` / `chattr` – wyświetla / modyfikuje atrybuty plików związanych z systemem plików (np. zabrania jakiejkolwiek modyfikacji pliku)
* `getcap` / `setcap` – wyświetla / modyfikuje atrybuty plików związanych z właściwościami jądra (zasadniczo zwiększonymi uprawnieniami programów je posiadających, ale bardziej ograniczonymi niż wykonanie na prawach root przez SUID)


### Użytkownicy

* `id [użytkownik]` – informacja o użytkowniku (m.in. grupy do których należy)
* `whoami` – informacja o aktualnym użytkowniku
* `w lub who` – informacja o zalogowanych użytkownikach

* `passwd [użytkownik]` – zmiana hasła

* `su [użytkownik]` – przełącza użytkownika (aby przełączony użytkownik miał dostęp do "naszego" x serwera wcześniej wydajemy `xhost LOCAL:użytkownik`)
* `sudo` – program pozwalający na wykonywanie uprzywilejowanych komend przez wyznaczonych użytkowników


### Procesy i zasoby

* `ps [opcje]` – wyświetla aktualnie działające procesy i informacje o nich\\ np. kombinacja opcji `-Af` powoduje wyświetlenie wszystkich procesów w rozszerzonym formacie wypisywania

* `top` – monitorowanie procesów obciążających CPU, pamięć, itd
* `iotop` – monitorowanie procesów obciążających I/O

* `kill [opcje] pid` – przesyła sygnał do procesów o podanych PID
* `killall [opcje] nazwa` – przesyła sygnał do procesów o pasującej nazwie


Inne polecenia
--------------

Oprócz opisanych wcześniej najpopularniejszych / najistotniejszych poleceń istnieje wiele innych standardowych lub mniej standardowych (wymagających doinstalowania na wielu systemach) narzędzi linii poleceń. Poniżej wymienionych zostało kilka bardziej użytecznych przykładów.

Ponadto dowolny program w środowisku linuxowym (unixowym) może być uruchomiony z linii poleceń poprzez podanie jego nazwy (jeżeli jest w ścieżce wyszukiwania `$PARTH`) lub pełnej ścieżki do niego.
W bardzo wielu przypadkach takie uruchamianie pozwala przekazać do niego argument w postaci pliku do otwarcia lub inne opcje, czy nawet użycie programu normalnie pracującego z graficznym interfejsem użytkownika (takiego jak blender, inkscape, ...) w trybie nie interaktywnym (np. do automatycznej konwersji, itp.).

* `date` – data i czas, program ten potrafi także przeliczać datę i czas - np. `date -d @847103830 '+%Y-%m-%d %H:%M:%S'`, `date -d '1996-11-04 11:37:10' '+%s'`, `date -d '1996-11-04 11:37:10 +3week -2days'`
* `cal` – kalendarz
* `wget` / `curl` – pobieranie stron internetowych i plików
* `file` – rozpoznaje typ pliku (w oparciu o zawartość)
* `convert` – konwersje plików graficznych

* `iconv` – konwersje kodowań plików tekstowych
* `konwert` – konwersje kodowań plików tekstowych – zarówno pomiędzy różnymi kodowaniami danego zbioru znaków, jak też pomiędzy kodowaniami nie pokrywającymi się czy też kodowaniami znaków 8 bitowych na mniejszej ilości bitów, na przykład:
	* `konwert utf8-ascii` "inteligentnie" usunie znaki nie ascii z pliku kodowanego w utf-8 (np. znaczki z polskimi ogonkami zamieni na odpowiednie znaki ASCII bez tych ogonków);//
	* `konwert qp-8bit` pozwoli zamienić kodowanie quoted printable na normalne 8 bitowe (rtf-8bit zrobi to z kodowaniem rtf'u)

* `mewencode` / `mewdecode` – program (stanowiący część pakieu narzędzi dodatkowych dla kilenta pocztowego Mew) do obsługi kodowań mime (w tym Quoted-Printable, base64), m.in. zmienia kodowanie base64 na 8 bitowe
* `qprint` – program do kodowania i dekodowania "Quoted-Printable"
* `base64` – program do kodowania i dekodowania base64
* `strings` – wypisuje sekwencje znaków drukowanych (określanie zawartości plików nietekstowych)

* `command -v  komenda` – zwraca wykonywaną ścieżkę / polecenie przy wykonywaniu `komenda`


### Planowanie zadań

Typowo system zapewnia usługę uruchamiania zadań o zadanym czasie. Z usługi tej można skorzystać przy pomocy poleceń:

* `crontab` pozwala oglądać i edytować tablice zaplanowanych zadań cyklicznych (dla cron'a)
* `at` pozwala jednorazowo zaplanować zadanie

Pliki konfiguracyjne crona / obsługiwane crontab-em mają postać: `minuty godzina  dzienMiesiaca miesiac dzienTygodnia polecenie`. Wpis oznacza że polecenie ma zostać wykonane jeżeli wszystkie warunki będą spełnione, jeżeli jakiś warunek nie jest nam potrzebny można użyć gwiazdki `*`, z kolei `*/n` oznacza wykonywanie jeżeli dana wartość jest podzielna przez n. Np.: `*/20 3  * * 1 ls` oznacza wykonanie komendy ls w każdy poniedziałek o godzinie 3:00 3:20 i 3:40

Standardowe wyjście, wyjście błędu oraz powiadomienie o niezerowym kodzie powrotu domyślnie są wysyłane na lokalny adres mailowy użytkownika będącego właścicielem danego contaba. Niekiedy dostępny jest także `anacron` pozwalający na mniej precyzyjne planowanie zadań.


Struktura katalogów
-------------------

Systemy unix'owe posiadają drzewiasty system plików zaczynający się w katalogu głównym oznaczanym przez ukośnik (`/`), w którym zamontowany jest główny system plików (rootfs), inne systemy plików mogą być montowane w kolejnych katalogach. Do najistotniejszych katalogów należy zaliczyć:

* `/bin` – zawierający pliki wykonywalne podstawowych programów
* `/sbin` – zawierający pliki wykonywalne podstawowych programów administracyjnych
* `/lib` – zawierający pliki podstawowych bibliotek
* `/usr` – zawierający oprogramowanie dodatkowe (wewnętrznie ma podobną strukturę do głównego - tzn. katalogi `/usr/bin`, `/usr/sbin`, `/usr/lib`, itd)
* `/etc` – zawierający konfiguracje ogólnosystemowe
* `/var` – jający dane programów i usług (takie jak kolejka poczty, harmonogramy zadań, bazy danych)
* `/home` – zawierający katalogi domowe użytkowników (często montowany z innego systemu plików, dlatego też root ma swój katalog domowy w `/root`, aby był dostępny nawet gdy takie montowanie nie doszło do skutku)
* `/tmp` – zawierający pliki tymczasowe (typowo czyszczony przy starcie systemu); w Linuxie występuje też `/run` przeznaczony do trzymania danych tymczasowych działających usług takich jak numery pid, blokady, itp
* `/dev` – zawierający pliki reprezentujące urządzenia; w Linuxie występuje też `/sys` zawierający informacje i ustawienia dotyczące m.in. urządzeń
* `/proc` – zawierający informacje o działających procesach (w Linuxie także interfejs konfiguracyjny dla wielu parametrów jądra)

Z punktu widzenia programisty czy też użytkownika (prawie) wszystko jest plikiem, których istnieją różne rodzaje (zwykły plik, katalog, urządzenie znakowe, urządzenie blokowe, link symboliczny, kolejka FIFO, ...); pewnym wyjątkiem są urządzenia sieciowe (które nie mają reprezentacji w systemie plików (ale gniazda związane z nawiązanymi połączeniami obsługuje się zasadniczo tak jak pliki).
