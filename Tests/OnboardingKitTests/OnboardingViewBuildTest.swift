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
                [OnboardingFeatureItem(id: "one", description: Text("One."))]
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
                        id: "label",
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
                        id: "localized-label",
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
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
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
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
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
    func nextStepAccessibilityHintDescribesPushPresentation() {
        #expect(OnboardingAccessibilityText.nextStepHint(for: .push) == "Opens a follow-up screen.")
    }

    @Test
    func nextStepAccessibilityHintDescribesSheetPresentation() {
        #expect(OnboardingAccessibilityText.nextStepHint(for: .sheet) == "Presents a follow-up sheet.")
    }

    @Test
    func featureInitializerStoresStableID() {
        let feature = OnboardingFeatureItem(
            id: "stable-feature",
            label: Text("Stable feature"),
            description: Text("A feature with stable identity."))

        #expect(feature.id == "stable-feature")
    }

    @Test
    func revealDelayStartsWithBaseDelay() {
        #expect(Tokens.Motion.revealDelay(for: 0) == Tokens.Motion.featureBaseDelay)
    }

    @Test
    func revealDelayCapsLongLists() {
        let expectedDelay = Tokens.Motion.featureBaseDelay + Tokens.Motion.maxFeatureStaggerDelay
        let actualDelay = Tokens.Motion.revealDelay(for: 100)

        #expect(abs(actualDelay - expectedDelay) < 0.0001)
    }

    @Test
    func viewConstructsWithSystemBackgroundModifier() {
        _ = self.backgroundView(.system)
    }

    @Test
    func viewConstructsWithSoftGradientBackground() {
        _ = self.backgroundView(.softGradient)
    }

    @Test
    func viewConstructsWithLinearGradientBackground() {
        _ = self.backgroundView(.linearGradient(
            colors: [.blue.opacity(0.18), .mint.opacity(0.12), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing))
    }

    @Test
    func viewConstructsWithAnimatedMeshBackground() {
        _ = self.backgroundView(.animatedMesh())
    }

    @Test
    func viewConstructsWithCustomBackground() {
        _ = self.backgroundView(.custom { context in
            LinearGradient(
                colors: [
                    Color.blue.opacity(context.reduceMotion ? 0.10 : 0.18),
                    Color.purple.opacity(0.12),
                ],
                startPoint: .top,
                endPoint: .bottom)
        })
    }

    @Test
    func footerMaskHeightQuantizesToWholePoints() {
        #expect(FooterMaskMetrics.quantizedHeight(123.4) == 123)
        #expect(FooterMaskMetrics.quantizedHeight(123.5) == 124)
    }

    @Test
    func footerMaskFrameQuantizesPositionAndHeight() {
        let frame = FooterMaskMetrics.quantizedFrame(CGRect(x: 0, y: 612.4, width: 390, height: 127.5))

        #expect(frame.minY == 612)
        #expect(frame.height == 128)
    }

    @Test
    func footerMaskFadeHeightCapsToAvoidEarlyMasking() {
        #expect(FooterMaskMetrics.resolvedFadeHeight(80) == FooterMaskMetrics.maximumFadeHeight)
    }

    @Test
    func footerMaskFadeHeightKeepsShorterValues() {
        #expect(FooterMaskMetrics.resolvedFadeHeight(18) == 18)
        #expect(FooterMaskMetrics.resolvedFadeHeight(0) == 0)
    }

    @Test
    func footerMaskFadeBottomIsHiddenWhenScrollableContentContinues() {
        #expect(FooterMaskMetrics.fadeBottomOpacity(scrollEdgeFadeOpacity: 1) == 0)
    }

    @Test
    func footerMaskFadeBottomIsVisibleAtScrollEnd() {
        #expect(FooterMaskMetrics.fadeBottomOpacity(scrollEdgeFadeOpacity: 0) == 1)
    }

    @Test
    func footerMaskLayoutUsesMeasuredFooterTop() {
        let layout = FooterMaskMetrics.layout(
            containerHeight: 740,
            footerFrame: FooterMaskFrame(minY: 612, height: 128),
            fadeHeight: FooterMaskMetrics.resolvedFadeHeight(80),
            scrollEdgeFadeOpacity: 1)

        #expect(layout.opaqueHeight == 584)
        #expect(layout.fadeHeight == 28)
        #expect(layout.clearHeight == 128)
        #expect(layout.fadeBottomOpacity == 0)
    }

    @Test
    func footerMaskLayoutStaysOpaqueBeforeFooterMeasurement() {
        let layout = FooterMaskMetrics.layout(
            containerHeight: 740,
            footerFrame: .zero,
            fadeHeight: FooterMaskMetrics.resolvedFadeHeight(80),
            scrollEdgeFadeOpacity: 1)

        #expect(layout.opaqueHeight == 740)
        #expect(layout.fadeHeight == 0)
        #expect(layout.clearHeight == 0)
        #expect(layout.fadeBottomOpacity == 1)
    }

    @Test
    func footerMaskContentBottomInsetMatchesMeasuredFooterArea() {
        let inset = FooterMaskMetrics.contentBottomInset(
            containerHeight: 740,
            footerFrame: FooterMaskFrame(minY: 612, height: 128))

        #expect(inset == 128)
    }

    @Test
    func footerMaskContentBottomInsetIsZeroBeforeFooterMeasurement() {
        let inset = FooterMaskMetrics.contentBottomInset(
            containerHeight: 740,
            footerFrame: .zero)

        #expect(inset == 0)
    }

    @Test
    func viewConstructsWithBackgroundAndPrimaryRouteChain() {
        _ = OnboardingView(
            content: BackgroundRouteContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {},
            onPrimaryRoutesComplete: {},
            primaryRouteDestination: { route in
                Text(route.id)
            })
            .onboardingBackground(.animatedMesh())
    }

    @Test
    func viewConstructsWithStandardStyleModifier() {
        _ = self.styledView()
            .onboardingStyle(.standard)
    }

    @Test
    func viewConstructsWithCustomStyleColors() {
        let style = OnboardingStyle(
            tint: .indigo,
            titleColor: .primary,
            subtitleColor: .secondary,
            featureIconColor: .mint,
            featureTitleColor: .primary,
            featureDescriptionColor: .secondary,
            nextStepsTitleColor: .primary,
            nextStepIconColor: .teal,
            nextStepTitleColor: .primary,
            nextStepDescriptionColor: .secondary,
            nextStepActionColor: .indigo,
            nextStepAccessoryColor: .secondary,
            primaryButtonForegroundColor: .white,
            primaryButtonProgressTint: .white,
            secondaryButtonColor: .secondary)

        _ = self.styledView()
            .onboardingBackground(.softGradient)
            .onboardingStyle(style)
    }

    @Test
    func animatedMeshPointsAreStableWithReduceMotion() {
        let first = OnboardingAnimatedMeshGeometry.points(phase: 0, reduceMotion: true)
        let second = OnboardingAnimatedMeshGeometry.points(phase: 0.5, reduceMotion: true)

        #expect(first[4].x == second[4].x)
        #expect(first[4].y == second[4].y)
    }

    @Test
    func animatedMeshPointsChangeAcrossPhases() {
        let first = OnboardingAnimatedMeshGeometry.points(phase: 0, reduceMotion: false)
        let second = OnboardingAnimatedMeshGeometry.points(phase: 0.25, reduceMotion: false)

        #expect(abs(first[4].x - second[4].x) > 0.0001)
    }

    @Test
    func scrollEdgeFadeQuantizesOpacity() {
        let opacity = ScrollEdgeFade.opacity(
            contentHeight: 1_000,
            visibleMaxY: 955,
            fadeHeight: 100)

        #expect(opacity == 0.45)
    }

    @Test
    func scrollEdgeFadeIsOpaqueAtScrollEnd() {
        let opacity = ScrollEdgeFade.opacity(
            contentHeight: 1_000,
            visibleMaxY: 1_000,
            fadeHeight: 100)

        #expect(opacity == 0)
    }

    @Test
    func scrollEdgeFadeIsOpaqueWhenVisibleRectExtendsPastContentEnd() {
        let opacity = ScrollEdgeFade.opacity(
            contentHeight: 1_000,
            visibleMaxY: 1_128,
            fadeHeight: 100)

        #expect(opacity == 0)
    }

    @Test
    func layoutUsesCompactPaddingAtBreakpoint() {
        let padding = LayoutMetrics.horizontalPadding(
            for: 390,
            compact: 16,
            regular: 24,
            breakpoint: 390)

        #expect(padding == 16)
    }

    @Test
    func layoutUsesRegularPaddingAboveBreakpoint() {
        let padding = LayoutMetrics.horizontalPadding(
            for: 391,
            compact: 16,
            regular: 24,
            breakpoint: 390)

        #expect(padding == 24)
    }

    @Test
    func viewConstructsWithPrimaryDestination() {
        struct PrimaryRouteContent: OnboardingContent {
            var title: Text { Text("Primary") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
            }
            var primaryButtonText: Text { Text("Continue") }
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
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
            }
            var primaryRoutes: [OnboardingPrimaryRoute] {
                [
                    OnboardingPrimaryRoute(id: "permissions"),
                    OnboardingPrimaryRoute(id: "sample-data"),
                    OnboardingPrimaryRoute(id: "notifications"),
                ]
            }
            var primaryButtonText: Text { Text("Continue") }
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
    func viewConstructsWithPrimaryRouteChainAndErrorMessage() {
        struct PrimaryRouteErrorContent: OnboardingContent {
            var title: Text { Text("Primary") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
            }
            var primaryRoutes: [OnboardingPrimaryRoute] {
                [OnboardingPrimaryRoute(id: "permissions")]
            }
            var primaryButtonText: Text { Text("Continue") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: PrimaryRouteErrorContent(),
            isLoading: .constant(false),
            errorMessage: .constant("Route failed"),
            onPrimary: {},
            onSkip: {},
            primaryRouteDestination: { route in
                Text(route.id)
            })
    }

    @Test
    func viewConstructsWithBlockingDismissalPolicy() {
        struct BlockingContent: OnboardingContent {
            var title: Text { Text("Blocking") }
            var features: [OnboardingFeatureItem] {
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
            }
            var primaryButtonText: Text { Text("Continue") }
            var errorAlertTitle: Text { Text("Error") }
            var errorOKText: Text { Text("OK") }
        }

        _ = OnboardingView(
            content: BlockingContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            allowsInteractiveDismissal: false,
            onPrimary: {},
            onSkip: {})
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
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
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
                [OnboardingFeatureItem(id: "one-feature", description: Text("One feature."))]
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
                        id: "feature-\(index)",
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
                    OnboardingFeatureItem(id: "first", description: Text("First computed feature.")),
                    OnboardingFeatureItem(id: "second", description: Text("Second computed feature.")),
                    OnboardingFeatureItem(id: "third", description: Text("Third computed feature.")),
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
                [OnboardingFeatureItem(id: "state", description: Text("State feature."))]
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

    private func backgroundView(_ background: OnboardingBackground) -> some View {
        self.styledView()
            .onboardingBackground(background)
    }

    private func styledView() -> OnboardingView<BackgroundContent> {
        OnboardingView(
            content: BackgroundContent(),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onPrimary: {},
            onSkip: {})
    }
}

private struct BackgroundContent: OnboardingContent {
    var title: Text { Text("Background") }
    var features: [OnboardingFeatureItem] {
        [OnboardingFeatureItem(id: "background-feature", description: Text("Background feature."))]
    }
    var primaryButtonText: Text { Text("Continue") }
    var errorAlertTitle: Text { Text("Error") }
    var errorOKText: Text { Text("OK") }
}

private struct BackgroundRouteContent: OnboardingContent {
    var title: Text { Text("Background route") }
    var features: [OnboardingFeatureItem] {
        [OnboardingFeatureItem(id: "background-route-feature", description: Text("Background route feature."))]
    }
    var primaryRoutes: [OnboardingPrimaryRoute] {
        [
            OnboardingPrimaryRoute(id: "first-route"),
            OnboardingPrimaryRoute(id: "second-route"),
        ]
    }
    var primaryButtonText: Text { Text("Continue") }
    var errorAlertTitle: Text { Text("Error") }
    var errorOKText: Text { Text("OK") }
}
#endif
