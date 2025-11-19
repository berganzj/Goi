import SwiftUI

// NOTE: This view is not used in the app - MainTabView is the main interface
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "book.japanese")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Goi - Japanese Dictionary")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
