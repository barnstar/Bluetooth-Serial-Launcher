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

struct LauncherTabView: View {
    @EnvironmentObject var launchController: LaunchController

    var body: some View {
        TabView {
            ConnectionsView()
                .tabItem({
                    Label("Connections", systemImage: "wifi")
                })
                .environmentObject(launchController.btSerial.connectionManager)
            LauncherView()
                .tabItem({
                    Label("Launch", systemImage: "bolt")
                })
                .onAppear {
                    launchController.sendValidationCommand()
                    launchController.sendCheckVoltage()
                }
            TerminalView()
                .tabItem({
                    Label("Terminal", systemImage: "terminal")
                })
                .environmentObject(launchController.btSerial.commandHistory)
            SettingsView()
                .tabItem({
                    Label("Settings", systemImage: "gear")
                })
        }
        .tint(.orange)
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject static var controller = LaunchController()

    static var previews: some View {
        LauncherTabView()
            .environmentObject(controller)
    }
}
