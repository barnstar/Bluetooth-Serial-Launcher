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
import Combine

class LaunchViewController : UIViewController
{
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var validationStatusLabel: UILabel!
    @IBOutlet weak var signalLabel: UILabel!
    @IBOutlet weak var voltageLabel: UILabel!
    @IBOutlet weak var highVoltageLabel: UILabel!

    @IBOutlet weak var armButton: UISwitch!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var ctyButton: UIButton!
    @IBOutlet weak var pingButton: UIButton!
    @IBOutlet var validateButton: UIBarButtonItem!

    @IBOutlet var roundedViews: [UIView]!

    @IBOutlet weak var continuityIndicator: UIView!

    private var subscribers: [AnyCancellable] = []
    
    var launchController: LaunchController!

    override func viewDidLoad()
    {
        launchController = LaunchController.shared()
        
        title = "Launch Control"
        connectionStatusLabel.text = "Not Connected"
        validationStatusLabel.text = "Not Validated"
        signalLabel.text = "No Signal"
    }

    override func viewWillAppear(_ animated: Bool) {
        armButton.isEnabled = LaunchController.shared().validated;
        fireButton.isHidden = true

        roundedViews.forEach { (button) in
            button.clipsToBounds = true
            button.layer.cornerRadius = 5.0
        }

        continuityIndicator.clipsToBounds = true
        continuityIndicator.layer.cornerRadius = 5.0
        continuityIndicator.isHidden = true

        startObservers()
        
        let connected = launchController.btConnections.connected
        if connected,
           false == launchController.validated {
            launchController.sendValidationCommand()
        }
    }
    
    private func startObservers()
    {
        subscribers.removeAll()
        
        launchController.btConnections.$connected
            .receive(on: DispatchQueue.main)
            .map( {$0 ? "Connected" : "Not Connected" })
            .assign(to: \.text, on: connectionStatusLabel)
            .store(in: &subscribers)
        
        launchController.btConnections.$connected
            .receive(on: DispatchQueue.main)
            .map( {$0 ? .green : .red } )
            .assign(to: \.backgroundColor, on: connectionStatusLabel)
            .store(in: &subscribers)
        
        launchController.$validated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: armButton)
            .store(in: &subscribers)

        launchController.$validated
            .receive(on: DispatchQueue.main)
            .map { $0 ? "Validated" : "Not Validated" }
            .assign(to: \.text, on: validationStatusLabel)
            .store(in: &subscribers)
        
        launchController.$validated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in
                guard let self = self else { return }
                switch val {
                case false: self.navigationController?.navigationBar.topItem?.setRightBarButton(validateButton, animated: true)
                case true: self.navigationController?.navigationBar.topItem?.setRightBarButton(nil, animated: true)
                }
            }
            .store(in: &subscribers)
      
        launchController.$validated
            .receive(on: DispatchQueue.main)
            .map {$0 ? .green : .red }
            .assign(to: \.backgroundColor, on: validationStatusLabel)
            .store(in: &subscribers)
        
        launchController.$continuity
            .receive(on: DispatchQueue.main)
            .map { !$0 }
            .assign(to: \.isHidden, on: continuityIndicator)
            .store(in: &subscribers)
        
        launchController.btController.$signalLevel
            .receive(on: DispatchQueue.main)
            .map {"Signal: \($0)" }
            .assign(to: \.text, on: signalLabel)
            .store(in: &subscribers)
        
        launchController.$batteryLevel
            .receive(on: DispatchQueue.main)
            .map {"LV Batt: \($0)" }
            .assign(to: \.text, on: voltageLabel)
            .store(in: &subscribers)
           
        launchController.$hvBatteryLevel
            .receive(on: DispatchQueue.main)
            .map {"HV Batt: \($0)" }
            .assign(to: \.text, on: highVoltageLabel)
            .store(in: &subscribers)
        
        launchController.$armed
            .receive(on: DispatchQueue.main)
            .filter({ $0 == true })
            .sink { [weak self] armed in
                self?.fireButton.isHidden = false
                self?.ctyButton.isHidden = true
                self?.pingButton.isHidden = true
            }.store(in: &subscribers)
        
        launchController.$armed
            .receive(on: DispatchQueue.main)
            .filter({ $0 == false })
            .sink { [weak self] armd in
                self?.fireButton.isHidden = true
                self?.ctyButton.isHidden = false
                self?.pingButton.isHidden = false
            }.store(in: &subscribers)
        
        
    }
  
    @IBAction func armToggled(_ sender: UISwitch) {
        launchController.setArmed(sender.isOn)
    }

    @IBAction func fireTouchDown(_ sender: Any) {
        launchController.sendFireCommand(true)
    }

    @IBAction func fireTouchUp(_ sender: Any) {
        launchController.sendFireCommand(false)
    }

    @IBAction func continuityOn(_ sender: Any) {
        launchController.sendContinuityCommand(true)
    }

    @IBAction func continuityOff(_ sender: Any) {
        launchController.sendContinuityCommand(false)
    }

    @IBAction func validatePressed(_ sender: Any) {
        launchController.sendValidationCommand()
    }

    @IBAction func pingPressed(_ sender: Any) {
        launchController.pingConnectedDevice()
        launchController.sendCheckVoltage()
    }
}
