<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Program w działaniu
===================

W przypadku uruchamiania naszego kodu bezpośrednio na sprzęcie, bez pośrednictwa systemu operacyjnego, jest on jedynym kodem który przetwarza procesor. Typowo program taki korzysta bezpośrednio z mechanizmów sprzętowych oferowanych przez dany procesor i platformę, a jego zakończenie, przerwanie wykonywania powoduje zawieszenie się lub wyłączenie całego systemu.

Sytuacja zmienia się gdy korzystamy z (wielozadaniowego) systemu operacyjnego. Wtedy nasz program jest jednym z wielu działających procesów. Każdy z procesów może znajdować się w jednym z kilku stanów, do najważniejszych należą:

* wykonywanie (kod procesu jest w danej chwili aktywnie wykonywany na procesorze)
* oczekiwanie na dostępność CPU (kod procesu jest gotowy do wykonywania, jednak nie jest aktualnie wykonywany ze względu na brak wolnego procesora / rdzenia)
* oczekiwanie na inne zdarzenia (np. oczekiwania na dane wprowadzane przez użytkownika, na dane odbierane z sieci, na upłynięcie wyznaczonego okresu czasu, itd)

Kolejkowanie procesów oczekujących na możliwość wykonywania na CPU i przełączanie pomiędzy nimi (w celu podziału czasu procesora na różne zadania) jest jednym z zadań systemu operacyjnego.

Innymi zadaniami systemu operacyjnego jest wsparcie dla tworzenia nowych procesów, czyli tworzenia procesów potomnych (rozgałęziania procesu) oraz zapewnienia mechanizmu przekazywania parametrów do nowo tworzonego procesu i możliwości komunikacji z nim. Na mechanizmy te składają się:

* argumenty linii poleceń, czyli lista napisów przekazana w trakcie uruchamiania programu, wykorzystywana typowo do określenia opcji i argumentów wpływających na jego zachowanie oraz określających dane do przetworzenia
* zmienne środowiskowe, czyli (określony przez proces rodzica) zbiór par klucz-wartość, z którego wartości mogą być pozyskane przez program z pomocą klucza i mogą wpływać na działanie programu
* kod powrotu, czyli numeryczna wartość określająca status zakończenia procesu zwracana do procesu rodzica
* strumienie standardowego wejścia, wyjścia i wyjścia błędu, umożliwiające przekazywanie danych pomiędzy procesami, a domyślnie wykorzystywane do przekazywania (tekstowego) inputu i output od/do użytkownika programu

W przypadku programów działających w środowisku graficznym (i korzystających z jego mechanizmów) do mechanizmów tych należy dodać przekazywanie zdarzeń i danych związanych z tym środowiskiem (takich jak np. miejsce kliknięcia myszą, dane schowka systemowego, itd.). Funkcjonalność ta często realizowana jest przez usługę systemową odpowiedzialną za działanie środowiska graficznego.


Aplikacje, procesy, wątki i separacja zasobów
---------------------------------------------

* W ramach systemu operacyjnego może być uruchomionych nie tylko wiele różnych programów, ale także wiele kopi tego samego programu (nawet uruchamianych z tego samego pliku wykonywalnego).
* Pojedynczy program może działać w ramach jednego lub (gdy wykorzystuje mechanizmy tworzenia procesów potomnych i wykonuje w nich własny kod) wielu procesów.
* Proces:
	* Posiada przydzielane zasoby systemowe (takie jak pamięć, uchwyty do plików, dostęp do urządzeń, ...).
	* Może być wstrzymany i/lub zakończony zewnętrznie (bez jego woli, przez system operacyjny).
	* System operacyjny zwalnia automatycznie wszystkie przydzielone zasoby po zakończeniu procesu.
	* Procesy mogą być wykonywane równolegle (czyli w tym samym czasie na różnych rdzeniach procesora mogą wykonywać się procesy związane z różnymi programami, jak również z tym samym programem).
	* Każdy z procesów działających na komputerze ma dostęp do pełnej przestrzeni adresowej pamięci operacyjnej, jednak nie posiada dostępu do pamięci innych procesów. Czyli proces A i proces B pod tym samym adresem mogą przechowywać różne dane.
	* W przypadku zakończenia działania procesu rodzica procesy potomne mogą zostać zakończone) lub mogą kontynuować swoje działanie (funkcję rodzica przejmuje wtedy inny proces).
* Oprócz pełnoprawnych procesów wyróżnia się także wątki (lekkie procesy). Wątki:
	* Są ściśle związane z procesem który je utworzył (w szczególności zostaną zakończone razem z nim, często nie są zewnętrznie kontrolowalne).
	* Mogą wykonywać się niezależnie od siebie, czyli być w różnych miejscach programu w tym samym czasie (tak samo jak normalne procesy).
	* Mogą (w większości wypadków) wykonywać się równolegle, czyli na różnych rdzeniach mogą działać w tym samym czasie różne wątki (nawet tego samego procesu).
	* Wszystkie wątki w ramach pojedynczego procesu współdzielą pamięć - czyli modyfikacja wartości pod jakimś adresem w pamięci będzie widoczna we wszystkich wątkach danego procesu (nie będzie widoczna w innych procesach, nawet wykonujących ten sam kod).
* Celem zapewnienia komunikacji między procesami stosowane są różne mechanizmy programistyczne oferowane przez system operacyjny - jednym z nich jest **pamięć współdzielona**. Stosuje się też mechanizmy **synchronizacji procesów i wątków** celem zapewnienia atomowości operacji wykonywanych na wspólnej pamięci (ochrona przed jednoczesną modyfikacją tej samej wartości przez kilka wątków). Bardziej szczegółowo mechanizmy te będą omówione przy tematyce programowania równoległego.

### Zarządzanie pamięcią

Związana z tym jest kolejna funkcją systemu operacyjnego jest zarządzanie pamięcią. Polega ono na odpowiednim mapowaniu adresów logicznych (używanych przez procesy) na adresy fizyczne (używane przez procesor), korzysta ono z wsparcia sprzętowego ze strony procesora. Jest to najczęściej realizowane w oparciu o wspomniany mechanizm stronicowania. Polega to na podziale pamięci dostępnej pamięci fizycznej na jednakowe bloki zwane ramkami oraz podziale pamięci logicznej na jednakowe bloki (o tej całej wielkości co ramki) zwane stronami. Strony które są wykorzystywane przez program są mapowane na dowolne ramki pamięci fizycznej (w przypadku gdy dana strona nie zamapowana - w zależności od okoliczności błąd braku strony lub błąd ochrony strony). Rozwiązuje to problem fragmentacji zewnętrznej, polegającej na braku spójnego obszaru pamięci o żądanej długości pomimo iż łączna ilość wolnej pamięci jest dostateczna, jednak nie rozwiązuje problemu fragmentacji wewnętrznej, polegającej na przydzielaniu zbyt dużych fragmentów pamięci dla procesu (a wręcz można powiedzieć że go pogłębia). Mechanizm ten wymaga trzymania tablicy wolnych ramek, tablicy stron dla każdego procesu (zawierającej przypisania mapowań stron danego procesu na ramki) oraz wykonywania tłumaczenia adresów logicznych (strona + przesunięcie na stronie). Także sama tablica stron procesu procesu może być stronicowania (mamy tablicę która informuje nas że przypisania stron w danym zakresie adresów są przechowywane w jakiejś ramce).
pamięć wirtualna
Strony i ramki mogą być współdzielone pomiędzy procesami (np. przy rozgałęzianiu procesu strony są kopiowane dopiero gdy zajdzie taka potrzeba). W przypadku braku miejsca w pamięci fizycznej wybrane strony nieaktywnego aktualnie procesu mogą być umieszczane na dysku (swap). Niekiedy może to powodować szamotanie procesu polegające na zbyt dużej liczbie wymian stron. Zawsze jednak prowadzi to do konieczności ustalania które strony najlepiej jest przenieść na dysk. Optymalne byłoby przenoszenie tych które najdłużej nie będą potrzebne (jednak z oczywistych względów jet to praktycznie nie do zrealizowania). Stosuje się różne algorytmy tego wyboru:

* FIFO - usuwamy najdłużej będącą w pamięci
* LRU - usuwanie tej do której najdawniej się odwoływano (licznik czasu, bit odniesienia, bit odniesienia w określonym czasie, bit modyfikacji)
* LFU - usuwamy z najmniejszą liczbą odwołań
* MFU - usuwamy z dużą liczbą odwołań

Alternatywną (i mniej wymagającą) wobec stronicowanie metodą zarządzania pamięcią jest segmentacja. W przypadku architektury x86 jest ona zawsze wykorzystywana jednak może być przykryta dużym segmentem na którym wykorzystujemy stronicowaniem.
