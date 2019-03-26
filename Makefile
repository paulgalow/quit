.PHONY: clean

build: clean compile

# Update dependencies
deps:
	swift package update
	swift package generate-xcodeproj

test:
	@swift test

clean:
	@rm -f /usr/local/bin/quit

compile:
	# Swift 4.2: @swift build -c release -Xswiftc -static-stdlib
	@swift build -c release --static-swift-stdlib
	@cp -f .build/release/Quit /usr/local/bin/quit