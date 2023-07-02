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

/// The duration for which we'll scan for peripherals
let maxScanTime: Duration = .seconds(5.0)


/// Listens for Bluetooth connection and discovery events and updates
/// the view model
class BTConnectionManager: ObservableObject
{
    /// List of discovered peripherals
    @Published var peripherals: [PeripheralViewModel] = []
    @Published var scanning =  false

    weak var scanner: PeripheralScanner?
    
    var scanTask: Task<Void, Never>? {
        didSet {
            Task { @MainActor in
                scanning = (scanTask != nil)
            }
        }
    }
    
    init(_ scanner: PeripheralScanner?) {
        self.scanner = scanner
    }
    
    func startScan() {
        guard scanTask == nil else { return }
        
        peripherals.removeAll()
        scanner?.startScan()
        
        scanTask = Task {
            defer {
                scanTask = nil
            }
            try? await Task.sleep(for: maxScanTime)
            scanner?.stopScan()
        }
    }
    
    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
        scanner?.stopScan()
    }

    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, rssi: Float)
    {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheralID == peripheral.identifier { return }
        }

        let model = PeripheralViewModel(
            name: peripheral.name ?? "(Unnamed)",
            rssi: rssi,
            state: .disconnected,
            peripheralID: peripheral.identifier)

        peripherals.append(model)
    }

    func serialDidChangeState(_ state: CBManagerState) {
        if state == .poweredOff {
            peripherals = []
            stopScan()
        }
    }
    
    func connectToPeripheral(_ peripheralID: UUID) {
        print("Connecting to \(peripheralID)")
        for viewModel in peripherals where viewModel.peripheralID == peripheralID {
            viewModel.connectionState = .pending
        }
        scanner?.connectToPeripheral(peripheralID)
    }

    func serialDidDisconnect(_ peripheralID: UUID, error: NSError?)
    {
        for viewModel in peripherals where viewModel.peripheralID == peripheralID {
            viewModel.connectionState = .disconnected
        }
    }

    func serialDidConnect(_ peripheralID: UUID)
    {
        for viewModel in peripherals where viewModel.peripheralID == peripheralID {
            viewModel.connectionState = .connected
        }
    }
    
    func serialDidReadRSSI(_ peripheralID: UUID, rssi: NSNumber) {
        for viewModel in peripherals where viewModel.peripheralID == peripheralID{
            viewModel.rssi = "\(rssi.floatValue)"
        }
    }
    
    func serialDidFailToConnect(_ peripheralID: UUID, error: NSError?)
    {
        for viewModel in peripherals where viewModel.peripheralID == peripheralID {
            viewModel.connectionState = .disconnected
        }
    }   
}
