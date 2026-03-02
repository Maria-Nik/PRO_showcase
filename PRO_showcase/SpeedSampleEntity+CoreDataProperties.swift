//
//  SpeedSampleEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 01.06.2025.
//
//

import Foundation
import CoreData


extension SpeedSampleEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SpeedSampleEntity> {
        return NSFetchRequest<SpeedSampleEntity>(entityName: "SpeedSampleEntity")
    }

    @NSManaged public var speed: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var workout: WorkoutEntity?

}

extension SpeedSampleEntity : Identifiable {

}
