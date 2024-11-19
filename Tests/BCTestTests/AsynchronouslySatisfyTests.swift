import Testing
import Observation
import Foundation
@testable import BCTest

struct AsynchronousSatisfySuite: Loggable {
   @Test @BCTest func asynchronouslySatisfyInDetachedTask() async throws {
      log()
      let need = try await needManager.need()

      Task.detached {
         need.satisfy()
      }

      try await awaitSatisfaction(of: need)
   }

   @Test @BCTest func asynchronouslyMultiplySatisfyInDetachedTask() async throws {
      log()
      let need = try await needManager.need(expectedCount: 2)

      Task.detached {
         need.satisfy()
         need.satisfy()
      }

      try await awaitSatisfaction(of: need)
   }

   @Test @BCTest func asynchronouslySatisfyInDetachedTaskBeforeAwaiting() async throws {
      log()
      let need = try await needManager.need()

      Task.detached {
         need.satisfy()
      }

      try await Task.sleep(for: .milliseconds(200))
      try await awaitSatisfaction(of: need)
   }

   @Test @BCTest func asynchronouslySatisfyInDetachedTaskWhileAwaiting() async throws {
      log()
      let need = try await needManager.need()

      Task.detached {
         try await Task.sleep(for: .milliseconds(100))
         need.satisfy()
      }

      try await awaitSatisfaction(of: need)
   }

   // MARK: - with observable model that performs async task

   @Test @BCTest @MainActor func asynchronouslySatisfiedModelDidAsyncThingWithoutDelay() async throws {
      log()
      let observableModel = ObservableModel()
      let need = try await needManager.need("did async thing")
      withObservationTracking {
         assert(!observableModel.didAsyncThing)
      } onChange: {
         Task { @MainActor in
            log("onChange observableModel.didAsyncThing=\(observableModel.didAsyncThing)")
            #expect(observableModel.didAsyncThing)
            need.satisfy()
         }
      }
      observableModel.doAsyncThing()
      try await awaitSatisfaction(of: need)
   }

   @Test @BCTest @MainActor func asynchronouslySatisfiedModelDidAsyncThingWithDelay() async throws {
      log()
      let observableModel = ObservableModel()
      let need = try await needManager.need("did async thing")
      withObservationTracking {
         assert(!observableModel.didAsyncThing)
      } onChange: {
         Task { @MainActor in
            log("onChange observableModel.didAsyncThing=\(observableModel.didAsyncThing)")
            #expect(observableModel.didAsyncThing)
            need.satisfy()
         }
      }
      observableModel.doAsyncThing(delay: 0.25)
      try await awaitSatisfaction(of: need)
   }
}

// MARK: - observable model

@Observable private final class ObservableModel: @unchecked Sendable, Loggable {
   private(set) var didAsyncThing = false

   @MainActor func doAsyncThing(delay: TimeInterval = 0.0) {
      log()
      Task.detached {
         if delay > 0.0 {
            try await Task.sleep(for: .nanoseconds(Int64(delay * 1_000_000_000)))
         }
         Task { @MainActor [weak self] in
            self?.didAsyncThing = true
         }
      }
   }
}
