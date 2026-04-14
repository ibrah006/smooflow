## Create Installers

### Macos
Build release:
```bash
flutter build macos --release
```
Create DMG installer:
```bash
mkdir -p build/macos/Build/Products/Release/installer                                             

create-dmg \
  --volname "Smooflow" \
  --volicon "assets/icons/logo.png" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 128 \
  --icon "smooflow.app" 200 190 \
  --hide-extension "smooflow.app" \
  --app-drop-link 600 185 \
  "build/macos/Build/Products/Release/installer/Smooflow-1.0.dmg" \
  "build/macos/Build/Products/Release/smooflow.app"
```

### build for both intel & silicon macs
```bash
arch -x86_64 flutter build macos --release
```

## Build Release & Distrubute

### Windows

### Build Release Setup

#### Make sure `openssl` is installed
```bash
choco install openssl
```

Generate key files: <b>dsa_priv.pem, dsa_pub.pem</b>
```bash
dart run auto_updater:generate_keys
```

Build release
```bash
flutter build windows --release
```

Create updated installer
```bash
fastforge release
```

### New:
```bash
fastforge release --name prod --jobs windows-release
```

#### Sign
```bash
dart run auto_updater:sign_update dist/1.0.0/smooflow-1.0.0-windows-setup.exe
```

---

## 🔒 License

This project is **proprietary / source-available**.

The source code is visible for evaluation purposes only.
Unauthorized use, redistribution, or commercial use is prohibited.

See the [LICENSE](./LICENSE) file for details.