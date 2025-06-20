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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with Generate button
            HStack {
                Text("Instructions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                
                // The "Wand" button to trigger image generation
                Button {
                    imageGeneratorViewModel.generateImages(for: recipe.steps, recipeTitle: recipe.name)
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                        .foregroundColor(.pink)
                }
                // Disable if already loading or has images to prevent re-tapping
                .disabled(imageGeneratorViewModel.isLoading || !imageGeneratorViewModel.generatedImages.isEmpty)
            }
            
            // Container for the loading view and the final image carousel
            StepImageCarouselContainer(viewModel: imageGeneratorViewModel)
            
            // The list of textual instructions - each in its own card
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .bold()
                            .foregroundStyle(.pink)
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
    }
}

