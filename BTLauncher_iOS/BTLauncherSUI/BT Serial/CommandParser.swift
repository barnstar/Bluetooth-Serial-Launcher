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
import CoreBluetooth

class CommandParser: NSObject {

    private var responseBuffer : String = ""
    private var reading : Bool = false
    
    @Published var command: String?
       
    func serialDidReceiveData(_ data: Data)
    {
        guard let message = String(data: data, encoding: String.Encoding.utf8) else {
            return
        }

        var msg = message
                    .trimmingCharacters(in: .newlines)
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
         
        
        NSLog(">>> \(msg)")

        //First character is a command terminator, put us in reading mode
        if(msg.prefix(1) == CMD_TERM_S) {
            responseBuffer = ""
            reading = true
        }

        // Disacard any leading junk characters up to the command terminator
        // There's a bug where some responses will not be enclosed in the terminators
        if false == reading && msg.prefix(1) != CMD_TERM_S {
            if let idx = msg.firstIndex(of: ":") {
                //let junk = msg.prefix(upTo: idx)
                msg = String(msg.suffix(from: idx))
                responseBuffer = ""
                reading = true
            }
        }

        if(reading) {
            responseBuffer.append(msg)
        }

        //Read until the last character in the buffer is a terminator
        if(responseBuffer.count > 0 && String(responseBuffer.last!) == CMD_TERM_S) {
            NSLog("Parsing response buffer \(responseBuffer)")
            let commands = responseBuffer.components(separatedBy: ":").filter{ $0.count > 1 }
            reading = false
            responseBuffer = ""
            
            //publish Each of the commands
            commands.forEach { cmd in
                NSLog("Publishing response \(cmd)")
                //This will publish each command in sequence
                self.command = cmd
            }
        }
    }
}

extension CommandParser {
    static func constructCommand(_ command:String, value:String?) -> String
    {
        var ret = CMD_TERM_S + command
        if let value = value {
            ret = ret + CMD_SEP_S + value
        }
        ret = ret + CMD_TERM_S
        return ret
    }
}

