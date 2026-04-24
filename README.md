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
    var primaryButtonText: Text { Text("Get started") }
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
            onSkip: { /* mark onboarding complete, dismiss */ })
    }
}
```

## State ownership

The view is purely presentational:

- `isLoading: Binding<Bool>` — when `true`, the primary button shows a progress spinner and both buttons are disabled.
- `errorMessage: Binding<String?>` — when non-nil, the view presents an alert. Setting it back to `nil` (or letting the user tap the OK button) dismisses the alert.
- `onPrimary` / `onSkip` — fired on tap. Your state layer handles the rest.

## License

Private. Copyright © HK Softworks.
