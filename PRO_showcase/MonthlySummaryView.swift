import SwiftUI
import AAInfographics
import CoreData

@available(iOS 16.0, *)
struct MonthlySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let showCloseButton: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutEntity.startDate, ascending: true)],
        animation: .default
    )
    private var workouts: FetchedResults<WorkoutEntity>
    
    @State private var selectedMonth: Date = Date()
    @State private var showingShareSheet = false
    @State private var shareData: ShareData?
    
    init(showCloseButton: Bool = true) {
        self.showCloseButton = showCloseButton
    }
    
    private var currentMonthWorkouts: [WorkoutEntity] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        return workouts.filter {
            guard let startDate = $0.startDate else { return false }
            return startDate >= startOfMonth && startDate < endOfMonth
        }
    }
    
    private var previousMonthWorkouts: [WorkoutEntity] {
        let calendar = Calendar.current
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        let startOfMonth = calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: previousMonth)?.end ?? previousMonth
        
        return workouts.filter {
            guard let startDate = $0.startDate else { return false }
            return startDate >= startOfMonth && startDate < endOfMonth
        }
    }
    
    private var sportTypeDistribution: [(sport: SportType, count: Int, percentage: Double)] {
        let totalWorkouts = currentMonthWorkouts.count
        guard totalWorkouts > 0 else { return [] }
        
        let grouped = Dictionary(grouping: currentMonthWorkouts) { workout in
            SportType(rawValue: workout.workoutType ?? "running") ?? .running
        }
        
        return grouped.map { (sport, workouts) in
            let count = workouts.count
            let percentage = Double(count) / Double(totalWorkouts) * 100
            return (sport: sport, count: count, percentage: percentage)
        }.sorted { $0.count > $1.count }
    }
    
    private var sportTypeStats: [SportTypeStats] {
        return SportType.allCases.map { sportType in
            let currentWorkouts = currentMonthWorkouts.filter { $0.workoutType == sportType.rawValue }
            let previousWorkouts = previousMonthWorkouts.filter { $0.workoutType == sportType.rawValue }
            
            return SportTypeStats(
                sportType: sportType,
                currentWorkouts: currentWorkouts,
                previousWorkouts: previousWorkouts
            )
        }.filter { $0.currentWorkouts.count > 0 }
    }
    
    private var monthlyRecords: [MonthlyRecord] {
        var records: [MonthlyRecord] = []
        
        // Группируем тренировки по типу спорта
        let workoutsBySport = Dictionary(grouping: currentMonthWorkouts) { workout in
            SportType(rawValue: workout.workoutType ?? "running") ?? .running
        }
        
        // Для каждого типа спорта находим тренировку с максимальной дистанцией
        for (sportType, workouts) in workoutsBySport {
            guard !workouts.isEmpty else { continue }
            
            // Находим тренировку с максимальной дистанцией для данного типа спорта
            let maxDistanceWorkout = workouts.max { $0.totalDistance < $1.totalDistance }
            
            if let recordWorkout = maxDistanceWorkout, recordWorkout.totalDistance > 0 {
                // Проверяем, является ли это рекордом по сравнению с предыдущим месяцем
                let previousWorkouts = previousMonthWorkouts.filter { 
                    SportType(rawValue: $0.workoutType ?? "running") == sportType 
                }
                let previousMaxDistance = previousWorkouts.map { $0.totalDistance }.max() ?? 0
                
                // Если это новый рекорд или первая тренировка такого типа в этом месяце
                if recordWorkout.totalDistance > previousMaxDistance || previousMaxDistance == 0 {
                    records.append(MonthlyRecord(
                        type: .distance,
                        value: recordWorkout.totalDistance / 1000,
                        unit: "km",
                        sport: sportType.rawValue,
                        isNewRecord: recordWorkout.totalDistance > previousMaxDistance && previousMaxDistance > 0
                    ))
                }
            }
        }
        
        return records.sorted { $0.value > $1.value } // Сортируем по убыванию дистанции
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Sport Distribution Chart
                        sportDistributionSection
                        
                        // Monthly Records
                        if !monthlyRecords.isEmpty {
                            monthlyRecordsSection
                        }
                        
                        // Sport Type Statistics
                        sportTypeStatisticsSection
                        
                        // Elevation Summary
                        elevationSummarySection
                        
                        // Monthly Comparison
                        monthlyComparisonSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Monthly Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        prepareShareData()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareData = shareData {
                    ShareSheetMetrics(activityItems: shareData.items, applicationActivities: nil)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                    Text("Training Summary")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    withAnimation {
                        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                        if nextMonth <= Date() {
                            selectedMonth = nextMonth
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(selectedMonth >= Date() ? .secondary : .primary)
                }
                .disabled(selectedMonth >= Date())
            }
            
            // Overview Statistics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                OverviewStatCard(
                    title: "Total Workouts",
                    value: "\(currentMonthWorkouts.count)",
                    icon: "figure.run",
                    color: .green
                )
                OverviewStatCard(
                    title: "Total Distance",
                    value: String(format: "%.1f", currentMonthWorkouts.reduce(0) { $0 + $1.totalDistance } / 1000),
                    unit: "km",
                    icon: "map",
                    color: .blue
                )
                OverviewStatCard(
                    title: "Total Duration",
                    value: formatDuration(currentMonthWorkouts.reduce(0) { $0 + $1.duration }),
                    icon: "timer",
                    color: .purple
                )
                OverviewStatCard(
                    title: "Total Calories",
                    value: String(format: "%.0f", currentMonthWorkouts.reduce(0) { $0 + $1.totalEnergyBurned }),
                    unit: "kcal",
                    icon: "flame",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Sport Distribution Section
    private var sportDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sport Distribution")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            if sportTypeDistribution.isEmpty {
                Text("No workouts this month")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    // Pie Chart
                    AAChartViewWrapper(chartModel: sportDistributionChartModel)
                        .frame(height: 250)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                    
                    // Legend
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(sportTypeDistribution, id: \.sport) { item in
                            HStack {
                                Circle()
                                    .fill(colorForSport(item.sport))
                                    .frame(width: 12, height: 12)
                                Text(item.sport.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Monthly Records Section
    private var monthlyRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Distance Records by Sport")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 12) {
                ForEach(monthlyRecords, id: \.sport) { record in
                    HStack {
                        Image(systemName: iconForRecordType(record.type))
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(record.sport.capitalized) - Longest Distance")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text(record.sport.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.1f", record.value))
                                    .font(.headline.bold())
                                    .foregroundColor(.blue)
                                Text(record.unit)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Best this month")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Sport Type Statistics Section
    private var sportTypeStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sport Performance")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 16) {
                ForEach(sportTypeStats, id: \.sportType) { stats in
                    SportTypeStatCard(stats: stats)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Elevation Summary Section
    private var elevationSummarySection: some View {
        let workoutsWithElevation = currentMonthWorkouts.filter { $0.totalElevationGain > 0 }
        let totalElevationGain = workoutsWithElevation.reduce(0) { $0 + $1.totalElevationGain }
        
        guard totalElevationGain > 0 else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Elevation Summary")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Elevation Gain")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.0f", totalElevationGain))
                                    .font(.title2.bold())
                                    .foregroundColor(.green)
                                Text("m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Workouts with Elevation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(workoutsWithElevation.count)")
                                .font(.title2.bold())
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Elevation comparison with previous month
                    let previousWorkoutsWithElevation = previousMonthWorkouts.filter { $0.totalElevationGain > 0 }
                    let previousTotalElevation = previousWorkoutsWithElevation.reduce(0) { $0 + $1.totalElevationGain }
                    
                    if previousTotalElevation > 0 {
                        HStack {
                            Text("vs Previous Month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: totalElevationGain > previousTotalElevation ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(totalElevationGain > previousTotalElevation ? .green : .red)
                                Text(String(format: "%.1f%%", (totalElevationGain - previousTotalElevation) / previousTotalElevation * 100))
                                    .font(.caption.bold())
                                    .foregroundColor(totalElevationGain > previousTotalElevation ? .green : .red)
                            }
                        }
                    }
                    
                    // Additional elevation stats
                    if let maxElevation = workoutsWithElevation.map({ $0.totalElevationGain }).max() {
                        HStack {
                            Text("Highest Single Workout")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f m", maxElevation))
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Monthly Comparison Section
    private var monthlyComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Comparison")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ComparisonRow(
                    title: "Total Workouts",
                    current: Double(currentMonthWorkouts.count),
                    previous: Double(previousMonthWorkouts.count),
                    unit: ""
                )
                ComparisonRow(
                    title: "Total Distance",
                    current: currentMonthWorkouts.reduce(0) { $0 + $1.totalDistance } / 1000,
                    previous: previousMonthWorkouts.reduce(0) { $0 + $1.totalDistance } / 1000,
                    unit: "km"
                )
                ComparisonRow(
                    title: "Total Duration",
                    current: currentMonthWorkouts.reduce(0) { $0 + $1.duration } / 3600,
                    previous: previousMonthWorkouts.reduce(0) { $0 + $1.duration } / 3600,
                    unit: "hours"
                )
                ComparisonRow(
                    title: "Total Calories",
                    current: currentMonthWorkouts.reduce(0) { $0 + $1.totalEnergyBurned },
                    previous: previousMonthWorkouts.reduce(0) { $0 + $1.totalEnergyBurned },
                    unit: "kcal"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Chart Model
    private var sportDistributionChartModel: AAChartModel {
        let data = sportTypeDistribution.map { item in
            [
                "name": item.sport.rawValue.capitalized,
                "y": item.count,
                "color": colorForSport(item.sport).toHex() ?? "#007AFF"
            ]
        }
        
        return AAChartModel()
            .chartType(.pie)
            .title("")
            .legendEnabled(false)
            .dataLabelsEnabled(true)
            .dataLabelsStyle(AAStyle(color: "#FFFFFF", fontSize: 12, weight: .bold))
            .series([
                AASeriesElement()
                    .name("Workouts")
                    .data(data)
            ])
    }
    
    // MARK: - Helper Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0 min"
    }
    
    private func colorForSport(_ sport: SportType) -> Color {
        switch sport {
        case .running: return .green
        case .cycling: return .blue
        case .walking: return .orange
        case .swimming: return .cyan
        case .hiking: return .brown
//        case .yoga: return .purple
//        case .strength: return .red
        case .other: return .gray
        }
    }
    
    private func iconForRecordType(_ type: MonthlyRecord.RecordType) -> String {
        switch type {
        case .distance: return "figure.walk.motion"
        case .duration: return "timer"
        case .calories: return "flame.fill"
        case .speed: return "speedometer"
        case .elevation: return "figure.walk.motion"
        }
    }
    
    private func recordTypeTitle(_ type: MonthlyRecord.RecordType) -> String {
        switch type {
        case .distance: return "Longest Distance"
        case .duration: return "Longest Duration"
        case .calories: return "Most Calories"
        case .speed: return "Highest Speed"
        case .elevation: return "Highest Elevation Gain"
        }
    }
    
    // MARK: - Share Functionality
    private func prepareShareData() {
        let shareText = generateShareText()
        let shareImage = generateShareImage()
        let csvData = generateCSVData()
        let csvURL = createCSVFile(data: csvData)
        
        shareData = ShareData(
            text: shareText,
            image: shareImage,
            csvData: csvData,
            csvURL: csvURL
        )
        
        showingShareSheet = true
    }
    
    private func createCSVFile(data: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let filename = "monthly_summary_\(formatter.string(from: selectedMonth)).csv"
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        var text = "📊 Monthly Training Summary - \(formatter.string(from: selectedMonth))\n\n"
        
        // Overview
        text += "🏃‍♂️ Overview:\n"
        text += "• Total Workouts: \(currentMonthWorkouts.count)\n"
        text += "• Total Distance: \(String(format: "%.1f km", currentMonthWorkouts.reduce(0) { $0 + $1.totalDistance } / 1000))\n"
        text += "• Total Duration: \(formatDuration(currentMonthWorkouts.reduce(0) { $0 + $1.duration }))\n"
        text += "• Total Calories: \(String(format: "%.0f kcal", currentMonthWorkouts.reduce(0) { $0 + $1.totalEnergyBurned }))\n\n"
        
        // Sport Distribution
        text += "🎯 Sport Distribution:\n"
        for item in sportTypeDistribution {
            text += "• \(item.sport.rawValue.capitalized): \(item.count) workouts (\(String(format: "%.1f", item.percentage))%)\n"
        }
        text += "\n"
        
        // Records
        if !monthlyRecords.isEmpty {
            text += "🏆 Distance Records by Sport:\n"
            for record in monthlyRecords {
                let recordStatus = record.isNewRecord ? " (New Record!)" : " (Best this month)"
                text += "• \(record.sport.capitalized): \(String(format: "%.1f", record.value)) \(record.unit)\(recordStatus)\n"
            }
            text += "\n"
        }
        
        // Elevation Summary
        let workoutsWithElevation = currentMonthWorkouts.filter { $0.totalElevationGain > 0 }
        let totalElevationGain = workoutsWithElevation.reduce(0) { $0 + $1.totalElevationGain }
        if totalElevationGain > 0 {
            text += "🏔 Elevation Summary:\n"
            text += "• Total Elevation Gain: \(String(format: "%.0f m", totalElevationGain))\n"
            text += "• Workouts with Elevation: \(workoutsWithElevation.count)\n\n"
        }
        
        text += "📱 Shared from Fitness Analytics App"
        
        return text
    }
    
    private func generateShareImage() -> UIImage? {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareImageView)
            renderer.scale = 3.0
            return renderer.uiImage
        } else {
            // Fallback for iOS 15 and earlier
            return nil
        }
    }
    
    private func generateCSVData() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var csv = "Date,Sport Type,Duration (min),Distance (km),Calories (kcal),Elevation Gain (m)\n"
        
        for workout in currentMonthWorkouts {
            guard let startDate = workout.startDate else { continue }
            
            let dateString = formatter.string(from: startDate)
            let sportType = workout.workoutType ?? "Unknown"
            let duration = String(format: "%.0f", workout.duration / 60)
            let distance = String(format: "%.3f", workout.totalDistance / 1000.0)
            let calories = String(format: "%.0f", workout.totalEnergyBurned)
            let elevation = String(format: "%.0f", workout.totalElevationGain)
            
            csv += "\(dateString),\(sportType),\(duration),\(distance),\(calories),\(elevation)\n"
        }
        
        return csv
    }
    
    private var shareImageView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Summary")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Overview Statistics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ShareStatCard(title: "Workouts", value: "\(currentMonthWorkouts.count)", unit: "", color: .green)
                ShareStatCard(title: "Distance", value: String(format: "%.1f", currentMonthWorkouts.reduce(0) { $0 + $1.totalDistance } / 1000), unit: "km", color: .blue)
                ShareStatCard(title: "Duration", value: formatDuration(currentMonthWorkouts.reduce(0) { $0 + $1.duration }), unit: "", color: .purple)
                ShareStatCard(title: "Calories", value: String(format: "%.0f", currentMonthWorkouts.reduce(0) { $0 + $1.totalEnergyBurned }), unit: "kcal", color: .orange)
            }
            
            // Sport Distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("Sport Distribution")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ForEach(sportTypeDistribution.prefix(3), id: \.sport) { item in
                    HStack {
                        Circle()
                            .fill(colorForSport(item.sport))
                            .frame(width: 8, height: 8)
                        Text(item.sport.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(item.count) (\(String(format: "%.0f", item.percentage))%)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
        .frame(width: 400, height: 600)
    }
}

// MARK: - Supporting Structures
struct SportTypeStats {
    let sportType: SportType
    let currentWorkouts: [WorkoutEntity]
    let previousWorkouts: [WorkoutEntity]
    
    var currentDistance: Double {
        currentWorkouts.reduce(0) { $0 + $1.totalDistance }
    }
    
    var currentDuration: TimeInterval {
        currentWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    var currentCalories: Double {
        currentWorkouts.reduce(0) { $0 + $1.totalEnergyBurned }
    }
    
    var currentElevation: Double {
        currentWorkouts.reduce(0) { $0 + $1.totalElevationGain }
    }
    
    var previousDistance: Double {
        previousWorkouts.reduce(0) { $0 + $1.totalDistance }
    }
    
    var previousDuration: TimeInterval {
        previousWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    var previousCalories: Double {
        previousWorkouts.reduce(0) { $0 + $1.totalEnergyBurned }
    }
    
    var previousElevation: Double {
        previousWorkouts.reduce(0) { $0 + $1.totalElevationGain }
    }
    
    var distanceChange: Double {
        guard previousDistance > 0 else { return 0 }
        return (currentDistance - previousDistance) / previousDistance * 100
    }
    
    var durationChange: Double {
        guard previousDuration > 0 else { return 0 }
        return (currentDuration - previousDuration) / previousDuration * 100
    }
    
    var caloriesChange: Double {
        guard previousCalories > 0 else { return 0 }
        return (currentCalories - previousCalories) / previousCalories * 100
    }
    
    var elevationChange: Double {
        guard previousElevation > 0 else { return 0 }
        return (currentElevation - previousElevation) / previousElevation * 100
    }
}

struct MonthlyRecord {
    enum RecordType {
        case distance, duration, calories, speed, elevation
    }
    
    let type: RecordType
    let value: Double
    let unit: String
    let sport: String
    let isNewRecord: Bool
}

// MARK: - Overview Stat Card
struct OverviewStatCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, unit: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    if let unit = unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views


struct SportTypeStatCard: View {
    let stats: SportTypeStats
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForSport(stats.sportType))
                    .font(.title2)
                    .foregroundColor(colorForSport(stats.sportType))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(stats.sportType.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(stats.currentWorkouts.count) workouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatRow(
                    title: "Distance",
                    value: String(format: "%.1f", stats.currentDistance / 1000),
                    unit: "km",
                    change: stats.distanceChange
                )
                StatRow(
                    title: "Duration",
                    value: formatDuration(stats.currentDuration),
                    unit: "",
                    change: stats.durationChange
                )
                StatRow(
                    title: "Calories",
                    value: String(format: "%.0f", stats.currentCalories),
                    unit: "kcal",
                    change: stats.caloriesChange
                )
                StatRow(
                    title: "Elevation",
                    value: String(format: "%.0f", stats.currentElevation),
                    unit: "m",
                    change: stats.elevationChange
                )
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
    
    private func iconForSport(_ sport: SportType) -> String {
        switch sport {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "mountain.2"
//        case .yoga: return "figure.mind.and.body"
//        case .strength: return "dumbbell.fill"
        case .other: return "figure.mixed.cardio"
        }
    }
    
    private func colorForSport(_ sport: SportType) -> Color {
        switch sport {
        case .running: return .green
        case .cycling: return .blue
        case .walking: return .orange
        case .swimming: return .cyan
        case .hiking: return .brown
//        case .yoga: return .purple
//        case .strength: return .red
        case .other: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0 min"
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let unit: String
    let change: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if change != 0 {
                HStack(spacing: 2) {
                    Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(change > 0 ? .green : .red)
                    Text(String(format: "%.1f%%", abs(change)))
                        .font(.caption2.bold())
                        .foregroundColor(change > 0 ? .green : .red)
                }
            }
        }
    }
}

struct ComparisonRow: View {
    let title: String
    let current: Double
    let previous: Double
    let unit: String
    
    private var change: Double {
        guard previous > 0 else { return 0 }
        return (current - previous) / previous * 100
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", current))
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if change != 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: change > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(change > 0 ? .green : .red)
                        Text(String(format: "%.1f%%", abs(change)))
                            .font(.subheadline.bold())
                            .foregroundColor(change > 0 ? .green : .red)
                    }
                    Text("vs previous")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - WorkoutEntity Extension for Elevation Calculation
extension WorkoutEntity {
    var totalElevationGain: Double {
        // Ensure we're on the main thread for Core Data access
        guard Thread.isMainThread else {
            // If not on main thread, return 0 to avoid crashes
            return 0
        }
        
        guard let routePoints = routePoints,
              let routePointsArray = routePoints.allObjects as? [RoutePointEntity] else { return 0 }
        
        let sortedPoints = routePointsArray.sorted { 
            guard let timestamp1 = $0.timestamp, let timestamp2 = $1.timestamp else { return false }
            return timestamp1 < timestamp2 
        }
        
        var totalElevationGain: Double = 0
        var previousAltitude: Double?
        
        for point in sortedPoints {
            let currentAltitude = point.altitude
            
            if let previous = previousAltitude {
                let elevationChange = currentAltitude - previous
                if elevationChange > 0 { // Только подъемы, игнорируем спуски
                    totalElevationGain += elevationChange
                }
            }
            
            previousAltitude = currentAltitude
        }
        
        return totalElevationGain
    }
    
    var maxElevation: Double {
        // Ensure we're on the main thread for Core Data access
        guard Thread.isMainThread else {
            return 0
        }
        
        guard let routePoints = routePoints,
              let routePointsArray = routePoints.allObjects as? [RoutePointEntity] else { return 0 }
        return routePointsArray.map { $0.altitude }.max() ?? 0
    }
    
    var minElevation: Double {
        // Ensure we're on the main thread for Core Data access
        guard Thread.isMainThread else {
            return 0
        }
        
        guard let routePoints = routePoints,
              let routePointsArray = routePoints.allObjects as? [RoutePointEntity] else { return 0 }
        return routePointsArray.map { $0.altitude }.min() ?? 0
    }
    
    var elevationRange: Double {
        return maxElevation - minElevation
    }
}


