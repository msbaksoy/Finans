import SwiftUI

/// Tema yönetimi – açık/koyu mod, okunabilir renkler
final class AppTheme: ObservableObject {
    @Published var isLight: Bool {
        didSet { UserDefaults.standard.set(isLight, forKey: "app_theme_light") }
    }
    
    init() {
        self.isLight = UserDefaults.standard.object(forKey: "app_theme_light") as? Bool ?? true
    }
    
    func toggle() {
        isLight.toggle()
    }
    
    // MARK: - Tema renkleri (okunabilirlik için)
    var background: Color {
        isLight ? Color(hex: "F8FAFC") : Color(hex: "0F172A")
    }
    
    var backgroundSecondary: Color {
        isLight ? Color(hex: "E2E8F0") : Color(hex: "1E293B")
    }
    
    var textPrimary: Color {
        isLight ? Color(hex: "0F172A") : .white
    }
    
    var textSecondary: Color {
        isLight ? Color(hex: "64748B") : Color.white.opacity(0.8)
    }
    
    /// Beyaz temada: kart içi beyaz. Siyah temada: kart = sayfa rengi (çerçeve ve iç aynı).
    /// Beyaz mod: kart içi beyaz. Siyah mod: kart içi siyah (sayfa ile aynı).
    var cardBackground: Color {
        isLight ? Color.white : Color(hex: "0F172A")
    }
    
    /// Beyaz mod: ince çerçeve. Siyah mod: sayfa ile aynı.
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
