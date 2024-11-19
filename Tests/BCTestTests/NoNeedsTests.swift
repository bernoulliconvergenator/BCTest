import Testing
@testable import BCTest

struct NoNeedsSuite: Loggable {
   @Test @BCTest func zeroNeeds() async throws {
      log()
   }
}
