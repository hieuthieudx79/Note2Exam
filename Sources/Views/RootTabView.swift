import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Início", systemImage: "house") }

            LibraryView()
                .tabItem { Label("Biblioteca", systemImage: "books.vertical") }

            ReviewView()
                .tabItem { Label("Revisar", systemImage: "repeat") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(.indigo)
    }
}
