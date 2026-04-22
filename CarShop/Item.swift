import Foundation
import SwiftData

@Model
final class Item {
    var name: String
    var itemDescription: String
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date

    init(name: String, itemDescription: String, photoData: Data?, createdAt: Date = .now) {
        self.name = name
        self.itemDescription = itemDescription
        self.photoData = photoData
        self.createdAt = createdAt
    }
}
