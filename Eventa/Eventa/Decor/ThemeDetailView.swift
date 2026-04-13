//
//  ThemeDetailView.swift
//  Eventa
//
//  Created by Nikhil on 13/04/26.
//

import SwiftUI

struct ThemeDetailView: View {
    let theme: DecorTheme
    var appState: AppState
    var activeEvent: Event? = nil
    var onSelect: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePreview = false
    @State private var showAR = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroBanner
                contentSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(theme.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
        }
        .sheet(isPresented: $showImagePreview) {
            DecorImagePreviewView(theme: theme, appState: appState)
        }
        .fullScreenCover(isPresented: $showAR) {
            DecorARContainerView(themeName: theme.name, imageName: theme.imageName)
        }
    }

    // MARK: - Hero Image
    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            if let imgName = theme.imageName, let uiImg = UIImage(named: imgName) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()
            } else {
                theme.category.gradient.frame(height: 260)
                Image(systemName: theme.category.icon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white.opacity(0.15))
            }

            LinearGradient(colors: [Color.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(theme.category.rawValue.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .tracking(1.5)
                Text(theme.tagline)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            if theme.imageName != nil {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                appState.toggleLike(theme)
                            }
                        } label: {
                            Image(systemName: appState.isLiked(theme) ? "heart.fill" : "heart")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(appState.isLiked(theme) ? .pink : .white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(10)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(height: 260)
        .onTapGesture {
            if theme.imageName != nil { showImagePreview = true }
        }
    }

    // MARK: - Content
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Label("About This Theme", systemImage: "text.alignleft")
                    .font(.headline)
                Text(theme.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Materials Required
            VStack(alignment: .leading, spacing: 10) {
                Label("Materials Required", systemImage: "list.bullet.clipboard.fill")
                    .font(.headline)

                ForEach(theme.items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.body)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.subheadline)
                            if !item.quantity.isEmpty {
                                Text(item.quantity)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Spacer(minLength: 20)

            Button {
                showAR = true
            } label: {
                Label("Preview in AR", systemImage: "arkit")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 10)
            
            if let event = activeEvent {
                let isSelected = event.likedDecorIDs.contains(theme.id)
                Button {
                    if !isSelected {
                        appState.likeTheme(theme, forEvent: event)
                    }
                    onSelect?()
                } label: {
                    Label(isSelected ? "Selected" : "Select Decor for \(event.name)", systemImage: isSelected ? "checkmark" : "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(isSelected ? .gray : .accentColor)
                .padding(.top, 4)
            }
        }
        .padding(20)
    }
}

#Preview {
    NavigationStack {
        ThemeDetailView(theme: DecorTheme.allThemes[0], appState: AppState.shared)
    }
}
