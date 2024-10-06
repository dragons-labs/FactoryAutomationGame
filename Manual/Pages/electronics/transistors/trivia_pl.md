<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: PDF based
-->

# Tranzystory

## Wzmacniacz

Omawiając poszczególne typy tranzystorów skupialiśmy się na ich pracy w roli przełącznika (klucza), działającego w dwóch stanach – przewodzenia (nasycenia) i zatkania.
Jednak tranzystor będąc elementem o regulowanym przewodzeniu może zostać wykorzystany także do wzmacniania sygnałów, czyli wytworzenia na swoim wyjściu sygnału proporcjonalnego do sygnału wejściowego tyle że wzmocnionego.
Wzmacnianiu może ulegać sygnał napięciowy lub prądowy (najprostszym przypadkiem jest wzmocnienie prądu bazy jako prądu kolektora *I(C) = β · I(B)* w tranzystorze bipolarnym).

[img]Manual/Pages/electronics/transistors/opamp.svg[/img]

Często do wzmacniania sygnału zamiast pojedynczego tranzystora wykorzystujemy układy scalone (złożone z wielu tranzystorów) nazywane wzmacniaczami operacyjnymi.
Cechują się one bardzo dużym wzmocnieniem różnicy napięcia pomiędzy swoimi wejściami, pożądane wzmocnienie uzyskuje się dobierając zewnętrzne elementy pętli ujemnego sprzężenia zwrotnego
	(w najprostszym przypadku na jedno wejście podajemy sygnał wejściowy, a na drugie odpowiednio przeskalowany przy pomocy dzielnika rezystancyjnego sygnał wyjściowy).

## Przełączanie AC

Tranzystory stosowane są powszechnie do przełączania w obwodach prądu stałego. Istnieją także elementy półprzewodnikowe mogące pełnić funkcję przełączającą w obwodach prądu przemiennego - są to przede wszystkim triaki.
