//  PersistantContainerTests.swift
//  HaloCoreData
//
//  Created by Danny Murphy on 4/24/21.
//

import XCTest
import CoreData
@testable import HaloCoreData

final class PersistantContainerTests: XCTestCase {

    override class func setUp() {

        // copy sqlite store to proper location.  This is a class setup since it only needs to be done 1 once at the beginning of this test suite

        let sqliteFile = Resource(name: "userModel", type: "sqlite")
        if let sqliteFileURL = sqliteFile.getDataURL() {

            let newLocation = PersistentContainer.defaultDirectoryURL().appendingPathComponent(sqliteFile.fullName())

            try? FileManager.default.removeItem(at: newLocation )
            do {
                try FileManager.default.copyItem(atPath: sqliteFileURL.path, toPath: newLocation.path)
            } catch let error {
                XCTFail("Setup failed for CoreDataManagerTest: \(error)")
            }
        }

    }

    override func tearDown() {

        // this is an instance teardown to remove any rows added/updated during testing.

        let myPersistent = Persistent(modelName: "userModel", bundleType: .module)

        XCTAssertNotNil(myPersistent.container)

        let container = myPersistent.container!

        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let firstNamePredicate = NSPredicate(format: "firstName != %@", "Bob")
        let lastNamePredicate = NSPredicate(format: "lastName != %@", "Evans")
        let dobPredicate = NSPredicate(format:"dob != %@", Date(timeIntervalSince1970: 0) as NSDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [firstNamePredicate, lastNamePredicate, dobPredicate])
        fetch.predicate = compoundPredicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)

        do {
            try container.viewContext.execute(request)
        } catch let error {
            print(error.localizedDescription)
        }

    }


    func testInitialization() {

        let myPersistent = Persistent(modelName: "userModel", storageType: .inMemory)
        let myPersistentWithExtension = Persistent(modelName: "userModel", modelExtension: "momd_copy", bundleType: .module)


        XCTAssertEqual(myPersistent.modelName, "userModel")
        XCTAssertEqual(myPersistentWithExtension.modelName, "userModel")

        XCTAssertEqual(myPersistent.modelExtension, "momd")
        XCTAssertEqual(myPersistentWithExtension.modelExtension, "momd_copy")

        XCTAssertEqual(myPersistent.bundleType, .main)
        XCTAssertEqual(myPersistentWithExtension.bundleType, .module)

        XCTAssertEqual(myPersistent.storageType, .inMemory)
        XCTAssertEqual(myPersistentWithExtension.storageType, .persistent)


    }

    func testContainer() {

        let myPersistent = Persistent(modelName: "userModel", bundleType: .module)

        XCTAssertNotNil(myPersistent.container)

        let container = myPersistent.container!

        if let userEntity = NSEntityDescription.entity(forEntityName: "User", in: container.viewContext) {
            XCTAssertTrue(container.managedObjectModel.entities.contains(userEntity))
        } else {
            XCTFail("Should have had User NSEntityDescription")
        }

    }

    func testContainerInMemory() {
        let myPersistent = Persistent(modelName: "userModel", bundleType: .module, storageType: .inMemory)

        XCTAssertNotNil(myPersistent.container)

        XCTAssertEqual("file:///dev/null", myPersistent.container?.persistentStoreDescriptions.first?.url?.absoluteString)

    }

    func testUserExistsInPrepopulated() {

        let myPersistent = Persistent(modelName: "userModel", bundleType: .module)

        XCTAssertNotNil(myPersistent.container)

        let container = myPersistent.container!

        let request: NSFetchRequest<User> = NSFetchRequest(entityName: "User")

        do {
            let result =  try container.viewContext.fetch(request)
            XCTAssertNotNil(result.first)

            XCTAssertTrue(result.count == 1)

            let bobUser = result.first!

            XCTAssertEqual("Bob", bobUser.firstName)
            XCTAssertEqual("Evans", bobUser.lastName)
            XCTAssertEqual(true, bobUser.isActive)
            XCTAssertEqual(Date(timeIntervalSince1970: 0), bobUser.dob)

        } catch let error {
            XCTFail("Error fetching user \(error)")
        }

    }

    func testLoad_10_000_UsersInMemory() {
        let userPersistentModel = Persistent(modelName: "userModel", bundleType: .module, storageType: .inMemory)
        XCTAssertNotNil(userPersistentModel.container)

        let container = userPersistentModel.container!

        measure {
            UserHelper.addUser(total: 10_000, in: container.viewContext)
        }


        do {
            try container.viewContext.save()
        } catch let error {
            XCTFail("Error saving users: \(error)")
        }

        let request: NSFetchRequest<User> = NSFetchRequest(entityName: "User")

        do {
            let result =  try container.viewContext.fetch(request)
            XCTAssertEqual(100_000, result.count)
        } catch let error {
            XCTFail("Error fetching users \(error)")
        }


    }

    func testLoad_10_000_UsersToDisk() {
        let userPersistentModel = Persistent(modelName: "userModel", bundleType: .module, storageType: .persistent)
        XCTAssertNotNil(userPersistentModel.container)

        let container = userPersistentModel.container!

        measure {
            UserHelper.addUser(total: 10_000, in: container.viewContext)
        }


        do {
            try container.viewContext.save()
        } catch let error {
            XCTFail("Error saving users: \(error)")
        }

        let request: NSFetchRequest<User> = NSFetchRequest(entityName: "User")

        do {
            let result =  try container.viewContext.fetch(request)
            // there will be the intial preload "Bob Evans" user so need to add 1
            XCTAssertEqual(100_000 + 1, result.count)
        } catch let error {
            XCTFail("Error fetching users \(error)")
        }


    }

}
