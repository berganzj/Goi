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
                    // Search bar with glass effect
                    HStack(spacing: 12) {
                        TextField("Search vocabulary...", text: $searchText)
                            .glassTextField()
                        
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: "line.horizontal.3.decrease.circle.fill")
                                .font(.title2)
                                .foregroundColor(selectedLevel != nil ? .blue : .gray)
                                .frame(width: 50, height: 50)
                                .glassCard(cornerRadius: 12)
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
                    if filteredEntries.isEmpty && searchText.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            
                            GlassContainer(cornerRadius: 24, padding: 32) {
                                VStack(spacing: 20) {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 60))
                                        .foregroundColor(.purple.opacity(0.6))
                                    
                                    VStack(spacing: 12) {
                                        Text("Start Building Your Vocabulary!")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text("Add your first Japanese word using the \"Add Word\" tab below")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding()
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredEntries) { entry in
                                    NavigationLink(destination: VocabularyDetailView(entry: entry)) {
                                        VocabularyEntryRowView(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive, action: {
                                            vocabularyManager.deleteEntry(entry)
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding()
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
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(.semibold)
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Main word display
                    GlassContainer(cornerRadius: 20, padding: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(entry.displayWord)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                if let level = entry.jlptLevel {
                                    Text(level.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.purple],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                        .foregroundColor(.white)
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
                    }
                    
                    // Meanings
                    GlassContainer(cornerRadius: 16, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meanings")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(entry.meanings.enumerated()), id: \.offset) { index, meaning in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    Text(meaning)
                                        .font(.body)
                                }
                            }
                        }
                    }
                    
                    // Parts of speech
                    if !entry.partOfSpeech.isEmpty {
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Part of Speech")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(entry.partOfSpeech.joined(separator: ", "))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Source information
                    if let source = entry.source {
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundColor(.blue)
                                    Text("Source")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(source)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Date added
                    GlassContainer(cornerRadius: 16, padding: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text("Added: \(entry.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
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