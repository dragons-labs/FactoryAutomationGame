<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: VIP based
-->

## Przetworniki ADC i DAC
Przetwornik analogowo-cyfrowe (ADC) służy do konwersji sygnału analogowego na postać cyfrową. Realizowane jest to poprzez pomiar napięcia, na ogół w regularnych odstępach czasowych (celem uzyskania przebiegu sygnału a nie tylko wartości chwilowej). Przetwornik ADC o porównaniu bezpośrednim realizowany jest w oparciu o zespół komparatorów analogowych (od ich liczby zależy bitowość danego przetwornika, ale ich liczba nie jest równa bitowości) które używają różnych napięć referencyjnych (typowo uzyskiwanych z jednego napięcia referencyjnego poprzez dzielnik). Stan z komparatorów podawany jest na enkoder celem konwersji do kodu binarnego. Inne stosowane sposoby realizacji przetworników ADC opierają się o pojedynczy komparator i podawanie na niego narastającego napięcia referencyjnego oraz zliczanie liczby kroków podnoszenia tego napięcia bądź podawaniu kolejnych napięć z przetwornika DAC i wyszukiwaniu tego które jest najbliższe wejściowemu.

Przetwornik cyfrowo-analogowy (DAC) służy do konwersji sygnału cyfrowego na analogowy. Oparty jest na zasadzie sumatora napięć, którego wejścia załączane są w zależności od ustawienia lub nie danego bitu w konwertowanej wartości. Typowo zamiast stosowania różnych wartości napięć i jednakowych rezystorów (jak w sumatorze), stosuje się różne wartości załączanych rezystorów i jednakowe napięcie do którego są podłączone. Może być też oparty na wytwarzaniu sygnału PWM i podawaniu go na kondensator filtrujący, z ewentualnym sprzężeniem zwrotnym (do korekcji wartości PWM) realizowanym przez ADC.

### pomiar napięcia i prądu

Pomiar napięcia realizuje bezpośrednio przetwornik ADC. W przypadku konieczności pomiaru wysokich napięć stosuje się przekładniki napięciowe, będące w istocie transformatorami o dobrze ustalonych parametrach pomiarowych. W przypadku małych napięć konieczne może okazać się ich wzmocnienie np. z użyciem wzmacniacza operacyjnego.

Pomiar prądu może być realizowany na kilka sposobów:

* jako pomiar napięcia na rezystancji włączonej w mierzony obwód; umożliwia pomiar prądów zmiennych i stałych
* poprzez przekładnik prądowy - transformator włączony szeregowo w obwód lub toroidalną cewkę przez którą przeprowadzony jest przewodnik w którym dokonywany jest pomiar prądu (pojedyncze uzwojenie pierwotne); stosuje się tylko dla prądów przemiennych (zmienny prąd w przewodzie powoduje powstanie indukcji magnetycznej która wymusza przepływ prądu w obwodzie pomiarowym)
* z wykorzystaniem efektu Halla (prąd może przepływać bezpośrednio przez układ pomiarowy, może płynąć pętlą ścieżki umieszczoną z drugiej strony płytki drukowanej niż czujnik efektu Halla lub może być realizowany analogicznie do toroidalnego przekładnika prądowego); umożliwia pomiar prądów zmiennych i stałych
