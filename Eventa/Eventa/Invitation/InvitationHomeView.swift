// InvitationHomeView.swift
// Eventa – Invitation home (Apple-native style)

import SwiftUI

struct InvitationHomeView: View {
    var appState: AppState
    @State private var showPicker       = false
    @State private var showEditor       = false
    @State private var showEventSetup   = false
    @State private var selectedTemplate : InvitationTemplate? = nil
    @State private var fromScratch      = false

    // Event setup form
    @State private var eventName        = ""
    @State private var eventCategory    = EventCategory.birthday
    @State private var selectedCategory: EventCategory? = nil
    @State private var pendingPreview   : SavedInvitationPreview? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Invitations")
                                .font(.largeTitle.weight(.bold))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        if appState.savedInvitations.isEmpty {
                            emptyState
                                .padding(.horizontal, 20)
                        } else {
                            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                            let activeCategories = EventCategory.allCases.filter { cat in
                                appState.savedInvitations.contains { $0.eventCategory == cat }
                            }
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(activeCategories) { cat in
                                    let count = appState.savedInvitations.filter { $0.eventCategory == cat }.count
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
                                            Text("\(count) invite\(count == 1 ? "" : "s")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }

                Button {
                    showPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedCategory) { cat in
                CategoryInvitationsListView(appState: appState, category: cat)
            }
        }

        // ── Template Picker ──
        .sheet(isPresented: $showPicker) {
            TemplatePickerView(
                onSelectTemplate: { template in
                    selectedTemplate = template
                    fromScratch      = false
                    showPicker       = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showEditor = true }
                },
                onScratch: {
                    fromScratch      = true
                    selectedTemplate = nil
                    showPicker       = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showEditor = true }
                }
            )
        }

        // ── Invitation Editor ──
        .fullScreenCover(isPresented: $showEditor) {
            InvitationEditorView(
                template: fromScratch ? nil : selectedTemplate,
                onSave: { preview in
                    pendingPreview = preview
                    appState.savedInvitations.insert(preview, at: 0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        loadDefaultEventName(from: preview)
                        showEventSetup = true
                    }
                }
            )
        }

        // ── Event Setup Sheet ──
        .sheet(isPresented: $showEventSetup) {
            eventSetupSheet
        }
    }

    // MARK: - Event Setup Sheet (Apple-native Form)
    private var eventSetupSheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "party.popper.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Color.accentColor)
                            Text("Name Your Event")
                                .font(.title3.weight(.bold))
                            Text("We'll use this to link your invite, decor & memories together.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Event Name") {
                    TextField("e.g. Sofia's Birthday", text: $eventName)
                }

                Section("Event Type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(EventCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation { eventCategory = cat }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(cat.icon)
                                        Text(cat.rawValue)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(eventCategory == cat ? Color.accentColor : Color(.systemFill))
                                    .foregroundStyle(eventCategory == cat ? .white : Color(.label))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .padding(.horizontal, 16)
                }

                Section {
                    Button {
                        if let preview = pendingPreview {
                            let name = eventName.isEmpty ? preview.name : eventName
                            appState.createEvent(name: name, category: eventCategory, invitation: preview)
                        }
                        showEventSetup = false
                    } label: {
                        HStack {
                            Spacer()
                            Label("Create Event", systemImage: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                            Spacer()
                        }
                    }
                    .disabled(eventName.isEmpty)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        showEventSetup = false
                    }
                }
            }
        }
    }

    private func loadDefaultEventName(from preview: SavedInvitationPreview) {
        eventName    = preview.name
        eventCategory = preview.eventCategory
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Invitations Yet", systemImage: "envelope.badge.fill")
        } description: {
            Text("Tap + to create your first invitation card.")
        }
    }
}

// MARK: - Saved Invitation Cell
struct SavedInvitationCell: View {
    var appState: AppState
    let preview: SavedInvitationPreview
    
    private var parentEvent: Event? {
        appState.events.first(where: { $0.invitationID == preview.id })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: preview.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
                
                LinearGradient(colors: [Color.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .center)
            }
            .frame(height: 140)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(parentEvent?.name ?? preview.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                
                let displayDate = parentEvent?.eventDate ?? preview.createdAt
                Text(displayDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Fullscreen Invitation Preview
struct FullscreenInvitationPreview: View {
    let preview: SavedInvitationPreview
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            Image(uiImage: preview.image)
                .resizable()
                .scaledToFit()
                .padding()
                .shadow(radius: 10)
        }
        .navigationTitle(preview.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: Image(uiImage: preview.image),
                    preview: SharePreview(preview.name, image: Image(uiImage: preview.image))
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    InvitationHomeView(appState: AppState.shared)
}
