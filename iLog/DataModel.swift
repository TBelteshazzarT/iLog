//
//  DataEntry.swift
//  iLogger
//
//  Created by Daniel Boyd on 9/1/25.
//


import Foundation

struct DataEntry: Identifiable, Codable {
    let id: UUID
    let value: Double
    let date: Date
    
    init(value: Double, date: Date = Date()) {
        self.id = UUID()
        self.value = value
        self.date = date
    }
}

class DataStore: ObservableObject {
    @Published var entries: [DataEntry] = []
    private let saveKey = "iLoggerData"
    
    init() {
        loadData()
    }
    
    func addEntry(_ entry: DataEntry) {
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        saveData()
    }
    
    func deleteEntry(_ entry: DataEntry) {
        entries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([DataEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
}