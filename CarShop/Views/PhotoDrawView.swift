import SwiftUI
import SwiftData

struct PhotoDrawView: View {
    let item: Item

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var text: String = ""
    @State private var textOffset: CGSize = .zero
    @State private var dragStart: CGSize = .zero
    @State private var fontSize: CGFloat = 32
    @State private var textColor: Color = .white

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                photoCanvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

                controls
                    .background(colorScheme == .dark ? Color(white: 0.12) : Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Draw")
                        .font(.openSansHeadline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    //Photo
    @ViewBuilder
    private var photoCanvas: some View {
        ZStack {
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

            if !text.isEmpty {
                overlayText
                    .offset(textOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                textOffset = CGSize(
                                    width: dragStart.width + value.translation.width,
                                    height: dragStart.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                dragStart = textOffset
                            }
                    )
            }
        }
    }

    private var overlayText: some View {
        Text(text)
            .font(.custom("OpenSans-Bold", size: fontSize))
            .foregroundStyle(textColor)
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            .padding(8)
    }

    
    //Controls
    private var controls: some View {
        VStack(spacing: 12) {
            TextField("Add text…", text: $text)
                .font(.openSansBody)
                .padding(8)
                .background(colorScheme == .dark ? Color(white: 0.22) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 16) {
                ColorPicker("", selection: $textColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 36, height: 36)

                HStack(spacing: 8) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundStyle(.secondary)
                    Slider(value: $fontSize, in: 14...96)
                    Image(systemName: "textformat.size.larger")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    //Save
    @MainActor
    private func save() {
        guard let data = item.photoData,
              let uiImage = UIImage(data: data) else {
            dismiss()
            return
        }

        let rendered = render(baseImage: uiImage)
        if let jpeg = rendered.jpegData(compressionQuality: 0.9) {
            item.photoData = jpeg
        }
        dismiss()
    }

   
    @MainActor
    private func render(baseImage: UIImage) -> UIImage {
        let composition = ZStack {
            Image(uiImage: baseImage)
                .resizable()
                .scaledToFit()
                .frame(width: baseImage.size.width, height: baseImage.size.height)
            Text(text)
                .font(.custom("OpenSans-Bold", size: fontSize * (baseImage.size.height / 600)))
                .foregroundStyle(textColor)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                .offset(
                    x: textOffset.width * (baseImage.size.width / 400),
                    y: textOffset.height * (baseImage.size.height / 600)
                )
        }
        .frame(width: baseImage.size.width, height: baseImage.size.height)

        let renderer = ImageRenderer(content: composition)
        renderer.scale = 1
        return renderer.uiImage ?? baseImage
    }
}
