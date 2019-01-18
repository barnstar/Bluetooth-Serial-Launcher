# Launcher
Light things on fire remotely with your iThing!
Now with automatic video...

# Hardware
- Arduino Nano
- 5V piezo
- 220 ohm and 330 ohm resistors
- 2N2222 transistor 
- HC08, HM11 or newer Bluetooth LE modem module
- 3 or 4 relay combo board
- 2x Momentary switch (Continuity & Reset)
- SPST switch (Hard Safe)
- 9V, 2s lipo or a 1s lipo with a 5V boost circuit
- ~12V high current battery for making the fire
- iPhone or iPad


# Protocol
The launcher uses a simple 2-way serial protocol to issue commands
in the for of ''':<Command>|<Value>:''' or simply ''':<Command>:''' .  A full
listing of the protocol commands can be found in [LauncherProtocol.h](Launcher/BTLauncher/LauncherProtocol.h)

Both the launcher and phone app require a validation code to be 
shared before any dangerous commands can be issued or consumed.  This
code can be changed via the phone app once validated.  If the unit
is started with RESET_PIN grounded, the code will be reset to "0000".

# Android Support
You have to write this yourself.  Contributions welcome.

# Bluetooth
iOS supports only Bluetooth LE so you need a newish module.  The
HC08 works.  The cheaper HC05/06 will not.   Some setup of the 
BT module using basic AT commands may be required.

# Schematic
![Schematic](Schematic.png =300x)

# Notes
- A voltage divider is required on the battery voltage 
  monitoring line (A0) and some modification to the code
  will be required if your battery voltage exceeds your 
  microcontroller voltage.  I built this using a 1S (3.7v) lipo and
  a boost/charging board and a 5V Arduino Nano.
- The relay wiring will depend on your relays.  I used
  a "trigger low" 4 relay combo board.  This requires
  a ground connection and 5V power. The relays will 
  trigger when their respective pin is connected to
  ground.  See the notes in [BTLauncher.ino](Launcher/BTLauncher/BTLauncher.ino)
- If the pin layout isn't suitable, everything is
  configurable in [BTLauncher.h](Launcher/BTLauncher/BTLauncher.h)
- I opted for a hard separation between the launcher and
  control circuits.  Additional indicators can be
  wired to the NC side of the relays to indicate
  safe/armed etc if desired (either via input pins,
  buzzers or LEDs)




