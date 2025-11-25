import SwiftUI

struct AddVocabularyView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
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
    
    enum KanaField {
        case word, hiragana, katakana
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Main word input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Word")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter Japanese word", text: $word)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("⌨️") {
                                activeKanaField = .word
                                showingKanaKeyboard = true
                            }
                        }
                    }
                    
                    // Kana inputs
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hiragana")
                                .font(.subheadline)
                            
                            HStack {
                                TextField("ひらがな", text: $hiragana)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("あ") {
                                    activeKanaField = .hiragana
                                    showingKanaKeyboard = true
                                }
                                .font(.caption)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Katakana")
                                .font(.subheadline)
                            
                            HStack {
                                TextField("カタカナ", text: $katakana)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("ア") {
                                    activeKanaField = .katakana
                                    showingKanaKeyboard = true
                                }
                                .font(.caption)
                            }
                        }
                    }
                    
                    // Romaji input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Romaji")
                            .font(.headline)
                        
                        TextField("Enter romaji pronunciation", text: $romaji)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Meanings input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Meanings")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: addMeaning) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        ForEach(meanings.indices, id: \.self) { index in
                            HStack {
                                TextField("Enter meaning \(index + 1)", text: $meanings[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                if meanings.count > 1 {
                                    Button(action: { removeMeaning(at: index) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Part of speech
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Part of Speech")
                            .font(.headline)
                        
                        TextField("e.g., noun, verb, adjective", text: $partOfSpeech)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // JLPT Level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JLPT Level (Optional)")
                            .font(.headline)
                        
                        HStack {
                            ForEach(JLPTLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    selectedJLPTLevel = selectedJLPTLevel == level ? nil : level
                                }) {
                                    Text(level.rawValue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedJLPTLevel == level ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedJLPTLevel == level ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Source input (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source (Optional)")
                            .font(.headline)
                        
                        TextField("e.g., Manga: One Piece Ch.1, Page 5", text: $source)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Save button
                    Button(action: saveVocabulary) {
                        Text("Save Word")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!canSave)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
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
        
        vocabularyManager.addEntry(entry)
        showingSuccessAlert = true
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
    }
}

#Preview {
    AddVocabularyView()
        .environmentObject(VocabularyManager())
}