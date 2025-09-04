//
//  UpdateManager.swift
//  iLog
//
//  Created by Daniel Boyd on 9/3/25.
//


// UpdateManager.swift
import SwiftUI
import Foundation

class UpdateManager: ObservableObject {
    @Published var showUpdateAlert = false
    @Published var updateAvailable = false
    @Published var latestVersion: String = ""
    @Published var updateURL: URL?
    @Published var releaseNotes: String = ""
    
    private let currentVersion: String
    private let repoOwner: String
    private let repoName: String
    
    init(repoOwner: String, repoName: String) {
        self.repoOwner = repoOwner
        self.repoName = repoName
        self.currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    func checkForUpdates() {
        let apiURL = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        
        URLSession.shared.dataTask(with: apiURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error checking for updates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                
                if self.isNewerVersion(latestVersion: latestVersion) {
                    DispatchQueue.main.async {
                        self.latestVersion = latestVersion
                        self.updateURL = URL(string: release.assets.first?.browserDownloadURL ?? "")
                        self.releaseNotes = release.body
                        self.updateAvailable = true
                        self.showUpdateAlert = true
                    }
                }
            } catch {
                print("Error parsing release data: \(error)")
            }
        }.resume()
    }
    
    private func isNewerVersion(latestVersion: String) -> Bool {
        let currentComponents = currentVersion.split(separator: ".").map { String($0) }
        let latestComponents = latestVersion.split(separator: ".").map { String($0) }
        
        for i in 0..<max(currentComponents.count, latestComponents.count) {
            let current = i < currentComponents.count ? Int(currentComponents[i]) ?? 0 : 0
            let latest = i < latestComponents.count ? Int(latestComponents[i]) ?? 0 : 0
            
            if latest > current {
                return true
            } else if latest < current {
                return false
            }
        }
        return false
    }
    
    func downloadAndInstallUpdate(completion: @escaping (Bool, Error?) -> Void) {
        guard let downloadURL = updateURL else {
            completion(false, NSError(domain: "UpdateManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No download URL available"]))
            return
        }
        
        // Download the new version
        downloadFile(from: downloadURL) { tempURL, error in
            guard let tempURL = tempURL, error == nil else {
                completion(false, error)
                return
            }
            
            // Install the update
            self.installUpdate(from: tempURL, completion: completion)
        }
    }
    
    private func downloadFile(from url: URL, completion: @escaping (URL?, Error?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil, error)
                return
            }
            
            // Move to a permanent location in temp directory
            let tempDir = FileManager.default.temporaryDirectory
            let destinationURL = tempDir.appendingPathComponent(url.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    private func installUpdate(from downloadedURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        do {
            // Get current app location
            let currentAppURL = Bundle.main.bundleURL
            let appName = currentAppURL.lastPathComponent
            let applicationsDir = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first!
            let targetURL = applicationsDir.appendingPathComponent(appName)
            
            // Quit the current application
            NSApp.terminate(nil)
            
            // Wait a moment for the app to quit, then install
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                do {
                    // Remove old version if it exists
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    
                    // Copy new version
                    try FileManager.default.copyItem(at: downloadedURL, to: targetURL)
                    
                    // Launch new version
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = [targetURL.path]
                    try process.run()
                    
                    completion(true, nil)
                } catch {
                    completion(false, error)
                }
            }
        } catch {
            completion(false, error)
        }
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String
    let assets: [Asset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name, body, assets
    }
}

struct Asset: Codable {
    let browserDownloadURL: String
    
    enum CodingKeys: String, CodingKey {
        case browserDownloadURL = "browser_download_url"
    }
}