//
//  DecorModels.swift
//  Eventa
//
//  Created by Nikhil on 13/04/26.
//

import Foundation
import SwiftUI

// ═══════════════════════════════════════════════════════
// MARK: - Decor Category
// ═══════════════════════════════════════════════════════
/// `DecorCategory` represents the different types of events that decors belong to.
/// We use this enum to categorize and filter the available decor themes in the app,
/// allowing the user to select decorations based on the event context (e.g., Birthday, Haldi).
/// It provides UI-specific properties like `icon` for iconography and `gradient` for styling.
enum DecorCategory: String, CaseIterable, Identifiable {
    case birthday    = "Birthday"
    case anniversary = "Anniversary"
    case babyShowers = "Baby Showers"
    case haldi       = "Haldi"
    case mehndi      = "Mehndi"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .birthday:    return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .babyShowers: return "figure.and.child.holdinghands"
        case .haldi:       return "sun.max.fill"
        case .mehndi:      return "hand.raised.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .birthday:
            return LinearGradient(colors: [Color(red:0.88,green:0.12,blue:0.52), Color(red:0.52,green:0.12,blue:0.88)], startPoint:.topLeading, endPoint:.bottomTrailing)
        case .anniversary:
            return LinearGradient(colors: [Color(red:0.85,green:0.20,blue:0.30), Color(red:0.95,green:0.55,blue:0.45)], startPoint:.topLeading, endPoint:.bottomTrailing)
        case .babyShowers:
            return LinearGradient(colors: [Color(red:0.55,green:0.80,blue:0.95), Color(red:0.90,green:0.75,blue:0.95)], startPoint:.topLeading, endPoint:.bottomTrailing)
        case .haldi:
            return LinearGradient(colors: [Color(red:0.95,green:0.75,blue:0.10), Color(red:1.0,green:0.88,blue:0.35)], startPoint:.topLeading, endPoint:.bottomTrailing)
        case .mehndi:
            return LinearGradient(colors: [Color(red:0.20,green:0.55,blue:0.20), Color(red:0.50,green:0.75,blue:0.25)], startPoint:.topLeading, endPoint:.bottomTrailing)
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Decor Item
// ═══════════════════════════════════════════════════════
/// `DecorItem` represents a single physical piece or bundle of decoration (e.g., balloons, curtains).
/// We use this to breakdown exactly what is included in a specific `DecorTheme`,
/// providing users a detailed understanding of the physical items they will receive or need.
struct DecorItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let quantity: String
}

// ═══════════════════════════════════════════════════════
// MARK: - Decor Theme
// ═══════════════════════════════════════════════════════
/// `DecorTheme` encapsulates the entire design and styling data for a specific decor setup.
/// We use this structure to provide a cohesive visual representation of an event aesthetic.
/// It consists of standard colors (`primaryColor`, `accentColor`), a collection of swatches
/// for UI theming, and an aggregated list of `DecorItem`s included in that theme.
struct DecorTheme: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: DecorCategory
    let tagline: String
    let description: String
    let primaryColor: Color
    let accentColor: Color
    let swatches: [Color]
    let items: [DecorItem]
    var imageName: String? = nil

    static func == (lhs: DecorTheme, rhs: DecorTheme) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Sample Data
    static let allThemes: [DecorTheme] = [

        // ═══════════════ BIRTHDAY ═══════════════

        DecorTheme(
            name: "Black & Gold Glam",
            category: .birthday,
            tagline: "Sophisticated elegance with maximum drama",
            description: "Transform your space into a glamorous celebration with black and gold accents. This theme features metallic gold letter balloons against a sleek black backdrop, gold foil curtains, and elegant confetti scattered across tables. Perfect for milestone birthdays and evening celebrations where you want a luxurious, high-end feel.",
            primaryColor: Color(red:0.85,green:0.65,blue:0.1),
            accentColor: .black,
            swatches: [.black, Color(red:0.85,green:0.65,blue:0.1), Color(red:0.7,green:0.55,blue:0.1), Color(red:1,green:0.9,blue:0.6), .white],
            items: [
                .init(name: "Gold Letter Balloons", icon: "bubbles.and.sparkles", quantity: "1 set (HAPPY BIRTHDAY)"),
                .init(name: "Black Latex Balloons", icon: "circle.fill", quantity: "20 pieces (12 inch)"),
                .init(name: "Gold Foil Curtain Backdrop", icon: "rectangle.fill", quantity: "2 panels (3×8 ft)"),
                .init(name: "Gold Confetti", icon: "sparkles", quantity: "3 packets"),
                .init(name: "Black & Gold Tablecloth", icon: "rectangle.fill", quantity: "2 pieces"),
                .init(name: "Gold Candle Holders", icon: "flame.fill", quantity: "6 pieces"),
                .init(name: "Star Shaped Mylar Balloons", icon: "star.fill", quantity: "4 pieces"),
            ],
            imageName: "decor1"
        ),

        DecorTheme(
            name: "Pastel Balloon Garden",
            category: .birthday,
            tagline: "Soft pastels with dreamy balloon clouds",
            description: "Create a whimsical wonderland with an enchanting pastel colour palette. Features a stunning balloon arch in soft pinks, lavenders, blues, and mint greens, complemented by white flower wall panels and delicate tissue pom-poms. Ideal for children's birthdays or anyone who loves a sweet, dreamy aesthetic.",
            primaryColor: Color(red:0.9,green:0.7,blue:0.85),
            accentColor: Color(red:1,green:0.95,blue:1),
            swatches: [Color(red:0.9,green:0.7,blue:0.85), Color(red:0.7,green:0.85,blue:0.9), Color(red:0.9,green:0.9,blue:0.7), Color(red:1,green:0.8,blue:0.85), .white],
            items: [
                .init(name: "Pastel Balloon Arch Kit", icon: "bubbles.and.sparkles", quantity: "1 set (100 balloons)"),
                .init(name: "White Flower Wall Panel", icon: "camera.macro", quantity: "4 panels (2×2 ft)"),
                .init(name: "Ribbon Streamers (Pastel Mix)", icon: "sparkles", quantity: "10 rolls"),
                .init(name: "Pink/Lilac Tissue Pom-Poms", icon: "circle.fill", quantity: "12 pieces"),
                .init(name: "White Sheer Drape Fabric", icon: "rectangle.fill", quantity: "3 panels"),
                .init(name: "Pastel Confetti Balloons", icon: "bubbles.and.sparkles", quantity: "10 pieces"),
                .init(name: "Gold Hoop Centrepiece Frame", icon: "circle", quantity: "2 pieces"),
            ],
            imageName: "decor2"
        ),

        DecorTheme(
            name: "Tropical Paradise",
            category: .birthday,
            tagline: "Lush jungle vibes for a wild celebration",
            description: "Bring the tropics indoors with vibrant greens, sunny yellows, and exotic accents. Features a tropical leaf balloon garland, flamingo standees, palm leaf decorations, and a fun tiki-themed setup. Perfect for summer birthdays or anyone who loves a colourful, island-inspired celebration.",
            primaryColor: Color(red:0.1,green:0.6,blue:0.25),
            accentColor: .yellow,
            swatches: [Color(red:0,green:0.6,blue:0.3), .yellow, .orange, Color(red:0.8,green:0.3,blue:0.4), Color(red:0.2,green:0.7,blue:0.5)],
            items: [
                .init(name: "Tropical Leaf Balloon Garland", icon: "leaf.fill", quantity: "1 garland (6 ft)"),
                .init(name: "Flamingo Standees", icon: "bird.fill", quantity: "3 pieces"),
                .init(name: "Palm Leaf Paper Decorations", icon: "leaf.fill", quantity: "20 pieces"),
                .init(name: "Pineapple Centrepieces", icon: "leaf.fill", quantity: "4 pieces"),
                .init(name: "Tropical Fruit Paper Fans", icon: "sparkles", quantity: "6 pieces"),
                .init(name: "Green & Yellow Balloon Cluster", icon: "bubbles.and.sparkles", quantity: "30 balloons"),
                .init(name: "Tiki Bar Decorations", icon: "cup.and.saucer.fill", quantity: "1 set"),
            ],
            imageName: "decor3"
        ),

        DecorTheme(
            name: "Princess Fantasy",
            category: .birthday,
            tagline: "A magical fairy-tale birthday celebration",
            description: "Create a royal birthday experience with pink and purple hues, sparkling elements, and princess-themed accents. Features a chrome and pastel balloon arch, princess crown photo props, a pink tulle table skirt, and iridescent foil curtains. Every little one deserves to feel like royalty on their special day.",
            primaryColor: Color(red:1,green:0.41,blue:0.71),
            accentColor: Color(red:0.85,green:0.7,blue:1),
            swatches: [.pink, Color(red:0.85,green:0.7,blue:1), Color(red:1,green:0.84,blue:0.88), Color(red:0.9,green:0.6,blue:0.9), .white],
            items: [
                .init(name: "Pink Balloon Arch (Chrome & Pastel)", icon: "bubbles.and.sparkles", quantity: "1 arch kit (120 pcs)"),
                .init(name: "Princess Crown Photo Prop", icon: "crown.fill", quantity: "5 pieces"),
                .init(name: "Pink Tulle Table Skirt", icon: "rectangle.fill", quantity: "1 piece (14 ft)"),
                .init(name: "Sparkle Star Wands", icon: "wand.and.stars", quantity: "10 pieces"),
                .init(name: "Iridescent Foil Curtain", icon: "sparkles", quantity: "2 panels"),
                .init(name: "Pink Flower Centrepieces", icon: "camera.macro", quantity: "4 arrangements"),
                .init(name: "Unicorn Cake Topper", icon: "star.fill", quantity: "1 piece"),
            ],
            imageName: "decor4"
        ),

        DecorTheme(
            name: "Cosmic Galaxy",
            category: .birthday,
            tagline: "Blast off to an out-of-this-world birthday",
            description: "Take your party to outer space with deep navy, purple, and cosmic chrome accents. Features a galaxy-themed balloon cluster, star and moon mylar balloons, a space backdrop, holographic streamers, and glow-in-the-dark star stickers. Perfect for kids and anyone fascinated by the cosmos.",
            primaryColor: Color(red:0.1,green:0,blue:0.4),
            accentColor: .purple,
            swatches: [Color(red:0.1,green:0,blue:0.4), Color(red:0.5,green:0,blue:0.8), .cyan, Color(red:1,green:0.85,blue:0), .white],
            items: [
                .init(name: "Galaxy Balloon Cluster (Chrome)", icon: "bubbles.and.sparkles", quantity: "1 pack (50 pcs, navy/purple/silver)"),
                .init(name: "Star & Moon Mylar Balloons", icon: "star.fill", quantity: "6 pieces"),
                .init(name: "Space Backdrop (Galaxy Print)", icon: "sparkles", quantity: "1 banner (5×3 ft)"),
                .init(name: "Holographic Star Streamers", icon: "rays", quantity: "20 strands"),
                .init(name: "Rocket Ship Centrepiece", icon: "airplane", quantity: "2 pieces"),
                .init(name: "Glow-in-dark Star Stickers", icon: "star.fill", quantity: "200 stickers"),
                .init(name: "Blue & Purple LED Fairy Lights", icon: "light.overhead.left.fill", quantity: "3 strings (10 ft)"),
            ],
            imageName: "decor6"
        ),

        // ═══════════════ ANNIVERSARY ═══════════════

        DecorTheme(
            name: "Rustic Romance",
            category: .anniversary,
            tagline: "Timeless elegance for your love story",
            description: "Celebrate your love with warm, rustic tones and vintage-inspired details. Features mason jar centrepieces with candles, burlap table runners, a dreamy string light canopy, wooden sign boards, and fresh wildflower bouquets. Perfect for creating an intimate, romantic atmosphere for anniversaries.",
            primaryColor: Color(red:0.55,green:0.35,blue:0.15),
            accentColor: Color(red:0.9,green:0.8,blue:0.6),
            swatches: [Color(red:0.55,green:0.35,blue:0.15), Color(red:0.9,green:0.8,blue:0.6), Color(red:0.7,green:0.5,blue:0.3), .white, Color(red:0.85,green:0.7,blue:0.5)],
            items: [
                .init(name: "Mason Jar Centrepieces", icon: "cup.and.saucer.fill", quantity: "8 jars"),
                .init(name: "Burlap Table Runner", icon: "rectangle.fill", quantity: "2 pieces"),
                .init(name: "String Light Canopy", icon: "light.overhead.left.fill", quantity: "1 set (50 ft)"),
                .init(name: "Wooden Sign Boards", icon: "square.fill", quantity: "3 pieces"),
                .init(name: "Wildflower Bouquets", icon: "camera.macro", quantity: "6 arrangements"),
                .init(name: "Rose Petal Scatter", icon: "camera.macro", quantity: "500 petals"),
                .init(name: "Gold Frame Table Numbers", icon: "number", quantity: "8 frames"),
            ]
        ),

        DecorTheme(
            name: "Red Rose Elegance",
            category: .anniversary,
            tagline: "Classic red roses for your special day",
            description: "Nothing says love like red roses. This elegant theme features deep red rose arrangements, romantic candle settings, satin table runners, and heart-shaped accents. The classic red and white colour scheme creates a sophisticated and deeply romantic ambiance for your anniversary celebration.",
            primaryColor: Color(red:0.8,green:0.1,blue:0.15),
            accentColor: .white,
            swatches: [Color(red:0.8,green:0.1,blue:0.15), .white, Color(red:0.6,green:0.05,blue:0.1), Color(red:1,green:0.85,blue:0.85), Color(red:0.85,green:0.65,blue:0.1)],
            items: [
                .init(name: "Red Rose Arrangements", icon: "camera.macro", quantity: "6 vases"),
                .init(name: "Pillar Candles (Red & White)", icon: "flame.fill", quantity: "12 candles"),
                .init(name: "Satin Table Runner", icon: "rectangle.fill", quantity: "2 pieces"),
                .init(name: "Heart-shaped Balloons", icon: "heart.fill", quantity: "20 pieces"),
                .init(name: "Anniversary Banner", icon: "flag.fill", quantity: "1 banner"),
                .init(name: "Gold Confetti Scatter", icon: "sparkles", quantity: "3 packets"),
            ]
        ),

        // ═══════════════ BABY SHOWER ═══════════════

        DecorTheme(
            name: "Dreamy Clouds",
            category: .babyShowers,
            tagline: "Soft clouds & sweet dreams",
            description: "Welcome the little one with a heavenly cloud-themed setup. Features fluffy white balloon clusters shaped like clouds, soft blue and pink streamers, adorable baby-themed cutouts, and a stunning backdrop with hanging stars and moons. A gentle, dreamy atmosphere perfect for celebrating new arrivals.",
            primaryColor: Color(red:0.7,green:0.85,blue:1.0),
            accentColor: .white,
            swatches: [Color(red:0.7,green:0.85,blue:1.0), .white, Color(red:1,green:0.85,blue:0.9), Color(red:0.9,green:0.95,blue:1), Color(red:0.85,green:0.75,blue:1)],
            items: [
                .init(name: "Cloud Balloon Cluster", icon: "bubbles.and.sparkles", quantity: "1 set (40 white balloons)"),
                .init(name: "Baby Blue/Pink Streamers", icon: "sparkles", quantity: "12 rolls"),
                .init(name: "Oh Baby! Gold Banner", icon: "flag.fill", quantity: "1 banner"),
                .init(name: "Star & Moon Hanging Decor", icon: "star.fill", quantity: "15 pieces"),
                .init(name: "Pastel Tulle Backdrop", icon: "rectangle.fill", quantity: "2 panels (5×7 ft)"),
                .init(name: "Baby Bottle Centrepieces", icon: "cup.and.saucer.fill", quantity: "6 pieces"),
                .init(name: "Diaper Cake Display", icon: "gift.fill", quantity: "1 cake"),
            ],
            imageName: "decor5"
        ),

        DecorTheme(
            name: "Teddy Bear Picnic",
            category: .babyShowers,
            tagline: "Adorable teddy-themed celebration",
            description: "An absolutely adorable baby shower theme featuring plush teddy bear accents, warm honey-gold tones, and picnic-style decorations. Includes a balloon garland in browns and creams, teddy bear centrepieces, gingham tablecloths, and wooden craft accents. Creates an irresistibly cute atmosphere for welcoming the new baby.",
            primaryColor: Color(red:0.65,green:0.45,blue:0.25),
            accentColor: Color(red:0.95,green:0.90,blue:0.80),
            swatches: [Color(red:0.65,green:0.45,blue:0.25), Color(red:0.95,green:0.90,blue:0.80), Color(red:0.85,green:0.70,blue:0.50), .white, Color(red:0.75,green:0.55,blue:0.35)],
            items: [
                .init(name: "Brown & Cream Balloon Garland", icon: "bubbles.and.sparkles", quantity: "1 garland (80 balloons)"),
                .init(name: "Teddy Bear Centrepieces", icon: "teddybear.fill", quantity: "4 pieces"),
                .init(name: "Gingham Tablecloth", icon: "rectangle.fill", quantity: "2 pieces"),
                .init(name: "Honey Pot Table Decor", icon: "cup.and.saucer.fill", quantity: "6 pieces"),
                .init(name: "Wooden Baby Blocks", icon: "square.fill", quantity: "8 blocks"),
                .init(name: "Welcome Baby Banner", icon: "flag.fill", quantity: "1 banner"),
            ]
        ),

        // ═══════════════ HALDI ═══════════════

        DecorTheme(
            name: "Golden Haldi Bliss",
            category: .haldi,
            tagline: "Sunshine yellow for auspicious celebrations",
            description: "Embrace the vibrant tradition of Haldi with a stunning yellow and marigold-themed setup. Features cascading marigold garlands, yellow drapes, brass urlis filled with flower petals, turmeric-coloured balloon arrangements, and traditional rangoli designs. Creates an authentic and joyful atmosphere for the pre-wedding ceremony.",
            primaryColor: Color(red:0.95,green:0.75,blue:0.10),
            accentColor: Color(red:1.0,green:0.55,blue:0.0),
            swatches: [Color(red:0.95,green:0.75,blue:0.10), Color(red:1.0,green:0.55,blue:0.0), Color(red:1,green:0.88,blue:0.35), .white, Color(red:0.85,green:0.55,blue:0.05)],
            items: [
                .init(name: "Marigold Garlands", icon: "camera.macro", quantity: "20 strings (5 ft each)"),
                .init(name: "Yellow Fabric Drapes", icon: "rectangle.fill", quantity: "6 panels (5×8 ft)"),
                .init(name: "Brass Urli with Petals", icon: "circle.fill", quantity: "4 pieces"),
                .init(name: "Yellow & Orange Balloons", icon: "bubbles.and.sparkles", quantity: "50 balloons"),
                .init(name: "Turmeric Paste Bowls (Decorative)", icon: "cup.and.saucer.fill", quantity: "4 bowls"),
                .init(name: "Rangoli Stencils & Colours", icon: "paintpalette.fill", quantity: "1 set"),
                .init(name: "Floor Seating Cushions (Yellow)", icon: "rectangle.fill", quantity: "12 cushions"),
            ]
        ),

        DecorTheme(
            name: "Rustic Haldi Garden",
            category: .haldi,
            tagline: "Earthy haldi vibes with greenery",
            description: "A modern take on the traditional Haldi ceremony blending earthy tones with fresh greenery. Features rustic wooden backdrops adorned with marigolds and eucalyptus, jute accents, brass diya arrangements, and vintage-style photo frames. Brings together the warmth of tradition with contemporary elegance.",
            primaryColor: Color(red:0.75,green:0.60,blue:0.15),
            accentColor: Color(red:0.35,green:0.55,blue:0.25),
            swatches: [Color(red:0.75,green:0.60,blue:0.15), Color(red:0.35,green:0.55,blue:0.25), Color(red:0.9,green:0.80,blue:0.45), Color(red:0.65,green:0.45,blue:0.20), .white],
            items: [
                .init(name: "Wooden Photo Frame Backdrop", icon: "rectangle.fill", quantity: "1 frame (6×6 ft)"),
                .init(name: "Marigold & Eucalyptus Garlands", icon: "camera.macro", quantity: "15 strings"),
                .init(name: "Jute Table Runner", icon: "rectangle.fill", quantity: "3 pieces"),
                .init(name: "Brass Diya Set", icon: "flame.fill", quantity: "12 diyas"),
                .init(name: "Yellow Tulle Drapes", icon: "sparkles", quantity: "4 panels"),
                .init(name: "Terracotta Pots with Marigolds", icon: "camera.macro", quantity: "8 pots"),
            ]
        ),

        // ═══════════════ MEHNDI ═══════════════

        DecorTheme(
            name: "Royal Mehndi Night",
            category: .mehndi,
            tagline: "Vibrant colours for the mehndi celebration",
            description: "Create a regal mehndi setup with rich jewel tones of emerald green, deep purple, and hot pink. Features a stunning floral backdrop, traditional floor seating with colourful cushions and bolsters, hanging lanterns, and intricate mirror work accents. The perfect setting for a memorable mehndi evening.",
            primaryColor: Color(red:0.20,green:0.55,blue:0.20),
            accentColor: Color(red:0.85,green:0.15,blue:0.50),
            swatches: [Color(red:0.20,green:0.55,blue:0.20), Color(red:0.85,green:0.15,blue:0.50), Color(red:0.45,green:0.10,blue:0.65), Color(red:1,green:0.75,blue:0.0), .white],
            items: [
                .init(name: "Floral Backdrop Wall", icon: "camera.macro", quantity: "1 wall (8×6 ft)"),
                .init(name: "Colourful Floor Cushions", icon: "rectangle.fill", quantity: "16 cushions"),
                .init(name: "Bolster Pillows (Embroidered)", icon: "rectangle.fill", quantity: "8 pieces"),
                .init(name: "Hanging Lanterns (Multi-colour)", icon: "light.overhead.right.fill", quantity: "12 lanterns"),
                .init(name: "Mirror Work Hangings", icon: "sparkles", quantity: "6 pieces"),
                .init(name: "Mehndi Cone Display Tray", icon: "tray.fill", quantity: "2 trays"),
                .init(name: "Rose & Jasmine Garlands", icon: "camera.macro", quantity: "10 strings"),
            ]
        ),

        DecorTheme(
            name: "Pastel Mehndi Garden",
            category: .mehndi,
            tagline: "Modern pastel mehndi aesthetics",
            description: "A contemporary twist on the traditional mehndi celebration with soft pastels – mint green, blush pink, and lavender. Features a dreamy pastel floral arch, fairy light canopy, plush pastel seating, and delicate origami paper lanterns. Perfect for modern brides who love a fresh, Instagram-worthy aesthetic.",
            primaryColor: Color(red:0.65,green:0.85,blue:0.70),
            accentColor: Color(red:0.95,green:0.75,blue:0.80),
            swatches: [Color(red:0.65,green:0.85,blue:0.70), Color(red:0.95,green:0.75,blue:0.80), Color(red:0.80,green:0.75,blue:0.95), .white, Color(red:0.90,green:0.90,blue:0.70)],
            items: [
                .init(name: "Pastel Floral Arch", icon: "camera.macro", quantity: "1 arch (7 ft)"),
                .init(name: "Fairy Light Canopy", icon: "light.overhead.left.fill", quantity: "1 set (100 ft)"),
                .init(name: "Pastel Cushion Seating", icon: "rectangle.fill", quantity: "14 cushions"),
                .init(name: "Origami Paper Lanterns", icon: "light.overhead.right.fill", quantity: "10 lanterns"),
                .init(name: "Mint & Pink Balloon Garland", icon: "bubbles.and.sparkles", quantity: "1 garland (60 balloons)"),
                .init(name: "Mehndi Station Setup", icon: "tray.fill", quantity: "3 stations"),
            ]
        ),
    ]
}

