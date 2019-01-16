# Launcher
Light things on fire remotely with your iThing!

# Hardware
- Arduino Nano
- 5V piezo
- Some LEDs if you want blinky lights
- 220 ohm and 330 ohm resistors
- 2N2222 transistor (quasi optional)
- HC08, HM11 or newer Bluetooth LE modem module
- 3 or 4 relay combo board
- Momentary switch
- SPST switch
- 2s Lipo or a 1s lipo with a 5V boost circuit
- iThing


# Protocol
The launcher uses a simple 2-way serial protocol to issue commands
in the for of :<Command>|<Value>: or simply :<Command>: .  A full
listing of the protocol commands can be found in LauncherProtocol.h.

Both the launcher and phone app require a validation code to be 
shared before any dangerous commands can be issued or consumed.  This
code can be changed via the phone app once validated.  

# Bluetooth
iOS supports only Bluetooth LE so you need a newish module.  The
HC08 works.  The HC05/06 probably won't.  

# Schematic

