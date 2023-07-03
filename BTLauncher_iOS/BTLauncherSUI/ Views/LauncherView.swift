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

struct LauncherView: View {
    @EnvironmentObject var launchController: LaunchController

    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(height: 15.0)
                ConnectionHeaderView(model: launchController.viewModel)
                VoltageHeaderView(model: launchController.viewModel)
                Spacer()
                ContinuityIndicator(model: launchController.viewModel)
                Spacer()
                ActionsView(controller: launchController,
                            model: launchController.viewModel)
                Spacer(minLength: 5.0)
            }.navigationTitle(Text("Launch Control"))
        }
    }
}

struct ConnectionHeaderView: View {
    @StateObject var model: LaunchControlViewModel
    
    var body: some View {
        HStack {
            IndicatorView(
                enabled: model.validated,
                text: "Validated" ,
                colors: ( .red, .green ) )
            .frame(minWidth: 0, maxWidth: .infinity)
            
            IndicatorView(
                enabled: model.connected,
                text: "Connected",
                colors: ( .red, .green ) )
            .frame(minWidth: 0, maxWidth: .infinity)
            
            IndicatorView(
                enabled: model.connected,
                text: model.signalLvlString,
                colors: ( .green, .green ) )
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(height: 40.0)
        .padding(4)
    }
}

struct VoltageHeaderView: View {
    @StateObject var model: LaunchControlViewModel

    var body: some View {
        HStack {
            IndicatorView(
                enabled: (model.batteryLevel > 3.7),
                text: model.lvBatteryIndicatorText,
                colors: ( .red, .green ) )
            .frame(minWidth: 0, maxWidth: .infinity)
            
            IndicatorView(
                enabled: (model.hvBatteryLevel > 11.7),
                text: model.hvBatteryIndicatorText,
                colors: ( .red, .green ) )
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(height: 40.0)
        .padding(4)
    }
}

struct ContinuityIndicator: View {
    @StateObject var model: LaunchControlViewModel

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(.green)
                    .frame(width: 240, height: 60)
                    .cornerRadius(10.0)
                Text("Continuity OK")
                    .modifier(HeaderTextStyle())
            }.padding(80)
        }.opacity(model.continuity ? 1.0 : 0.0)
    }
}

struct ActionsView: View {
    let controller: LaunchController
    @StateObject var model: LaunchControlViewModel
    
    var body: some View {
        VStack {
            ToggleButton(
                labels: ("Arm", "Armed !!"),
                colors:(.orange, .red),
                action:
                    { val in
                        controller.sendArmedCommand(val)
                        model.armed = val
                    })
            .frame(width: 240, height: 60)

            PressHoldButton(
                label: (model.armed ? "Engine Start" : "Unarmed"),
                colors: (.blue, .red),
                action:
                    { val in
                        if model.armed {
                            controller.sendFireCommand(val)
                        }
                    })
            .frame(width: 240, height: 60)
            .opacity(model.armed ? 1.0 : 0.0)
            
            PressHoldButton(
                label: "Continuity",
                colors: (.blue, .red),
                action:
                    { val in
                        controller.sendContinuityCommand(val)
                    })
            .frame(width: 240, height: 60)
            .opacity(model.armed ? 0.0 : 1.0)
        }
        .opacity(model.validated ? 1.0 : 0.0)
    }
}


struct LauncherView_Previews: PreviewProvider {
    @StateObject static var controller = LaunchController()

    static var previews: some View {
        LauncherView()
            .environmentObject(controller)
    }
}
