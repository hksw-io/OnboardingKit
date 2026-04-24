import SwiftUI

public struct OnboardingFeatureItem: Identifiable {
    public let id = UUID()
    public let image: Image?
    public let label: Text?
    public let description: Text

    public init(image: Image? = nil, label: Text? = nil, description: Text) {
        self.image = image
        self.label = label
        self.description = description
    }
}

public protocol OnboardingContent {
    var appIcon: Image? { get }
    var title: Text { get }
    var subtitle: Text? { get }
    var features: [OnboardingFeatureItem] { get }
    var primaryButtonText: Text { get }
    var skipButtonText: Text? { get }
    var errorAlertTitle: Text { get }
    var errorOKText: Text { get }
}

public extension OnboardingContent {
    var appIcon: Image? { nil }
    var subtitle: Text? { nil }
    var skipButtonText: Text? { nil }
}
