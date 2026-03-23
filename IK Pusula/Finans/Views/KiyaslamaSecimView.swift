// ================================================================
// KiyaslamaSecimView.swift — DÜZELTİLDİ
// ================================================================
// Hızlı Analiz kaldırıldı. Ekran artık doğrudan "İş Teklifi Analizi"
// sihirbazını açıyor.
// ================================================================

import SwiftUI

struct KiyaslamaSecimView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appTheme: AppTheme
    @StateObject private var viewModel = KariyerKiyaslamaViewModel()
    @State private var isWizardPresented = false

    var isCreatingProfile: Bool = false
    var isAddingOffer: Bool = false

    var body: some View {
        ZStack {
            appTheme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(hex: "0B0F1A"), Color(hex: "111827")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: 220)

                    // Altın halo
                    RadialGradient(
                        colors: [Color(hex: "F7D44C").opacity(0.18), .clear],
                        center: .init(x: 0.8, y: 0.2),
                        startRadius: 0, endRadius: 180
                    )
                    .frame(height: 220)
                    .allowsHitTesting(false)

                    VStack(alignment: .leading, spacing: 8) {
                        // Başlık
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "F7D44C"))
                            Text("KARİYER ANALİZİ")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(hex: "F7D44C"))
                                .tracking(2)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(hex: "F7D44C").opacity(0.12))
                        .clipShape(Capsule())

                        Text("İş Teklifi\nAnalizini Başlat")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(2)

                        Text("Mevcut işin mi, yeni teklif mi? Detaylı analiz et.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.50))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Ana başlatma kartı
                        Button {
                            viewModel.isDeepAnalysisSelected = true
                            viewModel.currentStep = 0
                            if isAddingOffer { viewModel.loadBaseProfileAsCurrent() }
                            isWizardPresented = true
                        } label: {
                            HStack(spacing: 20) {
                                // Sol: ikon
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "F7D44C").opacity(0.15))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "chart.bar.xaxis.ascending.badge.clock")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(Color(hex: "F7D44C"))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Analizi Başlat")
                                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Maaş · Yan haklar · Çalışma koşulları\nKariyere etkisi · AI yorumu")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.55))
                                        .lineSpacing(3)
                                }

                                Spacer()

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "F7D44C"))
                            }
                            .padding(24)
                            .background(Color(hex: "111827"))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color(hex: "F7D44C").opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color(hex: "F7D44C").opacity(0.10), radius: 20, y: 6)
                        }
                        .buttonStyle(PressButtonStyle())

                        // Özellik listesi
                        VStack(spacing: 12) {
                            ozellikSatiri(ikon: "turkishlirasign.circle.fill", renk: "34D399",
                                          baslik: "Gerçek Yıllık Paket",
                                          altyazi: "Tüm yan haklar dahil karşılaştırma")
                            ozellikSatiri(ikon: "clock.fill", renk: "60A5FA",
                                          baslik: "Kariyer Etkisi",
                                          altyazi: "Unvan, kıdem ve gelecek potansiyeli")
                            ozellikSatiri(ikon: "brain.head.profile", renk: "A78BFA",
                                          baslik: "AI Analizi",
                                          altyazi: "Yapay zeka yorum ve önerileri")
                            ozellikSatiri(ikon: "doc.richtext.fill", renk: "F59E0B",
                                          baslik: "PDF Rapor",
                                          altyazi: "Kaydet ve paylaş")
                        }
                        .padding(18)
                        .background(appTheme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $isWizardPresented) {
            TeklifWizardView(editingViewModel: nil)
                .environmentObject(appTheme)
        }
    }

    private func ozellikSatiri(ikon: String, renk: String, baslik: String, altyazi: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: renk).opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: ikon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: renk))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(baslik)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                Text(altyazi)
                    .font(.system(size: 12))
                    .foregroundColor(appTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: renk))
        }
    }
}
