import SwiftUI

@main
struct GoiApp: App {
    @StateObject private var dictionaryManager = DictionaryManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dictionaryManager)
        }
    }
}