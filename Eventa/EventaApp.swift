//
//  EventaApp.swift
//  Eventa
//
//  Created by HARSHIT on 23/03/26.
//

import SwiftUI

@main
struct EventaApp: App {
    @State private var store = EventStore() // Initialize the store

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store) // Pass it to all views
        }
    }
}
