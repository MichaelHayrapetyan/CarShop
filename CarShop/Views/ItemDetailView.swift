import SwiftUI

struct ItemDetailView: View {
    let item: Item

    @State private var isEditing = false
    @State private var isDrawing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photo
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.spaceGroteskLargeTitle)
                    Label {
                        Text("Added \(item.createdAt, format: .dateTime.year().month().day().hour().minute())")
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.spaceGroteskSubheadline)
                    .foregroundStyle(.secondary)
                }
                Divider()
                if item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No description")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(item.itemDescription)
                        .font(.spaceGroteskBody)
                }

                if item.photoData != nil {
                    Divider()
                        .padding(.top, 8)

                    HStack {
                        Spacer()
                        Button {
                            isDrawing = true
                        } label: {
                            Label("Draw", systemImage: "pencil.tip.crop.circle")
                                .font(.spaceGroteskHeadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.glass)
                        .frame(maxWidth: 150)
                        .frame(maxHeight: 75)
                        .controlSize(.regular)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            ItemEditor(mode: .edit(item))
        }
        .fullScreenCover(isPresented: $isDrawing) {
            PhotoDrawView(item: item)
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let data = item.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 240)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                )
        }
    }
}
