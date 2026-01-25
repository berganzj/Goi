import SwiftUI

struct AddVocabularyView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @StateObject private var dictionaryService = JMDictService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var word = ""
    @State private var hiragana = ""
    @State private var katakana = ""
    @State private var romaji = ""
    @State private var meanings = [""]
    @State private var partOfSpeech = ""
    @State private var selectedJLPTLevel: JLPTLevel?
    @State private var source = ""
    @State private var showingKanaKeyboard = false
    @State private var activeKanaField: KanaField?
    @State private var showingSuccessAlert = false
    @State private var dictionaryResults: [JapaneseEntry] = []
    @State private var showingDictionaryResults = false
    @State private var showingDuplicateAlert = false
    @State private var duplicateMessage = ""
    
    enum KanaField {
        case word, hiragana, katakana
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Main word input
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Word")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 12) {
                                    TextField("Enter Japanese word", text: $word)
                                        .glassTextField()
                                        .onChange(of: word) { _, newValue in
                                            if !newValue.isEmpty && newValue.count > 1 {
                                                searchDictionary(query: newValue)
                                            }
                                        }
                                    
                                    Button(action: {
                                        activeKanaField = .word
                                        showingKanaKeyboard = true
                                    }) {
                                        Text("⌨️")
                                            .font(.title2)
                                            .frame(width: 50, height: 50)
                                            .glassCard(cornerRadius: 12)
                                    }
                                }
                        
                                // Dictionary lookup results
                                if showingDictionaryResults && !dictionaryResults.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Dictionary Suggestions:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        ForEach(dictionaryResults.prefix(3)) { entry in
                                            Button(action: {
                                                fillFromDictionaryEntry(entry)
                                            }) {
                                                GlassContainer(cornerRadius: 12, padding: 12) {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text(entry.word)
                                                                .font(.body)
                                                                .fontWeight(.semibold)
                                                            Spacer()
                                                            Text("Tap to use")
                                                                .font(.caption)
                                                                .foregroundColor(.blue)
                                                        }
                                                        Text(entry.romaji)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Text(entry.meanings.prefix(2).joined(separator: ", "))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                    
                        // Kana inputs
                        HStack(spacing: 16) {
                            GlassContainer(cornerRadius: 16, padding: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Hiragana")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 12) {
                                        TextField("ひらがな", text: $hiragana)
                                            .glassTextField()
                                        
                                        Button(action: {
                                            activeKanaField = .hiragana
                                            showingKanaKeyboard = true
                                        }) {
                                            Text("あ")
                                                .font(.title3)
                                                .frame(width: 50, height: 50)
                                                .glassCard(cornerRadius: 12)
                                        }
                                    }
                                }
                            }
                            
                            GlassContainer(cornerRadius: 16, padding: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Katakana")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 12) {
                                        TextField("カタカナ", text: $katakana)
                                            .glassTextField()
                                        
                                        Button(action: {
                                            activeKanaField = .katakana
                                            showingKanaKeyboard = true
                                        }) {
                                            Text("ア")
                                                .font(.title3)
                                                .frame(width: 50, height: 50)
                                                .glassCard(cornerRadius: 12)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Romaji input
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Romaji")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("Enter romaji pronunciation", text: $romaji)
                                    .glassTextField()
                            }
                        }
                    
                        // Meanings input
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Meanings")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button(action: addMeaning) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                ForEach(meanings.indices, id: \.self) { index in
                                    HStack(spacing: 12) {
                                        TextField("Enter meaning \(index + 1)", text: $meanings[index])
                                            .glassTextField()
                                        
                                        if meanings.count > 1 {
                                            Button(action: { removeMeaning(at: index) }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Part of speech
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Part of Speech")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("e.g., noun, verb, adjective", text: $partOfSpeech)
                                    .glassTextField()
                            }
                        }
                        
                        // JLPT Level
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("JLPT Level (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 12) {
                                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                                        Button(action: {
                                            selectedJLPTLevel = selectedJLPTLevel == level ? nil : level
                                        }) {
                                            Text(level.rawValue)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Group {
                                                        if selectedJLPTLevel == level {
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
                                                .foregroundColor(selectedJLPTLevel == level ? .white : .primary)
                                                .cornerRadius(12)
                                                .shadow(color: selectedJLPTLevel == level ? Color.blue.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        // Source input (optional)
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Source (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("e.g., Manga: One Piece Ch.1, Page 5", text: $source)
                                    .glassTextField()
                            }
                        }
                        
                        // Save button
                        Button(action: saveVocabulary) {
                            Text("Save Word")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassButton(isEnabled: canSave)
                                .foregroundColor(canSave ? .white : .gray)
                        }
                        .disabled(!canSave)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add New Word")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingKanaKeyboard) {
                if let field = activeKanaField {
                    KanaKeyboardView(
                        text: bindingForField(field),
                        keyboardType: keyboardTypeForField(field),
                        isPresented: $showingKanaKeyboard
                    )
                }
            }
            .alert("Word Added!", isPresented: $showingSuccessAlert) {
                Button("Add Another") {
                    clearForm()
                }
                Button("Done") {
                    // Form remains as is for user to see
                }
            } message: {
                Text("'\(word)' has been added to your vocabulary!")
            }
            .alert("Duplicate Word", isPresented: $showingDuplicateAlert) {
                Button("OK") {
                    // Just dismiss the alert
                }
            } message: {
                Text(duplicateMessage)
            }
        }
    }
    
    private var canSave: Bool {
        !word.isEmpty && !romaji.isEmpty && !meanings.filter { !$0.isEmpty }.isEmpty
    }
    
    private func bindingForField(_ field: KanaField) -> Binding<String> {
        switch field {
        case .word:
            return $word
        case .hiragana:
            return $hiragana
        case .katakana:
            return $katakana
        }
    }
    
    private func keyboardTypeForField(_ field: KanaField) -> KanaKeyboardType {
        switch field {
        case .word:
            return .hiragana // Default to hiragana for general input
        case .hiragana:
            return .hiragana
        case .katakana:
            return .katakana
        }
    }
    
    private func addMeaning() {
        meanings.append("")
    }
    
    private func removeMeaning(at index: Int) {
        meanings.remove(at: index)
    }
    
    private func saveVocabulary() {
        let cleanedMeanings = meanings.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let cleanedPartOfSpeech = partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        let partOfSpeechArray = cleanedPartOfSpeech.isEmpty ? [] : [cleanedPartOfSpeech]
        
        let entry = VocabularyEntry(
            word: word,
            hiragana: hiragana.isEmpty ? nil : hiragana,
            katakana: katakana.isEmpty ? nil : katakana,
            romaji: romaji,
            meanings: cleanedMeanings,
            partOfSpeech: partOfSpeechArray,
            jlptLevel: selectedJLPTLevel,
            source: source.isEmpty ? nil : source
        )
        
        let success = vocabularyManager.addEntry(entry)
        if success {
            showingSuccessAlert = true
        } else {
            duplicateMessage = "This word already exists in your vocabulary. Try a different word or check your existing entries."
            showingDuplicateAlert = true
        }
    }
    
    private func clearForm() {
        word = ""
        hiragana = ""
        katakana = ""
        romaji = ""
        meanings = [""]
        partOfSpeech = ""
        selectedJLPTLevel = nil
        source = ""
        dictionaryResults = []
        showingDictionaryResults = false
    }
    
    private func searchDictionary(query: String) {
        dictionaryService.searchWord(query) { results in
            DispatchQueue.main.async {
                self.dictionaryResults = results
                self.showingDictionaryResults = !results.isEmpty
            }
        }
    }
    
    private func fillFromDictionaryEntry(_ entry: JapaneseEntry) {
        word = entry.word
        hiragana = entry.hiragana ?? ""
        katakana = entry.katakana ?? ""
        romaji = entry.romaji
        meanings = entry.meanings.isEmpty ? [""] : entry.meanings
        partOfSpeech = entry.partOfSpeech.joined(separator: ", ")
        selectedJLPTLevel = entry.jlptLevel
        showingDictionaryResults = false
    }
}

#Preview {
    AddVocabularyView()
        .environmentObject(VocabularyManager())
}