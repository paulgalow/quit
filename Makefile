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
	@swift build -c release -Xswiftc -static-stdlib
	@cp -f .build/release/Quit /usr/local/bin/quit