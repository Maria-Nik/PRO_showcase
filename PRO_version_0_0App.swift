//
//  PRO_version_0_0App.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import SwiftUI
import Firebase
import CoreData

@main
struct PRO_version_0_0App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject var bonusManager = BonusManager.shared
    @StateObject var permissionManager = PermissionManager.shared
    @StateObject var dataProcessingManager = DataProcessingManager.shared
    @StateObject var authManager = AuthenticationManager()
    @StateObject var userDataManager = UserDataManager.shared
    @StateObject var themeManager = ThemeManager.shared
    
    init() {
        // Firebase is configured in AppDelegate
    }
    
    var body: some Scene {
        WindowGroup {
                        AuthenticationCheckView()
                .environmentObject(bonusManager)
                .environmentObject(permissionManager)
                .environmentObject(dataProcessingManager)
                .environmentObject(authManager)
                .environmentObject(userDataManager)
                .environmentObject(themeManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(themeManager.colorScheme)
            
            // FIX: Removed duplicate DataProcessingView overlay
            // The InitialDataProcessingView in OnboardingView handles all progress display
            
            // Record notifications overlay
            RecordNotificationOverlay()
                .zIndex(1001)
            
        }
    }
}
