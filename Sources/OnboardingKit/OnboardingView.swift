#if os(iOS) || os(macOS)
import SwiftUI

public struct OnboardingView<Content: OnboardingContent>: View {
    let content: Content
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let allowsInteractiveDismissal: Bool
    private var background: OnboardingBackground = .system
    private var style: OnboardingStyle = .standard
    let onPrimary: () -> Void
    let onSkip: () -> Void
    let onNextStep: (OnboardingNextStepItem) -> Void
    let primaryDestination: (() -> AnyView)?
    let primaryRouteDestination: ((OnboardingPrimaryRoute) -> AnyView)?
    let onPrimaryRoutesComplete: () -> Void
    let nextStepDestination: ((OnboardingNextStepItem) -> AnyView)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var featuresVisible = false
    @State private var scrollEdgeFadeOpacity: Double = 1
    @State private var pushedNextSteps: [PresentedOnboardingNextStep] = []
    @State private var sheetNextStep: PresentedOnboardingNextStep?
    @State private var activePrimaryDestination = false
    @State private var activePrimaryRouteID: OnboardingPrimaryRoute.ID?
    @State private var routeTransitionDirection: OnboardingRouteTransitionDirection = .forward
    @State private var footerHeight: CGFloat = 0

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = Tokens.Platform.iconSize
    @ScaledMetric(relativeTo: .body) private var featureIconSize: CGFloat = Tokens.Platform.featureIconSize
    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var featureSpacing: CGFloat = Tokens.Platform.featureSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding
    @ScaledMetric(relativeTo: .body) private var scrollEdgeFadeHeight: CGFloat = Tokens.Platform.scrollEdgeFadeHeight
    @ScaledMetric(relativeTo: .body) private var compactHorizontalPadding: CGFloat = Tokens.Layout.compactHorizontalPadding
    @ScaledMetric(relativeTo: .body) private var regularHorizontalPadding: CGFloat = Tokens.Layout.regularHorizontalPadding

    public init(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in })
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.onNextStep = onNextStep
        self.primaryDestination = nil
        self.primaryRouteDestination = nil
        self.onPrimaryRoutesComplete = {}
        self.nextStepDestination = nil
    }

    public init<PrimaryDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        @ViewBuilder primaryDestination: @escaping () -> PrimaryDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.onNextStep = onNextStep
        self.primaryDestination = { AnyView(primaryDestination()) }
        self.primaryRouteDestination = nil
        self.onPrimaryRoutesComplete = {}
        self.nextStepDestination = nil
    }

    public init<PrimaryRouteDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        onPrimaryRoutesComplete: @escaping () -> Void = {},
        @ViewBuilder primaryRouteDestination: @escaping (OnboardingPrimaryRoute) -> PrimaryRouteDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.onNextStep = onNextStep
        self.primaryDestination = nil
        self.primaryRouteDestination = { AnyView(primaryRouteDestination($0)) }
        self.onPrimaryRoutesComplete = onPrimaryRoutesComplete
        self.nextStepDestination = nil
    }

    public init<NextStepDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        @ViewBuilder nextStepDestination: @escaping (OnboardingNextStepItem) -> NextStepDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.onNextStep = onNextStep
        self.primaryDestination = nil
        self.primaryRouteDestination = nil
        self.onPrimaryRoutesComplete = {}
        self.nextStepDestination = { AnyView(nextStepDestination($0)) }
    }

    public init<PrimaryDestination: View, NextStepDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        @ViewBuilder primaryDestination: @escaping () -> PrimaryDestination,
        @ViewBuilder nextStepDestination: @escaping (OnboardingNextStepItem) -> NextStepDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.onNextStep = onNextStep
        self.primaryDestination = { AnyView(primaryDestination()) }
        self.primaryRouteDestination = nil
        self.onPrimaryRoutesComplete = {}
        self.nextStepDestination = { AnyView(nextStepDestination($0)) }
    }

    public init<PrimaryRouteDestination: View, NextStepDestination: View>(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        allowsInteractiveDismissal: Bool = true,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        onPrimaryRoutesComplete: @escaping () -> Void = {},
        @ViewBuilder primaryRouteDestination: @escaping (OnboardingPrimaryRoute) -> PrimaryRouteDestination,
        @ViewBuilder nextStepDestination: @escaping (OnboardingNextStepItem) -> NextStepDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
        self.onPrimary = onPrimary
        self.onSkip = onSkip
        self.onNextStep = onNextStep
        self.primaryDestination = nil
        self.primaryRouteDestination = { AnyView(primaryRouteDestination($0)) }
        self.onPrimaryRoutesComplete = onPrimaryRoutesComplete
        self.nextStepDestination = { AnyView(nextStepDestination($0)) }
    }

    public var body: some View {
        Group {
            if self.nextStepDestination == nil {
                self.onboardingContent
            } else {
                NavigationStack(path: self.$pushedNextSteps) {
                    self.onboardingContent
                        .navigationDestination(for: PresentedOnboardingNextStep.self) { presentedStep in
                            self.nextStepDestination(for: presentedStep.step)
                        }
                }
            }
        }
        .onboardingTint(self.style.tint)
        .sheet(item: self.$sheetNextStep) { presentedStep in
            NavigationStack {
                self.nextStepDestination(for: presentedStep.step)
            }
        }
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

    public func onboardingBackground(_ background: OnboardingBackground) -> Self {
        var view = self
        view.background = background
        return view
    }

    public func onboardingStyle(_ style: OnboardingStyle) -> Self {
        var view = self
        view.style = style
        return view
    }

    private var onboardingContent: some View {
        ZStack {
            OnboardingBackgroundView(
                background: self.background,
                reduceMotion: self.reduceMotion)

            ZStack {
                if let activePrimaryRoute = self.activePrimaryRoute,
                   let primaryRouteDestination = self.primaryRouteDestination
                {
                    OnboardingPrimaryRouteDestinationContainer(
                        content: self.content,
                        background: self.background,
                        style: self.style,
                        destination: primaryRouteDestination(activePrimaryRoute.route),
                        index: activePrimaryRoute.index,
                        count: self.content.primaryRoutes.count,
                        onNext: {
                            self.openPrimaryRoute(after: activePrimaryRoute.index)
                        },
                        onDone: self.completePrimaryRoutes)
                        .id("primary-route-\(activePrimaryRoute.route.id)")
                        .transition(self.routeTransition)
                } else if self.activePrimaryDestination, let primaryDestination = self.primaryDestination {
                    OnboardingPrimaryDestinationContainer(
                        destination: primaryDestination())
                        .id("primary-destination")
                        .transition(self.routeTransition)
                } else {
                    self.onboardingOverview
                        .id("overview")
                        .transition(self.routeTransition)
                }
            }
            .animation(self.routeAnimation, value: self.primaryRoutePhaseID)
        }
        .clipped()
    }

    private var onboardingOverview: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: self.contentSpacing) {
                    OnboardingHeaderSection(
                        content: self.content,
                        iconSize: self.iconSize,
                        style: self.style)
                    OnboardingFeatureList(
                        features: self.content.features,
                        featureSpacing: self.featureSpacing,
                        featureIconSize: self.featureIconSize,
                        featuresVisible: self.featuresVisible,
                        reduceMotion: self.reduceMotion,
                        style: self.style)
                    OnboardingNextStepsSection(
                        title: self.content.nextStepsTitle,
                        steps: self.content.nextSteps,
                        featureIconSize: self.featureIconSize,
                        animationStartIndex: self.content.features.count,
                        itemsVisible: self.featuresVisible,
                        reduceMotion: self.reduceMotion,
                        isLoading: self.isLoading,
                        hasDestination: self.nextStepDestination != nil,
                        style: self.style,
                        onNextStep: self.selectNextStep)
                }
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.horizontalPadding(for: geometry.size.width))
                .padding(.top, self.topPadding)
                .padding(.bottom, self.bottomPadding)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: Double.self) { geometry in
                ScrollEdgeFade.opacity(
                    contentHeight: geometry.contentSize.height,
                    contentBottomInset: geometry.contentInsets.bottom,
                    visibleMaxY: geometry.visibleRect.maxY,
                    fadeHeight: self.scrollEdgeFadeHeight)
            } action: { _, newOpacity in
                if self.scrollEdgeFadeOpacity != newOpacity {
                    self.scrollEdgeFadeOpacity = newOpacity
                }
            }
            .mask {
                FooterContentMask(
                    footerHeight: self.footerHeight,
                    fadeHeight: self.scrollEdgeFadeHeight,
                    scrollEdgeFadeOpacity: self.scrollEdgeFadeOpacity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ZStack {
                    OnboardingFooterSection(
                        content: self.content,
                        isLoading: self.isLoading,
                        style: self.style,
                        onPrimary: self.performPrimaryAction,
                        onSkip: self.onSkip)
                        .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                        .padding(.horizontal, self.horizontalPadding(for: geometry.size.width))
                }
                .onGeometryChange(for: CGFloat.self) { geometry in
                    FooterMaskMetrics.quantizedHeight(geometry.size.height)
                } action: { newHeight in
                    if self.footerHeight != newHeight {
                        self.footerHeight = newHeight
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        #if os(macOS)
            .frame(minWidth: Tokens.Layout.compactSheetMinWidth, minHeight: 620)
        #endif
            .onAppear {
                self.featuresVisible = true
            }
    }

    private func selectNextStep(_ step: OnboardingNextStepItem) {
        self.onNextStep(step)

        guard self.nextStepDestination != nil else {
            return
        }

        let presentedStep = PresentedOnboardingNextStep(step: step)
        switch step.presentation {
        case .push:
            guard self.pushedNextSteps.last?.id != presentedStep.id else {
                return
            }
            self.pushedNextSteps.append(presentedStep)
        case .sheet:
            self.sheetNextStep = presentedStep
        }
    }

    private func performPrimaryAction() {
        self.onPrimary()

        if self.primaryRouteDestination != nil, !self.content.primaryRoutes.isEmpty {
            self.routeTransitionDirection = .forward
            withAnimation(self.routeAnimation) {
                self.activePrimaryDestination = false
                self.activePrimaryRouteID = self.content.primaryRoutes.first?.id
            }
            return
        }

        guard self.primaryDestination != nil else {
            return
        }

        self.routeTransitionDirection = .forward
        withAnimation(self.routeAnimation) {
            self.activePrimaryDestination = true
        }
    }

    @ViewBuilder
    private func nextStepDestination(for step: OnboardingNextStepItem) -> some View {
        if let nextStepDestination = self.nextStepDestination {
            nextStepDestination(step)
        } else {
            EmptyView()
        }
    }

    private func openPrimaryRoute(after index: Int) {
        let nextIndex = index + 1
        guard self.content.primaryRoutes.indices.contains(nextIndex) else {
            self.completePrimaryRoutes()
            return
        }

        self.routeTransitionDirection = .forward
        withAnimation(self.routeAnimation) {
            self.activePrimaryRouteID = self.content.primaryRoutes[nextIndex].id
        }
    }

    private func completePrimaryRoutes() {
        self.onPrimaryRoutesComplete()
        self.routeTransitionDirection = .backward
        withAnimation(self.routeAnimation) {
            self.activePrimaryRouteID = nil
        }
    }

    private var activePrimaryRoute: (index: Int, route: OnboardingPrimaryRoute)? {
        guard let activePrimaryRouteID else {
            return nil
        }

        guard let index = self.content.primaryRoutes.firstIndex(where: { $0.id == activePrimaryRouteID }) else {
            return nil
        }

        return (index, self.content.primaryRoutes[index])
    }

    private var routeTransition: AnyTransition {
        guard !self.reduceMotion else {
            return .opacity
        }

        switch self.routeTransitionDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity))
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity))
        }
    }

    private var routeAnimation: Animation? {
        self.reduceMotion ? nil : .easeInOut(duration: Tokens.Motion.routeTransitionDuration)
    }

    private var primaryRoutePhaseID: String {
        if let activePrimaryRouteID = self.activePrimaryRouteID {
            return "route-\(activePrimaryRouteID)"
        }

        return self.activePrimaryDestination ? "single" : "overview"
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        LayoutMetrics.horizontalPadding(
            for: width,
            compact: self.compactHorizontalPadding,
            regular: self.regularHorizontalPadding,
            breakpoint: Tokens.Layout.compactWidthBreakpoint)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { newValue in
                if !newValue { self.errorMessage = nil }
            })
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

enum ScrollEdgeFade {
    static let opacityStep = 0.05

    static func opacity(
        contentHeight: CGFloat,
        contentBottomInset: CGFloat,
        visibleMaxY: CGFloat,
        fadeHeight: CGFloat) -> Double
    {
        guard contentHeight > 0, fadeHeight > 0 else {
            return 1
        }

        let contentBottom = contentHeight + contentBottomInset
        let distance = contentBottom - visibleMaxY
        let rawOpacity = Double(min(1, max(0, distance / fadeHeight)))
        return self.quantize(rawOpacity)
    }

    static func quantize(_ opacity: Double, step: Double = Self.opacityStep) -> Double {
        guard step > 0 else {
            return opacity
        }

        return (opacity / step).rounded() * step
    }
}

enum FooterMaskMetrics {
    static let heightStep: CGFloat = 1

    static func quantizedHeight(_ height: CGFloat, step: CGFloat = Self.heightStep) -> CGFloat {
        guard height > 0, step > 0 else {
            return 0
        }

        return (height / step).rounded() * step
    }

    static func fadeBottomOpacity(scrollEdgeFadeOpacity: Double) -> Double {
        1 - min(1, max(0, scrollEdgeFadeOpacity))
    }
}

private struct FooterContentMask: View {
    let footerHeight: CGFloat
    let fadeHeight: CGFloat
    let scrollEdgeFadeOpacity: Double

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.black)

            LinearGradient(
                colors: [
                    .black,
                    .black.opacity(FooterMaskMetrics.fadeBottomOpacity(
                        scrollEdgeFadeOpacity: self.scrollEdgeFadeOpacity)),
                ],
                startPoint: .top,
                endPoint: .bottom)
                .frame(height: max(0, self.fadeHeight))

            Rectangle()
                .fill(.clear)
                .frame(height: max(0, self.footerHeight))
        }
    }
}

enum OnboardingAccessibilityText {
    static func nextStepHint(for presentation: OnboardingNextStepPresentation) -> String {
        switch presentation {
        case .push:
            "Opens a follow-up screen."
        case .sheet:
            "Presents a follow-up sheet."
        }
    }
}

private enum OnboardingRouteTransitionDirection {
    case forward
    case backward
}

private struct PresentedOnboardingNextStep: Identifiable, Hashable {
    let id: OnboardingNextStepItem.ID
    let step: OnboardingNextStepItem

    init(step: OnboardingNextStepItem) {
        self.id = step.id
        self.step = step
    }

    static func == (lhs: PresentedOnboardingNextStep, rhs: PresentedOnboardingNextStep) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

private struct OnboardingBackgroundView: View {
    let background: OnboardingBackground
    let reduceMotion: Bool

    var body: some View {
        self.background
            .makeView(context: OnboardingBackgroundContext(reduceMotion: self.reduceMotion))
            .ignoresSafeArea()
    }
}

private struct OnboardingPrimaryDestinationContainer<Destination: View>: View {
    let destination: Destination

    var body: some View {
        VStack(spacing: 0) {
            self.destination
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #if os(macOS)
            .frame(minWidth: Tokens.Layout.compactSheetMinWidth, minHeight: 620)
        #endif
    }
}

private struct OnboardingPrimaryRouteDestinationContainer<Content: OnboardingContent, Destination: View>: View {
    let content: Content
    let background: OnboardingBackground
    let style: OnboardingStyle
    let destination: Destination
    let index: Int
    let count: Int
    let onNext: () -> Void
    let onDone: () -> Void

    @ScaledMetric(relativeTo: .body) private var compactHorizontalPadding: CGFloat = Tokens.Layout.compactHorizontalPadding
    @ScaledMetric(relativeTo: .body) private var regularHorizontalPadding: CGFloat = Tokens.Layout.regularHorizontalPadding

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                self.destination
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    self.isLastRoute ? self.onDone() : self.onNext()
                } label: {
                    self.primaryButtonText
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .onboardingOptionalForegroundStyle(self.style.primaryButtonForegroundColor)
                        .frame(maxWidth: .infinity, minHeight: Tokens.Layout.buttonLabelMinHeight)
                        .padding(.vertical, Tokens.Platform.buttonVerticalPadding)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                #if os(macOS)
                    .environment(\.controlActiveState, .key)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.large))
                #else
                    .glassEffect(in: .rect(cornerRadius: Tokens.Radius.large))
                #endif
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .padding(.horizontal, self.horizontalPadding(for: geometry.size.width))
                .padding(.vertical, Tokens.Layout.footerVerticalPadding)
                .frame(maxWidth: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        #if os(macOS)
            .frame(minWidth: Tokens.Layout.compactSheetMinWidth, minHeight: 620)
        #endif
    }

    private var isLastRoute: Bool {
        self.index >= self.count - 1
    }

    private var primaryButtonText: Text {
        self.isLastRoute ? self.content.primaryRouteDoneButtonText : self.content.primaryRouteNextButtonText
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        LayoutMetrics.horizontalPadding(
            for: width,
            compact: self.compactHorizontalPadding,
            regular: self.regularHorizontalPadding,
            breakpoint: Tokens.Layout.compactWidthBreakpoint)
    }
}

private struct OnboardingHeaderSection<Content: OnboardingContent>: View {
    let content: Content
    let iconSize: CGFloat
    let style: OnboardingStyle

    var body: some View {
        VStack(spacing: Tokens.Spacing.large) {
            if let appIcon = self.content.appIcon {
                appIcon
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.iconSize, height: self.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: self.iconSize * Tokens.Radius.iconScale))
                    .accessibilityHidden(true)
            }

            self.content.title
            #if os(macOS)
                .font(.title)
            #else
                .font(.largeTitle)
            #endif
                .fontWeight(.bold)
                .onboardingOptionalForegroundStyle(self.style.titleColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let subtitle = self.content.subtitle {
                subtitle
                    .font(.body)
                    .foregroundStyle(self.style.subtitleForegroundStyle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct OnboardingFeatureList: View {
    let features: [OnboardingFeatureItem]
    let featureSpacing: CGFloat
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool
    let style: OnboardingStyle

    var body: some View {
        VStack(spacing: self.featureSpacing) {
            ForEach(Array(self.features.enumerated()), id: \.element.id) { index, feature in
                OnboardingFeatureRow(
                    feature: feature,
                    index: index,
                    featureIconSize: self.featureIconSize,
                    featuresVisible: self.featuresVisible,
                    reduceMotion: self.reduceMotion,
                    style: self.style)
            }
        }
    }
}

private struct OnboardingFeatureRow: View {
    let feature: OnboardingFeatureItem
    let index: Int
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool
    let style: OnboardingStyle

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
                    .foregroundStyle(self.style.featureIconForegroundStyle)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let label = self.feature.label {
                    label
                        .font(.headline)
                        .onboardingOptionalForegroundStyle(self.style.featureTitleColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                self.feature.description
                    .font(.subheadline)
                    .foregroundStyle(self.style.featureDescriptionForegroundStyle)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : (self.reduceMotion ? 0 : Tokens.Motion.revealOffset))
        .animation(
            self.reduceMotion ? nil : .easeOut(duration: Tokens.Motion.revealDuration).delay(delay),
            value: isVisible)
    }
}

private struct OnboardingNextStepsSection: View {
    let title: Text?
    let steps: [OnboardingNextStepItem]
    let featureIconSize: CGFloat
    let animationStartIndex: Int
    let itemsVisible: Bool
    let reduceMotion: Bool
    let isLoading: Bool
    let hasDestination: Bool
    let style: OnboardingStyle
    let onNextStep: (OnboardingNextStepItem) -> Void

    var body: some View {
        if !self.steps.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.Spacing.medium) {
                if let title = self.title {
                    title
                        .font(.headline)
                        .onboardingOptionalForegroundStyle(self.style.nextStepsTitleColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(spacing: Tokens.Spacing.small) {
                    ForEach(Array(self.steps.enumerated()), id: \.element.id) { index, step in
                        OnboardingNextStepRow(
                            step: step,
                            index: self.animationStartIndex + index,
                            featureIconSize: self.featureIconSize,
                            isVisible: self.itemsVisible,
                            reduceMotion: self.reduceMotion,
                            isLoading: self.isLoading,
                            isActionable: self.hasDestination || step.actionText != nil,
                            style: self.style,
                            onNextStep: self.onNextStep)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
        }
    }
}

private struct OnboardingNextStepRow: View {
    let step: OnboardingNextStepItem
    let index: Int
    let featureIconSize: CGFloat
    let isVisible: Bool
    let reduceMotion: Bool
    let isLoading: Bool
    let isActionable: Bool
    let style: OnboardingStyle
    let onNextStep: (OnboardingNextStepItem) -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let delay = Tokens.Motion.revealDelay(for: self.index)

        Group {
            if self.isActionable {
                Button {
                    self.onNextStep(self.step)
                } label: {
                    self.content
                }
                .buttonStyle(.plain)
                .disabled(self.isLoading)
            } else {
                self.content
            }
        }
        .padding(Tokens.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.rowBackgroundStyle, in: .rect(cornerRadius: Tokens.Radius.large))
        .overlay {
            RoundedRectangle(cornerRadius: Tokens.Radius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .modifier(OnboardingNextStepAccessibilityModifier(
            isActionable: self.isActionable,
            presentation: self.step.presentation))
        .opacity(self.isVisible ? 1 : 0)
        .offset(y: self.isVisible ? 0 : (self.reduceMotion ? 0 : Tokens.Motion.revealOffset))
        .animation(
            self.reduceMotion ? nil : .easeOut(duration: Tokens.Motion.revealDuration).delay(delay),
            value: self.isVisible)
    }

    private var rowBackgroundStyle: AnyShapeStyle {
        if self.reduceTransparency {
            AnyShapeStyle(Tokens.background)
        } else {
            AnyShapeStyle(.thinMaterial)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.medium) {
            if let image = self.step.image {
                image
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: self.featureIconSize, height: self.featureIconSize)
                    .foregroundStyle(self.style.nextStepIconForegroundStyle)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Tokens.Spacing.small) {
                self.step.title
                    .font(.subheadline.weight(.semibold))
                    .onboardingOptionalForegroundStyle(self.style.nextStepTitleColor)
                    .fixedSize(horizontal: false, vertical: true)

                if let description = self.step.description {
                    description
                        .font(.footnote)
                        .foregroundStyle(self.style.nextStepDescriptionForegroundStyle)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let actionText = self.step.actionText {
                    HStack(spacing: Tokens.Spacing.small) {
                        actionText
                            .font(.footnote.weight(.semibold))

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(self.style.nextStepActionForegroundStyle)
                    .padding(.top, 2)
                }
            }
            .multilineTextAlignment(.leading)
            .layoutPriority(1)

            if self.isActionable, self.step.actionText == nil {
                Image(systemName: self.step.presentation == .sheet ? "arrow.up.right.square" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(self.style.nextStepAccessoryForegroundStyle)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingFooterSection<Content: OnboardingContent>: View {
    let content: Content
    let isLoading: Bool
    let style: OnboardingStyle
    let onPrimary: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.medium) {
            Button {
                self.onPrimary()
            } label: {
                ZStack {
                    self.content.primaryButtonText
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .onboardingOptionalForegroundStyle(self.style.primaryButtonForegroundColor)
                        .opacity(self.isLoading ? 0 : 1)

                    HStack(spacing: Tokens.Spacing.small) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(self.style.resolvedPrimaryButtonProgressTint)

                        self.content.primaryButtonText
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .onboardingOptionalForegroundStyle(self.style.primaryButtonForegroundColor)
                    }
                    .opacity(self.isLoading ? 1 : 0)
                }
                .frame(maxWidth: .infinity, minHeight: Tokens.Layout.buttonLabelMinHeight)
                .padding(.vertical, Tokens.Platform.buttonVerticalPadding)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(self.content.primaryButtonText)
                .accessibilityValue(self.isLoading ? Text("Loading") : Text(""))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .disabled(self.isLoading)
            #if os(macOS)
                .environment(\.controlActiveState, .key)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.large))
            #else
                .glassEffect(in: .rect(cornerRadius: Tokens.Radius.large))
            #endif

            if let skipText = self.content.skipButtonText {
                Button {
                    self.onSkip()
                } label: {
                    skipText
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: Tokens.Layout.minimumControlHeight)
                }
                .buttonStyle(.plain)
                .foregroundStyle(self.style.secondaryButtonForegroundStyle)
                .disabled(self.isLoading)
            }
        }
        .padding(.vertical, Tokens.Layout.footerVerticalPadding)
    }
}

private struct OnboardingNextStepAccessibilityModifier: ViewModifier {
    let isActionable: Bool
    let presentation: OnboardingNextStepPresentation

    @ViewBuilder
    func body(content: Content) -> some View {
        if self.isActionable {
            content.accessibilityHint(Text(OnboardingAccessibilityText.nextStepHint(for: self.presentation)))
        } else {
            content
        }
    }
}

private extension View {
    @ViewBuilder
    func onboardingTint(_ color: Color?) -> some View {
        if let color {
            self.tint(color)
        } else {
            self
        }
    }

    @ViewBuilder
    func onboardingOptionalForegroundStyle(_ color: Color?) -> some View {
        if let color {
            self.foregroundStyle(color)
        } else {
            self
        }
    }
}

private struct OnboardingPreviewContent: OnboardingContent {
    var appIcon: Image? { Image(systemName: "app.gift.fill") }
    var title: Text { Text("Welcome") }
    var subtitle: Text? { Text("Here's what makes this app great.") }
    var features: [OnboardingFeatureItem] {
        [
            OnboardingFeatureItem(
                id: "tap-to-flip",
                systemImage: "hand.tap.fill",
                label: "Tap to flip",
                description: "Review cards with a simple tap."),
            OnboardingFeatureItem(
                id: "organize",
                systemImage: "folder.fill",
                label: "Organize",
                description: "Group cards into decks and folders."),
            OnboardingFeatureItem(
                id: "spaced-repetition",
                systemImage: "brain.head.profile.fill",
                label: "Spaced repetition",
                description: "Study smarter, not harder."),
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
                id: "study-reminder",
                systemImage: "bell.badge.fill",
                title: "Set a study reminder",
                description: "Pick a time that fits into your day.",
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

private struct LongOnboardingPreviewContent: OnboardingContent {
    var appIcon: Image? { Image(systemName: "rectangle.stack.badge.plus.fill") }
    var title: Text {
        Text("A much longer onboarding title that must wrap cleanly")
    }
    var subtitle: Text? {
        Text("This subtitle is intentionally longer so narrow presentations and larger Dynamic Type sizes still have room to breathe.")
    }
    var features: [OnboardingFeatureItem] {
        (1...12).map { index in
            OnboardingFeatureItem(
                id: "long-feature-\(index)",
                systemImage: "checkmark.circle.fill",
                label: "Onboarding feature \(index) with a longer localized label",
                description: "This onboarding description is long enough to wrap over multiple lines while keeping the icon, text, and action area stable.")
        }
    }
    var nextStepsTitle: Text? { Text("Recommended next steps") }
    var nextSteps: [OnboardingNextStepItem] {
        [
            OnboardingNextStepItem(
                id: "import-sample",
                systemImage: "tray.and.arrow.down.fill",
                title: "Import a sample collection with a longer localized title",
                description: "The description wraps across several lines so compact sheets and large accessibility sizes keep a stable rhythm.",
                actionText: "Import sample data"),
            OnboardingNextStepItem(
                id: "invite-collaborators",
                systemImage: "person.2.badge.gearshape.fill",
                title: "Invite collaborators later from settings",
                description: "A static recommendation can omit an action and still align with actionable rows.",
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

#Preview("Onboarding") {
    @Previewable @State var isLoading = false
    @Previewable @State var errorMessage: String?

    OnboardingView(
        content: OnboardingPreviewContent(),
        isLoading: $isLoading,
        errorMessage: $errorMessage,
        onPrimary: {},
        onSkip: {},
        onPrimaryRoutesComplete: {
            isLoading = false
        },
        primaryRouteDestination: { route in
            OnboardingPrimaryRoutePreviewDestination(route: route)
        },
        nextStepDestination: { step in
            OnboardingNextStepPreviewDestination(step: step)
        })
}

#Preview("Onboarding Soft Gradient") {
    OnboardingView(
        content: OnboardingPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            OnboardingPrimaryRoutePreviewDestination(route: route)
        },
        nextStepDestination: { step in
            OnboardingNextStepPreviewDestination(step: step)
        })
        .onboardingBackground(.softGradient)
        .frame(width: 390, height: 740)
}

#Preview("Onboarding Animated Background") {
    OnboardingView(
        content: OnboardingPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            OnboardingPrimaryRoutePreviewDestination(route: route)
        },
        nextStepDestination: { step in
            OnboardingNextStepPreviewDestination(step: step)
        })
        .onboardingBackground(.animatedMesh())
        .frame(width: 390, height: 740)
}

#Preview("Onboarding Long Narrow") {
    OnboardingView(
        content: LongOnboardingPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            OnboardingPrimaryRoutePreviewDestination(route: route)
        },
        nextStepDestination: { step in
            OnboardingNextStepPreviewDestination(step: step)
        })
        .frame(width: 320, height: 760)
}

#Preview("Onboarding Loading") {
    OnboardingView(
        content: OnboardingPreviewContent(),
        isLoading: .constant(true),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            OnboardingPrimaryRoutePreviewDestination(route: route)
        },
        nextStepDestination: { step in
            OnboardingNextStepPreviewDestination(step: step)
        })
        .frame(width: 390, height: 740)
}

#Preview("Onboarding Dark Accessibility") {
    OnboardingView(
        content: LongOnboardingPreviewContent(),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onPrimary: {},
        onSkip: {},
        primaryRouteDestination: { route in
            OnboardingPrimaryRoutePreviewDestination(route: route)
        },
        nextStepDestination: { step in
            OnboardingNextStepPreviewDestination(step: step)
        })
        .frame(width: 390, height: 780)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}

private struct OnboardingNextStepPreviewDestination: View {
    let step: OnboardingNextStepItem

    var body: some View {
        VStack(spacing: Tokens.Spacing.large) {
            step.title
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            if let description = step.description {
                description
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: Tokens.Layout.contentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Tokens.Spacing.xLarge)
        .navigationTitle("Next step")
    }
}

private struct OnboardingPrimaryRoutePreviewDestination: View {
    let route: OnboardingPrimaryRoute

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
            Text("Offer a final setup step before completing onboarding.")
        default:
            Text("The primary button can slide through chained follow-up routes inside the same sheet.")
        }
    }
}
#endif
