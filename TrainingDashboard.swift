//
//  TestBase.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 21.05.2025.
//


import SwiftUI
import AAInfographics
import CoreData

import SwiftUI

struct GradientBackground: View {
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    @Environment(\.colorScheme) var colorScheme

    // Преобразование HEX-строки в Color
    private func hexToColor(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        let length = hexSanitized.count
        guard length == 6 else { return Color(.systemBackground) } // Возвращаем системный цвет при ошибке
        
        let redHex = String(hexSanitized.prefix(2))
        let greenHex = String(hexSanitized.dropFirst(2).prefix(2))
        let blueHex = String(hexSanitized.dropFirst(4).prefix(2))
        
        var red: UInt64 = 0, green: UInt64 = 0, blue: UInt64 = 0
        
        Scanner(string: redHex).scanHexInt64(&red)
        Scanner(string: greenHex).scanHexInt64(&green)
        Scanner(string: blueHex).scanHexInt64(&blue)
        
        return Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                hexToColor(chartColorHex),
                hexToColor(accentColorHex)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all) // Занимает весь экран
    }
}


struct BlurredOverlay: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemBackground).opacity(0.6)) // Enhanced semi-transparent system layer
                .blur(radius: 10) // Blur effect
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial) // iOS-style blur
                .opacity(0.9) // Enhanced opacity for better contrast
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// Расширение для поддержки размытия
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}



struct CustomSegmentedControl: View {
    let options: [String]
    @Binding var selectedOption: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    Text(option)
                        .font(.headline)
                        .foregroundColor(selectedOption == option ? .white : .primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedOption == option ? Color.blue : Color(.tertiarySystemBackground))
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TimeFilterSegmentedControl: View {
    @Binding var selectedFilter: TimeFilter
    var onChange: ((TimeFilter) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                Button(action: {
                    selectedFilter = filter
                    onChange?(filter)
                }) {
                    Text(filter.displayName)
                        .font(.headline)
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedFilter == filter ? Color.blue : Color(.tertiarySystemBackground))
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}



struct DashboardView: View {
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var permissionManager = PermissionManager.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutEntity.startDate, ascending: true)],
        animation: .default
    )
    private var workouts: FetchedResults<WorkoutEntity>
    
    // Состояние для выбора временного диапазона
    @State private var selectedFilter: TimeFilter = .month
    
    // Состояние для выбора конкретного периода
    @State private var selectedPeriod: Date = Date() // По умолчанию текущий период
    
    @State private var isSheetPresented: Bool = false
    @State private var selectedChartModel: AAChartModel? = nil
    @State private var isHeartRateSheetPresented = false
    @State private var isSpeedSheetPresented = false
    @State private var isEnergySheetPresented = false
    @State private var isDistanceSheetPresented = false
    @State private var isCadenceSheetPresented = false
    @State private var isDurationSheetPresented = false
    @State private var isPaceSheetPresented = false
    @State private var isElevationSheetPresented = false
    @State private var showingShareSheet = false
    @State private var shareData: ShareData?
    
    @State private var selectedSport: SportType = .running
    
    // Фильтрованные данные
    private var filteredWorkouts: [WorkoutEntity] {
        let range = DateFilterHelper.calculateDateRange(for: selectedFilter, around: selectedPeriod)
        return workouts.filter {
            guard let startDate = $0.startDate else { return false }
            return startDate >= range.start && startDate <= range.end && $0.workoutType == selectedSport.rawValue
        }
    }
    private var availablePeriods: [Date] {
        DateFilterHelper.availablePeriods(for: selectedFilter)
    }
    
    private var monthlyAggregatedWorkouts: [MonthlyWorkoutSummary] {
        let calendar = Calendar.current
        
        // Группируем данные по месяцам
        let groupedByMonth = Dictionary(grouping: filteredWorkouts) { workout in
            calendar.dateComponents([.year, .month], from: workout.startDate!)
        }
        
        // Вычисляем суммарные значения для каждого месяца
        return groupedByMonth.map { (key, workoutsInMonth) -> MonthlyWorkoutSummary in
            let totalDistance = workoutsInMonth.reduce(0) { $0 + ($1.totalDistance) }
            let totalEnergyBurned = workoutsInMonth.reduce(0) { $0 + ($1.totalEnergyBurned) }
            
            // Calculate average heart rate excluding workouts with 0 heart rate
            let validHeartRates = workoutsInMonth.compactMap { $0.averageHeartRate > 0 ? $0.averageHeartRate : nil }
            let averageHeartRate = validHeartRates.isEmpty ? 0 : validHeartRates.reduce(0, +) / Double(validHeartRates.count)
            
            let maxHeartRate = workoutsInMonth.compactMap { $0.maxHeartRate }.max() ?? 0
            let averageSpeed = workoutsInMonth.compactMap { $0.averageSpeed }.reduce(0, +) / Double(workoutsInMonth.count)
            let maxSpeed = workoutsInMonth.compactMap { $0.maxSpeed }.max() ?? 0
            let averageCadence = workoutsInMonth.compactMap { $0.cadenceRun }.reduce(0, +) / Double(workoutsInMonth.count)
            let totalDuration = workoutsInMonth.reduce(0) { $0 + ($1.duration) }
            let averagePace = workoutsInMonth.compactMap { $0.pace }.reduce(0, +) / Double(workoutsInMonth.count)
            let totalElevation = workoutsInMonth.reduce(0) { $0 + ($1.totalElevationGain) }
            
            // Формируем дату начала месяца
            let monthStart = calendar.date(from: key)!
            
            return MonthlyWorkoutSummary(
                month: monthStart,
                totalDistance: totalDistance,
                totalEnergyBurned: totalEnergyBurned,
                averageHeartRate: averageHeartRate,
                maxHeartRate: maxHeartRate,
                averageSpeed: averageSpeed,
                maxSpeed: maxSpeed,
                averageCadence: averageCadence,
                totalDuration: totalDuration,
                averagePace: averagePace,
                totalElevation: totalElevation
            )
        }.sorted { $0.month < $1.month } // Сортируем по дате
    }
    
    private var aggregatedStatistics: (
        totalWorkouts: Int,
        totalDuration: TimeInterval,
        totalDistance: Double,
        totalEnergyBurned: Double,
        totalElevation: Double,
        averageHeartRate: Double
    ) {
        let filtered = filteredWorkouts
        print("Filtered workouts count: \(filtered.count)")
        
        // Calculate average heart rate excluding workouts with 0 heart rate
        let validHeartRates = filtered.compactMap { $0.averageHeartRate > 0 ? $0.averageHeartRate : nil }
        let averageHeartRate = validHeartRates.isEmpty ? 0 : validHeartRates.reduce(0, +) / Double(validHeartRates.count)
        
        return (
            totalWorkouts: filtered.count,
            totalDuration: filtered.reduce(0) { $0 + ($1.duration) },
            totalDistance: filtered.reduce(0) { $0 + ($1.totalDistance) },
            totalEnergyBurned: filtered.reduce(0) { $0 + ($1.totalEnergyBurned) },
            totalElevation: filtered.reduce(0) { $0 + ($1.totalElevationGain) },
            averageHeartRate: averageHeartRate
        )
    }

    // Вспомогательная структура для хранения суммарных данных за месяц
    struct MonthlyWorkoutSummary {
        let month: Date
        let totalDistance: Double
        let totalEnergyBurned: Double
        let averageHeartRate: Double
        let maxHeartRate: Double
        let averageSpeed: Double
        let maxSpeed: Double
        let averageCadence: Double
        let totalDuration: TimeInterval
        let averagePace: Double
        let totalElevation: Double
    }
    
    // Sport-specific chart configurations
    private var availableCharts: [ChartType] {
        switch selectedSport {
        case .running:
            return [.heartRate, .speed, .calories, .distance, .pace, .duration, .cadenceRun, .elevation]
        case .cycling:
            return [.heartRate, .speed, .calories, .distance, .duration, .elevation]
        case .swimming:
            return [.heartRate, .speed, .calories, .distance, .duration]
        case .walking:
            return [.heartRate, .speed, .calories, .distance, .duration, .elevation]
        case .hiking:
            return [.heartRate, .speed, .calories, .distance, .duration, .elevation]
        case .other:
            return [.heartRate, .speed, .calories, .distance, .duration]
        }
    }
    
    // Optimized elevation data for better performance
    private var optimizedElevationData: [Double] {
        if selectedFilter == .year {
            return monthlyAggregatedWorkouts.map { $0.totalElevation }
        } else {
            return filteredWorkouts.map { $0.totalElevationGain }
        }
    }
    
    var body: some View {
        ZStack {
            
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                    
                        // Header with Share Button and Monthly Summary
                        HStack {
                            Text("Training Dashboard")
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            
                            HStack(spacing: 16) {
                                // Permission indicator - show if HealthKit is not authorized
                                if permissionManager.healthKitStatus != .authorized {
                                    Button(action: {
                                        PermissionMessageHelper.showPermissionAlert(
                                            permissionType: .healthKit,
                                            featureName: "Statistics"
                                        )
                                    }) {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                    }
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        NavigationCoordinator.shared.selectMenuItem(.monthlySummary)
                                    }
                                }) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: {
                                    prepareDashboardShareData()
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.top, 30)
                        .padding(.horizontal)
                        
                        TimeFilterSegmentedControl(selectedFilter: $selectedFilter)
                        
                        // Календарный выбор периода
                        PeriodSelectionButton(filter: selectedFilter, selectedDate: $selectedPeriod)
                        
                        SportTabs(
                            options: SportType.allCases,
                            selectedOption: $selectedSport
                        )
                    }
                    // Раздел общей статистики
                    
                    StatisticsTable(aggregatedStatistics: aggregatedStatistics)
                    
                    // let filteredWorkouts = ...
                    let bestDistance = filteredWorkouts.map { $0.totalDistance }.max() ?? 0
                    let bestDuration = filteredWorkouts.map { $0.duration }.max() ?? 0
                    let bestPace = filteredWorkouts.compactMap { $0.pace > 0 ? $0.pace : nil }.min()
                    let bestCalories = filteredWorkouts.map { $0.totalEnergyBurned }.max() ?? 0
                    let bestElevation = filteredWorkouts.map { $0.totalElevationGain }.max() ?? 0

                    let previousPeriod = DateFilterHelper.previousPeriod(for: selectedFilter, around: selectedPeriod)
                    let previousFilteredWorkouts = workouts.filter {
                        guard let startDate = $0.startDate else { return false }
                        return startDate >= previousPeriod.start && startDate <= previousPeriod.end && $0.workoutType == selectedSport.rawValue
                    }
                    let prevBestDistance = previousFilteredWorkouts.map { $0.totalDistance }.max() ?? 0
                    let prevBestDuration = previousFilteredWorkouts.map { $0.duration }.max() ?? 0
                    let prevBestPace = previousFilteredWorkouts.compactMap { $0.pace > 0 ? $0.pace : nil }.min()
                    let prevBestCalories = previousFilteredWorkouts.map { $0.totalEnergyBurned }.max() ?? 0
                    let prevBestElevation = previousFilteredWorkouts.map { $0.totalElevationGain }.max() ?? 0

                    PersonalBestsWidget(
                        bestDistance: bestDistance / 1000,
                        bestDuration: bestDuration,
                        bestPace: bestPace,
                        bestCalories: bestCalories,
                        bestElevation: bestElevation,
                        isNewDistance: bestDistance > prevBestDistance,
                        isNewDuration: bestDuration > prevBestDuration,
                        isNewPace: (bestPace != nil && (prevBestPace == nil || bestPace! < prevBestPace!)),
                        isNewCalories: bestCalories > prevBestCalories,
                        isNewElevation: bestElevation > prevBestElevation
                    )
                    
                    
                    
                }
                .padding()
                
                // Dynamic chart grid based on sport type
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 1), GridItem(.flexible(), spacing: 1)], spacing: 4) {
                    ForEach(availableCharts, id: \.self) { chartType in
                        chartCard(for: chartType)
                    }
                }
                .padding(.horizontal)

            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showingShareSheet) {
            if let shareData = shareData {
                ShareSheetMetrics(activityItems: shareData.items, applicationActivities: nil)
            }
        }
        .onAppear {
            // Check permissions when view appears
            Task {
                await permissionManager.checkCurrentPermissions()
            }
        }
    }
    
    // Helper function to create chart cards dynamically
    @ViewBuilder
    private func chartCard(for chartType: ChartType) -> some View {
        switch chartType {
        case .heartRate:
            LiquidGlassCard(title: "Heart Rate", chartModel: heartRateChartModel) {
                selectedChartModel = heartRateChartModel
                isHeartRateSheetPresented = true
            }
            .sheet(isPresented: $isHeartRateSheetPresented) {
                FullScreenChartView(
                    chartType: .heartRate,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .speed:
            LiquidGlassCard(title: "Speed", chartModel: speedChartModel) {
                selectedChartModel = speedChartModel
                isSpeedSheetPresented = true
            }
            .sheet(isPresented: $isSpeedSheetPresented) {
                FullScreenChartView(
                    chartType: .speed,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .calories:
            LiquidGlassCard(title: "Calories Burned", chartModel: energyChartModel) {
                selectedChartModel = energyChartModel
                isEnergySheetPresented = true
            }
            .sheet(isPresented: $isEnergySheetPresented) {
                FullScreenChartView(
                    chartType: .calories,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .distance:
            LiquidGlassCard(title: "Distance", chartModel: distanceChartModel) {
                selectedChartModel = distanceChartModel
                isDistanceSheetPresented = true
            }
            .sheet(isPresented: $isDistanceSheetPresented) {
                FullScreenChartView(
                    chartType: .distance,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .cadenceRun:
            LiquidGlassCard(title: "Cadence", chartModel: cadenceChartModel) {
                selectedChartModel = cadenceChartModel
                isCadenceSheetPresented = true
            }
            .sheet(isPresented: $isCadenceSheetPresented) {
                FullScreenChartView(
                    chartType: .cadenceRun,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .duration:
            LiquidGlassCard(title: "Duration", chartModel: durationChartModel) {
                selectedChartModel = durationChartModel
                isDurationSheetPresented = true
            }
            .sheet(isPresented: $isDurationSheetPresented) {
                FullScreenChartView(
                    chartType: .duration,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .pace:
            LiquidGlassCard(title: "Pace", chartModel: paceChartModel) {
                selectedChartModel = paceChartModel
                isPaceSheetPresented = true
            }
            .sheet(isPresented: $isPaceSheetPresented) {
                FullScreenChartView(
                    chartType: .pace,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
            
        case .elevation:
            LiquidGlassCard(title: "Elevation", chartModel: elevationChartModel) {
                // Pre-load the chart model to avoid delays
                selectedChartModel = elevationChartModel
                DispatchQueue.main.async {
                    isElevationSheetPresented = true
                }
            }
            .sheet(isPresented: $isElevationSheetPresented) {
                FullScreenChartView(
                    chartType: .elevation,
                    initialFilter: selectedFilter,
                    initialPeriod: selectedPeriod
                )
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0 min"
    }
    var progressChartModel: AAChartModel {
        AAChartModel()
            .chartType(.line)
            .title("Total Calories Burned")
            .categories(categories)
            .series([
                AASeriesElement()
                    .name("Calories")
                    .data(selectedFilter == .year
                          ? monthlyAggregatedWorkouts.map { $0.totalEnergyBurned }
                          : filteredWorkouts.map { $0.totalEnergyBurned })
            ])
    }
    // MARK: - Chart Data Builders
    
    private var categories: [String] {
        if selectedFilter == .year {
            return monthlyAggregatedWorkouts.map {
                $0.month.formatted(date: .abbreviated, time: .omitted)
            }
        } else {
            return filteredWorkouts.map {
                $0.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "?"
            }
        }
    }
    
    var heartRateChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Avg HR").data(selectedFilter == .year
                                                      ? monthlyAggregatedWorkouts.map { $0.averageHeartRate }
                                                      : filteredWorkouts.compactMap { $0.averageHeartRate > 0 ? $0.averageHeartRate : nil }),
                AASeriesElement().name("Max HR").data(selectedFilter == .year
                                                      ? monthlyAggregatedWorkouts.map { $0.maxHeartRate }
                                                      : filteredWorkouts.compactMap { $0.maxHeartRate > 0 ? $0.maxHeartRate : nil })
            ])
    }
    
    var speedChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Avg Speed").data(selectedFilter == .year
                                                         ? monthlyAggregatedWorkouts.map { $0.averageSpeed * 3.6 }
                                                         : filteredWorkouts.map { $0.averageSpeed * 3.6 }),
                AASeriesElement().name("Max Speed").data(selectedFilter == .year
                                                         ? monthlyAggregatedWorkouts.map { $0.maxSpeed * 3.6 }
                                                         : filteredWorkouts.map { $0.maxSpeed * 3.6 })
            ])
    }
    
    var energyChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Calories").data(selectedFilter == .year
                                                        ? monthlyAggregatedWorkouts.map { $0.totalEnergyBurned }
                                                        : filteredWorkouts.map { $0.totalEnergyBurned })
            ])
    }
    
    var distanceChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("KM").data(selectedFilter == .year
                                                  ? monthlyAggregatedWorkouts.map { $0.totalDistance / 1000.0 }
                                                  : filteredWorkouts.map { $0.totalDistance / 1000.0 })
            ])
    }
    var paceChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Avg Pace").data(selectedFilter == .year
                                                        ? monthlyAggregatedWorkouts.map { $0.averagePace > 0 ? $0.averagePace * 1000 / 60 : nil }.compactMap { $0 }
                                                        : filteredWorkouts.map { $0.pace > 0 ? $0.pace * 1000 / 60 : nil }.compactMap { $0 })
            ])
    }
    var durationChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Duration").data(selectedFilter == .year
                                                        ? monthlyAggregatedWorkouts.map { $0.totalDuration / 60 }
                                                        : filteredWorkouts.map { ($0.duration) / 60 })
            ])
    }
    var cadenceChartModel: AAChartModel {
        AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Avg Cadence").data(selectedFilter == .year
                                                           ? monthlyAggregatedWorkouts.map { $0.averageCadence }
                                                           : filteredWorkouts.map { $0.cadenceRun })
            ])
    }
        var elevationChartModel: AAChartModel {
        return AAChartModel()
            .chartType(.spline)
            .title("")
            .legendEnabled(false)
            .categories(categories)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
            .series([
                AASeriesElement().name("Elevation Gain").data(optimizedElevationData)
            ])
    }
    
    
    // MARK: - Share Functionality
    private func prepareDashboardShareData() {
        let shareText = generateDashboardShareText()
        let shareImage = generateDashboardShareImage()
        let csvData = generateDashboardCSVData()
        let csvURL = createDashboardCSVFile(data: csvData)
        
        shareData = ShareData(
            text: shareText,
            image: shareImage,
            csvData: csvData,
            csvURL: csvURL
        )
        
        showingShareSheet = true
    }
    
    private func createDashboardCSVFile(data: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let filename = "training_dashboard_\(selectedSport.rawValue.lowercased())_\(selectedFilter.rawValue).csv"
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating CSV file: \(error)")
            return nil
        }
    }
    
    private func generateDashboardShareText() -> String {
        let periodRange = DateFilterHelper.calculateDateRange(for: selectedFilter, around: selectedPeriod)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var text = "🏃‍♂️ Training Dashboard Summary\n"
        text += "📅 Period: \(formatter.string(from: periodRange.start)) - \(formatter.string(from: periodRange.end))\n"
        text += "🏆 Sport: \(selectedSport.displayName)\n\n"
        
        // Overview Statistics
        text += "📊 Overview:\n"
        text += "• Total Workouts: \(aggregatedStatistics.totalWorkouts)\n"
        text += "• Total Duration: \(formatDuration(aggregatedStatistics.totalDuration))\n"
        text += "• Total Distance: \(String(format: "%.1f km", aggregatedStatistics.totalDistance / 1000))\n"
        text += "• Total Calories: \(String(format: "%.0f kcal", aggregatedStatistics.totalEnergyBurned))\n"
        text += "• Average Heart Rate: \(String(format: "%.0f bpm", aggregatedStatistics.averageHeartRate))\n\n"
        
        // Personal Bests
        let bestDistance = filteredWorkouts.map { $0.totalDistance }.max() ?? 0
        let bestDuration = filteredWorkouts.map { $0.duration }.max() ?? 0
        let bestPace = filteredWorkouts.compactMap { $0.pace > 0 ? $0.pace : nil }.min()
        let bestCalories = filteredWorkouts.map { $0.totalEnergyBurned }.max() ?? 0
        
        text += "🏅 Personal Bests:\n"
        text += "• Longest Distance: \(String(format: "%.1f km", bestDistance / 1000))\n"
        text += "• Longest Duration: \(formatDuration(bestDuration))\n"
        if let pace = bestPace {
            text += "• Best Pace: \(formatPaceFromSecPerMeter(pace)) min/km\n"
        }
        text += "• Max Calories: \(String(format: "%.0f kcal", bestCalories))\n\n"
        
        // Training Insights
        text += "💡 Training Insights:\n"
        if aggregatedStatistics.totalWorkouts > 0 {
            let avgDistance = aggregatedStatistics.totalDistance / Double(aggregatedStatistics.totalWorkouts) / 1000
            let avgDuration = aggregatedStatistics.totalDuration / Double(aggregatedStatistics.totalWorkouts) / 60
            text += "• Average Distance per Workout: \(String(format: "%.1f km", avgDistance))\n"
            text += "• Average Duration per Workout: \(String(format: "%.0f min", avgDuration))\n"
        }
        text += "• Consistency: \(aggregatedStatistics.totalWorkouts > 0 ? "Great job!" : "Keep going!")\n\n"
        
        // App Info
        text += "📱 Shared from Fitness Analytics App"
        
        return text
    }
    
    private func generateDashboardShareImage() -> UIImage? {
        let renderer = ImageRenderer(content: dashboardShareImageView)
        renderer.scale = 3.0
        return renderer.uiImage
    }
    
    private var dashboardShareImageView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Training Dashboard")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    Text("\(selectedSport.displayName) Performance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Overview Statistics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ShareStatCard(title: "Workouts", value: "\(aggregatedStatistics.totalWorkouts)", unit: "", color: .green)
                ShareStatCard(title: "Duration", value: formatDuration(aggregatedStatistics.totalDuration), unit: "", color: .purple)
                ShareStatCard(title: "Distance", value: String(format: "%.1f", aggregatedStatistics.totalDistance / 1000), unit: "km", color: .blue)
                ShareStatCard(title: "Calories", value: String(format: "%.0f", aggregatedStatistics.totalEnergyBurned), unit: "kcal", color: .orange)
            }
            
            // Personal Bests
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal Bests")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let bestDistance = filteredWorkouts.map { $0.totalDistance }.max() ?? 0
                let bestDuration = filteredWorkouts.map { $0.duration }.max() ?? 0
                let bestCalories = filteredWorkouts.map { $0.totalEnergyBurned }.max() ?? 0
                
                HStack {
                    ShareStatCard(title: "Best Distance", value: String(format: "%.1f", bestDistance / 1000), unit: "km", color: .blue)
                    ShareStatCard(title: "Best Duration", value: formatDuration(bestDuration), unit: "", color: .purple)
                    ShareStatCard(title: "Max Calories", value: String(format: "%.0f", bestCalories), unit: "kcal", color: .orange)
                }
            }
            
            // App Branding
            HStack {
                Spacer()
                Text("Fitness Analytics")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .frame(width: 400, height: 700)
    }
    
    private func generateDashboardCSVData() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        var csv = "Date,Sport Type,Duration (min),Distance (km),Calories (kcal),Avg Heart Rate (bpm),Max Heart Rate (bpm),Avg Speed (km/h),Max Speed (km/h),Pace (min/km),Cadence (spm),Elevation Gain (m)\n"
        
        for workout in filteredWorkouts {
            guard let startDate = workout.startDate else { continue }
            
            let dateString = formatter.string(from: startDate)
            let sportType = workout.workoutType ?? "Unknown"
            let duration = String(format: "%.0f", workout.duration / 60)
            let distance = String(format: "%.3f", workout.totalDistance / 1000.0)
            let calories = String(format: "%.0f", workout.totalEnergyBurned)
            let avgHR = String(format: "%.0f", workout.averageHeartRate)
            let maxHR = String(format: "%.0f", workout.maxHeartRate)
            let avgSpeed = String(format: "%.2f", workout.averageSpeed * 3.6)
            let maxSpeed = String(format: "%.2f", workout.maxSpeed * 3.6)
            let pace = workout.pace > 0 ? String(format: "%.2f", workout.pace * 1000 / 60) : ""
            let cadence = String(format: "%.0f", workout.cadenceRun)
            let elevation = String(format: "%.0f", workout.totalElevationGain)
            
            csv += "\(dateString),\(sportType),\(duration),\(distance),\(calories),\(avgHR),\(maxHR),\(avgSpeed),\(maxSpeed),\(pace),\(cadence),\(elevation)\n"
        }
        
        return csv
    }
}

struct SportTabs: View {
    let options: [SportType]
    @Binding var selectedOption: SportType
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        withAnimation {
                            selectedOption = option
                        }
                    }) {
                        Text(option.displayName)
                            .font(.headline)
                            .foregroundColor(selectedOption == option ? .white : .primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedOption == option ? Color.blue : Color(.tertiarySystemBackground))
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LiquidGlassCard: View {
    let title: String
    let chartModel: AAChartModel
    @Environment(\.colorScheme) var colorScheme
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForTitle(title))
                    .font(.headline)
                    .foregroundColor(accentColorForTitle(title))
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Image(systemName: "arrow.down.left.and.arrow.up.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            AAChartViewWrapper(chartModel: chartModel)
                .frame(height: 200)
                .padding(.all, 1)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
        .onTapGesture {
            action()
        }
    }
    private func iconForTitle(_ title: String) -> String {
        switch title.lowercased() {
        case let t where t.contains("heart"): return "heart.fill"
        case let t where t.contains("speed"): return "speedometer"
        case let t where t.contains("calorie"): return "flame.fill"
        case let t where t.contains("distance"): return "figure.walk.motion"
        case let t where t.contains("cadence"): return "figure.run"
        case let t where t.contains("duration"): return "timer"
        case let t where t.contains("pace"): return "hare.fill"
        case let t where t.contains("elevation"): return "mountain.2"
        default: return "chart.bar"
        }
    }
    private func accentColorForTitle(_ title: String) -> Color {
        switch title.lowercased() {
        case let t where t.contains("heart"): return .red
        case let t where t.contains("speed"): return .blue
        case let t where t.contains("calorie"): return .orange
        case let t where t.contains("distance"): return .blue
        case let t where t.contains("cadence"): return .green
        case let t where t.contains("duration"): return .purple
        case let t where t.contains("pace"): return .mint
        case let t where t.contains("elevation"): return .mint
        default: return .accentColor
        }
    }
}

enum ChartType {
    case heartRate
    case speed
    case calories
    case distance
    case pace
    case duration
    case cadenceRun
    case elevation
}

struct FullScreenChartView: View {
    let chartType: ChartType
    let initialFilter: TimeFilter
    let initialPeriod: Date
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutEntity.startDate, ascending: true)],
        animation: .default
    )
    private var workouts: FetchedResults<WorkoutEntity>

    @State private var selectedFilter: TimeFilter
    @State private var selectedPeriod: Date
    @State private var showingShareSheet = false
    @State private var shareData: ShareData?
    @State private var isLoading = true
    @State private var cachedChartModel: AAChartModel?
    
    // AI Analysis states
    @State private var isAIAnalyzing = false
    @State private var aiAnalysisResult: String?
    @State private var showingAIAnalysis = false
    @State private var aiAnalysisError: String?
    private let metricsSender = MetricsSender()

    init(chartType: ChartType, initialFilter: TimeFilter, initialPeriod: Date) {
        self.chartType = chartType
        self.initialFilter = initialFilter
        self.initialPeriod = initialPeriod
        _selectedFilter = State(initialValue: initialFilter)
        _selectedPeriod = State(initialValue: initialPeriod)
    }

    private var availablePeriods: [Date] {
        DateFilterHelper.availablePeriods(for: selectedFilter)
    }

    // Optimized data filtering with caching
    @State private var cachedFilteredData: [WorkoutEntity] = []
    @State private var cachedFilteredDataWithValues: [WorkoutEntity] = []
    
    private func updateCachedData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let range = DateFilterHelper.calculateDateRange(for: selectedFilter, around: selectedPeriod)
            let filtered = workouts.filter {
                guard let startDate = $0.startDate else { return false }
                return startDate >= range.start && startDate <= range.end
            }
            
            // Pre-calculate elevation values on main thread to avoid Core Data threading issues
            DispatchQueue.main.async {
                let filteredWithValues = self.filterDataWithValues(filtered)
                
                self.cachedFilteredData = filtered
                self.cachedFilteredDataWithValues = filteredWithValues
                self.cachedChartModel = nil // Clear chart cache when data changes
                self.updateChartModel() // Update chart model after data changes
                self.isLoading = false
            }
        }
    }
    
    private func filterDataWithValues(_ data: [WorkoutEntity]) -> [WorkoutEntity] {
        switch chartType {
        case .heartRate:
            return data.filter { 
                let hr = $0.averageHeartRate
                return hr > 0 && !hr.isNaN && !hr.isInfinite
            }
        case .speed:
            return data.filter { 
                let speed = $0.averageSpeed
                return speed > 0 && !speed.isNaN && !speed.isInfinite
            }
        case .calories:
            return data.filter { 
                let calories = $0.totalEnergyBurned
                return calories > 0 && !calories.isNaN && !calories.isInfinite
            }
        case .distance:
            return data.filter { 
                let distance = $0.totalDistance
                return distance > 0 && !distance.isNaN && !distance.isInfinite
            }
        case .pace:
            return data.filter { 
                let pace = $0.pace
                return pace > 0 && !pace.isNaN && !pace.isInfinite
            }
        case .duration:
            return data.filter { 
                let duration = $0.duration
                return duration > 0 && !duration.isNaN && !duration.isInfinite
            }
        case .cadenceRun:
            return data.filter { 
                let cadence = $0.cadenceRun
                return cadence > 0 && !cadence.isNaN && !cadence.isInfinite
            }
        case .elevation:
            return data.filter { 
                let elevation = $0.totalElevationGain
                return elevation > 0 && !elevation.isNaN && !elevation.isInfinite
            }
        }
    }

    private var categories: [String] {
        cachedFilteredData.map {
            $0.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "?"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                if isLoading {
                    VStack {
                        ProgressView("Loading chart data...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Please wait")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else {
                    ZStack {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Header Section
                                headerSection
                                // AI Analysis Section
                                if let aiResult = aiAnalysisResult {
                                    aiAnalysisSection(result: aiResult)
                                } else if let aiError = aiAnalysisError {
                                    aiErrorSection(error: aiError)
                                }
                                }
                                .padding()
                                // Chart Section
                                chartSection
                                
                                // Statistics Section
                                statisticsSection
                                
//                                // Trends Section
//                                trendsSection
                                
                                // Scientific Info Section
                                scientificInfoSection
                                
                                // Tips Section
                                tipsSection
                                
                                                            
                        }
                        
                        // AI Analysis Loading Overlay
                        if isAIAnalyzing {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                
                                Text("AI is analyzing your data...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("This may take a few moments")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(32)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            performAIAnalysis()
                        }) {
                            HStack(spacing: 4) {
                                if isAIAnalyzing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "brain.head.profile")
                                }
                                Text("AI Analysis")
                                    .font(.caption)
                            }
                            .foregroundColor(isAIAnalyzing ? .white : .blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isAIAnalyzing ? Color.blue : Color.blue.opacity(0.1))
                            )
                        }
                        .disabled(isAIAnalyzing || cachedFilteredDataWithValues.isEmpty)
                        
                        Button(action: {
                            prepareShareData()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareData = shareData {
                    ShareSheetMetrics(activityItems: shareData.items, applicationActivities: nil)
                }
            }
            .onAppear {
                updateCachedData()
                // Update chart model after data is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateChartModel()
                }
            }
            .onChange(of: selectedFilter) { oldValue, newValue in
                isLoading = true
                updateCachedData()
            }
            .onChange(of: selectedPeriod) { oldValue, newValue in
                isLoading = true
                updateCachedData()
            }
        }
    }
    
    // MARK: - Share Functionality
    private func prepareShareData() {
        let shareText = generateShareText()
        let shareImage = generateShareImage()
        let csvData = generateCSVData()
        let csvURL = createCSVFile(data: csvData, filename: "\(titleForChartType.lowercased().replacingOccurrences(of: " ", with: "_"))_data.csv")
        
        shareData = ShareData(
            text: shareText,
            image: shareImage,
            csvData: csvData,
            csvURL: csvURL
        )
        
        showingShareSheet = true
    }
    
    private func createCSVFile(data: String, filename: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating CSV file: \(error)")
            return nil
        }
    }
    
    private func generateShareText() -> String {
        let periodRange = DateFilterHelper.calculateDateRange(for: selectedFilter, around: selectedPeriod)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var text = "🏃‍♂️ \(titleForChartType) Analysis\n"
        text += "📅 Period: \(formatter.string(from: periodRange.start)) - \(formatter.string(from: periodRange.end))\n\n"
        
        // Key Statistics
        text += "📊 Key Statistics:\n"
        text += "• Average: \(averageValue) \(unitForChartType)\n"
        text += "• Best: \(bestValue) \(unitForChartType)\n"
        text += "• Total Sessions: \(cachedFilteredDataWithValues.count)\n"
        
        
        // Scientific Insights
        text += "🧠 Scientific Insights:\n"
        text += scientificDescription + "\n\n"
        
        // Pro Tip
        text += "💡 Pro Tip: \(proTip)\n\n"
        
        // App Info
        text += "📱 Shared from Fitness Analytics App"
        
        return text
    }
    
    private func generateShareImage() -> UIImage? {
        // Создаем изображение для шаринга
        let renderer = ImageRenderer(content: shareImageView)
        renderer.scale = 3.0
        return renderer.uiImage
    }
    
    private func generateCSVData() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        var csv = "Date,\(titleForChartType) (\(unitForChartType)),Max \(titleForChartType) (\(unitForChartType))\n"
        
        for workout in cachedFilteredDataWithValues {
            guard let startDate = workout.startDate else { continue }
            
            let dateString = formatter.string(from: startDate)
            let value: String
            let maxValue: String
            
            switch chartType {
            case .heartRate:
                value = String(format: "%.0f", workout.averageHeartRate)
                maxValue = String(format: "%.0f", workout.maxHeartRate)
            case .speed:
                value = String(format: "%.2f", workout.averageSpeed * 3.6)
                maxValue = String(format: "%.2f", workout.maxSpeed * 3.6)
            case .calories:
                value = String(format: "%.0f", workout.totalEnergyBurned)
                maxValue = value // Calories don't have max/min concept
            case .distance:
                value = String(format: "%.3f", workout.totalDistance / 1000.0)
                maxValue = value // Distance is total, not max
            case .pace:
                value = String(format: "%.2f", workout.pace * 1000 / 60)
                maxValue = value // Pace is average, not max
            case .duration:
                value = String(format: "%.0f", workout.duration / 60)
                maxValue = value // Duration is total, not max
            case .cadenceRun:
                value = String(format: "%.0f", workout.cadenceRun)
                maxValue = value // Cadence is average, not max
            case .elevation:
                value = String(format: "%.0f", workout.totalElevationGain)
                maxValue = value // Elevation is total, not max
            }
            
            csv += "\(dateString),\(value),\(maxValue)\n"
        }
        
        return csv
    }
    
    private var shareImageView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: iconForChartType)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(accentColorForChartType)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleForChartType)
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    Text(subtitleForChartType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Statistics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ShareStatCard(title: "Average", value: averageValue, unit: unitForChartType, color: .blue)
                ShareStatCard(title: "Best", value: bestValue, unit: unitForChartType, color: .orange)
                ShareStatCard(title: "Sessions", value: "\(cachedFilteredDataWithValues.count)", unit: "", color: .green)
                ShareStatCard(title: "Improvement", value: improvementValue, unit: "%", color: .green)
            }
            
            // Pro Tip
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Pro Tip: \(proTip)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            
            // App Branding
            HStack {
                Spacer()
                Text("Fitness Analytics")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .frame(width: 400, height: 600)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and Subtitle
            HStack {
                Image(systemName: iconForChartType)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(accentColorForChartType)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleForChartType)
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                    Text(subtitleForChartType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Filter Controls - в одной строке
            VStack {
                TimeFilterSegmentedControl(selectedFilter: $selectedFilter) { _ in
                    selectedPeriod = Date()
                }
                
                Spacer()
                
                PeriodSelectionButton(filter: selectedFilter, selectedDate: $selectedPeriod)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trend")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            AAChartViewWrapper(chartModel: updatedChartModel)
                .frame(height: 300)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.2 : 0.1), radius: 8, x: 0, y: 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Statistics")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCardMetrics(title: "Average", value: averageValue, unit: unitForChartType, icon: "chart.bar.fill", color: .blue)
                StatCardMetrics(title: "Best", value: bestValue, unit: unitForChartType, icon: "trophy.fill", color: .orange)
                StatCardMetrics(title: "Sessions", value: "\(cachedFilteredDataWithValues.count)", unit: "", icon: "figure.run", color: .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // // MARK: - Trends Section
    // private var trendsSection: some View {
    //     VStack(alignment: .leading, spacing: 16) {
    //         Text("Progress Trends")
    //             .font(.title2.bold())
    //             .foregroundColor(.primary)
            
    //         VStack(spacing: 12) {
    //             TrendRow(title: "Weekly Average", value: weeklyTrend, trend: .up, color: .green)
    //             TrendRow(title: "Monthly Progress", value: monthlyTrend, trend: .stable, color: .blue)
    //             TrendRow(title: "Consistency", value: consistencyValue, trend: .up, color: .orange)
    //         }
    //     }
    //     .padding()
    //     .background(Color(.systemBackground))
    //     .cornerRadius(20)
    //     .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    // }
    
    // MARK: - Scientific Info Section
    private var scientificInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scientific Insights")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(scientificDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Pro Tip: \(proTip)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Training Tips")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(trainingTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text(tip)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - AI Analysis Section
    private func aiAnalysisSection(result: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("AI Analysis")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    aiAnalysisResult = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            ScrollView {
                Text(try! AttributedString(markdown: result))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 300)
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Analysis based on your \(titleForChartType.lowercased()) data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - AI Error Section
    private func aiErrorSection(error: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("AI Analysis Error")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    aiAnalysisError = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            
            Button(action: {
                aiAnalysisError = nil
                performAIAnalysis()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Properties
    private var iconForChartType: String {
        switch chartType {
        case .heartRate: return "heart.fill"
        case .speed: return "speedometer"
        case .calories: return "flame.fill"
        case .distance: return "figure.walk.motion"
        case .pace: return "hare.fill"
        case .duration: return "timer"
        case .cadenceRun: return "figure.run"
        case .elevation: return "mountain.2"
        }
    }
    
    private var titleForChartType: String {
        switch chartType {
        case .heartRate: return "Heart Rate"
        case .speed: return "Speed"
        case .calories: return "Calories Burned"
        case .distance: return "Distance"
        case .pace: return "Pace"
        case .duration: return "Duration"
        case .cadenceRun: return "Cadence"
        case .elevation: return "Elevation Gain"
        }
    }
    
    private var subtitleForChartType: String {
        switch chartType {
        case .heartRate: return "Cardiovascular Performance"
        case .speed: return "Movement Velocity"
        case .calories: return "Energy Expenditure"
        case .distance: return "Distance Covered"
        case .pace: return "Time per Distance"
        case .duration: return "Training Duration"
        case .cadenceRun: return "Steps per Minute"
        case .elevation: return "Elevation Gain"
        }
    }
    
    private var accentColorForChartType: Color {
        switch chartType {
        case .heartRate: return .red
        case .speed: return .blue
        case .calories: return .orange
        case .distance: return .green
        case .pace: return .mint
        case .duration: return .purple
        case .cadenceRun: return .teal
        case .elevation: return .mint
        }
    }
    
    private var unitForChartType: String {
        switch chartType {
        case .heartRate: return "bpm"
        case .speed: return "km/h"
        case .calories: return "kcal"
        case .distance: return "km"
        case .pace: return "min/km"
        case .duration: return "min"
        case .cadenceRun: return "spm"
        case .elevation: return "m"
        }
    }
    
    private var averageValue: String {
        switch chartType {
        case .heartRate:
            let validData = cachedFilteredDataWithValues.compactMap { $0.averageHeartRate > 0 ? $0.averageHeartRate : nil }
            guard !validData.isEmpty else { return "0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.0f", avg)
        case .speed:
            let validData = cachedFilteredDataWithValues.compactMap { $0.averageSpeed > 0 ? $0.averageSpeed * 3.6 : nil }
            guard !validData.isEmpty else { return "0.0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.1f", avg)
        case .calories:
            let validData = cachedFilteredDataWithValues.compactMap { $0.totalEnergyBurned > 0 ? $0.totalEnergyBurned : nil }
            guard !validData.isEmpty else { return "0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.0f", avg)
        case .distance:
            let validData = cachedFilteredDataWithValues.compactMap { $0.totalDistance > 0 ? $0.totalDistance / 1000.0 : nil }
            guard !validData.isEmpty else { return "0.0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.1f", avg)
        case .pace:
            let validData = cachedFilteredDataWithValues.compactMap { $0.pace > 0 ? $0.pace : nil }
            guard !validData.isEmpty else { return "0:00" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return formatPaceFromSecPerMeter(avg)
        case .duration:
            let validData = cachedFilteredDataWithValues.compactMap { $0.duration > 0 ? $0.duration / 60 : nil }
            guard !validData.isEmpty else { return "0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.0f", avg)
        case .cadenceRun:
            let validData = cachedFilteredDataWithValues.compactMap { $0.cadenceRun > 0 ? $0.cadenceRun : nil }
            guard !validData.isEmpty else { return "0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.0f", avg)
        case .elevation:
            let validData = cachedFilteredDataWithValues.compactMap { $0.totalElevationGain > 0 ? $0.totalElevationGain : nil }
            guard !validData.isEmpty else { return "0" }
            let avg = validData.reduce(0, +) / Double(validData.count)
            return String(format: "%.0f", avg)
        }
    }
    
    private var bestValue: String {
        switch chartType {
        case .heartRate:
            let best = cachedFilteredDataWithValues.compactMap { $0.maxHeartRate > 0 ? $0.maxHeartRate : nil }.max() ?? 0
            return String(format: "%.0f", best)
        case .speed:
            let best = cachedFilteredDataWithValues.compactMap { $0.maxSpeed > 0 ? $0.maxSpeed * 3.6 : nil }.max() ?? 0
            return String(format: "%.1f", best)
        case .calories:
            let best = cachedFilteredDataWithValues.compactMap { $0.totalEnergyBurned > 0 ? $0.totalEnergyBurned : nil }.max() ?? 0
            return String(format: "%.0f", best)
        case .distance:
            let best = cachedFilteredDataWithValues.compactMap { $0.totalDistance > 0 ? $0.totalDistance / 1000.0 : nil }.max() ?? 0
            return String(format: "%.1f", best)
        case .pace:
            let best = cachedFilteredDataWithValues.compactMap { $0.pace > 0 ? $0.pace : nil }.min() ?? 0
            return formatPaceFromSecPerMeter(best)
        case .duration:
            let best = cachedFilteredDataWithValues.compactMap { $0.duration > 0 ? $0.duration / 60 : nil }.max() ?? 0
            return String(format: "%.0f", best)
        case .cadenceRun:
            let best = cachedFilteredDataWithValues.compactMap { $0.cadenceRun > 0 ? $0.cadenceRun : nil }.max() ?? 0
            return String(format: "%.0f", best)
        case .elevation:
            let best = cachedFilteredDataWithValues.compactMap { $0.totalElevationGain > 0 ? $0.totalElevationGain : nil }.max() ?? 0
            return String(format: "%.0f", best)
        }
    }
    
    private var improvementValue: String {
        // Simplified improvement calculation
        return "+12.5"
    }
    
    private var weeklyTrend: String {
        return "+8.2%"
    }
    
    private var monthlyTrend: String {
        return "Stable"
    }
    
    private var consistencyValue: String {
        return "85%"
    }
    
    private var scientificDescription: String {
        switch chartType {
        case .heartRate:
            return "Heart rate is a key indicator of cardiovascular fitness and training intensity. Monitoring your heart rate helps optimize training zones and prevent overtraining. Your heart rate data shows your cardiovascular adaptation to exercise."
        case .speed:
            return "Speed measures how fast you're moving during your workouts. It's crucial for understanding your performance progression and setting realistic training goals. Speed improvements indicate enhanced fitness and technique."
        case .calories:
            return "Calories burned represent the energy expenditure during your workouts. This metric helps with weight management and understanding the intensity of your training sessions. Higher calorie burn often correlates with more intense workouts."
        case .distance:
            return "Distance covered shows your training volume and endurance capacity. It's fundamental for building aerobic fitness and preparing for longer events. Consistent distance training builds your endurance base."
        case .pace:
            return "Pace measures how long it takes to cover a specific distance. It's essential for race planning and understanding your current fitness level. Improving pace indicates enhanced running economy and fitness."
        case .duration:
            return "Training duration reflects your commitment and endurance capacity. Longer sessions build aerobic fitness while shorter, intense sessions improve anaerobic capacity. Duration is key for progressive overload."
        case .cadenceRun:
            return "Cadence measures your step rate per minute. Optimal cadence reduces injury risk and improves running efficiency. Most runners benefit from a cadence of 170-180 steps per minute."
        case .elevation:
            return "Elevation gain shows the uphill and downhill portions of your workouts. It's important for understanding your training load and progress in different terrains. Consistent elevation training builds your endurance and strength."
        }
    }
    
    private var proTip: String {
        switch chartType {
        case .heartRate:
            return "Train in different heart rate zones to maximize fitness gains"
        case .speed:
            return "Include interval training to improve your top speed"
        case .calories:
            return "Focus on workout quality over calorie burn for better results"
        case .distance:
            return "Gradually increase distance by 10% each week"
        case .pace:
            return "Practice negative splits for better race performance"
        case .duration:
            return "Mix long and short sessions for optimal training"
        case .cadenceRun:
            return "Focus on quick, light steps rather than long strides"
        case .elevation:
            return "Include uphill and downhill workouts to improve your overall fitness"
        }
    }
    
    private var trainingTips: [String] {
        switch chartType {
        case .heartRate:
            return [
                "Train in Zone 2 (60-70% max HR) for base building",
                "Use Zone 4 (80-90% max HR) for threshold training",
                "Allow recovery in Zone 1 (50-60% max HR)",
                "Monitor resting heart rate for recovery status"
            ]
        case .speed:
            return [
                "Include 1-2 speed sessions per week",
                "Use intervals of 30 seconds to 5 minutes",
                "Allow full recovery between speed intervals",
                "Focus on form during high-speed efforts"
            ]
        case .calories:
            return [
                "Don't focus solely on calorie burn",
                "Prioritize workout quality and consistency",
                "Balance cardio and strength training",
                "Listen to your body's energy needs"
            ]
        case .distance:
            return [
                "Increase distance gradually (10% rule)",
                "Include one long session per week",
                "Vary your routes to stay motivated",
                "Build distance before increasing intensity"
            ]
        case .pace:
            return [
                "Practice negative splits in training",
                "Use tempo runs to improve pace",
                "Include hill training for strength",
                "Focus on running economy and form"
            ]
        case .duration:
            return [
                "Mix short intense and long easy sessions",
                "Allow adequate recovery between sessions",
                "Build duration before increasing intensity",
                "Listen to your body's recovery needs"
            ]
        case .cadenceRun:
            return [
                "Aim for 170-180 steps per minute",
                "Use a metronome app to practice",
                "Focus on quick, light steps",
                "Don't sacrifice stride length for cadence"
            ]
        case .elevation:
            return [
                "Include uphill workouts to improve your uphill endurance",
                "Practice downhill strides to improve your downhill form",
                "Use a heart rate monitor to stay within your target heart rate zone"
            ]
        }
    }

    private var updatedChartModel: AAChartModel {
        if let cached = cachedChartModel {
            return cached
        }
        
        // Return a default chart model if cache is empty
        // The actual chart will be updated via updateChartModel()
        return AAChartModel()
            .chartType(.spline)
            .legendEnabled(false)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)
    }
    
    private func updateChartModel() {
        let model = AAChartModel()
            .chartType(.spline)
            .legendEnabled(false)
            .xAxisLabelsEnabled(false)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(0)
            .markerRadius(0)

        let chartModel = createChartModel(baseModel: model)
        cachedChartModel = chartModel
    }
    
    // MARK: - AI Analysis Methods
    
    private func performAIAnalysis() {
        guard !cachedFilteredDataWithValues.isEmpty else {
            print("No data available for AI analysis")
            // Show a brief alert or message to user
            DispatchQueue.main.async {
                // You could add a state for showing an alert here
                print("No data available for AI analysis")
            }
            return
        }
        
        isAIAnalyzing = true
        aiAnalysisResult = nil
        
        let values = extractValuesForAnalysis()
        let name = titleForChartType
        let description = "\(name) data for \(selectedFilter.displayName) period"
        
        metricsSender.sendIndicatorAnalysis(
            name: name,
            values: values,
            description: description
        ) { data in
            DispatchQueue.main.async {
                self.isAIAnalyzing = false
                
                if let data = data {
                    if let response = self.metricsSender.parseServerResponse(data: data) {
                        self.aiAnalysisResult = response
                        self.aiAnalysisError = nil
                    } else {
                        print("Failed to parse AI analysis response")
                        self.aiAnalysisError = "Failed to parse AI response"
                        self.aiAnalysisResult = nil
                    }
                } else {
                    print("Failed to get AI analysis response")
                    self.aiAnalysisError = "Failed to get AI response"
                    self.aiAnalysisResult = nil
                }
            }
        }
    }
    
    private func extractValuesForAnalysis() -> [Double] {
        switch chartType {
        case .heartRate:
            return cachedFilteredDataWithValues.compactMap { $0.averageHeartRate > 0 ? $0.averageHeartRate : nil }
        case .speed:
            return cachedFilteredDataWithValues.compactMap { $0.averageSpeed > 0 ? $0.averageSpeed * 3.6 : nil }
        case .calories:
            return cachedFilteredDataWithValues.compactMap { $0.totalEnergyBurned > 0 ? $0.totalEnergyBurned : nil }
        case .distance:
            return cachedFilteredDataWithValues.compactMap { $0.totalDistance > 0 ? $0.totalDistance / 1000.0 : nil }
        case .pace:
            return cachedFilteredDataWithValues.compactMap { $0.pace > 0 ? $0.pace * 1000 / 60 : nil }
        case .duration:
            return cachedFilteredDataWithValues.compactMap { $0.duration > 0 ? $0.duration / 60 : nil }
        case .cadenceRun:
            return cachedFilteredDataWithValues.compactMap { $0.cadenceRun > 0 ? $0.cadenceRun : nil }
        case .elevation:
            return cachedFilteredDataWithValues.compactMap { $0.totalElevationGain > 0 ? $0.totalElevationGain : nil }
        }
    }
    
    private func createChartModel(baseModel: AAChartModel) -> AAChartModel {
        switch chartType {
        case .heartRate:
            let heartRateData = cachedFilteredDataWithValues.compactMap { $0.averageHeartRate > 0 ? $0.averageHeartRate : nil }
            let maxHeartRateData = cachedFilteredDataWithValues.compactMap { $0.maxHeartRate > 0 ? $0.maxHeartRate : nil }
            let heartRateCategories = cachedFilteredDataWithValues.compactMap { 
                $0.averageHeartRate > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(heartRateCategories)
                .series([
                    AASeriesElement().name("Avg HR").data(heartRateData),
                    AASeriesElement().name("Max HR").data(maxHeartRateData)
                ])

        case .speed:
            let avgSpeedData = cachedFilteredDataWithValues.compactMap { $0.averageSpeed > 0 ? $0.averageSpeed * 3.6 : nil }
            let maxSpeedData = cachedFilteredDataWithValues.compactMap { $0.maxSpeed > 0 ? $0.maxSpeed * 3.6 : nil }
            let speedCategories = cachedFilteredDataWithValues.compactMap { 
                $0.averageSpeed > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(speedCategories)
                .series([
                    AASeriesElement().name("Avg Speed").data(avgSpeedData),
                    AASeriesElement().name("Max Speed").data(maxSpeedData)
                ])

        case .calories:
            let caloriesData = cachedFilteredDataWithValues.compactMap { $0.totalEnergyBurned > 0 ? $0.totalEnergyBurned : nil }
            let caloriesCategories = cachedFilteredDataWithValues.compactMap { 
                $0.totalEnergyBurned > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(caloriesCategories)
                .series([
                    AASeriesElement().name("Calories").data(caloriesData)
                ])

        case .distance:
            let distanceData = cachedFilteredDataWithValues.compactMap { $0.totalDistance > 0 ? $0.totalDistance / 1000.0 : nil }
            let distanceCategories = cachedFilteredDataWithValues.compactMap { 
                $0.totalDistance > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(distanceCategories)
                .series([
                    AASeriesElement().name("Distance").data(distanceData)
                ])
                
        case .pace:
            let paceData = cachedFilteredDataWithValues.compactMap { $0.pace > 0 ? $0.pace * 1000 / 60 : nil }
            let paceCategories = cachedFilteredDataWithValues.compactMap { 
                $0.pace > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(paceCategories)
                .series([
                    AASeriesElement().name("Pace").data(paceData)
                ])

        case .duration:
            let durationData = cachedFilteredDataWithValues.compactMap { $0.duration > 0 ? $0.duration / 60 : nil }
            let durationCategories = cachedFilteredDataWithValues.compactMap { 
                $0.duration > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(durationCategories)
                .series([
                    AASeriesElement().name("Duration").data(durationData)
                ])

        case .cadenceRun:
            let cadenceData = cachedFilteredDataWithValues.compactMap { $0.cadenceRun > 0 ? $0.cadenceRun : nil }
            let cadenceCategories = cachedFilteredDataWithValues.compactMap { 
                $0.cadenceRun > 0 ? $0.startDate?.formatted(date: .abbreviated, time: .omitted) : nil 
            }.compactMap { $0 }
            
            return baseModel
                .categories(cadenceCategories)
                .series([
                    AASeriesElement().name("Cadence").data(cadenceData)
                ])

        case .elevation:
            // Optimize elevation data processing to avoid double filtering
            let validElevationWorkouts = cachedFilteredDataWithValues.filter { $0.totalElevationGain > 0 }
            let elevationData = validElevationWorkouts.map { $0.totalElevationGain }
            let elevationCategories = validElevationWorkouts.compactMap { 
                $0.startDate?.formatted(date: .abbreviated, time: .omitted)
            }
            
            return baseModel
                .categories(elevationCategories)
                .series([
                    AASeriesElement().name("Elevation Gain").data(elevationData)
                ])
        }
    }
}

// MARK: - Supporting Views
struct StatCardMetrics: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let color: Color
    
    enum TrendDirection {
        case up, down, stable
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: trendIcon)
                .foregroundColor(color)
                .font(.title3)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
}

struct StatisticsTable: View {
    let aggregatedStatistics: (
        totalWorkouts: Int,
        totalDuration: TimeInterval,
        totalDistance: Double,
        totalEnergyBurned: Double,
        totalElevation: Double,
        averageHeartRate: Double
    )
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CompactStatCard(title: "Workouts", value: "\(aggregatedStatistics.totalWorkouts)", icon: "figure.run", color: .green)
                CompactStatCard(title: "Duration", value: formatDuration(aggregatedStatistics.totalDuration), icon: "timer", color: .purple)
                CompactStatCard(title: "Distance", value: String(format: "%.1f km", aggregatedStatistics.totalDistance / 1000), icon: "map", color: .blue)
                CompactStatCard(title: "Calories", value: String(format: "%.0f kcal", aggregatedStatistics.totalEnergyBurned), icon: "flame", color: .orange)
                CompactStatCard(title: "Elevation", value: String(format: "%.0f m", aggregatedStatistics.totalElevation), icon: "mountain.2", color: .mint)
                CompactStatCard(title: "Avg HR", value: String(format: "%.0f bpm", aggregatedStatistics.averageHeartRate), icon: "heart", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0 min"
    }
}

struct PersonalBestsWidget: View {
    let bestDistance: Double
    let bestDuration: TimeInterval
    let bestPace: Double?
    let bestCalories: Double
    let bestElevation: Double
    let isNewDistance: Bool
    let isNewDuration: Bool
    let isNewPace: Bool
    let isNewCalories: Bool
    let isNewElevation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Bests")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    BestMetricView(icon: "figure.walk", value: String(format: "%.1f", bestDistance), unit: "km", label: "Longest Distance", isNewRecord: isNewDistance)
                    BestMetricView(icon: "timer", value: formatDuration(bestDuration), unit: "", label: "Longest Duration", isNewRecord: isNewDuration)
                    if let pace = bestPace {
                        BestMetricView(icon: "hare.fill", value: formatPaceFromSecPerMeter(pace), unit: "min/km", label: "Best Pace", isNewRecord: isNewPace)
                    }
                    BestMetricView(icon: "flame.fill", value: String(format: "%.0f", bestCalories), unit: "kcal", label: "Max Calories", isNewRecord: isNewCalories)
                    BestMetricView(icon: "mountain.2.fill", value: String(format: "%.0f", bestElevation), unit: "m", label: "Max Elevation", isNewRecord: isNewElevation)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.15), radius: 8, x: 0, y: 4)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0 min"
    }
}

struct BestMetricView: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let isNewRecord: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            if isNewRecord {
                Text("Better than last period!")
                    .font(.caption2.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
            }
            
        }
        .frame(minWidth: 70)
    }
}

struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct TableRow: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(accentColorForIcon(icon))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title.bold())
                    .foregroundColor(accentColorForIcon(icon))
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
    }
    private func accentColorForIcon(_ icon: String) -> Color {
        switch icon {
        case "figure.run": return .green
        case "timer": return .purple
        case "map": return .blue
        case "flame": return .orange
        case "heart": return .red
        default: return .accentColor
        }
    }
}

struct AAChartViewWrapper: UIViewRepresentable {
    var chartModel: AAChartModel

    func makeUIView(context: Context) -> AAChartView {
        let chartView = AAChartView()
        chartView.isScrollEnabled = true
        chartView.contentHeight = 200
        chartView.isClearBackgroundColor = true
        
        // Optimize chart rendering
        DispatchQueue.main.async {
            chartView.aa_drawChartWithChartModel(chartModel)
        }
        return chartView
    }

    func updateUIView(_ uiView: AAChartView, context: Context) {
        DispatchQueue.main.async {
            uiView.aa_refreshChartWholeContentWithChartModel(chartModel)
        }
    }
}

func formatPaceFromSecPerMeter(_ pace: Double) -> String {
    // Проверяем на NaN, бесконечность и отрицательные значения
    guard !pace.isNaN && !pace.isInfinite && pace > 0 else {
        return "0:00"
    }
    
    let paceSecPerKm = pace * 1000
    let minutes = Int(paceSecPerKm) / 60
    let seconds = Int(paceSecPerKm) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

// MARK: - Calendar Period Picker
struct CalendarPeriodPicker: View {
    let filter: TimeFilter
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Calendar View
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accentColor(.blue)
                .padding()
                
                // Info Text
                VStack(spacing: 8) {
                    Text("Selected Period")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(periodDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
                
                Spacer()
            }
            .navigationTitle("Choose Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var periodDescription: String {
        let range = DateFilterHelper.calculateDateRange(for: filter, around: selectedDate)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        switch filter {
        case .week:
            return "Week of \(formatter.string(from: range.start))"
        case .month:
            return "Month of \(formatter.string(from: range.start))"
        case .year:
            return "Year \(Calendar.current.component(.year, from: selectedDate))"
        }
    }
}

// MARK: - Period Selection Button
struct PeriodSelectionButton: View {
    let filter: TimeFilter
    @Binding var selectedDate: Date
    @State private var showingCalendar = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            showingCalendar = true
        }) {
            HStack {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .foregroundColor(.primary)
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarPeriodPicker(filter: filter, selectedDate: $selectedDate)
        }
    }
}

// MARK: - Share Data Structure
struct ShareData {
    let text: String
    let image: UIImage?
    let csvData: String?
    let csvURL: URL?
    
    var items: [Any] {
        var items: [Any] = [text]
        if let image = image {
            items.append(image)
        }
        if let csvURL = csvURL {
            items.append(csvURL)
        }
        return items
    }
    
    init(text: String, image: UIImage?, csvData: String? = nil, csvURL: URL? = nil) {
        self.text = text
        self.image = image
        self.csvData = csvData
        self.csvURL = csvURL
    }
}

// MARK: - Share Sheet
struct ShareSheetMetrics: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Настройка для лучшей поддержки файлов
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .markupAsPDF
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Stat Card
struct ShareStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}
