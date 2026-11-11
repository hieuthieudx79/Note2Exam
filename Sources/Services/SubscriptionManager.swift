import Foundation
import Combine
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyID = "com.note2exam.pro.monthly"
    static let yearlyID = "com.note2exam.pro.yearly"
    static let productIDs: Set<String> = [monthlyID, yearlyID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published var message: String?
    @Published var isLoading = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await observeTransactions() }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs).sorted {
                if $0.id == Self.yearlyID { return true }
                if $1.id == Self.yearlyID { return false }
                return $0.id < $1.id
            }
        } catch {
            message = "Não foi possível carregar os planos. Tente novamente mais tarde."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = "Não foi possível verificar a compra com a App Store."
                    return
                }
                await transaction.finish()
                await refreshEntitlements()
                message = isPro ? "Note2Exam Pro está ativo." : nil
            case .pending:
                message = "A compra está aguardando aprovação."
            case .userCancelled:
                break
            @unknown default:
                message = "Status de compra não reconhecido."
            }
        } catch {
            message = "A compra não foi concluída: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = isPro
                ? "Suas compras foram restauradas."
                : "Nenhuma assinatura Pro ativa foi encontrada."
        } catch {
            message = "Não foi possível restaurar as compras: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasPro = true
            }
        }
        isPro = hasPro
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }
}
