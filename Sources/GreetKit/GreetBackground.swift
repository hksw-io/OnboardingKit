#if os(iOS) || os(macOS)
import Foundation
import SwiftUI

public struct GreetBackgroundContext: Sendable {
    public let reduceMotion: Bool
    public let reduceTransparency: Bool
    public let colorSchemeContrast: ColorSchemeContrast
    public let brandColor: Color?
    public let colorScheme: ColorScheme

    public init(
        reduceMotion: Bool,
        reduceTransparency: Bool = false,
        colorSchemeContrast: ColorSchemeContrast = .standard,
        brandColor: Color? = nil,
        colorScheme: ColorScheme = .light)
    {
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
        self.colorSchemeContrast = colorSchemeContrast
        self.brandColor = brandColor
        self.colorScheme = colorScheme
    }
}

extension GreetBackgroundContext {
    var gradientDamping: GreetGradientDamping {
        GreetGradientDamping(
            reduceTransparency: self.reduceTransparency,
            increaseContrast: self.colorSchemeContrast == .increased)
    }

    /// A background's own `brand:` wins over the style tint, which wins over the default blue.
    func tones(brand: Color?) -> GreetGradientTones {
        GreetGradientTones(
            brand: brand ?? self.brandColor ?? .blue,
            colorScheme: self.colorScheme)
    }
}

/// Flattens a decorative colour wash when the person has asked for a background that competes less
/// with the text on top of it.
///
/// Reduce Transparency and Increase Contrast both mean the same thing for a wash like this: damp
/// it, and let the opaque base carry more of the surface, so foreground contrast stops depending on
/// where a blob happens to sit. Both gradients apply it the same way, field by field, so the two
/// operations live here rather than being re-derived from loose constants at each call.
struct GreetGradientDamping: Equatable, Sendable {
    static let none = Self(isActive: false)

    let isActive: Bool

    init(reduceTransparency: Bool, increaseContrast: Bool) {
        self.init(isActive: reduceTransparency || increaseContrast)
    }

    private init(isActive: Bool) {
        self.isActive = isActive
    }

    /// How much of the coloured wash survives.
    func tint(_ opacity: Double) -> Double {
        self.isActive ? opacity * 0.3 : opacity
    }

    /// How much more of the opaque base is pulled over the wash.
    func veil(_ opacity: Double) -> Double {
        self.isActive ? min(1, opacity + 0.25) : opacity
    }
}

/// The four colours a built-in gradient composites, derived from one brand colour.
///
/// The brand colour becomes `primary`, and the supporting tones are that same colour washed
/// toward the platform surface, so the field reads as one colour rather than as three unrelated
/// hues. Because the surface is light in light mode and dark in dark mode, the same wash lifts the
/// palette in one and deepens it in the other.
///
/// Dark mode washes less: a dark surface swallows chroma faster, so an equal mix would flatten the
/// supporting tones into the background.
struct GreetGradientTones {
    let base: Color
    let primary: Color
    let secondary: Color
    let accent: Color

    init(brand: Color, colorScheme: ColorScheme) {
        let secondaryMix = colorScheme == .dark ? 0.22 : 0.30
        let accentMix = colorScheme == .dark ? 0.42 : 0.55

        self.base = Tokens.background
        self.primary = brand
        self.secondary = brand.mix(with: Tokens.background, by: secondaryMix)
        self.accent = brand.mix(with: Tokens.background, by: accentMix)
    }
}

/// How far and how fast the animated gradient's colour field drifts.
///
/// Motion only: the palette, opacities, and blur are the same at every strength. A motion knob that
/// also brightened the field meant a caller who wanted a calmer *pace* got a paler *sheet*, and the
/// two are not the same request — Reduce Motion damps one and Reduce Transparency the other.
public struct GreetGradientMotion: Equatable, Sendable {
    public var strength: Double

    public static let subtle = Self(strength: 0.7)
    public static let standard = Self(strength: 1.2)
    public static let expressive = Self(strength: 1.6)

    public init(strength: Double = 1.2) {
        self.strength = strength
    }

    var clampedStrength: Double {
        min(2, max(0, self.strength))
    }

    var speedScale: Double {
        max(0.35, 0.65 + (self.clampedStrength * 0.35))
    }

    var travelScale: Double {
        self.clampedStrength
    }
}

public struct GreetBackground {
    enum Storage {
        case system
        case softGradient(brand: Color?)
        case animatedGradient(brand: Color?, motion: GreetGradientMotion)
        case custom((GreetBackgroundContext) -> AnyView)
    }

    let storage: Storage

    // Left as computed: GreetBackground is not Sendable — its `custom` case holds a plain
    // closure — so a static let would be a concurrency-unsafe global.
    public static var system: Self { Self(storage: .system) }
    public static var softGradient: Self { Self(storage: .softGradient(brand: nil)) }

    public static func softGradient(brand: Color? = nil) -> Self {
        Self(storage: .softGradient(brand: brand))
    }

    public static func animatedGradient(
        brand: Color? = nil,
        motion: GreetGradientMotion = .standard) -> Self
    {
        Self(storage: .animatedGradient(brand: brand, motion: motion))
    }

    public static func custom<Background: View>(
        @ViewBuilder _ background: @escaping (GreetBackgroundContext) -> Background) -> Self
    {
        Self(storage: .custom { context in
            AnyView(background(context))
        })
    }
}

extension GreetBackground {
    @MainActor
    func makeView(context: GreetBackgroundContext) -> AnyView {
        switch self.storage {
        case .system:
            // Draw nothing. Sheets carry their own material on both platforms, and painting an
            // opaque colour over it is what made the default presentation look unlike a system
            // sheet. `Tokens.background` stays as the opaque base the gradients composite onto.
            AnyView(EmptyView())
        case let .softGradient(brand):
            AnyView(GreetSoftGradientBackground(
                tones: context.tones(brand: brand),
                colorScheme: context.colorScheme,
                damping: context.gradientDamping))
        case let .animatedGradient(brand, motion):
            AnyView(GreetAnimatedGradientBackground(
                tones: context.tones(brand: brand),
                colorScheme: context.colorScheme,
                motion: motion,
                reduceMotion: context.reduceMotion,
                damping: context.gradientDamping))
        case let .custom(background):
            background(context)
        }
    }
}

private struct GreetSoftGradientBackground: View {
    let tones: GreetGradientTones
    let colorScheme: ColorScheme
    let damping: GreetGradientDamping

    var body: some View {
        let tuning = GreetGradientVisualTuning
            .soft(colorScheme: self.colorScheme)
            .damped(by: self.damping)

        ZStack {
            self.tones.base

            LinearGradient(
                colors: [
                    self.tones.primary.opacity(tuning.baseTintOpacity),
                    self.tones.secondary.opacity(tuning.baseTintOpacity * 0.7),
                    self.tones.accent.opacity(tuning.baseTintOpacity * 0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    self.tones.primary.opacity(tuning.primaryOpacity),
                    self.tones.secondary.opacity(tuning.secondaryOpacity),
                    self.tones.accent.opacity(tuning.accentOpacity),
                    self.tones.base.opacity(tuning.baseFadeOpacity),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    self.tones.base.opacity(tuning.topVeilOpacity),
                    self.tones.base.opacity(tuning.bottomVeilOpacity),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
    }
}

private struct GreetAnimatedGradientBackground: View {
    let tones: GreetGradientTones
    let colorScheme: ColorScheme
    let motion: GreetGradientMotion
    let reduceMotion: Bool
    let damping: GreetGradientDamping

    #if os(macOS)
        @Environment(\.controlActiveState) private var controlActiveState
    #endif

    private static let baseCycleDuration: TimeInterval = 10

    /// A Mac greet window can sit behind another app for as long as the person leaves it there.
    /// Nobody is watching the gradient at that point, so stop drawing it.
    private var isAppInactive: Bool {
        #if os(macOS)
            self.controlActiveState == .inactive
        #else
            false
        #endif
    }

    var body: some View {
        // A static field pins the phase; an inactive app only stops the clock. Pinning the phase
        // in the inactive case too would snap the blobs back to their start position and pop when
        // the person came back. Deriving the phase from the timeline date instead means resuming
        // is seamless — it lands wherever wall-clock time says it should.
        let isStatic = self.reduceMotion || self.motion.clampedStrength == 0

        TimelineView(.animation(
            minimumInterval: 1.0 / 30.0,
            paused: isStatic || self.isAppInactive))
        { timeline in
            let phase = isStatic
                ? 0
                : timeline.date.timeIntervalSinceReferenceDate / (Self.baseCycleDuration / self.motion.speedScale)

            GeometryReader { geometry in
                let centers = GreetAnimatedGradientMotion.centers(
                    phase: phase,
                    reduceMotion: self.reduceMotion,
                    motion: self.motion)
                let tuning = GreetGradientVisualTuning
                    .animated(colorScheme: self.colorScheme)
                    .damped(by: self.damping)

                Canvas(
                    opaque: true,
                    colorMode: .extendedLinear,
                    rendersAsynchronously: true)
                { context, size in
                    GreetAnimatedGradientRenderer.draw(
                        context: &context,
                        size: size,
                        tones: self.tones,
                        tuning: tuning,
                        centers: centers)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

private enum GreetAnimatedGradientRenderer {
    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        tones: GreetGradientTones,
        tuning: GreetAnimatedGradientTuning,
        centers: [CGPoint])
    {
        let rect = CGRect(origin: .zero, size: size)
        let baseSize = max(size.width, size.height)

        context.fill(Path(rect), with: .color(tones.base))

        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [
                    tones.primary.opacity(tuning.baseTintOpacity),
                    tones.secondary.opacity(tuning.baseTintOpacity * 0.76),
                    tones.accent.opacity(tuning.baseTintOpacity * 0.68),
                    tones.primary.opacity(tuning.baseTintOpacity * 0.58),
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)))

        var blobContext = context
        blobContext.addFilter(.blur(radius: baseSize * tuning.blobBlurRatio))
        blobContext.drawLayer { layer in
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.primary,
                opacity: tuning.primaryBlobOpacity,
                center: centers[0],
                radius: baseSize * 0.92)
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.secondary,
                opacity: tuning.secondaryBlobOpacity,
                center: centers[1],
                radius: baseSize * 1.00)
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.accent,
                opacity: tuning.accentBlobOpacity,
                center: centers[2],
                radius: baseSize * 0.88)
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.primary,
                opacity: tuning.trailingBlobOpacity,
                center: centers[3],
                radius: baseSize * 1.08)
        }

        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [
                    tones.base.opacity(tuning.topVeilOpacity),
                    tones.base.opacity(tuning.bottomVeilOpacity),
                ]),
                startPoint: CGPoint(x: size.width * 0.5, y: 0),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height)))
    }

    private static func drawBlob(
        context: inout GraphicsContext,
        canvasRect: CGRect,
        size: CGSize,
        color: Color,
        opacity: Double,
        center: CGPoint,
        radius: CGFloat)
    {
        let centerPoint = CGPoint(x: center.x * size.width, y: center.y * size.height)

        context.fill(
            Path(canvasRect),
            with: .radialGradient(
                Gradient(colors: [
                    color.opacity(opacity),
                    color.opacity(opacity * 0.42),
                    color.opacity(opacity * 0.12),
                    color.opacity(opacity * 0.08),
                ]),
                center: centerPoint,
                startRadius: 0,
                endRadius: radius))
    }
}

struct GreetSoftGradientTuning {
    let baseTintOpacity: Double
    let primaryOpacity: Double
    let secondaryOpacity: Double
    let accentOpacity: Double
    let baseFadeOpacity: Double
    let topVeilOpacity: Double
    let bottomVeilOpacity: Double

    func damped(by damping: GreetGradientDamping) -> Self {
        Self(
            baseTintOpacity: damping.tint(self.baseTintOpacity),
            primaryOpacity: damping.tint(self.primaryOpacity),
            secondaryOpacity: damping.tint(self.secondaryOpacity),
            accentOpacity: damping.tint(self.accentOpacity),
            baseFadeOpacity: damping.veil(self.baseFadeOpacity),
            topVeilOpacity: damping.veil(self.topVeilOpacity),
            bottomVeilOpacity: damping.veil(self.bottomVeilOpacity))
    }
}

struct GreetAnimatedGradientTuning {
    let baseTintOpacity: Double
    let primaryBlobOpacity: Double
    let secondaryBlobOpacity: Double
    let accentBlobOpacity: Double
    let trailingBlobOpacity: Double
    let topVeilOpacity: Double
    let bottomVeilOpacity: Double
    let blobBlurRatio: CGFloat

    func damped(by damping: GreetGradientDamping) -> Self {
        Self(
            baseTintOpacity: damping.tint(self.baseTintOpacity),
            primaryBlobOpacity: damping.tint(self.primaryBlobOpacity),
            secondaryBlobOpacity: damping.tint(self.secondaryBlobOpacity),
            accentBlobOpacity: damping.tint(self.accentBlobOpacity),
            trailingBlobOpacity: damping.tint(self.trailingBlobOpacity),
            topVeilOpacity: damping.veil(self.topVeilOpacity),
            bottomVeilOpacity: damping.veil(self.bottomVeilOpacity),
            blobBlurRatio: self.blobBlurRatio)
    }
}

enum GreetGradientVisualTuning {
    static func soft(colorScheme: ColorScheme) -> GreetSoftGradientTuning {
        if colorScheme == .dark {
            return GreetSoftGradientTuning(
                baseTintOpacity: 0.20,
                primaryOpacity: 0.24,
                secondaryOpacity: 0.18,
                accentOpacity: 0.16,
                baseFadeOpacity: 0.54,
                topVeilOpacity: 0.08,
                bottomVeilOpacity: 0.42)
        }

        return GreetSoftGradientTuning(
            baseTintOpacity: 0.12,
            primaryOpacity: 0.18,
            secondaryOpacity: 0.12,
            accentOpacity: 0.10,
            baseFadeOpacity: 0.62,
            topVeilOpacity: 0.04,
            bottomVeilOpacity: 0.78)
    }

    /// The veil is the surface colour painted back over the field. It is what keeps the gradient
    /// behind the content rather than competing with it, and light mode previously had almost none
    /// — a 0.38 base tint under a 0.04 veil, where `soft` reaches 0.78. That inversion is why the
    /// animated background read heavy in light mode and calm in dark.
    static func animated(colorScheme: ColorScheme) -> GreetAnimatedGradientTuning {
        if colorScheme == .dark {
            return GreetAnimatedGradientTuning(
                baseTintOpacity: 0.145,
                primaryBlobOpacity: 0.324,
                secondaryBlobOpacity: 0.259,
                accentBlobOpacity: 0.238,
                trailingBlobOpacity: 0.194,
                topVeilOpacity: 0.30,
                bottomVeilOpacity: 0.55,
                blobBlurRatio: 0.035)
        }

        return GreetAnimatedGradientTuning(
            baseTintOpacity: 0.165,
            primaryBlobOpacity: 0.324,
            secondaryBlobOpacity: 0.281,
            accentBlobOpacity: 0.259,
            trailingBlobOpacity: 0.216,
            topVeilOpacity: 0.20,
            bottomVeilOpacity: 0.38,
            blobBlurRatio: 0.035)
    }
}

enum GreetAnimatedGradientMotion {
    static func centers(
        phase: Double,
        reduceMotion: Bool,
        motion: GreetGradientMotion = .standard) -> [CGPoint]
    {
        let phase = reduceMotion ? 0 : phase
        let travelScale = reduceMotion ? 0 : motion.travelScale
        let baseAngle = phase * .pi * 2
        let slowAngle = (phase * 0.63 * .pi * 2) + 1.4
        let fastAngle = (phase * 1.21 * .pi * 2) + 2.1

        return [
            self.point(0.30 + (0.18 * travelScale * sin(baseAngle)), 0.22 + (0.14 * travelScale * cos(slowAngle))),
            self.point(0.70 + (0.18 * travelScale * cos(slowAngle)), 0.28 + (0.16 * travelScale * sin(fastAngle))),
            self.point(0.30 + (0.16 * travelScale * sin(fastAngle)), 0.72 + (0.18 * travelScale * cos(baseAngle))),
            self.point(0.70 + (0.18 * travelScale * cos(baseAngle)), 0.68 + (0.16 * travelScale * sin(slowAngle))),
        ]
    }

    private static func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: min(1, max(0, x)), y: min(1, max(0, y)))
    }
}
#endif
