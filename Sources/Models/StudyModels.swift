import Foundation
import SwiftData

enum FlashcardRating: String, CaseIterable, Identifiable {
    case again, hard, good, easy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }
}

@Model
final class StudySet {
    @Attribute(.unique) var id: UUID
    var title: String
    var sourceName: String
    var sourceType: String
    var sourceText: String
    var summaryTitle: String
    var summaryOverview: String
    var summaryKeyPoints: [String]
    var createdAt: Date
    var updatedAt: Date
    var lastStudiedAt: Date?
    var extractionWarning: String?

    @Relationship(deleteRule: .cascade, inverse: \Flashcard.studySet)
    var flashcards: [Flashcard] = []

    @Relationship(deleteRule: .cascade, inverse: \QuizQuestion.studySet)
    var quizQuestions: [QuizQuestion] = []

    init(
        title: String,
        sourceName: String,
        sourceType: String,
        sourceText: String,
        extractionWarning: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.sourceName = sourceName
        self.sourceType = sourceType
        self.sourceText = sourceText
        self.summaryTitle = ""
        self.summaryOverview = ""
        self.summaryKeyPoints = []
        self.createdAt = .now
        self.updatedAt = .now
        self.extractionWarning = extractionWarning
    }

    var hasSummary: Bool { !summaryOverview.isEmpty }
}

@Model
final class Flashcard {
    @Attribute(.unique) var id: UUID
    var question: String
    var answer: String
    var topic: String
    var sourceExcerpt: String
    var createdAt: Date
    var dueAt: Date
    var intervalDays: Int
    var repetitions: Int
    var lastRating: String
    var studySet: StudySet?

    init(question: String, answer: String, topic: String, sourceExcerpt: String) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.topic = topic
        self.sourceExcerpt = sourceExcerpt
        self.createdAt = .now
        self.dueAt = .now
        self.intervalDays = 0
        self.repetitions = 0
        self.lastRating = "new"
    }
}

@Model
final class QuizQuestion {
    @Attribute(.unique) var id: UUID
    var prompt: String
    var optionA: String
    var optionB: String
    var optionC: String
    var optionD: String
    var correctOptionIndex: Int
    var explanation: String
    var topic: String
    var sourceExcerpt: String
    var isReported: Bool
    var studySet: StudySet?

    init(
        prompt: String,
        options: [String],
        correctOptionIndex: Int,
        explanation: String,
        topic: String,
        sourceExcerpt: String
    ) {
        self.id = UUID()
        self.prompt = prompt
        self.optionA = options.indices.contains(0) ? options[0] : ""
        self.optionB = options.indices.contains(1) ? options[1] : ""
        self.optionC = options.indices.contains(2) ? options[2] : ""
        self.optionD = options.indices.contains(3) ? options[3] : ""
        self.correctOptionIndex = min(max(correctOptionIndex, 0), 3)
        self.explanation = explanation
        self.topic = topic
        self.sourceExcerpt = sourceExcerpt
        self.isReported = false
    }

    var options: [String] { [optionA, optionB, optionC, optionD] }
}
