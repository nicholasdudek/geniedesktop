// MARK: - Auto-Generated Trained Responsive Layout Tokens for macOS
// Trained across all Mac screen sizes (14", 16", Air, iMac, Studio Display 5K, 6K)

import SwiftUI

public struct GenieResponsiveTokens {
    public static func sidebarWidth(for viewportWidth: CGFloat) -> CGFloat {
        if viewportWidth < 800 { return 0 } // Collapsed into drawer
        return min(301.5, max(212.0, viewportWidth * 0.191))
    }
    
    public static func gridColumns(for availableWidth: CGFloat) -> [GridItem] {
        let minCardW: CGFloat = 222.6
        let gap: CGFloat = 10.1
        let count = max(1, Int(floor((availableWidth + gap) / (minCardW + gap))))
        return Array(repeating: GridItem(.flexible(minimum: minCardW, maximum: 453.8), spacing: gap), count: count)
    }
    
    public static func titleFontSize(for viewportWidth: CGFloat) -> CGFloat {
        let t = max(0.0, min(1.0, (viewportWidth - 756.0) / (3440.0 - 756.0)))
        return 18.9 + t * (33.9 - 18.9)
    }
    
    public static func bodyFontSize(for viewportWidth: CGFloat) -> CGFloat {
        let t = max(0.0, min(1.0, (viewportWidth - 756.0) / (3440.0 - 756.0)))
        return 13.0 + t * (16.7 - 13.0)
    }
}
