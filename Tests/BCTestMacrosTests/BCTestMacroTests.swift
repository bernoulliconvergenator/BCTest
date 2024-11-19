import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import BCTest

#if canImport(BCTestMacros)
import BCTestMacros

let testMacros: [String: Macro.Type] = ["BCTest": BCTestMacro.self]
#endif

final class BCTestMacroTests: XCTestCase, Loggable {
   
   // MARK: - legal invocations

   func testEmptyBody() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest func test() async {}
         """,
         expandedSource:
         """
         @Test func test() async {
             let needManager = BCTestNeedManager()
             await needManager.assertNeedsSatisfied()
         }
         """,
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   func testEmptyBody_withNoIssueArg() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest(.noIssue) func test() async {}
         """,
         expandedSource:
         """
         @Test func test() async {
             let needManager = BCTestNeedManager()
             await needManager.assertNeedsSatisfied()
         }
         """,
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   func testOneStatementBody() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest func test() async {
            log()
         }
         """,
         expandedSource:
         """
         @Test func test() async {
             let needManager = BCTestNeedManager()
             log()
             await needManager.assertNeedsSatisfied()
         }
         """,
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   func testOneLinerBody() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         #"""
         @Test @BCTest func test() async { for idx in 0...2 { log("\(idx)") } }
         """#,
         expandedSource:
         #"""
         @Test func test() async {
             let needManager = BCTestNeedManager()
             for idx in 0 ... 2 {
                 log("\(idx)")
             }
             await needManager.assertNeedsSatisfied()
         }
         """#,
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   func testOneLinerBodyWithSemicolons() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest func test() async { log(); log() }
         """,
         expandedSource:
         """
         @Test func test() async {
             let needManager = BCTestNeedManager()
             log();
             log()
             await needManager.assertNeedsSatisfied()
         }
         """,
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   // MARK: - with known issue

   func testWithKnownIssue() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest(.withKnownIssue) func test() async {}
         """,
         expandedSource:
         """
         @Test func test() async {
             let needManager = BCTestNeedManager()
             await withKnownIssue {
                 await needManager.assertNeedsSatisfied()
             }
         }
         """,
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   // MARK: - illegal invocations

   func testNonAsyncDiagnostic() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest func test() {}
         """,
         expandedSource:
         """
         @Test func test() {}
         """,
         diagnostics: [
            DiagnosticSpec(message: BCTestMacro.Error.onlyApplicableToAsyncTest.description, line: 1, column: 7)
         ],
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }

   func testThrowingNonAsyncDiagnostic() throws {
      log()
#if canImport(BCTestMacros)
      assertMacroExpansion(
         """
         @Test @BCTest func test() throws {}
         """,
         expandedSource:
         """
         @Test func test() throws {}
         """,
         diagnostics: [
            DiagnosticSpec(message: BCTestMacro.Error.onlyApplicableToAsyncTest.description, line: 1, column: 7)
         ],
         macros: testMacros
      )
#else
      XCTFail("BCTestMacros is not available on this platform.")
#endif
   }
}
