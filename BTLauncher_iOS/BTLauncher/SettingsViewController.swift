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

class SettingsViewController : UIViewController, UITextFieldDelegate
{
    @IBOutlet weak var validationCodeField: UITextField!
    @IBOutlet weak var autoRecordSwitch: UISwitch!
    @IBOutlet weak var updateButton: UIButton!

    var observers = [NSKeyValueObservation]()
    var lastCode : String?

    override func viewDidLoad() {
        self.title = "Settings"
        validationCodeField.text = LocalSettings.settings.validationCode
        autoRecordSwitch.setOn(LocalSettings.settings.autoRecord, animated: false)
        self.updateButton.isHidden = !LaunchController.shared().validated

        startObservers()
    }

    private func startObservers() {
        self.observers = [
            LaunchController.shared().observe(\LaunchController.validated, options: [.new]) {
                [unowned self] (_,_) in
                self.updateButton.isHidden = !LaunchController.shared().validated
            }
        ]
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let code = textField.text else {
            return
        }

        if(code.count == PIN_LEN) {
            LocalSettings.settings.validationCode = code
        }else{
            textField.text = LocalSettings.settings.validationCode
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let oldVal = textField.text {
            if let r = Range(range, in: oldVal) {
                let newVal = oldVal.replacingCharacters(in: r, with: string)
                return newVal.count <= 4
            }
        }
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func autoRecordChanged(_ sender: UISwitch) {
        LocalSettings.settings.autoRecord = sender.isOn
    }

    @IBAction func setCodePressed(_ sender: Any)
    {
        validationCodeField.resignFirstResponder()
        
        //Prevent button mashing
        if let last = lastCode {
            if(last == LocalSettings.settings.validationCode) {
                return
            }
        }

        let code = "New Code: " + LocalSettings.settings.validationCode
        let ac = UIAlertController(title: "Update Validation Code?", message: code, preferredStyle: .alert)
        let update = UIAlertAction(title: "Update", style: .destructive) { _ in
            LaunchController.shared().sendSetValidationCodeCommand(LocalSettings.settings.validationCode) {
                let ac = UIAlertController(title: "Code Updated", message: nil, preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                ac.addAction(ok)
                self.present(ac, animated: true, completion: nil)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(update)
        ac.addAction(cancel)
        self.present(ac, animated: true, completion: nil)
        lastCode = LocalSettings.settings.validationCode
    }
}

