//
//  EventaViewModel.swift
//  Eventa
//
//  Created by HARSHIT on 23/03/26.
//

import Foundation
import SwiftUI

@Observable
class EventStore {
    // MARK: - Data Collections (The "Tables")
    var events: [Event] = []
    var invitations: [SavedInvitationPreview] = []
    var memoryFolders: [MemoryFolder] = []
    var decorThemes: [DecorTheme] = []
    
    init() {
        setupMockData()
    }
    
    
    
    /// Finds the invitation associated with a specific event
    func getInvitation(for event: Event) -> SavedInvitationPreview? {
        invitations.first { $0.id == event.invitationID }
    }
    
    /// Finds the memory folder associated with a specific event
    func getMemoryFolder(for event: Event) -> MemoryFolder? {
        memoryFolders.first { $0.id == event.memoryFolderID }
    }
    
    /// Filters decor themes by category (e.g., show only Birthday themes)
    func getThemes(for category: DecorCategory) -> [DecorTheme] {
        decorThemes.filter { $0.category == category }
    }
    
    // MARK: - Actions
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        // Optional: Clean up related data
        if let invID = event.invitationID { invitations.removeAll { $0.id == invID } }
        if let memID = event.memoryFolderID { memoryFolders.removeAll { $0.id == memID } }
    }

    // MARK: - Mock Data Setup
    private func setupMockData() {
        let birthdayID = UUID()
        let folderID = UUID()
        let inviteID = UUID()
        
        // 1. Mock Invitation
        invitations = [
            SavedInvitationPreview(id: inviteID, name: "Super Mario Invite", image: UIImage())
        ]
        
        // 2. Mock Folder
        memoryFolders = [
            MemoryFolder(id: folderID, name: "1st Birthday Pics", emoji: "🎂", eventID: birthdayID, createdAt: .now)
        ]
        
        // 3. Mock Event (Linking them together)
        events = [
            Event(id: birthdayID, name: "Ayaan's Birthday", category: .birthday)
        ]
        events[0].invitationID = inviteID
        events[0].memoryFolderID = folderID
        
        // 4. Mock Decor
        decorThemes = [
            DecorTheme(name: "Forest Theme", category: .birthday, tagline: "Nature at home", items: []),
            DecorTheme(name: "Royal Gold", category: .anniversary, tagline: "Elegant setup", items: [])
        ]
    }
}
