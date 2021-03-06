import class AppKit.NSWorkspace
import class AppKit.NSRunningApplication
import func Darwin.C.stdlib.exit
import Dispatch
import Foundation
import os.log

import Basic
import Utility

@available(OSX 10.12, *)
public final class Quit: NSObject {
	// Instantiate logging handler
	private let logHandle = OSLog(subsystem: "com.paulgalow.quit", category: "General")
	
	// Instantiate CLI arguments property
	private let arguments: [String]
	// Get a list of running applications
	private let runningApps = NSWorkspace.shared.runningApplications
	
	public init(arguments: [String] = CommandLine.arguments) {
		// Drop first passed in argument which represents the app name itself
		self.arguments = Array(CommandLine.arguments.dropFirst())
	}
	
	//	Main function
	public func run() throws {
		
		let parser = ArgumentParser(
			commandName: "quit",
			usage: "[options] app",
			overview: "Gracefully quit macOS applications from the command line"
		)

//		let list = parser.add(
//			option: "--list",
//			shortName: "-l",
//			kind: Bool.self,
//			usage: "List running applications",
//			completion: .none)

//		let verbose = parser.add(
//			option: "--verbose",
//			shortName: "-v",
//			kind: Bool.self,
//			usage: "Display more verbose output",
//			completion: .none)
		
//		let force = parser.add(
//			option: "--force",
//			shortName: "-f",
//			kind: Bool.self,
//			usage: "Force quit application",
//			completion: .none)

		let timeout = parser.add(
			option: "--timeout",
			shortName: "-t",
			kind: Int.self,
			usage: "Time in seconds 'quit' will wait for an app to quit (defaults to 60)",
			completion: .none)
		
		let app = parser.add(
			positional: "app",
			kind: String.self,
			usage: "App name to quit, e.g. \"Google Chrome\""
		)
		
		let result = try parser.parse(arguments)
		
//		if let _ = result.get(list) {
//			listRunningApps()
//			return
//		}

		guard let appName = result.get(app) else {
			throw ArgumentParserError.expectedArguments(parser, ["app"])
		}
		
		if let timeoutValue = result.get(timeout) {
			os_log("Calling quitApp() with custom timeout value …", log: logHandle, type: .debug)
			try quitApp(appName, timeout: timeoutValue)
		} else {
			os_log("Calling quitApp() …", log: logHandle, type: .debug)
			try quitApp(appName)
		}
		
	}
	// List all running apps
//	public func listRunningApps() {
//
//		var appsList = runningApps.compactMap({ $0.localizedName }).sorted()
//
////		appsList.sort()
//
//		_ = appsList.map { print($0) }

//	}
	
	
	// Get app bundle ID from app name the user has passed in
	public func getBundleIDFromAppName(_ name: String) throws -> NSRunningApplication? {
		os_log("Entered getBundleIDFromAppName()", log: logHandle, type: .debug)
		
		let appsToQuit = runningApps.filter { $0.bundleURL?.lastPathComponent == "\(name).app" }

		// Check our results
		if appsToQuit.count > 1 {
			// If we've got more than one result the search term is ambiguous
			throw Error.appNameAmbiguous(name)
		} else if appsToQuit.count < 1 {
			
			// TODO: Build second check for localized name using "NSRunningApplication.localizedName"
			
			// Return nil if we cannot find the app name at all
			throw Error.appNotFound(name)
		}

		// Return first element because at this point we know we only have one result in our array
		return appsToQuit[0]
	}

	// Countdown timer for app to quit
	public func countdown(_ timeout: Int) {
		os_log("Entered countdown()", log: logHandle, type: .debug)
		
		var counter = 1

		// Run the following code every second
		_ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
			do {
				if counter <= timeout {
					os_log("Waiting (%{counter}d/%{timeout}d) …", log: self.logHandle, type: .default, counter, timeout)
					counter += 1
				} else {
					timer.invalidate()
					throw Error.timeout
				}
			} catch {
				os_log("Timeout", log: self.logHandle, type: .error)
				self.printErr("Timeout")
				self.exit(with: .failure)
			}
		}
	}
	
	// Gracefully quit app, prompting for saving open documents
	public func quitApp(_ appName: String, timeout: Int = 60) throws {
		os_log("Entered quitApp()", log: logHandle, type: .debug)
		
		guard let appToQuit = try getBundleIDFromAppName(appName) else {
			throw Error.unknownError
		}

		for app in self.runningApps {
			if app == appToQuit {
				app.addObserver(self, forKeyPath: "isTerminated", options: NSKeyValueObservingOptions(), context: nil)
				app.terminate()
				os_log("Quitting '%{public}s' …", log: logHandle, type: .default, app.localizedName ?? "")
				
				countdown(timeout)
			}
		}
		// Daemonize application
		RunLoop.main.run()
	}
	
	// Custom print function for colored output
	public func printErr(_ err: String) {
		os_log("Entered printErr()", log: logHandle, type: .debug)
		
		if let stdout = stdoutStream as? LocalFileOutputByteStream {
			let tc = TerminalController(stream: stdout)
			tc?.write(err + "\n", inColor: .red, bold: true)
		}
	}

	// Implement observer function to observe NSRunningApplication.isTerminated
	override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		os_log("Entered observeValue()", log: logHandle, type: .debug)
		
		guard let app = object as? NSRunningApplication else {
			os_log("Could not fetch object in observeValue()", log: logHandle, type: .error)
			return
		}
		
		if app.isTerminated {
			os_log("'%{public}s' is no longer running", log: logHandle, type: .default, app.localizedName ?? "")
			app.removeObserver(self, forKeyPath: "isTerminated")
			exit(with: .success)
		}
	}
}

@available(OSX 10.12, *)
public extension Quit {
	enum Error: Swift.Error {
		case appNotFound(String)
		case appNameAmbiguous(String)
		case couldNotQuit(String)
		case timeout
		case unknownError
	}
}

@available(OSX 10.12, *)
public extension Quit {
	// An enum indicating the execution status of run commands.
	enum ExecutionStatus {
		case success
		case failure
	}

	/// Exit the tool with the given execution status.
	func exit(with status: ExecutionStatus) -> Never {
		os_log("Entered exit()", log: logHandle, type: .debug)
		
		switch status {
		case .success:
			os_log("Exiting 'quit' with status code 0 …", log: logHandle, type: .default)
			Darwin.exit(0)
		case .failure:
			os_log("Exiting 'quit' with status code 1 …", log: logHandle, type: .error)
			Darwin.exit(1)
		}
	}
}
