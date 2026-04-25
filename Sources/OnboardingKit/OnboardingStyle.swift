#if os(iOS) || os(macOS)
import SwiftUI

public struct OnboardingStyle {
    public var tint: Color?
    public var titleColor: Color?
    public var subtitleColor: Color?
    public var featureIconColor: Color?
    public var featureTitleColor: Color?
    public var featureDescriptionColor: Color?
    public var nextStepsTitleColor: Color?
    public var nextStepIconColor: Color?
    public var nextStepTitleColor: Color?
    public var nextStepDescriptionColor: Color?
    public var nextStepActionColor: Color?
    public var nextStepAccessoryColor: Color?
    public var primaryButtonForegroundColor: Color?
    public var primaryButtonProgressTint: Color?
    public var secondaryButtonColor: Color?

    public static var standard: Self {
        Self()
    }

    public init(
        tint: Color? = nil,
        titleColor: Color? = nil,
        subtitleColor: Color? = nil,
        featureIconColor: Color? = nil,
        featureTitleColor: Color? = nil,
        featureDescriptionColor: Color? = nil,
        nextStepsTitleColor: Color? = nil,
        nextStepIconColor: Color? = nil,
        nextStepTitleColor: Color? = nil,
        nextStepDescriptionColor: Color? = nil,
        nextStepActionColor: Color? = nil,
        nextStepAccessoryColor: Color? = nil,
        primaryButtonForegroundColor: Color? = nil,
        primaryButtonProgressTint: Color? = nil,
        secondaryButtonColor: Color? = nil)
    {
        self.tint = tint
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.featureIconColor = featureIconColor
        self.featureTitleColor = featureTitleColor
        self.featureDescriptionColor = featureDescriptionColor
        self.nextStepsTitleColor = nextStepsTitleColor
        self.nextStepIconColor = nextStepIconColor
        self.nextStepTitleColor = nextStepTitleColor
        self.nextStepDescriptionColor = nextStepDescriptionColor
        self.nextStepActionColor = nextStepActionColor
        self.nextStepAccessoryColor = nextStepAccessoryColor
        self.primaryButtonForegroundColor = primaryButtonForegroundColor
        self.primaryButtonProgressTint = primaryButtonProgressTint
        self.secondaryButtonColor = secondaryButtonColor
    }
}

extension OnboardingStyle {
    var subtitleForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.subtitleColor, fallback: AnyShapeStyle(.secondary))
    }

    var featureIconForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.featureIconColor ?? self.tint, fallback: AnyShapeStyle(.tint))
    }

    var featureDescriptionForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.featureDescriptionColor, fallback: AnyShapeStyle(.secondary))
    }

    var nextStepIconForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.nextStepIconColor ?? self.tint, fallback: AnyShapeStyle(.tint))
    }

    var nextStepDescriptionForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.nextStepDescriptionColor, fallback: AnyShapeStyle(.secondary))
    }

    var nextStepActionForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.nextStepActionColor ?? self.tint, fallback: AnyShapeStyle(.tint))
    }

    var nextStepAccessoryForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.nextStepAccessoryColor, fallback: AnyShapeStyle(.secondary))
    }

    var secondaryButtonForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.secondaryButtonColor, fallback: AnyShapeStyle(.secondary))
    }

    var resolvedPrimaryButtonProgressTint: Color {
        self.primaryButtonProgressTint ?? self.primaryButtonForegroundColor ?? .white
    }

    private static func foregroundStyle(for color: Color?, fallback: AnyShapeStyle) -> AnyShapeStyle {
        guard let color else {
            return fallback
        }

        return AnyShapeStyle(color)
    }
}
#endif
