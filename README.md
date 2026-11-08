# RAVEN Downloader

**Professional video downloader for Ubuntu Touch** — Powered by yt-dlp with native QML interface and Python backend.

Runs on **Ubuntu Touch 20.04 and 24.04** (arm64, armhf, and amd64). OpenStore gives each device the right package.

[![OpenStore](https://open-store.io/badges/en_US.png)](https://open-store.io/app/raven.downloader.shohag)
[![Build and publish to OpenStore](https://github.com/raven-dev-s/RAVEN_Downloader/actions/workflows/openstore-monthly.yml/badge.svg)](https://github.com/raven-dev-s/RAVEN_Downloader/actions/workflows/openstore-monthly.yml) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-4.3.0-green.svg)](manifest.json.in)

---

## Features

### Core Capabilities
- **12 Platform Support** — YouTube, Vimeo, Dailymotion, Twitch, Facebook, Instagram, Twitter/X, TikTok, SoundCloud, Reddit, Bilibili with intelligent URL validation
- **Granular Format Control** — Independent video resolution and audio bitrate selection
- **Audio-Only Downloads** — Choose "Audio only" for any video, or make it the default in Settings
- **Smart Playlist Handling** — Batch downloads with per-video format customization (platform-dependent)
- **Pull-to-Refresh History** — Swipe down on download history to reload entries from storage
- **History Control** — Delete single entries, or clear everything after a confirmation
- **Library** — Every download is kept automatically; swipe up from the bottom edge to see, share, or delete files
- **Native ContentHub** — "Save as…" sends any file to Music, Videos, or another app
- **Resilient Downloads** — One progress figure for video and audio together, with automatic retries when the connection drops
- **Subtitle Engine** — Download, auto-caption, and embed subtitles in multiple languages
- **Entry-Based Storage** — Persistent history with dedicated directories and thumbnail caching
- **Adaptive Theming** — Ambiance and Suru Dark theme support

### Supported Platforms

| Platform | Video Downloads | Playlist Support |
|----------|----------------|------------------|
| **YouTube** | ✅ | ✅ Playlists |
| **Vimeo** | ✅ | ✅ Albums, Channels, Groups |
| **Dailymotion** | ✅ | ✅ Playlists |
| **Twitch** | ✅ | ✅ Collections |
| **Facebook** | ✅ | ✅ Series |
| **Instagram** | ✅ | ⚠️ Limited |
| **Twitter/X** | ✅ | ❌ |
| **TikTok** | ✅ | ✅ User Profiles |
| **SoundCloud** | ✅ | ✅ Playlists, Albums |
| **Reddit** | ✅ | ✅ Subreddit Feeds |
| **Bilibili** | ✅ | ✅ Playlists, Series |

> **Note:** Powered by yt-dlp's 1800+ extractors. The app validates URLs and provides platform-specific guidance for unsupported features.

---

## Quick Start

### Installation

```bash
# From OpenStore (Recommended)
[Get RAVEN Downloader from OpenStore](https://open-store.io/app/raven.downloader.shohag)

# Manual Build
clickable build
clickable install

# Desktop Testing
clickable desktop --no-nvidia
```

### Usage Examples

**Single Video Download**
1. Paste the link (e.g., `https://youtube.com/watch?v=VIDEO_ID`) into the bar at the top
2. Fetch → Choose video and audio quality (the best ones are preselected), or "Audio only" in the video list
3. Download → The file is kept in the Library; tap "Save as…" to send it to Music, Videos, or another app

**Playlist Download** (YouTube, Vimeo, Dailymotion, etc.)
1. Choose "Playlist" in the bar at the top
2. Paste the playlist link (e.g., `https://youtube.com/playlist?list=PLAYLIST_ID`)
3. Fetch → Watch the videos being added, and stop at any point
4. Choose formats and download each video individually

**Library** (swipe up from the bottom edge)
- Every finished download, newest first
- Tap a file to save it to another app; swipe to delete it

**Settings** (gear icon in the header)
- Enable subtitle downloads (embedded or separate)
- Toggle auto-captions
- Follow the system theme, or choose Light or Dark
- Clear download history (asks for confirmation)

**Lock Screen**
- The info circle on the lock screen shows how many videos you downloaded today

**History Management**
- Pull down on the download list to refresh from storage
- Swipe a list item to remove it from the list; its file stays in the Library
- Settings → Clear all history empties the list; the Library keeps its files

---

## Recent Updates

### Version 4.3.9 — November 2026

- **Link stays in the field** — Fetch no longer empties the link field; clear it with the cross when you're done
- **Paste after switching apps** — Paste picks up a link copied in another app while RAVEN was open

### Version 4.3.8 — November 2026

- **Lock screen count** — The lock screen's info circle shows how many videos you downloaded today, such as "5 videos downloaded today"

### Version 4.3.2 — November 2026

- **Library follows the theme** — Readable in light and dark, also right after switching
- **"Save as…" layout** — The list of apps starts below the title bar
- **Safer Library** — Deleting a file asks first
- **Release notes** — OpenStore shows what changed in each version, from `CHANGELOG.md`

### Version 4.3.1 — November 2026

- **Library** — Downloads are kept automatically and listed at the bottom edge; "Save as…" sends a file anywhere else, and Settings can ask after each download
- **Smoother downloads** — One combined progress figure for video and audio, and automatic retries that continue where the connection dropped
- **Clearer link field** — An outlined field that has focus when the app opens
- **Audio only first** — At the top of each video's quality list
- **Smaller packages** — The 20.04 runtime no longer ships the Python interpreter twice, and Python modules ship as compressed archives
- **Cleaner versions** — Releases use the plain version, such as 4.3.1; monthly builds add the date, such as 4.3.1-261201

### Version 4.3.0 — November 2026

- **Ubuntu Touch 20.04 is back** — Packages are built for both 20.04 and 24.04, each with the latest yt-dlp
- **Redesigned interface** — Link entry docked into the header across the full width, native list rows in Settings, and a real About page
- **Clearer downloads** — The best quality is preselected, each item shows its status, and finished files stay available to save later
- **Audio-only downloads** — Save just the audio of any video, per video or by default
- **More control** — Delete single entries, stop adding a playlist, and choose between a whole playlist and one of its videos
- **Settings apply immediately** — Theme and download settings no longer need an app restart
- **Bug fixes** — Auto download no longer restarts every history entry when the app opens, and saved format choices and progress survive a restart
- **Rebranded** — Developed by RAVEN Devs; support at support@raven-dev.tech

### Version 2.0.0 — December 2025

#### Major Enhancements
- **Pull-to-Refresh** — Swipe down on download history to reload entries from storage (6 grid unit threshold with debouncing)
- **Signal-Based History Clear** — One-tap history clearing with automatic UI refresh via PyOtherSide signals
- **Entry-Based Storage** — Dedicated directories per download with reliable persistence
- **Component Architecture** — 7 reusable QML components (ThumbnailImage, DownloadButton, CustomLabel, SectionLabel, etc.)
- **Code Optimization** — Reduced codebase by ~220 lines while adding features, cleaned debug logging
- **Python Type Hints** — Full type annotations for better IDE support and code clarity
- **Common Options Pattern** — Extracted duplicate yt-dlp configurations into `_get_common_ydl_opts()`

#### Bug Fixes
- **ContentHub Integration** — Resolved app restart issues during file export
- **Thumbnail Loading** — Fixed initial load bug in saved entries (Component.onCompleted)
- **Playlist Validation** — Enhanced platform-specific error messages

#### Code Quality
- **Minimal Debug Logging** — Removed verbose operational logs, kept only errors and critical state changes
- **PEP 8 Compliance** — All Python files follow style guidelines
- **Modular QML** — Extracted MainPageDialogs, MediaItem optimizations
- **Type Safety** — Type hints in url_validator, format_parser, download_manager
- **PyOtherSide Signals** — Event-driven architecture for cross-component communication

---

## Architecture

### Technology Stack
```
┌─────────────────────────────────────┐
│  QML UI (Lomiri Components 1.3)    │  ← User Interface
├─────────────────────────────────────┤
│  PyOtherSide Bridge                 │  ← QML ↔ Python IPC
├─────────────────────────────────────┤
│  Python Backend (Type-Annotated)    │
│  ├─ download_manager.py             │  ← yt-dlp orchestration, threading
│  ├─ ytdlp_bridge.py / ytdlp_worker.py │  ← yt-dlp on a bundled Python (20.04)
│  ├─ format_parser.py                │  ← Metadata extraction, formatting
│  ├─ url_validator.py                │  ← 12-platform URL validation
│  └─ storage_manager.py              │  ← Entry-based persistence, caching
├─────────────────────────────────────┤
│  yt-dlp (Embedded)                  │  ← 1800+ site extractors
│  ffmpeg (Embedded)                  │  ← Media processing
└─────────────────────────────────────┘
```

### Component Hierarchy
```
qml/
├── MainPage.qml              — Main UI, download list, pull-to-refresh
├── SettingsPage.qml          — Configuration, theme selection, history clearing
├── AboutPage.qml             — Version, support, project links
├── LibraryPage.qml           — Downloaded files, at the bottom edge
└── Components/
    ├── UrlBar.qml            — Link entry docked in the page header
    ├── DownloadItemManager.qml — History management with reload support
    ├── MediaItem.qml         — Download list item
    ├── ThumbnailImage.qml    — Smart thumbnail loader with caching
    ├── DownloadButton.qml    — Download orchestration with polling
    ├── CustomComboPopup.qml  — Format picker
    ├── MainPageDialogs.qml   — Error/warning dialog collection
    ├── EmptyState.qml        — Placeholder for empty lists
    ├── LinkRow.qml           — List row opening an external link
    ├── SectionLabel.qml      — Heading above list rows
    ├── SettingsCheckbox.qml  — Settings row with a switch
    └── ContentHubDialog.qml  — File export page
```

---

## Storage Architecture

### Directory Structure
```
~/.config/raven.downloader.shohag/
├── index.json                     # Entry summaries (fast loading)
├── settings.json                  # User preferences, theme
└── entries/                       # Per-download directories
    └── entry_<timestamp>_<rand>/
        ├── metadata.json          # Full download metadata
        └── thumbnail.jpg          # Cached thumbnail

~/.cache/raven.downloader.shohag/
└── downloads/                     # Temporary download storage
    └── [video_files]              # Exported via ContentHub
```

### Data Flow
1. **URL Submit** → Validate → Extract metadata → Cache thumbnail in entry dir
2. **Download** → Temp cache → Progress tracking → ContentHub export
3. **History Load** → Read index.json → Lazy-load full metadata on demand
4. **Pull-to-Refresh** → Flickable contentY detection → Clear model → Reload from storage
5. **History Clear** → Python clears storage → PyOtherSide signal → QML reloads UI automatically

---

## Building

### Prerequisites
- **Clickable** 8.0+ ([Installation Guide](https://clickable-ut.dev/en/latest/install.html))
- **Docker** or **LXD** (container runtime)
- **Ubuntu Touch device** or emulator (testing)

### Build Commands
```bash
# Clean build (recommended for dependency updates)
clickable clean && clickable build

# Architecture-specific build
clickable build --arch arm64    # For ARM devices
clickable build --arch amd64    # For x86_64

# Build for Ubuntu Touch 20.04 (the default is 24.04)
CLICKABLE_FRAMEWORK=ubuntu-sdk-20.04 clickable build --arch arm64

# Desktop testing (requires yt-dlp installed locally)
clickable desktop --no-nvidia

# View build logs
clickable logs

# Install on connected device
clickable install
```

### Embedded Dependencies
Dependencies are bundled by `scripts/embed-dependencies.sh` during the build:
- **ffmpeg** → `lib/<target-triplet>/bin/ffmpeg` (binary for media processing)
- **yt-dlp** → the latest release, in a location that depends on the target's system Python:

| Target | System Python | yt-dlp location | How it runs |
|--------|---------------|-----------------|-------------|
| Ubuntu Touch 24.04 | 3.12 | `lib/python3/yt_dlp.zip` | Inside the app, through PyOtherSide |
| Ubuntu Touch 20.04 | 3.8 | `lib/<target-triplet>/ytdlp-runtime/` | On a bundled Python, as a child process (`src/ytdlp_bridge.py`) |

Python modules ship as zip archives of bytecode (`scripts/pack-python.py`): yt-dlp is about 1,800 small modules, which take a fraction of the space this way, and Python imports them directly.

yt-dlp requires Python 3.11 or newer, and its last release for Python 3.8 dates from October 2024. PyOtherSide ties the app itself to the system Python, so 20.04 packages bundle a standalone Python for yt-dlp, trimmed to what yt-dlp needs. Any target whose system Python falls behind yt-dlp's requirement switches to this approach automatically.

### Automated OpenStore Releases

GitHub Actions builds arm64, amd64, and armhf packages for both Ubuntu Touch
20.04 and 24.04, and publishes them to OpenStore on the first day of every month
at 04:23 UTC. The build installs the latest stable `yt-dlp` release at build time.

Pushes to `main` build every package as a check, and publish when
`PROJECT_VERSION` in `CMakeLists.txt` is newer than the version on OpenStore.
Changes to Markdown files or the license alone do not run the workflow.

| Build | Ubuntu Touch 24.04 | Ubuntu Touch 20.04 |
|-------|--------------------|--------------------|
| Push to `main` or tag `v4.3.1` | `4.3.1` | `4.3.1~focal` |
| Monthly or manual run | `4.3.1-261201` | `4.3.1~focal-261201` |

Monthly builds add the build date (`YYMMDD`). OpenStore compares versions the
way Debian does, so `4.3.1` < `4.3.1-261201` < `4.3.2`, and it rejects one
version number for two frameworks, hence `~focal` on 20.04 packages. Raise
`PROJECT_VERSION` for every release with code changes.

Release notes on OpenStore come from `CHANGELOG.md`: add a `## <version>`
section for the new `PROJECT_VERSION` before pushing. Monthly builds publish a
short note about the yt-dlp update instead.

Before enabling the workflow, add the OpenStore API key as the
`OPENSTORE_API_KEY` GitHub Actions secret (repository-level or in the
`openstore` environment). The key is available from the OpenStore account
settings. A release tag beginning with `v` also publishes all architectures.
You can run the workflow manually from the Actions tab; manual runs build only
unless **Publish the built packages to OpenStore** is selected.

---

## URL Format Examples

| Platform | Single Video | Playlist |
|----------|-------------|----------|
| **YouTube** | `youtube.com/watch?v=VIDEO_ID` | `youtube.com/playlist?list=PLAYLIST_ID` |
| **Vimeo** | `vimeo.com/VIDEO_ID` | `vimeo.com/album/ALBUM_ID` |
| **Dailymotion** | `dailymotion.com/video/VIDEO_ID` | `dailymotion.com/playlist/PLAYLIST_ID` |
| **Twitch** | `twitch.tv/videos/VIDEO_ID` | `twitch.tv/collections/COLLECTION_ID` |
| **Facebook** | `facebook.com/watch/?v=VIDEO_ID` | `facebook.com/watch/[series]` |
| **Instagram** | `instagram.com/p/POST_ID/` | `instagram.com/explore/tags/TAG/` (limited) |
| **Twitter/X** | `twitter.com/user/status/TWEET_ID` | ❌ Not supported |
| **TikTok** | `tiktok.com/@user/video/VIDEO_ID` | `tiktok.com/@username` (user profile) |
| **SoundCloud** | `soundcloud.com/artist/track` | `soundcloud.com/artist/sets/PLAYLIST` |
| **Reddit** | `reddit.com/r/sub/comments/POST_ID/` | `reddit.com/r/subreddit/top` |
| **Bilibili** | `bilibili.com/video/BV_ID` | `bilibili.com/medialist/PLAYLIST_ID` |

> **Auto-Detection:** The app validates URLs and shows platform-specific error messages for unsupported features.

---

## Development

### Project Structure
```
raven.downloader/
├── qml/                    # QML UI files
│   ├── MainPage.qml
│   ├── SettingsPage.qml
│   ├── AboutPage.qml
│   └── Components/        # Reusable components
├── src/                    # Python backend
│   ├── __init__.py
│   ├── download_manager.py
│   ├── ytdlp_bridge.py
│   ├── ytdlp_worker.py
│   ├── format_parser.py
│   ├── url_validator.py
│   └── storage_manager.py
├── assets/                 # Images, icons
├── lib/                    # Embedded Python packages
│   └── python3/dist-packages/yt_dlp/
├── lib/<target-triplet>/bin/ # Embedded target binaries
│   └── ffmpeg
├── clickable.yaml          # Build configuration
├── manifest.json.in        # App metadata
└── README.md
```

### Adding Features
1. **Python Module** — Add to `src/`, import in `download_manager.py`
2. **QML Component** — Create in `qml/Components/`, import in parent files
3. **Platform Support** — Add pattern to `PLATFORM_PATTERNS` in `url_validator.py`

### Code Standards
- **Python**: PEP 8, type hints, docstrings
- **QML**: Lomiri Components 1.3, component-based design
- **Commits**: Atomic, descriptive messages

### Testing
```bash
# Python syntax check
python3 -m py_compile src/*.py

# QML validation (via clickable build)
clickable build

# Desktop run with full logs
clickable desktop --no-nvidia 2>&1 | tee app.log
```

---

## Troubleshooting

### Build Issues
| Error | Solution |
|-------|----------|
| **yt-dlp not found** | `clickable clean && clickable build` |
| **Module import error** | Verify `lib/python3/yt_dlp.zip` (24.04) or `lib/<target-triplet>/ytdlp-runtime/site-packages/yt_dlp.zip` (20.04) exists |
| **ffmpeg missing** | Check `lib/aarch64-linux-gnu/bin/ffmpeg` (or the matching target triplet) exists |
| **CMake warnings** | Safe to ignore deprecation warnings (compatibility) |

### Runtime Issues
| Problem | Diagnosis | Fix |
|---------|-----------|-----|
| **Progress stuck** | `clickable logs \| grep download` | Check network, try different format |
| **Playlist invalid** | Check [URL examples](#url-format-examples) | Ensure URL matches platform's playlist pattern |
| **Platform not supported** | Review [Supported Platforms](#supported-platforms) | Submit feature request with example URLs |
| **Thumbnails not loading** | Check `~/.config/raven.downloader.shohag/entries/` | Clear cache, re-download |
| **ContentHub fails** | Check AppArmor policy | Verify `content_exchange` permission |

### Debug Mode
Enable verbose logging:
```bash
# Terminal logs
clickable logs --follow

# Python debug output
# Edit src/download_manager.py, set ydl_opts['quiet'] = False
```

---

## Security

### AppArmor Policy
The app requires the following permissions (see `raven.downloader.apparmor`):
- **networking** — Download videos from internet
- **audio** — Audio playback (if implemented)
- **video** — Video preview (if implemented)
- **content_exchange** — Import URLs from other apps
- **content_exchange_source** — Export downloaded files to other apps

### Privacy
- **No tracking** — No analytics, telemetry, or user data collection
- **Local storage** — All data stored in user's config directory
- **No external APIs** — Direct connection to video platforms via yt-dlp

---

## Contributing

We welcome contributions! Follow these steps:

### Workflow
1. **Fork** the repository
2. **Create** feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** changes (`git commit -m 'Add amazing feature'`)
4. **Test** on Ubuntu Touch device/emulator
5. **Push** to branch (`git push origin feature/amazing-feature`)
6. **Submit** pull request

### Standards
- **Python**: PEP 8 style, type hints, docstrings
- **QML**: Lomiri Components 1.3, component-based design, clear property names
- **Commits**: Atomic, descriptive messages (e.g., "Fix thumbnail loading in saved entries")
- **Testing**: Verify on real device before submitting

### Areas for Contribution
- [ ] Add more platform support (e.g., Rumble, Odysee)
- [ ] Implement download queue with priority
- [ ] Add video preview in-app
- [ ] Improve error messages with recovery suggestions
- [ ] Add download scheduling
- [ ] Optimize thumbnail caching strategy

---

## License

**GNU General Public License v3.0**

Copyright (C) 2025 RAVEN Devs

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public License](LICENSE) for more details.

---

## Links & Resources

### Project
- **Repository**: [github.com/raven-dev-s/RAVEN_Downloader](https://github.com/raven-dev-s/RAVEN_Downloader)
- **OpenStore**: [open-store.io/app/raven.downloader.shohag](https://open-store.io/app/raven.downloader.shohag)
- **Issues**: [github.com/raven-dev-s/RAVEN_Downloader/issues](https://github.com/raven-dev-s/RAVEN_Downloader/issues)

### Contact
- **Developer**: RAVEN Devs
- **Email**: [support@raven-dev.tech](mailto:support@raven-dev.tech)
- **Platform**: Ubuntu Touch (Lomiri)

### Technologies
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — Video extraction engine (1800+ sites)
- [PyOtherSide](https://github.com/thp/pyotherside) — QML ↔ Python bridge
- [Ubuntu Touch](https://ubuntu-touch.io/) — Mobile Linux platform
- [Lomiri UI Toolkit](https://gitlab.com/ubports/development/core/lomiri-ui-toolkit) — QML components
- [Clickable](https://clickable-ut.dev/) — Ubuntu Touch build tool

---

<div align="center">

**⭐ Star this project if you find it useful!**

*Built with ❤️ for the Ubuntu Touch community*

</div>

---

*Powered by [yt-dlp](https://github.com/yt-dlp/yt-dlp) • [PyOtherSide](https://github.com/thp/pyotherside) • [Ubuntu Touch](https://ubuntu-touch.io/)*
