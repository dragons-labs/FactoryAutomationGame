<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Bramki

[img]Manual/Pages/electronics/digital_gates/gates_pl.svg[/img]

Bramki są układami elektronicznymi realizującymi podstawowe funkcje logiczne. Obok zostały przedstawione podstawowe symbole poszczególnych bramek w wariancie dwu wejściowym, spotkać się można także z symbolami z zanegowanymi wejściami - w takiej konwencji np. bramka AND reprezentowana jest przez NOR z zanegowanymi wejściami. Bramki (z wyjątkiem buforów oraz bramki NOT), mogą występować także w wariantach wielo-wejściowych (ze względu na łączność podstawowych operacji nie ma wątpliwości co don wyniku jaki powinna dawać np. 8 wejściowa bramka OR). Na ogół w pojedynczym układzie scalonym znajduje się kilka jednakowych bramek.

## trój-stanowe

Typowa bramka wymusza (w sposób silny) na swoim wyjściu stan wysoki lub niski, co uniemożliwia bezpośrednie łączenie wyjść bramek.
Bramki trój-stanowe mają możliwość skonfigurowania wyjścia w stan *wysokiej impedancji* czyli nie wymuszania żadnej jego wartości.
Sterowanie załączeniem bądź wyłączeniem wyjścia (przełączeniem w stan wysokiej impedancji) odbywa się przy pomocy zewnętrznego sygnału sterującego "output enabled" ("OE"), sygnał ten może występować w postaci prostej i zanegowanej.
Pozwala to na podłączanie do jednej linii wielu bramek i decydowaniu która z nich będzie nią sterować.

## open collector / drain

Są kolejnym rodzajem bramek których wyjścia można podłączać do wspólnej linii. Układy te posiadają wyjście w postaci tranzystora zwierającego linię wyjściową do masy, z tego względu samodzielnie zapewniają jedynie stan niski wyjścia (są w stanie wymusić stan niski, ale nie mają możliwości wymuszenia stanu wysokiego).

Stan wysoki musi zostać zapewniony zewnętrznym rezystorem podciągającym. Pozwala to stosować na takiej linii inny poziom stanu wysokiego niż na wejściach takiej bramki oraz pozwala na sterowanie wspólnej linii przez wiele bramek (czyli łączenie wyjść bramek, jednak w odróżnieniu od bramek trój-stanowych nie wymaga dodatkowych sygnałów sterujących).

[img]Manual/Pages/electronics/digital_gates/open_drain.svg[/img]

Na schemacie obok przedstawiono dwa układy (U1 i U2) typu open-drain sterujące wspólną linią wyjściową w układzie *suma na drucie*. Jeżeli jeden z podłączonych do linii układów będzie miał wewnętrzne wyjście ("ctrl*{X*") w stanie wysokim to jego wyjście OC będzie zwarte do masy (negacja na tranzystorze N-MOS lub NPN), wtedy też cała linia będzie w stanie niskim.
