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


import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var history: CommandHistory
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(height: 5.0)
                ZStack {
                    Rectangle()
                        .border(Color(.white))
                        .cornerRadius(10.0)
                    VStack {
                        ScrollView {
                            Text(history.history)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    
                }
                .padding(5)
                Spacer()
            }
            .navigationTitle(Text("Command History"))
            .toolbar(id: "terminal_actions") {
                ToolbarItem(id: "scan", placement: .navigationBarTrailing) {
                    Button(action: {
                        history.clear()
                    }, label: {
                        Image(systemName: "xmark.circle")
                    })
                }
            }
            .toolbarRole(.automatic)
        }
    }
}

struct TerminalView_Previews: PreviewProvider {
    @StateObject static var history = CommandHistory()

    static var previews: some View {
        TerminalView()
            .environmentObject(history)
    }
}
