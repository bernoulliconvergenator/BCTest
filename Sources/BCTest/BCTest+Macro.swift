/// Options for configuring whether a `BCTestNeedManager` assertion will or won't raise at least one `Issue`.
public enum BCTestMacroTrait {
   case noIssue
   case withKnownIssue
}

/// Adds to the head of a swift test body an instantiation of `BCTestNeedManager` named `needManager`, and adds to bottom of the
/// swift test body an invocation of `assertNeedsSatisfied()` on `needManager`.
///
/// - Parameters:
///   - trait: a `BCTestMacroTrait`.
///
/// If passed `withKnownIssue`, the `assertNeedsSatisfied()` invoked on the `BCTestNeedManager` added to the swift test will be
/// embedded in a `withKnownIssue` expression. If passed `noIssue` (the default), it won't.
///
/// Can only be attributed to a `@Test` swift test.
@attached(body)
public macro BCTest(_ trait: BCTestMacroTrait = .noIssue) = #externalMacro(module: "BCTestMacros", type: "BCTestMacro")
