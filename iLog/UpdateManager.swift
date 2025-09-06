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
    private let appName: String
    private let githubToken: String?
    
    init(repoOwner: String, repoName: String, appName: String? = nil, githubToken: String? = nil) {
        self.repoOwner = repoOwner
        self.repoName = repoName
        self.githubToken = githubToken
        
        // Determine app name - use provided name or extract from bundle
        if let appName = appName {
            self.appName = appName
        } else if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            self.appName = bundleName
        } else {
            self.appName = "App"
        }
        
        // Try to get the build version first, fall back to marketing version
        if let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            self.currentVersion = buildVersion
        } else if let marketingVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            self.currentVersion = marketingVersion
        } else {
            self.currentVersion = "1.0.0"
        }
        
        print("Initialized UpdateManager for \(self.appName) with version: \(currentVersion)")
    }
    
    func checkForUpdates() {
        print("=== Update Check Started ===")
        print("Current app version from Info.plist: \(currentVersion)")
        
        let apiURL = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        
        print("API URL: \(apiURL.absoluteString)")
        
        var request = URLRequest(url: apiURL)
        if let token = githubToken {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
    
    func downloadAndInstallUpdate(completion: @escaping (Bool, Error?) -> Void) {
        guard let downloadURL = updateURL else {
            completion(false, NSError(domain: "UpdateManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No download URL available"]))
            return
        }
        
        print("Starting download and installation...")
        
        downloadFile(from: downloadURL) { [weak self] fileURL, error in
            guard let self = self else { return }
            
            if let fileURL = fileURL {
                print("Download completed successfully: \(fileURL.path)")
                self.installUpdate(from: fileURL, completion: completion)
            } else {
                print("Download failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false, error)
            }
        }
    }
    
    private func isNewerVersion(latestVersion: String) -> Bool {
        let current = currentVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        let latest = latestVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Comparing versions - Current: '\(current)', Latest: '\(latest)'")
        
        // Remove any leading "v" from both versions
        let cleanCurrent = current.replacingOccurrences(of: "^v", with: "", options: .regularExpression)
        let cleanLatest = latest.replacingOccurrences(of: "^v", with: "", options: .regularExpression)
        
        let currentComponents = cleanCurrent.split(separator: ".").map { String($0) }
        let latestComponents = cleanLatest.split(separator: ".").map { String($0) }
        
        // Compare each version component
        for i in 0..<max(currentComponents.count, latestComponents.count) {
            let currentPart = i < currentComponents.count ? Int(currentComponents[i]) ?? 0 : 0
            let latestPart = i < latestComponents.count ? Int(latestComponents[i]) ?? 0 : 0
            
            if latestPart > currentPart {
                print("New version available! Latest is newer at part \(i)")
                return true
            } else if latestPart < currentPart {
                print("Current version is newer at part \(i)")
                return false
            }
            // If equal, continue to next part
        }
        
        print("Versions are identical")
        return false
    }
    
    private func downloadFile(from url: URL, completion: @escaping (URL?, Error?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil, error)
                return
            }
            
            let fileName = "\(self.appName)_update_\(Int(Date().timeIntervalSince1970)).zip"
            let persistentURL = URL(fileURLWithPath: "/private/tmp/\(fileName)")
            
            do {
                if FileManager.default.fileExists(atPath: persistentURL.path) {
                    try FileManager.default.removeItem(at: persistentURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: persistentURL)
                try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: persistentURL.path)
                
                print("File saved to: \(persistentURL.path)")
                completion(persistentURL, nil)
            } catch {
                print("Error moving file: \(error)")
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    private func installUpdate(from downloadedURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        print("=== Starting Update Installation ===")
        print("Downloaded file path: \(downloadedURL.path)")
        print("File exists: \(FileManager.default.fileExists(atPath: downloadedURL.path))")
        
        let currentAppURL = Bundle.main.bundleURL
        let appFileName = currentAppURL.lastPathComponent
        
        
        let scriptContent = """
        #!/bin/bash
        set -e
        
        APP_NAME="\(self.appName)"
        LOG_FILE="/private/tmp/\(self.appName)_update_detailed.log"
        exec > >(tee -a "$LOG_FILE") 2>&1
        
        echo "=========================================="
        echo "$APP_NAME UPDATE SCRIPT STARTED: $(date)"
        echo "=========================================="
        
        # Use the direct path provided by the app
        ZIP_FILE="\(downloadedURL.path)"
        TARGET_APP="/Applications/\(appFileName)"
        EXTRACT_DIR="/private/tmp/\(self.appName)_extract_$$"
        
        echo "ZIP file path: $ZIP_FILE"
        echo "Target app: $TARGET_APP"
        echo "Extract dir: $EXTRACT_DIR"
        
        # Verify the ZIP file exists
        if [ ! -f "$ZIP_FILE" ]; then
            echo "❌ ZIP file does not exist at: $ZIP_FILE"
            echo "Trying alternative locations..."
            
            # Check if file exists with /private prefix
            PRIVATE_PATH="/private\(downloadedURL.path)"
            if [ -f "$PRIVATE_PATH" ]; then
                ZIP_FILE="$PRIVATE_PATH"
                echo "✓ Found at private path: $ZIP_FILE"
            else
                echo "❌ File not found anywhere"
                echo "Files in /tmp/:"
                ls -la /tmp/ | grep -i "$APP_NAME"
                echo "Files in /private/tmp/:"
                ls -la /private/tmp/ | grep -i "$APP_NAME"
                exit 1
            fi
        fi
        
        echo "✓ ZIP file verified: $ZIP_FILE"
        echo "File size: $(wc -c < "$ZIP_FILE") bytes"
        echo "File type: $(file "$ZIP_FILE")"
        
        # Create extract directory
        echo "Creating extract directory: $EXTRACT_DIR"
        mkdir -p "$EXTRACT_DIR" || {
            echo "❌ Failed to create extract directory"
            exit 1
        }
        
        # First try using ditto (most reliable on macOS)
        echo "Extracting with ditto..."
        ditto -x -k "$ZIP_FILE" "$EXTRACT_DIR" 2>&1
        
        if [ $? -ne 0 ]; then
            echo "❌ ditto extraction failed, trying unzip..."
            unzip -o "$ZIP_FILE" -d "$EXTRACT_DIR" 2>&1
            
            if [ $? -ne 0 ]; then
                echo "❌ Both ditto and unzip failed!"
                echo "Trying with absolute path..."
                /usr/bin/unzip -o "$ZIP_FILE" -d "$EXTRACT_DIR" 2>&1
                
                if [ $? -ne 0 ]; then
                    echo "❌ All extraction methods failed!"
                    exit 1
                fi
            fi
        fi
        
        echo "✓ Extraction successful"
        echo "Extracted contents:"
        ls -la "$EXTRACT_DIR"
        
        # Find the .app file
        APP_PATH=$(find "$EXTRACT_DIR" -name "*.app" -type d | head -n 1)
        
        if [ -z "$APP_PATH" ]; then
            echo "❌ No .app file found in extracted contents!"
            echo "All extracted files:"
            find "$EXTRACT_DIR" -type f -o -type d
            exit 1
        fi
        
        echo "✓ Found app: $APP_PATH"
        
        # Verify app structure
        if [ ! -d "$APP_PATH/Contents/MacOS" ]; then
            echo "❌ App missing Contents/MacOS directory!"
            echo "App structure:"
            ls -la "$APP_PATH"
            exit 1
        fi
        
        # Remove old version (quit the app first if running)
        echo "Quitting current $APP_NAME instance..."
        pkill -x "$APP_NAME" || true
        sleep 1
        
        echo "Removing old version..."
        if [ -d "$TARGET_APP" ]; then
            rm -rf "$TARGET_APP" || {
                echo "❌ Failed to remove old version"
                exit 1
            }
        fi
        
        # Copy new version
        echo "Copying new version..."
        cp -R "$APP_PATH" "$TARGET_APP" || {
            echo "❌ Copy failed!"
            exit 1
        }
        
        # Fix permissions
        echo "Fixing permissions..."
        chmod -R 755 "$TARGET_APP" || {
            echo "⚠️  Failed to fix permissions, but continuing..."
        }
        
        # Remove quarantine attribute
        echo "Removing quarantine attributes..."
        xattr -rc "$TARGET_APP" 2>/dev/null || true
        
        # Code signing (optional)
        echo "Code signing..."
        codesign --force --deep --sign - "$TARGET_APP" 2>/dev/null || {
            echo "⚠️  Code signing failed (may be normal without developer cert)"
        }
        
        # Verify installation
        if [ -d "$TARGET_APP" ] && [ -d "$TARGET_APP/Contents/MacOS" ]; then
            echo "✓ Installation successful!"
        else
            echo "❌ Installation verification failed!"
            exit 1
        fi
        
        # Cleanup
        echo "Cleaning up..."
        rm -rf "$EXTRACT_DIR"
        rm -f "$ZIP_FILE"
        
        # Launch new version
        echo "Launching new $APP_NAME..."
        sleep 2
        open "$TARGET_APP" --args "--updated" || {
            echo "⚠️  Open command failed, but installation completed"
        }
        
        echo "=========================================="
        echo "$APP_NAME UPDATE COMPLETED SUCCESSFULLY: $(date)"
        echo "=========================================="
        
        # Self-cleanup
        rm -f "$0"
        
        exit 0
        """
        
        do {
            let scriptURL = URL(fileURLWithPath: "/tmp/update_\(self.appName)_\(UUID().uuidString).sh")
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
            
            print("Created update script at: \(scriptURL.path)")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptURL.path]
            try process.run()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
            
            completion(true, nil)
            
        } catch {
            print("Error: \(error)")
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
