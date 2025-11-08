<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Wstęp do elektroniki cyfrowej

Cyfrowość elektroniki polega na reprezentacji sygnałów w formie abstrakcyjnych wartości liczbowych, zamiast bezpośredniej wartości elektrycznych.

Liczby te zazwyczaj zapisywane są w systemie dwójkowym. Napięcie poniżej jakiejś wartości odpowiada zeru na danej cyfrze, natomiast powyżej jakiegoś poziomu jedynce. Kolejnymi cyframi są napięcia w różnych miejscach obwodu („na kolejnych przewodach”) lub w na pojedynczym przewodzie w kolejnych jednostkach czasu.

Taka reprezentacja w postaci dyskretnych poziomów napięć, identyfikowanych jako zera i jedynki – wartości logicznego fałszu i prawdy, pozwala między innymi zwiększyć odporność na zakłócenia i bezstratnie replikować taką cyfrową informację.

## Algebra Boole'a

### podstawowe operacje i elementy neutralne

* suma logiczna (OR, +, |, ||):
	* a OR 1 = 1
	* a OR 0 = a
	* a OR a = a
* iloczyn logiczny (AND, *, &, &&)
	* a AND 1 = a
	* a AND 0 = 0
	* a AND a = a
* negacja (NOT, ~, ^, !)
	* NOT 1 = 0
	* NOT 0 = 1
	* NOT (NOT a) = a

### własności działań

* łączność:
	* (a OR b) OR c = a OR (b OR c)
	* (a AND b) AND c = a AND (b AND c)
* przemienność:
	* a OR b = b OR a
	* a AND b = b AND a
* rozdzielność:
	* a AND (b OR c) = (a AND b) OR (a AND c)
	* a OR (b AND c) = (a OR b) AND (a OR c)
* absorpcja:
	* a AND (b OR a) = a
	* a OR (b AND a) = a
* negacja sumy i iloczynu:
	* NOT (a OR b) = (NOT a) AND (NOT b)
	* NOT (a AND b) = (NOT a) OR (NOT b)
* pochłanianie:
	* a OR (NOT a) = 1
	* a AND (NOT a) = 0

### dodatkowe operacje

* alternatywa wykluczająca (XOR):
	* a XOR b = (a AND (NOT b)) OR (b AND (NOT a))
	* a XOR 0 = a
	* a XOR a = 0
* a NAND b = NOT (a AND b)
	* (a NAND b) NAND (c NAND d) <!--= NOT( (NOT(a AND b)) AND (NOT(c AND d)) ) = NOT(NOT( (a AND b) OR (c AND d) ))--> = (a AND b) OR (c AND d)
* a NOR b = NOT (a OR b)
	* (a NOR b) NOR (c NOR d) <!--= NOT( (NOT(a OR b)) OR (NOT(c OR d)) ) = NOT(NOT( (a OR b) AND (c OR d) ))--> = (a OR b) AND (c OR d)
* a XNOR b = NOT (a XOR b)


## system dwójkowy

### reprezentacja liczb

Pojedynczą cyfrę systemu dwójkowego (przybierającą wartość 0 albo 1) określa się mianem **bit**u, liczby reprezentowane są jako ciągi takich cyfr. Terminem **bajt** określa się zazwyczaj ciąg o długości 8 bitów (ale w niektórych systemach ciąg o innej długości).

Podstawowym sposobem zapisu liczb całkowitych nie ujemnych w systemie dwójkowym jest **naturalny kod binarny** (**NKB**), w którym np. 4 bitowy ciąg `a₃ a₂ a₁ a₀` reprezentuje liczbę *2⁰ · a₀ + 2¹ · a₁ + 2² · a₂ + 2³ · a₃*.

Podstawowym sposobem zapisu liczb całkowitych (ze znakiem) jest **kod uzupełnień do dwóch** (**U2**) w którym n-bitowa liczba reprezentowana przez ciąg `aₙ₋₁ ... a₃ a₂ a₁ a₀` będzie miała wartość *2⁰ · a₀ + 2¹ · a₁ + 2² · a₂ + ... + 2ⁿ⁻² · aₙ₋₂ - 2ⁿ⁻¹ · aₙ₋₁*. Jako że najstarszy bit wchodzi z ujemną wagą, jego ustawienie na 1 oznacza liczbę ujemną (ale nie jest to kod znaku). Warto zauważyć kompatybilność z NKB.

Liczby zapisywane w tych kodowaniach systemu dwójkowego oznacza się często przy pomocy prefiksu "0b" albo sufiksu "b", np. `0b101 = 101b` reprezentuje liczbę 5 w systemie dziesiętnym (*2⁰ · 1 + 2¹ · 0 + 2² · 1 = 5*).

Oprócz podanych istnieje jeszcze kilka stosowanych sposobów zapisu liczb binarnych takich jak (dla liczb bez znaku): kod "1 z n", kod Graya, kod Johnsona, (dla liczb ze znakiem): kod znak-moduł, kod uzupełnień do jedności (U1). Odmiennym zagadnieniem jest kodowanie liczb zmiennoprzecinkowych.

### zapis hexalny (szesnastkowy)

Celem skrócenia zapisu liczb binarnych często zapisuje się je w postaci szesnastkowej, jest on wygodniejszy od dziesiątkowego gdyż każda cyfra systemu szesnastkowego rozkłada się na dokładnie 4 bity, co pozwala na niezależne konwertowanie poszczególnych cyfr szesnastkowych / ciągów 4 bitowych i ich łączenie w dłuższe ciągi.

Cyfry o wartościach powyżej 9 zapisuje się jako kolejne małe lub wielkie litery a, b, c, d, e, f. Liczby zapisywane w systemie szesnastkowym oznacza się przy pomocy prefiksu "0x" lub "#" albo sufiksu "h" np. `0xc7 = #c7 = c7h` reprezentuje liczbę 199 w systemie dziesiątkowym (*16⁰ · 7 + 16¹ · 12 = 199*). Konwersja na system binarny może odbywać się niezależnie dla każdej cyfry, jako że: `0xc = 0b1100` oraz `0x7 = 0b0111` to` 0xc7 = 0b 1100 0111`.

### reprezentacja elektryczna

Typowo logicznej 1 odpowiada stan wysoki (napięcie dodatnie), a logicznemu 0 stan niski (potencjał masy). W przypadku logiki odwróconej (ujemnej) logicznej 1 odpowiada stan niski a logicznemu zeru wysoki.
