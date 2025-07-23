//
//  InstructionsView.swift
//  app
//
//  Created by Rishav Raj Jain on 20/06/25.
//

import SwiftUI

struct InstructionsView: View {
    let recipe: Recipe
    @StateObject private var imageGeneratorViewModel = StepImageViewModel()
    @State private var showPremiumSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with Generate button
            HStack {
                Text("Instructions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                
                // The "Wand" button to trigger premium feature
                Button {
                    showPremiumSheet = true
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }

            // The list of textual instructions - each in its own card
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .bold()
                            .foregroundStyle(.black)
                            .font(.system(size: 16, weight: .bold))
                        Text(step)
                            .font(.system(size: 15))
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumFeatureSheet()
        }
    }
}

// MARK: - Premium Feature Sheet
struct PremiumFeatureSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Premium Feature")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                        .padding(.top, 32)
                    
                    Text("Get AI-generated step-by-step cooking photos")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 32)
                }
                
                // Visual separator
                Spacer()
                    .frame(height: 48)
                
                // Clean feature list
                VStack(spacing: 24) {
                    FeatureItem(
                        icon: "photo.on.rectangle",
                        text: "Visual cooking guidance for every step"
                    )
                    
                    FeatureItem(
                        icon: "sparkles",
                        text: "AI-powered food preparation images"
                    )
                    
                    FeatureItem(
                        icon: "eye",
                        text: "See exactly how your dish should look"
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // CTA
                VStack(spacing: 16) {
                    Button(action: {
                        openEmailApp()
                        dismiss()
                    }) {
                        Text("Get Access")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Button("Not Now") {
                        dismiss()
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
    
    private func openEmailApp() {
        let email = "sha@cookumber.app"
        let subject = "Access to Premium Features"
        let body = "Hi,\n\nI'd like to learn more about the premium visual cooking features.\n\nThanks!"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .center)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

