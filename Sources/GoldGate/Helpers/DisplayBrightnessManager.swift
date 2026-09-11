import AppKit
import CoreGraphics
import Foundation

// MARK: - Hardware Display & Keyboard Brightness Manager
@MainActor
public final class DisplayBrightnessManager: ObservableObject {
    public static let shared = DisplayBrightnessManager()

    @Published public var displayBrightness: Double = 0.85
    @Published public var keyboardBrightness: Double = 0.50
    @Published public var isKeyboardBacklightAvailable: Bool = false

    private typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private var getBrightnessFn: DisplayServicesGetBrightnessFunc?
    private var setBrightnessFn: DisplayServicesSetBrightnessFunc?
    private var keyboardClient: AnyObject?
    private var keyboardBacklightIDs: [Any] = []

    private init() {
        loadDisplayServices()
        loadKeyboardBrightnessClient()
        refreshBrightness()
    }

    // DisplayServices and CoreBrightness are private frameworks, and
    // KeyboardBrightnessClient is a private class reached through
    // NSClassFromString — all three are Guideline 2.5.1. macOS exposes no
    // public API for setting display or keyboard brightness, so Genie Lite
    // drops the feature: the function pointers stay nil,
    // isKeyboardBacklightAvailable stays false, and the brightness controls
    // hide themselves rather than presenting sliders that do nothing.
    private func loadDisplayServices() {
        #if !GENIE_MAS
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) {
            if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFn = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessFunc.self)
            }
            if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightnessFn = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
            }
        }
        #endif
    }

    private func loadKeyboardBrightnessClient() {
        #if !GENIE_MAS
        _ = dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY)
        if let cls = NSClassFromString("KeyboardBrightnessClient") as? NSObject.Type {
            let client = cls.init()
            self.keyboardClient = client
            if let ids = client.perform(NSSelectorFromString("copyKeyboardBacklightIDs"))?.takeUnretainedValue() as? [Any], !ids.isEmpty {
                self.keyboardBacklightIDs = ids
                self.isKeyboardBacklightAvailable = true
            }
        }
        #endif
    }

    public func refreshBrightness() {
        // 1. Display Brightness
        if let getFn = getBrightnessFn {
            var val: Float = 0.0
            let res = getFn(CGMainDisplayID(), &val)
            if res == 0 && val >= 0.0 {
                self.displayBrightness = Double(val)
            }
        }

        // 2. Keyboard Backlight Brightness
        if let client = keyboardClient as? NSObject, let firstID = keyboardBacklightIDs.first {
            let sel = NSSelectorFromString("brightnessForKeyboard:")
            if client.responds(to: sel) {
                if let method = class_getInstanceMethod(type(of: client), sel) {
                    typealias GetKBBrightnessFunc = @convention(c) (AnyObject, Selector, UInt64) -> Float
                    let fn = unsafeBitCast(method_getImplementation(method), to: GetKBBrightnessFunc.self)
                    let kbID = (firstID as? NSNumber)?.uint64Value ?? 0
                    let cur = fn(client, sel, kbID)
                    if cur >= 0.0 {
                        self.keyboardBrightness = Double(cur)
                    }
                }
            }
        }
    }

    public func setDisplayBrightness(_ newBrightness: Double) {
        let clamped = max(0.05, min(1.0, newBrightness))
        self.displayBrightness = clamped

        if let setFn = setBrightnessFn {
            for screen in NSScreen.screens {
                let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? CGMainDisplayID()
                _ = setFn(displayID, Float(clamped))
            }
        }
    }

    public func setKeyboardBrightness(_ newBrightness: Double) {
        let clamped = max(0.0, min(1.0, newBrightness))
        self.keyboardBrightness = clamped

        if let client = keyboardClient as? NSObject, let firstID = keyboardBacklightIDs.first {
            let sel = NSSelectorFromString("setBrightness:forKeyboard:")
            if let method = class_getInstanceMethod(type(of: client), sel) {
                typealias SetKBBrightnessFunc = @convention(c) (AnyObject, Selector, Float, UInt64) -> Void
                let fn = unsafeBitCast(method_getImplementation(method), to: SetKBBrightnessFunc.self)
                let kbID = (firstID as? NSNumber)?.uint64Value ?? 0
                fn(client, sel, Float(clamped), kbID)
            }
        }
    }
}
