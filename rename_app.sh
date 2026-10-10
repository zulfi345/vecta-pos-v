#!/bin/bash

# 1. Validasi direktori
if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then
    echo "❌ Error: Bukan direktori root proyek Flutter POS yang valid!"
    exit 1
fi

echo "🔄 Memulai perubahan nama aplikasi menjadi 'Vecta POS' dan branding 'Vecta Technology Group'..."

# 2. Mengubah nama aplikasi di Android (AndroidManifest.xml)
ANDROID_MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$ANDROID_MANIFEST" ]; then
    # Mengganti android:label="[nama_lama]" menjadi android:label="Vecta POS"
    sed -i 's/android:label="[^"]*"/android:label="Vecta POS"/g' "$ANDROID_MANIFEST"
    echo "✔ Android Manifest label berhasil diperbarui."
fi

# 3. Mengubah nama aplikasi di iOS (Info.plist)
IOS_INFO_PLIST="ios/Runner/Info.plist"
if [ -f "$IOS_INFO_PLIST" ]; then
    # Menggunakan python atau sed sederhana untuk mengganti CFBundleDisplayName
    sed -i '/<key>CFBundleDisplayName<\/key>/,+1 s/<string>[^<]*<\/string>/<string>Vecta POS<\/string>/' "$IOS_INFO_PLIST"
    echo "✔ iOS Info.plist berhasil diperbarui."
fi

# 4. Mencari dan memperbarui teks Powered by di dalam kode sumber lib/
echo "🔍 Memeriksa dan memperbarui teks 'Powered by' di direktori lib/..."
find lib/ -type f \( -name "*.dart" \) -exec sed -i 's/Powered by [^"]*/Powered by Vecta Technology Group/g' {} +
find lib/ -type f \( -name "*.dart" \) -exec sed -i 's/RetailFlow Solutions/Vecta Technology Group/g' {} +
find lib/ -type f \( -name "*.dart" \) -exec sed -i 's/RetailFlow POS/Vecta POS/g' {} +

echo "🎉 Selesai! Identitas aplikasi berhasil diubah ke Vecta POS & Vecta Technology Group."

