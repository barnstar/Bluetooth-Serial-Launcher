//
//  LaunchController.swift
//  BTLauncher
//
//  Created by Jonathan Nobels on 2019-01-10.
//  Copyright © 2019 Jonathan Nobels. All rights reserved.
//

import Foundation
import CoreBluetooth

class LaunchController : NSObject, BluetoothSerialDelegate
{
    @objc dynamic var armed : Bool = false {
        didSet {
            if(armed) {
                BluetoothSerial.shared().sendMessageToDevice(":ARM_ON:")
            }   else  {
                BluetoothSerial.shared().sendMessageToDevice(":ARM_OFF:")
            }
        }
    }

    @objc dynamic var connected : Bool = false {
        didSet {
            if(connected) {
                BluetoothSerial.shared().sendMessageToDevice(":PING:")
            }  
        }
    }

    private static let instance : LaunchController = {
        let instance = LaunchController()
        instance.armed = false;
        BluetoothSerial.shared().delegate = instance;
        return instance
    }()

    class func shared() -> LaunchController {
        return instance
    }

    public func sendLaunchCommand(_ enable: Bool) {
        if(armed && enable) {
            NSLog("Launch Sent")
            BluetoothSerial.shared().sendMessageToDevice(":FIRE_ON:")
        }else if(!enable) {
            BluetoothSerial.shared().sendMessageToDevice(":FIRE_OFF:")
        }else{
            NSLog("Not Armed");
        }
    }

    public func sendContinuityComman(_ enable: Bool) {
        if(enable) {
            NSLog("Continuity On Sent")
            BluetoothSerial.shared().sendMessageToDevice(":CTEST_ON:")
        }else{
            NSLog("Continuity Off Sent");
            BluetoothSerial.shared().sendMessageToDevice(":CTEST_OFF:")
        }
    }
}
