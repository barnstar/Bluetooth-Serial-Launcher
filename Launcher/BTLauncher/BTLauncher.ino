
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
#include "LauncherProtocol.h"

//Serial commands
String kFireOn = String(FIRE_ON);
String kFireOff = String(FIRE_OFF);
String kArm = String(ARM_ON);
String kDisarm = String(ARM_OFF);
String kPing = String(PING);
String kCTestOn = String(CTY_ON);
String kCTestOff = String(CTY_OFF);

String kCtyOn = String(CTY_OK);
String kCtyNone = String(CTY_NONE);


String kValidate = String(VALIDATE);
String kValidationCode = String(VCODE);

//Command structure is :COMMAND|VALUE:
const char cmdTerminator = CMD_TERM;
const char cmdValSeparator = CMD_SEP;
const size_t cmdLen = CMD_LEN_MAX;

#pragma mark -

SoftwareSerial BTSerial(BT_TX_PIN, BT_RX_PIN);

//Buffers for our serial commands
int cmdBufferIndex = 0;
char cmdBuffer[cmdLen];
char valueBuffer[cmdLen];
bool readingCmd = false;
bool readingVal = false;

const int MAX_ARM_TIME = 5000;
long armTime = 0;
bool armed;

const int MAX_FIRE_TIME_MS = 5000;
long fireTime = 0;

const int MAX_CONTINUITY_TIME_MS = 5000;
long continuityTime = 0;

bool isReady = false;
bool continuity = false;

void setup()
{
    Serial.begin(9600);
    BTSerial.begin(9600);

    Serial.println("Initialized");

    //If using relays, ground the pins to keep the relay
    //close (for the ones I'm using - YMMV)
    pinMode(CONTINUTITY_CONTROL_PIN, OUTPUT);
    pinMode(FIRE_CONTROL_PIN, INPUT);
    pinMode(ARM_CONTROL_PIN, INPUT);
    pinMode(CONTINUITY_READ_PIN, INPUT);

    pinMode(ARMED_INDICATOR_PIN, OUTPUT);
    digitalWrite(ARMED_INDICATOR_PIN, LOW);

    //Redudancy?
    setArmed(false);
    setFired(false);
    setContinuityTestOn(false);
}

void loop()
{
    if (!isReady)
    {
        playReadyTone();
        isReady = true;
    }
    
    readCommand();

    //Safety.  We don't want to keep any of these relays engaged for more than a few
    //seconds
    if (millis() - armTime > MAX_ARM_TIME)
    {
        setArmed(false);
    }

    if (millis() - fireTime > MAX_ARM_TIME)
    {
        setFired(false);
    }

    //Read the voltage on the continuity pin.  
    int cty_val = analogRead(CONTINUITY_READ_PIN);
    if(cty_val > 512 && !continuity) {
        String cmd = command(kCtyOn);
        BTSerial.println(cmd);
        continuity = true;
    }else if(cty_val < 128 && continuity) {
        String cmd = command(kCtyNone);
        BTSerial.println(cmd);
        continuity = false;
    }    
}

void readCommand()
{
    if (BTSerial.available())
    {
        char c = BTSerial.read();
        if (c == cmdTerminator && !readingCmd && !readingVal)
        {
            cmdBufferIndex = 0;
            readingCmd = true;
            memset(cmdBuffer, 0, cmdLen);
            memset(valueBuffer, 0, cmdLen);
            return;
        }

        if (c == cmdValSeparator && readingCmd)
        {
            cmdBufferIndex = 0;
            readingCmd = false;
            readingVal = true;
            return;
        }

        if (c == cmdTerminator && (readingCmd || readingVal))
        {
            String cmd = String(cmdBuffer);
            String value = String(valueBuffer);

            executeCommand(cmd, value);
            readingCmd = false;
            readingVal = false;
            return;
        }

        if (cmdBufferIndex < (cmdLen - 1))
        {
            if (readingCmd)
            {
                cmdBuffer[cmdBufferIndex] = c;
            }
            else if (readingVal)
            {
                valueBuffer[cmdBufferIndex] = c;
            }
            cmdBufferIndex++;
        }
    }
}

void executeCommand(const String &cmd, const String &value)
{
    Serial.println("Command: " + cmd + "|" + value);
    if (cmd == kFireOn)
    {
        //Redundancy
        if (armed)
        {
            setFired(true);
        }
    }
    else if (cmd == kFireOff)
    {
        setFired(false);
    }
    else if (cmd == kArm)
    {
        setArmed(true);
    }
    else if (cmd == kDisarm)
    {
        setArmed(false);
    }
    else if (cmd == kCTestOn)
    {
        setContinuityTestOn(true);
    }
    else if (cmd == kCTestOff)
    {
        setContinuityTestOn(false);
    }
    else if (cmd == kPing)
    {
        //Play a double beep to indicate all is well.
        playPingTone();
    }
    else if (cmd == kValidate)
    {
        if (value == kValidationCode)
        {
            String validateCmd = commandVal(kValidate, kValidationCode);
            //Return our internal validation code
            BTSerial.println(validateCmd);
            playPingTone();
        }
    }
}

String commandVal(String const& cmd, String const& val)
{
    return CMD_TERM_S + cmd + CMD_SEP_S + val + CMD_TERM_S;
}

String command(String const& cmd)
{
    return CMD_TERM_S + cmd + CMD_TERM_S;
}

//The relay boards I'm using trigger when the "input" pin
//is grounded.  So to turn them off, we set the pin to an
//input (without a pullup resistor) and to turn them on
//And set them to an ouput and set the pin to low.
//Your setup may be different.

void setContinuityTestOn(bool on)
{
    if (on)
    {
        continuityTime = millis();
        digitalWrite(CONTINUTITY_CONTROL_PIN, HIGH);
    }
    else
    {
        digitalWrite(CONTINUTITY_CONTROL_PIN, LOW);
        fireTime = 0;
    }
}

void setFired(bool fire)
{
    if (fire)
    {
        if (armed)
        {
            fireTime = millis();
            pinMode(FIRE_CONTROL_PIN, OUTPUT);
            digitalWrite(FIRE_CONTROL_PIN, LOW);
        }
    }
    else
    {
        pinMode(FIRE_CONTROL_PIN, INPUT);
        fireTime = 0;
    }
}

void setArmed(bool shouldArm)
{
    if (shouldArm)
    {
        armed = true;
        armTime = millis();
        digitalWrite(ARMED_INDICATOR_PIN, HIGH);
        pinMode(ARM_CONTROL_PIN, OUTPUT);
        digitalWrite(ARM_CONTROL_PIN, LOW);
    }
    else
    {
        armed = false;
        digitalWrite(ARMED_INDICATOR_PIN, LOW);
        pinMode(ARM_CONTROL_PIN, INPUT);
        armTime = 0;
    }
}

void playPingTone()
{
    digitalWrite(ARMED_INDICATOR_PIN, HIGH);
    delay(400);
    digitalWrite(ARMED_INDICATOR_PIN, LOW);
    delay(100);
    digitalWrite(ARMED_INDICATOR_PIN, HIGH);
    delay(400);
    digitalWrite(ARMED_INDICATOR_PIN, LOW);
}

void playReadyTone()
{
    for (int i = 0; i < 3; i++)
    {
        digitalWrite(ARMED_INDICATOR_PIN, HIGH);
        delay(100);
        digitalWrite(ARMED_INDICATOR_PIN, LOW);
        delay(100);
    }
}