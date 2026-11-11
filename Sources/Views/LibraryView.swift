import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \StudySet.updatedAt, order: .reverse) private var studySets: [StudySet]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @State private var showingImport = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if studySets.isEmpty {
                    ContentUnavailableView(
                        "Nenhum material ainda",
                        systemImage: "books.vertical",
                        description: Text("Seus conjuntos de estudo aparecerão aqui.")
                    )
                } else {
                    List {
                        ForEach(studySets) { set in
                            NavigationLink {
                                StudySetDetailView(studySet: set)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(set.title).font(.headline)
                                    Text(set.sourceName).font(.caption).foregroundStyle(.secondary)
                                    Text("\(set.flashcards.count) cards · \(set.quizQuestions.count) questões")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteSets)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Biblioteca")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { createAction() } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !studySets.isEmpty { EditButton() }
                }
            }
            .sheet(isPresented: $showingImport) { NewStudySetView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private func createAction() {
        if !subscriptions.isPro && studySets.count >= 2 {
            showingPaywall = true
        } else {
            showingImport = true
        }
    }

    private func deleteSets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(studySets[index])
        }
        try? modelContext.save()
    }
}
