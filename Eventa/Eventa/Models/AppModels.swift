//
//  AppModels.swift
//  Eventa
//
//  Created by HARSHIT on 08/04/26.
//

import Foundation
import SwiftUI
import Photos



// MARK: - Event Category
enum EventCategory: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    case birthday    = "Birthday"
    case anniversary = "Anniversary"
    case babyShower  = "Baby Shower"
    case haldi       = "Haldi"
    case mehndi      = "Mehndi"
    case other       = "Others"

    var icon: String {
        switch self {
        case .birthday:    return "🎂"
        case .anniversary: return "💍"
        case .babyShower:  return "👶"
        case .haldi:       return "🌼"
        case .mehndi:      return "🤲"
        case .other:       return "🎉"
        }
    }

    var systemIcon: String {
        switch self {
        case .birthday:    return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .babyShower:  return "figure.and.child.holdinghands"
        case .haldi:       return "sun.max.fill"
        case .mehndi:      return "hand.raised.fill"
        case .other:       return "party.popper.fill"
        }
    }

    // Used to show only related decorations for better personalization
    var relevantDecorCategories: [DecorCategory] {
        switch self {
        case .birthday:    return [.birthday]
        case .anniversary: return [.anniversary]
        case .babyShower:  return [.babyShowers]
        case .haldi:       return [.haldi]
        case .mehndi:      return [.mehndi]
        case .other:       return DecorCategory.allCases
        }
    }
}


// MARK: - Event Model
// Stores all information related to a specific event
struct Event: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: EventCategory
    var eventDate: Date?
    var eventTime: Date?
    var venue: String
    var invitationID: UUID?
    var likedDecorIDs: Set<UUID>
    var memoryFolderID: UUID?      // Links event to memory storage
    var createdAt: Date            // Used for sorting

    
    // Custom initializer for flexible event creation
    init(name: String, category: EventCategory, eventDate: Date? = nil, eventTime: Date? = nil, venue: String = "") {
        self.id             = UUID()
        self.name           = name
        self.category       = category
        self.eventDate      = eventDate
        self.eventTime      = eventTime
        self.venue          = venue
        self.invitationID   = nil
        self.likedDecorIDs  = []
        self.memoryFolderID = nil
        self.createdAt      = Date()
    }

    var likedDecorThemes: [DecorTheme] {
        DecorTheme.allThemes.filter { likedDecorIDs.contains($0.id) }
    }

    static func == (lhs: Event, rhs: Event) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}



// MARK: - Invitation Element Kind
// Defines types of elements used in invitation builder
enum InvitationElementKind: String, Codable {
    case text, image, sticker
}


// MARK: - Canvas Element

// Represents editable element in invitation editor
struct CanvasElement: Identifiable {
    let id: UUID
    var kind: InvitationElementKind
    var text: String = ""
    var fontName: String = "Georgia"
    var fontSize: CGFloat = 20
    var textColor: Color = .black
    var image: UIImage? = nil
    var position: CGPoint = .zero
    var size: CGSize = CGSize(width: 140, height: 50)
    var rotation: Angle = .zero
    var zIndex: Double = 0

    init(kind: InvitationElementKind) {
        self.id = UUID()
        self.kind = kind
    }
}


// MARK: - Invitation Template
// Predefined templates for quick invitation creation
struct InvitationTemplate: Identifiable {
    let id = UUID()
    let name: String
    let category: EventCategory
    let backgroundGradient: LinearGradient
    let previewIcon: String
    let elements: [TemplateElement]

    struct TemplateElement {
        var text: String
        var fontSize: CGFloat
        var fontName: String
        var color: Color
        var positionFraction: CGPoint
    }
}

// MARK: - Saved Invitation Preview

struct SavedInvitationPreview: Identifiable {
    let id: UUID
    let name: String
    let image: UIImage
    let createdAt: Date
    let eventCategory: EventCategory

    init(name: String, image: UIImage, createdAt: Date = Date(), eventCategory: EventCategory = .birthday) {
        self.id = UUID()
        self.name = name
        self.image = image
        self.createdAt = createdAt
        self.eventCategory = eventCategory
    }
}

// MARK: - Media Item
// Wrapper for photos/videos from device gallery
struct MediaItem: Identifiable {
    let id = UUID()
    var asset: PHAsset
    var thumbnail: UIImage? = nil

    init(asset: PHAsset) {
        self.asset = asset
    }
    // Loads thumbnail for performance optimization
    mutating func loadThumbnail() {
        let size = CGSize(width: 300, height: 300)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        let currentAsset = asset
        PHImageManager.default().requestImage(for: currentAsset, targetSize: size, contentMode: .aspectFill, options: options) { img, _ in
            // Note: thumbnail assignment should be handled by the caller/store
        }
    }

    var isVideo: Bool { asset.mediaType == .video }
    var duration: TimeInterval { asset.duration }
}


// MARK: - Memory Folder
// Stores event-related photos/videos
struct MemoryFolder: Identifiable {
    let id = UUID()
    var name: String
    var emoji: String
    var createdAt: Date
    var items: [MediaItem] = []

    init(name: String, emoji: String) {
        self.name = name
        self.emoji = emoji
        self.createdAt = Date()
    }

    var coverThumbnail: UIImage? { items.first?.thumbnail }
    var photoCount: Int { items.filter { !$0.isVideo }.count }
    var videoCount: Int { items.filter { $0.isVideo }.count }
}

