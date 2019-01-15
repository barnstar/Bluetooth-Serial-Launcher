
/*********************************************************************************
 * BT Video Launcher
 *
 * Launch your stuff with the bluetooths... With video!
 *
 * Copyright 2018, Jonathan Nobels
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **********************************************************************************/

#include <Arduino.h>

#define LAUNCHER_VERS           1

//GPIO configuration
#define BT_TX_PIN               3       //Software Serial TX Pin
#define BT_RX_PIN               4       //Software Serial RX BUZZER_PIN

#define BUZZER_PIN              6       //Piezo buzzer pin for arm tone
#define POWER_ON_PIN            11      //Power on indicator

//Relay Pins
#define CONTINUTITY_CONTROL_PIN 7       //Relay to control continuity check
#define FIRE_CONTROL_PIN        8       //Relay to control fire    
#define ARM_CONTROL_PIN         9       //Relay to control arming

#define CONTINUITY_READ_PIN     12