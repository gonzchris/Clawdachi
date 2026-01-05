//
//  ClawdachiApp.swift
//  Clawdachi
//
//  Created by Chris Gonzalez on 1/3/26.
//

import SwiftUI

@main
struct ClawdachiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
