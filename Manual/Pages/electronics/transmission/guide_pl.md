<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Transmisja - sterowanie linią

## bufory

Bufor jest to układ przekazujący sygnał logiczny z wejścia na wyjście. Bufor może służyć do:

* regeneracji sygnału,
* uniemożliwieniu wprowadzenia sygnału z jego strony wyjściowej na wejściową,
* decydowania o jego przepuszczeniu lub nie (trój-stanowy),
* decydowania o kierunku przepuszczenia sygnału (dwa trój-stanowe albo trój-stanowy dwukierunkowy),
* konwersji na linię open-collector / open-drain,
* negacji sygnału (niektóre bufory realizują funkcję NOT).

## enkodery

Enkoder "n to m" jest to układ o n wejściach, który na swoim m bitowym wyjściu wystawia numer (typowo) wejścia o najwyższym numerze, które znajduje się w stanie niskim. Możliwe są też warianty wystawiające numer pierwszego (a nie ostatniego) w kolejności wejścia lub wybierające wejście ze stanem wysokim.

Jako że wejścia numerowane są zazwyczaj od zera do 2m to układ najczęściej posiada dodatkowe wyjście informujące że którekolwiek z wejść jest w stanie aktywnym. Typowo numer wystawiany jest w postaci NKB, ale możliwe są inne kodowania.

Układ pozwala na redukcję ilości wejść potrzebnych do obsługi n-bitowego sygnału w którym tylko jeden bit może być ustawiony lub w którym można pozwolić sobie na obsługę kolejnych linii z kasowaniem ich bitu (np. wektor przerwań z priorytetyzacją).

## dekodery

Dekoder "m to n" jest układem o działaniu przeciwnym do enkodera. Aktywuje on wyjście o numerze odpowiadającym wartości na m-bitowym wejściu adresowym. Typowo posiada także wejście zezwolenia na aktywację wyjść, które może zostać użyte do podłączenia informacji że którekolwiek z wejść enkodera było w stanie aktywnym lub do podłączenia sygnału danych z multipleksowanej linii celem jej demultipleksacji.

## (de)multipleksery cyfrowy

Multiplekser cyfrowy (jednokierunkowy) na wyjście kopiuje stan wskazanego (poprzez adres podany na wejście adresowe) wejścia. W przypadku braku sygnału "enable" w zależności od rozwiązania wyjście pozostanie w stanie niskim lub wysokiej impedancji.

Demultiplekser cyfrowy (jednokierunkowy) to zazwyczaj układ dekodera w którym na wejście enabled podany jest sygnał z multipleksowanej linii. Nie wybrane wyjścia pozostają w stanie niskim lub wysokim (zależnie od użycia nieodwracającego lub odwracającego dekodera). Cyfrowe demultipleksery z 3 stanowym wyjściem są rzadkością. Demultipleksację można rozwiązać także przy pomocy odpowiednio sterowanych (np. z dekodera adresu) buforów trój-stanowych lub dwu-wejściowych multiplekserów.

## (de)multipleksery analogowy

Multiplekser analogowy (dwukierunkowy) działa na zasadzie przełącznika łączącego wskazane wejście z wyjściem, dzięki elektrycznemu "zwarciu" (na ogół rezystancja takiego zwarcia to kilkadziesiąt omów) wejścia z wyjściem transmisja może odbywać się w obu kierunkach. Pozwala to także na wykorzystanie tego samego układu w roli multipleksera i demultipleksera.
