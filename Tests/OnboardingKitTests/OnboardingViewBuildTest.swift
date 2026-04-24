import SwiftUI
import Testing
@testable import OnboardingKit

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
}
