//
//  ContentView.swift
//  CarShop
//
//  Created by Michael Hayrapetyan on 22.04.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]

    @State private var isAdding = false
    @State private var editingItem: Item?
    @State private var pendingDeletion: Item?

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No cars.",
                        systemImage: "tray",
                        description: Text("Tap + to add your first car.")
                    )
                } else {
                    List {
                        ForEach(items, id: \.persistentModelID) { item in
                            NavigationLink {
                                CarDetailView(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        pendingDeletion = item
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Cars")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAdding = true
                    } label: {
                        Label("Add car", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                ItemEditor(mode: .add)
            }
            .sheet(item: $editingItem) { item in
                ItemEditor(mode: .edit(item))
            }
            .alert(
                pendingDeletion.map { "Delete “\($0.name)”?" } ?? "Delete item?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                presenting: pendingDeletion
            ) { item in
                Button("Delete", role: .destructive) {
                    pendingDeletion = nil
                    withAnimation {
                        modelContext.delete(item)
                    }
                }
                Button("Cancel", role: .cancel) {
                    pendingDeletion = nil
                }
            } message: { _ in
                Text("Net puti nazad.")
            }
        }
    }
}

private struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = item.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
