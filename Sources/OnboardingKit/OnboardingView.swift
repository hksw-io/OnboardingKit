#if os(iOS) || os(macOS)
import SwiftUI

public struct OnboardingView<Content: OnboardingContent>: View {
    let content: Content
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let onPrimary: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var featuresVisible = false
    @State private var fadeOpacity: Double = 1

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = Tokens.Platform.iconSize
    @ScaledMetric(relativeTo: .body) private var featureIconSize: CGFloat = Tokens.Platform.featureIconSize
    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var featureSpacing: CGFloat = Tokens.Platform.featureSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding
    @ScaledMetric(relativeTo: .body) private var gradientMaskHeight: CGFloat = Tokens.Platform.scrollEdgeFadeHeight
    @ScaledMetric(relativeTo: .body) private var compactHorizontalPadding: CGFloat = Tokens.Layout.compactHorizontalPadding
    @ScaledMetric(relativeTo: .body) private var regularHorizontalPadding: CGFloat = Tokens.Layout.regularHorizontalPadding

    public init(
        content: Content,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        onPrimary: @escaping () -> Void,
        onSkip: @escaping () -> Void)
    {
        self.content = content
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.onPrimary = onPrimary
        self.onSkip = onSkip
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: self.contentSpacing) {
                    self.headerSection
                    self.featuresSection
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
                return min(1, max(0, distance / self.gradientMaskHeight))
            } action: { _, newOpacity in
                self.fadeOpacity = newOpacity
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ZStack {
                    self.footerSection
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
                        .frame(height: self.gradientMaskHeight)
                        .offset(y: -self.gradientMaskHeight)
                        .opacity(self.fadeOpacity)
                        .allowsHitTesting(false)
                }
                .background(Tokens.background)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .interactiveDismissDisabled()
        #if os(macOS)
            .frame(minWidth: 520, minHeight: 620)
        #endif
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
            .onAppear {
                self.featuresVisible = true
            }
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

    private var headerSection: some View {
        VStack(spacing: Tokens.Spacing.large) {
            if let appIcon = content.appIcon {
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

            if let subtitle = content.subtitle {
                subtitle
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var featuresSection: some View {
        VStack(spacing: self.featureSpacing) {
            ForEach(Array(self.content.features.enumerated()), id: \.offset) { index, feature in
                self.featureRow(feature: feature, index: index)
            }
        }
    }

    private func featureRow(feature: OnboardingFeatureItem, index: Int) -> some View {
        let delay = Tokens.Motion.featureBaseDelay + (Double(index) * Tokens.Motion.featureStaggerDelay)
        let isVisible = self.featuresVisible

        return HStack(alignment: .top, spacing: Tokens.Spacing.large) {
            if let image = feature.image {
                image
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: self.featureIconSize, height: self.featureIconSize)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let label = feature.label {
                    label
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                feature.description
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

    private var footerSection: some View {
        VStack(spacing: Tokens.Spacing.medium) {
            Button {
                self.onPrimary()
            } label: {
                Group {
                    if self.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        self.content.primaryButtonText
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .disabled(self.isLoading)

            if let skipText = content.skipButtonText {
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

#Preview("Onboarding") {
    struct PreviewContent: OnboardingContent {
        var appIcon: Image? { Image(systemName: "app.gift.fill") }
        var title: Text { Text("Welcome") }
        var subtitle: Text? { Text("Here's what makes this app great.") }
        var features: [OnboardingFeatureItem] {
            [
                OnboardingFeatureItem(
                    image: Image(systemName: "hand.tap.fill"),
                    label: Text("Tap to flip"),
                    description: Text("Review cards with a simple tap.")),
                OnboardingFeatureItem(
                    image: Image(systemName: "folder.fill"),
                    label: Text("Organize"),
                    description: Text("Group cards into decks and folders.")),
                OnboardingFeatureItem(
                    image: Image(systemName: "brain.head.profile.fill"),
                    label: Text("Spaced repetition"),
                    description: Text("Study smarter, not harder.")),
            ]
        }
        var primaryButtonText: Text { Text("Get started") }
        var skipButtonText: Text? { Text("Skip for now") }
        var errorAlertTitle: Text { Text("Something went wrong") }
        var errorOKText: Text { Text("OK") }
    }

    struct Host: View {
        @State private var isLoading = false
        @State private var errorMessage: String?
        var body: some View {
            OnboardingView(
                content: PreviewContent(),
                isLoading: $isLoading,
                errorMessage: $errorMessage,
                onPrimary: { isLoading = true },
                onSkip: {})
        }
    }
    return Host()
}
#endif
