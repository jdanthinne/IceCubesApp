//
//  CoreDataStack.swift
//  
//
//  Created by Jérôme Danthinne on 08/02/2023.
//

import CoreData

class CoreDataStack {
    static let preview = CoreDataStack(inMemory: true)

    let viewContext: NSManagedObjectContext

    private let modelName: String = "IceCubesDB"

    init(inMemory: Bool = false) {
        // Create NSPersistentContainer
        guard let modelURL = Bundle(for: Self.self).url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Unable to get CoreData model")
        }

        let persistentContainer = NSPersistentContainer(name: modelName,
                                                        managedObjectModel: model)

        // Create NSPersistentStoreDescription based on disk or memory for preview/testing
        let storeDescription: NSPersistentStoreDescription
        if inMemory {
            storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
            storeDescription.shouldAddStoreAsynchronously = false
        } else {
            guard let appSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                  in: .userDomainMask).first
            else {
                fatalError("Unable to get Library directory")
            }

            let storeURL = appSupportFolder.appendingPathComponent("\(modelName).sqlite")
            storeDescription = NSPersistentStoreDescription(url: storeURL)
        }
        persistentContainer.persistentStoreDescriptions = [storeDescription]

        // Load the NSPersistentContainer
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load with error: \(error)")
            }
        }

        // Get NSManagedObjectContext
        viewContext = persistentContainer.viewContext

        // Merge changes
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
    }
}
