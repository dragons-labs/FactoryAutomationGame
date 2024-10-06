<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: VIP
-->

Układy programowalne
====================

## Programowalna logika

[img]Manual/Pages/electronics/programmable/memory_logic_pl.svg[/img]

Układy z programowalną strukturą logiczną, oparte są na tym że wewnątrz takiego układu programujemy jakiś układ bramek logicznych, przerzutników i tym podobnych elementów oraz ich połączeń.

Do programowania tego typu układów służą języki opisu sprzętu typu HDL (hardware description language). Najczęściej jest to VHDL lub Verilog i zamiast wykonywanego kodu opisuje strukturę układu logicznego (połączenia bramek, tablice prawdy, etc), która następnie jest programowana w fizycznej kości. Pozwala to na zaprogramowanie jakiegoś algorytmu, który realizowany będzie czysto sprzętowo. Taka realizacja sprzętowa, dzięki urównolegleniu wielu procesów jest zazwyczaj znacznie szybsza w działaniu niż wersja programowa.

Najprostszym koncepcyjnie sposobem realizacji czegoś takiego jest układ pamięciowy, który pozwala na zrealizowanie dowolnej funkcji logicznej, czyli dowolnego układu bramek. Jeżeli weźmiemy pamięć która będzie miała 2ⁿ bitów i będzie adresowana n-bitową szyną adresową, to z każdym adresem związany jest jakiś jeden bit i każdy bit odpowiada jednemu adresowi. Pamięć tego typu pozwala na zapisanie tabeli prawdy dowolnej funkcji która posiada n wejść i jedno wyjście – każdemu wejściu odpowiada jeden bit adresu, a związana z daną kombinacją wejść, wartość wyjścia zapisana jest w tej pamięci.

Układy tego typu mają spore zastosowanie praktyczne i pozwalają na konstruowanie układów działających szybciej niż układy procesorowe Zastosowanie programowalnych układów logicznych jest prostsze i szybsze niż konstruowanie takich rozwiązań z pojedynczych elementów takich jak bramki, a przy produkcji na małą i średnią skalę także tańsze od projektowania i produkcji dedykowanych układów scalonych. Pozwala też na aktualizację takiego „sprzętu” poprzez zaprogramowanie poprawionej jego wersji.

Do kategorii tej zaliczają się układy typu:

* SPLD
	* PLE - programowalna matryca bramek OR
	* PAL i GAL - programowalna matryca AND z dodatkowymi bramkami OR (często także obudowana rejestrami i multiplekserami na wyjściach)
	* PLA - programowalne matryce AND i OR
* CPLD
* FPGA - programowalny element pamięciowy (możliwość zdefiniowania dowolnej - na ogół 4 wejściowej - funkcji w każdym elemencie logicznym, programowalne połączenia między elementami logicznymi i pinami, itd)
