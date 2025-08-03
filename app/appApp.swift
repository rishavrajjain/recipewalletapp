//
//  appApp.swift
//  app
//
//  Created by Rishav Raj Jain on 17/06/25.
//

import SwiftUI
import Firebase

@main
struct appApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.user != nil {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
