import SwiftUI
import HealthKit


enum SportType: String, CaseIterable, Decodable, Encodable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case walking = "Walking"
    case hiking = "Hiking"
    case other = "Other"
    
    var displayName: String {
        switch self {
        case .running: return String(localized: "Running", comment: "Sport type name")
        case .cycling: return String(localized: "Cycling", comment: "Sport type name")
        case .swimming: return String(localized: "Swimming", comment: "Sport type name")
        case .walking: return String(localized: "Walking", comment: "Sport type name")
        case .hiking: return String(localized: "Hiking", comment: "Sport type name")
        case .other: return String(localized: "Other", comment: "Sport type name for miscellaneous activities")
        }
    }
    var color: Color {
        switch self {
        case .running: return .blue
        case .cycling: return .green
        case .walking: return .orange
        case .hiking: return .purple
        case .swimming: return .indigo
        case .other: return .red
        }
    }
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .hiking: return "mountain.2"
        case .other: return "figure.mixed.cardio"
        }
    }
    
    var relevantMetrics: [WorkoutMetric] {
        switch self {
        case .running:
            return [.type, .start, .duration, .distance, .averageHeartRate, .maxHeartRate, .averageSpeed, .maxSpeed, .runningCadence, .pace]
        case .cycling:
            return [.type, .start, .duration, .distance, .averageHeartRate, .maxHeartRate, .averageSpeed, .maxSpeed, .cyclingCadence, .cyclingPower]
        case .swimming:
            return [.type, .start, .duration, .distance, .averageHeartRate, .maxHeartRate, .averageSpeed, .maxSpeed, .swimmingPace, .swimmingLaps]
        case .walking:
            return [.type, .start, .duration, .distance, .averageHeartRate, .maxHeartRate, .averageSpeed, .maxSpeed]
        case .hiking:
            return [.type, .start, .duration, .distance, .averageHeartRate, .maxHeartRate, .averageSpeed, .maxSpeed]
        case .other:
            return [.type, .start, .duration, .distance, .averageHeartRate, .maxHeartRate, .averageSpeed, .maxSpeed]
        }
    }
    
    var relevantSections: [WorkoutSection] {
        switch self {
        case .running:
            return [.main, .metadata, .heartRate, .heartRateZones, .speed, .segments, .route, .events]
        case .cycling:
            return [.main, .metadata, .heartRate, .heartRateZones, .speed, .segments, .route, .events]
        case .swimming:
            return [.main, .metadata, .heartRate, .heartRateZones, .speed, .segments, .swimmingLaps, .events]
        case .walking:
            return [.main, .metadata, .heartRate, .heartRateZones, .speed, .segments, .route, .events]
        case .hiking:
            return [.main, .metadata, .heartRate, .heartRateZones, .speed, .segments, .route, .events]
        case .other:
            return [.main, .metadata, .heartRate, .heartRateZones, .speed, .segments, .events]
        }
    }
    func toHKWorkoutActivityType() -> HKWorkoutActivityType {
        switch self {
        case .running:
            return .running
        case .cycling:
            return .cycling
        case .walking:
            return .walking
        case .hiking:
            return .hiking
        case .swimming:
            return .swimming
        case .other:
            return .other
        }
    }
}
