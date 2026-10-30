import AppKit
import Testing
import Defaults
@testable import Maccy

// swiftlint:disable type_body_length
@MainActor
class ClipboardTests: XCTestCase {
  let clipboard = Clipboard.shared
  let pasteboard = NSPasteboard.general
  let image = NSImage(named: "NSInfo")!
  let coloredString = NSAttributedString(string: "foo",
                                         attributes: [.foregroundColor: NSColor.red])

  let dynamicType = NSPasteboard.PasteboardType(rawValue: "dyn.ah62d4qmxhk4d425try1g44pdsm11g55gsu1e82xnqzv")
  let customType = NSPasteboard.PasteboardType(rawValue: "org.maccy.ConfidentialType")
  let fileURLType = NSPasteboard.PasteboardType.fileURL
  let htmlType = NSPasteboard.PasteboardType.html
  let rtfType = NSPasteboard.PasteboardType.rtf
  let stringType = NSPasteboard.PasteboardType.string
  let tiffType = NSPasteboard.PasteboardType.tiff
  let transientType = NSPasteboard.PasteboardType.transient
  let unknownType = NSPasteboard.PasteboardType(rawValue: "com.apple.AnnotationKit.AnnotationItem")

  let savedEnabledTypes = Defaults[.enabledPasteboardTypes]
  let savedIgnoreEvents = Defaults[.ignoreEvents]
  let savedIgnoreAllAppsExceptListed = Defaults[.ignoreAllAppsExceptListed]
  let savedIgnoredApps = Defaults[.ignoredApps]
  let savedIgnoredPasteboardTypes = Defaults[.ignoredPasteboardTypes]
  let savedModifyRules = Defaults[.modifyRules]

  override func setUp() {
    super.setUp()
    Defaults[.ignoreAllAppsExceptListed] = false
    Defaults[.ignoreEvents] = false
    Defaults[.modifyRules] = []
  }

  override func tearDown() {
    super.tearDown()
    Defaults[.enabledPasteboardTypes] = savedEnabledTypes
    Defaults[.ignoreEvents] = savedIgnoreEvents
    Defaults[.ignoreOnlyNextEvent] = false
    Defaults[.ignoreAllAppsExceptListed] = savedIgnoreAllAppsExceptListed
    Defaults[.ignoredApps] = savedIgnoredApps
    Defaults[.ignoredPasteboardTypes] = savedIgnoredPasteboardTypes
    Defaults[.modifyRules] = savedModifyRules
    MainActor.assumeIsolated {
      Clipboard.shared.clearHooks()
    }
  }

  func testChangesListenerAndAddHooks() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreStringWithOnlySpaces() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(" ", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreStringWithOnlyNewlines() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("\n", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testDoesNotIgnoreRTF() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    let rtf = NSAttributedString(string: "foo").rtf(
      from: NSRange(0...2),
      documentAttributes: [:]
    )
    pasteboard.declareTypes([.rtf], owner: nil)
    pasteboard.setData(rtf, forType: .rtf)
    waitForExpectations(timeout: 2)
  }

  func testDoesNotIgnoreHTML() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.html], owner: nil)
    pasteboard.setString("foo", forType: .html)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreEventsIsEnabled() {
    Defaults[.ignoreEvents] = true

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foo", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreOnlyNextEventIsEnabled() {
    Defaults[.ignoreEvents] = true
    Defaults[.ignoreOnlyNextEvent] = true

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("foo", forType: .string)
    waitForExpectations(timeout: 2)

    XCTAssertFalse(Defaults[.ignoreEvents])
    XCTAssertFalse(Defaults[.ignoreOnlyNextEvent])
  }

  func testIgnoreApplication() throws {
    Defaults[.ignoredApps] = [try frontmostAppBundleIdentifier()]

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreAllApplicationsExcept() throws {
    Defaults[.ignoreAllAppsExceptListed] = true
    Defaults[.ignoredApps] = [try frontmostAppBundleIdentifier()]

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreTransientTypes() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string, transientType], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreCustomTypes() {
    Defaults[.ignoredPasteboardTypes] = [customType.rawValue]

    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([.string, customType], owner: nil)
    pasteboard.setString("bar", forType: .string)
    waitForExpectations(timeout: 2)
  }

  func testIgnoreCopiesWithUnknownTypes() {
    let hookExpectation = expectation(description: "Hook is called")
    hookExpectation.isInverted = true
    clipboard.onNewCopy({ (_: HistoryItem) in
      hookExpectation.fulfill()
    })
    clipboard.start()
    pasteboard.declareTypes([unknownType], owner: nil)
    pasteboard.setString(" ", forType: unknownType)
    waitForExpectations(timeout: 2)
  }

  func testCopy() {
    let imageData = image.tiffRepresentation!
    let contents = [
      HistoryItemContent(type: stringType.rawValue, value: "foo".data(using: .utf8)!),
      HistoryItemContent(type: tiffType.rawValue, value: imageData),
      HistoryItemContent(type: fileURLType.rawValue, value: "file://foo.bar".data(using: .utf8)!)
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.application = "com.foo.bar"
    clipboard.copy(item)
    XCTAssertEqual(pasteboard.string(forType: .string), "foo")
    XCTAssertEqual(pasteboard.data(forType: .tiff), imageData)
    XCTAssertEqual(pasteboard.string(forType: .fileURL), "file://foo.bar")
    XCTAssertEqual(pasteboard.string(forType: .fromMaccy), "")
    XCTAssertEqual(pasteboard.string(forType: .source), "com.foo.bar")
  }

  func testCopyString() {
    clipboard.copyInMaccy("foo")
    XCTAssertEqual(pasteboard.string(forType: .string), "foo")
    XCTAssertEqual(pasteboard.string(forType: .source), NSPasteboard.PasteboardType.fromMaccy.rawValue)
  }

  func testCopyWithoutFormatting() {
    let contents = [
      HistoryItemContent(type: stringType.rawValue, value: "foo".data(using: .utf8)!),
      HistoryItemContent(type: fileURLType.rawValue, value: "file://foo.bar".data(using: .utf8)!),
      HistoryItemContent(type: rtfType.rawValue,
                         value: coloredString.rtf(from: NSRange(location: 0, length: coloredString.length),
                                                  documentAttributes: [:]))
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.application = "com.foo.bar"
    clipboard.copy(item, removeFormatting: true)
    XCTAssertEqual(pasteboard.string(forType: .string), "foo")
    XCTAssertEqual(pasteboard.string(forType: .fromMaccy), "")
    XCTAssertEqual(pasteboard.string(forType: .source), "com.foo.bar")
    XCTAssertEqual(pasteboard.string(forType: .fileURL), "file://foo.bar")
    XCTAssertNil(pasteboard.data(forType: .rtf))
  }

    let savedEnabledTypes = Defaults[.enabledPasteboardTypes]
    let savedIgnoreEvents = Defaults[.ignoreEvents]
    let savedIgnoreAllAppsExceptListed = Defaults[.ignoreAllAppsExceptListed]
    let savedIgnoredApps = Defaults[.ignoredApps]
    let savedIgnoredPasteboardTypes = Defaults[.ignoredPasteboardTypes]

    init() throws {
      image = try #require(NSImage(named: "NSInfo"))
      Defaults[.ignoreAllAppsExceptListed] = false
      Defaults[.ignoreEvents] = false
      clipboard.clearHooks()
    }

    deinit {
      Defaults[.enabledPasteboardTypes] = savedEnabledTypes
      Defaults[.ignoreEvents] = savedIgnoreEvents
      Defaults[.ignoreOnlyNextEvent] = false
      Defaults[.ignoreAllAppsExceptListed] = savedIgnoreAllAppsExceptListed
      Defaults[.ignoredApps] = savedIgnoredApps
      Defaults[.ignoredPasteboardTypes] = savedIgnoredPasteboardTypes
    }

    @Test("Changes listener and add hooks")
    func changesListenerAndAddHooks() async throws {
      let copies = try await waitForCopies(after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("bar", forType: .string)
      })
      #expect(copies.count == 1)
    }

    @Test("Ignore string with only spaces")
    func ignoreStringWithOnlySpaces() async throws {
      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(" ", forType: .string)
      })
      #expect(copies.isEmpty)
    }

    @Test("Ignore string with only newlines")
    func ignoreStringWithOnlyNewlines() async throws {
      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("\n", forType: .string)
      })
      #expect(copies.isEmpty)
    }

    @Test("Does not ignore RTF")
    func doesNotIgnoreRTF() async throws {
      let copies = try await waitForCopies(after: {
        let rtf = NSAttributedString(string: "foo").rtf(
          from: NSRange(0...2),
          documentAttributes: [:]
        )
        pasteboard.declareTypes([.rtf], owner: nil)
        pasteboard.setData(rtf, forType: .rtf)
      })
      #expect(copies.count == 1)
    }

    @Test("Does not ignore HTML")
    func doesNotIgnoreHTML() async throws {
      let copies = try await waitForCopies(after: {
        pasteboard.declareTypes([.html], owner: nil)
        pasteboard.setString("foo", forType: .html)
      })
      #expect(copies.count == 1)
    }

    @Test("Ignore events is enabled")
    func ignoreEventsIsEnabled() async throws {
      Defaults[.ignoreEvents] = true

      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("foo", forType: .string)
      })
      #expect(copies.isEmpty)
    }

    @Test("Ignore only next event is enabled")
    func ignoreOnlyNextEventIsEnabled() async throws {
      Defaults[.ignoreEvents] = true
      Defaults[.ignoreOnlyNextEvent] = true

      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("foo", forType: .string)
      })
      #expect(copies.isEmpty)

      #expect(!Defaults[.ignoreEvents])
      #expect(!Defaults[.ignoreOnlyNextEvent])
    }

    @Test("Ignore application")
    func ignoreApplication() async throws {
      Defaults[.ignoredApps] = [try frontmostAppBundleIdentifier()]

      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("bar", forType: .string)
      })
      #expect(copies.isEmpty)
    }

    @Test("Ignore all applications except")
    func ignoreAllApplicationsExcept() async throws {
      Defaults[.ignoreAllAppsExceptListed] = true
      Defaults[.ignoredApps] = [try frontmostAppBundleIdentifier()]

      let copies = try await waitForCopies(after: {
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("bar", forType: .string)
      })
      #expect(copies.count == 1)
    }

    @Test("Ignore transient types")
    func ignoreTransientTypes() async throws {
      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string, transientType], owner: nil)
        pasteboard.setString("bar", forType: .string)
      })
      #expect(copies.isEmpty)
    }

    @Test("Ignore custom types")
    func ignoreCustomTypes() async throws {
      Defaults[.ignoredPasteboardTypes] = [customType.rawValue]

      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([.string, customType], owner: nil)
        pasteboard.setString("bar", forType: .string)
      })
      #expect(copies.isEmpty)
    }

    @Test("Ignore copies with unknown types")
    func ignoreCopiesWithUnknownTypes() async throws {
      let copies = try await waitForCopies(expectingCopy: false, after: {
        pasteboard.declareTypes([unknownType], owner: nil)
        pasteboard.setString(" ", forType: unknownType)
      })
      #expect(copies.isEmpty)
    }

    @Test("Copy")
    func copy() {
      let imageData = image.tiffRepresentation!
      let contents = [
        HistoryItemContent(type: stringType.rawValue, value: "foo".data(using: .utf8)!),
        HistoryItemContent(type: tiffType.rawValue, value: imageData),
        HistoryItemContent(type: fileURLType.rawValue, value: "file://foo.bar".data(using: .utf8)!)
      ]
      let item = HistoryItem()
      Storage.shared.context.insert(item)
      item.contents = contents
      item.application = "com.foo.bar"
      clipboard.copy(item)
      #expect(pasteboard.string(forType: .string) == "foo")
      #expect(pasteboard.data(forType: .tiff) == imageData)
      #expect(pasteboard.string(forType: .fileURL) == "file://foo.bar")
      #expect(pasteboard.string(forType: .fromMaccy) == "")
      #expect(pasteboard.string(forType: .source) == "com.foo.bar")
    }

    @Test("Copy string")
    func copyString() {
      clipboard.copyInMaccy("foo")
      #expect(pasteboard.string(forType: .string) == "foo")
      #expect(pasteboard.string(forType: .source) == NSPasteboard.PasteboardType.fromMaccy.rawValue)
    }

    @Test("Copy without formatting")
    func copyWithoutFormatting() {
      let contents = [
        HistoryItemContent(type: stringType.rawValue, value: "foo".data(using: .utf8)!),
        HistoryItemContent(type: fileURLType.rawValue, value: "file://foo.bar".data(using: .utf8)!),
        HistoryItemContent(type: rtfType.rawValue,
                           value: coloredString.rtf(from: NSRange(location: 0, length: coloredString.length),
                                                    documentAttributes: [:]))
      ]
      let item = HistoryItem()
      Storage.shared.context.insert(item)
      item.contents = contents
      item.application = "com.foo.bar"
      clipboard.copy(item, removeFormatting: true)
      #expect(pasteboard.string(forType: .string) == "foo")
      #expect(pasteboard.string(forType: .fromMaccy) == "")
      #expect(pasteboard.string(forType: .source) == "com.foo.bar")
      #expect(pasteboard.string(forType: .fileURL) == "file://foo.bar")
      #expect(pasteboard.data(forType: .rtf) == nil)
    }

    @Test("Handles items without data")
    func handlesItemsWithoutData() async throws {
      pasteboard.clearContents()

      let copies = try await waitForCopies(after: {
        pasteboard.declareTypes([.fileURL, .string], owner: nil)
        // fileURL is left without data
        pasteboard.setString("bar", forType: .string)
      })
      #expect(copies.count == 1)
    }

    @Test("Merges multiple items")
    func mergesMultipleItems() async throws {
      let item1 = NSPasteboardItem()
      item1.setString("foo", forType: .string)
      let item2 = NSPasteboardItem()
      item2.setData(image.tiffRepresentation!, forType: .tiff)

      let copies = try await waitForCopies(after: {
        pasteboard.clearContents()
        pasteboard.writeObjects([item1, item2])
      })
      let copied = try #require(copies.first)
      #expect(copies.count == 1)
      #expect(
        Set(copied.contents.map({ $0.type })) ==
        Set([tiffType.rawValue, stringType.rawValue])
      )
    }

    @Test("Removes disabled types")
    func removesDisabledTypes() async throws {
      Defaults[.enabledPasteboardTypes] = [.fileURL]

      let item = NSPasteboardItem()
      item.setString("foo", forType: .string)
      item.setData(image.tiffRepresentation!, forType: .tiff)
      item.setData("file://foo.bar".data(using: .utf8)!, forType: .fileURL)

    waitForExpectations(timeout: 2)
  }

  func testRemovesDisabledTypes() {
    Defaults[.enabledPasteboardTypes] = [.fileURL]

    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map({ $0.type }), [self.fileURLType.rawValue])
      hookExpectation.fulfill()
    })

    let item = NSPasteboardItem()
    item.setString("foo", forType: .string)
    item.setData(image.tiffRepresentation!, forType: .tiff)
    item.setData("file://foo.bar".data(using: .utf8)!, forType: .fileURL)

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([item])

    waitForExpectations(timeout: 2)
  }

  func testRemovesDynamicTypes() {
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(item.contents.map({ $0.type }), [self.stringType.rawValue])
      hookExpectation.fulfill()
    })

    let item = NSPasteboardItem()
    item.setString("foo", forType: .string)
    item.setData("".data(using: .utf8)!, forType: dynamicType)

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([item])

    waitForExpectations(timeout: 2)
  }

  func testDoesNotStoreSafariWebArchive() {
    let webArchive = NSPasteboard.PasteboardType.safariWebArchve
    let hookExpectation = expectation(description: "Hook is called")
    clipboard.onNewCopy({ (item: HistoryItem) in
      XCTAssertEqual(Set(item.contents.map(\.type)), [self.stringType.rawValue])
      hookExpectation.fulfill()
    })

    let item = NSPasteboardItem()
    item.setString("hello from safari", forType: .string)
    item.setData(Data(repeating: 0x61, count: 1024 * 1024), forType: webArchive)

    clipboard.start()
    pasteboard.clearContents()
    pasteboard.writeObjects([item])

    waitForExpectations(timeout: 2)
  }

  private func frontmostAppBundleIdentifier() throws -> String {
    guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
      throw XCTSkip("No frontmost application to attribute a copy to")
    }

    return bundleIdentifier
  }
}
