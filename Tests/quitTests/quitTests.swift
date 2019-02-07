import XCTest
import class Foundation.Bundle
import QuitCore
import class AppKit.NSWorkspace
import class AppKit.NSRunningApplication

final class quitTests: XCTestCase {
	func testQuitOneWordApp() throws {
		// Some of the APIs that we use below are available in macOS 10.13 and above.
		guard #available(macOS 10.13, *) else {
			return
		}

		// Open test app
		let appName = "Grapher"
		let appID = "com.apple.grapher"
		let workspace = NSWorkspace.shared
		workspace.launchApplication(withBundleIdentifier: appID, options: .andHide, additionalEventParamDescriptor: nil, launchIdentifier: nil)
		
		let quitBinary = productsDirectory.appendingPathComponent("quit")
		
		let process = Process()
		process.executableURL = quitBinary
		process.arguments = [appName]
		
		let pipe = Pipe()
		process.standardOutput = pipe
		
		try process.run()
		process.waitUntilExit()
		
//		let data = pipe.fileHandleForReading.readDataToEndOfFile()
//		let output = String(data: data, encoding: .utf8)

		// Prepare our check
		sleep(1)
		let runningApps = workspace.runningApplications
		let appsToQuit = runningApps.filter { $0.bundleURL?.lastPathComponent == "\(appName).app" }
		
		XCTAssertEqual(appsToQuit.count, 0)
//		XCTAssertEqual(output, "")
	}
	
	func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let fooBinary = productsDirectory.appendingPathComponent("quit")

        let process = Process()
        process.executableURL = fooBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

		XCTAssertEqual(output, "Please provide an application name to quit, e.g. \"Google Chrome\"\n")
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
