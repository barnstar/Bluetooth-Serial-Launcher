//
//  LocalSettings.swift
//  BTLauncher
//
//  Created by Jonathan Nobels on 2019-01-11.
//  Copyright © 2019 Jonathan Nobels. All rights reserved.
//

import Foundation

class LocalSettings
{
    static let settings : LocalSettings = {
        let instance = LocalSettings()
        return instance
    }()

    private let kValidationCodeKey = "ValidationCode"
    private let kVideoKey = "RecordVideo"

    init() {
        validationCode = UserDefaults.standard.value(forKey: kValidationCodeKey) as? String
        if(nil == validationCode) {
            //Set to the hard coded value.
            validationCode = VCODE
        }

        autoRecord = UserDefaults.standard.value(forKey: kVideoKey) as? Bool
        if(nil == autoRecord) {
            //Set to the hard coded value.
            autoRecord = true
        }
    }

    var autoRecord : Bool! {
        didSet {
            UserDefaults.standard.set(autoRecord, forKey: kVideoKey)
        }
    }

    var validationCode : String! {
        didSet {
            UserDefaults.standard.set(validationCode, forKey: kValidationCodeKey)
        }
    }

}
