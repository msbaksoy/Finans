// ================================================================
// KliseIKView.swift
// ================================================================
// Klişe İK Rehberi — 15 soru, 5 kategori, günün sorusu, detay sheet, paylaş
// ================================================================

import SwiftUI
import UIKit

struct KliseIKView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var secilenKategori: KliseKategori? = nil
    @State private var acikSoru: KliseSoru? = nil
    @State private var gorundu = false

    private var gosterilecekSorular: [KliseSoru] {
        guard let kat = secilenKategori else { return KliseIKSorulari.tumSorular }
        return KliseIKSorulari.tumSorular.filter { $0.kategori == kat }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                hero

                VStack(spacing: 16) {
                    gunSorusu
                        .opacity(gorundu ? 1 : 0)
                        .offset(y: gorundu ? 0 : 14)
                        .animation(.spring(response: 0.5).delay(0.08), value: gorundu)

                    kategoriFiltre
                        .opacity(gorundu ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.14), value: gorundu)

                    LazyVStack(spacing: 10) {
                        ForEach(Array(gosterilecekSorular.enumerated()), id: \.element.id) { i, soru in
                            soruKarti(soru, index: i)
                                .opacity(gorundu ? 1 : 0)
                                .offset(y: gorundu ? 0 : 14)
                                .animation(.spring(response: 0.5).delay(0.20 + Double(i) * 0.03), value: gorundu)
                        }
                    }
                    Color.clear.frame(height: 36)
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 20)
            }
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("Klişe İK Rehberi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $acikSoru) { soru in
            SoruDetaySheet(soru: soru).environmentObject(appTheme)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { gorundu = true }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: DS.heroH)

            Circle()
                .fill(Color(hex: "E94560").opacity(0.15))
                .frame(width: 180).blur(radius: 35)
                .offset(x: UIScreen.main.bounds.width * 0.56, y: -20)

            Text("😅")
                .font(.system(size: 100))
                .opacity(0.10)
                .offset(x: UIScreen.main.bounds.width * 0.44, y: 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("İK'nın size söylemediği şeyler")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.50))
                    Spacer()
                    Text("\(KliseIKSorulari.tumSorular.count) soru")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "E94560"))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(hex: "E94560").opacity(0.15))
                        .clipShape(Capsule())
                        .padding(.trailing, DS.lg)
                }

                Text("Klişe İK\nRehberi")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(1)

                Text("Gerçek cevapları öğren, doğru sorular sor")
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

    private var gunSorusu: some View {
        let soru = KliseIKSorulari.gunSorusu
        return Button { acikSoru = soru } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "E94560").opacity(0.85), Color(hex: "C62A47")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120).blur(radius: 25)
                    .offset(x: UIScreen.main.bounds.width * 0.5, y: -20)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.8))
                        Text("GÜNÜN SORUSU")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.5)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text(soru.soru)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Cevabı gör")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(DS.base)
            }
        }
        .buttonStyle(PressButtonStyle())
    }

    private var kategoriFiltre: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Color.clear.frame(width: 2)
                let hepsiSec = secilenKategori == nil
                Button {
                    withAnimation(.spring(response: 0.25)) { secilenKategori = nil }
                } label: {
                    Text("Tümü")
                        .font(.system(size: 13, weight: hepsiSec ? .bold : .medium))
                        .foregroundColor(hepsiSec ? .white : appTheme.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(hepsiSec ? Color(hex: "E94560") : (appTheme.isLight ? Color(white: 0.95) : Color.white.opacity(0.07)))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(hepsiSec ? Color(hex: "E94560").opacity(0.5) : Color.clear, lineWidth: 1.5))
                        .shadow(color: hepsiSec ? Color(hex: "E94560").opacity(0.3) : .clear, radius: 5, y: 2)
                }
                .buttonStyle(PressButtonStyle())

                ForEach(KliseKategori.allCases, id: \.self) { kat in
                    let sec = secilenKategori == kat
                    Button {
                        withAnimation(.spring(response: 0.25)) { secilenKategori = kat }
                    } label: {
                        Text(kat.rawValue)
                            .font(.system(size: 13, weight: sec ? .bold : .medium))
                            .foregroundColor(sec ? .white : appTheme.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(sec ? Color(hex: "E94560") : (appTheme.isLight ? Color(white: 0.95) : Color.white.opacity(0.07)))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(sec ? Color(hex: "E94560").opacity(0.5) : Color.clear, lineWidth: 1.5))
                            .shadow(color: sec ? Color(hex: "E94560").opacity(0.3) : .clear, radius: 5, y: 2)
                    }
                    .buttonStyle(PressButtonStyle())
                }
                Color.clear.frame(width: 2)
            }
        }
    }

    private func soruKarti(_ soru: KliseSoru, index: Int) -> some View {
        Button { acikSoru = soru } label: {
            HStack(spacing: 12) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "E94560"))
                    .frame(width: 26, height: 26)
                    .background(Color(hex: "E94560").opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(soru.soru)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(soru.kategori.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary.opacity(0.35))
            }
            .padding(.horizontal, DS.md)
            .padding(.vertical, 13)
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: 6, y: 2)
        }
        .buttonStyle(PressButtonStyle())
    }
}

// MARK: - Soru Detay Sheet (kart görseli ile paylaşım)
struct SoruDetaySheet: View {
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    let soru: KliseSoru

    @State private var secilenTab = 0
    @State private var paylasimGoster = false
    @State private var kartGorsel: UIImage? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    soruBanner
                    icerikAlan
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    Color.clear.frame(height: 40)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if kartGorsel == nil {
                            kartGorsel = renderKartGorsel()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            paylasimGoster = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(appTheme.primaryAccent)
                    }
                }
            }
            .sheet(isPresented: $paylasimGoster) {
                if let gorsel = kartGorsel {
                    GoselPaylasSheet(gorsel: gorsel)
                }
            }
            .task {
                kartGorsel = renderKartGorsel()
            }
        }
        .presentationDetents([.large])
    }

    // MARK: Banner
    private var soruBanner: some View {
        let renk = Color(hex: soru.kategori.renk)
        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [renk.opacity(0.8), renk.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(minHeight: 160)

            Text(espriEmoji(soru.espriSeviyesi))
                .font(.system(size: 80))
                .opacity(0.15)
                .offset(x: 270, y: 0)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: soru.kategori.ikon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(soru.kategori.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.5)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<soru.espriSeviyesi, id: \.self) { _ in
                            Text(espriEmoji(1))
                                .font(.system(size: 14))
                        }
                    }
                }
                .foregroundColor(.white.opacity(0.8))

                Text("\"\(soru.soru)\"")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(20)
        }
    }

    // MARK: İçerik
    private var icerikAlan: some View {
        VStack(spacing: 16) {
            bilgiKutusu(
                baslik: "İK Aslında Ne Düşünüyor?",
                ikon: "text.bubble.fill",
                renkHex: "EF4444",
                icerik: soru.gizliAnlam,
                italic: true
            )

            bilgiKutusu(
                baslik: "Nasıl Cevap Vermeli?",
                ikon: "checkmark.seal.fill",
                renkHex: "10B981",
                icerik: soru.profesyonelCevap,
                italic: false
            )

            bilgiKutusu(
                baslik: "Bunu Asla Yapma",
                ikon: "xmark.circle.fill",
                renkHex: "F59E0B",
                icerik: soru.yapilmamasıGereken,
                italic: false
            )

            if let bonus = soru.bonusIpucu {
                HStack(alignment: .top, spacing: 12) {
                    Text("💡")
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bonus İpucu")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                        Text(bonus)
                            .font(.system(size: 13))
                            .foregroundColor(appTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(Color(hex: "8B5CF6").opacity(0.07))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1))
            }
        }
    }

    private func bilgiKutusu(
        baslik: String,
        ikon: String,
        renkHex: String,
        icerik: String,
        italic: Bool
    ) -> some View {
        let renk = Color(hex: renkHex)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: ikon)
                    .font(.system(size: 14))
                    .foregroundColor(renk)
                Text(baslik)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(renk)
            }
            Text(icerik)
                .font(italic
                      ? .system(size: 14).italic()
                      : .system(size: 14))
                .foregroundColor(appTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(renk.opacity(0.07))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(renk.opacity(0.2), lineWidth: 1))
    }

    private func renderKartGorsel() -> UIImage? {
        guard #available(iOS 16.0, *) else { return nil }

        let renderer = ImageRenderer(
            content: paylasimKartiView
                .frame(width: 390)
                .background(Color(hex: "0B1120"))
        )
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private var paylasimKartiView: some View {
        let renk = Color(hex: soru.kategori.renk)

        return VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [renk.opacity(0.9), renk.opacity(0.5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: soru.kategori.ikon)
                            .font(.system(size: 11, weight: .semibold))
                        Text("KLİŞE İK SORUSU")
                            .font(.system(size: 9, weight: .black))
                            .tracking(2)
                        Spacer()
                        Text("İK Pusula")
                            .font(.system(size: 9, weight: .medium))
                            .opacity(0.6)
                    }
                    .foregroundColor(.white.opacity(0.8))

                    Text("\"\(soru.soru)\"")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                        .lineLimit(3)
                }
                .padding(18)
            }

            VStack(spacing: 14) {
                kartBolumu(
                    ikon: "🧠",
                    baslik: "İK Aslında Ne Düşünüyor?",
                    icerik: soru.gizliAnlam,
                    renkHex: "EF4444"
                )

                kartBolumu(
                    ikon: "✅",
                    baslik: "Nasıl Cevaplanmalı?",
                    icerik: soru.profesyonelCevap,
                    renkHex: "10B981"
                )

                kartBolumu(
                    ikon: "⚠️",
                    baslik: "Bunu Asla Yapma",
                    icerik: soru.yapilmamasıGereken,
                    renkHex: "F59E0B"
                )
            }
            .padding(16)
            .background(Color(hex: "0F1628"))

            HStack {
                Image(systemName: "dial.medium.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "F7D44C"))
                Text("İK Pusula — Klişe İK Rehberi")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
                Text(soru.kategori.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(renk.opacity(0.7))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(hex: "080D18"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(16)
    }

    private func kartBolumu(ikon: String, baslik: String, icerik: String, renkHex: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(ikon)
                    .font(.system(size: 12))
                Text(baslik)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: renkHex))
            }
            Text(icerik)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.80))
                .lineSpacing(3)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: renkHex).opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: renkHex).opacity(0.15), lineWidth: 0.5)
        )
    }

    private func espriEmoji(_ seviye: Int) -> String {
        switch seviye {
        case 1: return "😏"
        case 2: return "😅"
        case 3: return "🤯"
        default: return "🎯"
        }
    }
}
