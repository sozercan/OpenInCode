import Foundation
import XCTest
@testable import OpenInCode

final class OpenInCodeCoreTests: XCTestCase {
    func testPreferredVSCodeBundleIdentifiers() {
        let bundleIdentifiers = OICPreferredVSCodeBundleIdentifiers()

        XCTAssertEqual(bundleIdentifiers.count, 2)
        XCTAssertEqual(bundleIdentifiers[0], OICVSCodeBundleIdentifier)
        XCTAssertEqual(bundleIdentifiers[1], OICVSCodeInsidersBundleIdentifier)
    }

    func testFinderPathRejectsUnavailableURLs() {
        XCTAssertNil(OICPathForFinderURL(nil))
        XCTAssertNil(OICPathForFinderURL(URL(string: "https://example.com")))
    }

    func testFinderPathResolution() throws {
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
        defer {
            try? fileManager.removeItem(atPath: temporaryRoot)
        }

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

        let folderBookmark = try URL(fileURLWithPath: folderPath, isDirectory: true).bookmarkData(
            options: .suitableForBookmarkFile,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let fileBookmark = try URL(fileURLWithPath: filePath).bookmarkData(
            options: .suitableForBookmarkFile,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let deletedTargetBookmark = try URL(fileURLWithPath: deletedTargetPath).bookmarkData(
            options: .suitableForBookmarkFile,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        try URL.writeBookmarkData(folderBookmark, to: folderAliasURL)
        try URL.writeBookmarkData(fileBookmark, to: fileAliasURL)
        try URL.writeBookmarkData(deletedTargetBookmark, to: brokenAliasURL)
        try fileManager.removeItem(atPath: deletedTargetPath)

        let resolvedFolderAliasURL = try URL(
            resolvingAliasFileAt: folderAliasURL,
            options: .withoutUI
        )
        let resolvedFileAliasURL = try URL(
            resolvingAliasFileAt: fileAliasURL,
            options: .withoutUI
        )
        let resolvedFolderAliasPath = OICFileSystemPathForURL(resolvedFolderAliasURL)
        let resolvedFileAliasParentPath = (
            OICFileSystemPathForURL(resolvedFileAliasURL) as NSString
        ).deletingLastPathComponent

        XCTAssertEqual(OICPathForFinderURL(URL(fileURLWithPath: folderPath)), folderPath)
        XCTAssertEqual(OICPathForFinderURL(URL(fileURLWithPath: filePath)), folderPath)
        XCTAssertEqual(OICPathForFinderURL(URL(fileURLWithPath: packagePath)), temporaryRoot)
        XCTAssertEqual(
            OICPathForFinderURL(URL(fileURLWithPath: directorySymlinkPath)),
            directorySymlinkPath
        )
        XCTAssertEqual(OICPathForFinderURL(folderAliasURL), resolvedFolderAliasPath)
        XCTAssertEqual(OICPathForFinderURL(fileAliasURL), resolvedFileAliasParentPath)
        XCTAssertNil(OICPathForFinderURL(brokenAliasURL))
        XCTAssertNil(
            OICPathForFinderURL(
                URL(fileURLWithPath: (temporaryRoot as NSString).appendingPathComponent("missing"))
            )
        )
    }
}
