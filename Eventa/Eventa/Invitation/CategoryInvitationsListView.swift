// CategoryInvitationsListView.swift
// Eventa – Shows invitations for a specific category with sorting

import SwiftUI

struct CategoryInvitationsListView: View {
    var appState: AppState
    var category: EventCategory
    @State private var sortOrder: EventSortOrder = .dateNewest

    private var filteredInvitations: [SavedInvitationPreview] {
        let invitations = appState.savedInvitations.filter { $0.eventCategory == category }
        switch sortOrder {
        case .dateNewest:
            return invitations.sorted { $0.createdAt > $1.createdAt }
        case .dateOldest:
            return invitations.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical:
            return invitations.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .reverseAlphabetical:
            return invitations.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredInvitations) { inv in
                    NavigationLink(destination: FullscreenInvitationPreview(appState: appState, preview: inv)) {
                        SavedInvitationCell(appState: appState, preview: inv)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(category.icon) \(category.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(EventSortOrder.allCases, id: \.self) { order in
                        Button {
                            withAnimation { sortOrder = order }
                        } label: {
                            Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : order.icon)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryInvitationsListView(appState: AppState.shared, category: .birthday)
    }
}
