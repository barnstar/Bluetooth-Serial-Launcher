
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

#include "BTLauncher.h"
#include <SoftwareSerial.h>

String kFireOn = String("FIRE_ON");
String kFireOff = String("FIRE_OFF");
String kArm = String("ARM_ON");
String kDisarm = String("ARM_OFF");
String kPing = String("PING");
String kCTestOn = String("CTEST_ON");
String kCTestOff = String("CTEST_OFF");

const char cmdTerminator = ':';

SoftwareSerial BTSerial(3, 4);
bool armed;

const byte ARMED_INDICATOR_PIN = 7;
const byte CONTINUTITY_READ_PIN = 5;
const byte CONTINUTITY_TEST_PIN = 6;
const byte FIRE_CONTROL_PIN = 8;
const byte ARM_CONTROL_PIN = 9;

const size_t cmdLen = 16;
int index = 0;
char cmd[cmdLen];
bool readingCmd = false;

void setup()
{
    Serial.begin(9600);
    BTSerial.begin(9600);

    Serial.println("Initialized");

    pinMode(ARMED_INDICATOR_PIN, OUTPUT);
    pinMode(FIRE_CONTROL_PIN, OUTPUT);
    pinMode(ARM_CONTROL_PIN, OUTPUT);

    pinMode(CONTINUTITY_READ_PIN, INPUT_PULLUP);
    pinMode(CONTINUTITY_TEST_PIN, OUTPUT);

    digitalWrite(ARMED_INDICATOR_PIN, LOW);
    digitalWrite(FIRE_CONTROL_PIN, LOW);
    digitalWrite(ARM_CONTROL_PIN, LOW);
}

void loop()
{
    readCommand();
}

void readCommand()
{

    bool hasCommand = false;
    if (BTSerial.available())
    {
        char val = BTSerial.read();
        if (val == cmdTerminator && !readingCmd)
        {
            index = 0;
            readingCmd = true;
            memset(cmd, 0, cmdLen);
            return;
        }

        if (val == cmdTerminator && readingCmd)
        {
            String command = String(cmd);
            executeCommand(command);
            readingCmd = false;
            return;
        }

        if (index < cmdLen)
        {
            cmd[index] = val;
            index++;
        }
    }
}

void executeCommand(const String &command)
{
    Serial.println("Command: " + command);
    if (command == kFireOn)
    {
        digitalWrite(FIRE_CONTROL_PIN, HIGH);
    }
    else if (command == kFireOff)
    {
        digitalWrite(FIRE_CONTROL_PIN, LOW);
    }
    else if (command == kArm)
    {
        armed = true;
        digitalWrite(ARMED_INDICATOR_PIN, HIGH);
        digitalWrite(ARM_CONTROL_PIN, HIGH);
    }
    else if (command == kDisarm)
    {
        armed = false;
        digitalWrite(ARMED_INDICATOR_PIN, LOW);
        digitalWrite(ARM_CONTROL_PIN, LOW);
    }
    else if (command == kPing)
    {
        //Play a double beep to indicate all is well.
        digitalWrite(ARMED_INDICATOR_PIN, HIGH);
        delay(1000);
        digitalWrite(ARMED_INDICATOR_PIN, LOW);
        delay(100);
        digitalWrite(ARMED_INDICATOR_PIN, HIGH);
        delay(1000);
        digitalWrite(ARMED_INDICATOR_PIN, LOW);
    }
}
