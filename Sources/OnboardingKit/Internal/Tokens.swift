import SwiftUI

enum Tokens {
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum Radius {
        static let large: CGFloat = 16
        static let iconScale: CGFloat = 0.22
    }

    enum Layout {
        static let contentMaxWidth: CGFloat = 560
        static let compactHorizontalPadding: CGFloat = 16
        static let regularHorizontalPadding: CGFloat = 24
        static let compactWidthBreakpoint: CGFloat = 390
        static let footerVerticalPadding: CGFloat = 20
    }

    enum Motion {
        static let featureBaseDelay: Double = 0.3
        static let featureStaggerDelay: Double = 0.15
        static let revealDuration: Double = 0.4
        static let revealOffset: CGFloat = 30
    }

    enum Platform {
        #if os(macOS)
            static let iconSize: CGFloat = 64
            static let featureIconSize: CGFloat = 24
            static let buttonVerticalPadding: CGFloat = 8
            static let contentSpacing: CGFloat = 24
            static let featureSpacing: CGFloat = 20
            static let topPadding: CGFloat = 32
            static let bottomPadding: CGFloat = 20
            static let scrollEdgeFadeHeight: CGFloat = 60
        #else
            static let iconSize: CGFloat = 100
            static let featureIconSize: CGFloat = 35
            static let buttonVerticalPadding: CGFloat = 14
            static let contentSpacing: CGFloat = 38
            static let featureSpacing: CGFloat = 32
            static let topPadding: CGFloat = 32
            static let bottomPadding: CGFloat = 24
            static let scrollEdgeFadeHeight: CGFloat = 80
        #endif
    }

    static var background: Color {
        #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
        #elseif os(iOS)
            Color(.systemBackground)
        #else
            Color.black
        #endif
    }
}
