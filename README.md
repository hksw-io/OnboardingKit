# OnboardingKit

A reusable SwiftUI onboarding sheet for iOS and macOS apps in the HK Softworks portfolio.

Pure SwiftUI — the consumer owns state (loading, error, dismissal). Works with any state management approach (TCA, `@Observable`, `@State`).

## Requirements

- iOS 26+ / macOS 26+
- Swift 6.0+

## Installation

```swift
.package(url: "https://github.com/hksw-io/OnboardingKit.git", from: "1.0.0")
```

Or in Xcode: **File > Add Package Dependencies** and enter the URL above.

## Usage

Implement `OnboardingContent` with your app's strings and icon, then drive the view with bindings and callbacks:

```swift
import SwiftUI
import OnboardingKit

struct MyOnboarding: OnboardingContent {
    var appIcon: Image? { Image("AppIconImage") }
    var title: Text { Text("Welcome to MyApp") }
    var subtitle: Text? { Text("Here's what makes it great.") }
    var features: [OnboardingFeatureItem] {
        [
            OnboardingFeatureItem(
                systemImage: "hand.tap.fill",
                label: "Tap to flip",
                description: "Review cards with a simple tap."),
        ]
    }
    var nextSteps: [OnboardingNextStepItem] {
        [
            OnboardingNextStepItem(
                id: "create-deck",
                systemImage: "square.and.pencil",
                title: "Create your first deck",
                description: "Start with a small set so the app can learn your rhythm.",
                actionText: "Open"),
            OnboardingNextStepItem(
                id: "notifications",
                systemImage: "bell.badge.fill",
                title: "Enable reminders",
                description: "Show a focused setup sheet after the overview.",
                actionText: "Configure",
                presentation: .sheet),
        ]
    }
    var primaryRoutes: [OnboardingPrimaryRoute] {
        [
            OnboardingPrimaryRoute(id: "permissions"),
            OnboardingPrimaryRoute(id: "sample-data"),
            OnboardingPrimaryRoute(id: "notifications"),
        ]
    }
    var primaryButtonText: Text { Text("Get started") }
    var primaryRouteDoneButtonText: Text { Text("Finish") }
    var skipButtonText: Text? { Text("Skip for now") }
    var errorAlertTitle: Text { Text("Something went wrong") }
    var errorOKText: Text { Text("OK") }
}

struct RootView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        OnboardingView(
            content: MyOnboarding(),
            isLoading: $isLoading,
            errorMessage: $errorMessage,
            onPrimary: { /* create sample data, then dismiss */ },
            onSkip: { /* mark onboarding complete, dismiss */ },
            onNextStep: { step in
                /* analytics or state updates before presentation */
            },
            onPrimaryRoutesComplete: {
                /* dismiss onboarding or mark setup complete */
            },
            primaryRouteDestination: { route in
                switch route.id {
                case "permissions":
                    PermissionsSetupView()
                case "sample-data":
                    SampleDataSetupView()
                case "notifications":
                    NotificationSetupView()
                default:
                    EmptyView()
                }
            },
            nextStepDestination: { step in
                switch step.id {
                case "create-deck":
                    CreateDeckSetupView()
                case "notifications":
                    ReminderSetupView()
                default:
                    EmptyView()
                }
            })
    }
}
```

## State ownership

The view is purely presentational:

- `isLoading: Binding<Bool>` — when `true`, the primary button shows a progress spinner and both buttons are disabled.
- `errorMessage: Binding<String?>` — when non-nil, the view presents an alert. Setting it back to `nil` (or letting the user tap the OK button) dismisses the alert.
- `onPrimary` / `onSkip` — fired on tap. Your state layer handles the rest.
- `primaryRoutes` / `primaryRouteDestination` — optional chained follow-up routes opened by the primary button with in-sheet slide transitions. The package supplies Next and Done controls.
- `primaryDestination` — convenience API for a single follow-up route. `onPrimary` still fires before the route opens.
- `nextSteps` / `nextStepDestination` — optional follow-up routes inside onboarding. Give each step a stable `id`; use `presentation: .push` for an in-flow route or `.sheet` for a focused setup sheet.
- `onNextStep` — optional hook fired before the route or sheet opens, useful for analytics or app state.

## License

Private. Copyright © HK Softworks.
