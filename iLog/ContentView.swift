//
//  ContentView.swift
//  iLog
//
//  Created by Daniel Boyd on 8/31/25.
//
import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isSidebarVisible = true
    @State private var showingSettings = false
    @AppStorage("sidebarWidth") private var sidebarWidth: Double = 200
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            if isSidebarVisible {
                SidebarView(selectedTab: $selectedTab, showingSettings: $showingSettings)
                    .frame(width: sidebarWidth)
                    .transition(.move(edge: .leading))
            }
            
            // Main Content
            VStack(spacing: 0) {
                // Top toolbar with sidebar toggle
                HStack {
                    Button {
                        withAnimation {
                            isSidebarVisible.toggle()
                        }
                    } label: {
                        Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                            .font(.system(size: 16))
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .frame(height: 40)
                .background(Color(.windowBackgroundColor).opacity(0.5))
                
                // Tab content
                TabView(selection: $selectedTab) {
                    DataEntryView()
                        .tabItem {
                            Label("Log", systemImage: "plus.circle")
                        }
                        .tag(0)
                    
                    GraphView()
                        .tabItem {
                            Label("Graphs", systemImage: "chart.xyaxis.line")
                        }
                        .tag(1)
                }
                .frame(minWidth: 700, minHeight: 500)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .animation(.easeInOut(duration: 0.2), value: isSidebarVisible)
    }
}

#Preview {
    ContentView()
}
