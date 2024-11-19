import Testing
import Observation

struct CheckedContinuationMultipleEventsShouldFailSuite: Loggable {

   // *** !! CRASHES ***
   // ✘ Test «unknown» recorded an issue at CheckedContinuationShouldFailTests.swift:99:22: Expectation failed: (observableModel.actorValue → 2) == 1
   // XCTest/HarnessEventHandler.swift:168: Fatal error: Issue recorded event did not contain a test
   @Test @MainActor func shouldFail() async throws {
      let observableModel = ObservableModel()
      try #require(observableModel.actorValue == nil)

      try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) -> Void in
         @Sendable func observeActorValue(count: Int) {
            withObservationTracking {
               log("observing observableModel.actorValue=\(String(describing: observableModel.actorValue)) count=\(count)")
            } onChange: {
               Task { @MainActor in
                  log("onChange observableModel.actorValue=\(String(describing: observableModel.actorValue))")
                  switch count {
                  case 0:
                     #expect(observableModel.actorValue == nil)
                  case 1:
                     #expect(observableModel.actorValue == 1)
                     cont.resume()
                  default:
                     Issue.record("recursed on observeActorModel (\(count) times, expected once")
                  }
                  observeActorValue(count: count + 1) // recurse
               }
            }
         }
         observeActorValue(count: 0)

         observableModel.buttonPressed()
         do {
            try #require(observableModel.actorValue == nil)
         } catch {
            cont.resume(throwing: error)
         }
      }
   }

   // *** !! BUG ***
   // Does not record Issue at #expect in case 1
   @Test @MainActor func shouldFail_earlyContinuation() async throws {
      let observableModel = ObservableModel()
      try #require(observableModel.actorValue == nil)

      try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) -> Void in
         @Sendable func observeActorValue(count: Int) {
            withObservationTracking {
               log("observing observableModel.actorValue=\(String(describing: observableModel.actorValue)) count=\(count)")
            } onChange: {
               Task { @MainActor in
                  log("onChange observableModel.actorValue=\(String(describing: observableModel.actorValue))")
                  switch count {
                  case 0:
                     #expect(observableModel.actorValue == nil)
                     cont.resume() // *** !! EARLY ***
                  case 1:
                     #expect(observableModel.actorValue == 1) // *** !! SHOULD FAIL BUT NO ISSUE RECORDED ***
                  default:
                     Issue.record("recursed on observeActorModel (\(count) times, expected once")
                  }
                  observeActorValue(count: count + 1) // recurse
               }
            }
         }
         observeActorValue(count: 0)

         observableModel.buttonPressed()
         do {
            try #require(observableModel.actorValue == nil)
         } catch {
            cont.resume(throwing: error)
         }
      }
   }
}

// MARK: - model

@Observable private final class ObservableModel: @unchecked Sendable, Loggable {
   private(set) var actorValue: Int?

   private let actorModel = ActorModel()

   @MainActor func buttonPressed() {
      log()
      actorValue = nil // reset

      Task.detached {
         let newActorValue = await self.actorModel.doMyThing()
         #expect(newActorValue == 1)
         Task { @MainActor [weak self] in
            self?.actorValue = 2 // *** !! MISTAKE ***
         }
      }
   }
}

private actor ActorModel: Loggable {
   func doMyThing() -> Int {
      log()
      return 1
   }
}
