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
    func viewConstructsWithNextSteps() {
        struct NextStepsContent: OnboardingContent {
            var title: Text { Text("Next") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One feature."))]
            }
            var nextStepsTitle: Text? { Text("Try next") }
            var nextSteps: [OnboardingNextStepItem] {
                [
                    OnboardingNextStepItem(
                        id: "create-sample",
                        image: Image(systemName: "sparkles"),
                        title: Text("Create a sample"),
                        description: Text("Use starter content to explore the app."),
                        actionText: Text("Create")),
                    OnboardingNextStepItem(
                        id: "adjust-settings",
                        title: Text("Adjust settings"),
                        description: Text("Review preferences when you are ready."),
                        presentation: .sheet),
                ]
            }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: NextStepsContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {},
            onNextStep: { _ in })
    }

    @Test
    func viewConstructsWithNextStepDestinations() {
        struct FlowContent: OnboardingContent {
            var title: Text { Text("Flow") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One feature."))]
            }
            var nextSteps: [OnboardingNextStepItem] {
                [
                    OnboardingNextStepItem(
                        id: "push-step",
                        title: Text("Push route"),
                        actionText: Text("Open")),
                    OnboardingNextStepItem(
                        id: "sheet-step",
                        title: Text("Show sheet"),
                        actionText: Text("Open"),
                        presentation: .sheet),
                ]
            }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: FlowContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {},
            nextStepDestination: { step in
                Text(step.id)
            })
    }

    @Test
    func nextStepInitializerStoresStableIDAndPresentation() {
        let step = OnboardingNextStepItem(
            id: "notifications",
            title: Text("Notifications"),
            presentation: .sheet)

        #expect(step.id == "notifications")
        #expect(step.presentation == .sheet)
    }

    @Test
    func viewConstructsWithPrimaryDestination() {
        struct PrimaryRouteContent: OnboardingContent {
            var title: Text { Text("Primary") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One feature."))]
            }
            var primaryButtonText: Text { Text("Continue") }
            var primaryRouteBackButtonText: Text { Text("Overview") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: PrimaryRouteContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {},
            primaryDestination: {
                Text("Primary route")
            })
    }

    @Test
    func viewConstructsWithPrimaryRouteChain() {
        struct PrimaryRouteChainContent: OnboardingContent {
            var title: Text { Text("Primary") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One feature."))]
            }
            var primaryRoutes: [OnboardingPrimaryRoute] {
                [
                    OnboardingPrimaryRoute(id: "permissions"),
                    OnboardingPrimaryRoute(id: "sample-data"),
                    OnboardingPrimaryRoute(id: "notifications"),
                ]
            }
            var primaryButtonText: Text { Text("Continue") }
            var primaryRouteBackButtonText: Text { Text("Overview") }
            var primaryRouteNextButtonText: Text { Text("Next step") }
            var primaryRouteDoneButtonText: Text { Text("Finish") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: PrimaryRouteChainContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {},
            onPrimaryRoutesComplete: {},
            primaryRouteDestination: { route in
                Text(route.id)
            })
    }

    @Test
    func primaryRouteStoresStableID() {
        let route = OnboardingPrimaryRoute(id: "sample-data")

        #expect(route.id == "sample-data")
    }

    @Test
    func nextStepsDefaultToEmptyAndDefaultTitleIsAvailable() {
        struct DefaultNextStepsContent: OnboardingContent {
            var title: Text { Text("Defaults") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One feature."))]
            }
            var primaryButtonText: Text { Text("Go") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        let content = DefaultNextStepsContent()

        #expect(content.nextSteps.isEmpty)
        #expect(content.nextStepsTitle != nil)
        #expect(content.primaryRoutes.isEmpty)
    }

    @Test
    func viewConstructsWithConvenienceNextStepInitializer() {
        struct ConvenienceContent: OnboardingContent {
            var title: Text { Text("Convenience") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(description: Text("One feature."))]
            }
            var nextSteps: [OnboardingNextStepItem] {
                [
                    OnboardingNextStepItem(
                        id: "localized-next-step",
                        systemImage: "checkmark.circle.fill",
                        title: "Localized next step",
                        description: "Localized next step description.",
                        actionText: "Open",
                        presentation: .sheet),
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
            var nextStepsTitle: Text? { Text("Next steps") }
            var nextSteps: [OnboardingNextStepItem] {
                [
                    OnboardingNextStepItem(
                        id: "import-sample",
                        image: Image(systemName: "tray.and.arrow.down.fill"),
                        title: Text("Import a sample collection with a longer localized title"),
                        description: Text("This description checks wrapping inside the next-step section on compact devices."),
                        actionText: Text("Import sample data")),
                    OnboardingNextStepItem(
                        id: "review-settings",
                        image: Image(systemName: "gearshape.fill"),
                        title: Text("Review settings later"),
                        description: Text("Static next-step rows can omit an action label."),
                        presentation: .sheet),
                ]
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
