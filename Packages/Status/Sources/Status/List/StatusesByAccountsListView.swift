import DesignSystem
import Env
import Models
import Shimmer
import SwiftUI

public struct StatusesByAccountsListView<Fetcher>: View where Fetcher: StatusesFetcher {
  @EnvironmentObject private var theme: Theme

  @ObservedObject private var fetcher: Fetcher
  private let hasPendingStatuses: (_ accountId: String) -> Bool
  private let onAccountShown: (_ accountId: String) -> Void

  public init(fetcher: Fetcher,
              hasPendingStatuses: @escaping (_ accountId: String) -> Bool,
              onAccountShown: @escaping (_ accountId: String) -> Void) {
    self.fetcher = fetcher
    self.hasPendingStatuses = hasPendingStatuses
    self.onAccountShown = onAccountShown
  }

  public var body: some View {
    switch fetcher.statusesByAccountState {
    case .loading:
      ForEach(Status.placeholders()) { status in
          AccountLastStatusView(viewModel: .init(status: status, isCompact: false))
          .redacted(reason: .placeholder)
          .listRowBackground(theme.primaryBackgroundColor)
          .listRowInsets(.init(top: 12,
                               leading: .layoutPadding,
                               bottom: 12,
                               trailing: .layoutPadding))
      }
    case .error:
      ErrorView(title: "status.error.title",
                message: "status.error.loading.message",
                buttonTitle: "action.retry") {
        Task {
          await fetcher.fetchStatuses()
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)

    case let .display(statuses, nextPageState):
      ForEach(statuses, id: \.viewId) { status in
        let viewModel = StatusRowViewModel(status: status, isCompact: false, onAccountShown: onAccountShown)
        if viewModel.filter?.filter.filterAction != .hide {
            AccountLastStatusView(viewModel: viewModel)
            .id(status.id)
            .listRowBackground(theme.primaryBackgroundColor)
            .listRowInsets(.init(top: 12,
                                 leading: .layoutPadding,
                                 bottom: 12,
                                 trailing: .layoutPadding))
            .overlay(alignment: .leading) {
                if hasPendingStatuses(status.account.id) {
                    Circle()
                        .fill(theme.tintColor)
                        .frame(width: 10, height: 10)
                        .offset(x: -14)
                }
            }
            .onAppear {
              fetcher.statusDidAppear(status: status)
            }
            .onDisappear {
              fetcher.statusDidDisappear(status: status)
            }
        }
      }
      switch nextPageState {
      case .hasNextPage:
        loadingRow
          .onAppear {
            Task {
              await fetcher.fetchNextPage()
            }
          }
      case .loadingNextPage:
        loadingRow
      case .none:
        EmptyView()
      }
    }
  }

  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .padding(.horizontal, .layoutPadding)
    .listRowBackground(theme.primaryBackgroundColor)
  }
}
