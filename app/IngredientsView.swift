import SwiftUI

struct IngredientsView: View {
    let recipe: Recipe
    
    var body: some View {
        DetailSectionView(title: "Ingredients") {
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                Label(ingredient, systemImage: "circle.fill")
                    .font(.body)
                    .imageScale(.small)
                    .foregroundStyle(Color.orange)
            }
        }
    }
} 