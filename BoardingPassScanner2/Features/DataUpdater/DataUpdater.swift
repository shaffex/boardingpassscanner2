//
//  DataUpdater.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 20/05/2026.
//

import Foundation

struct VersionResponse: Decodable {
    let version: Int
}

struct DataUpdater {
    private let dataBaseURL = URL(string: "https://shaffex.com/api/boardingpass2/Data/")!
    private let localVersionKey = "jsonVersion"
    private let remoteVersionKey = "dataFilesVersion"
    private let dataFileNames = ["airports.csv", "airlines.csv"]

    @discardableResult
    func checkForDataUpdate() async throws -> Bool {
        debugLog("Checking for data updates")
        let remote = try await remoteVersion()
        UserDefaults.standard.set(remote.version, forKey: remoteVersionKey)
        debugLog("Stored remote dataFilesVersion: \(remote.version)")

        let localVersion = UserDefaults.standard.integer(forKey: localVersionKey)
        debugLog("Local version: \(localVersion), remote version: \(remote.version)")

        guard remote.version != localVersion else {
            debugLog("Versions match. No data update needed")
            return false
        }

        debugLog("Version changed. Downloading data files: \(dataFileNames.joined(separator: ", "))")
        try await downloadDataFiles()
        UserDefaults.standard.set(remote.version, forKey: localVersionKey)
        debugLog("Updated local version to \(remote.version)")

        await MainActor.run {
            BoardingPassMapper.reload()
        }

        debugLog("Data update finished")
        return true
    }

    private func downloadDataFiles() async throws {
        for fileName in dataFileNames {
            let sourceURL = dataBaseURL.appendingPathComponent(fileName)
            let destinationURL = try storedDataFileURL(fileName: fileName)
            debugLog("Downloading \(sourceURL.absoluteString)")
            try await downloadFile(from: sourceURL, to: destinationURL)
            debugLog("Downloaded \(fileName) to \(destinationURL.path)")
        }
    }

    private func remoteVersion() async throws -> VersionResponse {
        let versionURL = dataBaseURL.appendingPathComponent("version.php")
        debugLog("Fetching remote version from \(versionURL.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: versionURL)

        guard isSuccessfulHTTPResponse(response) else {
            debugLog("Remote version request failed with response: \(String(describing: response))")
            throw URLError(.badServerResponse)
        }

        let version = try JSONDecoder().decode(VersionResponse.self, from: data)
        debugLog("Fetched remote version: \(version.version)")
        return version
    }

    private func downloadFile(from sourceURL: URL, to destinationURL: URL) async throws {
        let (temporaryURL, response) = try await URLSession.shared.download(from: sourceURL)

        guard isSuccessfulHTTPResponse(response) else {
            debugLog("Download failed for \(sourceURL.absoluteString) with response: \(String(describing: response))")
            throw URLError(.badServerResponse)
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }

    private func storedDataFileURL(fileName: String) throws -> URL {
        try BoardingPassMapper.dataDirectory().appendingPathComponent(fileName)
    }

    private func debugLog(_ message: String) {
        print("[DataUpdater] \(message)")
    }

    private func isSuccessfulHTTPResponse(_ response: URLResponse) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        return (200..<300).contains(httpResponse.statusCode)
    }
}
