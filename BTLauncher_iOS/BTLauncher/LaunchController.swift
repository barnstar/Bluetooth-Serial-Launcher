
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

import Foundation
import CoreBluetooth

class LaunchController : NSObject, BluetoothSerialDelegate
{
    @objc dynamic var armed : Bool = false {
        didSet {
            if(armed) {
                BluetoothSerial.shared().sendMessageToDevice(":ARM_ON:")
            }   else  {
                BluetoothSerial.shared().sendMessageToDevice(":ARM_OFF:")
            }
        }
    }

    @objc dynamic var connected : Bool = false {
        didSet {
            if(connected) {
                BluetoothSerial.shared().sendMessageToDevice(":PING:")
            }  
        }
    }

    private static let instance : LaunchController = {
        let instance = LaunchController()
        instance.armed = false;
        BluetoothSerial.shared().delegate = instance;
        return instance
    }()

    class func shared() -> LaunchController {
        return instance
    }

    public func sendLaunchCommand(_ enable: Bool) {
        if(armed && enable) {
            NSLog("Launch Sent")
            BluetoothSerial.shared().sendMessageToDevice(":FIRE_ON:")
        }else if(!enable) {
            BluetoothSerial.shared().sendMessageToDevice(":FIRE_OFF:")
        }else{
            NSLog("Not Armed");
        }
    }

    public func sendContinuityComman(_ enable: Bool) {
        if(enable) {
            NSLog("Continuity On Sent")
            BluetoothSerial.shared().sendMessageToDevice(":CTEST_ON:")
        }else{
            NSLog("Continuity Off Sent");
            BluetoothSerial.shared().sendMessageToDevice(":CTEST_OFF:")
        }
    }
}
