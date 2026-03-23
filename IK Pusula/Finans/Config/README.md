# API anahtarları

1. `APIKeys.xcconfig` içinde `OPENAI_API_KEY` değerini gerçek anahtarınızla doldurun.
2. Yedek olarak `APIKeys.xcconfig.example` dosyasını kopyalayabilirsiniz.
3. Xcode hedefi (IKPusula) bu xcconfig dosyasını **Configuration File** olarak kullanır; anahtar çalışma zamanında `Info.plist` üzerinden `OPENAI_API_KEY` olarak okunur.

**Not:** Anahtarı kaynak kodda tutmayın; App Store incelemesi için xcconfig veya güvenli gizli yönetimi kullanın.
