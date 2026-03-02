//
//  MainTab.swift
//  P.R.O.
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import SwiftUI
import CoreLocation
import MapKit
import HealthKit
import CoreData

// MARK: - Tab Item Enum
enum TabItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case workouts = "Workouts"
    // case trainingPlan = "Training Plan"  // DISABLED FOR V1
    case statistics = "Stats"
    case profile = "Profile"
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .home: return String(localized: "Home", comment: "Tab bar item")
        case .workouts: return String(localized: "Workouts", comment: "Tab bar item")
        case .statistics: return String(localized: "Stats", comment: "Tab bar item")
        case .profile: return String(localized: "Profile", comment: "Tab bar item")
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .workouts: return "figure.run"
        // case .trainingPlan: return "checklist"  // DISABLED FOR V1
        case .statistics: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .workouts: return "figure.run"
        // case .trainingPlan: return "checklist"  // DISABLED FOR V1
        case .statistics: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    
    @StateObject private var runningMapViewModel = RunningMapViewModel()

    @ObservedObject var coordinator = NavigationCoordinator.shared

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    
    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }
    
    var body: some View {
        ZStack {
            EnhancedSideMenuContainer {
                TabView(selection: $coordinator.currentTab) {
                    // Home Tab
                    NavigationView {
                        AllDashboardView()
                            .trackScreenTime(screenName: "main_dashboard")
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(.stack)
                    .tabItem {
                        Image(systemName: coordinator.currentTab == .home ? TabItem.home.selectedIcon : TabItem.home.icon)
                        Text(TabItem.home.displayName)
                    }
                    .tag(TabItem.home)
                    
                    // Workouts Tab
                    NavigationView {
                        WorkoutListView()
                            .trackScreenTime(screenName: "workout_list")
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(.stack)
                    .tabItem {
                        Image(systemName: coordinator.currentTab == .workouts ? TabItem.workouts.selectedIcon : TabItem.workouts.icon)
                        Text(TabItem.workouts.displayName)
                    }
                    .tag(TabItem.workouts)
                    
                    // Training Plan Tab - DISABLED FOR V1 RELEASE
                    /* COMMENTED OUT FOR APP STORE V1
                    NavigationView {
                        EnhancedTrainingPlanView()
                            .trackScreenTime(screenName: "training_plan")
                            .navigationBarHidden(true)
                    }
                    .tabItem {
                        Image(systemName: coordinator.currentTab == .trainingPlan ? TabItem.trainingPlan.selectedIcon : TabItem.trainingPlan.icon)
                        Text(TabItem.trainingPlan.rawValue)
                    }
                    .tag(TabItem.trainingPlan)
                    */
                    
                    // Statistics Tab
                    NavigationView {
                        DashboardView()
                            .trackScreenTime(screenName: "statistics_dashboard")
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(.stack)
                    .tabItem {
                        Image(systemName: coordinator.currentTab == .statistics ? TabItem.statistics.selectedIcon : TabItem.statistics.icon)
                        Text(TabItem.statistics.displayName)
                    }
                    .tag(TabItem.statistics)
                    
                    // Profile Tab
                    NavigationView {
                        ProfileView()
                            .trackScreenTime(screenName: "user_profile")
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(.stack)
                    .tabItem {
                        Image(systemName: coordinator.currentTab == .profile ? TabItem.profile.selectedIcon : TabItem.profile.icon)
                        Text(TabItem.profile.displayName)
                    }
                    .tag(TabItem.profile)
                }
                .accentColor(accentColor)
                .onAppear {
                    // Customize tab bar appearance
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor.systemBackground
                    
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
            
            // Sync overlay
            SyncOverlayView()
                .zIndex(1000)
        }
        .checkPermissions() // Проверяем разрешения при запуске
        .accentColor(accentColor)
        .ignoresSafeArea(.container, edges: .all)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMonthlySummary"))) { _ in
            // Handle monthly summary notification tap
            coordinator.selectMenuItem(.monthlySummary)
        }
        // COMMENTED OUT FOR V1 - Training Plan notifications
        /*.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenTrainingPlanUpdate"))) { _ in
            // Handle training plan update notification tap
            coordinator.currentTab = .trainingPlan
        }*/
    }
}

