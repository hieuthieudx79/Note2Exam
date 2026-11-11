# Note2Exam iOS

SwiftUI iPhone application scaffold for the Note2Exam MVP.

## Product

Note2Exam turns a learner's own PDFs, images and notes into source-grounded summaries, flashcards and multiple-choice quizzes. The MVP is Brazilian Portuguese-first, local-first, and designed for iPhones that support Apple Intelligence and Apple Foundation Models.

## Tech stack

- SwiftUI — app UI and navigation
- Apple Foundation Models — on-device summary, flashcard and quiz generation
- SwiftData — local persistence
- PDFKit + Vision — PDF extraction and image OCR
- StoreKit 2 — monthly/yearly Pro subscriptions
- XcodeGen — generate the Xcode project from \`project.yml\`

## Repository layout

- \`project.yml\` — XcodeGen project definition
- \`Sources/App\` — app entry point
- \`Sources/Models\` — SwiftData models
- \`Sources/Services\` — Foundation Models, document import, revision and subscription logic
- \`Sources/Views\` — Home, Library, Review, Settings, import, study, quiz and paywall screens

## Open the project

Requirements:
- macOS with Xcode 26 or newer
- iOS 26 SDK
- XcodeGen (\`brew install xcodegen\`)
- An iPhone compatible with Apple Intelligence / Foundation Models for on-device AI testing

\`\`\`bash
git clone https://github.com/hieuthieudx79/Note2Exam.git
cd Note2Exam
xcodegen generate
open Note2Exam.xcodeproj
\`\`\`

In Xcode:
1. Select the Note2Exam scheme.
2. Set your Development Team under Signing & Capabilities.
3. Choose an iOS 26 simulator or a compatible physical iPhone.
4. Build and run.
5. On device, verify Foundation Models availability and Portuguese locale support before testing generation.

The app checks model availability at runtime. A compatible device family alone does not guarantee that Foundation Models is available in the current OS, locale, region or system state.

## StoreKit setup

Create these auto-renewable subscription products in App Store Connect:

- \`com.note2exam.pro.monthly\`
- \`com.note2exam.pro.yearly\`

Both products unlock the \`pro\` entitlement in the app. Product display prices are loaded from StoreKit, not hardcoded. Configure a StoreKit Configuration file in Xcode for local purchase testing, then test restore, renewal, expiration, billing retry and revocation in Sandbox/TestFlight.

Before public release:
- Add published Terms of Use and Privacy Policy URLs to the paywall.
- Confirm Brazilian storefront price tiers and subscription group configuration.
- Complete App Store signing, metadata, screenshots and privacy disclosures.

## Current implementation scope

- SwiftUI tab navigation and study-set screens
- PDF import and OCR for scanned pages/images
- Local SwiftData storage
- Foundation Models summary, flashcard and quiz generation
- Flashcard revision scheduling
- StoreKit 2 monthly/yearly subscription paywall

## Important

This repository is an implementation starter, not an App Store-ready release. Xcode build and physical-device validation are still required. This environment cannot run the Xcode/iOS SDK build.

The implementation intentionally does not upload study documents to a Note2Exam server or use a cloud LLM in the MVP. Verify this behavior and all privacy claims during testing.

See the [Note2Exam PRD](https://app.notion.com/p/4150bccb8a3481a7abe0f4eb865d54d0) for product requirements.
