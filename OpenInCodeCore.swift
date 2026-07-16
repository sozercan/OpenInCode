import Foundation

let OICVSCodeBundleIdentifier = "com.microsoft.VSCode"
let OICVSCodeInsidersBundleIdentifier = "com.microsoft.VSCodeInsiders"

func OICPreferredVSCodeBundleIdentifiers() -> [String] {
    [OICVSCodeBundleIdentifier, OICVSCodeInsidersBundleIdentifier]
}

func OICFileSystemPathForURL(_ url: URL) -> String {
    var path: String
    if #available(macOS 13.0, *) {
        path = url.path(percentEncoded: false)
    } else {
        path = url.path
    }

    while path.count > 1 && path.last == "/" {
        path.removeLast()
    }
    return path
}

func OICPathForFinderURL(_ finderURL: URL?) -> String? {
    guard var url = finderURL, url.isFileURL else {
        return nil
    }

    let resourceValues = try? url.resourceValues(forKeys: [.isAliasFileKey, .isSymbolicLinkKey])
    if resourceValues?.isAliasFile == true && resourceValues?.isSymbolicLink != true {
        guard let bookmarkData = try? URL.bookmarkData(withContentsOf: url) else {
            return nil
        }

        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        url = resolvedURL
    }

    var path = (OICFileSystemPathForURL(url) as NSString).expandingTildeInPath
    guard !path.isEmpty else {
        return nil
    }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
        return nil
    }

    let packageCheckURL = url.resolvingSymlinksInPath()
    let packageValues = try? packageCheckURL.resourceValues(forKeys: [.isPackageKey])
    let isPackage = packageValues?.isPackage == true

    if !isDirectory.boolValue || isPackage {
        path = (path as NSString).deletingLastPathComponent
    }

    return path.isEmpty ? nil : path
}
