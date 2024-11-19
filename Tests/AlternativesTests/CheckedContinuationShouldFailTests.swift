import Testing

// Tests demonstrating various outcomes from invoking a CheckedContinuation before invoking test macros.

// MARK: - expect failures

struct CheckedContinuationShouldFailSuite {
   @Test func shouldFail() async throws {
      let myBool = false
      #expect(myBool)
   }

   @Test func shouldFailWithCheckedContinuation() async throws {
      let myBool = false
      await withCheckedContinuation { continuation in
         continuation.resume()
         #expect(myBool)
      }
   }

   @Test func shouldFailWithCheckedContinuationWithTask() async throws {
      let myBool = false
      await withCheckedContinuation { continuation in
         Task {
            continuation.resume()
            #expect(myBool)
         }
      }
   }

   // *** !! SHOULD FAIL BUT DOES NOT ***
   @Test func shouldFailWithCheckedContinuationWithTaskWithSleep() async throws {
      let myBool = false
      await withCheckedContinuation { continuation in
         Task {
            continuation.resume()
            try? await Task.sleep(for: .milliseconds(200))
            #expect(myBool)
         }
      }
   }
}

// MARK: - with known issue

struct CheckedContinuationWithKnownIssueSuite {
   @Test func shouldFail() async throws {
      let myBool = false
      withKnownIssue { #expect(myBool) }
   }

   @Test func shouldFailWithCheckedContinuation() async throws {
      let myBool = false
      await withCheckedContinuation { continuation in
         continuation.resume()
         withKnownIssue { #expect(myBool) }
      }
   }

   // *** !! INTERMITTENT CRASHES *** (generally on 2nd run)
   // XCTest/HarnessEventHandler.swift:295: Fatal error: Internal inconsistency: No test reporter for test case argumentIDs: Optional([]) in test
   @Test func shouldFailWithCheckedContinuationWithTask() async throws {
      let myBool = false
      await withCheckedContinuation { continuation in
         Task {
            continuation.resume()
            withKnownIssue { #expect(myBool) }
         }
      }
   }

   // *** !! DOES NOT RECORD KNOWN ISSUE ***
   @Test func shouldFailWithCheckedContinuationWithTaskWithSleep() async throws {
      let myBool = false
      await withCheckedContinuation { continuation in
         Task {
            continuation.resume()
            try? await Task.sleep(for: .milliseconds(200))
            withKnownIssue { #expect(myBool) }
         }
      }
   }
}
