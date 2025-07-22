import SwiftUI
import UniformTypeIdentifiers

struct ShoppingListView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var selectedItems = Set<UUID>()
    @State private var isSelectionMode = false
    
    var body: some View {
        NavigationView {
            Group {
                if recipeStore.shoppingList.isEmpty {
                    // Empty state
                    VStack(spacing: 32) {
                        Image(systemName: "cart")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 16) {
                            Text("Shopping List is Empty")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Add ingredients from recipes to build your shopping list!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                } else {
                    // Shopping list with items
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(recipeStore.shoppingList) { item in
                                HStack(spacing: 16) {
                                    // Selection/Checkbox circle
                                    Button(action: {
                                        toggleSelection(for: item)
                                    }) {
                                        Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(selectedItems.contains(item.id) ? Color(red: 0.2, green: 0.6, blue: 0.2) : Color(red: 0.2, green: 0.6, blue: 0.2))
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedItems.contains(item.id))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                        if let fromRecipe = item.fromRecipe {
                                            Text("From: \(fromRecipe)")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                                
                                if item.id != recipeStore.shoppingList.last?.id {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .toolbar {
                if !recipeStore.shoppingList.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            if !selectedItems.isEmpty {
                                Button(action: copySelectedItems) {
                                    Label("Copy Selected", systemImage: "doc.on.clipboard")
                                }
                                
                                Button(action: clearSelectedItems) {
                                    Label("Clear Selected", systemImage: "trash")
                                }
                                
                                Divider()
                            }
                            
                            Button(role: .destructive, action: clearAllItems) {
                                Label("Clear All", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .rotationEffect(.degrees(90))
                        }
                    }
                    
                    if !selectedItems.isEmpty {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Deselect All") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedItems.removeAll()
                                }
                            }
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.2))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Selection Methods
    
    private func toggleSelection(for item: ShoppingListItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
            } else {
                selectedItems.insert(item.id)
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func copySelectedItems() {
        let selectedNames = recipeStore.shoppingList
            .filter { selectedItems.contains($0.id) }
            .map { $0.name }
            .joined(separator: "\n")
        
        UIPasteboard.general.string = selectedNames
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Clear selection after copy
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedItems.removeAll()
        }
    }
    
    private func clearSelectedItems() {
        let itemsToRemove = recipeStore.shoppingList.filter { selectedItems.contains($0.id) }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for item in itemsToRemove {
                recipeStore.removeFromShoppingList(item)
            }
            selectedItems.removeAll()
        }
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func clearAllItems() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            recipeStore.clearShoppingList()
            selectedItems.removeAll()
        }
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
}