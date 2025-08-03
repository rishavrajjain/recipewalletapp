import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

/// View model responsible for handling authentication flows
class AuthViewModel: NSObject, ObservableObject {
    /// The currently authenticated Firebase user
    @Published var user: User?
    @Published var isAuthenticating = false

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
        isAuthenticating = true
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { 
            isAuthenticating = false
            return 
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            if let error = error {
                print("Google sign in failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                }
                return
            }
            guard
                let idToken = result?.user.idToken?.tokenString,
                let accessToken = result?.user.accessToken.tokenString
            else { 
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                }
                return 
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            Auth.auth().signIn(with: credential) { [weak self] _, error in
                if let error = error {
                    print("Firebase auth with Google credential failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.isAuthenticating = false
                    }
                }
                // Success case is handled by auth state listener
            }
        }
    }

    /// Prepares the Apple sign in request with a cryptographic nonce
    func handleAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        isAuthenticating = true
        
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
                DispatchQueue.main.async {
                    self.isAuthenticating = false
                }
                return 
            }

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { [weak self] _, error in
                if let error = error {
                    print("Apple sign in failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.isAuthenticating = false
                    }
                }
                // Success case is handled by auth state listener
            }
        case .failure(let error):
            print("Apple sign in request failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isAuthenticating = false
            }
        }
    }

    /// Signs out the current user
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticating = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
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

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
