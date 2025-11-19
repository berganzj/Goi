import SwiftUI

struct KanaKeyboardView: View {
    @Binding var text: String
    let keyboardType: KanaKeyboardType
    @Binding var isPresented: Bool
    
    @State private var currentKeyboard: KanaKeyboardType
    
    init(text: Binding<String>, keyboardType: KanaKeyboardType, isPresented: Binding<Bool>) {
        self._text = text
        self.keyboardType = keyboardType
        self._isPresented = isPresented
        self._currentKeyboard = State(initialValue: keyboardType)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Text input display
                HStack {
                    TextField("Enter text", text: $text)
                        .font(.title2)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button("Clear") {
                        text = ""
                    }
                    .foregroundColor(.red)
                }
                .padding()
                
                // Keyboard type switcher
                HStack {
                    Button("あ") {
                        currentKeyboard = .hiragana
                    }
                    .padding()
                    .background(currentKeyboard == .hiragana ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("ア") {
                        currentKeyboard = .katakana
                    }
                    .padding()
                    .background(currentKeyboard == .katakana ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("ABC") {
                        currentKeyboard = .romaji
                    }
                    .padding()
                    .background(currentKeyboard == .romaji ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                
                // Keyboard grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(getKeyboardLayout(), id: \.self) { key in
                            Button(key) {
                                if key == "⌫" {
                                    if !text.isEmpty {
                                        text.removeLast()
                                    }
                                } else if key == "space" {
                                    text += " "
                                } else {
                                    text += key
                                }
                            }
                            .frame(width: 60, height: 50)
                            .background(key == "⌫" ? Color.red.opacity(0.7) : Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.title2)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Kana Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func getKeyboardLayout() -> [String] {
        switch currentKeyboard {
        case .hiragana:
            return hiraganaLayout
        case .katakana:
            return katakanaLayout
        case .romaji:
            return romajiLayout
        }
    }
    
    private var hiraganaLayout: [String] {
        [
            "あ", "い", "う", "え", "お",
            "か", "き", "く", "け", "こ",
            "さ", "し", "す", "せ", "そ",
            "た", "ち", "つ", "て", "と",
            "な", "に", "ぬ", "ね", "の",
            "は", "ひ", "ふ", "へ", "ほ",
            "ま", "み", "む", "め", "も",
            "や", "ゆ", "よ", "ら", "り",
            "る", "れ", "ろ", "わ", "ん",
            "が", "ぎ", "ぐ", "げ", "ご",
            "ざ", "じ", "ず", "ぜ", "ぞ",
            "だ", "ぢ", "づ", "で", "ど",
            "ば", "び", "ぶ", "べ", "ぼ",
            "ぱ", "ぴ", "ぷ", "ぺ", "ぽ",
            "ゃ", "ゅ", "ょ", "っ", "ー",
            "space", "。", "、", "？", "⌫"
        ]
    }
    
    private var katakanaLayout: [String] {
        [
            "ア", "イ", "ウ", "エ", "オ",
            "カ", "キ", "ク", "ケ", "コ",
            "サ", "シ", "ス", "セ", "ソ",
            "タ", "チ", "ツ", "テ", "ト",
            "ナ", "ニ", "ヌ", "ネ", "ノ",
            "ハ", "ヒ", "フ", "ヘ", "ホ",
            "マ", "ミ", "ム", "メ", "モ",
            "ヤ", "ユ", "ヨ", "ラ", "リ",
            "ル", "レ", "ロ", "ワ", "ン",
            "ガ", "ギ", "グ", "ゲ", "ゴ",
            "ザ", "ジ", "ズ", "ゼ", "ゾ",
            "ダ", "ヂ", "ヅ", "デ", "ド",
            "バ", "ビ", "ブ", "ベ", "ボ",
            "パ", "ピ", "プ", "ペ", "ポ",
            "ャ", "ュ", "ョ", "ッ", "ー",
            "space", "。", "、", "？", "⌫"
        ]
    }
    
    private var romajiLayout: [String] {
        [
            "q", "w", "e", "r", "t",
            "y", "u", "i", "o", "p",
            "a", "s", "d", "f", "g",
            "h", "j", "k", "l", ";",
            "z", "x", "c", "v", "b",
            "n", "m", ",", ".", "?",
            "space", "⌫", "", "", ""
        ]
    }
}

#Preview {
    KanaKeyboardView(
        text: .constant("テスト"),
        keyboardType: .hiragana,
        isPresented: .constant(true)
    )
}