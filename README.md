Official-Kodi-Remote-iOS
===============================

Full-featured remote control for Kodi Media Center.  It features library browsing, now playing informations and a direct remote control.

Features

- Control Kodi's volume
- Manage multiple Kodi instances
- Live view of currently playing playlist
- Displays music cover art shown where available
- Displays movie poster and actor thumbs where available
- Play and queue albums, songs, genre selections and much more directly without having to turn on your TV.
- Browse files directly
... and much more!

## For testers

Join Testflight beta testing: https://testflight.apple.com/join/VQkpfqDN

## For maintainers (team Kodi)

Use [fastlane](https://fastlane.tools/) to manage everything related to AppStoreConnect.

### Prerequisites

1. `cd` to project's directory in terminal
2. Install or update Ruby dependencies: `bundle install` or `bundle update`

### Build and submit to Testflight

1. Grab p8 file (AppStoreConnect API key) from 1Password and place it in the project's directory
2. Run fastlane: `bundle exec fastlane tf`

### Fetch metadata

```sh
# optionally pass username via -u parameter
SPACESHIP_SKIP_2FA_UPGRADE=1 bundle exec fastlane deliver download_metadata --use_live_version
```
