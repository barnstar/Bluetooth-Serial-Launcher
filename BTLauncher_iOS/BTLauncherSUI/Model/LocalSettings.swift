/*********************************************************************************
 * BT Launcher
 *
 * Launch your stuff with the bluetooths.
 *
 * Copyright 2023, Jonathan Nobels
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


import Foundation

class LocalSettings
{
    static let settings : LocalSettings = {
        let instance = LocalSettings()
        return instance
    }()

    private let kValidationCodeKey = "ValidationCode"

    init() {
        validationCode = UserDefaults.standard.value(forKey: kValidationCodeKey) as? String
        if(nil == validationCode) {
            //Set to the hard coded value.
            validationCode = VCODE
        }
    }

    public var validationCode : String! {
        didSet {
            UserDefaults.standard.set(validationCode, forKey: kValidationCodeKey)
        }
    }

}
