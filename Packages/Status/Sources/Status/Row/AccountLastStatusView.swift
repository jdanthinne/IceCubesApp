import DesignSystem
import EmojiText
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct AccountLastStatusView: View {
    @Environment(\.redactionReasons) private var reasons
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var client: Client
    @EnvironmentObject private var routerPath: RouterPath
    @StateObject var viewModel: StatusRowViewModel

    public init(viewModel: StatusRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var contextMenu: some View {
        StatusRowContextMenu(viewModel: viewModel)
    }

    public var body: some View {
        if viewModel.isFiltered, let filter = viewModel.filter {
            switch filter.filter.filterAction {
            case .warn:
                Text("status.filter.filtered-by-\(filter.filter.title)")
            case .hide:
                EmptyView()
            }
        } else {
            HStack(spacing: .statusColumnsSpacing) {
                AvatarView(url: viewModel.status.account.avatar, size: .status)
                statusView
            }
            .onTapGesture(perform: navigateToAccount)
            .onAppear {
                if reasons.isEmpty {
                    viewModel.client = client
                    if preferences.autoExpandSpoilers == true && viewModel.displaySpoiler {
                        viewModel.displaySpoiler = false
                    }
                }
            }
            .listRowBackground(viewModel.highlightRowColor)
            .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
            .accessibilityAction {
                navigateToAccount()
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                -100
            }
        }
    }

    private func navigateToAccount() {
        routerPath.navigate(to: .accountDetail(id: viewModel.status.account.id, statusesOnly: true))
        viewModel.onAccountShown?(viewModel.status.account.id)
    }

    @ViewBuilder
    private var reblogView: some View {
      if let reblog = viewModel.status.reblog {
        HStack(spacing: 2) {
          Image(systemName: "arrow.left.arrow.right.circle.fill")
          AvatarView(url: reblog.account.avatar, size: .boost)
          EmojiTextApp(.init(stringValue: reblog.account.safeDisplayName), emojis: reblog.account.emojis)
        }
        .accessibilityElement()
        .accessibilityLabel(
          Text(reblog.account.safeDisplayName)
        )
        .font(.scaledFootnote)
        .foregroundColor(.gray)
        .fontWeight(.semibold)
      }
    }

    private var statusView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let status: AnyStatus = viewModel.status.reblog ?? viewModel.status {
                HStack(alignment: .firstTextBaseline) {
                    EmojiTextApp(.init(stringValue: viewModel.status.account.safeDisplayName),
                                 emojis: viewModel.status.account.emojis)
                    .font(.scaledSubheadline)
                    .fontWeight(.semibold)
                    .accessibilityElement()
                    .accessibilityLabel(Text("\(viewModel.status.account.displayName)"))
                    Spacer()
                    Text(status.createdAt.relativeFormatted)
                    .font(.scaledFootnote)
                    .foregroundColor(.gray)

                    Image(systemName: "chevron.forward")
                        .font(.scaledFootnote.bold())
                        .foregroundColor(Color(.systemGray3))
                }
                reblogView
                makeStatusContentView(status: status)
            }
        }
        .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
    }

    private func makeStatusContentView(status: AnyStatus) -> some View {
        Group {
            if !status.spoilerText.asRawText.isEmpty {
                HStack(alignment: .top) {
                    Text("⚠︎")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundColor(.secondary)
                    EmojiTextApp(status.spoilerText, emojis: status.emojis, language: status.language)
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            if !viewModel.displaySpoiler {
                Text(status.content.asRawText)
                    .font(.scaledSubheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}
