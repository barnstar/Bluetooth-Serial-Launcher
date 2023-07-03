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

struct ConnectionsView: View {
    @EnvironmentObject var connectionManager: BTConnectionManager
   
    var body: some View {
        NavigationStack {
            List {
                ForEach(connectionManager.peripherals) { peripheral in
                    PeripheralCell(peripheral: peripheral)
                        .onTapGesture   {
                            connectionManager.connectToPeripheral(peripheral.peripheralID)
                    }
                }
            }
            .navigationTitle(Text("Connections"))
            .toolbar(id: "connetions_actions") {
                ToolbarItem(id: "scan", placement: .navigationBarTrailing) {
                    Button(action: {
                        switch connectionManager.scanning {
                            case false: connectionManager.startScan()
                            case true: connectionManager.stopScan()
                        }
                    }, label: {
                        switch connectionManager.scanning {
                            case false: Image(systemName: "arrow.triangle.2.circlepath")
                            case true: Image(systemName: "xmark.circle")
                        }
                    })
                }
            }
            .toolbarRole(.automatic)
        }
    }
}

struct PeripheralCell: View {
    @StateObject var peripheral: PeripheralViewModel

    var body: some View {
        HStack {
            Text(peripheral.name)
            Spacer()
            Text("\(peripheral.rssi) db")
            Image(systemName: peripheral.stateImage)
        }
    }
}

struct ConnectionsView_Previews: PreviewProvider {
    @StateObject static var controller = LaunchController()
    
    static var previews: some View {
        
        ConnectionsView()
            .environmentObject(controller)
            .environmentObject(controller.btSerial.connectionManager)
    }
}
