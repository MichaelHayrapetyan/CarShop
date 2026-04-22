//
//  CarShopApp.swift
//  CarShop
//
//  Created by Michael Hayrapetyan on 22.04.26.
//

import SwiftUI
import SwiftData

@main
struct CarShopApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
