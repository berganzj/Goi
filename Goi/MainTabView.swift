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
    @State private var showingDownloadView = false
    @State private var dictionaryResults: [JapaneseEntry] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Input type selector with glass effect
                    GlassContainer(cornerRadius: 16, padding: 12) {
                        Picker("Input Type", selection: $inputType) {
                            ForEach(InputType.allCases, id: \.self) { type in
                                Text(type.displayName)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Search input with glass effect
                    HStack(spacing: 12) {
                        TextField("Search dictionary for \(inputType.displayName.lowercased())...", text: $searchText)
                            .glassTextField()
                            .onChange(of: searchText) { _, newValue in
                                searchDictionary(newValue)
                            }
                        
                        if inputType != .romaji {
                            Button(action: {
                                showingCustomKeyboard = true
                            }) {
                                Text("⌨️")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .glassCard(cornerRadius: 12)
                            }
                        }
                    }
                    .padding(.horizontal)
                
                    // Results
                    if dictionaryResults.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            GlassContainer(cornerRadius: 20, padding: 24) {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue.opacity(0.6))
                                    Text("No results found for \"\(searchText)\"")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            Spacer()
                        }
                    } else if dictionaryResults.isEmpty && searchText.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            GlassContainer(cornerRadius: 20, padding: 24) {
                                VStack(spacing: 16) {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 50))
                                        .foregroundColor(.purple.opacity(0.6))
                                    Text("Search for Japanese words")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Try searching for 'hello', 'no', or 'yes'")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(dictionaryResults) { entry in
                                    DictionaryEntryRowView(entry: entry, vocabularyManager: vocabularyManager)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            }
            .navigationTitle("Dictionary Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDownloadView = true
                    }) {
                        Image(systemName: dictionaryService.isJMDictLoaded ? "checkmark.circle.fill" : "arrow.down.circle")
                            .foregroundColor(dictionaryService.isJMDictLoaded ? .green : .blue)
                    }
                }
            }
            .sheet(isPresented: $showingCustomKeyboard) {
                KanaKeyboardView(
                    text: $searchText,
                    keyboardType: inputType.keyboardType,
                    isPresented: $showingCustomKeyboard
                )
            }
            .sheet(isPresented: $showingDownloadView) {
                JMDictDownloadView()
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
        GlassContainer(cornerRadius: 16, padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.word)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if let level = entry.jlptLevel {
                            Text(level.rawValue)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .foregroundColor(.primary)
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
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    addToVocabulary()
                }) {
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(isAdded ? .green : .blue)
                        .shadow(color: isAdded ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), radius: 8)
                }
                .disabled(isAdded)
            }
        }
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
        GlassContainer(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.displayWord)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let level = entry.jlptLevel {
                        Text(level.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.primary)
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
                    .foregroundColor(.primary)
                
                if let source = entry.source {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                        Text("Source: \(source)")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(VocabularyManager())
}