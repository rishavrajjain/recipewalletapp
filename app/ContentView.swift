import SwiftUI
import Foundation

// MARK: - Brand Colors
extension Color {
    // Primary brand colors matching the new app icon
    static let brandYellow = Color(red: 1.0, green: 0.8, blue: 0.0)       // Pure vibrant yellow from icon
    static let brandWhite = Color(red: 0.98, green: 0.98, blue: 1.0)      // Elegant white from pepper
    static let brandGray = Color(red: 0.45, green: 0.45, blue: 0.5)       // Sophisticated gray
    static let brandDarkGray = Color(red: 0.25, green: 0.25, blue: 0.3)   // Deep contrast
    
    // Accent colors
    static let brandGold = Color(red: 1.0, green: 0.75, blue: 0.0)        // Rich golden accent
    static let brandSilver = Color(red: 0.7, green: 0.7, blue: 0.75)      // Silver accent
}

// MARK: - Notification Names
extension Notification.Name {
    static let showUserProfile = Notification.Name("showUserProfile")
}

// ========================================================================
// MARK: - Models
// ========================================================================

// MARK: - Ingredient Categories
enum IngredientCategory: String, CaseIterable, Codable {
    case myIngredients = "My Ingredients"
    case fruitVegetables = "Fruit & Vegetables"
    case meatPoultryFish = "Meat, Poultry, Fish"
    case pastaRiceGrains = "Pasta, Rice & Grains"
    case herbsSpices = "Herbs & Spices"
    case cupboardStaples = "Cupboard Staples"
    case dairy = "Dairy"
    case cannedJarred = "Canned & Jarred"
    case other = "Other"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .myIngredients: return "plus.circle.fill"
        case .fruitVegetables: return "leaf.fill"
        case .meatPoultryFish: return "fish.fill"
        case .pastaRiceGrains: return "fork.knife"
        case .herbsSpices: return "sparkles"
        case .cupboardStaples: return "cabinet.fill"
        case .dairy: return "drop.fill"
        case .cannedJarred: return "cylinder.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .myIngredients: return .black
        case .fruitVegetables: return .green
        case .meatPoultryFish: return .red
        case .pastaRiceGrains: return .orange
        case .herbsSpices: return .purple
        case .cupboardStaples: return .brown
        case .dairy: return .blue
        case .cannedJarred: return .gray
        case .other: return .secondary
        }
    }
}

// MARK: - Nutrition Information
struct Nutrition: Codable, Hashable {
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fats: Int?
    let portions: Int?
    
    init(calories: Int? = nil, protein: Int? = nil, carbs: Int? = nil, fats: Int? = nil, portions: Int? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.portions = portions
    }
}

// MARK: - Backend Compatible Models
struct NutritionInfo: Codable, Hashable {
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fats: Int?
    let portions: Int?
    
    init(calories: Int? = nil, protein: Int? = nil, carbs: Int? = nil, fats: Int? = nil, portions: Int? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.portions = portions
    }
    
    // Convert from our Nutrition model
    init(from nutrition: Nutrition) {
        self.calories = nutrition.calories
        self.protein = nutrition.protein
        self.carbs = nutrition.carbs
        self.fats = nutrition.fats
        self.portions = nutrition.portions
    }
}

struct CategorizedIngredient: Codable, Hashable {
    let name: String
    let category: String
    
    // Convert from our Ingredient model
    init(from ingredient: Ingredient) {
        self.name = ingredient.name
        self.category = ingredient.category.rawValue
    }
}

// MARK: - Ingredient Model
struct Ingredient: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: IngredientCategory
    
    enum CodingKeys: String, CodingKey {
        case name
        case category
    }
    
    // Helper initializer for backward compatibility
    init(name: String, category: IngredientCategory = .other) {
        self.name = name
        self.category = category
    }
    
    // Custom decoder to handle potential data issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedName = try container.decode(String.self, forKey: .name)
        let categoryString = try container.decodeIfPresent(String.self, forKey: .category) ?? "Other"
        
        // Validate that name is not empty
        guard !decodedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Ingredient name cannot be empty"
            ))
        }
        
        // Map category string to enum, fallback to .other if not found
        self.category = IngredientCategory(rawValue: categoryString) ?? .other
        self.name = decodedName
    }
    
    // Computed property that returns a placeholder image URL based on category
    var categoryImageURL: URL? {
        let keyword = category.displayName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "food"
        let fallbackURL = URL(string: "https://loremflickr.com/400/400/\(keyword)")
        return fallbackURL
    }
}

// MARK: - Recipe Difficulty
enum RecipeDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        }
    }
}

// MARK: - Recipe Model
struct Recipe: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    let description: String
    let imageUrl: String
    let prepTime: Int?
    let cookTime: Int?
    let difficulty: RecipeDifficulty?
    let nutrition: Nutrition?
    let ingredients: [Ingredient]
    let isFromReel: Bool
    let extractedFrom: String?  // NEW: "instagram", "tiktok", "youtube", or "website"
    let creatorHandle: String?  // NEW: Creator's username with @ prefix
    let creatorName: String?    // NEW: Creator's display name
    let originalUrl: String?    // NEW: Original reel/post URL for opening in browser/app
    let steps: [String]
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, description: String, imageUrl: String, prepTime: Int? = nil, cookTime: Int? = nil, difficulty: RecipeDifficulty? = nil, nutrition: Nutrition? = nil, ingredients: [Ingredient], isFromReel: Bool = false, extractedFrom: String? = nil, creatorHandle: String? = nil, creatorName: String? = nil, originalUrl: String? = nil, steps: [String], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.difficulty = difficulty
        self.nutrition = nutrition
        self.ingredients = ingredients
        self.isFromReel = isFromReel
        self.extractedFrom = extractedFrom
        self.creatorHandle = creatorHandle
        self.creatorName = creatorName
        self.originalUrl = originalUrl
        self.steps = steps
        self.createdAt = createdAt
    }
    
    // Backward compatibility initializer for string ingredients (deprecated)
    init(id: String = UUID().uuidString, name: String, description: String, imageUrl: String, ingredients: [String], cookTime: Int? = nil, isFromReel: Bool = false, steps: [String], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.prepTime = nil
        self.cookTime = cookTime
        self.difficulty = nil
        self.nutrition = nil
        self.ingredients = ingredients.map { Ingredient(name: $0, category: .other) }
        self.isFromReel = isFromReel
        self.extractedFrom = nil
        self.creatorHandle = nil
        self.creatorName = nil
        self.originalUrl = nil
        self.steps = steps
        self.createdAt = createdAt
    }
    
    // Computed properties for UI convenience
    var totalTime: Int? {
        let prep = prepTime ?? 0
        let cook = cookTime ?? 0
        let total = prep + cook
        return total > 0 ? total : nil
    }
    
    var difficultyText: String {
        return difficulty?.displayName ?? "Unknown"
    }
    
    var ingredientsByCategory: [IngredientCategory: [Ingredient]] {
        return Dictionary(grouping: ingredients, by: { $0.category })
    }
    
    // Platform and creator convenience properties
    var platformDisplayName: String {
        switch extractedFrom?.lowercased() {
        case "instagram": return "Instagram"
        case "tiktok": return "TikTok"
        case "youtube": return "YouTube"
        case "website": return "Website"
        default: return "Unknown"
        }
    }
    
    var platformIcon: String {
        switch extractedFrom?.lowercased() {
        case "instagram": return "camera.fill"
        case "tiktok": return "music.note"
        case "youtube": return "play.rectangle.fill"
        case "website": return "globe"
        default: return "link"
        }
    }
    
    var hasCreatorInfo: Bool {
        return creatorHandle != nil || creatorName != nil
    }
    
    var displayCreatorName: String? {
        // Prioritize username (@handle) as it's more stable than display names
        if let handle = creatorHandle, !handle.isEmpty {
            return handle
        } else if let name = creatorName, !name.isEmpty {
            return name
        }
        return nil
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

struct ShoppingListItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let category: IngredientCategory?
    let fromRecipe: String?
    let addedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case category
        case fromRecipe
        case addedAt
    }
    
    init(name: String, category: IngredientCategory? = nil, fromRecipe: String? = nil) {
        self.name = name
        self.category = category
        self.fromRecipe = fromRecipe
        self.addedAt = Date()
    }
}

// ========================================================================
// MARK: - API Service Layer
// ========================================================================

private struct APIResponse: Decodable {
    let success: Bool
    let recipe: APIRecipe?
    let error: String?
    let source: String?
}

private struct APIIngredient: Decodable {
    let name: String
    let category: String? // Changed from imageUrl to category
    
    // Custom decoder to handle both string and object formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            // Backend sent ingredients as strings
            self.name = stringValue
            self.category = nil // No category for string ingredients
        } else if let dict = try? container.decode([String: String].self) {
            // Backend sent ingredients as objects
            self.name = dict["name"] ?? ""
            self.category = dict["category"] // Assuming category is sent as a string
        } else {
            throw DecodingError.typeMismatch(APIIngredient.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected either String or Dictionary for ingredient"
            ))
        }
    }
    
    func asIngredient() -> Ingredient {
        Ingredient(name: name, category: IngredientCategory(rawValue: category ?? "Other") ?? .other)
    }
}

private struct APIRecipe: Decodable {
    let title: String
    let description: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    let ingredients: [APIIngredient]?
    let prepTime: Int?
    let cookTime: Int?
    let difficulty: String?
    let nutrition: Nutrition?
    let extractedFrom: String?  // NEW: Platform source
    let creatorHandle: String?  // NEW: Creator's handle
    let creatorName: String?    // NEW: Creator's name
    let originalUrl: String?    // NEW: Original reel/post URL
    let steps: [String]?
    
    func asRecipe() -> Recipe {
        // Only print the specific values requested
        print("Prep time: \(prepTime?.description ?? "nil")")
        print("Cook time: \(cookTime?.description ?? "nil")")
        print("Creator name: \(creatorName ?? "nil")")
        print("Creator handle: \(creatorHandle ?? "nil")")
        print("Original URL: \(originalUrl ?? "nil")")
        
        let convertedIngredients = (ingredients ?? []).map { $0.asIngredient() }
        
        // For Instagram Reels, prioritize thumbnail as it's more representative of video content
        let finalImageUrl: String = {
            if let thumbnail = thumbnailUrl, !thumbnail.trimmingCharacters(in: .whitespaces).isEmpty {
                return thumbnail
            } else if let image = imageUrl, !image.trimmingCharacters(in: .whitespaces).isEmpty {
                return image
            } else {
                return ""
            }
        }()
        
        let finalRecipe = Recipe(
            name: title,
            description: description ?? "Recipe from Reel",
            imageUrl: finalImageUrl,
            prepTime: prepTime,
            cookTime: cookTime,
            difficulty: RecipeDifficulty(rawValue: difficulty ?? "Medium"),
            nutrition: nutrition,
            ingredients: convertedIngredients,
            isFromReel: true,
            extractedFrom: extractedFrom,
            creatorHandle: creatorHandle,
            creatorName: creatorName,
            originalUrl: self.originalUrl,
            steps: (steps ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        )
        
        // Debug: Print what was actually stored in the Recipe object
        print("Final Recipe - Prep time: \(finalRecipe.prepTime?.description ?? "nil")")
        print("Final Recipe - Cook time: \(finalRecipe.cookTime?.description ?? "nil")")
        print("Final Recipe - Total time: \(finalRecipe.totalTime?.description ?? "nil")")
        
        return finalRecipe
    }
}

class RecipeAPIService {
    func wakeUpServer() async {
        do {
            let healthURL = APIConfig.endpoint("health")
            
            var request = URLRequest(url: healthURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 10 // Short timeout for health check
            
            let (_, _) = try await URLSession.shared.data(for: request)
            
        } catch {
            // Don't throw error - this is just a wake-up call, not critical
        }
    }
    
    func importRecipeFromReel(reelURL: String) async throws -> Recipe {
        let importURL = APIConfig.endpoint("import-recipe")
        
        var request = URLRequest(url: importURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        
        do {
            request.httpBody = try JSONEncoder().encode(["link": reelURL])
        } catch {
            throw APIError.serverError("Failed to create request: \(error.localizedDescription)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid server response")
        }
        
        guard httpResponse.statusCode == 200 else {
            // Handle specific error responses from the new universal importer
            if httpResponse.statusCode == 500 {
                // Try to parse the error detail from the response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = errorData["detail"] as? String {
                    throw APIError.serverError(detail)
                } else {
                    throw APIError.serverError("Failed to extract a valid recipe from the provided link. The content may not be a recipe or the website is not supported.")
                }
            } else {
                throw APIError.serverError("Server connection failed. Please try again.")
            }
        }
        
        let decoder = JSONDecoder()
        // Backend already sends camelCase, no conversion needed
        
        do {
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            
            guard apiResponse.success, let apiRecipe = apiResponse.recipe else {
                let errorMsg = apiResponse.error ?? "Could not extract a recipe from the link."
                throw APIError.serverError(errorMsg)
            }
            
            let finalRecipe = apiRecipe.asRecipe()
            return finalRecipe
            
        } catch let decodingError {
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
    @Published var shoppingList: [ShoppingListItem] = [] {
        didSet { saveShoppingList() }
    }
    
    @Published var filteredRecipes: [Recipe] = []
    @Published var searchText = "" {
        didSet { filterRecipes() }
    }
    
    @Published var isProcessingReel = false
    @Published var importError: (isPresented: Bool, message: String) = (false, "")
    @Published var loadingRecipeName = ""
    @Published var shouldDismissToHome = false
    @Published var isFirstTimeUser = true
    
    private let apiService = RecipeAPIService()
    private var importTask: Task<Recipe, Error>?
    private var pendingCustomName: String = ""
    
    private let recipesKey = "userRecipes"
    private let collectionsKey = "userCollections"
    private let shoppingListKey = "userShoppingList"
    private let firstTimeUserKey = "isFirstTimeUser"
    
    init() {
        loadData()
        
        // Check if this is the first time user
        self.isFirstTimeUser = !UserDefaults.standard.bool(forKey: firstTimeUserKey)
        
        // Clean up old data structure
        cleanupOldCollections()
        
        if recipes.isEmpty {
            loadSampleData()
        } else {
            // If we have existing recipes but no Meal Preps collection, create it
            ensureMealPrepsCollectionExists()
        }
        filterRecipes()
    }
    
    private func cleanupOldCollections() {
        // Remove any old "Favorites" collections
        collections.removeAll { $0.name == "Favorites" }
        
        // If we have recipes but the Meal Preps collection is empty, fix it
        if let mealPrepsIndex = collections.firstIndex(where: { $0.name == "Meal Preps" }),
           collections[mealPrepsIndex].recipeIDs.isEmpty && !recipes.isEmpty {
            collections[mealPrepsIndex].recipeIDs = recipes.map { $0.id }
        }
    }
    
    // MARK: Collection Management
    
    func createCollection(named name: String) {
        let newCollection = Collection(name: name)
        collections.insert(newCollection, at: 0)
    }
    
    func deleteCollection(_ collection: Collection) {
        // Prevent the protected "Meal Preps" collection from being deleted
        guard collection.name != "Meal Preps" else { return }
        collections.removeAll { $0.id == collection.id }
    }
    
    private func ensureMealPrepsCollectionExists() {
        if !collections.contains(where: { $0.name == "Meal Preps" }) {
            // Create Meal Preps collection with all existing recipes
            let mealPreps = Collection(
                name: "Meal Preps",
                recipeIDs: recipes.map { $0.id }
            )
            collections.append(mealPreps)
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
    
    // MARK: Navigation
    
    func navigateToHome() {
        shouldDismissToHome = true
        // Reset the flag after a brief delay to allow views to react
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldDismissToHome = false
        }
    }
    
    func markFirstImportCompleted() {
        isFirstTimeUser = false
        UserDefaults.standard.set(true, forKey: firstTimeUserKey)
    }
    
    // MARK: Recipe Management
    
    func deleteRecipe(_ recipe: Recipe) {
        // Remove from recipes array
        recipes.removeAll { $0.id == recipe.id }
        
        // Remove from all collections
        for index in collections.indices {
            collections[index].recipeIDs.removeAll { $0 == recipe.id }
        }
        
        // Update filtered recipes
        filterRecipes()
    }
    
    // MARK: Shopping List Management
    
    func addIngredientsToShoppingList(_ ingredients: [Ingredient]) {
        var newItems: [ShoppingListItem] = []
        
        for ingredient in ingredients {
            // Check if ingredient is already in shopping list
            if !shoppingList.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() }) {
                let item = ShoppingListItem(name: ingredient.name, category: ingredient.category)
                newItems.append(item)
            }
        }
        
        // Insert new items at the beginning of the list (most recent first)
        shoppingList.insert(contentsOf: newItems, at: 0)
    }
    
    func removeFromShoppingList(_ item: ShoppingListItem) {
        shoppingList.removeAll { $0.id == item.id }
    }
    
    func clearShoppingList() {
        shoppingList.removeAll()
    }
    
    // MARK: Recipe Import Flow
    
    func startImport(url: String, customName: String) {
        pendingCustomName = customName
        isProcessingReel = true
        importError = (false, "")
        loadingRecipeName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        loadingRecipeName = ""
        importTask = nil
    }
    
    private func handleImportError(_ error: Error) {
        importError = (true, error.localizedDescription)
        isProcessingReel = false
        pendingCustomName = ""
        loadingRecipeName = ""
        importTask = nil
    }
    
    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        isProcessingReel = false
        pendingCustomName = ""
        loadingRecipeName = ""
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
                UserDefaults.standard.removeObject(forKey: collectionsKey)
                self.collections = []
            }
        }
        
        // Load shopping list
        if let shoppingListData = UserDefaults.standard.data(forKey: shoppingListKey) {
            do {
                let decodedShoppingList = try decoder.decode([ShoppingListItem].self, from: shoppingListData)
                self.shoppingList = decodedShoppingList
            } catch {
                UserDefaults.standard.removeObject(forKey: shoppingListKey)
                self.shoppingList = []
            }
        }

        // Load any data stored in Firestore for the current user
        RecipeCloudStore.shared.load { recipes, collections, list in
            if !recipes.isEmpty { self.recipes = recipes }
            if !collections.isEmpty { self.collections = collections }
            if !list.isEmpty { self.shoppingList = list }
        }
    }
    
    private func saveRecipes() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: recipesKey)
        }
        RecipeCloudStore.shared.save(recipes: recipes, collections: collections, shoppingList: shoppingList)
    }
    
    private func saveCollections() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(collections) {
            UserDefaults.standard.set(encoded, forKey: collectionsKey)
        }
        RecipeCloudStore.shared.save(recipes: recipes, collections: collections, shoppingList: shoppingList)
    }
    
    private func saveShoppingList() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(shoppingList) {
            UserDefaults.standard.set(encoded, forKey: shoppingListKey)
        }
        RecipeCloudStore.shared.save(recipes: recipes, collections: collections, shoppingList: shoppingList)
    }
    
    private func loadSampleData() {
        self.recipes = [
            // Recipe 1: High Protein Chipotle Chicken Bowls (Fresh from Instagram)
            Recipe(
                name: "High Protein Chipotle Chicken Bowls with Charred Sweetcorn & Zesty Rice",
                description: "A delicious, high-protein meal prep bowl featuring juicy chipotle chicken, smoky charred sweetcorn, and zesty black bean rice. Perfect for a healthy lunch or dinner packed with flavor and nutrients.",
                imageUrl: "https://instagram.fblr1-5.fna.fbcdn.net/v/t51.2885-15/490219596_18002752127761551_3326422995220106638_n.jpg?stp=dst-jpg_e15_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6ImltYWdlX3VybGdlbi43MjB4MTI4MC5zZHIuZjc1NzYxLmRlZmF1bHRfY292ZXJfZnJhbWUuYzIifQ&_nc_ht=instagram.fblr1-5.fna.fbcdn.net&_nc_cat=103&_nc_oc=Q6cZ2QGWv1XTFjygrBCwL7cQhV24sOnQSjkSmX-HVpP80nXTlfX3SRQ6HWTbW64g8GlBOZM&_nc_ohc=blLmkhHnFuoQ7kNvwExW24K&_nc_gid=QpuivisUUIwMVHbziw70Lw&edm=ANTKIIoBAAAA&ccb=7-5&oh=00_AfSDqCm7CuE1UJhDflKTDPb32vFREVK891kOESBZM42sZA&oe=6893E2A4&_nc_sid=d885a2",
                prepTime: 15,
                cookTime: 18,
                difficulty: .medium,
                nutrition: Nutrition(calories: 610, protein: 50, carbs: 60, fats: 19, portions: 3),
                ingredients: [
                    Ingredient(name: "600g Chicken Thigh Fillet", category: .meatPoultryFish),
                    Ingredient(name: "1.5 tsp Paprika", category: .herbsSpices),
                    Ingredient(name: "1 tsp Onion Powder", category: .herbsSpices),
                    Ingredient(name: "1 tsp Garlic Powder", category: .herbsSpices),
                    Ingredient(name: "1 tsp Cumin", category: .herbsSpices),
                    Ingredient(name: "1 lime (divided)", category: .fruitVegetables),
                    Ingredient(name: "3 tbsp Chipotle Sauce (divided)", category: .cannedJarred),
                    Ingredient(name: "1 tbsp Olive Oil", category: .cupboardStaples),
                    Ingredient(name: "140g Sweetcorn Kernels", category: .fruitVegetables),
                    Ingredient(name: "1 tbsp Salted Butter", category: .dairy),
                    Ingredient(name: "1/2 tsp Paprika (for corn)", category: .herbsSpices),
                    Ingredient(name: "1/3 Red Onion", category: .fruitVegetables),
                    Ingredient(name: "Few sprigs Coriander (divided)", category: .herbsSpices),
                    Ingredient(name: "225g Uncooked Long Grain Rice", category: .pastaRiceGrains),
                    Ingredient(name: "200g Black Beans", category: .cannedJarred),
                    Ingredient(name: "3 tbsp Sour Cream", category: .dairy),
                    Ingredient(name: "Chilli Powder (optional, for corn)", category: .herbsSpices)
                ],
                isFromReel: true,
                extractedFrom: "instagram",
                creatorHandle: "@foodinfivemins",
                creatorName: "Food In 5 | Bill",
                originalUrl: "https://www.instagram.com/foodinfivemins/reel/DIgNIdxyZpr/?hl=en",
                steps: [
                    "Cut chicken thigh fillets into bite-sized pieces (5 minutes).",
                    "In a large bowl, combine chicken with 1.5 tsp paprika, 1 tsp onion powder, 1 tsp garlic powder, 1 tsp cumin, juice of 1/2 lime, 2 tbsp chipotle sauce, and 1 tbsp olive oil. Mix well to coat. Marinate for at least 15 minutes.",
                    "Meanwhile, finely chop 1/3 red onion and roughly chop a few sprigs of coriander. Set aside.",
                    "Rinse 225g uncooked long grain rice under cold water. Measure out 200g black beans and drain if canned.",
                    "Cook rice according to package instructions (about 18 minutes).",
                    "Heat a medium-hot pan. Add marinated chicken and fry for 8-10 minutes, flipping halfway, until cooked through and slightly charred. Remove and set aside.",
                    "In the same pan, add 1 tbsp salted butter. Add 140g sweetcorn kernels, 1/2 tsp paprika, a pinch of chilli powder (optional), and 1 tsp chipotle sauce. Sauté for 5-6 minutes until corn is slightly charred.",
                    "Reduce heat and stir in juice of 1/2 lime, chopped red onion, and a few sprigs of coriander. Cook for 1-2 more minutes. Remove from heat.",
                    "In a large bowl, combine cooked rice, black beans, juice of 1/2 lime, and a few sprigs of chopped coriander. Mix well.",
                    "To serve, divide rice mixture among bowls. Top with chipotle chicken and charred sweetcorn. Add a dollop of sour cream to each bowl."
                ]
            ),
            
            // Recipe 2: Black Pepper Chicken Meal Prep (Fresh from Instagram)
            Recipe(
                name: "Black Pepper Chicken Meal Prep",
                description: "A quick and easy high-protein black pepper chicken stir fry, perfect for meal prep. Tender chicken thighs, colorful peppers, and a savory black pepper sauce come together for a delicious lunch or dinner. Serve with rice for a complete meal.",
                imageUrl: "https://instagram.fblr1-5.fna.fbcdn.net/v/t51.2885-15/502493486_670602509126939_5722353919325014122_n.jpg?stp=dst-jpg_e15_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6ImltYWdlX3VybGdlbi42NDB4MTEzNi5zZHIuZjcxODc4Lm5mcmFtZV9jb3Zlcl9mcmFtZS5jMiJ9&_nc_ht=instagram.fblr1-5.fna.fbcdn.net&_nc_cat=111&_nc_oc=Q6cZ2QEqHmqm5NIy2O_02Oxo4bIWL7riAj7bn8C9bRI482zJQI6H1xAUImXiOPherzjpzBc&_nc_ohc=qYMSLN43ZyIQ7kNvwH4RI6r&_nc_gid=_V3x-TGuJMGfGYUFEHrb2w&edm=ANTKIIoBAAAA&ccb=7-5&oh=00_AfTvqiRKriJVJUv8PKg2-orvvw46qox_OBSiFuWsVQcgTA&oe=6893EAA2&_nc_sid=d885a2",
                prepTime: 20,
                cookTime: 5,
                difficulty: .easy,
                nutrition: Nutrition(calories: 623, protein: 46, carbs: 82, fats: 12, portions: 3),
                ingredients: [
                    Ingredient(name: "600g Chicken Thigh Fillets", category: .meatPoultryFish),
                    Ingredient(name: "2 Cloves of Garlic", category: .fruitVegetables),
                    Ingredient(name: "1/2 Onion", category: .fruitVegetables),
                    Ingredient(name: "1 Red Pepper", category: .fruitVegetables),
                    Ingredient(name: "1 Green Pepper", category: .fruitVegetables),
                    Ingredient(name: "100ml Chicken Stock", category: .cupboardStaples),
                    Ingredient(name: "2 Tbsp Honey", category: .cupboardStaples),
                    Ingredient(name: "3 Tbsp Oyster Sauce", category: .cannedJarred),
                    Ingredient(name: "1 Heaped Tsp Ground Black Pepper", category: .herbsSpices),
                    Ingredient(name: "1 Fresh Chilli", category: .fruitVegetables),
                    Ingredient(name: "2 Spring Onion", category: .fruitVegetables),
                    Ingredient(name: "1 Tbsp Rice Vinegar", category: .cupboardStaples),
                    Ingredient(name: "1 Tbsp Sesame Oil", category: .cupboardStaples),
                    Ingredient(name: "1 Tbsp Dark Soy Sauce", category: .cupboardStaples),
                    Ingredient(name: "250g Uncooked Rice", category: .pastaRiceGrains)
                ],
                isFromReel: true,
                extractedFrom: "instagram",
                creatorHandle: "@foodinfivemins",
                creatorName: "Food In 5 | Bill",
                originalUrl: "https://www.instagram.com/foodinfivemins/reel/DKRUldhuOzt/?hl=en",
                steps: [
                    "Dice the chicken thigh fillets into bite-sized pieces.",
                    "Mince the garlic cloves.",
                    "Chop the half onion, red pepper, green pepper, fresh chili, and spring onions.",
                    "Measure out the chicken stock, honey, oyster sauce, ground black pepper, rice vinegar, sesame oil, and dark soy sauce.",
                    "Rinse the uncooked rice under cold water.",
                    "Cook the rice according to package instructions (usually 18-20 minutes).",
                    "Heat a large pan or wok over medium-high heat and add a little oil.",
                    "Add the minced garlic and chopped onion to the pan. Sauté for 3 minutes until fragrant and softened.",
                    "Add the diced chicken thigh to the pan. Fry for 8 minutes, stirring occasionally, until the chicken starts to brown.",
                    "Add the chopped red and green peppers. Sauté for 5 minutes until slightly softened.",
                    "Pour in the chicken stock, honey, oyster sauce, and ground black pepper. Stir to combine.",
                    "Let the mixture simmer for 4 minutes, allowing the sauce to thicken slightly.",
                    "Add the chopped fresh chili and spring onions, rice vinegar, sesame oil, and dark soy sauce. Stir well.",
                    "Cook for a final 2 minutes, ensuring everything is well coated and heated through.",
                    "Serve the black pepper chicken stir fry alongside the cooked rice. Divide into meal prep containers if desired."
                ]
            ),
            
            // Recipe 3: Sesame Ground Chicken with Honey Sesame Green Beans (Fresh from Instagram)
            Recipe(
                name: "Sesame Ground Chicken with Honey Sesame Green Beans",
                description: "A quick, high-protein stir-fry featuring savory sesame ground chicken and honey sesame green beans, served over fluffy long grain rice. Perfect for meal prep or a healthy weeknight dinner.",
                imageUrl: "https://instagram.fblr1-5.fna.fbcdn.net/v/t51.2885-15/489333370_18002136248761551_4361426156949198907_n.jpg?stp=dst-jpg_e15_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6ImltYWdlX3VybGdlbi43MjB4MTI4MC5zZHIuZjc1NzYxLmRlZmF1bHRfY292ZXJfZnJhbWUuYzIifQ&_nc_ht=instagram.fblr1-5.fna.fbcdn.net&_nc_cat=103&_nc_oc=Q6cZ2QFAby3_Ex0JGjA3zfN9GESU37EJhUdd_ElzolG9dG9OAmvFsUHANowjft24IscV7iA&_nc_ohc=SFBJz_xUOLQQ7kNvwG1eXsr&_nc_gid=Xmm_0zaci8p4uc-YQmAVcw&edm=ANTKIIoBAAAA&ccb=7-5&oh=00_AfRnNZlF7_1SM1_nHmXEbzKrwMHnDggKrvzyoao9nIsmPg&oe=6893EEE5&_nc_sid=d885a2",
                prepTime: 5,
                cookTime: 20,
                difficulty: .easy,
                nutrition: Nutrition(calories: 522, protein: 40, carbs: 57, fats: 15, portions: 3),
                ingredients: [
                    Ingredient(name: "500g Chicken Mince", category: .meatPoultryFish),
                    Ingredient(name: "1 tsp Chinese 5 Spice", category: .herbsSpices),
                    Ingredient(name: "2 cloves Garlic", category: .fruitVegetables),
                    Ingredient(name: "1/2 Red Onion", category: .fruitVegetables),
                    Ingredient(name: "2 tbsp Sesame Oil", category: .cupboardStaples),
                    Ingredient(name: "2 tbsp Light Soy Sauce", category: .cupboardStaples),
                    Ingredient(name: "2 tbsp Rice Wine Vinegar", category: .cupboardStaples),
                    Ingredient(name: "3 tbsp Honey", category: .cupboardStaples),
                    Ingredient(name: "1 Spring Onion", category: .fruitVegetables),
                    Ingredient(name: "3 Small Chillis", category: .fruitVegetables),
                    Ingredient(name: "300g Green Beans", category: .fruitVegetables),
                    Ingredient(name: "1 tbsp Black & White Sesame Seeds", category: .herbsSpices),
                    Ingredient(name: "275g Uncooked Long Grain Rice", category: .pastaRiceGrains)
                ],
                isFromReel: true,
                extractedFrom: "instagram",
                creatorHandle: "@foodinfivemins",
                creatorName: "Food In 5 | Bill",
                originalUrl: "https://www.instagram.com/foodinfivemins/reel/DIRHVcDy7Bk/?hl=en",
                steps: [
                    "Rinse the rice under cold water until the water runs clear. Add the rice to a pot with water (according to package instructions), bring to a boil, then reduce heat and simmer for 18-20 minutes until cooked. Fluff with a fork and set aside.",
                    "While the rice cooks, finely chop 1/2 red onion, mince 2 cloves of garlic, slice 3 small chilis, and finely slice 1 spring onion. Trim and cut the green beans into bite-sized pieces.",
                    "Heat 1 tablespoon of sesame oil in a large frying pan or wok over medium-high heat.",
                    "Add the chopped red onion and minced garlic to the pan. Sauté for 2-3 minutes until fragrant.",
                    "Add 500g chicken mince and 1 tsp Chinese 5 spice to the pan. Cook, breaking up the mince, until golden and cooked through (about 8 minutes).",
                    "Stir in 2 tbsp light soy sauce, 2 tbsp rice wine vinegar, 1 tbsp honey, and 1 tablespoon of sesame oil. Mix well and cook for another 2 minutes.",
                    "Add the sliced chillis and half of the spring onion. Continue to cook for 2-3 minutes until the honey caramelizes and the mixture is glossy. Remove the chicken mixture from the pan and set aside.",
                    "In the same pan, increase the heat to high. Add the green beans and stir-fry for 5 minutes until just tender.",
                    "Add 1 tbsp honey and 1 tbsp black & white sesame seeds to the green beans. Stir well and cook for another 1-2 minutes until the beans are coated and slightly caramelized.",
                    "To serve, divide the cooked rice among bowls. Top with the sesame ground chicken and honey sesame green beans. Garnish with the remaining spring onion and a drizzle of light soy sauce if desired."
                ]
            )
        ]
        // Create Meal Preps collection with all recipes
        let mealPrepsCollection = Collection(
            name: "Meal Preps",
            recipeIDs: self.recipes.map { $0.id }
        )
        self.collections = [mealPrepsCollection]
    }
}

// ========================================================================
// MARK: - Main Views
// ========================================================================

struct TabBarView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var recipeStore: RecipeStore
    
    var body: some View {
        ZStack {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
        NavigationView {
            HomeView()
        }
                case 1:
                    ImportTabView()
                case 2:
                    ShoppingListView()
                case 3:
                    NavigationView {
                        UserInfoView()
                    }
                default:
                    NavigationView {
                        HomeView()
                    }
                }
            }
            
            // Custom Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(recipeStore.$isProcessingReel) { isProcessing in
            if isProcessing {
                // Switch to Home tab when import starts
                selectedTab = 0
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var recipeStore: RecipeStore
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0,
                shouldAnimateAttention: false,
                action: { 
                    selectedTab = 0
                    recipeStore.navigateToHome()
                }
            )
            
            // Import Tab (Prominent)
            TabBarButton(
                icon: "sparkles",
                title: "Import",
                isSelected: selectedTab == 1,
                isProminent: true,
                shouldAnimateAttention: recipeStore.isFirstTimeUser,
                action: { 
                    selectedTab = 1
                    // Stop animation when user visits import page for first time
                    if recipeStore.isFirstTimeUser {
                        recipeStore.markFirstImportCompleted()
                    }
                }
            )
            
            // Shopping List Tab
            TabBarButton(
                icon: "list.clipboard.fill",
                title: "Shopping",
                isSelected: selectedTab == 2,
                shouldAnimateAttention: false,
                action: { selectedTab = 2 }
            )
            
            // Profile Tab
            TabBarButton(
                icon: "person.circle.fill",
                title: "Profile",
                isSelected: selectedTab == 3,
                shouldAnimateAttention: false,
                action: { selectedTab = 3 }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let isProminent: Bool
    let shouldAnimateAttention: Bool
    let action: () -> Void
    
    @State private var animationScale: Double = 1.0
    @State private var animationOpacity: Double = 1.0
    
    init(icon: String, title: String, isSelected: Bool, isProminent: Bool = false, shouldAnimateAttention: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.isProminent = isProminent
        self.shouldAnimateAttention = shouldAnimateAttention
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: isProminent ? 22 : 18, weight: .medium))
                    .foregroundColor(buttonColor)
                    .frame(width: isProminent ? 38 : 28, height: isProminent ? 38 : 28)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(buttonColor)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .scaleEffect(animationScale.isFinite ? animationScale : 1.0)
        .opacity(animationOpacity.isFinite ? animationOpacity : 1.0)
        .onAppear {
            if shouldAnimateAttention {
                startAttentionAnimation()
            }
        }
        .onChange(of: shouldAnimateAttention) { _, newValue in
            if newValue {
                startAttentionAnimation()
            } else {
                stopAttentionAnimation()
            }
        }
    }
    
    private var buttonColor: Color {
        if shouldAnimateAttention {
            return .black // Black attention-grabbing color
        } else {
            return isSelected ? .brandDarkGray : .brandSilver
        }
    }
    
    private func startAttentionAnimation() {
        // Ensure initial values are valid
        if !animationScale.isFinite { animationScale = 1.0 }
        if !animationOpacity.isFinite { animationOpacity = 1.0 }
        
        // Pulsing scale animation
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            animationScale = 1.2
        }
        
        // Subtle opacity pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animationOpacity = 0.7
        }
    }
    
    private func stopAttentionAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationScale = 1.0
            animationOpacity = 1.0
        }
    }
}

// MARK: - Tab Views

struct ImportTabView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var reelLink = ""
    @State private var customName = ""
    @State private var showingNameModal = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Section
                    VStack(spacing: 16) {
                        Text("Import Recipes")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Paste any recipe link and let AI extract everything for you")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)
                    
                    // Main Import Section
                    VStack(spacing: 20) {
                        // URL Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipe URL")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "link")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("https://instagram.com/reel/...", text: $reelLink)
                                    .focused($isTextFieldFocused)
                                    .font(.system(size: 16))
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                
                                if !reelLink.isEmpty {
                                    Button(action: { reelLink = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextFieldFocused ? Color.brandYellow : Color(.separator), lineWidth: 1)
                            )
                        }
                        
                        // Import Action
                        Button(action: { showingNameModal = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Quick Import")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.brandYellow)
                            .cornerRadius(12)
                            .shadow(color: Color.brandYellow.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(!isLinkValid)
                        .opacity(isLinkValid ? 1.0 : 0.6)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    
                    // Supported Platforms
                    VStack(spacing: 20) {
                        HStack {
                            Text("Supported Platforms")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 8) {
                            PlatformCard(
                                icon: "",
                                title: "TikTok",
                                subtitle: "Videos & recipes",
                                gradient: []
                            )
                            PlatformCard(
                                icon: "",
                                title: "Instagram",
                                subtitle: "Reels & posts",
                                gradient: []
                            )
                            PlatformCard(
                                icon: "",
                                title: "YouTube",
                                subtitle: "Cooking videos",
                                gradient: []
                            )
                            PlatformCard(
                                icon: "",
                                title: "Websites",
                                subtitle: "Recipe blogs",
                                gradient: []
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("")
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
        .sheet(isPresented: $showingNameModal) {
            CustomNameModal(reelLink: reelLink, customName: $customName) { name in
                recipeStore.startImport(url: reelLink, customName: name)
            }
        }
    }
    
    private var isLinkValid: Bool {
        let trimmed = reelLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && (
            trimmed.hasPrefix("http://") ||
            trimmed.hasPrefix("https://") ||
            trimmed.contains(".com") ||
            trimmed.contains(".org") ||
            trimmed.contains(".net")
        )
    }
    

}

struct TipItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct PlatformCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color] // Keep for compatibility but won't use
    
    var body: some View {
        HStack(spacing: 12) {
            // Use colorful SVG icons when available, fallback to system icons
            if let svgIconName = platformSVGIcon {
                Image(svgIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: platformSystemIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
    
    private var platformSVGIcon: String? {
        switch title.lowercased() {
        case "tiktok": return "tiktok-coloured"
        case "instagram": return "instagram-coloured"
        case "youtube": return "youtube-coloured"
        default: return nil // No SVG icon available
        }
    }
    
    private var platformSystemIcon: String {
        switch title.lowercased() {
        case "tiktok": return "music.note"
        case "instagram": return "camera"
        case "youtube": return "play.rectangle"
        case "websites": return "globe"
        default: return "link"
        }
    }
}

struct CustomNameModal: View {
    let reelLink: String
    @Binding var customName: String
    let onImport: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with drag indicator
            VStack(spacing: 16) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                
                VStack(spacing: 8) {
                    Text("Name Your Recipe")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Give your recipe a custom name or leave blank to use the original title")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)
            
            // Input section
            VStack(alignment: .leading, spacing: 12) {
                Text("Recipe Name (Optional)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("Enter custom name...", text: $customName)
                    .focused($isNameFieldFocused)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isNameFieldFocused ? Color.brandYellow : Color(.separator), lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    onImport(customName)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Import Recipe")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.brandYellow)
                    .cornerRadius(12)
                    .shadow(color: Color.brandYellow.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                
                Button("Cancel") { 
                    dismiss() 
                }
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden) // We have our own
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { 
                isNameFieldFocused = true 
            }
        }
    }
}



struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var recipeStore = RecipeStore()
    
    // Force light mode flag - set to true to always use light mode
    private let forceAlwaysLightMode = true
    
        var body: some View {
        TabBarView()
            .environmentObject(recipeStore)
            .environmentObject(authViewModel)
            .preferredColorScheme(forceAlwaysLightMode ? .light : nil)
            .onAppear {
                // Wake up the server on app launch
                Task {
                    await RecipeAPIService().wakeUpServer()
                }
            }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    
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
                    // Collections and recipe grid
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
                        // Loading Recipe Card (first item in grid when importing)
                        if recipeStore.isProcessingReel {
                            LoadingRecipeCard(recipeName: recipeStore.loadingRecipeName)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                        }
                        
                        ForEach(recipeStore.filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCard(recipe: recipe)
                                    .contentShape(Rectangle())
                                    .contextMenu {
                                        Button { recipeToManage = recipe } label: {
                                            Label("Add to Collection", systemImage: "folder.badge.plus")
                                        }
                                        
                                        Button(role: .destructive) { 
                                            deleteRecipe(recipe) 
                                        } label: {
                                            Label("Delete Recipe", systemImage: "trash")
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
                    
                    // Bottom padding to account for custom tab bar
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Recipe Wallet")
            .background(Color(.systemGroupedBackground))
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
        .animation(.default, value: recipeStore.filteredRecipes)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: recipeStore.isProcessingReel)
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        recipeStore.deleteRecipe(recipe)
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
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .padding(.bottom, 100) // Extra padding for custom tab bar
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct RecipeInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recipeStore: RecipeStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Button(action: {
                        openOriginalSource()
                    }) {
                AsyncImage(url: URL(string: recipe.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RecipeImagePlaceholder(isFromReel: recipe.isFromReel)
                }
                .frame(height: 250)
                .clipped()
                    }
                    .buttonStyle(.plain)
                    
                    // Custom back button with better visibility
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 50) // Account for status bar
                    .padding(.leading, 16)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.name).font(.largeTitle).fontWeight(.bold)
                        
                        // Recipe Info Grid (2x2 layout)
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 12) {
                            // Prep Time
                            if let prepTime = recipe.prepTime {
                                RecipeInfoCard(
                                    icon: "timer",
                                    title: "Prep Time",
                                    value: "\(prepTime) min",
                                    color: .orange
                                )
                            }
                            
                            // Cook Time
                            if let cookTime = recipe.cookTime {
                                RecipeInfoCard(
                                    icon: "flame",
                                    title: "Cook Time", 
                                    value: "\(cookTime) min",
                                    color: .red
                                )
                            }
                            
                            // Difficulty
                            if let difficulty = recipe.difficulty {
                                RecipeInfoCard(
                                    icon: difficulty.iconName,
                                    title: "Difficulty",
                                    value: difficulty.displayName,
                                    color: difficulty.color
                                )
                            }
                            
                            // Platform Source
                            if recipe.isFromReel && recipe.extractedFrom != nil && recipe.platformDisplayName != "Unknown" {
                                RecipeInfoCard(
                                    icon: recipe.platformIcon,
                                    title: "Source",
                                    value: recipe.platformDisplayName,
                                    color: .black
                                )
                            }
                        }
                        
                        if !recipe.description.isEmpty {
                            Text(recipe.description)
                                .padding(.top, 4)
                        }
                        
                        // Creator Information
                        if recipe.hasCreatorInfo, let creatorName = recipe.creatorHandle {
                            HStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                Text("by \(creatorName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    if let nutrition = recipe.nutrition {
                        NutritionView(nutrition: nutrition)
                    }
                    
                    HealthReport(recipe: recipe)
                    
                    IngredientsView(recipe: recipe)
                    
                    InstructionsView(recipe: recipe)
                    
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe right to go back
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .onReceive(recipeStore.$shouldDismissToHome) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    private func openOriginalSource() {
        // First try to use the stored original URL
        if let originalUrl = recipe.originalUrl, let url = URL(string: originalUrl) {
            UIApplication.shared.open(url)
            return
        }
        
        // Fallback to old behavior for recipes without stored URL
        guard recipe.isFromReel, let extractedFrom = recipe.extractedFrom else { return }
        
        let fallbackURL: String
        switch extractedFrom.lowercased() {
        case "instagram":
            fallbackURL = "https://instagram.com"
        case "tiktok":
            fallbackURL = "https://tiktok.com"
        case "youtube":
            fallbackURL = "https://youtube.com"
        default:
            fallbackURL = "https://google.com/search?q=\(recipe.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let url = URL(string: fallbackURL) {
            UIApplication.shared.open(url)
        }
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
                                if let totalTime = recipe.totalTime {
                                    Text("\(totalTime) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
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

struct ShareCollectionSheet: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let collection: Collection
    
    @State private var shareText = ""
    @State private var showingActivityView = false
    
    private var recipesInCollection: [Recipe] {
        store.recipes(in: collection)
    }
    
    private var shareContent: String {
        var content = "🍽️ Check out my '\(collection.name)' collection from Recipe Wallet!\n\n"
        
        if recipesInCollection.isEmpty {
            content += "This collection is ready for new recipes! 📝"
        } else {
            content += "📋 \(recipesInCollection.count) delicious \(recipesInCollection.count == 1 ? "recipe" : "recipes"):\n\n"
            
            for (index, recipe) in recipesInCollection.prefix(5).enumerated() {
                let timeText = recipe.totalTime.map { "\($0) min" } ?? ""
                content += "\(index + 1). \(recipe.name)" + (timeText.isEmpty ? "" : " (\(timeText))") + "\n"
            }
            
            if recipesInCollection.count > 5 {
                content += "... and \(recipesInCollection.count - 5) more!\n"
            }
        }
        
        content += "\n✨ Get Recipe Wallet to organize your recipes!"
        return content
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share Collection")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Spread the recipe love! 💙")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // Collection Preview
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    ScrollView {
                        Text(shareContent)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
                
                // Share Options
                VStack(spacing: 16) {
                    Button(action: {
                        showingActivityView = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                            Text("Share Collection")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        UIPasteboard.general.string = shareContent
                        // Show a brief success feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.title3)
                            Text("Copy to Clipboard")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingActivityView) {
            ActivityViewController(activityItems: [shareContent])
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(0..<2) { index in
                            Circle()
                                .fill(index <= currentStep.rawValue ? Color.black : Color.gray.opacity(0.2))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.top, 24)
                    
                    if currentStep == .nameInput {
                        VStack(spacing: 4) {
                            Text("Name Your Recipe")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            Text("Optional: Give it a custom name")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
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
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .disabled(currentStep == .linkInput && !isLinkValid)
                    
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.black.opacity(0.6))
                        .font(.system(size: 16, weight: .medium))
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
        // Accept any URL that looks like a valid web link
        return !trimmed.isEmpty && (
            trimmed.hasPrefix("http://") ||
            trimmed.hasPrefix("https://") ||
            trimmed.contains(".com") ||
            trimmed.contains(".org") ||
            trimmed.contains(".net") ||
            trimmed.contains("tiktok.com") ||
            trimmed.contains("instagram.com") ||
            trimmed.contains("youtube.com")
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
                
                HStack(spacing: 4) {
                    if let totalTime = recipe.totalTime {
                        Label("\(totalTime) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let difficulty = recipe.difficulty {
                        Image(systemName: difficulty.iconName)
                            .font(.caption2)
                            .foregroundColor(difficulty.color)
                    }
                }
            }
            .padding(10)
        }
        .background(.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct LoadingRecipeCard: View {
    let recipeName: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Loading image placeholder with shimmer effect
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.brandYellow)
                    
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .overlay(
                // Shimmer effect
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            )
            .clipped()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipeName.isEmpty ? "Extracting Recipe..." : recipeName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 44, alignment: .top)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(recipeName.isEmpty ? .secondary : .primary)
                
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.brandYellow)
                    
                    Text("Extracting recipe...")
                        .font(.caption)
                        .foregroundColor(.brandDarkGray)
                }
            }
            .padding(10)
        }
        .background(.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandYellow.opacity(0.6), lineWidth: 1.5)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct CollectionCard: View {
    let collection: Collection
    var onDelete: () -> Void
    
    @EnvironmentObject var store: RecipeStore
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
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
                
                // Bottom row with recipe count and share button
                HStack {
                Label("\(recipeCount) \(recipeCount == 1 ? "recipe" : "recipes")", systemImage: "tray.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Share button (bottom right)
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .frame(width: 160, height: 100)
            
            // Menu overlay (top right)
            if collection.name != "Meal Preps" {
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
        .sheet(isPresented: $showingShareSheet) {
            ShareCollectionSheet(collection: collection)
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
            ProgressView().scaleEffect(1.5).tint(.brandYellow)
            VStack(spacing: 8) {
                Text("Extracting Recipe...").font(.headline).fontWeight(.semibold)
                Text("AI is analyzing your link and extracting the recipe.\nThis can take up to 90 seconds.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
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
                .foregroundColor(isFromReel ? .black.opacity(0.8) : .orange.opacity(0.8))
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

// MARK: - Nutrition View
struct NutritionView: View {
    let nutrition: Nutrition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clean section title
            Text("Nutrition")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.bottom, 20)
            
            // Elegant nutrition grid
            VStack(spacing: 1) {
                // Top row: Calories (prominent)
                if let calories = nutrition.calories {
                    HStack {
                        Text("Calories")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(calories)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color(.systemBackground))
                    
                    // Separator
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                }
                
                // Macros in clean rows
                VStack(spacing: 1) {
                    if let protein = nutrition.protein {
                        NutritionRow(label: "Protein", value: "\(protein)g")
                    }
                    if let carbs = nutrition.carbs {
                        NutritionRow(label: "Carbohydrates", value: "\(carbs)g")
                    }
                    if let fats = nutrition.fats {
                        NutritionRow(label: "Total Fat", value: "\(fats)g")
                    }
                }
                
                // Bottom separator and servings
                if let portions = nutrition.portions {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                    
                    HStack {
                        Text("Servings")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(portions)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color(.systemBackground))
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .padding(.bottom, 24)
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
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
                Text("Recipe URL")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("Paste recipe link", text: $reelLink)
                    .focused($isLinkFieldFocused)
                    .textFieldStyle(.plain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            // Tips Section
            VStack(spacing: 16) {
                    Text("Quick Tips")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Tips List
                VStack(alignment: .leading, spacing: 16) {
                    TipRow(icon: "square.and.arrow.up",
                           text: "Copy link from any recipe source")
                    
                    TipRow(icon: "globe",
                           text: "Supports TikTok, websites & social media")
                    
                    TipRow(icon: "wand.and.stars",
                           text: "AI extracts ingredients & instructions")
            }
            .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 4) // Subtle padding for better visual balance
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.black.opacity(0.6))
                .font(.system(size: 15, weight: .medium))
                .frame(width: 18)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.7))
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

