import Testing
import Foundation
@testable import BCTest

struct MultipleAwaitSuite: Loggable {

   // MARK: - synchronous multiple await

   @Test("should catch error BCTestNeed.AwaitError.alreadyAwaited")
   @BCTest func synchronousMultipleAwait() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()

      try await awaitSatisfaction(of: need)

      await withKnownIssue {
         try await awaitSatisfaction(of: need) // !!
      }
   }

   // MARK: - asynchronous multiple await

   // Awaiting a need asynchronously from satisfy works/passes but if a second asynchronous await is added (which raises Issue
   // already awaited), this code crashes with "Thread 2: Fatal error: Issue recorded event did not contain a test".
   // Console reports "XCTest/HarnessEventHandler.swift:168: Fatal error: Issue recorded event did not contain a test".
   @Test(
      "should catch error BCTestNeed.AwaitError.alreadyAwaited",
      .disabled("crashes: XCTest/HarnessEventHandler.swift:168: Fatal error: Issue recorded event did not contain a test")
   )
   @BCTest @MainActor func asynchronousMultipleAwait() async throws {
      log()
      let need = try await needManager.need()

      Task.detached {
         try await awaitSatisfaction(of: need)

         await withKnownIssue {
            try await awaitSatisfaction(of: need) // !!
         }
      }

      need.satisfy()

      try await Task.sleep(for: .milliseconds(200))
   }
}
