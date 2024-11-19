import Testing
import Foundation
@testable import BCTest

struct OverSatisfiedySuite: Loggable {

   // MARK: - synchronously over satisfy

   @Test("should catch error BCTestNeed.SatisfyError.overSatisfied")
   @BCTest(.withKnownIssue)
   func synchronouslyOverSatisfyWithoutAwaitTimeout() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()
      need.satisfy()
      try await awaitSatisfaction(of: need)
   }

   @Test("should catch error BCTestNeed.SatisfyError.overSatisfied")
   @BCTest(.withKnownIssue)
   func synchronouslyOverSatisfyWithAwaitTimeout() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()
      need.satisfy()
      try await awaitSatisfaction(of: need, timeout: 0.25)
   }

   // MARK: - asynchronously

   @Test("should catch error BCTestNeed.SatisfyError.overSatisfied")
   @BCTest(.withKnownIssue)
   func asynchronouslyOverSatisfyInDetachedTask() async throws {
      log()
      let need = try await needManager.need()

      Task.detached {
         need.satisfy()
         need.satisfy()
      }

      try await awaitSatisfaction(of: need)
   }

   // MARK: - no issue for over satisfy

   @Test @BCTest func synchronouslyOverSatisfyWithoutAwaitTimeout_overSatisfyOK() async throws {
      log()
      let need = try await needManager.need(issueForOverSatisfied: false)
      need.satisfy()
      need.satisfy()
      try await awaitSatisfaction(of: need)
   }

   @Test @BCTest func synchronouslyOverSatisfyWithAwaitTimeout_overSatisfyOK() async throws {
      log()
      let need = try await needManager.need(issueForOverSatisfied: false)
      need.satisfy()
      need.satisfy()
      try await awaitSatisfaction(of: need, timeout: 0.25)
   }

   @Test @BCTest func asynchronouslyOverSatisfyInDetachedTask_overSatisfyOK() async throws {
      log()
      let need = try await needManager.need(issueForOverSatisfied: false)

      Task.detached {
         need.satisfy()
         need.satisfy()
      }

      try await awaitSatisfaction(of: need)
   }

   // MARK: - inverted need

   @Test
   @BCTest(.withKnownIssue) func overSatisfiedZeroExpectedCount() async throws {
      log()
      let need = try await needManager.need(expectedCount: 0)
      need.satisfy()
      try await awaitSatisfaction(of: need)
   }
}
