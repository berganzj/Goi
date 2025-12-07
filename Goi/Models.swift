import Foundation

// MARK: - Vocabulary Entry
struct VocabularyEntry: Identifiable, Codable {
    var id = UUID()
    let word: String
    let hiragana: String?
    let katakana: String?
    let romaji: String
    let meanings: [String]
    let partOfSpeech: [String]
    let jlptLevel: JLPTLevel?
    let source: String? // Optional source like "Manga: One Piece Ch.1"
    let dateAdded: Date
    
    // Helper computed properties
    var primaryKana: String {
        hiragana ?? katakana ?? romaji
    }
    
    var displayWord: String {
        word
    }
    
    init(word: String, hiragana: String? = nil, katakana: String? = nil, romaji: String, meanings: [String], partOfSpeech: [String] = [], jlptLevel: JLPTLevel? = nil, source: String? = nil) {
        self.id = UUID()
        self.word = word
        self.hiragana = hiragana
        self.katakana = katakana
        self.romaji = romaji
        self.meanings = meanings
        self.partOfSpeech = partOfSpeech
        self.jlptLevel = jlptLevel
        self.source = source
        self.dateAdded = Date()
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

// MARK: - Vocabulary Manager
class VocabularyManager: ObservableObject {
    @Published var vocabularyEntries: [VocabularyEntry] = []
    @Published var searchResults: [VocabularyEntry] = []
    @Published var isLoading = false
    
    private let entriesKey = "vocabulary_entries"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(vocabularyEntries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let entries = try? JSONDecoder().decode([VocabularyEntry].self, from: data) {
            vocabularyEntries = entries
        }
    }
    
    // MARK: - Vocabulary Management
    func addEntry(_ entry: VocabularyEntry) -> Bool {
        // Check for duplicates
        if hasDuplicate(entry) {
            return false
        }
        vocabularyEntries.append(entry)
        saveEntries()
        return true
    }
    
    func hasDuplicate(_ entry: VocabularyEntry) -> Bool {
        return vocabularyEntries.contains { existingEntry in
            // Check if word, romaji, or kana matches
            existingEntry.word.lowercased() == entry.word.lowercased() ||
            existingEntry.romaji.lowercased() == entry.romaji.lowercased() ||
            (existingEntry.hiragana != nil && entry.hiragana != nil && 
             existingEntry.hiragana!.lowercased() == entry.hiragana!.lowercased()) ||
            (existingEntry.katakana != nil && entry.katakana != nil && 
             existingEntry.katakana!.lowercased() == entry.katakana!.lowercased())
        }
    }
    
    func updateEntry(_ entry: VocabularyEntry) {
        if let index = vocabularyEntries.firstIndex(where: { $0.id == entry.id }) {
            vocabularyEntries[index] = entry
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: VocabularyEntry) {
        vocabularyEntries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    // MARK: - Search Functions
    func search(_ query: String, inputType: InputType) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let lowercaseQuery = query.lowercased()
        
        searchResults = vocabularyEntries.filter { entry in
            switch inputType {
            case .romaji:
                return entry.romaji.lowercased().contains(lowercaseQuery) ||
                       entry.meanings.joined().lowercased().contains(lowercaseQuery)
            case .hiragana:
                return entry.hiragana?.contains(query) == true ||
                       entry.word.contains(query)
            case .katakana:
                return entry.katakana?.contains(query) == true ||
                       entry.word.contains(query)
            }
        }.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    func searchBySource(_ source: String) -> [VocabularyEntry] {
        return vocabularyEntries.filter { entry in
            entry.source?.lowercased().contains(source.lowercased()) == true
        }.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    func getAllEntries() -> [VocabularyEntry] {
        return vocabularyEntries.sorted { $0.dateAdded > $1.dateAdded }
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
