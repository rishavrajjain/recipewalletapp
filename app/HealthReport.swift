import SwiftUI
import Foundation

// -------------------------------------------------------------------------
// MARK: – Enhanced Data Models
// -------------------------------------------------------------------------

struct HealthAnalysis: Identifiable {
    let id = UUID()
    let overallScore: Int
    let riskLevel: RiskLevel
    let personalMessage: String
    let mainCulprits: [IngredientImpact]
    let healthBoosters: [IngredientImpact]
    let recommendations: HealthRecommendations
    let bloodMarkersAffected: [BloodMarkerImpact]?
    
    enum RiskLevel: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var emoji: String {
            switch self {
            case .low: return "✅"
            case .medium: return "⚠️"
            case .high: return "🚨"
            }
        }
        
        var title: String {
            switch self {
            case .low: return "Looking Good!"
            case .medium: return "Be Careful"
            case .high: return "Red Alert!"
            }
        }
    }
}

struct IngredientImpact: Identifiable {
    let id = UUID()
    let ingredient: String
    let impact: String
    let severity: String  // Changed to String to match backend
    
    // Convert string severity to RiskLevel for UI
    var riskLevel: HealthAnalysis.RiskLevel {
        switch severity.lowercased() {
        case "high": return .high
        case "medium": return .medium
        default: return .low
        }
    }
    
    var emoji: String {
        switch riskLevel {
        case .low: return "😊"
        case .medium: return "😐"
        case .high: return "😰"
        }
    }
}

struct HealthRecommendations {
    let shouldAvoid: Bool
    let modifications: [String]
    let alternativeRecipes: [String]
}

struct BloodMarkerImpact: Identifiable {
    let id = UUID()
    let marker: String
    let currentLevel: Double
    let predictedImpact: String
    let targetRange: String
    let isOutOfRange: Bool
}

// -------------------------------------------------------------------------
// MARK: – API Request/Response Models
// -------------------------------------------------------------------------

struct HealthAnalysisRequest: Codable {
    let recipe: Recipe
    let bloodTestId: String?
    let includeBloodTest: Bool
    
    enum CodingKeys: String, CodingKey {
        case recipe
        case bloodTestId = "blood_test_id"
        case includeBloodTest = "include_blood_test"
    }
}

struct HealthAnalysisAPIResponse: Codable {
    let success: Bool
    let analysis: HealthAnalysis
    let error: String?
}

extension HealthAnalysis: Codable {
    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case riskLevel = "risk_level"
        case personalMessage = "personal_message"
        case mainCulprits = "main_culprits"
        case healthBoosters = "health_boosters"
        case recommendations
        case bloodMarkersAffected = "blood_markers_affected"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        overallScore = try container.decode(Int.self, forKey: .overallScore)
        riskLevel = try container.decode(RiskLevel.self, forKey: .riskLevel)
        personalMessage = try container.decode(String.self, forKey: .personalMessage)
        mainCulprits = try container.decode([IngredientImpact].self, forKey: .mainCulprits)
        healthBoosters = try container.decode([IngredientImpact].self, forKey: .healthBoosters)
        recommendations = try container.decode(HealthRecommendations.self, forKey: .recommendations)
        
        // Handle blood markers - can be either [String] or [BloodMarkerImpact] or nil
        if container.contains(.bloodMarkersAffected) {
            do {
                // Try to decode as [BloodMarkerImpact] first (blood test mode)
                bloodMarkersAffected = try container.decode([BloodMarkerImpact].self, forKey: .bloodMarkersAffected)
            } catch {
                do {
                    // If that fails, try as [String] (general mode)
                    let stringArray = try container.decode([String].self, forKey: .bloodMarkersAffected)
                    // Convert strings to simple BloodMarkerImpact objects
                    bloodMarkersAffected = stringArray.map { markerName in
                        BloodMarkerImpact(
                            marker: markerName.capitalized,
                            currentLevel: 0,
                            predictedImpact: "May be affected",
                            targetRange: "See your doctor",
                            isOutOfRange: false
                        )
                    }
                } catch {
                    // If both fail, set to nil
                    bloodMarkersAffected = nil
                }
            }
        } else {
            bloodMarkersAffected = nil
        }
    }
}

extension HealthAnalysis.RiskLevel: Codable {}

extension IngredientImpact: Codable {
    enum CodingKeys: String, CodingKey {
        case ingredient
        case impact
        case severity
    }
}

extension HealthRecommendations: Codable {
    enum CodingKeys: String, CodingKey {
        case shouldAvoid = "should_avoid"
        case modifications
        case alternativeRecipes = "alternative_recipes"
    }
}

extension BloodMarkerImpact: Codable {
    enum CodingKeys: String, CodingKey {
        case marker
        case currentLevel = "current_level"
        case predictedImpact = "predicted_impact"
        case targetRange = "target_range"
        case isOutOfRange = "is_out_of_range"
    }
}

enum HealthAnalysisError: LocalizedError {
    case noBloodTestFound
    case invalidURL
    case serverError(String)
    case analysisError(String)
    
    var errorDescription: String? {
        switch self {
        case .noBloodTestFound:
            return "Please upload your blood test report first in User Profile"
        case .invalidURL:
            return "Invalid server URL"
        case .serverError(let message):
            return "Server error: \(message)"
        case .analysisError(let message):
            return "Analysis failed: \(message)"
        }
    }
}

// -------------------------------------------------------------------------
// MARK: – Enhanced API Service
// -------------------------------------------------------------------------

actor HealthAnalysisAPI {
    static let shared = HealthAnalysisAPI()
    
    func analyzeHealthImpact(for recipe: Recipe, includeBloodTest: Bool = false) async throws -> HealthAnalysis {
        var bloodTestId: String? = nil
        
        // Only check for blood test if user wants to include it
        if includeBloodTest {
            guard let storedBloodTestId = UserDefaults.standard.string(forKey: "bloodTestID") else {
                throw HealthAnalysisError.noBloodTestFound
            }
            bloodTestId = storedBloodTestId
        }
        
        // Make actual API call to backend
        let url = APIConfig.endpoint("analyze-health-impact")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let requestBody = HealthAnalysisRequest(
            recipe: recipe,
            bloodTestId: bloodTestId,
            includeBloodTest: includeBloodTest
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // DEBUG: Print request details
        print("🚀 HEALTH ANALYSIS REQUEST:")
        print("Include Blood Test: \(includeBloodTest)")
        print("Blood Test ID: \(bloodTestId ?? "nil")")
        print("Recipe: \(recipe.name)")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw HealthAnalysisError.serverError("Invalid response")
        }
        
        print("📡 HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server error - Status: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw HealthAnalysisError.serverError("Server returned status \(httpResponse.statusCode)")
        }
        
        // DEBUG: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 RAW API RESPONSE:")
            print(jsonString)
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(HealthAnalysisAPIResponse.self, from: data)
            print("✅ JSON decoded successfully")
            return apiResponse.analysis
        } catch {
            print("❌ JSON DECODING ERROR:")
            print("Error: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
            throw HealthAnalysisError.analysisError("Failed to decode response: \(error.localizedDescription)")
        }
    }
}

// -------------------------------------------------------------------------
// MARK: – Enhanced Health Card
// -------------------------------------------------------------------------

struct HealthReport: View {
    let recipe: Recipe
    
    @State private var isLoading = false
    @State private var analysis: HealthAnalysis?
    @State private var showingDetail = false
    @State private var showingNoBloodTestAlert = false
    @State private var includeBloodTest = false
    
    var body: some View {
        Button(action: analyzeHealth) {
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
                    Image(systemName: isLoading ? "brain.head.profile" : "heart.text.square.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .symbolEffect(.pulse, isActive: isLoading)
                
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Health Analysis")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(includeBloodTest ? "Include blood test report" : "General health insights")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Custom toggle or loading
                    if !isLoading {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                includeBloodTest.toggle()
                            }
                        }) {
                            ZStack {
                                // Toggle background
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(includeBloodTest ? Color.green : Color.clear)
                                    .frame(width: 52, height: 32)
                                
                                // Toggle border
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    .frame(width: 52, height: 32)
                                
                                // Toggle circle
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                                    .offset(x: includeBloodTest ? 10 : -10)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: includeBloodTest)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProgressView()
                            .tint(.white.opacity(0.6))
                            .scaleEffect(0.9)
                    }
                    
                    // Chevron
                    if !isLoading {
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
        .disabled(isLoading)
        .sheet(isPresented: $showingDetail) {
            if let analysis = analysis {
                HealthAnalysisDetailView(analysis: analysis, recipe: recipe, includeBloodTest: includeBloodTest)
            }
        }
        .alert("Blood Test Required", isPresented: $showingNoBloodTestAlert) {
            Button("Upload Now") {
                // This will be handled by the parent view to show UserInfoView
                NotificationCenter.default.post(name: .showUserProfile, object: nil)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please upload your blood test report first to get personalized health analysis.")
        }
    }
    
    private func analyzeHealth() {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            do {
                let result = try await HealthAnalysisAPI.shared.analyzeHealthImpact(for: recipe, includeBloodTest: includeBloodTest)
                
                await MainActor.run {
                    self.analysis = result
                    self.isLoading = false
                    self.showingDetail = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    
                    // DEBUG: Print detailed error info
                    print("🔥 HEALTH ANALYSIS ERROR:")
                    print("Error type: \(type(of: error))")
                    print("Error description: \(error.localizedDescription)")
                    print("Include blood test was: \(includeBloodTest)")
                    
                    if error is HealthAnalysisError && error.localizedDescription.contains("blood test") {
                        print("👆 Showing blood test alert")
                        self.showingNoBloodTestAlert = true
                    } else {
                        print("👆 Other error - not showing alert")
                        // TODO: Show other error states
                    }
                }
            }
        }
    }
}

// -------------------------------------------------------------------------
// MARK: – Mind-Blowing Detail View
// -------------------------------------------------------------------------

struct HealthAnalysisDetailView: View {
    let analysis: HealthAnalysis
    let recipe: Recipe
    let includeBloodTest: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Score Section
                    heroScoreSection
                    
                    // Personal Message
                    personalMessageSection
                    
                    // Smart Recommendations - moved to top for better UX
                    recommendationsSection
                    
                    // Blood Markers Impact - only show if blood test is included AND data exists
                    if includeBloodTest && !(analysis.bloodMarkersAffected?.isEmpty ?? true) {
                        bloodMarkersSection
                    }
                    
                    // Main Culprits
                    if !analysis.mainCulprits.isEmpty {
                        culpritsSection
                    }
                    
                    // Health Boosters
                    if !analysis.healthBoosters.isEmpty {
                        boostersSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Health Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        dismiss() 
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 17, weight: .medium))
                }
            }
        }
    }
    
    private var heroScoreSection: some View {
        VStack(spacing: 20) {
            // Minimalist Score Display
            VStack(spacing: 12) {
                Text("\(analysis.overallScore)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                
                Text("HEALTH SCORE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(2)
            }
            
            // Clean Risk Level
            HStack(spacing: 12) {
                Circle()
                    .fill(analysis.riskLevel.color)
                    .frame(width: 12, height: 12)
                
                Text(analysis.riskLevel.title.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1)
            }
        }
        .padding(.vertical, 24)
    }
    
    private var personalMessageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ANALYSIS")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .tracking(2)
            
            Text(analysis.personalMessage)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black)
                .lineSpacing(4)
        }
        .padding(.vertical, 20)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("RECOMMENDATIONS")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .tracking(2)
            
            VStack(spacing: 16) {
                ForEach(analysis.recommendations.modifications, id: \.self) { modification in
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(modification)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.black)
                            .lineSpacing(2)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var bloodMarkersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            bloodMarkersSectionHeader
            bloodMarkersList
        }
        .padding(.vertical, 20)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var bloodMarkersSectionHeader: some View {
        Text("BLOOD MARKERS")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.gray)
            .tracking(2)
    }
    
    private var bloodMarkersList: some View {
        VStack(spacing: 16) {
            ForEach(analysis.bloodMarkersAffected ?? []) { marker in
                BloodMarkerCard(marker: marker)
            }
        }
    }
    
    private var culpritsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("⚠️")
                    .font(.title2)
                Text("Main Culprits")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(analysis.mainCulprits) { culprit in
                    IngredientImpactCard(impact: culprit, isNegative: true)
                }
            }
        }
    }
    
    private var boostersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("💪")
                    .font(.title2)
                Text("Health Boosters")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(analysis.healthBoosters) { booster in
                    IngredientImpactCard(impact: booster, isNegative: false)
                }
            }
        }
    }
}

// -------------------------------------------------------------------------
// MARK: – Supporting Views
// -------------------------------------------------------------------------

struct BloodMarkerRow: View {
    let marker: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 8))
            
            Text(marker.capitalized)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct BloodMarkerCard: View {
    let marker: BloodMarkerImpact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(marker.marker)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                if marker.isOutOfRange {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            
            if marker.currentLevel > 0 {
                HStack {
                    Text("Current: \(marker.currentLevel, specifier: "%.0f")")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text("Target: \(marker.targetRange)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Text(marker.predictedImpact)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .lineSpacing(2)
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.05)),
            alignment: .bottom
        )
    }
}

struct IngredientImpactCard: View {
    let impact: IngredientImpact
    let isNegative: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(impact.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(impact.ingredient)
                    .font(.subheadline.bold())
                
                Text(impact.impact)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Subtle indicator for severity
            Circle()
                .fill(impact.riskLevel.color)
                .frame(width: 8, height: 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// -------------------------------------------------------------------------
// MARK: – Preview
// -------------------------------------------------------------------------

#if DEBUG
struct _HealthReportPreview: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                HealthReport(recipe: Recipe(
                    id: UUID().uuidString,
                    name: "Cheesy Pasta",
                    description: "Rich and creamy",
                    imageUrl: "",
                    ingredients: [
                        Ingredient(name: "pasta", imageUrl: ""),
                        Ingredient(name: "cheese", imageUrl: ""),
                        Ingredient(name: "butter", imageUrl: ""),
                        Ingredient(name: "cream", imageUrl: "")
                    ],
                    cookTime: 20,
                    isFromReel: false,
                    steps: ["Cook pasta", "Add cheese"],
                    createdAt: Date()
                ))
                Spacer()
            }
            .padding()
        }
    }
}

#Preview { _HealthReportPreview() }
#endif
