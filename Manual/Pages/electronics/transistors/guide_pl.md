<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: PDF based
-->

# Tranzystory

Tranzystor jest to element o regulowanym elektrycznie przewodzeniu prądu (oporze), często wykorzystywany do wzmacniania sygnałów lub jako przełącznik elektroniczny (klucz tranzystorowy).
Klucz jest układem przełączającym wykorzystującym dwa skrajne stany pracy tranzystora - zatkania (tranzystor nie przewodzi), nasycenia (tranzystor przewodzi z minimalnymi ograniczeniami).

## NPN

Prąd przepływający pomiędzy kolektorem a emiterem jest funkcją prądu przepływającego pomiędzy bazą a emiterem: *I(C) = β · I(B)*.
Napięcie pomiędzy kolektorem a emiterem wynosi: *U(CE) = U(zasilania) - I(C) · R(load)*.
Napięcie to nie może jednak spaść poniżej wartości minimalnej wynoszącej około 0.2V, gdy z powyższych zależności wynikałby taki spadek to tranzystor pracuje w stanem nasycenia i *U(CE) ≈ 0.2V*.

[img]Manual/Pages/electronics/transistors/npn_pnp.svg[/img]

Aby wprowadzić tranzystor NPN w stan zatkania należy podać na jego bazę potencjał mniejszy lub równy potencjałowi emitera (zakładamy że potencjał kolektora jest nie mniejszy niż emitera - co ma miejsce w typowych warunkach polaryzacji tranzystora NPN), czyli *U(BE) ≤ 0*.

Aby wprowadzić tranzystor NPN w stan nasycenia należy na jego bazę wprowadzić potencjał większy od potencjałów emitera i kolektora, uzyskuje się to poprzez wprowadzenie do tranzystora prądu bazy *I(B) >> U(zasilania) / ( β · R(load))*.

Zobacz co dzieje się przy próbie podłączenia bazy tranzystora do potencjału znacznie wyższego niż potencjał emitera – złącze baza-emiter jest takim samym złączem z jakim mamy do czynienia w diodzie i tak jak w przypadku diody występuje na nim stały spadek napięcia (nie działa tu prawo Ohma). Dlatego aby ograniczyć prąd płynący tą gałęzią i zapobiec zniszczeniu tranzystora konieczne jest zastosowanie rezystora.

## PNP

Podobnie jak w NPN tyle że prąd przepływający pomiędzy emiterem a kolektorem jest funkcją prądu przepływającego pomiędzy emiterem a bazą.

Aby wprowadzić tranzystor PNP w stan zatkania należy podać na jego bazę potencjał większy lub równy potencjałowi emitera (zakładamy że potencjał emitera jest nie mniejszy niż kolektora - co ma miejsce w typowych warunkach polaryzacji tranzystora PNP), czyli *U(BE) ≥ 0*.

Aby wprowadzić tranzystor PNP w stan nasycenia należy na jego bazę wprowadzić potencjał mniejszy od potencjałów emitera i kolektora, uzyskuje się to poprzez wyprowadzenie z tranzystora prądu bazy *I(B) >> U(zasilania) / ( β · R(load))*.

Zwróć uwagę na podobieństwa i różnice w stosunku do tranzystora NPN:

* w obu wypadkach tranzystor przewodzi gdy płynie prąd bazy, ale ma on różne kierunki (w NPN wpływa on bazą do tranzystora, a w PNP wypływa z niego),
* w obu wypadkach tranzystor zostaje zatkany gdy potencjał bazy zrówna się z potencjałem emitera (ale w NPN potencjał emitera jest typowo najniższym z potencjałów w układzie, często równym masie, a w PNP najwyższym, często równym potencjałowi zasilania).

Zauważ także, że tutaj również potrzebujemy rezystora ograniczającego prąd bazy.

## N-MOSFET

[img]Manual/Pages/electronics/transistors/mosfet.svg[/img]

Prąd przepływający pomiędzy drenem (*drain*) a źródłem (*source*) jest funkcją napięcia pomiędzy bramką (*gate*) a źródłem (potencjału bramki względem źródła - *U(GS)*), bramka jest izolowana (nie płynie przez nią prąd).

W kierunku dren → źródło tranzystor ten przewodzi gdy *U(GS) > U(GS (th))*, natomiast w przeciwnym kierunku przewodzi zawsze. Dla tranzystorów N-MOSFET z kanałem wzbogacanym (*enhancement*) *U(GS (th)) > 0*, a z kanałem zubożonym (*depletion*) *U(GS (th)) < 0*.

Konkretna wartość *U(GS (th))* zależna jest od konkretnego modelu tranzystora, innym istotnym parametrem związanym z sterowaniem tranzystorem jest maksymalna i minimalna dopuszczalna wartość napięcia *U(GS)*.

Aby wprowadzić tranzystor N-MOSFET w stan zatkania należy podać *U(GS) < U(GS (th))*. Dla tranzystorów:

* z kanałem wzbogaconym wystarczy obniżyć potencjał bramki do wartości potencjału źródła (lub nawet wartości niewiele wyższej od niego)
* z kanałem zubożonym musi to być wartość poniżej potencjału źródła.

Aby wprowadzić tranzystor MOSFET w stan przewodzenia należy podać *U(GS) >> U(GS (th))*.

## P-MOSFET
Podobnie jak N-MOSFET tyle że:

* regulowane jest przewodzenie w kierunku źródło → dren (a w kierunku dren → źródło przewodzi zawsze),
* przewodzenie w kierunku źródło → dren ma miejsce gdy *U(GS) < U(GS (th))*,
* dla tranzystorów z kanałem wzbogacanym (*enhancement*) *U(GS (th)) < 0*, a z kanałem zubożonym (*depletion*) *U(GS (th)) > 0*.

Aby wprowadzić tranzystor P-MOSFET w stan zatkania należy podać *U(GS) > U(GS (th))*. Dla tranzystorów:

* z kanałem wzbogaconym wystarczy podnieść potencjał bramki do wartości potencjału źródła (lub nawet wartości niewiele niższej od niego)
* z kanałem zubożonym musi to być wartość powyżej potencjału źródła.

Aby wprowadzić tranzystor MOSFET w stan przewodzenia należy podać *U(GS) >> U(GS (th))*.

Zauważ podobieństwo w sterowaniu do tranzystorów NPN i PNP:

* N-MOSFET przewodzi gdy potencjał bramki odpowiednio wyższy od drenu, P-MOSFET gdy odpowiednio niższy
* obciążenie N-MOSFET włączane analogicznie jak NPN, a P-MOSFET jak PNP.

Zauważ różnice (bramka jest izolowana, nie płynie nią prąd (z pominięciem prądu związanego z przeładowaniem pojemności - pasożytniczego kondensatora), nie ma zatem potrzeby używania tam rezystora.


## Mostek H

[img]Manual/Pages/electronics/transistors/mostek_H_switche.svg[/img]

Mostek H jest to układ (oparty o 4 przełączniki, których rolę mogą pełnić klucze tranzystorowe) pozwalający na zmianę polaryzacji zasilania podłączonego do niego odbiornika. Układ taki złożony jest z dwóch identycznych gałęzi (S1 + S2 oraz S3 + S4, każda włączona pomiędzy dwoma biegunami zasilania). Pojedyncza taka gałąź nazywana jest pół-mostkiem i składa się z dwóch kluczy które powinny być sterowane przeciwstawnie (aby wyeliminować możliwość zwarcia zasilania z masą). Układ pół-mostka może być wykorzystywany także samodzielnie jako uniwersalny układ klucza pozwalającego na załączanie odbiornika zarówno od strony napięcia dodatniego jak i od strony masy (w zależności od sposobu jego podłączenia) lub przełączania dwóch odbiorników (jednego umieszczonego pomiędzy zasilaniem a wyjściem mostka, a drugiego pomiędzy wyjściem a masą).

Rolę kluczy (przełączników) w ramach mostka mogą pełnić tranzystory PNP (jako S1, S3) i NPN (jako S2, S4) albo analogicznie tranzystory P-MOSFET i N-MOSFET.
