/*********************************************************************************
 * BT Video Launcher
 *
 * Launch your stuff with the bluetooths.
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
import Combine

let kEnableTestMode = false

protocol TerminalDelegate {
    func appendString(_ string: String);
}


final class LaunchController : NSObject, BluetoothSerialDelegate
{
    private var signalTimer : AnyCancellable?
    private var voltageTimer : AnyCancellable?

    private var setCodeCallback : (()->Void)?
    
    let btSerial: BluetoothSerial
    let btController: BTController
    let btConnections: BTConnections
    
    var subsciberes = [AnyCancellable]()
    
    private static let instance : LaunchController = {
        LaunchController(BluetoothSerial())
    }()

    class func shared() -> LaunchController {
        instance
    }
    
    init(_ serial: BluetoothSerial) {
        self.armed = false
        if(kEnableTestMode) {
            validated = true
        }
        
        self.btSerial = serial
        self.btController = BTController(self.btSerial)
        self.btConnections = BTConnections(self.btSerial)
        self.btSerial.delegate = btController
        self.btSerial.connectionDelegate = btConnections
        super.init()

         btController.$command
            .filter { nil != $0 }
            .sink { [weak self] value in
                self?.handleIncomingCommand(value!)
            }.store(in: &subsciberes)
        
        btConnections.$connected
            .sink { [weak self] connected in
                switch connected{
                case false:
                    self?.validated = false
                    self?.signalTimer?.cancel()
                case true:
                    self?.signalTimer = Timer.publish(every: 2.0, on: .main, in: .default)
                        .autoconnect()
                        .sink { _ in
                            self?.btController.readRSSI()
                        }
                    
                }
                
            }.store(in: &subsciberes)
    }

    //MARK: Obserable Properties
   @Published var continuity : Bool = false
   @Published var deviceId : String?
   @Published var deviceVersion : String?
   @Published var rssi : Float = 0.0
   @Published var validated : Bool = false
   @Published var batteryLevel : Float = 0.0
   @Published var hvBatteryLevel : Float = 0.0
   @Published var armed : Bool = false


    //MARK: Command Interface

    private func constructCommand(_ command:String, value:String?) -> String
    {
        var ret = CMD_TERM_S + command
        if let value = value {
            ret = ret + CMD_SEP_S + value
        }
        ret = ret + CMD_TERM_S
        return ret
    }

    func setArmed(_ val: Bool) {
        armed = val
        sendArmedCommand(armed)
    }

    public func pingConnectedDevice()
    {
        //Allow ping w/o validation
        let cmdStr = constructCommand(PING, value:nil)
        btController.sendCommand(cmdStr)
    }

    public func sendSetValidationCodeCommand(_ code: String, callback:@escaping ()->Void)
    {
        guard validated else { return }

        setCodeCallback = callback
        let cmdStr = constructCommand(SETCODE, value: code)
        btController.sendCommand(cmdStr)

        if(kEnableTestMode) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                self.serialDidReceiveString(cmdStr)
            }
        }
    }

    public func sendValidationCommand()
    {
        let cmdStr = constructCommand(VALIDATE, value: LocalSettings.settings.validationCode)
        btController.sendCommand(cmdStr)

        if(kEnableTestMode) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                self.serialDidReceiveString(cmdStr)
            }
        }
    }

    public func sendFireCommand(_ enable: Bool)
    {
        guard validated else { return }

        switch (armed, enable) {
        case (true, true):
            btController.sendCommand(constructCommand(FIRE_ON, value:nil))
        case (_, false):
            btController.sendCommand(constructCommand(FIRE_OFF, value:nil))
        case (false, true):
            break
        }

    }

    public func sendContinuityCommand(_ enable: Bool)
    {
        guard validated else { return }

        let cmdStr = constructCommand((enable ? CTY_ON : CTY_OFF), value:nil)
        btController.sendCommand(cmdStr)

        if(kEnableTestMode) {
            let retStr = constructCommand((enable ? CTY_OK : CTY_NONE), value:nil)
            serialDidReceiveString(retStr)
        }
    }

    public func sendArmBuzzerEnabledCommand(_ enable: Bool)
    {
        let cmdStr = constructCommand(ARM_BUZZ_EN, value:enable ? "1" : "0")
        btController.sendCommand(cmdStr)
    }

    public func sendArmedCommand(_ enable: Bool)
    {
        guard validated else { return }

        let cmdStr = constructCommand((enable ? ARM_ON : ARM_OFF), value:nil)
        btController.sendCommand(cmdStr)
    }

    public func sendCheckVoltage()
    {
        //Low voltage (arduino battery)
        let cmdStrLv = constructCommand(LV_BAT_LEV, value:nil)
        btController.sendCommand(cmdStrLv)

        if(kEnableTestMode) {
            let retStr = constructCommand(LV_BAT_LEV, value:"3.30")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                self.serialDidReceiveString(retStr)
            }
        }

        //High voltage (main battery)
        let cmdStrHv = constructCommand(HV_BAT_LEV, value:nil)
        btController.sendCommand(cmdStrHv)

        if(kEnableTestMode) {
            let retStr = constructCommand(HV_BAT_LEV, value:"12.0")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                self.serialDidReceiveString(retStr)
            }
        }

    }

    private func handleIncomingCommand(_ cmd:String)
    {
        let stripped = cmd.trimmingCharacters(in: CharacterSet.init(charactersIn: CMD_TERM_S))
        let parts = stripped.components(separatedBy: CMD_SEP_S)
        let cmdStr = parts[0]
        let valStr : String? = parts.count == 2 ? parts[1] : nil
        
        
        switch (cmdStr, valStr) {
        case (VALIDATE, LocalSettings.settings.validationCode):
            validated = true
        case (DEVICEID, _):
            deviceId = valStr
        case (CTY_OK, _):
            continuity = true
        case (CTY_NONE, _):
            continuity = false
        case (REQ_VALID, _):
            validated = false
        case (VERSION, _):
            deviceVersion = valStr
        case (SETCODE, _):
            if let cb = setCodeCallback {
                cb()
                setCodeCallback = nil
            }
        case (LV_BAT_LEV, .some(let valStr)):
            batteryLevel = Float(valStr) ?? 0.0
        case (HV_BAT_LEV, .some(let valStr)):
            hvBatteryLevel = Float(valStr) ?? 0.0
        default:
            break
        }

    }
}
