import SwiftUI
import SwiftData

@main
struct Note2ExamApp: App {
    @StateObject private var subscriptions = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(subscriptions)
                .environment(\.locale, Locale(identifier: "pt_BR"))
        }
        .modelContainer(for: [StudySet.self, Flashcard.self, QuizQuestion.self])
    }
}
