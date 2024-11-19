import SwiftSyntax
import SwiftSyntaxMacros

/// Implements the expansion of a `@@CTest` attached `BodyMacro`.
public struct BCTestMacro: BodyMacro {
   public static func expansion(
      of node: AttributeSyntax,
      providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
      in context: some MacroExpansionContext
   ) throws -> [CodeBlockItemSyntax] {
      guard
         let funcDecl = declaration.as(FunctionDeclSyntax.self),
         let body = funcDecl.body
      else {
         throw Error.onlyApplicableToSwiftTestingTestFunction
      }

      let isTest = funcDecl.attributes.contains {
         $0
            .as(AttributeSyntax.self)?
            .attributeName
            .as(IdentifierTypeSyntax.self)?
            .name.identifier?.name == "Test"
      }
      guard isTest else {
         throw Error.onlyApplicableToSwiftTestingTestFunction
      }

      // test function must be async; since can only emend body, no ability to fix header
      guard let _ = funcDecl.signature.effectSpecifiers?.asyncSpecifier else {
         throw Error.onlyApplicableToAsyncTest
      }

      let hasKnownIssue = node.arguments?
         .as(LabeledExprListSyntax.self)?
         .first?.expression
         .as(MemberAccessExprSyntax.self)?
         .declName.baseName.text == "withKnownIssue"

      guard hasKnownIssue else {
         return ["let needManager = BCTestNeedManager()"] + body.statements + ["await needManager.assertNeedsSatisfied()"]
      }

      return ["let needManager = BCTestNeedManager()"] +
      body.statements +
      [
         """
         await withKnownIssue {
             await needManager.assertNeedsSatisfied()
         }
         """
      ]
   }

   // MARK: - error

   /// Errors that can occur from misuse of the `@BCTest` attached macro.
   public enum Error: Swift.Error, CustomStringConvertible {
      case onlyApplicableToSwiftTestingTestFunction
      case onlyApplicableToAsyncTest

      public var description: String {
         switch self {
         case .onlyApplicableToSwiftTestingTestFunction:
            return "@BCTest can only be applied to a swift-testing function"
         case .onlyApplicableToAsyncTest:
            return "@BCTest can only be applied to an async swift-testing function"
         }
      }
   }
}
