#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://github.com/OrionOS-Project/manifest -b bka --depth=1 --git-lfs;
git clone https://github.com/Alromine95/Local-manifest.git -b main .repo/local_manifests;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;


export BUILD_USERNAME=Abhinav
export BUILD_HOSTNAME=foss

rm -rf build/soong/fsgen;

printf '/*\n * Copyright (C) 2025 OrionOS Project\n * SPDX-License-Identifier: Apache-2.0\n */\npackage com.orion.support\n\nimport android.content.ComponentName\nimport android.content.Context\nimport android.content.Intent\nimport android.view.View\nimport androidx.preference.PreferenceScreen\nimport com.android.settings.R\nimport com.android.settingslib.core.AbstractPreferenceController\nimport com.android.settingslib.widget.LayoutPreference\n\nclass MolecularController(\n    context: Context\n) : AbstractPreferenceController(context) {\n\n    override fun displayPreference(screen: PreferenceScreen) {\n        super.displayPreference(screen)\n        val layout = screen.findPreference<LayoutPreference>(PREF_KEY) ?: return\n\n        bind(layout, R.id.molecular_statusbar, STATUSBAR)\n        bind(layout, R.id.molecular_quicksettings, QUICK_SETTINGS)\n        bind(layout, R.id.molecular_button, BUTTON)\n        bind(layout, R.id.molecular_lockscreen, LOCKSCREEN)\n        bind(layout, R.id.molecular_about, ABOUT)\n        bind(layout, R.id.molecular_misc, MISC)\n        bind(layout, R.id.molecular_spoof, SPOOF)\n        bind(layout, R.id.molecular_monet, MONET)\n    }\n\n    private fun bind(\n        layout: LayoutPreference,\n        viewId: Int,\n        activity: String\n    ) {\n        layout.findViewById<View>(viewId)?.setOnClickListener {\n            mContext.startActivity(\n                Intent().apply {\n                    val fullClassName = if (activity.startsWith(SETTINGS_PACKAGE)) activity else "$SETTINGS_PACKAGE.$activity"\n                    component = ComponentName(SETTINGS_PACKAGE, fullClassName)\n                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)\n                }\n            )\n        }\n    }\n\n    override fun isAvailable(): Boolean = true\n\n    override fun getPreferenceKey(): String = PREF_KEY\n\n    companion object {\n        private const val PREF_KEY = "molecular_homepage"\n        private const val SETTINGS_PACKAGE = "com.android.settings"\n        private const val STATUSBAR =\n            "Settings\\$MolecularStatusbarActivity"\n        private const val QUICK_SETTINGS =\n            "Settings\\$MolecularQuickSettingsActivity"\n        private const val BUTTON =\n            "Settings\\$MolecularButtonActivity"\n        private const val LOCKSCREEN =\n            "Settings\\$MolecularLockScreenActivity"\n        private const val ABOUT =\n            "Settings\\$MolecularAboutActivity"\n        private const val MISC =\n            "Settings\\$MolecularMiscActivity"\n        private const val SPOOF =\n            "Settings\\$MolecularSpoofActivity"\n        private const val MONET =\n            "Settings\\$MolecularMonetActivity"\n    }\n}\n' > packages/apps/Molecular/src/com/orion/support/MolecularController.kt ;

XML=vendor/lineage/prebuilt/common/etc/permissions/product-privapp-permissions-aosp.xml
if ! grep -q "com.google.android.deskclock" "$XML"; then
  sed -i 's|</permissions>|<privapp-permissions package="com.google.android.deskclock">\n<permission name="android.permission.CONTROL_DISPLAY_COLOR_TRANSFORMS"/>\n<permission name="android.permission.START_FOREGROUND_SERVICES_FROM_BACKGROUND"/>\n</privapp-permissions>\n</permissions>|' "$XML"
  echo "Patched privapp-permissions XML"
else
  echo "privapp-permissions XML already patched, skipping"
fi

echo "build started!..."

. build/envsetup.sh;
lunch lineage_blossom-bp2a-userdebug;
mka orion -j$(nproc --all);

echo "Upload to GoFile will be started..."

ZIP=$(find out/target/product/blossom -maxdepth 1 -type f -name "*.zip" | head -n 1)

if [ -n "$ZIP" ]; then
    echo "Uploading $ZIP..."
    wget https://raw.githubusercontent.com/lordgaruda/GoFile-Upload/refs/heads/master/upload.sh
    chmod +x upload.sh
    ./upload.sh "$ZIP"
else
    echo "No ROM ZIP found!"
    exit 1
fi







