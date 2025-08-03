import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

/// Beautifully designed authentication screen matching the Recipe Wallet brand
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var logoScale: CGFloat = 0.8
    @State private var buttonsOpacity: Double = 0.0
    
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
                    // Google Sign In Button
                    Button(action: handleGoogleSignIn) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black.opacity(0.8))
                            
                            Text("Continue with Google")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Apple Sign In Button
                    SignInWithAppleButton(.signIn) { request in
                        authViewModel.handleAppleSignIn(request: request)
                    } onCompletion: { result in
                        authViewModel.handleAppleSignInCompletion(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 32)
                }
                .opacity(buttonsOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.4), value: buttonsOpacity)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Text("Terms of Service")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("and")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text("Privacy Policy")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black.opacity(0.8))
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
    }

    private func handleGoogleSignIn() {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }
        authViewModel.signInWithGoogle(presenting: root)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
