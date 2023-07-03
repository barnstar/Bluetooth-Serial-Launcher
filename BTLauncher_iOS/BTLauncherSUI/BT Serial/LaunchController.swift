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
    
    var deviceId : String?
    var deviceVersion : String?
    var setCodeCallback : (()->Void)?
    
    let btSerial: BluetoothSerial = BluetoothSerial()
    
    var subscriberes = [AnyCancellable]()
    var signalTimer : AnyCancellable?
    var voltageTimer : AnyCancellable?
    
    init() {
        self.armed = false
        self.validated = false

        /// Observes the commandParser for incoming commands
        /// and forwards them to the handler method
        btSerial.commandParser.$command
            .filter { nil != $0 }
            .sink { [weak self] value in
                self?.handleResponse(value!)
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

    func ping()
    {
        //Allow ping w/o validation
        let cmdStr = CommandParser.constructCommand(PING, value:nil)
        btSerial.sendMessageToDevice(cmdStr)
    }

    /// Updates the units validation code
    func sendSetValidationCodeCommand(_ code: String, callback:@escaping ()->Void)
    {
        guard validated else { return }

        setCodeCallback = callback
        let cmdStr = CommandParser.constructCommand(SETCODE, value: code)
        btSerial.sendMessageToDevice(cmdStr)
    }

    /// Sends the request to validate with the given code
    func sendValidationCommand()
    {
        if validated { return }
        
        let cmdStr = CommandParser.constructCommand(VALIDATE, value: LocalSettings.settings.validationCode)
        btSerial.sendMessageToDevice(cmdStr)
    }

    /// Sends the fire on/fire off commands
    func sendFireCommand(_ enable: Bool)
    {
        guard validated else { return }

        switch (armed, enable) {
        case (true, true):
            btSerial.sendMessageToDevice(CommandParser.constructCommand(FIRE_ON, value:nil))
        case (_, false):
            btSerial.sendMessageToDevice(CommandParser.constructCommand(FIRE_OFF, value:nil))
        case (false, true):
            break
        }

    }

    /// Enables or disables the continuity check
    func sendContinuityCommand(_ enable: Bool)
    {
        guard validated else { return }

        let cmdStr = CommandParser.constructCommand((enable ? CTY_ON : CTY_OFF), value:nil)
        btSerial.sendMessageToDevice(cmdStr)
    }

    /// Enables/Disables the alarm buzzer
    func sendArmBuzzerEnabledCommand(_ enable: Bool)
    {
        let cmdStr = CommandParser.constructCommand(ARM_BUZZ_EN, value:enable ? "1" : "0")
        btSerial.sendMessageToDevice(cmdStr)
    }

    /// Sends the arm/disarm commands
    func sendArmedCommand(_ enable: Bool)
    {
        guard validated else { return }

        let cmdStr = CommandParser.constructCommand((enable ? ARM_ON : ARM_OFF), value:nil)
        btSerial.sendMessageToDevice(cmdStr)
        armed = enable
    }

    /// Sends a request for both the low and high voltage battery voltges
    public func sendCheckVoltage()
    {       
        //Low voltage (arduino battery)
        let cmdStrLv = CommandParser.constructCommand(LV_BAT_LEV, value:nil)
        btSerial.sendMessageToDevice(cmdStrLv)

        //High voltage (main battery)
        let cmdStrHv = CommandParser.constructCommand(HV_BAT_LEV, value:nil)
        btSerial.sendMessageToDevice(cmdStrHv)

    }

    /// Handles an incoming command string.
    func handleResponse(_ cmd:String)
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
            setCodeCallback?()
            setCodeCallback = nil
        case (LV_BAT_LEV, .some(let valStr)):
            viewModel.batteryLevel = Float(valStr) ?? 0.0
        case (HV_BAT_LEV, .some(let valStr)):
            viewModel.hvBatteryLevel = Float(valStr) ?? 0.0
        default:
            break
        }

    }
}
