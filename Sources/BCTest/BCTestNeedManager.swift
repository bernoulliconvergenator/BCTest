import Testing
import Foundation

/// A provider and manager of instances of `BCTestNeed` created in a swift test.
///
/// A `BCTestNeed` can only be created with a `BCTestNeedManager` and satisfaction of a `BCTestNeed` can only be asserted by
/// invoking `assertNeedsSatisfied()` on the manager that created it.
///
/// Both a `BCTestNeedManager` and assertion of the satisfaction of the needs it created are provided by the `@BCTest` macro.
public actor BCTestNeedManager: Loggable {
   private var needs: [BCTestNeed] = []
   private var didAssert = false

   // MARK: - init

   public init() {}

   // MARK: - new need

   /// Create and manage a new `BCTestNeed`.
   public func need(
      _ comment: Comment? = nil,
      expectedCount: Int = 1,
      issueForOverSatisfied: Bool = true,
      sourceLocation: SourceLocation = #_sourceLocation
   ) throws -> BCTestNeed {
      log("\(comment ?? "")")

      guard !didAssert else {
         throw Error.alreadyAsserted
      }

      let need = BCTestNeed(
         comment: comment,
         expectedCount: expectedCount,
         issueForOverSatisfied: issueForOverSatisfied,
         sourceLocation: sourceLocation
      )
      needs.append(need)
      return need
   }

   // MARK: - assert needs satisfied

   /// Assert satisfaction on all needs created by this manager.
   public func assertNeedsSatisfied() async {
      log()

      didAssert = true

      for need in needs {
         await need.assertSatisfied()
      }
   }
}

// MARK: - error

extension BCTestNeedManager {
   public enum Error: Swift.Error, CustomStringConvertible {
      case alreadyAsserted

      public var description: String {
         switch self {
         case .alreadyAsserted: return "Cannot create test needs after asserting satisfaction"
         }
      }
   }
}
