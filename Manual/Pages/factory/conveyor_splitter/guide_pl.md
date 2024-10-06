<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT
-->

# Conveyor Splitter

Pozwala na podział pasa transmisyjnego i kierowanie obiektów na inne pasy (w prawo, w lewo, prosto).

#### Sygnały wejściowe:

* `splitter_redirect_forward` - stan wysoki (> 2V) powoduje przekierowanie obiektu na wprost
* `splitter_redirect_to_left` - stan wysoki (> 2V) powoduje przekierowanie obiektu w lewo
* `splitter_redirect_to_right` - stan wysoki (> 2V) powoduje przekierowanie obiektu w prawo

Wejścia są priorytetowe, czyli podanie stanu wysokiego na więcej niż jedno z nich nie spowoduje awarii, natomiast zadziała tak jakby aktywowane było jedynie pierwsze z wejść (w powyższej kolejności) które otrzymały stan wysoki.

#### Sygnały wyjściowe:

* `splitter_object_inside` - stan wysoki (3.3V) informuje że obiekt znalazł się w obszarze działania bloczka i (jeżeli żadne z wejść nie jest w stanie wysokim) to został zatrzymany.
