import SwiftUI

struct TextOverlay: Identifiable {
    let id = UUID()
    var text: String = ""
    var offset: CGSize = .zero
    var fontSize: CGFloat = 32
    var dragStart: CGSize = .zero
    var pinchStart: CGFloat = 32
}

struct PhotoDrawView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss

    @State private var overlays: [TextOverlay] = []
    @State private var pending: TextOverlay = TextOverlay()
    @State private var isPending: Bool = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        NavigationStack {
            photoCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isPending {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPending = false }
            }
            ToolbarItem(placement: .principal) {
                Text("Draw").font(.spaceGroteskHeadline)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { commitPending() }
                    .disabled(pending.text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text("Draw").font(.spaceGroteskHeadline)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(overlays.isEmpty)
            }
        }
    }

    @ViewBuilder
    private var photoCanvas: some View {
        GeometryReader { proxy in
            ZStack {
                photoImage
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard !isPending else { return }
                        let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        let newOffset = CGSize(
                            width: location.x - center.x,
                            height: location.y - center.y
                        )
                        pending = TextOverlay(
                            offset: newOffset,
                            dragStart: newOffset
                        )
                        isPending = true
                        textFieldFocused = true
                    }

                ForEach(overlays) { overlay in
                    committedView(for: overlay)
                }

                if isPending {
                    pendingView(canvasWidth: proxy.size.width)
                }
            }
        }
    }

    private func committedView(for overlay: TextOverlay) -> some View {
        Text(overlay.text)
            .font(.custom("SpaceGrotesk-Bold", size: overlay.fontSize))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            .padding(8)
            .offset(overlay.offset)
            .onTapGesture {
                guard !isPending, let i = indexOf(overlay) else { return }
                pending = overlays.remove(at: i)
                isPending = true
                textFieldFocused = true
            }
    }

    private func pendingView(canvasWidth: CGFloat) -> some View {
        TextField(
            "",
            text: $pending.text,
            prompt: Text("Add text").foregroundStyle(.white.opacity(0.7))
        )
            .font(.custom("SpaceGrotesk-Bold", size: pending.fontSize))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .focused($textFieldFocused)
            .submitLabel(.done)
            .onSubmit { commitPending() }
            .padding(.horizontal, 8)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: canvasWidth * 0.8)
            .offset(pending.offset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        pending.offset = CGSize(
                            width: pending.dragStart.width + value.translation.width,
                            height: pending.dragStart.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        pending.dragStart = pending.offset
                    }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        pending.fontSize = max(8, min(200, pending.pinchStart * value.magnification))
                    }
                    .onEnded { _ in
                        pending.pinchStart = pending.fontSize
                    }
            )
    }

    @ViewBuilder
    private var photoImage: some View {
        if let data = item.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Color.gray.opacity(0.3)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                )
        }
    }

    private func indexOf(_ overlay: TextOverlay) -> Int? {
        overlays.firstIndex(where: { $0.id == overlay.id })
    }

    private func commitPending() {
        if !pending.text.trimmingCharacters(in: .whitespaces).isEmpty {
            overlays.append(pending)
        }
        isPending = false
    }

    @MainActor
    private func save() {
        guard let data = item.photoData,
              let uiImage = UIImage(data: data) else {
            dismiss()
            return
        }

        let rendered = render(baseImage: uiImage)
        UIImageWriteToSavedPhotosAlbum(rendered, nil, nil, nil)
        dismiss()
    }

    @MainActor
    private func render(baseImage: UIImage) -> UIImage {
        let composition = ZStack {
            Image(uiImage: baseImage)
                .resizable()
                .scaledToFit()
                .frame(width: baseImage.size.width, height: baseImage.size.height)

            ForEach(overlays) { overlay in
                Text(overlay.text)
                    .font(.custom("SpaceGrotesk-Bold", size: overlay.fontSize * (baseImage.size.height / 600)))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    .offset(
                        x: overlay.offset.width * (baseImage.size.width / 400),
                        y: overlay.offset.height * (baseImage.size.height / 600)
                    )
            }
        }
        .frame(width: baseImage.size.width, height: baseImage.size.height)

        let renderer = ImageRenderer(content: composition)
        renderer.scale = 1
        return renderer.uiImage ?? baseImage
    }
}
