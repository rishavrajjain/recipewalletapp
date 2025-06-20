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
    let bloodMarkersAffected: [BloodMarkerImpact]
    
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
    let severity: HealthAnalysis.RiskLevel
    
    var emoji: String {
        switch severity {
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
    let bloodTestId: String
    
    enum CodingKeys: String, CodingKey {
        case recipe
        case bloodTestId = "blood_test_id"
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
}

extension HealthAnalysis.RiskLevel: Codable {}

extension IngredientImpact: Codable {}
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
    
    func analyzeHealthImpact(for recipe: Recipe) async throws -> HealthAnalysis {
        // Check if user has uploaded blood test
        guard let bloodTestId = UserDefaults.standard.string(forKey: "bloodTestID") else {
            throw HealthAnalysisError.noBloodTestFound
        }
        
        // Make actual API call to backend
        guard let url = URL(string: "http://localhost:8000/analyze-health-impact") else {
            throw HealthAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let requestBody = HealthAnalysisRequest(
            recipe: recipe,
            bloodTestId: bloodTestId
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError("Server returned error")
        }
        
        let apiResponse = try JSONDecoder().decode(HealthAnalysisAPIResponse.self, from: data)
        
        guard apiResponse.success else {
            throw HealthAnalysisError.analysisError(apiResponse.error ?? "Analysis failed")
        }
        
        return apiResponse.analysis
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
    
    var body: some View {
        Button(action: analyzeHealth) {
            ZStack {
                // Pure black background - Apple style
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .frame(height: 88)
                
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Health Analysis")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(isLoading ? "Analyzing..." : "Personalized health insights")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Clean arrow or loading
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
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .sheet(isPresented: $showingDetail) {
            if let analysis = analysis {
                HealthAnalysisDetailView(analysis: analysis, recipe: recipe)
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
                let result = try await HealthAnalysisAPI.shared.analyzeHealthImpact(for: recipe)
                
                await MainActor.run {
                    self.analysis = result
                    self.isLoading = false
                    self.showingDetail = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    if error is HealthAnalysisError && error.localizedDescription.contains("blood test") {
                        self.showingNoBloodTestAlert = true
                    } else {
                        // TODO: Show other error states
                        print("Health analysis error: \(error.localizedDescription)")
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Score Section
                    heroScoreSection
                    
                    // Personal Message
                    personalMessageSection
                    
                    // Blood Markers Impact
                    bloodMarkersSection
                    
                    // Main Culprits
                    if !analysis.mainCulprits.isEmpty {
                        culpritsSection
                    }
                    
                    // Health Boosters
                    if !analysis.healthBoosters.isEmpty {
                        boostersSection
                    }
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        analysis.riskLevel.color.opacity(0.1),
                        analysis.riskLevel.color.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Health Impact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var heroScoreSection: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(analysis.riskLevel.color.opacity(0.3), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: CGFloat(analysis.overallScore) / 100)
                    .stroke(analysis.riskLevel.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(analysis.overallScore)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(analysis.riskLevel.color)
                    
                    Text("HEALTH\nSCORE")
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
            
            // Risk Level Badge
            HStack(spacing: 8) {
                Text(analysis.riskLevel.emoji)
                    .font(.title2)
                
                Text(analysis.riskLevel.title)
                    .font(.headline.bold())
                    .foregroundColor(analysis.riskLevel.color)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(analysis.riskLevel.color.opacity(0.15))
            )
        }
        .padding(.top, 20)
    }
    
    private var personalMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
                Text("Personal Message")
                    .font(.headline.bold())
                Spacer()
            }
            
            Text(analysis.personalMessage)
                .font(.body)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var bloodMarkersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.red)
                Text("Blood Markers Impact")
                    .font(.headline.bold())
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(analysis.bloodMarkersAffected) { marker in
                    BloodMarkerCard(marker: marker)
                }
            }
        }
    }
    
    private var culpritsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🚨")
                    .font(.title2)
                Text("Main Culprits")
                    .font(.headline.bold())
                    .foregroundColor(.red)
                Spacer()
            }
            
            VStack(spacing: 10) {
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
                    .foregroundColor(.green)
                Spacer()
            }
            
            VStack(spacing: 10) {
                ForEach(analysis.healthBoosters) { booster in
                    IngredientImpactCard(impact: booster, isNegative: false)
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Smart Recommendations")
                    .font(.headline.bold())
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(analysis.recommendations.modifications, id: \.self) { modification in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        
                        Text(modification)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                }
            }
        }
    }
}

// -------------------------------------------------------------------------
// MARK: – Supporting Views
// -------------------------------------------------------------------------

struct BloodMarkerCard: View {
    let marker: BloodMarkerImpact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(marker.marker)
                    .font(.subheadline.bold())
                
                HStack {
                    Text("Current: \(marker.currentLevel, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Target: \(marker.targetRange)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(marker.predictedImpact)
                    .font(.subheadline.bold())
                    .foregroundColor(marker.isOutOfRange ? .red : .green)
                
                if marker.isOutOfRange {
                    Text("⚠️ Out of range")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(marker.isOutOfRange ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(marker.isOutOfRange ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isNegative ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isNegative ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
        )
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
                    ingredients: ["pasta", "cheese", "butter", "cream"],
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
