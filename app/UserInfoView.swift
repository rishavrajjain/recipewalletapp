import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Document Picker for PDFs
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var selectedName: String?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedURL = url
            parent.selectedName = url.lastPathComponent
        }
    }
}

// MARK: - User Info View (kitchen photos + blood test PDF upload)
struct UserInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Kitchen photos
    @State private var kitchenPickerItems: [PhotosPickerItem] = []
    @State private var kitchenImages: [UIImage] = []
    
    // Blood test PDF
    @State private var isDocumentPickerPresented = false
    @State private var selectedPDFURL: URL?
    @State private var selectedPDFName: String?
    
    // Networking state
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Kitchen Photos Section
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.accentColor)
                            Text("Kitchen Photos")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if kitchenImages.isEmpty {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 120)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("No kitchen photos selected")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(kitchenImages.indices, id: \.self) { idx in
                                        Image(uiImage: kitchenImages[idx])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 110, height: 110)
                                            .clipped()
                                            .cornerRadius(10)
                                            .shadow(radius: 2)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        PhotosPicker(selection: $kitchenPickerItems,
                                     maxSelectionCount: 6,
                                     matching: .images) {
                            Label("Select Kitchen Photos", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Blood Test Report Section
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.red)
                            Text("Blood Test Report")
                                .font(.headline)
                            Spacer()
                        }
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 80)
                            .overlay(
                                HStack {
                                    Image(systemName: selectedPDFURL != nil ? "doc.text.fill" : "doc.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(selectedPDFURL != nil ? .red : .gray)
                                    
                                    VStack(alignment: .leading) {
                                        if let pdfName = selectedPDFName {
                                            Text(pdfName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("PDF selected")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("No PDF selected")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Text("Tap to select blood test report")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                            )
                            .onTapGesture {
                                isDocumentPickerPresented = true
                            }
                        
                        Button(action: {
                            isDocumentPickerPresented = true
                        }) {
                            Label("Select PDF Report", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Blood Test Analysis Section
                    if selectedPDFURL != nil {
                        BloodTestAnalysisCard()
                    }
                    
                    // Upload Section
                    VStack(spacing: 16) {
                        if isUploading {
                            ProgressView("Uploading user information…")
                                .frame(maxWidth: .infinity)
                        } else {
                            Button("Save User Information") {
                                Task { await uploadUserInfo() }
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            .disabled(kitchenImages.isEmpty && selectedPDFURL == nil)
                        }
                        
                        if let msg = errorMessage {
                            Text(msg)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("User Information")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: kitchenPickerItems) { _ in
                Task { await loadSelectedImages() }
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPicker(selectedURL: $selectedPDFURL, selectedName: $selectedPDFName)
            }
        }
    }
    
    // MARK: - Helpers
    /// Convert PhotosPicker items into UIImages
    private func loadSelectedImages() async {
        kitchenImages.removeAll()
        for item in kitchenPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                kitchenImages.append(img)
            }
        }
    }
    
    /// Upload kitchen photos and blood test PDF
    private func uploadUserInfo() async {
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        
        let boundary = UUID().uuidString
        
        do {
            // Build multipart request with both photos and PDF
            guard let request = try buildUserInfoRequest(boundary: boundary) else {
                errorMessage = "Failed to build upload request"
                return
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpRes = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpRes.statusCode == 200 {
                // Parse response and save user info
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Save kitchen ID if provided
                    if let kitchenId = json["kitchen_id"] as? String {
                        UserDefaults.standard.set(kitchenId, forKey: "kitchenID")
                    }
                    // Save blood test info if provided
                    if let bloodTestId = json["blood_test_id"] as? String {
                        UserDefaults.standard.set(bloodTestId, forKey: "bloodTestID")
                    }
                    dismiss()
                } else {
                    errorMessage = "Successfully uploaded but couldn't parse response"
                    dismiss()
                }
            } else {
                let errorData = String(data: data, encoding: .utf8) ?? "Unknown error"
                errorMessage = "Upload failed: \(httpRes.statusCode) - \(errorData)"
            }
        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }
    }
    
    /// Build multipart/form-data request with kitchen photos and PDF
    private func buildUserInfoRequest(boundary: String) throws -> URLRequest? {
        let url = APIConfig.endpoint("upload-user-info")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add kitchen photos
        for (index, image) in kitchenImages.enumerated() {
            if let jpeg = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"kitchen_photos\"; filename=\"kitchen_\(index + 1).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(jpeg)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        // Add blood test PDF
        if let pdfURL = selectedPDFURL {
            do {
                let pdfData = try Data(contentsOf: pdfURL)
                let filename = selectedPDFName ?? "blood_test.pdf"
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"blood_test_pdf\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
                body.append(pdfData)
                body.append("\r\n".data(using: .utf8)!)
            } catch {
                throw error
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        return req
    }
}

// MARK: - Blood Test Analysis Card
struct BloodTestAnalysisCard: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var showingRecipeSelection = false
    @State private var selectedRecipe: Recipe?
    @State private var isAnalyzing = false
    @State private var analysis: HealthAnalysis?
    @State private var showingAnalysisDetail = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.red)
                Text("Blood Test Analysis")
                    .font(.headline)
                Spacer()
            }
            
            Button(action: {
                showingRecipeSelection = true
            }) {
                ZStack {
                    // Pure black background - Apple style
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .frame(height: 88)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        .frame(height: 88)
                
                    HStack(spacing: 16) {
                        // Clean, minimal icon
                        Image(systemName: isAnalyzing ? "brain.head.profile" : "heart.text.square.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .symbolEffect(.pulse, isActive: isAnalyzing)
                    
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Health Analysis")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Include blood test report")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // Loading or chevron
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white.opacity(0.6))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                }
            }
            .buttonStyle(.plain)
            .disabled(isAnalyzing || recipeStore.recipes.isEmpty)
            
            if let recipe = selectedRecipe {
                HStack {
                    Text("Selected: \(recipe.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Analyze") {
                        Task { await analyzeRecipe() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnalyzing)
                }
            }
            
            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .sheet(isPresented: $showingRecipeSelection) {
            RecipeSelectionSheet(selectedRecipe: $selectedRecipe)
                .environmentObject(recipeStore)
        }
        .sheet(isPresented: $showingAnalysisDetail) {
            if let analysis = analysis, let recipe = selectedRecipe {
                HealthAnalysisDetailView(analysis: analysis, recipe: recipe, includeBloodTest: true)
            }
        }
    }
    
    private func analyzeRecipe() async {
        guard let recipe = selectedRecipe else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        do {
            let result = try await HealthAnalysisAPI.shared.analyzeHealthImpact(for: recipe, includeBloodTest: true)
            
            await MainActor.run {
                self.analysis = result
                self.isAnalyzing = false
                self.showingAnalysisDetail = true
            }
        } catch {
            await MainActor.run {
                self.isAnalyzing = false
                self.errorMessage = "Analysis failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Recipe Selection Sheet
struct RecipeSelectionSheet: View {
    @Binding var selectedRecipe: Recipe?
    @EnvironmentObject var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(recipeStore.recipes) { recipe in
                    Button(action: {
                        selectedRecipe = recipe
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                HStack {
                                    Label("\(recipe.cookTime) min", systemImage: "clock")
                                    if recipe.isFromReel {
                                        Label("Reel", systemImage: "video.fill")
                                            .font(.caption)
                                            .foregroundColor(.pink)
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedRecipe?.id == recipe.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .disabled(selectedRecipe == nil)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UserInfoView()
}
