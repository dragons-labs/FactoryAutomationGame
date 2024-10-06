<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: MOVIE+PDF+NEW merged
-->

Elementy bierne
===============

Obwody prądu stałego a zmiennego
--------------------------------

Pojemność oraz indukcyjność wprowadzona do obwodu ma znaczenie tylko gdy zachodzi zmiana natężania prądu płynącego przez obwód / zmiana wartości napięć odłożonych na jego elementach. W stanie ustalonym obwodu prądu stałego wprowadzona do obwodu pojemność oraz indukcyjność nie odgrywają roli, gdyż:

* pojemności zgromadziły już (stosowny do przyłożonego do nich napięcia) ładunek i nie pobierają prądu z obwodu,
* indukcyjności wytworzyły pole magnetyczne (stosowne do przepływającego przez nie prądu) i nie stanowią oporu dla płynącego prądu w obwodzie.

W takim przypadku można traktować pojemności jako rozwarcia, a indukcyjności jako zwarcia. Związane z tym jest także jedno z częstych zastosowań kondensatora – odcinanie składowej stałej. Wykorzystuje ono fakt że kondensator stanowi rozwarcie dla prądu stałego, ale przewodzi prąd zmienny (ze względu na prąd związany z jego ładowanie / rozładowywaniem).

* **Impedancja** – jest wielkością charakteryzującą zależność pomiędzy natężeniem prądu i napięciem uwzględniającą reaktancję obwodu. *Z = R+jX*
* **Reaktancja** – jest wielkością charakteryzującą opór bierny elementów pojemnościowych (kapacytancja *X = −1ωC*) i indukcyjnych (induktancja *X = ωL*).
* **Pulsacja** (*ω*) – charakteryzuje szybkość zmian (jest proporcjonalna do odwrotności czasu trwania okresu zmiany). *ω = 2πT*


Elementy rzeczywiste
--------------------

### rezystor

Rzeczywisty rezystor oprócz samej wartości oporu elektrycznego charakteryzują też inne parametry, m.in. takie jak:

* maksymalna moc która może zostać wydzielona na danym elemencie,
* dokładność, czyli to jak bardzo opór danego elementu może być odległy od wartości nominalnej,
* stabilność oporu w funkcji w funkcji temperatury oraz w funkcji napięcia przyłożonego do elementu.

### styki

Nawet styki w rzeczywistości posiadają swoje parametry, do głównych należy zaliczyć:

* obciążalność prądową
* rezystancję zamkniętego styku
* trawłość mechniczną (ilość cykli pracy)

W niektórych przypadkach (zwłaszcza w automatyce) w ramach grup styków działających na skutek tego samego czynnika mechanicznego wyróżnia się (i oznacza zmodyfikowanymi symbolami) styki wyprzedzające (załączające się przed pozostałymi) i opóźnione (działające jako ostatnie

W energetyce oznacza się także zdolność rozłączania prądów roboczych oraz prądów zwarciowych przez dany styk.

### kondensator

Najistotniejszym parametrem rzeczywistych kondensatorów oprócz pojemności nominalnej jest maksymalne napięcie przy którym może pracować oprócz tego istotne mogą być parametry takie jak rezystancja wewnętrzna, maksymalna temperatura w której kondensator może pracować, żywotność tego elementu, itd.

### cewka
Głównym (ale nie jedynym) parametrem rzeczywistej cewki oprócz indukcyjności jest maksymalny prąd który może przewodzić.

### przkaźniki i styczniki

Rzeczywiste przekaźniki i styczniki charakteryzują się parametrami takimi jak
- prąd przewodzenia
- moc pobierana przez cewkę
- napięcie cewki oraz działanie na prąd stały lub przemienny

Należy zaznaczyć, że przkaźniki i styczniki zasadniczo jest to ten sam typ urządzenia, przyjmuje się rozróżnienie w nazewnictwie - przekaźniki przełączają mniejsze prądy niż styczniki.


Transformatory w energetyce
---------------------------

Najpowszechniejszym wykorzystaniem transformatorów jest podnoszenie i obniżanie napięcia w energetyce. Na przykład przy elektrowniach mamy transformatory podwyższające napięcie, gdyż generator w elektrowniach pracuje na ogół na napięciu rzędu kilku kilowoltów (na przykład 6 kV), a sieci przesyłowe pracują na napięciu kilkuset kilowoltów (na przykład na 220 kV). Następnie im bardziej zbliżamy się do odbiorcy energii elektrycznej, to mamy kolejne transformatory, tym razem obniżające napięcie najpierw do kilkunastu kilowoltów, a potem do 230 woltów, czyli takiego jakie mamy w domach. Takie podwyższenie napięcia pozwala obniżyć straty przesyłowe i stosować mniejsze średnice przewodów.

Oprócz tego transformator może służyć do separacji galwanicznej obwodów, czyli rozdzielenia obwodu pierwotnego od obwodu wtórnego, w taki sposób aby prąd pomiędzy nimi nie mógł przepływać bezpośrednio. Wykonuje się to nawet pracując na tym samym napięciu, czyli istnieją i są stosowane również transformatory o przekładni jeden do jednego.

Separacja taka opiera się na tym, że jeżeli nie zewrzemy w jakiś sposób jednego bieguna strony pierwotnej z jednym biegunem strony wtórnej, to napięcie wyjściowe (które jest pomiędzy biegunami strony wtórnej), nie ma żadnego odniesienia do napięć strony pierwotnej. Można zaobserwować że napięcia te pływają względem siebie.

Typowo takie połączenie strony pierwotnej i wtórnej realizowane jest poprzez uziemienie jednego z wyprowadzeń każdej ze stron. W przypadku sieci elektroenergetycznych, które wykorzystują prąd trójfazowy, typowo łączony z potencjałem Ziemi jest punkt neutralny transformatora. W efekcie w większości naszych domowych gniazdek mamy przewód neutralny (połączony z potencjałem Ziemi) i fazowy (na którym jest napięcie w stosunku co do Ziemi). Zatem jeżeli chcemy żeby nasze napięcia za transformatorem odnosiły się do potencjału Ziemi to jeden z biegunów również uziemiamy, a jeżeli chcemy żeby transformator był separujący to tego nie robimy. Pierwsze podejście stosowane jest w większości (prawidłowo zasilonych) komputerów stacjonarnych, a drugie w wielu laptopach.
