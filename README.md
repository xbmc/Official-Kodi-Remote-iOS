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
3. Grab AppStoreConnect API key (p8 file) from 1Password and place it in the project's directory

### Build and submit to Testflight

`bundle exec fastlane tf`

### Submit to AppStore review

`bundle exec fastlane asc`

Optional parameters:

- `app_version`
- `build_number`

Omitted parameter means "use the latest uploaded". [More about passing parameters](https://docs.fastlane.tools/advanced/lanes/#passing-parameters).

Example: `bundle exec fastlane asc app_version:1.6.1`

### Fetch metadata

```sh
# optionally pass username via -u parameter
SPACESHIP_SKIP_2FA_UPGRADE=1 bundle exec fastlane deliver download_metadata --use_live_version
```
