//
//  PersistentContainer.swift
//  HaloCoreData
//
//  Created by Danny Murphy on 5/13/21.
//

import Foundation
import CoreData

open class PersistentContainer: NSPersistentContainer {

    let sqliteBaseURL: URL

    lazy var sqliteFileURL: URL = {
        sqliteBaseURL.appendingPathComponent(name.appending(".sqlite"))
    }()

    init(name: String, managedObjectModel: NSManagedObjectModel, sqliteBaseURL: URL = PersistentContainer.defaultDirectoryURL()) {
        self.sqliteBaseURL = sqliteBaseURL
        super.init(name: name, managedObjectModel: managedObjectModel)
    }

}

open class Persistent {

    public enum StorageType {
        case persistent, inMemory
    }

    public enum BundleType {
        case main
        case module

        public var bundle: Bundle {
            switch self {
                case .main:
                    return Bundle.main
                case .module:
                    return Bundle.module
            }
        }
    }

    let modelName: String
    let modelExtension: String
    let bundleType: BundleType
    let storageType: StorageType


    public init(modelName: String, modelExtension: String = "momd",
                bundleType: BundleType = .main,
                storageType: StorageType = .persistent) {

        self.modelName = modelName
        self.modelExtension = modelExtension
        self.bundleType = bundleType
        self.storageType = storageType

    }

    lazy public var container: PersistentContainer? =  {
        guard let modelURL = bundleType.bundle.url(forResource: modelName, withExtension: modelExtension) else {
            return  nil
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            return nil
        }


        let container = PersistentContainer(name: self.modelName, managedObjectModel: model)
        var persistentStoreDescription: NSPersistentStoreDescription

        /*: Note

         /dev/null is the currently preferred way to create an in-memory store. Apple talks about
         this in WWDC 2018 (https://developer.apple.com/videos/play/wwdc2018/224/)

         */

        switch storageType {

            case .persistent:
                persistentStoreDescription = NSPersistentStoreDescription(url: container.sqliteFileURL)
                persistentStoreDescription.shouldMigrateStoreAutomatically = true
                persistentStoreDescription.shouldInferMappingModelAutomatically = true
            case .inMemory:
                persistentStoreDescription = NSPersistentStoreDescription()
                persistentStoreDescription.url = URL(fileURLWithPath: "/dev/null")
        }


        container.persistentStoreDescriptions = [persistentStoreDescription]


        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()


}




