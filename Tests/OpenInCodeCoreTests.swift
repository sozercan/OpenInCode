import Darwin
import Foundation

private func fail(_ message: String) -> Never {
    let output = "FAIL: \(message)\n"
    FileHandle.standardError.write(Data(output.utf8))
    exit(1)
}

private func assertTrue(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fail(message)
    }
}

@main
private struct OpenInCodeCoreTests {
    static func main() {
        let bundleIdentifiers = OICPreferredVSCodeBundleIdentifiers()
        assertTrue(bundleIdentifiers.count == 2, "expected two VS Code channels")
        assertTrue(bundleIdentifiers[0] == OICVSCodeBundleIdentifier, "stable VS Code must be preferred")
        assertTrue(bundleIdentifiers[1] == OICVSCodeInsidersBundleIdentifier, "Insiders must be the fallback")

        assertTrue(OICPathForFinderURL(nil) == nil, "nil URL must return nil")
        assertTrue(OICPathForFinderURL(URL(string: "https://example.com")) == nil, "non-file URL must return nil")

        let temporaryRoot = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent(UUID().uuidString)
        let folderPath = (temporaryRoot as NSString).appendingPathComponent("Project")
        let filePath = (folderPath as NSString).appendingPathComponent("README.md")
        let packagePath = (temporaryRoot as NSString).appendingPathComponent("Example.app")
        let directorySymlinkPath = (temporaryRoot as NSString).appendingPathComponent("LinkedProject")
        let folderAliasURL = URL(
            fileURLWithPath: (temporaryRoot as NSString).appendingPathComponent("Project Folder.alias")
        )
        let fileAliasURL = URL(
            fileURLWithPath: (temporaryRoot as NSString).appendingPathComponent("Project File.alias")
        )
        let deletedTargetPath = (temporaryRoot as NSString).appendingPathComponent("Deleted Target.txt")
        let brokenAliasURL = URL(
            fileURLWithPath: (temporaryRoot as NSString).appendingPathComponent("Broken Target.alias")
        )

        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                atPath: folderPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try "test".write(toFile: filePath, atomically: true, encoding: .utf8)
            try "delete me".write(toFile: deletedTargetPath, atomically: true, encoding: .utf8)
            try fileManager.createDirectory(
                atPath: packagePath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try fileManager.createSymbolicLink(
                atPath: directorySymlinkPath,
                withDestinationPath: folderPath
            )
        } catch {
            fail("create test files: \(error)")
        }

        let folderBookmark: Data
        let fileBookmark: Data
        let deletedTargetBookmark: Data
        do {
            folderBookmark = try URL(fileURLWithPath: folderPath, isDirectory: true).bookmarkData(
                options: .suitableForBookmarkFile,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            fileBookmark = try URL(fileURLWithPath: filePath).bookmarkData(
                options: .suitableForBookmarkFile,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            deletedTargetBookmark = try URL(fileURLWithPath: deletedTargetPath).bookmarkData(
                options: .suitableForBookmarkFile,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            try URL.writeBookmarkData(folderBookmark, to: folderAliasURL)
            try URL.writeBookmarkData(fileBookmark, to: fileAliasURL)
            try URL.writeBookmarkData(deletedTargetBookmark, to: brokenAliasURL)
            try fileManager.removeItem(atPath: deletedTargetPath)
        } catch {
            fail("create test aliases: \(error)")
        }

        let resolvedFolderAliasURL: URL
        let resolvedFileAliasURL: URL
        do {
            resolvedFolderAliasURL = try URL(
                resolvingAliasFileAt: folderAliasURL,
                options: .withoutUI
            )
            resolvedFileAliasURL = try URL(
                resolvingAliasFileAt: fileAliasURL,
                options: .withoutUI
            )
        } catch {
            fail("resolve test aliases: \(error)")
        }

        let resolvedFolderAliasPath = OICFileSystemPathForURL(resolvedFolderAliasURL)
        let resolvedFileAliasParentPath = (OICFileSystemPathForURL(resolvedFileAliasURL) as NSString).deletingLastPathComponent

        assertTrue(
            OICPathForFinderURL(URL(fileURLWithPath: folderPath)) == folderPath,
            "folder should open itself"
        )
        assertTrue(
            OICPathForFinderURL(URL(fileURLWithPath: filePath)) == folderPath,
            "file should open its parent"
        )
        assertTrue(
            OICPathForFinderURL(URL(fileURLWithPath: packagePath)) == temporaryRoot,
            "Finder package should open its parent"
        )
        assertTrue(
            OICPathForFinderURL(URL(fileURLWithPath: directorySymlinkPath)) == directorySymlinkPath,
            "directory symlink should open the linked directory"
        )
        assertTrue(
            OICPathForFinderURL(folderAliasURL) == resolvedFolderAliasPath,
            "folder alias should resolve to its target"
        )
        assertTrue(
            OICPathForFinderURL(fileAliasURL) == resolvedFileAliasParentPath,
            "file alias should resolve to its target parent"
        )
        assertTrue(OICPathForFinderURL(brokenAliasURL) == nil, "broken alias must return nil")
        assertTrue(
            OICPathForFinderURL(
                URL(fileURLWithPath: (temporaryRoot as NSString).appendingPathComponent("missing"))
            ) == nil,
            "missing item must return nil"
        )

        do {
            try fileManager.removeItem(atPath: temporaryRoot)
        } catch {
            fail("remove test files: \(error)")
        }

        print("OpenInCodeCoreTests: PASS")
    }
}
