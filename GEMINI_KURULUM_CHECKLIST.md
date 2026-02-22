# Gemini AI Entegrasyonu - Adım Adım Checklist ✅

## ✅ Adım 1: Google AI Studio'dan API anahtarı al (SEN Yapacaksın)
- [ ] https://aistudio.google.com/ adresine git
- [ ] Google hesabınla giriş yap
- [ ] Sağ üstte **"Get API Key"** veya **"Create API Key"** tıkla
- [ ] Yeni proje seç veya mevcut projeyi kullan
- [ ] API anahtarını kopyala (ör: `AIzaSy...`)
- [ ] Anahtarı güvenli bir yerde sakla

---

## ✅ Adım 2: GeminiService — TAMAMLANDI
- `Finans/Finans/Services/GeminiService.swift` oluşturuldu
- `fetchYorum(mevcutIs:teklif:apiKey:)` → Gemini 1.5 Flash API'ye istek atar

---

## ✅ Adım 3: API anahtarı girişi — TAMAMLANDI
- Karşılaştırma formunda API anahtarı boşsa **SecureField** görünür
- Kullanıcı anahtarı girer, "Kaydet" ile `@AppStorage`'a kaydedilir
- Anahtar sonraki açılışlarda otomatik yüklenir

---

## ✅ Adım 4: "AI Yorumu Al" butonu — TAMAMLANDI
- Karşılaştırma formunda turuncu buton
- API anahtarı yoksa buton pasif (gri)
- Yükleme sırasında ProgressView gösterilir

---

## ✅ Adım 5: AI yorumu gösterme — TAMAMLANDI
- Başarılı yanıt: "AI Değerlendirmesi" kartında metin
- Hata: Kırmızı arka planlı hata mesajı

---

## Kullanım Akışı
1. Yan Hak Analizi'ni doldur → "Tamam" veya "Örnek Doldur"
2. Karşılaştırma formunda API anahtarını gir (ilk seferde) → Kaydet
3. **"AI Yorumu Al"** butonuna tıkla
4. Birkaç saniye bekle → AI yorumu görünecek
