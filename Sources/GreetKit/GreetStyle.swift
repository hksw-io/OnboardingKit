#if os(iOS) || os(macOS)
import SwiftUI

/// The brand colour for the sheet.
///
/// `GreetView` applies it with `.tint`, so the prominent glass button, the feature icons, and any
/// tinted control in a destination all take it from the environment. It is also what the built-in
/// gradient backgrounds derive their palette from, which is why the value is carried here rather
/// than left to a plain `.tint` modifier at the call site: a background cannot read the
/// environment's tint back out.
public struct GreetStyle: Sendable {
    public var tint: Color?

    public static let standard = Self()

    public init(tint: Color? = nil) {
        self.tint = tint
    }
}
#endif
