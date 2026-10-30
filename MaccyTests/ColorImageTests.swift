import Testing
@testable import Maccy

@MainActor
class ColorImageTests: XCTestCase {
  func testColorImageFromShortHex() {
    XCTAssertNotNil(ColorImage.from("fff"))
  }

  @Test("Color image from non-hex string")
  func colorImageFromNonHexString() {
    #expect(ColorImage.from("foo") == nil)
  }
}
