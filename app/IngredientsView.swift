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
            
            // Simple flat ingredient list (no categories in recipe view)
            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(spacing: 12) {
                        // Simple bullet point
                        Circle()
                            .fill(Color.secondary.opacity(0.6))
                            .frame(width: 6, height: 6)
                        
                        // Ingredient image (conditionally shown)
                        if showImages {
                            AsyncImage(url: ingredient.categoryImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(ingredient.category.color.opacity(0.2))
                                    .overlay(
                                        Image(systemName: ingredient.category.iconName)
                                            .foregroundColor(ingredient.category.color)
                                            .font(.system(size: 16))
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Text(ingredient.name)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .onAppear {
                        if showImages {
                            print("✅ Ingredient \(ingredient.name) category image URL: \(ingredient.categoryImageURL?.absoluteString ?? "nil")")
                        }
                    }
                    
                    if index < recipe.ingredients.count - 1 {
                        Divider()
                            .padding(.leading, showImages ? 58 : 34) // Adjust divider offset based on image visibility
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

struct CategorySection: View {
    let category: IngredientCategory
    let ingredients: [Ingredient]
    let showImages: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(category.color)
                    .frame(width: 20)
                
                Text(category.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(ingredients.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(category.color.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 4)
            
            // Ingredients in this category
            VStack(spacing: 0) {
                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(spacing: 12) {
                        // Category color indicator
                        Rectangle()
                            .fill(category.color)
                            .frame(width: 3, height: 40)
                            .cornerRadius(1.5)
                        
                        // Ingredient image (conditionally shown)
                        if showImages {
                            AsyncImage(url: ingredient.categoryImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(category.color.opacity(0.2))
                                    .overlay(
                                        Image(systemName: category.iconName)
                                            .foregroundColor(category.color)
                                            .font(.system(size: 16))
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Text(ingredient.name)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .onAppear {
                        if showImages {
                            print("✅ Ingredient \(ingredient.name) category image URL: \(ingredient.categoryImageURL?.absoluteString ?? "nil")")
                        }
                    }
                    
                    if index < ingredients.count - 1 {
                        Divider()
                            .padding(.leading, showImages ? 67 : 27) // Adjust divider offset based on image visibility
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
} 