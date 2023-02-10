import CoreData
import Models
import Network
import SwiftUI

public actor TimelineCache {
  public static let shared: TimelineCache = .init()

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

    private let viewContext: NSManagedObjectContext

  private init() {
      viewContext = CoreDataStack().viewContext
  }

    private func predicate(for client: Client) -> NSPredicate {
        NSPredicate(format: "statusId == %@", client.id)
    }

  public func cachedPostsCount(for client: Client) -> Int {
      let request = CachedStatus.fetchRequest()
      request.predicate = predicate(for: client)

      do {
          return try viewContext.count(for: request)
      } catch {
          print("Error counting status cache")
          return 0
      }
  }

  public func clearCache(for client: Client) {
      let request = CachedStatus.fetchRequest()
      request.predicate = predicate(for: client)
      request.includesPropertyValues = false

      do {
          let statuses = try viewContext.fetch(request)
          for status in statuses {
              viewContext.delete(status)
          }
          try viewContext.save()
      } catch {
          print("Error deleting status cache", error)
      }
  }

  func set(statuses: [Status], client: Client) async {
    guard !statuses.isEmpty else { return }
    let statuses = statuses.prefix(upTo: min(400, statuses.count - 1)).map { $0 }
    do {
        clearCache(for: client)
        for status in statuses {
            let cachedStatus = CachedStatus(context: viewContext)
            cachedStatus.clientId = client.id
            cachedStatus.status = try encoder.encode(status)
        }
        try viewContext.save()
    } catch {
        print("Error saving status cache", error)
    }
  }

  func getStatuses(for client: Client) async -> [CachedStatus]? {
      let request = CachedStatus.fetchRequest()
      request.predicate = predicate(for: client)
      request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedStatus.clientId, ascending: true)]

      return try? viewContext.fetch(request)
  }

  func setLatestSeenStatuses(ids: [String], for client: Client) {
    UserDefaults.standard.set(ids, forKey: "timeline-last-seen-\(client.id)")
  }

  func getLatestSeenStatus(for client: Client) -> [String]? {
    UserDefaults.standard.array(forKey: "timeline-last-seen-\(client.id)") as? [String]
  }
}
