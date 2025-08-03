import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Handles syncing recipe data with Firestore for the authenticated user
class RecipeCloudStore {
    static let shared = RecipeCloudStore()
    private let db = Firestore.firestore()

    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentUID: String?

    /// In-memory caches for the signed-in user
    private var cachedRecipes: [Recipe] = []
    private var cachedCollections: [Collection] = []
    private var cachedList: [ShoppingListItem] = []

    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.currentUID = user?.uid
            if user == nil {
                // Clear any cached data when signing out
                self.cachedRecipes = []
                self.cachedCollections = []
                self.cachedList = []
            }
        }
    }

    deinit {
        if let handle = authListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    /// Loads recipes, collections and shopping list for current user
    func load(completion: @escaping ([Recipe], [Collection], [ShoppingListItem]) -> Void) {
        guard let uid = currentUID else {
            completion([], [], [])
            return
        }

        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            let decoder = JSONDecoder()
            var loadedRecipes: [Recipe] = []
            var loadedCollections: [Collection] = []
            var loadedList: [ShoppingListItem] = []

            if let data = snapshot?.data() {
                if let recipeData = data["recipes"],
                   let jsonData = try? JSONSerialization.data(withJSONObject: recipeData),
                   let decoded = try? decoder.decode([Recipe].self, from: jsonData) {
                    loadedRecipes = decoded
                }
                if let collectionData = data["collections"],
                   let jsonData = try? JSONSerialization.data(withJSONObject: collectionData),
                   let decoded = try? decoder.decode([Collection].self, from: jsonData) {
                    loadedCollections = decoded
                }
                if let listData = data["shoppingList"],
                   let jsonData = try? JSONSerialization.data(withJSONObject: listData),
                   let decoded = try? decoder.decode([ShoppingListItem].self, from: jsonData) {
                    loadedList = decoded
                }
            }

            DispatchQueue.main.async {
                self?.cachedRecipes = loadedRecipes
                self?.cachedCollections = loadedCollections
                self?.cachedList = loadedList
                completion(loadedRecipes, loadedCollections, loadedList)
            }
        }
    }

    /// Saves recipes, collections and shopping list for current user
    func save(recipes: [Recipe], collections: [Collection], shoppingList: [ShoppingListItem]) {
        guard let uid = currentUID else { return }

        let encoder = JSONEncoder()
        var payload: [String: Any] = [:]

        if let encoded = try? encoder.encode(recipes),
           let json = try? JSONSerialization.jsonObject(with: encoded) {
            payload["recipes"] = json
        }
        if let encoded = try? encoder.encode(collections),
           let json = try? JSONSerialization.jsonObject(with: encoded) {
            payload["collections"] = json
        }
        if let encoded = try? encoder.encode(shoppingList),
           let json = try? JSONSerialization.jsonObject(with: encoded) {
            payload["shoppingList"] = json
        }

        db.collection("users").document(uid).setData(payload, merge: true)

        cachedRecipes = recipes
        cachedCollections = collections
        cachedList = shoppingList
    }
}
