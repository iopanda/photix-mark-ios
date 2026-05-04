import SwiftUI

enum AppTheme {
    static let accent        = Color.accentColor

    #if os(iOS)
    static let background    = Color(uiColor: .systemBackground)
    static let secondaryBg   = Color(uiColor: .secondarySystemBackground)
    static let tertiary      = Color(uiColor: .tertiarySystemBackground)
    static let primaryText   = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let separator     = Color(uiColor: .separator)
    #else
    static let background    = Color(nsColor: .windowBackgroundColor)
    static let secondaryBg   = Color(nsColor: .controlBackgroundColor)
    static let tertiary      = Color(nsColor: .underPageBackgroundColor)
    static let primaryText   = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let separator     = Color(nsColor: .separatorColor)
    #endif

    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 16
    static let tabBarHeight: CGFloat = 44
}

#if os(macOS)
extension View {
    /// Sets the mouse cursor when hovering over this view (macOS only).
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
#endif

extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        switch cleaned.count {
        case 6:
            self = Color(
                red:   Double((rgb >> 16) & 0xFF) / 255,
                green: Double((rgb >> 8)  & 0xFF) / 255,
                blue:  Double(rgb & 0xFF) / 255
            )
        case 8:
            self = Color(
                red:   Double((rgb >> 24) & 0xFF) / 255,
                green: Double((rgb >> 16) & 0xFF) / 255,
                blue:  Double((rgb >> 8)  & 0xFF) / 255,
                opacity: Double(rgb & 0xFF) / 255
            )
        default:
            self = .black
        }
    }
}
