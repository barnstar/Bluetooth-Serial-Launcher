
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
#include "EEPROM.h"

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
String kRequiresValidation = String(REQ_VALID);
String kVersion = String(VERSION);
String kSetCode = String(SETCODE);

//Command structure is :COMMAND|VALUE:
const char cmdTerminator = CMD_TERM;
const char cmdValSeparator = CMD_SEP;
const size_t cmdLen = CMD_LEN_MAX;

//No methods in this or it cant be used in the EEPROM calls
typedef struct
{
    uint8_t header[PIN_LEN] = PIN_VER;
    uint8_t code[PIN_LEN] = {'0', '0', '0', '0'};
} PinCode;

#pragma mark -

SoftwareSerial BTSerial(BT_TX_PIN, BT_RX_PIN);

//Buffers for our serial commands
int cmdBufferIndex = 0;
char cmdBuffer[cmdLen];
char valueBuffer[cmdLen];
bool readingCmd = false;
bool readingVal = false;

const int MAX_ARM_TIME_MS = 5000;
long armTime = 0;
bool armed;

const int MAX_FIRE_TIME_MS = 5000;
long fireTime = 0;

const int MAX_CONTINUITY_TIME_MS = 5000;
long continuityTime = 0;

bool isReady = false;
bool continuity = false;
bool ctyTestActive = false;

bool validated = false;

void log(String msg)
{
    Serial.println(msg);
    BTSerial.println(msg);
}

void setup()
{
    Serial.begin(9600);
    BTSerial.begin(9600);

    log("Initialized");

    //If using relays, ground the pins to keep the relay
    //close (for the ones I'm using - YMMV)
    pinMode(CONTINUTITY_CONTROL_PIN, INPUT);
    pinMode(FIRE_CONTROL_PIN, INPUT);
    pinMode(ARM_CONTROL_PIN, INPUT);
    pinMode(CONTINUITY_READ_PIN, INPUT_PULLUP);

    pinMode(BUZZER_PIN, OUTPUT);
    digitalWrite(BUZZER_PIN, LOW);

    //Redundancy?
    setArmed(false);
    setFired(false);
    setContinuityTestOn(false);

    //PinCode emptyPin;
    //setPinCode(emptyPin);
}

void loop()
{
    if (!isReady)
    {
        playReadyTone();
        isReady = true;

        //Send the version
        String vers = String(LAUNCHER_VERS);
        String cmd = commandVal(kVersion, vers);
        BTSerial.println(cmd);

        //Send the validation required in case we reset while connected
        String cmdRet = command(kRequiresValidation);
        BTSerial.println(cmdRet);

        PinCode p = readPinCode();
        String pStr = pinToString(p);
        Serial.println(pStr);
    }

    readCommand();

    //Safety.  We don't want to keep any of these relays engaged for more than a few
    //seconds
    if (millis() - armTime > MAX_ARM_TIME_MS)
    {
        setArmed(false);
    }

    if (millis() - fireTime > MAX_FIRE_TIME_MS)
    {
        setFired(false);
    }

    if (millis() - continuityTime > MAX_CONTINUITY_TIME_MS)
    {
        setContinuityTestOn(false);
    }

    if (ctyTestActive)
    {
        //Read the voltage on the continuity pin.
        int cty_val = digitalRead(CONTINUITY_READ_PIN);
        if (cty_val == LOW && !continuity)
        {
            String cmd = command(kCtyOn);
            BTSerial.println(cmd);
            continuity = true;
            digitalWrite(BUZZER_PIN, HIGH);
        }
        else if (cty_val == HIGH && continuity)
        {
            String cmd = command(kCtyNone);
            BTSerial.println(cmd);
            continuity = false;
            digitalWrite(BUZZER_PIN, LOW);
        }
    }
}

void readCommand()
{
    while (BTSerial.available())
    {
        char c = BTSerial.read();
        Serial.print(c);
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
            Serial.print("\n");
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
    log("Cmd Recv: " + cmd + "|" + value);
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
        playPingTone();
        BTSerial.println(kPing);
    }
    else if (cmd == kValidate)
    {
        validated = true;
        String validateCmd = commandVal(kValidate, value);
        BTSerial.println(validateCmd);

        /*
        PinCode pin = readPinCode();
        if (comparePinCode(pin, value))
        {
            String pinStr = pinToString(pin);
            Serial.println("Sending:" + pinStr);
            String validateCmd = commandVal(kValidate, pinStr);
            //Return our internal validation code
            BTSerial.println(validateCmd);
            Serial.println("Sent:" + validateCmd);
            playPingTone();
            validated = true;
        }*/
    }
    else if (cmd == kSetCode)
    {
        PinCode code;
        value.toCharArray(code.code, PIN_LEN);
        setPinCode(code);

        //Echo back to indicate we've set the pin
        String pinSetCmd = commandVal(cmd, value);
        BTSerial.println(pinSetCmd);
    }
}

String commandVal(String const &cmd, String const &val)
{
    return CMD_TERM_S + cmd + CMD_SEP_S + val + CMD_TERM_S;
}

String command(String const &cmd)
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
    if (!validated)
    {
        return;
    }

    if (on)
    {
        ctyTestActive = true;
        continuityTime = millis();
        pinMode(CONTINUTITY_CONTROL_PIN, OUTPUT);
        digitalWrite(CONTINUTITY_CONTROL_PIN, LOW);
    }
    else
    {
        ctyTestActive = false;
        pinMode(CONTINUTITY_CONTROL_PIN, INPUT);
        continuityTime = 0;
        continuity = false;
        String cmd = command(kCtyNone);
        BTSerial.println(cmd);
    }
}

void setFired(bool fire)
{
    if (!validated)
    {
        return;
    }

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
    if (!validated)
    {
        return;
    }

    if (shouldArm)
    {
        armed = true;
        armTime = millis();
        digitalWrite(BUZZER_PIN, HIGH);
        pinMode(ARM_CONTROL_PIN, OUTPUT);
        digitalWrite(ARM_CONTROL_PIN, LOW);
    }
    else
    {
        armed = false;
        digitalWrite(BUZZER_PIN, LOW);
        pinMode(ARM_CONTROL_PIN, INPUT);
        armTime = 0;
    }
}

void playPingTone()
{
    digitalWrite(BUZZER_PIN, HIGH);
    delay(400);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
    digitalWrite(BUZZER_PIN, HIGH);
    delay(400);
    digitalWrite(BUZZER_PIN, LOW);
}

void playReadyTone()
{
    for (int i = 0; i < 3; i++)
    {
        digitalWrite(BUZZER_PIN, HIGH);
        delay(100);
        digitalWrite(BUZZER_PIN, LOW);
        delay(100);
    }
}

#pragma mark - PinCode Support

bool isValidPin(PinCode p)
{
    PinCode emptyPin;
    for (int i = 0; i < 4; i++)
    {
        if (emptyPin.header[i] != p.header[i])
        {
            return false;
        }
    }
    return true;
}

bool comparePinCode(PinCode &pin, String pinStr)
{
    if (pinStr.length() != 4)
    {
        return false;
    }

    log("Comparing:" + pinStr);
    for (int i = 0; i < PIN_LEN; i++)
    {
        if (pin.code[i] != pinStr.charAt(i))
        {
            log("Code mismatch");
            return false;
        }
    }
    log("Code match");
    return true;
}

String pinToString(PinCode &p)
{
    char codeStr[PIN_LEN + 1];
    codeStr[PIN_LEN] = '\0';
    memcpy(codeStr, p.code, PIN_LEN);
    return String(codeStr);
}

void setPinCode(PinCode p)
{
    EEPROM.put(0, p);
}

PinCode readPinCode()
{
    PinCode pinCode;
    EEPROM.get(0, pinCode);
    if (!isValidPin(pinCode))
    {
        log("Setting default PIN code");
        PinCode emptyPin;
        setPinCode(emptyPin);
        return emptyPin;
    }
    return pinCode;
}
