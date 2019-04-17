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
 * 
 * Modified from: https://github.com/hoiberg/HM10-BluetoothSerial-iOS
 **********************************************************************************/

import UIKit
import CoreBluetooth

protocol BluetoothSerialDelegate
{
    func serialDidReceiveString(_ message: String)
    func serialDidReceiveBytes(_ bytes: [UInt8])
    func serialDidReceiveData(_ data: Data)
    func serialDidReadRSSI(_ rssi: NSNumber)
    func serialIsReady(_ peripheral: CBPeripheral)
}

protocol BluetoothConnectionDelegate
{
    func serialDidChangeState()
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?)
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?)
    func serialDidConnect(_ peripheral: CBPeripheral)
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?)
    func serialDidReadRSSI(_ rssi: NSNumber)
}

extension BluetoothSerialDelegate
{
    func serialDidReceiveString(_ message: String) {}
    func serialDidReceiveBytes(_ bytes: [UInt8]) {}
    func serialDidReceiveData(_ data: Data) {}
    func serialDidReadRSSI(_ rssi: NSNumber) {}
    func serialIsReady(_ peripheral: CBPeripheral) {}
}

extension BluetoothConnectionDelegate 
{
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnect(_ peripheral: CBPeripheral) {}
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {}
    func serialDidReadRSSI(_ rssi: NSNumber) {}
}

final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate 
{
    private static let serial : BluetoothSerial = {
        let instance = BluetoothSerial()
        instance.centralManager = CBCentralManager(delegate: instance, queue: nil)
        return instance
    }()

    class func shared() -> BluetoothSerial {
        return serial
    }

    var delegate: BluetoothSerialDelegate!
    var connectionDelegate : BluetoothConnectionDelegate!
    var centralManager: CBCentralManager!
    var pendingPeripheral: CBPeripheral?
    var connectedPeripheral: CBPeripheral?
    weak var writeCharacteristic: CBCharacteristic?
    
    var isReady: Bool {
        get {
            return centralManager.state == .poweredOn &&
                   connectedPeripheral != nil &&
                   writeCharacteristic != nil
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


    /// Start  for peripherals
    func startScan()
    {
        guard centralManager.state == .poweredOn else { return }
        
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        for peripheral in peripherals {
            connectionDelegate.serialDidDiscoverPeripheral(peripheral, RSSI: nil)
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connectToPeripheral(_ peripheral: CBPeripheral)
    {
        disconnect()
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    

    func disconnect()
    {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p) 
        }

        pendingPeripheral = nil
        connectedPeripheral = nil
    }
    
    func readRSSI()
    {
        guard isReady else { return }
        connectedPeripheral!.readRSSI()
    }
    
    func sendMessageToDevice(_ message: String)
    {
        NSLog("Sending message: \(message)")
        guard isReady else { return }

        if let data = message.data(using: String.Encoding.utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
        }
    }
    
    func sendBytesToDevice(_ bytes: [UInt8]) 
    {
        guard isReady else { return }
        
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    func sendDataToDevice(_ data: Data) 
    {
        guard isReady else { return }
        
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    
    // MARK: CBCentralManagerDelegate

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        connectionDelegate.serialDidDiscoverPeripheral(peripheral, RSSI: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral)
    {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        connectionDelegate.serialDidConnect(peripheral)

        // Okay, the peripheral is connected but we're not ready yet!
        // First get the 0xFFE0 service
        // Then get the 0xFFE1 characteristic of this service
        // Subscribe to it & create a weak reference to it (for writing later on), 
        // and find out the writeType by looking at characteristic.properties.
        // Only then we're ready for communication

        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?)
    {
        connectedPeripheral = nil
        pendingPeripheral = nil
        connectionDelegate.serialDidDisconnect(peripheral, error: error as NSError?)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral:
        CBPeripheral, error: Error?)
    {
        pendingPeripheral = nil
        connectionDelegate.serialDidFailToConnect(peripheral, error: error as NSError?)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        connectedPeripheral = nil
        pendingPeripheral = nil
        connectionDelegate.serialDidChangeState()
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
                    error: Error?)
                     {
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                writeCharacteristic = characteristic
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                delegate.serialIsReady(peripheral)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        let data = characteristic.value
        guard data != nil else { return }

        if let str = String(data: data!, encoding: String.Encoding.utf8) {
            delegate.serialDidReceiveString(str)
        } else {
            //print("Received an invalid string!") uncomment for debugging
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didReadRSSI RSSI:
        NSNumber, error: Error?)
    {
        connectionDelegate.serialDidReadRSSI(RSSI)
        delegate.serialDidReadRSSI(RSSI)
    }
}
