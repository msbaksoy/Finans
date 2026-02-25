import SwiftUI

/// Yan Hak karşılaştırma dashboard'u — profesyonel, görsel karşılaştırmalı rapor.
/// Ücret grafiği, KPI kartları, yan hak kıyaslamaları ve AI yorumu.
/// embedded: true ise NavigationStack/dismiss yok, aynı akışta gösterilir.
struct YanHakRaporView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("groq_api_key") private var groqAPIKey = ""
    
    let mevcutIs: YanHakVerisi
    let teklif: YanHakVerisi
    var embedded: Bool = false
    
    @State private var aiYorumText: String?
    @State private var aiYorumHata: String?
    @State private var aiYorumLoading = false
    
    private let temaRengi = Color("F59E0B")
    private let mevcutRengi = Color("3B82F6")
    private let teklifRengi = Color("F59E0B")
    
    private var yillikFark: Double {
        teklif.yillikNetMaas - mevcutIs.yillikNetMaas
    }
    
    /// Yıllık net maaş yüzde değişimi (teklif / mevcut)
    private var yillikNetOran: Double? {
        guard mevcutIs.yillikNetMaas > 0 else { return nil }
        return (teklif.yillikNetMaas - mevcutIs.yillikNetMaas) / mevcutIs.yillikNetMaas * 100
    }
    
    /// Prim dahil yıllık toplam yüzde değişimi
    private var primDahilOran: Double? {
        let m = mevcutIs.primDahilYillikToplam
        guard m > 0 else { return nil }
        return (teklif.primDahilYillikToplam - m) / m * 100
    }
    
    var body: some View {
        Group {
            if embedded {
                dashboardContent
            } else {
                NavigationStack {
                    dashboardContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Yan Hak Analizi")
                                .font(.headline)
                                .foregroundColor(appTheme.textPrimary)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(appTheme.textSecondary.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if !groqAPIKey.isEmpty, aiYorumText == nil, aiYorumHata == nil {
                Task { await aiYorumAl() }
            }
        }
    }
    
    private var dashboardContent: some View {
        let icerik = VStack(alignment: .leading, spacing: 18) {
            headerSection
            maasKarsilastirmaKarti
            primDahilYillikBarGrafigi
            healthComparisonView
            workModelBox
            commuteAnalysisBox
            kpiKartlari
            yanHakKarsilastirmalari
            aiYorumSection
        }
        
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(appTheme.background)
        
        return Group {
            if embedded {
                icerik
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    icerik
                        .padding(.bottom, 40)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxWidth: .infinity)
                .background(appTheme.background)
            }
        }
    }
    
    // MARK: - Header (taşmayı önlemek için lineLimit)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("İş Teklifi Karşılaştırması")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("Mevcut iş yeriniz ile teklif edilen pozisyonun kapsamlı analizi")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Maaş Karşılaştırma — Aylık Bazda Çizgi Grafik
    private var maasKarsilastirmaKarti: some View {
        let mevcutAylik = mevcutIs.aylikNetMaaslar
        let teklifAylik = teklif.aylikNetMaaslar
        let maxVal = max(mevcutAylik.max() ?? 0, teklifAylik.max() ?? 0) * 1.1
        let hasData = maxVal > 0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3)
                    .foregroundColor(temaRengi)
                Text("Aylık Net Maaş Karşılaştırması")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            
            if hasData {
                maasCizgiGrafik(mevcut: mevcutAylik, teklif: teklifAylik, maxVal: maxVal)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 24) {
                    HStack(spacing: 6) {
                        Circle().fill(mevcutRengi).frame(width: 8, height: 8)
                        Text("Mevcut İş").font(.caption).foregroundColor(appTheme.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(teklifRengi).frame(width: 8, height: 8)
                        Text("Teklif").font(.caption).foregroundColor(appTheme.textSecondary)
                    }
                }
                
                Divider().background(appTheme.textSecondary.opacity(0.3))
                HStack {
                    Text("Yıllık fark")
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    Spacer()
                    Text(formatNumberGoster(yillikFark))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(yillikFark >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                    Text("₺/yıl")
                        .font(.caption)
                        .foregroundColor(appTheme.textSecondary)
                }
                
                // Yüzde artış/düşüş görseli (mavi yukarı ok / kırmızı aşağı ok)
                if let oran = yillikNetOran {
                    maasOranGorseli(yillikOran: oran, primDahilOran: primDahilOran)
                }
                
                // Yorum metni
                if let oran = yillikNetOran, mevcutIs.yillikNetMaas > 0 {
                    maasYorumMetni(yillikOran: oran, primDahilOran: primDahilOran)
                }
            } else {
                Text("Maaş bilgisi girildiğinde grafik burada görünecek.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0.2), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Prim Dahil Yıllık Toplam — Yatay Bar Grafik
    private var primDahilYillikBarGrafigi: some View {
        let mevcutToplam = mevcutIs.primDahilYillikToplam
        let teklifToplam = teklif.primDahilYillikToplam
        let maxVal = max(mevcutToplam, teklifToplam)
        let hasData = maxVal > 0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title3)
                    .foregroundColor(temaRengi)
                Text("Prim Dahil Yıllık Toplam")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            
            if hasData {
                let barHeight: CGFloat = 28
                GeometryReader { geo in
                    let barAlaniGenislik = geo.size.width - 170
                    VStack(alignment: .leading, spacing: 20) {
                        yatayBarSatir(label: "Mevcut İş", deger: mevcutToplam, maxVal: maxVal, renk: mevcutRengi, barHeight: barHeight, barMaxW: barAlaniGenislik)
                        yatayBarSatir(label: "Teklif", deger: teklifToplam, maxVal: maxVal, renk: teklifRengi, barHeight: barHeight, barMaxW: barAlaniGenislik)
                    }
                }
                .frame(height: 100)
            } else {
                Text("Maaş bilgisi girildiğinde grafik burada görünecek.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0.2), radius: 12, x: 0, y: 4)
        )
    }
    
    private func yatayBarSatir(label: String, deger: Double, maxVal: Double, renk: Color, barHeight: CGFloat, barMaxW: CGFloat) -> some View {
        let fillW = maxVal > 0 ? max(8, barMaxW * CGFloat(deger / maxVal)) : CGFloat(0)
        return HStack(spacing: 10) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textPrimary)
                .frame(width: 70, alignment: .leading)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(renk.opacity(0.2))
                    .frame(height: barHeight)
                RoundedRectangle(cornerRadius: 6)
                    .fill(renk)
                    .frame(width: fillW, height: barHeight)
            }
            .frame(maxWidth: .infinity)
            Text(formatNumberGoster(deger) + " ₺")
                .font(.caption.weight(.semibold))
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 80, alignment: .trailing)
        }
    }
    
    private func maasCizgiGrafik(mevcut: [Double], teklif: [Double], maxVal: Double) -> some View {
        let yAxisWidth: CGFloat = 44
        let xAxisHeight: CGFloat = 56
        let chartHeight: CGFloat = 180
        let chartPadding: CGFloat = 8
        
        return HStack(alignment: .top, spacing: 0) {
            // Y ekseni etiketleri
            VStack(alignment: .trailing, spacing: 0) {
                Text(formatKisaTutar(maxVal))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(appTheme.textSecondary)
                Spacer()
                Text("0")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(appTheme.textSecondary)
            }
            .frame(width: yAxisWidth, height: chartHeight + xAxisHeight)
            .padding(.top, chartPadding)
            
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let w = geo.size.width - chartPadding * 2
                    let h = chartHeight - chartPadding * 2
                    let stepX = w / CGFloat(max(1, 11))
                    
                    ZStack(alignment: .topLeading) {
                        // Grid çizgileri
                        ForEach(1..<4, id: \.self) { i in
                            let y = h * CGFloat(i) / 4
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: y + chartPadding))
                                p.addLine(to: CGPoint(x: w + chartPadding * 2, y: y + chartPadding))
                            }
                            .stroke(appTheme.textSecondary.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                        
                        // Mevcut İş çizgisi
                        if maxVal > 0 {
                            cizgiPath(values: mevcut, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding)
                                .stroke(mevcutRengi, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            cizgiNoktalari(values: mevcut, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding, renk: mevcutRengi)
                        }
                        
                        // Teklif çizgisi
                        if maxVal > 0 {
                            cizgiPath(values: teklif, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding)
                                .stroke(teklifRengi, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            cizgiNoktalari(values: teklif, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding, renk: teklifRengi)
                        }
                    }
                }
                .frame(height: chartHeight)
                
                // X ekseni — kısa ay adları (sığma için)
                let kisaAylar = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(kisaAylar[i])
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(appTheme.textSecondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: xAxisHeight)
            }
        }
    }
    
    private func cizgiPath(values: [Double], maxVal: Double, width: CGFloat, height: CGFloat, stepX: CGFloat, padding: CGFloat) -> Path {
        var p = Path()
        guard maxVal > 0, !values.isEmpty else { return p }
        for (i, v) in values.enumerated() {
            let x = padding + CGFloat(i) * stepX
            let y = padding + height - (CGFloat(v / maxVal) * (height - padding * 2))
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return p
    }
    
    private func cizgiNoktalari(values: [Double], maxVal: Double, width: CGFloat, height: CGFloat, stepX: CGFloat, padding: CGFloat, renk: Color) -> some View {
        Group {
            ForEach(0..<values.count, id: \.self) { i in
                let v = values[i]
                let x = padding + CGFloat(i) * stepX
                let y = padding + height - (CGFloat(v / maxVal) * (height - padding * 2))
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(renk)
                        .frame(width: 6, height: 6)
                    Text(formatNumberGoster(v))
                        .font(.system(size: 7, weight: .medium, design: .rounded))
                        .foregroundColor(appTheme.textPrimary)
                        .rotationEffect(.degrees(-45))
                        .offset(y: -18)
                }
                .position(x: x, y: y)
            }
        }
    }
    
    private func formatKisaTutar(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.1fM", d / 1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK", d / 1_000) }
        return formatNumberGoster(d)
    }
    
    // MARK: - Maaş Oran Görseli (mavi yukarı / kırmızı aşağı ok)
    private func maasOranGorseli(yillikOran: Double, primDahilOran: Double?) -> some View {
        let yukariRenk = Color(hex: "3B82F6")
        let asagiRenk = Color(hex: "EF4444")
        
        return HStack(spacing: 12) {
            oranKutu(label: "Aylık", oran: yillikOran, yukariRenk: yukariRenk, asagiRenk: asagiRenk)
            oranKutu(label: "Yıllık", oran: yillikOran, yukariRenk: yukariRenk, asagiRenk: asagiRenk)
            if let prim = primDahilOran {
                oranKutu(label: "Prim Dahil", oran: prim, yukariRenk: yukariRenk, asagiRenk: asagiRenk)
            }
        }
        .padding(.vertical, 12)
        
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appTheme.listRowBackground.opacity(0.8))
        )
    }
    
    private func oranKutu(label: String, oran: Double, yukariRenk: Color, asagiRenk: Color) -> some View {
        let pozitif = oran >= 0
        let renk = pozitif ? yukariRenk : asagiRenk
        let ikon = pozitif ? "arrow.up.right" : "arrow.down.right"
        return HStack(spacing: 6) {
            Image(systemName: ikon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(renk)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(appTheme.textSecondary)
                Text(String(format: "%.1f%%", abs(oran)))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(renk)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(renk.opacity(0.12))
        )
    }
    
    // MARK: - Maaş Yorum Metni
    private func maasYorumMetni(yillikOran: Double, primDahilOran: Double?) -> some View {
        let pozitif = yillikOran >= 0
        let metin: String
        if pozitif {
            var s = "Yeni teklif mevcut iş yerine kıyasla yüzde \(formatOran(yillikOran)) maaş artışı sağlıyor (yıllık). Bu da aylık olarak maaşında yüzde \(formatOran(yillikOran)) artışa denk gelecek."
            if let prim = primDahilOran, prim >= 0 {
                s += " Yıllık primler dikkate alındığında yıllık bazda maaşın toplamda yüzde \(formatOran(prim)) artış sağlıyor."
            } else if let prim = primDahilOran {
                s += " Ancak primler dikkate alındığında yıllık bazda toplamda yüzde \(formatOran(-prim)) düşüş görülüyor."
            }
            metin = s
        } else {
            var s = "Yeni teklif mevcut iş yerine kıyasla yüzde \(formatOran(-yillikOran)) maaş düşüşü gösteriyor (yıllık). Bu da aylık olarak maaşında yüzde \(formatOran(-yillikOran)) azalmaya denk gelecek."
            if let prim = primDahilOran, prim < 0 {
                s += " Yıllık primler dikkate alındığında yıllık bazda maaşın toplamda yüzde \(formatOran(-prim)) düşüş sağlıyor."
            } else if let prim = primDahilOran {
                s += " Ancak primler dikkate alındığında yıllık bazda toplamda yüzde \(formatOran(prim)) artış görülüyor."
            }
            metin = s
        }
        return Text(metin)
            .font(.subheadline)
            .foregroundColor(appTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }
    
    private func formatOran(_ d: Double) -> String {
        String(format: "%.1f", abs(d))
    }
    
    // MARK: - KPI Kartları
    private var kpiKartlari: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            kpiKart(ikon: "banknote", baslik: "Yıllık Net", mevcut: mevcutIs.yillikNetMaas > 0 ? formatNumberGoster(mevcutIs.yillikNetMaas) + " ₺" : "—", teklif: teklif.yillikNetMaas > 0 ? formatNumberGoster(teklif.yillikNetMaas) + " ₺" : "—")
            kpiKart(ikon: "calendar", baslik: "Yılda Maaş", mevcut: "\(mevcutIs.maasPeriyodu)", teklif: "\(teklif.maasPeriyodu)")
            kpiKart(ikon: "sun.max", baslik: "Yıllık İzin", mevcut: mevcutIs.yillikIzinGunu.map { "\($0) gün" } ?? "—", teklif: teklif.yillikIzinGunu.map { "\($0) gün" } ?? "—")
            kpiKart(ikon: "building.2", baslik: "Çalışma", mevcut: mevcutIs.calismaModeli?.rawValue ?? "—", teklif: teklif.calismaModeli?.rawValue ?? "—")
            kpiKart(ikon: "gift", baslik: "Prim/Bonus", mevcut: mevcutIs.yillikPrimBonusTutar.map { formatNumberGoster($0) + " ₺" } ?? "—", teklif: teklif.yillikPrimBonusTutar.map { formatNumberGoster($0) + " ₺" } ?? "—")
            kpiKart(ikon: "clock", baslik: "Yolda Süre", mevcut: formatYoldaSure(mevcutIs), teklif: formatYoldaSure(teklif))
        }
    }
    
    private func kpiKart(ikon: String, baslik: String, mevcut: String, teklif: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: ikon)
                    .font(.subheadline)
                    .foregroundColor(temaRengi)
                Text(baslik)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appTheme.textSecondary)
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mevcut")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                    Text(mevcut)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Rectangle()
                    .fill(appTheme.textSecondary.opacity(0.2))
                    .frame(width: 1, height: 28)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Teklif")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                    Text(teklif)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appTheme.listRowBackground)
        )
    }
    
    // MARK: - Yan Hak Karşılaştırmaları (ortalanmış, fit tasarım)
    private var yanHakKarsilastirmalari: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Yan Haklar Karşılaştırması")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
                .frame(maxWidth: .infinity)
            
            VStack(spacing: 0) {
                yanHakSatir(ikon: "shield.checkered", baslik: "Sigorta", mevcut: formatSigorta(mevcutIs), teklif: formatSigorta(teklif))
                Divider().background(appTheme.textSecondary.opacity(0.2)).padding(.horizontal)
                yanHakSatir(ikon: "fork.knife", baslik: "Yemek", mevcut: formatYemek(mevcutIs), teklif: formatYemek(teklif))
                Divider().background(appTheme.textSecondary.opacity(0.2)).padding(.horizontal)
                yanHakSatir(ikon: "car.fill", baslik: "Ulaşım", mevcut: formatUlasim(mevcutIs), teklif: formatUlasim(teklif))
                Divider().background(appTheme.textSecondary.opacity(0.2)).padding(.horizontal)
                yanHakSatir(ikon: "iphone", baslik: "Telefon", mevcut: mevcutIs.telefonVeriliyor ? "Evet" : "Hayır", teklif: teklif.telefonVeriliyor ? "Evet" : "Hayır")
                Divider().background(appTheme.textSecondary.opacity(0.2)).padding(.horizontal)
                yanHakSatir(ikon: "wifi", baslik: "İnt./Elektrik", mevcut: mevcutIs.internetElektrikDestekVar ? "\(formatNumberGoster(mevcutIs.internetElektrikToplamTutar ?? 0)) ₺" : "Yok", teklif: teklif.internetElektrikDestekVar ? "\(formatNumberGoster(teklif.internetElektrikToplamTutar ?? 0)) ₺" : "Yok")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0.2), radius: 12, x: 0, y: 4)
        )
    }
    
    private func yanHakSatir(ikon: String, baslik: String, mevcut: String, teklif: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: ikon)
                .font(.subheadline)
                .foregroundColor(temaRengi)
                .frame(width: 24, alignment: .center)
            Text(baslik)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(1)
                .frame(minWidth: 70, alignment: .leading)
            Spacer(minLength: 8)
            Text(mevcut)
                .font(.caption)
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.left.arrow.right")
                .font(.caption2)
                .foregroundColor(appTheme.textSecondary.opacity(0.5))
            Text(teklif)
                .font(.caption)
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
    
    /// Sigorta: kısa etiketler — Tam., Öz., Göz/Diş (çok satır wrap önlenir)
    private func formatSigorta(_ d: YanHakVerisi) -> String {
        var p: [String] = []
        if d.tamamlayiciSaglikVar { p.append("Tam.") }
        if d.ozelSaglikVar { p.append("Öz.") }
        if d.gozDisDestegiVar { p.append("Göz/Diş") }
        return p.isEmpty ? "Yok" : p.joined(separator: " · ")
    }
    
    private func formatYemek(_ d: YanHakVerisi) -> String {
        switch d.yemekTipi {
        case .yemekhane: return "Yemekhane\(d.yemekhaneKalitePuan.map { " (\($0)/5)" } ?? "")"
        case .yemekKarti: return "Kart\(d.yemekKartiGunlukTutar.map { " \(formatNumberGoster($0)) ₺/gün" } ?? "")"
        case .none: return "Yok"
        }
    }
    
    private func formatUlasim(_ d: YanHakVerisi) -> String {
        guard let t = d.ulasimTipi else { return "—" }
        switch t {
        case .yolUcreti: return "Yol \(d.yolUcretiAylik.map { formatNumberGoster($0) + " ₺" } ?? "")"
        case .sirketAraci: return "Araç"
        case .servis: return "Servis"
        case .hicbiri: return "Yok"
        }
    }
    
    private func formatYoldaSure(_ d: YanHakVerisi) -> String {
        let s = d.yoldaSureSaat ?? 0
        let m = d.yoldaSureDakika ?? 0
        if s == 0 && m == 0 { return "—" }
        return "\(s) sa \(m) dk"
    }
    
    // MARK: - Sağlık Sigortası Karşılaştırma
    private var healthComparisonView: some View {
        // Rank: 0 = Yok, 1 = Tamamlayıcı, 2 = Özel
        func rank(_ d: YanHakVerisi) -> Int {
            if d.ozelSaglikVar { return 2 }
            if d.tamamlayiciSaglikVar { return 1 }
            return 0
        }
        func label(_ d: YanHakVerisi) -> String {
            if d.ozelSaglikVar { return "Özel Sağlık Sigortası" }
            if d.tamamlayiciSaglikVar { return "Tamamlayıcı Sağlık Sigortası" }
            return "Yok"
        }

        let mevcutRank = rank(mevcutIs)
        let teklifRank = rank(teklif)
        let positive = teklifRank >= mevcutRank
        let iconName = positive ? "checkmark.circle.fill" : "xmark.octagon.fill"
        let iconColor = positive ? Color(hex: "22C55E") : Color(hex: "EF4444")

        let message: String
        if mevcutRank == teklifRank {
            message = "Her iki iş de aynı sağlık kapsamını sunuyor (\(label(mevcutIs)))."
        } else if positive {
            message = "Teklif sağlık kapsamını yükseltiyor: \(label(mevcutIs)) → \(label(teklif))."
        } else {
            message = "Teklif sağlık kapsamını daraltıyor: \(label(mevcutIs)) → \(label(teklif))."
        }

        // Match styling/width to primDahilYillikBarGrafigi (padding 24 + cornerRadius 20)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .padding(.top, 2)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
            )
        }
    }
    
    // MARK: - Work Model Comparison Box (Analiz Kutucuğu)
    private var workModelBox: some View {
        let text = YanHakVerisi.workModelComparison(mevcut: mevcutIs, teklif: teklif)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(Color(hex: "3B82F6"))
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
    
    // MARK: - Commute & Life Quality Analysis Box
    private var commuteAnalysisBox: some View {
        let (msg, impact, _) = YanHakVerisi.commuteComparison(mevcut: mevcutIs, teklif: teklif)
        let bg: Color = {
            switch impact {
            case .major: return Color.green.opacity(0.05)
            case .moderate: return Color.yellow.opacity(0.04)
            case .minimal: return Color.blue.opacity(0.03)
            case .worse: return Color.red.opacity(0.04)
            }
        }()
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.title3)
                    .foregroundColor(Color(hex: "7C3AED"))
                VStack(alignment: .leading, spacing: 6) {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
            .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(bg)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
    
    // MARK: - AI Yorum Bölümü
    private var aiYorumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(temaRengi)
                Text("AI Değerlendirmesi")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            
            if aiYorumLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(temaRengi)
                    Text("Analiz ediliyor...")
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appTheme.textSecondary.opacity(0.3), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 16).fill(appTheme.listRowBackground.opacity(0.5)))
                )
            } else if let hata = aiYorumHata {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(hata)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
            } else if let yorum = aiYorumText {
                Text(yorum)
                    .font(.body)
                    .foregroundColor(appTheme.textPrimary)
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(appTheme.listRowBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(temaRengi.opacity(0.4), lineWidth: 1)
                            )
                    )
            } else if groqAPIKey.isEmpty {
                Text("AI değerlendirmesi için Groq API anahtarınızı kaydedin.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(appTheme.listRowBackground.opacity(0.5))
                    )
            }
        }
    }
    
    private func aiYorumAl() async {
        aiYorumLoading = true
        aiYorumHata = nil
        aiYorumText = nil
        do {
            let yorum = try await GroqService.shared.fetchYorum(mevcutIs: mevcutIs, teklif: teklif, apiKey: groqAPIKey)
            await MainActor.run {
                aiYorumText = yorum
                aiYorumLoading = false
            }
        } catch {
            await MainActor.run {
                aiYorumHata = error.localizedDescription
                aiYorumLoading = false
            }
        }
    }
    
    private func formatNumberGoster(_ d: Double) -> String {
        guard d != 0 else { return "0" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        fmt.decimalSeparator = ","
        fmt.groupingSeparator = "."
        return fmt.string(from: NSNumber(value: d)) ?? "—"
    }
}
