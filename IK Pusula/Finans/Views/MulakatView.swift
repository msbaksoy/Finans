// ================================================================
// MulakatView.swift — MÜLAKAT SİMÜLASYON UI
// ================================================================
// Giriş + Soru/Simülasyon + Sonuç ekranları (3 mod)
// ================================================================

import SwiftUI
import UIKit

// MARK: - Giriş Ekranı (Mod & Pozisyon Seçimi)
struct MulakatGirisView: View {
    @EnvironmentObject var appTheme: AppTheme
    @StateObject private var vm = MulakatViewModel()
    @State private var baslatiliyor = false
    @FocusState private var odak: Bool
    @AppStorage("aiConsentAccepted") private var aiConsentAccepted = false
    @State private var showAIConsentSheet = false
    @State private var gorundu = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero

                        VStack(spacing: 18) {
                            pozisyonBlogu
                            modSecimi
                            Color.clear.frame(height: 88)
                        }
                        .padding(.horizontal, DS.hPad)
                        .padding(.top, DS.xl)
                        .opacity(gorundu ? 1 : 0)
                        .offset(y: gorundu ? 0 : 14)
                        .animation(.spring(response: 0.5).delay(0.08), value: gorundu)
                    }
                }
                .background(appTheme.backgroundMain.ignoresSafeArea())

                stickyBaslatButon
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $baslatiliyor) {
                MulakatOturumView(vm: vm)
                    .environmentObject(appTheme)
            }
            .sheet(isPresented: $showAIConsentSheet) {
                AIVerisiBilgilendirmeView {
                    aiConsentAccepted = true
                    showAIConsentSheet = false
                    baslatiliyor = true
                    Task { await vm.oturumuBaslat() }
                } onCancel: {
                    showAIConsentSheet = false
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { gorundu = true }
                }
            }
        }
    }

    // MARK: Hero
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: DS.heroH)

            Circle()
                .fill(Color(hex: "0EA5E9").opacity(0.18))
                .frame(width: 180)
                .blur(radius: 36)
                .offset(x: UIScreen.main.bounds.width * 0.56, y: -20)

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 110, weight: .black))
                .foregroundColor(.white.opacity(0.035))
                .offset(x: UIScreen.main.bounds.width * 0.44, y: 10)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles").font(.system(size: 9, weight: .bold))
                    Text("AI Destekli").font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: "A78BFA"))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(hex: "A78BFA").opacity(0.15))
                .clipShape(Capsule())

                Text("Mülakat\nSimülasyonu")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(1)

                Text("Gerçek sorular · Anlık değerlendirme · PDF rapor")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.horizontal, DS.lg)
            .padding(.bottom, 20)
        }
        .frame(height: DS.heroH)
        .opacity(gorundu ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: gorundu)
    }

    // MARK: Pozisyon Bloğu
    private var pozisyonBlogu: some View {
        VStack(alignment: .leading, spacing: 14) {
            IKSectionHeader(title: "Pozisyon Bilgileri", icon: "briefcase.fill",
                            color: Color(hex: "0EA5E9"))

            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "0EA5E9"))
                        Text("Başvurulan Pozisyon")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(appTheme.textSecondary)
                    }
                    TextField("Örn: iOS Developer, Pazarlama Müdürü…", text: $vm.pozisyon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(appTheme.textPrimary)
                        .focused($odak)
                        .padding(.horizontal, DS.md)
                        .padding(.vertical, 13)
                        .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                            .stroke(Color(hex: "0EA5E9").opacity(0.25), lineWidth: 1.2))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "0EA5E9"))
                        Text("Hedef Şirket (isteğe bağlı)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(appTheme.textSecondary)
                    }
                    TextField("Örn: Garanti BBVA", text: $vm.hedefSirket)
                        .font(.system(size: 15))
                        .foregroundColor(appTheme.textPrimary)
                        .padding(.horizontal, DS.md)
                        .padding(.vertical, 13)
                        .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                            .stroke(Color(hex: "0EA5E9").opacity(0.20), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "0EA5E9"))
                        Text("Sektör")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(appTheme.textSecondary)
                    }
                    Picker("", selection: $vm.sektor) {
                        ForEach(vm.sektorler, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "0EA5E9"))
                    .padding(.horizontal, DS.md)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .stroke(Color(hex: "0EA5E9").opacity(0.20), lineWidth: 1))
                }
            }
        }
        .padding(DS.base)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    // MARK: Mod Seçimi
    private var modSecimi: some View {
        VStack(alignment: .leading, spacing: 12) {
            IKSectionHeader(title: "Mülakat Modu", icon: "list.bullet.clipboard.fill",
                            color: Color(hex: "8B5CF6"))

            VStack(spacing: 10) {
                ForEach(MulakatModu.allCases, id: \.self) { mod in
                    modKarti(mod)
                }
            }
        }
        .padding(DS.base)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private func modKarti(_ mod: MulakatModu) -> some View {
        let sec = vm.secilenMod == mod
        let renk = Color(hex: mod.renk)
        return Button {
            withAnimation(.spring(response: 0.25)) { vm.secilenMod = mod }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(sec ? renk : renk.opacity(0.10))
                        .frame(width: 44, height: 44)
                    Image(systemName: mod.ikon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(sec ? .white : renk)
                }
                .shadow(color: sec ? renk.opacity(0.3) : .clear, radius: 6, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(mod.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(appTheme.textPrimary)
                        Text(mod.zorluk)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(sec ? renk : appTheme.textSecondary)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background((sec ? renk : Color.gray).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text(mod.aciklama)
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if sec {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(renk)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18))
                        .foregroundColor(appTheme.textSecondary.opacity(0.3))
                }
            }
            .padding(.horizontal, DS.md)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                    .fill(sec ? renk.opacity(0.07) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                            .stroke(sec ? renk.opacity(0.40) : appTheme.cardStroke.opacity(0.25),
                                    lineWidth: sec ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(PressButtonStyle())
    }

    // MARK: Sticky Başlat — tek satır
    private var stickyBaslatButon: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [appTheme.backgroundMain.opacity(0), appTheme.backgroundMain],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                odak = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                if aiConsentAccepted {
                    baslatiliyor = true
                    Task { await vm.oturumuBaslat() }
                } else {
                    showAIConsentSheet = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Başlat")
                        .font(.system(size: DS.btnFont, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    Text(vm.secilenMod.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.70))
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .frame(height: DS.btnH)
                .background(
                    LinearGradient(
                        colors: vm.pozisyon.trimmingCharacters(in: .whitespaces).isEmpty
                            ? [Color.gray, Color.gray.opacity(0.85)]
                            : [Color(hex: "0F2027"), Color(hex: "2C5364")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.btnRadius, style: .continuous))
                .shadow(color: Color(hex: "0F2027").opacity(0.4), radius: 14, y: 6)
                .opacity(vm.pozisyon.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1.0)
            }
            .disabled(vm.pozisyon.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(PressButtonStyle())
            .padding(.horizontal, DS.lg)
            .padding(.bottom, 30)
            .background(appTheme.backgroundMain)
        }
    }
}

// MARK: - Oturum Ekranı (Sorular + Simülasyon)
struct MulakatOturumView: View {
    @EnvironmentObject var appTheme: AppTheme
    @ObservedObject var vm: MulakatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sonucGoster = false
    @FocusState private var yanitOdak: Bool

    var body: some View {
        Group {
            switch vm.asamaState {
            case .giris:
                yukleniyorEkrani
            case .sorular:
                soruEkrani
            case .simulasyon:
                simulasyonEkrani
            case .sonuc:
                MulakatSonucView(vm: vm, onKapat: { dismiss() })
                    .environmentObject(appTheme)
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { vm.hata != nil },
            set: { if !$0 { vm.hata = nil } }
        )) {
            Button("Tamam") { vm.hata = nil }
        } message: {
            Text(vm.hata ?? "")
        }
    }

    private var yukleniyorEkrani: some View {
        ZStack {
            appTheme.backgroundMain.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(Color(hex: "0EA5E9"))
                Text("Sorular hazırlanıyor…")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(appTheme.textSecondary)
                Text("AI pozisyona özel sorular üretiyor")
                    .font(.system(size: 13))
                    .foregroundColor(appTheme.textSecondary.opacity(0.6))
            }
        }
    }

    private var soruEkrani: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                appTheme.backgroundMain.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        soruHeader
                        if let soru = vm.mevcutSoru {
                            soruKarti(soru)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            yanitAlani
                                .padding(.horizontal, 20)
                                .padding(.top, 14)
                            if vm.mevcutSoruIndex > 0 {
                                oncekiDegerlendirme
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                            }
                        }
                        Color.clear.frame(height: 120)
                    }
                }
                stickyGonderButon
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Çık") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(vm.gecenSureMetni)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(appTheme.textSecondary)
                }
            }
        }
    }

    private var soruHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<vm.toplamSoru, id: \.self) { i in
                    Capsule()
                        .fill(i < vm.mevcutSoruIndex
                              ? Color(hex: "10B981")
                              : (i == vm.mevcutSoruIndex
                                 ? Color(hex: vm.secilenMod.renk)
                                 : Color.gray.opacity(0.15)))
                        .frame(height: 5)
                        .animation(.spring(response: 0.4), value: vm.mevcutSoruIndex)
                }
            }
            .padding(.horizontal, 20)

            HStack {
                Text("Soru \(vm.mevcutSoruIndex + 1) / \(vm.toplamSoru)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
                Spacer()
                if let soru = vm.mevcutSoru {
                    HStack(spacing: 5) {
                        Image(systemName: soru.kategori.ikon)
                            .font(.system(size: 11))
                        Text(soru.kategori.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: vm.secilenMod.renk))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(hex: vm.secilenMod.renk).opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private func soruKarti(_ soru: MulakatSoru) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: vm.secilenMod.renk).opacity(0.85),
                                 Color(hex: vm.secilenMod.renk).opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            Text("\(soru.siraNo)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.06))
                .offset(x: 200, y: 20)

            VStack(alignment: .leading, spacing: 12) {
                Text(soru.soru)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                if vm.secilenMod == .senaryo {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 11))
                        Text("STAR yöntemiyle cevapla: Durum → Görev → Eylem → Sonuç")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .frame(minHeight: 120)
        .shadow(color: Color(hex: vm.secilenMod.renk).opacity(0.3), radius: 16, y: 6)
    }

    private var yanitAlani: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cevabın")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(appTheme.textSecondary)
            TextEditor(text: $vm.kullaniciYaniti)
                .focused($yanitOdak)
                .font(.system(size: 15))
                .foregroundColor(appTheme.textPrimary)
                .frame(minHeight: 130)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(appTheme.formInputBackground.opacity(0.5))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(yanitOdak
                            ? Color(hex: vm.secilenMod.renk).opacity(0.5)
                            : appTheme.cardStroke.opacity(0.3), lineWidth: 1.5))
                .animation(.easeInOut(duration: 0.15), value: yanitOdak)
        }
    }

    @ViewBuilder
    private var oncekiDegerlendirme: some View {
        let oncekiSoru = vm.sorular[vm.mevcutSoruIndex - 1]
        if let puan = oncekiSoru.aiPuani {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "10B981"))
                        .font(.subheadline)
                    Text("Önceki sorunun değerlendirmesi")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f", puan) + "/10")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: puan.mulakatPuanRengi))
                }

                if !oncekiSoru.aiYorum.isEmpty {
                    Text(oncekiSoru.aiYorum)
                        .font(.system(size: 13))
                        .foregroundColor(appTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !oncekiSoru.aiOneri.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(oncekiSoru.aiOneri)
                            .font(.system(size: 12))
                            .foregroundColor(appTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(Color(hex: "F59E0B").opacity(0.08))
                    .cornerRadius(10)
                }
            }
            .padding(14)
            .background(appTheme.cardSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "10B981").opacity(0.2), lineWidth: 1))
        }
    }

    private var stickyGonderButon: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [appTheme.backgroundMain.opacity(0), appTheme.backgroundMain],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                yanitOdak = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await vm.yanitVeDevam() }
            } label: {
                HStack(spacing: 10) {
                    if vm.yukleniyor {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text("Değerlendiriliyor…")
                            .font(.system(size: 15, weight: .bold))
                    } else {
                        Text(vm.mevcutSoruIndex == vm.toplamSoru - 1 ? "Son Soru · Sonuçları Gör" : "Cevapla & Devam Et")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: vm.mevcutSoruIndex == vm.toplamSoru - 1 ? "flag.fill" : "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    vm.kullaniciYaniti.trimmingCharacters(in: .whitespaces).isEmpty || vm.yukleniyor
                    ? Color.gray
                    : Color(hex: vm.secilenMod.renk)
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: vm.secilenMod.renk).opacity(0.35), radius: 10, y: 4)
            }
            .disabled(vm.kullaniciYaniti.trimmingCharacters(in: .whitespaces).isEmpty || vm.yukleniyor)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .background(appTheme.backgroundMain)
        }
    }

    // MARK: Simülasyon Ekranı (Mod 3)
    private var simulasyonEkrani: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            Color.clear.frame(height: 8)
                            ForEach(vm.konusmaMesajlari) { mesaj in
                                mesajBalonu(mesaj)
                                    .id(mesaj.id)
                            }
                            if vm.yukleniyor {
                                yaziyor
                            }
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: vm.konusmaMesajlari.count) { _, _ in
                        if let last = vm.konusmaMesajlari.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                simulasyonGiris
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Mülakat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Çık") { dismiss() }
                        .foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(vm.gecenSureMetni)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(appTheme.textSecondary)
                }
            }
        }
    }

    private func mesajBalonu(_ mesaj: KonusmaMesaji) -> some View {
        let isAI = mesaj.rol == .ai
        return HStack(alignment: .bottom, spacing: 10) {
            if isAI {
                ZStack {
                    Circle()
                        .fill(Color(hex: "EF4444").opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "EF4444"))
                }
            } else {
                Spacer()
            }

            Text(mesaj.icerik)
                .font(.system(size: 15))
                .foregroundColor(isAI ? appTheme.textPrimary : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isAI
                             ? appTheme.cardSurface
                             : Color(hex: "EF4444"))
                .cornerRadius(18)
                .cornerRadius(isAI ? 4 : 18, corners: isAI ? .topLeft : .topRight)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: isAI ? .leading : .trailing)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isAI ? appTheme.cardStroke.opacity(0.3) : Color.clear, lineWidth: 1)
                )

            if !isAI {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            } else {
                Spacer()
            }
        }
    }

    private var yaziyor: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: "EF4444").opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "EF4444"))
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(appTheme.textSecondary)
                        .frame(width: 6, height: 6)
                        .opacity(0.5)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(appTheme.cardSurface)
            .cornerRadius(18)
            Spacer()
        }
    }

    @FocusState private var simOdak: Bool
    private var simulasyonGiris: some View {
        HStack(spacing: 10) {
            TextField("Cevabın…", text: $vm.kullaniciYaniti, axis: .vertical)
                .focused($simOdak)
                .font(.system(size: 15))
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(appTheme.formInputBackground.opacity(0.5))
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22)
                    .stroke(appTheme.cardStroke.opacity(0.3), lineWidth: 1))

            Button {
                simOdak = false
                Task { await vm.simulasyonMesajiGonder() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(
                        vm.kullaniciYaniti.trimmingCharacters(in: .whitespaces).isEmpty || vm.yukleniyor
                        ? Color.gray.opacity(0.4)
                        : Color(hex: "EF4444")
                    )
            }
            .disabled(vm.kullaniciYaniti.trimmingCharacters(in: .whitespaces).isEmpty || vm.yukleniyor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(appTheme.backgroundMain)
        .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
    }
}

// MARK: - RoundedCorner helper (UIKit corners)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - AI Veri Bilgilendirme Sheet'i
struct AIVerisiBilgilendirmeView: View {
    var onAccept: () -> Void
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    anaMetin
                    anonimMetin
                    ucuncuTarafMetin
                    sorumlulukMetni
                }
                .padding(20)
            }
            .navigationTitle("Yapay Zekâ Bilgilendirmesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") {
                        onCancel?()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                altButonlar
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.purple)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Destekli Özellikler")
                    .font(.headline)
                Text("Verilerinin nasıl işlendiğini bilmen önemli.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var anaMetin: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bu uygulamadaki bazı özellikler (kariyer kıyaslama analizi, mülakat simülasyonu, raporlar vb.), girdiğin bilgileri yapay zekâ modelleriyle analiz eder.")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text("Bu analizler için; pozisyon, sektör, maaş/teklif detayları, özgeçmiş bilgileri, mülakat cevapları gibi metinler, üçüncü taraf yapay zekâ hizmetlerine (örneğin OpenAI) gönderilebilir.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    private var anonimMetin: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Anonimleştirme ve sorumluluk")
                .font(.subheadline.weight(.semibold))
            Text("Uygulama, mümkün olduğu ölçüde verileri isim, iletişim bilgisi gibi doğrudan tanımlayıcılardan arındırmaya çalışır. Yine de metin alanlarına manuel olarak yazdığın kişi/şirket isimleri ve diğer kişisel bilgiler, yapay zekâ sağlayıcısına iletilebilir.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    private var ucuncuTarafMetin: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Üçüncü taraf hizmetler")
                .font(.subheadline.weight(.semibold))
            Text("Bu özellikler, OpenAI gibi üçüncü taraf yapay zekâ sağlayıcılarının API’leri üzerinden çalışır. Bu sağlayıcılar, kendi gizlilik politikaları ve kullanım şartları çerçevesinde verileri işleyebilir.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    private var sorumlulukMetni: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Devam ederek neyi kabul etmiş oluyorsun?")
                .font(.subheadline.weight(.semibold))
            Text("Bu bilgilendirmeyi onaylayarak, yukarıda açıklanan kapsamda verilerinin anonimleştirilmiş şekilde yapay zekâ hizmetleriyle paylaşılmasına izin vermiş olursun. Dilediğin zaman, metin alanlarına yazdığın bilgileri daha az kişisel detay içerecek şekilde daraltarak paylaşım kapsamını kendin de sınırlayabilirsin.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    private var altButonlar: some View {
        VStack(spacing: 10) {
            Button {
                onAccept()
            } label: {
                Text("Kabul Ediyorum ve Devam Et")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            
            Button {
                onCancel?()
            } label: {
                Text("Vazgeç")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Sonuç Ekranı
struct MulakatSonucView: View {
    @EnvironmentObject var appTheme: AppTheme
    @ObservedObject var vm: MulakatViewModel
    var onKapat: () -> Void

    @State private var pdfVerisi: Data? = nil
    @State private var pdfURL: URL? = nil
    @State private var pdfHazırlanıyor = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let oturum = vm.sonucOturumu {
                        puanHero(oturum)

                        if !oturum.aiGenelYorum.isEmpty {
                            genelYorumKarti(oturum.aiGenelYorum)
                        }

                        HStack(alignment: .top, spacing: 12) {
                            listeKart(
                                baslik: "Güçlü Yönler",
                                ikon: "checkmark.seal.fill",
                                renk: "10B981",
                                maddeler: oturum.aiGucluYonler
                            )
                            listeKart(
                                baslik: "Geliştirilecek",
                                ikon: "arrow.up.circle.fill",
                                renk: "F59E0B",
                                maddeler: oturum.aiGelistirilecek
                            )
                        }

                        if vm.secilenMod != .tamSimulasyon {
                            soruDetaylari(oturum)
                        }

                        pdfButon

                        Button {
                            vm.sifirla()
                            onKapat()
                        } label: {
                            Label("Yeni Mülakat Başlat", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(appTheme.primaryAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(appTheme.primaryAccent.opacity(0.1))
                                .cornerRadius(14)
                        }
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Mülakat Sonucu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { onKapat() }
                        .foregroundColor(appTheme.textSecondary)
                }
            }
            .sheet(isPresented: Binding(get: { pdfURL != nil }, set: { if !$0 { pdfURL = nil } })) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func puanHero(_ oturum: MulakatOturumu) -> some View {
        let puan = oturum.toplamPuan
        let puanRenk = Color(hex: puan.mulakatPuanRengi)
        return ZStack {
            LinearGradient(
                colors: [Color(hex: "0F2027"), Color(hex: "203A43")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(24)

            VStack(spacing: 12) {
                Text(oturum.moduEnum.rawValue + " Tamamlandı")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                (Text(String(format: "%.1f", puan))
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(puanRenk)
                 + Text("/10")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.4)))

                Text(puan.mulakatPuanEtiketi)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 20) {
                    statBadge(deger: "\(oturum.sureDakika) dk", etiket: "Süre")
                    statBadge(deger: "\(oturum.sorular.count > 0 ? oturum.sorular.count : vm.konusmaMesajlari.filter { $0.rol == .kullanici }.count)", etiket: "Yanıt")
                    statBadge(deger: oturum.moduEnum.zorluk, etiket: "Zorluk")
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .shadow(color: Color(hex: "0F2027").opacity(0.4), radius: 20, y: 8)
    }

    private func statBadge(deger: String, etiket: String) -> some View {
        VStack(spacing: 4) {
            Text(deger)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(etiket)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }

    private func genelYorumKarti(_ yorum: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.top, 2)
            Text(yorum)
                .font(.system(size: 14))
                .foregroundColor(appTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color(hex: "8B5CF6").opacity(0.07))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1))
    }

    private func listeKart(baslik: String, ikon: String, renk: String, maddeler: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: ikon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: renk))
                Text(baslik)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: renk))
            }
            ForEach(maddeler, id: \.self) { madde in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color(hex: renk).opacity(0.6))
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    Text(madde)
                        .font(.system(size: 12))
                        .foregroundColor(appTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: renk).opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: renk).opacity(0.18), lineWidth: 1))
    }

    private func soruDetaylari(_ oturum: MulakatOturumu) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Soru Bazlı Detaylar")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(appTheme.textPrimary)

            ForEach(oturum.sorular) { soru in
                soruDetayKarti(soru)
            }
        }
    }

    private func soruDetayKarti(_ soru: MulakatSoru) -> some View {
        let puan = soru.aiPuani ?? 0
        let renk = Color(hex: puan.mulakatPuanRengi)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("S\(soru.siraNo):")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                Text(soru.soru)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if let p = soru.aiPuani {
                    Text(String(format: "%.1f", p))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(renk)
                }
            }

            if !soru.aiYorum.isEmpty {
                Text(soru.aiYorum)
                    .font(.system(size: 12))
                    .foregroundColor(appTheme.textSecondary)
            }

            if !soru.aiOneri.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(soru.aiOneri)
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(Color(hex: "F59E0B").opacity(0.07))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(appTheme.cardSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(renk.opacity(0.2), lineWidth: 1))
    }

    private var pdfButon: some View {
        Button {
            pdfHazırlanıyor = true
            Task {
                if let oturum = vm.sonucOturumu {
                    let data = MulakatPdfOlusturucu.olustur(
                        oturum: oturum,
                        konusmaMesajlari: vm.konusmaMesajlari
                    )
                    if let data = data {
                        let url = FileManager.default.temporaryDirectory
                            .appendingPathComponent("Mulakat_Raporu.pdf")
                        try? data.write(to: url)
                        pdfURL = url
                    }
                }
                pdfHazırlanıyor = false
            }
        } label: {
            HStack(spacing: 10) {
                if pdfHazırlanıyor {
                    ProgressView().tint(.white).scaleEffect(0.9)
                    Text("PDF Hazırlanıyor…")
                        .font(.system(size: 15, weight: .bold))
                } else {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("PDF Raporu İndir")
                        .font(.system(size: 15, weight: .bold))
                }
                Spacer()
                if !pdfHazırlanıyor {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1E3A5F"), Color(hex: "2C5364")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "1E3A5F").opacity(0.4), radius: 12, y: 5)
        }
    }
}
