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
    let impact: String?  // Optional since backend might use different field names
    let severity: String?  // Optional since backend might not provide this
    let concern: String?  // Backend uses "concern" for main culprits
    let benefit: String?  // Backend uses "benefit" for health boosters
    
    // Computed property to get the actual impact/concern/benefit text
    var impactText: String {
        return impact ?? concern ?? benefit ?? "No details available"
    }
    
    // Convert string severity to RiskLevel for UI
    var riskLevel: HealthAnalysis.RiskLevel {
        guard let severity = severity else { return .medium }
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

struct HealthRecommendations: Codable {
    let shouldAvoid: Bool?
    let modifications: [String]?
    let alternativeRecipes: [String]?
    
    // Backend might send dynamic fields instead of fixed arrays
    let reduce_sodium: String?
    let reduce_sugar: String?
    let leaner_protein: String?
    let increase_vegetables: String?
    let whole_grain_option: String?
    
    // Computed property to get all recommendations as an array
    var allModifications: [String] {
        var mods: [String] = []
        
        // Add from modifications array if available
        if let modifications = modifications {
            mods.append(contentsOf: modifications)
        }
        
        // Add from dynamic fields
        if let reduce_sodium = reduce_sodium { mods.append(reduce_sodium) }
        if let reduce_sugar = reduce_sugar { mods.append(reduce_sugar) }
        if let leaner_protein = leaner_protein { mods.append(leaner_protein) }
        if let increase_vegetables = increase_vegetables { mods.append(increase_vegetables) }
        if let whole_grain_option = whole_grain_option { mods.append(whole_grain_option) }
        
        return mods
    }
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

struct SimpleRecipe: Codable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String
    let ingredients: [String]  // Simple names only
    let cookTime: Int?
    let isFromReel: Bool
    let steps: [String]
    let createdAt: Date
    
    init(from recipe: Recipe) {
        self.id = recipe.id
        self.name = recipe.name
        self.description = recipe.description
        self.imageUrl = recipe.imageUrl
        self.ingredients = recipe.ingredients.map { $0.name }  // Extract just the name from Ingredient objects
        self.cookTime = recipe.cookTime
        self.isFromReel = recipe.isFromReel
        self.steps = recipe.steps
        self.createdAt = recipe.createdAt
    }
}

struct HealthAnalysisRequest: Codable {
    let recipe: BackendRecipe  // Changed from SimpleRecipe to BackendRecipe
    let bloodTestId: String?
    let includeBloodTest: Bool
    
    enum CodingKeys: String, CodingKey {
        case recipe
        case bloodTestId = "blood_test_id"
        case includeBloodTest = "include_blood_test"
    }
}

// Backend compatible recipe format - matches new backend contract
struct BackendRecipe: Codable {
    let id: String
    let title: String  // Changed from 'name' to 'title'
    let description: String
    let imageUrl: String
    let prepTime: Int  // NEW FIELD - required
    let cookTime: Int
    let difficulty: String  // NEW FIELD - required ("Easy", "Medium", "Hard")
    let nutrition: NutritionInfo  // NEW FIELD - required
    let ingredients: [CategorizedIngredient]  // Changed from [String] to [CategorizedIngredient]
    let steps: [String]
    let isFromReel: Bool
    let extractedFrom: String  // NEW FIELD - required ("instagram", "tiktok", "youtube", "website")
    let creatorHandle: String?  // NEW FIELD - optional
    let creatorName: String?  // NEW FIELD - optional
    let createdAt: String  // Changed from Date to String
    
    // Convert from our Recipe format to backend format
    init(from recipe: Recipe) {
        self.id = recipe.id
        self.title = recipe.name  // Map 'name' to 'title'
        self.description = recipe.description
        self.imageUrl = recipe.imageUrl
        self.prepTime = recipe.prepTime ?? 0  // Default to 0 if nil
        self.cookTime = recipe.cookTime ?? 0  // Default to 0 if nil
        self.difficulty = recipe.difficulty?.rawValue ?? "Medium"  // Default to "Medium"
        self.nutrition = NutritionInfo(from: recipe.nutrition ?? Nutrition())  // Default empty nutrition
        self.ingredients = recipe.ingredients.map { CategorizedIngredient(from: $0) }
        self.steps = recipe.steps
        self.isFromReel = recipe.isFromReel
        self.extractedFrom = recipe.extractedFrom ?? "website"  // Default to "website"
        self.creatorHandle = recipe.creatorHandle
        self.creatorName = recipe.creatorName
        
        // Convert Date to ISO string
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.string(from: recipe.createdAt)
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
        case concern
        case benefit
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
            recipe: BackendRecipe(from: recipe),  // Convert to new backend format
            bloodTestId: bloodTestId,
            includeBloodTest: includeBloodTest
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError("Server returned status \(httpResponse.statusCode)")
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(HealthAnalysisAPIResponse.self, from: data)
            return apiResponse.analysis
        } catch {
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
                        
                        Text("General health insights")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Loading or chevron
                if isLoading {
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
        .disabled(isLoading)
        .sheet(isPresented: $showingDetail) {
            if let analysis = analysis {
                HealthAnalysisDetailView(analysis: analysis, recipe: recipe, includeBloodTest: false)
            }
        }
    }
    
    private func analyzeHealth() {
        // If we already have an analysis cached, just show it
        if let _ = analysis {
            showingDetail = true
            return
        }

        guard !isLoading else { return }

        isLoading = true

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        Task {
            do {
                let result = try await HealthAnalysisAPI.shared.analyzeHealthImpact(for: recipe, includeBloodTest: false)

                await MainActor.run {
                    self.analysis = result
                    self.isLoading = false
                    self.showingDetail = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // TODO: Show error state in UI
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
                ForEach(analysis.recommendations.allModifications, id: \.self) { modification in
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
                
                Text(impact.impactText)
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
                    prepTime: 5,
                    cookTime: 20,
                    difficulty: .easy,
                    nutrition: Nutrition(calories: 450, protein: 15, carbs: 55, fats: 18, portions: 2),
                    ingredients: [
                        Ingredient(name: "pasta", category: .pastaRiceGrains),
                        Ingredient(name: "cheese", category: .dairy),
                        Ingredient(name: "butter", category: .dairy),
                        Ingredient(name: "cream", category: .dairy)
                    ],
                    steps: ["Cook pasta", "Add cheese"],
                    isFromReel: false
                ))
                Spacer()
            }
            .padding()
        }
    }
}

#Preview { _HealthReportPreview() }
#endif
