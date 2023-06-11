//
//  BTSerialController.swift
//  BTLauncher
//
//  Created by Jonathan Nobels on 2023-06-09.
//  Copyright © 2023 Jonathan Nobels. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTController: NSObject, BluetoothSerialDelegate {

    private var responseBuffer : String = ""
    private var reading : Bool = false

    var terminal : TerminalDelegate?
    var btSerial : BluetoothSerial!
    var serialConnectionReady = false

    @Published var signalLevel: Double = 0
    @Published var command: String?
    
    init(_ serial: BluetoothSerial) {
        self.btSerial = serial
    }
    
    func serialDidReceiveString(_ message: String)
    {
        var msg = message
                    .trimmingCharacters(in: .newlines)
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
         
        
        NSLog(">>> \(msg)")
        terminal?.appendString("-> \(msg)\n")

        //First character is a command terminator, put us in reading mode
        if(msg.prefix(1) == CMD_TERM_S) {
            responseBuffer = ""
            reading = true
        }

        // Disacard any leading junk characters up to the command terminator
        // There's a bug where some responses will not be enclosed in the terminators
        if false == reading && msg.prefix(1) != CMD_TERM_S {
            if let idx = msg.firstIndex(of: ":") {
                let junk = msg.prefix(upTo: idx)
                msg = String(msg.suffix(from: idx))
                responseBuffer = ""
                reading = true
            }
        }

        if(reading) {
            responseBuffer.append(msg)
        }

        //Read until the last character in the buffer is a terminator
        if(responseBuffer.count > 0 && String(responseBuffer.last!) == CMD_TERM_S) {
            NSLog("Parsing response buffer \(responseBuffer)")
            let commands = responseBuffer.components(separatedBy: ":").filter{ $0.count > 1 }
            reading = false
            responseBuffer = ""
            
            //publish Each of the commands
            commands.forEach { cmd in
                NSLog("Publishing response \(cmd)")
                //This will publish each command in sequence
                self.command = cmd
            }
        }
    }

    func serialDidReadRSSI(_ rssi: NSNumber)  {
        self.signalLevel = rssi.doubleValue
    }
    
    func readRSSI() {
        btSerial.readRSSI()
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        serialConnectionReady = true
    }

    @discardableResult
    public func sendCommand(_ command: String) -> Bool
    {
        if false == serialConnectionReady {
            return false
        }
        
        btSerial.sendMessageToDevice(command);
        NSLog("<<< \(command)")
        if let delegate = terminal {
            delegate.appendString("<- \(command)\n")
        }
        return true
    }

}


class BTConnections: BluetoothConnectionDelegate
{
    @Published var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    @Published var connected =  false
    @Published var scanning =  false

    var btSerial: BluetoothSerial!

    init(_ serial: BluetoothSerial) {
        btSerial = serial
    }
    
    func startScan() {
        scanning = true
        peripherals.removeAll()
        btSerial.startScan()
    }
    
    func stopScan() {
        scanning = false
        btSerial.stopScan()
    }

    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?)
    {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }

        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        peripherals.sort { $0.RSSI < $1.RSSI }
    }

    func serialDidChangeState() {
    }
    
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        btSerial.connectToPeripheral(peripheral)
    }


    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?)
    {
        connected = false
    }

    func serialDidConnect(_ peripheral: CBPeripheral)
    {
        connected = true
    }

}
