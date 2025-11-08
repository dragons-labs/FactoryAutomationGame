<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->


# Bramki

## budowa wewnętrzna

[img]Manual/Pages/electronics/digital_gates/gates_cmos.svg[/img]

Przedstawiony powyżej układ sumy na drucie jest bardzo prostą (jedno tranzystorową) realizacją bramki logicznej realizującą funkcję logiczną NOT OR (z punktu widzenia wejść *ctrl1* i *ctrl2* oraz wyjścia *Out*).
W podobny sposób można zrealizować bramkę AND (negując wejścia, np. przy pomocy jednego traznzystora).
Jeszcze bardziej uproszczoną realizację można uzyskać stosując diody pozwalające na wpływanie prądu do węzła (funkcja OR) lub wypływanie z niego (funkcja AND).

Po prawej przedstawione zostały schematy ideowe inwertera, dwóch podstawowych bramek (NOR i NAND) oraz bramki transmisyjnej (bufora 3 stanowego) w technologii CMOS.

Działanie tych bramek (za wyjątkiem transmisyjnej) polega na otwieraniu tranzystorów podłączonych do napięcia które chcemy otrzymać na wyjściu, a zamykaniu prowadzących do napięcia przeciwnego. W szczególności bramka NOT stanowi pół-mostek H pomiędzy stanem wysokim a stanem niskim.

Dzięki zastosowaniu tranzystorów PMOS polaryzowanych Vdd oraz NMOS polaryzowanych GND obie gałęzie operują na tym samym sygnale wejściowym (nie jest wymagana jego negacja). Szeregowe łączenie tranzystorów zapewnia że należy otworzyć oba aby otworzyć daną drogę, a równoległe że otwarcie danej drogi powodowane jest otwarciem pojedynczego tranzystora. Dzięki zastosowaniu technologi MOS i podłączaniu wejść bramki tylko do bramek tranzystorów wejścia praktycznie nie pobierają prądu (istotnym wyjątkiem jest chwila zmiany sygnału).

Działanie bramki transmisyjnej polega na przepuszczaniu lub nie (w zależności od stanu wejścia sterującego) sygnału z wejścia na wyjście. Bramka taka nie regeneruje sygnału. Ponadto w uproszczonym (jedno tranzystorowym) rozwiązaniu prowadzi ona do degradacji sygnału wartość w przybliżeniu równą napięciu progowemu tranzystora. Dlatego też na ogół występuje wraz z bramką NOT (bufor 3 stanowy z negacją) lub dwiema szeregowo połączonymi bramkami NOT (bufor 3 stanowy bez negacji).
