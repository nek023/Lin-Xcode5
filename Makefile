test:
	xcodebuild \
		-project Lin.xcodeproj \
		-sdk macosx \
		-scheme Lin \
		-configuration Debug \
		clean test

