#!/bin/bash

# Dwellware Dashboard - Beta Packaging Script
# This script creates a beta distribution package with documentation

set -e  # Exit on any error

# Configuration
APP_NAME="Dwellware"
VERSION="1.0.0-beta.1"
BETA_NAME="Dwellware-Dashboard-Beta"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_ROOT/dist"
BETA_DIR="$PROJECT_ROOT/beta-release"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Create beta package
create_beta_package() {
    log_info "Creating beta release package..."
    
    # Clean and create beta directory
    rm -rf "$BETA_DIR"
    mkdir -p "$BETA_DIR"
    
    # Copy distribution files
    if [ -d "$DIST_DIR" ]; then
        cp -R "$DIST_DIR"/* "$BETA_DIR/"
    else
        log_info "No distribution files found. Run build-release.sh first."
        exit 1
    fi
    
    # Create beta documentation
    create_beta_docs
    
    # Create installation guide
    create_installation_guide
    
    # Create feedback form
    create_feedback_template
    
    log_success "Beta package created in $BETA_DIR"
}

# Create beta-specific documentation
create_beta_docs() {
    log_info "Creating beta documentation..."
    
    cat > "$BETA_DIR/BETA_README.md" << 'EOF'
# Dwellware Dashboard Beta Release

Welcome to the Dwellware Dashboard beta program! Thank you for helping us test and improve this revolutionary household application management system.

## What is Dwellware Dashboard?

Dwellware Dashboard is a native macOS application that makes creating custom household applications as easy as having a conversation. Simply describe what you need in plain English, and the system handles all the technical complexity.

## Beta Release Information

- **Version**: 1.0.0-beta.1
- **Release Date**: January 26, 2025
- **Platform**: macOS 10.14+ (Universal Binary)
- **Status**: Beta - For testing purposes only

## Quick Start

1. **Install**: Open the DMG file and drag Dwellware to your Applications folder
2. **Launch**: Open Dwellware from Applications
3. **Setup**: Follow the initial setup wizard
4. **Create**: Click "Create New App" and describe what you'd like to build
5. **Monitor**: Watch your application being developed in real-time
6. **Launch**: Use your completed application directly from the dashboard

## Key Features to Test

### 🏠 Application Management
- Create applications through natural conversation
- Monitor development progress in real-time
- Launch and manage completed applications
- Search and organize your application library

### 💬 Conversational Interface
- Natural language application requests
- Clarifying questions for better results
- Context-aware conversation flow
- Request modification and refinement

### 📊 Progress Monitoring
- Real-time development tracking
- Phase-by-phase progress visualization
- Detailed build logs and milestone tracking
- Error reporting and recovery options

### 🚀 Application Launching
- One-click application launching
- Integrated WebView for web applications
- Window management and state preservation
- Application health monitoring

## What We're Looking For

As a beta tester, your feedback is invaluable. We're particularly interested in:

### User Experience
- How intuitive is the application creation process?
- Are the conversation flows natural and helpful?
- Is the interface responsive and easy to navigate?
- Do error messages provide helpful guidance?

### Performance
- How quickly does the application respond to interactions?
- Are animations smooth and polished?
- Does the real-time progress monitoring work reliably?
- How well does the application handle multiple concurrent operations?

### Reliability
- Do you encounter any crashes or unexpected behavior?
- Are there any features that don't work as expected?
- How stable is the WebSocket connection for progress updates?
- Do applications launch and run correctly?

### Feature Completeness
- What additional features would be most valuable?
- Are there any workflow gaps or missing functionality?
- How could the conversation interface be improved?
- What would make application management more efficient?

## Known Issues

Please be aware of these known issues in the beta:

- **WebSocket Reconnection**: Occasional delays when reconnecting during development monitoring
- **Search Highlighting**: May not work correctly with special characters in application names
- **Window State**: Application window positions may not restore exactly after restart
- **Error Messages**: Some technical errors could have more user-friendly explanations
- **Offline Mode**: Limited functionality when internet connection is unavailable

## System Requirements

### Minimum Requirements
- **OS**: macOS 10.14 (Mojave) or later
- **Architecture**: Intel x64 or Apple Silicon (M1/M2)
- **Memory**: 4GB RAM
- **Storage**: 500MB available disk space
- **Network**: Internet connection required for application development

### Recommended Requirements
- **OS**: macOS 11.0 (Big Sur) or later
- **Memory**: 8GB RAM or more
- **Storage**: 2GB available disk space for application storage
- **Network**: Broadband internet connection for optimal performance

## Installation Instructions

### Standard Installation
1. Download the `Dwellware-1.0.0-beta.1.dmg` file
2. Double-click to open the disk image
3. Drag the Dwellware application to your Applications folder
4. Launch Dwellware from Applications or Spotlight
5. Follow the setup wizard on first launch

### Security Notes
This beta release is not code-signed with a Developer ID certificate. You may need to:

1. Right-click the application and select "Open"
2. Click "Open" in the security dialog
3. Or go to System Preferences > Security & Privacy and click "Open Anyway"

### Troubleshooting Installation
If you encounter issues:
- Ensure you have admin privileges on your Mac
- Try restarting your Mac and installing again
- Check that you have sufficient disk space
- Verify your macOS version meets requirements

## Providing Feedback

Your feedback helps us improve Dwellware Dashboard. Here are the ways to share your experience:

### In-App Feedback
- Use the "Send Feedback" option in the application menu
- Report issues directly from error dialogs
- Use the feedback button in the conversation interface

### Bug Reports
Please include:
- Steps to reproduce the issue
- Expected vs. actual behavior
- Screenshots or screen recordings if helpful
- System information (macOS version, hardware)
- Console logs if available

### Feature Requests
Tell us about:
- Workflows that could be improved
- Missing functionality you'd like to see
- Ideas for new application types
- Integration suggestions

### General Feedback
Share your thoughts on:
- Overall user experience
- Interface design and usability
- Performance and reliability
- Documentation and help content

## Beta Program Guidelines

### What to Expect
- **Regular Updates**: New beta versions with fixes and improvements
- **Direct Communication**: Responses to feedback and bug reports
- **Early Access**: Preview of upcoming features and enhancements
- **Community**: Access to beta tester discussions and forums

### What We Ask
- **Active Testing**: Regular use and exploration of features
- **Detailed Feedback**: Specific, actionable feedback on issues and improvements
- **Patience**: Understanding that this is beta software with potential issues
- **Confidentiality**: Please don't share beta builds with non-participants

## Support and Resources

### Documentation
- **User Guide**: Comprehensive guide to all features (included in app)
- **FAQ**: Common questions and answers
- **Video Tutorials**: Step-by-step feature demonstrations
- **API Documentation**: For advanced users and integrations

### Community
- **Beta Forum**: Discuss with other beta testers
- **Feature Requests**: Vote on and suggest new features
- **Best Practices**: Share tips and successful application examples

### Direct Support
- **Email**: beta-support@dwellware.com
- **Response Time**: 24-48 hours for beta issues
- **Priority**: Critical bugs and blocking issues get immediate attention

## Privacy and Data

### Data Collection
During the beta, we collect:
- **Usage Analytics**: Feature usage and performance metrics
- **Error Reports**: Crash logs and error information
- **Feedback Data**: Your submitted feedback and bug reports

### Data Protection
- All data is encrypted in transit and at rest
- Personal information is never shared with third parties
- You can request data deletion at any time
- Full privacy policy available in the application

## Roadmap and Future

### Upcoming Features
Based on feedback, we're planning:
- **Multi-Platform Support**: Windows and Linux versions
- **Native Applications**: Support for desktop applications beyond web apps
- **Team Collaboration**: Shared application libraries and permissions
- **Advanced Automation**: Scheduled tasks and application orchestration
- **Enhanced Offline**: Better functionality without internet connection

### Release Timeline
- **Beta Period**: January - March 2025
- **Release Candidate**: April 2025
- **General Availability**: May 2025

## Thank You

Thank you for participating in the Dwellware Dashboard beta program. Your feedback and testing are essential to creating the best possible household application management experience.

We're excited to see what amazing applications you'll create and how Dwellware Dashboard transforms your household workflows.

Happy testing!

---

*The Dwellware Team*  
*January 2025*
EOF

    log_success "Beta documentation created"
}

# Create installation guide
create_installation_guide() {
    log_info "Creating installation guide..."
    
    cat > "$BETA_DIR/INSTALLATION_GUIDE.md" << 'EOF'
# Dwellware Dashboard - Installation Guide

This guide will help you install and set up Dwellware Dashboard on your macOS system.

## Before You Begin

### System Requirements Check
Before installing, verify your system meets these requirements:

```bash
# Check macOS version
sw_vers

# Check available disk space
df -h

# Check memory
system_profiler SPHardwareDataType | grep Memory
```

**Requirements:**
- macOS 10.14 (Mojave) or later
- Intel x64 or Apple Silicon (M1/M2)
- 4GB RAM minimum (8GB recommended)
- 500MB available disk space
- Internet connection

## Installation Steps

### Step 1: Download
1. Download `Dwellware-1.0.0-beta.1.dmg` from the provided link
2. Verify the download completed successfully
3. Check the file size matches the expected size in RELEASE_INFO.txt

### Step 2: Verify Integrity (Optional but Recommended)
```bash
# Verify SHA256 checksum
shasum -a 256 Dwellware-1.0.0-beta.1.dmg
# Compare with the .sha256 file
```

### Step 3: Mount and Install
1. **Double-click** the DMG file to mount it
2. **Wait** for the disk image to open
3. **Drag** the Dwellware application to the Applications folder
4. **Wait** for the copy operation to complete
5. **Eject** the disk image when finished

### Step 4: First Launch
1. **Open** Applications folder (Cmd+Shift+A)
2. **Find** Dwellware in the list
3. **Right-click** on Dwellware and select "Open"
4. **Click "Open"** in the security dialog (required for unsigned beta)

### Step 5: Initial Setup
1. **Follow** the setup wizard
2. **Grant** necessary permissions when prompted
3. **Configure** your preferences
4. **Complete** the initial setup

## Security Considerations

### Gatekeeper and Code Signing
This beta release is not code-signed with a Developer ID certificate. macOS will show security warnings.

**To allow the application to run:**

#### Method 1: Right-Click Open (Recommended)
1. Right-click the Dwellware application
2. Select "Open" from the context menu
3. Click "Open" in the security dialog

#### Method 2: System Preferences
1. Try to open Dwellware normally
2. Go to System Preferences > Security & Privacy
3. Click "Open Anyway" next to the Dwellware message
4. Enter your admin password if prompted

#### Method 3: Command Line (Advanced)
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine /Applications/Dwellware.app
```

### Permissions
Dwellware may request these permissions:
- **Network Access**: For API communication and application development
- **File System Access**: For managing application files and preferences
- **Notifications**: For development progress and status updates

## Troubleshooting Installation

### Common Issues

#### "Dwellware.app is damaged and can't be opened"
**Cause**: Incomplete download or corruption  
**Solution**: 
1. Delete the downloaded DMG file
2. Clear browser cache
3. Re-download the DMG file
4. Verify checksum before installing

#### "The disk image couldn't be opened"
**Cause**: Corrupted DMG file  
**Solution**:
1. Re-download the DMG file
2. Try opening with Disk Utility
3. Check available disk space

#### Application won't launch after installation
**Cause**: Security restrictions or missing dependencies  
**Solution**:
1. Check Console.app for error messages
2. Ensure macOS version compatibility
3. Try the security bypass methods above
4. Restart your Mac and try again

#### "You don't have permission to open the application"
**Cause**: File permissions issue  
**Solution**:
```bash
# Fix permissions
sudo chown -R $(whoami) /Applications/Dwellware.app
chmod +x /Applications/Dwellware.app/Contents/MacOS/Dwellware
```

### Getting Help

If you encounter issues not covered here:

1. **Check Console Logs**:
   - Open Console.app
   - Filter for "Dwellware"
   - Look for error messages

2. **Collect System Information**:
   ```bash
   system_profiler SPSoftwareDataType > system_info.txt
   ```

3. **Contact Support**:
   - Email: beta-support@dwellware.com
   - Include: Error messages, system info, steps to reproduce

## Post-Installation

### Verify Installation
1. **Launch** Dwellware successfully
2. **Complete** the setup wizard
3. **Create** a test application request
4. **Verify** all features work as expected

### Recommended Setup
1. **Add to Dock**: Drag from Applications to Dock
2. **Enable Notifications**: Allow in System Preferences
3. **Configure Auto-Start**: Set in Dwellware preferences if desired
4. **Backup Preferences**: Note your settings for future reference

### Performance Optimization
1. **Close Unnecessary Apps**: Free up system resources
2. **Ensure Good Network**: Stable internet for best experience
3. **Regular Restarts**: Restart Dwellware periodically during beta testing
4. **Monitor Resources**: Use Activity Monitor to check performance

## Uninstallation

If you need to remove Dwellware:

### Complete Removal
```bash
# Remove application
rm -rf /Applications/Dwellware.app

# Remove preferences
rm -rf ~/Library/Preferences/com.toglefritz.householdAiEngineer.plist

# Remove application support files
rm -rf ~/Library/Application\ Support/Dwellware/

# Remove logs
rm -rf ~/Library/Logs/Dwellware/

# Remove caches
rm -rf ~/Library/Caches/com.toglefritz.householdAiEngineer/
```

### Selective Removal
To keep your data but remove the application:
```bash
# Remove only the application
rm -rf /Applications/Dwellware.app
```

## Next Steps

After successful installation:

1. **Read** the BETA_README.md for testing guidelines
2. **Explore** the application features
3. **Create** your first application
4. **Provide** feedback on your experience
5. **Join** the beta community discussions

## Support Resources

- **Beta Documentation**: BETA_README.md
- **User Guide**: Available within the application
- **FAQ**: Common questions and solutions
- **Community Forum**: Connect with other beta testers
- **Direct Support**: beta-support@dwellware.com

---

*Happy testing with Dwellware Dashboard!*
EOF

    log_success "Installation guide created"
}

# Create feedback template
create_feedback_template() {
    log_info "Creating feedback template..."
    
    cat > "$BETA_DIR/FEEDBACK_TEMPLATE.md" << 'EOF'
# Dwellware Dashboard Beta Feedback Template

Thank you for testing Dwellware Dashboard! Your feedback is invaluable in making this the best possible household application management tool.

## Basic Information

**Beta Version**: 1.0.0-beta.1  
**Test Date**: [Date of testing]  
**macOS Version**: [Your macOS version]  
**Hardware**: [Intel/Apple Silicon, RAM amount]  
**Testing Duration**: [How long you've been testing]  

## Overall Experience

### First Impressions
- What was your initial reaction to the application?
- How intuitive was the setup process?
- Did the interface meet your expectations?

### Ease of Use (1-5 scale, 5 being excellent)
- **Application Creation**: [ ] How easy was it to create your first application?
- **Navigation**: [ ] How easy was it to find and use features?
- **Understanding**: [ ] How clear were the instructions and feedback?
- **Efficiency**: [ ] How quickly could you accomplish tasks?

## Feature Testing

### Application Creation
**Did you successfully create an application?** [Yes/No]

If Yes:
- What type of application did you create?
- How many conversation turns did it take?
- Were the clarifying questions helpful?
- Was the final result what you expected?

If No:
- Where did the process fail?
- What error messages did you see?
- What would have helped you succeed?

### Progress Monitoring
**Did you observe the development process?** [Yes/No]

- How clear was the progress information?
- Did the real-time updates work correctly?
- Were the build logs helpful or confusing?
- Did you experience any connection issues?

### Application Launching
**Did you successfully launch a completed application?** [Yes/No]

- How responsive was the launch process?
- Did the application work as expected?
- Were there any display or functionality issues?
- How was the window management?

### Search and Organization
**Did you test the search functionality?** [Yes/No]

- How accurate were the search results?
- Was the filtering useful?
- Did you try organizing multiple applications?
- Any issues with the grid layout?

## Specific Feedback Areas

### User Interface
**What did you like about the interface?**
- 
- 
- 

**What could be improved?**
- 
- 
- 

**Any confusing elements?**
- 
- 
- 

### Performance
**How was the overall performance?**
- Application startup time: [Fast/Acceptable/Slow]
- Response to interactions: [Immediate/Acceptable/Laggy]
- Memory usage: [Light/Acceptable/Heavy]
- Battery impact: [Minimal/Acceptable/Significant]

**Any performance issues encountered?**
- 
- 
- 

### Reliability
**Did you encounter any crashes or errors?** [Yes/No]

If Yes, please describe:
- What were you doing when it happened?
- How often did it occur?
- Were you able to recover easily?
- Any error messages or codes?

**Any features that didn't work as expected?**
- 
- 
- 

## Bug Reports

### Bug #1
**Summary**: [Brief description]  
**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**: [What should happen]  
**Actual Result**: [What actually happened]  
**Frequency**: [Always/Sometimes/Rarely]  
**Severity**: [Critical/High/Medium/Low]  

### Bug #2
**Summary**: [Brief description]  
**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**: [What should happen]  
**Actual Result**: [What actually happened]  
**Frequency**: [Always/Sometimes/Rarely]  
**Severity**: [Critical/High/Medium/Low]  

## Feature Requests

### High Priority
What features would make the biggest difference to your experience?
1. 
2. 
3. 

### Nice to Have
What additional features would be useful but not essential?
1. 
2. 
3. 

### Integration Ideas
What other tools or services would you like to see integrated?
1. 
2. 
3. 

## Use Cases

### Your Applications
What types of applications did you create or try to create?
- 
- 
- 

### Household Context
How do you envision using Dwellware in your household?
- 
- 
- 

### Workflow Integration
How would this fit into your existing routines?
- 
- 
- 

## Comparison and Context

### Similar Tools
Have you used similar application creation or management tools?
- Which ones?
- How does Dwellware compare?
- What does Dwellware do better/worse?

### Expectations vs Reality
- What did you expect before trying Dwellware?
- How did the reality compare?
- What surprised you (positively or negatively)?

## Recommendations

### Would you recommend Dwellware to others? [Yes/No/Maybe]
**Why or why not?**


### Who would benefit most from this tool?**


### What would need to change for you to use this regularly?**


## Additional Comments

### Anything else you'd like to share?


### Questions for the development team?


### Suggestions for the beta program?


---

## Submission Information

**How to submit this feedback:**

1. **Email**: Send to beta-feedback@dwellware.com
2. **Subject**: "Beta Feedback - [Your Name/Identifier]"
3. **Attachments**: Include screenshots, logs, or recordings if helpful

**What happens next:**
- We'll acknowledge receipt within 24 hours
- Critical bugs will be addressed in the next beta release
- Feature requests will be considered for future versions
- You may be contacted for clarification or follow-up testing

**Thank you for your valuable feedback!**

---

*Dwellware Dashboard Beta Program*  
*Version 1.0.0-beta.1*
EOF

    log_success "Feedback template created"
}

# Main function
main() {
    log_info "Creating Dwellware Dashboard beta package..."
    
    create_beta_package
    
    # Create final beta archive
    BETA_ARCHIVE="$PROJECT_ROOT/${BETA_NAME}-${VERSION}.zip"
    cd "$PROJECT_ROOT"
    zip -r "$BETA_ARCHIVE" "$(basename "$BETA_DIR")"
    
    log_success "Beta package completed!"
    log_info "Beta archive: $BETA_ARCHIVE"
    log_info "Beta directory: $BETA_DIR"
}

# Run main function
main "$@"