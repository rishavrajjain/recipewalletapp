// StepImageGenerator.swift
import SwiftUI

// MARK: - Models
struct GeneratedImage: Decodable, Identifiable, Hashable {
    let id = UUID()
    let stepNumber: Int
    let imageUrl: String
    let stepText: String
    
    enum CodingKeys: String, CodingKey {
        case stepNumber, imageUrl, stepText
    }
}

private struct ImageGenerationRequest: Encodable {
    let instructions: [String]
    let recipeTitle: String
}

private struct ImageGenerationAPIResponse: Decodable {
    let success: Bool
    let generatedImages: [GeneratedImage]
    let failedSteps: [FailedStep]?
    
    struct FailedStep: Decodable, Hashable {
        let stepNumber: Int
        let error: String
    }
}

// MARK: - API Service
class StepImageAPIService {
    private let baseURL = URL(string: "https://recipewallet.onrender.com")!
    
    func generateImages(for steps: [String], recipeTitle: String) async throws -> [GeneratedImage] {
        let url = baseURL.appendingPathComponent("generate-step-images")
        let request = ImageGenerationRequest(instructions: steps, recipeTitle: recipeTitle)
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        urlRequest.timeoutInterval = 120
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to generate images")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiResponse = try decoder.decode(ImageGenerationAPIResponse.self, from: data)
        
        guard apiResponse.success else {
            let error = apiResponse.failedSteps?.first?.error ?? "Unknown error"
            throw APIError.serverError("Image generation failed: \(error)")
        }
        
        return apiResponse.generatedImages.sorted { $0.stepNumber < $1.stepNumber }
    }
}

// MARK: - ViewModel
@MainActor
class StepImageViewModel: ObservableObject {
    @Published var generatedImages: [GeneratedImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedImageIndex = 0
    @Published var showingFullScreen = false
    @Published var useMockData = false
    @Published var loadingProgress = 0.0
    @Published var loadingStage: LoadingStage = .preparing
    
    enum LoadingStage: String, CaseIterable {
        case preparing = "Preparing your recipe..."
        case generating = "Creating visual magic..."
        case processing = "Adding finishing touches..."
        case completed = "Almost ready!"
        
        var icon: String {
            switch self {
            case .preparing: return "book.closed"
            case .generating: return "sparkles"
            case .processing: return "paintbrush"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    private let apiService = StepImageAPIService()
    
    func generateImages(for steps: [String], recipeTitle: String) {
        guard !isLoading, generatedImages.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        loadingProgress = 0.0
        loadingStage = .preparing
        
        if useMockData {
            simulateMockGeneration(for: steps)
        } else {
            Task {
                do {
                    let images = try await apiService.generateImages(for: Array(steps.prefix(4)), recipeTitle: recipeTitle)
                    self.generatedImages = images
                    self.loadingStage = .completed
                    self.loadingProgress = 1.0
                    try await Task.sleep(nanoseconds: 500_000_000)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
    
    private func simulateMockGeneration(for steps: [String]) {
        Task {
            for (index, stage) in LoadingStage.allCases.enumerated() {
                loadingStage = stage
                let progress = Double(index) / Double(LoadingStage.allCases.count - 1)
                loadingProgress = progress
                try await Task.sleep(nanoseconds: 800_000_000)
            }
            
            let mockUrl = "https://media.istockphoto.com/id/1165114438/photo/boiled-rice-in-a-bowl.jpg?s=612x612&w=0&k=20&c=LpGzGTOja3SzDkpCgPB2UccfUGYyYbBmMyDkZLGu1gk="
            self.generatedImages = Array(steps.prefix(4).enumerated()).map { index, step in
                GeneratedImage(stepNumber: index + 1, imageUrl: mockUrl, stepText: step)
            }
            
            try await Task.sleep(nanoseconds: 300_000_000)
            self.isLoading = false
        }
    }
    
    func showFullScreen(at index: Int) {
        selectedImageIndex = index
        showingFullScreen = true
    }
    
    func regenerateImages(for steps: [String], recipeTitle: String) {
        generatedImages.removeAll()
        generateImages(for: steps, recipeTitle: recipeTitle)
    }
}

// MARK: - UI Components
struct StepImageCarouselContainer: View {
    @ObservedObject var viewModel: StepImageViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingCarouselView(viewModel: viewModel)
            } else if !viewModel.generatedImages.isEmpty {
                ImageCarouselView(viewModel: viewModel)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingFullScreen) {
            FullScreenImageViewer(viewModel: viewModel)
        }
    }
}

struct LoadingCarouselView: View {
    @ObservedObject var viewModel: StepImageViewModel
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 240)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [.clear, .pink.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 120)
                    .offset(x: shimmerOffset)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: shimmerOffset)
                    .clipped()
                
                VStack(spacing: 16) {
                    Image(systemName: viewModel.loadingStage.icon)
                        .font(.title)
                        .foregroundColor(.pink)
                        .padding(16)
                        .background(Circle().fill(.pink.opacity(0.2)))
                    
                    Text(viewModel.loadingStage.rawValue)
                        .font(.title3.weight(.semibold))
                    
                    ProgressView(value: viewModel.loadingProgress)
                        .frame(width: 200)
                        .tint(.pink)
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear { shimmerOffset = UIScreen.main.bounds.width + 120 }
    }
}

struct ImageCarouselView: View {
    @ObservedObject var viewModel: StepImageViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {  // Fixed alignment here
                ForEach(Array(viewModel.generatedImages.enumerated()), id: \.element.id) { index, image in
                    StepImageCard(image: image, index: index) {
                        viewModel.showFullScreen(at: index)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct StepImageCard: View {
    let image: GeneratedImage
    let index: Int
    let onTap: () -> Void
    @State private var hasAppeared = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                AsyncImage(url: URL(string: image.imageUrl)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        ImagePlaceholder(systemName: "photo.badge.exclamationmark", text: "Failed to load", color: .red)
                    default:
                        ImagePlaceholder(systemName: "photo", text: "Loading...", color: .pink)
                    }
                }
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(image.stepText)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(3)
                    .frame(width: 240, height: 60, alignment: .topLeading)  // Fixed height for alignment
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(hasAppeared ? 1.0 : 0.8)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: hasAppeared)
        .onAppear { hasAppeared = true }
    }
}

struct ImagePlaceholder: View {
    let systemName: String
    let text: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
            
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.title2)
                    .foregroundColor(color.opacity(0.7))
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FullScreenImageViewer: View {
    @ObservedObject var viewModel: StepImageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGSize = .zero
    
    var currentImage: GeneratedImage {
        viewModel.generatedImages[viewModel.selectedImageIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedImageIndex + 1) of \(viewModel.generatedImages.count)")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                
                // Image Viewer
                TabView(selection: $viewModel.selectedImageIndex) {
                    ForEach(Array(viewModel.generatedImages.enumerated()), id: \.element.id) { index, image in
                        AsyncImage(url: URL(string: image.imageUrl)) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fit)
                            case .failure:
                                VStack {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Failed to load")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            default:
                                ProgressView().tint(.white).scaleEffect(1.5)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Footer
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(0..<viewModel.generatedImages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == viewModel.selectedImageIndex ? .white : .white.opacity(0.3))
                                .frame(width: index == viewModel.selectedImageIndex ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: viewModel.selectedImageIndex)
                        }
                    }
                    
                    Text(currentImage.stepText)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
        }
        .statusBarHidden()
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) { dragOffset = .zero }
                    }
                }
        )
        .offset(y: dragOffset.height * 0.5)
        .scaleEffect(1 - dragOffset.height / 1000)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.title2.bold())
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}
