//
//  Countdown.swift
//  BTLauncher
//
//  Created by Jonathan Nobels on 2019-01-30.
//  Copyright © 2019 Jonathan Nobels. All rights reserved.
//

import UIKit
import AVKit

protocol CountdownDelegate
{
    func countdownChanged(_ value: Int)
}

class Countdown : NSObject, AVSpeechSynthesizerDelegate
{
    var currentValue : Int = 0
    var startingValue : Int = 0
    var cancelled = false
    var speedMS = 0.0

    let synthesizer = AVSpeechSynthesizer()
    private var cdTimer : Timer!
    var delegate : CountdownDelegate!


    func startCountdown(_ value: Int, speedMS: Double)
    {
        synthesizer.delegate = self;
        self.speedMS = speedMS
        cancelled = false
        currentValue = value
        startingValue = value
        let utterance = AVSpeechUtterance(string: "Tee Minus")
        utterance.rate = 0.6
        synthesizer.speak(utterance)

        cdTimer = Timer.scheduledTimer(withTimeInterval: speedMS*0.001, repeats: true) {
            [unowned self] _ in
            if(self.currentValue == 0) {
                self.stopCountdown()
            }else{
                self.announceValue(self.currentValue)
            }

            self.currentValue = self.currentValue - 1;
        }
    }

    func stopCountdown()
    {
        cancelled = true;
        if let cdTimer = cdTimer {
            cdTimer.invalidate()
            self.cdTimer = nil
        }
        if let delegate = delegate {
            delegate.countdownChanged(0)
        }

        if(self.currentValue == 0){
            let utterance = AVSpeechUtterance(string: "Ignihshun!")
            utterance.rate = 0.6
            synthesizer.speak(utterance)
        }
        self.currentValue = 0
        self.startingValue = 0
    }

    func announceValue(_ value: Int)
    {
        let utterance = AVSpeechUtterance(string: "\(value)")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
        if let delegate = delegate {
            delegate.countdownChanged(value)
        }
    }

}
