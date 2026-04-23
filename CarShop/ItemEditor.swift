import SwiftUI
import SwiftData
import PhotosUI

struct ItemEditor: View {
    enum Mode {
        case add
        case edit(Item)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var itemDescription: String = ""
    @State private var photoData: Data?
    @State private var photoSelection: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }
                Section("Description") {
                    TextField("Description", text: $itemDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Photo") {
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .transition(.opacity.combined(with: .scale(scale: 0.85)))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    PhotosPicker(
                        selection: $photoSelection,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(photoData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                    }
                    if photoData != nil {
                        Button(role: .destructive) {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                photoData = nil
                                photoSelection = nil
                            }
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadInitial)
            .onChange(of: photoSelection) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            photoData = data
                        }
                    }
                }
            }
        }
    }

    private var titleText: String {
        switch mode {
        case .add: return "New Item"
        case .edit: return "Edit Item"
        }
    }

    private func loadInitial() {
        if case .edit(let item) = mode {
            name = item.name
            itemDescription = item.itemDescription
            photoData = item.photoData
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .add:
            let item = Item(
                name: trimmedName,
                itemDescription: itemDescription,
                photoData: photoData
            )
            modelContext.insert(item)
        case .edit(let item):
            item.name = trimmedName
            item.itemDescription = itemDescription
            item.photoData = photoData
        }
        dismiss()
    }
}
