"""Injects the LAN/discovery permissions HyperDrop needs into the generated
AndroidManifest.xml. Safe to run repeatedly."""
from pathlib import Path

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")

PERMISSIONS = [
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>',
    '<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>',
    '<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>',
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
    '<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" '
    'android:usesPermissionFlags="neverForLocation"/>',
    '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" '
    'android:maxSdkVersion="32"/>',
    '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" '
    'android:maxSdkVersion="29"/>',
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>',
    '<uses-permission android:name="android.permission.WAKE_LOCK"/>',
]

text = MANIFEST.read_text(encoding="utf-8")
missing = [p for p in PERMISSIONS if p.split('android:name="')[1].split('"')[0] not in text]
if missing:
    marker = "<application"
    idx = text.index(marker)
    text = text[:idx] + "\n    ".join(missing) + "\n    " + text[idx:]

# Allow cleartext LAN sockets (transfers are direct device-to-device).
if "usesCleartextTraffic" not in text:
    text = text.replace("<application", '<application\n        android:usesCleartextTraffic="true"', 1)

MANIFEST.write_text(text, encoding="utf-8")
print(f"Patched {MANIFEST} ({len(missing)} permissions added)")
