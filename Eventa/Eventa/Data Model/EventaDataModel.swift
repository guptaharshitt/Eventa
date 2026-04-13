//
//  EventaDataModel.swift
//  Eventa
//
//  Created by HARSHIT on 23/03/26.
//

import Foundation
import SwiftUI
import Photos

// MARK: - ENTITY 1. Event
struct Event: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: EventCategory
    var createdAt: Date = Date()
    
    // Links to other entities (Foreign Keys)
    var invitationID: UUID?
    var memoryFolderID: UUID?
    
    // Metadata
    var likedDecorIDs: Set<UUID> = []
}

enum EventCategory: String, CaseIterable, Codable {
    case birthday = "Birthday"
    case anniversary = "Anniversary"
    case babyShower = "Baby Shower"
    case haldi = "Haldi"
}

// MARK: - ENTITY 2. Decor & Theme
struct DecorTheme: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: DecorCategory
    var tagline: String
    var imageName: String?
    var items: [DecorItem]
}

struct DecorItem: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var description: String
    var themeID: UUID // Foreign key linking back to DecorTheme
}

enum DecorCategory: String, CaseIterable {
    case birthday, anniversary, haldi, babyShower
}

// MARK: - ENTITY 3. Invitation

/// A lightweight model used for listing/saving invitation previews without full editing metadata.
struct SavedInvitationPreview: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var image: UIImage
    var eventCategory: EventCategory? = nil
}

struct SavedInvitation: Identifiable {
    var id: UUID = UUID()
    var name: String
    var previewImage: UIImage
    var eventID: UUID // Foreign key linking back to the Event
    var elements: [CanvasElement]
    var createdAt: Date = Date()
}

struct CanvasElement: Identifiable {
    var id: UUID = UUID()
    var kind: InvitationElementKind
    var text: String = ""
    var fontName: String = "Georgia"
    var fontSize: CGFloat = 20
    var textColor: Color = .black
    var image: UIImage?
    var position: CGPoint = .zero
    var size: CGSize = CGSize(width: 140, height: 50)
    var rotation: Angle = .zero
}

enum InvitationElementKind: String, Codable {
    case text, image, sticker
}

// MARK: - ENTITY 4. Memory
struct MemoryFolder: Identifiable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var eventID: UUID // Foreign key linking back to the Event
    var createdAt: Date = Date()
}

struct MediaItem: Identifiable {
    var id: UUID = UUID()
    let asset: PHAsset
    var thumbnail: UIImage?
    var folderID: UUID // Foreign key linking back to MemoryFolder
    
    var isVideo: Bool { asset.mediaType == .video }
}
