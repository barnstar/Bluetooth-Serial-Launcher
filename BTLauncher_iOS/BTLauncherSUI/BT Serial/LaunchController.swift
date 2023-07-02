/*********************************************************************************
 * BT Launcher
 *
 * Launch your stuff with the bluetooths.
 *
 * Copyright 2023, Jonathan Nobels
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

protocol TerminalDelegate {
    func appendString(_ string: String);
}

let kSignalCheckInterval: TimeInterval = 2.0
let kVoltageCheckInterval: TimeInterval = 10.0

class LaunchController : ObservableObject
{
    @Published var viewModel = LaunchControlViewModel()
    
    var armed: Bool {
        didSet { viewModel.armed = armed }
    }
    
    var validated: Bool {
        didSet { viewModel.validated = validated }
    }
    
    private var deviceId : String?
    private var deviceVersion : String?
    private var setCodeCallback : (()->Void)?
    
    let btSerial: BluetoothSerial = BluetoothSerial()
    
    var subscriberes = [AnyCancellable]()
    private var signalTimer : AnyCancellable?
    private var voltageTimer : AnyCancellable?
    
    init() {
        self.armed = false
        self.validated = false

        /// Observes the commandParser for incoming commands
        /// and forwards them to the handler method
        btSerial.commandParser.$command
            .filter { nil != $0 }
            .sink { [weak self] value in
                self?.handleIncomingCommand(value!)
            }.store(in: &subscriberes)
        
        /// Observers the serial managers connected peripheral property
        /// and updates the viewModel accordingly
        btSerial.$transmitEnabled
            .sink { [weak self] enabled in
                guard let self = self else { return }
                
                  
                // As soon as we have a connected peripheral, validate it and
                // periodically ping for the battery level and rssi
                switch enabled {
                case true:
                    self.enablePeripheralPing(true)
                    self.viewModel.connected = true
                case false:
                    self.enablePeripheralPing(false)
                    self.viewModel.connected = false
                    self.validated = false
                }
            }.store(in: &subscriberes)
        
       
        btSerial.$signalStrength
            .sink { [weak self] val in
                self?.viewModel.rssi = val ?? 0.0
            }.store(in: &subscriberes)
    }

    private func enablePeripheralPing(_ enabled: Bool) {
        switch enabled {
        case false:
            signalTimer?.cancel()
            voltageTimer?.cancel()
        case true:
            signalTimer = Timer.publish(every: kSignalCheckInterval, on:.main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.btSerial.readRSSI()
                }
            
            voltageTimer = Timer.publish(every: kVoltageCheckInterval, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.sendCheckVoltage()
                }
        }
    }

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

    func ping()
    {
        //Allow ping w/o validation
        let cmdStr = constructCommand(PING, value:nil)
        btSerial.sendMessageToDevice(cmdStr)
    }

    func sendSetValidationCodeCommand(_ code: String, callback:@escaping ()->Void)
    {
        guard validated else { return }

        setCodeCallback = callback
        let cmdStr = constructCommand(SETCODE, value: code)
        btSerial.sendMessageToDevice(cmdStr)
    }

    func sendValidationCommand()
    {
        if validated { return }
        
        let cmdStr = constructCommand(VALIDATE, value: LocalSettings.settings.validationCode)
        btSerial.sendMessageToDevice(cmdStr)
    }

    func sendFireCommand(_ enable: Bool)
    {
        guard validated else { return }

        switch (armed, enable) {
        case (true, true):
            btSerial.sendMessageToDevice(constructCommand(FIRE_ON, value:nil))
        case (_, false):
            btSerial.sendMessageToDevice(constructCommand(FIRE_OFF, value:nil))
        case (false, true):
            break
        }

    }

    func sendContinuityCommand(_ enable: Bool)
    {
        guard validated else { return }

        let cmdStr = constructCommand((enable ? CTY_ON : CTY_OFF), value:nil)
        btSerial.sendMessageToDevice(cmdStr)
    }

    func sendArmBuzzerEnabledCommand(_ enable: Bool)
    {
        let cmdStr = constructCommand(ARM_BUZZ_EN, value:enable ? "1" : "0")
        btSerial.sendMessageToDevice(cmdStr)
    }

    func sendArmedCommand(_ enable: Bool)
    {
        guard validated else { return }

        let cmdStr = constructCommand((enable ? ARM_ON : ARM_OFF), value:nil)
        btSerial.sendMessageToDevice(cmdStr)
        armed = enable
    }

    public func sendCheckVoltage()
    {       
        //Low voltage (arduino battery)
        let cmdStrLv = constructCommand(LV_BAT_LEV, value:nil)
        btSerial.sendMessageToDevice(cmdStrLv)

        //High voltage (main battery)
        let cmdStrHv = constructCommand(HV_BAT_LEV, value:nil)
        btSerial.sendMessageToDevice(cmdStrHv)

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
            viewModel.continuity = true
        case (CTY_NONE, _):
            viewModel.continuity = false
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
            viewModel.batteryLevel = Float(valStr) ?? 0.0
        case (HV_BAT_LEV, .some(let valStr)):
            viewModel.hvBatteryLevel = Float(valStr) ?? 0.0
        default:
            break
        }

    }
}
