import Testing
import Observation
import Foundation
@testable import BCTest

/// A `Suite` of tests that catch `unAwaited`, `timedOut`, and `unsatisfied` errors.
struct UnsatisfiedSuite: Loggable {

   // MARK: - neglect to satisfy

   @Test(
      .disabled("since no timeout on await on never satisfied need, test hits timeLimit and fails, as expected"),
      .timeLimit(.minutes(1))
   )
   @BCTest(.withKnownIssue)
   func awaitedButNeverSatisfiedWithoutAwaitTimeout() async throws {
      log()
      let need = try await needManager.need()
      // need.satisfy()
      try await awaitSatisfaction(of: need)
   }

   @Test("should catch error BCTestNeed.SatisfyError.timedOut")
   @BCTest(.withKnownIssue)
   func awaitedButNeverSatisfiedWithAwaitTimeout() async throws {
      log()
      let need = try await needManager.need()
      // need.satisfy()
      try await awaitSatisfaction(of: need, timeout: 0.25) // will timeout
   }

   // MARK: - neglect to await

   @Test("should catch error BCTestNeed.SatisfyError.unAwaited")
   @BCTest(.withKnownIssue)
   func satisfiedButNeverAwaited() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()
      // try await awaitSatisfaction(of: need)
   }

   // MARK: - neglect to satisfy. neglect to await

   @Test("should catch error BCTestNeed.SatisfyError.unAwaited")
   @BCTest(.withKnownIssue)
   func neverSatisfiedNorAwaited() async throws {
      log()
      let _ = try await needManager.need()
      // need.satisfy()
      // try await awaitSatisfaction(of: need)
   }

   // MARK: - satisfy after await completed

   @Test("should catch error BCTestNeed.SatisfyError.timedOut")
   @BCTest(.withKnownIssue)
   func awaitedBeforeSatisfied() async throws {
      log()
      let need = try await needManager.need()
      try await awaitSatisfaction(of: need, timeout: 0.25) // will timeout
      need.satisfy()
   }

   // MARK: - assert before await complete

   @Test("should catch error BCTestNeed.SatisfyError.unAwaited")
   @BCTest(.withKnownIssue)
   func asynchronouslyAssertedBeforeAwaited() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()

      Task.detached {
         try await Task.sleep(for: .milliseconds(250))
         try await awaitSatisfaction(of: need)
      }
   }

   @Test("should catch error BCTestNeed.SatisfyError.unAwaited")
   @BCTest(.withKnownIssue)
   func asynchronouslyAssertedWhileAwaiting() async throws {
      log()
      let need = try await needManager.need()

      // 0.00 async await
      // 0:00.2 assert
      // 0:00.4 async satisfy

      Task.detached {
         try await awaitSatisfaction(of: need)
      }

      let _ = Task.detached {
         try await Task.sleep(for: .milliseconds(400))
         need.satisfy()
      }

      try await Task.sleep(for: .milliseconds(200))
   }

   // MARK: - await cooperative cancellation

   @Test("should catch error BCTestNeed.SatisfyError.unsatisfied")
   @BCTest(.withKnownIssue)
   @MainActor func awaitedButCooperativelyCanceled_neverSatisfied() async throws {
      log()

      let need = try await needManager.need()

      let awaitTask = Task.detached {
         try await awaitSatisfaction(of: need)
      }

      try await Task.sleep(for: .milliseconds(250))
      // need.satisfy()
      awaitTask.cancel()
   }

   @Test("should catch error BCTestNeed.SatisfyError.unsatisfied")
   @BCTest(.withKnownIssue)
   @MainActor func awaitedButCooperativelyCanceled_satisfiedAfterCancel() async throws {
      log()

      let need = try await needManager.need()

      let awaitTask = Task.detached {
         try await awaitSatisfaction(of: need)
      }

      try await Task.sleep(for: .milliseconds(250))
      awaitTask.cancel()

      try await Task.sleep(for: .milliseconds(250))
      need.satisfy()
   }

   // MARK: - under satisfied

   @Test("should catch error BCTestNeed.SatisfyError.timedOut")
   @BCTest(.withKnownIssue)
   @MainActor func awaitedButUnderSatisfiedWithAwaitTimeout() async throws {
      log()
      let need = try await needManager.need(expectedCount: 2)
      need.satisfy()
      try await awaitSatisfaction(of: need, timeout: 0.25) // will timeout
   }

   // MARK: - with observable model that performs async task

   @Test("should catch error BCTestNeed.SatisfyError.timedOut")
   @BCTest(.withKnownIssue)
   @MainActor func awaitedButNeverSatisfied_ModelDidAsyncThingWithAwaitTimeout() async throws {
      log()

      let observableModel = ObservableModel()
      let need = try await needManager.need("model did async thing")

      withObservationTracking {
         assert(!observableModel.didAsyncThing)
      } onChange: {
         Task { @MainActor in
            log("onChange observableModel.didAsyncThing=\(observableModel.didAsyncThing)")
            #expect(observableModel.didAsyncThing)
            // need.satisfy()
         }
      }
      observableModel.doAsyncThing()

      try await awaitSatisfaction(of: need, timeout: 0.25) // will timeout

      // prove model change occurred
      #expect(observableModel.didAsyncThing)
   }
}

// MARK: - observable model

@Observable private final class ObservableModel: @unchecked Sendable, Loggable {
   private(set) var didAsyncThing = false

   @MainActor func doAsyncThing() {
      log()
      Task.detached {
         Task { @MainActor [weak self] in
            self?.didAsyncThing = true
         }
      }
   }
}
