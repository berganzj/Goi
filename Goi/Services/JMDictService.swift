import Foundation
import Combine

// MARK: - JMDICT Service
class JMDictService: ObservableObject {
    @Published var isLoading = false
    @Published var error: JMDictError?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Mock JMDICT Data
    // In a real app, you would integrate with actual JMDICT JSON data
    // For now, we'll use sample data that mimics JMDICT structure
    
    func searchWord(_ query: String, completion: @escaping ([JapaneseEntry]) -> Void) {
        isLoading = true
        error = nil
        
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            
            // Mock search results
            let results = self.mockJMDictSearch(query)
            completion(results)
        }
    }
    
    private func mockJMDictSearch(_ query: String) -> [JapaneseEntry] {
        let mockEntries = [
            JapaneseEntry(
                word: "\u3053\u3093\u306b\u3061\u306f",
                hiragana: "\u3053\u3093\u306b\u3061\u306f",
                katakana: nil,
                romaji: "konnichiwa",
                meanings: ["hello", "good day", "good afternoon"],
                partOfSpeech: ["expression", "greeting"],
                jlptLevel: .n5,
                frequency: 100
            ),
            JapaneseEntry(
                word: "\u5b66\u6821",
                hiragana: "\u304c\u3063\u3053\u3046",
                katakana: nil,
                romaji: "gakkou",
                meanings: ["school"],
                partOfSpeech: ["noun"],
                jlptLevel: .n5,
                frequency: 95,
                kanji: "\u5b66\u6821"
            ),
            JapaneseEntry(
                word: "\u30b3\u30fc\u30d2\u30fc",
                hiragana: nil,
                katakana: "\u30b3\u30fc\u30d2\u30fc",
                romaji: "koohii",
                meanings: ["coffee"],
                partOfSpeech: ["noun"],
                jlptLevel: .n5,
                frequency: 80
            ),
            JapaneseEntry(
                word: "\u5148\u751f",
                hiragana: "\u305b\u3093\u305b\u3044",
                katakana: nil,
                romaji: "sensei",
                meanings: ["teacher", "doctor", "master"],
                partOfSpeech: ["noun"],
                jlptLevel: .n5,
                frequency: 85,
                kanji: "\u5148\u751f"
            ),
            JapaneseEntry(
                word: "\u98df\u3079\u308b",
                hiragana: "\u305f\u3079\u308b",
                katakana: nil,
                romaji: "taberu",
                meanings: ["to eat"],
                partOfSpeech: ["ichidan verb", "transitive verb"],
                jlptLevel: .n5,
                frequency: 90,
                kanji: "\u98df\u3079\u308b"
            )
        ]
        
        // Filter based on query
        return mockEntries.filter { entry in
            entry.word.localizedCaseInsensitiveContains(query) ||
            entry.romaji.localizedCaseInsensitiveContains(query) ||
            (entry.hiragana?.localizedCaseInsensitiveContains(query) ?? false) ||
            (entry.katakana?.localizedCaseInsensitiveContains(query) ?? false) ||
            entry.meanings.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
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