
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

import Foundation
import CoreBluetooth

let kEnableLoopbackTest = false

class LaunchController : NSObject, BluetoothSerialDelegate
{
    private static let instance : LaunchController = {
        let instance = LaunchController()
        instance.armed = false
        BluetoothSerial.shared().delegate = instance
        return instance
    }()

    class func shared() -> LaunchController {
        return instance
    }

    //MARK: Obserable Properties

    @objc dynamic var continuity : Bool = false;

    @objc dynamic var deviceId : String?

    @objc dynamic var armed : Bool = false {
        didSet {
            sendArmedCommand(armed)
        }
    }

    @objc dynamic var connected : Bool = false {
        didSet {
            if(!connected) {
                validated = false
            }
        }
    }

    @objc dynamic var validated : Bool = false {
        didSet {
            NSLog("Validated \(validated)")
        }
    }


    //MARK: Command Interface

    func command(_ command:String, value:String?) -> String
    {
        var ret = CMD_TERM_S + command
        if let value = value {
            ret = ret + CMD_SEP_S + value
        }
        ret = ret + CMD_TERM_S
        return ret
    }


    public func pingConnectedDevice()
    {
        BluetoothSerial.shared().sendMessageToDevice(command(PING, value:nil))
    }

    public func sendValidationCommand()
    {
        let cmdStr = command(VALIDATE, value: LocalSettings.settings.validationCode)
        BluetoothSerial.shared().sendMessageToDevice(cmdStr)

        if(kEnableLoopbackTest) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                self.handleIncomingCommand(cmdStr)
            }
        }
    }

    public func sendFireCommand(_ enable: Bool)
    {
        if(!validated) {
            return
        }

        if(armed && enable) {
            BluetoothSerial.shared().sendMessageToDevice(command(FIRE_ON, value:nil))
        }else if(!enable) {
            BluetoothSerial.shared().sendMessageToDevice(command(FIRE_OFF, value:nil))
        }else{
            NSLog("Fire Command Ignored: Not Armed")
        }
    }

    public func sendContinuityCommand(_ enable: Bool)
    {
        if(!validated) {
            return
        }

        let cmdStr = command((enable ? CTY_ON : CTY_OFF), value:nil)
        BluetoothSerial.shared().sendMessageToDevice(cmdStr)

        if(kEnableLoopbackTest) {
            handleIncomingCommand(enable ? CTY_OK : CTY_NONE);
        }
    }

    func sendArmedCommand(_ enable: Bool)
    {
        if(!validated) {
            return
        }
        
        let cmdStr = command((enable ? ARM_ON : ARM_OFF), value:nil)
        BluetoothSerial.shared().sendMessageToDevice(cmdStr)
    }

    func handleIncomingCommand(_ cmd:String)
    {
        //Separate the command and the value
        let parts = cmd.components(separatedBy: CMD_SEP_S)
        let cmdStr = parts[0]
        let valStr : String? = parts.count == 2 ? parts[1] : nil

        if(cmd == command(VALIDATE, value: LocalSettings.settings.validationCode)) {
            validated = true
        }else if(cmdStr == DEVICEID) {
            deviceId = valStr
        }else if(cmdStr == CTY_OK) {
            continuity = true
        }else if(cmdStr == CTY_NONE) {
            continuity = false
        }
    }

    //MARK: BT Serial Delegate

    var stringBuffer : String = ""
    var cmdIncoming : Bool = false

    func serialDidReceiveString(_ message: String)
    {
        if(message.prefix(1) == CMD_TERM_S) {
            cmdIncoming = true
        }

        if(cmdIncoming) {
            stringBuffer.append(message)
        }

        //No particularily robust if we're quickly sending multiple commands.
        if(String(stringBuffer.last!) == CMD_TERM_S) {
            cmdIncoming = false
            //Trim the terminators
            stringBuffer = stringBuffer.trimmingCharacters(in: CharacterSet.init(charactersIn: CMD_TERM_S))
            handleIncomingCommand(stringBuffer)
            stringBuffer = ""
        }
    }
}
