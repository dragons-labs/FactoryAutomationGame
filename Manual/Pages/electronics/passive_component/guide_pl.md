<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

Elementy bierne
===============

## Rezystor

Dla elementów spełniających Prawo Ohma, stosunek napięcia między dwoma punktami przewodnika do wartości płynącego między nimi prądu nazywa się rezystancją (oporem).

Takim elementem jest rezystor (opornik). Wprowadza on do układu rezystancję związaną z swoją wartością nominalną. Typowo służy do ograniczania wartości prądu przez niego przepływającego lub uzyskania spadku napięcia.

Towarzyszy temu wydzielanie się energii (cieplnej) związanej z stratami na rezystancji - moc wydzielana wynosi *P = U·I*. Korzystając z prawa Ohma można zauważyć że przy stałym napięciu przyłożonym do rezystora im większy jego opór tym mniejsza moc się wydzieli (gdyż popłynie mniejszy prąd), ale przy stałym prądzie płynącym przez rezystor moc rośnie wraz ze wzrostem oporu.

Symbole rezystora: [img]Manual/Pages/electronics/passive_component/resistor-symbols.svg[/img]

### Rezystancyjny dzielnik napięcia

[img]Manual/Pages/electronics/passive_component/resistor-divider.svg[/img]

Jednym z najprostszych, użytecznych obwodów są dwa rezystory połączone szeregowo z źródłem napięcia. Układ taki nazywamy rezystancyjnym dzielnikiem napięcia. Pozwala on na uzyskanie napięcia niższego od napięcia źródła zgodnie z proporcją użytych rezystorów. Zwróć uwagę że napięcie wyjściowe z takiego układu jest bardzo zależne od pobieranego prądu / wielkości dołączonego obciążenia (w tym celu możesz użyć przełączników umieszczonych w symulowanym układzie), z tego powodu dzielnik rezystancyjny stosowany jest głównie w przypadkach gdy wiemy że obciążenie będzie pobierało niewielki prąd.

Rezystancyjny dzielnik napięcia jest bardzo często stosowany w celu proporcjonalnego podziału (obniżenia) napięcia wejściowego nieznanej (zmiennej) wielkości (np. celem jego pomiaru, przy użyciu miernika o ograniczonej skali), a nie w celu uzyskania napięcia wyjściowego o konkretnej wartości (co można uzyskać w lepszy - bardziej stabilny sposób).

### Rezystor podciągający

[img]Manual/Pages/electronics/passive_component/resistor-pullup.svg[/img]

Rezystor jest też często używany w celu wymuszenia domyślnego poziomu napięcia na jakiejś linii. Jest to zasadniczo forma dzielnika w którym jeden z rezystorów został zastąpiony jakiegoś rodzaju przełącznikiem, czyli czymś co w zależności od swojego stanu ma prawie zerową albo prawie nieskończoną rezystancję.

Rozwiązanie takie ma zastosowanie głównie na jakiś liniach sygnalizacyjnych, z których nie jest pobierany żaden większy prąd. W efekcie, w układzie pokazanym obok jeżeli styk jest rozwarty to prąd nie płynie, zatem spadek na rezystorze wynosi zero i na wyjściu mamy napięcie zasilania. Jeżeli styk zostanie zwarty prąd płynie, ale ze względu na małą rezystancję styku praktycznie całe napięcie odkłada się na rezystorze i na wyjściu mamy zero voltów.

Układ taki pozwala na przykład stosowanie zwykłego styku zwieranego zamiast przełączalnego i jest bardzo często spotykany. Oczywiście możemy zamienić rezystor z przełącznikiem miejscami i wtedy domyślnym stanem (przy rozwartym styku) będzie zero woltów.

### Potencjometr

[img]Manual/Pages/electronics/passive_component/resistor-variable-symbols.svg[/img]

Rezystory nastawne (potencjometry) posiadają 3 końcówki – pomiędzy dwiema jest stała rezystancja nominalna, a rezystancja do środkowej końcówki jest regulowana w zakresie typowo od prawie 0 do 100% tej rezystancji nominalnej.

## Styk

[img]Manual/Pages/electronics/passive_component/contacts-symbols.svg[/img]

Styk jest elementem służącym do mechanicznego załączania lub odłączania prądu. Czynnikiem odpowiedzialnym za przełączanie styków może być manualne działanie (przełącznik naciskany, przekręcany, pociąganym, itd przez człowieka) lub działanie elektromagnesu (cewki) - jest to wtedy przekaźnik elektromagnetyczny lub stycznik. Wyróżnia się:

* styki **monostabilne** (chwilowe), które (po ustaniu czynnika przełączającego) samoistnie wracają do jednej ze swoich pozycji:
    * nie przewodzącej prądu, w przypadku styków określanych jako normalnie otwarte (**normal open**, **NO**) / zwierne
    * przewodzącej prąd, w przypadku styków określanych jako normalnie zwarte (**normal close**, **NC**) / rozwierne
* **przełączne** (następuje przełączanie pomiędzy dwoma lub więcej możliwymi wyjściami),
    szczególnym ich przypadkiem są styki **bistabilne**, które posiadają dwie pozycje a po przełączeniu pozostają w wybranej pozycji.

Należy (zwłaszcza w systemach cyfrowych) pamiętać, że styki potrafią drgać - na ogół przy zmianie pozycji zamiast pojedynczego impulsu generują całą serię.

## Kondensator

[img]Manual/Pages/electronics/passive_component/capacitor-symbols.svg[/img]

Kondensator wprowadza do układu pojemność związaną z swoją wartością nominalną. Pojemność wyraża zdolność do gromadzenia ładunku przez dany element - im większa pojemność tym więcej ładunku (przy takim samym przyłożonym napięciu) zgromadzi element.

Kondensator typowo służy do ograniczania zmian napięcia (poprzez gromadzenie energii w polu elektrycznym) lub wprowadzenia opóźnienia (stałej czasowej) związanej z jego ładowaniem / rozładowywaniem. Czas potrzebny do zmiany napięcia na kondensatorze dany jest zależnością: *ΔT = C · ΔU / I*.

## Cewka

[img]Manual/Pages/electronics/passive_component/coil-symbols.svg[/img]

Cewka (dławik) wprowadza do układu indukcyjność związaną z swoją wartością nominalną. Samodzielnie występująca cewka typowo służy do ograniczania zmian prądu (poprzez gromadzenie energii w polu magnetycznym). Czas potrzebny zmiany prądu płynącego przez cewkę (dławik stawia opór takiej zmianie tak jak kondensator zmianie napięcia) dany jest zależnością: *ΔT = L · ΔI / U*.

### Przekaźniki, styczniki

Cewki możemy spotkać w urządzeniach takich jak przekaźniki lub styczniki. Nawinięte na odpowiednim rdzeniu pełnią one tam funkcję elektromagnesu odpowiedzialnego za zmianę fizycznej pozycji styków prowadzącą do ich zwarcia lub rozwarcia (przełączania).

### Transformatory

Innym urządzeniem opartym o cewki są transformatory - wykorzystują one kilka cewek na wspólnym rdzeniu do przekazywania energii poprzez pole magnetyczne (jedna z cewek dzięki przepływowi zmiennego prądu elektrycznego wytwarza zmienne pole magnetyczne, inna dzięki zmiennemu polu magnetycznemu wytwarza przemienny prąd elektryczny). Transformator typowo służy do zmiany napięcia lub separacji galwanicznej obwodów. W przypadku dwu uzwojeniowego transformatora zachodzi: *U₁/U₂ = I₁/I₂ = n₁/n₂ = z*, gdzie z to przekładnia transformatora, *n₁* to liczba uzwojeń strony pierwotnej (wejściowej), a *n₂* to liczba uzwojeń strony wtórnej (wyjściowej).

### Rozłączanie cewki

Jako że cewka jest elementem który dąży do zachowania płynącego przez niego prądu, to w przypadku rozwarcia obwodu zawierającego cewkę napięcie na niej będzie rosło i bez problemów może wielokrotnie przekroczyć napięcie zasilania. Zjawisko to bywa użyteczne i jest wykorzystywane w niektórych układach (np. przetwornicach podnoszących napięcie), ale często bywa też niepożądane, a nawet bardzo szkodliwe – może prowadzić do uszkadzania innych elementów w obwodzie (w szczególności elementu przełączającego).

Aby przeciwdziałać temu zjawisku można dołączyć równolegle do cewki odpowiednio mały opór, który pozwoli na rozładowanie się cewki. Wadą takiego rozwiązania są straty związane z przewodzeniem przez ten rezystor w momencie gdy cewka jest zasilona. Warto zauważyć że pojawiające się na cewce napięcie ma odwrotny znak (kierunek) niż spadek napięcia na tym elemencie w trakcie pracy. Pozwala to na podłączenie równolegle z cewką elementu który przewodzi tylko w jednym kierunku, w taki sposób aby w normalnym stanie nie przewodził, a po odłączeniu zasilania cewki pozwalał na jej rozładowanie.

Takim elementem jest dioda.
