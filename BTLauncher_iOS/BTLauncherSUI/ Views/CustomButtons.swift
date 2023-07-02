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
import SwiftUI


struct HeaderTextStyle: ViewModifier {
    var foregroundColor: Color = .white
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 16.0).weight(.semibold))
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1.0)
    }
}

struct IndicatorView: View {
    var enabled: Bool
    var text: String
    var colors: (Color, Color)
    var cornerRaduis: CGFloat = 10.0
    var textStyle: HeaderTextStyle = HeaderTextStyle()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(enabled ? colors.1 : colors.0)
                .cornerRadius(cornerRaduis)
            Text(text).modifier(textStyle)
        }
    }
}

struct ToggleButton: View {
    var labels: (String, String)
    var colors: (Color, Color)
    var action: (Bool) -> Void
    var textStyle: HeaderTextStyle = HeaderTextStyle()

    @State var pressed: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(pressed ? colors.1 : colors.0)
                .cornerRadius(10.0)
            Text(pressed ? labels.1 : labels.0)
                .modifier(textStyle)
        }.onTapGesture {
            pressed.toggle()
            action(pressed)
        }
    }
}

struct PressHoldButton: View {
    var label: String
    var colors: (Color, Color)
    var action: (Bool) -> Void
    var textStyle: HeaderTextStyle = HeaderTextStyle()

    @State var pressed: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(pressed ? colors.1 : colors.0)
                .cornerRadius(10.0)
            Text(label)
                .modifier(textStyle)
        }.gesture(
            DragGesture(minimumDistance: 0.0)
                .onChanged { _ in
                    if false == pressed {
                        action(true)
                    }
                    self.pressed = true
                }
                .onEnded { _ in
                    self.pressed = false
                    action(false)
                }
        )
    }
}
