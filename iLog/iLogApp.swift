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
    @StateObject private var updateManager = UpdateManager(
        repoOwner: "TBelteshazzarT",
        repoName: "iLog",
        appName: "iLog",
        githubToken: nil // Optional: add your GitHub token here if needed
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(updateManager)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        updateManager.checkForUpdates()
                    }
                }
                // Replace the alert with a sheet that shows your custom UpdateAlertView
                .sheet(isPresented: $updateManager.showUpdateAlert) {
                    UpdateAlertView(updateManager: updateManager)
                }
        }
    }
}
