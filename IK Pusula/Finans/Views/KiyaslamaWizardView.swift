import SwiftUI

/// Yeni nesil teklif kıyaslama sihirbazı için giriş noktası.
/// 
/// Şu an için mevcut `TeklifWizardView` akışını sarmalayan
/// bir VIP konteyner gibi çalışır; böylece proje içinde
/// yeni isimle (.fullScreenCover { KiyaslamaWizardView() }) 
/// kullanılabilir hale gelir. İleride adım yapısı bu view 
/// içine taşınarak Apple Wallet tarzı tek parça mimariye
/// evrilebilir.
struct KiyaslamaWizardView: View {
    @EnvironmentObject var appTheme: AppTheme

    /// Düzenleme modunda dışarıdan verilen viewModel (örn. KayitliTeklifDetayView).
    var editingViewModel: KariyerKiyaslamaViewModel? = nil

    var body: some View {
        TeklifWizardView(editingViewModel: editingViewModel)
            .environmentObject(appTheme)
    }
}

