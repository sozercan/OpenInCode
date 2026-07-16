# OpenInCode

Open the folder you are viewing in Finder—or the folder containing a selected item—in Visual Studio Code with one toolbar click.

## Requirements

- macOS 12 or newer
- Visual Studio Code or Visual Studio Code Insiders

## Install

Install the latest release with Homebrew:

```sh
brew install --cask sozercan/repo/open-in-code
```

You can also download the app from [GitHub Releases](https://github.com/sozercan/OpenInCode/releases). If you download it directly, move **Open in Code.app** to `/Applications`.

## Add Open in Code to Finder

1. Open `/Applications` in Finder.
2. Hold Command and drag **Open in Code** to the Finder toolbar.
3. Release it where you want the toolbar button to appear.

To remove or reposition the button later, hold Command while dragging it.

## Use

Open a Finder window, optionally select an item, and click **Open in Code** in the toolbar.

- A selected folder opens directly.
- A selected file or Finder package opens its containing folder.
- If multiple items are selected, the first item is used.
- If nothing is selected, the folder shown in the front Finder window opens.
- Visual Studio Code is preferred; Visual Studio Code Insiders is used when the stable app is not installed.

## Allow Finder access

On first use, macOS asks whether **Open in Code** may control Finder. Allow access so the app can read the current Finder selection.

If access was previously denied, enable **Open in Code → Finder** here:

- macOS 13 or newer: **System Settings → Privacy & Security → Automation**
- macOS 12: **System Preferences → Security & Privacy → Privacy → Automation**

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for source builds, tests, packaging, and release instructions.
