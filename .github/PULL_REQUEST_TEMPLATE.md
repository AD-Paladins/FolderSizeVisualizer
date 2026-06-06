# Pull Request Template

## 📋 Description
<!-- Provide a clear and concise description of what this PR does. -->
<!-- Link to related issue(s) using keywords like "Fixes #123" or "Closes #456" -->

**What changed:**
- 

**Why it changed:**
- 

## 🔗 Related Issues
<!-- List any related issues, tickets, or discussions. -->
- Fixes #
- Related to #

## ✅ Type of Change
<!-- Check all that apply. -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] ♻️ Refactoring (improves code quality without changing behavior)
- [ ] 📝 Documentation update
- [ ] 🧪 Test addition or improvement
- [ ] ⚡ Performance improvement
- [ ] 🔧 Configuration / build / CI change
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)

## 🧪 Testing
<!-- Describe how you tested your changes. -->
### Unit Tests
- [ ] Added/updated unit tests
- [ ] All existing unit tests pass

### Integration Tests
- [ ] Added/updated integration tests
- [ ] All existing integration tests pass

### Manual Testing
- [ ] Tested on device/simulator (iOS / Android)
- [ ] Tested on different OS versions
- [ ] Tested with different screen sizes / orientations
- [ ] Tested offline / poor network conditions
- [ ] Tested accessibility (VoiceOver / TalkBack)

### Screenshots / Videos (if UI changes)
<!-- Attach before/after screenshots or a short video demo. -->
| Before | After |
|--------|-------|
|        |       |

## 📱 Mobile-Specific Checklist
<!-- Check all that apply for mobile apps. -->
- [ ] **App builds successfully** in Debug and Release configurations
- [ ] **No new warnings** introduced (SwiftLint / ktlint / ESLint etc.)
- [ ] **Permissions** updated in Info.plist / AndroidManifest.xml if needed
- [ ] **Deep links / URL schemes** work correctly
- [ ] **Push notifications** tested (if applicable)
- [ ] **Background / foreground transitions** handled gracefully
- [ ] **Memory leaks** checked (Instruments / LeakCanary / etc.)
- [ ] **Crash reporting** verified (Sentry, Firebase Crashlytics, etc.)
- [ ] **Analytics / tracking** events fire as expected
- [ ] **Localization** strings added/updated for all supported languages
- [ ] **Dark mode / system theme** respected
- [ ] **Dynamic Type / font scaling** works
- [ ] **Orientation changes** handled (if supported)
- [ ] **Keyboard avoidance** works on relevant screens
- [ ] **Safe area / notch / Dynamic Island** respected
- [ ] **Biometric / FaceID / TouchID** flows tested (if applicable)
- [ ] **App Store / Play Store guidelines** considered (no private APIs, proper usage descriptions, etc.)

## 🏗️ Build & CI
- [ ] CI pipeline passes (GitHub Actions / Bitrise / Fastlane / etc.)
- [ ] Code coverage maintained or improved
- [ ] Static analysis passes (SwiftLint, ktlint, Detekt, SonarQube, etc.)
- [ ] Dependency updates reviewed (SPM / CocoaPods / Gradle / npm)

## 📚 Documentation
- [ ] README updated (if needed)
- [ ] CHANGELOG updated (if needed)
- [ ] API docs / comments updated
- [ ] Architecture decision record (ADR) added (for significant changes)

## 🔍 Code Review Focus Areas
<!-- Highlight specific areas you'd like reviewers to pay attention to. -->
- 

## ✍️ Reviewer Checklist
<!-- For reviewers to tick off during review. -->
- [ ] Code follows project style guides and conventions
- [ ] No obvious logic errors or edge cases missed
- [ ] Tests are meaningful and cover the changed behavior
- [ ] No sensitive data (keys, tokens, PII) committed
- [ ] Performance implications considered
- [ ] Security implications considered
- [ ] Backward compatibility maintained (or migration path provided)

## 📦 Release Notes
<!-- Optional: Provide a short summary for the release notes. -->
<!-- This will be copied into the release changelog. -->
**Release Note:**
- 

---

> **Note:** This template is a guideline. Adjust sections as needed for your specific change. The goal is to make the review process smooth and ensure high-quality mobile releases.