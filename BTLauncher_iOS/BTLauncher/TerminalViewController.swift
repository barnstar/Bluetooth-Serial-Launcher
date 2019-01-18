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

class TerminalViewController : UIViewController, UITextFieldDelegate, TerminalDelegate
{
    @IBOutlet weak var terminalTextView: UITextView!
    @IBOutlet weak var sendField: UITextField!
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint!

    private var observers = [NSKeyValueObservation]()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        self.title = "Terminal"
        LaunchController.shared().terminalDelegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    //MARK:- Actions

    @IBAction func sendPressed(_ sender: Any) {
        if let sendText = sendField.text {
            LaunchController.shared().sendCommand(sendText);
        }
        sendField.text = ""
    }

    @IBAction func clearPressed(_ sender: Any) {
        terminalTextView.text = "---  Cleared ---\n\n"
    }

    @IBAction func tap(_ sender: Any) {
        sendField.resignFirstResponder()
    }

    @objc func keyboardNotification(notification: NSNotification)
    {
        if let userInfo = notification.userInfo
        {
            guard let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else{
                return;
            }

            let keyboardFrameInView = view.convert(endFrame, from: nil)
            let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
            let intersection = safeAreaFrame.intersection(keyboardFrameInView)

            let endFrameY = endFrame.origin.y
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)

            if endFrameY >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint.constant = 4.0
            } else {
                self.keyboardHeightLayoutConstraint.constant = intersection.size.height + 4.0
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: { [unowned self] (_) in
                                self.scrollToBottom()
                            });
        }
    }

    private func scrollToBottom()
    {
        let size = self.terminalTextView.contentSize.height
        let height = self.terminalTextView.bounds.size.height
        if(size > height) {
            let bottom = CGPoint(x: 0, y: size - height)
            self.terminalTextView.setContentOffset(bottom, animated: false)
        }
    }


    //MARK:- Text Field Delegate

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        if (string.rangeOfCharacter(from: .newlines) != nil) {
            sendPressed(self)
        }
        return true
    }

    //MARK:- Terminal Delegate

    func appendString(_ string: String)
    {
        terminalTextView.insertText(string);
        scrollToBottom()
    }

}
