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
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("Item")
                    if items.count != 1 {
                        Text("s")
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .font(.openSansLargeTitle)
                .animation(.easeInOut(duration: 0.25), value: items.count)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if items.isEmpty {
                        ContentUnavailableView(
                            "No items.",
                            systemImage: "tray",
                            description: Text("Tap + to add item.")
                        )
                    } else {
                        List {
                            ForEach(items, id: \.persistentModelID) { item in
                                NavigationLink {
                                    ItemDetailView(item: item)
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
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAdding = true
                    } label: {
                        Label("Add item", systemImage: "plus")
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
                    .font(.openSansHeadline)
                Text(item.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.openSansCaption)
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
