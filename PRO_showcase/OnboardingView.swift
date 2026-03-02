//
//  OnboardingView.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 03.05.2025.
//

import SwiftUI
import Charts
import HealthKit
import CoreData



struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage("chartColorHex") private var chartColorHex: String = "#E86BAF"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#D42D78"
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    @State private var pageIndex = 0
    @State private var isBackgroundDataProcessing = false
    @State private var permissionsCheckTimer: Timer?
    @State private var showSwipeBlockedMessage = false
    @EnvironmentObject var permissionManager: PermissionManager
    @EnvironmentObject var dataProcessingManager: DataProcessingManager
    @EnvironmentObject var authManager: AuthenticationManager

    var chartColor: Color {
        Color(hex: chartColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var body: some View {
        ZStack {
            // Background image with sophisticated overlay and blur
            Image("AuthBg")
                .resizable()
                .scaledToFill()
                .blur(radius: 5)
                .ignoresSafeArea()
                .overlay(
                    // Enhanced gradient overlay for better text readability on new background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 0) {
                                                MinimalistProgressIndicator(currentPage: pageIndex, totalPages: 8)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                
                // Permission status indicator
                if pageIndex == 3 {
                    permissionStatusIndicator
                }
                
                // Swipe blocked message
                if showSwipeBlockedMessage {
                    swipeBlockedMessage
                }
                
                TabView(selection: $pageIndex) {
                    onboardingPages
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            handleDragGesture(value)
                        }
                )
                .onChange(of: pageIndex) { newIndex in
                    handlePageIndexChange(newIndex)
                }
                .onChange(of: permissionManager.allPermissionsGranted) { allGranted in
                    handlePermissionsGrantedChange(allGranted)
                }
                
                // Enhanced swipe hint with better visibility
                let lastPageIndex = 7
                if pageIndex < lastPageIndex {
                    swipeHintView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                // Start from welcome page (index 0)
                pageIndex = 0
                
                // Start periodic permissions check
                startPermissionsCheckTimer()
            }
            .onDisappear {
                // Clean up timer
                stopPermissionsCheckTimer()
            }
        }
    }
    
    // MARK: - Swipe Control
    
    private func canUserSwipe() -> Bool {
        // Users can always swipe - permissions are optional
        // App should function without all permissions granted
        return true
    }
    
    // MARK: - Permission Requirements
    
    private func hasEssentialPermissions() -> Bool {
        // Allow proceeding if at least HealthKit permissions are granted
        // This is the most critical permission for the app to function
        return permissionManager.healthKitStatus == .authorized
    }
    
    private func hasAllPermissions() -> Bool {
        return permissionManager.allPermissionsGranted
    }
    
    private func getPermissionStatus() -> (essential: Bool, all: Bool) {
        return (hasEssentialPermissions(), hasAllPermissions())
    }
    
    // MARK: - Page Navigation
    
    private func advanceToNextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pageIndex = min(pageIndex + 1, 7)
        }
    }
    
    // MARK: - Permissions Monitoring
    
    private func startPermissionsCheckTimer() {
        // Check permissions every 2 seconds
        permissionsCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await permissionManager.checkCurrentPermissions()
            }
        }
    }
    
    private func stopPermissionsCheckTimer() {
        permissionsCheckTimer?.invalidate()
        permissionsCheckTimer = nil
    }
    
    // MARK: - Informational Overlay (Non-Blocking)
    
    @ViewBuilder
    private var essentialPermissionsBlockingOverlay: some View {
        // Changed to informational only - does not block user interaction
        EmptyView() // Remove blocking overlay entirely - users can always proceed
    }
    
    @ViewBuilder
    private var optionalPermissionsOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Optional Permissions", comment: "Label for optional permissions section in onboarding")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .allowsHitTesting(false)
        
        // Informational overlay for optional permissions
        Rectangle()
            .fill(Color.black.opacity(0.05))
            .allowsHitTesting(false)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Optional Permissions", comment: "Title for optional permissions overlay in onboarding")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Location and notification permissions are optional but recommended for the best experience. You can continue without them or grant them later in settings.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button(String(localized: "Continue Anyway", comment: "Button to proceed with onboarding without granting optional permissions")) {
                        advanceToNextPage()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.top, 10)
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            )
            .allowsHitTesting(false)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: hasAllPermissions())
    }
    
    // MARK: - Permission Status Indicator
    
    @ViewBuilder
    private var permissionStatusIndicator: some View {
        if !hasEssentialPermissions() {
            // Permissions missing - show informational note (not blocking)
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Health permissions are recommended for full functionality. You can grant them anytime from Settings.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            .padding(.top, 8)
            .transition(.opacity)
        } else if !hasAllPermissions() {
            // Essential permissions granted, optional missing - show info
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Optional permissions recommended")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            .padding(.top, 8)
            .transition(.opacity)
        } else {
            // All permissions granted - show success
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("All permissions granted")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
            .padding(.top, 8)
            .transition(.opacity)
        }
    }
    
    // MARK: - Swipe Blocked Message
    
    @ViewBuilder
    private var swipeBlockedMessage: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 14))
                .foregroundColor(.red)
            
            Text("Complete permissions first", comment: "Message when user must complete permission step before swiping")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.2))
        .cornerRadius(8)
        .padding(.top, 4)
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSwipeBlockedMessage = false
                }
            }
        }
    }
    
    // MARK: - Background Data Processing
    
    private func startBackgroundDataProcessing() {
        guard !isBackgroundDataProcessing else { return }
        isBackgroundDataProcessing = true
        
        print("🚀 Starting background data processing while user continues onboarding")
        
        // Don't automatically advance - let user control when to proceed
        // User can swipe or tap Continue button when ready
        
        Task {
            await performBackgroundDataProcessing()
        }
    }
    
    private func performBackgroundDataProcessing() async {
        do {
            // Start data processing in background - user can continue with onboarding
            await dataProcessingManager.performInitialSetup()
            
            print("✅ Background data processing completed successfully")
            
        } catch {
            print("⚠️ Background processing error: \(error) - continuing anyway")
        }
        
        await MainActor.run {
            isBackgroundDataProcessing = false
        }
    }

    private func handleDragGesture(_ value: DragGesture.Value) {
        // Users can always swipe - permissions are optional
        let threshold: CGFloat = 50
        if value.translation.width < -threshold && pageIndex < 7 {
            // Swipe left (next page)
            advanceToNextPage()
        } else if value.translation.width > threshold && pageIndex > 0 {
            // Swipe right (previous page)
            withAnimation(.easeInOut(duration: 0.3)) {
                pageIndex = max(pageIndex - 1, 0)
            }
        }
    }

    private func handlePageIndexChange(_ newIndex: Int) {
        // Allow navigation to all pages - permissions are optional
        // Users can proceed without granting all permissions
    }

    private func handlePermissionsGrantedChange(_ allGranted: Bool) {
        // Automatically advance to next page when essential permissions are granted
        if hasEssentialPermissions() && pageIndex == 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                advanceToNextPage()
            }
        }
    }

    @ViewBuilder
    private var swipeHintView: some View {
        // Always show swipe hint - users can always proceed
        Text("Swipe right to continue →")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .transition(.opacity)
    }

    @ViewBuilder
    private var onboardingPages: some View {
        Group {
            // Page 0: Welcome
            MinimalistWelcomePage()
                .tag(0)
                .frame(maxWidth: 400)
                .padding(.horizontal, 16)
            
                            // Page 1: AI Features
                MinimalistAIFeaturesPage()
                    .tag(1)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
                
                // Page 2: Advanced Analytics
                MinimalistAdvancedAnalyticsPage()
                    .tag(2)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
                
                                // Page 3: Permissions
                MinimalistPermissionsPage(
                    onPermissionsGranted: startBackgroundDataProcessing,
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    isPresented: $isPresented,
                    onContinue: advanceToNextPage
                )
                    .tag(3)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
                    // Removed blocking overlay - users can always proceed
                    // Don't auto-request permissions - let user decide when to request
                
                // Page 4: Core Features
                MinimalistFeaturesPage()
                    .tag(4)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
                
                // Page 5: Bonus System
                MinimalistBonusSystemPage()
                    .tag(5)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
                
                // Page 6: Motivation
                MinimalistMotivationPage()
                    .tag(6)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
                
                // Page 7: Final step (data processing is already done in background)
                MinimalistFinalStepPage(
                    onComplete: {
                        // Enable streak tracking after onboarding completion
                        BonusManager.shared.checkAndEnableStreakTrackingIfNeeded()
                        
                        hasCompletedOnboarding = true
                        isPresented = false
                        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                    }
                )
                    .tag(7)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)
        }
    }
}

// MARK: - Enhanced Minimalist Progress Indicator

struct MinimalistProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Rectangle()
                    .fill(index == currentPage ? Color.white : Color(hex: "#D42D78").opacity(0.6))
                    .frame(width: index == currentPage ? 24 : 16, height: 2)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.02, blue: 0.12, opacity: 0.95))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#D42D78").opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Minimalist Welcome Page

struct MinimalistWelcomePage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Spacer for better layout
            Spacer()
                .frame(height: 50)
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Logo from assets
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 180)
                    .padding(.vertical, 10)
                
                Text("Progress Records Optimization")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(1)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - ASCII Logo Component

struct ASCIILogoView: View {
    let size: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            // ASCII art representation of "PRO" in computer font style
            Text("██████╗ ██████╗  ██████╗ ")
                .font(.system(size: size * 0.12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text("██╔══██╗██╔══██╗██╔═══██╗")
                .font(.system(size: size * 0.12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text("██████╔╝██████╔╝██║   ██║")
                .font(.system(size: size * 0.12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text("██╔═══╝ ██╔══██╗██║   ██║")
                .font(.system(size: size * 0.12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text("██║     ██║  ██║╚██████╔╝")
                .font(.system(size: size * 0.12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text("╚═╝     ╚═╝  ╚═╝ ╚═════╝ ")
                .font(.system(size: size * 0.12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// Alternative simpler ASCII version for smaller displays
struct SimpleASCIILogoView: View {
    let size: CGFloat
    
    var body: some View {
        VStack(spacing: 1) {
            Text("██████╗ ██████╗  ██████╗")
                .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text("██╔══██╗██╔══██╗██╔═══██╗")
                .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text("██████╔╝██████╔╝██║   ██║")
                .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text("██╔═══╝ ██╔══██╗██║   ██║")
                .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text("██║     ██║  ██║╚██████╔╝")
                .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text("╚═╝     ╚═╝  ╚═╝ ╚═════╝")
                .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// Compact ASCII logo for headers and navigation
struct CompactASCIILogoView: View {
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 2) {
            // Compact horizontal ASCII "PRO"
            Text("██████╗")
                .font(.system(size: size * 0.06, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text("██████╗")
                .font(.system(size: size * 0.06, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text(" ██████╗")
                .font(.system(size: size * 0.06, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - AI Features Page (Page 1)

// MARK: - Advanced Analytics Page (Page 2)

struct MinimalistAdvancedAnalyticsPage: View {
    @State private var animateAnalytics = false
    
    let analyticsFeatures = [
        MinimalistAnalyticsFeatureData(icon: "chart.line.uptrend.xyaxis", title: "Performance Trends", description: "Track your progress over time with detailed charts"),
        MinimalistAnalyticsFeatureData(icon: "speedometer", title: "Speed Analysis", description: "Analyze your pace and speed variations"),
        MinimalistAnalyticsFeatureData(icon: "heart.text.square", title: "Heart Rate Zones", description: "Monitor your training intensity and recovery"),
        MinimalistAnalyticsFeatureData(icon: "map", title: "Route Analysis", description: "Visualize your running routes and elevation data")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Analytics Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                    )
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.blue)
            }
            .opacity(animateAnalytics ? 1 : 0)
            .animation(.easeInOut(duration: 0.8), value: animateAnalytics)
            .padding(.bottom, 30)
            
            VStack(spacing: 12) {
                Text("Advanced Analytics")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Dive deep into your workout data with comprehensive analytics")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .opacity(animateAnalytics ? 1 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateAnalytics)
            .padding(.bottom, 30)
            
            // Analytics Features List
            VStack(spacing: 12) {
                ForEach(Array(analyticsFeatures.enumerated()), id: \.offset) { index, feature in
                    MinimalistAnalyticsFeatureCard(feature: feature)
                        .offset(x: animateAnalytics ? 0 : -30)
                        .opacity(animateAnalytics ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animateAnalytics)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            animateAnalytics = true
        }
    }
}

struct MinimalistAnalyticsFeatureData {
    let icon: String
    let title: String
    let description: String
}

struct MinimalistAnalyticsFeatureCard: View {
    let feature: MinimalistAnalyticsFeatureData
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(feature.description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(red: 0.1, green: 0.03, blue: 0.15, opacity: 0.95))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - New Authorization Page

struct MinimalistAuthorizationPage: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSigningIn = false
    @Binding var pageIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Sign In to Continue")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Create an account or sign in to save your progress and sync across devices")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .padding(.bottom, 30)
            .padding(.horizontal, 40)
            
            // Sign In Options
            VStack(spacing: 16) {
                // Apple Sign In
                Button(action: {
                    isSigningIn = true
                    Task {
                        await signInWithApple()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16))
                        Text("Continue with Apple")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isSigningIn)
                
                // Google Sign In
                Button(action: {
                    isSigningIn = true
                    Task {
                        await signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 16))
                        Text("Continue with Google")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                                            .background(Color.blue.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.7), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isSigningIn)
                
                // Email Sign In
                Button(action: {
                    isSigningIn = true
                    Task {
                        await signInWithEmail()
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                        Text("Continue with Email")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#D42D78").opacity(0.95))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#D42D78").opacity(0.7), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isSigningIn)
            }
            .padding(.horizontal, 40)
            
            if isSigningIn {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.0)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Signing you in...")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.top, 20)
            }
            
            // Manual continue button (in case authentication fails or user wants to skip)
            Button(action: {
                withAnimation {
                    pageIndex = 1
                }
            }) {
                Text("Continue Without Sign In")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                    .underline()
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                withAnimation {
                    pageIndex = 1
                }
            }
        }
    }
    
    private func signInWithApple() async {
        await authManager.signInWithApple()
    }
    
    private func signInWithGoogle() async {
        await authManager.signInWithGoogle()
    }
    
    private func signInWithEmail() async {
        // For now, we'll use a simple email sign-in approach
        // This could be enhanced with a proper email form
        await authManager.signIn(email: "demo@example.com", password: "demo123")
    }
}



// MARK: - Enhanced Minimalist Features Page

struct MinimalistFeaturesPage: View {
    @State private var animateFeatures = false
    
    let features = [
        MinimalistFeatureData(icon: "chart.bar.xaxis", title: "Real-time analytics", description: "Detailed charts and statistics"),
        MinimalistFeatureData(icon: "bolt.fill", title: "Lightning-fast processing", description: "Fast data analysis"),
        MinimalistFeatureData(icon: "trophy.fill", title: "Achievement system", description: "Earn bonuses and level up"),
        MinimalistFeatureData(icon: "heart.fill", title: "Health monitoring", description: "Track heart rate and activity")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("What awaits you?")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .opacity(animateFeatures ? 1 : 0)
                .animation(.easeInOut(duration: 0.6), value: animateFeatures)
                .padding(.bottom, 30)
            
            VStack(spacing: 12) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    MinimalistFeatureCard(feature: feature)
                        .offset(x: animateFeatures ? 0 : -30)
                        .opacity(animateFeatures ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animateFeatures)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            animateFeatures = true
        }
    }
}

struct MinimalistFeatureData {
    let icon: String
    let title: String
    let description: String
}

struct MinimalistFeatureCard: View {
    let feature: MinimalistFeatureData
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: "#D42D78").opacity(0.95))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#D42D78").opacity(0.7), lineWidth: 1.5)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(feature.description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(red: 0.1, green: 0.03, blue: 0.15, opacity: 0.95))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#D42D78").opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Enhanced Minimalist Motivation Page

struct MinimalistMotivationPage: View {
    @State private var animateMotivation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Enhanced minimalist motivation icons with better contrast
            HStack(spacing: 30) {
                MinimalistMotivationIcon(icon: "flame", color: .orange)
                MinimalistMotivationIcon(icon: "star", color: .yellow)
                MinimalistMotivationIcon(icon: "trophy", color: .white)
            }
            .opacity(animateMotivation ? 1 : 0)
            .animation(.easeInOut(duration: 0.8), value: animateMotivation)
            .padding(.bottom, 30)
            
            VStack(spacing: 12) {
                Text("Motivation & Achievements")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Earn points, level up, and reach new heights")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .opacity(animateMotivation ? 1 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateMotivation)
            .padding(.bottom, 30)
            
            // Achievement examples
            VStack(spacing: 10) {
                MinimalistAchievementExample(title: "Marathoner", points: "500")
                MinimalistAchievementExample(title: "Speed of light", points: "200")
                MinimalistAchievementExample(title: "100 days", points: "1000")
            }
            .opacity(animateMotivation ? 1 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.6), value: animateMotivation)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            animateMotivation = true
        }
    }
}

struct MinimalistMotivationIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 28, weight: .light))
            .foregroundColor(color)
            .frame(width: 50, height: 50)
            .background(Color(hex: "#D42D78").opacity(0.95))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#D42D78").opacity(0.7), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct MinimalistAchievementExample: View {
    let title: String
    let points: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            Spacer()
            
            Text("+\(points)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.1, green: 0.03, blue: 0.15, opacity: 0.95))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#D42D78").opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Minimalist Bonus System Page

struct MinimalistBonusSystemPage: View {
    @State private var animateBonus = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Enhanced minimalist bonus system icon with better contrast
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                
                Image(systemName: "gift")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)
            }
            .opacity(animateBonus ? 1 : 0)
            .animation(.easeInOut(duration: 0.8), value: animateBonus)
            .padding(.bottom, 30)
            
            VStack(spacing: 12) {
                Text("Bonus system")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Get special bonuses for outstanding results")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .opacity(animateBonus ? 1 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateBonus)
            .padding(.bottom, 30)
            
            // Bonus examples
            VStack(spacing: 10) {
                MinimalistBonusExample(title: "Speed record", bonus: "2x points")
                MinimalistBonusExample(title: "Long distance", bonus: "3x points")
                MinimalistBonusExample(title: "High heart rate", bonus: "1.5x points")
            }
            .opacity(animateBonus ? 1 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.6), value: animateBonus)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            animateBonus = true
        }
    }
}

struct MinimalistBonusExample: View {
    let title: String
    let bonus: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(bonus)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Spacer()
            
            Image(systemName: "gift")
                .foregroundColor(.yellow)
                .font(.system(size: 14))
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.1, green: 0.03, blue: 0.15, opacity: 0.95))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#D42D78").opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Enhanced Minimalist AI Features Page

struct MinimalistAIFeaturesPage: View {
    @State private var animateAIFeatures = false
    
    let aiFeatures = [
        MinimalistAIFeatureData(icon: "brain.head.profile", title: "Smart Analytics", description: "AI-powered insights from your workout data"),
        MinimalistAIFeatureData(icon: "calendar.badge.clock", title: "AI Training Plan", description: "Personalized workout schedules created by AI"),
        MinimalistAIFeatureData(icon: "message.and.waveform", title: "AI Chat Assistant", description: "Get instant answers and workout advice"),
        MinimalistAIFeatureData(icon: "bolt.circle", title: "Smart Recommendations", description: "Personalized workout suggestions")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // AI Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#D42D78").opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#D42D78").opacity(0.4), lineWidth: 1.5)
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(hex: "#D42D78"))
            }
            .opacity(animateAIFeatures ? 1 : 0)
            .animation(.easeInOut(duration: 0.8), value: animateAIFeatures)
            .padding(.bottom, 30)
            
            VStack(spacing: 12) {
                Text("AI-Powered Intelligence")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Compact logo from assets
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 90)
                    .padding(.vertical, 8)
                
                Text("Experience the future of fitness tracking with advanced AI")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .opacity(animateAIFeatures ? 1 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateAIFeatures)
            .padding(.bottom, 30)
            
            // AI Features List
            VStack(spacing: 12) {
                ForEach(Array(aiFeatures.enumerated()), id: \.offset) { index, feature in
                    MinimalistAIFeatureCard(feature: feature)
                        .offset(x: animateAIFeatures ? 0 : -30)
                        .opacity(animateAIFeatures ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animateAIFeatures)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            animateAIFeatures = true
        }
    }
}

struct MinimalistAIFeatureData {
    let icon: String
    let title: String
    let description: String
}

struct MinimalistAIFeatureCard: View {
    let feature: MinimalistAIFeatureData
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color(hex: "#D42D78"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "#D42D78").opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#D42D78").opacity(0.4), lineWidth: 1.5)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(feature.description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(red: 0.1, green: 0.03, blue: 0.15, opacity: 0.95))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#D42D78").opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Enhanced Minimalist Permissions Page

struct MinimalistPermissionsPage: View {
    @EnvironmentObject var permissionManager: PermissionManager
    @State private var isRequesting = false
    @State private var animatePermissions = false
    @State private var hasAutoRequested = false
    @State private var showingDeniedPermissionsAlert = false
    @State private var deniedPermissions: [PermissionType] = []
    let onPermissionsGranted: () -> Void
    @Binding var hasCompletedOnboarding: Bool
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("App Permissions")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                VStack(spacing: 4) {
                    Text("To provide you with the best experience,")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .tracking(0.5)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    Text("we need the following permissions:")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .tracking(0.5)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
            .opacity(animatePermissions ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: animatePermissions)
            .padding(.bottom, 30)
            
            // Permissions list
            VStack(spacing: 10) {
                ForEach(PermissionType.allCases, id: \.self) { permissionType in
                    MinimalistPermissionRowView(
                        type: permissionType,
                        status: statusForPermission(permissionType)
                    )
                }
            }
            .padding(.horizontal, 20)
            .opacity(animatePermissions ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.2), value: animatePermissions)
            .padding(.bottom, 30)
            
            // Status and action section
            VStack(spacing: 12) {
                if hasEssentialPermissions() {
                    if permissionManager.allPermissionsGranted {
                        // All permissions granted - show success and continue
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                
                                Text("All permissions granted!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            Text("You can now continue with the onboarding")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            // Success animation
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                    .scaleEffect(animatePermissions ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animatePermissions)
                            }
                            .padding(.vertical, 10)
                            
                            Button(action: onContinue) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15))
                                    Text("Continue")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color(hex: "#D42D78").opacity(0.95))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#D42D78").opacity(0.7), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 40)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.5), value: permissionManager.allPermissionsGranted)
                    } else {
                        // Essential permissions granted, optional missing - show continue option
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                
                                Text("Essential permissions granted!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            Text("You can continue with basic functionality. Optional permissions can be granted later.")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            // Continue button
                            Button(action: onContinue) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15))
                                    Text("Continue with Basic Features (not recommended)")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.blue.opacity(0.95))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.7), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 40)
                            
                            // Request remaining permissions button
                            Button(action: {
                                isRequesting = true
                                Task {
                                    // Check denied permissions before requesting
                                    let previouslyDenied = permissionManager.deniedPermissionsRequiringSettings
                                    
                                    let results = await permissionManager.requestAllPermissions()
                                    isRequesting = false
                                    
                                    // Check which permissions are still denied after request
                                    permissionManager.checkCurrentPermissions()
                                    // Wait a bit for status to update
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                    let stillDenied = await MainActor.run {
                                        permissionManager.deniedPermissionsRequiringSettings
                                    }
                                    
                                    // If some permissions were previously denied and are still denied, show alert
                                    if !stillDenied.isEmpty && stillDenied == previouslyDenied {
                                        deniedPermissions = stillDenied
                                        showingDeniedPermissionsAlert = true
                                    }
                                    
                                    // Start background processing if all permissions granted, but don't auto-navigate
                                    if results.values.allSatisfy({ $0 }) {
                                        print("✅ All permissions granted, starting background import")
                                        onPermissionsGranted()
                                    }
                                    // User stays on page - they can proceed when ready via button or swipe
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.shield")
                                        .font(.system(size: 15))
                                    Text("Request Remaining Permissions")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.pink.opacity(0.95))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#D42D78").opacity(0.7), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 40)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.5), value: hasEssentialPermissions())
                    }
                } else if permissionManager.isRequestingPermissions || isRequesting {
                    // Requesting permissions - show progress
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(1.0)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Requesting permissions...")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                } else {
                    // Permissions not granted - show request button as primary, continue as secondary
                    VStack(spacing: 16) {
                        // Recommendation message - emphasize that permissions are needed
                        VStack(spacing: 8) {
                            Text("Permissions Recommended")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Grant permissions to unlock the full potential of P.R.O. Your app needs access to Health data, Location, and Notifications to track workouts, provide insights, and deliver personalized training plans.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        
                        // Request Permissions button - PRIMARY ACTION (prominent)
                        Button(action: {
                            isRequesting = true
                            Task {
                                // Check denied permissions before requesting
                                let previouslyDenied = permissionManager.deniedPermissionsRequiringSettings
                                
                                let results = await permissionManager.requestAllPermissions()
                                isRequesting = false
                                
                                // Check which permissions are still denied after request
                                permissionManager.checkCurrentPermissions()
                                // Wait a bit for status to update
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                let stillDenied = await MainActor.run {
                                    permissionManager.deniedPermissionsRequiringSettings
                                }
                                
                                // If some permissions were previously denied and are still denied, show alert
                                if !stillDenied.isEmpty && stillDenied == previouslyDenied {
                                    deniedPermissions = stillDenied
                                    showingDeniedPermissionsAlert = true
                                }
                                
                                // Start background processing if permissions granted, but don't auto-navigate
                                if results[.healthKit] == true {
                                    print("✅ Essential permissions granted")
                                    onPermissionsGranted()
                                }
                                // User stays on page - they can proceed when ready via button or swipe
                            }
                        }) {
                            HStack(spacing: 10) {
                                if isRequesting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isRequesting ? "Requesting..." : "Request Permissions")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#D42D78"), Color(hex: "#E86BAF")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color(hex: "#D42D78").opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 40)
                        .disabled(isRequesting)
                        
                        // Continue with Basic Features button - SECONDARY ACTION (less prominent)
                        Button(action: onContinue) {
                            HStack {
                                Text("Continue with Limited Features")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        // Additional informational text
                        Text("Note: Most features require permissions to function")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 40)
            .opacity(animatePermissions ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.4), value: animatePermissions)
            
            Spacer()
        }
        .onAppear {
            animatePermissions = true
            
            // Don't automatically request permissions - let user decide when to request
            // User can tap "Request Permissions" button when ready
        }
        .alert(String(localized: "Some permissions need Settings", comment: "Alert title when some permissions were denied and must be enabled in Settings"), isPresented: $showingDeniedPermissionsAlert) {
            Button(String(localized: "Cancel", comment: "Button to dismiss the alert"), role: .cancel) { }
            Button(String(localized: "Open Settings", comment: "Button to open system Settings")) {
                Task {
                    await permissionManager.openSettings()
                }
            }
        } message: {
            let permissionNames = deniedPermissions.map { $0.displayName }.joined(separator: ", ")
            Text("\(permissionNames) \(deniedPermissions.count == 1 ? "was" : "were") previously denied. iOS won't show the permission dialog again. You can enable \(deniedPermissions.count == 1 ? "it" : "them") in Settings if you'd like.")
        }
    }
    
    private func statusForPermission(_ type: PermissionType) -> PermissionStatus {
        switch type {
        case .healthKit:
            return permissionManager.healthKitStatus
        case .location:
            return permissionManager.locationStatus
        case .notifications:
            return permissionManager.notificationStatus
        }
    }
    
    private func hasEssentialPermissions() -> Bool {
        // Allow proceeding if at least HealthKit permissions are granted
        return permissionManager.healthKitStatus == .authorized
    }
}

// MARK: - Minimalist Permission Row View
struct MinimalistPermissionRowView: View {
    let type: PermissionType
    let status: PermissionStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForPermission(type))
                .font(.system(size: 15))
                .foregroundColor(colorForStatus(status))
                .frame(width: 22, height: 22)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(titleForPermission(type))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(descriptionForPermission(type))
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Spacer()
            
            Image(systemName: iconForStatus(status))
                .font(.system(size: 13))
                .foregroundColor(colorForStatus(status))
        }
        .padding(10)
        .background(Color(red: 0.1, green: 0.03, blue: 0.15, opacity: 0.95))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#D42D78").opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
    
    private func iconForPermission(_ type: PermissionType) -> String {
        switch type {
        case .healthKit: return "heart.fill"
        case .location: return "location.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    private func titleForPermission(_ type: PermissionType) -> String {
        switch type {
        case .healthKit: return "Health Data"
        case .location: return "Location"
        case .notifications: return "Notifications"
        }
    }
    
    private func descriptionForPermission(_ type: PermissionType) -> String {
        switch type {
        case .healthKit: return "Access workout and health data"
        case .location: return "Track your running routes"
        case .notifications: return "Receive achievements and updates"
        }
    }
    
    private func iconForStatus(_ status: PermissionStatus) -> String {
        switch status {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .restricted: return "exclamationmark.triangle.fill"
        case .unavailable: return "xmark.circle"
        }
    }
    
    private func colorForStatus(_ status: PermissionStatus) -> Color {
        switch status {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .yellow
        case .restricted: return .orange
        case .unavailable: return .gray
        }
    }
}






// MARK: - Minimalist Final Step Page

struct MinimalistFinalStepPage: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Onboarding Complete!")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Small logo from assets
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 120)
                    .padding(.vertical, 10)
                
                Text("Your fitness journey is now optimized. Enjoy your workouts!")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .padding(.bottom, 30)
            
            // Final message
            Text("You can now start using the app to track your workouts and achieve your fitness goals.")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Background processing indicator
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                
                Text("Setting up your fitness profile in the background...")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            
            // Continue button
            Button(action: onComplete) {
                HStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15))
                    Text("Start Workouts")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: "#D42D78").opacity(0.95))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#D42D78").opacity(0.7), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}



// MARK: - Previews

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true), hasCompletedOnboarding: .constant(false))
            .environmentObject(PermissionManager.shared)
            .environmentObject(DataProcessingManager.shared)
            .environmentObject(AuthenticationManager())
    }
}

// MARK: - Individual onboarding screen previews

#Preview("Welcome") {
    onboardingPreviewBackground {
        MinimalistWelcomePage()
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("AI Features") {
    onboardingPreviewBackground {
        MinimalistAIFeaturesPage()
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("Advanced Analytics") {
    onboardingPreviewBackground {
        MinimalistAdvancedAnalyticsPage()
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("Permissions") {
    onboardingPreviewBackground {
        MinimalistPermissionsPage(
            onPermissionsGranted: {},
            hasCompletedOnboarding: .constant(false),
            isPresented: .constant(true),
            onContinue: {}
        )
        .frame(maxWidth: 400)
        .padding(.horizontal, 16)
        .environmentObject(PermissionManager.shared)
    }
}

#Preview("Features") {
    onboardingPreviewBackground {
        MinimalistFeaturesPage()
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("Bonus System") {
    onboardingPreviewBackground {
        MinimalistBonusSystemPage()
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("Motivation") {
    onboardingPreviewBackground {
        MinimalistMotivationPage()
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("Final Step") {
    onboardingPreviewBackground {
        MinimalistFinalStepPage(onComplete: {})
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
    }
}

#Preview("Progress indicator") {
    onboardingPreviewBackground {
        VStack {
            MinimalistProgressIndicator(currentPage: 2, totalPages: 8)
            Spacer()
        }
        .padding(.top, 20)
        .padding(.horizontal, 24)
    }
}

/// Shared background for onboarding screen previews so they match the real flow.
private struct OnboardingPreviewBackground<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Image("AuthBg")
                .resizable()
                .scaledToFill()
                .blur(radius: 5)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            content()
        }
    }
}

private func onboardingPreviewBackground<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
    OnboardingPreviewBackground(content: content)
}

// MARK: - Geometric Logo Component

struct GeometricLogoView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.1, blue: 0.2)) // Dark maroon background
                .frame(width: size, height: size * 0.6)
            
            // PRO Letters using geometric shapes
            HStack(spacing: size * 0.05) {
                // Letter P
                LetterP(size: size * 0.25)
                
                // Letter R
                LetterR(size: size * 0.25)
                
                // Letter O
                LetterO(size: size * 0.25)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// Letter P Component
struct LetterP: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Main vertical bar
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8)) // Light pink
                .frame(width: size * 0.2, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2) // Darker pink outline
                )
            
            // Top horizontal bar
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.6, height: size * 0.2)
                .offset(x: size * 0.1, y: -size * 0.35)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
            
            // Middle horizontal bar
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.6, height: size * 0.2)
                .offset(x: size * 0.1, y: 0)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
            
            // Right vertical bar (completing the P loop)
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.2, height: size * 0.4)
                .offset(x: size * 0.5, y: -size * 0.15)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
        }
    }
}

// Letter R Component
struct LetterR: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Main vertical bar
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.2, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
            
            // Top horizontal bar
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.6, height: size * 0.2)
                .offset(x: size * 0.1, y: -size * 0.35)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
            
            // Middle horizontal bar
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.6, height: size * 0.2)
                .offset(x: size * 0.1, y: 0)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
            
            // Diagonal leg of R
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.15, height: size * 0.4)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.35, y: size * 0.2)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                        .rotationEffect(.degrees(45))
                )
        }
    }
}

// Letter O Component
struct LetterO: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Outer rectangle (thick border)
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
            
            // Inner cutout (hollow center)
            Rectangle()
                .fill(Color(red: 0.4, green: 0.1, blue: 0.2)) // Same as background
                .frame(width: size * 0.6, height: size * 0.6)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 2)
                )
        }
    }
}

// Compact version for headers
struct CompactGeometricLogoView: View {
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: size * 0.02) {
            // Compact P
            CompactLetterP(size: size * 0.15)
            
            // Compact R
            CompactLetterR(size: size * 0.15)
            
            // Compact O
            CompactLetterO(size: size * 0.15)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.4, green: 0.1, blue: 0.2))
        )
    }
}

// Compact Letter Components
struct CompactLetterP: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.15, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.4, height: size * 0.15)
                .offset(x: size * 0.075, y: -size * 0.35)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.4, height: size * 0.15)
                .offset(x: size * 0.075, y: 0)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.15, height: size * 0.4)
                .offset(x: size * 0.3, y: -size * 0.15)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
        }
    }
}

struct CompactLetterR: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.15, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.4, height: size * 0.15)
                .offset(x: size * 0.075, y: -size * 0.35)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.4, height: size * 0.15)
                .offset(x: size * 0.075, y: 0)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size * 0.12, height: size * 0.3)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.25, y: size * 0.15)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                        .rotationEffect(.degrees(45))
                )
        }
    }
}

struct CompactLetterO: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.95, green: 0.6, blue: 0.8))
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
            
            Rectangle()
                .fill(Color(red: 0.4, green: 0.1, blue: 0.2))
                .frame(width: size * 0.6, height: size * 0.6)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.8, green: 0.4, blue: 0.6), lineWidth: 1)
                )
        }
    }
}




