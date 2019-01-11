
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

class ConnectionCell : UITableViewCell
{
    @IBOutlet var RSSILabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
}


class ConnectionViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, BluetoothConnectionDelegate
{
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    @IBOutlet weak var tableView: UITableView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.title = "Connect"
        BluetoothSerial.shared().connectionDelegate = self
        self.scanPressed(self);
    }

    var scanning : Bool = false;
    @IBAction func scanPressed(_ sender: Any) {
        if(!scanning) {
            BluetoothSerial.shared().startScan()
            scanning = true;
            self.title = "Scanning..."
        }

        //Abort scan after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            BluetoothSerial.shared().stopScan()
            self.scanning = false;
            self.title = "Connect"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ConnectionCell = tableView.dequeueReusableCell(withIdentifier: "connCell", for:indexPath) as! ConnectionCell
        let peripheral = peripherals[indexPath.row]
        cell.nameLabel.text = peripheral.peripheral.name
        let rssi = peripheral.RSSI
        cell.RSSILabel.text = "\(rssi)"
        let connected = BluetoothSerial.shared().connectedPeripheral == peripheral.peripheral
        cell.accessoryType = connected ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripherals[indexPath.row].peripheral
        BluetoothSerial.shared().connectToPeripheral(peripheral)
    }

    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }

        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        peripherals.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }

    func serialDidChangeState() {
    }

    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        LaunchController.shared().connected = false
        tableView.reloadData()
    }

    func serialDidConnect(_ peripheral: CBPeripheral) {
        LaunchController.shared().connected = true
        LaunchController.shared().sendValidationCommand()
        tableView.reloadData()
    }

}
