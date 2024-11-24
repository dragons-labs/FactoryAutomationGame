<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Electronic Control

Bloczek „Electronic Control” pozwala na tworzenie schematu układu elektronicznego kontrolującego fabrykę. Fabryka może zawierać tylko jeden taki bloczek, a miejsce jego umieszczenia nie ma znaczenia.

Stworzony układ powinien zawierać elementy typu „Net Connector”, które reprezentują połączenia pozwalające na komunikację układu elektronicznego z fabryką. Dodawanie i usuwanie bloczków z fabryki będzie wpływało na dostępne / obsługiwane połączenia – ich pełną listę można sprawdzić w menu rozwijanym wyboru nazwy połączenia. Można używać własnych nazw (opcja „custom”) do tworzenia połączeń wewnątrz schematu elektrycznego (zamiast / obok rysowania linii).

Połączenia reprezentują sygnały trzech typów:

* Napięcia zasilające, takie jak: Vcc, 5V, GND (masa posiada tez własny symbol połączenia: ⏚)
* Sygnały wejściowe (oznaczane jako ```@in```) dostarczają informacje o stanie fabryki do układu elektroniczego. Posiadają one niską impedancję (rzędu miliomów). Nie należy łączyć ich ze sobą lub z liniami zasilania.
* Sygnały wyjściowe (oznaczane jako ```@out```) dostarczają służą do kontrolowania elementów fabryki poprzez podanie na nie odpowiedniej wartości napięcia. Posiadają one wysoką impedancję (rzędu gigaomów). 

Nazwy sygnałów wejściowych i wyjściowych są poprzedzone nazwą bloczka z którego pochodzą (jeżeli jest ona niepusta).
