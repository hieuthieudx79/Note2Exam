# Note2Exam iOS

SwiftUI iPhone application scaffold for the Note2Exam MVP.

## Product

Note2Exam turns a learner's own PDFs, images and notes into source-grounded summaries, flashcards and multiple-choice quizzes. The MVP is Portuguese-first (Brazil), local-first and designed for Apple Intelligence-compatible iPhones.

## Included starter project

Download **[Note2Exam-iOS-Starter.zip.gz](./Note2Exam-iOS-Starter.zip.gz)**, decompress it once to obtain the ZIP archive, then unzip that archive. Open `Note2Exam/Note2Exam.xcodeproj` in Xcode.

The project contains:
- SwiftUI navigation and study-set screens
- PDFKit import and Vision OCR
- SwiftData persistence
- Apple Foundation Models summary, flashcard and quiz generation
- Local spaced-revision scheduling
- StoreKit 2 monthly/yearly subscription scaffold

## Requirements

- Xcode 26 or newer recommended
- iOS 26 deployment target
- Compatible iPhone with Foundation Models available at runtime
- App Store Connect products:
  - `com.note2exam.pro.monthly`
  - `com.note2exam.pro.yearly`

The app checks `SystemLanguageModel.default.availability` and Portuguese locale support at runtime. Device family alone does not guarantee Foundation Models availability.

## Important

This is an implementation starter, not an App Store-ready release. Build and test with Xcode on a real supported iPhone. Configure signing, bundle ID, StoreKit products, Terms and Privacy URLs, and perform native Portuguese content-quality review before release. This environment cannot perform an Xcode/iOS SDK build.

See the [Note2Exam PRD](https://app.notion.com/p/4150bccb8a3481a7abe0f4eb865d54d0) for product requirements.
