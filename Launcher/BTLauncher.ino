

#include "BTLauncher.h"
#include <SoftwareSerial.h>

String kFireOn = String("FIRE_ON");
String kFireOff = String("FIRE_OFF");
String kArm = String("ARM_ON");
String kDisarm = String("ARM_OFF");
String kPing = String("PING");
String kCTestOn = String("CTEST_ON");
String kCTestOff = String("CTEST_OFF");

SoftwareSerial BTSerial(5, 6);
bool armed;

const byte ARMED_INDICATOR_PIN = D1;
const byte CONTINUTITY_READ_PIN = D2;
const byte CONTINUTITY_TEST_PIN = D3;
const byte FIRE_CONTROL_PIN = D4;
const byte ARM_CONTROL_PIN = D5;

void setup()
{
    Serial.begin(9600);
    SoftwareSerial.begin(38400);

    pinMode(ARMED_INDICATOR_PIN, OUTPUT);
    pinMode(FIRE_CONTROL_PIN, OUTPUT);
    pinMode(ARM_CONTROL_PIN, OUTPUT);
    
    pinMode(CONTINUTITY_READ_PIN, INPUT_PULLUP);
    pinMode(CONTINUTITY_TEST_PIN, OUTPUT);

    write(ARMED_INDICATOR_PIN, LOW);
    write(FIRE_CONTROL_PIN, LOW);
    write(ARM_CONTROL_PIN, LOW);
}

void loop()
{
    readCommand();
}

void readCommand()
{
    const size_t cmdLen = 16;
    static char cmd[cmdLen];
    memset(cmd, 0, cmdLen);

    int index = 0;
    bool hasCommand = false;
    while (BTSerial.available())
    {
        if (index < cmdLen)
        {
            cmd[index] = BTSerial.read();
            hasCommand = true;
        }
        else
        {
            //Discard.  Command is too long.  Discard
            (void)BTSerial.read();
            hasCommand = false;
        }
        index++;
    }

    if (hasCommand)
    {
        String command = String(cmd);
        executeCommand(command);
    }
}

void executeCommand(const String &command)
{
    Serial.println("Command: " + command);
    if (command == kFireOn)
    {
        write(FIRE_CONTROL_PIN, HIGH);
    }
    else if (command == kFireOff)
    {
        write(FIRE_CONTROL_PIN, LOW);
    }
    else if (command == kArm)
    {
        armed = true;
        write(ARMED_INDICATOR_PIN, HIGH);
        write(ARM_CONTROL_PIN, HIGH);
    }
    else if (command == kDisarm)
    {
        armed = false;
        write(ARMED_INDICATOR_PIN, LOW);
        write(ARM_CONTROL_PIN, LOW);
    }
    else if (command == kPing)
    {
        //Play a double beep to indicate all is well.
        write(ARMED_INDICATOR_PIN, HIGH);
        delay(1000);
        write(ARMED_INDICATOR_PIN, LOW);
        delay(100);
        write(ARMED_INDICATOR_PIN, HIGH);
        delay(1000);
        write(ARMED_INDICATOR_PIN, LOW);
    }
}
