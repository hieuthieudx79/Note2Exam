import SwiftUI
import SwiftData

struct FlashcardSessionView: View {
    let cards: [Flashcard]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var index = 0
    @State private var showingAnswer = false
    @State private var completed = 0

    private var currentCard: Flashcard? {
        cards.indices.contains(index) ? cards[index] : nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                if let card = currentCard {
                    Text("Cartão \(index + 1) de \(cards.count)")
                        .font(.subheadline).foregroundStyle(.secondary)

                    VStack(spacing: 18) {
                        Text(card.question)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        if showingAnswer {
                            Divider()
                            Text(card.answer)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                            if !card.sourceExcerpt.isEmpty {
                                Text("Fonte: \(card.sourceExcerpt)")
                                    .font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .padding(24)
                    .background(.background, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 5)

                    if showingAnswer {
                        Text("Como foi sua resposta?")
                            .font(.headline)
                        HStack {
                            ForEach(FlashcardRating.allCases) { rating in
                                Button(rating.title) { rate(rating, card: card) }
                                    .buttonStyle(.borderedProminent)
                                    .tint(rating == .again ? .orange : .indigo)
                            }
                        }
                    } else {
                        Button("Mostrar resposta") { showingAnswer = true }
                            .buttonStyle(.borderedProminent).tint(.indigo)
                    }
                    Spacer()
                } else {
                    ContentUnavailableView(
                        "Sessão concluída",
                        systemImage: "checkmark.seal.fill",
                        description: Text("\(completed) cartões revisados.")
                    )
                    Button("Fechar") { dismiss() }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private func rate(_ rating: FlashcardRating, card: Flashcard) {
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

        completed += 1
        index += 1
        showingAnswer = false
    }
}

struct QuizSessionView: View {
    let questions: [QuizQuestion]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var index = 0
    @State private var selected: Int?
    @State private var submitted = false
    @State private var score = 0
    @State private var finished = false

    private var question: QuizQuestion? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                if finished {
                    ContentUnavailableView(
                        "Quiz concluído",
                        systemImage: "trophy.fill",
                        description: Text("Você acertou \(score) de \(questions.count) questões.")
                    )
                    Button("Fechar") { dismiss() }
                        .buttonStyle(.borderedProminent)
                } else if let question {
                    Text("Questão \(index + 1) de \(questions.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(question.prompt).font(.title2.bold())

                    ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                        Button {
                            if !submitted { selected = optionIndex }
                        } label: {
                            HStack {
                                Text(option).multilineTextAlignment(.leading)
                                Spacer()
                                if selected == optionIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                selected == optionIndex ? Color.indigo.opacity(0.12) : Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(submitted)
                    }

                    if submitted {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selected == question.correctOptionIndex ? "Correto!" : "Resposta incorreta")
                                .font(.headline)
                                .foregroundStyle(selected == question.correctOptionIndex ? .green : .orange)
                            Text(question.explanation)
                            if !question.sourceExcerpt.isEmpty {
                                Text("Fonte: \(question.sourceExcerpt)")
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(4)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }

                    Button(submitted ? "Próxima" : "Verificar resposta") {
                        if !submitted {
                            submitted = true
                            if selected == question.correctOptionIndex { score += 1 }
                            try? modelContext.save()
                        } else if index + 1 < questions.count {
                            index += 1
                            selected = nil
                            submitted = false
                        } else {
                            finished = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(!submitted && selected == nil)
                    Spacer()
                } else {
                    ContentUnavailableView("Nenhuma questão", systemImage: "questionmark.circle")
                }
            }
            .padding()
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
