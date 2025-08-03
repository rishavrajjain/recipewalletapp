import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

/// Simple authentication screen offering Google and Apple sign in options
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Recipe Wallet")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            // Google Sign In Button
            GoogleSignInButton(action: handleGoogleSignIn)
                .frame(height: 50)
                .padding(.horizontal)

            // Apple Sign In Button
            SignInWithAppleButton(.signIn) { request in
                authViewModel.handleAppleSignIn(request: request)
            } onCompletion: { result in
                authViewModel.handleAppleSignInCompletion(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
            Spacer()
        }
    }

    private func handleGoogleSignIn() {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }
        authViewModel.signInWithGoogle(presenting: root)
    }
}
