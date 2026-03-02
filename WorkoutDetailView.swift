//
//  WorkoutDetailView.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 19.06.2025.
//

import SwiftUI
import CoreLocation
import MapKit
import AAInfographics
import HealthKit



// MARK: - Workout Segmentation Models

struct WorkoutSegment {
    let segmentNumber: Int
    let startDistance: Double
    let endDistance: Double
    let distance: Double
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let averageSpeed: Double // м/с
    let averageSpeedKmH: Double // км/ч
    let pace: Double? // мин/км для бега
}

enum SegmentationType: String, CaseIterable {
    case distance = "Distance"
    case time = "Time"
    
    var displayName: String {
        switch self {
        case .distance: return "By Distance"
        case .time: return "By Time"
        }
    }
}

struct SegmentationSettings {
    var type: SegmentationType = .distance
    var value: Double = 1000 // метры для дистанции, секунды для времени
    var workoutType: String = "Running"
    
    var defaultValue: Double {
        switch type {
        case .distance:
            return workoutType.lowercased() == "cycling" ? 5000 : 1000 // 5км для велосипеда, 1км для бега
        case .time:
            return 300 // 5 минут по умолчанию
        }
    }
    
    var unit: String {
        switch type {
        case .distance: return "m"
        case .time: return "s"
        }
    }
    
    var displayValue: String {
        switch type {
        case .distance:
            let km = value / 1000
            return km >= 1 ? String(format: "%.1f km", km) : "\(Int(value)) m"
        case .time:
            let minutes = value / 60
            return minutes >= 1 ? String(format: "%.0f min", minutes) : "\(Int(value)) s"
        }
    }
}

// MARK: - Heart Rate Zones Models

struct HeartRateZone: Identifiable, Codable {
    let id: UUID
    var name: String
    var minBPM: Int
    var maxBPM: Int
    var color: String
    var description: String
    var percentage: Double = 0.0
    var duration: TimeInterval = 0.0
    
    init(name: String, minBPM: Int, maxBPM: Int, color: String, description: String, percentage: Double = 0.0, duration: TimeInterval = 0.0) {
        self.id = UUID()
        self.name = name
        self.minBPM = minBPM
        self.maxBPM = maxBPM
        self.color = color
        self.description = description
        self.percentage = percentage
        self.duration = duration
    }
    
    var range: String {
        return "\(minBPM)-\(maxBPM) bpm"
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedPercentage: String {
        return String(format: "%.1f%%", percentage)
    }
}

struct HeartRateZoneSettings: Codable {
    var maxHeartRate: Int = 220
    var zones: [HeartRateZone] = []
    
    mutating func calculateDefaultZones() {
        zones = [
            HeartRateZone(name: "Zone 1", minBPM: Int(Double(maxHeartRate) * 0.5), maxBPM: Int(Double(maxHeartRate) * 0.6), color: "#4ECDC4", description: "Recovery"),
            HeartRateZone(name: "Zone 2", minBPM: Int(Double(maxHeartRate) * 0.6), maxBPM: Int(Double(maxHeartRate) * 0.7), color: "#A8E6CF", description: "Aerobic Base"),
            HeartRateZone(name: "Zone 3", minBPM: Int(Double(maxHeartRate) * 0.7), maxBPM: Int(Double(maxHeartRate) * 0.8), color: "#FFD93D", description: "Aerobic"),
            HeartRateZone(name: "Zone 4", minBPM: Int(Double(maxHeartRate) * 0.8), maxBPM: Int(Double(maxHeartRate) * 0.9), color: "#FF6B6B", description: "Threshold"),
            HeartRateZone(name: "Zone 5", minBPM: Int(Double(maxHeartRate) * 0.9), maxBPM: maxHeartRate, color: "#6C5CE7", description: "VO2 Max")
        ]
    }
    
    mutating func updateZone(_ zone: HeartRateZone, at index: Int) {
        guard index < zones.count else { return }
        zones[index] = zone
    }
    
    mutating func updateZoneBoundaries(at index: Int, minBPM: Int, maxBPM: Int) {
        guard index < zones.count else { return }
        zones[index].minBPM = minBPM
        zones[index].maxBPM = maxBPM
    }
}

// MARK: - Sport Type and Metrics

enum WorkoutMetric: String, CaseIterable {
    case type = "Type"
    case start = "Start"
    case duration = "Duration"
    case distance = "Distance"
    case averageHeartRate = "Average heart rate"
    case maxHeartRate = "Max heart rate"
    case averageSpeed = "Average speed"
    case maxSpeed = "Max speed"
    case runningCadence = "Running cadence"
    case cyclingCadence = "Cycling cadence"
    case cyclingPower = "Cycling power"
    case pace = "Pace"
    case swimmingPace = "Swimming pace"
    case swimmingLaps = "Swimming laps"
    case elevationGain = "Elevation gain"
    
    var icon: String {
        switch self {
        case .type: return "figure.run"
        case .start: return "clock"
        case .duration: return "timer"
        case .distance: return "location"
        case .averageHeartRate: return "heart.fill"
        case .maxHeartRate: return "heart.circle.fill"
        case .averageSpeed: return "speedometer"
        case .maxSpeed: return "gauge.with.needle.fill"
        case .runningCadence: return "figure.walk"
        case .cyclingCadence: return "bicycle"
        case .cyclingPower: return "bolt.fill"
        case .pace: return "timer.circle"
        case .swimmingPace: return "timer.circle.fill"
        case .swimmingLaps: return "number.circle"
        case .elevationGain: return "mountain.2"
        }
    }
}

enum WorkoutSection: String, CaseIterable {
    case main = "Main"
    case metadata = "Metadata"
    case heartRate = "Heart rate over time"
    case heartRateZones = "Heart rate zones"
    case speed = "Speed over time"
    case segments = "Workout segments"
    case route = "Route"
    case events = "Events"
    case swimmingLaps = "Swimming laps"
}


// MARK: - Pause Information Models

struct WorkoutPause: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let startDistance: Double
    let endDistance: Double
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }
    
    var distanceRange: String {
        let startKm = startDistance / 1000
        let endKm = endDistance / 1000
        return String(format: "%.2f - %.2f km", startKm, endKm)
    }
}

// MARK: - Professional Workout Detail View

struct WorkoutDetailView: View {
    let workout: WorkoutEntity
    
    // MARK: - State Management
    @StateObject private var viewModel = WorkoutDetailViewModel()
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var selectedTab: DetailTab = .overview
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Professional background
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Header with workout summary
                    workoutHeader
                    
                    // Tab selector
                    tabSelector
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        OverviewTab(viewModel: viewModel, workout: workout)
                            .tag(DetailTab.overview)
                        
                        ChartsTab(viewModel: viewModel, workout: workout)
                            .tag(DetailTab.charts)
                        
                        RouteTab(viewModel: viewModel, workout: workout)
                            .tag(DetailTab.route)
                        
                        AnalysisTab(viewModel: viewModel, workout: workout)
                            .tag(DetailTab.analysis)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadWorkoutData(workout)
            }
            .sheet(isPresented: $showingEditSheet) {
                WorkoutEditView(workout: workout)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareWorkoutView(workout: workout)
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark ? 
                [Color.black, Color.gray.opacity(0.3)] :
                [Color.white, Color.gray.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var workoutHeader: some View {
        VStack(spacing: 16) {
            // Navigation bar
                                                HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Workout Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                                                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
            
            // Workout summary card
            WorkoutSummaryCard(workout: workout, viewModel: viewModel)
        }
        .padding(.top)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.title)
                                                    .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .background(
            Rectangle()
                .fill(Color.primary.opacity(0.05))
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Detail Tabs

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case charts = "Charts"
    case route = "Route"
    case analysis = "Analysis"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .charts: return "chart.line.uptrend.xyaxis"
        case .route: return "map.fill"
        case .analysis: return "brain.head.profile"
        }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var viewModel: WorkoutDetailViewModel
    let workout: WorkoutEntity
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Write permission message for app-tracked workouts
                if isAppTrackedWorkout && !hasWritePermissions {
                    WritePermissionBanner()
                }
                
                // Main metrics section
                MainMetricsSection(viewModel: viewModel, workout: workout)
                
                // Key metrics grid
                KeyMetricsGrid(workout: workout)
                
                // Heart rate zones
                if viewModel.heartRateZones.count > 0 {
                    HeartRateZonesCard(zones: viewModel.heartRateZones, workout: workout, viewModel: viewModel)
                }
                
                // Workout segments
                if viewModel.segments.count > 0 {
                    SegmentsCard(segments: viewModel.segments, workoutType: workout.workoutType ?? "Running", workout: workout, viewModel: viewModel)
                }
                
                // Weather data
                if let metadata = workout.metadata {
                    WeatherDataCard(metadata: metadata)
                            }
                        }
                        .padding()
                }
            }
    
    
    // MARK: - Helper Properties
    
    /// Checks if this workout was tracked through the app
    private var isAppTrackedWorkout: Bool {
        // Workouts tracked through the app have deviceName "P.R.O. App"
        return workout.deviceName == "P.R.O. App"
    }
    
    /// Checks if we have write permissions for HealthKit
    private var hasWritePermissions: Bool {
        let workoutType = HKObjectType.workoutType()
        let healthStore = HKHealthStore()
        return healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized
    }
}

// MARK: - Write Permission Banner

struct WritePermissionBanner: View {
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save to Apple Health")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("To save this workout to Apple Health, please grant write permissions in Settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                PermissionMessageHelper.showWritePermissionAlert()
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MainMetricsSection: View {
    @ObservedObject var viewModel: WorkoutDetailViewModel
    let workout: WorkoutEntity
    
    var body: some View {
        ChartCard(title: "Main Metrics", subtitle: "Workout details") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(WorkoutMetric.allCases, id: \.self) { metric in
                    if shouldShowMetric(metric, workout: workout) {
                        MetricRow(
                            title: metric.rawValue,
                            value: getMetricValue(metric, workout: workout, viewModel: viewModel),
                            icon: getMetricIcon(metric, workout: workout)
                        )
                    }
                }
            }
        }
    }
    
    private func shouldShowMetric(_ metric: WorkoutMetric, workout: WorkoutEntity) -> Bool {
        let sportType = getSportType(workout)
        return sportType.relevantMetrics.contains(metric)
    }
    
    private func getMetricValue(_ metric: WorkoutMetric, workout: WorkoutEntity, viewModel: WorkoutDetailViewModel) -> String {
        if viewModel.isMetricsCalculated {
            return viewModel.cachedMetrics[metric] ?? "—"
        } else {
            return calculateMetricValue(metric, workout: workout)
        }
    }
    
    private func calculateMetricValue(_ metric: WorkoutMetric, workout: WorkoutEntity) -> String {
        switch metric {
        case .type:
            return workout.workoutType ?? "—"
        case .start:
            return formattedDate(workout.startDate)
        case .duration:
            return formattedDuration(workout.duration)
        case .distance:
            return formattedDistance(workout.totalDistance)
        case .averageHeartRate:
            return String(format: "%.1f bpm", workout.averageHeartRate)
        case .maxHeartRate:
            return String(format: "%.1f bpm", workout.maxHeartRate)
        case .averageSpeed:
            return formattedSpeed(workout.averageSpeed)
        case .maxSpeed:
            return formattedSpeed(workout.maxSpeed)
        case .runningCadence:
            return String(format: "%.1f spm", workout.cadenceRun)
        case .cyclingCadence:
            return String(format: "%.1f rpm", workout.cadenceCycle)
        case .cyclingPower:
            return String(format: "%.1f W", workout.cyclingPower)
        case .pace:
            return calculatePace(workout)
        case .swimmingPace:
            return calculateSwimmingPace(workout)
        case .swimmingLaps:
            return calculateSwimmingLaps(workout)
        case .elevationGain:
            return String(format: "%.0f m", workout.totalElevationGain)
        }
    }
    
    private func getMetricIcon(_ metric: WorkoutMetric, workout: WorkoutEntity) -> String {
        switch metric {
        case .type:
            return getSportType(workout).icon
        default:
            return metric.icon
        }
    }
    
    private func getSportType(_ workout: WorkoutEntity) -> SportType {
        let workoutType = workout.workoutType ?? "Running"
        return SportType(rawValue: workoutType) ?? .other
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d h %d min", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d min %d sec", minutes, seconds)
        } else {
            return String(format: "%d sec", seconds)
        }
    }
    
    private func formattedDistance(_ distance: Double) -> String {
        let kilometers = distance / 1000
        return String(format: "%.2f km", kilometers)
    }
    
    private func formattedSpeed(_ speed: Double) -> String {
        let kmPerHour = speed * 3.6
        return String(format: "%.2f km/h", kmPerHour)
    }
    
    private func calculatePace(_ workout: WorkoutEntity) -> String {
        guard workout.duration > 0 && workout.totalDistance > 0 else { return "—" }
        
        let paceMinutesPerKm = (workout.duration / 60) / (workout.totalDistance / 1000)
        let minutes = Int(paceMinutesPerKm)
        let seconds = Int((paceMinutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private func calculateSwimmingPace(_ workout: WorkoutEntity) -> String {
        guard workout.duration > 0 && workout.totalDistance > 0 else { return "—" }
        
        let paceSecondsPer100m = (workout.duration) / (workout.totalDistance / 100)
        let minutes = Int(paceSecondsPer100m) / 60
        let seconds = Int(paceSecondsPer100m) % 60
        
        return String(format: "%d:%02d /100m", minutes, seconds)
    }
    
    private func calculateSwimmingLaps(_ workout: WorkoutEntity) -> String {
        let events = workout.workoutEvents?.allObjects as? [WorkoutEventEntity] ?? []
        
        let lapEvents = events.filter { event in
            let eventType = event.type?.lowercased() ?? ""
            return eventType.contains("lap") || eventType.contains("segment") || eventType.contains("length")
        }
        
        if !lapEvents.isEmpty {
            return String(format: "%d laps", lapEvents.count)
        }
        
        let totalDistance = workout.totalDistance
        let lapDistance25m = totalDistance / 25
        let lapDistance50m = totalDistance / 50
        
        if lapDistance25m >= 1 && lapDistance25m <= 100 {
            return String(format: "%.0f laps (25m)", lapDistance25m)
        } else if lapDistance50m >= 1 && lapDistance50m <= 50 {
            return String(format: "%.0f laps (50m)", lapDistance50m)
        } else {
            return "—"
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Charts Tab

struct ChartsTab: View {
    @ObservedObject var viewModel: WorkoutDetailViewModel
    let workout: WorkoutEntity
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Heart rate chart
                if !viewModel.heartRateData.isEmpty {
                    ChartCard(
                        title: "Heart Rate",
                        subtitle: "Average: \(Int(viewModel.averageHeartRate)) bpm"
                    ) {
                        HeartRateChart(data: viewModel.heartRateData)
                            .frame(height: 200)
                    }
                }
                
                // Speed chart
                if !viewModel.speedData.isEmpty {
                    ChartCard(
                        title: "Speed",
                        subtitle: "km/h"
                    ) {
                        SpeedChart(data: viewModel.speedData)
                            .frame(height: 200)
                    }
                }
                
                // Elevation chart
                if !viewModel.elevationData.isEmpty {
                    ChartCard(
                        title: "Elevation",
                        subtitle: "meters"
                    ) {
                        ElevationChart(data: viewModel.elevationData)
                            .frame(height: 200)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Route Tab

struct RouteTab: View {
    @ObservedObject var viewModel: WorkoutDetailViewModel
    let workout: WorkoutEntity
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Route map
                if !viewModel.routeCoordinates.isEmpty {
                    ChartCard(title: "Route", subtitle: "GPS track") {
                        RouteMapView(coordinates: viewModel.routeCoordinates)
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                }
                
                // Elevation profile
                if !viewModel.elevationData.isEmpty {
                    ChartCard(title: "Elevation Profile", subtitle: "meters") {
                        ElevationChart(data: viewModel.elevationData)
                            .frame(height: 200)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Analysis Tab

struct AnalysisTab: View {
    @ObservedObject var viewModel: WorkoutDetailViewModel
    let workout: WorkoutEntity
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Performance analysis
                PerformanceAnalysisCard(workout: workout)
                
                // Pauses analysis
                if !viewModel.pauses.isEmpty {
                    PausesAnalysisCard(pauses: viewModel.pauses)
                }
                
                // Swimming laps
                if workout.workoutType?.lowercased() == "swimming" {
                    SwimmingLapsCard(workout: workout)
                }
            }
            .padding()
        }
    }
}

// MARK: - View Model

@MainActor
class WorkoutDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var heartRateData: [(Date, Double)] = []
    @Published var speedData: [(Date, Double)] = []
    @Published var elevationData: [(Double, Double)] = []
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var heartRateZones: [HeartRateZone] = []
    @Published var segments: [WorkoutSegment] = []
    @Published var pauses: [WorkoutPause] = []
    @Published var averageHeartRate: Double = 0
    @Published var isLoading = false
    @Published var cachedMetrics: [WorkoutMetric: String] = [:]
    @Published var isMetricsCalculated = false
    
    // MARK: - Settings
    @Published var segmentationSettings = SegmentationSettings()
    @Published var heartRateZoneSettings = HeartRateZoneSettings()
    
    init() {
        // Initialize heart rate zone settings with default zones
        heartRateZoneSettings.calculateDefaultZones()
    }
    
    func loadWorkoutData(_ workout: WorkoutEntity) {
        isLoading = true
        
        Task {
            await loadAllData(workout)
            isLoading = false
        }
    }
    
    private func loadAllData(_ workout: WorkoutEntity) async {
        await withTaskGroup(of: Void.self) { group in
            // Load heart rate data
            group.addTask {
                await self.loadHeartRateData(workout)
            }
            
            // Load speed data
            group.addTask {
                await self.loadSpeedData(workout)
            }
            
            // Load route data
            group.addTask {
                await self.loadRouteData(workout)
            }
            
            // Load heart rate zones
            group.addTask {
                await self.loadHeartRateZones(workout)
            }
            
            // Load segments
            group.addTask {
                await self.loadSegments(workout)
            }
            
            // Load pauses
            group.addTask {
                await self.loadPauses(workout)
            }
            
            // Calculate metrics
            group.addTask {
                await self.calculateMetrics(workout)
            }
        }
    }
    
    private func loadHeartRateData(_ workout: WorkoutEntity) async {
        let samples = workout.heartRateSamples?.allObjects as? [HeartRateEntity] ?? []
        let sortedSamples = samples.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
        
        let data = sortedSamples.compactMap { sample -> (Date, Double)? in
            guard let timestamp = sample.timestamp else { return nil }
            return (timestamp, sample.bpm)
        }
        
        await MainActor.run {
            self.heartRateData = data
            self.averageHeartRate = data.isEmpty ? 0 : data.map { $0.1 }.reduce(0, +) / Double(data.count)
        }
    }
    
    private func loadSpeedData(_ workout: WorkoutEntity) async {
        let samples = workout.speedSamples?.allObjects as? [SpeedSampleEntity] ?? []
        let sortedSamples = samples.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
        
        let data = sortedSamples.compactMap { sample -> (Date, Double)? in
            guard let timestamp = sample.timestamp else { return nil }
            return (timestamp, sample.speed * 3.6) // Convert to km/h
        }
        
        await MainActor.run {
            self.speedData = data
        }
    }
    
    private func loadRouteData(_ workout: WorkoutEntity) async {
        let points = workout.routePoints?.allObjects as? [RoutePointEntity] ?? []
        let sortedPoints = points.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
        
        let coordinates = sortedPoints.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
        
        var elevationData: [(Double, Double)] = []
        var totalDistance = 0.0
        var previousCoordinate: CLLocationCoordinate2D?
        
        for point in sortedPoints {
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            
            if let prevCoordinate = previousCoordinate {
                let distance = calculateDistance(from: prevCoordinate, to: coordinate)
                totalDistance += distance
            }
            
            elevationData.append((totalDistance, point.altitude))
            previousCoordinate = coordinate
        }
        
        await MainActor.run {
            self.routeCoordinates = coordinates
            self.elevationData = elevationData
        }
    }
    
    private func loadHeartRateZones(_ workout: WorkoutEntity) async {
        let samples = workout.heartRateSamples?.allObjects as? [HeartRateEntity] ?? []
        
        // Initialize heart rate zone settings if needed
        if heartRateZoneSettings.zones.isEmpty {
            heartRateZoneSettings.maxHeartRate = Int(workout.maxHeartRate > 0 ? workout.maxHeartRate : 220)
            heartRateZoneSettings.calculateDefaultZones()
        }
        
        let zones = calculateHeartRateZones(samples: samples)
        
        await MainActor.run {
            self.heartRateZones = zones
        }
    }
    
    private func loadSegments(_ workout: WorkoutEntity) async {
        let segments = calculateSegments(workout: workout)
        
        await MainActor.run {
            self.segments = segments
        }
    }
    
    func recalculateSegments(workout: WorkoutEntity) async {
        await loadSegments(workout)
    }
    
    func recalculateHeartRateZones(workout: WorkoutEntity) async {
        await loadHeartRateZones(workout)
    }
    
    private func loadPauses(_ workout: WorkoutEntity) async {
        let events = workout.workoutEvents?.allObjects as? [WorkoutEventEntity] ?? []
        let pauses = calculatePauses(from: events, workout: workout)
        
        await MainActor.run {
            self.pauses = pauses
        }
    }
    
    private func calculateMetrics(_ workout: WorkoutEntity) async {
        var metrics: [WorkoutMetric: String] = [:]
        
        for metric in WorkoutMetric.allCases {
            if shouldShowMetric(metric, workout: workout) {
                metrics[metric] = getMetricValue(metric, workout: workout)
            }
        }
            
            await MainActor.run {
            self.cachedMetrics = metrics
            self.isMetricsCalculated = true
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    private func calculateHeartRateZones(samples: [HeartRateEntity]) -> [HeartRateZone] {
        guard !samples.isEmpty else { return [] }
        
        let sortedSamples = samples.sorted { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast }
        let totalDuration = sortedSamples.last?.timestamp?.timeIntervalSince(sortedSamples.first?.timestamp ?? Date()) ?? 0
        
        var zones = heartRateZoneSettings.zones
        if zones.isEmpty {
            heartRateZoneSettings.calculateDefaultZones()
            zones = heartRateZoneSettings.zones
        }
        
        var zoneMap: [Int: Int] = [:]
        for (index, zone) in zones.enumerated() {
            for bpm in zone.minBPM...zone.maxBPM {
                zoneMap[bpm] = index
            }
        }
        
        var zoneDurations: [TimeInterval] = Array(repeating: 0, count: zones.count)
        var previousTimestamp: Date?
        
        for sample in sortedSamples {
            guard let timestamp = sample.timestamp else { continue }
            
            let bpm = Int(sample.bpm)
            if let zoneIndex = zoneMap[bpm] {
                if let prevTimestamp = previousTimestamp {
                    zoneDurations[zoneIndex] += timestamp.timeIntervalSince(prevTimestamp)
                }
            }
            previousTimestamp = timestamp
        }
        
        for i in 0..<zones.count {
            zones[i].duration = zoneDurations[i]
            zones[i].percentage = totalDuration > 0 ? (zoneDurations[i] / totalDuration) * 100 : 0
        }
        
        return zones
    }
    
    private func calculateSegments(workout: WorkoutEntity) -> [WorkoutSegment] {
        let samples = workout.speedSamples?.allObjects as? [SpeedSampleEntity] ?? []
        let routePoints = workout.routePoints?.allObjects as? [RoutePointEntity] ?? []
        let workoutType = workout.workoutType ?? "Running"
        
        var localSettings = segmentationSettings
        localSettings.workoutType = workoutType
        
        if localSettings.value == 1000 {
            localSettings.value = localSettings.defaultValue
        }
        
        let distanceTimeData = prepareDistanceTimeData(speedSamples: samples, routePoints: routePoints)
        guard !distanceTimeData.isEmpty else { return [] }
        
        var segments: [WorkoutSegment] = []
        var currentSegmentNumber = 1
        var currentSegmentStartIndex = 0
        var currentSegmentValue = 0.0
        
        for (index, dataPoint) in distanceTimeData.enumerated() {
            let segmentValue: Double
            switch localSettings.type {
            case .distance:
                segmentValue = dataPoint.distance
            case .time:
                segmentValue = dataPoint.time
            }
            
            if segmentValue >= currentSegmentValue + localSettings.value {
                let segment = createSegment(
                    from: currentSegmentStartIndex,
                    to: index,
                    data: distanceTimeData,
                    segmentNumber: currentSegmentNumber,
                    settings: localSettings
                )
                segments.append(segment)
                
                currentSegmentNumber += 1
                currentSegmentStartIndex = index
                currentSegmentValue = segmentValue
            }
        }
        
        if currentSegmentStartIndex < distanceTimeData.count - 1 {
            let segment = createSegment(
                from: currentSegmentStartIndex,
                to: distanceTimeData.count - 1,
                data: distanceTimeData,
                segmentNumber: currentSegmentNumber,
                settings: localSettings
            )
            segments.append(segment)
        }
        
        return segments
    }
    
    private func prepareDistanceTimeData(
        speedSamples: [SpeedSampleEntity],
        routePoints: [RoutePointEntity]
    ) -> [(distance: Double, time: Double, timestamp: Date, speed: Double)] {
        var result: [(distance: Double, time: Double, timestamp: Date, speed: Double)] = []
        
        let sortedSpeedSamples = speedSamples.sorted { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast }
        let sortedRoutePoints = routePoints.sorted { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast }
        
        if !sortedRoutePoints.isEmpty {
            var totalDistance = 0.0
            var totalTime = 0.0
            var previousPoint: RoutePointEntity?
            
            for point in sortedRoutePoints {
                guard let timestamp = point.timestamp else { continue }
                
                if let prevPoint = previousPoint, let prevTimestamp = prevPoint.timestamp {
                    let distance = calculateDistance(
                        from: CLLocationCoordinate2D(latitude: prevPoint.latitude, longitude: prevPoint.longitude),
                        to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                    )
                    totalDistance += distance
                    
                    let timeInterval = timestamp.timeIntervalSince(prevTimestamp)
                    totalTime += timeInterval
                }
                
                let speed = findSpeedForTimestamp(timestamp, in: sortedSpeedSamples)
                
                result.append((
                    distance: totalDistance,
                    time: totalTime,
                    timestamp: timestamp,
                    speed: speed
                ))
                
                previousPoint = point
            }
        } else if !sortedSpeedSamples.isEmpty {
            var totalDistance = 0.0
            var totalTime = 0.0
            var previousSample: SpeedSampleEntity?
            
            for sample in sortedSpeedSamples {
                guard let timestamp = sample.timestamp else { continue }
                
                if let prevSample = previousSample, let prevTimestamp = prevSample.timestamp {
                    let timeInterval = timestamp.timeIntervalSince(prevTimestamp)
                    totalTime += timeInterval
                    
                    let avgSpeed = (sample.speed + prevSample.speed) / 2
                    let distance = avgSpeed * timeInterval
                    totalDistance += distance
                }
                
                result.append((
                    distance: totalDistance,
                    time: totalTime,
                    timestamp: timestamp,
                    speed: sample.speed
                ))
                
                previousSample = sample
            }
        }
        
        return result.filter { $0.distance > 0 || $0.time > 0 }
    }
    
    private func findSpeedForTimestamp(_ timestamp: Date, in samples: [SpeedSampleEntity]) -> Double {
        guard !samples.isEmpty else { return 0 }
        
        let sortedSamples = samples.sorted { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast }
        
        var left = 0
        var right = sortedSamples.count - 1
        var closestIndex = 0
        
        while left <= right {
            let mid = (left + right) / 2
            guard let midTimestamp = sortedSamples[mid].timestamp else {
                left = mid + 1
                continue
            }
            
            if midTimestamp == timestamp {
                closestIndex = mid
                break
            } else if midTimestamp < timestamp {
                left = mid + 1
                closestIndex = mid
            } else {
                right = mid - 1
            }
        }
        
        if closestIndex + 1 < sortedSamples.count {
            guard let currentTimestamp = sortedSamples[closestIndex].timestamp,
                  let nextTimestamp = sortedSamples[closestIndex + 1].timestamp else {
                return sortedSamples[closestIndex].speed
            }
            
            let currentDiff = abs(currentTimestamp.timeIntervalSince(timestamp))
            let nextDiff = abs(nextTimestamp.timeIntervalSince(timestamp))
            
            if nextDiff < currentDiff {
                closestIndex += 1
            }
        }
        
        return sortedSamples[closestIndex].speed
    }
    
    private func createSegment(
        from startIndex: Int,
        to endIndex: Int,
        data: [(distance: Double, time: Double, timestamp: Date, speed: Double)],
        segmentNumber: Int,
        settings: SegmentationSettings
    ) -> WorkoutSegment {
        guard startIndex < data.count && endIndex < data.count else {
            return WorkoutSegment(
                segmentNumber: segmentNumber,
                startDistance: 0,
                endDistance: 0,
                distance: 0,
                startTime: Date(),
                endTime: Date(),
                duration: 0,
                averageSpeed: 0,
                averageSpeedKmH: 0,
                pace: nil
            )
        }
        
        let startData = data[startIndex]
        let endData = data[endIndex]
        
        let startDistance = startData.distance
        let endDistance = endData.distance
        let distance = endDistance - startDistance
        
        let startTime = startData.timestamp
        let endTime = endData.timestamp
        let duration = endTime.timeIntervalSince(startTime)
        
        let segmentData = Array(data[startIndex...endIndex])
        let speeds = segmentData.map { $0.speed }.filter { $0 > 0 }
        let averageSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        let averageSpeedKmH = averageSpeed * 3.6
        
        let pace: Double?
        if settings.workoutType.lowercased() == "running" && averageSpeed > 0 && distance > 0 {
            pace = (duration / 60) / (distance / 1000)
        } else {
            pace = nil
        }
        
        return WorkoutSegment(
            segmentNumber: segmentNumber,
            startDistance: startDistance,
            endDistance: endDistance,
            distance: distance,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            averageSpeed: averageSpeed,
            averageSpeedKmH: averageSpeedKmH,
            pace: pace
        )
    }

    private func calculatePauses(from events: [WorkoutEventEntity], workout: WorkoutEntity) -> [WorkoutPause] {
        var pauses: [WorkoutPause] = []
        
        let pauseEvents = events.filter { event in
            let eventType = event.type?.lowercased() ?? ""
            return eventType.contains("pause") || eventType.contains("resume")
        }.sorted { $0.date ?? .distantPast < $1.date ?? .distantPast }
        
        let routePoints = workout.routePoints?.allObjects as? [RoutePointEntity] ?? []
        let sortedRoutePoints = routePoints.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
        
        var pauseStartTime: Date?
        var pauseStartDistance: Double = 0
        
        for event in pauseEvents {
            guard let eventDate = event.date else { continue }
            let eventType = event.type?.lowercased() ?? ""
            
            if eventType.contains("pause") {
                pauseStartTime = eventDate
                pauseStartDistance = getDistanceAtTime(eventDate, routePoints: sortedRoutePoints, workout: workout)
            } else if eventType.contains("resume") && pauseStartTime != nil {
                let pauseEndTime = eventDate
                let pauseEndDistance = getDistanceAtTime(eventDate, routePoints: sortedRoutePoints, workout: workout)
                
                let pause = WorkoutPause(
                    startTime: pauseStartTime!,
                    endTime: pauseEndTime,
                    duration: pauseEndTime.timeIntervalSince(pauseStartTime!),
                    startDistance: pauseStartDistance,
                    endDistance: pauseEndDistance
                )
                
                pauses.append(pause)
                
                pauseStartTime = nil
                pauseStartDistance = 0
            }
        }
        
        if let startTime = pauseStartTime {
            let endTime = workout.startDate?.addingTimeInterval(workout.duration) ?? Date()
            let endDistance = workout.totalDistance
            
            let pause = WorkoutPause(
                startTime: startTime,
                endTime: endTime,
                duration: endTime.timeIntervalSince(startTime),
                startDistance: pauseStartDistance,
                endDistance: endDistance
            )
            
            pauses.append(pause)
        }
        
        return pauses
    }
    
    private func getDistanceAtTime(_ time: Date, routePoints: [RoutePointEntity], workout: WorkoutEntity) -> Double {
        if !routePoints.isEmpty {
            var totalDistance = 0.0
            var previousPoint: RoutePointEntity?
            
            for point in routePoints {
                guard let pointTime = point.timestamp else { continue }
                
                if pointTime <= time {
                    if let prevPoint = previousPoint {
                        let distance = calculateDistance(
                            from: CLLocationCoordinate2D(latitude: prevPoint.latitude, longitude: prevPoint.longitude),
                            to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                        )
                        totalDistance += distance
                    }
                    previousPoint = point
                } else {
                    break
                }
            }
            
            return totalDistance
        } else {
            let workoutStartTime = workout.startDate ?? Date()
            let elapsedTime = time.timeIntervalSince(workoutStartTime)
            let totalTime = workout.duration
            
            if totalTime > 0 {
                return (elapsedTime / totalTime) * workout.totalDistance
            } else {
                return 0
            }
        }
    }
    
    // MARK: - Metric Functions
    
    private func shouldShowMetric(_ metric: WorkoutMetric, workout: WorkoutEntity) -> Bool {
        let sportType = getSportType(workout)
        return sportType.relevantMetrics.contains(metric)
    }
    
    private func getMetricValue(_ metric: WorkoutMetric, workout: WorkoutEntity) -> String {
        switch metric {
        case .type:
            return workout.workoutType ?? "—"
        case .start:
            return formattedDate(workout.startDate)
        case .duration:
            return formattedDuration(workout.duration)
        case .distance:
            return formattedDistance(workout.totalDistance)
        case .averageHeartRate:
            return String(format: "%.1f bpm", workout.averageHeartRate)
        case .maxHeartRate:
            return String(format: "%.1f bpm", workout.maxHeartRate)
        case .averageSpeed:
            return formattedSpeed(workout.averageSpeed)
        case .maxSpeed:
            return formattedSpeed(workout.maxSpeed)
        case .runningCadence:
            return String(format: "%.1f spm", workout.cadenceRun)
        case .cyclingCadence:
            return String(format: "%.1f rpm", workout.cadenceCycle)
        case .cyclingPower:
            return String(format: "%.1f W", workout.cyclingPower)
        case .pace:
            return calculatePace(workout)
        case .swimmingPace:
            return calculateSwimmingPace(workout)
        case .swimmingLaps:
            return calculateSwimmingLaps(workout)
        case .elevationGain:
            return String(format: "%.0f m", workout.totalElevationGain)
        }
    }
    
    private func getSportType(_ workout: WorkoutEntity) -> SportType {
        let workoutType = workout.workoutType ?? "Running"
        return SportType(rawValue: workoutType) ?? .other
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d h %d min", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d min %d sec", minutes, seconds)
        } else {
            return String(format: "%d sec", seconds)
        }
    }
    
    private func formattedDistance(_ distance: Double) -> String {
        let kilometers = distance / 1000
        return String(format: "%.2f km", kilometers)
    }
    
    private func formattedSpeed(_ speed: Double) -> String {
        let kmPerHour = speed * 3.6
        return String(format: "%.2f km/h", kmPerHour)
    }
    
    private func calculatePace(_ workout: WorkoutEntity) -> String {
        guard workout.duration > 0 && workout.totalDistance > 0 else { return "—" }
        
        let paceMinutesPerKm = (workout.duration / 60) / (workout.totalDistance / 1000)
        let minutes = Int(paceMinutesPerKm)
        let seconds = Int((paceMinutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private func calculateSwimmingPace(_ workout: WorkoutEntity) -> String {
        guard workout.duration > 0 && workout.totalDistance > 0 else { return "—" }
        
        let paceSecondsPer100m = (workout.duration) / (workout.totalDistance / 100)
        let minutes = Int(paceSecondsPer100m) / 60
        let seconds = Int(paceSecondsPer100m) % 60
        
        return String(format: "%d:%02d /100m", minutes, seconds)
    }
    
    private func calculateSwimmingLaps(_ workout: WorkoutEntity) -> String {
        let events = workout.workoutEvents?.allObjects as? [WorkoutEventEntity] ?? []
        
        let lapEvents = events.filter { event in
            let eventType = event.type?.lowercased() ?? ""
            return eventType.contains("lap") || eventType.contains("segment") || eventType.contains("length")
        }
        
        if !lapEvents.isEmpty {
            return String(format: "%d laps", lapEvents.count)
        }
        
        let totalDistance = workout.totalDistance
        let lapDistance25m = totalDistance / 25
        let lapDistance50m = totalDistance / 50
        
        if lapDistance25m >= 1 && lapDistance25m <= 100 {
            return String(format: "%.0f laps (25m)", lapDistance25m)
        } else if lapDistance50m >= 1 && lapDistance50m <= 50 {
            return String(format: "%.0f laps (50m)", lapDistance50m)
        } else {
            return "—"
        }
    }
}

// MARK: - UI Components

struct WorkoutSummaryCard: View {
    let workout: WorkoutEntity
    @ObservedObject var viewModel: WorkoutDetailViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Workout type and date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutType ?? "Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(formattedDate(workout.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Workout icon
                Image(systemName: workoutIcon)
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
            
            // Key metrics
            HStack(spacing: 20) {
                MetricItem(
                    title: "Duration",
                    value: formattedDuration(workout.duration),
                    icon: "clock.fill"
                )
                
                MetricItem(
                    title: "Distance",
                    value: formattedDistance(workout.totalDistance),
                    icon: "location.fill"
                )
                
                MetricItem(
                    title: "Avg HR",
                    value: "\(Int(workout.averageHeartRate)) bpm",
                    icon: "heart.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private var workoutIcon: String {
        let type = workout.workoutType?.lowercased() ?? ""
        switch type {
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "walking": return "figure.walk"
        default: return "figure.run"
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formattedDistance(_ distance: Double) -> String {
        let km = distance / 1000
        return String(format: "%.2f km", km)
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct KeyMetricsGrid: View {
    let workout: WorkoutEntity
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            MetricCard(
                title: "Average Speed",
                value: formattedSpeed(workout.averageSpeed),
                icon: "speedometer",
                color: .blue
            )
            
            MetricCard(
                title: "Max Speed",
                value: formattedSpeed(workout.maxSpeed),
                icon: "gauge.with.needle.fill",
                color: .red
            )
            
            MetricCard(
                title: "Max HR",
                value: "\(Int(workout.maxHeartRate)) bpm",
                icon: "heart.circle.fill",
                color: .pink
            )
            
            MetricCard(
                title: "Elevation",
                value: "\(Int(workout.totalElevationGain)) m",
                icon: "mountain.2.fill",
                color: .green
            )
        }
    }
    
    private func formattedSpeed(_ speed: Double) -> String {
        let kmh = speed * 3.6
        return String(format: "%.1f km/h", kmh)
    }
}

struct MetricCard: View {
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
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Chart Views

struct HeartRateChart: View {
    let data: [(Date, Double)]
    
    var body: some View {
        if data.isEmpty {
            Text("No heart rate data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            AAChartViewWrapperForDetails(chartModel: heartRateChartModel())
        }
    }
    
    private func heartRateChartModel() -> AAChartModel {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let categories = data.map { timeFormatter.string(from: $0.0) }
        let chartData = data.map { $0.1 }
        let averageBPM = data.isEmpty ? 0 : data.map { $0.1 }.reduce(0, +) / Double(data.count)
        
        return AAChartModel()
            .chartType(.spline)
            .title("Heart rate over time")
            .subtitle("Average: \(String(format: "%.0f", averageBPM)) bpm")
            .categories(categories)
            .colorsTheme(["#FF6B6B"])
            .markerRadius(0)
            .series([
                AASeriesElement()
                    .name("Heart rate")
                    .data(chartData)
                    .lineWidth(3)
                    .color("#FF6B6B")
                    .fillColor(AAGradientColor.linearGradient(
                        direction: .toTop,
                        startColor: "#FF6B6B",
                        endColor: "#FF6B6B00"
                    ))
                    .fillOpacity(0.3)
            ])
    }
}

struct SpeedChart: View {
    let data: [(Date, Double)]
    
    var body: some View {
        if data.isEmpty {
            Text("No speed data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            AAChartViewWrapperForDetails(chartModel: speedChartModel())
        }
    }
    
    private func speedChartModel() -> AAChartModel {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let categories = data.map { timeFormatter.string(from: $0.0) }
        let chartData = data.map { $0.1 }
        
        return AAChartModel()
            .chartType(.area)
            .title("Speed over time")
            .subtitle("km/h")
            .categories(categories)
            .colorsTheme(["#4ECDC4"])
            .markerRadius(0)
            .series([
                AASeriesElement()
                    .name("Speed")
                    .data(chartData)
                    .lineWidth(3)
                    .color("#4ECDC4")
                    .fillColor(AAGradientColor.linearGradient(
                        direction: .toTop,
                        startColor: "#4ECDC4",
                        endColor: "#4ECDC400"
                    ))
                    .fillOpacity(0.4)
            ])
    }
}

struct ElevationChart: View {
    let data: [(Double, Double)]
    
    var body: some View {
        if data.isEmpty {
            Text("No elevation data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            AAChartViewWrapperForDetails(chartModel: elevationChartModel())
        }
    }
    
    private func elevationChartModel() -> AAChartModel {
        let categories = data.enumerated().map { "\(Int($0.element.0))m" }
        let chartData = data.map { $0.1 }
        
        return AAChartModel()
            .chartType(.area)
            .title("Elevation gain")
            .subtitle("m")
            .categories(categories)
            .colorsTheme(["#A8E6CF"])
            .markerRadius(0)
            .series([
                AASeriesElement()
                    .name("Elevation")
                    .data(chartData)
                    .lineWidth(3)
                    .color("#A8E6CF")
                    .fillColor(AAGradientColor.linearGradient(
                        direction: .toTop,
                        startColor: "#A8E6CF",
                        endColor: "#A8E6CF00"
                    ))
                    .fillOpacity(0.5)
            ])
    }
}

struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        if coordinates.isEmpty {
            Text("No route data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            MapViewWithPolyline(routeCoordinates: coordinates)
        }
    }
}

// MARK: - Map View Implementation

struct MapViewWithPolyline: UIViewRepresentable {
    let routeCoordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Create polyline
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        mapView.addOverlay(polyline)
        
        // Auto-focus on route
        if !routeCoordinates.isEmpty {
            let region = calculateBoundingRegion(for: routeCoordinates)
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update polyline when coordinates change
        uiView.removeOverlays(uiView.overlays)
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        uiView.addOverlay(polyline)
        
        if !routeCoordinates.isEmpty {
            let region = calculateBoundingRegion(for: routeCoordinates)
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func calculateBoundingRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = (maxLat - minLat) * 1.2
        let lonDelta = (maxLon - minLon) * 1.2
        
        let minDelta = 0.001
        let finalLatDelta = max(latDelta, minDelta)
        let finalLonDelta = max(lonDelta, minDelta)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
        )
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithPolyline

        init(_ parent: MapViewWithPolyline) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - AAChartView Wrapper

struct AAChartViewWrapperForDetails: UIViewRepresentable {
    var chartModel: AAChartModel

    func makeUIView(context: Context) -> AAChartView {
        let chartView = AAChartView()
        chartView.isScrollEnabled = true
        chartView.contentHeight = 200
        chartView.isClearBackgroundColor = true
        
        let styledModel = applyLiquidGlassStyle(to: chartModel)
        chartView.aa_drawChartWithChartModel(styledModel)
        return chartView
    }

    func updateUIView(_ uiView: AAChartView, context: Context) {
        DispatchQueue.main.async {
            let styledModel = applyLiquidGlassStyle(to: chartModel)
            uiView.aa_refreshChartWholeContentWithChartModel(styledModel)
        }
    }
    
    private func applyLiquidGlassStyle(to model: AAChartModel) -> AAChartModel {
        return model
            .backgroundColor("#00000000")
            .dataLabelsEnabled(false)
            .legendEnabled(false)
    }
}

// MARK: - Analysis Components

struct HeartRateZonesCard: View {
    let zones: [HeartRateZone]
    let workout: WorkoutEntity
    @ObservedObject var viewModel: WorkoutDetailViewModel
    
    var body: some View {
        ChartCard(title: "Heart Rate Zones", subtitle: "Time distribution") {
            if zones.isEmpty {
                Text("No heart rate zones data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    // Customization Controls
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Max Heart Rate")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Max Heart Rate Slider
                        HStack {
                            Text("Max Heart Rate: \(viewModel.heartRateZoneSettings.maxHeartRate) bpm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(viewModel.heartRateZoneSettings.maxHeartRate) },
                                set: { newValue in
                                    viewModel.heartRateZoneSettings.maxHeartRate = Int(newValue)
                                }
                            ),
                            in: 150...220,
                            step: 1
                        )
                        .onChange(of: viewModel.heartRateZoneSettings.maxHeartRate) { _ in
                            viewModel.heartRateZoneSettings.calculateDefaultZones()
                            Task {
                                await viewModel.recalculateHeartRateZones(workout: workout)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.05))
                    )
                    
                    // Pie chart visualization
                    HeartRateZonesChart(zones: zones)
                        .frame(height: 150)
                    
                    // Zones table
                    HeartRateZonesTable(zones: zones)
                }
            }
        }
    }
}

struct HeartRateZonesChart: View {
    let zones: [HeartRateZone]
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 8)
                .frame(width: 120, height: 120)
            
            // Zone segments
            ForEach(Array(zones.enumerated()), id: \.element.id) { index, zone in
                if zone.percentage > 0 {
                    Circle()
                        .trim(from: getStartAngle(for: index), to: getEndAngle(for: index))
                        .stroke(Color(hex: zone.color), lineWidth: 8)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            // Center info
            VStack(spacing: 2) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("100%")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func getStartAngle(for index: Int) -> Double {
        let previousPercentages = zones.prefix(index).map { $0.percentage }
        let startPercentage = previousPercentages.reduce(0, +) / 100.0
        return startPercentage
    }
    
    private func getEndAngle(for index: Int) -> Double {
        let previousPercentages = zones.prefix(index + 1).map { $0.percentage }
        let endPercentage = previousPercentages.reduce(0, +) / 100.0
        return endPercentage
    }
}

struct HeartRateZonesTable: View {
    let zones: [HeartRateZone]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Headers
            HStack(spacing: 8) {
                Text("Zone")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                Text("Range")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text("Time")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .leading)
                
                Text("%")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            
            // Zone rows
            ForEach(zones) { zone in
                HeartRateZoneRow(zone: zone)
            }
        }
    }
}

struct HeartRateZoneRow: View {
    let zone: HeartRateZone
    
    var body: some View {
        HStack(spacing: 8) {
            // Color indicator and zone name
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: zone.color))
                    .frame(width: 12, height: 12)
                
                Text(zone.name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 60, alignment: .leading)
            
            Text(zone.range)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(zone.formattedDuration)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)
            
            Text(zone.formattedPercentage)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct SegmentsCard: View {
    let segments: [WorkoutSegment]
    let workoutType: String
    let workout: WorkoutEntity
    @ObservedObject var viewModel: WorkoutDetailViewModel
    
    var body: some View {
        ChartCard(title: "Workout Segments", subtitle: "Performance breakdown") {
            VStack(alignment: .leading, spacing: 16) {
                // Segmentation Controls
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Segmentation")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    // Type Picker
                    Picker("Segmentation Type", selection: $viewModel.segmentationSettings.type) {
                        ForEach(SegmentationType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.segmentationSettings.type) { _ in
                        viewModel.segmentationSettings.value = viewModel.segmentationSettings.defaultValue
                        Task {
                            await viewModel.recalculateSegments(workout: workout)
                        }
                    }
                    
                    // Value Slider
                    HStack {
                        Text("Interval: \(viewModel.segmentationSettings.displayValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Slider(
                        value: $viewModel.segmentationSettings.value,
                        in: viewModel.segmentationSettings.type == .distance ? 100...10000 : 30...1800,
                        step: viewModel.segmentationSettings.type == .distance ? 100 : 30
                    )
                    .onChange(of: viewModel.segmentationSettings.value) { _ in
                        Task {
                            await viewModel.recalculateSegments(workout: workout)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.05))
                )
                
                // Segments Table
                if segments.isEmpty {
                    Text("No segments data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SegmentsTableView(segments: segments, workoutType: workoutType)
                }
            }
        }
    }
}

struct SegmentsTableView: View {
    let segments: [WorkoutSegment]
    let workoutType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Table headers
            HStack(spacing: 8) {
                Text("#")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
                
                Text("Distance")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text("Time")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text("Speed")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .leading)
                
                if workoutType.lowercased() == "running" {
                    Text("Pace")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            
            // Segment rows
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(segments.enumerated()), id: \.element.segmentNumber) { index, segment in
                        SegmentRowView(segment: segment, workoutType: workoutType)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
}

struct SegmentRowView: View {
    let segment: WorkoutSegment
    let workoutType: String
    
    private var formattedDistance: String {
        let km = segment.distance / 1000
        return String(format: "%.2f", km)
    }
    
    private var formattedDuration: String {
        let minutes = Int(segment.duration) / 60
        let seconds = Int(segment.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var formattedSpeed: String {
        return String(format: "%.1f", segment.averageSpeedKmH)
    }
    
    private var formattedPace: String {
        guard let pace = segment.pace else { return "—" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(segment.segmentNumber)")
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .leading)
            
            Text(formattedDistance)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(formattedDuration)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(formattedSpeed)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)
            
            if workoutType.lowercased() == "running" {
                Text(formattedPace)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(width: 60, alignment: .leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct WeatherDataCard: View {
    let metadata: Data
    
    var body: some View {
        ChartCard(title: "Weather and METs", subtitle: "Conditions during workout") {
            let metadataDict = decodedMetadata(metadata)
            let filteredMetadata = filterAndFormatMetadata(metadataDict)
            
            if filteredMetadata.isEmpty {
                Text("No weather data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredMetadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(spacing: 12) {
                            Image(systemName: getMetadataIcon(key))
                                .font(.system(size: 16))
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(getMetadataDisplayName(key))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(value)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                                            
                                            Spacer()
                                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func decodedMetadata(_ data: Data) -> [String: Any] {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = object as? [String: Any] else {
            return [:]
        }
        return dict
    }
    
    private func filterAndFormatMetadata(_ metadataDict: [String: Any]) -> [String: String] {
        var filtered: [String: String] = [:]
        
        for (key, value) in metadataDict {
            let lowercasedKey = key.lowercased()
            
            if lowercasedKey.contains("met") || lowercasedKey.contains("average") {
                if let metValue = extractNumericValue(from: value) {
                    filtered[key] = String(format: "%.1f METs", metValue)
                }
            } else if lowercasedKey.contains("humidity") || lowercasedKey.contains("hkweatherhumidity") {
                if let humidityValue = extractNumericValue(from: value) {
                    let humidityPercent = humidityValue / 100.0
                    filtered[key] = String(format: "%.1f%%", humidityPercent)
                }
            } else if lowercasedKey.contains("temperature") || lowercasedKey.contains("hkweathertemperature") {
                if let tempValue = extractNumericValue(from: value) {
                    let celsiusTemp = (tempValue - 32) * 5/9
                    filtered[key] = String(format: "%.1f°C", celsiusTemp)
                }
            }
        }
        
        return filtered
    }
    
    private func extractNumericValue(from value: Any) -> Double? {
        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let intValue = value as? Int {
            return Double(intValue)
        }
        
        if let stringValue = value as? String {
            let cleanedString = stringValue
                .replacingOccurrences(of: "Optional (", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: " kcal/hr-kg", with: "")
                .replacingOccurrences(of: " %", with: "")
                .replacingOccurrences(of: " degF", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            return Double(cleanedString)
        }
        
        return nil
    }
    
    private func getMetadataIcon(_ key: String) -> String {
        let lowercasedKey = key.lowercased()
        
        if lowercasedKey.contains("met") || lowercasedKey.contains("average") {
            return "flame.fill"
        } else if lowercasedKey.contains("humidity") || lowercasedKey.contains("hkweatherhumidity") {
            return "humidity.fill"
        } else if lowercasedKey.contains("temperature") || lowercasedKey.contains("hkweathertemperature") {
            return "thermometer"
        } else {
            return "info.circle"
        }
    }
    
    private func getMetadataDisplayName(_ key: String) -> String {
        let lowercasedKey = key.lowercased()
        
        if lowercasedKey.contains("met") || lowercasedKey.contains("average") {
            return "Average METs"
        } else if lowercasedKey.contains("humidity") || lowercasedKey.contains("hkweatherhumidity") {
            return "Humidity"
        } else if lowercasedKey.contains("temperature") || lowercasedKey.contains("hkweathertemperature") {
            return "Temperature"
        } else {
            return key
        }
    }
}

struct PerformanceAnalysisCard: View {
    let workout: WorkoutEntity
    
    var body: some View {
        ChartCard(title: "Performance Analysis", subtitle: "Workout insights") {
        VStack(alignment: .leading, spacing: 16) {
                // Performance metrics
                HStack(spacing: 20) {
                    PerformanceMetric(
                        title: "Calories",
                        value: "\(Int(workout.totalEnergyBurned))",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    PerformanceMetric(
                        title: "Avg Pace",
                        value: calculateAveragePace(),
                        icon: "timer",
                        color: .blue
                    )
                    
                    PerformanceMetric(
                        title: "Efficiency",
                        value: calculateEfficiency(),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                }
                
                // Performance insights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Insights")
                .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(getPerformanceInsights(), id: \.self) { insight in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(insight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private func calculateAveragePace() -> String {
        guard workout.duration > 0 && workout.totalDistance > 0 else { return "—" }
        
        let paceMinutesPerKm = (workout.duration / 60) / (workout.totalDistance / 1000)
        let minutes = Int(paceMinutesPerKm)
        let seconds = Int((paceMinutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private func calculateEfficiency() -> String {
        guard workout.duration > 0 && workout.totalDistance > 0 else { return "—" }
        
        let efficiency = (workout.totalDistance / 1000) / (workout.duration / 3600) // km/h
        return String(format: "%.1f km/h", efficiency)
    }
    
    private func getPerformanceInsights() -> [String] {
        var insights: [String] = []
        
        if workout.averageHeartRate > 0 {
            insights.append("Good heart rate monitoring throughout")
        }
        
        if workout.totalDistance > 5000 {
            insights.append("Excellent distance covered")
        }
        
        if workout.duration > 1800 {
            insights.append("Sustained effort maintained")
        }
        
        if insights.isEmpty {
            insights.append("Keep up the great work!")
        }
        
        return insights
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                                                    .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                                                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PausesAnalysisCard: View {
    let pauses: [WorkoutPause]
    
    var body: some View {
        ChartCard(title: "Pauses", subtitle: "Rest periods") {
            if pauses.isEmpty {
                Text("No pauses detected during workout")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Pause statistics
                    HStack(spacing: 20) {
                        PauseStat(
                            title: "Total Pauses",
                            value: "\(pauses.count)",
                            icon: "pause.circle"
                        )
                        
                        PauseStat(
                            title: "Total Time",
                            value: formatTotalPauseTime(),
                            icon: "clock"
                        )
                        
                        PauseStat(
                            title: "Longest",
                            value: findLongestPause().formattedDuration,
                            icon: "timer"
                        )
                    }
                    
                    // Pause list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pause Details")
                                                    .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(Array(pauses.enumerated()), id: \.element.id) { index, pause in
                                    PauseRowView(pauseNumber: index + 1, pause: pause)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
        }
    }
    
    private func formatTotalPauseTime() -> String {
        let totalSeconds = pauses.reduce(0) { $0 + $1.duration }
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%d сек", seconds)
        }
    }
    
    private func findLongestPause() -> WorkoutPause {
        return pauses.max(by: { $0.duration < $1.duration }) ?? WorkoutPause(
            startTime: Date(),
            endTime: Date(),
            duration: 0,
            startDistance: 0,
            endDistance: 0
        )
    }
}

struct PauseStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
                    .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PauseRowView: View {
    let pauseNumber: Int
    let pause: WorkoutPause
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(pauseNumber)")
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .leading)
            
            Text(pause.formattedStartTime)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(pause.formattedEndTime)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(pause.formattedDuration)
                        .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(pause.distanceRange)
                        .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
                
                Spacer()
            }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
                .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct SwimmingLapsCard: View {
    let workout: WorkoutEntity
    
    var body: some View {
        ChartCard(title: "Swimming Laps", subtitle: "Lap breakdown") {
        let events = workout.workoutEvents?.allObjects as? [WorkoutEventEntity] ?? []
        let lapEvents = events.filter { event in
            let eventType = event.type?.lowercased() ?? ""
            return eventType.contains("lap") || eventType.contains("segment") || eventType.contains("length")
        }
        
            if lapEvents.isEmpty {
                Text("No lap data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
                SwimmingLapsView(lapEvents: lapEvents, totalDistance: workout.totalDistance, totalDuration: workout.duration)
            }
        }
    }
}

struct SwimmingLapsView: View {
    let lapEvents: [WorkoutEventEntity]
    let totalDistance: Double
    let totalDuration: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Lap statistics
            HStack(spacing: 20) {
                SwimmingLapStat(
                    title: "Total Laps",
                    value: "\(lapEvents.count)",
                    icon: "number.circle"
                )
                
                SwimmingLapStat(
                    title: "Avg Pace",
                    value: calculateAveragePace(),
                    icon: "timer"
                )
                
                SwimmingLapStat(
                    title: "Pool Length",
                    value: estimatePoolLength(),
                    icon: "ruler"
                )
            }
            
            // Lap details
            VStack(alignment: .leading, spacing: 8) {
                Text("Lap Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(lapEvents.enumerated()), id: \.element.objectID) { index, event in
                            SwimmingLapRow(
                                lapNumber: index + 1,
                                event: event,
                                poolLength: estimatePoolLengthValue()
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    private func calculateAveragePace() -> String {
        guard totalDuration > 0 && totalDistance > 0 else { return "—" }
        
        let paceSecondsPer100m = totalDuration / (totalDistance / 100)
        let minutes = Int(paceSecondsPer100m) / 60
        let seconds = Int(paceSecondsPer100m) % 60
        
        return String(format: "%d:%02d /100m", minutes, seconds)
    }
    
    private func estimatePoolLength() -> String {
        let poolLength = estimatePoolLengthValue()
        return "\(Int(poolLength))m"
    }
    
    private func estimatePoolLengthValue() -> Double {
        guard !lapEvents.isEmpty else { return 25 }
        
        let estimatedLength = totalDistance / Double(lapEvents.count)
        
        if abs(estimatedLength - 25) < 5 {
            return 25
        } else if abs(estimatedLength - 50) < 5 {
            return 50
        } else if abs(estimatedLength - 100) < 10 {
            return 100
        } else {
            return estimatedLength
        }
    }
}

struct SwimmingLapStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SwimmingLapRow: View {
    let lapNumber: Int
    let event: WorkoutEventEntity
    let poolLength: Double
    
    private var formattedTime: String {
        guard let date = event.date else { return "—" }
        
        let timeInterval = date.timeIntervalSince(event.date ?? Date())
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var formattedPace: String {
        let paceSecondsPer100m = 60 // Example value
        let minutes = Int(paceSecondsPer100m) / 60
        let seconds = Int(paceSecondsPer100m) % 60
        
        return String(format: "%d:%02d /100m", minutes, seconds)
    }
    
    private var strokeType: String {
        let eventType = event.type?.lowercased() ?? ""
        if eventType.contains("freestyle") || eventType.contains("free") {
            return "Freestyle"
        } else if eventType.contains("breaststroke") || eventType.contains("breast") {
            return "Breaststroke"
        } else if eventType.contains("backstroke") || eventType.contains("back") {
            return "Backstroke"
        } else if eventType.contains("butterfly") || eventType.contains("fly") {
            return "Butterfly"
        } else {
            return "Mixed"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(lapNumber)")
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .leading)
            
            Text(formattedTime)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(formattedPace)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(strokeType)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}



// MARK: - Workout Edit View

struct WorkoutEditView: View {
    let workout: WorkoutEntity
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Editable properties
    @State private var workoutType: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var totalDistance: Double
    @State private var duration: Double
    @State private var averageHeartRate: Double
    @State private var maxHeartRate: Double
    @State private var averageSpeed: Double
    @State private var maxSpeed: Double
    @State private var totalEnergyBurned: Double
    @State private var cadenceRun: Double
    @State private var cadenceCycle: Double
    @State private var cyclingPower: Double
    @State private var pace: Double
    @State private var deviceName: String
    
    // UI State
    @State private var showingDeleteAlert = false
    @State private var showingSaveAlert = false
    @State private var hasChanges = false
    
    init(workout: WorkoutEntity) {
        self.workout = workout
        self._workoutType = State(initialValue: workout.workoutType ?? "Running")
        self._startDate = State(initialValue: workout.startDate ?? Date())
        self._endDate = State(initialValue: workout.endDate ?? Date())
        self._totalDistance = State(initialValue: workout.totalDistance)
        self._duration = State(initialValue: workout.duration)
        self._averageHeartRate = State(initialValue: workout.averageHeartRate)
        self._maxHeartRate = State(initialValue: workout.maxHeartRate)
        self._averageSpeed = State(initialValue: workout.averageSpeed)
        self._maxSpeed = State(initialValue: workout.maxSpeed)
        self._totalEnergyBurned = State(initialValue: workout.totalEnergyBurned)
        self._cadenceRun = State(initialValue: workout.cadenceRun)
        self._cadenceCycle = State(initialValue: workout.cadenceCycle)
        self._cyclingPower = State(initialValue: workout.cyclingPower)
        self._pace = State(initialValue: workout.pace)
        self._deviceName = State(initialValue: workout.deviceName ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Information Section
                        EditSection(title: "Basic Information", icon: "info.circle") {
                            VStack(spacing: 16) {
                                // Workout Type
                                EditField(
                                    title: "Workout Type",
                                    value: $workoutType,
                                    placeholder: "Running",
                                    icon: "figure.run"
                                )
                                
                                // Start Date
                                DatePickerField(
                                    title: "Start Date",
                                    date: $startDate,
                                    icon: "calendar"
                                )
                                
                                // End Date
                                DatePickerField(
                                    title: "End Date",
                                    date: $endDate,
                                    icon: "calendar.badge.clock"
                                )
                                
                                // Device Name
                                EditField(
                                    title: "Device",
                                    value: $deviceName,
                                    placeholder: "Apple Watch",
                                    icon: "watch"
                                )
                            }
                        }
                        
                        // Distance & Duration Section
                        EditSection(title: "Distance & Duration", icon: "location") {
                            VStack(spacing: 16) {
                                // Total Distance
                                EditField(
                                    title: "Distance (km)",
                                    value: Binding(
                                        get: { String(format: "%.2f", totalDistance / 1000) },
                                        set: { 
                                            if let value = Double($0) {
                                                totalDistance = value * 1000
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0.00",
                                    icon: "ruler",
                                    keyboardType: .decimalPad
                                )
                                
                                // Duration
                                EditField(
                                    title: "Duration (minutes)",
                                    value: Binding(
                                        get: { String(format: "%.0f", duration / 60) },
                                        set: { 
                                            if let value = Double($0) {
                                                duration = value * 60
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0",
                                    icon: "timer",
                                    keyboardType: .numberPad
                                )
                            }
                        }
                        
                        // Heart Rate Section
                        EditSection(title: "Heart Rate", icon: "heart.fill") {
                            VStack(spacing: 16) {
                                // Average Heart Rate
                                EditField(
                                    title: "Average HR (bpm)",
                                    value: Binding(
                                        get: { String(format: "%.0f", averageHeartRate) },
                                        set: { 
                                            if let value = Double($0) {
                                                averageHeartRate = value
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0",
                                    icon: "heart",
                                    keyboardType: .numberPad
                                )
                                
                                // Max Heart Rate
                                EditField(
                                    title: "Max HR (bpm)",
                                    value: Binding(
                                        get: { String(format: "%.0f", maxHeartRate) },
                                        set: { 
                                            if let value = Double($0) {
                                                maxHeartRate = value
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0",
                                    icon: "heart.circle.fill",
                                    keyboardType: .numberPad
                                )
                            }
                        }
                        
                        // Speed Section
                        EditSection(title: "Speed & Pace", icon: "speedometer") {
                            VStack(spacing: 16) {
                                // Average Speed
                                EditField(
                                    title: "Average Speed (km/h)",
                                    value: Binding(
                                        get: { String(format: "%.1f", averageSpeed * 3.6) },
                                        set: { 
                                            if let value = Double($0) {
                                                averageSpeed = value / 3.6
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0.0",
                                    icon: "speedometer",
                                    keyboardType: .decimalPad
                                )
                                
                                // Max Speed
                                EditField(
                                    title: "Max Speed (km/h)",
                                    value: Binding(
                                        get: { String(format: "%.1f", maxSpeed * 3.6) },
                                        set: { 
                                            if let value = Double($0) {
                                                maxSpeed = value / 3.6
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0.0",
                                    icon: "gauge.with.needle.fill",
                                    keyboardType: .decimalPad
                                )
                                
                                // Pace (for running)
                                if workoutType.lowercased() == "running" {
                                    EditField(
                                        title: "Pace (min/km)",
                                        value: Binding(
                                            get: { String(format: "%.1f", pace) },
                                            set: { 
                                                if let value = Double($0) {
                                                    pace = value
                                                    hasChanges = true
                                                }
                                            }
                                        ),
                                        placeholder: "0.0",
                                        icon: "timer.circle",
                                        keyboardType: .decimalPad
                                    )
                                }
                            }
                        }
                        
                        // Additional Metrics Section
                        EditSection(title: "Additional Metrics", icon: "chart.bar.fill") {
                            VStack(spacing: 16) {
                                // Calories
                                EditField(
                                    title: "Calories",
                                    value: Binding(
                                        get: { String(format: "%.0f", totalEnergyBurned) },
                                        set: { 
                                            if let value = Double($0) {
                                                totalEnergyBurned = value
                                                hasChanges = true
                                            }
                                        }
                                    ),
                                    placeholder: "0",
                                    icon: "flame.fill",
                                    keyboardType: .numberPad
                                )
                                
                                // Running Cadence
                                if workoutType.lowercased() == "running" {
                                    EditField(
                                        title: "Cadence (spm)",
                                        value: Binding(
                                            get: { String(format: "%.0f", cadenceRun) },
                                            set: { 
                                                if let value = Double($0) {
                                                    cadenceRun = value
                                                    hasChanges = true
                                                }
                                            }
                                        ),
                                        placeholder: "0",
                                        icon: "figure.walk",
                                        keyboardType: .numberPad
                                    )
                                }
                                
                                // Cycling Cadence
                                if workoutType.lowercased() == "cycling" {
                                    EditField(
                                        title: "Cadence (rpm)",
                                        value: Binding(
                                            get: { String(format: "%.0f", cadenceCycle) },
                                            set: { 
                                                if let value = Double($0) {
                                                    cadenceCycle = value
                                                    hasChanges = true
                                                }
                                            }
                                        ),
                                        placeholder: "0",
                                        icon: "bicycle",
                                        keyboardType: .numberPad
                                    )
                                    
                                    // Cycling Power
                                    EditField(
                                        title: "Power (W)",
                                        value: Binding(
                                            get: { String(format: "%.0f", cyclingPower) },
                                            set: { 
                                                if let value = Double($0) {
                                                    cyclingPower = value
                                                    hasChanges = true
                                                }
                                            }
                                        ),
                                        placeholder: "0",
                                        icon: "bolt.fill",
                                        keyboardType: .numberPad
                                    )
                                }
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: saveWorkout) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(hasChanges ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!hasChanges)
                            
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Workout")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveWorkout() }
                        .fontWeight(.semibold)
                        .disabled(!hasChanges)
                }
            }
            .alert("Delete Workout", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { deleteWorkout() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
            .alert("Workout Saved", isPresented: $showingSaveAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your workout changes have been saved successfully.")
            }
        }
        .onChange(of: workoutType) { _ in hasChanges = true }
        .onChange(of: startDate) { _ in hasChanges = true }
        .onChange(of: endDate) { _ in hasChanges = true }
        .onChange(of: deviceName) { _ in hasChanges = true }
    }
    
    private func saveWorkout() {
        workout.workoutType = workoutType
        workout.startDate = startDate
        workout.endDate = endDate
        workout.totalDistance = totalDistance
        workout.duration = duration
        workout.averageHeartRate = averageHeartRate
        workout.maxHeartRate = maxHeartRate
        workout.averageSpeed = averageSpeed
        workout.maxSpeed = maxSpeed
        workout.totalEnergyBurned = totalEnergyBurned
        workout.cadenceRun = cadenceRun
        workout.cadenceCycle = cadenceCycle
        workout.cyclingPower = cyclingPower
        workout.pace = pace
        workout.deviceName = deviceName.isEmpty ? nil : deviceName
        
        do {
            try viewContext.save()
            showingSaveAlert = true
        } catch {
            print("Error saving workout: \(error)")
        }
    }
    
    private func deleteWorkout() {
        viewContext.delete(workout)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}

// MARK: - Edit Section Component

struct EditSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Edit Field Component

struct EditField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Date Picker Field Component

struct DatePickerField: View {
    let title: String
    @Binding var date: Date
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
    }
}



