<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: PDF based
-->


# Topologie i typy transmisji

W zależności od układu fizycznych połączeń komunikujących się urządzeń wyróżnia się różne topologie sieci.
Na schemacie poniżej przedstawione zostały główne topologie połączeń:


* **magistrala** (linear bus) -- wszystkie urządzenia są podłączone do jednej linii (wspólnego medium transmisyjnego), okablowanie nie wyróżnia punktu centralnego
* **łańcuch** (daisy chain) -- struktura okablowania podobna jak w magistrali, ale medium transmisyjne jest podzielone (połączenie n urządzeń składa się z n-1 łączy punkt-punkt pomiędzy urządzeniami)
* **pierścień** (ring) -- topologia daisy chain w której końce są połączone, uodparnia to na pojedyncze uszkodzenie
* **gwiazda** (star) -- wszystkie podłączenia biorą początek w węźle centralnym, w zależności od konstrukcji węzła centralnego może być realizowana w oparciu o współdzielone medium lub połączenia punkt-punkt
* **krata** (mesh) -- każde urządzenie ma bezpośrednie połączenie punkt-punkt do każdego innego urządzenia (połączenie n urządzeń wymaga n(n-1)/2 połączeń punkt punkt)

[img]Manual/Pages/electronics/transmission/topologie.svg[/img]

Ponadto występują topologie mieszane złożone z opisanych powyżej: gwiazda wielokrotna (tzn. taka gdzie niektóre z węzłów stanowią punkty centralne kolejnych gwiazd), magistrala lub ring pomiędzy punktami centralnymi gwiazd, gwiazda w której w węzłach występują magistrale lub pierścienie, itd.

Wyróżnić można także typy transmisji:

* **simplex** -- umożliwia tylko transmisję jednokierunkową
* **half-duplex** -- umożliwia transmisję dwukierunkową, ale tylko w jedną stronę równocześnie
* **full-duplex** -- umożliwia pełną transmisję dwukierunkową (równoczesne nadawanie i odbiór)


## Magistrala równoległa

[img=1000%]Manual/Pages/electronics/transmission/parallel_bus_pl.svg[/img]

Magistrala równoległa jest zespołem linii, wraz z układami nimi sterującymi, umożliwiającym równoległe przesyłanie danych (w jednym czasie / takcie zegara na magistrali wystawiane / przesyłane jest całe n-bitowe słowo).
Można wyróżnić szyny sterującą (kierunek przypływu, żądania obsługi, etc), adresową (adres układu który ma prawo nadawać) i danych (przesyłane dane). Często szyna adresowa współdzieli linie transmisyjne z szyną danych.
Do realizacji magistrali (celem umożliwiania podłączenia wielu układów) stosuje się zazwyczaj bufory trój-stanowe, a do zapewnienia współdzielonej szyny żądania obsługi (interrupt request) często układy typu open-collector.

Typowy układ realizacji magistrali half-duplex ze współdzielonymi liniami danych i adresu przestawiony został na schemacie zamieszczonym obok.
Zadaniem dekodera adresu jest ustalenie czy wystawiony na magistrali adres (w trakcie wysokiego stanu linii "Adres / Not Dane") jest adresem danego urządzenia i zapamiętanie tej informacji do czasu wystawienia nowego adresu. Informacja ta jest wykorzystywana do sterowania dwukierunkowym buforem trój-stanowym (jako sygnał enable).
O kierunku działania bufora decyduje sygnał "Read / Not Write". Przy magistralach o ustalonym protokole transmisyjnym sterowanie kierunkiem może być zależne od wykonywanej komendy (po ustawieniu adresu urządzenie odczytuje z magistrali polecenie i w zależności od niego steruje kierunkiem bufora - odczytuje lub zapisuje dane na magistralę).
Zastosowanie kilku linii typu OC do odbierania żądań obsługi pozwala (na podstawie tego które z tych linii znalazły się w stanie niskim na identyfikację urządzenia lub grupy urządzeń, z której niektóre zgłaszają żądanie obsługi.

W przypadku prostych urządzeń wejścia / wyjścia zamiast buforu dwukierunkowego może być umieszczony np.
jednokierunkowy bufor (lub n-bitowy rejestr) z wyjściami trój-stanowymi, który wystawia dane na magistralę w oparciu o sygnał zapisu na magistralę (WR) oraz zegar (clock) albo
n-bitowy rejestr do którego zapisywane są dane z magistrali w oparciu o sygnał RD i Clock.

## Magistrala szeregowa

[img=1000%]Manual/Pages/electronics/transmission/serial_bus_pl.svg[/img]

W magistrali szeregowej dane przesyłane są bit po bicie w pojedynczej linii. Podobnie jak w magistrali równoległej oprócz linii danych mogą występować także linie sterujące. Prostą realizację magistrali szeregowej zapewniają rejestry przesuwne.

Przykładowy układ realizacji magistrali simplex (jednokierunkowej) z rozdzielonymi szynami danych i adresową został na schemacie zamieszczonym obok.
W prezentowanym przykładzie oprócz adresu master wystawia trzy sygnały - dane, zegar i strobe. Z każdym taktem zegara na linii danych wystawiany jest kolejny bit który jest wczytywany do zespołu rejestrów. Sygnał strobe służy do przepisania wartości z rejestrów przesuwnych do rejestrów wyjściowych, takie rozwiązanie zapobiega zmianom wyjść w trakcie przesyłania nowych danych poprzez szynę szeregową, jest ono jednak opcjonalne.

W zależności od konstrukcji dekodera adresu szyna adresowa może być równoległa (w najprostszym przypadku - przez całą transmisję do danego urządzenia jego adres musi być wystawiony na szynie a dekoder jest układem bramek NOT i wielowejściowej bramki AND) lub szeregowa (w takim wypadku powinna posiadać własny zegar lub sygnał informujący o nadawaniu adresu z taktami zegara głównego, a dekoder powinien być wyposażony w rejestr przesuwny do odebrania i przechowywania aktualnego adresu z magistrali). Natomiast jeżeli magistrala byłaby oparta tylko na połączonych szeregowo rejestrach (wyjście serial-out do wejścia serial-in) to szyna adresowa nie jest potrzebna, ale konieczne może być każdorazowe wpisanie wszystkich wartości na szynę (czas zapisu rośnie z ilością podłączonych rejestrów).



# Standardowe interfejsy

Istnieje wiele zestandaryzowanych interfejsów zarówno szeregowych jak i równoległych, wśród najważniejszych należy wymienić:

## SPI (Serial Peripheral Interface)

[img=700%]Manual/Pages/electronics/transmission/spi.svg[/img]

SPI to szeregowa magistrala full-duplex działająca w układzie master-slave złożona z linii zegarowej (SCLK), nadawania przez mastera (MOSI), odbioru przez mastera (MISO) oraz linii służących do aktywacji urządzenia slave (SS / CS). 

## I2C (TWI)

[img=700%]Manual/Pages/electronics/transmission/twi.svg[/img]

I2C jest to szeregowa magistrala half-duplex złożona z linii sygnałowej (SDA) i zegara (SCL) posiadająca zdefiniowany format ramki wraz z adresowaniem. Z wyjątkiem bitu startu i stopu stan linii danych może zmieniać się tylko przy niskim stanie linii zegarowej. Nadajniki są typu open-drain przez co realizowany jest iloczyn na drucie, co pozwala na wykrywanie kolizji (jeżeli dany nadajnik nie nadaje zera a linia jest w stanie zera to nadaje także ktoś inny). Pozwala to także na uzyskanie układów multimaster, pomimo iż typowo na magistrali takiej występuje tylko jeden układ master (nadający sygnał zegara i inicjujący transmisję). 

## 1 wire (one-wire)

[img=700%]Manual/Pages/electronics/transmission/onewire.svg[/img]

1 wire jest to szeregowa magistrala half-duplex złożona z jedynie z linii sygnałowej (która może także służyć do zasilania urządzeń) posiadająca zdefiniowany format ramki wraz z adresowaniem. Standardowe nadawanie jest realizowane jako open-drain (wyjątkiem jest nadawanie tzw power-byte). 

## USART

USART jest to uniwersalny synchroniczny i asynchroniczny nadajnik i odbiornik, umożliwia realizację szeregowej transmisji synchronicznej (zgodnie z zegarem) lub asynchronicznej (wykrywanie początku ramki na podstawie linii danych). Interfejs korzysta z rozdzielonych linii nadajnika i odbiornika (wyjście danych TxD oraz wejście danych RxD, co umożliwia realizację transmisji full-duplex) oraz może korzystać z dodatkowych sygnałów sterujących (wyjście RTS informujące o gotowości do odbioru oraz wejście CTS informacji o gotowości odbioru / zezwolenia na nadawanie). Niekiedy dostępne jest także wyjście załączenia nadajnika używane do pracy w trybie half-duplex (linie TxD i RxD połączone buforem trój-stanowym nadajnika).

[img=1000%]Manual/Pages/electronics/transmission/uart1_pl.svg[/img]

Interfejs ten najczęściej wykorzystywany jest w trybie asynchronicznym jako UART. W połączeniach UART zarówno nadajnik jak i odbiornik muszą mieć ustawione takie same parametry transmisji (szybkość, znaczenie 9 bitu (typowo bit parzystości, ale może także oznaczać np. pole adresowe), itp). Głównymi standardami elektrycznymi dla UART są: poziomy napięć układów elektronicznych używających tych portów (3.3V, 5V), RS-232 (w pełnym wariancie używa sygnałów kontroli przepływu, poziom logiczny 1 wynosi od -15V do -3V, a poziom logiczny 0 od +3V do +15V), RS-422 (transmisja różnicowa full-duplex pomiędzy dwoma urządzeniami) i RS-485 (transmisja różnicowa half-duplex w oparciu o szynę łączącą wiele urządzeń, kompatybilny elektrycznie z RS-422), możliwa jest też transmisja światłowodowa i bezprzewodowa.

[img=1000%]Manual/Pages/electronics/transmission/uart2_pl.svg[/img]


## Rezystory terminujące

Niektóre  ze standardów interfejsów komunikacyjnych przewidują kończenie swoich magistral rezystorem terminującym. Zastosowanie takiego rezystora ma na celu eliminację odbić sygnału, które mogłyby powstać na końcu linii transmisyjnej.

Zjawisko to występuje w przypadku *linii długich*, czyli takich których długość jest zbliżona lub większa od długości fali związanej z przesyłanym sygnałem. Jeżeli rozważymy np. impuls o czasie trwania 1μs to zajmie on na kablu odcinek o długości około 200m (zależy to od prędkości rozchodzenia się fali elektromagnetycznej w ośrodku który stanowi dany przewód). Zatem dla sygnału 1MHz (czyli takiego gdzie pojedyncze impulsy są właśnie długości 1μs) przewód o długości kilkuset metrów będzie linią długą.

Odbicia te wynikają z faktu, iż przemieszczanie się sygnału (np. naszego impulsu 5V o czasie trwania 1μs) wzdłuż przewodu związane jest z ładowaniem kolejnych pojemności pasożytniczych, związanych z odcinkiem przewodu do którego dociera sygnał. Dzieje się to kosztem rozładowania pojemności odcinka przewodu który sygnał już opuścił.

W momencie gdy sygnał trafia na koniec przewodnika nie ma możliwości rozładowania tej pojemności na kolejny odcinek przewodu, więc ładunek z nią związany „rozpływa się po kablu” powodując powstanie odbicia. Odbicie takie (biegnące od końca przewodu w stronę nadajnika) nakłada się na kolejne impulsy naszego sygnału (biegnące od nadajnika) i powoduje zakłócenia w ich odbiorze (interpretacji).

Zastosowanie odpowiedniego rezystora na końcu linii pozwala na rozładowanie tej pojemności (tak jakby był tam kolejny nieskończenie długi odcinek przewodu) i eliminację odbicia. Wartość tej rezystancji jest charakterystyczna dla danego przewodu i określana przez parametr nazywany *impedancją falową*.

Rezystor terminujący stanowi obciążenie dla nadajnika i powinien on być stosowany tylko na końcach magistrali, czyli np. na ostatnich urządzeniach podłączonych do magistrali (a nie przy każdym urządzeniu do niej włączonym).

Jeżeli długość linii jest dużo mniejsza (dla sygnałów prostokątnych przyjmuje się że około 20-40 razy) od długości odcinka jaką zajmuje pojedynczy impuls (np. linia długości 3m, dla przykładowego sygnału 1MHz) to nie ma potrzeby stosowania rezystorów terminujących (często nawet gdy w ogólności dany standard je przewiduje), gdyż stan całej linii jest spójny i wymuszany przez nadajnik (nie jest to przypadek linii długiej).

Standard I2C nie przewiduje rezystorów terminujących (i nie powinny być w nim używane, zwłaszcza że są to linie open drain i powstawałby dzielnik z rezystorem pull-up). Wynika to z tego iż przy maksymalnej prędkości tego interfejsu za linie długie należałoby uznać odcinki co najmniej kilkunastometrowe, a z innych względów standard ten posiada ograniczenie do kilku metrów.

Standard RS-485 przewiduje stosowanie rezystorów terminujących 120 Ω, jednak w przypadku krótkich połączeń i/lub małych prędkości transmisji mogą one być pominięte.
