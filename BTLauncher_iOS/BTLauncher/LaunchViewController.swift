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
import AVFoundation

class LaunchViewController : UIViewController, AVCaptureFileOutputRecordingDelegate
{
    @IBOutlet weak var viewFinderContainer: UIView!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var validationStatusLabel: UILabel!
    @IBOutlet weak var signalLabel: UILabel!
    @IBOutlet weak var voltageLabel: UILabel!
    @IBOutlet weak var highVoltageLabel: UILabel!

    @IBOutlet weak var armButton: UIButton!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var ctyButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pingButton: UIButton!
    @IBOutlet weak var validateButton: UIBarButtonItem!

    @IBOutlet var roundedViews: [UIView]!

    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var continuityIndicator: UIView!

    private var observers = [NSKeyValueObservation]()

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice : AVCaptureDevice?
    private var audioDevice : AVCaptureDevice?

    private var movieOutput = AVCaptureMovieFileOutput()

    private var recording : Bool = false
    private var recordingReady : Bool = false
    private var savingDialog : UIAlertController?

    override func viewDidLoad()
    {
        self.title = "Fire Control"
        self.connectionStatusLabel.text = "Not Connected"
        self.validationStatusLabel.text = "Not Validated"
        self.signalLabel.text = "No Signal"

        self.armButton.isEnabled = LaunchController.shared().validated;
        stopButton.isHidden = true
        recordingLabel.isHidden = true
        fireButton.isHidden = true
        continuityIndicator.isHidden = true

        roundedViews.forEach { (button) in
            button.clipsToBounds = true
            button.layer.cornerRadius = 5.0
        }

        continuityIndicator.clipsToBounds = true
        continuityIndicator.layer.cornerRadius = 24

        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                AVCaptureDevice.requestAccess(for: AVMediaType.audio) { response in
                    DispatchQueue.main.async {
                        self.startCamera()
                    }
                }
            }
        }

        startObservers()
    }

    private func startObservers()
    {
        let rssi = LaunchController.shared().rssi
        self.signalLabel.text = "Signal: \(rssi)"

        let batteryLevel = LaunchController.shared().batteryLevel
        self.voltageLabel.text = "LV Batt: \(batteryLevel)v"

        let hvBatteryLevel = LaunchController.shared().hvBatteryLevel
        self.highVoltageLabel.text = "HV Batt: \(hvBatteryLevel)v"

        self.observers = [
            LaunchController.shared().observe(\LaunchController.connected, options: [.new]) {
                [unowned self] (_,_) in
                let connected = LaunchController.shared().connected
                self.connectionStatusLabel.text =  connected ? "Connected" : "Not Connected"
                self.connectionStatusLabel.backgroundColor = connected ? .green : .red
            },

            LaunchController.shared().observe(\LaunchController.validated, options: [.new]) {
                [unowned self] (_,_) in
                let validated = LaunchController.shared().validated
                self.validationStatusLabel.text = validated ? "Validated" : "Not Validated"
                self.validationStatusLabel.backgroundColor = validated ? .green : .red
                self.armButton.isEnabled = validated;
            },

            LaunchController.shared().observe(\LaunchController.continuity, options: [.new]) {
                [unowned self] (_,_) in
                self.continuityIndicator.isHidden = !LaunchController.shared().continuity
            },

            LaunchController.shared().observe(\LaunchController.rssi, options: [.new]) {
                [unowned self] (_,_) in
                let rssi = LaunchController.shared().rssi
                self.signalLabel.text = "Signal: \(rssi)"
            },

            LaunchController.shared().observe(\LaunchController.batteryLevel, options: [.new]) {
                [unowned self] (_,_) in
                let batteryLevel = LaunchController.shared().batteryLevel
                self.voltageLabel.text = "LV Batt: \(batteryLevel)v"
            },

            LaunchController.shared().observe(\LaunchController.hvBatteryLevel, options: [.new]) {
                [unowned self] (_,_) in
                let batteryLevel = LaunchController.shared().hvBatteryLevel
                self.highVoltageLabel.text = "HV Batt: \(batteryLevel)v"
            }
        ]
    }

    private func startCamera()
    {
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video),
              let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
         else {
            recordingLabel.isHidden = false
            recordingLabel.text = "Recording Disabled:\nNo Camera"
            NSLog("No camera device")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)

            captureSession = AVCaptureSession()
            if let captureSession = captureSession {
                captureSession.addInput(input)
                captureSession.addInput(audioInput)
                captureSession.addOutput(movieOutput)

                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer?.frame = viewFinderContainer.layer.bounds
                viewFinderContainer.layer.addSublayer(videoPreviewLayer!)
                captureSession.startRunning()
                recordingReady = true
            }
        } catch {
            print(error)
        }
    }

    private func setRecording(_ recording: Bool)
    {
        if(LocalSettings.settings.autoRecord == false)
        {
            return
        }

        stopButton.isHidden = !recording
        recordingLabel.isHidden = !recording
        
        if(recording == self.recording) {
            return
        }

        self.recording = recording

        if(!recording) {
            recordingReady  = false
            movieOutput.stopRecording()
            //savingDialog = UIAlertController.init(title: "Saving Video...", message: nil, preferredStyle: .alert)
            //self.present(savingDialog!, animated: true, completion: nil)
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl,
                                       recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?)
    {
        if let d = savingDialog {
            d.dismiss(animated: false, completion: nil)
        }
        if(error == nil) {
            DispatchQueue.main.async {
                let ac = UIAlertController.init(title: "Save", message: "Save Video", preferredStyle: .alert)
                let saveAction = UIAlertAction.init(title: "Save", style: .default) { (action) in
                    UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
                    self.recordingReady = true
                }
                let cancelAciton = UIAlertAction.init(title: "Cancel", style: .default) { _ in
                    self.recording = true
                }

                ac.addAction(saveAction)
                ac.addAction(cancelAciton)
                self.present(ac, animated: true, completion: nil)
            }
        }
    }


     @IBAction func armTouchDown(_ sender: Any)
     {
        if(LaunchController.shared().connected && LaunchController.shared().validated) {
            LaunchController.shared().armed = true
            fireButton.isHidden = false
            ctyButton.isHidden = true
            pingButton.isHidden = true
            setRecording(true)
        }
    }

    @IBAction func armTouchCancel(_ sender: Any)
    {
        LaunchController.shared().armed = false
        fireButton.isHidden = true
        ctyButton.isHidden = false
        pingButton.isHidden = false
    }

    @IBAction func fireTouchDown(_ sender: Any) {
        LaunchController.shared().sendFireCommand(true)
    }

    @IBAction func fireTouchUp(_ sender: Any) {
        LaunchController.shared().sendFireCommand(false)
    }

    @IBAction func stopPressed(_ sender: Any) {
        setRecording(false)
    }

    @IBAction func continuityOn(_ sender: Any) {
        LaunchController.shared().sendContinuityCommand(true)
    }

    @IBAction func continuityOff(_ sender: Any) {
        LaunchController.shared().sendContinuityCommand(false)
    }

    @IBAction func validatePressed(_ sender: Any) {
        LaunchController.shared().sendValidationCommand()
    }

    @IBAction func pingPressed(_ sender: Any) {
        LaunchController.shared().pingConnectedDevice()
    }
}
