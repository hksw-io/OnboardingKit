#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import GreetKit

@Suite("Gradient backgrounds")
struct GradientTests {
    @Test
    func backgroundContextStoresColorScheme() {
        let defaultContext = GreetBackgroundContext(reduceMotion: true)
        let darkContext = GreetBackgroundContext(
            reduceMotion: false,
            brandColor: .pink,
            colorScheme: .dark)

        #expect(defaultContext.reduceMotion)
        #expect(defaultContext.colorScheme == .light)
        #expect(!darkContext.reduceMotion)
        #expect(darkContext.colorScheme == .dark)
    }

    @Test
    func backgroundContextDefaultsToStandardAccessibilitySettings() {
        let context = GreetBackgroundContext(reduceMotion: false)

        #expect(!context.reduceTransparency)
        #expect(context.colorSchemeContrast == .standard)
        #expect(!context.gradientAccessibility.prefersFlatBackground)
    }

    @Test
    func backgroundContextFlagsEitherAccessibilitySetting() {
        let transparency = GreetBackgroundContext(reduceMotion: false, reduceTransparency: true)
        let contrast = GreetBackgroundContext(reduceMotion: false, colorSchemeContrast: .increased)

        #expect(transparency.gradientAccessibility.prefersFlatBackground)
        #expect(contrast.gradientAccessibility.prefersFlatBackground)
    }

    /// Both settings mean the same thing for a decorative wash: less colour, more of the opaque
    /// base, so foreground contrast stops depending on where a blob happens to sit.
    @Test
    func softGradientDampsItsWashWhenAFlatBackgroundIsPreferred() {
        let standard = GreetGradientVisualTuning.soft(colorScheme: .light)
        let damped = standard.damped(for: GreetGradientAccessibility(
            reduceTransparency: true,
            increaseContrast: false))

        #expect(damped.primaryOpacity < standard.primaryOpacity)
        #expect(damped.secondaryOpacity < standard.secondaryOpacity)
        #expect(damped.accentOpacity < standard.accentOpacity)
        #expect(damped.baseTintOpacity < standard.baseTintOpacity)
        #expect(damped.topVeilOpacity > standard.topVeilOpacity)
        #expect(damped.bottomVeilOpacity > standard.bottomVeilOpacity)
        #expect(damped.bottomVeilOpacity <= 1)
    }

    @Test
    func animatedGradientDampsItsBlobsWhenAFlatBackgroundIsPreferred() {
        let standard = GreetGradientVisualTuning.animated(colorScheme: .dark)
        let damped = standard.damped(for: GreetGradientAccessibility(
            reduceTransparency: false,
            increaseContrast: true))

        #expect(damped.primaryBlobOpacity < standard.primaryBlobOpacity)
        #expect(damped.trailingBlobOpacity < standard.trailingBlobOpacity)
        #expect(damped.topVeilOpacity > standard.topVeilOpacity)
        #expect(damped.blobBlurRatio == standard.blobBlurRatio)
    }

    @Test
    func tuningIsUntouchedWithStandardAccessibilitySettings() {
        let soft = GreetGradientVisualTuning.soft(colorScheme: .light)
        let animated = GreetGradientVisualTuning.animated(colorScheme: .light)

        #expect(soft.damped(for: .standard).primaryOpacity == soft.primaryOpacity)
        #expect(animated.damped(for: .standard).primaryBlobOpacity == animated.primaryBlobOpacity)
    }

    @Test
    func tonesAreDeeperInDarkModeThanInLight() {
        let light = GreetGradientTones(brand: .indigo, colorScheme: .light)
        let dark = GreetGradientTones(brand: .indigo, colorScheme: .dark)

        #expect(light.primary == .indigo)
        #expect(dark.primary == .indigo)
        #expect(light.secondary != dark.secondary)
        #expect(light.accent != dark.accent)
    }

    /// Supporting tones used to be fixed hues — `.cyan` and `.mint` regardless of brand — so the
    /// field read as three unrelated colours. They are now washed from the brand itself.
    @Test
    func supportingTonesAreDerivedFromTheBrand() {
        let red = GreetGradientTones(brand: .red, colorScheme: .light)
        let blue = GreetGradientTones(brand: .blue, colorScheme: .light)

        #expect(red.secondary != blue.secondary)
        #expect(red.accent != blue.accent)
        #expect(red.secondary != Color.cyan)
        #expect(red.accent != Color.mint)
    }

    /// A background's own `brand:` wins over the style tint, which wins over the default.
    @Test
    func contextResolvesTheBrandColorInPrecedenceOrder() {
        let styled = GreetBackgroundContext(reduceMotion: false, brandColor: .pink)

        #expect(styled.tones(brand: .green).primary == .green)
        #expect(styled.tones(brand: nil).primary == .pink)
        #expect(GreetBackgroundContext(reduceMotion: false).tones(brand: nil).primary == .blue)
    }

    @Test
    func gradientColorNormalizerPadsEmptyInput() {
        let colors = GradientColorNormalizer.colors([])

        #expect(colors.count == 2)
        #expect(colors[0] == Tokens.background)
        #expect(colors[1] == Tokens.background)
    }

    @Test
    func gradientColorNormalizerDuplicatesASingleColor() {
        let colors = GradientColorNormalizer.colors([.teal])

        #expect(colors == [.teal, .teal])
    }

    @Test
    func gradientColorNormalizerPassesThroughTwoOrMoreColors() {
        let input: [Color] = [.red, .green, .blue]

        #expect(GradientColorNormalizer.colors(input) == input)
    }

    @Test
    func motionStrengthClampsToTheSupportedRange() {
        #expect(GreetGradientMotion(strength: -1).clampedStrength == 0)
        #expect(GreetGradientMotion(strength: 5).clampedStrength == 2)
        #expect(GreetGradientMotion(strength: 1.2).clampedStrength == 1.2)
    }

    @Test
    func motionPresetsAreOrderedFromSubtleToExpressive() {
        #expect(GreetGradientMotion.subtle.strength < GreetGradientMotion.standard.strength)
        #expect(GreetGradientMotion.standard.strength < GreetGradientMotion.expressive.strength)
    }

    @Test
    func animatedGradientCentersAreStableWithReduceMotion() {
        let first = GreetAnimatedGradientMotion.centers(
            phase: 0,
            reduceMotion: true,
            motion: .expressive)
        let second = GreetAnimatedGradientMotion.centers(
            phase: 0.5,
            reduceMotion: true,
            motion: .expressive)

        #expect(first[0].x == second[0].x)
        #expect(first[0].y == second[0].y)
    }

    @Test
    func animatedGradientCentersChangeAcrossPhases() {
        let first = GreetAnimatedGradientMotion.centers(phase: 0, reduceMotion: false)
        let second = GreetAnimatedGradientMotion.centers(phase: 0.25, reduceMotion: false)

        #expect(abs(first[0].x - second[0].x) > 0.0001)
    }

    @Test
    func animatedGradientCentersStayInsideTheCanvas() {
        for phase in stride(from: 0.0, through: 1.0, by: 0.1) {
            let centers = GreetAnimatedGradientMotion.centers(
                phase: phase,
                reduceMotion: false,
                motion: GreetGradientMotion(strength: 2))

            #expect(centers.count == 4)
            #expect(centers.allSatisfy { $0.x >= 0 && $0.x <= 1 && $0.y >= 0 && $0.y <= 1 })
        }
    }

    @Test
    func expressiveAnimatedGradientMotionTravelsFartherThanSubtleMotion() {
        let subtleStart = GreetAnimatedGradientMotion.centers(
            phase: 0,
            reduceMotion: false,
            motion: .subtle)
        let subtleEnd = GreetAnimatedGradientMotion.centers(
            phase: 0.25,
            reduceMotion: false,
            motion: .subtle)
        let expressiveStart = GreetAnimatedGradientMotion.centers(
            phase: 0,
            reduceMotion: false,
            motion: .expressive)
        let expressiveEnd = GreetAnimatedGradientMotion.centers(
            phase: 0.25,
            reduceMotion: false,
            motion: .expressive)

        #expect(self.totalTravel(from: expressiveStart, to: expressiveEnd) > self.totalTravel(from: subtleStart, to: subtleEnd))
    }

    @Test
    func expressiveAnimatedGradientMotionHasHigherVisualContrastThanSubtleMotion() {
        #expect(GreetGradientMotion.expressive.baseTintScale > GreetGradientMotion.subtle.baseTintScale)
        #expect(GreetGradientMotion.expressive.blobOpacityScale > GreetGradientMotion.subtle.blobOpacityScale)
        #expect(GreetGradientMotion.expressive.blobBlurScale < GreetGradientMotion.subtle.blobBlurScale)
    }

    private func totalTravel(from first: [CGPoint], to second: [CGPoint]) -> Double {
        zip(first, second).reduce(0) { total, pair in
            let xDistance = Double(pair.0.x - pair.1.x)
            let yDistance = Double(pair.0.y - pair.1.y)
            return total + ((xDistance * xDistance) + (yDistance * yDistance)).squareRoot()
        }
    }
}
#endif
