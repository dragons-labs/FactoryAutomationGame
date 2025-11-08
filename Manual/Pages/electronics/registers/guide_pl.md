<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Przerzutniki i rejestry

## przerzutniki i ich budowa

RS Flip-flop (RS Latch) jest podstawowym układem służącym do zapamiętania jednego bitu informacji. Posiada on dwa wejścia (set i reset) i dwa wyjścia (Q i NOT Q), wejścia mogą reagować na stan wysoki (oznaczane jako S i R) lub niski (oznaczane jako wejścia zanegowane  S i  R), jedno z wyjść może być jedynie wewnętrzne (nie wyprowadzone na zewnątrz układu). Podanie stanu wysokiego na wejście S (niskiego na  S) powoduje wystawienie stanu wysokiego na wyjściu Q, a podanie stanu wysokiego na wejście R (niskiego na  R) powoduje wystawienie stanu niskiego na wyjściu Q. Stan na wyjściu Q nie zmienia się po zmianie wejść S i R na stan niski (zostaje zapamiętany).

## zatrzask a przerzutnik

Zatrzask jest elementem reagującym na poziom sygnału na wejściu "enable" (E). W przypadku nie zanegowanego wejścia E, jeżeli jest ono w stanie wysokim sygnał na wyjściach (Q i NOT Q) jest funkcją sygnałów wejściowych, natomiast stan niski wejścia E blokuje zmianę sygnału wyjściowego (zostaje on zapamiętany).

Przerzutnik jest elementem reagującym na zbocze sygnału na wejściu "clock" (CLK). W zależności od konstrukcji może reagować na zbocze narastające, opadające albo na oba (wtedy na jednym realizuje odczyt wejść a na drugim zmianę stanu wyjść).

## zatrzask i przerzutnik D

Posiada jedno wejścia sygnałowe "data" (D) oraz wejście "enable" (E) w przypadku zatrzasku lub wejście "clock" (CLK) w przypadku przerzutnika. Może także posiadać asynchroniczne (niezależne od stanu wejścia E / CLK) wejścia reset i set (zanegowane lub proste). Obniżenie sygnału E lub zbocze sygnału CLK powodują zapamiętanie (i wystawienie na wyjściu Q) stanu wejścia D.

## rejestry

Mianem rejestru n-bitowego określa się zespół n przerzutników (rzadziej zatrzasków), często z uwspólnionym sterowaniem (sygnały clock, set, reset, etc) służący do zapamiętania n-bitowej wartości (liczby). W zależności od sposobu zapisu i odczytu można wyróżnić:

### rejestry równoległe

Posiadają taką samą liczbę wejść jak i wyjść, sygnał na i-tym wyjściu jest bezpośrednio powiązany z sygnałem z i-tego wejścia (jest sygnałem zapamiętanym z tego wejścia).

### rejestry szeregowe serial-input

Z kolejnymi sygnałami zegarowymi odczytywany jest stan wejścia szeregowego, a stan poprzedni przenoszony jest do kolejnego przerzutnika w ramach rejestru. W ten sposób po n cyklach zegara n-bitowy rejestr ma zapisaną nową zawartość. Często posiada zespolony z nim rejestr równoległy zapobiegający zmianie stanu wyjść w trakcie ładowania danych z wejścia szeregowego przepisanie danych z rejestru przesuwnego do rejestru odpowiedzialnego za sterowanie wyjściami sterowane jest osobnym sygnałem zegarowym.

### rejestry szeregowe paraller-input serial-output

Z kolejnymi sygnałami zegarowymi na wyjście szeregowe wystawiany jest stan kolejnego z rejestrów wejściowych. Wariant asynchroniczny posiada osobny sygnał powodujący odczyt wejść do rejestru (sygnał działa jak "enable" w zatrzaskach). Wariant synchroniczny posiada sygnał decydujący o tym czy na zboczu zegara dokonywany jest odczyt wejść czy też przesuwanie zawartości rejestru umożliwiający odczyt z wyjścia szeregowego.

### liczniki

Z kolejnymi sygnałami zegarowymi zwiększana jest o jeden wartość rejestru. Prostszy w budowie licznik asynchroniczny ma większe (i w dodatku rosnące wraz z bitowością licznika) ograniczenia dotyczące szybkości zliczania od licznika synchronicznego, ze względu na opóźnienie z jakim dochodzi zliczany sygnał (CLK) do kolejnych stopni licznika.
