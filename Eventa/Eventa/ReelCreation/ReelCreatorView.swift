//
//  ReelCreatorView.swift
//  Eventa
//
//  Created by HARSHIT on 08/04/26.
//

import SwiftUI
import Photos
import AVFoundation
import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Filter Preset
struct FilterPreset: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let ciFilterName: String?          // nil = Original (no filter)
    let icon: String

    static let all: [FilterPreset] = [
        FilterPreset(name: "Original",  ciFilterName: nil,                          icon: "circle"),
        FilterPreset(name: "Vivid",     ciFilterName: "CIPhotoEffectProcess",       icon: "sun.max"),
        FilterPreset(name: "Noir",      ciFilterName: "CIPhotoEffectNoir",          icon: "moon.fill"),
        FilterPreset(name: "Chrome",    ciFilterName: "CIPhotoEffectChrome",        icon: "sparkles"),
        FilterPreset(name: "Fade",      ciFilterName: "CIPhotoEffectFade",          icon: "cloud"),
        FilterPreset(name: "Warm",      ciFilterName: "CIPhotoEffectTransfer",      icon: "flame"),
        FilterPreset(name: "Cool",      ciFilterName: "CIColorMonochrome",          icon: "snowflake"),
        FilterPreset(name: "Bloom",     ciFilterName: "CIBloom",                    icon: "camera.macro"),
        FilterPreset(name: "Sepia",     ciFilterName: "CISepiaTone",               icon: "paintbrush"),
        FilterPreset(name: "Mono",      ciFilterName: "CIPhotoEffectMono",          icon: "circle.lefthalf.filled"),
    ]

    static func == (lhs: FilterPreset, rhs: FilterPreset) -> Bool { lhs.id == rhs.id }
}

// MARK: - Editor Tab
enum ReelEditorTab: String, CaseIterable {
    case clips   = "Clips"
    case filters = "Filters"
    case music   = "Music"

    var icon: String {
        switch self {
        case .clips:   return "photo.stack"
        case .filters: return "camera.filters"
        case .music:   return "music.note"
        }
    }
}

// MARK: - Reel Creator View
struct ReelCreatorView: View {
    let items: [MediaItem]
    @Environment(\.dismiss) private var dismiss

    // Selection & ordering
    @State private var selectedItems: [MediaItem] = []
    @State private var previewIndex: Int = 0

    // Tabs
    @State private var activeTab: ReelEditorTab = .clips

    // Filter
    @State private var selectedFilter: FilterPreset = FilterPreset.all[0]

    // Music
    @State private var selectedMusicName: String? = nil

    // Settings
    @State private var photoDuration: Double = 2.0
    @State private var showDurationSlider = false

    // Export
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportedURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMsg = ""

    // Clip editor
    @State private var editingClip: MediaItem? = nil
    @State private var overlayText = ""

    // CIContext for filter previews
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    private let musicTracks: [(name: String, symbol: String, color: Color)] = [
        ("Happy Birthday 🎂",     "music.note",           .pink),
        ("Party Vibes 🎉",        "music.note.list",      .orange),
        ("Dreamy Moments ✨",     "waveform",             .purple),
        ("Celebration Beat 🥳",   "music.quarternote.3",  .cyan),
        ("Chill Sunset 🌅",       "music.mic",            .yellow),
        ("No Music",              "speaker.slash",        .gray),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isExporting {
                exportingOverlay
            } else {
                VStack(spacing: 0) {
                    topBar
                    previewArea
                    tabBar
                    bottomPanel
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMsg)
        }
        .fullScreenCover(item: $editingClip) { clip in
            ClipEditorView(item: clip, text: $overlayText)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Create Reel")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Button {
                guard !selectedItems.isEmpty else { return }
                composeReel()
            } label: {
                Text("Export")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(selectedItems.isEmpty ? .gray : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedItems.isEmpty ? Color.gray.opacity(0.3) : Color.white)
                    .clipShape(Capsule())
            }
            .disabled(selectedItems.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Preview Area
    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))

            if selectedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Select clips to preview")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                let safeIndex = min(previewIndex, selectedItems.count - 1)
                let item = selectedItems[max(0, safeIndex)]
                if let img = item.thumbnail {
                    Image(uiImage: applyFilter(to: img))
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .transition(.opacity)
                        .id("\(item.id)-\(selectedFilter.name)")
                } else {
                    ProgressView()
                        .tint(.white)
                }

                // Overlay text if any
                if !overlayText.isEmpty {
                    Text(overlayText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 6)
                        .padding()
                        .background(Color.black.opacity(0.25).cornerRadius(10))
                }

                // Clip counter
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(min(previewIndex + 1, selectedItems.count))/\(selectedItems.count)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.42)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onTapGesture {
            // Cycle through preview on tap
            if !selectedItems.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    previewIndex = (previewIndex + 1) % selectedItems.count
                }
            }
        }
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ReelEditorTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.3)) { activeTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(activeTab == tab ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    // MARK: - Bottom Panel
    private var bottomPanel: some View {
        Group {
            switch activeTab {
            case .clips:   clipsPanel
            case .filters: filtersPanel
            case .music:   musicPanel
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Clips Panel
    private var clipsPanel: some View {
        VStack(spacing: 10) {
            // Duration & summary
            HStack {
                Label("\(selectedItems.count) clips", systemImage: "film")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Label(reelDurationString(), systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button {
                    withAnimation { showDurationSlider.toggle() }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            if showDurationSlider {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Photo duration: \(String(format: "%.1f", photoDuration))s")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Slider(value: $photoDuration, in: 1...5, step: 0.5)
                        .tint(.white)
                }
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Clip strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        let isSelected = selectedItems.contains(where: { $0.id == item.id })
                        let order = selectedItems.firstIndex(where: { $0.id == item.id })

                        clipThumbnail(item: item, isSelected: isSelected, order: order)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.25)) {
                                    if isSelected {
                                        selectedItems.removeAll { $0.id == item.id }
                                        // Adjust preview index
                                        if !selectedItems.isEmpty {
                                            previewIndex = min(previewIndex, selectedItems.count - 1)
                                        }
                                    } else {
                                        selectedItems.append(item)
                                        previewIndex = selectedItems.count - 1
                                    }
                                }
                            }
                            .onLongPressGesture {
                                if isSelected {
                                    editingClip = item
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Selected order strip
            if !selectedItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Timeline Order")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(selectedItems.enumerated()), id: \.element.id) { idx, item in
                                ZStack(alignment: .topLeading) {
                                    if let img = item.thumbnail {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 52, height: 52)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 52, height: 52)
                                    }
                                    Text("\(idx + 1)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                        .offset(x: -2, y: -2)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            previewIndex == idx ? Color.accentColor : Color.white.opacity(0.15),
                                            lineWidth: previewIndex == idx ? 2 : 1
                                        )
                                )
                                .onTapGesture {
                                    withAnimation { previewIndex = idx }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func clipThumbnail(item: MediaItem, isSelected: Bool, order: Int?) -> some View {
        ZStack(alignment: .topTrailing) {
            if let img = item.thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 72, height: 72)
            }

            // Video badge
            if item.isVideo {
                HStack(spacing: 2) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 7))
                    Text(formatDuration(item.duration))
                        .font(.system(size: 8, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            // Selection indicator
            ZStack {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                        .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.0 : 0.95)
    }

    // MARK: - Filters Panel
    private var filtersPanel: some View {
        VStack(spacing: 12) {
            Text("Tap a filter to preview")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterPreset.all) { filter in
                        let isActive = selectedFilter.id == filter.id
                        filterCell(filter: filter, isActive: isActive)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Current filter label
            HStack {
                Image(systemName: "camera.filters")
                    .foregroundColor(.accentColor)
                Text(selectedFilter.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 6)

            Spacer(minLength: 0)
        }
    }

    private func filterCell(filter: FilterPreset, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if let firstItem = selectedItems.first, let thumb = firstItem.thumbnail {
                    Image(uiImage: applyFilter(to: thumb, using: filter))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 68)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .overlay(
                            Image(systemName: filter.icon)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )
            .shadow(color: isActive ? Color.accentColor.opacity(0.4) : .clear, radius: 6)

            Text(filter.name)
                .font(.caption2.weight(isActive ? .bold : .regular))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
        }
    }

    // MARK: - Music Panel
    private var musicPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(musicTracks, id: \.name) { track in
                    let isSelected = selectedMusicName == track.name
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedMusicName = isSelected ? nil : track.name
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: track.symbol)
                                .font(.system(size: 18))
                                .foregroundColor(isSelected ? track.color : .white.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .background(
                                    isSelected
                                        ? track.color.opacity(0.15)
                                        : Color.white.opacity(0.06)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text(track.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.accentColor)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            // Waveform visual
                            if isSelected {
                                HStack(spacing: 2) {
                                    ForEach(0..<5, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(track.color.opacity(0.6))
                                            .frame(width: 3, height: CGFloat.random(in: 8...20))
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: - Export Overlay
    private var exportingOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: exportProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.accentColor, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: exportProgress)

                Text("\(Int(exportProgress * 100))%")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundColor(.white)
            }

            Text("Creating Your Reel…")
                .font(.headline)
                .foregroundColor(.white)

            Text("Applying \(selectedFilter.name) filter")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers
    private func reelDurationString() -> String {
        let videoSecs = selectedItems.filter(\.isVideo).reduce(0.0) { $0 + $1.duration }
        let photoSecs = Double(selectedItems.filter { !$0.isVideo }.count) * photoDuration
        let total = videoSecs + photoSecs
        if total < 60 { return "\(Int(total))s" }
        return "\(Int(total / 60))m\(Int(total.truncatingRemainder(dividingBy: 60)))s"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    private func applyFilter(to image: UIImage) -> UIImage {
        applyFilter(to: image, using: selectedFilter)
    }

    private func applyFilter(to image: UIImage, using filter: FilterPreset) -> UIImage {
        guard let filterName = filter.ciFilterName,
              let cgImage = image.cgImage else { return image }

        let ciImage = CIImage(cgImage: cgImage)

        // Handle different filter types
        guard let ciFilter = CIFilter(name: filterName) else { return image }
        ciFilter.setValue(ciImage, forKey: kCIInputImageKey)

        // Special parameter handling
        if filterName == "CISepiaTone" {
            ciFilter.setValue(0.8, forKey: kCIInputIntensityKey)
        } else if filterName == "CIBloom" {
            ciFilter.setValue(10.0, forKey: kCIInputRadiusKey)
            ciFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        } else if filterName == "CIColorMonochrome" {
            ciFilter.setValue(CIColor(red: 0.5, green: 0.7, blue: 0.9), forKey: kCIInputColorKey)
            ciFilter.setValue(0.5, forKey: kCIInputIntensityKey)
        }

        guard let output = ciFilter.outputImage,
              let cgResult = ciContext.createCGImage(output, from: ciImage.extent) else {
            return image
        }
        return UIImage(cgImage: cgResult)
    }

    // MARK: - Compose Reel
    private func composeReel() {
        isExporting = true
        exportProgress = 0
        let assets = selectedItems.map(\.asset)
        let filterName = selectedFilter.ciFilterName

        Task {
            do {
                let url = try await VideoComposer.shared.compose(
                    assets: assets,
                    photoDuration: photoDuration,
                    filterName: filterName,
                    progressHandler: { p in
                        DispatchQueue.main.async { exportProgress = p }
                    }
                )
                await MainActor.run {
                    isExporting = false
                    exportedURL = url
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    errorMsg = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ReelCreatorView(items: [])
}

// MARK: - Instagram-style Clip Editor
struct ClipEditorView: View {
    let item: MediaItem
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingText = false
    @State private var tempText = ""
    @State private var selectedColor: Color = .white

    let colors: [Color] = [.white, .black, .red, .blue, .cyan, .yellow, .green, .orange, .pink, .purple]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = item.thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !text.isEmpty && !isAddingText {
                Text(text)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(selectedColor)
                    .shadow(color: .black.opacity(0.5), radius: 5)
                    .padding()
                    .background(Color.black.opacity(0.3).cornerRadius(12))
                    .offset(y: -50)
            }

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    Spacer()
                    HStack(spacing: 20) {
                        Button { isAddingText = true; tempText = text } label: {
                            Image(systemName: "textformat")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Button { } label: {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                Spacer()

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.body.weight(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }

            if isAddingText {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()

                    VStack {
                        HStack {
                            Spacer()
                            Button("Done") {
                                text = tempText
                                isAddingText = false
                            }
                            .font(.body.weight(.bold))
                            .foregroundColor(.white)
                            .padding()
                        }

                        Spacer()

                        TextField("Type something...", text: $tempText)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(selectedColor)
                            .multilineTextAlignment(.center)

                        Spacer()

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                        .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0))
                                        .onTapGesture { selectedColor = color }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
