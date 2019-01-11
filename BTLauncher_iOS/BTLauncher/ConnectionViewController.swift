//
//  ConnectionViewController.swift
//  BTLauncher
//
//  Created by Jonathan Nobels on 2019-01-10.
//  Copyright © 2019 Jonathan Nobels. All rights reserved.
//

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
        BluetoothSerial.shared().connectionDelegate = self;
        BluetoothSerial.shared().startScan()
    }

    @IBAction func scanPressed(_ sender: Any) {
        BluetoothSerial.shared().startScan()
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
        let connected = BluetoothSerial.shared().connectedPeripheral == peripheral.peripheral;
        cell.accessoryView?.isHidden = !connected;

        return cell;
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
        LaunchController.shared().connected = false;
        tableView.reloadData()
    }

    func serialDidConnect(_ peripheral: CBPeripheral) {
        LaunchController.shared().connected = true;
        tableView.reloadData()
    }

}
