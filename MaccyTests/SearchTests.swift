import AppKit
import Testing
import Defaults
@testable import Maccy

@MainActor
class SearchTests: XCTestCase {
  let savedSearchMode = Defaults[.searchMode]
  var items: [Search.Searchable]!

  override func tearDown() {
    super.tearDown()
    Defaults[.searchMode] = savedSearchMode
  }

  func testSimpleSearch() { // swiftlint:disable:this function_body_length
    Defaults[.searchMode] = Search.Mode.exact
    items = [
      HistoryItemDecorator(historyItemWithTitle("foo bar baz")),
      HistoryItemDecorator(historyItemWithTitle("foo bar zaz")),
      HistoryItemDecorator(historyItemWithTitle("xxx yyy zzz"))
    ]

    init() {
      items = [
        HistoryItemDecorator(Self.historyItemWithTitle("foo bar baz")),
        HistoryItemDecorator(Self.historyItemWithTitle("foo bar zaz")),
        HistoryItemDecorator(Self.historyItemWithTitle("xxx yyy zzz"))
      ]
    }

  func testFuzzySearch() { // swiftlint:disable:this function_body_length
    Defaults[.searchMode] = Search.Mode.fuzzy
    items = [
      HistoryItemDecorator(historyItemWithTitle("foo bar baz")),
      HistoryItemDecorator(historyItemWithTitle("foo bar zaz")),
      HistoryItemDecorator(historyItemWithTitle("xxx yyy zzz"))
    ]

    @Test("Simple search")
    func simpleSearch() { // swiftlint:disable:this function_body_length
      Defaults[.searchMode] = Search.Mode.exact
      #expect(search("") == [
        Search.SearchResult(score: nil, object: items[0], ranges: []),
        Search.SearchResult(score: nil, object: items[1], ranges: []),
        Search.SearchResult(score: nil, object: items[2], ranges: [])
      ])
      #expect(search("z") == [
        Search.SearchResult(
          score: nil,
          object: items[0],
          ranges: [range(from: 10, to: 10, in: items[0])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[1],
          ranges: [range(from: 8, to: 8, in: items[1])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[2],
          ranges: [range(from: 8, to: 8, in: items[2])]
        )
      ])
      #expect(search("foo") == [
        Search.SearchResult(
          score: nil,
          object: items[0],
          ranges: [range(from: 0, to: 2, in: items[0])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[1],
          ranges: [range(from: 0, to: 2, in: items[1])]
        )
      ])
      #expect(search("za") == [
        Search.SearchResult(
          score: nil,
          object: items[1],
          ranges: [range(from: 8, to: 9, in: items[1])]
        )
      ])
      #expect(search("yyy") == [
        Search.SearchResult(
          score: nil,
          object: items[2],
          ranges: [range(from: 4, to: 6, in: items[2])]
        )
      ])
      #expect(search("fbb") == [])
      #expect(search("m") == [])
    }

  func testRegexpSearch() { // swiftlint:disable:this function_body_length
    Defaults[.searchMode] = Search.Mode.regexp
    items = [
      HistoryItemDecorator(historyItemWithTitle("foo bar baz")),
      HistoryItemDecorator(historyItemWithTitle("foo bar zaz")),
      HistoryItemDecorator(historyItemWithTitle("xxx yyy zzz"))
    ]

    @Test("Regexp search")
    func regexpSearch() { // swiftlint:disable:this function_body_length
      Defaults[.searchMode] = Search.Mode.regexp
      #expect(search("") == [
        Search.SearchResult(score: nil, object: items[0], ranges: []),
        Search.SearchResult(score: nil, object: items[1], ranges: []),
        Search.SearchResult(score: nil, object: items[2], ranges: [])
      ])
      #expect(search("z+") == [
        Search.SearchResult(
          score: nil,
          object: items[0],
          ranges: [range(from: 10, to: 10, in: items[0])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[1],
          ranges: [range(from: 8, to: 8, in: items[1])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[2],
          ranges: [range(from: 8, to: 10, in: items[2])]
        )
      ])
      #expect(search("z*") == [
        Search.SearchResult(
          score: nil,
          object: items[0],
          ranges: [range(from: 0, to: -1, in: items[0])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[1],
          ranges: [range(from: 0, to: -1, in: items[1])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[2],
          ranges: [range(from: 0, to: -1, in: items[2])]
        )
      ])
      #expect(search("^foo") == [
        Search.SearchResult(
          score: nil,
          object: items[0], ranges: [range(from: 0, to: 2, in: items[0])]
        ),
        Search.SearchResult(
          score: nil,
          object: items[1], ranges: [range(from: 0, to: 2, in: items[1])]
        )
      ])
      #expect(search(" za") == [
        Search.SearchResult(
          score: nil,
          object: items[1],
          ranges: [range(from: 7, to: 9, in: items[1])]
        )
      ])
      #expect(search("[y]+") == [
        Search.SearchResult(
          score: nil,
          object: items[2],
          ranges: [range(from: 4, to: 6, in: items[2])]
        )
      ])
      #expect(search("fbb") == [])
      #expect(search("m") == [])
    }

    private func search(_ string: String) -> [Search.SearchResult] {
      return Search().search(string: string, within: items)
    }

    // swiftlint:disable:next identifier_name
    private func range(from: Int, to: Int, in item: HistoryItemDecorator) -> Range<String.Index> {
      let startIndex = item.title.startIndex
      let lowerBound = item.title.index(startIndex, offsetBy: from)
      let upperBound = item.title.index(startIndex, offsetBy: to + 1)

      return lowerBound..<upperBound
    }

  private func historyItemWithTitle(_ value: String?) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value?.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

      return item
    }
  }
}
