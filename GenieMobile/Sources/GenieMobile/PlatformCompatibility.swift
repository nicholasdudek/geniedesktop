#if os(macOS)
import SwiftUI

extension View {
    @ViewBuilder
    func textInputAutocapitalization(_ style: TextInputAutocapitalizationHelper?) -> some View {
        self
    }

    @ViewBuilder
    func keyboardType(_ type: KeyboardTypeHelper) -> some View {
        self
    }

    @ViewBuilder
    func navigationBarTitleDisplayMode(_ mode: TitleDisplayModeHelper) -> some View {
        self
    }
}

enum TextInputAutocapitalizationHelper {
    case never
    case words
    case sentences
    case characters
}

enum KeyboardTypeHelper {
    case URL
    case defaultType
}

enum TitleDisplayModeHelper {
    case inline
    case large
    case automatic
}
#endif

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public enum MobileHaptics {
    public static func light() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    public static func medium() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    public static func rigid() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}
