//
//  V2RayUSAApp.swift
//  V2RayUSA
//
//  Main app entry point for V2RayUSA
//

import SwiftUI

@main
struct V2RayUSAApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
