# GreetKit

A reusable SwiftUI onboarding sheet for iOS and macOS apps in the HK Softworks portfolio.

Pure SwiftUI — the consumer owns state (loading, error, dismissal). Works with any state management approach (TCA, `@Observable`, `@State`).

The package and import name is `GreetKit`. Public view and content APIs intentionally use the
domain language `Onboarding...`, for example `OnboardingView`, `OnboardingContent`, and
`OnboardingPrimaryRoute`.

## Preview

<p>
  <img src="Docs/Media/greetkit-default.png" alt="GreetKit default onboarding screen with branded gradient background and pinned actions." width="360">
  <img src="Docs/Media/greetkit-long-content.png" alt="GreetKit long localized onboarding content with branded gradient background, footer fade, and pinned actions." width="360">
</p>

## Requirements

- iOS 26+ / macOS 26+
- Swift 6.2+

## Installation

No release tags are published yet, so use the `master` branch for now:

```swift
.package(url: "https://github.com/hksw-io/GreetKit.git", branch: "master")
```

Switch to a semantic version requirement after the first release tag exists:

```swift
.package(url: "https://github.com/hksw-io/GreetKit.git", from: "1.0.0")
```

Or in Xcode: **File > Add Package Dependencies**, enter the URL above, and select the `master` branch until a release tag is available.

## Usage

Implement `OnboardingContent` with your app's strings and icon, then drive the view with bindings and callbacks:

```swift
import SwiftUI
import GreetKit

struct MyOnboarding: OnboardingContent {
    var appIcon: Image? { Image("AppIconImage") }
    var title: Text { Text("Welcome to MyApp") }
    var subtitle: Text? { Text("Here's what makes it great.") }
    var features: [OnboardingFeatureItem] {
        [
            OnboardingFeatureItem(
                id: "tap-to-flip",
                systemImage: "hand.tap.fill",
                label: "Tap to flip",
                description: "Review cards with a simple tap."),
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
    var primaryRouteNextButtonText: Text { Text("Next") }
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
            onPrimary: { /* analytics or setup before routes open */ },
            onSkip: { /* mark onboarding complete, dismiss */ },
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
            })
    }
}
```

For a simple onboarding sheet, omit `primaryRoutes` and `primaryRouteDestination`. The primary and skip callbacks can then dismiss the sheet directly.

For a chained setup flow, provide `primaryRoutes` and `primaryRouteDestination`. `onPrimary` fires first, then the library opens the first route with an in-sheet transition. Do not dismiss from `onPrimary` when using a route chain. Finish in `onPrimaryRoutesComplete` after the last route. `primaryRouteNextButtonText` and `primaryRouteDoneButtonText` customize the route controls.

GreetKit does not include a separate "next steps" card/list primitive. If the primary button should continue into setup, model that as a route chain; if the app needs additional cards, build them in the consuming app or in the destination views.

## Backgrounds

The default background is the system sheet surface. Use `onboardingBackground(_:)` when an app needs a more branded first-run experience:

```swift
OnboardingView(
    content: MyOnboarding(),
    isLoading: $isLoading,
    errorMessage: $errorMessage,
    onPrimary: {},
    onSkip: {})
    .onboardingBackground(.animatedGradient())
    .onboardingStyle(OnboardingStyle(tint: .indigo))
```

Built-in options:

- `.system` — the default platform background.
- `.softGradient` / `.softGradient(brand:palette:)` — a restrained brand-derived background tuned for readable onboarding content.
- `.linearGradient(colors:startPoint:endPoint:)` — app-provided colors with the library-managed footer treatment.
- `.animatedGradient(brand:palette:motion:)` — an opt-in smooth full-surface animated gradient. It uses the style tint by default, adapts its tones for light and dark mode, and automatically becomes static when Reduce Motion is enabled.
- `.custom { context in ... }` — a fully custom SwiftUI background. Use `context.reduceMotion`, `context.brandColor`, and `context.colorScheme` to keep custom backgrounds consistent and accessible.

Destination views can still draw their own backgrounds. If they do, that local destination background appears above the onboarding background.

Every background spans behind the pinned footer and button area, including `.system`. Scroll indicators are hidden on supported platforms so branded sheets do not show a macOS scrollbar over the content.

`OnboardingStyle.tint` is the default brand color for `.softGradient` and `.animatedGradient()`. Pass `brand:` when the background should use a different brand color from the controls, or pass a full palette when an app needs exact light and dark tones:

```swift
let palette = OnboardingGradientPalette(
    light: .init(
        base: .white,
        primary: .pink,
        secondary: .orange,
        accent: .yellow),
    dark: .init(
        base: .black,
        primary: .pink,
        secondary: .purple,
        accent: .cyan))

OnboardingView(
    content: MyOnboarding(),
    isLoading: $isLoading,
    errorMessage: $errorMessage,
    onPrimary: {},
    onSkip: {})
    .onboardingBackground(.animatedGradient(palette: palette))
```

Use `motion:` when the default dancing gradient should be calmer or more expressive:

```swift
OnboardingView(
    content: MyOnboarding(),
    isLoading: $isLoading,
    errorMessage: $errorMessage,
    onPrimary: {},
    onSkip: {})
    .onboardingBackground(.animatedGradient(motion: .expressive))
```

The built-in presets are `.subtle`, `.standard`, and `.expressive`. Stronger motion increases movement, speed, and gradient contrast. For finer control, pass `OnboardingGradientMotion(strength:)`; values are clamped from `0` to `2`, and `0` keeps the animated-gradient color field static.

`.animatedMesh(primary:secondary:accent:)` remains available as a deprecated compatibility alias for `.animatedGradient(palette:motion:)`.

GreetKit keeps the footer pinned while content scrolls behind it. A measured footer mask fades overflowing content only above the footer; when scrolling reaches the end, visible content is fully opaque again.

## Styling

Use `onboardingStyle(_:)` to override foreground, tint, and button colors while keeping the library's layout, typography, and motion:

```swift
OnboardingView(
    content: MyOnboarding(),
    isLoading: $isLoading,
    errorMessage: $errorMessage,
    onPrimary: {},
    onSkip: {})
    .onboardingBackground(.softGradient)
    .onboardingStyle(OnboardingStyle(
        tint: .indigo,
        titleColor: .primary,
        featureIconColor: .mint,
        primaryButtonForegroundColor: .white,
        primaryButtonProgressTint: .white,
        secondaryButtonColor: .secondary))
```

`OnboardingBackground` controls the surface behind the sheet content. `OnboardingStyle` controls foreground roles such as title, subtitle, feature rows, primary button text, and secondary button text. Any color you leave as `nil` uses the standard system treatment.

## State ownership

The view is purely presentational:

- Give every `OnboardingFeatureItem` and `OnboardingPrimaryRoute` a stable `id`. These IDs preserve SwiftUI identity and are used for routing and analytics.
- `isLoading: Binding<Bool>` — when `true`, the primary button shows a progress spinner and both buttons are disabled.
- `errorMessage: Binding<String?>` — when non-nil, the view presents an alert. Setting it back to `nil` (or letting the user tap the OK button) dismisses the alert.
- `allowsInteractiveDismissal` — defaults to `true`. Set it to `false` only for setup flows that must block swipe or window dismissal.
- `onPrimary` / `onSkip` — fired on tap. Your state layer handles the rest.
- `primaryRoutes` / `primaryRouteDestination` — optional chained follow-up routes opened by the primary button with in-sheet slide transitions. The package supplies customizable Next and Done controls.
- `primaryDestination` — convenience API for a single follow-up route. `onPrimary` still fires before the route opens.

Route navigation state is intentionally transient and owned inside `OnboardingView`; persist only completed setup state in your app. Destination builders are generic at the public API and type-erased internally so call sites can return different SwiftUI views without exposing that plumbing.

`OnboardingFeatureItem` has `Text` and `LocalizedStringResource` initializers. Prefer the initializer with an explicit `id`; the old ID-less initializers remain only for compatibility and are deprecated.

## Local development

Run the package tests from the package root:

```sh
swift test
```

## License

MIT. See [LICENSE](LICENSE).
