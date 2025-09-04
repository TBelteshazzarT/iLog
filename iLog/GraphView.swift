//
//  GraphView.swift
//  iLog
//
//  Created by Daniel Boyd on 9/1/25.
//
import SwiftUI
import Charts

struct GraphView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        ScrollView { // Wrap in ScrollView for flexibility
            VStack(spacing: 20) {
                Text("Weight Progress")
                    .font(.title)
                    .padding(.top)
                
                if dataStore.entries.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Add some weight entries to see your progress")
                    )
                    .padding()
                } else {
                    // Chart Section
                    VStack(alignment: .leading) {
                        Text("Progress Chart")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(dataStore.entries) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                            
                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisGridLine()
                                AxisTick()
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, style: .date)
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 250) // Fixed height for consistency
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.05))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Statistics Section
                    VStack(alignment: .leading) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            StatView(title: "Current", value: dataStore.entries.first?.value ?? 0, unit: "lbs")
                            StatView(title: "Min", value: dataStore.entries.map { $0.value }.min() ?? 0, unit: "lbs")
                            StatView(title: "Max", value: dataStore.entries.map { $0.value }.max() ?? 0, unit: "lbs")
                            StatView(title: "Avg", value: calculateAverage(), unit: "lbs")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.05))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Additional space at bottom for better scrolling
                    Color.clear
                        .frame(height: 20)
                }
            }
            .padding(.vertical)
        }
        .frame(minWidth: 600, minHeight: 400) // Ensure minimum size
    }
    
    private func calculateAverage() -> Double {
        guard !dataStore.entries.isEmpty else { return 0 }
        let sum = dataStore.entries.reduce(0) { $0 + $1.value }
        return sum / Double(dataStore.entries.count)
    }
}

struct StatView: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f")")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
}
