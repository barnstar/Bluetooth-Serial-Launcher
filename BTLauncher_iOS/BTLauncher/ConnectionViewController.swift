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


import UIKit
import CoreBluetooth
import Combine

class ConnectionCell : UITableViewCell
{
    @IBOutlet var RSSILabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
}


class ConnectionViewController :
    UIViewController,
    UITableViewDelegate,
    UITableViewDataSource
{
    
    @IBOutlet weak var tableView: UITableView!

    var subcribers = [AnyCancellable]()
    var controller = LaunchController.shared().btConnections

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        subcribers.removeAll()
        controller.$peripherals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }.store(in: &subcribers)
        
        controller.$scanning
            .receive(on: DispatchQueue.main)
            .sink{ scanning in
                self.title = scanning ? "Scanning..." : "Connect"
            }.store(in: &subcribers)
        
        controller.$connected
            .receive(on: DispatchQueue.main)
            .sink { [weak self ] _ in
                self?.tableView.reloadData()
            }.store(in: &subcribers)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if false == self?.controller.scanning,
               false == self?.controller.connected {
                self?.controller.startScan()
            }
        }
    }

    @IBAction func scanPressed(_ sender: Any)
    {
        switch controller.scanning {
        case false: controller.startScan()
        case true: controller.stopScan()
        }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let controller = LaunchController.shared().btConnections
        return controller.peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell : ConnectionCell = tableView.dequeueReusableCell(withIdentifier: "connCell", for:indexPath) as! ConnectionCell
        
        let peripheral = controller.peripherals[indexPath.row]
        
        cell.nameLabel.text = peripheral.peripheral.name
        cell.RSSILabel.text = "\(peripheral.RSSI) dBm"
        let connected = controller.btSerial.connectedPeripheral == peripheral.peripheral
        cell.accessoryType = connected ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        controller.stopScan()
        let peripheral = controller.peripherals[indexPath.row].peripheral
        controller.connectToPeripheral(peripheral)
    }
}

