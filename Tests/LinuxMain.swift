import XCTest

import quitTests

var tests = [XCTestCaseEntry]()
tests += quitTests.allTests()
XCTMain(tests)