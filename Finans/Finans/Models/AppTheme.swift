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
        isLight ? Color(hex: "475569") : Color.white.opacity(0.7)
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
}
