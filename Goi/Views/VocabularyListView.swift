import SwiftUI

struct VocabularyListView: View {
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
                (entry.katakana?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.source?.localizedCaseInsensitiveContains(searchText) ?? false)
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
                    TextField("Search vocabulary...", text: $searchText)
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
                            FilterPill(title: selectedLevel!.rawValue, isSelected: true) {
                                selectedLevel = nil
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Vocabulary entries list
                List {
                    Section {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: VocabularyDetailView(entry: entry)) {
                                VocabularyEntryRowView(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    } header: {
                        if !searchText.isEmpty {
                            Text("\(filteredEntries.count) results")
                        } else {
                            Text("My Vocabulary (\(filteredEntries.count))")
                        }
                    }
                }
            }
            .navigationTitle("My Words")
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedLevel: $selectedLevel)
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            vocabularyManager.deleteEntry(filteredEntries[index])
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct FilterView: View {
    @Binding var selectedLevel: JLPTLevel?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("JLPT Level") {
                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                        Button(action: {
                            selectedLevel = level
                            dismiss()
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
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VocabularyDetailView: View {
    let entry: VocabularyEntry
    @EnvironmentObject var vocabularyManager: VocabularyManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Main word display
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.displayWord)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let level = entry.jlptLevel {
                            Text(level.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    if let hiragana = entry.hiragana {
                        Text("Hiragana: \(hiragana)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let katakana = entry.katakana {
                        Text("Katakana: \(katakana)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Romaji: \(entry.romaji)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Meanings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meanings")
                        .font(.headline)
                    
                    ForEach(Array(entry.meanings.enumerated()), id: \.offset) { index, meaning in
                        Text("\(index + 1). \(meaning)")
                            .font(.body)
                    }
                }
                
                Divider()
                
                // Parts of speech
                if !entry.partOfSpeech.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Part of Speech")
                            .font(.headline)
                        
                        Text(entry.partOfSpeech.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                }
                
                // Source information
                if let source = entry.source {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.headline)
                        
                        Text(source)
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                }
                
                // Date added
                VStack(alignment: .leading, spacing: 4) {
                    Text("Added: \(entry.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Word Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        VocabularyListView()
            .environmentObject(VocabularyManager())
    }
}