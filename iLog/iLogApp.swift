//
//  iLogApp.swift
//  iLog
//
//  Created by Daniel Boyd on 8/31/25.
//

import SwiftUI

@main
struct iLogApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var updateManager = UpdateManager(repoOwner: "TBelteshazzarT", repoName: "iLog")
    @State private var showUpdateAlert = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .onAppear {
                    // Check for updates 2 seconds after app launches
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        updateManager.checkForUpdates()
                    }
                }
                .alert(isPresented: $updateManager.showUpdateAlert) {
                    Alert(
                        title: Text("Update Available"),
                        message: Text("iLog \(updateManager.latestVersion) is now available. Would you like to update now?"),
                        primaryButton: .default(Text("Update Now")) {
                            updateManager.downloadAndInstallUpdate { success, error in
                                if let error = error {
                                    // You might want to show an error alert here
                                    print("Update failed: \(error.localizedDescription)")
                                }
                            }
                        },
                        secondaryButton: .cancel(Text("Later"))
                    )
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateManager.checkForUpdates()
                }
                
                if updateManager.updateAvailable {
                    Divider()
                    Button("Install iLog \(updateManager.latestVersion)") {
                        updateManager.downloadAndInstallUpdate { success, error in
                            if let error = error {
                                print("Update error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
}
