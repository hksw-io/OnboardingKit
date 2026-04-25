#if os(iOS) || os(macOS)
import Foundation
import SwiftUI

public struct OnboardingBackgroundContext {
    public let reduceMotion: Bool

    public init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }
}

public struct OnboardingBackground {
    enum Storage {
        case system
        case softGradient
        case linearGradient(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint)
        case animatedMesh(primary: Color, secondary: Color, accent: Color)
        case custom((OnboardingBackgroundContext) -> AnyView)
    }

    let storage: Storage

    public static var system: Self { Self(storage: .system) }
    public static var softGradient: Self { Self(storage: .softGradient) }

    public static func linearGradient(
        colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing) -> Self
    {
        Self(storage: .linearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint))
    }

    public static func animatedMesh(
        primary: Color = .blue,
        secondary: Color = .purple,
        accent: Color = .mint) -> Self
    {
        Self(storage: .animatedMesh(primary: primary, secondary: secondary, accent: accent))
    }

    public static func custom<Background: View>(
        @ViewBuilder _ background: @escaping (OnboardingBackgroundContext) -> Background) -> Self
    {
        Self(storage: .custom { context in
            AnyView(background(context))
        })
    }
}

extension OnboardingBackground {
    var spansBehindFooter: Bool {
        true
    }

    var footerSurfaceStyle: AnyShapeStyle {
        AnyShapeStyle(.clear)
    }

    var footerFadeEndColor: Color {
        .clear
    }

    func makeView(context: OnboardingBackgroundContext) -> AnyView {
        switch self.storage {
        case .system:
            AnyView(Tokens.background)
        case .softGradient:
            AnyView(OnboardingSoftGradientBackground())
        case let .linearGradient(colors, startPoint, endPoint):
            AnyView(OnboardingLinearGradientBackground(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint))
        case let .animatedMesh(primary, secondary, accent):
            AnyView(OnboardingAnimatedMeshBackground(
                primary: primary,
                secondary: secondary,
                accent: accent,
                reduceMotion: context.reduceMotion))
        case let .custom(background):
            background(context)
        }
    }
}

private struct OnboardingSoftGradientBackground: View {
    var body: some View {
        ZStack {
            Tokens.background

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.16),
                    Color.mint.opacity(0.10),
                    Tokens.background.opacity(0.72),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    Tokens.background.opacity(0.05),
                    Tokens.background.opacity(0.86),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
    }
}

private struct OnboardingLinearGradientBackground: View {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    var body: some View {
        LinearGradient(
            colors: GradientColorNormalizer.colors(self.colors),
            startPoint: self.startPoint,
            endPoint: self.endPoint)
    }
}

private struct OnboardingAnimatedMeshBackground: View {
    let primary: Color
    let secondary: Color
    let accent: Color
    let reduceMotion: Bool

    @State private var phase = 0.0

    var body: some View {
        ZStack {
            Tokens.background

            MeshGradient(
                width: 3,
                height: 3,
                points: OnboardingAnimatedMeshGeometry.points(
                    phase: self.phase,
                    reduceMotion: self.reduceMotion),
                colors: self.colors)
                .opacity(0.58)

            LinearGradient(
                colors: [
                    Tokens.background.opacity(0.12),
                    Tokens.background.opacity(0.84),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
        .onAppear {
            self.startAnimationIfNeeded()
        }
        .onChange(of: self.reduceMotion) { _, reduceMotion in
            if reduceMotion {
                self.phase = 0
            } else {
                self.startAnimationIfNeeded()
            }
        }
    }

    private var colors: [Color] {
        [
            self.primary.opacity(0.18),
            self.secondary.opacity(0.15),
            Tokens.background,
            self.accent.opacity(0.18),
            Tokens.background.opacity(0.86),
            self.primary.opacity(0.14),
            Tokens.background,
            self.secondary.opacity(0.12),
            self.accent.opacity(0.16),
        ]
    }

    private func startAnimationIfNeeded() {
        guard !self.reduceMotion else {
            return
        }

        withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
            self.phase = 1
        }
    }
}

enum OnboardingAnimatedMeshGeometry {
    static func points(phase: Double, reduceMotion: Bool) -> [SIMD2<Float>] {
        let phase = reduceMotion ? 0 : phase
        let angle = phase * .pi * 2

        return [
            self.point(0, 0),
            self.point(0.50 + (0.04 * cos(angle)), 0.02 + (0.02 * sin(angle))),
            self.point(1, 0),
            self.point(0.02 + (0.02 * sin(angle * 0.7)), 0.50 + (0.04 * cos(angle))),
            self.point(0.50 + (0.05 * sin(angle)), 0.50 + (0.05 * cos(angle * 0.8))),
            self.point(0.98, 0.50 + (0.03 * sin(angle * 1.1))),
            self.point(0, 1),
            self.point(0.50 + (0.03 * cos(angle * 1.3)), 0.98),
            self.point(1, 1),
        ]
    }

    private static func point(_ x: Double, _ y: Double) -> SIMD2<Float> {
        SIMD2(Float(x), Float(y))
    }
}

enum GradientColorNormalizer {
    static func colors(_ colors: [Color]) -> [Color] {
        switch colors.count {
        case 0:
            [Tokens.background, Tokens.background]
        case 1:
            [colors[0], colors[0]]
        default:
            colors
        }
    }
}
#endif
