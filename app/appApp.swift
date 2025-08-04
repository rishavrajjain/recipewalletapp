//
//  appApp.swift
//  app
//
//  Created by Rishav Raj Jain on 17/06/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct appApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isLoading = true

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    // Show loading screen during initial auth check
                    LoadingView()
                } else if authViewModel.user != nil {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
                }
            }
            .onReceive(authViewModel.$user) { user in
                // Add a small delay to prevent flicker during auth transitions
                if user != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoading = false
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
            .onAppear {
                // Check initial auth state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if Auth.auth().currentUser == nil {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
}

// Simple loading view to prevent flicker
struct LoadingView: View {
    var body: some View {
        ZStack {
            // Brand yellow background to match auth screen
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.1),
                    Color(red: 1.0, green: 0.78, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App logo or icon
                if let logoImage = UIImage(named: "appLogo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                } else {
                    // Fallback icon
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.black.opacity(0.8))
                }
                
                Text("Recipe Wallet AI")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.black)
            }
        }
    }
}
