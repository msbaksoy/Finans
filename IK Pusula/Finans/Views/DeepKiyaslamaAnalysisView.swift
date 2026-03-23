import SwiftUI

struct DeepKiyaslamaAnalysisView: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    var onClose: (() -> Void)? = nil

    @State private var animasyonBasladi = false
    @State private var isAnalyzing = false
    @State private var ulasimMetni = ""
    @State private var showPDFShare = false
    @State private var pdfData: Data? = nil
    @State private var isPDFGenerating = false
    @State private var showAylikNetMaasSheet = false

    // ─── Hesaplamalar ────────────────────────────────────────────
    private var sirket1: String { viewModel.draft.mevcutSirketAdi.isEmpty ? "Mevcut" : viewModel.draft.mevcutSirketAdi }
    private var sirket2: String { viewModel.draft.teklifSirketAdi.isEmpty ? "Teklif"  : viewModel.draft.teklifSirketAdi }

    private var yalinM1: Double  { viewModel.graph1YillikNetMaas(isCurrent: true) }
    private var yalinM2: Double  { viewModel.graph1YillikNetMaas(isCurrent: false) }
    private var primM1: Double   { viewModel.graph2NetMaasVePrim(isCurrent: true) - yalinM1 }
    private var primM2: Double   { viewModel.graph2NetMaasVePrim(isCurrent: false) - yalinM2 }
    private var gizliM1: Double  { viewModel.calculateHiddenWealth(isCurrent: true) }
    private var gizliM2: Double  { viewModel.calculateHiddenWealth(isCurrent: false) }
    private var trueM1: Double   { yalinM1 + primM1 + gizliM1 }
    private var trueM2: Double   { yalinM2 + primM2 + gizliM2 }
    private var trueFark: Double { trueM2 - trueM1 }
    private var kidemRisk: Double{ viewModel.calculateKidemTazminatiRiski() }
    private var kirilimlar: [GizliServetKalemi] { viewModel.getGizliServetKirilimi() }

    // ─── Body ─────────────────────────────────────────────────────
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // 0. KARAR ÖZETİ (HERO KART)
                    kararOzetiKarti

                    // 1. TRUE TOTAL COMPENSATION (Tek Grafik)
                    trueTotalKarti

                    // 2. MAAŞ KESİNTİ ANALİZİ
                    maasKesintiBolumu

                    // 3. GİZLİ SERVET HESAP FİŞİ
                    gizliServetBolumu

                    // 4. ULAŞIM & SAĞLIK
                    ulasimSaglikBolumu

                    // 5. KIDEM TAZMİNATI TİMELINE
                    if kidemRisk > 0 { kidemAmortismanBolumu }

                    // 6. YILLIK İZİN & YAŞAM DENGESİ
                    yillikIzinBolumu

                    // 7. YAPAY ZEKA KARİYER KOÇU
                    aiKocBolumu

                    // 8. PDF BUTONU
                    pdfButonu

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("İş Teklifi Analizi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { onClose?(); dismiss() }
                        .foregroundColor(appTheme.primaryAccent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        olusturVePaylas()
                    } label: {
                        if isPDFGenerating {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Label("PDF", systemImage: "doc.badge.arrow.up")
                                .font(.subheadline.bold())
                        }
                    }
                    .foregroundColor(appTheme.primaryAccent)
                }
            }
            .sheet(isPresented: $showPDFShare) {
                if let data = pdfData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(isPresented: $showAylikNetMaasSheet) {
                AylikNetMaasKiyaslamaSheet(
                    sirket1: sirket1,
                    sirket2: sirket2,
                    aylikNetler1: viewModel.aylikNetMaasDizisi(isCurrent: true),
                    aylikNetler2: viewModel.aylikNetMaasDizisi(isCurrent: false),
                    renk1: viewModel.currentCompanyColor,
                    renk2: viewModel.offerCompanyColor
                )
                .environmentObject(appTheme)
            }
        }
        .onAppear {
            ulasimMetni = viewModel.ulasimAnaliziUret()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
                    animasyonBasladi = true
                }
            }
        }
    }

    // MARK: — 0. KARAR ÖZETİ HERO KARTI
    private var kararOzetiKarti: some View {
        let artis = trueFark > 0
        let renk = artis ? Color.green : Color.red
        let yuzde = trueM1 > 0 ? abs(trueFark / trueM1 * 100) : 0

        return ZStack {
            LinearGradient(
                colors: artis
                    ? [Color(hex: "0F4C3A"), Color(hex: "1A6B52")]
                    : [Color(hex: "4C0F0F"), Color(hex: "6B1A1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: artis ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.system(size: 200, weight: .black))
                .foregroundColor(.white.opacity(0.04))
                .offset(x: 80, y: 20)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sirket1)
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.6))
                        Text(fp(trueM1))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.title2.bold())
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sirket2)
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.6))
                        Text(fp(trueM2))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(renk.opacity(0.25))
                            .frame(width: 52, height: 52)
                        Image(systemName: artis ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(renk)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(artis
                            ? "Teklif Finansal Açıdan Güçlü"
                            : "Teklif Finansal Açıdan Zayıf")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text(artis
                            ? "Tüm yan haklar dahil yıllık \(fp(abs(trueFark))) daha fazla (%\(fy(yuzde)))"
                            : "Tüm yan haklar dahil yıllık \(fp(abs(trueFark))) daha az (%\(fy(yuzde)))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        showAylikNetMaasSheet = true
                    } label: {
                        ozet3Pill(ikon: "turkishlirasign", metin: "Maaş\n\(fp(trueM2 - gizliM2))", renk: .white.opacity(0.15))
                    }
                    .buttonStyle(.plain)
                    ozet3Pill(ikon: "gift.fill", metin: "Yan Hak\n\(fp(gizliM2))", renk: .white.opacity(0.15))
                    ozet3Pill(ikon: artis ? "arrow.up" : "arrow.down", metin: "\(artis ? "+" : "-")\(fy(yuzde))%\nFark", renk: renk.opacity(0.3))
                }
            }
            .padding(24)
        }
        .cornerRadius(24)
        .shadow(color: (artis ? Color.green : Color.red).opacity(0.25), radius: 20, y: 10)
    }

    @ViewBuilder
    private func ozet3Pill(ikon: String, metin: String, renk: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: ikon)
                .font(.footnote.bold())
                .foregroundColor(.white.opacity(0.8))
            Text(metin)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(renk)
        .cornerRadius(12)
    }

    // MARK: — 1. TRUE TOTAL (Tek birleşik grafik, 3 renk katmanı)
    private var trueTotalKarti: some View {
        let maxV = max(trueM1, trueM2, 1)
        return VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "diamond.fill").foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gerçek Yıllık Paket").font(.title3.bold()).foregroundColor(.white)
                    Text("Maaş + Prim + Tüm Yan Haklar").font(.caption).foregroundColor(.white.opacity(0.6))
                }
            }

            VStack(spacing: 20) {
                DeepStackedBar(
                    baslik: sirket1, maas: yalinM1, prim: primM1, gizli: gizliM1,
                    maxDeger: maxV, animasyonBasladi: animasyonBasladi,
                    renk: viewModel.currentCompanyColor
                )
                DeepStackedBar(
                    baslik: sirket2, maas: yalinM2, prim: primM2, gizli: gizliM2,
                    maxDeger: maxV, animasyonBasladi: animasyonBasladi,
                    renk: viewModel.offerCompanyColor
                )
            }

            HStack(spacing: 16) {
                legendPill(renk: Color(hex: "4A90E2"), metin: "Net Maaş")
                legendPill(renk: Color(hex: "50E3C2"), metin: "Net Prim")
                legendPill(renk: Color(hex: "B8E986"), metin: "Yan Haklar")
                Spacer()
            }
        }
        .padding(24)
        .background(LinearGradient(colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(24)
        .shadow(color: Color(hex: "1A1A2E").opacity(0.5), radius: 18, y: 8)
    }

    private func legendPill(renk: Color, metin: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(renk).frame(width: 12, height: 12)
            Text(metin).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: — 2. MAAŞ KESİNTİ ANALİZİ
    private var maasKesintiBolumu: some View {
        let m1Net = viewModel.calculateNet(isCurrent: true, includePrim: false)
        let m2Net = viewModel.calculateNet(isCurrent: false, includePrim: false)
        let m1Brut = viewModel.draft.mevcutBrutMaas
        let m2Brut = viewModel.draft.teklifBrutMaas

        return VStack(alignment: .leading, spacing: 16) {
            kartBaslik(ikon: "percent", metin: "Aylık Maaş Kesinti Analizi")
            Divider()

            HStack(spacing: 12) {
                kesintiBlogu(
                    sirket: sirket1, brut: m1Brut,
                    net: m1Net.aylikOrtalama,
                    renk: viewModel.currentCompanyColor
                )
                Divider().frame(maxHeight: 200)
                kesintiBlogu(
                    sirket: sirket2, brut: m2Brut,
                    net: m2Net.aylikOrtalama,
                    renk: viewModel.offerCompanyColor
                )
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.04), radius: 10)
    }

    @ViewBuilder
    private func kesintiBlogu(sirket: String, brut: Double, net: Double, renk: Color) -> some View {
        let sgk     = brut * 0.15
        let gv      = max(0, brut - sgk) * 0.15
        let dv      = brut * 0.00759
        let toplam  = sgk + gv + dv
        let netTahmini = brut - toplam

        VStack(alignment: .leading, spacing: 10) {
            Text(sirket)
                .font(.caption.bold())
                .foregroundColor(renk)

            VStack(spacing: 6) {
                kesintSatiri("Brüt Maaş", deger: brut, renk: .primary, bold: true)
                kesintSatiri("SGK + İşsizlik (%15)", deger: -sgk, renk: .orange)
                kesintSatiri("Gelir Vergisi (est.)", deger: -gv, renk: .red)
                kesintSatiri("Damga Vergisi (%0.759)", deger: -dv, renk: .red.opacity(0.7))
                Divider()
                kesintSatiri("Net Ele Geçen", deger: net > 0 ? net : netTahmini, renk: renk, bold: true)
            }

            let oran = brut > 0 ? (net > 0 ? net : netTahmini) / brut : 0
            VStack(alignment: .leading, spacing: 4) {
                Text("Net / Brüt: %\(Int(oran * 100))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(renk)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(renk.opacity(0.1)).frame(height: 8)
                        Capsule().fill(renk).frame(width: geo.size.width * CGFloat(oran), height: 8)
                            .animation(.spring(response: 0.8), value: animasyonBasladi)
                    }
                }
                .frame(height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func kesintSatiri(_ baslik: String, deger: Double, renk: Color, bold: Bool = false) -> some View {
        HStack {
            Text(baslik)
                .font(bold ? .caption.bold() : .caption)
                .foregroundColor(bold ? .primary : .secondary)
            Spacer()
            Text((deger < 0 ? "-" : "") + fp(abs(deger)))
                .font(bold ? .caption.bold() : .caption)
                .foregroundColor(renk)
        }
    }

    // MARK: — 3. GİZLİ SERVET HESAP FİŞİ (Mevcut sol, Teklif sağ)
    private var gizliServetBolumu: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "list.receipt")
                    .foregroundColor(appTheme.primaryAccent)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yan Haklar & Gizli Servet")
                        .font(.headline).foregroundColor(appTheme.textPrimary)
                    Text("Yıllık nakit karşılığı")
                        .font(.caption).foregroundColor(appTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.all, 20)

            Divider()

            if kirilimlar.isEmpty {
                Text("Girilen yan hak verisi bulunamadı.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(20)
            } else {
                HStack {
                    Spacer().frame(width: 52)
                    Text(sirket1)
                        .font(.caption.bold())
                        .foregroundColor(viewModel.currentCompanyColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(sirket2)
                        .font(.caption.bold())
                        .foregroundColor(viewModel.offerCompanyColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(appTheme.listRowBackground)

                Divider()

                ForEach(kirilimlar) { kalem in
                    GelismisReceiptRow(kalem: kalem,
                                       sirket1: sirket1, sirket2: sirket2,
                                       renk1: viewModel.currentCompanyColor,
                                       renk2: viewModel.offerCompanyColor)
                    Divider()
                }

                HStack {
                    Spacer().frame(width: 52)
                    VStack(spacing: 2) {
                        Text(fp(gizliM1))
                            .font(.subheadline.bold())
                            .foregroundColor(viewModel.currentCompanyColor)
                        Text("Mevcut toplam")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    VStack(spacing: 2) {
                        Text(fp(gizliM2))
                            .font(.subheadline.bold())
                            .foregroundColor(viewModel.offerCompanyColor)
                        Text("Teklif toplam")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.all, 16)
                .background(appTheme.primaryAccent.opacity(0.05))
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.04), radius: 10)
    }

    // MARK: — 4. ULAŞIM & SAĞLIK
    private var ulasimSaglikBolumu: some View {
        VStack(spacing: 12) {
            analizMetinKarti(
                ikon: "car.front.waves.up.fill",
                baslik: "Ulaşım ve Konfor",
                renk: .blue,
                metin: ulasimMetni
            )
            analizMetinKarti(
                ikon: "cross.case.fill",
                baslik: "Sağlık ve Güvence",
                renk: .green,
                metin: viewModel.saglikAnaliziUret()
            )
        }
    }

    @ViewBuilder
    private func analizMetinKarti(ikon: String, baslik: String, renk: Color, metin: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: ikon)
                    .font(.title3)
                    .foregroundColor(renk)
                    .frame(width: 38, height: 38)
                    .background(renk.opacity(0.12))
                    .clipShape(Circle())
                Text(baslik)
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            Divider()
            markdownText(metin)
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    // MARK: — 5. KIDEM TAZMİNATI AMORTİSMAN
    private var kidemAmortismanBolumu: some View {
        let aylikArtis = max(0, (trueM2 - trueM1) / 12)
        let amortismanAy = aylikArtis > 0 ? kidemRisk / aylikArtis : 999
        let amortismanYil = amortismanAy / 12.0
        let calismaYil = Double(viewModel.draft.mevcutUnvanYil)

        return VStack(alignment: .leading, spacing: 16) {
            kartBaslik(ikon: "hourglass.bottomhalf.filled", metin: "Kıdem Tazminatı & Amortisman")
            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bırakılan Tazminat").font(.caption).foregroundColor(.secondary)
                    Text(fp(kidemRisk))
                        .font(.title2.weight(.heavy))
                        .foregroundColor(.orange)
                }
                Divider().frame(maxHeight: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amortisman Süresi").font(.caption).foregroundColor(.secondary)
                    Text(amortismanAy >= 12
                         ? String(format: "%.1f Yıl", amortismanYil)
                         : String(format: "%.0f Ay", amortismanAy))
                        .font(.title2.weight(.heavy))
                        .foregroundColor(amortismanAy <= 18 ? appTheme.successColor : .orange)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.orange.opacity(0.06))
            .cornerRadius(14)

            if amortismanAy < 999 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amortisman Çizelgesi").font(.caption.bold()).foregroundColor(.secondary)
                    GeometryReader { geo in
                        let maxYil = max(calismaYil, amortismanYil, 3)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)).frame(height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.5))
                                .frame(width: animasyonBasladi ? geo.size.width * CGFloat(min(calismaYil / maxYil, 1)) : 0, height: 12)
                                .animation(.spring(response: 1.0), value: animasyonBasladi)
                            if amortismanYil <= maxYil {
                                Circle()
                                    .fill(appTheme.successColor)
                                    .frame(width: 16, height: 16)
                                    .offset(x: animasyonBasladi ? geo.size.width * CGFloat(amortismanYil / maxYil) - 8 : -8, y: -2)
                                    .animation(.spring(response: 1.0).delay(0.3), value: animasyonBasladi)
                            }
                        }
                    }
                    .frame(height: 16)

                    HStack {
                        Text("Şimdi")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                        Spacer()
                        if amortismanYil < 10 {
                            Text("\(String(format: "%.1f", amortismanYil)) Yıl — Amorti ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(appTheme.successColor)
                        }
                    }
                }
            }

            markdownText(viewModel.kidemAmortismanAnaliziUret())
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.04), radius: 10)
    }

    // MARK: — 6. YILLIK İZİN
    private var yillikIzinBolumu: some View {
        let m1Izin = viewModel.draft.mevcutYillikIzin
        let m2Izin = viewModel.draft.teklifYillikIzin
        let fark = m2Izin - m1Izin

        return VStack(alignment: .leading, spacing: 16) {
            kartBaslik(ikon: "beach.umbrella.fill", metin: "Yıllık İzin & Yaşam Dengesi")
            Divider()

            HStack(spacing: 12) {
                izinKutu(sirket: sirket1, gun: m1Izin, renk: viewModel.currentCompanyColor)
                izinKutu(sirket: sirket2, gun: m2Izin, renk: viewModel.offerCompanyColor)
            }

            if fark != 0 {
                HStack(spacing: 8) {
                    Image(systemName: fark > 0 ? "checkmark.circle.fill" : "minus.circle.fill")
                        .foregroundColor(fark > 0 ? appTheme.successColor : appTheme.warningColor)
                    Text(fark > 0
                        ? "Yıllık \(fark) gün daha fazla izin hakkı — bu yılda \(fark) günlük ekstra özgürlük demek."
                        : "Yıllık \(abs(fark)) gün daha az izin. Maaş artışı bu kaybı telafi ediyor mu değerlendirmelisin.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background((fark > 0 ? appTheme.successColor : appTheme.warningColor).opacity(0.07))
                .cornerRadius(12)
            } else {
                Text("Her iki şirkette yıllık izin gün sayısı aynı.").font(.subheadline).foregroundColor(.secondary)
            }

            markdownText(viewModel.yillikIzinAnaliziUret())
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.04), radius: 10)
    }

    @ViewBuilder
    private func izinKutu(sirket: String, gun: Int, renk: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sirket).font(.caption.bold()).foregroundColor(renk).lineLimit(1)
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(gun)").font(.system(size: 36, weight: .heavy, design: .rounded)).foregroundColor(renk)
                Text("gün").font(.subheadline).foregroundColor(.secondary).padding(.bottom, 5)
            }
            Text("Yıllık İzin Hakkı").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(renk.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(renk.opacity(0.15), lineWidth: 1))
    }

    // MARK: — 7. YAPAY ZEKA KARİYER KOÇU
    private var aiKocBolumu: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "brain.head.profile")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kariyer Koçu (AI)").font(.headline).foregroundColor(appTheme.textPrimary)
                    Text("Kişisel stratejik yorum").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }

            if let sonuc = viewModel.aiDerinYorumu {
                markdownText(sonuc)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .background(Color.purple.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.15), lineWidth: 1))
            } else if isAnalyzing {
                VStack(spacing: 14) {
                    ProgressView().scaleEffect(1.3).tint(.purple)
                    Text("Tazminat riski, gizli servetler ve kariyer çapı üzerinden sana özel derin analiz hazırlanıyor...")
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(28)
                .background(Color.purple.opacity(0.04)).cornerRadius(16)
            } else {
                Button {
                    Task { await fetchDeepAI(currentTrue: trueM1, offerTrue: trueM2, kidemRisk: kidemRisk) }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles").font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Derin Analiz Raporunu İste").font(.headline.bold())
                            Text("Tüm verilerinle kişiselleştirilmiş AI yorumu").font(.caption).opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding(18)
                    .background(LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(18)
                    .shadow(color: .purple.opacity(0.4), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.04), radius: 10)
    }

    // MARK: — 8. PDF BUTONU
    private var pdfButonu: some View {
        Button {
            olusturVePaylas()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext.fill")
                    .font(.title3.bold())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kariyer Analiz Raporu — PDF").font(.headline.bold())
                    Text("Paylaşılabilir, şık profesyonel rapor").font(.caption).opacity(0.75)
                }
                Spacer()
                if isPDFGenerating {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1A1A2E"), Color(hex: "2D2D5E")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color(hex: "1A1A2E").opacity(0.4), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func olusturVePaylas() {
        isPDFGenerating = true
        let d = viewModel.draft
        let snapshot = KiyaslamaPdfDraftSnapshot(
            mevcutBrutMaas: d.mevcutBrutMaas,
            teklifBrutMaas: d.teklifBrutMaas,
            mevcutUnvanYil: d.mevcutUnvanYil,
            mevcutUnvan: d.mevcutUnvan,
            teklifUnvan: d.teklifUnvan,
            terfiVarMi: d.terfiVarMi,
            mevcutCalismaModeli: d.mevcutCalismaModeli,
            teklifCalismaModeli: d.teklifCalismaModeli,
            mevcutSigortaTipi: d.mevcutSigortaTipi,
            teklifSigortaTipi: d.teklifSigortaTipi,
            mevcutYemekTipi: d.mevcutYemekTipi,
            teklifYemekTipi: d.teklifYemekTipi,
            mevcutGunlukYemekUcreti: d.mevcutGunlukYemekUcreti,
            teklifGunlukYemekUcreti: d.teklifGunlukYemekUcreti,
            mevcutBesVarMi: d.mevcutBesVarMi,
            teklifBesVarMi: d.teklifBesVarMi,
            mevcutYillikIzin: d.mevcutYillikIzin,
            teklifYillikIzin: d.teklifYillikIzin,
            mevcutAracSegment: d.mevcutAracSegment,
            teklifAracSegment: d.teklifAracSegment
        )
        let kirilimlarCopy = viewModel.getGizliServetKirilimi()
        let kidemMetin = viewModel.kidemAmortismanAnaliziUret()
        let s1 = sirket1
        let s2 = sirket2
        let t1 = trueM1; let t2 = trueM2
        let y1 = yalinM1; let y2 = yalinM2
        let p1 = primM1; let p2 = primM2
        let g1 = gizliM1; let g2 = gizliM2
        let kr = kidemRisk
        DispatchQueue.global(qos: .userInitiated).async {
            let data = KiyaslamaPdfOlusturucu.olustur(
                draft: snapshot,
                sirket1: s1, sirket2: s2,
                trueM1: t1, trueM2: t2,
                yalinM1: y1, yalinM2: y2,
                primM1: p1, primM2: p2,
                gizliM1: g1, gizliM2: g2,
                kidemRisk: kr,
                kirilimlar: kirilimlarCopy,
                kidemAnalizMetni: kidemMetin
            )
            DispatchQueue.main.async {
                self.pdfData = data
                self.isPDFGenerating = false
                self.showPDFShare = true
            }
        }
    }

    private func kartBaslik(ikon: String, metin: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ikon).foregroundColor(appTheme.primaryAccent).font(.title2)
            Text(metin).font(.headline).foregroundColor(appTheme.textPrimary)
        }
    }

    private func markdownText(_ str: String) -> Text {
        if let attr = try? AttributedString(markdown: str) { return Text(attr) }
        return Text(str)
    }

    private func fp(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "₺"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }
    private func fy(_ v: Double) -> String { String(format: "%.1f", v).replacingOccurrences(of: ".", with: ",") }

    private func fetchDeepAI(currentTrue: Double, offerTrue: Double, kidemRisk: Double) async {
        withAnimation { isAnalyzing = true }
        do {
            let sonuc = try await OpenAIService.shared.fetchDeepDiveAdvice(
                draft: viewModel.draft,
                currentTrue: currentTrue, offerTrue: offerTrue,
                currentHidden: gizliM1, offerHidden: gizliM2,
                kidemRisk: kidemRisk
            )
            withAnimation { viewModel.aiDerinYorumu = sonuc; isAnalyzing = false }
        } catch {
            withAnimation { viewModel.aiDerinYorumu = "Bağlantı hatası oluştu."; isAnalyzing = false }
        }
    }
}

// MARK: — DeepStackedBar (3 renk katmanı)
struct DeepStackedBar: View {
    let baslik: String
    let maas: Double; let prim: Double; let gizli: Double
    let maxDeger: Double; let animasyonBasladi: Bool; let renk: Color

    private var total: Double { maas + prim + gizli }
    private var maasR: CGFloat { maxDeger > 0 ? CGFloat(maas / maxDeger) : 0 }
    private var primR: CGFloat { maxDeger > 0 ? CGFloat(prim / maxDeger) : 0 }
    private var gizliR: CGFloat { maxDeger > 0 ? CGFloat(gizli / maxDeger) : 0 }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom) {
                Text(baslik).font(.subheadline.bold()).foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(deepFp(total)).font(.title3.weight(.heavy)).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 22)
                    if animasyonBasladi {
                        HStack(spacing: 1) {
                            if maasR > 0 {
                                Rectangle()
                                    .fill(Color(hex: "4A90E2"))
                                    .frame(width: max(geo.size.width * maasR, 8))
                            }
                            if primR > 0 {
                                Rectangle()
                                    .fill(Color(hex: "50E3C2"))
                                    .frame(width: max(geo.size.width * primR, 6))
                            }
                            if gizliR > 0 {
                                Rectangle()
                                    .fill(Color(hex: "B8E986"))
                                    .frame(width: max(geo.size.width * gizliR, 6))
                            }
                        }
                        .clipShape(Capsule())
                        .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animasyonBasladi)
                    }
                }
            }
            .frame(height: 22)

            HStack(spacing: 8) {
                if maas > 0 { miniPill(renk: Color(hex: "4A90E2"), label: "Maaş", val: maas) }
                if prim > 0 { miniPill(renk: Color(hex: "50E3C2"), label: "Prim", val: prim) }
                if gizli > 0 { miniPill(renk: Color(hex: "B8E986"), label: "Yan Hak", val: gizli) }
                Spacer()
            }
        }
        .padding(.bottom, 4)
    }

    private func miniPill(renk: Color, label: String, val: Double) -> some View {
        HStack(spacing: 4) {
            Circle().fill(renk).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text(kisaPara(val)).font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Color.white.opacity(0.05)).cornerRadius(6)
    }

    private func deepFp(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencySymbol = "₺"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }
    private func kisaPara(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v/1_000_000) }
        if v >= 1_000 { return String(format: "%.0fK", v/1_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: — GelismisReceiptRow (Mevcut sol, Teklif sağ; “↑ Daha iyi” etiketi)
struct GelismisReceiptRow: View {
    let kalem: GizliServetKalemi
    let sirket1: String; let sirket2: String
    let renk1: Color; let renk2: Color

    var body: some View {
        let m1Ust = kalem.mevcutDeger >= kalem.teklifDeger
        HStack(spacing: 12) {
            Image(systemName: kalem.ikon)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(kalem.baslik).font(.subheadline.bold())
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(receiptFp(kalem.mevcutDeger))
                            .font(.caption.bold())
                            .foregroundColor(m1Ust ? renk1 : .secondary)
                        if m1Ust {
                            Text("↑ Daha iyi")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(renk1.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(receiptFp(kalem.teklifDeger))
                            .font(.caption.bold())
                            .foregroundColor(!m1Ust ? renk2 : .secondary)
                        if !m1Ust {
                            Text("↑ Daha iyi")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(renk2.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func receiptFp(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencySymbol = "₺"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }
}

// MARK: — ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: — Aylık Net Maaş Kıyaslama (Maaş kutusuna tıklanınca açılır)
struct AylikNetMaasKiyaslamaSheet: View {
    let sirket1: String
    let sirket2: String
    let aylikNetler1: [Double]
    let aylikNetler2: [Double]
    let renk1: Color
    let renk2: Color
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss

    private var ortalama1: Double {
        guard aylikNetler1.count == 12 else { return 0 }
        return aylikNetler1.reduce(0, +) / 12
    }
    private var ortalama2: Double {
        guard aylikNetler2.count == 12 else { return 0 }
        return aylikNetler2.reduce(0, +) / 12
    }

    private func fp(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Brüt maaşta her ay yatacak net farklı olabilir; bordro motoru ile hesaplandı (prim hariç).")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Image(systemName: "banknote.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aylık Net Maaş (Ortalama)")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("Prim dahil değil")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    let maxAylik = max(ortalama1, ortalama2, 1.0)
                    VStack(spacing: 20) {
                        AylikNetMaasBar(baslik: sirket1, deger: ortalama1, maxDeger: maxAylik, renk: renk1)
                        AylikNetMaasBar(baslik: sirket2, deger: ortalama2, maxDeger: maxAylik, renk: renk2)
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
                .shadow(color: Color(hex: "1A1A2E").opacity(0.4), radius: 14, y: 6)
                .padding(.horizontal, 20)

                AylikNetMaasCizgiGrafikKarti(
                    sirket1: sirket1,
                    sirket2: sirket2,
                    aylikNetler1: aylikNetler1,
                    aylikNetler2: aylikNetler2,
                    renk1: renk1,
                    renk2: renk2
                )
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Aylık Net Maaş")
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

private struct AylikNetMaasBar: View {
    let baslik: String
    let deger: Double
    let maxDeger: Double
    let renk: Color

    private func fp(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(baslik)
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text(fp(deger))
                    .font(.headline.weight(.heavy))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 14)
                    Capsule()
                        .fill(renk)
                        .frame(width: maxDeger > 0 ? geo.size.width * CGFloat(deger / maxDeger) : 0, height: 14)
                }
            }
            .frame(height: 14)
        }
    }
}

// MARK: — Aylık net maaş çizgi grafik (iki şirket aynı grafikte, 12 ay — brütte aylar arası net farkı)
private struct AylikNetMaasCizgiGrafikKarti: View {
    let sirket1: String
    let sirket2: String
    let aylikNetler1: [Double]
    let aylikNetler2: [Double]
    let renk1: Color
    let renk2: Color

    private static let ayKisaltmalar = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]

    private func fp(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }

    private func yEksenMetin(_ val: Double) -> String {
        if val >= 1_000_000 { return String(format: "%.1fM", val / 1_000_000) }
        if val >= 1_000 { return String(format: "%.0fK", val / 1_000) }
        return String(format: "%.0f", val)
    }

    var body: some View {
        let d1 = aylikNetler1.count == 12 ? aylikNetler1 : Array(repeating: 0.0, count: 12)
        let d2 = aylikNetler2.count == 12 ? aylikNetler2 : Array(repeating: 0.0, count: 12)
        let tumDegerler = d1 + d2
        let maxVal = tumDegerler.max() ?? 1
        let minVal = 0.0  // Grafik her zaman 0'dan başlasın; "sıfır maaş" izlenimi vermesin
        let range = max(maxVal - minVal, 1.0)
        let chartH: CGFloat = 160
        let bottomPad: CGFloat = 22
        let rightPad: CGFloat = 44

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aylık Net Maaş — 12 Ay")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Text("Her ay yatacak net (brütten hesaplanan)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 0) {
                // Grafik alanı (sol + orta)
                GeometryReader { geo in
                    let chartW = max(geo.size.width - rightPad, 1)
                    ZStack(alignment: .bottomLeading) {
                        // Noktalı yatay grid (referans stili)
                        ForEach(0..<4, id: \.self) { i in
                            let yRatio = CGFloat(i) / 3.0
                            let y = bottomPad + chartH * (1 - yRatio)
                            Path { p in
                                var x: CGFloat = 0
                                while x <= chartW {
                                    p.move(to: CGPoint(x: x, y: y))
                                    p.addLine(to: CGPoint(x: min(x + 4, chartW), y: y))
                                    x += 8
                                }
                            }
                            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }

                        // Çizgi 1 — 12 noktayı birleştir
                        if !d1.allSatisfy({ $0 == 0 }) {
                            Path { p in
                                for (i, val) in d1.enumerated() {
                                    let x = i < 11 ? chartW * CGFloat(i) / 11 : chartW
                                    let yRatio = (val - minVal) / range
                                    let y = bottomPad + chartH * (1 - CGFloat(yRatio))
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(renk1, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                            // Son nokta vurgusu — şirket 1
                            let last1 = d1[11]
                            let y1 = bottomPad + chartH * (1 - CGFloat((last1 - minVal) / range))
                            ZStack {
                                Circle().fill(renk1.opacity(0.35)).frame(width: 24, height: 24).position(x: chartW, y: y1)
                                Circle().fill(renk1).frame(width: 10, height: 10).position(x: chartW, y: y1)
                            }
                        }

                        // Çizgi 2 — 12 noktayı birleştir
                        if !d2.allSatisfy({ $0 == 0 }) {
                            Path { p in
                                for (i, val) in d2.enumerated() {
                                    let x = i < 11 ? chartW * CGFloat(i) / 11 : chartW
                                    let yRatio = (val - minVal) / range
                                    let y = bottomPad + chartH * (1 - CGFloat(yRatio))
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(renk2, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                            // Son nokta vurgusu — şirket 2
                            let last2 = d2[11]
                            let y2 = bottomPad + chartH * (1 - CGFloat((last2 - minVal) / range))
                            ZStack {
                                Circle().fill(renk2.opacity(0.35)).frame(width: 24, height: 24).position(x: chartW, y: y2)
                                Circle().fill(renk2).frame(width: 10, height: 10).position(x: chartW, y: y2)
                            }
                        }
                    }
                }
                .frame(height: chartH + bottomPad)

                // Y ekseni etiketleri (sağda — referans görseldeki gibi)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(yEksenMetin(maxVal))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer().frame(height: chartH / 2 - 10)
                    Text(yEksenMetin(minVal + range / 2))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer().frame(height: chartH / 2 - 10)
                    Text(yEksenMetin(minVal))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(width: rightPad, height: chartH + bottomPad)
            }
            .frame(height: chartH + bottomPad)

            // X ekseni — aylar
            HStack(spacing: 0) {
                ForEach(Array(Self.ayKisaltmalar.enumerated()), id: \.offset) { _, ay in
                    Text(ay)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Legend + son ay değeri (Bugün / Aralık)
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle().fill(renk1).frame(width: 10, height: 10)
                    Text(sirket1).font(.caption.weight(.semibold)).foregroundColor(.white.opacity(0.9)).lineLimit(1)
                    Text(fp(d1.last ?? 0)).font(.caption.bold()).foregroundColor(renk1)
                }
                HStack(spacing: 8) {
                    Circle().fill(renk2).frame(width: 10, height: 10)
                    Text(sirket2).font(.caption.weight(.semibold)).foregroundColor(.white.opacity(0.9)).lineLimit(1)
                    Text(fp(d2.last ?? 0)).font(.caption.bold()).foregroundColor(renk2)
                }
                Spacer()
            }
            .padding(.top, 6)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 4)
    }
}
