import Foundation
import FirebaseFirestore
import FirebaseAuth

// Array chunking extension for Firestore batch queries
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

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
        
        // 📱 Load shopping list + profile + ownership lists from user document
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
                
                // Log ownership info for debugging
                if let ownedRecipeIds = data["ownedRecipeIds"] as? [String],
                   let ownedCollectionIds = data["ownedCollectionIds"] as? [String] {
                    print("📊 User owns \(ownedRecipeIds.count) recipes, \(ownedCollectionIds.count) collections (from user doc)")
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

        // Save ownership lists for better tracking
        let recipeIds = cachedUserRecipes.map { $0.id }
        let collectionIds = cachedUserCollections.map { $0.id }
        payload["ownedRecipeIds"] = recipeIds
        payload["ownedCollectionIds"] = collectionIds

        db.collection("users").document(uid).setData(payload, merge: true) { error in
            if let error = error {
                print("❌ Failed to save user data: \(error)")
            } else {
                print("✅ Saved user data: \(shoppingList.count) shopping items, \(recipeIds.count) recipes, \(collectionIds.count) collections")
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

    /// Delete multiple recipes from Firestore by their document IDs
    func deleteRecipes(ids: [String]) {
        guard let _ = currentUID, !ids.isEmpty else { return }
        let batch = db.batch()
        ids.forEach { id in
            let ref = db.collection("recipes").document(id)
            batch.deleteDocument(ref)
        }
        batch.commit { error in
            if let error = error {
                print("❌ Failed to delete duplicate recipes: \(error)")
            } else {
                print("🗑️ Deleted \(ids.count) duplicate recipes")
            }
        }
    }

    /// Delete multiple collections from Firestore by their document IDs
    func deleteCollections(ids: [String]) {
        guard let _ = currentUID, !ids.isEmpty else { return }
        let batch = db.batch()
        ids.forEach { id in
            let ref = db.collection("collections").document(id)
            batch.deleteDocument(ref)
        }
        batch.commit { error in
            if let error = error {
                print("❌ Failed to delete duplicate collections: \(error)")
            } else {
                print("🗑️ Deleted \(ids.count) duplicate collections")
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
    
    /// Get ownership lists for the current user
    func getOwnershipLists() -> (recipeIds: [String], collectionIds: [String]) {
        return (
            recipeIds: cachedUserRecipes.map { $0.id },
            collectionIds: cachedUserCollections.map { $0.id }
        )
    }
    
    /// Check if current user owns a specific collection
    func ownsCollection(id: String) -> Bool {
        return cachedUserCollections.contains { $0.id == id }
    }
    
    /// Check if current user owns a specific recipe
    func ownsRecipe(id: String) -> Bool {
        return cachedUserRecipes.contains { $0.id == id }
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
    
    // ========================================================================
    // MARK: - 🔗 Collection Sharing
    // ========================================================================
    
    /// Fetch a specific collection by ID from Firestore (for sharing/importing)
    func fetchCollection(id: String, completion: @escaping (Collection?, [Recipe]) -> Void) {
        // First fetch the collection
        db.collection("collections").document(id).getDocument { [weak self] snapshot, error in
            guard let self = self else { 
                completion(nil, [])
                return 
            }
            
            if let error = error {
                print("❌ Failed to fetch collection \(id): \(error)")
                completion(nil, [])
                return
            }
            
            guard let data = snapshot?.data(),
                  let collection = try? snapshot?.data(as: Collection.self) else {
                print("❌ Collection \(id) not found or invalid")
                completion(nil, [])
                return
            }
            
            // Now fetch all recipes in this collection
            if collection.recipeIDs.isEmpty {
                completion(collection, [])
                return
            }
            
            // Firestore 'in' queries are limited to 30 items, so we'll batch if needed
            let batchSize = 30
            let batches = collection.recipeIDs.chunked(into: batchSize)
            var allRecipes: [Recipe] = []
            let group = DispatchGroup()
            
            for batch in batches {
                group.enter()
                self.db.collection("recipes")
                    .whereField(FieldPath.documentID(), in: Array(batch))
                    .getDocuments { snapshot, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ Failed to fetch recipe batch: \(error)")
                            return
                        }
                        
                        if let documents = snapshot?.documents {
                            for doc in documents {
                                if let recipe = try? doc.data(as: Recipe.self) {
                                    allRecipes.append(recipe)
                                }
                            }
                        }
                    }
            }
            
            group.notify(queue: .main) {
                print("✅ Fetched collection '\(collection.name)' with \(allRecipes.count) recipes")
                completion(collection, allRecipes)
            }
        }
    }
}
