<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
--> 

System Operacyjny
=================

System operacyjny jest oprogramowaniem odpowiedzialnym za zarządzanie zasobami systemu komputerowego (sprzętem, ale nie tylko) oraz uruchomionymi na nim aplikacjami. Do najistotniejszych zadań systemu operacyjnego zalicza się podział czasu procesora i szeregowanie zadań oraz zarządzanie pamięcią - w szczególności obsługa pamięci wirtualnej, najczęściej z wykorzystaniem mechanizmu stronicowania.

Oprócz tego system zajmuje się także zarządzaniem plikami, wejściem/wyjściem (najczęściej jest ono realizowane w oparciu o przerwania (IRQ), ale znane są także modele programowego we/wy polegającego na aktywnym czekaniu), obsługą urządzeń (wejście/wyjście, sterowniki, dostęp), obsługą sieci (stos protokołów sieciowych), itd. Część zadań realizowana jest z minimalnym udziałem procesora (a więc także i systemu) jest to na przykład transfer danych w trybie DMA polegający na tym iż dane kopiowane są całymi blokami bez udziału procesora do/z pamięci (system zajmuje się tylko inicjacją transmisji). Należy tu jednocześnie zaznaczyć iż w przypadku nie stosowania tej technologii dane też kopiowane są pomiędzy dyskiem a procesorem całymi blokami (minimum sektor) gdyż dysk (w odróżnieniu od pamięci operacyjnej) nie jest bezpośrednio dostępny dla procesora.

Współczesne systemy korzystają z co najmniej dwóch poziomów pracy - uprzywilejowanego poziomu "nadzorcy" w którym działa jądro systemu operacyjnego oraz trybu użytkownika. Operacje I/O muszą odbywać się w trybie uprzywilejowanym. Również pamięć posiada obszar chroniony, w którym umieszczany jest m.in. tablica wektorów przerwań (inaczej zmiana adresu w tym wektorze mogłaby doprowadzić do przejęcia systemu w trybie uprzywilejowanym).

Procesy i szeregowanie zadań
----------------------------

Istotną rolą systemu operacyjnego w zarządzaniu procesami (obok czynności administracyjnych jak ich tworzenie powielanie, usuwanie, czy też wstrzymywanie itp) jest zapewnienie ochrony pamięci (każdy proces może pisać po swojej i ewentualnie współdzielonej gdy dostał do tego prawo) oraz procesora (przerwanie zegarowe powoduje wywołanie planisty, który ustala jaki proces dostanie następny kwant czasu procesora). Niektóre systemy wyróżniają obok procesów także wątki, które różnią się od nich współdzieloną (między wątkami jednego procesu) pamięcią i zasobami (np. otwartymi plikami). System operacyjny zapewnia także zestaw usług i funkcji (wywołań) systemowych zapewniających pośrednictwo między interfejsem trybu użytkownika a sprzętem.

Istotnym zadaniem systemu operacyjnego jest przeciwdziałaniem tzw. blokadom, czyli sytuacji gdy dwa lub więcej procesów blokują się wzajemnie w oczekiwaniu na zasoby (a ma zasób X, którego potrzebuje b aby zwolnić zasób Y, którego potrzebuje a do zwolnienia X). Realizowane to może być na kilka sposobów:

* zapobieganie blokadzie (czyli niedopuszczenie do zajścia warunków koniecznych) - np. poprzez konieczność deklarowania wszystkich zasobów na początku, zwalniania przydzielonych zasobów przed zgłoszeniem zapotrzebowania na następne
* unikanie blokady (czyli określamy maksymalne zapotrzebowanie i tak przydzielamy zasoby aby uniknąć zajścia blokady) - np. poprzez kontrolę czy po spełnieniu żądania dalej będziemy działać w stanie "bezpiecznym", tj takim że istnieje sekwencja (zwana bezpieczną) w której maksymalne zapotrzebowanie każdego procesu może być spełnione w oparciu o zasoby zwolnione przez procesy będące wcześniej w tej sekwencji oraz zasoby wolne
* wykrywanie i usuwanie blokady gdy do niej doszło

Planista procesora, czyli fragment systemu odpowiedzialny za przydzielanie procesora procesom, może pracować w trybie z wywłaszczaniem lub bez. W tym pierwszym wypadku proces otrzymuje kwant czasu procesora który może wykorzystać w całości (wtedy przejdzie z stanu wykonywania w stan gotowości) lub z niego wcześniej zrezygnować (gdy np. czeka na I/O, wtedy przejdzie z stanu wykonywania w stan oczekiwania). W drugim przypadku proces wykonuje swój kod do momentu aż sam odda procesor. Forma ta zbliżona jest do wykorzystywanej w szeregowaniu czasu rzeczywistego - proces będzie wywłaszczony tylko przez proces o wyższym priorytecie i będzie to natychmiastowe (przy najbliższym przerwaniu zegarowym). Istnieje wiele algorytmów szeregowania takich jak:

* FCFS - pierwszy zgłoszony = pierwszy obsłużony
* SJF - najkrótszy zgłoszony będzie pierwszym wykonanym (wersja z wywłaszczaniem - SRTF - gdy nowy najkrótszy pozostały), algorytm raczej nie do zastosowania praktycznego - trzeba by przewidywać długość wykonania
* priorytetowe - zawsze o najwyższym priorytecie (jak wspomniałem wyżej wykorzystywane w systemach real-time
* rotacyjne - każdy po kawałku, potem na koniec kolejki
* kolejki wielopoziomowe - system z priorytetami, podziałem czasu pomiędzy kolejki, przenoszeniem procesów między kolejkami, ...

Proces uruchamiania komputera

-----------------------------
Po otrzymaniu sygnału resetu (także przy uruchamianiu systemu - "Power-on Reset") procesor po inicjalizacji rejestrów zaczyna wykonywanie kodu znajdującego się pod jakimś ustalonym adresem (typowo w wbudowanej lub zewnętrznej pamięci typu ROM lub Flash). W zależności od danej architektury / procesrora może to być m.in.: bezpośrednio kod programu użytkownika, wbudowany bootloader danego procesora umożliwiający dalsze ładowanie np. z karty SD, zewnętrzny niskopoziomowy bootloader (np. u-boot).

W przypadku architektur zgodnych z x86 jest to BIOS, który po zakończeniu procesu inicjalizacji sprzętu i testów rozruchowych ładuje do pamięci kod znajdujący się w pierwszym sektorze dysku twardego (sektorze rozruchowym rozpoczynającym się od adresu zerowego) i uruchamia go (przekazuje do niego kontrolę). Znajduje się tam kod (lub tylko początek kodu) programu rozruchowego, którego zadaniem jest załadowanie systemu operacyjnego. W przypadku współczesnych systemów linuxowych jest to zazwyczaj GRUB.

W przypadku sektorów rozruchowych typu MBR (i kompatybilnych z nim), kod ten może liczyć maksymalnie 446 bajtów (gdyż na kolejnych pozycjach znajduje się tablica partycji) i jego zadaniem jest załadowanie i uruchomienie pozostałej części programu rozruchowego (musi znać jej położenie na dysku). Pozostała część programu rozruchowego może znajdować się tuż za MBR (w przerwie pomiędzy MBR a pierwszą partycją - dla tablicy partycji MBR/msdos), w dedykowanej partycji BIOS boot partition (dla tablicy partycji GPT) lub w partycji oznaczonej jako bootowalna. Część ta zawiera moduły pozwalające na dostęp do systemu plików zawierającego konfigurację, obraz jądra, itp oraz informację o jego położeniu (dysk, partycja, ścieżka).

W przypadku komputerów opartych na UEFI firmware odpowiedzialny jest za zinterpretowanie tablicy partycji (GPT) i załadowanie programu rozruchowego z pliku znajdującego się na specjalnej partycji EFI (EFI System partition) z systemem plików FAT32. W pliku tym umieszczana jest całość (obie opisane powyżej części programu rozruchowego).

Start systemu rozpoczyna się od załadowania do pamięci obrazu jądra wraz z parametrami oraz (opcjonalnie) initrd i przekazania kontroli do jądra przez program rozruchowy (np. GRUB). W przypadku jądra linuxowego i korzystania z initrd obraz ten przekształcany jest na RAM-dysk w trybie zapisu-odczytu i montowany jako rootfs z którego uruchamiany jest `/sbin/init` (którego podstawowym zadaniem jest zamontowanie właściwego rootfs). Po jego zakończeniu (lub od razu gdy nie używamy initrd) uruchamiany jest program wskazany w opcji `init=` jądra (domyślnie typowo `/sbin/init`) z rootfs wskazanego w opcji `root=` jądra. W opcji `init=` można wskazać dowolny program lub skrypt (uruchomiony zostanie z prawami root'a).
