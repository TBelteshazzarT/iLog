//
//  SidebarView.swift
//  iLog
//
//  Created by Daniel Boyd on 8/31/25.
//
import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Int
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Info Section
            VStack(alignment: .leading, spacing: 8) {
                Text("iLog")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
            }
            .padding(.horizontal)
            
            // Navigation Section
            VStack(alignment: .leading, spacing: 12) {
                SidebarButton(
                    title: "Data Entry",
                    icon: "plus.circle",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                SidebarButton(
                    title: "Graphs",
                    icon: "chart.xyaxis.line",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                Divider()
                
                SidebarButton(
                    title: "Settings",
                    icon: "gear",
                    isSelected: false
                ) {
                    showingSettings = true
                }
                
                SidebarButton(
                    title: "Help",
                    icon: "questionmark.circle",
                    isSelected: false
                ) {
                    // Placeholder for help functionality
                    print("Help tapped")
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Footer
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                Text("© 2025 iLog App")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .padding(.top, 20)
        .background(Color(.windowBackgroundColor))
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SidebarView(selectedTab: .constant(0), showingSettings: .constant(false))
}
