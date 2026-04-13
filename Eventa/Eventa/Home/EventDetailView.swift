// EventDetailView.swift
// Eventa – Detail page for a single event (Apple-native style)

import SwiftUI

struct EventDetailView: View {
    var appState: AppState
    var baseEvent: Event

    private var event: Event {
        appState.event(id: baseEvent.id) ?? baseEvent
    }

    init(appState: AppState, event: Event) {
        self.appState = appState
        self.baseEvent = event
    }
    @Environment(\.dismiss) private var dismiss
    @State private var showMemoryFolder = false
    @State private var showTemplatePicker = false
    @State private var showInviteEditor = false
    @State private var selectedTemplate: InvitationTemplate? = nil
    @State private var fromScratch = false
    @State private var selectedDecorTheme: DecorTheme? = nil
    @State private var showSavedInvitePicker = false
    @State private var showDecorBrowser = false

    private var invitation: SavedInvitationPreview? {
        guard let id = event.invitationID else { return nil }
        return appState.savedInvitations.first(where: { $0.id == id })
    }

    private var memFolder: MemoryFolder {
        appState.memoryFolder(for: event)
    }

    var body: some View {
        List {
            // ── Event Header ──
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Color.accentColor.opacity(0.15)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .frame(width: 56, height: 56)
                        Text(event.category.icon)
                            .font(.title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.title3.weight(.bold))
                        HStack(spacing: 6) {
                            Text(event.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(event.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // ── Event Details ──
            if event.eventDate != nil || !event.venue.isEmpty {
                Section("Details") {
                    if let date = event.eventDate {
                        LabeledContent {
                            Text(date.formatted(date: .long, time: .omitted))
                        } label: {
                            Label("Date", systemImage: "calendar")
                        }
                    }
                    if let time = event.eventTime {
                        LabeledContent {
                            Text(time.formatted(date: .omitted, time: .shortened))
                        } label: {
                            Label("Time", systemImage: "clock")
                        }
                    }
                    if !event.venue.isEmpty {
                        LabeledContent {
                            Text(event.venue)
                        } label: {
                            Label("Venue", systemImage: "mappin.and.ellipse")
                        }
                    }
                }
            }

            // ── Invitation Card ──
            if let inv = invitation {
                Section("Invitation Card") {
                    VStack(spacing: 12) {
                        Image(uiImage: inv.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 12) {
                            Button {
                                showInviteEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            ShareLink(
                                item: Image(uiImage: inv.image),
                                preview: SharePreview(
                                    "Invitation for \(event.name)",
                                    image: Image(uiImage: inv.image)
                                )
                            ) {
                                Label("Send Invite", systemImage: "paperplane.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Section("Invitation") {
                    NavigationLink {
                        TemplatePickerView(
                            onSelectTemplate: { template in
                                selectedTemplate = template
                                fromScratch = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showInviteEditor = true
                                }
                            },
                            onScratch: {
                                selectedTemplate = nil
                                fromScratch = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showInviteEditor = true
                                }
                            }
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.square.dashed")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create an Invitation")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color(.label))
                                Text("Design a beautiful invite for this event")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                }
            }

            // ── Decor ──
            if !event.likedDecorIDs.isEmpty {
                Section("Decor Selected") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(event.likedDecorThemes) { theme in
                                Button {
                                    selectedDecorTheme = theme
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ZStack(alignment: .bottomLeading) {
                                            if let imgName = theme.imageName, let uiImg = UIImage(named: imgName) {
                                                Image(uiImage: uiImg)
                                                    .resizable().scaledToFill()
                                                    .frame(width: 130, height: 90).clipped()
                                            } else {
                                                theme.category.gradient.frame(width: 130, height: 90)
                                            }
                                            LinearGradient(colors: [Color.black.opacity(0.5), .clear],
                                                           startPoint: .bottom, endPoint: .center)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Text(theme.name)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(Color(.label))
                                            .lineLimit(1)
                                    }
                                    .frame(width: 130)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else {
                Section("Decor") {
                    Button {
                        showDecorBrowser = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(.pink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Browse Decor")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color(.label))
                                Text("Find the perfect decor for this event")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // ── Memories ──
            Section("Memories") {
                if event.memoryFolderID == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("No memories yet")
                            .font(.subheadline.weight(.medium))
                        Text("Capture photos and videos from this event")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    memoryPreview
                }

                Button { showMemoryFolder = true } label: {
                    Label(
                        event.memoryFolderID == nil ? "Add Memories" : "View & Add Memories",
                        systemImage: event.memoryFolderID == nil ? "plus.circle.fill" : "photo.stack.fill"
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showMemoryFolder) {
            MemoryFolderView(appState: appState, folder: memFolder)
        }
        .navigationDestination(item: $selectedDecorTheme) { theme in
            ThemeDetailView(theme: theme, appState: appState)
        }
        .fullScreenCover(isPresented: $showInviteEditor) {
            InvitationEditorView(
                template: fromScratch ? nil : selectedTemplate,
                onSave: { preview in
                    // Remove previous invitation if editing
                    if let oldID = event.invitationID {
                        appState.savedInvitations.removeAll { $0.id == oldID }
                    }
                    appState.savedInvitations.insert(preview, at: 0)
                    if let idx = appState.events.firstIndex(where: { $0.id == event.id }) {
                        appState.events[idx].invitationID = preview.id
                    }
                }
            )
        }
        // Saved invitation picker
        .sheet(isPresented: $showSavedInvitePicker) {
            savedInvitePickerSheet
        }
        // Decor browser
        .sheet(isPresented: $showDecorBrowser) {
            NavigationStack {
                // Pass current reactive event to show checkmarks
                DecorHomeView(appState: appState, activeEvent: event, onDecorSelected: {
                    showDecorBrowser = false
                })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showDecorBrowser = false }
                        }
                    }
            }
        }
    }

    // MARK: - Saved Invite Picker Sheet
    private var savedInvitePickerSheet: some View {
        NavigationStack {
            List {
                let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(appState.savedInvitations) { inv in
                        Button {
                            if let idx = appState.events.firstIndex(where: { $0.id == event.id }) {
                                appState.events[idx].invitationID = inv.id
                            }
                            showSavedInvitePicker = false
                        } label: {
                            VStack(spacing: 6) {
                                Image(uiImage: inv.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(event.invitationID == inv.id ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                Text(inv.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(.label))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSavedInvitePicker = false }
                }
            }
        }
    }



    @ViewBuilder
    private var memoryPreview: some View {
        let folder = memFolder
        if folder.items.isEmpty {
            Text("Folder created – tap below to add photos & videos")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(folder.items.prefix(8)) { item in
                        if let img = item.thumbnail {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                if item.isVideo {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                        .padding(3)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(appState: AppState.shared, event: {
            let e = Event(name: "Sofia's Birthday", category: .birthday)
            return e
        }())
    }
}
