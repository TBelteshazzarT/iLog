//
//  UpdateAlertView.swift
//  iLog
//
//  Created by Daniel Boyd on 9/3/25.
//

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
            
            // Always show release notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Release Notes:")
                    .font(.subheadline)
                    .bold()
                
                Text(updateManager.releaseNotes)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            HStack(spacing: 20) {
                Button("Later") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Update Now") {
                    updateManager.downloadAndInstallUpdate { success, error in
                        if let error = error {
                            print("Update failed: \(error.localizedDescription)")
                            // You might want to show an error alert here
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
