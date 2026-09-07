import Foundation
import CoreGraphics
import AppKit

func click(x: Double, y: Double) {
    let pt = CGPoint(x: x, y: y)
    
    // Move
    if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left) {
        move.post(tap: .cghidEventTap)
    }
    Thread.sleep(forTimeInterval: 0.1)
    
    // Down
    if let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: pt, mouseButton: .left) {
        down.post(tap: .cghidEventTap)
    }
    Thread.sleep(forTimeInterval: 0.1)
    
    // Up
    if let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: pt, mouseButton: .left) {
        up.post(tap: .cghidEventTap)
    }
}

func scroll(dy: Int32) {
    if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: dy, wheel2: 0, wheel3: 0) {
        scrollEvent.post(tap: .cghidEventTap)
    }
}

let args = CommandLine.arguments
if args.count >= 4 && args[1] == "click" {
    if let x = Double(args[2]), let y = Double(args[3]) {
        click(x: x, y: y)
        print("Clicked at (\(x), \(y))")
    }
} else if args.count >= 3 && args[1] == "scroll" {
    if let dy = Int32(args[2]) {
        scroll(dy: dy)
        print("Scrolled \(dy)")
    }
} else {
    print("Usage: ui_control click <x> <y> | scroll <dy>")
}
