import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dictionaryManager: DictionaryManager
    
    var body: some View {
        TabView {
            DictionaryView()
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Dictionary")
                }
            
            MangaListView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Manga")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }
        .environmentObject(dictionaryManager)
    }
}

struct SearchView: View {
    @EnvironmentObject var dictionaryManager: DictionaryManager
    @State private var searchText = ""
    @State private var inputType: InputType = .romaji
    @State private var showingCustomKeyboard = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Input type selector
                Picker("Input Type", selection: $inputType) {
                    ForEach(InputType.allCases, id: \.self) { type in
                        Text(type.displayName)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search input
                HStack {
                    TextField("Search in \(inputType.displayName)...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            dictionaryManager.search(newValue, inputType: inputType)
                        }
                    
                    if inputType != .romaji {
                        Button("⌨️") {
                            showingCustomKeyboard = true
                        }
                    }
                }
                .padding(.horizontal)
                
                // Results
                List(dictionaryManager.searchResults) { entry in
                    VocabularyEntryRowView(entry: entry)
                }
            }
            .navigationTitle("Search")
            .sheet(isPresented: $showingCustomKeyboard) {
                KanaKeyboardView(
                    text: $searchText,
                    keyboardType: inputType.keyboardType,
                    isPresented: $showingCustomKeyboard
                )
            }
        }
    }
}

struct VocabularyEntryRowView: View {
    let entry: JapaneseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.displayWord)
                    .font(.headline)
                
                if let level = entry.jlptLevel {
                    Text(level.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            Text(entry.primaryKana)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(entry.romaji)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(entry.meanings.joined(separator: ", "))
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MainTabView()
        .environmentObject(DictionaryManager())
}