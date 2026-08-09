#if os(iOS) || os(macOS)
import SwiftUI

public struct GreetView<Content: GreetContent>: View {
    let content: Content
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let allowsInteractiveDismissal: Bool
    private var background: GreetBackground = .system
    private var style: GreetStyle = .standard
    let onPrimary: () -> Void
    let onSkip: () -> Void
    let primaryDestination: (() -> AnyView)?
    let primaryRouteDestination: ((GreetPrimaryRoute) -> AnyView)?
    let onPrimaryRoutesComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.colorScheme) private var colorScheme
    @State private var featuresVisible = false
    @State private var routeState = GreetRouteState()
    @State private var containerWidth: CGFloat = Tokens.Platform.assumedContainerWidth

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = Tokens.Platform.iconSize
    @ScaledMetric(relativeTo: .body) private var featureIconSize: CGFloat = Tokens.Platform.featureIconSize
    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var featureSpacing: CGFloat = Tokens.Platform.featureSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding

    public init(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.primaryDestination = nil
        self.primaryRouteDestination = nil
        self.onPrimaryRoutesComplete = {}
    }

    public init<PrimaryDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        @ViewBuilder primaryDestination: @escaping () -> PrimaryDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.primaryDestination = { AnyView(primaryDestination()) }
        self.primaryRouteDestination = nil
        self.onPrimaryRoutesComplete = {}
    }

    public init<PrimaryRouteDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onPrimaryRoutesComplete: @escaping () -> Void = {},
        @ViewBuilder primaryRouteDestination: @escaping (GreetPrimaryRoute) -> PrimaryRouteDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.primaryDestination = nil
        self.primaryRouteDestination = { AnyView(primaryRouteDestination($0)) }
        self.onPrimaryRoutesComplete = onPrimaryRoutesComplete
    }

    public var body: some View {
        self.greetContent
            .greetTint(self.style.tint)
            .alert(
                self.content.errorAlertTitle,
                isPresented: self.errorPresented,
                actions: {
                    Button(role: .cancel) {
                        self.errorMessage = nil
                    } label: {
                        self.content.errorOKText
                    }
                },
                message: {
                    if let message = self.errorMessage {
                        Text(message)
                    }
                })
            .interactiveDismissDisabled(!self.allowsInteractiveDismissal)
    }

    public func greetBackground(_ background: GreetBackground) -> Self {
        var view = self
        view.background = background
        return view
    }

    public func greetStyle(_ style: GreetStyle) -> Self {
        var view = self
        view.style = style
        return view
    }

    private var greetContent: some View {
        ZStack {
            GreetBackgroundView(
                background: self.background,
                reduceMotion: self.reduceMotion,
                reduceTransparency: self.reduceTransparency,
                colorSchemeContrast: self.colorSchemeContrast,
                brandColor: self.style.tint,
                colorScheme: self.colorScheme)

            ZStack {
                if let activeRoute = self.routeState.activeRoute(in: self.content.primaryRoutes),
                   let primaryRouteDestination = self.primaryRouteDestination
                {
                    GreetPrimaryRouteDestinationContainer(
                        content: self.content,
                        destination: primaryRouteDestination(activeRoute.route),
                        index: activeRoute.index,
                        count: self.content.primaryRoutes.count,
                        onNext: {
                            self.routeState.advance(after: activeRoute.index, in: self.content.primaryRoutes)
                        },
                        onDone: self.completePrimaryRoutes)
                        .id("primary-route-\(activeRoute.route.id)")
                        .transition(self.routeTransition)
                } else if self.routeState.showsSingleDestination, let primaryDestination = self.primaryDestination {
                    GreetPrimaryDestinationContainer(
                        destination: primaryDestination())
                        .id("primary-destination")
                        .transition(self.routeTransition)
                } else {
                    self.greetOverview
                        .id("overview")
                        .transition(self.routeTransition)
                }
            }
            .animation(self.routeAnimation, value: self.primaryRoutePhaseID)
        }
        .clipped()
        .greetScrollIndicators()
    }

    private var greetOverview: some View {
        ScrollView(.vertical) {
            VStack(spacing: self.contentSpacing) {
                GreetHeaderSection(
                    content: self.content,
                    iconSize: self.iconSize)
                GreetFeatureList(
                    features: self.content.features,
                    featureSpacing: self.featureSpacing,
                    featureIconSize: self.featureIconSize,
                    featuresVisible: self.featuresVisible,
                    reduceMotion: self.reduceMotion)
            }
            // Mac users expect to be able to select and copy this copy out of a window.
            .textSelection(.enabled)
            .frame(maxWidth: Tokens.Layout.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .greetHorizontalPadding(containerWidth: self.containerWidth)
            .padding(.top, self.topPadding)
            .padding(.bottom, self.bottomPadding)
        }
        .greetScrollIndicators()
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaBar(edge: .bottom) {
            GreetFooterSection(
                content: self.content,
                isLoading: self.isLoading,
                allowsCancelShortcut: GreetKeyboardPolicy.allowsCancelShortcut(
                    hasSkipButton: self.content.skipButtonText != nil,
                    allowsInteractiveDismissal: self.allowsInteractiveDismissal),
                onPrimary: self.performPrimaryAction,
                onSkip: self.onSkip)
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .greetHorizontalPadding(containerWidth: self.containerWidth)
                .frame(maxWidth: .infinity)
        }
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .greetContainerWidth(self.$containerWidth)
        #if os(macOS)
            .frame(
                minWidth: Tokens.Platform.sheetMinWidth,
                idealWidth: Tokens.Platform.sheetIdealWidth,
                minHeight: Tokens.Platform.sheetMinHeight,
                idealHeight: Tokens.Platform.sheetIdealHeight)
        #endif
            .onAppear {
                self.featuresVisible = true
            }
    }

    private func performPrimaryAction() {
        self.onPrimary()

        self.routeState.begin(
            routes: self.content.primaryRoutes,
            hasRouteDestination: self.primaryRouteDestination != nil,
            hasSingleDestination: self.primaryDestination != nil)
    }

    private func completePrimaryRoutes() {
        self.onPrimaryRoutesComplete()
        self.routeState.complete()
    }

    private var routeTransition: AnyTransition {
        guard !self.reduceMotion else {
            return .opacity
        }

        switch self.routeState.transitionDirection {
        case .forward:
            return .push(from: .trailing)
        case .backward:
            return .push(from: .leading)
        }
    }

    private var routeAnimation: Animation? {
        self.reduceMotion ? nil : .smooth(duration: Tokens.Motion.routeTransitionDuration)
    }

    private var primaryRoutePhaseID: String {
        self.routeState.phaseID(in: self.content.primaryRoutes)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { newValue in
                if !newValue { self.errorMessage = nil }
            })
    }
}

/// Decides whether Escape may stand in for the skip action.
///
/// Escape fires `onSkip`, which is a real caller callback rather than a plain dismissal, so it is
/// only bound where the skip button is actually on screen and dismissal is allowed. That keeps the
/// keyboard from triggering something the person cannot see, and keeps blocking setup flows
/// blocking.
enum GreetKeyboardPolicy {
    static func allowsCancelShortcut(hasSkipButton: Bool, allowsInteractiveDismissal: Bool) -> Bool {
        hasSkipButton && allowsInteractiveDismissal
    }
}

enum LayoutMetrics {
    static func horizontalPadding(
        for width: CGFloat,
        compact: CGFloat,
        regular: CGFloat,
        breakpoint: CGFloat) -> CGFloat
    {
        width <= breakpoint ? compact : regular
    }
}

private struct GreetBackgroundView: View {
    let background: GreetBackground
    let reduceMotion: Bool
    let reduceTransparency: Bool
    let colorSchemeContrast: ColorSchemeContrast
    let brandColor: Color?
    let colorScheme: ColorScheme

    var body: some View {
        self.background
            .makeView(context: GreetBackgroundContext(
                reduceMotion: self.reduceMotion,
                reduceTransparency: self.reduceTransparency,
                colorSchemeContrast: self.colorSchemeContrast,
                brandColor: self.brandColor,
                colorScheme: self.colorScheme))
            .ignoresSafeArea()
    }
}

private struct GreetPrimaryDestinationContainer<Destination: View>: View {
    let destination: Destination

    var body: some View {
        VStack(spacing: 0) {
            self.destination
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #if os(macOS)
            .frame(
                minWidth: Tokens.Platform.sheetMinWidth,
                idealWidth: Tokens.Platform.sheetIdealWidth,
                minHeight: Tokens.Platform.sheetMinHeight,
                idealHeight: Tokens.Platform.sheetIdealHeight)
        #endif
    }
}

private struct GreetPrimaryRouteDestinationContainer<Content: GreetContent, Destination: View>: View {
    let content: Content
    let destination: Destination
    let index: Int
    let count: Int
    let onNext: () -> Void
    let onDone: () -> Void

    @State private var containerWidth: CGFloat = Tokens.Platform.assumedContainerWidth

    var body: some View {
        self.destination
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaBar(edge: .bottom) {
                GreetPrimaryButton(
                    label: self.primaryButtonText,
                    action: {
                        self.isLastRoute ? self.onDone() : self.onNext()
                    })
                    .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                    .greetHorizontalPadding(containerWidth: self.containerWidth)
                    .padding(.top, Tokens.Layout.footerTopPadding)
                    .padding(.bottom, Tokens.Layout.footerBottomPadding)
                    .frame(maxWidth: .infinity)
            }
            .greetContainerWidth(self.$containerWidth)
        #if os(macOS)
            .frame(
                minWidth: Tokens.Platform.sheetMinWidth,
                idealWidth: Tokens.Platform.sheetIdealWidth,
                minHeight: Tokens.Platform.sheetMinHeight,
                idealHeight: Tokens.Platform.sheetIdealHeight)
        #endif
    }

    private var isLastRoute: Bool {
        self.index >= self.count - 1
    }

    private var primaryButtonText: Text {
        self.isLastRoute ? self.content.primaryRouteDoneButtonText : self.content.primaryRouteNextButtonText
    }
}

private struct GreetHeaderSection<Content: GreetContent>: View {
    let content: Content
    let iconSize: CGFloat

    var body: some View {
        VStack(spacing: Tokens.Spacing.large) {
            if let appIcon = self.content.appIcon {
                appIcon
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.iconSize, height: self.iconSize)
                    .clipShape(.rect(
                        cornerRadius: self.iconSize * Tokens.Radius.iconScale,
                        style: .continuous))
                    .accessibilityHidden(true)
            }

            self.content.title
            #if os(macOS)
                .font(.title)
            #else
                .font(.largeTitle)
            #endif
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let subtitle = self.content.subtitle {
                subtitle
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct GreetFeatureList: View {
    let features: [GreetFeatureItem]
    let featureSpacing: CGFloat
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: self.featureSpacing) {
            ForEach(Array(self.features.enumerated()), id: \.element.id) { index, feature in
                GreetFeatureRow(
                    feature: feature,
                    index: index,
                    featureIconSize: self.featureIconSize,
                    featuresVisible: self.featuresVisible,
                    reduceMotion: self.reduceMotion)
            }
        }
    }
}

private struct GreetFeatureRow: View {
    let feature: GreetFeatureItem
    let index: Int
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool

    var body: some View {
        let delay = Tokens.Motion.revealDelay(for: self.index)
        let isVisible = self.featuresVisible

        HStack(alignment: .top, spacing: Tokens.Spacing.large) {
            if let image = self.feature.image {
                image
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: self.featureIconSize, height: self.featureIconSize)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let label = self.feature.label {
                    label
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                self.feature.description
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        // Scoped to the two modifiers that do the revealing, and nothing else.
        //
        // `.animation(_:value:)` only controls *when* an animation fires; it still animates every
        // animatable difference in the subtree at that moment. So anything else settling on the
        // same frame — a `@ScaledMetric` resolving, the description rewrapping — got swept into
        // the reveal's transaction and animated with the row's delay, which read as the text
        // jumping and shaking before it landed. The body form animates only what it wraps, so
        // layout that settles underneath applies instantly and invisibly.
        //
        // Ease-in-out, not a spring: this is a one-shot entrance nothing can interrupt, and a
        // spring's asymptotic tail reads as the row drifting after it has visually arrived. The
        // eased onset matters as much as the eased landing — ease-out starts at full speed, which
        // makes a row snap into motion the instant its delay expires.
        .animation(self.revealAnimation(delay: delay)) { content in
            content
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : self.revealOffset)
        }
    }

    private var revealOffset: CGFloat {
        self.reduceMotion ? 0 : Tokens.Motion.revealOffset
    }

    private func revealAnimation(delay: Double) -> Animation? {
        guard !self.reduceMotion else {
            return nil
        }

        return .easeInOut(duration: Tokens.Motion.revealDuration).delay(delay)
    }
}

/// The primary action shared by the overview footer and the route destinations.
///
/// Uses the system prominent glass button so press, hover, focus, and the disabled and
/// high-contrast treatments all come from the platform. The surrounding `GreetView` applies
/// `GreetStyle.tint`, which is what colours the button.
///
/// Pass `loading` only where the button can actually enter a loading state; route
/// destinations leave it `nil` so no progress affordance is built at all.
private struct GreetPrimaryButton: View {
    struct Loading {
        let isLoading: Bool
        let accessibilityValue: Text
    }

    let label: Text
    var loading: Loading?
    let action: () -> Void

    @State private var activationCount = 0

    var body: some View {
        Button {
            #if os(iOS)
                // Only iOS reads this; mutating it elsewhere buys a render pass on every click
                // for nothing.
                self.activationCount += 1
            #endif
            self.action()
        } label: {
            self.labelContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(self.label)
                // Applied unconditionally. A `@ViewBuilder` branch here would swap the label's
                // structural identity the instant `isLoading` flips — which is the instant of the
                // click — so SwiftUI would tear down and rebuild the label subtree while the glass
                // button was still animating its press. That reads as the button stuttering.
                .accessibilityValue(self.accessibilityValue)
        }
        .greetPrimarySensoryFeedback(trigger: self.activationCount)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .buttonSizing(.flexible)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
        .disabled(self.isLoading)
    }

    private var isLoading: Bool {
        self.loading?.isLoading ?? false
    }

    /// Empty rather than absent when idle, so the modifier is always present and the label keeps
    /// one identity across the loading flip.
    private var accessibilityValue: Text {
        guard self.isLoading, let loading = self.loading else {
            return Text(verbatim: "")
        }

        return loading.accessibilityValue
    }

    /// Cross-fades the label and the progress indicator in place, with the label alone deciding
    /// the size.
    ///
    /// The spinner is an overlay rather than a sibling in a stack, and that is load-bearing. A
    /// stack sizes to `max(label, spinner)`, and an indeterminate `ProgressView` reports a size
    /// that varies by a fraction of a point as it animates. Those two heights are close enough
    /// that the max flipped between them every frame, so the button, the footer, and the whole
    /// `safeAreaBar` re-measured continuously — over 11,000 times a minute, swinging a full point
    /// — while the button's own body never re-evaluated. Pure layout churn, and the reason the
    /// button looked like jelly while loading. An overlay takes its size from what it covers and
    /// contributes nothing back.
    @ViewBuilder
    private var labelContent: some View {
        if self.loading != nil {
            self.styledLabel
                .opacity(self.isLoading ? 0 : 1)
                .overlay {
                    ProgressView()
                        .controlSize(.small)
                        .opacity(self.isLoading ? 1 : 0)
                }
        } else {
            self.styledLabel
        }
    }

    private var styledLabel: some View {
        self.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct GreetFooterSection<Content: GreetContent>: View {
    let content: Content
    let isLoading: Bool
    let allowsCancelShortcut: Bool
    let onPrimary: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Layout.footerControlSpacing) {
            GreetPrimaryButton(
                label: self.content.primaryButtonText,
                loading: GreetPrimaryButton.Loading(
                    isLoading: self.isLoading,
                    accessibilityValue: self.content.primaryButtonLoadingAccessibilityValue),
                action: self.onPrimary)

            if let skipText = self.content.skipButtonText {
                Button {
                    self.onSkip()
                } label: {
                    skipText
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: Tokens.Platform.minimumControlHeight,
                            alignment: .top)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .greetLinkPointer()
                .greetCancelShortcut(self.allowsCancelShortcut)
                .disabled(self.isLoading)
            }
        }
        .padding(.top, Tokens.Layout.footerTopPadding)
        .padding(.bottom, Tokens.Layout.footerBottomPadding)
    }
}

/// Applies the compact or regular horizontal padding for a container width.
///
/// Lives in a modifier so the two `@ScaledMetric` values behind it are declared once.
private struct GreetHorizontalPadding: ViewModifier {
    let containerWidth: CGFloat

    @ScaledMetric(relativeTo: .body) private var compactPadding: CGFloat = Tokens.Layout.compactHorizontalPadding
    @ScaledMetric(relativeTo: .body) private var regularPadding: CGFloat = Tokens.Layout.regularHorizontalPadding

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, LayoutMetrics.horizontalPadding(
                for: self.containerWidth,
                compact: self.compactPadding,
                regular: self.regularPadding,
                breakpoint: Tokens.Layout.compactWidthBreakpoint))
    }
}

private extension View {
    func greetHorizontalPadding(containerWidth: CGFloat) -> some View {
        self.modifier(GreetHorizontalPadding(containerWidth: containerWidth))
    }

    /// Hides the scroll indicator on iOS, where the scroll edge effect and a swipe carry the
    /// affordance, and keeps the system scroller on macOS, where it is how a window tells you
    /// there is more below.
    @ViewBuilder
    func greetScrollIndicators() -> some View {
        #if os(macOS)
            self.scrollIndicators(.automatic, axes: .vertical)
        #else
            self.scrollIndicators(.never, axes: .vertical)
        #endif
    }

    /// Publishes the receiver's width so `greetHorizontalPadding(containerWidth:)` can pick a
    /// breakpoint without a `GeometryReader` claiming the offered size.
    func greetContainerWidth(_ width: Binding<CGFloat>) -> some View {
        self.onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { newWidth in
            if width.wrappedValue != newWidth {
                width.wrappedValue = newWidth
            }
        }
    }

    @ViewBuilder
    func greetTint(_ color: Color?) -> some View {
        if let color {
            self.tint(color)
        } else {
            self
        }
    }

    /// Confirms the primary action with a light impact on iOS.
    ///
    /// The primary button commits the person to setup, which is the one moment in this sheet
    /// worth a haptic. The skip button deliberately gets none. Macs are left alone — a click
    /// there is not conventionally answered with feedback.
    @ViewBuilder
    func greetPrimarySensoryFeedback(trigger: Int) -> some View {
        #if os(iOS)
            self.sensoryFeedback(.impact, trigger: trigger)
        #else
            self
        #endif
    }

    /// Gives the borderless skip button a pointer cue on macOS.
    ///
    /// The primary button gets hover from `.glassProminent`, but a plain text button has nothing
    /// to tell a Mac user it is clickable until the pointer changes over it.
    @ViewBuilder
    func greetLinkPointer() -> some View {
        #if os(macOS)
            self.pointerStyle(.link)
        #else
            self
        #endif
    }

    @ViewBuilder
    func greetCancelShortcut(_ isEnabled: Bool) -> some View {
        if isEnabled {
            self.keyboardShortcut(.cancelAction)
        } else {
            self
        }
    }

}

private struct GreetPreviewContent: GreetContent {
    var appIcon: Image? { Image(systemName: "app.gift.fill") }
    var title: Text { Text("Welcome") }
    var subtitle: Text? { Text("Here's what makes this app great.") }
    var features: [GreetFeatureItem] {
        [
            GreetFeatureItem(
                id: "tap-to-flip",
                systemImage: "hand.tap.fill",
                label: "Tap to flip",
                description: "Review cards with a simple tap."),
            GreetFeatureItem(
                id: "organize",
                systemImage: "folder.fill",
                label: "Organize",
                description: "Group cards into decks and folders."),
            GreetFeatureItem(
                id: "spaced-repetition",
                systemImage: "brain.head.profile.fill",
                label: "Spaced repetition",
                description: "Study smarter, not harder."),
        ]
    }
    var primaryRoutes: [GreetPrimaryRoute] {
        [
            GreetPrimaryRoute(id: "permissions"),
            GreetPrimaryRoute(id: "sample-data"),
            GreetPrimaryRoute(id: "notifications"),
        ]
    }
    var primaryButtonText: Text { Text("Get started") }
    var primaryRouteDoneButtonText: Text { Text("Finish") }
    var skipButtonText: Text? { Text("Skip for now") }
    var errorAlertTitle: Text { Text("Something went wrong") }
    var errorOKText: Text { Text("OK") }
}

private struct LongGreetPreviewContent: GreetContent {
    var appIcon: Image? { Image(systemName: "rectangle.stack.badge.plus.fill") }
    var title: Text {
        Text("A much longer greet title that must wrap cleanly")
    }
    var subtitle: Text? {
        Text("This subtitle is intentionally longer so narrow presentations and larger Dynamic Type sizes still have room to breathe.")
    }
    var features: [GreetFeatureItem] {
        (1...12).map { index in
            GreetFeatureItem(
                id: "long-feature-\(index)",
                systemImage: "checkmark.circle.fill",
                label: "Greet feature \(index) with a longer localized label",
                description: "This greet description is long enough to wrap over multiple lines while keeping the icon, text, and action area stable.")
        }
    }
    var primaryButtonText: Text {
        Text("Get started with all sample data and preferences")
    }
    var skipButtonText: Text? {
        Text("Skip this longer greet flow for now")
    }
    var errorAlertTitle: Text { Text("Something went wrong") }
    var errorOKText: Text { Text("OK") }
}

#Preview("Greet") {
    @Previewable @State var isLoading = false
    @Previewable @State var errorMessage: String?

    GreetView(
        content: GreetPreviewContent(),
        isLoading: $isLoading,
        errorMessage: $errorMessage,
        onPrimary: {},
        onSkip: {},
        onPrimaryRoutesComplete: {
            isLoading = false
        },
        primaryRouteDestination: { route in
            GreetPrimaryRoutePreviewDestination(route: route)
        })
}

#Preview("Greet Soft Gradient") {
    GreetView(
        content: GreetPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            GreetPrimaryRoutePreviewDestination(route: route)
        })
        .greetBackground(.softGradient)
        .frame(width: 390, height: 740)
}

#Preview("Greet Animated Background") {
    GreetView(
        content: GreetPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            GreetPrimaryRoutePreviewDestination(route: route)
        })
        .greetBackground(.animatedGradient())
        .frame(width: 390, height: 740)
}

#Preview("Greet Long Narrow") {
    GreetView(
        content: LongGreetPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            GreetPrimaryRoutePreviewDestination(route: route)
        })
        .frame(width: 320, height: 760)
}

#Preview("Greet Loading") {
    GreetView(
        content: GreetPreviewContent(),
        isLoading: .constant(true),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            GreetPrimaryRoutePreviewDestination(route: route)
        })
        .frame(width: 390, height: 740)
}

#Preview("Greet Dark Accessibility") {
    GreetView(
        content: LongGreetPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            GreetPrimaryRoutePreviewDestination(route: route)
        })
        .frame(width: 390, height: 780)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}

private struct GreetPrimaryRoutePreviewDestination: View {
    let route: GreetPrimaryRoute

    var body: some View {
        VStack(spacing: Tokens.Spacing.large) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .frame(width: 72, height: 72)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            self.title
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            self.description
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: Tokens.Layout.contentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Tokens.Spacing.xLarge)
    }

    private var title: Text {
        switch self.route.id {
        case "permissions":
            Text("Enable permissions")
        case "sample-data":
            Text("Create sample data")
        case "notifications":
            Text("Set reminders")
        default:
            Text("Primary Route")
        }
    }

    private var description: Text {
        switch self.route.id {
        case "permissions":
            Text("Ask for access at the moment it makes sense and explain why it helps.")
        case "sample-data":
            Text("Prepare starter content so users can try the app immediately.")
        case "notifications":
            Text("Offer a final setup step before completing greet.")
        default:
            Text("The primary button can slide through chained follow-up routes inside the same sheet.")
        }
    }
}
#endif
