# Contributing

Issues and pull requests are welcome.

## Setup

1. Install the Xcode command line tools: `xcode-select --install`
2. Clone the repo and run `./build.sh install`

`build.sh` builds a universal binary, signs it, copies it to `/Applications`, and restarts Hush. It signs with your first Apple Development or Developer ID certificate, so macOS keeps permissions across rebuilds. Set `HUSH_SIGN_ID` to choose a certificate.

## Guidelines

- Keep Hush small. No dependencies.
- React to system events. Do not add polling.
- Every feature needs an on/off switch in the menu.
- Check CPU and memory before you open a pull request: `top -pid $(pgrep -x Hush)` and `footprint $(pgrep -x Hush)`.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.

## Icon

The icon source is `assets/Hush.icon`. Edit it in Icon Composer, which comes with Xcode 26. Then run `./scripts/make-icon.sh` and commit the files it writes to `Resources/` and `icon.png`.

## Release

1. Update the version in `Info.plist` and add an entry to `CHANGELOG.md`.
2. Tag and push: `git tag -a v0.4.0 -m v0.4.0 && git push --tags`
3. The release workflow attaches `Hush-v0.4.0.zip` and `sha256.txt` to a GitHub release.
4. Update `version` and `sha256` in `Casks/hush.rb` in [homebrew-tap](https://github.com/laurenschristian/homebrew-tap).
