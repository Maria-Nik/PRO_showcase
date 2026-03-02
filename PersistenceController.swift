//
//  PersistenceController.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 25.05.2025.
//
import SwiftUI
import CoreData

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    static let preview: PersistenceController = {
            let result = PersistenceController()
            let viewContext = result.container.viewContext
            // Создайте тестовые данные, если необходимо
            return result
        }()
    
    private init() {
        container = NSPersistentContainer(name: "WorkoutModel")
        container.loadPersistentStores { [self] description, error in
            if let error = error {
                fatalError("Ошибка: \(error)")
            }
            // Исправленная проверка
            let model = container.managedObjectModel
            if let workoutEntity = model.entitiesByName["WorkoutEntity"] {
                print("WorkoutEntity найдена: \(workoutEntity)")
            } else {
                fatalError("WorkoutEntity не найдена в модели")
            }
        }
    }
    func getAllWorkouts() -> [WorkoutEntity] {
            let request = WorkoutEntity.fetchRequest()
            return try! container.viewContext.fetch(request)
        }
    
    // MARK: - Chat History Support
    
    /// Save context with error handling
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Get view context
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}
