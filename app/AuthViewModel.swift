import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

/// View model responsible for handling authentication flows
class AuthViewModel: NSObject, ObservableObject {
    /// The currently authenticated Firebase user
    @Published var user: User?
    @Published var isAuthenticating = false
    @Published var errorMessage: String?
    @Published var showingError = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    override init() {
        super.init()
        // Observe authentication state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                // Prevent rapid state changes during auth flow
                if self?.isAuthenticating == true && user != nil {
                    // Add small delay to ensure smooth transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.user = user
                        self?.isAuthenticating = false
                        self?.clearError()
                    }
                } else {
                    self?.user = user
                    if user == nil {
                        self?.isAuthenticating = false
                    }
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    /// Starts the Google sign in flow
    func signInWithGoogle(presenting: UIViewController) {
        // Prevent double taps
        guard !isAuthenticating else { return }
        
        isAuthenticating = true
        clearError()
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { 
            showError("Google configuration error. Please try again.")
            isAuthenticating = false
            return 
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("Google sign-in failed: \(error.localizedDescription)")
                    self?.isAuthenticating = false
                    return
                }
                
                guard
                    let idToken = result?.user.idToken?.tokenString,
                    let accessToken = result?.user.accessToken.tokenString
                else { 
                    self?.showError("Failed to get Google authentication tokens. Please try again.")
                    self?.isAuthenticating = false
                    return 
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: accessToken)
                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showError("Authentication failed: \(error.localizedDescription)")
                            self?.isAuthenticating = false
                        } else {
                            // Success - ensure user profile is created with Firebase UID as primary key
                            self?.createUserProfileIfNeeded(authResult?.user)
                        }
                    }
                }
            }
        }
    }

    /// Prepares the Apple sign in request with a cryptographic nonce
    func handleAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        guard !isAuthenticating else { return }
        
        isAuthenticating = true
        clearError()
        
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Handles the completion of Apple sign in flow
    func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            guard
                let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else { 
                showError("Apple sign-in failed. Please try again.")
                isAuthenticating = false
                return 
            }

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError("Apple authentication failed: \(error.localizedDescription)")
                        self?.isAuthenticating = false
                    } else {
                        // Success - handle Apple's "Hide My Email" properly
                        self?.createUserProfileIfNeeded(authResult?.user, fullName: appleIDCredential.fullName)
                    }
                }
            }
        case .failure(let error):
            showError("Apple sign-in request failed: \(error.localizedDescription)")
            isAuthenticating = false
        }
    }

    /// Signs out the current user
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticating = false
            clearError()
        } catch {
            showError("Error signing out: \(error.localizedDescription)")
        }
    }
    
    /// Soft delete user account (marks as deleted but doesn't actually delete)
    func softDeleteAccount() {
        guard let currentUser = Auth.auth().currentUser else {
            showError("No user is currently signed in")
            return
        }
        
        // Mark user as deleted in Firestore instead of actually deleting
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).updateData([
            "isDeleted": true,
            "deletedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("Failed to delete account: \(error.localizedDescription)")
                } else {
                    // Sign out after marking as deleted
                    self?.signOut()
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
        print("🚨 Auth Error: \(message)")
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - Private Methods
    
    /// Creates user profile if needed, handles Apple's Hide My Email properly
    private func createUserProfileIfNeeded(_ user: User?, fullName: PersonNameComponents? = nil) {
        guard let user = user else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid) // Firebase UID as primary key
        
        userRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error checking user profile: \(error)")
                return
            }
            
            // If user doesn't exist, create profile
            if !(snapshot?.exists ?? false) {
                var userData: [String: Any] = [
                    "uid": user.uid, // Firebase UID as primary key
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastSignIn": FieldValue.serverTimestamp(),
                    "isDeleted": false
                ]
                
                // Handle email (might be Apple's private relay email)
                if let email = user.email {
                    userData["email"] = email
                    userData["emailVerified"] = user.isEmailVerified
                }
                
                // Handle display name
                if let fullName = fullName {
                    let displayName = PersonNameComponentsFormatter().string(from: fullName)
                    userData["name"] = displayName
                } else if let displayName = user.displayName, !displayName.isEmpty {
                    userData["name"] = displayName
                }
                
                // Provider info
                if let providerData = user.providerData.first {
                    userData["provider"] = providerData.providerID
                }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        print("Error creating user profile: \(error)")
                    } else {
                        print("✅ User profile created successfully for UID: \(user.uid)")
                    }
                }
            } else {
                // Update last sign in
                userRef.updateData(["lastSignIn": FieldValue.serverTimestamp()])
            }
        }
    }

    // MARK: - Nonce utilities
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    // MARK: - Email Login for Apple Review Team
    
    /// Signs in with hardcoded email credentials for Apple review team
    func signInWithEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // Hardcoded credentials for Apple review
        guard email == "test@recipewallet.ai" && password == "Test#123" else {
            showError("Invalid credentials. Please use the provided test credentials.")
            completion(false)
            return
        }
        
        guard !isAuthenticating else {
            completion(false)
            return
        }
        
        isAuthenticating = true
        clearError()
        
        // Try to sign in with Firebase Auth
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                // If user doesn't exist, create them
                self?.createTestUser(email: email, password: password, completion: completion)
            } else {
                // Success - user already exists
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    completion(true)
                }
            }
        }
    }
    
    /// Creates the test user in Firebase Auth and Firestore with basic profile
    private func createTestUser(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("Failed to create test user: \(error.localizedDescription)")
                    self?.isAuthenticating = false
                    completion(false)
                    return
                }
                
                guard let user = result?.user else {
                    self?.showError("Failed to get user after creation")
                    self?.isAuthenticating = false
                    completion(false)
                    return
                }
                
                // Create basic user profile
                self?.createBasicTestUserProfile(user: user, completion: completion)
            }
        }
    }
    
    /// Creates basic test user profile in Firestore without dummy data
    private func createBasicTestUserProfile(user: User, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        // Create basic user profile - no dummy recipes or collections
        let userData: [String: Any] = [
            "uid": user.uid,
            "name": "Apple Review User",
            "email": "test@recipewallet.ai",
            "provider": "email",
            "createdAt": FieldValue.serverTimestamp(),
            "lastSignIn": FieldValue.serverTimestamp(),
            "isDeleted": false,
            "shoppingList": [],
            "ownedRecipeIds": [],
            "ownedCollectionIds": []
        ]
        
        // Create user document
        userRef.setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error creating user profile: \(error)")
                    self?.showError("Failed to create user profile")
                    self?.isAuthenticating = false
                    completion(false)
                } else {
                    print("✅ Basic test user created successfully")
                    self?.isAuthenticating = false
                    completion(true)
                }
            }
        }
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
