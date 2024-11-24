<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Computer Control

Bloczek „Computer Control” pozwala na tworzenie programów komputerowych kontrolujących fabrykę. Miejsce umieszczenia tego bloczka nie ma znaczenia. Zazwyczaj będzie tylko jeden bloczek tego typu (i tylko ten pierwszy bloczek będzie posiadać połączenie z fabryką), jednak w niektórych fabrykach może być ich więcej.

Kontrolowanie fabryki możliwe jest poprzez:
* odczyt wartości sygnałów wejściowych, poprzez czytanie zawartości plików w `/dev/factory_control/inputs`
* ustawianie wartości sygnałów wyjściowych, poprzez zapisywanie wartości do plików w `/dev/factory_control/outputs`

Wartość z `/dev/factory_control/time` pozwala korzystać z czasu zgodnego z prędkością działania fabryki (jest on odliczany od uruchomienia fabryki, uwzględnia prędkość gry oraz pauzowanie). Gdy fabryka nie jest uruchomiona ma wartość ujemną.

**Uwaga:** Liczba wpisywana / odczytywana z tych plików odpowiada napięciu (a nie stanowi logicznemu), fabryka działa w logice 3.3 V, czyli aby ustawić stan wysoki wyjścia należy do pliku zapisać np. wartość 3 a nie 1.

## Biblioteka pythonowa

Dla ułatwienia kontroli fabryki w systemie dostępna jest biblioteka pythonowa `factory_control`, aby poznać szczegóły należy skorzystać z wbudowanej dokumentacji:

```Python
import factory_control
help(factory_control)
```
