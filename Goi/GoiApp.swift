import SwiftUI

@main
struct GoiApp: App {
    @StateObject private var vocabularyManager = VocabularyManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(vocabularyManager)
        }
    }
}