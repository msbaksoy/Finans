import SwiftUI
import UIKit

struct BrutNetView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showMaasGirisSheet = false
    @State private var showPdfShare = false
    @State private var pdfData: Data?
    @State private var yil: Int = Calendar.current.component(.year, from: Date())
    @State private var detayTablosuAcik = false
    /// Inline maaş girişi (ekran açılınca doğrudan tablo)
    @State private var brutlar: [String] = Array(repeating: "", count: 12)
    @State private var primler: [String] = Array(repeating: "", count: 12)
    @State private var triggerBrutFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var triggerPrimFocus: [Bool] = Array(repeating: false, count: 12)
    
    private var yilMaaslar: [AylikMaas] {
        dataManager.aylikMaaslar.filter { $0.yil == yil }.sorted { $0.ay < $1.ay }
    }
    
    /// Tablo gösterimi için detaylı hesaplama (landscape modda kullanılır)
    private var detayliSonuclar: [AylikBrutNetDetay] {
        let brutlar = (1...12).map { ay in
            yilMaaslar.first { $0.ay == ay }?.brutTutar ?? 0
        }
        let primler = (1...12).map { ay in
            yilMaaslar.first { $0.ay == ay }?.primTutar ?? 0
        }
        return BrutNetCalculator.hesaplaYillikDetayli(brutlar: brutlar, primler: primler)
    }
    
    private var toplamNet: Double {
        yilMaaslar.reduce(0) { $0 + $1.netTutar }
    }
    
    private var aylikOrtalamaNet: Double {
        guard !yilMaaslar.isEmpty else { return 0 }
        return toplamNet / Double(yilMaaslar.count)
    }
    
    private var toplamKesinti: Double {
        yilMaaslar.reduce(0) { sum, maas in
            sum + maas.kesintiler.reduce(0) { $0 + $1.tutar }
        }
    }
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            if isLandscape && !yilMaaslar.isEmpty {
                // Yatay mod: tablo tüm ekranı kaplar, PDF butonu overlay
                ZStack(alignment: .topTrailing) {
                    BrutNetDetayTablosu(detaylar: detayliSonuclar, yil: yil)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Button {
                        pdfData = BrutNetPdfOlusturucu.olustur(detaylar: detayliSonuclar, yil: yil)
                        showPdfShare = true
                    } label: {
                        Label("PDF Dışa Aktar", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityLabel("PDF Dışa Aktar")
                    .accessibilityHint("Aylık detay tablosunu PDF olarak dışa aktarır")
                    .padding(16)
                }
            } else {
                // Dikey mod: doğrudan maaş giriş tablosu, altında özet
                ScrollView {
                    VStack(spacing: 24) {
                        inlineMaasGirisTablosu
                        Button {
                            maasGirisKaydet()
                        } label: {
                            Label("Hesapla", systemImage: "function")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityLabel("Brüt ve prim girişini hesapla")

                        if !yilMaaslar.isEmpty {
                            ozetKartlari
                            aylikNetListesi
                            detayTablosuBolumu
                            pdfExportButonu
                        } else {
                            bosDurumView
                        }
                    }
                    .padding(AppSpacing.xxl)
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationTitle("Çalışma Hayatım")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if isLandscape && !yilMaaslar.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showMaasGirisSheet = true
                    } label: {
                        Label("Brüt/Prim Düzenle", systemImage: "square.and.pencil")
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                }
            }
        }
        .sheet(isPresented: $showMaasGirisSheet) {
            MaasGirisSheetView(yil: yil, mevcutMaaslar: yilMaaslar) {
                showMaasGirisSheet = false
            }
            .environmentObject(dataManager)
            .environmentObject(appTheme)
        }
        .onAppear {
            yilMaaslariFormaYukle()
        }
        .onDisappear {
            dataManager.brutNetVerileriniTemizle()
        }
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
 
    }

    /// Mevcut yıl verisini forma doldurur
    private func yilMaaslariFormaYukle() {
        for (_, maas) in yilMaaslar.enumerated() {
            let ay = maas.ay
            guard ay >= 1, ay <= 12 else { continue }
            let i = ay - 1
            if maas.brutTutar > 0 { brutlar[i] = "\(Int(maas.brutTutar))" }
            if maas.primTutar > 0 { primler[i] = "\(Int(maas.primTutar))" }
        }
    }

    /// Inline tablo: brüt/prim binding (ay N güncellenince N ve sonrası aynı değeri alır)
    private func bindingBrutForAy(_ ay: Int) -> Binding<String> {
        let idx = ay - 1
        return Binding(
            get: { brutlar[idx] },
            set: { newValue in
                for i in idx..<12 { brutlar[i] = newValue }
            }
        )
    }

    private func bindingPrimForAy(_ ay: Int) -> Binding<String> {
        Binding(
            get: { primler[ay - 1] },
            set: { primler[ay - 1] = $0 }
        )
    }

    /// Inline girişten kaydet (sheet’teki kaydetVeKapat ile aynı mantık)
    private func maasGirisKaydet() {
        let brutListesi: [Double] = (0..<12).map { parseFormattedNumber(brutlar[$0]) ?? 0 }
        let primListesi: [Double] = (0..<12).map { parseFormattedNumber(primler[$0]) ?? 0 }
        guard brutListesi.contains(where: { $0 > 0 }) else { return }
        let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: brutListesi, primler: primListesi)
        for (index, sonuc) in sonuclar.enumerated() {
            let ay = index + 1
            let brut = brutListesi[index]
            let prim = primListesi[index]
            let kesintiCodable = sonuc.kesintiler.map { KesintiKalemCodable(ad: $0.ad, tutar: $0.tutar, oran: $0.oran) }
            let maas = AylikMaas(ay: ay, brutTutar: brut, primTutar: prim, netTutar: sonuc.net, kesintiler: kesintiCodable, yil: yil)
            dataManager.setAylikMaas(maas)
        }
    }

    private var inlineMaasGirisTablosu: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Ay")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appTheme.textSecondary)
                    .frame(width: 70, alignment: .leading)
                Text("Brüt (₺)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Prim (₺)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ForEach(1...12, id: \.self) { ay in
                HStack(spacing: 12) {
                    Text(ayIsimleri[ay - 1])
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(appTheme.textPrimary)
                        .frame(width: 70, alignment: .leading)

                    FormattedNumberField(
                        text: bindingBrutForAy(ay),
                        placeholder: "0",
                        allowDecimals: false,
                        focusTrigger: Binding(
                            get: { triggerBrutFocus.indices.contains(ay - 1) ? triggerBrutFocus[ay - 1] : false },
                            set: { if triggerBrutFocus.indices.contains(ay - 1) { triggerBrutFocus[ay - 1] = $0 } }
                        ),
                        isLightMode: appTheme.isLight
                    )
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(appTheme.cardBackgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { triggerBrutFocus[ay - 1] = true }

                    FormattedNumberField(
                        text: bindingPrimForAy(ay),
                        placeholder: "0",
                        allowDecimals: false,
                        focusTrigger: Binding(
                            get: { triggerPrimFocus.indices.contains(ay - 1) ? triggerPrimFocus[ay - 1] : false },
                            set: { if triggerPrimFocus.indices.contains(ay - 1) { triggerPrimFocus[ay - 1] = $0 } }
                        ),
                        isLightMode: appTheme.isLight
                    )
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(appTheme.cardBackgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { triggerPrimFocus[ay - 1] = true }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func tarihFormatla(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }
    
    private var bosDurumView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundColor(appTheme.textSecondary.opacity(0.6))
            Text("Henüz maaş verisi yok")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            Text("Brüt maaş ve prim girişi yapmak için Brütten Nete ve Prim Hesaplama alanına tıklayın")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    private var ozetKartlari: some View {
        VStack(spacing: 16) {
            // Aylık ortalama net + Toplam kesinti
            HStack(spacing: 16) {
                OzetKart(
                    title: "Aylık Ort. Net",
                    value: formatCurrency(aylikOrtalamaNet),
                    icon: "chart.bar.fill",
                    color: Color(hex: "34D399")
                )
                OzetKart(
                    title: "Toplam Kesinti",
                    value: formatCurrency(toplamKesinti),
                    icon: "arrow.down.circle.fill",
                    color: Color(hex: "F87171")
                )
            }
            
            // Yıllık toplam net
            HStack {
                Image(systemName: "sum")
                    .font(AppTypography.title2)
                    .foregroundColor(Color(hex: "60A5FA"))
                Text("Yıllık Toplam Net")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                Spacer()
                Text(formatCurrency(toplamNet))
                    .font(AppTypography.amountMedium)
                    .monospacedDigit()
                    .foregroundColor(Color(hex: "60A5FA"))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
            )
        }
    }
    
    private var aylikNetListesi: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aylık Net Maaş")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            
            LazyVStack(spacing: 12) {
                ForEach(yilMaaslar) { maas in
                    AylikNetRow(maas: maas)
                }
            }
        }
    }
    
    private var detayTablosuBolumu: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { detayTablosuAcik.toggle() }
            } label: {
                HStack {
                    Text("Aylık Detay Tablosu")
                        .font(AppTypography.headline)
                        .foregroundColor(appTheme.textPrimary)
                    Spacer()
                    Image(systemName: detayTablosuAcik ? "chevron.up" : "chevron.down")
                        .font(AppTypography.footnote.weight(.semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                .padding(AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(appTheme.listRowBackground)
                )
            }
            .buttonStyle(.plain)
            
            if detayTablosuAcik {
                BrutNetDetayTablosu(detaylar: detayliSonuclar, yil: yil)
                    .frame(maxHeight: 400)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var pdfExportButonu: some View {
        Button {
            pdfData = BrutNetPdfOlusturucu.olustur(detaylar: detayliSonuclar, yil: yil)
            showPdfShare = true
        } label: {
            Label("PDF Olarak Dışa Aktar", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel("PDF Olarak Dışa Aktar")
        .accessibilityHint("Aylık detay tablosunu PDF olarak dışa aktarır")
        .padding(.top, 8)
    }
}

// MARK: - Özet Kart
struct OzetKart: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(AppTypography.headline)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
            }
            Text(value)
                .font(AppTypography.amountMedium)
                .monospacedDigit()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

// MARK: - Aylık Net Satır
struct AylikNetRow: View {
    let maas: AylikMaas
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            Text(ayIsimleri[maas.ay - 1])
                .font(AppTypography.headline)
                .foregroundColor(appTheme.textPrimary)
                .frame(width: 70, alignment: .leading)
            
            Text(maas.primTutar > 0 ? "\(formatCurrency(maas.brutTutar)) + \(formatCurrency(maas.primTutar))" : formatCurrency(maas.brutTutar))
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(appTheme.textSecondary)
            
            Spacer()
            
            Text(formatCurrency(maas.netTutar))
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .foregroundColor(Color(hex: "34D399"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

// MARK: - Maaş Giriş Sheet
struct MaasGirisSheetView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) var dismiss
    let yil: Int
    let mevcutMaaslar: [AylikMaas]
    let onTamam: () -> Void
    
    /// Brüt: fill-down — ay N güncellenince N ve sonrası yeni değeri alır. Prim: ay bazlı.
    @State private var brutlar: [String] = Array(repeating: "", count: 12)
    @State private var primler: [String] = Array(repeating: "", count: 12)
    @State private var triggerBrutFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var triggerPrimFocus: [Bool] = Array(repeating: false, count: 12)
    
    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Üç sütun başlık: Ay | Brüt | Prim
                        HStack(spacing: 12) {
                            Text("Ay")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(width: 70, alignment: .leading)
                            Text("Brüt (₺)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Prim (₺)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        ForEach(1...12, id: \.self) { ay in
                            HStack(spacing: 12) {
                                Text(ayIsimleri[ay - 1])
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(appTheme.textPrimary)
                                    .frame(width: 70, alignment: .leading)
                                
                                FormattedNumberField(
                                    text: bindingBrutForAy(ay),
                                    placeholder: "0",
                                    allowDecimals: false,
                                    focusTrigger: Binding(
                                        get: { triggerBrutFocus.indices.contains(ay - 1) ? triggerBrutFocus[ay - 1] : false },
                                        set: { if triggerBrutFocus.indices.contains(ay - 1) { triggerBrutFocus[ay - 1] = $0 } }
                                    ),
                                    isLightMode: appTheme.isLight
                                )
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(appTheme.cardBackgroundSecondary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { triggerBrutFocus[ay - 1] = true }
                                
                                FormattedNumberField(
                                    text: bindingPrimForAy(ay),
                                    placeholder: "0",
                                    allowDecimals: false,
                                    focusTrigger: Binding(
                                        get: { triggerPrimFocus.indices.contains(ay - 1) ? triggerPrimFocus[ay - 1] : false },
                                        set: { if triggerPrimFocus.indices.contains(ay - 1) { triggerPrimFocus[ay - 1] = $0 } }
                                    ),
                                    isLightMode: appTheme.isLight
                                )
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(appTheme.cardBackgroundSecondary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { triggerPrimFocus[ay - 1] = true }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Brütten Nete ve Prim Hesaplama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
            .toolbarBackground(appTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "94A3B8"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        kaydetVeKapat()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
        .onAppear {
            // Her açılışta boş form — eski veriler yüklensin istemiyoruz
        }
    }
    
    /// Brüt: ay N'ye yazınca N ve sonrası aylar aynı değeri alır (fill-down).
    private func bindingBrutForAy(_ ay: Int) -> Binding<String> {
        let idx = ay - 1
        return Binding(
            get: { brutlar[idx] },
            set: { newValue in
                for i in idx..<12 { brutlar[i] = newValue }
            }
        )
    }
    
    private func bindingPrimForAy(_ ay: Int) -> Binding<String> {
        Binding(
            get: { primler[ay - 1] },
            set: { primler[ay - 1] = $0 }
        )
    }
    
    private func kaydetVeKapat() {
        var brutListesi: [Double] = []
        for i in 0..<12 {
            brutListesi.append(parseFormattedNumber(brutlar[i]) ?? 0)
        }
        var primListesi: [Double] = []
        for i in 0..<12 {
            primListesi.append(parseFormattedNumber(primler[i]) ?? 0)
        }
        let sonBrutlar = brutListesi
        
        if sonBrutlar.contains(where: { $0 > 0 }) {
            
            let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: sonBrutlar, primler: primListesi)
            for (index, sonuc) in sonuclar.enumerated() {
                let ay = index + 1
                let brut = sonBrutlar[index]
                let prim = primListesi[index]
                let kesintiCodable = sonuc.kesintiler.map { KesintiKalemCodable(ad: $0.ad, tutar: $0.tutar, oran: $0.oran) }
                let maas = AylikMaas(ay: ay, brutTutar: brut, primTutar: prim, netTutar: sonuc.net, kesintiler: kesintiCodable, yil: yil)
                dataManager.setAylikMaas(maas)
            }
        }
        
        onTamam()
        dismiss()
    }
}

// MARK: - Brüt-Net Detay Tablosu (yatay mod)
struct BrutNetDetayTablosu: View {
    let detaylar: [AylikBrutNetDetay]
    let yil: Int
    @EnvironmentObject var appTheme: AppTheme
    
    private let colWidth: CGFloat = 88
    private let firstColWidth: CGFloat = 64
    private let rowHeight: CGFloat = 36
    
    private let sutunlar: [(anahtar: KeyPath<AylikBrutNetDetay, Double>, baslik: String)] = [
        (\.brutToplam, "Brüt+Prim"),
        (\.sgkIsci, "SSK İşçi"),
        (\.issizlikIsci, "İşsizlik İşçi"),
        (\.aylikGelirVergisi, "Aylık Gelir Vergisi"),
        (\.damgaVergisi, "Damga Vergisi"),
        (\.kumulatifVergiMatrahi, "Kümülatif Vergi Matrahı"),
        (\.netVergiOncesi, "Net"),
        (\.agi, "AGİ"),
        (\.asgariUcretGVIstisnasi, "Asg. G.V. İst."),
        (\.asgariUcretDVIstisnasi, "Asg. D.V. İst."),
        (\.toplamNetEleGecen, "Toplam Net"),
        (\.sgkIsveren, "SSK İşveren"),
        (\.issizlikIsveren, "İşsizlik İşv."),
        (\.toplamMaliyet, "Toplam Maliyet")
    ]
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Başlık satırı
                HStack(alignment: .center, spacing: 0) {
                    Text("Ay")
                        .frame(width: firstColWidth, alignment: .leading)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(appTheme.textPrimary)
                    ForEach(Array(sutunlar.enumerated()), id: \.offset) { _, sutun in
                        Text(sutun.baslik)
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(appTheme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(appTheme.backgroundSecondary)
                .frame(minHeight: rowHeight + 16)
                
                Divider().background(appTheme.cardStroke)
                
                // Veri satırları
                ForEach(detaylar.filter { $0.brutToplam > 0 }) { d in
                    HStack(alignment: .center, spacing: 0) {
                        Text(ayIsimleri[d.ay - 1])
                            .frame(width: firstColWidth, alignment: .leading)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(appTheme.textPrimary)
                        Group {
                            Text(formatCurrency(d.brut))
                            Text(formatCurrency(d.sgkIsci))
                            Text(formatCurrency(d.issizlikIsci))
                            Text(formatCurrency(d.aylikGelirVergisi))
                            Text(formatCurrency(d.damgaVergisi))
                            Text(formatCurrency(d.kumulatifVergiMatrahi))
                            Text(formatCurrency(d.netVergiOncesi))
                            Text(formatCurrency(d.agi))
                            Text(formatCurrency(d.asgariUcretGVIstisnasi))
                            Text(formatCurrency(d.asgariUcretDVIstisnasi))
                            Text(formatCurrency(d.toplamNetEleGecen))
                            Text(formatCurrency(d.sgkIsveren))
                            Text(formatCurrency(d.issizlikIsveren))
                            Text(formatCurrency(d.toplamMaliyet))
                        }
                        .frame(minWidth: colWidth, alignment: .trailing)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(minHeight: rowHeight)
                }
                
                // TOPLAM satırı
                if !detaylar.filter({ $0.brutToplam > 0 }).isEmpty {
                    Divider().background(appTheme.cardStroke)
                    HStack(alignment: .center, spacing: 0) {
                        Text("TOPLAM")
                            .frame(width: firstColWidth, alignment: .leading)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.brutToplam }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.sgkIsci }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.issizlikIsci }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.aylikGelirVergisi }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.damgaVergisi }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.last?.kumulatifVergiMatrahi ?? 0))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.netVergiOncesi }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(0))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.asgariUcretGVIstisnasi }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.asgariUcretDVIstisnasi }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.toplamNetEleGecen }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.sgkIsveren }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.issizlikIsveren }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(formatCurrency(detaylar.reduce(0) { $0 + $1.toplamMaliyet }))
                            .frame(minWidth: colWidth, alignment: .trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: rowHeight)
                    .background(Color(hex: "F59E0B").opacity(0.15))
                }
            }
            .padding(12)
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PDF Oluşturucu
struct BrutNetPdfOlusturucu {
    static func olustur(detaylar: [AylikBrutNetDetay], yil: Int) -> Data? {
        let aylik = detaylar.filter { $0.brutToplam > 0 }
        guard !aylik.isEmpty else { return nil }
        
        let pageWidth: CGFloat = 842
        let pageHeight: CGFloat = 595
        let margin: CGFloat = 40
        let rowHeight: CGFloat = 24
        let colWidth: CGFloat = 70
        let firstColWidth: CGFloat = 50
        
        let pdfMeta = [
            kCGPDFContextCreator: "Finans - Brütten Nete"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMeta as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let font = UIFont.systemFont(ofSize: 9)
            let boldFont = UIFont.boldSystemFont(ofSize: 10)
            
            var y: CGFloat = margin
            let headerRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 28)
            "Brüt'ten Net'e Maaş Hesaplama Tablosu - \(yil)".draw(in: headerRect, withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.darkGray
            ])
            y += 36
            
            let headers = ["Ay", "Brüt+Prim", "SSK İşçi", "İşsizlik İşçi", "Gelir Vergisi", "Damga V.", "Küm. Matrah", "Net", "AGİ", "Asg.GV İst.", "Asg.DV İst.", "Toplam Net", "SSK İşv.", "İşsizlik İşv.", "Toplam Maliyet"]
            let keyPaths: [KeyPath<AylikBrutNetDetay, Double>] = [\.brutToplam, \.sgkIsci, \.issizlikIsci, \.aylikGelirVergisi, \.damgaVergisi, \.kumulatifVergiMatrahi, \.netVergiOncesi, \.agi, \.asgariUcretGVIstisnasi, \.asgariUcretDVIstisnasi, \.toplamNetEleGecen, \.sgkIsveren, \.issizlikIsveren, \.toplamMaliyet]
            
            var x = margin
            for (i, h) in headers.enumerated() {
                let w = i == 0 ? firstColWidth : colWidth
                h.draw(in: CGRect(x: x, y: y, width: w, height: rowHeight), withAttributes: [.font: boldFont, .foregroundColor: UIColor.darkGray])
                x += w
            }
            y += rowHeight + 4
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.decimalSeparator = ","
            formatter.groupingSeparator = "."
            formatter.locale = Locale(identifier: "tr_TR")
            
            for d in aylik {
                x = margin
                (ayIsimleri[d.ay - 1] as NSString).draw(in: CGRect(x: x, y: y, width: firstColWidth, height: rowHeight), withAttributes: [.font: font, .foregroundColor: UIColor.black])
                x += firstColWidth
                for kp in keyPaths {
                    let val = d[keyPath: kp]
                    let str = formatter.string(from: NSNumber(value: val)) ?? "0,00"
                    (str as NSString).draw(in: CGRect(x: x, y: y, width: colWidth, height: rowHeight), withAttributes: [.font: font, .foregroundColor: UIColor.black])
                    x += colWidth
                }
                y += rowHeight
            }
            
            y += 4
            x = margin
            ("TOPLAM" as NSString).draw(in: CGRect(x: x, y: y, width: firstColWidth, height: rowHeight), withAttributes: [.font: boldFont, .foregroundColor: UIColor.systemOrange])
            x += firstColWidth
            let toplamlar: [Double] = [
                aylik.reduce(0) { $0 + $1.brutToplam },
                aylik.reduce(0) { $0 + $1.sgkIsci },
                aylik.reduce(0) { $0 + $1.issizlikIsci },
                aylik.reduce(0) { $0 + $1.aylikGelirVergisi },
                aylik.reduce(0) { $0 + $1.damgaVergisi },
                aylik.last?.kumulatifVergiMatrahi ?? 0,
                aylik.reduce(0) { $0 + $1.netVergiOncesi },
                0,
                aylik.reduce(0) { $0 + $1.asgariUcretGVIstisnasi },
                aylik.reduce(0) { $0 + $1.asgariUcretDVIstisnasi },
                aylik.reduce(0) { $0 + $1.toplamNetEleGecen },
                aylik.reduce(0) { $0 + $1.sgkIsveren },
                aylik.reduce(0) { $0 + $1.issizlikIsveren },
                aylik.reduce(0) { $0 + $1.toplamMaliyet }
            ]
            for t in toplamlar {
                let str = formatter.string(from: NSNumber(value: t)) ?? "0,00"
                (str as NSString).draw(in: CGRect(x: x, y: y, width: colWidth, height: rowHeight), withAttributes: [.font: boldFont, .foregroundColor: UIColor.systemOrange])
                x += colWidth
            }
        }
        
        return data
    }
}

// MARK: - PDF Paylaşım Sheet
struct PdfShareSheet: UIViewControllerRepresentable {
    let pdfData: Data
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BrutNet_\(Date().timeIntervalSince1970).pdf")
        try? pdfData.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        BrutNetView()
            .environmentObject(DataManager.shared)
            .environmentObject(AppTheme())
    }
}
