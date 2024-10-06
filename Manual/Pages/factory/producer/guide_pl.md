<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Producer

„Producer” jest bloczkiem wytwarzającym obiekty, które są przetwarzane przez fabrykę w finalny produkt zgodny ze specyfikacją.

Utworzenie obiektu wymaga pewnego czasu, jednak niektóre linie produkcyjne mogą działać wolniej, w związku z czym konieczne może być kontrolowanie momentu wypuszczenia obiektu, aby uniknąć tworzenia się zatorów na linii produkcyjnej.

#### Sygnały wejściowe:

* `producer_control_enabled` - stan wysoki (> 2V) dezaktywuje automatyczne wypuszczanie gotowego obiektu i powoduje oczekiwanie na sygnał `producer_release_object` w tym celu
* `producer_release_object` - stan wysoki (> 2V) powoduje wypuszczenie obiektu i rozpoczęcie przygotowywania kolejnego

#### Sygnały wyjściowe:

* `producer_object_ready` - stan wysoki (3.3V) informuje że obiekt jest gotowy do wypuszczenia
