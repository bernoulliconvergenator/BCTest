import Testing
import Foundation

/// Wait on a need to be satisfied with an optional timeout.
///
/// - Parameters:
///   - need: a `BCTestNeed` to wait on.
///   - timeout: optional time, in seconds, to wait for satisfaction of `need`.
///
/// Does not return until `need` is satisfied or until timeout, if any, elapses.
public func awaitSatisfaction(
   of need: BCTestNeed,
   timeout: TimeInterval = .infinity
) async throws {
   try await awaitSatisfaction(of: [need], timeout: timeout)
}

/// Wait on a set of needs to be satisfied with an optional timeout.
///
/// - Parameters:
///   - needs: the `BCTestNeed`s to wait on.
///   - timeout: optional time, in seconds, to wait for satisfaction of all `needs`.
///
/// Does not return until all needs are satisfied or until timeout, if any, elapses.
public func awaitSatisfaction(
   of needs: Set<BCTestNeed>,
   timeout: TimeInterval = .infinity
) async throws {
   log()

   do {
      try await withThrowingTaskGroup(of: Void.self) { group in
         for need in needs {
            let addedTask = group.addTaskUnlessCancelled {
               try await need.awaitSatisfaction(timeout: timeout)
            }
            if !addedTask { break }
         }

         // Must for try await to detect if a child task throws BCTestNeed.AwaitError.alreadyAwaited, the only error possible.
         // If thrown, the already awaited BCTestNeed will report 2 errors: already having been awaited and unsatisfied.
         // Also, the thrown already awaited error exits this for try await loop and causes all other child tasks to be canceled.
         // An await for satisfaction in a child task is cooperatively cancelled and the BCTestNeed will report unsatisfied.
         for try await _ in group {}
      }
   } catch {
      guard case BCTestNeed.AwaitError.alreadyAwaited(let str, let sourceLocation) = error else { throw error }
      Issue.record(error, Comment(rawValue: str), sourceLocation: sourceLocation)
   }
}
