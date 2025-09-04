//
//  UpdateAlertView.swift
//  iLog
//
//  Created by Daniel Boyd on 9/3/25.
//


// UpdateAlertView.swift
import SwiftUI

struct UpdateAlertView: View {
    @ObservedObject var updateManager: UpdateManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Update Available")
                .font(.headline)
            
            Text("Version \(updateManager.latestVersion) is now available.")
                .multilineTextAlignment(.center)
            
            if !updateManager.releaseNotes.isEmpty {
                VStack(alignment: .leading) {
                    Text("Release Notes:")
                        .font(.subheadline)
                        .bold()
                    ScrollView {
                        Text(updateManager.releaseNotes)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                }
            }
            
            HStack(spacing: 20) {
                Button("Later") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Update Now") {
                    updateManager.downloadAndInstallUpdate { success, error in
                        if let error = error {
                            print("Update failed: \(error.localizedDescription)")
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }
}