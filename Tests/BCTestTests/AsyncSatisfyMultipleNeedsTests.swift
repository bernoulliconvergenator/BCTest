import Testing
import Foundation
import Observation
@testable import BCTest

struct AsyncSatisfyMultipleNeedsSuite: Loggable {
   @Test @BCTest @MainActor func asynchronouslySatisfyMultipleNeeds_usingBCTestNeed() async throws {
      log()

      let needActorValue = try await needManager.need("change actor value", expectedCount: 2)
      let needButtonEnabled = try await needManager.need("toggle button state", expectedCount: 2)

      let observableModel = ObservableModel()
      try #require(observableModel.actorValue == nil)
      try #require(observableModel.buttonEnabled)

      @Sendable func observeActorValue(count: Int) {
         withObservationTracking {
            log("observing observableModel.actorValue count=\(count) current=\(String(describing: observableModel.actorValue))")
         } onChange: {
            Task { @MainActor in
               log("onChange observableModel.actorValue=\(String(describing: observableModel.actorValue))")
               switch count {
               case 0:
                  #expect(observableModel.actorValue == nil)
                  needActorValue.satisfy()
                  observeActorValue(count: count + 1) // recurse
               case 1:
                  #expect(observableModel.actorValue == 1)
                  needActorValue.satisfy()
               default:
                  Issue.record("recursed on observeActorModel too many times")
               }
            }
         }
      }
      observeActorValue(count: 0)

      @Sendable func observeButtonState(count: Int) {
         withObservationTracking {
            log(" observing observableModel.buttonEnabled count=\(count) current=\(observableModel.buttonEnabled)")
         } onChange: {
            Task { @MainActor in
               log("onChange observableModel.buttonEnabled=\(observableModel.buttonEnabled)")
               switch count {
               case 0:
                  #expect(!observableModel.buttonEnabled)
                  needButtonEnabled.satisfy()
                  observeButtonState(count: count + 1) // recurse
               case 1:
                  #expect(observableModel.buttonEnabled)
                  needButtonEnabled.satisfy()
               default:
                  Issue.record("recursed on observeButtonState too many times")
               }
            }
         }
      }
      observeButtonState(count: 0)

      observableModel.doActorModelThing()
      try #require(observableModel.actorValue == nil)
      try #require(!observableModel.buttonEnabled)

      try await awaitSatisfaction(of: [needActorValue, needButtonEnabled])
   }
}

// MARK: - model

@Observable private final class ObservableModel: @unchecked Sendable, Loggable {
   private(set) var actorValue: Int?
   private(set) var buttonEnabled = true

   private let actorModel = ActorModel()

   // MARK: - button actions

   @MainActor func doActorModelThing(delay: TimeInterval = 0.0) {
      log()
      buttonEnabled = false
      actorValue = nil

      Task.detached { [weak self] in
         if delay > 0.0 {
            try await Task.sleep(for: .nanoseconds(Int64(delay * 1_000_000_000)))
         }

         guard let self else { return }
         let newActorValue = try await self.actorModel.doThing(delay: delay)

         Task { @MainActor [weak self] in
            self?.actorValue = newActorValue
            self?.buttonEnabled = true
         }
      }
   }
}

private actor ActorModel: Loggable {
   func doThing(delay: TimeInterval = 0) async throws -> Int {
      log()

      if delay > 0.0 {
         log("starting sleep")
         try await Task.sleep(for: .nanoseconds(Int(delay * 1_000_000_000)))
         log("sleep ended")
      }

      return 1
   }
}


