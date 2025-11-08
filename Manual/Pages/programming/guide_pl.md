<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Programowanie
=============

[url=guide://electronics/digital/programmable]Jak wiemy[/url] działanie procesora (a zatem i komputerów) polega na pobieraniu i wykonywaniu kolejnych instrukcji jakiegoś programu. Mają one postać numeryczną, zrozumiałą dla danej architektury procesora, czyli kodu maszynowego.  Tym instrukcjom jeden do jednego odpowiadają instrukcje asemblera danego procesora.

Tworząc programy komputerowe najczęściej korzystamy jednak z wyżej poziomowych języków programowania i operujemy bardziej abstrakcyjnych instrukcjach, które są niezależne od architektury procesora. Programowanie polega na zapisie pewnego algorytmu, określającego to co i w jaki sposób ma robić dany program, w pewnym języku programowania. Istnieją setki języków programowania, jednak w prawie każdym z nich można odnaleźć mechanizmy związane z tymi samymi podstawowymi koncepcjami programistycznymi:

* wykonywanie operacji arytmetycznych, logicznych oraz bitowych – komputer jest cyfrową elektroniczną maszyną liczącą, więc większość jego działa sprowadza się do jakiegoś rodzaju obliczeń (na liczbach zapisanych w systemie dwójkowym)
* korzystanie z pamięci, czyli odwoływanie się oraz modyfikowanie przechowywanych w niej danych – jeżeli operacja wykonywana przez program nie jest jakiegoś rodzaju obliczeniem prawie na pewno będzie pobraniem bądź modyfikcją danych w pamięci (np. zmiana litery w edytorze tekstu, czy koloru piksela w programie graficznym)
* powtarzanie oraz warunkowe wykonywanie pewnej grupy – pozwala na redukcję ilości kodu, „automatyzację” różnych operacji i możliwość reagowania na dane i sygnały wejściowe
* wywoływanie (a także tworzenie własnych) funkcji bibliotecznych – czyli definiowanie i wywoływanie z innego miejsca programu fragmentów kodu operujących na przekazanych do nich argumentach i mogących zwracać wynik operacji
* wykonywanie operacji wejścia / wyjścia, czyli wczytywania danych i zwracania wyników – operacje takie mogą być związane np. z lokalnymi urządzeniami wejścia/wyjścia (jak klawiatura i monitor), danymi zapisanymi na różnego rodzaju nośnikach (jak dyski twarde), dostępem do sieci komputerowej, mechanizmami komunikacji międzyprocesowej, itd.

## Funckje

Mianem funkcji określa się grupę instrukcji, która może być wywołana z innego miejsca w programie. W uproszczeniu polega to na wykonaniu skoku na początek takiej grupy i skoku powrotnego gdy wykonywanie tego fragmentu kodu zostanie zakończone. Celem zarządzania przechowywaniem adresów dla skoków powrotnych wykorzystywany jest stos (oprócz tego umieszczane są na nim argumenty, wartości zwracane oraz zmienne lokalne).

Funkcja może otrzymywać argumenty, które będą dostępne jako zmienne wewnątrz niej oraz zwracać wartość. Zmienne definiowane wewnątrz funkcji nie będą widoczne poza nią, a modyfikacja wartości argumentów nie wpłynie na wartość zmiennych przekazanych jako argumenty – są one przekazywane przez kopiowanie wartości do nowej zmiennej. Typowo funkcje mogą używać (i modyfikować) zmienne globalne, czyli takie zdefiniowane poza zakresem funkcji.

## Typy danych

Dla komputera wszystkie dane przechowywane w pamięci są po prostu ciągami bitów. Celem wykonywania na nich operacji konieczne jest określenie sposobu interpretacji tych danych. W programowaniu wykorzystuje się w tym celu typy  zmiennych.

W językach statycznie typowanych, takich jak C czy C++, typ musi być jawnie zdefiniowany przed użyciem zmiennej, a jego zmiana jest niemożliwa. Możliwa jest jednak w niektórych językach automatyczna detekcja typu w oparciu o typ wartości przypisywanej do zmiennej w momencie jej deklaracji (np. typ `auto` w C++).

W językach dynamicznie typowanych, takich jak Python, typy danych są przypisywane automatycznie podczas wykonywania programu i mogą ulegać zmianie w trakcie działania (ta sama zmienna może mieć róży typ w różnych momentach wykonania programu), co zapewnia elastyczność, ale może prowadzić do błędów związanych z nieoczekiwanym typem zmiennej.

Można się spotkać także z podejściem że typ zmiennej (będącej np. zawsze napisem) jest interpretowany w momencie użycia zmiennej i zależy właśnie od kontekstu użycia (w taki sposób funkcjonują zmienne powłoki sh i zmienne środowiskowe w systemach Unix).

Procesor wykonuje operacje jedynie na liczbach o skończonej (zależnej od danej architektury) długości bitowej. Wszystkie bardziej zaawansowane typy danych są implementowane w ramach mechanizmów tworzących poszczególne języki z użyciem tych podstawowych typów i operacji na nich. Dotyczy to także typów liczbowych bez ograniczonego zakresu, a na niektórych platformach także liczb zmiennoprzecinkowych. W związku z tym dostępność poszczególnych takich typów danych mocno zależy od języka programowania. Do najważniejszych należy zaliczyć:

* tablice – uporządkowany zbiór kolejnych wartości tego samego typu danych z dostępem poprzez numer kolejny elementu (indeks), często w postaci ciągłego obszaru pamięci
* struktury / klasy – zbiór wartości różnego typu danych, z dostępem poprzez nazwę
* napisy – ciągi znakowe, niekiedy implementowane w postaci tablicy a niekiedy jako niezależny typ danych
* listy – uporządkowany zbiór kolejnych wartości (tego samego lub różnych typów danych) z dostępem poprzez odwołanie do kolejnego / poprzedniego elementu
	* jednokierunkowe – nie posiadają odwołań do poprzedniego elementu
	* cykliczne – elementem następnym po ostatnim jest pierwszy, a poprzednim do pierwszego jest ostatni
* słowniki / mapy / tablice asocjacyjne – zbiór par klucz-wartość z dostępem poprzez wartość unikalnego klucza, zależnie od implementacji wszystkie klucze / wartości muszą być tego samego lub mogą być różnych typów
	* multimapy – wariant nie wymagający unikalności klucza
	* zbiory – wariant nie przechowujący wartości (same unikalne klucze)

## Adres zmiennej

Wszelkie dane na których operuje program komputerowy przechowywane są w jakimś rodzaju pamięci - najczęściej jest to pamięć operacyjna. W pewnych sytuacjach niektóre dane mogą być przechowywane np. tylko w rejestrach procesora lub rejestrach urządzeń wejścia-wyjścia.

W programowaniu na poziomie wyższym od kodu maszynowego i asemblera używa się pojęcia zmiennej i (niemal zawsze) pozostawia kompilatorowi/interpretatorowi decyzję o tym gdzie ona jest przechowywana. Wyjątkiem są grupy zmiennych, czy też bufory alokowane w sposób jawny w pamięci. Ze względu na ograniczoną liczbę rejestrów procesora większość zmiennych (w szczególności tych dłużej istniejących i większych) będzie znajdowała się w pamięci i będą przenoszone do rejestrów celem wykonania jakiś operacji na nich po czym wynik będzie przenoszony do pamięci.

Z każdą zmienną przechowywaną w pamięci związany jest adres pamięci pod którym się ona znajduje. Niektóre z języków programowania pozwalają na odwoływanie się do niego poprzez wskaźnik na zmienną lub referencję do zmiennej (odwołania do adresu zmiennej mogą wymusić umieszczenie jej w pamięci nawet gdyby normalnie znajdowała się tylko w rejestrze procesora). 

## Wartość vs referencja

Główną różnicą pomiędzy korzystaniem bezpośrednio ze zmiennej (z wartości) a korzystaniem z referencji na zmienną (jej adresu, wskaźnika) można zauważyć przy przekazywaniu takiej zmiennej przez kopiowanie (np. w wyniku przypisania lub przekazania do funkcji).
W przypadku korzystania ze „zwykłej” zmiennej kopia nie ma możliwości modyfikowania oryginału. W przypadku przekazania referencji wszystkie zmiany na wartości na którą wskazuje będa widoczne przez obie referencje (orginalną i kopię), przynajmniej do momentu gdy pozostają sobie równe (wskazują na ten sam adres w pamięci).
Może to być użyte jako inna metoda zwracania wartości z funkcji – poprzez modyfikowanie wartości zmiennych na które funkcja dostała referencje (wskaźniki) w swoich argumentach.

## Kompilacja, interpretacja, ...

Istotnym podziałem języków programowania jest podział na języki kompilowane i interpretowane.

W przypadku języków kompilowanych konieczne jest przekształcenie źródeł programu w kod maszynowy przy pomocy odpowiedniego programu (kompilatora). Kompilacja może przebiegać kilku etapowo – na przykład najpierw może być wywołany preprocesor (celem przetworzenia kodu źródłowego na kod wyjściowy), następnie właściwa kompilacja kodu w języku wysokiego poziomu do kodu assemblerowego / kodu maszynowego, a dopiero na końcu konsolidacja czyli linkowanie z używanymi bibliotekami oraz ustalenie punktu wejścia (miejsca od którego rozpocznie wykonywanie się programu)

W przypadku języków interpretowanych (skryptowych) interpreter języka czyta na bieżąco kolejne instrukcje kodu źródłowego i wykonuje. Instrukcje te mogą być czytane z pliku tekstowego (praca wsadowa) lub wprowadzane do linii poleceń interpretera przez użytkownika komputera (praca interaktywna).

Wyróżnić należy też języki kompilowane do kodu pośredniego - w takim przypadku kod źródłowy jest kompilowany do (typowo) niezależnego od platformy sprzętowej binarnego kodu pośredniego. I dopiero ten kod jest interpretowany i tłumaczony na instrukcje procesora w trakcie uruchamiania/działania programu. 

Typowo zaletą języków interpretowanych jest możliwość pracy interaktywnej i łatwość modyfikowania kodu, a języków kompilowanych szybkość działania programu.
