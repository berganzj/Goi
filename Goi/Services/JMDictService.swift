import Foundation
import Combine

// MARK: - JMDICT Service
class JMDictService: ObservableObject {
    @Published var isLoading = false
    @Published var error: JMDictError?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Core vocabulary loaded from bundled JSON
    private var coreVocabulary: [JapaneseEntry] = []
    
    // Cache for API results to avoid repeated requests
    private var apiCache: [String: [JapaneseEntry]] = [:]
    
    init() {
        loadCoreVocabulary()
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
        isLoading = true
        error = nil
        
        // First, search core vocabulary
        let coreResults = searchCoreVocabulary(query)
        
        if !coreResults.isEmpty {
            // Found results in core vocabulary
            isLoading = false
            completion(coreResults)
            return
        }
        
        // Check cache for API results
        if let cachedResults = apiCache[query.lowercased()] {
            isLoading = false
            completion(cachedResults)
            return
        }
        
        // Fall back to JMDICT API for broader search
        searchJMDictAPI(query) { [weak self] results in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.apiCache[query.lowercased()] = results
                completion(results)
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
    
    private func searchJMDictAPI(_ query: String, completion: @escaping ([JapaneseEntry]) -> Void) {
        // For now, return empty results since we don't have API access
        // In a real implementation, this would query the JMDICT API
        print("Searching JMDICT API for: \(query)")
        
        // Simulate API delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            completion([])
        }
    }
    
    
    // MARK: - Future JMDICT API Integration
    // For production use, implement real JMDICT API calls here:
    // - https://jisho.org/api/ (unofficial but popular)
    // - Local JMDICT JSON processing
    // - Other Japanese dictionary APIs
    
    // MARK: - Real JMDICT Integration
    // Uncomment and implement when you want to use real JMDICT data
    
    /*
    func loadJMDictData() {
        // Download JMDICT JSON from:
        // https://github.com/scriptin/jmdict-simplified
        // Parse and store locally for offline use
        
        guard let url = URL(string: "https://raw.githubusercontent.com/scriptin/jmdict-simplified/master/jmdict-eng-3.1.0.json") else {
            error = .invalidURL
            return
        }
        
        isLoading = true
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: JMDictResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.error = .networkError(error)
                    }
                },
                receiveValue: { response in
                    // Process JMDICT data and convert to JapaneseEntry objects
                    self.processJMDictData(response)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processJMDictData(_ response: JMDictResponse) {
        // Convert JMDICT format to our JapaneseEntry format
        // This would be implemented based on JMDICT structure
    }
    */
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
