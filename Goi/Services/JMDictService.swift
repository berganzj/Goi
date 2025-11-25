import Foundation
import Combine

// MARK: - Vocabulary Data Service
class VocabularyDataService: ObservableObject {
    @Published var isLoading = false
    @Published var error: VocabularyError?
    
    private let vocabularyKey = "vocabulary_entries"
    private let backupKey = "vocabulary_backup"
    
    // MARK: - Data Management
    func saveVocabulary(_ entries: [VocabularyEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: vocabularyKey)
            
            // Create backup
            UserDefaults.standard.set(data, forKey: backupKey)
            
            error = nil
        } catch {
            self.error = .encodingError
        }
    }
    
    func loadVocabulary() -> [VocabularyEntry] {
        guard let data = UserDefaults.standard.data(forKey: vocabularyKey) else {
            return []
        }
        
        do {
            let entries = try JSONDecoder().decode([VocabularyEntry].self, from: data)
            error = nil
            return entries
        } catch {
            self.error = .decodingError
            
            // Try to load from backup
            return loadBackupVocabulary()
        }
    }
    
    private func loadBackupVocabulary() -> [VocabularyEntry] {
        guard let data = UserDefaults.standard.data(forKey: backupKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([VocabularyEntry].self, from: data)
        } catch {
            return []
        }
    }
    
    // MARK: - Export/Import
    func exportVocabulary(_ entries: [VocabularyEntry]) -> Data? {
        do {
            return try JSONEncoder().encode(entries)
        } catch {
            error = .encodingError
            return nil
        }
    }
    
    func importVocabulary(from data: Data) -> [VocabularyEntry]? {
        do {
            return try JSONDecoder().decode([VocabularyEntry].self, from: data)
        } catch {
            error = .decodingError
            return nil
        }
    }
    
    // MARK: - Statistics
    func getVocabularyStats(_ entries: [VocabularyEntry]) -> VocabularyStats {
        let total = entries.count
        let withSource = entries.filter { $0.source != nil }.count
        let jlptLevels = Dictionary(grouping: entries.compactMap { $0.jlptLevel }) { $0 }
        let recentlyAdded = entries.filter { 
            Calendar.current.isDate($0.dateAdded, inSameDayAs: Date()) 
        }.count
        
        return VocabularyStats(
            totalWords: total,
            wordsWithSource: withSource,
            jlptDistribution: jlptLevels.mapValues { $0.count },
            recentlyAdded: recentlyAdded
        )
    }
}

// MARK: - Error Types
enum VocabularyError: Error, LocalizedError {
    case encodingError
    case decodingError
    case noData
    case exportError
    case importError
    
    var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Failed to save vocabulary data"
        case .decodingError:
            return "Failed to load vocabulary data"
        case .noData:
            return "No vocabulary data available"
        case .exportError:
            return "Failed to export vocabulary"
        case .importError:
            return "Failed to import vocabulary"
        }
    }
}

// MARK: - Vocabulary Statistics
struct VocabularyStats {
    let totalWords: Int
    let wordsWithSource: Int
    let jlptDistribution: [JLPTLevel: Int]
    let recentlyAdded: Int
    
    var sourcePercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsWithSource) / Double(totalWords) * 100
    }
}
