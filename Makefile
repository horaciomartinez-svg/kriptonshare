all:
	@echo "Building KRIPTONSHARE..."
	flutter pub get
	flutter build apk --release

# iOS (requires macOS + Xcode)
build-ios:
	flutter build ios --release --no-codesign

# Web build
build-web:
	flutter build web --release

# Clean build artifacts
clean:
	flutter clean
	flutter pub get

# Run tests
test:
	flutter test

# Analyze code (CI-compliant)
analyze:
	flutter analyze --fatal-warnings

# Run in debug mode
debug:
	flutter run

# Generate icon launchers
icons:
	flutter pub run flutter_launcher_icons:main

# Format code
format:
	dart format --set-exit-if-changed lib/ test/

# Generate API documentation
docs:
	dart doc --output doc/api

# Full CI pipeline (analyze + test + build)
ci: analyze test build-apk

.PHONY: all build-apk build-ios build-web clean test analyze debug icons format docs ci
