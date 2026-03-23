import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct BrutNetView_YENI: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appTheme: AppTheme
    @Query(sort: [SortDescriptor(\AylikMaas.yil, order: .reverse), SortDescriptor(\AylikMaas.ay)]) private var aylikMaaslar: [AylikMaas]
    @State private var stableAylikMaaslar: [AylikMaas] = []
    @State private var isLoaded: Bool = false
    @State private var showMaasGirisSheet = false
    @State private var showPdfShare = false
    @State private var pdfData: Data?
    @State private var yil: Int = Calendar.current.component(.year, from: Date())
    @State private var detayTabloAcik = false
    @State private var seciliAylikDetay: AylikBrutNetDetay?
    @StateObject private var viewModel = BrutNetViewModel()
    @State private var triggerBrutFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var triggerPrimFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var yillikDetayGoster = false
    @State private var saveErrorMessage: String?
    @State private var gorundu = false

    // ── Veri seçimi (değişmedi) ───────────────────────────────
    private var yilMaaslar: [AylikMaas] {
        let source = isLoaded ? stableAylikMaaslar : aylikMaaslar
        return source.filter { $0.yil == yil }.sorted { $0.ay < $1.ay }
    }

    private var detayliSonuclar: [AylikBrutNetDetay] {
        let b = (1...12).map { ay in yilMaaslar.first { $0.ay == ay }?.brutTutar ?? 0 }
        let p = (1...12).map { ay in yilMaaslar.first { $0.ay == ay }?.primTutar ?? 0 }
        return BrutNetCalculator.hesaplaYillikDetayli(brutlar: b, primler: p)
    }

    private var gosterilenDetaylar: [AylikBrutNetDetay] {
        viewModel.hasValidInput ? viewModel.liveDetayliSonuclar : detayliSonuclar
    }

    private var toplamNet: Double { yilMaaslar.reduce(0) { $0 + $1.netTutar } }

    private var aylikOrtalamaNet: Double {
        guard !yilMaaslar.isEmpty else { return 0 }
        return toplamNet / Double(yilMaaslar.count)
    }

    private var toplamNetGosterilen: Double { viewModel.toplamNetGosterilen }

    private var aylikOrtalamaNetGosterilen: Double {
        let d = gosterilenDetaylar.filter { $0.brutToplam > 0 }
        guard !d.isEmpty else { return 0 }
        return toplamNetGosterilen / Double(d.count)
    }

    private var toplamKesintiGosterilen: Double {
        gosterilenDetaylar.reduce(0) { r, d in
            r + d.sgkIsci + d.issizlikIsci + d.aylikGelirVergisi + d.damgaVergisi
        }
    }

    private var toplamKesinti: Double {
        yilMaaslar.reduce(0) { sum, maas in
            sum + maas.kesintiler.reduce(0) { $0 + $1.tutar }
        }
    }

    private func toplamBrutNetFromDetay(_ detaylar: [AylikBrutNetDetay]) -> Double {
        detaylar.reduce(0) { $0 + $1.brutToplam }
    }

    private var veriVar: Bool { toplamBrutNetFromDetay(gosterilenDetaylar) > 0 }
    private var aktifDetaylar: [AylikBrutNetDetay] { gosterilenDetaylar.filter { $0.brutToplam > 0 } }

    private var toplamSGK: Double { aktifDetaylar.reduce(0) { $0 + $1.sgkIsci + $1.issizlikIsci } }
    private var toplamVergi: Double { aktifDetaylar.reduce(0) { $0 + $1.aylikGelirVergisi + $1.damgaVergisi } }
    private var yillikNet: Double { aktifDetaylar.reduce(0) { $0 + $1.toplamNetEleGecen } }
    private var toplamBrut: Double { aktifDetaylar.reduce(0) { $0 + $1.brutToplam } }
    private var toplamMaliyet: Double { aktifDetaylar.reduce(0) { $0 + $1.toplamMaliyet } }

    private var netOran: Double { toplamBrut > 0 ? yillikNet / toplamBrut : 0 }
    private var sgkOran: Double { toplamBrut > 0 ? toplamSGK / toplamBrut : 0 }
    private var vergiOran: Double { toplamBrut > 0 ? toplamVergi / toplamBrut : 0 }
    private var aylikOrtNet: Double { aktifDetaylar.isEmpty ? 0 : yillikNet / Double(aktifDetaylar.count) }
    private var gunlukNet: Double { aylikOrtNet > 0 ? aylikOrtNet / 22.0 : 0 }

    private func vergiDilimiOraniVeVurgu(_ kum: Double) -> (oran: Double, is20: Bool, is27: Bool) {
        if kum <= 0 { return (0.15, false, false) }
        if kum <= 190_000 { return (0.15, false, false) }
        if kum <= 400_000 { return (0.20, true, false) }
        if kum <= 1_500_000 { return (0.27, false, true) }
        if kum <= 5_000_000 { return (0.35, false, false) }
        return (0.40, false, false)
    }

    private func vergiDilimiDegisti(detay: AylikBrutNetDetay, tumDetaylar: [AylikBrutNetDetay]) -> Bool {
        let onceki = tumDetaylar.first { $0.ay == detay.ay - 1 }?.kumulatifVergiMatrahi ?? 0
        let (buAy, is20, is27) = vergiDilimiOraniVeVurgu(detay.kumulatifVergiMatrahi)
        let (oncekiOran, _, _) = vergiDilimiOraniVeVurgu(onceki)
        return buAy > oncekiOran && (is20 || is27)
    }

    private func vergiDilimiDegistiCaption(_ detay: AylikBrutNetDetay, _ tumDetaylar: [AylikBrutNetDetay]) -> String? {
        let (_, is20, is27) = vergiDilimiOraniVeVurgu(detay.kumulatifVergiMatrahi)
        guard vergiDilimiDegisti(detay: detay, tumDetaylar: tumDetaylar) else { return nil }
        if is20 { return "%20 Dilimine Girildi" }
        if is27 { return "%27 Dilimine Girildi" }
        return nil
    }

    private func ayBarRenk(_ detay: AylikBrutNetDetay) -> Color {
        let (_, is20, is27) = vergiDilimiOraniVeVurgu(detay.kumulatifVergiMatrahi)
        if is27 { return Color(hex: "F87171") }
        if is20 { return Color(hex: "60A5FA") }
        return Color(hex: "34D399")
    }

    var body: some View {
        ZStack {
            appTheme.backgroundMain.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroBant
                        .opacity(gorundu ? 1 : 0)
                        .animation(.easeOut(duration: 0.35), value: gorundu)

                    VStack(spacing: 14) {
                        compactGirisKarti
                            .opacity(gorundu ? 1 : 0)
                            .offset(y: gorundu ? 0 : 12)
                            .animation(.spring(response: 0.5).delay(0.06), value: gorundu)

                        if veriVar {
                            dagilimSeridi
                                .opacity(gorundu ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(0.10), value: gorundu)
                            aylikBarChart
                                .opacity(gorundu ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(0.14), value: gorundu)
                            vergiTakvimiDikey
                                .opacity(gorundu ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(0.18), value: gorundu)
                            icgoruleGrid
                                .opacity(gorundu ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(0.22), value: gorundu)
                            detayTabloButonu
                                .opacity(gorundu ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(0.26), value: gorundu)
                            pdfButonu
                                .opacity(gorundu ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(0.30), value: gorundu)
                        } else {
                            bosDurum
                        }
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationTitle("Bordro Analizi")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.backgroundMain, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { }
        .sheet(isPresented: $showMaasGirisSheet) {
            MaasGirisSheetView(yil: yil, mevcutMaaslar: yilMaaslar, onSaveMaas: { setAylikMaas($0) }) {
                showMaasGirisSheet = false
            }
            .environmentObject(appTheme)
        }
        .sheet(item: $seciliAylikDetay) { detay in
            AylikKesintiDetaySheet(detay: detay).environmentObject(appTheme)
        }
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData { PdfShareSheet(pdfData: data) }
        }
        .alert("Kaydetme Hatası", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("Tamam") { saveErrorMessage = nil }
        } message: {
            if let msg = saveErrorMessage { Text(msg) }
        }
        .onAppear {
            if !isLoaded {
                stableAylikMaaslar = aylikMaaslar
                isLoaded = true
            }
            yilMaaslariFormaYukle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { gorundu = true }
        }
        .onChange(of: aylikMaaslar) { old, new in
            guard old.count != new.count ||
                old.last?.id != new.last?.id ||
                old.last?.netTutar != new.last?.netTutar else { return }
            withAnimation { stableAylikMaaslar = new }
        }
    }

    // MARK: ─ Hero Bant
    private var heroBant: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E293B")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 200)

            Circle()
                .fill(Color(hex: "34D399").opacity(0.10))
                .frame(width: 220).blur(radius: 45)
                .offset(x: UIScreen.main.bounds.width * 0.55, y: -20)

            Image(systemName: "chart.pie.fill")
                .font(.system(size: 110, weight: .black))
                .foregroundColor(.white.opacity(0.03))
                .offset(x: UIScreen.main.bounds.width * 0.44, y: 8)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.3)) { yil -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 28, height: 28)
                    }
                    Text(verbatim: String(yil))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 42, alignment: .center)
                    Button {
                        withAnimation(.spring(response: 0.3)) { yil += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 28, height: 28)
                    }
                }
                .background(Color.white.opacity(0.07))
                .clipShape(Capsule())
                .padding(.bottom, 16)

                if veriVar {
                    HStack(spacing: 1) {
                        metrikHucresi("Aylık Net",       formatTLKisa(aylikOrtNet),          Color(hex: "34D399"))
                        Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 46)
                        metrikHucresi("Yıllık Toplam",   formatTLKisa(yillikNet),             .white)
                        Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 46)
                        metrikHucresi("Toplam Kesinti",  formatTLKisa(toplamSGK + toplamVergi), Color(hex: "F87171"))
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                    )
                } else {
                    Text("Bordro Analizi")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Maaş bilgilerini girerek yıllık analizini gör")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.50))
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .frame(height: 200)
    }

    private func metrikHucresi(_ etiket: String, _ deger: String, _ renk: Color) -> some View {
        VStack(spacing: 4) {
            Text(etiket)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .lineLimit(1)
            Text(deger)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(renk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5), value: deger)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: ─ Compact Giriş Kartı
    private var compactGirisKarti: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(appTheme.warningColor)
                Text("MAAŞ GİRİŞİ")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.4)
                Spacer()
                Button {
                    showMaasGirisSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text("Ay ay")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(appTheme.warningColor)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(appTheme.warningColor.opacity(0.10))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                girisAlani("Aylık Brüt (₺)", placeholder: "0",
                           binding: bindingBrutForAy(1),
                           focus: $triggerBrutFocus[0],
                           renk: Color(hex: "0EA5E9"))
                girisAlani("Yıllık Prim (₺)", placeholder: "0",
                           binding: bindingPrimForAy(1),
                           focus: $triggerPrimFocus[0],
                           renk: Color(hex: "8B5CF6"))
            }

            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                maasGirisKaydet()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Hesapla & Kaydet")
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    LinearGradient(colors: [appTheme.warningColor, appTheme.warningColor.opacity(0.80)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: appTheme.warningColor.opacity(0.32), radius: 8, y: 3)
            }
            .buttonStyle(PressButtonStyle())
        }
        .padding(16)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private func girisAlani(_ etiket: String, placeholder: String,
                             binding: Binding<String>,
                             focus: Binding<Bool>, renk: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(etiket)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(appTheme.textSecondary)
            FormattedNumberField(
                text: binding,
                placeholder: placeholder,
                allowDecimals: false,
                focusTrigger: focus,
                fontSize: 17,
                fontWeight: .bold,
                isLightMode: appTheme.isLight,
                onCommit: { maasGirisKaydet() }
            )
            .padding(.horizontal, 12).padding(.vertical, 12)
            .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(renk.opacity(0.22), lineWidth: 1.2))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: ─ Dağılım Şeridi (donut yerine)
    private var dagilimSeridi: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(appTheme.textSecondary)
                Text("GELİR DAĞILIMI")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("Brüt \(Int(netOran * 100 + sgkOran * 100 + vergiOran * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(appTheme.textSecondary)
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    let totalW = geo.size.width
                    let netW = max(totalW * netOran, 8)
                    let sgkW = max(totalW * sgkOran, 8)
                    let taxW = max(totalW * vergiOran, 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(hex: "34D399"))
                        .frame(width: netW)
                        .animation(.spring(response: 0.6), value: netOran)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(hex: "60A5FA"))
                        .frame(width: sgkW)
                        .animation(.spring(response: 0.6), value: sgkOran)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(hex: "FB923C"))
                        .frame(width: taxW)
                        .animation(.spring(response: 0.6), value: vergiOran)
                }
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            HStack(spacing: 16) {
                legendItem(Color(hex: "34D399"), "Net %\(Int(netOran * 100))", formatTLKisa(yillikNet))
                legendItem(Color(hex: "60A5FA"), "SGK %\(Int(sgkOran * 100))", formatTLKisa(toplamSGK))
                legendItem(Color(hex: "FB923C"), "Vergi %\(Int(vergiOran * 100))", formatTLKisa(toplamVergi))
            }
        }
        .padding(16)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private func legendItem(_ renk: Color, _ etiket: String, _ tutar: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(renk).frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(etiket)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
                Text(tutar)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: ─ Aylık Bar Chart
    private var aylikBarChart: some View {
        let detaylar = gosterilenDetaylar
        let maksNet = detaylar.map { $0.toplamNetEleGecen }.max() ?? 1
        let tumDetaylar = gosterilenDetaylar

        return VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(appTheme.textSecondary)
                Text("AYLIK NET MAAŞ")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("Tüm yıl")
                    .font(.system(size: 10))
                    .foregroundColor(appTheme.textSecondary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(1...12, id: \.self) { ay in
                    let detay = detaylar.first { $0.ay == ay }
                    let net = detay?.toplamNetEleGecen ?? 0
                    let oran = net > 0 ? net / maksNet : 0
                    let renk = detay.map { ayBarRenk($0) } ?? appTheme.textSecondary.opacity(0.15)
                    let dilimGecti = detay.map { vergiDilimiDegisti(detay: $0, tumDetaylar: tumDetaylar) } ?? false

                    VStack(spacing: 3) {
                        if dilimGecti {
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 7, weight: .black))
                                .foregroundColor(renk)
                        } else {
                            Color.clear.frame(height: 10)
                        }

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(appTheme.isLight ? Color(white: 0.93) : Color.white.opacity(0.06))
                                .frame(height: 72)
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(renk)
                                .frame(height: max(CGFloat(oran) * 72, net > 0 ? 4 : 0))
                                .animation(.spring(response: 0.5).delay(Double(ay) * 0.03), value: net)
                        }
                        .frame(height: 72)
                        .onTapGesture {
                            if let d = detay { seciliAylikDetay = d }
                        }

                        Text(String(Aylar.isim(ay: ay).prefix(1)))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(dilimGecti ? renk : appTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 92)

            HStack(spacing: 14) {
                barLegend(Color(hex: "34D399"), "%15 dilim")
                barLegend(Color(hex: "60A5FA"), "%20 dilim")
                barLegend(Color(hex: "F87171"), "%27 dilim")
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(appTheme.warningColor)
                    Text("dilim geçişi")
                        .font(.system(size: 10))
                        .foregroundColor(appTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private func barLegend(_ renk: Color, _ etiket: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(renk)
                .frame(width: 10, height: 10)
            Text(etiket)
                .font(.system(size: 10))
                .foregroundColor(appTheme.textSecondary)
        }
    }

    // MARK: ─ Vergi Dilimi Takvimi — Dikey
    private var vergiTakvimiDikey: some View {
        let detaylar = gosterilenDetaylar
        let tumDetaylar = gosterilenDetaylar
        let maksKum = min(detaylar.map { $0.kumulatifVergiMatrahi }.max() ?? 400_000, 5_000_000)

        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(appTheme.textSecondary)
                Text("VERGİ DİLİMİ TAKVİMİ")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("Aylık net & dilim")
                    .font(.system(size: 10))
                    .foregroundColor(appTheme.textSecondary)
            }
            .padding(16)

            Rectangle()
                .fill(appTheme.cardStroke.opacity(0.25))
                .frame(height: 0.5)

            ForEach(1...12, id: \.self) { ay in
                let detay = detaylar.first { $0.ay == ay }
                let kum = detay?.kumulatifVergiMatrahi ?? 0
                let aylikNet = detay?.toplamNetEleGecen ?? 0
                let (oran, is20, is27) = vergiDilimiOraniVeVurgu(kum)
                let dilimGecti = detay.map { vergiDilimiDegisti(detay: $0, tumDetaylar: tumDetaylar) } ?? false
                let progress = maksKum > 0 ? min(kum / maksKum, 1.0) : 0
                let barRenk: Color = is27 ? Color(hex: "F87171") : (is20 ? Color(hex: "60A5FA") : Color(hex: "34D399"))
                let vurguBG: Color = dilimGecti ? (is27 ? Color(hex: "F87171").opacity(0.06) : Color(hex: "60A5FA").opacity(0.06)) : Color.clear

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Text(String(Aylar.isim(ay: ay).prefix(3)) + ".")
                            .font(.system(size: 12, weight: dilimGecti ? .bold : .regular))
                            .foregroundColor(dilimGecti ? barRenk : appTheme.textSecondary)
                            .frame(width: 36, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(appTheme.isLight ? Color(white: 0.92) : Color.white.opacity(0.07))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barRenk)
                                    .frame(width: max(geo.size.width * progress, kum > 0 ? 4 : 0), height: 6)
                                    .animation(.spring(response: 0.5).delay(Double(ay) * 0.03), value: kum)
                            }
                        }
                        .frame(height: 6)

                        HStack(spacing: 10) {
                            Text(aylikNet > 0 ? formatTLKisa(aylikNet) : "—")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(appTheme.textSecondary.opacity(0.75))
                                .lineLimit(1)

                            HStack(spacing: 3) {
                                Text("%\(Int(oran * 100))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(barRenk)
                                if dilimGecti {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundColor(barRenk)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(vurguBG)

                    if ay < 12 {
                        Rectangle()
                            .fill(appTheme.cardStroke.opacity(0.12))
                            .frame(height: 0.5)
                            .padding(.leading, 62)
                    }
                }
                .onTapGesture {
                    if let d = detay { seciliAylikDetay = d }
                }
            }
        }
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    // MARK: ─ İçgörü Grid
    private var icgoruleGrid: some View {
        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            icgoruleKarti(
                etiket: "Yıllık Net Toplam",
                deger: formatTL(yillikNet),
                altyazi: "Eline geçen",
                ikon: "sum",
                renk: Color(hex: "34D399"),
                koyu: true
            )
            icgoruleKarti(
                etiket: "Günlük Net",
                deger: formatTLKisa(gunlukNet),
                altyazi: "22 iş günü",
                ikon: "sun.max.fill",
                renk: Color(hex: "3B82F6"),
                koyu: false
            )
            icgoruleKarti(
                etiket: "Şirket Maliyeti",
                deger: formatTLKisa(toplamMaliyet),
                altyazi: "İşveren yıllık",
                ikon: "building.2.fill",
                renk: Color(hex: "8B5CF6"),
                koyu: false
            )
            icgoruleKarti(
                etiket: "Net / Brüt",
                deger: "%\(Int(netOran * 100))",
                altyazi: "Ortalama oran",
                ikon: "percent",
                renk: Color(hex: "F59E0B"),
                koyu: false
            )
        }
    }

    private func icgoruleKarti(etiket: String, deger: String, altyazi: String,
                                ikon: String, renk: Color, koyu: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: ikon)
                    .font(.system(size: 11))
                    .foregroundColor(koyu ? renk : renk)
                Text(etiket)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(koyu ? .white.opacity(0.45) : appTheme.textSecondary)
                    .lineLimit(1)
            }
            Text(deger)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(koyu ? renk : renk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5), value: deger)
            Text(altyazi)
                .font(.system(size: 10))
                .foregroundColor(koyu ? .white.opacity(0.30) : appTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(koyu ? Color(hex: "0F172A") : appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(koyu ? renk.opacity(0.20) : appTheme.cardStroke.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: koyu ? renk.opacity(0.18) : .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    // MARK: ─ Detay Tablo Butonu
    private var detayTabloButonu: some View {
        Button {
            detayTabloAcik = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(appTheme.primaryAccent.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(appTheme.primaryAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aylık Detay Tablosu")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(appTheme.textPrimary)
                    Text("Vergi dilimleri ve tüm kesintiler")
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary.opacity(0.4))
            }
            .padding(14)
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
        }
        .buttonStyle(PressButtonStyle())
        .sheet(isPresented: $detayTabloAcik) {
            FullDetayTableView(detaylar: gosterilenDetaylar, yil: yil)
                .environmentObject(appTheme)
        }
    }

    // MARK: ─ PDF Butonu
    private var pdfButonu: some View {
        Button {
            pdfData = BrutNetPdfOlusturucu.olustur(detaylar: gosterilenDetaylar, yil: yil, baslik: "Bordro Özeti")
            showPdfShare = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bordro PDF Oluştur")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("Tüm yıl, tablo + analiz")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(14)
            .background(Color(hex: "0F172A"))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(PressButtonStyle())
    }

    // MARK: ─ Boş Durum
    private var bosDurum: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(appTheme.textSecondary.opacity(0.4))
            Text("Henüz maaş verisi yok")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(appTheme.textPrimary)
            Text("Brüt maaşını gir, anlık bordro analizi görün")
                .font(.system(size: 14))
                .foregroundColor(appTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    // MARK: ─ Veri yönetimi (değişmedi)
    private func yilMaaslariFormaYukle() {
        var newBrut = viewModel.brutlar
        var newPrim = viewModel.primler
        for maas in yilMaaslar {
            let ay = maas.ay
            guard ay >= 1, ay <= 12 else { continue }
            let i = ay - 1
            if maas.brutTutar > 0 { newBrut[i] = "\(Int(maas.brutTutar))" }
            if maas.primTutar > 0 { newPrim[i] = "\(Int(maas.primTutar))" }
        }
        viewModel.brutlar = newBrut
        viewModel.primler = newPrim
    }

    private func bindingBrutForAy(_ ay: Int) -> Binding<String> {
        let idx = ay - 1
        return Binding(
            get: { viewModel.brutlar[idx] },
            set: { newValue in
                var copy = viewModel.brutlar
                for i in idx..<12 { copy[i] = newValue }
                viewModel.brutlar = copy
            }
        )
    }

    private func bindingPrimForAy(_ ay: Int) -> Binding<String> {
        Binding(
            get: { viewModel.primler[ay - 1] },
            set: { viewModel.primler[ay - 1] = $0 }
        )
    }

    private func maasGirisKaydet() {
        viewModel.saveToDatabase(context: modelContext, yil: yil)
        MaasAlarmService.shared.planla(detaylar: gosterilenDetaylar, yil: yil)
    }

    private func setAylikMaas(_ maas: AylikMaas) {
        let existing = aylikMaaslar.first { $0.ay == maas.ay && $0.yil == maas.yil }
        if let existing {
            existing.brutTutar = maas.brutTutar
            existing.primTutar = maas.primTutar
            existing.netTutar = maas.netTutar
            existing.kesintiler = maas.kesintiler
        } else {
            modelContext.insert(maas)
        }
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "Maaş verisi kaydedilirken bir hata oluştu."
        }
    }

    private func formatTL(_ d: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: d)) ?? "0") + " ₺"
    }

    private func formatTLKisa(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.1fM ₺", d / 1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK ₺", d / 1_000) }
        return String(format: "%.0f ₺", d)
    }
}

@MainActor
final class MaasAlarmService: ObservableObject {
    static let shared = MaasAlarmService()

    @Published var bildirimIzniVar = false
    @Published var alarmAktif: Bool {
        didSet { UserDefaults.standard.set(alarmAktif, forKey: "maas_alarm_aktif") }
    }
    @Published var maasGunu: Int {
        didSet { UserDefaults.standard.set(maasGunu, forKey: "maas_gunu") }
    }

    private init() {
        alarmAktif = UserDefaults.standard.bool(forKey: "maas_alarm_aktif")
        maasGunu = UserDefaults.standard.integer(forKey: "maas_gunu")
        if maasGunu == 0 { maasGunu = 15 }
    }

    func setup() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            bildirimIzniVar = settings.authorizationStatus == .authorized
        }
    }

    func izinIste() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            bildirimIzniVar = granted
            if granted { alarmAktif = true }
        } catch {
            bildirimIzniVar = false
        }
    }

    func planla(detaylar: [AylikBrutNetDetay], yil: Int) {
        guard alarmAktif else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (1...12).map { "maas_gunu_\(yil)_\($0)" })

        for detay in detaylar where detay.brutToplam > 0 {
            let content = UNMutableNotificationContent()
            content.title = "Maas Gunu"
            content.body = "\(Aylar.isim(ay: detay.ay)) net maasin yaklasik \(formatTL(detay.toplamNetEleGecen))."
            content.sound = .default

            var date = DateComponents()
            date.year = yil
            date.month = detay.ay
            date.day = min(max(maasGunu, 1), 28)
            date.hour = 8
            date.minute = 30

            let req = UNNotificationRequest(
                identifier: "maas_gunu_\(yil)_\(detay.ay)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            )
            center.add(req)
        }
    }

    private func formatTL(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "tr_TR")
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: v)) ?? "0") + " ₺"
    }
}

struct MaasAlarmAyarlariView: View {
    @EnvironmentObject var appTheme: AppTheme
    @ObservedObject var service = MaasAlarmService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Maas Alarmlari", systemImage: "bell.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                Spacer()
            }

            if !service.bildirimIzniVar {
                Button {
                    Task { await service.izinIste() }
                } label: {
                    Text("Bildirimlere Izin Ver")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(hex: "F59E0B"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Toggle("Alarmlar aktif", isOn: $service.alarmAktif)
                    .tint(Color(hex: "F59E0B"))
                if service.alarmAktif {
                    Picker("Maas Gunu", selection: $service.maasGunu) {
                        ForEach(1...28, id: \.self) { gun in
                            Text("Ayin \(gun)'i").tag(gun)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(14)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

