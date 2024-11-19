import Testing
@testable import BCTest

struct SynchronouslySatisfySuite: Loggable {
   @Test @BCTest func synchronouslySatisfyWithoutAwaitTimeout() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()
      try await awaitSatisfaction(of: need)
   }

   @Test @BCTest func synchronouslySatisfyWithAwaitTimeout() async throws {
      log()
      let need = try await needManager.need()
      need.satisfy()
      try await awaitSatisfaction(of: need, timeout: 0.25)
   }

   @Test @BCTest func synchronouslyMultiplySatisfyWithoutAwaitTimeout() async throws {
      log()
      let need = try await needManager.need(expectedCount: 2)
      need.satisfy()
      need.satisfy()
      try await awaitSatisfaction(of: need)
   }

   @BCTest @Test func synchronouslyMultiplySatisfyWithAwaitTimeout() async throws {
      log()
      let need = try await needManager.need(expectedCount: 2)
      need.satisfy()
      need.satisfy()
      try await awaitSatisfaction(of: need, timeout: 0.25)
   }

   // MARK: - inverted need

   @Test @BCTest func zeroExpectedCount() async throws {
      log()
      let need = try await needManager.need(expectedCount: 0)
      try await awaitSatisfaction(of: need)
   }
}
