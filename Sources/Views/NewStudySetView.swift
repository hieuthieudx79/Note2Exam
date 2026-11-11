import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct NewStudySetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @Query private var studySets: [StudySet]

    @State private var title = ""
    @State private var sourceText = ""
    @State private var sourceName = "Anotações coladas"
    @State private var sourceType = "Text"
    @State private var warning: String?
    @State private var errorMessage: String?
    @State private var showingImporter = false
    @State private var showingPaywall = false
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Material de estudo") {
                    TextField("Nome do conjunto", text: $title)
                    Text("Importe um PDF ou imagem, ou cole suas anotações.")
                        .font(.footnote).foregroundStyle(.secondary)

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Importar PDF ou imagem", systemImage: "doc.badge.plus")
                    }
                    .disabled(isImporting)

                    TextEditor(text: $sourceText)
                        .frame(minHeight: 220)
                        .overlay(alignment: .topLeading) {
                            if sourceText.isEmpty {
                                Text("Cole aqui suas anotações…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }

                    if !sourceName.isEmpty {
                        Label(sourceName, systemImage: "doc.text")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let warning {
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        saveStudySet()
                    } label: {
                        if isImporting {
                            ProgressView()
                        } else {
                            Text("Salvar conjunto de estudo")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                }
            }
            .navigationTitle("Novo conjunto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                importSelection(result)
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private func importSelection(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            isImporting = true
            defer { isImporting = false }

            let imported: ImportedStudySource
            if url.pathExtension.lowercased() == "pdf" {
                imported = try DocumentImportService.readPDF(at: url)
            } else {
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess { url.stopAccessingSecurityScopedResource() }
                }
                let data = try Data(contentsOf: url)
                imported = try DocumentImportService.readImage(data: data, name: url.lastPathComponent)
            }

            sourceText = imported.text
            sourceName = imported.name
            sourceType = imported.type
            warning = imported.warning
            if title.isEmpty {
                title = URL(fileURLWithPath: imported.name).deletingPathExtension().lastPathComponent
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveStudySet() {
        guard subscriptions.isPro || studySets.count < 2 else {
            showingPaywall = true
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let studySet = StudySet(
            title: cleanTitle.isEmpty ? "Novo conjunto" : cleanTitle,
            sourceName: sourceName,
            sourceType: sourceType,
            sourceText: cleanText,
            extractionWarning: warning
        )
        modelContext.insert(studySet)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Não foi possível salvar: \(error.localizedDescription)"
        }
    }
}
