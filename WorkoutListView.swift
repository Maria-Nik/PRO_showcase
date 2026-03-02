//
//  ContentView.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import SwiftUI
import HealthKit
import CoreData

// --- Новый компонент фильтров ---
struct WorkoutFilterTabs: View {
    let filters: [String]
    @Binding var selected: String?
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        selected = (filter == "All") ? nil : filter
                    }) {
                        Text(filter)
                            .font(.headline)
                            .foregroundColor(selected == filter || (filter == "All" && selected == nil) ? .white : .primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(selected == filter || (filter == "All" && selected == nil) ? Color.blue : Color(.tertiarySystemBackground))
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
    }
}

// --- Новый минималистичный WorkoutCardView ---
struct WorkoutCardView: View {
    let workout: WorkoutEntity
    var onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Цветная иконка спорта
                Image(systemName: iconForSport(workout.workoutType))
                    .font(.title3)
                    .foregroundColor(colorForSport(workout.workoutType))

                // Основная информация
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.workoutType ?? "Workout")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(formattedDate(workout.startDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Метрики
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(workout.totalDistanceKm, specifier: "%.2f") km")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("\(workout.totalEnergyBurned, specifier: "%.0f") kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                Color(.secondarySystemBackground)
                    .opacity(colorScheme == .dark ? 0.7 : 1.0)
            )
            .cornerRadius(14)
            .shadow(
                color: colorScheme == .light ? Color.black.opacity(0.04) : .clear,
                radius: 6, x: 0, y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForSport(_ type: String?) -> String {
        switch type?.lowercased() {
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "swimming": return "drop.fill"
        case "walking": return "figure.walk"
        default: return "figure.walk"
        }
    }
    private func colorForSport(_ type: String?) -> Color {
        switch type?.lowercased() {
        case "running": return .green
        case "cycling": return .blue
        case "swimming": return .teal
        case "walking": return .orange
        default: return .gray
        }
    }
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct WorkoutListView: View {
    @StateObject private var workoutRepo = WorkoutRepository.shared
    @StateObject private var importVM = WorkoutImportViewModel()
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isLoading = false
    @State private var selectedWorkout: WorkoutEntity?
    @State private var isAuthorized = false
    @State private var showAuthorizationAlert = false
    @State private var isFirstLaunch = true
    @StateObject private var viewModel = WorkoutImportViewModel()
    @State private var selectedSportFilter: String? = nil
    @State private var cachedGroupedWorkouts: [(month: String, workouts: [WorkoutEntity])] = []
    @State private var isCalculatingGroups = false
    @State private var isLoadingWorkoutDetails = false
    @State private var workoutToLoad: WorkoutEntity?
    @State private var loadingProgress: Double = 0.0
    @State private var backgroundImportInProgress = false
    @State private var showSyncNotification = false
    @State private var isSyncing = false
    @State private var isProcessingSync = false
    @State private var notificationObserversSetup = false
    @State private var lastSyncNotificationTime: Date?
    @State private var isProcessingAfterPermissionGrant = false
    @State private var processingProgress: Double = 0.0
    @State private var processingMessage: String = ""
    @State private var previousHealthKitStatus: PermissionStatus = .notDetermined
    let sportFilters = ["Running", "Cycling", "Swimming", "All"]
    private let healthStore = HKHealthStore()

    var body: some View {
        NavigationView {
            ZStack {
                
                
                VStack(spacing: 0) {
                    // Header with filters
                    headerSection
                    
                    // Content
                    if shouldShowLoadingView {
                        loadingView
                    } else if groupedWorkouts.isEmpty {
                        emptyStateView
                    } else {
                        workoutList
                    }
                }
                
                // Sync notification overlay
                if showSyncNotification {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("New workouts synced from Apple Health")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    .animation(.easeInOut(duration: 0.3), value: showSyncNotification)
                }
                
                // Syncing overlay
                if isSyncing {
                    VStack {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Syncing workouts from Apple Health...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    .animation(.easeInOut(duration: 0.3), value: isSyncing)
                }
                
                // Processing overlay - shown when processing workouts after permission grant
                if isProcessingAfterPermissionGrant {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView(value: processingProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(width: 250)
                            
                            Text(processingMessage)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("\(Int(processingProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Custom title with permission indicator
                    HStack(spacing: 8) {
                        Text("Workouts")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Permission indicator - show if HealthKit is not authorized
                        if permissionManager.healthKitStatus != .authorized {
                            Button(action: {
                                PermissionMessageHelper.showPermissionAlert(
                                    permissionType: .healthKit,
                                    featureName: "Workouts"
                                )
                            }) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Manual sync button (Import from Health)
                        Button(action: {
                            // Check permissions before syncing
                            if permissionManager.healthKitStatus != .authorized {
                                PermissionMessageHelper.showPermissionAlert(
                                    permissionType: .healthKit,
                                    featureName: "Import from Health"
                                )
                            } else {
                                Task {
                                    await manualSyncWorkouts()
                                }
                            }
                        }) {
                            Image(systemName: "icloud.and.arrow.down")
                        }
                        .onLongPressGesture {
                            // Check permissions before force sync
                            if permissionManager.healthKitStatus != .authorized {
                                PermissionMessageHelper.showPermissionAlert(
                                    permissionType: .healthKit,
                                    featureName: "Import from Health"
                                )
                            } else {
                                Task {
                                    await forceFullSync()
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            handleFirstLaunch()
            setupNotificationObserver()
            // Check permissions when view appears (but don't auto-process)
            Task {
                await permissionManager.checkCurrentPermissions()
            }
            // Note: Sync is now handled centrally by DataProcessingManager
            // No need to check for new workouts here to avoid duplication
        }
        .onDisappear {
            removeNotificationObserver()
        }
        .onChange(of: selectedSportFilter) { oldValue, newValue in
            Task { @MainActor in
                recalculateGroupsAsync()
            }
        }
        .onChange(of: workoutRepo.workouts) { oldValue, newValue in
            Task { @MainActor in
                recalculateGroupsAsync()
            }
        }
        .alert("Access to Apple Health not granted", isPresented: $showAuthorizationAlert) {
            Button("Ok") {}
        } message: {
            Text("Please, allow access to Apple Health in device settings.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var groupedWorkouts: [(month: String, workouts: [WorkoutEntity])] {
        return cachedGroupedWorkouts
    }
    
    // MARK: - Views
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Sport filter tabs
            WorkoutFilterTabs(filters: sportFilters, selected: $selectedSportFilter)
                .padding(.horizontal)
            
            // Sync status indicator
            WorkoutSyncStatusView()
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(groupedWorkouts, id: \.month) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.month)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        LazyVStack(spacing: 12) {
                            ForEach(group.workouts, id: \.uuid) { workout in
                                WorkoutCardView(workout: workout) {
                                    loadWorkoutDetails(workout)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
        .overlay(workoutDetailsLoadingOverlay)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading workouts...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Import your workouts from Apple Health to get started!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Import from Health") {
                // Check permissions before importing
                if permissionManager.healthKitStatus != .authorized {
                    PermissionMessageHelper.showPermissionAlert(
                        permissionType: .healthKit,
                        featureName: "Import from Health"
                    )
                } else {
                    Task {
                        // Use the same sync function as the toolbar button
                        // This will import and process all workouts
                        await manualSyncWorkouts()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Smart Loading Logic
    
    private var shouldShowLoadingView: Bool {
        // Показываем загрузку только если:
        // 1. Нет тренировок И идет фоновый импорт
        // 2. Или это первый запуск и еще не загрузили данные
        return (workoutRepo.workouts.isEmpty && backgroundImportInProgress) || 
               (isFirstLaunch && workoutRepo.workouts.isEmpty)
    }
    
    // MARK: - Loading Overlay
    
    private var workoutDetailsLoadingOverlay: some View {
        Group {
            if isLoadingWorkoutDetails {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Loading workout details...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ProgressView(value: loadingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                        
                        Text("\(Int(loadingProgress * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }
        }
    }

    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d ч %d мин", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d мин %d сек", minutes, seconds)
        } else {
            return String(format: "%d сек", seconds)
        }
    }

    private func groupedWorkouts(_ workouts: [WorkoutEntity]) -> [(month: String, workouts: [WorkoutEntity])] {
        // Проверяем, что тренировки не пустые
        guard !workouts.isEmpty else {
            print("📊 Нет тренировок для группировки")
            return []
        }
        
        // Фильтруем только валидные тренировки
        let validWorkouts = workouts.filter { workout in
            workout.startDate != nil && workout.workoutType != nil
        }
        
        if validWorkouts.count != workouts.count {
            print("⚠️ Отфильтровано \(workouts.count - validWorkouts.count) некорректных тренировок")
        }
        
        let sortedWorkouts = sortedByDate(validWorkouts)
        let groupedByMonth = groupByMonth(sortedWorkouts)
        return sortMonthsChronologically(groupedByMonth)
    }


    // MARK: - Workout Processing Utilities
    
    nonisolated private func sortedByDate(_ workouts: [WorkoutEntity]) -> [WorkoutEntity] {
        return workouts.sorted {
            $0.startDate ?? Date() > $1.startDate ?? Date()
        }
    }

    nonisolated private func groupByMonth(_ workouts: [WorkoutEntity]) -> [String: [WorkoutEntity]] {
        return Dictionary(grouping: workouts) { workout in
            guard let date = workout.startDate else { 
                print("⚠️ Тренировка без даты: \(workout.uuid?.uuidString ?? "unknown")")
                return "Unknown" 
            }
            return formatMonthYear(from: date)
        }
    }

    nonisolated private func sortMonthsChronologically(_ grouped: [String: [WorkoutEntity]]) -> [(month: String, workouts: [WorkoutEntity])] {
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            
            // Безопасное сравнение дат
            guard let date1 = formatter.date(from: key1),
                  let date2 = formatter.date(from: key2) else {
                return key1 > key2 // Fallback для некорректных дат
            }
            
            return date1 > date2
        }
        
        return sortedKeys.compactMap { month in
            guard let workouts = grouped[month] else { return nil }
            return (month: month, workouts: workouts)
        }
    }
    
    nonisolated private func formatMonthYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func filterButton(for sport: String) -> some View {
        Button(action: {
            if sport == "All" {
                selectedSportFilter = nil
            } else {
                selectedSportFilter = sport
            }
        }) {
            Text(sport)
                .padding(8)
                .background(
                    (sport == "All" && selectedSportFilter == nil) || selectedSportFilter == sport
                        ? Color.blue
                        : Color.gray.opacity(0.3)
                )
                .foregroundColor(
                    (sport == "All" && selectedSportFilter == nil) || selectedSportFilter == sport
                        ? .white
                        : .black
                )
                .cornerRadius(8)
        }
    }

    private func workoutText(_ text: String, font: Font, color: Color) -> some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
    }

    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .runningSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingPower)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            completion(success)
        }
    }
    
    // MARK: - Async Grouping
    
    @MainActor
    private func calculateGroupsAsync() {
        guard !isCalculatingGroups else { return }
        
        isCalculatingGroups = true
        
        // Получаем данные до запуска фонового потока
        let workouts = workoutRepo.workouts
        let sportFilter = selectedSportFilter
        
        Task.detached(priority: .userInitiated) {
            // Безопасная фильтрация с проверкой типов
            let filteredWorkouts = sportFilter == nil
                ? workouts
                : workouts.filter { workout in
                    guard let workoutType = workout.workoutType else { return false }
                    return workoutType == sportFilter
                }
            
            // Проверяем, что все тренировки имеют корректные данные
            let validWorkouts = filteredWorkouts.filter { workout in
                workout.startDate != nil && workout.workoutType != nil
            }
            
            // Выполняем группировку в фоновом потоке
            let sortedWorkouts = self.sortedByDate(validWorkouts)
            let groupedByMonth = self.groupByMonth(sortedWorkouts)
            let grouped = self.sortMonthsChronologically(groupedByMonth)
            
            await MainActor.run {
                self.cachedGroupedWorkouts = grouped
                self.isCalculatingGroups = false
                print("📊 Группировка завершена: \(grouped.count) групп, \(validWorkouts.count) тренировок")
            }
        }
    }
    
    @MainActor
    private func recalculateGroupsAsync() {
        cachedGroupedWorkouts = []
        calculateGroupsAsync()
    }

    private func loadWorkoutDetails(_ workout: WorkoutEntity) {
        workoutToLoad = workout
        isLoadingWorkoutDetails = true
        loadingProgress = 0.0
        
        // Асинхронно загружаем детали тренировки
        Task.detached(priority: .userInitiated) {
            // Имитируем прогресс загрузки
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 секунды
                await MainActor.run {
                    self.loadingProgress = Double(i) / 10.0
                }
            }
            
            await MainActor.run {
                self.selectedWorkout = workout
                self.isLoadingWorkoutDetails = false
                self.workoutToLoad = nil
                self.loadingProgress = 0.0
            }
        }
    }

    private func handleFirstLaunch() {
        guard isFirstLaunch else { return }
        isFirstLaunch = false
        
        print("🚀 WorkoutListView: начинаем обработку первого запуска")
        
        // Просто загружаем существующие данные без тяжелых операций
        Task {
            await workoutRepo.fetchWorkouts()
            print("📊 WorkoutListView: загружено \(workoutRepo.workouts.count) тренировок из CoreData")
            
            await MainActor.run {
                self.calculateGroupsAsync()
            }
        }
    }

    private func manualSyncWorkouts() async {
        print("🔄 WorkoutListView: Manual sync triggered")
        
        // Check if this is the first sync (no workouts exist)
        await workoutRepo.fetchWorkouts()
        let existingWorkoutCount = workoutRepo.workouts.count
        let isFirstSync = existingWorkoutCount == 0
        
        if isFirstSync {
            print("📊 First sync detected - will perform full import and processing")
            // Use full processing for first sync
            await processWorkoutsAfterPermissionGrant()
            return
        }
        
        // Set manual sync flag to prevent automatic processing
        await MainActor.run {
            DataProcessingManager.shared.isManualSyncInProgress = true
            self.isSyncing = true
        }
        
        // Post sync started notification
        await MainActor.run {
            NotificationCenter.default.post(name: .workoutSyncStarted, object: nil, userInfo: nil)
        }
        
        // Check authorization
        let authStatus = await checkHealthKitAuthorization()
        await MainActor.run {
            self.isAuthorized = authStatus
        }
        
        guard authStatus else {
            await MainActor.run {
                self.showAuthorizationAlert = true
                self.isSyncing = false
                DataProcessingManager.shared.isManualSyncInProgress = false
            }
            return
        }
        
        do {
            // Fetch workouts from HealthKit with timeout
            let workouts = try await withTimeout(seconds: 30) {
                await fetchWorkoutsFromHealthKit()
            }
            print("📊 WorkoutListView: Manual sync found \(workouts.count) workouts in Apple Health")
            
            // Import new workouts
            await importNewWorkouts(workouts)
            
        } catch {
            print("❌ WorkoutListView: Manual sync error: \(error)")
            await MainActor.run {
                // Show error notification
                self.showSyncNotification = true
                self.isSyncing = false
                DataProcessingManager.shared.isManualSyncInProgress = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showSyncNotification = false
                }
            }
        }
    }
    
    private func forceFullSync() async {
        print("🔄 WorkoutListView: Force full sync triggered")
        
        // Set manual sync flag to prevent automatic processing
        await MainActor.run {
            DataProcessingManager.shared.isManualSyncInProgress = true
            self.isSyncing = true
        }
        
        // Post sync started notification
        await MainActor.run {
            NotificationCenter.default.post(name: .workoutSyncStarted, object: nil, userInfo: nil)
        }
        
        // Check authorization
        let authStatus = await checkHealthKitAuthorization()
        await MainActor.run {
            self.isAuthorized = authStatus
        }
        
        guard authStatus else {
            await MainActor.run {
                self.showAuthorizationAlert = true
                self.isSyncing = false
                DataProcessingManager.shared.isManualSyncInProgress = false
            }
            return
        }
        
        do {
            // Fetch workouts from HealthKit with timeout
            let workouts = try await withTimeout(seconds: 30) {
                await fetchWorkoutsFromHealthKit()
            }
            print("📊 WorkoutListView: Force full sync found \(workouts.count) workouts in Apple Health")
            
            // Import new workouts
            await importNewWorkouts(workouts)
            
        } catch {
            print("❌ WorkoutListView: Force full sync error: \(error)")
            await MainActor.run {
                // Show error notification
                self.showSyncNotification = true
                self.isSyncing = false
                DataProcessingManager.shared.isManualSyncInProgress = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showSyncNotification = false
                }
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {}
    
    private func fetchWorkoutsFromHealthKit() async -> [HKWorkout] {
        return await withCheckedContinuation { continuation in
            HealthKitManager.shared.fetchWorkouts { workouts in
                continuation.resume(returning: workouts)
            }
        }
    }
    
    private func importNewWorkouts(_ workouts: [HKWorkout]) async {
        // Get existing workout UUIDs to avoid duplicates
        let existingUUIDs = await getExistingWorkoutUUIDs()
        let newWorkouts = workouts.filter { !existingUUIDs.contains($0.uuid) }
        
        print("📊 WorkoutListView: Manual sync - \(workouts.count) total workouts, \(existingUUIDs.count) existing, \(newWorkouts.count) new to import")
        
        // Debug: Print the UUIDs of workouts being imported
        if !newWorkouts.isEmpty {
            print("📊 WorkoutListView: New workout UUIDs: \(newWorkouts.map { $0.uuid })")
        }
        
        if newWorkouts.isEmpty {
            print("✅ WorkoutListView: Manual sync - no new workouts to import")
            // Still update sync time even if no new workouts
            await MainActor.run {
                UserDefaults.standard.set(Date(), forKey: "lastSyncDate")
                DataProcessingManager.shared.isManualSyncInProgress = false
                // Post sync completed notification even if no new workouts
                NotificationCenter.default.post(name: .workoutSyncCompleted, object: nil, userInfo: nil)
            }
            return
        }
        
        // Import new workouts using the existing optimized system (silent to avoid duplicate notifications)
        let workoutImport = WorkoutImportViewModel()
        await workoutImport.importWorkoutsInBackgroundSilent(newWorkouts)
        
        // Wait a moment for the import to complete and be saved
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Update repositories after import
        await WorkoutRepository.shared.fetchWorkouts()
        print("📊 WorkoutListView: WorkoutRepository updated after manual sync")
        
        // Process only the new workouts with bonuses and records
        // Use the HKWorkout UUIDs to find the corresponding WorkoutEntities
        await processNewWorkoutsOnly(newWorkouts)
        
        await MainActor.run {
            // Update sync time
            UserDefaults.standard.set(Date(), forKey: "lastSyncDate")
            
            // Recalculate groups
            self.calculateGroupsAsync()
            
            // Refresh streak history to ensure widget shows correct workout day indicators
            if BonusManager.shared.isStreakTrackingEnabled {
                print("🔥 WorkoutListView: Refreshing streak history after manual sync")
                BonusManager.shared.populateStreakHistoryFromExistingWorkouts()
            }
            
            // Clear manual sync flag
            DataProcessingManager.shared.isManualSyncInProgress = false
            
            // Post sync completed notification
            NotificationCenter.default.post(name: .workoutSyncCompleted, object: nil, userInfo: nil)
        }
        
        print("✅ WorkoutListView: Manual sync completed - imported \(newWorkouts.count) workouts")
    }
    
    private func processNewWorkoutsOnly(_ newWorkouts: [HKWorkout]) async {
        print("📊 WorkoutListView: Processing \(newWorkouts.count) new workouts only")
        
        // Convert HKWorkouts to WorkoutEntities for processing
        let workoutEntities = await convertToWorkoutEntities(newWorkouts)
        
        // Use the new method to process only new workouts
        let dataProcessingManager = DataProcessingManager.shared
        await dataProcessingManager.processNewWorkoutsOnly(workoutEntities)
        
        print("📊 WorkoutListView: New workouts processing completed")
    }
    
    private func convertToWorkoutEntities(_ workouts: [HKWorkout]) async -> [WorkoutEntity] {
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        return await context.perform {
            var entities: [WorkoutEntity] = []
            var foundUUIDs = Set<UUID>()
            
            for hkWorkout in workouts {
                // Find the corresponding WorkoutEntity in Core Data
                let request = NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
                request.predicate = NSPredicate(format: "uuid == %@", hkWorkout.uuid as CVarArg)
                
                do {
                    let results = try context.fetch(request)
                    if let workoutEntity = results.first {
                        // Check for duplicates
                        if !foundUUIDs.contains(workoutEntity.uuid ?? UUID()) {
                            entities.append(workoutEntity)
                            foundUUIDs.insert(workoutEntity.uuid ?? UUID())
                        } else {
                            print("⚠️ WorkoutListView: Duplicate workout entity found for UUID: \(workoutEntity.uuid ?? UUID())")
                        }
                    } else {
                        print("⚠️ WorkoutListView: No workout entity found for UUID: \(hkWorkout.uuid)")
                    }
                } catch {
                    print("❌ WorkoutListView: Error finding workout entity: \(error)")
                }
            }
            
            print("📊 WorkoutListView: Converted \(workouts.count) HKWorkouts to \(entities.count) WorkoutEntities")
            return entities
        }
    }
    
    private func getExistingWorkoutUUIDs() async -> Set<UUID> {
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        return await context.perform {
            let request = NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
            
            do {
                let workouts = try context.fetch(request)
                let uuids = workouts.compactMap { workout -> UUID? in
                    return workout.uuid
                }
                
                // Debug: Check for duplicate UUIDs in the database
                let uniqueUUIDs = Set(uuids)
                if uniqueUUIDs.count != uuids.count {
                    print("⚠️ WorkoutListView: Found \(uuids.count - uniqueUUIDs.count) duplicate UUIDs in database")
                }
                
                return uniqueUUIDs
            } catch {
                print("❌ WorkoutListView: Error fetching existing workout UUIDs: \(error)")
                return Set<UUID>()
            }
        }
    }

    private func setupNotificationObserver() {
        // Prevent duplicate setup
        guard !notificationObserversSetup else {
            print("🔧 WorkoutListView: Notification observers already setup, skipping")
            return
        }
        
        print("🔧 WorkoutListView: Setting up notification observers")
        notificationObserversSetup = true
        
        // Listen for background import completion (from onboarding)
        NotificationCenter.default.addObserver(
            forName: .backgroundImportCompleted,
            object: nil,
            queue: .main
        ) { _ in
            print("📊 WorkoutListView: получено уведомление о завершении фоновой загрузки")
            Task { @MainActor in
                await self.workoutRepo.fetchWorkouts()
                
                // Проверяем авторизацию после фоновой загрузки
                let authStatus = await self.checkHealthKitAuthorization()
                self.isAuthorized = authStatus
                print("📊 WorkoutListView: статус авторизации после фоновой загрузки: \(authStatus)")
                self.backgroundImportInProgress = false
                self.calculateGroupsAsync()
            }
        }
        
        // Listen for workout sync completion (from manual sync)
        NotificationCenter.default.addObserver(
            forName: .workoutSyncCompleted,
            object: nil,
            queue: .main
        ) { _ in
            let now = Date()
            print("📊 WorkoutListView: получено уведомление о завершении синхронизации тренировок в \(now)")
            
            Task { @MainActor in
                // Prevent duplicate processing with time-based check
                if let lastTime = self.lastSyncNotificationTime,
                   now.timeIntervalSince(lastTime) < 2.0 {
                    print("⚠️ WorkoutListView: Sync notification received too soon after last one, skipping")
                    return
                }
                
                // Prevent duplicate processing
                guard !self.isProcessingSync else {
                    print("⚠️ WorkoutListView: Sync already being processed, skipping")
                    return
                }
                
                self.lastSyncNotificationTime = now
                self.isProcessingSync = true
                self.isSyncing = false
                
                await self.workoutRepo.fetchWorkouts()
                
                // Recalculate groups with new workouts and show notification
                self.calculateGroupsAsync()
                
                // Process all workouts for streaks to ensure accurate streak counting
                if BonusManager.shared.isStreakTrackingEnabled {
                    print("🔥 WorkoutListView: Processing all workouts for accurate streak tracking after sync")
                    BonusManager.shared.processAllWorkoutsForStreaks()
                }
                
                self.showSyncNotification = true
                self.isProcessingSync = false
                
                // Clear manual sync flag
                DataProcessingManager.shared.isManualSyncInProgress = false
                
                // Hide notification after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showSyncNotification = false
                }
            }
        }
    }

    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: .backgroundImportCompleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .workoutSyncCompleted, object: nil)
    }

    // MARK: - HealthKit Authorization Check
    
    // MARK: - Process Workouts After Permission Grant
    
    private func processWorkoutsAfterPermissionGrant() async {
        // Only process if we're not already processing
        guard !isProcessingAfterPermissionGrant else {
            print("⚠️ Already processing workouts after permission grant")
            return
        }
        
        await MainActor.run {
            isProcessingAfterPermissionGrant = true
            processingProgress = 0.0
            processingMessage = String(localized: "Importing workouts from Apple Health...", comment: "Progress message during Health import")
        }
        
        print("🚀 Starting full workout import and processing after permission grant...")
        
        do {
            // Step 1: Import all workouts from HealthKit (40% of progress)
            await MainActor.run {
                processingProgress = 0.1
                processingMessage = String(localized: "Importing workouts from Apple Health...", comment: "Progress message during Health import")
            }
            
            let importVM = WorkoutImportViewModel()
            await importVM.importWorkouts()
            
            // Fetch imported workouts
            await workoutRepo.fetchWorkouts()
            let importedWorkouts = workoutRepo.workouts
            
            if importedWorkouts.isEmpty {
                print("📊 No workouts found in HealthKit")
                await MainActor.run {
                    isProcessingAfterPermissionGrant = false
                    processingProgress = 0.0
                    processingMessage = ""
                }
                return
            }
            
            print("📥 Imported \(importedWorkouts.count) workouts from HealthKit")
            
            // Step 2: Process bonuses for all workouts (30% of progress)
            await MainActor.run {
                processingProgress = 0.5
                processingMessage = String(localized: "Calculating achievements...", comment: "Progress message during bonus calculation")
            }
            
            let batchSize = 50
            let totalBatches = (importedWorkouts.count + batchSize - 1) / batchSize
            
            for batchIndex in 0..<totalBatches {
                let startIndex = batchIndex * batchSize
                let endIndex = min(startIndex + batchSize, importedWorkouts.count)
                let batch = Array(importedWorkouts[startIndex..<endIndex])
                
                // Process bonuses for this batch using BonusCalculator (same as DataProcessingManager)
                let batchResults = await Task.detached(priority: .background) {
                    var bonuses: [Bonus] = []
                    var achievementsToUpdate: [WorkoutEntity] = []
                    
                    for workout in batch {
                        let workoutBonuses = BonusCalculator.shared.calculateWorkoutBonusHistorical(for: workout)
                        bonuses.append(contentsOf: workoutBonuses)
                        achievementsToUpdate.append(workout)
                    }
                    
                    return (bonuses: bonuses, achievements: achievementsToUpdate)
                }.value
                
                // Update on main actor
                await MainActor.run {
                    for bonus in batchResults.bonuses {
                        BonusManager.shared.addHistoricalBonus(bonus)
                    }
                    for workout in batchResults.achievements {
                        BonusManager.shared.updateAchievements(with: workout)
                    }
                }
                
                // Update progress
                let progress = 0.5 + (Double(batchIndex + 1) / Double(totalBatches)) * 0.3
                await MainActor.run {
                    processingProgress = progress
                    processingMessage = String(localized: "Calculating achievements... \(batchIndex + 1)/\(totalBatches)", comment: "Progress message with batch index during bonus calculation")
                }
            }
            
            // Step 3: Process records for all workouts (20% of progress)
            await MainActor.run {
                processingProgress = 0.8
                processingMessage = String(localized: "Analyzing records...", comment: "Progress message during records analysis")
            }
            
            // Use WorkoutRecordsManager to process records for all periods
            // This processes records for all workouts across different time periods
            await WorkoutRecordsManager.shared.processRecordsForPeriods([.allTime, .thisYear, .thisMonth, .thisWeek, .lastMonth, .lastYear])
            
            // Step 4: Finalize (10% of progress)
            await MainActor.run {
                processingProgress = 0.9
                processingMessage = String(localized: "Finalizing...", comment: "Progress message when finalizing import")
            }
            
            // Update user profile statistics
            await MainActor.run {
                BonusManager.shared.userProfile.totalWorkouts = importedWorkouts.count
                BonusManager.shared.userProfile.totalDistance = importedWorkouts.reduce(0) { $0 + $1.totalDistance }
                BonusManager.shared.userProfile.totalDuration = importedWorkouts.reduce(0) { $0 + $1.duration }
                BonusManager.shared.saveProfile()
            }
            
            // Refresh workout list
            await workoutRepo.fetchWorkouts()
            
            // Recalculate groups
            await MainActor.run {
                recalculateGroupsAsync()
            }
            
            // Complete
            await MainActor.run {
                processingProgress = 1.0
                processingMessage = String(localized: "Complete!", comment: "Message when workout import and processing is finished")
            }
            
            // Wait a moment to show completion
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                isProcessingAfterPermissionGrant = false
                processingProgress = 0.0
                processingMessage = ""
            }
            
            print("✅ Finished processing \(importedWorkouts.count) workouts after permission grant")
            
        } catch {
            print("❌ Error processing workouts after permission grant: \(error)")
            await MainActor.run {
                isProcessingAfterPermissionGrant = false
                processingProgress = 0.0
                processingMessage = ""
            }
        }
    }
    
    private func checkHealthKitAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            let typesToRead: Set = [
                HKObjectType.workoutType(),
                HKSeriesType.workoutRoute(),
                HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                HKQuantityType.quantityType(forIdentifier: .runningSpeed)!,
                HKQuantityType.quantityType(forIdentifier: .cyclingSpeed)!,
                HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!,
                HKQuantityType.quantityType(forIdentifier: .cyclingPower)!,
                HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            ]
            
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private func checkForNewWorkoutsOnAppear() async {
        let lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncDate ?? Date())
        
        if timeSinceLastSync > 300 { // 5 минут
            print("🔄 WorkoutListView: Проверяем наличие новых тренировок при появлении")
            await manualSyncWorkouts()
        } else {
            print("✅ WorkoutListView: Нет необходимости синхронизировать тренировки, последний синхрон был \(Int(timeSinceLastSync)) секунд назад.")
        }
    }
}

struct MonthGroupView: View {
    let month: String
    let workouts: [WorkoutEntity]
    let onWorkoutTap: (WorkoutEntity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            monthHeader(month)
            workoutsInMonth(workouts)
        }
    }

    private func monthHeader(_ month: String) -> some View {
        Text(month)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 16)
    }

    private func workoutsInMonth(_ workouts: [WorkoutEntity]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(workouts, id: \.uuid) { workout in
                WorkoutCapsule(workout: workout) {
                    onWorkoutTap(workout)
                }
            }
        }
    }
}

struct WorkoutCapsule: View {
    let workout: WorkoutEntity
    let action: () -> Void
    
    // Кэшируем отформатированные данные
    private var formattedDate: String {
        guard let date = workout.startDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var formattedDistance: String {
        return workout.totalDistanceKm.formatted(.number.precision(.fractionLength(2)))
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                workoutText(workout.workoutType ?? "No type", font: .headline, color: .white)
                workoutText("Date: \(formattedDate)", font: .subheadline, color: .white.opacity(0.8))
                workoutText("Distance: \(formattedDistance) km", font: .footnote, color: .white.opacity(0.6))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func workoutText(_ text: String, font: Font, color: Color) -> some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
    }
}


