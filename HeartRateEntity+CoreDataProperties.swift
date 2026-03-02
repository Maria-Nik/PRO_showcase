//
//  HeartRateEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 01.06.2025.
//
//

import Foundation
import CoreData


extension HeartRateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeartRateEntity> {
        return NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
    }

    @NSManaged public var bpm: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var workout: WorkoutEntity?

}

extension HeartRateEntity : Identifiable {

}
