import Foundation
import FirebaseFirestore
import FirebaseAuth

/// 🎯 Simple, clean cloud store - just the essentials
class RecipeCloudStore {
    static let shared = RecipeCloudStore()
    private let db = Firestore.firestore()

    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentUID: String?

    /// In-memory caches
    private var cachedUserRecipes: [Recipe] = []
    private var cachedUserCollections: [Collection] = []
    private var cachedShoppingList: [ShoppingListItem] = []
    private var cachedProfile: UserProfile?

    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.currentUID = user?.uid
            if user == nil {
                self.clearCache()
            }
        }
    }

    deinit {
        if let handle = authListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func clearCache() {
        cachedUserRecipes = []
        cachedUserCollections = []
        cachedShoppingList = []
        cachedProfile = nil
    }

    // ========================================================================
    // MARK: - 📱 Load User Data 
    // ========================================================================
    
    func load(completion: @escaping ([Recipe], [Collection], [ShoppingListItem]) -> Void) {
        guard let uid = currentUID else {
            completion([], [], [])
            return
        }

        loadUserData(uid: uid, completion: completion)
    }
    
    private func loadUserData(uid: String, completion: @escaping ([Recipe], [Collection], [ShoppingListItem]) -> Void) {
        let group = DispatchGroup()
        
        var loadedRecipes: [Recipe] = []
        var loadedCollections: [Collection] = []
        var loadedShoppingList: [ShoppingListItem] = []
        
        // 📱 Load shopping list + profile from user document
        group.enter()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            defer { group.leave() }
            
            if let data = snapshot?.data() {
                // Load shopping list
                if let listData = data["shoppingList"],
                   let jsonData = try? JSONSerialization.data(withJSONObject: listData),
                   let decoded = try? JSONDecoder().decode([ShoppingListItem].self, from: jsonData) {
                    loadedShoppingList = decoded
                }
                
                // Load and cache user profile
                if let profileData = data["profile"],
                   let jsonData = try? JSONSerialization.data(withJSONObject: profileData) {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    self?.cachedProfile = try? decoder.decode(UserProfile.self, from: jsonData)
                }
            }
        }
        
        // 🍳 Load recipes from recipes collection
        group.enter()
        db.collection("recipes").whereField("createdBy", isEqualTo: uid).getDocuments { snapshot, _ in
            defer { group.leave() }
            
            if let documents = snapshot?.documents {
                for doc in documents {
                    if let recipe = try? doc.data(as: Recipe.self) {
                        loadedRecipes.append(recipe)
                    }
                }
            }
        }
        
        // 📚 Load collections from collections collection
        group.enter()
        db.collection("collections").whereField("createdBy", isEqualTo: uid).getDocuments { snapshot, _ in
            defer { group.leave() }
            
            if let documents = snapshot?.documents {
                for doc in documents {
                    if let collection = try? doc.data(as: Collection.self) {
                        loadedCollections.append(collection)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            self.cachedUserRecipes = loadedRecipes
            self.cachedUserCollections = loadedCollections
            self.cachedShoppingList = loadedShoppingList
            completion(loadedRecipes, loadedCollections, loadedShoppingList)
            
            print("✅ Loaded data:")
            print("   📱 Shopping: \(loadedShoppingList.count) items")
            print("   🍳 Recipes: \(loadedRecipes.count) from /recipes/")
            print("   📚 Collections: \(loadedCollections.count) from /collections/")
        }
    }

    // ========================================================================
    // MARK: - 💾 Save User Data
    // ========================================================================
    
    func save(recipes: [Recipe], collections: [Collection], shoppingList: [ShoppingListItem]) {
        guard let uid = currentUID else { return }

        // Save shopping list to user document
        saveUserData(uid: uid, shoppingList: shoppingList)
        
        // Save recipes & collections to separate collections
        saveRecipesAndCollections(uid: uid, recipes: recipes, collections: collections)
        
        // Update cache
        cachedUserRecipes = recipes
        cachedUserCollections = collections
        cachedShoppingList = shoppingList
    }
    
    private func saveUserData(uid: String, shoppingList: [ShoppingListItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var payload: [String: Any] = [:]

        // Save shopping list
        if let encoded = try? encoder.encode(shoppingList),
           let json = try? JSONSerialization.jsonObject(with: encoded) {
            payload["shoppingList"] = json
        }

        db.collection("users").document(uid).setData(payload, merge: true) { error in
            if let error = error {
                print("❌ Failed to save shopping list: \(error)")
            } else {
                print("✅ Saved shopping list (\(shoppingList.count) items)")
            }
        }
    }
    
    private func saveRecipesAndCollections(uid: String, recipes: [Recipe], collections: [Collection]) {
        let batch = db.batch()
        
        // Save recipes
        for recipe in recipes {
            var updatedRecipe = recipe
            updatedRecipe.createdBy = uid
            updatedRecipe.updatedAt = Date()
            
            let recipeRef = db.collection("recipes").document(recipe.id)
            if let encoded = try? Firestore.Encoder().encode(updatedRecipe) {
                batch.setData(encoded, forDocument: recipeRef, merge: true)
            }
        }
        
        // Save collections
        for collection in collections {
            var updatedCollection = collection
            updatedCollection.createdBy = uid
            updatedCollection.updatedAt = Date()
            
            let collectionRef = db.collection("collections").document(collection.id)
            if let encoded = try? Firestore.Encoder().encode(updatedCollection) {
                batch.setData(encoded, forDocument: collectionRef, merge: true)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Failed to save recipes/collections: \(error)")
            } else {
                print("✅ Saved \(recipes.count) recipes + \(collections.count) collections")
            }
        }
    }

    // ========================================================================
    // MARK: - 👤 User Profile (The Important Stuff You Actually Use)
    // ========================================================================
    
    func getCachedProfile() -> UserProfile? {
        return cachedProfile
    }
    
    func updateCachedProfile(_ profile: UserProfile) {
        cachedProfile = profile
    }
    
    func getUserSummary() -> (recipesCount: Int, collectionsCount: Int, shoppingItemsCount: Int, hasProfile: Bool) {
        return (
            recipesCount: cachedUserRecipes.count,
            collectionsCount: cachedUserCollections.count,
            shoppingItemsCount: cachedShoppingList.count,
            hasProfile: cachedProfile != nil
        )
    }
    
    func getUserDietaryPreference() -> String? {
        return cachedProfile?.foodPreference
    }
    
    func isProfileComplete() -> Bool {
        guard let profile = cachedProfile else { return false }
        return !profile.name.isEmpty && !profile.age.isEmpty && !profile.weight.isEmpty
    }
    
    func getPersonalizedGreeting() -> String {
        return "Recipe Wallet"
    }
}
