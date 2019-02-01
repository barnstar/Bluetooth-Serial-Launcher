
/*********************************************************************************
 * BT Video Launcher
 *
 * Launch your stuff with the bluetooths... With video!
 *
 * Copyright 2019, Jonathan Nobels
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

#define LAUNCHER_VERS 4

#define ARM_ON      "AO"        //Arm enable
#define ARM_OFF     "AF"        //Arm disable
#define FIRE_ON     "FO"        //Fire enable
#define FIRE_OFF    "FF"        //Fire disable
#define CTY_ON      "CO"        //Continuity enable
#define CTY_OFF     "CF"        //Continuity disable
#define PING        "PI"        //Ping

#define ARM_BUZZ_EN "ABE"       //Enable or disable the armed buzzer.  Arg 0 or 1

#define REQ_VALID   "RV"        //Validation required (launcher->controller)

#define VALIDATE    "VA"        //Validate.  Arg is the 4 digit code
#define VCODE       "0000"      //Default code

#define DEVICEID    "ID"        //Device ID.  Arg is the ID
#define VERSION     "VER"       //Version.  Arg is the version

#define SETCODE     "SC"        //Set the pin code.  Arg is the 4 digit code

#define CTY_OK      "CY"        //Continuity check OK
#define CTY_NONE    "CX"        //Continuity check no continuity

#define LV_BAT_LEV  "BL"        //Lipo Battery level.  Arg is the voltage reading
#define HV_BAT_LEV  "HVBL"      //Main (launch) battery level.  Arg is the voltage reading

#define CMD_TERM    ':'
#define CMD_SEP     '|'


//For Swift which doesn't translate chars to constants
#define CMD_TERM_S  ":"
#define CMD_SEP_S   "|"

#define CMD_LEN_MAX  16

#define PIN_LEN 4
#define PIN_VER {'v','1','0','0'}
