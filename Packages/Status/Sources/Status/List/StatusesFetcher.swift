import Models
import SwiftUI
import OrderedCollections

public enum StatusesState {
  public enum PagingState {
    case hasNextPage, loadingNextPage, none
  }

  case loading
  case display(statuses: [Status], nextPageState: StatusesState.PagingState)
  case error(error: Error)
}

@MainActor
public protocol StatusesFetcher: ObservableObject {
  var statusesState: StatusesState { get }
    var statusesByAccountState: StatusesState { get }
  func fetchStatuses() async
  func fetchNextPage() async
  func statusDidAppear(status: Status)
  func statusDidDisappear(status: Status)
}

public extension StatusesFetcher {
    var statusesByAccountState: StatusesState {
        switch statusesState {
        case .loading, .error:
            return statusesState
        case let .display(statuses, _):
            let accountIds = OrderedSet(statuses.map(\.account.id))
            let firstStatuses = accountIds
                .compactMap { accountId in
                    statuses.first(where: { $0.account.id == accountId })
                }
            return .display(statuses: firstStatuses, nextPageState: .none)
        }
    }
}
