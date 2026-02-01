import SwiftUI

struct JMDictDownloadView: View {
    @StateObject private var dictionaryService = JMDictService()
    @Environment(\.dismiss) private var dismiss
    
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
                    VStack(spacing: 24) {
                        // Header
                        GlassContainer(cornerRadius: 20, padding: 24) {
                            VStack(spacing: 16) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("JMDict Dictionary")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Download the full Japanese dictionary with over 200,000 entries for offline searching.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        
                        // Status
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Status")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(dictionaryService.getJMDictStatus())
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                if dictionaryService.isJMDictLoaded {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Ready to search")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Download progress
                        if dictionaryService.isDownloading {
                            GlassContainer(cornerRadius: 16, padding: 16) {
                                VStack(spacing: 16) {
                                    Text("Downloading...")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    ProgressView(value: dictionaryService.downloadProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    
                                    Text("\(Int(dictionaryService.downloadProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("This may take several minutes. The file is approximately 100MB.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            if !dictionaryService.isJMDictLoaded && !dictionaryService.isDownloading {
                                Button(action: {
                                    dictionaryService.downloadJMDict()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Download Dictionary")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .glassButton(isEnabled: true)
                                    .foregroundColor(.white)
                                }
                                .padding(.horizontal)
                            }
                            
                            if dictionaryService.hasJMDictFile() && !dictionaryService.isJMDictLoaded {
                                Button(action: {
                                    dictionaryService.loadJMDictFromFile()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                        Text("Reload Dictionary")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .glassButton(isEnabled: true)
                                    .foregroundColor(.white)
                                }
                                .padding(.horizontal)
                            }
                            
                            if let error = dictionaryService.error {
                                GlassContainer(cornerRadius: 16, padding: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("Error")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        Text(error.localizedDescription)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Info
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About JMDict")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("JMDict is a comprehensive Japanese dictionary containing over 200,000 entries. Once downloaded, all searches will use this full dictionary for more accurate and complete results.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("The dictionary file is stored locally on your device and works offline.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Dictionary Download")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    JMDictDownloadView()
}
