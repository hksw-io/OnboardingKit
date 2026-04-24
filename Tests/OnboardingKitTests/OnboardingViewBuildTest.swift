#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import OnboardingKit

@MainActor
struct OnboardingViewBuildTest {
    @Test
    func viewConstructsWithMinimalContent() {
        struct MinimalContent: OnboardingContent {
            var title: Text { Text("Welcome") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One."))]
            }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: MinimalContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {})
    }

    @Test
    func viewConstructsWithAllOptionalFields() {
        struct RichContent: OnboardingContent {
            var appIcon: Image? { Image(systemName: "app.gift.fill") }
            var title: Text { Text("Welcome") }
            var subtitle: Text? { Text("Subtitle line.") }
            var features: [OnboardingFeatureItem] {
                [
                    OnboardingFeatureItem(
                        image: Image(systemName: "star"),
                        label: Text("Label"),
                        description: Text("Description.")),
                ]
            }
            var primaryButtonText: Text { Text("Get started") }
            var skipButtonText: Text? { Text("Skip") }
            var errorAlertTitle: Text { Text("Something went wrong") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: RichContent(),
            isLoading: .constant(true),
            errorMessage: .constant("Network offline"),
            onPrimary: {},
            onSkip: {})
    }

    @Test
    func viewConstructsWithConvenienceFeatureInitializer() {
        struct ConvenienceContent: OnboardingContent {
            var title: Text { Text("Convenience") }
            var features: [OnboardingFeatureItem] {
                [
                    OnboardingFeatureItem(
                        systemImage: "sparkles",
                        label: "Localized label",
                        description: "Localized description."),
                ]
            }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: ConvenienceContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {})
    }

    @Test
    func viewConstructsWithLongLocalizedContentAndManyFeatures() {
        struct LongContent: OnboardingContent {
            var appIcon: Image? { Image(systemName: "app.badge.fill") }
            var title: Text {
                Text("A much longer onboarding title that must wrap cleanly on compact devices")
            }
            var subtitle: Text? {
                Text("This subtitle is intentionally longer so narrow presentations and larger Dynamic Type sizes still have room to breathe.")
            }
            var features: [OnboardingFeatureItem] {
                (1...12).map { index in
                    OnboardingFeatureItem(
                        image: Image(systemName: "checkmark.circle.fill"),
                        label: Text("Onboarding feature \(index) with a longer localized label"),
                        description: Text(
                            "This onboarding description is long enough to wrap over multiple lines while keeping the icon, text, and action area stable."))
                }
            }
            var primaryButtonText: Text {
                Text("Get started with all sample data and preferences")
            }
            var skipButtonText: Text? {
                Text("Skip this longer onboarding flow for now")
            }
            var errorAlertTitle: Text { Text("Something went wrong") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: LongContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {})
    }

    @Test
    func viewConstructsWhenComputedFeaturesRecreateValues() {
        struct ComputedContent: OnboardingContent {
            var title: Text { Text("Computed") }
            var features: [OnboardingFeatureItem] {
                [
                    OnboardingFeatureItem(description: Text("First computed feature.")),
                    OnboardingFeatureItem(description: Text("Second computed feature.")),
                    OnboardingFeatureItem(description: Text("Third computed feature.")),
                ]
            }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: ComputedContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {})
    }

    @Test
    func viewConstructsAcrossLoadingAndErrorStates() {
        struct StateContent: OnboardingContent {
            var title: Text { Text("State") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("State feature."))]
            }
            var primaryButtonText: Text { Text("Start") }
            var skipButtonText: Text? { Text("Skip") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: StateContent(),
            isLoading: .constant(true),
            errorMessage: .constant("Network offline"),
            onPrimary: {},
            onSkip: {})

        _ = OnboardingView(
            content: StateContent(),
            isLoading: .constant(false),
            errorMessage: .constant("Retry failed"),
            onPrimary: {},
            onSkip: {})
    }
}
#endif
