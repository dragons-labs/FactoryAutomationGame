<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: NEW, VIP
-->

Podstawy programowania w C
==========================

Kompilacja
----------

Programy w C wymagają kompilacji i konsolidacji, celem zamiany kodu źródłowego na kod wykonywalny. W środowisku linuxowym tym celu możemy skorzystać z jednego z kilku dostępnych kompilatorów (zauważ że w każdym przypadku podstawowa składnia jest taka sama):

* Domyślnego kompilatora C (zazwyczaj jeden z poniższych): `cc -o plik_wykonywalny plik_zrodlowy.c`
* Tiny C Compiler: `tcc -o plik_wykonywalny plik_zrodlowy.c`
* kompilatora C z GNU Compiler Collection: `gcc -o plik_wykonywalny plik_zrodlowy.c`
* clang i LLVM: `clang -o plik_wykonywalny plik_zrodlowy.c`

W każdym wypadku powstanie plik wynikowy o nazwie określonej w opcji `-o` polecenia (`plik_wykonywalny`), który uruchomić możemy poleceniem: `./plik_wykonywalny`

### Wiele plików źródłowych

Jeżeli program składa się z wielu plików źródłowych możemy wymienić je wszystkie w poleceniu (np. `cc -o plik_wykonywalny plik_zrodlowy_1.c plik_zrodlowy_2.c plik_zrodlowy_3.c`), jednak lepszym (szybszym i dużo częściej stosowanym) podejściem jest rozdzielenie kompilacji poszczególnych plików i konsolidacji całego programu na osobne etapy – np. (zauważ opcję -c):

```sh
cc -o plik_wynikowy_1.o -c plik_zrodlowy_1.c
cc -o plik_wynikowy_2.o -c plik_zrodlowy_2.c
cc -o plik_wynikowy_3.o -c plik_zrodlowy_3.c

cc -o plik_wykonywalny plik_wynikowy_1.o plik_wynikowy_2.o plik_wynikowy_3.o
```

Dzięki temu kompilacja musi być powtarzana jedynie dla zmodyfikowanych plików.


Pierwszy program
----------------

### Punkt startu programu

Wykonywanie programu stworzonego w C rozpocznie się od funkcji **main**. W ramach całego programu (nieważne czy zapisanego w jednym czy w wielu plikach) musi być dokładnie jedna funkcja `main`. Zakończenie tej funkcji oznacza zakończenie programu, a wartość przez nią zwracana odpowiedzialna jest za **kod powrotu** przekazany procesowi wywołującemu program.

### Kod programu

```C
#include <stdio.h> /* plik nagłówkowy zawierający deklarację funkcji puts */
int main() {
	puts("Hello from C"); // wywołanie funkcji puts wypisującej teskt na standardowe wyjście
	return 0; // kod powrotu ustawiony na zero = sukces
}
```

* tekst ujęty pomiędzy `/*` a `*/` oraz teksty od `//` do końca linii stanowi komentarz, czyli informacje dla programisty (np. opis działania algorytmu) ignorowane przez kompilator
* definicja funkcji rozpoczyna się od typu zwracanego (w wypadku funkcji *main* jest to `int`, czyli liczba całkowita), po którym (po spacji) następuje nazwa funkcji, następnie nawiasy okrągłe zawierające listę argumentów (w tym przykładzie puste) a następnie kod funkcji
* kod funkcji, a także innych bloków kodu, ujmowany jest w nawiasy klamrowe ({` i `}`)
* do oddzielania kolejnych poleceń używany jest średnik `;`
* słowo kluczowe `return` kończy działanie funkcji i ustawia wartość zwracaną
* komenda preprocesora `#include` służy do dołączania treści innego pliku, w tym wypadku dołączany jest plik nagłówkowy biblioteki standardowej języka C zawierający deklaracje funkcji związanych z obsługą standardowego wejścia i wyjścia


Dokumentacja
------------

Biblioteka standardowa C opisana jest w rozdziałach 2 i 3 manuala systemowego. W rozdziale 2 opisane są wywołania systemowe, a w rozdziale 3 pozostałe elementy biblioteki standardowej C. Zatem wykonując komendę `man 3 printf` zapoznamy się z dokumentacją funkcji `printf`.


Zmienne
-------

```C
#include <stdio.h>
int main() {
	char bajt = 13;
	int calkowita = 12345;
	double zmiennoprzecinkowa = 13.111;
	
	printf("%d %x %d %f\n", bajt, bajt, calkowita, zmiennoprzecinkowa);
	
	return 0;
}
```

* deklaracja zmiennej składa się z typu zmiennej i jej nazwy
* definicja zmiennej oprócz tego zawiera przypisanie wartości
* podstawowe typy zmiennych to:
	* liczby całkowite zależne od architektury:
		* ze znakiem - takie jak: `char`, `short`, `int`, `long`, `long long`
		* bez znaku - takie jak `unsigned char`, `unsigned short`, `unsigned int`, `unsigned long`, `unsigned long long`
		* ilośc bitów (a zatem też obsługiwany zares wartości) takiej liczby zależna jest od architektury/kompilatora, standard określa jedynie minimalną wielkość np. 16 bitów dla typu `int`, choć ten najczęściej ma 32 bity
	* liczby całkowite o uslonej ilosci bitów (mogą wymagać nagłówka `stdint.h`):
		* ze znakiem - takie jak: `int8_t`, `int16_t`, `int32_t`,`int64_t`
		* bez znaku - takie jak: `uint8_t`, `uint16_t`, `uint32_t`,`uint64_t`
	* liczby zmiennoprzecinkowe - takie jak: `float`, `double`
* odwołanie do zmiennej następuje poprzez jej nazwę
*  niezainicjalizowane zmienne mogą mieć dowolną wartość

### printf

Do wypisywania wartości zmiennych może być użyta funkcja `printf` z biblioteki standardowej (z nagłówka `stdio.h`).

* w pierwszym argumencie przyjmuje ona napis formatujący zawierający ciągi rozpoczynające się od znaku procenta (`%`) pod które będą podstawiane wartości kolejnych zmiennych
* ciąg znaków po `%` określa sposób wypisywania, np.:
	* `%d` - liczba całkowita typu `int` wypisana dziesiętnie
	* `%x` - liczba całkowita bez znaku wypisana szesnastkowo
	* `%f` - liczba zmiennoprzecinkowa
	* `%s` - napis
* może on określać też sposób wypisania liczby, np:
	* `%3d` - całkowita rezerwująca 3 miejsca (dopełnianie spacjami od przodu)
	* `%03d` - całkowita rezerwująca 3 miejsca (dopełnianie zerami wiodącymi)
	* `%.2d` - zmiennoprzecinkowa z dwoma miejscami po kropce
	* `%6.2d` - zmiennoprzecinkowa z dwoma miejscami po kropce, rezerwująca 6 miejsc (wliczając kropkę i miejsca po kropce)


Tablice
-------

```C
#include <stdio.h>
int main() {
	int tablica[3]; // tablica 3 elementowa liczb całkowitych
	
	tablica[0] = 13; // do elementów tablicy odwołujemy się z użyciem [],
	                 // elementy tablicy indeksujemy od zera
	tablica[2] = 17;
	
	printf("%d %d\n", tablica[0], tablica[1]);
	// nie zainicializowane elementy (tak samo jak nie zainicjalizowane zmienne) będą mieć przypadkową wartość
	// (nie jest to jednak dobre źródło losowości)
	
	return 0;
}
```

* tablica jest to zbiór zmiennych tego samego typu, do których odwołujemy się korzystając z nazwy zmiennej tablicowej i indeksu
* definicja tablicy określa jej rozmiar (ilość elementów), C nie pilnuje przechodzenia poza zakres tablicy - jest to odpowiedzialność programisty
	* w powyższym przykładzie odwołanie się do np. piątego elementu tablicy nie zostanie wykryte przez kompilator jako błąd i może (ale nie musi) powodowć błąd naruszenia ochrony pamięci w trakcie działania programu
* elementy tablicy indeksujemy od zera

## tablice zmiennej długości

Język C od wersji C99 pozwala na korzystanie z tablic zmiennej długości (*VLA*), czyli tablic których rozmiar nie jest stałą czasu kompilowania a zmienną - np.:

```c
void xxx(int n) {
    float vals[n];
    v[0] = 21;
    /* ... */
}
```


Operacje arytmetyczne
---------------------

Podstawowe operacje arytmetyczne realizowane są z użyciem operatorów zapisywanych pomiędzy argumentami, czyli w taki sposób jak wygląda zapis matematyczny.

* dodawanie: `+` np. `int a = 3 + 2;` (zmienna `a` będzie miała wartość 5)
* odejmowanie: `-` np. `int a = 3 - 2;` (zmienna `a` będzie miała wartość 1)
* mnożenie: `*` np. `int a = 3 * 2;` (zmienna `a` będzie miała wartość 6)
	* w C mnożenie zawsze musi być zapisane z użyciem znaku mnożenia (operatora), znany z matematyki zapis [i]3a[/i] jako [i]3 * a[/i] nie jest dopuszczalny
	* możliwe i stosowane jest dodanie znaku `-` przed nazwą zmiennej celem odwrócenia jej znaku (pomnożenia przez -1), np. `int b = -a;`
* dzielenie: `/` np. `int a = 3 / 2; float b = 3 / 2; float c = 3.0 / 2;` (zmienna `a` będzie miała wartość 1, tak samo `b`, natomiast `c` będzie miało 1.5 bo jest zmiennoprzecinkowym wynikiem dzielenia w którym jeden z argumentów jest zmiennoprzecinkowy)
	* w C typ dzielenia (całkowite lub zmiennoprzecinkowe) zależy od typów argumentów)
* reszta z dzielenia: `%` np. `int a = 3 % 2;` (zmienna `a` będzie miała wartość 1)

Zachowywana jest kolejność działań, a operacje mogą być grupowane przy pomocy nawiasów okrągłych `(` i `)`, np. `int a = 3 + 2 * 2` ustawi wartość zmiennej `a` na 7, natomiast `int a = (3 + 2) * 2` ustawi wartość zmiennej `a` na 10.


```c
#include <stdio.h>

int main() {
	double a = 12.7, b = 3, c, d, e;
	int x = 5, y = 6, z;
	
	// dodawanie, mnożenie, odejmowanie zapisuje się
	// i działają one tak jak w normalnej matematyce:
	e = (a + b) * 4 - y;
	
	// dzielenie zależy od typów argumentów
	d = a / b; // będzie dzieleniem zmiennoprzecinkowym bo a i b są typu float
	c = x / y; // będzie dzieleniem całkowitym bo z i y są zmiennymi typu int
	b = (int)a / (int)b; // będzie dzieleniem całkowitym
	a = (double)x / (double)y; // będzie dzieleniem zmiennoprzecinkowym
	
	// reszta z dzielenia (tylko dla argumentów całkowitych)
	z = x % y;
	
	// wypisanie wyników
	printf("%d %f %f %f %f %f\n", z, e, d, c, b, a);
	
	// uwaga: powyższy program może nie wykonywać obliczeń w czasie działania
	// ze względu na optymalizację i fakt iż wyniki wszystkich operacji
	// są znane w momencie kompilacji programu
```


Operacje logiczne i bitowe
--------------------------

Operacje logiczne i bitowe są operacjami działającymi w algebrze Boole'a. W przypadku operacji logicznych są one wykonywane na poziomie całej zmiennej (czyli to cała wartość zmiennej odpowiada logicznej jedynce lub logicznemu zeru). Natomiast operacje bitowe wykonywane sa na poszczególnych bitach zmiennych będących argumentami operacji, czyli bity na pozycji zero obu argumentów dają wynik w bicie na pozycji zero zmiennej wynikowej, bity na pozycjach jeden dają wynik na pozycji jeden itd.

```c
#include <stdio.h>

int main() {
	// operacje logiczne:
	// ((a większe równe od 0) AND (b mniejsze od 2)) OR (z równe 5)
	z = (a>=0 && b<2) || z == 5;
	// negacja logiczna z
	x = !z;
	
	printf("%d %d\n", z, x);
	
	// operacje binarne:
	// bitowy OR 0x0f z 0x11 i przesunięcie wyniku o 1 w lewo
	x = (0x0f | 0x11) << 1;
	// bitowy XOR 0x0f z 0x11
	y = (0x0f ^ 0x11);
	// negacja bitowa wyniku bitowego AND 0xfff i 0x0f0
	z = ~(0xfff & 0x0f0);
	
	printf("%x %x %x\n", x, y, z);
	
	// uwaga: powyższy program może nie wykonywać obliczeń w czasie działania
	// ze względu na optymalizację i fakt iż wyniki wszystkich operacji
	// są znane w momencie kompilacji programu
}
```

Argumenty linii poleceń
-----------------------

Argumenty linii poleceń (w tym nazwa pod którą został uruchomiony program) przekazywne są do funkcji main jako dwa argumenty:

* liczba całkowita określająca ilość argumentów, typowo nazywany *argc*
* tablica napisów, typowo nazywany *argv*

```C
#include <stdio.h>
int main(int argc, char *argv[]) {
	printf("%d %s\n", argc, argv[0]);
	return 0;
}
```


Pętle i warunki
---------------

```C
#include <stdio.h>

int main(int argc, char *argv[]) {
	int i = 1, j = argc, k = 4;
	
	// instrukcja waunkowa if - else
	if (i<j) {
		puts("i<j");
	} else if (j<k) {
		puts("i>=j AND j<k");
	} else {
		puts("i>=j AND j>=k");
	}
	
	// podstawowe operatory logiczne
	if (i<j || j<k)
		puts("i<j OR j<k");
	// innymi operatorami logicznymi są && (AND), ! (NOT)
	
	// pętla for
	for (i=2; i<=9; ++i) {
		if (i==3) {
			// pominięcie tego kroku pętli
			continue;
		}
		if (i==7) {
			// wyjście z pętli
			break;
		}
		printf(" a: %d\n", i);
	}
	
	// pętla while
	while (i>0) {
		printf(" b: %d\n", --i);
	}
	
	// pętla do - while
	do {
		printf(" c: %d\n", ++i);
	} while (i<2);
	
	// instrukcja wyboru switch
	switch(i) {
		case 1:
			puts("i==1");
			break;
		default:
			puts("i!=1");
			break;
	}
}
```


Funkcje
-------

```C
#include <stdio.h>

// funkcja bezargumentowa niezwracająca wartości
void f1() {
	puts("ABC");
}

// funkcja dwuargumentowa zwracająca wartość
int f2(int a, int b) {
	return a*2.5 + b;
}

// funkcja z jednym argumentem obowiązkowym i jednym opcjonalnym
float f3(int a, int b=1) {
	puts("F3");
	return a*2.5 + b;
}

int main() {
	f1();
	
	int a = f2(3, 6);
	// zwracaną wartość można wykorzystać (jak wyżej) lub zignorować:
	f3(0);
	
	printf("%d\n", a);
}
```

Napisy
------

Napisy w języku C są tablicami bajtów (tablicami typu `char`) zakończonymi bajtem o wartości zero (NULL), będącym znacznikiem końca napisu.

```C
#include <stdio.h>
#include <string.h>

int main() {
	// napisy w stylu C
	// czyli tak naprawdę tablice bajtów (znaków)
	const char* x = "abcdefg";
	
	// wypisanie długości napisu
	printf("%d\n", strlen(x));
	
	// wypisanie pod-napisu od 2 do końca
	puts(x+2);
	
	// wyszukiwanie
	// pod-napisu "cd" w x od pozycji 1
	const char* cd = strstr(x+1, "cd");
	printf("%d\n", cd-x);
	
	// 3 znakowy pod-napis napisu x
	// rozpoczynający się od cd 
	char buf[16];
	strncpy(buf, cd, 3);
	buf[3]=0; // NULL end
	puts(buf);
	
	// porównywanie
	if (strcmp(x, "a") == 0)
		puts("x == \"a\"");
	if (strncmp(x, "a", 1) == 0)
		puts("pierwsze 1 znaków x to \"a\"");
}
```

Pliki
-----

```C
#include <stdio.h>

int main() {
	// otwieramy plik określony w pierwszym argumencie,
	// w trybie określonym w drugim argumencie:
	// r - odczyt, w - zapis, a - dopisywanie,
	// + - dwukierunkowy (używane po r, w albo a)
	FILE *plik = fopen("/tmp/plik1.txt", "w+");
	
	// zapisujemy do pliku
	fputs("Hello World !!!\n", plik);
	fprintf(plik, "%.3f\n", 13.13131);
	
	// jako że są to operacje buforowane to aby mieć
	// pewność że to jest już w pliku należy wykonać
	// fflush(), nie jest to konieczne gdy zamykamy
	// plik (wtedy wykonywane jest z automatu)
	fflush(plik);
	
	int poz = ftell(plik);
	printf("aktualna pozycja w pliku to %d\n", poz);
	
	// przewijamy do początku
	// jest to równoważne rewind(plik);
	fseek(plik, 0, SEEK_SET);
	
	// wczytywanie z pliku
	char napis[10];
	fgets(napis, 10, plik);
	// wczytany napis będzie miał 9 znaków + NULL-end
	
	puts(napis);
	
	// powrót do poprzedniej pozycji
	fseek(plik, poz, SEEK_SET);
	
	// operacje binarne - w ten sposób możemy zapisywać
	// i odczytywać całe bufory z pamięci, czyli także napisy
	// zapis do pliku
	double x = 731.54112, y = 12.2;
	fwrite(&x, 1, sizeof(double), plik);
	fflush(plik);
	
	// przesuniecie do pozycji na której zapisywaliśmy
	fseek(plik, poz, SEEK_SET);
	// i odczyt z pliku ...
	fread(&y, 1, sizeof(double), plik);
	
	printf("zapisano: %f, odczytano: %f\n", x, y);
	
	// są także funkcje read() i write() działające w oparciu o
	// numeryczny deskryptor pliku uzyskiwany np. z funkcji open()
	// a nie obiekt FILE uzyskiwany z fopen()
	
	fclose(plik);
}
```
