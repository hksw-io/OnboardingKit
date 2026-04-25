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

    public init(
        systemImage: String? = nil,
        label: LocalizedStringResource? = nil,
        description: LocalizedStringResource)
    {
        self.image = systemImage.map { Image(systemName: $0) }
        self.label = label.map { Text($0) }
        self.description = Text(description)
    }
}

public struct OnboardingNextStepItem: Identifiable {
    public let id: String
    public let image: Image?
    public let title: Text
    public let description: Text?
    public let actionText: Text?
    public let presentation: OnboardingNextStepPresentation

    public init(
        id: String = UUID().uuidString,
        image: Image? = nil,
        title: Text,
        description: Text? = nil,
        actionText: Text? = nil,
        presentation: OnboardingNextStepPresentation = .push)
    {
        self.id = id
        self.image = image
        self.title = title
        self.description = description
        self.actionText = actionText
        self.presentation = presentation
    }

    public init(
        id: String = UUID().uuidString,
        systemImage: String? = nil,
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        actionText: LocalizedStringResource? = nil,
        presentation: OnboardingNextStepPresentation = .push)
    {
        self.id = id
        self.image = systemImage.map { Image(systemName: $0) }
        self.title = Text(title)
        self.description = description.map { Text($0) }
        self.actionText = actionText.map { Text($0) }
        self.presentation = presentation
    }
}

public enum OnboardingNextStepPresentation: Equatable {
    case push
    case sheet
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
    var nextStepsTitle: Text? { get }
    var nextSteps: [OnboardingNextStepItem] { get }
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
    var nextStepsTitle: Text? { Text("Next steps") }
    var nextSteps: [OnboardingNextStepItem] { [] }
    var skipButtonText: Text? { nil }
}
