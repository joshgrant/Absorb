//
// Created by Joshua Grant on 10/10/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import CoreData

public class Database {
    
    static let container: NSPersistentContainer = {
        let persistentContainer = NSPersistentContainer(name: "Model")
        
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
            }
            print("Core Data stack has been initialized with description: \(storeDescription)")
        }
        
        return persistentContainer
    }()
    
    static var model: NSManagedObjectModel {
        container.managedObjectModel
    }
    
    static var context: NSManagedObjectContext {
        container.viewContext
    }
    
    public static var topScore: Score? {
        
        let fetchRequest: NSFetchRequest<Score> = Score.fetchRequest()
        fetchRequest.sortDescriptors = [.init(key: "score", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        return try? context.fetch(fetchRequest).first
    }
    
    public static var topTenScores: [Score] {
        let fetchRequest: NSFetchRequest<Score> = Score.fetchRequest()
        fetchRequest.sortDescriptors = [.init(key: "score", ascending: false)]
        fetchRequest.fetchLimit = 10
        return (try? context.fetch(fetchRequest)) ?? []
    }
}
