<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Computer Control

Bloczek „Computer Control” pozwala na tworzenie programów komputerowych kontrolujących fabrykę. Miejsce umieszczenia tego bloczka nie ma znaczenia. Zazwyczaj będzie tylko jeden bloczek tego typu (i tylko ten pierwszy bloczek będzie posiadać połączenie z fabryką), jednak w niektórych fabrykach może być ich więcej.

Kontrolowanie fabryki możliwe jest poprzez:
* odczyt wartości sygnałów wejściowych, poprzez czytanie zawartości plików w `/dev/factory_control/inputs`
* ustawianie wartości sygnałów wyjściowych, poprzez zapisywanie wartości do plików w `/dev/factory_control/outputs`

**Uwaga:** Liczba wpisywana / odczytywana z tych plików odpowiada napięciu (a nie stanowi logicznemu), fabryka działa w logice 3.3 V, czyli aby ustawić stan wysoki wyjścia należy do pliku zapisać np. wartość 3 a nie 1.
