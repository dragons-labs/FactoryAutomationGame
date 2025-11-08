<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Podstawy programowania w C (tematy bardziej zaawansowane)
=========================================================

Preprocesor
-----------

Preprocesor C może być użyty także do:

- definiowania stałych
- definiowania makr
- warunkowej kompilacji kodu oraz komentowania jego fragmentów (`#if 0` oraz `#endif`)

```C
// poniższe polecenie każe zastąpić w kodzie programu KAŻDE wystąpienie _NAPIS_
// poprzez "Hello World"
#define _NAPIS_ "Hello World"
// w podobny sposób możemy definiować pseudo funkcje
#define _SUMA_(a,b) (a + b)
// poprzedzenie argumentu # powoduje ujęcie go w ""
#define _WYPISZ_(a) printf(#a)
// ## powoduje sklejenie ...

// ze względu na kontrolę błędów na etapie kompilacji
// zaleca się ograniczanie #define (w powyższych zastosowaniach)
// na rzecz stałych i funkcji inline

// możemy też warunkować włączanie fragmentów kodu
#define PL

#ifdef PL
	// ten fragment wykona się tylko gdy zdefiniowana PL
	#undef _NAPIS_
	// oddefiniowalismy _NAPIS_
	#define _NAPIS_ "Witaj World"
	// i zdefiniowaliśmy go inaczej
#endif

#if 0
to jest trzeci rodzaj komentarza w C
#endif

#include <stdio.h>

int main() {
	printf("%s\n", _NAPIS_);
	printf("%d\n", _SUMA_(5,3));
	_WYPISZ_ (witaj świecie !!! \n);
}
```

Dowolna liczba argumentów funkcji
---------------------------------

```C
#include <stdio.h>
#include <stdarg.h> // do obsługi dowolnej ilości argumentów

// funkcja z dwoma argumentami wymaganymi i dowolną ilością argumentów opcjonalnych
float f4(int a, int b, ...) {
	float ret;
	
	va_list vl;
	va_start(vl, b);
	
	// w tym miejscu potrzebujemy znać ilość
	// oraz typy argumentów
	for (int i=0; i<a; i++) {
		ret += b * va_arg(vl,double);
	}
	va_end(vl);

	return ret;
}

int main() {
	float b = f4(2, 1, 2.8, 3.5);
	
	printf("%f\n", b);
}
```

Niskopoziomowe mechanizmy skoków
--------------------------------

Instrukcje `goto` i funkcje `setjmp`/`longjmp` służą do bezpośredniego zarządzania przepływem sterowania w programie, ale zazwyczaj unika się tych mechanizmów, ponieważ mogą zmniejszać czytelność kodu.

### goto

```C
#include <stdio.h>

int main() {
	goto ETYKIETA;
	puts("to się nigdy nie wykona");
	puts("bo wcześniej robimy bezwarunkowe goto");
	
	ETYKIETA:
	puts("a to się wykona");
}
```

Najczęstszym przypadkiem użycia `goto` jest obsługa błędów w złożonych funkcjach (tzw. "cleanup" na końcu funkcji). `goto` do kodu wykonujące sprzątanie i wyjście z funkcji używany jest zamiast return w warunkach sprawdzających wystąpienie błędu.


### długi skok

Skok długi realizowany przez funkcje `setjmp` i `longjmp` pozwala na wykonywanie skoków pomiędzy różnymi funkcjami. `setjmp` zapisuje kontekst programu (m.in. stan stosu) i zwraca zero, a `longjmp` pozwala do niego wrócić (w tym przypadku `setjmp` zwróci wartość określoną w argumencie `longjmp`.

```C
#include <stdio.h>
#include <setjmp.h>

jmp_buf buffer;

void second() {
    longjmp(buffer, 1);  // skok z powrotem do miejsca wywołania setjmp
}

void first() {
    if (setjmp(buffer) == 0) {
        second();  // wywołanie drugiej funkcji
    } else {
        printf("Powrót z longjmp\n");
    }
}
```


Zmienna i jej adres
-------------------

Wszelkie dane na których operuje program komputerowy przechowywane są w jakimś rodzaju pamięci - najczęściej jest to pamięć operacyjna. W pewnych sytuacjach niektóre dane mogą być przechowywane np. tylko w rejestrach procesora lub rejestrach urządzeń wejścia-wyjścia.

W programowaniu na poziomie wyższym od kodu maszynowego i asemblera używa się pojęcia zmiennej i (niemal zawsze) pozostawia kompilatorowi/interpretatorowi decyzję o tym gdzie ona jest przechowywana. Oczywistym wyjątkiem są grupy zmiennych, czy też bufory alokowane w sposób jawny w pamięci. Ze względu na ograniczoną liczbę rejestrów procesora większość zmiennych (w szczególności tych dłużej istniejących i większych) będzie znajdowała się w pamięci i będą przenoszone do rejestrów celem wykonania jakiś operacji na nich po czym wynik będzie przenoszony do pamięci.

Z każdą zmienną przechowywaną w pamięci związany jest *adres pamięci* pod którym się ona znajduje. Niektóre z języków programowania pozwalają na odwoływanie się do niego poprzez wskaźnik na zmienną lub referencję do zmiennej (odwołania do adresu zmiennej mogą wymusić umieszczenie jej w pamięci nawet gdyby normalnie znajdowała się tylko w rejestrze procesora).

Wszystkie dane są zapisywane w postaci liczb lub ciągów liczb. Typ zmiennej (jawny lub nie) informuje o tym jakiej długości jest dana liczba i jak należy ją interpretować (jak należy interpretować ciąg liczb). 

### Zasięg zmiennej

Zasięg zmiennych (widoczność i istnienie) jest limitowany do bloku (wydzielanego nawiasami klamrowymi) w którym zostały zadeklarowane, zmienne z bloków wewnętrznych mogą przesłaniać zmienne zadeklarowane wcześniej.

Wywołanie funkcji powoduje rozpoczęcie nowego kontekstu w którym zmienne z bloku wywołującego funkcję nie są widoczne (ale nadal istnieją). Argumenty do funkcji przekazywane są przez kopiowanie, więc funkcja nie ma możliwości modyfikacji zmiennych z bloku ją wywołującego nawet do niej przekazanych (wyjątkiem jest przekazanie przez referencję lub wskaźnik).

W przypadku manualnej alokacji pamięci (z użyciem `malloc`) limitowana jest widoczność i istnienie otrzymanego wskaźnika, ale nie zaalokowanego bloku pamięci. Zatem ograniczona jest widoczność takich zmiennych ale nie czas ich istnienia, dlatego też przed utratą wskaźnika na nie należy je usunąć (zwolnić zaalokowaną pamięć). 

### Wskaźniki

Wskaźnik jest zmienną, która przechowuje adres pamięci, pod którym znajdują się jakieś dane (inna zmienna). Jako że wskaźnik jest zmienną która też jest umieszczona gdzieś w pamięci można utworzyć wskaźnik do wskaźnika itd. Na wskaźnikach można wykonywać operacje arytmetyczne (najczęściej jest to dodawanie offsetu). Na wskaźniku można wykonać operację wyłuskania czyli odwołania się do wartości zmiennej pod adresem na który wskazuje, a nie do zmiennej wskaźnikowej (zawierającej adres).

Wskaźniki pozwalają na operowanie dużymi zbiorami danych (duże struktury, napisy, etc) bez konieczności ich kopiowania przy przekazywaniu do funkcji, umieszczaniu w różnych strukturach danych, sortowaniu, itd (kopiowaniu ulega jedynie wskaźnik czyli adres) oraz na współdzielenie tych samych danych pomiędzy różnymi obiektami.

Wskaźnik może wskazywać na niewłaściwy adres w pamięci (np. na skutek zwolnienia tego fragmentu lub błędu w operacjach matematycznych na wskaźnikach - wyjściu poza dozwolony zakres), typowo wskaźnikowi który nic nie wskazuje przypisuje się wartość `NULL` (zero). Wyłuskania wskaźników o wartości `NULL` lub wskazujących niewłaściwy obszar pamięci prowadzą do błędów programu, często do zakończenia programu z powodu naruszenia ochrony pamięci ("Segmentation fault"). 

```c
#include <stdio.h>

int main() {
    int zm = 13;
    int *wsk = NULL; // zmienna wskaźnikowa (na typ int)
    
    // przypisanie do zmiennej wskaźnikowej adresu zmiennej zm
    // pobranie adresu zmiennej przy pomocy operatora &
    wsk = &zm;
    printf("%p %p\n", &zm, wsk);
    
    // odwołanie do zmiennej wskazywanej przez wskaźnik (wyłuskanie wartości)
    // przy pomocy operatora *
    printf("%d %d\n", zm, *wsk);
    *wsk = 17;
    printf("%d %d\n", zm, *wsk);
}
```

### Wskaźniki a tablice

Zmienna tablicowa w C to w istocie wskaźnik na pierwszy element tablicy. Dostęp do elementów tablicy odbywa się w oparciu o obliczanie ich adresu na podstawie zależności: [i]AdresElementu = AdresPoczatkuTablicy + IndexElementu * RozmiarElementu[/i].

```c
#include <stdio.h>

int main() {
  int t[4] = {1, 8, 3, 2};
  int *tt = t; // zauważ brak operatora pobrania adresu
  
  printf("%d %d\n", t[2], tt[2]);
  printf("%d %d\n", *(t + 2), *(tt + 2));
}
```

Zauważ że operator `t[x]` działa tak samo dla tablicy jak i dla wskaźnika i jest w istocie ładniejszym zapisem operacji `*(t+x)` na samym wskaźniku.

### Wskaźniki a funkcje

Argumenty do funkcji przekazywane są przez kopiowanie, w związku z tym modyfikacja zmiennej będącej argumentem funkcji wewnątrz tej funkcji nie będzie widoczna poza nią:

```c
void ff(int a) {
    a = 15;
}
int main() {
    int x = 10;
    ff(x);
    printf("%d\n", x); // wypisze 10
}
```

Jeżeli chcemy mieć możliwość modyfikacji zmiennej przekazywanej przez argument możemy przekazać zmienną do funkcji przez wskaźnik:

```c
void ff(int* a) {
    *a = 15;
}
int main() {
    int x = 10;
    ff(&x);
    printf("%d\n", x); // wypisze 15
}
```

Z rozwiązania takiego korzystamy też gdy chcemy uniknąć kopiowania dużych struktur, w tym przypadku dobrym zwyczajem jest dodanie `const`, aby funkcja nie mogła modyfikować tego na co wskazuje ten wskaźnik:

```c
struct Struktura {
  int a, b;
};
void ff(const struct Struktura *s) {
    s->a = 15; // błąd kompilacji w tym miejscu, z powodu const w linii wyżej
    /* zauważ że do elementów struktur możemy się odwoływać
       obiekt.pole lub (&obiekt)->pole (czyli wskazik_na_obiekt->pole) */
}
int main() {
    struct Struktura s;
    ff (&s);
}
```


### Arytmetyka wskaźnikowa

Jak już zauważyliśmy na wskaźnikach można wykonywać (niektóre) operacje arytmetyczne. Ich działanie jest zależne od typu wskaźnika, tj. zwiększenie wskaźnika o 1 zwiększa adres na który on wskazuje o tyle bajtów ile zajmuje zmienna której typu jest wskaźnik.

```c
#include <stdio.h>

int main() {
    char a;    int    b;
    char *wsk_a = &a;
    int  *wsk_b = &b;
    
    printf("char: %p %p\n", wsk_a, wsk_a+1);
    printf("int:    %p %p\n", wsk_b, wsk_b+1);
}
```



## Kolejność bajtów

Wskaźniki i rzutowanie typów pozwala patrzeć na dane w postaci poszczególnych bajtów.

```c
#include <inttypes.h>
#include <stdio.h>
int main() {
    // dane jako tablica liczb 16 bitowych
    uint16_t aa[4] = {0x1234, 0x5678, 0x9abc, 0xdeff};
    
    // wypisujemy ją
    printf("A0: %x %x %x %x\n", aa[0], aa[1], aa[2], aa[3]);
    // chyba nikogo nie zaskoczy wynik powyższego printf:
    //   A0: 1234 5678 9abc deff
    
    // wypisujemy dwie pierwsze liczby rozłożone na części 8 bitowe
    // (poszczególne bajty)
    printf(
        "A1: %x %x %x %x\n",
        (aa[0] >> 8) & 0xff, aa[0] & 0xff,
        (aa[1] >> 8) & 0xff, aa[1] & 0xff
    );
    // efekt też jest oczywisty:  A1: 12 34 56 78
    
    // każemy na te same dane patrzeć jako na liczby 8 bitowe
    // (poszczególne bajty)
    uint8_t* bb = (uint8_t*) aa;
    
    printf("B0: %x %x %x %x\n", bb[0], bb[1], bb[2], bb[3]);
    // czego się teraz spodziewamy?
    //  - wypisze nam tylko połowę oryginalnej tablicy
    //  - ale dokładny wynik zależy od architektury na której uruchamiamy
    //    program (big endian vs little endian)
}
```

Kod ten w zależności od architektury procesora na którym będzie uruchomiony może wypisać inny wynik:

* na *little endian* (np. x86):
```
A0: 1234 5678 9abc deff
A1: 12 34 12 34
B0: 34 12 78 56
```
* na *big endian* (np. sparc) – zapis w "ludzkiej" kolejności:
```
A0: 1234 5678 9abc deff
A1: 12 34 12 34
B0: 12 34 56 78
```

Fakt, że różne komputery ten sam ciąg zero-jedynkowy mogą interpretować jako różne liczby (w zależności od architektury ,,big endian'' vs ,,little endian''), powoduje że przy wymianie danych między systemami konieczne jest ustalenie sposobu tej interpretacji (np. protokoły sieciowe takie jak IP używają ,,big endian'') lub zawarcie tej informacji w wymienianych danych (kodowania Unicode UTF-16 i UTF-32 zawierają na początku danych znacznik BOM).

Jak wykonywany jest kod C
-------------------------

Instrukcje skoku, które w programowaniu są związane z takimi konstrukcjami jak pętle i warunki, polegają na załadowaniu nowej wartości do licznika programu. W przypadku skoków warunkowych (takich jakich używają instrukcje warunkowe) może to być np. zależne od rejestru flag jednostki ALU, ustawianych w wyniku wykonania poprzedniej operacji arytmetycznej.

```asm
# fragment kodu asemblerowego wygenerowanego poleceniem "gcc -S" z kodu C:
#    if (argc == 1)
#        puts("A");
#    else
#        puts("B");
#    puts("C");

# operacja porównania                                      --- warunek if
	cmpl	$1, -4(%rbp)
# skok jeżeli nie równe do bloku else
	jne	.L2
# odłożenie argumentu "A" na stos i wywołanie funkcji puts --- blok if
	leaq	.LC0(%rip), %rdi
	call	puts@PLT
# skok bezwarunkowy za blok if - else
	jmp	.L3
.L2:
# odłożenie argumentu "B" na stos i wywołanie funkcji puts --- blok else
	leaq	.LC1(%rip), %rdi
	call	puts@PLT
.L3:
# odłożenie argumentu "C" na stos i wywołanie funkcji puts --- kod po if-else
	leaq	.LC2(%rip), %rdi
	call	puts@PLT
```

Powyżej znajduje się fragment kodu asemblerowego x86 wygenerowanego przez kompilator gcc dla widocznej konstrukcji if - else. Celem wykonania warunku if, sprawdzającego czy jakaś zmienna jest jeden, najpierw wykonywana jest ta operacja arytmetyczna porównania. A następnie wykonywana jest instrukcja skoku warunkowego zależna od ustawienia bądź nie ustawienia flagi informującej że była równość. Jako że ten if ma blok else to skok warunkowy (dla niespełnionego warunku) realizowany jest na pierwszą instrukcje bloku else, czyli adres tej instrukcji zostanie załadowany do licznika programu. Natomiast po ostatniej instrukcji bloku if mamy skok bezwarunkowy na pierwszą instrukcję po całej konstrukcji if - else, tak aby ominąć blok else. Skok bezwarunkowy jest po prostu instrukcją, która ładuje odpowiednią wartość adresu do licznika programu.
