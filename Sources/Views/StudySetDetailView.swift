import SwiftUI
import SwiftData

private enum StudySheet: String, Identifiable {
    case summary, flashcards, quiz
    var id: String { rawValue }
}

struct StudySetDetailView: View {
    @Bindable var studySet: StudySet
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptions: SubscriptionManager

    @State private var ai = FoundationModelsService()
    @State private var isWorking = false
    @State private var progressText = ""
    @State private var errorMessage: String?
    @State private var showingPaywall = false
    @State private var activeSheet: StudySheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(studySet.title).font(.largeTitle.bold())
                    Label(studySet.sourceName, systemImage: "doc.text")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("\(studySet.sourceText.count) caracteres · \(studySet.sourceType)")
                        .font(.caption).foregroundStyle(.tertiary)
                    if let warning = studySet.extractionWarning {
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                if studySet.hasSummary {
                    Button { activeSheet = .summary } label: {
                        FeatureRow(title: "Ver resumo", subtitle: "Principais ideias do material", icon: "text.alignleft", count: nil)
                    }.buttonStyle(.plain)
                }

                Button { Task { await generateSummary() } } label: {
                    FeatureRow(title: "Gerar resumo com IA", subtitle: "Sintetize as ideias principais", icon: "sparkles", count: nil)
                }
                .buttonStyle(.plain)

                Button { Task { await generateFlashcards() } } label: {
                    FeatureRow(title: "Criar flashcards", subtitle: "Perguntas e respostas para memorizar", icon: "rectangle.on.rectangle", count: studySet.flashcards.count)
                }
                .buttonStyle(.plain)

                Button { Task { await generateQuiz() } } label: {
                    FeatureRow(title: "Criar quiz", subtitle: "Teste seus conhecimentos", icon: "list.clipboard", count: studySet.quizQuestions.count)
                }
                .buttonStyle(.plain)

                if !studySet.flashcards.isEmpty {
                    Button { activeSheet = .flashcards } label: {
                        Label("Estudar flashcards", systemImage: "play.fill")
                            .frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent).tint(.indigo)
                }

                if !studySet.quizQuestions.isEmpty {
                    Button { activeSheet = .quiz } label: {
                        Label("Fazer quiz", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.bordered).tint(.indigo)
                }

                if isWorking {
                    ProgressView(progressText).frame(maxWidth: .infinity).padding()
                }
                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Conjunto de estudo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .summary:
                SummaryView(studySet: studySet)
            case .flashcards:
                FlashcardSessionView(cards: studySet.flashcards)
            case .quiz:
                QuizSessionView(questions: studySet.quizQuestions)
            }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private func allowedToRegenerate(existing: Bool) -> Bool {
        subscriptions.isPro || !existing
    }

    private func generateSummary() async {
        guard allowedToRegenerate(existing: studySet.hasSummary) else {
            showingPaywall = true
            return
        }
        await runAI("Gerando resumo…") {
            let result = try await ai.makeSummary(from: studySet.sourceText)
            studySet.summaryTitle = result.title
            studySet.summaryOverview = result.overview
            studySet.summaryKeyPoints = result.keyPoints
            studySet.updatedAt = .now
            try modelContext.save()
            activeSheet = .summary
        }
    }

    private func generateFlashcards() async {
        guard allowedToRegenerate(existing: !studySet.flashcards.isEmpty) else {
            showingPaywall = true
            return
        }
        await runAI("Criando flashcards…") {
            let limit = subscriptions.isPro ? 30 : 10
            let results = try await ai.makeFlashcards(from: studySet.sourceText, limit: limit)
            for (draft, excerpt) in results {
                let card = Flashcard(
                    question: draft.question,
                    answer: draft.answer,
                    topic: draft.topic,
                    sourceExcerpt: excerpt
                )
                card.studySet = studySet
                modelContext.insert(card)
            }
            studySet.updatedAt = .now
            try modelContext.save()
        }
    }

    private func generateQuiz() async {
        guard allowedToRegenerate(existing: !studySet.quizQuestions.isEmpty) else {
            showingPaywall = true
            return
        }
        await runAI("Criando quiz…") {
            let limit = subscriptions.isPro ? 15 : 5
            let results = try await ai.makeQuiz(from: studySet.sourceText, limit: limit)
            for (draft, excerpt) in results {
                let question = QuizQuestion(
                    prompt: draft.question,
                    options: [draft.optionA, draft.optionB, draft.optionC, draft.optionD],
                    correctOptionIndex: draft.correctOptionIndex,
                    explanation: draft.explanation,
                    topic: draft.topic,
                    sourceExcerpt: excerpt
                )
                question.studySet = studySet
                modelContext.insert(question)
            }
            studySet.updatedAt = .now
            try modelContext.save()
        }
    }

    private func runAI(_ message: String, operation: () async throws -> Void) async {
        isWorking = true
        progressText = message
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FeatureRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let count: Int?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2).foregroundStyle(.indigo)
                .frame(width: 48, height: 48)
                .background(.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let count {
                Text("\(count)").font(.subheadline.bold()).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 17))
    }
}

struct SummaryView: View {
    let studySet: StudySet

    var body: some View {
        NavigationStack {
            List {
                Section(studySet.summaryTitle) {
                    Text(studySet.summaryOverview)
                }
                Section("Pontos principais") {
                    ForEach(Array(studySet.summaryKeyPoints.enumerated()), id: \.offset) { _, point in
                        Label(point, systemImage: "checkmark.circle")
                    }
                }
            }
            .navigationTitle("Resumo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
