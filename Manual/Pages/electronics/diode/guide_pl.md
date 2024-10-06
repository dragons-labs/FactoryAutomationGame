<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: PDF based
-->

# Dioda

[img]Manual/Pages/electronics/diode/diodes_pl.svg[/img]

Dioda idealna to element przewodzący prąd tylko w jednym kierunku. Symbole najpopularniejszych typów diod pokazane zostały obok. Dioda jest elementem nieliniowym – spadek napięcia na przewodzącej diodzie nie spełnia prawa Ohma i jest prawie stały (niezależny od prądu).

Rzeczywiste diody przewodzą prąd zdecydowanie chętniej w jednym kierunku niż w drugim (na ogół przewodzenie w kierunku zaporowym się pomija) ponadto charakteryzują je cechy zależne od technologi wykonania takie jak:

* spadek napięcia w kierunku przewodzenia (typowo dla diod krzemowych 0.6V - 0.7V, a dla diod Schottky’ego 0.3V)
* napięcie przebicia - napięcie, które przyłożone w kierunku zaporowym powoduje znaczące przewodzenie diody w tym kierunku - w większości przypadków parametr którego nie należy przekraczać, jednak wykorzystywane (i stanowiące ich parametr) w niektórych typach diod
* maksymalny prąd przewodzenia
* czas przełączania (związany głównie z pasożytniczą pojemnością złącza) - zdecydowanie krótszy (około 100 ps) w diodach Schottky’ego niż w diodach krzemowych,.

Ponadto stosowane są m.in.:

* diody Zenera - wykorzystuje się (charakterystyczną dla danego typu) wartość napięcia przebicia do uzyskania w układzie spadku napięcia o tej wartości,
* diody świecące (LED) - emitujące światło w trakcie przewodzenia (na elemencie występuje stały spadek napięcia, jasność zależy od natężenia prądu),
* fotodiody - będące detektorami oświetlenia (przewodzenie spolaryzowanej w kierunku zaporowym zależy od ilości padającego na element światła, niespolaryzowana pod wpływem oświetlenia staje się źródłem prądu).

## resystor przy diodach LED

Dioda jest elementem dla którego nie jest spełnione prawo Ohma. Dioda charakteryzuje się prawie stałym spadkiem napięcia w kierunku przewodzenia.

Dlatego, jeżeli do diody przyłożymy napięcie większe od jej napięcia przewodzenia (np. do czerwonej diody LED o spadku około 1.7V przyłożymy napięcie 5V) przez układ taki popłynie bardzo duży prąd (często równy prądowi zwarciowemu naszego źródła), co doprowadzi do zniszczenia diody.

Z tego powodu diody LED podłączamy prawie zawsze (wyjątkiem są diody zasilane ze źródła prądowego) z szeregowym rezystorem służącym do ograniczenia prądu. W przypadku innego typu diod prąd przez nie płynący też musi być limitowany w jakiś sposób - np. w prostownikach rolę tego rezystora pełni obciążenie.

## prostownik

Prostownik służy do zamiany napięcia przemiennego (zmieniającego znak) na napięcie zmienne o stałym znaku. Funkcję tą może pełnić nawet pojedyncza dioda – mamy wtedy do czynienia z prostownikiem jednopołówkowym, charakteryzującym się tym że napięcie na jego wyjściu spada przez połowę okresu wynosi zero.

Lepszym i częściej stosowanym rozwiązaniem jest prostownik pełnookresowy (dwupołówkowy). Najczęstszą jego realizacją jest tzw. mostek Graetza, czyli układ 4 diod połączonych w taki sposób iż dwie z nich zawsze (w każdym punkcie napięcia wejściowego) przewodzą. Wadą takiego układu jest znaczny spadek napięcia na mostku, wynoszący dwukrotność spadku napięcia na pojedynczej diodzie.

## dzielnik napięcia z diodą Zenera

W rozdziale \ref{dzielnik} omawialiśmy rezystancyjny dzielnik napięcia złożony z dwóch rezystorów. Wadą takiego układu była duża zależność napięcia wyjściowego od obciążenia. Zjawisko to można ograniczyć zastępując jeden z rezystorów (ten równolegle połączony z obciążeniem) diodą Zenera w polaryzacji zaporowej, która charakteryzuje się dość stałym spadkiem napięcia. Zobacz symulację \url{http://ln.opcode.eu.org/zener}, zauważ że nadal nie jest to rozwiązanie idealne, ale znacznie bardziej stabilne od poprzedniego.
