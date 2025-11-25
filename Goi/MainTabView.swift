import SwiftUI

// Import view files that aren't automatically found
struct VocabularyListView_Dummy { } // Placeholder
struct AddVocabularyView_Dummy { }   // Placeholder

struct MainTabView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    
    var body: some View {
        TabView {
            Text("Vocabulary List - Add files to Xcode")
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("My Words")
                }
            
            Text("Add Vocabulary - Add files to Xcode")
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Add Word")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }
        .environmentObject(vocabularyManager)
    }
}

struct SearchView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
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
                            vocabularyManager.search(newValue, inputType: inputType)
                        }
                    
                    if inputType != .romaji {
                        Button("⌨️") {
                            showingCustomKeyboard = true
                        }
                    }
                }
                .padding(.horizontal)
                
                // Results
                List(vocabularyManager.searchResults) { entry in
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
    let entry: VocabularyEntry
    
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
            
            if let source = entry.source {
                Text("Source: \(source)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MainTabView()
        .environmentObject(VocabularyManager())
}