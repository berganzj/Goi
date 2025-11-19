import Foundation

// MARK: - Japanese Vocabulary Entry
struct JapaneseEntry: Identifiable, Codable {
    var id = UUID()
    let word: String
    let hiragana: String?
    let katakana: String?
    let romaji: String
    let meanings: [String]
    let partOfSpeech: [String]
    let jlptLevel: JLPTLevel?
    let frequency: Int?
    let kanji: String?
    
    // Helper computed properties
    var primaryKana: String {
        hiragana ?? katakana ?? romaji
    }
    
    var displayWord: String {
        kanji ?? word
    }
}

// MARK: - JLPT Levels
enum JLPTLevel: String, CaseIterable, Codable {
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    
    var color: String {
        switch self {
        case .n5: return "green"
        case .n4: return "blue"
        case .n3: return "yellow"
        case .n2: return "orange"
        case .n1: return "red"
        }
    }
}

// MARK: - Manga Book
struct MangaBook: Identifiable, Codable {
    var id = UUID()
    var title: String
    var author: String?
    var volume: Int?
    var chapter: String?
    var vocabularyEntries: [UUID] // References to JapaneseEntry IDs
    var dateAdded: Date
    var coverImageData: Data?
    var notes: String
    
    init(title: String, author: String? = nil, volume: Int? = nil, chapter: String? = nil, notes: String = "") {
        self.title = title
        self.author = author
        self.volume = volume
        self.chapter = chapter
        self.vocabularyEntries = []
        self.dateAdded = Date()
        self.notes = notes
    }
}

// MARK: - Search/Input Type
enum InputType: CaseIterable {
    case romaji
    case hiragana
    case katakana
    
    var displayName: String {
        switch self {
        case .romaji: return "Romaji"
        case .hiragana: return "ひらがな"
        case .katakana: return "カタカナ"
        }
    }
    
    var keyboardType: KanaKeyboardType {
        switch self {
        case .romaji: return .romaji
        case .hiragana: return .hiragana
        case .katakana: return .katakana
        }
    }
}

// MARK: - Keyboard Type
enum KanaKeyboardType {
    case romaji
    case hiragana
    case katakana
}

// MARK: - Dictionary Manager
class DictionaryManager: ObservableObject {
    @Published var allEntries: [JapaneseEntry] = []
    @Published var mangaBooks: [MangaBook] = []
    @Published var searchResults: [JapaneseEntry] = []
    @Published var isLoading = false
    
    private let entriesKey = "japanese_entries"
    private let mangaBooksKey = "manga_books"
    
    init() {
        loadData()
        loadSampleData() // For development
    }
    
    // MARK: - Data Persistence
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(allEntries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    private func saveMangaBooks() {
        if let data = try? JSONEncoder().encode(mangaBooks) {
            UserDefaults.standard.set(data, forKey: mangaBooksKey)
        }
    }
    
    private func loadData() {
        // Load entries
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let entries = try? JSONDecoder().decode([JapaneseEntry].self, from: data) {
            allEntries = entries
        }
        
        // Load manga books
        if let data = UserDefaults.standard.data(forKey: mangaBooksKey),
           let books = try? JSONDecoder().decode([MangaBook].self, from: data) {
            mangaBooks = books
        }
    }
    
    // MARK: - Search Functions
    func search(_ query: String, inputType: InputType) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let lowercaseQuery = query.lowercased()
        
        searchResults = allEntries.filter { entry in
            switch inputType {
            case .romaji:
                return entry.romaji.lowercased().contains(lowercaseQuery)
            case .hiragana:
                return entry.hiragana?.contains(query) == true ||
                       entry.word.contains(query)
            case .katakana:
                return entry.katakana?.contains(query) == true ||
                       entry.word.contains(query)
            }
        }
    }
    
    func searchInManga(_ mangaId: UUID, query: String) -> [JapaneseEntry] {
        guard let manga = mangaBooks.first(where: { $0.id == mangaId }) else { return [] }
        
        let mangaEntries = allEntries.filter { entry in
            manga.vocabularyEntries.contains(entry.id)
        }
        
        return mangaEntries.filter { entry in
            entry.word.lowercased().contains(query.lowercased()) ||
            entry.romaji.lowercased().contains(query.lowercased()) ||
            entry.meanings.joined().lowercased().contains(query.lowercased())
        }
    }
    
    // MARK: - Manga Management
    func addMangaBook(_ book: MangaBook) {
        mangaBooks.append(book)
        saveMangaBooks()
    }
    
    func updateMangaBook(_ book: MangaBook) {
        if let index = mangaBooks.firstIndex(where: { $0.id == book.id }) {
            mangaBooks[index] = book
            saveMangaBooks()
        }
    }
    
    func deleteMangaBook(_ book: MangaBook) {
        mangaBooks.removeAll { $0.id == book.id }
        saveMangaBooks()
    }
    
    func addEntryToManga(_ entryId: UUID, mangaId: UUID) {
        if let index = mangaBooks.firstIndex(where: { $0.id == mangaId }) {
            if !mangaBooks[index].vocabularyEntries.contains(entryId) {
                mangaBooks[index].vocabularyEntries.append(entryId)
                saveMangaBooks()
            }
        }
    }
    
    // MARK: - Sample Data
    private func loadSampleData() {
        if allEntries.isEmpty {
            allEntries = [
                JapaneseEntry(
                    word: "こんにちは",
                    hiragana: "こんにちは",
                    katakana: nil,
                    romaji: "konnichiwa",
                    meanings: ["hello", "good afternoon"],
                    partOfSpeech: ["greeting"],
                    jlptLevel: .n5,
                    frequency: 100
                ),
                JapaneseEntry(
                    word: "ありがとう",
                    hiragana: "ありがとう",
                    katakana: nil,
                    romaji: "arigatou",
                    meanings: ["thank you"],
                    partOfSpeech: ["expression"],
                    jlptLevel: .n5,
                    frequency: 95
                ),
                JapaneseEntry(
                    word: "コーヒー",
                    hiragana: nil,
                    katakana: "コーヒー",
                    romaji: "koohii",
                    meanings: ["coffee"],
                    partOfSpeech: ["noun"],
                    jlptLevel: .n5,
                    frequency: 80
                ),
                JapaneseEntry(
                    word: "学校",
                    hiragana: "がっこう",
                    katakana: nil,
                    romaji: "gakkou",
                    meanings: ["school"],
                    partOfSpeech: ["noun"],
                    jlptLevel: .n5,
                    frequency: 90,
                    kanji: "学校"
                )
            ]
        }
        
        if mangaBooks.isEmpty {
            let sampleManga = MangaBook(
                title: "ワンピース", 
                author: "尾田栄一郎",
                volume: 1,
                chapter: "1",
                notes: "Adventure manga"
            )
            mangaBooks = [sampleManga]
        }
    }
}