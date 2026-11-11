import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query private var studySets: [StudySet]
    @Environment(\.modelContext) private var modelContext

    private var dueCards: [Flashcard] {
        studySets.flatMap(\.flashcards).filter { $0.dueAt <= .now }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if dueCards.isEmpty {
                        ContentUnavailableView(
                            "Tudo em dia!",
                            systemImage: "checkmark.circle",
                            description: Text("Nenhum flashcard precisa ser revisado agora.")
                        )
                    } else {
                        ForEach(dueCards) { card in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(card.question).font(.headline)
                                Text(card.answer).font(.subheadline).foregroundStyle(.secondary)
                                HStack {
                                    ForEach(FlashcardRating.allCases) { rating in
                                        Button(rating.title) {
                                            apply(rating, to: card)
                                        }
                                        .font(.caption.bold())
                                        .buttonStyle(.bordered)
                                        .tint(rating == .again ? .orange : .indigo)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                } header: {
                    Text("Revisões pendentes · \(dueCards.count)")
                }
            }
            .navigationTitle("Revisar")
        }
    }

    private func apply(_ rating: FlashcardRating, to card: Flashcard) {
        let result = RevisionScheduler.nextReview(
            currentInterval: card.intervalDays,
            repetitions: card.repetitions,
            rating: rating
        )
        card.intervalDays = result.interval
        card.repetitions = result.repetitions
        card.dueAt = result.dueAt
        card.lastRating = rating.rawValue
        try? modelContext.save()
    }
}
