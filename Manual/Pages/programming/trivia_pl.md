<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text editing.

editing note: NEW
-->

Programowanie
=============

## Wielość języków programowania

Istnienie więcej niż jednego języka programowania ma sens, gdyż pozwala na dostosowanie języka do specyfiki jego użycia - trochę innych mechanizmów będzie wymagał język przeznaczony do pracy z plikami i uruchamiania innych programów, inaczej wysokopoziomowy język skryptowy ogólnego przeznaczenia, a jeszcze inaczej niezbyt wysokopoziomowy, wydajny, język kompilowany. Warto też poznać więcej niż jedne język programowania tak aby poznane przez programistę języki pokrywały takie różne zastosowania. Nie warto jednak uczyć się kilkunastu czy więcej języków „na zapas”, gdyż po pierwsze nieużywane języki, ich szczegóły składniowe będzie się zapominać, a po drugie umiejąc programować opanowanie kolejnego (zwłaszcza niezbyt egzotycznego) języka jest kwestią kilku-kilkunastu godzin programowania posiłkując się dokumentacją tego języka i jego standardowych bibliotek.

## Realizacja wejścia / wyjścia

Zależnie od tego na na jaki system tworzony jest nasz program, czy będzie on działać pod kontrolą systemu operacyjny czy bezpośrednio na sprzęcie realizacja operacji I/O może wyglądać inaczej. W przypadku tworzenia programu działającego pod kontrolą systemu operacyjnego praktycznie wszystkie operacje I/O realizowane są poprzez wywołania odpowiednich mechanizmów tego systemu za pośrednictwem funkcji biblioteki standardowej. Natomiast w przypadku bezpośrednie programowania sprzętu nierzadko konieczne jest samodzielne napisanie całych takich funkcji, bądź przynajmniej funkcji „systemowych” realizujących rzeczywistą operację I/O używanych przez funkcje biblioteki standardowej.

Przykładem może być korzystanie z funkcji `printf` biblioteki standardowej C. Na systemach linuxowych korzysta ona z systemowego mechanizmu standardowego wyjścia, które jest wypisywane na terminalu lub może być przekierowane do innego procesu. Jeżeli chcemy użyć tej funkcji na platformie STM32 musimy zaimplementować funkcję realizującą fizyczne wysyłanie danych poprzez wybrany port szeregowy lub wyświetlanie ich na alfanumerycznym wyświetlaczu LCD.

## Programowanie obiektowe

Programowanie obiektowe jest podejściem polegającym na powiązaniu danych z funkcjami na nich operującymi w ramach klas / obiektów. Klasa definiuje typ danych, który będą posiadały obiekty tej klasy poprzez określenie jakie będą posiadały atrybuty (pola składowe przechowujące dane) i metody (funkcje udostępniane przez obiekt i operujące na nim). Obiekt to konkretna instancja klasy, która zawiera rzeczywiste dane. Klasy różnią się od złożonych typów nieobiektowych (np. struktur czy tablic) tym, że definiują zarówno dane, jak i związane z nimi zachowanie, co ułatwia modelowanie rzeczywistych bytów w kodzie. W rezultacie zamiast grupy funkcji operujących na jakiejś strukturze danych i osobnych instancjach tej struktury (np. napis typu `char*` i funkcje z rodziny `string.h`) operuje się obiektami zawierającymi w sobie dane i posiadającym metody na nich operujące (np. napis typu `std::string`).

### Metody

Funkcje zdefiniowane w klasie określa się mianem metod tej klasy. Typowo funkcje takie wymagają do swojego działania obiektu danej klasy, który jest do nich przekazywany jako (jawny lub ukryty) argument. Wyróżnia się metody statyczne, które pomimo zdefiniowania wewnątrz klasy nie wymagają do swojego działania obiektu tej klasy (a przynajmniej otrzymania go w postaci tego specjalnego argumentu, jak zwykłe metody). Pozwalają one na traktowanie klasy jako pewnej przestrzeni nazw i umieszczanie w niej funkcji logicznie powiązanych (ale nie operujących na obiekcie), np. funkcji tworzących obiekty klasy i innych funkcji pomocniczych.

### Dziedziczenie

Mechanizm dziedziczenia pozwala tworzyć nowe klasy na bazie istniejących, wykorzystując ich atrybuty i metody. Pozwala to na rozszerzanie istniejących typów oraz tworzenie typów bardziej specyficznych (np. klasy „trójkąt” i „kwadrat” dziedzicząca po klasie „wielobok”).

Dodatkowo często możliwe jest redefiniowanie w klasie pochodnej (dziedziczącej) metod istniejących już w klasie bazowej. W przypadku użycia mechanizmu metod wirtualnych pozwala to na uruchamianie metody z odpowiedniej klasy pochodnej, także w sytuacji gdy w chwili kompilacji kodu wiemy jedynie że obiekt jest obiektem klasy bazowej (a nie znamy konkretnej klasy pochodnej). Na przykład:

* klasa „wielobok” dostarcza metodę wirtualną „oblicz pole”
* klasy po niej dziedziczące („trójkąt” i „kwadrat”) dostarczają różne wersje tej metody
* funkcja dostająca listę bądź tablicę obiektów typu „wielobok” (będących w istocie obiektami typu „trójkąt” lub „kwadrat”) może wywoływać funkcję „oblicz pole” na każdym z nich (bez jawnego sprawdzenia jaki to konkretnie typ) i będzie użyta właściwa funkcja

Pozwala to na tworzenie interfejsów klas, które wystawiają do użycia w programie jedynie to co o obiektach klasy powinno być widoczne i pozwalają ukryć szczegóły implementacyjne.

## Przeciążanie funkcji i operatorów

Wiele języków programowania pozwala na definiowanie funkcji o tej samej nazwie ale różniących się zbiorem argumentów - może to być liczba argumentów lub po prostu typ (nawet pojedynczego) argumentu – mechanizm ten określany jest mianem przeciążania funkcji. Podobnie w niektórych językach możliwe jest definiowanie własnych zachowań dla standardowych operatorów (np. dodawania) wywoływanych na obiektach jakiejś własnej klasy.

## Lamba

Funkcje typu lambda to anonimowe funkcje, które nie mają przypisanej nazwy, a ich definicja jest zazwyczaj zwarta i jednozdaniowa. Są często wykorzystywane w krótkich operacjach, zwłaszcza gdy funkcje są przekazywane jako argumenty do innych funkcji. Typowo wartości argumentów i zmiennych są mapowane dopiero w momencie wykonania funkcji, a nie w chwili jej definicji, co oznacza, że środowisko, w którym funkcja zostanie uruchomiona, może wpływać na wynik (np. przez zmienne globalne lub zmienne z otaczającego zakresu).

W niektórych językach możliwe jest jednak wymuszenie użycia wartości z chwili definicji, czyli tzw. zamrożenie (ang. "capture by value"). 


W Pythonie można to osiągnąć, np. za pomocą domyślnych wartości argumentów w lambdach:

```python
x = 10
lambda_function = lambda y, x=x: x + y  # x jest teraz zamrożone jako 10
```

W C++ lambdy mają mechanizm przechwytywania zmiennych przez wartość lub referencję. Można explicite zamrozić zmienne poprzez przechwycenie ich przez wartość:

```cpp
int x = 10;
auto lambda_function = [x](int y) { return x + y; };  // x jest zamrożone jako 10
```

## Szablony

Silne, statyczne typowanie, pomimo swoich zalet, posiada także wady. Jedną z nich jest prowadzenie do duplikowania kodu m.in. w sytuacji gdy oczekujemy takiego samego zachowania funkcji dla różnych typów danych. Na przykład funkcja obliczająca jakieś wyrażenie matematyczne, która powinna działać dla różnych typów liczb stało i zmiennoprzecinkowych bez dokonywania konwersji tych typów powinna być zdefiniowana dla każdego z nich osobno w identyczny sposób. Rozwiązaniem tego problemu jest stosowanie mechanizmu szablonów (udostępnianego przez niektóre języki). Pozwala on definiować szablony funkcji i/lub klas, dzięki którym kompilator będzie mógł wytworzyć funkcje/klasy dla potrzebnych typów w oparciu o ten szablon (zdefiniowany dla ogólnego typu zastępczego).

Przykład w C++:

```cpp
// definicja szablonu
template <typename T> T wyrazenie(T a, T b) {
	// T jest parametrem szablonu (typem zastępczym) i będzie zastąpione typem argumentu
	return a + 2*b*a + 3*b;
}

// przykłady użycia:

// 1. argumenty są typu int i wynik jest typu int
int fun1(int a) { return wyrazenie(a, 13); }

// 2. argumenty są typu double i wynik jest typu double
double fun2(double a) { return wyrazenie(a, 1.3); }

// 3. argumenty są różnych typów (double i int),
// jawnie wymuszamy działanie funkcji `wyrazenie` typu double (jako T),
// wartość `a` będzie rzutowana z int na double, wynik jest typu double
double fun3(int a) { return wyrazenie<double>(a, 1.3); }
```
