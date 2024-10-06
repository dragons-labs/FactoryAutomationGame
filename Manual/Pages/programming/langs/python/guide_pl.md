<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

editing note: NEW, VIP
-->

Podstawy programowania w Python
===============================

Uruchamianie kodu
-----------------

Kod pythonowy może być tworzony i wykonywany w linii poleceń interpretera. Dłuższe fragmenty kodu pythonowego często wygodniej jest pisać w pliku tekstowym niż bezpośrednio w linii poleceń. Plik taki może zostać wykonany przy pomocy polecenia: `./nazwa_pliku` pod warunkiem że ma prawo wykonalności (powinien także zawierać w pierwszą linii komentarz określający program używany do interpretacji tekstowego pliku wykonywalnego, w postaci: `#!/usr/bin/python3` lub `#!/usr/bin/env python3`). Może też być wykonany za pomocą wywołania: `python3 nazwa_pliku`.

Polecenie `python3 -i nazwa_pliku` (opcja `-i`_ pozwala na uzyskanie interpretera w stanie po wykonaniu poleceń z pliku `nazwa_pliku`.

### Skrypty

Plik zawierający polecenia powłoki określany jest mianem skryptu. Wykonywanie skryptu powłoki rozpocznie się od pierwszej jego linii. Skrypt może przyjmować dowolną ilość parametrów pozycyjnych, są one dostępne w tablicy `sys.argv`.

```Python
#!/usr/bin/env python3

import sys

print("Hello World")
print(sys.argv)

exit(0)
```

* tekst tekst od `#` do końca linii stanowi komentarz, czyli informacje dla programisty (np. opis działania algorytmu) ignorowane przez kompilator
	* komentarz w pierwszej linii rozpoczynający się od `!` jest komentarzem sterującym określającym program który ma być użyty do interpretacji kodu z pliku tekstowego
* polecenie `import` służy do zaimportowania modułu pythonowego (są nimi fragmenty biblioteki standardowej oraz innych bibliotek także tworzonych przez nas)
	* w tym przypadku importowany jest fragment biblioteki standardowej, 
* funkcja `print` wypisuje tekst określony w argumentach na standardowe wyjście
* funkcja `exit` kończy działanie skryptu ustawiając podaną w argumencie wartość jako kod powrotu, stosowanie jej na końcu skryptu (jak w tym przykładzie) nie jest obowiązkowe


Dokumentacja
------------

Python posiada wbudowany system dokumentacji, celem jej użycia należy wykonać funkcję `help` od funkcji, typu, etc z dokumentacją którego chcemy się zapoznać, np. `help(print)` wypisze dokumentację funkcji `print`, `help(sys)` (po `import sys`) wypisze dokumentację modułu `sys`.


Zmienne
-------

```Python
# dynamiczne typowanie - typ określany jest
# na podstawie wartości zapisywanej do zmiennej

zmienna_liczbowa = -91.7
zmienna_napisowa = "qa z"
```

Podstawowe operacje
-------------------

```Python
a = 12.7
b = 3
x = 5
y = 6

# dodawanie, mnożenie, odejmowanie zapisuje się
# i działają one tak jak w normalnej matematyce:
e = (a + b) * 4 - y

# dzielenie zmiennoprzecinkowe
c = x / y

# dzielenie całkowite
b = a // b

# reszta z dzielenia
z = x % y;

# wypisanie wyników
print(e, c, b, z)

# operacje logiczne:
# ((a większe równe od 0) AND (b mniejsze od 2)) OR (z równe 5)
z = (a>=0 and b<2) or z == 5;
# negacja logiczna z
x = not z;

print(z, x);

# operacje binarne:
# bitowy OR 0x0f z 0x11 i przesunięcie wyniku o 1 w lewo
x = (0x0f | 0x11) << 1;
# bitowy XOR 0x0f z 0x11
y = (0x0f ^ 0x11);
# negacja bitowa wyniku bitowego AND 0xfff i 0x0f0
z = ~(0xfff & 0x0f0);

print(hex(x), hex(y), hex(z & 0xffff));
# wypisując z musimy określić jego bitowość

# wieloargumentowa operacja przypisania
# może być użyta do zamiany wartości pomiędzy dwoma zmiennymi
# bez jawnego używania zmiennej tymczasowej
print(a, b)
a, b = b, a
print(a, b)
# oczywiście można w jej ramach używać więcej niż dwóch zmiennych
```

Pętle i warunki
---------------

Bloki kodu w Pythonie wydzielane są z użyciem wcięć.

```Python
i, k, j = 0, 0, 0 # wielokrotne przypisanie
# najpierw oblicza wartości wyrażeń po prawej, potem przypisuje.
# Pozwala na a, b = b, a celem zamiany wartości zmiennych

# instrukcja waunkowa if - else
if i<j :
	print("i<j")
elif j<k :
	print("i>=j AND j<k")
else:
	print("i>=j AND j>=k")

# podstawowe operatory logiczne
if i<j or j<k:
	print("i<j OR j<k");
# innymi operatorami logicznymi są and oraz not

# pętla for
for i in range(2, 9):
	if i==3:
		# pominięcie tego kroku pętli
		continue;
	if i==7:
		# wyjście z pętli
		break;
	print(" a:", i)

# pętla while
while i>0 :
	i = i - 1;
	print(" b:", i)
```


Funkcje
-------

```Python
# funkcja bezargumentowa, zwracająca wartość
def f1():
	print("AA")
	return 5

a = f1()
print(a)

# funkcja przyjmująca jeden obowiązkowy
# argument oraz dwa opcjonalne
def f2(a, b=2, c=0):
	print(a**b+c)

f2(3)
f2(3, 3)
# można pominąć dowolne z argumentów z wartością
# domyślną odwołując się do pozostałych nazwami
f2(2, c=1)
# można podawać argumenty w dowolnej kolejności
# odwołując się do nich nazwami
f2(b=3, a=2)


# nieokreślona ilość argumentów pozycyjnych
def f(*a):
	for aa in a:
		print(aa)

f(1, "y", 6)
# ale nie: f(1, "y", u="p")

# nieokreślona ilość argumentów nazwanych
def f(**a):
	for aa in a:
		print(aa, "=", a[aa])

f(a="y", u="p")
# ale nie: f(1, u="p")

# nieokreślona ilość argumentów pozycyjnych i nazwanych
def f(*a1, **a2):
	print(a1)
	print(a2)

f(1, "y", 6)
f(a="y", u="p")
f(1, "y", u="p")

# można też wymusić ileś argumentów jawnych
def f(x, *a1, y="8", **a2):
	print(x, y)
	print(a1)
	print(a2)

f(1, "y", 6)
f(1, "y", u="p")
f(1, "z", y="y", u="p")
# ale nie: f(a="y", u="p")
```


Kontenery
---------

### listy (tablice)

```Python
l = [ 3, 5, 8 ]

# wstawienie elementu na koniec
l.append(1)

# wstawienie elementu na pozycje 2
l.insert(2, 13)

print("liczba elementów =", len(l))
print("pierwszy =", l[0])
print("dwa kolejne =", l[1:3])

# wypisanie wszystkich elementów
for e in l:
	# możemy modyfikować zmienną "e",
	# ale nie będzie maiło to wplywu na listę
	print(e)

# alternatywne iterowanie po elementach
# (pozwala na ich modyfikowanie)
for i in range(len(l)):
	l[i] = l[i] + 1
	print(l[i])

# możemy też uzyskać listę w oparciu o wykonanie jakiś
# operacji na danej liście w formie jednolinijkowca:
l = [a * 2 for a in l]
# listę taką możemy przypisać do innej
# lub (jak wyżej) do tej samej zmiennej

# pobranie i usuniecie ostatniego elementu
print("ostatnim był:", l.pop())
print("ostatnim był:", l.pop())

# pobranie i usuniecie elementu na wskazanej pozycji
print("drugim elementem był:", l.pop(1))

# wypisanie całej listy
print(l)
```

### słowniki

```Python
m = { "ab" : 11, "cd" : "xx" }
x = "e"
m[x] = True;

# pobranie samych kluczy
for k in m:
	print (k, "=>", m[k])

# sprawdzenie istnienia 
if "ab" in m:
	print ("jest ab")
	# usunięcie elementu
	del m['ab']

# modyfikacja wartości
m["cd"] = "oi"

# pobranie par klucz wartość
for k,v in m.items():
	print (k, "=>", v)
```


Napisy
------

Napisem w Pythonie jest ciąg znaków ujęty w cudzysłowa lub apostrofy (nie ma różnicy którego zapisu użyjemy). Potrójne cudzysłowa / apostrofy pozwalają na definiowanie napisów wieloliniowych (a także zawierających pojedyncze cudzysłowa / apostrofy w tekście).

```Python
x = "abcdefg"
y = "aa bb cc bb dd bb ee"
z = "qw=rt"

# wypisanie długości napisu
print(len(x))

# wypisanie pod-napisu od 2 do końca
# i od 0 (początku)do 3
print (x[2:], x[0:3])

# wypisanie ostatniego i 3 ostatnich znaków
print (x[-1], x[-3:])

# wypisanie co 3ciego znaku z napisu oraz napisu od tyłu
print (y[::3], x[::-1])

# wyszukiwanie
# pod-napisu "bb" w y od pozycji 5
print (y.find("bb", 5))

# porównywanie
if x == "a":
	print("x == \"a\"")

# sprawdzanie czy jest pod-napisem
if "ab" in x:
	print ("ab jest pod-napisem:", x)

# sprawdzanie czy jest pod-napisem
if "ba" in x:
	print ("ba jest pod-napisem:", x)

# nie da się modyfikować napisu z użyciem odwołań x[numer] np.
# x[2]="X"
# nie zadziała

# można (gdy dużo tego typu modyfikacji) przepisać do listy:
l=list(x)
# alternatywnie można manualnie:
#	l=[]
#	for c in x:
#		l.append(c)
# albo tak:
#	l=[c for c in x]

l[1]="X"
l[3]="qqq"
del l[5]
print("".join(l))

# albo tak (gdy mniej modyfikacji)
print(x[:2] + "XXX" + x[3:])

# można także modyfikować po kolei i dodawać do nowego napisu
s = ""
for c in x:
	if c == "a":
		s += "AA"
	else:
		s += c

print(s)

# przy pomocy metody split() napis możemy podzielić
# na listę napisów przy pomocy dowolnego separatora
print(y.split(" "))
print(y.split(" cc "))
```

### Konwersja liczba - napis

```Python
# konwersja liczb na napis w systemach:
# dwójkowym, ósemkowym, dziesiętnym i szesnastkowym
print( bin(7), oct(0xf), str(0o10), hex(0b11) )

# liczby podawane do wypisywania są w odpowiednio systemach:
# dziesiętnym, szesnastkowym, ósemkowym i dwójkowym
# wskazane jest to przez brak prefixu i prefixy "0x" "0o" "0b"

# alternatywnie w stylu printf, ale bez dwójkowego
s = "0o%o %d 0x%x" % (0xf, 0o10, 0b11)
print(s)
```

### Konwersja znak - numer znaku i kodowania znaków

```Python
# wypisywanie znaków z użyciem ich numeru w unikodzie
# - funkcja chr() zwraca napis złożony ze znaku o podanym numerze
# w ramach napisów można też użyć \uNNNN gdzie NNNN jest numerem znaku
# lub po prostu umieścić dany znak w pliku kodowanym UTF8
print(chr(0x21c4) + " == \u21c4 == ⇄")

# funkcja ord() umożliwia konwersję napis złożonego
# z pojedynczego znaku na numer unicodowy
print(hex(ord("⇄")), hex(ord("\u21c4")), hex(ord(chr(0x21c4))) )

# Python używa Unicode dla obsługi napisów, jednak przed
# przekazaniem napisu do świata zewnętrznego konieczne
# może być zastosowanie konwersji do określonej postaci
# bytowej (zastosowanie odpowiedniego kodowania)
# służy do tego metoda encode() np.
a = "aąbcć ... ⇄"
inUTF7 = a.encode('utf7')
inUTF8 =  a.encode() # lub a.encode('utf8')
print("'" + a + "' w UTF7 to: " + str(inUTF7))
print(" i jest typu: " + str(type(inUTF7)))

# obiekty typu 'bytes' mogą zostać zdekodowane do napisu
print("zdekodowany UTF7: " + inUTF7.decode('utf7'))

# lub zostać poddane dalszej konwersji np. kodowaniu base64:
import codecs
b64 = codecs.encode(inUTF8, 'base64')
print("napis w UTF8 po zakodowaniu base64 to: " + str(b64))
```

### Wyrażenia regularne

W przetwarzaniu napisów bardzo często stosowane są wyrażenia regularne służące do dopasowywania napisów do wzorca który opisują, wyszukiwaniu/zastępowaniu tego wzorca. Do typowej, podstawowej składni wyrażeń regularnych zalicza się m.in. następujące operatory:

```
.      - dowolny znak
[a-z]  - znak z zakresu
[^a-z] - znak z poza zakresu (aby mieć zakres z ^ należy dać go nie na początku)
^      - początek napisu/linii
$      - koniec napisu/linii

*      - dowolna ilość powtórzeń
?      - 0 lub jedno powtórzenie
+      - jedno lub więcej powtórzeń
{n,m}  - od n do m powtórzeń

()     - pod-wyrażenie (może być używane dla operatorów powtórzeń, a także dla referencji wstecznych)
|      - alternatywa: wystąpienie wyrażenia podanego po lewej stronie albo wyrażenia podanego prawej stronie
```

```Python
import re

if re.search("[dz]", x):
	print(x, "zawiera d lub z")

# zastępowanie (dowolny niepusty ciąg złożony z liter b oraz c na XX)
print (re.sub('[bc]+', "XX", y))

# czwarty (opcjonalny) argument określa ile razy ma być wykonane zastępowanie
print (re.sub('[bc]+', "XX", y, 2))

# zastępowanie z użyciem podstawienia
# \\2 zostanie zastąpione wartością drugie pod-wyrażenia,
# czyli fragmentu ujętego w nawiasach
print (re.sub('([bc]+) ([bc]+)', "X-\\2-X", y))

# mamy też wpływ na zachłanność wyrażeń regularnych:

print (re.sub('bb (.*) bb', "X \\1 X", y))
# "bb (.*) bb" dopasowało najdłuższy możliwy fragment, czyli: cc bb dd

print (re.sub('.*bb (.*) bb.*', "\\1", y))
# "bb (.*) bb" dopasowało jedynie "dd", bo najdłuższy możliwy
# fragment został dopasowany przez poprzedzające ".*"

print (re.sub('.*?bb (.*) bb.*', "\\1", y))
# "bb (.*) bb" mogło i dopasowało najdłuższy możliwy fragment,
# gdyż było poprzedzone niezachłanną odmianą dopasowania
# dowolnego napisu, czyli: .*?

# Po każdym z operatorów powtórzeń (. ? + {n,m}) możemy dodać
# pytajnik (.? ?? +? {n,m}?) aby wskazać że ma on dopasowywać
# najmniejszy możliwy fragment, czyli ma działać nie zachłannie.
```


Pliki
-----

```Python
# otwarcie pliku do odczytu
f=open("/etc/passwd", "r")
# funkcja pozwala na określenie kodowania pliku poprzez
# argument nazwany "encoding" (np. encoding='utf8'),
# domyślne kodowanie zależne jest od ustawień systemowych
# można je sprawdzić poprzez locale.getpreferredencoding()
#
# jeżeli plik ma być otwarty w trybie binarnym a nie
# tekstowym konieczne jest podanie flagi b w ramach
# drugiego argumentu

# odczyt po linii
l1 = f.readline()
l2 = f.readline()

# można także czytać z jawnym użyciem iteratorów:
li = iter(f)
l3 = next(li)
l4 = next(li)

print("l1: " + l1 + "l2: " + l2 + "l3: " + l3 + "l4: " + l4)

# albo w ramach pętli
i = 5
for l in f:
	print(str(i) + ": " + l)
	i += 1

# powrót na początek pliku
f.seek(0)

# odczyt jako tablica linii
ll = f.readlines()

print(ll)

# i kolejny raz ... jako jednolity tekst
f.seek(0)
print( f.read() )

f.close()
```

### tworzenie pliku oraz dopisywanie

```Python
import os.path

# jeżeli plik istnieje to:
if os.path.isfile("/tmp/plik3.txt"):
	# otwieramy w trybie do zapisu i odczytu
	# i ustawiamy się na końcu pliku celem dopisywania
	f=open("/tmp/plik3.txt", "r+")
	f.seek(0, 2)
else:
	f=open("/tmp/plik3.txt", "w")

# pobieramy aktualną pozycje w pliku
# (która w tym wypadku jest równa długości pliku)
pos = f.tell()

# jeżeli plik ma więcej niż 5 bajtów
if pos > 5:
	# to cofamy się o 3
	f.seek(pos-3)

f.write("0123456789")

f.close()
```

### pliki binarne

```Python
# obsługa plików binarnych
# wymagane jest dodanie flagi b w flagach funkcji open():
f=open("/tmp/plik1.txt", "rb")

# czytanie bajt po bajcie
while True:
	b = f.read(1)
	if b == b"":
		break
	print(b)

f.close()
```
