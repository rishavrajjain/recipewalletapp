import SwiftUI
import GoogleSignInSwift
import AuthenticationServices
import SafariServices

/// Beautifully designed authentication screen matching the Recipe Wallet brand
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var logoScale: CGFloat = 0.8
    @State private var buttonsOpacity: Double = 0.0
    @State private var showingSafari = false
    @State private var safariURL: URL?
    
    var body: some View {
        ZStack {
            // Brand yellow background with subtle gradient
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.1),
                    Color(red: 1.0, green: 0.78, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and Brand Section
                VStack(spacing: 24) {
                    // App Logo
                    if let logoImage = UIImage(named: "appLogo") {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .scaleEffect(logoScale)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
                    } else {
                        // Fallback to system icon if logo not found
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.black)
                        }
                        .scaleEffect(logoScale)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Recipe Wallet AI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.black)

                        Text("Your food journey starts here")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }

                Spacer()
                Spacer()

                // Authentication Buttons Section
                VStack(spacing: 16) {
                    // Apple Sign In Button (First on iOS as per guidelines)
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            authViewModel.handleAppleSignIn(request: request)
                        },
                        onCompletion: { result in
                            authViewModel.handleAppleSignInCompletion(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50) // ≥ 44pt as required
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 32)
                    .disabled(authViewModel.isAuthenticating)
                    .opacity(authViewModel.isAuthenticating ? 0.6 : 1.0)

                    // Google Sign In Button
                    Button(action: handleGoogleSignIn) {
                        HStack(spacing: 12) {
                            if authViewModel.isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.black.opacity(0.8))
                            } else {
                                // Official Google logo
                                Image("google-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                            }

                            Text(authViewModel.isAuthenticating ? "Signing in..." : "Continue with Google")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50) // Same height as Apple button
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(authViewModel.isAuthenticating ? Color.white.opacity(0.7) : Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    .disabled(authViewModel.isAuthenticating)
                    .padding(.horizontal, 32)
                }
                .opacity(buttonsOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.4), value: buttonsOpacity)

                Spacer()

                // Error Message Display
                if let errorMessage = authViewModel.errorMessage {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, 32)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Footer with Tappable Terms
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))

                    HStack(spacing: 4) {
                        Button(action: { openTermsOfService() }) {
                            Text("Terms of Service")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                                .underline()
                        }

                        Text("and")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))

                        Button(action: { openPrivacyPolicy() }) {
                            Text("Privacy Policy")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                                .underline()
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Animate logo and buttons on appear
            logoScale = 1.0
            buttonsOpacity = 1.0
        }
        .sheet(isPresented: $showingSafari) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
        .alert("Authentication Error", isPresented: $authViewModel.showingError) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An unexpected error occurred")
        }
    }

    private func handleGoogleSignIn() {
        // Prevent double taps
        guard !authViewModel.isAuthenticating else { return }
        
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            authViewModel.showError("Unable to access window for authentication")
            return
        }
        authViewModel.signInWithGoogle(presenting: root)
    }
    
    private func openTermsOfService() {
        safariURL = URL(string: "https://recipewallet.ai/terms")
        showingSafari = true
    }
    
    private func openPrivacyPolicy() {
        safariURL = URL(string: "https://recipewallet.ai/privacy")
        showingSafari = true
    }
}

// MARK: - Safari View for In-App Browser
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
