<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Układy programowalne
====================

Układy programowalne można podzielić na dwie podstawowe grupy, czyli układy z programowalną strukturą logiczną oraz systemy procesorowe.

## Układy procesorowe

[img=1000%]Manual/Pages/electronics/programmable/cpu_pl.svg[/img]

Układy procesorowe to systemy wykonujące ciąg instrukcji pobieranych z jakieś pamięci. Składają się one z procesora, pamięci programu i pamięci danych. Procesor odpowiedzialny jest za interpretację i wykonywanie kolejnych instrukcji, pamięć przechowuje instrukcje i dane. W zależności od stosowanej architektury kod programu, a raczej kod maszynowy utworzony w wyniku kompilacji kodu programu, może znajdować się albo w tej samej pamięci w której przechowujemy również dane albo może mieć osobną, wydzieloną pamięć.

Systemami procesorowymi są zarówno systemy komputerowe, takie jak PCty czy laptopy, są nimi telefony komórkowe, zarówno smartfony jak i te bardziej prymitywne, są nimi duże systemy obliczeniowe, a także różnego rodzaju mikrokontrolery znajdujące się w sterownikach przemysłowych, centralkach alarmowych, telewizorach, sprzęcie AGD i tak dalej.

Procesor pracuje w cyklach rozkazowych, w ramach których przetwarza pojedynczą instrukcję. Cykl taki może trwać od 1 do kilku lub więcej cykli zegarowych i typowo składa się z następujących kroków:

1. pobranie instrukcji z pamięci - realizowane jest poprzez wystawienie na szynę adresową zawartości *licznika programu* (zawierające adres instrukcji do wykonania) oraz wygenerowanie cyklu odczytu z pamięci, po wykonaniu odczytu danych następuje ich zapamiętanie w *rejestrze instrukcji* oraz zwiększenie wartości *licznika programu* o jeden; (zawartość rejestru *licznika programu* po resecie procesora określa skąd pobierana będzie pierwsza instrukcja, pod takim adresem zazwyczaj umieszczana jest jakaś pamięć typu ROM lub flash)
2. dekodowanie instrukcji - układ dekodera (np. oparty o PLA) dokonuje zdekodowania instrukcji znajdującej się w *rejestrze instrukcji* i konfiguracji procesora w zależności od jej kodu i (opcjonalnie) jej argumentów; może to być np.:
	* odpowiednie ustawienie multiplekserów pomiędzy rejestrami a jednostką ALU oraz wystawienie odpowiedniego kod operacji dla ALU (celem wykonania operacji arytmetycznej na wartościach rejestrów)
	* wystawienie zawartości wskazanego rejestru na szynę adresową, podłączenie wskazanego rejestru do szyny danych oraz skonfigurowanie operacji odczytu/zapisu (celem wykonania odczytu lub zapisu wartości rejestru z/do pamięci)
3. wykonanie instrukcji - realizacja wcześniej zdekodowanej instrukcji zgodnie z ustawioną konfiguracją procesora

Instrukcje skoku polegają na załadowaniu nowej wartości do *licznika programu*, w przypadku skoków warunkowych jest to uzależnione od stanu *rejestru flag*, które ustawiane są w oparciu o wynik ostatniej operacji wykonywanej przez ALU.

Trochę uproszczony model działania procesora może wyglądać w sposób następujący: Procesor wystawia na szynę adresową magistrali umożliwiającej dostęp do pamięci adres będący zawartością tak zwanego licznika programu. Jest to adres instrukcji, która ma zostać pobrana i wykonana. Po wystawieniu tego adresu generowany jest cykl odczytu na tej szynie. A odczytany kod instrukcji zapamiętywany jest w rejestrze instrukcji, następuje też zwiększenie licznika programu o 1 po to żeby móc w następnym cyklu pobrać kolejną instrukcję.
	
Następnym krokiem jest dekodowanie instrukcji – znajdujący się w procesorze układ dekodera dokonuje zdekodowania instrukcji znajdującej się we wspomnianym rejestrze i konfiguracji procesora w zależności od jej kodu i opcjonalnie argumentów. Konfiguracja ta może polegać na ustawienie odpowiednich multiplekserów, czyli właśnie takich przełączników elektronicznych pomiędzy rejestrami a jednostką wykonującą obliczenia (tak zwanym ALU – jednostką arytmetyczno-logiczną), wystawieniu odpowiedniego kodu operacji dla ALU (celem wykonanie operacji na przykład na zawartości określonych rejestrów). Może to być także podpięcie wskazanego rejestru do szyny danych (celem skomunikowania go z pamięcią - wykonania odczytu lub zapisu do pamięci, bądź celem załadowania jego wartości do licznika programu aby wykonać skok) i tym podobne operacje. Ostatnim krokiem takiego cyklu jest wykonanie tych operacji, czyli wykonanie wcześniej zdekodowanej instrukcji, zgodnie z ustawioną konfiguracją procesora.

Przedstawiony model działania jest przykładowym i w rzeczywistym procesorze może to wyglądać odmiennie - np. długość instrukcji może być większa niż długość słowa używanego przez procesor / szerokość szyny danych co rozbudowuje fazę pobierania instrukcji z pamięci (instrukcja będzie ładowana w kilku fazach, gdyż cała instrukcja nie mieści się jednorazowo na szynie danych), mogą występować instrukcje bardziej złożone (np. operacje wykonywane z argumentem pobieranym z pamięci a nie rejestru), może także występować więcej faz (np. poprzez wydzielenie faz dostępu do pamięci, czy zapisywania wyników działania instrukcji).

Procesor może również działać potokowo, czyli fazy mogą się na siebie nakładać – podczas gdy jedna instrukcja jest wykonywana to kolejna może być już dekodowana. Oczywiście wtedy procesor musi wykonywać pewne założenia co do prawdziwości skoków warunkowych, czyli na przykład wykonuje instrukcje skoku warunkowego, ale dekoduje już instrukcję która jest po niej, tak jakby skok miał nie zajść. W takiej sytuacji jeżeli skok zachodzi to wtedy ta zdekodowane instrukcja jest unieważniona, potok należy zapełnić od nowa i nie udaje się wykorzystać przyspieszenia związanego z wielopotokowością. Na takiej pracy potokowej opiera się tak zwany Hyper Threading dostępny w niektórych procesorach, jednak jak się przekonaliśmy taka praca potokowa nie jest równoważna z większą ilością niezależnych rdzeni.

Magistrala pomiędzy procesorem a pamięcią często jest magistralą równoległą, na której mogą się znaleźć też inne urządzenia wejść wyjść dostępne pod innymi adresami. W niektórych konstrukcjach mają one wydzieloną przestrzeń adresową, a w innych wspólną z pamięcią.

### Mikrokontrolery

Przykładem systemu mikroprocesorowego, będącego jednocześnie przykładem układu typu system on chip, są mikrokontrolery. W jednym układzie scalonym zawierają one procesor, pamięć operacyjną RAM, pamięć stałą typu flash do przechowywania kodu programu (nie jest on w ich wypadku ładowany do RAMu, tylko wykonywany bezpośrednio z pamięci flash). Bardzo często w układzie tym znajdują się również różnego rodzaju układy wejścia-wyjścia, takie jak porty GPIO, które umożliwiają ustawienie lub odczyt stanu danej nóżki układu, mogą nimi być bardziej zaawansowane interfejsy jak porty szeregowe USART, I2C, SPI. Mogą to być także przetworniki analogowo-cyfrowe (umożliwiające pomiar wartości jakiegoś napięcia – sygnału analogowego) i cyfrowo analogowe (umożliwiające wystawienie napięcia o danej wartości).
