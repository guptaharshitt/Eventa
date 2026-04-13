// MemoryFolderView.swift
// Eventa (Apple-native style)
// Created By Harshit

import SwiftUI
import Photos
import PhotosUI
import AVKit

struct MemoryFolderView: View {
    var appState: AppState
    var baseFolder: MemoryFolder
    
    init(appState: AppState, folder: MemoryFolder) {
        self.appState = appState
        self.baseFolder = folder
    }

    private var folder: MemoryFolder {
        appState.memoryFolders.first(where: { $0.id == baseFolder.id }) ?? baseFolder
    }
    @State private var showPicker = false
    @State private var showReelCreator = false
    @State private var selectedItemIndex: Int? = nil
    @State private var showFullscreen = false

    let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        Group {
            if folder.items.isEmpty {
                ContentUnavailableView {
                    Label("No Photos or Videos", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Tap + to add photos and videos from your gallery.")
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(folder.items.indices, id: \.self) { i in
                            let item = folder.items[i]
                            ZStack(alignment: .bottomTrailing) {
                                AsyncAssetImage(asset: item.asset)
                                    .frame(height: 120)
                                    .clipped()
                                
                                if item.isVideo {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .shadow(radius: 4)
                                        .padding(6)
                                }
                            }
                            .onTapGesture {
                                selectedItemIndex = i
                                showFullscreen = true
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.emoji + " " + folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    if !folder.items.isEmpty {
                        Button {
                            showReelCreator = true
                        } label: {
                            Image(systemName: "film.stack")
                        }
                    }
                    Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            MultiMediaPicker { assets in
                let newItems = assets.map { MediaItem(asset: $0) }
                if let idx = appState.memoryFolders.firstIndex(where: { $0.id == folder.id }) {
                    appState.memoryFolders[idx].items.append(contentsOf: newItems)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            if let idx = selectedItemIndex {
                FullscreenMediaViewer(items: folder.items, startIndex: idx)
            }
        }
        .fullScreenCover(isPresented: $showReelCreator) {
            ReelCreatorView(items: folder.items)
        }
    }
}

// MARK: - Multi Media Picker
struct MultiMediaPicker: UIViewControllerRepresentable {
    let onPick: ([PHAsset]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: ([PHAsset]) -> Void
        init(onPick: @escaping ([PHAsset]) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let identifiers = results.compactMap(\.assetIdentifier)
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            var assets: [PHAsset] = []
            assetResults.enumerateObjects { asset, _, _ in assets.append(asset) }
            DispatchQueue.main.async { self.onPick(assets) }
        }
    }
}

// MARK: - Fullscreen Viewer
struct FullscreenMediaViewer: View {
    let items: [MediaItem]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { i in
                    let item = items[i]
                    if item.isVideo {
                        VideoPlayerCell(asset: item.asset)
                            .tag(i)
                    } else if let img = item.thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .tag(i)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onAppear { currentIndex = startIndex }

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 4)
            }
            .padding(20)
        }
    }
}

// MARK: - Video Player Cell
struct VideoPlayerCell: View {
    let asset: PHAsset
    @State private var player: AVPlayer? = nil

    var body: some View {
        Group {
            if let p = player {
                VideoPlayer(player: p)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            let opts = PHVideoRequestOptions()
            opts.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: opts) { avAsset, _, _ in
                guard let avAsset else { return }
                DispatchQueue.main.async {
                    self.player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
                    self.player?.play()
                }
            }
        }
    }
}

// MARK: - Async Asset Image
struct AsyncAssetImage: View {
    let asset: PHAsset
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay {
                        ProgressView().tint(.gray)
                    }
                    .onAppear { load() }
            }
        }
    }
    
    private func load() {
        let size = CGSize(width: 300, height: 300)
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .opportunistic
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: opts) { img, _ in
            DispatchQueue.main.async { self.image = img }
        }
    }
}

#Preview {
    NavigationStack {
        MemoryFolderView(appState: AppState.shared, folder: {
            let f = MemoryFolder(name: "Birthday Party", emoji: "🎂")
            return f
        }())
    }
}

