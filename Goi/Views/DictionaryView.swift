import SwiftUI

// Note: This view is kept for backward compatibility but not used in the main app
// The main vocabulary functionality is now in VocabularyListView
struct DictionaryView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var searchText = ""
    @State private var selectedLevel: JLPTLevel?
    @State private var showingFilters = false
    
    private var filteredEntries: [VocabularyEntry] {
        let entries = searchText.isEmpty ? vocabularyManager.getAllEntries() : 
            vocabularyManager.getAllEntries().filter { entry in
                entry.word.localizedCaseInsensitiveContains(searchText) ||
                entry.romaji.localizedCaseInsensitiveContains(searchText) ||
                entry.meanings.joined().localizedCaseInsensitiveContains(searchText) ||
                (entry.hiragana?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.katakana?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        
        if let level = selectedLevel {
            return entries.filter { $0.jlptLevel == level }
        }
        
        return entries
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search dictionary...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(selectedLevel != nil ? .blue : .gray)
                    }
                }
                .padding(.horizontal)
                
                // Filter pills
                if selectedLevel != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button(action: { selectedLevel = nil }) {
                                HStack(spacing: 4) {
                                    Text(selectedLevel!.rawValue)
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Dictionary entries list
                List {
                    Section {
                        ForEach(filteredEntries) { entry in
                            VocabularyEntryRowView(entry: entry)
                        }
                    } header: {
                        if !searchText.isEmpty {
                            Text("\(filteredEntries.count) results")
                        } else {
                            Text("All Dictionary Entries (\(filteredEntries.count))")
                        }
                    }
                }
            }
            .navigationTitle("Dictionary")
            .sheet(isPresented: $showingFilters) {
                NavigationView {
                    List {
                        Section("JLPT Level") {
                            ForEach(JLPTLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    selectedLevel = level
                                    showingFilters = false
                                }) {
                                    HStack {
                                        Text(level.rawValue)
                                        Spacer()
                                        if selectedLevel == level {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                            
                            Button("Clear Filter") {
                                selectedLevel = nil
                                showingFilters = false
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .navigationTitle("Filters")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFilters = false
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DictionaryView()
            .environmentObject(VocabularyManager())
    }
}