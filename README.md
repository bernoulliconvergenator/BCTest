# BCTest

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbernoulliconvergenator%2FBCTest%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/bernoulliconvergenator/BCTest)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbernoulliconvergenator%2FBCTest%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/bernoulliconvergenator/BCTest)

The swift package `BCTest` provides asserting asynchronous conditions in swift tests with ergonomics like `XCTestExpectation`.

```swift
@Test @BCTest myTest() async throws {
  let myNeed = await needManager.need(expectedCount: 1)
  let myOtherNeed = await needManager.need(expectedCount: 1)
  Task.detached { 
    myNeed.satisfy()
    myOtherNeed.satisfy()
  }
  try await awaitSatisfaction(of: [myNeed, myOtherNeed], timeout: .infinity)
}
```

`needManager` is an instance of `BCTestNeedManager`. The `@BCTest` macro creates `needManager` at the top of the swift test body. Use `needManager` to create instances of `BCTestNeed`. 

Use global function `awaitSatisfaction(of:timeout:)` to await satisfaction of a `BCTestNeed`. 

All created needs must be both awaited and satisfied for the swift test to pass.  The `@BCTest` macro adds `await needManager.assertNeedsSatisfied()` to the end of the swift test body. 

The expanded macro:

```swift
@Test @BCTest myTest() async throws {
  let needManager = BCTestNeedManager() // *** ADDED BY MACRO ***
  let myNeed = await needManager.need(expectedCount: 1)
  let myOtherNeed = await needManager.need(expectedCount: 1)
  Task.detached { 
    myNeed.satisfy()
	 myOtherNeed.satisfy()
  }
  try await awaitSatisfaction(of: [myNeed, myOtherNeed], timeout: .infinity)
  await needManager.assertNeedsSatisfied() // *** ADDED BY MACRO ***
}
```

A test need is configured to expect zero or more invocations of `satisfy()`. A test need is configured to fail or not fail if over satisfied. 

A `BCTestNeed` can only be created by a `BCTestNeedManager`.

Assertion of need satisfaction can only be performed by the need manager that created it.

### Intentional never satisfied

Configure a need with `expectedCount: 0` if it is never to be satisfied. If `satisfy()` is called on the need (eg in a code path not to be taken), the need will be over satisfied and the test will fail.

### Intentional assertion failures

If a test is designed such that the need manager's assertion is intended to fail, avoid failing the test by including the `.withKnownIssue` trait which wraps the need manager's assertion in `withKnownIssue {..}`.

## Invariants

`BCTest` provides these invariants:
- a need must be both satisfied and awaited to pass assertion 
- a need can be satisfied before being awaited
- a need can be satisfied during await
- a need cannot be satisfied after await has ended *
- a test fails if need is not awaited
- a test fails if need is not satisfied before await ends
- a test fails if await times out
- a test fails if need is awaited more than once
- a test fails if await is not ended when asserted
- an await on need satisfaction can be canceled

* Invoking `satisfy()` after await has ended increments a need's satisfaction count but does not qualify for satisfaction. 
 
## Fragility

The macro expansion requires `BCTestNeedManager` methods `init` and `assertNeedsSatisfied()` are public, but you should not create another need manager as the macro will not ensure the need manager asserts satisfaction and awaiting for needs it creates.

If a test helper functions create needs, pass it `needManager` provided by the macro.

## As an alternative to `Confirmation` and `CheckedContinuation` 

`Confirmation` and `CheckedContinuation` are suggested for testing asynchronous events in swift tests but are not as ergonomically friendly as XCTest's `XCTestExpectation`.

`Confirmation` requires confirmation occurs before its `body` arg exits. `await confirmation() { c in Task { c() } }` fails while `await confirmation() { c in await Task { c() }.value }` passes.  

`CheckedContinuation` does not require `resume()` before its `body` arg exits:
```swift
await withCheckedContinuation { c in 
  Task {
    let cookies = await chimChim.threwCookies()
    #expect(cookies.count == 1)
    c.resume()
  }
}
```
But `CheckedContinuation` can only `resume()` once and so cannot internally provide tracking of events that are to happen more than once.

Also `CheckedContinuation` requires care that `resume()` is invoked *after* all `@expect/#require` statements else swift testing context may miss them. See the `CheckedContinuationShouldFail` and `CheckedContinuationWithKnownIssue` tests in `Tests/AlternativeTests`.

Lastly `Confirmation` and `CheckedContinuation` have a 1:1 relationship with a closure and confirmation/continuation that occurs inside the closure. A test that assures multiple asynchronous events occur may require nesting instances of these structures.

## License

This package is released under the Unlicensed license.
