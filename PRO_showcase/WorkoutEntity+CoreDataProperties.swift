//
//  WorkoutEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 01.06.2025.
//
//

import Foundation
import CoreData


extension WorkoutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        return NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }

    @NSManaged public var averageHeartRate: Double
    @NSManaged public var averageSpeed: Double
    @NSManaged public var cadenceCycle: Double
    @NSManaged public var cadenceRun: Double
    @NSManaged public var cyclingPower: Double
    @NSManaged public var deviceName: String?
    @NSManaged public var duration: Double
    @NSManaged public var endDate: Date?
    @NSManaged public var maxHeartRate: Double
    @NSManaged public var maxSpeed: Double
    @NSManaged public var metadata: Data?
    @NSManaged public var pace: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var totalDistance: Double
    @NSManaged public var totalEnergyBurned: Double
    @NSManaged public var uuid: UUID?
    @NSManaged public var workoutType: String?
    @NSManaged public var bonusScore: Double
    @NSManaged public var heartRateSamples: NSSet?
    @NSManaged public var routePoints: NSSet?
    @NSManaged public var speedSamples: NSSet?
    @NSManaged public var workoutEvents: NSSet?

}

// MARK: Generated accessors for heartRateSamples
extension WorkoutEntity {

    @objc(addHeartRateSamplesObject:)
    @NSManaged public func addToHeartRateSamples(_ value: HeartRateEntity)

    @objc(removeHeartRateSamplesObject:)
    @NSManaged public func removeFromHeartRateSamples(_ value: HeartRateEntity)

    @objc(addHeartRateSamples:)
    @NSManaged public func addToHeartRateSamples(_ values: NSSet)

    @objc(removeHeartRateSamples:)
    @NSManaged public func removeFromHeartRateSamples(_ values: NSSet)

}

// MARK: Generated accessors for routePoints
extension WorkoutEntity {

    @objc(addRoutePointsObject:)
    @NSManaged public func addToRoutePoints(_ value: RoutePointEntity)

    @objc(removeRoutePointsObject:)
    @NSManaged public func removeFromRoutePoints(_ value: RoutePointEntity)

    @objc(addRoutePoints:)
    @NSManaged public func addToRoutePoints(_ values: NSSet)

    @objc(removeRoutePoints:)
    @NSManaged public func removeFromRoutePoints(_ values: NSSet)

}

// MARK: Generated accessors for speedSamples
extension WorkoutEntity {

    @objc(addSpeedSamplesObject:)
    @NSManaged public func addToSpeedSamples(_ value: SpeedSampleEntity)

    @objc(removeSpeedSamplesObject:)
    @NSManaged public func removeFromSpeedSamples(_ value: SpeedSampleEntity)

    @objc(addSpeedSamples:)
    @NSManaged public func addToSpeedSamples(_ values: NSSet)

    @objc(removeSpeedSamples:)
    @NSManaged public func removeFromSpeedSamples(_ values: NSSet)

}

// MARK: Generated accessors for workoutEvents
extension WorkoutEntity {

    @objc(addWorkoutEventsObject:)
    @NSManaged public func addToWorkoutEvents(_ value: WorkoutEventEntity)

    @objc(removeWorkoutEventsObject:)
    @NSManaged public func removeFromWorkoutEvents(_ value: WorkoutEventEntity)

    @objc(addWorkoutEvents:)
    @NSManaged public func addToWorkoutEvents(_ values: NSSet)

    @objc(removeWorkoutEvents:)
    @NSManaged public func removeFromWorkoutEvents(_ values: NSSet)

}

extension WorkoutEntity : Identifiable {

}
