//
//  AppStore.swift
//  Eventa
//
//  Created by HARSHIT on 08/04/26.
//

// AppStore.swift


import SwiftUI


@Observable
class AppStore {
    // Singleton instance used to access a single shared AppStore across the entire app
    static let shared = AppStore()

    // MARK: - Auth & Onboarding
    var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding") }
    }
    var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn") }
    }

    // MARK: - User
    var userName: String = "YOU"
    var userEmail: String = ""
    var userPhoto: Data? = nil

    // MARK: - Core Data
    var memoryFolders: [MemoryFolder] = []
    var savedInvitations: [SavedInvitationPreview] = []
    var likedThemeIDs: Set<UUID> = []
    var events: [Event] = []

    // MARK: - Banner Prompt State
    var pendingDecorPromptEventID: UUID? = nil
    var pendingMemoryPromptEventID: UUID? = nil

    // MARK: - Init
    private init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    // MARK: - Computed Helpers
    var likedThemes: [DecorTheme] {
        DecorTheme.allThemes.filter { likedThemeIDs.contains($0.id) }
    }

    // Gets recent media for home screen display
    var recentMemoryItems: [MediaItem] {
        memoryFolders.flatMap { $0.items }.prefix(12).map { $0 }
    }

    // MARK: - Like / Unlike
    func toggleLike(_ theme: DecorTheme) {
        if likedThemeIDs.contains(theme.id) {
            likedThemeIDs.remove(theme.id)
        } else {
            likedThemeIDs.insert(theme.id)
        }
    }

    func isLiked(_ theme: DecorTheme) -> Bool {
        likedThemeIDs.contains(theme.id)
    }

    // MARK: - Event Helpers
    func event(forInvitationID id: UUID) -> Event? {
        events.first { $0.invitationID == id }
    }

    func event(id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    @discardableResult
    func memoryFolder(for event: Event) -> MemoryFolder {
        if let folderID = event.memoryFolderID,
           let existing = memoryFolders.first(where: { $0.id == folderID }) {
            return existing
        }
        let folder = MemoryFolder(name: event.name, emoji: event.category.icon)
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx].memoryFolderID = folder.id
        }
        memoryFolders.insert(folder, at: 0)
        return folder
    }

    @discardableResult
    func createEvent(name: String, category: EventCategory, invitation: SavedInvitationPreview) -> Event {
        var event = Event(name: name, category: category)
        event.invitationID = invitation.id
        events.insert(event, at: 0)
        pendingDecorPromptEventID = event.id
        return event
    }

    @discardableResult
    func createEventFromFlow(
        name: String,
        category: EventCategory,
        eventDate: Date?,
        eventTime: Date?,
        venue: String,
        invitationID: UUID? = nil,
        selectedDecorIDs: Set<UUID> = []
    ) -> Event {
        var event = Event(name: name, category: category, eventDate: eventDate, eventTime: eventTime, venue: venue)
        event.invitationID = invitationID
        event.likedDecorIDs = selectedDecorIDs
        events.insert(event, at: 0)
        return event
    }

    func likeTheme(_ theme: DecorTheme, forEvent event: Event) {
        likedThemeIDs.insert(theme.id)
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx].likedDecorIDs.insert(theme.id)
        }
        pendingMemoryPromptEventID = event.id
        if pendingDecorPromptEventID == event.id {
            pendingDecorPromptEventID = nil
        }
    }

    func unlikeTheme(_ theme: DecorTheme, forEvent event: Event) {
        likedThemeIDs.remove(theme.id)
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx].likedDecorIDs.remove(theme.id)
        }
    }

    // MARK: - First-Time User Check
    var isFirstTimeUser: Bool {
        events.isEmpty && savedInvitations.isEmpty && likedThemeIDs.isEmpty && memoryFolders.isEmpty
    }

    // MARK: - Account Management
    func deleteAccount() {
        userName = "Rohan"
        userEmail = ""
        userPhoto = nil
        memoryFolders.removeAll()
        savedInvitations.removeAll()
        likedThemeIDs.removeAll()
        events.removeAll()
        pendingDecorPromptEventID = nil
        pendingMemoryPromptEventID = nil
        isLoggedIn = false
        hasSeenOnboarding = false
    }
}

// MARK: - Backwards-Compatible Typealias

/// Existing views use `AppState` — this alias keeps them compiling without edits
typealias AppState = AppStore

