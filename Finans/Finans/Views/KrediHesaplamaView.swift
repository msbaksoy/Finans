import SwiftUI

enum KrediTuru: String, CaseIterable {
    case tuketici = "Tüketici Kredisi"
    case konut = "Konut Kredisi"
    case tasit = "Taşıt Kredisi"
    case mevduat = "Mevduat Faizi"
}

struct KrediHesaplamaView: View {
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    Text("Kredi Türü Seçin")
                        .font(AppTypography.title2)
                        .foregroundColor(appTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xs)
                    
                    ForEach(KrediTuru.allCases, id: \.self) { tur in
                        NavigationLink(destination: krediDetayView(tur)) {
                            HStack(spacing: 20) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(krediTuruRengi(tur).opacity(0.2))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: krediTuruIkon(tur))
                                            .font(.system(size: 24))
                                            .foregroundColor(krediTuruRengi(tur))
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tur.rawValue)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(appTheme.textPrimary)
                                    Text(krediTuruAltYazi(tur))
                                        .font(.subheadline)
                                        .foregroundColor(appTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(appTheme.textSecondary)
                            }
                            .padding(AppSpacing.xl)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(appTheme.cardBackgroundSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(krediTuruRengi(tur).opacity(0.25), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: appTheme.isLight ? 4 : 0, y: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(AppSpacing.xxl)
            }
        }
        .navigationTitle("Kredi Hesaplama")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    @ViewBuilder
    private func krediDetayView(_ tur: KrediTuru) -> some View {
        switch tur {
        case .tuketici:
            TuketiciKredisiView()
        case .konut:
            KonutKredisiView()
        case .tasit:
            TasitKredisiView()
        case .mevduat:
            MevduatFaiziView()
        }
    }
    
    private func krediTuruRengi(_ tur: KrediTuru) -> Color {
        switch tur {
        case .tuketici: return Color(hex: "8B5CF6")
        case .konut: return Color(hex: "06B6D4")
        case .tasit: return Color(hex: "F59E0B")
        case .mevduat: return Color(hex: "06B6D4")
        }
    }
    
    private func krediTuruIkon(_ tur: KrediTuru) -> String {
        switch tur {
        case .tuketici: return "creditcard.fill"
        case .konut: return "house.fill"
        case .tasit: return "car.fill"
        case .mevduat: return "building.columns.fill"
        }
    }
    
    private func krediTuruAltYazi(_ tur: KrediTuru) -> String {
        switch tur {
        case .tuketici: return "İhtiyaç kredisi, KKDF ve BSMV dahil"
        case .konut: return "KKDF/BSMV yok, sadece faiz"
        case .tasit: return "Taşıt kredisi hesaplama"
        case .mevduat: return "Basit veya birleşik faiz hesaplama"
        }
    }
}

// MARK: - Placeholder (Konut/Taşıt henüz hazır değil)
struct PlaceholderKrediView: View {
    let tur: String
    let mesaj: String
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 64))
                    .foregroundColor(appTheme.textSecondary.opacity(0.6))
                Text(tur)
                    .font(.title2.weight(.bold))
                    .foregroundColor(appTheme.textPrimary)
                Text(mesaj)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
        .navigationTitle(tur)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        KrediHesaplamaView()
            .environmentObject(AppTheme())
            .environmentObject(KrediConfigService.shared)
            .environmentObject(MevduatConfigService.shared)
    }
}
