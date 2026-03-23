import Foundation
import SwiftUI

/// Araç segmenti seçenekleri ve açıklamaları. Teklif kıyaslama akışında kullanılır.
enum AracSegmentBilgisi {
    /// Kullanıcının seçebileceği segmentler (Yok + A..S).
    static let segmentler: [String] = ["Yok", "A", "B", "C", "D", "E", "F", "G", "J", "M", "S"]

    /// Draft’a kaydedilecek format: "A Segment", "B Segment", "J Segment" vb. "Yok" veya boş için "".
    static func draftDegeri(secim: String) -> String {
        guard secim != "Yok", !secim.isEmpty else { return "" }
        return "\(secim) Segment"
    }

    /// Draft’tan gelen değeri picker için gösterim formatına çevirir (örn. "B Segment" → "B").
    static func gosterimDegeri(draft: String) -> String {
        if draft.isEmpty { return "Yok" }
        return draft.replacingOccurrences(of: " Segment", with: "")
    }

    private static let aciklamalar: [String: String] = [
        "A": "En küçük araçlar (max 3,7 m). Şehir içi, park kolaylığı, uygun fiyat.",
        "B": "3,7–4 m arası küçük araçlar. Uygun fiyat, A'ya göre daha ağır ve güçlü.",
        "C": "Kompakt / alt-orta sınıf. Küçük aile otomobili. Türkiye'de en çok satan segment.",
        "D": "Üst-orta sınıf / geniş aile aracı. Geniş iç mekan, yüksek silindir hacmi.",
        "E": "Üst sınıf, 5 m+ lüks araçlar. 2.0 CC+ motor, ağır ve kaliteli malzeme.",
        "F": "Lüks otomobil sınıfı. Geniş hacim, yüksek güç, üstün işçilik ve donanım.",
        "G": "Spor araçlar. Üstün performans, cabrio/coupe/roadster karoser.",
        "J": "SUV ve CUV. 4x4, off-road, şehir içi uyumlu.",
        "M": "MPV – çok amaçlı araçlar. Birden fazla segment özelliği.",
        "S": "İki kapılı spor. Yüksek beygir, üstün manevra ve yol tutuş."
    ]

    static func aciklama(for segment: String) -> String {
        let key = segment.replacingOccurrences(of: " Segment", with: "").trimmingCharacters(in: .whitespaces)
        return aciklamalar[key] ?? ""
    }

    /// Tüm segment–açıklama çiftleri (bilgi sayfası için).
    static var tumAciklamalar: [(segment: String, aciklama: String)] {
        segmentler.filter { $0 != "Yok" }.map { ($0, aciklamalar[$0] ?? "") }
    }
}

// MARK: - Segment bilgi sayfası (i butonuna tıklanınca açılır)

struct AracSegmentBilgiSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Araç segmenti, boyut ve kullanım amacına göre sınıflandırmadır. Aşağıdaki tablo genel bilgi içerir.")
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                        .padding(.bottom, 8)

                    ForEach(AracSegmentBilgisi.tumAciklamalar, id: \.segment) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Segment \(item.segment)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(appTheme.primaryAccent)
                                Spacer()
                            }
                            Text(item.aciklama)
                                .font(.caption)
                                .foregroundColor(appTheme.textPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(appTheme.background)
            .navigationTitle("Araç segmentleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                        .foregroundColor(appTheme.primaryAccent)
                }
            }
        }
    }
}

// MARK: - Tıklanabilir segment seçim butonu (Menu yerine şık liste)

/// Segment seçimi için anlaşılır, tıklanabilir buton. Açılır listede tüm segmentler + bilgi linki.
struct AracSegmentSecimButonu: View {
    @Binding var selection: String
    var accentColor: Color
    @EnvironmentObject var appTheme: AppTheme
    @State private var showSegmentList = false
    @State private var showBilgiSheet = false

    private var segmentSecenekleri: [String] { AracSegmentBilgisi.segmentler.filter { $0 != "Yok" } }
    private var gosterimMetni: String {
        if selection.isEmpty { return "Segment seçin" }
        return "Segment \(selection)"
    }

    var body: some View {
        Button {
            showSegmentList = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "car.fill")
                    .font(.subheadline)
                    .foregroundColor(accentColor.opacity(0.9))
                Text(gosterimMetni)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(selection.isEmpty ? appTheme.textSecondary : appTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.down.circle.fill")
                    .font(.body)
                    .foregroundColor(accentColor.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSegmentList) {
            segmentSecimListesi
        }
        .sheet(isPresented: $showBilgiSheet) {
            AracSegmentBilgiSheet()
                .environmentObject(appTheme)
        }
    }

    private var segmentSecimListesi: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showSegmentList = false
                        showBilgiSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(appTheme.primaryAccent)
                            Text("Segmentler hakkında bilgi")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.primaryAccent)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Araç segmenti").font(.caption).foregroundColor(.secondary)) {
                    ForEach(segmentSecenekleri, id: \.self) { seg in
                        Button {
                            selection = seg
                            showSegmentList = false
                        } label: {
                            HStack {
                                Text("Segment \(seg)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(appTheme.textPrimary)
                                Spacer()
                                if selection == seg {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Segment seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { showSegmentList = false }
                        .foregroundColor(appTheme.textSecondary)
                }
            }
        }
    }
}
