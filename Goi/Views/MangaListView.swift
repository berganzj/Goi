import SwiftUI

struct MangaListView: View {
    @EnvironmentObject var dictionaryManager: DictionaryManager
    @State private var showingAddManga = false
    @State private var searchText = ""
    
    private var filteredManga: [MangaBook] {
        if searchText.isEmpty {
            return dictionaryManager.mangaBooks.sorted { $0.dateAdded > $1.dateAdded }
        } else {
            return dictionaryManager.mangaBooks.filter { manga in
                manga.title.localizedCaseInsensitiveContains(searchText) ||
                (manga.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search manga...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Manga list
                List {
                    ForEach(filteredManga) { manga in
                        NavigationLink(destination: MangaDetailView(manga: manga)) {
                            MangaRowView(manga: manga, dictionaryManager: dictionaryManager)
                        }
                    }
                    .onDelete(perform: deleteManga)
                }
            }
            .navigationTitle("Manga Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddManga = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddManga) {
                AddMangaView()
            }
        }
    }
    
    private func deleteManga(at offsets: IndexSet) {
        for index in offsets {
            dictionaryManager.deleteMangaBook(filteredManga[index])
        }
    }
}

struct MangaRowView: View {
    let manga: MangaBook
    let dictionaryManager: DictionaryManager
    
    private var vocabularyCount: Int {
        manga.vocabularyEntries.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                if let volume = manga.volume {
                    Text("Vol. \(volume)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if let author = manga.author {
                Text("by \(author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(vocabularyCount) vocabulary words")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let chapter = manga.chapter {
                    Text("Ch. \(chapter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !manga.notes.isEmpty {
                Text(manga.notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddMangaView: View {
    @EnvironmentObject var dictionaryManager: DictionaryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var volume = ""
    @State private var chapter = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Manga Details") {
                    TextField("Title", text: $title)
                    TextField("Author (optional)", text: $author)
                }
                
                Section("Volume/Chapter") {
                    TextField("Volume number", text: $volume)
                        .keyboardType(.numberPad)
                    TextField("Chapter", text: $chapter)
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Manga")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveManga()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveManga() {
        let volumeInt = Int(volume)
        let newManga = MangaBook(
            title: title,
            author: author.isEmpty ? nil : author,
            volume: volumeInt,
            chapter: chapter.isEmpty ? nil : chapter,
            notes: notes
        )
        dictionaryManager.addMangaBook(newManga)
        dismiss()
    }
}

struct MangaDetailView: View {
    let manga: MangaBook
    @EnvironmentObject var dictionaryManager: DictionaryManager
    @State private var searchText = ""
    
    private var vocabularyEntries: [JapaneseEntry] {
        dictionaryManager.allEntries.filter { entry in
            manga.vocabularyEntries.contains(entry.id)
        }
    }
    
    private var filteredVocabulary: [JapaneseEntry] {
        if searchText.isEmpty {
            return vocabularyEntries
        } else {
            return vocabularyEntries.filter { entry in
                entry.word.localizedCaseInsensitiveContains(searchText) ||
                entry.romaji.localizedCaseInsensitiveContains(searchText) ||
                entry.meanings.joined().localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Manga info header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(manga.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if let volume = manga.volume {
                        Text("Vol. \(volume)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                if let author = manga.author {
                    Text("by \(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(vocabularyEntries.count) vocabulary words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let chapter = manga.chapter {
                        Text("Chapter \(chapter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            // Search vocabulary
            TextField("Search vocabulary in this manga...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Vocabulary list
            List {
                ForEach(filteredVocabulary) { entry in
                    NavigationLink(destination: VocabularyDetailView(entry: entry)) {
                        VocabularyEntryRowView(entry: entry)
                    }
                }
            }
        }
        .navigationTitle("Manga Vocabulary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        MangaListView()
            .environmentObject(DictionaryManager())
    }
}