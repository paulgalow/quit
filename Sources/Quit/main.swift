import QuitCore

import Utility

if #available(OSX 10.12, *) {

	let tool = Quit()

	do {
		try tool.run()
	} catch ArgumentParserError.expectedArguments(_, let stringArray) {
		tool.printErr("Missing arguments: \(stringArray.joined())")
		print("Please provide an application name to quit, e.g. \"Google Chrome\"")
		tool.exit(with: .failure)
	} catch ArgumentParserError.unexpectedArgument(let arg) {
		tool.printErr("Unexpected positional argument: \(arg)")
		tool.exit(with: .failure)
	} catch ArgumentParserError.unknownOption(let option) {
		tool.printErr("Unknown option: \(option)")
		tool.exit(with: .failure)
	} catch Quit.Error.appNotFound(let app) {
		tool.printErr("Sorry, could not find \"\(app)\" among running applications")
		tool.exit(with: .failure)
	} catch Quit.Error.appNameAmbiguous(let app) {
		tool.printErr("Sorry, application name \"\(app)\" is ambiguous")
		tool.exit(with: .failure)
	} catch Quit.Error.couldNotQuit(let app) {
		tool.printErr("Sorry, could not quit \"\(app)\"")
		tool.exit(with: .failure)
	} catch Quit.Error.timeout {
		tool.printErr("Timeout")
		tool.exit(with: .failure)
	} catch Quit.Error.unknownError {
		tool.printErr("Sorry, there was an unknown error")
		tool.exit(with: .failure)
	} catch {
		tool.printErr("Whoops! An error occured: \(error)")
		tool.exit(with: .failure)
	}

}
