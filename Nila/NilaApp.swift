//
//  NilaApp.swift
//  Nila
//
//  Created by Niloufar on 15/11/25.
//

import SwiftUI

@main
struct IAmApp3App: App {
    var body: some Scene {
        WindowGroup {
            PagedAffirmationsView(phrases: [
                "I am full of infinite hope.",
                "I am grounded, calm, and present.",
                "I am worthy of love and peace.",
                "I am growing into my best self.",
                "I am resilient and capable.",
                "I am grateful for this moment.",
                "I am open to joy and abundance.",
                "I am confident in my path.",
                "I am kind to myself and others.",
                "I am learning and evolving every day.",
                "I am strong in mind, body, and spirit.",
                "I am exactly where I need to be."
            ])
        }
    }
}

