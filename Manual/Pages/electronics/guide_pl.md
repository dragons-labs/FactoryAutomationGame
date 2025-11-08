<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Elektronika
===========

Konstruowanie układów elektronicznych pozwala na przetwarzanie sygnałów w postaci prądów i napięć elektrycznych. Dzięki temu możemy tworzyć różnego rodzaju systemy sterujące, przesyłające informacje, czy też ją przetwarzające.

## Podstawowe pojęcia

### Napięcie elektryczne

Napięcie elektryczne *U* pomiędzy punktem A i B (jakiegoś obwodu) jest to różnica potencjału elektrycznego w punkcie A i w punkcie B.
Jako że wynik odejmowania zależy od kolejności argumentów, to także znak napięcia zależy od kierunku, w którym przechodzimy po obwodzie elektrycznym.

#### Potencjał elektryczny

Potencjał to poziom energii w danym punkcie obwodu w stosunku do jakiegoś odniesienia (zwykle uziemienia). W praktyce potencjał mówi, jak dużo energii ma ładunek elektryczny w tym punkcie.

#### Masa

Masa (oznaczana jako GND) jest to umowny potencjał zerowy, względem którego wyraża się inne potencjały w układzie (co umożliwia traktowanie ich jako różnic potencjałów - napięć elektrycznych). Potencjał ten może być równy potencjałowi ziemi (masie ochronnej PE), bądź może być z nim nie związany (układy izolowane).

Można też spotkać się z układami w których wyróżnia się więcej niż jedną masę, a także (jeszcze rzadziej) takie w których nie wyróżnia się żadnego z potencjałów.

### Prąd elektryczny

Zjawisko prądu związane jest z przepływem ładunku (z uporządkowanym ruchem nośników ładunku), aby wystąpiło konieczna jest różnica potencjałów (napięcie) pomiędzy końcami przewodnika.

#### Natężenie prądu

Natężenie prądu *I* to ilość ładunku, który przepływa w jednostce czasu. Czyli określa ono intensywność przepływu ładunku. Przyjmuje się umowny kierunek przepływu prądu (bez względu na rzeczywisty kierunek przepływu nośników ładunku) od potencjału wyższego do niższego.


## Obwody elektryczne

Obwód elektryczny składa się z elementów elektrycznych oraz węzłów je łączących. Graficzną reprezentację (modelu) obwodu elektrycznego jest jego schemat.

### Podstawowe prawa

#### Pierwsze prawo Kirchhoffa

Węzeł układu (sam w sobie, pomijając zjawiska pasożytnicze) nie jest w stanie gromadzić ładunku elektrycznego zatem:
	*Suma prądów wpływających do węzła jest równa sumie prądów wypływających z tego węzła.*

#### Drugie prawo Kirchhoffa

Jeżeli rozważamy obwód zamknięty od punktu A z potencjałem *V(A)* to sumując napięcia na kolejnych elementach obwodu (oporach, źródłach napięciowych, etc) z uwzględnieniem ich znaku gdy wrócimy do punktu A to potencjał nadal musi wynosić *V(A)*, zatem:
	*Suma spadków napięć w zamkniętym obwodzie jest równa zeru.*

#### Zależność prądu i napięcia

Występuje (charakterystyczna dla danego elementu) zależność pomiędzy napięciem na jego wyprowadzeniach a płynącym prądem. 

Dla znaczącej grupy materiałów ma ona postać:
	*Prąd elektryczny płynący między dwoma punktami jest wprost proporcjonalny do napięcia między tymi punktami.* (**Prawo Ohma**)
Jednocześnie w wielu innych przypadkach zależność ta może mieć inną postać.

Stosunek napięcia pomiędzy końcami elementu (dla którego zachodzi Prawo Ohma, np. rezystora czy zwykłego kawałka przewodu) do natężenia prądu przez niego płynącego nazywamy **oporem**: *R=U/I*.

### Konwencje schematów

Nie ma oficjalnego standardu, który określałby sposób rysowania schematów elektronicznych, czy elektrycznych i używane na nich symbole. Są to powszechnie przyjęte zwyczaje. Zdarza się także, że temu samemu elementowi odpowiada kilka różnych reprezentacji graficznych.

Typowo elektronicy na schematach nie rysują źródeł napięcia (np. w postaci symbolu baterii – chyba że chodzi o podkreślenie, iż dane zasilanie faktycznie odbywa się z baterii lub akumulatora), zamiast tego umieszczają znaczniki potencjałów zasilania (np. +5V, +3V3, Vcc, Vbus) względem masy i znaczniki masy (GND, ⏚).

Typowo potencjały wyższe umieszcza się na schemacie wyżej a niższe niżej (czyli 5V będzie na górze, a GND na dole), a przepływ prąd odbywa się w relacji od lewej do prawej i z góry na dół. Jest to ogólna reguła, ułatwiająca czytanie schematów, nie jest ona jednak wyrocznią i trafiają się od niej odstępstwa, podyktowane zwiększeniem czytelności schematu.

## Zmienność w czasie

Wartość napięcia bądź prądu wytwarzanego przez dane źródło może być stała (**DC**) lub zmienna w czasie (**AC**).

Warto zauważyć że nawet w układach DC podczas załączania zasilania występuje stan przejściowy, zanim system osiągnie stan ustalony. W tym czasie prądy i napięcia w obwodach mogą gwałtownie wzrosnąć, a potem stabilizować się do wartości nominalnych. Jest to istotne dla układów z kondensatorami i indukcyjnościami, które w stanie ustalonym działają inaczej niż w chwili załączenia. O stanach przejściowych i ustalonych możemy mówić także w przypadku prądu zmiennego (AC) – stan ustalony oznacza cykliczne zmiany parametrów, zgodne z częstotliwością sygnału.

### Zasilanie vs sygnał

Terminy DC i AC często używane są w kontekście zasilania i wtedy oznaczają zasilanie stałym napięciem / prądem bądź napięciem / prądem sinusiodalnie przemiennym. Sygnały zmienne to takie, które cyklicznie zmieniają swoją wartość w czasie (np. typowy sygnał audio). Sygnały impulsowe są formą sygnałów zmiennych, charakteryzują się krótkotrwałymi zmianami wartości (np. sygnały prostokątne lub wąskie impulsy), często stosowane w cyfrowych układach logicznych i sterujących.
