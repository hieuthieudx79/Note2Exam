import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section("Assinatura") {
                    HStack {
                        Label("Note2Exam Pro", systemImage: "sparkles")
                        Spacer()
                        Text(subscriptions.isPro ? "Ativo" : "Free")
                            .foregroundStyle(subscriptions.isPro ? .green : .secondary)
                    }
                    if !subscriptions.isPro {
                        Button("Conhecer o Pro") { showingPaywall = true }
                    }
                    Button("Restaurar compras") {
                        Task { await subscriptions.restorePurchases() }
                    }
                    if let message = subscriptions.message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("Privacidade") {
                    Label("Processamento de IA no dispositivo", systemImage: "iphone.gen3")
                    Text("Seus documentos e materiais de estudo permanecem armazenados localmente nesta versão.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Sobre") {
                    LabeledContent("Versão", value: "1.0 MVP")
                    LabeledContent("Mercado inicial", value: "Brasil")
                }
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }
}
