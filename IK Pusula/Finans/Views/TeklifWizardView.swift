import SwiftUI
import SwiftData
import UIKit

// MARK: - Ana Wizard

struct TeklifWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appTheme: AppTheme

    /// Düzenleme modunda dışarıdan verilen viewModel (örn. KayitliTeklifDetayView).
    var editingViewModel: KariyerKiyaslamaViewModel? = nil
    @StateObject private var internalViewModel = KariyerKiyaslamaViewModel()
    private var viewModel: KariyerKiyaslamaViewModel { editingViewModel ?? internalViewModel }

    @State private var currentStep = 0
    // Step 0 = Survey (son sayfa: Teklif BES). Sonra: Hızlı = Analiz; Derin = doğrudan Derin Analiz sonuç (ara soru sayfaları yok).
    private var totalWizardSteps: Int {
        viewModel.isDeepAnalysisSelected ? 2 : 2
    }
    private var isEditMode: Bool { editingViewModel != nil }

    var body: some View {
        ZStack(alignment: .top) {
            // Arka plan: klavye kapatma için dokunma almıyor; tüm tıklamalar içeriğe gitsin
            appTheme.backgroundMain
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Üst bar (analiz adımında gizle)
                if currentStep < totalWizardSteps {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Button { goBack() } label: {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(currentStep > 0 ? appTheme.textSecondary : .clear)
                                    .frame(width: 32, height: 32)
                                    .background(currentStep > 0 ? Color.gray.opacity(0.12) : .clear)
                                    .clipShape(Circle())
                            }
                            .disabled(currentStep == 0)

                            Spacer()

                            // Gerçek zamanlı dopamin sayacı
                            LiveWealthTicker(viewModel: viewModel)
                                .environmentObject(appTheme)

                            Spacer()

                            Button {
                                if !isEditMode { viewModel.clearDraft() }
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(appTheme.textSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.gray.opacity(0.12))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // İlerleme Çubuğu (Survey aşamasında SurveyEngineView kendi çubuğunu gösterir)
                        if currentStep > 0 {
                            ProgressView(value: Double(currentStep + 1), total: Double(totalWizardSteps))
                                .progressViewStyle(LinearProgressViewStyle(tint: appTheme.primaryAccent))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 12)
                        }
                    }
                    .background(appTheme.backgroundMain.ignoresSafeArea(.all, edges: .top))
                    .zIndex(2)
                } else {
                    // Analiz adımı başlık çubuğu
                    HStack {
                        Text("Kıyaslama Sonuçları")
                            .font(.headline.bold())
                            .foregroundColor(appTheme.textPrimary)
                        Spacer()
                        Button {
                            if !isEditMode { viewModel.clearDraft() }
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                }

                ZStack {
                    if currentStep == 0 {
                        // Her konu tek sayfa: Soru 1–8 (mevcut/teklif temel, terfi, çalışma, ulaşım, yemek, sağlık, BES) — 14 iç adım
                        SurveyEngineView(viewModel: viewModel, onFinish: { advance() })
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)))
                            .id("step0_survey")
                    } else if viewModel.isDeepAnalysisSelected {
                        // Derin analiz: Survey (son sayfa = Teklif BES) sonrası doğrudan sonuç sayfası
                        if currentStep == 1 {
                            DeepKiyaslamaAnalysisView(viewModel: viewModel, onClose: { bitirVeKaydet(); dismiss() })
                                .onAppear {
                                    viewModel.draft.derinAnalizYapildiMi = true
                                    viewModel.saveDraft()
                                }
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                                .id("step1_deep")
                        }
                    } else {
                        // Hızlı analiz: sadece sonuç sayfası
                        if currentStep == 1 {
                            KiyaslamaAnalysisView(
                                viewModel: viewModel,
                                isReadOnly: false,
                                isEditMode: isEditMode,
                                onEditTapped: { withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { currentStep = 0; viewModel.saveDraft() } },
                                onFinish: isEditMode ? { dismiss() } : { bitirVeKaydet() }
                            )
                                .onAppear { viewModel.saveDraft() }
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            .id("step1_fast")
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentStep)
            }
            .zIndex(1)
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentStep += 1
        }
    }

    private func goBack() {
        HapticHelper.triggerImpact(.light)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentStep = max(currentStep - 1, 0)
        }
    }

    private func bitirVeKaydet() {
        viewModel.syncStringsToModel()
        let src = viewModel.draft

        // draft nesnesi herhangi bir context'te olmayabilir.
        // Güvenli yol: container context'i içinde sıfırdan oluştur, alanları kopyala.
        let ctx = ModelContext(IKPusulaApp.teklifContainer)
        let yeni = TeklifKiyaslama()
        yeni.olusturulmaTarihi    = Date()
        yeni.mevcutSirketAdi      = src.mevcutSirketAdi
        yeni.teklifSirketAdi      = src.teklifSirketAdi
        yeni.terfiVarMi           = src.terfiVarMi
        yeni.mevcutUnvan          = src.mevcutUnvan
        yeni.teklifUnvan          = src.teklifUnvan
        yeni.mevcutUnvanYil       = src.mevcutUnvanYil
        yeni.mevcutUnvanRank      = src.mevcutUnvanRank
        yeni.teklifUnvanRank      = src.teklifUnvanRank
        yeni.mevcutBrutMaas       = src.mevcutBrutMaas
        yeni.mevcutMaasBrutMu     = src.mevcutMaasBrutMu
        yeni.teklifBrutMaas       = src.teklifBrutMaas
        yeni.teklifMaasBrutMu     = src.teklifMaasBrutMu
        yeni.mevcutMaasSayisi     = src.mevcutMaasSayisi
        yeni.teklifMaasSayisi     = src.teklifMaasSayisi
        yeni.mevcutPrimTutar      = src.mevcutPrimTutar
        yeni.mevcutPrimBrutMu     = src.mevcutPrimBrutMu
        yeni.teklifPrimTutar      = src.teklifPrimTutar
        yeni.teklifPrimBrutMu     = src.teklifPrimBrutMu
        yeni.mevcutCalismaModeli  = src.mevcutCalismaModeli
        yeni.teklifCalismaModeli  = src.teklifCalismaModeli
        yeni.mevcutOfisGunSayisi  = src.mevcutOfisGunSayisi
        yeni.teklifOfisGunSayisi  = src.teklifOfisGunSayisi
        yeni.mevcutUlasimTipi     = src.mevcutUlasimTipi
        yeni.teklifUlasimTipi     = src.teklifUlasimTipi
        yeni.mevcutYolSureDakika  = src.mevcutYolSureDakika
        yeni.teklifYolSureDakika  = src.teklifYolSureDakika
        yeni.mevcutYemekTipi      = src.mevcutYemekTipi
        yeni.teklifYemekTipi      = src.teklifYemekTipi
        yeni.mevcutYemekLezzetYildiz  = src.mevcutYemekLezzetYildiz
        yeni.teklifYemekLezzetYildiz  = src.teklifYemekLezzetYildiz
        yeni.mevcutGunlukYemekUcreti  = src.mevcutGunlukYemekUcreti
        yeni.teklifGunlukYemekUcreti  = src.teklifGunlukYemekUcreti
        yeni.mevcutSigortaTipi    = src.mevcutSigortaTipi
        yeni.teklifSigortaTipi    = src.teklifSigortaTipi
        yeni.mevcutSigortaYararlananKisiSayisi = src.mevcutSigortaYararlananKisiSayisi
        yeni.teklifSigortaYararlananKisiSayisi = src.teklifSigortaYararlananKisiSayisi
        // Eski alan (geriye dönük): hızlı yorum varsa oraya da yaz
        yeni.aiYorumu             = viewModel.aiHizliYorumu ?? ""
        yeni.aiHizliYorumu        = viewModel.aiHizliYorumu ?? ""
        yeni.aiDerinYorumu        = viewModel.aiDerinYorumu ?? ""
        yeni.derinAnalizYapildiMi = src.derinAnalizYapildiMi

        ctx.insert(yeni)
        do {
            try ctx.save()
        } catch {
            print("⚠️ TeklifKiyaslama kayıt hatası: \(error)")
        }

        HapticHelper.triggerSuccess()
        viewModel.clearDraft()
        dismiss()
    }
}

// MARK: - Adım 1: Klavyeli Alan

struct ZenTextInputsStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    @FocusState private var focused: ZenField?

    enum ZenField: Hashable {
        case mevcutSirket, teklifSirket
        case mevcutMaas, teklifMaas
        case mevcutPrim, teklifPrim
    }

    private var canProceed: Bool {
        !viewModel.draft.mevcutSirketAdi.isEmpty &&
        !viewModel.draft.teklifSirketAdi.isEmpty &&
        !viewModel.mevcutMaasStr.isEmpty &&
        !viewModel.teklifMaasStr.isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Önce temel rakamları girelim.\nBundan sonra klavyeye ihtiyacımız olmayacak.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .multilineTextAlignment(.center)

                // MARK: Mevcut İşin (kompakt kart)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yerin").font(.headline.bold())
                        .foregroundColor(viewModel.currentCompanyColor)

                    ZenTextField(placeholder: "Şirket Adı", text: $viewModel.draft.mevcutSirketAdi,
                                 color: viewModel.currentCompanyColor, field: .mevcutSirket,
                                 focused: $focused, submitLabel: .next,
                                 onSubmit: { focused = .mevcutMaas })

                    // Maaş: giriş + yılda kaç maaş (inline menü)
                    HStack(alignment: .bottom, spacing: 12) {
                        CurrencyInputField(title: "Aylık Maaş (₺)", rawText: $viewModel.mevcutMaasStr,
                                           color: viewModel.currentCompanyColor, field: .mevcutMaas,
                                           focused: $focused, submitLabel: .next,
                                           onSubmit: { focused = .mevcutPrim })
                        Menu {
                            ForEach(12...16, id: \.self) { val in
                                Button("\(val) Maaş") { viewModel.draft.mevcutMaasSayisi = val }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("x\(viewModel.draft.mevcutMaasSayisi)")
                                    .font(.subheadline.bold())
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(appTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    Picker("", selection: $viewModel.mevcutMaasBrutMu) {
                        Text("Brüt").tag(true)
                        Text("Net").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    // Prim: aşamalı gösterim (sadece tutar > 0 ise Brüt/Net seçici)
                    VStack(alignment: .leading, spacing: 8) {
                        CurrencyInputField(title: "Yıllık Prim (₺)", rawText: $viewModel.mevcutPrimStr,
                                           color: viewModel.currentCompanyColor, field: .mevcutPrim,
                                           focused: $focused, submitLabel: .next,
                                           onSubmit: { focused = .teklifSirket })
                        if (Int(viewModel.mevcutPrimStr) ?? 0) > 0 {
                            Picker("Prim Tipi", selection: $viewModel.draft.mevcutPrimBrutMu) {
                                Text("Brüt").tag(true)
                                Text("Net").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.mevcutPrimStr)
                }
                .zenKutu(color: viewModel.currentCompanyColor)

                // MARK: Yeni Teklif (kompakt kart)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklif Eden İş Yeri").font(.headline.bold())
                        .foregroundColor(viewModel.offerCompanyColor)

                    ZenTextField(placeholder: "Şirket Adı", text: $viewModel.draft.teklifSirketAdi,
                                 color: viewModel.offerCompanyColor, field: .teklifSirket,
                                 focused: $focused, submitLabel: .next,
                                 onSubmit: { focused = .teklifMaas })

                    HStack(alignment: .bottom, spacing: 12) {
                        CurrencyInputField(title: "Aylık Maaş (₺)", rawText: $viewModel.teklifMaasStr,
                                           color: viewModel.offerCompanyColor, field: .teklifMaas,
                                           focused: $focused, submitLabel: .next,
                                           onSubmit: { focused = .teklifPrim })
                        Menu {
                            ForEach(12...16, id: \.self) { val in
                                Button("\(val) Maaş") { viewModel.draft.teklifMaasSayisi = val }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("x\(viewModel.draft.teklifMaasSayisi)")
                                    .font(.subheadline.bold())
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(appTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    Picker("", selection: $viewModel.teklifMaasBrutMu) {
                        Text("Brüt").tag(true)
                        Text("Net").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        CurrencyInputField(title: "Yıllık Prim (₺)", rawText: $viewModel.teklifPrimStr,
                                           color: viewModel.offerCompanyColor, field: .teklifPrim,
                                           focused: $focused, submitLabel: .done,
                                           onSubmit: { focused = nil })
                        if (Int(viewModel.teklifPrimStr) ?? 0) > 0 {
                            Picker("Prim Tipi", selection: $viewModel.draft.teklifPrimBrutMu) {
                                Text("Brüt").tag(true)
                                Text("Net").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.teklifPrimStr)
                }
                .zenKutu(color: viewModel.offerCompanyColor)

                Button {
                    focused = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onNext() }
                } label: {
                    Text("Devam Et")
                        .font(.headline.bold()).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(canProceed ? Color(hex: "3B82F6") : Color.gray.opacity(0.3))
                        .cornerRadius(14)
                }
                .disabled(!canProceed)
                .padding(.bottom, 40)

                // MARK: - KLAVYE BOŞLUĞU (KEYBOARD SPACER)
                // Klavye açıldığında ekranın rahatça yukarı kayabilmesi ve
                // alttaki kutucukların görünür kalması için ekstra şeffaf alan
                Color.clear.frame(height: 180)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - Adım 2: Kariyer (Yığılmalı — chip üstte, soru altta açılır)

struct ZenCareerStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    @FocusState private var unvanFocused: UnvanField?

    enum UnvanField: Hashable { case mevcutUnvan, teklifUnvan }

    // phase 0: Q1 açık | 1: Q2 açık | 2: Q3 açık
    @State private var phase = 0

    // terfi=true tamamlandı mı?
    private var terfiTamamlandi: Bool {
        viewModel.draft.terfiVarMi && !viewModel.draft.teklifUnvan.isEmpty
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Q1 — Kariyer geçiş tipi
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bu geçiş kariyerini nasıl etkiliyor?")
                            .font(.title3.bold()).foregroundColor(appTheme.textPrimary)

                        if phase == 0 {
                            VStack(spacing: 10) {
                                ZenBigButton(title: "Terfi Alarak Geçiyorum",
                                             icon: "arrow.up.right.circle.fill",
                                             color: appTheme.warningColor) {
                                    viewModel.draft.terfiVarMi = true
                                    viewModel.careerQ1Answered = true
                                    ilerle(proxy: proxy, anchor: "q2")
                                }
                                ZenBigButton(title: "Aynı Unvanda Geçiyorum",
                                             icon: "equal.circle.fill",
                                             color: appTheme.primaryAccent) {
                                    viewModel.draft.terfiVarMi = false
                                    viewModel.careerQ1Answered = true
                                    ilerle(proxy: proxy, anchor: "q2")
                                }
                            }
                        } else {
                            ZenAnswerChip(
                                text: viewModel.draft.terfiVarMi
                                    ? "Terfi Alarak Geçiyorum" : "Aynı Unvanda Geçiyorum",
                                icon: viewModel.draft.terfiVarMi
                                    ? "arrow.up.right.circle.fill" : "equal.circle.fill",
                                color: viewModel.draft.terfiVarMi
                                    ? appTheme.warningColor : appTheme.primaryAccent
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.draft.mevcutUnvan = ""
                                    viewModel.draft.teklifUnvan = ""
                                    phase = 0
                                }
                            }
                        }
                    }

                    // Q2 — Mevcut unvan (serbest metin + kademe)
                    if phase >= 1 {
                        zenAyrac()

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Mevcut işindeki unvanın nedir?")
                                .font(.title3.bold())
                                .foregroundColor(viewModel.currentCompanyColor)

                            TextField("Örn: Kıdemli Veri Analisti, Scrum Master", text: $viewModel.draft.mevcutUnvan)
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 4)
                                .focused($unvanFocused, equals: .mevcutUnvan)

                            Text("Bu unvanın sorumluluk seviyesi (kademesi) nedir?")
                                .font(.subheadline.bold())
                                .foregroundColor(viewModel.currentCompanyColor)

                            UnvanKademeChips(
                                selectedRank: $viewModel.draft.mevcutUnvanRank,
                                renk: viewModel.currentCompanyColor,
                                onSelect: { viewModel.setUnvanRank(isCurrent: true, rank: $0) }
                            )

                            if !viewModel.draft.mevcutUnvan.isEmpty {
                                Button(action: { ilerle(proxy: proxy, anchor: "q3") }) {
                                    HStack {
                                        Text("İlerle")
                                        Image(systemName: "arrow.right.circle.fill")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.currentCompanyColor)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .id("q2")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Q3 — Teklif unvan (terfi=true) + Kıdem yılı (her zaman)
                    if phase >= 2 {
                        zenAyrac()

                        if viewModel.draft.terfiVarMi {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Teklifteki yeni unvanın nedir?")
                                    .font(.title3.bold())
                                    .foregroundColor(viewModel.offerCompanyColor)

                                TextField("Örn: Ürün Müdürü, Direktör", text: $viewModel.draft.teklifUnvan)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 4)

                                Text("Yeni unvanın sorumluluk seviyesi (kademesi) nedir?")
                                    .font(.subheadline.bold())
                                    .foregroundColor(viewModel.offerCompanyColor)

                                UnvanKademeChips(
                                    selectedRank: $viewModel.draft.teklifUnvanRank,
                                    renk: viewModel.offerCompanyColor,
                                    onSelect: { viewModel.setUnvanRank(isCurrent: false, rank: $0) }
                                )
                            }
                            .id("q3")
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            zenAyrac()
                        }

                        // Airbnb tarzı özel yıl seçici (geniş dokunma alanı, premium görünüm)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mevcut unvanda/iş yerinde kaç yıldır çalışıyorsun?")
                                .font(.subheadline.bold())
                                .foregroundColor(appTheme.textPrimary)

                            HStack(spacing: 20) {
                                Button {
                                    if viewModel.draft.mevcutUnvanYil > 0 {
                                        HapticHelper.triggerImpact(.light)
                                        viewModel.draft.mevcutUnvanYil -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.title2.bold())
                                        .foregroundColor(viewModel.draft.mevcutUnvanYil > 0 ? appTheme.textPrimary : .gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)

                                Text("\(viewModel.draft.mevcutUnvanYil) Yıl")
                                    .font(.title2.weight(.heavy))
                                    .foregroundColor(appTheme.primaryAccent)
                                    .frame(minWidth: 80)
                                    .multilineTextAlignment(.center)

                                Button {
                                    if viewModel.draft.mevcutUnvanYil < 40 {
                                        HapticHelper.triggerImpact(.light)
                                        viewModel.draft.mevcutUnvanYil += 1
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2.bold())
                                        .foregroundColor(appTheme.textPrimary)
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)

                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 8)
                        .id("q3")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.draft.mevcutUnvan)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.draft.teklifUnvan)
            }
            .scrollDismissesKeyboard(.immediately)
            // Sabit Devam Butonu
            .safeAreaInset(edge: .bottom) {
                if terfiTamamlandi || (phase >= 2 && !viewModel.draft.terfiVarMi) {
                    zenDevamButonu(
                        renk: viewModel.draft.terfiVarMi
                            ? viewModel.offerCompanyColor
                            : viewModel.currentCompanyColor,
                        action: { HapticHelper.triggerImpact(.medium); onNext() }
                    )
                }
            }
        }
        .onAppear { restorePhase() }
    }

    private func ilerle(proxy: ScrollViewProxy, anchor: String) {
        HapticHelper.triggerImpact(.medium)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(anchor, anchor: .top) }
        }
    }

    private func restorePhase() {
        if !viewModel.draft.teklifUnvan.isEmpty { phase = 2 }
        else if !viewModel.draft.mevcutUnvan.isEmpty { phase = 2 }
        else if viewModel.careerQ1Answered { phase = 1 }
    }

    @ViewBuilder private func zenAyrac() -> some View {
        Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 1)
    }
}

// MARK: - Unvan kademe seçimi (1–5: Giriş → C-Level)
private let unvanKademeSecenekleri: [(rank: Int, baslik: String, aciklama: String)] = [
    (1, "Giriş", "Asistan, Yeni Mezun, Stajyer, Yardımcı roller"),
    (2, "Orta", "Uzman, Analist, Temsilci, Mühendis"),
    (3, "Kıdemli", "Kıdemli Uzman, Takım Lideri, Baş Mühendis"),
    (4, "Yönetim", "Müdür, Şef, Yönetmen, Bölge Yöneticisi"),
    (5, "C-Level", "Direktör, GMY, CEO, Kurucu")
]

struct UnvanKademeChips: View {
    @Binding var selectedRank: Int
    let renk: Color
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(unvanKademeSecenekleri, id: \.rank) { item in
                        let isSelected = selectedRank == item.rank
                        Button(action: {
                            selectedRank = item.rank
                            onSelect?(item.rank)
                        }) {
                            Text(item.baslik)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(isSelected ? renk : renk.opacity(0.12))
                                .foregroundColor(isSelected ? .white : renk)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            if let secili = unvanKademeSecenekleri.first(where: { $0.rank == selectedRank }) {
                Text(secili.aciklama)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Adım 3: Çalışma Düzeni (Yığılmalı — mevcut + teklif tek scroll)

struct ZenWorkModelStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    @State private var mevcutServisTekYonKm: String = ""
    @State private var teklifServisTekYonKm: String = ""

    private var mevcutUlasimGerekli: Bool {
        let m = viewModel.draft.mevcutCalismaModeli
        return !m.isEmpty && m != "Uzaktan"
    }
    private var teklifUlasimGerekli: Bool {
        let m = viewModel.draft.teklifCalismaModeli
        return !m.isEmpty && m != "Uzaktan"
    }
    private var mevcutTamamlandi: Bool {
        viewModel.workMevcutTamamlandi
    }
    private var teklifTamamlandi: Bool {
        let m = viewModel.draft.teklifCalismaModeli
        if m.isEmpty { return false }
        if m == "Uzaktan" { return true }
        if m == "Hibrit" && viewModel.draft.teklifOfisGunSayisi == 0 { return false }
        return !viewModel.draft.teklifUlasimTipi.isEmpty
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ─── MEVCUT ŞİRKET ───────────────────────────────
                    sirketBaslik(
                        viewModel.draft.mevcutSirketAdi.isEmpty
                            ? "Mevcut İşin" : viewModel.draft.mevcutSirketAdi,
                        color: viewModel.currentCompanyColor
                    )

                    soruBolumu {
                        // Q_m1: Çalışma Modeli
                        Text("Çalışma Düzeni Nasıl?")
                            .font(.title3.bold())
                            .foregroundColor(viewModel.currentCompanyColor)
                        if viewModel.draft.mevcutCalismaModeli.isEmpty {
                            modelButonlari(for: .mevcut, proxy: proxy)
                        } else {
                            ZenAnswerChip(
                                text: viewModel.draft.mevcutCalismaModeli,
                                icon: modelIkonu(viewModel.draft.mevcutCalismaModeli),
                                color: viewModel.currentCompanyColor
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.draft.mevcutCalismaModeli = ""
                                    viewModel.draft.mevcutOfisGunSayisi = 0
                                    viewModel.draft.mevcutUlasimTipi = ""
                                    viewModel.workMevcutTamamlandi = false
                                }
                            }
                        }
                    }

                    // Q_m2: Hibrit gün (görünür → model == Hibrit)
                    if viewModel.draft.mevcutCalismaModeli == "Hibrit" {
                        ayrac()
                        soruBolumu(id: "m2") {
                            Text("Haftada kaç gün ofise gidiliyor?")
                                .font(.title3.bold())
                                .foregroundColor(viewModel.currentCompanyColor)
                            if viewModel.draft.mevcutOfisGunSayisi == 0 {
                                gunButonlari(for: .mevcut, proxy: proxy)
                            } else {
                                ZenAnswerChip(
                                    text: "Haftada \(viewModel.draft.mevcutOfisGunSayisi) gün",
                                    icon: "calendar",
                                    color: viewModel.currentCompanyColor
                                ) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.draft.mevcutOfisGunSayisi = 0
                                        viewModel.draft.mevcutUlasimTipi = ""
                                        viewModel.workMevcutTamamlandi = false
                                    }
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Q_m3: Ulaşım (görünür → model seçildi ve Uzaktan değil, ve eğer Hibrit ise gün de seçildi)
                    let mevcutUlasimGorunur = mevcutUlasimGerekli &&
                        (viewModel.draft.mevcutCalismaModeli != "Hibrit" ||
                         viewModel.draft.mevcutOfisGunSayisi > 0)
                    if mevcutUlasimGorunur {
                        ayrac()
                        soruBolumu(id: "m3") {
                            Text("Ulaşım nasıl sağlanıyor?")
                                .font(.title3.bold())
                                .foregroundColor(viewModel.currentCompanyColor)
                            if viewModel.draft.mevcutUlasimTipi.isEmpty {
                                ulasimButonlari(for: .mevcut, proxy: proxy)
                            } else {
                                ZenAnswerChip(
                                    text: viewModel.draft.mevcutUlasimTipi,
                                    icon: ulasimIkonu(viewModel.draft.mevcutUlasimTipi),
                                    color: viewModel.currentCompanyColor
                                ) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.draft.mevcutUlasimTipi = ""
                                        viewModel.workMevcutTamamlandi = false
                                    }
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Q_m4: Yol Süresi (görünür → ulaşım seçildi)
                    if !viewModel.draft.mevcutUlasimTipi.isEmpty {
                        ayrac()
                        soruBolumu(id: "m4") {
                            Text("Günlük yol süresi?")
                                .font(.title3.bold())
                                .foregroundColor(viewModel.currentCompanyColor)
                            sureStepper(
                                value: $viewModel.draft.mevcutYolSureDakika,
                                color: viewModel.currentCompanyColor
                            )
                            if viewModel.draft.mevcutUlasimTipi == "Servis" {
                                servisKmKutucuk(
                                    km: $mevcutServisTekYonKm,
                                    color: viewModel.currentCompanyColor
                                )
                            }
                            if !viewModel.workMevcutTamamlandi {
                                zenAkisButonu(
                                    baslik: "Teklif Edilen İşe Geç →",
                                    renk: viewModel.currentCompanyColor
                                ) {
                                    HapticHelper.triggerImpact(.medium)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.workMevcutTamamlandi = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation { proxy.scrollTo("teklifBaslik", anchor: .top) }
                                    }
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Uzaktan ise direkt "Teklif İşe Geç" göster
                    if viewModel.draft.mevcutCalismaModeli == "Uzaktan" && !viewModel.workMevcutTamamlandi {
                        ayrac()
                        soruBolumu {
                            zenAkisButonu(
                                baslik: "Teklif Edilen İşe Geç →",
                                renk: viewModel.currentCompanyColor
                            ) {
                                HapticHelper.triggerImpact(.medium)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.workMevcutTamamlandi = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation { proxy.scrollTo("teklifBaslik", anchor: .top) }
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ─── TEKLİF ŞİRKET ───────────────────────────────
                    if mevcutTamamlandi {
                        Divider()
                            .padding(.vertical, 12)
                            .id("teklifBaslik")

                        sirketBaslik(
                            viewModel.draft.teklifSirketAdi.isEmpty
                                ? "Teklif" : viewModel.draft.teklifSirketAdi,
                            color: viewModel.offerCompanyColor
                        )

                        soruBolumu {
                            Text("Çalışma Düzeni Nasıl?")
                                .font(.title3.bold())
                                .foregroundColor(viewModel.offerCompanyColor)
                            if viewModel.draft.teklifCalismaModeli.isEmpty {
                                modelButonlari(for: .teklif, proxy: proxy)
                            } else {
                                ZenAnswerChip(
                                    text: viewModel.draft.teklifCalismaModeli,
                                    icon: modelIkonu(viewModel.draft.teklifCalismaModeli),
                                    color: viewModel.offerCompanyColor
                                ) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.draft.teklifCalismaModeli = ""
                                        viewModel.draft.teklifOfisGunSayisi = 0
                                        viewModel.draft.teklifUlasimTipi = ""
                                    }
                                }
                            }
                        }

                        if viewModel.draft.teklifCalismaModeli == "Hibrit" {
                            ayrac()
                            soruBolumu(id: "t2") {
                                Text("Haftada kaç gün ofise gidiliyor?")
                                    .font(.title3.bold())
                                    .foregroundColor(viewModel.offerCompanyColor)
                                if viewModel.draft.teklifOfisGunSayisi == 0 {
                                    gunButonlari(for: .teklif, proxy: proxy)
                                } else {
                                    ZenAnswerChip(
                                        text: "Haftada \(viewModel.draft.teklifOfisGunSayisi) gün",
                                        icon: "calendar",
                                        color: viewModel.offerCompanyColor
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            viewModel.draft.teklifOfisGunSayisi = 0
                                            viewModel.draft.teklifUlasimTipi = ""
                                        }
                                    }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        let teklifUlasimGorunur = teklifUlasimGerekli &&
                            (viewModel.draft.teklifCalismaModeli != "Hibrit" ||
                             viewModel.draft.teklifOfisGunSayisi > 0)
                        if teklifUlasimGorunur {
                            ayrac()
                            soruBolumu(id: "t3") {
                                Text("Ulaşım nasıl sağlanıyor?")
                                    .font(.title3.bold())
                                    .foregroundColor(viewModel.offerCompanyColor)
                                if viewModel.draft.teklifUlasimTipi.isEmpty {
                                    ulasimButonlari(for: .teklif, proxy: proxy)
                                } else {
                                    ZenAnswerChip(
                                        text: viewModel.draft.teklifUlasimTipi,
                                        icon: ulasimIkonu(viewModel.draft.teklifUlasimTipi),
                                        color: viewModel.offerCompanyColor
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            viewModel.draft.teklifUlasimTipi = ""
                                        }
                                    }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        if !viewModel.draft.teklifUlasimTipi.isEmpty {
                            ayrac()
                            soruBolumu(id: "t4") {
                                Text("Günlük yol süresi?")
                                    .font(.title3.bold())
                                    .foregroundColor(viewModel.offerCompanyColor)
                                sureStepper(
                                    value: $viewModel.draft.teklifYolSureDakika,
                                    color: viewModel.offerCompanyColor
                                )
                                if viewModel.draft.teklifUlasimTipi == "Servis" {
                                    servisKmKutucuk(
                                        km: $teklifServisTekYonKm,
                                        color: viewModel.offerCompanyColor
                                    )
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

                    Spacer(minLength: 100)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                           value: viewModel.draft.mevcutCalismaModeli)
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                           value: viewModel.draft.mevcutUlasimTipi)
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                           value: viewModel.workMevcutTamamlandi)
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                           value: viewModel.draft.teklifCalismaModeli)
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                           value: viewModel.draft.teklifUlasimTipi)
            }
            .safeAreaInset(edge: .bottom) {
                if teklifTamamlandi ||
                   (mevcutTamamlandi && viewModel.draft.teklifCalismaModeli == "Uzaktan") {
                    zenDevamButonu(renk: viewModel.offerCompanyColor) {
                        HapticHelper.triggerImpact(.medium); onNext()
                    }
                }
            }
        }
    }

    enum Taraf { case mevcut, teklif }

    @ViewBuilder
    private func modelButonlari(for taraf: Taraf, proxy: ScrollViewProxy) -> some View {
        let renk = taraf == .mevcut ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        VStack(spacing: 10) {
            ZenBigButton(title: "Ofis",   icon: "building.2.fill", color: renk) {
                setModel("Ofis", taraf: taraf, proxy: proxy)
            }
            ZenBigButton(title: "Hibrit", icon: "laptopcomputer",  color: renk) {
                setModel("Hibrit", taraf: taraf, proxy: proxy)
            }
            ZenBigButton(title: "Remote", icon: "house.fill",      color: renk) {
                setModel("Uzaktan", taraf: taraf, proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func gunButonlari(for taraf: Taraf, proxy: ScrollViewProxy) -> some View {
        let renk = taraf == .mevcut ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { gun in
                Button("\(gun)") { setGun(gun, taraf: taraf, proxy: proxy) }
                    .font(.title2.bold())
                    .frame(width: 52, height: 52)
                    .background(renk.opacity(0.1))
                    .foregroundColor(renk)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(renk.opacity(0.3), lineWidth: 1.5))
            }
        }
    }

    @ViewBuilder
    private func ulasimButonlari(for taraf: Taraf, proxy: ScrollViewProxy) -> some View {
        let renk = taraf == .mevcut ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        VStack(spacing: 10) {
            ZenBigButton(title: "Araç",         icon: "car.fill",    color: renk) { setUlasim("Araç", taraf: taraf, proxy: proxy) }
            ZenBigButton(title: "Servis",        icon: "bus.fill",    color: renk) { setUlasim("Servis", taraf: taraf, proxy: proxy) }
            ZenBigButton(title: "Toplu Taşıma",  icon: "tram.fill",   color: renk) { setUlasim("Toplu Taşıma", taraf: taraf, proxy: proxy) }
            ZenBigButton(title: "Yürüyerek",     icon: "figure.walk", color: renk) { setUlasim("Yürüyüş", taraf: taraf, proxy: proxy) }
        }
    }

    @ViewBuilder
    private func sureStepper(value: Binding<Int>, color: Color) -> some View {
        HStack(spacing: 20) {
            Button {
                value.wrappedValue = max(0, value.wrappedValue - 10)
                HapticHelper.triggerImpact(.light)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 36)).foregroundColor(color)
            }
            Text("\(value.wrappedValue) Dk")
                .font(.system(size: 28, weight: .bold)).frame(minWidth: 100)
            Button {
                value.wrappedValue = min(300, value.wrappedValue + 10)
                HapticHelper.triggerImpact(.light)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36)).foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func servisKmKutucuk(km: Binding<String>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tek yön kaç km?")
                .font(.subheadline.bold())
                .foregroundColor(color)
            TextField("Km", text: km)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding(12)
        }
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        .padding(.top, 8)
    }

    @ViewBuilder
    private func sirketBaslik(_ baslik: String, color: Color) -> some View {
        Text(baslik)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    @ViewBuilder
    private func soruBolumu(id: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .applyIf(id != nil) { $0.id(id!) }
    }

    @ViewBuilder private func ayrac() -> some View {
        Rectangle().fill(Color.gray.opacity(0.12)).frame(height: 1).padding(.horizontal, 24)
    }

    private func setModel(_ model: String, taraf: Taraf, proxy: ScrollViewProxy) {
        HapticHelper.triggerImpact(.light)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if taraf == .mevcut { viewModel.draft.mevcutCalismaModeli = model }
            else                { viewModel.draft.teklifCalismaModeli = model }
        }
        let anchor = taraf == .mevcut ? "m2" : "t2"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { proxy.scrollTo(anchor, anchor: .top) }
        }
    }

    private func setGun(_ gun: Int, taraf: Taraf, proxy: ScrollViewProxy) {
        HapticHelper.triggerImpact(.light)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if taraf == .mevcut { viewModel.draft.mevcutOfisGunSayisi = gun }
            else                { viewModel.draft.teklifOfisGunSayisi = gun }
        }
        let anchor = taraf == .mevcut ? "m3" : "t3"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { proxy.scrollTo(anchor, anchor: .top) }
        }
    }

    private func setUlasim(_ tip: String, taraf: Taraf, proxy: ScrollViewProxy) {
        HapticHelper.triggerImpact(.light)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if taraf == .mevcut { viewModel.draft.mevcutUlasimTipi = tip }
            else                { viewModel.draft.teklifUlasimTipi = tip }
        }
        let anchor = taraf == .mevcut ? "m4" : "t4"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { proxy.scrollTo(anchor, anchor: .top) }
        }
    }

    private func modelIkonu(_ model: String) -> String {
        switch model {
        case "Hibrit":  return "laptopcomputer"
        case "Uzaktan": return "house.fill"
        default:        return "building.2.fill"
        }
    }

    private func ulasimIkonu(_ tip: String) -> String {
        switch tip {
        case "Araç":         return "car.fill"
        case "Servis":       return "bus.fill"
        case "Toplu Taşıma": return "tram.fill"
        default:             return "figure.walk"
        }
    }
}

// MARK: - Adım 4a–4d: Yan Haklar — Her biri tek soru, tek sayfa

struct ZenYemekMevcutStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Mevcut işinde yemek imkanı nasıl?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            VStack(spacing: 14) {
                ZenBigButton(title: "Yemekhane", icon: "fork.knife", color: viewModel.currentCompanyColor) {
                    viewModel.draft.mevcutYemekTipi = "Yemekhane"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Yemek Kartı / Ticket", icon: "creditcard.fill", color: viewModel.currentCompanyColor) {
                    viewModel.draft.mevcutYemekTipi = "Yemek Kartı"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Yok", icon: "xmark.circle", color: .gray) {
                    viewModel.draft.mevcutYemekTipi = "Yok"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ZenSigortaMevcutStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Mevcut işinde sağlık sigortası sağlanıyor mu?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            VStack(spacing: 14) {
                ZenBigButton(title: "Özel Sağlık (ÖSS)", icon: "staroflife.fill", color: viewModel.currentCompanyColor) {
                    viewModel.draft.mevcutSigortaTipi = "Özel"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Tamamlayıcı (TSS)", icon: "cross.case.fill", color: viewModel.currentCompanyColor) {
                    viewModel.draft.mevcutSigortaTipi = "Tamamlayıcı"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Yok", icon: "xmark.circle", color: .gray) {
                    viewModel.draft.mevcutSigortaTipi = "Yok"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ZenYemekTeklifStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Yeni teklifte yemek imkanı var mı?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            VStack(spacing: 14) {
                ZenBigButton(title: "Yemekhane", icon: "fork.knife", color: viewModel.offerCompanyColor) {
                    viewModel.draft.teklifYemekTipi = "Yemekhane"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Yemek Kartı / Ticket", icon: "creditcard.fill", color: viewModel.offerCompanyColor) {
                    viewModel.draft.teklifYemekTipi = "Yemek Kartı"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Yok", icon: "xmark.circle", color: .gray) {
                    viewModel.draft.teklifYemekTipi = "Yok"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ZenSigortaTeklifStep: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Yeni teklifte sağlık sigortası sağlanıyor mu?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            VStack(spacing: 14) {
                ZenBigButton(title: "Özel Sağlık (ÖSS)", icon: "staroflife.fill", color: viewModel.offerCompanyColor) {
                    viewModel.draft.teklifSigortaTipi = "Özel"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Tamamlayıcı (TSS)", icon: "cross.case.fill", color: viewModel.offerCompanyColor) {
                    viewModel.draft.teklifSigortaTipi = "Tamamlayıcı"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
                ZenBigButton(title: "Yok", icon: "xmark.circle", color: .gray) {
                    viewModel.draft.teklifSigortaTipi = "Yok"
                    HapticHelper.triggerImpact(.light)
                    onNext()
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Paylaşılan: Sabit Devam Butonu

@ViewBuilder
private func zenDevamButonu(renk: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text("Devam Et →")
            .font(.headline.bold()).foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(renk).cornerRadius(14)
            .shadow(color: renk.opacity(0.3), radius: 8, y: 4)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 8)
    .background(
        LinearGradient(
            colors: [Color.clear, Color(uiColor: .systemBackground).opacity(0.95)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    )
}

@ViewBuilder
private func zenAkisButonu(baslik: String, renk: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(baslik)
            .font(.subheadline.bold()).foregroundColor(renk)
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(renk.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(renk.opacity(0.2), lineWidth: 1))
    }
    .buttonStyle(.plain)
}

// MARK: - Paylaşılan: İçi Geri Butonu (artık sadece Work ve Benefits step'leri kullanır)

@ViewBuilder
private func zenGeriButonu(goster: Bool, action: @escaping () -> Void) -> some View {
    HStack {
        if goster {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.caption.bold())
                    Text("Geri").font(.subheadline.bold())
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1)).cornerRadius(20)
            }
            .transition(.opacity.combined(with: .move(edge: .leading)))
        }
        Spacer()
    }
    .padding(.horizontal, 24).padding(.top, 4)
    .animation(.easeInOut(duration: 0.2), value: goster)
}

// MARK: - Paylaşılan Bileşenler

struct ZenAnswerChip: View {
    let text: String
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.subheadline).foregroundColor(color)
            Text(text).font(.subheadline.bold()).foregroundColor(color)
            Spacer()
            if onTap != nil {
                Image(systemName: "pencil.circle").font(.callout).foregroundColor(color.opacity(0.45))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

struct ZenTextField<Field: Hashable>: View {
    let placeholder: String
    @Binding var text: String
    let color: Color
    let field: Field
    let focused: FocusState<Field?>.Binding
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body.weight(.semibold))
            .padding(14).frame(minHeight: 52)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .focused(focused, equals: field)
            .submitLabel(submitLabel).onSubmit(onSubmit)
            .simultaneousGesture(TapGesture().onEnded { focused.wrappedValue = field })
    }
}

struct ZenNumberField<Field: Hashable>: View {
    let placeholder: String
    @Binding var text: String
    let color: Color
    let field: Field
    let focused: FocusState<Field?>.Binding
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(14).frame(minHeight: 52)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .focused(focused, equals: field)
            .submitLabel(submitLabel).onSubmit(onSubmit)
            .simultaneousGesture(TapGesture().onEnded { focused.wrappedValue = field })
    }
}

// MARK: - Akıllı Para Giriş Alanı (Fintech Standartı)
/// Tutar sadece rakam olarak düzenlenir; ₺ simgesi sabit gösterilir ve silinmez.
struct CurrencyInputField<Field: Hashable>: View {
    var title: String
    @Binding var rawText: String
    let color: Color
    let field: Field
    let focused: FocusState<Field?>.Binding
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    @State private var displayValue: String = ""

    private func formatCurrency(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    var body: some View {
        HStack(spacing: 4) {
            TextField(title, text: $displayValue)
                .keyboardType(.numberPad)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .focused(focused, equals: field)
                .submitLabel(submitLabel).onSubmit(onSubmit)
                .simultaneousGesture(TapGesture().onEnded { focused.wrappedValue = field })
                .onChange(of: displayValue) { _, newValue in
                    let cleanString = newValue.filter { $0.isNumber }
                    rawText = cleanString
                    if let number = Int(cleanString) {
                        displayValue = formatCurrency(number)
                    } else {
                        displayValue = ""
                    }
                }
                .onAppear {
                    if !rawText.isEmpty, let number = Int(rawText) {
                        displayValue = formatCurrency(number)
                    }
                }
            Text("₺")
                .font(.body.weight(.semibold))
                .foregroundColor(color)
        }
        .padding(14).frame(minHeight: 52)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ZenSegmented: View {
    @Binding var selected: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Button("Brüt") { selected = true;  HapticHelper.triggerImpact(.light) }
                .font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(selected ? color : Color.clear)
                .foregroundColor(selected ? .white : .gray)
            Divider()
            Button("Net")  { selected = false; HapticHelper.triggerImpact(.light) }
                .font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(!selected ? color : Color.clear)
                .foregroundColor(!selected ? .white : .gray)
        }
        .frame(width: 60)
        .background(Color(uiColor: .systemBackground)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct ZenStepperRow: View {
    let title: String
    @Binding var value: Int
    let color: Color

    var body: some View {
        HStack {
            Text(title).font(.subheadline.bold()).foregroundColor(.secondary)
            Spacer()
            Button { if value > 1  { value -= 1; HapticHelper.triggerImpact(.light) } } label: {
                Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(color)
            }
            Text("\(value)").font(.title3.bold()).frame(width: 28, alignment: .center)
            Button { if value < 24 { value += 1; HapticHelper.triggerImpact(.light) } } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(color)
            }
        }
        .padding(12).background(Color(uiColor: .systemBackground)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct ZenBigButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.headline.bold())
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 18).frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground)).foregroundColor(color)
            .cornerRadius(18).shadow(color: color.opacity(0.12), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct ZenMenuLabel: View {
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Text(text).font(.headline.bold())
            Spacer()
            Image(systemName: "chevron.up.chevron.down").font(.callout)
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
        .background(Color(uiColor: .systemBackground)).foregroundColor(color)
        .cornerRadius(18).shadow(color: color.opacity(0.12), radius: 12, y: 4)
    }
}

// MARK: - View Modifier Yardımcılar

private extension View {
    func zenKutu(color: Color) -> some View {
        self.padding(18).background(color.opacity(0.05)).cornerRadius(20)
    }

    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Adım 5: Kıyaslama Analiz Dashboard'u
