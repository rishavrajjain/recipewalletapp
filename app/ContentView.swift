import SwiftUI
import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let showUserProfile = Notification.Name("showUserProfile")
}

// ========================================================================
// MARK: - Models
// ==================================================x======================

struct Ingredient: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case imageUrl
    }
    
    // Helper initializer for backward compatibility
    init(name: String, imageUrl: String = "") {
        print("🥕 INGREDIENT: Creating ingredient - Name: '\(name)', ImageURL: '\(imageUrl)'")
        self.name = name
        self.imageUrl = imageUrl
    }
    
    // Custom decoder to handle potential data issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedImageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        
        print("🥕 INGREDIENT: Decoding ingredient - Name: '\(decodedName)', ImageURL: '\(decodedImageUrl)'")
        
        // Validate that name is not empty or contains invalid characters
        guard !decodedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ INGREDIENT: Empty ingredient name detected")
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Ingredient name cannot be empty"
            ))
        }
        
        self.name = decodedName
        self.imageUrl = decodedImageUrl
    }
    
    // Computed property that returns a usable URL – falls back to Unsplash if missing
    var resolvedImageURL: URL? {
        if !imageUrl.trimmingCharacters(in: .whitespaces).isEmpty,
           let url = URL(string: imageUrl) {
            print("🥕 INGREDIENT: Using provided image URL for '\(name)': \(url)")
            return url
        }
        // Fallback to LoremFlickr keyword image (reliable)
        let keyword = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "food"
        let fallbackURL = URL(string: "https://loremflickr.com/400/400/\(keyword)")
        print("🥕 INGREDIENT: Using fallback image URL for '\(name)': \(fallbackURL?.absoluteString ?? "nil")")
        return fallbackURL
    }
}

struct Recipe: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    let description: String
    let imageUrl: String
    let ingredients: [Ingredient]  // Changed from [String] to [Ingredient]
    let cookTime: Int
    let isFromReel: Bool
    let steps: [String]
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, description: String, imageUrl: String, ingredients: [Ingredient], cookTime: Int, isFromReel: Bool = false, steps: [String], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.ingredients = ingredients
        self.cookTime = cookTime
        self.isFromReel = isFromReel
        self.steps = steps
        self.createdAt = createdAt
    }
    
    // Backward compatibility initializer for string ingredients
    init(id: String = UUID().uuidString, name: String, description: String, imageUrl: String, ingredients: [String], cookTime: Int, isFromReel: Bool = false, steps: [String], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.ingredients = ingredients.map { Ingredient(name: $0) }
        self.cookTime = cookTime
        self.isFromReel = isFromReel
        self.steps = steps
        self.createdAt = createdAt
    }
}

struct Collection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var recipeIDs: [String]
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, recipeIDs: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.recipeIDs = recipeIDs
        self.createdAt = createdAt
    }
}

// ========================================================================
// MARK: - API Service Layer
// ========================================================================

private struct APIResponse: Decodable {
    let success: Bool
    let recipe: APIRecipe?
    let error: String?
}

private struct APIIngredient: Decodable {
    let name: String
    let imageUrl: String?
    
    // Custom decoder to handle both string and object formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            // Backend sent ingredients as strings
            print("🥕 API_INGREDIENT: Decoding string ingredient: '\(stringValue)'")
            self.name = stringValue
            self.imageUrl = nil
        } else if let dict = try? container.decode([String: String].self) {
            // Backend sent ingredients as objects
            print("🥕 API_INGREDIENT: Decoding object ingredient: \(dict)")
            self.name = dict["name"] ?? ""
            self.imageUrl = dict["imageUrl"]
        } else {
            print("❌ API_INGREDIENT: Failed to decode ingredient")
            throw DecodingError.typeMismatch(APIIngredient.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected either String or Dictionary for ingredient"
            ))
        }
    }
    
    func asIngredient() -> Ingredient {
        Ingredient(name: name, imageUrl: imageUrl ?? "")
    }
}

private struct APIRecipe: Decodable {
    let title: String
    let description: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    let ingredients: [APIIngredient]?
    let cookTimeMinutes: Int?
    let totalTimeMinutes: Int?
    let steps: [String]?
    
    func asRecipe() -> Recipe {
        print("🍳 API_RECIPE: Converting API recipe to app recipe")
        print("🍳 API_RECIPE: Title: '\(title)'")
        print("🍳 API_RECIPE: Description: '\(description ?? "nil")'")
        print("🍳 API_RECIPE: ImageURL: '\(imageUrl ?? "nil")'")
        print("🍳 API_RECIPE: ThumbnailURL: '\(thumbnailUrl ?? "nil")'")
        print("🍳 API_RECIPE: Ingredients count: \(ingredients?.count ?? 0)")
        print("🍳 API_RECIPE: Cook time minutes: \(cookTimeMinutes ?? 0)")
        print("🍳 API_RECIPE: Total time minutes: \(totalTimeMinutes ?? 0)")
        print("🍳 API_RECIPE: Steps count: \(steps?.count ?? 0)")
        
        // Debug ingredients
        if let ingredients = ingredients {
            for (index, ingredient) in ingredients.enumerated() {
                print("🍳 API_RECIPE: Ingredient[\(index)]: name='\(ingredient.name)', imageUrl='\(ingredient.imageUrl ?? "nil")'")
            }
        }
        
        let convertedIngredients = (ingredients ?? []).map { $0.asIngredient() }
        print("🍳 API_RECIPE: Converted ingredients count: \(convertedIngredients.count)")
        
        let finalRecipe = Recipe(
            name: title,
            description: description ?? "Recipe from Reel",
            imageUrl: imageUrl ?? thumbnailUrl ?? "",
            ingredients: convertedIngredients,
            cookTime: cookTimeMinutes ?? totalTimeMinutes ?? 25,
            isFromReel: true,
            steps: (steps ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        )
        
        print("✅ API_RECIPE: Recipe conversion completed successfully")
        return finalRecipe
    }
}

class RecipeAPIService {
    func importRecipeFromReel(reelURL: String) async throws -> Recipe {
        print("🚀 IMPORT: Starting recipe import from URL: \(reelURL)")
        
        let importURL = APIConfig.endpoint("import-recipe")
        print("🚀 IMPORT: API endpoint: \(importURL)")
        
        var request = URLRequest(url: importURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        
        do {
            request.httpBody = try JSONEncoder().encode(["link": reelURL])
            print("🚀 IMPORT: Request body created successfully")
        } catch {
            print("❌ IMPORT: Failed to encode request body: \(error)")
            throw APIError.serverError("Failed to create request: \(error.localizedDescription)")
        }
        
        print("🚀 IMPORT: Sending request to server...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ IMPORT: Invalid HTTP response")
            throw APIError.serverError("Invalid server response")
        }
        
        print("🚀 IMPORT: HTTP Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🚀 IMPORT: Raw server response:")
            print(responseString)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("❌ IMPORT: Server error (\(httpResponse.statusCode)): \(errorMessage)")
            throw APIError.serverError("Server connection failed. Please try again.")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            print("🚀 IMPORT: Attempting to decode API response...")
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            print("🚀 IMPORT: API Response decoded - Success: \(apiResponse.success)")
            
            if let error = apiResponse.error {
                print("🚀 IMPORT: API returned error: \(error)")
            }
            
            guard apiResponse.success, let apiRecipe = apiResponse.recipe else {
                let errorMsg = apiResponse.error ?? "Could not extract a recipe from the link."
                print("❌ IMPORT: API failed: \(errorMsg)")
                throw APIError.serverError(errorMsg)
            }
            
            print("🚀 IMPORT: Converting API recipe to app recipe...")
            let finalRecipe = apiRecipe.asRecipe()
            print("✅ IMPORT: Recipe conversion successful - Name: \(finalRecipe.name)")
            print("✅ IMPORT: Recipe ingredients count: \(finalRecipe.ingredients.count)")
            
            return finalRecipe
            
        } catch let decodingError {
            print("❌ IMPORT: JSON decoding failed: \(decodingError)")
            if let decodingError = decodingError as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("❌ IMPORT: Data corrupted: \(context)")
                case .keyNotFound(let key, let context):
                    print("❌ IMPORT: Key not found: \(key) - \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ IMPORT: Type mismatch: \(type) - \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ IMPORT: Value not found: \(type) - \(context)")
                @unknown default:
                    print("❌ IMPORT: Unknown decoding error")
                }
            }
            throw APIError.serverError("Failed to parse server response: \(decodingError.localizedDescription)")
        }
    }
}

enum APIError: LocalizedError {
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message): message
        }
    }
}


// ========================================================================
// MARK: - Data Store (ObservableObject)
// ========================================================================

@MainActor
class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = [] {
        didSet { saveRecipes() }
    }
    @Published var collections: [Collection] = [] {
        didSet { saveCollections() }
    }
    
    @Published var filteredRecipes: [Recipe] = []
    @Published var searchText = "" {
        didSet { filterRecipes() }
    }
    
    @Published var isProcessingReel = false
    @Published var importError: (isPresented: Bool, message: String) = (false, "")
    
    private let apiService = RecipeAPIService()
    private var importTask: Task<Recipe, Error>?
    private var pendingCustomName: String = ""
    
    private let recipesKey = "userRecipes"
    private let collectionsKey = "userCollections"
    
    init() {
        loadData()
        if recipes.isEmpty && collections.isEmpty {
            loadSampleData()
        }
        ensureFavoritesCollectionExists()
        filterRecipes()
    }
    
    // MARK: Collection Management
    
    func createCollection(named name: String) {
        let newCollection = Collection(name: name)
        collections.insert(newCollection, at: 0)
    }
    
    func deleteCollection(_ collection: Collection) {
        // Prevent the protected "Favorites" collection from being deleted
        guard collection.name != "Favorites" else { return }
        collections.removeAll { $0.id == collection.id }
    }
    
    private func ensureFavoritesCollectionExists() {
        if !collections.contains(where: { $0.name == "Favorites" }) {
            let favorites = Collection(name: "Favorites")
            collections.append(favorites)
        }
    }
    
    func toggle(_ recipe: Recipe, in collection: Collection) {
        guard let collectionIndex = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        
        var recipeIDs = Set(collections[collectionIndex].recipeIDs)
        if recipeIDs.contains(recipe.id) {
            recipeIDs.remove(recipe.id)
        } else {
            recipeIDs.insert(recipe.id)
        }
        
        collections[collectionIndex].recipeIDs = Array(recipeIDs)
    }
    
    func recipes(in collection: Collection) -> [Recipe] {
        let recipeIdSet = Set(collection.recipeIDs)
        return recipes.filter { recipeIdSet.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func isRecipe(_ recipe: Recipe, in collection: Collection) -> Bool {
        collection.recipeIDs.contains(recipe.id)
    }
    
    // MARK: Recipe Import Flow
    
    func startImport(url: String, customName: String) {
        pendingCustomName = customName
        isProcessingReel = true
        importError = (false, "")
        
        importTask = Task {
            do {
                let recipe = try await apiService.importRecipeFromReel(reelURL: url)
                await MainActor.run {
                    self.completeImport(with: recipe)
                }
                return recipe
            } catch {
                await MainActor.run {
                    self.handleImportError(error)
                }
                throw error
            }
        }
    }
    
    private func completeImport(with recipe: Recipe) {
        var finalRecipe = recipe
        let trimmedName = pendingCustomName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            finalRecipe.name = trimmedName
        }
        
        recipes.insert(finalRecipe, at: 0)
        filterRecipes()
        
        isProcessingReel = false
        pendingCustomName = ""
        importTask = nil
    }
    
    private func handleImportError(_ error: Error) {
        importError = (true, error.localizedDescription)
        isProcessingReel = false
        pendingCustomName = ""
        importTask = nil
    }
    
    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        isProcessingReel = false
        pendingCustomName = ""
    }
    
    // MARK: Filtering & Data Loading
    
    func filterRecipes() {
        if searchText.isEmpty {
            filteredRecipes = recipes.sorted { $0.createdAt > $1.createdAt }
        } else {
            let lowercasedQuery = searchText.lowercased()
            filteredRecipes = recipes.filter {
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.ingredients.map { $0.name }.joined().lowercased().contains(lowercasedQuery)
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        // Try to load recipes with new format first
        if let recipesData = UserDefaults.standard.data(forKey: recipesKey) {
            do {
                let decodedRecipes = try decoder.decode([Recipe].self, from: recipesData)
                self.recipes = decodedRecipes
            } catch {
                print("⚠️ Failed to load recipes with new format, clearing old data: \(error)")
                // Clear old incompatible data and start fresh
                UserDefaults.standard.removeObject(forKey: recipesKey)
                self.recipes = []
            }
        }
        
        // Load collections (should be compatible)
        if let collectionsData = UserDefaults.standard.data(forKey: collectionsKey) {
            do {
                let decodedCollections = try decoder.decode([Collection].self, from: collectionsData)
                self.collections = decodedCollections
            } catch {
                print("⚠️ Failed to load collections, clearing old data: \(error)")
                UserDefaults.standard.removeObject(forKey: collectionsKey)
                self.collections = []
            }
        }
    }
    
    private func saveRecipes() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: recipesKey)
        }
    }
    
    private func saveCollections() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(collections) {
            UserDefaults.standard.set(encoded, forKey: collectionsKey)
        }
    }
    
    private func loadSampleData() {
        self.recipes = [
            Recipe(name: "Classic Spaghetti Carbonara", description: "A creamy Italian pasta dish.", imageUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=400", ingredients: [
                Ingredient(name: "200g Spaghetti", imageUrl: "https://images.unsplash.com/photo-1551892589-865f69869476?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "100g Guanciale", imageUrl: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "2 large Eggs", imageUrl: "https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "50g Pecorino Romano", imageUrl: "https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "Black Pepper", imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&q=80&w=400")
            ], cookTime: 20, steps: ["Boil spaghetti.", "Cook guanciale.", "Mix eggs and cheese.", "Combine all ingredients."]),
            Recipe(name: "Veg Stir Fry Soupy Udon Noodles", description: "Quick and healthy udon noodle soup.", imageUrl: "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&q=80&w=400", ingredients: [
                Ingredient(name: "1 lb Chicken Breasts", imageUrl: "https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "1 tbsp Soy Sauce", imageUrl: "https://images.unsplash.com/photo-1609501676725-7186f734b8d8?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "Bell Peppers", imageUrl: "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "Carrots", imageUrl: "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "Broccoli", imageUrl: "https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "Garlic", imageUrl: "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=400"),
                Ingredient(name: "Ginger", imageUrl: "https://images.unsplash.com/photo-1615485500704-8e990f9900f7?auto=format&fit=crop&q=80&w=400")
            ], cookTime: 25, steps: ["Marinate chicken.", "Stir-fry chicken.", "Add veggies.", "Add sauce and serve."])
        ]
        if let firstRecipe = self.recipes.first {
            self.collections = [
                Collection(name: "Favorites")
            ]
        }
    }
}

// ========================================================================
// MARK: - Main Views
// ========================================================================

struct ContentView: View {
    @StateObject private var recipeStore = RecipeStore()
    
    var body: some View {
        NavigationView {
            HomeView()
        }
        .environmentObject(recipeStore)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    
    // --- STATE VARIABLES FOR NEW FLOW ---
    @State private var showingImportOptions = false   // For the new pop-up menu
    @State private var showingImportSheet = false     // To show the original video import
    @State private var showingScanKitchenPage = false // To show the new scan page
    // --- END ---
    
    @State private var showingCreateCollectionSheet = false
    @State private var recipeToManage: Recipe?
    @State private var isCollectionsExpanded = true
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                SearchBar(text: $recipeStore.searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                
                ScrollView {
                    // ... your existing collections and recipe grid code remains the same ...
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isCollectionsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Collections")
                                    .font(.title2.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .rotationEffect(.degrees(isCollectionsExpanded ? 90 : 0))
                            }
                            .foregroundColor(.primary)
                            .padding()
                        }
                        
                        if isCollectionsExpanded {
                            CollectionsRowView(showingCreateSheet: $showingCreateCollectionSheet)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.animation(.easeInOut(duration: 0.2))
                                ))
                        }
                    }
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(recipeStore.filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCard(recipe: recipe)
                                    .contextMenu {
                                        Button { recipeToManage = recipe } label: {
                                            Label("Add to Collection", systemImage: "folder.badge.plus")
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .onLongPressGesture(minimumDuration: 0.5) {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                recipeToManage = recipe
                            }
                        }
                    }
                    .padding([.horizontal, .top])
                    
                    if recipeStore.filteredRecipes.isEmpty && !recipeStore.searchText.isEmpty {
                        Spacer(minLength: 80)
                        EmptyStateView(hasRecipes: true, searchText: recipeStore.searchText)
                    }
                }
            }
            .navigationTitle("My Recipes")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                // --- MODIFIED TOOLBAR ITEM ---
                // This button now triggers the action sheet instead of going directly to the import sheet.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImportOptions = true
                    } label: {
                        Label {
                            Text("Import")
                        } icon: {
                            Image(systemName: "line.3.horizontal")
                                .rotationEffect(.degrees(90))
                        }
                    }
                }
                // --- END MODIFICATION ---
            }
            // --- ALL SHEET MODIFIERS ---
            .sheet(isPresented: $showingImportSheet) { ImportReelSheet() }
            .sheet(isPresented: $showingScanKitchenPage) { UserInfoView() } // For the new page
            .sheet(isPresented: $showingCreateCollectionSheet) { NewCollectionSheet() }
            .sheet(item: $recipeToManage) { recipe in
                AddToCollectionSheet(recipe: recipe)
            }
            .alert("Import Error", isPresented: $recipeStore.importError.isPresented) {
                Button("OK") { }
            } message: {
                Text(recipeStore.importError.message)
            }
        }
        .overlay {
            if recipeStore.recipes.isEmpty {
                EmptyStateView(hasRecipes: false, searchText: "")
            }
        }
        .overlay(processingOverlay)
        .animation(.default, value: recipeStore.filteredRecipes)
        .onReceive(NotificationCenter.default.publisher(for: .showUserProfile)) { _ in
            showingScanKitchenPage = true
        }
        // --- ACTION SHEET IMPLEMENTATION ---
        // This presents the user with the two choices.
        .actionSheet(isPresented: $showingImportOptions) {
            ActionSheet(title: Text("More"),
                        message: Text("Choose an option"),
                        buttons: [
                            .default(Text("User Profile")) {
                                showingScanKitchenPage = true
                            },
                            .default(Text("Import Video")) {
                                showingImportSheet = true
                            },
                            .cancel()
                        ])
        }
        // --- END ---
    }
    
    @ViewBuilder
    private var processingOverlay: some View {
        if recipeStore.isProcessingReel {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
            
            ProcessingIndicator(onCancel: {
                recipeStore.cancelImport()
            })
            .transition(.scale.combined(with: .opacity))
        }
    }
}

struct CollectionDetailView: View {
    let collection: Collection
    @EnvironmentObject var store: RecipeStore
    @State private var showingAddRecipesSheet = false
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        let recipesInCollection = store.recipes(in: collection)
        
        Group {
            if recipesInCollection.isEmpty {
                emptyState
            } else {
                recipeGrid(recipes: recipesInCollection)
            }
        }
        .navigationTitle(collection.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddRecipesSheet = true
                } label: {
                    Label("Add Recipes", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecipesSheet) {
            AddRecipesToCollectionSheet(collection: collection)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Recipes Yet")
                .font(.title2).bold()
            Text("Long-press any recipe on Home to add it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        
    }
    
    private func recipeGrid(recipes: [Recipe]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: recipe.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RecipeImagePlaceholder(isFromReel: recipe.isFromReel)
                }
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.name).font(.largeTitle).fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            Label("\(recipe.cookTime) min", systemImage: "clock")
                            if recipe.isFromReel {
                                Label("Reel Import", systemImage: "video.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink.cornerRadius(8))
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        if !recipe.description.isEmpty {
                            Text(recipe.description)
                                .padding(.top, 4)
                        }
                    }
                    
                    HealthReport(recipe: recipe)
                    
                    IngredientsView(recipe: recipe)
                    
                    InstructionsView(recipe: recipe)
                    
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
    }
}

// ========================================================================
// MARK: - Sheet Views
// ========================================================================

struct NewCollectionSheet: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Name")) {
                    TextField("e.g., Weeknight Meals", text: $name)
                        .focused($isFocused)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        store.createCollection(named: name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct AddToCollectionSheet: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    
    var body: some View {
        NavigationView {
            List {
                if store.collections.isEmpty {
                    Text("No collections found.\nCreate one from the Home screen.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ForEach(store.collections) { collection in
                        Button(action: {
                            store.toggle(recipe, in: collection)
                        }) {
                            HStack {
                                Text(collection.name)
                                Spacer()
                                if store.isRecipe(recipe, in: collection) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add '\(recipe.name)' to...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AddRecipesToCollectionSheet: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let collection: Collection
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.recipes) { recipe in
                    Button(action: {
                        store.toggle(recipe, in: collection)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recipe.name).lineLimit(1)
                                Text("\(recipe.cookTime) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if store.isRecipe(recipe, in: collection) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add to '\(collection.name)'")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ImportReelSheet: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: ImportStep = .linkInput
    @State private var reelLink = ""
    @State private var customName = ""
    
    @FocusState private var isLinkFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool
    
    enum ImportStep: Int {
        case linkInput
        case nameInput
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<2) { index in
                            Circle()
                                .fill(index <= currentStep.rawValue ? Color.pink : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 12)
                    
                    HStack(spacing: 12) {
                        Image(systemName: currentStep == .linkInput ? "link" : "pencil")
                            .font(.title2)
                            .foregroundColor(.pink)
                            .frame(width: 32, height: 32)
                            .background(Color.pink.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentStep == .linkInput ? "Add Instagram Link" : "Name Your Recipe")
                                .font(.title3).fontWeight(.semibold)
                            Text(currentStep == .linkInput ? "Paste your Instagram Reel URL" : "Optional: Give it a custom name")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 24) {
                    switch currentStep {
                    case .linkInput:
                        LinkInputContent(reelLink: $reelLink, isLinkFieldFocused: $isLinkFieldFocused)
                    case .nameInput:
                        NameInputContent(customName: $customName, isNameFieldFocused: $isNameFieldFocused)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: handlePrimaryAction) {
                        HStack(spacing: 8) {
                            if currentStep == .nameInput { Image(systemName: "sparkles") }
                            Text(currentStep == .linkInput ? "Continue" : "Import Recipe").fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent).tint(.pink).disabled(currentStep == .linkInput && !isLinkValid)
                    
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if currentStep == .linkInput {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isLinkFieldFocused = true }
            }
        }
    }
    
    private var isLinkValid: Bool {
        let trimmed = reelLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && (
            trimmed.contains("instagram.com/reel/") ||
            trimmed.contains("instagram.com/p/") ||
            trimmed.contains("instagram.com/reels/")
        )
    }
    
    private func handlePrimaryAction() {
        switch currentStep {
        case .linkInput:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .nameInput
                isLinkFieldFocused = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isNameFieldFocused = true }
            
        case .nameInput:
            recipeStore.startImport(url: reelLink, customName: customName)
            dismiss()
        }
    }
}


// ========================================================================
// MARK: - Reusable Component Views
// ========================================================================

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: recipe.imageUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RecipeImagePlaceholder(isFromReel: false)
            }
            .frame(height: 120)
            .clipped()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 44, alignment: .top)
                    .minimumScaleFactor(0.8)
                
                Label("\(recipe.cookTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
        }
        .background(.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct CollectionCard: View {
    let collection: Collection
    var onDelete: () -> Void
    
    @EnvironmentObject var store: RecipeStore
    @State private var showingDeleteAlert = false
    
    private var recipeCount: Int {
        store.recipes(in: collection).count
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // Title area with flexible height
                Text(collection.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Recipe count at bottom
                Label("\(recipeCount) \(recipeCount == 1 ? "recipe" : "recipes")", systemImage: "tray.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(width: 160, height: 100)
            
            // Menu overlay
            if collection.name != "Favorites" {
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Collection", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .alert("Delete '\(collection.name)'?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure? This action cannot be undone.")
        }
    }
}
struct CollectionsRowView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @Binding var showingCreateSheet: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(recipeStore.collections) { collection in
                    NavigationLink(destination: CollectionDetailView(collection: collection)) {
                        CollectionCard(collection: collection) {
                            recipeStore.deleteCollection(collection)
                        }
                    }
                    .buttonStyle(.plain)
                }
                AddCollectionCard(action: {
                    showingCreateSheet = true
                })
            }
            .padding()
        }
        .frame(height: 124)
    }
}

struct AddCollectionCard: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(Color.secondary.opacity(0.6))
                
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                    Text("New")
                        .font(.headline)
                }
                .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search recipes or ingredients...", text: $text)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct ProcessingIndicator: View {
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5).tint(.pink)
            VStack(spacing: 8) {
                Text("Extracting Recipe from Reel...").font(.headline).fontWeight(.semibold)
                Text("This can take up to 90 seconds.\nPlease wait.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            Button("Cancel", action: onCancel).buttonStyle(.bordered).controlSize(.large).tint(.secondary)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20)
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}

struct EmptyStateView: View {
    let hasRecipes: Bool
    let searchText: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasRecipes ? "magnifyingglass" : "fork.knife.circle")
                .font(.system(size: 60)).foregroundColor(.secondary)
            Text(titleText)
                .font(.headline)
            Text(subtitleText)
                .font(.subheadline).foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center).padding()
    }
    
    private var titleText: String {
        if !searchText.isEmpty {
            return "No results for \"\(searchText)\""
        }
        return hasRecipes ? "" : "No Recipes Yet"
    }
    
    private var subtitleText: String {
        if !searchText.isEmpty {
            return "Try a different search."
        }
        return hasRecipes ? "" : "Import a recipe to get started."
    }
}

struct RecipeImagePlaceholder: View {
    let isFromReel: Bool
    
    var body: some View {
        ZStack {
            Rectangle().fill(Color.gray.opacity(0.1))
            Image(systemName: isFromReel ? "video" : "fork.knife")
                .font(.largeTitle)
                .foregroundColor(isFromReel ? .pink.opacity(0.8) : .orange.opacity(0.8))
        }
    }
}

struct DetailSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2).fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 10) { content }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
}


// MARK: Import Sheet Subviews

struct LinkInputContent: View {
    @Binding var reelLink: String
    @FocusState.Binding var isLinkFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // URL Input Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Instagram URL")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                TextField("Paste Instagram reel link here", text: $reelLink)
                    .focused($isLinkFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.body)
            }
            
            // Tips Section
            VStack(spacing: 16) {
                // Tips Header
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("Quick Tips")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Tips List
                VStack(alignment: .leading, spacing: 12) {
                    TipRow(icon: "square.and.arrow.up",
                           text: "Share → Copy Link from Instagram")
                    
                    TipRow(icon: "text.alignleft",
                           text: "Works with recipe descriptions")
                    
                    TipRow(icon: "clock",
                           text: "Processing takes 30-90 seconds")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, 4) // Subtle padding for better visual balance
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct NameInputContent: View {
    @Binding var customName: String
    @FocusState.Binding var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill").foregroundColor(.orange)
                    Text("Custom Name").font(.subheadline).fontWeight(.medium)
                    Spacer()
                    Text("Optional").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1)).cornerRadius(8)
                }
                TextField("Enter recipe name...", text: $customName)
                    .focused($isNameFieldFocused).textFieldStyle(.roundedBorder)
            }
            HStack(spacing: 12) {
                Image(systemName: "magic.wand.and.stars").foregroundColor(.purple).font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text("We'll handle the rest!").font(.subheadline).fontWeight(.medium)
                    Text("Leave blank to use the original recipe name. You can always edit it later.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(16).background(Color.purple.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.2), lineWidth: 1)).cornerRadius(12)
        }
    }
}

