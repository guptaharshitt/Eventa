// InvitationEditorView.swift
// Eventa – Canva-style invitation canvas editor

import SwiftUI
import PencilKit
import PhotosUI

// MARK: - Tool Mode
enum EditorTool: String, CaseIterable {
    case pointer    = "cursor.arrow"
    case text       = "textformat"
    case image      = "photo"
    case draw       = "pencil.tip"
    case eraser     = "eraser"
    case background = "paintpalette"
    case sticker    = "face.smiling"
}

// MARK: - Editor View
struct InvitationEditorView: View {
    let template: InvitationTemplate?
    var initialCategory: EventCategory? = nil
    let onSave: (SavedInvitationPreview) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var elements: [CanvasElement] = []
    @State private var selectedID: UUID? = nil
    @State private var activeTool: EditorTool = .pointer
    @State private var bgGradient: LinearGradient = LinearGradient(
        colors: [.white, Color(red: 0.95, green: 0.93, blue: 0.98)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    @State private var bgColor: Color = .white
    @State private var useGradientBG = false

    // Undo / redo
    @State private var elementHistory: [[CanvasElement]] = []
    @State private var redoStack: [[CanvasElement]] = []



    // Drawing / Erasing
    @State private var canvasView = PKCanvasView()
    @State private var showDrawingCanvas = false
    @State private var drawingHistory: [PKDrawing] = []

    // Category (from template or picker)
    @State private var editorCategory: EventCategory = .birthday

    // Sheets
    @State private var showImagePicker = false
    @State private var showBGPicker = false
    @State private var showStickerPanel = false
    @State private var showLayersPanel = false

    private let canvasSize = CGSize(width: 340, height: 500)

    // MARK: - Derived
    private var selectedElement: CanvasElement? {
        guard let sid = selectedID else { return nil }
        return elements.first { $0.id == sid }
    }

    var body: some View {
        ZStack {
            // Light context background
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                canvasArea
                Spacer(minLength: 0)
                propertyPanel
                bottomToolbar
            }
        }
        .onAppear(perform: loadTemplate)
        .sheet(isPresented: $showBGPicker) { bgPickerSheet }
        .sheet(isPresented: $showStickerPanel) { stickerPanel }
        .sheet(isPresented: $showLayersPanel) { layersPanel }
        .sheet(isPresented: $showImagePicker) {
            PhotoPickerWrapper { img in
                guard let img else { return }
                pushHistory()
                var el = CanvasElement(kind: .image)
                el.image = img
                el.position = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                el.size = CGSize(width: 160, height: 120)
                el.zIndex = Double(elements.count)
                elements.append(el)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 0) {
            // Close
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }
            .padding(.leading, 12)

            // Title
            Text("Eventa Editor")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(.label))
                .frame(maxWidth: .infinity)

            // Layers button
            Button { showLayersPanel = true } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }

            // Undo
            Button { performUndo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(elementHistory.isEmpty && drawingHistory.isEmpty ? Color(.tertiaryLabel) : Color(.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }
            .disabled(elementHistory.isEmpty && drawingHistory.isEmpty)

            // Redo
            Button { performRedo() } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(redoStack.isEmpty ? Color(.tertiaryLabel) : Color(.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }
            .disabled(redoStack.isEmpty)

            // Save
            Button { exportAndSave() } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Canvas Area
    private var canvasArea: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            ZStack {
                // Canvas paper
                Group {
                    if useGradientBG {
                        bgGradient
                    } else {
                        bgColor
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)

                ForEach($elements) { $el in
                    elementView(element: $el)
                }

                if showDrawingCanvas {
                    PKCanvasRepresentable(
                        canvasView: $canvasView,
                        isErasing: activeTool == .eraser,
                        onStrokeBegin: {
                            drawingHistory.append(canvasView.drawing)
                            if drawingHistory.count > 30 { drawingHistory.removeFirst() }
                        }
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .allowsHitTesting(activeTool == .draw || activeTool == .eraser)
                }

                // Canvas border when nothing selected (guide outline)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(selectedID == nil ? 0.15 : 0), lineWidth: 1)
            }
            .coordinateSpace(name: "Canvas")
            .frame(width: canvasSize.width, height: canvasSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 8)
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            if activeTool == .pointer { selectedID = nil }
        }
    }

    // MARK: - Single Element
    @ViewBuilder
    private func elementView(element: Binding<CanvasElement>) -> some View {
        let el = element.wrappedValue
        let isSelected = selectedID == el.id

        Group {
            switch el.kind {
            case .text:
                if isSelected {
                    TextField("Enter text", text: element.text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(Font.custom(el.fontName, size: el.fontSize).weight(el.isBold ? .bold : .regular))
                        .italic(el.isItalic)
                        .underline(el.isUnderline)
                        .foregroundColor(el.textColor)
                        .multilineTextAlignment(.center)
                        .frame(width: el.size.width)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(el.text.isEmpty ? "Tap to edit" : el.text)
                        .font(Font.custom(el.fontName, size: el.fontSize).weight(el.isBold ? .bold : .regular))
                        .italic(el.isItalic)
                        .underline(el.isUnderline)
                        .foregroundColor(el.textColor)
                        .multilineTextAlignment(.center)
                        .frame(width: el.size.width)
                        .fixedSize(horizontal: false, vertical: true)
                }
            case .image:
                if let img = el.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: el.size.width, height: el.size.height)
                        .clipped()
                }
            case .sticker:
                Text(el.text)
                    .font(.system(size: el.fontSize))
                    .frame(width: el.size.width, height: el.size.height)
            }
        }
        .rotationEffect(el.rotation)
        .position(el.position)
        .overlay {
            if isSelected {
                // Canva-style dashed selection border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        Color(red: 0.4, green: 0.7, blue: 1.0),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5])
                    )
                    .frame(
                        width: el.size.width + 12,
                        height: (el.kind == .text ? el.fontSize + 12 : el.size.height) + 12
                    )
                    .position(el.position)
            }
        }
        .gesture(
            SimultaneousGesture(
                DragGesture(coordinateSpace: .named("Canvas"))
                    .onChanged { val in
                        if activeTool == .pointer {
                            element.wrappedValue.position = val.location
                        }
                    }
                    .onEnded { _ in pushHistory() },
                MagnificationGesture()
                    .onChanged { scale in
                        element.wrappedValue.size = CGSize(
                            width: max(40, el.size.width * scale),
                            height: max(30, el.size.height * scale)
                        )
                    }
            )
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { angle in element.wrappedValue.rotation = el.rotation + angle }
        )
        .onTapGesture {
            selectedID = el.id
        }
        .zIndex(el.zIndex)
    }

    // MARK: - Contextual Property Panel
    @ViewBuilder
    private var propertyPanel: some View {
        if let sel = selectedElement {
            VStack(spacing: 0) {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        
                        if sel.kind == .text {
                            let idxOpt = elements.firstIndex(where: { $0.id == sel.id })
                            if let idx = idxOpt {
                                let el = elements[idx]
                                
                                panelButton(icon: "square.3.layers.3d", label: "Layers") {
                                    showLayersPanel = true
                                }
                                
                                panelButton(icon: "textformat", label: "Font") {
                                    pushHistory()
                                    let fonts = ["Georgia", "Avenir", "Helvetica", "Chalkboard SE", "Courier"]
                                    if let curr = fonts.firstIndex(of: el.fontName) {
                                        elements[idx].fontName = fonts[(curr + 1) % fonts.count]
                                    } else {
                                        elements[idx].fontName = fonts[0]
                                    }
                                }
                                
                                panelButton(icon: "minus.magnifyingglass", label: "Smaller") {
                                    pushHistory()
                                    elements[idx].fontSize = max(10, el.fontSize - 2)
                                }
                                
                                panelButton(icon: "plus.magnifyingglass", label: "Larger") {
                                    pushHistory()
                                    elements[idx].fontSize = min(120, el.fontSize + 2)
                                }
                                
                                panelToggle(icon: "bold", label: "Bold", isActive: el.isBold) {
                                    pushHistory()
                                    elements[idx].isBold.toggle()
                                }
                                
                                panelToggle(icon: "italic", label: "Italic", isActive: el.isItalic) {
                                    pushHistory()
                                    elements[idx].isItalic.toggle()
                                }
                                
                                panelToggle(icon: "underline", label: "Underline", isActive: el.isUnderline) {
                                    pushHistory()
                                    elements[idx].isUnderline.toggle()
                                }
                                
                                panelButton(icon: "trash", label: "Delete", accent: .red) {
                                    pushHistory()
                                    elements.removeAll { $0.id == sel.id }
                                    selectedID = nil
                                }
                            }
                        } else {
                            panelButton(icon: "square.3.layers.3d", label: "Layers") {
                                showLayersPanel = true
                            }
                            panelButton(icon: "trash", label: "Delete", accent: .red) {
                                pushHistory()
                                elements.removeAll { $0.id == sel.id }
                                selectedID = nil
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func panelButton(icon: String, label: String, accent: Color = Color(.label), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accent)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(accent.opacity(0.8))
            }
            .frame(width: 56, height: 50)
            .background(Color(.systemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func panelToggle(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? .white : Color(.label))
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? .white : Color(.label).opacity(0.8))
            }
            .frame(width: 56, height: 50)
            .background(isActive ? Color.accentColor : Color(.systemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(EditorTool.allCases, id: \.self) { tool in
                        Button {
                            withAnimation(.spring(duration: 0.22)) { activeTool = tool }
                            handleToolTap(tool)
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: tool.rawValue)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(activeTool == tool ? Color.accentColor : Color(.secondaryLabel))
                                Text(toolLabel(tool))
                                    .font(.system(size: 9.5, weight: activeTool == tool ? .semibold : .regular))
                                    .foregroundColor(activeTool == tool ? Color.accentColor : Color(.tertiaryLabel))
                            }
                            .frame(width: 60, height: 52)
                            .background(
                                activeTool == tool
                                    ? Color.accentColor.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        activeTool == tool ? Color.accentColor.opacity(0.3) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
        }
    }

    // MARK: - Tool Handling
    private func handleToolTap(_ tool: EditorTool) {
        switch tool {
        case .text:
            pushHistory()
            var el = CanvasElement(kind: .text)
            el.text = "Your Text Here"
            el.position = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            el.zIndex = Double(elements.count)
            elements.append(el)
            selectedID = el.id

        case .image:
            showImagePicker = true

        case .draw:
            showDrawingCanvas = true
            canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 3)

        case .eraser:
            showDrawingCanvas = true
            canvasView.tool = PKEraserTool(.bitmap)

        case .background:
            showBGPicker = true

        case .sticker:
            showStickerPanel = true

        case .pointer:
            showDrawingCanvas = false
        }
    }

    private func toolLabel(_ t: EditorTool) -> String {
        switch t {
        case .pointer:    return "Select"
        case .text:       return "Text"
        case .image:      return "Image"
        case .draw:       return "Draw"
        case .eraser:     return "Eraser"
        case .background: return "BG"
        case .sticker:    return "Sticker"
        }
    }

    // MARK: - Undo / Redo
    private func pushHistory() {
        elementHistory.append(elements)
        redoStack.removeAll()
        if elementHistory.count > 30 { elementHistory.removeFirst() }
    }

    private func performUndo() {
        if activeTool == .draw || activeTool == .eraser {
            if !drawingHistory.isEmpty {
                canvasView.drawing = drawingHistory.removeLast()
            }
        } else {
            if !elementHistory.isEmpty {
                redoStack.append(elements)
                elements = elementHistory.removeLast()
                selectedID = nil
            }
        }
    }

    private func performRedo() {
        if !redoStack.isEmpty {
            elementHistory.append(elements)
            elements = redoStack.removeLast()
            selectedID = nil
        }
    }



    // MARK: - BG Picker Sheet
    private var bgPickerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use Gradient", isOn: $useGradientBG)
                }
                if !useGradientBG {
                    Section("Solid Color") {
                        ColorPicker("Background", selection: $bgColor, supportsOpacity: false)
                    }
                } else {
                    Section("Gradient Presets") {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 10
                        ) {
                            ForEach(gradientPresets.indices, id: \.self) { i in
                                Button { bgGradient = gradientPresets[i] } label: {
                                    gradientPresets[i]
                                        .frame(height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showBGPicker = false }
                }
            }
        }
    }

    private var gradientPresets: [LinearGradient] {
        [
            LinearGradient(colors: [Color(red:0.48,green:0.18,blue:0.55), Color(red:0.91,green:0.65,blue:0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [.pink, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(red:0.1,green:0,blue:0.4), Color(red:0.5,green:0,blue:0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(red:0,green:0.55,blue:0.3), Color(red:0.9,green:0.9,blue:0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(red:0.85,green:0.65,blue:0.1), .black], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [.white, Color(red:0.9, green:0.85, blue:1)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(red:0.07,green:0.07,blue:0.07), Color(red:0.2,green:0.2,blue:0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
        ]
    }

    // MARK: - Sticker Panel
    private var stickerPanel: some View {
        NavigationStack {
            let stickers = ["🎂","🎈","🎉","🎁","🥳","✨","🌟","💝","👑","🦋","🌸","🎊","🍰","🎀","💐","🫧","🎵","🪄","🌈","💫"]
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                    ForEach(stickers, id: \.self) { s in
                        Button {
                            pushHistory()
                            var el = CanvasElement(kind: .sticker)
                            el.text = s
                            el.fontSize = 40
                            el.position = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                            el.size = CGSize(width: 60, height: 60)
                            el.zIndex = Double(elements.count)
                            elements.append(el)
                            showStickerPanel = false
                        } label: { Text(s).font(.system(size: 36)) }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showStickerPanel = false }
                }
            }
        }
    }

    // MARK: - Layers Panel
    private var layersPanel: some View {
        NavigationStack {
            List {
                ForEach(elements.sorted { $0.zIndex > $1.zIndex }) { el in
                    HStack(spacing: 12) {
                        // Miniature preview
                        Group {
                            switch el.kind {
                            case .text:
                                ZStack {
                                    Color(.secondarySystemFill)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Text("T")
                                        .font(.custom(el.fontName, size: 14))
                                        .foregroundColor(el.textColor)
                                }
                            case .image:
                                if let img = el.image {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Color(.secondarySystemFill)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            case .sticker:
                                Text(el.text)
                                    .font(.system(size: 22))
                            }
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(el.kind == .text ? el.text.prefix(20) + (el.text.count > 20 ? "…" : "") :
                                 el.kind == .sticker ? "Sticker \(el.text)" : "Image")
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text("Layer \(Int(el.zIndex))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: selectedID == el.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedID == el.id ? .accentColor : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedID = el.id
                        showLayersPanel = false
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showLayersPanel = false }
                }
            }
        }
    }

    // MARK: - Helpers
    private func loadTemplate() {
        if let initCat = initialCategory {
            editorCategory = initCat
        } else if let t = template {
            editorCategory = t.category
        }
        
        guard let t = template else { return }
        useGradientBG = true
        bgGradient = t.backgroundGradient
        for te in t.elements {
            var el = CanvasElement(kind: .text)
            el.text      = te.text
            el.fontSize  = te.fontSize
            el.fontName  = te.fontName
            el.textColor = te.color
            el.position  = CGPoint(
                x: canvasSize.width  * te.positionFraction.x,
                y: canvasSize.height * te.positionFraction.y
            )
            el.size  = CGSize(width: canvasSize.width - 40, height: 50)
            el.zIndex = Double(elements.count)
            elements.append(el)
        }
    }

    private func exportAndSave() {
        let renderer = ImageRenderer(content:
            ZStack {
                if useGradientBG { bgGradient } else { bgColor }
                ForEach(elements) { el in
                    Group {
                        switch el.kind {
                        case .text:
                            Text(el.text)
                                .font(Font.custom(el.fontName, size: el.fontSize).weight(el.isBold ? .bold : .regular))
                                .italic(el.isItalic)
                                .underline(el.isUnderline)
                                .foregroundColor(el.textColor)
                        case .image:
                            if let img = el.image {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: el.size.width, height: el.size.height).clipped()
                            }
                        case .sticker:
                            Text(el.text).font(.system(size: el.fontSize))
                        }
                    }
                    .rotationEffect(el.rotation)
                    .position(el.position)
                    .zIndex(el.zIndex)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
        )
        renderer.scale = 3.0
        if let img = renderer.uiImage {
            onSave(SavedInvitationPreview(
                name: "Invitation \(Date().formatted(date: .abbreviated, time: .omitted))",
                image: img,
                createdAt: Date(),
                eventCategory: editorCategory
            ))
            dismiss()
        }
    }
}


// MARK: - PencilKit Representable
struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var isErasing: Bool
    var onStrokeBegin: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onStrokeBegin: onStrokeBegin) }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = isErasing
            ? PKEraserTool(.bitmap)
            : PKInkingTool(.pen, color: .systemBlue, width: 3)
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = isErasing
            ? PKEraserTool(.bitmap)
            : PKInkingTool(.pen, color: .systemBlue, width: 3)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onStrokeBegin: () -> Void
        init(onStrokeBegin: @escaping () -> Void) { self.onStrokeBegin = onStrokeBegin }
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) { onStrokeBegin() }
    }
}

// MARK: - Photo Picker Wrapper
struct PhotoPickerWrapper: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { onPick(nil); return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async { self.onPick(obj as? UIImage) }
            }
        }
    }
}

#Preview {
    InvitationEditorView(template: InvitationTemplate.all[0], onSave: { _ in })
}
