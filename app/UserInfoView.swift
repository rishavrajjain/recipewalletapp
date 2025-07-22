import SwiftUI
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

// MARK: - User Info View (user profile + blood test PDF upload)
struct UserInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    // User profile fields
    @State private var userName: String = ""
    @State private var userAge: String = ""
    @State private var userWeight: String = ""
    @State private var foodPreference: FoodPreference = .omnivore
    
    // Blood test PDF
    @State private var isDocumentPickerPresented = false
    @State private var selectedPDFURL: URL?
    @State private var selectedPDFName: String?
    
    // Networking state
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    enum FoodPreference: String, CaseIterable {
        case omnivore = "Omnivore"
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case pescatarian = "Pescatarian"
        case keto = "Keto"
        case paleo = "Paleo"
        case glutenFree = "Gluten-Free"
        
        var icon: String {
            switch self {
            case .omnivore: return "fork.knife"
            case .vegetarian: return "leaf.fill"
            case .vegan: return "carrot.fill"
            case .pescatarian: return "fish.fill"
            case .keto: return "flame.fill"
            case .paleo: return "mountain.2.fill"
            case .glutenFree: return "checkmark.shield.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // User Profile Section
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("Personal Information")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    Text("Full Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                TextField("Enter your name", text: $userName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // Age and Weight Row
                            HStack(spacing: 16) {
                                // Age Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.orange)
                                            .frame(width: 20)
                                        Text("Age")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    TextField("25", text: $userAge)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                }
                                
                                // Weight Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "scalemass")
                                            .foregroundColor(.green)
                                            .frame(width: 20)
                                        Text("Weight (kg)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    TextField("70", text: $userWeight)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                }
                            }
                            
                            // Food Preference Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .foregroundColor(.purple)
                                        .frame(width: 20)
                                    Text("Food Preference")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Menu {
                                    ForEach(FoodPreference.allCases, id: \.self) { preference in
                                        Button(action: {
                                            foodPreference = preference
                                        }) {
                                            HStack {
                                                Image(systemName: preference.icon)
                                                Text(preference.rawValue)
                                                if foodPreference == preference {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: foodPreference.icon)
                                            .foregroundColor(.purple)
                                        Text(foodPreference.rawValue)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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
                            .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPicker(selectedURL: $selectedPDFURL, selectedName: $selectedPDFName)
            }
            .onAppear {
                loadExistingUserData()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadExistingUserData() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        userAge = UserDefaults.standard.string(forKey: "userAge") ?? ""
        userWeight = UserDefaults.standard.string(forKey: "userWeight") ?? ""
        
        if let savedPreference = UserDefaults.standard.string(forKey: "foodPreference"),
           let preference = FoodPreference(rawValue: savedPreference) {
            foodPreference = preference
        }
    }
    
    /// Upload user profile and blood test PDF
    private func uploadUserInfo() async {
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        
        let boundary = UUID().uuidString
        
        do {
            // Build multipart request with user profile and PDF
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
                    // Save user profile info locally
                    UserDefaults.standard.set(userName, forKey: "userName")
                    UserDefaults.standard.set(userAge, forKey: "userAge")
                    UserDefaults.standard.set(userWeight, forKey: "userWeight")
                    UserDefaults.standard.set(foodPreference.rawValue, forKey: "foodPreference")
                    
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
    
    /// Build multipart/form-data request with user profile and PDF
    private func buildUserInfoRequest(boundary: String) throws -> URLRequest? {
        let url = APIConfig.endpoint("upload-user-info")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add user profile fields
        let profileFields = [
            ("name", userName),
            ("age", userAge),
            ("weight", userWeight),
            ("food_preference", foodPreference.rawValue)
        ]
        
        for (fieldName, fieldValue) in profileFields {
            if !fieldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n\r\n".data(using: .utf8)!)
                body.append(fieldValue.data(using: .utf8)!)
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
