import XCTest
import Defaults
@testable import Maccy

@MainActor
class ModifyRuleTests: XCTestCase {
  let clipboard = Clipboard.shared
  let customType = NSPasteboard.PasteboardType(rawValue: "org.maccy.CustomType")
  let fooToBaz = ModifyRule(search: "foo", modify: "bar", replacement: "baz")

  // Use a private pasteboard to avoid touching the general one.
  nonisolated(unsafe) let pasteboard = NSPasteboard.withUniqueName()

  let savedModifyRules = Defaults[.modifyRules]
  let savedIgnoreRegexp = Defaults[.ignoreRegexp]

  override func setUp() {
    super.setUp()
    Defaults[.modifyRules] = [fooToBaz]
    Defaults[.ignoreRegexp] = []
  }

  override func tearDown() {
    super.tearDown()
    pasteboard.releaseGlobally()
    Defaults[.modifyRules] = savedModifyRules
    Defaults[.ignoreRegexp] = savedIgnoreRegexp
  }

  func testAppliesWhenSearchMatches() {
    let rule = ModifyRule(search: #"https://youtu\.be"#, modify: #"\?si=[^\s]+"#, replacement: "")
    XCTAssertEqual(
      rule.apply(to: "https://youtu.be/dQw4w9WgXcQ?si=aYSMGK-FxZe1XuBf is a neat video"),
      "https://youtu.be/dQw4w9WgXcQ is a neat video"
    )
  }

  func testDoesNotApplyWhenSearchDoesNotMatch() {
    XCTAssertEqual(fooToBaz.apply(to: "barbaz"), "barbaz")
  }

  func testEmptySearchAppliesToEveryCopy() {
    let rule = ModifyRule(search: "", modify: "pizza", replacement: "sandwich")
    XCTAssertEqual(rule.apply(to: "Please eat this pizza"), "Please eat this sandwich")
  }

  func testEmptyModifyDoesNothing() {
    let rule = ModifyRule(search: "", modify: "", replacement: "x")
    XCTAssertEqual(rule.apply(to: "abc"), "abc")
  }

  func testInvalidPatternsAreSkipped() {
    let rules = [
      ModifyRule(search: "(", modify: "foo", replacement: "x"),
      ModifyRule(search: "foo", modify: "[", replacement: "x"),
      fooToBaz
    ]
    XCTAssertEqual(ModifyRule.apply(rules, to: "foobar"), "foobaz")
  }

  func testRulesRunSequentially() {
    let rules = [fooToBaz, ModifyRule(search: "azb", modify: "zba", replacement: "_")]
    XCTAssertEqual(ModifyRule.apply(rules, to: "foobarbaz"), "fooba_z")
  }

  func testReplacementSupportsCaptureGroups() {
    let rule = ModifyRule(search: "", modify: #"(\w+)@(\w+)"#, replacement: "$2 at $1")
    XCTAssertEqual(rule.apply(to: "user@example"), "example at user")
  }

  func testIsValid() {
    XCTAssertTrue(ModifyRule.isValid(""))
    XCTAssertTrue(ModifyRule.isValid(#"^\d+$"#))
    XCTAssertFalse(ModifyRule.isValid("("))
  }

  func testLegacyRulesAreCombined() throws {
    let legacyKeys = [ModifyRule.legacySearchKey, ModifyRule.legacyModifyKey, ModifyRule.legacyReplacementKey]
    let defaults = try XCTUnwrap(UserDefaults(suiteName: Defaults.Keys.testingSuiteName))
    defer { legacyKeys.forEach(defaults.removeObject) }

    defaults.set(["foo", "azb"], forKey: ModifyRule.legacySearchKey)
    defaults.set(["bar", "zba", "orphan"], forKey: ModifyRule.legacyModifyKey)
    defaults.set(["baz"], forKey: ModifyRule.legacyReplacementKey)

    let rules = ModifyRule.legacyRules(in: defaults)
    XCTAssertEqual(rules.map(\.search), ["foo", "azb"])
    XCTAssertEqual(rules.map(\.modify), ["bar", "zba"])
    XCTAssertEqual(rules.map(\.replacement), ["baz", ""])
  }

  func testRewritesPasteboard() {
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foobarbaz", forType: .string)

    XCTAssertTrue(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.string(forType: .string), "foobazbaz")
  }

  func testRewritesPasteboardWhenOnlyNormalizationChanges() {
    Defaults[.modifyRules] = [ModifyRule(search: "", modify: "e\u{301}", replacement: "\u{E9}")]
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("cafe\u{301}", forType: .string)

    XCTAssertTrue(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.string(forType: .string)?.unicodeScalars.count, 4)
  }

  func testLeavesPasteboardWhenNothingChanges() {
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("barbaz", forType: .string)
    let changeCount = pasteboard.changeCount

    XCTAssertFalse(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.changeCount, changeCount)
  }

  func testRemovesStaleFormattingFromModifiedItems() {
    let html = Data("<b>foobar</b>".utf8)
    let png = Data([0x89, 0x50, 0x4E, 0x47])
    pasteboard.declareTypes([.string, .html, .png, .source], owner: nil)
    pasteboard.setString("foobar", forType: .string)
    pasteboard.setData(html, forType: .html)
    pasteboard.setData(png, forType: .png)
    pasteboard.setString("com.example.App", forType: .source)

    XCTAssertTrue(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.string(forType: .string), "foobaz")
    XCTAssertNil(pasteboard.data(forType: .html))
    XCTAssertEqual(pasteboard.data(forType: .png), png)
    XCTAssertEqual(pasteboard.string(forType: .source), "com.example.App")
  }

  func testKeepsUnmodifiedItemsIntact() throws {
    let modified = NSPasteboardItem()
    modified.setString("foobar", forType: .string)
    let unmodified = NSPasteboardItem()
    unmodified.setString("other", forType: .string)
    unmodified.setData(Data("<i>other</i>".utf8), forType: .html)
    unmodified.setString("custom", forType: customType)
    pasteboard.clearContents()
    pasteboard.writeObjects([modified, unmodified])

    XCTAssertTrue(clipboard.applyModifyRules(to: pasteboard))

    let items = try XCTUnwrap(pasteboard.pasteboardItems)
    XCTAssertEqual(items.count, 2)
    XCTAssertEqual(items[0].string(forType: .string), "foobaz")
    XCTAssertEqual(items[1].string(forType: .string), "other")
    XCTAssertEqual(items[1].data(forType: .html), Data("<i>other</i>".utf8))
    XCTAssertEqual(items[1].string(forType: customType), "custom")
  }

  func testHandlesTypesWithoutData() {
    pasteboard.declareTypes([.string, customType], owner: nil)
    pasteboard.setString("foobar", forType: .string)

    XCTAssertTrue(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.string(forType: .string), "foobaz")
  }

  func testIgnoresCopiesFromMaccy() {
    pasteboard.declareTypes([.string, .fromMaccy], owner: nil)
    pasteboard.setString("foobar", forType: .string)
    pasteboard.setString("", forType: .fromMaccy)

    XCTAssertFalse(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.string(forType: .string), "foobar")
  }

  func testIgnoresItemsMatchingIgnoreRegexp() {
    Defaults[.ignoreRegexp] = ["secret"]
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("secret foobar", forType: .string)

    XCTAssertFalse(clipboard.applyModifyRules(to: pasteboard))
    XCTAssertEqual(pasteboard.string(forType: .string), "secret foobar")
  }

  func testDoesNothingWithoutRules() {
    Defaults[.modifyRules] = []
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foobar", forType: .string)

    XCTAssertFalse(clipboard.applyModifyRules(to: pasteboard))
  }
}

// Goes through clipboard monitoring, so it uses the general pasteboard like ClipboardTests.
@MainActor
class ModifyOnCopyTests: XCTestCase {
  let clipboard = Clipboard.shared
  let pasteboard = NSPasteboard.general

  let savedModifyRules = Defaults[.modifyRules]
  let savedIgnoreEvents = Defaults[.ignoreEvents]

  override func setUp() {
    super.setUp()
    Defaults[.modifyRules] = [ModifyRule(search: "foo", modify: "bar", replacement: "baz")]
    Defaults[.ignoreEvents] = false
  }

  override func tearDown() {
    super.tearDown()
    Defaults[.modifyRules] = savedModifyRules
    Defaults[.ignoreEvents] = savedIgnoreEvents
    MainActor.assumeIsolated {
      Clipboard.shared.clearHooks()
    }
  }

  func testModifiesCopiedText() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.text, "foobazbaz")
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foobarbaz", forType: .string)
    waitForExpectations(timeout: 2)

    XCTAssertEqual(pasteboard.string(forType: .string), "foobazbaz")
  }

  func testAddsModifiedCopyOnlyOnce() {
    let hookExpectation = expectation(description: "Hook is called")
    let repeatedHookExpectation = expectation(description: "Hook is called again")
    repeatedHookExpectation.isInverted = true
    var calls = 0
    clipboard.onNewCopy({ (_: HistoryItem) in
      calls += 1
      if calls == 1 {
        hookExpectation.fulfill()
      } else {
        repeatedHookExpectation.fulfill()
      }
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foobarbaz", forType: .string)
    wait(for: [hookExpectation], timeout: 2)
    wait(for: [repeatedHookExpectation], timeout: 2)
  }

  func testStoresModifiedCopyWithoutStaleFormatting() {
    let rtf = NSAttributedString(string: "foobar", attributes: [.foregroundColor: NSColor.red])
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.text, "foobaz")
      XCTAssertNil(item.rtfData)
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string, .rtf], owner: nil)
    pasteboard.setString("foobar", forType: .string)
    pasteboard.setData(rtf.rtf(from: NSRange(location: 0, length: rtf.length), documentAttributes: [:]), forType: .rtf)
    waitForExpectations(timeout: 2)

    XCTAssertNil(pasteboard.data(forType: .rtf))
  }
}
