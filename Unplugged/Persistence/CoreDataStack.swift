import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    private init() {
        container = NSPersistentContainer(name: "Unplugged")

        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.suiteName)?
            .appendingPathComponent("Unplugged.sqlite")

        if let storeURL {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let ctx = viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            assertionFailure("CoreData save failed: \(error)")
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
