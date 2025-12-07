import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    
    var body: some View {
        TabView {
            VocabularyListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("My Words")
                }
            
            AddVocabularyView()
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
    @StateObject private var dictionaryService = JMDictService()
    @State private var searchText = ""
    @State private var inputType: InputType = .romaji
    @State private var showingCustomKeyboard = false
    @State private var dictionaryResults: [JapaneseEntry] = []
    
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
                    TextField("Search dictionary for \(inputType.displayName.lowercased())...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            searchDictionary(newValue)
                        }
                    
                    if inputType != .romaji {
                        Button("⌨️") {
                            showingCustomKeyboard = true
                        }
                    }
                }
                .padding(.horizontal)
                
                // Results
                if dictionaryResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No results found for \"\(searchText)\"")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else if dictionaryResults.isEmpty && searchText.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Search for Japanese words")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("Try searching for 'hello', 'no', or 'yes'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else {
                    List(dictionaryResults) { entry in
                        DictionaryEntryRowView(entry: entry, vocabularyManager: vocabularyManager)
                    }
                }
            }
            .navigationTitle("Dictionary Search")
            .sheet(isPresented: $showingCustomKeyboard) {
                KanaKeyboardView(
                    text: $searchText,
                    keyboardType: inputType.keyboardType,
                    isPresented: $showingCustomKeyboard
                )
            }
        }
    }
    
    private func searchDictionary(_ query: String) {
        guard !query.isEmpty else {
            dictionaryResults = []
            return
        }
        
        dictionaryService.searchWord(query) { results in
            DispatchQueue.main.async {
                self.dictionaryResults = results
            }
        }
    }
}

struct DictionaryEntryRowView: View {
    let entry: JapaneseEntry
    let vocabularyManager: VocabularyManager
    @State private var isAdded = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.word)
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
                
                if let hiragana = entry.hiragana {
                    Text(hiragana)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.romaji)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.meanings.joined(separator: ", "))
                    .font(.body)
            }
            
            Spacer()
            
            Button(action: {
                addToVocabulary()
            }) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundColor(isAdded ? .green : .blue)
            }
            .disabled(isAdded)
        }
        .padding(.vertical, 2)
    }
    
    private func addToVocabulary() {
        let vocabularyEntry = VocabularyEntry(
            word: entry.word,
            hiragana: entry.hiragana,
            katakana: entry.katakana,
            romaji: entry.romaji,
            meanings: entry.meanings,
            partOfSpeech: entry.partOfSpeech,
            jlptLevel: entry.jlptLevel
        )
        
        let success = vocabularyManager.addEntry(vocabularyEntry)
        if success {
            withAnimation {
                isAdded = true
            }
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isAdded = false
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