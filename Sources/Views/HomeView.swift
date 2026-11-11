import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \StudySet.updatedAt, order: .reverse) private var studySets: [StudySet]
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @State private var showingImport = false
    @State private var showingPaywall = false

    private var dueCount: Int {
        studySets.flatMap(\.flashcards).filter { $0.dueAt <= .now }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Olá! 👋")
                            .font(.largeTitle.bold())
                        Text("Transforme suas anotações em conhecimento.")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if !subscriptions.isPro && studySets.count >= 2 {
                            showingPaywall = true
                        } else {
                            showingImport = true
                        }
                    } label: {
                        Label("Criar conjunto de estudo", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    HStack(spacing: 12) {
                        MetricCard(title: "Conjuntos", value: "\(studySets.count)", icon: "books.vertical")
                        MetricCard(title: "Para revisar", value: "\(dueCount)", icon: "repeat")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recentes").font(.title2.bold())
                            Spacer()
                            NavigationLink("Ver todos") { LibraryView() }
                                .font(.subheadline)
                        }

                        if studySets.isEmpty {
                            ContentUnavailableView(
                                "Sua biblioteca está vazia",
                                systemImage: "book.closed",
                                description: Text("Importe um PDF, uma imagem ou cole suas anotações para começar.")
                            )
                        } else {
                            ForEach(Array(studySets.prefix(4))) { set in
                                NavigationLink {
                                    StudySetDetailView(studySet: set)
                                } label: {
                                    StudySetRow(studySet: set)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Note2Exam")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingImport = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingImport) { NewStudySetView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundStyle(.indigo)
            Text(value).font(.largeTitle.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct StudySetRow: View {
    let studySet: StudySet

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 48, height: 48)
                .background(.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(studySet.title).font(.headline).foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(studySet.flashcards.count) flashcards · \(studySet.quizQuestions.count) questões")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 17))
    }
}
