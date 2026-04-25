#if os(iOS) || os(macOS)
import SwiftUI

public struct OnboardingView<Content: OnboardingContent>: View {
    let content: Content
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
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
    @State private var activePrimaryRouteIndex: Int?
    @State private var routeTransitionDirection: OnboardingRouteTransitionDirection = .forward

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
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in })
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
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
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        @ViewBuilder primaryDestination: @escaping () -> PrimaryDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
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
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        onPrimaryRoutesComplete: @escaping () -> Void = {},
        @ViewBuilder primaryRouteDestination: @escaping (OnboardingPrimaryRoute) -> PrimaryRouteDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
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
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        @ViewBuilder nextStepDestination: @escaping (OnboardingNextStepItem) -> NextStepDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
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
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onNextStep: @escaping (OnboardingNextStepItem) -> Void = { _ in },
        @ViewBuilder primaryDestination: @escaping () -> PrimaryDestination,
        @ViewBuilder nextStepDestination: @escaping (OnboardingNextStepItem) -> NextStepDestination)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
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
    }

    private var onboardingContent: some View {
        ZStack {
            if let activePrimaryRouteIndex = self.activePrimaryRouteIndex,
               self.content.primaryRoutes.indices.contains(activePrimaryRouteIndex),
               let primaryRouteDestination = self.primaryRouteDestination
            {
                let route = self.content.primaryRoutes[activePrimaryRouteIndex]
                OnboardingPrimaryRouteDestinationContainer(
                    content: self.content,
                    destination: primaryRouteDestination(route),
                    index: activePrimaryRouteIndex,
                    count: self.content.primaryRoutes.count,
                    onNext: {
                        self.openPrimaryRoute(after: activePrimaryRouteIndex)
                    },
                    onDone: self.completePrimaryRoutes)
                    .id("primary-route-\(activePrimaryRouteIndex)")
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
        .clipped()
        .animation(self.routeAnimation, value: self.primaryRoutePhaseID)
    }

    private var onboardingOverview: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: self.contentSpacing) {
                    OnboardingHeaderSection(
                        content: self.content,
                        iconSize: self.iconSize)
                    OnboardingFeatureList(
                        features: self.content.features,
                        featureSpacing: self.featureSpacing,
                        featureIconSize: self.featureIconSize,
                        featuresVisible: self.featuresVisible,
                        reduceMotion: self.reduceMotion)
                    OnboardingNextStepsSection(
                        title: self.content.nextStepsTitle,
                        steps: self.content.nextSteps,
                        featureIconSize: self.featureIconSize,
                        animationStartIndex: self.content.features.count,
                        itemsVisible: self.featuresVisible,
                        reduceMotion: self.reduceMotion,
                        isLoading: self.isLoading,
                        hasDestination: self.nextStepDestination != nil,
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
                guard geometry.contentSize.height > 0 else { return 1 }
                let contentBottom = geometry.contentSize.height + geometry.contentInsets.bottom
                let distance = contentBottom - geometry.visibleRect.maxY
                return min(1, max(0, distance / self.scrollEdgeFadeHeight))
            } action: { _, newOpacity in
                self.scrollEdgeFadeOpacity = newOpacity
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ZStack {
                    OnboardingFooterSection(
                        content: self.content,
                        isLoading: self.isLoading,
                        onPrimary: self.performPrimaryAction,
                        onSkip: self.onSkip)
                        .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                        .padding(.horizontal, self.horizontalPadding(for: geometry.size.width))
                }
                .frame(maxWidth: .infinity)
                .background(alignment: .top) {
                    LinearGradient(
                        colors: [
                            Tokens.background.opacity(0),
                            Tokens.background,
                        ],
                        startPoint: .top,
                        endPoint: .bottom)
                        .frame(height: self.scrollEdgeFadeHeight)
                        .offset(y: -self.scrollEdgeFadeHeight)
                        .opacity(self.scrollEdgeFadeOpacity)
                        .allowsHitTesting(false)
                }
                .background(Tokens.background)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .interactiveDismissDisabled()
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
                self.activePrimaryRouteIndex = 0
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
            self.activePrimaryRouteIndex = nextIndex
        }
    }

    private func completePrimaryRoutes() {
        self.onPrimaryRoutesComplete()
        self.routeTransitionDirection = .backward
        withAnimation(self.routeAnimation) {
            self.activePrimaryRouteIndex = nil
        }
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
        if let activePrimaryRouteIndex = self.activePrimaryRouteIndex {
            return "route-\(activePrimaryRouteIndex)"
        }

        return self.activePrimaryDestination ? "single" : "overview"
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < Tokens.Layout.compactWidthBreakpoint ? self.compactHorizontalPadding : self.regularHorizontalPadding
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { newValue in
                if !newValue { self.errorMessage = nil }
            })
    }
}

private enum OnboardingRouteTransitionDirection {
    case forward
    case backward
}

private struct PresentedOnboardingNextStep: Identifiable, Hashable {
    let id = UUID()
    let step: OnboardingNextStepItem

    static func == (lhs: PresentedOnboardingNextStep, rhs: PresentedOnboardingNextStep) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

private struct OnboardingPrimaryDestinationContainer<Destination: View>: View {
    let destination: Destination

    var body: some View {
        VStack(spacing: 0) {
            self.destination
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Tokens.background)
        #if os(macOS)
            .frame(minWidth: Tokens.Layout.compactSheetMinWidth, minHeight: 620)
        #endif
    }
}

private struct OnboardingPrimaryRouteDestinationContainer<Content: OnboardingContent, Destination: View>: View {
    let content: Content
    let destination: Destination
    let index: Int
    let count: Int
    let onNext: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            self.destination
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Button {
                self.isLastRoute ? self.onDone() : self.onNext()
            } label: {
                self.primaryButtonText
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
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
            .padding(.horizontal, Tokens.Layout.regularHorizontalPadding)
            .padding(.vertical, Tokens.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(Tokens.background)
        }
        .background(Tokens.background)
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
}

private struct OnboardingHeaderSection<Content: OnboardingContent>: View {
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

private struct OnboardingFeatureList: View {
    let features: [OnboardingFeatureItem]
    let featureSpacing: CGFloat
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: self.featureSpacing) {
            ForEach(Array(self.features.enumerated()), id: \.offset) { index, feature in
                OnboardingFeatureRow(
                    feature: feature,
                    index: index,
                    featureIconSize: self.featureIconSize,
                    featuresVisible: self.featuresVisible,
                    reduceMotion: self.reduceMotion)
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

    var body: some View {
        let delay = Tokens.Motion.featureBaseDelay + (Double(index) * Tokens.Motion.featureStaggerDelay)
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
    let onNextStep: (OnboardingNextStepItem) -> Void

    var body: some View {
        if !self.steps.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.Spacing.medium) {
                if let title = self.title {
                    title
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(spacing: Tokens.Spacing.small) {
                    ForEach(Array(self.steps.enumerated()), id: \.offset) { index, step in
                        OnboardingNextStepRow(
                            step: step,
                            index: self.animationStartIndex + index,
                            featureIconSize: self.featureIconSize,
                            isVisible: self.itemsVisible,
                            reduceMotion: self.reduceMotion,
                            isLoading: self.isLoading,
                            isActionable: self.hasDestination || step.actionText != nil,
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
    let onNextStep: (OnboardingNextStepItem) -> Void

    var body: some View {
        let delay = Tokens.Motion.featureBaseDelay + (Double(self.index) * Tokens.Motion.featureStaggerDelay)

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
        .background(.thinMaterial, in: .rect(cornerRadius: Tokens.Radius.large))
        .overlay {
            RoundedRectangle(cornerRadius: Tokens.Radius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .opacity(self.isVisible ? 1 : 0)
        .offset(y: self.isVisible ? 0 : (self.reduceMotion ? 0 : Tokens.Motion.revealOffset))
        .animation(
            self.reduceMotion ? nil : .easeOut(duration: Tokens.Motion.revealDuration).delay(delay),
            value: self.isVisible)
    }

    private var content: some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.medium) {
            if let image = self.step.image {
                image
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: self.featureIconSize, height: self.featureIconSize)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Tokens.Spacing.small) {
                self.step.title
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                if let description = self.step.description {
                    description
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.tint)
                    .padding(.top, 2)
                }
            }
            .multilineTextAlignment(.leading)
            .layoutPriority(1)

            if self.isActionable, self.step.actionText == nil {
                Image(systemName: self.step.presentation == .sheet ? "arrow.up.right.square" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingFooterSection<Content: OnboardingContent>: View {
    let content: Content
    let isLoading: Bool
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
                        .opacity(self.isLoading ? 0 : 1)

                    HStack(spacing: Tokens.Spacing.small) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)

                        self.content.primaryButtonText
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(self.isLoading ? 1 : 0)
                }
                .frame(maxWidth: .infinity, minHeight: 28)
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(self.isLoading)
            }
        }
        .padding(.vertical, Tokens.Spacing.medium)
    }
}

private struct OnboardingPreviewContent: OnboardingContent {
    var appIcon: Image? { Image(systemName: "app.gift.fill") }
    var title: Text { Text("Welcome") }
    var subtitle: Text? { Text("Here's what makes this app great.") }
    var features: [OnboardingFeatureItem] {
        [
            OnboardingFeatureItem(
                systemImage: "hand.tap.fill",
                label: "Tap to flip",
                description: "Review cards with a simple tap."),
            OnboardingFeatureItem(
                systemImage: "folder.fill",
                label: "Organize",
                description: "Group cards into decks and folders."),
            OnboardingFeatureItem(
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
