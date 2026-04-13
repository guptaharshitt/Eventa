// HomeView.swift
// Eventa – Premium Apple-native Dashboard

import SwiftUI

struct HomeView: View {
    var appState: AppState
    @Binding var selectedTab: Int
    @State private var showProfileEdit = false
    @State private var showEventCreation = false
    @State private var selectedEvent: Event? = nil
    @State private var selectedCategory: EventCategory? = nil
    @State private var showAllEvents = false
    @State private var showAllUpcomingEvents = false

    private var displayUserName: String {
        let name = appState.userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Harshit" : name
    }

    private var upcomingEvents: [Event] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return appState.events
            .filter { event in
                guard let d = event.eventDate else { return false }
                return d >= startOfDay
            }
            .sorted { $0.eventDate! < $1.eventDate! }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // ── Upcoming Events ──
                    if !upcomingEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                showAllUpcomingEvents = true
                            } label: {
                                HStack {
                                    Text("Upcoming Events")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color(.label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(upcomingEvents.prefix(3))) { event in
                                    Button {
                                        selectedEvent = event
                                    } label: {
                                        RecentEventRow(appState: appState, event: event)
                                            .padding()
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // ── My Events (Category Cards) ──
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            showAllEvents = true
                        } label: {
                            HStack {
                                Text("My Events")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color(.label))
                                Spacer()
                                if !appState.events.isEmpty {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)

                        if appState.events.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.tertiary)
                                Text("No events yet")
                                    .font(.subheadline.weight(.semibold))
                                Text("Tap + to create your first event!")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 30)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else {
                            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                            let activeCategories = EventCategory.allCases.filter { cat in
                                appState.events.contains { $0.category == cat }
                            }
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(activeCategories, id: \.self) { cat in
                                    Button {
                                        selectedCategory = cat
                                    } label: {
                                        VStack(spacing: 10) {
                                            Image(systemName: cat.systemIcon)
                                                .font(.system(size: 28))
                                                .foregroundStyle(Color.accentColor)
                                            Text(cat.rawValue)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Color(.label))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    

                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .padding(.bottom, 60) // Extra padding so content isn't hidden behind FAB
            }
            .background(Color(.systemGroupedBackground))

                // ── Floating Action Button ──
                Button {
                    showEventCreation = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            } // ZStack
            .navigationTitle("Hi, \(displayUserName)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfileEdit.toggle() } label: {
                        if let photoData = appState.userPhoto, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventDetailView(appState: appState, event: event)
            }
            .navigationDestination(item: $selectedCategory) { cat in
                CategoryEventsListView(appState: appState, category: cat)
            }
            .navigationDestination(isPresented: $showAllEvents) {
                AllEventsListView(appState: appState)
            }
            .navigationDestination(isPresented: $showAllUpcomingEvents) {
                AllUpcomingEventsListView(appState: appState)
            }
        }
        .sheet(isPresented: $showProfileEdit) { profileEditSheet }
        .fullScreenCover(isPresented: $showEventCreation) {
            EventCreationFlowView(appState: appState, selectedTab: $selectedTab)
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: - Profile Sheet
    // ─────────────────────────────────────────────────────────
    private var profileEditSheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.tertiary)
                        let bindable = Bindable(appState)
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Your name", text: bindable.userName)
                                .font(.title3.weight(.semibold))
                            Text("Eventa User")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Your Activity") {
                    LabeledContent {
                        Text("\(appState.events.count)")
                    } label: {
                        Label("Events", systemImage: "calendar.badge.checkmark")
                    }
                    LabeledContent {
                        Text("\(appState.savedInvitations.count)")
                    } label: {
                        Label("Invitations", systemImage: "envelope.fill")
                    }
                    LabeledContent {
                        Text("\(appState.memoryFolders.count)")
                    } label: {
                        Label("Memory Folders", systemImage: "photo.stack.fill")
                    }
                    LabeledContent {
                        Text("\(appState.likedThemes.count)")
                    } label: {
                        Label("Liked Themes", systemImage: "heart.fill")
                    }
                }
                Section {
                    Button(role: .destructive) {
                        withAnimation { appState.isLoggedIn = false; showProfileEdit = false }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showProfileEdit = false }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Recent Event Row (Apple-native list row)
// ═══════════════════════════════════════════════════════════════
struct RecentEventRow: View {
    var appState: AppState
    var event: Event

    private var invitation: SavedInvitationPreview? {
        guard let invID = event.invitationID else { return nil }
        return appState.savedInvitations.first(where: { $0.id == invID })
    }

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            Group {
                if let inv = invitation {
                    Image(uiImage: inv.image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.accentColor.opacity(0.12)
                        Text(event.category.icon)
                            .font(.title2)
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(event.category.icon)
                        .font(.caption2)
                    Text((event.eventDate ?? event.createdAt).formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status tags
            HStack(spacing: 6) {
                if invitation != nil {
                    Image(systemName: "envelope.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }
                if !event.likedDecorIDs.isEmpty {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.pink)
                }
                if event.memoryFolderID != nil {
                    Image(systemName: "photo.stack.fill")
                        .font(.caption2)
                        .foregroundStyle(.indigo)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Liked Decor Mini Card
// ═══════════════════════════════════════════════════════════════
struct LikedDecorMiniCard: View {
    let theme: DecorTheme
    var appState: AppState

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imgName = theme.imageName, let uiImg = UIImage(named: imgName) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                theme.category.gradient
                    .frame(height: 120)
            }
            LinearGradient(colors: [Color.black.opacity(0.6), .clear],
                           startPoint: .bottom, endPoint: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(theme.category.rawValue)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(10)

            // Unlike button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { appState.toggleLike(theme) }
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView(appState: AppState.shared, selectedTab: .constant(0))
}
