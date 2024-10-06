<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: PDF based
-->

Podstawy programowania w C++
============================

## referencje

Referencje są zasadniczo wskaźnikami, których używamy jak zwykłych zmiennych (bez stosowania operatora `*` w celu operowania na wartości wskaźnika). W odróżnieniu od wskaźników nie możemy bezpośrednio operować na adresie referencji (np. spowodować aby wskazywała na inną zmienną). Kontynuując przykład z modyfikacją zmiennej przekazanej jako argument funkcji, z użyciem referencji kod ten może wyglądać następująco:

```cpp
void ff(int& a) { // zwróć uwagę na & oznaczający że będzie to referencja
    a = 15;
}
int main() {
    x = 10;
    ff(x);
    printf("%d\n", x); // wypisze 15
}
```
