import AppKit
import Darwin
import Dispatch
import Foundation

private let finderAutomationPermissionMessage = "Open the Automation privacy settings and allow Open in Code to control Finder, then try again."

private let finderLocationScript = """
tell application "Finder"
    if (count of selection) > 0 then
        set targetItem to item 1 of selection
    else if (count of Finder windows) > 0 then
        set targetItem to target of front Finder window
    else
        return ""
    end if

    return URL of targetItem
end tell
"""

@MainActor
private func showErrorAlert(message: String, informativeText: String) {
    _ = NSApplication.shared
    NSApp.setActivationPolicy(.accessory)
    NSApp.activate(ignoringOtherApps: true)

    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = message
    alert.informativeText = informativeText
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

@MainActor
private func pathToFrontFinderLocation() -> (path: String?, errorMessage: String?) {
    guard let script = NSAppleScript(source: finderLocationScript) else {
        return (nil, finderAutomationPermissionMessage)
    }

    var errorInfo: NSDictionary?
    let result = script.executeAndReturnError(&errorInfo)
    if errorInfo != nil {
        return (nil, finderAutomationPermissionMessage)
    }

    guard let targetURLString = result.stringValue, !targetURLString.isEmpty else {
        return (nil, "Open a Finder window for a local folder and try again.")
    }

    guard let targetURL = URL(string: targetURLString),
          let path = OICPathForFinderURL(targetURL) else {
        return (nil, "The selected Finder item does not have an accessible local path.")
    }

    return (path, nil)
}

private final class OICOpenAttempt: @unchecked Sendable {
    private let lock = NSLock()
    private var opened = false
    private var errorMessage: String?

    func complete(application: NSRunningApplication?, error: Error?) {
        lock.lock()
        opened = application != nil && error == nil
        errorMessage = error?.localizedDescription
        lock.unlock()
    }

    func result() -> (opened: Bool, errorMessage: String?) {
        lock.lock()
        defer { lock.unlock() }
        return (opened, errorMessage)
    }
}

private func openPathInPreferredVSCode(_ path: String) -> (opened: Bool, errorMessage: String?) {
    guard !path.isEmpty else {
        return (false, "No folder path was available to open.")
    }

    let folderURL = URL(fileURLWithPath: path, isDirectory: true)
    let workspace = NSWorkspace.shared

    for bundleIdentifier in OICPreferredVSCodeBundleIdentifiers() {
        guard let applicationURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            continue
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.promptsUserIfNeeded = true
        configuration.allowsRunningApplicationSubstitution = false

        let completion = DispatchSemaphore(value: 0)
        let attempt = OICOpenAttempt()

        workspace.open(
            [folderURL],
            withApplicationAt: applicationURL,
            configuration: configuration
        ) { application, error in
            attempt.complete(application: application, error: error)
            completion.signal()
        }

        completion.wait()

        let result = attempt.result()
        if result.opened {
            return (true, nil)
        }

        return (
            false,
            result.errorMessage?.isEmpty == false
                ? result.errorMessage
                : "Visual Studio Code could not open the selected folder."
        )
    }

    return (false, "Install Visual Studio Code or Visual Studio Code Insiders, then try again.")
}

@MainActor
private func run() -> Int32 {
    let finderResult = pathToFrontFinderLocation()
    guard let path = finderResult.path else {
        showErrorAlert(
            message: "Couldn’t read the Finder location",
            informativeText: finderResult.errorMessage ?? "Open a Finder window and try again."
        )
        return 1
    }

    let launchResult = openPathInPreferredVSCode(path)
    guard launchResult.opened else {
        showErrorAlert(
            message: "Couldn’t open Visual Studio Code",
            informativeText: launchResult.errorMessage ?? "The application could not be launched."
        )
        return 2
    }

    return 0
}

exit(run())
