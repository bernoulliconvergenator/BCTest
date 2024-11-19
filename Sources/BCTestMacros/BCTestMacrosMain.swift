import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Compiler plugin executable main entry point for implementation of `BCTest` macro.
@main
struct BCTestMacrosMain: CompilerPlugin {
   let providingMacros: [Macro.Type] = [BCTestMacro.self]
}
