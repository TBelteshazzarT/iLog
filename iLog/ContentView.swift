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
    
    var body: some View {
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
        .frame(minWidth: 700, minHeight: 500) // Increased minimum size
    }
}
