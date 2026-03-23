// ================================================================
// ContentView.swift — TAMAMEN YENİDEN TASARIM
// Dashboard: Bento Grid layout, glassmorphism kartlar,
// animasyonlu hero, net navigasyon
// ================================================================

import SwiftUI
import SwiftData
import UIKit

private enum TabTag: Int { case ana = 0, araclar = 1 }

// MARK: ─ Root ─────────────────────────────────────────────────
struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @State private var selectedTab: Int = TabTag.ana.rawValue

    /// SwiftUI tab bar arka planı — `UITabBar.appearance()` kullanmıyoruz (AttributeGraph döngüsü riski).
    private var tabBarBackground: Color {
        appTheme.isLight ? Color(hex: "F8FAFC") : Color(hex: "07080A")
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectedTab: $selectedTab)
                    .environmentObject(dataManager)
                    .environmentObject(appTheme)
                    .navigationBarHidden(true)
                    .modelContainer(IKPusulaApp.modelContainer)
            }
            .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
            .tag(TabTag.ana.rawValue)

            NavigationStack {
                ProfilimView()
                    .environmentObject(dataManager)
                    .environmentObject(appTheme)
                    .modelContainer(IKPusulaApp.modelContainer)
            }
            .tabItem { Label("Profilim", systemImage: "person.crop.circle.fill") }
            .tag(TabTag.araclar.rawValue)
        }
        .tint(Color(hex: "F7D44C"))
        .toolbarBackground(tabBarBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .imageScale(.large)
                }
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { dataManager.lastUserFacingError != nil },
            set: { if !$0 { dataManager.clearLastError() } }
        )) {
            Button("Tamam") { dataManager.clearLastError() }
        } message: {
            if let msg = dataManager.lastUserFacingError { Text(msg) }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: DASHBOARD — YEPYENİ TASARIM
// MARK: ═══════════════════════════════════════════════════════════
struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @Binding var selectedTab: Int

    @State private var gorundu = false
    @State private var simdikiZaman = Date()
    private let zamanTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // Zaman
    private var saat: Int { Calendar.current.component(.hour, from: simdikiZaman) }
    private var saatStr: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: simdikiZaman)
    }
    private var tarihStr: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: simdikiZaman)
    }
    private var selamlama: String {
        switch saat {
        case 5..<12:  return "Günaydın"
        case 12..<17: return "İyi günler"
        case 17..<21: return "İyi akşamlar"
        default:       return "İyi geceler"
        }
    }
    private var sallamaEmoji: String {
        switch saat {
        case 5..<12: return "☀️"
        case 12..<17: return "🌤"
        case 17..<21: return "🌆"
        default: return "🌙"
        }
    }

    var body: some View {
        ZStack {
            // Arka plan
            (appTheme.isLight
                ? LinearGradient(colors: [Color(hex: "F0F4F8"), Color(hex: "E2E8F0")],
                                  startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Color(hex: "07080A"), Color(hex: "0F1218")],
                                  startPoint: .top, endPoint: .bottom)
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBolumu
                    heroCTA
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .dAnim(gorundu, delay: 0.06)

                    // MARK: Bento Grid
                    bentoKariyerGrid
                        .padding(.top, 24)
                        .dAnim(gorundu, delay: 0.12)

                    bentoMaasGrid
                        .padding(.top, 20)
                        .dAnim(gorundu, delay: 0.20)

                    Color.clear
                        .frame(height: 60)
                        .dAnim(gorundu, delay: 0.28)
                }
            }
        }
        .onAppear {
            simdikiZaman = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.5)) { gorundu = true }
            }
        }
        .onReceive(zamanTimer) { simdikiZaman = $0 }
    }

    // MARK: ─ Header ───────────────────────────────────────────
    private var headerBolumu: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 52)

            HStack(alignment: .center) {
                // Logo
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F7D44C"), Color(hex: "F0BC2E")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 34, height: 34)
                        Image(systemName: "dial.medium.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "060D1F"))
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("İK PUSULA")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(appTheme.textPrimary)
                            .tracking(2)
                        Text(tarihStr)
                            .font(.system(size: 10))
                            .foregroundColor(appTheme.textSecondary)
                    }
                }

                Spacer()

                // Tema butonu
                Button {
                    withAnimation(.spring(response: 0.35)) { appTheme.toggle() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(appTheme.isLight ? Color.white : Color.white.opacity(0.08))
                            .frame(width: 38, height: 38)
                            .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0), radius: 8, y: 2)
                        Image(systemName: appTheme.isLight ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(appTheme.isLight ? Color(hex: "64748B") : Color(hex: "F59E0B"))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Selamlama
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selamlama) \(sallamaEmoji)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(appTheme.textPrimary)
                    Text("Kariyer yolculuğuna devam et")
                        .font(.system(size: 13))
                        .foregroundColor(appTheme.textSecondary)
                }
                Spacer()
                Text(saatStr)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(appTheme.textPrimary.opacity(0.12))
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .opacity(gorundu ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: gorundu)
    }

    // MARK: ─ Hero CTA ─────────────────────────────────────────
    private var heroCTA: some View {
        NavigationLink(destination: KiyaslamaSecimView().environmentObject(appTheme)) {
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    // Arka plan gradient
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F7D44C"), Color(hex: "F0BC2E"), Color(hex: "E5A300")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)

                    // Dekoratif daireler (ekran genişliği yerine gerçek kart genişliği)
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 140)
                        .offset(x: w * 0.52, y: -30)
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 80)
                        .offset(x: w * 0.15, y: 30)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                Text("EN POPÜLER")
                                    .font(.system(size: 9, weight: .black))
                                    .tracking(1.5)
                            }
                            .foregroundColor(Color(hex: "060D1F").opacity(0.50))

                            Text("İş Teklifi Analizi")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: "060D1F"))

                            Text("Mevcut iş mi, yeni teklif mi?")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "060D1F").opacity(0.50))
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color(hex: "060D1F"))
                                .frame(width: 42, height: 42)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "F7D44C"))
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .frame(width: geo.size.width, height: 120)
            }
            .frame(height: 120)
        }
        .buttonStyle(PressButtonStyle())
    }

    // MARK: ─ Bölüm Başlığı ────────────────────────────────────
    @ViewBuilder
    private func bolumBaslik(_ text: String, ikon: String, renk: Color) -> some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(renk.opacity(0.12))
                    .frame(width: 24, height: 24)
                Image(systemName: ikon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(renk)
            }
            Text(text)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(appTheme.textSecondary)
                .tracking(1.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: ─ KARİYER Bento Grid ───────────────────────────────
    private var bentoKariyerGrid: some View {
        VStack(spacing: 10) {
            bolumBaslik("KARİYER", ikon: "person.fill.checkmark", renk: Color(hex: "8B5CF6"))

            // Üst satır: 2 kart yan yana
            HStack(spacing: 10) {
                bentoKart(
                    baslik: "Mülakat\nSimülasyonu",
                    altyazi: "AI ile pratik",
                    ikon: "mic.fill",
                    renk: Color(hex: "EF4444"),
                    gradientColors: [Color(hex: "FEE2E2"), Color(hex: "FECACA")],
                    darkGradient: [Color(hex: "2D1515"), Color(hex: "1F1010")],
                    hedef: AnyView(MulakatGirisView()),
                    boyut: .medium
                )
                bentoKart(
                    baslik: "CV\nOluştur",
                    altyazi: "Profesyonel PDF",
                    ikon: "doc.text.fill",
                    renk: Color(hex: "8B5CF6"),
                    gradientColors: [Color(hex: "EDE9FE"), Color(hex: "DDD6FE")],
                    darkGradient: [Color(hex: "1E1533"), Color(hex: "150F25")],
                    hedef: AnyView(OzgecmisAnaView()),
                    boyut: .medium
                )
            }
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                bentoKart(
                    baslik: "Kariyer\nKoçu",
                    altyazi: "AI ile sohbet",
                    ikon: "brain.head.profile",
                    renk: Color(hex: "8B5CF6"),
                    gradientColors: [Color(hex: "EDE9FE"), Color(hex: "DDD6FE")],
                    darkGradient: [Color(hex: "1E1533"), Color(hex: "150F25")],
                    hedef: AnyView(KariyerKocuView()),
                    boyut: .medium
                )
                bentoKart(
                    baslik: "Klişe İK\nRehberi",
                    altyazi: "15 soru hazırlık",
                    ikon: "face.smiling.inverse",
                    renk: Color(hex: "E94560"),
                    gradientColors: [Color(hex: "FCE7F3"), Color(hex: "FBCFE8")],
                    darkGradient: [Color(hex: "2D1520"), Color(hex: "1F0F18")],
                    hedef: AnyView(KliseIKView()),
                    boyut: .medium
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: ─ MAAŞ & BORDRO Bento Grid ────────────────────────
    private var bentoMaasGrid: some View {
        VStack(spacing: 10) {
            bolumBaslik("MAAŞ & BORDRO", ikon: "turkishlirasign.circle.fill", renk: Color(hex: "10B981"))

            // 2x2 grid
            HStack(spacing: 10) {
                bentoKart(
                    baslik: "Bordro\nAnalizi",
                    altyazi: "SGK · vergi · net",
                    ikon: "chart.pie.fill",
                    renk: Color(hex: "3B82F6"),
                    gradientColors: [Color(hex: "DBEAFE"), Color(hex: "BFDBFE")],
                    darkGradient: [Color(hex: "0F1A2E"), Color(hex: "0A1220")],
                    hedef: AnyView(BrutNetView()),
                    boyut: .medium
                )
                bentoKart(
                    baslik: "Zam\nHesapla",
                    altyazi: "Net zam etkisi",
                    ikon: "arrow.up.right.circle.fill",
                    renk: Color(hex: "10B981"),
                    gradientColors: [Color(hex: "D1FAE5"), Color(hex: "A7F3D0")],
                    darkGradient: [Color(hex: "0F2E1A"), Color(hex: "0A2012")],
                    hedef: AnyView(ZamHesaplayiciView()),
                    boyut: .medium
                )
            }
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                bentoKart(
                    baslik: "Kıdem &\nİhbar",
                    altyazi: "2026 tavanı",
                    ikon: "briefcase.fill",
                    renk: Color(hex: "F59E0B"),
                    gradientColors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A")],
                    darkGradient: [Color(hex: "2E2A0F"), Color(hex: "201D0A")],
                    hedef: AnyView(KidemIhbarView()),
                    boyut: .medium
                )
                bentoKart(
                    baslik: "Reel Maaş\nAnalizi",
                    altyazi: "Enflasyon etkisi",
                    ikon: "chart.line.uptrend.xyaxis",
                    renk: Color(hex: "A78BFA"),
                    gradientColors: [Color(hex: "EDE9FE"), Color(hex: "C4B5FD")],
                    darkGradient: [Color(hex: "1C152E"), Color(hex: "140F20")],
                    hedef: AnyView(RealMaasKaybiView()),
                    boyut: .medium
                )
            }
            .padding(.horizontal, 16)

            bentoKart(
                baslik: "Yan Hak\nHesapla",
                altyazi: "Yıllık parasal karşılık",
                ikon: "gift.fill",
                renk: Color(hex: "14B8A6"),
                gradientColors: [Color(hex: "CCFBF1"), Color(hex: "99F6E4")],
                darkGradient: [Color(hex: "102A2A"), Color(hex: "0A1D1D")],
                hedef: AnyView(YanHakHesaplayiciView()),
                boyut: .wide
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: ─ Bento Kart Bileşeni ──────────────────────────────
    private enum BentoSize {
        case medium // Yarım genişlik
        case wide   // Tam genişlik
    }

    @ViewBuilder
    private func bentoKart(
        baslik: String, altyazi: String,
        ikon: String, renk: Color,
        gradientColors: [Color], darkGradient: [Color],
        hedef: AnyView, boyut: BentoSize
    ) -> some View {
        let isWide = boyut == .wide
        let kartH: CGFloat = isWide ? 90 : 140

        NavigationLink(destination: hedef.environmentObject(appTheme)) {
            ZStack(alignment: isWide ? .leading : .topLeading) {
                // Arka plan
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: appTheme.isLight ? gradientColors : darkGradient,
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: kartH)

                // Dekoratif büyük ikon (metnin arkasında; UIScreen yerine kart genişliği)
                GeometryReader { geo in
                    let w = max(geo.size.width, 1)
                    Image(systemName: ikon)
                        .font(.system(size: isWide ? 60 : 50, weight: .black))
                        .foregroundColor(renk.opacity(appTheme.isLight ? 0.08 : 0.10))
                        .offset(
                            x: isWide ? w * 0.50 : 70,
                            y: isWide ? 10 : 50
                        )
                }
                .frame(height: kartH)
                .allowsHitTesting(false)

                // İçerik
                VStack(alignment: .leading, spacing: isWide ? 6 : 10) {
                    // İkon badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(renk.opacity(appTheme.isLight ? 0.15 : 0.25))
                            .frame(width: 36, height: 36)
                        Image(systemName: ikon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(renk)
                    }

                    if isWide {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(baslik)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(appTheme.textPrimary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .allowsTightening(true)
                                Text(altyazi)
                                    .font(.system(size: 11))
                                    .foregroundColor(appTheme.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(renk.opacity(0.5))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(baslik)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(appTheme.textPrimary)
                                .lineSpacing(2)
                            Text(altyazi)
                                .font(.system(size: 10))
                                .foregroundColor(appTheme.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        appTheme.isLight
                            ? renk.opacity(0.12)
                            : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(color: renk.opacity(appTheme.isLight ? 0.10 : 0.05), radius: 12, y: 4)
        }
        .buttonStyle(PressButtonStyle())
    }
}

// MARK: ─ Dashboard Animasyon yardımcısı ───────────────────────
private extension View {
    func dAnim(_ gorundu: Bool, delay: Double) -> some View {
        self
            .opacity(gorundu ? 1 : 0)
            .offset(y: gorundu ? 0 : 16)
            .animation(.spring(response: 0.5).delay(delay), value: gorundu)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: ARAÇLAR LİSTESİ
// MARK: ═══════════════════════════════════════════════════════════
struct AraclarListView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var dataManager: DataManager

    @State private var gorundu = false
    @State private var showKiyaslama = false
    @State private var aramaMetni = ""

    private struct AracKarti: Identifiable {
        let id: String; let baslik: String; let altyazi: String
        let ikon: String; let renk: Color; let tip: Tip
        enum Tip { case nav(AnyView); case aksiyon(() -> Void) }
    }
    private struct GrupVerisi: Identifiable {
        var id: String { baslik }
        let baslik: String
        let ikon: String
        let renk: Color
        let araclar: [AracKarti]
    }

    private var gruplar: [GrupVerisi] {
        [
            GrupVerisi(baslik: "Kariyer & Mülakat", ikon: "person.fill.checkmark", renk: Color(hex: "8B5CF6"), araclar: [
                AracKarti(id: "kiyaslama", baslik: "İş Teklifi Kıyasla", altyazi: "Mevcut iş vs. yeni teklif analizi", ikon: "arrow.left.arrow.right.circle.fill", renk: Color(hex: "F7D44C"), tip: .aksiyon({ showKiyaslama = true })),
                AracKarti(id: "mulakat", baslik: "Mülakat Simülasyonu", altyazi: "AI ile gerçek pratik", ikon: "mic.fill", renk: Color(hex: "EF4444"), tip: .nav(AnyView(MulakatGirisView()))),
                AracKarti(id: "koc", baslik: "Kariyer Koçu", altyazi: "AI ile kariyer sohbeti", ikon: "brain.head.profile", renk: Color(hex: "8B5CF6"), tip: .nav(AnyView(KariyerKocuView()))),
                AracKarti(id: "klise", baslik: "Klişe İK Rehberi", altyazi: "15 soruda hazırlık", ikon: "face.smiling.inverse", renk: Color(hex: "E94560"), tip: .nav(AnyView(KliseIKView()))),
            ]),
            GrupVerisi(baslik: "Maaş & Bordro", ikon: "turkishlirasign.circle.fill", renk: Color(hex: "10B981"), araclar: [
                AracKarti(id: "brutnet", baslik: "Bordro Analizi", altyazi: "SGK, vergi, net maaş hesabı", ikon: "doc.text.fill", renk: Color(hex: "0EA5E9"), tip: .nav(AnyView(BrutNetView()))),
                AracKarti(id: "zam", baslik: "Zam Hesaplayıcı", altyazi: "Net zam etkisini gör", ikon: "arrow.up.circle.fill", renk: Color(hex: "10B981"), tip: .nav(AnyView(ZamHesaplayiciView()))),
                AracKarti(id: "kidem", baslik: "Kıdem & İhbar", altyazi: "Tazminat hakkını hesapla", ikon: "briefcase.fill", renk: Color(hex: "8B5CF6"), tip: .nav(AnyView(KidemIhbarView()))),
                AracKarti(id: "reel", baslik: "Reel Maaş Analizi", altyazi: "Enflasyona karşı kayıp/kazanım", ikon: "chart.line.uptrend.xyaxis", renk: Color(hex: "3B82F6"), tip: .nav(AnyView(RealMaasKaybiView()))),
                AracKarti(id: "yanhak", baslik: "Yan Hak Hesaplayıcı", altyazi: "Yan hakların yıllık karşılığı", ikon: "gift.fill", renk: Color(hex: "14B8A6"), tip: .nav(AnyView(YanHakHesaplayiciView()))),
            ]),
            GrupVerisi(baslik: "Belgeler & Arşiv", ikon: "folder.fill", renk: Color(hex: "22C55E"), araclar: [
                AracKarti(id: "cv", baslik: "CV Oluştur", altyazi: "Profesyonel özgeçmiş & PDF", ikon: "person.text.rectangle.fill", renk: Color(hex: "8B5CF6"), tip: .nav(AnyView(OzgecmisAnaView()))),
                AracKarti(id: "kayitlicv", baslik: "Kayıtlı CV'lerim", altyazi: "Kaydedilmiş taslaklar", ikon: "doc.text.magnifyingglass", renk: Color(hex: "22C55E"), tip: .nav(AnyView(OzgecmisAnaView()))),
                AracKarti(id: "teklifler", baslik: "Kayıtlı Teklifler", altyazi: "Analiz arşivi", ikon: "archivebox.fill", renk: Color(hex: "10B981"), tip: .nav(AnyView(TeklifWizardView()))),
            ]),
        ]
    }

    private var filtreliGruplar: [GrupVerisi] {
        guard !aramaMetni.isEmpty else { return gruplar }
        return gruplar.compactMap { g in
            let f = g.araclar.filter {
                $0.baslik.localizedCaseInsensitiveContains(aramaMetni) ||
                $0.altyazi.localizedCaseInsensitiveContains(aramaMetni)
            }
            return f.isEmpty ? nil : GrupVerisi(baslik: g.baslik, ikon: g.ikon, renk: g.renk, araclar: f)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(appTheme.textSecondary)
                    TextField("Araç ara...", text: $aramaMetni)
                        .font(.system(size: 15))
                        .foregroundColor(appTheme.textPrimary)
                    if !aramaMetni.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.25)) { aramaMetni = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(appTheme.textSecondary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(appTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 22)
                .opacity(gorundu ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.05), value: gorundu)

                ForEach(Array(filtreliGruplar.enumerated()), id: \.element.id) { idx, grup in
                    aracGrubu(grup)
                        .padding(.horizontal, 18).padding(.bottom, 22)
                        .opacity(gorundu ? 1 : 0)
                        .offset(y: gorundu ? 0 : 14)
                        .animation(.spring(response: 0.5).delay(0.06 + Double(idx) * 0.06), value: gorundu)
                }
                Color.clear.frame(height: 44)
            }
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("Araçlar")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showKiyaslama) {
            KiyaslamaSecimView().environmentObject(appTheme)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { gorundu = true }
            }
        }
    }

    private func aracGrubu(_ grup: GrupVerisi) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(grup.renk.opacity(0.14)).frame(width: 28, height: 28)
                    Image(systemName: grup.ikon)
                        .font(.system(size: 12, weight: .bold)).foregroundColor(grup.renk)
                }
                Text(grup.baslik.uppercased())
                    .font(.system(size: 11, weight: .black)).foregroundColor(appTheme.textSecondary).tracking(1.4)
                Spacer()
                Text("\(grup.araclar.count) araç")
                    .font(.system(size: 11)).foregroundColor(appTheme.textSecondary.opacity(0.4))
            }
            VStack(spacing: 0) {
                ForEach(Array(grup.araclar.enumerated()), id: \.element.id) { i, kart in
                    aracSatir(kart, isLast: i == grup.araclar.count - 1)
                }
            }
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.32), lineWidth: 1))
            .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
        }
    }

    @ViewBuilder
    private func aracSatir(_ kart: AracKarti, isLast: Bool) -> some View {
        switch kart.tip {
        case .nav(let hedef):
            NavigationLink(destination: hedef.environmentObject(appTheme)) {
                satirIcerik(kart, isLast: isLast)
            }.buttonStyle(.plain)
        case .aksiyon(let fn):
            Button(action: fn) { satirIcerik(kart, isLast: isLast) }.buttonStyle(.plain)
        }
    }

    private func satirIcerik(_ kart: AracKarti, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(kart.renk.opacity(0.13)).frame(width: 44, height: 44)
                    Image(systemName: kart.ikon)
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(kart.renk)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(kart.baslik).font(.system(size: 15, weight: .semibold)).foregroundColor(appTheme.textPrimary)
                    Text(kart.altyazi).font(.system(size: 12)).foregroundColor(appTheme.textSecondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(appTheme.textSecondary.opacity(0.28))
            }
            .padding(.horizontal, 16).padding(.vertical, 15).contentShape(Rectangle())
            if !isLast { Divider().padding(.leading, 74) }
        }
    }
}

// MARK: ─ Paylaşılan Componentler ─────────────────────────────
struct ThemeToggleButton: View {
    @EnvironmentObject var appTheme: AppTheme
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { appTheme.toggle() }
        } label: {
            ZStack {
                Circle()
                    .fill(appTheme.isLight ? Color.white.opacity(0.9) : Color(hex: "1E293B"))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 0.5))
                Image(systemName: appTheme.isLight ? "moon.stars.fill" : "sun.max.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(appTheme.isLight ? Color(hex: "64748B") : Color(hex: "F59E0B"))
            }
        }
        .buttonStyle(PressButtonStyle())
    }
}

// MARK: - AI Kariyer Kocu
struct KocuMesaj: Identifiable, Equatable {
    let id = UUID()
    let rol: Rol
    let icerik: String
    enum Rol { case kullanici, ai, sistem }
}

@MainActor
final class KariyerKocuViewModel: ObservableObject {
    @Published var mesajlar: [KocuMesaj] = [
        KocuMesaj(
            rol: .sistem,
            icerik: "Merhaba! Kariyer kararlarinda sana yardimci olabilirim. Sorunu yaz, birlikte netlestirelim."
        )
    ]
    @Published var inputText = ""
    @Published var yukleniyor = false

    func gonder() async {
        let soru = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !soru.isEmpty, !yukleniyor else { return }
        inputText = ""
        mesajlar.append(KocuMesaj(rol: .kullanici, icerik: soru))
        yukleniyor = true
        defer { yukleniyor = false }

        do {
            let cevap = try await fetchKocuCevap(soru: soru)
            mesajlar.append(KocuMesaj(rol: .ai, icerik: cevap))
        } catch {
            mesajlar.append(KocuMesaj(rol: .ai, icerik: "Baglanti sorunu yasandi. Lutfen tekrar dene."))
        }
    }

    private func fetchKocuCevap(soru: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = OpenAIService.shared.makeRequest(url: url)
        let systemPrompt = """
        Sen Turkiye is piyasasinda deneyimli bir kariyer kocusun.
        Cevaplarin net, kisa ve somut olsun. Turkce yaz.
        """
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": soru],
            ],
            "temperature": 0.7,
            "max_tokens": 600,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return json.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Cevap alinamadi."
    }
}

struct KariyerKocuView: View {
    @EnvironmentObject var appTheme: AppTheme
    @StateObject private var vm = KariyerKocuViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(vm.mesajlar) { mesaj in
                            HStack {
                                if mesaj.rol == .kullanici { Spacer() }
                                Text(mesaj.icerik)
                                    .font(.system(size: 14))
                                    .foregroundColor(mesaj.rol == .kullanici ? .white : appTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(mesaj.rol == .kullanici ? Color(hex: "3B82F6") : appTheme.cardSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                if mesaj.rol != .kullanici { Spacer() }
                            }
                            .id(mesaj.id)
                        }
                        if vm.yukleniyor {
                            ProgressView().padding(.vertical, 6)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: vm.mesajlar.count) { _, _ in
                    if let last = vm.mesajlar.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Kariyer sorunu yaz...", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(appTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button {
                    Task { await vm.gonder() }
                } label: {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color(hex: "8B5CF6"))
                        .clipShape(Circle())
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.yukleniyor)
            }
            .padding(12)
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("Kariyer Kocu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Yan Hak Hesaplayici
private struct YanHakKalemi: Identifiable {
    let id = UUID()
    let baslik: String
    let icon: String
    let renk: Color
    var aktif: Bool = false
    var aylikTutar: Double
}

struct YanHakHesaplayiciView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var kalemler: [YanHakKalemi] = [
        .init(baslik: "Yemek", icon: "fork.knife", renk: Color(hex: "F59E0B"), aylikTutar: 3500),
        .init(baslik: "Saglik", icon: "cross.case.fill", renk: Color(hex: "10B981"), aylikTutar: 7500),
        .init(baslik: "Sirket Araci", icon: "car.fill", renk: Color(hex: "3B82F6"), aylikTutar: 42000),
        .init(baslik: "BES", icon: "banknote.fill", renk: Color(hex: "8B5CF6"), aylikTutar: 2500),
        .init(baslik: "Servis", icon: "bus.fill", renk: Color(hex: "0EA5E9"), aylikTutar: 2000),
        .init(baslik: "Telefon", icon: "iphone", renk: Color(hex: "6366F1"), aylikTutar: 800),
    ]

    private var aylikToplam: Double { kalemler.filter(\.aktif).reduce(0) { $0 + $1.aylikTutar } }
    private var yillikToplam: Double { aylikToplam * 12 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Aylik: \(formatTL(aylikToplam))")
                        .font(.system(size: 16, weight: .bold))
                    Text("Yillik: \(formatTL(yillikToplam))")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "14B8A6"))
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(appTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                ForEach(Array(kalemler.enumerated()), id: \.element.id) { idx, k in
                    VStack(spacing: 8) {
                        HStack {
                            Label(k.baslik, systemImage: k.icon).foregroundColor(appTheme.textPrimary)
                            Spacer()
                            Toggle("", isOn: $kalemler[idx].aktif).labelsHidden()
                        }
                        if k.aktif {
                            TextField("Aylik tutar", value: $kalemler[idx].aylikTutar, format: .number)
                                .keyboardType(.numberPad)
                                .padding(10)
                                .background(k.renk.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(12)
                    .background(appTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(16)
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("Yan Hak Hesaplayici")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatTL(_ d: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "tr_TR")
        return (f.string(from: NSNumber(value: d)) ?? "0") + " ₺"
    }
}
