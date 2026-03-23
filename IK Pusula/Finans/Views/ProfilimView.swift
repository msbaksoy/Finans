// ================================================================
// ProfilimView.swift
// ================================================================
// ContentView.swift içindeki Tab 2 (eski: AraclarListView) yerine.
// Tab bar ikinci sekmesi "Profilim" → Kayıtlılar hub'ı.
//
// Bölümler:
//   1. Kayıtlı CV'lerim   (OzgecmisStore.kayitliOzgecmisler)
//   2. Kayıtlı Teklifler  (KariyerProfiliManager — mevcut iş profili)
//   3. Bordro Geçmişi     (SwiftData AylikMaas — yıl bazlı özet)
// ================================================================

import SwiftUI
import SwiftData

struct ProfilimView: View {
    @EnvironmentObject var appTheme: AppTheme
    @StateObject private var ozgecmisStore = OzgecmisStore()
    @ObservedObject private var kariyerManager = KariyerProfiliManager.shared
    @Query(sort: [SortDescriptor(\AylikMaas.yil, order: .reverse)]) private var aylikMaaslar: [AylikMaas]

    @State private var gorundu = false
    @State private var showCVOnizleme: KayitliOzgecmis? = nil
    @State private var showTeklifWizard = false

    // Bordro: yıl bazlı özet
    private var yillar: [Int] {
        Array(Set(aylikMaaslar.map { $0.yil })).sorted(by: >)
    }
    private func yilNetToplam(_ yil: Int) -> Double {
        aylikMaaslar.filter { $0.yil == yil }.reduce(0) { $0 + $1.netTutar }
    }
    private func yilAyliklarSayisi(_ yil: Int) -> Int {
        aylikMaaslar.filter { $0.yil == yil }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    baslik
                        .opacity(gorundu ? 1 : 0)
                        .animation(.easeOut(duration: 0.35), value: gorundu)

                    VStack(spacing: 22) {
                        cvBolumu
                            .opacity(gorundu ? 1 : 0)
                            .offset(y: gorundu ? 0 : 12)
                            .animation(.spring(response: 0.5).delay(0.08), value: gorundu)

                        teklifBolumu
                            .opacity(gorundu ? 1 : 0)
                            .offset(y: gorundu ? 0 : 12)
                            .animation(.spring(response: 0.5).delay(0.14), value: gorundu)

                        bordroBolumu
                            .opacity(gorundu ? 1 : 0)
                            .offset(y: gorundu ? 0 : 12)
                            .animation(.spring(response: 0.5).delay(0.20), value: gorundu)

                        MaasAlarmAyarlariView()
                            .environmentObject(appTheme)
                            .opacity(gorundu ? 1 : 0)
                            .offset(y: gorundu ? 0 : 12)
                            .animation(.spring(response: 0.5).delay(0.24), value: gorundu)

                        Color.clear.frame(height: 44)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { gorundu = true }
                }
            }
            .fullScreenCover(item: $showCVOnizleme) { kayitli in
                OzgecmisKayitliOnizleme(kayit: kayitli)
            }
            .fullScreenCover(isPresented: $showTeklifWizard) {
                TeklifWizardView()
                    .environmentObject(appTheme)
            }
        }
        .environmentObject(ozgecmisStore)
    }

    // MARK: ─ Başlık ───────────────────────────────────────────

    private var baslik: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Color(hex: "060D1F").frame(height: 130)
                RadialGradient(
                    colors: [Color(hex: "3B82F6").opacity(0.12), .clear],
                    center: .init(x: 0.85, y: 0.2),
                    startRadius: 0, endRadius: 150
                )
                .frame(height: 130)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 4) {
                    Color.clear.frame(height: 52)
                    Text("Kayıtlılarım")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("CV'lerim · Tekliflerim · Bordro")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.38))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
        }
    }

    // MARK: ─ Bölüm Başlığı ────────────────────────────────────

    private func bolumBaslik(_ baslik: String, ikon: String, renk: Color, sayi: Int) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(renk.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: ikon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(renk)
            }
            Text(baslik)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
            Spacer()
            if sayi > 0 {
                Text("\(sayi)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(renk)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(renk.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: ─ 1. Kayıtlı CV'lerim ─────────────────────────────

    private var cvBolumu: some View {
        VStack(alignment: .leading, spacing: 12) {
            bolumBaslik("Kayıtlı CV'lerim",
                        ikon: "person.text.rectangle.fill",
                        renk: Color(hex: "8B5CF6"),
                        sayi: ozgecmisStore.kayitliOzgecmisler.count)

            if ozgecmisStore.kayitliOzgecmisler.isEmpty {
                boshDurum(
                    ikon: "doc.badge.plus",
                    baslik: "Henüz kayıtlı CV yok",
                    altyazi: "CV ekranından taslak oluşturup kaydedebilirsin.",
                    renk: Color(hex: "8B5CF6"),
                    hedef: AnyView(OzgecmisAnaView().environmentObject(appTheme))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(ozgecmisStore.kayitliOzgecmisler) { cv in
                        cvKarti(cv)
                    }
                }
            }

            NavigationLink(destination: OzgecmisAnaView().environmentObject(appTheme)) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Yeni CV Oluştur")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: "8B5CF6"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: "8B5CF6").opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "8B5CF6").opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(PressButtonStyle())
        }
    }

    private func cvKarti(_ cv: KayitliOzgecmis) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "8B5CF6").opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(cv.baslik.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "8B5CF6"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(cv.baslik)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                    .lineLimit(1)
                Text(tarihStr(cv.olusturulmaTarihi))
                    .font(.system(size: 11))
                    .foregroundColor(appTheme.textSecondary)
            }

            Spacer()

            Button {
                showCVOnizleme = cv
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8B5CF6"))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "8B5CF6").opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.30), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                ozgecmisStore.kayitSil(cv)
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    // MARK: ─ 2. Kariyer Profili / Teklif ─────────────────────

    private var teklifBolumu: some View {
        VStack(alignment: .leading, spacing: 12) {
            bolumBaslik("Kariyer Profili",
                        ikon: "arrow.left.arrow.right.circle.fill",
                        renk: Color(hex: "F7D44C"),
                        sayi: kariyerManager.hasProfile ? 1 : 0)

            if let profil = kariyerManager.baseProfile {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "F7D44C").opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "D97706"))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(profil.mevcutSirketAdi.isEmpty ? "Mevcut İş" : profil.mevcutSirketAdi)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(appTheme.textPrimary)
                                .lineLimit(1)
                            if !profil.mevcutUnvan.isEmpty {
                                Text(profil.mevcutUnvan)
                                    .font(.system(size: 12))
                                    .foregroundColor(appTheme.textSecondary)
                            }
                        }
                        Spacer()
                        if profil.mevcutBrutMaas > 0 {
                            Text(formatTLKisaLocal(profil.mevcutBrutMaas) + " brüt")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "D97706"))
                        }
                    }
                    .padding(14)

                    Rectangle()
                        .fill(appTheme.cardStroke.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.horizontal, 14)

                    Button {
                        showTeklifWizard = true
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13))
                            Text("Bu profile karşı yeni teklif kıyasla")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "D97706"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .background(appTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: "F7D44C").opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)

            } else {
                boshDurum(
                    ikon: "arrow.left.arrow.right.circle.fill",
                    baslik: "Kariyer profili oluşturulmamış",
                    altyazi: "İş Teklifi Kıyasla'yı tamamlarsan profil burada görünür.",
                    renk: Color(hex: "F7D44C"),
                    hedef: AnyView(KiyaslamaSecimView().environmentObject(appTheme))
                )
            }
        }
    }

    // MARK: ─ 3. Bordro Geçmişi ────────────────────────────────

    private var bordroBolumu: some View {
        VStack(alignment: .leading, spacing: 12) {
            bolumBaslik("Bordro Geçmişi",
                        ikon: "doc.text.fill",
                        renk: Color(hex: "0EA5E9"),
                        sayi: yillar.count)

            if yillar.isEmpty {
                boshDurum(
                    ikon: "doc.text",
                    baslik: "Henüz bordro verisi yok",
                    altyazi: "Bordro Analizi ekranından maaş bilgisi girerek başlayabilirsin.",
                    renk: Color(hex: "0EA5E9"),
                    hedef: AnyView(BrutNetView().environmentObject(appTheme))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(yillar, id: \.self) { yil in
                        NavigationLink(destination: BrutNetView().environmentObject(appTheme)) {
                            bordroYilKarti(yil)
                        }
                        .buttonStyle(PressButtonStyle())
                    }
                }
            }
        }
    }

    private func bordroYilKarti(_ yil: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "0EA5E9").opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(verbatim: String(yil % 100))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "0EA5E9"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: "\(yil) Bordro Özeti")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                Text("\(yilAyliklarSayisi(yil)) aylık veri")
                    .font(.system(size: 11))
                    .foregroundColor(appTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTLKisaLocal(yilNetToplam(yil)))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "34D399"))
                Text("yıllık net")
                    .font(.system(size: 10))
                    .foregroundColor(appTheme.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(appTheme.textSecondary.opacity(0.30))
        }
        .padding(14)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.30), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
    }

    // MARK: ─ Boş Durum ────────────────────────────────────────

    private func boshDurum(ikon: String, baslik: String, altyazi: String, renk: Color, hedef: AnyView) -> some View {
        NavigationLink(destination: hedef) {
            HStack(spacing: 14) {
                Image(systemName: ikon)
                    .font(.system(size: 22))
                    .foregroundColor(renk.opacity(0.5))
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(baslik)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(appTheme.textPrimary)
                    Text(altyazi)
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(renk.opacity(0.5))
            }
            .padding(14)
            .background(renk.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(renk.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(PressButtonStyle())
    }

    // MARK: ─ Yardımcılar ──────────────────────────────────────

    private func tarihStr(_ date: Date) -> String {
        let cal = Calendar.current
        let day = cal.component(.day, from: date)
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "tr_TR")
        monthFormatter.dateFormat = "MMMM"
        let month = monthFormatter.string(from: date)
        let year = cal.component(.year, from: date)
        return "\(day) \(month) \(year)"
    }

    private func formatTLKisaLocal(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.1fM ₺", d / 1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK ₺", d / 1_000) }
        return String(format: "%.0f ₺", d)
    }
}

// MARK: - Kayıtlı CV → Önizleme (ayrı OzgecmisStore örneği)

private struct OzgecmisKayitliOnizleme: View {
    let kayit: KayitliOzgecmis
    @StateObject private var store: OzgecmisStore

    init(kayit: KayitliOzgecmis) {
        self.kayit = kayit
        let s = OzgecmisStore()
        s.kayitYukle(kayit)
        _store = StateObject(wrappedValue: s)
    }

    var body: some View {
        OzgecmisPreviewView()
            .environmentObject(store)
    }
}
