import SwiftUI
import UIKit

// HEX destekli Color initializer — proje genelinde kullanılıyor.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// Tema yönetimi – Design System 2.0 (Anayasa): token’lar + semantik renkler
@MainActor
final class AppTheme: ObservableObject {
    @AppStorage("app_theme_light") var isLight: Bool = true

    // MARK: - Design Tokens (Anayasa)
    enum Tokens {
        static let mainRadius: CGFloat = 24
        static let subRadius: CGFloat = 16
        static let padding: CGFloat = 20
        static let shadowRadius: CGFloat = 12
        static var squircleStyle: RoundedRectangle {
            RoundedRectangle(cornerRadius: mainRadius, style: .continuous)
        }
    }

    func toggle() {
        isLight.toggle()
    }

    // MARK: - Semantic Colors (Design System)
    var brandPrimary: Color { isLight ? Color(hex: "3B82F6") : Color(hex: "60A5FA") }
    var backgroundMain: Color { isLight ? Color(hex: "F8FAFC") : Color(hex: "0F172A") }
    var cardSurface: Color { isLight ? .white : Color(hex: "1E293B") }
    var textMain: Color { isLight ? Color(hex: "0F172A") : .white }

    // MARK: - Tema renkleri (geriye dönük uyumluluk)
    var background: Color { backgroundMain }
    var backgroundSecondary: Color {
        isLight ? Color(hex: "E2E8F0") : Color(hex: "1E293B")
    }
    var textPrimary: Color { textMain }
    var textSecondary: Color {
        isLight ? Color(hex: "64748B") : Color.white.opacity(0.8)
    }
    var cardBackground: Color {
        isLight ? Color.white : Color(hex: "0F172A")
    }
    var cardStroke: Color {
        isLight ? Color(hex: "E2E8F0") : Color(hex: "0F172A")
    }
    
    var colorScheme: ColorScheme {
        isLight ? .light : .dark
    }
    
    /// Liste satırı, özet kartı arka planı
    var listRowBackground: Color {
        isLight ? Color(hex: "F1F5F9") : Color.white.opacity(0.06)
    }
    
    /// İkincil kart arka planı (biraz daha koyu/açık)
    var cardBackgroundSecondary: Color {
        isLight ? Color(hex: "F8FAFC") : Color.white.opacity(0.08)
    }
    
    /// Form input arka planı (sheet'lerde)
    var formInputBackground: Color {
        isLight ? Color(hex: "E2E8F0") : Color.white.opacity(0.08)
    }
    
    /// Form secondary input (nested alanlar)
    var formInputSecondary: Color {
        isLight ? Color(hex: "F1F5F9") : Color.white.opacity(0.06)
    }

    // MARK: - Semantik renkler (Design System — açık/koyu mod uyumlu, gradient türetme opacity ile)

    /// Birincil vurgu (mavi) — brandPrimary ile aynı
    var primaryAccent: Color { brandPrimary }

    /// İkincil vurgu (mor) — Kıyaslama teklif, Portföy
    var secondaryAccent: Color {
        isLight ? Color(hex: "8B5CF6") : Color(hex: "A78BFA")
    }

    /// Başarı / gelir / onay (yeşil)
    var successColor: Color {
        isLight ? Color(hex: "10B981") : Color(hex: "34D399")
    }

    /// Uyarı / Kredi / ikincil CTA (turuncu/amber)
    var warningColor: Color {
        isLight ? Color(hex: "D97706") : Color(hex: "F59E0B")
    }

    /// Gider / iptal / silme (kırmızı) — iki modda aynı
    var dangerColor: Color { Color(hex: "F87171") }

    /// Özel modül vurgusu (cyan — Mevduat, Konut kredisi)
    var cyanAccent: Color {
        isLight ? Color(hex: "0891B2") : Color(hex: "06B6D4")
    }

    /// İkincil ikon / nötr
    var neutralSecondary: Color { Color(hex: "64748B") }

    /// Kart gölgesi — açık modda hafif gölge, koyu modda yok
    var cardShadowOpacity: Double { isLight ? 0.04 : 0 }
    var cardShadowRadius: CGFloat { isLight ? 8 : 0 }
    var cardShadowY: CGFloat { 4 }
}

// MARK: - Tipografi (Apple HIG uyumlu)
enum AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
    
    /// Finansal tutarlar için rounded design (Stripe/Apple tarzı)
    static let amountLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    static let amountMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let amountSmall = Font.system(size: 16, weight: .semibold, design: .rounded)
}

// MARK: - Spacing Sistemi (4pt tabanlı)
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Köşe yuvarlama (Design System — 3–4 seviye)
enum AppRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Kart gölgesi (tema uyumlu)
extension View {
    func cardShadow(theme: AppTheme) -> some View {
        shadow(
            color: .black.opacity(theme.cardShadowOpacity),
            radius: theme.cardShadowRadius,
            y: theme.cardShadowY
        )
    }

    /// Premium kart — Design Tokens ile (squircle, padding, gölge)
    func premiumCard(theme: AppTheme) -> some View {
        self
            .padding(AppTheme.Tokens.padding)
            .background(theme.cardSurface)
            .clipShape(AppTheme.Tokens.squircleStyle)
            .shadow(
                color: .black.opacity(theme.isLight ? 0.06 : 0.2),
                radius: AppTheme.Tokens.shadowRadius,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Haptic (premium his)
enum HapticHelper {
    static func triggerImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
    }

    static func triggerSuccess() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
}

// MARK: - Finans Formatlayıcıları

/// Metin alanından sayıyı parse eder (TR: 1.234,56 veya 1234,56). Tüm modüllerde kullanılır.
func parseFormattedNumber(_ text: String?) -> Double? {
    guard let t = text?.trimmingCharacters(in: .whitespaces), !t.isEmpty else { return nil }
    
    // Kullanıcı girişinde '.' ve ',' şu rolleri üstlenebilir:
    // - TR: 1.234,56  => '.' binlik, ',' ondalık
    // - EN: 1,234.56  => ',' binlik, '.' ondalık
    // - Tek ondalık: 3.6 / 3,6
    let normalized = t.replacingOccurrences(of: "\u{00A0}", with: "").trimmingCharacters(in: .whitespaces)
    
    // Sadece rakam/işaret/ayraç kalacak şekilde temizle.
    // Not: '-' negatif sayılarda kullanılır.
    let allowedSet = CharacterSet(charactersIn: "0123456789-.,")
    let filteredScalars = normalized.unicodeScalars.filter { allowedSet.contains($0) }
    let filtered = String(filteredScalars)
    guard !filtered.isEmpty else { return nil }
    
    let dotCount = filtered.filter { $0 == "." }.count
    let commaCount = filtered.filter { $0 == "," }.count
    let lastDot = filtered.lastIndex(of: ".")
    let lastComma = filtered.lastIndex(of: ",")
    
    // Hem '.' hem ',' varsa: son görülen ayraç ondalık kabul edilir.
    if dotCount > 0 && commaCount > 0, let d = lastDot, let c = lastComma {
        let decimalIsDot = d > c
        if decimalIsDot {
            // '.' ondalık, ',' binlik
            let noThousands = filtered.replacingOccurrences(of: ",", with: "")
            return Double(noThousands)
        } else {
            // ',' ondalık, '.' binlik
            let noThousands = filtered.replacingOccurrences(of: ".", with: "")
            let decimalNormalized = noThousands.replacingOccurrences(of: ",", with: ".")
            return Double(decimalNormalized)
        }
    }
    
    // Sadece ',' varsa: ',' ondalık kabul et.
    if commaCount > 0 && dotCount == 0 {
        if commaCount == 1 {
            let normalizedDecimal = filtered.replacingOccurrences(of: ",", with: ".")
            return Double(normalizedDecimal)
        } else {
            // Birden fazla ',' -> muhtemelen binlik ayırıcı; hepsini kaldır.
            let noThousands = filtered.replacingOccurrences(of: ",", with: "")
            return Double(noThousands)
        }
    }
    
    // Sadece '.' varsa: '.' ondalık kabul et; ama "12.345" gibi binlik formatı için
    // fraksiyon kısmı 3 haneliyse binlik say (heuristic).
    if dotCount > 0 && commaCount == 0 {
        if dotCount == 1, let dotIndex = filtered.firstIndex(of: ".") {
            let fractionalLen = filtered[filtered.index(after: dotIndex)...].count
            if fractionalLen == 3 {
                // 12.345 => 12345 (binlik ayrımı)
                let noThousands = filtered.replacingOccurrences(of: ".", with: "")
                return Double(noThousands)
            } else {
                // 3.6 => 3.6
                return Double(filtered)
            }
        }
        // Birden fazla '.' -> binlik ayrıcı varsayımıyla kaldır.
        let noThousands = filtered.replacingOccurrences(of: ".", with: "")
        return Double(noThousands)
    }
    
    // Hiç ayraç yoksa direkt parse
    return Double(filtered)
}

/// Double değeri TR para formatında metne çevirir (decimals opsiyonel).
func formatCurrency(_ value: Double, decimals: Int = 2) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.numberStyle = .currency
    formatter.currencySymbol = "₺"
    formatter.minimumFractionDigits = decimals
    formatter.maximumFractionDigits = decimals
    return formatter.string(from: NSNumber(value: value)) ?? "₺\(value)"
}

/// Sayı metnini TR giriş formatına çevirir (örn. "1234.56" → "1.234,56").
func formatNumberGiris(_ value: String, allowDecimals: Bool) -> String {
    guard let d = Double(value.replacingOccurrences(of: ",", with: ".")) else { return value }
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = allowDecimals ? 2 : 0
    formatter.maximumFractionDigits = allowDecimals ? 2 : 0
    return formatter.string(from: NSNumber(value: d)) ?? value
}

enum FinanceFormatter {
    static func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₺\(Int(value))"
    }

    /// Büyük tutarları Milyar (Mr) / Milyon (M) kısaltmasıyla gösterir; taşmayı önler.
    static func kompaktMiktar(_ amount: Double) -> String {
        let sign = amount < 0 ? "-" : ""
        let absAmount = abs(amount)

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = "."

        if absAmount >= 1_000_000_000 {
            let val = formatter.string(from: NSNumber(value: absAmount / 1_000_000_000)) ?? ""
            return "\(sign)₺\(val) Mr"
        } else if absAmount >= 1_000_000 {
            let val = formatter.string(from: NSNumber(value: absAmount / 1_000_000)) ?? ""
            return "\(sign)₺\(val) M"
        } else {
            return currencyString(amount)
        }
    }
}

// MARK: - Global Para Birimi Extension'ı

extension Double {
    /// Rakamı Türkiye yereline uygun ₺ formatına dönüştürür.
    /// - Parameters:
    ///   - minFraction: Minimum kuruş hanesi (varsayılan 2)
    ///   - maxFraction: Maksimum kuruş hanesi (varsayılan 2)
    func asCurrency(minFraction: Int = 2, maxFraction: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.currencySymbol = "₺"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = minFraction
        formatter.maximumFractionDigits = maxFraction
        return formatter.string(from: NSNumber(value: self)) ?? "₺\(self)"
    }

    /// Kuruşlu standart format (örn: 1.250,50 ₺)
    var asCurrency: String {
        asCurrency(minFraction: 2, maxFraction: 2)
    }

    /// Kuruş hanesi olmayan basit format (örn: 15.000 ₺).
    var asCurrencySimple: String {
        asCurrency(minFraction: 0, maxFraction: 0)
    }
}

// MARK: - Buton Stilleri
// Renk dışarıdan verilir; tema ile uyum için .buttonStyle(PrimaryButtonStyle(color: appTheme.warningColor)) kullanın.

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AppRadius.lg)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0 : 0.12), radius: 10, y: 4)
            .accessibilityAddTraits(.isButton)
            .contentShape(Rectangle())
    }
}
