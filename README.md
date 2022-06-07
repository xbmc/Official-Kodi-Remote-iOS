Official-Kodi-Remote-iOS
===============================

Full-featured remote control for Kodi Media Center.  It features library browsing, now playing informations and a direct remote control.

Features

- Control Kodi's volume
- Manage multiple Kodi instances
- Browse, search and sort your library
- Access your favorites
- Live view of currently playing playlist
- Displays music cover art where available
- Displays movie poster and actor thumbs where available
- Displays details for albums, artists, movies, TV shows and more
- Play and queue albums, songs, movies, genre selections and much more
– Switch to live TV channels and trigger or play recordings on your PVR setup
- Access and change settings of Kodi Media Center
- Browse files directly
- Clean and refresh your library
- Supports iOS Darkmode
... and much more!

## For testers

Join Testflight beta testing: https://testflight.apple.com/join/VQkpfqDN

## Building

As the app is regularly submitted to AppStore, the only guaranteed working setup is to use modern toolchain (recent Xcode and iOS SDK). Building with older Xcode version / against older iOS SDK might or might not work. You can find AppStore toolchain requirements on the [Apple Developer Portal](https://developer.apple.com/news/upcoming-requirements/).

## For maintainers (team Kodi)

Use [fastlane](https://fastlane.tools/) to manage everything related to AppStoreConnect.

### Prerequisites

1. `cd` to project's directory in terminal
2. Install or update Ruby dependencies: `bundle install` or `bundle update`
3. Grab AppStoreConnect API key (p8 file) from 1Password and place it in the project's directory

### Build and submit to Testflight

`bundle exec fastlane tf`

Optional parameters:

- `notify`: set to `0` to disable automatic notification of external testers

To be able to also create prerelease+tag on Github, define `GITHUB_API_TOKEN` environment variable. Example:

`GITHUB_API_TOKEN=your_PAT_token bundle exec fastlane tf notify:0`

### Submit for AppStore review

First, make an RC build with unfinished localizations excluded from the settings bundle: (it supports the same parameters as the normal `tf` lane described above)

    bundle exec fastlane rc

In case there're no changes compared to the last TF build, don't define `GITHUB_API_TOKEN` environment variable to prevent useless Github release being created.

Submit for review: `bundle exec fastlane asc`

If you also want to draft release on Github, define `GITHUB_API_TOKEN` environment variable like above.

Optional parameters:

- `app_version`
- `build_number`
- `manual_release`: set to `1` to use manual release mode rather than automatic
- `release_name` (you'll be asked to enter it if not provided)

Omitted `app_version` / `build_number` parameter means "use the latest uploaded". [More about passing parameters](https://docs.fastlane.tools/advanced/lanes/#passing-parameters).

Note: if new app version doesn't exist in ASC yet, you **must** pass at least `app_version`, otherwise fastlane fails. Hopefully it'll be fixed, see [issue about that](https://github.com/fastlane/fastlane/issues/18571).

Example: `bundle exec fastlane asc app_version:1.6.1`

### Fetch metadata

```sh
# optionally pass username via -u parameter
SPACESHIP_SKIP_2FA_UPGRADE=1 bundle exec fastlane deliver download_metadata --use_live_version
```
