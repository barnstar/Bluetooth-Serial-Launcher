//
//  LaunchViewController.swift
//  BTLauncher
//
//  Created by Jonathan Nobels on 2019-01-10.
//  Copyright © 2019 Jonathan Nobels. All rights reserved.
//

import UIKit
import AVFoundation

class LaunchViewController : UIViewController, AVCaptureFileOutputRecordingDelegate
{
    @IBOutlet weak var viewFinderContainer: UIView!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var launcherStatusLabel: UILabel!

    @IBOutlet weak var armButton: UIButton!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var audioDevice : AVCaptureDevice?

    var observers = [NSKeyValueObservation]()
    var movieOutput = AVCaptureMovieFileOutput()

    var recording : Bool = false;
    var recordingReady : Bool = false;
    var savingDialog : UIAlertController?

    override func viewDidLoad()
    {
        self.connectionStatusLabel.text = "Not Connected"
        startObservers()
        LaunchController.shared().armed = false
        stopButton.isHidden = true;
        recordingLabel.isHidden = true;

        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                AVCaptureDevice.requestAccess(for: AVMediaType.audio) { response in
                    DispatchQueue.main.async {
                        self.startCamera()
                    }
                }
            }
        }
    }

    func startCamera()
    {
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video),
              let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
         else {
            NSLog("No camera device");
            return;
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
                recordingReady = true;
            }
        } catch {
            print(error)
        }
    }

    func setRecording(_ recording: Bool) {
        stopButton.isHidden = !recording
        recordingLabel.isHidden = !recording
        
        if(recording == self.recording) {
            return;
        }

        self.recording = recording;

        if(!recording) {
            recordingReady  = false;
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
            d.dismiss(animated: false, completion: nil);
        }
        if(error == nil) {
            DispatchQueue.main.async {
                let ac = UIAlertController.init(title: "Save", message: "Save Video", preferredStyle: .alert)
                let saveAction = UIAlertAction.init(title: "Save", style: .default) { (action) in
                    UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
                    self.recordingReady = true;
                }
                let cancelAciton = UIAlertAction.init(title: "Cancel", style: .default) { _ in
                    self.recording = true;
                }

                ac.addAction(saveAction)
                ac.addAction(cancelAciton)
                self.present(ac, animated: true, completion: nil)
            }
        }
    }

    func startObservers()
    {
        self.observers = [
            LaunchController.shared().observe(\LaunchController.connected, options: [.new]) {
                controller, change in
                let connected = controller.connected
                self.connectionStatusLabel.text = connected ? "Connected" : "Not Connected"
            },

            LaunchController.shared().observe(\LaunchController.armed, options: [.new]) {
                controller, change in
                let connected = controller.armed
                self.launcherStatusLabel.text = connected ? "Armed" : nil
                self.launcherStatusLabel.isHidden = !controller.armed;
            }
        ];
    }

    @IBAction func armTouchDown(_ sender: Any) {
        LaunchController.shared().armed = true
        fireButton.isEnabled = true
        setRecording(true)
    }

    @IBAction func armTouchCancel(_ sender: Any) {
        LaunchController.shared().armed = false
        fireButton.isEnabled = false;
    }

    @IBAction func fireTouchDown(_ sender: Any) {
        LaunchController.shared().sendLaunchCommand(true)
    }

    @IBAction func fireTouchUp(_ sender: Any) {
        LaunchController.shared().sendLaunchCommand(false)
    }

    @IBAction func stopPressed(_ sender: Any) {
        setRecording(false)
    }
}
