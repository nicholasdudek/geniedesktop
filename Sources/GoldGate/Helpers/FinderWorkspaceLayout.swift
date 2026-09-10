import Foundation

enum FinderWorkspaceLayout {
    static func browserWidth(totalWidth: CGFloat, ratio: CGFloat) -> CGFloat {
        let available = max(0, totalWidth - 8)
        let minimum = min(300, available)
        let maximum = max(minimum, available - 320)
        return min(maximum, max(minimum, available * ratio))
    }

    static func ratio(totalWidth: CGFloat, startWidth: CGFloat, translation: CGFloat) -> CGFloat {
        let available = max(1, totalWidth - 8)
        return browserWidth(totalWidth: totalWidth, ratio: (startWidth + translation) / available) / available
    }
}
