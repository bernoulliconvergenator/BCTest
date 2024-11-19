import Foundation

internal protocol Loggable {
   static func log(_: String, function: String)
   func log(_: String, function: String)
}

extension Loggable {
   internal static func log(_ message: String = "", function: String = #function) {
      print("[\(Self.self) static \(function)] \(message)")
   }

   internal func log(_ message: String = "", function: String = #function) {
      print("[\(Self.self).\(function)] \(message)")
   }
}

internal func log(_ message: String = "", function: String = #function) {
   print("[\(function)] \(message)")
}
