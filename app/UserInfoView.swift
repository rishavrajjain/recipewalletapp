import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Profile Model
struct UserProfile: Codable {
    var name: String
    var email: String
    var age: String
    var weight: String
    var foodPreference: String
    var photoURL: String?
    var provider: String // "google", "apple", "email"
    var lastUpdated: Date
    
    init(name: String = "", email: String = "", age: String = "", weight: String = "", foodPreference: String = "Omnivore", photoURL: String? = nil, provider: String = "unknown") {
        self.name = name
        self.email = email
        self.age = age
        self.weight = weight
        self.foodPreference = foodPreference
        self.photoURL = photoURL
        self.provider = provider
        self.lastUpdated = Date()
    }
}

// MARK: - User Info View
struct UserInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // User profile fields
    @State private var userProfile = UserProfile()
    @State private var userName: String = ""
    @State private var userAge: String = ""
    @State private var userWeight: String = ""
    @State private var foodPreference: FoodPreference = .omnivore
    
    // Networking state
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var showingSavedConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
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
            if isLoading {
                ProgressView("Loading profile...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header with Avatar
                        VStack(spacing: 24) {
                            // User Avatar
                            AsyncImage(url: URL(string: userProfile.photoURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.brandYellow)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.brandYellow, lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 8) {
                                Text(userName.isEmpty ? "Your Profile" : userName)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                if !userProfile.email.isEmpty {
                                    Text(userProfile.email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                // Provider Badge
                                HStack(spacing: 4) {
                                    Image(systemName: providerIcon)
                                        .font(.system(size: 12))
                                    Text("Signed in with \(userProfile.provider.capitalized)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                        
                        // Form Fields
                        VStack(spacing: 24) {
                            // Name Field
                            FormField(
                                title: "Name",
                                text: $userName,
                                placeholder: "Enter your name"
                            )
                            
                            // Age and Weight Row
                            HStack(spacing: 16) {
                                FormField(
                                    title: "Age",
                                    text: $userAge,
                                    placeholder: "25",
                                    keyboardType: .numberPad
                                )
                                
                                FormField(
                                    title: "Weight (kg)",
                                    text: $userWeight,
                                    placeholder: "70",
                                    keyboardType: .decimalPad
                                )
                            }
                            
                            // Food Preference
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Dietary Preference")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Menu {
                                    ForEach(FoodPreference.allCases, id: \.self) { preference in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                foodPreference = preference
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: preference.icon)
                                                Text(preference.rawValue)
                                                Spacer()
                                                if foodPreference == preference {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.brandYellow)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: foodPreference.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(.brandYellow)
                                        
                                        Text(foodPreference.rawValue)
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 48)
                        
                        // Save Button
                        VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    await saveUserProfile()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.black)
                                    } else {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    
                                    Text(isSaving ? "Saving..." : "Save Profile")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.brandYellow)
                                .cornerRadius(16)
                                .shadow(color: Color.brandYellow.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isSaving || userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity((isSaving || userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
                            .buttonStyle(.plain)
                            
                            if showingSavedConfirmation {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Profile saved successfully")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            Button(action: {
                                authViewModel.signOut()
                            }) {
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                            }
                            
                            // Button(action: {
                            //     showingDeleteConfirmation = true
                            // }) {
                            //     Text("Delete Account")
                            //         .font(.system(size: 16, weight: .semibold))
                            //         .foregroundColor(.white)
                            //         .frame(maxWidth: .infinity)
                            //         .frame(height: 52)
                            //         .background(Color.red)
                            //         .cornerRadius(16)
                            // }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120) // Account for tab bar
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(.systemGroupedBackground))
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .onAppear {
            Task {
                await loadUserProfile()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                authViewModel.softDeleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete your account. This action cannot be undone. Are you sure you want to continue?")
        }
    }
    
    // MARK: - Computed Properties
    
    private var providerIcon: String {
        switch userProfile.provider.lowercased() {
        case "google":
            return "globe"
        case "apple":
            return "applelogo"
        default:
            return "person.circle"
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func loadUserProfile() async {
        isLoading = true
        
        do {
            // First try to load from Firestore
            if let firestoreProfile = try await UserProfileStore.shared.loadProfile() {
                userProfile = firestoreProfile
                populateFields(from: firestoreProfile)
            } else {
                // If no Firestore profile, populate from Firebase Auth
                populateFromFirebaseAuth()
                // Also check UserDefaults for any legacy data
                loadLegacyUserData()
                
                // 🎯 AUTO-SAVE: If we have useful data from auth, save it automatically
                if shouldAutoSaveProfile() {
                    await autoSaveProfileFromAuth()
                }
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            showingError = true
            // Fallback to Firebase Auth data
            populateFromFirebaseAuth()
            loadLegacyUserData()
            
            // Try to auto-save even on error
            if shouldAutoSaveProfile() {
                await autoSaveProfileFromAuth()
            }
        }
        
        isLoading = false
    }
    
    private func populateFromFirebaseAuth() {
        guard let user = authViewModel.user else { return }
        
        // Extract data from Firebase Auth
        userProfile.email = user.email ?? ""
        userProfile.photoURL = user.photoURL?.absoluteString
        
        // Determine provider
        if let providerData = user.providerData.first {
            switch providerData.providerID {
            case "google.com":
                userProfile.provider = "google"
            case "apple.com":
                userProfile.provider = "apple"
            default:
                userProfile.provider = "email"
            }
        }
        
        // Use display name from auth if available
        if let displayName = user.displayName, !displayName.isEmpty {
            userProfile.name = displayName
            userName = displayName
        }
        
        // Populate email field
        if !userProfile.email.isEmpty {
            // Email is read-only from auth, so we don't need to set it in UI
        }
    }
    
    private func populateFields(from profile: UserProfile) {
        userName = profile.name
        userAge = profile.age
        userWeight = profile.weight
        
        if let preference = FoodPreference(rawValue: profile.foodPreference) {
            foodPreference = preference
        }
    }
    
    private func loadLegacyUserData() {
        // Load any existing data from UserDefaults as fallback
        if userName.isEmpty {
            userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        }
        if userAge.isEmpty {
            userAge = UserDefaults.standard.string(forKey: "userAge") ?? ""
        }
        if userWeight.isEmpty {
            userWeight = UserDefaults.standard.string(forKey: "userWeight") ?? ""
        }
        
        if let savedPreference = UserDefaults.standard.string(forKey: "foodPreference"),
           let preference = FoodPreference(rawValue: savedPreference) {
            foodPreference = preference
        }
    }
    
    @MainActor
    private func saveUserProfile() async {
        isSaving = true
        errorMessage = nil
        
        // Update the profile model with current form data
        userProfile.name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.age = userAge.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.weight = userWeight.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.foodPreference = foodPreference.rawValue
        userProfile.lastUpdated = Date()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        do {
            // Save to Firestore
            try await UserProfileStore.shared.saveProfile(userProfile)
            
            // Also save to UserDefaults for offline access
            UserDefaults.standard.set(userProfile.name, forKey: "userName")
            UserDefaults.standard.set(userProfile.age, forKey: "userAge")
            UserDefaults.standard.set(userProfile.weight, forKey: "userWeight")
            UserDefaults.standard.set(userProfile.foodPreference, forKey: "foodPreference")
            
            // Success feedback
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSavedConfirmation = true
            }
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Hide confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSavedConfirmation = false
                }
            }
            
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showingError = true
            
            // Error haptic
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        isSaving = false
    }
    
    // Check if we have enough data from auth to auto-save
    private func shouldAutoSaveProfile() -> Bool {
        return !userProfile.name.isEmpty || !userProfile.email.isEmpty
    }
    
    // Auto-save profile with auth data (silent, no UI feedback)
    @MainActor
    private func autoSaveProfileFromAuth() async {
        // Update the profile model with current form data
        userProfile.name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.age = userAge.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.weight = userWeight.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.foodPreference = foodPreference.rawValue
        userProfile.lastUpdated = Date()
        
        do {
            // Save to Firestore silently
            try await UserProfileStore.shared.saveProfile(userProfile)
            
            // Also save to UserDefaults for offline access
            UserDefaults.standard.set(userProfile.name, forKey: "userName")
            UserDefaults.standard.set(userProfile.age, forKey: "userAge")
            UserDefaults.standard.set(userProfile.weight, forKey: "userWeight")
            UserDefaults.standard.set(userProfile.foodPreference, forKey: "foodPreference")
            
            print("✅ Auto-saved profile with auth data: \(userProfile.name), \(userProfile.email)")
        } catch {
            print("❌ Failed to auto-save profile: \(error.localizedDescription)")
            // Don't show error to user for auto-save failures
        }
    }
}

// MARK: - User Profile Store
class UserProfileStore {
    static let shared = UserProfileStore()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func saveProfile(_ profile: UserProfile) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserProfileStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(profile)
        let json = try JSONSerialization.jsonObject(with: data)
        
        try await db.collection("users").document(uid).setData(["profile": json], merge: true)
        
        // Update the cached profile in RecipeCloudStore for consistency
        RecipeCloudStore.shared.updateCachedProfile(profile)
    }
    
    func loadProfile() async throws -> UserProfile? {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserProfileStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // First check if we have a cached profile
        if let cachedProfile = RecipeCloudStore.shared.getCachedProfile() {
            return cachedProfile
        }
        
        // If not cached, fetch from Firestore
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard let data = document.data(),
              let profileData = data["profile"] else {
            return nil
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: profileData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let profile = try decoder.decode(UserProfile.self, from: jsonData)
        
        // Cache the loaded profile
        RecipeCloudStore.shared.updateCachedProfile(profile)
        
        return profile
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isReadOnly: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(isReadOnly ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
                .keyboardType(keyboardType)
                .disabled(isReadOnly)
        }
    }
}

// MARK: - Preview
#Preview {
    UserInfoView()
}
