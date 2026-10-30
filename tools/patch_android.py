#!/usr/bin/env python3
"""Runs in CI after the Android scaffold is copied in.

1. AndroidManifest: notification permissions + receivers, Arabic app label.
2. app/build.gradle(.kts): enable core library desugaring (needed by
   flutter_local_notifications).
Fails loudly (exit 1) if the expected anchors are missing.
"""
import pathlib
import re
import sys

root = pathlib.Path("android")
manifest = root / "app/src/main/AndroidManifest.xml"
if not manifest.exists():
    sys.exit("AndroidManifest.xml not found")

text = manifest.read_text(encoding="utf-8")

PERMS = """    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
"""
RECEIVERS = """        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""

if "POST_NOTIFICATIONS" not in text:
    if "<application" not in text or "</application>" not in text:
        sys.exit("Manifest anchors missing")
    text = text.replace("<application", PERMS + "    <application", 1)
    text = text.replace("</application>", RECEIVERS + "    </application>", 1)

text = re.sub(r'android:label="[^"]*"', 'android:label="دراسي"', text, count=1)
manifest.write_text(text, encoding="utf-8")

gradle = None
for name in ("build.gradle", "build.gradle.kts"):
    f = root / "app" / name
    if f.exists():
        gradle = f
        break
if gradle is None:
    sys.exit("app/build.gradle(.kts) not found")

g = gradle.read_text(encoding="utf-8")
kts = gradle.suffix == ".kts"

if "desugar_jdk_libs" not in g:
    flag = "isCoreLibraryDesugaringEnabled = true" if kts else "coreLibraryDesugaringEnabled true"
    g, n = re.subn(r"(compileOptions\s*\{)", r"\1\n        " + flag, g, count=1)
    if n != 1:
        sys.exit("compileOptions block not found in " + gradle.name)
    dep = ('coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")'
           if kts else
           "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'")
    if re.search(r"^dependencies\s*\{", g, re.M):
        g = re.sub(r"^(dependencies\s*\{)", r"\1\n    " + dep, g, count=1, flags=re.M)
    else:
        g += "\ndependencies {\n    " + dep + "\n}\n"
    gradle.write_text(g, encoding="utf-8")

print("Android patched OK:", gradle.name)
