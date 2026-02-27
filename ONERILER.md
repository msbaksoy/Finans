# Finans Projesi — Öneriler

Bu belge, proje dökümüne dayanarak yapılabilecek iyileştirmeleri öncelik sırasına göre listeler.

---

## 1. Öncelik: Dosya ve proje tutarlılığı

### 1.1 Kullanılmayan / çift dosyaları temizle

- **Durum:** `Finans/Finans/Finans/Models/` altında **Color+Hex.swift** ve **DesignSystem.swift** var; **project.pbxproj içinde referansları yok.** Yani derlemede kullanılmıyorlar. Aynı işi `AppTheme.swift` (tema, Color(hex:), FinanceFormatter, PrimaryButtonStyle vb.) zaten yapıyor.
- **Öneri:** Bu iki dosyayı (ve gerekiyorsa boş kalan `Finans/Finans/Finans/` klasörünü) sil. Böylece:
  - Çift tanım riski kalkar.
  - Hangi dosyanın “tek kaynak” olduğu netleşir.
  - Proje yapısı sadeleşir.

**Yapılacak:**  
`Finans/Finans/Finans/Models/Color+Hex.swift` ve `Finans/Finans/Finans/Models/DesignSystem.swift` dosyalarını sil; klasör boşsa `Finans/Finans/Finans/` klasörünü de kaldır.

---

## 2. Öncelik: ContentView sadeleştirme

### 2.1 Kullanılmayan legacy view’ları kaldır

- **Durum:** `ContentView.swift` içinde hâlâ **referans amaçlı** bırakılmış, gerçekte kullanılmayan yapılar var:
  - `LegacyKiyaslamaCommuteView`
  - `LegacyKiyaslamaYemekView`
  - `LegacyDashboardView`
- **Öneri:** Bu üç `fileprivate struct`’ı tamamen sil. Akış zaten `KiyaslamaFlow.swift` içindeki `KiyaslamaCommuteView`, `KiyaslamaYemekView` ve `DashboardView` ile yürüyor; legacy kopyalar sadece dosyayı şişiriyor.

### 2.2 Kullanılmayan WorkCommuteInputView

- **Durum:** `WorkCommuteInputView` (ulaşım/commute girişi) tanımlı ama hiçbir `destination` veya sayfa bu view’ı göstermiyor; yorumda da “bu view şu anda kullanılmıyor” deniyor.
- **Öneri:** Gerçekten kullanılmıyorsa bu struct’ı da kaldır. İleride ihtiyaç olursa `KiyaslamaFlow` veya ayrı bir dosyada yeniden yazılabilir.

### 2.3 TransportMethod ve TransportOptionButton

- **Durum:** `TransportMethod` enum’ı ve `TransportOptionButton` ContentView içinde; kıyaslama akışıyla ilgili.
- **Öneri:**  
  - `TransportMethod`’u **KiyaslamaModels.swift**’e taşı (WorkModel, YemekImkani ile aynı domain).  
  - `TransportOptionButton`’ı **KiyaslamaComponents.swift**’e taşı (veya KiyaslamaFlow’da kullanılan yere yakın bir component dosyasına).  
  Böylece ContentView daha çok “kapsayıcı + navigasyon” rolüne oturur.

### 2.4 ContentView’daki tekrarlayan kart bileşenleri

- **Durum:** `SectionHeader`, `FeaturedCard`, `SquareModuleCard`, `ToolRow` ContentView’da `fileprivate` tanımlı; **DashboardView** kendi içinde aynı isimlerle tekrar tanımlıyor (fileprivate).
- **Öneri:** Bu ortak kart/başlık bileşenlerini tek yerde topla:  
  - Ya **AppTheme.swift**’in sonuna** (veya ayrı bir `DesignComponents.swift`) “shared UI” olarak ekle,  
  - Ya da **DashboardView** kendi dosyasında kullanıyorsa, ContentView’daki kopyaları kaldır ve sadece Dashboard’daki tanımı kullan.  
  Böylece aynı isimde iki ayrı tanım kalkar, bakım kolaylaşır.

---

## 3. Orta öncelik: Tasarım ve veri akışı

### 3.1 Tasarım sistemini tek yerde toplama

- **Durum:** Renk, tipografi, spacing, buton stilleri ve formatlar büyük ölçüde **AppTheme.swift**’te; bazı view’lar hâlâ `Color(hex: "…")` veya `UIColor.secondarySystemGroupedBackground` gibi dağınık kullanımlar yapıyor.
- **Öneri:**  
  - Mümkün olan yerlerde `appTheme.textPrimary`, `appTheme.cardBackground` vb. kullan.  
  - Sabit renkler (örn. vurgu renkleri) için AppTheme’e `static let accentKredi = Color(hex: "8B5CF6")` gibi isimli sabitler ekleyip view’ların bunları kullanmasını sağla.  
  Böylece tema değişince tek yerden güncellemek kolaylaşır.

### 3.2 Sheet’lerde EnvironmentObject

- **Durum:** Bazı sheet’lerde sadece `appTheme` veriliyor; `dataManager` verilmiyor (örn. AddIncomeView, AddExpenseView sheet’leri).
- **Öneri:** Bu sheet’lerin içinde `DataManager` kullanılıyorsa (gelir/gider ekleme gibi), ilgili sheet çağrılarına `.environmentObject(dataManager)` ekle. Zaten `ContentView` → `DashboardView` zincirinde veriliyorsa sorun yok; ama doğrudan sheet açan view’lar (örn. BudgetView) kendi `dataManager`’ını almıyorsa environment’a eklenmeli.

---

## 4. Düşük öncelik / ileride

### 4.1 BudgetView’daki PDF paylaşımı

- **Durum:** `PdfShareSheet` ve `formatCurrency` BudgetView.swift içinde; BrutNetView’da da benzer paylaşım var.
- **Öneri:** PDF paylaşımı için ortak bir helper (ör. `PdfShareSheet` + ortak formatlama) tek dosyada toplanabilir; şu an acil değil.

### 4.2 CloudKit

- **Durum:** `DataManager` içinde `useCloudKit = false` ile kapalı.
- **Öneri:** iCloud kullanmayacaksanız ileride CloudKit kodunu minimize edebilir veya feature-flag ile tamamen ayırabilirsiniz; şu an için olduğu gibi bırakılabilir.

### 4.3 Unit test

- **Durum:** Proje dökümünde test target’ı yok.
- **Öneri:** Özellikle `BrutNetCalculator`, `KrediCalculator` ve `parseFormattedNumber` / `formatNumberGiris` gibi mantık yoğun yerler için unit test eklemek, refaktör ve güncellemelerde güveni artırır.

---

## Özet eylem listesi

| Öncelik | Ne yapılacak? |
|--------|----------------|
| **1**  | `Finans/Finans/Finans/Models/Color+Hex.swift` ve `DesignSystem.swift` dosyalarını sil; boşsa `Finans/Finans/Finans/` klasörünü kaldır. |
| **2**  | ContentView’dan `LegacyKiyaslamaCommuteView`, `LegacyKiyaslamaYemekView`, `LegacyDashboardView` struct’larını kaldır. |
| **3**  | Kullanılmıyorsa `WorkCommuteInputView`’ı ContentView’dan kaldır. |
| **4**  | `TransportMethod`’u KiyaslamaModels.swift’e taşı; `TransportOptionButton`’ı KiyaslamaComponents’e (veya uygun yere) taşı ve ContentView’dan çıkar. |
| **5**  | SectionHeader, FeaturedCard, SquareModuleCard, ToolRow için tek kaynak belirle (ContentView veya DashboardView); diğerindeki tekrarı kaldır. |
| **6**  | Sheet açan ekranlarda gerekirse `.environmentObject(dataManager)` eksikse ekle. |
| **7**  | Uzun vadede: Tema renklerini AppTheme sabitlerine çekmek, PDF/formatlama ortaklaştırmak, kritik hesaplar için unit test eklemek. |

İlk dört madde projeyi daha tutarlı ve bakımı kolay hale getirir; 5–7 isteğe ve zamana göre adım adım yapılabilir.
