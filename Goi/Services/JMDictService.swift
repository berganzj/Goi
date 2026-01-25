import Foundation
import Combine

// MARK: - JMDICT Service
class JMDictService: ObservableObject {
    @Published var isLoading = false
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    @Published var error: JMDictError?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    private var downloadObservation: NSKeyValueObservation?
    
    // Core vocabulary loaded from bundled JSON
    private var coreVocabulary: [JapaneseEntry] = []
    
    // Full JMDict dictionary loaded from downloaded file
    private var jmdictEntries: [JapaneseEntry] = []
    private var jmdictLoaded = false
    
    // Cache for search results
    private var searchCache: [String: [JapaneseEntry]] = [:]
    
    // File paths
    private var jmdictFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("jmdict-eng.json")
    }
    
    init() {
        loadCoreVocabulary()
        loadJMDictFromFile()
    }
    
    
    // MARK: - Core Vocabulary Loading
    private func loadCoreVocabulary() {
        guard let url = Bundle.main.url(forResource: "CoreVocabulary", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load CoreVocabulary.json")
            return
        }
        
        do {
            struct VocabEntry: Codable {
                let word: String
                let hiragana: String?
                let katakana: String?
                let romaji: String
                let meanings: [String]
                let partOfSpeech: [String]
                let jlptLevel: String?
                let kanji: String?
            }
            
            let entries = try JSONDecoder().decode([VocabEntry].self, from: data)
            coreVocabulary = entries.map { entry in
                JapaneseEntry(
                    word: entry.word,
                    hiragana: entry.hiragana,
                    katakana: entry.katakana,
                    romaji: entry.romaji,
                    meanings: entry.meanings,
                    partOfSpeech: entry.partOfSpeech,
                    jlptLevel: JLPTLevel(rawValue: entry.jlptLevel ?? "N5"),
                    frequency: nil,
                    kanji: entry.kanji
                )
            }
            print("Loaded \(coreVocabulary.count) core vocabulary entries")
        } catch {
            print("Failed to decode CoreVocabulary.json: \(error)")
        }
    }
    
    func searchWord(_ query: String, completion: @escaping ([JapaneseEntry]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        isLoading = true
        error = nil
        
        // Check cache first
        let cacheKey = query.lowercased()
        if let cachedResults = searchCache[cacheKey] {
            isLoading = false
            completion(cachedResults)
            return
        }
        
        // Search in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var results: [JapaneseEntry] = []
            
            // First, search core vocabulary
            let coreResults = self.searchCoreVocabulary(query)
            results.append(contentsOf: coreResults)
            
            // Then search full JMDict if loaded
            if self.jmdictLoaded {
                let jmdictResults = self.searchJMDict(query)
                results.append(contentsOf: jmdictResults)
            }
            
            // Remove duplicates based on word/romaji combination and limit results
            var seen = Set<String>()
            let uniqueResults = results.filter { entry in
                let key = "\(entry.word.lowercased())-\(entry.romaji.lowercased())"
                if seen.contains(key) {
                    return false
                }
                seen.insert(key)
                return true
            }.prefix(100) // Limit to 100 results for performance
            
            let finalResults = Array(uniqueResults)
            
            // Cache results
            DispatchQueue.main.async {
                self.searchCache[cacheKey] = finalResults
                self.isLoading = false
                completion(finalResults)
            }
        }
    }
    
    private func searchCoreVocabulary(_ query: String) -> [JapaneseEntry] {
        let lowercaseQuery = query.lowercased()
        
        return coreVocabulary.filter { entry in
            entry.word.localizedCaseInsensitiveContains(lowercaseQuery) ||
            entry.romaji.localizedCaseInsensitiveContains(lowercaseQuery) ||
            (entry.hiragana?.localizedCaseInsensitiveContains(lowercaseQuery) ?? false) ||
            (entry.katakana?.localizedCaseInsensitiveContains(lowercaseQuery) ?? false) ||
            entry.meanings.contains { $0.localizedCaseInsensitiveContains(lowercaseQuery) } ||
            (entry.kanji?.localizedCaseInsensitiveContains(lowercaseQuery) ?? false)
        }
    }
    
    // MARK: - JMDict Search
    private func searchJMDict(_ query: String) -> [JapaneseEntry] {
        let lowercaseQuery = query.lowercased()
        
        return jmdictEntries.filter { entry in
            entry.word.localizedCaseInsensitiveContains(lowercaseQuery) ||
            entry.romaji.localizedCaseInsensitiveContains(lowercaseQuery) ||
            (entry.hiragana?.localizedCaseInsensitiveContains(lowercaseQuery) ?? false) ||
            (entry.katakana?.localizedCaseInsensitiveContains(lowercaseQuery) ?? false) ||
            entry.meanings.contains { $0.localizedCaseInsensitiveContains(lowercaseQuery) } ||
            (entry.kanji?.localizedCaseInsensitiveContains(lowercaseQuery) ?? false)
        }
    }
    
    // MARK: - JMDict Download and Loading
    func downloadJMDict() {
        guard !isDownloading else { return }
        
        // Download JMDict simplified JSON from GitHub
        // Note: This file is large (~100MB+), so download may take time
        // Alternative URLs if the main one doesn't work:
        // - https://github.com/scriptin/jmdict-simplified/releases
        // - Use a CDN or mirror if available
        
        guard let jmdictURL = URL(string: "https://raw.githubusercontent.com/scriptin/jmdict-simplified/master/jmdict-eng-3.5.0.json") else {
            error = .invalidURL
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        error = nil
        
        let task = session.downloadTask(with: jmdictURL) { [weak self] localURL, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadProgress = 1.0
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = .networkError(error)
                }
                return
            }
            
            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    self.error = .noData
                }
                return
            }
            
            // Move downloaded file to documents directory
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: self.jmdictFileURL.path) {
                    try fileManager.removeItem(at: self.jmdictFileURL)
                }
                try fileManager.moveItem(at: localURL, to: self.jmdictFileURL)
                
                // Load the dictionary
                self.loadJMDictFromFile()
                
                DispatchQueue.main.async {
                    print("JMDict downloaded and loaded successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .decodingError
                }
            }
        }
        
        // Track download progress
        downloadObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
            }
        }
        
        task.resume()
    }
    
    func loadJMDictFromFile() {
        guard FileManager.default.fileExists(atPath: jmdictFileURL.path) else {
            print("JMDict file not found. Call downloadJMDict() first.")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try Data(contentsOf: self.jmdictFileURL)
                let decoder = JSONDecoder()
                let jmdictResponse = try decoder.decode(JMDictResponse.self, from: data)
                
                // Convert JMDict entries to JapaneseEntry format
                var entries: [JapaneseEntry] = []
                
                for word in jmdictResponse.words {
                    // Get kanji text (use first common kanji or first available)
                    let kanjiText = word.kanji?.first(where: { $0.common == true })?.text ?? 
                                   word.kanji?.first?.text
                    
                    // Get kana (hiragana/katakana)
                    let kana = word.kana.first(where: { $0.common == true }) ?? word.kana.first
                    let kanaText = kana?.text ?? ""
                    
                    // Determine if it's hiragana or katakana
                    let isKatakana = kanaText.unicodeScalars.contains { scalar in
                        (0x30A0...0x30FF).contains(scalar.value) // Katakana range
                    }
                    let hiragana = isKatakana ? nil : kanaText.isEmpty ? nil : kanaText
                    let katakana = isKatakana ? kanaText : nil
                    
                    // Get meanings from senses
                    var meanings: [String] = []
                    var partOfSpeech: [String] = []
                    
                    for sense in word.sense {
                        // Get English glosses
                        let englishGlosses = sense.gloss.filter { gloss in
                            gloss.lang == nil || gloss.lang == "eng" || gloss.lang == "en"
                        }
                        meanings.append(contentsOf: englishGlosses.map { $0.text })
                        
                        // Get part of speech
                        if let pos = sense.partOfSpeech {
                            partOfSpeech.append(contentsOf: pos)
                        }
                    }
                    
                    // Remove duplicate meanings and limit
                    let uniqueMeanings = Array(Set(meanings)).prefix(5)
                    
                    // Generate romaji - try to extract from kana or use a placeholder
                    // Note: For production, use a proper kana-to-romaji library
                    let romaji = kanaText.isEmpty ? "N/A" : generateRomaji(from: kanaText)
                    
                    // Skip entries without meanings
                    guard !uniqueMeanings.isEmpty else { continue }
                    
                    // Create entry
                    let entry = JapaneseEntry(
                        word: kanjiText ?? kanaText,
                        hiragana: hiragana,
                        katakana: katakana,
                        romaji: romaji,
                        meanings: Array(uniqueMeanings),
                        partOfSpeech: Array(Set(partOfSpeech)).prefix(3).map { $0 }, // Limit POS
                        jlptLevel: nil, // JMDict doesn't include JLPT levels
                        frequency: nil,
                        kanji: kanjiText
                    )
                    
                    entries.append(entry)
                }
                
                DispatchQueue.main.async {
                    self.jmdictEntries = entries
                    self.jmdictLoaded = true
                    print("Loaded \(entries.count) JMDict entries into memory")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.error = .decodingError
                    print("Failed to load JMDict: \(error)")
                }
            }
        }
    }
    
    // Simple romaji conversion (basic implementation)
    // Note: This is a placeholder. For production, consider using a proper kana-to-romaji library
    private func generateRomaji(from kana: String) -> String {
        // Basic hiragana to romaji mapping (simplified)
        // For a full implementation, use a library like "KanaKit" or similar
        let hiraganaToRomaji: [String: String] = [
            "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
            "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
            "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
            "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
            "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
            "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
            "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
            "や": "ya", "ゆ": "yu", "よ": "yo",
            "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
            "わ": "wa", "を": "wo", "ん": "n"
        ]
        
        // For now, return a placeholder. The JMDict might already have romaji in some fields
        // or we can extract it from the kana using a proper library
        return kana // Temporary - will be improved
    }
    
    // MARK: - Helper Methods
    func hasJMDictFile() -> Bool {
        return FileManager.default.fileExists(atPath: jmdictFileURL.path)
    }
    
    func getJMDictStatus() -> String {
        if jmdictLoaded {
            return "Loaded: \(jmdictEntries.count) entries"
        } else if hasJMDictFile() {
            return "File exists, not loaded yet"
        } else {
            return "Not downloaded"
        }
    }
    
    // Public accessor for jmdictLoaded
    var isJMDictLoaded: Bool {
        return jmdictLoaded
    }
}

// MARK: - JapaneseEntry for JMDICT compatibility
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

// MARK: - Error Types
enum JMDictError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode data"
        case .noData:
            return "No data available"
        }
    }
}

// MARK: - JMDICT Response Models
// These would be used for real JMDICT integration
struct JMDictResponse: Codable {
    let version: String
    let languages: [String]
    let words: [JMDictWord]
}

struct JMDictWord: Codable {
    let id: String
    let kanji: [JMDictKanji]?
    let kana: [JMDictKana]
    let sense: [JMDictSense]
}

struct JMDictKanji: Codable {
    let common: Bool?
    let text: String
    let tags: [String]?
}

struct JMDictKana: Codable {
    let common: Bool?
    let text: String
    let tags: [String]?
    let appliesToKanji: [String]?
}

struct JMDictSense: Codable {
    let partOfSpeech: [String]?
    let appliesTo: [String]?
    let misc: [String]?
    let info: [String]?
    let languageSource: [JMDictLanguageSource]?
    let dialect: [String]?
    let gloss: [JMDictGloss]
}

struct JMDictLanguageSource: Codable {
    let lang: String?
    let partial: Bool?
    let wasei: Bool?
    let text: String?
}

struct JMDictGloss: Codable {
    let lang: String?
    let gender: String?
    let type: String?
    let text: String
}
