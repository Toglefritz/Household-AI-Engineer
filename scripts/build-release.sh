#!/bin/bash

# Dwellware Dashboard - macOS Release Build Script
# This script builds and packages the Flutter dashboard for distribution

set -e  # Exit on any error

# Configuration
APP_NAME="Dwellware"
BUNDLE_ID="com.toglefritz.householdAiEngineer"
VERSION="1.0.0-beta.1"
BUILD_NUMBER="1"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Flutter version
    FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
    log_info "Flutter version: $FLUTTER_VERSION"
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools are not installed"
        exit 1
    fi
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script must be run on macOS"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    
    cd "$FRONTEND_DIR"
    
    # Clean Flutter build
    flutter clean
    
    # Remove build directories
    rm -rf build/
    rm -rf "$BUILD_DIR"
    rm -rf "$DIST_DIR"
    
    # Create fresh directories
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    
    log_success "Build directories cleaned"
}

# Get dependencies
get_dependencies() {
    log_info "Getting Flutter dependencies..."
    
    cd "$FRONTEND_DIR"
    flutter pub get
    
    log_success "Dependencies retrieved"
}

# Generate localization files
generate_localizations() {
    log_info "Generating localization files..."
    
    cd "$FRONTEND_DIR"
    flutter gen-l10n
    
    log_success "Localization files generated"
}

# Build the Flutter app
build_flutter_app() {
    log_info "Building Flutter app for macOS..."
    
    cd "$FRONTEND_DIR"
    
    # Build for release
    flutter build macos \
        --release \
        --build-name="$VERSION" \
        --build-number="$BUILD_NUMBER" \
        --dart-define=FLUTTER_WEB_USE_SKIA=true
    
    log_success "Flutter app built successfully"
}

# Code signing (placeholder - requires actual certificates)
code_sign_app() {
    log_info "Code signing application..."
    
    APP_PATH="$FRONTEND_DIR/build/macos/Build/Products/Release/$APP_NAME.app"
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "Application bundle not found at $APP_PATH"
        exit 1
    fi
    
    # Note: This requires proper code signing certificates
    # For beta distribution, we'll skip code signing
    log_warning "Code signing skipped for beta release"
    log_warning "For production release, configure proper code signing certificates"
    
    # Uncomment and configure for production:
    # codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" "$APP_PATH"
    
    log_success "Code signing completed (skipped for beta)"
}

# Create DMG installer
create_dmg() {
    log_info "Creating DMG installer..."
    
    APP_PATH="$FRONTEND_DIR/build/macos/Build/Products/Release/$APP_NAME.app"
    DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "Application bundle not found at $APP_PATH"
        exit 1
    fi
    
    # Create temporary DMG directory
    TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"
    mkdir -p "$TEMP_DMG_DIR"
    
    # Copy app to temp directory
    cp -R "$APP_PATH" "$TEMP_DMG_DIR/"
    
    # Create Applications symlink
    ln -s /Applications "$TEMP_DMG_DIR/Applications"
    
    # Create DMG
    hdiutil create -volname "$APP_NAME $VERSION" \
        -srcfolder "$TEMP_DMG_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    # Clean up temp directory
    rm -rf "$TEMP_DMG_DIR"
    
    log_success "DMG created at $DMG_PATH"
}

# Create ZIP archive
create_zip() {
    log_info "Creating ZIP archive..."
    
    APP_PATH="$FRONTEND_DIR/build/macos/Build/Products/Release/$APP_NAME.app"
    ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.zip"
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "Application bundle not found at $APP_PATH"
        exit 1
    fi
    
    cd "$(dirname "$APP_PATH")"
    zip -r "$ZIP_PATH" "$APP_NAME.app"
    
    log_success "ZIP archive created at $ZIP_PATH"
}

# Generate checksums
generate_checksums() {
    log_info "Generating checksums..."
    
    cd "$DIST_DIR"
    
    # Generate SHA256 checksums
    for file in *.dmg *.zip; do
        if [ -f "$file" ]; then
            shasum -a 256 "$file" > "$file.sha256"
            log_info "Checksum for $file: $(cat "$file.sha256")"
        fi
    done
    
    log_success "Checksums generated"
}

# Create release notes
create_release_info() {
    log_info "Creating release information..."
    
    RELEASE_INFO="$DIST_DIR/RELEASE_INFO.txt"
    
    cat > "$RELEASE_INFO" << EOF
Dwellware Dashboard - Release Information
========================================

Version: $VERSION
Build Number: $BUILD_NUMBER
Build Date: $(date)
Platform: macOS (Universal Binary)

System Requirements:
- macOS 10.14 (Mojave) or later
- Intel x64 or Apple Silicon (M1/M2)
- 4GB RAM minimum, 8GB recommended
- 500MB available disk space
- Internet connection required

Installation Instructions:
1. Download the DMG file
2. Open the DMG and drag Dwellware to Applications folder
3. Launch Dwellware from Applications
4. Follow the setup wizard on first launch

Files in this release:
EOF
    
    # List files with sizes
    for file in "$DIST_DIR"/*; do
        if [ -f "$file" ] && [[ "$file" != "$RELEASE_INFO" ]]; then
            filename=$(basename "$file")
            size=$(ls -lh "$file" | awk '{print $5}')
            echo "- $filename ($size)" >> "$RELEASE_INFO"
        fi
    done
    
    log_success "Release information created at $RELEASE_INFO"
}

# Main build process
main() {
    log_info "Starting Dwellware Dashboard release build..."
    log_info "Version: $VERSION"
    log_info "Build Number: $BUILD_NUMBER"
    
    check_prerequisites
    clean_build
    get_dependencies
    generate_localizations
    build_flutter_app
    code_sign_app
    create_dmg
    create_zip
    generate_checksums
    create_release_info
    
    log_success "Release build completed successfully!"
    log_info "Distribution files available in: $DIST_DIR"
    
    # List created files
    echo ""
    log_info "Created files:"
    ls -la "$DIST_DIR"
}

# Run main function
main "$@"