import WinAppSDK
import XCTest

public class InitiailzerTests: XCTestCase {
    public func testInitializer() {
        XCTAssertNoThrow(try WindowsAppRuntimeInitializer())
    }
}
