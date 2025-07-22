import SwiftUI
import Foundation

struct IngredientsView: View {
    let recipe: Recipe
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var showingAddedToast = false
    
    // Toggle this to show/hide ingredient images
    private let showImages = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                                // Add to Cart Icon
                Button(action: {
                    addIngredientsToShoppingList()
                }) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 0.15, green: 0.4, blue: 0.2))
                }
                .buttonStyle(.plain)
            }
            
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
        .overlay(
            // Toast notification
            VStack {
                if showingAddedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Added to Shopping List!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
        )
    }
    
    private func addIngredientsToShoppingList() {
        recipeStore.addIngredientsToShoppingList(recipe.ingredients)
        
        // Show toast notification
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingAddedToast = true
        }
        
        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingAddedToast = false
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
} 