// ================================================================
// OzgecmisAnaView.swift — TAM YENİDEN TASARIM
// ================================================================

import SwiftUI
import PDFKit
import UIKit

// MARK: - Bölüm enum (değişmedi)
enum OzgecmisSection: String, CaseIterable, Identifiable {
    case kisisel, deneyim, egitim, yetenekler
    case diller, sertifikalar, projeler, referanslar, diger, ozet

    var id: String { rawValue }

    var baslik: String {
        switch self {
        case .kisisel:      return "Kişisel Bilgiler"
        case .ozet:         return "Profesyonel Özet"
        case .deneyim:      return "İş Deneyimi"
        case .egitim:       return "Eğitim"
        case .yetenekler:   return "Yetenekler"
        case .diller:       return "Diller"
        case .sertifikalar: return "Sertifikalar"
        case .projeler:     return "Projeler"
        case .referanslar:  return "Referanslar"
        case .diger:        return "Ödüller & Hobiler"
        }
    }
    var altBaslik: String {
        switch self {
        case .kisisel:      return "Ad, iletişim, konum"
        case .ozet:         return "Kariyer özeti veya hedef"
        case .deneyim:      return "Çalışma geçmişi"
        case .egitim:       return "Okul ve dereceler"
        case .yetenekler:   return "Teknik ve kişisel"
        case .diller:       return "Dil ve seviye"
        case .sertifikalar: return "Sertifika ve kurslar"
        case .projeler:     return "Başarılar ve projeler"
        case .referanslar:  return "Referans kişiler"
        case .diger:        return "Ödül, hobi, ek bilgi"
        }
    }
    var sistemIkoni: String {
        switch self {
        case .kisisel:      return "person.fill"
        case .ozet:         return "text.alignleft"
        case .deneyim:      return "briefcase.fill"
        case .egitim:       return "graduationcap.fill"
        case .yetenekler:   return "star.fill"
        case .diller:       return "globe"
        case .sertifikalar: return "checkmark.seal.fill"
        case .projeler:     return "folder.fill"
        case .referanslar:  return "person.2.fill"
        case .diger:        return "sparkles"
        }
    }
    var renk: Color {
        switch self {
        case .kisisel:      return Color(hex: "3B82F6")
        case .ozet:         return Color(hex: "8B5CF6")
        case .deneyim:      return Color(hex: "0EA5E9")
        case .egitim:       return Color(hex: "10B981")
        case .yetenekler:   return Color(hex: "F59E0B")
        case .diller:       return Color(hex: "06B6D4")
        case .sertifikalar: return Color(hex: "EC4899")
        case .projeler:     return Color(hex: "8B5CF6")
        case .referanslar:  return Color(hex: "14B8A6")
        case .diger:        return Color(hex: "F97316")
        }
    }
    var zorunlu: Bool { self == .kisisel || self == .deneyim || self == .egitim }
}

// MARK: - Ana Ekran (üstte yatay tab bar; tek ekranda bölüm formları)
struct OzgecmisAnaView: View {
    @EnvironmentObject var appTheme: AppTheme
    @StateObject private var store = OzgecmisStore()

    @State private var activeSection: OzgecmisSection = .kisisel
    @State private var showPreview        = false
    @State private var showTemizleOnay    = false
    @State private var showKaydetSheet    = false
    @State private var showCVOkuyucu      = false
    @State private var showATSPuanlama    = false
    @State private var kaydetIsim         = ""
    @State private var gorundu            = false

    private var tamamlanan: Int { OzgecmisSection.allCases.filter { isDolu($0) }.count }
    private var toplam: Int     { OzgecmisSection.allCases.count }
    private var oran: Double    { Double(tamamlanan) / Double(toplam) }
    private var isimBos: Bool   { store.draft.kisisel.adSoyad.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Aktif section'ın index'i
    private var activeIndex: Int {
        OzgecmisSection.allCases.firstIndex(of: activeSection) ?? 0
    }
    /// Son bölüm mü?
    private var sonBolumMu: Bool {
        activeSection == OzgecmisSection.allCases.last
    }

    private var sonrakiBolumBasligi: String? {
        let all = OzgecmisSection.allCases
        guard activeIndex + 1 < all.count else { return nil }
        return all[activeIndex + 1].baslik
    }

    var body: some View {
        VStack(spacing: 0) {
            miniHero
                .opacity(gorundu ? 1 : 0)
                .animation(.easeOut(duration: 0.35), value: gorundu)

            sectionTabBar
                .opacity(gorundu ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.1), value: gorundu)

            ZStack {
                formIcerik
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            altBar
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPreview) {
            NavigationStack {
                OzgecmisPreviewView()
                    .environmentObject(appTheme)
                    .environmentObject(store)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showKaydetSheet = true
                    } label: {
                        Label("Taslak Kaydet", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        showPreview = true
                    } label: {
                        Label("Önizle & PDF", systemImage: "doc.richtext")
                    }
                    Button {
                        showCVOkuyucu = true
                    } label: {
                        Label("CV'den Oluştur", systemImage: "doc.badge.plus")
                    }
                    Button {
                        showATSPuanlama = true
                    } label: {
                        Label("CV'mi Puanla", systemImage: "checkmark.shield")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showTemizleOnay = true
                    } label: {
                        Label("Formu Temizle", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(appTheme.primaryAccent)
                }
            }
        }
        .confirmationDialog("Tüm bilgiler silinecek.", isPresented: $showTemizleOnay, titleVisibility: .visible) {
            Button("Temizle", role: .destructive) { store.sifirla() }
            Button("Vazgeç", role: .cancel) {}
        }
        .sheet(isPresented: $showKaydetSheet) { kaydetSheet }
        .sheet(isPresented: $showCVOkuyucu) {
            CVOkuyucuView(taslak: $store.draft)
                .environmentObject(appTheme)
        }
        .sheet(isPresented: $showATSPuanlama) {
            CVATSPuanlamaView()
                .environmentObject(store)
                .environmentObject(appTheme)
        }
        .environmentObject(store)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { gorundu = true }
        }
    }

    // MARK: ─ Mini Hero ────────────────────────────────────────
    private var miniHero: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isimBos ? "Özgeçmişini Oluştur" : store.draft.kisisel.adSoyad)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(appTheme.primaryAccent.opacity(0.12))
                                .frame(height: 5)
                            Capsule()
                                .fill(appTheme.primaryAccent)
                                .frame(width: max(g.size.width * oran, 5), height: 5)
                                .animation(.spring(response: 0.5), value: oran)
                        }
                    }
                    .frame(height: 5)

                    Text("%\(Int(oran * 100))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(appTheme.primaryAccent)
                }
            }

            Spacer()

            Button {
                showCVOkuyucu = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("CV Yükle")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(appTheme.primaryAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(appTheme.primaryAccent.opacity(0.10))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: ─ Yatay Tab Bar ────────────────────────────────────
    private var sectionTabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(OzgecmisSection.allCases) { section in
                        let isActive = activeSection == section
                        let dolu = isDolu(section)

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                activeSection = section
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if dolu {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(isActive ? .white : Color(hex: "10B981"))
                                } else {
                                    Image(systemName: section.sistemIkoni)
                                        .font(.system(size: 10))
                                        .foregroundColor(isActive ? .white : section.renk)
                                }
                                Text(section.baslik)
                                    .font(.system(size: 11, weight: isActive ? .bold : .medium))
                                    .foregroundColor(isActive ? .white : appTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isActive
                                    ? AnyShapeStyle(section.renk)
                                    : AnyShapeStyle(appTheme.cardSurface)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isActive ? Color.clear : appTheme.cardStroke.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .id(section)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: activeSection) { _, newVal in
                withAnimation {
                    proxy.scrollTo(newVal, anchor: .center)
                }
            }
        }
        .background(appTheme.backgroundMain)
    }

    // MARK: ─ Form İçerik ──────────────────────────────────────
    @ViewBuilder
    private var formIcerik: some View {
        Group {
            switch activeSection {
            case .kisisel:      OzgecmisKisiselFormView()
            case .ozet:         OzgecmisOzetFormView()
            case .deneyim:      OzgecmisDeneyimFormView()
            case .egitim:       OzgecmisEgitimFormView()
            case .yetenekler:   OzgecmisYeteneklerFormView()
            case .diller:       OzgecmisDillerFormView()
            case .sertifikalar: OzgecmisSertifikalarFormView()
            case .projeler:     OzgecmisProjelerFormView()
            case .referanslar:  OzgecmisReferanslarFormView()
            case .diger:        OzgecmisDigerFormView()
            }
        }
        .environmentObject(store)
        .environmentObject(appTheme)
        .transition(.opacity)
        .id(activeSection)
    }

    // MARK: ─ Alt Bar ──────────────────────────────────────────
    private var altBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(appTheme.cardStroke.opacity(0.2))
                .frame(height: 0.5)

            HStack(spacing: 12) {
                if activeIndex > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            let allSections = OzgecmisSection.allCases
                            activeSection = allSections[activeIndex - 1]
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(appTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(appTheme.cardSurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(appTheme.cardStroke.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if sonBolumMu {
                        showPreview = true
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            let allSections = OzgecmisSection.allCases
                            if activeIndex + 1 < allSections.count {
                                activeSection = allSections[activeIndex + 1]
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: sonBolumMu ? "doc.richtext.fill" : "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                        Text(sonBolumMu ? "PDF Önizle" : "Kaydet & Devam Et")
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                        Spacer()
                        if !sonBolumMu, let nextTitle = sonrakiBolumBasligi {
                            Text(nextTitle)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Image(systemName: sonBolumMu ? "arrow.up.right.circle.fill" : "chevron.right")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(
                        sonBolumMu
                            ? LinearGradient(colors: [Color(hex: "1E3A5F"), Color(hex: "2D1B69")],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [activeSection.renk, activeSection.renk.opacity(0.80)],
                                             startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: activeSection.renk.opacity(0.30), radius: 10, y: 4)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(PressButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 30)
            .background(appTheme.backgroundMain)
        }
    }

    // MARK: ─ Kaydet Sheet ─────────────────────────────────────
    @ViewBuilder
    private var kaydetSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CV'nize bir isim verin")
                        .font(.headline.bold())
                        .foregroundColor(appTheme.textPrimary)
                    Text("Bu isim Kayıtlı CV'lerim listesinde görünecek.")
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }

                TextField("Örn: İş Başvurusu 2026", text: $kaydetIsim)
                    .font(.body)
                    .padding(14)
                    .background(appTheme.formInputBackground.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(appTheme.primaryAccent.opacity(0.3), lineWidth: 1))
                    .textInputAutocapitalization(.words)

                Spacer()
            }
            .padding(20)
            .background(appTheme.background.ignoresSafeArea())
            .navigationTitle("Kaydet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { kaydetIsim = ""; showKaydetSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        store.kayitliCvEkle(baslik: kaydetIsim)
                        kaydetIsim = ""
                        showKaydetSheet = false
                    }
                    .fontWeight(.bold)
                    .disabled(kaydetIsim.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onDisappear { kaydetIsim = "" }
    }

    // MARK: ─ Yardımcılar ──────────────────────────────────────
    private func isDolu(_ s: OzgecmisSection) -> Bool {
        switch s {
        case .kisisel:      return !store.draft.kisisel.adSoyad.isEmpty
        case .ozet:         return !store.draft.ozet.isEmpty
        case .deneyim:      return !store.draft.isDeneyimleri.isEmpty
        case .egitim:       return !store.draft.egitimler.isEmpty
        case .yetenekler:   return !store.draft.yetenekler.isEmpty
        case .diller:       return !store.draft.diller.isEmpty
        case .sertifikalar: return !store.draft.sertifikalar.isEmpty
        case .projeler:     return !store.draft.projeler.isEmpty
        case .referanslar:  return !store.draft.referanslar.isEmpty
        case .diger:        return !store.draft.oduller.isEmpty || !store.draft.hobiler.isEmpty
        }
    }

}

// MARK: - Section Form Host (basit — push zinciri yok; tab bar kullanılıyor)
struct OzgecmisSectionFormHost: View {
    let section: OzgecmisSection

    var body: some View {
        Group {
            switch section {
            case .kisisel:      OzgecmisKisiselFormView()
            case .ozet:         OzgecmisOzetFormView()
            case .deneyim:      OzgecmisDeneyimFormView()
            case .egitim:       OzgecmisEgitimFormView()
            case .yetenekler:   OzgecmisYeteneklerFormView()
            case .diller:       OzgecmisDillerFormView()
            case .sertifikalar: OzgecmisSertifikalarFormView()
            case .projeler:     OzgecmisProjelerFormView()
            case .referanslar:  OzgecmisReferanslarFormView()
            case .diger:        OzgecmisDigerFormView()
            }
        }
        .navigationTitle(section.baslik)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - CV önizleme (format + renk)
private struct VRenk: Identifiable {
    let id: String
    let isim: String
    let sw: Color
    let ui: UIColor
}

private let ozgecmisOnizlemeRenkleri: [VRenk] = [
    VRenk(id: "navy", isim: "Lacivert", sw: Color(hex: "0D3D73"), ui: UIColor(red: 0.05, green: 0.24, blue: 0.45, alpha: 1)),
    VRenk(id: "teal", isim: "Zümrüt", sw: Color(hex: "0F766E"), ui: UIColor(red: 0.06, green: 0.46, blue: 0.43, alpha: 1)),
    VRenk(id: "slate", isim: "Antrasit", sw: Color(hex: "1E293B"), ui: UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1)),
    VRenk(id: "violet", isim: "Mor", sw: Color(hex: "6D28D9"), ui: UIColor(red: 0.43, green: 0.16, blue: 0.85, alpha: 1)),
    VRenk(id: "crimson", isim: "Bordo", sw: Color(hex: "991B1B"), ui: UIColor(red: 0.60, green: 0.11, blue: 0.11, alpha: 1)),
    VRenk(id: "forest", isim: "Orman", sw: Color(hex: "166534"), ui: UIColor(red: 0.09, green: 0.40, blue: 0.20, alpha: 1)),
    VRenk(id: "amber", isim: "Kehribar", sw: Color(hex: "92400E"), ui: UIColor(red: 0.57, green: 0.25, blue: 0.05, alpha: 1)),
]

private struct CVFmt: Identifiable {
    let id: String
    let isim: String
    let baseColor: Color
    let render: (OzgecmisDraft, UIColor) -> Data?
}

private func ozgecmisTumFormatlar() -> [CVFmt] {
    var list: [CVFmt] = [
        CVFmt(id: "classic", isim: "Classic", baseColor: Color(hex: "0D3D73"),
              render: { d, c in
                  var dd = d
                  dd.solPanelRenkHex = c.ozgecmisPanelHexString()
                  return OzgecmisPDFRenderer.render(draft: dd)
              }),
    ]
    for t in CVFormatSecici.allFormats {
        list.append(CVFmt(id: t.id, isim: t.isim, baseColor: Color(uiColor: t.onizlemeRenk), render: t.render))
    }
    return list
}

private extension UIColor {
    /// 6 haneli hex, `solPanelRenkHex` ile uyumlu (örn. "0D3D73")
    func ozgecmisPanelHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - Özgeçmiş PDF Önizleme Ekranı
struct OzgecmisPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: OzgecmisStore
    @State private var fmtIdx: Int = 0
    @State private var renkID: String = "navy"
    @State private var pdfData: Data?
    @State private var shareURL: URL?
    @State private var showATSPuanlama = false
    @State private var loading = false
    @State private var thumbs: [String: UIImage] = [:]
    private let fmts = ozgecmisTumFormatlar()
    private var fmt: CVFmt { fmts[fmtIdx] }
    private var renk: VRenk { ozgecmisOnizlemeRenkleri.first { $0.id == renkID } ?? ozgecmisOnizlemeRenkleri[0] }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.10).ignoresSafeArea()
                VStack(spacing: 0) {
                    ZStack {
                        if loading {
                            VStack(spacing: 10) {
                                ProgressView().tint(.white).scaleEffect(1.3)
                                Text("Hazırlanıyor…").font(.system(size: 12)).foregroundColor(.white.opacity(0.45))
                            }
                        } else if let d = pdfData {
                            OzgecmisPDFKitView(data: d).id("\(fmtIdx)-\(renkID)")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // v3: kompakt alt şerit (≤80pt)
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 8) {
                            renkSeciciCompact
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 1, height: 36)
                            formatSecCompact
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .frame(maxHeight: 80)
                    }
                    .background(Color(white: 0.08))
                    .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5), alignment: .top)
                }
            }
            .navigationTitle("CV Önizleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(white: 0.08), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showATSPuanlama = true
                    } label: {
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let u = shareURL {
                        ShareLink(item: u, preview: SharePreview("Ozgecmis.pdf", image: Image(systemName: "doc.fill"))) {
                            Image(systemName: "square.and.arrow.up").foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear { renderPDF(); buildThumbs() }
            .onChange(of: fmtIdx) { _, _ in renderPDF() }
            .onChange(of: renkID) { _, _ in
                renderPDF()
                buildThumbs()
            }
            .onChange(of: store.draft) { _, _ in renderPDF() }
            .sheet(isPresented: $showATSPuanlama) {
                CVATSPuanlamaView()
                    .environmentObject(store)
            }
        }
    }

    private var renkSecici: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                Color.clear.frame(width: 4)
                ForEach(ozgecmisOnizlemeRenkleri) { r in
                    let s = renkID == r.id
                    Button {
                        withAnimation(.spring(response: 0.25)) { renkID = r.id }
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(r.sw).frame(width: 13, height: 13)
                                .overlay(Circle().stroke(Color.white.opacity(s ? 0.9 : 0.2), lineWidth: s ? 2 : 0.5))
                            Text(r.isim).font(.system(size: 11, weight: s ? .bold : .medium))
                                .foregroundColor(s ? .white : .white.opacity(0.45))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(s ? r.sw.opacity(0.25) : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(s ? r.sw.opacity(0.6) : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Color.clear.frame(width: 4)
            }
        }
    }

    private var formatSec: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                Color.clear.frame(width: 4)
                ForEach(Array(fmts.enumerated()), id: \.element.id) { idx, f in
                    let sel = fmtIdx == idx
                    Button {
                        withAnimation(.spring(response: 0.28)) { fmtIdx = idx }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6).fill(f.baseColor.opacity(0.14)).frame(width: 52, height: 68)
                                if let img = thumbs[f.id + renkID] {
                                    Image(uiImage: img).resizable().scaledToFit().frame(width: 48, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                } else {
                                    RoundedRectangle(cornerRadius: 4).fill(f.baseColor.opacity(0.28)).frame(width: 40, height: 54)
                                        .overlay(
                                            VStack(spacing: 3) {
                                                ForEach(0..<5, id: \.self) { _ in
                                                    RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.25)).frame(height: 2)
                                                }
                                            }
                                            .padding(6)
                                        )
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(sel ? renk.sw : Color.white.opacity(0.10), lineWidth: sel ? 2 : 0.7))
                            .shadow(color: sel ? renk.sw.opacity(0.35) : .clear, radius: 5, y: 2)
                            Text(f.isim).font(.system(size: 9.5, weight: sel ? .bold : .medium))
                                .foregroundColor(sel ? .white : .white.opacity(0.4)).lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Color.clear.frame(width: 4)
            }
            .padding(.vertical, 4)
        }
        .onAppear { buildThumbs() }
    }

    /// Önizleme v3: tek satırda renk + format, toplam yükseklik ≤80pt
    private var renkSeciciCompact: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(ozgecmisOnizlemeRenkleri) { r in
                    let s = renkID == r.id
                    Button {
                        withAnimation(.spring(response: 0.25)) { renkID = r.id }
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(r.sw).frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Color.white.opacity(s ? 0.9 : 0.2), lineWidth: s ? 1.5 : 0.5))
                            Text(r.isim).font(.system(size: 9, weight: s ? .bold : .medium))
                                .foregroundColor(s ? .white : .white.opacity(0.45))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 5)
                        .background(s ? r.sw.opacity(0.22) : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 8)
        }
        .frame(height: 36)
    }

    private var formatSecCompact: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(fmts.enumerated()), id: \.element.id) { idx, f in
                    let sel = fmtIdx == idx
                    Button {
                        withAnimation(.spring(response: 0.28)) { fmtIdx = idx }
                    } label: {
                        VStack(spacing: 3) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(f.baseColor.opacity(0.14))
                                    .frame(width: 30, height: 40)
                                if let img = thumbs[f.id + renkID] {
                                    Image(uiImage: img).resizable().scaledToFit()
                                        .frame(width: 26, height: 34)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(f.baseColor.opacity(0.28))
                                        .frame(width: 22, height: 30)
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 4)
                                .stroke(sel ? renk.sw : Color.white.opacity(0.10), lineWidth: sel ? 1.5 : 0.5))
                            Text(f.isim)
                                .font(.system(size: 8, weight: sel ? .bold : .medium))
                                .foregroundColor(sel ? .white : .white.opacity(0.4))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 8)
        }
        .frame(height: 48)
        .onAppear { buildThumbs() }
    }

    private func renderPDF() {
        loading = true
        let d = store.draft
        let r = renk.ui
        let f = fmt
        DispatchQueue.global(qos: .userInitiated).async {
            let data = f.render(d, r)
            let url: URL? = data.map { dt in
                let u = FileManager.default.temporaryDirectory.appendingPathComponent("Ozgecmis_\(f.id).pdf")
                try? dt.write(to: u)
                return u
            }
            DispatchQueue.main.async {
                pdfData = data
                shareURL = url
                loading = false
            }
        }
    }

    private func buildThumbs() {
        let d = store.draft
        let r = renk.ui
        for f in fmts {
            let key = f.id + renkID
            guard thumbs[key] == nil else { continue }
            DispatchQueue.global(qos: .utility).async {
                guard let data = f.render(d, r),
                      let doc = PDFDocument(data: data),
                      let page = doc.page(at: 0) else { return }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 0.18
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                let img = UIGraphicsImageRenderer(size: size).image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.translateBy(x: 0, y: size.height)
                    ctx.cgContext.scaleBy(x: scale, y: -scale)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                DispatchQueue.main.async { thumbs[key] = img }
            }
        }
    }
}

struct OzgecmisPDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.displaysPageBreaks = true
        v.backgroundColor = .white
        v.document = PDFDocument(data: data)
        return v
    }

    func updateUIView(_ v: PDFView, context: Context) {
        if v.document?.dataRepresentation() != data {
            v.document = PDFDocument(data: data)
        }
    }
}
