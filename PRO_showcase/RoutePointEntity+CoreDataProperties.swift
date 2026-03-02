//
//  RoutePointEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 01.06.2025.
//
//

import Foundation
import CoreData


extension RoutePointEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoutePointEntity> {
        return NSFetchRequest<RoutePointEntity>(entityName: "RoutePointEntity")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var altitude: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var workout: WorkoutEntity?

}

extension RoutePointEntity : Identifiable {

}
