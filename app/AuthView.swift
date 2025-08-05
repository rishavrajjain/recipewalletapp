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
    @State private var showingEmailLogin = false
    
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
                        Text("Recipe Wallet")
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
                // Discreet Email Login for Apple Review
                Button(action: { showingEmailLogin = true }) {
                    Text("Login with email")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .underline()
                }
                .padding(.bottom, 16)
                
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
        .sheet(isPresented: $showingEmailLogin) {
            EmailLoginSheet(authViewModel: authViewModel, isPresented: $showingEmailLogin)
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

// MARK: - Email Login Sheet for Apple Review
struct EmailLoginSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.1),
                        Color(red: 1.0, green: 0.78, blue: 0.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 60)
                        
                        // App Logo Section
                        VStack(spacing: 20) {
                            if let logoImage = UIImage(named: "appLogo") {
                                Image(uiImage: logoImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            } else {
                                // Fallback icon
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "fork.knife.circle.fill")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            }
                            
                            // App Title
                            Text("Recipe Wallet AI")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Login to your account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding(.bottom, 50)
                        
                        // Login Form
                        VStack(spacing: 24) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                                
                                TextField("Enter your email", text: $email)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                                
                                SecureField("Enter your password", text: $password)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            // Login Button
                            Button(action: handleLogin) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    }
                                    
                                    Text(isLoading ? "Signing In..." : "Login")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color.black, Color.black.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .scaleEffect(isLoading ? 0.98 : 1.0)
                                .opacity(isLoading ? 0.8 : 1.0)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: isLoading)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        
        authViewModel.signInWithEmail(email: email, password: password) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
