#!/bin/bash

# Dwellware Dashboard - Release Preparation Script
# This script prepares the project for release by running all necessary checks and preparations

set -e  # Exit on any error

# Configuration
VERSION="1.0.0-beta.1"
BUILD_NUMBER="1"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
check_environment() {
    log_info "Checking environment..."
    
    if [ ! -f "$FRONTEND_DIR/pubspec.yaml" ]; then
        log_error "pubspec.yaml not found. Are you in the correct directory?"
        exit 1
    fi
    
    if [ ! -d "$FRONTEND_DIR/lib" ]; then
        log_error "lib directory not found. This doesn't appear to be a Flutter project."
        exit 1
    fi
    
    log_success "Environment check passed"
}

# Verify Flutter installation and version
check_flutter() {
    log_info "Checking Flutter installation..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
    log_info "Flutter version: $FLUTTER_VERSION"
    
    # Check if Flutter supports macOS
    if ! flutter config | grep -q "macos.*true"; then
        log_warning "macOS support may not be enabled. Run: flutter config --enable-macos-desktop"
    fi
    
    log_success "Flutter check passed"
}

# Clean and get dependencies
prepare_dependencies() {
    log_info "Preparing dependencies..."
    
    cd "$FRONTEND_DIR"
    
    # Clean previous builds
    flutter clean
    
    # Get dependencies
    flutter pub get
    
    # Generate localization files
    flutter gen-l10n
    
    log_success "Dependencies prepared"
}

# Run static analysis
run_analysis() {
    log_info "Running static analysis..."
    
    cd "$FRONTEND_DIR"
    
    # Run Flutter analyze
    if flutter analyze; then
        log_success "Static analysis passed"
    else
        log_error "Static analysis failed. Please fix issues before release."
        exit 1
    fi
}

# Run tests
run_tests() {
    log_info "Running tests..."
    
    cd "$FRONTEND_DIR"
    
    # Run unit and widget tests
    if flutter test; then
        log_success "All tests passed"
    else
        log_error "Tests failed. Please fix failing tests before release."
        exit 1
    fi
}

# Check version consistency
check_version() {
    log_info "Checking version consistency..."
    
    # Check pubspec.yaml version
    PUBSPEC_VERSION=$(grep "^version:" "$FRONTEND_DIR/pubspec.yaml" | cut -d ' ' -f 2)
    
    if [ "$PUBSPEC_VERSION" != "$VERSION+$BUILD_NUMBER" ]; then
        log_warning "pubspec.yaml version ($PUBSPEC_VERSION) doesn't match expected ($VERSION+$BUILD_NUMBER)"
        
        # Update pubspec.yaml version
        sed -i '' "s/^version:.*/version: $VERSION+$BUILD_NUMBER/" "$FRONTEND_DIR/pubspec.yaml"
        log_info "Updated pubspec.yaml version to $VERSION+$BUILD_NUMBER"
    fi
    
    log_success "Version consistency checked"
}

# Verify build configuration
check_build_config() {
    log_info "Checking build configuration..."
    
    # Check if release configuration exists
    if [ ! -f "$FRONTEND_DIR/macos/Runner/Configs/Release.xcconfig" ]; then
        log_error "Release.xcconfig not found"
        exit 1
    fi
    
    # Check if entitlements exist
    if [ ! -f "$FRONTEND_DIR/macos/Runner/Release.entitlements" ]; then
        log_error "Release.entitlements not found"
        exit 1
    fi
    
    log_success "Build configuration verified"
}

# Test build process
test_build() {
    log_info "Testing release build..."
    
    cd "$FRONTEND_DIR"
    
    # Attempt a release build
    if flutter build macos --release --build-name="$VERSION" --build-number="$BUILD_NUMBER"; then
        log_success "Release build successful"
    else
        log_error "Release build failed"
        exit 1
    fi
    
    # Verify the app bundle was created
    APP_PATH="build/macos/Build/Products/Release/Dwellware.app"
    if [ -d "$APP_PATH" ]; then
        log_success "Application bundle created successfully"
        
        # Check bundle structure
        if [ -f "$APP_PATH/Contents/MacOS/Dwellware" ]; then
            log_success "Executable found in bundle"
        else
            log_error "Executable not found in bundle"
            exit 1
        fi
    else
        log_error "Application bundle not created"
        exit 1
    fi
}

# Verify documentation
check_documentation() {
    log_info "Checking documentation..."
    
    # Check if CHANGELOG exists and is updated
    if [ ! -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
        log_error "CHANGELOG.md not found"
        exit 1
    fi
    
    # Check if version is mentioned in CHANGELOG
    if ! grep -q "$VERSION" "$PROJECT_ROOT/CHANGELOG.md"; then
        log_warning "Version $VERSION not found in CHANGELOG.md"
    fi
    
    # Check if README exists
    if [ ! -f "$PROJECT_ROOT/README.md" ]; then
        log_warning "README.md not found in project root"
    fi
    
    log_success "Documentation check completed"
}

# Create release summary
create_release_summary() {
    log_info "Creating release summary..."
    
    SUMMARY_FILE="$PROJECT_ROOT/RELEASE_SUMMARY.md"
    
    cat > "$SUMMARY_FILE" << EOF
# Release Summary - Dwellware Dashboard v$VERSION

## Build Information
- **Version**: $VERSION
- **Build Number**: $BUILD_NUMBER
- **Build Date**: $(date)
- **Platform**: macOS Universal Binary
- **Flutter Version**: $(flutter --version | head -n 1)

## Pre-Release Checks
- ✅ Environment verified
- ✅ Flutter installation checked
- ✅ Dependencies prepared
- ✅ Static analysis passed
- ✅ All tests passed
- ✅ Version consistency verified
- ✅ Build configuration checked
- ✅ Release build successful
- ✅ Documentation verified

## Build Artifacts
- Application Bundle: \`frontend/build/macos/Build/Products/Release/Dwellware.app\`
- Size: $(du -sh "$FRONTEND_DIR/build/macos/Build/Products/Release/Dwellware.app" | cut -f1)

## Next Steps
1. Run \`./scripts/build-release.sh\` to create distribution packages
2. Run \`./scripts/package-beta.sh\` to create beta release package
3. Test installation on clean macOS system
4. Distribute to beta testers
5. Collect and analyze feedback

## Release Notes
See CHANGELOG.md for detailed release notes and feature descriptions.

## Quality Assurance
- All automated tests passed
- Static analysis clean
- Build process verified
- Documentation updated

---
Generated on $(date) by release preparation script
EOF

    log_success "Release summary created at $SUMMARY_FILE"
}

# Main preparation process
main() {
    log_info "Starting Dwellware Dashboard release preparation..."
    log_info "Target Version: $VERSION"
    log_info "Build Number: $BUILD_NUMBER"
    
    check_environment
    check_flutter
    prepare_dependencies
    run_analysis
    run_tests
    check_version
    check_build_config
    test_build
    check_documentation
    create_release_summary
    
    echo ""
    log_success "🎉 Release preparation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Review the release summary: RELEASE_SUMMARY.md"
    echo "  2. Run: ./scripts/build-release.sh"
    echo "  3. Run: ./scripts/package-beta.sh"
    echo "  4. Test the distribution packages"
    echo "  5. Distribute to beta testers"
    echo ""
    log_info "The project is ready for release! 🚀"
}

# Run main function
main "$@"