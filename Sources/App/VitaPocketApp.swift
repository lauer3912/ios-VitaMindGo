import SwiftUI

@main
struct VitaPocketApp: App {
    @StateObject private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .preferredColorScheme(.dark)
        }
    }
}