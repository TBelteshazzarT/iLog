//
//  DataEntryView.swift
//  iLog
//
//  Created by Daniel Boyd on 9/1/25.
//


import SwiftUI

struct DataEntryView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var weight: String = ""
    @State private var selectedDate = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Log Weight")
                .font(.title)
                .padding(.top)
            
            Form {
                TextField("Weight", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                    .multilineTextAlignment(.center)
                
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .frame(width: 200)
                
                Button("Add Entry") {
                    addEntry()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .formStyle(.grouped)
            
            List {
                ForEach(dataStore.entries) { entry in
                    HStack {
                        Text(entry.date, style: .date)
                        Spacer()
                        Text("\(entry.value, specifier: "%.1f") lbs")
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .listStyle(.plain)
        }
        .padding()
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addEntry() {
        guard let weightValue = Double(weight), weightValue > 0 else {
            alertMessage = "Please enter a valid weight value"
            showAlert = true
            return
        }
        
        let newEntry = DataEntry(value: weightValue, date: selectedDate)
        dataStore.addEntry(newEntry)
        weight = ""
        selectedDate = Date()
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            dataStore.deleteEntry(dataStore.entries[index])
        }
    }
}
