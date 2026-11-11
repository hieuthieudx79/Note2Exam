import Foundation

struct RevisionScheduler {
    /// Simple and explainable MVP heuristic, not a claim of optimal learning science.
    static func nextReview(
        from date: Date = .now,
        currentInterval: Int,
        repetitions: Int,
        rating: FlashcardRating
    ) -> (interval: Int, repetitions: Int, dueAt: Date) {
        let nextInterval: Int
        let nextRepetitions: Int

        switch rating {
        case .again:
            nextInterval = 0
            nextRepetitions = 0
        case .hard:
            nextInterval = max(1, currentInterval == 0 ? 1 : Int((Double(currentInterval) * 1.2).rounded(.up)))
            nextRepetitions = repetitions + 1
        case .good:
            nextInterval = currentInterval == 0 ? 1 : (currentInterval == 1 ? 3 : Int((Double(currentInterval) * 2).rounded()))
            nextRepetitions = repetitions + 1
        case .easy:
            nextInterval = currentInterval == 0 ? 3 : max(4, Int((Double(currentInterval) * 2.5).rounded()))
            nextRepetitions = repetitions + 1
        }

        let dueAt = Calendar.current.date(byAdding: .day, value: nextInterval, to: date) ?? date
        return (nextInterval, nextRepetitions, dueAt)
    }
}
