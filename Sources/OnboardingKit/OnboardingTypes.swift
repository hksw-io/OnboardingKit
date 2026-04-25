import SwiftUI

public struct OnboardingFeatureItem: Identifiable {
    public let id: String
    public let image: Image?
    public let label: Text?
    public let description: Text

    public init(id: String, image: Image? = nil, label: Text? = nil, description: Text) {
        self.id = id
        self.image = image
        self.label = label
        self.description = description
    }

    public init(
        id: String,
        systemImage: String? = nil,
        label: LocalizedStringResource? = nil,
        description: LocalizedStringResource)
    {
        self.id = id
        self.image = systemImage.map { Image(systemName: $0) }
        self.label = label.map { Text($0) }
        self.description = Text(description)
    }

    @available(*, deprecated, message: "Provide a stable id so SwiftUI can preserve feature identity.")
    public init(image: Image? = nil, label: Text? = nil, description: Text) {
        self.init(id: UUID().uuidString, image: image, label: label, description: description)
    }

    @available(*, deprecated, message: "Provide a stable id so SwiftUI can preserve feature identity.")
    public init(
        systemImage: String? = nil,
        label: LocalizedStringResource? = nil,
        description: LocalizedStringResource)
    {
        self.init(
            id: UUID().uuidString,
            systemImage: systemImage,
            label: label,
            description: description)
    }
}

public struct OnboardingPrimaryRoute: Identifiable, Hashable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public protocol OnboardingContent {
    var appIcon: Image? { get }
    var title: Text { get }
    var subtitle: Text? { get }
    var features: [OnboardingFeatureItem] { get }
    var primaryRoutes: [OnboardingPrimaryRoute] { get }
    var primaryRouteNextButtonText: Text { get }
    var primaryRouteDoneButtonText: Text { get }
    var primaryButtonText: Text { get }
    var skipButtonText: Text? { get }
    var errorAlertTitle: Text { get }
    var errorOKText: Text { get }
}

public extension OnboardingContent {
    var appIcon: Image? { nil }
    var subtitle: Text? { nil }
    var primaryRoutes: [OnboardingPrimaryRoute] { [] }
    var primaryRouteNextButtonText: Text { Text("Next") }
    var primaryRouteDoneButtonText: Text { Text("Done") }
    var skipButtonText: Text? { nil }
}
