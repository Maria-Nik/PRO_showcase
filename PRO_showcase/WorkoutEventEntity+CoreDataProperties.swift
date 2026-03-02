//
//  WorkoutEventEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 01.06.2025.
//
//

import Foundation
import CoreData


extension WorkoutEventEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEventEntity> {
        return NSFetchRequest<WorkoutEventEntity>(entityName: "WorkoutEventEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var workout: WorkoutEntity?

}

extension WorkoutEventEntity : Identifiable {

}
