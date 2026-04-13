// MemoryHomeView.swift
// Eventa – Memories tab with event-category cards, creation dates, and sorting

// Created By Harshit

// MemoryHomeView.swift
// Eventa – Memories tab with event-category cards, creation dates, and sorting

import SwiftUI

struct MemoryHomeView: View {
    var appState: AppState
    @State private var showNewFolderPrompt = false
    @State private var newFolderName = ""
    @State private var newFolderEmoji = "📸"
    @State private var selectedFolder: MemoryFolder? = nil
    @State private var sortOrder: EventSortOrder = .dateNewest
    @State private var selectedCategory: EventCategory? = nil

    let emojiOptions = ["📸","🎂","🎉","🎄","🎃","🌸","💍","🎓","🏖️","🌟"]

    // Map memory folders to event categories via linked events
    private func eventCategory(for folder: MemoryFolder) -> EventCategory? {
        appState.events.first { $0.memoryFolderID == folder.id }?.category
    }

    private var sortedFolders: [MemoryFolder] {
        let folders = appState.memoryFolders
        switch sortOrder {
        case .dateNewest:
            return folders.sorted { $0.createdAt > $1.createdAt }
        case .dateOldest:
            return folders.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical:
            return folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .reverseAlphabetical:
            return folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
    }

    // Active categories that have memory folders
    private var activeCategories: [EventCategory] {
        EventCategory.allCases.filter { cat in
            appState.memoryFolders.contains { folder in
                eventCategory(for: folder) == cat
            }
        }
    }

    // Folders not linked to any event
    private var uncategorizedFolders: [MemoryFolder] {
        sortedFolders.filter { eventCategory(for: $0) == nil }
    }

    private func foldersFor(category: EventCategory) -> [MemoryFolder] {
        sortedFolders.filter { eventCategory(for: $0) == category }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.memoryFolders.isEmpty {
                    ContentUnavailableView {
                        Label("No Memory Folders", systemImage: "photo.stack.fill")
                    } description: {
                        Text("Tap + to create a folder and start saving photos & videos from your events.")
                    }
                } else if selectedCategory != nil {
                    // Show folders for selected category
                    memoryFolderList(folders: foldersFor(category: selectedCategory!))
                } else {
                    // Show category cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if !activeCategories.isEmpty {
                                let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(activeCategories, id: \.self) { cat in
                                        Button {
                                            selectedCategory = cat
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Image(systemName: cat.systemIcon)
                                                        .font(.system(size: 28))
                                                        .foregroundStyle(Color.accentColor)
                                                    Text(cat.rawValue)
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundStyle(Color(.label))
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(Color(.tertiaryLabel))
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(16)
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Uncategorized folders
                            if !uncategorizedFolders.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Other Memories")
                                        .font(.headline)
                                    ForEach(uncategorizedFolders) { folder in
                                        NavigationLink(destination: MemoryFolderView(appState: appState, folder: folder)) {
                                            memoryFolderRow(folder: folder)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Memories")
            .toolbar {
                if selectedCategory != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation { selectedCategory = nil }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }
            .alert("New Memory Folder", isPresented: $showNewFolderPrompt) {
                TextField("Folder Name", text: $newFolderName)
                Button("Create") {
                    guard !newFolderName.isEmpty else { return }
                    let folder = MemoryFolder(name: newFolderName, emoji: newFolderEmoji)
                    withAnimation { appState.memoryFolders.append(folder) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a name for this memory folder.")
            }
        }
    }

    // MARK: - Folder List for a given category
    private func memoryFolderList(folders: [MemoryFolder]) -> some View {
        List {
            ForEach(folders) { folder in
                NavigationLink(destination: MemoryFolderView(appState: appState, folder: folder)) {
                    memoryFolderRow(folder: folder)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Memory Folder Row with creation date
    private func memoryFolderRow(folder: MemoryFolder) -> some View {
        HStack(spacing: 14) {
            Text(folder.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(.systemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(folder.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    Text("\(folder.items.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(folder.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MemoryHomeView(appState: AppState.shared)
}
