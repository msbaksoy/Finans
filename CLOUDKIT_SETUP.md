# CloudKit'i Etkinleştirme

Uygulama şu an telefon build için iCloud olmadan yapılandırılmıştır. Veriler UserDefaults ile saklanır.

CloudKit (uygulama silindikten sonra veri geri gelsin) için:

1. **Apple Developer Portal** → Identifiers → com.finans.app → iCloud'u etkinleştir, iCloud.com.finans.app container ekle
2. **Finans.entitlements** dosyasına şunu ekle (dict içine):

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.finans.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

3. Xcode → Clean Build → Tekrar derle
