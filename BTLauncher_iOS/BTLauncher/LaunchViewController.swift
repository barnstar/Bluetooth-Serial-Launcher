
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

    @IBOutlet weak var armButton: UIButton!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var ctyButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pingButton: UIButton!
    @IBOutlet weak var validateButton: UIBarButtonItem!

    @IBOutlet var roundedViews: [UIView]!

    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var continuityIndicator: UIView!

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var audioDevice : AVCaptureDevice?

    var observers = [NSKeyValueObservation]()
    var movieOutput = AVCaptureMovieFileOutput()

    var recording : Bool = false
    var recordingReady : Bool = false
    var savingDialog : UIAlertController?

    override func viewDidLoad()
    {
        self.title = "Fire Control"
        self.connectionStatusLabel.text = "Not Connected"

        stopButton.isHidden = true
        recordingLabel.isHidden = true
        fireButton.isHidden = true
        continuityIndicator.isHidden = true;

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
        updateConnectionStatusLabel()
    }

    func startCamera()
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

    func setRecording(_ recording: Bool) {
        if(nil == captureSession ||
            nil == captureDevice ||
            LocalSettings.settings.autoRecord == false)
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
        }else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
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

    func updateConnectionStatusLabel()
    {
        let connected = LaunchController.shared().connected
        let validated = LaunchController.shared().validated
        let vString = validated ? "Validated" : "Not Validated"
        if(connected) {
            self.connectionStatusLabel.text = "Connected & " + vString
            self.connectionStatusLabel.textColor = validated ? .green : .red
        }else{
            self.connectionStatusLabel.text = ":: Not Connected ::"
            self.connectionStatusLabel.textColor = .red
        }

        if(validated) {
            self.navigationItem.rightBarButtonItem = nil;
        }else{
            self.navigationItem.rightBarButtonItem = validateButton;
        }
    }

    func startObservers()
    {
        self.observers = [
            LaunchController.shared().observe(\LaunchController.connected, options: [.new]) {
                [weak self] (_,_) in
                self?.updateConnectionStatusLabel()
            },

            LaunchController.shared().observe(\LaunchController.validated, options: [.new]) {
                [weak self] (_,_) in
                self?.updateConnectionStatusLabel()
            },

            LaunchController.shared().observe(\LaunchController.continuity, options: [.new]) {
                [weak self] (_,_) in
                self?.continuityIndicator.isHidden = !LaunchController.shared().continuity;
            },
        ]
    }

    @IBAction func armTouchDown(_ sender: Any) {
        LaunchController.shared().armed = true
        fireButton.isHidden = false
        ctyButton.isHidden = true
        pingButton.isHidden = true;
        setRecording(true)
    }

    @IBAction func armTouchCancel(_ sender: Any) {
        LaunchController.shared().armed = false
        fireButton.isHidden = true
        ctyButton.isHidden = false
        pingButton.isHidden = false;
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
