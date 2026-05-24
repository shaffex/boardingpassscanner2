//
//  DataUpdater.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 20/05/2026.
//

import Foundation
import MagicUiFramework

struct SxUrlCache {
    static private let DIR_MAGICUI = "MagicUI"
    static private let DIR_CACHES = "UrlCaches"
    static private var directoryRoot: URL {
#if os(macOS)
        SxFile.applicationSupportDirectoryPath.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(DIR_MAGICUI)
#else
        SxFile.applicationSupportDirectoryPath.appendingPathComponent(DIR_MAGICUI)
//    SxFile.documentsDirectory
#endif
    }
    
    static func fileNameCache(safeFileName: String) -> URL {
        directoryRoot.appendingPathComponent(DIR_CACHES).appendingPathComponent(safeFileName)
    }
    
    static func getCahedUrlFilename(urlString: String) -> URL {
        let safeFilename = urlString.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        return fileNameCache(safeFileName: safeFilename)
    }
    
    static func isUrlInCache(urlString: String) -> Bool {
        if SxFile.fileExists(fileURL: getCahedUrlFilename(urlString: urlString)) {
            return true
        }
        return false
    }
}

struct VersionResponse: Decodable {
    let version: Int
}

struct DataUpdater {
    private let dataBaseURL = URL(string: "https://shaffex.com/api/boardingpass2/Data/")!
    private let localVersionKey = "jsonVersion"
    private let dataFileNames = ["airports.csv", "airlines.csv"]

    @discardableResult
    func checkForDataUpdate() async throws -> Bool {
        debugLog("Checking for data updates")
        let remote = try await remoteVersion()
        SxMagicVariables.shared.setValue(remote.version, forKey: "dataFilesVersion")
        debugLog("Stored dataFilesVersion MagicUI variable: \(remote.version)")

        let localVersion = UserDefaults.standard.integer(forKey: localVersionKey)
        debugLog("Local version: \(localVersion), remote version: \(remote.version)")

        guard remote.version != localVersion else {
            debugLog("Versions match. No data update needed")
            return false
        }

        debugLog("Version changed. Downloading data files: \(dataFileNames.joined(separator: ", "))")
        let downloaded = try await downloadDataFiles()
        if downloaded {
            UserDefaults.standard.set(remote.version, forKey: localVersionKey)
            debugLog("Updated local version to \(remote.version)")
            
            PluginActions.shared.runAction("loadDataModel:dataModelName:dataModelAirlines;type:csv;src:urlCache:https://shaffex.com/api/boardingpass2/Data/airlines.csv")
            PluginActions.shared.runAction("loadDataModel:dataModelName:dataModelAirports;type:csv;src:urlCache:https://shaffex.com/api/boardingpass2/Data/airports.csv")
        }

        debugLog("Data update finished. Downloaded: \(downloaded)")
        return downloaded
    }

    func downloadDataFiles() async throws -> Bool {
        for fileName in dataFileNames {
            let sourceURL = dataBaseURL.appendingPathComponent(fileName)
            let destinationURL = try cachedDataFileURL(fileName: fileName)
            debugLog("Downloading \(sourceURL.absoluteString)")
            try await downloadFile(from: sourceURL, to: destinationURL)
            debugLog("Downloaded \(fileName) to \(destinationURL.path)")
        }

        debugLog("All data files downloaded. Deleting MagicUI URL cache files")
        try deleteUrlCacheFiles()
        return true
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
            debugLog("Removing existing file at \(destinationURL.path)")
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }

    private func cachedDataFileURL(fileName: String) throws -> URL {
        let cacheDirectory = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dataDirectory = cacheDirectory.appendingPathComponent("Data", isDirectory: true)

        try FileManager.default.createDirectory(
            at: dataDirectory,
            withIntermediateDirectories: true
        )

        return dataDirectory.appendingPathComponent(fileName)
    }

    private func deleteUrlCacheFiles() throws {
        let fileManager = FileManager.default

        for fileName in dataFileNames {
            let sourceURL = dataBaseURL.appendingPathComponent(fileName)
            let cacheURL = SxUrlCache.getCahedUrlFilename(urlString: sourceURL.absoluteString)

            if fileManager.fileExists(atPath: cacheURL.path) {
                debugLog("Deleting URL cache for \(sourceURL.absoluteString): \(cacheURL.path)")
                try fileManager.removeItem(at: cacheURL)
            } else {
                debugLog("No URL cache file found for \(sourceURL.absoluteString): \(cacheURL.path)")
            }
        }
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

struct Action_checkForDataUpdate: SxActionProtocol {
    let node: MagicUiFramework.MagicNode?
    
    func execute(_ actionString: String) {
        Task {
            try? await DataUpdater().checkForDataUpdate()
        }
    }
}
