import SwiftUI
import UniformTypeIdentifiers

struct ShoppingListView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var selectedItems = Set<UUID>()
    @State private var isSelectionMode = false
    @State private var newItemText = ""
    @State private var showingAddField = false
    @FocusState private var isAddFieldFocused: Bool
    
    // Group shopping list items by category
    private var groupedShoppingListItems: [(key: IngredientCategory?, value: [ShoppingListItem])] {
        let grouped = Dictionary(grouping: recipeStore.shoppingList) { item in
            item.category
        }
        
        // Sort categories: "My Ingredients" first, then other categories alphabetically, then nil
        return grouped.sorted { first, second in
            switch (first.key, second.key) {
            case (.myIngredients, .myIngredients):
                return false // Both myIngredients, maintain order
            case (.myIngredients, _):
                return true // myIngredients always goes first
            case (_, .myIngredients):
                return false // myIngredients always goes first
            case (nil, nil):
                return false // Both nil, maintain order
            case (nil, _):
                return false // nil goes last
            case (_, nil):
                return true // non-nil goes first
            case (let cat1?, let cat2?):
                return cat1.displayName < cat2.displayName // sort by category name
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                                if recipeStore.shoppingList.isEmpty {
                    // Designer Empty State
                    VStack(spacing: 0) {
                        // Add new item field (when empty state)
                        if showingAddField {
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    TextField("Add item", text: $newItemText)
                                        .focused($isAddFieldFocused)
                                        .font(.system(size: 16, weight: .medium))
                                        .onSubmit {
                                            addNewItem()
                                        }
                                        .submitLabel(.done)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                            }
                        }
                        
                        Spacer()
                        
                        // Main elevated card
                        VStack(spacing: 24) {
                            // Icon with subtle background
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "cart")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Your Shopping List is Empty")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Add ingredients from recipes or type your own items")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        Spacer() // Extra spacer to center better
                    }
                } else {
                    // Shopping list with items
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Add new item field
                            if showingAddField {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    TextField("Add item", text: $newItemText)
                                        .focused($isAddFieldFocused)
                                        .font(.system(size: 16, weight: .medium))
                                        .onSubmit {
                                            addNewItem()
                                        }
                                    
                                    Button("Cancel") {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showingAddField = false
                                            newItemText = ""
                                        }
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                Divider()
                                    .padding(.leading, 52)
                            }
                            
                            // Group items by category for better organization
                            ForEach(groupedShoppingListItems, id: \.key) { categoryGroup in
                                // Category header (only if items have categories)
                                if let category = categoryGroup.key {
                                    HStack(spacing: 8) {
                                        Image(systemName: category.iconName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(category.color)
                                            .frame(width: 20)
                                        
                                        Text(category.displayName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(categoryGroup.value.count)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(category.color.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                }
                                
                                ForEach(categoryGroup.value) { item in
                                HStack(spacing: 16) {
                                    // Selection/Checkbox circle
                                    Button(action: {
                                        toggleSelection(for: item)
                                    }) {
                                        Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(selectedItems.contains(item.id) ? Color(red: 0.15, green: 0.4, blue: 0.2) : Color(red: 0.15, green: 0.4, blue: 0.2))
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
                                
                                    if item.id != categoryGroup.value.last?.id {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                        }
                        
                        // Bottom padding to account for custom tab bar
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .toolbar {
                // Add button (always visible)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !recipeStore.shoppingList.isEmpty && !showingAddField {
                        Menu {
                            Button(action: {
                                withAnimation(.easeIn(duration: 0.2)) {
                                    showingAddField = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isAddFieldFocused = true
                                }
                            }) {
                                Label("Add Item", systemImage: "plus")
                            }
                            
                            Divider()
                            
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
                    } else if recipeStore.shoppingList.isEmpty {
                        Button(action: {
                            withAnimation(.easeIn(duration: 0.2)) {
                                showingAddField = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isAddFieldFocused = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                        }
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
                        .foregroundColor(Color(red: 0.15, green: 0.4, blue: 0.2))
                    }
                }
            }
        }
    }
    
    // MARK: - Adding Items
    
    private func addNewItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Check if item already exists
        let existsAlready = recipeStore.shoppingList.contains { item in
            item.name.lowercased() == trimmedText.lowercased()
        }
        
        if !existsAlready {
            let newItem = ShoppingListItem(name: trimmedText, category: .myIngredients, fromRecipe: nil)
            recipeStore.shoppingList.insert(newItem, at: 0)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        // Reset and hide field
        newItemText = ""
        withAnimation(.easeOut(duration: 0.2)) {
            showingAddField = false
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