import Testing
import Foundation

/// A necessary outcome in an asynchronous swift test. A `BCTestNeed` must be both satisfied and have been awaited on when a
/// `BCTestNeedManager` asserts its satisfaction. Create a `BCTestNeed` with a `BCTestNeedManager` provided by the `@BCTest`
/// macro.
///
/// Satisfaction requires both invoking `satisfy()` `expectedCount` times and awaiting satisfaction by passing the need to an
/// invocation of global func `awaitSatisfaction(of:timeOut:)`.
///
/// A need can be configured to raise an `Issue` if `satisfy()` is invoked more than `expectedCount` times.
public actor BCTestNeed: Loggable {
   public nonisolated let id = UUID()

   private let comment: Comment?
   private let expectedCount: Int
   private let issueForOverSatisfied: Bool
   private let sourceLocation: SourceLocation

   private var receivedCount: Int = 0
   private var continuation: AsyncStream<Void>.Continuation?

   private enum AwaitState { case notStarted, started, ended }
   private var awaitState = AwaitState.notStarted

   private var didSatisfy = false
   private var didTimeout = false

   // MARK: - init

   internal init(
      comment: Comment?,
      expectedCount: Int,
      issueForOverSatisfied: Bool,
      sourceLocation: SourceLocation
   ) {
      self.comment = comment
      self.expectedCount = max(expectedCount, 0)
      self.issueForOverSatisfied = issueForOverSatisfied
      self.sourceLocation = sourceLocation
      didSatisfy = expectedCount == 0
   }

   // MARK: - satisfy

   /// Increments received count and if received count then equals expected count, marks as satisfied.
   ///
   /// Method is `nonisolated` so as to avoid suspending caller which may require synchronous code to accurately test a flow.
   public nonisolated func satisfy() {
      Task { await _satisfy() }
   }

   private func _satisfy() {
      log("\(comment ?? "")")
      receivedCount += 1
      guard receivedCount == expectedCount else { return }

      // Invariant: a need can be satisfied before await starts or during await
      didSatisfy = awaitState != .ended

      continuation?.finish()
      continuation = nil
   }

   // MARK: - await satisfaction

   /// Await satisfaction of this need (if not yet awaited) with optional timeout.
   ///
   /// If this need has not yet been awaited, this method only returns on satisfaction or time out, whichever occurs first. If
   /// this need is already satisfied, this method returns immediately else suspends. If this need has already been awaited, this
   /// method immediately throws `AwaitError.alreadyAwaited` whether or not this need is satisfied. Satisfaction of a need can
   /// only be awaited once.
   internal func awaitSatisfaction(timeout: TimeInterval = .infinity) async throws(AwaitError) {
      log("\(comment ?? "")")

      // MUST not have been awaited
      guard awaitState == .notStarted else {
         // Invariant: a test fails if need is awaited more than once
         let str = (comment?.rawValue ?? "<no description>") + ": satisfied \(receivedCount) times, expected \(expectedCount)"
         throw .alreadyAwaited(str, sourceLocation)
      }

      awaitState = .started
      defer { awaitState = .ended }

      // MUST return if already satisfied
      guard !didSatisfy else { return }

      let stream = AsyncStream<Void> { continuation = $0 }
      var timeoutTask: Task<Void, Error>?

      if timeout < .infinity {
         timeoutTask = Task {
            try await Task.sleep(for: .milliseconds(Int(timeout * 1000)))
            guard continuation != nil else { return }
            didTimeout = true
            continuation?.finish()
            continuation = nil
         }
      }

      // Invariant: an await can be canceled
      for await _ in stream {}
      timeoutTask?.cancel()
   }

   // MARK: - assert satisfaction

   /// Raise an `Issue` if this need is not satisfied nor awaited.
   internal func assertSatisfied() {
      log("\(comment ?? "")")
      let stateStr = (comment?.rawValue ?? "<no description>") + ": satisfied \(receivedCount) times, expected \(expectedCount)"

      switch awaitState {
      case .notStarted:
         // Invariant: a test fails if need is not awaited
         Issue.record(SatisfyError.unAwaited, Comment(rawValue: stateStr), sourceLocation: sourceLocation)
      case .started:
         // Invariant: a test fails if await is not ended when asserted
         Issue.record(SatisfyError.unAwaited, Comment(rawValue: stateStr), sourceLocation: sourceLocation)
         continuation?.finish()
         continuation = nil
      case .ended:
         guard !didTimeout else {
            // Invariant: a test fails if await times out
            Issue.record(SatisfyError.timedOut, Comment(rawValue: stateStr), sourceLocation: sourceLocation)
            return
         }

         guard didSatisfy else {
            // Invariant: a test fails if need is not satisfied before await ends
            Issue.record(SatisfyError.unsatisfied, Comment(rawValue: stateStr), sourceLocation: sourceLocation)
            return
         }

         if receivedCount > expectedCount && issueForOverSatisfied {
            // Invariant: a test can be configured to fail if need is over satisfied
            Issue.record(SatisfyError.overSatisfied, Comment(rawValue: stateStr), sourceLocation: sourceLocation)
         }
      }
   }
}

// MARK: - error

extension BCTestNeed {
   public enum AwaitError: Error, CustomStringConvertible, Sendable {
      case alreadyAwaited(String, SourceLocation)

      public var description: String {
         switch self {
         case .alreadyAwaited: return "BCTestNeed satisfaction can only be awaited once"
         }
      }
   }

   internal enum SatisfyError: Error, CustomStringConvertible {
      case unAwaited
      case timedOut
      case unsatisfied
      case overSatisfied

      public var description: String {
         switch self {
         case .unAwaited: return "BCTestNeed satisfaction must be awaited"
         case .timedOut: return "BCTestNeed await satisfaction timed out"
         case .unsatisfied: return "BCTestNeed is not satisfied"
         case .overSatisfied: return "BCTestNeed is over satisfied"
         }
      }
   }
}

// MARK: - hashable

extension BCTestNeed: Hashable {
   public static func == (lhs: BCTestNeed, rhs: BCTestNeed) -> Bool {
      lhs.id == rhs.id
   }
   
   nonisolated public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
   }
}
