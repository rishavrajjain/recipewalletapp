import SwiftUI
import Foundation

struct IngredientsView: View {
    let recipe: Recipe
    
    // Toggle this to show/hide ingredient images
    private let showImages = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(spacing: 12) {
                        // Ingredient image (conditionally shown)
                        if showImages {
                            AsyncImage(url: ingredient.resolvedImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Text(ingredient.name)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .onAppear {
                        if showImages {
                            print("✅ Ingredient \(ingredient.name) image URL: \(ingredient.resolvedImageURL?.absoluteString ?? "nil")")
                        }
                    }
                    
                    if index < recipe.ingredients.count - 1 {
                        Divider()
                            .padding(.leading, showImages ? 78 : 16) // Adjust divider offset based on image visibility
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
} 