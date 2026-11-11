import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptions: SubscriptionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)

                VStack(spacing: 8) {
                    Text("Desbloqueie o Note2Exam Pro")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Crie mais materiais de estudo, gere quizzes maiores e acompanhe seus pontos fracos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Mais conjuntos de estudo", systemImage: "books.vertical")
                    Label("Até 30 flashcards por geração", systemImage: "rectangle.on.rectangle")
                    Label("Quizzes com até 15 questões", systemImage: "list.clipboard")
                    Label("Insights de revisão", systemImage: "chart.bar")
                    Label("Sem anúncios", systemImage: "nosign")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                if subscriptions.products.isEmpty {
                    ProgressView("Carregando planos…")
                        .task { await subscriptions.loadProducts() }
                } else {
                    ForEach(subscriptions.products, id: \.id) { product in
                        Button {
                            Task { await subscriptions.purchase(product) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(product.id == SubscriptionManager.yearlyID ? "Anual" : "Mensal")
                                        .font(.headline)
                                    Text(product.id == SubscriptionManager.yearlyID ? "Melhor valor" : "Cobrado mensalmente")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(product.displayPrice)
                                    .font(.headline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(subscriptions.isLoading)
                    }
                }

                if subscriptions.isLoading {
                    ProgressView()
                }

                Button("Restaurar compras") {
                    Task { await subscriptions.restorePurchases() }
                }
                .font(.subheadline)

                if let message = subscriptions.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("A assinatura é renovada automaticamente até ser cancelada nas configurações da sua conta Apple. Adicione os links publicados de Termos de Uso e Política de Privacidade antes do lançamento.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Note2Exam Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
