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
                    // Designer Empty State
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Main elevated card
                        VStack(spacing: 24) {
                            // Icon with subtle background
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "cart")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Your Shopping List is Empty")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Start by adding ingredients from your favorite recipes to build your shopping list")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        
                        // Left-aligned tip section
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Text("💡")
                                            .font(.system(size: 14))
                                        Text("Quick Tip")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("Go to Home → View any recipe → Tap ingredients to add them here")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        Spacer()
                        Spacer() // Extra spacer to center better
                    }
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