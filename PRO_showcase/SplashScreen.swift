//
//  SplashScreen.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 19.06.2025.
//

import SwiftUI

struct SplashScreen: View {
    @State private var animateLogo = false
    @State private var animateText = false
    @State private var animateProgress = false
    @State private var isFinished = false
    
    var body: some View {
        Group {
            if !isFinished {
                ZStack {
                    // Background image with gradient overlay (same as onboarding)
                    Image("AuthBg")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.1),
                                    Color.black.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 36) {
                        Spacer()
                        
                        // Animated logo
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 120)
                            .scaleEffect(animateLogo ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateLogo)
                        
                        // Loading text
                        VStack(spacing: 10) {
                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(animateText ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateText)
                        }
                        
                        // Progress indicator
                        VStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                                .opacity(animateProgress ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6).delay(0.6), value: animateProgress)
                        }
                        
                        Spacer()
                        
                        // App version
                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                            .opacity(animateText ? 1 : 0)
                            .animation(.easeInOut(duration: 0.6).delay(1.0), value: animateText)
                            .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                }
                .onAppear {
                    // Start animations
                    animateLogo = true
                    animateText = true
                    animateProgress = true
                    
                    // Show splash for a short time
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isFinished = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
} 
