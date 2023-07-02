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


import UIKit
import CoreBluetooth
import Combine

enum ConnectionState {
    case disconnected
    case pending
    case connected
}

protocol PeripheralScanner: AnyObject {
    func startScan()
    func stopScan()
    func connectToPeripheral(_ peripheralID: UUID)
    func disconnect()
}


class BluetoothSerial:
    NSObject,
    CBCentralManagerDelegate,
    CBPeripheralDelegate
{
    /// Non nil iff we're attempting a connection
    @Published var pendingPeripheral: CBPeripheral?
    
    /// Non nil if we have a connected peripheral.
    @Published var connectedPeripheral: CBPeripheral?
    
    /// Non nil if we have a connected peripheral and a value for it's
    /// signal strength
    @Published var signalStrength: Float?

    @Published var transmitEnabled: Bool = false

    /// Tracks and manages the the connection to our peripheral
    var connectionManager: BTConnectionManager!
    
    /// Parses the incoming byte stream into a series of published commands
    var commandParser: CommandParser!
    
    /// Tracks the incoming and outgoing command streams for display
    var commandHistory = CommandHistory()
    
    /// Listens to the incoming command history for publishing to the commandHistory
    var historySub: AnyCancellable?

    /// CoreBluetooth support
    var centralManager: CBCentralManager!
    var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    var writeCharacteristic: CBCharacteristic?
   
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.connectionManager = BTConnectionManager(self)
        self.commandParser = CommandParser()
        
        historySub = commandParser.$command
            .sink { [weak self] val in
                if let val = val {
                    self?.commandHistory.append(val, direction: .rx)
                }
            }
    }
    
    
    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    var isPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }
    
    var serviceUUID = CBUUID(string: "FFE0")
    var characteristicUUID = CBUUID(string: "FFE1")
    
    /// Whether to write to the HM10 with or without response. Set automatically.
    /// Legit HM10 modules (from JNHuaMao) require 'Write without Response',
    /// while fake modules (e.g. from Bolutek) require 'Write with Response'.
    private var writeType: CBCharacteristicWriteType = .withoutResponse

   
    func readRSSI()
    {
        connectedPeripheral?.readRSSI()
    }
       
    @discardableResult
    func sendMessageToDevice(_ message: String) -> Bool
    {
        guard transmitEnabled,
            let connectedPeripheral = connectedPeripheral else {
            commandHistory.append(message + " (FAILED - no device)", direction: .tx)
            return false
        }

        if let data = message.data(using: String.Encoding.utf8) {
            commandHistory.append(message, direction: .tx)
            connectedPeripheral.writeValue(data, for: writeCharacteristic!, type: writeType)
            return true
        }
        return false
    }
    
    @discardableResult
    func sendBytesToDevice(_ bytes: [UInt8]) -> Bool
    {
        guard transmitEnabled,
              let connectedPeripheral = connectedPeripheral else { return false  }

        let data = Data(bytes: bytes, count: bytes.count)
        connectedPeripheral.writeValue(data, for: writeCharacteristic!, type: writeType)
        commandHistory.append("Sent Raw \(bytes.count) bytes", direction: .tx)

        return true
    }
    
    @discardableResult
    func sendDataToDevice(_ data: Data) -> Bool
    {
        guard transmitEnabled,
              let connectedPeripheral = connectedPeripheral else { return false  }

        connectedPeripheral.writeValue(data, for: writeCharacteristic!, type: writeType)
        commandHistory.append("Sent Data \(data.count) bytes", direction: .tx)

        return true
    }

    
    // MARK: CBCentralManagerDelegate

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber)
    {
        connectionManager.serialDidDiscoverPeripheral(peripheral, rssi: RSSI.floatValue)
        discoveredPeripherals[peripheral.identifier] = peripheral
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral)
    {
        peripheral.delegate = self
        pendingPeripheral = peripheral
        connectedPeripheral = nil

        // Okay, the peripheral is connected but we're not ready yet!
        // First get the 0xFFE0 service
        // Then get the 0xFFE1 characteristic of this service
        // Subscribe to it & create a weak reference to it (for writing later on), 
        // and find out the writeType by looking at characteristic.properties.
        // Only then we're ready for communication

        peripheral.discoverServices([serviceUUID])
        peripheral.readRSSI()
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?)
    {
        connectedPeripheral = nil
        pendingPeripheral = nil
        signalStrength = 0.0
        transmitEnabled = false

        connectionManager.serialDidDisconnect(peripheral.identifier, error: error as NSError?)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral:
                        CBPeripheral, error: Error?)
    {
        pendingPeripheral = nil
        connectedPeripheral = nil
        connectionManager.serialDidFailToConnect(peripheral.identifier, error: error as NSError?)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if central.state == .poweredOff {
            connectedPeripheral = nil
            pendingPeripheral = nil
            signalStrength = 0.0
        }
        connectionManager.serialDidChangeState(central.state)
    }
    
    
    // MARK: CBPeripheralDelegate functions
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?)
    {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                writeCharacteristic = characteristic
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                transmitEnabled = true
             }
        }
        
        // A device is not completely connected until we've discovered all of it's characteristics
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        connectionManager.serialDidConnect(peripheral.identifier)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral,
                    didReadRSSI RSSI:NSNumber,
                    error: Error?)
    {
        connectionManager.serialDidReadRSSI(peripheral.identifier, rssi: RSSI)
        
        if peripheral == self.connectedPeripheral {
            signalStrength = RSSI.floatValue
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        guard let data = characteristic.value else {
            return
        }
        commandParser.serialDidReceiveData(data)
    }

}


extension BluetoothSerial: PeripheralScanner {
    /// Scan  for peripherals
    func startScan()
    {
        self.discoveredPeripherals = [:]
        guard centralManager.state == .poweredOn else { return }
        Task {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connectToPeripheral(_ peripheralID: UUID)
    {
        disconnect()
        if let peripheral = discoveredPeripherals[peripheralID] {
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func disconnect()
    {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        
        pendingPeripheral = nil
        connectedPeripheral = nil
        writeCharacteristic = nil
    }
}

