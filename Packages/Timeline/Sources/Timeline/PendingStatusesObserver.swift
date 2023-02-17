import Env
import Foundation
import Models
import SwiftUI

@MainActor
class PendingStatusesObserver: ObservableObject {
  @Published var pendingStatusesCount: Int = 0

  var disableUpdate: Bool = false
  var scrollToIndex: ((Int) -> Void)?

  var pendingStatuses: [PendingStatus] = [] {
    didSet {
      pendingStatusesCount = pendingStatuses.count
    }
  }

  func removeStatus(status: Status) {
    if !disableUpdate, let index = pendingStatuses.map(\.statusId).firstIndex(of: status.id) {
      pendingStatuses.removeSubrange(index ... (pendingStatuses.count - 1))
      HapticManager.shared.fireHaptic(of: .timeline)
    }
  }

  func removeStatuses(withAccountId accountId: String) {
    if !disableUpdate {
      pendingStatuses.removeAll { $0.accountId == accountId }
    }
  }

  func hasPendingStatutes(accountId: String) -> Bool {
    pendingStatuses.first(where: { $0.accountId == accountId }) != nil
  }

  init() {}
}

struct PendingStatusesObserverView: View {
  @ObservedObject var observer: PendingStatusesObserver

  var body: some View {
    if observer.pendingStatusesCount > 0 {
      HStack(spacing: 6) {
        Spacer()
        Button {
          observer.scrollToIndex?(observer.pendingStatusesCount)
        } label: {
          Text("\(observer.pendingStatusesCount)")
        }
        .buttonStyle(.bordered)
        .background(.thinMaterial)
        .cornerRadius(8)
      }
      .padding(12)
    }
  }
}
