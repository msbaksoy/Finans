import SwiftUI

struct SurveyEngineView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appTheme: AppTheme
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel

    @State var currentStep = 1
    let totalSteps = 9

    @State var mevcutSirketYil: Double = 1
    @State var mevcutMaasSayisi: Int = 12
    @State var teklifMaasSayisi: Int = 12

    @State var terfiDurumu: String = ""
    @State var terfiKademesi: String = ""

    @State var mevcutCalismaModeli: String = ""
    @State var mevcutHibritGun: Double = 2
    @State var teklifCalismaModeli: String = ""
    @State var teklifHibritGun: Double = 2

    @State var mevcutUlasimTipi: String = ""
    @State var mevcutAracSegment: String = ""
    @State var mevcutYakitKarsilayan: String = ""
    @State var mevcutYakitTutari: String = ""
    @State var mevcutTopluTutar: String = ""
    @State var mevcutTopluKarsilayan: String = ""

    @State var teklifUlasimTipi: String = ""
    @State var teklifAracSegment: String = ""
    @State var teklifYakitKarsilayan: String = ""
    @State var teklifYakitTutari: String = ""
    @State var teklifTopluTutar: String = ""
    @State var teklifTopluKarsilayan: String = ""

    // Remote çalışanlar için: araç tahsis + yakıt desteği akışı
    @State var mevcutRemoteAracTahsisVarMi: Bool? = nil
    @State var mevcutRemoteYakitDestegiVarMi: Bool? = nil
    @State var mevcutRemoteYakitAylikTL: String = ""
    @State var teklifRemoteAracTahsisVarMi: Bool? = nil
    @State var teklifRemoteYakitDestegiVarMi: Bool? = nil
    @State var teklifRemoteYakitAylikTL: String = ""

    @State var mevcutYemekTipi: String = ""
    @State var mevcutYemekPuan: Int = 3
    @State var mevcutGunlukYemek: String = ""

    @State var teklifYemekTipi: String = ""
    @State var teklifYemekPuan: Int = 3
    @State var teklifGunlukYemek: String = ""

    @State var mevcutSaglikTipi: String = ""
    @State var mevcutSaglikAile: Bool? = nil
    @State var mevcutSaglikKisiSayisi: Int = 2
    @State var teklifSaglikTipi: String = ""
    @State var teklifSaglikAile: Bool? = nil
    @State var teklifSaglikKisiSayisi: Int = 2

    @State var mevcutBesVarMi: Bool? = nil
    @State var mevcutBesTutar: String = ""
    @State var teklifBesVarMi: Bool? = nil
    @State var teklifBesTutar: String = ""

    @State var mevcutYillikIzin: Int = 14
    @State var teklifYillikIzin: Int = 14

    @FocusState var isInputActive: Bool

    var onFinish: (() -> Void)? = nil

    private var segmentSecenekleri: [String] { AracSegmentBilgisi.segmentler.filter { $0 != "Yok" } }

    var mevcutSirketLabel: String {
        let ad = viewModel.draft.mevcutSirketAdi.trimmingCharacters(in: .whitespacesAndNewlines)
        return ad.isEmpty ? "Mevcut İş" : ad
    }
    var teklifSirketLabel: String {
        let ad = viewModel.draft.teklifSirketAdi.trimmingCharacters(in: .whitespacesAndNewlines)
        return ad.isEmpty ? "Yeni Teklif" : ad
    }

    private let stepMeta: [(ikon: String, baslik: String, renk: String)] = [
        ("building.2.fill", "Mevcut İşin", "3B82F6"),
        ("sparkles", "Yeni Teklif", "8B5CF6"),
        ("arrow.up.right.circle.fill", "Kariyer Adımı", "10B981"),
        ("laptopcomputer", "Çalışma Modeli", "3B82F6"),
        ("car.fill", "Ulaşım", "F59E0B"),
        ("fork.knife", "Yemek", "EF4444"),
        ("cross.case.fill", "Sağlık", "10B981"),
        ("umbrella.fill", "BES", "8B5CF6"),
        ("beach.umbrella.fill", "Yıllık İzin", "F59E0B"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            appTheme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 0) {
                stepHeader

                ZStack {
                    Group {
                        if currentStep == 1 { step1_MevcutTemel }
                        else if currentStep == 2 { step2_TeklifTemel }
                        else if currentStep == 3 { step3_Terfi }
                        else if currentStep == 4 { step4_CalismaDuzeni }
                        else if currentStep == 5 { step5_Ulasim }
                        else if currentStep == 6 { step6_Yemek }
                        else if currentStep == 7 { step7_Saglik }
                        else if currentStep == 8 { step8_BES }
                        else if currentStep == 9 { step9_YillikIzin }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
                    .id(currentStep)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture { isInputActive = false }

                Color.clear.frame(height: 100)
            }

            stickyDevamButonu
        }
        .onAppear { syncDraftToLocalState() }
    }

    private var stepHeader: some View {
        let meta = stepMeta[currentStep - 1]
        let renk = Color(hex: meta.renk)
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button(action: prevStep) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .foregroundColor(appTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                Spacer()
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(renk.opacity(0.15)).frame(width: 32, height: 32)
                        Image(systemName: meta.ikon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(renk)
                    }
                    Text(meta.baslik)
                        .font(.subheadline.bold())
                        .foregroundColor(appTheme.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(appTheme.cardSurface)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                Spacer()
                Button("İptal") { dismiss() }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            HStack(spacing: 4) {
                ForEach(1...totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep ? renk : Color.gray.opacity(0.15))
                        .frame(height: 4)
                        .animation(.spring(response: 0.4), value: currentStep)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .background(appTheme.backgroundMain)
    }

    private var stickyDevamButonu: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [appTheme.backgroundMain.opacity(0), appTheme.backgroundMain],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 30)
            .allowsHitTesting(false)
            HStack(spacing: 12) {
                if viewModel.draft.mevcutBrutMaas > 0 || viewModel.draft.teklifBrutMaas > 0 {
                    LiveWealthTicker(viewModel: viewModel)
                        .environmentObject(appTheme)
                }
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isInputActive = false
                    handleNextStep()
                }) {
                    HStack(spacing: 8) {
                        Text(currentStep == totalSteps ? "Analizi Göster" : "Devam")
                            .font(.headline.bold())
                        Image(systemName: currentStep == totalSteps ? "chart.bar.fill" : "arrow.right")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: stepMeta[currentStep - 1].renk), Color(hex: stepMeta[currentStep - 1].renk).opacity(0.8)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color(hex: stepMeta[currentStep - 1].renk).opacity(0.35), radius: 10, y: 5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .background(appTheme.backgroundMain)
        }
    }

    /// Analiz sayfasından geri dönüldüğünde draft’taki seçimleri forma geri yükler.
    private func syncDraftToLocalState() {
        let d = viewModel.draft
        terfiDurumu = d.terfiVarMi ? "Terfi" : "Yatay"
        let kademeIsimler = ["", "Giriş (Junior)", "Orta (Mid-Level)", "Kıdemli (Senior)", "Yönetim (Manager)", "C-Level / Direktör"]
        if d.teklifUnvanRank >= 1, d.teklifUnvanRank <= 5 { terfiKademesi = kademeIsimler[d.teklifUnvanRank] }
        mevcutCalismaModeli = d.mevcutCalismaModeli
        mevcutHibritGun = d.mevcutOfisGunSayisi > 0 ? Double(d.mevcutOfisGunSayisi) : 2
        teklifCalismaModeli = d.teklifCalismaModeli
        teklifHibritGun = d.teklifOfisGunSayisi > 0 ? Double(d.teklifOfisGunSayisi) : 2
        // Ulaşım
        if d.mevcutSirketAraciVarMi {
            mevcutUlasimTipi = "Şirket Aracı"
            mevcutRemoteAracTahsisVarMi = true
        } else if d.mevcutUlasimKalitesi == "Kendi Aracım" {
            mevcutUlasimTipi = "Şahsi Araç"
        } else if d.mevcutUlasimKalitesi == "Toplu Taşıma" {
            mevcutUlasimTipi = "Toplu Ulaşım"
        } else if d.mevcutUlasimKalitesi == "Servis" {
            mevcutUlasimTipi = "Servis"
        } else if !d.mevcutUlasimKalitesi.isEmpty {
            mevcutUlasimTipi = d.mevcutUlasimKalitesi
        }
        mevcutAracSegment = AracSegmentBilgisi.gosterimDegeri(draft: d.mevcutAracSegment)
        if mevcutAracSegment == "SUV" { mevcutAracSegment = "J" }
        mevcutTopluTutar = d.mevcutTopluTasimaTutar
        mevcutTopluKarsilayan = d.mevcutTopluTasimaDestekVarMi ? "Şirket" : (d.mevcutTopluTasimaTutar.isEmpty ? "" : "Ben")
        mevcutYakitTutari = d.mevcutKendiAracAylikGider
        mevcutYakitKarsilayan = d.mevcutKendiAracGiderKimin.isEmpty ? "" : (d.mevcutKendiAracGiderKimin == "Şirket" ? "Şirket" : "Ben")
        if !d.mevcutYakitDestekTutar.isEmpty {
            mevcutRemoteYakitDestegiVarMi = true
            mevcutRemoteYakitAylikTL = d.mevcutYakitDestekTutar
        }
        if d.teklifSirketAraciVarMi {
            teklifUlasimTipi = "Şirket Aracı"
            teklifRemoteAracTahsisVarMi = true
        } else if d.teklifUlasimKalitesi == "Kendi Aracım" {
            teklifUlasimTipi = "Şahsi Araç"
        } else if d.teklifUlasimKalitesi == "Toplu Taşıma" {
            teklifUlasimTipi = "Toplu Ulaşım"
        } else if d.teklifUlasimKalitesi == "Servis" {
            teklifUlasimTipi = "Servis"
        } else if !d.teklifUlasimKalitesi.isEmpty {
            teklifUlasimTipi = d.teklifUlasimKalitesi
        }
        teklifAracSegment = AracSegmentBilgisi.gosterimDegeri(draft: d.teklifAracSegment)
        if teklifAracSegment == "SUV" { teklifAracSegment = "J" }
        teklifTopluTutar = d.teklifTopluTasimaTutar
        teklifTopluKarsilayan = d.teklifTopluTasimaDestekVarMi ? "Şirket" : (d.teklifTopluTasimaTutar.isEmpty ? "" : "Ben")
        teklifYakitTutari = d.teklifKendiAracAylikGider
        teklifYakitKarsilayan = d.teklifKendiAracGiderKimin.isEmpty ? "" : (d.teklifKendiAracGiderKimin == "Şirket" ? "Şirket" : "Ben")
        if !d.teklifYakitDestekTutar.isEmpty {
            teklifRemoteYakitDestegiVarMi = true
            teklifRemoteYakitAylikTL = d.teklifYakitDestekTutar
        }
        // Yemek
        mevcutYemekTipi = d.mevcutYemekTipi
        mevcutYemekPuan = d.mevcutYemekLezzetYildiz > 0 ? d.mevcutYemekLezzetYildiz : 3
        mevcutGunlukYemek = d.mevcutGunlukYemekUcreti > 0 ? String(Int(d.mevcutGunlukYemekUcreti)) : ""
        teklifYemekTipi = d.teklifYemekTipi
        teklifYemekPuan = d.teklifYemekLezzetYildiz > 0 ? d.teklifYemekLezzetYildiz : 3
        teklifGunlukYemek = d.teklifGunlukYemekUcreti > 0 ? String(Int(d.teklifGunlukYemekUcreti)) : ""
        // Sağlık
        if d.mevcutSigortaTipi == "Özel" { mevcutSaglikTipi = "ÖSS" }
        else if d.mevcutSigortaTipi == "Tamamlayıcı" { mevcutSaglikTipi = "TSS" }
        else { mevcutSaglikTipi = d.mevcutSigortaTipi.isEmpty ? "" : d.mevcutSigortaTipi }
        mevcutSaglikKisiSayisi = max(2, min(10, d.mevcutSigortaYararlananKisiSayisi))
        mevcutSaglikAile = d.mevcutSigortaYararlananKisiSayisi > 1
        if d.teklifSigortaTipi == "Özel" { teklifSaglikTipi = "ÖSS" }
        else if d.teklifSigortaTipi == "Tamamlayıcı" { teklifSaglikTipi = "TSS" }
        else { teklifSaglikTipi = d.teklifSigortaTipi.isEmpty ? "" : d.teklifSigortaTipi }
        teklifSaglikKisiSayisi = max(2, min(10, d.teklifSigortaYararlananKisiSayisi))
        teklifSaglikAile = d.teklifSigortaYararlananKisiSayisi > 1
        // BES
        mevcutBesVarMi = d.mevcutBesVarMi ? true : false
        mevcutBesTutar = d.mevcutBesAylikKatki
        teklifBesVarMi = d.teklifBesVarMi ? true : false
        teklifBesTutar = d.teklifBesAylikKatki
        // Yıllık izin
        mevcutYillikIzin = d.mevcutYillikIzin
        teklifYillikIzin = d.teklifYillikIzin
        // Maas sayisi (step 1/2)
        mevcutMaasSayisi = d.mevcutMaasSayisi
        teklifMaasSayisi = d.teklifMaasSayisi
    }

    // MARK: - ADIM 1: MEVCUT İŞ
    private var step1_MevcutTemel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Mevcut işinle başlayalım")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)

                VStack(spacing: 14) {
                    CompanyAutocompleteField(placeholder: "Şirket Adını Yaz", text: Binding(get: { viewModel.draft.mevcutSirketAdi }, set: { viewModel.draft.mevcutSirketAdi = $0 }))
                    CustomTextField(placeholder: "Unvanın  (Örn: Kıdemli Uzman)", text: Binding(get: { viewModel.draft.mevcutUnvan }, set: { viewModel.draft.mevcutUnvan = $0 }))
                        .focused($isInputActive)
                }
                .padding(16)
                .background(viewModel.currentCompanyColor.opacity(0.04))
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(viewModel.currentCompanyColor.opacity(0.15), lineWidth: 1))

                VStack(spacing: 20) {
                    sliderSatiri(baslik: "Bu şirkette kaç yıldır çalışıyorsun?", deger: $mevcutSirketYil, aralik: 0...30, renk: viewModel.currentCompanyColor)
                    sliderSatiri(baslik: "Mevcut unvanda kaç yıldır çalışıyorsun?", deger: Binding(get: { Double(viewModel.draft.mevcutUnvanYil) }, set: { viewModel.draft.mevcutUnvanYil = Int($0) }), aralik: 0...20, renk: viewModel.currentCompanyColor)
                }

                maasGirisBloku(baslik: "Aylık Ücretin", maasStr: $viewModel.mevcutMaasStr, brutMu: Binding(get: { viewModel.draft.mevcutMaasBrutMu }, set: { viewModel.draft.mevcutMaasBrutMu = $0 }), maasSayisi: $mevcutMaasSayisi, primStr: $viewModel.mevcutPrimStr, renk: viewModel.currentCompanyColor)

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - ADIM 2: TEKLİF
    private var step2_TeklifTemel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Şimdi teklif detayları")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)

                VStack(spacing: 14) {
                    CompanyAutocompleteField(placeholder: "Teklif Veren Şirket", text: Binding(get: { viewModel.draft.teklifSirketAdi }, set: { viewModel.draft.teklifSirketAdi = $0 }))
                    CustomTextField(placeholder: "Önerilen Unvan (Örn: Müdür)", text: Binding(get: { viewModel.draft.teklifUnvan }, set: { viewModel.draft.teklifUnvan = $0 }))
                        .focused($isInputActive)
                }
                .padding(16)
                .background(viewModel.offerCompanyColor.opacity(0.04))
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(viewModel.offerCompanyColor.opacity(0.15), lineWidth: 1))

                maasGirisBloku(baslik: "Önerilen Aylık Ücret", maasStr: $viewModel.teklifMaasStr, brutMu: Binding(get: { viewModel.draft.teklifMaasBrutMu }, set: { viewModel.draft.teklifMaasBrutMu = $0 }), maasSayisi: $teklifMaasSayisi, primStr: $viewModel.teklifPrimStr, renk: viewModel.offerCompanyColor)

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    func adimBaslik(_ metin: String, renk: Color) -> some View {
        Text(metin)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundColor(appTheme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    func sirketBolumBasligi(_ isim: String, renk: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(renk).frame(width: 8, height: 8)
            Text(isim).font(.subheadline.bold()).foregroundColor(renk).lineLimit(1)
        }
    }

    private func sliderSatiri(baslik: String, deger: Binding<Double>, aralik: ClosedRange<Double>, renk: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(baslik).font(.subheadline).foregroundColor(appTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("\(Int(deger.wrappedValue)) Yıl").font(.title3.weight(.heavy)).foregroundColor(renk).frame(minWidth: 60, alignment: .trailing).contentTransition(.numericText()).animation(.spring(response: 0.3), value: deger.wrappedValue)
            }
            Slider(value: deger, in: aralik, step: 1).tint(renk)
        }
        .padding(16)
        .background(Color.gray.opacity(0.04))
        .cornerRadius(14)
    }

    @ViewBuilder
    private func maasGirisBloku(baslik: String, maasStr: Binding<String>, brutMu: Binding<Bool>, maasSayisi: Binding<Int>, primStr: Binding<String>, renk: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(baslik).font(.subheadline.bold()).foregroundColor(renk)
            HStack(spacing: 12) {
                Picker("", selection: brutMu) {
                    Text("Net").tag(false)
                    Text("Brüt").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                TextField("₺ 0", text: maasStr)
                    .keyboardType(.numberPad)
                    .focused($isInputActive)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(renk)
                    .multilineTextAlignment(.trailing)
            }
            .padding(14)
            .background(renk.opacity(0.06))
            .cornerRadius(14)
            HStack {
                Text("Yılda kaç maaş?").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 16) {
                    Button { if maasSayisi.wrappedValue > 12 { maasSayisi.wrappedValue -= 1 } } label: {
                        Image(systemName: "minus").font(.body.bold())
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundColor(appTheme.textPrimary)
                    }
                    Text("\(maasSayisi.wrappedValue)").font(.headline.monospacedDigit()).frame(width: 32, alignment: .center)
                    Button { if maasSayisi.wrappedValue < 24 { maasSayisi.wrappedValue += 1 } } label: {
                        Image(systemName: "plus").font(.body.bold())
                            .frame(width: 36, height: 36)
                            .background(renk.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundColor(renk)
                    }
                }
            }
            .padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 6) {
                Text("Yıllık Prim / İkramiye (opsiyonel)").font(.caption).foregroundColor(.secondary)
                TextField("₺ 0 — yoksa boş bırak", text: primStr)
                    .keyboardType(.numberPad)
                    .focused($isInputActive)
                    .font(.headline)
                    .padding(12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - ADIM 3: TERFİ (tam ekran kartlar, seçince otomatik ilerleme)
    private var step3_Terfi: some View {
        VStack(alignment: .leading, spacing: 20) {
            adimBaslik("Bu geçiş kariyerini nasıl etkiliyor?", renk: appTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            VStack(spacing: 12) {
                terfiKarti(baslik: "Terfi Alıyorum", altBaslik: "Daha yüksek bir unvana geçiyorum", ikon: "arrow.up.right.circle.fill", renk: appTheme.successColor, secili: terfiDurumu == "Terfi") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    terfiDurumu = "Terfi"
                    viewModel.draft.terfiVarMi = true
                }

                if terfiDurumu == "Terfi" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hangi kademeye terfi ediyorsun?").font(.subheadline.bold()).foregroundColor(appTheme.textPrimary).padding(.horizontal, 24)
                        let kademeler: [(Int, String, String)] = [
                            (1, "Giriş (Junior)", "person.fill"),
                            (2, "Orta (Mid-Level)", "person.2.fill"),
                            (3, "Kıdemli (Senior)", "star.fill"),
                            (4, "Yönetim (Manager)", "briefcase.fill"),
                            (5, "C-Level / Direktör", "crown.fill"),
                        ]
                        ForEach(kademeler, id: \.0) { rank, isim, ikon in
                            Button {
                                terfiKademesi = isim
                                viewModel.draft.teklifUnvanRank = rank
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { nextStep() }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: ikon).font(.title3).foregroundColor(terfiKademesi == isim ? .white : appTheme.successColor).frame(width: 40, height: 40).background(terfiKademesi == isim ? appTheme.successColor : appTheme.successColor.opacity(0.1)).clipShape(Circle())
                                    Text(isim).font(.subheadline.bold()).foregroundColor(terfiKademesi == isim ? appTheme.successColor : appTheme.textPrimary)
                                    Spacer()
                                    if terfiKademesi == isim { Image(systemName: "checkmark.circle.fill").foregroundColor(appTheme.successColor) }
                                }
                                .padding(14)
                                .background(terfiKademesi == isim ? appTheme.successColor.opacity(0.08) : appTheme.cardSurface)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(terfiKademesi == isim ? appTheme.successColor : Color.gray.opacity(0.1), lineWidth: terfiKademesi == isim ? 2 : 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: terfiDurumu)
                }

                terfiKarti(baslik: "Yatay Geçiş", altBaslik: "Aynı unvan, farklı şirket", ikon: "arrow.right.circle.fill", renk: appTheme.primaryAccent, secili: terfiDurumu == "Yatay") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    terfiDurumu = "Yatay"
                    viewModel.draft.terfiVarMi = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { nextStep() }
                }

                terfiKarti(baslik: "Unvan Geri Gidiyor", altBaslik: "Finansal avantaj var ama kademe düşüyor", ikon: "arrow.down.right.circle.fill", renk: appTheme.warningColor, secili: terfiDurumu == "Gerileme") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    terfiDurumu = "Gerileme"
                    viewModel.draft.terfiVarMi = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { nextStep() }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func terfiKarti(baslik: String, altBaslik: String, ikon: String, renk: Color, secili: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(secili ? renk : renk.opacity(0.12)).frame(width: 52, height: 52)
                    Image(systemName: ikon).font(.title2).foregroundColor(secili ? .white : renk)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(baslik).font(.headline.bold()).foregroundColor(secili ? renk : appTheme.textPrimary)
                    Text(altBaslik).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if secili { Image(systemName: "checkmark.circle.fill").foregroundColor(renk).font(.title2) }
            }
            .padding(18)
            .background(secili ? renk.opacity(0.07) : appTheme.cardSurface)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(secili ? renk : Color.gray.opacity(0.1), lineWidth: secili ? 2 : 1))
            .shadow(color: secili ? renk.opacity(0.15) : .black.opacity(0.02), radius: 8, y: 3)
            .scaleEffect(secili ? 0.985 : 1.0)
            .animation(.spring(response: 0.25), value: secili)
        }
        .buttonStyle(.plain)
    }

    // MARK: - ADIM 4: ÇALIŞMA DÜZENİ (3'lü ikonlu kart grid)
    private var step4_CalismaDuzeni: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                adimBaslik("Çalışma düzeni nasıl değişiyor?", renk: appTheme.textPrimary)

                VStack(spacing: 16) {
                    sirketBolumBasligi(mevcutSirketLabel, renk: viewModel.currentCompanyColor)
                    HStack(spacing: 12) {
                        calismaModeliKarti("Ofis", ikon: "building.2.fill", renk: viewModel.currentCompanyColor, secili: mevcutCalismaModeli == "Ofis") {
                            mevcutCalismaModeli = "Ofis"
                            viewModel.draft.mevcutCalismaModeli = "Ofis"
                            viewModel.draft.mevcutOfisGunSayisi = 5
                        }
                        calismaModeliKarti("Hibrit", ikon: "house.and.flag.fill", renk: viewModel.currentCompanyColor, secili: mevcutCalismaModeli == "Hibrit") {
                            withAnimation { mevcutCalismaModeli = "Hibrit" }
                            viewModel.draft.mevcutCalismaModeli = "Hibrit"
                        }
                        calismaModeliKarti("Remote", ikon: "house.fill", renk: viewModel.currentCompanyColor, secili: mevcutCalismaModeli == "Remote") {
                            mevcutCalismaModeli = "Remote"
                            viewModel.draft.mevcutCalismaModeli = "Uzaktan"
                            viewModel.draft.mevcutOfisGunSayisi = 0
                        }
                    }
                    if mevcutCalismaModeli == "Hibrit" {
                        hibritGunSecici(deger: $mevcutHibritGun, renk: viewModel.currentCompanyColor) { viewModel.draft.mevcutOfisGunSayisi = Int($0) }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(18)
                .background(viewModel.currentCompanyColor.opacity(0.03))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(viewModel.currentCompanyColor.opacity(0.12), lineWidth: 1))

                VStack(spacing: 16) {
                    sirketBolumBasligi(teklifSirketLabel, renk: viewModel.offerCompanyColor)
                    HStack(spacing: 12) {
                        calismaModeliKarti("Ofis", ikon: "building.2.fill", renk: viewModel.offerCompanyColor, secili: teklifCalismaModeli == "Ofis") {
                            teklifCalismaModeli = "Ofis"
                            viewModel.draft.teklifCalismaModeli = "Ofis"
                            viewModel.draft.teklifOfisGunSayisi = 5
                        }
                        calismaModeliKarti("Hibrit", ikon: "house.and.flag.fill", renk: viewModel.offerCompanyColor, secili: teklifCalismaModeli == "Hibrit") {
                            withAnimation { teklifCalismaModeli = "Hibrit" }
                            viewModel.draft.teklifCalismaModeli = "Hibrit"
                        }
                        calismaModeliKarti("Remote", ikon: "house.fill", renk: viewModel.offerCompanyColor, secili: teklifCalismaModeli == "Remote") {
                            teklifCalismaModeli = "Remote"
                            viewModel.draft.teklifCalismaModeli = "Uzaktan"
                            viewModel.draft.teklifOfisGunSayisi = 0
                        }
                    }
                    if teklifCalismaModeli == "Hibrit" {
                        hibritGunSecici(deger: $teklifHibritGun, renk: viewModel.offerCompanyColor) { viewModel.draft.teklifOfisGunSayisi = Int($0) }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(18)
                .background(viewModel.offerCompanyColor.opacity(0.03))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(viewModel.offerCompanyColor.opacity(0.12), lineWidth: 1))

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .animation(.spring(response: 0.4), value: mevcutCalismaModeli)
            .animation(.spring(response: 0.4), value: teklifCalismaModeli)
        }
    }

    private func calismaModeliKarti(_ baslik: String, ikon: String, renk: Color, secili: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); action() }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(secili ? renk : renk.opacity(0.1)).frame(width: 56, height: 56)
                    Image(systemName: ikon).font(.title2).foregroundColor(secili ? .white : renk)
                }
                Text(baslik).font(.caption.bold()).foregroundColor(secili ? renk : appTheme.textPrimary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(secili ? renk.opacity(0.08) : Color.gray.opacity(0.04))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(secili ? renk : Color.clear, lineWidth: 2))
            .scaleEffect(secili ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: secili)
        }
        .buttonStyle(.plain)
    }

    private func hibritGunSecici(deger: Binding<Double>, renk: Color, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Haftada kaç gün ofis?").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("\(Int(deger.wrappedValue)) Gün/Hafta").font(.subheadline.bold()).foregroundColor(renk)
            }
            Slider(value: deger, in: 1...4, step: 1)
                .tint(renk)
                .onChange(of: deger.wrappedValue) { _, n in onChange(n) }
        }
        .padding(12)
        .background(renk.opacity(0.06))
        .cornerRadius(12)
    }

    private func ikiSecenekButon(secili: Bool, baslik: String, ikon: String, renk: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: ikon).font(.subheadline)
                Text(baslik).font(.subheadline.bold())
            }
            .foregroundColor(secili ? .white : appTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(secili ? (renk == .secondary ? Color.gray : renk) : Color.gray.opacity(0.1))
            .cornerRadius(14)
            .scaleEffect(secili ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: secili)
        }
        .buttonStyle(.plain)
    }

    private func syncUlasimToDraft() {
        // Ulaşım tipi: draft’a da yaz ki analiz/geri yükleme tutarlı olsun
        viewModel.draft.mevcutUlasimTipi = mevcutUlasimTipi
        viewModel.draft.teklifUlasimTipi = teklifUlasimTipi
        viewModel.draft.mevcutSirketAraciVarMi = (mevcutUlasimTipi == "Şirket Aracı") || (mevcutRemoteAracTahsisVarMi == true)
        viewModel.draft.teklifSirketAraciVarMi = (teklifUlasimTipi == "Şirket Aracı") || (teklifRemoteAracTahsisVarMi == true)

        // Segment: Şirket Aracı seçiliyse boş bırakılmışsa varsayılan "B" kullan (analizde satır çıksın)
        var mevcutSeg = mevcutAracSegment
        if (mevcutUlasimTipi == "Şirket Aracı" || mevcutRemoteAracTahsisVarMi == true), mevcutSeg.isEmpty { mevcutSeg = "B" }
        var teklifSeg = teklifAracSegment
        if (teklifUlasimTipi == "Şirket Aracı" || teklifRemoteAracTahsisVarMi == true), teklifSeg.isEmpty { teklifSeg = "B" }

        viewModel.draft.mevcutAracSegment = AracSegmentBilgisi.draftDegeri(secim: mevcutSeg)
        viewModel.draft.mevcutYakitDestekTutar = mevcutRemoteYakitDestegiVarMi == true ? mevcutRemoteYakitAylikTL : ""
        viewModel.draft.mevcutKendiAracAylikGider = mevcutUlasimTipi == "Şahsi Araç" ? mevcutYakitTutari : ""
        viewModel.draft.mevcutKendiAracGiderKimin = mevcutUlasimTipi == "Şahsi Araç" ? (mevcutYakitKarsilayan == "Şirket" ? "Şirket" : "Ben") : ""
        viewModel.draft.mevcutTopluTasimaTutar = mevcutUlasimTipi == "Toplu Ulaşım" ? mevcutTopluTutar : ""
        viewModel.draft.mevcutTopluTasimaDestekVarMi = mevcutTopluKarsilayan == "Şirket"
        viewModel.draft.teklifAracSegment = AracSegmentBilgisi.draftDegeri(secim: teklifSeg)
        viewModel.draft.teklifYakitDestekTutar = teklifRemoteYakitDestegiVarMi == true ? teklifRemoteYakitAylikTL : ""
        viewModel.draft.teklifKendiAracAylikGider = teklifUlasimTipi == "Şahsi Araç" ? teklifYakitTutari : ""
        viewModel.draft.teklifKendiAracGiderKimin = teklifUlasimTipi == "Şahsi Araç" ? (teklifYakitKarsilayan == "Şirket" ? "Şirket" : "Ben") : ""
        viewModel.draft.teklifTopluTasimaTutar = teklifUlasimTipi == "Toplu Ulaşım" ? teklifTopluTutar : ""
        viewModel.draft.teklifTopluTasimaDestekVarMi = teklifTopluKarsilayan == "Şirket"
    }


    private func handleNextStep() {
        switch currentStep {
        case 1:
            viewModel.draft.mevcutMaasSayisi = mevcutMaasSayisi
        case 2:
            viewModel.draft.teklifMaasSayisi = teklifMaasSayisi
        case 4:
            viewModel.draft.mevcutOfisGunSayisi = mevcutCalismaModeli == "Hibrit" ? Int(mevcutHibritGun) : (mevcutCalismaModeli == "Ofis" ? 5 : 0)
            viewModel.draft.teklifOfisGunSayisi = teklifCalismaModeli == "Hibrit" ? Int(teklifHibritGun) : (teklifCalismaModeli == "Ofis" ? 5 : 0)
        case 5:
            syncUlasimToDraft()
        case 6:
            viewModel.draft.mevcutGunlukYemekUcreti = Double(mevcutGunlukYemek.replacingOccurrences(of: ".", with: "")) ?? 0
            viewModel.draft.teklifGunlukYemekUcreti = Double(teklifGunlukYemek.replacingOccurrences(of: ".", with: "")) ?? 0
        case 7:
            viewModel.draft.mevcutSigortaYararlananKisiSayisi = (mevcutSaglikAile == true) ? mevcutSaglikKisiSayisi : 1
            viewModel.draft.teklifSigortaYararlananKisiSayisi = (teklifSaglikAile == true) ? teklifSaglikKisiSayisi : 1
        case 8:
            viewModel.draft.mevcutBesAylikKatki = mevcutBesTutar
            viewModel.draft.teklifBesAylikKatki = teklifBesTutar
        case 9:
            viewModel.draft.mevcutYillikIzin = mevcutYillikIzin
            viewModel.draft.teklifYillikIzin = teklifYillikIzin
            viewModel.syncStringsToModel()
            onFinish?()
            return
        default: break
        }
        nextStep()
    }

    private func nextStep() {
        withAnimation(.easeOut(duration: 0.08)) {
            if currentStep < totalSteps { currentStep += 1 }
            else { viewModel.syncStringsToModel(); onFinish?() }
        }
    }

    private func prevStep() {
        isInputActive = false
        withAnimation(.easeOut(duration: 0.08)) {
            if currentStep > 1 { currentStep -= 1 }
            else { dismiss() }
        }
    }

}

// MARK: - Custom TextField
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body.weight(.medium))
            .foregroundColor(.primary)
            .padding(12)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
    }
}
