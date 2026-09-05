# HyperDrop (Flutter)

Offline, high-speed peer-to-peer file transfer for Android and Windows.
Discovery uses UDP broadcast beacons on the local network; transfers run over a
direct TCP socket with 6-digit pairing codes and SHA-256 verification. No
internet, no accounts, no cloud.

## Run locally

```bash
cd flutter_app
flutter create --platforms=android,windows --org com.hyperdrop --project-name hyperdrop .
python3 ../.github/scripts/patch_android_manifest.py   # Android permissions
flutter pub get
flutter run -d windows      # or: flutter run -d <android-device>
```

The `android/` and `windows/` folders are generated, not committed — the command
above recreates them exactly as CI does.

## Builds

Push to `main` (or open a PR) and GitHub Actions builds both targets:

- `hyperdrop-android-apk` — release `app-release.apk`
- `hyperdrop-windows` — zipped release runner with `hyperdrop.exe`

Push a `v*` tag (e.g. `v1.0.0`) and both artifacts are attached to a GitHub
Release automatically.

## Layout

| Path | Purpose |
| --- | --- |
| `lib/models.dart` | Device, file entry, transfer + history models |
| `lib/services/discovery_service.dart` | UDP beacon discovery of nearby peers |
| `lib/services/transfer_service.dart` | TCP server/client, pairing, chunked streaming, hashing |
| `lib/services/failures.dart` | User-facing failure taxonomy |
| `lib/app_state.dart` | Single source of truth (identity, prefs, outbox, history) |
| `lib/screens/` | Home, Connect, Transfer, Devices, History, Settings |
| `lib/theme.dart` | Deep Charcoal / Electric Blue design system |
