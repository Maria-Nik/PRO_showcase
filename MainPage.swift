//
//  Donut chart.swift
//  P.R.O.
//
//  Created by Maria Nikolaeva on 04.04.2025.
//
import SwiftUI
import Charts
import HealthKit
import MapKit
import CoreData


struct SleepData: Identifiable {
    let id = UUID()
    let hour: Int
    let quality: Double
}

struct Goal: Identifiable {
    let id = UUID()
    let title: String
    var progress: Double // 0.0 to 1.0
}
struct GlobalGoals: Identifiable, Codable {
    let id: UUID
    var title: String
    var progress: Double
    var sportType: SportType // Новый параметр
    var unit: Unit // Новый параметр
    var targetValue: Double // Новый параметр
    
    init(title: String, progress: Double, sportType: SportType, unit: Unit, targetValue: Double) {
        self.id = UUID()
        self.title = title
        self.progress = progress
        self.sportType = sportType
        self.unit = unit
        self.targetValue = targetValue
    }

    enum SportType: String, CaseIterable, Codable {
        case running = "Running"
        case cycling = "Cycling"
        case swimming = "Swimming"
        case walking = "Walking"
        case other = "Other"
        
        var displayName: String {
            switch self {
            case .running: return String(localized: "Running", comment: "Sport type name")
            case .cycling: return String(localized: "Cycling", comment: "Sport type name")
            case .swimming: return String(localized: "Swimming", comment: "Sport type name")
            case .walking: return String(localized: "Walking", comment: "Sport type name")
            case .other: return String(localized: "Other", comment: "Sport type name")
            }
        }
    }

    enum Unit: String, CaseIterable, Codable {
        case kilometers = "km"
        case miles = "mi"
        case hours = "h"
        case calories = "kcal"
    }
}


struct DashboardCard<Content: View>: View {
    let background: Color
    let content: Content
    let width: CGFloat
    let height: CGFloat
    @Environment(\.colorScheme) var colorScheme

    init(background: Color? = nil, width: CGFloat = 170, height: CGFloat = 120, @ViewBuilder content: () -> Content) {
        self.background = background ?? (Color(.systemBackground))
        self.width = width
        self.height = height
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: width, height: height)
            .background(background)
            .cornerRadius(24)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.07), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
            )
    }
}

// MARK: - HealthRingsView
struct HealthRingsView: View {
    @Binding var showDetail: Bool
    var stepsProgress: Double // 0...1
    var caloriesProgress: Double // 0...1
    var floorsProgress: Double // 0...1
    
    @State private var animatedStepsProgress: Double = 0
    @State private var animatedCaloriesProgress: Double = 0
    @State private var animatedFloorsProgress: Double = 0

    var body: some View {
        ZStack {
            // Steps (outer, biggest) - Background
            Circle()
                .stroke(Color.green.opacity(0.2), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .frame(width: 140, height: 140)
            
            // Steps (outer, biggest) - Animated Progress
            Circle()
                .trim(from: 0, to: animatedStepsProgress)
                .stroke(Color.green.opacity(0.8), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: 140)
                .animation(.easeOut(duration: 1.0), value: animatedStepsProgress)
            
            // Calories (middle) - Background
            Circle()
                .stroke(Color.orange.opacity(0.2), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 110, height: 110)
            
            // Calories (middle) - Animated Progress
            Circle()
                .trim(from: 0, to: animatedCaloriesProgress)
                .stroke(Color.orange.opacity(0.8), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 110, height: 110)
                .animation(.easeOut(duration: 1.0), value: animatedCaloriesProgress)
            
            // Floors (inner, smallest) - Background
            Circle()
                .stroke(Color.purple.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 80, height: 80)
            
            // Floors (inner, smallest) - Animated Progress
            Circle()
                .trim(from: 0, to: animatedFloorsProgress)
                .stroke(Color.purple.opacity(0.8), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 84, height: 84)
                .animation(.easeOut(duration: 1.0), value: animatedFloorsProgress)
        }
        .frame(width: 160, height: 160)
        .onTapGesture {
            showDetail = true
        }
        .onAppear {
            // Простая анимация при появлении
            withAnimation(.easeOut(duration: 1.0)) {
                animatedStepsProgress = stepsProgress
                animatedCaloriesProgress = caloriesProgress
                animatedFloorsProgress = floorsProgress
            }
        }
        .onChange(of: stepsProgress) { oldValue, newValue in
            print("Steps progress changed from \(oldValue) to \(newValue)")
            withAnimation(.easeOut(duration: 0.5)) {
                animatedStepsProgress = newValue
            }
        }
        .onChange(of: caloriesProgress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedCaloriesProgress = newValue
            }
        }
        .onChange(of: floorsProgress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedFloorsProgress = newValue
            }
        }
    }
}

// --- RingsDetailEditorView ---
struct RingsDetailEditorView: View {
    @Binding var stepsGoal: Int
    @Binding var caloriesGoal: Int
    @Binding var floorsGoal: Int
    var stepsValue: Int
    var caloriesValue: Int
    var floorsValue: Int
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                ForEach([("Steps", stepsValue, stepsGoal, Color.green, $stepsGoal),
                         ("Calories", caloriesValue, caloriesGoal, Color.orange, $caloriesGoal),
                         ("Floors", floorsValue, floorsGoal, Color.purple, $floorsGoal)], id: \.0) { label, value, goal, color, binding in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(label)
                                .font(.headline)
                                .foregroundColor(color)
                            Spacer()
                            Text("\(value) / \(goal)")
                                .font(.title3).bold()
                        }
                        ProgressView(value: min(Double(value) / Double(goal == 0 ? 1 : goal), 1.0))
                            .tint(color)
                        Text(String(format: "%.0f%% of goal", 100 * (goal == 0 ? 0 : Double(value) / Double(goal))))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("Goal:")
                            TextField("Goal", value: binding, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(16)
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("Daily Goals", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - ReadinessMetricCard
struct ReadinessMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct AllDashboardView: View {
    @StateObject private var sleepManager = SleepDataManager()
    @StateObject private var bonusSystem = BonusManager.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Helper function to get the current window scene
    private func getCurrentWindowScene() -> UIWindowScene? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene
    }
    
    @State private var globalgoals: [GlobalGoals] = []
    @State private var steps: String = "0"
    @State private var activeEnergy: String = "0 kcal"
    @State private var distance: String = "0 km"
    @State private var flightsClimbed: String = "0" {
        didSet {
            print("🪜 flightsClimbed changed from \(oldValue) to \(flightsClimbed)")
        }
    }
    @State private var isGoalsExpanded: Bool = false
    @State private var isSleepExpanded: Bool = false
    @State private var isDayGoalExpanded: Bool = false
    @State private var isHealthDataLoading: Bool = false
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"

    // --- New for editing goals ---
    @AppStorage("stepsGoal") private var stepsGoal: Int = 10000
    @AppStorage("caloriesGoal") private var caloriesGoal: Int = 500
    @AppStorage("floorsGoal") private var floorsGoal: Int = 20
    @State private var showRingsDetail = false

    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    let readiness = 74
    
    // Readiness Widget Computed Properties
    var readinessStatusIcon: String {
        switch readiness {
        case 0..<40: return "exclamationmark.triangle.fill"
        case 40..<70: return "pause.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    var readinessStatusColor: Color {
        switch readiness {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    var readinessStatusTitle: String {
        switch readiness {
        case 0..<40: return "Not Ready"
        case 40..<70: return "Moderate"
        default: return "Ready to Train"
        }
    }
    
    var readinessStatusDescription: String {
        switch readiness {
        case 0..<40: return "Consider rest or light activity"
        case 40..<70: return "Moderate intensity workout recommended"
        default: return "Perfect for high-intensity training"
        }
    }
    
    var readinessRecommendation: String {
        switch readiness {
        case 0..<40: return "Focus on recovery today. Try gentle stretching, yoga, or a light walk. Your body needs rest to perform better tomorrow."
        case 40..<70: return "Good day for moderate training. Consider a steady-state cardio session or moderate strength training with proper warm-up."
        default: return "Excellent conditions for intense training! Push your limits with high-intensity intervals, heavy lifting, or challenging endurance work."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // NeuroButton Section
                HStack {
                    Spacer()
                    NeuroButton()
                        .padding(.trailing, 16)
                }
                .padding(.top, 8)
                
                // Today's Activity Section
                VStack(spacing: 8) {
                    HStack {
                        Text("Today's Activity")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            print("🔄 Manual refresh triggered")
                            loadHealthData()
                            loadSleepData()
                        }) {
                            if isHealthDataLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                        .disabled(isHealthDataLoading)
                        
                        // Show permission status indicator
                        if !HKHealthStore.isHealthDataAvailable() {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .onTapGesture {
                                    // Show alert about HealthKit not being available
                                    let alert = UIAlertController(
                                        title: "Health Data Unavailable",
                                        message: "HealthKit is not available on this device.",
                                        preferredStyle: .alert
                                    )
                                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                                    getCurrentWindowScene()?.windows.first?.rootViewController?.present(alert, animated: true)
                                }
                        } else if permissionManager.healthKitStatus != .authorized {
                            // Check permission status using PermissionManager for accurate status
                            Image(systemName: "lock.fill")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    // Show informational alert when user actively taps the feature
                                    // Use PermissionMessageHelper for consistent messaging
                                    PermissionMessageHelper.showPermissionAlert(
                                        permissionType: .healthKit,
                                        featureName: "This view"
                                    )
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    HStack(spacing: 8) {
                        DashboardCard(width: 170, height: 120) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "figure.walk")
                                        .foregroundColor(.green)
                                    Spacer()
                                    if isHealthDataLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.green)
                                    } else {
                                        Text(steps)
                                            .font(.title)
                                            .bold()
                                    }
                                }
                                Text("Steps")
                                    .font(.headline)
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        DashboardCard(width: 170, height: 120) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Spacer()
                                    if isHealthDataLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.orange)
                                    } else {
                                        Text(activeEnergy)
                                            .font(.title3)
                                            .bold()
                                    }
                                }
                                Text("Active Energy")
                                    .font(.headline)
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        
                    }
                    HStack(spacing: 8) {
                        DashboardCard(width: 170, height: 120) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "figure.walk.motion")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    if isHealthDataLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text(distance)
                                            .font(.title3)
                                            .bold()
                                    }
                                }
                                Text("Distance")
                                    .font(.headline)
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        DashboardCard(width: 170, height: 120) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "figure.stairs")
                                        .foregroundColor(.purple)
                                    Spacer()
                                    if isHealthDataLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.purple)
                                    } else {
                                        Text(flightsClimbed)
                                            .font(.title3)
                                            .bold()
                                    }
                                }
                                Text("Flights Up")
                                    .font(.headline)
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
                .padding(.top, 16)

                // Новый отдельный BonusWidgetCompact
                BonusWidgetCompact()
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .padding(.horizontal, 16)

                // Streak Tracking Widget
                StreakTrackingWidget()
                    .padding(.horizontal, 16)

                // --- GOALS SECTION (moved below activity) ---
                HStack(alignment: .center, spacing: 16) {
                    // Health Rings (только кольца, без карточки)
                    HealthRingsView(
                        showDetail: $showRingsDetail,
                        stepsProgress: min((Double(steps) ?? 0) / Double(stepsGoal), 1.0),
                        caloriesProgress: min((Double(activeEnergy.split(separator: " ").first ?? "0") ?? 0) / Double(caloriesGoal), 1.0),
                        floorsProgress: min((Double(flightsClimbed) ?? 0) / Double(floorsGoal), 1.0)
                    )
                    .frame(width: 160, height: 160)
                    
                    // Компактный виджет целей (увеличенный размер)
                    AllGoalsWidget()
                        .onTapGesture {
                            isGoalsExpanded = true
                        }
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                // Новый Steps Analysis Widget
                StepsAnalysisWidget()
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding(.horizontal, 16)

                // // Records Widget
                // CompactRecordsWidget()
                //     .frame(maxWidth: .infinity, minHeight: 120)
                //     .padding(.horizontal, 16)

                // Monthly Summary Widget
                MonthlySummaryWidget()
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding(.horizontal, 16)

                // Premium Training Plan Promotion
                // Training plan is now available in side menu
                // PremiumTrainingPlanPromotion()
                //     .frame(maxWidth: .infinity, minHeight: 120)
                //     .padding(.horizontal, 16)

                // --- SLEEP ZONES BAR WIDGET (full width) ---
                SleepZonesBarWidget(sleepSamples: sleepManager.sleepSamples, sleepManager: sleepManager)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .onAppear {
                        print("🌙 Sleep widget appeared with \(sleepManager.sleepSamples.count) samples")
                    }
//                // Readiness Widget
//                VStack(spacing: 16) {
//                    // Main Readiness Card
//                    VStack(alignment: .leading, spacing: 20) {
//                        // Header
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("Workout Readiness")
//                                    .font(.title2)
//                                    .bold()
//                                Text("Based on your recent activity and recovery")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                            }
//                            Spacer()
//                            ZStack {
//                                Circle()
//                                    .stroke(Color.green.opacity(0.2), lineWidth: 8)
//                                    .frame(width: 60, height: 60)
//                                Circle()
//                                    .trim(from: 0, to: CGFloat(readiness) / 100)
//                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
//                                    .rotationEffect(.degrees(-90))
//                                    .animation(.easeOut(duration: 1.0), value: readiness)
//                                Text("\(readiness)%")
//                                    .font(.headline)
//                                    .bold()
//                            }
//                        }
//                        
//                        // Readiness Status
////                        HStack {
////                            Image(systemName: readinessStatusIcon)
////                                .font(.title2)
////                                .foregroundColor(readinessStatusColor)
////                            VStack(alignment: .leading, spacing: 2) {
////                                Text(readinessStatusTitle)
////                                    .font(.headline)
////                                    .foregroundColor(readinessStatusColor)
////                                Text(readinessStatusDescription)
////                                    .font(.caption)
////                                    .foregroundColor(.secondary)
////                            }
////                            Spacer()
////                        }
////                        .padding(.horizontal, 16)
////                        .padding(.vertical, 12)
////                        .background(readinessStatusColor.opacity(0.1))
////                        .cornerRadius(12)
//                        
//                        // Metrics Grid
//                        // LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
//                        //     ReadinessMetricCard(
//                        //         title: "Sleep Quality",
//                        //         value: "85%",
//                        //         icon: "bed.double.fill",
//                        //         color: .blue,
//                        //         trend: "+5%"
//                        //     )
//                            
//                        //     ReadinessMetricCard(
//                        //         title: "Recovery",
//                        //         value: "92%",
//                        //         icon: "heart.fill",
//                        //         color: .green,
//                        //         trend: "+3%"
//                        //     )
//                            
//                        //     ReadinessMetricCard(
//                        //         title: "Fatigue",
//                        //         value: "18%",
//                        //         icon: "battery.25",
//                        //         color: .orange,
//                        //         trend: "-2%"
//                        //     )
//                            
//                        //     ReadinessMetricCard(
//                        //         title: "Motivation",
//                        //         value: "88%",
//                        //         icon: "flame.fill",
//                        //         color: .red,
//                        //         trend: "+7%"
//                        //     )
//                        // }
//                        
//                        // Recommendation
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Today's Recommendation")
//                                .font(.headline)
//                                .foregroundColor(.primary)
//                            Text(readinessRecommendation)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .lineLimit(nil)
//                        }
//                        .padding(16)
//                        .background(Color(.systemGray6))
//                        .cornerRadius(12)
//                    }
//                    .padding(20)
//                    .background(Color(.systemBackground))
//                    .cornerRadius(20)
//                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.07), radius: 8, x: 0, y: 4)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 20)
//                            .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
//                    )
//                }
//                .padding(.horizontal, 16)
                TrainingCalendarView()
                        .padding()
                
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            print("🏠 AllDashboardView appeared - starting health data loading")
            
            // Check permissions when view appears
            permissionManager.checkCurrentPermissions()
            
            // Update widget data
            WidgetIntegrationManager.shared.updateWidgetsOnAppBecomeActive()
            
            // Add a small delay to ensure HealthKit is ready (reduced delay)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Load health data for today's activity (NOT workout syncing)
                loadHealthData()
                // Load sleep data
                loadSleepData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("🔄 App became active - refreshing permissions and health data")
            // Refresh permission status when app becomes active (e.g., user returned from Settings)
            permissionManager.checkCurrentPermissions()
            // Refresh health data when app becomes active (NOT workout syncing)
            loadHealthData()
            loadSleepData()
        }
        .onAppear {
            // Check permissions when view appears
            permissionManager.checkCurrentPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            print("🎉 Onboarding completed - triggering initial data load")
            // Trigger data loading when onboarding is completed (reduced delay)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                loadHealthData()
                loadSleepData()
            }
        }
        .sheet(isPresented: $isSleepExpanded) {
            SleepView()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding()
        }
        .sheet(isPresented: $isDayGoalExpanded) {
            GoalTrackingView()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding()
        }
        .sheet(isPresented: $isGoalsExpanded) {
            GoalTrackingView()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding()
        }
        .sheet(isPresented: $showRingsDetail) {
            RingsDetailEditorView(
                stepsGoal: $stepsGoal,
                caloriesGoal: $caloriesGoal,
                floorsGoal: $floorsGoal,
                stepsValue: Int(steps) ?? 0,
                caloriesValue: Int(activeEnergy.split(separator: " ").first ?? "0") ?? 0,
                floorsValue: Int(flightsClimbed) ?? 0
            )
        }
        .navigationBarHidden(true)
    }
    
    private func loadSleepData() {
        print("🔄 Loading sleep data...")
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            return
        }
        
        // Check if sleep permissions are granted
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Sleep analysis type not available")
            return
        }
        
        let healthStore = HKHealthStore()
        let authorizationStatus = healthStore.authorizationStatus(for: sleepType)
        
        if authorizationStatus == .sharingAuthorized {
            // Permissions granted, load sleep data
            print("✅ Sleep permissions granted, loading data...")
            sleepManager.requestAuthorization()
        } else {
            print("❌ Sleep permissions not granted. Status: \(authorizationStatus.rawValue)")
            // Try to request permissions
            print("🔄 Requesting sleep permissions...")
            sleepManager.requestAuthorization()
        }
    }
    
    private func loadHealthData() {
        isHealthDataLoading = true
        print("🔄 Starting health data loading...")
        
        // Check if HealthKit permissions are granted first
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            isHealthDataLoading = false
            return
        }
        
        // Use PermissionManager's improved permission checking
        // This handles read-only permissions correctly
        Task {
            // First, check current permission status
            await permissionManager.checkHealthKitPermissions()
            
            let status = await MainActor.run {
                permissionManager.healthKitStatus
            }
            
            if status == .authorized {
                // We have permissions (either read or write), try to load data
                await MainActor.run {
                    self.loadHealthDataAfterPermissions()
                }
            } else if status == .notDetermined {
                print("⚠️ Permissions not determined yet. Trying to request permissions and load data...")
                // For first-time users, try to request permissions and then load data
                let success = await permissionManager.requestHealthKitPermissions()
                if success {
                    print("✅ Permissions granted, loading data...")
                    await MainActor.run {
                        self.loadHealthDataAfterPermissions()
                    }
                } else {
                    print("❌ Failed to get permissions")
                    await MainActor.run {
                        self.setDefaultValues()
                    }
                }
            } else {
                // Denied or unavailable
                print("❌ HealthKit permissions not granted. Status: \(status)")
                await MainActor.run {
                    self.setDefaultValues()
                }
            }
        }
    }
    
    private func loadHealthDataAfterPermissions() {
        print("🔄 Loading health data after permissions granted...")
        let group = DispatchGroup()
        
        var loadedSteps: Double = 0
        var loadedEnergy: Double = 0
        var loadedDistance: Double = 0
        var loadedFlights: Double = 0
        
        // Load steps
        group.enter()
        HealthKitManager.shared.fetchTodayStepCount { steps in
            loadedSteps = steps
            DispatchQueue.main.async {
                self.steps = "\(Int(steps))"
            }
            group.leave()
        }
        
        // Load active energy
        group.enter()
        HealthKitManager.shared.fetchTodayActiveEnergy { energy in
            loadedEnergy = energy
            DispatchQueue.main.async {
                self.activeEnergy = "\(Int(energy)) kcal"
            }
            group.leave()
        }
        
        // Load distance
        group.enter()
        HealthKitManager.shared.fetchTodayDistance { distance in
            loadedDistance = distance
            DispatchQueue.main.async {
                self.distance = String(format: "%.1f km", distance/1000)
            }
            group.leave()
        }
        
        // Load flights climbed
        group.enter()
        HealthKitManager.shared.fetchTodayFlightsClimbed { flights in
            loadedFlights = flights
            DispatchQueue.main.async {
                self.flightsClimbed = "\(Int(flights))"
                print("🪜 Flights climbed loaded: \(flights) -> UI updated to: \(self.flightsClimbed)")
            }
            group.leave()
        }
        
        // When all data is loaded
        group.notify(queue: .main) {
            self.isHealthDataLoading = false
            
            // Check if we got zero data across all metrics
            let totalData = loadedSteps + loadedEnergy + loadedDistance + loadedFlights
            if totalData == 0 {
                print("⚠️ No health data found - checking if we have read permissions...")
                // Verify if we can read but just have no data
                Task {
                    let (canRead, hasData) = await self.permissionManager.verifyHealthKitDataAccess()
                    if canRead && !hasData {
                        // We have read permissions but no data - show helpful message
                        print("ℹ️ Can read HealthKit data but no data found - showing alert")
                        DispatchQueue.main.async {
                            PermissionMessageHelper.showNoDataFoundAlert()
                        }
                    }
                }
            } else {
                print("✅ All health data loaded successfully after permissions")
            }
        }
    }
    
    private func setDefaultValues() {
        print("📊 Setting default values")
        self.steps = "0"
        self.activeEnergy = "0 kcal"
        self.distance = "0.0 km"
        self.flightsClimbed = "0"
        self.isHealthDataLoading = false
    }
}

struct WidgetCard<Content: View>: View {
    let content: Content
    let width: CGFloat
    let height: CGFloat
    let hasHeader: Bool
    let headerTitle: String?
    let headerActionSymbol: String?
    let onHeaderTap: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme

    init(
        width: CGFloat = 180,
        height: CGFloat = 220,
        hasHeader: Bool = false,
        headerTitle: String? = nil,
        headerActionSymbol: String? = nil,
        onHeaderTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.height = height
        self.hasHeader = hasHeader
        self.headerTitle = headerTitle
        self.headerActionSymbol = headerActionSymbol
        self.onHeaderTap = onHeaderTap
        self.content = content()
    }
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground).opacity(0.1)
                    
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 5) // Легкое размытие
            .cornerRadius(20)
            VStack(alignment: .leading, spacing: 0) {
                // 1) Шапка всегда вверху
                if hasHeader, let title = headerTitle {
                    WidgetHeader(
                        title: title,
                        actionSymbol: headerActionSymbol ?? "chevron.right",
                        onTapAction: onHeaderTap
                    )
                    .padding(.top, 15)
                    .padding(.horizontal, 15)
                }
                
                // 2) Контент сразу под шапкой
                content
                    .frame(maxWidth: .infinity)
                    .padding()       // отступы вокруг, чтобы диаграмма не прилегала вплотную
                    .aspectRatio(1, contentMode: .fit) // квадратный контейнер
                
                // 3) Если нужно, спейсер только снизу
                Spacer(minLength: 0)
            }
            .frame(width: width, height: height)
                        
            .cornerRadius(20)
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
            )
        }
        }
}
struct WidgetHeader: View {
    let title: String
    var actionSymbol: String = "chevron.right"
    var onTapAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                onTapAction?()
            }) {
                Image(systemName: actionSymbol)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct TrainingCalendarView: View {
    let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()
    let currentMonth: Date = Date()
    @State private var trainingData: [Date: [HKWorkout]] = [:] // Завершённые тренировки
    @State private var plannedTraining: [Date: String] = [:] // Планируемые тренировки
    private let healthStore = HKHealthStore()
    private let plannedTrainingKey = "PlannedTraining"
    
    // Sheet state using Identifiable item to avoid blank-first-present issues
    private enum ActiveSheet: Identifiable {
        case workoutDetails(date: Date, workout: HKWorkout)
        case trainingPlanning(date: Date)
        case plannedTrainingInfo(date: Date)
        case multipleWorkouts(date: Date)

        var id: String {
            switch self {
            case let .workoutDetails(date, workout):
                return "workout-\(date.timeIntervalSince1970)-\(workout.uuid.uuidString)"
            case let .trainingPlanning(date):
                return "plan-\(date.timeIntervalSince1970)"
            case let .plannedTrainingInfo(date):
                return "info-\(date.timeIntervalSince1970)"
            case let .multipleWorkouts(date):
                return "multi-\(date.timeIntervalSince1970)"
            }
        }
    }

    @State private var activeSheet: ActiveSheet? = nil
    @State private var selectedDate: Date = Date()
    @State private var plannedTrainingType = ""
    @State private var plannedTrainingGoal = ""
    @State private var isLoadingWorkouts = true
    
    var body: some View {
        VStack {
            Text("Training Calendar")
                .font(.title)
                .bold()
                .padding(.top)

            if isLoadingWorkouts || trainingData.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading workout data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let days = generateCalendarDays(for: currentMonth)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    ForEach(days, id: \.self) { date in
                        // Use consistent date normalization
                        let normalizedDate = normalizeDate(date)
                        let count = trainingData[normalizedDate]?.count ?? 0
                        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        let isToday = calendar.isDateInToday(date)
                        let isPlanned = plannedTraining.keys.contains(normalizedDate)
                        CalendarDayView(
                            date: date,
                            trainingCount: count,
                            isCurrentMonth: isCurrentMonth,
                            isToday: isToday,
                            isPlanned: isPlanned
                        )
                        .onTapGesture {
                            selectedDate = normalizedDate
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .full
                            dateFormatter.timeStyle = .short
                            dateFormatter.timeZone = TimeZone.current
                            
                            print("🔍 Original date: \(date)")
                            print("🔍 Normalized date: \(normalizedDate)")
                            print("🔍 Formatted normalized date: \(dateFormatter.string(from: normalizedDate))")
                            print("🔍 Training data count: \(trainingData.count)")
                            print("🔍 Workouts for this date: \(trainingData[normalizedDate]?.count ?? 0)")
                            print("🔍 Is loading: \(isLoadingWorkouts)")
                            
                            // If still loading, try to fetch workouts again
                            if isLoadingWorkouts {
                                print("🔄 Still loading, triggering fetch again...")
                                fetchWorkouts()
                                return
                            }
                            
                            // Check if we have workouts for this date
                            let workoutsForDate = trainingData[normalizedDate] ?? []
                            if !workoutsForDate.isEmpty {
                                print("🔍 Found \(workoutsForDate.count) workout(s) for date")
                                if workoutsForDate.count == 1 {
                                    if let onlyWorkout = workoutsForDate.first {
                                        activeSheet = .workoutDetails(date: normalizedDate, workout: onlyWorkout)
                                    }
                                    print("🔍 Showing single workout details")
                                } else {
                                    activeSheet = .multipleWorkouts(date: normalizedDate)
                                    print("🔍 Showing multiple workouts sheet")
                                }
                            } else if isPlanned {
                                activeSheet = .plannedTrainingInfo(date: normalizedDate)
                                print("🔍 Showing planned training info")
                            } else if !isToday && !isDateInPast(date) {
                                activeSheet = .trainingPlanning(date: normalizedDate)
                                print("🔍 Showing training planning")
                            } else {
                                print("🔍 No action taken - no workouts, not planned, and not future date")
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            print("📅 TrainingCalendarView appeared")
            requestHealthKitAccess()
            loadPlannedTraining()
            
            // If we don't have data yet, try to fetch it
            if trainingData.isEmpty && !isLoadingWorkouts {
                print("🔄 No training data found, fetching workouts...")
                fetchWorkouts()
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case let .workoutDetails(date, workout):
                WorkoutDetailsSheet(workout: workout, date: date)
            case let .trainingPlanning(date):
                TrainingPlanningSheet(
                    date: date,
                    trainingType: $plannedTrainingType,
                    trainingGoal: $plannedTrainingGoal,
                    onSave: {
                        if !plannedTrainingType.isEmpty && !plannedTrainingGoal.isEmpty {
                            plannedTraining[date] = "\(plannedTrainingType): \(plannedTrainingGoal)"
                            savePlannedTraining()
                            plannedTrainingType = ""
                            plannedTrainingGoal = ""
                        }
                    }
                )
            case let .plannedTrainingInfo(date):
                PlannedTrainingInfoSheet(
                    date: date,
                    trainingInfo: plannedTraining[date] ?? "",
                    onDelete: {
                        plannedTraining.removeValue(forKey: date)
                        savePlannedTraining()
                    }
                )
            case let .multipleWorkouts(date):
                MultipleWorkoutsSheet(
                    date: date,
                    workouts: trainingData[date] ?? [],
                    onWorkoutSelected: { workout in
                        // Present workout details after selecting one
                        activeSheet = .workoutDetails(date: date, workout: workout)
                    }
                )
            }
        }
    }
    func requestHealthKitAccess() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device.")
            return
        }

        print("🔐 Requesting HealthKit authorization...")
        let workoutType = HKObjectType.workoutType()
        healthStore.requestAuthorization(toShare: nil, read: [workoutType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit authorization granted")
                    self.fetchWorkouts()
                } else {
                    print("❌ HealthKit authorization denied: \(String(describing: error))")
                    self.isLoadingWorkouts = false
                }
            }
        }
    }
    private func loadPlannedTraining() {
        if let savedData = UserDefaults.standard.dictionary(forKey: plannedTrainingKey) as? [String: String] {
            var loadedTraining: [Date: String] = [:]
            let formatter = ISO8601DateFormatter()
            for (key, value) in savedData {
                if let date = formatter.date(from: key) {
                    loadedTraining[date] = value
                }
            }
            plannedTraining = loadedTraining
        }
    }
    private func savePlannedTraining() {
        var dataToSave: [String: String] = [:]
        let formatter = ISO8601DateFormatter()
        for (date, description) in plannedTraining {
            dataToSave[formatter.string(from: date)] = description
        }
        UserDefaults.standard.set(dataToSave, forKey: plannedTrainingKey)
    }
        
    func fetchWorkouts() {
        print("🔄 Starting to fetch workouts...")
        let workoutType = HKObjectType.workoutType()
        let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) // За последний год
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, samples, error in
            guard let samples = samples as? [HKWorkout], error == nil else {
                print("❌ Error fetching workouts: \(String(describing: error))")
                return
            }

            print("✅ Fetched \(samples.count) workouts from HealthKit")
            var newData: [Date: [HKWorkout]] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateFormatter.timeZone = TimeZone.current
            
            for workout in samples {
                // Use the same date normalization as the calendar
                let workoutDate = self.normalizeDate(workout.startDate)
                newData[workoutDate, default: []].append(workout)
                
                // Debug first few workouts to see date processing
                if newData[workoutDate]?.count == 1 {
                    print("📅 Workout date processing:")
                    print("   Original: \(dateFormatter.string(from: workout.startDate))")
                    print("   Normalized: \(dateFormatter.string(from: workoutDate))")
                }
            }

            print("📊 Organized workouts into \(newData.count) unique dates")
            DispatchQueue.main.async {
                self.trainingData = newData
                self.isLoadingWorkouts = false
                print("✅ Training data updated on main thread")
            }
        }

        healthStore.execute(query)
    }
    func generateCalendarDays(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0-based index

        var days: [Date] = []
        for _ in 0..<firstWeekday {
            days.append(Date.distantPast)
        }

        var currentDate = firstDayOfMonth
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        while days.count % 7 != 0 {
            days.append(Date.distantFuture)
        }

        return days
    }

    func isDateInPast(_ date: Date) -> Bool {
        return calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }
    
    // Helper function to normalize dates consistently
    private func normalizeDate(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
}

struct WorkoutDetailsSheet: View {
    let workout: HKWorkout?
    let date: Date
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"

    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with date
                    VStack(spacing: 8) {
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Workout Summary")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    if let workout = workout {
                        // Workout type card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: workoutIcon(for: workout.workoutActivityType))
                                    .font(.title)
                                    .foregroundColor(chartColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.workoutActivityType.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text("Completed Workout")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(16)
                        }

                        // Stats grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            WorkoutStatCard(
                                title: "Duration",
                                value: formattedDuration(workout.duration),
                                icon: "clock.fill",
                                color: .blue
                            )
                            
                            WorkoutStatCard(
                                title: "Distance",
                                value: distanceString(for: workout.totalDistance),
                                icon: "location.fill",
                                color: .green
                            )
                            
                            WorkoutStatCard(
                                title: "Calories",
                                value: caloriesString(for: workout),
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            WorkoutStatCard(
                                title: "Start Time",
                                value: workout.startDate.formatted(date: .omitted, time: .shortened),
                                icon: "calendar",
                                color: .purple
                            )
                        }
                        
                        // Additional details
                        if let metadata = workout.metadata, !metadata.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional Details")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(Array(metadata.keys.prefix(5)), id: \.self) { key in
                                    let valueText = formatMetadataValue(metadata[key], forKey: key)
                                    if let valueText = valueText {
                                        HStack {
                                            Text(displayName(for: key))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(valueText)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    } else {
                        // No workout data
                        VStack(spacing: 16) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No Workout Data")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("No workout was recorded for this day.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "N/A"
    }

    private func distanceString(for distance: HKQuantity?) -> String {
        guard let distance = distance else { return "N/A" }
        let distanceValue = distance.doubleValue(for: .meter())
        return String(format: "%.2f km", distanceValue / 1000)
    }

    private func caloriesString(for workout: HKWorkout) -> String {
        if #available(iOS 18.0, *) {
            if let statistics = workout.statistics(for: HKQuantityType(.activeEnergyBurned)),
               let totalEnergyBurned = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                return String(format: "%.1f kcal", totalEnergyBurned)
            }
        } else {
            if let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                return String(format: "%.1f kcal", totalEnergyBurned)
            }
        }
        return "N/A"
    }
    
    // MARK: - Additional details formatting
    private func displayName(for key: String) -> String {
        let lower = key.lowercased()
        if lower.contains("indoor") { return "Location" }
        if lower.contains("hkaveragespeed") || lower.contains("averagespeed") { return "Average Speed" }
        if lower.contains("hkmaxspeed") || lower.contains("maxspeed") { return "Max Speed" }
        if lower.contains("hkaverageheartrate") || lower.contains("averageheartrate") { return "Avg Heart Rate" }
        if lower.contains("hkmaxheartrate") || lower.contains("maxheartrate") { return "Max Heart Rate" }

        let stripped = key.hasPrefix("HK") ? String(key.dropFirst(2)) : key
        let spaced = stripped.replacingOccurrences(of: "(?<!^)([A-Z])", with: " $1", options: .regularExpression)
        return spaced.trimmingCharacters(in: .whitespaces)
    }

    private func formatMetadataValue(_ raw: Any?, forKey key: String) -> String? {
        guard let raw = raw else { return nil }
        let lower = key.lowercased()

        if lower.contains("indoor") {
            let isIndoor: Bool
            if let b = raw as? Bool { isIndoor = b }
            else if let n = raw as? NSNumber { isIndoor = n.intValue != 0 }
            else if let s = raw as? String { isIndoor = (Int(s) ?? 0) != 0 }
            else { isIndoor = false }
            return isIndoor ? "Indoor" : "Outdoor"
        }

        if lower.contains("heartrate") {
            if let n = number(from: raw) { return String(format: "%.0f bpm", n) }
        }

        if lower.contains("averagespeed") || lower.contains("maxspeed") {
            if let n = number(from: raw) { return String(format: "%.1f km/h", n * 3.6) }
        }

        if let n = number(from: raw) {
            if floor(n) == n { return String(format: "%.0f", n) }
            return String(format: "%.2f", n)
        }
        if let s = raw as? String { return s }
        return String(describing: raw)
    }

    private func number(from value: Any) -> Double? {
        if let d = value as? Double { return d }
        if let f = value as? Float { return Double(f) }
        if let i = value as? Int { return Double(i) }
        if let n = value as? NSNumber { return n.doubleValue }
        if let s = value as? String { return Double(s) }
        return nil
    }
    
    private func workoutIcon(for activityType: HKWorkoutActivityType) -> String {
        // Map HKWorkoutActivityType to SportType and use its icon
        switch activityType {
        case .running:
            return SportType.running.icon
        case .cycling:
            return SportType.cycling.icon
        case .walking:
            return SportType.walking.icon
        case .swimming:
            return SportType.swimming.icon
        case .hiking:
            return SportType.hiking.icon
        default:
            return SportType.other.icon
        }
    }
}

// MARK: - Multiple Workouts Sheet

struct MultipleWorkoutsSheet: View {
    let date: Date
    let workouts: [HKWorkout]
    let onWorkoutSelected: (HKWorkout) -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"

    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(workouts.count) Workout\(workouts.count == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Workouts list
                    LazyVStack(spacing: 12) {
                        ForEach(Array(workouts.enumerated()), id: \.offset) { index, workout in
                            CalendarWorkoutCard(
                                workout: workout,
                                index: index + 1,
                                onTap: {
                                    onWorkoutSelected(workout)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct CalendarWorkoutCard: View {
    let workout: HKWorkout
    let index: Int
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    
    var chartColor: Color {
        Color(hex: chartColorHex)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Workout number and icon
                VStack(spacing: 4) {
                    Text("#\(index)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(chartColor)
                    
                    Image(systemName: workoutIcon(for: workout.workoutActivityType))
                        .font(.title2)
                        .foregroundColor(chartColor)
                }
                .frame(width: 40)
                
                // Workout details
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutActivityType.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        WorkoutSummaryItem(
                            icon: "clock",
                            value: formattedDuration(workout.duration)
                        )
                        
                        if let distance = workout.totalDistance {
                            WorkoutSummaryItem(
                                icon: "location",
                                value: String(format: "%.1f km", distance.doubleValue(for: .meter()) / 1000)
                            )
                        }
                        
                        WorkoutSummaryItem(
                            icon: "flame",
                            value: caloriesString(for: workout)
                        )
                    }
                    
                    Text(workout.startDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func workoutIcon(for activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return SportType.running.icon
        case .cycling:
            return SportType.cycling.icon
        case .walking:
            return SportType.walking.icon
        case .swimming:
            return SportType.swimming.icon
        case .hiking:
            return SportType.hiking.icon
        default:
            return SportType.other.icon
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "N/A"
    }
    
    private func caloriesString(for workout: HKWorkout) -> String {
        if #available(iOS 18.0, *) {
            if let statistics = workout.statistics(for: HKQuantityType(.activeEnergyBurned)),
               let totalEnergyBurned = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                return String(format: "%.0f kcal", totalEnergyBurned)
            }
        } else {
            if let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                return String(format: "%.0f kcal", totalEnergyBurned)
            }
        }
        return "N/A"
    }
}

struct WorkoutSummaryItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Supporting Components

struct WorkoutStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct WorkoutDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct TrainingSportTypeCard: View {
    let sport: SportType
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    
    var chartColor: Color {
        Color(hex: chartColorHex)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: sportIcon(for: sport))
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : chartColor)
                
                Text(sport.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? chartColor : Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? chartColor : Color(.separator), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sportIcon(for sport: SportType) -> String {
        return sport.icon
    }
}

// MARK: - Supporting Enums

enum GoalType: CaseIterable {
    case distance
    case duration
    case calories
    case steps
    
    var displayName: String {
        switch self {
        case .distance:
            return "Distance"
        case .duration:
            return "Duration"
        case .calories:
            return "Calories"
        case .steps:
            return "Steps"
        }
    }
    
    var unit: String {
        switch self {
        case .distance:
            return "km"
        case .duration:
            return "min"
        case .calories:
            return "kcal"
        case .steps:
            return "steps"
        }
    }
    
    var placeholder: String {
        switch self {
        case .distance:
            return "Enter distance"
        case .duration:
            return "Enter duration"
        case .calories:
            return "Enter calories"
        case .steps:
            return "Enter steps"
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .distance, .duration, .calories, .steps:
            return .decimalPad
        }
    }
    
    var quickGoals: [String] {
        switch self {
        case .distance:
            return ["1", "3", "5", "10", "21", "42"]
        case .duration:
            return ["15", "30", "45", "60", "90", "120"]
        case .calories:
            return ["100", "200", "300", "400", "500", "600"]
        case .steps:
            return ["1000", "5000", "8000", "10000", "12000", "15000"]
        }
    }
}

struct TrainingPlanningSheet: View {
    let date: Date
    @Binding var trainingType: String
    @Binding var trainingGoal: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    @State private var selectedSportType: SportType = .running
    @State private var customGoal: String = ""
    @State private var selectedGoalType: GoalType = .distance

    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Plan Your Training")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Sport type selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Sport Type")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SportType.allCases, id: \.self) { sport in
                                TrainingSportTypeCard(
                                    sport: sport,
                                    isSelected: selectedSportType == sport,
                                    onTap: { selectedSportType = sport }
                                )
                            }
                        }
                    }

                    // Goal type selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goal Type")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("Goal Type", selection: $selectedGoalType) {
                            ForEach(GoalType.allCases, id: \.self) { goalType in
                                Text(goalType.displayName).tag(goalType)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }

                    // Custom goal input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Goal")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            TextField(selectedGoalType.placeholder, text: $customGoal)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(selectedGoalType.keyboardType)
                            
                            Text(selectedGoalType.unit)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // Quick goal suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Goals")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(selectedGoalType.quickGoals, id: \.self) { goal in
                                Button(action: {
                                    customGoal = goal
                                }) {
                                    Text(goal)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        trainingType = selectedSportType.rawValue
                        trainingGoal = "\(customGoal) \(selectedGoalType.unit)"
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(customGoal.isEmpty)
                }
            }
        }
    }
}

struct PlannedTrainingInfoSheet: View {
    let date: Date
    let trainingInfo: String
    let onDelete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    @State private var showingDeleteAlert = false

    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Planned Training")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Training info card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title)
                                .foregroundColor(chartColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scheduled Workout")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Ready to go!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(16)
                    }

                    // Training details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Training Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            WorkoutDetailRow(
                                icon: "figure.run",
                                title: "Activity",
                                value: parseTrainingType(from: trainingInfo),
                                color: .blue
                            )
                            
                            WorkoutDetailRow(
                                icon: "target",
                                title: "Goal",
                                value: parseTrainingGoal(from: trainingInfo),
                                color: .green
                            )
                            
                            WorkoutDetailRow(
                                icon: "calendar",
                                title: "Date",
                                value: date.formatted(date: .abbreviated, time: .omitted),
                                color: .purple
                            )
                        }
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Could add edit functionality here
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Training Plan")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(chartColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Training Plan")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Training Plan", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this training plan? This action cannot be undone.")
            }
        }
    }
    
    private func parseTrainingType(from info: String) -> String {
        let components = info.components(separatedBy: ": ")
        return components.first ?? "Unknown"
    }
    
    private func parseTrainingGoal(from info: String) -> String {
        let components = info.components(separatedBy: ": ")
        return components.count > 1 ? components[1] : "No goal set"
    }
}


struct CalendarDayView: View {
    let date: Date
    let trainingCount: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let isPlanned: Bool
    let calendar = Calendar.current
    @Environment(\.colorScheme) var colorScheme
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
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: 36, height: 36)
            
            // Border for today
            if isToday {
                Circle()
                    .stroke(chartColor, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
            
            // Training indicator dots
            if trainingCount > 0 {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<min(trainingCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(chartColor)
                                .frame(width: 4, height: 4)
                        }
                    }
                    if trainingCount > 3 {
                        Text("+\(trainingCount - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(chartColor)
                    }
                }
            }

            // Date text
            if date == Date.distantPast || date == Date.distantFuture {
                Text("")
            } else {
                Text("\(calendar.component(.day, from: date))")
                    .foregroundColor(textColor)
                    .font(.system(size: 14, weight: isToday ? .semibold : .regular))
            }
            
            // Planned training indicator (top right corner)
            if isPlanned {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 8))
                            .foregroundColor(chartColor)
                            .padding(.trailing, 2)
                    }
                    Spacer()
                }
                .frame(width: 40, height: 40)
            }
        }
        .frame(width: 40, height: 40)
        .scaleEffect(isToday ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isToday)
    }
    
    private var backgroundColor: Color {
        if isToday {
            return chartColor.opacity(0.1)
        } else if trainingCount > 0 {
            return chartColor.opacity(0.15) // More visible for past workouts
        } else if isPlanned {
            return chartColor.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isToday {
            return chartColor
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
}

// --- SleepZonesBarWidget ---
struct SleepZonesBarWidget: View {
    let sleepSamples: [HKCategorySample]
    let sleepManager: SleepDataManager
    @State private var selectedPhaseIndex: Int? = nil
    @State private var refreshButtonPressed = false
    @State private var infoButtonPressed = false
    @State private var permissionButtonPressed = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.colorScheme) var colorScheme

    private var phaseDurations: [(phase: SleepPhase, minutes: Double)] {
        var durations: [SleepPhase: Double] = [:]
        for phase in SleepPhase.allCases where phase != .inBed {
            let total = sleepSamples
                .filter { phase.matches(sample: $0) }
                .reduce(0.0) { acc, sample in
                    acc + sample.endDate.timeIntervalSince(sample.startDate)
                }
            durations[phase] = total / 60
        }
        return durations
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }
    private var totalMinutes: Double {
        phaseDurations.map { $0.minutes }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sleep last night")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // Refresh sleep data
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    sleepManager.refreshSleepData()
                    showAlert(message: "Sleep data refreshed!")
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .scaleEffect(refreshButtonPressed ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: refreshButtonPressed)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        refreshButtonPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        refreshButtonPressed = false
                    }
                }
                .help("Refresh sleep data")
                
                Button(action: {
                    // Check sleep data availability
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    sleepManager.checkSleepDataAvailability()
                    showAlert(message: "Checking sleep data availability... ")
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .scaleEffect(infoButtonPressed ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: infoButtonPressed)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        infoButtonPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        infoButtonPressed = false
                    }
                }
                .help("Check sleep data availability")
                
                Button(action: {
                    // Request sleep permissions
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    sleepManager.requestAuthorization()
                    showAlert(message: "Requesting sleep permissions... ")
                }) {
                    Image(systemName: "lock.open")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .scaleEffect(permissionButtonPressed ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: permissionButtonPressed)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        permissionButtonPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        permissionButtonPressed = false
                    }
                }
                .help("Request sleep permissions")
            }
            
            if sleepSamples.isEmpty {
                VStack(spacing: 8) {
                    Text("No sleep data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Make sure you have sleep tracking enabled and permissions granted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                Text("Total: \(formattedTime(from: totalMinutes))")
                    .font(.title2).bold()
                    .padding(.bottom, 8)
            GeometryReader { geo in
                let barMaxWidth = geo.size.width - 170 // 90 (label) + 60 (time) + 20 (margins)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(phaseDurations.enumerated()), id: \.1.phase) { idx, item in
                        let percent = totalMinutes == 0 ? 0 : item.minutes / totalMinutes
                        HStack {
                            Text(item.phase.title)
                                .frame(width: 90, alignment: .leading)
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(item.phase.color.opacity(0.2))
                                    .frame(height: 18)
                                Capsule()
                                    .fill(item.phase.color)
                                    .frame(width: CGFloat(percent) * barMaxWidth, height: 18)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedPhaseIndex = selectedPhaseIndex == idx ? nil : idx
                                }
                            }
                            Text(formattedTime(from: item.minutes))
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
                .overlay(
                    Group {
                        if let idx = selectedPhaseIndex, idx < phaseDurations.count {
                            let item = phaseDurations[idx]
                            let percent = totalMinutes == 0 ? 0 : item.minutes / totalMinutes
                            TooltipView(
                                title: item.phase.title,
                                duration: formattedTime(from: item.minutes),
                                percent: Int(percent * 100),
                                color: item.phase.color
                            )
                            .position(
                                x: 90 + CGFloat(percent) * barMaxWidth / 2,
                                y: CGFloat(idx) * 30 - 20 // 30 — высота строки, -20 — смещение вверх
                            )
                        }
                    }
                )
                .frame(height: CGFloat(phaseDurations.count) * 30)
            }
            .frame(height: CGFloat(phaseDurations.count) * 30)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.07), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
        .alert("Sleep Data", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func formattedTime(from minutes: Double) -> String {
        let total = Int(minutes)
        let hours = total / 60
        let mins = total % 60
        return hours > 0 ? "\(hours) h \(mins) min" : "\(mins) min"
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

struct TooltipView: View {
    let title: String
    let duration: String
    let percent: Int
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(color)
            Text(duration)
                .font(.caption2)
                .foregroundColor(.primary)
            Text("\(percent)%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.5 : 0.3), radius: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
    }
}


// --- Новый Steps Analysis Widget ---
struct StepsAnalysisWidget: View {
    @StateObject private var stepsViewModel = StepsAnalysisViewModel()
    @State private var selectedDayInfo: StepsDataPoint?
    @State private var showingDayInfo = false
    @State private var showingStepsView = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    
    var chartColor: Color {
        Color(hex: chartColorHex)
    }
    
    var accentColor: Color {
        Color(hex: accentColorHex)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Steps Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingStepsView = true
                }) {
                    Text("View Details")
                        .font(.caption)
                        .foregroundColor(chartColor)
                }
            }
            
            // Stats Row
            HStack(spacing: 12) {
                // Today's Steps with Progress Circle
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stepsViewModel.todaySteps)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(chartColor)
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // Progress Circle
                        ZStack {
                            Circle()
                                .stroke(chartColor.opacity(0.2), lineWidth: 3)
                                .frame(width: 30, height: 30)
                            Circle()
                                .trim(from: 0, to: min(Double(stepsViewModel.todaySteps) / 10000.0, 1.0))
                                .stroke(chartColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 30, height: 30)
                                .animation(.easeOut(duration: 0.5), value: stepsViewModel.todaySteps)
                        }
                    }
                }
                Spacer()
                // Weekly Average
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(weeklyAverage)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                    Text("Weekly Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Best Day
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(bestDaySteps)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Best Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Mini Chart (отдельно, после статистики)
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.subheadline)
                    .fontWeight(.medium)
                GeometryReader { geo in
                    let count = max(stepsViewModel.weeklyData.count, 1)
                    let barWidth = max(geo.size.width / CGFloat(count), 8)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(stepsViewModel.weeklyData) { dataPoint in
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(chartColor.opacity(0.8))
                                    .frame(
                                        width: barWidth * 0.7,
                                        height: max(4, min(CGFloat(dataPoint.steps) / 10000 * 40, 35))
                                    )
                                    .onTapGesture {
                                        showDayInfo(dataPoint)
                                    }
                                Text(dayLabel(for: dataPoint.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 48)
                }
                .frame(height: 60)
            }
            .padding(.bottom, 4)
            
            // Active Challenges
            if !stepsViewModel.userChallenges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Challenges")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(stepsViewModel.userChallenges.prefix(3)) { challenge in
                                ChallengeMiniCard(challenge: challenge)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.08), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
        .onAppear {
            stepsViewModel.loadStepsData()
        }
        .animation(.easeInOut(duration: 0.3), value: stepsViewModel.todaySteps)
        .animation(.easeInOut(duration: 0.3), value: stepsViewModel.weeklyData.count)
        .alert("Steps for \(selectedDayInfo?.date.formatted(date: .abbreviated, time: .omitted) ?? "")", isPresented: $showingDayInfo) {
            Button("OK") { }
        } message: {
            Text("\(selectedDayInfo?.steps ?? 0) steps\nGoal: \(selectedDayInfo?.goal ?? 0) steps")
        }
        .sheet(isPresented: $showingStepsView) {
            StepsAnalysisView(isOpenedAsSheet: true)
        }
    }
    
    private var weeklyAverage: Int {
        let total = stepsViewModel.weeklyData.reduce(0) { $0 + $1.steps }
        return stepsViewModel.weeklyData.isEmpty ? 0 : total / stepsViewModel.weeklyData.count
    }
    
    private var bestDaySteps: Int {
        stepsViewModel.weeklyData.map { $0.steps }.max() ?? 0
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private func showDayInfo(_ dataPoint: StepsDataPoint) {
        selectedDayInfo = dataPoint
        showingDayInfo = true
    }
}

struct ChallengeMiniCard: View {
    let challenge: StepsChallenge
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(challenge.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(challenge.targetSteps) steps")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: 0, total: Double(challenge.targetSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
        .padding(8)
        .frame(width: 80)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}




