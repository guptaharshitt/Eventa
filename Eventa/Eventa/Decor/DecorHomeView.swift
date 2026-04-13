//
//  DecorHomeView.swift
//  Eventa
//
//  Created by Nikhil on 13/04/26.
//

import SwiftUI

struct DecorHomeView: View {
    var appState: AppState
    var activeEvent: Event? = nil
    var onDecorSelected: (() -> Void)? = nil

    @State private var selectedCategory: DecorCategory? = nil
    @State private var searchText = ""
    @State private var previewTheme: DecorTheme? = nil
    @State private var arPreviewTheme: DecorTheme? = nil
    @State private var showOnlyLiked = false


    private var eventRelevantCategories: [DecorCategory] {
        activeEvent?.category.relevantDecorCategories ?? DecorCategory.allCases
    }

    private var filteredThemes: [DecorTheme] {
        var themes = DecorTheme.allThemes
        if showOnlyLiked {
            themes = themes.filter { appState.isLiked($0) }
        }
        if let cat = selectedCategory {
            themes = themes.filter { $0.category == cat }
        }
        if !searchText.isEmpty { themes = themes.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return themes
    }

    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Event context banner
                    if let event = activeEvent {
                        HStack(spacing: 12) {
                            Text(event.category.icon).font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Decors for \(event.name)")
                                    .font(.subheadline.weight(.semibold))
                                Text("Showing \(event.category.rawValue.lowercased())-themed suggestions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Spacer().frame(width: 8)
                            categoryChip(label: "Liked", icon: "heart.fill", isSelected: showOnlyLiked)
                                .onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) { showOnlyLiked.toggle() }
                                }
                            categoryChip(label: "All", icon: "square.grid.2x2.fill", isSelected: !showOnlyLiked && selectedCategory == nil)
                                .onTapGesture { withAnimation(.spring(duration: 0.3)) { showOnlyLiked = false; selectedCategory = nil } }
                            ForEach(DecorCategory.allCases) { cat in
                                categoryChip(label: cat.rawValue, icon: cat.icon, isSelected: selectedCategory == cat)
                                    .onTapGesture {
                                        withAnimation(.spring(duration: 0.3)) {
                                            selectedCategory = selectedCategory == cat ? nil : cat
                                        }
                                    }
                            }
                            Spacer().frame(width: 8)
                        }
                    }

                    // Theme grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredThemes) { theme in
                            NavigationLink(destination: ThemeDetailView(theme: theme, appState: appState, activeEvent: activeEvent, onSelect: onDecorSelected)) {
                                DecorThemeCard(
                                    theme: theme,
                                    appState: appState,
                                    activeEvent: activeEvent,
                                    onPreviewTapped: { previewTheme = theme },
                                    onARTapped: { arPreviewTheme = theme }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Decor Themes")
            .searchable(text: $searchText, prompt: "Search themes…")
        }
        .sheet(item: $previewTheme) { theme in
            DecorImagePreviewView(theme: theme, appState: appState, activeEvent: activeEvent)
        }
        .fullScreenCover(item: $arPreviewTheme) { theme in
            DecorARContainerView(themeName: theme.name, imageName: theme.imageName)
        }
    }

    private func categoryChip(label: String, icon: String, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption.bold())
            Text(label).font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        .foregroundStyle(isSelected ? .white : Color(.label))
        .clipShape(Capsule())
    }
}

// MARK: - Theme Card
struct DecorThemeCard: View {
    let theme: DecorTheme
    var appState: AppState
    var activeEvent: Event? = nil
    var onPreviewTapped: () -> Void
    var onARTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner
            ZStack(alignment: .bottomLeading) {
                if let imgName = theme.imageName, let uiImg = UIImage(named: imgName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                } else {
                    theme.category.gradient
                        .frame(height: 140)
                    Image(systemName: theme.category.icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 12)
                }

                LinearGradient(colors: [Color.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .center)
                Text(theme.category.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1.2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                // Top-right buttons: like + action buttons
                VStack {
                    HStack(spacing: 8) {
                        Spacer()
                        // Like button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if let event = activeEvent {
                                    appState.likeTheme(theme, forEvent: event)
                                } else {
                                    appState.toggleLike(theme)
                                }
                            }
                        } label: {
                            Image(systemName: appState.isLiked(theme) ? "heart.fill" : "heart")
                                .font(.caption.bold())
                                .foregroundColor(appState.isLiked(theme) ? .pink : .white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        if theme.imageName != nil {
                            Button { onARTapped() } label: {
                                Image(systemName: "arkit")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            Button { onPreviewTapped() } label: {
                                Image(systemName: "eye.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(8)
                    Spacer()
                }
            }
            .frame(height: 140)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0,
                                              bottomTrailingRadius: 0, topTrailingRadius: 16))

            // Info Row (no like button here anymore)
            VStack(alignment: .leading, spacing: 3) {
                Text(theme.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                Text(theme.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16,
                                              bottomTrailingRadius: 16, topTrailingRadius: 0))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Full-screen Image Preview
struct DecorImagePreviewView: View {
    let theme: DecorTheme
    var appState: AppState
    var activeEvent: Event? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let imgName = theme.imageName, let uiImg = UIImage(named: imgName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    theme.category.gradient.ignoresSafeArea()
                }
            }
            .navigationTitle(theme.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if let event = activeEvent {
                                appState.likeTheme(theme, forEvent: event)
                            } else {
                                appState.toggleLike(theme)
                            }
                        }
                    } label: {
                        Image(systemName: appState.isLiked(theme) ? "heart.fill" : "heart")
                            .foregroundColor(appState.isLiked(theme) ? .pink : .white)
                    }
                }
            }
        }
    }
}

#Preview {
    DecorHomeView(appState: AppState.shared)
}
