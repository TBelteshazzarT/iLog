//
//  SettingsView.swift
//  iLog
//
//  Created by Daniel Boyd on 9/6/25.
//


//
//  SettingsView.swift
//  iLog
//
//  Created by Daniel Boyd on 8/31/25.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("syncFrequency") private var syncFrequency = 15
    @AppStorage("theme") private var theme = "System"
    @Environment(\.dismiss) private var dismiss
    
    let syncOptions = [5, 15, 30, 60]
    let themeOptions = ["System", "Light", "Dark"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General")) {
                    Toggle("Auto Save", isOn: $autoSave)
                    
                    Picker("Sync Frequency", selection: $syncFrequency) {
                        ForEach(syncOptions, id: \.self) { minutes in
                            Text("Every \(minutes) min")
                        }
                    }
                    
                    Picker("Appearance", selection: $theme) {
                        ForEach(themeOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }
                
                Section(header: Text("Data")) {
                    Button("Export Data") {
                        exportData()
                    }
                    
                    Button("Import Data") {
                        importData()
                    }
                    
                    Button("Clear All Data", role: .destructive) {
                        confirmClearData()
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Visit Website", destination: URL(string: "https://yourwebsite.com")!)
                    Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 600)
        }
    }
    
    private func exportData() {
        // Placeholder for export functionality
        print("Export data")
    }
    
    private func importData() {
        // Placeholder for import functionality
        print("Import data")
    }
    
    private func confirmClearData() {
        // Placeholder for clear data confirmation
        print("Clear data confirmation")
    }
}

#Preview {
    SettingsView()
}