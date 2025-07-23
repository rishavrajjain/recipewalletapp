import SwiftUI

// MARK: - User Info View
struct UserInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    // User profile fields
    @State private var userName: String = ""
    @State private var userAge: String = ""
    @State private var userWeight: String = ""
    @State private var foodPreference: FoodPreference = .omnivore
    
    // Networking state
    @State private var isSaving = false
    @State private var showingSavedConfirmation = false
    
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
                VStack(spacing: 0) {
                    // Profile Header
                    VStack(spacing: 24) {
                        // Avatar
                        
                        
                        VStack(spacing: 8) {
                            Text(userName.isEmpty ? "Your Profile" : userName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Personalize your recipe experience")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
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
                            saveUserInfo()
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Account for tab bar
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
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
    
    private func saveUserInfo() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSaving = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Simulate save delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Save user profile info locally
            UserDefaults.standard.set(userName, forKey: "userName")
            UserDefaults.standard.set(userAge, forKey: "userAge")
            UserDefaults.standard.set(userWeight, forKey: "userWeight")
            UserDefaults.standard.set(foodPreference.rawValue, forKey: "foodPreference")
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isSaving = false
                showingSavedConfirmation = true
            }
            
            // Success haptic
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Hide confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSavedConfirmation = false
                }
            }
        }
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Preview
#Preview {
    UserInfoView()
}
