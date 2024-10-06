<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: PDF based
-->

Podstawy programowania w C++
============================

Większość podstaw składniowych C++ jest tożsama z [ur=guide://programming/basics/c]podstawami składniowymi C[/url]. Poniżej przedstawione są najistotniejsze rozszerzenia i różnice wnoszone przez C++.


Kompilacja
----------

C++ wymaga kompilacji przy pomocy kompilatora obsługującego ten język. W środowisku linuxowym tym celu możemy skorzystać z jednego z kilku dostępnych kompilatorów (zauważ że w każdym przypadku podstawowa składnia jest taka sama):

* Domyślnego kompilatora C++ (zazwyczaj jeden z poniższych): `c++ -o plik_wykonywalny plik_zrodlowy.c`
* kompilatora C z GNU Compiler Collection: `g++ -o plik_wykonywalny plik_zrodlowy.c`
* clang i LLVM: `clang++ -o plik_wykonywalny plik_zrodlowy.c`


Biblioteka standardowa C++ a C
------------------------------

C++ posiada własną bibliotekę standardową, pozwala też na bezproblemowe korzystanie z biblioteki standardowej C. Biblioteka C++ dostarcza nawet wiele funkcji całkowicie zgodnych z biblioteką standardową C (korzystając jednak z innych plików nagłówkowych).

### strumienie wejścia wyjścia

Chyba najbardziej zauważalną zmianą są strumienie wejścia - wyjścia zamiast funkcji typu `printf` (korzystanie z niej jest jednak nadal możliwe):

```cpp
#include <iostream>

int main() {
	int x = 13;
	std::cout << "Hello world, x=" << x << std::endl;
}
```

### napisy

C++ posiada własny typ obudowujący *null-end string* znany z C (oferuje m.in. informację o długości napisu bez konieczności czytania całego napisu i dynamiczne alokowanie).

```cpp
#include <stdio.h>
#include <iostream>

#include <string>
#include <string.h>
#include <bitset>
#include <regex>
#include <sstream>

int main() {
	const char* x = "abcdefg";
	
	std::string xx(x);
	std::string y = "aa bb cc bb dd bb ee";
	
	// wypisanie długości napisu
	std::cout << xx.size() << "\n";
	// .size() to to samo co .length()
	
	// uzyskanie napisy w stylu C
	puts(xx.c_str());
	
	// wypisanie pod-napisu od 2 do końca
	std::cout << xx.substr(2) << "\n";
	std::cout << xx.substr(2, std::string::npos) << "\n";
	// i od 0 (początku)do 3
	std::cout << xx.substr(0, 3) << "\n";
	
	// wyszukiwanie pod-napisu "bb" w y od pozycji 5
	std::cout << y.find("bb", 5) << "\n";
	
	// porównywanie
	if (xx == "a")
		std::cout << "x == \"a\"\n";
	if (xx.compare(0, 1, "a") == 0)
		puts("pierwsze 1 znaków x to \"a\"");
	
	if ( std::regex_match(xx, std::regex(".*[dz].*")) )
		puts("x zawiera d lub z");
		// regex_match dopasowuje całość napisu do wyrażenia regularnego
		// dopasowanie częściowe wraz z opcjonalnym uzyskaniem
		// pasującej części umożliwia: std::regex_search()
	
	// modyfikowanie std::string
	xx = "Ala ma psa";
	// wstawianie - insert(pozycja, co)
	xx.insert(6, " kota i");
	std::cout << xx << std::endl;
	
	// zastępowanie - replace(pozycja, ile, czym);
	xx.replace(4, 2, "miała samochód", 0, 6);
	// mogłoby też być xx.replace(4, 2, "miała"); i parę innych wariantów ...
	std::cout << xx << std::endl;
	
	// usuwanie - erase(pozycja, ile);
	xx.erase(9, 1); // 9 zamiast 8 bo UTF-8 i ł ma dwa znaki
	std::cout << xx << std::endl;
}
```

Dokumentacja
------------

Dokumentacja dostępna jest m.in. w formie *C++ reference* dostępnego online [url=https://en.cppreference.com/]https://en.cppreference.com/[/url], a często także dystrybuowanego jako pakiet systemowy.


Kontenery STL
-------------

### tablice zmiennej długości

C++ tablic zmiennej długości w stylu C99 C++ oficjalnie nie obsługuje, przy czym niektóre z kompilatorów dopuszczają użycie VLA w C++.
C++ posiada za to typ std:vector pozwalający na definiowanie tablic, których rozmiar można łatwo (z punktu widzenia programisty, niekoniecznie maszyny wykonującej ten kod) zmieniać nawet po utworzeniu tablicy:
```cpp
#include <vector>

void xxx(int n) {
    std::vector<float> vals(n);
    v[0] = 21;
    /* ... */
}
```

### listy

Biblioteka standardowa C++ (a dokładniej jej fragment określany mianem STL) dostarcza także obsługę list:

```cpp
#include <iostream>
#include <list>

int main() {
    std::list<int> l;
    
    // dodanie elementu na końcu
    l.push_back(17);
    l.push_back(13);
    l.push_back(3);
    l.push_back(27);
    l.push_back(21);
    // dodanie elementu na początku
    l.push_front(8);
    
    // wypisanie liczby elementów
    std::cout << "size=" << l.size()<< "\n";
    
    // wypisanie pierwszego i ostatniego elementu
    std::cout << "first=" << l.front() << " last=" << l.back() << "\n";
    
    // usuniecie ostatniego elementu
    l.pop_back();
    
    // posortowanie listy
    l.sort();
    
    // odwrócenie kolejności elementów
    l.reverse();
    
    // usuniecie pierwszego elementu
    l.pop_front();
    
    for (std::list<int>::iterator i = l.begin(); i != l.end(); ++i) {
        // wypisanie wszystkich elementów
        std::cout << *i << "\n";
        // możliwe jest także:
        //  - usuwanie elementu wskazanego przez iterator
        //  - wstawianie elementu przed wskazanym przez iterator
    }
}
```

W przypadku C++ listy implementowane są jako listy a nie tablice wskaźników, więc operacje wstawiania na początku i w środku są szybkie, ale operacja uzyskania n-tego elementu jest powolna.

### mapy

Biblioteka standardowa C++ oferuje także kontener umożliwiający przechowywanie danych w postaci par klucz-wartość, gdzie wartość identyfikowana jest unikalnym kluczem (podobnie jak w pythonowych słownikach):

```cpp
#include <iostream>
#include <map>

int main() {
    std::map<std::string, int> m;
    
    m["a"] = 6;
    m["cd"] = 9;
    std::cout << m["a"] << " " << m["ab"] << "\n";
    
    // wyszukanie elementu po kluczu
    std::map<std::string, int>::iterator iter = m.find("cd");
    // sprawdzenie czy istnieje
    if (iter != m.end()) {
        // wypisanie pary - klucz wartość
        std::cout << iter->first << " => " << iter->second << "\n";
        // usunięcie elementu
        m.erase(iter);
    }
    
    m["a"] = 45;
    
    // wypisanie całej mapy
    for (iter = m.begin(); iter != m.end(); ++iter)
        std::cout << iter->first << " => " << iter->second << "\n";
    // jak widać mapa jest wewnętrznie posortowana
}
```

Mapa `std::map` nie zachowuje kolejności wkładania elementów, natomiast jest zawsze posortowana. C++ oferuje też inne rodzaje map (np. nie posortowaną `std::unordered_map`, czy też nie wymagającą unikalności klucza `std::multimap`).


Więcej C-plus-plusa ...
-----------------------

### iteratory

W powyższych przykładach użycia list i map w C++ warto zwrócić uwagę na użycie iteratorów pozwalających na pobieranie kolejnych wartości z tych kontenerów:

```cpp
void wypiszListe(std::list<int> l) {
    for (std::list<int>::iterator i = l.begin(); i != l.end(); ++i) {
        std::cout << *i << "\n";
    }
}
```

Iterator zwracają niektóre z metod obiektów reprezentujących te kontenery, np. `.begin()` zwraca iterator na pierwszy element. Zwiększanie iteratora odbywa się z użyciem operatorów `++`. Wyjście poza zakres (zwiększenie iteratora wskazującego na ostatni element kolekcji) nie powoduje rzucenia wyjątku, za to iterator przyjmuje specjalną wartość oznaczającą koniec. Iterator o tej wartości zwracany jest przez metodę `.end()` (lub `.rend()` przy iterowaniu w przeciwną stronę).

### typ auto

Współczesny C++ oferuje także specjalny typ `auto` zwalniający programistę z konieczności jawnego definiowania typu zmiennej do której przypisywana jest od razu jakaś wartość z określonym typem. Możemy napisać np. `auto x = 5;`, ale nie możemy napisać `auto x; x = 5;`. Typ ten jest użyteczny np. do obsługi iteratorów, pozwalając powyższą pętle zapisać bez `std::list<int>::iterator` jako:

```cpp
void wypiszListe(std::list<int> l) {
    for (auto i = l.begin(); i != l.end(); ++i) {
        std::cout << *i << "\n";
    }
}
```

### pętla for(each)

C++ udostępnia także inną składnię pętli `for` pozwalającą na iterowanie po wszystkich elementach kolekcji takich jak listy, mapy, itp. Będącą odpowiednikiem pętli *foreach* znanej z niektórych języków programowania, czy też pythonowskiej pętli *for*:

```cpp
void wypiszListe(std::list<int> l) {
    for (auto i : l) {
        std::cout << i << "\n";
    }
}
```

Zamiast `auto i` możemy napisać `auto& i` aby otrzymać dostęp przez referencję (wtedy wykonanie przypisania wartości do i, np `i = 0`, spowoduje modyfikację elementu listy).

Warto zauważyć także, że w odróżnieniu od wcześniejszej pętli nie operujemy tutaj na iteratorach, a na wartościach / referencjach do wartości z kontenera.

### szablony

C++ pozwala też definiować szablony funkcji oraz klas, dzięki którym kompilator będzie mógł wytworzyć funkcje/klasy dla potrzebnych typów w oparciu o ten szablon (zdefiniowany dla ogólnego typu). Na przykład powyższa funkcja wypisująca listy zdefiniowana jest tylko dla list zawierających liczby całkowite. Jednak takie funkcje dla dowolnych typów obsługiwanych przez cout-owy operator `<<` (np. liczb zmiennoprzecinkowych, napisów, ...) będą wyglądały tak samo. Dzięki mechanizmowi szablonów możemy napisać:

```cpp
template <typename T> void wypiszListe(std::list<T>& l) {
    for (auto i : l) {
        std::cout << i << "\n";
    }
}
```

I następnie używać jej dla różnych typów list:

```cpp
int main() {
    std::list<int> x={1, 3, 7, 2, 3};
    wypiszListe(x);
    
    std::list<float> z={2.7, 5.0, 3.1, 3.9};
    wypiszListe(z);
}
```

### lambda

```cpp
#include <iostream>

int main() {
    int x = 1, y = 1;

    // ta lamba będzie używać:
    //  wartości x z chwili wywołania (i jej zmiana bedzie widoczna na zewnątrz)
    //  wartości y z chwili utworzenia
    auto moja_lambda = [&x, y](int z) { x += z * y; return 11; };

    moja_lambda(2);
    std::cout << x << std::endl; // 3 bo x = 1 + 2 * 1

    x = 0;
    y = 0;

    int z = moja_lambda(2);
    std::cout << x << " " << z << std::endl; // 2 bo x = 0 + 2 * 1
}
```

C++ pozwala także na definiowanie i używanie lambd. Definicja taka składa się z listy przechwytywanych zmiennych, listy argumentów i ciała funkcji. Lista przechwytywania może określać przechwytywanie przez wartość lub przez referencję. W pierwszym przypadku wartość zmiennej z miejsca utworzenia funkcji zostanie w niej "zamrożona", czyli jej dalsze zmiany nie będą widoczne w wywołaniach lambdy.' W drugim przypadku lambda będzie widzieć zawsze aktualną wartość, a zmiany tej zmiennej wewnątrz lambdy będą widoczne także na zewnątrz. Lista argumentów i ciało funkcji działa jak w zwykłych funkcjach. Lambda może zwracać lub może nie zwracać wartość z użyciem return.
