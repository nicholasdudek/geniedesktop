import CoreGraphics
import Foundation

private typealias RawCGWindowListCreateImageFunc = @convention(c) (
    CGRect,
    UInt32,
    UInt32,
    UInt32
) -> Unmanaged<CGImage>?

private let _rawCGWindowListCreateImage: RawCGWindowListCreateImageFunc? = {
    guard let handle = dlopen(nil, RTLD_NOW) else { return nil }
    guard let sym = dlsym(handle, "CGWindowListCreateImage") else { return nil }
    return unsafeBitCast(sym, to: RawCGWindowListCreateImageFunc.self)
}()

@inline(__always)
public func safeCGWindowListCreateImage(
    _ screenBounds: CGRect,
    _ listOption: CGWindowListOption,
    _ windowID: CGWindowID,
    _ imageOption: CGWindowImageOption
) -> CGImage? {
    guard let fn = _rawCGWindowListCreateImage else { return nil }
    return fn(screenBounds, listOption.rawValue, windowID, imageOption.rawValue)?.takeRetainedValue()
}
