//
//  MetalPetalExamplesApp.swift
//  Shared
//
//  Created by YuAo on 2021/4/8.
//

import SwiftUI

@main
struct MetalPetalExamplesApp: App {
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            true
        }
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }.commands(content: {
            SidebarCommands()
        })
    }
}
