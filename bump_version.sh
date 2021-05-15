#!/usr/bin/env bash

newVersion="$1"
if [[ -z $newVersion ]]; then
  echo 'new version must be passed as argument'
  exit 1
fi

projectFile='Kodi Remote.xcodeproj/project.pbxproj'
newBranch="bump-$newVersion"

git checkout -b "$newBranch"
sed -E -i '' -e "s/MARKETING_VERSION = .+/MARKETING_VERSION = $newVersion;/" "$projectFile"
git commit -m "bump version to $newVersion" "$projectFile"
git push --set-upstream origin "$newBranch"
