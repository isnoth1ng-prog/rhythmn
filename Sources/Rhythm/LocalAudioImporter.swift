import Foundation

struct LocalAudioImportOutcome: Sendable {
    let tracks: [Track]
    let failures: [String]
}

actor LocalAudioImporter {
    func importFiles(_ urls: [URL]) async -> LocalAudioImportOutcome {
        var tracks: [Track] = []
        var failures: [String] = []

        for url in urls {
            do {
                tracks.append(try copyFile(url))
            } catch {
                failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return LocalAudioImportOutcome(tracks: tracks, failures: failures)
    }

    private func copyFile(_ sourceURL: URL) throws -> Track {
        let hasSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let importDirectory = documents.appendingPathComponent("ImportedAudio", isDirectory: true)
        try fileManager.createDirectory(at: importDirectory, withIntermediateDirectories: true)

        let fileExtension = sourceURL.pathExtension.isEmpty ? "audio" : sourceURL.pathExtension
        let destinationURL = importDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            if fileManager.fileExists(atPath: destinationURL.path) {
                do {
                    try fileManager.removeItem(at: destinationURL)
                } catch {
                    print("Rhythm could not remove an incomplete audio import: \(error.localizedDescription)")
                }
            }
            throw error
        }

        let name = sourceURL.deletingPathExtension().lastPathComponent
        return Track(
            id: "local:\(UUID().uuidString)",
            title: name.isEmpty ? sourceURL.lastPathComponent : name,
            artist: "Локальный файл",
            artistID: "local-imports",
            album: "Импортированная музыка",
            duration: 0,
            tags: ["Локально"],
            tone: .graphite,
            lyrics: [],
            localAudioURL: destinationURL,
            audioSource: .localFile
        )
    }
}
